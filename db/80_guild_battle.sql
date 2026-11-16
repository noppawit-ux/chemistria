-- 80: Guild Battle — จับคู่กิลด์แข่งเกมกดลูกศรตามจังหวะ (ต้องรันหลัง 45, 62, 63)
-- ครูสร้างรอบ → จับคู่กิลด์ → สมาชิกเล่นได้กี่ครั้งก็ได้ตามที่ตั้ง (เล่นเวลาไหนก็ได้ภายในช่วงเวลา) → คะแนนรายคน = ครั้งที่ดีที่สุด
-- คะแนนกิลด์ = ค่าเฉลี่ยของ 3 คนที่ดีที่สุด (คนที่ไม่ได้เล่นนับ 0) → กิลด์คะแนนสูงกว่าชนะ (เสมอ = ชนะทั้งคู่)
-- กิลด์ที่ไม่มีคู่ (จำนวนคี่) ได้แข่งกับ “ผีกิลด์” คะแนนคงที่ตามที่ครูตั้ง
-- เซิร์ฟเวอร์ตรวจคะแนนจากลำดับการกดที่ส่งมา (เทียบกับโน้ตของรอบ) และตรวจเวลาที่ใช้จริง

create table if not exists guild_battle_rounds (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  bpm int not null default 100,
  chart jsonb not null,                 -- [{t: มิลลิวินาที, k: 'L'|'D'|'U'|'R'}, ...]
  len_ms int not null,
  attempts int not null default 3,
  starts_at timestamptz not null default now(),
  ends_at timestamptz not null,
  paired boolean not null default false,
  ghost_score int not null default 600,
  win_coins int not null default 40, win_pulls int not null default 1, lose_coins int not null default 15,
  created_at timestamptz not null default now()
);
create table if not exists guild_battle_matches (
  id uuid primary key default gen_random_uuid(),
  round_id uuid not null references guild_battle_rounds(id) on delete cascade,
  guild_a uuid not null references guilds(id) on delete cascade,
  guild_b uuid references guilds(id) on delete cascade      -- null = สู้กับผีกิลด์
);
create index if not exists gbm_round on guild_battle_matches(round_id);
create table if not exists guild_battle_runs (
  id uuid primary key default gen_random_uuid(),
  round_id uuid not null references guild_battle_rounds(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  guild_id uuid not null references guilds(id) on delete cascade,
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  score int, perfect int, good int, miss int, max_combo int
);
create index if not exists gbr_round on guild_battle_runs(round_id, student_id);
create table if not exists guild_battle_claims (
  round_id uuid not null references guild_battle_rounds(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  claimed_at timestamptz not null default now(),
  primary key (round_id, student_id)
);
do $$ declare t text; begin
  foreach t in array array['guild_battle_rounds','guild_battle_matches','guild_battle_runs','guild_battle_claims'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists teacher_all on public.%I', t);
    execute format('create policy teacher_all on public.%I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;

-- ---------- ตัวช่วยภายใน ----------
-- คะแนนดีที่สุดของแต่ละคนในรอบ
create or replace function _gb_best(p_round uuid, p_sid uuid) returns int
language sql stable security definer set search_path = public as $$
  select coalesce(max(score), 0)::int from guild_battle_runs where round_id = p_round and student_id = p_sid and finished_at is not null $$;

-- คะแนนกิลด์ = (ผลรวมคะแนนดีที่สุดของ 3 คนแรก) / 3
create or replace function _gb_guild_score(p_round uuid, p_guild uuid) returns int
language sql stable security definer set search_path = public as $$
  select round(coalesce(sum(b), 0) / 3.0)::int from (
    select max(r.score) b from guild_battle_runs r
     where r.round_id = p_round and r.guild_id = p_guild and r.finished_at is not null
     group by r.student_id order by b desc limit 3) x $$;

-- ข้อมูลฝ่ายหนึ่งของการแข่ง
create or replace function _gb_side(p_round uuid, p_guild uuid, p_ghost int, p_detail boolean) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare g guilds%rowtype; mem jsonb := '[]'::jsonb;
begin
  if p_guild is null then
    return jsonb_build_object('ghost', true, 'name', '👻 ผีกิลด์ครูบุ๊ค', 'emblem', null, 'score', p_ghost, 'played', 0, 'size', 0);
  end if;
  select * into g from guilds where id = p_guild;
  if p_detail then
    select coalesce(jsonb_agg(jsonb_build_object('name', s.name, 'leader', (g.leader_id = s.id), 'best', _gb_best(p_round, s.id),
             'runs', (select count(*) from guild_battle_runs r where r.round_id = p_round and r.student_id = s.id)) order by _gb_best(p_round, s.id) desc, s.name), '[]'::jsonb)
      into mem from guild_members gm join students s on s.id = gm.student_id where gm.guild_id = p_guild;
  end if;
  return jsonb_build_object('ghost', false, 'id', g.id, 'name', g.name, 'emblem', _guild_emb(g.id, g.emblem), 'class_id', g.class_id,
    'score', _gb_guild_score(p_round, p_guild),
    'played', (select count(distinct student_id) from guild_battle_runs r where r.round_id = p_round and r.guild_id = p_guild and r.finished_at is not null),
    'size', (select count(*) from guild_members where guild_id = p_guild), 'members', mem);
end $$;

-- ผลแข่ง (ตัดสินเมื่อหมดเวลา + เผื่อ 3 นาทีให้คนที่กำลังเล่นส่งคะแนนทัน)
create or replace function _gb_result(p_a int, p_b int, p_final boolean) returns text
language sql immutable as $$ select case when not p_final then null when p_a > p_b then 'a' when p_b > p_a then 'b' else 'draw' end $$;

create or replace function _gb_state(r guild_battle_rounds) returns text
language sql stable as $$ select case when now() < r.starts_at then 'soon' when not r.paired then 'unpaired'
  when now() <= r.ends_at then 'open' when now() <= r.ends_at + interval '3 minutes' then 'counting' else 'final' end $$;

-- ---------- RPC นักเรียน ----------
create or replace function gb_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); gid uuid; r guild_battle_rounds%rowtype; m guild_battle_matches%rowtype; stt text; fin boolean;
  me_g uuid; opp uuid; sa jsonb; sb jsonb; used int := 0; res text; mine text; hist jsonb := '[]'::jsonb; claimed boolean := false; rw jsonb := null;
begin
  select guild_id into gid from guild_members where student_id = sid;
  select * into r from guild_battle_rounds where starts_at <= now() order by starts_at desc, created_at desc limit 1;
  if not found then return json_build_object('round', null, 'has_guild', gid is not null); end if;
  stt := _gb_state(r); fin := stt = 'final';
  if gid is null then return json_build_object('round', json_build_object('id', r.id, 'title', r.title, 'state', stt), 'has_guild', false); end if;
  select * into m from guild_battle_matches where round_id = r.id and (guild_a = gid or guild_b = gid) limit 1;
  if found then
    sa := _gb_side(r.id, gid, r.ghost_score, true);
    opp := case when m.guild_a = gid then m.guild_b else m.guild_a end;
    sb := _gb_side(r.id, opp, r.ghost_score, false);
    res := _gb_result((sa->>'score')::int, (sb->>'score')::int, fin);
    mine := case when res is null then null when res = 'draw' then 'win' when res = 'a' then 'win' else 'lose' end;
  end if;
  select count(*) into used from guild_battle_runs where round_id = r.id and student_id = sid;
  select exists (select 1 from guild_battle_claims where round_id = r.id and student_id = sid) into claimed;
  if mine is not null then
    rw := jsonb_build_object('coins', case when mine = 'win' then r.win_coins else r.lose_coins end, 'pulls', case when mine = 'win' then r.win_pulls else 0 end);
  end if;
  -- ประวัติรอบก่อนๆ ของกิลด์นี้
  select coalesce(jsonb_agg(h order by (h->>'at') desc), '[]'::jsonb) into hist from (
    select jsonb_build_object('title', x.title, 'at', x.starts_at,
             'me', _gb_guild_score(x.id, gid),
             'opp', case when mm.guild_a = gid then (case when mm.guild_b is null then x.ghost_score else _gb_guild_score(x.id, mm.guild_b) end) else _gb_guild_score(x.id, mm.guild_a) end,
             'opp_name', case when mm.guild_a = gid then coalesce((select name from guilds where id = mm.guild_b), '👻 ผีกิลด์') else (select name from guilds where id = mm.guild_a) end) h
      from guild_battle_rounds x join guild_battle_matches mm on mm.round_id = x.id and (mm.guild_a = gid or mm.guild_b = gid)
     where x.id <> r.id and now() > x.ends_at + interval '3 minutes' order by x.starts_at desc limit 5) q;
  return json_build_object('round', json_build_object('id', r.id, 'title', r.title, 'bpm', r.bpm, 'len_ms', r.len_ms, 'attempts', r.attempts,
      'starts_at', r.starts_at, 'ends_at', r.ends_at, 'state', stt, 'notes', jsonb_array_length(r.chart)),
    'has_guild', true, 'in_match', m.id is not null, 'me', sa, 'opp', sb, 'result', res, 'mine', mine,
    'used', used, 'left', greatest(0, r.attempts - used), 'best', _gb_best(r.id, sid),
    'reward', rw, 'claimed', claimed, 'can_claim', (mine is not null and not claimed and exists (select 1 from guild_battle_runs x where x.round_id = r.id and x.student_id = sid and x.finished_at is not null)),
    'history', hist);
end $$;

create or replace function gb_start(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); gid uuid; r guild_battle_rounds%rowtype; used int; rid uuid;
begin
  select guild_id into gid from guild_members where student_id = sid;
  if gid is null then raise exception 'ต้องมีกิลด์ก่อนจึงจะแข่ง Guild Battle ได้'; end if;
  select * into r from guild_battle_rounds where starts_at <= now() order by starts_at desc, created_at desc limit 1;
  if not found or _gb_state(r) <> 'open' then raise exception 'ตอนนี้ไม่มีรอบ Guild Battle ที่เปิดอยู่'; end if;
  if not exists (select 1 from guild_battle_matches where round_id = r.id and (guild_a = gid or guild_b = gid)) then
    raise exception 'กิลด์ของคุณยังไม่ได้ถูกจับคู่ในรอบนี้';
  end if;
  select count(*) into used from guild_battle_runs where round_id = r.id and student_id = sid;
  if used >= r.attempts then raise exception 'ใช้สิทธิ์เล่นครบ % ครั้งแล้ว', r.attempts; end if;
  -- รอบเดิมที่เริ่มแล้วไม่ส่งภายใน 3 นาที ปล่อยทิ้ง (ยังนับสิทธิ์) · กันกดเริ่มซ้อน
  if exists (select 1 from guild_battle_runs where round_id = r.id and student_id = sid and finished_at is null
              and started_at > now() - make_interval(secs => r.len_ms / 1000.0 + 40)) then
    raise exception 'ยังมีรอบที่กำลังเล่นอยู่ — รอสักครู่หรือส่งผลก่อน';
  end if;
  insert into guild_battle_runs (round_id, student_id, guild_id) values (r.id, sid, gid) returning id into rid;
  return json_build_object('run', rid, 'bpm', r.bpm, 'len_ms', r.len_ms, 'chart', r.chart, 'left', r.attempts - used - 1);
end $$;

-- ตรวจคะแนนจากลำดับการกด: [{t: มิลลิวินาทีนับจากเริ่ม, k: 'L'|'D'|'U'|'R'}, ...]
create or replace function gb_submit(p_token uuid, p_run uuid, p_presses jsonb) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); run guild_battle_runs%rowtype; r guild_battle_rounds%rowtype; el numeric;
  n int; np int; pt int[] := '{}'; pk text[] := '{}'; used boolean[] := '{}'; i int; j int; bj int; bd int; d int;
  note jsonb; combo int := 0; best_combo int := 0; raw numeric := 0; mx numeric := 0; pf int := 0; gd int := 0; ms int := 0; pts int; s int; p jsonb;
begin
  select * into run from guild_battle_runs where id = p_run and student_id = sid for update;
  if not found then raise exception 'ไม่พบรอบการเล่น'; end if;
  if run.finished_at is not null then raise exception 'รอบนี้ส่งคะแนนไปแล้ว'; end if;
  select * into r from guild_battle_rounds where id = run.round_id;
  if now() > r.ends_at + interval '3 minutes' then raise exception 'หมดเวลาส่งคะแนนของรอบนี้แล้ว'; end if;
  el := extract(epoch from now() - run.started_at);
  if el < r.len_ms / 1000.0 - 1 then raise exception 'ส่งคะแนนเร็วผิดปกติ'; end if;
  if el > r.len_ms / 1000.0 + 180 then raise exception 'ใช้เวลานานเกินไป — เริ่มรอบใหม่'; end if;
  n := jsonb_array_length(r.chart);
  if p_presses is null or jsonb_typeof(p_presses) <> 'array' then p_presses := '[]'::jsonb; end if;
  np := jsonb_array_length(p_presses);
  if np > n * 4 + 20 then raise exception 'ข้อมูลการกดไม่ถูกต้อง'; end if;
  for p in select * from jsonb_array_elements(p_presses) loop
    if jsonb_typeof(p) <> 'object' or (p->>'k') not in ('L','D','U','R') or (p->>'t') !~ '^-?[0-9]{1,7}$' then raise exception 'ข้อมูลการกดไม่ถูกต้อง'; end if;
    pt := pt || (p->>'t')::int; pk := pk || (p->>'k'); used := used || false;
  end loop;
  i := 0;
  for note in select * from jsonb_array_elements(r.chart) loop
    i := i + 1; bj := 0; bd := 221;
    for j in 1..np loop
      if not used[j] and pk[j] = note->>'k' then
        d := abs(pt[j] - (note->>'t')::int);
        if d < bd then bd := d; bj := j; end if;
      end if;
    end loop;
    mx := mx + 100 * (1 + least(i, 20) * 0.02);
    if bj > 0 then
      used[bj] := true;
      combo := combo + 1; best_combo := greatest(best_combo, combo);
      if bd <= 90 then pts := 100; pf := pf + 1; else pts := 60; gd := gd + 1; end if;
      raw := raw + pts * (1 + least(combo, 20) * 0.02);
    else combo := 0; ms := ms + 1; end if;
  end loop;
  s := round(1000 * raw / mx)::int;
  update guild_battle_runs set finished_at = now(), score = s, perfect = pf, good = gd, miss = ms, max_combo = best_combo where id = run.id;
  return json_build_object('score', s, 'perfect', pf, 'good', gd, 'miss', ms, 'max_combo', best_combo, 'best', _gb_best(run.round_id, sid), 'notes', n);
end $$;

create or replace function gb_claim(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); r guild_battle_rounds%rowtype; gid uuid; m guild_battle_matches%rowtype; sa int; sb int; win boolean; c int; pl int; opp uuid;
begin
  select * into r from guild_battle_rounds where starts_at <= now() order by starts_at desc, created_at desc limit 1;
  if not found or _gb_state(r) <> 'final' then raise exception 'ยังรับรางวัลไม่ได้ — รอให้รอบนี้จบก่อน'; end if;
  select guild_id into gid from guild_battle_runs where round_id = r.id and student_id = sid and finished_at is not null order by finished_at desc limit 1;
  if gid is null then raise exception 'ต้องลงแข่งอย่างน้อย 1 ครั้งจึงรับรางวัลได้'; end if;
  select * into m from guild_battle_matches where round_id = r.id and (guild_a = gid or guild_b = gid) limit 1;
  if not found then raise exception 'ไม่พบการจับคู่ของกิลด์คุณ'; end if;
  if exists (select 1 from guild_battle_claims where round_id = r.id and student_id = sid) then raise exception 'รับรางวัลรอบนี้ไปแล้ว'; end if;
  opp := case when m.guild_a = gid then m.guild_b else m.guild_a end;
  sa := _gb_guild_score(r.id, gid);
  sb := case when opp is null then r.ghost_score else _gb_guild_score(r.id, opp) end;
  win := sa >= sb;
  c := case when win then r.win_coins else r.lose_coins end; pl := case when win then r.win_pulls else 0 end;
  insert into guild_battle_claims (round_id, student_id) values (r.id, sid);
  perform _guild_give(sid, 'gb:' || r.id || ':' || sid, 'Guild Battle ' || r.title || (case when win then ' (ชนะ)' else ' (ร่วมแข่ง)' end), c, pl, 0);
  return json_build_object('win', win, 'coins', c, 'pulls', pl);
end $$;

revoke execute on function gb_status(uuid), gb_start(uuid), gb_submit(uuid, uuid, jsonb), gb_claim(uuid) from public;
grant execute on function gb_status(uuid), gb_start(uuid), gb_submit(uuid, uuid, jsonb), gb_claim(uuid) to anon, authenticated;
revoke execute on function _gb_best(uuid, uuid), _gb_guild_score(uuid, uuid), _gb_side(uuid, uuid, int, boolean), _gb_result(int, int, boolean), _gb_state(guild_battle_rounds) from public, anon, authenticated;

-- ---------- RPC ครู ----------
create or replace function admin_gb_create(p_title text, p_bpm int default 100, p_notes int default 40, p_hours int default 48, p_attempts int default 3,
  p_win_coins int default 40, p_win_pulls int default 1, p_lose_coins int default 15, p_ghost int default 600) returns uuid
language plpgsql security definer set search_path = public as $$
declare beat numeric; t int := 2000; ch jsonb := '[]'::jsonb; i int; mult numeric[] := array[1,1,1,1,0.5,0.5,1.5]; k text := 'LDUR'; rid uuid; bpm int := least(140, greatest(60, coalesce(p_bpm, 100)));
  n int := least(80, greatest(16, coalesce(p_notes, 40)));
begin
  if not is_teacher() then raise exception 'เฉพาะครู'; end if;
  if coalesce(trim(p_title), '') = '' then raise exception 'ใส่ชื่อรอบ'; end if;
  beat := 60000.0 / bpm;
  for i in 1..n loop
    ch := ch || jsonb_build_object('t', t, 'k', substr(k, 1 + floor(random() * 4)::int, 1));
    t := t + greatest(300, round(beat * mult[1 + floor(random() * 7)::int])::int);
  end loop;
  insert into guild_battle_rounds (title, bpm, chart, len_ms, attempts, ends_at, win_coins, win_pulls, lose_coins, ghost_score)
  values (trim(p_title), bpm, ch, (ch->(n - 1)->>'t')::int + 1500, greatest(1, least(10, coalesce(p_attempts, 3))), now() + make_interval(hours => greatest(1, coalesce(p_hours, 48))),
          greatest(0, coalesce(p_win_coins, 0)), greatest(0, coalesce(p_win_pulls, 0)), greatest(0, coalesce(p_lose_coins, 0)), greatest(0, least(1000, coalesce(p_ghost, 600))))
  returning id into rid;
  return rid;
end $$;

-- จับคู่: rank = เรียงตามอันดับ Mini Guild แล้วจับคู่ติดกัน · random = สุ่ม (เฉพาะกิลด์ที่ติดอันดับ = สมาชิกพอ) · กิลด์คี่ได้สู้กับผีกิลด์
create or replace function admin_gb_pair(p_round uuid, p_mode text default 'rank') returns int
language plpgsql security definer set search_path = public as $$
declare ids uuid[]; i int := 1; n int; c int := 0;
begin
  if not is_teacher() then raise exception 'เฉพาะครู'; end if;
  if not exists (select 1 from guild_battle_rounds where id = p_round) then raise exception 'ไม่พบรอบ'; end if;
  if exists (select 1 from guild_battle_runs where round_id = p_round) then raise exception 'มีคนเริ่มเล่นไปแล้ว — จับคู่ใหม่ไม่ได้'; end if;
  delete from guild_battle_matches where round_id = p_round;
  select array_agg(guild_id order by case when p_mode = 'random' then random() end, rank nulls last, avg desc) into ids
    from _guild_ranks() where size >= (_guild_cfg()->>'min_members')::int;
  n := coalesce(array_length(ids, 1), 0);
  while i <= n loop
    insert into guild_battle_matches (round_id, guild_a, guild_b) values (p_round, ids[i], case when i + 1 <= n then ids[i + 1] end);
    i := i + 2; c := c + 1;
  end loop;
  update guild_battle_rounds set paired = (c > 0) where id = p_round;
  return c;
end $$;

create or replace function admin_gb_add_match(p_round uuid, p_a uuid, p_b uuid default null) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not is_teacher() then raise exception 'เฉพาะครู'; end if;
  if p_a is null or p_a = p_b then raise exception 'เลือกกิลด์ให้ถูกต้อง'; end if;
  if exists (select 1 from guild_battle_runs where round_id = p_round and guild_id in (p_a, coalesce(p_b, p_a))) then raise exception 'กิลด์นี้มีคนเล่นแล้ว แก้คู่ไม่ได้'; end if;
  delete from guild_battle_matches where round_id = p_round and (guild_a in (p_a, p_b) or guild_b in (p_a, p_b));
  insert into guild_battle_matches (round_id, guild_a, guild_b) values (p_round, p_a, p_b);
  update guild_battle_rounds set paired = true where id = p_round;
end $$;

create or replace function admin_gb_del_match(p_match uuid) returns void
language plpgsql security definer set search_path = public as $$
declare rid uuid;
begin
  if not is_teacher() then raise exception 'เฉพาะครู'; end if;
  select round_id into rid from guild_battle_matches where id = p_match;
  if exists (select 1 from guild_battle_runs x join guild_battle_matches m on m.round_id = x.round_id and x.guild_id in (m.guild_a, m.guild_b) where m.id = p_match) then
    raise exception 'มีคนเล่นแล้ว ลบคู่นี้ไม่ได้';
  end if;
  delete from guild_battle_matches where id = p_match;
end $$;

create or replace function admin_gb_end(p_round uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not is_teacher() then raise exception 'เฉพาะครู'; end if;
  update guild_battle_rounds set ends_at = least(ends_at, now()) where id = p_round;
end $$;

create or replace function admin_gb_delete(p_round uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not is_teacher() then raise exception 'เฉพาะครู'; end if;
  delete from guild_battle_rounds where id = p_round;
end $$;

create or replace function admin_gb_list() returns json
language plpgsql security definer set search_path = public as $$
declare out jsonb := '[]'::jsonb; r guild_battle_rounds%rowtype; ms jsonb;
begin
  if not is_teacher() then raise exception 'เฉพาะครู'; end if;
  for r in select * from guild_battle_rounds order by created_at desc limit 10 loop
    select coalesce(jsonb_agg(jsonb_build_object('id', m.id, 'a', _gb_side(r.id, m.guild_a, r.ghost_score, false), 'b', _gb_side(r.id, m.guild_b, r.ghost_score, false),
             'result', _gb_result(_gb_guild_score(r.id, m.guild_a), case when m.guild_b is null then r.ghost_score else _gb_guild_score(r.id, m.guild_b) end, _gb_state(r) = 'final'))
           order by m.id), '[]'::jsonb) into ms from guild_battle_matches m where m.round_id = r.id;
    out := out || jsonb_build_object('id', r.id, 'title', r.title, 'bpm', r.bpm, 'notes', jsonb_array_length(r.chart), 'attempts', r.attempts, 'starts_at', r.starts_at,
      'ends_at', r.ends_at, 'state', _gb_state(r), 'paired', r.paired, 'ghost_score', r.ghost_score, 'win_coins', r.win_coins, 'win_pulls', r.win_pulls, 'lose_coins', r.lose_coins,
      'players', (select count(distinct student_id) from guild_battle_runs where round_id = r.id and finished_at is not null), 'matches', ms,
      'claims', (select count(*) from guild_battle_claims where round_id = r.id));
  end loop;
  return json_build_object('rounds', out, 'guilds', (select coalesce(jsonb_agg(jsonb_build_object('id', g.id, 'name', g.name, 'class', c.name) order by c.name, g.name), '[]'::jsonb)
    from guilds g join classes c on c.id = g.class_id));
end $$;

revoke execute on function admin_gb_create(text, int, int, int, int, int, int, int, int), admin_gb_pair(uuid, text), admin_gb_add_match(uuid, uuid, uuid),
  admin_gb_del_match(uuid), admin_gb_end(uuid), admin_gb_delete(uuid), admin_gb_list() from public, anon;
grant execute on function admin_gb_create(text, int, int, int, int, int, int, int, int), admin_gb_pair(uuid, text), admin_gb_add_match(uuid, uuid, uuid),
  admin_gb_del_match(uuid), admin_gb_end(uuid), admin_gb_delete(uuid), admin_gb_list() to authenticated;
