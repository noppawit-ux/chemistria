-- =====================================================================
-- Chemistria · รอบที่ 5: ตัวละครเต็มตัว + ชุด/เอฟเฟค/ไอเทมลอย + หอเกียรติยศเฉพาะห้องตัวเอง
-- รันซ้ำได้ · ต้องรันหลัง 05_decor.sql (setup_all.sql รวมให้แล้ว)
-- ฟังก์ชัน _decor_of / equip_decor / hall_of_fame ในไฟล์นี้ใช้แทนเวอร์ชันใน 05
-- =====================================================================

alter table decor_items add column if not exists image text;      -- ใช้กับช่อง "ไอเทม" (ภาพลอยข้างตัวละคร)
alter table decor_items drop constraint if exists decor_items_slot_check;
alter table decor_items add constraint decor_items_slot_check
  check (slot in ('frame','bg','hat','pet','title','outfit','fx','item'));

create or replace function _decor_of(p_sid uuid) returns json
language sql stable security definer set search_path = public as $$
  select coalesce(json_object_agg(d.slot, json_build_object('id', d.id, 'key', d.key, 'color', d.color,
           'emoji', d.emoji, 'name', d.name, 'rarity', d.rarity, 'image', d.image)), '{}'::json)
    from students s
    cross join lateral jsonb_each_text(s.decor) e
    join decor_items d on d.id = e.value::uuid and d.slot = e.key
   where s.id = p_sid
$$;

create or replace function equip_decor(p_token uuid, p_slot text, p_item uuid) returns void
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  if p_slot not in ('frame','bg','hat','pet','title','outfit','fx','item') then raise exception 'ช่องไม่ถูกต้อง'; end if;
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

-- หอเกียรติยศ: Top 3 ของ "ห้องตัวเองเท่านั้น" (เฉพาะคนที่มี EXP > 0)
create or replace function hall_of_fame(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); mycls uuid; r json;
begin
  select class_id into mycls from students where id = sid;
  select coalesce(json_agg(h), '[]'::json) into r from (
    select c.id, c.code, c.name, true as mine,
      (select json_agg(json_build_object('name', x.name, 'no', x.no, 'avatar', x.avatar, 'char_class', x.char_class, 'exp', x.exp,
          'level', level_for(x.exp), 'rank_info', rank_info(x.exp), 'decor', _decor_of(x.id), 'me', x.id = sid) order by x.exp desc, x.no)
         from (select * from students where class_id = c.id and exp > 0 order by exp desc, no limit 3) x) as top
      from classes c where c.id = mycls
  ) h where h.top is not null;
  return r;
end $$;

-- ---------------------------------------------------------------------
-- ไอเทมตัวอย่างใหม่: ชุด / เอฟเฟค / ไอเทมลอย (ใส่เฉพาะตอนยังไม่มีสามช่องนี้)
-- ภาพชุด: web/assets/chars/<คลาส>_<สไตล์>.png (ไม่มีภาพจะใช้ชุดเริ่มต้นแทน)
-- ---------------------------------------------------------------------
do $$
begin
  if exists (select 1 from decor_items where slot in ('outfit','fx','item')) then return; end if;
  insert into decor_items (slot, key, color, name, emoji, rarity, price, sort, image)
  select slot, key, color, name, emoji, rarity, price, sort, image from (values
    ('outfit','space',null,'ชุดนักบินอวกาศ','🚀','R',250,1,null),
    ('outfit','wizard',null,'ชุดจอมเวทย์','🪄','SR',null,2,null),
    ('fx','sparkle',null,'ประกายดาว','✨','N',100,1,null),
    ('fx','bubbles',null,'ฟองสารเคมี','🫧','R',150,2,null),
    ('fx','flame',null,'ออร่าเปลวไฟ','🔥','R',200,3,null),
    ('fx','ice',null,'หิมะน้ำแข็ง','❄️','R',200,4,null),
    ('fx','lightning',null,'สายฟ้าฟาด','⚡','SR',null,5,null),
    ('fx','orbit',null,'ดาวโคจร','🪐','SSR',null,6,null),
    ('item','img',null,'ขวดยาสีแดง','🧪','N',60,1,'assets/items/potion_red.png'),
    ('item','img',null,'ขวดยาสีเขียว','🧪','R',100,2,'assets/items/potion_green.png'),
    ('item','img',null,'ตะเกียงแอลกอฮอล์','🔥','R',120,3,'assets/items/burner.png'),
    ('item','img',null,'กล้องจุลทรรศน์','🔬','R',150,4,'assets/items/microscope.png'),
    ('item','img',null,'คริสตัลเรืองแสง','💎','SR',null,5,'assets/items/crystal.png'),
    ('item','img',null,'คทาเวทมนตร์','🪄','SSR',null,6,'assets/items/wand.png')
  ) v(slot, key, color, name, emoji, rarity, price, sort, image);

  insert into gacha_items (name, rarity, kind, value, emoji, weight, decor_id)
  select d.name, d.rarity, 'decor', 0, d.emoji,
         case d.rarity when 'N' then 3 when 'R' then 2 else 1 end, d.id
    from decor_items d
   where d.slot in ('outfit','fx','item')
     and (d.rarity in ('SR','SSR') or d.price is null or d.name in ('ชุดนักบินอวกาศ','ออร่าเปลวไฟ'));
end $$;
