-- 93: เควส "มาเรียนวันนี้" / "ส่งงานวันนี้" แสดงเฉพาะวันที่ทำได้จริง (รันซ้ำได้)
--  · attendance → แสดงเมื่อครูเช็คชื่อห้องนั้นในวันนั้นแล้ว (มีข้อมูลใน ch_attendance)
--  · submit     → แสดงเมื่อห้องมีงานที่ยังไม่เลยกำหนด (หรือไม่มีกำหนดส่ง) หรือมีคนส่งงานของห้องแล้วในวันนั้น
--  · ปิดฟีเจอร์: update app_settings set value='0' where key='quests_day_aware'
--  · แสดงผลเท่านั้น: การให้รางวัลอัตโนมัติ (_auto_quests) ไม่เปลี่ยน
insert into app_settings (key, value) values ('quests_day_aware', '1') on conflict (key) do nothing;

create or replace function todays_quests(p_class uuid, p_date date)
returns setof quests language sql stable security definer set search_path = public as $$
  (select * from quests
    where active and auto_trigger is null and kind = 'daily' and (class_id is null or class_id = p_class)
      and coalesce((select value from app_settings where key = 'quests_auto_only'), '1') <> '1'
    order by md5(id::text || p_date::text)
    limit coalesce((select value::int from app_settings where key = 'daily_quest_count'), 3))
  union all
  (select * from quests
    where active and auto_trigger is null and kind = 'weekly' and (class_id is null or class_id = p_class)
      and coalesce((select value from app_settings where key = 'quests_auto_only'), '1') <> '1')
  union all
  (select * from quests q
    where q.active and q.auto_trigger is not null and (q.class_id is null or q.class_id = p_class)
      and (coalesce((select value from app_settings where key = 'quests_day_aware'), '1') <> '1'
           or case q.auto_trigger
                when 'attendance' then exists (select 1 from ch_attendance a where a.class_id = p_class and a.att_date = p_date)
                when 'submit' then exists (select 1 from ch_assignments x
                                            where x.class_id = p_class and (x.due_date is null or x.due_date >= p_date))
                                or exists (select 1 from ch_submissions sb join ch_assignments x on x.id = sb.assignment_id
                                            where x.class_id = p_class and sb.status in ('submitted','late')
                                              and (sb.submitted_at at time zone 'Asia/Bangkok')::date = p_date)
                else true end))
$$;
revoke execute on function todays_quests(uuid, date) from public, anon, authenticated;
