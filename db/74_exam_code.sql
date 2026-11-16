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
