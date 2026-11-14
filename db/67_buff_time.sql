-- 67: บัฟมีเวลาจำกัด (นาที) แทนถึงสิ้นวัน + ส่ง lv ของอุปกรณ์ให้หน้าจอ (v2.01) · รันซ้ำได้
--  · ระยะเวลาต่อไอเทมอยู่ที่ consumables.minutes (ค่าเริ่มต้น: EXP/เหรียญ 60 · โชค 30 · ดาเมจบอส/ปัญญา 45) ครูแก้ได้ในแอดมิน
--  · บัฟชนิดเดียวกันใช้ซ้อนไม่ได้ขณะยังไม่หมดเวลา (หมดแล้วใช้ใหม่ได้)
alter table consumables add column if not exists minutes int not null default 60 check (minutes between 5 and 1440);
alter table student_buffs add column if not exists expires_at timestamptz not null default now();
update consumables set minutes = 60 where key in ('p_exp', 'p_coin');
update consumables set minutes = 30 where key = 'p_luck';
update consumables set minutes = 45 where key in ('p_str', 'p_int');
update consumables set descr = replace(descr, 'ถึงสิ้นวัน', 'นาน ' || minutes || ' นาที') where kind like 'buff\_%' and descr like '%ถึงสิ้นวัน%';

-- _stats: นับเฉพาะบัฟที่ยังไม่หมดเวลา
do $$ declare d text; n text; begin
  d := pg_get_functiondef('_stats(uuid)'::regprocedure);
  if d like '%day = today_th()%' then
    n := replace(d, 'where student_id = p_sid and day = today_th()', 'where student_id = p_sid and expires_at > now()');
    n := replace(n, 'json_build_object(''kind'', kind, ''power'', power)', 'json_build_object(''kind'', kind, ''power'', power, ''until'', expires_at)');
    if n = d or n not like '%expires_at > now()%' then raise exception '_stats: ไม่พบข้อความที่ต้องแก้ (ต้องรัน 66 ก่อน)'; end if;
    execute n;
  end if;
end $$;
revoke execute on function _stats(uuid) from public, anon, authenticated;

-- ใช้ไอเทม
create or replace function use_item(p_token uuid, p_item uuid, p_battle uuid default null) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); c consumables%rowtype; q int; b battles%rowtype; add int; msg text;
begin
  select * into c from consumables where id = p_item and active;
  if not found then raise exception 'ไม่พบไอเทม'; end if;
  if c.kind = 'scroll' then raise exception 'ม้วนอัปเกรด: เลือกอุปกรณ์ที่ต้องการอัปเกรดในหน้าไอเทม'; end if;
  perform 1 from students where id = sid for update;
  select qty into q from student_items where student_id = sid and item_id = c.id for update;
  if coalesce(q, 0) < 1 then raise exception 'ไม่มีไอเทมนี้ในคลัง'; end if;
  if c.kind like 'buff\_%' then
    if exists (select 1 from student_buffs where student_id = sid and kind = c.kind and expires_at > now()) then raise exception 'บัฟชนิดนี้ยังมีผลอยู่ (ซ้อนกันไม่ได้)'; end if;
    insert into student_buffs (student_id, kind, power, day, expires_at) values (sid, c.kind, c.power, today_th(), now() + make_interval(mins => c.minutes))
      on conflict (student_id, kind) do update set power = excluded.power, day = excluded.day, expires_at = excluded.expires_at;
    msg := c.name || ' มีผล ' || c.minutes || ' นาที';
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

-- รายการไอเทม/อุปกรณ์ของฉัน
create or replace function my_items(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); today date := today_th(); res json;
begin
  select json_build_object(
    'coins', (select coins from students where id = sid),
    'items', coalesce((select json_agg(json_build_object('id', c.id, 'key', c.key, 'name', c.name, 'emoji', c.emoji, 'image', c.image, 'rarity', c.rarity, 'kind', c.kind,
              'power', c.power, 'price', c.price, 'descr', c.descr, 'minutes', c.minutes, 'qty', coalesce(si.qty, 0), 'daily_buy', c.daily_buy,
              'bought', coalesce(idl.bought, 0),
              'active_until', (select b.expires_at from student_buffs b where b.student_id = sid and b.kind = c.kind and b.expires_at > now())) order by c.sort, c.name)
         from consumables c left join student_items si on si.item_id = c.id and si.student_id = sid
         left join item_daily idl on idl.item_id = c.id and idl.student_id = sid and idl.day = today where c.active), '[]'::json),
    'buffs', (_stats(sid)->'buffs'),
    'gear', coalesce((select json_agg(json_build_object('id', d.id, 'name', d.name, 'emoji', d.emoji, 'image', d.image, 'slot', d.slot, 'rarity', d.rarity, 'lvl', sd.lvl,
              'ability', d.ability, 'coin', d.st_coin,
              'main', _item_main(d.st_int, d.st_dil, d.st_str, d.st_luk),
              'stats', json_build_object('int', d.st_int, 'dil', d.st_dil, 'str', d.st_str, 'luk', d.st_luk),
              'equipped', (select s.decor->>d.slot = d.id::text from students s where s.id = sid),
              'cost', _upg_cost(d.rarity, sd.lvl)) order by (d.rarity = 'LEG') desc, d.rarity desc, d.name)
         from student_decor sd join decor_items d on d.id = sd.item_id where sd.student_id = sid), '[]'::json)
  ) into res;
  return res;
end $$;

-- _decor_of: ส่ง lv ของอุปกรณ์ที่สวมอยู่
create or replace function _decor_of(p_sid uuid) returns json
language sql stable security definer set search_path = public as $$
  select (coalesce((select json_object_agg(d.slot, json_build_object('id', d.id, 'key', d.key, 'color', d.color,
           'emoji', d.emoji, 'name', d.name, 'rarity', d.rarity, 'image', d.image, 'lvl', coalesce(sd.lvl, 1)))
    from students s
    cross join lateral jsonb_each_text(s.decor) e
    join decor_items d on d.id = e.value::uuid and d.slot = e.key
    left join student_decor sd on sd.student_id = s.id and sd.item_id = d.id
   where s.id = p_sid), '{}'::json)::jsonb
   || jsonb_build_object('gender', (select gender from students where id = p_sid)))::json
$$;
revoke execute on function _decor_of(uuid) from public, anon, authenticated;
revoke execute on function my_items(uuid), use_item(uuid, uuid, uuid) from public;
grant execute on function my_items(uuid), use_item(uuid, uuid, uuid) to anon, authenticated;

update news_posts set body = replace(body, 'บัฟมีผลถึงสิ้นวัน ชนิดละ 1 ครั้ง/วัน', 'บัฟมีผลตามเวลา (30–60 นาที)') where title like 'ไอเทมกดใช้%';
