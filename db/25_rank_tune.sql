-- 25: ปรับอัตราการได้ EXP และเกณฑ์แรงค์ (แรงค์ขึ้นช้าลง)
-- 1) เกณฑ์แรงค์ใหม่ (เปลี่ยนเฉพาะแรงค์ที่ยังเป็นค่าเริ่มต้น ถ้าครูเคยแก้เองจะไม่ทับ)
update ch_ranks r set min_exp = v.new_exp
  from (values ('bronze',100,250),('silver',250,600),('gold',450,1100),('platinum',700,1800),('emerald',1000,2700),
               ('diamond',1400,3900),('master',1900,5400),('grandmaster',2500,7200),('challenger',3200,9500)) v(key, old_exp, new_exp)
 where r.key = v.key and r.min_exp = v.old_exp;

-- 2) ลดรายได้ EXP จากเกม (เปลี่ยนเฉพาะค่าที่ยังเป็นค่าเริ่มต้น)
update app_settings set value = '25' where key = 'game_daily_cap_exp' and value = '40';
update app_settings set value = '1'  where key = 'kb_exp_per_round' and value = '2';
update app_settings set value = '6'  where key = 'kb_win_exp' and value = '10';
update app_settings set value = '2'  where key = 'battle_rewards_per_day' and value = '3';
update app_settings set value = '3'  where key = 'duel_rewards_per_day' and value = '5';
insert into app_settings (key, value) values ('kb_exp_per_round','1'),('kb_win_exp','6') on conflict (key) do nothing;

-- 3) ประลองครูบุ๊คนับรวมในเพดาน EXP เกมรายวันด้วย
create or replace function kb_submit(p_token uuid, p_cleared int, p_won boolean, p_seconds int) returns json
language plpgsql security definer set search_path = public as $$
declare
  sid uuid := _sid(p_token); d date := today_th(); n int; mx int; e int; c int := 0; sc int; raw int; cap int := _setting_int('game_daily_cap_exp', 25);
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
  raw := p_cleared * _setting_int('kb_exp_per_round', 1) + (case when p_won then _setting_int('kb_win_exp', 6) else 0 end);
  e := least(raw, greatest(0, cap - _game_exp_today(sid)));
  if p_won then c := _setting_int('kb_win_coins', 5); end if;
  insert into game_plays (student_id, game, play_date, score, exp, coins) values (sid, 'kb', d, sc, e, c);
  perform award(sid, e, c, case when p_won then 'ชนะการประลองครูบุ๊ค 🏆' else 'ประลองครูบุ๊ค (ผ่าน ' || p_cleared || '/8 รอบ)' end, 'game:kb:' || d || ':' || (n + 1));
  return json_build_object('exp', e, 'coins', c, 'cleared', p_cleared, 'won', p_won, 'no_reward', false, 'capped', e < raw, 'plays', n + 1, 'max_plays', mx);
end $$;
