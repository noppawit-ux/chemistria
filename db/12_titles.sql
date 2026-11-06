-- รอบที่ 12: ฉายาปั่นๆ พร้อมความสามารถ + ชุดปั่นๆ 3 แบบ (เป็ดยาง / ไดโนเสาร์ / แมวส้ม) (รันซ้ำได้)
-- ความสามารถของฉายา = ค่าสเตตัส (ปัญญา/ขยัน/พลัง/โชค) + โบนัสเหรียญ % (st_coin) + ข้อความอธิบาย (ability)
--   ปัญญา +1 EXP/ควิซ ต่อ 2 แต้ม · ขยัน +1% EXP · พลัง +3% ดาเมจบอส · โชค +3% โอกาส SR/SSR · โบนัสเหรียญ +N% จากเช็คชื่อ/ส่งงาน/เควส
-- ครูแก้ค่า/ข้อความได้ที่แท็บ "ตกแต่ง"

-- ฉายาเดิม: ใส่ความสามารถให้ (เฉพาะที่ยังไม่มี)
update decor_items set st_int = 1, st_coin = 0, ability = 'อ่านเยอะ ฉลาดขึ้นนิดๆ' where slot='title' and name='หนอนตำรา' and ability is null;
update decor_items set st_int = 1, st_dil = 1, ability = 'คำนวณโมลแม่นขึ้น' where slot='title' and name='ผู้พิชิตโมล' and ability is null;
update decor_items set st_dil = 1, st_str = 1, ability = 'พลังคาร์บอนสายยาว' where slot='title' and name='ราชาออร์แกนิก' and ability is null;
update decor_items set st_int = 2, st_luk = 1, st_coin = 3, ability = 'เวทธาตุเสกเหรียญเพิ่ม +3%' where slot='title' and name='จอมเวทธาตุ' and ability is null;
update decor_items set st_int = 2, st_dil = 2, st_str = 1, st_luk = 1, st_coin = 5, ability = 'ตำนานแห่งห้องแล็บ ทุกด้านเก่งขึ้น' where slot='title' and name='ตำนานห้องแล็บ' and ability is null;

insert into decor_items (slot, key, name, emoji, rarity, price, sort, st_int, st_dil, st_str, st_luk, st_coin, ability)
select v.* from (values
  ('title','text','ผู้ถือโมลไม่ถือกฎ','🧂','N',60,10,0,1,0,0,0,'ขยันแบบงงๆ แต่ได้ผล'),
  ('title','text','เจ้าแห่งการลืมสมุด','📓','N',60,11,0,0,0,1,0,'ลืมสมุดแต่โชคดีตลอด'),
  ('title','text','ง่วงแต่ยังมา','😪','N',70,12,0,2,0,0,0,'มาครบทุกคาบแม้ตาจะปิด'),
  ('title','text','คุณชายนอนหลับในคาบ','🛌','N',70,13,1,0,0,0,2,'ฝันถึงสูตรเคมี เหรียญเข้า +2%'),
  ('title','text','นักล่าเศษเหรียญ','🪙','R',140,14,0,0,0,1,4,'เก็บเหรียญเก่งขึ้น +4%'),
  ('title','text','มือบอนแตะหลอดทดลอง','🧪','R',160,15,1,0,2,0,0,'ซนแล้วดาเมจแรงขึ้น'),
  ('title','text','ตำรวจจับโมล','🚓','R',160,16,2,1,0,0,0,'เห็นทุกจุดผิดในสมการ'),
  ('title','text','ขวดแตกแต่ไม่ท้อ','🍶','R',150,17,0,2,1,0,0,'ล้มแล้วลุกใหม่ ขยันขึ้น'),
  ('title','text','แมวทำหลอดตก','😼','R',180,18,0,0,1,2,0,'ทำของตกแต่ได้ของดี'),
  ('title','text','พ่อค้าเหรียญเรืองแสง','💰','SR',null,19,0,1,0,1,8,'ขายเก่ง เหรียญเพิ่ม +8%'),
  ('title','text','ผู้บันทึก "ส่งแล้วครับ"','📮','SR',null,20,0,3,0,0,3,'ส่งงานไวสุด ขยัน +3'),
  ('title','text','ราชันย์ลูกเต๋าลอยฟ้า','🎲','SR',null,21,0,0,1,3,0,'โชคล้นฟ้า SR ออกง่ายขึ้น'),
  ('title','text','เจ้าพ่อบอสฟาร์ม','👹','SR',null,22,0,0,3,1,0,'ซัดบอสเจ็บแสบ'),
  ('title','text','สมองกลวงแต่ใจกล้า','🧠','SSR',null,23,1,1,3,1,0,'ไม่คิดมาก ดาเมจสุดโหด'),
  ('title','text','ผู้ถูกเลือกโดยพรีเมียมกาชา','🌈','SSR',null,24,0,0,1,4,6,'โชคสุดจัด เหรียญเพิ่ม +6%'),
  ('title','text','มหาเทพขาประจำหน้าห้อง','👑','SSR',null,25,2,2,2,2,6,'ทุกด้านพุ่ง ครูเห็นหน้าทุกวัน')
) v(slot,key,name,emoji,rarity,price,sort,st_int,st_dil,st_str,st_luk,st_coin,ability)
where not exists (select 1 from decor_items d where d.slot='title' and d.name=v.name);

-- ชุดปั่นๆ (ภาพ: web/assets/chars/<คลาส>_duck|dino|cat.png)
insert into decor_items (slot, key, name, emoji, rarity, price, sort, st_int, st_dil, st_str, st_luk, st_coin, ability)
select v.* from (values
  ('outfit','duck','ชุดเป็ดยางตัวป่วน','🦆','R',280,6,0,1,0,2,3,'ลอยน้ำได้ โชคดี เหรียญ +3%'),
  ('outfit','dino','ชุดไดโนเสาร์ตัวจิ๋ว','🦖','SR',null,7,0,0,3,1,0,'ก้าวร้าวน่ารัก ดาเมจบอสแรง'),
  ('outfit','cat','ชุดแมวส้มจอมเกียจคร้าน','🐱','R',280,8,1,0,0,2,4,'ขี้เกียจแต่เหรียญเข้า +4%')
) v(slot,key,name,emoji,rarity,price,sort,st_int,st_dil,st_str,st_luk,st_coin,ability)
where not exists (select 1 from decor_items d where d.slot='outfit' and d.name=v.name);

-- เข้ากาชา: ฉายา/ชุดที่ไม่ขายในร้าน
insert into gacha_items (name, rarity, kind, value, emoji, weight, decor_id)
select d.name, d.rarity, 'decor', 0, d.emoji, case d.rarity when 'N' then 3 when 'R' then 2 else 1 end, d.id
  from decor_items d
 where d.slot in ('title','outfit') and d.price is null and d.rarity in ('SR','SSR')
   and not exists (select 1 from gacha_items g where g.decor_id = d.id);
