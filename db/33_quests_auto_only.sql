-- 33: เควสวันนี้แสดงเฉพาะเควสที่ระบบเช็คอัตโนมัติ (รันซ้ำได้)
--  · ตั้งค่า quests_auto_only = 1 (ค่าเริ่มต้น) → นักเรียนเห็นเฉพาะเควสอัตโนมัติ · ตั้งเป็น 0 เพื่อกลับไปแสดงเควสที่กดขอรับรางวัล (รายวันสุ่ม + รายสัปดาห์) ด้วย
insert into app_settings (key, value) values ('quests_auto_only', '1') on conflict (key) do nothing;

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
  (select * from quests
    where active and auto_trigger is not null and (class_id is null or class_id = p_class))
$$;
revoke execute on function todays_quests(uuid, date) from public, anon, authenticated;
