-- 28: ไอเทมตกแต่งใหม่ 14 ชิ้น ธีมเคมี (หมวก 3 · สัตว์เลี้ยง 3 · ไอเทมถือ 3 · พื้นหลัง 2 · กรอบ 1 · ฉายา 2)
-- รันซ้ำได้ (เพิ่มเฉพาะที่ยังไม่มี) · ภาพอยู่ใน web/assets/hats|pets|items · ค่าสเตตัสครูแก้ได้ที่แท็บ "ตกแต่ง"
insert into decor_items (slot, key, name, emoji, rarity, price, sort, image, st_int, st_dil, st_str, st_luk, st_coin, ability)
select v.* from (values
  ('hat','img','หมวกพ่อมดธาตุ','🧙','SR',null,20,'assets/hats/wizard.png',2,0,0,1,0,'เวทมนตร์จากตารางธาตุ'),
  ('hat','img','มงกุฎลอเรลนักวิจัย','🌿','SSR',null,21,'assets/hats/laurel.png',2,1,0,1,0,'ผู้พิชิตการทดลองทุกครั้ง'),
  ('hat','img','หมวกบีกเกอร์ปั่น','🧪','N',100,22,'assets/hats/beaker.png',0,1,0,0,0,'ใส่แล้วขยันขึ้นนิดๆ'),
  ('pet','img','หุ่นยนต์จิ๋วผู้ช่วยแล็บ','🤖','R',220,20,'assets/pets/robot.png',1,1,0,0,0,'ช่วยจดผลการทดลอง'),
  ('pet','img','สไลม์สารเคมี','🟢','N',120,21,'assets/pets/slime.png',0,0,0,1,0,'เด้งดึ๋งนำโชค'),
  ('pet','img','ฟีนิกซ์น้อยเปลวเพลิง','🐦‍🔥','SSR',null,22,'assets/pets/phoenix.png',0,0,2,1,3,'เกิดใหม่จากเปลวไฟ'),
  ('item','img','หลอดหยดทองคำ','💧','N',90,30,'assets/items/dropper.png',1,0,0,0,0,'หยดเดียวก็แม่นยำ'),
  ('item','img','ตะเกียงแอลกอฮอล์เปลวฟ้า','🪔','R',150,31,'assets/items/lamp.png',0,0,1,1,0,'ให้ความร้อนพอดี'),
  ('item','img','เพชรคาร์บอน','💎','SSR',null,32,'assets/items/diamond.png',2,0,1,1,0,'คาร์บอนที่ทนแรงดันมาแล้ว'),
  ('bg','volcano','พื้นภูเขาไฟ','🌋','R',100,20,null,0,0,0,0,0,null),
  ('bg','crystal','พื้นถ้ำผลึก','💠','SR',null,21,null,0,0,0,0,0,null),
  ('frame','amethyst','กรอบอเมทิสต์','🔮','R',120,20,null,0,0,0,0,0,null),
  ('title','text','นักปั่นสมการ','📐','R',150,30,null,1,1,0,0,0,'สมดุลสมการแบบไม่ต้องคิดนาน'),
  ('title','text','ผู้รอดชีวิตจากปฏิกิริยา','⚡','SR',null,31,null,0,1,1,0,2,'ผ่านมาทุกการทดลองไม่มีหาย')
) v(slot,key,name,emoji,rarity,price,sort,image,st_int,st_dil,st_str,st_luk,st_coin,ability)
where not exists (select 1 from decor_items d where d.slot = v.slot and d.name = v.name);

-- ชิ้นที่ไม่ขายในร้านเข้ากาชา
insert into gacha_items (name, rarity, kind, value, emoji, weight, decor_id)
select d.name, d.rarity, 'decor', 0, d.emoji, case d.rarity when 'N' then 3 when 'R' then 2 else 1 end, d.id
  from decor_items d
 where d.name in ('หมวกพ่อมดธาตุ','มงกุฎลอเรลนักวิจัย','ฟีนิกซ์น้อยเปลวเพลิง','เพชรคาร์บอน','พื้นถ้ำผลึก','ผู้รอดชีวิตจากปฏิกิริยา')
   and not exists (select 1 from gacha_items g where g.decor_id = d.id);
