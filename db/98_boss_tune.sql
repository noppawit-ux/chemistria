-- 98: ปรับความยากบอสด่านเลื่อนแรงค์ (ลดพลังบอสลงเป็นขั้น: Silver ลดน้อย → Challenger ลดมาก)
-- ปรับเฉพาะบอสที่ยังเป็นค่าเดิมตอนติดตั้ง (ถ้าครูแก้ค่าเองในแอดมินแล้ว จะไม่ถูกเขียนทับ) · รันซ้ำได้
-- ค่าเดิม HP/ATK → ค่าใหม่:
--   Silver 170/14→160/13 · Gold 230/16→205/14 · Platinum 310/18→250/15 · Emerald 390/20→285/16
--   Diamond 490/22→335/17 · Master 610/24→385/19 · Grandmaster 770/27→445/21 · Challenger 960/30→510/23
update monsters m set hp = v.nhp, atk = v.natk
  from (values ('silver',170,14,160,13),('gold',230,16,205,14),('platinum',310,18,250,15),('emerald',390,20,285,16),
               ('diamond',490,22,335,17),('master',610,24,385,19),('grandmaster',770,27,445,21),('challenger',960,30,510,23))
       v(rk, ohp, oatk, nhp, natk)
 where m.trial_rank = v.rk and m.hp = v.ohp and m.atk = v.oatk;
