-- SQL 111 · ดันเจี้ยนเพิ่ม 3 แห่ง (ต่อจาก 110) — รันซ้ำได้ (on conflict do nothing)
--   โรงหลอมภูเขาไฟ 🌋 (เลเวล 3+) · บึงก๊าซพิษ ☣️ (เลเวล 6+) · ห้องแล็บอวกาศ 🚀 (เลเวล 10+)
--   โครงสร้างเหมือน crystal_cave: 5 ชั้น ชั้นสุดท้ายเป็นบอส · มอนสเตอร์ซ่อนด้วย trial_rank = 'dgN:ชั้น'
insert into dungeons (key, name, emoji, descr, min_level, floors, sort) values
  ('volcano_forge', 'โรงหลอมภูเขาไฟ', '🌋', 'ผ่านเมืองยามเย็นลงสู่โรงหลอมลาวา เจอสนิม เขม่า และลาวาโซเดียม ชั้นสุดท้ายคือราชาลาวา', 3, 5, 2),
  ('toxic_swamp', 'บึงก๊าซพิษ', '☣️', 'บึงหมอกแอมโมเนียและเมือกกรด ตอบเร็วลดดาเมจให้ทัน ชั้นสุดท้ายคือเจ้าแห่งก๊าซคลอรีน', 6, 5, 3),
  ('space_lab', 'ห้องแล็บอวกาศ', '🚀', 'ด่านสุดท้ายของเหล่านักเคมี ไนโตรเจนเหลว โอโซน และพลาสมา ชั้นสุดท้ายคือมหาพลาสมาแห่งจักรวาล', 10, 5, 4)
on conflict (key) do nothing;

insert into monsters (key, name, emoji, image, level, hp, atk, exp, coins, atk_name, descr, sort, active, arena, element, trial_rank)
select v.k, v.n, b.emoji, b.image, least(v.lv, 5), v.hp, v.atk, 0, 0, b.atk_name, 'มอนสเตอร์ดันเจี้ยน ชั้น ' || v.fl, 900 + v.dg * 10 + v.fl, true, b.arena, b.element, 'dg' || v.dg || ':' || v.fl
  from (values
    ('dg2_f1', 'สนิมเหล็กจอมกัดกร่อน', 'rust', 3, 150, 14, 1, 2), ('dg2_f2', 'เขม่าคาร์บอนมืดมิด', 'ash', 4, 200, 18, 2, 2),
    ('dg2_f3', 'ลาวาโซเดียมระเบิด', 'lava', 5, 260, 22, 3, 2), ('dg2_f4', 'พลาสมาไฟนรก', 'plasma', 6, 330, 26, 4, 2),
    ('dg2_f5', 'ราชาลาวาแห่งโรงหลอม', 'lava', 7, 600, 34, 5, 2),
    ('dg3_f1', 'หมอกแอมโมเนียหลอน', 'fog', 6, 190, 18, 1, 3), ('dg3_f2', 'เมือกกรดซัลฟิวริกเดือด', 'sludge', 7, 250, 22, 2, 3),
    ('dg3_f3', 'เกลือพิษจอมซ่า', 'salt', 8, 320, 26, 3, 3), ('dg3_f4', 'ก๊าซคลอรีนพิษร้าย', 'toxic', 9, 400, 30, 4, 3),
    ('dg3_f5', 'เจ้าแห่งก๊าซคลอรีน', 'toxic', 10, 720, 40, 5, 3),
    ('dg4_f1', 'ไนโตรเจนเหลวนักล่า', 'cryo', 10, 260, 24, 1, 4), ('dg4_f2', 'โอโซนพายุจักรวาล', 'ozone', 11, 340, 28, 2, 4),
    ('dg4_f3', 'น้ำแข็งแห้งดวงดาว', 'frost', 12, 420, 33, 3, 4), ('dg4_f4', 'ไข่ธรณีผลึกอวกาศ', 'geode', 13, 520, 38, 4, 4),
    ('dg4_f5', 'มหาพลาสมาแห่งจักรวาล', 'plasma', 15, 900, 48, 5, 4)
  ) v(k, n, base, lv, hp, atk, fl, dg)
  join monsters b on b.key = v.base
on conflict (key) do nothing;

insert into dungeon_floors (dungeon_key, floor, monster_key, bg, exp, coins, boss) values
  ('volcano_forge', 1, 'dg2_f1', 'assets/bg/a4.webp', 25, 12, false), ('volcano_forge', 2, 'dg2_f2', 'assets/bg/a4.webp', 40, 20, false),
  ('volcano_forge', 3, 'dg2_f3', 'assets/bg/s4.webp', 60, 30, false), ('volcano_forge', 4, 'dg2_f4', 'assets/bg/s4.webp', 85, 42, false),
  ('volcano_forge', 5, 'dg2_f5', 'assets/bg/s6.webp', 160, 80, true),
  ('toxic_swamp', 1, 'dg3_f1', 'assets/bg/a3.webp', 40, 20, false), ('toxic_swamp', 2, 'dg3_f2', 'assets/bg/a3.webp', 65, 32, false),
  ('toxic_swamp', 3, 'dg3_f3', 'assets/bg/s3.webp', 95, 47, false), ('toxic_swamp', 4, 'dg3_f4', 'assets/bg/s5.webp', 130, 65, false),
  ('toxic_swamp', 5, 'dg3_f5', 'assets/bg/s5.webp', 250, 125, true),
  ('space_lab', 1, 'dg4_f1', 'assets/bg/a2.webp', 60, 30, false), ('space_lab', 2, 'dg4_f2', 'assets/bg/a2.webp', 95, 47, false),
  ('space_lab', 3, 'dg4_f3', 'assets/bg/s7.webp', 140, 70, false), ('space_lab', 4, 'dg4_f4', 'assets/bg/s7.webp', 190, 95, false),
  ('space_lab', 5, 'dg4_f5', 'assets/bg/s7.webp', 360, 180, true)
on conflict (dungeon_key, floor) do nothing;
