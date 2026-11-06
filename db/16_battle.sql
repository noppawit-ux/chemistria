-- =====================================================================
-- Chemistria · รอบที่ 18: มินิเกมต่อสู้มอนสเตอร์เคมี (รันซ้ำได้)
--  · ผลัดกันเดิน: เลือกสกิลของคลาส (โจมตี/บัพ/ฮีล) → ตอบคำถามให้ถูกสกิลถึงจะออก (ตอบไวโจมตีแรงขึ้น)
--  · มอนสเตอร์โจมตีกลับ → กดลูกศรตามลำดับเพื่อลดดาเมจ (ลดได้สูงสุด 80%)
--  · จบเกม: ชนะ = EXP + เหรียญ + สุ่มดรอปไอเทม · มีโควตา "รอบที่ได้รางวัล" ต่อวัน (แพ้ได้ปลอบใจเล็กน้อย)
--  · ตรวจคำตอบ/ดาเมจ/รางวัลที่เซิร์ฟเวอร์ทั้งหมด (เฉลยไม่ถูกส่งไปเบราว์เซอร์ก่อนตอบ)
-- =====================================================================
create table if not exists monsters (
  id uuid primary key default gen_random_uuid(),
  key text unique not null,
  name text not null,
  emoji text not null default '👾',
  image text,
  level int not null default 1 check (level between 1 and 5),
  hp int not null default 60 check (hp > 0),
  atk int not null default 8 check (atk > 0),
  exp int not null default 10,
  coins int not null default 5,
  atk_name text not null default 'พุ่งชน',
  descr text,
  active boolean not null default true,
  sort int not null default 0
);

create table if not exists battle_skills (
  key text primary key,
  class_key text,                       -- null = สกิลทั่วไป (ใช้เมื่อยังไม่มีคลาส)
  name text not null,
  emoji text not null default '✨',
  kind text not null check (kind in ('attack', 'buff', 'heal')),
  power int not null default 0,         -- โจมตี=ดาเมจพื้นฐาน · ฮีล=HP ที่ฟื้น
  effect text,                          -- attack: crit | buff: atk_up, shield, weak, crit_up
  cd int not null default 0,            -- เทิร์นรอก่อนใช้ซ้ำ
  descr text,
  sort int not null default 0
);

create table if not exists battles (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  monster_id uuid not null references monsters(id) on delete cascade,
  status text not null default 'active' check (status in ('active', 'won', 'lost', 'fled')),
  p_hp int not null, p_max int not null, m_hp int not null, m_max int not null,
  turn int not null default 1,
  cur_skill text, cur_q uuid, asked_at timestamptz,
  pend jsonb,
  buffs jsonb not null default '{}'::jsonb,
  cds jsonb not null default '{}'::jsonb,
  used_q uuid[] not null default '{}',
  correct int not null default 0,
  rewarded boolean not null default false,
  exp int not null default 0, coins int not null default 0, drop_name text,
  play_date date not null default today_th(),
  created_at timestamptz default now(), finished_at timestamptz
);
create index if not exists idx_battles_student on battles(student_id, play_date);

do $$
declare t text;
begin
  foreach t in array array['monsters', 'battle_skills', 'battles'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists teacher_all on public.%I', t);
    execute format('create policy teacher_all on public.%I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;

insert into app_settings (key, value) values ('battle_rewards_per_day', '3') on conflict (key) do nothing;

-- ---------- มอนสเตอร์ระดับอ่อน ----------
insert into monsters (key, name, emoji, image, level, hp, atk, exp, coins, atk_name, descr, sort) values
  ('bubble', 'บับเบิลโซดา',        '🫧', 'assets/monsters/bubble.png', 1, 60, 8,  10, 6,  'ฟองแตกกระจาย',   'ฟองโซดาซนๆ ชอบแตกใส่หน้า', 1),
  ('rust',   'สนิมจอมตะกละ',       '🟤', 'assets/monsters/rust.png',   1, 80, 10, 14, 8,  'สนิมกัดเหล็ก',   'กินเหล็กทุกอย่างที่ขวางหน้า', 2),
  ('salt',   'เกลือจอมซ่า',        '🧂', 'assets/monsters/salt.png',   2, 100, 12, 18, 10, 'ผลึกแหลมคม',    'ผลึก NaCl จอมกวนที่ชอบสาดเกลือ', 3),
  ('lemon',  'กรดมะนาวจิ๋ว',       '🍋', 'assets/monsters/lemon.png',  2, 120, 14, 22, 12, 'หยดกรดเปรี้ยว', 'เปรี้ยวจี๊ด! ระวังหยดกรด', 4),
  ('fog',    'หมอกแอมโมเนีย',      '🌫️', 'assets/monsters/fog.png',    3, 140, 16, 28, 15, 'ควันฉุนพิษ',   'หมอกหลอนกลิ่นฉุนที่ลอยมาไม่รู้ตัว', 5)
on conflict (key) do nothing;

-- ---------- สกิลตามคลาส (โจมตี / บัพ / ฮีล) ----------
insert into battle_skills (key, class_key, name, emoji, kind, power, effect, cd, descr, sort) values
  ('alc_fire',  'alchemist', 'ปฏิกิริยาเดือด',     '🔥', 'attack', 22, null,       0, 'โจมตีด้วยเปลวไฟจากปฏิกิริยาเคมี', 1),
  ('alc_boost', 'alchemist', 'สูตรเร่งปฏิกิริยา',   '🧪', 'buff',    0, 'atk_up',   3, 'การโจมตี 2 ครั้งถัดไปแรงขึ้น +50%', 2),
  ('alc_heal',  'alchemist', 'ยาฟื้นฟูจากธาตุ',    '💧', 'heal',   30, null,       3, 'ฟื้นฟู HP', 3),
  ('sci_shock', 'scientist', 'ช็อตไฟฟ้า',          '⚡', 'attack', 22, null,       0, 'ปล่อยกระแสไฟฟ้าใส่เป้าหมาย', 1),
  ('sci_scan',  'scientist', 'วิเคราะห์จุดอ่อน',   '🔬', 'buff',    0, 'weak',     3, 'มอนสเตอร์รับดาเมจเพิ่ม +40% นาน 3 เทิร์น', 2),
  ('sci_heal',  'scientist', 'สารฟื้นฟูเซลล์',     '🩹', 'heal',   26, null,       3, 'ฟื้นฟู HP', 3),
  ('gua_strike','guardian',  'ฟาดด้วยพลังโมล',     '⚔️', 'attack', 20, null,       0, 'ฟาดด้วยอาวุธแห่งโมล', 1),
  ('gua_shield','guardian',  'โล่โมล',             '🛡️', 'buff',    0, 'shield',   3, 'ลดดาเมจที่ได้รับ 50% ในการโจมตี 2 ครั้งถัดไป', 2),
  ('gua_heal',  'guardian',  'ฟื้นฟูผู้พิทักษ์',   '💚', 'heal',   34, null,       4, 'ฟื้นฟู HP มาก', 3),
  ('see_dice',  'seeker',    'ลูกเต๋าโชคชะตา',     '🎲', 'attack', 20, 'crit',     0, 'มีโอกาสคริติคอล x2 (ยิ่งโชคสูงยิ่งออกบ่อย)', 1),
  ('see_luck',  'seeker',    'พรโชคดี',            '🍀', 'buff',    0, 'crit_up',  3, 'การโจมตี 2 ครั้งถัดไปคริติคอลแน่นอน', 2),
  ('see_heal',  'seeker',    'น้ำพุโชคลาภ',        '✨', 'heal',   24, null,       3, 'ฟื้นฟู HP', 3),
  ('gen_hit',   null,        'โจมตีพื้นฐาน',       '💥', 'attack', 18, null,       0, 'โจมตีธรรมดา (เลือกคลาสเพื่อปลดล็อกสกิลพิเศษ)', 1),
  ('gen_focus', null,        'ตั้งสมาธิ',          '📈', 'buff',    0, 'atk_up',   3, 'การโจมตี 2 ครั้งถัดไปแรงขึ้น +50%', 2),
  ('gen_heal',  null,        'ปฐมพยาบาล',          '🩹', 'heal',   22, null,       3, 'ฟื้นฟู HP', 3)
on conflict (key) do nothing;

-- ---------- ฟังก์ชันภายใน ----------
create or replace function _battle_skillset(p_sid uuid) returns setof battle_skills
language sql stable security definer set search_path = public as $$
  select * from battle_skills
   where class_key is not distinct from (
     case when exists (select 1 from battle_skills k join students s on s.char_class = k.class_key where s.id = p_sid)
          then (select char_class from students where id = p_sid) else null end)
   order by sort
$$;

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
    'monster', json_build_object('id', m.id, 'name', m.name, 'emoji', m.emoji, 'image', m.image, 'level', m.level, 'atk_name', m.atk_name),
    'buffs', b.buffs, 'skills', sk, 'q', q, 'pend', pv, 'correct', b.correct, 'rewarded', b.rewarded,
    'exp', b.exp, 'coins', b.coins, 'drop', b.drop_name);
end $$;

-- ดรอปไอเทมหลังชนะ: สุ่มจากไอเทมกาชา N/R (มีโอกาส SR เล็กน้อย เพิ่มตามค่าโชค)
create or replace function _battle_drop(p_sid uuid, p_battle uuid) returns json
language plpgsql security definer set search_path = public as $$
declare it gacha_items%rowtype; luk int := coalesce((_stats(p_sid)->'luk'->>'total')::int, 0); sr boolean; chance numeric; refund int;
begin
  chance := least(0.9, 0.6 + luk * 0.02);
  if random() > chance then return null; end if;
  sr := random() < least(0.3, 0.06 + luk * 0.01);
  select * into it from gacha_items
   where active and kind in ('coins', 'exp', 'cosmetic', 'decor') and rarity = any (case when sr then array['SR'] else array['N', 'R'] end)
   order by -ln(greatest(random(), 1e-9)) / weight limit 1;
  if not found then
    select * into it from gacha_items where active and kind in ('coins', 'exp', 'cosmetic', 'decor') and rarity in ('N', 'R')
     order by random() limit 1;
  end if;
  if not found then return null; end if;
  if it.kind = 'coins' then perform award(p_sid, 0, it.value, 'ดรอปมอนสเตอร์: ' || it.name, null);
  elsif it.kind = 'exp' then perform award(p_sid, it.value, 0, 'ดรอปมอนสเตอร์: ' || it.name, null);
  elsif it.kind = 'cosmetic' then
    insert into inventory (student_id, item_id) values (p_sid, it.id)
    on conflict (student_id, item_id) do update set qty = inventory.qty + 1;
  elsif it.kind = 'decor' and it.decor_id is not null then
    if exists (select 1 from student_decor where student_id = p_sid and item_id = it.decor_id) then
      refund := case it.rarity when 'SR' then 20 else 8 end;
      perform award(p_sid, 0, refund, 'ไอเทมตกแต่งซ้ำ: ' || it.name, null);
    else
      insert into student_decor (student_id, item_id, source) values (p_sid, it.decor_id, 'gacha');
    end if;
  end if;
  update battles set drop_name = it.name where id = p_battle;
  return json_build_object('name', it.name, 'rarity', it.rarity, 'kind', it.kind, 'value', it.value, 'emoji', it.emoji, 'image', it.image_url);
end $$;

-- ---------- RPC นักเรียน ----------
create or replace function battle_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); act uuid; used int; lim int := _setting_int('battle_rewards_per_day', 3);
begin
  select id into act from battles where student_id = sid and status = 'active' order by created_at desc limit 1;
  select count(*) into used from battles where student_id = sid and play_date = today_th() and rewarded;
  return json_build_object('used', used, 'limit', lim,
    'p_max', 80 + 6 * level_for((select exp from students where id = sid)),
    'monsters', (select coalesce(json_agg(json_build_object('id', m.id, 'name', m.name, 'emoji', m.emoji, 'image', m.image, 'level', m.level,
        'hp', m.hp, 'atk', m.atk, 'exp', m.exp, 'coins', m.coins, 'descr', m.descr) order by m.sort, m.level), '[]'::json) from monsters m where m.active),
    'skills', (select coalesce(json_agg(json_build_object('key', s.key, 'name', s.name, 'emoji', s.emoji, 'kind', s.kind, 'descr', s.descr, 'cd', s.cd) order by s.sort), '[]'::json)
                 from _battle_skillset(sid) s),
    'active', case when act is null then null else _battle_view(act) end);
end $$;

create or replace function battle_start(p_token uuid, p_monster uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); m monsters%rowtype; used int; lim int := _setting_int('battle_rewards_per_day', 3); pm int; bid uuid;
begin
  select * into m from monsters where id = p_monster and active;
  if not found then raise exception 'ไม่พบมอนสเตอร์'; end if;
  update battles set status = 'fled', finished_at = now() where student_id = sid and status = 'active';
  select count(*) into used from battles where student_id = sid and play_date = today_th() and rewarded;
  pm := 80 + 6 * level_for((select exp from students where id = sid));
  insert into battles (student_id, monster_id, p_hp, p_max, m_hp, m_max, rewarded)
  values (sid, m.id, pm, pm, m.hp, m.hp, used < lim) returning id into bid;
  return _battle_view(bid);
end $$;

create or replace function battle_ask(p_token uuid, p_battle uuid, p_skill text) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); b battles%rowtype; sk battle_skills%rowtype; qid uuid;
begin
  select * into b from battles where id = p_battle and student_id = sid for update;
  if not found or b.status <> 'active' then raise exception 'ไม่พบการต่อสู้ที่กำลังเล่นอยู่'; end if;
  if b.pend is not null then raise exception 'ต้องป้องกันการโจมตีของมอนสเตอร์ก่อน'; end if;
  if b.cur_q is not null then return _battle_view(b.id); end if;
  select s.* into sk from _battle_skillset(sid) s where s.key = p_skill;
  if not found then raise exception 'สกิลนี้ใช้ไม่ได้'; end if;
  if coalesce((b.cds->>sk.key)::int, 0) > 0 then raise exception 'สกิลยังรอคูลดาวน์'; end if;
  select id into qid from quiz_questions where active and id <> all (b.used_q) order by random() limit 1;
  if qid is null then select id into qid from quiz_questions where active order by random() limit 1; end if;
  if qid is null then raise exception 'ยังไม่มีคำถามในระบบ'; end if;
  update battles set cur_skill = sk.key, cur_q = qid, asked_at = now(), used_q = used_q || qid where id = b.id;
  return _battle_view(b.id);
end $$;

create or replace function battle_answer(p_token uuid, p_battle uuid, p_pick int) returns json
language plpgsql security definer set search_path = public as $$
declare
  sid uuid := _sid(p_token); b battles%rowtype; m monsters%rowtype; sk battle_skills%rowtype; q quiz_questions%rowtype;
  st json; elapsed numeric; ok boolean; dmg int := 0; heal int := 0; crit boolean := false; fast boolean := false; mult numeric;
  bf jsonb; cdz jsonb; k text; n int; seqs text := ''; i int; rw_exp int := 0; rw_coins int := 0; drop json := null; ev jsonb;
  luk int; critp numeric; intl int;
begin
  select * into b from battles where id = p_battle and student_id = sid for update;
  if not found or b.status <> 'active' then raise exception 'ไม่พบการต่อสู้ที่กำลังเล่นอยู่'; end if;
  if b.cur_q is null or b.pend is not null then raise exception 'ยังไม่ได้เลือกสกิล'; end if;
  select * into m from monsters where id = b.monster_id;
  select * into sk from battle_skills where key = b.cur_skill;
  select * into q from quiz_questions where id = b.cur_q;
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
      rw_coins := m.coins;
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

create or replace function battle_defend(p_token uuid, p_battle uuid, p_hits int) returns json
language plpgsql security definer set search_path = public as $$
declare
  sid uuid := _sid(p_token); b battles%rowtype; m monsters%rowtype; n int; hits int; dmg int; fin int; shield boolean := false;
  bf jsonb; el numeric; rw_exp int := 0; ev jsonb;
begin
  select * into b from battles where id = p_battle and student_id = sid for update;
  if not found or b.status <> 'active' or b.pend is null then raise exception 'ไม่มีการโจมตีให้ป้องกัน'; end if;
  select * into m from monsters where id = b.monster_id;
  n := (b.pend->>'n')::int; dmg := (b.pend->>'dmg')::int;
  el := extract(epoch from now()) - (b.pend->>'at')::numeric;
  hits := greatest(0, least(coalesce(p_hits, 0), n));
  if el < 0.25 * hits then hits := 0; end if;              -- เร็วเกินคนกดไม่ทัน = ไม่นับ
  fin := round(dmg * (1 - 0.8 * hits / n))::int;
  bf := b.buffs;
  if coalesce((bf->>'shield')::int, 0) > 0 then
    shield := true; fin := round(fin * 0.5)::int; bf := jsonb_set(bf, '{shield}', to_jsonb((bf->>'shield')::int - 1));
  end if;
  fin := greatest(case when hits = n then 0 else 1 end, fin);
  if coalesce((bf->>'weak')::int, 0) > 0 then bf := jsonb_set(bf, '{weak}', to_jsonb((bf->>'weak')::int - 1)); end if;
  b.p_hp := greatest(0, b.p_hp - fin);
  ev := jsonb_build_object('hits', hits, 'n', n, 'taken', fin, 'raw', dmg, 'shield', shield);
  if b.p_hp <= 0 then
    if b.rewarded then
      rw_exp := least(6, b.correct * 2);
      if rw_exp > 0 then perform award(sid, rw_exp, 0, 'สู้มอนสเตอร์: ' || m.name || ' (ให้กำลังใจ)', 'game:battle:' || b.id); end if;
    end if;
    update battles set status = 'lost', finished_at = now(), p_hp = 0, pend = null, buffs = bf, exp = rw_exp, turn = b.turn + 1 where id = b.id;
  else
    update battles set p_hp = b.p_hp, pend = null, buffs = bf, turn = b.turn + 1 where id = b.id;
  end if;
  return json_build_object('event', ev, 'state', _battle_view(b.id));
end $$;

create or replace function battle_flee(p_token uuid, p_battle uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  update battles set status = 'fled', finished_at = now(), pend = null, cur_q = null
   where id = p_battle and student_id = _sid(p_token) and status = 'active';
end $$;

-- ---------- สิทธิ์ ----------
revoke execute on function _battle_skillset(uuid), _battle_view(uuid), _battle_drop(uuid, uuid) from public, anon, authenticated;
revoke execute on function battle_status(uuid), battle_start(uuid, uuid), battle_ask(uuid, uuid, text),
  battle_answer(uuid, uuid, int), battle_defend(uuid, uuid, int), battle_flee(uuid, uuid) from public;
grant execute on function battle_status(uuid), battle_start(uuid, uuid), battle_ask(uuid, uuid, text),
  battle_answer(uuid, uuid, int), battle_defend(uuid, uuid, int), battle_flee(uuid, uuid) to anon, authenticated;
