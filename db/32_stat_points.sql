-- 32: แต้มสเตตัส (Status Point) — เลเวลอัพได้แต้ม แจกให้ ปัญญา/ขยัน/พลังโจมตี/โชค ได้เอง (รันซ้ำได้)
--  · แต้มทั้งหมด = (เลเวล − 1) × stat_pts_per_level (ค่าเริ่มต้น 2) · ใส่ได้ด้านละไม่เกิน stat_alloc_cap (ค่าเริ่มต้น 15)
--  · รีเซ็ตแต้มได้โดยเสียเหรียญ stat_reset_cost (ค่าเริ่มต้น 100) · แต้มที่ใส่นับรวมในทุกโบนัสผ่าน _stats()
insert into app_settings (key, value) values ('stat_pts_per_level', '2'), ('stat_alloc_cap', '15'), ('stat_reset_cost', '100') on conflict (key) do nothing;
alter table students add column if not exists stat_pts jsonb not null default '{}'::jsonb;

create or replace function _stats(p_sid uuid) returns json
language plpgsql stable security definer set search_path = public as $$
declare
  b_int int; b_dil int; b_str int; b_luk int;
  i_int int := 0; i_dil int := 0; i_str int := 0; i_luk int := 0; i_coin int := 0;
  p_int int; p_dil int; p_str int; p_luk int; cap int := _setting_int('stat_alloc_cap', 15);
  sp jsonb; lv int; tot int; per int := _setting_int('stat_pts_per_level', 2);
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
  select coalesce(sum(d.st_int), 0), coalesce(sum(d.st_dil), 0), coalesce(sum(d.st_str), 0), coalesce(sum(d.st_luk), 0), coalesce(sum(d.st_coin), 0)
    into i_int, i_dil, i_str, i_luk, i_coin
    from students s
    cross join lateral jsonb_each_text(s.decor) e
    join decor_items d on d.id = e.value::uuid and d.slot = e.key
   where s.id = p_sid;
  return json_build_object(
    'int', json_build_object('base', b_int, 'pts', p_int, 'item', i_int, 'total', b_int + p_int + i_int),
    'dil', json_build_object('base', b_dil, 'pts', p_dil, 'item', i_dil, 'total', b_dil + p_dil + i_dil),
    'str', json_build_object('base', b_str, 'pts', p_str, 'item', i_str, 'total', b_str + p_str + i_str),
    'luk', json_build_object('base', b_luk, 'pts', p_luk, 'item', i_luk, 'total', b_luk + p_luk + i_luk),
    'points', json_build_object('total', tot, 'spent', p_int + p_dil + p_str + p_luk, 'left', greatest(0, tot - (p_int + p_dil + p_str + p_luk)),
                                'cap', cap, 'per_level', per, 'reset_cost', _setting_int('stat_reset_cost', 100)),
    'effects', json_build_object('quiz_exp', (b_int + p_int + i_int) / 2, 'exp_pct', b_dil + p_dil + i_dil,
                                 'boss_pct', 3 * (b_str + p_str + i_str), 'rare_pct', 3 * (b_luk + p_luk + i_luk), 'coin_pct', i_coin));
end $$;
revoke execute on function _stats(uuid) from public, anon, authenticated;

-- เพิ่มแต้มให้สเตตัส 1 ด้าน (p_stat = int|dil|str|luk) ครั้งละ p_n แต้ม
create or replace function stat_add(p_token uuid, p_stat text, p_n int default 1) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); st json; left_ int; cur int; cap int := _setting_int('stat_alloc_cap', 15);
begin
  if p_stat not in ('int','dil','str','luk') then raise exception 'สเตตัสไม่ถูกต้อง'; end if;
  if p_n is null or p_n < 1 or p_n > 20 then raise exception 'จำนวนแต้มไม่ถูกต้อง'; end if;
  perform 1 from students where id = sid for update;
  st := _stats(sid); left_ := (st->'points'->>'left')::int; cur := (st->p_stat->>'pts')::int;
  if left_ < p_n then raise exception 'แต้มสเตตัสไม่พอ'; end if;
  if cur + p_n > cap then raise exception 'ด้านนี้ใส่ได้สูงสุด % แต้ม', cap; end if;
  update students set stat_pts = jsonb_set(coalesce(stat_pts, '{}'::jsonb), array[p_stat], to_jsonb(cur + p_n)) where id = sid;
  return _stats(sid);
end $$;

-- รีเซ็ตแต้มที่ใส่ไว้ทั้งหมด (เสียเหรียญ)
create or replace function stat_reset(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cost int := _setting_int('stat_reset_cost', 100); have int; st json;
begin
  perform 1 from students where id = sid for update;
  st := _stats(sid);
  if (st->'points'->>'spent')::int = 0 then raise exception 'ยังไม่ได้ใส่แต้มสเตตัส'; end if;
  select coins into have from students where id = sid;
  if have < cost then raise exception 'เหรียญไม่พอ (ต้องใช้ % เหรียญ)', cost; end if;
  perform award(sid, 0, -cost, 'รีเซ็ตแต้มสเตตัส', 'statreset:' || sid || ':' || extract(epoch from clock_timestamp())::bigint || ':' || floor(random()*1e6)::int);
  update students set stat_pts = '{}'::jsonb where id = sid;
  return _stats(sid);
end $$;

revoke execute on function stat_add(uuid, text, int), stat_reset(uuid) from public;
grant execute on function stat_add(uuid, text, int), stat_reset(uuid) to anon, authenticated;
