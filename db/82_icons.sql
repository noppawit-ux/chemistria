-- =====================================================================
-- 82: ไอคอนพิกเซลให้ยา/ของใช้/เอฟเฟกต์ + ไอเทมสวมใส่ธาตุชุดใหม่ (ดาบ 5 + หมวก 5) (รันซ้ำได้)
--  ต้องรันหลัง 81 · ไฟล์ภาพอยู่ที่ assets/px/ (ไอคอนจาก Raven Fantasy Icons — ดูเครดิตใน assets/CREDITS.md)
--  ใส่ภาพเฉพาะรายการที่ครูยังไม่เคยใส่ภาพเอง (image เป็นค่าว่าง)
-- =====================================================================
update consumables c set image = v.img
  from (values ('p_exp', 'assets/px/p_exp.png'), ('p_coin', 'assets/px/p_coin.png'), ('p_luck', 'assets/px/p_luck.png'), ('p_str', 'assets/px/p_str.png'),
               ('p_int', 'assets/px/p_int.png'), ('p_heal', 'assets/px/p_heal.png'), ('scroll', 'assets/px/scroll.png'), ('t_reset', 'assets/px/t_reset.png')) v(k, img)
 where c.key = v.k and c.image is null;

update decor_items d set image = v.img
  from (values ('ออร่าเปลวไฟ', 'assets/px/fx_flame.png'), ('หิมะน้ำแข็ง', 'assets/px/fx_ice.png'), ('สายฟ้าฟาด', 'assets/px/fx_bolt.png'),
               ('ประกายดาว', 'assets/px/fx_spark.png'), ('ฟองสารเคมี', 'assets/px/fx_bubble.png'), ('ดาวโคจร', 'assets/px/fx_orbit.png')) v(n, img)
 where d.slot = 'fx' and d.name = v.n and d.image is null;

-- ไอเทมใหม่: ดาบ/คทา (ช่องไอเทมถือ = โจมตี) และหมวก (= ลดดาเมจ) อย่างละ 1 ต่อธาตุ
insert into decor_items (slot, key, name, emoji, rarity, price, sort, image, element, fx_atk, fx_def, fx_hp)
select v.slot, 'img', v.name, v.emoji, v.rarity, v.price, v.sort, v.img, v.el, v.atk, v.def, 0
  from (values
    ('item', 'ดาบเพลิงอัคนี',        '🗡️', 'SR', 480, 41, 'assets/px/sw_fire.png',    'fire',    3, 0),
    ('item', 'ดาบคลื่นน้ำแข็ง',      '🗡️', 'R',  240, 42, 'assets/px/sw_water.png',   'water',   2, 0),
    ('item', 'ใบมีดมรกตพงไพร',      '🗡️', 'R',  240, 43, 'assets/px/sw_plant.png',   'plant',   2, 0),
    ('item', 'ดาบสายฟ้าทองคำ',       '🗡️', 'SR', 480, 44, 'assets/px/sw_thunder.png', 'thunder', 3, 0),
    ('item', 'คทาดาบสารเคมีม่วง',    '🗡️', 'SR', 480, 45, 'assets/px/sw_chem.png',    'chem',    3, 0),
    ('hat',  'หมวกจอมเวทเพลิง',      '🎩', 'R',  200, 41, 'assets/px/hat_fire.png',   'fire',    0, 2),
    ('hat',  'หมวกจอมเวทสายน้ำ',     '🎩', 'R',  200, 42, 'assets/px/hat_water.png',  'water',   0, 2),
    ('hat',  'หมวกจอมเวทพงไพร',      '🎩', 'R',  200, 43, 'assets/px/hat_plant.png',  'plant',   0, 2),
    ('hat',  'หมวกเกราะสายฟ้า',      '⛑️', 'SR', 420, 44, 'assets/px/hat_thunder.png', 'thunder', 0, 3),
    ('hat',  'หมวกจอมเวทสารเคมี',    '🎩', 'R',  200, 45, 'assets/px/hat_chem.png',   'chem',    0, 2)
  ) v(slot, name, emoji, rarity, price, sort, img, el, atk, def)
 where not exists (select 1 from decor_items d where d.name = v.name and d.slot = v.slot);
