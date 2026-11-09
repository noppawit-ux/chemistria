-- 48: ลดสเตตัสไอเทม Legendary ลง (รันซ้ำได้) — สำหรับคนที่รัน 46 รุ่นแรกไปแล้ว
-- รวมต่อชิ้น = 7 (เดิม 13–18) · สูงกว่า SSR สูงสุดเล็กน้อย · ครูปรับต่อได้ที่แท็บ 🎨 ตกแต่ง
update decor_items set st_int=0, st_dil=1, st_str=4, st_luk=2, st_coin=2 where rarity='LEG' and name='ดาบผลึกอัคนีโลหิต';
update decor_items set st_int=4, st_dil=1, st_str=0, st_luk=2, st_coin=2 where rarity='LEG' and name='คัมภีร์อะตอมโลหิต';
update decor_items set st_int=1, st_dil=2, st_str=3, st_luk=1, st_coin=3 where rarity='LEG' and name='ชุดอัศวินมังกรโลหิต';
update decor_items set st_int=3, st_dil=2, st_str=1, st_luk=1, st_coin=3 where rarity='LEG' and name='ชุดราชันจอมเวทสีชาด';
