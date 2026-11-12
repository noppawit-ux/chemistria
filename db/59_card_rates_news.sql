-- 59: ลดโอกาสดรอปการ์ดเป็น 30% + ปรับเรทความหายาก (N70 · R22 · SR7 · SSR1) + รวมประกาศการ์ดเหลือฉบับเดียว (v1.90)
update app_settings set value = '30' where key = 'card_drop_pct';
update app_settings set value = '70' where key = 'card_w_n';
update app_settings set value = '22' where key = 'card_w_r';
update app_settings set value = '7'  where key = 'card_w_sr';
update app_settings set value = '1'  where key = 'card_w_ssr';

-- ลบประกาศการ์ดเดิมที่ซ้ำ/ล้าสมัยทั้งหมด แล้วลงประกาศใหม่ฉบับเดียว
delete from news_posts where title like 'สมุดการ์ดสะสมเปิดแล้ว%' or title like 'ปรับกติกาการ์ดสะสม%' or title like 'กติกาการ์ดสะสม%';
insert into news_posts (kind, title, summary, body, image, sort, active)
values ('news', 'กติกาการ์ดสะสม 📖🃏 ดรอปจากมอนสเตอร์',
  'ชนะมอนสเตอร์ ลุ้นการ์ด 30% · วันละไม่เกิน 3 ใบ · ยิ่งหายากยิ่งดรอปยาก',
  E'📖 สมุดการ์ดสะสม — 60 ใบ 3 ชุด (ธาตุรอบตัว · นักเคมี · อุปกรณ์แล็บ)\n\n🐲 ได้การ์ดจาก "ชนะมอนสเตอร์" เท่านั้น\n🎲 ชนะแต่ละครั้งมีโอกาสได้การ์ด 30% · ใบแรกของทุกคนได้แน่นอน\n📅 จำกัดวันละไม่เกิน 3 ใบต่อคน\n💎 เรทความหายาก: N 70% · R 22% · SR 7% · SSR 1%\n♻️ ใบซ้ำกลายเป็นเศษธาตุ · ซ้ำติดกันหลายครั้งใบต่อไปจะเป็นใบใหม่แน่นอน\n🏆 สะสมครบชุดรับเหรียญ ตั๋วกาชา และของตกแต่ง\n🎁 ครูอาจแจกการ์ดเป็นของขวัญพิเศษ',
  'assets/news/items.jpg', 40, true);
