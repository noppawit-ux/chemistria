-- =====================================================================
-- 47: แก้บั๊ก "หน้าข่าว/ตารางสอน/โปรโมชันไม่ขึ้น" หลังรัน SQL 43
--  สาเหตุ: SQL 43 ทำให้ _sid() บันทึกจำนวนคำสั่งต่อนาที (UPDATE) แต่ news_list / timetable_list / promo_status
--  ประกาศเป็น STABLE (ห้ามเขียนข้อมูล) จึงล้มเหลวทุกครั้ง → เปลี่ยนเป็น VOLATILE (รันซ้ำได้)
-- =====================================================================
alter function news_list(uuid) volatile;
alter function timetable_list(uuid) volatile;
alter function promo_status(uuid) volatile;
-- กันพลาดในอนาคต: ฟังก์ชันอื่นที่เรียก _sid แต่ยังเป็น STABLE/IMMUTABLE จะถูกแก้ให้ด้วย
do $$ declare r record; begin
  for r in select p.oid::regprocedure f from pg_proc p join pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'public' and p.provolatile <> 'v' and p.prosrc ~ '_sid\(' and p.proname <> '_sid' loop
    execute format('alter function %s volatile', r.f);
  end loop;
end $$;
