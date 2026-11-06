-- =====================================================================
-- Chemistria · รอบที่ 4: ตกแต่งตัวละคร (กรอบ/พื้นหลัง/หมวก/สัตว์เลี้ยง/ฉายา) + หอเกียรติยศประจำห้อง
-- รันซ้ำได้ · ต้องรัน 01_schema.sql, 02_seed.sql มาก่อน (setup_all.sql รวมทุกไฟล์ให้แล้ว)
-- =====================================================================

create table if not exists decor_items (
  id uuid primary key default gen_random_uuid(),
  slot text not null check (slot in ('frame','bg','hat','pet','title')),
  key text not null default 'solid',      -- ชื่อสไตล์ในหน้าเว็บ (เช่น solid, flame, galaxy) — ถ้าเพิ่มสไตล์ใหม่ต้องแก้ CSS
  color text,                              -- สีหลัก (ใช้กับสไตล์ solid)
  name text not null,
  emoji text not null default '✨',        -- กรอบ/พื้นหลัง/ฉายา = ไอคอนในรายการ · หมวก/สัตว์เลี้ยง = ตัวที่แสดงบนตัวละคร
  rarity text not null default 'R' check (rarity in ('N','R','SR','SSR')),
  price int check (price is null or price >= 0),   -- ใส่ราคา = วางขายในร้านค้า · ว่าง = ได้จากกาชาเท่านั้น
  sort int not null default 0,
  active boolean not null default true
);

create table if not exists student_decor (
  student_id uuid not null references students(id) on delete cascade,
  item_id uuid not null references decor_items(id) on delete cascade,
  source text not null default 'shop' check (source in ('shop','gacha','teacher')),
  acquired_at timestamptz default now(),
  primary key (student_id, item_id)
);

alter table students add column if not exists decor jsonb not null default '{}'::jsonb;   -- {slot: decor_item_id}
alter table gacha_items add column if not exists decor_id uuid references decor_items(id) on delete cascade;
alter table gacha_items drop constraint if exists gacha_items_kind_check;
alter table gacha_items add constraint gacha_items_kind_check check (kind in ('coins','exp','cosmetic','privilege','decor'));

do $$
declare t text;
begin
  foreach t in array array['decor_items','student_decor'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists teacher_all on public.%I', t);
    execute format('create policy teacher_all on public.%I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- ฟังก์ชัน
-- ---------------------------------------------------------------------
-- ไอเทมที่สวมอยู่ของนักเรียน → {frame:{...}, bg:{...}, hat:{...}, pet:{...}, title:{...}}
create or replace function _decor_of(p_sid uuid) returns json
language sql stable security definer set search_path = public as $$
  select coalesce(json_object_agg(d.slot, json_build_object('id', d.id, 'key', d.key, 'color', d.color,
           'emoji', d.emoji, 'name', d.name, 'rarity', d.rarity)), '{}'::json)
    from students s
    cross join lateral jsonb_each_text(s.decor) e
    join decor_items d on d.id = e.value::uuid and d.slot = e.key
   where s.id = p_sid
$$;

create or replace function buy_decor(p_token uuid, p_item uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); d decor_items%rowtype; s students%rowtype;
begin
  select * into d from decor_items where id = p_item and active;
  if not found or d.price is null then raise exception 'ไอเทมนี้ไม่ได้วางขาย'; end if;
  select * into s from students where id = sid for update;
  if exists (select 1 from student_decor where student_id = sid and item_id = d.id) then
    raise exception 'มีไอเทมนี้แล้ว';
  end if;
  if s.coins < d.price then raise exception 'เหรียญไม่พอ (ต้องใช้ % เหรียญ)', d.price; end if;
  insert into student_decor (student_id, item_id, source) values (sid, d.id, 'shop');
  perform award(sid, 0, -d.price, 'ซื้อไอเทมตกแต่ง: ' || d.name, null);
  return json_build_object('name', d.name, 'coins', s.coins - d.price);
end $$;

-- สวมใส่ (p_item = null → ถอดออกจากช่องนั้น)
create or replace function equip_decor(p_token uuid, p_slot text, p_item uuid) returns void
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  if p_slot not in ('frame','bg','hat','pet','title') then raise exception 'ช่องไม่ถูกต้อง'; end if;
  if p_item is null then
    update students set decor = decor - p_slot where id = sid;
    return;
  end if;
  if not exists (select 1 from student_decor sd join decor_items d on d.id = sd.item_id
                  where sd.student_id = sid and sd.item_id = p_item and d.slot = p_slot) then
    raise exception 'ยังไม่มีไอเทมนี้';
  end if;
  update students set decor = decor || jsonb_build_object(p_slot, p_item::text) where id = sid;
end $$;

-- หอเกียรติยศ: Top 3 ของทุกห้อง (เฉพาะคนที่มี EXP > 0) · ห้องของตัวเองขึ้นก่อน
create or replace function hall_of_fame(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); mycls uuid; r json;
begin
  select class_id into mycls from students where id = sid;
  select coalesce(json_agg(h order by h.mine desc, h.name), '[]'::json) into r from (
    select c.id, c.code, c.name, (c.id = mycls) as mine,
      (select json_agg(json_build_object('name', x.name, 'no', x.no, 'avatar', x.avatar, 'char_class', x.char_class, 'exp', x.exp,
          'level', level_for(x.exp), 'rank_info', rank_info(x.exp), 'decor', _decor_of(x.id), 'me', x.id = sid) order by x.exp desc, x.no)
         from (select * from students where class_id = c.id and exp > 0 order by exp desc, no limit 3) x) as top
      from classes c
  ) h where h.top is not null;
  return r;
end $$;

revoke execute on function _decor_of(uuid) from public, anon, authenticated;
revoke execute on function buy_decor(uuid, uuid) from public;
revoke execute on function equip_decor(uuid, text, uuid) from public;
revoke execute on function hall_of_fame(uuid) from public;
grant execute on function buy_decor(uuid, uuid) to anon, authenticated;
grant execute on function equip_decor(uuid, text, uuid) to anon, authenticated;
grant execute on function hall_of_fame(uuid) to anon, authenticated;

-- ---------------------------------------------------------------------
-- ไอเทมตัวอย่าง (ใส่เฉพาะตอนตารางยังว่าง) · gw = น้ำหนักในตู้กาชา (0 = ไม่อยู่ในกาชา)
-- ---------------------------------------------------------------------
do $$
begin
  if exists (select 1 from decor_items) then return; end if;
  insert into decor_items (slot, key, color, name, emoji, rarity, price, sort)
  select slot, key, color, name, emoji, rarity, price, sort from (values
    -- กรอบ
    ('frame','solid','#4fe3b0','กรอบมิ้นต์','🖼️','N',50,1),
    ('frame','solid','#ff8fb7','กรอบซากุระ','🌸','N',50,2),
    ('frame','ice',null,'กรอบน้ำแข็ง','🧊','R',120,3),
    ('frame','flame',null,'กรอบเปลวไฟ','🔥','R',120,4),
    ('frame','neon',null,'กรอบนีออน','💜','SR',null,5),
    ('frame','gold',null,'กรอบทองคำ','🏅','SR',null,6),
    ('frame','rainbow',null,'กรอบสายรุ้ง','🌈','SSR',null,7),
    -- พื้นหลัง
    ('bg','solid','#3a1f78','พื้นม่วงห้องแล็บ','🟣','N',40,1),
    ('bg','sunset',null,'พื้นพระอาทิตย์ตก','🌇','R',100,2),
    ('bg','forest',null,'พื้นป่าเขียว','🌲','R',100,3),
    ('bg','lab',null,'พื้นกริดห้องแล็บ','🧪','R',null,4),
    ('bg','galaxy',null,'พื้นกาแล็กซี','🌌','SR',null,5),
    ('bg','aurora',null,'พื้นแสงเหนือ','🌠','SSR',null,6),
    -- หมวก/เครื่องประดับบนหัว
    ('hat','emoji',null,'โบว์ชมพู','🎀','N',60,1),
    ('hat','emoji',null,'หมวกแก๊ป','🧢','N',60,2),
    ('hat','emoji',null,'หมวกบัณฑิต','🎓','R',150,3),
    ('hat','emoji',null,'หมวกทรงสูง','🎩','R',150,4),
    ('hat','emoji',null,'มงกุฎทอง','👑','SSR',null,5),
    -- สัตว์เลี้ยง
    ('pet','emoji',null,'น้องกบ','🐸','N',80,1),
    ('pet','emoji',null,'น้องแมว','🐱','R',200,2),
    ('pet','emoji',null,'น้องหมา','🐶','R',200,3),
    ('pet','emoji',null,'น้องจิ้งจอก','🦊','SR',null,4),
    ('pet','emoji',null,'มังกรน้อย','🐉','SSR',null,5),
    -- ฉายา
    ('title','text',null,'หนอนตำรา','📚','N',50,1),
    ('title','text',null,'ผู้พิชิตโมล','⚖️','R',150,2),
    ('title','text',null,'ราชาออร์แกนิก','🧬','R',150,3),
    ('title','text',null,'จอมเวทธาตุ','🔮','SR',null,4),
    ('title','text',null,'ตำนานห้องแล็บ','🏆','SSR',null,5)
  ) v(slot, key, color, name, emoji, rarity, price, sort);

  -- ไอเทมที่ออกจากกาชา: ทุกชิ้นที่ N/R ราคาขายต่ำ + ชิ้น SR/SSR ทั้งหมด
  insert into gacha_items (name, rarity, kind, value, emoji, weight, decor_id)
  select d.name, d.rarity, 'decor', 0, d.emoji,
         case d.rarity when 'N' then 3 when 'R' then 2 else 1 end, d.id
    from decor_items d
   where d.rarity in ('SR','SSR') or d.price is null or d.name in ('กรอบน้ำแข็ง','กรอบเปลวไฟ','หมวกบัณฑิต','น้องแมว','ผู้พิชิตโมล');
end $$;
