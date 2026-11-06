-- =====================================================================
-- Chemistria · รอบที่ 22: สนามต่อสู้หลายสนาม + ท้าดวลเพื่อนแบบเรียลไทม์ (รันซ้ำได้ · ต้องรัน 16_battle.sql ก่อน)
--  · สนาม (arenas): ธีมต่างกัน ปลดล็อกตามเลเวล โบนัสรางวัลเพิ่มขึ้น · มอนสเตอร์ผูกกับสนาม
--  · ท้าดวล (duels): เพื่อนห้องเดียวกันที่ออนไลน์ → ส่งคำท้า → อีกฝ่ายรับ → ตอบคำถามพร้อมกันทุกรอบ
--    ตอบถูก = ทำดาเมจใส่อีกฝ่าย (ไว/ตอบก่อน = โบนัส) · สกิลประจำคลาส 1 ครั้ง/แมตช์ · HP หมดหรือครบ 8 รอบ
--  · เรียลไทม์ด้วยการโพลล์ RPC ทุก ~1 วิ · เซิร์ฟเวอร์ตัดสินทุกอย่าง (เฉลยไม่ถูกส่งก่อนทั้งคู่ตอบ/หมดเวลา)
-- =====================================================================
create table if not exists arenas (
  key text primary key,
  name text not null,
  emoji text not null default '🏟️',
  theme text not null default 'lab',        -- lab | ice | volcano | swamp | storm | crystal (ชุดสีในหน้าเกม)
  descr text,
  min_level int not null default 1,
  reward_pct int not null default 100 check (reward_pct between 50 and 300),
  active boolean not null default true,
  sort int not null default 0
);
alter table monsters add column if not exists arena text not null default 'lab';

create table if not exists duel_presence (student_id uuid primary key references students(id) on delete cascade, seen_at timestamptz not null default now());

create table if not exists duels (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references classes(id) on delete cascade,
  a_id uuid not null references students(id) on delete cascade,
  b_id uuid not null references students(id) on delete cascade,
  arena text not null default 'lab',
  status text not null default 'invited' check (status in ('invited', 'active', 'done', 'declined', 'cancelled', 'expired')),
  a_hp int not null default 100, b_hp int not null default 100, hp_max int not null default 100,
  round int not null default 0, phase text not null default 'q' check (phase in ('q', 'reveal')),
  cur_q uuid, round_at timestamptz, next_at timestamptz, idle int not null default 0,
  a_pick int, a_ms int, a_skill boolean not null default false,
  b_pick int, b_ms int, b_skill boolean not null default false,
  a_used boolean not null default false, b_used boolean not null default false,
  used_q uuid[] not null default '{}',
  last jsonb,
  winner uuid,
  a_exp int not null default 0, a_coins int not null default 0, b_exp int not null default 0, b_coins int not null default 0,
  created_at timestamptz not null default now(), finished_at timestamptz, play_date date not null default today_th()
);
create index if not exists idx_duels_a on duels(a_id, status);
create index if not exists idx_duels_b on duels(b_id, status);

do $$
declare t text;
begin
  foreach t in array array['arenas', 'duel_presence', 'duels'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists teacher_all on public.%I', t);
    execute format('create policy teacher_all on public.%I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;

insert into app_settings (key, value) values ('duel_rewards_per_day', '5') on conflict (key) do nothing;

insert into arenas (key, name, emoji, theme, descr, min_level, reward_pct, sort) values
  ('lab',     'ห้องแล็บเคมี',     '🧪', 'lab',     'สนามเริ่มต้น ฟองโซดาลอยเต็มห้อง',               1, 100, 1),
  ('ice',     'ถ้ำน้ำแข็งแห้ง',   '🧊', 'ice',     'หมอกเย็นจัด ไอ CO₂ ลอยฟุ้ง',                    2, 110, 2),
  ('volcano', 'ภูเขาไฟเดือด',     '🌋', 'volcano', 'ลาวาไหลริน ร้อนระอุ รางวัลคุ้มกว่า',            4, 120, 3),
  ('swamp',   'บึงกรดมรณะ',       '☣️', 'swamp',   'น้ำกรดเขียวเรืองแสง ระวังหยดกรด',               6, 130, 4),
  ('storm',   'ยอดเขาพายุไฟฟ้า',  '⛈️', 'storm',   'ฟ้าผ่าตลอดเวลา สายฟ้าฟาดเป็นระยะ',              8, 140, 5),
  ('crystal', 'ถ้ำผลึกมหัศจรรย์', '💎', 'crystal', 'ผลึกเรืองแสงทุกทิศ สนามสุดท้ายของนักเคมีตัวจริง', 10, 150, 6)
on conflict (key) do nothing;

update monsters set arena = 'lab' where key in ('bubble', 'rust');
update monsters set arena = 'ice' where key in ('salt');
update monsters set arena = 'swamp' where key in ('lemon');
update monsters set arena = 'storm' where key in ('fog');
insert into monsters (key, name, emoji, image, level, hp, atk, exp, coins, atk_name, descr, sort, arena) values
  ('frost',  'น้ำแข็งแห้งจอมหนาว',   '🧊', null, 2, 110, 13, 20, 11, 'ไอเย็นเยือก',     'CO₂ แข็งที่ระเหิดเป็นหมอกเย็น', 11, 'ice'),
  ('cryo',   'ไนโตรเจนเหลวหิมะ',     '❄️', null, 4, 170, 18, 32, 17, 'ลมหนาวขั้วโลก',   'เย็นจัด −196 องศาเซลเซียส',      12, 'ice'),
  ('lava',   'ลาวาโซเดียมระเบิด',    '🌋', null, 3, 150, 17, 28, 15, 'ลาวาพุ่งกระเด็น', 'ทำปฏิกิริยากับน้ำรุนแรง',         21, 'volcano'),
  ('ash',    'เขม่าคาร์บอนดำ',       '⚫', null, 4, 180, 19, 34, 18, 'ควันดำคลุ้ง',     'เขม่าที่ลอยฟุ้งทั่วปล่อง',       22, 'volcano'),
  ('sludge', 'เมือกกรดซัลฟิวริก',    '🟢', null, 3, 150, 17, 28, 15, 'น้ำกรดกัดกร่อน',  'เมือกเขียวหนืดกัดทุกอย่าง',     31, 'swamp'),
  ('toxic',  'ก๊าซคลอรีนพิษ',        '☣️', null, 4, 175, 19, 33, 18, 'ไอพิษแสบจมูก',    'ก๊าซสีเหลืองอมเขียวอันตราย',     32, 'swamp'),
  ('ozone',  'โอโซนจอมพายุ',         '⛈️', null, 4, 180, 19, 34, 18, 'สายฟ้าฟาด',       'ก๊าซ O₃ ที่ชอบฟ้าผ่า',          41, 'storm'),
  ('plasma', 'พลาสมาไอออนคลั่ง',     '⚡', null, 5, 220, 22, 42, 22, 'คลื่นพลาสมา',     'สถานะที่ 4 ของสสาร',            42, 'storm'),
  ('quartz', 'ควอตซ์ผลึกคม',         '💎', null, 4, 180, 19, 34, 18, 'เศษผลึกแหลม',     'SiO₂ ผลึกใสแข็งแกร่ง',          51, 'crystal'),
  ('geode',  'ไข่ธรณีผลึกเวท',       '🔮', null, 5, 230, 22, 44, 23, 'แสงผลึกเจิดจ้า',  'ภายในซ่อนผลึกหายากเรืองแสง',     52, 'crystal')
on conflict (key) do nothing;

update monsters set image = 'assets/monsters/' || key || '.png'
 where image is null and key in ('frost', 'cryo', 'lava', 'ash', 'sludge', 'toxic', 'ozone', 'plasma', 'quartz', 'geode');

-- ---------- ปรับระบบต่อสู้ให้รู้จักสนาม (ปลดล็อกตามเลเวล + โบนัสรางวัล) ----------
create or replace function _battle_view(p_b uuid) returns json
language plpgsql stable security definer set search_path = public as $$
declare b battles%rowtype; m monsters%rowtype; ph text; q json := null; sk json; pv json := null;
begin
  select * into b from battles where id = p_b;
  select * into m from monsters where id = b.monster_id;
  ph := case when b.status <> 'active' then b.status when b.pend is not null then 'defend'
             when b.cur_q is not null then 'question' else 'choose' end;
  if ph = 'question' then
    select json_build_object('id', x.id, 'topic', x.topic, 'question', x.question,
             'choices', json_build_array(x.a, x.b, x.c, x.d), 'skill', b.cur_skill,
             'elapsed', round(extract(epoch from now() - b.asked_at)::numeric, 1))
      into q from quiz_questions x where x.id = b.cur_q;
  end if;
  if b.pend is not null then
    pv := json_build_object('n', (b.pend->>'n')::int, 'seq', b.pend->>'seq', 'dmg', (b.pend->>'dmg')::int, 'name', m.atk_name);
  end if;
  select coalesce(json_agg(json_build_object('key', s.key, 'name', s.name, 'emoji', s.emoji, 'kind', s.kind,
           'power', s.power, 'descr', s.descr, 'cd', s.cd, 'left', coalesce((b.cds->>s.key)::int, 0)) order by s.sort), '[]'::json)
    into sk from _battle_skillset(b.student_id) s;
  return json_build_object('id', b.id, 'status', b.status, 'phase', ph, 'turn', b.turn,
    'p_hp', b.p_hp, 'p_max', b.p_max, 'm_hp', b.m_hp, 'm_max', b.m_max,
    'monster', json_build_object('id', m.id, 'name', m.name, 'emoji', m.emoji, 'image', m.image, 'level', m.level, 'atk_name', m.atk_name, 'arena', m.arena, 'theme', (select a.theme from arenas a where a.key = m.arena), 'arena_name', (select a.name from arenas a where a.key = m.arena)),
    'buffs', b.buffs, 'skills', sk, 'q', q, 'pend', pv, 'correct', b.correct, 'rewarded', b.rewarded,
    'exp', b.exp, 'coins', b.coins, 'drop', b.drop_name);
end $$;

create or replace function battle_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); act uuid; used int; lim int := _setting_int('battle_rewards_per_day', 3); lv int := level_for((select exp from students where id = sid));
begin
  select id into act from battles where student_id = sid and status = 'active' order by created_at desc limit 1;
  select count(*) into used from battles where student_id = sid and play_date = today_th() and rewarded;
  return json_build_object('used', used, 'limit', lim,
    'p_max', 80 + 6 * level_for((select exp from students where id = sid)),
    'monsters', (select coalesce(json_agg(json_build_object('id', m.id, 'name', m.name, 'emoji', m.emoji, 'image', m.image, 'level', m.level,
        'hp', m.hp, 'atk', m.atk, 'exp', m.exp, 'coins', m.coins, 'descr', m.descr, 'arena', m.arena) order by m.sort, m.level), '[]'::json) from monsters m where m.active),
    'arenas', (select coalesce(json_agg(json_build_object('key', a.key, 'name', a.name, 'emoji', a.emoji, 'theme', a.theme, 'descr', a.descr, 'min_level', a.min_level, 'reward_pct', a.reward_pct, 'locked', a.min_level > lv) order by a.sort), '[]'::json) from arenas a where a.active),
    'level', lv,
    'skills', (select coalesce(json_agg(json_build_object('key', s.key, 'name', s.name, 'emoji', s.emoji, 'kind', s.kind, 'descr', s.descr, 'cd', s.cd) order by s.sort), '[]'::json)
                 from _battle_skillset(sid) s),
    'active', case when act is null then null else _battle_view(act) end);
end $$;

create or replace function battle_start(p_token uuid, p_monster uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); m monsters%rowtype; used int; lim int := _setting_int('battle_rewards_per_day', 3); pm int; bid uuid; ar arenas%rowtype;
begin
  select * into m from monsters where id = p_monster and active;
  if not found then raise exception 'ไม่พบมอนสเตอร์'; end if;
  select * into ar from arenas where key = m.arena;
  if found and (not ar.active or ar.min_level > level_for((select exp from students where id = sid))) then raise exception 'ยังปลดล็อกสนามนี้ไม่ได้ (ต้องถึงเลเวล %)', ar.min_level; end if;
  update battles set status = 'fled', finished_at = now() where student_id = sid and status = 'active';
  select count(*) into used from battles where student_id = sid and play_date = today_th() and rewarded;
  pm := 80 + 6 * level_for((select exp from students where id = sid));
  insert into battles (student_id, monster_id, p_hp, p_max, m_hp, m_max, rewarded)
  values (sid, m.id, pm, pm, m.hp, m.hp, used < lim) returning id into bid;
  return _battle_view(bid);
end $$;

create or replace function battle_answer(p_token uuid, p_battle uuid, p_pick int) returns json
language plpgsql security definer set search_path = public as $$
declare
  sid uuid := _sid(p_token); b battles%rowtype; m monsters%rowtype; sk battle_skills%rowtype; q quiz_questions%rowtype;
  st json; elapsed numeric; ok boolean; dmg int := 0; heal int := 0; crit boolean := false; fast boolean := false; mult numeric;
  bf jsonb; cdz jsonb; k text; n int; seqs text := ''; i int; rw_exp int := 0; rw_coins int := 0; drop json := null; ev jsonb;
  luk int; critp numeric; intl int; pct numeric := 1;
begin
  select * into b from battles where id = p_battle and student_id = sid for update;
  if not found or b.status <> 'active' then raise exception 'ไม่พบการต่อสู้ที่กำลังเล่นอยู่'; end if;
  if b.cur_q is null or b.pend is not null then raise exception 'ยังไม่ได้เลือกสกิล'; end if;
  select * into m from monsters where id = b.monster_id;
  select * into sk from battle_skills where key = b.cur_skill;
  select * into q from quiz_questions where id = b.cur_q;
  select coalesce(a.reward_pct, 100) / 100.0 into pct from arenas a where a.key = m.arena;
  pct := coalesce(pct, 1);
  st := _stats(sid);
  luk := coalesce((st->'luk'->>'total')::int, 0); intl := coalesce((st->'int'->>'total')::int, 0);
  elapsed := extract(epoch from now() - b.asked_at);
  ok := p_pick is not null and p_pick = q.answer and elapsed <= 40;
  bf := b.buffs; cdz := b.cds;
  -- คูลดาวน์ทุกสกิลลดลง 1 เทิร์น
  for k in select jsonb_object_keys(cdz) loop cdz := jsonb_set(cdz, array[k], to_jsonb(greatest(0, (cdz->>k)::int - 1))); end loop;
  ev := jsonb_build_object('correct', ok, 'answer', q.answer, 'explain', q.explain, 'pick', p_pick,
          'skill', jsonb_build_object('key', sk.key, 'name', sk.name, 'emoji', sk.emoji, 'kind', sk.kind));
  if ok then
    cdz := jsonb_set(cdz, array[sk.key], to_jsonb(sk.cd));
    if sk.kind = 'attack' then
      fast := elapsed <= 8;
      mult := 1 + coalesce((st->'effects'->>'boss_pct')::int, 0) / 100.0;       -- พลัง (STR)
      if fast then mult := mult * 1.25; end if;
      if coalesce((bf->>'atk_up')::int, 0) > 0 then mult := mult * 1.5; bf := jsonb_set(bf, '{atk_up}', to_jsonb((bf->>'atk_up')::int - 1)); end if;
      if coalesce((bf->>'weak')::int, 0) > 0 then mult := mult * 1.4; end if;
      critp := case when sk.effect = 'crit' then least(0.85, 0.3 + luk * 0.03) else least(0.3, luk * 0.01) end;
      if coalesce((bf->>'crit_up')::int, 0) > 0 then crit := true; bf := jsonb_set(bf, '{crit_up}', to_jsonb((bf->>'crit_up')::int - 1));
      else crit := random() < critp; end if;
      if crit then mult := mult * 2; end if;
      dmg := greatest(1, round(sk.power * mult * (0.9 + random() * 0.2) + intl / 2)::int);
      b.m_hp := greatest(0, b.m_hp - dmg);
    elsif sk.kind = 'heal' then
      heal := round(sk.power * (1 + intl * 0.02))::int;
      heal := least(heal, b.p_max - b.p_hp); b.p_hp := b.p_hp + heal;
    else
      bf := jsonb_set(bf, array[sk.effect], to_jsonb(case sk.effect when 'weak' then 3 else 2 end));
    end if;
    b.correct := b.correct + 1;
  end if;
  ev := ev || jsonb_build_object('dmg', dmg, 'heal', heal, 'crit', crit, 'fast', fast);
  -- ชนะ
  if b.m_hp <= 0 then
    if b.rewarded then
      rw_exp := m.exp + case when b.p_hp >= 0.7 * b.p_max then round(m.exp * 0.25)::int else 0 end;
      rw_coins := round(m.coins * pct)::int;
      rw_exp := round(rw_exp * pct)::int;
      perform award(sid, rw_exp, rw_coins, 'ปราบมอนสเตอร์: ' || m.name, 'game:battle:' || b.id);
      drop := _battle_drop(sid, b.id);
    end if;
    update battles set status = 'won', finished_at = now(), m_hp = 0, p_hp = b.p_hp, correct = b.correct, exp = rw_exp, coins = rw_coins,
           cur_q = null, cur_skill = null, buffs = bf, cds = cdz where id = b.id;
    perform check_achievements(sid);
    return json_build_object('event', ev, 'drop', drop, 'state', _battle_view(b.id));
  end if;
  -- ตาของมอนสเตอร์: สร้างลำดับลูกศรให้ผู้เล่นกดป้องกัน
  n := least(5, 2 + m.level);
  for i in 1..n loop seqs := seqs || substr('LURD', 1 + floor(random() * 4)::int, 1); end loop;
  update battles set m_hp = b.m_hp, p_hp = b.p_hp, correct = b.correct, buffs = bf, cds = cdz, cur_q = null, cur_skill = null,
         pend = jsonb_build_object('dmg', greatest(1, round(m.atk * (0.85 + random() * 0.3))::int), 'n', n, 'seq', seqs,
                                   'at', extract(epoch from now())) where id = b.id;
  return json_build_object('event', ev, 'state', _battle_view(b.id));
end $$;

-- =====================================================================
-- ท้าดวลเพื่อนแบบเรียลไทม์
-- =====================================================================
create or replace function _duel_fighter(p_sid uuid) returns json
language sql stable security definer set search_path = public as $$
  select json_build_object('id', s.id, 'name', s.name, 'no', s.no, 'char_class', s.char_class,
           'level', level_for(s.exp), 'decor', _decor_of(s.id))
    from students s where s.id = p_sid
$$;

-- สกิลโจมตีประจำคลาสสำหรับ "ท่าไม้ตาย" ในดวล
create or replace function _duel_skill(p_sid uuid) returns json
language sql stable security definer set search_path = public as $$
  select json_build_object('key', s.key, 'name', s.name, 'emoji', s.emoji) from _battle_skillset(p_sid) s where s.kind = 'attack' order by s.sort limit 1
$$;

create or replace function _duel_view(p_d uuid, p_sid uuid) returns json
language plpgsql stable security definer set search_path = public as $$
declare d duels%rowtype; me_a boolean; q json := null; opp uuid; lst jsonb; swp jsonb; el numeric;
begin
  select * into d from duels where id = p_d;
  me_a := d.a_id = p_sid; opp := case when me_a then d.b_id else d.a_id end;
  if d.status = 'active' and d.phase = 'q' and d.cur_q is not null then
    select json_build_object('id', x.id, 'topic', x.topic, 'question', x.question, 'choices', json_build_array(x.a, x.b, x.c, x.d))
      into q from quiz_questions x where x.id = d.cur_q;
  end if;
  lst := d.last;
  if lst is not null and not me_a then   -- สลับมุมมอง: me/opp ให้ผู้ดูเสมอ
    lst := jsonb_set(jsonb_set(lst, '{a}', lst->'b'), '{b}', lst->'a');
  end if;
  el := case when d.round_at is null then 0 else extract(epoch from now() - d.round_at) end;
  return json_build_object('id', d.id, 'status', d.status, 'phase', d.phase, 'round', d.round, 'rounds', 8, 'arena', d.arena,
    'theme', (select a.theme from arenas a where a.key = d.arena), 'arena_name', (select a.name from arenas a where a.key = d.arena),
    'me', _duel_fighter(p_sid), 'opp', _duel_fighter(opp), 'host', me_a,
    'me_hp', case when me_a then d.a_hp else d.b_hp end, 'opp_hp', case when me_a then d.b_hp else d.a_hp end, 'hp_max', d.hp_max,
    'q', q, 'elapsed', round(el::numeric, 1),
    'wait', case when d.next_at is null then 0 else greatest(0, round(extract(epoch from d.next_at - now())::numeric, 1)) end,
    'answered', case when me_a then d.a_pick is not null or d.a_ms is not null else d.b_pick is not null or d.b_ms is not null end,
    'opp_answered', case when me_a then d.b_pick is not null or d.b_ms is not null else d.a_pick is not null or d.a_ms is not null end,
    'skill_ready', not case when me_a then d.a_used else d.b_used end, 'skill', _duel_skill(p_sid), 'opp_skill', _duel_skill(opp),
    'last', lst,
    'result', case when d.status <> 'done' then null else json_build_object('win', d.winner = p_sid, 'draw', d.winner is null,
        'exp', case when me_a then d.a_exp else d.b_exp end, 'coins', case when me_a then d.a_coins else d.b_coins end) end);
end $$;

-- เริ่มรอบถัดไป
create or replace function _duel_next(p_d uuid) returns void
language plpgsql security definer set search_path = public as $$
declare d duels%rowtype; qid uuid;
begin
  select * into d from duels where id = p_d;
  select id into qid from quiz_questions where active and id <> all (d.used_q) order by random() limit 1;
  if qid is null then select id into qid from quiz_questions where active order by random() limit 1; end if;
  if qid is null then raise exception 'ยังไม่มีคำถามในระบบ'; end if;
  update duels set round = round + 1, phase = 'q', cur_q = qid, round_at = now(), next_at = null,
         a_pick = null, a_ms = null, a_skill = false, b_pick = null, b_ms = null, b_skill = false, used_q = used_q || qid where id = p_d;
end $$;

-- รางวัลหลังจบ (ต้องเล่นอย่างน้อย 3 รอบ · โควตาต่อวัน · จำกัดคู่เดิมไม่ให้ปั๊ม)
create or replace function _duel_reward(p_d uuid, p_sid uuid, p_win boolean, p_draw boolean) returns int[]
language plpgsql security definer set search_path = public as $$
declare d duels%rowtype; opp uuid; used int; same int; lim int := _setting_int('duel_rewards_per_day', 5); e int; c int;
begin
  select * into d from duels where id = p_d;
  opp := case when d.a_id = p_sid then d.b_id else d.a_id end;
  select count(*) into used from duels x where x.play_date = today_th() and x.status = 'done' and x.id <> d.id and x.round >= 3
     and ((x.a_id = p_sid and (x.a_exp > 0 or x.a_coins > 0)) or (x.b_id = p_sid and (x.b_exp > 0 or x.b_coins > 0)));
  select count(*) into same from duels x where x.play_date = today_th() and x.status = 'done' and x.id <> d.id and x.round >= 3
     and ((x.a_id = p_sid and x.b_id = opp and (x.a_exp > 0 or x.a_coins > 0)) or (x.b_id = p_sid and x.a_id = opp and (x.b_exp > 0 or x.b_coins > 0)));
  if d.round < 3 or used >= lim or same >= 2 then return array[0, 0]; end if;
  e := case when p_draw then 8 when p_win then 16 else 5 end;
  c := case when p_draw then 3 when p_win then 8 else 0 end;
  e := round(e * coalesce((select reward_pct from arenas where key = d.arena), 100) / 100.0)::int;
  perform award(p_sid, e, c, 'ท้าดวลเพื่อน' || case when p_draw then ' (เสมอ)' when p_win then ' (ชนะ)' else ' (ให้กำลังใจ)' end, 'game:duel:' || d.id || ':' || p_sid);
  return array[e, c];
end $$;

create or replace function _duel_finish(p_d uuid, p_winner uuid) returns void
language plpgsql security definer set search_path = public as $$
declare d duels%rowtype; ra int[]; rb int[];
begin
  select * into d from duels where id = p_d;
  ra := _duel_reward(d.id, d.a_id, p_winner = d.a_id, p_winner is null);
  rb := _duel_reward(d.id, d.b_id, p_winner = d.b_id, p_winner is null);
  update duels set status = 'done', winner = p_winner, finished_at = now(), a_exp = ra[1], a_coins = ra[2], b_exp = rb[1], b_coins = rb[2] where id = d.id;
  perform check_achievements(d.a_id); perform check_achievements(d.b_id);
end $$;

-- ตัดสินรอบ (เรียกเมื่อทั้งคู่ตอบแล้วหรือหมดเวลา)
create or replace function _duel_resolve(p_d uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  d duels%rowtype; q quiz_questions%rowtype; sa json; sb json; ok_a boolean; ok_b boolean; da int := 0; db int := 0;
  mult numeric; ca boolean := false; cb boolean := false; fa boolean := false; fb boolean := false; first_a boolean;
  la int; lb int; ia int; ib int; luk int; sk_a boolean; sk_b boolean; win uuid; fin boolean := false;
begin
  select * into d from duels where id = p_d;
  select * into q from quiz_questions where id = d.cur_q;
  ok_a := d.a_pick is not null and d.a_pick = q.answer; ok_b := d.b_pick is not null and d.b_pick = q.answer;
  sk_a := d.a_skill and ok_a; sk_b := d.b_skill and ok_b;
  first_a := ok_a and ok_b and d.a_ms <= d.b_ms;
  if ok_a then
    sa := _stats(d.a_id); luk := coalesce((sa->'luk'->>'total')::int, 0);
    mult := 1 + coalesce((sa->'effects'->>'boss_pct')::int, 0) / 100.0;
    if d.a_ms <= 6000 then mult := mult * 1.25; fa := true; end if;
    if ok_b and first_a then mult := mult * 1.2; end if;
    if not ok_b then mult := mult * 1.15; end if;                       -- ตอบถูกคนเดียว
    if sk_a then mult := mult * 1.7; end if;
    ca := random() < least(0.3, luk * 0.01); if ca then mult := mult * 1.5; end if;
    da := greatest(1, round(16 * mult * (0.92 + random() * 0.16) + coalesce((sa->'int'->>'total')::int, 0) / 3.0)::int);
  end if;
  if ok_b then
    sb := _stats(d.b_id); luk := coalesce((sb->'luk'->>'total')::int, 0);
    mult := 1 + coalesce((sb->'effects'->>'boss_pct')::int, 0) / 100.0;
    if d.b_ms <= 6000 then mult := mult * 1.25; fb := true; end if;
    if ok_a and not first_a then mult := mult * 1.2; end if;
    if not ok_a then mult := mult * 1.15; end if;
    if sk_b then mult := mult * 1.7; end if;
    cb := random() < least(0.3, luk * 0.01); if cb then mult := mult * 1.5; end if;
    db := greatest(1, round(16 * mult * (0.92 + random() * 0.16) + coalesce((sb->'int'->>'total')::int, 0) / 3.0)::int);
  end if;
  la := greatest(0, d.a_hp - db); lb := greatest(0, d.b_hp - da);     -- a รับดาเมจของ b และกลับกัน
  ia := d.idle; ia := case when d.a_ms is null and d.b_ms is null then d.idle + 1 else 0 end;
  if la <= 0 or lb <= 0 or d.round >= 8 then
    fin := true; win := case when la > lb then d.a_id when lb > la then d.b_id else null end;
  end if;
  update duels set a_hp = la, b_hp = lb, idle = ia, phase = 'reveal', next_at = now() + interval '4.5 seconds',
    a_used = a_used or sk_a or d.a_skill, b_used = b_used or sk_b or d.b_skill,
    last = jsonb_build_object('answer', q.answer, 'explain', q.explain, 'question', q.question,
      'a', jsonb_build_object('pick', d.a_pick, 'ok', ok_a, 'dmg', da, 'crit', ca, 'fast', fa, 'first', first_a, 'skill', sk_a, 'skill_try', d.a_skill, 'ms', d.a_ms),
      'b', jsonb_build_object('pick', d.b_pick, 'ok', ok_b, 'dmg', db, 'crit', cb, 'fast', fb, 'first', ok_a and ok_b and not first_a, 'skill', sk_b, 'skill_try', d.b_skill, 'ms', d.b_ms))
   where id = d.id;
  if fin then perform _duel_finish(d.id, win);
  elsif ia >= 2 then update duels set status = 'cancelled', finished_at = now() where id = d.id; end if;
end $$;

-- ขยับสถานะตามเวลา (เรียกภายใต้ล็อกแถว)
create or replace function _duel_tick(p_d uuid) returns void
language plpgsql security definer set search_path = public as $$
declare d duels%rowtype;
begin
  select * into d from duels where id = p_d;
  if d.status = 'invited' and d.created_at < now() - interval '2 minutes' then
    update duels set status = 'expired', finished_at = now() where id = d.id; return;
  end if;
  if d.status <> 'active' then return; end if;
  if d.phase = 'q' then
    if (d.a_ms is not null and d.b_ms is not null) or now() >= d.round_at + interval '21 seconds' then perform _duel_resolve(d.id); end if;
  elsif d.next_at is not null and now() >= d.next_at then
    perform _duel_next(d.id);
  end if;
end $$;

-- ---------- RPC นักเรียน ----------
create or replace function duel_lobby(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cls uuid; act uuid; lim int := _setting_int('duel_rewards_per_day', 5); used int; w int; l int; r record;
begin
  select class_id into cls from students where id = sid;
  insert into duel_presence (student_id, seen_at) values (sid, now()) on conflict (student_id) do update set seen_at = now();
  for r in select id from duels where status in ('invited', 'active') and (a_id = sid or b_id = sid) for update loop perform _duel_tick(r.id); end loop;
  select id into act from duels where status = 'active' and (a_id = sid or b_id = sid) order by created_at desc limit 1;
  select count(*) into used from duels x where x.play_date = today_th() and x.status = 'done' and x.round >= 3
     and ((x.a_id = sid and (x.a_exp > 0 or x.a_coins > 0)) or (x.b_id = sid and (x.b_exp > 0 or x.b_coins > 0)));
  select count(*) filter (where winner = sid), count(*) filter (where winner is not null and winner <> sid) into w, l
    from duels where status = 'done' and round >= 3 and (a_id = sid or b_id = sid);
  return json_build_object('used', used, 'limit', lim, 'wins', w, 'losses', l, 'level', level_for((select exp from students where id = sid)),
    'active', case when act is null then null else _duel_view(act, sid) end,
    'invites', (select coalesce(json_agg(json_build_object('id', d.id, 'from', _duel_fighter(d.a_id), 'arena', d.arena,
                  'arena_name', (select a.name from arenas a where a.key = d.arena), 'secs', greatest(0, round(120 - extract(epoch from now() - d.created_at))::int))
                  order by d.created_at), '[]'::json) from duels d where d.status = 'invited' and d.b_id = sid),
    'sent', (select json_build_object('id', d.id, 'to', _duel_fighter(d.b_id), 'arena', d.arena, 'secs', greatest(0, round(120 - extract(epoch from now() - d.created_at))::int))
               from duels d where d.status = 'invited' and d.a_id = sid order by d.created_at desc limit 1),
    'online', (select coalesce(json_agg(json_build_object('f', _duel_fighter(s.id), 'busy', exists (select 1 from duels z where z.status = 'active' and (z.a_id = s.id or z.b_id = s.id)))
                  order by s.name), '[]'::json)
                 from students s join duel_presence p on p.student_id = s.id
                where s.class_id = cls and s.id <> sid and p.seen_at > now() - interval '75 seconds'),
    'arenas', (select coalesce(json_agg(json_build_object('key', a.key, 'name', a.name, 'emoji', a.emoji, 'theme', a.theme, 'min_level', a.min_level,
                  'locked', a.min_level > level_for((select exp from students where id = sid))) order by a.sort), '[]'::json) from arenas a where a.active));
end $$;

create or replace function duel_invite(p_token uuid, p_to uuid, p_arena text) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cls uuid; ar arenas%rowtype; did uuid;
begin
  select class_id into cls from students where id = sid;
  if p_to = sid or not exists (select 1 from students where id = p_to and class_id = cls) then raise exception 'ท้าดวลได้เฉพาะเพื่อนในห้องเดียวกัน'; end if;
  if not exists (select 1 from duel_presence where student_id = p_to and seen_at > now() - interval '75 seconds') then raise exception 'เพื่อนคนนี้ไม่ได้ออนไลน์อยู่'; end if;
  select * into ar from arenas where key = p_arena and active;
  if not found then raise exception 'ไม่พบสนาม'; end if;
  if ar.min_level > level_for((select exp from students where id = sid)) then raise exception 'ยังปลดล็อกสนามนี้ไม่ได้ (ต้องถึงเลเวล %)', ar.min_level; end if;
  update duels set status = 'cancelled', finished_at = now() where status = 'invited' and a_id = sid;
  if exists (select 1 from duels where status = 'active' and (a_id in (sid, p_to) or b_id in (sid, p_to))) then raise exception 'มีคนกำลังดวลอยู่ รอสักครู่'; end if;
  insert into duels (class_id, a_id, b_id, arena) values (cls, sid, p_to, ar.key) returning id into did;
  return json_build_object('id', did);
end $$;

create or replace function duel_respond(p_token uuid, p_duel uuid, p_accept boolean) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); d duels%rowtype;
begin
  select * into d from duels where id = p_duel and b_id = sid for update;
  if not found then raise exception 'ไม่พบคำท้า'; end if;
  perform _duel_tick(d.id); select * into d from duels where id = d.id;
  if d.status <> 'invited' then raise exception 'คำท้านี้หมดอายุหรือถูกยกเลิกแล้ว'; end if;
  if not p_accept then update duels set status = 'declined', finished_at = now() where id = d.id; return json_build_object('declined', true); end if;
  if exists (select 1 from duels where status = 'active' and (a_id in (d.a_id, sid) or b_id in (d.a_id, sid))) then raise exception 'มีคนกำลังดวลอยู่ รอสักครู่'; end if;
  update duels set status = 'active' where id = d.id;
  perform _duel_next(d.id);
  return _duel_view(d.id, sid);
end $$;

create or replace function duel_state(p_token uuid, p_duel uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); d duels%rowtype;
begin
  select * into d from duels where id = p_duel and (a_id = sid or b_id = sid) for update;
  if not found then raise exception 'ไม่พบการดวล'; end if;
  perform _duel_tick(d.id);
  insert into duel_presence (student_id, seen_at) values (sid, now()) on conflict (student_id) do update set seen_at = now();
  return _duel_view(d.id, sid);
end $$;

create or replace function duel_answer(p_token uuid, p_duel uuid, p_pick int, p_skill boolean default false) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); d duels%rowtype; ms int; me_a boolean; use_sk boolean;
begin
  select * into d from duels where id = p_duel and (a_id = sid or b_id = sid) for update;
  if not found then raise exception 'ไม่พบการดวล'; end if;
  perform _duel_tick(d.id); select * into d from duels where id = d.id;
  me_a := d.a_id = sid;
  if d.status = 'active' and d.phase = 'q' and not (case when me_a then d.a_ms is not null else d.b_ms is not null end) then
    ms := greatest(0, round(extract(epoch from now() - d.round_at) * 1000)::int);
    if ms <= 20500 then
      use_sk := coalesce(p_skill, false) and not (case when me_a then d.a_used else d.b_used end);
      if me_a then update duels set a_pick = p_pick, a_ms = ms, a_skill = use_sk where id = d.id;
      else update duels set b_pick = p_pick, b_ms = ms, b_skill = use_sk where id = d.id; end if;
      perform _duel_tick(d.id);
    end if;
  end if;
  return _duel_view(d.id, sid);
end $$;

create or replace function duel_leave(p_token uuid, p_duel uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); d duels%rowtype;
begin
  select * into d from duels where id = p_duel and (a_id = sid or b_id = sid) for update;
  if not found then raise exception 'ไม่พบการดวล'; end if;
  if d.status = 'invited' then update duels set status = case when d.a_id = sid then 'cancelled' else 'declined' end, finished_at = now() where id = d.id;
  elsif d.status = 'active' then
    update duels set a_hp = case when a_id = sid then 0 else a_hp end, b_hp = case when b_id = sid then 0 else b_hp end where id = d.id;
    perform _duel_finish(d.id, case when d.a_id = sid then d.b_id else d.a_id end);   -- ยอมแพ้/ออกกลางคัน = อีกฝ่ายชนะ
  end if;
  return _duel_view(d.id, sid);
end $$;

-- ---------- สิทธิ์ ----------
revoke execute on function _duel_fighter(uuid), _duel_skill(uuid), _duel_view(uuid, uuid), _duel_next(uuid), _duel_reward(uuid, uuid, boolean, boolean),
  _duel_finish(uuid, uuid), _duel_resolve(uuid), _duel_tick(uuid) from public, anon, authenticated;
revoke execute on function duel_lobby(uuid), duel_invite(uuid, uuid, text), duel_respond(uuid, uuid, boolean), duel_state(uuid, uuid),
  duel_answer(uuid, uuid, int, boolean), duel_leave(uuid, uuid) from public;
grant execute on function duel_lobby(uuid), duel_invite(uuid, uuid, text), duel_respond(uuid, uuid, boolean), duel_state(uuid, uuid),
  duel_answer(uuid, uuid, int, boolean), duel_leave(uuid, uuid) to anon, authenticated;
revoke execute on function battle_status(uuid), battle_start(uuid, uuid), battle_answer(uuid, uuid, int) from public;
grant execute on function battle_status(uuid), battle_start(uuid, uuid), battle_answer(uuid, uuid, int) to anon, authenticated;
