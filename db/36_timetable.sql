-- 36: ตารางสอนรายห้อง → ขึ้นในปฏิทินนักเรียน (ภาคเรียน 2/2569 ใช้ตั้งแต่ 2 พ.ย. 2569) · รันซ้ำได้
create table if not exists timetable (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references classes(id) on delete cascade,
  dow int not null check (dow between 1 and 7),     -- 1=จันทร์ ... 7=อาทิตย์
  start_time text not null,                          -- เช่น 08:40
  end_time text not null,                            -- เช่น 09:30
  period text,                                       -- เช่น คาบ 1-2
  title text not null,
  room text,
  effective_from date not null default '2026-11-02',
  effective_to date,
  active boolean not null default true,
  unique (class_id, dow, start_time)
);
alter table timetable enable row level security;
drop policy if exists teacher_all on timetable;
create policy teacher_all on timetable for all using (is_teacher()) with check (is_teacher());
revoke all on timetable from anon;

insert into timetable (class_id, dow, start_time, end_time, period, title, room)
select c.id, v.d, v.s, v.e, v.p, v.t, v.r
  from (values
    ('ม.6/6', 1, '11:10', '12:00', 'คาบ 4',   'เคมี 6 (ว33226)', '734'),
    ('ม.6/6', 4, '10:20', '12:00', 'คาบ 3-4', 'เคมี 6 (ว33226)', '734'),
    ('ม.1/1', 1, '13:40', '15:20', 'คาบ 7-8', 'เคมี 2 (ว21202)', '716'),
    ('ม.1/1', 2, '09:30', '10:20', 'คาบ 2',   'เคมี 2 (ว21202)', '716'),
    ('ม.6/4', 2, '10:20', '12:00', 'คาบ 3-4', 'เคมี 6 (ว33226)', '734'),
    ('ม.6/4', 5, '13:40', '14:30', 'คาบ 7',   'เคมี 6 (ว33226)', '734'),
    ('ม.6/2', 3, '08:40', '10:20', 'คาบ 1-2', 'เคมี 6 (ว33226)', '734'),
    ('ม.6/2', 5, '10:20', '11:10', 'คาบ 3',   'เคมี 6 (ว33226)', '734'),
    ('ม.6/5', 3, '13:40', '14:30', 'คาบ 7',   'เคมี 6 (ว33226)', '734'),
    ('ม.6/5', 5, '08:40', '10:20', 'คาบ 1-2', 'เคมี 6 (ว33226)', '734')
  ) v(cn, d, s, e, p, t, r)
  join classes c on c.name = v.cn
on conflict (class_id, dow, start_time) do nothing;

create or replace function timetable_list(p_token uuid) returns json
language plpgsql stable security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  return coalesce((select json_agg(json_build_object('dow', t.dow, 'start', t.start_time, 'end', t.end_time,
      'period', t.period, 'title', t.title, 'room', t.room, 'from', t.effective_from, 'to', t.effective_to)
      order by t.dow, t.start_time)
    from timetable t join students s on s.class_id = t.class_id
   where s.id = sid and t.active), '[]'::json);
end $$;
revoke execute on function timetable_list(uuid) from public;
grant execute on function timetable_list(uuid) to anon, authenticated;

-- ให้ผู้สังเกตการณ์ (โหมดส่อง) เรียก timetable_list ได้
create or replace function _sid(p_token uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare v uuid; o boolean; fn text;
begin
  select student_id, observer into v, o from student_sessions where token = p_token and expires_at > now();
  if v is null then raise exception 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่'; end if;
  if o then
    fn := regexp_replace(coalesce(current_setting('request.path', true), ''), '^.*/', '');
    if fn not in ('student_dashboard','student_extras','hall_of_fame','board_list','celebrations_feed','game_status','spell_status','kb_status','news_list','run_status','timetable_list') then
      raise exception 'โหมดส่องนักเรียน: ดูได้อย่างเดียว';
    end if;
  end if;
  return v;
end $$;
