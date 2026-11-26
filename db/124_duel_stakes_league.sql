-- SQL 124 · ประลอง: ท้าดวลมีเดิมพัน 💰 + ลีกประลองรายสัปดาห์ 🏆
-- ต้องรันหลัง 123 · รันซ้ำได้ · ไม่แก้ฟังก์ชัน duel_* / award / battle_* เดิม (ใช้ trigger บนตาราง duels + RPC ใหม่)
-- เดิมพัน: ผู้ท้าเลือกเดิมพันเหรียญ (0–duel_stake_max) → ตอนอีกฝ่ายกดรับ ระบบหักเหรียญทั้งสองฝ่ายไว้ (เหรียญไม่พอ = กดรับไม่ได้)
--          จบดวล (≥3 รอบ) ผู้ชนะได้เหรียญทั้งกอง + EXP โบนัส · เสมอ/ออกก่อน 3 รอบ/ยกเลิก = คืนเดิมพันทั้งคู่
-- ผู้ท้าชิง: ผู้ชนะที่ EXP ต่ำกว่าคู่ต่อสู้ (< duel_underdog_pct %) ได้ EXP โบนัสเพิ่ม (ดวลที่นับเท่านั้น)
-- ลีก: ทุกดวลที่นับ (≥3 รอบ, ไม่เกิน league_per_day/วัน, คู่เดิมไม่เกิน league_same/วัน) เก็บแต้มรายสัปดาห์ (จันทร์–อาทิตย์)
--      ชนะ +league_win · เสมอ +league_draw · แพ้ +league_loss · ชนะคนที่แต้มสูงกว่า = โบนัสล้มยักษ์
--      จบสัปดาห์: อันดับ 1–3 ของห้อง (แต้ม ≥ league_min_pts) ได้ EXP + เหรียญ ref league:* (ไม่ถูกเพดานเล่นต่อวัน)

insert into app_settings(key, value) values
  ('duel_stake_max', '30'), ('duel_stake_per_day', '3'), ('duel_stake_win_exp', '8'),
  ('duel_underdog_exp', '6'), ('duel_underdog_pct', '75'),
  ('league_win', '30'), ('league_draw', '10'), ('league_loss', '5'), ('league_upset_max', '20'),
  ('league_per_day', '6'), ('league_same', '2'), ('league_min_pts', '30'),
  ('league_r1_exp', '80'), ('league_r1_coins', '60'), ('league_r2_exp', '50'), ('league_r2_coins', '40'),
  ('league_r3_exp', '30'), ('league_r3_coins', '25')
on conflict (key) do nothing;

alter table duels add column if not exists stake int not null default 0 check (stake >= 0);
alter table duels add column if not exists stake_held boolean not null default false;
alter table duels add column if not exists pot_done boolean not null default false;

create table if not exists league_points (
  season date not null, student_id uuid not null references students(id) on delete cascade, class_id uuid not null,
  pts int not null default 0, wins int not null default 0, draws int not null default 0, losses int not null default 0,
  primary key (season, student_id));
create table if not exists league_log (
  duel_id uuid not null references duels(id) on delete cascade, student_id uuid not null references students(id) on delete cascade,
  opp uuid not null, day date not null default today_th(), season date not null,
  result text not null check (result in ('win', 'draw', 'loss')), pts int not null, upset int not null default 0,
  primary key (duel_id, student_id));
create index if not exists idx_league_log_day on league_log (student_id, day);
create table if not exists league_results (
  season date not null, student_id uuid not null references students(id) on delete cascade, class_id uuid not null,
  rank int not null, pts int not null, exp int not null default 0, coins int not null default 0,
  primary key (season, student_id));
create table if not exists league_done (season date primary key, done_at timestamptz not null default now());
do $$ declare t text; begin
  foreach t in array array['league_points', 'league_log', 'league_results', 'league_done'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists teacher_all on public.%I', t);
    execute format('create policy teacher_all on public.%I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on public.%I from anon', t);
  end loop; end $$;

create or replace function _league_season() returns date
language sql stable as $$ select date_trunc('week', today_th()::timestamp)::date $$;

-- ---------- ล็อกเดิมพันตอนกดรับ (BEFORE) ----------
create or replace function trg_duel_stake_hold() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if old.status = 'invited' and new.status = 'active' and new.stake > 0 and not new.stake_held then
    if (select coins from students where id = new.a_id) < new.stake then raise exception 'ผู้ท้ามีเหรียญไม่พอสำหรับเดิมพัน % เหรียญ', new.stake; end if;
    if (select coins from students where id = new.b_id) < new.stake then raise exception 'เหรียญไม่พอสำหรับเดิมพัน % เหรียญ (ปฏิเสธคำท้าได้)', new.stake; end if;
    perform award(new.a_id, 0, -new.stake, 'เดิมพันท้าดวล (หักไว้)', 'duelstake:' || new.id || ':' || new.a_id);
    perform award(new.b_id, 0, -new.stake, 'เดิมพันท้าดวล (หักไว้)', 'duelstake:' || new.id || ':' || new.b_id);
    new.stake_held := true;
  end if;
  return new;
end $$;
drop trigger if exists trg_duel_stake_hold on duels;
create trigger trg_duel_stake_hold before update of status on duels for each row execute function trg_duel_stake_hold();

-- ---------- สรุปแต้มลีก + โบนัสผู้ท้าชิง ----------
create or replace function _duel_post_player(d duels, p uuid, o uuid, res text) returns void
language plpgsql security definer set search_path = public as $$
declare ssn date := _league_season(); lim int := _setting_int('league_per_day', 6); same int := _setting_int('league_same', 2);
        n_day int; n_same int; mine int; theirs int; gain int; up int := 0; cls uuid;
begin
  if d.round < 3 then return; end if;
  select count(*) into n_day from league_log where student_id = p and day = today_th() and duel_id <> d.id;
  select count(*) into n_same from league_log where student_id = p and opp = o and day = today_th() and duel_id <> d.id;
  if n_day >= lim or n_same >= same then return; end if;
  select class_id into cls from students where id = p;
  select coalesce(max(lp.pts), 0) into mine from league_points lp where lp.season = ssn and lp.student_id = p;
  select coalesce(max(lp.pts), 0) into theirs from league_points lp where lp.season = ssn and lp.student_id = o;
  gain := case res when 'win' then _setting_int('league_win', 30) when 'draw' then _setting_int('league_draw', 10) else _setting_int('league_loss', 5) end;
  if res = 'win' and theirs > mine then up := least(_setting_int('league_upset_max', 20), 10 + (theirs - mine) / 10); end if;
  insert into league_log (duel_id, student_id, opp, season, result, pts, upset) values (d.id, p, o, ssn, res, gain + up, up) on conflict do nothing;
  if not found then return; end if;
  insert into league_points (season, student_id, class_id, pts, wins, draws, losses)
  values (ssn, p, cls, gain + up, (res = 'win')::int, (res = 'draw')::int, (res = 'loss')::int)
  on conflict (season, student_id) do update set pts = league_points.pts + excluded.pts, wins = league_points.wins + excluded.wins,
     draws = league_points.draws + excluded.draws, losses = league_points.losses + excluded.losses;
  if res = 'win' and (select exp from students where id = p) < (select exp from students where id = o) * _setting_int('duel_underdog_pct', 75) / 100.0 then
    perform award(p, _setting_int('duel_underdog_exp', 6), 0, 'โบนัสผู้ท้าชิง ล้มยักษ์ ⚔️', 'duelup:' || d.id || ':' || p);
  end if;
end $$;

-- ---------- ปิดดวล (AFTER): จ่ายกองเดิมพัน/คืนเดิมพัน + แต้มลีก ----------
create or replace function trg_duel_settle() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if old.status = 'active' and new.status <> 'active' then
    if new.stake_held and not new.pot_done then
      if new.status = 'done' and new.round >= 3 and new.winner is not null then
        perform award(new.winner, _setting_int('duel_stake_win_exp', 8), new.stake * 2, 'ชนะเดิมพันท้าดวล 💰', 'duelpot:' || new.id || ':' || new.winner);
      else
        perform award(new.a_id, 0, new.stake, 'คืนเดิมพันท้าดวล', 'duelrefund:' || new.id || ':' || new.a_id);
        perform award(new.b_id, 0, new.stake, 'คืนเดิมพันท้าดวล', 'duelrefund:' || new.id || ':' || new.b_id);
      end if;
      update duels set pot_done = true where id = new.id;
    end if;
    if new.status = 'done' then
      perform _duel_post_player(new, new.a_id, new.b_id, case when new.winner is null then 'draw' when new.winner = new.a_id then 'win' else 'loss' end);
      perform _duel_post_player(new, new.b_id, new.a_id, case when new.winner is null then 'draw' when new.winner = new.b_id then 'win' else 'loss' end);
    end if;
  end if;
  return null;
end $$;
drop trigger if exists trg_duel_settle on duels;
create trigger trg_duel_settle after update of status on duels for each row execute function trg_duel_settle();

-- ---------- ท้าดวลพร้อมเดิมพัน ----------
create or replace function duel_invite2(p_token uuid, p_to uuid, p_arena text, p_stake int default 0) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); st int := greatest(0, coalesce(p_stake, 0)); mx int := _setting_int('duel_stake_max', 30); r json;
begin
  if st > mx then raise exception 'เดิมพันสูงสุด % เหรียญ', mx; end if;
  if st > 0 then
    if (select coins from students where id = sid) < st then raise exception 'เหรียญไม่พอสำหรับเดิมพัน'; end if;
    if (select count(*) from duels x where x.play_date = today_th() and x.stake > 0 and x.status in ('active', 'done') and (x.a_id = sid or x.b_id = sid)) >= _setting_int('duel_stake_per_day', 3)
      then raise exception 'วันนี้เล่นดวลเดิมพันครบ % ครั้งแล้ว', _setting_int('duel_stake_per_day', 3); end if;
  end if;
  r := duel_invite(p_token, p_to, p_arena);
  update duels set stake = st where id = (r->>'id')::uuid;
  return json_build_object('id', r->>'id', 'stake', st);
end $$;

-- เดิมพันของคำท้า/ดวลที่เกี่ยวข้องกับฉัน (invited/active) + ผลดวลล่าสุด
create or replace function duel_stakes(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  return (select coalesce(json_agg(json_build_object('id', d.id, 'stake', d.stake, 'status', d.status, 'held', d.stake_held,
      'lp', (select l.pts from league_log l where l.duel_id = d.id and l.student_id = sid),
      'upset', (select l.upset from league_log l where l.duel_id = d.id and l.student_id = sid),
      'up_exp', (select coalesce(sum(exp), 0) from ledger where student_id = sid and ref_key = 'duelup:' || d.id || ':' || sid),
      'won', d.winner = sid)), '[]'::json)
    from duels d where (d.a_id = sid or d.b_id = sid) and (d.status in ('invited', 'active') or (d.status = 'done' and d.finished_at > now() - interval '10 minutes')));
end $$;

-- ---------- ปิดฤดูกาลที่จบแล้ว ----------
create or replace function _league_finalize_old() returns int
language plpgsql security definer set search_path = public as $$
declare s record; r record; n int := 0; ex int; co int; mn int := _setting_int('league_min_pts', 30);
begin
  for s in select distinct season from league_points where season < _league_season() and season not in (select season from league_done) loop
    for r in select * from (select lp.*, rank() over (partition by class_id order by pts desc, wins desc, student_id) rnk
                              from league_points lp where season = s.season and pts >= mn) z where rnk <= 3 loop
      ex := case r.rnk when 1 then _setting_int('league_r1_exp', 80) when 2 then _setting_int('league_r2_exp', 50) else _setting_int('league_r3_exp', 30) end;
      co := case r.rnk when 1 then _setting_int('league_r1_coins', 60) when 2 then _setting_int('league_r2_coins', 40) else _setting_int('league_r3_coins', 25) end;
      insert into league_results (season, student_id, class_id, rank, pts, exp, coins) values (s.season, r.student_id, r.class_id, r.rnk, r.pts, ex, co) on conflict do nothing;
      if found then
        perform award(r.student_id, ex, co, 'ลีกประลอง อันดับ ' || r.rnk || ' ของห้อง 🏆', 'league:' || s.season || ':' || r.student_id);
        insert into student_notices (student_id, ref, icon, title, body) values (r.student_id, 'league:' || s.season,
          case r.rnk when 1 then '🥇' when 2 then '🥈' else '🥉' end, 'ผลลีกประลองสัปดาห์ที่แล้ว',
          'คุณได้อันดับ ' || r.rnk || ' ของห้อง (' || r.pts || ' แต้ม) · รับ ' || ex || ' EXP + ' || co || ' เหรียญ') on conflict (student_id, ref) do nothing;
        n := n + 1;
      end if;
    end loop;
    insert into league_done (season) values (s.season) on conflict do nothing;
  end loop;
  return n;
end $$;

create or replace function league_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cls uuid; ssn date := _league_season(); me json; top json; last json;
begin
  select class_id into cls from students where id = sid;
  perform _league_finalize_old();
  select coalesce(json_agg(x order by x.rank), '[]'::json) into top from (
    select rank() over (order by lp.pts desc, lp.wins desc, lp.student_id)::int as rank, s.name, s.avatar, lp.pts, lp.wins, (lp.student_id = sid) as me
      from league_points lp join students s on s.id = lp.student_id where lp.season = ssn and lp.class_id = cls order by 1 limit 10) x;
  select row_to_json(x) into me from (
    select y.rank, y.pts, y.wins, y.draws, y.losses from (
      select lp.student_id, lp.pts, lp.wins, lp.draws, lp.losses, rank() over (order by lp.pts desc, lp.wins desc, lp.student_id)::int as rank
        from league_points lp where lp.season = ssn and lp.class_id = cls) y where y.student_id = sid) x;
  select row_to_json(x) into last from (select season, rank, pts, exp, coins from league_results where student_id = sid order by season desc limit 1) x;
  return json_build_object('season', ssn, 'ends', ssn + 6, 'me', me, 'top', top, 'last', last,
    'today', (select count(*) from league_log where student_id = sid and day = today_th()), 'per_day', _setting_int('league_per_day', 6),
    'rules', json_build_object('win', _setting_int('league_win', 30), 'draw', _setting_int('league_draw', 10), 'loss', _setting_int('league_loss', 5), 'min', _setting_int('league_min_pts', 30),
      'stake_max', _setting_int('duel_stake_max', 30), 'stake_win_exp', _setting_int('duel_stake_win_exp', 8), 'underdog_exp', _setting_int('duel_underdog_exp', 6)),
    'prizes', json_build_array(json_build_object('exp', _setting_int('league_r1_exp', 80), 'coins', _setting_int('league_r1_coins', 60)),
      json_build_object('exp', _setting_int('league_r2_exp', 50), 'coins', _setting_int('league_r2_coins', 40)),
      json_build_object('exp', _setting_int('league_r3_exp', 30), 'coins', _setting_int('league_r3_coins', 25))));
end $$;

revoke execute on function _league_season(), trg_duel_stake_hold(), trg_duel_settle(), _duel_post_player(duels, uuid, uuid, text), _league_finalize_old() from public, anon, authenticated;
revoke execute on function duel_invite2(uuid, uuid, text, int), duel_stakes(uuid), league_status(uuid) from public;
grant execute on function duel_invite2(uuid, uuid, text, int), duel_stakes(uuid), league_status(uuid) to anon, authenticated;
