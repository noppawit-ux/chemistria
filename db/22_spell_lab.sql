-- =====================================================================
-- Chemistria · รอบที่ 27: มินิเกม "ห้องฝึกเวทย์ผสมธาตุ" (รันซ้ำได้)
--  · ผสมอะตอมในหม้อต้มให้ได้สารตามคาถา (สูตรเคมี) · ตัวเกมอยู่ฝั่งเบราว์เซอร์ เซิร์ฟเวอร์ตรวจช่วงคะแนน/เวลา
--  · รางวัลนับรวมเพดาน EXP เกมต่อวัน (game_daily_cap_exp) · ตั้งค่า spell_plays_per_day, spell_max_exp ได้ที่แอดมิน
-- =====================================================================
insert into app_settings (key, value) values ('spell_max_exp', '10'), ('spell_plays_per_day', '3') on conflict (key) do nothing;

do $$ declare c text; begin
  for c in select conname from pg_constraint
           where conrelid = 'public.game_plays'::regclass and contype = 'c' and pg_get_constraintdef(oid) like '%game%quiz%' loop
    execute format('alter table game_plays drop constraint %I', c);
  end loop;
  alter table game_plays add constraint game_plays_game_check check (game in ('quiz', 'match', 'spell'));
end $$;

create or replace function spell_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); d date := today_th();
begin
  return json_build_object(
    'plays', (select count(*) from game_plays where student_id = sid and game = 'spell' and play_date = d),
    'max_plays', _setting_int('spell_plays_per_day', 3),
    'max_exp', _setting_int('spell_max_exp', 10),
    'best', (select max(score) from game_plays where student_id = sid and game = 'spell' and play_date = d));
end $$;

create or replace function spell_submit(p_token uuid, p_score int, p_spells int, p_seconds int) returns json
language plpgsql security definer set search_path = public as $$
declare
  sid uuid := _sid(p_token); d date := today_th(); n int; mx int; raw int; e int; c int := 0;
  cap int := _setting_int('game_daily_cap_exp', 40);
begin
  if p_score is null or p_score < 0 or p_score > 100 or p_spells not between 4 and 10 or p_seconds is null or p_seconds < p_spells * 2 then
    raise exception 'ผลการเล่นไม่ถูกต้อง';
  end if;
  select count(*) into n from game_plays where student_id = sid and game = 'spell' and play_date = d;
  mx := _setting_int('spell_plays_per_day', 3);
  raw := round(_setting_int('spell_max_exp', 10) * p_score / 100.0);
  if n >= mx then
    insert into game_plays (student_id, game, play_date, score, exp, coins) values (sid, 'spell', d, p_score, 0, 0);
    return json_build_object('exp', 0, 'coins', 0, 'score', p_score, 'capped', true, 'no_reward', true, 'plays', n + 1, 'max_plays', mx);
  end if;
  e := least(raw, greatest(0, cap - _game_exp_today(sid)));
  if p_score >= 90 then c := 1; end if;
  insert into game_plays (student_id, game, play_date, score, exp, coins) values (sid, 'spell', d, p_score, e, c);
  perform award(sid, e, c, 'ห้องฝึกเวทย์ผสมธาตุ (' || p_score || ' คะแนน)', 'game:spell:' || d || ':' || (n + 1));
  return json_build_object('exp', e, 'coins', c, 'score', p_score, 'capped', e < raw, 'no_reward', false, 'plays', n + 1, 'max_plays', mx);
end $$;

revoke execute on function spell_status(uuid), spell_submit(uuid, int, int, int) from public;
grant execute on function spell_status(uuid), spell_submit(uuid, int, int, int) to anon, authenticated;
