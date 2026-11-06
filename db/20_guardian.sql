-- =====================================================================
-- รอบที่ 25b: เปลี่ยนความสามารถ “ผู้พิทักษ์” → โล่ทีม (ช่วยเพื่อน/ลดโทษ)
-- เดิม: ตัวผู้พิทักษ์เองมาสาย/ส่งช้าได้เต็ม · ใหม่: เพื่อนร่วมทีมที่มี “ผู้พิทักษ์” อยู่ด้วย
-- มาสาย/ส่งงานช้าแล้วยังได้รางวัลเต็ม (ตัวผู้พิทักษ์เองได้ตามปกติ) · รันซ้ำได้
-- =====================================================================
create or replace function _guardian_cover(p_student uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from students me
    join students g on g.team_id = me.team_id and g.id <> me.id and g.char_class = 'guardian'
    where me.id = p_student and me.team_id is not null)
$$;
revoke execute on function _guardian_cover(uuid) from public, anon, authenticated;

create or replace function trg_attendance() returns trigger
language plpgsql security definer set search_path = public as $$
declare v uuid;
begin
  if new.status = 'present' then
    perform award(new.student_id, 5, 2, 'มาเรียนตรงเวลา ' || new.att_date, 'att:' || new.id);
  elsif new.status = 'late' then
    if _guardian_cover(new.student_id) then
      perform award(new.student_id, 5, 2, 'มาเรียน (สาย — ผู้พิทักษ์ในทีมช่วยไว้) ' || new.att_date, 'att:' || new.id);
    else
      perform award(new.student_id, 2, 1, 'มาเรียน (สาย) ' || new.att_date, 'att:' || new.id);
    end if;
  end if;

  if new.status in ('present', 'late') and new.att_date >= today_th() - 3 then
    -- ตั๋วสุ่มกาชาฟรี 1 ใบต่อการเข้าเรียนหนึ่งครั้ง (กันซ้ำด้วย ledger)
    v := null;
    insert into ledger (student_id, exp, coins, reason, ref_key)
    values (new.student_id, 0, 0, 'ตั๋วสุ่มกาชาฟรี (เช็คชื่อ ' || new.att_date || ')', 'attticket:' || new.id)
    on conflict (student_id, ref_key) do nothing returning id into v;
    if v is not null then update students set free_pulls = free_pulls + 1 where id = new.student_id; end if;

    -- เควสที่ตั้งเป็น “สำเร็จอัตโนมัติเมื่อเช็คชื่อ”
    perform _auto_quests(new.student_id, 'attendance', new.att_date);
  end if;
  perform check_achievements(new.student_id);
  return new;
end $$;

create or replace function trg_submission() returns trigger
language plpgsql security definer set search_path = public as $$
declare a ch_assignments%rowtype; ref text;
begin
  select * into a from ch_assignments where id = new.assignment_id;
  ref := 'sub:' || new.id || case when new.attempt > 1 then ':' || new.attempt else '' end;
  if new.status = 'submitted' then
    perform award(new.student_id, a.exp_reward, a.coin_reward, 'ส่งงาน: ' || a.title, ref);
  elsif new.status = 'late' then
    if _guardian_cover(new.student_id) then
      perform award(new.student_id, a.exp_reward, a.coin_reward, 'ส่งงาน (ช้า — ผู้พิทักษ์ในทีมช่วยไว้): ' || a.title, ref);
    else
      perform award(new.student_id, a.exp_reward / 2, a.coin_reward / 2, 'ส่งงาน (ช้า): ' || a.title, ref);
    end if;
  end if;
  if new.status in ('submitted', 'late') then perform _auto_quests(new.student_id, 'submit'); end if;
  perform check_achievements(new.student_id);
  return new;
end $$;


update char_classes set
  description = 'ปกป้องเพื่อนร่วมทีม',
  ability = 'เพื่อนในทีมเดียวกับผู้พิทักษ์ มาสาย/ส่งงานช้า ยังได้รางวัลเต็ม (ต้องอยู่ทีมเดียวกัน)'
where key = 'guardian' and ability = 'มาสาย/ส่งงานช้า ได้รางวัลเต็ม เหมือนตรงเวลา';
