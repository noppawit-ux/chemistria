-- ===== รันไฟล์นี้ไฟล์เดียว: SQL 117–121 (ปรับสมดุล EXP/เหรียญ + แจ้งเตือนรายบุคคล + ข่าวหน้าแรก) =====
-- ต้องรันหลัง SQL 100 และ 110–116 · รันซ้ำได้ (แต่ละส่วนทำครั้งเดียว)
-- สรุป: เพดานเล่นต่อวัน EXP 120 / เหรียญ 180 (กัน race) · แรงค์ Diamond 4,700 · Master 7,000 · Grandmaster 10,000 · Challenger 14,500
--       ลดรางวัล Achievement + ดันเจี้ยน 50% · หัก EXP ที่เกินเพดานย้อนหลัง "บางส่วน" (50% ของส่วนเกิน)
--       ส่งแจ้งเตือนรายบุคคลให้นักเรียนทุกคน · ลบข่าว/อีเว้นท์ที่จบแล้ว · เพิ่มข่าวหน้าแรกชุดใหม่

-- SQL 117 · ปรับสมดุล EXP: เพดาน EXP จากการเล่นเกมต่อวัน + แรงค์สูงขึ้นยากขึ้น
-- ต้องรันหลัง 25, 100 (เกณฑ์แรงค์เดิม) · รันซ้ำได้ · ไม่แก้ฟังก์ชัน award/battle_* เดิม (ใช้ทริกเกอร์)
--
-- 1) เพดานรวม "EXP จากการเล่น" ต่อวัน (play_daily_cap_exp, ค่าเริ่มต้น 100 · 0 = ไม่จำกัด)
--    นับรวม: มินิเกม · สู้มอนสเตอร์/บอส · ท้าดวล · ดันเจี้ยน · EXP จากหีบ/ดรอป · ประลองครูบุ๊ค (ledger ref game:* / dungeon:* และ EXP จากดรอป)
--    ไม่นับ (ครูเป็นคนกำหนด จึงไม่จำกัด): เช็คชื่อ · ส่งงาน · เควส · สอบ · ของขวัญ/ปรับ EXP จากครู · Achievement
--    เกินเพดานแล้วยังได้เหรียญ/ไอเทมตามปกติ แต่ EXP ส่วนที่เกินจะไม่เข้า (บันทึกใน ledger ว่า "ครบเพดาน")
-- 2) เกณฑ์แรงค์ Diamond ขึ้นไป (ปรับแบบเบา): Diamond 4,400→4,700 · Master 6,300→7,000 · Grandmaster 8,700→10,000 · Challenger 12,000→14,500
--    เปลี่ยนเฉพาะแรงค์ที่ยังเป็นค่าจาก SQL 100 (ถ้าครูแก้เองไว้จะไม่ทับ) · EXP นักเรียนไม่หาย แต่แรงค์ที่แสดงอาจลดลงเล็กน้อยตามเกณฑ์ใหม่

insert into app_settings (key, value) values ('play_daily_cap_exp', '100') on conflict (key) do nothing;

update ch_ranks r set min_exp = v.new_exp
  from (values ('diamond',4400,4700),('master',6300,7000),('grandmaster',8700,10000),('challenger',12000,14500)) v(key, old_exp, new_exp)
 where r.key = v.key and r.min_exp in (v.old_exp, v.new_exp);

-- แถว ledger ที่ถือว่าเป็น "EXP จากการเล่น"
create or replace function _is_play_ledger(p_ref text, p_reason text) returns boolean
language sql immutable as $$
  select coalesce(p_ref ~ '^(game|dungeon):', false)
      or (p_ref is null and coalesce(p_reason ~ '^(ดรอปมอนสเตอร์|หีบดันเจี้ยน|รางวัลจากครูบุ๊ค)', false))
$$;

create or replace function _play_exp_today(p_sid uuid) returns int
language sql stable security definer set search_path = public as $$
  select coalesce(sum(exp), 0)::int from ledger
   where student_id = p_sid and exp > 0 and (created_at at time zone 'Asia/Bangkok')::date = today_th()
     and _is_play_ledger(ref_key, reason)
$$;
revoke execute on function _is_play_ledger(text, text) from public, anon, authenticated;
revoke execute on function _play_exp_today(uuid) from public, anon, authenticated;

-- ทริกเกอร์ 1: ก่อนบันทึก ledger ตัด EXP ส่วนเกินเพดาน แล้วจดส่วนที่ตัดไว้ให้ทริกเกอร์ของ students
create or replace function trg_play_cap() returns trigger
language plpgsql security definer set search_path = public as $$
declare cap int := _setting_int('play_daily_cap_exp', 100); used int; room int; cut int;
begin
  if cap <= 0 or new.exp <= 0 or not _is_play_ledger(new.ref_key, new.reason) then return new; end if;
  if new.ref_key is not null and exists (select 1 from ledger where student_id = new.student_id and ref_key = new.ref_key) then return new; end if;  -- ซ้ำ: จะถูกข้ามอยู่แล้ว
  used := _play_exp_today(new.student_id);
  room := greatest(0, cap - used);
  if new.exp <= room then return new; end if;
  cut := new.exp - room;
  new.exp := room;
  new.reason := coalesce(new.reason, '') || ' (ครบเพดาน EXP จากการเล่นวันนี้ — ตัด ' || cut || ')';
  perform set_config('ch.play_cut', new.student_id::text || ':' || cut, true);
  return new;
end $$;
drop trigger if exists play_cap on ledger;
create trigger play_cap before insert on ledger for each row execute function trg_play_cap();

-- ทริกเกอร์ 2: ตอน award() บวก EXP เข้า students ให้หักส่วนที่ตัดออก (ไม่แก้ award)
create or replace function trg_play_cap_apply() returns trigger
language plpgsql security definer set search_path = public as $$
declare v text := current_setting('ch.play_cut', true); cut int;
begin
  if coalesce(v, '') = '' then return new; end if;
  if split_part(v, ':', 1) <> new.id::text then return new; end if;
  perform set_config('ch.play_cut', '', true);
  cut := coalesce(nullif(split_part(v, ':', 2), '')::int, 0);
  if cut > 0 and new.exp > old.exp then new.exp := greatest(old.exp, new.exp - cut); end if;
  return new;
end $$;
drop trigger if exists play_cap_apply on students;
create trigger play_cap_apply before update of exp on students for each row execute function trg_play_cap_apply();

-- สถานะสำหรับแสดงในแอป
create or replace function play_exp_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  return json_build_object('cap', _setting_int('play_daily_cap_exp', 100), 'used', _play_exp_today(sid));
end $$;
revoke execute on function trg_play_cap() from public, anon, authenticated;
revoke execute on function trg_play_cap_apply() from public, anon, authenticated;
revoke execute on function play_exp_status(uuid) from public;
grant execute on function play_exp_status(uuid) to anon, authenticated;

-- SQL 118 · เพดานเหรียญจากการเล่นต่อวัน (ต่อจาก 117)
-- ต้องรันหลัง 117 · รันซ้ำได้ · ไม่แก้ award/battle_* (ใช้ทริกเกอร์เดิมของ 117 ขยายให้ตัดเหรียญด้วย)
-- play_daily_cap_coins = 150 เหรียญ/วัน (0 = ไม่จำกัด) · นับแถวเดียวกับเพดาน EXP: มินิเกม · ต่อสู้ · ท้าดวล · ดันเจี้ยน · หีบ/ดรอป · ประลองครูบุ๊ค
-- ไม่นับ เช็คชื่อ/ส่งงาน/เควส/สอบ/ของขวัญครู/Achievement/การคืนเงิน (เหรียญติดลบไม่ถูกจำกัด)

insert into app_settings (key, value) values ('play_daily_cap_coins', '150') on conflict (key) do nothing;

create or replace function _play_coins_today(p_sid uuid) returns int
language sql stable security definer set search_path = public as $$
  select coalesce(sum(coins), 0)::int from ledger
   where student_id = p_sid and coins > 0 and (created_at at time zone 'Asia/Bangkok')::date = today_th()
     and _is_play_ledger(ref_key, reason)
$$;
revoke execute on function _play_coins_today(uuid) from public, anon, authenticated;

create or replace function trg_play_cap() returns trigger
language plpgsql security definer set search_path = public as $$
declare capx int := _setting_int('play_daily_cap_exp', 100); capc int := _setting_int('play_daily_cap_coins', 150);
        roomx int; roomc int; cutx int := 0; cutc int := 0; note text := '';
begin
  if (new.exp <= 0 and new.coins <= 0) or not _is_play_ledger(new.ref_key, new.reason) then return new; end if;
  if new.ref_key is not null and exists (select 1 from ledger where student_id = new.student_id and ref_key = new.ref_key) then return new; end if;  -- ซ้ำ: ถูกข้ามอยู่แล้ว
  if capx > 0 and new.exp > 0 then
    roomx := greatest(0, capx - _play_exp_today(new.student_id));
    if new.exp > roomx then cutx := new.exp - roomx; new.exp := roomx; note := note || ' ตัด EXP ' || cutx; end if;
  end if;
  if capc > 0 and new.coins > 0 then
    roomc := greatest(0, capc - _play_coins_today(new.student_id));
    if new.coins > roomc then cutc := new.coins - roomc; new.coins := roomc; note := note || ' ตัดเหรียญ ' || cutc; end if;
  end if;
  if cutx > 0 or cutc > 0 then
    new.reason := coalesce(new.reason, '') || ' (ครบเพดานจากการเล่นวันนี้ —' || note || ')';
    perform set_config('ch.play_cut', new.student_id::text || ':' || cutx || ':' || cutc, true);
  end if;
  return new;
end $$;

create or replace function trg_play_cap_apply() returns trigger
language plpgsql security definer set search_path = public as $$
declare v text := current_setting('ch.play_cut', true); cx int; cc int;
begin
  if coalesce(v, '') = '' or split_part(v, ':', 1) <> new.id::text then return new; end if;
  perform set_config('ch.play_cut', '', true);
  cx := coalesce(nullif(split_part(v, ':', 2), '')::int, 0);
  cc := coalesce(nullif(split_part(v, ':', 3), '')::int, 0);
  if cx > 0 and new.exp > old.exp then new.exp := greatest(old.exp, new.exp - cx); end if;
  if cc > 0 and new.coins > old.coins then new.coins := greatest(old.coins, new.coins - cc); end if;
  return new;
end $$;
drop trigger if exists play_cap_apply on students;
create trigger play_cap_apply before update of exp, coins on students for each row execute function trg_play_cap_apply();

create or replace function play_exp_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  return json_build_object('cap', _setting_int('play_daily_cap_exp', 100), 'used', _play_exp_today(sid),
                           'coin_cap', _setting_int('play_daily_cap_coins', 150), 'coin_used', _play_coins_today(sid));
end $$;
revoke execute on function trg_play_cap() from public, anon, authenticated;
revoke execute on function trg_play_cap_apply() from public, anon, authenticated;

-- SQL 119 · ปิดช่องโหว่เพดานต่อวัน: ส่งคำขอพร้อมกันหลายคำขอ (race) แล้วได้ EXP/เหรียญเกินเพดาน
-- ต้องรันหลัง 118 · รันซ้ำได้ · ล็อกต่อนักเรียนก่อนนับยอดวันนี้ (advisory lock จนจบทรานแซกชัน)
-- ทดสอบก่อนแก้: ส่ง award 2 คำขอพร้อมกัน (80/80) ได้ 160/160 ทั้งที่เพดาน 100/150 → หลังแก้ได้ 100/150

create or replace function trg_play_cap() returns trigger
language plpgsql security definer set search_path = public as $$
declare capx int := _setting_int('play_daily_cap_exp', 100); capc int := _setting_int('play_daily_cap_coins', 150);
        roomx int; roomc int; cutx int := 0; cutc int := 0; note text := '';
begin
  if (new.exp <= 0 and new.coins <= 0) or not _is_play_ledger(new.ref_key, new.reason) then return new; end if;
  if capx <= 0 and capc <= 0 then return new; end if;
  perform pg_advisory_xact_lock(hashtextextended('play_cap:' || new.student_id::text, 0));   -- คิวต่อคน: คำขอที่มาพร้อมกันรอกัน แล้วนับยอดใหม่
  if new.ref_key is not null and exists (select 1 from ledger where student_id = new.student_id and ref_key = new.ref_key) then return new; end if;
  if capx > 0 and new.exp > 0 then
    roomx := greatest(0, capx - _play_exp_today(new.student_id));
    if new.exp > roomx then cutx := new.exp - roomx; new.exp := roomx; note := note || ' ตัด EXP ' || cutx; end if;
  end if;
  if capc > 0 and new.coins > 0 then
    roomc := greatest(0, capc - _play_coins_today(new.student_id));
    if new.coins > roomc then cutc := new.coins - roomc; new.coins := roomc; note := note || ' ตัดเหรียญ ' || cutc; end if;
  end if;
  if cutx > 0 or cutc > 0 then
    new.reason := coalesce(new.reason, '') || ' (ครบเพดานจากการเล่นวันนี้ —' || note || ')';
    perform set_config('ch.play_cut', new.student_id::text || ':' || cutx || ':' || cutc, true);
  end if;
  return new;
end $$;
revoke execute on function trg_play_cap() from public, anon, authenticated;

-- SQL 120 · ปรับสมดุลรอบ 2: เพดานเพิ่มเล็กน้อย · ลดรางวัล Achievement/ดันเจี้ยน · ตัด EXP ที่ได้เกินเพดานย้อนหลัง
-- ต้องรันหลัง 119 · รันซ้ำได้ (แต่ละส่วนทำครั้งเดียว บันทึกใน bal_patch)
--   1) เพดานเล่นต่อวัน: EXP 100→120 · เหรียญ 150→180 (เปลี่ยนเฉพาะที่ยังเป็นค่าเริ่มต้น ถ้าครูตั้งเองไว้จะไม่ทับ)
--   2) รางวัล Achievement (EXP/เหรียญ) ลดเหลือ 50% (ผู้ที่รับไปแล้วไม่ถูกเรียกคืน)
--   3) ดันเจี้ยน: EXP/เหรียญต่อชั้น และ EXP/เหรียญในหีบ (loot_items ของ dungeon:*) ลดเหลือ 50%
--   4) ย้อนหลัง: แต่ละวันที่ EXP จากการเล่น (มินิเกม/ต่อสู้/ท้าดวล/ดันเจี้ยน/หีบ) เกินเพดานใหม่ → หัก "บางส่วน" (50% ของส่วนที่เกิน ปรับได้ที่ play_fix_pct) ออกจาก EXP นักเรียน
--      บันทึกรายวันใน exp_fix_log + แถว ledger "ปรับสมดุล EXP" (ref fix:exp120:<id>) · แก้เฉพาะ EXP ไม่เรียกคืนเหรียญที่ใช้ไปแล้ว
--
-- ดูตัวอย่างก่อนรันจริง (อ่านอย่างเดียว ไม่แก้ข้อมูล) — แต่ละแถวคือ นักเรียน/วัน ที่จะถูกหัก EXP:
--   select s.name, x.d, x.s as play_exp, x.s - 120 as cut from (
--     select student_id, (created_at at time zone 'Asia/Bangkok')::date d, sum(exp)::int s from ledger
--      where exp > 0 and (ref_key ~ '^(game|dungeon):' or (ref_key is null and reason ~ '^(ดรอปมอนสเตอร์|หีบดันเจี้ยน|รางวัลจากครูบุ๊ค)'))
--      group by 1, 2) x join students s on s.id = x.student_id where x.s > 120 order by cut desc;

create table if not exists bal_patch (key text primary key, done_at timestamptz not null default now());
alter table bal_patch enable row level security;
drop policy if exists teacher_all on bal_patch;
create policy teacher_all on bal_patch for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on bal_patch from anon;

create table if not exists exp_fix_log (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  day date not null, play_exp int not null, cap int not null, cut int not null,
  created_at timestamptz not null default now(), unique (student_id, day));
alter table exp_fix_log enable row level security;
drop policy if exists teacher_all on exp_fix_log;
create policy teacher_all on exp_fix_log for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on exp_fix_log from anon;

-- 1) เพดาน
update app_settings set value = '120' where key = 'play_daily_cap_exp' and value = '100';
update app_settings set value = '180' where key = 'play_daily_cap_coins' and value = '150';

-- 2) Achievement
do $$ begin
  if not exists (select 1 from bal_patch where key = 'ach_half') then
    update achievements set reward_exp = case when reward_exp > 0 then greatest(1, round(reward_exp * 0.5)::int) else 0 end,
                            reward_coins = case when reward_coins > 0 then greatest(1, round(reward_coins * 0.5)::int) else 0 end;
    insert into bal_patch (key) values ('ach_half');
  end if;
end $$;

-- 3) ดันเจี้ยน
do $$ begin
  if not exists (select 1 from bal_patch where key = 'dungeon_half') then
    update dungeon_floors set exp = greatest(1, round(exp * 0.5)::int), coins = greatest(1, round(coins * 0.5)::int);
    update loot_items set value = greatest(1, round(value * 0.5)::int) where source like 'dungeon:%' and kind in ('exp', 'coins');
    insert into bal_patch (key) values ('dungeon_half');
  end if;
end $$;

-- 4) แก้ประวัติ EXP เกินเพดานย้อนหลัง
create or replace function _fix_exp_history(p_cap int, p_pct int default 50) returns int
language plpgsql security definer set search_path = public as $$
declare r record; n int := 0; tot int;
begin
  if p_cap <= 0 then return 0; end if;
  insert into exp_fix_log (student_id, day, play_exp, cap, cut)
  select student_id, d, s, p_cap, ceil((s - p_cap) * least(100, greatest(0, p_pct)) / 100.0)::int from (
    select student_id, (created_at at time zone 'Asia/Bangkok')::date d, sum(exp)::int s from ledger
     where exp > 0 and _is_play_ledger(ref_key, reason) group by 1, 2) x
   where s > p_cap and p_pct > 0
  on conflict (student_id, day) do nothing;
  for r in select student_id, sum(cut)::int cut, count(*)::int days from exp_fix_log group by student_id loop
    if award(r.student_id, -r.cut, 0, 'ปรับสมดุล EXP: ตัดบางส่วนของ EXP ที่เกินเพดานการเล่น ' || r.days || ' วัน (รวม ' || r.cut || ')', 'fix:exp120:' || r.student_id) then n := n + 1; end if;
  end loop;
  return n;
end $$;
revoke execute on function _fix_exp_history(int, int) from public, anon, authenticated;

do $$ begin
  if not exists (select 1 from bal_patch where key = 'exp_history_fix') then
    perform _fix_exp_history(_setting_int('play_daily_cap_exp', 120), _setting_int('play_fix_pct', 50));
    insert into bal_patch (key) values ('exp_history_fix');
  end if;
end $$;

-- SQL 121 · แจ้งเตือนรายบุคคล (กระดิ่ง 🔔) + ข่าวหน้าแรกชุดใหม่ + ลบข่าว/อีเว้นท์ที่จบแล้ว
-- ต้องรันหลัง 120 · รันซ้ำได้ · ใช้แจ้งเรื่องปรับสมดุล EXP/เหรียญ (นักเรียนที่ถูกหัก EXP ย้อนหลังจะเห็นยอดของตัวเอง)

create table if not exists student_notices (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  ref text,                                   -- กันสร้างซ้ำ (student_id, ref)
  icon text not null default '📢', title text not null, body text,
  created_at timestamptz not null default now(), read_at timestamptz,
  unique (student_id, ref));
create index if not exists student_notices_sid on student_notices (student_id, created_at desc);
alter table student_notices enable row level security;
drop policy if exists teacher_all on student_notices;
create policy teacher_all on student_notices for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on student_notices from anon;

-- นักเรียนดูแจ้งเตือนของตัวเอง (ล่าสุด 30 รายการ)
create or replace function my_notices(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  return coalesce((select json_agg(x order by x.created_at desc) from (
    select id, icon, title, body, created_at, read_at is not null as read from student_notices
     where student_id = sid order by created_at desc limit 30) x), '[]'::json);
end $$;

-- ทำเครื่องหมายอ่านแล้ว (p_id ว่าง = ทั้งหมด)
create or replace function notice_read(p_token uuid, p_id uuid default null) returns void
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  update student_notices set read_at = now() where student_id = sid and read_at is null and (p_id is null or id = p_id);
end $$;
revoke execute on function my_notices(uuid), notice_read(uuid, uuid) from public;
grant execute on function my_notices(uuid), notice_read(uuid, uuid) to anon, authenticated;

-- สร้างประกาศปรับสมดุลให้นักเรียนทุกคน (+ ข้อความเฉพาะตัวถ้าโดนหัก EXP ย้อนหลัง) · ซ้ำไม่ได้
create or replace function _notice_balance() returns int
language plpgsql security definer set search_path = public as $$
declare r record; n int := 0; cx int := _setting_int('play_daily_cap_exp', 120); cc int := _setting_int('play_daily_cap_coins', 180);
begin
  for r in select s.id, coalesce(f.cut, 0) cut, coalesce(f.days, 0) days from students s
             left join (select student_id, sum(cut)::int cut, count(*)::int days from exp_fix_log group by student_id) f on f.student_id = s.id loop
    insert into student_notices (student_id, ref, icon, title, body) values (r.id, 'balance:2026-11', '⚖️', 'ปรับสมดุล EXP และเหรียญ',
      'EXP จากการเล่น (มินิเกม ต่อสู้ ท้าดวล ดันเจี้ยน หีบ) ได้สูงสุด ' || cx || ' ต่อวัน และเหรียญสูงสุด ' || cc || ' ต่อวัน · เช็คชื่อ/ส่งงาน/เควส/รางวัลครูไม่นับรวม · เกณฑ์แรงค์ Diamond ขึ้นไปยากขึ้นเล็กน้อย (Master 7,000 · Grandmaster 10,000 · Challenger 14,500) · รางวัล Achievement และดันเจี้ยนลดลงครึ่งหนึ่ง (ที่รับไปแล้วไม่เรียกคืน)')
      on conflict (student_id, ref) do nothing;
    if found then n := n + 1; end if;
    if r.cut > 0 then
      insert into student_notices (student_id, ref, icon, title, body) values (r.id, 'balance-cut:2026-11', '🔧', 'EXP ของคุณถูกปรับย้อนหลัง −' || r.cut,
        'ครูหัก EXP ส่วนที่เกินเพดานการเล่นรายวันออกบางส่วน (ครึ่งหนึ่งของส่วนที่เกิน) รวม ' || r.cut || ' EXP จาก ' || r.days || ' วัน · ดูรายการ "ปรับสมดุล EXP" ในประวัติ · เหรียญที่ใช้ไปแล้วไม่เรียกคืน · แรงค์อาจลดลงเล็กน้อยตามเกณฑ์ใหม่ ขอบคุณที่เข้าใจนะ 🙏')
        on conflict (student_id, ref) do nothing;
    end if;
  end loop;
  return n;
end $$;
revoke execute on function _notice_balance() from public, anon, authenticated;

do $$ begin
  if not exists (select 1 from bal_patch where key = 'notice_balance_121') then
    perform _notice_balance();
    -- ข่าวหน้าแรก: ลบที่จบแล้ว แล้วเพิ่มข่าวใหม่
    delete from news_posts where ends_at is not null and ends_at < today_th();
    insert into news_posts (kind, title, summary, body, sort, active, ends_at)
    select 'news', 'ปรับสมดุล EXP และเหรียญ ⚖️',
      'เล่นเกมได้ EXP สูงสุด 120 และเหรียญ 180 ต่อวัน · แรงค์ Diamond ขึ้นไปยากขึ้นเล็กน้อย',
      E'• EXP จากการเล่น (มินิเกม ต่อสู้ ท้าดวล ดันเจี้ยน หีบ) สูงสุด 120 ต่อวัน · เหรียญสูงสุด 180 ต่อวัน\n• เช็คชื่อ ส่งงาน เควส และรางวัลจากครู ไม่นับรวมในเพดาน\n• เกณฑ์แรงค์: Diamond 4,700 · Master 7,000 · Grandmaster 10,000 · Challenger 14,500 EXP\n• รางวัล Achievement และดันเจี้ยนลดลงครึ่งหนึ่ง (ที่รับไปแล้วไม่เรียกคืน)\n• วันที่ได้ EXP เกินเพดานมาก ครูหักส่วนเกินออกบางส่วน ดูในแจ้งเตือน 🔔 ของแต่ละคน',
      100, true, today_th() + 21
     where not exists (select 1 from news_posts where title = 'ปรับสมดุล EXP และเหรียญ ⚖️');
    insert into bal_patch (key) values ('notice_balance_121');
  end if;
end $$;
