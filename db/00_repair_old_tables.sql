-- กู้ตารางของระบบ KruBook เก่า (players, quiz_log, attendance, assignments, submissions)
-- หลังรอบแรกของ Chemistria ไปแตะโดยไม่ตั้งใจ — รันซ้ำได้ ไม่แตะข้อมูล
drop trigger if exists attendance_award on public.attendance;
drop trigger if exists submission_award on public.submissions;
do $$
declare t text;
begin
  foreach t in array array['players','quiz_log','attendance','assignments','submissions'] loop
    execute format('drop policy if exists teacher_all on public.%I', t);
    execute format('grant select, insert, update, delete on public.%I to anon, authenticated', t);
  end loop;
end $$;
