-- =====================================================================
-- ระบบจัดการห้องเรียนครูบุ๊ค (Kru Book Classroom RPG) — schema แกนหลัก
-- รันทั้งไฟล์ใน Supabase > SQL Editor (รันซ้ำได้ ไม่ทำให้ข้อมูลหาย)
-- แนวคิดความปลอดภัย:
--   * ครู  = Supabase Auth (อีเมล/รหัสผ่าน) + ตาราง teachers + RLS
--   * นักเรียน = ไม่แตะตารางโดยตรง เรียกผ่านฟังก์ชัน (RPC) ด้วย token หลังล็อกอินเลขที่ + PIN
-- =====================================================================

create extension if not exists pgcrypto with schema extensions;

-- ---------- ตั้งค่า / ครู ----------
create table if not exists app_settings (
  key text primary key,
  value text not null
);

create table if not exists teachers (
  email text primary key
);

create or replace function is_teacher() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from teachers
    where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;

create or replace function today_th() returns date
language sql stable as $$ select (now() at time zone 'Asia/Bangkok')::date $$;

-- ---------- ห้องเรียน / นักเรียน ----------
create table if not exists classes (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,            -- รหัสห้อง ใช้ล็อกอิน เช่น M6-2
  name text not null,                   -- เช่น ม.6/2
  subject_code text,                    -- เช่น ว33225
  subject_name text,
  term text default '2569/2',
  bonus_cap int not null default 5,     -- เพดานคะแนนพิเศษ (ครูกำหนดเอง)
  created_at timestamptz default now()
);

create table if not exists students (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references classes(id) on delete cascade,
  no int not null,                      -- เลขที่
  name text not null,
  pin_hash text,
  avatar text not null default '🧪',
  exp int not null default 0,
  coins int not null default 0,
  gacha_pity int not null default 0,
  fail_count int not null default 0,
  locked_until timestamptz,
  last_login timestamptz,
  created_at timestamptz default now(),
  unique (class_id, no)
);

create table if not exists student_sessions (
  token uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  expires_at timestamptz not null default now() + interval '30 days'
);

-- ---------- เช็คชื่อ ----------
create table if not exists ch_attendance (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references classes(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  att_date date not null,
  status text not null check (status in ('present','late','absent','leave')),
  note text,
  unique (student_id, class_id, att_date)
);

-- ---------- งาน / การส่งงาน ----------
create table if not exists ch_assignments (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references classes(id) on delete cascade,
  title text not null,
  description text,
  due_date date,
  max_score numeric not null default 10,
  exp_reward int not null default 20,
  coin_reward int not null default 5,
  created_at timestamptz default now()
);

create table if not exists ch_submissions (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid not null references ch_assignments(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  status text not null check (status in ('submitted','late','missing')),
  score numeric,
  submitted_at timestamptz default now(),
  unique (assignment_id, student_id)
);

-- ---------- ปฏิทินรายวิชา ----------
create table if not exists events (
  id uuid primary key default gen_random_uuid(),
  class_id uuid references classes(id) on delete cascade,   -- null = ทุกห้อง
  title text not null,
  event_date date not null,
  end_date date,
  kind text not null default 'lesson'
    check (kind in ('lesson','assignment','exam','holiday','activity')),
  note text
);

-- ---------- คะแนน (รวมเป็นผลรวมคะแนนดิบ ไม่ปรับสัดส่วน) ----------
create table if not exists score_items (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references classes(id) on delete cascade,
  category text not null check (category in
    ('pre_mid','midterm','post_mid','final','behavior','bonus')),
  title text not null,
  max_score numeric not null default 10,
  created_at timestamptz default now()
);

create table if not exists scores (
  item_id uuid not null references score_items(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  score numeric not null,
  primary key (item_id, student_id)
);

-- ---------- EXP / เหรียญ (สมุดบัญชี กันให้ซ้ำด้วย ref_key) ----------
create table if not exists ledger (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  exp int not null default 0,
  coins int not null default 0,
  reason text,
  ref_key text,
  created_at timestamptz default now(),
  unique (student_id, ref_key)
);

-- ---------- เควส ----------
create table if not exists quests (
  id uuid primary key default gen_random_uuid(),
  class_id uuid references classes(id) on delete cascade,   -- null = ทุกห้อง
  title text not null,
  description text,
  kind text not null default 'daily' check (kind in ('daily','weekly')),
  exp int not null default 10,
  coins int not null default 3,
  needs_approval boolean not null default true,
  active boolean not null default true
);

create table if not exists quest_claims (
  id uuid primary key default gen_random_uuid(),
  quest_id uuid not null references quests(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  claim_date date not null,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz default now(),
  unique (quest_id, student_id, claim_date)
);

-- ---------- สิทธิพิเศษ ----------
create table if not exists privileges (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  emoji text default '🎟️',
  cost int,                              -- เหรียญที่ใช้แลกในร้าน; null = ได้จากกาชาอย่างเดียว
  active boolean not null default true
);

create table if not exists redemptions (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  privilege_id uuid not null references privileges(id) on delete cascade,
  source text not null default 'shop' check (source in ('shop','gacha','teacher')),
  status text not null default 'available'
    check (status in ('available','requested','approved','rejected')),
  created_at timestamptz default now(),
  used_at timestamptz
);

-- ---------- กาชา ----------
create table if not exists gacha_items (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  rarity text not null check (rarity in ('N','R','SR','SSR')),
  kind text not null check (kind in ('coins','exp','cosmetic','privilege')),
  value int not null default 0,          -- จำนวนเหรียญ/EXP
  privilege_id uuid references privileges(id) on delete set null,
  emoji text default '🎁',
  image_url text,
  weight int not null default 10 check (weight > 0),
  active boolean not null default true
);

create table if not exists gacha_pulls (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  item_id uuid references gacha_items(id) on delete set null,
  cost int not null default 0,
  created_at timestamptz default now()
);

create table if not exists inventory (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  item_id uuid not null references gacha_items(id) on delete cascade,
  qty int not null default 1,
  unique (student_id, item_id)
);

-- ---------- Achievement ----------
create table if not exists achievements (
  id uuid primary key default gen_random_uuid(),
  key text unique not null,
  name text not null,
  description text,
  emoji text default '🏅',
  metric text not null check (metric in
    ('attendance_count','present_count','attendance_streak','ontime_submissions',
     'total_exp','level','gacha_pulls','quests_done')),
  threshold int not null,
  reward_exp int not null default 0,
  reward_coins int not null default 0,
  reward_privilege_id uuid references privileges(id) on delete set null,
  active boolean not null default true
);

create table if not exists student_achievements (
  student_id uuid not null references students(id) on delete cascade,
  achievement_id uuid not null references achievements(id) on delete cascade,
  earned_at timestamptz default now(),
  primary key (student_id, achievement_id)
);

-- ---------- แรงค์ / คลาส ----------
create table if not exists ch_ranks (
  key text primary key,
  name text not null,
  sort int not null,
  min_exp int not null,             -- EXP ขั้นต่ำของแรงค์นี้
  divisions int not null default 4, -- จำนวนดิวิชัน (IV..I); 1 = ไม่มีดิวิชัน
  image text
);

create table if not exists char_classes (
  key text primary key,
  name text not null,
  emoji text default '🧪',
  description text,
  ability text,                     -- คำอธิบายความสามารถพิเศษ (ผลจริงกำหนดตาม key)
  image text,
  sort int not null default 0,
  active boolean not null default true
);

alter table students add column if not exists char_class text references char_classes(key) on delete set null;
alter table students add column if not exists class_changes int not null default 0;

create index if not exists idx_att_student on ch_attendance(student_id, att_date desc);
create index if not exists idx_sub_student on ch_submissions(student_id);
create index if not exists idx_ledger_student on ledger(student_id, created_at desc);

-- =====================================================================
-- ฟังก์ชันภายใน (ไม่เปิดให้ผู้ใช้เรียกตรง)
-- =====================================================================
create or replace function level_for(p_exp int) returns int
language sql immutable as $$
  select floor(sqrt(greatest(p_exp, 0) / 40.0))::int + 1
$$;

create or replace function rank_for(p_level int) returns text
language sql immutable as $$
  select case
    when p_level >= 15 then 'Legend'
    when p_level >= 11 then 'Diamond'
    when p_level >= 8  then 'Platinum'
    when p_level >= 5  then 'Gold'
    when p_level >= 3  then 'Silver'
    else 'Bronze' end
$$;

create or replace function rank_info(p_exp int) returns json
language plpgsql stable security definer set search_path = public as $$
declare t ch_ranks%rowtype; nx ch_ranks%rowtype; span int; slice numeric; idx int; lo int; hi int;
        romans text[] := array['I','II','III','IV','V','VI'];
begin
  select * into t from ch_ranks where min_exp <= greatest(p_exp, 0) order by min_exp desc limit 1;
  if not found then select * into t from ch_ranks order by min_exp limit 1; end if;
  select * into nx from ch_ranks where min_exp > t.min_exp order by min_exp limit 1;
  if not found then
    return json_build_object('key', t.key, 'name', t.name, 'image', t.image, 'division', '',
      'lp', greatest(p_exp, 0) - t.min_exp, 'lp_max', null, 'exp_lo', t.min_exp, 'exp_hi', null,
      'next', null, 'top', true);
  end if;
  span := nx.min_exp - t.min_exp;
  if t.divisions <= 1 then
    lo := t.min_exp; hi := nx.min_exp;
    return json_build_object('key', t.key, 'name', t.name, 'image', t.image, 'division', '',
      'lp', floor(100.0 * (p_exp - lo) / (hi - lo))::int, 'lp_max', 100, 'exp_lo', lo, 'exp_hi', hi,
      'next', nx.name, 'top', false);
  end if;
  slice := span::numeric / t.divisions;
  idx := least(t.divisions - 1, floor((greatest(p_exp, 0) - t.min_exp) / slice)::int);
  lo := t.min_exp + round(idx * slice)::int;
  hi := t.min_exp + round((idx + 1) * slice)::int;
  return json_build_object('key', t.key, 'name', t.name, 'image', t.image,
    'division', romans[t.divisions - idx],
    'lp', floor(100.0 * (p_exp - lo) / (hi - lo))::int, 'lp_max', 100, 'exp_lo', lo, 'exp_hi', hi,
    'next', case when idx = t.divisions - 1 then nx.name else t.name || ' ' || romans[t.divisions - idx - 1] end,
    'top', false);
end $$;

create or replace function student_class(p_student uuid) returns text
language sql stable security definer set search_path = public as $$
  select char_class from students where id = p_student
$$;

create or replace function quest_period(p_kind text, p_date date) returns date
language sql immutable as $$
  select case when p_kind = 'weekly' then date_trunc('week', p_date)::date else p_date end
$$;

create or replace function award(p_student uuid, p_exp int, p_coins int, p_reason text, p_ref text default null)
returns boolean language plpgsql security definer set search_path = public as $$
declare v uuid; cls text; e int := p_exp; c int := p_coins; rs text := p_reason;
begin
  -- ความสามารถคลาส: โบนัสเฉพาะรางวัลจากเช็คชื่อ / ส่งงาน / เควส
  if p_ref ~ '^(att|sub|quest):' then
    cls := student_class(p_student);
    if cls = 'scientist' and e > 0 then e := ceil(e * 1.15)::int; rs := rs || ' (โบนัสนักทดลอง)'; end if;
    if cls = 'alchemist' and c > 0 then c := ceil(c * 1.25)::int; rs := rs || ' (โบนัสนักเล่นแร่แปรธาตุ)'; end if;
  end if;
  insert into ledger (student_id, exp, coins, reason, ref_key)
  values (p_student, e, c, rs, p_ref)
  on conflict (student_id, ref_key) do nothing
  returning id into v;
  if v is null then return false; end if;
  update students
     set exp = greatest(0, exp + e),
         coins = greatest(0, coins + c)
   where id = p_student;
  return true;
end $$;

create or replace function student_metric(p_student uuid, p_metric text) returns int
language plpgsql stable security definer set search_path = public as $$
declare n int := 0; r record;
begin
  case p_metric
    when 'attendance_count' then
      select count(*) into n from ch_attendance where student_id = p_student and status in ('present','late');
    when 'present_count' then
      select count(*) into n from ch_attendance where student_id = p_student and status = 'present';
    when 'attendance_streak' then
      -- จำนวนคาบล่าสุดที่มาต่อเนื่อง (มาสาย/ลา ไม่นับว่าขาด แต่มาสายไม่เพิ่มสตรีค)
      for r in select status from ch_attendance where student_id = p_student order by att_date desc loop
        exit when r.status = 'absent';
        if r.status = 'present' then n := n + 1; end if;
      end loop;
    when 'ontime_submissions' then
      select count(*) into n from ch_submissions where student_id = p_student and status = 'submitted';
    when 'total_exp' then
      select exp into n from students where id = p_student;
    when 'level' then
      select level_for(exp) into n from students where id = p_student;
    when 'gacha_pulls' then
      select count(*) into n from gacha_pulls where student_id = p_student;
    when 'quests_done' then
      select count(*) into n from quest_claims where student_id = p_student and status = 'approved';
    else n := 0;
  end case;
  return coalesce(n, 0);
end $$;

create or replace function check_achievements(p_student uuid) returns int
language plpgsql security definer set search_path = public as $$
declare a record; got int := 0;
begin
  for a in
    select * from achievements ac
    where ac.active
      and not exists (select 1 from student_achievements sa
                      where sa.student_id = p_student and sa.achievement_id = ac.id)
  loop
    if student_metric(p_student, a.metric) >= a.threshold then
      insert into student_achievements (student_id, achievement_id)
      values (p_student, a.id) on conflict do nothing;
      perform award(p_student, a.reward_exp, a.reward_coins, 'Achievement: ' || a.name, 'ach:' || a.id);
      if a.reward_privilege_id is not null then
        insert into redemptions (student_id, privilege_id, source)
        values (p_student, a.reward_privilege_id, 'teacher');
      end if;
      got := got + 1;
    end if;
  end loop;
  return got;
end $$;

create or replace function _sid(p_token uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare v uuid;
begin
  select student_id into v from student_sessions where token = p_token and expires_at > now();
  if v is null then raise exception 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่'; end if;
  return v;
end $$;

-- ---------- ทริกเกอร์ให้ EXP อัตโนมัติ ----------
create or replace function trg_attendance() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'present' then
    perform award(new.student_id, 5, 2, 'มาเรียนตรงเวลา ' || new.att_date, 'att:' || new.id);
  elsif new.status = 'late' then
    if student_class(new.student_id) = 'guardian' then
      perform award(new.student_id, 5, 2, 'มาเรียน (สาย — ผู้พิทักษ์ได้เต็ม) ' || new.att_date, 'att:' || new.id);
    else
      perform award(new.student_id, 2, 1, 'มาเรียน (สาย) ' || new.att_date, 'att:' || new.id);
    end if;
  end if;
  perform check_achievements(new.student_id);
  return new;
end $$;

drop trigger if exists attendance_award on ch_attendance;
create trigger attendance_award after insert or update of status on ch_attendance
  for each row execute function trg_attendance();

create or replace function trg_submission() returns trigger
language plpgsql security definer set search_path = public as $$
declare a ch_assignments%rowtype;
begin
  select * into a from ch_assignments where id = new.assignment_id;
  if new.status = 'submitted' then
    perform award(new.student_id, a.exp_reward, a.coin_reward, 'ส่งงาน: ' || a.title, 'sub:' || new.id);
  elsif new.status = 'late' then
    if student_class(new.student_id) = 'guardian' then
      perform award(new.student_id, a.exp_reward, a.coin_reward, 'ส่งงาน (ช้า — ผู้พิทักษ์ได้เต็ม): ' || a.title, 'sub:' || new.id);
    else
      perform award(new.student_id, a.exp_reward / 2, a.coin_reward / 2, 'ส่งงาน (ช้า): ' || a.title, 'sub:' || new.id);
    end if;
  end if;
  perform check_achievements(new.student_id);
  return new;
end $$;

drop trigger if exists submission_award on ch_submissions;
create trigger submission_award after insert or update of status on ch_submissions
  for each row execute function trg_submission();

create or replace function trg_quest_claim() returns trigger
language plpgsql security definer set search_path = public as $$
declare q quests%rowtype;
begin
  if new.status = 'approved' then
    select * into q from quests where id = new.quest_id;
    perform award(new.student_id, q.exp, q.coins, 'เควส: ' || q.title, 'quest:' || new.id);
    perform check_achievements(new.student_id);
  end if;
  return new;
end $$;

drop trigger if exists quest_claim_award on quest_claims;
create trigger quest_claim_award after insert or update of status on quest_claims
  for each row execute function trg_quest_claim();

-- =====================================================================
-- RPC สำหรับนักเรียน (เรียกด้วย anon key + token)
-- =====================================================================
create or replace function student_login(p_class_code text, p_no int, p_pin text)
returns json language plpgsql security definer set search_path = public, extensions as $$
declare s students%rowtype; t uuid;
begin
  select st.* into s from students st join classes c on c.id = st.class_id
   where upper(c.code) = upper(trim(p_class_code)) and st.no = p_no;
  if not found then raise exception 'ไม่พบห้องหรือเลขที่นี้'; end if;
  if s.locked_until is not null and s.locked_until > now() then
    raise exception 'ใส่ PIN ผิดหลายครั้ง กรุณารอสักครู่แล้วลองใหม่';
  end if;
  if s.pin_hash is null or crypt(p_pin, s.pin_hash) <> s.pin_hash then
    -- ไม่ใช้ raise ที่นี่ เพราะ exception จะย้อนการนับครั้งที่ผิดกลับไปด้วย
    update students
       set locked_until = case when fail_count + 1 >= 5 then now() + interval '10 minutes' else locked_until end,
           fail_count = case when fail_count + 1 >= 5 then 0 else fail_count + 1 end
     where id = s.id;
    return json_build_object('error', 'PIN ไม่ถูกต้อง');
  end if;
  update students set fail_count = 0, locked_until = null, last_login = now() where id = s.id;
  insert into student_sessions (student_id) values (s.id) returning token into t;
  delete from student_sessions where student_id = s.id and expires_at < now();
  return json_build_object('token', t, 'name', s.name);
end $$;

-- รายชื่อห้องสำหรับหน้าล็อกอิน (เปิดเผยเฉพาะรหัสและชื่อห้อง)
create or replace function list_classes() returns json
language sql stable security definer set search_path = public as $$
  select coalesce(json_agg(json_build_object('code', code, 'name', name, 'subject', subject_name) order by name), '[]'::json)
  from classes
$$;

create or replace function todays_quests(p_class uuid, p_date date)
returns setof quests language sql stable security definer set search_path = public as $$
  (select * from quests
    where active and kind = 'daily' and (class_id is null or class_id = p_class)
    order by md5(id::text || p_date::text)
    limit coalesce((select value::int from app_settings where key = 'daily_quest_count'), 3))
  union all
  (select * from quests
    where active and kind = 'weekly' and (class_id is null or class_id = p_class))
$$;

create or replace function student_dashboard(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare
  sid uuid := _sid(p_token);
  s students%rowtype; c classes%rowtype;
  today date := today_th();
  lv int;
  show_sc boolean := coalesce((select value from app_settings where key = 'show_scores'), '1') = '1';
begin
  select * into s from students where id = sid;
  select * into c from classes where id = s.class_id;
  lv := level_for(s.exp);
  return json_build_object(
    'student', json_build_object(
      'id', s.id, 'no', s.no, 'name', s.name, 'avatar', s.avatar,
      'exp', s.exp, 'coins', s.coins, 'level', lv, 'rank', (rank_info(s.exp)->>'name'), 'char_class', s.char_class,
      'exp_this_level', (40 * power(lv - 1, 2))::int,
      'exp_next_level', (40 * power(lv, 2))::int,
      'pity', s.gacha_pity, 'decor', _decor_of(s.id)),
    'rank_info', rank_info(s.exp),
    'ranks', (select coalesce(json_agg(json_build_object('key', r.key, 'name', r.name, 'min_exp', r.min_exp,
        'image', r.image) order by r.sort), '[]'::json) from ch_ranks r),
    'classes', (select coalesce(json_agg(json_build_object('key', k.key, 'name', k.name, 'emoji', k.emoji,
        'description', k.description, 'ability', k.ability, 'image', k.image) order by k.sort), '[]'::json)
        from char_classes k where k.active),
    'class_change_cost', coalesce((select value::int from app_settings where key = 'class_change_cost'), 100),
    'class_free', s.class_changes = 0,
    'class', json_build_object('id', c.id, 'code', c.code, 'name', c.name,
                               'subject_code', c.subject_code, 'subject_name', c.subject_name),
    'settings', json_build_object(
      'gacha_cost', coalesce((select value::int from app_settings where key = 'gacha_cost'), 30),
      'pity_max', coalesce((select value::int from app_settings where key = 'pity_max'), 10),
      'show_scores', show_sc),
    'attendance', (select coalesce(json_agg(json_build_object('date', att_date, 'status', status) order by att_date desc), '[]'::json)
                     from (select att_date, status from ch_attendance where student_id = sid order by att_date desc limit 120) a),
    'attendance_summary', json_build_object(
      'present', student_metric(sid, 'present_count'),
      'late', (select count(*) from ch_attendance where student_id = sid and status = 'late'),
      'absent', (select count(*) from ch_attendance where student_id = sid and status = 'absent'),
      'leave', (select count(*) from ch_attendance where student_id = sid and status = 'leave'),
      'streak', student_metric(sid, 'attendance_streak')),
    'assignments', (select coalesce(json_agg(json_build_object(
        'id', a.id, 'title', a.title, 'description', a.description, 'due_date', a.due_date,
        'max_score', a.max_score, 'exp', a.exp_reward, 'coins', a.coin_reward,
        'status', sb.status, 'score', case when show_sc then sb.score end) order by a.due_date nulls last, a.created_at), '[]'::json)
        from ch_assignments a
        left join ch_submissions sb on sb.assignment_id = a.id and sb.student_id = sid
       where a.class_id = c.id),
    'events', (select coalesce(json_agg(json_build_object('id', e.id, 'title', e.title, 'date', e.event_date,
        'end_date', e.end_date, 'kind', e.kind, 'note', e.note) order by e.event_date), '[]'::json)
        from events e
       where (e.class_id is null or e.class_id = c.id)
         and e.event_date between today - 30 and today + 120),
    'scores', case when show_sc then (select coalesce(json_agg(json_build_object(
        'category', si.category, 'title', si.title, 'max', si.max_score, 'score', sc.score) order by si.created_at), '[]'::json)
        from score_items si left join scores sc on sc.item_id = si.id and sc.student_id = sid
       where si.class_id = c.id) else '[]'::json end,
    'quests', (select coalesce(json_agg(json_build_object(
        'id', q.id, 'title', q.title, 'description', q.description, 'kind', q.kind,
        'exp', q.exp, 'coins', q.coins, 'needs_approval', q.needs_approval,
        'status', (select cl.status from quest_claims cl
                    where cl.quest_id = q.id and cl.student_id = sid
                      and cl.claim_date = quest_period(q.kind, today)))), '[]'::json)
        from todays_quests(c.id, today) q),
    'achievements', (select coalesce(json_agg(json_build_object(
        'id', ac.id, 'name', ac.name, 'description', ac.description, 'emoji', ac.emoji, 'image', to_jsonb(ac)->>'image',
        'threshold', ac.threshold, 'metric', ac.metric, 'progress', student_metric(sid, ac.metric),
        'earned_at', sa.earned_at, 'reward_exp', ac.reward_exp, 'reward_coins', ac.reward_coins)
        order by ac.metric, ac.threshold), '[]'::json)
        from achievements ac
        left join student_achievements sa on sa.achievement_id = ac.id and sa.student_id = sid
       where ac.active),
    'inventory', (select coalesce(json_agg(json_build_object('item_id', gi.id, 'name', gi.name,
        'rarity', gi.rarity, 'emoji', gi.emoji, 'image', gi.image_url, 'qty', inv.qty,
        'equipped', coalesce(gi.image_url, gi.emoji) = s.avatar)), '[]'::json)
        from inventory inv join gacha_items gi on gi.id = inv.item_id where inv.student_id = sid),
    'privileges', (select coalesce(json_agg(json_build_object('id', r.id, 'name', p.name, 'description', p.description,
        'emoji', p.emoji, 'status', r.status, 'source', r.source) order by r.created_at desc), '[]'::json)
        from redemptions r join privileges p on p.id = r.privilege_id where r.student_id = sid),
    'shop', (select coalesce(json_agg(json_build_object('id', p.id, 'name', p.name, 'description', p.description,
        'emoji', p.emoji, 'cost', p.cost) order by p.cost), '[]'::json)
        from privileges p where p.active and p.cost is not null),
    'gacha_pool', (select coalesce(json_agg(json_build_object('name', gi.name, 'rarity', gi.rarity, 'emoji', gi.emoji, 'image', gi.image_url)
        order by case gi.rarity when 'SSR' then 1 when 'SR' then 2 when 'R' then 3 else 4 end), '[]'::json)
        from gacha_items gi where gi.active),
    'decor_catalog', (select coalesce(json_agg(json_build_object('id', d.id, 'slot', d.slot, 'key', d.key, 'color', d.color,
        'emoji', d.emoji, 'name', d.name, 'rarity', d.rarity, 'price', d.price, 'image', d.image,
        'owned', exists (select 1 from student_decor sd where sd.student_id = sid and sd.item_id = d.id),
        'in_gacha', exists (select 1 from gacha_items gi where gi.decor_id = d.id and gi.active))
        order by d.slot, d.sort, d.price nulls last), '[]'::json) from decor_items d where d.active),
    'leaderboard', (select coalesce(json_agg(json_build_object('name', x.name, 'avatar', x.avatar, 'exp', x.exp, 'char_class', x.char_class,
        'level', level_for(x.exp), 'rank_info', rank_info(x.exp), 'decor', _decor_of(x.id), 'me', x.id = sid) order by x.exp desc), '[]'::json)
        from (select id, name, avatar, exp, char_class from students where class_id = c.id order by exp desc limit 10) x),
    'ledger', (select coalesce(json_agg(json_build_object('reason', l.reason, 'exp', l.exp, 'coins', l.coins,
        'at', l.created_at) order by l.created_at desc), '[]'::json)
        from (select * from ledger where student_id = sid order by created_at desc limit 20) l)
  );
end $$;

create or replace function claim_quest(p_token uuid, p_quest uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); s students%rowtype; q quests%rowtype; st text; per date;
begin
  select * into s from students where id = sid;
  select * into q from todays_quests(s.class_id, today_th()) t where t.id = p_quest;
  if not found then raise exception 'เควสนี้ไม่ได้เปิดให้ทำวันนี้'; end if;
  per := quest_period(q.kind, today_th());
  st := case when q.needs_approval then 'pending' else 'approved' end;
  begin
    insert into quest_claims (quest_id, student_id, claim_date, status) values (q.id, sid, per, st);
  exception when unique_violation then
    raise exception 'ทำเควสนี้ไปแล้ว';
  end;
  return json_build_object('status', st);
end $$;

create or replace function gacha_pick(p_high boolean) returns gacha_items
language plpgsql security definer set search_path = public as $$
declare total int; r numeric; acc int := 0; it gacha_items%rowtype; last_it gacha_items%rowtype;
begin
  select coalesce(sum(weight), 0) into total from gacha_items
   where active and (not p_high or rarity in ('SR','SSR'));
  if total = 0 then raise exception 'ยังไม่มีไอเทมในกาชา'; end if;
  r := random() * total;
  for it in select * from gacha_items
             where active and (not p_high or rarity in ('SR','SSR')) order by id loop
    acc := acc + it.weight;
    last_it := it;
    if r < acc then return it; end if;
  end loop;
  return last_it;
end $$;

create or replace function gacha_pull(p_token uuid, p_n int default 1) returns json
language plpgsql security definer set search_path = public as $$
declare
  sid uuid := _sid(p_token); s students%rowtype;
  unit int := coalesce((select value::int from app_settings where key = 'gacha_cost'), 30);
  pity_max int := coalesce((select value::int from app_settings where key = 'pity_max'), 10);
  cost int; i int; it gacha_items%rowtype; high boolean; res jsonb := '[]'::jsonb; refund int := 0;
begin
  if student_class(sid) = 'seeker' then pity_max := greatest(3, pity_max - 2); end if;
  if p_n not in (1, 10) then raise exception 'จำนวนครั้งไม่ถูกต้อง'; end if;
  cost := unit * p_n;
  select * into s from students where id = sid for update;
  if s.coins < cost then raise exception 'เหรียญไม่พอ (ต้องใช้ % เหรียญ)', cost; end if;
  update students set coins = coins - cost where id = sid;
  for i in 1..p_n loop
    select * into s from students where id = sid;
    high := s.gacha_pity + 1 >= pity_max;
    it := gacha_pick(high);
    if it.rarity in ('SR','SSR') then
      update students set gacha_pity = 0 where id = sid;
    else
      update students set gacha_pity = gacha_pity + 1 where id = sid;
    end if;
    insert into gacha_pulls (student_id, item_id, cost) values (sid, it.id, unit);
    if it.kind = 'coins' then
      perform award(sid, 0, it.value, 'กาชา: ' || it.name, null);
    elsif it.kind = 'exp' then
      perform award(sid, it.value, 0, 'กาชา: ' || it.name, null);
    elsif it.kind = 'cosmetic' then
      insert into inventory (student_id, item_id) values (sid, it.id)
      on conflict (student_id, item_id) do update set qty = inventory.qty + 1;
    elsif it.kind = 'privilege' and it.privilege_id is not null then
      insert into redemptions (student_id, privilege_id, source) values (sid, it.privilege_id, 'gacha');
    elsif it.kind = 'decor' and it.decor_id is not null then
      if exists (select 1 from student_decor where student_id = sid and item_id = it.decor_id) then
        refund := case it.rarity when 'SSR' then 40 when 'SR' then 20 when 'R' then 10 else 5 end;
        perform award(sid, 0, refund, 'ไอเทมตกแต่งซ้ำ: ' || it.name, null);
      else
        insert into student_decor (student_id, item_id, source) values (sid, it.decor_id, 'gacha');
        refund := 0;
      end if;
    end if;
    res := res || jsonb_build_object('name', it.name, 'rarity', it.rarity, 'kind', it.kind,
                                     'value', it.value, 'emoji', it.emoji, 'image', it.image_url,
                                     'dup_refund', case when it.kind = 'decor' then refund else 0 end);
  end loop;
  perform check_achievements(sid);
  select * into s from students where id = sid;
  return json_build_object('items', res, 'coins', s.coins, 'exp', s.exp, 'pity', s.gacha_pity);
end $$;

create or replace function set_avatar(p_token uuid, p_item uuid) returns void
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); e text;
begin
  if p_item is null then
    update students set avatar = '🧪' where id = sid;
    return;
  end if;
  select coalesce(gi.image_url, gi.emoji) into e from inventory inv join gacha_items gi on gi.id = inv.item_id
   where inv.student_id = sid and inv.item_id = p_item and gi.kind = 'cosmetic';
  if e is null then raise exception 'ยังไม่มีไอเทมนี้'; end if;
  update students set avatar = e where id = sid;
end $$;

create or replace function choose_class(p_token uuid, p_key text) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); s students%rowtype; k char_classes%rowtype;
        cost int := coalesce((select value::int from app_settings where key = 'class_change_cost'), 100);
begin
  select * into k from char_classes where key = p_key and active;
  if not found then raise exception 'ไม่พบคลาสนี้'; end if;
  select * into s from students where id = sid for update;
  if s.char_class = p_key then raise exception 'คุณเป็นคลาสนี้อยู่แล้ว'; end if;
  if s.class_changes > 0 then
    if s.coins < cost then raise exception 'เหรียญไม่พอ (เปลี่ยนคลาสใช้ % เหรียญ)', cost; end if;
    update students set coins = coins - cost where id = sid;
    insert into ledger (student_id, exp, coins, reason) values (sid, 0, -cost, 'เปลี่ยนคลาสเป็น ' || k.name);
  end if;
  update students set char_class = p_key, class_changes = class_changes + 1 where id = sid;
  return json_build_object('class', k.name, 'paid', case when s.class_changes > 0 then cost else 0 end);
end $$;

create or replace function buy_privilege(p_token uuid, p_privilege uuid) returns void
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); p privileges%rowtype; s students%rowtype;
begin
  select * into p from privileges where id = p_privilege and active and cost is not null;
  if not found then raise exception 'ไม่พบสิทธิพิเศษนี้'; end if;
  select * into s from students where id = sid for update;
  if s.coins < p.cost then raise exception 'เหรียญไม่พอ'; end if;
  update students set coins = coins - p.cost where id = sid;
  insert into ledger (student_id, exp, coins, reason) values (sid, 0, -p.cost, 'แลกสิทธิพิเศษ: ' || p.name);
  insert into redemptions (student_id, privilege_id, source) values (sid, p.id, 'shop');
end $$;

create or replace function request_privilege(p_token uuid, p_redemption uuid) returns void
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  update redemptions set status = 'requested'
   where id = p_redemption and student_id = sid and status = 'available';
  if not found then raise exception 'ใช้สิทธิ์นี้ไม่ได้'; end if;
end $$;

create or replace function change_pin(p_token uuid, p_old text, p_new text) returns void
language plpgsql security definer set search_path = public, extensions as $$
declare sid uuid := _sid(p_token); s students%rowtype;
begin
  if p_new !~ '^[0-9]{4,6}$' then raise exception 'PIN ต้องเป็นตัวเลข 4-6 หลัก'; end if;
  select * into s from students where id = sid;
  if crypt(p_old, s.pin_hash) <> s.pin_hash then raise exception 'PIN เดิมไม่ถูกต้อง'; end if;
  update students set pin_hash = crypt(p_new, gen_salt('bf')) where id = sid;
end $$;

-- =====================================================================
-- RPC สำหรับครู (ตรวจ is_teacher() ภายใน)
-- =====================================================================
create or replace function admin_add_students(p_class uuid, p_students jsonb, p_pin text default '1234')
returns int language plpgsql security definer set search_path = public, extensions as $$
declare r jsonb; n int := 0;
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  for r in select * from jsonb_array_elements(p_students) loop
    insert into students (class_id, no, name, pin_hash)
    values (p_class, (r ->> 'no')::int, r ->> 'name', crypt(p_pin, gen_salt('bf')))
    on conflict (class_id, no) do update set name = excluded.name;
    n := n + 1;
  end loop;
  return n;
end $$;

create or replace function admin_reset_pin(p_student uuid, p_pin text default '1234') returns void
language plpgsql security definer set search_path = public, extensions as $$
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  update students set pin_hash = crypt(p_pin, gen_salt('bf')), fail_count = 0, locked_until = null
   where id = p_student;
end $$;

create or replace function admin_adjust(p_student uuid, p_exp int, p_coins int, p_reason text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  perform award(p_student, p_exp, p_coins, coalesce(nullif(p_reason, ''), 'ครูปรับให้'), null);
  perform check_achievements(p_student);
end $$;

-- p_records: [{"student_id": "...", "status": "present"}, ...]
create or replace function admin_mark_attendance(p_class uuid, p_date date, p_records jsonb) returns int
language plpgsql security definer set search_path = public as $$
declare r jsonb; n int := 0;
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  for r in select * from jsonb_array_elements(p_records) loop
    insert into ch_attendance (class_id, student_id, att_date, status)
    values (p_class, (r ->> 'student_id')::uuid, p_date, r ->> 'status')
    on conflict (student_id, class_id, att_date) do update set status = excluded.status;
    n := n + 1;
  end loop;
  return n;
end $$;

-- p_records: [{"student_id": "...", "status": "submitted|late|missing", "score": 8}, ...]
create or replace function admin_mark_submissions(p_assignment uuid, p_records jsonb) returns int
language plpgsql security definer set search_path = public as $$
declare r jsonb; n int := 0;
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  for r in select * from jsonb_array_elements(p_records) loop
    insert into ch_submissions (assignment_id, student_id, status, score)
    values (p_assignment, (r ->> 'student_id')::uuid, r ->> 'status', nullif(r ->> 'score', '')::numeric)
    on conflict (assignment_id, student_id)
      do update set status = excluded.status, score = excluded.score;
    n := n + 1;
  end loop;
  return n;
end $$;

create or replace function admin_review_quest(p_claim uuid, p_approve boolean) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  update quest_claims set status = case when p_approve then 'approved' else 'rejected' end
   where id = p_claim and status = 'pending';
end $$;

create or replace function admin_review_privilege(p_redemption uuid, p_approve boolean) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  update redemptions
     set status = case when p_approve then 'approved' else 'rejected' end,
         used_at = case when p_approve then now() end
   where id = p_redemption and status = 'requested';
end $$;

-- ---------- สมุดคะแนนรวม (ผลรวมคะแนนดิบ + คะแนนพิเศษไม่เกินเพดาน) ----------
create or replace view v_gradebook with (security_invoker = true) as
select
  st.id as student_id, st.class_id, st.no, st.name,
  coalesce(sum(sc.score) filter (where si.category = 'pre_mid'), 0)  as pre_mid,
  coalesce(sum(sc.score) filter (where si.category = 'midterm'), 0)  as midterm,
  coalesce(sum(sc.score) filter (where si.category = 'post_mid'), 0) as post_mid,
  coalesce(sum(sc.score) filter (where si.category = 'final'), 0)    as final,
  coalesce(sum(sc.score) filter (where si.category = 'behavior'), 0) as behavior,
  least(coalesce(sum(sc.score) filter (where si.category = 'bonus'), 0), cl.bonus_cap) as bonus,
  coalesce(sum(sc.score) filter (where si.category <> 'bonus'), 0)   as total,
  coalesce(sum(sc.score) filter (where si.category <> 'bonus'), 0)
    + least(coalesce(sum(sc.score) filter (where si.category = 'bonus'), 0), cl.bonus_cap) as total_with_bonus
from students st
join classes cl on cl.id = st.class_id
left join score_items si on si.class_id = st.class_id
left join scores sc on sc.item_id = si.id and sc.student_id = st.id
group by st.id, st.class_id, st.no, st.name, cl.bonus_cap;

-- =====================================================================
-- สิทธิ์การเข้าถึง
-- =====================================================================
do $$
declare t text;
begin
  -- เฉพาะตารางของ Chemistria เท่านั้น (ไม่แตะตารางของระบบ KruBook เก่า: players, quiz_log ฯลฯ)
  foreach t in array array['app_settings','teachers','classes','students','student_sessions',
    'ch_attendance','ch_assignments','ch_submissions','events','score_items','scores','ledger',
    'quests','quest_claims','privileges','redemptions','gacha_items','gacha_pulls','inventory',
    'achievements','student_achievements','ch_ranks','char_classes'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists teacher_all on public.%I', t);
    execute format('create policy teacher_all on public.%I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;
grant select on v_gradebook to authenticated;

-- ปิดฟังก์ชันภายในไม่ให้เรียกจากเว็บ
revoke execute on function award(uuid, int, int, text, text) from public, anon, authenticated;
revoke execute on function rank_info(int) from public, anon, authenticated;
revoke execute on function student_class(uuid) from public, anon, authenticated;
revoke execute on function check_achievements(uuid) from public, anon, authenticated;
revoke execute on function student_metric(uuid, text) from public, anon, authenticated;
revoke execute on function _sid(uuid) from public, anon, authenticated;
revoke execute on function gacha_pick(boolean) from public, anon, authenticated;
revoke execute on function todays_quests(uuid, date) from public, anon, authenticated;

-- เปิดเฉพาะ RPC นักเรียนให้ anon
revoke execute on function student_login(text, int, text) from public;
revoke execute on function student_dashboard(uuid) from public;
revoke execute on function claim_quest(uuid, uuid) from public;
revoke execute on function gacha_pull(uuid, int) from public;
revoke execute on function set_avatar(uuid, uuid) from public;
revoke execute on function choose_class(uuid, text) from public;
revoke execute on function buy_privilege(uuid, uuid) from public;
revoke execute on function request_privilege(uuid, uuid) from public;
revoke execute on function change_pin(uuid, text, text) from public;
revoke execute on function list_classes() from public;
grant execute on function list_classes() to anon, authenticated;
grant execute on function student_login(text, int, text) to anon, authenticated;
grant execute on function student_dashboard(uuid) to anon, authenticated;
grant execute on function claim_quest(uuid, uuid) to anon, authenticated;
grant execute on function gacha_pull(uuid, int) to anon, authenticated;
grant execute on function set_avatar(uuid, uuid) to anon, authenticated;
grant execute on function choose_class(uuid, text) to anon, authenticated;
grant execute on function buy_privilege(uuid, uuid) to anon, authenticated;
grant execute on function request_privilege(uuid, uuid) to anon, authenticated;
grant execute on function change_pin(uuid, text, text) to anon, authenticated;

-- RPC ของครู: เฉพาะผู้ล็อกอิน (และตรวจ is_teacher ภายในอีกชั้น)
revoke execute on function admin_add_students(uuid, jsonb, text) from public, anon;
revoke execute on function admin_reset_pin(uuid, text) from public, anon;
revoke execute on function admin_adjust(uuid, int, int, text) from public, anon;
revoke execute on function admin_mark_attendance(uuid, date, jsonb) from public, anon;
revoke execute on function admin_mark_submissions(uuid, jsonb) from public, anon;
revoke execute on function admin_review_quest(uuid, boolean) from public, anon;
revoke execute on function admin_review_privilege(uuid, boolean) from public, anon;
grant execute on function admin_add_students(uuid, jsonb, text) to authenticated;
grant execute on function admin_reset_pin(uuid, text) to authenticated;
grant execute on function admin_adjust(uuid, int, int, text) to authenticated;
grant execute on function admin_mark_attendance(uuid, date, jsonb) to authenticated;
grant execute on function admin_mark_submissions(uuid, jsonb) to authenticated;
grant execute on function admin_review_quest(uuid, boolean) to authenticated;
grant execute on function admin_review_privilege(uuid, boolean) to authenticated;
