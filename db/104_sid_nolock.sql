-- 104: แก้คอขวด _sid — ทุกคำสั่งของนักเรียนอัปเดตแถวเซสชันเดียวกัน (ตัวนับกันสแปม) แล้วล็อกแถวค้างจนจบคำสั่ง
--      → นักเรียน 1 คนยิง 10+ คำสั่งพร้อมกันตอนเปิดหน้า จึงต้องต่อคิวรอกันเอง (คำของ่ายๆ ก็เฉลี่ย ~250 ms)
--  · เปลี่ยนเป็น: ตรวจเซสชันด้วยการอ่านธรรมดา (ไม่ล็อก) · นับด้วย FOR UPDATE SKIP LOCKED
--    ถ้าคำสั่งอื่นของคนเดียวกันกำลังนับอยู่ ข้ามการนับรอบนี้แทนการรอ (ตัวนับคลาดเคลื่อนเล็กน้อยได้ ไม่กระทบการกันบอท)
--  · พฤติกรรมอื่นเหมือนเดิม: เซสชันหมดอายุ → error เดิม · เกินเกณฑ์/ถึงเกณฑ์ → error/บันทึก rate_abuse เดิม · โหมดส่องดูได้อย่างเดียว
create or replace function _sid(p_token uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare v uuid; o boolean; fn text; n int; lim int := _setting_int('sec_rpc_per_min', 240);
begin
  select student_id, observer into v, o from student_sessions where token = p_token and expires_at > now();
  if v is null then raise exception 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่'; end if;
  with c as (select token from student_sessions where token = p_token for update skip locked)
  update student_sessions s
     set win_n = case when s.win_start is null or s.win_start < now() - interval '1 minute' then 1 else s.win_n + 1 end,
         win_start = case when s.win_start is null or s.win_start < now() - interval '1 minute' then now() else s.win_start end
    from c where s.token = c.token
  returning s.win_n into n;
  if n is not null and n > lim then raise exception 'ส่งคำสั่งถี่เกินไป กรุณารอสักครู่'; end if;
  if n is not null and n = lim then
    perform _sec_log('rate_abuse', 'high', v, 'ส่งคำสั่งถึง ' || lim || ' ครั้งใน 1 นาที (อาจเป็นสคริปต์/บอท)', 'rate:' || v || ':' || to_char(now(), 'YYYYMMDDHH24MI'));
  end if;
  if o then
    fn := regexp_replace(coalesce(current_setting('request.path', true), ''), '^.*/', '');
    if fn not in ('student_dashboard','student_extras','hall_of_fame','board_list','celebrations_feed','game_status','spell_status','kb_status','news_list','run_status','timetable_list','promo_status','guild_status','guild_board') then
      raise exception 'โหมดส่องนักเรียน: ดูได้อย่างเดียว';
    end if;
  end if;
  return v;
end $$;
