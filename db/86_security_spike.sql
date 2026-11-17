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
