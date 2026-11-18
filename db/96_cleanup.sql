-- 96: คลีนระบบ + เพิ่มดัชนีให้ทำงานคล่องขึ้น (รันซ้ำได้)
--  · admin_cleanup(p_apply) : ครูเรียกจากแท็บ "ระบบ/สำรองข้อมูล" — false = ดูจำนวนก่อน (ไม่ลบ), true = ลบจริง
--  · ลบเฉพาะบันทึกชั่วคราว/ล็อกเก่าที่ไม่กระทบ EXP เหรียญ ความสำเร็จ สถิติ หรือประวัติการเล่น (ledger, game_plays, battles, ch_* ไม่แตะ)
--  · ดัชนี: เพิ่มเฉพาะที่ยังไม่มี (ถ้าตาราง/คอลัมน์ไม่ตรงจะข้ามเงียบๆ)
do $$ declare r record; begin
  for r in select * from (values
    ('idx_quest_claims_student', 'quest_claims', 'student_id, claim_date'),
    ('idx_gacha_pulls_student', 'gacha_pulls', 'student_id, created_at desc'),
    ('idx_game_plays_game', 'game_plays', 'student_id, game'),
    ('idx_battles_student_status', 'battles', 'student_id, status'),
    ('idx_exam_attempts_student', 'exam_attempts', 'student_id'),
    ('idx_scores_student', 'scores', 'student_id'),
    ('idx_redemptions_student', 'redemptions', 'student_id'),
    ('idx_ledger_created', 'ledger', 'created_at desc'),
    ('idx_student_sessions_student', 'student_sessions', 'student_id'),
    ('idx_student_sessions_exp', 'student_sessions', 'expires_at'),
    ('idx_students_class', 'students', 'class_id'),
    ('idx_card_drops_student', 'card_drops', 'student_id, created_at desc')
  ) v(n, t, c) loop
    begin execute format('create index if not exists %I on public.%I (%s)', r.n, r.t, r.c);
    exception when others then null; end;
  end loop;
end $$;

create or replace function admin_cleanup(p_apply boolean default false) returns json
language plpgsql security definer set search_path = public as $$
declare out jsonb := '[]'::jsonb; n int; today date := today_th();
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;

  select count(*) into n from student_sessions where expires_at < now() - interval '7 days';
  if p_apply then delete from student_sessions where expires_at < now() - interval '7 days'; end if;
  out := out || jsonb_build_object('key', 'sessions', 'label', 'เซสชันเข้าสู่ระบบที่หมดอายุเกิน 7 วัน', 'n', n);

  select count(*) into n from login_attempts where at < now() - interval '3 days';
  if p_apply then delete from login_attempts where at < now() - interval '3 days'; end if;
  out := out || jsonb_build_object('key', 'logins', 'label', 'บันทึกการล็อกอินผิดเกิน 3 วัน', 'n', n);

  select count(*) into n from security_events where seen and at < now() - interval '90 days';
  if p_apply then delete from security_events where seen and at < now() - interval '90 days'; end if;
  out := out || jsonb_build_object('key', 'secev', 'label', 'เหตุผิดปกติที่ดูแล้วและเก่าเกิน 90 วัน', 'n', n);

  select count(*) into n from upload_slots where used or expires_at < now() - interval '1 day';
  if p_apply then delete from upload_slots where used or expires_at < now() - interval '1 day'; end if;
  out := out || jsonb_build_object('key', 'slots', 'label', 'สิทธิ์อัปโหลดงานที่ใช้แล้ว/หมดอายุ', 'n', n);

  select count(*) into n from item_daily where day < today - 7;
  if p_apply then delete from item_daily where day < today - 7; end if;
  out := out || jsonb_build_object('key', 'itemday', 'label', 'ตัวนับซื้อไอเทมรายวันเกิน 7 วัน', 'n', n);

  select count(*) into n from student_buffs where day < today;
  if p_apply then delete from student_buffs where day < today; end if;
  out := out || jsonb_build_object('key', 'buffs', 'label', 'บัฟรายวันที่หมดอายุแล้ว', 'n', n);

  select count(*) into n from celebrations where created_at < now() - interval '30 days';
  if p_apply then delete from celebrations where created_at < now() - interval '30 days'; end if;
  out := out || jsonb_build_object('key', 'celeb', 'label', 'ข่าวฉลอง SSR/เลื่อนแรงค์ เกิน 30 วัน', 'n', n);

  select count(*) into n from gift_log where seen and at < now() - interval '90 days';
  if p_apply then delete from gift_log where seen and at < now() - interval '90 days'; end if;
  out := out || jsonb_build_object('key', 'giftlog', 'label', 'ประวัติของขวัญเพื่อนที่อ่านแล้วเกิน 90 วัน (คะแนนมิตรภาพยังอยู่)', 'n', n);

  select count(*) into n from card_drops where created_at < now() - interval '90 days';
  if p_apply then delete from card_drops where created_at < now() - interval '90 days'; end if;
  out := out || jsonb_build_object('key', 'drops', 'label', 'ประวัติการดรอปการ์ดเกิน 90 วัน (การ์ดที่ได้ยังอยู่)', 'n', n);

  select count(*) into n from duels where status in ('declined', 'cancelled', 'expired') and created_at < now() - interval '14 days';
  if p_apply then delete from duels where status in ('declined', 'cancelled', 'expired') and created_at < now() - interval '14 days'; end if;
  out := out || jsonb_build_object('key', 'duels', 'label', 'คำท้าดวลที่ถูกปฏิเสธ/ยกเลิก/หมดเวลา เกิน 14 วัน', 'n', n);

  select count(*) into n from exam_code_fails where first_at < now() - interval '30 days';
  if p_apply then delete from exam_code_fails where first_at < now() - interval '30 days'; end if;
  out := out || jsonb_build_object('key', 'examfail', 'label', 'บันทึกใส่รหัสสอบผิดเกิน 30 วัน', 'n', n);

  return json_build_object('applied', p_apply, 'total', (select coalesce(sum((x->>'n')::int), 0) from jsonb_array_elements(out) x), 'items', out);
end $$;
revoke execute on function admin_cleanup(boolean) from public, anon;
grant execute on function admin_cleanup(boolean) to authenticated;
