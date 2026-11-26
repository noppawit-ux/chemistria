-- ===== รันไฟล์นี้ไฟล์เดียว: SQL 117–126 =====
-- ต้องรันหลัง SQL 100 และ 110–116 · รันซ้ำได้ (แต่ละส่วนทำครั้งเดียว) · ถ้าเคยรัน 117–121 แล้ว รันไฟล์นี้ซ้ำได้ ระบบข้ามส่วนที่ทำแล้ว
-- 117–121 ปรับสมดุล: เพดานเล่นต่อวัน · แรงค์ Diamond 4,700 / Master 7,000 / Grandmaster 10,000 / Challenger 14,500 · ลดรางวัล Achievement + ดันเจี้ยน 50% · หัก EXP เกินเพดานย้อนหลังบางส่วน · แจ้งเตือนรายบุคคล · ข่าวหน้าแรก
-- 122 ยกเพดาน EXP 150 / เหรียญ 200 ต่อวัน + โบนัสไล่ตามทัน (คนตามหลังค่ากลางห้อง เพดาน ×1.5–×2)
-- 123 กิจกรรมพลิกเกม (ประลองเป็นช่วงๆ อันดับ 1–3 ของห้องรับ EXP + เหรียญ · ครูตั้งที่หน้าครู → มินิเกม)
-- 125 ข่าวหน้าแรก: โหมดประลอง + มินิเกมปลูกผักเคมี (เร็วๆ นี้)
-- 124 ประลอง: ท้าดวลมีเดิมพัน (หักเหรียญตอนกดรับ ผู้ชนะได้กอง + EXP · เสมอคืน) + ลีกประลองรายสัปดาห์ (แต้ม → รางวัลอันดับ 1–3 ของห้อง) + โบนัสผู้ท้าชิง
-- 126 ห้องสมุด: อ่านบทความ/ดูวิดีโอครบเวลา + ตอบคำถามท้ายเรื่อง → รับ EXP/เหรียญ (ครูจัดการเนื้อหาที่แท็บมินิเกม)

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

-- SQL 122 · ยกเพดานเล่นต่อวัน + โบนัสไล่ตามทัน (catch-up) สำหรับคนที่ EXP ตามหลังห้อง
-- ต้องรันหลัง 121 · รันซ้ำได้ · ไม่แก้ award/battle_* (ขยายทริกเกอร์ trg_play_cap เดิม)
--  1) เพดานเล่นต่อวัน: EXP 120→150 · เหรียญ 180→200 (เปลี่ยนเฉพาะที่ยังเป็นค่า 120/180 ถ้าครูตั้งเองไว้จะไม่ทับ)
--  2) โบนัสไล่ตามทัน: เทียบ EXP ของนักเรียนกับค่ากลาง (median) ของห้อง (นับเฉพาะคนที่มี EXP > 0)
--       ต่ำกว่า 50% ของค่ากลาง → เพดาน ×2.0 · ต่ำกว่า 75% → ×1.5 · นอกนั้น ×1 (ครูแก้ได้: catchup_on = 1/0, catchup_t1/t2 = เปอร์เซ็นต์, catchup_m1/m2 = ตัวคูณ)
--       ใช้กับเพดาน EXP และเหรียญจากการเล่น · ไม่แตะรางวัลที่ครูกำหนด (เช็คชื่อ/ส่งงาน/เควส)

insert into app_settings (key, value) values
  ('catchup_on', '1'), ('catchup_t1', '50'), ('catchup_t2', '75'), ('catchup_m1', '2'), ('catchup_m2', '1.5')
on conflict (key) do nothing;
update app_settings set value = '150' where key = 'play_daily_cap_exp' and value = '120';
update app_settings set value = '200' where key = 'play_daily_cap_coins' and value = '180';

create or replace function _play_cap_mult(p_sid uuid) returns numeric
language plpgsql stable security definer set search_path = public as $$
declare me int; cls uuid; med numeric; r numeric;
begin
  if _setting_int('catchup_on', 1) <> 1 then return 1; end if;
  select exp, class_id into me, cls from students where id = p_sid;
  if me is null then return 1; end if;
  select percentile_cont(0.5) within group (order by exp) into med from students where class_id = cls and exp > 0;
  if med is null or med <= 0 then return 1; end if;
  r := me / med * 100;
  if r < _setting_int('catchup_t1', 50) then return coalesce(nullif((select value from app_settings where key = 'catchup_m1'), '')::numeric, 2); end if;
  if r < _setting_int('catchup_t2', 75) then return coalesce(nullif((select value from app_settings where key = 'catchup_m2'), '')::numeric, 1.5); end if;
  return 1;
end $$;
revoke execute on function _play_cap_mult(uuid) from public, anon, authenticated;

create or replace function trg_play_cap() returns trigger
language plpgsql security definer set search_path = public as $$
declare mult numeric; capx int := _setting_int('play_daily_cap_exp', 150); capc int := _setting_int('play_daily_cap_coins', 200);
        roomx int; roomc int; cutx int := 0; cutc int := 0; note text := '';
begin
  if (new.exp <= 0 and new.coins <= 0) or not _is_play_ledger(new.ref_key, new.reason) then return new; end if;
  if capx <= 0 and capc <= 0 then return new; end if;
  perform pg_advisory_xact_lock(hashtextextended('play_cap:' || new.student_id::text, 0));
  if new.ref_key is not null and exists (select 1 from ledger where student_id = new.student_id and ref_key = new.ref_key) then return new; end if;
  mult := _play_cap_mult(new.student_id);
  capx := ceil(capx * mult)::int; capc := ceil(capc * mult)::int;
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

-- สถานะในแอป: cap/coin_cap รวมตัวคูณแล้ว + boost (1 = ไม่มีโบนัส)
create or replace function play_exp_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); m numeric := _play_cap_mult(sid); cx int := _setting_int('play_daily_cap_exp', 150); cc int := _setting_int('play_daily_cap_coins', 200);
begin
  return json_build_object('cap', case when cx > 0 then ceil(cx * m)::int else 0 end, 'used', _play_exp_today(sid),
                           'coin_cap', case when cc > 0 then ceil(cc * m)::int else 0 end, 'coin_used', _play_coins_today(sid), 'boost', m);
end $$;

-- แจ้งนักเรียน: ข่าวหน้าแรก + แจ้งเตือนรายบุคคล (ครั้งเดียว)
do $$ begin
  if not exists (select 1 from bal_patch where key = 'catchup_122') then
    insert into student_notices (student_id, ref, icon, title, body)
    select id, 'catchup:2026-11', '🚀', 'เพิ่มเพดาน EXP + โบนัสไล่ตามทัน',
      'เพดาน EXP จากการเล่นเพิ่มเป็น 150 ต่อวัน และเหรียญ 200 ต่อวัน · ใครที่ EXP ตามหลังค่ากลางของห้อง จะได้เพดาน ×1.5 (ต่ำกว่า 75% ของค่ากลาง) หรือ ×2 (ต่ำกว่า 50%) อัตโนมัติ · ดูเพดานของตัวเองที่หน้ามินิเกม · ยิ่งตามหลังยิ่งไล่ทันเร็ว'
    from students on conflict (student_id, ref) do nothing;
    insert into news_posts (kind, title, summary, body, sort, active, ends_at)
    select 'news', 'โบนัสไล่ตามทัน 🚀', 'เพดาน EXP 150/วัน · คนที่ตามหลังห้องได้เพดาน ×1.5–×2',
      E'• เพดาน EXP จากการเล่นเพิ่มเป็น 150 ต่อวัน · เหรียญ 200 ต่อวัน\n• EXP ต่ำกว่า 75% ของค่ากลางห้อง → เพดาน ×1.5\n• EXP ต่ำกว่า 50% ของค่ากลางห้อง → เพดาน ×2\n• คิดอัตโนมัติทุกวัน ดูเพดานของตัวเองที่หน้ามินิเกม', 110, true, today_th() + 21
     where not exists (select 1 from news_posts where title = 'โบนัสไล่ตามทัน 🚀');
    insert into bal_patch (key) values ('catchup_122');
  end if;
end $$;

-- SQL 123 · กิจกรรมพลิกเกม ⚔️🔥 — ประลองเป็นช่วงๆ อันดับ 1–3 ของห้องรับ EXP + เหรียญก้อนใหญ่ (ไม่นับเพดานเล่นต่อวัน)
-- ต้องรันหลัง 122 · รันซ้ำได้ · ครูสร้างกิจกรรมที่หน้าครู → ตั้งค่า → กิจกรรมพลิกเกม
-- คะแนน: ดึงจาก game_plays ที่เซิร์ฟเวอร์ตรวจแล้ว (ควิซ/จับคู่/สเปลล์/ประลองครูบุ๊ค/เคมีรัน) ในช่วงวันที่ของกิจกรรม
--        เกมที่เลือก = เกมนั้นเกมเดียว (คะแนนสูงสุด) · เว้นว่าง = ทุกเกม (รวมคะแนนสูงสุดของแต่ละเกม → เก่งรอบด้าน)
-- พลิกเกม: คนที่ตามหลังค่ากลางห้อง (ตัวคูณไล่ตามทัน SQL 122) ได้คะแนนเพิ่ม ×1.25 ของ (ตัวคูณ−1) เช่น ×2 → +25% · ×1.5 → +12.5% (ปิดได้ที่ handicap)
-- จัดอันดับแยกตามห้อง (class) · จบกิจกรรมอัตโนมัติเมื่อพ้นวันสิ้นสุด (ครั้งแรกที่มีใครเปิดหน้าเกม) หรือครูสั่งปิดเอง · มอบรางวัลผ่านแจ้งเตือนรายบุคคล

create table if not exists flip_events (
  id uuid primary key default gen_random_uuid(),
  title text not null, descr text,
  game text check (game is null or game in ('quiz','match','spell','kb','run')),
  starts_on date not null default today_th(), ends_on date not null default today_th() + 6,
  handicap boolean not null default true,
  p1_exp int not null default 300, p1_coins int not null default 150,
  p2_exp int not null default 200, p2_coins int not null default 100,
  p3_exp int not null default 120, p3_coins int not null default 60,
  part_exp int not null default 20, part_coins int not null default 10,
  active boolean not null default true,
  finalized_at timestamptz, created_at timestamptz not null default now());
create table if not exists flip_results (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references flip_events(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  class_id uuid not null, rank int not null, score int not null, adj int not null,
  exp int not null default 0, coins int not null default 0,
  unique (event_id, student_id));
alter table flip_events enable row level security; alter table flip_results enable row level security;
drop policy if exists teacher_all on flip_events; drop policy if exists teacher_all on flip_results;
create policy teacher_all on flip_events for all to authenticated using (is_teacher()) with check (is_teacher());
create policy teacher_all on flip_results for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on flip_events, flip_results from anon;

-- อันดับสดของห้องหนึ่ง (ยังไม่ปิดกิจกรรม)
create or replace function _flip_board(p_event uuid, p_class uuid) returns table (student_id uuid, score int, adj int, rnk int)
language sql stable security definer set search_path = public as $$
  with e as (select * from flip_events where id = p_event),
  best as (
    select gp.student_id, gp.game, max(gp.score) s from game_plays gp
      join students st on st.id = gp.student_id and st.class_id = p_class, e
     where gp.play_date between e.starts_on and e.ends_on and gp.score > 0 and (e.game is null or gp.game = e.game)
     group by gp.student_id, gp.game),
  tot as (select b.student_id, sum(b.s)::int score from best b group by b.student_id)
  select t.student_id, t.score,
         round(t.score * (1 + case when (select handicap from e) then (_play_cap_mult(t.student_id) - 1) * 0.25 else 0 end))::int adj,
         (row_number() over (order by round(t.score * (1 + case when (select handicap from e) then (_play_cap_mult(t.student_id) - 1) * 0.25 else 0 end)) desc, t.score desc, t.student_id))::int rnk
    from tot t
$$;
revoke execute on function _flip_board(uuid, uuid) from public, anon, authenticated;

-- ปิดกิจกรรม: จัดอันดับทุกห้อง → แจกรางวัล + แจ้งเตือน (ซ้ำไม่ได้ ด้วย ref)
create or replace function _flip_finalize(p_event uuid) returns int
language plpgsql security definer set search_path = public as $$
declare e flip_events%rowtype; c record; r record; ex int; co int; n int := 0; lab text;
begin
  select * into e from flip_events where id = p_event for update;
  if not found or e.finalized_at is not null then return 0; end if;
  for c in select distinct class_id from students loop
    for r in select * from _flip_board(e.id, c.class_id) loop
      ex := e.part_exp + case r.rnk when 1 then e.p1_exp when 2 then e.p2_exp when 3 then e.p3_exp else 0 end;
      co := e.part_coins + case r.rnk when 1 then e.p1_coins when 2 then e.p2_coins when 3 then e.p3_coins else 0 end;
      lab := case r.rnk when 1 then '🥇 ชนะเลิศ' when 2 then '🥈 รองชนะเลิศ' when 3 then '🥉 อันดับ 3' else 'ร่วมกิจกรรม' end;
      insert into flip_results (event_id, student_id, class_id, rank, score, adj, exp, coins) values (e.id, r.student_id, c.class_id, r.rnk, r.score, r.adj, ex, co);
      perform award(r.student_id, ex, co, 'กิจกรรมพลิกเกม: ' || e.title || ' (' || lab || ')', 'flip:' || e.id || ':' || r.student_id);
      insert into student_notices (student_id, ref, icon, title, body) values (r.student_id, 'flip:' || e.id,
        case r.rnk when 1 then '🥇' when 2 then '🥈' when 3 then '🥉' else '🔥' end, 'ผลกิจกรรมพลิกเกม: ' || e.title,
        lab || ' · อันดับ ' || r.rnk || ' ของห้อง · คะแนน ' || r.adj || ' · ได้ ' || ex || ' EXP + ' || co || ' เหรียญ') on conflict (student_id, ref) do nothing;
      n := n + 1;
    end loop;
  end loop;
  update flip_events set finalized_at = now() where id = e.id;
  return n;
end $$;
revoke execute on function _flip_finalize(uuid) from public, anon, authenticated;

-- ครูกดปิดกิจกรรมเอง
create or replace function flip_close(p_event uuid) returns int
language plpgsql security definer set search_path = public as $$
begin
  if not is_teacher() then raise exception 'เฉพาะครู'; end if;
  return _flip_finalize(p_event);
end $$;
revoke execute on function flip_close(uuid) from public, anon; grant execute on function flip_close(uuid) to authenticated;

-- นักเรียนดูกิจกรรม (กำลังจัด + ที่จบใน 14 วัน) พร้อมอันดับห้องตัวเอง
create or replace function flip_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cls uuid; e record; out json[] := '{}'; top json; me json; fin boolean;
begin
  select class_id into cls from students where id = sid;
  for e in select * from flip_events where active and ends_on < today_th() and finalized_at is null loop perform _flip_finalize(e.id); end loop;
  for e in select * from flip_events where active and starts_on <= today_th() + 3 and (finalized_at is null or finalized_at > now() - interval '14 days') order by starts_on desc limit 3 loop
    fin := e.finalized_at is not null;
    if fin then
      select coalesce(json_agg(x order by x.rank), '[]'::json) into top from (
        select r.rank, s.name, s.avatar, r.adj as score from flip_results r join students s on s.id = r.student_id where r.event_id = e.id and r.class_id = cls and r.rank <= 10) x;
      select row_to_json(x) into me from (select rank, adj as score, exp, coins from flip_results where event_id = e.id and student_id = sid) x;
    else
      select coalesce(json_agg(x order by x.rank), '[]'::json) into top from (
        select b.rnk as rank, s.name, s.avatar, b.adj as score from _flip_board(e.id, cls) b join students s on s.id = b.student_id where b.rnk <= 10) x;
      select row_to_json(x) into me from (select rnk as rank, adj as score, score as raw from _flip_board(e.id, cls) where student_id = sid) x;
    end if;
    out := out || json_build_object('id', e.id, 'title', e.title, 'descr', e.descr, 'game', e.game, 'starts_on', e.starts_on, 'ends_on', e.ends_on,
      'handicap', e.handicap, 'done', fin, 'upcoming', e.starts_on > today_th(),
      'prizes', json_build_array(json_build_object('exp', e.p1_exp, 'coins', e.p1_coins), json_build_object('exp', e.p2_exp, 'coins', e.p2_coins), json_build_object('exp', e.p3_exp, 'coins', e.p3_coins)),
      'part', json_build_object('exp', e.part_exp, 'coins', e.part_coins),
      'top', top, 'me', me, 'boost', _play_cap_mult(sid));
  end loop;
  return array_to_json(out);
end $$;
revoke execute on function flip_status(uuid) from public; grant execute on function flip_status(uuid) to anon, authenticated;

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

-- SQL 125 · ข่าวหน้าแรก: โหมดประลอง (เดิมพัน + ลีก) และมินิเกมปลูกผักเคมี (เร็วๆ นี้)
-- ต้องรันหลัง 124 · รันซ้ำได้ (กันซ้ำด้วยชื่อข่าว) · ภาพ assets/news/duel.jpg, farm.jpg
delete from news_posts where ends_at is not null and ends_at < today_th();
insert into news_posts (kind, title, summary, body, image, sort, active, ends_at)
select 'news', 'โหมดประลองใหม่: ท้าดวลเดิมพัน + ลีกประจำสัปดาห์ ⚔️🏆',
  'วางเดิมพันเหรียญกับเพื่อน ผู้ชนะได้ทั้งกอง · สะสมแต้มลีก อันดับ 1–3 ของห้องรับรางวัลทุกสัปดาห์',
  E'• ท้าดวลเพื่อนแบบมีเดิมพัน 0–30 เหรียญ (ทั้งสองฝ่ายวางเท่ากัน) ผู้ชนะ (ดวลครบ 3 รอบขึ้นไป) ได้เหรียญทั้งกอง + EXP · เสมอหรือออกก่อน 3 รอบ = คืนเดิมพัน\n• ชนะคนที่ EXP สูงกว่ามาก ได้โบนัสผู้ท้าชิง\n• ลีกประลองประจำสัปดาห์ (จันทร์–อาทิตย์): ชนะ +30 · เสมอ +10 · แพ้ +5 แต้ม ชนะคนแต้มสูงกว่าได้โบนัส\n• จบสัปดาห์ อันดับ 1–3 ของห้อง (ต้องมี ≥ 30 แต้ม) รับ EXP + เหรียญ และมีแจ้งเตือนที่กระดิ่ง\n• เล่นที่ ศูนย์เกม → โดโจ (ต้องรีเฟรชหน้าเว็บให้เป็นเวอร์ชัน 2.80)',
  'assets/news/duel.jpg', 120, true, today_th() + 30
 where not exists (select 1 from news_posts where title = 'โหมดประลองใหม่: ท้าดวลเดิมพัน + ลีกประจำสัปดาห์ ⚔️🏆');
insert into news_posts (kind, title, summary, body, image, sort, active, ends_at)
select 'news', 'เร็วๆ นี้: มินิเกมปลูกผักเคมี 🌱',
  'มินิเกมใหม่ ปลูก รดน้ำ ใส่ปุ๋ยให้ถูกสูตร แล้วเก็บเกี่ยวรางวัล — รอติดตามได้เลย',
  E'• มินิเกมใหม่ "ปลูกผักเคมี" กำลังจะมา\n• ปลูกผัก รดน้ำ ใส่ปุ๋ยให้ถูกสูตรเคมี แล้วเก็บเกี่ยวรางวัล\n• ยังไม่เปิดให้เล่น ติดตามข่าวในหน้านี้ได้เลย',
  'assets/news/farm.jpg', 110, true, today_th() + 30
 where not exists (select 1 from news_posts where title = 'เร็วๆ นี้: มินิเกมปลูกผักเคมี 🌱');

-- SQL 126 · ห้องสมุด 📚 — บทความ/วิดีโอให้นักเรียนอ่านหรือดูจนครบแล้วรับ EXP/เหรียญ
-- ต้องรันหลัง 125 · รันซ้ำได้ · ครูเพิ่มเนื้อหาที่หน้าครู → แท็บมินิเกม → ห้องสมุด
-- กติกา: เปิดอ่านแล้วเริ่มจับเวลา (ฝั่งเซิร์ฟเวอร์) · กดรับรางวัลได้เมื่อครบเวลาขั้นต่ำ (min_secs) และตอบคำถามท้ายเรื่องถูก (ถ้าครูตั้งไว้)
--        รับได้ครั้งเดียวต่อเรื่อง (ref lib:*) · จำกัดจำนวนเรื่องที่ได้รางวัลต่อวัน library_daily_max (ตั้งเป็น 0 = ไม่จำกัด)
--        รางวัลห้องสมุดไม่ถูกเพดาน EXP/เหรียญจากการเล่นเกม

insert into app_settings(key, value) values ('library_daily_max', '5') on conflict (key) do nothing;

create table if not exists library_items (
  id uuid primary key default gen_random_uuid(),
  class_id uuid references classes(id) on delete cascade,      -- ว่าง = ทุกห้อง
  kind text not null default 'article' check (kind in ('article', 'video')),
  title text not null, summary text, icon text not null default '📖', category text,
  body text,                                                     -- บทความ (ขึ้นบรรทัดใหม่ได้ · บรรทัดขึ้นต้น "# " = หัวข้อ)
  url text check (url is null or url = '' or url ~ '^https?://'),            -- วิดีโอ YouTube หรือลิงก์ภายนอก
  min_secs int not null default 60 check (min_secs >= 0),
  exp int not null default 10 check (exp >= 0), coins int not null default 5 check (coins >= 0),
  q_text text, q_opts text, q_ans int check (q_ans is null or q_ans >= 1),   -- ตัวเลือกคั่นด้วย | · q_ans เริ่มที่ 1
  sort int not null default 0, active boolean not null default true, created_at timestamptz not null default now());
create table if not exists library_reads (
  student_id uuid not null references students(id) on delete cascade,
  item_id uuid not null references library_items(id) on delete cascade,
  started_at timestamptz not null default now(), done_at timestamptz, exp int not null default 0, coins int not null default 0,
  primary key (student_id, item_id));
do $$ declare t text; begin
  foreach t in array array['library_items', 'library_reads'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists teacher_all on public.%I', t);
    execute format('create policy teacher_all on public.%I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on public.%I from anon', t);
  end loop; end $$;

create or replace function library_list(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cls uuid;
begin
  select class_id into cls from students where id = sid;
  return json_build_object(
    'today', (select count(*) from library_reads where student_id = sid and done_at >= today_th()::timestamp at time zone 'Asia/Bangkok'),
    'limit', _setting_int('library_daily_max', 5),
    'items', (select coalesce(json_agg(json_build_object('id', i.id, 'kind', i.kind, 'title', i.title, 'summary', i.summary, 'icon', i.icon, 'category', i.category,
          'min_secs', i.min_secs, 'exp', i.exp, 'coins', i.coins, 'quiz', nullif(btrim(i.q_text), '') is not null, 'started', r.started_at is not null, 'done', r.done_at is not null)
          order by (r.done_at is not null), i.sort desc, i.created_at desc), '[]'::json)
        from library_items i left join library_reads r on r.item_id = i.id and r.student_id = sid
       where i.active and (i.class_id is null or i.class_id = cls)));
end $$;

create or replace function library_open(p_token uuid, p_item uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cls uuid; i library_items%rowtype; r library_reads%rowtype;
begin
  select class_id into cls from students where id = sid;
  select * into i from library_items where id = p_item and active and (class_id is null or class_id = cls);
  if not found then raise exception 'ไม่พบเนื้อหานี้'; end if;
  insert into library_reads (student_id, item_id) values (sid, i.id) on conflict do nothing;
  select * into r from library_reads where student_id = sid and item_id = i.id;
  return json_build_object('id', i.id, 'kind', i.kind, 'title', i.title, 'icon', i.icon, 'summary', i.summary, 'body', i.body, 'url', i.url,
    'min_secs', i.min_secs, 'exp', i.exp, 'coins', i.coins, 'done', r.done_at is not null,
    'elapsed', greatest(0, floor(extract(epoch from now() - r.started_at))::int),
    'q', case when nullif(btrim(i.q_text), '') is null then null else json_build_object('text', i.q_text, 'opts', string_to_array(coalesce(i.q_opts, ''), '|')) end,
    'got', case when r.done_at is not null then json_build_object('exp', r.exp, 'coins', r.coins) end);
end $$;

create or replace function library_finish(p_token uuid, p_item uuid, p_pick int default null) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cls uuid; i library_items%rowtype; r library_reads%rowtype; lim int := _setting_int('library_daily_max', 5); n int; el int;
begin
  select class_id into cls from students where id = sid;
  select * into i from library_items where id = p_item and active and (class_id is null or class_id = cls);
  if not found then raise exception 'ไม่พบเนื้อหานี้'; end if;
  select * into r from library_reads where student_id = sid and item_id = i.id for update;
  if not found then raise exception 'ต้องเปิดอ่านก่อน'; end if;
  if r.done_at is not null then return json_build_object('already', true, 'exp', r.exp, 'coins', r.coins); end if;
  el := floor(extract(epoch from now() - r.started_at))::int;
  if el < i.min_secs then raise exception 'ยังอ่าน/ดูไม่ครบเวลา (อีก % วินาที)', i.min_secs - el; end if;
  if nullif(btrim(i.q_text), '') is not null and (p_pick is null or p_pick <> i.q_ans) then raise exception 'ตอบคำถามท้ายเรื่องยังไม่ถูก ลองอ่านทบทวนแล้วตอบใหม่'; end if;
  select count(*) into n from library_reads where student_id = sid and done_at >= today_th()::timestamp at time zone 'Asia/Bangkok';
  if lim > 0 and n >= lim then raise exception 'วันนี้รับรางวัลห้องสมุดครบ % เรื่องแล้ว พรุ่งนี้มาอ่านต่อ', lim; end if;
  perform award(sid, i.exp, i.coins, 'ห้องสมุด: ' || i.title, 'lib:' || i.id || ':' || sid);
  update library_reads set done_at = now(), exp = i.exp, coins = i.coins where student_id = sid and item_id = i.id;
  return json_build_object('exp', i.exp, 'coins', i.coins);
end $$;

revoke execute on function library_list(uuid), library_open(uuid, uuid), library_finish(uuid, uuid, int) from public;
grant execute on function library_list(uuid), library_open(uuid, uuid), library_finish(uuid, uuid, int) to anon, authenticated;

-- เนื้อหาตัวอย่าง 2 เรื่อง (ครูแก้/ลบได้)
insert into library_items (kind, title, summary, icon, category, body, min_secs, exp, coins, q_text, q_opts, q_ans, sort)
select 'article', 'อะตอมคืออะไร', 'อนุภาคเล็กที่สุดของธาตุ ประกอบด้วยโปรตอน นิวตรอน และอิเล็กตรอน', '⚛️', 'พื้นฐานเคมี',
  E'# อะตอม\nสารทุกอย่างรอบตัวประกอบด้วยอะตอม อะตอมเป็นหน่วยเล็กที่สุดของธาตุที่ยังคงสมบัติของธาตุนั้นไว้\n# ส่วนประกอบของอะตอม\n• โปรตอน (p) มีประจุบวก อยู่ในนิวเคลียส\n• นิวตรอน (n) ไม่มีประจุ อยู่ในนิวเคลียส\n• อิเล็กตรอน (e) มีประจุลบ เคลื่อนที่รอบนิวเคลียส\n# เลขอะตอม\nเลขอะตอมคือจำนวนโปรตอนในนิวเคลียส ธาตุแต่ละชนิดมีเลขอะตอมไม่เหมือนกัน เช่น ไฮโดรเจนมี 1 โปรตอน คาร์บอนมี 6 โปรตอน\nอะตอมที่เป็นกลางทางไฟฟ้ามีจำนวนอิเล็กตรอนเท่ากับจำนวนโปรตอน',
  30, 5, 3, 'อะตอมของคาร์บอนมีกี่โปรตอน', 'ไม่มีโปรตอน|1 ตัว|6 ตัว|12 ตัวเสมอ', 3, 10
 where not exists (select 1 from library_items where title = 'อะตอมคืออะไร');
insert into library_items (kind, title, summary, icon, category, body, min_secs, exp, coins, q_text, q_opts, q_ans, sort)
select 'article', 'อ่านตารางธาตุให้เป็น', 'คาบ หมู่ และตำแหน่งของธาตุบอกอะไรเราได้บ้าง', '🧪', 'พื้นฐานเคมี',
  E'# ตารางธาตุจัดอย่างไร\nตารางธาตุเรียงธาตุตามเลขอะตอมจากน้อยไปมาก\n• แถวแนวนอนเรียกว่า คาบ\n• แถวแนวตั้งเรียกว่า หมู่\n# ธาตุในหมู่เดียวกัน\nธาตุที่อยู่หมู่เดียวกันมีสมบัติทางเคมีคล้ายกัน เพราะมีจำนวนเวเลนซ์อิเล็กตรอนเท่ากัน เช่น ลิเทียม โซเดียม โพแทสเซียม อยู่หมู่ 1 ทำปฏิกิริยากับน้ำได้รุนแรง\n# โลหะ อโลหะ และกึ่งโลหะ\nธาตุส่วนใหญ่เป็นโลหะอยู่ด้านซ้ายและกลางตาราง อโลหะอยู่ด้านขวาบน และมีกึ่งโลหะคั่นอยู่ตามแนวขั้นบันได',
  30, 5, 3, 'ธาตุที่อยู่หมู่เดียวกันมีสมบัติคล้ายกัน เพราะเหตุใด', 'มีเลขอะตอมเท่ากัน|มีเวเลนซ์อิเล็กตรอนเท่ากัน|อยู่คาบเดียวกัน|มีมวลเท่ากัน', 2, 9
 where not exists (select 1 from library_items where title = 'อ่านตารางธาตุให้เป็น');

-- ข่าวหน้าแรก
delete from news_posts where ends_at is not null and ends_at < today_th();
insert into news_posts (kind, title, summary, body, image, sort, active, ends_at)
select 'news', 'เปิดห้องสมุดแล้ว 📚 อ่าน/ดูแล้วรับ EXP และเหรียญ',
  'อ่านบทความหรือดูวิดีโอให้ครบ ตอบคำถามท้ายเรื่อง รับ EXP + เหรียญ',
  E'• เข้าได้จาก หอสมุดอะตอม ในแผนที่เมือง หรือรายการเกม\n• อ่าน/ดูให้ครบเวลาที่กำหนด แล้วตอบคำถามท้ายเรื่องให้ถูก\n• รับรางวัลได้ครั้งเดียวต่อเรื่อง และไม่เกิน 5 เรื่องต่อวัน\n• ต้องรีเฟรชหน้าเว็บให้เป็นเวอร์ชัน 2.82',
  'assets/news/promo.jpg', 130, true, today_th() + 30
 where not exists (select 1 from news_posts where title = 'เปิดห้องสมุดแล้ว 📚 อ่าน/ดูแล้วรับ EXP และเหรียญ');
