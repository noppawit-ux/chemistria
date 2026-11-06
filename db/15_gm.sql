-- =====================================================================
-- Chemistria · รอบที่ 15: ไอดี GM (ปลดล็อคทุกอย่าง) (รันซ้ำได้)
--  · สร้างห้องลับ "GM" (ไม่โผล่ในรายชื่อห้องหน้าล็อกอิน) + นักเรียนเลขที่ 1 = ไอดี GM แยกจากห้องจริง จึงไม่กระทบอันดับ/บอส/ทีมของห้องไหน
--  · ปลดล็อค: ไอเทมตกแต่งทุกชิ้น · ไอเทมกาชาทุกชิ้น · Achievement ทุกอัน · สิทธิพิเศษทุกอย่าง · EXP/เหรียญสูงสุด (แรงค์สูงสุด) · สเตตัสพื้นฐานเต็ม 10
--  · ครูสร้างที่แอดมิน > ตั้งค่า > “ไอดี GM” โดยตั้ง PIN เอง (ไม่มี PIN ตายตัวในโค้ด) · กดซ้ำเพื่อซิงก์ของใหม่ที่เพิ่มทีหลัง
--  ล็อกอิน: รหัสห้อง GM · เลขที่ 1 · PIN ที่ตั้งไว้
-- =====================================================================
alter table classes add column if not exists hidden boolean not null default false;
alter table students add column if not exists is_gm boolean not null default false;

create or replace function list_classes() returns json
language sql stable security definer set search_path = public as $$
  select coalesce(json_agg(json_build_object('code', code, 'name', name, 'subject', subject_name) order by name), '[]'::json)
  from classes where not hidden
$$;

create or replace function _gm_unlock(p_sid uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  insert into student_decor (student_id, item_id, source) select p_sid, id, 'teacher' from decor_items on conflict do nothing;
  insert into inventory (student_id, item_id, qty) select p_sid, id, 1 from gacha_items on conflict (student_id, item_id) do nothing;
  insert into student_achievements (student_id, achievement_id) select p_sid, id from achievements on conflict do nothing;
  insert into redemptions (student_id, privilege_id, source, status)
    select p_sid, p.id, 'teacher', 'available' from privileges p
     where not exists (select 1 from redemptions r where r.student_id = p_sid and r.privilege_id = p.id);
  update students set
    exp = greatest(exp, coalesce((select max(min_exp) from ch_ranks), 0) + 1000),
    coins = greatest(coins, 999999),
    is_gm = true
  where id = p_sid;
end $$;

create or replace function admin_create_gm(p_pin text) returns json
language plpgsql security definer set search_path = public, extensions as $$
declare cid uuid; sid uuid;
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  if p_pin is null or p_pin !~ '^[0-9]{4,8}$' then raise exception 'PIN ต้องเป็นตัวเลข 4-8 หลัก'; end if;
  select id into cid from classes where code = 'GM';
  if cid is null then
    insert into classes (code, name, subject_name, hidden) values ('GM', '🛠️ GM (ห้องทดสอบ)', 'ห้องทดสอบของครู', true) returning id into cid;
  end if;
  select id into sid from students where class_id = cid and no = 1;
  if sid is null then
    insert into students (class_id, no, name, pin_hash, avatar) values (cid, 1, 'GM ครูบุ๊ค', crypt(p_pin, gen_salt('bf')), '🛠️') returning id into sid;
  else
    update students set pin_hash = crypt(p_pin, gen_salt('bf')), fail_count = 0, locked_until = null where id = sid;
  end if;
  perform _gm_unlock(sid);
  return json_build_object('class_code', 'GM', 'no', 1, 'student_id', sid);
end $$;

-- ซิงก์ของใหม่ให้ไอดี GM (ไม่เปลี่ยน PIN)
create or replace function admin_gm_sync() returns int
language plpgsql security definer set search_path = public as $$
declare sid uuid; n int := 0;
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  for sid in select id from students where is_gm loop perform _gm_unlock(sid); n := n + 1; end loop;
  return n;
end $$;

revoke execute on function _gm_unlock(uuid) from public, anon, authenticated;
revoke execute on function admin_create_gm(text), admin_gm_sync() from public, anon;
grant execute on function admin_create_gm(text), admin_gm_sync() to authenticated;
revoke execute on function list_classes() from public;
grant execute on function list_classes() to anon, authenticated;
