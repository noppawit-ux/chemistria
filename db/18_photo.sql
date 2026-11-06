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
