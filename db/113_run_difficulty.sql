-- SQL 113 · เคมีรัน: ระดับความยากของแต่ละด่าน (⭐1–5) + โบนัส EXP ตามความยาก (คำนวณที่เซิร์ฟเวอร์)
--   · ไม่แก้ run_submit เดิม: ฟังก์ชันใหม่ run_submit_v2(token, score, seconds, stage) เรียก run_submit แล้วเติมโบนัส
--   · โบนัส = EXP ที่ได้จากรอบนั้น × bonus_pct/100 (ปัดเศษ) · ไม่เกินเพดาน EXP จากเกมต่อวัน · ไม่ได้ EXP รอบนั้น = ไม่มีโบนัส
--   · ครูแก้ดาว/โบนัสได้ที่ตาราง run_stages · รันซ้ำได้
create table if not exists run_stages (
  stage text primary key, name text not null, stars int not null check (stars between 1 and 5),
  bonus_pct int not null default 0 check (bonus_pct between 0 and 100), sort int not null default 0);
alter table run_stages enable row level security;
drop policy if exists teacher_all on run_stages;
create policy teacher_all on run_stages for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on run_stages from anon;
grant select, insert, update, delete on run_stages to authenticated;

insert into run_stages (stage, name, stars, bonus_pct, sort) values
  ('lab', 'ห้องแล็บ', 1, 0, 1), ('sea', 'ทะเลหลากสี', 2, 10, 2), ('fall', 'น้ำตกเวทมนตร์', 2, 10, 3),
  ('mtn', 'ภูเขายามเช้า', 3, 20, 4), ('night', 'ป่าเงียบยามค่ำ', 3, 20, 5),
  ('space', 'อวกาศ', 4, 35, 6), ('ice', 'ธารน้ำแข็ง', 5, 50, 7), ('rand', 'สุ่มด่าน', 3, 15, 8)
on conflict (stage) do nothing;

create or replace function run_stage_info(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
begin
  perform _sid(p_token);
  return (select coalesce(json_object_agg(stage, json_build_object('stars', stars, 'bonus_pct', bonus_pct)), '{}'::json) from run_stages);
end $$;

create or replace function run_submit_v2(p_token uuid, p_score int, p_seconds int, p_stage text) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); d date := today_th(); r jsonb; rs run_stages%rowtype; e int; bonus int := 0;
        cap int := _setting_int('game_daily_cap_exp', 25); room int; pid uuid;
begin
  r := run_submit(p_token, p_score, p_seconds)::jsonb;
  select * into rs from run_stages where stage = coalesce(p_stage, 'rand');
  if not found then select * into rs from run_stages where stage = 'rand'; end if;
  e := coalesce((r->>'exp')::int, 0);
  if found and e > 0 and coalesce((r->>'no_reward')::boolean, false) = false and rs.bonus_pct > 0 then
    room := greatest(0, cap - _game_exp_today(sid));
    bonus := least(round(e * rs.bonus_pct / 100.0)::int, room);
    if bonus > 0 then
      select id into pid from game_plays where student_id = sid and game = 'run' and play_date = d order by created_at desc limit 1;
      update game_plays set exp = exp + bonus where id = pid;
      perform award(sid, bonus, 0, 'เคมีรัน โบนัสด่าน ' || rs.name || ' ' || repeat('⭐', rs.stars), 'game:runbonus:' || pid);
    end if;
  end if;
  return (r || jsonb_build_object('bonus', bonus, 'stars', coalesce(rs.stars, 1), 'stage', coalesce(rs.stage, 'rand')))::json;
end $$;

revoke execute on function run_stage_info(uuid), run_submit_v2(uuid, int, int, text) from public;
grant execute on function run_stage_info(uuid), run_submit_v2(uuid, int, int, text) to anon, authenticated;
