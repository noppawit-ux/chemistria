-- 66: ไอเทมกดใช้ (ยา/บัฟ/ม้วนอัปเกรด) + เลเวลของสวมใส่ + ปรับสมดุลสเตตัส + ลดเรท SSR กาชา (v2.00) · รันซ้ำได้
--  · ไอเทมกดใช้: ซื้อด้วยเหรียญ (จำกัดต่อวัน) · บัฟมีผลถึงสิ้นวัน (เวลาไทย) ชนิดละ 1 ครั้ง/วัน
--  · ยาฟื้นฟู: ใช้ในศึกมอนสเตอร์ (ฟื้นตามเปอร์เซ็นต์ HP สูงสุด · สูงสุด 2 ครั้ง/ศึก)
--  · อัปเกรดของสวมใส่: ใช้ม้วนอัปเกรด + เหรียญ · ทุกเลเวลที่เพิ่ม = +1 สเตตัสหลักของไอเทมนั้น
--  · สมดุล: เพดานสเตตัสต่อไอเทมตามความหายาก + เพดานรวมโบนัสจากไอเทม (stat_item_cap=12, stat_coin_cap=15)
--  · กาชา: น้ำหนัก SSR × gacha_ssr_mult % (ค่าเริ่มต้น 20 → SSR ราว 3% จากเดิม ~14%)

-- ---------- ตาราง ----------
create table if not exists consumables (
  id uuid primary key default gen_random_uuid(),
  key text unique not null,
  name text not null, emoji text not null default '🧪', image text,
  rarity text not null default 'N' check (rarity in ('N','R','SR','SSR')),
  kind text not null check (kind in ('buff_exp','buff_coin','buff_luk','buff_str','buff_int','heal','scroll','stat_reset')),
  power int not null default 0,          -- ขนาดผล: บัฟ = ค่าที่เพิ่ม · heal = % ของ HP สูงสุด
  price int check (price is null or price >= 0),
  daily_buy int not null default 3 check (daily_buy between 1 and 20),
  descr text, sort int not null default 0, active boolean not null default true
);
create table if not exists student_items (
  student_id uuid not null references students(id) on delete cascade,
  item_id uuid not null references consumables(id) on delete cascade,
  qty int not null default 0 check (qty >= 0),
  primary key (student_id, item_id)
);
create table if not exists student_buffs (
  student_id uuid not null references students(id) on delete cascade,
  kind text not null, power int not null, day date not null,
  primary key (student_id, kind)
);
create table if not exists item_daily (
  student_id uuid not null references students(id) on delete cascade,
  item_id uuid not null references consumables(id) on delete cascade,
  day date not null, bought int not null default 0,
  primary key (student_id, item_id, day)
);
alter table student_decor add column if not exists lvl int not null default 1 check (lvl between 1 and 9);
alter table battles add column if not exists potions int not null default 0;

do $$ declare t text; begin
  foreach t in array array['consumables', 'student_items', 'student_buffs', 'item_daily'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists teacher_all on public.%I', t);
    execute format('create policy teacher_all on public.%I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;

insert into app_settings (key, value) values ('stat_item_cap', '12'), ('stat_coin_cap', '15'), ('gacha_ssr_mult', '20') on conflict (key) do nothing;

-- ---------- ไอเทมตั้งต้น ----------
insert into consumables (key, name, emoji, rarity, kind, power, price, daily_buy, descr, sort)
select v.* from (values
  ('p_exp',   'ยาเพิ่มพลังสมอง',   '🧪', 'R',  'buff_exp',   15, 90,  2, 'EXP ที่ได้รับ +15% ถึงสิ้นวัน',                10),
  ('p_coin',  'ยาเหรียญทอง',       '💰', 'R',  'buff_coin',  20, 80,  2, 'เหรียญที่ได้รับ +20% ถึงสิ้นวัน',              20),
  ('p_luck',  'ยาโชคสี่แฉก',       '🍀', 'SR', 'buff_luk',    4, 120, 2, 'โชค +4 ถึงสิ้นวัน (โอกาส SR/SSR ในกาชาสูงขึ้น)', 30),
  ('p_str',   'ยากล้ามเคมี',       '⚔️', 'R',  'buff_str',   15, 90,  2, 'ดาเมจบอสจากเควส +15% ถึงสิ้นวัน',              40),
  ('p_int',   'ยาอัจฉริยะ',        '🧠', 'R',  'buff_int',    2, 80,  2, 'โบนัส EXP ควิซ +2 ถึงสิ้นวัน',                 50),
  ('p_heal',  'ยาฟื้นฟู HP',       '💚', 'N',  'heal',       40, 60,  5, 'ใช้ในศึกมอนสเตอร์ ฟื้น HP 40% (ใช้ได้ 2 ครั้ง/ศึก)', 60),
  ('scroll',  'ม้วนอัปเกรด',       '📜', 'R',  'scroll',      0, 120, 5, 'ใช้อัปเกรดเลเวลของสวมใส่ (ดูแท็บ 🧪 ไอเทม)',      70),
  ('t_reset', 'ตั๋วล้างแต้มสเตตัส', '🔄', 'N',  'stat_reset',  0, 90,  2, 'ล้างแต้มสเตตัสที่ใส่ไว้ ใส่ใหม่ได้ทันที',        80)
) v(key, name, emoji, rarity, kind, power, price, daily_buy, descr, sort)
where not exists (select 1 from consumables c where c.key = v.key);

-- ---------- สมดุลสเตตัสของไอเทมตกแต่ง ----------
create or replace function _item_main(a int, b int, c int, d int) returns text
language sql immutable as $$
  select case when greatest(a, b, c, d) <= 0 then null
              when a >= greatest(b, c, d) then 'int' when b >= greatest(c, d) then 'dil' when c >= d then 'str' else 'luk' end
$$;
revoke execute on function _item_main(int, int, int, int) from public, anon, authenticated;

do $$ declare r record; cap int; ccap int; a int; b int; c int; d int; n int; begin
  for r in select * from decor_items loop
    cap := case r.rarity when 'N' then 2 when 'R' then 3 when 'SR' then 4 when 'SSR' then 5 else 7 end;
    ccap := case r.rarity when 'N' then 2 when 'R' then 4 when 'SR' then 6 when 'SSR' then 6 else 8 end;
    a := coalesce(r.st_int, 0); b := coalesce(r.st_dil, 0); c := coalesce(r.st_str, 0); d := coalesce(r.st_luk, 0);
    n := 0;
    while a + b + c + d > cap and n < 40 loop
      if a >= greatest(b, c, d) then a := a - 1; elsif b >= greatest(c, d) then b := b - 1; elsif c >= d then c := c - 1; else d := d - 1; end if;
      n := n + 1;
    end loop;
    if a <> coalesce(r.st_int, 0) or b <> coalesce(r.st_dil, 0) or c <> coalesce(r.st_str, 0) or d <> coalesce(r.st_luk, 0) or coalesce(r.st_coin, 0) > ccap then
      update decor_items set st_int = a, st_dil = b, st_str = c, st_luk = d, st_coin = least(coalesce(st_coin, 0), ccap) where id = r.id;
    end if;
  end loop;
end $$;

-- ---------- _stats: เลเวลของสวมใส่ + เพดานโบนัสไอเทม + บัฟประจำวัน ----------
create or replace function _stats(p_sid uuid) returns json
language plpgsql stable security definer set search_path = public as $$
declare
  b_int int; b_dil int; b_str int; b_luk int;
  i_int int := 0; i_dil int := 0; i_str int := 0; i_luk int := 0; i_coin int := 0;
  p_int int; p_dil int; p_str int; p_luk int; cap int := _setting_int('stat_alloc_cap', 15);
  sp jsonb; lv int; tot int; per int := _setting_int('stat_pts_per_level', 2);
  k numeric := _setting_int('stat_effect_pct', 50) / 100.0;
  icap int := _setting_int('stat_item_cap', 12); ccap int := _setting_int('stat_coin_cap', 15);
  f_exp int := 0; f_coin int := 0; f_luk int := 0; f_str int := 0; f_int int := 0; bl json;
begin
  b_int := least(10, coalesce((select sum(correct) from game_plays where student_id = p_sid and game = 'quiz'), 0)::int / 8);
  b_dil := least(10, student_metric(p_sid, 'present_count') / 4);
  b_str := least(10, student_metric(p_sid, 'quests_done') / 8);
  b_luk := least(10, student_metric(p_sid, 'gacha_pulls') / 6);
  if coalesce((select is_gm from students where id = p_sid), false) then b_int := 10; b_dil := 10; b_str := 10; b_luk := 10; end if;
  select s.stat_pts, level_for(s.exp) into sp, lv from students s where s.id = p_sid;
  sp := coalesce(sp, '{}'::jsonb);
  p_int := least(cap, coalesce((sp->>'int')::int, 0)); p_dil := least(cap, coalesce((sp->>'dil')::int, 0));
  p_str := least(cap, coalesce((sp->>'str')::int, 0)); p_luk := least(cap, coalesce((sp->>'luk')::int, 0));
  tot := greatest(0, coalesce(lv, 1) - 1) * per;
  select coalesce(sum(d.st_int + case when m.main = 'int' then m.up else 0 end), 0), coalesce(sum(d.st_dil + case when m.main = 'dil' then m.up else 0 end), 0),
         coalesce(sum(d.st_str + case when m.main = 'str' then m.up else 0 end), 0), coalesce(sum(d.st_luk + case when m.main = 'luk' then m.up else 0 end), 0),
         coalesce(sum(d.st_coin), 0)
    into i_int, i_dil, i_str, i_luk, i_coin
    from students s
    cross join lateral jsonb_each_text(s.decor) e
    join decor_items d on d.id = e.value::uuid and d.slot = e.key
    left join student_decor sd on sd.student_id = s.id and sd.item_id = d.id
    cross join lateral (select _item_main(d.st_int, d.st_dil, d.st_str, d.st_luk) main, greatest(coalesce(sd.lvl, 1) - 1, 0) up) m
   where s.id = p_sid;
  i_int := least(i_int, icap); i_dil := least(i_dil, icap); i_str := least(i_str, icap); i_luk := least(i_luk, icap); i_coin := least(i_coin, ccap);
  select coalesce(sum(power) filter (where kind = 'buff_exp'), 0), coalesce(sum(power) filter (where kind = 'buff_coin'), 0),
         coalesce(sum(power) filter (where kind = 'buff_luk'), 0), coalesce(sum(power) filter (where kind = 'buff_str'), 0),
         coalesce(sum(power) filter (where kind = 'buff_int'), 0),
         coalesce(json_agg(json_build_object('kind', kind, 'power', power)), '[]'::json)
    into f_exp, f_coin, f_luk, f_str, f_int, bl
    from student_buffs where student_id = p_sid and day = today_th();
  return json_build_object(
    'int', json_build_object('base', b_int, 'pts', p_int, 'item', i_int, 'total', b_int + p_int + i_int),
    'dil', json_build_object('base', b_dil, 'pts', p_dil, 'item', i_dil, 'total', b_dil + p_dil + i_dil),
    'str', json_build_object('base', b_str, 'pts', p_str, 'item', i_str, 'total', b_str + p_str + i_str),
    'luk', json_build_object('base', b_luk, 'pts', p_luk, 'item', i_luk, 'buff', f_luk, 'total', b_luk + p_luk + i_luk + f_luk),
    'points', json_build_object('total', tot, 'spent', p_int + p_dil + p_str + p_luk, 'left', greatest(0, tot - (p_int + p_dil + p_str + p_luk)),
                                'cap', cap, 'per_level', per, 'reset_cost', _setting_int('stat_reset_cost', 100)),
    'buffs', bl,
    'effects', json_build_object('quiz_exp', floor((b_int + p_int + i_int) / 2.0 * k)::int + f_int,
                                 'exp_pct', round((b_dil + p_dil + i_dil) * k)::int + f_exp,
                                 'boss_pct', round(3 * (b_str + p_str + i_str) * k)::int + f_str,
                                 'rare_pct', round(3 * (b_luk + p_luk + i_luk + f_luk) * k)::int,
                                 'coin_pct', round(i_coin * k)::int + f_coin));
end $$;
revoke execute on function _stats(uuid) from public, anon, authenticated;

-- ---------- กาชา: ลดน้ำหนัก SSR ----------
create or replace function _gacha_pick_luk(p_high boolean, p_luk int, p_sid uuid) returns gacha_items
language plpgsql security definer set search_path = public as $$
declare total numeric; r numeric; acc numeric := 0; it gacha_items%rowtype; last_it gacha_items%rowtype; w numeric;
        rate numeric := _leg_rate(p_sid); n int;
        k numeric := 0.03 * _setting_int('stat_effect_pct', 50) / 100.0;
        sm numeric := least(greatest(_setting_int('gacha_ssr_mult', 20), 0), 100) / 100.0;
begin
  select count(*) into n from gacha_items where active and rarity = 'LEG';
  if n > 0 and random() < rate then
    select * into it from gacha_items where active and rarity = 'LEG' order by random() limit 1;
    return it;
  end if;
  select coalesce(sum(weight * case when rarity in ('SR','SSR') then 1 + k * greatest(p_luk, 0) else 1 end * case when rarity = 'SSR' then sm else 1 end), 0) into total
    from gacha_items where active and rarity <> 'LEG' and (not p_high or rarity in ('SR','SSR'));
  if total = 0 then raise exception 'ยังไม่มีไอเทมในกาชา'; end if;
  r := random() * total;
  for it in select * from gacha_items where active and rarity <> 'LEG' and (not p_high or rarity in ('SR','SSR')) order by id loop
    w := it.weight * case when it.rarity in ('SR','SSR') then 1 + k * greatest(p_luk, 0) else 1 end * case when it.rarity = 'SSR' then sm else 1 end;
    acc := acc + w; last_it := it;
    if r < acc then return it; end if;
  end loop;
  return last_it;
end $$;
revoke execute on function _gacha_pick_luk(boolean, int, uuid) from public, anon, authenticated;

-- ---------- RPC ฝั่งนักเรียน ----------
create or replace function _upg_cost(p_rarity text, p_lvl int) returns json
language sql immutable as $$
  select json_build_object(
    'max', case p_rarity when 'N' then 2 when 'R' then 3 when 'SR' then 4 else 5 end,
    'coins', case p_rarity when 'N' then 40 when 'R' then 70 when 'SR' then 120 when 'SSR' then 200 else 300 end * p_lvl,
    'scrolls', case when p_lvl + 1 <= 3 then 1 else 2 end)
$$;
revoke execute on function _upg_cost(text, int) from public, anon, authenticated;

create or replace function my_items(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); today date := today_th(); res json;
begin
  select json_build_object(
    'coins', (select coins from students where id = sid),
    'items', coalesce((select json_agg(json_build_object('id', c.id, 'key', c.key, 'name', c.name, 'emoji', c.emoji, 'image', c.image, 'rarity', c.rarity, 'kind', c.kind,
              'power', c.power, 'price', c.price, 'descr', c.descr, 'qty', coalesce(si.qty, 0), 'daily_buy', c.daily_buy,
              'bought', coalesce(idl.bought, 0),
              'used_today', c.kind like 'buff\_%' and exists (select 1 from student_buffs b where b.student_id = sid and b.kind = c.kind and b.day = today)) order by c.sort, c.name)
         from consumables c left join student_items si on si.item_id = c.id and si.student_id = sid
         left join item_daily idl on idl.item_id = c.id and idl.student_id = sid and idl.day = today where c.active), '[]'::json),
    'buffs', (_stats(sid)->'buffs'),
    'gear', coalesce((select json_agg(json_build_object('id', d.id, 'name', d.name, 'emoji', d.emoji, 'slot', d.slot, 'rarity', d.rarity, 'lvl', sd.lvl,
              'main', _item_main(d.st_int, d.st_dil, d.st_str, d.st_luk),
              'stats', json_build_object('int', d.st_int, 'dil', d.st_dil, 'str', d.st_str, 'luk', d.st_luk),
              'equipped', (select s.decor->>d.slot = d.id::text from students s where s.id = sid),
              'cost', _upg_cost(d.rarity, sd.lvl)) order by (d.rarity = 'LEG') desc, d.rarity desc, d.name)
         from student_decor sd join decor_items d on d.id = sd.item_id where sd.student_id = sid), '[]'::json)
  ) into res;
  return res;
end $$;

create or replace function buy_item(p_token uuid, p_item uuid, p_n int default 1) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); c consumables%rowtype; today date := today_th(); got int; have int; cost int;
begin
  if p_n is null or p_n < 1 or p_n > 5 then raise exception 'จำนวนไม่ถูกต้อง'; end if;
  select * into c from consumables where id = p_item and active;
  if not found or c.price is null then raise exception 'ไอเทมนี้ไม่ได้วางขาย'; end if;
  perform 1 from students where id = sid for update;
  select coalesce(bought, 0) into got from item_daily where student_id = sid and item_id = c.id and day = today;
  got := coalesce(got, 0);
  if got + p_n > c.daily_buy then raise exception 'วันนี้ซื้อ “%” ได้อีก % ชิ้น (จำกัด % ชิ้น/วัน)', c.name, greatest(c.daily_buy - got, 0), c.daily_buy; end if;
  cost := c.price * p_n;
  select coins into have from students where id = sid;
  if have < cost then raise exception 'เหรียญไม่พอ (ต้องใช้ % เหรียญ)', cost; end if;
  perform award(sid, 0, -cost, 'ซื้อไอเทม: ' || c.name || ' ×' || p_n, null);
  insert into item_daily (student_id, item_id, day, bought) values (sid, c.id, today, p_n)
    on conflict (student_id, item_id, day) do update set bought = item_daily.bought + p_n;
  insert into student_items (student_id, item_id, qty) values (sid, c.id, p_n)
    on conflict (student_id, item_id) do update set qty = student_items.qty + p_n;
  return json_build_object('name', c.name, 'coins', have - cost);
end $$;

create or replace function use_item(p_token uuid, p_item uuid, p_battle uuid default null) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); c consumables%rowtype; q int; b battles%rowtype; add int; today date := today_th(); msg text;
begin
  select * into c from consumables where id = p_item and active;
  if not found then raise exception 'ไม่พบไอเทม'; end if;
  if c.kind = 'scroll' then raise exception 'ม้วนอัปเกรดใช้ที่ส่วนอัปเกรดอุปกรณ์'; end if;
  perform 1 from students where id = sid for update;
  select qty into q from student_items where student_id = sid and item_id = c.id for update;
  if coalesce(q, 0) < 1 then raise exception 'ไม่มีไอเทมนี้ในคลัง'; end if;
  if c.kind like 'buff\_%' then
    if exists (select 1 from student_buffs where student_id = sid and kind = c.kind and day = today) then raise exception 'วันนี้ใช้บัฟชนิดนี้ไปแล้ว (บัฟไม่ซ้อนกัน)'; end if;
    insert into student_buffs (student_id, kind, power, day) values (sid, c.kind, c.power, today);
    msg := c.name || ' มีผลถึงสิ้นวันนี้';
  elsif c.kind = 'heal' then
    if p_battle is null then raise exception 'ยาฟื้นฟูใช้ได้ระหว่างสู้มอนสเตอร์เท่านั้น'; end if;
    select * into b from battles where id = p_battle and student_id = sid and status = 'active' for update;
    if not found then raise exception 'ไม่มีศึกที่กำลังสู้อยู่'; end if;
    if b.potions >= 2 then raise exception 'ศึกนี้ใช้ยาครบ 2 ครั้งแล้ว'; end if;
    if b.p_hp >= b.p_max then raise exception 'HP เต็มอยู่แล้ว'; end if;
    add := ceil(b.p_max * c.power / 100.0);
    update battles set p_hp = least(p_max, p_hp + add), potions = potions + 1 where id = b.id;
    msg := 'ฟื้น HP +' || least(add, b.p_max - b.p_hp);
  elsif c.kind = 'stat_reset' then
    if coalesce((_stats(sid)->'points'->>'spent')::int, 0) = 0 then raise exception 'ยังไม่ได้ใส่แต้มสเตตัส'; end if;
    update students set stat_pts = '{}'::jsonb where id = sid;
    msg := 'ล้างแต้มสเตตัสแล้ว ใส่ใหม่ได้เลย';
  end if;
  update student_items set qty = qty - 1 where student_id = sid and item_id = c.id;
  return json_build_object('name', c.name, 'msg', msg);
end $$;

create or replace function upgrade_decor(p_token uuid, p_item uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); d decor_items%rowtype; sd student_decor%rowtype; cst json; cn int; sc int; have int; scid uuid; sq int;
begin
  perform 1 from students where id = sid for update;
  select * into sd from student_decor where student_id = sid and item_id = p_item for update;
  if not found then raise exception 'ยังไม่มีไอเทมนี้'; end if;
  select * into d from decor_items where id = p_item;
  if _item_main(d.st_int, d.st_dil, d.st_str, d.st_luk) is null then raise exception 'ไอเทมนี้ไม่มีสเตตัสให้อัปเกรด'; end if;
  cst := _upg_cost(d.rarity, sd.lvl);
  if sd.lvl >= (cst->>'max')::int then raise exception 'เลเวลสูงสุดแล้ว (Lv %)', sd.lvl; end if;
  cn := (cst->>'coins')::int; sc := (cst->>'scrolls')::int;
  select id into scid from consumables where kind = 'scroll' order by sort limit 1;
  select qty into sq from student_items where student_id = sid and item_id = scid for update;
  if coalesce(sq, 0) < sc then raise exception 'ม้วนอัปเกรดไม่พอ (ต้องใช้ % ม้วน)', sc; end if;
  select coins into have from students where id = sid;
  if have < cn then raise exception 'เหรียญไม่พอ (ต้องใช้ % เหรียญ)', cn; end if;
  perform award(sid, 0, -cn, 'อัปเกรด ' || d.name || ' → Lv' || (sd.lvl + 1), null);
  update student_items set qty = qty - sc where student_id = sid and item_id = scid;
  update student_decor set lvl = lvl + 1 where student_id = sid and item_id = p_item;
  return json_build_object('name', d.name, 'lvl', sd.lvl + 1, 'main', _item_main(d.st_int, d.st_dil, d.st_str, d.st_luk));
end $$;

create or replace function admin_give_item(p_students uuid[], p_item uuid, p_qty int) returns int
language plpgsql security definer set search_path = public as $$
declare n int := 0; s uuid;
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  if p_qty is null or p_qty < 1 or p_qty > 50 then raise exception 'จำนวนไม่ถูกต้อง'; end if;
  if not exists (select 1 from consumables where id = p_item) then raise exception 'ไม่พบไอเทม'; end if;
  foreach s in array p_students loop
    insert into student_items (student_id, item_id, qty) values (s, p_item, p_qty)
      on conflict (student_id, item_id) do update set qty = student_items.qty + p_qty;
    n := n + 1;
  end loop;
  return n;
end $$;

revoke execute on function my_items(uuid), buy_item(uuid, uuid, int), use_item(uuid, uuid, uuid), upgrade_decor(uuid, uuid) from public;
grant execute on function my_items(uuid), buy_item(uuid, uuid, int), use_item(uuid, uuid, uuid), upgrade_decor(uuid, uuid) to anon, authenticated;
revoke execute on function admin_give_item(uuid[], uuid, int) from public, anon;
grant execute on function admin_give_item(uuid[], uuid, int) to authenticated;

-- ---------- ประกาศ ----------
insert into news_posts (kind, title, summary, body, image, sort, active)
select 'news', 'ไอเทมกดใช้ 🧪 ยา บัฟ ม้วนอัปเกรด + ปรับสมดุล',
  'ซื้อยาบัฟช่วยเก็บ EXP/เหรียญ/โชค · อัปเกรดเลเวลของสวมใส่ · SSR หายากขึ้น',
  E'🧪 แท็บใหม่ "ไอเทม" เปิดแล้ว!\n\n💊 ยาบัฟ (มีผลถึงสิ้นวัน ชนิดละ 1 ครั้ง/วัน)\n• 🧪 EXP +15% • 💰 เหรียญ +20% • 🍀 โชค +4 • ⚔️ ดาเมจบอส +15% • 🧠 EXP ควิซ +2\n💚 ยาฟื้นฟู HP ใช้ในศึกมอนสเตอร์ (2 ครั้ง/ศึก)\n🔄 ตั๋วล้างแต้มสเตตัส\n📜 ม้วนอัปเกรด ใช้อัปเกรดเลเวลของสวมใส่ ทุกเลเวล +1 สเตตัสหลักของไอเทมนั้น\n\n⚖️ ปรับสมดุลสเตตัสไอเทมไม่ให้แรงเกินไป (มีเพดานต่อชิ้นและเพดานรวม)\n🎰 ลดอัตราออก SSR ในกาชาลงอีก (จากราว 14% เหลือราว 3%)\n\nแวะไปดูที่แท็บ 🧪 ไอเทม ได้เลย',
  'assets/news/consumables.jpg', 46, true
where not exists (select 1 from news_posts where title like 'ไอเทมกดใช้%');
