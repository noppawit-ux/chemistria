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
-- =====================================================================
-- ข้อมูลตั้งต้น (แก้ไขได้ทั้งหมดในหน้าแอดมิน) — รันหลัง 01_schema.sql
-- รันซ้ำได้: เติมเฉพาะตารางที่ยังว่าง
-- =====================================================================

insert into app_settings (key, value) values
  ('gacha_cost', '30'),          -- เหรียญต่อ 1 ครั้ง
  ('pity_max', '10'),            -- สุ่มครบกี่ครั้งการันตี SR ขึ้นไป
  ('daily_quest_count', '3'),    -- จำนวนเควสประจำวันที่สุ่มให้
  ('show_scores', '1')           -- 1 = นักเรียนเห็นคะแนนของตัวเอง
on conflict (key) do nothing;

-- บัญชีครูที่เข้าหน้าแอดมินได้ (ต้องสร้างผู้ใช้อีเมลเดียวกันใน Authentication ด้วย)
insert into teachers (email) values ('noppawit@nonghanwit.ac.th') on conflict do nothing;

-- ห้องเรียนปีการศึกษา 2569 (รหัสห้องใช้ตอนนักเรียนล็อกอิน)
insert into classes (code, name, subject_code, subject_name)
select * from (values
  ('M6-2',  'ม.6/2',  'ว33225', 'เคมี'),
  ('M6-4',  'ม.6/4',  'ว33225', 'เคมี'),
  ('M6-6',  'ม.6/6',  'ว33225', 'เคมี'),
  ('M2-16', 'ม.2/16', 'ว20204', 'เชื้อเพลิงเพื่อการคมนาคม'),
  ('M2-17', 'ม.2/17', 'ว20204', 'เชื้อเพลิงเพื่อการคมนาคม'),
  ('M1-1',  'ม.1/1',  'ว20201', 'เคมี')
) v(code, name, subject_code, subject_name)
where not exists (select 1 from classes);

-- สิทธิพิเศษ (ตัวอย่าง — ปรับ/ปิดได้ตามที่ครูเห็นสมควร)
insert into privileges (name, description, emoji, cost)
select * from (values
  ('เลือกที่นั่ง 1 คาบ',       'เลือกที่นั่งเองได้ 1 คาบเรียน',                 '💺', 40),
  ('ต่อเวลาส่งงาน 1 วัน',      'ขอขยายเวลาส่งงาน 1 ชิ้นออกไปอีก 1 วัน',          '⏰', 80),
  ('คะแนนพิเศษ +1',            'ขอรับคะแนนพิเศษ 1 คะแนน (รวมไม่เกินเพดานที่ครูกำหนด)', '⭐', null::int)
) v(name, description, emoji, cost)
where not exists (select 1 from privileges);

-- ไอเทมกาชา
insert into gacha_items (name, rarity, kind, value, emoji, weight, privilege_id)
select v.name, v.rarity, v.kind, v.value, v.emoji, v.weight,
       (select id from privileges p where p.name = v.priv)
from (values
  ('เหรียญ +10',            'N',   'coins',     10, '🪙', 30, null),
  ('EXP +10',               'N',   'exp',       10, '✨', 25, null),
  ('เหรียญ +25',            'R',   'coins',     25, '💰', 15, null),
  ('EXP +30',               'R',   'exp',       30, '🌟', 12, null),
  ('อวาตาร์ หลอดทดลอง',     'R',   'cosmetic',   0, '🧫', 6,  null),
  ('อวาตาร์ DNA',           'SR',  'cosmetic',   0, '🧬', 4,  null),
  ('อวาตาร์ ขวดกลั่น',      'SR',  'cosmetic',   0, '⚗️', 4,  null),
  ('คูปองเลือกที่นั่ง',      'SR',  'privilege',  0, '💺', 3,  'เลือกที่นั่ง 1 คาบ'),
  ('คูปองต่อเวลาส่งงาน',     'SSR', 'privilege',  0, '⏰', 1,  'ต่อเวลาส่งงาน 1 วัน'),
  ('คูปองคะแนนพิเศษ +1',    'SSR', 'privilege',  0, '⭐', 1,  'คะแนนพิเศษ +1'),
  ('อวาตาร์ นักเล่นแร่แปรธาตุ','SSR', 'cosmetic',  0, '🧙', 1,  null)
) v(name, rarity, kind, value, emoji, weight, priv)
where not exists (select 1 from gacha_items);

-- Achievement (ด้าน "เก็บเวลา" = มาเรียนตรงเวลา / สตรีค / ส่งงานตรงเวลา)
insert into achievements (key, name, description, emoji, metric, threshold, reward_exp, reward_coins)
select * from (values
  ('present_5',   'ตรงเวลาสไตล์ธาตุเฉื่อย', 'มาเรียนตรงเวลาครบ 5 คาบ',          '⏱️', 'present_count',      5,  30, 10),
  ('present_20',  'นาฬิกาอะตอม',            'มาเรียนตรงเวลาครบ 20 คาบ',         '⌚', 'present_count',      20, 100, 30),
  ('streak_5',    'สตรีคไฟลุก',             'มาตรงเวลาติดต่อกัน 5 คาบ',          '🔥', 'attendance_streak',  5,  50, 15),
  ('streak_10',   'ปฏิกิริยาลูกโซ่',         'มาตรงเวลาติดต่อกัน 10 คาบ',         '⚡', 'attendance_streak',  10, 120, 40),
  ('ontime_3',    'ส่งงานทันใจ',            'ส่งงานตรงเวลา 3 ชิ้น',              '📬', 'ontime_submissions', 3,  30, 10),
  ('ontime_10',   'นักส่งงานมือโปร',         'ส่งงานตรงเวลา 10 ชิ้น',             '📦', 'ontime_submissions', 10, 100, 30),
  ('quest_5',     'นักผจญภัยฝึกหัด',         'ทำเควสสำเร็จ 5 ครั้ง',              '🗺️', 'quests_done',        5,  40, 10),
  ('quest_20',    'ฮีโร่แห่งเคมีเรีย',       'ทำเควสสำเร็จ 20 ครั้ง',             '🛡️', 'quests_done',        20, 150, 50),
  ('gacha_10',    'สายสุ่ม',                'สุ่มกาชาครบ 10 ครั้ง',              '🎰', 'gacha_pulls',        10, 30, 0),
  ('level_5',     'เลเวล 5',                'ไปถึงเลเวล 5',                      '🏆', 'level',              5,  0,  30),
  ('level_10',    'เลเวล 10',               'ไปถึงเลเวล 10',                     '👑', 'level',              10, 0,  80)
) v(key, name, description, emoji, metric, threshold, reward_exp, reward_coins)
where not exists (select 1 from achievements);

-- เควส (ประจำวันสุ่มวันละ 3 ข้อ / รายสัปดาห์แสดงทุกข้อ)
insert into quests (title, description, kind, exp, coins, needs_approval)
select * from (values
  ('อ่านบทเรียนก่อนเข้าเรียน', 'อ่านเนื้อหาที่จะเรียนวันนี้ แล้วแจ้งครูเมื่อพร้อม',      'daily', 10, 3, true),
  ('ถามคำถามที่น่าสนใจ',       'ถามคำถามเกี่ยวกับเคมี 1 ข้อในคาบ',                      'daily', 15, 5, true),
  ('ช่วยเพื่อนเข้าใจ',          'อธิบายเรื่องที่เรียนให้เพื่อนฟัง 1 คน',                  'daily', 15, 5, true),
  ('จดโน้ตสรุป',               'สรุปเนื้อหาวันนี้ลงสมุด/โน้ตของตัวเอง',                  'daily', 10, 3, true),
  ('เก็บของให้เรียบร้อย',       'ช่วยจัดห้อง/เก็บอุปกรณ์หลังคาบ',                          'daily', 8,  2, true),
  ('ตอบคำถามท้ายคาบถูก',       'ตอบคำถามท้ายคาบได้ถูกต้อง',                              'daily', 12, 4, true),
  ('ส่งงานครบทุกชิ้นในสัปดาห์', 'ส่งงานทุกชิ้นที่ครูมอบหมายภายในสัปดาห์นี้',              'weekly', 40, 15, true)
) v(title, description, kind, exp, coins, needs_approval)
where not exists (select 1 from quests);


-- ---------- แรงค์ (สไตล์ LoL: แต่ละแรงค์มีดิวิชัน IV→I; Master ขึ้นไปไม่มีดิวิชัน) ----------
insert into ch_ranks (key, name, sort, min_exp, divisions, image)
select * from (values
  ('iron',        'Iron',         1,    0, 4, 'assets/ranks/iron.png'),
  ('bronze',      'Bronze',       2,  100, 4, 'assets/ranks/bronze.png'),
  ('silver',      'Silver',       3,  250, 4, 'assets/ranks/silver.png'),
  ('gold',        'Gold',         4,  450, 4, 'assets/ranks/gold.png'),
  ('platinum',    'Platinum',     5,  700, 4, 'assets/ranks/platinum.png'),
  ('emerald',     'Emerald',      6, 1000, 4, 'assets/ranks/emerald.png'),
  ('diamond',     'Diamond',      7, 1400, 4, 'assets/ranks/diamond.png'),
  ('master',      'Master',       8, 1900, 1, 'assets/ranks/master.png'),
  ('grandmaster', 'Grandmaster',  9, 2500, 1, 'assets/ranks/grandmaster.png'),
  ('challenger',  'Challenger',  10, 3200, 1, 'assets/ranks/challenger.png')
) v(key, name, sort, min_exp, divisions, image)
where not exists (select 1 from ch_ranks);

-- ---------- คลาสตัวละคร (ผลของความสามารถกำหนดตามรหัส key ในฐานข้อมูล แก้ชื่อ/คำอธิบาย/รูปได้ในแอดมิน) ----------
insert into char_classes (key, name, emoji, description, ability, image, sort)
select * from (values
  ('alchemist', 'นักเล่นแร่แปรธาตุ', '⚗️', 'เปลี่ยนความขยันเป็นทอง', 'ได้เหรียญจากเช็คชื่อ ส่งงาน และเควส เพิ่ม +25%', 'assets/avatars/alchemist.png', 1),
  ('scientist', 'นักทดลอง',          '🧪', 'ยิ่งทดลอง ยิ่งเก่ง',        'ได้ EXP จากเช็คชื่อ ส่งงาน และเควส เพิ่ม +15%',    'assets/avatars/scientist.png', 2),
  ('guardian',  'ผู้พิทักษ์',         '🛡️', 'ไม่ทิ้งใครไว้ข้างหลัง',    'มาสาย/ส่งงานช้า ได้รางวัลเต็ม เหมือนตรงเวลา',        'assets/avatars/guardian.png',  3),
  ('seeker',    'นักล่าโชค',          '🍀', 'โชคดีเข้าข้างคนกล้า',       'กาชาการันตี SR ขึ้นไปเร็วขึ้น 2 ครั้ง (ทุก 8 ครั้งแทน 10)', 'assets/avatars/seeker.png',    4)
) v(key, name, emoji, description, ability, image, sort)
where not exists (select 1 from char_classes);

insert into app_settings (key, value) values ('class_change_cost', '100') on conflict (key) do nothing;

-- ---------- ภาพไอเทมกาชา (ใส่เฉพาะไอเทมที่ยังไม่มีรูป) ----------
update gacha_items g set image_url = v.img
from (values
  ('เหรียญ +10',               'assets/items/pouch.png'),
  ('EXP +10',                  'assets/items/crystal.png'),
  ('เหรียญ +25',               'assets/items/chest.png'),
  ('EXP +30',                  'assets/items/wand.png'),
  ('อวาตาร์ หลอดทดลอง',        'assets/items/potion_green.png'),
  ('อวาตาร์ DNA',              'assets/items/microscope.png'),
  ('อวาตาร์ ขวดกลั่น',         'assets/items/potion_red.png'),
  ('คูปองเลือกที่นั่ง',         'assets/items/tile.png'),
  ('คูปองต่อเวลาส่งงาน',        'assets/items/hourglass.png'),
  ('คูปองคะแนนพิเศษ +1',       'assets/items/ticket.png'),
  ('อวาตาร์ นักเล่นแร่แปรธาตุ', 'assets/items/crown.png')
) v(name, img)
where g.name = v.name and g.image_url is null;
-- =====================================================================
-- Chemistria · รอบที่ 3: มินิเกม (ควิซประจำวัน + จับคู่ธาตุ)
-- รันซ้ำได้ (idempotent) · ต้องรัน 01_schema.sql และ 02_seed.sql ก่อน
-- =====================================================================

create table if not exists quiz_questions (
  id uuid primary key default gen_random_uuid(),
  topic text not null default 'ทั่วไป',
  question text not null,
  a text not null, b text not null, c text not null, d text not null,
  answer int not null default 0 check (answer between 0 and 3),   -- 0=ก 1=ข 2=ค 3=ง
  explain text,
  active boolean not null default true
);

create table if not exists game_plays (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  game text not null check (game in ('quiz','match')),
  play_date date not null default today_th(),
  score int not null default 0,
  correct int,
  exp int not null default 0,
  coins int not null default 0,
  created_at timestamptz default now()
);
create unique index if not exists uq_quiz_once_a_day on game_plays(student_id, play_date) where game = 'quiz';
create index if not exists idx_game_plays_day on game_plays(student_id, play_date);

do $$
declare t text;
begin
  foreach t in array array['quiz_questions','game_plays'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists teacher_all on public.%I', t);
    execute format('create policy teacher_all on public.%I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;

insert into app_settings (key, value) values
  ('game_daily_cap_exp', '40'),     -- EXP รวมจากมินิเกมสูงสุดต่อวัน
  ('quiz_count', '5'),              -- จำนวนข้อควิซประจำวัน
  ('quiz_exp_per_correct', '4'),    -- EXP ต่อข้อที่ตอบถูก
  ('quiz_perfect_bonus', '5'),      -- โบนัส EXP เมื่อถูกทุกข้อ
  ('match_max_exp', '10'),          -- EXP สูงสุดต่อรอบเกมจับคู่ธาตุ
  ('match_plays_per_day', '3')      -- เล่นจับคู่ที่ได้รางวัลสูงสุดกี่รอบต่อวัน
on conflict (key) do nothing;

-- ---------------------------------------------------------------------
-- ฟังก์ชันภายใน
-- ---------------------------------------------------------------------
create or replace function _setting_int(p_key text, p_def int) returns int
language sql stable security definer set search_path = public as $$
  select coalesce((select nullif(value, '')::int from app_settings where key = p_key), p_def)
$$;

create or replace function _game_exp_today(p_sid uuid) returns int
language sql stable security definer set search_path = public as $$
  select coalesce(sum(exp), 0)::int from game_plays where student_id = p_sid and play_date = today_th()
$$;

-- ชุดคำถามของนักเรียนวันนั้น: สุ่มแบบคงที่ต่อคนต่อวัน (เปิดกี่ครั้งก็ได้ชุดเดิม)
create or replace function _quiz_ids(p_sid uuid, p_date date) returns uuid[]
language sql stable security definer set search_path = public as $$
  select coalesce(array_agg(id order by k), '{}') from (
    select id, md5(id::text || p_sid::text || p_date::text) as k
      from quiz_questions where active order by k limit _setting_int('quiz_count', 5)
  ) s
$$;

create or replace function _quiz_streak(p_sid uuid) returns int
language plpgsql stable security definer set search_path = public as $$
declare d date := today_th(); n int := 0;
begin
  if not exists (select 1 from game_plays where student_id = p_sid and game = 'quiz' and play_date = d) then
    d := d - 1;
  end if;
  while exists (select 1 from game_plays where student_id = p_sid and game = 'quiz' and play_date = d) loop
    n := n + 1; d := d - 1;
  end loop;
  return n;
end $$;

-- ---------------------------------------------------------------------
-- RPC นักเรียน
-- ---------------------------------------------------------------------
create or replace function game_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); d date := today_th(); qp game_plays%rowtype;
begin
  select * into qp from game_plays where student_id = sid and game = 'quiz' and play_date = d;
  return json_build_object(
    'exp_today', _game_exp_today(sid),
    'cap', _setting_int('game_daily_cap_exp', 40),
    'quiz_done', found,
    'quiz_score', qp.correct,
    'quiz_exp', qp.exp,
    'quiz_total', coalesce(array_length(_quiz_ids(sid, d), 1), 0),
    'streak', _quiz_streak(sid),
    'per_correct', _setting_int('quiz_exp_per_correct', 4),
    'perfect_bonus', _setting_int('quiz_perfect_bonus', 5),
    'match_plays', (select count(*) from game_plays where student_id = sid and game = 'match' and play_date = d),
    'match_max_plays', _setting_int('match_plays_per_day', 3),
    'match_max_exp', _setting_int('match_max_exp', 10),
    'match_best', (select max(score) from game_plays where student_id = sid and game = 'match' and play_date = d)
  );
end $$;

create or replace function quiz_today(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); d date := today_th(); ids uuid[]; qs json;
begin
  if exists (select 1 from game_plays where student_id = sid and game = 'quiz' and play_date = d) then
    return json_build_object('done', true);
  end if;
  ids := _quiz_ids(sid, d);
  select json_agg(json_build_object('id', q.id, 'topic', q.topic, 'question', q.question,
           'choices', json_build_array(q.a, q.b, q.c, q.d)) order by u.pos)
    into qs
    from unnest(ids) with ordinality as u(id, pos) join quiz_questions q on q.id = u.id;
  return json_build_object('done', false, 'questions', coalesce(qs, '[]'::json));
end $$;

-- ตรวจคำตอบฝั่งเซิร์ฟเวอร์: p_answers = [0..3, ...] เรียงตามข้อที่แสดง (-1 = ไม่ตอบ)
create or replace function quiz_submit(p_token uuid, p_answers jsonb) returns json
language plpgsql security definer set search_path = public as $$
declare
  sid uuid := _sid(p_token); d date := today_th(); ids uuid[]; q quiz_questions%rowtype;
  total int; i int; pick int; corr int := 0; res jsonb := '[]'::jsonb;
  raw int; e int; c int := 0; stk int; cap int := _setting_int('game_daily_cap_exp', 40);
begin
  if p_answers is null or jsonb_typeof(p_answers) <> 'array' then raise exception 'ข้อมูลคำตอบไม่ถูกต้อง'; end if;
  ids := _quiz_ids(sid, d);
  total := coalesce(array_length(ids, 1), 0);
  if total = 0 then raise exception 'ยังไม่มีคำถามในระบบ'; end if;
  if exists (select 1 from game_plays where student_id = sid and game = 'quiz' and play_date = d) then
    raise exception 'วันนี้ทำควิซไปแล้ว พรุ่งนี้มาใหม่นะ';
  end if;
  for i in 1..total loop
    select * into q from quiz_questions where id = ids[i];
    begin pick := coalesce((p_answers ->> (i - 1))::int, -1); exception when others then pick := -1; end;
    if pick = q.answer then corr := corr + 1; end if;
    res := res || jsonb_build_object('id', q.id, 'pick', pick, 'answer', q.answer,
             'ok', pick = q.answer, 'explain', q.explain);
  end loop;
  raw := corr * _setting_int('quiz_exp_per_correct', 4)
         + case when corr = total then _setting_int('quiz_perfect_bonus', 5) else 0 end;
  e := least(raw, greatest(0, cap - _game_exp_today(sid)));
  begin
    insert into game_plays (student_id, game, play_date, score, correct, exp, coins)
    values (sid, 'quiz', d, round(100.0 * corr / total), corr, e, 0);
  exception when unique_violation then
    raise exception 'วันนี้ทำควิซไปแล้ว พรุ่งนี้มาใหม่นะ';
  end;
  stk := _quiz_streak(sid);
  if corr > 0 then c := corr + least(stk - 1, 5); end if;   -- เหรียญ 1/ข้อ + โบนัสทำติดกันหลายวัน (สูงสุด +5)
  update game_plays set coins = c where student_id = sid and game = 'quiz' and play_date = d;
  perform award(sid, e, c, 'ควิซประจำวัน ' || corr || '/' || total, 'game:quiz:' || d);
  return json_build_object('correct', corr, 'total', total, 'exp', e, 'coins', c, 'raw_exp', raw,
                           'capped', e < raw, 'streak', stk, 'results', res);
end $$;

-- เกมจับคู่ธาตุ: เล่นฝั่งเบราว์เซอร์ ส่งผลคะแนน 0-100 มาให้เซิร์ฟเวอร์ (มีเพดานจำนวนรอบ + EXP ต่อวันกันโกง)
create or replace function match_submit(p_token uuid, p_score int, p_pairs int, p_seconds int) returns json
language plpgsql security definer set search_path = public as $$
declare
  sid uuid := _sid(p_token); d date := today_th(); n int; mx int; raw int; e int; c int := 0;
  cap int := _setting_int('game_daily_cap_exp', 40);
begin
  if p_score is null or p_score < 0 or p_score > 100 or p_pairs not between 4 and 12 or p_seconds is null or p_seconds < p_pairs then
    raise exception 'ผลการเล่นไม่ถูกต้อง';
  end if;
  select count(*) into n from game_plays where student_id = sid and game = 'match' and play_date = d;
  mx := _setting_int('match_plays_per_day', 3);
  raw := round(_setting_int('match_max_exp', 10) * p_score / 100.0);
  if n >= mx then
    -- เล่นต่อได้ แต่ไม่ได้รางวัลแล้ว
    insert into game_plays (student_id, game, play_date, score, exp, coins) values (sid, 'match', d, p_score, 0, 0);
    return json_build_object('exp', 0, 'coins', 0, 'score', p_score, 'capped', true, 'no_reward', true, 'plays', n + 1, 'max_plays', mx);
  end if;
  e := least(raw, greatest(0, cap - _game_exp_today(sid)));
  if p_score >= 90 then c := 1; end if;
  insert into game_plays (student_id, game, play_date, score, exp, coins) values (sid, 'match', d, p_score, e, c);
  perform award(sid, e, c, 'จับคู่ธาตุ (' || p_score || ' คะแนน)', 'game:match:' || d || ':' || (n + 1));
  return json_build_object('exp', e, 'coins', c, 'score', p_score, 'capped', e < raw, 'no_reward', false, 'plays', n + 1, 'max_plays', mx);
end $$;

-- ---------------------------------------------------------------------
-- สิทธิ์การเรียกใช้
-- ---------------------------------------------------------------------
revoke execute on function _setting_int(text, int) from public, anon, authenticated;
revoke execute on function _game_exp_today(uuid) from public, anon, authenticated;
revoke execute on function _quiz_ids(uuid, date) from public, anon, authenticated;
revoke execute on function _quiz_streak(uuid) from public, anon, authenticated;
revoke execute on function game_status(uuid) from public;
revoke execute on function quiz_today(uuid) from public;
revoke execute on function quiz_submit(uuid, jsonb) from public;
revoke execute on function match_submit(uuid, int, int, int) from public;
grant execute on function game_status(uuid) to anon, authenticated;
grant execute on function quiz_today(uuid) to anon, authenticated;
grant execute on function quiz_submit(uuid, jsonb) to anon, authenticated;
grant execute on function match_submit(uuid, int, int, int) to anon, authenticated;

-- ---------------------------------------------------------------------
-- คำถามตัวอย่าง 46 ข้อ (เพิ่ม/แก้/ปิดได้ที่หน้าแอดมิน → 🎮 มินิเกม) — ใส่เฉพาะตอนตารางยังว่าง
-- answer: 0=ก 1=ข 2=ค 3=ง
-- ---------------------------------------------------------------------
do $$
begin
  if exists (select 1 from quiz_questions) then return; end if;
  insert into quiz_questions (topic, question, a, b, c, d, answer, explain) values
  ('ตารางธาตุ','ธาตุที่มีสัญลักษณ์ Na คือธาตุใด','โพแทสเซียม','โซเดียม','ไนโตรเจน','นีออน',1,'Na มาจากชื่อละติน natrium คือโซเดียม ส่วนโพแทสเซียมคือ K'),
  ('ตารางธาตุ','ธาตุหมู่ 1 (ยกเว้นไฮโดรเจน) เรียกว่าอะไร','โลหะอัลคาไล','ฮาโลเจน','แก๊สเฉื่อย','โลหะแทรนซิชัน',0,'หมู่ 1 คือโลหะอัลคาไล เช่น Li Na K ทำปฏิกิริยากับน้ำรุนแรง'),
  ('ตารางธาตุ','ธาตุหมู่ 17 เรียกว่าอะไร','แอลคาไลน์เอิร์ท','ฮาโลเจน','แก๊สเฉื่อย','แคลโคเจน',1,'หมู่ 17 คือฮาโลเจน เช่น F Cl Br I มีเวเลนซ์อิเล็กตรอน 7'),
  ('ตารางธาตุ','ข้อใดเป็นแก๊สเฉื่อย','ออกซิเจน','ฮีเลียม','ไนโตรเจน','คลอรีน',1,'แก๊สเฉื่อยอยู่หมู่ 18 มีเวเลนซ์อิเล็กตรอนครบ จึงไม่ค่อยทำปฏิกิริยา'),
  ('ตารางธาตุ','ธาตุใดมีเลขอะตอมน้อยที่สุด','ฮีเลียม','ไฮโดรเจน','ลิเทียม','คาร์บอน',1,'ไฮโดรเจนมีเลขอะตอม 1'),
  ('ตารางธาตุ','ในคาบเดียวกัน จากซ้ายไปขวา ขนาดอะตอมโดยทั่วไปเป็นอย่างไร','เพิ่มขึ้น','ลดลง','เท่าเดิม','เพิ่มแล้วลดสลับกัน',1,'ประจุนิวเคลียสเพิ่ม ดึงอิเล็กตรอนเข้าหาแน่นขึ้น อะตอมจึงเล็กลง'),
  ('ตารางธาตุ','สัญลักษณ์ของธาตุเหล็กคือข้อใด','Ir','F','Fe','Au',2,'Fe มาจากภาษาละติน ferrum'),
  ('ตารางธาตุ','ธาตุใดเป็นโลหะที่เป็นของเหลวที่อุณหภูมิห้อง','ปรอท','เหล็ก','ทองแดง','ซิลิคอน',0,'ปรอท (Hg) เป็นโลหะเพียงชนิดเดียวที่เป็นของเหลวที่อุณหภูมิห้อง'),
  ('ตารางธาตุ','ธาตุใดมีค่าอิเล็กโทรเนกาติวิตีสูงที่สุด','ออกซิเจน','ฟลูออรีน','คลอรีน','ไนโตรเจน',1,'ฟลูออรีนดึงอิเล็กตรอนได้แรงที่สุดในตารางธาตุ'),
  ('โครงสร้างอะตอม','อนุภาคใดในอะตอมมีประจุบวก','อิเล็กตรอน','นิวตรอน','โปรตอน','ไม่มีข้อถูก',2,'โปรตอน (+) นิวตรอน (0) อิเล็กตรอน (−)'),
  ('โครงสร้างอะตอม','เลขอะตอมบอกจำนวนอะไร','นิวตรอน','โปรตอน','นิวคลีออนทั้งหมด','มวลอะตอม',1,'เลขอะตอม = จำนวนโปรตอน (ในอะตอมกลางเท่ากับจำนวนอิเล็กตรอน)'),
  ('โครงสร้างอะตอม','อะตอมหนึ่งมีโปรตอน 6 และนิวตรอน 6 เลขมวลเท่าใด','6','12','18','0',1,'เลขมวล = โปรตอน + นิวตรอน = 6 + 6 = 12'),
  ('โครงสร้างอะตอม','ไอโซโทปของธาตุเดียวกันต่างกันที่อะไร','จำนวนโปรตอน','จำนวนเวเลนซ์อิเล็กตรอน','จำนวนนิวตรอน','ชื่อธาตุ',2,'ไอโซโทปมีโปรตอนเท่ากันแต่นิวตรอนต่างกัน จึงมีเลขมวลต่างกัน'),
  ('โครงสร้างอะตอม','การจัดเรียงอิเล็กตรอนของ Na (เลขอะตอม 11) คือข้อใด','2, 8, 1','2, 8, 2','2, 9','2, 7, 2',0,'ชั้นแรกจุ 2 ชั้นที่สองจุ 8 เหลือ 1 ที่ชั้นนอกสุด'),
  ('โครงสร้างอะตอม','คลอรีน (เลขอะตอม 17) มีเวเลนซ์อิเล็กตรอนกี่ตัว','5','6','7','8',2,'การจัดเรียง 2, 8, 7 จึงมีเวเลนซ์อิเล็กตรอน 7 ตัว'),
  ('พันธะเคมี','NaCl เกิดจากพันธะชนิดใด','โคเวเลนต์','ไอออนิก','โลหะ','ไฮโดรเจน',1,'Na ให้อิเล็กตรอนแก่ Cl เกิดไอออน Na⁺ และ Cl⁻ ดึงดูดกัน'),
  ('พันธะเคมี','พันธะโคเวเลนต์เกิดจากอะไร','การให้และรับอิเล็กตรอน','การใช้อิเล็กตรอนร่วมกัน','แรงดึงดูดของแม่เหล็ก','การแลกเปลี่ยนนิวเคลียส',1,'อะตอมอโลหะใช้อิเล็กตรอนร่วมกันเพื่อให้เวเลนซ์ครบ 8'),
  ('พันธะเคมี','โมเลกุล H₂O มีพันธะระหว่างอะตอมเป็นแบบใด','ไอออนิก','โลหะ','โคเวเลนต์','ไม่มีพันธะ',2,'H และ O เป็นอโลหะ จึงใช้อิเล็กตรอนร่วมกัน'),
  ('พันธะเคมี','สารประกอบไอออนิกโดยทั่วไปมีสมบัติใด','จุดหลอมเหลวต่ำ','จุดหลอมเหลวสูง','เป็นแก๊สที่อุณหภูมิห้อง','นำไฟฟ้าได้ดีเมื่อเป็นของแข็ง',1,'แรงยึดเหนี่ยวระหว่างไอออนแข็งแรงมาก จึงต้องใช้พลังงานสูงในการหลอมเหลว'),
  ('พันธะเคมี','ในโมเลกุล CO₂ มีพันธะคู่ (C=O) กี่พันธะ','1','2','3','4',1,'โครงสร้าง O=C=O มีพันธะคู่ 2 พันธะ'),
  ('ปริมาณสารสัมพันธ์','สาร 1 โมลมีจำนวนอนุภาคเท่าใด','6.02 × 10²³ อนุภาค','6.02 × 10³² อนุภาค','3.01 × 10²³ อนุภาค','1.66 × 10⁻²⁴ อนุภาค',0,'เลขอโวคาโดร = 6.02 × 10²³ ต่อโมล'),
  ('ปริมาณสารสัมพันธ์','มวลโมเลกุลของน้ำ (H = 1, O = 16) เท่าใด','16','17','18','20',2,'(2 × 1) + 16 = 18'),
  ('ปริมาณสารสัมพันธ์','มวลโมเลกุลของ CO₂ (C = 12, O = 16) เท่าใด','28','44','32','56',1,'12 + (2 × 16) = 44'),
  ('ปริมาณสารสัมพันธ์','สารละลายที่มีตัวถูกละลาย 0.5 โมลในสารละลาย 1 ลิตร มีความเข้มข้นกี่โมลาร์','0.5 โมลาร์','2 โมลาร์','5 โมลาร์','1 โมลาร์',0,'โมลาร์ = โมลตัวถูกละลาย ÷ ปริมาตรสารละลาย (ลิตร)'),
  ('ปริมาณสารสัมพันธ์','แก๊สอุดมคติ 1 โมลที่ STP มีปริมาตรกี่ลิตร','11.2','22.4','24.0','44.8',1,'ที่ STP (0 °C, 1 atm) แก๊ส 1 โมล = 22.4 ลิตร'),
  ('กรด-เบส','สารละลายที่มี pH = 3 มีสมบัติอย่างไร','เบส','กลาง','กรด','บอกไม่ได้',2,'pH < 7 เป็นกรด'),
  ('กรด-เบส','น้ำบริสุทธิ์ที่ 25 °C มี pH เท่าใด','0','7','14','1',1,'น้ำบริสุทธิ์เป็นกลาง pH = 7'),
  ('กรด-เบส','ปฏิกิริยาระหว่างกรดกับเบสเรียกว่าอะไร','การเผาไหม้','การสลายตัว','การสะเทิน','การรีดักชัน',2,'กรด + เบส → เกลือ + น้ำ เรียกว่าปฏิกิริยาสะเทิน'),
  ('กรด-เบส','กระดาษลิตมัสสีน้ำเงินเมื่อสัมผัสกรดจะเปลี่ยนเป็นสีใด','แดง','เขียว','เหลือง','ไม่เปลี่ยนสี',0,'กรดทำให้ลิตมัสน้ำเงินเป็นสีแดง เบสทำให้ลิตมัสแดงเป็นสีน้ำเงิน'),
  ('กรด-เบส','HCl จัดเป็นสารประเภทใด','กรดแก่','เบสแก่','เกลือ','สารกลาง',0,'HCl แตกตัวเป็นไอออนได้เกือบสมบูรณ์ในน้ำ จึงเป็นกรดแก่'),
  ('สมบัติของสาร','การเปลี่ยนสถานะจากของแข็งเป็นแก๊สโดยตรงเรียกว่าอะไร','การระเหย','การระเหิด','การควบแน่น','การหลอมเหลว',1,'เช่น น้ำแข็งแห้ง การบูร ลูกเหม็น'),
  ('สมบัติของสาร','น้ำแข็งแห้งคือของแข็งของสารใด','O₂','N₂','CO₂','H₂O',2,'น้ำแข็งแห้งคือคาร์บอนไดออกไซด์ในสถานะของแข็ง'),
  ('สมบัติของสาร','ส่วนผสมที่เป็นเนื้อเดียวกันตลอด เรียกว่าอะไร','สารแขวนลอย','สารละลาย','ธาตุ','สารประกอบ',1,'สารละลายเป็นสารเนื้อเดียว เช่น น้ำเกลือ'),
  ('สมบัติของสาร','ข้อใดเป็นการเปลี่ยนแปลงทางเคมี','น้ำแข็งละลาย','เหล็กเป็นสนิม','น้ำระเหย','ตัดกระดาษ',1,'เหล็กเป็นสนิมเกิดสารใหม่คือเหล็กออกไซด์'),
  ('เคมีอินทรีย์','สารประกอบที่ประกอบด้วย C และ H เท่านั้น เรียกว่าอะไร','คาร์โบไฮเดรต','ไฮโดรคาร์บอน','แอลกอฮอล์','กรดอินทรีย์',1,'ไฮโดรคาร์บอน (Hydro = H, Carbon = C)'),
  ('เคมีอินทรีย์','แอลเคนที่มีคาร์บอน 1 อะตอมคือสารใด','อีเทน','มีเทน','โพรเพน','บิวเทน',1,'มีเทน CH₄ เป็นแอลเคนที่เล็กที่สุด'),
  ('เคมีอินทรีย์','สูตรทั่วไปของแอลเคนคือข้อใด','CₙH₂ₙ','CₙH₂ₙ₊₂','CₙH₂ₙ₋₂','CₙHₙ',1,'เช่น n = 3 → C₃H₈ (โพรเพน)'),
  ('เคมีอินทรีย์','หมู่ฟังก์ชันของแอลกอฮอล์คือข้อใด','–COOH','–OH','–CHO','–NH₂',1,'แอลกอฮอล์มีหมู่ไฮดรอกซิล –OH'),
  ('เคมีอินทรีย์','หมู่ฟังก์ชันของกรดคาร์บอกซิลิกคือข้อใด','–OH','–CHO','–COOH','–CO–',2,'เช่น กรดแอซีติก CH₃COOH ในน้ำส้มสายชู'),
  ('เคมีอินทรีย์','แอลคีนมีลักษณะเฉพาะคือข้อใด','พันธะเดี่ยวทั้งหมด','มีพันธะคู่ C=C','มีพันธะสาม C≡C','มีพันธะไอออนิก',1,'แอลคีนมีพันธะคู่ระหว่างคาร์บอนอย่างน้อย 1 พันธะ สูตร CₙH₂ₙ'),
  ('เคมีอินทรีย์','โพรเพนมีสูตรโมเลกุลใด','C₂H₆','C₃H₈','C₄H₁₀','C₃H₆',1,'แอลเคน C₃ → C₃H₂(₃)₊₂ = C₃H₈'),
  ('เคมีอินทรีย์','เอทานอลมีสูตรโครงสร้างข้อใด','CH₃CH₂OH','CH₃COOH','CH₃CHO','CH₃OCH₃',0,'เอทานอลคือแอลกอฮอล์ที่มี C 2 อะตอม'),
  ('ความปลอดภัย','ก่อนใช้สารเคมีควรอ่านอะไรเป็นอันดับแรก','สลากและข้อมูลความปลอดภัย (SDS)','ราคาสินค้า','สีของขวด','ไม่ต้องอ่าน',0,'อ่านสลากและ SDS เพื่อรู้ความเป็นอันตรายและวิธีใช้อย่างปลอดภัย'),
  ('ความปลอดภัย','ถ้ากรดกระเด็นถูกผิวหนัง ควรทำอย่างไรก่อน','ทาแป้ง','ล้างด้วยน้ำสะอาดปริมาณมากทันที','เช็ดด้วยผ้าแห้ง','รอครู',1,'ล้างด้วยน้ำปริมาณมากทันทีอย่างน้อย 15 นาที แล้วแจ้งครู'),
  ('ความปลอดภัย','ข้อใดห้ามทำในห้องปฏิบัติการ','สวมแว่นตานิรภัย','ชิมสารเคมี','รวบผมยาว','ล้างมือหลังเสร็จ',1,'ห้ามชิมหรือสัมผัสสารเคมีโดยตรง'),
  ('ความปลอดภัย','การเจือจางกรดเข้มข้นควรทำอย่างไร','เทน้ำลงในกรดอย่างรวดเร็ว','เทกรดลงในน้ำอย่างช้าๆ พร้อมคน','ผสมสองอย่างพร้อมกัน','ไม่ต้องคน',1,'เติมกรดลงน้ำเพื่อให้ความร้อนที่เกิดขึ้นกระจายตัวและไม่กระเด็น');
end $$;
-- =====================================================================
-- Chemistria · รอบที่ 4: ตกแต่งตัวละคร (กรอบ/พื้นหลัง/หมวก/สัตว์เลี้ยง/ฉายา) + หอเกียรติยศประจำห้อง
-- รันซ้ำได้ · ต้องรัน 01_schema.sql, 02_seed.sql มาก่อน (setup_all.sql รวมทุกไฟล์ให้แล้ว)
-- =====================================================================

create table if not exists decor_items (
  id uuid primary key default gen_random_uuid(),
  slot text not null check (slot in ('frame','bg','hat','pet','title')),
  key text not null default 'solid',      -- ชื่อสไตล์ในหน้าเว็บ (เช่น solid, flame, galaxy) — ถ้าเพิ่มสไตล์ใหม่ต้องแก้ CSS
  color text,                              -- สีหลัก (ใช้กับสไตล์ solid)
  name text not null,
  emoji text not null default '✨',        -- กรอบ/พื้นหลัง/ฉายา = ไอคอนในรายการ · หมวก/สัตว์เลี้ยง = ตัวที่แสดงบนตัวละคร
  rarity text not null default 'R' check (rarity in ('N','R','SR','SSR')),
  price int check (price is null or price >= 0),   -- ใส่ราคา = วางขายในร้านค้า · ว่าง = ได้จากกาชาเท่านั้น
  sort int not null default 0,
  active boolean not null default true
);

create table if not exists student_decor (
  student_id uuid not null references students(id) on delete cascade,
  item_id uuid not null references decor_items(id) on delete cascade,
  source text not null default 'shop' check (source in ('shop','gacha','teacher')),
  acquired_at timestamptz default now(),
  primary key (student_id, item_id)
);

alter table students add column if not exists decor jsonb not null default '{}'::jsonb;   -- {slot: decor_item_id}
alter table gacha_items add column if not exists decor_id uuid references decor_items(id) on delete cascade;
alter table gacha_items drop constraint if exists gacha_items_kind_check;
alter table gacha_items add constraint gacha_items_kind_check check (kind in ('coins','exp','cosmetic','privilege','decor'));

do $$
declare t text;
begin
  foreach t in array array['decor_items','student_decor'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists teacher_all on public.%I', t);
    execute format('create policy teacher_all on public.%I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- ฟังก์ชัน
-- ---------------------------------------------------------------------
-- ไอเทมที่สวมอยู่ของนักเรียน → {frame:{...}, bg:{...}, hat:{...}, pet:{...}, title:{...}}
create or replace function _decor_of(p_sid uuid) returns json
language sql stable security definer set search_path = public as $$
  select coalesce(json_object_agg(d.slot, json_build_object('id', d.id, 'key', d.key, 'color', d.color,
           'emoji', d.emoji, 'name', d.name, 'rarity', d.rarity)), '{}'::json)
    from students s
    cross join lateral jsonb_each_text(s.decor) e
    join decor_items d on d.id = e.value::uuid and d.slot = e.key
   where s.id = p_sid
$$;

create or replace function buy_decor(p_token uuid, p_item uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); d decor_items%rowtype; s students%rowtype;
begin
  select * into d from decor_items where id = p_item and active;
  if not found or d.price is null then raise exception 'ไอเทมนี้ไม่ได้วางขาย'; end if;
  select * into s from students where id = sid for update;
  if exists (select 1 from student_decor where student_id = sid and item_id = d.id) then
    raise exception 'มีไอเทมนี้แล้ว';
  end if;
  if s.coins < d.price then raise exception 'เหรียญไม่พอ (ต้องใช้ % เหรียญ)', d.price; end if;
  insert into student_decor (student_id, item_id, source) values (sid, d.id, 'shop');
  perform award(sid, 0, -d.price, 'ซื้อไอเทมตกแต่ง: ' || d.name, null);
  return json_build_object('name', d.name, 'coins', s.coins - d.price);
end $$;

-- สวมใส่ (p_item = null → ถอดออกจากช่องนั้น)
create or replace function equip_decor(p_token uuid, p_slot text, p_item uuid) returns void
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  if p_slot not in ('frame','bg','hat','pet','title') then raise exception 'ช่องไม่ถูกต้อง'; end if;
  if p_item is null then
    update students set decor = decor - p_slot where id = sid;
    return;
  end if;
  if not exists (select 1 from student_decor sd join decor_items d on d.id = sd.item_id
                  where sd.student_id = sid and sd.item_id = p_item and d.slot = p_slot) then
    raise exception 'ยังไม่มีไอเทมนี้';
  end if;
  update students set decor = decor || jsonb_build_object(p_slot, p_item::text) where id = sid;
end $$;

-- หอเกียรติยศ: Top 3 ของทุกห้อง (เฉพาะคนที่มี EXP > 0) · ห้องของตัวเองขึ้นก่อน
create or replace function hall_of_fame(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); mycls uuid; r json;
begin
  select class_id into mycls from students where id = sid;
  select coalesce(json_agg(h order by h.mine desc, h.name), '[]'::json) into r from (
    select c.id, c.code, c.name, (c.id = mycls) as mine,
      (select json_agg(json_build_object('name', x.name, 'no', x.no, 'avatar', x.avatar, 'char_class', x.char_class, 'exp', x.exp,
          'level', level_for(x.exp), 'rank_info', rank_info(x.exp), 'decor', _decor_of(x.id), 'me', x.id = sid) order by x.exp desc, x.no)
         from (select * from students where class_id = c.id and exp > 0 order by exp desc, no limit 3) x) as top
      from classes c
  ) h where h.top is not null;
  return r;
end $$;

revoke execute on function _decor_of(uuid) from public, anon, authenticated;
revoke execute on function buy_decor(uuid, uuid) from public;
revoke execute on function equip_decor(uuid, text, uuid) from public;
revoke execute on function hall_of_fame(uuid) from public;
grant execute on function buy_decor(uuid, uuid) to anon, authenticated;
grant execute on function equip_decor(uuid, text, uuid) to anon, authenticated;
grant execute on function hall_of_fame(uuid) to anon, authenticated;

-- ---------------------------------------------------------------------
-- ไอเทมตัวอย่าง (ใส่เฉพาะตอนตารางยังว่าง) · gw = น้ำหนักในตู้กาชา (0 = ไม่อยู่ในกาชา)
-- ---------------------------------------------------------------------
do $$
begin
  if exists (select 1 from decor_items) then return; end if;
  insert into decor_items (slot, key, color, name, emoji, rarity, price, sort)
  select slot, key, color, name, emoji, rarity, price, sort from (values
    -- กรอบ
    ('frame','solid','#4fe3b0','กรอบมิ้นต์','🖼️','N',50,1),
    ('frame','solid','#ff8fb7','กรอบซากุระ','🌸','N',50,2),
    ('frame','ice',null,'กรอบน้ำแข็ง','🧊','R',120,3),
    ('frame','flame',null,'กรอบเปลวไฟ','🔥','R',120,4),
    ('frame','neon',null,'กรอบนีออน','💜','SR',null,5),
    ('frame','gold',null,'กรอบทองคำ','🏅','SR',null,6),
    ('frame','rainbow',null,'กรอบสายรุ้ง','🌈','SSR',null,7),
    -- พื้นหลัง
    ('bg','solid','#3a1f78','พื้นม่วงห้องแล็บ','🟣','N',40,1),
    ('bg','sunset',null,'พื้นพระอาทิตย์ตก','🌇','R',100,2),
    ('bg','forest',null,'พื้นป่าเขียว','🌲','R',100,3),
    ('bg','lab',null,'พื้นกริดห้องแล็บ','🧪','R',null,4),
    ('bg','galaxy',null,'พื้นกาแล็กซี','🌌','SR',null,5),
    ('bg','aurora',null,'พื้นแสงเหนือ','🌠','SSR',null,6),
    -- หมวก/เครื่องประดับบนหัว
    ('hat','emoji',null,'โบว์ชมพู','🎀','N',60,1),
    ('hat','emoji',null,'หมวกแก๊ป','🧢','N',60,2),
    ('hat','emoji',null,'หมวกบัณฑิต','🎓','R',150,3),
    ('hat','emoji',null,'หมวกทรงสูง','🎩','R',150,4),
    ('hat','emoji',null,'มงกุฎทอง','👑','SSR',null,5),
    -- สัตว์เลี้ยง
    ('pet','emoji',null,'น้องกบ','🐸','N',80,1),
    ('pet','emoji',null,'น้องแมว','🐱','R',200,2),
    ('pet','emoji',null,'น้องหมา','🐶','R',200,3),
    ('pet','emoji',null,'น้องจิ้งจอก','🦊','SR',null,4),
    ('pet','emoji',null,'มังกรน้อย','🐉','SSR',null,5),
    -- ฉายา
    ('title','text',null,'หนอนตำรา','📚','N',50,1),
    ('title','text',null,'ผู้พิชิตโมล','⚖️','R',150,2),
    ('title','text',null,'ราชาออร์แกนิก','🧬','R',150,3),
    ('title','text',null,'จอมเวทธาตุ','🔮','SR',null,4),
    ('title','text',null,'ตำนานห้องแล็บ','🏆','SSR',null,5)
  ) v(slot, key, color, name, emoji, rarity, price, sort);

  -- ไอเทมที่ออกจากกาชา: ทุกชิ้นที่ N/R ราคาขายต่ำ + ชิ้น SR/SSR ทั้งหมด
  insert into gacha_items (name, rarity, kind, value, emoji, weight, decor_id)
  select d.name, d.rarity, 'decor', 0, d.emoji,
         case d.rarity when 'N' then 3 when 'R' then 2 else 1 end, d.id
    from decor_items d
   where d.rarity in ('SR','SSR') or d.price is null or d.name in ('กรอบน้ำแข็ง','กรอบเปลวไฟ','หมวกบัณฑิต','น้องแมว','ผู้พิชิตโมล');
end $$;
-- =====================================================================
-- Chemistria · รอบที่ 5: ตัวละครเต็มตัว + ชุด/เอฟเฟค/ไอเทมลอย + หอเกียรติยศเฉพาะห้องตัวเอง
-- รันซ้ำได้ · ต้องรันหลัง 05_decor.sql (setup_all.sql รวมให้แล้ว)
-- ฟังก์ชัน _decor_of / equip_decor / hall_of_fame ในไฟล์นี้ใช้แทนเวอร์ชันใน 05
-- =====================================================================

alter table decor_items add column if not exists image text;      -- ใช้กับช่อง "ไอเทม" (ภาพลอยข้างตัวละคร)
alter table decor_items drop constraint if exists decor_items_slot_check;
alter table decor_items add constraint decor_items_slot_check
  check (slot in ('frame','bg','hat','pet','title','outfit','fx','item'));

create or replace function _decor_of(p_sid uuid) returns json
language sql stable security definer set search_path = public as $$
  select coalesce(json_object_agg(d.slot, json_build_object('id', d.id, 'key', d.key, 'color', d.color,
           'emoji', d.emoji, 'name', d.name, 'rarity', d.rarity, 'image', d.image)), '{}'::json)
    from students s
    cross join lateral jsonb_each_text(s.decor) e
    join decor_items d on d.id = e.value::uuid and d.slot = e.key
   where s.id = p_sid
$$;

create or replace function equip_decor(p_token uuid, p_slot text, p_item uuid) returns void
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  if p_slot not in ('frame','bg','hat','pet','title','outfit','fx','item') then raise exception 'ช่องไม่ถูกต้อง'; end if;
  if p_item is null then
    update students set decor = decor - p_slot where id = sid;
    return;
  end if;
  if not exists (select 1 from student_decor sd join decor_items d on d.id = sd.item_id
                  where sd.student_id = sid and sd.item_id = p_item and d.slot = p_slot) then
    raise exception 'ยังไม่มีไอเทมนี้';
  end if;
  update students set decor = decor || jsonb_build_object(p_slot, p_item::text) where id = sid;
end $$;

-- หอเกียรติยศ: Top 3 ของ "ห้องตัวเองเท่านั้น" (เฉพาะคนที่มี EXP > 0)
create or replace function hall_of_fame(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); mycls uuid; r json;
begin
  select class_id into mycls from students where id = sid;
  select coalesce(json_agg(h), '[]'::json) into r from (
    select c.id, c.code, c.name, true as mine,
      (select json_agg(json_build_object('name', x.name, 'no', x.no, 'avatar', x.avatar, 'char_class', x.char_class, 'exp', x.exp,
          'level', level_for(x.exp), 'rank_info', rank_info(x.exp), 'decor', _decor_of(x.id), 'me', x.id = sid) order by x.exp desc, x.no)
         from (select * from students where class_id = c.id and exp > 0 order by exp desc, no limit 3) x) as top
      from classes c where c.id = mycls
  ) h where h.top is not null;
  return r;
end $$;

-- ---------------------------------------------------------------------
-- ไอเทมตัวอย่างใหม่: ชุด / เอฟเฟค / ไอเทมลอย (ใส่เฉพาะตอนยังไม่มีสามช่องนี้)
-- ภาพชุด: web/assets/chars/<คลาส>_<สไตล์>.png (ไม่มีภาพจะใช้ชุดเริ่มต้นแทน)
-- ---------------------------------------------------------------------
do $$
begin
  if exists (select 1 from decor_items where slot in ('outfit','fx','item')) then return; end if;
  insert into decor_items (slot, key, color, name, emoji, rarity, price, sort, image)
  select slot, key, color, name, emoji, rarity, price, sort, image from (values
    ('outfit','space',null,'ชุดนักบินอวกาศ','🚀','R',250,1,null),
    ('outfit','wizard',null,'ชุดจอมเวทย์','🪄','SR',null,2,null),
    ('fx','sparkle',null,'ประกายดาว','✨','N',100,1,null),
    ('fx','bubbles',null,'ฟองสารเคมี','🫧','R',150,2,null),
    ('fx','flame',null,'ออร่าเปลวไฟ','🔥','R',200,3,null),
    ('fx','ice',null,'หิมะน้ำแข็ง','❄️','R',200,4,null),
    ('fx','lightning',null,'สายฟ้าฟาด','⚡','SR',null,5,null),
    ('fx','orbit',null,'ดาวโคจร','🪐','SSR',null,6,null),
    ('item','img',null,'ขวดยาสีแดง','🧪','N',60,1,'assets/items/potion_red.png'),
    ('item','img',null,'ขวดยาสีเขียว','🧪','R',100,2,'assets/items/potion_green.png'),
    ('item','img',null,'ตะเกียงแอลกอฮอล์','🔥','R',120,3,'assets/items/burner.png'),
    ('item','img',null,'กล้องจุลทรรศน์','🔬','R',150,4,'assets/items/microscope.png'),
    ('item','img',null,'คริสตัลเรืองแสง','💎','SR',null,5,'assets/items/crystal.png'),
    ('item','img',null,'คทาเวทมนตร์','🪄','SSR',null,6,'assets/items/wand.png')
  ) v(slot, key, color, name, emoji, rarity, price, sort, image);

  insert into gacha_items (name, rarity, kind, value, emoji, weight, decor_id)
  select d.name, d.rarity, 'decor', 0, d.emoji,
         case d.rarity when 'N' then 3 when 'R' then 2 else 1 end, d.id
    from decor_items d
   where d.slot in ('outfit','fx','item')
     and (d.rarity in ('SR','SSR') or d.price is null or d.name in ('ชุดนักบินอวกาศ','ออร่าเปลวไฟ'));
end $$;
-- Chemistria · รอบที่ 6: ภาพหมวก/เครื่องประดับ/สัตว์เลี้ยงแบบภาพวาด · รันซ้ำได้ (ต้องรันหลัง 06)
update decor_items set image = 'assets/hats/' || v.f || '.png' from (values
  ('โบว์ชมพู','bow'),('หมวกแก๊ป','cap'),('หมวกบัณฑิต','grad'),('หมวกทรงสูง','tophat'),('มงกุฎทอง','crown')) v(n,f)
 where decor_items.slot = 'hat' and decor_items.name = v.n;
update decor_items set image = 'assets/pets/' || v.f || '.png' from (values
  ('น้องกบ','frog'),('น้องแมว','cat'),('น้องหมา','dog'),('น้องจิ้งจอก','fox'),('มังกรน้อย','dragon')) v(n,f)
 where decor_items.slot = 'pet' and decor_items.name = v.n;

insert into decor_items (slot, key, name, emoji, rarity, price, sort, image)
select 'hat','emoji','แว่นนิรภัยแล็บ','🥽','R',150,6,'assets/hats/goggles.png'
 where not exists (select 1 from decor_items where slot='hat' and name='แว่นนิรภัยแล็บ');
insert into decor_items (slot, key, name, emoji, rarity, price, sort, image)
select 'pet','emoji','น้องฮูกนักวิชาการ','🦉','R',200,6,'assets/pets/owl.png'
 where not exists (select 1 from decor_items where slot='pet' and name='น้องฮูกนักวิชาการ');
-- =====================================================================
-- Chemistria · รอบที่ 7: ฟังก์ชันแนะนำ 8 ข้อ
--  1 รางวัลทันทีหลังเช็คชื่อ/ส่งงาน (ตั๋วสุ่มกาชาฟรี + เควสอัตโนมัติ)   2 ตัวเตือนงานค้าง (ฝั่งหน้าเว็บ)
--  3 ทีม/ห้องแข่ง EXP   4 สรุปรายสัปดาห์ของครู   5 ควิซตามบทเรียน
--  6 ส่งออก Excel (ฝั่งหน้าเว็บ)   7 ส่งงานเป็นรูปภาพ/ออนไลน์   8 บอสประจำสัปดาห์
-- รันซ้ำได้ · ต้องรันหลัง 01–07 (setup_all.sql รวมให้แล้ว) · ฟังก์ชัน gacha_pull/trg_attendance/trg_submission/_quiz_ids ในไฟล์นี้ใช้แทนเวอร์ชันเดิม
-- =====================================================================

-- ---------------------------------------------------------------------
-- ตาราง/คอลัมน์ใหม่
-- ---------------------------------------------------------------------
alter table students add column if not exists free_pulls int not null default 0;
alter table quests add column if not exists auto_trigger text;
alter table quests drop constraint if exists quests_auto_trigger_check;
alter table quests add constraint quests_auto_trigger_check check (auto_trigger is null or auto_trigger in
  ('attendance','login','quiz','quiz_perfect','match','submit','gacha','decorate'));

alter table ch_assignments add column if not exists submit_mode text not null default 'teacher';
alter table ch_assignments drop constraint if exists ch_assignments_submit_mode_check;
alter table ch_assignments add constraint ch_assignments_submit_mode_check check (submit_mode in ('teacher','online','photo'));
alter table ch_submissions add column if not exists image_path text;
alter table ch_submissions add column if not exists note text;
alter table ch_submissions add column if not exists attempt int not null default 1;
alter table ch_submissions add column if not exists via text not null default 'teacher';

create table if not exists upload_slots (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  assignment_id uuid not null references ch_assignments(id) on delete cascade,
  expires_at timestamptz not null default now() + interval '15 minutes',
  used boolean not null default false
);

create table if not exists teams (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references classes(id) on delete cascade,
  name text not null,
  emoji text not null default '🧪',
  sort int not null default 0
);
alter table students add column if not exists team_id uuid references teams(id) on delete set null;

alter table quiz_questions add column if not exists class_id uuid references classes(id) on delete cascade;   -- null = ทุกห้อง
alter table classes add column if not exists quiz_topic text;                                                 -- บทที่กำลังเรียน (ควิซจะเน้นหัวข้อนี้)

create table if not exists bosses (
  id uuid primary key default gen_random_uuid(),
  class_id uuid references classes(id) on delete cascade,          -- null = ทุกห้อง
  name text not null,
  emoji text not null default '👹',
  image text,                                                      -- ภาพมอนสเตอร์ เช่น assets/bosses/acid_dragon.png (ว่าง = ใช้อีโมจิ)
  description text,
  hp_per_student int not null default 150 check (hp_per_student > 0),   -- เลือดบอส = ค่านี้ × จำนวนนักเรียนในห้อง
  start_date date not null default (date_trunc('week', today_th()))::date,
  days int not null default 7 check (days between 1 and 31),
  reward_exp int not null default 50,
  reward_coins int not null default 30,
  active boolean not null default true
);

do $$
declare t text;
begin
  foreach t in array array['upload_slots','teams','bosses'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists teacher_all on public.%I', t);
    execute format('create policy teacher_all on public.%I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;
alter table bosses add column if not exists image text;
alter table quest_claims add column if not exists dmg int;      -- ความเสียหายต่อบอส (บันทึกตอนอนุมัติ รวมโบนัสพลังโจมตี)
alter table bosses alter column hp_per_student set default 150;
create index if not exists idx_quest_claims_day on quest_claims(claim_date, status);
create index if not exists idx_students_team on students(team_id);

-- ---------------------------------------------------------------------
-- ข้อ 1: รางวัลทันทีหลังเช็คชื่อ
-- ---------------------------------------------------------------------
create or replace function trg_attendance() returns trigger
language plpgsql security definer set search_path = public as $$
declare v uuid;
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

  if new.status in ('present', 'late') and new.att_date >= today_th() - 3 then
    -- ตั๋วสุ่มกาชาฟรี 1 ใบต่อการเข้าเรียนหนึ่งครั้ง (กันซ้ำด้วย ledger)
    v := null;
    insert into ledger (student_id, exp, coins, reason, ref_key)
    values (new.student_id, 0, 0, 'ตั๋วสุ่มกาชาฟรี (เช็คชื่อ ' || new.att_date || ')', 'attticket:' || new.id)
    on conflict (student_id, ref_key) do nothing returning id into v;
    if v is not null then update students set free_pulls = free_pulls + 1 where id = new.student_id; end if;

    -- เควสที่ตั้งเป็น “สำเร็จอัตโนมัติเมื่อเช็คชื่อ”
    perform _auto_quests(new.student_id, 'attendance', new.att_date);
  end if;
  perform check_achievements(new.student_id);
  return new;
end $$;

create or replace function trg_submission() returns trigger
language plpgsql security definer set search_path = public as $$
declare a ch_assignments%rowtype; ref text;
begin
  select * into a from ch_assignments where id = new.assignment_id;
  ref := 'sub:' || new.id || case when new.attempt > 1 then ':' || new.attempt else '' end;
  if new.status = 'submitted' then
    perform award(new.student_id, a.exp_reward, a.coin_reward, 'ส่งงาน: ' || a.title, ref);
  elsif new.status = 'late' then
    if student_class(new.student_id) = 'guardian' then
      perform award(new.student_id, a.exp_reward, a.coin_reward, 'ส่งงาน (ช้า — ผู้พิทักษ์ได้เต็ม): ' || a.title, ref);
    else
      perform award(new.student_id, a.exp_reward / 2, a.coin_reward / 2, 'ส่งงาน (ช้า): ' || a.title, ref);
    end if;
  end if;
  if new.status in ('submitted', 'late') then perform _auto_quests(new.student_id, 'submit'); end if;
  perform check_achievements(new.student_id);
  return new;
end $$;

-- กาชา: ถ้ามีตั๋วฟรี สุ่ม ×1 จะใช้ตั๋วก่อน (ไม่เสียเหรียญ)
create or replace function gacha_pull(p_token uuid, p_n int default 1) returns json
language plpgsql security definer set search_path = public as $$
declare
  sid uuid := _sid(p_token); s students%rowtype;
  unit int := coalesce((select value::int from app_settings where key = 'gacha_cost'), 30);
  pity_max int := coalesce((select value::int from app_settings where key = 'pity_max'), 10);
  cost int; i int; it gacha_items%rowtype; high boolean; res jsonb := '[]'::jsonb; refund int := 0; free boolean := false;
begin
  if student_class(sid) = 'seeker' then pity_max := greatest(3, pity_max - 2); end if;
  if p_n not in (1, 10) then raise exception 'จำนวนครั้งไม่ถูกต้อง'; end if;
  select * into s from students where id = sid for update;
  if p_n = 1 and s.free_pulls > 0 then
    free := true; cost := 0;
    update students set free_pulls = free_pulls - 1 where id = sid;
  else
    cost := unit * p_n;
    if s.coins < cost then raise exception 'เหรียญไม่พอ (ต้องใช้ % เหรียญ)', cost; end if;
    update students set coins = coins - cost where id = sid;
  end if;
  for i in 1..p_n loop
    select * into s from students where id = sid;
    high := s.gacha_pity + 1 >= pity_max;
    it := _gacha_pick_luk(high, coalesce((_stats(sid)->'luk'->>'total')::int, 0));
    if it.rarity in ('SR','SSR') then
      update students set gacha_pity = 0 where id = sid;
    else
      update students set gacha_pity = gacha_pity + 1 where id = sid;
    end if;
    insert into gacha_pulls (student_id, item_id, cost) values (sid, it.id, case when free then 0 else unit end);
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
  return json_build_object('items', res, 'coins', s.coins, 'exp', s.exp, 'pity', s.gacha_pity, 'used_free', free, 'free_pulls', s.free_pulls);
end $$;

-- ---------------------------------------------------------------------
-- ข้อ 7: ส่งงานออนไลน์ / ถ่ายรูป
-- ---------------------------------------------------------------------
create or replace function _slot_ok(p_name text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from upload_slots where (id::text || '.jpg') = p_name and not used and expires_at > now())
$$;
revoke execute on function _slot_ok(text) from public;
grant execute on function _slot_ok(text) to anon, authenticated;

create or replace function begin_upload(p_token uuid, p_assignment uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); a ch_assignments%rowtype; v uuid;
begin
  select a2.* into a from ch_assignments a2 join students s on s.class_id = a2.class_id
   where a2.id = p_assignment and s.id = sid;
  if not found then raise exception 'ไม่พบงานนี้'; end if;
  if a.submit_mode <> 'photo' then raise exception 'งานนี้ไม่ต้องอัปโหลดรูป'; end if;
  delete from upload_slots where expires_at < now() - interval '1 day';
  insert into upload_slots (student_id, assignment_id) values (sid, a.id) returning id into v;
  return v;
end $$;

create or replace function submit_assignment(p_token uuid, p_assignment uuid, p_slot uuid default null) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); a ch_assignments%rowtype; ex ch_submissions%rowtype; st text; path text;
begin
  select a2.* into a from ch_assignments a2 join students s on s.class_id = a2.class_id
   where a2.id = p_assignment and s.id = sid;
  if not found then raise exception 'ไม่พบงานนี้'; end if;
  if a.submit_mode = 'teacher' then raise exception 'งานนี้ครูเป็นผู้บันทึกการส่ง'; end if;
  st := case when a.due_date is not null and today_th() > a.due_date then 'late' else 'submitted' end;

  select * into ex from ch_submissions where assignment_id = a.id and student_id = sid;
  if found and ex.status in ('submitted', 'late') then raise exception 'ส่งงานนี้แล้ว'; end if;

  if a.submit_mode = 'photo' then
    if p_slot is null then raise exception 'กรุณาแนบรูปงาน'; end if;
    perform 1 from upload_slots where id = p_slot and student_id = sid and assignment_id = a.id and not used and expires_at > now();
    if not found then raise exception 'ช่องอัปโหลดหมดอายุ ลองใหม่อีกครั้ง'; end if;
    path := p_slot::text || '.jpg';
    if not exists (select 1 from storage.objects where bucket_id = 'submissions' and name = path) then
      raise exception 'ยังไม่พบรูปที่อัปโหลด ลองใหม่อีกครั้ง';
    end if;
    update upload_slots set used = true where id = p_slot;
  end if;

  insert into ch_submissions (assignment_id, student_id, status, image_path, via, note)
  values (a.id, sid, st, path, 'student', null)
  on conflict (assignment_id, student_id)
    do update set status = excluded.status, image_path = excluded.image_path, via = 'student', note = null, submitted_at = now();
  return json_build_object('status', st, 'exp', case when st = 'late' then a.exp_reward / 2 else a.exp_reward end);
end $$;

-- ครูส่งคืนงาน (ไม่ผ่าน): หัก EXP/เหรียญที่ให้ไปคืน แล้วให้นักเรียนส่งใหม่ได้
create or replace function admin_return_submission(p_sub uuid, p_note text default null) returns void
language plpgsql security definer set search_path = public as $$
declare s ch_submissions%rowtype; ref text; l ledger%rowtype; a ch_assignments%rowtype;
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  select * into s from ch_submissions where id = p_sub;
  if not found then raise exception 'ไม่พบการส่งงาน'; end if;
  select * into a from ch_assignments where id = s.assignment_id;
  ref := 'sub:' || s.id || case when s.attempt > 1 then ':' || s.attempt else '' end;
  select * into l from ledger where student_id = s.student_id and ref_key = ref;
  if found and (l.exp <> 0 or l.coins <> 0) then
    perform award(s.student_id, -l.exp, -l.coins, 'ครูส่งคืนงาน: ' || a.title, 'subret:' || s.id || ':' || s.attempt);
  end if;
  update ch_submissions set status = 'missing', note = coalesce(nullif(p_note, ''), 'ครูส่งคืนให้แก้ไข'), attempt = attempt + 1, score = null where id = s.id;
end $$;

-- ที่เก็บรูป (Supabase Storage): ส่วนตัว, ไฟล์ละไม่เกิน 1.5MB, เฉพาะ JPEG · นักเรียนอัปโหลดได้เฉพาะช่องที่ระบบเปิดให้ · ครูอ่าน/ลบได้
do $$
begin
  if to_regclass('storage.buckets') is not null then
    insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
    values ('submissions', 'submissions', false, 1572864, array['image/jpeg'])
    on conflict (id) do update set public = false, file_size_limit = 1572864, allowed_mime_types = array['image/jpeg'];
    drop policy if exists chem_sub_upload on storage.objects;
    create policy chem_sub_upload on storage.objects for insert to anon, authenticated
      with check (bucket_id = 'submissions' and public._slot_ok(name));
    drop policy if exists chem_sub_teacher on storage.objects;
    create policy chem_sub_teacher on storage.objects for all to authenticated
      using (bucket_id = 'submissions' and public.is_teacher()) with check (bucket_id = 'submissions' and public.is_teacher());
  end if;
exception when others then
  raise notice 'ตั้งค่า Storage ไม่สำเร็จ (%): ไปสร้าง bucket ชื่อ submissions แบบ Private ใน Storage เอง แล้วดูวิธีใน README', sqlerrm;
end $$;

-- ---------------------------------------------------------------------
-- เควสที่ระบบเช็คให้อัตโนมัติ: ตั้งที่แท็บเควส คอลัมน์ “อัตโนมัติ” (ทำเงื่อนไขเมื่อไหร่ ระบบให้รางวัลทันที ไม่ต้องกดขอและไม่ต้องรอครู)
--   attendance=ครูเช็คชื่อว่ามา · login=เข้าสู่ระบบวันนี้ · quiz=ทำควิซประจำวัน · quiz_perfect=ควิซถูกทุกข้อ
--   match=เล่นเกมจับคู่ธาตุ · submit=ส่งงาน 1 ชิ้น · gacha=สุ่มกาชา · decorate=เปลี่ยนชุด/ไอเทมตกแต่งตัวละคร
-- ---------------------------------------------------------------------
create or replace function _auto_quests(p_sid uuid, p_trigger text, p_date date default null) returns void
language plpgsql security definer set search_path = public as $$
declare cls uuid; q record; d date := coalesce(p_date, today_th());
begin
  select class_id into cls from students where id = p_sid;
  for q in select * from quests where active and auto_trigger = p_trigger and (class_id is null or class_id = cls) loop
    insert into quest_claims (quest_id, student_id, claim_date, status)
    values (q.id, p_sid, quest_period(q.kind, d), 'approved')
    on conflict (quest_id, student_id, claim_date) do nothing;
  end loop;
end $$;

create or replace function trg_auto_game() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.game = 'quiz' then
    perform _auto_quests(new.student_id, 'quiz', new.play_date);
    if new.score >= 100 then perform _auto_quests(new.student_id, 'quiz_perfect', new.play_date); end if;
  else
    perform _auto_quests(new.student_id, 'match', new.play_date);
  end if;
  return new;
end $$;
drop trigger if exists auto_game on game_plays;
create trigger auto_game after insert on game_plays for each row execute function trg_auto_game();

create or replace function trg_auto_login() returns trigger
language plpgsql security definer set search_path = public as $$
begin perform _auto_quests(new.id, 'login'); return new; end $$;
drop trigger if exists auto_login on students;
create trigger auto_login after update of last_login on students
  for each row when (new.last_login is distinct from old.last_login) execute function trg_auto_login();

create or replace function trg_auto_decor() returns trigger
language plpgsql security definer set search_path = public as $$
begin perform _auto_quests(new.id, 'decorate'); return new; end $$;
drop trigger if exists auto_decor on students;
create trigger auto_decor after update of decor on students
  for each row when (new.decor is distinct from old.decor and new.decor <> '{}'::jsonb) execute function trg_auto_decor();

create or replace function trg_auto_gacha() returns trigger
language plpgsql security definer set search_path = public as $$
begin perform _auto_quests(new.student_id, 'gacha'); return new; end $$;
drop trigger if exists auto_gacha on gacha_pulls;
create trigger auto_gacha after insert on gacha_pulls for each row execute function trg_auto_gacha();

-- เควสอัตโนมัติ: แสดงในรายการเสมอ (ไม่นับโควตาสุ่มรายวัน) แต่นักเรียนกดเองไม่ได้ (กันกดโดยไม่ได้มาเรียน)
create or replace function todays_quests(p_class uuid, p_date date)
returns setof quests language sql stable security definer set search_path = public as $$
  (select * from quests
    where active and auto_trigger is null and kind = 'daily' and (class_id is null or class_id = p_class)
    order by md5(id::text || p_date::text)
    limit coalesce((select value::int from app_settings where key = 'daily_quest_count'), 3))
  union all
  (select * from quests
    where active and auto_trigger is null and kind = 'weekly' and (class_id is null or class_id = p_class))
  union all
  (select * from quests
    where active and auto_trigger is not null and (class_id is null or class_id = p_class))
$$;

create or replace function claim_quest(p_token uuid, p_quest uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); s students%rowtype; q quests%rowtype; st text; per date;
begin
  select * into s from students where id = sid;
  select * into q from todays_quests(s.class_id, today_th()) t where t.id = p_quest;
  if not found then raise exception 'เควสนี้ไม่ได้เปิดให้ทำวันนี้'; end if;
  if q.auto_trigger is not null then raise exception 'เควสนี้ระบบเช็คให้อัตโนมัติ ไม่ต้องกดเอง'; end if;
  per := quest_period(q.kind, today_th());
  st := case when q.needs_approval then 'pending' else 'approved' end;
  begin
    insert into quest_claims (quest_id, student_id, claim_date, status) values (q.id, sid, per, st);
  exception when unique_violation then
    raise exception 'ทำเควสนี้ไปแล้ว';
  end;
  return json_build_object('status', st);
end $$;

-- ---------------------------------------------------------------------
-- ข้อ 3: ทีม / ห้องแข่ง EXP (นับจาก EXP ที่ได้ “สัปดาห์นี้” จากสมุดบัญชี)
-- ---------------------------------------------------------------------
create or replace function team_board(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); s students%rowtype; wk date := date_trunc('week', today_th())::date; r json;
begin
  select * into s from students where id = sid;
  select json_build_object(
    'week_start', wk,
    'my_team', s.team_id,
    'teams', (select coalesce(json_agg(t order by t.avg_week desc, t.exp_week desc, t.name), '[]'::json) from (
        select tm.id, tm.name, tm.emoji, (tm.id = s.team_id) as mine,
               count(st.id)::int as members,
               coalesce(sum(w.x), 0)::int as exp_week,
               case when count(st.id) = 0 then 0 else round(coalesce(sum(w.x), 0)::numeric / count(st.id), 1) end as avg_week,
               (select coalesce(json_agg(json_build_object('name', m.name, 'exp_week', coalesce(mw.x, 0), 'me', m.id = sid)
                        order by coalesce(mw.x, 0) desc, m.no), '[]'::json)
                  from students m
                  left join lateral (select sum(l.exp)::int as x from ledger l
                       where l.student_id = m.id and (l.created_at at time zone 'Asia/Bangkok')::date >= wk) mw on true
                 where m.team_id = tm.id and tm.id = s.team_id) as roster
          from teams tm
          left join students st on st.team_id = tm.id
          left join lateral (select sum(l.exp) as x from ledger l
               where l.student_id = st.id and (l.created_at at time zone 'Asia/Bangkok')::date >= wk) w on true
         where tm.class_id = s.class_id
         group by tm.id, tm.name, tm.emoji
    ) t),
    'rooms', (select coalesce(json_agg(x order by x.avg_week desc), '[]'::json) from (
        select c.name, (c.id = s.class_id) as mine, count(st.id)::int as students,
               case when count(st.id) = 0 then 0 else round(coalesce(sum(w.x), 0)::numeric / count(st.id), 1) end as avg_week
          from classes c
          left join students st on st.class_id = c.id
          left join lateral (select sum(l.exp) as x from ledger l
               where l.student_id = st.id and (l.created_at at time zone 'Asia/Bangkok')::date >= wk) w on true
         group by c.id, c.name
        having count(st.id) > 0
    ) x)
  ) into r;
  return r;
end $$;

-- ครู: สุ่มแบ่งทีมทั้งห้อง (ลบทีมเดิมของห้อง)
create or replace function admin_random_teams(p_class uuid, p_n int) returns int
language plpgsql security definer set search_path = public as $$
declare
  names text[] := array['ไฮโดรเจน','ฮีเลียม','ลิเทียม','คาร์บอน','ไนโตรเจน','ออกซิเจน','นีออน','โซเดียม','แมกนีเซียม','ทองคำ','เงิน','ทองแดง'];
  emos text[] := array['💧','🎈','🔋','💎','🌫️','🫧','💡','🧂','✨','🥇','🥈','🥉'];
  ids uuid[] := '{}'; tid uuid; i int := 0; sid uuid;
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  if p_n < 2 or p_n > 12 then raise exception 'จำนวนทีมต้องอยู่ระหว่าง 2–12'; end if;
  update students set team_id = null where class_id = p_class;
  delete from teams where class_id = p_class;
  for i in 1..p_n loop
    insert into teams (class_id, name, emoji, sort) values (p_class, 'ทีม' || names[i], emos[i], i) returning id into tid;
    ids := ids || tid;
  end loop;
  i := 0;
  for sid in select id from students where class_id = p_class order by random() loop
    update students set team_id = ids[(i % p_n) + 1] where id = sid;
    i := i + 1;
  end loop;
  return i;
end $$;

-- ---------------------------------------------------------------------
-- ข้อ 4: สรุปรายสัปดาห์สำหรับครู
-- ---------------------------------------------------------------------
create or replace function admin_weekly_digest(p_class uuid, p_days int default 7) returns json
language plpgsql security definer set search_path = public as $$
declare d0 date := today_th() - (greatest(p_days, 1) - 1); today date := today_th(); r json;
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  select json_build_object(
    'from', d0, 'to', today, 'days', p_days,
    'students', (select count(*) from students where class_id = p_class),
    'attendance', (select json_build_object(
        'days_marked', count(distinct att_date),
        'present', count(*) filter (where status = 'present'), 'late', count(*) filter (where status = 'late'),
        'absent', count(*) filter (where status = 'absent'), 'leave', count(*) filter (where status = 'leave'))
        from ch_attendance where class_id = p_class and att_date between d0 and today),
    'absent', (select coalesce(json_agg(x order by x.absent_week desc, x.no), '[]'::json) from (
        select s.no, s.name,
               count(*) filter (where a.att_date between d0 and today and a.status = 'absent')::int as absent_week,
               count(*) filter (where a.att_date >= today - 29 and a.status = 'absent')::int as absent_30,
               count(*) filter (where a.att_date >= today - 29 and a.status = 'late')::int as late_30
          from students s left join ch_attendance a on a.student_id = s.id
         where s.class_id = p_class group by s.id, s.no, s.name
        having count(*) filter (where a.att_date between d0 and today and a.status = 'absent') > 0
            or count(*) filter (where a.att_date >= today - 29 and a.status = 'absent') >= 3
    ) x),
    'missing', (select coalesce(json_agg(x order by x.missing desc, x.no), '[]'::json) from (
        select s.no, s.name, count(*)::int as missing, json_agg(a.title order by a.due_date) as titles
          from students s
          join ch_assignments a on a.class_id = s.class_id and a.due_date is not null and a.due_date < today
          left join ch_submissions sb on sb.assignment_id = a.id and sb.student_id = s.id and sb.status in ('submitted','late')
         where s.class_id = p_class and sb.id is null
         group by s.id, s.no, s.name
    ) x),
    'inactive', (select coalesce(json_agg(x order by x.last_login nulls first, x.no), '[]'::json) from (
        select no, name, last_login from students
         where class_id = p_class and (last_login is null or last_login < now() - make_interval(days => p_days))
    ) x),
    'top', (select coalesce(json_agg(x order by x.exp_week desc), '[]'::json) from (
        select s.no, s.name, sum(l.exp)::int as exp_week
          from ledger l join students s on s.id = l.student_id
         where s.class_id = p_class and (l.created_at at time zone 'Asia/Bangkok')::date between d0 and today
         group by s.id, s.no, s.name order by sum(l.exp) desc limit 5
    ) x),
    'exp_total', (select coalesce(sum(l.exp), 0)::int from ledger l join students s on s.id = l.student_id
                   where s.class_id = p_class and (l.created_at at time zone 'Asia/Bangkok')::date between d0 and today)
  ) into r;
  return r;
end $$;

-- ---------------------------------------------------------------------
-- ข้อ 5: ควิซตามบทเรียน — ข้อของบทที่ห้องกำลังเรียนมาก่อน, ข้อเฉพาะห้องมาถัดไป, แล้วเติมด้วยข้อทั่วไป
-- ---------------------------------------------------------------------
create or replace function _quiz_ids(p_sid uuid, p_date date) returns uuid[]
language sql stable security definer set search_path = public as $$
  select coalesce(array_agg(id order by pri, k), '{}') from (
    select q.id, md5(q.id::text || p_sid::text || p_date::text) as k,
           case when c.quiz_topic is not null and q.topic = c.quiz_topic then 0
                when q.class_id is not null then 1 else 2 end as pri
      from quiz_questions q
      join students s on s.id = p_sid
      join classes c on c.id = s.class_id
     where q.active and (q.class_id is null or q.class_id = s.class_id)
     order by pri, k
     limit _setting_int('quiz_count', 5)
  ) z
$$;

-- ---------------------------------------------------------------------
-- ข้อ 8: บอสประจำสัปดาห์ — ความเสียหาย = EXP ของเควสที่ได้รับอนุมัติในช่วงของบอส (ทั้งห้องรวมกัน)
-- ---------------------------------------------------------------------
create or replace function _boss_for(p_class uuid) returns bosses
language sql stable security definer set search_path = public as $$
  select * from bosses
   where active and (class_id is null or class_id = p_class)
     and today_th() between start_date and start_date + days - 1 + 7        -- แสดงต่ออีก 7 วันหลังหมดเวลา เพื่อรับรางวัล
   order by (class_id is null), start_date desc limit 1
$$;

create or replace function _boss_damage(p_boss bosses, p_class uuid, p_student uuid default null) returns int
language sql stable security definer set search_path = public as $$
  select coalesce(sum(coalesce(cl.dmg, greatest(q.exp, 1))), 0)::int
    from quest_claims cl
    join quests q on q.id = cl.quest_id
    join students st on st.id = cl.student_id
   where st.class_id = p_class and cl.status = 'approved'
     and cl.claim_date between p_boss.start_date and p_boss.start_date + p_boss.days - 1
     and (p_student is null or cl.student_id = p_student)
$$;

create or replace function boss_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cls uuid; b bosses%rowtype; n int; mx int; dmg int; mine int; end_d date; done boolean; claimed boolean;
begin
  select class_id into cls from students where id = sid;
  b := _boss_for(cls);
  if b.id is null then return null; end if;
  select count(*) into n from students where class_id = cls;
  mx := b.hp_per_student * greatest(n, 1);
  dmg := _boss_damage(b, cls);
  mine := _boss_damage(b, cls, sid);
  end_d := b.start_date + b.days - 1;
  done := dmg >= mx;
  claimed := exists (select 1 from ledger where student_id = sid and ref_key = 'boss:' || b.id);
  return json_build_object(
    'id', b.id, 'name', b.name, 'emoji', b.emoji, 'image', b.image, 'description', b.description,
    'max_hp', mx, 'damage', least(dmg, mx), 'hp', greatest(mx - dmg, 0), 'defeated', done,
    'my_damage', mine, 'start', b.start_date, 'end', end_d, 'ended', today_th() > end_d,
    'days_left', greatest(end_d - today_th() + 1, 0),
    'reward_exp', b.reward_exp, 'reward_coins', b.reward_coins,
    'claimed', claimed, 'can_claim', done and mine > 0 and not claimed,
    'top', (select coalesce(json_agg(x), '[]'::json) from (
        select st.name, sum(coalesce(cl.dmg, greatest(q.exp, 1)))::int as dmg, (st.id = sid) as me
          from quest_claims cl join quests q on q.id = cl.quest_id join students st on st.id = cl.student_id
         where st.class_id = cls and cl.status = 'approved'
           and cl.claim_date between b.start_date and end_d
         group by st.id, st.name order by sum(coalesce(cl.dmg, greatest(q.exp, 1))) desc limit 5) x));
end $$;

create or replace function boss_claim(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cls uuid; b bosses%rowtype; n int; ok boolean;
begin
  select class_id into cls from students where id = sid;
  b := _boss_for(cls);
  if b.id is null then raise exception 'ไม่มีบอสในตอนนี้'; end if;
  select count(*) into n from students where class_id = cls;
  if _boss_damage(b, cls) < b.hp_per_student * greatest(n, 1) then raise exception 'ยังปราบบอสไม่สำเร็จ'; end if;
  if _boss_damage(b, cls, sid) <= 0 then raise exception 'ต้องช่วยทำเควสอย่างน้อย 1 ครั้งจึงจะรับรางวัลได้'; end if;
  ok := award(sid, b.reward_exp, b.reward_coins, 'ปราบบอส: ' || b.name, 'boss:' || b.id);
  if not ok then raise exception 'รับรางวัลไปแล้ว'; end if;
  perform check_achievements(sid);
  return json_build_object('exp', b.reward_exp, 'coins', b.reward_coins);
end $$;

-- ---------------------------------------------------------------------
-- ข้อมูลเสริมสำหรับหน้านักเรียน (เรียกครั้งเดียวตอนโหลด)
-- ---------------------------------------------------------------------
create or replace function student_extras(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); s students%rowtype;
begin
  select * into s from students where id = sid;
  return json_build_object(
    'free_pulls', s.free_pulls,
    'submit', (select coalesce(json_object_agg(a.id, json_build_object('mode', a.submit_mode, 'note', sb.note,
                 'has_image', sb.image_path is not null, 'via', sb.via)), '{}'::json)
                 from ch_assignments a left join ch_submissions sb on sb.assignment_id = a.id and sb.student_id = sid
                where a.class_id = s.class_id),
    'stats', _stats(sid),
    'stats_abilities', (select coalesce(json_agg(a), '[]'::json) from (select d.name || ' — ' || (to_jsonb(d)->>'ability') as a
        from students sx cross join lateral jsonb_each_text(sx.decor) e join decor_items d on d.id = e.value::uuid and d.slot = e.key
       where sx.id = sid and coalesce(to_jsonb(d)->>'ability', '') <> '') z),
    'item_stats', (select coalesce(json_object_agg(d.id, json_build_object('int', d.st_int, 'dil', d.st_dil, 'str', d.st_str, 'luk', d.st_luk, 'coin', to_jsonb(d)->>'st_coin', 'ability', to_jsonb(d)->>'ability')), '{}'::json)
                     from decor_items d where d.active and (d.st_int + d.st_dil + d.st_str + d.st_luk > 0 or coalesce((to_jsonb(d)->>'st_coin')::int, 0) > 0)),
    'auto', (select coalesce(json_object_agg(q.id, q.auto_trigger), '{}'::json) from todays_quests(s.class_id, today_th()) q where q.auto_trigger is not null),
    'teams', team_board(p_token),
    'boss', boss_status(p_token));
end $$;

revoke execute on function _boss_for(uuid) from public, anon, authenticated;
revoke execute on function _boss_damage(bosses, uuid, uuid) from public, anon, authenticated;
revoke execute on function trg_attendance() from public, anon, authenticated;
revoke execute on function trg_submission() from public, anon, authenticated;
revoke execute on function gacha_pull(uuid, int) from public;
revoke execute on function begin_upload(uuid, uuid) from public;
revoke execute on function submit_assignment(uuid, uuid, uuid) from public;
revoke execute on function team_board(uuid) from public;
revoke execute on function boss_status(uuid) from public;
revoke execute on function boss_claim(uuid) from public;
revoke execute on function student_extras(uuid) from public;
revoke execute on function admin_return_submission(uuid, text) from public, anon;
revoke execute on function admin_random_teams(uuid, int) from public, anon;
revoke execute on function admin_weekly_digest(uuid, int) from public, anon;
revoke execute on function _auto_quests(uuid, text, date) from public, anon, authenticated;
grant execute on function gacha_pull(uuid, int), begin_upload(uuid, uuid), submit_assignment(uuid, uuid, uuid), team_board(uuid),
  boss_status(uuid), boss_claim(uuid), student_extras(uuid) to anon, authenticated;
grant execute on function admin_return_submission(uuid, text), admin_random_teams(uuid, int), admin_weekly_digest(uuid, int) to authenticated;

-- ---------------------------------------------------------------------
-- ตัวอย่างเริ่มต้น (ใส่เฉพาะตอนยังไม่มี)
-- ---------------------------------------------------------------------
do $$
begin
  -- บอสหมุนเวียนรายสัปดาห์ 6 ตัว (เพิ่มเฉพาะชื่อที่ยังไม่มี · เริ่มสัปดาห์นี้ ตัวถัดไปทุกวันจันทร์ · ครูแก้/ปิด/เพิ่มได้ที่แท็บบอส)
  insert into bosses (name, emoji, image, description, hp_per_student, start_date, reward_exp, reward_coins)
  select v.n, v.e, 'assets/bosses/' || v.i || '.png', v.d, 150, (date_trunc('week', today_th()))::date + 7 * v.w, 50, 30
    from (values
      (0, 'มังกรกรดซัลฟิวริก', '🐲', 'acid_dragon', 'มังกรพ่นกรดที่ขดตัวรอบขวดทดลอง! ทุกเควสที่ทำสำเร็จคือการโจมตี ช่วยกันทั้งห้องก่อนหมดสัปดาห์'),
      (1, 'โกเลมบีกเกอร์พิษ', '🧪', 'beaker_golem', 'หุ่นแก้วบรรจุของเหลวสีม่วงเดือดพล่าน ใครทำเควสเยอะ ยิ่งแตกเร็ว'),
      (2, 'จอมเวทอิเล็กตรอน', '⚡', 'electron_wizard', 'ผู้ควบคุมอะตอมและสายฟ้า วงโคจรของมันป้องกันได้แค่คนที่ไม่ขยัน'),
      (3, 'หุ่นยนต์ธาตุจักรกล', '🤖', 'element_robot', 'เกราะทำจากแผ่นธาตุในตารางธาตุ ต้องใช้ความรู้เคมีจึงจะพังได้'),
      (4, 'ปีศาจตะเกียงเพลิง', '🔥', 'flame_demon', 'วิญญาณเปลวไฟจากตะเกียงแอลกอฮอล์ ดับมันด้วยการสะสมเควสให้ครบ'),
      (5, 'ไฮดราเชื้อโรคแปดตา', '🦠', 'germ_hydra', 'เชื้อโรคจอมแพร่พันธุ์ที่มีกล้องจุลทรรศน์เป็นตา ต้องช่วยกันทั้งห้องถึงจะปราบได้')
    ) v(w, n, e, i, d)
   where not exists (select 1 from bosses b where b.name = v.n);
  update bosses set image = 'assets/bosses/acid_dragon.png' where name = 'มังกรกรดซัลฟิวริก' and image is null;
  -- เควสประจำวันที่ระบบเช็คให้เอง (เพิ่มเฉพาะที่ยังไม่มีเงื่อนไขนั้น ครูแก้/ปิดได้ที่แท็บเควส)
  insert into quests (class_id, title, description, kind, exp, coins, needs_approval, auto_trigger)
  select null, v.t, v.d, 'daily', v.e, v.c, false, v.a from (values
    ('attendance', 'มาเรียนวันนี้', 'สำเร็จอัตโนมัติเมื่อครูเช็คชื่อว่ามา', 3, 1),
    ('login', 'เข้าห้องแล็บวันนี้', 'เข้าสู่ระบบ Chemistria วันนี้', 2, 1),
    ('quiz', 'ทำควิซประจำวัน', 'ทำควิซประจำวันให้ครบ (ไปที่แท็บเกม)', 3, 1),
    ('quiz_perfect', 'ควิซเต็ม!', 'ตอบควิซประจำวันถูกทุกข้อ', 5, 2),
    ('match', 'จับคู่ธาตุ', 'เล่นเกมจับคู่ธาตุ 1 รอบ', 3, 1),
    ('submit', 'ส่งงานวันนี้', 'ส่งงาน 1 ชิ้นในวันนี้ (ออนไลน์/ส่งรูป หรือครูบันทึกให้)', 5, 2),
    ('gacha', 'ลองดวงกาชา', 'สุ่มกาชา 1 ครั้ง (ใช้ตั๋วฟรีได้)', 2, 1),
    ('decorate', 'แต่งตัวละคร', 'เปลี่ยนชุด/เอฟเฟค/ไอเทมของตัวละคร', 2, 1)
  ) v(a, t, d, e, c)
  where not exists (select 1 from quests q where q.auto_trigger = v.a);
  update bosses set hp_per_student = 150 where name = 'มังกรกรดซัลฟิวริก' and hp_per_student = 60;
end $$;
-- =====================================================================
-- Chemistria · รอบที่ 9: สเตตัสนักเรียน (ปัญญา · ความขยัน · พลังโจมตี · โชค) + ไอเทมเพิ่มสเตตัส
--   ปัญญา  → โบนัส EXP ทุกครั้งที่ทำควิซประจำวัน (+1 EXP ต่อ 2 แต้ม)
--   ขยัน   → EXP จากเช็คชื่อ/ส่งงาน/เควส เพิ่มขึ้น +1% ต่อแต้ม
--   พลังโจมตี → ความเสียหายต่อบอส +3% ต่อแต้ม (คิดตอนเควสสำเร็จ)
--   โชค    → โอกาสออกของ SR/SSR ในกาชา +3% ต่อแต้ม
-- ค่าสเตตัส = ฐานจากการเรียน/เล่น (ต่อด้านสูงสุด 10) + โบนัสจากไอเทมที่สวมใส่
-- รันซ้ำได้ · ต้องรันหลัง 08 (setup_all.sql รวมให้แล้ว) · ฟังก์ชัน award/quiz_submit ในไฟล์นี้ใช้แทนเวอร์ชันเดิม
-- =====================================================================

alter table decor_items add column if not exists st_int int not null default 0;   -- ปัญญา
alter table decor_items add column if not exists st_dil int not null default 0;   -- ความขยัน
alter table decor_items add column if not exists st_str int not null default 0;   -- พลังโจมตี
alter table decor_items add column if not exists st_luk int not null default 0;   -- โชค
alter table decor_items add column if not exists st_coin int not null default 0;  -- โบนัสเหรียญ % (เช็คชื่อ/ส่งงาน/เควส) — ความสามารถพิเศษของฉายา/ไอเทม
alter table decor_items add column if not exists ability text;                   -- คำอธิบายความสามารถ (โชว์ให้นักเรียนเห็น)

create or replace function _stats(p_sid uuid) returns json
language plpgsql stable security definer set search_path = public as $$
declare
  b_int int; b_dil int; b_str int; b_luk int;
  i_int int := 0; i_dil int := 0; i_str int := 0; i_luk int := 0; i_coin int := 0;
begin
  b_int := least(10, coalesce((select sum(correct) from game_plays where student_id = p_sid and game = 'quiz'), 0)::int / 8);
  b_dil := least(10, student_metric(p_sid, 'present_count') / 4);
  b_str := least(10, student_metric(p_sid, 'quests_done') / 8);
  b_luk := least(10, student_metric(p_sid, 'gacha_pulls') / 6);
  if coalesce((select is_gm from students where id = p_sid), false) then b_int := 10; b_dil := 10; b_str := 10; b_luk := 10; end if;   -- ไอดี GM: ค่าพื้นฐานเต็ม
  select coalesce(sum(d.st_int), 0), coalesce(sum(d.st_dil), 0), coalesce(sum(d.st_str), 0), coalesce(sum(d.st_luk), 0), coalesce(sum(d.st_coin), 0)
    into i_int, i_dil, i_str, i_luk, i_coin
    from students s
    cross join lateral jsonb_each_text(s.decor) e
    join decor_items d on d.id = e.value::uuid and d.slot = e.key
   where s.id = p_sid;
  return json_build_object(
    'int', json_build_object('base', b_int, 'item', i_int, 'total', b_int + i_int),
    'dil', json_build_object('base', b_dil, 'item', i_dil, 'total', b_dil + i_dil),
    'str', json_build_object('base', b_str, 'item', i_str, 'total', b_str + i_str),
    'luk', json_build_object('base', b_luk, 'item', i_luk, 'total', b_luk + i_luk),
    'effects', json_build_object('quiz_exp', (b_int + i_int) / 2, 'exp_pct', b_dil + i_dil,
                                 'boss_pct', 3 * (b_str + i_str), 'rare_pct', 3 * (b_luk + i_luk), 'coin_pct', i_coin));
end $$;

-- ความเสียหายต่อบอสของเควสหนึ่งครั้ง: ฐาน = EXP ของเควส (อย่างน้อย 1) × (1 + 3% × พลังโจมตี) · บันทึกไว้ตอนอนุมัติ ไม่เปลี่ยนย้อนหลัง
create or replace function trg_claim_dmg() returns trigger
language plpgsql security definer set search_path = public as $$
declare base int; s int;
begin
  if new.status = 'approved' and new.dmg is null then
    select greatest(q.exp, 1) into base from quests q where q.id = new.quest_id;
    s := coalesce((_stats(new.student_id)->'str'->>'total')::int, 0);
    new.dmg := greatest(round(coalesce(base, 1) * (1 + 0.03 * s))::int, 1);
  end if;
  return new;
end $$;
drop trigger if exists claim_dmg on quest_claims;
create trigger claim_dmg before insert or update of status on quest_claims
  for each row execute function trg_claim_dmg();

-- กาชา: ค่าโชคเพิ่มน้ำหนักของ SR/SSR ทีละ 3% ต่อแต้ม
create or replace function _gacha_pick_luk(p_high boolean, p_luk int) returns gacha_items
language plpgsql security definer set search_path = public as $$
declare total numeric; r numeric; acc numeric := 0; it gacha_items%rowtype; last_it gacha_items%rowtype; w numeric;
begin
  select coalesce(sum(weight * case when rarity in ('SR','SSR') then 1 + 0.03 * greatest(p_luk, 0) else 1 end), 0) into total
    from gacha_items where active and (not p_high or rarity in ('SR','SSR'));
  if total = 0 then raise exception 'ยังไม่มีไอเทมในกาชา'; end if;
  r := random() * total;
  for it in select * from gacha_items where active and (not p_high or rarity in ('SR','SSR')) order by id loop
    w := it.weight * case when it.rarity in ('SR','SSR') then 1 + 0.03 * greatest(p_luk, 0) else 1 end;
    acc := acc + w; last_it := it;
    if r < acc then return it; end if;
  end loop;
  return last_it;
end $$;

create or replace function award(p_student uuid, p_exp int, p_coins int, p_reason text, p_ref text default null)
returns boolean language plpgsql security definer set search_path = public as $$
declare v uuid; cls text; e int := p_exp; c int := p_coins; rs text := p_reason; dil int; e2 int; cp int; c2 int;
begin
  -- ความสามารถคลาส: โบนัสเฉพาะรางวัลจากเช็คชื่อ / ส่งงาน / เควส
  if p_ref ~ '^(att|sub|quest):' then
    cls := student_class(p_student);
    if cls = 'scientist' and e > 0 then e := ceil(e * 1.15)::int; rs := rs || ' (โบนัสนักทดลอง)'; end if;
    if cls = 'alchemist' and c > 0 then c := ceil(c * 1.25)::int; rs := rs || ' (โบนัสนักเล่นแร่แปรธาตุ)'; end if;
    -- สเตตัสความขยัน: +1% ต่อแต้ม (เฉพาะรางวัลเช็คชื่อ/ส่งงาน/เควส)
    if e > 0 then
      dil := coalesce((_stats(p_student)->'dil'->>'total')::int, 0);
      e2 := round(e * (1 + dil / 100.0))::int;
      if e2 > e then e := e2; rs := rs || ' (ขยัน +' || dil || '%)'; end if;
    end if;
    -- ความสามารถฉายา/ไอเทม: โบนัสเหรียญ %
    if c > 0 then
      cp := coalesce((_stats(p_student)->'effects'->>'coin_pct')::int, 0);
      c2 := round(c * (1 + cp / 100.0))::int;
      if c2 > c then c := c2; rs := rs || ' (เหรียญ +' || cp || '%)'; end if;
    end if;
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

create or replace function quiz_submit(p_token uuid, p_answers jsonb) returns json
language plpgsql security definer set search_path = public as $$
declare
  sid uuid := _sid(p_token); d date := today_th(); ids uuid[]; q quiz_questions%rowtype;
  total int; i int; pick int; corr int := 0; res jsonb := '[]'::jsonb;
  raw int; e int; c int := 0; stk int; cap int := _setting_int('game_daily_cap_exp', 40); sb int := 0;
begin
  if p_answers is null or jsonb_typeof(p_answers) <> 'array' then raise exception 'ข้อมูลคำตอบไม่ถูกต้อง'; end if;
  ids := _quiz_ids(sid, d);
  total := coalesce(array_length(ids, 1), 0);
  if total = 0 then raise exception 'ยังไม่มีคำถามในระบบ'; end if;
  if exists (select 1 from game_plays where student_id = sid and game = 'quiz' and play_date = d) then
    raise exception 'วันนี้ทำควิซไปแล้ว พรุ่งนี้มาใหม่นะ';
  end if;
  for i in 1..total loop
    select * into q from quiz_questions where id = ids[i];
    begin pick := coalesce((p_answers ->> (i - 1))::int, -1); exception when others then pick := -1; end;
    if pick = q.answer then corr := corr + 1; end if;
    res := res || jsonb_build_object('id', q.id, 'pick', pick, 'answer', q.answer,
             'ok', pick = q.answer, 'explain', q.explain);
  end loop;
  if corr > 0 then sb := coalesce((_stats(sid)->'int'->>'total')::int, 0) / 2; end if;     -- สเตตัสปัญญา: +1 EXP ต่อ 2 แต้ม
  raw := corr * _setting_int('quiz_exp_per_correct', 4)
         + case when corr = total then _setting_int('quiz_perfect_bonus', 5) else 0 end + sb;
  e := least(raw, greatest(0, cap - _game_exp_today(sid)));
  begin
    insert into game_plays (student_id, game, play_date, score, correct, exp, coins)
    values (sid, 'quiz', d, round(100.0 * corr / total), corr, e, 0);
  exception when unique_violation then
    raise exception 'วันนี้ทำควิซไปแล้ว พรุ่งนี้มาใหม่นะ';
  end;
  stk := _quiz_streak(sid);
  if corr > 0 then c := corr + least(stk - 1, 5); end if;   -- เหรียญ 1/ข้อ + โบนัสทำติดกันหลายวัน (สูงสุด +5)
  update game_plays set coins = c where student_id = sid and game = 'quiz' and play_date = d;
  perform award(sid, e, c, 'ควิซประจำวัน ' || corr || '/' || total || case when sb > 0 then ' (+' || sb || ' ปัญญา)' else '' end, 'game:quiz:' || d);
  return json_build_object('correct', corr, 'total', total, 'exp', e, 'coins', c, 'raw_exp', raw,
                           'capped', e < raw, 'streak', stk, 'stat_bonus', sb, 'results', res);
end $$;

revoke execute on function _stats(uuid) from public, anon, authenticated;
revoke execute on function _gacha_pick_luk(boolean, int) from public, anon, authenticated;
revoke execute on function trg_claim_dmg() from public, anon, authenticated;
revoke execute on function award(uuid, int, int, text, text) from public, anon, authenticated;
revoke execute on function quiz_submit(uuid, jsonb) from public;
grant execute on function quiz_submit(uuid, jsonb) to anon, authenticated;

-- ---------------------------------------------------------------------
-- สเตตัสไอเทมตัวอย่าง (ใส่เฉพาะตอนยังไม่มีไอเทมชิ้นไหนมีสเตตัส · ครูแก้ได้ที่แท็บตกแต่ง)
--   หมวก→ปัญญา · ชุด→ขยัน · เอฟเฟค→พลังโจมตี · สัตว์เลี้ยง→โชค · กรอบ→ขยัน · พื้นหลัง→โชค · ไอเทมถือ→สลับปัญญา/พลัง · ฉายา→ไม่มี
--   ค่า: N=1 R=1 SR=2 SSR=3 (SSR ได้เพิ่ม +1 อีกด้านหนึ่ง)
-- ---------------------------------------------------------------------
do $$
begin
  if exists (select 1 from decor_items where st_int + st_dil + st_str + st_luk > 0) then return; end if;
  update decor_items d set
    st_int = case when d.slot = 'hat' or (d.slot = 'item' and d.sort % 2 = 1) then v.x else 0 end,
    st_dil = case when d.slot in ('outfit', 'frame') then v.x else 0 end,
    st_str = case when d.slot = 'fx' or (d.slot = 'item' and d.sort % 2 = 0) then v.x else 0 end,
    st_luk = case when d.slot in ('pet', 'bg') then v.x else 0 end
  from (select id, case rarity when 'N' then 1 when 'R' then 1 when 'SR' then 2 else 3 end as x from decor_items) v
  where v.id = d.id and d.slot <> 'title';
  -- SSR: โบนัสด้านรอง +1
  update decor_items set
    st_dil = st_dil + case when slot in ('hat', 'fx', 'item', 'pet', 'bg') then 1 else 0 end,
    st_luk = st_luk + case when slot in ('outfit', 'frame') then 1 else 0 end
   where rarity = 'SSR' and slot <> 'title';
end $$;
-- รอบที่ 10: ภาพเหรียญรางวัลของ Achievement (รันซ้ำได้)
alter table achievements add column if not exists image text;
update achievements set image = 'assets/medals/' || key || '.png' where image is null and key in
  ('present_5','present_20','streak_5','streak_10','ontime_3','ontime_10','quest_5','quest_20','gacha_10','level_5','level_10');
-- รอบที่ 11: ชุดใหม่ 3 แบบ (เสื้อกาวน์ / อัศวิน / ชุดไทย) + ไอเทมถือใหม่ 12 ชิ้น (รันซ้ำได้ — เพิ่มเฉพาะที่ยังไม่มี)
-- ภาพชุด: web/assets/chars/<คลาส>_<labcoat|knight|thai>.png · ภาพไอเทม: web/assets/items/*.png
-- ค่าสเตตัสของแต่ละชิ้นตั้งไว้ในไฟล์นี้ (ครูแก้ได้ที่แท็บ "ตกแต่ง")
insert into decor_items (slot, key, name, emoji, rarity, price, sort, image, st_int, st_dil, st_str, st_luk)
select v.* from (values
  ('outfit','labcoat','ชุดเสื้อกาวน์นักเคมี','🥼','N',150,3,null,1,1,0,0),
  ('outfit','knight','ชุดอัศวินเคมี','🛡️','R',320,4,null,0,1,2,0),
  ('outfit','thai','ชุดไทยลายทอง','🪷','SR',null,5,null,0,2,0,1),
  ('item','img','คัมภีร์ตารางธาตุ','📜','N',80,7,'assets/items/scroll.png',1,0,0,0),
  ('item','img','แว่นขยายทองคำ','🔍','N',90,8,'assets/items/magnifier.png',1,0,0,0),
  ('item','img','ชั้นหลอดทดลอง','🧫','R',130,9,'assets/items/rack.png',1,0,0,1),
  ('item','img','หนังสือเวทอะตอม','📖','R',180,10,'assets/items/spellbook.png',2,0,0,0),
  ('item','img','ขวดกลมประกายฟ้า','⚗️','R',140,11,'assets/items/flask.png',0,1,0,1),
  ('item','img','ดาบหลอดแก้ว','🗡️','R',220,12,'assets/items/sword.png',0,0,2,0),
  ('item','img','โล่ตราขวดแล็บ','🛡️','R',220,13,'assets/items/shield.png',0,2,1,0),
  ('item','img','ไม้เท้าเกลียวดีเอ็นเอ','🧬','SR',null,14,'assets/items/dnastaff.png',2,0,0,1),
  ('item','img','จรวดจิ๋ว','🚀','SR',null,15,'assets/items/rocket.png',0,0,2,1),
  ('item','img','ถ้วยรางวัลทองคำ','🏆','SR',null,16,'assets/items/trophy.png',0,2,1,0),
  ('item','img','คบไฟตะเกียงน้ำเงิน','🔥','SR',null,17,'assets/items/torch.png',0,0,3,0),
  ('item','img','คทาสายฟ้าม่วง','⚡','SSR',null,18,'assets/items/scepter.png',1,0,3,1)
) v(slot,key,name,emoji,rarity,price,sort,image,st_int,st_dil,st_str,st_luk)
where not exists (select 1 from decor_items d where d.slot = v.slot and d.name = v.name);

-- เข้ากาชา: ชิ้นที่ไม่ขายในร้าน (SR/SSR) + ชุดอัศวิน
insert into gacha_items (name, rarity, kind, value, emoji, weight, decor_id)
select d.name, d.rarity, 'decor', 0, d.emoji, case d.rarity when 'N' then 3 when 'R' then 2 else 1 end, d.id
  from decor_items d
 where d.name in ('ชุดไทยลายทอง','ชุดอัศวินเคมี','ไม้เท้าเกลียวดีเอ็นเอ','จรวดจิ๋ว','ถ้วยรางวัลทองคำ','คบไฟตะเกียงน้ำเงิน','คทาสายฟ้าม่วง')
   and not exists (select 1 from gacha_items g where g.decor_id = d.id);
-- รอบที่ 12: ฉายาปั่นๆ พร้อมความสามารถ + ชุดปั่นๆ 3 แบบ (เป็ดยาง / ไดโนเสาร์ / แมวส้ม) (รันซ้ำได้)
-- ความสามารถของฉายา = ค่าสเตตัส (ปัญญา/ขยัน/พลัง/โชค) + โบนัสเหรียญ % (st_coin) + ข้อความอธิบาย (ability)
--   ปัญญา +1 EXP/ควิซ ต่อ 2 แต้ม · ขยัน +1% EXP · พลัง +3% ดาเมจบอส · โชค +3% โอกาส SR/SSR · โบนัสเหรียญ +N% จากเช็คชื่อ/ส่งงาน/เควส
-- ครูแก้ค่า/ข้อความได้ที่แท็บ "ตกแต่ง"

-- ฉายาเดิม: ใส่ความสามารถให้ (เฉพาะที่ยังไม่มี)
update decor_items set st_int = 1, st_coin = 0, ability = 'อ่านเยอะ ฉลาดขึ้นนิดๆ' where slot='title' and name='หนอนตำรา' and ability is null;
update decor_items set st_int = 1, st_dil = 1, ability = 'คำนวณโมลแม่นขึ้น' where slot='title' and name='ผู้พิชิตโมล' and ability is null;
update decor_items set st_dil = 1, st_str = 1, ability = 'พลังคาร์บอนสายยาว' where slot='title' and name='ราชาออร์แกนิก' and ability is null;
update decor_items set st_int = 2, st_luk = 1, st_coin = 3, ability = 'เวทธาตุเสกเหรียญเพิ่ม +3%' where slot='title' and name='จอมเวทธาตุ' and ability is null;
update decor_items set st_int = 2, st_dil = 2, st_str = 1, st_luk = 1, st_coin = 5, ability = 'ตำนานแห่งห้องแล็บ ทุกด้านเก่งขึ้น' where slot='title' and name='ตำนานห้องแล็บ' and ability is null;

insert into decor_items (slot, key, name, emoji, rarity, price, sort, st_int, st_dil, st_str, st_luk, st_coin, ability)
select v.* from (values
  ('title','text','ผู้ถือโมลไม่ถือกฎ','🧂','N',60,10,0,1,0,0,0,'ขยันแบบงงๆ แต่ได้ผล'),
  ('title','text','เจ้าแห่งการลืมสมุด','📓','N',60,11,0,0,0,1,0,'ลืมสมุดแต่โชคดีตลอด'),
  ('title','text','ง่วงแต่ยังมา','😪','N',70,12,0,2,0,0,0,'มาครบทุกคาบแม้ตาจะปิด'),
  ('title','text','คุณชายนอนหลับในคาบ','🛌','N',70,13,1,0,0,0,2,'ฝันถึงสูตรเคมี เหรียญเข้า +2%'),
  ('title','text','นักล่าเศษเหรียญ','🪙','R',140,14,0,0,0,1,4,'เก็บเหรียญเก่งขึ้น +4%'),
  ('title','text','มือบอนแตะหลอดทดลอง','🧪','R',160,15,1,0,2,0,0,'ซนแล้วดาเมจแรงขึ้น'),
  ('title','text','ตำรวจจับโมล','🚓','R',160,16,2,1,0,0,0,'เห็นทุกจุดผิดในสมการ'),
  ('title','text','ขวดแตกแต่ไม่ท้อ','🍶','R',150,17,0,2,1,0,0,'ล้มแล้วลุกใหม่ ขยันขึ้น'),
  ('title','text','แมวทำหลอดตก','😼','R',180,18,0,0,1,2,0,'ทำของตกแต่ได้ของดี'),
  ('title','text','พ่อค้าเหรียญเรืองแสง','💰','SR',null,19,0,1,0,1,8,'ขายเก่ง เหรียญเพิ่ม +8%'),
  ('title','text','ผู้บันทึก "ส่งแล้วครับ"','📮','SR',null,20,0,3,0,0,3,'ส่งงานไวสุด ขยัน +3'),
  ('title','text','ราชันย์ลูกเต๋าลอยฟ้า','🎲','SR',null,21,0,0,1,3,0,'โชคล้นฟ้า SR ออกง่ายขึ้น'),
  ('title','text','เจ้าพ่อบอสฟาร์ม','👹','SR',null,22,0,0,3,1,0,'ซัดบอสเจ็บแสบ'),
  ('title','text','สมองกลวงแต่ใจกล้า','🧠','SSR',null,23,1,1,3,1,0,'ไม่คิดมาก ดาเมจสุดโหด'),
  ('title','text','ผู้ถูกเลือกโดยพรีเมียมกาชา','🌈','SSR',null,24,0,0,1,4,6,'โชคสุดจัด เหรียญเพิ่ม +6%'),
  ('title','text','มหาเทพขาประจำหน้าห้อง','👑','SSR',null,25,2,2,2,2,6,'ทุกด้านพุ่ง ครูเห็นหน้าทุกวัน')
) v(slot,key,name,emoji,rarity,price,sort,st_int,st_dil,st_str,st_luk,st_coin,ability)
where not exists (select 1 from decor_items d where d.slot='title' and d.name=v.name);

-- ชุดปั่นๆ (ภาพ: web/assets/chars/<คลาส>_duck|dino|cat.png)
insert into decor_items (slot, key, name, emoji, rarity, price, sort, st_int, st_dil, st_str, st_luk, st_coin, ability)
select v.* from (values
  ('outfit','duck','ชุดเป็ดยางตัวป่วน','🦆','R',280,6,0,1,0,2,3,'ลอยน้ำได้ โชคดี เหรียญ +3%'),
  ('outfit','dino','ชุดไดโนเสาร์ตัวจิ๋ว','🦖','SR',null,7,0,0,3,1,0,'ก้าวร้าวน่ารัก ดาเมจบอสแรง'),
  ('outfit','cat','ชุดแมวส้มจอมเกียจคร้าน','🐱','R',280,8,1,0,0,2,4,'ขี้เกียจแต่เหรียญเข้า +4%')
) v(slot,key,name,emoji,rarity,price,sort,st_int,st_dil,st_str,st_luk,st_coin,ability)
where not exists (select 1 from decor_items d where d.slot='outfit' and d.name=v.name);

-- เข้ากาชา: ฉายา/ชุดที่ไม่ขายในร้าน
insert into gacha_items (name, rarity, kind, value, emoji, weight, decor_id)
select d.name, d.rarity, 'decor', 0, d.emoji, case d.rarity when 'N' then 3 when 'R' then 2 else 1 end, d.id
  from decor_items d
 where d.slot in ('title','outfit') and d.price is null and d.rarity in ('SR','SSR')
   and not exists (select 1 from gacha_items g where g.decor_id = d.id);
-- =====================================================================
-- Chemistria · รอบที่ 13: บอร์ดกระดานสาธารณะ (ประกาศครู + โพสต์นักเรียน) (รันซ้ำได้)
--  · ครู (แอดมิน) โพสต์ได้ทั้งห้องเดียวหรือทุกห้อง ปักหมุด/ซ่อน/ลบได้
--  · นักเรียนโพสต์ได้ในห้องตัวเอง (ไม่เกิน 3 โพสต์/วัน, ไม่เกิน 500 ตัวอักษร) ลบโพสต์ตัวเองได้
--  · นักเรียนเห็นประกาศของห้องตัวเอง + ประกาศทุกห้อง
-- =====================================================================
create table if not exists board_posts (
  id uuid primary key default gen_random_uuid(),
  class_id uuid references classes(id) on delete cascade,          -- null = ทุกห้อง
  author_kind text not null default 'student' check (author_kind in ('teacher','student')),
  student_id uuid references students(id) on delete cascade,
  title text,
  body text not null check (char_length(body) between 1 and 1000),
  pinned boolean not null default false,
  hidden boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists board_posts_idx on board_posts (class_id, created_at desc);
alter table students add column if not exists board_seen timestamptz;

alter table board_posts enable row level security;
drop policy if exists teacher_all on board_posts;
create policy teacher_all on board_posts for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on board_posts from anon;
grant select, insert, update, delete on board_posts to authenticated;

-- รายการบอร์ดสำหรับนักเรียน + จำนวนที่ยังไม่ได้อ่าน
create or replace function board_list(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); s students%rowtype;
begin
  select * into s from students where id = sid;
  return json_build_object(
    'unread', (select count(*) from board_posts b
                where not b.hidden and (b.class_id is null or b.class_id = s.class_id)
                  and coalesce(b.student_id, '00000000-0000-0000-0000-000000000000'::uuid) <> sid
                  and b.created_at > coalesce(s.board_seen, 'epoch'::timestamptz))::int,
    'posts', (select coalesce(json_agg(x order by x.pinned desc, x.created_at desc), '[]'::json) from (
        select b.id, b.title, b.body, b.pinned, b.created_at, b.author_kind,
               (b.class_id is null) as all_classes, (b.student_id = sid) as mine,
               case when b.author_kind = 'teacher' then 'ครูบุ๊ค' else st.name end as author,
               case when b.author_kind = 'student' then st.char_class end as char_class
          from board_posts b left join students st on st.id = b.student_id
         where not b.hidden and (b.class_id is null or b.class_id = s.class_id)
         order by b.pinned desc, b.created_at desc limit 60) x));
end $$;

create or replace function board_mark_seen(p_token uuid) returns void
language plpgsql security definer set search_path = public as $$
begin update students set board_seen = now() where id = _sid(p_token); end $$;

create or replace function board_post(p_token uuid, p_title text, p_body text) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); s students%rowtype; n int; b text := btrim(coalesce(p_body, '')); nid uuid;
begin
  select * into s from students where id = sid;
  if char_length(b) < 1 then raise exception 'พิมพ์ข้อความก่อนโพสต์'; end if;
  if char_length(b) > 500 then raise exception 'ข้อความยาวเกิน 500 ตัวอักษร'; end if;
  select count(*) into n from board_posts where student_id = sid and (created_at at time zone 'Asia/Bangkok')::date = today_th();
  if n >= 3 then raise exception 'โพสต์ได้วันละ 3 ครั้ง วันนี้ครบแล้ว'; end if;
  insert into board_posts (class_id, author_kind, student_id, title, body)
  values (s.class_id, 'student', sid, nullif(left(btrim(coalesce(p_title, '')), 80), ''), b) returning board_posts.id into nid;
  return json_build_object('ok', true, 'id', nid);
end $$;

create or replace function board_delete(p_token uuid, p_id uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  delete from board_posts where id = p_id and student_id = _sid(p_token) and author_kind = 'student';
  if not found then raise exception 'ลบไม่ได้ (ลบได้เฉพาะโพสต์ของตัวเอง)'; end if;
end $$;

revoke execute on function board_list(uuid), board_mark_seen(uuid), board_post(uuid, text, text), board_delete(uuid, uuid) from public;
grant execute on function board_list(uuid), board_mark_seen(uuid), board_post(uuid, text, text), board_delete(uuid, uuid) to anon, authenticated;

-- ประกาศตัวอย่าง (ใส่ครั้งเดียวตอนบอร์ดยังว่าง)
insert into board_posts (class_id, author_kind, title, body, pinned)
select null, 'teacher', '📢 ยินดีต้อนรับสู่บอร์ดเคมีเรีย', 'ที่นี่คือบอร์ดประกาศของห้อง — ครูจะแปะประกาศสำคัญไว้ด้านบน นักเรียนโพสต์ถามตอบหรือแชร์เทคนิคได้ (วันละ 3 โพสต์) ขอให้ใช้ถ้อยคำสุภาพนะ', true
where not exists (select 1 from board_posts);
-- รอบที่ 14: เลือกเพศตัวละคร (ชาย/หญิง) — ภาพตัวพื้นฐานของแต่ละคลาสมีทั้งสองเพศ (รันซ้ำได้)
--  ว่าง (null) = ใช้หน้าตาเดิมของคลาส · ชุดที่ยังไม่มีภาพของอีกเพศจะแสดงตัวพื้นฐานของเพศนั้นแทน
alter table students add column if not exists gender text;
do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'students_gender_chk') then
    alter table students add constraint students_gender_chk check (gender is null or gender in ('m','f'));
  end if;
end $$;

create or replace function _decor_of(p_sid uuid) returns json
language sql stable security definer set search_path = public as $$
  select (coalesce((select json_object_agg(d.slot, json_build_object('id', d.id, 'key', d.key, 'color', d.color,
           'emoji', d.emoji, 'name', d.name, 'rarity', d.rarity, 'image', d.image))
    from students s
    cross join lateral jsonb_each_text(s.decor) e
    join decor_items d on d.id = e.value::uuid and d.slot = e.key
   where s.id = p_sid), '{}'::json)::jsonb
   || jsonb_build_object('gender', (select gender from students where id = p_sid)))::json
$$;

create or replace function set_gender(p_token uuid, p_gender text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if p_gender is not null and p_gender not in ('m','f') then raise exception 'เพศไม่ถูกต้อง'; end if;
  update students set gender = p_gender where id = _sid(p_token);
end $$;

revoke execute on function _decor_of(uuid) from public, anon, authenticated;
revoke execute on function set_gender(uuid, text) from public;
grant execute on function set_gender(uuid, text) to anon, authenticated;
-- =====================================================================
-- Chemistria · รอบที่ 15: ไอดี GM (ปลดล็อคทุกอย่าง) (รันซ้ำได้)
--  · สร้างห้องลับ "GM" (ไม่โผล่ในรายชื่อห้องหน้าล็อกอิน) + นักเรียนเลขที่ 1 = ไอดี GM แยกจากห้องจริง จึงไม่กระทบอันดับ/บอส/ทีมของห้องไหน
--  · ปลดล็อค: ไอเทมตกแต่งทุกชิ้น · ไอเทมกาชาทุกชิ้น · Achievement ทุกอัน · สิทธิพิเศษทุกอย่าง · EXP/เหรียญสูงสุด (แรงค์สูงสุด) · สเตตัสพื้นฐานเต็ม 10
--  · ครูสร้างที่แอดมิน > ตั้งค่า > “ไอดี GM” โดยตั้ง PIN เอง (ไม่มี PIN ตายตัวในโค้ด) · กดซ้ำเพื่อซิงก์ของใหม่ที่เพิ่มทีหลัง
--  ล็อกอิน: รหัสห้อง GM · เลขที่ 1 · PIN ที่ตั้งไว้
-- =====================================================================
alter table classes add column if not exists hidden boolean not null default false;
alter table students add column if not exists is_gm boolean not null default false;

create or replace function list_classes() returns json
language sql stable security definer set search_path = public as $$
  select coalesce(json_agg(json_build_object('code', code, 'name', name, 'subject', subject_name) order by name), '[]'::json)
  from classes where not hidden
$$;

create or replace function _gm_unlock(p_sid uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  insert into student_decor (student_id, item_id, source) select p_sid, id, 'teacher' from decor_items on conflict do nothing;
  insert into inventory (student_id, item_id, qty) select p_sid, id, 1 from gacha_items on conflict (student_id, item_id) do nothing;
  insert into student_achievements (student_id, achievement_id) select p_sid, id from achievements on conflict do nothing;
  insert into redemptions (student_id, privilege_id, source, status)
    select p_sid, p.id, 'teacher', 'available' from privileges p
     where not exists (select 1 from redemptions r where r.student_id = p_sid and r.privilege_id = p.id);
  update students set
    exp = greatest(exp, coalesce((select max(min_exp) from ch_ranks), 0) + 1000),
    coins = greatest(coins, 999999),
    is_gm = true
  where id = p_sid;
end $$;

create or replace function admin_create_gm(p_pin text) returns json
language plpgsql security definer set search_path = public, extensions as $$
declare cid uuid; sid uuid;
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  if p_pin is null or p_pin !~ '^[0-9]{4,8}$' then raise exception 'PIN ต้องเป็นตัวเลข 4-8 หลัก'; end if;
  select id into cid from classes where code = 'GM';
  if cid is null then
    insert into classes (code, name, subject_name, hidden) values ('GM', '🛠️ GM (ห้องทดสอบ)', 'ห้องทดสอบของครู', true) returning id into cid;
  end if;
  select id into sid from students where class_id = cid and no = 1;
  if sid is null then
    insert into students (class_id, no, name, pin_hash, avatar) values (cid, 1, 'GM ครูบุ๊ค', crypt(p_pin, gen_salt('bf')), '🛠️') returning id into sid;
  else
    update students set pin_hash = crypt(p_pin, gen_salt('bf')), fail_count = 0, locked_until = null where id = sid;
  end if;
  perform _gm_unlock(sid);
  return json_build_object('class_code', 'GM', 'no', 1, 'student_id', sid);
end $$;

-- ซิงก์ของใหม่ให้ไอดี GM (ไม่เปลี่ยน PIN)
create or replace function admin_gm_sync() returns int
language plpgsql security definer set search_path = public as $$
declare sid uuid; n int := 0;
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  for sid in select id from students where is_gm loop perform _gm_unlock(sid); n := n + 1; end loop;
  return n;
end $$;

revoke execute on function _gm_unlock(uuid) from public, anon, authenticated;
revoke execute on function admin_create_gm(text), admin_gm_sync() from public, anon;
grant execute on function admin_create_gm(text), admin_gm_sync() to authenticated;
revoke execute on function list_classes() from public;
grant execute on function list_classes() to anon, authenticated;
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
-- =====================================================================
-- Chemistria · รอบที่ 24: รูปโปรไฟล์ที่นักเรียนอัปโหลดเอง (ครอป/ซูมในเบราว์เซอร์ก่อน แล้วเก็บเป็น JPEG ขนาดเล็กใน students.avatar) — รันซ้ำได้
--  · ครูปิดฟีเจอร์ได้ที่ตั้งค่า "allow_student_photo" = 0 · ครูลบรูปรายคนได้ในแท็บนักเรียน
-- =====================================================================
insert into app_settings (key, value) values ('allow_student_photo', '1') on conflict (key) do nothing;

create or replace function set_photo(p_token uuid, p_data text) returns void
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  if p_data is null or p_data = '' then update students set avatar = '🧪' where id = sid; return; end if;
  if _setting_int('allow_student_photo', 1) = 0 then raise exception 'ครูปิดการใช้รูปโปรไฟล์ส่วนตัวไว้'; end if;
  if length(p_data) > 30000 or p_data !~ '^data:image/jpeg;base64,[A-Za-z0-9+/=]+$' then raise exception 'รูปไม่ถูกต้องหรือไฟล์ใหญ่เกินไป'; end if;
  update students set avatar = p_data where id = sid;
end $$;
revoke execute on function set_photo(uuid, text) from public;
grant execute on function set_photo(uuid, text) to anon, authenticated;
-- =====================================================================
-- Chemistria · รอบที่ 25: คลังควิซเพิ่ม 131 ข้อ (รันซ้ำได้ — ข้ามข้อที่มีคำถามเดียวกันอยู่แล้ว)
-- หัวข้อ: ตารางธาตุ · โครงสร้างอะตอม · พันธะเคมี · ปริมาณสารสัมพันธ์ · กรด-เบส · ปฏิกิริยาเคมี · ไฟฟ้าเคมี · เคมีอินทรีย์ · พอลิเมอร์ · สมบัติของสาร · เคมีในชีวิตประจำวัน · ความปลอดภัย
-- answer: 0=ก 1=ข 2=ค 3=ง · แก้ไข/ปิดข้อ/เพิ่มเองได้ที่หน้าแอดมิน → เกม → คลังคำถาม
-- =====================================================================
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select v.* from (values
  ('ตารางธาตุ','สัญลักษณ์ของธาตุโพแทสเซียมคือข้อใด','P','K','Po','Pt',1,'โพแทสเซียมมาจากภาษาละติน Kalium จึงใช้ K'),
  ('ตารางธาตุ','สัญลักษณ์ของทองคำคือข้อใด','Au','Ag','Go','Gd',0,'Au มาจากภาษาละติน Aurum'),
  ('ตารางธาตุ','สัญลักษณ์ของเงินคือข้อใด','Au','Si','Sn','Ag',3,'Ag มาจากภาษาละติน Argentum'),
  ('ตารางธาตุ','ธาตุที่มีสัญลักษณ์ Cu คือธาตุใด','คาร์บอน','แคลเซียม','ทองแดง','โคบอลต์',2,'Cu มาจาก Cuprum ซึ่งคือทองแดง'),
  ('ตารางธาตุ','ธาตุหมู่ 2 เรียกว่าอะไร','โลหะแอลคาไล','โลหะแอลคาไลน์เอิร์ท','ฮาโลเจน','แก๊สเฉื่อย',1,'หมู่ 1 = แอลคาไล, หมู่ 2 = แอลคาไลน์เอิร์ท'),
  ('ตารางธาตุ','แก๊สชนิดใดเบาที่สุดในบรรดาธาตุทั้งหมด','ไฮโดรเจน','ฮีเลียม','ออกซิเจน','ไนโตรเจน',0,'ไฮโดรเจนมีมวลอะตอมน้อยที่สุด'),
  ('ตารางธาตุ','ธาตุที่มีสัญลักษณ์ Ca คือธาตุใด','คาร์บอน','แคดเมียม','ซีเซียม','แคลเซียม',3,'แคลเซียมพบมากในกระดูกและฟัน'),
  ('ตารางธาตุ','ธาตุใดมีมากที่สุดในอากาศ (โดยปริมาตร)','ออกซิเจน','อาร์กอน','ไนโตรเจน','ไฮโดรเจน',2,'อากาศมีไนโตรเจนประมาณ 78%'),
  ('ตารางธาตุ','ธาตุใดจัดเป็นธาตุกึ่งโลหะ','โซเดียม','ซิลิคอน','คลอรีน','ทองแดง',1,'ซิลิคอนมีสมบัติกึ่งโลหะ ใช้ทำชิปคอมพิวเตอร์'),
  ('ตารางธาตุ','ตารางธาตุในปัจจุบันเรียงธาตุตามอะไร','เลขอะตอมจากน้อยไปมาก','มวลอะตอม','ความหนาแน่น','วันที่ค้นพบ',0,'โมสลีย์เสนอให้เรียงตามเลขอะตอม'),
  ('ตารางธาตุ','ธาตุใดนำไฟฟ้าได้ดีที่สุด','เหล็ก','ตะกั่ว','ปรอท','เงิน',3,'เงินนำไฟฟ้าได้ดีที่สุด รองลงมาคือทองแดง'),
  ('ตารางธาตุ','ธาตุฮาโลเจนชนิดใดเป็นของเหลวที่อุณหภูมิห้อง','คลอรีน','ฟลูออรีน','โบรมีน','ไอโอดีน',2,'โบรมีนเป็นของเหลวสีน้ำตาลแดง'),
  ('ตารางธาตุ','แถวแนวนอนในตารางธาตุเรียกว่าอะไร','หมู่','คาบ','อนุกรม','กลุ่มธาตุแทรนซิชัน',1,'แถวแนวนอน = คาบ, แถวแนวตั้ง = หมู่'),
  ('ตารางธาตุ','ธาตุที่อยู่ในหมู่เดียวกันมีลักษณะอย่างไร','สมบัติทางเคมีคล้ายกัน','มีเลขอะตอมเท่ากัน','มีมวลเท่ากัน','มีจำนวนชั้นอิเล็กตรอนเท่ากัน',0,'เพราะมีเวเลนซ์อิเล็กตรอนเท่ากัน'),
  ('ตารางธาตุ','ในหมู่เดียวกัน จากบนลงล่าง ขนาดอะตอมโดยทั่วไปเป็นอย่างไร','เล็กลง','เท่าเดิม','ไม่แน่นอน','ใหญ่ขึ้น',3,'จำนวนระดับพลังงานเพิ่มขึ้น อะตอมจึงใหญ่ขึ้น'),
  ('โครงสร้างอะตอม','อนุภาคใดในอะตอมไม่มีประจุไฟฟ้า','โปรตอน','อิเล็กตรอน','นิวตรอน','ไอออน',2,'นิวตรอนเป็นกลางทางไฟฟ้า'),
  ('โครงสร้างอะตอม','นักวิทยาศาสตร์คนใดทดลองยิงอนุภาคแอลฟาใส่แผ่นทองคำ จนพบนิวเคลียส','ทอมสัน','รัทเทอร์ฟอร์ด','ดอลตัน','เมนเดเลเยฟ',1,'รัทเทอร์ฟอร์ดพบว่าอะตอมมีนิวเคลียสเล็กและหนาแน่น'),
  ('โครงสร้างอะตอม','ผู้ค้นพบอิเล็กตรอนคือใคร','เจ.เจ. ทอมสัน','ชาดวิก','ดอลตัน','โบร์',0,'ทอมสันค้นพบอิเล็กตรอนจากหลอดรังสีแคโทด'),
  ('โครงสร้างอะตอม','เลขมวลหมายถึงอะไร','จำนวนโปรตอน','จำนวนอิเล็กตรอน','จำนวนนิวตรอน','ผลรวมของโปรตอนและนิวตรอน',3,'เลขมวล = p + n'),
  ('โครงสร้างอะตอม','อะตอมโซเดียมมีเลขอะตอม 11 เลขมวล 23 มีนิวตรอนกี่ตัว','11','23','12','34',2,'นิวตรอน = 23 − 11 = 12'),
  ('โครงสร้างอะตอม','ไอออน Mg²⁺ (เลขอะตอมของ Mg = 12) มีอิเล็กตรอนกี่ตัว','12','10','14','2',1,'เสีย 2 อิเล็กตรอน จึงเหลือ 12 − 2 = 10'),
  ('โครงสร้างอะตอม','ไอออนลบเกิดจากอะตอมที่ทำอะไร','รับอิเล็กตรอน','เสียอิเล็กตรอน','รับโปรตอน','เสียนิวตรอน',0,'รับอิเล็กตรอนเพิ่มทำให้มีประจุลบ'),
  ('โครงสร้างอะตอม','ระดับพลังงานชั้นที่ 2 (n = 2) รับอิเล็กตรอนได้สูงสุดกี่ตัว','2','18','32','8',3,'สูตร 2n² = 2 × 4 = 8'),
  ('โครงสร้างอะตอม','การจัดเรียงอิเล็กตรอนของโซเดียม (เลขอะตอม 11) คือข้อใด','2, 8, 8','2, 9','2, 8, 1','8, 3',2,'ชั้นแรก 2 ชั้นสอง 8 เหลือ 1 ในชั้นสาม'),
  ('โครงสร้างอะตอม','ไอโซโทป C-12 และ C-14 ต่างกันที่อะไร','จำนวนโปรตอน','จำนวนนิวตรอน','จำนวนอิเล็กตรอน','เลขอะตอม',1,'ไอโซโทปมีโปรตอนเท่ากัน แต่นิวตรอนต่างกัน'),
  ('โครงสร้างอะตอม','แมกนีเซียม (เลขอะตอม 12) มีเวเลนซ์อิเล็กตรอนกี่ตัว','2','1','12','8',0,'การจัดเรียง 2, 8, 2 ชั้นนอกสุดมี 2'),
  ('พันธะเคมี','พันธะระหว่างโลหะกับอโลหะมักเป็นพันธะชนิดใด','โคเวเลนต์','ไฮโดรเจน','โลหะ','ไอออนิก',3,'โลหะให้อิเล็กตรอน อโลหะรับ เกิดไอออนยึดกัน'),
  ('พันธะเคมี','พันธะระหว่างอะตอมอโลหะกับอโลหะเป็นพันธะชนิดใดโดยทั่วไป','ไอออนิก','โลหะ','โคเวเลนต์','ไฮโดรเจน',2,'อโลหะใช้อิเล็กตรอนร่วมกัน'),
  ('พันธะเคมี','พันธะโลหะเกิดจากอะไร','การถ่ายโอนอิเล็กตรอนครบหนึ่งคู่','แรงดึงดูดระหว่างไอออนบวกกับ “ทะเลอิเล็กตรอน”','การใช้อิเล็กตรอนร่วมกันหนึ่งคู่','แรงระหว่างโมเลกุลมีขั้ว',1,'อิเล็กตรอนเคลื่อนที่ได้อิสระ โลหะจึงนำไฟฟ้า'),
  ('พันธะเคมี','โมเลกุล N₂ มีพันธะระหว่างอะตอมแบบใด','พันธะสาม','พันธะเดี่ยว','พันธะคู่','ไม่มีพันธะ',0,'N≡N เป็นพันธะสาม จึงเสถียรมาก'),
  ('พันธะเคมี','โมเลกุลใดมีรูปร่างเป็นเส้นตรง','H₂O','NH₃','CH₄','CO₂',3,'CO₂ มีโครงสร้าง O=C=O เป็นเส้นตรง'),
  ('พันธะเคมี','โมเลกุลมีเทน (CH₄) มีรูปร่างเป็นอย่างไร','พีระมิดฐานสามเหลี่ยม','เส้นตรง','ทรงสี่หน้า','มุมงอ',2,'คาร์บอนมี 4 พันธะ ผลักกันเป็นทรงสี่หน้า'),
  ('พันธะเคมี','โมเลกุลแอมโมเนีย (NH₃) มีรูปร่างเป็นอย่างไร','ทรงสี่หน้า','พีระมิดฐานสามเหลี่ยม','เส้นตรง','มุมงอ',1,'มี 3 พันธะและ 1 คู่โดดเดี่ยว'),
  ('พันธะเคมี','แรงยึดเหนี่ยวระหว่างโมเลกุลของน้ำที่เด่นที่สุดคือข้อใด','พันธะไฮโดรเจน','พันธะไอออนิก','พันธะโลหะ','พันธะโคเวเลนต์ร่วมแบบสาม',0,'ทำให้น้ำมีจุดเดือดสูงกว่าที่คาด'),
  ('พันธะเคมี','ข้อใดเป็นโมเลกุลมีขั้ว','CO₂','CH₄','N₂','H₂O',3,'น้ำมีรูปร่างงอ ทำให้เกิดขั้วไฟฟ้า'),
  ('พันธะเคมี','สารประกอบไอออนิกนำไฟฟ้าได้ในสถานะใด','ของแข็ง','ทุกสถานะ','หลอมเหลวหรือละลายน้ำ','ไม่นำไฟฟ้าเลย',2,'ไอออนเคลื่อนที่ได้เมื่อหลอมเหลวหรือละลายน้ำ'),
  ('พันธะเคมี','ข้อใดมีจุดหลอมเหลวสูงที่สุด','น้ำตาลทราย','โซเดียมคลอไรด์','แนฟทาลีน','น้ำแข็ง',1,'NaCl เป็นผลึกไอออนิก จุดหลอมเหลวประมาณ 801 °C'),
  ('ปริมาณสารสัมพันธ์','เลขอาโวกาโดรมีค่าประมาณเท่าใด','6.02 × 10²³','3.00 × 10⁸','1.60 × 10⁻¹⁹','9.8',0,'1 โมลมี 6.02 × 10²³ อนุภาค'),
  ('ปริมาณสารสัมพันธ์','มวลโมเลกุลของมีเทน CH₄ (C = 12, H = 1) เท่ากับเท่าใด','13','14','12','16',3,'12 + 4(1) = 16'),
  ('ปริมาณสารสัมพันธ์','มวลสูตรของ NaCl (Na = 23, Cl = 35.5) เท่ากับเท่าใด','23','35.5','58.5','12.5',2,'23 + 35.5 = 58.5'),
  ('ปริมาณสารสัมพันธ์','NaOH หนัก 4 กรัม (มวลโมลาร์ 40) เป็นกี่โมล','0.4','0.1','1','10',1,'โมล = 4 ÷ 40 = 0.1'),
  ('ปริมาณสารสัมพันธ์','CO₂ หนัก 22 กรัม (มวลโมลาร์ 44) เป็นกี่โมล','0.5','2','1','44',0,'โมล = 22 ÷ 44 = 0.5'),
  ('ปริมาณสารสัมพันธ์','น้ำ 36 กรัม (มวลโมลาร์ 18) เป็นกี่โมล','1','18','0.5','2',3,'โมล = 36 ÷ 18 = 2'),
  ('ปริมาณสารสัมพันธ์','แก๊สอุดมคติ 2 โมลที่ STP มีปริมาตรกี่ dm³','22.4','11.2','44.8','2',2,'1 โมลที่ STP = 22.4 dm³ จึง 2 โมล = 44.8'),
  ('ปริมาณสารสัมพันธ์','จากสมการ 2H₂ + O₂ → 2H₂O ถ้ามี H₂ 4 โมล ต้องใช้ O₂ กี่โมลพอดี','4','2','1','8',1,'อัตราส่วน H₂ : O₂ = 2 : 1'),
  ('ปริมาณสารสัมพันธ์','สารกำหนดปริมาณ (limiting reactant) คืออะไร','สารตั้งต้นที่หมดก่อน','สารตั้งต้นที่เหลือหลังเกิดปฏิกิริยา','ตัวเร่งปฏิกิริยา','ผลิตภัณฑ์หลัก',0,'สารที่หมดก่อนกำหนดปริมาณผลิตภัณฑ์ที่เกิดได้'),
  ('ปริมาณสารสัมพันธ์','สารละลาย NaCl 0.5 โมล ในสารละลาย 2 dm³ มีความเข้มข้นกี่โมล/dm³','1','4','2.5','0.25',3,'M = 0.5 ÷ 2 = 0.25'),
  ('ปริมาณสารสัมพันธ์','สูตรเอมพิริคัลของกลูโคส C₆H₁₂O₆ คือข้อใด','C₆H₁₂O₆','CHO','CH₂O','C₂H₄O₂',2,'หารอัตราส่วน 6 : 12 : 6 ด้วย 6 ได้ 1 : 2 : 1'),
  ('ปริมาณสารสัมพันธ์','ธาตุออกซิเจนใน H₂O (H = 1, O = 16) มีร้อยละโดยมวลประมาณเท่าใด','11.1','88.9','50','16',1,'16 ÷ 18 × 100 ≈ 88.9'),
  ('ปริมาณสารสัมพันธ์','น้ำ 1 โมล มีอะตอมของไฮโดรเจนประมาณกี่อะตอม','1.204 × 10²⁴','6.02 × 10²³','1.806 × 10²⁴','2',0,'H₂O 1 โมลมี H 2 โมล = 2 × 6.02 × 10²³'),
  ('กรด-เบส','ข้อใดเป็นเบสแก่','CH₃COOH','NH₃','H₂CO₃','NaOH',3,'NaOH แตกตัวในน้ำได้เกือบสมบูรณ์'),
  ('กรด-เบส','สารละลายที่มี pH = 12 มีสมบัติอย่างไร','เป็นกรด','เป็นกลาง','เป็นเบส','เป็นกรดแก่',2,'pH มากกว่า 7 เป็นเบส'),
  ('กรด-เบส','pH ลดลง 1 หน่วย ความเข้มข้นของ H⁺ เปลี่ยนไปกี่เท่า','เพิ่มขึ้น 2 เท่า','เพิ่มขึ้น 10 เท่า','ลดลง 10 เท่า','ไม่เปลี่ยน',1,'pH = −log[H⁺] เป็นสเกลลอการิทึมฐาน 10'),
  ('กรด-เบส','HCl 0.01 โมล/dm³ มี pH เท่าใด','2','1','12','0.01',0,'[H⁺] = 10⁻² จึง pH = 2'),
  ('กรด-เบส','ฟีนอล์ฟทาลีนให้สีใดในสารละลายเบส','ไม่มีสี','เหลือง','น้ำเงิน','ชมพู',3,'ในกรดไม่มีสี ในเบสเป็นสีชมพู'),
  ('กรด-เบส','กรดทำให้กระดาษลิตมัสสีน้ำเงินเปลี่ยนเป็นสีใด','น้ำเงินเข้มขึ้น','เขียว','แดง','ไม่เปลี่ยน',2,'กรดเปลี่ยนลิตมัสน้ำเงินเป็นแดง'),
  ('กรด-เบส','สังกะสีทำปฏิกิริยากับกรดไฮโดรคลอริก ได้แก๊สใด','ออกซิเจน','ไฮโดรเจน','คาร์บอนไดออกไซด์','คลอรีน',1,'Zn + 2HCl → ZnCl₂ + H₂'),
  ('กรด-เบส','กรดทำปฏิกิริยากับหินปูน (CaCO₃) แล้วเกิดแก๊สใด','คาร์บอนไดออกไซด์','ไฮโดรเจน','ออกซิเจน','ไนโตรเจน',0,'คาร์บอเนตกับกรดให้ CO₂ น้ำ และเกลือ'),
  ('กรด-เบส','กรดในน้ำส้มสายชูคือกรดใด','กรดซิตริก','กรดซัลฟิวริก','กรดไนตริก','กรดแอซีติก',3,'น้ำส้มสายชูมีกรดแอซีติกประมาณ 4–7%'),
  ('กรด-เบส','กรดที่พบมากในมะนาวคือกรดใด','กรดแอซีติก','กรดแลกติก','กรดซิตริก','กรดไฮโดรคลอริก',2,'รสเปรี้ยวของผลไม้ตระกูลส้มมาจากกรดซิตริก'),
  ('กรด-เบส','โซดาไฟมีชื่อทางเคมีว่าอะไร','โซเดียมคลอไรด์','โซเดียมไฮดรอกไซด์','โซเดียมไฮโดรเจนคาร์บอเนต','แคลเซียมไฮดรอกไซด์',1,'โซดาไฟคือ NaOH'),
  ('กรด-เบส','การไทเทรตใช้เพื่อหาอะไร','ความเข้มข้นของสารละลาย','มวลอะตอม','จุดเดือด','ความหนาแน่น',0,'ใช้สารละลายมาตรฐานทำปฏิกิริยาพอดีกับสารที่ไม่ทราบความเข้มข้น'),
  ('กรด-เบส','ยาลดกรดในกระเพาะอาหารมีสมบัติอย่างไร','เป็นกรดแก่','เป็นกลาง','เป็นเบสแก่มาก','เป็นเบสอ่อน',3,'เบสอ่อนสะเทินกรดส่วนเกินในกระเพาะ'),
  ('ปฏิกิริยาเคมี','กฎทรงมวลกล่าวว่าอย่างไร','มวลเพิ่มขึ้นเสมอ','มวลลดลงเสมอ','มวลรวมก่อนและหลังปฏิกิริยาเท่ากัน','มวลขึ้นกับอุณหภูมิ',2,'สสารไม่สูญหายและไม่เกิดขึ้นใหม่ในปฏิกิริยาเคมี'),
  ('ปฏิกิริยาเคมี','ปฏิกิริยาคายความร้อนทำให้สิ่งแวดล้อมเป็นอย่างไร','อุณหภูมิต่ำลง','อุณหภูมิสูงขึ้น','ไม่เปลี่ยน','เกิดสุญญากาศ',1,'ระบบคายความร้อนออกมาสู่สิ่งแวดล้อม'),
  ('ปฏิกิริยาเคมี','การเผาไหม้ไฮโดรคาร์บอนอย่างสมบูรณ์ได้ผลิตภัณฑ์ใด','คาร์บอนไดออกไซด์และน้ำ','คาร์บอนมอนอกไซด์และไฮโดรเจน','เขม่าและน้ำ','ออกซิเจนและน้ำ',0,'การเผาไหม้สมบูรณ์ได้ CO₂ + H₂O'),
  ('ปฏิกิริยาเคมี','การเกิดสนิมของเหล็กเป็นปฏิกิริยาประเภทใด','การระเหิด','สะเทิน','การสลายตัวด้วยความร้อน','ออกซิเดชัน',3,'เหล็กถูกออกซิไดซ์โดยออกซิเจนและน้ำ'),
  ('ปฏิกิริยาเคมี','ตัวเร่งปฏิกิริยามีบทบาทอย่างไร','ถูกใช้จนหมดในปฏิกิริยา','เพิ่มปริมาณผลิตภัณฑ์รวมให้มากขึ้น','เพิ่มอัตราเร็วโดยไม่ถูกใช้หมด','ทำให้ปฏิกิริยาช้าลง',2,'ตัวเร่งลดพลังงานก่อกัมมันต์'),
  ('ปฏิกิริยาเคมี','เมื่ออุณหภูมิสูงขึ้น อัตราเร็วของปฏิกิริยาโดยทั่วไปเป็นอย่างไร','ลดลง','เพิ่มขึ้น','เท่าเดิม','หยุด',1,'อนุภาคชนกันบ่อยและแรงขึ้น'),
  ('ปฏิกิริยาเคมี','ที่ภาวะสมดุลเคมี ข้อใดถูกต้อง','อัตราปฏิกิริยาไปข้างหน้าเท่ากับย้อนกลับ','ปฏิกิริยาหยุดเกิดขึ้น','สารตั้งต้นหมดไป','ผลิตภัณฑ์หมดไป',0,'สมดุลเคมีเป็นสมดุลไดนามิก'),
  ('ปฏิกิริยาเคมี','ปฏิกิริยา A + B → AB เป็นปฏิกิริยาประเภทใด','การสลายตัว','การแทนที่เดี่ยว','การแทนที่คู่','การรวมตัว',3,'สารตั้งต้นหลายตัวรวมเป็นผลิตภัณฑ์เดียว'),
  ('ปฏิกิริยาเคมี','ปฏิกิริยา 2H₂O₂ → 2H₂O + O₂ เป็นปฏิกิริยาประเภทใด','การรวมตัว','สะเทิน','การสลายตัว','การตกตะกอน',2,'สารตั้งต้นตัวเดียวแตกเป็นหลายสาร'),
  ('ปฏิกิริยาเคมี','ปฏิกิริยา Zn + CuSO₄ → ZnSO₄ + Cu เป็นปฏิกิริยาประเภทใด','การแทนที่คู่','การแทนที่เดี่ยว','การรวมตัว','การสลายตัว',1,'สังกะสีแทนที่ทองแดงในสารประกอบ'),
  ('ปฏิกิริยาเคมี','ถุงเย็นสำเร็จรูปเย็นเพราะเกิดปฏิกิริยาแบบใด','ดูดความร้อน','คายความร้อน','เผาไหม้','รวมตัวกับออกซิเจน',0,'การละลายของเกลือบางชนิดดูดความร้อนจากสิ่งแวดล้อม'),
  ('ปฏิกิริยาเคมี','หลักของเลอชาเตอลิเยร์กล่าวว่าอย่างไร','สมดุลไม่เปลี่ยนเมื่อรบกวน','ปฏิกิริยาย้อนกลับเกิดไม่ได้','พลังงานสร้างขึ้นใหม่ได้','ระบบสมดุลจะปรับตัวต้านการเปลี่ยนแปลงที่มากระทบ',3,'เมื่อเปลี่ยนความเข้มข้น อุณหภูมิ หรือความดัน สมดุลจะเลื่อนเพื่อลดผลกระทบ'),
  ('ไฟฟ้าเคมี','ออกซิเดชันหมายถึงอะไร','การรับอิเล็กตรอน','การรับโปรตอน','การเสียอิเล็กตรอน','การเสียนิวตรอน',2,'จำง่าย: OIL RIG — Oxidation Is Loss'),
  ('ไฟฟ้าเคมี','ที่แคโทดในเซลล์กัลวานิกเกิดปฏิกิริยาใด','ออกซิเดชัน','รีดักชัน','สะเทิน','ไม่มีปฏิกิริยา',1,'ที่แคโทดเกิดรีดักชันเสมอ'),
  ('ไฟฟ้าเคมี','ตัวออกซิไดซ์ (oxidizing agent) คือสารที่ทำอะไร','รับอิเล็กตรอน','ให้อิเล็กตรอน','ให้โปรตอน','รับนิวตรอน',0,'ตัวออกซิไดซ์เองถูกรีดิวซ์'),
  ('ไฟฟ้าเคมี','เลขออกซิเดชันของ O ใน H₂O เป็นเท่าใด','+2','0','−1','−2',3,'โดยทั่วไป O มีเลขออกซิเดชัน −2'),
  ('ไฟฟ้าเคมี','เลขออกซิเดชันของ Fe ใน Fe₂O₃ เป็นเท่าใด','+2','+6','+3','0',2,'O 3 อะตอมรวม −6 ดังนั้น Fe แต่ละตัวเป็น +3'),
  ('ไฟฟ้าเคมี','แบตเตอรี่ขณะจ่ายไฟแปลงพลังงานชนิดใดเป็นพลังงานไฟฟ้า','พลังงานแสง','พลังงานเคมี','พลังงานความร้อน','พลังงานนิวเคลียร์',1,'เซลล์กัลวานิกเปลี่ยนพลังงานเคมีเป็นไฟฟ้า'),
  ('ไฟฟ้าเคมี','การชุบโลหะด้วยไฟฟ้าใช้เซลล์ชนิดใด','เซลล์อิเล็กโทรลิติก','เซลล์กัลวานิก','เซลล์สุริยะ','เซลล์เชื้อเพลิง',0,'ใช้ไฟฟ้าภายนอกขับให้เกิดปฏิกิริยา'),
  ('เคมีอินทรีย์','สารที่มีสูตร C₂H₂ จัดเป็นสารประเภทใด','แอลคีน','แอลเคน','แอลกอฮอล์','แอลไคน์',3,'มีพันธะสามระหว่างคาร์บอน'),
  ('เคมีอินทรีย์','เบนซีนมีสูตรโมเลกุลใด','C₆H₁₂','C₆H₁₄','C₆H₆','C₅H₆',2,'เบนซีนเป็นสารอะโรมาติกมีวงหกเหลี่ยม'),
  ('เคมีอินทรีย์','แอลเคนที่มีคาร์บอน 4 อะตอมชื่อว่าอะไร','โพรเพน','บิวเทน','เพนเทน','เฮกเซน',1,'1–4 คือ มีเทน เอทเทน โพรเพน บิวเทน'),
  ('เคมีอินทรีย์','แอลเคนที่มีคาร์บอน 6 อะตอมชื่อว่าอะไร','เฮกเซน','เพนเทน','เฮปเทน','บิวเทน',0,'เฮกเซน = 6 คาร์บอน'),
  ('เคมีอินทรีย์','หมู่ฟังก์ชันของอัลดีไฮด์คือข้อใด','–COOH','–OH','–COO–','–CHO',3,'คาร์บอนิลที่ปลายสายพร้อมไฮโดรเจน'),
  ('เคมีอินทรีย์','หมู่ฟังก์ชันของเอสเทอร์คือข้อใด','–CO–','–O–','–COO–','–COOH',2,'เอสเทอร์มีกลิ่นหอมผลไม้'),
  ('เคมีอินทรีย์','ไอโซเมอร์คือสารที่มีลักษณะอย่างไร','เลขอะตอมเท่ากันแต่มวลต่างกัน','สูตรโมเลกุลเดียวกันแต่โครงสร้างต่างกัน','สูตรโครงสร้างเหมือนกันทุกประการ','เป็นสารที่มีธาตุต่างกัน',1,'เช่น บิวเทนและไอโซบิวเทน'),
  ('เคมีอินทรีย์','ปฏิกิริยาเอสเทอริฟิเคชันเกิดจากสารคู่ใด','กรดคาร์บอกซิลิกกับแอลกอฮอล์','แอลเคนกับน้ำ','แอลคีนกับแอลเคน','กรดกับโลหะ',0,'ได้เอสเทอร์และน้ำ'),
  ('เคมีอินทรีย์','แอลคีนเกิดปฏิกิริยาเด่นแบบใด','การแทนที่','การสะเทิน','การระเหิด','การเติม',3,'พันธะคู่ของแอลคีนเปิดออกรับอะตอมเพิ่ม'),
  ('เคมีอินทรีย์','สารละลายโบรมีนสีน้ำตาลแดงจางหายเมื่อทำปฏิกิริยากับสารใด','แอลเคน','น้ำ','แอลคีน','เกลือแกง',2,'แอลคีนเกิดปฏิกิริยาการเติมกับโบรมีน'),
  ('เคมีอินทรีย์','เมทานอลมีสูตรโมเลกุลใด','C₂H₅OH','CH₃OH','CH₃COOH','HCHO',1,'เมทานอลมี 1 คาร์บอน หมู่ –OH 1 หมู่'),
  ('เคมีอินทรีย์','ปฏิกิริยาสะปอนนิฟิเคชันใช้ผลิตสิ่งใด','สบู่','พลาสติก','น้ำมันเบนซิน','ผงซักฟอก (แอลคิลเบนซีนซัลโฟเนต) เท่านั้น',0,'ไขมันหรือน้ำมันทำปฏิกิริยากับเบสแก่ได้สบู่และกลีเซอรอล'),
  ('เคมีอินทรีย์','เอทานอลมีสูตรโมเลกุลใด','CH₃OH','CH₃CHO','C₂H₆','C₂H₅OH',3,'เอทานอลคือแอลกอฮอล์ในเครื่องดื่ม'),
  ('เคมีอินทรีย์','ก๊าซหุงต้ม (LPG) ส่วนใหญ่ประกอบด้วยสารใด','มีเทนล้วน','เอทานอล','โพรเพนและบิวเทน','แอซีทิลีน',2,'LPG = Liquefied Petroleum Gas'),
  ('พอลิเมอร์','มอนอเมอร์ของพอลิเอทิลีนคือสารใด','โพรพีน','เอทีน (เอทิลีน)','สไตรีน','ไวนิลคลอไรด์',1,'เอทีนต่อกันเป็นสายยาวเป็นพอลิเอทิลีน'),
  ('พอลิเมอร์','ข้อใดเป็นพอลิเมอร์ธรรมชาติ','แป้ง','PVC','ไนลอน','พอลิเอทิลีน',0,'แป้งเป็นพอลิเมอร์ของกลูโคส'),
  ('พอลิเมอร์','โปรตีนเป็นพอลิเมอร์ของมอนอเมอร์ชนิดใด','กลูโคส','กรดไขมัน','เอทีน','กรดอะมิโน',3,'กรดอะมิโนต่อกันด้วยพันธะเพปไทด์'),
  ('พอลิเมอร์','แป้งเป็นพอลิเมอร์ของมอนอเมอร์ชนิดใด','ฟรักโทส','กรดอะมิโน','กลูโคส','เอทีน',2,'แป้งและเซลลูโลสเป็นพอลิเมอร์ของกลูโคส'),
  ('พอลิเมอร์','พลาสติกที่หลอมและขึ้นรูปใหม่ได้เมื่อได้รับความร้อนเรียกว่าอะไร','เทอร์โมเซต','เทอร์โมพลาสติก','ยางวัลคาไนซ์','เส้นใยธรรมชาติ',1,'เทอร์โมพลาสติก เช่น พอลิเอทิลีน พีวีซี'),
  ('พอลิเมอร์','การวัลคาไนซ์ยางใช้สารใด','กำมะถัน','ออกซิเจน','ไนโตรเจน','ซิลิกา',0,'กำมะถันสร้างพันธะเชื่อมขวาง ทำให้ยางแข็งแรงยืดหยุ่น'),
  ('พอลิเมอร์','การสังเคราะห์ไนลอนเป็นพอลิเมอไรเซชันแบบใด','แบบเติม','แบบแทนที่','แบบสะเทิน','แบบควบแน่น',3,'ควบแน่นแล้วเกิดโมเลกุลเล็กเช่นน้ำ'),
  ('พอลิเมอร์','เซลลูโลสพบมากที่ส่วนใดของสิ่งมีชีวิต','ไข่ขาว','น้ำนม','ผนังเซลล์พืช','กระดูกสัตว์',2,'เซลลูโลสเป็นโครงสร้างหลักของพืช'),
  ('สมบัติของสาร','การเปลี่ยนสถานะจากของแข็งเป็นของเหลวเรียกว่าอะไร','การระเหย','การหลอมเหลว','การควบแน่น','การแข็งตัว',1,'เช่น น้ำแข็งละลายเป็นน้ำ'),
  ('สมบัติของสาร','การเปลี่ยนสถานะจากแก๊สเป็นของเหลวเรียกว่าอะไร','การควบแน่น','การระเหิด','การหลอมเหลว','การกลายเป็นไอ',0,'เช่น ไอน้ำกลายเป็นหยดน้ำบนแก้วเย็น'),
  ('สมบัติของสาร','ความหนาแน่นของสารคำนวณจากสูตรใด','ปริมาตร ÷ มวล','มวล × ปริมาตร','มวล − ปริมาตร','มวล ÷ ปริมาตร',3,'หน่วยเช่น g/cm³'),
  ('สมบัติของสาร','ข้อใดเป็นสารผสมเนื้อเดียว','น้ำโคลน','น้ำมันกับน้ำ','น้ำเกลือ','ทรายผสมน้ำ',2,'น้ำเกลือเป็นสารละลายเห็นเป็นเนื้อเดียวกัน'),
  ('สมบัติของสาร','ข้อใดเป็นสารประกอบ','ทองแดง','น้ำ','ออกซิเจน','สเตนเลส',1,'น้ำ H₂O ประกอบด้วยสองธาตุรวมกันด้วยอัตราส่วนคงที่'),
  ('สมบัติของสาร','การกลั่นแยกสารอาศัยความแตกต่างของสมบัติใด','จุดเดือด','สี','ความเป็นกรด-เบส','มวลอะตอม',0,'สารที่เดือดต่ำกว่าจะกลายเป็นไอก่อน'),
  ('สมบัติของสาร','โครมาโทกราฟีแยกสารโดยอาศัยอะไร','จุดเดือดต่างกัน','ความหนาแน่นต่างกันเท่านั้น','สีของสารต้นทาง','การละลายและการดูดซับของสารต่างกัน',3,'สารเคลื่อนที่ตามตัวทำละลายได้ไม่เท่ากัน'),
  ('สมบัติของสาร','น้ำบริสุทธิ์เดือดที่ความดัน 1 บรรยากาศที่อุณหภูมิกี่องศาเซลเซียส','0','37','100','212',2,'น้ำเดือดที่ 100 °C ที่ระดับน้ำทะเล'),
  ('สมบัติของสาร','กฎของบอยล์กล่าวถึงความสัมพันธ์ใดของแก๊ส (อุณหภูมิคงที่)','ความดันแปรผันตรงกับปริมาตร','ความดันแปรผกผันกับปริมาตร','ปริมาตรไม่ขึ้นกับความดัน','ความดันไม่เปลี่ยนเลย',1,'P₁V₁ = P₂V₂'),
  ('สมบัติของสาร','การแยกเกลือออกจากน้ำเกลือทำได้ด้วยวิธีใดเหมาะสมที่สุด','การระเหยแห้ง','การกรอง','การใช้แม่เหล็ก','การร่อน',0,'น้ำระเหยไป เกลือเหลืออยู่'),
  ('สมบัติของสาร','การละลายน้ำตาลในน้ำเป็นการเปลี่ยนแปลงชนิดใด','การเปลี่ยนแปลงทางเคมี','ปฏิกิริยาเผาไหม้','ปฏิกิริยาสะเทิน','การเปลี่ยนแปลงทางกายภาพ',3,'น้ำตาลไม่ได้กลายเป็นสารใหม่'),
  ('เคมีในชีวิตประจำวัน','เกลือแกงมีสูตรเคมีใด','NaOH','KCl','NaCl','Na₂CO₃',2,'เกลือแกงคือโซเดียมคลอไรด์'),
  ('เคมีในชีวิตประจำวัน','ผงฟูหรือเบกกิ้งโซดามีชื่อทางเคมีว่าอะไร','โซเดียมคลอไรด์','โซเดียมไฮโดรเจนคาร์บอเนต','แคลเซียมคาร์บอเนต','โซเดียมไฮดรอกไซด์',1,'สูตร NaHCO₃ ให้ CO₂ ทำให้ขนมฟู'),
  ('เคมีในชีวิตประจำวัน','หินปูนและเปลือกหอยมีสารหลักคือสารใด','แคลเซียมคาร์บอเนต','โซเดียมคลอไรด์','แคลเซียมคลอไรด์','ซิลิกอนไดออกไซด์',0,'สูตร CaCO₃'),
  ('เคมีในชีวิตประจำวัน','น้ำยาฟอกขาวในครัวเรือนมีสารออกฤทธิ์หลักคือสารใด','โซเดียมคลอไรด์','เอทานอล','ไฮโดรเจนเปอร์ออกไซด์ที่เจือจางมาก','โซเดียมไฮโพคลอไรต์',3,'NaOCl เป็นตัวออกซิไดซ์ที่ฟอกสีได้'),
  ('เคมีในชีวิตประจำวัน','น้ำตาลทรายมีสูตรโมเลกุลใด','C₆H₁₂O₆','C₂H₅OH','C₁₂H₂₂O₁₁','CH₃COOH',2,'ซูโครสประกอบด้วยกลูโคสและฟรักโทส'),
  ('เคมีในชีวิตประจำวัน','ข้อใดเป็นเหตุผลที่แก๊สคาร์บอนไดออกไซด์ทำให้เกิดภาวะเรือนกระจก','ทำให้โลกเย็นลง','ดูดและกักเก็บรังสีอินฟราเรดไว้','เป็นแก๊สเฉื่อย','ลดแสงอาทิตย์ทั้งหมด',1,'ก๊าซเรือนกระจกกักความร้อนไว้ในบรรยากาศ'),
  ('เคมีในชีวิตประจำวัน','แก๊สใดที่พืชนำไปใช้ในการสังเคราะห์ด้วยแสง','คาร์บอนไดออกไซด์','ไนโตรเจน','ฮีเลียม','ไฮโดรเจนซัลไฟด์',0,'6CO₂ + 6H₂O → C₆H₁₂O₆ + 6O₂'),
  ('เคมีในชีวิตประจำวัน','ปุ๋ยยูเรียให้ธาตุอาหารหลักตัวใดแก่พืชเป็นหลัก','ฟอสฟอรัส','โพแทสเซียม','แคลเซียม','ไนโตรเจน',3,'ยูเรีย CO(NH₂)₂ มีไนโตรเจนสูง'),
  ('เคมีในชีวิตประจำวัน','แก๊สที่ทำให้ลูกโป่งลอยได้ปลอดภัยกว่าไฮโดรเจนเพราะไม่ติดไฟคือแก๊สใด','ออกซิเจน','มีเทน','ฮีเลียม','คลอรีน',2,'ฮีเลียมเบาและเฉื่อย ไม่ติดไฟ'),
  ('ความปลอดภัย','ถ้าสารเคมีเข้าตา ควรล้างตาด้วยน้ำสะอาดต่อเนื่องอย่างน้อยกี่นาที','1 นาที','15 นาที','30 วินาที','2 ชั่วโมง',1,'ล้างนานและต่อเนื่องแล้วรีบไปพบแพทย์'),
  ('ความปลอดภัย','การดมสารเคมีในห้องปฏิบัติการควรทำอย่างไร','โบกไอเข้าหาจมูกเบาๆ','ดมใกล้ๆ โดยตรง','สูดหายใจลึกๆ เหนือภาชนะ','ใช้ปากชิมเล็กน้อย',0,'ห้ามดมตรงๆ และห้ามชิมสารเคมี'),
  ('ความปลอดภัย','สัญลักษณ์เปลวไฟบนฉลากสารเคมีหมายถึงอะไร','สารกัดกร่อน','สารพิษ','สารกัมมันตรังสี','สารไวไฟ',3,'ต้องเก็บให้ห่างจากแหล่งความร้อนและประกายไฟ'),
  ('ความปลอดภัย','ไฟไหม้ตัวทำละลายอินทรีย์ในห้องแล็บ ไม่ควรดับด้วยอะไร','ผ้าห่มดับไฟ','ถังดับเพลิง CO₂','น้ำ','ทราย',2,'ตัวทำละลายอินทรีย์มักลอยบนน้ำ ทำให้ไฟลามกว้างขึ้น'),
  ('ความปลอดภัย','ทำปฏิกิริยาที่เกิดแก๊สพิษควรทำที่ใด','โต๊ะปฏิบัติการปกติที่ปิดหน้าต่าง','ตู้ดูดควัน','ใกล้ประตูห้อง','ในห้องเก็บของ',1,'ตู้ดูดควันดูดแก๊สพิษออกจากผู้ปฏิบัติการ'),
  ('ความปลอดภัย','อุปกรณ์ป้องกันที่ควรสวมขณะทำการทดลองเคมีอย่างน้อยคือข้อใด','แว่นตานิรภัยและเสื้อกาวน์','หมวกกันน็อก','หูฟัง','รองเท้าแตะ',0,'ป้องกันดวงตาและผิวหนังจากสารเคมี'),
  ('ความปลอดภัย','ก่อนทิ้งสารละลายที่เหลือจากการทดลองควรทำอย่างไร','เทลงอ่างน้ำทุกชนิด','เทรวมลงถังขยะ','นำกลับบ้าน','ทิ้งตามประเภทที่ครูกำหนด',3,'สารบางชนิดต้องแยกเก็บเป็นของเสียอันตราย')
) as v(topic, question, a, b, c, d, answer, explain)
where not exists (select 1 from quiz_questions x where x.question = v.question);
-- =====================================================================
-- รอบที่ 25b: เปลี่ยนความสามารถ “ผู้พิทักษ์” → โล่ทีม (ช่วยเพื่อน/ลดโทษ)
-- เดิม: ตัวผู้พิทักษ์เองมาสาย/ส่งช้าได้เต็ม · ใหม่: เพื่อนร่วมทีมที่มี “ผู้พิทักษ์” อยู่ด้วย
-- มาสาย/ส่งงานช้าแล้วยังได้รางวัลเต็ม (ตัวผู้พิทักษ์เองได้ตามปกติ) · รันซ้ำได้
-- =====================================================================
create or replace function _guardian_cover(p_student uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from students me
    join students g on g.team_id = me.team_id and g.id <> me.id and g.char_class = 'guardian'
    where me.id = p_student and me.team_id is not null)
$$;
revoke execute on function _guardian_cover(uuid) from public, anon, authenticated;

create or replace function trg_attendance() returns trigger
language plpgsql security definer set search_path = public as $$
declare v uuid;
begin
  if new.status = 'present' then
    perform award(new.student_id, 5, 2, 'มาเรียนตรงเวลา ' || new.att_date, 'att:' || new.id);
  elsif new.status = 'late' then
    if _guardian_cover(new.student_id) then
      perform award(new.student_id, 5, 2, 'มาเรียน (สาย — ผู้พิทักษ์ในทีมช่วยไว้) ' || new.att_date, 'att:' || new.id);
    else
      perform award(new.student_id, 2, 1, 'มาเรียน (สาย) ' || new.att_date, 'att:' || new.id);
    end if;
  end if;

  if new.status in ('present', 'late') and new.att_date >= today_th() - 3 then
    -- ตั๋วสุ่มกาชาฟรี 1 ใบต่อการเข้าเรียนหนึ่งครั้ง (กันซ้ำด้วย ledger)
    v := null;
    insert into ledger (student_id, exp, coins, reason, ref_key)
    values (new.student_id, 0, 0, 'ตั๋วสุ่มกาชาฟรี (เช็คชื่อ ' || new.att_date || ')', 'attticket:' || new.id)
    on conflict (student_id, ref_key) do nothing returning id into v;
    if v is not null then update students set free_pulls = free_pulls + 1 where id = new.student_id; end if;

    -- เควสที่ตั้งเป็น “สำเร็จอัตโนมัติเมื่อเช็คชื่อ”
    perform _auto_quests(new.student_id, 'attendance', new.att_date);
  end if;
  perform check_achievements(new.student_id);
  return new;
end $$;

create or replace function trg_submission() returns trigger
language plpgsql security definer set search_path = public as $$
declare a ch_assignments%rowtype; ref text;
begin
  select * into a from ch_assignments where id = new.assignment_id;
  ref := 'sub:' || new.id || case when new.attempt > 1 then ':' || new.attempt else '' end;
  if new.status = 'submitted' then
    perform award(new.student_id, a.exp_reward, a.coin_reward, 'ส่งงาน: ' || a.title, ref);
  elsif new.status = 'late' then
    if _guardian_cover(new.student_id) then
      perform award(new.student_id, a.exp_reward, a.coin_reward, 'ส่งงาน (ช้า — ผู้พิทักษ์ในทีมช่วยไว้): ' || a.title, ref);
    else
      perform award(new.student_id, a.exp_reward / 2, a.coin_reward / 2, 'ส่งงาน (ช้า): ' || a.title, ref);
    end if;
  end if;
  if new.status in ('submitted', 'late') then perform _auto_quests(new.student_id, 'submit'); end if;
  perform check_achievements(new.student_id);
  return new;
end $$;


update char_classes set
  description = 'ปกป้องเพื่อนร่วมทีม',
  ability = 'เพื่อนในทีมเดียวกับผู้พิทักษ์ มาสาย/ส่งงานช้า ยังได้รางวัลเต็ม (ต้องอยู่ทีมเดียวกัน)'
where key = 'guardian' and ability = 'มาสาย/ส่งงานช้า ได้รางวัลเต็ม เหมือนตรงเวลา';
-- =====================================================================
-- Chemistria · รอบที่ 26: ประกาศ popup แสดงความยินดี (ได้ SSR / เลื่อนแรงค์) (รันซ้ำได้)
--  · ระบบบันทึกเหตุการณ์อัตโนมัติ → เพื่อนร่วมห้องเห็น popup ตอนเปิดแอป (ย้อนหลัง ≤ 24 ชม.)
--  · ครูปิดได้ที่ตั้งค่า celebrate_enabled = 0
-- =====================================================================
insert into app_settings (key, value) values ('celebrate_enabled', '1') on conflict (key) do nothing;

create table if not exists celebrations (
  id bigint generated always as identity primary key,
  class_id uuid not null references classes(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  kind text not null check (kind in ('ssr', 'rank')),
  title text not null,          -- ชื่อไอเทม SSR หรือชื่อแรงค์ใหม่
  emoji text,
  image text,
  created_at timestamptz not null default now()
);
create index if not exists celebrations_idx on celebrations (class_id, id desc);
alter table celebrations enable row level security;
drop policy if exists teacher_all on celebrations;
create policy teacher_all on celebrations for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on celebrations from anon;
grant select, insert, update, delete on celebrations to authenticated;

-- ได้ SSR จากกาชา
create or replace function trg_cel_ssr() returns trigger
language plpgsql security definer set search_path = public as $$
declare it gacha_items%rowtype; cid uuid;
begin
  if _setting_int('celebrate_enabled', 1) = 0 then return new; end if;
  select * into it from gacha_items where id = new.item_id;
  if found and it.rarity = 'SSR' then
    select class_id into cid from students where id = new.student_id;
    insert into celebrations (class_id, student_id, kind, title, emoji, image)
    values (cid, new.student_id, 'ssr', it.name, it.emoji, it.image_url);
  end if;
  return new;
end $$;
drop trigger if exists cel_ssr on gacha_pulls;
create trigger cel_ssr after insert on gacha_pulls for each row execute function trg_cel_ssr();

-- เลื่อนแรงค์ (เปลี่ยนระดับแรงค์ เช่น Bronze → Silver)
create or replace function trg_cel_rank() returns trigger
language plpgsql security definer set search_path = public as $$
declare a json; b json;
begin
  if new.exp <= old.exp or _setting_int('celebrate_enabled', 1) = 0 then return new; end if;
  a := rank_info(old.exp); b := rank_info(new.exp);
  if (a->>'key') <> (b->>'key') then
    insert into celebrations (class_id, student_id, kind, title, image)
    values (new.class_id, new.id, 'rank', b->>'name', b->>'image');
  end if;
  return new;
end $$;
drop trigger if exists cel_rank on students;
create trigger cel_rank after update of exp on students for each row execute function trg_cel_rank();

-- ดึงประกาศของห้องตัวเอง: p_since = id ล่าสุดที่เคยเห็น (null = เฉพาะ 6 ชม.ล่าสุด)
create or replace function celebrations_feed(p_token uuid, p_since bigint default null) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cid uuid; mx bigint;
begin
  select class_id into cid from students where id = sid;
  select coalesce(max(id), 0) into mx from celebrations where class_id = cid;
  return json_build_object('max', mx, 'items', coalesce((
    select json_agg(x order by x.id) from (
      select c.id, c.kind, c.title, c.emoji, c.image, s.name, (c.student_id = sid) as mine,
             s.char_class
        from celebrations c join students s on s.id = c.student_id
       where c.class_id = cid
         and ((p_since is not null and c.id > p_since and c.created_at > now() - interval '24 hours')
              or (p_since is null and c.created_at > now() - interval '6 hours'))
       order by c.id desc limit 8) x), '[]'::json));
end $$;
revoke execute on function celebrations_feed(uuid, bigint) from public;
grant execute on function celebrations_feed(uuid, bigint) to anon, authenticated;
revoke execute on function trg_cel_ssr(), trg_cel_rank() from public, anon, authenticated;
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
-- 24: ครูบุ๊คส่องมุมมองนักเรียนรายคน (อ่านอย่างเดียว ไม่แตะคะแนน/อันดับ/รายชื่อ)
alter table student_sessions add column if not exists observer boolean not null default false;

-- เซสชันผู้สังเกตการณ์ใช้ได้เฉพาะ RPC แบบอ่านอย่างเดียว (บังคับที่ฝั่งฐานข้อมูล)
create or replace function _sid(p_token uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare v uuid; o boolean; fn text;
begin
  select student_id, observer into v, o from student_sessions where token = p_token and expires_at > now();
  if v is null then raise exception 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่'; end if;
  if o then
    fn := regexp_replace(coalesce(current_setting('request.path', true), ''), '^.*/', '');
    if fn not in ('student_dashboard','student_extras','hall_of_fame','board_list','celebrations_feed','game_status','spell_status','kb_status') then
      raise exception 'โหมดส่องนักเรียน: ดูได้อย่างเดียว';
    end if;
  end if;
  return v;
end $$;

-- ครูขอโทเคนส่องนักเรียน (หมดอายุใน 2 ชั่วโมง) — ไม่แก้ last_login/คะแนน/รายชื่อ
create or replace function admin_peek(p_student uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare t uuid;
begin
  if not is_teacher() then raise exception 'เฉพาะครูเท่านั้น'; end if;
  if not exists (select 1 from students where id = p_student) then raise exception 'ไม่พบนักเรียน'; end if;
  delete from student_sessions where observer and expires_at < now();
  insert into student_sessions (student_id, observer, expires_at) values (p_student, true, now() + interval '2 hours') returning token into t;
  return t;
end $$;
revoke execute on function admin_peek(uuid) from public, anon;
grant execute on function admin_peek(uuid) to authenticated;
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
-- 26: คลังข้อสอบประลองครูบุ๊ค (แก้ไขได้ในหน้าครู) + ชุดข้อสอบ ม.ต้น (เนื้อหา ม.1)
create table if not exists kb_bank (
  id uuid primary key default gen_random_uuid(),
  level text not null default 'hs' check (level in ('hs','jr')),            -- hs = ม.ปลาย · jr = ม.ต้น (ม.1–ม.3)
  kind text not null check (kind in ('quiz','calc','tf','odd')),            -- ควิซ · คำนวณ · จริง/เท็จ · หาตัวแปลกแยก
  question text not null,
  answer text not null,                                                      -- คำตอบที่ถูก (tf = จริง/เท็จ · odd = ตัวที่แปลกแยก)
  wrong jsonb not null default '[]'::jsonb,                                  -- ตัวลวง 3 ข้อ (odd = สมาชิกในกลุ่มเดียวกัน 3 ตัว)
  explain text,
  active boolean not null default true,
  created_at timestamptz default now()
);
alter table kb_bank enable row level security;
drop policy if exists teacher_all on kb_bank;
create policy teacher_all on kb_bank for all using (is_teacher()) with check (is_teacher());
revoke all on kb_bank from anon;

create or replace function _kb_level(p_sid uuid) returns text
language sql stable security definer set search_path = public as $$
  select case when c.name ~ '^ม\.?\s*[123]\s*([/ ]|$)' then 'jr' else 'hs' end
    from students s join classes c on c.id = s.class_id where s.id = p_sid
$$;
revoke execute on function _kb_level(uuid) from public, anon, authenticated;

create or replace function kb_bank(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); lv text := coalesce(_kb_level(sid), 'hs');
begin
  return json_build_object('level', lv, 'items', coalesce((
    select json_agg(json_build_object('kind', kind, 'question', question, 'answer', answer, 'wrong', wrong, 'explain', explain))
      from kb_bank where active and level = lv), '[]'::json));
end $$;
revoke execute on function kb_bank(uuid) from public;
grant execute on function kb_bank(uuid) to anon, authenticated;

insert into kb_bank (level, kind, question, answer, wrong, explain)
select v.* from (values
('jr','quiz','ข้อใดเป็นอุปกรณ์สำหรับวัดปริมาตรของเหลวได้แม่นยำที่สุด','กระบอกตวง','["บีกเกอร์", "ขวดรูปกรวย", "จานระเหย"]'::jsonb,'กระบอกตวงมีขีดบอกปริมาตรละเอียดกว่าบีกเกอร์'),
('jr','quiz','สถานะใดของสารที่มีรูปร่างและปริมาตรคงที่','ของแข็ง','["ของเหลว", "แก๊ส", "พลาสมา"]'::jsonb,'ของแข็งอนุภาคเรียงชิดกันและอยู่กับที่'),
('jr','quiz','การที่น้ำแข็งกลายเป็นน้ำ เรียกว่า','การหลอมเหลว','["การระเหย", "การควบแน่น", "การระเหิด"]'::jsonb,'ของแข็ง → ของเหลว = หลอมเหลว'),
('jr','quiz','การที่ไอน้ำกลายเป็นหยดน้ำที่ข้างแก้วน้ำเย็น เรียกว่า','การควบแน่น','["การระเหย", "การหลอมเหลว", "การแข็งตัว"]'::jsonb,'แก๊ส → ของเหลว = ควบแน่น'),
('jr','quiz','สารใดต่อไปนี้เป็นธาตุ','ทองแดง','["น้ำ", "เกลือแกง", "อากาศ"]'::jsonb,'ทองแดง (Cu) เป็นธาตุ ส่วนที่เหลือเป็นสารประกอบหรือสารผสม'),
('jr','quiz','สารใดต่อไปนี้เป็นสารประกอบ','น้ำ','["ออกซิเจน", "เหล็ก", "ทองคำ"]'::jsonb,'น้ำ (H₂O) ประกอบด้วยธาตุไฮโดรเจนและออกซิเจน'),
('jr','quiz','สารใดต่อไปนี้เป็นสารผสม','น้ำเกลือ','["น้ำบริสุทธิ์", "ออกซิเจน", "เงิน"]'::jsonb,'น้ำเกลือเป็นเกลือผสมในน้ำ'),
('jr','quiz','วิธีแยกเกลือออกจากน้ำเกลือที่เหมาะสมที่สุดคือ','การระเหยแห้ง','["การกรอง", "การใช้แม่เหล็กดูด", "การร่อน"]'::jsonb,'น้ำระเหยไป เกลือเหลืออยู่'),
('jr','quiz','วิธีแยกทรายออกจากน้ำขุ่นคือ','การกรอง','["การระเหย", "การกลั่น", "การใช้แม่เหล็ก"]'::jsonb,'ทรายไม่ละลายน้ำ กรองได้'),
('jr','quiz','วิธีแยกผงเหล็กออกจากผงทรายคือ','ใช้แม่เหล็กดูด','["การกรอง", "การระเหย", "การกลั่น"]'::jsonb,'เหล็กถูกแม่เหล็กดูด ทรายไม่ถูก'),
('jr','quiz','ข้อใดคือสัญลักษณ์ธาตุของออกซิเจน','O','["Ox", "Og", "Oy"]'::jsonb,'ออกซิเจน = O'),
('jr','quiz','สัญลักษณ์ธาตุของโซเดียมคือ','Na','["S", "So", "N"]'::jsonb,'Na มาจากภาษาละติน natrium'),
('jr','quiz','สัญลักษณ์ธาตุของเหล็กคือ','Fe','["F", "Ir", "Fi"]'::jsonb,'Fe มาจากภาษาละติน ferrum'),
('jr','quiz','สัญลักษณ์ธาตุของทองคำคือ','Au','["Ag", "Go", "Gd"]'::jsonb,'Au มาจากภาษาละติน aurum'),
('jr','quiz','สัญลักษณ์ธาตุของคาร์บอนคือ','C','["Ca", "Cr", "Co"]'::jsonb,'คาร์บอน = C'),
('jr','quiz','สูตรเคมีของน้ำคือ','H₂O','["HO₂", "H₂O₂", "CO₂"]'::jsonb,'น้ำมีไฮโดรเจน 2 อะตอม ออกซิเจน 1 อะตอม'),
('jr','quiz','สูตรเคมีของแก๊สคาร์บอนไดออกไซด์คือ','CO₂','["CO", "C₂O", "O₂C₂"]'::jsonb,'คาร์บอน 1 อะตอม ออกซิเจน 2 อะตอม'),
('jr','quiz','อนุภาคที่มีประจุบวกในอะตอมคือ','โปรตอน','["นิวตรอน", "อิเล็กตรอน", "โมเลกุล"]'::jsonb,'โปรตอนมีประจุ +1'),
('jr','quiz','อนุภาคที่ไม่มีประจุในอะตอมคือ','นิวตรอน','["โปรตอน", "อิเล็กตรอน", "ไอออน"]'::jsonb,'นิวตรอนเป็นกลางทางไฟฟ้า'),
('jr','quiz','อิเล็กตรอนอยู่ที่ส่วนใดของอะตอม','รอบนิวเคลียส','["ในนิวเคลียส", "ไม่มีอยู่ในอะตอม", "ที่ผิวอะตอมเท่านั้น"]'::jsonb,'อิเล็กตรอนเคลื่อนที่รอบนิวเคลียส'),
('jr','quiz','สารละลายที่มี pH น้อยกว่า 7 มีสมบัติเป็น','กรด','["เบส", "กลาง", "เกลือ"]'::jsonb,'pH < 7 เป็นกรด'),
('jr','quiz','น้ำบริสุทธิ์มีค่า pH ประมาณ','7','["1", "10", "14"]'::jsonb,'น้ำบริสุทธิ์เป็นกลาง'),
('jr','quiz','น้ำมะนาวมีสมบัติเป็น','กรด','["เบส", "กลาง", "ไม่มีสมบัติใด"]'::jsonb,'น้ำมะนาวมีรสเปรี้ยว เป็นกรดซิตริก'),
('jr','quiz','สบู่หรือน้ำสบู่มักมีสมบัติเป็น','เบส','["กรด", "กลาง", "ไม่แน่นอน"]'::jsonb,'สบู่ลื่นมือ มีสมบัติเป็นเบส'),
('jr','quiz','กระดาษลิตมัสสีน้ำเงินเมื่อสัมผัสกรดจะเปลี่ยนเป็นสี','แดง','["เขียว", "ม่วง", "ไม่เปลี่ยน"]'::jsonb,'กรดเปลี่ยนลิตมัสน้ำเงินเป็นแดง'),
('jr','quiz','สัญลักษณ์ที่ใช้เตือนสารไวไฟคือรูป','เปลวไฟ','["หัวกะโหลก", "ถังขยะ", "หยดน้ำ"]'::jsonb,'เปลวไฟบอกว่าติดไฟง่าย'),
('jr','quiz','ก่อนทำการทดลองในห้องปฏิบัติการ สิ่งที่ควรทำคือ','สวมเสื้อกาวน์และแว่นตานิรภัย','["ชิมสารเคมีดูรส", "วิ่งเล่นในห้อง", "ดมสารโดยตรง"]'::jsonb,'ความปลอดภัยต้องมาก่อน'),
('jr','quiz','เมื่อทำสารเคมีหกใส่มือ ควรทำอย่างไรก่อน','ล้างด้วยน้ำสะอาดและแจ้งครู','["เช็ดกับเสื้อ", "ปล่อยไว้", "ใช้สารอื่นล้าง"]'::jsonb,'ล้างน้ำปริมาณมากแล้วแจ้งครูทันที'),
('jr','quiz','หน่วยของมวลในระบบ SI คือ','กิโลกรัม','["ลิตร", "เมตร", "วินาที"]'::jsonb,'มวล = กิโลกรัม (kg)'),
('jr','quiz','เครื่องมือที่ใช้วัดมวลคือ','เครื่องชั่ง','["ไม้บรรทัด", "นาฬิกา", "เทอร์โมมิเตอร์"]'::jsonb,'เครื่องชั่งวัดมวล'),
('jr','quiz','เทอร์โมมิเตอร์ใช้วัดอะไร','อุณหภูมิ','["มวล", "ความยาว", "เวลา"]'::jsonb,'เทอร์โมมิเตอร์วัดอุณหภูมิ'),
('jr','quiz','น้ำเดือดที่ความดันปกติที่อุณหภูมิประมาณ','100 องศาเซลเซียส','["0 องศาเซลเซียส", "50 องศาเซลเซียส", "200 องศาเซลเซียส"]'::jsonb,'จุดเดือดของน้ำ = 100 °C'),
('jr','quiz','น้ำแข็งละลายที่อุณหภูมิประมาณ','0 องศาเซลเซียส','["10 องศาเซลเซียส", "100 องศาเซลเซียส", "-10 องศาเซลเซียส"]'::jsonb,'จุดหลอมเหลวของน้ำแข็ง = 0 °C'),
('jr','quiz','แก๊สที่เราหายใจเข้าไปเพื่อใช้ในร่างกายคือ','ออกซิเจน','["ไนโตรเจน", "คาร์บอนไดออกไซด์", "ไฮโดรเจน"]'::jsonb,'ร่างกายใช้ออกซิเจนในการหายใจ'),
('jr','quiz','แก๊สที่มีมากที่สุดในอากาศคือ','ไนโตรเจน','["ออกซิเจน", "คาร์บอนไดออกไซด์", "อาร์กอน"]'::jsonb,'ไนโตรเจนประมาณ 78%'),
('jr','quiz','การเปลี่ยนแปลงใดเป็นการเปลี่ยนแปลงทางเคมี','เหล็กเป็นสนิม','["น้ำแข็งละลาย", "น้ำระเหย", "ตัดกระดาษ"]'::jsonb,'เกิดสารใหม่คือสนิม'),
('jr','quiz','การเปลี่ยนแปลงใดเป็นการเปลี่ยนแปลงทางกายภาพ','น้ำแข็งละลาย','["ไม้ไหม้ไฟ", "นมบูด", "อาหารเน่า"]'::jsonb,'ไม่เกิดสารใหม่'),
('jr','quiz','ข้อใดบอกว่าเกิดการเปลี่ยนแปลงทางเคมี','มีแก๊สเกิดขึ้นและมีสีเปลี่ยน','["สารเปลี่ยนรูปร่าง", "สารเปลี่ยนขนาด", "สารเปลี่ยนตำแหน่ง"]'::jsonb,'แก๊ส ตะกอน สี กลิ่น ความร้อน เป็นหลักฐานของปฏิกิริยาเคมี'),
('jr','quiz','สารที่ละลายอยู่ในน้ำเรียกว่า','ตัวละลาย','["ตัวทำละลาย", "ตะกอน", "ตัวเร่ง"]'::jsonb,'ตัวละลายคือสารที่ถูกละลาย'),
('jr','quiz','น้ำตาลที่ละลายในน้ำจนเป็นเนื้อเดียวกัน เรียกว่า','สารละลาย','["สารประกอบ", "ธาตุ", "สารเนื้อเดียวไม่ได้"]'::jsonb,'ผสมกันเป็นเนื้อเดียว เรียกสารละลาย'),
('jr','quiz','ภาชนะแก้วที่นิยมใช้ต้มน้ำหรือให้ความร้อนคือ','บีกเกอร์','["กระบอกตวง", "หลอดหยด", "กระจกนาฬิกา"]'::jsonb,'บีกเกอร์ทนความร้อนได้'),
('jr','calc','น้ำตาล 20 กรัม ละลายในน้ำ 80 กรัม สารละลายมีมวลรวมกี่กรัม','100','["60", "80", "120"]'::jsonb,'20 + 80 = 100'),
('jr','calc','ผสมน้ำ 150 cm³ กับน้ำ 250 cm³ ได้ปริมาตรรวมกี่ cm³','400','["100", "300", "375"]'::jsonb,'150 + 250 = 400'),
('jr','calc','เหล็ก 1 ชิ้นมวล 80 g ปริมาตร 10 cm³ ความหนาแน่นกี่ g/cm³','8','["0.125", "70", "800"]'::jsonb,'D = m/V = 80/10'),
('jr','calc','วัตถุมวล 50 g ปริมาตร 25 cm³ มีความหนาแน่นกี่ g/cm³','2','["0.5", "25", "75"]'::jsonb,'50 ÷ 25 = 2'),
('jr','calc','น้ำมีความหนาแน่น 1 g/cm³ น้ำ 300 cm³ มีมวลกี่ g','300','["1", "30", "3"]'::jsonb,'m = D × V'),
('jr','calc','ถ้าอุณหภูมิน้ำ 25 °C เพิ่มขึ้นอีก 30 °C จะเป็นกี่ °C','55','["5", "45", "65"]'::jsonb,'25 + 30 = 55'),
('jr','calc','น้ำเกลือเข้มข้น 10% โดยมวล สารละลาย 200 g มีเกลือกี่ g','20','["10", "2", "100"]'::jsonb,'10% ของ 200 = 20'),
('jr','calc','โมเลกุลน้ำ (H₂O) 1 โมเลกุลมีอะตอมรวมกี่อะตอม','3','["2", "1", "4"]'::jsonb,'H 2 + O 1 = 3'),
('jr','calc','โมเลกุล CO₂ 1 โมเลกุลมีอะตอมออกซิเจนกี่อะตอม','2','["1", "3", "4"]'::jsonb,'เลข 2 บอกจำนวน O'),
('jr','calc','อะตอมมีโปรตอน 6 ตัว อิเล็กตรอนกี่ตัว (อะตอมเป็นกลาง)','6','["12", "0", "3"]'::jsonb,'โปรตอนเท่ากับอิเล็กตรอน'),
('jr','tf','น้ำเป็นสารประกอบ','จริง','[]'::jsonb,null),
('jr','tf','อากาศเป็นสารบริสุทธิ์','เท็จ','[]'::jsonb,null),
('jr','tf','แก๊สมีรูปร่างและปริมาตรไม่คงที่','จริง','[]'::jsonb,null),
('jr','tf','ของแข็งไหลได้เหมือนของเหลว','เท็จ','[]'::jsonb,null),
('jr','tf','เหล็กเป็นสนิมเป็นการเปลี่ยนแปลงทางเคมี','จริง','[]'::jsonb,null),
('jr','tf','การละลายน้ำตาลในน้ำเกิดสารใหม่','เท็จ','[]'::jsonb,null),
('jr','tf','สารละลายกรดมี pH มากกว่า 7','เท็จ','[]'::jsonb,null),
('jr','tf','สบู่มีสมบัติเป็นเบส','จริง','[]'::jsonb,null),
('jr','tf','น้ำเดือดที่ 100 °C ที่ความดันปกติ','จริง','[]'::jsonb,null),
('jr','tf','น้ำแข็งแห้งคือน้ำที่แข็งตัว','เท็จ','[]'::jsonb,null),
('jr','tf','โปรตอนมีประจุบวก','จริง','[]'::jsonb,null),
('jr','tf','อิเล็กตรอนอยู่ในนิวเคลียส','เท็จ','[]'::jsonb,null),
('jr','tf','เกลือแกงเป็นธาตุ','เท็จ','[]'::jsonb,null),
('jr','tf','ออกซิเจนช่วยให้ไฟติด','จริง','[]'::jsonb,null),
('jr','tf','ควรชิมสารเคมีเพื่อตรวจสอบ','เท็จ','[]'::jsonb,null),
('jr','tf','ต้องสวมแว่นตานิรภัยเมื่อทำการทดลอง','จริง','[]'::jsonb,null),
('jr','tf','ทองแดงนำไฟฟ้าได้ดี','จริง','[]'::jsonb,null),
('jr','tf','พลาสติกนำไฟฟ้าได้ดีมาก','เท็จ','[]'::jsonb,null),
('jr','tf','น้ำมันกับน้ำผสมกันเป็นเนื้อเดียว','เท็จ','[]'::jsonb,null),
('jr','tf','กรองใช้แยกของแข็งที่ไม่ละลายออกจากของเหลว','จริง','[]'::jsonb,null),
('jr','tf','สัญลักษณ์ธาตุของเงินคือ Ag','จริง','[]'::jsonb,null),
('jr','tf','สัญลักษณ์ธาตุของไฮโดรเจนคือ He','เท็จ','[]'::jsonb,null),
('jr','tf','การระเหยคือของเหลวกลายเป็นแก๊ส','จริง','[]'::jsonb,null),
('jr','tf','น้ำมะนาวมีสมบัติเป็นเบส','เท็จ','[]'::jsonb,null),
('jr','odd','ข้อใดแปลกแยกจากพวก','น้ำ','["ทองแดง", "เหล็ก", "อะลูมิเนียม"]'::jsonb,'ที่เหลือเป็นโลหะ น้ำเป็นสารประกอบ'),
('jr','odd','ข้อใดแปลกแยกจากพวก','น้ำสบู่','["น้ำมะนาว", "น้ำส้มสายชู", "น้ำอัดลม"]'::jsonb,'ที่เหลือเป็นกรด น้ำสบู่เป็นเบส'),
('jr','odd','ข้อใดแปลกแยกจากพวก','ความร้อน','["ของแข็ง", "ของเหลว", "แก๊ส"]'::jsonb,'ที่เหลือเป็นสถานะของสาร'),
('jr','odd','ข้อใดแปลกแยกจากพวก','Fe','["H₂O", "CO₂", "NaCl"]'::jsonb,'ที่เหลือเป็นสารประกอบ Fe เป็นธาตุ'),
('jr','odd','ข้อใดแปลกแยกจากพวก','ไม้บรรทัด','["บีกเกอร์", "กระบอกตวง", "ขวดรูปกรวย"]'::jsonb,'ที่เหลือเป็นอุปกรณ์แก้วในห้องแล็บ'),
('jr','odd','ข้อใดแปลกแยกจากพวก','เหล็กเป็นสนิม','["การระเหย", "การควบแน่น", "การหลอมเหลว"]'::jsonb,'ที่เหลือเป็นการเปลี่ยนแปลงทางกายภาพ'),
('jr','odd','ข้อใดแปลกแยกจากพวก','ทองคำ','["น้ำเกลือ", "น้ำโคลน", "อากาศ"]'::jsonb,'ที่เหลือเป็นสารผสม ทองคำเป็นธาตุ'),
('jr','odd','ข้อใดแปลกแยกจากพวก','โมเลกุล','["โปรตอน", "นิวตรอน", "อิเล็กตรอน"]'::jsonb,'ที่เหลือเป็นอนุภาคย่อยของอะตอม'),
('jr','odd','ข้อใดแปลกแยกจากพวก','การชั่ง','["แม่เหล็ก", "การกรอง", "การระเหย"]'::jsonb,'ที่เหลือเป็นวิธีแยกสาร'),
('jr','odd','ข้อใดแปลกแยกจากพวก','CO₂','["O", "Na", "Fe"]'::jsonb,'ที่เหลือเป็นสัญลักษณ์ธาตุ')
) v(level, kind, question, answer, wrong, explain)
where not exists (select 1 from kb_bank x where x.level = v.level and x.kind = v.kind and x.question = v.question and x.answer = v.answer);
-- 27: ข่าวสาร/อีเว้นท์ สไลด์หน้าแรก (ครูเพิ่ม/แก้ได้ในหน้าครู)
create table if not exists news_posts (
  id uuid primary key default gen_random_uuid(),
  kind text not null default 'news' check (kind in ('news','event')),
  title text not null,
  summary text,                       -- ข้อความสั้นบนสไลด์
  body text,                          -- รายละเอียดเต็มเมื่อกดดู
  image text,                         -- พาธรูป (เช่น assets/news/rank.jpg) หรือ URL https
  starts_at date,                     -- อีเว้นท์: วันเริ่ม (ไม่บังคับ)
  ends_at date,                       -- แสดงถึงวันนี้ (ไม่บังคับ)
  sort int not null default 0,        -- เลขมากขึ้นก่อน
  active boolean not null default true,
  created_at timestamptz default now()
);
alter table news_posts enable row level security;
drop policy if exists teacher_all on news_posts;
create policy teacher_all on news_posts for all using (is_teacher()) with check (is_teacher());
revoke all on news_posts from anon;

create or replace function news_list(p_token uuid) returns json
language plpgsql stable security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  return coalesce((select json_agg(x order by x.sort desc, x.created_at desc) from (
    select id, kind, title, summary, body, image, starts_at, ends_at, sort, created_at from news_posts
     where active and (ends_at is null or ends_at >= today_th()) order by sort desc, created_at desc limit 12) x), '[]'::json);
end $$;
revoke execute on function news_list(uuid) from public;
grant execute on function news_list(uuid) to anon, authenticated;

-- ให้ผู้สังเกตการณ์ (โหมดส่อง) เรียก news_list ได้
create or replace function _sid(p_token uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare v uuid; o boolean; fn text;
begin
  select student_id, observer into v, o from student_sessions where token = p_token and expires_at > now();
  if v is null then raise exception 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่'; end if;
  if o then
    fn := regexp_replace(coalesce(current_setting('request.path', true), ''), '^.*/', '');
    if fn not in ('student_dashboard','student_extras','hall_of_fame','board_list','celebrations_feed','game_status','spell_status','kb_status','news_list') then
      raise exception 'โหมดส่องนักเรียน: ดูได้อย่างเดียว';
    end if;
  end if;
  return v;
end $$;

insert into news_posts (kind,title,summary,body,image,sort)
select 'event','ประลองครูบุ๊ค เปิดแล้ว!','8 รอบ 8 มินิเกม เวลาลดทุกรอบ ชนะรับ EXP + เหรียญ',
 E'โหมดใหม่ในแท็บ เกม: ท้าสู้ครูบุ๊คสุดโหด\n• 8 รอบ 8 มินิเกม สลับลำดับทุกครั้ง\n• มีหัวใจ 3 ดวง ตอบผิดเสียหัวใจ\n• สู้ใน 4 สนาม เปลี่ยนตามรอบ\n• ชนะรับ EXP และเหรียญ (มีเพดานต่อวัน)\n• ห้อง ม.1–3 ได้ชุดข้อสอบ ม.ต้น','assets/news/challenge.jpg',30
where not exists (select 1 from news_posts where title='ประลองครูบุ๊ค เปิดแล้ว!');
insert into news_posts (kind,title,summary,body,image,sort)
select 'news','ปรับระบบแรงค์ใหม่','เกณฑ์ไต่แรงค์ยากขึ้น เพื่อให้แต่ละขั้นมีความหมาย',
 E'เกณฑ์ EXP ใหม่: Bronze 250 · Silver 600 · Gold 1,100 · Platinum 1,800 · Emerald 2,700 · Diamond 3,900 · Master 5,400 · Grandmaster 7,200 · Challenger 9,500\nเลเวลไม่เปลี่ยน แต่แรงค์ของบางคนอาจลดลงจากเดิม ใครอยากไต่แรงค์ ทำเควส ส่งงาน และเล่นเกมสม่ำเสมอ','assets/news/rank.jpg',20
where not exists (select 1 from news_posts where title='ปรับระบบแรงค์ใหม่');
insert into news_posts (kind,title,summary,body,image,sort)
select 'news','ช่องอุปกรณ์ข้างตัวละคร','แตะช่องเพื่อสลับชุด เอฟเฟกต์ หมวก สัตว์เลี้ยง ได้ทันที',
 E'ที่หน้าหลัก ข้างตัวละครมี 8 ช่องอุปกรณ์: ชุด เอฟเฟกต์ ไอเทม หมวก สัตว์เลี้ยง กรอบ พื้นหลัง และฉายา\nแตะช่องไหนก็เลือกไอเทมที่มีอยู่มาใส่ได้เลย ไม่ต้องเข้าหน้าแต่งตัว','assets/news/equip.jpg',10
where not exists (select 1 from news_posts where title='ช่องอุปกรณ์ข้างตัวละคร');
-- 28: ไอเทมตกแต่งใหม่ 14 ชิ้น ธีมเคมี (หมวก 3 · สัตว์เลี้ยง 3 · ไอเทมถือ 3 · พื้นหลัง 2 · กรอบ 1 · ฉายา 2)
-- รันซ้ำได้ (เพิ่มเฉพาะที่ยังไม่มี) · ภาพอยู่ใน web/assets/hats|pets|items · ค่าสเตตัสครูแก้ได้ที่แท็บ "ตกแต่ง"
insert into decor_items (slot, key, name, emoji, rarity, price, sort, image, st_int, st_dil, st_str, st_luk, st_coin, ability)
select v.* from (values
  ('hat','img','หมวกพ่อมดธาตุ','🧙','SR',null,20,'assets/hats/wizard.png',2,0,0,1,0,'เวทมนตร์จากตารางธาตุ'),
  ('hat','img','มงกุฎลอเรลนักวิจัย','🌿','SSR',null,21,'assets/hats/laurel.png',2,1,0,1,0,'ผู้พิชิตการทดลองทุกครั้ง'),
  ('hat','img','หมวกบีกเกอร์ปั่น','🧪','N',100,22,'assets/hats/beaker.png',0,1,0,0,0,'ใส่แล้วขยันขึ้นนิดๆ'),
  ('pet','img','หุ่นยนต์จิ๋วผู้ช่วยแล็บ','🤖','R',220,20,'assets/pets/robot.png',1,1,0,0,0,'ช่วยจดผลการทดลอง'),
  ('pet','img','สไลม์สารเคมี','🟢','N',120,21,'assets/pets/slime.png',0,0,0,1,0,'เด้งดึ๋งนำโชค'),
  ('pet','img','ฟีนิกซ์น้อยเปลวเพลิง','🐦‍🔥','SSR',null,22,'assets/pets/phoenix.png',0,0,2,1,3,'เกิดใหม่จากเปลวไฟ'),
  ('item','img','หลอดหยดทองคำ','💧','N',90,30,'assets/items/dropper.png',1,0,0,0,0,'หยดเดียวก็แม่นยำ'),
  ('item','img','ตะเกียงแอลกอฮอล์เปลวฟ้า','🪔','R',150,31,'assets/items/lamp.png',0,0,1,1,0,'ให้ความร้อนพอดี'),
  ('item','img','เพชรคาร์บอน','💎','SSR',null,32,'assets/items/diamond.png',2,0,1,1,0,'คาร์บอนที่ทนแรงดันมาแล้ว'),
  ('bg','volcano','พื้นภูเขาไฟ','🌋','R',100,20,null,0,0,0,0,0,null),
  ('bg','crystal','พื้นถ้ำผลึก','💠','SR',null,21,null,0,0,0,0,0,null),
  ('frame','amethyst','กรอบอเมทิสต์','🔮','R',120,20,null,0,0,0,0,0,null),
  ('title','text','นักปั่นสมการ','📐','R',150,30,null,1,1,0,0,0,'สมดุลสมการแบบไม่ต้องคิดนาน'),
  ('title','text','ผู้รอดชีวิตจากปฏิกิริยา','⚡','SR',null,31,null,0,1,1,0,2,'ผ่านมาทุกการทดลองไม่มีหาย')
) v(slot,key,name,emoji,rarity,price,sort,image,st_int,st_dil,st_str,st_luk,st_coin,ability)
where not exists (select 1 from decor_items d where d.slot = v.slot and d.name = v.name);

-- ชิ้นที่ไม่ขายในร้านเข้ากาชา
insert into gacha_items (name, rarity, kind, value, emoji, weight, decor_id)
select d.name, d.rarity, 'decor', 0, d.emoji, case d.rarity when 'N' then 3 when 'R' then 2 else 1 end, d.id
  from decor_items d
 where d.name in ('หมวกพ่อมดธาตุ','มงกุฎลอเรลนักวิจัย','ฟีนิกซ์น้อยเปลวเพลิง','เพชรคาร์บอน','พื้นถ้ำผลึก','ผู้รอดชีวิตจากปฏิกิริยา')
   and not exists (select 1 from gacha_items g where g.decor_id = d.id);
-- 29: ชุดตัวละครใหม่ 2 แบบ (ชุดฮาซ์แมท / ชุดซามูไรเคมี) ครบ 5 คลาส · รันซ้ำได้
-- ภาพ: web/assets/chars/<คลาส>_<hazmat|samurai>.png
insert into decor_items (slot, key, name, emoji, rarity, price, sort, st_int, st_dil, st_str, st_luk, st_coin, ability)
select v.* from (values
  ('outfit','hazmat','ชุดป้องกันสารเคมี (ฮาซ์แมท)','☣️','R',300,6,1,1,1,0,0,'ปลอดภัยไว้ก่อน ทำแล็บได้มั่นใจ'),
  ('outfit','samurai','ชุดซามูไรนักเคมี','⚔️','SSR',null,7,1,1,2,1,0,'เกราะทองแห่งห้องแล็บ')
) v(slot,key,name,emoji,rarity,price,sort,st_int,st_dil,st_str,st_luk,st_coin,ability)
where not exists (select 1 from decor_items d where d.slot = v.slot and d.key = v.key);

insert into gacha_items (name, rarity, kind, value, emoji, weight, decor_id)
select d.name, d.rarity, 'decor', 0, d.emoji, 1, d.id
  from decor_items d
 where d.slot='outfit' and d.key = 'samurai'
   and not exists (select 1 from gacha_items g where g.decor_id = d.id);
-- 30: ประกาศข่าว "ไอเทมใหม่" บนสไลด์หน้าแรก (รันซ้ำได้) — ต้องรัน 27_news.sql ก่อน
insert into news_posts (kind,title,summary,body,image,sort)
select 'event','ไอเทมใหม่ 16 ชิ้น + ชุดตัวละครใหม่!','หมวก สัตว์เลี้ยง ไอเทมถือ พื้นหลัง กรอบ ฉายา และชุดซามูไร/ฮาซ์แมท',
 E'มาแล้ว! ไอเทมตกแต่งธีมเคมี\n• หมวก: พ่อมดธาตุ · มงกุฎลอเรลนักวิจัย · หมวกบีกเกอร์ปั่น\n• สัตว์เลี้ยง: หุ่นยนต์จิ๋ว · สไลม์สารเคมี · ฟีนิกซ์น้อย\n• ไอเทมถือ: หลอดหยดทอง · ตะเกียงแอลกอฮอล์ · เพชรคาร์บอน\n• พื้นหลังภูเขาไฟ/ถ้ำผลึก · กรอบอเมทิสต์ · ฉายาใหม่ 2 แบบ\n• ชุดใหม่: ฮาซ์แมท (ร้านค้า) และซามูไรนักเคมี (SSR จากกาชา)\n\nชิ้นที่ราคาเหรียญขายในแท็บ ตกแต่ง ส่วนชิ้นหายากต้องลุ้นจากแท็บ กาชา','assets/news/items.jpg',40
where not exists (select 1 from news_posts where title='ไอเทมใหม่ 16 ชิ้น + ชุดตัวละครใหม่!');
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
-- 32: แต้มสเตตัส (Status Point) — เลเวลอัพได้แต้ม แจกให้ ปัญญา/ขยัน/พลังโจมตี/โชค ได้เอง (รันซ้ำได้)
--  · แต้มทั้งหมด = (เลเวล − 1) × stat_pts_per_level (ค่าเริ่มต้น 2) · ใส่ได้ด้านละไม่เกิน stat_alloc_cap (ค่าเริ่มต้น 15)
--  · รีเซ็ตแต้มได้โดยเสียเหรียญ stat_reset_cost (ค่าเริ่มต้น 100) · แต้มที่ใส่นับรวมในทุกโบนัสผ่าน _stats()
insert into app_settings (key, value) values ('stat_pts_per_level', '2'), ('stat_alloc_cap', '15'), ('stat_reset_cost', '100') on conflict (key) do nothing;
alter table students add column if not exists stat_pts jsonb not null default '{}'::jsonb;

create or replace function _stats(p_sid uuid) returns json
language plpgsql stable security definer set search_path = public as $$
declare
  b_int int; b_dil int; b_str int; b_luk int;
  i_int int := 0; i_dil int := 0; i_str int := 0; i_luk int := 0; i_coin int := 0;
  p_int int; p_dil int; p_str int; p_luk int; cap int := _setting_int('stat_alloc_cap', 15);
  sp jsonb; lv int; tot int; per int := _setting_int('stat_pts_per_level', 2);
begin
  b_int := least(10, coalesce((select sum(correct) from game_plays where student_id = p_sid and game = 'quiz'), 0)::int / 8);
  b_dil := least(10, student_metric(p_sid, 'present_count') / 4);
  b_str := least(10, student_metric(p_sid, 'quests_done') / 8);
  b_luk := least(10, student_metric(p_sid, 'gacha_pulls') / 6);
  if coalesce((select is_gm from students where id = p_sid), false) then b_int := 10; b_dil := 10; b_str := 10; b_luk := 10; end if;
  select s.stat_pts, level_for(s.exp) into sp, lv from students s where s.id = p_sid;
  sp := coalesce(sp, '{}'::jsonb);
  p_int := least(cap, coalesce((sp->>'int')::int, 0)); p_dil := least(cap, coalesce((sp->>'dil')::int, 0));
  p_str := least(cap, coalesce((sp->>'str')::int, 0)); p_luk := least(cap, coalesce((sp->>'luk')::int, 0));
  tot := greatest(0, coalesce(lv, 1) - 1) * per;
  select coalesce(sum(d.st_int), 0), coalesce(sum(d.st_dil), 0), coalesce(sum(d.st_str), 0), coalesce(sum(d.st_luk), 0), coalesce(sum(d.st_coin), 0)
    into i_int, i_dil, i_str, i_luk, i_coin
    from students s
    cross join lateral jsonb_each_text(s.decor) e
    join decor_items d on d.id = e.value::uuid and d.slot = e.key
   where s.id = p_sid;
  return json_build_object(
    'int', json_build_object('base', b_int, 'pts', p_int, 'item', i_int, 'total', b_int + p_int + i_int),
    'dil', json_build_object('base', b_dil, 'pts', p_dil, 'item', i_dil, 'total', b_dil + p_dil + i_dil),
    'str', json_build_object('base', b_str, 'pts', p_str, 'item', i_str, 'total', b_str + p_str + i_str),
    'luk', json_build_object('base', b_luk, 'pts', p_luk, 'item', i_luk, 'total', b_luk + p_luk + i_luk),
    'points', json_build_object('total', tot, 'spent', p_int + p_dil + p_str + p_luk, 'left', greatest(0, tot - (p_int + p_dil + p_str + p_luk)),
                                'cap', cap, 'per_level', per, 'reset_cost', _setting_int('stat_reset_cost', 100)),
    'effects', json_build_object('quiz_exp', (b_int + p_int + i_int) / 2, 'exp_pct', b_dil + p_dil + i_dil,
                                 'boss_pct', 3 * (b_str + p_str + i_str), 'rare_pct', 3 * (b_luk + p_luk + i_luk), 'coin_pct', i_coin));
end $$;
revoke execute on function _stats(uuid) from public, anon, authenticated;

-- เพิ่มแต้มให้สเตตัส 1 ด้าน (p_stat = int|dil|str|luk) ครั้งละ p_n แต้ม
create or replace function stat_add(p_token uuid, p_stat text, p_n int default 1) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); st json; left_ int; cur int; cap int := _setting_int('stat_alloc_cap', 15);
begin
  if p_stat not in ('int','dil','str','luk') then raise exception 'สเตตัสไม่ถูกต้อง'; end if;
  if p_n is null or p_n < 1 or p_n > 20 then raise exception 'จำนวนแต้มไม่ถูกต้อง'; end if;
  perform 1 from students where id = sid for update;
  st := _stats(sid); left_ := (st->'points'->>'left')::int; cur := (st->p_stat->>'pts')::int;
  if left_ < p_n then raise exception 'แต้มสเตตัสไม่พอ'; end if;
  if cur + p_n > cap then raise exception 'ด้านนี้ใส่ได้สูงสุด % แต้ม', cap; end if;
  update students set stat_pts = jsonb_set(coalesce(stat_pts, '{}'::jsonb), array[p_stat], to_jsonb(cur + p_n)) where id = sid;
  return _stats(sid);
end $$;

-- รีเซ็ตแต้มที่ใส่ไว้ทั้งหมด (เสียเหรียญ)
create or replace function stat_reset(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cost int := _setting_int('stat_reset_cost', 100); have int; st json;
begin
  perform 1 from students where id = sid for update;
  st := _stats(sid);
  if (st->'points'->>'spent')::int = 0 then raise exception 'ยังไม่ได้ใส่แต้มสเตตัส'; end if;
  select coins into have from students where id = sid;
  if have < cost then raise exception 'เหรียญไม่พอ (ต้องใช้ % เหรียญ)', cost; end if;
  perform award(sid, 0, -cost, 'รีเซ็ตแต้มสเตตัส', 'statreset:' || sid || ':' || extract(epoch from clock_timestamp())::bigint || ':' || floor(random()*1e6)::int);
  update students set stat_pts = '{}'::jsonb where id = sid;
  return _stats(sid);
end $$;

revoke execute on function stat_add(uuid, text, int), stat_reset(uuid) from public;
grant execute on function stat_add(uuid, text, int), stat_reset(uuid) to anon, authenticated;
-- 33: เควสวันนี้แสดงเฉพาะเควสที่ระบบเช็คอัตโนมัติ (รันซ้ำได้)
--  · ตั้งค่า quests_auto_only = 1 (ค่าเริ่มต้น) → นักเรียนเห็นเฉพาะเควสอัตโนมัติ · ตั้งเป็น 0 เพื่อกลับไปแสดงเควสที่กดขอรับรางวัล (รายวันสุ่ม + รายสัปดาห์) ด้วย
insert into app_settings (key, value) values ('quests_auto_only', '1') on conflict (key) do nothing;

create or replace function todays_quests(p_class uuid, p_date date)
returns setof quests language sql stable security definer set search_path = public as $$
  (select * from quests
    where active and auto_trigger is null and kind = 'daily' and (class_id is null or class_id = p_class)
      and coalesce((select value from app_settings where key = 'quests_auto_only'), '1') <> '1'
    order by md5(id::text || p_date::text)
    limit coalesce((select value::int from app_settings where key = 'daily_quest_count'), 3))
  union all
  (select * from quests
    where active and auto_trigger is null and kind = 'weekly' and (class_id is null or class_id = p_class)
      and coalesce((select value from app_settings where key = 'quests_auto_only'), '1') <> '1')
  union all
  (select * from quests
    where active and auto_trigger is not null and (class_id is null or class_id = p_class))
$$;
revoke execute on function todays_quests(uuid, date) from public, anon, authenticated;
-- รอบ 53: บอสประจำสัปดาห์ — ความสามารถของบอส + รายชื่อผู้โจมตีทั้งห้อง
alter table bosses add column if not exists abilities jsonb;

update bosses set abilities = '[{"icon": "🧪", "name": "พ่นกรดกัดกร่อน", "desc": "ละลายเกราะของนักเรียนที่ขี้เกียจ ใครทำเควสไม่ครบจะถูกมังกรเยาะเย้ย"}, {"icon": "🔥", "name": "เกล็ดทนไฟ", "desc": "เกล็ดป้องกันความร้อนสูง ต้องสะสมการโจมตีต่อเนื่องหลายวัน"}, {"icon": "☁️", "name": "ไอกรดหมอกหนา", "desc": "ซ่อนตัวในหมอกกรด โจมตีให้ทุกวันถึงจะเห็นจุดอ่อน"}]'::jsonb where name = 'มังกรกรดซัลฟิวริก' and abilities is null;
update bosses set abilities = '[{"icon": "🟣", "name": "ของเหลวเดือดพล่าน", "desc": "ยิ่งโดนโจมตีมาก ของเหลวยิ่งเดือด จนแตกกระจายในที่สุด"}, {"icon": "🛡️", "name": "กระจกบอโรซิลิเกต", "desc": "ทนทานสูง ต้องช่วยกันทั้งห้องจึงจะทำลายได้"}, {"icon": "☠️", "name": "ไอพิษม่วง", "desc": "ทำให้ผู้ที่หยุดทำเควสเสียสมาธิ"}]'::jsonb where name = 'โกเลมบีกเกอร์พิษ' and abilities is null;
update bosses set abilities = '[{"icon": "⚡", "name": "สายฟ้าวงโคจร", "desc": "ปล่อยสายฟ้าตามวงโคจร ป้องกันได้เฉพาะคนที่ไม่ขยัน"}, {"icon": "🌀", "name": "ควอนตัมเทเลพอร์ต", "desc": "หลบการโจมตีที่ไม่สม่ำเสมอ ต้องทำเควสทุกวัน"}, {"icon": "🔋", "name": "ดูดพลังงาน", "desc": "ดูดพลังงานจากห้องที่เงียบเหงา"}]'::jsonb where name = 'จอมเวทอิเล็กตรอน' and abilities is null;
update bosses set abilities = '[{"icon": "🧱", "name": "เกราะตารางธาตุ", "desc": "เกราะแต่ละแผ่นคือธาตุหนึ่ง ต้องใช้ความรู้เคมีจึงจะพังได้"}, {"icon": "⚙️", "name": "ระบบซ่อมตัวเอง", "desc": "ฟื้นฟูตัวเองหากห้องหยุดโจมตี"}, {"icon": "📡", "name": "สแกนจุดอ่อน", "desc": "เปิดจุดอ่อนให้ผู้ที่ทำควิซเต็ม"}]'::jsonb where name = 'หุ่นยนต์ธาตุจักรกล' and abilities is null;
update bosses set abilities = '[{"icon": "🔥", "name": "เปลวไฟลุกลาม", "desc": "ยิ่งปล่อยไว้นาน ไฟยิ่งแรง รีบสะสมเควสให้ครบ"}, {"icon": "💨", "name": "ควันพราง", "desc": "ซ่อนตัวในควัน ต้องโจมตีต่อเนื่อง"}, {"icon": "🧯", "name": "แพ้การสะสม", "desc": "ดับได้ด้วยการทำเควสพร้อมกันทั้งห้อง"}]'::jsonb where name = 'ปีศาจตะเกียงเพลิง' and abilities is null;
update bosses set abilities = '[{"icon": "🦠", "name": "แพร่พันธุ์", "desc": "งอกหัวใหม่ทุกวันที่ห้องไม่โจมตี"}, {"icon": "🔬", "name": "แปดตาจุลทรรศน์", "desc": "มองเห็นทุกการโจมตี ไม่มีใครหลบหน้าที่ได้"}, {"icon": "🤝", "name": "อ่อนแอต่อความร่วมมือ", "desc": "ต้องช่วยกันทั้งห้องถึงจะปราบได้"}]'::jsonb where name = 'ไฮดราเชื้อโรคแปดตา' and abilities is null;

create or replace function boss_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cls uuid; b bosses%rowtype; n int; mx int; dmg int; mine int; end_d date; done boolean; claimed boolean;
begin
  select class_id into cls from students where id = sid;
  b := _boss_for(cls);
  if b.id is null then return null; end if;
  select count(*) into n from students where class_id = cls;
  mx := b.hp_per_student * greatest(n, 1);
  dmg := _boss_damage(b, cls);
  mine := _boss_damage(b, cls, sid);
  end_d := b.start_date + b.days - 1;
  done := dmg >= mx;
  claimed := exists (select 1 from ledger where student_id = sid and ref_key = 'boss:' || b.id);
  return json_build_object(
    'id', b.id, 'name', b.name, 'emoji', b.emoji, 'image', b.image, 'description', b.description,
    'max_hp', mx, 'damage', least(dmg, mx), 'hp', greatest(mx - dmg, 0), 'defeated', done,
    'my_damage', mine, 'start', b.start_date, 'end', end_d, 'ended', today_th() > end_d,
    'days_left', greatest(end_d - today_th() + 1, 0),
    'reward_exp', b.reward_exp, 'reward_coins', b.reward_coins,
    'abilities', coalesce(b.abilities, '[]'::jsonb),
    'claimed', claimed, 'can_claim', done and mine > 0 and not claimed,
    'top', (select coalesce(json_agg(x), '[]'::json) from (
        select st.name, sum(coalesce(cl.dmg, greatest(q.exp, 1)))::int as dmg, (st.id = sid) as me
          from quest_claims cl join quests q on q.id = cl.quest_id join students st on st.id = cl.student_id
         where st.class_id = cls and cl.status = 'approved'
           and cl.claim_date between b.start_date and end_d
         group by st.id, st.name order by sum(coalesce(cl.dmg, greatest(q.exp, 1))) desc limit 5) x),
    'attackers', (select coalesce(json_agg(x), '[]'::json) from (
        select st.name, sum(coalesce(cl.dmg, greatest(q.exp, 1)))::int as dmg, count(*)::int as hits, (st.id = sid) as me
          from quest_claims cl join quests q on q.id = cl.quest_id join students st on st.id = cl.student_id
         where st.class_id = cls and cl.status = 'approved'
           and cl.claim_date between b.start_date and end_d
         group by st.id, st.name order by sum(coalesce(cl.dmg, greatest(q.exp, 1))) desc, st.name) x));
end $$;
-- 35: ประกาศมินิเกม "เคมีรัน" บนสไลด์ข่าวหน้าแรก (รันซ้ำได้) — ต้องรัน 27_news.sql ก่อน
insert into news_posts (kind,title,summary,body,image,sort)
select 'event','มินิเกมใหม่! เคมีรัน 🏃','วิ่งเก็บเหรียญ กระโดดหลบอุปสรรคแล็บ สไลด์ใต้เมฆพิษ แต่งตัวละครของคุณวิ่งได้เลย',
 E'เคมีรัน มินิเกมสไตล์วิ่งไม่หยุด เปิดแล้วที่แท็บเกม!\n• แตะ/กด = กระโดด (กระโดดซ้ำได้ 2 ครั้งกลางอากาศ) · ปุ่มสไลด์ = มุดใต้เมฆพิษ\n• เก็บเหรียญ แผ่นธาตุ ยาเติมพลัง และดาว หลบเตาไฟกับชั้นหลอดทดลอง\n• ตัวละครที่วิ่งคือชุดที่คุณใส่อยู่ มีสัตว์เลี้ยงวิ่งตามด้วย\n• เล่นได้วันละ 3 รอบ ได้ EXP และเหรียญตามคะแนน ยิ่งวิ่งไกลยิ่งได้เยอะ\nไปทำลายสถิติกันเลย!',
 'assets/news/run.jpg', 10
where not exists (select 1 from news_posts where title='มินิเกมใหม่! เคมีรัน 🏃');
-- 36: ตารางสอนรายห้อง → ขึ้นในปฏิทินนักเรียน (ภาคเรียน 2/2569 ใช้ตั้งแต่ 2 พ.ย. 2569) · รันซ้ำได้
create table if not exists timetable (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references classes(id) on delete cascade,
  dow int not null check (dow between 1 and 7),     -- 1=จันทร์ ... 7=อาทิตย์
  start_time text not null,                          -- เช่น 08:40
  end_time text not null,                            -- เช่น 09:30
  period text,                                       -- เช่น คาบ 1-2
  title text not null,
  room text,
  effective_from date not null default '2026-11-02',
  effective_to date,
  active boolean not null default true,
  unique (class_id, dow, start_time)
);
alter table timetable enable row level security;
drop policy if exists teacher_all on timetable;
create policy teacher_all on timetable for all using (is_teacher()) with check (is_teacher());
revoke all on timetable from anon;

insert into timetable (class_id, dow, start_time, end_time, period, title, room)
select c.id, v.d, v.s, v.e, v.p, v.t, v.r
  from (values
    ('ม.6/6', 1, '11:10', '12:00', 'คาบ 4',   'เคมี 6 (ว33226)', '734'),
    ('ม.6/6', 4, '10:20', '12:00', 'คาบ 3-4', 'เคมี 6 (ว33226)', '734'),
    ('ม.1/1', 1, '13:40', '15:20', 'คาบ 7-8', 'เคมี 2 (ว21202)', '716'),
    ('ม.1/1', 2, '09:30', '10:20', 'คาบ 2',   'เคมี 2 (ว21202)', '716'),
    ('ม.6/4', 2, '10:20', '12:00', 'คาบ 3-4', 'เคมี 6 (ว33226)', '734'),
    ('ม.6/4', 5, '13:40', '14:30', 'คาบ 7',   'เคมี 6 (ว33226)', '734'),
    ('ม.6/2', 3, '08:40', '10:20', 'คาบ 1-2', 'เคมี 6 (ว33226)', '734'),
    ('ม.6/2', 5, '10:20', '11:10', 'คาบ 3',   'เคมี 6 (ว33226)', '734'),
    ('ม.6/5', 3, '13:40', '14:30', 'คาบ 7',   'เคมี 6 (ว33226)', '734'),
    ('ม.6/5', 5, '08:40', '10:20', 'คาบ 1-2', 'เคมี 6 (ว33226)', '734')
  ) v(cn, d, s, e, p, t, r)
  join classes c on c.name = v.cn
on conflict (class_id, dow, start_time) do nothing;

create or replace function timetable_list(p_token uuid) returns json
language plpgsql stable security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  return coalesce((select json_agg(json_build_object('dow', t.dow, 'start', t.start_time, 'end', t.end_time,
      'period', t.period, 'title', t.title, 'room', t.room, 'from', t.effective_from, 'to', t.effective_to)
      order by t.dow, t.start_time)
    from timetable t join students s on s.class_id = t.class_id
   where s.id = sid and t.active), '[]'::json);
end $$;
revoke execute on function timetable_list(uuid) from public;
grant execute on function timetable_list(uuid) to anon, authenticated;

-- ให้ผู้สังเกตการณ์ (โหมดส่อง) เรียก timetable_list ได้
create or replace function _sid(p_token uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare v uuid; o boolean; fn text;
begin
  select student_id, observer into v, o from student_sessions where token = p_token and expires_at > now();
  if v is null then raise exception 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่'; end if;
  if o then
    fn := regexp_replace(coalesce(current_setting('request.path', true), ''), '^.*/', '');
    if fn not in ('student_dashboard','student_extras','hall_of_fame','board_list','celebrations_feed','game_status','spell_status','kb_status','news_list','run_status','timetable_list') then
      raise exception 'โหมดส่องนักเรียน: ดูได้อย่างเดียว';
    end if;
  end if;
  return v;
end $$;
-- 37: โปรโมชันเปิดระบบใหม่ (รันซ้ำได้) — ต้องรัน 09_stats.sql ก่อน
--  · ของขวัญเปิดระบบ (รับได้คนละ 1 ครั้ง): เหรียญ 50 + EXP 20 + ตั๋วกาชาฟรี 1 ใบ
--  · โบนัส EXP +25% (ค่าตั้งต้น) จากเช็คชื่อ/ส่งงาน/เควส ระหว่างโปร
--  ตั้งค่าได้ในแอดมิน → ตั้งค่า: promo_on, promo_until, promo_exp_pct, promo_coins, promo_exp, promo_pulls
insert into app_settings (key, value) values
  ('promo_on', '1'), ('promo_exp_pct', '25'), ('promo_coins', '50'), ('promo_exp', '20'), ('promo_pulls', '1'),
  ('promo_until', to_char(today_th() + 7, 'YYYY-MM-DD'))
on conflict (key) do nothing;

create or replace function _promo_until() returns date
language sql stable security definer set search_path = public as $$
  select case when coalesce((select value from app_settings where key = 'promo_on'), '0') = '1'
              then nullif((select value from app_settings where key = 'promo_until'), '')::date end
$$;
create or replace function _promo_pct() returns int
language sql stable security definer set search_path = public as $$
  select case when _promo_until() >= today_th() then greatest(0, _setting_int('promo_exp_pct', 0)) else 0 end
$$;
revoke execute on function _promo_until() from public, anon, authenticated;
revoke execute on function _promo_pct() from public, anon, authenticated;

create or replace function award(p_student uuid, p_exp int, p_coins int, p_reason text, p_ref text default null)
returns boolean language plpgsql security definer set search_path = public as $$
declare v uuid; pp int; cls text; e int := p_exp; c int := p_coins; rs text := p_reason; dil int; e2 int; cp int; c2 int;
begin
  -- ความสามารถคลาส: โบนัสเฉพาะรางวัลจากเช็คชื่อ / ส่งงาน / เควส
  if p_ref ~ '^(att|sub|quest):' then
    cls := student_class(p_student);
    if cls = 'scientist' and e > 0 then e := ceil(e * 1.15)::int; rs := rs || ' (โบนัสนักทดลอง)'; end if;
    if cls = 'alchemist' and c > 0 then c := ceil(c * 1.25)::int; rs := rs || ' (โบนัสนักเล่นแร่แปรธาตุ)'; end if;
    -- สเตตัสความขยัน: +1% ต่อแต้ม (เฉพาะรางวัลเช็คชื่อ/ส่งงาน/เควส)
    if e > 0 then
      dil := coalesce((_stats(p_student)->'dil'->>'total')::int, 0);
      e2 := round(e * (1 + dil / 100.0))::int;
      if e2 > e then e := e2; rs := rs || ' (ขยัน +' || dil || '%)'; end if;
    end if;
    -- โปรโมชัน: โบนัส EXP % (ตั้งใน app_settings: promo_exp_pct / promo_until)
    pp := _promo_pct();
    if pp > 0 and e > 0 then e := round(e * (1 + pp / 100.0))::int; rs := rs || ' (โปรเปิดระบบ +' || pp || '%)'; end if;
    -- ความสามารถฉายา/ไอเทม: โบนัสเหรียญ %
    if c > 0 then
      cp := coalesce((_stats(p_student)->'effects'->>'coin_pct')::int, 0);
      c2 := round(c * (1 + cp / 100.0))::int;
      if c2 > c then c := c2; rs := rs || ' (เหรียญ +' || cp || '%)'; end if;
    end if;
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
revoke execute on function award(uuid, int, int, text, text) from public, anon, authenticated;

create or replace function promo_status(p_token uuid) returns json
language plpgsql stable security definer set search_path = public as $$
declare sid uuid := _sid(p_token); u date := _promo_until();
begin
  if u is null or u < today_th() then return json_build_object('active', false); end if;
  return json_build_object('active', true, 'until', u, 'days_left', u - today_th() + 1,
    'pct', _promo_pct(),
    'gift', json_build_object('coins', _setting_int('promo_coins', 0), 'exp', _setting_int('promo_exp', 0), 'pulls', _setting_int('promo_pulls', 0)),
    'claimed', exists (select 1 from ledger where student_id = sid and ref_key = 'promo:launch'));
end $$;

create or replace function promo_claim(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); u date := _promo_until(); c int := _setting_int('promo_coins', 0);
        e int := _setting_int('promo_exp', 0); pl int := _setting_int('promo_pulls', 0); ok boolean;
begin
  if u is null or u < today_th() then raise exception 'โปรโมชันนี้สิ้นสุดแล้ว'; end if;
  ok := award(sid, e, c, 'ของขวัญเปิดระบบใหม่ 🎁', 'promo:launch');
  if not ok then raise exception 'รับของขวัญไปแล้ว'; end if;
  if pl > 0 then update students set free_pulls = free_pulls + pl where id = sid; end if;
  return json_build_object('coins', c, 'exp', e, 'pulls', pl);
end $$;
revoke execute on function promo_status(uuid) from public;
revoke execute on function promo_claim(uuid) from public;
grant execute on function promo_status(uuid) to anon, authenticated;
grant execute on function promo_claim(uuid) to anon, authenticated;

-- ให้ผู้สังเกตการณ์ (โหมดส่อง) เรียก promo_status ได้
create or replace function _sid(p_token uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare v uuid; o boolean; fn text;
begin
  select student_id, observer into v, o from student_sessions where token = p_token and expires_at > now();
  if v is null then raise exception 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่'; end if;
  if o then
    fn := regexp_replace(coalesce(current_setting('request.path', true), ''), '^.*/', '');
    if fn not in ('student_dashboard','student_extras','hall_of_fame','board_list','celebrations_feed','game_status','spell_status','kb_status','news_list','run_status','timetable_list','promo_status') then
      raise exception 'โหมดส่องนักเรียน: ดูได้อย่างเดียว';
    end if;
  end if;
  return v;
end $$;

-- ประกาศบนสไลด์ข่าว
insert into news_posts (kind, title, summary, body, image, sort, ends_at)
select 'event', 'โปรโมชันเปิดระบบใหม่ Chemistria! 🎉', 'รับของขวัญต้อนรับฟรี + โบนัส EXP +25% จากเช็คชื่อ ส่งงาน และเควส ช่วงเปิดตัว',
 E'ฉลองเปิดระบบ Chemistria ใหม่!\n🎁 ของขวัญต้อนรับ: กดรับที่หน้าหลักได้คนละ 1 ครั้ง (เหรียญ + EXP + ตั๋วสุ่มกาชาฟรี)\n⚡ โบนัส EXP +25% จากเช็คชื่อ ส่งงาน และเควส ตลอดช่วงโปร\nรีบกดรับก่อนโปรหมดนะ!',
 'assets/news/promo.jpg', 20, nullif((select value from app_settings where key = 'promo_until'), '')::date
where not exists (select 1 from news_posts where title = 'โปรโมชันเปิดระบบใหม่ Chemistria! 🎉');
-- 38: ซ่อนห้องทดสอบ (GM) ออกจากอันดับ "ห้องแข่งห้อง" (รันซ้ำได้) — ต้องรัน 08 และ 15 ก่อน
create or replace function team_board(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); s students%rowtype; wk date := date_trunc('week', today_th())::date; r json;
begin
  select * into s from students where id = sid;
  select json_build_object(
    'week_start', wk,
    'my_team', s.team_id,
    'teams', (select coalesce(json_agg(t order by t.avg_week desc, t.exp_week desc, t.name), '[]'::json) from (
        select tm.id, tm.name, tm.emoji, (tm.id = s.team_id) as mine,
               count(st.id)::int as members,
               coalesce(sum(w.x), 0)::int as exp_week,
               case when count(st.id) = 0 then 0 else round(coalesce(sum(w.x), 0)::numeric / count(st.id), 1) end as avg_week,
               (select coalesce(json_agg(json_build_object('name', m.name, 'exp_week', coalesce(mw.x, 0), 'me', m.id = sid)
                        order by coalesce(mw.x, 0) desc, m.no), '[]'::json)
                  from students m
                  left join lateral (select sum(l.exp)::int as x from ledger l
                       where l.student_id = m.id and (l.created_at at time zone 'Asia/Bangkok')::date >= wk) mw on true
                 where m.team_id = tm.id and tm.id = s.team_id) as roster
          from teams tm
          left join students st on st.team_id = tm.id
          left join lateral (select sum(l.exp) as x from ledger l
               where l.student_id = st.id and (l.created_at at time zone 'Asia/Bangkok')::date >= wk) w on true
         where tm.class_id = s.class_id
         group by tm.id, tm.name, tm.emoji
    ) t),
    'rooms', (select coalesce(json_agg(x order by x.avg_week desc), '[]'::json) from (
        select c.name, (c.id = s.class_id) as mine, count(st.id)::int as students,
               case when count(st.id) = 0 then 0 else round(coalesce(sum(w.x), 0)::numeric / count(st.id), 1) end as avg_week
          from classes c
          left join students st on st.class_id = c.id
          left join lateral (select sum(l.exp) as x from ledger l
               where l.student_id = st.id and (l.created_at at time zone 'Asia/Bangkok')::date >= wk) w on true
         where (not c.hidden or c.id = s.class_id)   -- ซ่อนห้องทดสอบ (GM) จากอันดับห้อง ยกเว้นตัวเองอยู่ในห้องนั้น
         group by c.id, c.name
        having count(st.id) > 0
    ) x)
  ) into r;
  return r;
end $$;
-- 39: ตรวจสุขภาพระบบ (เฉพาะครู) + เก็บกวาดสิทธิ์ (รันซ้ำได้)
-- 1) เก็บกวาดสิทธิ์: view สมุดคะแนนไม่ให้ anon แตะเลย (เดิมปลอดภัยอยู่แล้วเพราะ security_invoker + RLS แต่ปิดซ้ำอีกชั้น)
revoke all on v_gradebook from anon;
-- 2) health_check(): ส่งรายการตรวจ [{key,label,level,count,detail}] level = ok | warn | bad
create or replace function health_check() returns json
language plpgsql stable security definer set search_path = public as $$
declare out jsonb := '[]'; n int; missing text; fn text;
  need text[] := array['student_login','student_dashboard','student_extras','game_status','quiz_today','quiz_submit','match_submit',
    'spell_status','spell_submit','kb_status','kb_submit','run_status','run_submit','battle_start','battle_answer','battle_defend',
    'duel_lobby','duel_state','gacha_pull','boss_status','boss_claim','news_list','timetable_list','promo_status','hall_of_fame',
    'board_list','team_board','claim_quest','submit_assignment','buy_decor','buy_privilege','admin_adjust','admin_mark_attendance'];
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;

  -- ข้อมูลเพี้ยน
  select count(*) into n from students where exp < 0 or coins < 0 or coalesce(free_pulls,0) < 0;
  out := out || jsonb_build_object('key','neg','label','ตัวเลขติดลบ (EXP/เหรียญ/ตั๋วกาชา)','level',case when n>0 then 'bad' else 'ok' end,'count',n,'detail','ควรเป็น 0');
  select count(*) into n from (select s.id from students s left join ledger l on l.student_id=s.id group by s.id, s.exp having s.exp <> greatest(0, coalesce(sum(l.exp),0))) x;
  out := out || jsonb_build_object('key','ledger','label','EXP ในตัวนักเรียนไม่ตรงกับยอดรวมในบัญชีรางวัล','level',case when n>0 then 'warn' else 'ok' end,'count',n,'detail','อาจเกิดจากครูแก้ตัวเลขตรงๆ หรือถูกปัดเป็น 0');
  select count(*) into n from students where pin_hash is null;
  out := out || jsonb_build_object('key','nopin','label','นักเรียนที่ยังไม่มี PIN','level',case when n>0 then 'warn' else 'ok' end,'count',n,'detail','เข้าสู่ระบบไม่ได้จนกว่าจะตั้ง PIN');
  select count(*) into n from students where locked_until is not null and locked_until > now();
  out := out || jsonb_build_object('key','locked','label','บัญชีที่ถูกล็อกชั่วคราว (ใส่ PIN ผิดหลายครั้ง)','level',case when n>0 then 'warn' else 'ok' end,'count',n,'detail','ปลดเองใน 10 นาที');
  select count(*) into n from students where class_id is null or not exists (select 1 from classes c where c.id = students.class_id);
  out := out || jsonb_build_object('key','orphan','label','นักเรียนที่ไม่มีห้อง','level',case when n>0 then 'bad' else 'ok' end,'count',n,'detail','');
  select count(*) into n from (select class_id, no from students group by 1,2 having count(*) > 1) x;
  out := out || jsonb_build_object('key','dupno','label','เลขที่ซ้ำในห้องเดียวกัน','level',case when n>0 then 'bad' else 'ok' end,'count',n,'detail','ทำให้ล็อกอินสับสน');

  -- เซสชัน
  select count(*) into n from student_sessions where expires_at < now() - interval '30 days';
  out := out || jsonb_build_object('key','oldsess','label','เซสชันหมดอายุเกิน 30 วัน (ควรลบ)','level',case when n>500 then 'warn' else 'ok' end,'count',n,'detail','กดล้างได้ในหน้านี้');
  select count(*) into n from student_sessions where observer and expires_at > now();
  out := out || jsonb_build_object('key','peek','label','เซสชันโหมดส่องที่ยังใช้ได้อยู่','level','ok','count',n,'detail','ดูอย่างเดียว');

  -- ฟังก์ชันที่ระบบต้องใช้
  select string_agg(f, ', ') into missing from unnest(need) f where not exists (select 1 from pg_proc p where p.proname = f and p.pronamespace = 'public'::regnamespace);
  out := out || jsonb_build_object('key','rpc','label','ฟังก์ชันหลักที่ขาดหาย (ยังไม่ได้รัน SQL ครบ)','level',case when missing is not null then 'bad' else 'ok' end,'count',coalesce(array_length(string_to_array(missing, ', '),1),0),'detail',coalesce(missing,''));

  -- ตั้งค่า
  select count(*) into n from app_settings where key in ('promo_on') and value = '1' and (select value from app_settings where key='promo_until') < to_char(today_th(),'YYYY-MM-DD');
  out := out || jsonb_build_object('key','promo','label','โปรโมชันเปิดอยู่แต่เลยวันสิ้นสุดแล้ว','level',case when n>0 then 'warn' else 'ok' end,'count',n,'detail','ปิด promo_on หรือขยายวัน');
  select count(*) into n from news_posts where ends_at is not null and ends_at < today_th();
  out := out || jsonb_build_object('key','oldnews','label','ประกาศที่หมดอายุแล้ว (ยังค้างในตาราง)','level','ok','count',n,'detail','ไม่แสดงให้นักเรียนอยู่แล้ว');
  select count(*) into n from bosses where coalesce(active,true);
  out := out || jsonb_build_object('key','boss','label','บอสที่เปิดใช้งาน','level',case when n=0 then 'warn' else 'ok' end,'count',n,'detail','ควรมีอย่างน้อย 1');

  return json_build_object('checked_at', now(), 'items', out);
end $$;
revoke execute on function health_check() from public, anon;
grant execute on function health_check() to authenticated;

-- 3) ล้างเซสชันเก่า (เฉพาะครู)
create or replace function admin_purge_sessions() returns int
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  delete from student_sessions where expires_at < now() - interval '7 days';
  get diagnostics n = row_count;
  return n;
end $$;
revoke execute on function admin_purge_sessions() from public, anon;
grant execute on function admin_purge_sessions() to authenticated;
-- =====================================================================
-- 40: ชุดข้อสอบ/แบบฝึกหัดเคมี ม.ต้น + เกร็ดความรู้ 200 ข้อ สำหรับห้อง ม.1/1
-- ใส่เป็นคำถามเฉพาะห้อง (class_id = ม.1/1) → ควิซประจำวันของ ม.1/1 จะสุ่มจากชุดนี้ก่อน
-- (ห้องอื่นไม่เห็น) · รันซ้ำได้ ข้ามข้อที่มีอยู่แล้ว · ถ้าไม่มีห้องชื่อ "ม.1/1" จะไม่เพิ่มอะไร
-- หัวข้อ: สมบัติของสาร · ธาตุ/สารประกอบ/สารผสม · การแยกสารและสารละลาย · ตารางธาตุ · อะตอมเบื้องต้น
--        กรด-เบส · การเปลี่ยนแปลงทางกายภาพ/เคมี · ความปลอดภัยในห้องปฏิบัติการ · เคมีในชีวิตประจำวัน · เกร็ดความรู้
-- answer: 0=ก 1=ข 2=ค 3=ง · แก้ไข/ปิดข้อ ได้ที่แอดมิน → เกม → คลังคำถามควิซ
-- =====================================================================
insert into quiz_questions (topic, question, a, b, c, d, answer, explain, class_id, active)
select v.topic, v.question, v.a, v.b, v.c, v.d, v.answer, v.explain, c.id, true
from (values
  ('สมบัติของสารและสถานะ','สถานะใดของสารที่มีรูปร่างเปลี่ยนตามภาชนะ แต่ปริมาตรคงที่','ของแข็ง','ของเหลว','แก๊ส','พลาสมา',1,'ของเหลวไหลได้ เปลี่ยนรูปร่างตามภาชนะ แต่ปริมาตรแทบไม่เปลี่ยน'),
  ('สมบัติของสารและสถานะ','สถานะใดของสารที่อนุภาคอยู่ห่างกันมากที่สุด','ผลึก','ของเหลว','แก๊ส','ของแข็ง',2,'อนุภาคแก๊สอยู่ห่างกันมาก เคลื่อนที่อิสระ จึงอัดให้เล็กลงได้'),
  ('สมบัติของสารและสถานะ','การที่ลูกอมการบูรหายไปเองโดยไม่ละลายเป็นของเหลวก่อน เรียกว่าอะไร','การระเหิด','การเยือกแข็ง','การควบแน่น','การหลอมเหลว',0,'การระเหิดคือของแข็งเปลี่ยนเป็นแก๊สโดยตรง'),
  ('สมบัติของสารและสถานะ','การที่น้ำเปลี่ยนเป็นน้ำแข็ง เรียกว่าอะไร','การระเหย','การหลอมเหลว','การแข็งตัว','การควบแน่น',2,'ของเหลวเปลี่ยนเป็นของแข็งเรียกว่าการแข็งตัว (เยือกแข็ง)'),
  ('สมบัติของสารและสถานะ','จุดเดือดของน้ำบริสุทธิ์ที่ความดัน 1 บรรยากาศ คือกี่องศาเซลเซียส','0','50','100','212',2,'น้ำเดือดที่ 100 °C ที่ระดับน้ำทะเล'),
  ('สมบัติของสารและสถานะ','จุดหลอมเหลวของน้ำแข็งบริสุทธิ์ที่ความดัน 1 บรรยากาศ คือกี่องศาเซลเซียส','100','32','-10','0',3,'น้ำแข็งหลอมเหลวที่ 0 °C'),
  ('สมบัติของสารและสถานะ','ความหนาแน่นหาได้จากสูตรใด','มวล + ปริมาตร','ปริมาตร ÷ มวล','มวล ÷ ปริมาตร','มวล × ปริมาตร',2,'ความหนาแน่น = มวล / ปริมาตร'),
  ('สมบัติของสารและสถานะ','ไม้ลอยน้ำได้เพราะอะไร','มีมวลน้อยเสมอ','มีสีอ่อนกว่าน้ำ','ความหนาแน่นมากกว่าน้ำ','ความหนาแน่นน้อยกว่าน้ำ',3,'วัตถุที่หนาแน่นน้อยกว่าของเหลวจะลอย'),
  ('สมบัติของสารและสถานะ','ข้อใดเป็นสมบัติทางกายภาพของสาร','การติดไฟ','จุดเดือด','การเน่าเสีย','การเกิดสนิม',1,'จุดเดือดวัดได้โดยไม่ทำให้สารเปลี่ยนเป็นสารใหม่'),
  ('สมบัติของสารและสถานะ','ข้อใดเป็นสมบัติทางเคมีของสาร','สี','จุดหลอมเหลว','การติดไฟ','ความแข็ง',2,'การติดไฟทำให้เกิดสารใหม่ จึงเป็นสมบัติทางเคมี'),
  ('สมบัติของสารและสถานะ','สารใดนำไฟฟ้าได้ดีที่สุดในข้อต่อไปนี้','พลาสติก','ไม้','ยาง','ทองแดง',3,'โลหะนำไฟฟ้าได้ดี ทองแดงจึงใช้ทำสายไฟ'),
  ('สมบัติของสารและสถานะ','ข้อใดเป็นฉนวนไฟฟ้า','อะลูมิเนียม','ทองแดง','เหล็ก','พลาสติก',3,'พลาสติกไม่นำไฟฟ้า จึงใช้หุ้มสายไฟ'),
  ('สมบัติของสารและสถานะ','สมบัติการนำความร้อนของโลหะช่วยให้นำไปใช้ทำอะไร','หม้อและกระทะ','ฉนวนสายไฟ','ถุงมือกันความร้อน','หลอดไฟ',0,'โลหะนำความร้อนดี จึงทำภาชนะหุงต้ม'),
  ('สมบัติของสารและสถานะ','เมื่อน้ำเปลี่ยนจากของเหลวเป็นไอ อนุภาคของน้ำเปลี่ยนไปอย่างไร','อยู่ชิดกันมากขึ้น','กลายเป็นอะตอมอื่น','เล็กลงจนหายไป','อยู่ห่างกันมากขึ้นและเคลื่อนที่เร็วขึ้น',3,'เปลี่ยนสถานะไม่เปลี่ยนชนิดของสาร'),
  ('สมบัติของสารและสถานะ','หน่วยของมวลในระบบเอสไอ (SI) คือข้อใด','เมตร','กิโลกรัม','องศาเซลเซียส','ลิตร',1,'มวลมีหน่วยเป็นกิโลกรัม (kg)'),
  ('สมบัติของสารและสถานะ','สารที่ไหลได้และมีปริมาตรคงที่แต่ไม่มีรูปร่างแน่นอนคือสถานะใด','ผง','ของแข็ง','ของเหลว','แก๊ส',2,'ตัวอย่างคือน้ำ น้ำมัน'),
  ('สมบัติของสารและสถานะ','ลูกโป่งที่ถูกบีบจนเล็กลงได้ แสดงว่าแก๊สมีสมบัติอย่างไร','หนักมาก','มีรูปร่างคงที่','ไม่มีมวล','ถูกอัดได้',3,'อนุภาคแก๊สห่างกัน จึงอัดให้ปริมาตรลดลงได้'),
  ('สมบัติของสารและสถานะ','สารที่ถูกดึงดูดด้วยแม่เหล็กได้ดีคือข้อใด','ไม้','เหล็ก','อะลูมิเนียม','ทองแดง',1,'เหล็ก นิกเกิล โคบอลต์ ถูกแม่เหล็กดูดได้'),
  ('สมบัติของสารและสถานะ','ข้อใดคือหน่วยของปริมาตรที่นิยมใช้วัดของเหลว','วินาที','เมตร','มิลลิลิตร','กรัม',2,'1 ลิตร = 1,000 มิลลิลิตร'),
  ('สมบัติของสารและสถานะ','น้ำแข็งลอยน้ำได้เพราะน้ำแข็งมีสมบัติอย่างไร','เย็นกว่าน้ำ','มีสีขาว','หนักกว่าน้ำ','หนาแน่นน้อยกว่าน้ำเหลว',3,'น้ำแข็งมีโครงสร้างโปร่ง ความหนาแน่นต่ำกว่าน้ำ'),
  ('ธาตุ สารประกอบ และสารผสม','สารบริสุทธิ์ที่ประกอบด้วยอะตอมชนิดเดียวกันเรียกว่าอะไร','ธาตุ','สารประกอบ','สารผสม','สารละลาย',0,'ธาตุคือสารบริสุทธิ์ที่แยกให้ง่ายกว่าเดิมด้วยวิธีทางเคมีไม่ได้'),
  ('ธาตุ สารประกอบ และสารผสม','สารที่ประกอบด้วยธาตุตั้งแต่ 2 ชนิดรวมกันด้วยอัตราส่วนคงที่ เรียกว่าอะไร','ธาตุ','อะตอม','สารผสม','สารประกอบ',3,'เช่น น้ำ H₂O มี H และ O รวมกัน'),
  ('ธาตุ สารประกอบ และสารผสม','น้ำ (H₂O) จัดเป็นสารประเภทใด','สารประกอบ','อะตอม','ธาตุ','สารผสมเนื้อเดียว',0,'น้ำประกอบด้วยไฮโดรเจนและออกซิเจนรวมกันทางเคมี'),
  ('ธาตุ สารประกอบ และสารผสม','ข้อใดเป็นธาตุ','น้ำส้มสายชู','เหล็ก','เกลือแกง','น้ำตาล',1,'เหล็กคือธาตุ Fe'),
  ('ธาตุ สารประกอบ และสารผสม','ข้อใดเป็นสารประกอบ','ทองแดง','อะลูมิเนียม','ออกซิเจน','เกลือแกง (NaCl)',3,'NaCl ประกอบด้วยโซเดียมและคลอรีน'),
  ('ธาตุ สารประกอบ และสารผสม','ข้อใดเป็นสารผสม','น้ำกลั่น','ทองคำบริสุทธิ์','ออกซิเจนบริสุทธิ์','อากาศ',3,'อากาศมีแก๊สหลายชนิดผสมกัน'),
  ('ธาตุ สารประกอบ และสารผสม','น้ำทะเลจัดเป็นสารประเภทใด','สารบริสุทธิ์','สารประกอบ','สารผสม','ธาตุ',2,'น้ำทะเลมีน้ำ เกลือ และสารอื่นปนกัน'),
  ('ธาตุ สารประกอบ และสารผสม','สารผสมที่มองเห็นเป็นเนื้อเดียวกันทั้งหมด เรียกว่าอะไร','สารประกอบ','สารเนื้อเดียว','สารเนื้อผสม','ธาตุ',1,'เช่น น้ำเกลือ น้ำอัดลมที่ไม่มีฟอง'),
  ('ธาตุ สารประกอบ และสารผสม','สารผสมที่มองเห็นส่วนประกอบแยกกันได้ เรียกว่าอะไร','สารประกอบ','สารเนื้อเดียว','สารเนื้อผสม','ธาตุ',2,'เช่น น้ำผสมทราย สลัดผัก'),
  ('ธาตุ สารประกอบ และสารผสม','ข้อใดเป็นสารเนื้อเดียว','น้ำปนทราย','น้ำมันกับน้ำ','ส้มตำ','น้ำเชื่อม',3,'น้ำเชื่อมละลายเป็นเนื้อเดียวกัน'),
  ('ธาตุ สารประกอบ และสารผสม','ข้อใดเป็นสารเนื้อผสม','อากาศบริสุทธิ์','น้ำส้มสายชู','น้ำเกลือ','น้ำปนดินโคลน',3,'เห็นดินแยกจากน้ำได้'),
  ('ธาตุ สารประกอบ และสารผสม','โมเลกุลของแก๊สออกซิเจนมีสูตรเคมีใด','CO₂','O₂','O₃','O',1,'ออกซิเจนในอากาศอยู่เป็นโมเลกุล O₂'),
  ('ธาตุ สารประกอบ และสารผสม','สูตรเคมีของคาร์บอนไดออกไซด์คือข้อใด','CO','C₂O','CO₂','O₂',2,'1 อะตอมคาร์บอน กับ 2 อะตอมออกซิเจน'),
  ('ธาตุ สารประกอบ และสารผสม','สูตรเคมีของน้ำคือข้อใด','H₂O₂','HO','H₂O','OH',2,'ไฮโดรเจน 2 อะตอม ออกซิเจน 1 อะตอม'),
  ('ธาตุ สารประกอบ และสารผสม','ข้อใดเป็นสารบริสุทธิ์','น้ำทะเล','น้ำอัดลม','นม','น้ำกลั่น',3,'น้ำกลั่นมีเฉพาะ H₂O'),
  ('ธาตุ สารประกอบ และสารผสม','ทองเหลืองเป็นโลหะผสมของธาตุใดบ้าง','ทองแดงกับสังกะสี','เงินกับทอง','ทองแดงกับดีบุก','เหล็กกับคาร์บอน',0,'ทองเหลือง = Cu + Zn'),
  ('ธาตุ สารประกอบ และสารผสม','เหล็กกล้าเป็นโลหะผสมของเหล็กกับธาตุใดเป็นหลัก','คาร์บอน','ทองแดง','ตะกั่ว','ปรอท',0,'เติมคาร์บอนทำให้เหล็กแข็งแรงขึ้น'),
  ('ธาตุ สารประกอบ และสารผสม','โมเลกุลคืออะไร','ส่วนผสมของสารหลายชนิด','อนุภาคที่เล็กที่สุดในจักรวาล','กลุ่มอะตอมที่ยึดกันด้วยพันธะเคมี','สารที่มองไม่เห็นเท่านั้น',2,'โมเลกุลเกิดจากอะตอมตั้งแต่ 2 อะตอมขึ้นไปมาเกาะกัน'),
  ('ธาตุ สารประกอบ และสารผสม','อะตอมของธาตุเดียวกันมีสมบัติทางเคมีอย่างไร','เป็นอนุภาคคนละชนิดกัน','เหมือนกัน','ไม่มีประจุ','ต่างกันทุกตัว',1,'อะตอมธาตุเดียวกันมีจำนวนโปรตอนเท่ากัน'),
  ('ธาตุ สารประกอบ และสารผสม','สารที่เกิดจากการรวมกันของธาตุ 2 ชนิดขึ้นไปแล้วสมบัติเปลี่ยนไปจากเดิมคือข้อใด','ส่วนผสมเชิงกล','สารประกอบ','สารละลาย','อะตอม',1,'สารประกอบมีสมบัติต่างจากธาตุที่เป็นองค์ประกอบ'),
  ('การแยกสารและสารละลาย','การแยกทรายออกจากน้ำขุ่นใช้วิธีใด','การสกัด','การกรอง','การระเหยแห้ง','การกลั่น',1,'ทรายไม่ละลาย แยกได้ด้วยกระดาษกรอง'),
  ('การแยกสารและสารละลาย','การทำนาเกลือใช้หลักการแยกสารแบบใด','การกรอง','การตกตะกอน','การกลั่น','การระเหยน้ำ',3,'น้ำทะเลระเหยไป เหลือเกลือเป็นผลึก'),
  ('การแยกสารและสารละลาย','การทำน้ำกลั่นจากน้ำทะเลใช้วิธีใด','การกลั่น','การร่อน','การใช้แม่เหล็ก','การกรอง',0,'ต้มน้ำให้เป็นไอแล้วควบแน่นกลับเป็นน้ำบริสุทธิ์'),
  ('การแยกสารและสารละลาย','การแยกผงเหล็กออกจากทรายใช้วิธีใดสะดวกที่สุด','การกรอง','ใช้แม่เหล็กดูด','การระเหยแห้ง','การกลั่น',1,'เหล็กถูกแม่เหล็กดูด ทรายไม่ถูกดูด'),
  ('การแยกสารและสารละลาย','การแยกสีในหมึกปากกาด้วยกระดาษโดยให้ตัวทำละลายเคลื่อนขึ้น เรียกว่าอะไร','โครมาโทกราฟี','การกลั่น','การระเหิด','การกรอง',0,'สีต่างชนิดเคลื่อนที่ได้ไม่เท่ากัน จึงแยกกัน'),
  ('การแยกสารและสารละลาย','การร่อนแยกก้อนกรวดออกจากทรายละเอียดใช้อะไรเป็นหลัก','สี','กลิ่น','ความร้อน','ขนาดอนุภาค',3,'ตะแกรงมีรูขนาดต่างกัน'),
  ('การแยกสารและสารละลาย','การแยกน้ำมันที่ลอยบนน้ำออกจากน้ำใช้วิธีใด','การแยกด้วยกรวยแยก','การระเหยแห้ง','การระเหิด','การตกผลึก',0,'น้ำกับน้ำมันไม่รวมเป็นเนื้อเดียวกัน แยกเป็นชั้น'),
  ('การแยกสารและสารละลาย','ตัวละลายคือสารใดในน้ำเกลือ','อากาศ','น้ำ','ทราย','เกลือ',3,'เกลือถูกละลายในน้ำ น้ำเป็นตัวทำละลาย'),
  ('การแยกสารและสารละลาย','ตัวทำละลายในน้ำเชื่อมคือสารใด','น้ำตาล','น้ำ','น้ำมัน','เกลือ',1,'น้ำละลายน้ำตาล จึงเป็นตัวทำละลาย'),
  ('การแยกสารและสารละลาย','สารละลายอิ่มตัวคืออะไร','สารละลายที่ไม่มีตัวละลาย','สารละลายที่ร้อนจัด','สารละลายที่ละลายตัวละลายได้เต็มที่แล้ว','สารละลายที่เจือจางมาก',2,'เติมตัวละลายเพิ่มจะไม่ละลายอีก ณ อุณหภูมิเดิม'),
  ('การแยกสารและสารละลาย','เพิ่มอุณหภูมิของน้ำ โดยทั่วไปน้ำตาลจะละลายได้อย่างไร','ละลายได้น้อยลง','ไม่ละลายเลย','ละลายได้มากขึ้น','ละลายเท่าเดิมเสมอ',2,'อุณหภูมิสูงขึ้นมักละลายสารที่เป็นของแข็งได้มากขึ้น'),
  ('การแยกสารและสารละลาย','การคนน้ำตาลในน้ำช่วยอะไร','ทำให้น้ำตาลหายไป','ทำให้ละลายได้มากกว่าเดิมตลอดไป','ทำให้น้ำเดือด','ทำให้ละลายเร็วขึ้น',3,'การคนเพิ่มการสัมผัสกันระหว่างตัวทำละลายกับตัวละลาย'),
  ('การแยกสารและสารละลาย','สารละลายเข้มข้นคือสารละลายที่มีลักษณะอย่างไร','มีตัวละลายมาก','ไม่มีตัวทำละลาย','มีตัวละลายน้อย','เป็นแก๊สเสมอ',0,'ปริมาณตัวละลายมากเมื่อเทียบกับปริมาณสารละลาย'),
  ('การแยกสารและสารละลาย','ข้อใดเป็นสารละลายที่ตัวทำละลายเป็นแก๊ส','ทองเหลือง','น้ำอัดลม','น้ำเกลือ','อากาศ',3,'อากาศคือแก๊สหลายชนิดละลายปนกัน'),
  ('การแยกสารและสารละลาย','ข้อใดเป็นสารละลายที่ตัวละลายเป็นแก๊ส','น้ำเชื่อม','น้ำเกลือ','น้ำอัดลม','ทองเหลือง',2,'น้ำอัดลมมีแก๊สคาร์บอนไดออกไซด์ละลายอยู่'),
  ('การแยกสารและสารละลาย','ข้อใดเป็นสารละลายที่เป็นของแข็ง','ทองเหลือง','น้ำเกลือ','อากาศ','น้ำส้มสายชู',0,'โลหะผสมเป็นสารละลายของแข็ง'),
  ('การแยกสารและสารละลาย','ข้อใดเป็นคอลลอยด์','น้ำเชื่อม','นม','น้ำเกลือ','น้ำกลั่น',1,'อนุภาคนมเล็กพอกระจาย แต่ใหญ่พอกระเจิงแสง'),
  ('การแยกสารและสารละลาย','การกรองใช้แยกสารที่มีลักษณะใด','แก๊สจากแก๊ส','ของแข็งที่ไม่ละลายออกจากของเหลว','สารที่ละลายในน้ำได้','สีจากหมึก',1,'ตัวละลายผ่านกระดาษกรองได้ ของแข็งที่ไม่ละลายค้างอยู่'),
  ('การแยกสารและสารละลาย','ถ้าต้องการแยกน้ำตาลออกจากน้ำเชื่อมให้ได้ผลึก ควรใช้วิธีใด','การระเหยแล้วตกผลึก','การใช้แม่เหล็ก','การร่อน','การกรอง',0,'ระเหยน้ำออก น้ำตาลจะตกผลึก'),
  ('การแยกสารและสารละลาย','ข้อใดคือตัวอย่างของการสกัดสาร','การชงชา','การต้มไข่','การเผากระดาษ','การหลอมทอง',0,'น้ำร้อนสกัดสารสีและรสจากใบชา'),
  ('การแยกสารและสารละลาย','การนำน้ำเกลือมาต้มให้เหลือเกลือ เรียกว่าการแยกสารด้วยวิธีใด','การระเหยแห้ง','การกรอง','การร่อน','การโครมาโทกราฟี',0,'ระเหยตัวทำละลายทิ้ง เหลือตัวละลาย'),
  ('ตารางธาตุและสัญลักษณ์ธาตุ','สัญลักษณ์ธาตุของไฮโดรเจนคือข้อใด','H','Hd','Hy','He',0,'ไฮโดรเจน = H'),
  ('ตารางธาตุและสัญลักษณ์ธาตุ','สัญลักษณ์ธาตุของฮีเลียมคือข้อใด','H','Hl','He','Hm',2,'ฮีเลียม = He'),
  ('ตารางธาตุและสัญลักษณ์ธาตุ','สัญลักษณ์ธาตุของคาร์บอนคือข้อใด','Ca','C','Co','Cr',1,'คาร์บอน = C'),
  ('ตารางธาตุและสัญลักษณ์ธาตุ','สัญลักษณ์ธาตุของไนโตรเจนคือข้อใด','N','No','Ni','Na',0,'ไนโตรเจน = N'),
  ('ตารางธาตุและสัญลักษณ์ธาตุ','สัญลักษณ์ธาตุของทองคำคือข้อใด','Ag','Au','Gd','Go',1,'Au มาจากภาษาละติน aurum'),
  ('ตารางธาตุและสัญลักษณ์ธาตุ','สัญลักษณ์ธาตุของเงินคือข้อใด','Au','Si','Sr','Ag',3,'Ag มาจากภาษาละติน argentum'),
  ('ตารางธาตุและสัญลักษณ์ธาตุ','สัญลักษณ์ธาตุของทองแดงคือข้อใด','Cu','Co','Cr','Cd',0,'Cu มาจากภาษาละติน cuprum'),
  ('ตารางธาตุและสัญลักษณ์ธาตุ','สัญลักษณ์ธาตุของเหล็กคือข้อใด','F','Ir','Fe','Fl',2,'Fe มาจากภาษาละติน ferrum'),
  ('ตารางธาตุและสัญลักษณ์ธาตุ','สัญลักษณ์ธาตุของแคลเซียมคือข้อใด','C','Ca','Cs','Cl',1,'แคลเซียม = Ca'),
  ('ตารางธาตุและสัญลักษณ์ธาตุ','สัญลักษณ์ธาตุของคลอรีนคือข้อใด','Ca','Cl','C','Cr',1,'คลอรีน = Cl'),
  ('ตารางธาตุและสัญลักษณ์ธาตุ','สัญลักษณ์ธาตุของโพแทสเซียมคือข้อใด','P','Po','Pt','K',3,'K มาจากภาษาละติน kalium'),
  ('ตารางธาตุและสัญลักษณ์ธาตุ','สัญลักษณ์ธาตุของกำมะถันคือข้อใด','Sn','Si','S','Sc',2,'กำมะถัน = S'),
  ('ตารางธาตุและสัญลักษณ์ธาตุ','สัญลักษณ์ธาตุของอะลูมิเนียมคือข้อใด','Au','A','Al','Am',2,'อะลูมิเนียม = Al'),
  ('ตารางธาตุและสัญลักษณ์ธาตุ','สัญลักษณ์ธาตุของปรอทคือข้อใด','Hg','Pt','Mg','Pb',0,'Hg มาจากภาษากรีก hydrargyrum'),
  ('ตารางธาตุและสัญลักษณ์ธาตุ','สัญลักษณ์ธาตุของตะกั่วคือข้อใด','Sn','Tl','Pb','Le',2,'Pb มาจากภาษาละติน plumbum'),
  ('ตารางธาตุและสัญลักษณ์ธาตุ','สัญลักษณ์ธาตุของโซเดียมคือข้อใด','S','N','Na','So',2,'Na มาจากภาษาละติน natrium'),
  ('ตารางธาตุและสัญลักษณ์ธาตุ','ธาตุที่มีสัญลักษณ์ Mg คือธาตุใด','โมลิบดีนัม','ปรอท','แมกนีเซียม','แมงกานีส',2,'Mg = แมกนีเซียม'),
  ('ตารางธาตุและสัญลักษณ์ธาตุ','ธาตุที่มีสัญลักษณ์ Zn คือธาตุใด','ดีบุก','ซีนอน','เซอร์โคเนียม','สังกะสี',3,'Zn = สังกะสี ใช้ชุบเหล็กกันสนิม'),
  ('ตารางธาตุและสัญลักษณ์ธาตุ','ตารางธาตุในปัจจุบันเรียงธาตุตามอะไร','เลขอะตอมจากน้อยไปมาก','ปีที่ค้นพบ','สีของธาตุ','ตัวอักษรแรกของชื่อ',0,'เรียงตามเลขอะตอม (จำนวนโปรตอน)'),
  ('ตารางธาตุและสัญลักษณ์ธาตุ','แถวแนวนอนในตารางธาตุเรียกว่าอะไร','หมู่','อนุกรม','คาบ','ชุด',2,'แถวแนวนอน = คาบ แถวแนวตั้ง = หมู่'),
  ('ตารางธาตุและสัญลักษณ์ธาตุ','แถวแนวตั้งในตารางธาตุเรียกว่าอะไร','คาบ','หมู่','ระดับ','ชุด',1,'ธาตุในหมู่เดียวกันมีสมบัติคล้ายกัน'),
  ('ตารางธาตุและสัญลักษณ์ธาตุ','ธาตุกลุ่มใดไม่ค่อยทำปฏิกิริยากับสารอื่น','แก๊สเฉื่อย','โลหะแอลคาไล','ฮาโลเจน','โลหะทรานซิชัน',0,'แก๊สเฉื่อยมีอิเล็กตรอนวงนอกสุดเต็ม'),
  ('ตารางธาตุและสัญลักษณ์ธาตุ','ข้อใดเป็นแก๊สเฉื่อย','ไนโตรเจน','นีออน','ออกซิเจน','คลอรีน',1,'นีออน อาร์กอน ฮีเลียม เป็นแก๊สเฉื่อย'),
  ('ตารางธาตุและสัญลักษณ์ธาตุ','ธาตุใดเป็นของเหลวที่อุณหภูมิห้องและเป็นโลหะ','ทองแดง','ตะกั่ว','เหล็ก','ปรอท',3,'ปรอทเป็นโลหะชนิดเดียวที่เป็นของเหลวที่อุณหภูมิห้อง'),
  ('ตารางธาตุและสัญลักษณ์ธาตุ','โลหะส่วนใหญ่มีสมบัติข้อใด','มีผิวไม่มันวาว','นำไฟฟ้าและนำความร้อนได้ดี','เปราะแตกง่าย','เป็นฉนวน',1,'โลหะนำไฟฟ้า นำความร้อน ตีเป็นแผ่นได้'),
  ('ตารางธาตุและสัญลักษณ์ธาตุ','อโลหะส่วนใหญ่ในสถานะของแข็งมีสมบัติอย่างไร','ตีเป็นแผ่นได้','มันวาวและนำไฟฟ้าดี','เหนียวมาก','เปราะ ไม่นำไฟฟ้า',3,'เช่น กำมะถัน ฟอสฟอรัส เปราะและเป็นฉนวน'),
  ('อะตอมเบื้องต้น','อนุภาคใดในอะตอมมีประจุบวก','โปรตอน','นิวตรอน','โมเลกุล','อิเล็กตรอน',0,'โปรตอนมีประจุ +1'),
  ('อะตอมเบื้องต้น','อนุภาคใดในอะตอมมีประจุลบ','โปรตอน','นิวตรอน','อิเล็กตรอน','นิวเคลียส',2,'อิเล็กตรอนมีประจุ -1'),
  ('อะตอมเบื้องต้น','อนุภาคใดในอะตอมไม่มีประจุไฟฟ้า','อิเล็กตรอน','นิวตรอน','ไอออน','โปรตอน',1,'นิวตรอนเป็นกลางทางไฟฟ้า'),
  ('อะตอมเบื้องต้น','ศูนย์กลางของอะตอมที่มีโปรตอนและนิวตรอนเรียกว่าอะไร','ออร์บิทัล','นิวเคลียส','โมเลกุล','เปลือกอะตอม',1,'นิวเคลียสรวมมวลเกือบทั้งหมดของอะตอม'),
  ('อะตอมเบื้องต้น','เลขอะตอมของธาตุบอกถึงอะไร','จำนวนโมเลกุล','จำนวนนิวตรอน','จำนวนโปรตอน','ความหนาแน่น',2,'เลขอะตอม = จำนวนโปรตอน'),
  ('อะตอมเบื้องต้น','อะตอมที่เป็นกลางทางไฟฟ้ามีลักษณะอย่างไร','จำนวนโปรตอนเท่ากับอิเล็กตรอน','มีนิวตรอนเท่ากับโปรตอนเสมอ','ไม่มีอนุภาคมีประจุ','มีแต่โปรตอน',0,'ประจุบวกและลบหักล้างกันพอดี'),
  ('อะตอมเบื้องต้น','ใครเสนอแบบจำลองอะตอมลูกบิลเลียดที่เป็นทรงกลมตัน','ดอลตัน','ทอมสัน','โบร์','รัทเทอร์ฟอร์ด',0,'จอห์น ดอลตัน เสนอทฤษฎีอะตอมของเขา'),
  ('อะตอมเบื้องต้น','ผู้ค้นพบอิเล็กตรอนคือใคร','ชาดวิก','ดอลตัน','ทอมสัน','โบร์',2,'เจ.เจ. ทอมสัน ค้นพบอิเล็กตรอนจากการทดลองรังสีแคโทด'),
  ('อะตอมเบื้องต้น','อะตอมคืออะไร','สารประกอบ','อนุภาคที่เล็กที่สุดของธาตุที่ยังคงสมบัติของธาตุนั้น','กลุ่มของโมเลกุล','ส่วนผสมของสาร',1,'อะตอมเป็นหน่วยพื้นฐานของสสาร'),
  ('อะตอมเบื้องต้น','อะตอมคาร์บอนมีเลขอะตอม 6 มีโปรตอนกี่ตัว','12','6','2','3',1,'เลขอะตอม = จำนวนโปรตอน = 6'),
  ('อะตอมเบื้องต้น','อะตอมที่เสียอิเล็กตรอนไปจะกลายเป็นอะไร','นิวตรอน','ไอออนบวก','ไอออนลบ','โมเลกุล',1,'เสียอิเล็กตรอน ประจุบวกมากกว่า จึงเป็นไอออนบวก'),
  ('อะตอมเบื้องต้น','อะตอมของธาตุต่างชนิดกันต่างกันที่จุดใดเป็นหลัก','สีของอะตอม','จำนวนโปรตอน','ขนาดของนิวเคลียสเท่านั้น','จำนวนโมเลกุล',1,'ธาตุแต่ละชนิดมีจำนวนโปรตอนเฉพาะตัว'),
  ('กรด เบส และสารละลาย','น้ำมะนาวมีสมบัติเป็นอะไร','กรด','ด่างแก่','กลาง','เบส',0,'น้ำมะนาวมีกรดซิตริก'),
  ('กรด เบส และสารละลาย','สบู่และน้ำสบู่ส่วนใหญ่มีสมบัติอย่างไร','เป็นแก๊ส','เป็นกลางเสมอ','เป็นกรด','เป็นเบส',3,'สบู่มีฤทธิ์เป็นเบสอ่อน'),
  ('กรด เบส และสารละลาย','น้ำบริสุทธิ์มีค่า pH ประมาณเท่าใด','0','14','1','7',3,'pH 7 คือสารละลายเป็นกลาง'),
  ('กรด เบส และสารละลาย','สารละลายที่ pH น้อยกว่า 7 เป็นสารละลายใด','กรด','เกลือ','กลาง','เบส',0,'pH ต่ำกว่า 7 = กรด'),
  ('กรด เบส และสารละลาย','สารละลายที่ pH มากกว่า 7 เป็นสารละลายใด','เบส','กรด','กลาง','น้ำมัน',0,'pH สูงกว่า 7 = เบส'),
  ('กรด เบส และสารละลาย','กระดาษลิตมัสสีน้ำเงินเมื่อสัมผัสกรดจะเปลี่ยนเป็นสีใด','แดง','เหลือง','เขียว','ไม่เปลี่ยน',0,'กรดเปลี่ยนลิตมัสน้ำเงินเป็นสีแดง'),
  ('กรด เบส และสารละลาย','กระดาษลิตมัสสีแดงเมื่อสัมผัสเบสจะเปลี่ยนเป็นสีใด','ส้ม','เหลือง','น้ำเงิน','ไม่เปลี่ยน',2,'เบสเปลี่ยนลิตมัสแดงเป็นสีน้ำเงิน'),
  ('กรด เบส และสารละลาย','น้ำส้มสายชูมีสมบัติอย่างไร','เป็นเบส','เป็นแก๊ส','เป็นกลาง','เป็นกรด',3,'มีกรดแอซีติก (กรดน้ำส้ม)'),
  ('กรด เบส และสารละลาย','ยาลดกรดช่วยบรรเทาอาการกรดไหลย้อนเพราะมีสมบัติอย่างไร','เป็นเบสอ่อนที่ทำปฏิกิริยากับกรด','เป็นน้ำมัน','เป็นกรดแก่','เป็นแก๊ส',0,'เบสทำปฏิกิริยาสะเทินกับกรดในกระเพาะ'),
  ('กรด เบส และสารละลาย','ปฏิกิริยาระหว่างกรดกับเบสเรียกว่าอะไร','การระเหิด','การควบแน่น','ปฏิกิริยาสะเทิน','ปฏิกิริยาการเผาไหม้',2,'ได้เกลือกับน้ำ'),
  ('กรด เบส และสารละลาย','ข้อใดเป็นสมบัติของกรด','ลื่นมือ','ทำให้ลิตมัสแดงเป็นน้ำเงิน','มีรสเปรี้ยว','มีรสขมเสมอ',2,'กรดรสเปรี้ยว แต่ห้ามชิมสารเคมีในห้องปฏิบัติการ'),
  ('กรด เบส และสารละลาย','ข้อใดเป็นสมบัติของเบส','ทำให้ลิตมัสน้ำเงินเป็นแดง','มี pH ต่ำกว่า 7','มีรสเปรี้ยวเสมอ','ลื่นมือ',3,'เบสมีความลื่นคล้ายสบู่'),
  ('กรด เบส และสารละลาย','ข้อใดเป็นกรด','น้ำสบู่','น้ำปูนใส','น้ำส้มสายชู','ยาล้างห้องน้ำชนิดเบส',2,'น้ำส้มสายชูมีกรดแอซีติก'),
  ('กรด เบส และสารละลาย','ข้อใดเป็นเบส','น้ำมะนาว','น้ำปูนใส','น้ำอัดลม','น้ำส้ม',1,'น้ำปูนใสคือสารละลายแคลเซียมไฮดรอกไซด์'),
  ('กรด เบส และสารละลาย','อินดิเคเตอร์จากธรรมชาติที่ใช้ทดสอบกรด-เบสได้คือข้อใด','เกลือ','น้ำตาล','น้ำคั้นกะหล่ำปลีม่วง','น้ำเปล่า',2,'กะหล่ำปลีม่วงเปลี่ยนสีตามกรด-เบส'),
  ('กรด เบส และสารละลาย','กรดไฮโดรคลอริกที่เข้มข้นอันตรายอย่างไร','ติดไฟง่ายมาก','กัดกร่อนผิวหนังและโลหะ','มีแต่กลิ่นหอม','ไม่เป็นอันตราย',1,'ต้องสวมแว่นและถุงมือเมื่อใช้'),
  ('กรด เบส และสารละลาย','ข้อใดเป็นผลของฝนกรด','ทำให้น้ำใสขึ้น','ทำให้ดินเป็นกลางเสมอ','ทำให้ต้นไม้โตเร็วขึ้น','ทำให้สิ่งก่อสร้างหินปูนและโลหะผุกร่อน',3,'ฝนกรดมาจาก SO₂ และ NOx ในอากาศ'),
  ('กรด เบส และสารละลาย','ฝนกรดเกิดจากแก๊สพิษใดเป็นหลัก','ออกซิเจน','ไฮโดรเจน','ซัลเฟอร์ไดออกไซด์','ไนโตรเจน',2,'SO₂ ละลายน้ำฝนกลายเป็นกรด'),
  ('กรด เบส และสารละลาย','ผักผลไม้ดองที่มีรสเปรี้ยวมีสมบัติใกล้เคียงกับสารใด','สารเป็นกลาง','ฉนวน','เบส','กรด',3,'กรดอินทรีย์จากการหมักให้รสเปรี้ยว'),
  ('กรด เบส และสารละลาย','ข้อใดควรทำเมื่อกรดหกรดมือเล็กน้อย','ล้างด้วยน้ำสะอาดปริมาณมากทันที','ปล่อยไว้ให้แห้ง','เช็ดด้วยกระดาษแห้ง','ทาครีมทันที',0,'ล้างด้วยน้ำปริมาณมากและแจ้งครู'),
  ('การเปลี่ยนแปลงทางกายภาพและเคมี','การเปลี่ยนแปลงข้อใดเป็นการเปลี่ยนแปลงทางเคมี','น้ำแข็งละลาย','ละลายน้ำตาลในน้ำ','ฉีกกระดาษ','เหล็กเป็นสนิม',3,'เกิดสารใหม่คือสนิมเหล็ก'),
  ('การเปลี่ยนแปลงทางกายภาพและเคมี','การเปลี่ยนแปลงข้อใดเป็นการเปลี่ยนแปลงทางกายภาพ','ขนมปังขึ้นรา','ไม้ถูกเผา','นมบูด','น้ำระเหยเป็นไอ',3,'ไม่เกิดสารใหม่ แค่เปลี่ยนสถานะ'),
  ('การเปลี่ยนแปลงทางกายภาพและเคมี','ข้อใดเป็นสัญญาณว่าอาจเกิดปฏิกิริยาเคมี','การฉีกกระดาษ','มีฟองแก๊สเกิดขึ้นพร้อมสีเปลี่ยน','การละลายน้ำตาล','น้ำแข็งแข็งตัว',1,'การเกิดแก๊ส สีเปลี่ยน ตะกอน อุณหภูมิเปลี่ยน'),
  ('การเปลี่ยนแปลงทางกายภาพและเคมี','การเผาไหม้ต้องมีองค์ประกอบใดบ้าง','น้ำ เกลือ น้ำตาล','แสง เสียง ลม','เหล็ก ทราย น้ำ','เชื้อเพลิง ออกซิเจน และความร้อน',3,'สามองค์ประกอบของสามเหลี่ยมไฟ'),
  ('การเปลี่ยนแปลงทางกายภาพและเคมี','การดับไฟโดยใช้ผ้าห่มคลุมไฟได้ผลเพราะอะไร','ตัดออกซิเจน','เพิ่มความร้อน','เพิ่มแก๊สไนโตรเจนเข้าไปเสมอ','เพิ่มเชื้อเพลิง',0,'ไม่มีออกซิเจนไฟจะดับ'),
  ('การเปลี่ยนแปลงทางกายภาพและเคมี','แก๊สใดที่ทำให้ปูนขาวใสขุ่นเมื่อผ่านเข้าไป','คาร์บอนไดออกไซด์','ไฮโดรเจน','ออกซิเจน','ไนโตรเจน',0,'CO₂ ทำให้น้ำปูนใสขุ่น'),
  ('การเปลี่ยนแปลงทางกายภาพและเคมี','สนิมเหล็กเกิดจากเหล็กทำปฏิกิริยากับสารใดเป็นหลัก','ไฮโดรเจนและน้ำมัน','ไนโตรเจนและเกลือ','คาร์บอนและทราย','ออกซิเจนและน้ำ',3,'เหล็ก + ออกซิเจน + น้ำ ได้สนิม'),
  ('การเปลี่ยนแปลงทางกายภาพและเคมี','วิธีป้องกันเหล็กเป็นสนิมคือข้อใด','ทาสีหรือชุบสังกะสี','แช่น้ำเกลือ','ขูดผิวให้หยาบ','ทิ้งไว้กลางฝน',0,'เคลือบผิวไม่ให้สัมผัสอากาศและน้ำ'),
  ('การเปลี่ยนแปลงทางกายภาพและเคมี','การใส่ผงฟูในขนมแล้วขนมฟู เกิดจากอะไร','เกิดแก๊สนีออน','เกิดแก๊สออกซิเจน','เกิดแก๊สคาร์บอนไดออกไซด์','ผงฟูกลายเป็นน้ำ',2,'ผงฟูสลายตัวให้ CO₂'),
  ('การเปลี่ยนแปลงทางกายภาพและเคมี','การเปลี่ยนแปลงใดมีการดูดความร้อนจากสิ่งแวดล้อม','น้ำแข็งเกิดขึ้น','ไอน้ำกลายเป็นหมอก','น้ำแข็งหลอมเหลว','น้ำควบแน่น',2,'การหลอมเหลวต้องการความร้อน'),
  ('การเปลี่ยนแปลงทางกายภาพและเคมี','การเน่าเสียของอาหารเป็นการเปลี่ยนแปลงแบบใด','การระเหิด','ทางเคมี','ทางกายภาพ','การเปลี่ยนสถานะ',1,'เกิดสารใหม่ มีกลิ่นและรสเปลี่ยน'),
  ('การเปลี่ยนแปลงทางกายภาพและเคมี','ปฏิกิริยาเคมีเกิดขึ้นเมื่อสารตั้งต้นกลายเป็นอะไร','แก๊สเฉื่อย','อะตอมใหม่','ตัวทำละลาย','ผลิตภัณฑ์',3,'สารตั้งต้นเปลี่ยนเป็นผลิตภัณฑ์'),
  ('การเปลี่ยนแปลงทางกายภาพและเคมี','กฎการอนุรักษ์มวลกล่าวว่าอย่างไร','มวลลดลงครึ่งหนึ่ง','มวลหายไปเมื่อเกิดปฏิกิริยา','มวลรวมก่อนและหลังปฏิกิริยาเท่ากัน','มวลเพิ่มขึ้นเสมอ',2,'มวลไม่หายไป แค่เปลี่ยนรูป'),
  ('การเปลี่ยนแปลงทางกายภาพและเคมี','ไม้ขีดไฟเมื่อติดไฟแล้วกลายเป็นถ่าน เป็นการเปลี่ยนแปลงแบบใด','การระเหย','ทางกายภาพ','การหลอมเหลว','ทางเคมี',3,'เกิดสารใหม่คือถ่านและแก๊ส'),
  ('การเปลี่ยนแปลงทางกายภาพและเคมี','การละลายน้ำตาลในน้ำเป็นการเปลี่ยนแปลงแบบใด','การเกิดสนิม','ทางเคมี','การเผาไหม้','ทางกายภาพ',3,'ได้สารละลาย ระเหยน้ำออกยังได้น้ำตาลกลับมา'),
  ('อุปกรณ์และความปลอดภัยในห้องปฏิบัติการ','อุปกรณ์วัดปริมาตรของเหลวที่แม่นยำที่สุดในข้อต่อไปนี้คือ','บีกเกอร์','หลอดทดลอง','กระบอกตวง','ขวดรูปชมพู่',2,'กระบอกตวงมีขีดบอกปริมาตรละเอียด'),
  ('อุปกรณ์และความปลอดภัยในห้องปฏิบัติการ','ข้อใดใช้สำหรับให้ความร้อนในห้องปฏิบัติการ','กระบอกตวง','ตะเกียงแอลกอฮอล์','ที่จับหลอดทดลอง','ช้อนตักสาร',1,'ใช้ให้ความร้อนแก่สารอย่างปลอดภัย'),
  ('อุปกรณ์และความปลอดภัยในห้องปฏิบัติการ','ควรสวมอุปกรณ์ใดเสมอเมื่อทำการทดลองกับสารเคมี','สร้อยคอ','รองเท้าแตะ','แว่นตานิรภัย','หมวกแก๊ป',2,'ป้องกันสารเคมีกระเด็นเข้าตา'),
  ('อุปกรณ์และความปลอดภัยในห้องปฏิบัติการ','เมื่อได้กลิ่นสารเคมีควรปฏิบัติอย่างไร','ชิมเล็กน้อย','ดมโดยตรงให้ลึก','อมสารไว้','โบกมือพัดไอระเหยเข้าหาจมูกเบาๆ',3,'ไม่ควรสูดดมโดยตรง'),
  ('อุปกรณ์และความปลอดภัยในห้องปฏิบัติการ','ห้ามทำสิ่งใดในห้องปฏิบัติการ','ชิมสารเคมี','ล้างมือหลังทดลอง','สวมเสื้อกาวน์','อ่านฉลากสาร',0,'สารเคมีอาจเป็นพิษ'),
  ('อุปกรณ์และความปลอดภัยในห้องปฏิบัติการ','สัญลักษณ์รูปเปลวไฟบนฉลากสารเคมีหมายความว่าอย่างไร','สารปลอดภัย','สารไวไฟ','สารกัดกร่อน','สารเป็นพิษ',1,'ต้องเก็บให้ห่างความร้อนและประกายไฟ'),
  ('อุปกรณ์และความปลอดภัยในห้องปฏิบัติการ','สัญลักษณ์รูปหัวกะโหลกไขว้บนฉลากสารเคมีหมายความว่าอย่างไร','สารมีพิษ','สารรีไซเคิลได้','สารกัดกร่อน','สารไวไฟ',0,'ห้ามกินหรือสูดดม'),
  ('อุปกรณ์และความปลอดภัยในห้องปฏิบัติการ','ก่อนใช้สารเคมีควรทำสิ่งใดก่อน','ถอดแว่นตา','อ่านฉลากและคำเตือน','ชิมเพื่อทดสอบ','เทผสมกันก่อน',1,'ฉลากบอกอันตรายและวิธีใช้'),
  ('อุปกรณ์และความปลอดภัยในห้องปฏิบัติการ','เมื่อต้องการเจือจางกรดเข้มข้น ควรทำอย่างไรที่ถูกต้อง','เทผสมพร้อมกันแรงๆ','เติมน้ำลงในกรดเร็วๆ','ใช้มือคน','เติมกรดลงในน้ำช้าๆ',3,'เติมกรดลงน้ำ ป้องกันกระเด็นจากความร้อน'),
  ('อุปกรณ์และความปลอดภัยในห้องปฏิบัติการ','ถ้าสารเคมีกระเด็นเข้าตา ควรทำอย่างไรเป็นอันดับแรก','ขยี้ตา','ล้างตาด้วยน้ำสะอาดทันทีและแจ้งครู','ปล่อยไว้','หยอดน้ำส้มสายชู',1,'ต้องรีบล้างด้วยน้ำปริมาณมาก'),
  ('อุปกรณ์และความปลอดภัยในห้องปฏิบัติการ','การให้ความร้อนหลอดทดลอง ควรหันปากหลอดไปทางใด','เข้าหาตนเอง','เข้าหาเพื่อน','ขึ้นเหนือใบหน้า','ไม่หันเข้าหาตนเองและผู้อื่น',3,'ป้องกันสารพุ่งกระเด็นใส่ผู้อื่น'),
  ('อุปกรณ์และความปลอดภัยในห้องปฏิบัติการ','ข้อใดเป็นการจัดการสารเคมีเหลือหลังการทดลองที่ถูกต้อง','เทลงท่อทุกชนิดทันที','ทิ้งตามคำแนะนำของครู','นำกลับบ้าน','เทกลับขวดเดิม',1,'ไม่ปนเปื้อนสารเดิม และปลอดภัยต่อสิ่งแวดล้อม'),
  ('อุปกรณ์และความปลอดภัยในห้องปฏิบัติการ','เมื่อเกิดไฟไหม้เล็กน้อยในห้องปฏิบัติการ ควรทำสิ่งใดก่อน','ซ่อนไว้','แจ้งครูทันทีและใช้อุปกรณ์ดับเพลิงตามคำแนะนำ','เทน้ำใส่ไฟทุกชนิด','วิ่งหนีโดยไม่บอกใคร',1,'แจ้งครูและทำตามขั้นตอนความปลอดภัย'),
  ('อุปกรณ์และความปลอดภัยในห้องปฏิบัติการ','ทำไมต้องผูกผมยาวเมื่อทำการทดลอง','ป้องกันผมติดไฟหรือสัมผัสสารเคมี','ให้ทำงานเร็วขึ้น','ให้ดูสวย','ให้ได้ผลทดลองแม่นยำ',0,'ผมยาวอาจโดนไฟหรือสารเคมีได้'),
  ('อุปกรณ์และความปลอดภัยในห้องปฏิบัติการ','ข้อใดเป็นอุปกรณ์สำหรับจับหลอดทดลองขณะร้อน','ช้อนตักสาร','กระบอกตวง','ที่จับหลอดทดลอง','หลอดหยด',2,'ป้องกันมือสัมผัสความร้อน'),
  ('เคมีในชีวิตประจำวัน','ผงซักฟอกช่วยกำจัดคราบมันได้เพราะอะไร','มีสีสวย','โมเลกุลจับได้ทั้งน้ำและน้ำมัน','เป็นกรดแก่','ทำให้น้ำเดือด',1,'สารลดแรงตึงผิวทำให้น้ำมันหลุดลอยไปกับน้ำ'),
  ('เคมีในชีวิตประจำวัน','ปุ๋ยเคมีสูตรหลักมีธาตุสำคัญ 3 ชนิดคือข้อใด','เงิน ทอง ทองแดง','ไนโตรเจน ฟอสฟอรัส โพแทสเซียม','คาร์บอน ออกซิเจน ไฮโดรเจน','เหล็ก ทองแดง สังกะสี',1,'N-P-K คือธาตุอาหารหลักของพืช'),
  ('เคมีในชีวิตประจำวัน','ถุงพลาสติกส่วนใหญ่ผลิตจากอะไร','พอลิเมอร์ที่ได้จากปิโตรเลียม','แร่เหล็ก','หินปูน','เส้นใยฝ้าย',0,'พลาสติกเป็นพอลิเมอร์สังเคราะห์'),
  ('เคมีในชีวิตประจำวัน','ข้อใดเป็นข้อดีของการรีไซเคิลพลาสติก','ทำให้พลาสติกหายไปทันที','ไม่มีข้อดี','ลดขยะและประหยัดทรัพยากร','ทำให้โลกร้อนขึ้น',2,'นำวัสดุกลับมาใช้ใหม่'),
  ('เคมีในชีวิตประจำวัน','เกลือไอโอดีนช่วยป้องกันโรคใด','โรคคอพอก','โรคหวัด','โรคลักปิดลักเปิด','โรคกระดูกพรุน',0,'ไอโอดีนจำเป็นต่อฮอร์โมนไทรอยด์'),
  ('เคมีในชีวิตประจำวัน','แคลเซียมจำเป็นต่อร่างกายส่วนใดมากที่สุด','ลิ้น','เล็บเท่านั้น','กระดูกและฟัน','ผม',2,'แคลเซียมเป็นองค์ประกอบสำคัญของกระดูก'),
  ('เคมีในชีวิตประจำวัน','น้ำยาล้างจานช่วยล้างคราบมันได้ ใช้หลักการใด','การกลั่น','การระเหย','สารลดแรงตึงผิว','การกรอง',2,'สบู่และน้ำยาล้างจานมีสารลดแรงตึงผิว'),
  ('เคมีในชีวิตประจำวัน','เบกกิ้งโซดามีสมบัติเป็นอย่างไร','เป็นกรดแก่','เป็นกลางเสมอ','เป็นแก๊ส','เป็นเบสอ่อน',3,'โซเดียมไฮโดรเจนคาร์บอเนต'),
  ('เคมีในชีวิตประจำวัน','เมื่อผสมน้ำส้มสายชูกับเบกกิ้งโซดา จะเกิดสิ่งใด','ไม่มีอะไรเกิดขึ้น','เกิดไฟ','เกิดแก๊สไฮโดรเจนทั้งหมด','เกิดฟองแก๊สคาร์บอนไดออกไซด์',3,'กรดทำปฏิกิริยากับเบส ได้ CO₂'),
  ('เคมีในชีวิตประจำวัน','น้ำตาลทรายเป็นสารที่ใช้ปรุงรสชนิดใด','รสขม','รสเค็ม','รสหวาน','รสเปรี้ยว',2,'น้ำตาลเป็นคาร์โบไฮเดรต'),
  ('เคมีในชีวิตประจำวัน','ผงฟูในขนมเค้กช่วยอะไร','ทำให้ขนมสีดำ','ทำให้ขนมแข็ง','ทำให้ขนมหวานขึ้นเสมอ','ทำให้ขนมฟูนุ่ม',3,'ปล่อยแก๊ส CO₂ ทำให้เนื้อขนมพองตัว'),
  ('เคมีในชีวิตประจำวัน','ข้อใดเป็นแหล่งเชื้อเพลิงฟอสซิล','แสงอาทิตย์','ลม','น้ำมันดิบ','น้ำตก',2,'ถ่านหิน น้ำมัน แก๊สธรรมชาติ คือเชื้อเพลิงฟอสซิล'),
  ('เคมีในชีวิตประจำวัน','แก๊สหุงต้ม (LPG) จัดเป็นอะไร','สารที่ดับไฟ','สารเป็นกลางที่ไม่ติดไฟ','สารฟอกขาว','เชื้อเพลิงที่ติดไฟได้ง่าย',3,'ต้องเก็บให้ห่างไฟและตรวจรอยรั่ว'),
  ('เคมีในชีวิตประจำวัน','สารฟอกขาวในครัวเรือนอันตรายอย่างไรหากผสมกับน้ำยาล้างห้องน้ำ','ไม่มีอันตราย','เกิดน้ำเปล่า','เกิดแก๊สพิษได้','เกิดอาหาร',2,'ห้ามผสมสารทำความสะอาดต่างชนิดกัน'),
  ('เคมีในชีวิตประจำวัน','ข้อใดเป็นวิธีถนอมอาหารที่ใช้เกลือ','การต้มจืด','การดองเค็ม','การแช่น้ำเปล่า','การปิ้งย่างไม่ใส่เกลือ',1,'เกลือช่วยยับยั้งจุลินทรีย์'),
  ('เกร็ดความรู้เคมีรอบตัว','ธาตุใดเบาที่สุดและมีอยู่มากที่สุดในเอกภพ','คาร์บอน','ไฮโดรเจน','ฮีเลียม','ออกซิเจน',1,'ไฮโดรเจนมีมากราว 3 ใน 4 ของสสารธรรมดาในเอกภพ'),
  ('เกร็ดความรู้เคมีรอบตัว','ธาตุใดมีมากที่สุดในอากาศ','ไนโตรเจน','คาร์บอนไดออกไซด์','อาร์กอน','ออกซิเจน',0,'อากาศมีไนโตรเจนประมาณ 78%'),
  ('เกร็ดความรู้เคมีรอบตัว','ออกซิเจนในอากาศมีประมาณร้อยละเท่าใด','50','1','78','21',3,'ออกซิเจนราว 21% ของอากาศโดยปริมาตร'),
  ('เกร็ดความรู้เคมีรอบตัว','เพชรเป็นรูปแบบหนึ่งของธาตุใด','คาร์บอน','ทองคำ','ซิลิคอน','เหล็ก',0,'เพชรและกราไฟต์ล้วนเป็นคาร์บอน'),
  ('เกร็ดความรู้เคมีรอบตัว','ดินสอไส้ดำทำจากสารใดเป็นหลัก','กราไฟต์','เหล็ก','ตะกั่ว','ปรอท',0,'กราไฟต์เป็นคาร์บอน ไม่มีตะกั่วจริง'),
  ('เกร็ดความรู้เคมีรอบตัว','โลหะชนิดใดนำไฟฟ้าได้ดีที่สุด','เงิน','ทอง','เหล็ก','ตะกั่ว',0,'เงินนำไฟฟ้าได้ดีที่สุด แต่ทองแดงราคาถูกกว่าจึงใช้ทำสายไฟ'),
  ('เกร็ดความรู้เคมีรอบตัว','ทองคำ 24 กะรัตมีความบริสุทธิ์ประมาณกี่เปอร์เซ็นต์','ประมาณ 50','ประมาณ 10','ประมาณ 99.9','ประมาณ 75',2,'ทอง 24 กะรัตคือทองที่เกือบบริสุทธิ์'),
  ('เกร็ดความรู้เคมีรอบตัว','ธาตุใดที่ร่างกายเราใช้สร้างฮีโมโกลบินในเลือด','ทองแดง','เหล็ก','ปรอท','ทอง',1,'ธาตุเหล็กช่วยขนส่งออกซิเจนในเลือด'),
  ('เกร็ดความรู้เคมีรอบตัว','น้ำแข็งแห้งคือสารใดในสถานะของแข็ง','น้ำ','คาร์บอนไดออกไซด์','ไนโตรเจน','ออกซิเจน',1,'น้ำแข็งแห้งระเหิดเป็นแก๊สโดยไม่เป็นน้ำ'),
  ('เกร็ดความรู้เคมีรอบตัว','ฮีเลียมในลูกโป่งทำให้ลอยได้เพราะอะไร','ร้อนจัด','หนักกว่าอากาศ','เบากว่าอากาศ','มีสี',2,'ฮีเลียมความหนาแน่นต่ำกว่าอากาศมาก'),
  ('เกร็ดความรู้เคมีรอบตัว','แก๊สที่บรรจุในหลอดไฟป้ายซึ่งเรืองแสงสีส้มแดงคือสารใด','นีออน','คาร์บอน','ออกซิเจน','ไนโตรเจน',0,'หลอดนีออนให้แสงส้มแดง'),
  ('เกร็ดความรู้เคมีรอบตัว','ความเค็มของน้ำทะเลมาจากสารใดเป็นส่วนใหญ่','โซเดียมคลอไรด์','น้ำมัน','ทราย','น้ำตาล',0,'เกลือแกงคือ NaCl'),
  ('เกร็ดความรู้เคมีรอบตัว','โลหะชนิดใดมีจุดหลอมเหลวต่ำมาก จนหลอมละลายในมือได้','ทังสเตน','เหล็ก','ทองแดง','แกลเลียม',3,'แกลเลียมหลอมเหลวที่ราว 29.8 °C'),
  ('เกร็ดความรู้เคมีรอบตัว','โลหะชนิดใดมีจุดหลอมเหลวสูงมากจนใช้ทำไส้หลอดไฟ','ทังสเตน','ปรอท','ดีบุก','ตะกั่ว',0,'ทังสเตนหลอมเหลวที่เกิน 3,400 °C'),
  ('เกร็ดความรู้เคมีรอบตัว','ก๊าซคาร์บอนไดออกไซด์ที่พืชนำไปใช้ในกระบวนการใด','การย่อยอาหาร','การคายน้ำ','การหายใจเท่านั้น','การสังเคราะห์ด้วยแสง',3,'พืชใช้ CO₂ และน้ำสร้างน้ำตาลและออกซิเจน'),
  ('เกร็ดความรู้เคมีรอบตัว','พืชปล่อยแก๊สใดออกมาจากการสังเคราะห์ด้วยแสง','ไฮโดรเจน','ออกซิเจน','คาร์บอนมอนอกไซด์','ฮีเลียม',1,'ออกซิเจนเป็นผลพลอยได้'),
  ('เกร็ดความรู้เคมีรอบตัว','สีของใบไม้เขียวเกิดจากสารใด','แคลเซียม','ฮีโมโกลบิน','เมลานิน','คลอโรฟิลล์',3,'คลอโรฟิลล์ดูดแสงสีแดงและน้ำเงิน สะท้อนเขียว'),
  ('เกร็ดความรู้เคมีรอบตัว','สีแดงของเลือดเกิดจากสารใด','เคราติน','อะไมเลส','ฮีโมโกลบิน','คลอโรฟิลล์',2,'ฮีโมโกลบินมีเหล็กเป็นองค์ประกอบ'),
  ('เกร็ดความรู้เคมีรอบตัว','เหตุใดไอศกรีมที่ใส่เกลือน้ำแข็งจึงเย็นจัดขึ้น','เกลือทำให้จุดเยือกแข็งของน้ำต่ำลง','เกลือทำให้น้ำแข็งหนักขึ้น','เกลือทำให้น้ำเดือด','เกลือเป็นฉนวนความร้อน',0,'ส่วนผสมเกลือกับน้ำแข็งเย็นกว่า 0 °C'),
  ('เกร็ดความรู้เคมีรอบตัว','น้ำมันกับน้ำไม่ผสมกันเพราะอะไร','น้ำมันมีสีเหลืองเสมอ','โมเลกุลมีสมบัติต่างกัน ไม่ละลายซึ่งกันและกัน','น้ำมันหนักกว่าน้ำเสมอ','น้ำเป็นแก๊ส',1,'น้ำมันไม่มีขั้ว น้ำมีขั้ว จึงแยกชั้น'),
  ('เกร็ดความรู้เคมีรอบตัว','ทำไมท้องฟ้าจึงมีสีฟ้า (ระดับพื้นฐาน)','อากาศมีสีฟ้า','โมเลกุลในอากาศกระเจิงแสงสีน้ำเงินได้ดี','ดวงอาทิตย์เป็นสีฟ้า','ทะเลสะท้อนขึ้นไปทั้งหมด',1,'แสงน้ำเงินกระเจิงมากกว่าแสงแดง'),
  ('เกร็ดความรู้เคมีรอบตัว','ทำไมโลหะบางชนิดจึงเปลี่ยนสีเป็นเขียวเมื่อใช้งานนาน (เช่นรูปปั้นทองแดง)','ทองแดงทำปฏิกิริยากับอากาศ เกิดสนิมสีเขียว','ทองแดงกลายเป็นทอง','ทาสีเขียวไว้เอง','ทองแดงละลายน้ำ',0,'สนิมทองแดงเรียกว่าสนิมเขียว (verdigris)'),
  ('เกร็ดความรู้เคมีรอบตัว','ทำไมกล้วยสุกเมื่อวางใกล้ผลไม้อื่น ผลไม้อื่นจึงสุกเร็วขึ้น','ปล่อยแก๊สเอทิลีนช่วยเร่งการสุก','ปล่อยแก๊สออกซิเจนมาก','ปล่อยความร้อน','มีน้ำตาลมากกว่า',0,'เอทิลีนเป็นฮอร์โมนพืชในรูปแก๊ส'),
  ('เกร็ดความรู้เคมีรอบตัว','ทำไมผลึกน้ำตาลในรูปน้ำตาลกรวดจึงใหญ่ได้','ถูกแช่แข็ง','ถูกหลอมรวมกัน','ตกผลึกช้าๆ จากสารละลายเข้มข้น','ผสมกับน้ำมัน',2,'การตกผลึกช้าทำให้ผลึกใหญ่'),
  ('เกร็ดความรู้เคมีรอบตัว','ลูกบอลกระดอนทำจากวัสดุที่มีสมบัติใด','เปราะแตกง่าย','นำไฟฟ้า','ละลายน้ำ','ยืดหยุ่น',3,'ยางและพอลิเมอร์บางชนิดยืดหยุ่นได้'),
  ('เกร็ดความรู้เคมีรอบตัว','ในโลกของเคมี คำว่า "ธาตุ" ในตารางธาตุมีกี่ธาตุโดยประมาณ','500','50','10','118',3,'ปัจจุบันตารางธาตุมี 118 ธาตุ'),
  ('เกร็ดความรู้เคมีรอบตัว','ใครคือผู้เสนอตารางธาตุที่เรียงตามมวลอะตอมและทำนายธาตุที่ยังไม่ค้นพบได้','ทอมสัน','เมนเดเลเยฟ','ดอลตัน','รัทเทอร์ฟอร์ด',1,'ดมีตรี เมนเดเลเยฟ แห่งรัสเซีย'),
  ('เกร็ดความรู้เคมีรอบตัว','น้ำที่อุณหภูมิ 4 องศาเซลเซียสมีสมบัติพิเศษอย่างไร','กลายเป็นแก๊ส','หนาแน่นที่สุด','เดือดทันที','เบาที่สุด',1,'น้ำมีความหนาแน่นสูงสุดที่ราว 4 °C'),
  ('เกร็ดความรู้เคมีรอบตัว','ทำไมเสื้อสีดำจึงร้อนกว่าเสื้อสีขาวเมื่อตากแดด','สีดำหนักกว่า','สีดำดูดกลืนแสงและความร้อนได้ดี','สีดำมีความร้อนในตัว','สีดำสะท้อนแสงได้ดี',1,'สีเข้มดูดรังสีมากกว่าสีอ่อน'),
  ('เกร็ดความรู้เคมีรอบตัว','หน่วยอุณหภูมิในระบบเอสไอ (SI) คือข้อใด','องศาเมตร','เซลเซียส','เคลวิน','ฟาเรนไฮต์',2,'เคลวิน (K) เป็นหน่วย SI ของอุณหภูมิ'),
  ('เกร็ดความรู้เคมีรอบตัว','กรดในกระเพาะอาหารของคนคือกรดใด','กรดแอซีติก','กรดซัลฟิวริก','กรดซิตริก','กรดไฮโดรคลอริก',3,'HCl ช่วยย่อยอาหารและฆ่าเชื้อโรค'),
  ('เกร็ดความรู้เคมีรอบตัว','ข้อใดเป็นสาเหตุหนึ่งของภาวะโลกร้อนจากแก๊สเรือนกระจก','คาร์บอนไดออกไซด์','ออกซิเจน','อาร์กอน','ฮีเลียม',0,'CO₂ ดักความร้อนในบรรยากาศ'),
  ('เกร็ดความรู้เคมีรอบตัว','ทับทิมสีแดงมีองค์ประกอบหลักเป็นสารใด','อะลูมิเนียมออกไซด์','เหล็กออกไซด์','คาร์บอน','โซเดียมคลอไรด์',0,'ทับทิมคือคอรันดัม (Al₂O₃) ที่มีโครเมียมเจือปนให้สีแดง'),
  ('เกร็ดความรู้เคมีรอบตัว','โลหะใดเบาที่สุดในบรรดาโลหะ','ทองแดง','ตะกั่ว','ลิเทียม','เหล็ก',2,'ลิเทียมมีความหนาแน่นต่ำมาก ใช้ทำแบตเตอรี่'),
  ('เกร็ดความรู้เคมีรอบตัว','การโรยเกลือบนถนนที่มีน้ำแข็งช่วยอะไร','ทำให้น้ำแข็งละลายที่อุณหภูมิต่ำกว่า 0 °C','ทำให้น้ำแข็งหนาขึ้น','ทำให้น้ำแข็งเป็นแก๊ส','ทำให้ถนนร้อนเอง',0,'เกลือลดจุดเยือกแข็งของน้ำ'),
  ('เกร็ดความรู้เคมีรอบตัว','น้ำร้อนละลายน้ำตาลได้เร็วกว่าน้ำเย็นเพราะอะไร','น้ำเย็นเป็นกรด','อนุภาคเคลื่อนที่เร็วกว่าและชนกันบ่อยกว่า','น้ำร้อนมีน้ำตาลอยู่แล้ว','น้ำร้อนหนักกว่า',1,'อุณหภูมิสูงอนุภาคมีพลังงานมากขึ้น')
) as v(topic, question, a, b, c, d, answer, explain)
cross join (select id from classes where name = 'ม.1/1' limit 1) c
where not exists (select 1 from quiz_questions q where q.question = v.question and q.class_id = c.id);
-- 41: สถิติเกมและรางวัล (เฉพาะครู) — ดูว่าเกมไหนมีคนเล่น/แจกรางวัลสูงเกินไปหรือไม่
-- game_stats(p_days) คืน {days, students, active, sources:[{src, grants, players, exp, coins, avg_exp, share_exp}],
--                          spent_coins, promo_claims, top_students:[...]}
create or replace function _ledger_src(p_reason text) returns text
language sql immutable as $$
  select case
    when p_reason is null then 'อื่นๆ'
    when p_reason like 'ควิซประจำวัน%' then '🧠 ควิซประจำวัน'
    when p_reason like 'จับคู่ธาตุ%' then '🧩 จับคู่ธาตุ'
    when p_reason like 'ห้องฝึกเวทย์%' then '⚗️ ห้องฝึกเวทย์'
    when p_reason like 'เคมีรัน%' then '🏃 เคมีรัน'
    when p_reason like '%ประลองครูบุ๊ค%' then '🎓 ประลองครูบุ๊ค'
    when p_reason like '%มอนสเตอร์%' and p_reason not like 'ดรอป%' then '👾 ล่ามอนสเตอร์'
    when p_reason like 'ท้าดวล%' then '⚔️ ท้าดวล'
    when p_reason like 'ปราบบอส%' then '🐉 บอสประจำสัปดาห์'
    when p_reason like 'ของขวัญเปิดระบบ%' then '🎁 โปรโมชันเปิดระบบ'
    when p_reason like 'มาเรียน%' then '📋 เช็คชื่อ'
    when p_reason like 'ส่งงาน%' then '📝 ส่งงาน'
    when p_reason like 'เควส:%' then '🎯 เควส'
    when p_reason like 'Achievement:%' then '🏅 เหรียญรางวัล'
    when p_reason like 'กาชา:%' or p_reason like 'ดรอป%' or p_reason like 'ไอเทมตกแต่งซ้ำ%' then '🎰 กาชา/ของดรอป'
    when p_reason like 'ครูปรับให้%' or p_reason like 'ครูส่งคืนงาน%' then '👩‍🏫 ครูปรับ'
    else 'อื่นๆ' end
$$;

create or replace function game_stats(p_days int default 7) returns json
language plpgsql stable security definer set search_path = public as $$
declare d int := greatest(1, least(coalesce(p_days, 7), 120)); since timestamptz := now() - make_interval(days => d);
        n_stu int; n_act int; srcs json; spent bigint; promo int; top json;
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  select count(*) into n_stu from students;
  select count(distinct student_id) into n_act from ledger where created_at >= since;
  select coalesce(json_agg(r order by r.exp desc), '[]'::json) into srcs from (
    select _ledger_src(reason) as src, count(*) as grants, count(distinct student_id) as players,
           sum(exp) filter (where exp > 0) as exp, sum(coins) filter (where coins > 0) as coins,
           round(avg(exp) filter (where exp > 0), 1) as avg_exp,
           round(100.0 * sum(exp) filter (where exp > 0) / nullif(sum(sum(exp) filter (where exp > 0)) over (), 0), 1) as share_exp
      from ledger where created_at >= since group by 1) r;
  select coalesce(-sum(coins) filter (where coins < 0), 0) into spent from ledger where created_at >= since;
  select count(*) into promo from ledger where ref_key = 'promo:launch';
  select coalesce(json_agg(t), '[]'::json) into top from (
    select s.name, c.name as room, sum(l.exp) as exp, sum(l.coins) filter (where l.coins > 0) as coins
      from ledger l join students s on s.id = l.student_id left join classes c on c.id = s.class_id
     where l.created_at >= since group by s.id, s.name, c.name order by sum(l.exp) desc limit 5) t;
  return json_build_object('days', d, 'students', n_stu, 'active', n_act, 'sources', srcs,
                           'spent_coins', spent, 'promo_claims', promo, 'top_students', top);
end $$;
revoke execute on function game_stats(int) from public, anon;
revoke execute on function _ledger_src(text) from public, anon, authenticated;
grant execute on function game_stats(int) to authenticated;
-- 42: ระบบป้องกันและแจ้งเตือนการโจมตี
-- ส่วนประกอบ: บันทึกเหตุ (security_events) · จำกัดการเดา PIN ต่อ IP · สแกนหาช่องโหว่/ข้อมูลผิดปกติ
--            · เตือนเมื่อรายชื่อครูถูกแก้ · ปุ่มปิดระบบนักเรียนฉุกเฉิน (lockdown)
create table if not exists security_events (
  id bigserial primary key,
  at timestamptz not null default now(),
  kind text not null,
  sev text not null default 'warn' check (sev in ('info','warn','high','critical')),
  student_id uuid references students(id) on delete set null,
  ip text,
  detail text,
  dedupe_key text,
  seen boolean not null default false
);
create unique index if not exists security_events_dedupe on security_events(dedupe_key) where dedupe_key is not null;
create index if not exists security_events_at on security_events(at desc);

create table if not exists login_attempts (
  id bigserial primary key,
  at timestamptz not null default now(),
  ip text,
  acct text
);
create index if not exists login_attempts_ip_at on login_attempts(ip, at desc);

do $$ declare t text; begin
  foreach t in array array['security_events','login_attempts'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists teacher_all on public.%I', t);
    execute format('create policy teacher_all on public.%I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;

-- IP ของผู้เรียก (ถ้า PostgREST ส่งมา)
create or replace function _req_ip() returns text language plpgsql stable as $$
begin
  return nullif(trim(split_part(coalesce((current_setting('request.headers', true))::json->>'x-forwarded-for', ''), ',', 1)), '');
exception when others then return null; end $$;

create or replace function _sec_log(p_kind text, p_sev text, p_student uuid, p_detail text, p_key text default null) returns void
language plpgsql security definer set search_path = public as $$
begin
  insert into security_events(kind, sev, student_id, ip, detail, dedupe_key)
  values (p_kind, p_sev, p_student, _req_ip(), p_detail, p_key) on conflict do nothing;
end $$;
revoke execute on function _req_ip() from public, anon, authenticated;
revoke execute on function _sec_log(text, text, uuid, text, text) from public, anon, authenticated;

-- ตรวจพฤติกรรมเดา PIN ต่อ IP แล้วบันทึกเหตุ (เรียกหลังบันทึกความพยายามที่ผิดทุกครั้ง)
create or replace function _sec_ip_check(p_ip text) returns void
language plpgsql security definer set search_path = public as $$
declare nfail int; naccts int; lim int := _setting_int('sec_ip_limit', 60); sweep int := _setting_int('sec_sweep_accts', 20);
        bucket text := to_char(date_trunc('hour', now()) + floor(extract(minute from now())/10) * interval '10 minutes', 'YYYYMMDDHH24MI');
begin
  if p_ip is null then return; end if;
  select count(*), count(distinct a.acct) into nfail, naccts from login_attempts a where a.ip = p_ip and a.at > now() - interval '10 minutes';
  if naccts >= sweep then
    perform _sec_log('ip_sweep', 'high', null, 'เดา PIN หลายบัญชีจาก IP เดียว (' || naccts || ' บัญชี / ' || nfail || ' ครั้งใน 10 นาที)', 'sweep:' || p_ip || ':' || bucket);
  end if;
  if nfail >= lim then
    perform _sec_log('ip_blocked', 'high', null, 'IP นี้ถูกบล็อกชั่วคราว 10 นาที (ผิด ' || nfail || ' ครั้ง)', 'block:' || p_ip || ':' || bucket);
  end if;
end $$;
revoke execute on function _sec_ip_check(text) from public, anon, authenticated;

-- ล็อกอินนักเรียน: เพิ่มโหมดฉุกเฉิน · จำกัดต่อ IP · บันทึกเหตุผิดปกติ
create or replace function student_login(p_class_code text, p_no int, p_pin text)
returns json language plpgsql security definer set search_path = public, extensions as $$
declare s students%rowtype; t uuid; v_ip text := _req_ip(); acct text; nfail int; naccts int;
        lim int := _setting_int('sec_ip_limit', 60); sweep int := _setting_int('sec_sweep_accts', 20);
        bucket text := to_char(date_trunc('hour', now()) + floor(extract(minute from now())/10) * interval '10 minutes', 'HH24MI');
begin
  if coalesce((select value from app_settings where key = 'sec_lockdown'), '0') = '1' then
    raise exception 'ระบบนักเรียนปิดชั่วคราว (ครูกำลังตรวจสอบความปลอดภัย)';
  end if;
  if v_ip is not null and (select count(*) from login_attempts la where la.ip = v_ip and la.at > now() - interval '10 minutes') >= lim then
    raise exception 'พยายามเข้าสู่ระบบผิดมากเกินไป กรุณารอ 10 นาทีแล้วลองใหม่';
  end if;
  acct := upper(trim(coalesce(p_class_code,''))) || '#' || coalesce(p_no::text, '?');
  select st.* into s from students st join classes c on c.id = st.class_id
   where upper(c.code) = upper(trim(p_class_code)) and st.no = p_no;
  if not found then
    insert into login_attempts(ip, acct) values (v_ip, acct);
    perform _sec_ip_check(v_ip);
    return json_build_object('error', 'ไม่พบห้องหรือเลขที่นี้');
  end if;
  if s.locked_until is not null and s.locked_until > now() then
    raise exception 'ใส่ PIN ผิดหลายครั้ง กรุณารอสักครู่แล้วลองใหม่';
  end if;
  if s.pin_hash is null or crypt(p_pin, s.pin_hash) <> s.pin_hash then
    update students
       set locked_until = case when fail_count + 1 >= 5 then now() + interval '10 minutes' else locked_until end,
           fail_count = case when fail_count + 1 >= 5 then 0 else fail_count + 1 end
     where id = s.id;
    insert into login_attempts(ip, acct) values (v_ip, acct);
    delete from login_attempts where at < now() - interval '2 days' and id % 50 = 0;
    if s.fail_count + 1 >= 5 then
      perform _sec_log('pin_lock', 'warn', s.id, 'ใส่ PIN ผิดครบ 5 ครั้ง ล็อกบัญชี 10 นาที', 'pinlock:' || s.id || ':' || to_char(now(), 'YYYYMMDDHH24') || bucket);
    end if;
    perform _sec_ip_check(v_ip);
    return json_build_object('error', 'PIN ไม่ถูกต้อง');
  end if;
  if s.fail_count >= 3 then
    perform _sec_log('login_after_fails', 'warn', s.id, 'เข้าสู่ระบบสำเร็จหลังใส่ PIN ผิด ' || s.fail_count || ' ครั้ง', 'laf:' || s.id || ':' || to_char(now(), 'YYYYMMDDHH24'));
  end if;
  update students set fail_count = 0, locked_until = null, last_login = now() where id = s.id;
  insert into student_sessions (student_id) values (s.id) returning token into t;
  delete from student_sessions where student_id = s.id and expires_at < now();
  return json_build_object('token', t, 'name', s.name);
end $$;

-- ตรวจจับการแก้รายชื่อครู (ผู้โจมตีมักเพิ่มตัวเองเป็นครู)
create or replace function _trg_teachers_audit() returns trigger
language plpgsql security definer set search_path = public as $$
declare who text := coalesce(auth.jwt()->>'email', 'SQL Editor/ระบบ');
begin
  perform _sec_log('teachers_changed', 'critical', null,
    case TG_OP when 'INSERT' then 'เพิ่มครู ' || new.email when 'DELETE' then 'ลบครู ' || old.email else 'แก้ครู ' || old.email || ' → ' || new.email end || ' โดย ' || who,
    'teachers:' || md5(random()::text));
  return coalesce(new, old);
end $$;
drop trigger if exists teachers_audit on teachers;
create trigger teachers_audit after insert or update or delete on teachers for each row execute function _trg_teachers_audit();

-- สแกนความปลอดภัย (เฉพาะครู) — บันทึกเหตุใหม่ แล้วคืนจำนวนที่พบ
create or replace function security_scan() returns json
language plpgsql security definer set search_path = public as $$
declare r record; n int := 0; day text := to_char(now(), 'YYYYMMDD'); spike int := _setting_int('sec_exp_spike', 600);
begin
  if not is_teacher() then raise exception 'เฉพาะครูเท่านั้น'; end if;
  -- 1) ตารางที่ปิด RLS
  for r in select c.relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
            where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity
              and exists (select 1 from pg_policies pp where pp.schemaname = 'public' and pp.tablename = c.relname and pp.policyname = 'teacher_all') loop
    perform _sec_log('rls_off', 'critical', null, 'ตาราง ' || r.relname || ' ปิด RLS — ใครก็อ่านได้', 'rls:' || r.relname || ':' || day); n := n + 1;
  end loop;
  -- 2) ฟังก์ชันครูที่ anon เรียกได้
  for r in select p.proname from pg_proc p where p.pronamespace = 'public'::regnamespace
            and (p.proname like 'admin\_%' or p.proname in ('health_check','game_stats','security_scan','security_summary'))
            and has_function_privilege('anon', p.oid, 'execute') loop
    perform _sec_log('anon_admin_fn', 'critical', null, 'ฟังก์ชัน ' || r.proname || ' เปิดให้คนทั่วไปเรียกได้', 'fn:' || r.proname || ':' || day); n := n + 1;
  end loop;
  -- 3) anon อ่านตารางสำคัญได้
  for r in select t from unnest(array['students','ledger','student_sessions','teachers','security_events']) t
            where to_regclass('public.' || t) is not null and has_table_privilege('anon', 'public.' || t, 'select') loop
    perform _sec_log('anon_table', 'critical', null, 'anon มีสิทธิ์อ่านตาราง ' || r.t, 'tbl:' || r.t || ':' || day); n := n + 1;
  end loop;
  -- 4) EXP พุ่งผิดปกติใน 1 ชั่วโมง
  for r in select l.student_id, s.name, sum(l.exp) e from ledger l join students s on s.id = l.student_id
            where l.created_at > now() - interval '1 hour' group by 1, 2 having sum(l.exp) > spike loop
    perform _sec_log('exp_spike', 'high', r.student_id, r.name || ' ได้ EXP ' || r.e || ' ใน 1 ชั่วโมง (เกณฑ์ ' || spike || ')', 'spike:' || r.student_id || ':' || day || to_char(now(), 'HH24')); n := n + 1;
  end loop;
  -- 5) เซสชันนักเรียนคนเดียวมากผิดปกติ
  for r in select ss.student_id, count(*) c from student_sessions ss where not ss.observer and ss.expires_at > now() group by 1 having count(*) > 40 loop
    perform _sec_log('many_sessions', 'warn', r.student_id, 'มีเซสชันที่ใช้งานอยู่ ' || r.c || ' รายการ (อาจมีการเข้าซ้ำอัตโนมัติ)', 'sess:' || r.student_id || ':' || day); n := n + 1;
  end loop;
  -- 6) ค่าติดลบ
  if exists (select 1 from students where exp < 0 or coins < 0) then
    perform _sec_log('negative', 'high', null, 'พบ EXP/เหรียญติดลบ ตรวจสอบหน้าสุขภาพระบบ', 'neg:' || day); n := n + 1;
  end if;
  return json_build_object('found', n, 'at', now());
end $$;

-- สรุปให้แบนเนอร์/หน้าแดชบอร์ด
create or replace function security_summary() returns json
language plpgsql security definer set search_path = public as $$
declare ev json; blocked json;
begin
  if not is_teacher() then raise exception 'เฉพาะครูเท่านั้น'; end if;
  select coalesce(json_agg(x order by x.id desc), '[]') into ev from (
    select e.id, e.at, e.kind, e.sev, e.detail, e.ip, e.seen, s.name as student
      from security_events e left join students s on s.id = e.student_id order by e.id desc limit 40) x;
  select coalesce(json_agg(b), '[]') into blocked from (
    select ip, count(*) fails, count(distinct acct) accts from login_attempts
     where ip is not null and at > now() - interval '10 minutes' group by ip having count(*) >= _setting_int('sec_ip_limit', 60)) b;
  return json_build_object(
    'unseen', (select count(*) from security_events where not seen and sev in ('high','critical')),
    'unseen_warn', (select count(*) from security_events where not seen and sev = 'warn'),
    'critical', (select count(*) from security_events where not seen and sev = 'critical'),
    'lockdown', coalesce((select value from app_settings where key = 'sec_lockdown'), '0') = '1',
    'fails_1h', (select count(*) from login_attempts where at > now() - interval '1 hour'),
    'blocked', blocked, 'events', ev);
end $$;

create or replace function admin_sec_ack(p_ids bigint[] default null) returns int
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if not is_teacher() then raise exception 'เฉพาะครูเท่านั้น'; end if;
  update security_events set seen = true where not seen and (p_ids is null or id = any(p_ids));
  get diagnostics n = row_count; return n;
end $$;

create or replace function admin_lockdown(p_on boolean) returns json
language plpgsql security definer set search_path = public as $$
declare n int := 0;
begin
  if not is_teacher() then raise exception 'เฉพาะครูเท่านั้น'; end if;
  insert into app_settings(key, value) values ('sec_lockdown', case when p_on then '1' else '0' end)
    on conflict (key) do update set value = excluded.value;
  if p_on then delete from student_sessions where not observer; get diagnostics n = row_count; end if;
  insert into security_events(kind, sev, detail, seen) values ('lockdown', 'info', case when p_on then 'ครูเปิดโหมดฉุกเฉิน: ปิดระบบนักเรียน เตะเซสชัน ' || n || ' รายการ' else 'ครูปิดโหมดฉุกเฉิน: เปิดระบบนักเรียนแล้ว' end, true);
  return json_build_object('lockdown', p_on, 'kicked', n);
end $$;

create or replace function admin_unblock_ip(p_ip text) returns int
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if not is_teacher() then raise exception 'เฉพาะครูเท่านั้น'; end if;
  delete from login_attempts where ip = p_ip; get diagnostics n = row_count; return n;
end $$;

do $$ declare f text; begin
  foreach f in array array['security_scan()','security_summary()','admin_sec_ack(bigint[])','admin_lockdown(boolean)','admin_unblock_ip(text)'] loop
    execute format('revoke execute on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;
revoke execute on function _trg_teachers_audit() from public, anon, authenticated;
-- 43: ป้องกันสคริปต์/บอท/AI ช่วยเจาะเกม
--  1) ล็อก PIN แบบทวีคูณ  2) จำกัดจำนวนคำสั่งต่อนาทีต่อเซสชัน  3) เกมต้อง "เริ่มเล่น" ที่เซิร์ฟเวอร์ก่อนส่งคะแนน และเวลาต้องสมเหตุสมผล
alter table students add column if not exists lock_level int not null default 0;
alter table student_sessions add column if not exists win_start timestamptz;
alter table student_sessions add column if not exists win_n int not null default 0;

-- ครูเปลี่ยน PIN ใหม่ → ปลดล็อกและรีเซ็ตระดับการล็อกอัตโนมัติ
create or replace function _trg_pin_reset() returns trigger language plpgsql as $$
begin
  if new.pin_hash is distinct from old.pin_hash then new.lock_level := 0; new.fail_count := 0; new.locked_until := null; end if;
  return new;
end $$;
drop trigger if exists students_pin_reset on students;
create trigger students_pin_reset before update of pin_hash on students for each row execute function _trg_pin_reset();

-- ล็อกอินนักเรียน (รอบ 2): ล็อกแบบทวีคูณ 10 นาที → 30 นาที → 90 นาที … สูงสุด 24 ชม. กันเดา PIN 4 หลักด้วยสคริปต์
create or replace function student_login(p_class_code text, p_no int, p_pin text)
returns json language plpgsql security definer set search_path = public, extensions as $$
declare s students%rowtype; t uuid; v_ip text := _req_ip(); acct text; nfail int; naccts int;
        lim int := _setting_int('sec_ip_limit', 60); sweep int := _setting_int('sec_sweep_accts', 20);
        bucket text := to_char(date_trunc('hour', now()) + floor(extract(minute from now())/10) * interval '10 minutes', 'HH24MI');
begin
  if coalesce((select value from app_settings where key = 'sec_lockdown'), '0') = '1' then
    raise exception 'ระบบนักเรียนปิดชั่วคราว (ครูกำลังตรวจสอบความปลอดภัย)';
  end if;
  if v_ip is not null and (select count(*) from login_attempts la where la.ip = v_ip and la.at > now() - interval '10 minutes') >= lim then
    raise exception 'พยายามเข้าสู่ระบบผิดมากเกินไป กรุณารอ 10 นาทีแล้วลองใหม่';
  end if;
  acct := upper(trim(coalesce(p_class_code,''))) || '#' || coalesce(p_no::text, '?');
  select st.* into s from students st join classes c on c.id = st.class_id
   where upper(c.code) = upper(trim(p_class_code)) and st.no = p_no;
  if not found then
    insert into login_attempts(ip, acct) values (v_ip, acct);
    perform _sec_ip_check(v_ip);
    return json_build_object('error', 'ไม่พบห้องหรือเลขที่นี้');
  end if;
  if s.locked_until is not null and s.locked_until > now() then
    raise exception 'ใส่ PIN ผิดหลายครั้ง กรุณารอสักครู่แล้วลองใหม่';
  end if;
  if s.pin_hash is null or crypt(p_pin, s.pin_hash) <> s.pin_hash then
    update students
       set locked_until = case when fail_count + 1 >= 5 then now() + least(interval '24 hours', interval '10 minutes' * power(3, least(lock_level, 6))::int) else locked_until end,
           lock_level = case when fail_count + 1 >= 5 then lock_level + 1 else lock_level end,
           fail_count = case when fail_count + 1 >= 5 then 0 else fail_count + 1 end
     where id = s.id;
    insert into login_attempts(ip, acct) values (v_ip, acct);
    delete from login_attempts where at < now() - interval '2 days' and id % 50 = 0;
    if s.fail_count + 1 >= 5 then
      perform _sec_log('pin_lock', case when s.lock_level >= 2 then 'high' else 'warn' end, s.id, 'ใส่ PIN ผิดครบ 5 ครั้ง ล็อกรอบที่ ' || (s.lock_level + 1) || ' (นานขึ้นทุกรอบ)', 'pinlock:' || s.id || ':' || to_char(now(), 'YYYYMMDDHH24') || bucket);
    end if;
    perform _sec_ip_check(v_ip);
    return json_build_object('error', 'PIN ไม่ถูกต้อง');
  end if;
  if s.fail_count >= 3 then
    perform _sec_log('login_after_fails', 'warn', s.id, 'เข้าสู่ระบบสำเร็จหลังใส่ PIN ผิด ' || s.fail_count || ' ครั้ง', 'laf:' || s.id || ':' || to_char(now(), 'YYYYMMDDHH24'));
  end if;
  update students set fail_count = 0, locked_until = null, lock_level = 0, last_login = now() where id = s.id;
  insert into student_sessions (student_id) values (s.id) returning token into t;
  delete from student_sessions where student_id = s.id and expires_at < now();
  return json_build_object('token', t, 'name', s.name);
end $$;


-- จำกัดอัตราเรียกคำสั่งต่อนาทีต่อเซสชัน (ค่าเริ่มต้น 240/นาที ปรับที่ app_settings.sec_rpc_per_min)
create or replace function _sid(p_token uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare v uuid; o boolean; fn text; n int; lim int := _setting_int('sec_rpc_per_min', 240);
begin
  update student_sessions
     set win_n = case when win_start is null or win_start < now() - interval '1 minute' then 1 else win_n + 1 end,
         win_start = case when win_start is null or win_start < now() - interval '1 minute' then now() else win_start end
   where token = p_token and expires_at > now()
  returning student_id, observer, win_n into v, o, n;
  if v is null then raise exception 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่'; end if;
  if n > lim then raise exception 'ส่งคำสั่งถี่เกินไป กรุณารอสักครู่'; end if;
  if n = lim then
    perform _sec_log('rate_abuse', 'high', v, 'ส่งคำสั่งถึง ' || lim || ' ครั้งใน 1 นาที (อาจเป็นสคริปต์/บอท)', 'rate:' || v || ':' || to_char(now(), 'YYYYMMDDHH24MI'));
  end if;
  if o then
    fn := regexp_replace(coalesce(current_setting('request.path', true), ''), '^.*/', '');
    if fn not in ('student_dashboard','student_extras','hall_of_fame','board_list','celebrations_feed','game_status','spell_status','kb_status','news_list','run_status','timetable_list','promo_status') then
      raise exception 'โหมดส่องนักเรียน: ดูได้อย่างเดียว';
    end if;
  end if;
  return v;
end $$;

-- เกม: ต้องเรียก game_begin ตอนเริ่มเล่น แล้วเซิร์ฟเวอร์เทียบเวลาจริงกับเวลาที่ส่งคะแนน
create table if not exists game_starts (
  student_id uuid not null references students(id) on delete cascade,
  game text not null,
  started_at timestamptz not null default now(),
  primary key (student_id, game)
);
alter table game_starts enable row level security;
drop policy if exists teacher_all on game_starts;
create policy teacher_all on game_starts for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on game_starts from anon;
grant select, insert, update, delete on game_starts to authenticated;

create or replace function game_begin(p_token uuid, p_game text) returns void
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  if p_game not in ('quiz','match','spell','kb','run') then raise exception 'เกมไม่ถูกต้อง'; end if;
  insert into game_starts(student_id, game, started_at) values (sid, p_game, now())
  on conflict (student_id, game) do update set started_at = excluded.started_at;
end $$;

-- ตรวจเวลา: คืนเมื่อผ่าน (และ "ใช้" การเริ่มเกมครั้งนั้น) / error เมื่อไม่ผ่าน
create or replace function _game_check(p_sid uuid, p_game text, p_floor numeric, p_claimed numeric) returns void
language plpgsql security definer set search_path = public as $$
declare st timestamptz; el numeric; need numeric;
begin
  if coalesce((select value from app_settings where key = 'sec_game_timing'), '1') = '0' then return; end if;
  select started_at into st from game_starts where student_id = p_sid and game = p_game;
  if st is null then raise exception 'ยังไม่ได้เริ่มเกม — กรุณารีเฟรชหน้าแล้วเล่นใหม่'; end if;
  el := extract(epoch from (now() - st));
  need := greatest(p_floor, coalesce(p_claimed, 0) * 0.5 - 2);
  if el < need then raise exception 'ผลการเล่นไม่ถูกต้อง (เวลาเล่นสั้นเกินจริง)'; end if;
  delete from game_starts where student_id = p_sid and game = p_game;
end $$;

-- ห่อฟังก์ชันส่งคะแนนเดิม: เปลี่ยนชื่อเดิมเป็น _xxx (ภายใน) แล้วสร้างตัวห่อชื่อเดิมที่ตรวจเวลาก่อน
do $$ begin
  if not exists (select 1 from pg_proc where proname = '_match_submit' and pronamespace = 'public'::regnamespace) then
    alter function match_submit(uuid, int, int, int) rename to _match_submit; end if;
  if not exists (select 1 from pg_proc where proname = '_spell_submit' and pronamespace = 'public'::regnamespace) then
    alter function spell_submit(uuid, int, int, int) rename to _spell_submit; end if;
  if not exists (select 1 from pg_proc where proname = '_kb_submit' and pronamespace = 'public'::regnamespace) then
    alter function kb_submit(uuid, int, boolean, int) rename to _kb_submit; end if;
  if not exists (select 1 from pg_proc where proname = '_run_submit' and pronamespace = 'public'::regnamespace) then
    alter function run_submit(uuid, int, int) rename to _run_submit; end if;
  if not exists (select 1 from pg_proc where proname = '_quiz_submit' and pronamespace = 'public'::regnamespace) then
    alter function quiz_submit(uuid, jsonb) rename to _quiz_submit; end if;
end $$;

create or replace function match_submit(p_token uuid, p_score int, p_pairs int, p_seconds int) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin perform _game_check(sid, 'match', greatest(6, coalesce(p_pairs, 4) * 1.5), p_seconds); return _match_submit(p_token, p_score, p_pairs, p_seconds); end $$;
create or replace function spell_submit(p_token uuid, p_score int, p_spells int, p_seconds int) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin perform _game_check(sid, 'spell', greatest(6, coalesce(p_spells, 1) * 3), p_seconds); return _spell_submit(p_token, p_score, p_spells, p_seconds); end $$;
create or replace function kb_submit(p_token uuid, p_cleared int, p_won boolean, p_seconds int) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin perform _game_check(sid, 'kb', greatest(6, coalesce(p_cleared, 0) * 2), p_seconds); return _kb_submit(p_token, p_cleared, p_won, p_seconds); end $$;
create or replace function run_submit(p_token uuid, p_score int, p_seconds int) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin perform _game_check(sid, 'run', 5, p_seconds); return _run_submit(p_token, p_score, p_seconds); end $$;
create or replace function quiz_submit(p_token uuid, p_answers jsonb) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin perform _game_check(sid, 'quiz', _setting_int('quiz_min_seconds', 8), 0); return _quiz_submit(p_token, p_answers); end $$;

do $$ declare f text; begin
  foreach f in array array['_match_submit(uuid,int,int,int)','_spell_submit(uuid,int,int,int)','_kb_submit(uuid,int,boolean,int)','_run_submit(uuid,int,int)','_quiz_submit(uuid,jsonb)',
                            '_game_check(uuid,text,numeric,numeric)','_trg_pin_reset()'] loop
    execute format('revoke execute on function %s from public, anon, authenticated', f);
  end loop;
  foreach f in array array['match_submit(uuid,int,int,int)','spell_submit(uuid,int,int,int)','kb_submit(uuid,int,boolean,int)','run_submit(uuid,int,int)','quiz_submit(uuid,jsonb)','game_begin(uuid,text)'] loop
    execute format('revoke execute on function %s from public', f);
    execute format('grant execute on function %s to anon, authenticated', f);
  end loop;
end $$;
-- 44: ประกาศ "Mini Guild" แบบ Coming soon บนสไลด์ข่าว (ยังไม่มีระบบกิลด์ — เป็นการประกาศล่วงหน้า)
insert into news_posts (kind, title, summary, body, image, sort)
select 'event', 'Mini Guild · เร็วๆ นี้! 🏰', 'ตั้งกิลด์ 4–5 คน แข่งเป็นที่ 1 ของทุกห้อง 2 สัปดาห์ ตั้งชื่อกิลด์เองได้',
 E'🏰 Mini Guild — เร็วๆ นี้!\n\nกิจกรรมใหม่ 2 สัปดาห์ เริ่มชวนเพื่อนไว้ได้เลย\n• รวมกลุ่ม 4–5 คน ตั้งเป็นกิลด์\n• ตั้งชื่อกิลด์เอง ชื่อจะโชว์หน้าชื่อของสมาชิกทุกคน\n• เล่นเกมและทำเควสเก็บแต้มให้กิลด์ แข่งเป็นอันดับ 1 ของทุกห้อง\n• แต้มยิ่งสูง ยิ่งปลดล็อกของรางวัลมากขึ้น\n\nวันเปิดรับสมัครและกติกาละเอียด ครูจะประกาศอีกครั้ง ระหว่างนี้เล่นเกมและทำเควสสะสมความแข็งแกร่งไว้ก่อน!',
 'assets/news/challenge.jpg', 30
where not exists (select 1 from news_posts where title = 'Mini Guild · เร็วๆ นี้! 🏰');
-- 45: Mini Guild — กิจกรรมกิลด์ 15–30 พ.ย. (ห้องเดียวกัน · จัดอันดับรวมทุกห้อง · ซ่อนอันดับวันสุดท้าย · ครูสุ่มจัดคนที่ยังไม่มีกิลด์)
-- แต้มกิลด์ (GP) = EXP จริงจากเกม/เควส/เช็คชื่อ/ส่งงานในช่วงกิจกรรม (จาก ledger) จำกัดต่อคนต่อวัน · อันดับ = GP เฉลี่ยต่อคน
insert into app_settings(key, value) values
  ('guild_start','2026-11-15'), ('guild_end','2026-11-30'), ('guild_reg_from','2026-11-12'), ('guild_join_until','2026-11-17'),
  ('guild_hide_days','1'), ('guild_min_members','3'), ('guild_max_members','5'), ('guild_gp_cap_day','60'), ('guild_min_personal_gp','40'),
  ('guild_room_bonus_coins','30'),
  ('guild_banned','ควย,เหี้ย,สัส,เย็ด,ไอ้สัตว์,fuck,shit,porn,sex')
on conflict (key) do nothing;

create table if not exists guilds (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references classes(id) on delete cascade,
  name text not null,
  leader_id uuid references students(id) on delete set null,
  renamed boolean not null default false,
  auto boolean not null default false,
  created_at timestamptz not null default now()
);
create unique index if not exists guilds_name_uq on guilds (lower(name));
create table if not exists guild_members (
  student_id uuid primary key references students(id) on delete cascade,
  guild_id uuid not null references guilds(id) on delete cascade,
  joined_at timestamptz not null default now()
);
create index if not exists guild_members_g on guild_members(guild_id);
create table if not exists guild_tiers (
  tier int primary key, label text not null, emoji text not null default '🏅',
  min_avg int not null, coins int not null default 0, pulls int not null default 0, exp int not null default 0
);
create table if not exists guild_prizes (
  rank int primary key, label text not null, coins int not null default 0, pulls int not null default 0, exp int not null default 0
);
insert into guild_tiers(tier,label,emoji,min_avg,coins,pulls,exp) values
  (1,'บรอนซ์','🥉',150,20,0,0), (2,'ซิลเวอร์','🥈',300,30,1,0), (3,'โกลด์','🥇',500,40,2,0), (4,'เลเจนด์','👑',700,60,3,50)
on conflict (tier) do nothing;
insert into guild_prizes(rank,label,coins,pulls,exp) values
  (1,'กิลด์แชมป์เปี้ยน 🏆',100,3,0), (2,'รองแชมป์ 🥈',60,2,0), (3,'อันดับ 3 🥉',40,1,0)
on conflict (rank) do nothing;
-- แท็บแอดมินแก้ตารางผ่านคอลัมน์ id
alter table guild_tiers add column if not exists id uuid not null default gen_random_uuid();
alter table guild_prizes add column if not exists id uuid not null default gen_random_uuid();
create unique index if not exists guild_tiers_id on guild_tiers(id);
create unique index if not exists guild_prizes_id on guild_prizes(id);
do $$ declare t text; begin
  foreach t in array array['guilds','guild_members','guild_tiers','guild_prizes'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists teacher_all on public.%I', t);
    execute format('create policy teacher_all on public.%I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;

-- ---------- ตัวช่วยภายใน ----------
create or replace function _gd(p_key text, p_def text) returns text language sql stable security definer set search_path = public as $$
  select coalesce(nullif((select value from app_settings where key = p_key), ''), p_def) $$;
create or replace function _gp_ok(p_reason text) returns boolean language sql immutable as $$
  -- นับเฉพาะ EXP จากการลงแรงจริง (เกม เควส เช็คชื่อ ส่งงาน บอส) — ไม่นับกาชา/ของดรอป/เหรียญรางวัล/โปรโมชัน/ครูปรับ และเหตุผลที่ไม่รู้จัก (เช่น ครูปรับด้วยข้อความเอง)
  select p_reason is not null and p_reason not like 'Mini Guild%'
     and _ledger_src(p_reason) not in ('อื่นๆ', '🎰 กาชา/ของดรอป', '🏅 เหรียญรางวัล', '🎁 โปรโมชันเปิดระบบ', '👩‍🏫 ครูปรับ') $$;
create or replace function _guild_cfg() returns jsonb language plpgsql stable security definer set search_path = public as $$
declare t date := today_th(); st date := _gd('guild_start','2026-11-15')::date; en date := _gd('guild_end','2026-11-30')::date;
        rf date := _gd('guild_reg_from','2026-11-12')::date; ju date := _gd('guild_join_until','2026-11-17')::date; hd int := _gd('guild_hide_days','1')::int;
begin
  return jsonb_build_object('today', t, 'start', st, 'end', en, 'reg_from', rf, 'join_until', ju, 'hide_days', hd,
    'min_members', _gd('guild_min_members','3')::int, 'max_members', _gd('guild_max_members','5')::int,
    'cap_day', _gd('guild_gp_cap_day','60')::int, 'min_personal', _gd('guild_min_personal_gp','40')::int,
    'phase', case when t < rf then 'soon' when t < st then 'reg' when t <= en then 'running' else 'ended' end,
    'can_edit', (t >= rf and t <= ju and t <= en),
    'hidden', (t <= en and t >= en - (greatest(hd,0) - 1) and hd > 0),
    'days_left', greatest(0, en - t + 1));
end $$;

-- GP รายคนของสมาชิกกิลด์ทุกคน
create or replace function _guild_member_gp() returns table(guild_id uuid, student_id uuid, gp numeric)
language sql stable security definer set search_path = public as $$
  with c as (select _guild_cfg() j),
  w as (select ((j->>'start')::date)::timestamp at time zone 'Asia/Bangkok' st, (((j->>'end')::date + 1)::timestamp at time zone 'Asia/Bangkok') en, (j->>'cap_day')::int cap from c),
  d as (select l.student_id, (l.created_at at time zone 'Asia/Bangkok')::date dt, sum(l.exp) e
          from ledger l, w where l.exp > 0 and l.created_at >= w.st and l.created_at < w.en and _gp_ok(l.reason)
           and l.student_id in (select student_id from guild_members) group by 1, 2)
  select gm.guild_id, gm.student_id, coalesce(sum(least((select cap from w), coalesce(d.e, 0))), 0)::numeric
    from guild_members gm left join d on d.student_id = gm.student_id group by gm.guild_id, gm.student_id $$;

create or replace function _guild_ranks() returns table(guild_id uuid, class_id uuid, name text, size int, total numeric, avg numeric, ranked boolean, rank int, room_rank int)
language sql stable security definer set search_path = public as $$
  with mn as (select (_guild_cfg()->>'min_members')::int m),
  s as (select g.id, g.class_id, g.name, count(mg.student_id)::int size, coalesce(sum(mg.gp),0) total,
               round(coalesce(sum(mg.gp),0) / nullif(count(mg.student_id),0), 1) avg
          from guilds g left join _guild_member_gp() mg on mg.guild_id = g.id group by g.id),
  r as (select s.*, (s.size >= (select m from mn)) ranked from s)
  select r.id, r.class_id, r.name, r.size, r.total, coalesce(r.avg,0), r.ranked,
         case when r.ranked then (rank() over (partition by r.ranked order by coalesce(r.avg,0) desc, r.total desc))::int end,
         case when r.ranked then (rank() over (partition by r.class_id, r.ranked order by coalesce(r.avg,0) desc, r.total desc))::int end
    from r $$;

create or replace function _guild_name_ok(p_name text) returns text language plpgsql stable security definer set search_path = public as $$
declare n text := btrim(coalesce(p_name,'')); w text;
begin
  if char_length(n) < 2 or char_length(n) > 16 then raise exception 'ชื่อกิลด์ต้องยาว 2–16 ตัวอักษร'; end if;
  if n ~ '[[:cntrl:]]' then raise exception 'ชื่อกิลด์มีอักขระที่ใช้ไม่ได้'; end if;
  for w in select btrim(x) from unnest(string_to_array(_gd('guild_banned',''), ',')) x where btrim(x) <> '' loop
    if lower(n) like '%' || lower(w) || '%' then raise exception 'ชื่อกิลด์ไม่เหมาะสม กรุณาตั้งชื่อใหม่'; end if;
  end loop;
  if exists (select 1 from guilds where lower(name) = lower(n)) then raise exception 'ชื่อกิลด์นี้มีคนใช้แล้ว'; end if;
  return n;
end $$;

-- ---------- ฝั่งนักเรียน ----------
create or replace function guild_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cfg jsonb := _guild_cfg(); s students%rowtype; gid uuid; me jsonb := null; hid boolean := (cfg->>'hidden')::boolean;
        rk record; v_avg numeric := 0; tiers jsonb; v_open jsonb := '[]'; pr jsonb := null; mygp numeric := 0; t date := (cfg->>'today')::date;
        en date := (cfg->>'end')::date; ph text := cfg->>'phase';
begin
  select * into s from students where id = sid;
  select guild_id into gid from guild_members where student_id = sid;
  select * into rk from _guild_ranks() where guild_id = gid;
  if gid is not null then
    v_avg := coalesce(rk.avg, 0);
    select coalesce(gp,0) into mygp from _guild_member_gp() where student_id = sid;
    me := jsonb_build_object('id', gid, 'name', rk.name, 'size', rk.size, 'ranked', rk.ranked,
      'leader', exists (select 1 from guilds where id = gid and leader_id = sid),
      'can_rename', exists (select 1 from guilds where id = gid and leader_id = sid and not renamed) and t <= en,
      'auto', (select auto from guilds where id = gid),
      'personal_gp', case when hid then null else mygp end,
      'avg', case when hid then null else v_avg end, 'total', case when hid then null else rk.total end,
      'rank', case when hid then null else rk.rank end, 'room_rank', case when hid then null else rk.room_rank end,
      'members', (select coalesce(jsonb_agg(jsonb_build_object('no', st.no, 'name', st.name, 'avatar', st.avatar, 'me', st.id = sid,
            'leader', gl.leader_id = st.id, 'gp', case when hid then null else mg.gp end) order by (gl.leader_id = st.id) desc, st.no), '[]')
          from guild_members gm join students st on st.id = gm.student_id join guilds gl on gl.id = gm.guild_id
          left join _guild_member_gp() mg on mg.student_id = st.id where gm.guild_id = gid));
  elsif (cfg->>'can_edit')::boolean then
    select coalesce(jsonb_agg(jsonb_build_object('id', g.id, 'name', g.name, 'size', x.n) order by g.name), '[]') into v_open
      from guilds g join (select guild_id, count(*)::int n from guild_members group by guild_id) x on x.guild_id = g.id
     where g.class_id = s.class_id and x.n < (cfg->>'max_members')::int;
  end if;
  select coalesce(jsonb_agg(jsonb_build_object('tier', gt.tier, 'label', gt.label, 'emoji', gt.emoji, 'min_avg', gt.min_avg, 'coins', gt.coins, 'pulls', gt.pulls, 'exp', gt.exp,
      'reached', gid is not null and v_avg >= gt.min_avg,
      'claimed', exists (select 1 from ledger l where l.student_id = sid and l.ref_key = 'guild:tier:' || gt.tier),
      'claimable', gid is not null and v_avg >= gt.min_avg and mygp >= (cfg->>'min_personal')::int and ph in ('running','ended') and t <= en + 3
                   and not exists (select 1 from ledger l where l.student_id = sid and l.ref_key = 'guild:tier:' || gt.tier)) order by gt.tier), '[]') into tiers from guild_tiers gt;
  if ph = 'ended' and gid is not null and rk.rank is not null then
    pr := jsonb_build_object('rank', rk.rank, 'room_rank', rk.room_rank,
      'prize', (select to_jsonb(p) from guild_prizes p where p.rank = rk.rank),
      'room_bonus', case when rk.room_rank = 1 then (_gd('guild_room_bonus_coins','30'))::int else null end,
      'eligible', mygp >= (cfg->>'min_personal')::int and t <= en + 14,
      'claimed_rank', exists (select 1 from ledger l where l.student_id = sid and l.ref_key = 'guild:prize:rank'),
      'claimed_room', exists (select 1 from ledger l where l.student_id = sid and l.ref_key = 'guild:prize:room'));
  end if;
  return json_build_object('cfg', cfg, 'my', me, 'open', v_open, 'tiers', tiers, 'prize', pr, 'class_name', (select name from classes where id = s.class_id));
end $$;

create or replace function guild_board(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cfg jsonb := _guild_cfg(); mygid uuid; rws jsonb;
begin
  select guild_id into mygid from guild_members where student_id = sid;
  if (cfg->>'hidden')::boolean then return json_build_object('cfg', cfg, 'hidden', true, 'rows', '[]'::json); end if;
  select coalesce(jsonb_agg(x order by x.rank), '[]') into rws from (
    select r.rank, r.name, c.name as class_name, r.size, r.avg, (r.guild_id = mygid) as mine, r.room_rank
      from _guild_ranks() r join classes c on c.id = r.class_id where r.ranked order by r.rank limit 30) x;
  return json_build_object('cfg', cfg, 'hidden', false, 'rows', rws,
    'unranked', (select count(*) from _guild_ranks() where not ranked), 'total', (select count(*) from guilds));
end $$;

create or replace function guild_create(p_token uuid, p_name text) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); s students%rowtype; n text; gid uuid;
begin
  if not (_guild_cfg()->>'can_edit')::boolean then raise exception 'ช่วงรับสมัครกิลด์ยังไม่เปิดหรือปิดแล้ว'; end if;
  select * into s from students where id = sid for update;
  if exists (select 1 from guild_members where student_id = sid) then raise exception 'คุณมีกิลด์อยู่แล้ว'; end if;
  n := _guild_name_ok(p_name);
  insert into guilds(class_id, name, leader_id) values (s.class_id, n, sid) returning id into gid;
  insert into guild_members(student_id, guild_id) values (sid, gid);
  return json_build_object('id', gid, 'name', n);
end $$;

create or replace function guild_join(p_token uuid, p_guild uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); s students%rowtype; g guilds%rowtype; n int;
begin
  if not (_guild_cfg()->>'can_edit')::boolean then raise exception 'ช่วงรับสมัครกิลด์ยังไม่เปิดหรือปิดแล้ว'; end if;
  select * into s from students where id = sid for update;
  if exists (select 1 from guild_members where student_id = sid) then raise exception 'คุณมีกิลด์อยู่แล้ว'; end if;
  select * into g from guilds where id = p_guild for update;
  if not found or g.class_id <> s.class_id then raise exception 'ไม่พบกิลด์นี้ในห้องของคุณ'; end if;
  select count(*) into n from guild_members where guild_id = g.id;
  if n >= (_guild_cfg()->>'max_members')::int then raise exception 'กิลด์นี้เต็มแล้ว'; end if;
  insert into guild_members(student_id, guild_id) values (sid, g.id);
  return json_build_object('id', g.id, 'name', g.name);
end $$;

create or replace function guild_leave(p_token uuid) returns void
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); g guilds%rowtype; nxt uuid;
begin
  if not (_guild_cfg()->>'can_edit')::boolean then raise exception 'ช่วงเปลี่ยนกิลด์ปิดแล้ว (ล็อกสมาชิก) ถ้าจำเป็นให้แจ้งครู'; end if;
  select g2.* into g from guilds g2 join guild_members m on m.guild_id = g2.id where m.student_id = sid for update of g2;
  if not found then raise exception 'คุณยังไม่มีกิลด์'; end if;
  delete from guild_members where student_id = sid;
  select student_id into nxt from guild_members where guild_id = g.id order by joined_at limit 1;
  if nxt is null then delete from guilds where id = g.id;
  elsif g.leader_id = sid then update guilds set leader_id = nxt where id = g.id; end if;
end $$;

create or replace function guild_rename(p_token uuid, p_name text) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); g guilds%rowtype; n text;
begin
  if today_th() > (_guild_cfg()->>'end')::date then raise exception 'กิจกรรมจบแล้ว'; end if;
  select * into g from guilds where leader_id = sid for update;
  if not found then raise exception 'เฉพาะหัวหน้ากิลด์เท่านั้น'; end if;
  if g.renamed then raise exception 'เปลี่ยนชื่อได้เพียง 1 ครั้ง (ถ้าจำเป็นให้แจ้งครู)'; end if;
  n := _guild_name_ok(p_name);
  update guilds set name = n, renamed = true where id = g.id;
  return json_build_object('name', n);
end $$;

create or replace function _guild_give(p_sid uuid, p_ref text, p_label text, p_coins int, p_pulls int, p_exp int) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not award(p_sid, p_exp, p_coins, 'Mini Guild: ' || p_label, p_ref) then raise exception 'รับรางวัลนี้ไปแล้ว'; end if;
  if p_pulls > 0 then update students set free_pulls = coalesce(free_pulls, 0) + p_pulls where id = p_sid; end if;
end $$;

create or replace function guild_claim_tier(p_token uuid, p_tier int) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); st json := guild_status(p_token); tr json; gt guild_tiers%rowtype;
begin
  select x into tr from json_array_elements(st->'tiers') x where (x->>'tier')::int = p_tier;
  if tr is null then raise exception 'ไม่พบขั้นรางวัลนี้'; end if;
  if (tr->>'claimed')::boolean then raise exception 'รับรางวัลนี้ไปแล้ว'; end if;
  if not (tr->>'claimable')::boolean then raise exception 'ยังรับไม่ได้ (กิลด์ยังไม่ถึงขั้นนี้ หรือแต้มส่วนตัวของคุณยังไม่ถึงเกณฑ์)'; end if;
  select * into gt from guild_tiers where tier = p_tier;
  perform _guild_give(sid, 'guild:tier:' || p_tier, gt.label, gt.coins, gt.pulls, gt.exp);
  return json_build_object('label', gt.label, 'coins', gt.coins, 'pulls', gt.pulls, 'exp', gt.exp);
end $$;

create or replace function guild_claim_prize(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); st json := guild_status(p_token); pz json := st->'prize'; p guild_prizes%rowtype; got json := '{}'; bc int; any_ boolean := false;
begin
  if pz is null then raise exception 'ยังไม่มีรางวัลอันดับ (กิจกรรมยังไม่จบ หรือกิลด์ไม่ติดอันดับ)'; end if;
  if not (pz->>'eligible')::boolean then raise exception 'แต้มส่วนตัวยังไม่ถึงเกณฑ์ หรือหมดเวลารับรางวัลแล้ว'; end if;
  select * into p from guild_prizes where rank = (pz->>'rank')::int;
  if found and not (pz->>'claimed_rank')::boolean then
    perform _guild_give(sid, 'guild:prize:rank', p.label, p.coins, p.pulls, p.exp); any_ := true;
    got := json_build_object('rank', p.label, 'coins', p.coins, 'pulls', p.pulls, 'exp', p.exp);
  end if;
  bc := nullif(pz->>'room_bonus','')::int;
  if bc is not null and not (pz->>'claimed_room')::boolean then
    perform _guild_give(sid, 'guild:prize:room', 'กิลด์อันดับ 1 ของห้อง', bc, 0, 0); any_ := true;
    got := (got::jsonb || jsonb_build_object('room_coins', bc))::json;
  end if;
  if not any_ then raise exception 'ไม่มีรางวัลอันดับที่ต้องรับ หรือรับไปแล้ว'; end if;
  return got;
end $$;

-- ---------- ฝั่งครู ----------
create or replace function admin_guild_list() returns json
language plpgsql stable security definer set search_path = public as $$
begin
  if not is_teacher() then raise exception 'เฉพาะครูเท่านั้น'; end if;
  return json_build_object('cfg', _guild_cfg(),
    'unassigned', (select coalesce(json_agg(json_build_object('class_id', c.id, 'class', c.name, 'n', x.n) order by c.name), '[]') from classes c
                    join (select s.class_id, count(*)::int n from students s where not coalesce(s.is_gm,false) and not exists (select 1 from guild_members m where m.student_id = s.id) group by s.class_id) x on x.class_id = c.id
                   where c.code <> 'GM'),
    'guilds', (select coalesce(json_agg(json_build_object('id', r.guild_id, 'name', r.name, 'class', c.name, 'class_id', r.class_id, 'size', r.size, 'total', r.total, 'avg', r.avg, 'rank', r.rank, 'room_rank', r.room_rank,
        'auto', g.auto, 'renamed', g.renamed,
        'members', (select coalesce(json_agg(json_build_object('id', st.id, 'no', st.no, 'name', st.name, 'gp', mg.gp, 'leader', g.leader_id = st.id) order by st.no), '[]')
                     from guild_members gm join students st on st.id = gm.student_id left join _guild_member_gp() mg on mg.student_id = st.id where gm.guild_id = r.guild_id))
        order by r.rank nulls last, c.name, r.name), '[]')
      from _guild_ranks() r join guilds g on g.id = r.guild_id join classes c on c.id = r.class_id));
end $$;

create or replace function admin_guild_random(p_class uuid default null) returns json
language plpgsql security definer set search_path = public as $$
declare c record; ids uuid[]; n int; i int; g record; rem int; groups int; base int; extra int; k int; sz int; gid uuid; nm text; seq int; mx int := (_guild_cfg()->>'max_members')::int;
        assigned int := 0; created int := 0; sid uuid; idx int;
begin
  if not is_teacher() then raise exception 'เฉพาะครูเท่านั้น'; end if;
  for c in select cl.id, cl.code from classes cl where (p_class is null or cl.id = p_class) and cl.code <> 'GM' loop
    select coalesce(array_agg(s.id order by random()), '{}') into ids from students s
     where s.class_id = c.id and not coalesce(s.is_gm, false) and not exists (select 1 from guild_members m where m.student_id = s.id);
    n := coalesce(cardinality(ids), 0); i := 1;
    if n = 0 then continue; end if;
    -- 1) เติมกิลด์ที่ยังไม่ถึง 4 คนให้ครบ 4 ก่อน
    for g in select gl.id, count(m.student_id)::int sz from guilds gl left join guild_members m on m.guild_id = gl.id where gl.class_id = c.id group by gl.id having count(m.student_id) < 4 order by count(m.student_id) loop
      sz := g.sz;
      while sz < 4 and i <= n loop insert into guild_members(student_id, guild_id) values (ids[i], g.id); i := i + 1; sz := sz + 1; assigned := assigned + 1; end loop;
    end loop;
    rem := n - i + 1;
    if rem > 0 and rem < 3 then
      -- 2) เหลือน้อยกว่า 3 คน: ใส่กิลด์ที่เล็กที่สุดของห้อง (ถ้ายังไม่มีกิลด์เลย สร้างกิลด์เล็ก)
      while i <= n loop
        select gl.id into gid from guilds gl left join guild_members m on m.guild_id = gl.id where gl.class_id = c.id group by gl.id order by count(m.student_id) limit 1;
        if gid is null then
          seq := 1; loop nm := 'กิลด์ ' || c.code || '-' || seq; exit when not exists (select 1 from guilds where lower(name) = lower(nm)); seq := seq + 1; end loop;
          insert into guilds(class_id, name, leader_id, auto) values (c.id, nm, ids[i], true) returning id into gid; created := created + 1;
        end if;
        insert into guild_members(student_id, guild_id) values (ids[i], gid); i := i + 1; assigned := assigned + 1;
      end loop;
    elsif rem >= 3 then
      -- 3) แบ่งกลุ่มใหม่ขนาด 4–5 คนให้เท่าๆ กัน
      groups := ceil(rem / 5.0)::int; base := rem / groups; extra := rem % groups;
      for k in 1..groups loop
        sz := base + case when k <= extra then 1 else 0 end;
        seq := 1; loop nm := 'กิลด์ ' || c.code || '-' || seq; exit when not exists (select 1 from guilds where lower(name) = lower(nm)); seq := seq + 1; end loop;
        insert into guilds(class_id, name, leader_id, auto) values (c.id, nm, ids[i], true) returning id into gid; created := created + 1;
        for idx in 1..sz loop insert into guild_members(student_id, guild_id) values (ids[i], gid); i := i + 1; assigned := assigned + 1; end loop;
      end loop;
    end if;
  end loop;
  insert into security_events(kind, sev, detail, seen) values ('guild_random', 'info', 'ครูสุ่มจัดนักเรียนเข้ากิลด์ ' || assigned || ' คน (สร้างกิลด์ใหม่ ' || created || ')', true);
  return json_build_object('assigned', assigned, 'created', created);
end $$;

create or replace function admin_guild_rename(p_guild uuid, p_name text) returns void
language plpgsql security definer set search_path = public as $$
declare n text;
begin
  if not is_teacher() then raise exception 'เฉพาะครูเท่านั้น'; end if;
  n := _guild_name_ok(p_name);
  update guilds set name = n where id = p_guild;
end $$;
create or replace function admin_guild_disband(p_guild uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not is_teacher() then raise exception 'เฉพาะครูเท่านั้น'; end if;
  delete from guilds where id = p_guild;
end $$;
create or replace function admin_guild_move(p_student uuid, p_guild uuid default null) returns void
language plpgsql security definer set search_path = public as $$
declare g guilds%rowtype; old uuid; nxt uuid; oldl uuid;
begin
  if not is_teacher() then raise exception 'เฉพาะครูเท่านั้น'; end if;
  select guild_id into old from guild_members where student_id = p_student;
  if p_guild is not null then
    select * into g from guilds where id = p_guild;
    if not found or g.class_id <> (select class_id from students where id = p_student) then raise exception 'กิลด์ต้องอยู่ห้องเดียวกับนักเรียน'; end if;
  end if;
  delete from guild_members where student_id = p_student;
  if p_guild is not null then insert into guild_members(student_id, guild_id) values (p_student, p_guild); end if;
  if old is not null then
    select leader_id into oldl from guilds where id = old;
    select student_id into nxt from guild_members where guild_id = old order by joined_at limit 1;
    if nxt is null then delete from guilds where id = old; elsif oldl = p_student or oldl is null then update guilds set leader_id = nxt where id = old; end if;
  end if;
end $$;

-- ---------- ชื่อกิลด์แสดงบนชื่อนักเรียน: ห่อฟังก์ชันเดิม (เปลี่ยนชื่อเดิมเป็น _xxx) ----------
do $$ begin
  if not exists (select 1 from pg_proc where proname = '_student_dashboard' and pronamespace = 'public'::regnamespace) then
    alter function student_dashboard(uuid) rename to _student_dashboard; end if;
  if not exists (select 1 from pg_proc where proname = '_hall_of_fame' and pronamespace = 'public'::regnamespace) then
    alter function hall_of_fame(uuid) rename to _hall_of_fame; end if;
end $$;

create or replace function student_dashboard(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); r jsonb; tag text;
begin
  r := _student_dashboard(p_token)::jsonb;
  select g.name into tag from guild_members gm join guilds g on g.id = gm.guild_id where gm.student_id = sid;
  if jsonb_typeof(r->'leaderboard') = 'array' then
    r := jsonb_set(r, '{leaderboard}', coalesce((select jsonb_agg(t || jsonb_build_object('guild',
          (select g.name from students s2 join guild_members gm on gm.student_id = s2.id join guilds g on g.id = gm.guild_id
            where s2.class_id = (select class_id from students where id = sid) and s2.name = t->>'name' limit 1))) from jsonb_array_elements(r->'leaderboard') t), '[]'::jsonb));
  end if;
  return jsonb_set(r, '{student,guild}', coalesce(to_jsonb(tag), 'null'::jsonb))::json;
end $$;

create or replace function hall_of_fame(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); r jsonb; o jsonb;
begin
  r := _hall_of_fame(p_token)::jsonb;
  select coalesce(jsonb_agg(
    case when jsonb_typeof(h->'top') = 'array' then
      jsonb_set(h, '{top}', coalesce((select jsonb_agg(t || jsonb_build_object('guild',
          (select g.name from students s join guild_members gm on gm.student_id = s.id join guilds g on g.id = gm.guild_id
            where s.class_id = (h->>'id')::uuid and s.no = (t->>'no')::int))) from jsonb_array_elements(h->'top') t), '[]'::jsonb))
    else h end), '[]'::jsonb) into o from jsonb_array_elements(r) h;
  return o::json;
end $$;

-- โหมดส่องดูกิลด์ได้ (อ่านอย่างเดียว) — ต่อจากรายการเดิมใน 43
create or replace function _sid(p_token uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare v uuid; o boolean; fn text; n int; lim int := _setting_int('sec_rpc_per_min', 240);
begin
  update student_sessions
     set win_n = case when win_start is null or win_start < now() - interval '1 minute' then 1 else win_n + 1 end,
         win_start = case when win_start is null or win_start < now() - interval '1 minute' then now() else win_start end
   where token = p_token and expires_at > now()
  returning student_id, observer, win_n into v, o, n;
  if v is null then raise exception 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่'; end if;
  if n > lim then raise exception 'ส่งคำสั่งถี่เกินไป กรุณารอสักครู่'; end if;
  if n = lim then
    perform _sec_log('rate_abuse', 'high', v, 'ส่งคำสั่งถึง ' || lim || ' ครั้งใน 1 นาที (อาจเป็นสคริปต์/บอท)', 'rate:' || v || ':' || to_char(now(), 'YYYYMMDDHH24MI'));
  end if;
  if o then
    fn := regexp_replace(coalesce(current_setting('request.path', true), ''), '^.*/', '');
    if fn not in ('student_dashboard','student_extras','hall_of_fame','board_list','celebrations_feed','game_status','spell_status','kb_status','news_list','run_status','timetable_list','promo_status','guild_status','guild_board') then
      raise exception 'โหมดส่องนักเรียน: ดูได้อย่างเดียว';
    end if;
  end if;
  return v;
end $$;

-- ---------- สิทธิ์ ----------
do $$ declare f text; begin
  foreach f in array array['_gd(text,text)','_gp_ok(text)','_guild_cfg()','_guild_member_gp()','_guild_ranks()','_guild_name_ok(text)','_guild_give(uuid,text,text,int,int,int)','_student_dashboard(uuid)','_hall_of_fame(uuid)'] loop
    execute format('revoke execute on function %s from public, anon, authenticated', f);
  end loop;
  foreach f in array array['student_dashboard(uuid)','hall_of_fame(uuid)'] loop
    execute format('revoke execute on function %s from public', f);
    execute format('grant execute on function %s to anon, authenticated', f);
  end loop;
  foreach f in array array['guild_status(uuid)','guild_board(uuid)','guild_create(uuid,text)','guild_join(uuid,uuid)','guild_leave(uuid)','guild_rename(uuid,text)','guild_claim_tier(uuid,int)','guild_claim_prize(uuid)'] loop
    execute format('revoke execute on function %s from public', f);
    execute format('grant execute on function %s to anon, authenticated', f);
  end loop;
  foreach f in array array['admin_guild_list()','admin_guild_random(uuid)','admin_guild_rename(uuid,text)','admin_guild_disband(uuid)','admin_guild_move(uuid,uuid)'] loop
    execute format('revoke execute on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

-- ประกาศบนสไลด์ข่าว: เปลี่ยนจาก "เร็วๆ นี้" เป็นรายละเอียดจริง
update news_posts set
  title = 'Mini Guild · 15–30 พ.ย. 🏰',
  summary = 'รวมกิลด์ 4–5 คนในห้องเดียวกัน เก็บแต้มแข่งอันดับรวมทุกห้อง สมัครได้ตั้งแต่ 12 พ.ย.',
  body = E'🏰 Mini Guild · 15–30 พ.ย.\n\n• สมัคร/ตั้งกิลด์ได้ตั้งแต่ 12–17 พ.ย. (ล็อกสมาชิกหลัง 17 พ.ย.)\n• กิลด์ละ 4–5 คน ต้องเป็นห้องเดียวกัน ตั้งชื่อกิลด์เองได้ ชื่อจะโชว์หน้าชื่อของสมาชิก\n• ใครยังไม่มีกิลด์ ครูจะสุ่มจัดให้\n• แต้มกิลด์มาจาก EXP ที่ได้จากเกม เควส เช็คชื่อ และส่งงาน (จำกัดต่อคนต่อวัน ทุกคนต้องช่วยกัน) จัดอันดับด้วยแต้มเฉลี่ยต่อคน เทียบทุกห้อง\n• แต้มยิ่งสูง ยิ่งปลดล็อกรางวัล 4 ขั้น: 🥉 บรอนซ์ 🥈 ซิลเวอร์ 🥇 โกลด์ 👑 เลเจนด์ และมีรางวัลกิลด์อันดับ 1–3 กับอันดับ 1 ของแต่ละห้อง\n• วันที่ 30 พ.ย. ซ่อนอันดับเพื่อความลุ้น ประกาศผลหลังจบกิจกรรม\n\nไปที่เมนู 🏰 กิลด์ ได้เลย!',
  starts_at = '2026-11-12', ends_at = '2026-11-30'
 where title like 'Mini Guild · เร็วๆ นี้%';
-- =====================================================================
-- Chemistria · รอบที่ 79: ไอเทมระดับ Legendary (LEG) — เรทรวม 0.5% กรอบสีแดง (รันซ้ำได้)
--  · อุปกรณ์ถือ 2 ชิ้น + ชุดสวมใส่ 2 ชุด สเตตัสสูงกว่า SSR เล็กน้อย ได้จากกาชาเท่านั้น
--  · ได้ครั้งแรกของแต่ละชิ้น → แถมสิทธิ์ "แลกคะแนนจริง +2 คะแนน" (ครูอนุมัติในแท็บสิทธิพิเศษ) · ซ้ำ = คืน 100 เหรียญ
--  · เรทปรับได้ที่ app_settings.gacha_leg_rate (ค่าเริ่มต้น 0.005 = 0.5%) · ต้องรันหลัง 42–45
-- =====================================================================
insert into app_settings (key, value) values ('gacha_leg_rate', '0.005') on conflict (key) do nothing;

-- เพิ่มระดับ LEG ในตาราง
do $$ declare c record; begin
  for c in select conrelid::regclass t, conname from pg_constraint
            where contype = 'c' and conrelid in ('gacha_items'::regclass, 'decor_items'::regclass) and pg_get_constraintdef(oid) like '%SSR%' loop
    execute format('alter table %s drop constraint %I', c.t, c.conname);
  end loop;
  alter table gacha_items add constraint gacha_items_rarity_chk check (rarity in ('N','R','SR','SSR','LEG'));
  alter table decor_items add constraint decor_items_rarity_chk check (rarity in ('N','R','SR','SSR','LEG'));
  for c in select conname from pg_constraint where contype = 'c' and conrelid = 'celebrations'::regclass and pg_get_constraintdef(oid) like '%ssr%' loop
    execute format('alter table celebrations drop constraint %I', c.conname);
  end loop;
  alter table celebrations add constraint celebrations_kind_chk check (kind in ('ssr','rank','leg'));
end $$;

-- สิทธิ์แลกคะแนนจริง
insert into privileges (name, description, emoji, cost, active)
select 'แลกคะแนนจริง +2 คะแนน', 'ได้จากไอเทม Legendary — กดใช้สิทธิ์แล้วครูอนุมัติ เพิ่มคะแนนเก็บจริง 2 คะแนน', '🎓', null, true
 where not exists (select 1 from privileges where name = 'แลกคะแนนจริง +2 คะแนน');

-- ไอเทม LEG 4 ชิ้น (ภาพ: assets/items/leg_*.png · assets/chars/<คลาส>_crimson*.png)
insert into decor_items (slot, key, name, emoji, rarity, price, sort, image, st_int, st_dil, st_str, st_luk, st_coin, ability)
select v.* from (values
  ('item','img','ดาบผลึกอัคนีโลหิต','🗡️','LEG',null::int,90,'assets/items/leg_sword.png',0,1,4,2,2,'ตำนานแห่งห้องแล็บ · แลกคะแนนจริง +2 คะแนน'),
  ('item','img','คัมภีร์อะตอมโลหิต','📕','LEG',null,91,'assets/items/leg_book.png',4,1,0,2,2,'ตำนานแห่งห้องแล็บ · แลกคะแนนจริง +2 คะแนน'),
  ('outfit','crimsonknight','ชุดอัศวินมังกรโลหิต','🐉','LEG',null,90,null,1,2,3,1,3,'ตำนานแห่งห้องแล็บ · แลกคะแนนจริง +2 คะแนน'),
  ('outfit','crimsonmage','ชุดราชันจอมเวทสีชาด','🔴','LEG',null,91,null,3,2,1,1,3,'ตำนานแห่งห้องแล็บ · แลกคะแนนจริง +2 คะแนน')
) v(slot,key,name,emoji,rarity,price,sort,image,st_int,st_dil,st_str,st_luk,st_coin,ability)
where not exists (select 1 from decor_items d where d.slot = v.slot and d.name = v.name);

insert into gacha_items (name, rarity, kind, value, emoji, weight, decor_id)
select d.name, 'LEG', 'decor', 0, d.emoji, 1, d.id from decor_items d
 where d.rarity = 'LEG' and not exists (select 1 from gacha_items g where g.decor_id = d.id);

-- สุ่ม: ทอย LEG ก่อนด้วยเรทคงที่ (ไม่ขึ้นกับจำนวนไอเทมอื่นในตู้) แล้วค่อยสุ่มปกติ (ไม่รวม LEG)
create or replace function _gacha_pick_luk(p_high boolean, p_luk int) returns gacha_items
language plpgsql security definer set search_path = public as $$
declare total numeric; r numeric; acc numeric := 0; it gacha_items%rowtype; last_it gacha_items%rowtype; w numeric;
        rate numeric := least(greatest(coalesce((select value::numeric from app_settings where key = 'gacha_leg_rate'), 0.005), 0), 1); n int;
begin
  select count(*) into n from gacha_items where active and rarity = 'LEG';
  if n > 0 and random() < rate then
    select * into it from gacha_items where active and rarity = 'LEG' order by random() limit 1;
    return it;
  end if;
  select coalesce(sum(weight * case when rarity in ('SR','SSR') then 1 + 0.03 * greatest(p_luk, 0) else 1 end), 0) into total
    from gacha_items where active and rarity <> 'LEG' and (not p_high or rarity in ('SR','SSR'));
  if total = 0 then raise exception 'ยังไม่มีไอเทมในกาชา'; end if;
  r := random() * total;
  for it in select * from gacha_items where active and rarity <> 'LEG' and (not p_high or rarity in ('SR','SSR')) order by id loop
    w := it.weight * case when it.rarity in ('SR','SSR') then 1 + 0.03 * greatest(p_luk, 0) else 1 end;
    acc := acc + w; last_it := it;
    if r < acc then return it; end if;
  end loop;
  return last_it;
end $$;
revoke execute on function _gacha_pick_luk(boolean, int) from public, anon, authenticated;

-- สุ่มกาชา (ฉบับ LEG: รีเซ็ตการันตี · ซ้ำคืน 100 เหรียญ · ได้ครั้งแรกแถมสิทธิ์แลกคะแนน)
create or replace function gacha_pull(p_token uuid, p_n int default 1) returns json
language plpgsql security definer set search_path = public as $$
declare
  sid uuid := _sid(p_token); s students%rowtype;
  unit int := coalesce((select value::int from app_settings where key = 'gacha_cost'), 30);
  pity_max int := coalesce((select value::int from app_settings where key = 'pity_max'), 10);
  cost int; i int; it gacha_items%rowtype; high boolean; res jsonb := '[]'::jsonb; refund int := 0; free boolean := false; first_leg boolean; leg_priv uuid := (select id from privileges where name = 'แลกคะแนนจริง +2 คะแนน' and active limit 1);
begin
  if student_class(sid) = 'seeker' then pity_max := greatest(3, pity_max - 2); end if;
  if p_n not in (1, 10) then raise exception 'จำนวนครั้งไม่ถูกต้อง'; end if;
  select * into s from students where id = sid for update;
  if p_n = 1 and s.free_pulls > 0 then
    free := true; cost := 0;
    update students set free_pulls = free_pulls - 1 where id = sid;
  else
    cost := unit * p_n;
    if s.coins < cost then raise exception 'เหรียญไม่พอ (ต้องใช้ % เหรียญ)', cost; end if;
    update students set coins = coins - cost where id = sid;
  end if;
  for i in 1..p_n loop
    select * into s from students where id = sid;
    high := s.gacha_pity + 1 >= pity_max;
    it := _gacha_pick_luk(high, coalesce((_stats(sid)->'luk'->>'total')::int, 0));
    first_leg := false;
    if it.rarity in ('SR','SSR','LEG') then
      update students set gacha_pity = 0 where id = sid;
    else
      update students set gacha_pity = gacha_pity + 1 where id = sid;
    end if;
    insert into gacha_pulls (student_id, item_id, cost) values (sid, it.id, case when free then 0 else unit end);
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
        refund := case it.rarity when 'LEG' then 100 when 'SSR' then 40 when 'SR' then 20 when 'R' then 10 else 5 end;
        perform award(sid, 0, refund, 'ไอเทมตกแต่งซ้ำ: ' || it.name, null);
      else
        insert into student_decor (student_id, item_id, source) values (sid, it.decor_id, 'gacha');
        refund := 0;
        if it.rarity = 'LEG' and leg_priv is not null then   -- ได้ไอเทมตำนานครั้งแรก: แถมสิทธิ์แลกคะแนนจริง 2 คะแนน
          insert into redemptions (student_id, privilege_id, source) values (sid, leg_priv, 'gacha');
        end if;
      end if;
    end if;
    res := res || jsonb_build_object('name', it.name, 'rarity', it.rarity, 'kind', it.kind,
                                     'value', it.value, 'emoji', it.emoji, 'image', it.image_url,
                                     'dup_refund', case when it.kind = 'decor' then refund else 0 end);
  end loop;
  perform check_achievements(sid);
  select * into s from students where id = sid;
  return json_build_object('items', res, 'coins', s.coins, 'exp', s.exp, 'pity', s.gacha_pity, 'used_free', free, 'free_pulls', s.free_pulls);
end $$;
revoke execute on function gacha_pull(uuid, int) from public;
grant execute on function gacha_pull(uuid, int) to anon, authenticated;

-- ประกาศแสดงความยินดี: ได้ SSR / LEG
create or replace function trg_cel_ssr() returns trigger
language plpgsql security definer set search_path = public as $$
declare it gacha_items%rowtype; cid uuid;
begin
  if _setting_int('celebrate_enabled', 1) = 0 then return new; end if;
  select * into it from gacha_items where id = new.item_id;
  if found and it.rarity in ('SSR','LEG') then
    select class_id into cid from students where id = new.student_id;
    insert into celebrations (class_id, student_id, kind, title, emoji, image)
    values (cid, new.student_id, case when it.rarity = 'LEG' then 'leg' else 'ssr' end, it.name, it.emoji, it.image_url);
  end if;
  return new;
end $$;
revoke execute on function trg_cel_ssr() from public, anon, authenticated;

-- ประกาศข่าว/อีเว้นท์
insert into news_posts (kind, title, summary, body, image, starts_at, ends_at, sort, active)
select 'event', 'เปิดตู้ตำนาน! Legendary 0.5% 🔴', 'ของระดับตำนานกรอบสีแดง อุปกรณ์ 2 + ชุด 2 · เรทเริ่ม 0.01% ยิ่งสุ่มยิ่งเพิ่มสูงสุด 0.5%', E'🔴 เปิดตู้ตำนาน! ไอเทมระดับ LEGENDARY\n\n• โอกาสออกเริ่มที่ 0.01% แล้วยิ่งสุ่มยิ่งเพิ่มขึ้นจนสูงสุด 0.5% ต่อครั้ง (ได้แล้วเริ่มนับใหม่) · กรอบสีแดง\n• อุปกรณ์ในตำนาน 2 ชิ้น: 🗡️ ดาบผลึกอัคนีโลหิต · 📕 คัมภีร์อะตอมโลหิต\n• ชุดสวมใส่ในตำนาน 2 ชุด: 🐉 ชุดอัศวินมังกรโลหิต · 🔴 ชุดราชันจอมเวทสีชาด\n• เพิ่มสเตตัสสูงกว่า SSR เล็กน้อยกว่าไอเทมทุกระดับ (ปัญญา/ขยัน/พลัง/โชค + โบนัสเหรียญ)\n• ได้ครั้งแรกของแต่ละชิ้น แถมสิทธิ์ "แลกคะแนนจริง +2 คะแนน" ให้กดขอครูในเมนู 🎟️ สิทธิพิเศษ\n• ซ้ำจะคืนเหรียญ 100 🪙\n\nไปสุ่มที่เมนู 🎰 กาชา ได้เลย — ขอให้โชคดี!', 'assets/news/legendary.jpg', today_th(), today_th() + 30, 1, true
 where not exists (select 1 from news_posts where title like 'เปิดตู้ตำนาน!%');
-- =====================================================================
-- 47: แก้บั๊ก "หน้าข่าว/ตารางสอน/โปรโมชันไม่ขึ้น" หลังรัน SQL 43
--  สาเหตุ: SQL 43 ทำให้ _sid() บันทึกจำนวนคำสั่งต่อนาที (UPDATE) แต่ news_list / timetable_list / promo_status
--  ประกาศเป็น STABLE (ห้ามเขียนข้อมูล) จึงล้มเหลวทุกครั้ง → เปลี่ยนเป็น VOLATILE (รันซ้ำได้)
-- =====================================================================
alter function news_list(uuid) volatile;
alter function timetable_list(uuid) volatile;
alter function promo_status(uuid) volatile;
-- กันพลาดในอนาคต: ฟังก์ชันอื่นที่เรียก _sid แต่ยังเป็น STABLE/IMMUTABLE จะถูกแก้ให้ด้วย
do $$ declare r record; begin
  for r in select p.oid::regprocedure f from pg_proc p join pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'public' and p.provolatile <> 'v' and p.prosrc ~ '_sid\(' and p.proname <> '_sid' loop
    execute format('alter function %s volatile', r.f);
  end loop;
end $$;
-- 48: ลดสเตตัสไอเทม Legendary ลง (รันซ้ำได้) — สำหรับคนที่รัน 46 รุ่นแรกไปแล้ว
-- รวมต่อชิ้น = 7 (เดิม 13–18) · สูงกว่า SSR สูงสุดเล็กน้อย · ครูปรับต่อได้ที่แท็บ 🎨 ตกแต่ง
update decor_items set st_int=0, st_dil=1, st_str=4, st_luk=2, st_coin=2 where rarity='LEG' and name='ดาบผลึกอัคนีโลหิต';
update decor_items set st_int=4, st_dil=1, st_str=0, st_luk=2, st_coin=2 where rarity='LEG' and name='คัมภีร์อะตอมโลหิต';
update decor_items set st_int=1, st_dil=2, st_str=3, st_luk=1, st_coin=3 where rarity='LEG' and name='ชุดอัศวินมังกรโลหิต';
update decor_items set st_int=3, st_dil=2, st_str=1, st_luk=1, st_coin=3 where rarity='LEG' and name='ชุดราชันจอมเวทสีชาด';
-- =====================================================================
-- 49: ลดอัตราผลของสเตตัสโดยรวม (ค่าเริ่มต้น = 50% ของเดิม) · รันซ้ำได้
--  ตั้งค่า app_settings.stat_effect_pct (100 = เท่าเดิม · 50 = ครึ่งหนึ่ง · 0 = ปิดผลสเตตัส)
--  ผลที่ลดตามสัดส่วน: ขยัน (+EXP%), ปัญญา (+EXP ควิซ), พลัง (+ดาเมจบอส/ดวล), โชค (+โอกาส SR/SSR), โบนัสเหรียญ% ของไอเทม
--  ตัวเลขแต้มสเตตัสเองไม่เปลี่ยน แปลงเฉพาะ "ผล" ที่ได้ (แอปแสดงผลจากเซิร์ฟเวอร์อัตโนมัติ)
-- =====================================================================
insert into app_settings (key, value) values ('stat_effect_pct', '50') on conflict (key) do nothing;

do $$
declare d text; n text; k text := '_setting_int(''stat_effect_pct'', 50) / 100.0';
begin
  -- _stats: ลดค่า effects
  d := pg_get_functiondef('_stats(uuid)'::regprocedure);
  if d not like '%stat_effect_pct%' then
    n := d;
    n := replace(n, '''quiz_exp'', (b_int + p_int + i_int) / 2', '''quiz_exp'', floor((b_int + p_int + i_int) / 2.0 * ' || k || ')::int');
    n := replace(n, '''exp_pct'', b_dil + p_dil + i_dil', '''exp_pct'', round((b_dil + p_dil + i_dil) * ' || k || ')::int');
    n := replace(n, '''boss_pct'', 3 * (b_str + p_str + i_str)', '''boss_pct'', round(3 * (b_str + p_str + i_str) * ' || k || ')::int');
    n := replace(n, '''rare_pct'', 3 * (b_luk + p_luk + i_luk)', '''rare_pct'', round(3 * (b_luk + p_luk + i_luk) * ' || k || ')::int');
    n := replace(n, '''coin_pct'', i_coin', '''coin_pct'', round(i_coin * ' || k || ')::int');
    if n = d or n not like '%stat_effect_pct%' then raise exception '_stats: ไม่พบข้อความที่ต้องแก้'; end if;
    execute n;
  end if;
  -- award: โบนัส EXP ขยันใช้ค่า effects
  d := pg_get_functiondef('award(uuid,int,int,text,text)'::regprocedure);
  if d like '%''dil''->>''total''%' then
    n := replace(d, '(_stats(p_student)->''dil''->>''total'')::int', '(_stats(p_student)->''effects''->>''exp_pct'')::int');
    if n = d then raise exception 'award: ไม่พบข้อความที่ต้องแก้'; end if;
    execute n;
  end if;
  -- ควิซ: โบนัสปัญญา
  d := pg_get_functiondef('_quiz_submit(uuid,jsonb)'::regprocedure);
  if d like '%''int''->>''total''%' then
    n := replace(d, '(_stats(sid)->''int''->>''total'')::int, 0) / 2', '(_stats(sid)->''effects''->>''quiz_exp'')::int, 0)');
    if n = d then raise exception '_quiz_submit: ไม่พบข้อความที่ต้องแก้'; end if;
    execute n;
  end if;
  -- ดาเมจบอสจากเควส: พลัง
  d := pg_get_functiondef('trg_claim_dmg()'::regprocedure);
  if d like '%0.03 * s%' then
    n := replace(replace(d, '(_stats(new.student_id)->''str''->>''total'')::int', '(_stats(new.student_id)->''effects''->>''boss_pct'')::int'), '(1 + 0.03 * s)', '(1 + s / 100.0)');
    if n = d then raise exception 'trg_claim_dmg: ไม่พบข้อความที่ต้องแก้'; end if;
    execute n;
  end if;
  -- กาชา: โชคเพิ่มน้ำหนัก SR/SSR
  d := pg_get_functiondef('_gacha_pick_luk(boolean,int)'::regprocedure);
  if d not like '%stat_effect_pct%' then
    n := replace(d, '0.03 * greatest(p_luk, 0)', '(0.03 * _setting_int(''stat_effect_pct'', 50) / 100.0) * greatest(p_luk, 0)');
    if n = d then raise exception '_gacha_pick_luk: ไม่พบข้อความที่ต้องแก้'; end if;
    execute n;
  end if;
end $$;
revoke execute on function _stats(uuid) from public, anon, authenticated;
revoke execute on function award(uuid,int,int,text,text) from public, anon, authenticated;
revoke execute on function _gacha_pick_luk(boolean,int) from public, anon, authenticated;
-- =====================================================================
-- 50: เรท Legendary แบบไต่ระดับ — ครั้งแรก 0.01% ยิ่งสุ่มไม่ได้ยิ่งเพิ่ม สูงสุด 0.5% (รันซ้ำได้ · ต้องรันหลัง 46)
--  ตั้งค่า app_settings: gacha_leg_rate_min (0.0001 = 0.01%) · gacha_leg_rate (0.005 = 0.5% สูงสุด) · gacha_leg_ramp (100 = สุ่มกี่ครั้งถึงเรทสูงสุด)
--  ตัวนับ students.leg_pulls: +1 ทุกครั้งที่สุ่ม · รีเซ็ตเป็น 0 เมื่อได้ LEG (กลับไปเริ่มที่เรทต่ำ)
-- =====================================================================
alter table students add column if not exists leg_pulls int not null default 0;
insert into app_settings (key, value) values ('gacha_leg_rate_min', '0.0001'), ('gacha_leg_ramp', '100') on conflict (key) do nothing;

create or replace function _leg_rate(p_sid uuid) returns numeric
language plpgsql security definer set search_path = public as $$
declare mx numeric := least(greatest(coalesce((select value::numeric from app_settings where key = 'gacha_leg_rate'), 0.005), 0), 1);
        mn numeric := least(greatest(coalesce((select value::numeric from app_settings where key = 'gacha_leg_rate_min'), 0.0001), 0), 1);
        ramp int := greatest(coalesce(_setting_int('gacha_leg_ramp', 100), 100), 2);
        n int := coalesce((select leg_pulls from students where id = p_sid), 0);
begin
  mn := least(mn, mx);
  return mn + (mx - mn) * least(n, ramp - 1)::numeric / (ramp - 1);
end $$;
revoke execute on function _leg_rate(uuid) from public, anon, authenticated;

-- สุ่มของ (ใช้เรท LEG ตามจำนวนครั้งที่สุ่มสะสมของนักเรียน)
create or replace function _gacha_pick_luk(p_high boolean, p_luk int, p_sid uuid) returns gacha_items
language plpgsql security definer set search_path = public as $$
declare total numeric; r numeric; acc numeric := 0; it gacha_items%rowtype; last_it gacha_items%rowtype; w numeric;
        rate numeric := _leg_rate(p_sid); n int;
        k numeric := 0.03 * _setting_int('stat_effect_pct', 50) / 100.0;
begin
  select count(*) into n from gacha_items where active and rarity = 'LEG';
  if n > 0 and random() < rate then
    select * into it from gacha_items where active and rarity = 'LEG' order by random() limit 1;
    return it;
  end if;
  select coalesce(sum(weight * case when rarity in ('SR','SSR') then 1 + k * greatest(p_luk, 0) else 1 end), 0) into total
    from gacha_items where active and rarity <> 'LEG' and (not p_high or rarity in ('SR','SSR'));
  if total = 0 then raise exception 'ยังไม่มีไอเทมในกาชา'; end if;
  r := random() * total;
  for it in select * from gacha_items where active and rarity <> 'LEG' and (not p_high or rarity in ('SR','SSR')) order by id loop
    w := it.weight * case when it.rarity in ('SR','SSR') then 1 + k * greatest(p_luk, 0) else 1 end;
    acc := acc + w; last_it := it;
    if r < acc then return it; end if;
  end loop;
  return last_it;
end $$;
revoke execute on function _gacha_pick_luk(boolean, int, uuid) from public, anon, authenticated;

-- gacha_pull: ส่ง sid เข้าไปคำนวณเรท + อัปเดตตัวนับ
do $$ declare d text; n text; begin
  d := pg_get_functiondef('gacha_pull(uuid,int)'::regprocedure);
  if d not like '%leg_pulls%' then
    n := replace(d, '_gacha_pick_luk(high, coalesce((_stats(sid)->''luk''->>''total'')::int, 0))', '_gacha_pick_luk(high, coalesce((_stats(sid)->''luk''->>''total'')::int, 0), sid)');
    n := replace(n, 'first_leg := false;', 'first_leg := false;' || chr(10) || '    update students set leg_pulls = case when it.rarity = ''LEG'' then 0 else leg_pulls + 1 end where id = sid;');
    if n = d or n not like '%leg_pulls%' or n not like '%, sid)%' then raise exception 'gacha_pull: ไม่พบข้อความที่ต้องแก้ (ต้องรัน 46 ก่อน)'; end if;
    execute n;
  end if;
end $$;
drop function if exists _gacha_pick_luk(boolean, int);

-- อัปเดตข้อความประกาศ
update news_posts set summary = 'ของระดับตำนานกรอบสีแดง อุปกรณ์ 2 + ชุด 2 · เรทเริ่ม 0.01% ยิ่งสุ่มยิ่งเพิ่มสูงสุด 0.5%',
  body = replace(body, '• โอกาสออกรวม 0.5% ต่อการสุ่ม 1 ครั้ง (กรอบสีแดง)', '• โอกาสออกเริ่มที่ 0.01% แล้วยิ่งสุ่มยิ่งเพิ่มขึ้นจนสูงสุด 0.5% ต่อครั้ง (ได้แล้วเริ่มนับใหม่) · กรอบสีแดง')
 where title like 'เปิดตู้ตำนาน!%';
-- =====================================================================
-- 51: แจกของขวัญให้นักเรียนหลายคนพร้อมกัน (แอดมิน → แท็บ 🎁 ของขวัญ) · รันซ้ำได้
--  ของขวัญ = EXP / เหรียญ / ตั๋วกาชาฟรี / ไอเทมตกแต่ง / สิทธิพิเศษ + ข้อความจากครู · นักเรียนเห็นป๊อปอัปครั้งเดียวเมื่อเปิดแอป
-- =====================================================================
create table if not exists gifts (
  id uuid primary key default gen_random_uuid(),
  batch uuid not null,
  student_id uuid not null references students(id) on delete cascade,
  message text not null default '',
  exp int not null default 0, coins int not null default 0, pulls int not null default 0,
  decor_id uuid references decor_items(id) on delete set null,
  privilege_id uuid references privileges(id) on delete set null,
  seen boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists gifts_student on gifts(student_id, seen);
alter table gifts enable row level security;
drop policy if exists teacher_all on gifts;
create policy teacher_all on gifts for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on gifts from anon;

-- แจกของขวัญ: p_students = รายชื่อนักเรียน (uuid[])
create or replace function admin_gift(p_students uuid[], p_exp int default 0, p_coins int default 0, p_pulls int default 0,
                                      p_decor uuid default null, p_priv uuid default null, p_message text default '')
returns json language plpgsql security definer set search_path = public as $$
declare sid uuid; b uuid := gen_random_uuid(); n int := 0; dup int := 0; ids uuid[]; msg text := left(coalesce(btrim(p_message), ''), 200);
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  select array_agg(distinct x) into ids from unnest(coalesce(p_students, '{}')) x;
  if ids is null or cardinality(ids) = 0 then raise exception 'ยังไม่ได้เลือกนักเรียน'; end if;
  if cardinality(ids) > 600 then raise exception 'เลือกนักเรียนได้ครั้งละไม่เกิน 600 คน'; end if;
  if coalesce(p_exp, 0) < 0 or coalesce(p_coins, 0) < 0 or coalesce(p_pulls, 0) < 0 then raise exception 'จำนวนต้องไม่ติดลบ (ถ้าจะหักให้ใช้ ± EXP/เหรียญ ในแท็บนักเรียน)'; end if;
  if p_exp > 10000 or p_coins > 10000 or p_pulls > 50 then raise exception 'จำนวนมากเกินไป (EXP/เหรียญ ≤ 10000 · ตั๋ว ≤ 50)'; end if;
  if coalesce(p_exp, 0) = 0 and coalesce(p_coins, 0) = 0 and coalesce(p_pulls, 0) = 0 and p_decor is null and p_priv is null then raise exception 'ยังไม่ได้เลือกของขวัญ'; end if;
  if p_decor is not null and not exists (select 1 from decor_items where id = p_decor) then raise exception 'ไม่พบไอเทมตกแต่ง'; end if;
  if p_priv is not null and not exists (select 1 from privileges where id = p_priv) then raise exception 'ไม่พบสิทธิพิเศษ'; end if;
  for sid in select id from students where id = any(ids) loop
    if coalesce(p_exp, 0) > 0 or coalesce(p_coins, 0) > 0 then
      perform award(sid, coalesce(p_exp, 0), coalesce(p_coins, 0), '🎁 ของขวัญจากครู' || case when msg <> '' then ': ' || msg else '' end, 'gift:' || b);
    end if;
    if coalesce(p_pulls, 0) > 0 then update students set free_pulls = free_pulls + p_pulls where id = sid; end if;
    if p_decor is not null then
      insert into student_decor (student_id, item_id, source) values (sid, p_decor, 'teacher') on conflict do nothing;
      if not found then dup := dup + 1; end if;
    end if;
    if p_priv is not null then insert into redemptions (student_id, privilege_id, source) values (sid, p_priv, 'teacher'); end if;
    insert into gifts (batch, student_id, message, exp, coins, pulls, decor_id, privilege_id)
    values (b, sid, msg, coalesce(p_exp, 0), coalesce(p_coins, 0), coalesce(p_pulls, 0), p_decor, p_priv);
    n := n + 1;
  end loop;
  perform check_achievements(s.id) from students s where s.id = any(ids);
  return json_build_object('given', n, 'decor_already_owned', dup, 'batch', b);
end $$;
revoke execute on function admin_gift(uuid[], int, int, int, uuid, uuid, text) from public, anon;
grant execute on function admin_gift(uuid[], int, int, int, uuid, uuid, text) to authenticated;

-- นักเรียน: ของขวัญที่ยังไม่เคยเห็น + กดรับทราบ
create or replace function gift_inbox(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  return coalesce((select json_agg(json_build_object('id', g.id, 'message', g.message, 'exp', g.exp, 'coins', g.coins, 'pulls', g.pulls,
            'decor', d.name, 'decor_emoji', d.emoji, 'privilege', p.name, 'at', g.created_at) order by g.created_at)
          from gifts g left join decor_items d on d.id = g.decor_id left join privileges p on p.id = g.privilege_id
         where g.student_id = sid and not g.seen), '[]'::json);
end $$;
create or replace function gift_ack(p_token uuid) returns void
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin update gifts set seen = true where student_id = sid and not seen; end $$;
revoke execute on function gift_inbox(uuid), gift_ack(uuid) from public;
grant execute on function gift_inbox(uuid), gift_ack(uuid) to anon, authenticated;
-- =====================================================================
-- 52: ตรวจงานด้วย QR — นักเรียนโชว์ QR (เปลี่ยนรหัสทุก 30 วินาที) ครูสแกนแล้วบันทึกส่งงาน + คะแนน + EXP · รันซ้ำได้
-- =====================================================================
create table if not exists app_secrets (key text primary key, value text not null);
alter table app_secrets enable row level security;
revoke all on app_secrets from anon, authenticated;
insert into app_secrets (key, value) values ('qr', gen_random_uuid()::text || gen_random_uuid()::text) on conflict do nothing;

create or replace function _qr_sig(p_sid uuid, p_w bigint) returns text
language sql stable security definer set search_path = public as $$
  select left(encode(sha256(convert_to((select value from app_secrets where key = 'qr') || p_sid::text || ':' || p_w::text, 'utf8')), 'hex'), 20) $$;
revoke execute on function _qr_sig(uuid, bigint) from public, anon, authenticated;

-- นักเรียน: ขอ QR ของตัวเอง (หมดอายุเร็ว — แคปภาพส่งต่อไม่ได้)
create or replace function my_qr(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); w bigint := floor(extract(epoch from now()) / 30);
begin
  return json_build_object('code', 'KB1.' || sid || '.' || w || '.' || _qr_sig(sid, w), 'ttl', 30 - (extract(epoch from now())::bigint % 30));
end $$;
revoke execute on function my_qr(uuid) from public;
grant execute on function my_qr(uuid) to anon, authenticated;

-- ครู: สแกน QR แล้วบันทึกส่งงาน (ได้ EXP/เหรียญตามงานโดยอัตโนมัติ) · สแกนซ้ำ = ไม่ให้ซ้ำ
create or replace function admin_scan_submit(p_assignment uuid, p_code text, p_score numeric default null, p_status text default 'submitted')
returns json language plpgsql security definer set search_path = public as $$
declare a ch_assignments%rowtype; parts text[]; sid uuid; w bigint; nw bigint := floor(extract(epoch from now()) / 30);
        s students%rowtype; ex ch_submissions%rowtype;
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  if p_status not in ('submitted', 'late') then raise exception 'สถานะไม่ถูกต้อง'; end if;
  select * into a from ch_assignments where id = p_assignment;
  if a.id is null then raise exception 'ไม่พบงาน'; end if;
  if p_score is not null and (p_score < 0 or p_score > a.max_score) then raise exception 'คะแนนต้องอยู่ระหว่าง 0–%', a.max_score; end if;
  parts := string_to_array(coalesce(p_code, ''), '.');
  if coalesce(array_length(parts, 1), 0) <> 4 or parts[1] <> 'KB1' then raise exception 'QR ไม่ถูกต้อง'; end if;
  begin sid := parts[2]::uuid; w := parts[3]::bigint; exception when others then raise exception 'QR ไม่ถูกต้อง'; end;
  if parts[4] <> _qr_sig(sid, w) then raise exception 'QR ไม่ถูกต้อง'; end if;
  if w < nw - 3 or w > nw + 1 then raise exception 'QR หมดอายุ — ให้นักเรียนเปิดใหม่'; end if;
  select * into s from students where id = sid;
  if s.id is null then raise exception 'ไม่พบนักเรียน'; end if;
  if s.class_id <> a.class_id then raise exception '% ไม่ใช่นักเรียนห้องของงานนี้', s.name; end if;
  select * into ex from ch_submissions where assignment_id = a.id and student_id = sid;
  if ex.id is not null and ex.status in ('submitted', 'late') then
    return json_build_object('ok', true, 'dup', true, 'sid', s.id, 'no', s.no, 'name', s.name, 'status', ex.status, 'score', ex.score);
  end if;
  insert into ch_submissions (assignment_id, student_id, status, score, via) values (a.id, sid, p_status, p_score, 'teacher')
  on conflict (assignment_id, student_id) do update set status = excluded.status, score = excluded.score, submitted_at = now(), via = 'teacher';
  return json_build_object('ok', true, 'dup', false, 'sid', s.id, 'no', s.no, 'name', s.name, 'status', p_status, 'score', p_score, 'exp', a.exp_reward, 'coins', a.coin_reward);
end $$;
revoke execute on function admin_scan_submit(uuid, text, numeric, text) from public, anon;
grant execute on function admin_scan_submit(uuid, text, numeric, text) to authenticated;
-- =====================================================================
-- 53: สถิติท้ายเกม + สถิติที่ดีที่สุดของแต่ละคน (ควิซ จับคู่ สเปลล์ KB เคมีรัน ต่อสู้ ดวล) · รันซ้ำได้
--  ใช้เพื่อ "แสดงผล" เท่านั้น — ไม่ผูกกับรางวัล (รางวัลยังคำนวณจากระบบเดิมฝั่งเซิร์ฟเวอร์)
-- =====================================================================
create table if not exists game_bests (
  student_id uuid not null references students(id) on delete cascade,
  game text not null, metric text not null,
  best numeric not null, updated_at timestamptz not null default now(),
  primary key (student_id, game, metric)
);
alter table game_bests enable row level security;
drop policy if exists teacher_all on game_bests;
create policy teacher_all on game_bests for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on game_bests from anon;

-- ตั้งต้นจากประวัติการเล่นเดิม (game_plays): จำนวนครั้ง + คะแนน/ตอบถูก/EXP สูงสุด
insert into game_bests (student_id, game, metric, best)
  select student_id, game, 'plays', count(*) from game_plays group by student_id, game on conflict do nothing;
insert into game_bests (student_id, game, metric, best)
  select student_id, 'quiz', 'correct', max(correct) from game_plays where game = 'quiz' and correct is not null group by student_id on conflict do nothing;
insert into game_bests (student_id, game, metric, best)
  select student_id, 'quiz', 'exp', max(exp) from game_plays where game = 'quiz' and exp > 0 group by student_id on conflict do nothing;
insert into game_bests (student_id, game, metric, best)
  select student_id, game, 'score', max(score) from game_plays where game in ('match', 'spell', 'run') and score > 0 group by student_id, game on conflict do nothing;

-- บันทึกผลรอบนี้ → คืนผลรอบนี้ / สถิติดีที่สุด / ตัวชี้วัดที่ทำลายสถิติ
create or replace function game_record(p_token uuid, p_game text, p_stats jsonb) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); g jsonb; k text; dir text; v numeric; old numeric; n numeric;
  cur jsonb := '{}'::jsonb; bst jsonb := '{}'::jsonb; nb text[] := '{}';
  cfg jsonb := '{"quiz":{"correct":"max","exp":"max","secs":"min"},
    "match":{"score":"max","secs":"min","wrong":"min"},
    "spell":{"score":"max","secs":"min","combo":"max","wrong":"min","hints":"min"},
    "kb":{"cleared":"max","secs":"min","wins":"sum"},
    "run":{"score":"max","dist":"max","secs":"max","combo":"max","coins":"max"},
    "battle":{"correct":"max","hp_left":"max","turns":"min","wins":"sum"},
    "duel":{"hp_left":"max","rounds":"min","wins":"sum"}}';
begin
  g := cfg -> p_game;
  if g is null then raise exception 'ไม่รู้จักเกมนี้'; end if;
  if p_stats is null or jsonb_typeof(p_stats) <> 'object' then raise exception 'ข้อมูลสถิติไม่ถูกต้อง'; end if;
  insert into game_bests (student_id, game, metric, best) values (sid, p_game, 'plays', 1)
    on conflict (student_id, game, metric) do update set best = game_bests.best + 1, updated_at = now() returning best into n;
  for k, dir in select key, value #>> '{}' from jsonb_each(g) loop
    begin v := (p_stats ->> k)::numeric; exception when others then v := null; end;
    if v is null then continue; end if;
    v := least(greatest(v, 0), case when k = 'secs' then 86400 else 100000 end);
    if k = 'secs' and v = 0 then continue; end if;
    select best into old from game_bests where student_id = sid and game = p_game and metric = k;
    if dir = 'sum' then
      if v > 0 then
        insert into game_bests (student_id, game, metric, best) values (sid, p_game, k, v)
          on conflict (student_id, game, metric) do update set best = game_bests.best + excluded.best, updated_at = now() returning best into old;
      end if;
      cur := cur || jsonb_build_object(k, v); bst := bst || jsonb_build_object(k, coalesce(old, 0));
      continue;
    end if;
    cur := cur || jsonb_build_object(k, v);
    if old is null or (dir = 'max' and v > old) or (dir = 'min' and v < old) then
      insert into game_bests (student_id, game, metric, best) values (sid, p_game, k, v)
        on conflict (student_id, game, metric) do update set best = excluded.best, updated_at = now();
      nb := nb || k; old := v;
    end if;
    bst := bst || jsonb_build_object(k, old);
  end loop;
  return json_build_object('game', p_game, 'plays', n, 'first', n <= 1, 'cur', cur, 'best', bst, 'newbest', to_json(nb));
end $$;
revoke execute on function game_record(uuid, text, jsonb) from public;
grant execute on function game_record(uuid, text, jsonb) to anon, authenticated;

-- สถิติดีที่สุดทั้งหมดของฉัน (ใช้แสดงในหน้าหลักของแต่ละเกม): {game: {metric: best}}
create or replace function game_bests_all(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  return coalesce((select json_object_agg(x.game, x.m) from (select game, json_object_agg(metric, best) m from game_bests where student_id = sid group by game) x), '{}'::json);
end $$;
revoke execute on function game_bests_all(uuid) from public;
grant execute on function game_bests_all(uuid) to anon, authenticated;
-- =====================================================================
-- 54: การ์ดสะสม (📖 สมุดสะสม) · รันซ้ำได้
--  • ชุดการ์ดเคมี 3 ชุดตั้งต้น (ธาตุ 36 · นักเคมี 12 · อุปกรณ์แล็บ 12) พร้อมข้อเท็จจริง 1 บรรทัดต่อใบ — ครูเพิ่ม/แก้ได้ในแอดมิน
--  • ได้การ์ดจาก: จบเกม (สุ่ม · เพดานต่อวัน · โอกาสเพิ่มเมื่อทำสถิติใหม่) · กาชา · ครูแจก
--  • ซ้ำ → เศษธาตุ (ใช้อัปอุปกรณ์ในเฟสถัดไป) · pity รับประกันใบใหม่ · สะสมครบชุดรับรางวัล
-- =====================================================================
create table if not exists card_sets (
  id uuid primary key default gen_random_uuid(),
  code text not null unique, title text not null, emoji text not null default '📖', color text not null default '#7c4dff',
  reward_coins int not null default 100, reward_pulls int not null default 1,
  reward_decor uuid references decor_items(id) on delete set null,
  sort int not null default 0, active boolean not null default true
);
create table if not exists cards (
  id uuid primary key default gen_random_uuid(),
  set_id uuid not null references card_sets(id) on delete cascade,
  no int not null, name text not null, symbol text not null default '', emoji text not null default '🃏',
  rarity text not null check (rarity in ('N', 'R', 'SR', 'SSR')),
  fact text not null default '', image_url text, active boolean not null default true,
  unique (set_id, no)
);
create table if not exists student_cards (
  student_id uuid not null references students(id) on delete cascade,
  card_id uuid not null references cards(id) on delete cascade,
  qty int not null default 1, first_at timestamptz not null default now(),
  primary key (student_id, card_id)
);
create table if not exists student_set_claims (
  student_id uuid not null references students(id) on delete cascade,
  set_id uuid not null references card_sets(id) on delete cascade,
  claimed_at timestamptz not null default now(), primary key (student_id, set_id)
);
create table if not exists card_drops (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  card_id uuid references cards(id) on delete set null,
  source text not null check (source in ('game', 'gacha', 'gift')), game text,
  is_new boolean, shards int not null default 0,
  play_date date not null default today_th(), created_at timestamptz not null default now()
);
create index if not exists card_drops_day on card_drops(student_id, play_date, source);
alter table students add column if not exists shards int not null default 0;
alter table students add column if not exists card_pity int not null default 0;
alter table game_plays add column if not exists card_rolled boolean not null default false;
alter table game_plays add column if not exists best_hit boolean not null default false;
alter table battles add column if not exists card_rolled boolean not null default false;
alter table gifts add column if not exists card_id uuid references cards(id) on delete set null;
alter table gifts add column if not exists card_n int not null default 0;

do $$ declare t text; begin
  foreach t in array array['card_sets', 'cards', 'student_cards', 'student_set_claims', 'card_drops'] loop
    execute format('alter table %I enable row level security', t);
    execute format('drop policy if exists teacher_all on %I', t);
    execute format('create policy teacher_all on %I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on %I from anon', t);
  end loop;
end $$;

insert into app_settings (key, value) values
  ('card_drop_pct', '30'), ('card_best_bonus', '25'), ('card_daily_cap', '5'), ('card_pity', '4'), ('card_gacha_pct', '40'),
  ('card_w_n', '60'), ('card_w_r', '28'), ('card_w_sr', '10'), ('card_w_ssr', '2')
on conflict (key) do nothing;

-- ---------- ชุดการ์ดตั้งต้น ----------
insert into card_sets (code, title, emoji, color, reward_coins, reward_pulls, sort) values
  ('elements', 'ธาตุรอบตัว', '⚛️', '#4dabf7', 300, 3, 1),
  ('chemists', 'นักเคมีผู้ยิ่งใหญ่', '🧑‍🔬', '#ffb300', 200, 2, 2),
  ('lab', 'อุปกรณ์ห้องแล็บ', '🧪', '#51cf66', 150, 2, 3)
on conflict (code) do nothing;

insert into cards (set_id, no, name, symbol, emoji, rarity, fact)
select s.id, v.no, v.name, v.symbol, v.emoji, v.rarity, v.fact
from (values
 ('elements', 1, 'ไฮโดรเจน', 'H', '🎈', 'N', 'ธาตุที่เบาที่สุด และมีมากที่สุดในเอกภพ'),
 ('elements', 2, 'ฮีเลียม', 'He', '🎈', 'N', 'ไม่ติดไฟ จึงใช้บรรจุลูกโป่งให้ลอยได้อย่างปลอดภัย'),
 ('elements', 3, 'ลิเทียม', 'Li', '🔋', 'R', 'โลหะที่เบาที่สุด ใช้ทำแบตเตอรี่ในโทรศัพท์และรถยนต์ไฟฟ้า'),
 ('elements', 4, 'คาร์บอน', 'C', '✏️', 'N', 'เพชรและไส้ดินสอ (แกรไฟต์) ล้วนเป็นคาร์บอนเหมือนกัน'),
 ('elements', 5, 'ไนโตรเจน', 'N', '💨', 'N', 'เป็นก๊าซประมาณ 78% ของอากาศที่เราหายใจ'),
 ('elements', 6, 'ออกซิเจน', 'O', '🫁', 'N', 'จำเป็นต่อการหายใจและการเผาไหม้'),
 ('elements', 7, 'ฟลูออรีน', 'F', '🦷', 'R', 'สารประกอบของฟลูออรีนในยาสีฟันช่วยป้องกันฟันผุ'),
 ('elements', 8, 'นีออน', 'Ne', '💡', 'R', 'เรืองแสงสีส้มแดงในหลอดป้ายไฟนีออน'),
 ('elements', 9, 'โซเดียม', 'Na', '🧂', 'N', 'ทำปฏิกิริยารุนแรงกับน้ำ แต่รวมกับคลอรีนเป็นเกลือแกงที่เรากินได้'),
 ('elements', 10, 'แมกนีเซียม', 'Mg', '🎆', 'N', 'เผาไหม้ด้วยแสงสว่างจ้า จึงใช้ทำพลุและแฟลชรุ่นเก่า'),
 ('elements', 11, 'อะลูมิเนียม', 'Al', '🥫', 'N', 'เบาและไม่เป็นสนิม ใช้ทำกระป๋องเครื่องดื่มและฟอยล์'),
 ('elements', 12, 'ซิลิคอน', 'Si', '💻', 'R', 'วัสดุหลักของชิปคอมพิวเตอร์และเซลล์สุริยะ'),
 ('elements', 13, 'ฟอสฟอรัส', 'P', '🧬', 'R', 'เป็นส่วนประกอบของ DNA กระดูก และพลังงาน ATP ในร่างกาย'),
 ('elements', 14, 'กำมะถัน', 'S', '🌋', 'N', 'ใช้ผลิตกรดซัลฟิวริก ซึ่งเป็นสารเคมีที่ผลิตมากที่สุดในโลก'),
 ('elements', 15, 'คลอรีน', 'Cl', '🏊', 'N', 'ใช้ฆ่าเชื้อโรคในน้ำประปาและสระว่ายน้ำ'),
 ('elements', 16, 'อาร์กอน', 'Ar', '🔆', 'R', 'ก๊าซเฉื่อยที่มีมากเป็นอันดับสามในอากาศ ใช้บรรจุในหลอดไฟ'),
 ('elements', 17, 'โพแทสเซียม', 'K', '🍌', 'N', 'พบมากในกล้วย และจำเป็นต่อการทำงานของเส้นประสาทและกล้ามเนื้อ'),
 ('elements', 18, 'แคลเซียม', 'Ca', '🥛', 'N', 'สร้างกระดูกและฟัน พบมากในนมและเปลือกไข่'),
 ('elements', 19, 'ไทเทเนียม', 'Ti', '🦿', 'R', 'แข็งแรงแต่เบา และเข้ากับร่างกายได้ดี ใช้ทำรากฟันเทียม'),
 ('elements', 20, 'โครเมียม', 'Cr', '🚗', 'R', 'ให้ผิวเงาวับของชิ้นส่วนโครเมียมบนรถและก๊อกน้ำ'),
 ('elements', 21, 'เหล็ก', 'Fe', '🩸', 'N', 'อยู่ในฮีโมโกลบินของเลือด ช่วยลำเลียงออกซิเจนทั่วร่างกาย'),
 ('elements', 22, 'โคบอลต์', 'Co', '🔵', 'R', 'ให้สีน้ำเงินสดในเครื่องเคลือบและแก้ว'),
 ('elements', 23, 'นิกเกิล', 'Ni', '🪙', 'N', 'ใช้ทำเหรียญและผสมเป็นโลหะผสมสเตนเลส'),
 ('elements', 24, 'ทองแดง', 'Cu', '🔌', 'N', 'นำไฟฟ้าได้ดีมาก จึงใช้ทำสายไฟ'),
 ('elements', 25, 'สังกะสี', 'Zn', '🏠', 'R', 'ใช้เคลือบเหล็กกันสนิม เช่น หลังคาสังกะสี'),
 ('elements', 26, 'โบรมีน', 'Br', '🧪', 'R', 'อโลหะชนิดเดียวที่เป็นของเหลวที่อุณหภูมิห้อง'),
 ('elements', 27, 'เงิน', 'Ag', '🥈', 'R', 'นำไฟฟ้าและความร้อนได้ดีที่สุดในบรรดาโลหะทั้งหมด'),
 ('elements', 28, 'ดีบุก', 'Sn', '🥫', 'N', 'ใช้เคลือบกระป๋องอาหารกันสนิม จึงเรียกว่า “กระป๋องดีบุก”'),
 ('elements', 29, 'ไอโอดีน', 'I', '🧂', 'R', 'จำเป็นต่อต่อมไทรอยด์ พบในเกลือเสริมไอโอดีน'),
 ('elements', 30, 'ทังสเตน', 'W', '💡', 'SR', 'โลหะที่มีจุดหลอมเหลวสูงที่สุด ใช้ทำไส้หลอดไฟ'),
 ('elements', 31, 'แพลทินัม', 'Pt', '💍', 'SR', 'ใช้เป็นตัวเร่งปฏิกิริยาในท่อไอเสียรถยนต์ และทำเครื่องประดับ'),
 ('elements', 32, 'ทองคำ', 'Au', '🥇', 'SR', 'ไม่ทำปฏิกิริยากับอากาศ จึงไม่หมองและเงางามมานับพันปี'),
 ('elements', 33, 'ปรอท', 'Hg', '🌡️', 'SR', 'โลหะชนิดเดียวที่เป็นของเหลวที่อุณหภูมิห้อง (แต่เป็นพิษ ห้ามสัมผัส)'),
 ('elements', 34, 'ตะกั่ว', 'Pb', '⚖️', 'R', 'หนักและอ่อน เคยใช้ทำท่อน้ำ ปัจจุบันจำกัดการใช้เพราะเป็นพิษ'),
 ('elements', 35, 'เรเดียม', 'Ra', '☢️', 'SSR', 'มารี คูรี ค้นพบ สารประกอบของมันเรืองแสงจาง ๆ ในที่มืด'),
 ('elements', 36, 'ยูเรเนียม', 'U', '⚡', 'SSR', 'เชื้อเพลิงของโรงไฟฟ้านิวเคลียร์'),
 ('chemists', 1, 'โรเบิร์ต บอยล์', 'Boyle', '🧑‍🔬', 'N', 'ค้นพบว่าก๊าซความดันสูงขึ้นปริมาตรจะลดลง (กฎของบอยล์)'),
 ('chemists', 2, 'หลุยส์ ปาสเตอร์', 'Pasteur', '🧑‍🔬', 'N', 'คิดวิธีพาสเจอไรซ์ ฆ่าเชื้อในนมและเครื่องดื่มด้วยความร้อน'),
 ('chemists', 3, 'อาเมเดโอ อาโวกาโดร', 'Avogadro', '🧑‍🔬', 'N', 'เลขอาโวกาโดร (6.02×10²³) ตั้งชื่อเป็นเกียรติแก่เขา'),
 ('chemists', 4, 'จอห์น ดอลตัน', 'Dalton', '⚛️', 'N', 'เสนอทฤษฎีอะตอมว่าสสารประกอบด้วยอะตอมเล็ก ๆ'),
 ('chemists', 5, 'อ็องตวน ลาวัวซีเย', 'Lavoisier', '⚖️', 'R', 'บิดาแห่งเคมีสมัยใหม่ ชี้ว่ามวลสารก่อนและหลังทำปฏิกิริยาเท่ากัน'),
 ('chemists', 6, 'เออร์เนสต์ รัทเทอร์ฟอร์ด', 'Rutherford', '☄️', 'R', 'ค้นพบนิวเคลียสของอะตอมจากการยิงอนุภาคแอลฟาใส่แผ่นทองคำ'),
 ('chemists', 7, 'นีลส์ โบร์', 'Bohr', '🌀', 'R', 'เสนอแบบจำลองอะตอมที่อิเล็กตรอนวิ่งตามระดับพลังงาน'),
 ('chemists', 8, 'โดโรธี ฮอดจ์กิน', 'Hodgkin', '🔬', 'R', 'ใช้รังสีเอกซ์หาโครงสร้างเพนิซิลลินและอินซูลิน ได้รางวัลโนเบลสาขาเคมี'),
 ('chemists', 9, 'ดิมิทรี เมนเดเลเยฟ', 'Mendeleev', '📊', 'SR', 'จัดตารางธาตุและเว้นช่องว่างไว้ทำนายธาตุที่ยังไม่ถูกค้นพบ'),
 ('chemists', 10, 'อัลเฟรด โนเบล', 'Nobel', '🏅', 'SR', 'นักเคมีผู้ประดิษฐ์ไดนาไมต์ และตั้งรางวัลโนเบลจากพินัยกรรมของเขา'),
 ('chemists', 11, 'ไลนัส พอลิง', 'Pauling', '🧬', 'SR', 'ได้รางวัลโนเบลสองครั้ง คือสาขาเคมีและสาขาสันติภาพ'),
 ('chemists', 12, 'มารี คูรี', 'Curie', '☢️', 'SSR', 'ได้รางวัลโนเบลสองสาขา (ฟิสิกส์และเคมี) ค้นพบธาตุพอโลเนียมและเรเดียม'),
 ('lab', 1, 'บีกเกอร์', 'Beaker', '🥛', 'N', 'ใช้ใส่และผสมสาร ขีดบอกปริมาตรข้างแก้วเป็นเพียงค่าโดยประมาณ'),
 ('lab', 2, 'ขวดรูปกรวย', 'Flask', '⚗️', 'N', 'ทรงกรวยช่วยให้เขย่าสารได้โดยไม่กระฉอกออก'),
 ('lab', 3, 'กระบอกตวง', 'Cylinder', '📏', 'N', 'วัดปริมาตรของเหลวได้แม่นกว่าบีกเกอร์ ให้อ่านค่าที่ระดับสายตา'),
 ('lab', 4, 'หลอดทดลอง', 'Tube', '🧪', 'N', 'ใช้ทดสอบปฏิกิริยาของสารปริมาณน้อย'),
 ('lab', 5, 'ตะเกียงแอลกอฮอล์', 'Lamp', '🔥', 'N', 'ให้ความร้อนในห้องปฏิบัติการ ห้ามเติมแอลกอฮอล์ขณะไฟยังติดอยู่'),
 ('lab', 6, 'แว่นตานิรภัย', 'Goggles', '🥽', 'N', 'ต้องสวมทุกครั้งที่ทดลอง ป้องกันสารกระเด็นเข้าตา'),
 ('lab', 7, 'ปิเปตต์', 'Pipette', '💧', 'R', 'ดูดและถ่ายของเหลวในปริมาตรที่แม่นยำ'),
 ('lab', 8, 'บิวเรตต์', 'Burette', '🧴', 'R', 'ใช้หยดสารละลายทีละน้อยเพื่อไทเทรต'),
 ('lab', 9, 'เครื่องชั่งละเอียด', 'Balance', '⚖️', 'R', 'ชั่งมวลสารได้ละเอียดหลายตำแหน่งทศนิยม'),
 ('lab', 10, 'ตู้ดูดควัน', 'Hood', '🌬️', 'R', 'ดูดไอสารพิษออกจากโต๊ะทดลองเพื่อความปลอดภัย'),
 ('lab', 11, 'เครื่องเหวี่ยงแยก', 'Centrifuge', '🌀', 'SR', 'ใช้แรงเหวี่ยงแยกตะกอนออกจากของเหลว'),
 ('lab', 12, 'เครื่อง NMR', 'NMR', '🧲', 'SSR', 'ตรวจโครงสร้างโมเลกุลด้วยสนามแม่เหล็กแรงสูง หลักการเดียวกับเครื่อง MRI')
) as v(code, no, name, symbol, emoji, rarity, fact)
join card_sets s on s.code = v.code
on conflict (set_id, no) do nothing;

-- ---------- ฟังก์ชันภายใน ----------
create or replace function _card_shards(p_rarity text) returns int language sql immutable as
$$ select case p_rarity when 'SSR' then 30 when 'SR' then 10 when 'R' then 3 else 1 end $$;

-- เลือกการ์ด: สุ่มระดับตามน้ำหนัก แล้วสุ่มใบในระดับนั้น (p_new = เฉพาะใบที่ยังไม่มี)
create or replace function _card_pick(p_sid uuid, p_new boolean) returns uuid
language plpgsql security definer set search_path = public as $$
declare rs text[] := array['N', 'R', 'SR', 'SSR'];
  ws numeric[] := array[_setting_int('card_w_n', 60), _setting_int('card_w_r', 28), _setting_int('card_w_sr', 10), _setting_int('card_w_ssr', 2)];
  av numeric[] := array[0, 0, 0, 0]; i int; tot numeric := 0; r numeric; acc numeric := 0; pick text; cid uuid;
begin
  for i in 1..4 loop
    if ws[i] > 0 and exists (select 1 from cards c join card_sets s on s.id = c.set_id where c.active and s.active and c.rarity = rs[i]
         and (not p_new or not exists (select 1 from student_cards sc where sc.student_id = p_sid and sc.card_id = c.id))) then
      av[i] := ws[i]; tot := tot + ws[i];
    end if;
  end loop;
  if tot <= 0 then return null; end if;
  r := random() * tot;
  for i in 1..4 loop
    if av[i] > 0 then pick := rs[i]; acc := acc + av[i]; if r < acc then exit; end if; end if;
  end loop;
  select c.id into cid from cards c join card_sets s on s.id = c.set_id where c.active and s.active and c.rarity = pick
     and (not p_new or not exists (select 1 from student_cards sc where sc.student_id = p_sid and sc.card_id = c.id)) order by random() limit 1;
  return cid;
end $$;

-- มอบการ์ด 1 ใบ: ซ้ำ → เศษธาตุ · ครบชุด → รางวัล (ครั้งเดียวต่อชุด)
create or replace function _card_grant(p_sid uuid, p_card uuid, p_source text, p_game text default null) returns jsonb
language plpgsql security definer set search_path = public as $$
declare c cards%rowtype; st card_sets%rowtype; isnew boolean; sh int := 0; done jsonb := null; tot int; own int;
begin
  select * into c from cards where id = p_card;
  if c.id is null then raise exception 'ไม่พบการ์ด'; end if;
  select * into st from card_sets where id = c.set_id;
  insert into student_cards (student_id, card_id) values (p_sid, p_card)
    on conflict (student_id, card_id) do update set qty = student_cards.qty + 1 returning (xmax = 0) into isnew;
  if isnew then update students set card_pity = 0 where id = p_sid;
  else sh := _card_shards(c.rarity); update students set shards = shards + sh, card_pity = card_pity + 1 where id = p_sid; end if;
  insert into card_drops (student_id, card_id, source, game, is_new, shards) values (p_sid, p_card, p_source, p_game, isnew, sh);
  if isnew then
    select count(*) into tot from cards where set_id = c.set_id and active;
    select count(*) into own from student_cards sc join cards x on x.id = sc.card_id where sc.student_id = p_sid and x.set_id = c.set_id and x.active;
    if tot > 0 and own >= tot and not exists (select 1 from student_set_claims where student_id = p_sid and set_id = c.set_id) then
      insert into student_set_claims (student_id, set_id) values (p_sid, c.set_id);
      if st.reward_coins > 0 then perform award(p_sid, 0, st.reward_coins, '📖 สะสมการ์ดครบชุด ' || st.title, 'cardset:' || c.set_id); end if;
      if st.reward_pulls > 0 then update students set free_pulls = free_pulls + st.reward_pulls where id = p_sid; end if;
      if st.reward_decor is not null then insert into student_decor (student_id, item_id, source) values (p_sid, st.reward_decor, 'teacher') on conflict do nothing; end if;
      done := jsonb_build_object('title', st.title, 'coins', st.reward_coins, 'pulls', st.reward_pulls);
    end if;
  end if;
  return jsonb_build_object('id', c.id, 'name', c.name, 'symbol', c.symbol, 'emoji', c.emoji, 'rarity', c.rarity, 'fact', c.fact,
                            'image', c.image_url, 'set', st.title, 'set_emoji', st.emoji, 'is_new', isnew, 'shards', sh, 'set_done', done);
end $$;

-- สุ่มการ์ด 1 ใบให้นักเรียน (pity: ซ้ำติดกันครบเกณฑ์ → ใบถัดไปเป็นใบใหม่แน่นอน)
create or replace function _card_draw(p_sid uuid, p_source text, p_game text) returns jsonb
language plpgsql security definer set search_path = public as $$
declare pity int := greatest(1, _setting_int('card_pity', 4)); pt int; cid uuid; force boolean;
begin
  select card_pity into pt from students where id = p_sid;
  force := coalesce(pt, 0) >= pity - 1 or not exists (select 1 from student_cards where student_id = p_sid);
  cid := _card_pick(p_sid, force);
  if cid is null and force then cid := _card_pick(p_sid, false); end if;
  if cid is null then return null; end if;
  return _card_grant(p_sid, cid, p_source, p_game);
end $$;
revoke execute on function _card_shards(text), _card_pick(uuid, boolean), _card_grant(uuid, uuid, text, text), _card_draw(uuid, text, text) from public, anon, authenticated;

-- ---------- นักเรียน: สุ่มการ์ดหลังจบเกม (ต้องมีรอบเล่นจริงที่ยังไม่เคยสุ่ม) ----------
create or replace function card_roll(p_token uuid, p_game text) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); hit boolean := false; got boolean := false; used int; cap int := _setting_int('card_daily_cap', 5);
  pct int; card jsonb;
begin
  if p_game in ('quiz', 'match', 'spell', 'kb', 'run') then
    update game_plays set card_rolled = true where id = (select id from game_plays where student_id = sid and game = p_game and play_date = today_th() and not card_rolled
        order by best_hit desc, created_at limit 1 for update skip locked) returning best_hit into hit;
    got := found;
  elsif p_game = 'battle' then
    update battles set card_rolled = true where id = (select id from battles where student_id = sid and status = 'won' and play_date = today_th() and not card_rolled
        order by created_at limit 1 for update skip locked);
    got := found;
  else raise exception 'เกมนี้ไม่มีการ์ดดรอป'; end if;
  if not got then return json_build_object('drop', false, 'reason', 'no_play'); end if;
  select count(*) into used from card_drops where student_id = sid and play_date = today_th() and source = 'game';
  if used >= cap then return json_build_object('drop', false, 'reason', 'cap', 'cap', cap, 'left', 0); end if;
  pct := least(90, _setting_int('card_drop_pct', 30) + case when hit then _setting_int('card_best_bonus', 25) else 0 end);
  if not exists (select 1 from student_cards where student_id = sid) then pct := 100; end if;   -- ใบแรกได้แน่นอน
  if random() * 100 >= pct then return json_build_object('drop', false, 'reason', 'miss', 'cap', cap, 'left', cap - used); end if;
  card := _card_draw(sid, 'game', p_game);
  if card is null then return json_build_object('drop', false, 'reason', 'empty'); end if;
  return json_build_object('drop', true, 'card', card, 'cap', cap, 'left', cap - used - 1, 'bonus', hit);
end $$;
revoke execute on function card_roll(uuid, text) from public;
grant execute on function card_roll(uuid, text) to anon, authenticated;

-- ---------- นักเรียน: สมุดสะสม ----------
create or replace function card_album(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); res json; s students%rowtype;
begin
  select * into s from students where id = sid;
  select json_build_object('shards', s.shards, 'pity', s.card_pity, 'pity_max', _setting_int('card_pity', 4),
    'cap', _setting_int('card_daily_cap', 5), 'used', (select count(*) from card_drops where student_id = sid and play_date = today_th() and source = 'game'),
    'sets', coalesce((select json_agg(json_build_object('id', cs.id, 'title', cs.title, 'emoji', cs.emoji, 'color', cs.color,
        'reward', json_build_object('coins', cs.reward_coins, 'pulls', cs.reward_pulls, 'decor', (select d.name from decor_items d where d.id = cs.reward_decor)),
        'claimed', exists (select 1 from student_set_claims x where x.student_id = sid and x.set_id = cs.id),
        'cards', (select coalesce(json_agg(json_build_object('id', c.id, 'no', c.no, 'rarity', c.rarity, 'symbol', c.symbol, 'emoji', c.emoji,
              'own', sc.card_id is not null, 'qty', coalesce(sc.qty, 0), 'name', case when sc.card_id is not null then c.name end,
              'fact', case when sc.card_id is not null then c.fact end, 'image', case when sc.card_id is not null then c.image_url end) order by c.no), '[]'::json)
            from cards c left join student_cards sc on sc.card_id = c.id and sc.student_id = sid where c.set_id = cs.id and c.active))
        order by cs.sort, cs.title) from card_sets cs where cs.active), '[]'::json)) into res;
  return res;
end $$;
revoke execute on function card_album(uuid) from public;
grant execute on function card_album(uuid) to anon, authenticated;

-- ---------- game_record: ทำเครื่องหมาย "ทำสถิติใหม่" ที่รอบเล่นล่าสุด (โอกาสการ์ดเพิ่ม) ----------
create or replace function game_record(p_token uuid, p_game text, p_stats jsonb) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); g jsonb; k text; dir text; v numeric; old numeric; n numeric;
  cur jsonb := '{}'::jsonb; bst jsonb := '{}'::jsonb; nb text[] := '{}';
  cfg jsonb := '{"quiz":{"correct":"max","exp":"max","secs":"min"},
    "match":{"score":"max","secs":"min","wrong":"min"},
    "spell":{"score":"max","secs":"min","combo":"max","wrong":"min","hints":"min"},
    "kb":{"cleared":"max","secs":"min","wins":"sum"},
    "run":{"score":"max","dist":"max","secs":"max","combo":"max","coins":"max"},
    "battle":{"correct":"max","hp_left":"max","turns":"min","wins":"sum"},
    "duel":{"hp_left":"max","rounds":"min","wins":"sum"}}';
begin
  g := cfg -> p_game;
  if g is null then raise exception 'ไม่รู้จักเกมนี้'; end if;
  if p_stats is null or jsonb_typeof(p_stats) <> 'object' then raise exception 'ข้อมูลสถิติไม่ถูกต้อง'; end if;
  insert into game_bests (student_id, game, metric, best) values (sid, p_game, 'plays', 1)
    on conflict (student_id, game, metric) do update set best = game_bests.best + 1, updated_at = now() returning best into n;
  for k, dir in select key, value #>> '{}' from jsonb_each(g) loop
    begin v := (p_stats ->> k)::numeric; exception when others then v := null; end;
    if v is null then continue; end if;
    v := least(greatest(v, 0), case when k = 'secs' then 86400 else 100000 end);
    if k = 'secs' and v = 0 then continue; end if;
    select best into old from game_bests where student_id = sid and game = p_game and metric = k;
    if dir = 'sum' then
      if v > 0 then
        insert into game_bests (student_id, game, metric, best) values (sid, p_game, k, v)
          on conflict (student_id, game, metric) do update set best = game_bests.best + excluded.best, updated_at = now() returning best into old;
      end if;
      cur := cur || jsonb_build_object(k, v); bst := bst || jsonb_build_object(k, coalesce(old, 0));
      continue;
    end if;
    cur := cur || jsonb_build_object(k, v);
    if old is null or (dir = 'max' and v > old) or (dir = 'min' and v < old) then
      insert into game_bests (student_id, game, metric, best) values (sid, p_game, k, v)
        on conflict (student_id, game, metric) do update set best = excluded.best, updated_at = now();
      nb := nb || k; old := v;
    end if;
    bst := bst || jsonb_build_object(k, old);
  end loop;
  if cardinality(nb) > 0 and n > 1 and p_game in ('quiz', 'match', 'spell', 'kb', 'run') then
    update game_plays set best_hit = true where id = (select id from game_plays where student_id = sid and game = p_game and play_date = today_th()
       and not card_rolled order by created_at desc limit 1);
  end if;
  return json_build_object('game', p_game, 'plays', n, 'first', n <= 1, 'cur', cur, 'best', bst, 'newbest', to_json(nb));
end $$;
revoke execute on function game_record(uuid, text, jsonb) from public;
grant execute on function game_record(uuid, text, jsonb) to anon, authenticated;

-- ---------- กาชา: ห่อฟังก์ชันเดิม แล้วแถมการ์ดสะสม (สุ่ม 1 ครั้ง = มีโอกาส · สุ่ม 10 ครั้ง = ได้ 1 ใบแน่นอน + โอกาสอีก 1) ----------
do $$ begin
  if not exists (select 1 from pg_proc where proname = '_gacha_pull' and pronamespace = 'public'::regnamespace) then
    alter function gacha_pull(uuid, int) rename to _gacha_pull; end if;
end $$;
revoke execute on function _gacha_pull(uuid, int) from public, anon, authenticated;
create or replace function gacha_pull(p_token uuid, p_n int default 1) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); r json; cards jsonb := '[]'::jsonb; k int; n int; pct int := _setting_int('card_gacha_pct', 40); c jsonb;
begin
  r := _gacha_pull(p_token, p_n);
  n := case when p_n = 10 then 1 else 0 end + case when random() * 100 < pct then 1 else 0 end;
  for k in 1..n loop
    c := _card_draw(sid, 'gacha', 'gacha');
    if c is not null then cards := cards || c; end if;
  end loop;
  return (r::jsonb || jsonb_build_object('cards', cards))::json;
end $$;
revoke execute on function gacha_pull(uuid, int) from public;
grant execute on function gacha_pull(uuid, int) to anon, authenticated;

-- ---------- ของขวัญ: เพิ่ม "การ์ดสะสม" ----------
drop function if exists admin_gift(uuid[], int, int, int, uuid, uuid, text);
create or replace function admin_gift(p_students uuid[], p_exp int default 0, p_coins int default 0, p_pulls int default 0,
                                      p_decor uuid default null, p_priv uuid default null, p_message text default '',
                                      p_card uuid default null, p_card_n int default 1)
returns json language plpgsql security definer set search_path = public as $$
declare sid uuid; b uuid := gen_random_uuid(); n int := 0; dup int := 0; ids uuid[]; msg text := left(coalesce(btrim(p_message), ''), 200);
        cn int := case when p_card is null then 0 else greatest(1, coalesce(p_card_n, 1)) end; i int;
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  select array_agg(distinct x) into ids from unnest(coalesce(p_students, '{}')) x;
  if ids is null or cardinality(ids) = 0 then raise exception 'ยังไม่ได้เลือกนักเรียน'; end if;
  if cardinality(ids) > 600 then raise exception 'เลือกนักเรียนได้ครั้งละไม่เกิน 600 คน'; end if;
  if coalesce(p_exp, 0) < 0 or coalesce(p_coins, 0) < 0 or coalesce(p_pulls, 0) < 0 or coalesce(p_card_n, 1) < 0 then raise exception 'จำนวนต้องไม่ติดลบ (ถ้าจะหักให้ใช้ ± EXP/เหรียญ ในแท็บนักเรียน)'; end if;
  if p_exp > 10000 or p_coins > 10000 or p_pulls > 50 or cn > 10 then raise exception 'จำนวนมากเกินไป (EXP/เหรียญ ≤ 10000 · ตั๋ว ≤ 50 · การ์ด ≤ 10 ใบ)'; end if;
  if coalesce(p_exp, 0) = 0 and coalesce(p_coins, 0) = 0 and coalesce(p_pulls, 0) = 0 and p_decor is null and p_priv is null and p_card is null then raise exception 'ยังไม่ได้เลือกของขวัญ'; end if;
  if p_decor is not null and not exists (select 1 from decor_items where id = p_decor) then raise exception 'ไม่พบไอเทมตกแต่ง'; end if;
  if p_priv is not null and not exists (select 1 from privileges where id = p_priv) then raise exception 'ไม่พบสิทธิพิเศษ'; end if;
  if p_card is not null and not exists (select 1 from cards where id = p_card) then raise exception 'ไม่พบการ์ด'; end if;
  for sid in select id from students where id = any(ids) loop
    if coalesce(p_exp, 0) > 0 or coalesce(p_coins, 0) > 0 then
      perform award(sid, coalesce(p_exp, 0), coalesce(p_coins, 0), '🎁 ของขวัญจากครู' || case when msg <> '' then ': ' || msg else '' end, 'gift:' || b);
    end if;
    if coalesce(p_pulls, 0) > 0 then update students set free_pulls = free_pulls + p_pulls where id = sid; end if;
    if p_decor is not null then
      insert into student_decor (student_id, item_id, source) values (sid, p_decor, 'teacher') on conflict do nothing;
      if not found then dup := dup + 1; end if;
    end if;
    if p_priv is not null then insert into redemptions (student_id, privilege_id, source) values (sid, p_priv, 'teacher'); end if;
    for i in 1..cn loop perform _card_grant(sid, p_card, 'gift', null); end loop;
    insert into gifts (batch, student_id, message, exp, coins, pulls, decor_id, privilege_id, card_id, card_n)
    values (b, sid, msg, coalesce(p_exp, 0), coalesce(p_coins, 0), coalesce(p_pulls, 0), p_decor, p_priv, p_card, cn);
    n := n + 1;
  end loop;
  perform check_achievements(s.id) from students s where s.id = any(ids);
  return json_build_object('given', n, 'decor_already_owned', dup, 'batch', b);
end $$;
revoke execute on function admin_gift(uuid[], int, int, int, uuid, uuid, text, uuid, int) from public, anon;
grant execute on function admin_gift(uuid[], int, int, int, uuid, uuid, text, uuid, int) to authenticated;

create or replace function gift_inbox(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  return coalesce((select json_agg(json_build_object('id', g.id, 'message', g.message, 'exp', g.exp, 'coins', g.coins, 'pulls', g.pulls,
            'decor', d.name, 'decor_emoji', d.emoji, 'privilege', p.name, 'card', c.name, 'card_emoji', c.emoji, 'card_rarity', c.rarity, 'card_n', g.card_n,
            'at', g.created_at) order by g.created_at)
          from gifts g left join decor_items d on d.id = g.decor_id left join privileges p on p.id = g.privilege_id left join cards c on c.id = g.card_id
         where g.student_id = sid and not g.seen), '[]'::json);
end $$;
revoke execute on function gift_inbox(uuid) from public;
grant execute on function gift_inbox(uuid) to anon, authenticated;
-- 55: ภาพการ์ด SSR (แนว chemistry fantasy) + ประกาศข่าวสมุดการ์ดสะสม
-- ไฟล์ภาพวางที่ assets/cards/ (ถ้าไฟล์ยังไม่มี หน้าการ์ดจะกลับไปใช้หน้าการ์ดวาดด้วย CSS อัตโนมัติ)
update cards c set image_url = 'assets/cards/' || v.f
from (values ('elements', 35, 'ssr-radium.jpg'), ('elements', 36, 'ssr-uranium.jpg'),
             ('chemists', 12, 'ssr-curie.jpg'), ('lab', 12, 'ssr-nmr.jpg')) v(code, no, f)
join card_sets s on s.code = v.code
where c.set_id = s.id and c.no = v.no and c.image_url is null;

insert into news_posts (kind, title, summary, body, image, sort)
select 'event', 'สมุดการ์ดสะสมเปิดแล้ว! 📖🃏', 'เล่นเกมจบ ลุ้นได้การ์ดธาตุ นักเคมี อุปกรณ์แล็บ — สะสมครบชุดรับรางวัล',
 E'📖 สมุดการ์ดสะสม — เปิดแล้ว!\n\nการ์ด 60 ใบใน 3 ชุด: ⚛️ ธาตุรอบตัว · 👩‍🔬 นักเคมีดัง · 🧪 อุปกรณ์แล็บ\nทุกใบมีข้อเท็จจริงเคมี 1 บรรทัด เล่นไปก็ได้ความรู้ไปด้วย\nความหายาก N · R · SR · SSR (ใบ SSR มีภาพวาดแนวแฟนตาซีเคมี)\n\n🎁 ได้การ์ดจากไหน\n• จบเกม (ควิซ จับคู่ สเปลล์ ประลองครูบุ๊ค เคมีรัน ล่ามอนสเตอร์) — ทำสถิติใหม่โอกาสเพิ่ม · วันละไม่เกิน 5 ใบ\n• สุ่มกาชา — หมุน 10 ครั้งได้การ์ด 1 ใบแน่นอน\n• ครูแจกเป็นของขวัญ\n\n✨ ได้ใบซ้ำไม่เสียเปล่า\nแปลงเป็น "เศษธาตุ" เก็บไว้อัปเลเวลอุปกรณ์ในอัปเดตถัดไป\nได้ใบใหม่ไม่ออกสักที? ซ้ำติดกัน 3 ครั้ง ใบต่อไปได้ใบใหม่แน่นอน!\n\n🏆 สะสมครบชุดรับ เหรียญ + ตั๋วกาชา\nเปิดดูที่แท็บ 📖 สมุดสะสม ได้เลย',
 'assets/news/items.jpg', 40
where not exists (select 1 from news_posts where title = 'สมุดการ์ดสะสมเปิดแล้ว! 📖🃏');
-- 56: ผูกภาพการ์ด SR (ภาพวางที่ assets/cards/ — ถ้าไฟล์ยังไม่มี จะใช้หน้าการ์ด CSS แทนอัตโนมัติ)
update cards c set image_url = 'assets/cards/' || v.f
from (values ('elements', 30, 'sr-tungsten.jpg'), ('elements', 31, 'sr-platinum.jpg'),
             ('elements', 32, 'sr-gold.jpg'), ('elements', 33, 'sr-mercury.jpg'),
             ('chemists', 9, 'sr-mendeleev.jpg'), ('chemists', 10, 'sr-nobel.jpg'),
             ('chemists', 11, 'sr-pauling.jpg'), ('lab', 11, 'sr-centrifuge.jpg')) v(code, no, f)
join card_sets s on s.code = v.code
where c.set_id = s.id and c.no = v.no and c.image_url is null;
-- 57: ผูกภาพการ์ด R (22) และ N (26) — ไฟล์ภาพวางที่ assets/cards/ (ไฟล์ไหนยังไม่มี จะใช้หน้าการ์ด CSS แทนอัตโนมัติ)
update cards c set image_url = 'assets/cards/' || v.f
from (values
 ('elements', 3, 'r-elements-03-lithium.jpg'),
 ('elements', 7, 'r-elements-07-fluorine.jpg'),
 ('elements', 8, 'r-elements-08-neon.jpg'),
 ('elements', 12, 'r-elements-12-silicon.jpg'),
 ('elements', 13, 'r-elements-13-phosphorus.jpg'),
 ('elements', 16, 'r-elements-16-argon.jpg'),
 ('elements', 19, 'r-elements-19-titanium.jpg'),
 ('elements', 20, 'r-elements-20-chromium.jpg'),
 ('elements', 22, 'r-elements-22-cobalt.jpg'),
 ('elements', 25, 'r-elements-25-zinc.jpg'),
 ('elements', 26, 'r-elements-26-bromine.jpg'),
 ('elements', 27, 'r-elements-27-silver.jpg'),
 ('elements', 29, 'r-elements-29-iodine.jpg'),
 ('elements', 34, 'r-elements-34-lead.jpg'),
 ('chemists', 5, 'r-chemists-05-lavoisier.jpg'),
 ('chemists', 6, 'r-chemists-06-rutherford.jpg'),
 ('chemists', 7, 'r-chemists-07-bohr.jpg'),
 ('chemists', 8, 'r-chemists-08-hodgkin.jpg'),
 ('lab', 7, 'r-lab-07-pipette.jpg'),
 ('lab', 8, 'r-lab-08-burette.jpg'),
 ('lab', 9, 'r-lab-09-balance.jpg'),
 ('lab', 10, 'r-lab-10-hood.jpg'),
 ('elements', 1, 'n-elements-01-hydrogen.jpg'),
 ('elements', 2, 'n-elements-02-helium.jpg'),
 ('elements', 4, 'n-elements-04-carbon.jpg'),
 ('elements', 5, 'n-elements-05-nitrogen.jpg'),
 ('elements', 6, 'n-elements-06-oxygen.jpg'),
 ('elements', 9, 'n-elements-09-sodium.jpg'),
 ('elements', 10, 'n-elements-10-magnesium.jpg'),
 ('elements', 11, 'n-elements-11-aluminium.jpg'),
 ('elements', 14, 'n-elements-14-sulfur.jpg'),
 ('elements', 15, 'n-elements-15-chlorine.jpg'),
 ('elements', 17, 'n-elements-17-potassium.jpg'),
 ('elements', 18, 'n-elements-18-calcium.jpg'),
 ('elements', 21, 'n-elements-21-iron.jpg'),
 ('elements', 23, 'n-elements-23-nickel.jpg'),
 ('elements', 24, 'n-elements-24-copper.jpg'),
 ('elements', 28, 'n-elements-28-tin.jpg'),
 ('chemists', 1, 'n-chemists-01-boyle.jpg'),
 ('chemists', 2, 'n-chemists-02-pasteur.jpg'),
 ('chemists', 3, 'n-chemists-03-avogadro.jpg'),
 ('chemists', 4, 'n-chemists-04-dalton.jpg'),
 ('lab', 1, 'n-lab-01-beaker.jpg'),
 ('lab', 2, 'n-lab-02-flask.jpg'),
 ('lab', 3, 'n-lab-03-cylinder.jpg'),
 ('lab', 4, 'n-lab-04-tube.jpg'),
 ('lab', 5, 'n-lab-05-lamp.jpg'),
 ('lab', 6, 'n-lab-06-goggles.jpg')
) v(code, no, f)
join card_sets s on s.code = v.code
where c.set_id = s.id and c.no = v.no and c.image_url is null;
-- 58: การ์ดสะสมดรอปจากมอนสเตอร์เท่านั้น + โควต้าต่อวัน + รูปหลังการ์ด (v1.89)
-- • card_roll รับเฉพาะ 'battle' (ต้องมีรอบชนะมอนสเตอร์จริงที่เซิร์ฟเวอร์บันทึก) เกมอื่นไม่ดรอป
-- • โควต้าต่อวัน = card_daily_cap (ค่าเริ่ม 3 ถ้ายังเป็นค่าเดิม 5) · ใบแรกได้แน่นอน · pity ยังทำงาน
-- • กาชาไม่แถมการ์ดอีก · ครูแจกการ์ดให้นักเรียนยังทำได้ตามเดิม
create or replace function card_roll(p_token uuid, p_game text) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); used int; cap int := _setting_int('card_daily_cap', 3); pct int; card jsonb;
begin
  if p_game in ('quiz', 'match', 'spell', 'kb', 'run') then
    return json_build_object('drop', false, 'reason', 'monster_only');
  elsif p_game <> 'battle' then raise exception 'เกมนี้ไม่มีการ์ดดรอป'; end if;
  update battles set card_rolled = true where id = (select id from battles where student_id = sid and status = 'won' and play_date = today_th() and not card_rolled
      order by created_at limit 1 for update skip locked);
  if not found then return json_build_object('drop', false, 'reason', 'no_play'); end if;
  select count(*) into used from card_drops where student_id = sid and play_date = today_th() and source = 'game';
  if used >= cap then return json_build_object('drop', false, 'reason', 'cap', 'cap', cap, 'left', 0); end if;
  pct := least(90, _setting_int('card_drop_pct', 50));
  if not exists (select 1 from student_cards where student_id = sid) then pct := 100; end if;
  if random() * 100 >= pct then return json_build_object('drop', false, 'reason', 'miss', 'cap', cap, 'left', cap - used); end if;
  card := _card_draw(sid, 'game', 'battle');
  if card is null then return json_build_object('drop', false, 'reason', 'empty'); end if;
  return json_build_object('drop', true, 'card', card, 'cap', cap, 'left', cap - used - 1);
end $$;
revoke execute on function card_roll(uuid, text) from public;
grant execute on function card_roll(uuid, text) to anon, authenticated;

-- กาชาไม่แถมการ์ด (ห่อไว้เหมือนเดิม คืน cards เป็นอาร์เรย์ว่าง)
create or replace function gacha_pull(p_token uuid, p_n int default 1) returns json
language plpgsql security definer set search_path = public as $$
declare r json;
begin
  r := _gacha_pull(p_token, p_n);
  return (r::jsonb || jsonb_build_object('cards', '[]'::jsonb))::json;
end $$;
revoke execute on function gacha_pull(uuid, int) from public;
grant execute on function gacha_pull(uuid, int) to anon, authenticated;

-- ค่าเริ่มต้นใหม่ (เปลี่ยนเฉพาะที่ครูยังไม่เคยแก้)
update app_settings set value = '3'  where key = 'card_daily_cap' and value = '5';
update app_settings set value = '50' where key = 'card_drop_pct'  and value = '30';
update app_settings set value = '0'  where key = 'card_gacha_pct';

create or replace function card_album(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); res json; s students%rowtype;
begin
  select * into s from students where id = sid;
  select json_build_object('shards', s.shards, 'pity', s.card_pity, 'pity_max', _setting_int('card_pity', 4),
    'cap', _setting_int('card_daily_cap', 3), 'used', (select count(*) from card_drops where student_id = sid and play_date = today_th() and source = 'game'),
    'sets', coalesce((select json_agg(json_build_object('id', cs.id, 'title', cs.title, 'emoji', cs.emoji, 'color', cs.color,
        'reward', json_build_object('coins', cs.reward_coins, 'pulls', cs.reward_pulls, 'decor', (select d.name from decor_items d where d.id = cs.reward_decor)),
        'claimed', exists (select 1 from student_set_claims x where x.student_id = sid and x.set_id = cs.id),
        'cards', (select coalesce(json_agg(json_build_object('id', c.id, 'no', c.no, 'rarity', c.rarity, 'symbol', c.symbol, 'emoji', c.emoji,
              'own', sc.card_id is not null, 'qty', coalesce(sc.qty, 0), 'name', case when sc.card_id is not null then c.name end,
              'fact', case when sc.card_id is not null then c.fact end, 'image', case when sc.card_id is not null then c.image_url end) order by c.no), '[]'::json)
            from cards c left join student_cards sc on sc.card_id = c.id and sc.student_id = sid where c.set_id = cs.id and c.active))
        order by cs.sort, cs.title) from card_sets cs where cs.active), '[]'::json)) into res;
  return res;
end $$;
revoke execute on function card_album(uuid) from public;
grant execute on function card_album(uuid) to anon, authenticated;

insert into news_posts (kind, title, summary, body, sort, active)
select 'news', 'ปรับกติกาการ์ดสะสม: ดรอปจากมอนสเตอร์ 🐲🃏',
  'การ์ดสุ่มได้จากการ "ชนะมอนสเตอร์" เท่านั้น วันละไม่เกิน 3 ใบ · พร้อมหลังการ์ดลายใหม่!',
  'ตั้งแต่นี้ การ์ดสะสมจะสุ่มได้จากการชนะมอนสเตอร์ในโหมดต่อสู้เท่านั้น (เล่นควิซ/จับคู่/เกมอื่นและสุ่มกาชาไม่ได้การ์ดแล้ว) · จำกัดวันละ 3 ใบต่อคน · ใบแรกของทุกคนได้แน่นอน · ใบซ้ำกลายเป็นเศษธาตุเหมือนเดิม · ครูยังแจกการ์ดเป็นของขวัญได้ · และการ์ดทุกใบมีหลังการ์ดลายใหม่ตอนพลิกเปิดแล้ว!',
  5, true
where not exists (select 1 from news_posts where title like 'ปรับกติกาการ์ดสะสม%');

-- ประกาศเดิมอธิบายกติกาเก่า → ปิด แล้วใช้ประกาศใหม่แทน
update news_posts set active = false where title = 'สมุดการ์ดสะสมเปิดแล้ว! 📖🃏';
-- 59: ลดโอกาสดรอปการ์ดเป็น 30% + ปรับเรทความหายาก (N70 · R22 · SR7 · SSR1) + รวมประกาศการ์ดเหลือฉบับเดียว (v1.90)
update app_settings set value = '30' where key = 'card_drop_pct';
update app_settings set value = '70' where key = 'card_w_n';
update app_settings set value = '22' where key = 'card_w_r';
update app_settings set value = '7'  where key = 'card_w_sr';
update app_settings set value = '1'  where key = 'card_w_ssr';

-- ลบประกาศการ์ดเดิมที่ซ้ำ/ล้าสมัยทั้งหมด แล้วลงประกาศใหม่ฉบับเดียว
delete from news_posts where title like 'สมุดการ์ดสะสมเปิดแล้ว%' or title like 'ปรับกติกาการ์ดสะสม%' or title like 'กติกาการ์ดสะสม%';
insert into news_posts (kind, title, summary, body, image, sort, active)
values ('news', 'กติกาการ์ดสะสม 📖🃏 ดรอปจากมอนสเตอร์',
  'ชนะมอนสเตอร์ ลุ้นการ์ด 30% · วันละไม่เกิน 3 ใบ · ยิ่งหายากยิ่งดรอปยาก',
  E'📖 สมุดการ์ดสะสม — 60 ใบ 3 ชุด (ธาตุรอบตัว · นักเคมี · อุปกรณ์แล็บ)\n\n🐲 ได้การ์ดจาก "ชนะมอนสเตอร์" เท่านั้น\n🎲 ชนะแต่ละครั้งมีโอกาสได้การ์ด 30% · ใบแรกของทุกคนได้แน่นอน\n📅 จำกัดวันละไม่เกิน 3 ใบต่อคน\n💎 เรทความหายาก: N 70% · R 22% · SR 7% · SSR 1%\n♻️ ใบซ้ำกลายเป็นเศษธาตุ · ซ้ำติดกันหลายครั้งใบต่อไปจะเป็นใบใหม่แน่นอน\n🏆 สะสมครบชุดรับเหรียญ ตั๋วกาชา และของตกแต่ง\n🎁 ครูอาจแจกการ์ดเป็นของขวัญพิเศษ',
  'assets/news/items.jpg', 40, true);
-- 60: รูปประกาศ Mini Guild และการ์ดสะสม (v1.91)
update news_posts set image = 'assets/news/guild.jpg' where title like 'Mini Guild%';
update news_posts set image = 'assets/news/cards.jpg' where title like 'กติกาการ์ดสะสม%';
-- 61: Mini Guild แสดงตัวละครสมาชิก (พร้อมพื้นหลัง/ชุด/กรอบ) ในหน้ากิลด์ และในตารางอันดับกิลด์ (v1.92)
do $$ begin
  if not exists (select 1 from pg_proc where proname = '_guild_status' and pronamespace = 'public'::regnamespace) then
    alter function guild_status(uuid) rename to _guild_status; end if;
end $$;
revoke execute on function _guild_status(uuid) from public, anon, authenticated;

create or replace function _guild_member_card(p_guild uuid, p_hid boolean) returns jsonb
language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(jsonb_build_object('no', st.no, 'name', st.name, 'avatar', st.avatar, 'char_class', st.char_class,
      'rank_info', rank_info(st.exp)::jsonb, 'decor', _decor_of(st.id)::jsonb, 'leader', gl.leader_id = st.id,
      'gp', case when p_hid then null else mg.gp end) order by (gl.leader_id = st.id) desc, st.no), '[]'::jsonb)
    from guild_members gm join students st on st.id = gm.student_id join guilds gl on gl.id = gm.guild_id
    left join _guild_member_gp() mg on mg.student_id = st.id where gm.guild_id = p_guild $$;
revoke execute on function _guild_member_card(uuid, boolean) from public, anon, authenticated;

create or replace function guild_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare r jsonb; sid uuid := _sid(p_token); hid boolean; gid uuid;
begin
  r := _guild_status(p_token)::jsonb;
  if r->'my' is not null and jsonb_typeof(r->'my') = 'object' then
    hid := coalesce((r#>>'{cfg,hidden}')::boolean, false);
    gid := (r#>>'{my,id}')::uuid;
    r := jsonb_set(r, '{my,members}', (
      select coalesce(jsonb_agg(m || jsonb_build_object('me', (select st.id = sid from students st where st.no = (m->>'no')::int
            and st.id in (select student_id from guild_members where guild_id = gid)))), '[]'::jsonb)
        from jsonb_array_elements(_guild_member_card(gid, hid)) m));
  end if;
  return r::json;
end $$;
revoke execute on function guild_status(uuid) from public;
grant execute on function guild_status(uuid) to anon, authenticated;

create or replace function guild_board(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cfg jsonb := _guild_cfg(); mygid uuid; rws jsonb;
begin
  select guild_id into mygid from guild_members where student_id = sid;
  if (cfg->>'hidden')::boolean then return json_build_object('cfg', cfg, 'hidden', true, 'rows', '[]'::json); end if;
  select coalesce(jsonb_agg(x order by x.rank), '[]') into rws from (
    select r.rank, r.name, c.name as class_name, r.size, r.avg, (r.guild_id = mygid) as mine, r.room_rank,
           _guild_member_card(r.guild_id, true) as members
      from _guild_ranks() r join classes c on c.id = r.class_id where r.ranked order by r.rank limit 30) x;
  return json_build_object('cfg', cfg, 'hidden', false, 'rows', rws,
    'unranked', (select count(*) from _guild_ranks() where not ranked), 'total', (select count(*) from guilds));
end $$;
revoke execute on function guild_board(uuid) from public;
grant execute on function guild_board(uuid) to anon, authenticated;
-- 62: สัญลักษณ์กิลด์ (เลือกได้ 12 แบบ) แสดงข้างชื่อกิลด์ในหน้ากิลด์/อันดับ/หน้าแรก (v1.97)
alter table guilds add column if not exists emblem smallint check (emblem between 1 and 12);

-- ค่าเริ่มต้นของกิลด์ที่ยังไม่เลือก: สุ่มแบบคงที่จากรหัสกิลด์ (1–12)
create or replace function _guild_emb(p_id uuid, p_emblem smallint) returns int
language sql immutable as $$ select coalesce(p_emblem::int, 1 + abs(hashtext(p_id::text)) % 12) $$;
revoke execute on function _guild_emb(uuid, smallint) from public, anon, authenticated;

create or replace function guild_set_emblem(p_token uuid, p_emblem int) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); g guilds%rowtype;
begin
  if today_th() > (_guild_cfg()->>'end')::date then raise exception 'กิจกรรมจบแล้ว'; end if;
  if p_emblem is null or p_emblem < 1 or p_emblem > 12 then raise exception 'สัญลักษณ์ไม่ถูกต้อง'; end if;
  select * into g from guilds where leader_id = sid for update;
  if not found then raise exception 'เฉพาะหัวหน้ากิลด์เท่านั้น'; end if;
  update guilds set emblem = p_emblem where id = g.id;
  return json_build_object('emblem', p_emblem);
end $$;
revoke execute on function guild_set_emblem(uuid, int) from public;
grant execute on function guild_set_emblem(uuid, int) to anon, authenticated;

create or replace function guild_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare r jsonb; sid uuid := _sid(p_token); hid boolean; gid uuid;
begin
  r := _guild_status(p_token)::jsonb;
  if r->'my' is not null and jsonb_typeof(r->'my') = 'object' then
    hid := coalesce((r#>>'{cfg,hidden}')::boolean, false);
    gid := (r#>>'{my,id}')::uuid;
    r := jsonb_set(r, '{my,members}', (
      select coalesce(jsonb_agg(m || jsonb_build_object('me', (select st.id = sid from students st where st.no = (m->>'no')::int
            and st.id in (select student_id from guild_members where guild_id = gid)))), '[]'::jsonb)
        from jsonb_array_elements(_guild_member_card(gid, hid)) m));
    r := jsonb_set(r, '{my,emblem}', to_jsonb((select _guild_emb(id, emblem) from guilds where id = gid)));
  end if;
  if jsonb_typeof(r->'open') = 'array' then
    r := jsonb_set(r, '{open}', (select coalesce(jsonb_agg(o || jsonb_build_object('emblem',
          coalesce((select _guild_emb(gl.id, gl.emblem) from guilds gl where gl.id = (o->>'id')::uuid), 1))), '[]'::jsonb)
        from jsonb_array_elements(r->'open') o));
  end if;
  return r::json;
end $$;
revoke execute on function guild_status(uuid) from public;
grant execute on function guild_status(uuid) to anon, authenticated;

create or replace function guild_board(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cfg jsonb := _guild_cfg(); mygid uuid; rws jsonb;
begin
  select guild_id into mygid from guild_members where student_id = sid;
  if (cfg->>'hidden')::boolean then return json_build_object('cfg', cfg, 'hidden', true, 'rows', '[]'::json); end if;
  select coalesce(jsonb_agg(x order by x.rank), '[]') into rws from (
    select r.rank, r.name, c.name as class_name, r.size, r.avg, (r.guild_id = mygid) as mine, r.room_rank,
           _guild_emb(gl.id, gl.emblem) as emblem, _guild_member_card(r.guild_id, true) as members
      from _guild_ranks() r join classes c on c.id = r.class_id join guilds gl on gl.id = r.guild_id where r.ranked order by r.rank limit 30) x;
  return json_build_object('cfg', cfg, 'hidden', false, 'rows', rws,
    'unranked', (select count(*) from _guild_ranks() where not ranked), 'total', (select count(*) from guilds));
end $$;
revoke execute on function guild_board(uuid) from public;
grant execute on function guild_board(uuid) to anon, authenticated;
-- 63: ภารกิจกิลด์ + แถบรางวัลแบบ Battle Pass (v1.98)
-- ภารกิจร่วมกันในกิลด์ (เริ่มชุดแรก: ตอบถูกรวม · ล่ามอนสเตอร์ · มาเรียนครบทีม · ครบทุกคนเล่นเกมในวันเดียว)
-- เป้าหมายปรับตามจำนวนสมาชิก · เพดานต่อคนต่อภารกิจ (cap_pct) กันคนเก่งคนเดียวแบก · ความคืบหน้านับจากข้อมูลจริงที่เซิร์ฟเวอร์บันทึก
-- รางวัลขั้นบาร์: ปลดล็อกเมื่อ MP รวมของกิลด์ถึงเกณฑ์ · กดรับได้เฉพาะคนที่ช่วยอย่างน้อย 1 ภารกิจ
create table if not exists guild_quests (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('correct', 'monster', 'attend', 'allplay')),
  title text not null, emoji text not null default '🎯',
  per_member int not null default 10 check (per_member > 0),   -- เป้าต่อสมาชิก 1 คน (allplay = จำนวนวันของทั้งทีม)
  mp int not null default 100 check (mp >= 0),                 -- MP ที่ได้เมื่อครบเป้า (ได้ตามสัดส่วน)
  cap_pct int not null default 40 check (cap_pct between 10 and 100), -- คนเดียวนับได้ไม่เกินกี่ % ของเป้า
  sort int not null default 0, active boolean not null default true
);
create table if not exists guild_pass_tiers (
  tier int primary key, need_mp int not null check (need_mp >= 0), label text not null, emoji text not null default '🏅',
  coins int not null default 0, pulls int not null default 0, exp int not null default 0
);
create table if not exists guild_pass_claims (
  student_id uuid not null references students(id) on delete cascade, tier int not null, claimed_at timestamptz not null default now(),
  primary key (student_id, tier)
);
do $$ declare t text; begin
  foreach t in array array['guild_quests', 'guild_pass_tiers', 'guild_pass_claims'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists teacher_all on public.%I', t);
    execute format('create policy teacher_all on public.%I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;

insert into guild_quests (kind, title, emoji, per_member, mp, cap_pct, sort)
select * from (values
  ('correct', 'รวมพลังตอบโจทย์', '🧪', 40, 100, 40, 1),
  ('monster', 'ล่ามอนสเตอร์ร่วมกัน', '🐲', 6, 100, 40, 2),
  ('attend', 'มาเรียนครบทีม', '🏫', 4, 100, 60, 3),
  ('allplay', 'ครบทุกคนวันนี้', '🤝', 6, 100, 100, 5)) v(kind, title, emoji, per_member, mp, cap_pct, sort)
where not exists (select 1 from guild_quests);
insert into guild_pass_tiers (tier, need_mp, label, emoji, coins, pulls, exp)
select * from (values
  (1, 40, 'ก้าวแรก', '🥉', 15, 0, 0), (2, 100, 'ร่วมแรง', '🥉', 20, 0, 0), (3, 180, 'ใจเดียวกัน', '🥈', 25, 1, 0),
  (4, 260, 'ทีมแกร่ง', '🥈', 30, 1, 0), (5, 340, 'เกือบสุดทาง', '🥇', 40, 2, 0), (6, 400, 'ครบทุกภารกิจ', '👑', 50, 2, 50)) v(tier, need_mp, label, emoji, coins, pulls, exp)
where not exists (select 1 from guild_pass_tiers);

-- ความคืบหน้าของกิลด์ (คืน jsonb) — ภายในเท่านั้น
create or replace function _gq_calc(p_guild uuid) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare cfg jsonb := _guild_cfg(); st date := (cfg->>'start')::date; en date := least((cfg->>'end')::date, today_th());
        g guilds%rowtype; size int; q guild_quests%rowtype; tgt int; capn int; per jsonb; prog int; qs jsonb := '[]'; tot int := 0; mpq int; ids uuid[];
        r record; days int; sh jsonb; n numeric; mem jsonb := '{}'; helped jsonb := '{}';
begin
  select * into g from guilds where id = p_guild;
  select array_agg(student_id) into ids from guild_members where guild_id = p_guild;
  size := coalesce(cardinality(ids), 0);
  if not found or size = 0 or st > en then
    for q in select * from guild_quests where active order by sort, title loop
      qs := qs || jsonb_build_object('id', q.id, 'kind', q.kind, 'title', q.title, 'emoji', q.emoji, 'target', case when q.kind = 'allplay' then q.per_member else q.per_member * greatest(size, 1) end,
        'progress', 0, 'mp', q.mp, 'mp_got', 0, 'cap', q.cap_pct);
    end loop;
    return jsonb_build_object('quests', qs, 'total_mp', 0, 'share', '{}'::jsonb);
  end if;
  for q in select * from guild_quests where active order by sort, title loop
    per := '{}'::jsonb;
    if q.kind = 'allplay' then
      tgt := q.per_member;
      select count(*) into days from generate_series(st, en, interval '1 day') d
       where not exists (select 1 from unnest(ids) s where not exists (select 1 from game_plays gp where gp.student_id = s and gp.play_date = d::date)
                                                      and not exists (select 1 from battles b where b.student_id = s and b.play_date = d::date));
      prog := least(tgt, days);
      for r in select s from unnest(ids) s loop per := per || jsonb_build_object(r.s::text, case when prog > 0 then prog::numeric / size else 0 end); end loop;
    else
      tgt := q.per_member * size; capn := greatest(1, ceil(tgt * q.cap_pct / 100.0)::int);
      for r in select s from unnest(ids) s loop
        n := case q.kind
          when 'correct' then coalesce((select sum(correct) from game_plays where student_id = r.s and play_date between st and en), 0)
                            + coalesce((select sum(correct) from battles where student_id = r.s and play_date between st and en), 0)
          when 'monster' then (select count(*) from battles where student_id = r.s and status = 'won' and play_date between st and en)
          else (select count(*) from ch_attendance where student_id = r.s and class_id = g.class_id and status in ('present', 'late') and att_date between st and en) end;
        per := per || jsonb_build_object(r.s::text, least(n, capn));
      end loop;
      select least(tgt, coalesce(sum(value::numeric), 0)::int) into prog from jsonb_each_text(per);
    end if;
    mpq := floor(q.mp * prog::numeric / tgt)::int; tot := tot + mpq;
    for r in select key, value::numeric v from jsonb_each_text(per) loop
      mem := jsonb_set(mem, array[r.key], to_jsonb(coalesce((mem->>r.key)::numeric, 0) + case when tgt > 0 then q.mp * r.v / tgt else 0 end));
      if r.v > 0 then helped := jsonb_set(helped, array[r.key], 'true'::jsonb); end if;
    end loop;
    qs := qs || jsonb_build_object('id', q.id, 'kind', q.kind, 'title', q.title, 'emoji', q.emoji, 'target', tgt, 'progress', prog, 'mp', q.mp, 'mp_got', mpq, 'cap', q.cap_pct);
  end loop;
  return jsonb_build_object('quests', qs, 'total_mp', tot, 'share', mem, 'helped', helped);
end $$;
revoke execute on function _gq_calc(uuid) from public, anon, authenticated;

create or replace function _gq_status(p_guild uuid, p_sid uuid) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare c jsonb := _gq_calc(p_guild); tot int := (c->>'total_mp')::int; tiers jsonb; mx int; ok boolean := coalesce((c->'helped'->>p_sid::text)::boolean, false); mem jsonb;
begin
  select coalesce(jsonb_agg(jsonb_build_object('tier', t.tier, 'need_mp', t.need_mp, 'label', t.label, 'emoji', t.emoji, 'coins', t.coins, 'pulls', t.pulls, 'exp', t.exp,
      'reached', tot >= t.need_mp, 'claimed', exists (select 1 from guild_pass_claims x where x.student_id = p_sid and x.tier = t.tier),
      'claimable', tot >= t.need_mp and ok and not exists (select 1 from guild_pass_claims x where x.student_id = p_sid and x.tier = t.tier)) order by t.tier), '[]'::jsonb) into tiers from guild_pass_tiers t;
  select coalesce(sum((q->>'mp')::int), 0) into mx from jsonb_array_elements(c->'quests') q;
  select coalesce(jsonb_agg(jsonb_build_object('name', st.name, 'leader', gl.leader_id = st.id, 'me', st.id = p_sid,
        'mp', round(coalesce((c->'share'->>st.id::text)::numeric, 0))::int) order by coalesce((c->'share'->>st.id::text)::numeric, 0) desc, st.no), '[]'::jsonb) into mem
    from guild_members gm join students st on st.id = gm.student_id join guilds gl on gl.id = gm.guild_id where gm.guild_id = p_guild;
  return jsonb_build_object('quests', c->'quests', 'total_mp', tot, 'max_mp', greatest(mx, coalesce((select max(need_mp) from guild_pass_tiers), 0)), 'tiers', tiers, 'eligible', ok, 'members', mem);
end $$;
revoke execute on function _gq_status(uuid, uuid) from public, anon, authenticated;

create or replace function guild_pass_claim(p_token uuid, p_tier int) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); gid uuid; s jsonb; t jsonb; gt guild_pass_tiers%rowtype;
begin
  if (_guild_cfg()->>'phase') not in ('running', 'ended') then raise exception 'กิจกรรมยังไม่เริ่ม'; end if;
  select guild_id into gid from guild_members where student_id = sid;
  if gid is null then raise exception 'คุณยังไม่มีกิลด์'; end if;
  s := _gq_status(gid, sid);
  select x into t from jsonb_array_elements(s->'tiers') x where (x->>'tier')::int = p_tier;
  if t is null then raise exception 'ไม่พบขั้นรางวัลนี้'; end if;
  if (t->>'claimed')::boolean then raise exception 'รับรางวัลนี้ไปแล้ว'; end if;
  if not (t->>'reached')::boolean then raise exception 'กิลด์ยังไม่ถึงขั้นนี้'; end if;
  if not (s->>'eligible')::boolean then raise exception 'ต้องช่วยภารกิจอย่างน้อย 1 อย่างก่อนถึงจะรับรางวัลได้'; end if;
  select * into gt from guild_pass_tiers where tier = p_tier;
  perform _guild_give(sid, 'guild:pass:' || p_tier, 'ภารกิจกิลด์ · ' || gt.label, gt.coins, gt.pulls, gt.exp);
  insert into guild_pass_claims (student_id, tier) values (sid, p_tier) on conflict do nothing;
  return json_build_object('label', gt.label, 'coins', gt.coins, 'pulls', gt.pulls, 'exp', gt.exp);
end $$;
revoke execute on function guild_pass_claim(uuid, int) from public;
grant execute on function guild_pass_claim(uuid, int) to anon, authenticated;

-- guild_status: เพิ่ม my.pass (ภารกิจ + แถบรางวัล) — โหมดส่องดูได้เพราะอยู่ในฟังก์ชันที่อนุญาตอยู่แล้ว
create or replace function guild_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare r jsonb; sid uuid := _sid(p_token); hid boolean; gid uuid;
begin
  r := _guild_status(p_token)::jsonb;
  if r->'my' is not null and jsonb_typeof(r->'my') = 'object' then
    hid := coalesce((r#>>'{cfg,hidden}')::boolean, false);
    gid := (r#>>'{my,id}')::uuid;
    r := jsonb_set(r, '{my,members}', (
      select coalesce(jsonb_agg(m || jsonb_build_object('me', (select st.id = sid from students st where st.no = (m->>'no')::int
            and st.id in (select student_id from guild_members where guild_id = gid)))), '[]'::jsonb)
        from jsonb_array_elements(_guild_member_card(gid, hid)) m));
    r := jsonb_set(r, '{my,emblem}', to_jsonb((select _guild_emb(id, emblem) from guilds where id = gid)));
    if (r#>>'{cfg,phase}') in ('running', 'ended') then r := jsonb_set(r, '{my,pass}', _gq_status(gid, sid)); end if;
  end if;
  if jsonb_typeof(r->'open') = 'array' then
    r := jsonb_set(r, '{open}', (select coalesce(jsonb_agg(o || jsonb_build_object('emblem',
          coalesce((select _guild_emb(gl.id, gl.emblem) from guilds gl where gl.id = (o->>'id')::uuid), 1))), '[]'::jsonb)
        from jsonb_array_elements(r->'open') o));
  end if;
  return r::json;
end $$;
revoke execute on function guild_status(uuid) from public;
grant execute on function guild_status(uuid) to anon, authenticated;
-- 64: ประกาศภารกิจกิลด์ (v1.98) — รันซ้ำได้ ไม่โพสต์ซ้ำ
insert into news_posts (kind, title, summary, body, image, sort, active)
select 'news', 'ภารกิจกิลด์ 🎯 ช่วยกันสะสม MP ปลดล็อกรางวัล',
  'ตอบถูก · ล่ามอนสเตอร์ · มาเรียน · เล่นพร้อมกัน — MP รวมของทีมปลดล็อกรางวัล 6 ขั้น',
  E'🎯 ภารกิจกิลด์ เปิดแล้ว! ดูได้ที่หน้า Mini Guild\n\n✅ ตอบถูกรวมทีม\n👾 ล่ามอนสเตอร์\n📅 มาเรียนครบทีม\n🤝 ทุกคนในกิลด์เล่นเกมในวันเดียวกัน\n\n📊 เป้าหมายปรับตามจำนวนสมาชิก · คนเดียวช่วยได้ไม่เกินสัดส่วนที่กำหนด จึงต้องช่วยกันทั้งทีม\n🎁 สะสม MP รวมของกิลด์ ปลดล็อกรางวัล 6 ขั้น (เหรียญ · ตั๋วกาชา · EXP)\n🙋 รับรางวัลได้เฉพาะคนที่ช่วยอย่างน้อย 1 ภารกิจ ใครไม่ช่วยอดนะ!\n\nรีบชวนเพื่อนในทีมมาเล่นกันเลย 💪',
  'assets/news/mission.jpg', 45, true
where not exists (select 1 from news_posts where title like 'ภารกิจกิลด์%');
-- 65: ฉายาปั่นๆ ชุดใหม่ 20 แบบ (ธีมกิลด์/ภารกิจ/มอนสเตอร์/การ์ด) รันซ้ำได้
-- ปัญญา +1 EXP/ควิซ ต่อ 2 แต้ม · ขยัน +1% EXP · พลัง +3% ดาเมจบอส · โชค +3% โอกาส SR/SSR · st_coin = โบนัสเหรียญ %
insert into decor_items (slot, key, name, emoji, rarity, price, sort, st_int, st_dil, st_str, st_luk, st_coin, ability)
select v.* from (values
  ('title','text','คนเดียวในกิลด์ที่ทำการบ้าน','📚','N',60,40,1,0,0,0,0,'เพื่อนในทีมพึ่งได้'),
  ('title','text','ขอแค่แต้มเฉลี่ยผ่าน','🙏','N',60,41,0,1,0,0,0,'ไม่หวังสูง แต่ไม่ทิ้งทีม'),
  ('title','text','ตื่นมาเล่นตอนตีสอง','🌙','N',70,42,0,0,0,1,0,'ดึกแต่โชคดี'),
  ('title','text','พิมพ์ชื่อกิลด์ผิดทุกครั้ง','⌨️','N',60,43,0,0,1,0,0,'ผิดแต่มั่นใจ ดาเมจแรงขึ้นนิดๆ'),
  ('title','text','ลืมกดรับรางวัล','😵','N',70,44,0,0,0,1,2,'ลืมบ่อย แต่เหรียญยังเข้า +2%'),
  ('title','text','แบกทีมด้วยมือเดียว','💪','R',150,45,0,0,2,1,0,'ช่วยภารกิจกิลด์สุดแรง'),
  ('title','text','ล่ามอนไม่เลือกวัน','👾','R',160,46,0,1,2,0,0,'ตีมอนสเตอร์ได้ทุกวัน'),
  ('title','text','นักสะสมการ์ดสายหวย','🃏','R',170,47,0,0,0,2,3,'ลุ้นการ์ดเก่ง เหรียญ +3%'),
  ('title','text','ผู้เช็คชื่อทันก่อนครูเดินเข้า','⏱️','R',150,48,0,2,0,1,0,'มาทันเสมอ ขยันขึ้น'),
  ('title','text','ตอบถูกเพราะดวง (บอกว่าเพราะเก่ง)','🎯','R',160,49,2,0,0,1,0,'ถ่อมตัวไม่เป็น แต่ถูกจริง'),
  ('title','text','เศรษฐีเหรียญหน้ากิลด์','🏦','R',180,50,0,0,0,1,5,'เหรียญเข้าเยอะ +5%'),
  ('title','text','เทพเจ้าแห่ง MP','⚡','SR',null,51,0,1,1,2,3,'MP ไหลเข้ากิลด์ไม่หยุด'),
  ('title','text','ผู้นำกิลด์ผู้ไม่เคยพัก','👑','SR',null,52,1,2,1,0,4,'ปลุกทีมทุกเช้า'),
  ('title','text','ราชาพิชิตมอนสเตอร์ (ตัวที่ 1 เท่านั้น)','🐲','SR',null,53,0,0,3,1,0,'ชนะแล้วมั่นใจเกินตัว'),
  ('title','text','นักปั่นแต้มไม่หลับไม่นอน','🌀','SR',null,54,0,3,0,1,2,'ขยัน +3 ไม่รู้จักเหนื่อย'),
  ('title','text','จอมโกยการ์ด SSR','🌟','SSR',null,55,0,0,1,4,5,'โชคสุดจัด การ์ดหายากมาหา'),
  ('title','text','ตำนานกิลด์อันดับ 1','🏆','SSR',null,56,2,1,2,2,5,'ทั้งทีมกราบ ทุกด้านพุ่ง'),
  ('title','text','อัจฉริยะผู้ลืมวันส่งงาน','🧠','SSR',null,57,4,0,1,1,0,'เก่งสุดขีด แต่ต้องมีคนเตือน'),
  ('title','text','ผู้ถูกเลือกโดยเทพเจ้าเคมี','⚗️','SSR',null,58,1,1,3,1,4,'บอสเจอถึงกับร้อง'),
  ('title','text','ฉายาที่ครูก็ยังอ่านไม่ออก','❓','SSR',null,59,2,2,1,1,3,'ปริศนาแห่งห้องแล็บ')
) v(slot,key,name,emoji,rarity,price,sort,st_int,st_dil,st_str,st_luk,st_coin,ability)
where not exists (select 1 from decor_items d where d.slot='title' and d.name=v.name);

-- ฉายา SR/SSR ที่ไม่ขายในร้าน เข้ากาชา
insert into gacha_items (name, rarity, kind, value, emoji, weight, decor_id)
select d.name, d.rarity, 'decor', 0, d.emoji, case d.rarity when 'N' then 3 when 'R' then 2 else 1 end, d.id
  from decor_items d
 where d.slot = 'title' and d.price is null and d.rarity in ('SR','SSR')
   and not exists (select 1 from gacha_items g where g.decor_id = d.id);
-- 66: ไอเทมกดใช้ (ยา/บัฟ/ม้วนอัปเกรด) + เลเวลของสวมใส่ + ปรับสมดุลสเตตัส + ลดเรท SSR กาชา (v2.00) · รันซ้ำได้
--  · ไอเทมกดใช้: ซื้อด้วยเหรียญ (จำกัดต่อวัน) · บัฟมีผลถึงสิ้นวัน (เวลาไทย) ชนิดละ 1 ครั้ง/วัน
--  · ยาฟื้นฟู: ใช้ในศึกมอนสเตอร์ (ฟื้นตามเปอร์เซ็นต์ HP สูงสุด · สูงสุด 2 ครั้ง/ศึก)
--  · อัปเกรดของสวมใส่: ใช้ม้วนอัปเกรด + เหรียญ · ทุกเลเวลที่เพิ่ม = +1 สเตตัสหลักของไอเทมนั้น
--  · สมดุล: เพดานสเตตัสต่อไอเทมตามความหายาก + เพดานรวมโบนัสจากไอเทม (stat_item_cap=12, stat_coin_cap=15)
--  · กาชา: น้ำหนัก SSR × gacha_ssr_mult % (ค่าเริ่มต้น 20 → SSR ราว 3% จากเดิม ~14%)

-- ---------- ตาราง ----------
create table if not exists consumables (
  id uuid primary key default gen_random_uuid(),
  key text unique not null,
  name text not null, emoji text not null default '🧪', image text,
  rarity text not null default 'N' check (rarity in ('N','R','SR','SSR')),
  kind text not null check (kind in ('buff_exp','buff_coin','buff_luk','buff_str','buff_int','heal','scroll','stat_reset')),
  power int not null default 0,          -- ขนาดผล: บัฟ = ค่าที่เพิ่ม · heal = % ของ HP สูงสุด
  price int check (price is null or price >= 0),
  daily_buy int not null default 3 check (daily_buy between 1 and 20),
  descr text, sort int not null default 0, active boolean not null default true
);
create table if not exists student_items (
  student_id uuid not null references students(id) on delete cascade,
  item_id uuid not null references consumables(id) on delete cascade,
  qty int not null default 0 check (qty >= 0),
  primary key (student_id, item_id)
);
create table if not exists student_buffs (
  student_id uuid not null references students(id) on delete cascade,
  kind text not null, power int not null, day date not null,
  primary key (student_id, kind)
);
create table if not exists item_daily (
  student_id uuid not null references students(id) on delete cascade,
  item_id uuid not null references consumables(id) on delete cascade,
  day date not null, bought int not null default 0,
  primary key (student_id, item_id, day)
);
alter table student_decor add column if not exists lvl int not null default 1 check (lvl between 1 and 9);
alter table battles add column if not exists potions int not null default 0;

do $$ declare t text; begin
  foreach t in array array['consumables', 'student_items', 'student_buffs', 'item_daily'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists teacher_all on public.%I', t);
    execute format('create policy teacher_all on public.%I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;

insert into app_settings (key, value) values ('stat_item_cap', '12'), ('stat_coin_cap', '15'), ('gacha_ssr_mult', '20') on conflict (key) do nothing;

-- ---------- ไอเทมตั้งต้น ----------
insert into consumables (key, name, emoji, rarity, kind, power, price, daily_buy, descr, sort)
select v.* from (values
  ('p_exp',   'ยาเพิ่มพลังสมอง',   '🧪', 'R',  'buff_exp',   15, 90,  2, 'EXP ที่ได้รับ +15% ถึงสิ้นวัน',                10),
  ('p_coin',  'ยาเหรียญทอง',       '💰', 'R',  'buff_coin',  20, 80,  2, 'เหรียญที่ได้รับ +20% ถึงสิ้นวัน',              20),
  ('p_luck',  'ยาโชคสี่แฉก',       '🍀', 'SR', 'buff_luk',    4, 120, 2, 'โชค +4 ถึงสิ้นวัน (โอกาส SR/SSR ในกาชาสูงขึ้น)', 30),
  ('p_str',   'ยากล้ามเคมี',       '⚔️', 'R',  'buff_str',   15, 90,  2, 'ดาเมจบอสจากเควส +15% ถึงสิ้นวัน',              40),
  ('p_int',   'ยาอัจฉริยะ',        '🧠', 'R',  'buff_int',    2, 80,  2, 'โบนัส EXP ควิซ +2 ถึงสิ้นวัน',                 50),
  ('p_heal',  'ยาฟื้นฟู HP',       '💚', 'N',  'heal',       40, 60,  5, 'ใช้ในศึกมอนสเตอร์ ฟื้น HP 40% (ใช้ได้ 2 ครั้ง/ศึก)', 60),
  ('scroll',  'ม้วนอัปเกรด',       '📜', 'R',  'scroll',      0, 120, 5, 'ใช้อัปเกรดเลเวลของสวมใส่ (ดูแท็บ 🧪 ไอเทม)',      70),
  ('t_reset', 'ตั๋วล้างแต้มสเตตัส', '🔄', 'N',  'stat_reset',  0, 90,  2, 'ล้างแต้มสเตตัสที่ใส่ไว้ ใส่ใหม่ได้ทันที',        80)
) v(key, name, emoji, rarity, kind, power, price, daily_buy, descr, sort)
where not exists (select 1 from consumables c where c.key = v.key);

-- ---------- สมดุลสเตตัสของไอเทมตกแต่ง ----------
create or replace function _item_main(a int, b int, c int, d int) returns text
language sql immutable as $$
  select case when greatest(a, b, c, d) <= 0 then null
              when a >= greatest(b, c, d) then 'int' when b >= greatest(c, d) then 'dil' when c >= d then 'str' else 'luk' end
$$;
revoke execute on function _item_main(int, int, int, int) from public, anon, authenticated;

do $$ declare r record; cap int; ccap int; a int; b int; c int; d int; n int; begin
  for r in select * from decor_items loop
    cap := case r.rarity when 'N' then 2 when 'R' then 3 when 'SR' then 4 when 'SSR' then 5 else 7 end;
    ccap := case r.rarity when 'N' then 2 when 'R' then 4 when 'SR' then 6 when 'SSR' then 6 else 8 end;
    a := coalesce(r.st_int, 0); b := coalesce(r.st_dil, 0); c := coalesce(r.st_str, 0); d := coalesce(r.st_luk, 0);
    n := 0;
    while a + b + c + d > cap and n < 40 loop
      if a >= greatest(b, c, d) then a := a - 1; elsif b >= greatest(c, d) then b := b - 1; elsif c >= d then c := c - 1; else d := d - 1; end if;
      n := n + 1;
    end loop;
    if a <> coalesce(r.st_int, 0) or b <> coalesce(r.st_dil, 0) or c <> coalesce(r.st_str, 0) or d <> coalesce(r.st_luk, 0) or coalesce(r.st_coin, 0) > ccap then
      update decor_items set st_int = a, st_dil = b, st_str = c, st_luk = d, st_coin = least(coalesce(st_coin, 0), ccap) where id = r.id;
    end if;
  end loop;
end $$;

-- ---------- _stats: เลเวลของสวมใส่ + เพดานโบนัสไอเทม + บัฟประจำวัน ----------
create or replace function _stats(p_sid uuid) returns json
language plpgsql stable security definer set search_path = public as $$
declare
  b_int int; b_dil int; b_str int; b_luk int;
  i_int int := 0; i_dil int := 0; i_str int := 0; i_luk int := 0; i_coin int := 0;
  p_int int; p_dil int; p_str int; p_luk int; cap int := _setting_int('stat_alloc_cap', 15);
  sp jsonb; lv int; tot int; per int := _setting_int('stat_pts_per_level', 2);
  k numeric := _setting_int('stat_effect_pct', 50) / 100.0;
  icap int := _setting_int('stat_item_cap', 12); ccap int := _setting_int('stat_coin_cap', 15);
  f_exp int := 0; f_coin int := 0; f_luk int := 0; f_str int := 0; f_int int := 0; bl json;
begin
  b_int := least(10, coalesce((select sum(correct) from game_plays where student_id = p_sid and game = 'quiz'), 0)::int / 8);
  b_dil := least(10, student_metric(p_sid, 'present_count') / 4);
  b_str := least(10, student_metric(p_sid, 'quests_done') / 8);
  b_luk := least(10, student_metric(p_sid, 'gacha_pulls') / 6);
  if coalesce((select is_gm from students where id = p_sid), false) then b_int := 10; b_dil := 10; b_str := 10; b_luk := 10; end if;
  select s.stat_pts, level_for(s.exp) into sp, lv from students s where s.id = p_sid;
  sp := coalesce(sp, '{}'::jsonb);
  p_int := least(cap, coalesce((sp->>'int')::int, 0)); p_dil := least(cap, coalesce((sp->>'dil')::int, 0));
  p_str := least(cap, coalesce((sp->>'str')::int, 0)); p_luk := least(cap, coalesce((sp->>'luk')::int, 0));
  tot := greatest(0, coalesce(lv, 1) - 1) * per;
  select coalesce(sum(d.st_int + case when m.main = 'int' then m.up else 0 end), 0), coalesce(sum(d.st_dil + case when m.main = 'dil' then m.up else 0 end), 0),
         coalesce(sum(d.st_str + case when m.main = 'str' then m.up else 0 end), 0), coalesce(sum(d.st_luk + case when m.main = 'luk' then m.up else 0 end), 0),
         coalesce(sum(d.st_coin), 0)
    into i_int, i_dil, i_str, i_luk, i_coin
    from students s
    cross join lateral jsonb_each_text(s.decor) e
    join decor_items d on d.id = e.value::uuid and d.slot = e.key
    left join student_decor sd on sd.student_id = s.id and sd.item_id = d.id
    cross join lateral (select _item_main(d.st_int, d.st_dil, d.st_str, d.st_luk) main, greatest(coalesce(sd.lvl, 1) - 1, 0) up) m
   where s.id = p_sid;
  i_int := least(i_int, icap); i_dil := least(i_dil, icap); i_str := least(i_str, icap); i_luk := least(i_luk, icap); i_coin := least(i_coin, ccap);
  select coalesce(sum(power) filter (where kind = 'buff_exp'), 0), coalesce(sum(power) filter (where kind = 'buff_coin'), 0),
         coalesce(sum(power) filter (where kind = 'buff_luk'), 0), coalesce(sum(power) filter (where kind = 'buff_str'), 0),
         coalesce(sum(power) filter (where kind = 'buff_int'), 0),
         coalesce(json_agg(json_build_object('kind', kind, 'power', power)), '[]'::json)
    into f_exp, f_coin, f_luk, f_str, f_int, bl
    from student_buffs where student_id = p_sid and day = today_th();
  return json_build_object(
    'int', json_build_object('base', b_int, 'pts', p_int, 'item', i_int, 'total', b_int + p_int + i_int),
    'dil', json_build_object('base', b_dil, 'pts', p_dil, 'item', i_dil, 'total', b_dil + p_dil + i_dil),
    'str', json_build_object('base', b_str, 'pts', p_str, 'item', i_str, 'total', b_str + p_str + i_str),
    'luk', json_build_object('base', b_luk, 'pts', p_luk, 'item', i_luk, 'buff', f_luk, 'total', b_luk + p_luk + i_luk + f_luk),
    'points', json_build_object('total', tot, 'spent', p_int + p_dil + p_str + p_luk, 'left', greatest(0, tot - (p_int + p_dil + p_str + p_luk)),
                                'cap', cap, 'per_level', per, 'reset_cost', _setting_int('stat_reset_cost', 100)),
    'buffs', bl,
    'effects', json_build_object('quiz_exp', floor((b_int + p_int + i_int) / 2.0 * k)::int + f_int,
                                 'exp_pct', round((b_dil + p_dil + i_dil) * k)::int + f_exp,
                                 'boss_pct', round(3 * (b_str + p_str + i_str) * k)::int + f_str,
                                 'rare_pct', round(3 * (b_luk + p_luk + i_luk + f_luk) * k)::int,
                                 'coin_pct', round(i_coin * k)::int + f_coin));
end $$;
revoke execute on function _stats(uuid) from public, anon, authenticated;

-- ---------- กาชา: ลดน้ำหนัก SSR ----------
create or replace function _gacha_pick_luk(p_high boolean, p_luk int, p_sid uuid) returns gacha_items
language plpgsql security definer set search_path = public as $$
declare total numeric; r numeric; acc numeric := 0; it gacha_items%rowtype; last_it gacha_items%rowtype; w numeric;
        rate numeric := _leg_rate(p_sid); n int;
        k numeric := 0.03 * _setting_int('stat_effect_pct', 50) / 100.0;
        sm numeric := least(greatest(_setting_int('gacha_ssr_mult', 20), 0), 100) / 100.0;
begin
  select count(*) into n from gacha_items where active and rarity = 'LEG';
  if n > 0 and random() < rate then
    select * into it from gacha_items where active and rarity = 'LEG' order by random() limit 1;
    return it;
  end if;
  select coalesce(sum(weight * case when rarity in ('SR','SSR') then 1 + k * greatest(p_luk, 0) else 1 end * case when rarity = 'SSR' then sm else 1 end), 0) into total
    from gacha_items where active and rarity <> 'LEG' and (not p_high or rarity in ('SR','SSR'));
  if total = 0 then raise exception 'ยังไม่มีไอเทมในกาชา'; end if;
  r := random() * total;
  for it in select * from gacha_items where active and rarity <> 'LEG' and (not p_high or rarity in ('SR','SSR')) order by id loop
    w := it.weight * case when it.rarity in ('SR','SSR') then 1 + k * greatest(p_luk, 0) else 1 end * case when it.rarity = 'SSR' then sm else 1 end;
    acc := acc + w; last_it := it;
    if r < acc then return it; end if;
  end loop;
  return last_it;
end $$;
revoke execute on function _gacha_pick_luk(boolean, int, uuid) from public, anon, authenticated;

-- ---------- RPC ฝั่งนักเรียน ----------
create or replace function _upg_cost(p_rarity text, p_lvl int) returns json
language sql immutable as $$
  select json_build_object(
    'max', case p_rarity when 'N' then 2 when 'R' then 3 when 'SR' then 4 else 5 end,
    'coins', case p_rarity when 'N' then 40 when 'R' then 70 when 'SR' then 120 when 'SSR' then 200 else 300 end * p_lvl,
    'scrolls', case when p_lvl + 1 <= 3 then 1 else 2 end)
$$;
revoke execute on function _upg_cost(text, int) from public, anon, authenticated;

create or replace function my_items(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); today date := today_th(); res json;
begin
  select json_build_object(
    'coins', (select coins from students where id = sid),
    'items', coalesce((select json_agg(json_build_object('id', c.id, 'key', c.key, 'name', c.name, 'emoji', c.emoji, 'image', c.image, 'rarity', c.rarity, 'kind', c.kind,
              'power', c.power, 'price', c.price, 'descr', c.descr, 'qty', coalesce(si.qty, 0), 'daily_buy', c.daily_buy,
              'bought', coalesce(idl.bought, 0),
              'used_today', c.kind like 'buff\_%' and exists (select 1 from student_buffs b where b.student_id = sid and b.kind = c.kind and b.day = today)) order by c.sort, c.name)
         from consumables c left join student_items si on si.item_id = c.id and si.student_id = sid
         left join item_daily idl on idl.item_id = c.id and idl.student_id = sid and idl.day = today where c.active), '[]'::json),
    'buffs', (_stats(sid)->'buffs'),
    'gear', coalesce((select json_agg(json_build_object('id', d.id, 'name', d.name, 'emoji', d.emoji, 'slot', d.slot, 'rarity', d.rarity, 'lvl', sd.lvl,
              'main', _item_main(d.st_int, d.st_dil, d.st_str, d.st_luk),
              'stats', json_build_object('int', d.st_int, 'dil', d.st_dil, 'str', d.st_str, 'luk', d.st_luk),
              'equipped', (select s.decor->>d.slot = d.id::text from students s where s.id = sid),
              'cost', _upg_cost(d.rarity, sd.lvl)) order by (d.rarity = 'LEG') desc, d.rarity desc, d.name)
         from student_decor sd join decor_items d on d.id = sd.item_id where sd.student_id = sid), '[]'::json)
  ) into res;
  return res;
end $$;

create or replace function buy_item(p_token uuid, p_item uuid, p_n int default 1) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); c consumables%rowtype; today date := today_th(); got int; have int; cost int;
begin
  if p_n is null or p_n < 1 or p_n > 5 then raise exception 'จำนวนไม่ถูกต้อง'; end if;
  select * into c from consumables where id = p_item and active;
  if not found or c.price is null then raise exception 'ไอเทมนี้ไม่ได้วางขาย'; end if;
  perform 1 from students where id = sid for update;
  select coalesce(bought, 0) into got from item_daily where student_id = sid and item_id = c.id and day = today;
  got := coalesce(got, 0);
  if got + p_n > c.daily_buy then raise exception 'วันนี้ซื้อ “%” ได้อีก % ชิ้น (จำกัด % ชิ้น/วัน)', c.name, greatest(c.daily_buy - got, 0), c.daily_buy; end if;
  cost := c.price * p_n;
  select coins into have from students where id = sid;
  if have < cost then raise exception 'เหรียญไม่พอ (ต้องใช้ % เหรียญ)', cost; end if;
  perform award(sid, 0, -cost, 'ซื้อไอเทม: ' || c.name || ' ×' || p_n, null);
  insert into item_daily (student_id, item_id, day, bought) values (sid, c.id, today, p_n)
    on conflict (student_id, item_id, day) do update set bought = item_daily.bought + p_n;
  insert into student_items (student_id, item_id, qty) values (sid, c.id, p_n)
    on conflict (student_id, item_id) do update set qty = student_items.qty + p_n;
  return json_build_object('name', c.name, 'coins', have - cost);
end $$;

create or replace function use_item(p_token uuid, p_item uuid, p_battle uuid default null) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); c consumables%rowtype; q int; b battles%rowtype; add int; today date := today_th(); msg text;
begin
  select * into c from consumables where id = p_item and active;
  if not found then raise exception 'ไม่พบไอเทม'; end if;
  if c.kind = 'scroll' then raise exception 'ม้วนอัปเกรดใช้ที่ส่วนอัปเกรดอุปกรณ์'; end if;
  perform 1 from students where id = sid for update;
  select qty into q from student_items where student_id = sid and item_id = c.id for update;
  if coalesce(q, 0) < 1 then raise exception 'ไม่มีไอเทมนี้ในคลัง'; end if;
  if c.kind like 'buff\_%' then
    if exists (select 1 from student_buffs where student_id = sid and kind = c.kind and day = today) then raise exception 'วันนี้ใช้บัฟชนิดนี้ไปแล้ว (บัฟไม่ซ้อนกัน)'; end if;
    insert into student_buffs (student_id, kind, power, day) values (sid, c.kind, c.power, today);
    msg := c.name || ' มีผลถึงสิ้นวันนี้';
  elsif c.kind = 'heal' then
    if p_battle is null then raise exception 'ยาฟื้นฟูใช้ได้ระหว่างสู้มอนสเตอร์เท่านั้น'; end if;
    select * into b from battles where id = p_battle and student_id = sid and status = 'active' for update;
    if not found then raise exception 'ไม่มีศึกที่กำลังสู้อยู่'; end if;
    if b.potions >= 2 then raise exception 'ศึกนี้ใช้ยาครบ 2 ครั้งแล้ว'; end if;
    if b.p_hp >= b.p_max then raise exception 'HP เต็มอยู่แล้ว'; end if;
    add := ceil(b.p_max * c.power / 100.0);
    update battles set p_hp = least(p_max, p_hp + add), potions = potions + 1 where id = b.id;
    msg := 'ฟื้น HP +' || least(add, b.p_max - b.p_hp);
  elsif c.kind = 'stat_reset' then
    if coalesce((_stats(sid)->'points'->>'spent')::int, 0) = 0 then raise exception 'ยังไม่ได้ใส่แต้มสเตตัส'; end if;
    update students set stat_pts = '{}'::jsonb where id = sid;
    msg := 'ล้างแต้มสเตตัสแล้ว ใส่ใหม่ได้เลย';
  end if;
  update student_items set qty = qty - 1 where student_id = sid and item_id = c.id;
  return json_build_object('name', c.name, 'msg', msg);
end $$;

create or replace function upgrade_decor(p_token uuid, p_item uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); d decor_items%rowtype; sd student_decor%rowtype; cst json; cn int; sc int; have int; scid uuid; sq int;
begin
  perform 1 from students where id = sid for update;
  select * into sd from student_decor where student_id = sid and item_id = p_item for update;
  if not found then raise exception 'ยังไม่มีไอเทมนี้'; end if;
  select * into d from decor_items where id = p_item;
  if _item_main(d.st_int, d.st_dil, d.st_str, d.st_luk) is null then raise exception 'ไอเทมนี้ไม่มีสเตตัสให้อัปเกรด'; end if;
  cst := _upg_cost(d.rarity, sd.lvl);
  if sd.lvl >= (cst->>'max')::int then raise exception 'เลเวลสูงสุดแล้ว (Lv %)', sd.lvl; end if;
  cn := (cst->>'coins')::int; sc := (cst->>'scrolls')::int;
  select id into scid from consumables where kind = 'scroll' order by sort limit 1;
  select qty into sq from student_items where student_id = sid and item_id = scid for update;
  if coalesce(sq, 0) < sc then raise exception 'ม้วนอัปเกรดไม่พอ (ต้องใช้ % ม้วน)', sc; end if;
  select coins into have from students where id = sid;
  if have < cn then raise exception 'เหรียญไม่พอ (ต้องใช้ % เหรียญ)', cn; end if;
  perform award(sid, 0, -cn, 'อัปเกรด ' || d.name || ' → Lv' || (sd.lvl + 1), null);
  update student_items set qty = qty - sc where student_id = sid and item_id = scid;
  update student_decor set lvl = lvl + 1 where student_id = sid and item_id = p_item;
  return json_build_object('name', d.name, 'lvl', sd.lvl + 1, 'main', _item_main(d.st_int, d.st_dil, d.st_str, d.st_luk));
end $$;

create or replace function admin_give_item(p_students uuid[], p_item uuid, p_qty int) returns int
language plpgsql security definer set search_path = public as $$
declare n int := 0; s uuid;
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  if p_qty is null or p_qty < 1 or p_qty > 50 then raise exception 'จำนวนไม่ถูกต้อง'; end if;
  if not exists (select 1 from consumables where id = p_item) then raise exception 'ไม่พบไอเทม'; end if;
  foreach s in array p_students loop
    insert into student_items (student_id, item_id, qty) values (s, p_item, p_qty)
      on conflict (student_id, item_id) do update set qty = student_items.qty + p_qty;
    n := n + 1;
  end loop;
  return n;
end $$;

revoke execute on function my_items(uuid), buy_item(uuid, uuid, int), use_item(uuid, uuid, uuid), upgrade_decor(uuid, uuid) from public;
grant execute on function my_items(uuid), buy_item(uuid, uuid, int), use_item(uuid, uuid, uuid), upgrade_decor(uuid, uuid) to anon, authenticated;
revoke execute on function admin_give_item(uuid[], uuid, int) from public, anon;
grant execute on function admin_give_item(uuid[], uuid, int) to authenticated;

-- ---------- ประกาศ ----------
insert into news_posts (kind, title, summary, body, image, sort, active)
select 'news', 'ไอเทมกดใช้ 🧪 ยา บัฟ ม้วนอัปเกรด + ปรับสมดุล',
  'ซื้อยาบัฟช่วยเก็บ EXP/เหรียญ/โชค · อัปเกรดเลเวลของสวมใส่ · SSR หายากขึ้น',
  E'🧪 แท็บใหม่ "ไอเทม" เปิดแล้ว!\n\n💊 ยาบัฟ (มีผลถึงสิ้นวัน ชนิดละ 1 ครั้ง/วัน)\n• 🧪 EXP +15% • 💰 เหรียญ +20% • 🍀 โชค +4 • ⚔️ ดาเมจบอส +15% • 🧠 EXP ควิซ +2\n💚 ยาฟื้นฟู HP ใช้ในศึกมอนสเตอร์ (2 ครั้ง/ศึก)\n🔄 ตั๋วล้างแต้มสเตตัส\n📜 ม้วนอัปเกรด ใช้อัปเกรดเลเวลของสวมใส่ ทุกเลเวล +1 สเตตัสหลักของไอเทมนั้น\n\n⚖️ ปรับสมดุลสเตตัสไอเทมไม่ให้แรงเกินไป (มีเพดานต่อชิ้นและเพดานรวม)\n🎰 ลดอัตราออก SSR ในกาชาลงอีก (จากราว 14% เหลือราว 3%)\n\nแวะไปดูที่แท็บ 🧪 ไอเทม ได้เลย',
  'assets/news/consumables.jpg', 46, true
where not exists (select 1 from news_posts where title like 'ไอเทมกดใช้%');
-- 67: บัฟมีเวลาจำกัด (นาที) แทนถึงสิ้นวัน + ส่ง lv ของอุปกรณ์ให้หน้าจอ (v2.01) · รันซ้ำได้
--  · ระยะเวลาต่อไอเทมอยู่ที่ consumables.minutes (ค่าเริ่มต้น: EXP/เหรียญ 60 · โชค 30 · ดาเมจบอส/ปัญญา 45) ครูแก้ได้ในแอดมิน
--  · บัฟชนิดเดียวกันใช้ซ้อนไม่ได้ขณะยังไม่หมดเวลา (หมดแล้วใช้ใหม่ได้)
alter table consumables add column if not exists minutes int not null default 60 check (minutes between 5 and 1440);
alter table student_buffs add column if not exists expires_at timestamptz not null default now();
update consumables set minutes = 60 where key in ('p_exp', 'p_coin');
update consumables set minutes = 30 where key = 'p_luck';
update consumables set minutes = 45 where key in ('p_str', 'p_int');
update consumables set descr = replace(descr, 'ถึงสิ้นวัน', 'นาน ' || minutes || ' นาที') where kind like 'buff\_%' and descr like '%ถึงสิ้นวัน%';

-- _stats: นับเฉพาะบัฟที่ยังไม่หมดเวลา
do $$ declare d text; n text; begin
  d := pg_get_functiondef('_stats(uuid)'::regprocedure);
  if d like '%day = today_th()%' then
    n := replace(d, 'where student_id = p_sid and day = today_th()', 'where student_id = p_sid and expires_at > now()');
    n := replace(n, 'json_build_object(''kind'', kind, ''power'', power)', 'json_build_object(''kind'', kind, ''power'', power, ''until'', expires_at)');
    if n = d or n not like '%expires_at > now()%' then raise exception '_stats: ไม่พบข้อความที่ต้องแก้ (ต้องรัน 66 ก่อน)'; end if;
    execute n;
  end if;
end $$;
revoke execute on function _stats(uuid) from public, anon, authenticated;

-- ใช้ไอเทม
create or replace function use_item(p_token uuid, p_item uuid, p_battle uuid default null) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); c consumables%rowtype; q int; b battles%rowtype; add int; msg text;
begin
  select * into c from consumables where id = p_item and active;
  if not found then raise exception 'ไม่พบไอเทม'; end if;
  if c.kind = 'scroll' then raise exception 'ม้วนอัปเกรด: เลือกอุปกรณ์ที่ต้องการอัปเกรดในหน้าไอเทม'; end if;
  perform 1 from students where id = sid for update;
  select qty into q from student_items where student_id = sid and item_id = c.id for update;
  if coalesce(q, 0) < 1 then raise exception 'ไม่มีไอเทมนี้ในคลัง'; end if;
  if c.kind like 'buff\_%' then
    if exists (select 1 from student_buffs where student_id = sid and kind = c.kind and expires_at > now()) then raise exception 'บัฟชนิดนี้ยังมีผลอยู่ (ซ้อนกันไม่ได้)'; end if;
    insert into student_buffs (student_id, kind, power, day, expires_at) values (sid, c.kind, c.power, today_th(), now() + make_interval(mins => c.minutes))
      on conflict (student_id, kind) do update set power = excluded.power, day = excluded.day, expires_at = excluded.expires_at;
    msg := c.name || ' มีผล ' || c.minutes || ' นาที';
  elsif c.kind = 'heal' then
    if p_battle is null then raise exception 'ยาฟื้นฟูใช้ได้ระหว่างสู้มอนสเตอร์เท่านั้น'; end if;
    select * into b from battles where id = p_battle and student_id = sid and status = 'active' for update;
    if not found then raise exception 'ไม่มีศึกที่กำลังสู้อยู่'; end if;
    if b.potions >= 2 then raise exception 'ศึกนี้ใช้ยาครบ 2 ครั้งแล้ว'; end if;
    if b.p_hp >= b.p_max then raise exception 'HP เต็มอยู่แล้ว'; end if;
    add := ceil(b.p_max * c.power / 100.0);
    update battles set p_hp = least(p_max, p_hp + add), potions = potions + 1 where id = b.id;
    msg := 'ฟื้น HP +' || least(add, b.p_max - b.p_hp);
  elsif c.kind = 'stat_reset' then
    if coalesce((_stats(sid)->'points'->>'spent')::int, 0) = 0 then raise exception 'ยังไม่ได้ใส่แต้มสเตตัส'; end if;
    update students set stat_pts = '{}'::jsonb where id = sid;
    msg := 'ล้างแต้มสเตตัสแล้ว ใส่ใหม่ได้เลย';
  end if;
  update student_items set qty = qty - 1 where student_id = sid and item_id = c.id;
  return json_build_object('name', c.name, 'msg', msg);
end $$;

-- รายการไอเทม/อุปกรณ์ของฉัน
create or replace function my_items(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); today date := today_th(); res json;
begin
  select json_build_object(
    'coins', (select coins from students where id = sid),
    'items', coalesce((select json_agg(json_build_object('id', c.id, 'key', c.key, 'name', c.name, 'emoji', c.emoji, 'image', c.image, 'rarity', c.rarity, 'kind', c.kind,
              'power', c.power, 'price', c.price, 'descr', c.descr, 'minutes', c.minutes, 'qty', coalesce(si.qty, 0), 'daily_buy', c.daily_buy,
              'bought', coalesce(idl.bought, 0),
              'active_until', (select b.expires_at from student_buffs b where b.student_id = sid and b.kind = c.kind and b.expires_at > now())) order by c.sort, c.name)
         from consumables c left join student_items si on si.item_id = c.id and si.student_id = sid
         left join item_daily idl on idl.item_id = c.id and idl.student_id = sid and idl.day = today where c.active), '[]'::json),
    'buffs', (_stats(sid)->'buffs'),
    'gear', coalesce((select json_agg(json_build_object('id', d.id, 'name', d.name, 'emoji', d.emoji, 'image', d.image, 'slot', d.slot, 'rarity', d.rarity, 'lvl', sd.lvl,
              'ability', d.ability, 'coin', d.st_coin,
              'main', _item_main(d.st_int, d.st_dil, d.st_str, d.st_luk),
              'stats', json_build_object('int', d.st_int, 'dil', d.st_dil, 'str', d.st_str, 'luk', d.st_luk),
              'equipped', (select s.decor->>d.slot = d.id::text from students s where s.id = sid),
              'cost', _upg_cost(d.rarity, sd.lvl)) order by (d.rarity = 'LEG') desc, d.rarity desc, d.name)
         from student_decor sd join decor_items d on d.id = sd.item_id where sd.student_id = sid), '[]'::json)
  ) into res;
  return res;
end $$;

-- _decor_of: ส่ง lv ของอุปกรณ์ที่สวมอยู่
create or replace function _decor_of(p_sid uuid) returns json
language sql stable security definer set search_path = public as $$
  select (coalesce((select json_object_agg(d.slot, json_build_object('id', d.id, 'key', d.key, 'color', d.color,
           'emoji', d.emoji, 'name', d.name, 'rarity', d.rarity, 'image', d.image, 'lvl', coalesce(sd.lvl, 1)))
    from students s
    cross join lateral jsonb_each_text(s.decor) e
    join decor_items d on d.id = e.value::uuid and d.slot = e.key
    left join student_decor sd on sd.student_id = s.id and sd.item_id = d.id
   where s.id = p_sid), '{}'::json)::jsonb
   || jsonb_build_object('gender', (select gender from students where id = p_sid)))::json
$$;
revoke execute on function _decor_of(uuid) from public, anon, authenticated;
revoke execute on function my_items(uuid), use_item(uuid, uuid, uuid) from public;
grant execute on function my_items(uuid), use_item(uuid, uuid, uuid) to anon, authenticated;

update news_posts set body = replace(body, 'บัฟมีผลถึงสิ้นวัน ชนิดละ 1 ครั้ง/วัน', 'บัฟมีผลตามเวลา (30–60 นาที)') where title like 'ไอเทมกดใช้%';
-- 68: ของขวัญเพื่อน + คะแนนความสัมพันธ์ + เลือกความสัมพันธ์ (v2.02) · รันซ้ำได้
--  · ซื้อ-ส่งของขวัญให้เพื่อนห้องเดียวกันด้วยเหรียญ → คะแนนความสัมพันธ์ (RP) ของคู่นั้นเพิ่ม
--  · RP ถึงเกณฑ์ → ปลดล็อกชนิดความสัมพันธ์ (เพื่อน / เพื่อนสนิท / คู่หูติว ฯลฯ) · ฝ่ายหนึ่งเสนอ อีกฝ่ายกดยอมรับ
--  · กันโกง: ของขวัญหักเหรียญจริง · RP ต่อคู่ต่อวันมีเพดาน (gift_pair_cap) · ส่งได้ไม่เกิน gift_daily_limit ชิ้น/วัน · ส่งได้เฉพาะเพื่อนในห้องเดียวกัน
create table if not exists gift_items (
  id uuid primary key default gen_random_uuid(),
  key text unique not null, name text not null, emoji text not null default '🎁',
  rarity text not null default 'N' check (rarity in ('N','R','SR','SSR')),
  price int not null check (price >= 0), points int not null check (points > 0),
  descr text, sort int not null default 0, active boolean not null default true
);
create table if not exists relation_types (
  key text primary key, name text not null, emoji text not null default '🤝',
  need_rp int not null check (need_rp >= 0), sort int not null default 0, active boolean not null default true
);
create table if not exists friendships (
  a uuid not null references students(id) on delete cascade, b uuid not null references students(id) on delete cascade,
  rp int not null default 0, rel text, pend_rel text, pend_by uuid,
  day date, day_rp int not null default 0, updated_at timestamptz not null default now(),
  primary key (a, b), check (a < b)
);
create table if not exists gift_log (
  id uuid primary key default gen_random_uuid(),
  from_id uuid not null references students(id) on delete cascade, to_id uuid not null references students(id) on delete cascade,
  name text not null, emoji text not null, points int not null, msg text,
  at timestamptz not null default now(), seen boolean not null default false
);
create index if not exists gift_log_to on gift_log (to_id, at desc);
create index if not exists gift_log_from on gift_log (from_id, at desc);
do $$ declare t text; begin
  foreach t in array array['gift_items', 'relation_types', 'friendships', 'gift_log'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists teacher_all on public.%I', t);
    execute format('create policy teacher_all on public.%I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;
insert into app_settings (key, value) values ('gift_daily_limit', '5'), ('gift_pair_cap', '40') on conflict (key) do nothing;

insert into gift_items (key, name, emoji, rarity, price, points, descr, sort)
select v.* from (values
  ('candy',  'ลูกอมน้ำใจ',        '🍬', 'N',  15,  3, 'ของขวัญชิ้นเล็กๆ ส่งความรู้สึกดีๆ', 10),
  ('choco',  'ช็อกโกแลตแท่ง',     '🍫', 'N',  30,  7, 'หวานนิดๆ เพิ่มมิตรภาพ', 20),
  ('flower', 'ช่อดอกไม้ทดลอง',    '🌸', 'R',  50, 12, 'ดอกไม้จากห้องแล็บ หอมไม่เป็นพิษ', 30),
  ('bear',   'ตุ๊กตาหมีนักเคมี',   '🧸', 'R',  80, 20, 'กอดแล้วสบายใจ เหมาะกับเพื่อนสนิท', 40),
  ('crystal','ผลึกแห่งมิตรภาพ',   '💎', 'SR', 150, 38, 'ผลึกหายาก เปล่งประกายเมื่อมีเพื่อนแท้', 50)
) v(key, name, emoji, rarity, price, points, descr, sort)
where not exists (select 1 from gift_items g where g.key = v.key);

insert into relation_types (key, name, emoji, need_rp, sort)
select v.* from (values
  ('friend',  'เพื่อน',              '🤝',  30, 10),
  ('bestie',  'เพื่อนสนิท',           '😎',  80, 20),
  ('study',   'คู่หูติวเข้ม',         '📚',  80, 21),
  ('rival',   'คู่แข่งสุดซี้',        '⚔️',  80, 22),
  ('bff',     'เพื่อนซี้',            '🫶', 160, 30),
  ('mischief','คู่หูตัวแสบ',          '😈', 160, 31),
  ('lab',     'คู่หูห้องแล็บ',        '🧪', 160, 32),
  ('forever', 'เพื่อนแท้ตลอดกาล',    '💎', 300, 40),
  ('legend',  'คู่หูในตำนาน',         '👑', 300, 41),
  ('family',  'พี่น้องห้องเคมี',      '🧬', 300, 42)
) v(key, name, emoji, need_rp, sort)
where not exists (select 1 from relation_types r where r.key = v.key);

-- ---------- ตัวช่วย ----------
create or replace function _rel_pair(x uuid, y uuid) returns uuid[]
language sql immutable as $$ select case when x < y then array[x, y] else array[y, x] end $$;

create or replace function _rel_home(p_sid uuid) returns json
language sql stable security definer set search_path = public as $$
  select json_build_object(
    'rels', coalesce((select json_agg(json_build_object('no', o.no, 'name', o.name, 'rp', f.rp, 'rel', f.rel, 'rel_name', t.name, 'rel_emoji', t.emoji) order by f.rp desc)
        from friendships f join students o on o.id = case when f.a = p_sid then f.b else f.a end left join relation_types t on t.key = f.rel
       where (f.a = p_sid or f.b = p_sid) and f.rel is not null), '[]'::json),
    'incoming', coalesce((select json_agg(json_build_object('no', o.no, 'name', o.name, 'rel', f.pend_rel, 'rel_name', t.name, 'rel_emoji', t.emoji))
        from friendships f join students o on o.id = f.pend_by join relation_types t on t.key = f.pend_rel
       where (f.a = p_sid or f.b = p_sid) and f.pend_by is not null and f.pend_by <> p_sid), '[]'::json),
    'new_gifts', (select count(*) from gift_log where to_id = p_sid and not seen))
$$;
revoke execute on function _rel_pair(uuid, uuid), _rel_home(uuid) from public, anon, authenticated;

-- student_extras: เพิ่ม relations (ครอบฟังก์ชันเดิม)
do $$ begin
  if exists (select 1 from pg_proc where proname = 'student_extras' and pronamespace = 'public'::regnamespace)
     and not exists (select 1 from pg_proc where proname = '_student_extras' and pronamespace = 'public'::regnamespace) then
    alter function student_extras(uuid) rename to _student_extras;
  end if;
end $$;
revoke execute on function _student_extras(uuid) from public, anon, authenticated;
create or replace function student_extras(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare r jsonb;
begin
  r := _student_extras(p_token)::jsonb;
  return (r || jsonb_build_object('relations', _rel_home(_sid(p_token))))::json;
end $$;
revoke execute on function student_extras(uuid) from public;
grant execute on function student_extras(uuid) to anon, authenticated;

-- ---------- RPC นักเรียน ----------
create or replace function friend_list(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cid uuid; today date := today_th(); res json; cap int := _setting_int('gift_pair_cap', 40);
begin
  select class_id into cid from students where id = sid;
  res := json_build_object(
    'coins', (select coins from students where id = sid),
    'gifts', coalesce((select json_agg(json_build_object('id', g.id, 'name', g.name, 'emoji', g.emoji, 'rarity', g.rarity, 'price', g.price, 'points', g.points, 'descr', g.descr) order by g.sort, g.price) from gift_items g where g.active), '[]'::json),
    'types', coalesce((select json_agg(json_build_object('key', t.key, 'name', t.name, 'emoji', t.emoji, 'need_rp', t.need_rp) order by t.need_rp, t.sort) from relation_types t where t.active), '[]'::json),
    'sent_today', (select count(*) from gift_log where from_id = sid and (at at time zone 'Asia/Bangkok')::date = today),
    'send_limit', _setting_int('gift_daily_limit', 5), 'pair_cap', cap,
    'mates', coalesce((select json_agg(json_build_object('no', o.no, 'name', o.name, 'rp', coalesce(f.rp, 0), 'rel', f.rel, 'rel_name', t.name, 'rel_emoji', t.emoji,
          'day_left', greatest(0, cap - case when f.day = today then f.day_rp else 0 end),
          'pend', case when f.pend_rel is null then null else json_build_object('rel', f.pend_rel, 'name', pt.name, 'emoji', pt.emoji, 'by_me', f.pend_by = sid) end) order by o.no)
        from students o left join friendships f on f.a = (_rel_pair(sid, o.id))[1] and f.b = (_rel_pair(sid, o.id))[2]
        left join relation_types t on t.key = f.rel left join relation_types pt on pt.key = f.pend_rel
       where o.class_id = cid and o.id <> sid), '[]'::json),
    'inbox', coalesce((select json_agg(x) from (select json_build_object('from', o.name, 'emoji', l.emoji, 'name', l.name, 'msg', l.msg, 'points', l.points, 'at', l.at, 'seen', l.seen) x
        from gift_log l join students o on o.id = l.from_id where l.to_id = sid order by l.at desc limit 12) z), '[]'::json));
  update gift_log set seen = true where to_id = sid and not seen;
  return res;
end $$;

create or replace function gift_send(p_token uuid, p_to_no int, p_gift uuid, p_msg text default null) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); me students%rowtype; o students%rowtype; g gift_items%rowtype; pr uuid[]; f friendships%rowtype; today date := today_th();
        cap int := _setting_int('gift_pair_cap', 40); lim int := _setting_int('gift_daily_limit', 5); sent int; used int; m text;
begin
  select * into me from students where id = sid for update;
  select * into o from students where class_id = me.class_id and no = p_to_no;
  if not found or o.id = sid then raise exception 'เลือกเพื่อนในห้องเดียวกันเท่านั้น'; end if;
  select * into g from gift_items where id = p_gift and active;
  if not found then raise exception 'ไม่พบของขวัญ'; end if;
  select count(*) into sent from gift_log where from_id = sid and (at at time zone 'Asia/Bangkok')::date = today;
  if sent >= lim then raise exception 'วันนี้ส่งของขวัญครบ % ชิ้นแล้ว พรุ่งนี้ส่งใหม่ได้', lim; end if;
  m := nullif(left(btrim(coalesce(p_msg, '')), 60), '');
  pr := _rel_pair(sid, o.id);
  insert into friendships (a, b) values (pr[1], pr[2]) on conflict (a, b) do nothing;
  select * into f from friendships where a = pr[1] and b = pr[2] for update;
  used := case when f.day = today then f.day_rp else 0 end;
  if used + g.points > cap then raise exception 'วันนี้ให้คะแนนมิตรภาพกับเพื่อนคนนี้ได้อีกแค่ % แต้ม (ลองของขวัญชิ้นเล็กลงหรือพรุ่งนี้)', greatest(cap - used, 0); end if;
  if me.coins < g.price then raise exception 'เหรียญไม่พอ (ต้องใช้ % เหรียญ)', g.price; end if;
  perform award(sid, 0, -g.price, 'ส่งของขวัญให้เพื่อน: ' || g.name, null);
  update friendships set rp = rp + g.points, day = today, day_rp = used + g.points, updated_at = now() where a = pr[1] and b = pr[2];
  insert into gift_log (from_id, to_id, name, emoji, points, msg) values (sid, o.id, g.name, g.emoji, g.points, m);
  return json_build_object('to', o.name, 'gift', g.name, 'points', g.points, 'rp', f.rp + g.points);
end $$;

create or replace function rel_propose(p_token uuid, p_to_no int, p_rel text) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); me students%rowtype; o students%rowtype; t relation_types%rowtype; pr uuid[]; f friendships%rowtype;
begin
  select * into me from students where id = sid;
  select * into o from students where class_id = me.class_id and no = p_to_no and id <> sid;
  if not found then raise exception 'เลือกเพื่อนในห้องเดียวกันเท่านั้น'; end if;
  select * into t from relation_types where key = p_rel and active;
  if not found then raise exception 'ไม่พบชนิดความสัมพันธ์'; end if;
  pr := _rel_pair(sid, o.id);
  select * into f from friendships where a = pr[1] and b = pr[2] for update;
  if not found or f.rp < t.need_rp then raise exception 'คะแนนมิตรภาพยังไม่ถึง % แต้ม', t.need_rp; end if;
  if f.rel = t.key then raise exception 'เป็นความสัมพันธ์นี้อยู่แล้ว'; end if;
  update friendships set pend_rel = t.key, pend_by = sid, updated_at = now() where a = pr[1] and b = pr[2];
  return json_build_object('to', o.name, 'rel', t.name);
end $$;

create or replace function rel_respond(p_token uuid, p_from_no int, p_accept boolean) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); me students%rowtype; o students%rowtype; pr uuid[]; f friendships%rowtype;
begin
  select * into me from students where id = sid;
  select * into o from students where class_id = me.class_id and no = p_from_no and id <> sid;
  if not found then raise exception 'ไม่พบเพื่อน'; end if;
  pr := _rel_pair(sid, o.id);
  select * into f from friendships where a = pr[1] and b = pr[2] for update;
  if not found or f.pend_rel is null or f.pend_by is distinct from o.id then raise exception 'ไม่มีคำขอจากเพื่อนคนนี้'; end if;
  if p_accept then update friendships set rel = pend_rel, pend_rel = null, pend_by = null, updated_at = now() where a = pr[1] and b = pr[2];
  else update friendships set pend_rel = null, pend_by = null, updated_at = now() where a = pr[1] and b = pr[2]; end if;
  return json_build_object('from', o.name, 'accepted', p_accept);
end $$;

-- ยกเลิกคำขอของตัวเอง หรือเลิกความสัมพันธ์ (คะแนนยังอยู่)
create or replace function rel_end(p_token uuid, p_no int) returns void
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); me students%rowtype; o students%rowtype; pr uuid[];
begin
  select * into me from students where id = sid;
  select * into o from students where class_id = me.class_id and no = p_no and id <> sid;
  if not found then raise exception 'ไม่พบเพื่อน'; end if;
  pr := _rel_pair(sid, o.id);
  update friendships set rel = case when pend_by = sid then rel else null end, pend_rel = null, pend_by = null, updated_at = now() where a = pr[1] and b = pr[2];
end $$;

create or replace function admin_gift_log(p_limit int default 60) returns json
language plpgsql security definer set search_path = public as $$
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  return coalesce((select json_agg(x) from (select json_build_object('at', l.at, 'class', c.name, 'from', f.name, 'to', t.name, 'gift', l.emoji || ' ' || l.name, 'points', l.points, 'msg', l.msg) x
      from gift_log l join students f on f.id = l.from_id join students t on t.id = l.to_id left join classes c on c.id = f.class_id order by l.at desc limit least(greatest(p_limit, 1), 300)) z), '[]'::json);
end $$;

revoke execute on function friend_list(uuid), gift_send(uuid, int, uuid, text), rel_propose(uuid, int, text), rel_respond(uuid, int, boolean), rel_end(uuid, int) from public;
grant execute on function friend_list(uuid), gift_send(uuid, int, uuid, text), rel_propose(uuid, int, text), rel_respond(uuid, int, boolean), rel_end(uuid, int) to anon, authenticated;
revoke execute on function admin_gift_log(int) from public, anon;
grant execute on function admin_gift_log(int) to authenticated;
-- 69: ด่านบอสเลื่อนแรงค์ — EXP ถึงเกณฑ์แรงค์หลักแล้ว ต้องชนะบอสด่านนั้นก่อนจึงเลื่อนแรงค์
-- ต้องรันหลัง 17 (battle), 21 (celebrate), 61 (guild_avatars) และ 68
-- กติกา: EXP ไม่หาย · แพ้/หนี = สอบใหม่ได้วันถัดไป (นับ 1 ครั้งต่อด่านต่อวัน) · นักเรียนที่ถึงแรงค์อยู่แล้วตอนรันไฟล์นี้ได้สิทธิ์ผ่านด่านให้โดยอัตโนมัติ

alter table monsters add column if not exists trial_rank text;   -- รหัสแรงค์ใน ch_ranks ที่มอนนี้เป็นบอสด่านเลื่อนแรงค์
alter table battles  add column if not exists trial_rank text;

create table if not exists rank_trial_pass (
  student_id uuid not null references students(id) on delete cascade,
  rank_key text not null,
  passed_at timestamptz not null default now(),
  primary key (student_id, rank_key)
);
alter table rank_trial_pass enable row level security;
drop policy if exists teacher_all on rank_trial_pass;
create policy teacher_all on rank_trial_pass for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on rank_trial_pass from anon;
grant select, insert, update, delete on rank_trial_pass to authenticated;

insert into app_settings (key, value) values ('rank_trial_on', '1'), ('rank_trial_coins', '50') on conflict (key) do nothing;

-- บอสด่านเลื่อนแรงค์ (Silver ขึ้นไป · Bronze เข้าฟรี) ครูแก้ HP/พลัง หรือปิด active เพื่อยกเลิกด่านนั้นได้ที่แท็บมอนสเตอร์
insert into monsters (key, name, emoji, level, hp, atk, exp, coins, atk_name, descr, sort, active, arena, trial_rank) values
 ('trial_silver',      'ผู้พิทักษ์ธาตุเงิน',     '🥈', 3, 170, 14, 0, 0, 'ประกายเงินวาบ',   'ด่านเลื่อนแรงค์ Silver',      900, true, 'lab', 'silver'),
 ('trial_gold',        'ราชันทองคำเรืองแสง',    '🥇', 4, 230, 16, 0, 0, 'คลื่นทองแผดเผา',  'ด่านเลื่อนแรงค์ Gold',        901, true, 'lab', 'gold'),
 ('trial_platinum',    'อสูรแพลทินัมไร้ปฏิกิริยา','⚪', 4, 310, 18, 0, 0, 'เกราะเฉื่อยทลาย',  'ด่านเลื่อนแรงค์ Platinum',    902, true, 'lab', 'platinum'),
 ('trial_emerald',     'มรกตพิษมรณะ',           '🟢', 4, 390, 20, 0, 0, 'ผลึกเขียวทิ่มแทง', 'ด่านเลื่อนแรงค์ Emerald',     903, true, 'lab', 'emerald'),
 ('trial_diamond',     'ราชาเพชรพันธะโควาเลนต์','💎', 5, 490, 22, 0, 0, 'แสงหักเหมรณะ',    'ด่านเลื่อนแรงค์ Diamond',     904, true, 'lab', 'diamond'),
 ('trial_master',      'จอมปราชญ์ตารางธาตุ',    '🧙', 5, 610, 24, 0, 0, 'สมการสะท้านฟ้า',  'ด่านเลื่อนแรงค์ Master',      905, true, 'lab', 'master'),
 ('trial_grandmaster', 'มหาอสูรปฏิกิริยาลูกโซ่', '☢️', 5, 770, 27, 0, 0, 'ระเบิดลูกโซ่',     'ด่านเลื่อนแรงค์ Grandmaster', 906, true, 'lab', 'grandmaster'),
 ('trial_challenger',  'ราชันย์แห่งเคมีนิรันดร์','👑', 5, 960, 30, 0, 0, 'พิโรธนิรันดร์',    'ด่านสุดท้าย Challenger',      907, true, 'lab', 'challenger')
on conflict (key) do nothing;

-- ---------- แกนกลาง ----------
-- รหัสแรงค์ที่ยังขวางอยู่ (EXP ถึงเกณฑ์แต่ยังไม่ผ่านด่าน) · null = ไม่มี
create or replace function _rank_gate(p_sid uuid, p_exp int) returns text
language sql stable security definer set search_path = public as $$
  select r.key from ch_ranks r
   where _setting_int('rank_trial_on', 1) = 1 and r.sort > 1 and r.min_exp <= greatest(p_exp, 0)
     and exists (select 1 from monsters m where m.trial_rank = r.key and m.active)
     and not exists (select 1 from rank_trial_pass p where p.student_id = p_sid and p.rank_key = r.key)
   order by r.sort limit 1
$$;
-- EXP ที่ใช้คำนวณแรงค์ (ถูกกั้นไว้ก่อนเกณฑ์ของด่านที่ยังไม่ผ่าน)
create or replace function _rank_exp(p_sid uuid, p_exp int) returns int
language sql stable security definer set search_path = public as $$
  select coalesce((select least(greatest(p_exp, 0), r.min_exp - 1) from ch_ranks r where r.key = _rank_gate(p_sid, p_exp)), p_exp)
$$;
-- rank_info + สถานะล็อกด่าน
create or replace function _rank_info_s(p_sid uuid, p_exp int) returns json
language plpgsql stable security definer set search_path = public as $$
declare g text := _rank_gate(p_sid, p_exp); gr ch_ranks%rowtype; j jsonb;
begin
  j := rank_info(case when g is null then p_exp else _rank_exp(p_sid, p_exp) end)::jsonb;
  if g is not null then
    select * into gr from ch_ranks where key = g;
    j := j || jsonb_build_object('locked', true, 'gate_key', gr.key, 'gate_name', gr.name, 'gate_image', gr.image, 'gate_exp', gr.min_exp);
  end if;
  return j::json;
end $$;
revoke execute on function _rank_gate(uuid, int), _rank_exp(uuid, int), _rank_info_s(uuid, int) from public, anon, authenticated;

-- ---------- ย้ายทุกจุดที่เรียก rank_info(x.exp) ไปใช้ตัวที่คิดด่านแล้ว ----------
do $$
declare f record; def text; n int := 0;
begin
  for f in select p.oid, p.proname from pg_proc p where p.pronamespace = 'public'::regnamespace and p.prokind = 'f'
            and p.proname not in ('rank_info', '_rank_info_s', '_rank_exp', '_rank_gate')
            and pg_get_functiondef(p.oid) ~ 'rank_info\(\w+\.exp\)' loop
    def := pg_get_functiondef(f.oid);
    def := regexp_replace(def, 'rank_info\((\w+)\.exp\)', '_rank_info_s(\1.id, \1.exp)', 'g');
    execute def; n := n + 1;
  end loop;
  if n = 0 and not exists (select 1 from pg_proc where proname = 'trg_cel_rank' and pg_get_functiondef(oid) like '%_rank_info_s%') then
    raise exception 'ไม่พบฟังก์ชันที่ต้องแก้ rank_info (ต้องรันไฟล์ก่อนหน้าให้ครบ)';
  end if;
end $$;

-- ซ่อนบอสด่านจากรายการมอนสเตอร์ปกติ + กันเริ่มสู้บอสด่านตรงๆ
do $$
declare d text;
begin
  select pg_get_functiondef('battle_status(uuid)'::regprocedure) into d;
  if d not like '%trial_rank%' then
    d := replace(d, 'from monsters m where m.active', 'from monsters m where m.active and m.trial_rank is null');
    if d not like '%m.trial_rank is null%' then raise exception 'แก้ battle_status ไม่สำเร็จ'; end if;
    execute d;
  end if;
  select pg_get_functiondef('battle_start(uuid,uuid)'::regprocedure) into d;
  if d not like '%trial_rank%' then
    d := replace(d, 'select * into m from monsters where id = p_monster and active;',
                    'select * into m from monsters where id = p_monster and active and (trial_rank is null or current_setting(''app.trial_ok'', true) = ''1'');');
    if d not like '%app.trial_ok%' then raise exception 'แก้ battle_start ไม่สำเร็จ'; end if;
    execute d;
  end if;
end $$;

-- ---------- ผ่านด่านเมื่อชนะบอส ----------
create or replace function trg_rank_trial() returns trigger
language plpgsql security definer set search_path = public as $$
declare st students%rowtype; gr ch_ranks%rowtype; ri json; c int := _setting_int('rank_trial_coins', 50);
begin
  if new.status = 'won' and old.status is distinct from 'won' and new.trial_rank is not null then
    insert into rank_trial_pass (student_id, rank_key) values (new.student_id, new.trial_rank) on conflict do nothing;
    if found then
      select * into gr from ch_ranks where key = new.trial_rank;
      if c > 0 then perform award(new.student_id, 0, c, 'ผ่านด่านเลื่อนแรงค์ ' || gr.name || ' 🎖️', 'trial:' || new.trial_rank); end if;
      select * into st from students where id = new.student_id;
      ri := _rank_info_s(st.id, st.exp);
      if _setting_int('celebrate_enabled', 1) = 1 then
        insert into celebrations (class_id, student_id, kind, title, image) values (st.class_id, st.id, 'rank', ri->>'name', ri->>'image');
      end if;
    end if;
  end if;
  return new;
end $$;
drop trigger if exists trial_win on battles;
create trigger trial_win after update of status on battles for each row execute function trg_rank_trial();
revoke execute on function trg_rank_trial() from public, anon, authenticated;

-- ---------- RPC นักเรียน ----------
create or replace function rank_trial_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); s students%rowtype; g text; r ch_ranks%rowtype; m monsters%rowtype; tried boolean := false; act text;
begin
  select * into s from students where id = sid;
  g := _rank_gate(sid, s.exp);
  select b.trial_rank into act from battles b where b.student_id = sid and b.status = 'active' and b.trial_rank is not null limit 1;
  if g is null then return json_build_object('gate', null, 'active_trial', act); end if;
  select * into r from ch_ranks where key = g;
  select * into m from monsters where trial_rank = g and active order by sort limit 1;
  select exists (select 1 from battles b where b.student_id = sid and b.trial_rank = g and b.play_date = today_th()) into tried;
  return json_build_object('gate', json_build_object('key', r.key, 'name', r.name, 'image', r.image, 'min_exp', r.min_exp),
    'exp', s.exp, 'extra', greatest(0, s.exp - r.min_exp + 1), 'reward_coins', _setting_int('rank_trial_coins', 50),
    'boss', json_build_object('id', m.id, 'name', m.name, 'emoji', m.emoji, 'image', m.image, 'level', m.level, 'hp', m.hp, 'atk', m.atk, 'descr', m.descr),
    'tried_today', tried and act is null, 'can_start', (not tried) or act is not null, 'active_trial', act);
end $$;

create or replace function rank_trial_start(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); s students%rowtype; g text; m monsters%rowtype; act uuid; r json; bid uuid;
begin
  select * into s from students where id = sid;
  select b.id into act from battles b where b.student_id = sid and b.status = 'active' and b.trial_rank is not null limit 1;
  if act is not null then return _battle_view(act); end if;
  g := _rank_gate(sid, s.exp);
  if g is null then raise exception 'ตอนนี้ไม่มีด่านเลื่อนแรงค์ที่ต้องสอบ'; end if;
  if exists (select 1 from battles b where b.student_id = sid and b.trial_rank = g and b.play_date = today_th()) then
    raise exception 'วันนี้สอบด่านนี้ไปแล้ว พรุ่งนี้มาลองใหม่ได้ (EXP ของคุณไม่หาย)';
  end if;
  select * into m from monsters where trial_rank = g and active order by sort limit 1;
  perform set_config('app.trial_ok', '1', true);
  r := battle_start(p_token, m.id);
  perform set_config('app.trial_ok', '0', true);
  bid := (r->>'id')::uuid;
  update battles set trial_rank = g, rewarded = false where id = bid;
  return _battle_view(bid);
end $$;

revoke execute on function rank_trial_status(uuid), rank_trial_start(uuid) from public;
grant execute on function rank_trial_status(uuid), rank_trial_start(uuid) to anon, authenticated;

-- ครู: ให้ผ่านด่าน/ยกเลิกสิทธิ์ผ่านด่านรายคน
create or replace function admin_rank_trial_pass(p_student uuid, p_rank text, p_pass boolean default true) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not is_teacher() then raise exception 'เฉพาะครู'; end if;
  if p_pass then insert into rank_trial_pass (student_id, rank_key) values (p_student, p_rank) on conflict do nothing;
  else delete from rank_trial_pass where student_id = p_student and rank_key = p_rank; end if;
end $$;
revoke execute on function admin_rank_trial_pass(uuid, text, boolean) from public, anon;
grant execute on function admin_rank_trial_pass(uuid, text, boolean) to authenticated;

-- ปลดล็อกย้อนหลัง: คนที่ถึงแรงค์ไปแล้วก่อนมีระบบนี้ ไม่ต้องกลับมาสอบ
insert into rank_trial_pass (student_id, rank_key)
select s.id, r.key from students s join ch_ranks r on r.min_exp <= s.exp where r.sort > 1
on conflict do nothing;
-- 70: ภาพบอสด่านเลื่อนแรงค์ (ต้องรันหลัง 69) — ใส่เฉพาะบอสที่ยังไม่มีภาพ ครูเปลี่ยนภาพเองที่แท็บมอนสเตอร์ได้
update monsters set image = 'assets/monsters/' || key || '.png'
 where key in ('trial_silver','trial_gold','trial_platinum','trial_emerald','trial_diamond','trial_master','trial_grandmaster','trial_challenger')
   and (image is null or image = '');
-- 71: ระบบป้องกันใหม่ในการต่อสู้ — "ตั้งรับ" เป็นแอคชันที่เลือกเอง แทนการกดลูกศรลดดาเมจทุกรอบ
--  • ปกติมอนสเตอร์โจมตีอัตโนมัติ รับดาเมจ 70% ของค่าพื้นฐาน (ไม่ต้องกดลูกศร)
--  • ทุกเทิร์นที่ 3 (3,6,9…) มอนสเตอร์ "โจมตีหนัก" ×1.5 (หน้าเว็บเตือนล่วงหน้า)
--  • ตั้งรับ (แทนการโจมตี 1 เทิร์น · ไม่ต้องตอบคำถาม · คูลดาวน์ 2 เทิร์น): กดลูกศรให้ตรง ยิ่งถูกยิ่งลดดาเมจ (ถูกหมด = 0)
--    ถูกครบทุกลูกศร = ปัดป้องสมบูรณ์ → สวนกลับ + ฟื้น HP 8%
--  • โล่โมล (บัพของ Guardian) ยังลดดาเมจ 50% และทำให้ตั้งรับมีลูกศรน้อยลง 1 ลูก
-- ต้องรันหลัง 17 (และ 69/70 ถ้าใช้ด่านบอส) — ไม่แตะข้อมูลเดิม
alter table battles add column if not exists guard boolean not null default false;

-- ให้มุมมองการต่อสู้ส่ง guard / guard_left ให้หน้าเว็บ
do $$
declare d text;
begin
  select pg_get_functiondef('_battle_view(uuid)'::regprocedure) into d;
  if d not like '%guard_left%' then
    d := replace(d, '''turn'', b.turn,', '''turn'', b.turn, ''guard'', b.guard, ''guard_left'', coalesce((b.cds->>''guard'')::int, 0),');
    if d not like '%guard_left%' then raise exception 'แก้ _battle_view ไม่สำเร็จ'; end if;
    execute d;
  end if;
end $$;

-- ตั้งรับ: ใช้แทนการโจมตี 1 เทิร์น แล้วเข้าสู่มินิเกมกดลูกศร
create or replace function battle_guard(p_token uuid, p_battle uuid) returns json
language plpgsql security definer set search_path = public as $$
declare
  sid uuid := _sid(p_token); b battles%rowtype; m monsters%rowtype; cdz jsonb; k text; n int; i int; seqs text := '';
begin
  select * into b from battles where id = p_battle and student_id = sid for update;
  if not found or b.status <> 'active' then raise exception 'ไม่พบการต่อสู้ที่กำลังเล่นอยู่'; end if;
  if b.pend is not null then raise exception 'ต้องป้องกันการโจมตีของมอนสเตอร์ก่อน'; end if;
  if b.cur_q is not null then raise exception 'กำลังตอบคำถามอยู่'; end if;
  cdz := b.cds;
  if coalesce((cdz->>'guard')::int, 0) > 0 then raise exception 'ตั้งรับยังรอคูลดาวน์'; end if;
  select * into m from monsters where id = b.monster_id;
  -- คูลดาวน์สกิลอื่นลด 1 เทิร์น (เหมือนการใช้สกิล) แล้วตั้งคูลดาวน์ตั้งรับ 2 เทิร์น
  for k in select jsonb_object_keys(cdz) loop cdz := jsonb_set(cdz, array[k], to_jsonb(greatest(0, (cdz->>k)::int - 1))); end loop;
  cdz := jsonb_set(cdz, '{guard}', to_jsonb(2));
  n := least(5, 2 + m.level);
  if coalesce((b.buffs->>'shield')::int, 0) > 0 then n := greatest(2, n - 1); end if;
  for i in 1..n loop seqs := seqs || substr('LURD', 1 + floor(random() * 4)::int, 1); end loop;
  update battles set guard = true, cds = cdz,
         pend = jsonb_build_object('dmg', greatest(1, round(m.atk * (0.85 + random() * 0.3))::int), 'n', n, 'seq', seqs, 'at', extract(epoch from now()))
   where id = b.id;
  return _battle_view(b.id);
end $$;

-- รับการโจมตีของมอนสเตอร์ (ไม่ตั้งรับ = ลูกศรไม่มีผล รับ 70%)
create or replace function battle_defend(p_token uuid, p_battle uuid, p_hits int) returns json
language plpgsql security definer set search_path = public as $$
declare
  sid uuid := _sid(p_token); b battles%rowtype; m monsters%rowtype; n int; hits int := 0; dmg int; fin int; shield boolean := false;
  bf jsonb; el numeric; rw_exp int := 0; ev jsonb; heavy boolean; perfect boolean := false; ctr int := 0; hl int := 0; st json;
  intl int; mult numeric;
begin
  select * into b from battles where id = p_battle and student_id = sid for update;
  if not found or b.status <> 'active' or b.pend is null then raise exception 'ไม่มีการโจมตีให้ป้องกัน'; end if;
  select * into m from monsters where id = b.monster_id;
  n := (b.pend->>'n')::int; dmg := (b.pend->>'dmg')::int;
  heavy := (b.turn % 3 = 0);
  if heavy then dmg := round(dmg * 1.5)::int; end if;
  bf := b.buffs;
  if b.guard then
    el := extract(epoch from now()) - (b.pend->>'at')::numeric;
    hits := greatest(0, least(coalesce(p_hits, 0), n));
    if el < 0.25 * hits then hits := 0; end if;            -- เร็วเกินคนกดไม่ทัน = ไม่นับ
    perfect := n > 0 and hits = n;
    fin := round(dmg * (1 - hits::numeric / n))::int;
  else
    fin := round(dmg * 0.7)::int;
  end if;
  if coalesce((bf->>'shield')::int, 0) > 0 then
    shield := true; fin := round(fin * 0.5)::int; bf := jsonb_set(bf, '{shield}', to_jsonb((bf->>'shield')::int - 1));
  end if;
  fin := greatest(case when perfect then 0 else 1 end, fin);
  if coalesce((bf->>'weak')::int, 0) > 0 then bf := jsonb_set(bf, '{weak}', to_jsonb((bf->>'weak')::int - 1)); end if;
  b.p_hp := greatest(0, b.p_hp - fin);
  -- ปัดป้องสมบูรณ์: สวนกลับ + ฟื้น HP (สวนกลับไม่ฆ่า เหลือ HP อย่างน้อย 1)
  if perfect and b.p_hp > 0 then
    st := _stats(sid); intl := coalesce((st->'int'->>'total')::int, 0);
    mult := 1 + coalesce((st->'effects'->>'boss_pct')::int, 0) / 100.0;
    if coalesce((bf->>'weak')::int, 0) > 0 then mult := mult * 1.4; end if;
    ctr := greatest(1, round((20 + intl / 2.0) * mult)::int);
    ctr := least(ctr, greatest(0, b.m_hp - 1));
    b.m_hp := b.m_hp - ctr;
    hl := least(b.p_max - b.p_hp, round(b.p_max * 0.08)::int); b.p_hp := b.p_hp + hl;
  end if;
  ev := jsonb_build_object('hits', hits, 'n', n, 'taken', fin, 'raw', dmg, 'shield', shield, 'guard', b.guard, 'heavy', heavy,
                           'perfect', perfect, 'counter', ctr, 'heal', hl);
  if b.p_hp <= 0 then
    if b.rewarded then
      rw_exp := least(6, b.correct * 2);
      if rw_exp > 0 then perform award(sid, rw_exp, 0, 'สู้มอนสเตอร์: ' || m.name || ' (ให้กำลังใจ)', 'game:battle:' || b.id); end if;
    end if;
    update battles set status = 'lost', finished_at = now(), p_hp = 0, pend = null, guard = false, buffs = bf, exp = rw_exp, turn = b.turn + 1 where id = b.id;
  else
    update battles set p_hp = b.p_hp, m_hp = b.m_hp, pend = null, guard = false, buffs = bf, turn = b.turn + 1 where id = b.id;
  end if;
  return json_build_object('event', ev, 'state', _battle_view(b.id));
end $$;

revoke execute on function battle_guard(uuid, uuid) from public;
grant execute on function battle_guard(uuid, uuid) to anon, authenticated;
-- 72: ระบบสอบเก็บคะแนน (เฟส 1) — สอบผ่านมือถือ/แท็บเล็ตที่โรงเรียน
--  ชนิดข้อ: mcq เลือกตอบ · tf จริง/เท็จ · short ข้อเขียน (พิมพ์ + แนบรูปที่วาดได้) · match จับคู่ · drag ลากวางใส่กลุ่ม
--  ต้องรันหลัง 71 · ไม่แตะข้อมูลเดิม · ผลสอบเข้า scores (สมุดคะแนนเดิม) เมื่อครูกด "ส่งคะแนน"
--
-- รูปแบบ data ของแต่ละชนิดข้อ (เก็บใน exam_questions.data — นักเรียนอ่านตรงๆ ไม่ได้):
--   mcq   {"choices":[{"t":"ข้อความ","img":"รูป"}], "answer":0}
--   tf    {"answer":true}
--   short {"answers":["2","สอง"], "review":true, "upload":true, "hint":"คำใบ้"}   (answers ว่าง = ครูตรวจเองทั้งหมด)
--   match {"left":[{"t","img"}], "right":[{"t","img"}], "pairs":[ดัชนี right ของแต่ละ left]}
--   drag  {"zones":[{"t","img"}], "items":[{"t","img"}], "answer":[ดัชนี zone ของแต่ละ item]}

create table if not exists exam_questions (
  id uuid primary key default gen_random_uuid(),
  topic text not null default 'ทั่วไป',
  kind text not null check (kind in ('mcq', 'tf', 'short', 'match', 'drag')),
  q text not null,
  img text,
  data jsonb not null default '{}'::jsonb,
  points numeric not null default 1 check (points >= 0),
  explain text,
  explain_img text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists exams (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  topic text,
  class_ids uuid[] not null default '{}',
  score_cat text not null default 'pre_mid' check (score_cat in ('pre_mid', 'midterm', 'post_mid', 'final', 'behavior', 'bonus')),
  max_score numeric not null default 10 check (max_score > 0),
  open_at timestamptz,
  close_at timestamptz,
  minutes int not null default 30 check (minutes between 1 and 240),
  shuffle boolean not null default true,
  max_attempts int not null default 1 check (max_attempts between 1 and 10),
  show_result text not null default 'after_close' check (show_result in ('after_submit', 'after_close', 'never')),
  reward_exp int not null default 0 check (reward_exp >= 0),
  status text not null default 'draft' check (status in ('draft', 'open', 'closed')),
  score_items jsonb not null default '{}'::jsonb,       -- {class_id: score_item_id} ที่ส่งคะแนนไปแล้ว
  pushed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists exam_items (
  exam_id uuid not null references exams(id) on delete cascade,
  qid uuid not null references exam_questions(id) on delete restrict,
  pos int not null default 0,
  points numeric check (points >= 0),                   -- null = ใช้คะแนนของข้อนั้น
  primary key (exam_id, qid)
);

create table if not exists exam_attempts (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references exams(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  no int not null default 1,
  started_at timestamptz not null default now(),
  deadline timestamptz not null,
  submitted_at timestamptz,
  status text not null default 'active' check (status in ('active', 'submitted')),
  perm jsonb not null default '{}'::jsonb,              -- {"order":[qid..], "q":{qid:{c|r|i:[..]}}} การสลับของแต่ละคน
  blur int not null default 0,
  score numeric,
  total numeric,
  needs_review boolean not null default false,
  unique (exam_id, student_id, no)
);
create index if not exists exam_attempts_exam on exam_attempts (exam_id);

create table if not exists exam_answers (
  attempt_id uuid not null references exam_attempts(id) on delete cascade,
  qid uuid not null references exam_questions(id) on delete restrict,
  ans jsonb,
  img text,                                             -- path รูปที่แนบใน bucket exam
  score numeric,
  graded boolean not null default false,
  manual boolean not null default false,                -- ครูให้คะแนนเอง (ตรวจใหม่อัตโนมัติจะไม่ทับ)
  note text,
  saved_at timestamptz not null default now(),
  primary key (attempt_id, qid)
);

create table if not exists exam_slots (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  attempt_id uuid not null references exam_attempts(id) on delete cascade,
  qid uuid not null,
  expires_at timestamptz not null default now() + interval '15 minutes',
  used boolean not null default false
);

do $$
declare t text;
begin
  foreach t in array array['exam_questions', 'exams', 'exam_items', 'exam_attempts', 'exam_answers', 'exam_slots'] loop
    execute format('alter table %I enable row level security', t);
    execute format('drop policy if exists teacher_all on %I', t);
    execute format('create policy teacher_all on %I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on %I from anon', t);
    execute format('grant select, insert, update, delete on %I to authenticated', t);
  end loop;
end $$;

insert into app_settings (key, value) values ('exam_grace_sec', '30') on conflict (key) do nothing;

-- ---------- Storage: รูปคำตอบของนักเรียน (private) + รูปโจทย์ของครู (public) ----------
create or replace function _exam_slot_ok(p_name text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from exam_slots where (id::text || '.jpg') = p_name and not used and expires_at > now())
$$;
revoke execute on function _exam_slot_ok(text) from public;
grant execute on function _exam_slot_ok(text) to anon, authenticated;

do $$
begin
  if to_regclass('storage.buckets') is not null then
    insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
    values ('exam', 'exam', false, 1572864, array['image/jpeg'])
    on conflict (id) do update set public = false, file_size_limit = 1572864, allowed_mime_types = array['image/jpeg'];
    insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
    values ('examimg', 'examimg', true, 2097152, array['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml'])
    on conflict (id) do update set public = true, file_size_limit = 2097152, allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml'];
    drop policy if exists chem_exam_upload on storage.objects;
    create policy chem_exam_upload on storage.objects for insert to anon, authenticated
      with check (bucket_id = 'exam' and public._exam_slot_ok(name));
    drop policy if exists chem_exam_teacher on storage.objects;
    create policy chem_exam_teacher on storage.objects for all to authenticated
      using (bucket_id in ('exam', 'examimg') and public.is_teacher()) with check (bucket_id in ('exam', 'examimg') and public.is_teacher());
    drop policy if exists chem_examimg_read on storage.objects;
    create policy chem_examimg_read on storage.objects for select to anon, authenticated using (bucket_id = 'examimg');
  end if;
exception when others then
  raise notice 'ตั้งค่า Storage ของระบบสอบไม่สำเร็จ (%): สร้าง bucket "exam" (Private) และ "examimg" (Public) เองใน Storage', sqlerrm;
end $$;

-- ---------- ฟังก์ชันภายใน ----------
-- สลับลำดับ 0..n-1 แบบสุ่ม (เป็น jsonb array)
create or replace function _exam_shuf(n int, p_on boolean) returns jsonb
language sql volatile as $$
  select coalesce(jsonb_agg(i order by case when p_on then random() else i end), '[]'::jsonb) from generate_series(0, n - 1) i
$$;

-- คะแนนต่อข้อของชุดสอบ
create or replace function _exam_pts(p_exam uuid, p_q uuid) returns numeric
language sql stable security definer set search_path = public as $$
  select coalesce(ei.points, q.points) from exam_items ei join exam_questions q on q.id = ei.qid where ei.exam_id = p_exam and ei.qid = p_q
$$;

-- มุมมองข้อสอบที่ส่งให้นักเรียน (ไม่มีเฉลย) ตามการสลับของ attempt นั้น
create or replace function _exam_qview(q exam_questions, pm jsonb, pts numeric) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare d jsonb := q.data; v jsonb := '{}'::jsonb; idx jsonb; e jsonb;
begin
  if q.kind = 'mcq' then
    select coalesce(jsonb_agg(d->'choices'->(x::int) order by o), '[]'::jsonb) into idx from jsonb_array_elements_text(pm->'c') with ordinality t(x, o);
    v := jsonb_build_object('choices', idx);
  elsif q.kind = 'match' then
    select coalesce(jsonb_agg(d->'right'->(x::int) order by o), '[]'::jsonb) into idx from jsonb_array_elements_text(pm->'r') with ordinality t(x, o);
    v := jsonb_build_object('left', d->'left', 'right', idx);
  elsif q.kind = 'drag' then
    select coalesce(jsonb_agg(d->'items'->(x::int) order by o), '[]'::jsonb) into idx from jsonb_array_elements_text(pm->'i') with ordinality t(x, o);
    v := jsonb_build_object('zones', d->'zones', 'items', idx);
  elsif q.kind = 'short' then
    v := jsonb_build_object('upload', coalesce((d->>'upload')::boolean, false), 'hint', d->>'hint');
  end if;
  return jsonb_build_object('id', q.id, 'kind', q.kind, 'q', q.q, 'img', q.img, 'topic', q.topic, 'points', pts, 'view', v);
end $$;

-- ตรวจ 1 ข้อ → {"f": เศษส่วนคะแนน 0..1, "graded": ตรวจเสร็จหรือยัง}
create or replace function _exam_grade_q(q exam_questions, pm jsonb, a jsonb) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare d jsonb := q.data; f numeric := 0; n int; ok int := 0; i int; r int; t text; acc text; hit boolean := false; cnt int;
begin
  if a is null then return jsonb_build_object('f', 0, 'graded', true); end if;
  if q.kind = 'mcq' then
    if a ? 'i' and (a->>'i') ~ '^\d+$' then
      f := case when (pm->'c'->>((a->>'i')::int)) is not null and (pm->'c'->>((a->>'i')::int))::int = (d->>'answer')::int then 1 else 0 end;
    end if;
  elsif q.kind = 'tf' then
    f := case when a ? 'v' and (a->>'v')::boolean = (d->>'answer')::boolean then 1 else 0 end;
  elsif q.kind = 'short' then
    t := lower(regexp_replace(coalesce(a->>'t', ''), '\s+', '', 'g'));
    cnt := jsonb_array_length(coalesce(d->'answers', '[]'::jsonb));
    if cnt = 0 then
      return jsonb_build_object('f', 0, 'graded', coalesce(a->>'t', '') = '' and not (a ? 'img'));      -- ว่างเปล่า = 0 คะแนนทันที
    end if;
    for acc in select lower(regexp_replace(x, '\s+', '', 'g')) from jsonb_array_elements_text(d->'answers') x loop
      if t <> '' and acc = t then hit := true; end if;
    end loop;
    if hit then return jsonb_build_object('f', 1, 'graded', true); end if;
    return jsonb_build_object('f', 0, 'graded', not (coalesce((d->>'review')::boolean, true) and (t <> '' or coalesce((d->>'upload')::boolean, false))));
  elsif q.kind = 'match' then
    n := jsonb_array_length(d->'left');
    for i in 0..n - 1 loop
      if a->'m'->>i is not null and (a->'m'->>i) ~ '^\d+$' then
        r := (pm->'r'->>((a->'m'->>i)::int))::int;
        if r is not null and r = (d->'pairs'->>i)::int then ok := ok + 1; end if;
      end if;
    end loop;
    f := case when n > 0 then ok::numeric / n else 0 end;
  elsif q.kind = 'drag' then
    n := jsonb_array_length(d->'items');
    for i in 0..n - 1 loop
      if a->'z'->>i is not null and (a->'z'->>i) ~ '^\d+$' then
        r := (pm->'i'->>i)::int;
        if (a->'z'->>i)::int = (d->'answer'->>r)::int then ok := ok + 1; end if;
      end if;
    end loop;
    f := case when n > 0 then ok::numeric / n else 0 end;
  end if;
  return jsonb_build_object('f', f, 'graded', true);
end $$;

-- ตรวจทั้งชุด (ข้ามข้อที่ครูให้คะแนนเองแล้ว) แล้วรวมคะแนน
create or replace function _exam_regrade(p_att uuid) returns void
language plpgsql security definer set search_path = public as $$
declare at exam_attempts%rowtype; qr exam_questions%rowtype; g jsonb; ans exam_answers%rowtype; tot numeric := 0; sc numeric := 0; need boolean := false; pts numeric;
begin
  select * into at from exam_attempts where id = p_att;
  for qr in select q.* from exam_items ei join exam_questions q on q.id = ei.qid where ei.exam_id = at.exam_id order by ei.pos loop
    pts := _exam_pts(at.exam_id, qr.id);
    tot := tot + pts;
    select * into ans from exam_answers where attempt_id = p_att and qid = qr.id;
    if not found then
      insert into exam_answers (attempt_id, qid, ans, score, graded) values (p_att, qr.id, null, 0, true);
      continue;
    end if;
    if ans.manual then
      sc := sc + coalesce(ans.score, 0);
      continue;
    end if;
    g := _exam_grade_q(qr, at.perm->'q'->(qr.id::text), case when ans.img is not null then coalesce(ans.ans, '{}'::jsonb) || jsonb_build_object('img', true) else ans.ans end);
    update exam_answers set score = round((g->>'f')::numeric * pts, 2), graded = (g->>'graded')::boolean where attempt_id = p_att and qid = qr.id;
    sc := sc + round((g->>'f')::numeric * pts, 2);
    if not (g->>'graded')::boolean then need := true; end if;
  end loop;
  update exam_attempts set score = sc, total = tot, needs_review = need or exists (select 1 from exam_answers where attempt_id = p_att and not graded) where id = p_att;
end $$;

-- ส่งข้อสอบ (ตรวจ + ให้ EXP เข้าสอบ)
create or replace function _exam_finish(p_att uuid) returns void
language plpgsql security definer set search_path = public as $$
declare at exam_attempts%rowtype; ex exams%rowtype;
begin
  select * into at from exam_attempts where id = p_att for update;
  if at.status = 'submitted' then return; end if;
  update exam_attempts set status = 'submitted', submitted_at = now() where id = p_att;
  perform _exam_regrade(p_att);
  select * into ex from exams where id = at.exam_id;
  if ex.reward_exp > 0 then
    perform award(at.student_id, ex.reward_exp, 0, 'เข้าสอบ: ' || ex.title, 'exam:' || ex.id);
  end if;
end $$;

-- ปิด attempt ที่หมดเวลา (เผื่อเวลาส่งอีกเล็กน้อย)
create or replace function _exam_expire(p_exam uuid default null) returns void
language plpgsql security definer set search_path = public as $$
declare r record;
begin
  for r in select id from exam_attempts where status = 'active' and (p_exam is null or exam_id = p_exam)
            and now() > deadline + make_interval(secs => _setting_int('exam_grace_sec', 30)) loop
    perform _exam_finish(r.id);
  end loop;
end $$;

-- สถานะเปิดสอบ: upcoming | open | closed
create or replace function _exam_state(e exams) returns text
language sql stable as $$
  select case when e.status = 'draft' then 'draft' when e.status = 'closed' then 'closed'
              when e.close_at is not null and now() > e.close_at then 'closed'
              when e.open_at is not null and now() < e.open_at then 'upcoming' else 'open' end
$$;

-- ผลสอบ/เฉลยเปิดให้นักเรียนดูได้หรือยัง
create or replace function _exam_visible(e exams, at exam_attempts) returns boolean
language sql stable as $$
  select at.status = 'submitted' and case e.show_result when 'after_submit' then true when 'after_close' then _exam_state(e) = 'closed' else false end
$$;

-- ---------- RPC นักเรียน ----------
create or replace function exam_list(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cid uuid; res jsonb := '[]'::jsonb; e exams%rowtype; atts jsonb; nq int; tot numeric; act uuid; best exam_attempts%rowtype; vis boolean;
begin
  select class_id into cid from students where id = sid;
  perform _exam_expire();
  for e in select * from exams where status <> 'draft' and cid = any (class_ids) order by coalesce(open_at, created_at) desc loop
    select count(*), coalesce(sum(coalesce(ei.points, q.points)), 0) into nq, tot from exam_items ei join exam_questions q on q.id = ei.qid where ei.exam_id = e.id;
    select coalesce(jsonb_agg(jsonb_build_object('id', a.id, 'no', a.no, 'status', a.status, 'submitted_at', a.submitted_at) order by a.no), '[]'::jsonb) into atts
      from exam_attempts a where a.exam_id = e.id and a.student_id = sid;
    select id into act from exam_attempts where exam_id = e.id and student_id = sid and status = 'active' limit 1;
    select * into best from exam_attempts where exam_id = e.id and student_id = sid and status = 'submitted' order by score desc nulls last limit 1;
    vis := best.id is not null and _exam_visible(e, best);
    res := res || jsonb_build_object('id', e.id, 'title', e.title, 'topic', e.topic, 'minutes', e.minutes, 'open_at', e.open_at, 'close_at', e.close_at,
      'state', _exam_state(e), 'nq', nq, 'total', tot, 'max_attempts', e.max_attempts, 'attempts', atts, 'active', act, 'show_result', e.show_result,
      'result', case when vis then jsonb_build_object('score', best.score, 'total', best.total, 'scaled', round(coalesce(best.score, 0) / nullif(best.total, 0) * e.max_score, 2),
                          'max', e.max_score, 'review', best.needs_review) else null end,
      'submitted', best.id is not null);
  end loop;
  return json_build_object('now', now(), 'exams', res);
end $$;

create or replace function _exam_payload(p_att uuid) returns json
language plpgsql security definer set search_path = public as $$
declare at exam_attempts%rowtype; e exams%rowtype; qs jsonb := '[]'::jsonb; qid uuid; q exam_questions%rowtype; a exam_answers%rowtype;
begin
  select * into at from exam_attempts where id = p_att;
  select * into e from exams where id = at.exam_id;
  for qid in select x::uuid from jsonb_array_elements_text(at.perm->'order') x loop
    select * into q from exam_questions where id = qid;
    select * into a from exam_answers where attempt_id = p_att and exam_answers.qid = q.id;
    qs := qs || (_exam_qview(q, at.perm->'q'->(q.id::text), _exam_pts(e.id, q.id)) || jsonb_build_object('ans', a.ans, 'photo', a.img is not null));
  end loop;
  return json_build_object('attempt', jsonb_build_object('id', at.id, 'no', at.no, 'deadline', at.deadline, 'now', now(), 'status', at.status),
    'exam', jsonb_build_object('id', e.id, 'title', e.title, 'minutes', e.minutes), 'qs', qs);
end $$;

create or replace function exam_start(p_token uuid, p_exam uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cid uuid; e exams%rowtype; at exam_attempts%rowtype; used int; pm jsonb; ord jsonb := '[]'::jsonb; qr record; n int; qmap jsonb := '{}'::jsonb; dl timestamptz;
begin
  select class_id into cid from students where id = sid;
  select * into e from exams where id = p_exam;
  if not found or not (cid = any (e.class_ids)) then raise exception 'ไม่พบข้อสอบนี้'; end if;
  perform _exam_expire(p_exam);
  select * into at from exam_attempts where exam_id = e.id and student_id = sid and status = 'active' limit 1;
  if found then return _exam_payload(at.id); end if;
  if _exam_state(e) <> 'open' then raise exception 'ข้อสอบนี้ยังไม่เปิดหรือปิดรับแล้ว'; end if;
  select count(*) into used from exam_attempts where exam_id = e.id and student_id = sid;
  if used >= e.max_attempts then raise exception 'คุณสอบครบจำนวนครั้งแล้ว'; end if;
  if not exists (select 1 from exam_items where exam_id = e.id) then raise exception 'ข้อสอบชุดนี้ยังไม่มีข้อ'; end if;
  -- ลำดับข้อ + การสลับตัวเลือกของแต่ละคน
  for qr in select q.* from exam_items ei join exam_questions q on q.id = ei.qid where ei.exam_id = e.id order by case when e.shuffle then random() else ei.pos end, ei.pos loop
    ord := ord || to_jsonb(qr.id::text);
    pm := '{}'::jsonb;
    if qr.kind = 'mcq' then pm := jsonb_build_object('c', _exam_shuf(jsonb_array_length(qr.data->'choices'), e.shuffle));
    elsif qr.kind = 'match' then pm := jsonb_build_object('r', _exam_shuf(jsonb_array_length(qr.data->'right'), e.shuffle));
    elsif qr.kind = 'drag' then pm := jsonb_build_object('i', _exam_shuf(jsonb_array_length(qr.data->'items'), e.shuffle)); end if;
    qmap := qmap || jsonb_build_object(qr.id::text, pm);
  end loop;
  dl := now() + make_interval(mins => e.minutes);
  if e.close_at is not null and e.close_at < dl then dl := e.close_at; end if;
  insert into exam_attempts (exam_id, student_id, no, deadline, perm) values (e.id, sid, used + 1, dl, jsonb_build_object('order', ord, 'q', qmap)) returning * into at;
  return _exam_payload(at.id);
end $$;

-- บันทึกคำตอบรายข้อ (เรียกบ่อย) — รับได้จนถึงเวลาหมด + เวลาผ่อนผัน
create or replace function exam_save(p_token uuid, p_attempt uuid, p_qid uuid, p_ans jsonb) returns void
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); at exam_attempts%rowtype;
begin
  select * into at from exam_attempts where id = p_attempt and student_id = sid;
  if not found or at.status <> 'active' then raise exception 'ส่งข้อสอบไปแล้วหรือหมดเวลา'; end if;
  if now() > at.deadline + make_interval(secs => _setting_int('exam_grace_sec', 30)) then raise exception 'หมดเวลาแล้ว'; end if;
  if not exists (select 1 from exam_items where exam_id = at.exam_id and qid = p_qid) then raise exception 'ไม่พบข้อนี้ในข้อสอบ'; end if;
  if length(coalesce(p_ans::text, '')) > 6000 then raise exception 'คำตอบยาวเกินไป'; end if;
  insert into exam_answers (attempt_id, qid, ans) values (p_attempt, p_qid, p_ans)
  on conflict (attempt_id, qid) do update set ans = excluded.ans, saved_at = now();
end $$;

create or replace function exam_blur(p_token uuid, p_attempt uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  update exam_attempts set blur = blur + 1 where id = p_attempt and student_id = _sid(p_token) and status = 'active';
end $$;

-- ขอช่องอัปโหลดรูปคำตอบ (ข้อเขียนที่เปิดให้แนบรูป)
create or replace function exam_slot(p_token uuid, p_attempt uuid, p_qid uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); at exam_attempts%rowtype; q exam_questions%rowtype; v uuid;
begin
  select * into at from exam_attempts where id = p_attempt and student_id = sid;
  if not found or at.status <> 'active' or now() > at.deadline + make_interval(secs => _setting_int('exam_grace_sec', 30)) then raise exception 'ส่งข้อสอบไปแล้วหรือหมดเวลา'; end if;
  select * into q from exam_questions where id = p_qid;
  if not found or q.kind <> 'short' or not coalesce((q.data->>'upload')::boolean, false) or not exists (select 1 from exam_items where exam_id = at.exam_id and qid = p_qid) then
    raise exception 'ข้อนี้ไม่ต้องแนบรูป';
  end if;
  delete from exam_slots where expires_at < now() - interval '1 day';
  insert into exam_slots (student_id, attempt_id, qid) values (sid, p_attempt, p_qid) returning id into v;
  return v;
end $$;

create or replace function exam_attach(p_token uuid, p_attempt uuid, p_qid uuid, p_slot uuid) returns void
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); path text := p_slot::text || '.jpg';
begin
  perform 1 from exam_slots where id = p_slot and student_id = sid and attempt_id = p_attempt and qid = p_qid and not used and expires_at > now();
  if not found then raise exception 'ช่องอัปโหลดหมดอายุ ลองใหม่อีกครั้ง'; end if;
  if to_regclass('storage.objects') is not null and not exists (select 1 from storage.objects where bucket_id = 'exam' and name = path) then
    raise exception 'ยังไม่พบรูปที่อัปโหลด ลองใหม่อีกครั้ง';
  end if;
  update exam_slots set used = true where id = p_slot;
  insert into exam_answers (attempt_id, qid, ans, img) values (p_attempt, p_qid, null, path)
  on conflict (attempt_id, qid) do update set img = excluded.img, saved_at = now();
end $$;

create or replace function exam_submit(p_token uuid, p_attempt uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); at exam_attempts%rowtype; e exams%rowtype;
begin
  select * into at from exam_attempts where id = p_attempt and student_id = sid;
  if not found then raise exception 'ไม่พบข้อสอบ'; end if;
  perform _exam_finish(at.id);
  select * into at from exam_attempts where id = p_attempt;
  select * into e from exams where id = at.exam_id;
  return json_build_object('submitted', true, 'visible', _exam_visible(e, at),
    'score', case when _exam_visible(e, at) then at.score end, 'total', case when _exam_visible(e, at) then at.total end);
end $$;

-- ทบทวนข้อสอบ + เฉลย (เมื่อเปิดผลแล้ว)
create or replace function exam_review(p_token uuid, p_exam uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); e exams%rowtype; at exam_attempts%rowtype; qs jsonb := '[]'::jsonb; q exam_questions%rowtype; a exam_answers%rowtype; qid uuid;
        pm jsonb; key jsonb; d jsonb; i int;
begin
  select * into e from exams where id = p_exam;
  if not found then raise exception 'ไม่พบข้อสอบ'; end if;
  select * into at from exam_attempts where exam_id = e.id and student_id = sid and status = 'submitted' order by score desc nulls last limit 1;
  if not found or not _exam_visible(e, at) then raise exception 'ยังไม่เปิดดูเฉลย'; end if;
  for qid in select x::uuid from jsonb_array_elements_text(at.perm->'order') x loop
    select * into q from exam_questions where id = qid;
    select * into a from exam_answers where attempt_id = at.id and exam_answers.qid = q.id;
    pm := at.perm->'q'->(q.id::text); d := q.data; key := 'null'::jsonb;
    if q.kind = 'mcq' then
      select to_jsonb(o - 1) into key from jsonb_array_elements_text(pm->'c') with ordinality t(x, o) where x::int = (d->>'answer')::int;
    elsif q.kind = 'tf' then key := d->'answer';
    elsif q.kind = 'short' then key := coalesce(d->'answers', '[]'::jsonb);
    elsif q.kind = 'match' then
      key := '[]'::jsonb;
      for i in 0..jsonb_array_length(d->'left') - 1 loop
        key := key || (select to_jsonb(o - 1) from jsonb_array_elements_text(pm->'r') with ordinality t(x, o) where x::int = (d->'pairs'->>i)::int);
      end loop;
    elsif q.kind = 'drag' then
      key := '[]'::jsonb;
      for i in 0..jsonb_array_length(d->'items') - 1 loop
        key := key || (d->'answer'->((pm->'i'->>i)::int));
      end loop;
    end if;
    qs := qs || (_exam_qview(q, pm, _exam_pts(e.id, q.id)) || jsonb_build_object('ans', a.ans, 'key', key, 'score', a.score, 'graded', a.graded, 'note', a.note,
                'explain', q.explain, 'explain_img', q.explain_img, 'has_photo', a.img is not null));
  end loop;
  return json_build_object('exam', jsonb_build_object('id', e.id, 'title', e.title, 'max', e.max_score),
    'score', at.score, 'total', at.total, 'review', at.needs_review, 'qs', qs);
end $$;

-- ---------- RPC ครู ----------
create or replace function exam_monitor(p_exam uuid) returns json
language plpgsql security definer set search_path = public as $$
declare e exams%rowtype; rows jsonb; qst jsonb;
begin
  if not is_teacher() then raise exception 'เฉพาะครู'; end if;
  select * into e from exams where id = p_exam;
  perform _exam_expire(p_exam);
  select coalesce(jsonb_agg(jsonb_build_object('sid', s.id, 'no', s.no, 'name', s.name, 'class', c.name, 'att', (
      select jsonb_agg(jsonb_build_object('id', a.id, 'no', a.no, 'status', a.status, 'score', a.score, 'total', a.total, 'blur', a.blur, 'review', a.needs_review,
             'started', a.started_at, 'submitted', a.submitted_at) order by a.no) from exam_attempts a where a.exam_id = e.id and a.student_id = s.id))
      order by c.name, s.no), '[]'::jsonb) into rows
    from students s join classes c on c.id = s.class_id where s.class_id = any (e.class_ids);
  select coalesce(jsonb_agg(jsonb_build_object('qid', q.id, 'q', q.q, 'kind', q.kind, 'pos', ei.pos, 'points', coalesce(ei.points, q.points),
      'n', (select count(*) from exam_answers a join exam_attempts t on t.id = a.attempt_id where t.exam_id = e.id and t.status = 'submitted' and a.qid = q.id),
      'avg', (select round(avg(a.score / nullif(coalesce(ei.points, q.points), 0)) * 100) from exam_answers a join exam_attempts t on t.id = a.attempt_id
               where t.exam_id = e.id and t.status = 'submitted' and a.qid = q.id and a.graded)) order by ei.pos), '[]'::jsonb) into qst
    from exam_items ei join exam_questions q on q.id = ei.qid where ei.exam_id = e.id;
  return json_build_object('rows', rows, 'qs', qst);
end $$;

create or replace function exam_attempt_detail(p_attempt uuid) returns json
language plpgsql security definer set search_path = public as $$
declare at exam_attempts%rowtype; e exams%rowtype; qs jsonb := '[]'::jsonb; q exam_questions%rowtype; a exam_answers%rowtype; qid uuid; pm jsonb; nm text;
begin
  if not is_teacher() then raise exception 'เฉพาะครู'; end if;
  select * into at from exam_attempts where id = p_attempt;
  if not found then raise exception 'ไม่พบการสอบ'; end if;
  select * into e from exams where id = at.exam_id;
  select name into nm from students where id = at.student_id;
  for qid in select x::uuid from jsonb_array_elements_text(at.perm->'order') x loop
    select * into q from exam_questions where id = qid;
    select * into a from exam_answers where attempt_id = at.id and exam_answers.qid = q.id;
    pm := at.perm->'q'->(q.id::text);
    qs := qs || (_exam_qview(q, pm, _exam_pts(e.id, q.id)) || jsonb_build_object('ans', a.ans, 'img_path', a.img, 'score', a.score, 'graded', a.graded, 'manual', a.manual,
                'note', a.note, 'key', q.data, 'perm', pm, 'explain', q.explain));
  end loop;
  return json_build_object('attempt', to_jsonb(at) - 'perm', 'student', nm, 'exam', e.title, 'qs', qs);
end $$;

create or replace function exam_grade(p_attempt uuid, p_qid uuid, p_score numeric, p_note text default null) returns void
language plpgsql security definer set search_path = public as $$
declare at exam_attempts%rowtype; pts numeric;
begin
  if not is_teacher() then raise exception 'เฉพาะครู'; end if;
  select * into at from exam_attempts where id = p_attempt;
  pts := _exam_pts(at.exam_id, p_qid);
  if p_score < 0 or p_score > pts then raise exception 'คะแนนต้องอยู่ระหว่าง 0 ถึง %', pts; end if;
  insert into exam_answers (attempt_id, qid, score, graded, manual, note) values (p_attempt, p_qid, p_score, true, true, nullif(p_note, ''))
  on conflict (attempt_id, qid) do update set score = excluded.score, graded = true, manual = true, note = nullif(p_note, '');
  update exam_attempts set score = (select coalesce(sum(score), 0) from exam_answers where attempt_id = p_attempt),
         needs_review = exists (select 1 from exam_answers where attempt_id = p_attempt and not graded) where id = p_attempt;
end $$;

-- ตรวจใหม่ทั้งชุดหลังแก้เฉลย (ข้อที่ครูให้คะแนนเองไม่ถูกทับ)
create or replace function exam_regrade(p_exam uuid) returns int
language plpgsql security definer set search_path = public as $$
declare r record; n int := 0;
begin
  if not is_teacher() then raise exception 'เฉพาะครู'; end if;
  for r in select id from exam_attempts where exam_id = p_exam and status = 'submitted' loop perform _exam_regrade(r.id); n := n + 1; end loop;
  return n;
end $$;

-- ปิดสอบทันที: ปิดการสอบที่ค้างอยู่ทั้งหมด
create or replace function exam_close(p_exam uuid) returns int
language plpgsql security definer set search_path = public as $$
declare r record; n int := 0;
begin
  if not is_teacher() then raise exception 'เฉพาะครู'; end if;
  update exams set status = 'closed' where id = p_exam;
  for r in select id from exam_attempts where exam_id = p_exam and status = 'active' loop perform _exam_finish(r.id); n := n + 1; end loop;
  return n;
end $$;

-- ส่งคะแนนเข้าสมุดคะแนน (score_items/scores) — ใช้คะแนนครั้งที่ดีที่สุด ปรับเป็นคะแนนเต็มของชุดสอบ
create or replace function exam_push(p_exam uuid, p_force boolean default false) returns json
language plpgsql security definer set search_path = public as $$
declare e exams%rowtype; cid uuid; iid uuid; map jsonb; n int := 0; pend int; r record;
begin
  if not is_teacher() then raise exception 'เฉพาะครู'; end if;
  select * into e from exams where id = p_exam;
  perform _exam_expire(p_exam);
  select count(*) into pend from exam_attempts where exam_id = p_exam and status = 'submitted' and needs_review;
  if pend > 0 and not p_force then raise exception 'ยังมี % การสอบที่รอตรวจข้อเขียน (ตรวจให้เสร็จก่อน หรือเลือกส่งทั้งที่ยังไม่ครบ)', pend; end if;
  map := e.score_items;
  foreach cid in array e.class_ids loop
    iid := nullif(map->>(cid::text), '')::uuid;
    if iid is null or not exists (select 1 from score_items where id = iid) then
      insert into score_items (class_id, category, title, max_score) values (cid, e.score_cat, e.title, e.max_score) returning id into iid;
      map := map || jsonb_build_object(cid::text, iid);
    else
      update score_items set max_score = e.max_score, title = e.title where id = iid;
    end if;
    for r in select distinct on (a.student_id) a.student_id, a.score, a.total from exam_attempts a join students s on s.id = a.student_id
              where a.exam_id = p_exam and a.status = 'submitted' and s.class_id = cid order by a.student_id, a.score desc nulls last loop
      insert into scores (item_id, student_id, score) values (iid, r.student_id, round(coalesce(r.score, 0) / nullif(r.total, 0) * e.max_score, 2))
      on conflict (item_id, student_id) do update set score = excluded.score;
      n := n + 1;
    end loop;
  end loop;
  update exams set score_items = map, pushed_at = now() where id = p_exam;
  return json_build_object('students', n, 'pending', pend);
end $$;

revoke execute on function _exam_shuf(int, boolean), _exam_pts(uuid, uuid), _exam_qview(exam_questions, jsonb, numeric), _exam_grade_q(exam_questions, jsonb, jsonb),
  _exam_regrade(uuid), _exam_finish(uuid), _exam_expire(uuid), _exam_state(exams), _exam_visible(exams, exam_attempts), _exam_payload(uuid) from public, anon, authenticated;
revoke execute on function exam_list(uuid), exam_start(uuid, uuid), exam_save(uuid, uuid, uuid, jsonb), exam_blur(uuid, uuid), exam_slot(uuid, uuid, uuid),
  exam_attach(uuid, uuid, uuid, uuid), exam_submit(uuid, uuid), exam_review(uuid, uuid) from public;
grant execute on function exam_list(uuid), exam_start(uuid, uuid), exam_save(uuid, uuid, uuid, jsonb), exam_blur(uuid, uuid), exam_slot(uuid, uuid, uuid),
  exam_attach(uuid, uuid, uuid, uuid), exam_submit(uuid, uuid), exam_review(uuid, uuid) to anon, authenticated;
revoke execute on function exam_monitor(uuid), exam_attempt_detail(uuid), exam_grade(uuid, uuid, numeric, text), exam_regrade(uuid), exam_close(uuid), exam_push(uuid, boolean) from public, anon;
grant execute on function exam_monitor(uuid), exam_attempt_detail(uuid), exam_grade(uuid, uuid, numeric, text), exam_regrade(uuid), exam_close(uuid), exam_push(uuid, boolean) to authenticated;
-- 73: ข้อสอบหัวข้อ “ไอโซเมอร์” (โครงสร้าง + สเตอริโอ) — ต้องรัน 72 ก่อน · รันซ้ำได้ (ไม่เพิ่มข้อซ้ำ)
-- รูปโครงสร้างอยู่ที่ assets/exam/isomer/ (สร้างด้วย tools/make_isomer_imgs.py)

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$mcq$j$, $j$แอลเคนสูตรโมเลกุล C4H10 มีไอโซเมอร์โครงสร้างกี่แบบ$j$, null, $j${"choices": [{"t": "1 แบบ"}, {"t": "2 แบบ"}, {"t": "3 แบบ"}, {"t": "4 แบบ"}], "answer": 1}$j$::jsonb, 1, $j$C4H10 มี 2 แบบ คือ บิวเทน (โซ่ตรง) และ 2-เมทิลโพรเพน (โซ่กิ่ง)$j$, $j$assets/exam/isomer/p_chain.png$j$
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$แอลเคนสูตรโมเลกุล C4H10 มีไอโซเมอร์โครงสร้างกี่แบบ$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$mcq$j$, $j$แอลเคนสูตรโมเลกุล C5H12 มีไอโซเมอร์โครงสร้างกี่แบบ$j$, null, $j${"choices": [{"t": "2 แบบ"}, {"t": "3 แบบ"}, {"t": "4 แบบ"}, {"t": "5 แบบ"}], "answer": 1}$j$::jsonb, 1, $j$C5H12 มี 3 แบบ: เพนเทน, 2-เมทิลบิวเทน และ 2,2-ไดเมทิลโพรเพน$j$, $j$assets/exam/isomer/pentane.png$j$
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$แอลเคนสูตรโมเลกุล C5H12 มีไอโซเมอร์โครงสร้างกี่แบบ$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$mcq$j$, $j$สารคู่ในรูปเป็นไอโซเมอร์โครงสร้างชนิดใด$j$, $j$assets/exam/isomer/p_pos.png$j$, $j${"choices": [{"t": "โซ่คาร์บอน"}, {"t": "ตำแหน่งหมู่ฟังก์ชัน"}, {"t": "หมู่ฟังก์ชัน"}, {"t": "เรขาคณิต (cis-trans)"}], "answer": 1}$j$::jsonb, 1, $j$1-โพรพานอลและ 2-โพรพานอล มีหมู่ -OH เหมือนกันแต่ติดคนละตำแหน่ง จึงเป็นไอโซเมอร์ตำแหน่ง$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$สารคู่ในรูปเป็นไอโซเมอร์โครงสร้างชนิดใด$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$mcq$j$, $j$เอทานอล (CH3CH2OH) กับไดเมทิลอีเทอร์ (CH3OCH3) เป็นไอโซเมอร์ชนิดใด$j$, $j$assets/exam/isomer/p_func.png$j$, $j${"choices": [{"t": "โซ่คาร์บอน"}, {"t": "ตำแหน่งหมู่ฟังก์ชัน"}, {"t": "หมู่ฟังก์ชัน"}, {"t": "เรขาคณิต (cis-trans)"}], "answer": 2}$j$::jsonb, 1, $j$สูตรโมเลกุลเดียวกัน (C2H6O) แต่มีหมู่ฟังก์ชันต่างกัน (แอลกอฮอล์ vs อีเทอร์)$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$เอทานอล (CH3CH2OH) กับไดเมทิลอีเทอร์ (CH3OCH3) เป็นไอโซเมอร์ชนิดใด$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$mcq$j$, $j$บิวเทนกับ 2-เมทิลโพรเพน (ในรูป) เป็นไอโซเมอร์ชนิดใด$j$, $j$assets/exam/isomer/p_chain.png$j$, $j${"choices": [{"t": "โซ่คาร์บอน"}, {"t": "ตำแหน่งหมู่ฟังก์ชัน"}, {"t": "หมู่ฟังก์ชัน"}, {"t": "เรขาคณิต (cis-trans)"}], "answer": 0}$j$::jsonb, 1, $j$ต่างกันที่การจัดเรียงโซ่คาร์บอน (โซ่ตรง vs โซ่กิ่ง)$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$บิวเทนกับ 2-เมทิลโพรเพน (ในรูป) เป็นไอโซเมอร์ชนิดใด$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$mcq$j$, $j$สารในข้อใดแสดงไอโซเมอร์เรขาคณิต (cis-trans) ได้$j$, null, $j${"choices": [{"t": "", "img": "assets/exam/isomer/propene.png"}, {"t": "", "img": "assets/exam/isomer/isobutene.png"}, {"t": "", "img": "assets/exam/isomer/cis2butene.png"}, {"t": "", "img": "assets/exam/isomer/11dce.png"}], "answer": 2}$j$::jsonb, 1, $j$ต้องมี C=C ที่คาร์บอนแต่ละตัวต่อกับหมู่ที่ต่างกัน 2 หมู่ — บิวต์-2-อีนตรงเงื่อนไข ส่วนโพรพีน, 2-เมทิลโพรพีน และ 1,1-ไดคลอโรเอทีน มีคาร์บอนข้างหนึ่งต่อกับหมู่เหมือนกัน$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$สารในข้อใดแสดงไอโซเมอร์เรขาคณิต (cis-trans) ได้$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$mcq$j$, $j$สารในข้อใดมีคาร์บอนไครัล (chiral carbon)$j$, null, $j${"choices": [{"t": "", "img": "assets/exam/isomer/ethanol.png"}, {"t": "", "img": "assets/exam/isomer/2propanol.png"}, {"t": "", "img": "assets/exam/isomer/2butanol.png"}, {"t": "", "img": "assets/exam/isomer/3pentanol.png"}], "answer": 2}$j$::jsonb, 1, $j$C2 ของ 2-บิวทานอลต่อกับ 4 หมู่ต่างกัน: -OH, -H, -CH3, -CH2CH3$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$สารในข้อใดมีคาร์บอนไครัล (chiral carbon)$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$mcq$j$, $j$สารสูตร C4H8 มีไอโซเมอร์โครงสร้าง (นับรวมโครงสร้างวงแหวน แต่ไม่นับ cis-trans) กี่แบบ$j$, null, $j${"choices": [{"t": "3 แบบ"}, {"t": "4 แบบ"}, {"t": "5 แบบ"}, {"t": "6 แบบ"}], "answer": 2}$j$::jsonb, 2, $j$บิวต์-1-อีน, บิวต์-2-อีน, 2-เมทิลโพรพีน, ไซโคลบิวเทน, เมทิลไซโคลโพรเพน = 5 แบบ (ถ้านับ cis/trans แยก จะเป็น 6 สเตอริโอไอโซเมอร์)$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$สารสูตร C4H8 มีไอโซเมอร์โครงสร้าง (นับรวมโครงสร้างวงแหวน แต่ไม่นับ cis-trans) กี่แบบ$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$mcq$j$, $j$สารสูตร C4H10O มีไอโซเมอร์โครงสร้างกี่แบบ (แอลกอฮอล์ + อีเทอร์)$j$, null, $j${"choices": [{"t": "4 แบบ"}, {"t": "5 แบบ"}, {"t": "6 แบบ"}, {"t": "7 แบบ"}], "answer": 3}$j$::jsonb, 2, $j$แอลกอฮอล์ 4 แบบ (บิวทัน-1-ออล, บิวทัน-2-ออล, 2-เมทิลโพรพัน-1-ออล, 2-เมทิลโพรพัน-2-ออล) + อีเทอร์ 3 แบบ (ไดเอทิลอีเทอร์, เมทิลโพรพิลอีเทอร์, ไอโซโพรพิลเมทิลอีเทอร์) = 7$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$สารสูตร C4H10O มีไอโซเมอร์โครงสร้างกี่แบบ (แอลกอฮอล์ + อีเทอร์)$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$mcq$j$, $j$ข้อใดกล่าวถูกต้องเกี่ยวกับเอนันทิโอเมอร์ (enantiomer) คู่หนึ่ง$j$, $j$assets/exam/isomer/p_enan.png$j$, $j${"choices": [{"t": "จุดเดือดต่างกันมาก"}, {"t": "หมุนระนาบแสงโพลาไรซ์ในทิศตรงข้ามกัน องศาเท่ากัน"}, {"t": "เป็นโครงสร้างเดียวกัน ซ้อนทับกันได้"}, {"t": "ไม่มีคาร์บอนไครัลเลย"}], "answer": 1}$j$::jsonb, 1, $j$เอนันทิโอเมอร์เป็นภาพสะท้อนในกระจกที่ซ้อนทับกันไม่ได้ สมบัติทางกายภาพส่วนใหญ่เหมือนกัน แต่หมุนแสงโพลาไรซ์ตรงข้ามกัน$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$ข้อใดกล่าวถูกต้องเกี่ยวกับเอนันทิโอเมอร์ (enantiomer) คู่หนึ่ง$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$mcq$j$, $j$เงื่อนไขของ C=C ที่ทำให้เกิดไอโซเมอร์เรขาคณิตคือข้อใด$j$, null, $j${"choices": [{"t": "คาร์บอนตัวใดตัวหนึ่งของ C=C ต่อกับหมู่เหมือนกัน 2 หมู่"}, {"t": "คาร์บอนแต่ละตัวของ C=C ต่อกับหมู่ที่ต่างกัน 2 หมู่"}, {"t": "ต้องมีธาตุเฮไลด์อยู่ในโมเลกุล"}, {"t": "ต้องเป็นโมเลกุลวงแหวนเท่านั้น"}], "answer": 1}$j$::jsonb, 1, $j$พันธะคู่หมุนอิสระไม่ได้ ถ้าแต่ละ C ต่อกับหมู่ต่างกัน 2 หมู่จะเกิดรูป cis และ trans$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$เงื่อนไขของ C=C ที่ทำให้เกิดไอโซเมอร์เรขาคณิตคือข้อใด$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$mcq$j$, $j$สารที่มีคาร์บอนไครัลต่างกัน 2 อะตอม (เช่น 2,3-ไดโบรโมเพนเทน) มีสเตอริโอไอโซเมอร์ได้สูงสุดกี่แบบ$j$, $j$assets/exam/isomer/23dbp.png$j$, $j${"choices": [{"t": "2 แบบ"}, {"t": "3 แบบ"}, {"t": "4 แบบ"}, {"t": "8 แบบ"}], "answer": 2}$j$::jsonb, 2, $j$จำนวนสเตอริโอไอโซเมอร์สูงสุด = 2ⁿ เมื่อ n = จำนวนคาร์บอนไครัล → 2² = 4$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$สารที่มีคาร์บอนไครัลต่างกัน 2 อะตอม (เช่น 2,3-ไดโบรโมเพนเทน) มีสเตอริโอไอโซเมอร์ได้สูงสุดกี่แบบ$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$tf$j$, $j$บิวเทนและ 2-เมทิลโพรเพนเป็นไอโซเมอร์กัน$j$, null, $j${"answer": true}$j$::jsonb, 1, $j$สูตรโมเลกุลเดียวกัน (C4H10) แต่โครงสร้างต่างกัน$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$บิวเทนและ 2-เมทิลโพรเพนเป็นไอโซเมอร์กัน$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$tf$j$, $j$เอทานอลและไดเมทิลอีเทอร์มีสมบัติทางกายภาพ (เช่น จุดเดือด) เหมือนกัน เพราะสูตรโมเลกุลเดียวกัน$j$, null, $j${"answer": false}$j$::jsonb, 1, $j$หมู่ฟังก์ชันต่างกัน: เอทานอลมีพันธะไฮโดรเจนระหว่างโมเลกุล จุดเดือดสูงกว่าไดเมทิลอีเทอร์มาก$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$เอทานอลและไดเมทิลอีเทอร์มีสมบัติทางกายภาพ (เช่น จุดเดือด) เหมือนกัน เพราะสูตรโมเลกุลเดียวกัน$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$tf$j$, $j$โมเลกุลที่มีคาร์บอนไครัล 1 อะตอม จะมีเอนันทิโอเมอร์ (ภาพสะท้อนในกระจกที่ซ้อนทับไม่ได้) เสมอ$j$, null, $j${"answer": true}$j$::jsonb, 1, $j$คาร์บอนไครัลเดียวทำให้โมเลกุลไม่มีระนาบสมมาตร จึงมีคู่เอนันทิโอเมอร์เสมอ$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$โมเลกุลที่มีคาร์บอนไครัล 1 อะตอม จะมีเอนันทิโอเมอร์ (ภาพสะท้อนในกระจกที่ซ้อนทับไม่ได้) เสมอ$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$tf$j$, $j$1,1-ไดคลอโรเอทีนมีไอโซเมอร์เรขาคณิต (cis-trans)$j$, $j$assets/exam/isomer/11dce.png$j$, $j${"answer": false}$j$::jsonb, 1, $j$คาร์บอนตัวหนึ่งต่อกับ Cl เหมือนกัน 2 อะตอม จึงไม่เกิด cis-trans$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$1,1-ไดคลอโรเอทีนมีไอโซเมอร์เรขาคณิต (cis-trans)$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$match$j$, $j$จับคู่ชนิดของไอโซเมอร์กับสารคู่ตัวอย่างที่ถูกต้อง$j$, null, $j${"left": [{"t": "ไอโซเมอร์โซ่คาร์บอน"}, {"t": "ไอโซเมอร์ตำแหน่ง"}, {"t": "ไอโซเมอร์หมู่ฟังก์ชัน"}, {"t": "ไอโซเมอร์เรขาคณิต (cis-trans)"}], "right": [{"t": "", "img": "assets/exam/isomer/p_chain.png"}, {"t": "", "img": "assets/exam/isomer/p_pos.png"}, {"t": "", "img": "assets/exam/isomer/p_func.png"}, {"t": "", "img": "assets/exam/isomer/p_geo.png"}], "pairs": [0, 1, 2, 3]}$j$::jsonb, 4, $j$บิวเทน/ไอโซบิวเทน = โซ่ · 1-/2-โพรพานอล = ตำแหน่ง · เอทานอล/ไดเมทิลอีเทอร์ = หมู่ฟังก์ชัน · cis/trans-1,2-ไดคลอโรเอทีน = เรขาคณิต$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$จับคู่ชนิดของไอโซเมอร์กับสารคู่ตัวอย่างที่ถูกต้อง$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$match$j$, $j$จับคู่โครงสร้างของแอลเคน C5H12 กับชื่อ IUPAC$j$, null, $j${"left": [{"t": "", "img": "assets/exam/isomer/pentane.png"}, {"t": "", "img": "assets/exam/isomer/2mebutane.png"}, {"t": "", "img": "assets/exam/isomer/neopentane.png"}], "right": [{"t": "เพนเทน"}, {"t": "2-เมทิลบิวเทน"}, {"t": "2,2-ไดเมทิลโพรเพน"}, {"t": "3-เมทิลบิวเทน"}], "pairs": [0, 1, 2]}$j$::jsonb, 3, $j$เลือกโซ่หลักยาวที่สุดและเลขตำแหน่งต่ำสุด — “3-เมทิลบิวเทน” ไม่ใช่ชื่อที่ถูก (ต้องนับจากอีกด้านเป็น 2-เมทิลบิวเทน)$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$จับคู่โครงสร้างของแอลเคน C5H12 กับชื่อ IUPAC$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$drag$j$, $j$จัดสารคู่ต่อไปนี้ให้อยู่ในกลุ่มชนิดไอโซเมอร์โครงสร้างที่ถูกต้อง$j$, null, $j${"zones": [{"t": "ไอโซเมอร์โซ่คาร์บอน"}, {"t": "ไอโซเมอร์ตำแหน่ง"}, {"t": "ไอโซเมอร์หมู่ฟังก์ชัน"}], "items": [{"t": "", "img": "assets/exam/isomer/p_chain.png"}, {"t": "", "img": "assets/exam/isomer/p_chain2.png"}, {"t": "", "img": "assets/exam/isomer/p_pos.png"}, {"t": "", "img": "assets/exam/isomer/p_pos2.png"}, {"t": "", "img": "assets/exam/isomer/p_func.png"}, {"t": "", "img": "assets/exam/isomer/p_func2.png"}], "answer": [0, 0, 1, 1, 2, 2]}$j$::jsonb, 6, $j$บิวเทน/ไอโซบิวเทน และ เพนเทน/นีโอเพนเทน = โซ่ · 1-/2-โพรพานอล และ 1-/2-บิวทีน = ตำแหน่ง · เอทานอล/ไดเมทิลอีเทอร์ และ โพรพานัล/อะซีโตน = หมู่ฟังก์ชัน$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$จัดสารคู่ต่อไปนี้ให้อยู่ในกลุ่มชนิดไอโซเมอร์โครงสร้างที่ถูกต้อง$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$drag$j$, $j$ลากสารแต่ละชนิดไปยังกลุ่มว่า “มี cis-trans” หรือ “ไม่มี cis-trans”$j$, null, $j${"zones": [{"t": "มีไอโซเมอร์ cis-trans"}, {"t": "ไม่มีไอโซเมอร์ cis-trans"}], "items": [{"t": "", "img": "assets/exam/isomer/trans2butene.png"}, {"t": "", "img": "assets/exam/isomer/cisdce.png"}, {"t": "", "img": "assets/exam/isomer/2pentene.png"}, {"t": "", "img": "assets/exam/isomer/propene.png"}, {"t": "", "img": "assets/exam/isomer/11dce.png"}, {"t": "", "img": "assets/exam/isomer/2me2butene.png"}], "answer": [0, 0, 0, 1, 1, 1]}$j$::jsonb, 6, $j$ต้องมี C=C ที่คาร์บอนทั้งสองต่อกับหมู่ต่างกัน: บิวต์-2-อีน, 1,2-ไดคลอโรเอทีน, เพนต์-2-อีน มี · โพรพีน, 1,1-ไดคลอโรเอทีน, 2-เมทิลบิวต์-2-อีน ไม่มี$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$ลากสารแต่ละชนิดไปยังกลุ่มว่า “มี cis-trans” หรือ “ไม่มี cis-trans”$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$drag$j$, $j$ลากสารแต่ละชนิดไปยังกลุ่มว่า “มีคาร์บอนไครัล” หรือ “ไม่มีคาร์บอนไครัล”$j$, null, $j${"zones": [{"t": "มีคาร์บอนไครัล"}, {"t": "ไม่มีคาร์บอนไครัล"}], "items": [{"t": "", "img": "assets/exam/isomer/2butanol.png"}, {"t": "", "img": "assets/exam/isomer/lactic.png"}, {"t": "", "img": "assets/exam/isomer/2clbutane.png"}, {"t": "", "img": "assets/exam/isomer/3mehexane.png"}, {"t": "", "img": "assets/exam/isomer/2propanol.png"}, {"t": "", "img": "assets/exam/isomer/ethanol.png"}, {"t": "", "img": "assets/exam/isomer/3pentanol.png"}], "answer": [0, 0, 0, 0, 1, 1, 1]}$j$::jsonb, 7, $j$คาร์บอนไครัลต้องต่อกับ 4 หมู่ที่ต่างกัน: 2-บิวทานอล, กรดแลกติก, 2-คลอโรบิวเทน, 3-เมทิลเฮกเซน มี · 2-โพรพานอล, เอทานอล, 3-เพนทานอลไม่มี$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$ลากสารแต่ละชนิดไปยังกลุ่มว่า “มีคาร์บอนไครัล” หรือ “ไม่มีคาร์บอนไครัล”$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$short$j$, $j$วาดโครงสร้างไอโซเมอร์ของแอลเคนสูตร C5H12 ให้ครบทุกแบบ พร้อมเขียนชื่อกำกับ (วาดบนกระดาษแล้วถ่ายรูปแนบ)$j$, null, $j${"answers": [], "upload": true, "review": true, "hint": "ครบ 3 โครงสร้าง ชื่อต้องถูกด้วย"}$j$::jsonb, 4, $j$ต้องได้ 3 โครงสร้าง: เพนเทน, 2-เมทิลบิวเทน, 2,2-ไดเมทิลโพรเพน (1 คะแนนต่อโครงสร้างที่ถูก + 1 คะแนนชื่อถูกครบ)$j$, $j$assets/exam/isomer/pentane.png$j$
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$วาดโครงสร้างไอโซเมอร์ของแอลเคนสูตร C5H12 ให้ครบทุกแบบ พร้อมเขียนชื่อกำกับ (วาดบนกระดาษแล้วถ่ายรูปแนบ)$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$short$j$, $j$1-บิวทานอล (CH3CH2CH2CH2OH) กับไดเอทิลอีเทอร์ (CH3CH2OCH2CH3) เป็นไอโซเมอร์ชนิดใด (ตอบสั้นๆ)$j$, null, $j${"answers": ["ไอโซเมอร์หมู่ฟังก์ชัน", "หมู่ฟังก์ชัน", "functional group", "functional group isomer"], "upload": false, "review": true}$j$::jsonb, 2, $j$สูตรโมเลกุลเดียวกัน C4H10O แต่มีหมู่ฟังก์ชันต่างกัน (แอลกอฮอล์ vs อีเทอร์) จึงเป็นไอโซเมอร์หมู่ฟังก์ชัน$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$1-บิวทานอล (CH3CH2CH2CH2OH) กับไดเอทิลอีเทอร์ (CH3CH2OCH2CH3) เป็นไอโซเมอร์ชนิดใด (ตอบสั้นๆ)$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$short$j$, $j$2,3-ไดโบรโมเพนเทน (CH3CHBrCHBrCH2CH3) มีคาร์บอนไครัลกี่อะตอม (ตอบเป็นตัวเลข)$j$, $j$assets/exam/isomer/23dbp.png$j$, $j${"answers": ["2", "สอง", "2 อะตอม"], "upload": false, "review": false}$j$::jsonb, 1, $j$C2 และ C3 แต่ละตัวต่อกับ 4 หมู่ต่างกัน$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$2,3-ไดโบรโมเพนเทน (CH3CHBrCHBrCH2CH3) มีคาร์บอนไครัลกี่อะตอม (ตอบเป็นตัวเลข)$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$short$j$, $j$วาดโครงสร้าง cis- และ trans-1,2-ไดคลอโรเอทีน พร้อมอธิบายว่าสองโครงสร้างนี้ต่างกันอย่างไร และเหตุใดจึงเปลี่ยนรูปหากันไม่ได้ (วาดแล้วถ่ายรูปแนบ + พิมพ์อธิบาย)$j$, null, $j${"answers": [], "upload": true, "review": true}$j$::jsonb, 4, $j$cis: Cl อยู่ด้านเดียวกันของพันธะคู่ · trans: Cl อยู่คนละด้าน · พันธะคู่หมุนอิสระไม่ได้ จึงเปลี่ยนรูปหากันไม่ได้ (ต้องทำลายพันธะ π ก่อน)$j$, $j$assets/exam/isomer/p_geo.png$j$
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$วาดโครงสร้าง cis- และ trans-1,2-ไดคลอโรเอทีน พร้อมอธิบายว่าสองโครงสร้างนี้ต่างกันอย่างไร และเหตุใดจึงเปลี่ยนรูปหากันไม่ได้ (วาดแล้วถ่ายรูปแนบ + พิมพ์อธิบาย)$j$);

-- ชุดสอบฉบับร่าง (ยังไม่ระบุห้อง): เปิดแท็บ 📝 ข้อสอบ → แก้ → เลือกห้อง/เวลา → เปลี่ยนสถานะเป็น “เปิดให้สอบ”
with e as (
  insert into exams (title, topic, minutes, shuffle, max_attempts, show_result, max_score, status)
  select 'สอบเก็บคะแนน: ไอโซเมอร์ (โครงสร้าง + สเตอริโอ)', $j$ไอโซเมอร์$j$, 40, true, 1, 'after_close', 10, 'draft'
  where not exists (select 1 from exams where title = 'สอบเก็บคะแนน: ไอโซเมอร์ (โครงสร้าง + สเตอริโอ)')
  returning id)
insert into exam_items (exam_id, qid, pos)
select e.id, q.id, row_number() over (order by q.created_at, q.id) from e, exam_questions q where q.topic = $j$ไอโซเมอร์$j$;
-- 74: รหัสสอบ — เริ่มสอบแต่ละครั้งต้องกรอกรหัสที่ครูบอกในห้อง (ต้องรันหลัง 72)
--  ทำต่อจากที่เริ่มค้างไว้ (ยังไม่ส่ง) ไม่ต้องกรอกซ้ำ · ผิดเกิน 5 ครั้งใน 10 นาที ล็อกชั่วคราว
alter table exams add column if not exists access_code text;

create table if not exists exam_code_fails (
  exam_id uuid not null references exams(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  n int not null default 0,
  first_at timestamptz not null default now(),
  primary key (exam_id, student_id)
);
alter table exam_code_fails enable row level security;
drop policy if exists teacher_all on exam_code_fails;
create policy teacher_all on exam_code_fails for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on exam_code_fails from anon;
grant select, insert, update, delete on exam_code_fails to authenticated;

do $$
declare d text; ok text := 'if _exam_state(e) <> ''open'' then raise exception ''ข้อสอบนี้ยังไม่เปิดหรือปิดรับแล้ว''; end if;';
begin
  select pg_get_functiondef('public.exam_start(uuid, uuid)'::regprocedure) into d;
  if position(ok in d) = 0 then raise exception 'ไม่พบจุดแทรกใน exam_start'; end if;
  d := replace(d, 'exam_start(p_token uuid, p_exam uuid)', 'exam_start(p_token uuid, p_exam uuid, p_code text default null)');
  d := replace(d, ok, ok || '
  if coalesce(e.access_code, '''') <> '''' then
    delete from exam_code_fails where exam_id = e.id and student_id = sid and first_at < now() - interval ''10 minutes'';
    if coalesce((select f.n from exam_code_fails f where f.exam_id = e.id and f.student_id = sid), 0) >= 5 then
      return json_build_object(''code_error'', ''กรอกรหัสผิดหลายครั้ง รอสักครู่แล้วลองใหม่ หรือขอรหัสจากครู'');
    end if;
    if lower(btrim(coalesce(p_code, ''''))) <> lower(btrim(e.access_code)) then
      insert into exam_code_fails (exam_id, student_id, n) values (e.id, sid, 1)
        on conflict (exam_id, student_id) do update set n = exam_code_fails.n + 1;
      return json_build_object(''code_error'', ''รหัสสอบไม่ถูกต้อง'');   -- ไม่ raise เพื่อให้จำนวนครั้งที่ผิดถูกบันทึก
    end if;
    delete from exam_code_fails where exam_id = e.id and student_id = sid;
  end if;');
  drop function public.exam_start(uuid, uuid);
  execute d;
  select pg_get_functiondef('public.exam_list(uuid)'::regprocedure) into d;
  if position('''show_result'', e.show_result,' in d) = 0 then raise exception 'ไม่พบจุดแทรกใน exam_list'; end if;
  d := replace(d, '''show_result'', e.show_result,', '''show_result'', e.show_result, ''has_code'', coalesce(e.access_code, '''') <> '''',');
  execute d;
end $$;

revoke execute on function exam_start(uuid, uuid, text) from public;
grant execute on function exam_start(uuid, uuid, text) to anon, authenticated;
-- 75: กันโกงสอบ — สลับหน้าจอ/ยุบแอปเกินกำหนด = ส่งข้อสอบอัตโนมัติ (ต้องรันหลัง 72/74)
alter table exams add column if not exists max_blur int not null default 3 check (max_blur between 0 and 20);   -- 0 = ไม่จำกัด (นับอย่างเดียว)

drop function if exists exam_blur(uuid, uuid);
create or replace function exam_blur(p_token uuid, p_attempt uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); at exam_attempts%rowtype; mx int;
begin
  select * into at from exam_attempts where id = p_attempt and student_id = sid for update;
  if not found then raise exception 'ไม่พบข้อสอบ'; end if;
  select max_blur into mx from exams where id = at.exam_id;
  if at.status <> 'active' then return json_build_object('blur', at.blur, 'max', mx, 'locked', at.status = 'submitted'); end if;
  update exam_attempts set blur = blur + 1 where id = p_attempt returning blur into at.blur;
  if mx > 0 and at.blur > mx then
    perform _exam_finish(p_attempt);
    return json_build_object('blur', at.blur, 'max', mx, 'locked', true);
  end if;
  return json_build_object('blur', at.blur, 'max', mx, 'locked', false);
end $$;
revoke execute on function exam_blur(uuid, uuid) from public;
grant execute on function exam_blur(uuid, uuid) to anon, authenticated;
-- 76: รางวัล + ความสำเร็จ "ชนะประลองครูบุ๊ค" (v2.15) · รันซ้ำได้
--  · Achievement ใหม่ 8 อัน (เล่นครั้งแรก / ผ่านครึ่งทาง / เกือบชนะ / ชนะ 1-3-10 ครั้ง / ชนะเร็ว ≤ 5 นาที)
--  · ชนะ (รอบที่ได้รางวัล) ดรอปยาสุ่ม 1 ชิ้น · ชนะครั้งแรกได้ฉายา "ผู้พิชิตครูบุ๊ค" + ม้วนอัปเกรด
--    ชนะครั้งที่ 3 / ทุก 5 ครั้งได้ม้วนอัปเกรดเพิ่ม · ชนะครบ 10 ครั้งได้กรอบ "กรอบแชมป์ครูบุ๊ค"
--  · ชนะนอกโควตารายวัน (ฝึกซ้อม) ไม่ได้ดรอปและไม่นับ Achievement

-- ---------- ตาราง ----------
alter table game_plays add column if not exists kb_secs int;
do $$ declare c text; begin
  for c in select conname from pg_constraint where conrelid = 'public.achievements'::regclass and contype = 'c' and pg_get_constraintdef(oid) like '%attendance_count%' loop
    execute format('alter table achievements drop constraint %I', c);
  end loop;
  alter table achievements add constraint achievements_metric_check check (metric in
    ('attendance_count','present_count','attendance_streak','ontime_submissions','total_exp','level','gacha_pulls','quests_done',
     'kb_plays','kb_cleared','kb_wins','kb_fast'));
  for c in select conname from pg_constraint where conrelid = 'public.student_decor'::regclass and contype = 'c' and pg_get_constraintdef(oid) like '%gacha%' loop
    execute format('alter table student_decor drop constraint %I', c);
  end loop;
  alter table student_decor add constraint student_decor_source_check check (source in ('shop','gacha','teacher','kb'));
end $$;

-- ---------- ตัวชี้วัดใหม่ ----------
do $$ declare def text; nd text; begin
  def := pg_get_functiondef('student_metric(uuid,text)'::regprocedure);
  if position('kb_wins' in def) > 0 then return; end if;
  if position(E'else n := 0;' in def) = 0 then raise exception 'student_metric: ไม่พบจุดแทนที่'; end if;
  nd := replace(def, E'else n := 0;', $r$when 'kb_plays' then
      select count(*) into n from game_plays where student_id = p_student and game = 'kb' and (exp > 0 or coins > 0);
    when 'kb_cleared' then
      select coalesce(max(case when score = 100 then 8 else score / 12 end), 0) into n from game_plays where student_id = p_student and game = 'kb' and (exp > 0 or coins > 0);
    when 'kb_wins' then
      select count(*) into n from game_plays where student_id = p_student and game = 'kb' and score = 100 and (exp > 0 or coins > 0);
    when 'kb_fast' then
      select count(*) into n from game_plays where student_id = p_student and game = 'kb' and score = 100 and (exp > 0 or coins > 0) and kb_secs is not null and kb_secs <= 300;
    else n := 0;$r$);
  execute nd;
end $$;

-- ---------- ของรางวัล ----------
insert into decor_items (slot, key, color, name, emoji, rarity, price, sort, st_int, st_dil, st_str, st_luk, st_coin)
select 'title', 'text', null, 'ผู้พิชิตครูบุ๊ค', '🏆', 'SSR', null, 900, 2, 0, 1, 1, 3
where not exists (select 1 from decor_items where slot = 'title' and name = 'ผู้พิชิตครูบุ๊ค');
insert into decor_items (slot, key, color, name, emoji, rarity, price, sort, st_int, st_dil, st_str, st_luk, st_coin)
select 'frame', 'solid', '#f5b301', 'กรอบแชมป์ครูบุ๊ค', '🥇', 'SSR', null, 901, 1, 1, 1, 1, 2
where not exists (select 1 from decor_items where slot = 'frame' and name = 'กรอบแชมป์ครูบุ๊ค');

insert into achievements (key, name, description, emoji, metric, threshold, reward_exp, reward_coins)
select * from (values
  ('kb_play_1',  'กล้าท้าครู',            'ลงสนามประลองครูบุ๊คครั้งแรก',               '⚔️', 'kb_plays',   1,  10, 5),
  ('kb_round4',  'ผ่านครึ่งทาง',           'ผ่านครบ 4 รอบในประลองครูบุ๊ค',               '🛡️', 'kb_cleared', 4,  30, 10),
  ('kb_round7',  'อีกแค่ก้าวเดียว',        'ผ่าน 7 รอบ เหลือแค่รอบสุดท้าย',              '🔥', 'kb_cleared', 7,  60, 20),
  ('kb_win_1',   'ล้มครูบุ๊คได้!',         'ชนะประลองครูบุ๊คครั้งแรก (ได้ฉายา ผู้พิชิตครูบุ๊ค)', '🏆', 'kb_wins', 1, 150, 50),
  ('kb_win_3',   'ศิษย์เอกท้าครู',         'ชนะครูบุ๊คครบ 3 ครั้ง',                      '🥋', 'kb_wins',    3,  200, 80),
  ('kb_win_10',  'ตำนานผู้พิชิตครูบุ๊ค',   'ชนะครูบุ๊คครบ 10 ครั้ง (ได้กรอบแชมป์)',        '👑', 'kb_wins',    10, 500, 200),
  ('kb_fast',    'สายฟ้าเคมี',             'ชนะครูบุ๊คภายใน 5 นาที',                     '⚡', 'kb_fast',    1,  120, 40)
) v(key, name, description, emoji, metric, threshold, reward_exp, reward_coins)
where not exists (select 1 from achievements a where a.key = v.key);

-- ---------- ตัวห่อ kb_submit: ตรวจเวลา (เดิม) → ส่งผล (_kb_submit) → ดรอป/Achievement ----------
create or replace function kb_submit(p_token uuid, p_cleared int, p_won boolean, p_seconds int) returns json
language plpgsql security definer set search_path = public as $$
declare
  sid uuid := _sid(p_token); r jsonb; before uuid[]; w int; cid uuid; drops jsonb := '[]'::jsonb; decs jsonb := '[]'::jsonb; ach jsonb;
  pot record; sc int := 0; did uuid;
begin
  perform _game_check(sid, 'kb', greatest(6, coalesce(p_cleared, 0) * 2), p_seconds);
  select array(select achievement_id from student_achievements where student_id = sid) into before;
  r := _kb_submit(p_token, p_cleared, p_won, p_seconds)::jsonb;
  update game_plays set kb_secs = p_seconds
   where id = (select id from game_plays where student_id = sid and game = 'kb' order by created_at desc, id limit 1);

  if p_won and not coalesce((r->>'no_reward')::boolean, false) then
    select count(*) into w from game_plays where student_id = sid and game = 'kb' and score = 100 and (exp > 0 or coins > 0);
    -- ยาสุ่ม 1 ชิ้นทุกครั้งที่ชนะ
    select * into pot from consumables where key in ('p_exp','p_coin','p_luck','p_str','p_int') and active order by random() limit 1;
    if pot.id is not null then
      insert into student_items (student_id, item_id, qty) values (sid, pot.id, 1)
        on conflict (student_id, item_id) do update set qty = student_items.qty + 1;
      drops := drops || jsonb_build_array(jsonb_build_object('emoji', pot.emoji, 'name', pot.name, 'qty', 1));
    end if;
    -- ม้วนอัปเกรด: ชนะครั้งแรก 1 · ครั้งที่ 3 → 1 · ทุก 5 ครั้ง → 2
    sc := case when w = 1 then 1 when w = 3 then 1 when w >= 5 and w % 5 = 0 then 2 else 0 end;
    if sc > 0 then
      select id into cid from consumables where key = 'scroll';
      if cid is not null then
        insert into student_items (student_id, item_id, qty) values (sid, cid, sc)
          on conflict (student_id, item_id) do update set qty = student_items.qty + sc;
        drops := drops || jsonb_build_array(jsonb_build_object('emoji', '📜', 'name', 'ม้วนอัปเกรด', 'qty', sc));
      end if;
    end if;
    -- ฉายา (ชนะครั้งแรก) · กรอบแชมป์ (ชนะ 10 ครั้ง)
    if w >= 1 then
      select id into did from decor_items where slot = 'title' and name = 'ผู้พิชิตครูบุ๊ค';
      if did is not null then
        insert into student_decor (student_id, item_id, source) values (sid, did, 'kb') on conflict do nothing;
        if found then decs := decs || jsonb_build_array(jsonb_build_object('emoji', '🏆', 'name', 'ฉายา ผู้พิชิตครูบุ๊ค')); end if;
      end if;
    end if;
    if w >= 10 then
      select id into did from decor_items where slot = 'frame' and name = 'กรอบแชมป์ครูบุ๊ค';
      if did is not null then
        insert into student_decor (student_id, item_id, source) values (sid, did, 'kb') on conflict do nothing;
        if found then decs := decs || jsonb_build_array(jsonb_build_object('emoji', '🥇', 'name', 'กรอบแชมป์ครูบุ๊ค')); end if;
      end if;
    end if;
    r := r || jsonb_build_object('wins', w);
  end if;

  perform check_achievements(sid);
  select coalesce(jsonb_agg(jsonb_build_object('emoji', a.emoji, 'name', a.name, 'exp', a.reward_exp, 'coins', a.reward_coins) order by a.threshold), '[]'::jsonb) into ach
    from student_achievements sa join achievements a on a.id = sa.achievement_id
   where sa.student_id = sid and a.metric like 'kb\_%' and sa.achievement_id <> all (before);
  return (r || jsonb_build_object('drops', drops, 'decors', decs, 'ach', ach))::json;
end $$;
revoke execute on function kb_submit(uuid, int, boolean, int) from public;
grant execute on function kb_submit(uuid, int, boolean, int) to anon, authenticated;
-- 77: คลังข้อสอบเคมีอินทรีย์ ม.6 จำนวน 300 ข้อ (v2.18) · รันซ้ำได้ (ข้อที่โจทย์ + หัวข้อซ้ำจะไม่ถูกเพิ่มอีก)
--  · ชนิด: เลือกตอบ / จริง-เท็จ / จับคู่ / ลากวาง · มีเฉลยอธิบายทุกข้อ · แยก 13 หัวข้อ
--  · แอลเคนและการเรียกชื่อ 24 · แอลคีนและแอลไคน์ 25 · อะโรมาติกไฮโดรคาร์บอน 20 · ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน 25 · แอลกอฮอล์และอีเทอร์ 25 · แอลดีไฮด์และคีโตน 23 · กรดคาร์บอกซิลิกและเอสเทอร์ 25 · เอมีนและเอไมด์ 20 · หมู่ฟังก์ชันและเฮโลแอลเคน 22 · พอลิเมอร์ 24 · คาร์โบไฮเดรต 23 · กรดอะมิโนและโปรตีน 21 · ลิพิดและกรดนิวคลีอิก 23
--  · อยู่ใน 'คลังข้อสอบ' แท็บ 📝 ข้อสอบ ครูเลือกข้อเข้าชุดสอบได้เอง

insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$สูตรทั่วไปของแอลเคนสายเปิดคือข้อใด$t$, $j${"choices": [{"t": "CnH2n"}, {"t": "CnH2n-2"}, {"t": "CnHn"}, {"t": "CnH2n+2"}], "answer": 3}$j$::jsonb, 1, $t$แอลเคนสายเปิดเป็นสารอิ่มตัว มี H = 2n+2$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$สูตรทั่วไปของแอลเคนสายเปิดคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$แอลเคนที่มีคาร์บอน 8 อะตอมมีสูตรโมเลกุลใด$t$, $j${"choices": [{"t": "C8H18"}, {"t": "C8H14"}, {"t": "C8H16"}, {"t": "C8H20"}], "answer": 0}$j$::jsonb, 1, $t$n = 8 → H = 2(8)+2 = 18$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$แอลเคนที่มีคาร์บอน 8 อะตอมมีสูตรโมเลกุลใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$แอลเคนสายตรงที่มีคาร์บอน 5 อะตอมชื่อว่าอะไร$t$, $j${"choices": [{"t": "เพนเทน"}, {"t": "เพนทีน"}, {"t": "เฮกเซน"}, {"t": "บิวเทน"}], "answer": 0}$j$::jsonb, 1, $t$C1-C5 คือ มีเทน อีเทน โพรเพน บิวเทน เพนเทน$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$แอลเคนสายตรงที่มีคาร์บอน 5 อะตอมชื่อว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$CH3CH(CH3)CH2CH3 มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "3-เมทิลบิวเทน"}, {"t": "เพนเทน"}, {"t": "2-เมทิลโพรเพน"}, {"t": "2-เมทิลบิวเทน"}], "answer": 3}$j$::jsonb, 1, $t$โซ่หลักยาว 4 C (บิวเทน) มีเมทิลที่ C2$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$CH3CH(CH3)CH2CH3 มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$(CH3)3C-CH3 มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "2-เมทิลบิวเทน"}, {"t": "1,1-ไดเมทิลโพรเพน"}, {"t": "เพนเทน"}, {"t": "2,2-ไดเมทิลโพรเพน"}], "answer": 3}$j$::jsonb, 1, $t$โซ่หลัก 3 C มีเมทิล 2 หมู่ที่ C2$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$(CH3)3C-CH3 มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$หมู่อัลคิลที่ได้จากเอทเทน (ตัด H ออก 1 อะตอม) คือข้อใด$t$, $j${"choices": [{"t": "เอทิล"}, {"t": "โพรพิล"}, {"t": "เมทิล"}, {"t": "บิวทิล"}], "answer": 0}$j$::jsonb, 1, $t$-CH2CH3 เรียกเอทิล$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$หมู่อัลคิลที่ได้จากเอทเทน (ตัด H ออก 1 อะตอม) คือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$หมู่ -CH(CH3)2 มีชื่อเรียกว่าอะไร$t$, $j${"choices": [{"t": "เอทิล"}, {"t": "ไอโซโพรพิล"}, {"t": "บิวทิล"}, {"t": "โพรพิล"}], "answer": 1}$j$::jsonb, 1, $t$หมู่โพรพิลที่ต่อที่คาร์บอนตัวกลางเรียกไอโซโพรพิล$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$หมู่ -CH(CH3)2 มีชื่อเรียกว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$แอลเคนข้อใดมีจุดเดือดสูงที่สุด (เปรียบเทียบไอโซเมอร์ C5H12)$t$, $j${"choices": [{"t": "2-เมทิลบิวเทน"}, {"t": "2,2-ไดเมทิลโพรเพน"}, {"t": "เพนเทน"}, {"t": "ทุกตัวเท่ากัน"}], "answer": 2}$j$::jsonb, 1, $t$โซ่ตรงมีพื้นที่ผิวสัมผัสมากกว่า แรงลอนดอนมากกว่า จุดเดือดสูงกว่าไอโซเมอร์ที่แตกกิ่ง$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$แอลเคนข้อใดมีจุดเดือดสูงที่สุด (เปรียบเทียบไอโซเมอร์ C5H12)$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$เหตุใดแอลเคนจึงไม่ละลายน้ำ$t$, $j${"choices": [{"t": "แอลเคนทำปฏิกิริยากับน้ำจนหมด"}, {"t": "แอลเคนมีมวลโมเลกุลน้อยเกินไป"}, {"t": "แอลเคนเป็นไอออนิก"}, {"t": "แอลเคนไม่มีขั้ว แต่น้ำมีขั้ว"}], "answer": 3}$j$::jsonb, 1, $t$สารไม่มีขั้วไม่ละลายในตัวทำละลายมีขั้ว (like dissolves like)$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$เหตุใดแอลเคนจึงไม่ละลายน้ำ$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$แอลเคนที่มีคาร์บอน 1-4 อะตอมมีสถานะใดที่อุณหภูมิห้อง$t$, $j${"choices": [{"t": "ของแข็ง"}, {"t": "แก๊ส"}, {"t": "พลาสมา"}, {"t": "ของเหลว"}], "answer": 1}$j$::jsonb, 1, $t$C1-C4 มีมวลโมเลกุลน้อย แรงลอนดอนน้อย จุดเดือดต่ำกว่าอุณหภูมิห้อง$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$แอลเคนที่มีคาร์บอน 1-4 อะตอมมีสถานะใดที่อุณหภูมิห้อง$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$เมื่อจำนวนคาร์บอนในแอลเคนสายตรงเพิ่มขึ้น จุดเดือดเปลี่ยนแปลงอย่างไร$t$, $j${"choices": [{"t": "ต่ำลง เพราะพันธะอ่อนลง"}, {"t": "สูงขึ้น เพราะแรงลอนดอนมากขึ้น"}, {"t": "ไม่เปลี่ยนแปลง"}, {"t": "ต่ำลง เพราะขั้วเพิ่มขึ้น"}], "answer": 1}$j$::jsonb, 1, $t$โมเลกุลใหญ่ขึ้นมีแรงยึดเหนี่ยวระหว่างโมเลกุลมากขึ้น$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$เมื่อจำนวนคาร์บอนในแอลเคนสายตรงเพิ่มขึ้น จุดเดือดเปลี่ยนแปลงอย่างไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$ปฏิกิริยาสำคัญของแอลเคนคือข้อใด$t$, $j${"choices": [{"t": "การเผาไหม้และการแทนที่ด้วยฮาโลเจน"}, {"t": "การหมัก"}, {"t": "การเกิดพอลิเมอร์แบบเติม"}, {"t": "การเติมไฮโดรเจน"}], "answer": 0}$j$::jsonb, 1, $t$แอลเคนอิ่มตัว ไม่ให้ปฏิกิริยาการเติม จึงเกิดแทนที่และเผาไหม้$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$ปฏิกิริยาสำคัญของแอลเคนคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$3-เมทิลเฮกเซนมีสูตรโมเลกุลใด$t$, $j${"choices": [{"t": "C8H18"}, {"t": "C7H14"}, {"t": "C7H16"}, {"t": "C6H14"}], "answer": 2}$j$::jsonb, 1, $t$โซ่หลัก 6 C + เมทิล 1 C = 7 C และเป็นแอลเคน → H = 16$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$3-เมทิลเฮกเซนมีสูตรโมเลกุลใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$2,3-ไดเมทิลบิวเทนมีไฮโดรเจนกี่อะตอม$t$, $j${"choices": [{"t": "10 อะตอม"}, {"t": "12 อะตอม"}, {"t": "14 อะตอม"}, {"t": "16 อะตอม"}], "answer": 2}$j$::jsonb, 1, $t$C ทั้งหมด 4+2 = 6 → C6H14$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$2,3-ไดเมทิลบิวเทนมีไฮโดรเจนกี่อะตอม$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$CH3CH2CH(CH3)CH2CH3 มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "3-เมทิลเพนเทน"}, {"t": "2-เมทิลเพนเทน"}, {"t": "เฮกเซน"}, {"t": "2-เอทิลบิวเทน"}], "answer": 0}$j$::jsonb, 1, $t$โซ่หลักยาว 5 C เมทิลอยู่ C3$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$CH3CH2CH(CH3)CH2CH3 มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$สูตรทั่วไปของไซโคลแอลเคนคือข้อใด$t$, $j${"choices": [{"t": "CnH2n+2"}, {"t": "CnH2n-2"}, {"t": "CnH2n"}, {"t": "CnH2n-6"}], "answer": 2}$j$::jsonb, 1, $t$การเป็นวงแหวนทำให้ H ลดลง 2 อะตอมเทียบกับแอลเคนสายเปิด$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$สูตรทั่วไปของไซโคลแอลเคนคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$ไซโคลเฮกเซนมีสูตรโมเลกุลใด$t$, $j${"choices": [{"t": "C6H14"}, {"t": "C6H10"}, {"t": "C6H12"}, {"t": "C6H6"}], "answer": 2}$j$::jsonb, 1, $t$CnH2n เมื่อ n = 6$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$ไซโคลเฮกเซนมีสูตรโมเลกุลใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$สารใดต่อไปนี้เป็นแอลเคน$t$, $j${"choices": [{"t": "C3H6"}, {"t": "C6H6"}, {"t": "C3H8"}, {"t": "C2H2"}], "answer": 2}$j$::jsonb, 1, $t$แอลเคนสายเปิดต้องเป็น CnH2n+2$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$สารใดต่อไปนี้เป็นแอลเคน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$แอลเคนมีคาร์บอน 20 อะตอม จะมีไฮโดรเจนกี่อะตอม$t$, $j${"choices": [{"t": "40 อะตอม"}, {"t": "44 อะตอม"}, {"t": "42 อะตอม"}, {"t": "38 อะตอม"}], "answer": 2}$j$::jsonb, 1, $t$2(20)+2 = 42$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$แอลเคนมีคาร์บอน 20 อะตอม จะมีไฮโดรเจนกี่อะตอม$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'tf', $t$แอลเคนเป็นสารไฮโดรคาร์บอนอิ่มตัว$t$, $j${"answer": true}$j$::jsonb, 1, $t$มีเฉพาะพันธะเดี่ยว C-C และ C-H$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$แอลเคนเป็นสารไฮโดรคาร์บอนอิ่มตัว$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'tf', $t$ไซโคลแอลเคนทุกชนิดมีสูตรทั่วไป CnH2n+2$t$, $j${"answer": false}$j$::jsonb, 1, $t$ไซโคลแอลเคนมีสูตร CnH2n ส่วน CnH2n+2 เป็นของแอลเคนสายเปิด$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$ไซโคลแอลเคนทุกชนิดมีสูตรทั่วไป CnH2n+2$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'tf', $t$การเรียกชื่อ IUPAC ต้องเลือกโซ่คาร์บอนต่อเนื่องที่ยาวที่สุดเป็นโซ่หลัก$t$, $j${"answer": true}$j$::jsonb, 1, $t$เป็นหลักการข้อแรกของการเรียกชื่อ$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$การเรียกชื่อ IUPAC ต้องเลือกโซ่คาร์บอนต่อเนื่องที่ยาวที่สุดเป็นโซ่หลัก$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'tf', $t$มีเทนเป็นแอลเคนที่มีมวลโมเลกุลน้อยที่สุด$t$, $j${"answer": true}$j$::jsonb, 1, $t$CH4 มวลโมเลกุล 16$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$มีเทนเป็นแอลเคนที่มีมวลโมเลกุลน้อยที่สุด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'match', $t$จับคู่ชื่อแอลเคนกับสูตรโมเลกุล$t$, $j${"left": [{"t": "มีเทน"}, {"t": "อีเทน"}, {"t": "โพรเพน"}, {"t": "บิวเทน"}], "right": [{"t": "C2H6"}, {"t": "C3H8"}, {"t": "C5H12"}, {"t": "C4H10"}, {"t": "CH4"}], "pairs": [4, 0, 1, 3]}$j$::jsonb, 4, $t$CnH2n+2: n = 1, 2, 3, 4$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$จับคู่ชื่อแอลเคนกับสูตรโมเลกุล$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$สูตรทั่วไปของแอลคีนสายเปิด (มีพันธะคู่ 1 พันธะ) คือข้อใด$t$, $j${"choices": [{"t": "CnH2n"}, {"t": "CnH2n-2"}, {"t": "CnHn"}, {"t": "CnH2n+2"}], "answer": 0}$j$::jsonb, 1, $t$แอลคีน = CnH2n$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$สูตรทั่วไปของแอลคีนสายเปิด (มีพันธะคู่ 1 พันธะ) คือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$สูตรทั่วไปของแอลไคน์สายเปิด (มีพันธะสาม 1 พันธะ) คือข้อใด$t$, $j${"choices": [{"t": "CnH2n-2"}, {"t": "CnH2n-6"}, {"t": "CnH2n+2"}, {"t": "CnH2n"}], "answer": 0}$j$::jsonb, 1, $t$แอลไคน์ = CnH2n-2$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$สูตรทั่วไปของแอลไคน์สายเปิด (มีพันธะสาม 1 พันธะ) คือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$C2H4 มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "เอไทน์"}, {"t": "เอเทน"}, {"t": "เอทานอล"}, {"t": "เอทีน"}], "answer": 3}$j$::jsonb, 1, $t$เอทีน (เอทิลีน) เป็นแอลคีนที่เล็กที่สุด$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$C2H4 มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$C2H2 มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "เบนซีน"}, {"t": "เอไทน์"}, {"t": "เอเทน"}, {"t": "เอทีน"}], "answer": 1}$j$::jsonb, 1, $t$เอไทน์ (อะเซทิลีน) เป็นแอลไคน์ที่เล็กที่สุด$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$C2H2 มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$CH3CH=CH2 มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "โพรไพน์"}, {"t": "ไซโคลโพรเพน"}, {"t": "โพรเพน"}, {"t": "โพรพีน"}], "answer": 3}$j$::jsonb, 1, $t$มีพันธะคู่ 3 คาร์บอน → โพรพีน$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$CH3CH=CH2 มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$CH3C≡CH มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "โพรไพน์"}, {"t": "โพรพีน"}, {"t": "เอไทน์"}, {"t": "โพรเพน"}], "answer": 0}$j$::jsonb, 1, $t$มีพันธะสาม 3 คาร์บอน → โพรไพน์$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$CH3C≡CH มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$CH3CH=CHCH3 มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "บิวเทน"}, {"t": "2-บิวทีน"}, {"t": "1-บิวทีน"}, {"t": "2-บิวไทน์"}], "answer": 1}$j$::jsonb, 1, $t$พันธะคู่อยู่ระหว่างคาร์บอนตำแหน่งที่ 2 และ 3 ให้เลขต่ำสุด = 2$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$CH3CH=CHCH3 มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$ปฏิกิริยาเฉพาะของแอลคีนคือข้อใด$t$, $j${"choices": [{"t": "ปฏิกิริยาการแทนที่"}, {"t": "ปฏิกิริยาการเติม"}, {"t": "ปฏิกิริยาการหมัก"}, {"t": "ปฏิกิริยาสะปอนนิฟิเคชัน"}], "answer": 1}$j$::jsonb, 1, $t$พันธะ π ของ C=C ถูกเปิดออกเพื่อรับอะตอมใหม่$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$ปฏิกิริยาเฉพาะของแอลคีนคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$เติม Br2 ลงในเอทีน ได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "1,1-ไดโบรโมเอเทน"}, {"t": "เอทานอล"}, {"t": "โบรโมเอเทน"}, {"t": "1,2-ไดโบรโมเอเทน"}], "answer": 3}$j$::jsonb, 1, $t$Br ต่อเข้าที่คาร์บอนทั้งสองของพันธะคู่$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$เติม Br2 ลงในเอทีน ได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$การทดสอบสารไม่อิ่มตัวด้วยน้ำโบรมีน จะสังเกตการเปลี่ยนแปลงใด$t$, $j${"choices": [{"t": "สีส้มแดงของน้ำโบรมีนจางหายไป"}, {"t": "เกิดตะกอนสีขาว"}, {"t": "สีเปลี่ยนจากไม่มีสีเป็นน้ำเงิน"}, {"t": "เกิดฟองแก๊สมาก"}], "answer": 0}$j$::jsonb, 1, $t$Br2 ถูกใช้ไปในปฏิกิริยาการเติม สีจึงจางหาย$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$การทดสอบสารไม่อิ่มตัวด้วยน้ำโบรมีน จะสังเกตการเปลี่ยนแปลงใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$ทดสอบแอลคีนด้วยสารละลาย KMnO4 เจือจางที่เป็นเบส จะสังเกตเห็นอะไร$t$, $j${"choices": [{"t": "ไม่มีการเปลี่ยนแปลง"}, {"t": "สีม่วงจางหายไป และเกิดตะกอนสีน้ำตาล"}, {"t": "เกิดตะกอนสีขาว"}, {"t": "สารละลายเป็นสีเหลือง"}], "answer": 1}$j$::jsonb, 1, $t$MnO4- ถูกรีดิวซ์เป็น MnO2 (ตะกอนน้ำตาล)$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$ทดสอบแอลคีนด้วยสารละลาย KMnO4 เจือจางที่เป็นเบส จะสังเกตเห็นอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$การเติม H2 ลงในแอลคีนโดยใช้ Ni หรือ Pt เป็นตัวเร่ง ได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "แอลไคน์"}, {"t": "แอลกอฮอล์"}, {"t": "กรดคาร์บอกซิลิก"}, {"t": "แอลเคน"}], "answer": 3}$j$::jsonb, 1, $t$ไฮโดรจีเนชันทำให้พันธะคู่กลายเป็นพันธะเดี่ยว$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$การเติม H2 ลงในแอลคีนโดยใช้ Ni หรือ Pt เป็นตัวเร่ง ได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$เติม HBr ลงในโพรพีน ผลิตภัณฑ์หลักตามกฎของมาร์คอฟนิคอฟคือข้อใด$t$, $j${"choices": [{"t": "โพรเพน"}, {"t": "1,2-ไดโบรโมโพรเพน"}, {"t": "1-โบรโมโพรเพน"}, {"t": "2-โบรโมโพรเพน"}], "answer": 3}$j$::jsonb, 1, $t$H เข้าที่คาร์บอนที่มี H มากกว่า Br จึงไปอยู่ที่ C2$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$เติม HBr ลงในโพรพีน ผลิตภัณฑ์หลักตามกฎของมาร์คอฟนิคอฟคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$เติมน้ำ (H2O) ในสภาวะกรดลงในเอทีน ได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "เอทานัล"}, {"t": "กรดเอทาโนอิก"}, {"t": "เอทานอล"}, {"t": "เอทิลีนไกลคอล"}], "answer": 2}$j$::jsonb, 1, $t$ไฮเดรชันของแอลคีนให้แอลกอฮอล์$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$เติมน้ำ (H2O) ในสภาวะกรดลงในเอทีน ได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$เติม H2 ให้ครบ (มากเกินพอ) ลงในเอไทน์ ได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "เอทานอล"}, {"t": "เบนซีน"}, {"t": "เอเทน"}, {"t": "เอทีน"}], "answer": 2}$j$::jsonb, 1, $t$พันธะสามรับ H2 2 โมล กลายเป็นพันธะเดี่ยว$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$เติม H2 ให้ครบ (มากเกินพอ) ลงในเอไทน์ ได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$พันธะระหว่างคาร์บอนในเอไทน์ประกอบด้วยพันธะชนิดใดบ้าง$t$, $j${"choices": [{"t": "ซิกมา 3 พันธะ"}, {"t": "พาย 3 พันธะ"}, {"t": "ซิกมา 2 พันธะ และพาย 1 พันธะ"}, {"t": "ซิกมา 1 พันธะ และพาย 2 พันธะ"}], "answer": 3}$j$::jsonb, 1, $t$พันธะสามคือ 1σ + 2π$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$พันธะระหว่างคาร์บอนในเอไทน์ประกอบด้วยพันธะชนิดใดบ้าง$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$มุมพันธะรอบคาร์บอนของเอทีนมีค่าประมาณเท่าใด$t$, $j${"choices": [{"t": "90 องศา"}, {"t": "120 องศา"}, {"t": "180 องศา"}, {"t": "109.5 องศา"}], "answer": 1}$j$::jsonb, 1, $t$คาร์บอนไฮบริไดซ์แบบ sp2 รูปร่างสามเหลี่ยมแบนราบ$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$มุมพันธะรอบคาร์บอนของเอทีนมีค่าประมาณเท่าใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$โมเลกุลเอไทน์มีรูปร่างเป็นอย่างไร$t$, $j${"choices": [{"t": "เส้นตรง (มุม 180 องศา)"}, {"t": "เตตระฮีดรอล"}, {"t": "งอ"}, {"t": "สามเหลี่ยมแบนราบ"}], "answer": 0}$j$::jsonb, 1, $t$คาร์บอน sp ให้มุม H-C≡C เท่ากับ 180°$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$โมเลกุลเอไทน์มีรูปร่างเป็นอย่างไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$1-บิวทีนมีสูตรโมเลกุลใด$t$, $j${"choices": [{"t": "C4H8"}, {"t": "C4H6"}, {"t": "C4H4"}, {"t": "C4H10"}], "answer": 0}$j$::jsonb, 1, $t$แอลคีน CnH2n เมื่อ n = 4$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$1-บิวทีนมีสูตรโมเลกุลใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$เพนต์-1-อีนมีไฮโดรเจนกี่อะตอม$t$, $j${"choices": [{"t": "8 อะตอม"}, {"t": "6 อะตอม"}, {"t": "10 อะตอม"}, {"t": "12 อะตอม"}], "answer": 2}$j$::jsonb, 1, $t$C5H10$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$เพนต์-1-อีนมีไฮโดรเจนกี่อะตอม$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$เฮกไซน์ (C6) มีไฮโดรเจนกี่อะตอม$t$, $j${"choices": [{"t": "14 อะตอม"}, {"t": "8 อะตอม"}, {"t": "10 อะตอม"}, {"t": "12 อะตอม"}], "answer": 2}$j$::jsonb, 1, $t$CnH2n-2 เมื่อ n = 6 → H = 10$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$เฮกไซน์ (C6) มีไฮโดรเจนกี่อะตอม$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'tf', $t$แอลคีนและแอลไคน์จัดเป็นไฮโดรคาร์บอนไม่อิ่มตัว$t$, $j${"answer": true}$j$::jsonb, 1, $t$มีพันธะคู่หรือพันธะสามระหว่างคาร์บอน$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$แอลคีนและแอลไคน์จัดเป็นไฮโดรคาร์บอนไม่อิ่มตัว$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'tf', $t$เอทีนเป็นฮอร์โมนพืชชนิดหนึ่งที่ช่วยให้ผลไม้สุก$t$, $j${"answer": true}$j$::jsonb, 1, $t$เอทิลีน (C2H4) กระตุ้นการสุกของผลไม้$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$เอทีนเป็นฮอร์โมนพืชชนิดหนึ่งที่ช่วยให้ผลไม้สุก$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'tf', $t$แอลไคน์ทุกชนิดมีพันธะสามอยู่ที่ปลายโซ่เท่านั้น$t$, $j${"answer": false}$j$::jsonb, 1, $t$เช่น 2-บิวไทน์ มีพันธะสามอยู่กลางโซ่$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$แอลไคน์ทุกชนิดมีพันธะสามอยู่ที่ปลายโซ่เท่านั้น$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'match', $t$จับคู่ชื่อกับสูตรโมเลกุล$t$, $j${"left": [{"t": "เอทีน"}, {"t": "เอไทน์"}, {"t": "โพรพีน"}, {"t": "โพรไพน์"}], "right": [{"t": "C2H4"}, {"t": "C3H8"}, {"t": "C2H2"}, {"t": "C3H4"}, {"t": "C3H6"}], "pairs": [0, 2, 4, 3]}$j$::jsonb, 4, $t$แอลคีน CnH2n · แอลไคน์ CnH2n-2$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$จับคู่ชื่อกับสูตรโมเลกุล$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$เบนซีนมีสูตรโมเลกุลใด$t$, $j${"choices": [{"t": "C6H6"}, {"t": "C5H6"}, {"t": "C6H12"}, {"t": "C6H14"}], "answer": 0}$j$::jsonb, 1, $t$วงแหวนคาร์บอน 6 อะตอม แต่ละอะตอมต่อกับ H 1 อะตอม$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$เบนซีนมีสูตรโมเลกุลใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$ข้อใดอธิบายโครงสร้างของเบนซีนได้ถูกต้องที่สุด$t$, $j${"choices": [{"t": "มีพันธะเดี่ยวและพันธะคู่สลับกันโดยมีความยาวต่างกัน"}, {"t": "วงแหวนหกเหลี่ยมแบนราบ พันธะ C-C ทุกพันธะยาวเท่ากันเพราะเรโซแนนซ์"}, {"t": "เป็นวงแหวนอิ่มตัวเช่นเดียวกับไซโคลเฮกเซน"}, {"t": "เป็นโซ่ตรงที่มีพันธะคู่ 3 พันธะ"}], "answer": 1}$j$::jsonb, 1, $t$อิเล็กตรอน π แบ่งปันรอบวงแหวน (เรโซแนนซ์)$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$ข้อใดอธิบายโครงสร้างของเบนซีนได้ถูกต้องที่สุด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$ความยาวพันธะ C-C ในเบนซีนเมื่อเทียบกับพันธะเดี่ยวและพันธะคู่ C=C ปกติเป็นอย่างไร$t$, $j${"choices": [{"t": "เท่ากับพันธะคู่"}, {"t": "ยาวกว่าพันธะเดี่ยว"}, {"t": "เท่ากับพันธะเดี่ยว"}, {"t": "อยู่ระหว่างพันธะเดี่ยวกับพันธะคู่"}], "answer": 3}$j$::jsonb, 1, $t$พันธะมีลักษณะกึ่งกลางเนื่องจากเรโซแนนซ์$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$ความยาวพันธะ C-C ในเบนซีนเมื่อเทียบกับพันธะเดี่ยวและพันธะคู่ C=C ปกติเป็นอย่างไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$ปฏิกิริยาที่เบนซีนเกิดได้ง่ายที่สุดคือข้อใด$t$, $j${"choices": [{"t": "ปฏิกิริยาการแทนที่"}, {"t": "ปฏิกิริยาการเติม"}, {"t": "ปฏิกิริยาการหมัก"}, {"t": "ปฏิกิริยาการเกิดเอสเทอร์"}], "answer": 0}$j$::jsonb, 1, $t$ต้องการรักษาระบบเรโซแนนซ์ของวงแหวน$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$ปฏิกิริยาที่เบนซีนเกิดได้ง่ายที่สุดคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$เบนซีนทำปฏิกิริยากับ Br2 โดยมี FeBr3 เป็นตัวเร่ง ได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "โบรโมเบนซีนและ HBr"}, {"t": "เฮกเซน"}, {"t": "1,2-ไดโบรโมไซโคลเฮกเซน"}, {"t": "ฟีนอล"}], "answer": 0}$j$::jsonb, 1, $t$เป็นปฏิกิริยาการแทนที่ H ด้วย Br$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$เบนซีนทำปฏิกิริยากับ Br2 โดยมี FeBr3 เป็นตัวเร่ง ได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$เบนซีนทำปฏิกิริยากับกรดไนตริกและกรดซัลฟิวริกเข้มข้น ได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "ไนโตรเบนซีน"}, {"t": "โทลูอีน"}, {"t": "ไซโคลเฮกเซน"}, {"t": "แอนิลีน"}], "answer": 0}$j$::jsonb, 1, $t$ปฏิกิริยาไนเตรชัน ใส่หมู่ -NO2$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$เบนซีนทำปฏิกิริยากับกรดไนตริกและกรดซัลฟิวริกเข้มข้น ได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$โทลูอีนมีสูตรโมเลกุลใด$t$, $j${"choices": [{"t": "C8H10"}, {"t": "C6H6"}, {"t": "C7H8"}, {"t": "C7H14"}], "answer": 2}$j$::jsonb, 1, $t$C6H5CH3 = C7H8$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$โทลูอีนมีสูตรโมเลกุลใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$ฟีนอลมีสูตรโครงสร้างตามข้อใด$t$, $j${"choices": [{"t": "C6H5CH3"}, {"t": "C6H5OH"}, {"t": "C6H5COOH"}, {"t": "C6H5NH2"}], "answer": 1}$j$::jsonb, 1, $t$หมู่ -OH ต่อกับวงแหวนเบนซีน$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$ฟีนอลมีสูตรโครงสร้างตามข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$แอนิลีนมีหมู่ฟังก์ชันใดต่ออยู่กับวงแหวนเบนซีน$t$, $j${"choices": [{"t": "หมู่ไนโตร (-NO2)"}, {"t": "หมู่เมทิล (-CH3)"}, {"t": "หมู่ไฮดรอกซิล (-OH)"}, {"t": "หมู่อะมิโน (-NH2)"}], "answer": 3}$j$::jsonb, 1, $t$แอนิลีน = C6H5NH2$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$แอนิลีนมีหมู่ฟังก์ชันใดต่ออยู่กับวงแหวนเบนซีน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$ไดเมทิลเบนซีน (ไซลีน) มีไอโซเมอร์ตำแหน่งกี่แบบ$t$, $j${"choices": [{"t": "3 แบบ (ออร์โท เมทา พารา)"}, {"t": "4 แบบ"}, {"t": "1 แบบ"}, {"t": "2 แบบ"}], "answer": 0}$j$::jsonb, 1, $t$หมู่เมทิล 2 หมู่บนวงแหวนอยู่ตำแหน่ง 1,2 / 1,3 / 1,4$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$ไดเมทิลเบนซีน (ไซลีน) มีไอโซเมอร์ตำแหน่งกี่แบบ$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$หมู่แทนที่สองหมู่บนวงแหวนเบนซีนที่อยู่ตำแหน่ง 1,4 เรียกว่าอะไร$t$, $j${"choices": [{"t": "เมทา (meta)"}, {"t": "ไอโซ (iso)"}, {"t": "พารา (para)"}, {"t": "ออร์โท (ortho)"}], "answer": 2}$j$::jsonb, 1, $t$1,2 = ออร์โท · 1,3 = เมทา · 1,4 = พารา$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$หมู่แทนที่สองหมู่บนวงแหวนเบนซีนที่อยู่ตำแหน่ง 1,4 เรียกว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$สารใดต่อไปนี้เป็นสารประกอบอะโรมาติก$t$, $j${"choices": [{"t": "โทลูอีน"}, {"t": "1-เฮกซีน"}, {"t": "เฮกเซน"}, {"t": "ไซโคลเฮกเซน"}], "answer": 0}$j$::jsonb, 1, $t$มีวงแหวนเบนซีน$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$สารใดต่อไปนี้เป็นสารประกอบอะโรมาติก$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$อัตราส่วนอะตอม C : H ของเบนซีนเท่ากับเท่าใด (สูตรเอมพิริคัล)$t$, $j${"choices": [{"t": "2 : 1"}, {"t": "1 : 2"}, {"t": "1 : 3"}, {"t": "1 : 1 (CH)"}], "answer": 3}$j$::jsonb, 1, $t$C6H6 ลดทอนเป็น CH$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$อัตราส่วนอะตอม C : H ของเบนซีนเท่ากับเท่าใด (สูตรเอมพิริคัล)$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$แนฟทาลีนมีสูตรโมเลกุลใด$t$, $j${"choices": [{"t": "C6H6"}, {"t": "C10H8"}, {"t": "C12H10"}, {"t": "C10H18"}], "answer": 1}$j$::jsonb, 1, $t$วงแหวนเบนซีน 2 วงหลอมรวมกัน$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$แนฟทาลีนมีสูตรโมเลกุลใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$มวลโมเลกุลของเบนซีน (C=12, H=1) เท่ากับเท่าใด$t$, $j${"choices": [{"t": "78"}, {"t": "72"}, {"t": "84"}, {"t": "66"}], "answer": 0}$j$::jsonb, 1, $t$6×12 + 6×1 = 78$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$มวลโมเลกุลของเบนซีน (C=12, H=1) เท่ากับเท่าใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$สไตรีน (ไวนิลเบนซีน, C6H5CH=CH2) มีสูตรโมเลกุลใด$t$, $j${"choices": [{"t": "C7H8"}, {"t": "C8H10"}, {"t": "C8H8"}, {"t": "C8H6"}], "answer": 2}$j$::jsonb, 1, $t$วงแหวน C6H5 + CH=CH2 → C8H8$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$สไตรีน (ไวนิลเบนซีน, C6H5CH=CH2) มีสูตรโมเลกุลใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'tf', $t$เบนซีนทำปฏิกิริยาการเติมกับ Br2 ได้ง่ายเหมือนแอลคีน$t$, $j${"answer": false}$j$::jsonb, 1, $t$เบนซีนเสถียรกว่าเพราะเรโซแนนซ์ จึงเกิดแทนที่แทนการเติม$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$เบนซีนทำปฏิกิริยาการเติมกับ Br2 ได้ง่ายเหมือนแอลคีน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'tf', $t$น้ำโบรมีนไม่จางสีเมื่อเขย่ากับเบนซีนที่อุณหภูมิห้อง$t$, $j${"answer": true}$j$::jsonb, 1, $t$เบนซีนไม่ทำปฏิกิริยาการเติมในสภาวะนี้$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$น้ำโบรมีนไม่จางสีเมื่อเขย่ากับเบนซีนที่อุณหภูมิห้อง$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'tf', $t$เบนซีนเป็นสารก่อมะเร็ง ควรหลีกเลี่ยงการสูดดมและสัมผัส$t$, $j${"answer": true}$j$::jsonb, 1, $t$เบนซีนเป็นสารก่อมะเร็งในมนุษย์$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$เบนซีนเป็นสารก่อมะเร็ง ควรหลีกเลี่ยงการสูดดมและสัมผัส$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'match', $t$จับคู่ชื่อสารอะโรมาติกกับสูตร$t$, $j${"left": [{"t": "เบนซีน"}, {"t": "โทลูอีน"}, {"t": "ฟีนอล"}, {"t": "แอนิลีน"}], "right": [{"t": "C6H5CH3"}, {"t": "C6H6"}, {"t": "C6H5NH2"}, {"t": "C6H5COOH"}, {"t": "C6H5OH"}], "pairs": [1, 0, 4, 2]}$j$::jsonb, 4, $t$ดูหมู่ที่ต่ออยู่กับวงแหวนเบนซีน$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$จับคู่ชื่อสารอะโรมาติกกับสูตร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$การเผาไหม้ไฮโดรคาร์บอนอย่างสมบูรณ์ให้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "CO2 และ H2"}, {"t": "CO2 และ H2O"}, {"t": "CO และ H2O"}, {"t": "C และ H2"}], "answer": 1}$j$::jsonb, 1, $t$ออกซิเจนเพียงพอ C → CO2, H → H2O$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$การเผาไหม้ไฮโดรคาร์บอนอย่างสมบูรณ์ให้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$การเผาไหม้ไม่สมบูรณ์ของไฮโดรคาร์บอนอาจเกิดสารใดเพิ่ม$t$, $j${"choices": [{"t": "NH3"}, {"t": "SO3"}, {"t": "CO และเขม่า (C)"}, {"t": "O3"}], "answer": 2}$j$::jsonb, 1, $t$ออกซิเจนไม่เพียงพอ$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$การเผาไหม้ไม่สมบูรณ์ของไฮโดรคาร์บอนอาจเกิดสารใดเพิ่ม$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$การเผาไหม้มีเทนสมบูรณ์ CH4 + O2 → CO2 + H2O เมื่อดุลสมการแล้ว ใช้ O2 กี่โมลต่อ CH4 1 โมล$t$, $j${"choices": [{"t": "3 โมล"}, {"t": "1 โมล"}, {"t": "2 โมล"}, {"t": "4 โมล"}], "answer": 2}$j$::jsonb, 1, $t$CH4 + 2O2 → CO2 + 2H2O$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$การเผาไหม้มีเทนสมบูรณ์ CH4 + O2 → CO2 + H2O เมื่อดุลสมการแล้ว ใช้ O2 กี่โมลต่อ CH4 1 โมล$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$เผาโพรเพน (C3H8) 1 โมลอย่างสมบูรณ์ ใช้ O2 กี่โมล$t$, $j${"choices": [{"t": "7 โมล"}, {"t": "5 โมล"}, {"t": "3 โมล"}, {"t": "4 โมล"}], "answer": 1}$j$::jsonb, 1, $t$C3H8 + 5O2 → 3CO2 + 4H2O$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$เผาโพรเพน (C3H8) 1 โมลอย่างสมบูรณ์ ใช้ O2 กี่โมล$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$เผาบิวเทน (C4H10) 1 โมลอย่างสมบูรณ์ ใช้ O2 กี่โมล$t$, $j${"choices": [{"t": "8 โมล"}, {"t": "6.5 โมล"}, {"t": "4 โมล"}, {"t": "5 โมล"}], "answer": 1}$j$::jsonb, 1, $t$C4H10 + 13/2 O2 → 4CO2 + 5H2O$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$เผาบิวเทน (C4H10) 1 โมลอย่างสมบูรณ์ ใช้ O2 กี่โมล$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$เผาอีเทน (C2H6) 1 โมลอย่างสมบูรณ์ ได้ CO2 กี่โมล$t$, $j${"choices": [{"t": "3 โมล"}, {"t": "6 โมล"}, {"t": "1 โมล"}, {"t": "2 โมล"}], "answer": 3}$j$::jsonb, 1, $t$คาร์บอน 2 อะตอมทุกอะตอมกลายเป็น CO2$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$เผาอีเทน (C2H6) 1 โมลอย่างสมบูรณ์ ได้ CO2 กี่โมล$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$เผาเอทีน (C2H4) 1 โมลอย่างสมบูรณ์ ใช้ O2 กี่โมล$t$, $j${"choices": [{"t": "2.5 โมล"}, {"t": "3 โมล"}, {"t": "4 โมล"}, {"t": "2 โมล"}], "answer": 1}$j$::jsonb, 1, $t$C2H4 + 3O2 → 2CO2 + 2H2O$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$เผาเอทีน (C2H4) 1 โมลอย่างสมบูรณ์ ใช้ O2 กี่โมล$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$ไฮโดรคาร์บอนข้อใดเมื่อเผาไหม้แล้วให้เขม่ามากที่สุด$t$, $j${"choices": [{"t": "อีเทน"}, {"t": "เบนซีน"}, {"t": "โพรเพน"}, {"t": "มีเทน"}], "answer": 1}$j$::jsonb, 1, $t$เบนซีนมีร้อยละโดยมวลของคาร์บอนสูงที่สุด จึงเผาไหม้ไม่สมบูรณ์ง่ายและเกิดเขม่า$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$ไฮโดรคาร์บอนข้อใดเมื่อเผาไหม้แล้วให้เขม่ามากที่สุด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$แก๊สพิษที่ไม่มีสีและไม่มีกลิ่น เกิดจากการเผาไหม้ไม่สมบูรณ์คือข้อใด$t$, $j${"choices": [{"t": "SO2"}, {"t": "NO2"}, {"t": "CO2"}, {"t": "CO"}], "answer": 3}$j$::jsonb, 1, $t$CO ไปจับฮีโมโกลบินแทนออกซิเจน$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$แก๊สพิษที่ไม่มีสีและไม่มีกลิ่น เกิดจากการเผาไหม้ไม่สมบูรณ์คือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$ปฏิกิริยาแทนที่ของมีเทนกับคลอรีนต้องมีสภาวะใด$t$, $j${"choices": [{"t": "ตัวเร่ง Ni"}, {"t": "กรดซัลฟิวริกเข้มข้น"}, {"t": "ความเย็นจัด"}, {"t": "แสงอัลตราไวโอเลต"}], "answer": 3}$j$::jsonb, 1, $t$แสง UV ทำให้ Cl2 แตกเป็นอนุมูล$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$ปฏิกิริยาแทนที่ของมีเทนกับคลอรีนต้องมีสภาวะใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$ผลิตภัณฑ์ขั้นแรกของ CH4 + Cl2 (แสง) คือข้อใด$t$, $j${"choices": [{"t": "CCl4 เท่านั้น"}, {"t": "CH3Cl และ HCl"}, {"t": "CH2Cl2 และ H2"}, {"t": "C2H6"}], "answer": 1}$j$::jsonb, 1, $t$แทนที่ H 1 อะตอมด้วย Cl$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$ผลิตภัณฑ์ขั้นแรกของ CH4 + Cl2 (แสง) คือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$ปฏิกิริยาการเติม (addition) มีลักษณะอย่างไร$t$, $j${"choices": [{"t": "สารแตกตัวเป็นโมเลกุลเล็กลง"}, {"t": "อะตอม H ถูกแทนที่ด้วยอะตอมอื่น"}, {"t": "อะตอมหรือหมู่อะตอมเข้าต่อที่พันธะคู่หรือพันธะสาม ได้ผลิตภัณฑ์เพียงชนิดเดียว"}, {"t": "สารสองชนิดรวมกันและเสียน้ำ"}], "answer": 2}$j$::jsonb, 1, $t$พันธะ π ถูกเปิดออก$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$ปฏิกิริยาการเติม (addition) มีลักษณะอย่างไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$ไฮโดรจีเนชันคือปฏิกิริยาที่เติมสารใด$t$, $j${"choices": [{"t": "ไฮโดรเจนเฮไลด์ (HX)"}, {"t": "น้ำ (H2O)"}, {"t": "ออกซิเจน (O2)"}, {"t": "ไฮโดรเจน (H2)"}], "answer": 3}$j$::jsonb, 1, $t$hydro = ไฮโดรเจน$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$ไฮโดรจีเนชันคือปฏิกิริยาที่เติมสารใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$เติม Cl2 ลงในเอไทน์ 2 โมล (มากเกินพอ) ได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "1,1-ไดคลอโรเอเทน"}, {"t": "คลอโรเอเทน"}, {"t": "1,1,2,2-เตตระคลอโรเอเทน"}, {"t": "1,2-ไดคลอโรเอทีน"}], "answer": 2}$j$::jsonb, 1, $t$พันธะสามรับ Cl2 2 โมล กลายเป็นพันธะเดี่ยว$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$เติม Cl2 ลงในเอไทน์ 2 โมล (มากเกินพอ) ได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$เผา CH4 1 ลิตรอย่างสมบูรณ์ที่ T และ P เดียวกัน ได้ CO2 กี่ลิตร$t$, $j${"choices": [{"t": "1 ลิตร"}, {"t": "2 ลิตร"}, {"t": "0.5 ลิตร"}, {"t": "3 ลิตร"}], "answer": 0}$j$::jsonb, 1, $t$CH4 : CO2 = 1 : 1 โดยโมล (และโดยปริมาตรของแก๊ส)$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$เผา CH4 1 ลิตรอย่างสมบูรณ์ที่ T และ P เดียวกัน ได้ CO2 กี่ลิตร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$เผา C2H6 1 ลิตรอย่างสมบูรณ์ต้องใช้ O2 กี่ลิตรที่ T และ P เดียวกัน$t$, $j${"choices": [{"t": "2 ลิตร"}, {"t": "3.5 ลิตร"}, {"t": "7 ลิตร"}, {"t": "5 ลิตร"}], "answer": 1}$j$::jsonb, 1, $t$C2H6 + 7/2 O2 → 2CO2 + 3H2O$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$เผา C2H6 1 ลิตรอย่างสมบูรณ์ต้องใช้ O2 กี่ลิตรที่ T และ P เดียวกัน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$องค์ประกอบหลักของแก๊สธรรมชาติคือข้อใด$t$, $j${"choices": [{"t": "เบนซีน"}, {"t": "ออกซิเจน"}, {"t": "มีเทน"}, {"t": "เอทีน"}], "answer": 2}$j$::jsonb, 1, $t$มีเทนประมาณ 70-95%$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$องค์ประกอบหลักของแก๊สธรรมชาติคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$แก๊สหุงต้ม (LPG) ประกอบด้วยไฮโดรคาร์บอนหลักชนิดใด$t$, $j${"choices": [{"t": "เอทีนและโพรพีน"}, {"t": "เบนซีนและโทลูอีน"}, {"t": "โพรเพนและบิวเทน"}, {"t": "มีเทนและอีเทน"}], "answer": 2}$j$::jsonb, 1, $t$อัดเป็นของเหลวภายใต้ความดัน$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$แก๊สหุงต้ม (LPG) ประกอบด้วยไฮโดรคาร์บอนหลักชนิดใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$น้ำมันดิบถูกแยกเป็นส่วนต่างๆ ด้วยกระบวนการใด$t$, $j${"choices": [{"t": "การกลั่นลำดับส่วน"}, {"t": "การกรอง"}, {"t": "การตกผลึก"}, {"t": "การระเหิด"}], "answer": 0}$j$::jsonb, 1, $t$แยกตามความแตกต่างของจุดเดือด$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$น้ำมันดิบถูกแยกเป็นส่วนต่างๆ ด้วยกระบวนการใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$ผลิตภัณฑ์จากการกลั่นน้ำมันดิบส่วนใดมีจุดเดือดต่ำสุด$t$, $j${"choices": [{"t": "แอสฟอลต์"}, {"t": "น้ำมันดีเซล"}, {"t": "น้ำมันหล่อลื่น"}, {"t": "แก๊สปิโตรเลียม"}], "answer": 3}$j$::jsonb, 1, $t$โมเลกุลเล็กที่สุด (C1-C4)$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$ผลิตภัณฑ์จากการกลั่นน้ำมันดิบส่วนใดมีจุดเดือดต่ำสุด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$ค่าออกเทนของน้ำมันเบนซินบอกสมบัติใด$t$, $j${"choices": [{"t": "ปริมาณกำมะถัน"}, {"t": "ความสามารถในการต้านการน็อกของเครื่องยนต์"}, {"t": "ปริมาณน้ำ"}, {"t": "จุดเยือกแข็ง"}], "answer": 1}$j$::jsonb, 1, $t$ออกเทนสูงจุดระเบิดช้ากว่า น็อกน้อยลง$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$ค่าออกเทนของน้ำมันเบนซินบอกสมบัติใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'tf', $t$การแตกสลายด้วยความร้อน (cracking) เปลี่ยนไฮโดรคาร์บอนโมเลกุลใหญ่ให้เป็นโมเลกุลเล็กลง$t$, $j${"answer": true}$j$::jsonb, 1, $t$เพิ่มปริมาณน้ำมันเบนซินและแอลคีน$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$การแตกสลายด้วยความร้อน (cracking) เปลี่ยนไฮโดรคาร์บอนโมเลกุลใหญ่ให้เป็นโมเลกุลเล็กลง$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'tf', $t$การเผาไหม้ของไฮโดรคาร์บอนเป็นปฏิกิริยาดูดความร้อน$t$, $j${"answer": false}$j$::jsonb, 1, $t$เป็นปฏิกิริยาคายความร้อน ใช้เป็นเชื้อเพลิง$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$การเผาไหม้ของไฮโดรคาร์บอนเป็นปฏิกิริยาดูดความร้อน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'tf', $t$แอลเคนทำปฏิกิริยาการเติมกับ Br2 ได้ในที่มืด$t$, $j${"answer": false}$j$::jsonb, 1, $t$แอลเคนอิ่มตัว ไม่เกิดการเติม ต้องแทนที่ด้วยแสง$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$แอลเคนทำปฏิกิริยาการเติมกับ Br2 ได้ในที่มืด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'match', $t$จับคู่สารตั้งต้นกับชนิดของปฏิกิริยา$t$, $j${"left": [{"t": "CH4 + Cl2 (แสง)"}, {"t": "CH2=CH2 + Br2"}, {"t": "C3H8 + O2 (มากเกินพอ)"}, {"t": "C6H14 (ความร้อนสูง/ตัวเร่ง)"}], "right": [{"t": "การหมัก"}, {"t": "การแทนที่"}, {"t": "การเผาไหม้"}, {"t": "การแตกสลาย"}, {"t": "การเติม"}], "pairs": [1, 4, 2, 3]}$j$::jsonb, 4, $t$สอดคล้องกับลักษณะของปฏิกิริยา$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$จับคู่สารตั้งต้นกับชนิดของปฏิกิริยา$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$หมู่ฟังก์ชันของแอลกอฮอล์คือข้อใด$t$, $j${"choices": [{"t": "-OH (ไฮดรอกซิล)"}, {"t": "-COOH"}, {"t": "-CHO"}, {"t": "-O- (ระหว่างคาร์บอน)"}], "answer": 0}$j$::jsonb, 1, $t$แอลกอฮอล์มี -OH ต่อกับคาร์บอนอิ่มตัว$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$หมู่ฟังก์ชันของแอลกอฮอล์คือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$CH3CH2OH มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "เอทานอยด์"}, {"t": "เอทานอล"}, {"t": "เอทานัล"}, {"t": "เมทานอล"}], "answer": 1}$j$::jsonb, 1, $t$2 คาร์บอน + ลงท้าย -ออล$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$CH3CH2OH มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$CH3CH2CH2OH มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "โพรพานัล"}, {"t": "โพรพาโนน"}, {"t": "1-โพรพานอล"}, {"t": "2-โพรพานอล"}], "answer": 2}$j$::jsonb, 1, $t$OH อยู่ที่คาร์บอนปลายโซ่ (C1)$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$CH3CH2CH2OH มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$CH3CH(OH)CH3 มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "2-โพรพานอล"}, {"t": "ไดเมทิลอีเทอร์"}, {"t": "โพรพานัล"}, {"t": "1-โพรพานอล"}], "answer": 0}$j$::jsonb, 1, $t$OH อยู่ที่ C2$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$CH3CH(OH)CH3 มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$แอลกอฮอล์ปฐมภูมิ (1°) หมายถึงข้อใด$t$, $j${"choices": [{"t": "คาร์บอนที่ต่อกับ -OH ต่ออยู่กับคาร์บอนอื่น 3 อะตอม"}, {"t": "มี -OH 1 หมู่ในโมเลกุลเท่านั้น"}, {"t": "คาร์บอนที่ต่อกับ -OH ต่ออยู่กับคาร์บอนอื่น 2 อะตอม"}, {"t": "คาร์บอนที่ต่อกับ -OH ต่ออยู่กับคาร์บอนอื่นอีก 1 อะตอม"}], "answer": 3}$j$::jsonb, 1, $t$นับจำนวนคาร์บอนที่ต่อกับคาร์บอนที่มี -OH$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$แอลกอฮอล์ปฐมภูมิ (1°) หมายถึงข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$2-โพรพานอลจัดเป็นแอลกอฮอล์ประเภทใด$t$, $j${"choices": [{"t": "ทุติยภูมิ (2°)"}, {"t": "ปฐมภูมิ (1°)"}, {"t": "ตติยภูมิ (3°)"}, {"t": "ไม่จัดเป็นแอลกอฮอล์"}], "answer": 0}$j$::jsonb, 1, $t$C2 ต่อกับคาร์บอนอื่น 2 อะตอม$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$2-โพรพานอลจัดเป็นแอลกอฮอล์ประเภทใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$2-เมทิล-2-โพรพานอลจัดเป็นแอลกอฮอล์ประเภทใด$t$, $j${"choices": [{"t": "ตติยภูมิ (3°)"}, {"t": "ไม่ใช่แอลกอฮอล์"}, {"t": "ทุติยภูมิ (2°)"}, {"t": "ปฐมภูมิ (1°)"}], "answer": 0}$j$::jsonb, 1, $t$คาร์บอนที่มี -OH ต่อกับคาร์บอนอื่น 3 อะตอม$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$2-เมทิล-2-โพรพานอลจัดเป็นแอลกอฮอล์ประเภทใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$เหตุใดเอทานอลมีจุดเดือดสูงกว่าไดเมทิลอีเทอร์ ทั้งที่เป็นไอโซเมอร์กัน$t$, $j${"choices": [{"t": "ไดเมทิลอีเทอร์เป็นไอออนิก"}, {"t": "เอทานอลสร้างพันธะไฮโดรเจนระหว่างโมเลกุลได้"}, {"t": "เอทานอลมีมวลโมเลกุลมากกว่า"}, {"t": "เอทานอลมีพันธะคู่"}], "answer": 1}$j$::jsonb, 1, $t$อีเทอร์ไม่มี O-H จึงไม่เกิดพันธะไฮโดรเจนระหว่างโมเลกุลกันเอง$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$เหตุใดเอทานอลมีจุดเดือดสูงกว่าไดเมทิลอีเทอร์ ทั้งที่เป็นไอโซเมอร์กัน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$แอลกอฮอล์ที่มีคาร์บอนน้อยๆ (เช่น เมทานอล เอทานอล) ละลายน้ำได้ดีเพราะเหตุใด$t$, $j${"choices": [{"t": "สร้างพันธะไฮโดรเจนกับน้ำได้"}, {"t": "มีพันธะไอออนิก"}, {"t": "มีมวลโมเลกุลมาก"}, {"t": "เป็นสารไม่มีขั้ว"}], "answer": 0}$j$::jsonb, 1, $t$หมู่ -OH มีขั้วและสร้างพันธะไฮโดรเจนกับน้ำ$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$แอลกอฮอล์ที่มีคาร์บอนน้อยๆ (เช่น เมทานอล เอทานอล) ละลายน้ำได้ดีเพราะเหตุใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$เมื่อจำนวนคาร์บอนของแอลกอฮอล์สายตรงเพิ่มขึ้น การละลายน้ำเปลี่ยนแปลงอย่างไร$t$, $j${"choices": [{"t": "เพิ่มขึ้น เพราะมีพันธะคู่มากขึ้น"}, {"t": "ไม่เปลี่ยนแปลง"}, {"t": "เพิ่มขึ้น เพราะมวลโมเลกุลมากขึ้น"}, {"t": "ลดลง เพราะส่วนที่ไม่มีขั้ว (ไฮโดรคาร์บอน) ยาวขึ้น"}], "answer": 3}$j$::jsonb, 1, $t$ส่วนหางที่ไม่มีขั้วมีอิทธิพลมากขึ้น$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$เมื่อจำนวนคาร์บอนของแอลกอฮอล์สายตรงเพิ่มขึ้น การละลายน้ำเปลี่ยนแปลงอย่างไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$แอลกอฮอล์ทำปฏิกิริยากับโลหะโซเดียมให้แก๊สใด$t$, $j${"choices": [{"t": "H2"}, {"t": "Cl2"}, {"t": "O2"}, {"t": "CO2"}], "answer": 0}$j$::jsonb, 1, $t$2ROH + 2Na → 2RONa + H2$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$แอลกอฮอล์ทำปฏิกิริยากับโลหะโซเดียมให้แก๊สใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$การออกซิไดส์แอลกอฮอล์ปฐมภูมิอย่างอ่อนให้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "เอสเทอร์"}, {"t": "แอลคีน"}, {"t": "คีโตน"}, {"t": "แอลดีไฮด์"}], "answer": 3}$j$::jsonb, 1, $t$RCH2OH → RCHO$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$การออกซิไดส์แอลกอฮอล์ปฐมภูมิอย่างอ่อนให้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$การออกซิไดส์แอลกอฮอล์ทุติยภูมิให้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "คีโตน"}, {"t": "อีเทอร์"}, {"t": "กรดคาร์บอกซิลิก"}, {"t": "แอลดีไฮด์"}], "answer": 0}$j$::jsonb, 1, $t$R2CHOH → R2C=O$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$การออกซิไดส์แอลกอฮอล์ทุติยภูมิให้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$แอลกอฮอล์ตติยภูมิถูกออกซิไดส์ด้วยตัวออกซิไดส์ทั่วไปได้หรือไม่$t$, $j${"choices": [{"t": "ได้เป็นกรดคาร์บอกซิลิก"}, {"t": "ไม่ได้ เพราะคาร์บอนที่มี -OH ไม่มี H"}, {"t": "ได้เป็นคีโตน"}, {"t": "ได้เป็นแอลดีไฮด์"}], "answer": 1}$j$::jsonb, 1, $t$ไม่มี H ที่คาร์บอนให้ถูกดึงออก$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$แอลกอฮอล์ตติยภูมิถูกออกซิไดส์ด้วยตัวออกซิไดส์ทั่วไปได้หรือไม่$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$การออกซิไดส์เอทานอลอย่างสมบูรณ์ได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "โพรพาโนน"}, {"t": "เอทานัล"}, {"t": "ไดเอทิลอีเทอร์"}, {"t": "กรดเอทาโนอิก (กรดแอซีติก)"}], "answer": 3}$j$::jsonb, 1, $t$เอทานอล → เอทานัล → กรดเอทาโนอิก$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$การออกซิไดส์เอทานอลอย่างสมบูรณ์ได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$เมื่อทำให้เอทานอลขาดน้ำด้วย H2SO4 เข้มข้นที่ประมาณ 170 องศาเซลเซียส ได้ผลิตภัณฑ์หลักใด$t$, $j${"choices": [{"t": "เอไทน์"}, {"t": "เอทีน"}, {"t": "เอทานัล"}, {"t": "ไดเอทิลอีเทอร์"}], "answer": 1}$j$::jsonb, 1, $t$การกำจัดน้ำภายในโมเลกุล (intramolecular dehydration)$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$เมื่อทำให้เอทานอลขาดน้ำด้วย H2SO4 เข้มข้นที่ประมาณ 170 องศาเซลเซียส ได้ผลิตภัณฑ์หลักใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$เมื่อทำให้เอทานอลขาดน้ำด้วย H2SO4 เข้มข้นที่ประมาณ 140 องศาเซลเซียส ได้ผลิตภัณฑ์หลักใด$t$, $j${"choices": [{"t": "เอทีน"}, {"t": "ไดเอทิลอีเทอร์"}, {"t": "เอทานัล"}, {"t": "เอทิลเอทาโนเอต"}], "answer": 1}$j$::jsonb, 1, $t$ขาดน้ำระหว่างโมเลกุลสองโมเลกุล$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$เมื่อทำให้เอทานอลขาดน้ำด้วย H2SO4 เข้มข้นที่ประมาณ 140 องศาเซลเซียส ได้ผลิตภัณฑ์หลักใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$กระบวนการหมักน้ำตาลกลูโคสโดยยีสต์ให้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "เอทานอลและ CO2"}, {"t": "กรดแอซีติกและ H2"}, {"t": "เอทีนและ H2O"}, {"t": "เมทานอลและ O2"}], "answer": 0}$j$::jsonb, 1, $t$C6H12O6 → 2C2H5OH + 2CO2$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$กระบวนการหมักน้ำตาลกลูโคสโดยยีสต์ให้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$แอลกอฮอล์ชนิดใดเป็นพิษมาก ดื่มแล้วอาจทำให้ตาบอดหรือเสียชีวิต$t$, $j${"choices": [{"t": "เมทานอล"}, {"t": "น้ำตาล"}, {"t": "กลีเซอรอล"}, {"t": "เอทานอลเจือจาง"}], "answer": 0}$j$::jsonb, 1, $t$เมทานอลถูกเปลี่ยนเป็นฟอร์มาลดีไฮด์และกรดฟอร์มิกในร่างกาย$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$แอลกอฮอล์ชนิดใดเป็นพิษมาก ดื่มแล้วอาจทำให้ตาบอดหรือเสียชีวิต$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$เอทิลีนไกลคอล (1,2-เอทานไดออล) ใช้ประโยชน์ในข้อใด$t$, $j${"choices": [{"t": "เครื่องดื่มบำรุงกำลัง"}, {"t": "ยาสลบ"}, {"t": "สารกันเสียในอาหาร"}, {"t": "สารป้องกันการแข็งตัวของน้ำในหม้อน้ำรถยนต์"}], "answer": 3}$j$::jsonb, 1, $t$เป็นสารพิษ ห้ามบริโภค$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$เอทิลีนไกลคอล (1,2-เอทานไดออล) ใช้ประโยชน์ในข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$กลีเซอรอล (โพรเพน-1,2,3-ไตรออล) มีหมู่ -OH กี่หมู่$t$, $j${"choices": [{"t": "1 หมู่"}, {"t": "4 หมู่"}, {"t": "2 หมู่"}, {"t": "3 หมู่"}], "answer": 3}$j$::jsonb, 1, $t$ไตรออล = 3 หมู่ -OH$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$กลีเซอรอล (โพรเพน-1,2,3-ไตรออล) มีหมู่ -OH กี่หมู่$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$CH3OCH3 มีชื่อเรียกว่าอะไร$t$, $j${"choices": [{"t": "ไดเมทิลอีเทอร์"}, {"t": "เมทานอล"}, {"t": "เอทานอล"}, {"t": "เอทิลเมทานอล"}], "answer": 0}$j$::jsonb, 1, $t$R-O-R' ที่ R = R' = CH3$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$CH3OCH3 มีชื่อเรียกว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'tf', $t$อีเทอร์ไม่สามารถสร้างพันธะไฮโดรเจนกับโมเลกุลอีเทอร์ด้วยกันเองได้$t$, $j${"answer": true}$j$::jsonb, 1, $t$ไม่มีไฮโดรเจนต่ออยู่กับออกซิเจน (ไม่มี O-H)$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$อีเทอร์ไม่สามารถสร้างพันธะไฮโดรเจนกับโมเลกุลอีเทอร์ด้วยกันเองได้$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'tf', $t$เอทานอลและไดเมทิลอีเทอร์มีสมบัติทางกายภาพเหมือนกันเพราะสูตรโมเลกุลเดียวกัน$t$, $j${"answer": false}$j$::jsonb, 1, $t$หมู่ฟังก์ชันต่างกัน จุดเดือดและความสามารถในการละลายน้ำต่างกัน$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$เอทานอลและไดเมทิลอีเทอร์มีสมบัติทางกายภาพเหมือนกันเพราะสูตรโมเลกุลเดียวกัน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'match', $t$จับคู่แอลกอฮอล์กับสูตร$t$, $j${"left": [{"t": "เมทานอล"}, {"t": "เอทานอล"}, {"t": "1-โพรพานอล"}, {"t": "2-โพรพานอล"}], "right": [{"t": "CH3CH2CH2OH"}, {"t": "CH3CH2OH"}, {"t": "CH3OCH3"}, {"t": "CH3CH(OH)CH3"}, {"t": "CH3OH"}], "pairs": [4, 1, 0, 3]}$j$::jsonb, 4, $t$ดูตำแหน่ง -OH และจำนวนคาร์บอน$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$จับคู่แอลกอฮอล์กับสูตร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$หมู่ฟังก์ชันของแอลดีไฮด์คือข้อใด$t$, $j${"choices": [{"t": "-CO- ระหว่างคาร์บอน"}, {"t": "-OH"}, {"t": "-CHO"}, {"t": "-COOH"}], "answer": 2}$j$::jsonb, 1, $t$หมู่คาร์บอนิลที่ปลายโซ่ ต่อกับ H$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$หมู่ฟังก์ชันของแอลดีไฮด์คือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$หมู่ฟังก์ชันของคีโตนคือข้อใด$t$, $j${"choices": [{"t": "-OH"}, {"t": "-COO-"}, {"t": "C=O ที่ปลายโซ่ต่อกับ H"}, {"t": "หมู่คาร์บอนิล (C=O) ที่อยู่ระหว่างคาร์บอนสองอะตอม"}], "answer": 3}$j$::jsonb, 1, $t$R-CO-R'$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$หมู่ฟังก์ชันของคีโตนคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$HCHO มีชื่อเรียกว่าอะไร$t$, $j${"choices": [{"t": "เมทานัล (ฟอร์มาลดีไฮด์)"}, {"t": "เมทิลอีเทอร์"}, {"t": "เมทานอล"}, {"t": "กรดฟอร์มิก"}], "answer": 0}$j$::jsonb, 1, $t$แอลดีไฮด์ที่มี 1 คาร์บอน$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$HCHO มีชื่อเรียกว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$CH3CHO มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "กรดเอทาโนอิก"}, {"t": "โพรพาโนน"}, {"t": "เอทานอล"}, {"t": "เอทานัล"}], "answer": 3}$j$::jsonb, 1, $t$ลงท้ายแอลดีไฮด์ -นัล$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$CH3CHO มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$CH3COCH3 มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "2-โพรพานอล"}, {"t": "เอทานัล"}, {"t": "โพรพาโนน (แอซีโทน)"}, {"t": "โพรพานัล"}], "answer": 2}$j$::jsonb, 1, $t$คีโตนลงท้าย -โนน$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$CH3COCH3 มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$แอลดีไฮด์ที่มี 3 คาร์บอนมีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "กรดโพรพาโนอิก"}, {"t": "โพรพานอล"}, {"t": "โพรพาโนน"}, {"t": "โพรพานัล"}], "answer": 3}$j$::jsonb, 1, $t$CH3CH2CHO$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$แอลดีไฮด์ที่มี 3 คาร์บอนมีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$คีโตนที่เล็กที่สุดมีคาร์บอนกี่อะตอม$t$, $j${"choices": [{"t": "1 อะตอม"}, {"t": "3 อะตอม"}, {"t": "2 อะตอม"}, {"t": "4 อะตอม"}], "answer": 1}$j$::jsonb, 1, $t$ต้องมีคาร์บอนอยู่ทั้งสองข้างของ C=O จึงเริ่มที่โพรพาโนน$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$คีโตนที่เล็กที่สุดมีคาร์บอนกี่อะตอม$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$แอลดีไฮด์และคีโตนที่มีจำนวนคาร์บอนเท่ากันเป็นไอโซเมอร์ชนิดใด$t$, $j${"choices": [{"t": "ไอโซเมอร์ตำแหน่ง"}, {"t": "ไอโซเมอร์โซ่คาร์บอน"}, {"t": "ไอโซเมอร์ต่างหมู่ฟังก์ชัน"}, {"t": "ไอโซเมอร์เรขาคณิต"}], "answer": 2}$j$::jsonb, 1, $t$เช่น โพรพานัลกับโพรพาโนน (C3H6O)$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$แอลดีไฮด์และคีโตนที่มีจำนวนคาร์บอนเท่ากันเป็นไอโซเมอร์ชนิดใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$สารละลายเบเนดิกต์ (Benedict) ใช้ทดสอบสมบัติใดของแอลดีไฮด์$t$, $j${"choices": [{"t": "การเกิดเอสเทอร์ ได้กลิ่นหอม"}, {"t": "การไม่อิ่มตัว สีจางหาย"}, {"t": "ความสามารถในการรีดิวซ์ ได้ตะกอนสีแดงอิฐ"}, {"t": "ความเป็นกรด ได้สารละลายสีเหลือง"}], "answer": 2}$j$::jsonb, 1, $t$แอลดีไฮด์ถูกออกซิไดส์เป็นกรด และ Cu2+ ถูกรีดิวซ์เป็น Cu2O (ตะกอนแดงอิฐ)$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$สารละลายเบเนดิกต์ (Benedict) ใช้ทดสอบสมบัติใดของแอลดีไฮด์$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$ปฏิกิริยากระจกเงิน (ทอลเลนส์) ให้ผลบวกกับสารใด$t$, $j${"choices": [{"t": "แอลคีน"}, {"t": "คีโตน"}, {"t": "อีเทอร์"}, {"t": "แอลดีไฮด์"}], "answer": 3}$j$::jsonb, 1, $t$Ag+ ถูกรีดิวซ์เป็นโลหะ Ag เกาะผนังเป็นกระจกเงา$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$ปฏิกิริยากระจกเงิน (ทอลเลนส์) ให้ผลบวกกับสารใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$ข้อใดแยกเอทานัลออกจากโพรพาโนนได้ด้วยสารละลายเบเนดิกต์$t$, $j${"choices": [{"t": "ทั้งสองให้ตะกอนสีแดงอิฐ"}, {"t": "ทั้งสองไม่เกิดการเปลี่ยนแปลง"}, {"t": "เอทานัลให้ตะกอนสีแดงอิฐ ส่วนโพรพาโนนไม่เกิดตะกอน"}, {"t": "โพรพาโนนให้ตะกอนสีแดงอิฐ ส่วนเอทานัลไม่เกิด"}], "answer": 2}$j$::jsonb, 1, $t$คีโตนไม่ถูกออกซิไดส์ง่ายเหมือนแอลดีไฮด์$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$ข้อใดแยกเอทานัลออกจากโพรพาโนนได้ด้วยสารละลายเบเนดิกต์$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$การออกซิไดส์แอลดีไฮด์ให้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "อีเทอร์"}, {"t": "คีโตน"}, {"t": "แอลกอฮอล์ตติยภูมิ"}, {"t": "กรดคาร์บอกซิลิก"}], "answer": 3}$j$::jsonb, 1, $t$RCHO → RCOOH$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$การออกซิไดส์แอลดีไฮด์ให้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$การรีดิวซ์โพรพาโนนด้วย H2 (ตัวเร่ง) ได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "โพรพานัล"}, {"t": "2-โพรพานอล"}, {"t": "1-โพรพานอล"}, {"t": "โพรเพน"}], "answer": 1}$j$::jsonb, 1, $t$คีโตนรีดิวซ์เป็นแอลกอฮอล์ทุติยภูมิ$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$การรีดิวซ์โพรพาโนนด้วย H2 (ตัวเร่ง) ได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$การรีดิวซ์แอลดีไฮด์ให้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "กรดคาร์บอกซิลิก"}, {"t": "แอลกอฮอล์ปฐมภูมิ"}, {"t": "คีโตน"}, {"t": "แอลกอฮอล์ทุติยภูมิ"}], "answer": 1}$j$::jsonb, 1, $t$RCHO + H2 → RCH2OH$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$การรีดิวซ์แอลดีไฮด์ให้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$ฟอร์มาลีน (สารละลายฟอร์มาลดีไฮด์ในน้ำ) ใช้ประโยชน์ในข้อใด$t$, $j${"choices": [{"t": "ใช้เป็นเชื้อเพลิงรถยนต์"}, {"t": "ใช้เป็นสารให้ความหวาน"}, {"t": "ผสมในเครื่องดื่ม"}, {"t": "ดองรักษาสภาพตัวอย่างสิ่งมีชีวิต"}], "answer": 3}$j$::jsonb, 1, $t$ฟอร์มาลีนเป็นพิษ ห้ามใช้กับอาหาร$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$ฟอร์มาลีน (สารละลายฟอร์มาลดีไฮด์ในน้ำ) ใช้ประโยชน์ในข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$แอซีโทนมีประโยชน์หลักในข้อใด$t$, $j${"choices": [{"t": "เป็นตัวทำละลาย เช่น ล้างน้ำยาทาเล็บ"}, {"t": "เป็นสารกันบูดในอาหาร"}, {"t": "เป็นปุ๋ยพืช"}, {"t": "เป็นสารให้ความหวาน"}], "answer": 0}$j$::jsonb, 1, $t$แอซีโทนละลายสารอินทรีย์ได้ดีและระเหยง่าย$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$แอซีโทนมีประโยชน์หลักในข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$เหตุใดแอลดีไฮด์ที่มีคาร์บอนน้อยๆ จึงละลายน้ำได้$t$, $j${"choices": [{"t": "เป็นสารไม่มีขั้ว"}, {"t": "มีไฮโดรเจนต่อกับออกซิเจน"}, {"t": "ออกซิเจนของ C=O สร้างพันธะไฮโดรเจนกับน้ำได้"}, {"t": "มีพันธะไอออนิก"}], "answer": 2}$j$::jsonb, 1, $t$แอลดีไฮด์และคีโตนไม่มี O-H ในโมเลกุลตัวเอง แต่รับพันธะไฮโดรเจนจากน้ำได้$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$เหตุใดแอลดีไฮด์ที่มีคาร์บอนน้อยๆ จึงละลายน้ำได้$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$จุดเดือดของแอลดีไฮด์/คีโตนเมื่อเทียบกับแอลกอฮอล์ที่มีมวลโมเลกุลใกล้เคียงกันเป็นอย่างไร$t$, $j${"choices": [{"t": "ต่ำกว่า เพราะไม่มีพันธะไฮโดรเจนระหว่างโมเลกุลชนิดเดียวกัน"}, {"t": "สูงกว่า เพราะมีพันธะคู่"}, {"t": "เท่ากัน"}, {"t": "สูงกว่า เพราะมีพันธะไอออนิก"}], "answer": 0}$j$::jsonb, 1, $t$มีขั้วจึงสูงกว่าแอลเคน แต่ต่ำกว่าแอลกอฮอล์$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$จุดเดือดของแอลดีไฮด์/คีโตนเมื่อเทียบกับแอลกอฮอล์ที่มีมวลโมเลกุลใกล้เคียงกันเป็นอย่างไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$เบนซัลดีไฮด์ต่างจากเบนซีนที่หมู่ฟังก์ชันใด$t$, $j${"choices": [{"t": "มีหมู่ -OH"}, {"t": "มีหมู่ -CHO ต่ออยู่กับวงแหวน"}, {"t": "มีหมู่ -NH2"}, {"t": "มีหมู่ -COOH"}], "answer": 1}$j$::jsonb, 1, $t$C6H5CHO เป็นแอลดีไฮด์อะโรมาติก (กลิ่นอัลมอนด์)$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$เบนซัลดีไฮด์ต่างจากเบนซีนที่หมู่ฟังก์ชันใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'tf', $t$คีโตนให้ผลบวกกับปฏิกิริยากระจกเงาของทอลเลนส์$t$, $j${"answer": false}$j$::jsonb, 1, $t$คีโตนไม่ถูกออกซิไดส์ง่าย จึงไม่ให้กระจกเงา$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$คีโตนให้ผลบวกกับปฏิกิริยากระจกเงาของทอลเลนส์$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'tf', $t$แอลดีไฮด์ถูกออกซิไดส์เป็นกรดคาร์บอกซิลิกได้ง่าย$t$, $j${"answer": true}$j$::jsonb, 1, $t$เป็นเหตุผลที่แอลดีไฮด์ให้ผลบวกกับเบเนดิกต์และทอลเลนส์$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$แอลดีไฮด์ถูกออกซิไดส์เป็นกรดคาร์บอกซิลิกได้ง่าย$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'tf', $t$แอซีโทนเป็นแอลดีไฮด์ที่เล็กที่สุด$t$, $j${"answer": false}$j$::jsonb, 1, $t$แอซีโทนเป็นคีโตน ส่วนแอลดีไฮด์ที่เล็กที่สุดคือเมทานัล$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$แอซีโทนเป็นแอลดีไฮด์ที่เล็กที่สุด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'match', $t$จับคู่ชื่อแอลดีไฮด์และคีโตนกับสูตร$t$, $j${"left": [{"t": "เมทานัล"}, {"t": "เอทานัล"}, {"t": "โพรพาโนน"}, {"t": "เบนซัลดีไฮด์"}], "right": [{"t": "C6H5CHO"}, {"t": "CH3COOH"}, {"t": "CH3COCH3"}, {"t": "HCHO"}, {"t": "CH3CHO"}], "pairs": [3, 4, 2, 0]}$j$::jsonb, 4, $t$ดูหมู่คาร์บอนิล$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$จับคู่ชื่อแอลดีไฮด์และคีโตนกับสูตร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$หมู่ฟังก์ชันของกรดคาร์บอกซิลิกคือข้อใด$t$, $j${"choices": [{"t": "-OH"}, {"t": "-COOH"}, {"t": "-COO- ระหว่างคาร์บอน"}, {"t": "-CHO"}], "answer": 1}$j$::jsonb, 1, $t$หมู่คาร์บอกซิล$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$หมู่ฟังก์ชันของกรดคาร์บอกซิลิกคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$CH3COOH มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "เอทานัล"}, {"t": "กรดเอทาโนอิก"}, {"t": "กรดเมทาโนอิก"}, {"t": "เอทานอล"}], "answer": 1}$j$::jsonb, 1, $t$2 คาร์บอน (รวมคาร์บอนของ -COOH) ลงท้าย -โนอิก$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$CH3COOH มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$HCOOH มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "เมทานอล"}, {"t": "กรดเอทาโนอิก"}, {"t": "เมทานัล"}, {"t": "กรดเมทาโนอิก"}], "answer": 3}$j$::jsonb, 1, $t$กรดฟอร์มิก พบในมดและต่อ$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$HCOOH มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$CH3CH2COOH มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "โพรพาโนน"}, {"t": "กรดโพรพาโนอิก"}, {"t": "กรดบิวทาโนอิก"}, {"t": "โพรพานัล"}], "answer": 1}$j$::jsonb, 1, $t$3 คาร์บอน$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$CH3CH2COOH มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$น้ำส้มสายชูมีกรดชนิดใดเป็นองค์ประกอบหลัก$t$, $j${"choices": [{"t": "กรดไฮโดรคลอริก"}, {"t": "กรดเอทาโนอิก (แอซีติก)"}, {"t": "กรดเมทาโนอิก"}, {"t": "กรดซิตริก"}], "answer": 1}$j$::jsonb, 1, $t$น้ำส้มสายชูมีกรดแอซีติกประมาณ 4-7%$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$น้ำส้มสายชูมีกรดชนิดใดเป็นองค์ประกอบหลัก$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$กรดคาร์บอกซิลิกจัดเป็นกรดประเภทใด$t$, $j${"choices": [{"t": "กรดแก่"}, {"t": "สารที่เป็นกลาง"}, {"t": "กรดอ่อน"}, {"t": "เบสอ่อน"}], "answer": 2}$j$::jsonb, 1, $t$แตกตัวเป็นไอออนได้บางส่วนในน้ำ$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$กรดคาร์บอกซิลิกจัดเป็นกรดประเภทใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$กรดเอทาโนอิกทำปฏิกิริยากับ NaOH ได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "เอทิลเอทาโนเอตและน้ำ"}, {"t": "เอทานัลและน้ำ"}, {"t": "เอทานอลและโซเดียม"}, {"t": "โซเดียมเอทาโนเอตและน้ำ"}], "answer": 3}$j$::jsonb, 1, $t$CH3COOH + NaOH → CH3COONa + H2O$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$กรดเอทาโนอิกทำปฏิกิริยากับ NaOH ได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$กรดเอทาโนอิกทำปฏิกิริยากับ NaHCO3 ได้แก๊สใด$t$, $j${"choices": [{"t": "CO2"}, {"t": "NH3"}, {"t": "O2"}, {"t": "H2"}], "answer": 0}$j$::jsonb, 1, $t$กรดคาร์บอกซิลิกแรงกว่ากรดคาร์บอนิก จึงดันให้เกิด CO2$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$กรดเอทาโนอิกทำปฏิกิริยากับ NaHCO3 ได้แก๊สใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$กรดคาร์บอกซิลิกมีจุดเดือดสูงกว่าแอลกอฮอล์ที่มีมวลโมเลกุลใกล้เคียงกัน เพราะเหตุใด$t$, $j${"choices": [{"t": "ไม่มีขั้ว"}, {"t": "สร้างพันธะไฮโดรเจนได้แข็งแรงกว่า (เกิดคู่โมเลกุลไดเมอร์)"}, {"t": "มีพันธะไอออนิก"}, {"t": "มีพันธะคู่ C=C"}], "answer": 1}$j$::jsonb, 1, $t$หมู่ -COOH สร้างพันธะไฮโดรเจนระหว่างโมเลกุล 2 จุด$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$กรดคาร์บอกซิลิกมีจุดเดือดสูงกว่าแอลกอฮอล์ที่มีมวลโมเลกุลใกล้เคียงกัน เพราะเหตุใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$ปฏิกิริยาระหว่างกรดคาร์บอกซิลิกกับแอลกอฮอล์เรียกว่าอะไร$t$, $j${"choices": [{"t": "ไฮโดรจีเนชัน"}, {"t": "ไนเตรชัน"}, {"t": "การหมัก"}, {"t": "เอสเทอริฟิเคชัน"}], "answer": 3}$j$::jsonb, 1, $t$ได้เอสเทอร์และน้ำ$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$ปฏิกิริยาระหว่างกรดคาร์บอกซิลิกกับแอลกอฮอล์เรียกว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$เอสเทอริฟิเคชันมักใช้ตัวเร่งปฏิกิริยาใด$t$, $j${"choices": [{"t": "FeBr3"}, {"t": "กรดซัลฟิวริกเข้มข้น"}, {"t": "โลหะนิกเกิล"}, {"t": "โพแทสเซียมเปอร์แมงกาเนต"}], "answer": 1}$j$::jsonb, 1, $t$H2SO4 เข้มข้นเป็นทั้งตัวเร่งและดูดน้ำ$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$เอสเทอริฟิเคชันมักใช้ตัวเร่งปฏิกิริยาใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$CH3COOH + CH3OH → (H2SO4) ได้เอสเทอร์ชื่อใด$t$, $j${"choices": [{"t": "เมทิลเมทาโนเอต"}, {"t": "เอทิลเมทาโนเอต"}, {"t": "เอทิลเอทาโนเอต"}, {"t": "เมทิลเอทาโนเอต"}], "answer": 3}$j$::jsonb, 1, $t$ชื่อหมู่อัลคิลจากแอลกอฮอล์ + ชื่อส่วนกรดลงท้าย -โนเอต$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$CH3COOH + CH3OH → (H2SO4) ได้เอสเทอร์ชื่อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$เอสเทอร์ที่ได้จากกรดเมทาโนอิกและเอทานอลชื่อว่าอะไร$t$, $j${"choices": [{"t": "เอทิลเอทาโนเอต"}, {"t": "เมทิลเอทาโนเอต"}, {"t": "เอทิลเมทาโนเอต"}, {"t": "เมทิลเมทาโนเอต"}], "answer": 2}$j$::jsonb, 1, $t$เอทิลจากเอทานอล + เมทาโนเอตจากกรดเมทาโนอิก$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$เอสเทอร์ที่ได้จากกรดเมทาโนอิกและเอทานอลชื่อว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$เอสเทอร์ CH3COOCH2CH3 มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "เมทิลเอทาโนเอต"}, {"t": "เอทิลโพรพาโนเอต"}, {"t": "เมทิลโพรพาโนเอต"}, {"t": "เอทิลเอทาโนเอต"}], "answer": 3}$j$::jsonb, 1, $t$กรดเอทาโนอิก + เอทานอล$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$เอสเทอร์ CH3COOCH2CH3 มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$หมู่ฟังก์ชันของเอสเทอร์คือข้อใด$t$, $j${"choices": [{"t": "-CO- ระหว่างคาร์บอน"}, {"t": "-COOH"}, {"t": "-COO- (ต่อกับหมู่อัลคิลทั้งสองด้าน)"}, {"t": "-CONH2"}], "answer": 2}$j$::jsonb, 1, $t$R-COO-R'$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$หมู่ฟังก์ชันของเอสเทอร์คือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$เอสเทอร์มีสมบัติเด่นข้อใด$t$, $j${"choices": [{"t": "มักมีกลิ่นหอมคล้ายผลไม้"}, {"t": "เป็นสารที่ละลายน้ำได้ดีมาก"}, {"t": "มีกลิ่นฉุนเหมือนปลา"}, {"t": "มีรสเปรี้ยวจัด"}], "answer": 0}$j$::jsonb, 1, $t$ใช้เป็นสารแต่งกลิ่นรส$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$เอสเทอร์มีสมบัติเด่นข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$เอสเทอร์ที่ให้กลิ่นกล้วยหอมคือข้อใด$t$, $j${"choices": [{"t": "เอทิลเมทาโนเอต"}, {"t": "กรดบิวทาโนอิก"}, {"t": "เมทิลซาลิไซเลต"}, {"t": "เพนทิลเอทาโนเอต"}], "answer": 3}$j$::jsonb, 1, $t$เพนทิลแอซีเตต ใช้แต่งกลิ่นกล้วย$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$เอสเทอร์ที่ให้กลิ่นกล้วยหอมคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$ปฏิกิริยาไฮโดรไลซิสของเอสเทอร์ด้วยกรดให้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "คีโตนและแก๊สไฮโดรเจน"}, {"t": "แอลคีนและน้ำ"}, {"t": "กรดคาร์บอกซิลิกและแอลกอฮอล์"}, {"t": "แอลดีไฮด์และน้ำ"}], "answer": 2}$j$::jsonb, 1, $t$ย้อนกลับของเอสเทอริฟิเคชัน$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$ปฏิกิริยาไฮโดรไลซิสของเอสเทอร์ด้วยกรดให้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$ปฏิกิริยาของเอสเทอร์กับสารละลาย NaOH (สะปอนนิฟิเคชัน) ได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "กรดคาร์บอกซิลิกและแอลกอฮอล์"}, {"t": "แอลดีไฮด์และเกลือ"}, {"t": "เกลือของกรดคาร์บอกซิลิกและแอลกอฮอล์"}, {"t": "แอลเคนและเกลือ"}], "answer": 2}$j$::jsonb, 1, $t$RCOOR' + NaOH → RCOONa + R'OH$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$ปฏิกิริยาของเอสเทอร์กับสารละลาย NaOH (สะปอนนิฟิเคชัน) ได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$C2H4O2 มีไอโซเมอร์ที่เป็นกรดและเอสเทอร์ ได้แก่คู่ใด$t$, $j${"choices": [{"t": "เอทานอล กับ เอทานัล"}, {"t": "โพรพาโนน กับ โพรพานัล"}, {"t": "เอทีน กับ เอเทน"}, {"t": "กรดเอทาโนอิก กับ เมทิลเมทาโนเอต"}], "answer": 3}$j$::jsonb, 1, $t$CH3COOH กับ HCOOCH3$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$C2H4O2 มีไอโซเมอร์ที่เป็นกรดและเอสเทอร์ ได้แก่คู่ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$สารใดมีจุดเดือดสูงที่สุด (มวลโมเลกุลใกล้เคียงกัน)$t$, $j${"choices": [{"t": "แอลเคน"}, {"t": "แอลดีไฮด์"}, {"t": "กรดคาร์บอกซิลิก"}, {"t": "เอสเทอร์"}], "answer": 2}$j$::jsonb, 1, $t$กรดมีพันธะไฮโดรเจนระหว่างโมเลกุลแข็งแรงที่สุด$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$สารใดมีจุดเดือดสูงที่สุด (มวลโมเลกุลใกล้เคียงกัน)$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'tf', $t$กรดคาร์บอกซิลิกเปลี่ยนสีกระดาษลิตมัสสีน้ำเงินเป็นสีแดง$t$, $j${"answer": true}$j$::jsonb, 1, $t$มีสมบัติเป็นกรด$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$กรดคาร์บอกซิลิกเปลี่ยนสีกระดาษลิตมัสสีน้ำเงินเป็นสีแดง$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'tf', $t$เอสเทอริฟิเคชันเป็นปฏิกิริยาที่เกิดน้ำเป็นผลพลอยได้$t$, $j${"answer": true}$j$::jsonb, 1, $t$RCOOH + R'OH ⇌ RCOOR' + H2O$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$เอสเทอริฟิเคชันเป็นปฏิกิริยาที่เกิดน้ำเป็นผลพลอยได้$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'tf', $t$กรดแอซีติกเป็นกรดแก่ที่แตกตัวได้สมบูรณ์ในน้ำ$t$, $j${"answer": false}$j$::jsonb, 1, $t$เป็นกรดอ่อน แตกตัวได้เพียงบางส่วน$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$กรดแอซีติกเป็นกรดแก่ที่แตกตัวได้สมบูรณ์ในน้ำ$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'match', $t$จับคู่ชื่อสารกับสูตร$t$, $j${"left": [{"t": "กรดเมทาโนอิก"}, {"t": "กรดเอทาโนอิก"}, {"t": "เมทิลเอทาโนเอต"}, {"t": "เอทิลเอทาโนเอต"}], "right": [{"t": "CH3COOCH2CH3"}, {"t": "CH3COOCH3"}, {"t": "HCOOCH3"}, {"t": "CH3COOH"}, {"t": "HCOOH"}], "pairs": [4, 3, 1, 0]}$j$::jsonb, 4, $t$ชื่อเอสเทอร์เรียงอัลคิลจากแอลกอฮอล์ก่อน$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$จับคู่ชื่อสารกับสูตร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$หมู่ฟังก์ชันของเอมีนคือข้อใด$t$, $j${"choices": [{"t": "หมู่ที่มีไนโตรเจนต่ออยู่กับหมู่อัลคิลหรืออะริล เช่น -NH2"}, {"t": "-CHO"}, {"t": "-OH"}, {"t": "-COOH"}], "answer": 0}$j$::jsonb, 1, $t$เอมีนเป็นอนุพันธ์ของแอมโมเนีย$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$หมู่ฟังก์ชันของเอมีนคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$CH3NH2 มีชื่อเรียกว่าอะไร$t$, $j${"choices": [{"t": "เมทานอล"}, {"t": "เมทานามีน (เมทิลเอมีน)"}, {"t": "เมทานัล"}, {"t": "กรดเมทาโนอิก"}], "answer": 1}$j$::jsonb, 1, $t$เอมีนปฐมภูมิที่เล็กที่สุด$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$CH3NH2 มีชื่อเรียกว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$CH3CH2NH2 มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "เอทานามีน"}, {"t": "เอไมด์"}, {"t": "เอทานอล"}, {"t": "เอทานัล"}], "answer": 0}$j$::jsonb, 1, $t$2 คาร์บอน + เอมีน$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$CH3CH2NH2 มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$(CH3)2NH จัดเป็นเอมีนประเภทใด$t$, $j${"choices": [{"t": "เอไมด์"}, {"t": "เอมีนปฐมภูมิ (1°)"}, {"t": "เอมีนตติยภูมิ (3°)"}, {"t": "เอมีนทุติยภูมิ (2°)"}], "answer": 3}$j$::jsonb, 1, $t$ไนโตรเจนต่อกับหมู่อัลคิล 2 หมู่$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$(CH3)2NH จัดเป็นเอมีนประเภทใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$(CH3)3N จัดเป็นเอมีนประเภทใด$t$, $j${"choices": [{"t": "เอไมด์"}, {"t": "เอมีนปฐมภูมิ (1°)"}, {"t": "เอมีนทุติยภูมิ (2°)"}, {"t": "เอมีนตติยภูมิ (3°)"}], "answer": 3}$j$::jsonb, 1, $t$ไนโตรเจนต่อกับหมู่อัลคิล 3 หมู่$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$(CH3)3N จัดเป็นเอมีนประเภทใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$เอมีนมีสมบัติทางเคมีข้อใด$t$, $j${"choices": [{"t": "เป็นกลางเสมอ"}, {"t": "เป็นกรดแก่"}, {"t": "เป็นเบสอ่อน"}, {"t": "เป็นตัวออกซิไดส์รุนแรง"}], "answer": 2}$j$::jsonb, 1, $t$คู่อิเล็กตรอนอิสระบนไนโตรเจนรับโปรตอนได้$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$เอมีนมีสมบัติทางเคมีข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$เมื่อเอมีนทำปฏิกิริยากับ HCl จะได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "แอลกอฮอล์"}, {"t": "เอไมด์"}, {"t": "กรดคาร์บอกซิลิก"}, {"t": "เกลือแอมโมเนียม (เอมีนไฮโดรคลอไรด์)"}], "answer": 3}$j$::jsonb, 1, $t$RNH2 + HCl → RNH3+Cl-$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$เมื่อเอมีนทำปฏิกิริยากับ HCl จะได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$เอมีนโมเลกุลเล็กมักมีกลิ่นลักษณะใด$t$, $j${"choices": [{"t": "กลิ่นคาวปลา"}, {"t": "ไม่มีกลิ่น"}, {"t": "กลิ่นหอมหวานผลไม้"}, {"t": "กลิ่นน้ำส้มสายชู"}], "answer": 0}$j$::jsonb, 1, $t$เช่น ไตรเมทิลเอมีนในปลาเน่า$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$เอมีนโมเลกุลเล็กมักมีกลิ่นลักษณะใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$เอมีนชนิดใดที่ไม่สามารถสร้างพันธะไฮโดรเจนกับโมเลกุลชนิดเดียวกัน$t$, $j${"choices": [{"t": "เอมีนทุติยภูมิ"}, {"t": "เอมีนปฐมภูมิ"}, {"t": "เอมีนตติยภูมิ"}, {"t": "ทุกชนิดสร้างได้"}], "answer": 2}$j$::jsonb, 1, $t$ไม่มี N-H$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$เอมีนชนิดใดที่ไม่สามารถสร้างพันธะไฮโดรเจนกับโมเลกุลชนิดเดียวกัน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$หมู่ฟังก์ชันของเอไมด์คือข้อใด$t$, $j${"choices": [{"t": "-COOR"}, {"t": "-NH2"}, {"t": "-COOH"}, {"t": "-CONH2 (หรือ -CONHR, -CONR2)"}], "answer": 3}$j$::jsonb, 1, $t$คาร์บอนิลต่อกับไนโตรเจน$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$หมู่ฟังก์ชันของเอไมด์คือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$CH3CONH2 มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "กรดเอทาโนอิก"}, {"t": "เอทานามีน"}, {"t": "เมทิลเอทาโนเอต"}, {"t": "เอทานาไมด์"}], "answer": 3}$j$::jsonb, 1, $t$ชื่อเอไมด์ลงท้าย -าไมด์$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$CH3CONH2 มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$เอไมด์เกิดจากปฏิกิริยาระหว่างสารคู่ใด$t$, $j${"choices": [{"t": "แอลดีไฮด์กับแอลกอฮอล์"}, {"t": "แอลคีนกับน้ำ"}, {"t": "กรดคาร์บอกซิลิกกับแอลกอฮอล์"}, {"t": "กรดคาร์บอกซิลิกกับเอมีนหรือแอมโมเนีย"}], "answer": 3}$j$::jsonb, 1, $t$เกิดพันธะเอไมด์ พร้อมเสียน้ำ$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$เอไมด์เกิดจากปฏิกิริยาระหว่างสารคู่ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$พันธะเปปไทด์ในโปรตีนคือพันธะชนิดใดทางเคมีอินทรีย์$t$, $j${"choices": [{"t": "พันธะเอไมด์"}, {"t": "พันธะไกลโคซิดิก"}, {"t": "พันธะอีเทอร์"}, {"t": "พันธะเอสเทอร์"}], "answer": 0}$j$::jsonb, 1, $t$-CO-NH-$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$พันธะเปปไทด์ในโปรตีนคือพันธะชนิดใดทางเคมีอินทรีย์$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$ยูเรีย (NH2)2CO มีหมู่ฟังก์ชันใดเด่นชัด$t$, $j${"choices": [{"t": "เอสเทอร์"}, {"t": "เอไมด์"}, {"t": "อีเทอร์"}, {"t": "แอลดีไฮด์"}], "answer": 1}$j$::jsonb, 1, $t$คาร์บอนิลต่อกับ -NH2 สองหมู่$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$ยูเรีย (NH2)2CO มีหมู่ฟังก์ชันใดเด่นชัด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$เอไมด์โดยทั่วไปมีสมบัติทางกรด-เบสอย่างไร$t$, $j${"choices": [{"t": "เกือบเป็นกลาง (เป็นเบสอ่อนมาก)"}, {"t": "เป็นกรดแก่"}, {"t": "เป็นเบสแก่"}, {"t": "เป็นกรดอ่อนกว่ากรดคาร์บอกซิลิกมาก"}], "answer": 0}$j$::jsonb, 1, $t$คู่อิเล็กตรอนของ N เกิดเรโซแนนซ์กับ C=O$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$เอไมด์โดยทั่วไปมีสมบัติทางกรด-เบสอย่างไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$แอนิลีนจัดเป็นเอมีนประเภทใด$t$, $j${"choices": [{"t": "เอไมด์"}, {"t": "เอมีนอะโรมาติกปฐมภูมิ"}, {"t": "เอสเทอร์"}, {"t": "เอมีนทุติยภูมิ"}], "answer": 1}$j$::jsonb, 1, $t$C6H5NH2$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$แอนิลีนจัดเป็นเอมีนประเภทใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$สารกลุ่มไนโตรเจนใดมีจุดเดือดสูงที่สุด (มวลโมเลกุลใกล้เคียงกัน)$t$, $j${"choices": [{"t": "อีเทอร์"}, {"t": "แอลเคน"}, {"t": "เอไมด์ปฐมภูมิ"}, {"t": "เอมีนตติยภูมิ"}], "answer": 2}$j$::jsonb, 1, $t$เอไมด์สร้างพันธะไฮโดรเจนหลายตำแหน่ง$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$สารกลุ่มไนโตรเจนใดมีจุดเดือดสูงที่สุด (มวลโมเลกุลใกล้เคียงกัน)$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'tf', $t$เอมีนเกิดจากการแทนที่ H ในโมเลกุลแอมโมเนียด้วยหมู่อัลคิล$t$, $j${"answer": true}$j$::jsonb, 1, $t$เช่น NH3 → CH3NH2$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$เอมีนเกิดจากการแทนที่ H ในโมเลกุลแอมโมเนียด้วยหมู่อัลคิล$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'tf', $t$เอไมด์มีสมบัติเป็นเบสแรงกว่าเอมีนเสมอ$t$, $j${"answer": false}$j$::jsonb, 1, $t$เอมีนเป็นเบสแรงกว่าเอไมด์$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$เอไมด์มีสมบัติเป็นเบสแรงกว่าเอมีนเสมอ$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'match', $t$จับคู่สารกับหมู่ฟังก์ชัน$t$, $j${"left": [{"t": "CH3NH2"}, {"t": "CH3CONH2"}, {"t": "CH3COOH"}, {"t": "CH3COOCH3"}], "right": [{"t": "เอมีน"}, {"t": "เอไมด์"}, {"t": "แอลดีไฮด์"}, {"t": "เอสเทอร์"}, {"t": "กรดคาร์บอกซิลิก"}], "pairs": [0, 1, 4, 3]}$j$::jsonb, 4, $t$ดูอะตอมที่ต่อกับคาร์บอนิล$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$จับคู่สารกับหมู่ฟังก์ชัน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$CH3CH2Cl จัดเป็นสารประกอบประเภทใด$t$, $j${"choices": [{"t": "แอลกอฮอล์"}, {"t": "เอไมด์"}, {"t": "เฮโลแอลเคน (แอลคิลเฮไลด์)"}, {"t": "เอสเทอร์"}], "answer": 2}$j$::jsonb, 1, $t$มีอะตอมฮาโลเจนต่อกับคาร์บอนอิ่มตัว$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$CH3CH2Cl จัดเป็นสารประกอบประเภทใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$CH3Cl มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "ไดคลอโรมีเทน"}, {"t": "เมทิลคลอไรด์เมทานอล"}, {"t": "คลอโรอีเทน"}, {"t": "คลอโรมีเทน"}], "answer": 3}$j$::jsonb, 1, $t$ใช้ชื่อฮาโลเจนนำหน้าชื่อแอลเคน$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$CH3Cl มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$CCl4 มีชื่อเรียกว่าอะไร$t$, $j${"choices": [{"t": "เตตระคลอโรมีเทน (คาร์บอนเตตระคลอไรด์)"}, {"t": "คลอโรมีเทน"}, {"t": "ไตรคลอโรมีเทน"}, {"t": "ไดคลอโรมีเทน"}], "answer": 0}$j$::jsonb, 1, $t$คาร์บอน 1 อะตอมต่อ Cl 4 อะตอม$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$CCl4 มีชื่อเรียกว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$CHCl3 มีชื่อสามัญว่าอะไร$t$, $j${"choices": [{"t": "แอซีโทน"}, {"t": "ฟอร์มาลีน"}, {"t": "คลอโรฟอร์ม"}, {"t": "เอทานอล"}], "answer": 2}$j$::jsonb, 1, $t$ไตรคลอโรมีเทน เคยใช้เป็นยาสลบ$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$CHCl3 มีชื่อสามัญว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$CFC (คลอโรฟลูออโรคาร์บอน) ส่งผลเสียต่อสิ่งแวดล้อมในข้อใด$t$, $j${"choices": [{"t": "ทำให้ดินเป็นด่าง"}, {"t": "ทำให้เกิดฝนกรดโดยตรง"}, {"t": "ทำให้น้ำทะเลเค็มขึ้น"}, {"t": "ทำลายชั้นโอโซนในบรรยากาศ"}], "answer": 3}$j$::jsonb, 1, $t$อะตอม Cl ถูกปล่อยออกมาทำลาย O3$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$CFC (คลอโรฟลูออโรคาร์บอน) ส่งผลเสียต่อสิ่งแวดล้อมในข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$เฮโลแอลเคนโดยทั่วไปละลายในน้ำได้หรือไม่$t$, $j${"choices": [{"t": "แตกตัวเป็นไอออนในน้ำสมบูรณ์"}, {"t": "ละลายได้น้อยมาก"}, {"t": "ละลายได้ดีมาก"}, {"t": "ทำปฏิกิริยากับน้ำรุนแรงเสมอ"}], "answer": 1}$j$::jsonb, 1, $t$มีขั้วเล็กน้อย ไม่สร้างพันธะไฮโดรเจนกับน้ำได้ดี$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$เฮโลแอลเคนโดยทั่วไปละลายในน้ำได้หรือไม่$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$สารใดต่อไปนี้เป็นเอสเทอร์$t$, $j${"choices": [{"t": "CH3CONH2"}, {"t": "CH3COOCH3"}, {"t": "CH3CH2CHO"}, {"t": "CH3CH2OCH3"}], "answer": 1}$j$::jsonb, 1, $t$มีหมู่ -COO- ต่อกับหมู่อัลคิลสองด้าน$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$สารใดต่อไปนี้เป็นเอสเทอร์$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$สารใดต่อไปนี้เป็นอีเทอร์$t$, $j${"choices": [{"t": "CH3COCH3"}, {"t": "CH3COOCH3"}, {"t": "CH3OCH2CH3"}, {"t": "CH3CH2CH2OH"}], "answer": 2}$j$::jsonb, 1, $t$R-O-R' ไม่มี C=O$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$สารใดต่อไปนี้เป็นอีเทอร์$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$สารใดต่อไปนี้มีทั้งหมู่ -OH และ -COOH ในโมเลกุลเดียวกัน$t$, $j${"choices": [{"t": "กรดแลกติก CH3CH(OH)COOH"}, {"t": "เมทิลเอทาโนเอต"}, {"t": "เอทานอล"}, {"t": "กรดเอทาโนอิก"}], "answer": 0}$j$::jsonb, 1, $t$เป็นกรดไฮดรอกซี$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$สารใดต่อไปนี้มีทั้งหมู่ -OH และ -COOH ในโมเลกุลเดียวกัน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$เรียงลำดับจุดเดือดจากต่ำไปสูงของสารที่มีมวลโมเลกุลใกล้เคียงกัน ข้อใดถูกต้อง$t$, $j${"choices": [{"t": "แอลกอฮอล์ < กรดคาร์บอกซิลิก < แอลเคน < อีเทอร์"}, {"t": "อีเทอร์ < แอลเคน < กรดคาร์บอกซิลิก < แอลกอฮอล์"}, {"t": "แอลเคน < อีเทอร์ < แอลดีไฮด์/คีโตน < แอลกอฮอล์ < กรดคาร์บอกซิลิก"}, {"t": "กรดคาร์บอกซิลิก < แอลกอฮอล์ < คีโตน < แอลเคน"}], "answer": 2}$j$::jsonb, 1, $t$ขึ้นกับขั้วและพันธะไฮโดรเจน$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$เรียงลำดับจุดเดือดจากต่ำไปสูงของสารที่มีมวลโมเลกุลใกล้เคียงกัน ข้อใดถูกต้อง$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$สารใดมีสมบัติเป็นกรดต่อสารละลาย NaHCO3 แล้วเกิดฟองแก๊ส$t$, $j${"choices": [{"t": "CH3CH2OH"}, {"t": "CH3CHO"}, {"t": "CH3COCH3"}, {"t": "CH3COOH"}], "answer": 3}$j$::jsonb, 1, $t$กรดคาร์บอกซิลิกให้ CO2$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$สารใดมีสมบัติเป็นกรดต่อสารละลาย NaHCO3 แล้วเกิดฟองแก๊ส$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$สารใดต่อไปนี้ถูกออกซิไดส์ได้ง่ายที่สุดด้วยตัวออกซิไดส์อ่อน$t$, $j${"choices": [{"t": "CH3COCH3"}, {"t": "CH3OCH3"}, {"t": "CH3COOH"}, {"t": "CH3CHO"}], "answer": 3}$j$::jsonb, 1, $t$แอลดีไฮด์ถูกออกซิไดส์เป็นกรด$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$สารใดต่อไปนี้ถูกออกซิไดส์ได้ง่ายที่สุดด้วยตัวออกซิไดส์อ่อน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$สาร C3H6O มีไอโซเมอร์ที่เป็นแอลดีไฮด์และคีโตน คือคู่ใด$t$, $j${"choices": [{"t": "เมทิลอีเทอร์และเอทานอล"}, {"t": "กรดและเอสเทอร์"}, {"t": "โพรพานัลและโพรพาโนน"}, {"t": "โพรพานอลและโพรพีน"}], "answer": 2}$j$::jsonb, 1, $t$CH3CH2CHO และ CH3COCH3$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$สาร C3H6O มีไอโซเมอร์ที่เป็นแอลดีไฮด์และคีโตน คือคู่ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$หมู่ฟังก์ชันของสาร CH3CH2CH2NH2 คือข้อใด$t$, $j${"choices": [{"t": "อีเทอร์"}, {"t": "เอมีน"}, {"t": "เอไมด์"}, {"t": "แอลกอฮอล์"}], "answer": 1}$j$::jsonb, 1, $t$-NH2 ต่อกับหมู่อัลคิล$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$หมู่ฟังก์ชันของสาร CH3CH2CH2NH2 คือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$ข้อใดจัดเป็นสารประกอบอินทรีย์$t$, $j${"choices": [{"t": "CO2"}, {"t": "NaCl"}, {"t": "CaCO3"}, {"t": "CH4"}], "answer": 3}$j$::jsonb, 1, $t$สารอินทรีย์ส่วนใหญ่มีคาร์บอนต่อกับไฮโดรเจน (CO2 และคาร์บอเนตจัดเป็นอนินทรีย์)$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$ข้อใดจัดเป็นสารประกอบอินทรีย์$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$ทำไมสารประกอบอินทรีย์ส่วนใหญ่จุดหลอมเหลวต่ำกว่าสารประกอบไอออนิก$t$, $j${"choices": [{"t": "ไม่มีอิเล็กตรอนวาเลนซ์"}, {"t": "มีพันธะโลหะ"}, {"t": "แรงยึดเหนี่ยวระหว่างโมเลกุลอ่อนกว่าพันธะไอออนิก"}, {"t": "มีมวลโมเลกุลมากกว่าเสมอ"}], "answer": 2}$j$::jsonb, 1, $t$สารโมเลกุลโคเวเลนต์ใช้พลังงานน้อยกว่าในการแยกโมเลกุล$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$ทำไมสารประกอบอินทรีย์ส่วนใหญ่จุดหลอมเหลวต่ำกว่าสารประกอบไอออนิก$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$คาร์บอนมีเวเลนซ์อิเล็กตรอนกี่ตัว และสร้างพันธะโคเวเลนต์ได้กี่พันธะ$t$, $j${"choices": [{"t": "4 ตัว และ 4 พันธะ"}, {"t": "4 ตัว และ 8 พันธะ"}, {"t": "6 ตัว และ 2 พันธะ"}, {"t": "2 ตัว และ 2 พันธะ"}], "answer": 0}$j$::jsonb, 1, $t$เลขอะตอม 6 (2,4)$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$คาร์บอนมีเวเลนซ์อิเล็กตรอนกี่ตัว และสร้างพันธะโคเวเลนต์ได้กี่พันธะ$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$รูปร่างโมเลกุลรอบคาร์บอนของมีเทนเป็นแบบใด$t$, $j${"choices": [{"t": "เส้นตรง"}, {"t": "พีระมิดฐานสี่เหลี่ยม"}, {"t": "สามเหลี่ยมแบนราบ"}, {"t": "เตตระฮีดรัล (มุม 109.5 องศา)"}], "answer": 3}$j$::jsonb, 1, $t$คาร์บอน sp3$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$รูปร่างโมเลกุลรอบคาร์บอนของมีเทนเป็นแบบใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'tf', $t$สารที่มีสูตร C3H8O เป็นได้ทั้งแอลกอฮอล์และอีเทอร์$t$, $j${"answer": true}$j$::jsonb, 1, $t$1-โพรพานอล 2-โพรพานอล และเอทิลเมทิลอีเทอร์$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$สารที่มีสูตร C3H8O เป็นได้ทั้งแอลกอฮอล์และอีเทอร์$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'tf', $t$CO2 จัดเป็นสารประกอบอินทรีย์เพราะมีคาร์บอน$t$, $j${"answer": false}$j$::jsonb, 1, $t$จัดเป็นสารอนินทรีย์$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$CO2 จัดเป็นสารประกอบอินทรีย์เพราะมีคาร์บอน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'drag', $t$ลากสารแต่ละชนิดไปยังหมู่ฟังก์ชันที่ถูกต้อง$t$, $j${"zones": [{"t": "แอลกอฮอล์"}, {"t": "แอลดีไฮด์"}, {"t": "กรดคาร์บอกซิลิก"}, {"t": "เอสเทอร์"}], "items": [{"t": "CH3CH2OH"}, {"t": "CH3CHO"}, {"t": "CH3COOH"}, {"t": "CH3COOCH3"}, {"t": "CH3CH2CH2OH"}, {"t": "HCOOH"}], "answer": [0, 1, 2, 3, 0, 2]}$j$::jsonb, 6, $t$ดู -OH, -CHO, -COOH และ -COO-$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$ลากสารแต่ละชนิดไปยังหมู่ฟังก์ชันที่ถูกต้อง$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'drag', $t$ลากสารแต่ละชนิดไปยังกลุ่มที่ถูกต้อง: ไฮโดรคาร์บอนอิ่มตัว / ไม่อิ่มตัว$t$, $j${"zones": [{"t": "อิ่มตัว"}, {"t": "ไม่อิ่มตัว"}], "items": [{"t": "CH3CH3"}, {"t": "CH2=CH2"}, {"t": "CH3CH2CH3"}, {"t": "HC≡CH"}, {"t": "CH3CH=CH2"}, {"t": "ไซโคลเฮกเซน"}], "answer": [0, 1, 0, 1, 1, 0]}$j$::jsonb, 6, $t$พันธะเดี่ยวล้วน = อิ่มตัว · มีพันธะคู่/สาม = ไม่อิ่มตัว$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$ลากสารแต่ละชนิดไปยังกลุ่มที่ถูกต้อง: ไฮโดรคาร์บอนอิ่มตัว / ไม่อิ่มตัว$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$มอนอเมอร์คืออะไร$t$, $j${"choices": [{"t": "หน่วยย่อยที่เป็นโมเลกุลเล็กซึ่งนำมาต่อกันเป็นพอลิเมอร์"}, {"t": "พอลิเมอร์ที่มีมวลโมเลกุลสูงมาก"}, {"t": "ตัวเร่งปฏิกิริยา"}, {"t": "ผลิตภัณฑ์พลอยได้ (น้ำ)"}], "answer": 0}$j$::jsonb, 1, $t$poly = มาก, mono = หนึ่งหน่วย$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$มอนอเมอร์คืออะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$พอลิเอทิลีนมีมอนอเมอร์ชนิดใด$t$, $j${"choices": [{"t": "เอทีน"}, {"t": "โพรพีน"}, {"t": "เอไทน์"}, {"t": "ไวนิลคลอไรด์"}], "answer": 0}$j$::jsonb, 1, $t$nCH2=CH2 → -(CH2CH2)n-$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พอลิเอทิลีนมีมอนอเมอร์ชนิดใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$พอลิโพรพิลีนมีมอนอเมอร์ชนิดใด$t$, $j${"choices": [{"t": "เอทีน"}, {"t": "โพรพีน"}, {"t": "สไตรีน"}, {"t": "บิวทีน"}], "answer": 1}$j$::jsonb, 1, $t$CH3CH=CH2$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พอลิโพรพิลีนมีมอนอเมอร์ชนิดใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$พอลิไวนิลคลอไรด์ (PVC) มีมอนอเมอร์ชนิดใด$t$, $j${"choices": [{"t": "สไตรีน"}, {"t": "เอทีน"}, {"t": "ไวนิลคลอไรด์ (CH2=CHCl)"}, {"t": "เตตระฟลูออโรเอทีน"}], "answer": 2}$j$::jsonb, 1, $t$ใช้ทำท่อน้ำ$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พอลิไวนิลคลอไรด์ (PVC) มีมอนอเมอร์ชนิดใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$พอลิสไตรีนมีมอนอเมอร์ชนิดใด$t$, $j${"choices": [{"t": "สไตรีน (C6H5CH=CH2)"}, {"t": "เอทีน"}, {"t": "โทลูอีน"}, {"t": "เบนซีน"}], "answer": 0}$j$::jsonb, 1, $t$ใช้ทำโฟมเม็ด/กล่องโฟม$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พอลิสไตรีนมีมอนอเมอร์ชนิดใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$เทฟลอน (PTFE) มีมอนอเมอร์ชนิดใด$t$, $j${"choices": [{"t": "โพรพีน"}, {"t": "ไวนิลคลอไรด์"}, {"t": "เตตระฟลูออโรเอทีน (CF2=CF2)"}, {"t": "เอทีน"}], "answer": 2}$j$::jsonb, 1, $t$ใช้เคลือบกระทะไม่ติด$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$เทฟลอน (PTFE) มีมอนอเมอร์ชนิดใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$พอลิเมอร์ชนิดเติม (addition polymer) เกิดจากมอนอเมอร์ที่มีลักษณะใด$t$, $j${"choices": [{"t": "มีหมู่ -NH2 เท่านั้น"}, {"t": "มีพันธะคู่ระหว่างคาร์บอน"}, {"t": "มีหมู่ -OH 2 หมู่"}, {"t": "มีหมู่ -COOH 2 หมู่"}], "answer": 1}$j$::jsonb, 1, $t$พันธะ π เปิดออกเพื่อต่อโซ่$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พอลิเมอร์ชนิดเติม (addition polymer) เกิดจากมอนอเมอร์ที่มีลักษณะใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$พอลิเมอร์ชนิดควบแน่น (condensation polymer) มีลักษณะสำคัญข้อใด$t$, $j${"choices": [{"t": "เกิดจากแอลเคนเท่านั้น"}, {"t": "ไม่มีผลิตภัณฑ์พลอยได้"}, {"t": "เกิดจากการเปิดพันธะคู่"}, {"t": "มอนอเมอร์ต่อกันพร้อมเสียโมเลกุลเล็ก เช่น น้ำ"}], "answer": 3}$j$::jsonb, 1, $t$เช่น ไนลอน พอลิเอสเทอร์$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พอลิเมอร์ชนิดควบแน่น (condensation polymer) มีลักษณะสำคัญข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$ไนลอน-6,6 เกิดจากมอนอเมอร์คู่ใด$t$, $j${"choices": [{"t": "กลูโคสและฟรุกโทส"}, {"t": "เอทีน และ โพรพีน"}, {"t": "กรดเทเรฟทาลิก และเอทิลีนไกลคอล"}, {"t": "กรดเฮกเซนไดโอิก และ เฮกเซน-1,6-ไดเอมีน"}], "answer": 3}$j$::jsonb, 1, $t$ต่อกันด้วยพันธะเอไมด์ เสียน้ำ$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$ไนลอน-6,6 เกิดจากมอนอเมอร์คู่ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$พันธะที่เชื่อมมอนอเมอร์ในไนลอนคือพันธะใด$t$, $j${"choices": [{"t": "พันธะอีเทอร์"}, {"t": "พันธะไกลโคซิดิก"}, {"t": "พันธะเอสเทอร์"}, {"t": "พันธะเอไมด์"}], "answer": 3}$j$::jsonb, 1, $t$-CO-NH-$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พันธะที่เชื่อมมอนอเมอร์ในไนลอนคือพันธะใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$พอลิเอทิลีนเทเรฟทาเลต (PET) เกิดจากพันธะใดเชื่อมมอนอเมอร์$t$, $j${"choices": [{"t": "พันธะเอสเทอร์"}, {"t": "พันธะเปปไทด์"}, {"t": "พันธะไกลโคซิดิก"}, {"t": "พันธะเอไมด์"}], "answer": 0}$j$::jsonb, 1, $t$PET เป็นพอลิเอสเทอร์ ใช้ทำขวดน้ำดื่ม$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พอลิเอทิลีนเทเรฟทาเลต (PET) เกิดจากพันธะใดเชื่อมมอนอเมอร์$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$ยางธรรมชาติมีมอนอเมอร์ชนิดใด$t$, $j${"choices": [{"t": "เอทีน"}, {"t": "บิวทาไดอีน"}, {"t": "สไตรีน"}, {"t": "ไอโซพรีน"}], "answer": 3}$j$::jsonb, 1, $t$2-เมทิล-1,3-บิวทาไดอีน$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$ยางธรรมชาติมีมอนอเมอร์ชนิดใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$การทำให้ยางวัลคาไนซ์ใช้สารใด$t$, $j${"choices": [{"t": "คลอรีน"}, {"t": "ไฮโดรเจน"}, {"t": "กำมะถัน (ซัลเฟอร์)"}, {"t": "โซเดียมไฮดรอกไซด์"}], "answer": 2}$j$::jsonb, 1, $t$เกิดพันธะเชื่อมขวางระหว่างโซ่ ยางแข็งแรงและยืดหยุ่นขึ้น$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$การทำให้ยางวัลคาไนซ์ใช้สารใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$พลาสติกเทอร์โมเซต (thermosetting) มีสมบัติอย่างไร$t$, $j${"choices": [{"t": "อ่อนตัวและหลอมได้เมื่อให้ความร้อนซ้ำ"}, {"t": "สลายตัวเป็นมอนอเมอร์เมื่อโดนแสง"}, {"t": "ละลายน้ำได้"}, {"t": "แข็ง เมื่อขึ้นรูปแล้วไม่หลอมเหลวเมื่อให้ความร้อนซ้ำ"}], "answer": 3}$j$::jsonb, 1, $t$มีพันธะเชื่อมขวางสามมิติ เช่น เบกาไลต์$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พลาสติกเทอร์โมเซต (thermosetting) มีสมบัติอย่างไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$พลาสติกเทอร์โมพลาสติกมีสมบัติอย่างไร$t$, $j${"choices": [{"t": "ระเหยเป็นไอเมื่อได้รับความร้อน"}, {"t": "ไม่เปลี่ยนแปลงเมื่อได้รับความร้อน"}, {"t": "อ่อนตัวและหลอมเมื่อได้รับความร้อน นำกลับมาขึ้นรูปใหม่ได้"}, {"t": "แข็งและไม่หลอมเมื่อได้รับความร้อน"}], "answer": 2}$j$::jsonb, 1, $t$โซ่ไม่มีพันธะเชื่อมขวาง เช่น PE PP PVC$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พลาสติกเทอร์โมพลาสติกมีสมบัติอย่างไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$พอลิเมอร์ชนิดใดต่อไปนี้เป็นพอลิเมอร์ธรรมชาติ$t$, $j${"choices": [{"t": "PVC"}, {"t": "แป้ง"}, {"t": "เทฟลอน"}, {"t": "ไนลอน"}], "answer": 1}$j$::jsonb, 1, $t$แป้งเป็นพอลิเมอร์ของกลูโคส$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พอลิเมอร์ชนิดใดต่อไปนี้เป็นพอลิเมอร์ธรรมชาติ$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$พอลิเมอร์ที่ย่อยสลายได้ทางชีวภาพคือข้อใด$t$, $j${"choices": [{"t": "PVC"}, {"t": "พอลิแลกติกแอซิด (PLA)"}, {"t": "เทฟลอน"}, {"t": "พอลิสไตรีน"}], "answer": 1}$j$::jsonb, 1, $t$ผลิตจากกรดแลกติก ย่อยสลายได้ภายใต้สภาวะที่เหมาะสม$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พอลิเมอร์ที่ย่อยสลายได้ทางชีวภาพคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$พอลิเอทิลีนที่มีโซ่ตรงอัดแน่นกว่าและแข็งกว่าเรียกว่าอะไร$t$, $j${"choices": [{"t": "PET"}, {"t": "HDPE"}, {"t": "PVC"}, {"t": "LDPE"}], "answer": 1}$j$::jsonb, 1, $t$High-density polyethylene$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พอลิเอทิลีนที่มีโซ่ตรงอัดแน่นกว่าและแข็งกว่าเรียกว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$ถ้าพอลิเอทิลีนสายหนึ่งมี n = 1000 หน่วยซ้ำ มวลโมเลกุลประมาณเท่าไร (C = 12, H = 1)$t$, $j${"choices": [{"t": "28,000"}, {"t": "56,000"}, {"t": "2,800"}, {"t": "14,000"}], "answer": 0}$j$::jsonb, 1, $t$หน่วยซ้ำ CH2CH2 = 28 → 28 × 1000$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$ถ้าพอลิเอทิลีนสายหนึ่งมี n = 1000 หน่วยซ้ำ มวลโมเลกุลประมาณเท่าไร (C = 12, H = 1)$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$ปัญหาสิ่งแวดล้อมหลักของพลาสติกส่วนใหญ่คืออะไร$t$, $j${"choices": [{"t": "เป็นสารกัมมันตรังสี"}, {"t": "ย่อยสลายยากและตกค้างเป็นเวลานาน"}, {"t": "ละลายหมดในน้ำฝน"}, {"t": "ทำให้ดินมีสภาพเป็นกรดจัด"}], "answer": 1}$j$::jsonb, 1, $t$ควรลดการใช้ นำกลับมาใช้ซ้ำ และรีไซเคิล$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$ปัญหาสิ่งแวดล้อมหลักของพลาสติกส่วนใหญ่คืออะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'tf', $t$พอลิเมอร์ชนิดเติมมักไม่เกิดผลิตภัณฑ์พลอยได้$t$, $j${"answer": true}$j$::jsonb, 1, $t$มอนอเมอร์ต่อกันโดยไม่เสียโมเลกุลเล็ก$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พอลิเมอร์ชนิดเติมมักไม่เกิดผลิตภัณฑ์พลอยได้$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'tf', $t$ไนลอนเป็นพอลิเมอร์ชนิดเติม$t$, $j${"answer": false}$j$::jsonb, 1, $t$ไนลอนเป็นพอลิเมอร์ชนิดควบแน่น$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$ไนลอนเป็นพอลิเมอร์ชนิดเติม$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'tf', $t$พอลิเมอร์มีมวลโมเลกุลสูงเพราะประกอบด้วยหน่วยซ้ำจำนวนมาก$t$, $j${"answer": true}$j$::jsonb, 1, $t$n มักเป็นหลักร้อยถึงหลักล้าน$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พอลิเมอร์มีมวลโมเลกุลสูงเพราะประกอบด้วยหน่วยซ้ำจำนวนมาก$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'match', $t$จับคู่พอลิเมอร์กับมอนอเมอร์$t$, $j${"left": [{"t": "พอลิเอทิลีน"}, {"t": "พอลิโพรพิลีน"}, {"t": "PVC"}, {"t": "พอลิสไตรีน"}], "right": [{"t": "ไอโซพรีน"}, {"t": "สไตรีน"}, {"t": "โพรพีน"}, {"t": "ไวนิลคลอไรด์"}, {"t": "เอทีน"}], "pairs": [4, 2, 3, 1]}$j$::jsonb, 4, $t$ชื่อพอลิเมอร์มักบอกมอนอเมอร์$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$จับคู่พอลิเมอร์กับมอนอเมอร์$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$กลูโคสมีสูตรโมเลกุลใด$t$, $j${"choices": [{"t": "C6H12O6"}, {"t": "C6H10O5"}, {"t": "C5H10O5"}, {"t": "C12H22O11"}], "answer": 0}$j$::jsonb, 1, $t$โมโนแซ็กคาไรด์หกคาร์บอน$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$กลูโคสมีสูตรโมเลกุลใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$คาร์โบไฮเดรตมีสูตรทั่วไปตามข้อใด$t$, $j${"choices": [{"t": "CnH2n+2"}, {"t": "CnH2n-2"}, {"t": "CnH2nO2"}, {"t": "Cn(H2O)m"}], "answer": 3}$j$::jsonb, 1, $t$ชื่อ "คาร์บอนที่มีน้ำ"$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$คาร์โบไฮเดรตมีสูตรทั่วไปตามข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$กลูโคสและฟรุกโทสเป็นไอโซเมอร์กัน เพราะเหตุใด$t$, $j${"choices": [{"t": "มีมวลโมเลกุลต่างกัน"}, {"t": "เป็นพอลิเมอร์ทั้งคู่"}, {"t": "สูตรโมเลกุลเดียวกัน (C6H12O6) แต่โครงสร้างต่างกัน"}, {"t": "มีหมู่ฟังก์ชันเหมือนกันทุกประการ"}], "answer": 2}$j$::jsonb, 1, $t$กลูโคสมีหมู่แอลดีไฮด์ ส่วนฟรุกโทสมีหมู่คีโตน$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$กลูโคสและฟรุกโทสเป็นไอโซเมอร์กัน เพราะเหตุใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$ซูโครสเป็นไดแซ็กคาไรด์ที่เกิดจากมอนอเมอร์คู่ใด$t$, $j${"choices": [{"t": "ฟรุกโทสและกาแล็กโทส"}, {"t": "กลูโคสและฟรุกโทส"}, {"t": "กลูโคสและกาแล็กโทส"}, {"t": "กลูโคสและกลูโคส"}], "answer": 1}$j$::jsonb, 1, $t$น้ำตาลทราย$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$ซูโครสเป็นไดแซ็กคาไรด์ที่เกิดจากมอนอเมอร์คู่ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$มอลโทสเป็นไดแซ็กคาไรด์ที่เกิดจากมอนอเมอร์คู่ใด$t$, $j${"choices": [{"t": "ฟรุกโทสและกาแล็กโทส"}, {"t": "กลูโคสและฟรุกโทส"}, {"t": "กลูโคสและกาแล็กโทส"}, {"t": "กลูโคสและกลูโคส"}], "answer": 3}$j$::jsonb, 1, $t$น้ำตาลมอลต์$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$มอลโทสเป็นไดแซ็กคาไรด์ที่เกิดจากมอนอเมอร์คู่ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$แล็กโทสซึ่งพบในนมเกิดจากมอนอเมอร์คู่ใด$t$, $j${"choices": [{"t": "ฟรุกโทสและฟรุกโทส"}, {"t": "กลูโคสและฟรุกโทส"}, {"t": "กลูโคสและกลูโคส"}, {"t": "กลูโคสและกาแล็กโทส"}], "answer": 3}$j$::jsonb, 1, $t$น้ำตาลนม$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$แล็กโทสซึ่งพบในนมเกิดจากมอนอเมอร์คู่ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$พันธะที่เชื่อมแซ็กคาไรด์สองหน่วยเข้าด้วยกันเรียกว่าอะไร$t$, $j${"choices": [{"t": "พันธะไกลโคซิดิก"}, {"t": "พันธะเอสเทอร์"}, {"t": "พันธะไฮโดรเจน"}, {"t": "พันธะเปปไทด์"}], "answer": 0}$j$::jsonb, 1, $t$เกิดจากการเสียน้ำระหว่างหมู่ -OH$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$พันธะที่เชื่อมแซ็กคาไรด์สองหน่วยเข้าด้วยกันเรียกว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$เมื่อกลูโคส 2 โมเลกุลรวมกันเป็นมอลโทส จะเกิดผลิตภัณฑ์พลอยได้ใด$t$, $j${"choices": [{"t": "น้ำ 1 โมเลกุล"}, {"t": "แก๊สไฮโดรเจน"}, {"t": "ไม่มีผลิตภัณฑ์พลอยได้"}, {"t": "CO2 1 โมเลกุล"}], "answer": 0}$j$::jsonb, 1, $t$2C6H12O6 → C12H22O11 + H2O$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$เมื่อกลูโคส 2 โมเลกุลรวมกันเป็นมอลโทส จะเกิดผลิตภัณฑ์พลอยได้ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$น้ำตาลชนิดใดไม่เป็นน้ำตาลรีดิวซ์ (ไม่ให้ผลบวกกับเบเนดิกต์โดยตรง)$t$, $j${"choices": [{"t": "ซูโครส"}, {"t": "กลูโคส"}, {"t": "มอลโทส"}, {"t": "ฟรุกโทส"}], "answer": 0}$j$::jsonb, 1, $t$ซูโครสไม่มีหมู่แอลดีไฮด์หรือคีโตนอิสระ$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$น้ำตาลชนิดใดไม่เป็นน้ำตาลรีดิวซ์ (ไม่ให้ผลบวกกับเบเนดิกต์โดยตรง)$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$น้ำตาลชนิดใดให้ผลบวกกับสารละลายเบเนดิกต์$t$, $j${"choices": [{"t": "แป้ง"}, {"t": "เซลลูโลส"}, {"t": "กลูโคส"}, {"t": "ซูโครส"}], "answer": 2}$j$::jsonb, 1, $t$น้ำตาลรีดิวซ์ให้ตะกอนแดงอิฐ$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$น้ำตาลชนิดใดให้ผลบวกกับสารละลายเบเนดิกต์$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$สารละลายไอโอดีนใช้ทดสอบสารใด และให้สีอะไร$t$, $j${"choices": [{"t": "แป้ง ให้สีน้ำเงินเข้ม (ม่วงเข้ม)"}, {"t": "โปรตีน ให้สีม่วง"}, {"t": "กลูโคส ให้สีแดง"}, {"t": "เซลลูโลส ให้สีเขียว"}], "answer": 0}$j$::jsonb, 1, $t$แป้ง + I2 → สารเชิงซ้อนสีน้ำเงินเข้ม$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$สารละลายไอโอดีนใช้ทดสอบสารใด และให้สีอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$พอลิแซ็กคาไรด์ที่พืชใช้สะสมพลังงานคือข้อใด$t$, $j${"choices": [{"t": "ไกลโคเจน"}, {"t": "เซลลูโลส"}, {"t": "ซูโครส"}, {"t": "แป้ง"}], "answer": 3}$j$::jsonb, 1, $t$สะสมในเมล็ด หัว ราก$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$พอลิแซ็กคาไรด์ที่พืชใช้สะสมพลังงานคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$พอลิแซ็กคาไรด์ที่เป็นโครงสร้างผนังเซลล์พืชคือข้อใด$t$, $j${"choices": [{"t": "เซลลูโลส"}, {"t": "ไกลโคเจน"}, {"t": "มอลโทส"}, {"t": "แป้ง"}], "answer": 0}$j$::jsonb, 1, $t$ประกอบด้วยกลูโคสต่อกันเป็นโซ่ตรงยาว$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$พอลิแซ็กคาไรด์ที่เป็นโครงสร้างผนังเซลล์พืชคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$พอลิแซ็กคาไรด์ที่สัตว์ใช้สะสมพลังงานในตับและกล้ามเนื้อคือข้อใด$t$, $j${"choices": [{"t": "ไกลโคเจน"}, {"t": "ไคติน"}, {"t": "เซลลูโลส"}, {"t": "แป้ง"}], "answer": 0}$j$::jsonb, 1, $t$คล้ายอะไมโลเพกตินแต่แตกกิ่งมากกว่า$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$พอลิแซ็กคาไรด์ที่สัตว์ใช้สะสมพลังงานในตับและกล้ามเนื้อคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$เหตุใดมนุษย์ย่อยเซลลูโลสไม่ได้$t$, $j${"choices": [{"t": "เซลลูโลสละลายในน้ำมาก"}, {"t": "ไม่มีเอนไซม์เซลลูเลสสำหรับย่อยพันธะ β-ไกลโคซิดิก"}, {"t": "เซลลูโลสเป็นไขมัน"}, {"t": "เซลลูโลสเป็นโปรตีน"}], "answer": 1}$j$::jsonb, 1, $t$สัตว์เคี้ยวเอื้องย่อยได้เพราะจุลินทรีย์ในกระเพาะ$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$เหตุใดมนุษย์ย่อยเซลลูโลสไม่ได้$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$เมื่อไฮโดรไลซ์แป้งอย่างสมบูรณ์ด้วยกรดหรือเอนไซม์ ได้ผลิตภัณฑ์สุดท้ายใด$t$, $j${"choices": [{"t": "ฟรุกโทส"}, {"t": "กลูโคส"}, {"t": "กรดอะมิโน"}, {"t": "กลีเซอรอล"}], "answer": 1}$j$::jsonb, 1, $t$แป้งเป็นพอลิเมอร์ของกลูโคส$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$เมื่อไฮโดรไลซ์แป้งอย่างสมบูรณ์ด้วยกรดหรือเอนไซม์ ได้ผลิตภัณฑ์สุดท้ายใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$เมื่อไฮโดรไลซ์ซูโครส ได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "กลูโคส 2 โมเลกุล"}, {"t": "กลูโคสและกาแล็กโทส"}, {"t": "กลูโคสและฟรุกโทส"}, {"t": "กลีเซอรอลและกรดไขมัน"}], "answer": 2}$j$::jsonb, 1, $t$ได้น้ำตาลอินเวิร์ต$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$เมื่อไฮโดรไลซ์ซูโครส ได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$น้ำตาลชนิดใดมีรสหวานมากที่สุดในกลุ่มมอนอแซ็กคาไรด์$t$, $j${"choices": [{"t": "กลูโคส"}, {"t": "ไรโบส"}, {"t": "กาแล็กโทส"}, {"t": "ฟรุกโทส"}], "answer": 3}$j$::jsonb, 1, $t$พบในน้ำผึ้งและผลไม้$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$น้ำตาลชนิดใดมีรสหวานมากที่สุดในกลุ่มมอนอแซ็กคาไรด์$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$เอนไซม์อะไมเลสในน้ำลายช่วยย่อยสารใด$t$, $j${"choices": [{"t": "ไขมัน"}, {"t": "โปรตีน"}, {"t": "แป้ง"}, {"t": "เซลลูโลส"}], "answer": 2}$j$::jsonb, 1, $t$แป้งถูกย่อยเป็นมอลโทสและกลูโคส$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$เอนไซม์อะไมเลสในน้ำลายช่วยย่อยสารใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$ไรโบสมีจำนวนคาร์บอนกี่อะตอม$t$, $j${"choices": [{"t": "5 อะตอม"}, {"t": "4 อะตอม"}, {"t": "6 อะตอม"}, {"t": "12 อะตอม"}], "answer": 0}$j$::jsonb, 1, $t$เพนโทส C5H10O5 เป็นส่วนประกอบของ RNA$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$ไรโบสมีจำนวนคาร์บอนกี่อะตอม$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'tf', $t$แป้งและเซลลูโลสเป็นพอลิเมอร์ของกลูโคสทั้งคู่$t$, $j${"answer": true}$j$::jsonb, 1, $t$ต่างกันที่รูปแบบพันธะไกลโคซิดิก (α และ β)$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$แป้งและเซลลูโลสเป็นพอลิเมอร์ของกลูโคสทั้งคู่$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'tf', $t$ซูโครสให้ผลบวกกับเบเนดิกต์ทันทีโดยไม่ต้องไฮโดรไลซ์$t$, $j${"answer": false}$j$::jsonb, 1, $t$ซูโครสไม่ใช่น้ำตาลรีดิวซ์ ต้องถูกไฮโดรไลซ์ก่อน$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$ซูโครสให้ผลบวกกับเบเนดิกต์ทันทีโดยไม่ต้องไฮโดรไลซ์$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'match', $t$จับคู่คาร์โบไฮเดรตกับชนิด$t$, $j${"left": [{"t": "กลูโคส"}, {"t": "ซูโครส"}, {"t": "แป้ง"}, {"t": "เซลลูโลส"}], "right": [{"t": "มอนอแซ็กคาไรด์"}, {"t": "ไดแซ็กคาไรด์"}, {"t": "พอลิแซ็กคาไรด์ (โครงสร้างพืช)"}, {"t": "โปรตีน"}, {"t": "พอลิแซ็กคาไรด์"}], "pairs": [0, 1, 4, 2]}$j$::jsonb, 4, $t$จำนวนหน่วยน้ำตาล: 1, 2, จำนวนมาก$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$จับคู่คาร์โบไฮเดรตกับชนิด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$กรดอะมิโนมีหมู่ฟังก์ชันใดอยู่ในโมเลกุล$t$, $j${"choices": [{"t": "-CO- และ -OH"}, {"t": "หมู่อะมิโน (-NH2) และหมู่คาร์บอกซิล (-COOH)"}, {"t": "-COOR และ -NH2 เท่านั้น"}, {"t": "-OH และ -CHO"}], "answer": 1}$j$::jsonb, 1, $t$ต่อที่คาร์บอนตัวเดียวกัน (α-คาร์บอน)$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$กรดอะมิโนมีหมู่ฟังก์ชันใดอยู่ในโมเลกุล$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$โครงสร้างทั่วไปของ α-กรดอะมิโนคือข้อใด$t$, $j${"choices": [{"t": "H2N-CH(R)-COOH"}, {"t": "H2N-CH2-CH2-COOH เสมอ"}, {"t": "R-CO-NH2"}, {"t": "HOOC-R-COOH"}], "answer": 0}$j$::jsonb, 1, $t$R คือหมู่ข้างเคียงที่ต่างกันในแต่ละกรดอะมิโน$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$โครงสร้างทั่วไปของ α-กรดอะมิโนคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$กรดอะมิโนชนิดใดที่ R เป็น H$t$, $j${"choices": [{"t": "ไกลซีน"}, {"t": "อะลานีน"}, {"t": "ไลซีน"}, {"t": "ซีสเตอีน"}], "answer": 0}$j$::jsonb, 1, $t$H2N-CH2-COOH ไม่มีไครัลคาร์บอน$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$กรดอะมิโนชนิดใดที่ R เป็น H$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$พันธะที่เชื่อมกรดอะมิโนเข้าด้วยกันในโปรตีนเรียกว่าอะไร$t$, $j${"choices": [{"t": "พันธะไกลโคซิดิก"}, {"t": "พันธะไฮโดรเจน"}, {"t": "พันธะเอสเทอร์"}, {"t": "พันธะเปปไทด์"}], "answer": 3}$j$::jsonb, 1, $t$เกิดระหว่างหมู่ -COOH กับ -NH2 พร้อมเสียน้ำ$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$พันธะที่เชื่อมกรดอะมิโนเข้าด้วยกันในโปรตีนเรียกว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$กรดอะมิโน 2 โมเลกุลรวมกันเป็นไดเปปไทด์ จะเสียน้ำกี่โมเลกุล$t$, $j${"choices": [{"t": "2 โมเลกุล"}, {"t": "0 โมเลกุล"}, {"t": "1 โมเลกุล"}, {"t": "3 โมเลกุล"}], "answer": 2}$j$::jsonb, 1, $t$สร้างพันธะเปปไทด์ 1 พันธะ$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$กรดอะมิโน 2 โมเลกุลรวมกันเป็นไดเปปไทด์ จะเสียน้ำกี่โมเลกุล$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$โพลีเปปไทด์สายตรงที่ประกอบด้วยกรดอะมิโน 10 หน่วยมีพันธะเปปไทด์กี่พันธะ$t$, $j${"choices": [{"t": "11 พันธะ"}, {"t": "9 พันธะ"}, {"t": "10 พันธะ"}, {"t": "8 พันธะ"}], "answer": 1}$j$::jsonb, 1, $t$n หน่วย → n − 1 พันธะ$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$โพลีเปปไทด์สายตรงที่ประกอบด้วยกรดอะมิโน 10 หน่วยมีพันธะเปปไทด์กี่พันธะ$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$เมื่อกรดอะมิโน 5 โมเลกุลรวมเป็นสายตรง จะเสียน้ำกี่โมเลกุล$t$, $j${"choices": [{"t": "6 โมเลกุล"}, {"t": "3 โมเลกุล"}, {"t": "4 โมเลกุล"}, {"t": "5 โมเลกุล"}], "answer": 2}$j$::jsonb, 1, $t$n − 1 = 4$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$เมื่อกรดอะมิโน 5 โมเลกุลรวมเป็นสายตรง จะเสียน้ำกี่โมเลกุล$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$การทดสอบไบยูเรต (biuret) ใช้ตรวจสารใด และผลบวกให้สีอะไร$t$, $j${"choices": [{"t": "น้ำตาลรีดิวซ์ ให้ตะกอนแดงอิฐ"}, {"t": "โปรตีน (พันธะเปปไทด์) ให้สีม่วง"}, {"t": "ไขมัน ให้สีเหลือง"}, {"t": "แป้ง ให้สีน้ำเงินเข้ม"}], "answer": 1}$j$::jsonb, 1, $t$Cu2+ เกิดสารเชิงซ้อนกับพันธะเปปไทด์$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$การทดสอบไบยูเรต (biuret) ใช้ตรวจสารใด และผลบวกให้สีอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$การเสียสภาพของโปรตีน (denaturation) เกิดจากปัจจัยใด$t$, $j${"choices": [{"t": "การแช่แข็งเฉยๆ"}, {"t": "การเติมน้ำเปล่า"}, {"t": "การเติมแป้ง"}, {"t": "ความร้อน กรดหรือเบสแก่ ตัวทำละลายอินทรีย์ หรือโลหะหนัก"}], "answer": 3}$j$::jsonb, 1, $t$โครงสร้างสามมิติถูกทำลาย แต่ลำดับกรดอะมิโนยังอยู่$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$การเสียสภาพของโปรตีน (denaturation) เกิดจากปัจจัยใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$เมื่อต้มไข่ขาวจนขาวขุ่นแข็งเป็นตัวอย่างของอะไร$t$, $j${"choices": [{"t": "การไฮโดรไลซ์แป้ง"}, {"t": "การเสียสภาพของโปรตีน"}, {"t": "การหมัก"}, {"t": "การเกิดเอสเทอร์"}], "answer": 1}$j$::jsonb, 1, $t$ความร้อนทำให้โครงสร้างสามมิติเปลี่ยน$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$เมื่อต้มไข่ขาวจนขาวขุ่นแข็งเป็นตัวอย่างของอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$โครงสร้างปฐมภูมิของโปรตีนหมายถึงข้อใด$t$, $j${"choices": [{"t": "ลำดับของกรดอะมิโนในสายโพลีเปปไทด์"}, {"t": "การรวมของหลายสายโพลีเปปไทด์"}, {"t": "การพับตัวสามมิติรวม"}, {"t": "การม้วนเป็นเกลียวแอลฟา"}], "answer": 0}$j$::jsonb, 1, $t$ลำดับกำหนดโดยรหัสพันธุกรรม$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$โครงสร้างปฐมภูมิของโปรตีนหมายถึงข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$เกลียวแอลฟา (α-helix) และแผ่นเบตา (β-sheet) จัดเป็นโครงสร้างระดับใดของโปรตีน$t$, $j${"choices": [{"t": "ทุติยภูมิ"}, {"t": "ตติยภูมิ"}, {"t": "ปฐมภูมิ"}, {"t": "จตุตถภูมิ"}], "answer": 0}$j$::jsonb, 1, $t$เสถียรด้วยพันธะไฮโดรเจนระหว่างหมู่ C=O กับ N-H ของแกนหลัก$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$เกลียวแอลฟา (α-helix) และแผ่นเบตา (β-sheet) จัดเป็นโครงสร้างระดับใดของโปรตีน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$พันธะชนิดใดหลักที่ทำให้โครงสร้างทุติยภูมิของโปรตีนเสถียร$t$, $j${"choices": [{"t": "พันธะโลหะ"}, {"t": "พันธะไฮโดรเจน"}, {"t": "พันธะไอออนิกล้วน"}, {"t": "พันธะคู่ C=C"}], "answer": 1}$j$::jsonb, 1, $t$ระหว่าง C=O และ N-H ของแกนหลัก$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$พันธะชนิดใดหลักที่ทำให้โครงสร้างทุติยภูมิของโปรตีนเสถียร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$เอนไซม์ส่วนใหญ่เป็นสารชีวโมเลกุลประเภทใด$t$, $j${"choices": [{"t": "คาร์โบไฮเดรต"}, {"t": "ไขมัน"}, {"t": "กรดนิวคลีอิก"}, {"t": "โปรตีน"}], "answer": 3}$j$::jsonb, 1, $t$ทำหน้าที่เป็นตัวเร่งปฏิกิริยาในสิ่งมีชีวิต$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$เอนไซม์ส่วนใหญ่เป็นสารชีวโมเลกุลประเภทใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$ฮีโมโกลบินทำหน้าที่ใด$t$, $j${"choices": [{"t": "สะสมไขมัน"}, {"t": "ย่อยแป้ง"}, {"t": "ต้านทานการแข็งตัวของเลือดเท่านั้น"}, {"t": "ลำเลียงออกซิเจนในเลือด"}], "answer": 3}$j$::jsonb, 1, $t$เป็นโปรตีนที่มีฮีม (เหล็ก)$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$ฮีโมโกลบินทำหน้าที่ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$กรดอะมิโนที่จำเป็น (essential amino acid) หมายถึงข้อใด$t$, $j${"choices": [{"t": "กรดอะมิโนที่ร่างกายสร้างเองไม่ได้ ต้องได้รับจากอาหาร"}, {"t": "กรดอะมิโนที่ร่างกายสร้างได้มากเกินพอ"}, {"t": "กรดอะมิโนที่ไม่พบในโปรตีน"}, {"t": "กรดอะมิโนที่มีหมู่ -OH"}], "answer": 0}$j$::jsonb, 1, $t$ผู้ใหญ่มี 9 ชนิด$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$กรดอะมิโนที่จำเป็น (essential amino acid) หมายถึงข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$เอนไซม์เพปซินในกระเพาะอาหารย่อยสารใด$t$, $j${"choices": [{"t": "โปรตีน"}, {"t": "ไขมัน"}, {"t": "แป้ง"}, {"t": "เซลลูโลส"}], "answer": 0}$j$::jsonb, 1, $t$ทำงานได้ดีในสภาพกรดของกระเพาะ$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$เอนไซม์เพปซินในกระเพาะอาหารย่อยสารใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$โปรตีนจากเนื้อสัตว์เมื่อถูกย่อยอย่างสมบูรณ์ได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "กรดอะมิโน"}, {"t": "กลีเซอรอล"}, {"t": "กรดไขมัน"}, {"t": "กลูโคส"}], "answer": 0}$j$::jsonb, 1, $t$พันธะเปปไทด์ถูกไฮโดรไลซ์$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$โปรตีนจากเนื้อสัตว์เมื่อถูกย่อยอย่างสมบูรณ์ได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'tf', $t$ไกลซีนเป็นกรดอะมิโนที่ไม่มีคาร์บอนไครัล$t$, $j${"answer": true}$j$::jsonb, 1, $t$R = H คาร์บอนต่อกับ H 2 อะตอมเหมือนกัน$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$ไกลซีนเป็นกรดอะมิโนที่ไม่มีคาร์บอนไครัล$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'tf', $t$การเสียสภาพของโปรตีนทำให้ลำดับกรดอะมิโนเปลี่ยนไป$t$, $j${"answer": false}$j$::jsonb, 1, $t$เปลี่ยนเฉพาะโครงสร้างสามมิติ ลำดับกรดอะมิโนคงเดิม$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$การเสียสภาพของโปรตีนทำให้ลำดับกรดอะมิโนเปลี่ยนไป$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'match', $t$จับคู่หัวข้อกับข้อมูลของโปรตีน$t$, $j${"left": [{"t": "พันธะเชื่อมกรดอะมิโน"}, {"t": "ตรวจโปรตีนด้วยสารละลายคอปเปอร์(II)"}, {"t": "โครงสร้างปฐมภูมิ"}, {"t": "เกลียวแอลฟา"}], "right": [{"t": "พันธะไกลโคซิดิก"}, {"t": "โครงสร้างทุติยภูมิ"}, {"t": "ไบยูเรต สีม่วง"}, {"t": "พันธะเปปไทด์"}, {"t": "ลำดับกรดอะมิโน"}], "pairs": [3, 2, 4, 1]}$j$::jsonb, 4, $t$เชื่อมโยงสมบัติกับโครงสร้างโปรตีน$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$จับคู่หัวข้อกับข้อมูลของโปรตีน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$ไขมันและน้ำมัน (ไตรกลีเซอไรด์) เกิดจากสารคู่ใด$t$, $j${"choices": [{"t": "เอทานอล 3 โมเลกุล และกรด 1 โมเลกุล"}, {"t": "กรดไขมัน 1 โมเลกุลและกลีเซอรอล 3 โมเลกุล"}, {"t": "กลีเซอรอล 1 โมเลกุล และกรดไขมัน 3 โมเลกุล"}, {"t": "กลูโคส 1 โมเลกุล และกรดอะมิโน 3 โมเลกุล"}], "answer": 2}$j$::jsonb, 1, $t$พันธะเอสเทอร์ 3 พันธะ$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$ไขมันและน้ำมัน (ไตรกลีเซอไรด์) เกิดจากสารคู่ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$ในโมเลกุลไตรกลีเซอไรด์ 1 โมเลกุล มีพันธะเอสเทอร์กี่พันธะ$t$, $j${"choices": [{"t": "1 พันธะ"}, {"t": "3 พันธะ"}, {"t": "6 พันธะ"}, {"t": "2 พันธะ"}], "answer": 1}$j$::jsonb, 1, $t$กลีเซอรอล 3 หมู่ -OH รวมกับกรดไขมัน 3 โมเลกุล$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$ในโมเลกุลไตรกลีเซอไรด์ 1 โมเลกุล มีพันธะเอสเทอร์กี่พันธะ$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$กรดไขมันอิ่มตัวต่างจากกรดไขมันไม่อิ่มตัวอย่างไร$t$, $j${"choices": [{"t": "กรดไขมันอิ่มตัวมีพันธะคู่หลายพันธะ"}, {"t": "กรดไขมันอิ่มตัวไม่มีพันธะคู่ C=C ในสายไฮโดรคาร์บอน"}, {"t": "กรดไขมันอิ่มตัวมีไนโตรเจน"}, {"t": "กรดไขมันอิ่มตัวไม่มีหมู่ -COOH"}], "answer": 1}$j$::jsonb, 1, $t$ไขมันสัตว์มีกรดไขมันอิ่มตัวสูง$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$กรดไขมันอิ่มตัวต่างจากกรดไขมันไม่อิ่มตัวอย่างไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$น้ำมันพืชมักเป็นของเหลวที่อุณหภูมิห้อง เพราะเหตุใด$t$, $j${"choices": [{"t": "มีน้ำเป็นองค์ประกอบมาก"}, {"t": "มีโปรตีนมาก"}, {"t": "มีกรดไขมันไม่อิ่มตัวมาก โซ่งอ จัดเรียงชิดกันได้ยาก จุดหลอมเหลวต่ำ"}, {"t": "มีกรดไขมันอิ่มตัวมาก"}], "answer": 2}$j$::jsonb, 1, $t$พันธะคู่แบบซิสทำให้โซ่งอ$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$น้ำมันพืชมักเป็นของเหลวที่อุณหภูมิห้อง เพราะเหตุใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$ปฏิกิริยาไฮโดรจีเนชันของน้ำมันพืชทำให้เกิดอะไร$t$, $j${"choices": [{"t": "ได้น้ำมันที่เหลวขึ้น"}, {"t": "ได้โปรตีน"}, {"t": "ได้กลูโคส"}, {"t": "ได้ไขมันที่แข็งขึ้น (เช่น มาร์การีน)"}], "answer": 3}$j$::jsonb, 1, $t$เติม H2 ที่พันธะคู่ ทำให้อิ่มตัวมากขึ้น$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$ปฏิกิริยาไฮโดรจีเนชันของน้ำมันพืชทำให้เกิดอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$สะปอนนิฟิเคชันคือปฏิกิริยาระหว่างไตรกลีเซอไรด์กับสารใด$t$, $j${"choices": [{"t": "สารละลายเบสแก่ เช่น NaOH"}, {"t": "สารละลายกรดอ่อน"}, {"t": "น้ำเย็น"}, {"t": "แก๊สไฮโดรเจน"}], "answer": 0}$j$::jsonb, 1, $t$ได้สบู่และกลีเซอรอล$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$สะปอนนิฟิเคชันคือปฏิกิริยาระหว่างไตรกลีเซอไรด์กับสารใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$ผลิตภัณฑ์จากสะปอนนิฟิเคชันของน้ำมันพืชด้วย NaOH คือข้อใด$t$, $j${"choices": [{"t": "สบู่ (โซเดียมเกลือของกรดไขมัน) และกลีเซอรอล"}, {"t": "กรดไขมันและน้ำ"}, {"t": "แป้งและน้ำ"}, {"t": "กลูโคสและเอทานอล"}], "answer": 0}$j$::jsonb, 1, $t$RCOONa + C3H5(OH)3$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$ผลิตภัณฑ์จากสะปอนนิฟิเคชันของน้ำมันพืชด้วย NaOH คือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$โมเลกุลสบู่ส่วนหัวชอบน้ำและส่วนหางชอบน้ำมัน ลักษณะนี้เรียกว่าอะไร$t$, $j${"choices": [{"t": "ไอโซเมอริก"}, {"t": "แอมฟิพาทิก (ส่วนหัวมีขั้ว ส่วนหางไม่มีขั้ว)"}, {"t": "โมโนเมอริก"}, {"t": "รีดิวซ์"}], "answer": 1}$j$::jsonb, 1, $t$หัว -COO-Na+ ชอบน้ำ · หาง R ชอบไขมัน$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$โมเลกุลสบู่ส่วนหัวชอบน้ำและส่วนหางชอบน้ำมัน ลักษณะนี้เรียกว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$สบู่ขจัดคราบไขมันได้ด้วยกลไกใด$t$, $j${"choices": [{"t": "ทำปฏิกิริยากับไขมันให้กลายเป็นแก๊ส"}, {"t": "ย่อยไขมันเป็นกลูโคส"}, {"t": "ทำให้ไขมันเป็นไอออนิก"}, {"t": "หางจับคราบไขมันเกิดไมเซลล์ ส่วนหัวหันออกสู่น้ำ"}], "answer": 3}$j$::jsonb, 1, $t$ไมเซลล์ลอยไปกับน้ำล้างออกได้$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$สบู่ขจัดคราบไขมันได้ด้วยกลไกใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$เหตุใดสบู่ทำงานไม่ดีในน้ำกระด้าง$t$, $j${"choices": [{"t": "Ca2+ และ Mg2+ ทำให้เกิดตะกอนเกลือของกรดไขมันที่ไม่ละลาย"}, {"t": "น้ำกระด้างทำให้สบู่ไหม้"}, {"t": "น้ำกระด้างเป็นกรดแก่มาก"}, {"t": "น้ำกระด้างมีไขมันสูง"}], "answer": 0}$j$::jsonb, 1, $t$เกิดคราบสบู่ (scum)$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$เหตุใดสบู่ทำงานไม่ดีในน้ำกระด้าง$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$ผงซักฟอกสังเคราะห์ทำงานได้ดีในน้ำกระด้าง เพราะเหตุใด$t$, $j${"choices": [{"t": "เกลือแคลเซียมและแมกนีเซียมของผงซักฟอกละลายน้ำได้"}, {"t": "ไม่มีส่วนหางที่ไม่มีขั้ว"}, {"t": "เป็นกรดแก่"}, {"t": "เป็นเบสแก่"}], "answer": 0}$j$::jsonb, 1, $t$ไม่เกิดตะกอนกับ Ca2+/Mg2+$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$ผงซักฟอกสังเคราะห์ทำงานได้ดีในน้ำกระด้าง เพราะเหตุใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$ไขมันให้พลังงานต่อกรัมโดยประมาณเท่าใด$t$, $j${"choices": [{"t": "12 กิโลแคลอรี"}, {"t": "2 กิโลแคลอรี"}, {"t": "9 กิโลแคลอรี"}, {"t": "4 กิโลแคลอรี"}], "answer": 2}$j$::jsonb, 1, $t$คาร์โบไฮเดรตและโปรตีนให้ประมาณ 4 กิโลแคลอรีต่อกรัม$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$ไขมันให้พลังงานต่อกรัมโดยประมาณเท่าใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$โคเลสเตอรอลจัดเป็นลิพิดชนิดใด$t$, $j${"choices": [{"t": "สเตอรอยด์"}, {"t": "แว็กซ์"}, {"t": "ไตรกลีเซอไรด์"}, {"t": "ฟอสโฟลิพิด"}], "answer": 0}$j$::jsonb, 1, $t$โครงสร้างวงแหวนหลายวงหลอมรวมกัน$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$โคเลสเตอรอลจัดเป็นลิพิดชนิดใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$ส่วนประกอบของนิวคลีโอไทด์ 1 หน่วยคือข้อใด$t$, $j${"choices": [{"t": "น้ำตาลเฮกโซสและกรดอะมิโน"}, {"t": "กรดอะมิโน กรดไขมัน และฟอสเฟต"}, {"t": "กลูโคส กรดไขมัน และกลีเซอรอล"}, {"t": "น้ำตาลเพนโทส หมู่ฟอสเฟต และเบสไนโตรเจน"}], "answer": 3}$j$::jsonb, 1, $t$เป็นหน่วยย่อยของ DNA และ RNA$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$ส่วนประกอบของนิวคลีโอไทด์ 1 หน่วยคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$น้ำตาลเพนโทสใน DNA คืออะไร$t$, $j${"choices": [{"t": "ไรโบส"}, {"t": "กลูโคส"}, {"t": "ฟรุกโทส"}, {"t": "ดีออกซีไรโบส"}], "answer": 3}$j$::jsonb, 1, $t$RNA มีไรโบส$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$น้ำตาลเพนโทสใน DNA คืออะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$เบสไนโตรเจนที่พบใน DNA ได้แก่ข้อใด$t$, $j${"choices": [{"t": "A, T, G, C"}, {"t": "A, T, U, C"}, {"t": "A, U, G, C"}, {"t": "A, T, G, U"}], "answer": 0}$j$::jsonb, 1, $t$อะดีนีน ไทมีน กวานีน ไซโทซีน$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$เบสไนโตรเจนที่พบใน DNA ได้แก่ข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$เบสไนโตรเจนที่พบใน RNA แต่ไม่พบใน DNA คือข้อใด$t$, $j${"choices": [{"t": "ไทมีน (T)"}, {"t": "ยูราซิล (U)"}, {"t": "อะดีนีน (A)"}, {"t": "กวานีน (G)"}], "answer": 1}$j$::jsonb, 1, $t$U แทนที่ T ใน RNA$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$เบสไนโตรเจนที่พบใน RNA แต่ไม่พบใน DNA คือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$การจับคู่เบสใน DNA ข้อใดถูกต้อง$t$, $j${"choices": [{"t": "A กับ T และ G กับ C"}, {"t": "A กับ U และ G กับ T"}, {"t": "A กับ G และ T กับ C"}, {"t": "A กับ C และ G กับ T"}], "answer": 0}$j$::jsonb, 1, $t$ด้วยพันธะไฮโดรเจน$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$การจับคู่เบสใน DNA ข้อใดถูกต้อง$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$คู่เบส G-C มีพันธะไฮโดรเจนกี่พันธะ$t$, $j${"choices": [{"t": "1 พันธะ"}, {"t": "2 พันธะ"}, {"t": "3 พันธะ"}, {"t": "4 พันธะ"}], "answer": 2}$j$::jsonb, 1, $t$A-T มี 2 พันธะ$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$คู่เบส G-C มีพันธะไฮโดรเจนกี่พันธะ$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$ถ้าสาย DNA สายหนึ่งมีลำดับเบส ATGC สายคู่สมที่จับคู่เบสตรงกันทีละตำแหน่งมีลำดับเบสใด$t$, $j${"choices": [{"t": "ATGC"}, {"t": "UACG"}, {"t": "TACG"}, {"t": "GCAT"}], "answer": 2}$j$::jsonb, 1, $t$A→T, T→A, G→C, C→G (DNA ไม่มี U)$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$ถ้าสาย DNA สายหนึ่งมีลำดับเบส ATGC สายคู่สมที่จับคู่เบสตรงกันทีละตำแหน่งมีลำดับเบสใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'tf', $t$DNA เป็นสายเกลียวคู่ ส่วน RNA โดยทั่วไปเป็นสายเดี่ยว$t$, $j${"answer": true}$j$::jsonb, 1, $t$เป็นความแตกต่างสำคัญของ DNA และ RNA$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$DNA เป็นสายเกลียวคู่ ส่วน RNA โดยทั่วไปเป็นสายเดี่ยว$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'tf', $t$ไขมันอิ่มตัวมีพันธะคู่ C=C ในสายกรดไขมัน$t$, $j${"answer": false}$j$::jsonb, 1, $t$ไขมันอิ่มตัวไม่มีพันธะคู่ C=C$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$ไขมันอิ่มตัวมีพันธะคู่ C=C ในสายกรดไขมัน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'match', $t$จับคู่ส่วนประกอบกับกรดนิวคลีอิก$t$, $j${"left": [{"t": "น้ำตาลดีออกซีไรโบส"}, {"t": "น้ำตาลไรโบส"}, {"t": "เบสไทมีน (T)"}, {"t": "เบสยูราซิล (U)"}], "right": [{"t": "DNA"}, {"t": "DNA"}, {"t": "RNA"}, {"t": "RNA"}, {"t": "โปรตีน"}], "pairs": [1, 2, 0, 3]}$j$::jsonb, 4, $t$ใช้ความแตกต่างของน้ำตาลและเบส$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$จับคู่ส่วนประกอบกับกรดนิวคลีอิก$t$);
-- 78: ข้อสอบพื้นฐานเคมี เน้นจำ 300 ข้อ สำหรับควิซประจำวัน (v2.19) · รันซ้ำได้ (ข้อที่หัวข้อ + โจทย์ซ้ำจะไม่ถูกเพิ่ม)
--  · ทุกห้อง (class_id ว่าง) · ปิดข้อที่ไม่เหมาะกับห้องได้ในแท็บ 🎮 มินิเกม
--  · สัญลักษณ์ธาตุ 37 · เลขอะตอม 15 · หมู่ของธาตุ 21 · ไอออนและประจุ 20 · สูตรและชื่อสาร 34 · ไอออนอะตอมกลุ่ม 18 · กรด-เบส 14 · อินดิเคเตอร์ 14 · อุปกรณ์วิทยาศาสตร์ 18 · ความปลอดภัยในห้องปฏิบัติการ 12 · หน่วยและการวัด 12 · นักวิทยาศาสตร์และแบบจำลองอะตอม 14 · สถานะและการเปลี่ยนสถานะ 6 · การแยกสาร 10 · สารในชีวิตประจำวัน 18 · โมลและมวลโมเลกุล 15 · สมบัติธาตุตามหมู่และคาบ 13 · แก๊สและการทดสอบแก๊ส 9

insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$H เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$โคบอลต์$t$, $t$คลอรีน$t$, $t$โครเมียม$t$, $t$ไฮโดรเจน$t$, 3, $t$H คือ ไฮโดรเจน$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$H เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของฮีเลียมคือข้อใด$t$, $t$H$t$, $t$He$t$, $t$Hg$t$, $t$Cr$t$, 1, $t$ฮีเลียม = He$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของฮีเลียมคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$Li เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$ออกซิเจน$t$, $t$เบริลเลียม$t$, $t$กำมะถัน (ซัลเฟอร์)$t$, $t$ลิเทียม$t$, 3, $t$Li คือ ลิเทียม$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$Li เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของเบริลเลียมคือข้อใด$t$, $t$Be$t$, $t$B$t$, $t$Ba$t$, $t$Br$t$, 0, $t$เบริลเลียม = Be$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของเบริลเลียมคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$B เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$แพลทินัม$t$, $t$ฟอสฟอรัส$t$, $t$ฮีเลียม$t$, $t$โบรอน$t$, 3, $t$B คือ โบรอน$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$B เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของคาร์บอนคือข้อใด$t$, $t$Ca$t$, $t$C$t$, $t$Cr$t$, $t$Cl$t$, 1, $t$คาร์บอน = C$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของคาร์บอนคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$N เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$ไนโตรเจน$t$, $t$เบริลเลียม$t$, $t$กำมะถัน (ซัลเฟอร์)$t$, $t$ซิลิคอน$t$, 0, $t$N คือ ไนโตรเจน$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$N เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของออกซิเจนคือข้อใด$t$, $t$O$t$, $t$Co$t$, $t$Cl$t$, $t$Si$t$, 0, $t$ออกซิเจน = O$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของออกซิเจนคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$F เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$แพลทินัม$t$, $t$ฟลูออรีน$t$, $t$ไฮโดรเจน$t$, $t$นิกเกิล$t$, 1, $t$F คือ ฟลูออรีน$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$F เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของนีออนคือข้อใด$t$, $t$O$t$, $t$Ne$t$, $t$N$t$, $t$Ni$t$, 1, $t$นีออน = Ne$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของนีออนคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$Mg เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$กำมะถัน (ซัลเฟอร์)$t$, $t$แมกนีเซียม$t$, $t$เบริลเลียม$t$, $t$ลิเทียม$t$, 1, $t$Mg คือ แมกนีเซียม$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$Mg เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของอะลูมิเนียมคือข้อใด$t$, $t$Al$t$, $t$Ar$t$, $t$Zn$t$, $t$Ca$t$, 0, $t$อะลูมิเนียม = Al$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของอะลูมิเนียมคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$Si เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$ฮีเลียม$t$, $t$กำมะถัน (ซัลเฟอร์)$t$, $t$ซิลิคอน$t$, $t$ออกซิเจน$t$, 2, $t$Si คือ ซิลิคอน$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$Si เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของฟอสฟอรัสคือข้อใด$t$, $t$Pt$t$, $t$Pb$t$, $t$P$t$, $t$F$t$, 2, $t$ฟอสฟอรัส = P$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของฟอสฟอรัสคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$S เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$ไทเทเนียม$t$, $t$ซีนอน$t$, $t$โบรมีน$t$, $t$กำมะถัน (ซัลเฟอร์)$t$, 3, $t$S คือ กำมะถัน (ซัลเฟอร์)$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$S เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของคลอรีนคือข้อใด$t$, $t$Cl$t$, $t$C$t$, $t$Ca$t$, $t$Cr$t$, 0, $t$คลอรีน = Cl$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของคลอรีนคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$Ar เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$นิกเกิล$t$, $t$อาร์กอน$t$, $t$ฟลูออรีน$t$, $t$ลิเทียม$t$, 1, $t$Ar คือ อาร์กอน$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$Ar เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของแคลเซียมคือข้อใด$t$, $t$C$t$, $t$Cr$t$, $t$Cl$t$, $t$Ca$t$, 3, $t$แคลเซียม = Ca$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของแคลเซียมคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$Zn เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$นิกเกิล$t$, $t$ฟลูออรีน$t$, $t$สังกะสี$t$, $t$นีออน$t$, 2, $t$Zn คือ สังกะสี$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$Zn เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของดีบุกคือข้อใด$t$, $t$S$t$, $t$Si$t$, $t$Be$t$, $t$Sn$t$, 3, $t$ดีบุก = Sn$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของดีบุกคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$Hg เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$แคลเซียม$t$, $t$ไทเทเนียม$t$, $t$โบรอน$t$, $t$ปรอท$t$, 3, $t$Hg คือ ปรอท$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$Hg เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของตะกั่วคือข้อใด$t$, $t$Pt$t$, $t$P$t$, $t$Pb$t$, $t$Zn$t$, 2, $t$ตะกั่ว = Pb$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของตะกั่วคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$Mn เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$แมงกานีส$t$, $t$ฟอสฟอรัส$t$, $t$คริปทอน$t$, $t$นิกเกิล$t$, 0, $t$Mn คือ แมงกานีส$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$Mn เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของโครเมียมคือข้อใด$t$, $t$Cr$t$, $t$C$t$, $t$Ca$t$, $t$Cl$t$, 0, $t$โครเมียม = Cr$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของโครเมียมคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$Ni เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$แมกนีเซียม$t$, $t$นิกเกิล$t$, $t$ฟลูออรีน$t$, $t$แบเรียม$t$, 1, $t$Ni คือ นิกเกิล$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$Ni เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของโบรมีนคือข้อใด$t$, $t$Be$t$, $t$Br$t$, $t$Ba$t$, $t$B$t$, 1, $t$โบรมีน = Br$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของโบรมีนคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$I เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$โคบอลต์$t$, $t$อะลูมิเนียม$t$, $t$ไอโอดีน$t$, $t$ดีบุก$t$, 2, $t$I คือ ไอโอดีน$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$I เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของแพลทินัมคือข้อใด$t$, $t$P$t$, $t$Kr$t$, $t$Pb$t$, $t$Pt$t$, 3, $t$แพลทินัม = Pt$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของแพลทินัมคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$U เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$คาร์บอน$t$, $t$ยูเรเนียม$t$, $t$ซีนอน$t$, $t$แมงกานีส$t$, 1, $t$U คือ ยูเรเนียม$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$U เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของแบเรียมคือข้อใด$t$, $t$B$t$, $t$Be$t$, $t$Ba$t$, $t$Br$t$, 2, $t$แบเรียม = Ba$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของแบเรียมคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$Co เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$ลิเทียม$t$, $t$แมกนีเซียม$t$, $t$โคบอลต์$t$, $t$แบเรียม$t$, 2, $t$Co คือ โคบอลต์$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$Co เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของไทเทเนียมคือข้อใด$t$, $t$O$t$, $t$Mn$t$, $t$Ti$t$, $t$Li$t$, 2, $t$ไทเทเนียม = Ti$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของไทเทเนียมคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$Kr เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$ฟลูออรีน$t$, $t$ฮีเลียม$t$, $t$คริปทอน$t$, $t$ไทเทเนียม$t$, 2, $t$Kr คือ คริปทอน$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$Kr เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของซีนอนคือข้อใด$t$, $t$Xe$t$, $t$Be$t$, $t$Mn$t$, $t$Co$t$, 0, $t$ซีนอน = Xe$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของซีนอนคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุทองแดงมีเลขอะตอมเท่าใด$t$, $t$28$t$, $t$30$t$, $t$31$t$, $t$29$t$, 3, $t$เลขอะตอมของทองแดง = 29 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุทองแดงมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุโซเดียมมีเลขอะตอมเท่าใด$t$, $t$12$t$, $t$11$t$, $t$10$t$, $t$13$t$, 1, $t$เลขอะตอมของโซเดียม = 11 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุโซเดียมมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุซิลิคอนมีเลขอะตอมเท่าใด$t$, $t$15$t$, $t$14$t$, $t$13$t$, $t$16$t$, 1, $t$เลขอะตอมของซิลิคอน = 14 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุซิลิคอนมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุโพแทสเซียมมีเลขอะตอมเท่าใด$t$, $t$20$t$, $t$21$t$, $t$18$t$, $t$19$t$, 3, $t$เลขอะตอมของโพแทสเซียม = 19 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุโพแทสเซียมมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุไฮโดรเจนมีเลขอะตอมเท่าใด$t$, $t$4$t$, $t$1$t$, $t$3$t$, $t$2$t$, 1, $t$เลขอะตอมของไฮโดรเจน = 1 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุไฮโดรเจนมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุกำมะถันมีเลขอะตอมเท่าใด$t$, $t$16$t$, $t$17$t$, $t$18$t$, $t$15$t$, 0, $t$เลขอะตอมของกำมะถัน = 16 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุกำมะถันมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุนีออนมีเลขอะตอมเท่าใด$t$, $t$10$t$, $t$11$t$, $t$9$t$, $t$12$t$, 0, $t$เลขอะตอมของนีออน = 10 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุนีออนมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุฟอสฟอรัสมีเลขอะตอมเท่าใด$t$, $t$14$t$, $t$16$t$, $t$15$t$, $t$17$t$, 2, $t$เลขอะตอมของฟอสฟอรัส = 15 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุฟอสฟอรัสมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุคาร์บอนมีเลขอะตอมเท่าใด$t$, $t$6$t$, $t$8$t$, $t$5$t$, $t$7$t$, 0, $t$เลขอะตอมของคาร์บอน = 6 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุคาร์บอนมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุอะลูมิเนียมมีเลขอะตอมเท่าใด$t$, $t$13$t$, $t$14$t$, $t$12$t$, $t$15$t$, 0, $t$เลขอะตอมของอะลูมิเนียม = 13 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุอะลูมิเนียมมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุอาร์กอนมีเลขอะตอมเท่าใด$t$, $t$20$t$, $t$18$t$, $t$19$t$, $t$17$t$, 1, $t$เลขอะตอมของอาร์กอน = 18 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุอาร์กอนมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุลิเทียมมีเลขอะตอมเท่าใด$t$, $t$3$t$, $t$2$t$, $t$5$t$, $t$4$t$, 0, $t$เลขอะตอมของลิเทียม = 3 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุลิเทียมมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุฮีเลียมมีเลขอะตอมเท่าใด$t$, $t$4$t$, $t$3$t$, $t$2$t$, $t$1$t$, 2, $t$เลขอะตอมของฮีเลียม = 2 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุฮีเลียมมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุเหล็กมีเลขอะตอมเท่าใด$t$, $t$28$t$, $t$27$t$, $t$25$t$, $t$26$t$, 3, $t$เลขอะตอมของเหล็ก = 26 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุเหล็กมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุแคลเซียมมีเลขอะตอมเท่าใด$t$, $t$21$t$, $t$19$t$, $t$20$t$, $t$22$t$, 2, $t$เลขอะตอมของแคลเซียม = 20 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุแคลเซียมมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$ลิเทียม (Li) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 1$t$, $t$หมู่ 18$t$, $t$หมู่ 2$t$, $t$หมู่ 16$t$, 0, $t$ลิเทียม อยู่หมู่ 1 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$ลิเทียม (Li) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$โซเดียม (Na) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 17$t$, $t$หมู่ 15$t$, $t$หมู่ 13$t$, $t$หมู่ 1$t$, 3, $t$โซเดียม อยู่หมู่ 1 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$โซเดียม (Na) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$โพแทสเซียม (K) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 2$t$, $t$หมู่ 17$t$, $t$หมู่ 15$t$, $t$หมู่ 1$t$, 3, $t$โพแทสเซียม อยู่หมู่ 1 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$โพแทสเซียม (K) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$เบริลเลียม (Be) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 1$t$, $t$หมู่ 2$t$, $t$หมู่ 18$t$, $t$หมู่ 17$t$, 1, $t$เบริลเลียม อยู่หมู่ 2 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$เบริลเลียม (Be) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$แมกนีเซียม (Mg) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 1$t$, $t$หมู่ 2$t$, $t$หมู่ 15$t$, $t$หมู่ 13$t$, 1, $t$แมกนีเซียม อยู่หมู่ 2 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$แมกนีเซียม (Mg) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$แคลเซียม (Ca) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 2$t$, $t$หมู่ 14$t$, $t$หมู่ 17$t$, $t$หมู่ 16$t$, 0, $t$แคลเซียม อยู่หมู่ 2 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$แคลเซียม (Ca) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$โบรอน (B) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 13$t$, $t$หมู่ 14$t$, $t$หมู่ 15$t$, $t$หมู่ 16$t$, 0, $t$โบรอน อยู่หมู่ 13 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$โบรอน (B) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$อะลูมิเนียม (Al) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 2$t$, $t$หมู่ 17$t$, $t$หมู่ 13$t$, $t$หมู่ 18$t$, 2, $t$อะลูมิเนียม อยู่หมู่ 13 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$อะลูมิเนียม (Al) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$คาร์บอน (C) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 14$t$, $t$หมู่ 13$t$, $t$หมู่ 17$t$, $t$หมู่ 18$t$, 0, $t$คาร์บอน อยู่หมู่ 14 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$คาร์บอน (C) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$ซิลิคอน (Si) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 13$t$, $t$หมู่ 14$t$, $t$หมู่ 16$t$, $t$หมู่ 1$t$, 1, $t$ซิลิคอน อยู่หมู่ 14 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$ซิลิคอน (Si) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$ไนโตรเจน (N) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 16$t$, $t$หมู่ 15$t$, $t$หมู่ 2$t$, $t$หมู่ 18$t$, 1, $t$ไนโตรเจน อยู่หมู่ 15 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$ไนโตรเจน (N) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$ฟอสฟอรัส (P) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 18$t$, $t$หมู่ 2$t$, $t$หมู่ 1$t$, $t$หมู่ 15$t$, 3, $t$ฟอสฟอรัส อยู่หมู่ 15 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$ฟอสฟอรัส (P) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$ออกซิเจน (O) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 14$t$, $t$หมู่ 15$t$, $t$หมู่ 16$t$, $t$หมู่ 18$t$, 2, $t$ออกซิเจน อยู่หมู่ 16 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$ออกซิเจน (O) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$กำมะถัน (S) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 16$t$, $t$หมู่ 13$t$, $t$หมู่ 15$t$, $t$หมู่ 2$t$, 0, $t$กำมะถัน อยู่หมู่ 16 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$กำมะถัน (S) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$ฟลูออรีน (F) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 2$t$, $t$หมู่ 16$t$, $t$หมู่ 17$t$, $t$หมู่ 13$t$, 2, $t$ฟลูออรีน อยู่หมู่ 17 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$ฟลูออรีน (F) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$คลอรีน (Cl) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 16$t$, $t$หมู่ 13$t$, $t$หมู่ 18$t$, $t$หมู่ 17$t$, 3, $t$คลอรีน อยู่หมู่ 17 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$คลอรีน (Cl) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$โบรมีน (Br) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 13$t$, $t$หมู่ 17$t$, $t$หมู่ 14$t$, $t$หมู่ 16$t$, 1, $t$โบรมีน อยู่หมู่ 17 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$โบรมีน (Br) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$ไอโอดีน (I) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 13$t$, $t$หมู่ 14$t$, $t$หมู่ 16$t$, $t$หมู่ 17$t$, 3, $t$ไอโอดีน อยู่หมู่ 17 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$ไอโอดีน (I) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$นีออน (Ne) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 1$t$, $t$หมู่ 18$t$, $t$หมู่ 15$t$, $t$หมู่ 2$t$, 1, $t$นีออน อยู่หมู่ 18 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$นีออน (Ne) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$อาร์กอน (Ar) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 18$t$, $t$หมู่ 13$t$, $t$หมู่ 17$t$, $t$หมู่ 14$t$, 0, $t$อาร์กอน อยู่หมู่ 18 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$อาร์กอน (Ar) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของโซเดียมมีสัญลักษณ์ใด$t$, $t$Na⁺$t$, $t$Na²⁻$t$, $t$Na⁻$t$, $t$Na²⁺$t$, 0, $t$Na⁺ — ให้ e⁻ เกิดไอออนบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของโซเดียมมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของโพแทสเซียมมีสัญลักษณ์ใด$t$, $t$K³⁺$t$, $t$K²⁻$t$, $t$K²⁺$t$, $t$K⁺$t$, 3, $t$K⁺ — ให้ e⁻ เกิดไอออนบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของโพแทสเซียมมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของลิเทียมมีสัญลักษณ์ใด$t$, $t$Li²⁺$t$, $t$Li⁺$t$, $t$Li²⁻$t$, $t$Li³⁺$t$, 1, $t$Li⁺ — ให้ e⁻ เกิดไอออนบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของลิเทียมมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของเงินมีสัญลักษณ์ใด$t$, $t$Ag²⁻$t$, $t$Ag³⁻$t$, $t$Ag⁺$t$, $t$Ag³⁺$t$, 2, $t$Ag⁺ — ให้ e⁻ เกิดไอออนบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของเงินมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของแมกนีเซียมมีสัญลักษณ์ใด$t$, $t$Mg²⁺$t$, $t$Mg⁻$t$, $t$Mg²⁻$t$, $t$Mg³⁻$t$, 0, $t$Mg²⁺ — ให้ e⁻ เกิดไอออนบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของแมกนีเซียมมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของแคลเซียมมีสัญลักษณ์ใด$t$, $t$Ca⁺$t$, $t$Ca²⁻$t$, $t$Ca³⁺$t$, $t$Ca²⁺$t$, 3, $t$Ca²⁺ — ให้ e⁻ เกิดไอออนบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของแคลเซียมมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของแบเรียมมีสัญลักษณ์ใด$t$, $t$Ba⁺$t$, $t$Ba³⁺$t$, $t$Ba⁻$t$, $t$Ba²⁺$t$, 3, $t$Ba²⁺ — ให้ e⁻ เกิดไอออนบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของแบเรียมมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของสังกะสีมีสัญลักษณ์ใด$t$, $t$Zn²⁻$t$, $t$Zn³⁺$t$, $t$Zn²⁺$t$, $t$Zn⁺$t$, 2, $t$Zn²⁺ — ให้ e⁻ เกิดไอออนบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของสังกะสีมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของอะลูมิเนียมมีสัญลักษณ์ใด$t$, $t$Al⁻$t$, $t$Al²⁺$t$, $t$Al⁺$t$, $t$Al³⁺$t$, 3, $t$Al³⁺ — ให้ e⁻ เกิดไอออนบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของอะลูมิเนียมมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของคลอรีนมีสัญลักษณ์ใด$t$, $t$Cl⁻$t$, $t$Cl⁺$t$, $t$Cl²⁺$t$, $t$Cl³⁺$t$, 0, $t$Cl⁻ — รับ e⁻ เกิดไอออนลบ$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของคลอรีนมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของโบรมีนมีสัญลักษณ์ใด$t$, $t$Br²⁻$t$, $t$Br⁻$t$, $t$Br²⁺$t$, $t$Br³⁺$t$, 1, $t$Br⁻ — รับ e⁻ เกิดไอออนลบ$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของโบรมีนมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของไอโอดีนมีสัญลักษณ์ใด$t$, $t$I⁻$t$, $t$I⁺$t$, $t$I²⁺$t$, $t$I³⁻$t$, 0, $t$I⁻ — รับ e⁻ เกิดไอออนลบ$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของไอโอดีนมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของฟลูออรีนมีสัญลักษณ์ใด$t$, $t$F⁻$t$, $t$F²⁻$t$, $t$F⁺$t$, $t$F²⁺$t$, 0, $t$F⁻ — รับ e⁻ เกิดไอออนลบ$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของฟลูออรีนมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของออกซิเจนมีสัญลักษณ์ใด$t$, $t$O²⁻$t$, $t$O⁺$t$, $t$O³⁺$t$, $t$O³⁻$t$, 0, $t$O²⁻ — รับ e⁻ เกิดไอออนลบ$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของออกซิเจนมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของกำมะถันมีสัญลักษณ์ใด$t$, $t$S³⁻$t$, $t$S²⁺$t$, $t$S²⁻$t$, $t$S⁻$t$, 2, $t$S²⁻ — รับ e⁻ เกิดไอออนลบ$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของกำมะถันมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของไนโตรเจนมีสัญลักษณ์ใด$t$, $t$N³⁺$t$, $t$N²⁺$t$, $t$N³⁻$t$, $t$N⁺$t$, 2, $t$N³⁻ — รับ e⁻ เกิดไอออนลบ$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของไนโตรเจนมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของซีเซียมมีสัญลักษณ์ใด$t$, $t$Cs⁻$t$, $t$Cs²⁻$t$, $t$Cs⁺$t$, $t$Cs³⁻$t$, 2, $t$Cs⁺ — ให้ e⁻ เกิดไอออนบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของซีเซียมมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนของทองแดง(II)มีสัญลักษณ์ใด$t$, $t$Cu³⁺$t$, $t$Cu²⁻$t$, $t$Cu²⁺$t$, $t$Cu⁺$t$, 2, $t$Cu²⁺ — ให้ e⁻ เกิดไอออนบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนของทองแดง(II)มีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนของตะกั่ว(II)มีสัญลักษณ์ใด$t$, $t$Pb³⁺$t$, $t$Pb²⁻$t$, $t$Pb²⁺$t$, $t$Pb⁻$t$, 2, $t$Pb²⁺ — ให้ e⁻ เกิดไอออนบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนของตะกั่ว(II)มีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนของเหล็ก(III)มีสัญลักษณ์ใด$t$, $t$Fe²⁺$t$, $t$Fe³⁺$t$, $t$Fe⁺$t$, $t$Fe²⁻$t$, 1, $t$Fe³⁺ — ให้ e⁻ เกิดไอออนบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนของเหล็ก(III)มีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร CO₂ มีชื่อว่าอะไร$t$, $t$แคลเซียมไฮดรอกไซด์$t$, $t$คาร์บอนไดออกไซด์$t$, $t$แมกนีเซียมไฮดรอกไซด์$t$, $t$กรดซัลฟิวริก$t$, 1, $t$CO₂ คือ คาร์บอนไดออกไซด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร CO₂ มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของแอมโมเนียคือข้อใด$t$, $t$NH₃$t$, $t$SO₃$t$, $t$P₂O₅$t$, $t$CaCO₃$t$, 0, $t$แอมโมเนีย = NH₃$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของแอมโมเนียคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร CH₄ มีชื่อว่าอะไร$t$, $t$โซเดียมไฮดรอกไซด์$t$, $t$แบเรียมซัลเฟต$t$, $t$คาร์บอนมอนอกไซด์$t$, $t$มีเทน$t$, 3, $t$CH₄ คือ มีเทน$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร CH₄ มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของโซเดียมคลอไรด์คือข้อใด$t$, $t$CaCO₃$t$, $t$H₂SO₄$t$, $t$NaOH$t$, $t$NaCl$t$, 3, $t$โซเดียมคลอไรด์ = NaCl$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของโซเดียมคลอไรด์คือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร H₂O₂ มีชื่อว่าอะไร$t$, $t$คาร์บอนไดออกไซด์$t$, $t$แคลเซียมคลอไรด์$t$, $t$ไฮโดรเจนเปอร์ออกไซด์$t$, $t$ซัลเฟอร์ไตรออกไซด์$t$, 2, $t$H₂O₂ คือ ไฮโดรเจนเปอร์ออกไซด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร H₂O₂ มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของโซเดียมไฮดรอกไซด์คือข้อใด$t$, $t$NH₃$t$, $t$NaOH$t$, $t$Fe₂O₃$t$, $t$NaHCO₃$t$, 1, $t$โซเดียมไฮดรอกไซด์ = NaOH$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของโซเดียมไฮดรอกไซด์คือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร HCl มีชื่อว่าอะไร$t$, $t$อะลูมิเนียมออกไซด์$t$, $t$โซเดียมคาร์บอเนต$t$, $t$โซเดียมซัลเฟต$t$, $t$กรดไฮโดรคลอริก$t$, 3, $t$HCl คือ กรดไฮโดรคลอริก$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร HCl มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของกรดซัลฟิวริกคือข้อใด$t$, $t$H₂SO₄$t$, $t$KCl$t$, $t$BaSO₄$t$, $t$CH₄$t$, 0, $t$กรดซัลฟิวริก = H₂SO₄$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของกรดซัลฟิวริกคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร HNO₃ มีชื่อว่าอะไร$t$, $t$น้ำ$t$, $t$แอมโมเนีย$t$, $t$กรดไนตริก$t$, $t$ซิลิคอนไดออกไซด์$t$, 2, $t$HNO₃ คือ กรดไนตริก$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร HNO₃ มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของแคลเซียมคาร์บอเนตคือข้อใด$t$, $t$CaCO₃$t$, $t$H₂S$t$, $t$HNO₃$t$, $t$H₂SO₄$t$, 0, $t$แคลเซียมคาร์บอเนต = CaCO₃$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของแคลเซียมคาร์บอเนตคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร CaO มีชื่อว่าอะไร$t$, $t$โพแทสเซียมเปอร์แมงกาเนต$t$, $t$แมกนีเซียมออกไซด์$t$, $t$แคลเซียมออกไซด์$t$, $t$แอมโมเนีย$t$, 2, $t$CaO คือ แคลเซียมออกไซด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร CaO มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของแมกนีเซียมออกไซด์คือข้อใด$t$, $t$CH₄$t$, $t$Mg(OH)₂$t$, $t$MgO$t$, $t$Fe₂O₃$t$, 2, $t$แมกนีเซียมออกไซด์ = MgO$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของแมกนีเซียมออกไซด์คือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร Fe₂O₃ มีชื่อว่าอะไร$t$, $t$ซัลเฟอร์ไตรออกไซด์$t$, $t$โพแทสเซียมคลอไรด์$t$, $t$ไดฟอสฟอรัสเพนตะออกไซด์$t$, $t$เหล็ก(III) ออกไซด์$t$, 3, $t$Fe₂O₃ คือ เหล็ก(III) ออกไซด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร Fe₂O₃ มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของอะลูมิเนียมออกไซด์คือข้อใด$t$, $t$CaCO₃$t$, $t$P₂O₅$t$, $t$Al₂O₃$t$, $t$Ca(OH)₂$t$, 2, $t$อะลูมิเนียมออกไซด์ = Al₂O₃$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของอะลูมิเนียมออกไซด์คือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร NaHCO₃ มีชื่อว่าอะไร$t$, $t$โซเดียมไฮโดรเจนคาร์บอเนต$t$, $t$ไฮโดรเจนเปอร์ออกไซด์$t$, $t$โซเดียมคาร์บอเนต$t$, $t$ซิลิคอนไดออกไซด์$t$, 0, $t$NaHCO₃ คือ โซเดียมไฮโดรเจนคาร์บอเนต$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร NaHCO₃ มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของโพแทสเซียมไนเตรตคือข้อใด$t$, $t$NaHCO₃$t$, $t$KNO₃$t$, $t$CaO$t$, $t$CO$t$, 1, $t$โพแทสเซียมไนเตรต = KNO₃$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของโพแทสเซียมไนเตรตคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร CaCl₂ มีชื่อว่าอะไร$t$, $t$แคลเซียมคลอไรด์$t$, $t$กรดฟอสฟอริก$t$, $t$โซเดียมคลอไรด์$t$, $t$แมกนีเซียมออกไซด์$t$, 0, $t$CaCl₂ คือ แคลเซียมคลอไรด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร CaCl₂ มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของซิงค์ออกไซด์คือข้อใด$t$, $t$H₂S$t$, $t$H₂SO₄$t$, $t$Al₂O₃$t$, $t$ZnO$t$, 3, $t$ซิงค์ออกไซด์ = ZnO$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของซิงค์ออกไซด์คือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร AgNO₃ มีชื่อว่าอะไร$t$, $t$แมกนีเซียมไฮดรอกไซด์$t$, $t$กรดไนตริก$t$, $t$ซิลิคอนไดออกไซด์$t$, $t$ซิลเวอร์ไนเตรต$t$, 3, $t$AgNO₃ คือ ซิลเวอร์ไนเตรต$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร AgNO₃ มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของโพแทสเซียมคลอไรด์คือข้อใด$t$, $t$CH₄$t$, $t$NaHCO₃$t$, $t$CO$t$, $t$KCl$t$, 3, $t$โพแทสเซียมคลอไรด์ = KCl$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของโพแทสเซียมคลอไรด์คือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร NH₄Cl มีชื่อว่าอะไร$t$, $t$แอมโมเนียมคลอไรด์$t$, $t$โพแทสเซียมคลอไรด์$t$, $t$โพแทสเซียมไนเตรต$t$, $t$คาร์บอนไดออกไซด์$t$, 0, $t$NH₄Cl คือ แอมโมเนียมคลอไรด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร NH₄Cl มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของคาร์บอนมอนอกไซด์คือข้อใด$t$, $t$SiO₂$t$, $t$CO$t$, $t$NaOH$t$, $t$NH₃$t$, 1, $t$คาร์บอนมอนอกไซด์ = CO$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของคาร์บอนมอนอกไซด์คือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร SO₂ มีชื่อว่าอะไร$t$, $t$กรดไฮโดรคลอริก$t$, $t$ซิงค์ออกไซด์$t$, $t$แคลเซียมไฮดรอกไซด์$t$, $t$ซัลเฟอร์ไดออกไซด์$t$, 3, $t$SO₂ คือ ซัลเฟอร์ไดออกไซด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร SO₂ มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของซัลเฟอร์ไตรออกไซด์คือข้อใด$t$, $t$HNO₃$t$, $t$MgO$t$, $t$H₃PO₄$t$, $t$SO₃$t$, 3, $t$ซัลเฟอร์ไตรออกไซด์ = SO₃$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของซัลเฟอร์ไตรออกไซด์คือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร SiO₂ มีชื่อว่าอะไร$t$, $t$โพแทสเซียมคลอไรด์$t$, $t$ไดฟอสฟอรัสเพนตะออกไซด์$t$, $t$โซเดียมไฮโดรเจนคาร์บอเนต$t$, $t$ซิลิคอนไดออกไซด์$t$, 3, $t$SiO₂ คือ ซิลิคอนไดออกไซด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร SiO₂ มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของโพแทสเซียมเปอร์แมงกาเนตคือข้อใด$t$, $t$H₂S$t$, $t$HCl$t$, $t$Na₂CO₃$t$, $t$KMnO₄$t$, 3, $t$โพแทสเซียมเปอร์แมงกาเนต = KMnO₄$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของโพแทสเซียมเปอร์แมงกาเนตคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร BaSO₄ มีชื่อว่าอะไร$t$, $t$มีเทน$t$, $t$คาร์บอนไดออกไซด์$t$, $t$แบเรียมซัลเฟต$t$, $t$แอมโมเนีย$t$, 2, $t$BaSO₄ คือ แบเรียมซัลเฟต$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร BaSO₄ มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของแคลเซียมไฮดรอกไซด์คือข้อใด$t$, $t$Ca(OH)₂$t$, $t$CaCO₃$t$, $t$HCl$t$, $t$H₂O₂$t$, 0, $t$แคลเซียมไฮดรอกไซด์ = Ca(OH)₂$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของแคลเซียมไฮดรอกไซด์คือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร Na₂CO₃ มีชื่อว่าอะไร$t$, $t$โซเดียมคาร์บอเนต$t$, $t$กรดไฮโดรคลอริก$t$, $t$น้ำ$t$, $t$โพแทสเซียมไนเตรต$t$, 0, $t$Na₂CO₃ คือ โซเดียมคาร์บอเนต$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร Na₂CO₃ มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของกรดฟอสฟอริกคือข้อใด$t$, $t$H₂O$t$, $t$H₃PO₄$t$, $t$NaHCO₃$t$, $t$H₂SO₄$t$, 1, $t$กรดฟอสฟอริก = H₃PO₄$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของกรดฟอสฟอริกคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร H₂S มีชื่อว่าอะไร$t$, $t$ไฮโดรเจนซัลไฟด์$t$, $t$แอมโมเนียมคลอไรด์$t$, $t$ซัลเฟอร์ไตรออกไซด์$t$, $t$แมกนีเซียมไฮดรอกไซด์$t$, 0, $t$H₂S คือ ไฮโดรเจนซัลไฟด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร H₂S มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของไดฟอสฟอรัสเพนตะออกไซด์คือข้อใด$t$, $t$NH₃$t$, $t$P₂O₅$t$, $t$MgO$t$, $t$NaCl$t$, 1, $t$ไดฟอสฟอรัสเพนตะออกไซด์ = P₂O₅$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของไดฟอสฟอรัสเพนตะออกไซด์คือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร Mg(OH)₂ มีชื่อว่าอะไร$t$, $t$อะลูมิเนียมออกไซด์$t$, $t$โซเดียมคาร์บอเนต$t$, $t$แมกนีเซียมไฮดรอกไซด์$t$, $t$โซเดียมซัลเฟต$t$, 2, $t$Mg(OH)₂ คือ แมกนีเซียมไฮดรอกไซด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร Mg(OH)₂ มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของโซเดียมซัลเฟตคือข้อใด$t$, $t$Mg(OH)₂$t$, $t$BaSO₄$t$, $t$Ca(OH)₂$t$, $t$Na₂SO₄$t$, 3, $t$โซเดียมซัลเฟต = Na₂SO₄$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของโซเดียมซัลเฟตคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนไฮดรอกไซด์มีสูตรตามข้อใด$t$, $t$SO₃²⁻$t$, $t$CH₃COO⁻$t$, $t$PO₄³⁻$t$, $t$OH⁻$t$, 3, $t$ไฮดรอกไซด์ = OH⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนไฮดรอกไซด์มีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนไนเตรตมีสูตรตามข้อใด$t$, $t$CH₃COO⁻$t$, $t$NO₃⁻$t$, $t$CO₃²⁻$t$, $t$CrO₄²⁻$t$, 1, $t$ไนเตรต = NO₃⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนไนเตรตมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนซัลเฟตมีสูตรตามข้อใด$t$, $t$SO₃²⁻$t$, $t$CH₃COO⁻$t$, $t$C₂O₄²⁻$t$, $t$SO₄²⁻$t$, 3, $t$ซัลเฟต = SO₄²⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนซัลเฟตมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนคาร์บอเนตมีสูตรตามข้อใด$t$, $t$OH⁻$t$, $t$PO₄³⁻$t$, $t$SO₃²⁻$t$, $t$CO₃²⁻$t$, 3, $t$คาร์บอเนต = CO₃²⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนคาร์บอเนตมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนฟอสเฟตมีสูตรตามข้อใด$t$, $t$OH⁻$t$, $t$NO₃⁻$t$, $t$PO₄³⁻$t$, $t$H₃O⁺$t$, 2, $t$ฟอสเฟต = PO₄³⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนฟอสเฟตมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนแอมโมเนียมมีสูตรตามข้อใด$t$, $t$NH₄⁺$t$, $t$H₃O⁺$t$, $t$CO₃²⁻$t$, $t$NO₃⁻$t$, 0, $t$แอมโมเนียม = NH₄⁺$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนแอมโมเนียมมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนไฮโดรเจนคาร์บอเนตมีสูตรตามข้อใด$t$, $t$CO₃²⁻$t$, $t$MnO₄⁻$t$, $t$Cr₂O₇²⁻$t$, $t$HCO₃⁻$t$, 3, $t$ไฮโดรเจนคาร์บอเนต = HCO₃⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนไฮโดรเจนคาร์บอเนตมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนไนไตรต์มีสูตรตามข้อใด$t$, $t$CrO₄²⁻$t$, $t$NO₂⁻$t$, $t$OH⁻$t$, $t$HCO₃⁻$t$, 1, $t$ไนไตรต์ = NO₂⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนไนไตรต์มีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนซัลไฟต์มีสูตรตามข้อใด$t$, $t$CO₃²⁻$t$, $t$SO₄²⁻$t$, $t$NO₃⁻$t$, $t$SO₃²⁻$t$, 3, $t$ซัลไฟต์ = SO₃²⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนซัลไฟต์มีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนเปอร์แมงกาเนตมีสูตรตามข้อใด$t$, $t$HSO₄⁻$t$, $t$PO₄³⁻$t$, $t$MnO₄⁻$t$, $t$NO₂⁻$t$, 2, $t$เปอร์แมงกาเนต = MnO₄⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนเปอร์แมงกาเนตมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนไดโครเมตมีสูตรตามข้อใด$t$, $t$HCO₃⁻$t$, $t$OH⁻$t$, $t$NO₃⁻$t$, $t$Cr₂O₇²⁻$t$, 3, $t$ไดโครเมต = Cr₂O₇²⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนไดโครเมตมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนโครเมตมีสูตรตามข้อใด$t$, $t$NH₄⁺$t$, $t$CrO₄²⁻$t$, $t$CN⁻$t$, $t$HSO₄⁻$t$, 1, $t$โครเมต = CrO₄²⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนโครเมตมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนไฮโดรเนียมมีสูตรตามข้อใด$t$, $t$OH⁻$t$, $t$CrO₄²⁻$t$, $t$H₃O⁺$t$, $t$SO₄²⁻$t$, 2, $t$ไฮโดรเนียม = H₃O⁺$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนไฮโดรเนียมมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนแอซีเตตมีสูตรตามข้อใด$t$, $t$HSO₄⁻$t$, $t$CO₃²⁻$t$, $t$CH₃COO⁻$t$, $t$H₃O⁺$t$, 2, $t$แอซีเตต = CH₃COO⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนแอซีเตตมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนคลอเรตมีสูตรตามข้อใด$t$, $t$ClO₃⁻$t$, $t$CrO₄²⁻$t$, $t$HCO₃⁻$t$, $t$PO₄³⁻$t$, 0, $t$คลอเรต = ClO₃⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนคลอเรตมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนไฮโดรเจนซัลเฟตมีสูตรตามข้อใด$t$, $t$HSO₄⁻$t$, $t$OH⁻$t$, $t$ClO₃⁻$t$, $t$MnO₄⁻$t$, 0, $t$ไฮโดรเจนซัลเฟต = HSO₄⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนไฮโดรเจนซัลเฟตมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนไซยาไนด์มีสูตรตามข้อใด$t$, $t$CN⁻$t$, $t$MnO₄⁻$t$, $t$CH₃COO⁻$t$, $t$NO₃⁻$t$, 0, $t$ไซยาไนด์ = CN⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนไซยาไนด์มีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนออกซาเลตมีสูตรตามข้อใด$t$, $t$H₃O⁺$t$, $t$PO₄³⁻$t$, $t$CO₃²⁻$t$, $t$C₂O₄²⁻$t$, 3, $t$ออกซาเลต = C₂O₄²⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนออกซาเลตมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$กรดชนิดใดมีอยู่ในกระเพาะอาหารของมนุษย์$t$, $t$กรดซัลฟิวริก$t$, $t$กรดไฮโดรคลอริก (HCl)$t$, $t$กรดแอซีติก$t$, $t$กรดไนตริก$t$, 1, $t$ช่วยย่อยอาหารและฆ่าเชื้อโรค$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$กรดชนิดใดมีอยู่ในกระเพาะอาหารของมนุษย์$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$กรดที่ใช้ในแบตเตอรี่รถยนต์คือข้อใด$t$, $t$กรดแอซีติก$t$, $t$กรดไฮโดรคลอริก$t$, $t$กรดซิตริก$t$, $t$กรดซัลฟิวริก (H₂SO₄)$t$, 3, $t$แบตเตอรี่ตะกั่ว-กรดใช้สารละลาย H₂SO₄$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$กรดที่ใช้ในแบตเตอรี่รถยนต์คือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$กรดที่ทำให้น้ำมะนาวมีรสเปรี้ยวคือกรดชนิดใด$t$, $t$กรดซิตริก$t$, $t$กรดแอซีติก$t$, $t$กรดแลกติก$t$, $t$กรดฟอร์มิก$t$, 0, $t$พบในผลไม้ตระกูลส้ม$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$กรดที่ทำให้น้ำมะนาวมีรสเปรี้ยวคือกรดชนิดใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$สารละลายที่มีค่า pH เท่ากับ 7 ที่ 25 องศาเซลเซียส มีสมบัติเป็นอย่างไร$t$, $t$เป็นกลาง$t$, $t$เป็นเบสอ่อน$t$, $t$เป็นกรดแก่$t$, $t$เป็นกรดอ่อน$t$, 0, $t$น้ำบริสุทธิ์มี pH = 7$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$สารละลายที่มีค่า pH เท่ากับ 7 ที่ 25 องศาเซลเซียส มีสมบัติเป็นอย่างไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$สารละลายที่มี pH น้อยกว่า 7 มีสมบัติอย่างไร$t$, $t$เป็นเบส$t$, $t$เป็นกลาง$t$, $t$เป็นเกลือเท่านั้น$t$, $t$เป็นกรด$t$, 3, $t$pH ต่ำ = ความเป็นกรดสูง$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$สารละลายที่มี pH น้อยกว่า 7 มีสมบัติอย่างไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$สารละลายที่มี pH มากกว่า 7 มีสมบัติอย่างไร$t$, $t$เป็นกลาง$t$, $t$เป็นเกลือเสมอ$t$, $t$เป็นกรด$t$, $t$เป็นเบส$t$, 3, $t$pH สูง = ความเป็นเบสสูง$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$สารละลายที่มี pH มากกว่า 7 มีสมบัติอย่างไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$ปฏิกิริยาระหว่างกรดกับเบสเรียกว่าอะไร และได้ผลิตภัณฑ์ใด$t$, $t$การหมัก ได้เอทานอล$t$, $t$การสะเทิน ได้เกลือและน้ำ$t$, $t$การเติม ได้แอลเคน$t$, $t$การเผาไหม้ ได้ CO₂ และน้ำ$t$, 1, $t$กรด + เบส → เกลือ + น้ำ$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$ปฏิกิริยาระหว่างกรดกับเบสเรียกว่าอะไร และได้ผลิตภัณฑ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$เมื่อกรดทำปฏิกิริยากับโลหะ เช่น สังกะสี จะเกิดแก๊สใด$t$, $t$Cl₂$t$, $t$O₂$t$, $t$H₂$t$, $t$CO₂$t$, 2, $t$กรด + โลหะ → เกลือ + H₂$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$เมื่อกรดทำปฏิกิริยากับโลหะ เช่น สังกะสี จะเกิดแก๊สใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$เมื่อกรดทำปฏิกิริยากับหินปูน (CaCO₃) จะเกิดแก๊สใด$t$, $t$H₂$t$, $t$NH₃$t$, $t$CO₂$t$, $t$O₂$t$, 2, $t$กรด + คาร์บอเนต → เกลือ + น้ำ + CO₂$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$เมื่อกรดทำปฏิกิริยากับหินปูน (CaCO₃) จะเกิดแก๊สใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$ไอออนที่เกิดขึ้นเมื่อกรดละลายน้ำและทำให้สารละลายเป็นกรดคือข้อใด$t$, $t$Cl⁻$t$, $t$Na⁺$t$, $t$H₃O⁺$t$, $t$OH⁻$t$, 2, $t$ไฮโดรเนียมไอออน$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$ไอออนที่เกิดขึ้นเมื่อกรดละลายน้ำและทำให้สารละลายเป็นกรดคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$ข้อใดเป็นกรดแก่$t$, $t$CH₃COOH$t$, $t$NH₃$t$, $t$HCl$t$, $t$H₂CO₃$t$, 2, $t$HCl แตกตัวสมบูรณ์ ส่วนกรดแอซีติกเป็นกรดอ่อน$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$ข้อใดเป็นกรดแก่$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$ข้อใดเป็นเบสอ่อน$t$, $t$NaOH$t$, $t$HCl$t$, $t$KOH$t$, $t$NH₃$t$, 3, $t$แอมโมเนียแตกตัวบางส่วนในน้ำ$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$ข้อใดเป็นเบสอ่อน$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$น้ำบริสุทธิ์ที่ 25 องศาเซลเซียส มีค่า pH เท่าใด$t$, $t$14$t$, $t$1$t$, $t$0$t$, $t$7$t$, 3, $t$เป็นกลาง$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$น้ำบริสุทธิ์ที่ 25 องศาเซลเซียส มีค่า pH เท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$กรดชนิดใดพบในมดและต่อ$t$, $t$กรดซิตริก$t$, $t$กรดแลกติก$t$, $t$กรดฟอร์มิก$t$, $t$กรดแอซีติก$t$, 2, $t$HCOOH (กรดเมทาโนอิก)$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$กรดชนิดใดพบในมดและต่อ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$กระดาษลิตมัสสีน้ำเงินเมื่อสัมผัสสารละลายกรดจะเปลี่ยนเป็นสีใด$t$, $t$ม่วง$t$, $t$เขียว$t$, $t$ไม่เปลี่ยนสี$t$, $t$แดง$t$, 3, $t$กรดเปลี่ยนลิตมัสน้ำเงินเป็นแดง$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$กระดาษลิตมัสสีน้ำเงินเมื่อสัมผัสสารละลายกรดจะเปลี่ยนเป็นสีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$กระดาษลิตมัสสีแดงเมื่อสัมผัสสารละลายเบสจะเปลี่ยนเป็นสีใด$t$, $t$ไม่มีสี$t$, $t$น้ำเงิน$t$, $t$เขียว$t$, $t$เหลือง$t$, 1, $t$เบสเปลี่ยนลิตมัสแดงเป็นน้ำเงิน$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$กระดาษลิตมัสสีแดงเมื่อสัมผัสสารละลายเบสจะเปลี่ยนเป็นสีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$ฟีนอล์ฟทาลีนในสารละลายเบสให้สีใด$t$, $t$เหลือง$t$, $t$ชมพู$t$, $t$น้ำเงิน$t$, $t$ไม่มีสี$t$, 1, $t$ในกรดและสารละลายกลางไม่มีสี$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$ฟีนอล์ฟทาลีนในสารละลายเบสให้สีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$ฟีนอล์ฟทาลีนในสารละลายกรดให้สีใด$t$, $t$ชมพู$t$, $t$ไม่มีสี$t$, $t$แดง$t$, $t$เหลือง$t$, 1, $t$จึงใช้ดูจุดยุติการไทเทรตกรดกับเบสได้$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$ฟีนอล์ฟทาลีนในสารละลายกรดให้สีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$เมทิลออเรนจ์ในสารละลายกรดให้สีใด$t$, $t$แดง$t$, $t$เหลือง$t$, $t$ไม่มีสี$t$, $t$น้ำเงิน$t$, 0, $t$ในเบสให้สีเหลือง$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$เมทิลออเรนจ์ในสารละลายกรดให้สีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$โบรมไทมอลบลู (BTB) ในสารละลายกรดให้สีใด$t$, $t$ชมพู$t$, $t$เขียว$t$, $t$เหลือง$t$, $t$น้ำเงิน$t$, 2, $t$กรด = เหลือง · กลาง = เขียว · เบส = น้ำเงิน$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$โบรมไทมอลบลู (BTB) ในสารละลายกรดให้สีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$โบรมไทมอลบลู (BTB) ในสารละลายเป็นกลางให้สีใด$t$, $t$ไม่มีสี$t$, $t$เขียว$t$, $t$น้ำเงิน$t$, $t$เหลือง$t$, 1, $t$จึงใช้ทดสอบ CO₂ ในน้ำที่ทำให้เป็นกรดได้$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$โบรมไทมอลบลู (BTB) ในสารละลายเป็นกลางให้สีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$อินดิเคเตอร์สากล (universal indicator) ใช้ทำอะไร$t$, $t$บอกค่า pH โดยประมาณจากสีที่เปลี่ยนไป$t$, $t$วัดปริมาตรของแก๊ส$t$, $t$วัดมวลของสาร$t$, $t$วัดอุณหภูมิของสาร$t$, 0, $t$เป็นอินดิเคเตอร์ผสมที่เปลี่ยนสีได้หลายช่วง pH$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$อินดิเคเตอร์สากล (universal indicator) ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$สารสกัดจากกะหล่ำปลีสีม่วงใช้ทำอะไรได้$t$, $t$เป็นอินดิเคเตอร์ธรรมชาติบอกกรด-เบส$t$, $t$ใช้วัดความหนาแน่น$t$, $t$เป็นเชื้อเพลิง$t$, $t$เป็นสารละลายบัฟเฟอร์เท่านั้น$t$, 0, $t$สีเปลี่ยนตาม pH (แดง-ม่วง-เขียว-เหลือง)$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$สารสกัดจากกะหล่ำปลีสีม่วงใช้ทำอะไรได้$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$น้ำปูนใสจะขุ่นขาวเมื่อรับแก๊สใด$t$, $t$O₂$t$, $t$H₂$t$, $t$CO₂$t$, $t$N₂$t$, 2, $t$Ca(OH)₂ + CO₂ → CaCO₃ (ตะกอนขาว) + H₂O$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$น้ำปูนใสจะขุ่นขาวเมื่อรับแก๊สใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$ข้อใดเป็นอินดิเคเตอร์ตามธรรมชาติ$t$, $t$น้ำมันพืช$t$, $t$ดอกอัญชัน$t$, $t$เกลือแกง$t$, $t$น้ำตาลทราย$t$, 1, $t$สารแอนโทไซยานินเปลี่ยนสีตามค่า pH$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$ข้อใดเป็นอินดิเคเตอร์ตามธรรมชาติ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$ขมิ้นชันเมื่อหยดสารละลายเบสจะเปลี่ยนเป็นสีใด$t$, $t$แดงน้ำตาล$t$, $t$เขียวใส$t$, $t$ไม่มีสี$t$, $t$น้ำเงิน$t$, 0, $t$ใช้เป็นอินดิเคเตอร์ธรรมชาติ$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$ขมิ้นชันเมื่อหยดสารละลายเบสจะเปลี่ยนเป็นสีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$สารละลายที่ทำให้ลิตมัสแดงเป็นน้ำเงินมีสมบัติเป็นอะไร$t$, $t$เกลือกรด$t$, $t$กลาง$t$, $t$เบส$t$, $t$กรด$t$, 2, $t$เบสเปลี่ยนลิตมัสแดงเป็นน้ำเงิน$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$สารละลายที่ทำให้ลิตมัสแดงเป็นน้ำเงินมีสมบัติเป็นอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$หลังจากหยดฟีนอล์ฟทาลีนลงในสารละลายแล้วได้สีชมพู แสดงว่าสารละลายเป็นอะไร$t$, $t$กลาง$t$, $t$น้ำตาล$t$, $t$กรด$t$, $t$เบส$t$, 3, $t$เกินช่วง pH ประมาณ 8.3$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$หลังจากหยดฟีนอล์ฟทาลีนลงในสารละลายแล้วได้สีชมพู แสดงว่าสารละลายเป็นอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$อุปกรณ์ใดใช้หยดสารละลายและวัดปริมาตรที่ใช้ในการไทเทรตได้แม่นยำ$t$, $t$บิวเรต$t$, $t$กระบอกตวง$t$, $t$ขวดรูปกรวย$t$, $t$บีกเกอร์$t$, 0, $t$ปริมาตรอ่านจากขีดบอกบนหลอดแก้วยาว มีก๊อกควบคุมการไหล$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$อุปกรณ์ใดใช้หยดสารละลายและวัดปริมาตรที่ใช้ในการไทเทรตได้แม่นยำ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$อุปกรณ์ใดเหมาะที่สุดสำหรับเตรียมสารละลายที่มีปริมาตรแน่นอน$t$, $t$ขวดกำหนดปริมาตร$t$, $t$บีกเกอร์$t$, $t$ขวดรูปชมพู่$t$, $t$หลอดทดลอง$t$, 0, $t$มีขีดบอกปริมาตรเดียวและมีความแม่นยำสูง$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$อุปกรณ์ใดเหมาะที่สุดสำหรับเตรียมสารละลายที่มีปริมาตรแน่นอน$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$อุปกรณ์ใดใช้วัดปริมาตรของเหลวโดยประมาณ$t$, $t$กระบอกตวง$t$, $t$ขวดกำหนดปริมาตร$t$, $t$บิวเรต$t$, $t$ปิเปตวัดปริมาตร$t$, 0, $t$ความแม่นยำปานกลาง ใช้งานง่าย$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$อุปกรณ์ใดใช้วัดปริมาตรของเหลวโดยประมาณ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$อุปกรณ์ใดใช้ถ่ายโอนสารละลายปริมาตรแน่นอน$t$, $t$บีกเกอร์$t$, $t$ปิเปต$t$, $t$เบ้าหลอม$t$, $t$กรวยแก้ว$t$, 1, $t$ดูดสารละลายตามปริมาตรที่ต้องการ$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$อุปกรณ์ใดใช้ถ่ายโอนสารละลายปริมาตรแน่นอน$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$อุปกรณ์ใดใช้ระเหยสารละลายให้แห้งเพื่อให้ได้ของแข็ง$t$, $t$ปิเปต$t$, $t$บิวเรต$t$, $t$กระบอกตวง$t$, $t$ถ้วยระเหย$t$, 3, $t$ทนความร้อนได้ ใช้ในการระเหยตัวทำละลาย$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$อุปกรณ์ใดใช้ระเหยสารละลายให้แห้งเพื่อให้ได้ของแข็ง$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$อุปกรณ์ใดใช้ให้ความร้อนสารที่อุณหภูมิสูงมาก เช่น เผาสารจนไหม้หมด$t$, $t$หลอดทดลอง$t$, $t$ขวดรูปชมพู่$t$, $t$เบ้าหลอม$t$, $t$บีกเกอร์$t$, 2, $t$ทำจากเซรามิก ทนความร้อนสูง$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$อุปกรณ์ใดใช้ให้ความร้อนสารที่อุณหภูมิสูงมาก เช่น เผาสารจนไหม้หมด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$อุปกรณ์ใดใช้จับหรือคีบถ้วยระเหยร้อน$t$, $t$ช้อนตักสาร$t$, $t$คีมคีบ$t$, $t$หลอดหยด$t$, $t$แท่งแก้ว$t$, 1, $t$ป้องกันความร้อนลวกมือ$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$อุปกรณ์ใดใช้จับหรือคีบถ้วยระเหยร้อน$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$อุปกรณ์ใดใช้ให้ความร้อนที่ให้เปลวไฟสีฟ้า ปรับอากาศและแก๊สได้$t$, $t$เตาไมโครเวฟ$t$, $t$ตะเกียงบุนเซน$t$, $t$ฮอตเพลต$t$, $t$ตะเกียงแอลกอฮอล์$t$, 1, $t$ใช้แก๊สเชื้อเพลิง เปลวไฟร้อนสูง$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$อุปกรณ์ใดใช้ให้ความร้อนที่ให้เปลวไฟสีฟ้า ปรับอากาศและแก๊สได้$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$ตะแกรงลวดที่วางบนขาตั้งสามขามีหน้าที่ใด$t$, $t$ใช้ผสมสาร$t$, $t$กระจายความร้อนให้ทั่วภาชนะ$t$, $t$ใช้วัดอุณหภูมิ$t$, $t$ใช้กรองสาร$t$, 1, $t$ป้องกันภาชนะแก้วร้อนไม่สม่ำเสมอ$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$ตะแกรงลวดที่วางบนขาตั้งสามขามีหน้าที่ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$อุปกรณ์ใดใช้แยกของแข็งที่ไม่ละลายออกจากของเหลว ควบคู่กับกระดาษกรอง$t$, $t$กรวยกรอง$t$, $t$ถ้วยระเหย$t$, $t$กรวยแยก$t$, $t$บิวเรต$t$, 0, $t$กระดาษกรองพับวางในกรวยแก้ว$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$อุปกรณ์ใดใช้แยกของแข็งที่ไม่ละลายออกจากของเหลว ควบคู่กับกระดาษกรอง$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$อุปกรณ์ใดใช้แยกของเหลวสองชนิดที่ไม่ละลายกัน เช่น น้ำมันกับน้ำ$t$, $t$กระบอกตวง$t$, $t$กรวยกรอง$t$, $t$กรวยแยก$t$, $t$ปิเปต$t$, 2, $t$ของเหลวชั้นล่างปล่อยออกทางก๊อก$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$อุปกรณ์ใดใช้แยกของเหลวสองชนิดที่ไม่ละลายกัน เช่น น้ำมันกับน้ำ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$อุปกรณ์ใดใช้ชั่งมวลสาร$t$, $t$เครื่องชั่ง$t$, $t$ปิเปต$t$, $t$เทอร์มอมิเตอร์$t$, $t$บิวเรต$t$, 0, $t$หน่วยมวลเป็นกรัม$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$อุปกรณ์ใดใช้ชั่งมวลสาร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$อุปกรณ์ใดใช้วัดอุณหภูมิ$t$, $t$บีกเกอร์$t$, $t$เทอร์มอมิเตอร์$t$, $t$กระบอกตวง$t$, $t$เครื่องชั่ง$t$, 1, $t$หน่วยเป็นองศาเซลเซียสหรือเคลวิน$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$อุปกรณ์ใดใช้วัดอุณหภูมิ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$กระจกนาฬิกา (watch glass) มักใช้ทำอะไร$t$, $t$ใช้กรองสาร$t$, $t$ใส่สารปริมาณน้อยเพื่อชั่งหรือสังเกต$t$, $t$ใช้วัดปริมาตร$t$, $t$ใช้ต้มสารละลาย$t$, 1, $t$เป็นแผ่นแก้วโค้งเล็กน้อย$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$กระจกนาฬิกา (watch glass) มักใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$หลอดหยดใช้ทำอะไร$t$, $t$วัดอุณหภูมิ$t$, $t$ถ่ายโอนของเหลวปริมาณน้อยเป็นหยดๆ$t$, $t$ให้ความร้อน$t$, $t$ชั่งมวล$t$, 1, $t$ควบคุมปริมาณสารได้ละเอียด$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$หลอดหยดใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$ขวดรูปชมพู่ (Erlenmeyer flask) นิยมใช้ทำอะไร$t$, $t$ผสมสารและไทเทรต เพราะเขย่าได้โดยไม่กระเด็น$t$, $t$กรองสาร$t$, $t$วัดปริมาตรแม่นยำ$t$, $t$ชั่งสาร$t$, 0, $t$ปากแคบกว่าก้น ลดการหกกระเด็น$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$ขวดรูปชมพู่ (Erlenmeyer flask) นิยมใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$แท่งแก้วคน (glass rod) ใช้ทำอะไร$t$, $t$ให้ความร้อน$t$, $t$กวนสารให้เข้ากันหรือช่วยนำทางเมื่อเท$t$, $t$วัดปริมาตร$t$, $t$ชั่งมวล$t$, 1, $t$ใช้ร่วมกับบีกเกอร์$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$แท่งแก้วคน (glass rod) ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$ตัวอ่านปริมาตรของเหลวในหลอดแก้วควรอ่านที่ระดับใด$t$, $t$เหนือผิวของเหลว$t$, $t$ระดับสายตาตรงกับผิวโค้งต่ำสุด (เมนิสคัส)$t$, $t$ระดับก้นภาชนะ$t$, $t$จากด้านบนมองลงมา$t$, 1, $t$ลดความผิดพลาดจากพารัลแลกซ์$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$ตัวอ่านปริมาตรของเหลวในหลอดแก้วควรอ่านที่ระดับใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยในห้องปฏิบัติการ$t$, $t$สัญลักษณ์รูปหัวกะโหลกไขว้ในฉลากสารเคมีบอกอันตรายใด$t$, $t$ระเบิดได้$t$, $t$ไวไฟ$t$, $t$เป็นพิษ$t$, $t$กัดกร่อน$t$, 2, $t$พิษร้ายแรงถึงตายหากสูดดมหรือกลืน$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยในห้องปฏิบัติการ$t$ and question = $t$สัญลักษณ์รูปหัวกะโหลกไขว้ในฉลากสารเคมีบอกอันตรายใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยในห้องปฏิบัติการ$t$, $t$สัญลักษณ์รูปเปลวไฟบนฉลากสารเคมีหมายถึงอะไร$t$, $t$ระเบิดได้$t$, $t$เป็นพิษ$t$, $t$กัดกร่อน$t$, $t$สารไวไฟ$t$, 3, $t$ห้ามอยู่ใกล้เปลวไฟหรือประกายไฟ$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยในห้องปฏิบัติการ$t$ and question = $t$สัญลักษณ์รูปเปลวไฟบนฉลากสารเคมีหมายถึงอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยในห้องปฏิบัติการ$t$, $t$สัญลักษณ์รูปมือถูกกัดและโลหะถูกกัดกร่อน หมายถึงอะไร$t$, $t$เป็นพิษ$t$, $t$ออกซิไดส์$t$, $t$กัดกร่อน$t$, $t$ไวไฟ$t$, 2, $t$ระวังกรดแก่และเบสแก่$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยในห้องปฏิบัติการ$t$ and question = $t$สัญลักษณ์รูปมือถูกกัดและโลหะถูกกัดกร่อน หมายถึงอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยในห้องปฏิบัติการ$t$, $t$ควรทำอย่างไรเมื่อต้องเจือจางกรดซัลฟิวริกเข้มข้นด้วยน้ำ$t$, $t$ค่อยๆ เทกรดลงในน้ำ พร้อมกวนเบาๆ$t$, $t$ใช้ความร้อนช่วย$t$, $t$เทน้ำลงในกรดอย่างรวดเร็ว$t$, $t$เทพร้อมกันทั้งสองอย่าง$t$, 0, $t$ปฏิกิริยาคายความร้อนสูง การเติมน้ำลงกรดอาจกระเด็นรุนแรง$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยในห้องปฏิบัติการ$t$ and question = $t$ควรทำอย่างไรเมื่อต้องเจือจางกรดซัลฟิวริกเข้มข้นด้วยน้ำ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยในห้องปฏิบัติการ$t$, $t$เมื่อกรดหกรดผิวหนัง ควรทำสิ่งใดก่อน$t$, $t$เช็ดด้วยกระดาษแห้ง$t$, $t$ทาด้วยเบสแก่$t$, $t$ล้างด้วยน้ำสะอาดปริมาณมากอย่างน้อย 15 นาที$t$, $t$ปล่อยให้แห้งเอง$t$, 2, $t$ล้างให้เจือจางก่อน แล้วแจ้งครูทันที$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยในห้องปฏิบัติการ$t$ and question = $t$เมื่อกรดหกรดผิวหนัง ควรทำสิ่งใดก่อน$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยในห้องปฏิบัติการ$t$, $t$วิธีดมกลิ่นสารเคมีที่ปลอดภัยคือข้อใด$t$, $t$ดมใกล้ๆ ทีละหลายครั้ง$t$, $t$ใช้ปากชิมรส$t$, $t$ใช้มือโบกไอสารเข้าหาจมูกเบาๆ$t$, $t$เอาจมูกจ่อปากภาชนะแล้วสูดแรงๆ$t$, 2, $t$หลีกเลี่ยงการสูดไอสารโดยตรง$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยในห้องปฏิบัติการ$t$ and question = $t$วิธีดมกลิ่นสารเคมีที่ปลอดภัยคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยในห้องปฏิบัติการ$t$, $t$อุปกรณ์ป้องกันดวงตาที่ต้องใส่ขณะทำการทดลองเคมีคือข้อใด$t$, $t$แว่นตานิรภัย$t$, $t$ผ้าปิดจมูกอย่างเดียว$t$, $t$หมวกกันน็อก$t$, $t$แว่นกันแดด$t$, 0, $t$ป้องกันสารเคมีกระเด็นเข้าตา$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยในห้องปฏิบัติการ$t$ and question = $t$อุปกรณ์ป้องกันดวงตาที่ต้องใส่ขณะทำการทดลองเคมีคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยในห้องปฏิบัติการ$t$, $t$ข้อใดเป็นการปฏิบัติที่ถูกต้องในห้องปฏิบัติการ$t$, $t$วิ่งเล่นในห้องแล็บ$t$, $t$กินอาหารระหว่างทดลอง$t$, $t$ชิมสารเพื่อทดสอบ$t$, $t$รวบผมให้เรียบร้อยและสวมเสื้อกาวน์$t$, 3, $t$เพื่อความปลอดภัยของตนเองและผู้อื่น$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยในห้องปฏิบัติการ$t$ and question = $t$ข้อใดเป็นการปฏิบัติที่ถูกต้องในห้องปฏิบัติการ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยในห้องปฏิบัติการ$t$, $t$เมื่อให้ความร้อนหลอดทดลองที่ใส่ของเหลว ควรหันปากหลอดไปทางใด$t$, $t$ไม่หันเข้าหาตนเองหรือผู้อื่น$t$, $t$ลงพื้นโดยตรง$t$, $t$เข้าหาตนเอง$t$, $t$เข้าหาเพื่อน$t$, 0, $t$ป้องกันของเหลวพุ่งออกมาลวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยในห้องปฏิบัติการ$t$ and question = $t$เมื่อให้ความร้อนหลอดทดลองที่ใส่ของเหลว ควรหันปากหลอดไปทางใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยในห้องปฏิบัติการ$t$, $t$ควรทำอย่างไรกับสารเคมีที่เหลือจากการทดลอง$t$, $t$เทกลับขวดเดิมทันที$t$, $t$นำกลับบ้าน$t$, $t$ทิ้งลงอ่างล้างมือทุกชนิด$t$, $t$ทิ้งในภาชนะรองรับของเสียตามที่ครูกำหนด$t$, 3, $t$ป้องกันการปนเปื้อนและมลพิษ$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยในห้องปฏิบัติการ$t$ and question = $t$ควรทำอย่างไรกับสารเคมีที่เหลือจากการทดลอง$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยในห้องปฏิบัติการ$t$, $t$สัญลักษณ์เครื่องหมายตกใจ (!) บนฉลากสารเคมีบ่งบอกถึงอะไร$t$, $t$ระคายเคือง/อันตรายต่อสุขภาพในระดับหนึ่ง$t$, $t$ปลอดภัยสมบูรณ์$t$, $t$เป็นพิษถึงตายเสมอ$t$, $t$สารกัมมันตรังสี$t$, 0, $t$ควรหลีกเลี่ยงการสัมผัสและสูดดม$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยในห้องปฏิบัติการ$t$ and question = $t$สัญลักษณ์เครื่องหมายตกใจ (!) บนฉลากสารเคมีบ่งบอกถึงอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยในห้องปฏิบัติการ$t$, $t$ก่อนใช้สารเคมีควรปฏิบัติสิ่งใดเป็นลำดับแรก$t$, $t$ผสมกับสารอื่นเพื่อดูผล$t$, $t$ชิมรสเพื่อเช็กชนิด$t$, $t$อ่านฉลากและคำเตือนบนภาชนะ$t$, $t$เทใส่มือก่อนใช้งาน$t$, 2, $t$ฉลากบอกชื่อสาร อันตราย และการเก็บรักษา$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยในห้องปฏิบัติการ$t$ and question = $t$ก่อนใช้สารเคมีควรปฏิบัติสิ่งใดเป็นลำดับแรก$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและการวัด$t$, $t$คำนำหน้าหน่วย กิโล (k) มีค่าเท่าใด$t$, $t$10⁶$t$, $t$10²$t$, $t$10³$t$, $t$10⁻³$t$, 2, $t$1 กิโลเมตร = 1000 เมตร$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและการวัด$t$ and question = $t$คำนำหน้าหน่วย กิโล (k) มีค่าเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและการวัด$t$, $t$คำนำหน้าหน่วย มิลลิ (m) มีค่าเท่าใด$t$, $t$10³$t$, $t$10⁻²$t$, $t$10⁻³$t$, $t$10⁻⁶$t$, 2, $t$1 มิลลิลิตร = 0.001 ลิตร$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและการวัด$t$ and question = $t$คำนำหน้าหน่วย มิลลิ (m) มีค่าเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและการวัด$t$, $t$คำนำหน้าหน่วย เซนติ (c) มีค่าเท่าใด$t$, $t$10⁻¹$t$, $t$10⁻²$t$, $t$10²$t$, $t$10⁻³$t$, 1, $t$1 เซนติเมตร = 0.01 เมตร$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและการวัด$t$ and question = $t$คำนำหน้าหน่วย เซนติ (c) มีค่าเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและการวัด$t$, $t$คำนำหน้าหน่วย ไมโคร (μ) มีค่าเท่าใด$t$, $t$10⁻⁹$t$, $t$10⁶$t$, $t$10⁻⁶$t$, $t$10⁻³$t$, 2, $t$1 ไมโครเมตร = 10⁻⁶ เมตร$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและการวัด$t$ and question = $t$คำนำหน้าหน่วย ไมโคร (μ) มีค่าเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและการวัด$t$, $t$คำนำหน้าหน่วย นาโน (n) มีค่าเท่าใด$t$, $t$10⁹$t$, $t$10⁻⁹$t$, $t$10⁻¹²$t$, $t$10⁻⁶$t$, 1, $t$1 นาโนเมตร = 10⁻⁹ เมตร$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและการวัด$t$ and question = $t$คำนำหน้าหน่วย นาโน (n) มีค่าเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและการวัด$t$, $t$คำนำหน้าหน่วย เมกะ (M) มีค่าเท่าใด$t$, $t$10⁻⁶$t$, $t$10³$t$, $t$10⁹$t$, $t$10⁶$t$, 3, $t$1 เมกะไบต์ ≈ 10⁶ ไบต์$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและการวัด$t$ and question = $t$คำนำหน้าหน่วย เมกะ (M) มีค่าเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและการวัด$t$, $t$1 ลิตร เท่ากับกี่มิลลิลิตร$t$, $t$100 มิลลิลิตร$t$, $t$10000 มิลลิลิตร$t$, $t$1000 มิลลิลิตร$t$, $t$10 มิลลิลิตร$t$, 2, $t$1 L = 1000 mL$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและการวัด$t$ and question = $t$1 ลิตร เท่ากับกี่มิลลิลิตร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและการวัด$t$, $t$1 มิลลิลิตร มีปริมาตรเท่ากับข้อใด$t$, $t$10 ลูกบาศก์เซนติเมตร$t$, $t$1 ลูกบาศก์เซนติเมตร$t$, $t$0.1 ลูกบาศก์เซนติเมตร$t$, $t$1 ลูกบาศก์เมตร$t$, 1, $t$1 mL = 1 cm³$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและการวัด$t$ and question = $t$1 มิลลิลิตร มีปริมาตรเท่ากับข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและการวัด$t$, $t$1 กิโลกรัม เท่ากับกี่กรัม$t$, $t$10 กรัม$t$, $t$1000 กรัม$t$, $t$10000 กรัม$t$, $t$100 กรัม$t$, 1, $t$1 kg = 1000 g$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและการวัด$t$ and question = $t$1 กิโลกรัม เท่ากับกี่กรัม$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและการวัด$t$, $t$หน่วย SI ของปริมาณสารคือข้อใด$t$, $t$โมล (mol)$t$, $t$กิโลกรัม$t$, $t$กรัม$t$, $t$ลิตร$t$, 0, $t$ใช้บอกจำนวนอนุภาคของสาร$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและการวัด$t$ and question = $t$หน่วย SI ของปริมาณสารคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและการวัด$t$, $t$หน่วย SI ของอุณหภูมิคือข้อใด$t$, $t$องศาเซลเซียส$t$, $t$เคลวิน (K)$t$, $t$องศาฟาเรนไฮต์$t$, $t$แคลอรี$t$, 1, $t$K = °C + 273$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและการวัด$t$ and question = $t$หน่วย SI ของอุณหภูมิคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและการวัด$t$, $t$0 องศาเซลเซียส เท่ากับกี่เคลวิน (ประมาณ)$t$, $t$0 K$t$, $t$100 K$t$, $t$373 K$t$, $t$273 K$t$, 3, $t$K = °C + 273$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและการวัด$t$ and question = $t$0 องศาเซลเซียส เท่ากับกี่เคลวิน (ประมาณ)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$ใครเสนอทฤษฎีอะตอมว่าอะตอมเป็นทรงกลมตัน แบ่งแยกไม่ได้$t$, $t$จอห์น ดาลตัน$t$, $t$เจ.เจ. ทอมสัน$t$, $t$นีลส์ โบร์$t$, $t$เออร์เนสต์ รัทเทอร์ฟอร์ด$t$, 0, $t$แบบจำลองอะตอมของดาลตัน (ค.ศ. 1803)$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$ใครเสนอทฤษฎีอะตอมว่าอะตอมเป็นทรงกลมตัน แบ่งแยกไม่ได้$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$ใครค้นพบอิเล็กตรอน$t$, $t$เจ.เจ. ทอมสัน$t$, $t$จอห์น ดาลตัน$t$, $t$โรเบิร์ต มิลลิแกน$t$, $t$เจมส์ แชดวิก$t$, 0, $t$จากการทดลองรังสีแคโทด$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$ใครค้นพบอิเล็กตรอน$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$แบบจำลองอะตอมแบบพุดดิ้งลูกเกด (plum pudding) เสนอโดยใคร$t$, $t$จอห์น ดาลตัน$t$, $t$เจ.เจ. ทอมสัน$t$, $t$เออร์วิน ชเรอดิงเงอร์$t$, $t$นีลส์ โบร์$t$, 1, $t$อะตอมเป็นทรงกลมมีประจุบวก มีอิเล็กตรอนฝังอยู่$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$แบบจำลองอะตอมแบบพุดดิ้งลูกเกด (plum pudding) เสนอโดยใคร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$ใครค้นพบนิวเคลียสของอะตอมจากการทดลองยิงอนุภาคแอลฟาใส่แผ่นทองคำ$t$, $t$เจ.เจ. ทอมสัน$t$, $t$เออร์เนสต์ รัทเทอร์ฟอร์ด$t$, $t$เจมส์ แชดวิก$t$, $t$นีลส์ โบร์$t$, 1, $t$อะตอมส่วนใหญ่เป็นที่ว่าง มีนิวเคลียสเล็กหนาแน่นประจุบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$ใครค้นพบนิวเคลียสของอะตอมจากการทดลองยิงอนุภาคแอลฟาใส่แผ่นทองคำ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$ใครเสนอแบบจำลองอะตอมที่อิเล็กตรอนโคจรในระดับพลังงานเฉพาะ$t$, $t$เจ.เจ. ทอมสัน$t$, $t$เออร์เนสต์ รัทเทอร์ฟอร์ด$t$, $t$นีลส์ โบร์$t$, $t$จอห์น ดาลตัน$t$, 2, $t$แบบจำลองอะตอมของโบร์$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$ใครเสนอแบบจำลองอะตอมที่อิเล็กตรอนโคจรในระดับพลังงานเฉพาะ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$ใครค้นพบนิวตรอน$t$, $t$นีลส์ โบร์$t$, $t$เจมส์ แชดวิก$t$, $t$เออร์เนสต์ รัทเทอร์ฟอร์ด$t$, $t$เจ.เจ. ทอมสัน$t$, 1, $t$ค.ศ. 1932$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$ใครค้นพบนิวตรอน$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$ใครเป็นผู้เรียงธาตุตามมวลอะตอมและจัดทำตารางธาตุฉบับแรกที่ทำนายธาตุที่ยังไม่พบได้$t$, $t$เฮนรี มอสลีย์$t$, $t$ดิมิทรี เมนเดเลเยฟ$t$, $t$จอห์น ดาลตัน$t$, $t$อันตวน ลาวัวซีเย$t$, 1, $t$ตารางธาตุของเมนเดเลเยฟ$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$ใครเป็นผู้เรียงธาตุตามมวลอะตอมและจัดทำตารางธาตุฉบับแรกที่ทำนายธาตุที่ยังไม่พบได้$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$ใครเสนอให้เรียงธาตุตามเลขอะตอม$t$, $t$นีลส์ โบร์$t$, $t$เฮนรี มอสลีย์$t$, $t$ดิมิทรี เมนเดเลเยฟ$t$, $t$จอห์น ดาลตัน$t$, 1, $t$ตารางธาตุปัจจุบันเรียงตามเลขอะตอม$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$ใครเสนอให้เรียงธาตุตามเลขอะตอม$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$ใครเสนอกฎทรงมวล (มวลรวมก่อนและหลังปฏิกิริยาเท่ากัน)$t$, $t$อันตวน ลาวัวซีเย$t$, $t$โรเบิร์ต บอยล์$t$, $t$อาโวกาโดร$t$, $t$จอห์น ดาลตัน$t$, 0, $t$มวลสารไม่สูญหายและไม่เกิดขึ้นใหม่$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$ใครเสนอกฎทรงมวล (มวลรวมก่อนและหลังปฏิกิริยาเท่ากัน)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$ใครเสนอกฎสัดส่วนคงที่ของสารประกอบ$t$, $t$อาโวกาโดร$t$, $t$โรเบิร์ต บอยล์$t$, $t$โจเซฟ พราวส์ท$t$, $t$ชาร์ลส์$t$, 2, $t$สารประกอบหนึ่งมีอัตราส่วนโดยมวลคงที่เสมอ$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$ใครเสนอกฎสัดส่วนคงที่ของสารประกอบ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$กฎของบอยล์ (Boyle) อธิบายความสัมพันธ์ระหว่างปริมาณใด$t$, $t$ปริมาตรกับอุณหภูมิ$t$, $t$ความดันกับอุณหภูมิ$t$, $t$มวลกับปริมาตร$t$, $t$ความดันกับปริมาตรของแก๊ส เมื่ออุณหภูมิคงที่$t$, 3, $t$P ∝ 1/V$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$กฎของบอยล์ (Boyle) อธิบายความสัมพันธ์ระหว่างปริมาณใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$กฎของชาร์ลส์ (Charles) อธิบายความสัมพันธ์ระหว่างปริมาณใด$t$, $t$มวลกับพลังงาน$t$, $t$ความดันกับจำนวนโมล$t$, $t$ความดันกับปริมาตร$t$, $t$ปริมาตรกับอุณหภูมิ (เคลวิน) เมื่อความดันคงที่$t$, 3, $t$V ∝ T$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$กฎของชาร์ลส์ (Charles) อธิบายความสัมพันธ์ระหว่างปริมาณใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$ใครเสนอว่าแก๊สที่ปริมาตรเท่ากัน ที่ T และ P เดียวกัน มีจำนวนโมเลกุลเท่ากัน$t$, $t$บอยล์$t$, $t$ชาร์ลส์$t$, $t$ดาลตัน$t$, $t$อาโวกาโดร$t$, 3, $t$กฎของอาโวกาโดร$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$ใครเสนอว่าแก๊สที่ปริมาตรเท่ากัน ที่ T และ P เดียวกัน มีจำนวนโมเลกุลเท่ากัน$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$แบบจำลองอะตอมแบบกลุ่มหมอก (กลุ่มหมอกอิเล็กตรอน) พัฒนาจากแนวคิดของใคร$t$, $t$เจ.เจ. ทอมสัน$t$, $t$เออร์วิน ชเรอดิงเงอร์$t$, $t$จอห์น ดาลตัน$t$, $t$เออร์เนสต์ รัทเทอร์ฟอร์ด$t$, 1, $t$แบบจำลองกลศาสตร์ควอนตัม$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$แบบจำลองอะตอมแบบกลุ่มหมอก (กลุ่มหมอกอิเล็กตรอน) พัฒนาจากแนวคิดของใคร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สถานะและการเปลี่ยนสถานะ$t$, $t$การเปลี่ยนสถานะจากของเหลวเป็นแก๊สเรียกว่าอะไร$t$, $t$การระเหิด$t$, $t$การแข็งตัว$t$, $t$การกลายเป็นไอ (ระเหย/เดือด)$t$, $t$การหลอมเหลว$t$, 2, $t$น้ำเป็นไอน้ำ$t$
where not exists (select 1 from quiz_questions where topic = $t$สถานะและการเปลี่ยนสถานะ$t$ and question = $t$การเปลี่ยนสถานะจากของเหลวเป็นแก๊สเรียกว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สถานะและการเปลี่ยนสถานะ$t$, $t$การเปลี่ยนสถานะจากของเหลวเป็นของแข็งเรียกว่าอะไร$t$, $t$การระเหย$t$, $t$การควบแน่น$t$, $t$การแข็งตัว$t$, $t$การหลอมเหลว$t$, 2, $t$น้ำเป็นน้ำแข็ง$t$
where not exists (select 1 from quiz_questions where topic = $t$สถานะและการเปลี่ยนสถานะ$t$ and question = $t$การเปลี่ยนสถานะจากของเหลวเป็นของแข็งเรียกว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สถานะและการเปลี่ยนสถานะ$t$, $t$น้ำบริสุทธิ์เดือดที่อุณหภูมิกี่องศาเซลเซียส (ที่ความดัน 1 บรรยากาศ)$t$, $t$0$t$, $t$50$t$, $t$373$t$, $t$100$t$, 3, $t$จุดเดือดของน้ำ = 100 °C$t$
where not exists (select 1 from quiz_questions where topic = $t$สถานะและการเปลี่ยนสถานะ$t$ and question = $t$น้ำบริสุทธิ์เดือดที่อุณหภูมิกี่องศาเซลเซียส (ที่ความดัน 1 บรรยากาศ)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สถานะและการเปลี่ยนสถานะ$t$, $t$น้ำบริสุทธิ์แข็งตัวที่อุณหภูมิกี่องศาเซลเซียส (ที่ความดัน 1 บรรยากาศ)$t$, $t$10$t$, $t$−10$t$, $t$0$t$, $t$100$t$, 2, $t$จุดเยือกแข็ง/จุดหลอมเหลวของน้ำ = 0 °C$t$
where not exists (select 1 from quiz_questions where topic = $t$สถานะและการเปลี่ยนสถานะ$t$ and question = $t$น้ำบริสุทธิ์แข็งตัวที่อุณหภูมิกี่องศาเซลเซียส (ที่ความดัน 1 บรรยากาศ)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สถานะและการเปลี่ยนสถานะ$t$, $t$ขณะสารบริสุทธิ์กำลังเปลี่ยนสถานะ อุณหภูมิจะเป็นอย่างไร$t$, $t$เพิ่มขึ้นเรื่อยๆ$t$, $t$ผันผวนไม่แน่นอน$t$, $t$คงที่$t$, $t$ลดลงเรื่อยๆ$t$, 2, $t$พลังงานที่ให้ใช้ในการเปลี่ยนสถานะ$t$
where not exists (select 1 from quiz_questions where topic = $t$สถานะและการเปลี่ยนสถานะ$t$ and question = $t$ขณะสารบริสุทธิ์กำลังเปลี่ยนสถานะ อุณหภูมิจะเป็นอย่างไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สถานะและการเปลี่ยนสถานะ$t$, $t$สถานะใดของสารที่ไม่มีรูปร่างและปริมาตรคงที่ ขยายเต็มภาชนะ$t$, $t$ของแข็ง$t$, $t$ของเหลว$t$, $t$แก๊ส$t$, $t$ผลึก$t$, 2, $t$อนุภาคอยู่ห่างกันมากและเคลื่อนที่อิสระ$t$
where not exists (select 1 from quiz_questions where topic = $t$สถานะและการเปลี่ยนสถานะ$t$ and question = $t$สถานะใดของสารที่ไม่มีรูปร่างและปริมาตรคงที่ ขยายเต็มภาชนะ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การแยกสาร$t$, $t$เกลือละลายอยู่ในน้ำ ต้องการแยกเกลือออกมาควรใช้วิธีใด$t$, $t$การใช้แม่เหล็ก$t$, $t$การร่อน$t$, $t$การกรอง$t$, $t$การระเหยแห้ง (ต้มระเหยน้ำ)$t$, 3, $t$เกลือไม่ระเหย น้ำระเหยออกไป$t$
where not exists (select 1 from quiz_questions where topic = $t$การแยกสาร$t$ and question = $t$เกลือละลายอยู่ในน้ำ ต้องการแยกเกลือออกมาควรใช้วิธีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การแยกสาร$t$, $t$ทรายปนเหล็กผง ควรแยกด้วยวิธีใด$t$, $t$ใช้แม่เหล็กดูดเหล็ก$t$, $t$การตกผลึก$t$, $t$การกลั่น$t$, $t$การระเหยแห้ง$t$, 0, $t$เหล็กถูกแม่เหล็กดูด ทรายไม่ถูก$t$
where not exists (select 1 from quiz_questions where topic = $t$การแยกสาร$t$ and question = $t$ทรายปนเหล็กผง ควรแยกด้วยวิธีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การแยกสาร$t$, $t$น้ำขุ่นที่มีดินปน ควรแยกด้วยวิธีใด$t$, $t$การกรอง$t$, $t$การกลั่น$t$, $t$การตกผลึก$t$, $t$การระเหิด$t$, 0, $t$ของแข็งไม่ละลายถูกกรองไว้บนกระดาษกรอง$t$
where not exists (select 1 from quiz_questions where topic = $t$การแยกสาร$t$ and question = $t$น้ำขุ่นที่มีดินปน ควรแยกด้วยวิธีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การแยกสาร$t$, $t$การแยกน้ำบริสุทธิ์ออกจากน้ำทะเลที่มีเกลือละลายอยู่ ใช้วิธีใด$t$, $t$การกลั่น$t$, $t$การร่อน$t$, $t$การกรอง$t$, $t$การหยิบออก$t$, 0, $t$น้ำเดือดเป็นไอแล้วควบแน่นกลับเป็นน้ำบริสุทธิ์$t$
where not exists (select 1 from quiz_questions where topic = $t$การแยกสาร$t$ and question = $t$การแยกน้ำบริสุทธิ์ออกจากน้ำทะเลที่มีเกลือละลายอยู่ ใช้วิธีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การแยกสาร$t$, $t$การแยกน้ำมันพืชออกจากน้ำใช้วิธีใดได้ดี$t$, $t$ใช้กรวยแยก$t$, $t$การระเหยแห้ง$t$, $t$การตกผลึก$t$, $t$การใช้แม่เหล็ก$t$, 0, $t$ของเหลวสองชั้นไม่ละลายกัน$t$
where not exists (select 1 from quiz_questions where topic = $t$การแยกสาร$t$ and question = $t$การแยกน้ำมันพืชออกจากน้ำใช้วิธีใดได้ดี$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การแยกสาร$t$, $t$การแยกสีผสมในหมึกปากกาออกเป็นสีต่างๆ ใช้วิธีใด$t$, $t$โครมาโทกราฟี$t$, $t$การกรอง$t$, $t$การระเหิด$t$, $t$การกลั่น$t$, 0, $t$สารต่างๆ เคลื่อนที่บนตัวดูดซับได้ไม่เท่ากัน$t$
where not exists (select 1 from quiz_questions where topic = $t$การแยกสาร$t$ and question = $t$การแยกสีผสมในหมึกปากกาออกเป็นสีต่างๆ ใช้วิธีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การแยกสาร$t$, $t$การแยกน้ำมันดิบเป็นส่วนต่างๆ ใช้วิธีใด$t$, $t$การกรอง$t$, $t$การกลั่นลำดับส่วน$t$, $t$การร่อน$t$, $t$การตกผลึก$t$, 1, $t$แยกตามจุดเดือดที่ต่างกัน$t$
where not exists (select 1 from quiz_questions where topic = $t$การแยกสาร$t$ and question = $t$การแยกน้ำมันดิบเป็นส่วนต่างๆ ใช้วิธีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การแยกสาร$t$, $t$การทำให้สารละลายอิ่มตัวเย็นลงแล้วได้ผลึกของสารบริสุทธิ์ขึ้นมาเรียกว่าอะไร$t$, $t$การกลั่น$t$, $t$การระเหิด$t$, $t$การตกผลึก$t$, $t$การกรอง$t$, 2, $t$เช่น การทำผลึกสารส้ม$t$
where not exists (select 1 from quiz_questions where topic = $t$การแยกสาร$t$ and question = $t$การทำให้สารละลายอิ่มตัวเย็นลงแล้วได้ผลึกของสารบริสุทธิ์ขึ้นมาเรียกว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การแยกสาร$t$, $t$การแยกสารที่ระเหิดได้ เช่น ไอโอดีน ออกจากสารที่ไม่ระเหิด ใช้วิธีใด$t$, $t$การกรอง$t$, $t$การระเหิด$t$, $t$การร่อน$t$, $t$การกลั่น$t$, 1, $t$ไอโอดีนระเหิดเป็นไอสีม่วงแล้วกลับเป็นของแข็ง$t$
where not exists (select 1 from quiz_questions where topic = $t$การแยกสาร$t$ and question = $t$การแยกสารที่ระเหิดได้ เช่น ไอโอดีน ออกจากสารที่ไม่ระเหิด ใช้วิธีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การแยกสาร$t$, $t$ข้าวสารปนก้อนกรวด ควรแยกด้วยวิธีใด$t$, $t$การกลั่น$t$, $t$การหยิบออกหรือการร่อน$t$, $t$การระเหยแห้ง$t$, $t$การตกผลึก$t$, 1, $t$อนุภาคขนาดต่างกันแยกด้วยการร่อนได้$t$
where not exists (select 1 from quiz_questions where topic = $t$การแยกสาร$t$ and question = $t$ข้าวสารปนก้อนกรวด ควรแยกด้วยวิธีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$เบกกิ้งโซดามีสูตรเคมีตามข้อใด$t$, $t$NaOH$t$, $t$Na₂CO₃$t$, $t$NaHCO₃$t$, $t$NaCl$t$, 2, $t$โซเดียมไฮโดรเจนคาร์บอเนต$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$เบกกิ้งโซดามีสูตรเคมีตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$โซดาซักผ้ามีสูตรเคมีตามข้อใด$t$, $t$Na₂CO₃$t$, $t$NaOH$t$, $t$NaCl$t$, $t$NaHCO₃$t$, 0, $t$โซเดียมคาร์บอเนต$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$โซดาซักผ้ามีสูตรเคมีตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$เกลือแกงมีสูตรเคมีตามข้อใด$t$, $t$KCl$t$, $t$NaCl$t$, $t$Na₂SO₄$t$, $t$NaHCO₃$t$, 1, $t$โซเดียมคลอไรด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$เกลือแกงมีสูตรเคมีตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$โซดาไฟมีสูตรเคมีตามข้อใด$t$, $t$Ca(OH)₂$t$, $t$Na₂CO₃$t$, $t$NaOH$t$, $t$KOH$t$, 2, $t$โซเดียมไฮดรอกไซด์ เบสแก่$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$โซดาไฟมีสูตรเคมีตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$หินปูนและหินอ่อนมีองค์ประกอบหลักคือสารใด$t$, $t$Ca(OH)₂$t$, $t$CaCO₃$t$, $t$CaSO₄$t$, $t$CaO$t$, 1, $t$แคลเซียมคาร์บอเนต$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$หินปูนและหินอ่อนมีองค์ประกอบหลักคือสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$น้ำปูนใสคือสารละลายของสารใด$t$, $t$CaO$t$, $t$NaOH$t$, $t$Ca(OH)₂$t$, $t$CaCO₃$t$, 2, $t$แคลเซียมไฮดรอกไซด์ในน้ำ$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$น้ำปูนใสคือสารละลายของสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$น้ำส้มสายชูมีองค์ประกอบหลักคือสารใด$t$, $t$NaOH$t$, $t$CH₃COOH$t$, $t$HCl$t$, $t$H₂SO₄$t$, 1, $t$กรดแอซีติก$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$น้ำส้มสายชูมีองค์ประกอบหลักคือสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$แอมโมเนียมีกลิ่นอย่างไร$t$, $t$หอมหวาน$t$, $t$ฉุนแสบจมูก$t$, $t$กลิ่นไข่เน่า$t$, $t$ไม่มีกลิ่น$t$, 1, $t$NH₃ มีกลิ่นฉุนเฉพาะตัว$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$แอมโมเนียมีกลิ่นอย่างไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$ทรายและแก้วมีองค์ประกอบหลักเป็นสารใด$t$, $t$Fe₂O₃$t$, $t$NaCl$t$, $t$SiO₂$t$, $t$CaCO₃$t$, 2, $t$ซิลิคอนไดออกไซด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$ทรายและแก้วมีองค์ประกอบหลักเป็นสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$จุนสีเป็นผลึกสีฟ้าของสารใด$t$, $t$FeSO₄·7H₂O$t$, $t$CuSO₄·5H₂O$t$, $t$NaCl$t$, $t$CaSO₄·2H₂O$t$, 1, $t$คอปเปอร์(II) ซัลเฟตเพนตะไฮเดรต$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$จุนสีเป็นผลึกสีฟ้าของสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$ยิปซัม (ใช้ทำปูนปลาสเตอร์) คือสารใด$t$, $t$CaSO₄·2H₂O$t$, $t$CaCO₃$t$, $t$NaCl$t$, $t$CuSO₄·5H₂O$t$, 0, $t$แคลเซียมซัลเฟตไดไฮเดรต$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$ยิปซัม (ใช้ทำปูนปลาสเตอร์) คือสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$น้ำตาลทรายมีสารองค์ประกอบหลักคือสารใด$t$, $t$กลูโคส$t$, $t$ซูโครส$t$, $t$แป้ง$t$, $t$ฟรุกโทส$t$, 1, $t$ไดแซ็กคาไรด์ของกลูโคสและฟรุกโทส$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$น้ำตาลทรายมีสารองค์ประกอบหลักคือสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$แก๊สหัวเราะคือสารใด$t$, $t$N₂O$t$, $t$NO2$t$, $t$NO$t$, $t$N₂$t$, 0, $t$ไดไนโตรเจนมอนอกไซด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$แก๊สหัวเราะคือสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$น้ำยาฟอกขาวที่ใช้ซักผ้าขาวมักมีสารใดเป็นตัวออกซิไดส์หลัก$t$, $t$โซเดียมไฮโปคลอไรต์ (NaOCl)$t$, $t$โซเดียมไฮดรอกไซด์ (NaOH)$t$, $t$โซเดียมคลอไรด์ (NaCl)$t$, $t$น้ำตาล$t$, 0, $t$ฟอกสีและฆ่าเชื้อ$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$น้ำยาฟอกขาวที่ใช้ซักผ้าขาวมักมีสารใดเป็นตัวออกซิไดส์หลัก$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$ไฮโดรเจนเปอร์ออกไซด์เจือจาง (H₂O₂) ใช้ประโยชน์ในข้อใด$t$, $t$ฆ่าเชื้อบาดแผลหรือฟอกสี$t$, $t$ปุ๋ย$t$, $t$เชื้อเพลิงรถยนต์$t$, $t$ให้ความหวาน$t$, 0, $t$สลายตัวให้ออกซิเจนและน้ำ$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$ไฮโดรเจนเปอร์ออกไซด์เจือจาง (H₂O₂) ใช้ประโยชน์ในข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$แก๊สหุงต้ม (LPG) ประกอบด้วยแก๊สใดเป็นหลัก$t$, $t$ไฮโดรเจนและออกซิเจน$t$, $t$มีเทนและอีเทน$t$, $t$CO₂ และไนโตรเจน$t$, $t$โพรเพนและบิวเทน$t$, 3, $t$อัดเป็นของเหลวในถัง$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$แก๊สหุงต้ม (LPG) ประกอบด้วยแก๊สใดเป็นหลัก$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$สนิมเหล็กมีองค์ประกอบหลักเป็นสารใดโดยประมาณ$t$, $t$CaCO₃$t$, $t$Fe₂O₃$t$, $t$NaCl$t$, $t$CuO$t$, 1, $t$เหล็กรวมกับออกซิเจนและความชื้น$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$สนิมเหล็กมีองค์ประกอบหลักเป็นสารใดโดยประมาณ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$ปุ๋ยยูเรียมีไนโตรเจนเป็นองค์ประกอบ มีสูตรคือข้อใด$t$, $t$(NH₂)₂CO$t$, $t$NaCl$t$, $t$CaCO₃$t$, $t$CH₄$t$, 0, $t$ยูเรียให้ธาตุไนโตรเจนแก่พืช$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$ปุ๋ยยูเรียมีไนโตรเจนเป็นองค์ประกอบ มีสูตรคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$เลขอาโวกาโดรมีค่าเท่าใด$t$, $t$6.02 × 10²³$t$, $t$3.01 × 10²³$t$, $t$6.02 × 10²⁴$t$, $t$6.02 × 10²²$t$, 0, $t$จำนวนอนุภาคใน 1 โมล$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$เลขอาโวกาโดรมีค่าเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$แก๊สใดๆ 1 โมล ที่ STP (0 °C, 1 atm) มีปริมาตรเท่าใด$t$, $t$1 ลิตร$t$, $t$24 ลิตร$t$, $t$22.4 ลิตร$t$, $t$11.2 ลิตร$t$, 2, $t$ปริมาตรมอลาร์ที่ STP$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$แก๊สใดๆ 1 โมล ที่ STP (0 °C, 1 atm) มีปริมาตรเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$H₂O 1 โมล มีกี่โมเลกุล$t$, $t$18 โมเลกุล$t$, $t$6.02 × 10²² โมเลกุล$t$, $t$6.02 × 10²³ โมเลกุล$t$, $t$1 โมเลกุล$t$, 2, $t$1 โมล = 6.02 × 10²³ อนุภาค$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$H₂O 1 โมล มีกี่โมเลกุล$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$มวลโมเลกุลของน้ำ (H₂O) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$, $t$36$t$, $t$20$t$, $t$18$t$, $t$16$t$, 2, $t$H₂O = 18$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$มวลโมเลกุลของน้ำ (H₂O) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$มวลโมเลกุลของคาร์บอนไดออกไซด์ (CO₂) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$, $t$42$t$, $t$88$t$, $t$44$t$, $t$46$t$, 2, $t$CO₂ = 44$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$มวลโมเลกุลของคาร์บอนไดออกไซด์ (CO₂) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$มวลโมเลกุลของโซเดียมคลอไรด์ (NaCl) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$, $t$56.5$t$, $t$60.5$t$, $t$117$t$, $t$58.5$t$, 3, $t$NaCl = 58.5$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$มวลโมเลกุลของโซเดียมคลอไรด์ (NaCl) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$มวลโมเลกุลของแอมโมเนีย (NH₃) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$, $t$34$t$, $t$15$t$, $t$19$t$, $t$17$t$, 3, $t$NH₃ = 17$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$มวลโมเลกุลของแอมโมเนีย (NH₃) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$มวลโมเลกุลของมีเทน (CH₄) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$, $t$16$t$, $t$18$t$, $t$14$t$, $t$32$t$, 0, $t$CH₄ = 16$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$มวลโมเลกุลของมีเทน (CH₄) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$มวลโมเลกุลของกรดซัลฟิวริก (H₂SO₄) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$, $t$98$t$, $t$100$t$, $t$88$t$, $t$96$t$, 0, $t$H₂SO₄ = 98$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$มวลโมเลกุลของกรดซัลฟิวริก (H₂SO₄) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$มวลโมเลกุลของแคลเซียมคาร์บอเนต (CaCO₃) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$, $t$90$t$, $t$102$t$, $t$100$t$, $t$98$t$, 2, $t$CaCO₃ = 100$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$มวลโมเลกุลของแคลเซียมคาร์บอเนต (CaCO₃) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$มวลโมเลกุลของโซเดียมไฮดรอกไซด์ (NaOH) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$, $t$40$t$, $t$80$t$, $t$42$t$, $t$38$t$, 0, $t$NaOH = 40$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$มวลโมเลกุลของโซเดียมไฮดรอกไซด์ (NaOH) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$มวลโมเลกุลของกลูโคส (C₆H₁₂O₆) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$, $t$170$t$, $t$178$t$, $t$180$t$, $t$182$t$, 2, $t$C₆H₁₂O₆ = 180$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$มวลโมเลกุลของกลูโคส (C₆H₁₂O₆) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$มวลโมเลกุลของแก๊สออกซิเจน (O₂) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$, $t$64$t$, $t$34$t$, $t$30$t$, $t$32$t$, 3, $t$O₂ = 32$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$มวลโมเลกุลของแก๊สออกซิเจน (O₂) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$มวลโมเลกุลของแก๊สไนโตรเจน (N₂) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$, $t$26$t$, $t$28$t$, $t$30$t$, $t$56$t$, 1, $t$N₂ = 28$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$มวลโมเลกุลของแก๊สไนโตรเจน (N₂) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$มวลโมเลกุลของแคลเซียมไฮดรอกไซด์ (Ca(OH)₂) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$, $t$72$t$, $t$64$t$, $t$76$t$, $t$74$t$, 3, $t$Ca(OH)₂ = 74$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$มวลโมเลกุลของแคลเซียมไฮดรอกไซด์ (Ca(OH)₂) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สมบัติธาตุตามหมู่และคาบ$t$, $t$ธาตุใดมีค่าอิเล็กโทรเนกาติวิตีสูงที่สุดในตารางธาตุ$t$, $t$ซีเซียม$t$, $t$ออกซิเจน$t$, $t$ฟลูออรีน$t$, $t$คลอรีน$t$, 2, $t$อยู่มุมขวาบน (ไม่นับแก๊สเฉื่อย)$t$
where not exists (select 1 from quiz_questions where topic = $t$สมบัติธาตุตามหมู่และคาบ$t$ and question = $t$ธาตุใดมีค่าอิเล็กโทรเนกาติวิตีสูงที่สุดในตารางธาตุ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สมบัติธาตุตามหมู่และคาบ$t$, $t$ในหมู่เดียวกัน เมื่อเลื่อนลงล่าง ขนาดอะตอมเปลี่ยนแปลงอย่างไร$t$, $t$ใหญ่ขึ้น$t$, $t$เล็กลง$t$, $t$เล็กลงแล้วใหญ่ขึ้น$t$, $t$ไม่เปลี่ยน$t$, 0, $t$จำนวนระดับพลังงานเพิ่มขึ้น$t$
where not exists (select 1 from quiz_questions where topic = $t$สมบัติธาตุตามหมู่และคาบ$t$ and question = $t$ในหมู่เดียวกัน เมื่อเลื่อนลงล่าง ขนาดอะตอมเปลี่ยนแปลงอย่างไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สมบัติธาตุตามหมู่และคาบ$t$, $t$ในคาบเดียวกัน เมื่อไปทางขวา ขนาดอะตอมโดยทั่วไปเป็นอย่างไร$t$, $t$ใหญ่ขึ้น$t$, $t$ใหญ่ขึ้นแล้วเล็กลง$t$, $t$ไม่เปลี่ยน$t$, $t$เล็กลง$t$, 3, $t$ประจุนิวเคลียสเพิ่มขึ้น ดึงอิเล็กตรอนแรงขึ้น$t$
where not exists (select 1 from quiz_questions where topic = $t$สมบัติธาตุตามหมู่และคาบ$t$ and question = $t$ในคาบเดียวกัน เมื่อไปทางขวา ขนาดอะตอมโดยทั่วไปเป็นอย่างไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สมบัติธาตุตามหมู่และคาบ$t$, $t$พลังงานไอออไนเซชันของธาตุในคาบเดียวกันเมื่อไปทางขวาโดยทั่วไปเป็นอย่างไร$t$, $t$คงที่$t$, $t$เป็นศูนย์$t$, $t$ลดลง$t$, $t$เพิ่มขึ้น$t$, 3, $t$อะตอมเล็กลง ดึงอิเล็กตรอนแน่นขึ้น$t$
where not exists (select 1 from quiz_questions where topic = $t$สมบัติธาตุตามหมู่และคาบ$t$ and question = $t$พลังงานไอออไนเซชันของธาตุในคาบเดียวกันเมื่อไปทางขวาโดยทั่วไปเป็นอย่างไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สมบัติธาตุตามหมู่และคาบ$t$, $t$ในโลหะแอลคาไล ธาตุใดว่องไวต่อปฏิกิริยากับน้ำมากที่สุดในตัวเลือก$t$, $t$โซเดียม$t$, $t$ไฮโดรเจน$t$, $t$โพแทสเซียม$t$, $t$ลิเทียม$t$, 2, $t$ความว่องไวเพิ่มขึ้นจากบนลงล่าง$t$
where not exists (select 1 from quiz_questions where topic = $t$สมบัติธาตุตามหมู่และคาบ$t$ and question = $t$ในโลหะแอลคาไล ธาตุใดว่องไวต่อปฏิกิริยากับน้ำมากที่สุดในตัวเลือก$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สมบัติธาตุตามหมู่และคาบ$t$, $t$ธาตุหมู่ 18 เรียกว่าอะไร$t$, $t$โลหะแอลคาไล$t$, $t$โลหะแทรนซิชัน$t$, $t$ฮาโลเจน$t$, $t$แก๊สเฉื่อย$t$, 3, $t$เสถียร มีเวเลนซ์อิเล็กตรอนครบ$t$
where not exists (select 1 from quiz_questions where topic = $t$สมบัติธาตุตามหมู่และคาบ$t$ and question = $t$ธาตุหมู่ 18 เรียกว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สมบัติธาตุตามหมู่และคาบ$t$, $t$ออกไซด์ของโลหะโดยทั่วไปมีสมบัติใด$t$, $t$เป็นกลางเสมอ$t$, $t$เป็นกรด$t$, $t$เป็นเบส$t$, $t$เป็นแก๊สสีน้ำเงิน$t$, 2, $t$ละลายน้ำได้สารละลายเบส เช่น Na₂O$t$
where not exists (select 1 from quiz_questions where topic = $t$สมบัติธาตุตามหมู่และคาบ$t$ and question = $t$ออกไซด์ของโลหะโดยทั่วไปมีสมบัติใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สมบัติธาตุตามหมู่และคาบ$t$, $t$ออกไซด์ของอโลหะโดยทั่วไปมีสมบัติใด$t$, $t$เป็นโลหะ$t$, $t$เป็นกรด$t$, $t$เป็นกลางเสมอ$t$, $t$เป็นเบส$t$, 1, $t$เช่น CO₂ SO₂ ละลายน้ำได้สารละลายกรด$t$
where not exists (select 1 from quiz_questions where topic = $t$สมบัติธาตุตามหมู่และคาบ$t$ and question = $t$ออกไซด์ของอโลหะโดยทั่วไปมีสมบัติใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สมบัติธาตุตามหมู่และคาบ$t$, $t$ข้อใดเป็นสมบัติของโลหะ$t$, $t$นำไฟฟ้าและนำความร้อนได้ดี$t$, $t$เป็นฉนวนความร้อน$t$, $t$เปราะแตกง่าย$t$, $t$ไม่มีความแวววาว$t$, 0, $t$โลหะมีอิเล็กตรอนอิสระ$t$
where not exists (select 1 from quiz_questions where topic = $t$สมบัติธาตุตามหมู่และคาบ$t$ and question = $t$ข้อใดเป็นสมบัติของโลหะ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สมบัติธาตุตามหมู่และคาบ$t$, $t$ธาตุกึ่งโลหะ (metalloid) ในข้อใด$t$, $t$คลอรีน$t$, $t$โซเดียม$t$, $t$ทองแดง$t$, $t$ซิลิคอน$t$, 3, $t$มีสมบัติกึ่งกลางระหว่างโลหะและอโลหะ$t$
where not exists (select 1 from quiz_questions where topic = $t$สมบัติธาตุตามหมู่และคาบ$t$ and question = $t$ธาตุกึ่งโลหะ (metalloid) ในข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สมบัติธาตุตามหมู่และคาบ$t$, $t$ธาตุแทรนซิชันมีสมบัติเด่นข้อใด$t$, $t$เป็นแก๊สทั้งหมด$t$, $t$สารประกอบมักมีสี$t$, $t$เป็นฉนวนไฟฟ้า$t$, $t$ไม่มีโลหะเลย$t$, 1, $t$เช่น Cu²⁺ สีฟ้า$t$
where not exists (select 1 from quiz_questions where topic = $t$สมบัติธาตุตามหมู่และคาบ$t$ and question = $t$ธาตุแทรนซิชันมีสมบัติเด่นข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$แก๊สและการทดสอบแก๊ส$t$, $t$แก๊สใดทำให้ไม้ขีดที่มีเพียงประกายไฟลุกขึ้นเป็นเปลวไฟได้$t$, $t$คาร์บอนไดออกไซด์$t$, $t$ฮีเลียม$t$, $t$ออกซิเจน$t$, $t$ไนโตรเจน$t$, 2, $t$ออกซิเจนช่วยให้ติดไฟ$t$
where not exists (select 1 from quiz_questions where topic = $t$แก๊สและการทดสอบแก๊ส$t$ and question = $t$แก๊สใดทำให้ไม้ขีดที่มีเพียงประกายไฟลุกขึ้นเป็นเปลวไฟได้$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$แก๊สและการทดสอบแก๊ส$t$, $t$แก๊สใดเมื่อจุดไฟให้เสียงปัง$t$, $t$คาร์บอนไดออกไซด์$t$, $t$ออกซิเจน$t$, $t$ไนโตรเจน$t$, $t$ไฮโดรเจน$t$, 3, $t$2H₂ + O₂ → 2H₂O$t$
where not exists (select 1 from quiz_questions where topic = $t$แก๊สและการทดสอบแก๊ส$t$ and question = $t$แก๊สใดเมื่อจุดไฟให้เสียงปัง$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$แก๊สและการทดสอบแก๊ส$t$, $t$แก๊สใดทำให้น้ำปูนใสขุ่น$t$, $t$ฮีเลียม$t$, $t$ออกซิเจน$t$, $t$คาร์บอนไดออกไซด์$t$, $t$ไฮโดรเจน$t$, 2, $t$เกิดตะกอนขาวของ CaCO₃$t$
where not exists (select 1 from quiz_questions where topic = $t$แก๊สและการทดสอบแก๊ส$t$ and question = $t$แก๊สใดทำให้น้ำปูนใสขุ่น$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$แก๊สและการทดสอบแก๊ส$t$, $t$แก๊สใดทำให้กระดาษลิตมัสแดงชื้นเปลี่ยนเป็นน้ำเงิน$t$, $t$ซัลเฟอร์ไดออกไซด์$t$, $t$คาร์บอนไดออกไซด์$t$, $t$คลอรีน$t$, $t$แอมโมเนีย$t$, 3, $t$แอมโมเนียเป็นเบส$t$
where not exists (select 1 from quiz_questions where topic = $t$แก๊สและการทดสอบแก๊ส$t$ and question = $t$แก๊สใดทำให้กระดาษลิตมัสแดงชื้นเปลี่ยนเป็นน้ำเงิน$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$แก๊สและการทดสอบแก๊ส$t$, $t$อากาศแห้งประกอบด้วยแก๊สชนิดใดมากที่สุด$t$, $t$ออกซิเจน (ประมาณ 78%)$t$, $t$อาร์กอน (ประมาณ 78%)$t$, $t$ไนโตรเจน (ประมาณ 78%)$t$, $t$คาร์บอนไดออกไซด์ (ประมาณ 78%)$t$, 2, $t$ออกซิเจนประมาณ 21%$t$
where not exists (select 1 from quiz_questions where topic = $t$แก๊สและการทดสอบแก๊ส$t$ and question = $t$อากาศแห้งประกอบด้วยแก๊สชนิดใดมากที่สุด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$แก๊สและการทดสอบแก๊ส$t$, $t$แก๊สใดเบากว่าอากาศและไม่ติดไฟ ใช้บรรจุบอลลูนอย่างปลอดภัย$t$, $t$ไฮโดรเจน$t$, $t$มีเทน$t$, $t$ฮีเลียม$t$, $t$คลอรีน$t$, 2, $t$ไฮโดรเจนเบาแต่ไวไฟ$t$
where not exists (select 1 from quiz_questions where topic = $t$แก๊สและการทดสอบแก๊ส$t$ and question = $t$แก๊สใดเบากว่าอากาศและไม่ติดไฟ ใช้บรรจุบอลลูนอย่างปลอดภัย$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$แก๊สและการทดสอบแก๊ส$t$, $t$แก๊สใดเป็นสาเหตุหลักของฝนกรดจากการเผาไหม้เชื้อเพลิงที่มีกำมะถัน$t$, $t$ไนโตรเจน$t$, $t$อาร์กอน$t$, $t$ซัลเฟอร์ไดออกไซด์$t$, $t$ฮีเลียม$t$, 2, $t$SO₂ ละลายน้ำเป็นกรด$t$
where not exists (select 1 from quiz_questions where topic = $t$แก๊สและการทดสอบแก๊ส$t$ and question = $t$แก๊สใดเป็นสาเหตุหลักของฝนกรดจากการเผาไหม้เชื้อเพลิงที่มีกำมะถัน$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$แก๊สและการทดสอบแก๊ส$t$, $t$แก๊สสีเหลืองอมเขียว กลิ่นฉุน ใช้ฆ่าเชื้อโรคในน้ำประปา คือแก๊สใด$t$, $t$คลอรีน$t$, $t$ไนโตรเจน$t$, $t$ออกซิเจน$t$, $t$ฟลูออรีน$t$, 0, $t$Cl₂$t$
where not exists (select 1 from quiz_questions where topic = $t$แก๊สและการทดสอบแก๊ส$t$ and question = $t$แก๊สสีเหลืองอมเขียว กลิ่นฉุน ใช้ฆ่าเชื้อโรคในน้ำประปา คือแก๊สใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$แก๊สและการทดสอบแก๊ส$t$, $t$แก๊สโอโซนมีสูตรใด$t$, $t$O$t$, $t$O₃$t$, $t$O₂$t$, $t$CO₂$t$, 1, $t$ชั้นโอโซนช่วยกรองรังสี UV$t$
where not exists (select 1 from quiz_questions where topic = $t$แก๊สและการทดสอบแก๊ส$t$ and question = $t$แก๊สโอโซนมีสูตรใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สมบัติธาตุตามหมู่และคาบ$t$, $t$อโลหะชนิดใดเป็นของเหลวที่อุณหภูมิห้อง$t$, $t$โบรมีน$t$, $t$คลอรีน$t$, $t$กำมะถัน$t$, $t$ไอโอดีน$t$, 0, $t$โบรมีนเป็นของเหลวสีแดงน้ำตาล (ปรอทเป็นโลหะเหลว)$t$
where not exists (select 1 from quiz_questions where topic = $t$สมบัติธาตุตามหมู่และคาบ$t$ and question = $t$อโลหะชนิดใดเป็นของเหลวที่อุณหภูมิห้อง$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สมบัติธาตุตามหมู่และคาบ$t$, $t$แก๊สเฉื่อยชนิดใดมีมวลอะตอมน้อยที่สุด$t$, $t$นีออน$t$, $t$ฮีเลียม$t$, $t$คริปทอน$t$, $t$อาร์กอน$t$, 1, $t$He มีเลขอะตอม 2$t$
where not exists (select 1 from quiz_questions where topic = $t$สมบัติธาตุตามหมู่และคาบ$t$ and question = $t$แก๊สเฉื่อยชนิดใดมีมวลอะตอมน้อยที่สุด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$ธาตุใดมีมากที่สุดในเปลือกโลกโดยมวล$t$, $t$อะลูมิเนียม$t$, $t$เหล็ก$t$, $t$ซิลิคอน$t$, $t$ออกซิเจน$t$, 3, $t$ประมาณ 46% โดยมวล รองลงมาคือซิลิคอน$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$ธาตุใดมีมากที่สุดในเปลือกโลกโดยมวล$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$ธาตุใดมีมากที่สุดในเอกภพ$t$, $t$คาร์บอน$t$, $t$ไฮโดรเจน$t$, $t$ออกซิเจน$t$, $t$ฮีเลียม$t$, 1, $t$H เป็นธาตุที่เบาที่สุดและพบมากที่สุดในดวงดาว$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$ธาตุใดมีมากที่สุดในเอกภพ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$ธาตุใดเป็นองค์ประกอบหลักของสารอินทรีย์ทุกชนิด$t$, $t$ซิลิคอน$t$, $t$ไนโตรเจน$t$, $t$คาร์บอน$t$, $t$กำมะถัน$t$, 2, $t$สารอินทรีย์คือสารประกอบของคาร์บอน$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$ธาตุใดเป็นองค์ประกอบหลักของสารอินทรีย์ทุกชนิด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$เวเลนซ์อิเล็กตรอนคือข้อใด$t$, $t$อิเล็กตรอนทั้งหมดของอะตอม$t$, $t$อิเล็กตรอนในระดับพลังงานนอกสุดที่ใช้สร้างพันธะ$t$, $t$อิเล็กตรอนในนิวเคลียส$t$, $t$โปรตอนที่อยู่นอกสุด$t$, 1, $t$จำนวนเวเลนซ์อิเล็กตรอนเท่ากับเลขหมู่ (หมู่หลัก 1, 2 และ 13-18 ใช้หลักหน่วย)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$เวเลนซ์อิเล็กตรอนคือข้อใด$t$);
-- 79: เพิ่มความยากด่านบอสเลื่อนแรงค์ (ต้องรันหลัง 69 และ 17)
--  1) บอสแรงขึ้น: HP ×1.3, พลังโจมตี ×1.5 (ปรับเฉพาะบอสที่ครูยังไม่เคยแก้ค่าเดิม)
--  2) ผู้เล่นเข้าด่านด้วย HP สูงสุด 85% ของปกติ
--  3) เวลาตอบคำถามในด่านบอส 15 วินาที (ปกติ 20)
--  4) ตอบผิด/หมดเวลาในด่านบอส → บอสฟื้น HP 5% ของ HP สูงสุด
-- รันซ้ำได้ ไม่ทับค่าที่ครูแก้เอง

update monsters m set hp = v.nh, atk = v.na
  from (values ('trial_silver',170,14,220,21), ('trial_gold',230,16,300,24), ('trial_platinum',310,18,400,27),
               ('trial_emerald',390,20,510,30), ('trial_diamond',490,22,640,33), ('trial_master',610,24,790,36),
               ('trial_grandmaster',770,27,1000,40), ('trial_challenger',960,30,1250,45)) v(k, oh, oa, nh, na)
 where m.key = v.k and m.hp = v.oh and m.atk = v.oa;

do $$
declare d text;
begin
  -- ผู้เล่น HP 85% ในด่านบอส
  select pg_get_functiondef('rank_trial_start(uuid)'::regprocedure) into d;
  if d not like '%0.85%' then
    d := replace(d, 'update battles set trial_rank = g, rewarded = false where id = bid;',
                    'update battles set trial_rank = g, rewarded = false, p_max = round(p_max * 0.85)::int, p_hp = round(p_max * 0.85)::int where id = bid;');
    if d not like '%0.85%' then raise exception 'แก้ rank_trial_start ไม่สำเร็จ (ต้องรัน 69 ก่อน)'; end if;
    execute d;
  end if;
  -- เวลา 17 วินาทีฝั่งเซิร์ฟเวอร์ (เผื่อเน็ตช้า) — ถ้าหาจุดแก้ไม่เจอจะข้าม (ฝั่งหน้าเว็บจำกัด 15 วินาทีอยู่แล้ว)
  select pg_get_functiondef('battle_answer(uuid,uuid,int)'::regprocedure) into d;
  if d !~ 'b\.trial_rank is not null then 17' and d ~ 'elapsed\s*<=\s*40' then
    execute regexp_replace(d, 'elapsed\s*<=\s*40', 'elapsed <= case when b.trial_rank is not null then 17 else 40 end');
  elsif d !~ 'b\.trial_rank is not null then 17' then
    raise notice 'ข้ามการแก้เวลาฝั่งเซิร์ฟเวอร์ (ไม่พบจุดแก้) — ไม่กระทบส่วนอื่น';
  end if;
end $$;

-- ตอบผิดในด่านบอส → บอสฟื้น 5% (ใช้ trigger แทนการแก้ฟังก์ชันตอบ จึงไม่ขึ้นกับหน้าตาของฟังก์ชัน)
create or replace function trg_trial_regen() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.trial_rank is not null and new.status = 'active' and old.cur_q is not null and new.cur_q is null
     and new.correct = old.correct and new.m_hp = old.m_hp then
    new.m_hp := least(new.m_max, new.m_hp + round(new.m_max * 0.05)::int);
  end if;
  return new;
end $$;
drop trigger if exists trial_regen on battles;
create trigger trial_regen before update on battles for each row execute function trg_trial_regen();
revoke execute on function trg_trial_regen() from public, anon, authenticated;
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
-- =====================================================================
-- 81: โบนัสโจมตี/ป้องกัน/HP จากอุปกรณ์สวมใส่ + การ์ดสวมใส่ 3 ช่อง + ระบบธาตุ 5 ธาตุ (รันซ้ำได้)
--  ธาตุ: fire 🔥ไฟ · water 💧น้ำ · plant 🌿พืช · thunder ⚡ไฟฟ้า · chem 🧪สารเคมี
--  วงจรแพ้ทาง: น้ำ→ไฟ→พืช→สารเคมี→ไฟฟ้า→น้ำ (ลูกศร = ชนะ) เช่น น้ำดับไฟ · ไฟเผาพืช · พืชดูดซับสารเคมี · สารเคมีกัดกร่อนวงจรไฟฟ้า · ไฟฟ้าแยกน้ำ (อิเล็กโทรลิซิส)
--  แต่ละชิ้นที่ใส่ (อุปกรณ์/การ์ด) ที่ธาตุชนะธาตุมอนสเตอร์ = โจมตีเพิ่ม · ธาตุแพ้มอนสเตอร์ = โดนแรงขึ้น (ชิ้นละเล็กน้อย มีเพดาน)
--  ปรับตัวเลขได้ที่ ⚙️ ตั้งค่า: gear_fx_pct, gear_cap_atk/def/hp, elem_adv_pct, elem_weak_pct, elem_cap_pct
--  ต้องรันหลัง 54 (การ์ด) · 66 (ไอเทม/อัปเกรด) · 69 (ด่านแรงค์) · 79
-- =====================================================================
alter table decor_items add column if not exists element text check (element in ('fire','water','plant','thunder','chem'));
alter table decor_items add column if not exists fx_atk int not null default 0;   -- โจมตี +%
alter table decor_items add column if not exists fx_def int not null default 0;   -- ลดดาเมจที่โดน %
alter table decor_items add column if not exists fx_hp  int not null default 0;   -- HP สูงสุด +%
alter table cards add column if not exists element text check (element in ('fire','water','plant','thunder','chem'));
alter table cards add column if not exists fx_kind text check (fx_kind in ('atk','def','hp'));
alter table cards add column if not exists fx_pct int not null default 0;
alter table monsters add column if not exists element text check (element in ('fire','water','plant','thunder','chem'));

create table if not exists student_card_slots (
  student_id uuid not null references students(id) on delete cascade,
  slot smallint not null check (slot between 1 and 3),
  card_id uuid not null references cards(id) on delete cascade,
  primary key (student_id, slot),
  unique (student_id, card_id)
);
alter table student_card_slots enable row level security;
drop policy if exists teacher_all on student_card_slots;
create policy teacher_all on student_card_slots for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on student_card_slots from anon;
grant select, insert, update, delete on student_card_slots to authenticated;

insert into app_settings (key, value) values ('gear_fx_pct', '100'), ('gear_cap_atk', '25'), ('gear_cap_def', '20'), ('gear_cap_hp', '30'),
  ('elem_adv_pct', '4'), ('elem_weak_pct', '4'), ('elem_cap_pct', '20') on conflict (key) do nothing;

-- ---------- ใส่ค่าเริ่มต้นให้ของเดิม (ทำครั้งเดียว ครูแก้ภายหลังได้ในหน้าครู) ----------
do $$
declare r int;
begin
  if exists (select 1 from app_settings where key = 'gear_fx_seeded') then return; end if;
  -- ธาตุ: จับคำในชื่อก่อน ที่เหลือกระจายด้วย md5 (คงที่)
  update decor_items set element = case
      when name ~ 'ไฟ(?!ฟ้า)|เพลิง|ลาวา|ร้อน|มังกร|ฟีนิกซ์|เตา' then 'fire'
      when name ~ 'น้ำ|ทะเล|คลื่น|ฟอง|หยด|เงือก|ปลา' then 'water'
      when name ~ 'พืช|ใบไม้|ดอก|ป่า|เห็ด|ต้นไม้|สวน|เขียว' then 'plant'
      when name ~ 'ฟ้า|ไฟฟ้า|สายฟ้า|ประจุ|อิเล็ก|แม่เหล็ก|พลาสมา' then 'thunder'
      when name ~ 'สาร|แล็บ|ขวด|ฟลาสก์|กรด|เบส|เคมี|ทดลอง|ผลึก|อะตอม|ตารางธาตุ' then 'chem'
      else (array['fire','water','plant','thunder','chem'])[1 + get_byte(decode(md5(name), 'hex'), 0) % 5] end
   where element is null and slot in ('hat', 'outfit', 'item', 'fx', 'pet');
  -- โบนัส: ระดับ R=1 SR=2 SSR=3 LEG=4 (N ไม่มี) · ไอเทมถือ/เอฟเฟค=โจมตี · หมวก/สัตว์เลี้ยง=ป้องกัน · ชุด=HP×2
  update decor_items d set
      fx_atk = case when slot in ('item', 'fx') then v.r else 0 end,
      fx_def = case when slot in ('hat', 'pet') then v.r else 0 end,
      fx_hp  = case when slot = 'outfit' then 2 * v.r else 0 end
    from (select id, case rarity when 'R' then 1 when 'SR' then 2 when 'SSR' then 3 when 'LEG' then 4 else 0 end r from decor_items) v
   where v.id = d.id and d.slot in ('hat', 'outfit', 'item', 'fx', 'pet') and d.fx_atk + d.fx_def + d.fx_hp = 0;
  -- การ์ด: ธาตุและชนิดโบนัสกระจายด้วย md5 · แรงตามระดับ N=1 R=2 SR=3 SSR=5 (HP ×2)
  update cards set element = (array['fire','water','plant','thunder','chem'])[1 + get_byte(decode(md5(name), 'hex'), 0) % 5],
      fx_kind = (array['atk','def','hp'])[1 + get_byte(decode(md5(name), 'hex'), 1) % 3]
   where element is null;
  update cards set fx_pct = (case rarity when 'N' then 1 when 'R' then 2 when 'SR' then 3 else 5 end) * (case when fx_kind = 'hp' then 2 else 1 end) where fx_pct = 0;
  -- มอนสเตอร์
  update monsters set element = case key
      when 'bubble' then 'water' when 'fog' then 'water' when 'frost' then 'water' when 'cryo' then 'water'
      when 'lava' then 'fire' when 'ash' then 'fire' when 'lemon' then 'plant' when 'geode' then 'plant'
      when 'rust' then 'thunder' when 'ozone' then 'thunder' when 'plasma' then 'thunder'
      when 'salt' then 'chem' when 'sludge' then 'chem' when 'toxic' then 'chem' when 'quartz' then 'chem'
      when 'trial_silver' then 'chem' when 'trial_gold' then 'fire' when 'trial_platinum' then 'water' when 'trial_emerald' then 'plant'
      when 'trial_diamond' then 'thunder' when 'trial_master' then 'chem' when 'trial_grandmaster' then 'fire' when 'trial_challenger' then 'water'
      else (array['fire','water','plant','thunder','chem'])[1 + get_byte(decode(md5(key), 'hex'), 0) % 5] end
   where element is null;
  insert into app_settings (key, value) values ('gear_fx_seeded', '1');
end $$;

-- ---------- ตัวช่วยธาตุ/โบนัส (ภายใน) ----------
create or replace function _elem_beats(a text, b text) returns boolean language sql immutable as $$
  select (a, b) in (('water', 'fire'), ('fire', 'plant'), ('plant', 'chem'), ('chem', 'thunder'), ('thunder', 'water')) $$;

-- รวมโบนัสของผู้เล่น: {atk, def, hp (%, หลังคูณ gear_fx_pct และจำกัดเพดาน), el: {ธาตุ: จำนวนชิ้น}, parts: [...]}
create or replace function _gear(p_sid uuid) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare sc numeric := _setting_int('gear_fx_pct', 100) / 100.0; a numeric := 0; d numeric := 0; h numeric := 0; el jsonb := '{}'::jsonb; parts jsonb := '[]'::jsonb; r record;
begin
  for r in
    select 'item' src, di.name, di.emoji, di.element el,
           di.fx_atk * (1 + 0.15 * (coalesce(sd.lvl, 1) - 1)) fa, di.fx_def * (1 + 0.15 * (coalesce(sd.lvl, 1) - 1)) fd, di.fx_hp * (1 + 0.15 * (coalesce(sd.lvl, 1) - 1)) fh
      from students s cross join lateral jsonb_each_text(s.decor) e
      join decor_items di on di.id = e.value::uuid and di.slot = e.key and di.slot in ('hat', 'outfit', 'item', 'fx', 'pet')
      left join student_decor sd on sd.student_id = s.id and sd.item_id = di.id
     where s.id = p_sid
    union all
    select 'card', c.name, c.emoji, c.element, (case when c.fx_kind = 'atk' then c.fx_pct else 0 end)::numeric, (case when c.fx_kind = 'def' then c.fx_pct else 0 end)::numeric,
           (case when c.fx_kind = 'hp' then c.fx_pct else 0 end)::numeric
      from student_card_slots sl join cards c on c.id = sl.card_id and c.active where sl.student_id = p_sid
  loop
    a := a + r.fa; d := d + r.fd; h := h + r.fh;
    if r.el is not null then el := jsonb_set(el, array[r.el], to_jsonb(coalesce((el->>r.el)::int, 0) + 1)); end if;
    parts := parts || jsonb_build_object('src', r.src, 'name', r.name, 'emoji', r.emoji, 'el', r.el);
  end loop;
  return jsonb_build_object('atk', least(_setting_int('gear_cap_atk', 25), round(a * sc, 1)), 'def', least(_setting_int('gear_cap_def', 20), round(d * sc, 1)),
    'hp', least(_setting_int('gear_cap_hp', 30), round(h * sc, 1)), 'el', el, 'parts', parts);
end $$;

-- ตัวคูณในศึกกับมอนสเตอร์ธาตุ m_el (null = ไม่มีธาตุ)
create or replace function _gear_battle(p_sid uuid, m_el text) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare g jsonb := _gear(p_sid); adv int := 0; weak int := 0; k text; n int; cap numeric := _setting_int('elem_cap_pct', 20);
begin
  if m_el is not null then
    for k, n in select key, value::int from jsonb_each_text(g->'el') loop
      if _elem_beats(k, m_el) then adv := adv + n; elsif _elem_beats(m_el, k) then weak := weak + n; end if;
    end loop;
  end if;
  return jsonb_build_object(
    'atk_mult', 1 + (g->>'atk')::numeric / 100 + least(cap, adv * _setting_int('elem_adv_pct', 4)) / 100,
    'in_mult', (1 - (g->>'def')::numeric / 100) * (1 + least(cap, weak * _setting_int('elem_weak_pct', 4)) / 100),
    'hp_mult', 1 + (g->>'hp')::numeric / 100, 'adv', adv, 'weak', weak);
end $$;
revoke execute on function _elem_beats(text, text), _gear(uuid), _gear_battle(uuid, text) from public, anon, authenticated;

-- ---------- RPC นักเรียน ----------
create or replace function gear_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); g jsonb := _gear(sid);
begin
  return json_build_object('gear', g,
    'slots', (select coalesce(json_agg(json_build_object('slot', sl.slot, 'card', sl.card_id) order by sl.slot), '[]'::json) from student_card_slots sl join cards c on c.id = sl.card_id and c.active where sl.student_id = sid),
    'cards', (select coalesce(json_object_agg(c.id, json_build_object('el', c.element, 'kind', c.fx_kind, 'pct', c.fx_pct)), '{}'::json) from cards c where c.active and (c.element is not null or c.fx_pct > 0)),
    'items', (select coalesce(json_object_agg(d.id, json_build_object('el', d.element, 'atk', d.fx_atk, 'def', d.fx_def, 'hp', d.fx_hp)), '{}'::json) from decor_items d where d.active and (d.element is not null or d.fx_atk + d.fx_def + d.fx_hp > 0)),
    'monsters', (select coalesce(json_object_agg(m.id, m.element), '{}'::json) from monsters m where m.element is not null),
    'cfg', json_build_object('adv', _setting_int('elem_adv_pct', 4), 'weak', _setting_int('elem_weak_pct', 4), 'cap', _setting_int('elem_cap_pct', 20)));
end $$;

-- ใส่/ถอดการ์ด (p_card = null → ถอด) · ต้องเป็นการ์ดที่มี · ใบเดียวกันใส่ได้ช่องเดียว
create or replace function card_equip(p_token uuid, p_slot int, p_card uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  if p_slot is null or p_slot not between 1 and 3 then raise exception 'ช่องการ์ดไม่ถูกต้อง'; end if;
  if p_card is null then
    delete from student_card_slots where student_id = sid and slot = p_slot;
  else
    if not exists (select 1 from student_cards where student_id = sid and card_id = p_card and qty > 0) then raise exception 'ยังไม่มีการ์ดใบนี้'; end if;
    if not exists (select 1 from cards where id = p_card and active) then raise exception 'การ์ดใบนี้ปิดใช้งาน'; end if;
    delete from student_card_slots where student_id = sid and (slot = p_slot or card_id = p_card);
    insert into student_card_slots (student_id, slot, card_id) values (sid, p_slot, p_card);
  end if;
  return gear_status(p_token);
end $$;
revoke execute on function gear_status(uuid), card_equip(uuid, int, uuid) from public;
grant execute on function gear_status(uuid), card_equip(uuid, int, uuid) to anon, authenticated;

-- ---------- ฟังก์ชันศึก (แทนที่ทั้งฟังก์ชัน — เพิ่มเฉพาะบรรทัดที่มีคอมเมนต์ “SQL 81”) ----------
CREATE OR REPLACE FUNCTION public.battle_start(p_token uuid, p_monster uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare sid uuid := _sid(p_token); m monsters%rowtype; used int; lim int := _setting_int('battle_rewards_per_day', 3); pm int; bid uuid; ar arenas%rowtype;
begin
  select * into m from monsters where id = p_monster and active and (trial_rank is null or current_setting('app.trial_ok', true) = '1');
  if not found then raise exception 'ไม่พบมอนสเตอร์'; end if;
  select * into ar from arenas where key = m.arena;
  if found and (not ar.active or ar.min_level > level_for((select exp from students where id = sid))) then raise exception 'ยังปลดล็อกสนามนี้ไม่ได้ (ต้องถึงเลเวล %)', ar.min_level; end if;
  update battles set status = 'fled', finished_at = now() where student_id = sid and status = 'active';
  select count(*) into used from battles where student_id = sid and play_date = today_th() and rewarded;
  pm := 80 + 6 * level_for((select exp from students where id = sid));
  pm := round(pm * (_gear_battle(sid, m.element)->>'hp_mult')::numeric)::int;   -- โบนัส HP จากอุปกรณ์/การ์ด (SQL 81)
  insert into battles (student_id, monster_id, p_hp, p_max, m_hp, m_max, rewarded)
  values (sid, m.id, pm, pm, m.hp, m.hp, used < lim) returning id into bid;
  return _battle_view(bid);
end $function$;

CREATE OR REPLACE FUNCTION public.battle_answer(p_token uuid, p_battle uuid, p_pick integer)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
  ok := p_pick is not null and p_pick = q.answer and elapsed <= case when b.trial_rank is not null then 17 else 40 end;
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
      mult := mult * (_gear_battle(sid, m.element)->>'atk_mult')::numeric;   -- โบนัสโจมตี + ธาตุได้เปรียบ (SQL 81)
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
end $function$;

CREATE OR REPLACE FUNCTION public.battle_defend(p_token uuid, p_battle uuid, p_hits integer)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  sid uuid := _sid(p_token); b battles%rowtype; m monsters%rowtype; n int; hits int := 0; dmg int; fin int; shield boolean := false;
  bf jsonb; el numeric; rw_exp int := 0; ev jsonb; heavy boolean; perfect boolean := false; ctr int := 0; hl int := 0; st json;
  intl int; mult numeric;
begin
  select * into b from battles where id = p_battle and student_id = sid for update;
  if not found or b.status <> 'active' or b.pend is null then raise exception 'ไม่มีการโจมตีให้ป้องกัน'; end if;
  select * into m from monsters where id = b.monster_id;
  n := (b.pend->>'n')::int; dmg := (b.pend->>'dmg')::int;
  heavy := (b.turn % 3 = 0);
  if heavy then dmg := round(dmg * 1.5)::int; end if;
  bf := b.buffs;
  if b.guard then
    el := extract(epoch from now()) - (b.pend->>'at')::numeric;
    hits := greatest(0, least(coalesce(p_hits, 0), n));
    if el < 0.25 * hits then hits := 0; end if;            -- เร็วเกินคนกดไม่ทัน = ไม่นับ
    perfect := n > 0 and hits = n;
    fin := round(dmg * (1 - hits::numeric / n))::int;
  else
    fin := round(dmg * 0.7)::int;
  end if;
  if coalesce((bf->>'shield')::int, 0) > 0 then
    shield := true; fin := round(fin * 0.5)::int; bf := jsonb_set(bf, '{shield}', to_jsonb((bf->>'shield')::int - 1));
  end if;
  fin := round(fin * (_gear_battle(sid, m.element)->>'in_mult')::numeric)::int;   -- ป้องกัน + ธาตุแพ้ทาง (SQL 81)
  fin := greatest(case when perfect then 0 else 1 end, fin);
  if coalesce((bf->>'weak')::int, 0) > 0 then bf := jsonb_set(bf, '{weak}', to_jsonb((bf->>'weak')::int - 1)); end if;
  b.p_hp := greatest(0, b.p_hp - fin);
  -- ปัดป้องสมบูรณ์: สวนกลับ + ฟื้น HP (สวนกลับไม่ฆ่า เหลือ HP อย่างน้อย 1)
  if perfect and b.p_hp > 0 then
    st := _stats(sid); intl := coalesce((st->'int'->>'total')::int, 0);
    mult := 1 + coalesce((st->'effects'->>'boss_pct')::int, 0) / 100.0;
    if coalesce((bf->>'weak')::int, 0) > 0 then mult := mult * 1.4; end if;
    mult := mult * (_gear_battle(sid, m.element)->>'atk_mult')::numeric;
    ctr := greatest(1, round((20 + intl / 2.0) * mult)::int);
    ctr := least(ctr, greatest(0, b.m_hp - 1));
    b.m_hp := b.m_hp - ctr;
    hl := least(b.p_max - b.p_hp, round(b.p_max * 0.08)::int); b.p_hp := b.p_hp + hl;
  end if;
  ev := jsonb_build_object('hits', hits, 'n', n, 'taken', fin, 'raw', dmg, 'shield', shield, 'guard', b.guard, 'heavy', heavy,
                           'perfect', perfect, 'counter', ctr, 'heal', hl);
  if b.p_hp <= 0 then
    if b.rewarded then
      rw_exp := least(6, b.correct * 2);
      if rw_exp > 0 then perform award(sid, rw_exp, 0, 'สู้มอนสเตอร์: ' || m.name || ' (ให้กำลังใจ)', 'game:battle:' || b.id); end if;
    end if;
    update battles set status = 'lost', finished_at = now(), p_hp = 0, pend = null, guard = false, buffs = bf, exp = rw_exp, turn = b.turn + 1 where id = b.id;
  else
    update battles set p_hp = b.p_hp, m_hp = b.m_hp, pend = null, guard = false, buffs = bf, turn = b.turn + 1 where id = b.id;
  end if;
  return json_build_object('event', ev, 'state', _battle_view(b.id));
end $function$;
-- =====================================================================
-- 82: ไอคอนพิกเซลให้ยา/ของใช้/เอฟเฟกต์ + ไอเทมสวมใส่ธาตุชุดใหม่ (ดาบ 5 + หมวก 5) (รันซ้ำได้)
--  ต้องรันหลัง 81 · ไฟล์ภาพอยู่ที่ assets/px/ (ไอคอนจาก Raven Fantasy Icons — ดูเครดิตใน assets/CREDITS.md)
--  ใส่ภาพเฉพาะรายการที่ครูยังไม่เคยใส่ภาพเอง (image เป็นค่าว่าง)
-- =====================================================================
update consumables c set image = v.img
  from (values ('p_exp', 'assets/px/p_exp.png'), ('p_coin', 'assets/px/p_coin.png'), ('p_luck', 'assets/px/p_luck.png'), ('p_str', 'assets/px/p_str.png'),
               ('p_int', 'assets/px/p_int.png'), ('p_heal', 'assets/px/p_heal.png'), ('scroll', 'assets/px/scroll.png'), ('t_reset', 'assets/px/t_reset.png')) v(k, img)
 where c.key = v.k and c.image is null;

update decor_items d set image = v.img
  from (values ('ออร่าเปลวไฟ', 'assets/px/fx_flame.png'), ('หิมะน้ำแข็ง', 'assets/px/fx_ice.png'), ('สายฟ้าฟาด', 'assets/px/fx_bolt.png'),
               ('ประกายดาว', 'assets/px/fx_spark.png'), ('ฟองสารเคมี', 'assets/px/fx_bubble.png'), ('ดาวโคจร', 'assets/px/fx_orbit.png')) v(n, img)
 where d.slot = 'fx' and d.name = v.n and d.image is null;

-- ไอเทมใหม่: ดาบ/คทา (ช่องไอเทมถือ = โจมตี) และหมวก (= ลดดาเมจ) อย่างละ 1 ต่อธาตุ
insert into decor_items (slot, key, name, emoji, rarity, price, sort, image, element, fx_atk, fx_def, fx_hp)
select v.slot, 'img', v.name, v.emoji, v.rarity, v.price, v.sort, v.img, v.el, v.atk, v.def, 0
  from (values
    ('item', 'ดาบเพลิงอัคนี',        '🗡️', 'SR', 480, 41, 'assets/px/sw_fire.png',    'fire',    3, 0),
    ('item', 'ดาบคลื่นน้ำแข็ง',      '🗡️', 'R',  240, 42, 'assets/px/sw_water.png',   'water',   2, 0),
    ('item', 'ใบมีดมรกตพงไพร',      '🗡️', 'R',  240, 43, 'assets/px/sw_plant.png',   'plant',   2, 0),
    ('item', 'ดาบสายฟ้าทองคำ',       '🗡️', 'SR', 480, 44, 'assets/px/sw_thunder.png', 'thunder', 3, 0),
    ('item', 'คทาดาบสารเคมีม่วง',    '🗡️', 'SR', 480, 45, 'assets/px/sw_chem.png',    'chem',    3, 0),
    ('hat',  'หมวกจอมเวทเพลิง',      '🎩', 'R',  200, 41, 'assets/px/hat_fire.png',   'fire',    0, 2),
    ('hat',  'หมวกจอมเวทสายน้ำ',     '🎩', 'R',  200, 42, 'assets/px/hat_water.png',  'water',   0, 2),
    ('hat',  'หมวกจอมเวทพงไพร',      '🎩', 'R',  200, 43, 'assets/px/hat_plant.png',  'plant',   0, 2),
    ('hat',  'หมวกเกราะสายฟ้า',      '⛑️', 'SR', 420, 44, 'assets/px/hat_thunder.png', 'thunder', 0, 3),
    ('hat',  'หมวกจอมเวทสารเคมี',    '🎩', 'R',  200, 45, 'assets/px/hat_chem.png',   'chem',    0, 2)
  ) v(slot, name, emoji, rarity, price, sort, img, el, atk, def)
 where not exists (select 1 from decor_items d where d.name = v.name and d.slot = v.slot);
-- =====================================================================
-- 83: กดอิโมจิให้ตัวละครเพื่อนในห้อง (❤️ 👍 🔥 😄 ⭐ 👏) (รันซ้ำได้)
--  - ดูตัวละครเพื่อน (char_view) · กดอิโมจิ (char_react) · วันละ 1 อิโมจิต่อเพื่อน 1 คน (กดใหม่ = เปลี่ยนอิโมจิ, กดซ้ำ = ยกเลิก)
--  - จำกัดจำนวนเพื่อนที่กดให้ได้ต่อวัน (ตั้งค่า react_daily_max, ค่าเริ่มต้น 15) · ไม่มีเหรียญ/คะแนน
--  - เจ้าของเห็นยอดรวมอิโมจิที่ได้รับที่หน้าตัวละครของตัวเอง
-- =====================================================================
create table if not exists char_reactions (
  from_id uuid not null references students(id) on delete cascade,
  to_id uuid not null references students(id) on delete cascade,
  day date not null,
  emoji text not null check (emoji in ('❤️', '👍', '🔥', '😄', '⭐', '👏')),
  created_at timestamptz not null default now(),
  primary key (from_id, to_id, day),
  check (from_id <> to_id)
);
create index if not exists char_reactions_to on char_reactions (to_id);
alter table char_reactions enable row level security;
drop policy if exists teacher_all on char_reactions;
create policy teacher_all on char_reactions for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on char_reactions from anon;
grant select, insert, update, delete on char_reactions to authenticated;
insert into app_settings (key, value) values ('react_daily_max', '15') on conflict (key) do nothing;

create or replace function _char_view(p_sid uuid, p_target uuid) returns json
language plpgsql stable security definer set search_path = public as $$
declare t students%rowtype; today date := today_th();
begin
  select * into t from students where id = p_target;
  return json_build_object('no', t.no, 'name', t.name, 'avatar', t.avatar, 'char_class', t.char_class, 'level', level_for(t.exp),
    'rank_info', _rank_info_s(t.id, t.exp), 'decor', _decor_of(t.id), 'is_me', t.id = p_sid,
    'totals', coalesce((select json_object_agg(emoji, n) from (select emoji, count(*) n from char_reactions where to_id = t.id group by emoji) x), '{}'::json),
    'total', (select count(*) from char_reactions where to_id = t.id),
    'mine', (select emoji from char_reactions where from_id = p_sid and to_id = t.id and day = today),
    'sent_today', (select count(*) from char_reactions where from_id = p_sid and day = today),
    'limit', _setting_int('react_daily_max', 15));
end $$;

create or replace function char_view(p_token uuid, p_no int default null) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); tid uuid;
begin
  if p_no is null then tid := sid;
  else select o.id into tid from students o where o.no = p_no and o.class_id = (select class_id from students where id = sid);
    if tid is null then raise exception 'ไม่พบเพื่อนคนนี้ในห้อง'; end if;
  end if;
  return _char_view(sid, tid);
end $$;

create or replace function char_react(p_token uuid, p_no int, p_emoji text) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); tid uuid; today date := today_th(); cur text;
begin
  select o.id into tid from students o where o.no = p_no and o.class_id = (select class_id from students where id = sid);
  if tid is null then raise exception 'ไม่พบเพื่อนคนนี้ในห้อง'; end if;
  if tid = sid then raise exception 'กดให้ตัวละครของตัวเองไม่ได้'; end if;
  if p_emoji is not null and p_emoji not in ('❤️', '👍', '🔥', '😄', '⭐', '👏') then raise exception 'อิโมจินี้ไม่รองรับ'; end if;
  select emoji into cur from char_reactions where from_id = sid and to_id = tid and day = today;
  if p_emoji is null or p_emoji = cur then
    delete from char_reactions where from_id = sid and to_id = tid and day = today;
  elsif cur is not null then
    update char_reactions set emoji = p_emoji, created_at = now() where from_id = sid and to_id = tid and day = today;
  else
    if (select count(*) from char_reactions where from_id = sid and day = today) >= _setting_int('react_daily_max', 15) then
      raise exception 'วันนี้กดให้เพื่อนครบ % คนแล้ว พรุ่งนี้มาใหม่นะ', _setting_int('react_daily_max', 15);
    end if;
    insert into char_reactions (from_id, to_id, day, emoji) values (sid, tid, today, p_emoji);
  end if;
  return _char_view(sid, tid);
end $$;

revoke execute on function _char_view(uuid, uuid) from public, anon, authenticated;
revoke execute on function char_view(uuid, int), char_react(uuid, int, text) from public;
grant execute on function char_view(uuid, int), char_react(uuid, int, text) to anon, authenticated;
-- =====================================================================
-- 84: Achievement ใหม่ 29 รายการ (ส่งงาน · สอบ · ล่ามอนสเตอร์ · เคมีรัน · การ์ด · ไอเทม · ใช้ไอเทม) + ใส่ภาพตราให้ทุกอัน (รันซ้ำได้)
--  - เงื่อนไขใหม่ใน student_metric: submissions_total, exam_taken/exam_high/exam_full, monster_wins/monster_kinds/trial_passed,
--    run_plays/run_best, cards_owned/cards_ssr/card_sets, gear_owned/gear_rare/gear_maxlv, items_used
--  - นับการใช้ไอเทมตั้งแต่รันไฟล์นี้เป็นต้นไป (ตาราง item_use_log) · ผู้ที่ทำเงื่อนไขได้อยู่แล้วจะได้ตราตอนมีกิจกรรมครั้งถัดไป
--  - ใส่ภาพ assets/medals/*.png ให้เฉพาะตราที่ยังไม่มีภาพ
-- =====================================================================
create table if not exists item_use_log (
  id bigserial primary key,
  student_id uuid not null references students(id) on delete cascade,
  item_id uuid not null,
  used_at timestamptz not null default now()
);
create index if not exists item_use_log_st on item_use_log (student_id);
alter table item_use_log enable row level security;
drop policy if exists teacher_all on item_use_log;
create policy teacher_all on item_use_log for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on item_use_log from anon;
grant select, insert, update, delete on item_use_log to authenticated;
grant usage, select on sequence item_use_log_id_seq to authenticated;

alter table achievements drop constraint if exists achievements_metric_check;
alter table achievements add constraint achievements_metric_check check (metric in (
  'attendance_count', 'present_count', 'attendance_streak', 'ontime_submissions', 'total_exp', 'level', 'gacha_pulls', 'quests_done',
  'kb_plays', 'kb_cleared', 'kb_wins', 'kb_fast',
  'card_sets', 'cards_owned', 'cards_ssr', 'exam_full', 'exam_high', 'exam_taken', 'gear_maxlv', 'gear_owned', 'gear_rare', 'items_used', 'monster_kinds', 'monster_wins', 'run_best', 'run_plays', 'submissions_total', 'trial_passed'));

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
    when 'kb_plays' then
      select count(*) into n from game_plays where student_id = p_student and game = 'kb' and (exp > 0 or coins > 0);
    when 'kb_cleared' then
      select coalesce(max(case when score = 100 then 8 else score / 12 end), 0) into n from game_plays where student_id = p_student and game = 'kb' and (exp > 0 or coins > 0);
    when 'kb_wins' then
      select count(*) into n from game_plays where student_id = p_student and game = 'kb' and score = 100 and (exp > 0 or coins > 0);
    when 'kb_fast' then
      select count(*) into n from game_plays where student_id = p_student and game = 'kb' and score = 100 and (exp > 0 or coins > 0) and kb_secs is not null and kb_secs <= 300;
    when 'submissions_total' then
      select count(*) into n from ch_submissions where student_id = p_student and status in ('submitted', 'late');
    when 'exam_taken' then
      select count(*) into n from exam_attempts where student_id = p_student and submitted_at is not null;
    when 'exam_high' then
      select count(*) into n from exam_attempts where student_id = p_student and submitted_at is not null and total > 0 and score is not null and score / total >= 0.8;
    when 'exam_full' then
      select count(*) into n from exam_attempts where student_id = p_student and submitted_at is not null and total > 0 and score is not null and score >= total;
    when 'monster_wins' then
      select count(*) into n from battles where student_id = p_student and status = 'won';
    when 'monster_kinds' then
      select count(distinct monster_id) into n from battles where student_id = p_student and status = 'won';
    when 'trial_passed' then
      select count(*) into n from rank_trial_pass where student_id = p_student;
    when 'run_plays' then
      select count(*) into n from game_plays where student_id = p_student and game = 'run';
    when 'run_best' then
      select coalesce(max(score), 0) into n from game_plays where student_id = p_student and game = 'run';
    when 'cards_owned' then
      select count(*) into n from student_cards where student_id = p_student and qty > 0;
    when 'cards_ssr' then
      select count(*) into n from student_cards sc join cards c on c.id = sc.card_id where sc.student_id = p_student and sc.qty > 0 and c.rarity = 'SSR';
    when 'card_sets' then
      select count(*) into n from student_set_claims where student_id = p_student;
    when 'gear_owned' then
      select count(*) into n from student_decor where student_id = p_student;
    when 'gear_rare' then
      select count(*) into n from student_decor sd join decor_items d on d.id = sd.item_id where sd.student_id = p_student and d.rarity in ('SR', 'SSR', 'LEG');
    when 'gear_maxlv' then
      select coalesce(max(lvl), 0) into n from student_decor where student_id = p_student;
    when 'items_used' then
      select count(*) into n from item_use_log where student_id = p_student;
    else n := 0;
  end case;
  return coalesce(n, 0);
end $$;
revoke execute on function student_metric(uuid, text) from public, anon, authenticated;

-- บันทึกการใช้ไอเทม: เมื่อจำนวนไอเทมสิ้นเปลืองลดลง 1 หน่วย = ใช้ 1 ครั้ง
create or replace function trg_item_use_log() returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.qty < old.qty then insert into item_use_log (student_id, item_id) select new.student_id, new.item_id from generate_series(1, old.qty - new.qty); end if;
  return new;
end $$;
drop trigger if exists item_use_log_t on student_items;
create trigger item_use_log_t after update of qty on student_items for each row when (new.qty < old.qty) execute function trg_item_use_log();

-- ตรวจ achievement ทันทีเมื่อมีกิจกรรมที่เกี่ยวข้อง
create or replace function trg_ach_student() returns trigger language plpgsql security definer set search_path = public as $$
begin perform check_achievements(new.student_id); return new; end $$;
revoke execute on function trg_item_use_log(), trg_ach_student() from public, anon, authenticated;
drop trigger if exists ach_chk on ch_submissions;   create trigger ach_chk after insert or update on ch_submissions for each row execute function trg_ach_student();
drop trigger if exists ach_chk on exam_attempts;    create trigger ach_chk after update on exam_attempts for each row when (new.submitted_at is not null) execute function trg_ach_student();
drop trigger if exists ach_chk on battles;          create trigger ach_chk after update on battles for each row when (new.status = 'won') execute function trg_ach_student();
drop trigger if exists ach_chk on rank_trial_pass;  create trigger ach_chk after insert on rank_trial_pass for each row execute function trg_ach_student();
drop trigger if exists ach_chk on game_plays;       create trigger ach_chk after insert on game_plays for each row execute function trg_ach_student();
drop trigger if exists ach_chk on student_cards;    create trigger ach_chk after insert or update on student_cards for each row execute function trg_ach_student();
drop trigger if exists ach_chk on student_set_claims; create trigger ach_chk after insert on student_set_claims for each row execute function trg_ach_student();
drop trigger if exists ach_chk on student_decor;    create trigger ach_chk after insert or update on student_decor for each row execute function trg_ach_student();
drop trigger if exists ach_chk on item_use_log;     create trigger ach_chk after insert on item_use_log for each row execute function trg_ach_student();

-- รายการ achievement ใหม่
insert into achievements (key, name, description, emoji, metric, threshold, reward_exp, reward_coins)
select v.* from (values
    ('sub_1', 'ส่งงานชิ้นแรก', 'ส่งงานครบ 1 ชิ้น (ตรงเวลาหรือสาย)', '📜', 'submissions_total', 1, 15, 5),
    ('sub_25', 'นักส่งงานตัวยง', 'ส่งงานสะสม 25 ชิ้น', '📨', 'submissions_total', 25, 60, 25),
    ('sub_50', 'ราชาแห่งการส่งงาน', 'ส่งงานสะสม 50 ชิ้น', '👑', 'submissions_total', 50, 120, 50),
    ('exam_1', 'นักสอบหน้าใหม่', 'ส่งข้อสอบออนไลน์ครั้งแรก', '📝', 'exam_taken', 1, 20, 10),
    ('exam_5', 'สนามสอบคุ้นเคย', 'ส่งข้อสอบออนไลน์ 5 ครั้ง', '📘', 'exam_taken', 5, 60, 25),
    ('exam_high_3', 'คะแนนสูงติดปีก', 'ได้คะแนนสอบตั้งแต่ 80% ขึ้นไป 3 ครั้ง', '🌟', 'exam_high', 3, 80, 30),
    ('exam_full_1', 'เต็มร้อย!', 'ทำข้อสอบได้คะแนนเต็มหนึ่งครั้ง', '🏆', 'exam_full', 1, 100, 50),
    ('mon_1', 'นักล่ามือใหม่', 'ชนะมอนสเตอร์ครั้งแรก', '🗡️', 'monster_wins', 1, 15, 5),
    ('mon_10', 'นักล่าตัวจริง', 'ชนะมอนสเตอร์ 10 ครั้ง', '⚔️', 'monster_wins', 10, 60, 25),
    ('mon_30', 'เจ้าแห่งสนามต่อสู้', 'ชนะมอนสเตอร์ 30 ครั้ง', '💀', 'monster_wins', 30, 150, 60),
    ('mon_kinds_8', 'นักสำรวจมอนสเตอร์', 'เคยปราบมอนสเตอร์ครบ 8 ชนิดที่ต่างกัน', '🧭', 'monster_kinds', 8, 100, 40),
    ('trial_1', 'ผ่านด่านแรงค์', 'ชนะบอสเลื่อนแรงค์ครั้งแรก', '🛡️', 'trial_passed', 1, 80, 30),
    ('trial_4', 'ผู้พิชิตด่านแรงค์', 'ชนะบอสเลื่อนแรงค์ 4 ด่าน', '🏰', 'trial_passed', 4, 200, 80),
    ('run_1', 'ออกสตาร์ท', 'เล่นเคมีรันครั้งแรก', '🏃', 'run_plays', 1, 10, 5),
    ('run_20', 'นักวิ่งเคมี', 'เล่นเคมีรัน 20 ครั้ง', '👟', 'run_plays', 20, 60, 25),
    ('run_800', 'ทะลุแปดร้อย', 'ทำคะแนนเคมีรันได้ 800 ขึ้นไป', '⚡', 'run_best', 800, 50, 20),
    ('run_2000', 'นักวิ่งตำนาน', 'ทำคะแนนเคมีรันได้ 2,000 ขึ้นไป', '🔥', 'run_best', 2000, 150, 60),
    ('card_5', 'นักสะสมมือใหม่', 'สะสมการ์ดได้ 5 ใบ (ไม่ซ้ำ)', '🃏', 'cards_owned', 5, 20, 10),
    ('card_20', 'สมุดการ์ดเริ่มหนา', 'สะสมการ์ดได้ 20 ใบ (ไม่ซ้ำ)', '📖', 'cards_owned', 20, 80, 30),
    ('card_40', 'ราชาการ์ด', 'สะสมการ์ดได้ 40 ใบ (ไม่ซ้ำ)', '💎', 'cards_owned', 40, 200, 80),
    ('card_set_1', 'ครบชุดแรก', 'สะสมการ์ดครบ 1 ชุดและรับรางวัลแล้ว', '🧩', 'card_sets', 1, 60, 30),
    ('card_ssr_1', 'การ์ดตำนาน', 'มีการ์ดระดับ SSR อย่างน้อย 1 ใบ', '✨', 'cards_ssr', 1, 80, 30),
    ('gear_5', 'นักสะสมอุปกรณ์', 'มีไอเทมแต่งตัว/อุปกรณ์ 5 ชิ้น', '🎒', 'gear_owned', 5, 30, 15),
    ('gear_20', 'ตู้โชว์เต็มห้อง', 'มีไอเทมแต่งตัว/อุปกรณ์ 20 ชิ้น', '🧰', 'gear_owned', 20, 100, 40),
    ('gear_rare_3', 'ของหายากเพียบ', 'มีไอเทมระดับ SR ขึ้นไป 3 ชิ้น', '💍', 'gear_rare', 3, 80, 30),
    ('gear_lv3', 'ช่างตีบวก', 'อัปเกรดอุปกรณ์ชิ้นใดชิ้นหนึ่งถึงเลเวล 3', '🔨', 'gear_maxlv', 3, 100, 40),
    ('use_1', 'ลองใช้ไอเทม', 'ใช้ไอเทมสิ้นเปลือง (ยา/ม้วน/ตั๋ว) ครั้งแรก', '🧪', 'items_used', 1, 10, 5),
    ('use_10', 'นักใช้ยา', 'ใช้ไอเทมสิ้นเปลืองสะสม 10 ครั้ง', '⚗️', 'items_used', 10, 50, 20),
    ('use_30', 'ปรมาจารย์ยา', 'ใช้ไอเทมสิ้นเปลืองสะสม 30 ครั้ง', '🧙', 'items_used', 30, 120, 50)
) v(key, name, description, emoji, metric, threshold, reward_exp, reward_coins)
on conflict (key) do nothing;

update achievements a set image = v.img
  from (values
    ('sub_1', 'assets/medals/sub_1.png'),
    ('sub_25', 'assets/medals/sub_25.png'),
    ('sub_50', 'assets/medals/sub_50.png'),
    ('exam_1', 'assets/medals/exam_1.png'),
    ('exam_5', 'assets/medals/exam_5.png'),
    ('exam_high_3', 'assets/medals/exam_high_3.png'),
    ('exam_full_1', 'assets/medals/exam_full_1.png'),
    ('mon_1', 'assets/medals/mon_1.png'),
    ('mon_10', 'assets/medals/mon_10.png'),
    ('mon_30', 'assets/medals/mon_30.png'),
    ('mon_kinds_8', 'assets/medals/mon_kinds_8.png'),
    ('trial_1', 'assets/medals/trial_1.png'),
    ('trial_4', 'assets/medals/trial_4.png'),
    ('run_1', 'assets/medals/run_1.png'),
    ('run_20', 'assets/medals/run_20.png'),
    ('run_800', 'assets/medals/run_800.png'),
    ('run_2000', 'assets/medals/run_2000.png'),
    ('card_5', 'assets/medals/card_5.png'),
    ('card_20', 'assets/medals/card_20.png'),
    ('card_40', 'assets/medals/card_40.png'),
    ('card_set_1', 'assets/medals/card_set_1.png'),
    ('card_ssr_1', 'assets/medals/card_ssr_1.png'),
    ('gear_5', 'assets/medals/gear_5.png'),
    ('gear_20', 'assets/medals/gear_20.png'),
    ('gear_rare_3', 'assets/medals/gear_rare_3.png'),
    ('gear_lv3', 'assets/medals/gear_lv3.png'),
    ('use_1', 'assets/medals/use_1.png'),
    ('use_10', 'assets/medals/use_10.png'),
    ('use_30', 'assets/medals/use_30.png'),
    ('kb_round4', 'assets/medals/kb_round4.png'),
    ('kb_round7', 'assets/medals/kb_round7.png'),
    ('kb_fast', 'assets/medals/kb_fast.png'),
    ('kb_play_1', 'assets/medals/kb_play_1.png'),
    ('kb_win_1', 'assets/medals/kb_win_1.png'),
    ('kb_win_3', 'assets/medals/kb_win_3.png'),
    ('kb_win_10', 'assets/medals/kb_win_10.png')
  ) v(k, img)
 where a.key = v.k and a.image is null;
-- =====================================================================
-- 85: อีเว้นท์เช็คอินรับของรางวัล (ครูเปิด-ปิดเป็นช่วงเวลา · นักเรียนทุกคนกดรับได้คนละ 1 ครั้งต่ออีเว้นท์) · รันซ้ำได้
--  รางวัล: EXP / เหรียญ / ตั๋วกาชาฟรี / ไอเทมตกแต่ง 1 ชิ้น / การ์ด 1 ใบ (ไม่บังคับ แต่ต้องมีอย่างน้อย 1 อย่าง)
-- =====================================================================
create table if not exists checkin_events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  message text not null default '',
  starts_at timestamptz not null default now(),
  ends_at timestamptz not null,
  exp int not null default 0 check (exp >= 0),
  coins int not null default 0 check (coins >= 0),
  pulls int not null default 0 check (pulls >= 0),
  decor_id uuid references decor_items(id) on delete set null,
  card_id uuid references cards(id) on delete set null,
  closed boolean not null default false,
  created_at timestamptz not null default now()
);
create table if not exists checkin_claims (
  event_id uuid not null references checkin_events(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  claimed_at timestamptz not null default now(),
  primary key (event_id, student_id)
);
create index if not exists checkin_claims_st on checkin_claims (student_id);
alter table checkin_events enable row level security;
alter table checkin_claims enable row level security;
drop policy if exists teacher_all on checkin_events;
create policy teacher_all on checkin_events for all to authenticated using (is_teacher()) with check (is_teacher());
drop policy if exists teacher_all on checkin_claims;
create policy teacher_all on checkin_claims for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on checkin_events, checkin_claims from anon;

-- ครู: เปิดอีเว้นท์ทันที p_hours ชั่วโมง
create or replace function admin_checkin_open(p_title text, p_message text, p_hours numeric, p_exp int default 0, p_coins int default 0,
                                              p_pulls int default 0, p_decor uuid default null, p_card uuid default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare id uuid;
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  if btrim(coalesce(p_title, '')) = '' then raise exception 'ใส่ชื่ออีเว้นท์ก่อน'; end if;
  if coalesce(p_hours, 0) <= 0 or p_hours > 24 * 60 then raise exception 'ระยะเวลาต้องอยู่ระหว่าง 0–1440 ชั่วโมง'; end if;
  if coalesce(p_exp, 0) < 0 or coalesce(p_coins, 0) < 0 or coalesce(p_pulls, 0) < 0 or p_exp > 10000 or p_coins > 10000 or p_pulls > 50 then
    raise exception 'จำนวนรางวัลไม่ถูกต้อง (EXP/เหรียญ ≤ 10000 · ตั๋ว ≤ 50)'; end if;
  if coalesce(p_exp, 0) = 0 and coalesce(p_coins, 0) = 0 and coalesce(p_pulls, 0) = 0 and p_decor is null and p_card is null then
    raise exception 'ยังไม่ได้เลือกรางวัล'; end if;
  insert into checkin_events (title, message, ends_at, exp, coins, pulls, decor_id, card_id)
  values (left(btrim(p_title), 80), left(btrim(coalesce(p_message, '')), 200), now() + make_interval(secs => (p_hours * 3600)::int),
          coalesce(p_exp, 0), coalesce(p_coins, 0), coalesce(p_pulls, 0), p_decor, p_card) returning checkin_events.id into id;
  return id;
end $$;
revoke execute on function admin_checkin_open(text, text, numeric, int, int, int, uuid, uuid) from public, anon;
grant execute on function admin_checkin_open(text, text, numeric, int, int, int, uuid, uuid) to authenticated;

-- นักเรียน: อีเว้นท์ที่เปิดอยู่ตอนนี้ + สถานะว่ารับแล้วหรือยัง
create or replace function checkin_list(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  return coalesce((select json_agg(json_build_object('id', e.id, 'title', e.title, 'message', e.message, 'ends_at', e.ends_at,
            'exp', e.exp, 'coins', e.coins, 'pulls', e.pulls, 'decor', d.name, 'decor_emoji', d.emoji, 'card', c.name, 'card_emoji', c.emoji,
            'claimed', exists (select 1 from checkin_claims k where k.event_id = e.id and k.student_id = sid)) order by e.ends_at)
          from checkin_events e left join decor_items d on d.id = e.decor_id left join cards c on c.id = e.card_id
         where not e.closed and now() >= e.starts_at and now() < e.ends_at), '[]'::json);
end $$;

-- นักเรียน: กดรับรางวัล (คนละ 1 ครั้งต่ออีเว้นท์)
create or replace function checkin_claim(p_token uuid, p_event uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); e checkin_events%rowtype; dn text; cn text;
begin
  select * into e from checkin_events where id = p_event for share;
  if not found or e.closed or now() < e.starts_at or now() >= e.ends_at then raise exception 'อีเว้นท์นี้ปิดแล้ว หรือยังไม่เปิด'; end if;
  insert into checkin_claims (event_id, student_id) values (e.id, sid) on conflict do nothing;
  if not found then raise exception 'คุณรับรางวัลอีเว้นท์นี้แล้ว'; end if;
  if e.exp > 0 or e.coins > 0 then perform award(sid, e.exp, e.coins, '🎟️ เช็คอิน: ' || e.title, 'checkin:' || e.id); end if;
  if e.pulls > 0 then update students set free_pulls = free_pulls + e.pulls where id = sid; end if;
  if e.decor_id is not null then
    insert into student_decor (student_id, item_id, source) values (sid, e.decor_id, 'teacher') on conflict do nothing;
    select name into dn from decor_items where id = e.decor_id;
  end if;
  if e.card_id is not null then
    insert into student_cards (student_id, card_id, qty) values (sid, e.card_id, 1)
    on conflict (student_id, card_id) do update set qty = student_cards.qty + 1;
    select name into cn from cards where id = e.card_id;
  end if;
  perform check_achievements(sid);
  return json_build_object('title', e.title, 'exp', e.exp, 'coins', e.coins, 'pulls', e.pulls, 'decor', dn, 'card', cn);
end $$;
revoke execute on function checkin_list(uuid), checkin_claim(uuid, uuid) from public;
grant execute on function checkin_list(uuid), checkin_claim(uuid, uuid) to anon, authenticated;
-- =====================================================================
-- 86: ปรับตัวตรวจ "EXP พุ่งผิดปกติ" ไม่ให้แจ้งเตือนมั่วจากรางวัลที่ระบบ/ครูแจกเอง (รันซ้ำได้)
--  สาเหตุ: SQL 84 เพิ่มตราใหม่ → นักเรียนที่ทำเงื่อนไขได้อยู่แล้วได้รางวัลตราย้อนหลังพร้อมกันหลายอัน (EXP รวมเกิน 600 ใน 1 ชม.)
--  แก้: ไม่นับรายการที่ ref_key ขึ้นต้น ach: / gift: / checkin: (ยังนับ EXP จากเกม/ส่งงาน/เควส/ปรับมือ ตามเดิม)
-- =====================================================================
create or replace function security_scan() returns json
language plpgsql security definer set search_path = public as $$
declare r record; n int := 0; day text := to_char(now(), 'YYYYMMDD'); spike int := _setting_int('sec_exp_spike', 600);
begin
  if not is_teacher() then raise exception 'เฉพาะครูเท่านั้น'; end if;
  -- 1) ตารางที่ปิด RLS
  for r in select c.relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
            where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity
              and exists (select 1 from pg_policies pp where pp.schemaname = 'public' and pp.tablename = c.relname and pp.policyname = 'teacher_all') loop
    perform _sec_log('rls_off', 'critical', null, 'ตาราง ' || r.relname || ' ปิด RLS — ใครก็อ่านได้', 'rls:' || r.relname || ':' || day); n := n + 1;
  end loop;
  -- 2) ฟังก์ชันครูที่ anon เรียกได้
  for r in select p.proname from pg_proc p where p.pronamespace = 'public'::regnamespace
            and (p.proname like 'admin\_%' or p.proname in ('health_check','game_stats','security_scan','security_summary'))
            and has_function_privilege('anon', p.oid, 'execute') loop
    perform _sec_log('anon_admin_fn', 'critical', null, 'ฟังก์ชัน ' || r.proname || ' เปิดให้คนทั่วไปเรียกได้', 'fn:' || r.proname || ':' || day); n := n + 1;
  end loop;
  -- 3) anon อ่านตารางสำคัญได้
  for r in select t from unnest(array['students','ledger','student_sessions','teachers','security_events']) t
            where to_regclass('public.' || t) is not null and has_table_privilege('anon', 'public.' || t, 'select') loop
    perform _sec_log('anon_table', 'critical', null, 'anon มีสิทธิ์อ่านตาราง ' || r.t, 'tbl:' || r.t || ':' || day); n := n + 1;
  end loop;
  -- 4) EXP พุ่งผิดปกติใน 1 ชั่วโมง (ไม่นับรางวัลที่ระบบ/ครูแจก: ตราความสำเร็จ ของขวัญ เช็คอิน)
  for r in select l.student_id, s.name, sum(l.exp) e from ledger l join students s on s.id = l.student_id
            where l.created_at > now() - interval '1 hour' and coalesce(l.ref_key, '') !~ '^(ach|gift|checkin):' group by 1, 2 having sum(l.exp) > spike loop
    perform _sec_log('exp_spike', 'high', r.student_id, r.name || ' ได้ EXP ' || r.e || ' ใน 1 ชั่วโมง (เกณฑ์ ' || spike || ')', 'spike:' || r.student_id || ':' || day || to_char(now(), 'HH24')); n := n + 1;
  end loop;
  -- 5) เซสชันนักเรียนคนเดียวมากผิดปกติ
  for r in select ss.student_id, count(*) c from student_sessions ss where not ss.observer and ss.expires_at > now() group by 1 having count(*) > 40 loop
    perform _sec_log('many_sessions', 'warn', r.student_id, 'มีเซสชันที่ใช้งานอยู่ ' || r.c || ' รายการ (อาจมีการเข้าซ้ำอัตโนมัติ)', 'sess:' || r.student_id || ':' || day); n := n + 1;
  end loop;
  -- 6) ค่าติดลบ
  if exists (select 1 from students where exp < 0 or coins < 0) then
    perform _sec_log('negative', 'high', null, 'พบ EXP/เหรียญติดลบ ตรวจสอบหน้าสุขภาพระบบ', 'neg:' || day); n := n + 1;
  end if;
  return json_build_object('found', n, 'at', now());
end $$;
-- =====================================================================
-- 87: แคมเปญเช็คอินสะสมวัน — เช็คอินวันละครั้ง ยิ่งครบหลายวันยิ่งได้รางวัลมาก ท้ายสุดแจก "ชุดลิมิเต็ด" (รันซ้ำได้)
--  - นับ "จำนวนวันที่เช็คอิน" (ไม่ต้องติดกัน) · ถึงเป้าแต่ละขั้น = ได้รางวัลขั้นนั้นอัตโนมัติ (ครั้งเดียวต่อขั้น)
--  - รางวัลต่อขั้น: EXP / เหรียญ / ตั๋วกาชา / การ์ด 1 ใบ / ไอเทมตกแต่ง 1 ชิ้น / ชุดไอเทม (set_key)
--  - ชุดลิมิเต็ด "ราชันธาตุ" 3 ชิ้น (หมวก/ดาบ/เอฟเฟกต์) ได้จากแคมเปญเท่านั้น (ไม่ขาย ไม่อยู่ในกาชา)
-- =====================================================================
alter table decor_items add column if not exists set_key text;

insert into decor_items (slot, key, name, emoji, rarity, price, sort, image, element, fx_atk, fx_def, fx_hp, set_key, ability)
select v.slot, 'img', v.name, v.emoji, 'SSR', null, v.sort, v.img, null, v.atk, v.def, v.hp, 'lim_king1', 'ลิมิเต็ด · ชุดราชันธาตุ (ได้จากอีเว้นท์เช็คอินเท่านั้น)'
  from (values
    ('hat',  '[Limited] หมวกราชันธาตุ',    '👑', 95, 'assets/px/lim_hat.png',   0, 4, 3),
    ('item', '[Limited] ดาบราชันธาตุ',     '🗡️', 95, 'assets/px/lim_sword.png', 5, 0, 0),
    ('fx',   '[Limited] ออร่าราชันธาตุ',   '✨', 95, 'assets/px/lim_fx.png',    2, 2, 4)
  ) v(slot, name, emoji, sort, img, atk, def, hp)
where not exists (select 1 from decor_items d where d.slot = v.slot and d.name = v.name);
update decor_items set set_key = 'lim_king1' where name like '[Limited] %ราชันธาตุ' and set_key is null;

create table if not exists checkin_camps (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  message text not null default '',
  start_day date not null default today_th(),
  end_day date not null,
  closed boolean not null default false,
  created_at timestamptz not null default now()
);
create table if not exists checkin_miles (
  id uuid primary key default gen_random_uuid(),
  camp_id uuid not null references checkin_camps(id) on delete cascade,
  need int not null check (need > 0),
  exp int not null default 0 check (exp >= 0),
  coins int not null default 0 check (coins >= 0),
  pulls int not null default 0 check (pulls >= 0),
  decor_id uuid references decor_items(id) on delete set null,
  card_id uuid references cards(id) on delete set null,
  set_key text,
  unique (camp_id, need)
);
create table if not exists checkin_days (
  camp_id uuid not null references checkin_camps(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  day date not null,
  primary key (camp_id, student_id, day)
);
create table if not exists checkin_mclaims (
  mile_id uuid not null references checkin_miles(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  at timestamptz not null default now(),
  primary key (mile_id, student_id)
);
alter table checkin_camps enable row level security; alter table checkin_miles enable row level security;
alter table checkin_days enable row level security; alter table checkin_mclaims enable row level security;
do $$ declare t text; begin
  foreach t in array array['checkin_camps','checkin_miles','checkin_days','checkin_mclaims'] loop
    execute format('drop policy if exists teacher_all on %I', t);
    execute format('create policy teacher_all on %I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on %I from anon', t);
  end loop; end $$;

-- ภายใน: แจกรางวัลของ 1 ขั้น
create or replace function _camp_grant(p_sid uuid, m checkin_miles) returns void
language plpgsql security definer set search_path = public as $$
begin
  if m.exp > 0 or m.coins > 0 then perform award(p_sid, m.exp, m.coins, '🎟️ เช็คอินสะสม ' || m.need || ' วัน', 'checkin:' || m.id); end if;
  if m.pulls > 0 then update students set free_pulls = free_pulls + m.pulls where id = p_sid; end if;
  if m.decor_id is not null then insert into student_decor (student_id, item_id, source) values (p_sid, m.decor_id, 'teacher') on conflict do nothing; end if;
  if m.set_key is not null then
    insert into student_decor (student_id, item_id, source) select p_sid, d.id, 'teacher' from decor_items d where d.set_key = m.set_key on conflict do nothing;
  end if;
  if m.card_id is not null then
    insert into student_cards (student_id, card_id, qty) values (p_sid, m.card_id, 1) on conflict (student_id, card_id) do update set qty = student_cards.qty + 1;
  end if;
end $$;
revoke execute on function _camp_grant(uuid, checkin_miles) from public, anon, authenticated;

-- ครู: เปิดแคมเปญ (เริ่มวันนี้ นาน p_days วัน) พร้อมขั้นรางวัล p_miles = [{need,exp,coins,pulls,decor_id,card_id,set_key}]
create or replace function admin_camp_open(p_title text, p_message text, p_days int, p_miles jsonb) returns uuid
language plpgsql security definer set search_path = public as $$
declare cid uuid; m jsonb; mx int := 0;
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  if btrim(coalesce(p_title, '')) = '' then raise exception 'ใส่ชื่อแคมเปญก่อน'; end if;
  if coalesce(p_days, 0) < 1 or p_days > 120 then raise exception 'จำนวนวันต้องอยู่ระหว่าง 1–120'; end if;
  if jsonb_typeof(p_miles) <> 'array' or jsonb_array_length(p_miles) = 0 then raise exception 'ต้องมีขั้นรางวัลอย่างน้อย 1 ขั้น'; end if;
  insert into checkin_camps (title, message, end_day) values (left(btrim(p_title), 80), left(btrim(coalesce(p_message, '')), 200), today_th() + (p_days - 1)) returning id into cid;
  for m in select * from jsonb_array_elements(p_miles) loop
    if coalesce((m->>'need')::int, 0) < 1 or (m->>'need')::int > p_days then raise exception 'จำนวนวันของแต่ละขั้นต้องอยู่ระหว่าง 1–% วัน', p_days; end if;
    if coalesce((m->>'exp')::int, 0) > 10000 or coalesce((m->>'coins')::int, 0) > 10000 or coalesce((m->>'pulls')::int, 0) > 50 then raise exception 'จำนวนรางวัลมากเกินไป'; end if;
    if coalesce((m->>'exp')::int, 0) + coalesce((m->>'coins')::int, 0) + coalesce((m->>'pulls')::int, 0) = 0 and nullif(m->>'decor_id', '') is null and nullif(m->>'card_id', '') is null and nullif(m->>'set_key', '') is null then
      raise exception 'ขั้น % วัน ยังไม่ได้ใส่รางวัล', m->>'need'; end if;
    insert into checkin_miles (camp_id, need, exp, coins, pulls, decor_id, card_id, set_key)
    values (cid, (m->>'need')::int, coalesce((m->>'exp')::int, 0), coalesce((m->>'coins')::int, 0), coalesce((m->>'pulls')::int, 0),
            nullif(m->>'decor_id', '')::uuid, nullif(m->>'card_id', '')::uuid, nullif(m->>'set_key', ''));
  end loop;
  return cid;
end $$;
revoke execute on function admin_camp_open(text, text, int, jsonb) from public, anon;
grant execute on function admin_camp_open(text, text, int, jsonb) to authenticated;

-- นักเรียน: แคมเปญที่เปิดอยู่ + ความคืบหน้า
create or replace function camp_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); td date := today_th();
begin
  return coalesce((select json_agg(json_build_object(
      'id', c.id, 'title', c.title, 'message', c.message, 'start_day', c.start_day, 'end_day', c.end_day,
      'days_total', c.end_day - c.start_day + 1, 'days_left', c.end_day - td,
      'done', (select count(*) from checkin_days k where k.camp_id = c.id and k.student_id = sid),
      'today', exists (select 1 from checkin_days k where k.camp_id = c.id and k.student_id = sid and k.day = td),
      'miles', (select json_agg(json_build_object('need', m.need, 'exp', m.exp, 'coins', m.coins, 'pulls', m.pulls,
                  'decor', d.name, 'card', cd.name,
                  'set', (select json_agg(json_build_object('name', x.name, 'emoji', x.emoji, 'image', x.image) order by x.sort) from decor_items x where x.set_key = m.set_key),
                  'got', exists (select 1 from checkin_mclaims q where q.mile_id = m.id and q.student_id = sid)) order by m.need)
                from checkin_miles m left join decor_items d on d.id = m.decor_id left join cards cd on cd.id = m.card_id where m.camp_id = c.id)
    ) order by c.end_day)
    from checkin_camps c where not c.closed and td between c.start_day and c.end_day), '[]'::json);
end $$;

-- นักเรียน: เช็คอินวันนี้ (วันละครั้ง) → ได้รางวัลขั้นที่ถึงเป้าอัตโนมัติ
create or replace function camp_checkin(p_token uuid, p_camp uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); td date := today_th(); c checkin_camps%rowtype; n int; m checkin_miles%rowtype; got json[] := '{}'; sk json;
begin
  select * into c from checkin_camps where id = p_camp for share;
  if not found or c.closed or td < c.start_day or td > c.end_day then raise exception 'แคมเปญนี้ปิดแล้ว หรือยังไม่เปิด'; end if;
  insert into checkin_days (camp_id, student_id, day) values (c.id, sid, td) on conflict do nothing;
  if not found then raise exception 'วันนี้เช็คอินแล้ว พรุ่งนี้มาใหม่นะ'; end if;
  select count(*) into n from checkin_days where camp_id = c.id and student_id = sid;
  for m in select * from checkin_miles where camp_id = c.id and need <= n order by need loop
    insert into checkin_mclaims (mile_id, student_id) values (m.id, sid) on conflict do nothing;
    if found then
      perform _camp_grant(sid, m);
      select json_agg(json_build_object('name', x.name, 'emoji', x.emoji)) into sk from decor_items x where x.set_key = m.set_key;
      got := got || json_build_object('need', m.need, 'exp', m.exp, 'coins', m.coins, 'pulls', m.pulls,
               'decor', (select name from decor_items where id = m.decor_id), 'card', (select name from cards where id = m.card_id), 'set', sk);
    end if;
  end loop;
  perform check_achievements(sid);
  return json_build_object('title', c.title, 'done', n, 'rewards', to_json(got));
end $$;
revoke execute on function camp_status(uuid), camp_checkin(uuid, uuid) from public;
grant execute on function camp_status(uuid), camp_checkin(uuid, uuid) to anon, authenticated;
-- =====================================================================
-- 89: camp_status ส่งรายการ "วันที่เช็คอินแล้ว" + วันนี้ เพื่อแสดงแบนเนอร์เป็นแถวรายวัน (รันซ้ำได้ · ต้องรัน SQL 87 ก่อน)
-- =====================================================================
create or replace function camp_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); td date := today_th();
begin
  return coalesce((select json_agg(json_build_object(
      'id', c.id, 'title', c.title, 'message', c.message, 'start_day', c.start_day, 'end_day', c.end_day,
      'days_total', c.end_day - c.start_day + 1, 'days_left', c.end_day - td,
      'done', (select count(*) from checkin_days k where k.camp_id = c.id and k.student_id = sid),
      'checked', (select coalesce(json_agg(k.day order by k.day), '[]'::json) from checkin_days k where k.camp_id = c.id and k.student_id = sid),
      'today_date', td,
      'today', exists (select 1 from checkin_days k where k.camp_id = c.id and k.student_id = sid and k.day = td),
      'miles', (select json_agg(json_build_object('need', m.need, 'exp', m.exp, 'coins', m.coins, 'pulls', m.pulls,
                  'decor', d.name, 'card', cd.name,
                  'set', (select json_agg(json_build_object('name', x.name, 'emoji', x.emoji, 'image', x.image) order by x.sort) from decor_items x where x.set_key = m.set_key),
                  'got', exists (select 1 from checkin_mclaims q where q.mile_id = m.id and q.student_id = sid)) order by m.need)
                from checkin_miles m left join decor_items d on d.id = m.decor_id left join cards cd on cd.id = m.card_id where m.camp_id = c.id)
    ) order by c.end_day)
    from checkin_camps c where not c.closed and td between c.start_day and c.end_day), '[]'::json);
end $$;
-- =====================================================================
-- 90: ออร่าชุดราชันธาตุให้มีเอฟเฟกต์ตอนสวมใส่ (รันซ้ำได้) — ตั้ง key = 'king' เพื่อให้หน้าเว็บวาดออร่าทองประกายรอบตัวละคร
-- =====================================================================
update decor_items set key = 'king' where set_key = 'lim_king1' and slot = 'fx' and key <> 'king';
-- =====================================================================
-- 91: ช่องอุปกรณ์ใหม่ "สร้อย" (neck) และ "แหวน" (ring) + ไอเทม 13 ชิ้น (แหวน 6 · สร้อย 7) (รันซ้ำได้ · ต้องรัน 81 ก่อน)
--  แหวน = เพิ่มพลังโจมตี (+สเตตัสพลังโจมตี) · สร้อย = เพิ่มป้องกัน/HP (+สเตตัสโชค) · มีธาตุตามสีพลอย/ลูกปัด · ขายในร้านค้าด้วยเหรียญ
--  ภาพ: assets/px/ring_*.png, neck_*.png (Shikashi's Fantasy Icons — ดัดแปลงสีพลอย/ลูกปัด · ดูเครดิตใน assets/CREDITS.md)
-- =====================================================================
alter table decor_items drop constraint if exists decor_items_slot_check;
alter table decor_items add constraint decor_items_slot_check
  check (slot in ('frame','bg','hat','pet','title','outfit','fx','item','neck','ring'));

create or replace function equip_decor(p_token uuid, p_slot text, p_item uuid) returns void
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  if p_slot not in ('frame','bg','hat','pet','title','outfit','fx','item','neck','ring') then raise exception 'ช่องไม่ถูกต้อง'; end if;
  if p_item is null then
    update students set decor = decor - p_slot where id = sid;
    return;
  end if;
  if not exists (select 1 from student_decor sd join decor_items d on d.id = sd.item_id
                  where sd.student_id = sid and sd.item_id = p_item and d.slot = p_slot) then
    raise exception 'ยังไม่มีไอเทมนี้';
  end if;
  update students set decor = decor || jsonb_build_object(p_slot, p_item::text) where id = sid;
end $$;

create or replace function _gear(p_sid uuid) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare sc numeric := _setting_int('gear_fx_pct', 100) / 100.0; a numeric := 0; d numeric := 0; h numeric := 0; el jsonb := '{}'::jsonb; parts jsonb := '[]'::jsonb; r record;
begin
  for r in
    select 'item' src, di.name, di.emoji, di.element el,
           di.fx_atk * (1 + 0.15 * (coalesce(sd.lvl, 1) - 1)) fa, di.fx_def * (1 + 0.15 * (coalesce(sd.lvl, 1) - 1)) fd, di.fx_hp * (1 + 0.15 * (coalesce(sd.lvl, 1) - 1)) fh
      from students s cross join lateral jsonb_each_text(s.decor) e
      join decor_items di on di.id = e.value::uuid and di.slot = e.key and di.slot in ('hat', 'outfit', 'item', 'fx', 'pet', 'neck', 'ring')
      left join student_decor sd on sd.student_id = s.id and sd.item_id = di.id
     where s.id = p_sid
    union all
    select 'card', c.name, c.emoji, c.element, (case when c.fx_kind = 'atk' then c.fx_pct else 0 end)::numeric, (case when c.fx_kind = 'def' then c.fx_pct else 0 end)::numeric,
           (case when c.fx_kind = 'hp' then c.fx_pct else 0 end)::numeric
      from student_card_slots sl join cards c on c.id = sl.card_id and c.active where sl.student_id = p_sid
  loop
    a := a + r.fa; d := d + r.fd; h := h + r.fh;
    if r.el is not null then el := jsonb_set(el, array[r.el], to_jsonb(coalesce((el->>r.el)::int, 0) + 1)); end if;
    parts := parts || jsonb_build_object('src', r.src, 'name', r.name, 'emoji', r.emoji, 'el', r.el);
  end loop;
  return jsonb_build_object('atk', least(_setting_int('gear_cap_atk', 25), round(a * sc, 1)), 'def', least(_setting_int('gear_cap_def', 20), round(d * sc, 1)),
    'hp', least(_setting_int('gear_cap_hp', 30), round(h * sc, 1)), 'el', el, 'parts', parts);
end $$;

insert into decor_items (slot, key, name, emoji, rarity, price, sort, image, element, fx_atk, fx_def, fx_hp, st_str, st_luk, ability)
select v.slot, 'img', v.name, v.emoji, v.rarity, v.price, v.sort, v.img, v.el, v.atk, v.def, v.hp,
       case when v.slot = 'ring' then v.st else 0 end, case when v.slot = 'neck' then v.st else 0 end,
       case when v.slot = 'ring' then 'แหวน: เพิ่มพลังโจมตีตอนสู้มอนสเตอร์' else 'สร้อย: เพิ่มป้องกันและ HP ตอนสู้มอนสเตอร์' end
  from (values
    ('ring', 'แหวนทองเรียบ', '💍', 'N', 120, 50, 'assets/px/ring_gold.png', null, 1, 0, 0, 1),
    ('ring', 'แหวนเพชรสายน้ำ', '💍', 'R', 240, 51, 'assets/px/ring_water.png', 'water', 2, 0, 0, 1),
    ('ring', 'แหวนทับทิมเพลิง', '💍', 'R', 240, 52, 'assets/px/ring_fire.png', 'fire', 2, 0, 0, 1),
    ('ring', 'แหวนมรกตพงไพร', '💍', 'R', 240, 53, 'assets/px/ring_plant.png', 'plant', 2, 0, 0, 1),
    ('ring', 'แหวนโทแพซสายฟ้า', '💍', 'SR', 480, 54, 'assets/px/ring_thunder.png', 'thunder', 3, 0, 0, 2),
    ('ring', 'แหวนอเมทิสต์สารเคมี', '💍', 'SR', 480, 55, 'assets/px/ring_chem.png', 'chem', 3, 0, 0, 2),
    ('neck', 'สร้อยเขี้ยวป่า', '📿', 'N', 120, 60, 'assets/px/neck_fang.png', null, 0, 1, 1, 1),
    ('neck', 'สร้อยจี้ทองคำ', '📿', 'R', 260, 61, 'assets/px/neck_gold.png', null, 0, 1, 2, 1),
    ('neck', 'สร้อยลูกปัดเพลิง', '📿', 'R', 240, 62, 'assets/px/neck_fire.png', 'fire', 0, 1, 2, 1),
    ('neck', 'สร้อยลูกปัดสายน้ำ', '📿', 'R', 240, 63, 'assets/px/neck_water.png', 'water', 0, 1, 2, 1),
    ('neck', 'สร้อยลูกปัดพงไพร', '📿', 'R', 240, 64, 'assets/px/neck_plant.png', 'plant', 0, 1, 2, 1),
    ('neck', 'สร้อยลูกปัดสายฟ้า', '📿', 'SR', 480, 65, 'assets/px/neck_thunder.png', 'thunder', 0, 2, 3, 2),
    ('neck', 'สร้อยลูกปัดสารเคมี', '📿', 'SR', 480, 66, 'assets/px/neck_chem.png', 'chem', 0, 2, 3, 2)
  ) v(slot, name, emoji, rarity, price, sort, img, el, atk, def, hp, st)
 where not exists (select 1 from decor_items d where d.slot = v.slot and d.name = v.name);
-- =====================================================================
-- 92: ปรับธีมสร้อย/แหวนเป็น "ของขลังผสมวิทย์ปั่นๆ" — เปลี่ยนชื่อ/คำอธิบาย/ภาพของ 13 ชิ้นจาก SQL 91 (รันซ้ำได้ · ต้องรัน 91 ก่อน)
--  ค่าพลัง/ราคา/ธาตุ/ไอเทมที่นักเรียนมีอยู่แล้วไม่เปลี่ยน (แก้เฉพาะชื่อ คำอธิบาย และภาพ)
-- =====================================================================
update decor_items d set name = v.new_name, image = v.img, ability = v.ab || case when d.slot = 'ring' then ' · เพิ่มพลังโจมตีตอนสู้มอนสเตอร์' else ' · เพิ่มป้องกันและ HP ตอนสู้มอนสเตอร์' end
  from (values
    ('ring', 'แหวนทองเรียบ', 'แหวนทองเลขอะตอม 79', 'assets/px/ring_gold.png', 'ทอง (Au) เลขอะตอม 79 — ขลังแบบเรียบๆ แต่ปั่นไม่เบา'),
    ('ring', 'แหวนเพชรสายน้ำ', 'แหวนน้ำมนต์ pH 7', 'assets/px/rg_water.png', 'น้ำมนต์เป็นกลางพอดี pH 7 — ศัตรูเดินผ่านแล้วงงไปสามวิ'),
    ('ring', 'แหวนทับทิมเพลิง', 'แหวนขวดไวไฟ ห้ามใกล้เปลวไฟ', 'assets/px/rg_fire.png', 'ขวดจิ๋วในวงแหวน เขย่าแล้วร้อนวูบ ใครแตะโดนเจ็บ'),
    ('ring', 'แหวนมรกตพงไพร', 'แหวนขวดคลอโรฟิลล์ศักดิ์สิทธิ์', 'assets/px/rg_plant.png', 'สังเคราะห์แสงได้แม้ในห้องเรียน ใส่แล้วสดชื่นฮึดสู้'),
    ('ring', 'แหวนโทแพซสายฟ้า', 'แหวนขวดอิเล็กตรอนแรงสูง', 'assets/px/rg_thunder.png', 'อิเล็กตรอนวิ่งปั่นป่วนในขวด ระวังช็อตเพื่อนข้างๆ'),
    ('ring', 'แหวนอเมทิสต์สารเคมี', 'แหวนขวดม่วงไอโอดีน', 'assets/px/rg_chem.png', 'สีม่วงของไอโอดีนระเหิดเป็นไอ ขลังจนมอนสเตอร์ไอ'),
    ('neck', 'สร้อยเขี้ยวป่า', 'สร้อยเขี้ยวเสือเคลือบแคลเซียม', 'assets/px/neck_fang.png', 'เขี้ยวเสือ(ปลอม) เสริมแคลเซียมแน่นปึ้ก กันกัดไม่เข้า'),
    ('neck', 'สร้อยจี้ทองคำ', 'สร้อยตะกรุดโซเดียม (ห้ามโดนน้ำ)', 'assets/px/nk_gold.png', 'ตะกรุดม้วนด้ายแดง ขลังสุดๆ แต่ห้ามเปียก ไม่งั้นระเบิดปุ๊'),
    ('neck', 'สร้อยลูกปัดเพลิง', 'สร้อยขวดเปลวไฟอาถรรพ์', 'assets/px/nk_fire.png', 'ขวดไฟนรกห้อยคอ ใส่แล้วใจร้อน โจมตีแล้วเจ็บเหมือนโดนลวก'),
    ('neck', 'สร้อยลูกปัดสายน้ำ', 'สร้อยขวดน้ำมนต์ H₂O', 'assets/px/nk_water.png', 'น้ำมนต์สูตร H₂O บริสุทธิ์ ทั้งขลังทั้งไม่มีสารตกค้าง'),
    ('neck', 'สร้อยลูกปัดพงไพร', 'สร้อยขวดยาสมุนไพรคลอโรฟิลล์', 'assets/px/nk_plant.png', 'ยาหม้อใหญ่ในขวดจิ๋ว กลิ่นเหม็นเขียวแต่ฟื้น HP ดีนัก'),
    ('neck', 'สร้อยลูกปัดสายฟ้า', 'สร้อยขวดกรดฟ้าผ่า', 'assets/px/nk_thunder.png', 'กรดเข้มข้นผสมฟ้าผ่า ใส่แล้วผมชี้ ขนลุกทั้งสนามรบ'),
    ('neck', 'สร้อยลูกปัดสารเคมี', 'สร้อยจี้อะตอมวิเศษ', 'assets/px/nk_chem.png', 'อะตอมสุดขลัง นิวเคลียสเรืองแสง อิเล็กตรอนวิ่งวนปกป้องเจ้าของ')
  ) v(slot, old_name, new_name, img, ab)
 where d.slot = v.slot and d.name = v.old_name;
-- 93: เควส "มาเรียนวันนี้" / "ส่งงานวันนี้" แสดงเฉพาะวันที่ทำได้จริง (รันซ้ำได้)
--  · attendance → แสดงเมื่อครูเช็คชื่อห้องนั้นในวันนั้นแล้ว (มีข้อมูลใน ch_attendance)
--  · submit     → แสดงเมื่อห้องมีงานที่ยังไม่เลยกำหนด (หรือไม่มีกำหนดส่ง) หรือมีคนส่งงานของห้องแล้วในวันนั้น
--  · ปิดฟีเจอร์: update app_settings set value='0' where key='quests_day_aware'
--  · แสดงผลเท่านั้น: การให้รางวัลอัตโนมัติ (_auto_quests) ไม่เปลี่ยน
insert into app_settings (key, value) values ('quests_day_aware', '1') on conflict (key) do nothing;

create or replace function todays_quests(p_class uuid, p_date date)
returns setof quests language sql stable security definer set search_path = public as $$
  (select * from quests
    where active and auto_trigger is null and kind = 'daily' and (class_id is null or class_id = p_class)
      and coalesce((select value from app_settings where key = 'quests_auto_only'), '1') <> '1'
    order by md5(id::text || p_date::text)
    limit coalesce((select value::int from app_settings where key = 'daily_quest_count'), 3))
  union all
  (select * from quests
    where active and auto_trigger is null and kind = 'weekly' and (class_id is null or class_id = p_class)
      and coalesce((select value from app_settings where key = 'quests_auto_only'), '1') <> '1')
  union all
  (select * from quests q
    where q.active and q.auto_trigger is not null and (q.class_id is null or q.class_id = p_class)
      and (coalesce((select value from app_settings where key = 'quests_day_aware'), '1') <> '1'
           or case q.auto_trigger
                when 'attendance' then exists (select 1 from ch_attendance a where a.class_id = p_class and a.att_date = p_date)
                when 'submit' then exists (select 1 from ch_assignments x
                                            where x.class_id = p_class and (x.due_date is null or x.due_date >= p_date))
                                or exists (select 1 from ch_submissions sb join ch_assignments x on x.id = sb.assignment_id
                                            where x.class_id = p_class and sb.status in ('submitted','late')
                                              and (sb.submitted_at at time zone 'Asia/Bangkok')::date = p_date)
                else true end))
$$;
revoke execute on function todays_quests(uuid, date) from public, anon, authenticated;
-- 94: ย่อยการ์ดซ้ำเป็นเศษธาตุ → หลอมการ์ดใหม่ (รันซ้ำได้)
--  · การ์ดซ้ำไม่แปลงเป็นเศษอัตโนมัติอีกต่อไป: เก็บเป็น "ใบสำรอง" นักเรียนเลือกย่อยเอง (เก็บไว้แลก/แจกไม่ได้ ย่อยได้เท่านั้น)
--  · ย่อย: N=1 · R=3 · SR=10 · SSR=30 เศษต่อใบ (ตรงกับค่าเดิมของ _card_shards)
--  · หลอม: เลือกระดับ แล้วได้การ์ด "ใบที่ยังไม่มี" แบบสุ่มในระดับนั้นแน่นอน · ราคา N=5 R=12 SR=40 SSR=100 (ปรับได้ใน app_settings: forge_n/forge_r/forge_sr/forge_ssr)
--  · ใบที่ได้เคยถูกแปลงเป็นเศษไปแล้วก่อนหน้านี้ ไม่ถูกนับเป็นใบสำรอง (กันได้เศษซ้ำ)
alter table student_cards add column if not exists paid int not null default 0;

do $$ begin
  if not exists (select 1 from app_settings where key = 'card_forge_migrated') then
    update student_cards sc set paid = least(greatest(sc.qty - 1, 0), (select count(*) from card_drops d
        where d.student_id = sc.student_id and d.card_id = sc.card_id and d.is_new = false and d.shards > 0));
    insert into app_settings (key, value) values ('card_forge_migrated', '1');
  end if;
end $$;

insert into app_settings (key, value) values ('forge_n', '5'), ('forge_r', '12'), ('forge_sr', '40'), ('forge_ssr', '100') on conflict (key) do nothing;

alter table card_drops drop constraint if exists card_drops_source_check;
alter table card_drops add constraint card_drops_source_check check (source in ('game', 'gacha', 'gift', 'forge'));

create or replace function _forge_cost(p_rarity text) returns int language sql stable security definer set search_path = public as $$
  select case p_rarity when 'N' then _setting_int('forge_n', 5) when 'R' then _setting_int('forge_r', 12)
                       when 'SR' then _setting_int('forge_sr', 40) when 'SSR' then _setting_int('forge_ssr', 100) end $$;
revoke execute on function _forge_cost(text) from public, anon, authenticated;

-- มอบการ์ด: ซ้ำ → เป็นใบสำรอง (ไม่ให้เศษอัตโนมัติ) · ครบชุด → รางวัล (ครั้งเดียวต่อชุด)
create or replace function _card_grant(p_sid uuid, p_card uuid, p_source text, p_game text default null) returns jsonb
language plpgsql security definer set search_path = public as $$
declare c cards%rowtype; st card_sets%rowtype; isnew boolean; done jsonb := null; tot int; own int;
begin
  select * into c from cards where id = p_card;
  if c.id is null then raise exception 'ไม่พบการ์ด'; end if;
  select * into st from card_sets where id = c.set_id;
  insert into student_cards (student_id, card_id) values (p_sid, p_card)
    on conflict (student_id, card_id) do update set qty = student_cards.qty + 1 returning (xmax = 0) into isnew;
  if isnew then update students set card_pity = 0 where id = p_sid;
  else update students set card_pity = card_pity + 1 where id = p_sid; end if;
  insert into card_drops (student_id, card_id, source, game, is_new, shards) values (p_sid, p_card, p_source, p_game, isnew, 0);
  if isnew then
    select count(*) into tot from cards where set_id = c.set_id and active;
    select count(*) into own from student_cards sc join cards x on x.id = sc.card_id where sc.student_id = p_sid and x.set_id = c.set_id and x.active;
    if tot > 0 and own >= tot and not exists (select 1 from student_set_claims where student_id = p_sid and set_id = c.set_id) then
      insert into student_set_claims (student_id, set_id) values (p_sid, c.set_id);
      if st.reward_coins > 0 then perform award(p_sid, 0, st.reward_coins, '📖 สะสมการ์ดครบชุด ' || st.title, 'cardset:' || c.set_id); end if;
      if st.reward_pulls > 0 then update students set free_pulls = free_pulls + st.reward_pulls where id = p_sid; end if;
      if st.reward_decor is not null then insert into student_decor (student_id, item_id, source) values (p_sid, st.reward_decor, 'teacher') on conflict do nothing; end if;
      done := jsonb_build_object('title', st.title, 'coins', st.reward_coins, 'pulls', st.reward_pulls);
    end if;
  end if;
  return jsonb_build_object('id', c.id, 'name', c.name, 'symbol', c.symbol, 'emoji', c.emoji, 'rarity', c.rarity, 'fact', c.fact,
                            'image', c.image_url, 'set', st.title, 'set_emoji', st.emoji, 'is_new', isnew, 'shards', 0, 'spare', not isnew, 'set_done', done);
end $$;
revoke execute on function _card_grant(uuid, uuid, text, text) from public, anon, authenticated;

-- ย่อยใบสำรองเป็นเศษธาตุ: p_card = การ์ดใบนั้น (p_n = จำนวน, ว่าง = ทุกใบสำรอง) · p_card ว่าง = ทุกใบสำรองของทุกการ์ด
create or replace function card_dismantle(p_token uuid, p_card uuid default null, p_n int default null) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); r record; sp int; take int; gain int := 0; cnt int := 0; sh int;
begin
  perform 1 from students where id = sid for update;
  for r in select sc.card_id, sc.qty, sc.paid, c.rarity from student_cards sc join cards c on c.id = sc.card_id
            where sc.student_id = sid and (p_card is null or sc.card_id = p_card) order by c.rarity for update of sc loop
    sp := r.qty - 1 - r.paid;
    if sp <= 0 then continue; end if;
    take := case when p_card is null or p_n is null then sp else least(sp, greatest(p_n, 0)) end;
    if take <= 0 then continue; end if;
    update student_cards set qty = qty - take where student_id = sid and card_id = r.card_id;
    gain := gain + take * _card_shards(r.rarity); cnt := cnt + take;
  end loop;
  if cnt = 0 then raise exception 'ไม่มีการ์ดสำรองให้ย่อย'; end if;
  update students set shards = shards + gain where id = sid returning shards into sh;
  return json_build_object('cards', cnt, 'gained', gain, 'shards', sh);
end $$;
revoke execute on function card_dismantle(uuid, uuid, int) from public;
grant execute on function card_dismantle(uuid, uuid, int) to anon, authenticated;

-- หลอมการ์ดใหม่: เลือกระดับ → ได้ใบที่ยังไม่มีแบบสุ่มในระดับนั้น
create or replace function card_forge(p_token uuid, p_rarity text) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cost int; cid uuid; sh int; res jsonb;
begin
  if p_rarity not in ('N', 'R', 'SR', 'SSR') then raise exception 'ระดับการ์ดไม่ถูกต้อง'; end if;
  cost := _forge_cost(p_rarity);
  select shards into sh from students where id = sid for update;
  if sh < cost then raise exception 'เศษธาตุไม่พอ (ต้องใช้ % มี %)', cost, sh; end if;
  select c.id into cid from cards c join card_sets s on s.id = c.set_id
   where c.active and s.active and c.rarity = p_rarity
     and not exists (select 1 from student_cards x where x.student_id = sid and x.card_id = c.id)
   order by random() limit 1;
  if cid is null then raise exception 'คุณมีการ์ดระดับนี้ครบทุกใบแล้ว'; end if;
  update students set shards = shards - cost where id = sid returning shards into sh;
  res := _card_grant(sid, cid, 'forge');
  return json_build_object('card', res, 'cost', cost, 'shards', sh);
end $$;
revoke execute on function card_forge(uuid, text) from public;
grant execute on function card_forge(uuid, text) to anon, authenticated;

create or replace function card_album(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); res json; s students%rowtype;
begin
  select * into s from students where id = sid;
  select json_build_object('shards', s.shards, 'pity', s.card_pity, 'pity_max', _setting_int('card_pity', 4),
    'cap', _setting_int('card_daily_cap', 3), 'used', (select count(*) from card_drops where student_id = sid and play_date = today_th() and source = 'game'),
    'spare_total', (select coalesce(sum(greatest(sc.qty - 1 - sc.paid, 0)), 0) from student_cards sc where sc.student_id = sid),
    'spare_shards', (select coalesce(sum(greatest(sc.qty - 1 - sc.paid, 0) * _card_shards(c.rarity)), 0) from student_cards sc join cards c on c.id = sc.card_id where sc.student_id = sid),
    'forge', (select json_agg(json_build_object('rarity', r.k, 'cost', _forge_cost(r.k),
        'left', (select count(*) from cards c join card_sets cs on cs.id = c.set_id where c.active and cs.active and c.rarity = r.k
                   and not exists (select 1 from student_cards x where x.student_id = sid and x.card_id = c.id))) order by r.o)
        from (values ('N', 1), ('R', 2), ('SR', 3), ('SSR', 4)) r(k, o)),
    'sets', coalesce((select json_agg(json_build_object('id', cs.id, 'title', cs.title, 'emoji', cs.emoji, 'color', cs.color,
        'reward', json_build_object('coins', cs.reward_coins, 'pulls', cs.reward_pulls, 'decor', (select d.name from decor_items d where d.id = cs.reward_decor)),
        'claimed', exists (select 1 from student_set_claims x where x.student_id = sid and x.set_id = cs.id),
        'cards', (select coalesce(json_agg(json_build_object('id', c.id, 'no', c.no, 'rarity', c.rarity, 'symbol', c.symbol, 'emoji', c.emoji,
              'own', sc.card_id is not null, 'qty', coalesce(sc.qty, 0), 'spare', greatest(coalesce(sc.qty, 0) - 1 - coalesce(sc.paid, 0), 0),
              'name', case when sc.card_id is not null then c.name end,
              'fact', case when sc.card_id is not null then c.fact end, 'image', case when sc.card_id is not null then c.image_url end) order by c.no), '[]'::json)
            from cards c left join student_cards sc on sc.card_id = c.id and sc.student_id = sid where c.set_id = cs.id and c.active))
        order by cs.sort, cs.title) from card_sets cs where cs.active), '[]'::json)) into res;
  return res;
end $$;
revoke execute on function card_album(uuid) from public;
grant execute on function card_album(uuid) to anon, authenticated;
