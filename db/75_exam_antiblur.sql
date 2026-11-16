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
