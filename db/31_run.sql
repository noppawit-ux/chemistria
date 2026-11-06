-- 31: มินิเกม "เคมีรัน" (วิ่งเก็บเหรียญหลบอุปสรรค สไตล์ Cookie Run) (รันซ้ำได้)
--  · ตัวเกมอยู่ฝั่งเบราว์เซอร์ เซิร์ฟเวอร์ตรวจความสมเหตุสมผลของคะแนน/เวลา · รางวัลนับรวมเพดาน EXP เกมต่อวัน
--  · ตั้งค่าได้: run_plays_per_day (รอบที่ได้รางวัล/วัน) · run_max_exp (EXP สูงสุด/รอบ) · run_target_score (คะแนนที่ได้เต็ม)
insert into app_settings (key, value) values ('run_plays_per_day', '3'), ('run_max_exp', '10'), ('run_target_score', '2500') on conflict (key) do nothing;

do $$ declare c text; begin
  for c in select conname from pg_constraint
           where conrelid = 'public.game_plays'::regclass and contype = 'c' and pg_get_constraintdef(oid) like '%game%quiz%' loop
    execute format('alter table game_plays drop constraint %I', c);
  end loop;
  alter table game_plays add constraint game_plays_game_check check (game in ('quiz', 'match', 'spell', 'kb', 'run'));
end $$;

create or replace function run_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); d date := today_th();
begin
  return json_build_object(
    'plays', (select count(*) from game_plays where student_id = sid and game = 'run' and play_date = d),
    'max_plays', _setting_int('run_plays_per_day', 3),
    'max_exp', _setting_int('run_max_exp', 10),
    'target', _setting_int('run_target_score', 2500),
    'best', (select max(score) from game_plays where student_id = sid and game = 'run'));
end $$;

-- p_score = คะแนนรวม (ระยะทาง + เหรียญ + ธาตุ) · p_seconds = เวลาที่เล่นจริง
create or replace function run_submit(p_token uuid, p_score int, p_seconds int) returns json
language plpgsql security definer set search_path = public as $$
declare
  sid uuid := _sid(p_token); d date := today_th(); n int; mx int; tg int; raw int; e int; c int := 0;
  cap int := _setting_int('game_daily_cap_exp', 25);
begin
  if p_score is null or p_seconds is null or p_score < 0 or p_seconds < 5 or p_seconds > 1200 or p_score > p_seconds * 160 + 100 then
    raise exception 'ผลการเล่นไม่ถูกต้อง';
  end if;
  select count(*) into n from game_plays where student_id = sid and game = 'run' and play_date = d;
  mx := _setting_int('run_plays_per_day', 3); tg := greatest(1, _setting_int('run_target_score', 2500));
  raw := round(_setting_int('run_max_exp', 10) * least(1.0, p_score::numeric / tg));
  if n >= mx then
    insert into game_plays (student_id, game, play_date, score, exp, coins) values (sid, 'run', d, p_score, 0, 0);
    return json_build_object('exp', 0, 'coins', 0, 'score', p_score, 'capped', true, 'no_reward', true, 'plays', n + 1, 'max_plays', mx);
  end if;
  e := least(raw, greatest(0, cap - _game_exp_today(sid)));
  if p_score >= tg then c := 1; end if;
  insert into game_plays (student_id, game, play_date, score, exp, coins) values (sid, 'run', d, p_score, e, c);
  perform award(sid, e, c, 'เคมีรัน (' || p_score || ' คะแนน)', 'game:run:' || d || ':' || (n + 1));
  return json_build_object('exp', e, 'coins', c, 'score', p_score, 'capped', e < raw, 'no_reward', false, 'plays', n + 1, 'max_plays', mx);
end $$;

revoke execute on function run_status(uuid), run_submit(uuid, int, int) from public;
grant execute on function run_status(uuid), run_submit(uuid, int, int) to anon, authenticated;

-- ให้โหมดส่องนักเรียนเรียก run_status ได้ (อ่านอย่างเดียว)
create or replace function _sid(p_token uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare v uuid; o boolean; fn text;
begin
  select student_id, observer into v, o from student_sessions where token = p_token and expires_at > now();
  if v is null then raise exception 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่'; end if;
  if o then
    fn := regexp_replace(coalesce(current_setting('request.path', true), ''), '^.*/', '');
    if fn not in ('student_dashboard','student_extras','hall_of_fame','board_list','celebrations_feed','game_status','spell_status','kb_status','news_list','run_status') then
      raise exception 'โหมดส่องนักเรียน: ดูได้อย่างเดียว';
    end if;
  end if;
  return v;
end $$;
