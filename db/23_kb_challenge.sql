-- =====================================================================
-- Chemistria · รอบที่ 33: โหมด "ประลองครูบุ๊ค" (Extremely Hard) (รันซ้ำได้)
--  · 8 รอบ หลายมินิเกม เวลาลดลงเรื่อยๆ · ตัวเกมอยู่ฝั่งเบราว์เซอร์ เซิร์ฟเวอร์ตรวจช่วงผลและจำกัดรอบ/วัน
--  · รางวัลไม่นับรวมเพดาน EXP เกมต่อวัน แต่จำกัดจำนวนรอบ/วัน (kb_plays_per_day)
-- =====================================================================
insert into app_settings (key, value) values ('kb_plays_per_day', '2'), ('kb_exp_per_round', '2'), ('kb_win_exp', '10'), ('kb_win_coins', '5') on conflict (key) do nothing;

do $$ declare c text; begin
  for c in select conname from pg_constraint
           where conrelid = 'public.game_plays'::regclass and contype = 'c' and pg_get_constraintdef(oid) like '%game%quiz%' loop
    execute format('alter table game_plays drop constraint %I', c);
  end loop;
  alter table game_plays add constraint game_plays_game_check check (game in ('quiz', 'match', 'spell', 'kb'));
end $$;

create or replace function kb_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); d date := today_th();
begin
  return json_build_object(
    'plays', (select count(*) from game_plays where student_id = sid and game = 'kb' and play_date = d),
    'max_plays', _setting_int('kb_plays_per_day', 2),
    'per_round', _setting_int('kb_exp_per_round', 2), 'win_exp', _setting_int('kb_win_exp', 10), 'win_coins', _setting_int('kb_win_coins', 5),
    'wins', (select count(*) from game_plays where student_id = sid and game = 'kb' and score = 100),
    'best', (select max(score) from game_plays where student_id = sid and game = 'kb'));
end $$;

-- p_cleared = จำนวนรอบที่ผ่าน (0-8), p_won = ชนะครูบุ๊ค (ผ่านครบ 8 รอบ)
create or replace function kb_submit(p_token uuid, p_cleared int, p_won boolean, p_seconds int) returns json
language plpgsql security definer set search_path = public as $$
declare
  sid uuid := _sid(p_token); d date := today_th(); n int; mx int; e int; c int := 0; sc int;
begin
  if p_cleared is null or p_cleared not between 0 and 8 or p_won is null or (p_won and p_cleared <> 8) or p_seconds is null or p_seconds < p_cleared * 3 then
    raise exception 'ผลการเล่นไม่ถูกต้อง';
  end if;
  sc := case when p_won then 100 else p_cleared * 12 end;
  select count(*) into n from game_plays where student_id = sid and game = 'kb' and play_date = d;
  mx := _setting_int('kb_plays_per_day', 2);
  if n >= mx then
    insert into game_plays (student_id, game, play_date, score, exp, coins) values (sid, 'kb', d, sc, 0, 0);
    return json_build_object('exp', 0, 'coins', 0, 'cleared', p_cleared, 'won', p_won, 'no_reward', true, 'plays', n + 1, 'max_plays', mx);
  end if;
  e := p_cleared * _setting_int('kb_exp_per_round', 2) + (case when p_won then _setting_int('kb_win_exp', 10) else 0 end);
  if p_won then c := _setting_int('kb_win_coins', 5); end if;
  insert into game_plays (student_id, game, play_date, score, exp, coins) values (sid, 'kb', d, sc, e, c);
  perform award(sid, e, c, case when p_won then 'ชนะการประลองครูบุ๊ค 🏆' else 'ประลองครูบุ๊ค (ผ่าน ' || p_cleared || '/8 รอบ)' end, 'game:kb:' || d || ':' || (n + 1));
  return json_build_object('exp', e, 'coins', c, 'cleared', p_cleared, 'won', p_won, 'no_reward', false, 'plays', n + 1, 'max_plays', mx);
end $$;

revoke execute on function kb_status(uuid), kb_submit(uuid, int, boolean, int) from public;
grant execute on function kb_status(uuid), kb_submit(uuid, int, boolean, int) to anon, authenticated;
