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
