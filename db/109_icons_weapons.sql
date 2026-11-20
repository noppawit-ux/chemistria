-- 109: ไอเทมถือ (ดาบ/คทา/โล่) 12 ชิ้น → ไอคอนจากแพ็ก Animated RPG Icons (assets/aic/s_*.webp) แทนรูปเดิม
-- ย้อนกลับ: ดูรูปเดิมของแต่ละชิ้นใน README รอบ 163
with m(name, ico) as (values
  ('ดาบผลึกอัคนีโลหิต','sw_blood'), ('ดาบคลื่นน้ำแข็ง','sw_ice'), ('ดาบหลอดแก้ว','sw_chrono'), ('ใบมีดมรกตพงไพร','sw_nature'),
  ('คทาดาบสารเคมีม่วง','sw_nebula'), ('ดาบเพลิงอัคนี','sw_dragon'), ('ดาบสายฟ้าทองคำ','sw_solarion'), ('[Limited] ดาบราชันธาตุ','sw_prism'),
  ('คทาเวทมนตร์','st_divine'), ('คทาสายฟ้าม่วง','st_storm'), ('ไม้เท้าเกลียวดีเอ็นเอ','st_voltage'), ('โล่ตราขวดแล็บ','sh_paladin')),
old as (select d.id, d.image from decor_items d join m on m.name = d.name and d.slot = 'item'),
u as (update decor_items d set image = 'assets/aic/s_' || m.ico || '.webp' from m where d.name = m.name and d.slot = 'item' returning d.id, d.image)
update gacha_items g set image_url = u.image from u where g.decor_id = u.id;
