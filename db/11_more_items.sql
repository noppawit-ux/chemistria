-- รอบที่ 11: ชุดใหม่ 3 แบบ (เสื้อกาวน์ / อัศวิน / ชุดไทย) + ไอเทมถือใหม่ 12 ชิ้น (รันซ้ำได้ — เพิ่มเฉพาะที่ยังไม่มี)
-- ภาพชุด: web/assets/chars/<คลาส>_<labcoat|knight|thai>.png · ภาพไอเทม: web/assets/items/*.png
-- ค่าสเตตัสของแต่ละชิ้นตั้งไว้ในไฟล์นี้ (ครูแก้ได้ที่แท็บ "ตกแต่ง")
insert into decor_items (slot, key, name, emoji, rarity, price, sort, image, st_int, st_dil, st_str, st_luk)
select v.* from (values
  ('outfit','labcoat','ชุดเสื้อกาวน์นักเคมี','🥼','N',150,3,null,1,1,0,0),
  ('outfit','knight','ชุดอัศวินเคมี','🛡️','R',320,4,null,0,1,2,0),
  ('outfit','thai','ชุดไทยลายทอง','🪷','SR',null,5,null,0,2,0,1),
  ('item','img','คัมภีร์ตารางธาตุ','📜','N',80,7,'assets/items/scroll.png',1,0,0,0),
  ('item','img','แว่นขยายทองคำ','🔍','N',90,8,'assets/items/magnifier.png',1,0,0,0),
  ('item','img','ชั้นหลอดทดลอง','🧫','R',130,9,'assets/items/rack.png',1,0,0,1),
  ('item','img','หนังสือเวทอะตอม','📖','R',180,10,'assets/items/spellbook.png',2,0,0,0),
  ('item','img','ขวดกลมประกายฟ้า','⚗️','R',140,11,'assets/items/flask.png',0,1,0,1),
  ('item','img','ดาบหลอดแก้ว','🗡️','R',220,12,'assets/items/sword.png',0,0,2,0),
  ('item','img','โล่ตราขวดแล็บ','🛡️','R',220,13,'assets/items/shield.png',0,2,1,0),
  ('item','img','ไม้เท้าเกลียวดีเอ็นเอ','🧬','SR',null,14,'assets/items/dnastaff.png',2,0,0,1),
  ('item','img','จรวดจิ๋ว','🚀','SR',null,15,'assets/items/rocket.png',0,0,2,1),
  ('item','img','ถ้วยรางวัลทองคำ','🏆','SR',null,16,'assets/items/trophy.png',0,2,1,0),
  ('item','img','คบไฟตะเกียงน้ำเงิน','🔥','SR',null,17,'assets/items/torch.png',0,0,3,0),
  ('item','img','คทาสายฟ้าม่วง','⚡','SSR',null,18,'assets/items/scepter.png',1,0,3,1)
) v(slot,key,name,emoji,rarity,price,sort,image,st_int,st_dil,st_str,st_luk)
where not exists (select 1 from decor_items d where d.slot = v.slot and d.name = v.name);

-- เข้ากาชา: ชิ้นที่ไม่ขายในร้าน (SR/SSR) + ชุดอัศวิน
insert into gacha_items (name, rarity, kind, value, emoji, weight, decor_id)
select d.name, d.rarity, 'decor', 0, d.emoji, case d.rarity when 'N' then 3 when 'R' then 2 else 1 end, d.id
  from decor_items d
 where d.name in ('ชุดไทยลายทอง','ชุดอัศวินเคมี','ไม้เท้าเกลียวดีเอ็นเอ','จรวดจิ๋ว','ถ้วยรางวัลทองคำ','คบไฟตะเกียงน้ำเงิน','คทาสายฟ้าม่วง')
   and not exists (select 1 from gacha_items g where g.decor_id = d.id);
