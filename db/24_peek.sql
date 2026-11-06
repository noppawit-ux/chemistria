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
