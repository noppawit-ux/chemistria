-- 108: ไอคอนใหม่จากแพ็ก Animated RPG Icons (assets/aic/s_*.webp) แทน emoji — ชุดเกราะ 12 ชุด + ขวดยา 6 ชนิดในแท็บไอเทม
-- ใส่เฉพาะแถวที่ยังไม่มีรูป (ไม่ทับรูปที่ครูตั้งเอง) ยกเว้นขวดยาที่เปลี่ยนจากรูปเดิม assets/px/p_*.png
-- 1) ชุด (outfit) — ชื่อ → ไอคอน
with m(name, ico) as (values
  ('ชุดราชันจอมเวทสีชาด','arm_pyro'), ('ชุดอัศวินมังกรโลหิต','arm_dragon'), ('ชุดเสื้อกาวน์นักเคมี','arm_plague'), ('ชุดนักบินอวกาศ','arm_electro'),
  ('ชุดป้องกันสารเคมี (ฮาซ์แมท)','arm_shadow'), ('ชุดเป็ดยางตัวป่วน','arm_solar'), ('ชุดแมวส้มจอมเกียจคร้าน','arm_jaguar'), ('ชุดอัศวินเคมี','arm_hero'),
  ('ชุดจอมเวทย์','arm_crystal'), ('ชุดไดโนเสาร์ตัวจิ๋ว','arm_kraken'), ('ชุดไทยลายทอง','arm_griffin'), ('ชุดซามูไรนักเคมี','arm_shogun'))
update decor_items d set image = 'assets/aic/s_' || m.ico || '.webp'
  from m where d.name = m.name and d.slot = 'outfit' and (d.image is null or d.image = '');
-- 2) ของในตู้กาชาที่ผูกกับของตกแต่ง (ชุด/หมวก/สัตว์เลี้ยง/ไอเทมถือ/เอฟเฟกต์) แต่ยังไม่มีรูป → ใช้รูปเดียวกับของตกแต่ง (กรอบ/พื้น/ฉายาไม่มีรูปในชุดนี้ จึงคง emoji)
update gacha_items g set image_url = d.image
  from decor_items d where g.decor_id = d.id and (g.image_url is null or g.image_url = '') and d.image is not null and d.image <> '' and d.slot not in ('title', 'bg', 'frame');
-- 3) ขวดยา (consumables)
with m(key, ico) as (values ('p_exp','pot_mana'), ('p_coin','pot_stamina'), ('p_luck','pot_poison'), ('p_str','pot_fire'), ('p_int','pot_ice'), ('p_heal','pot_health'))
update consumables c set image = 'assets/aic/s_' || m.ico || '.webp'
  from m where c.key = m.key and (c.image is null or c.image = '' or c.image like 'assets/px/p\_%');
