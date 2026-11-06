-- =====================================================================
-- ข้อมูลตั้งต้น (แก้ไขได้ทั้งหมดในหน้าแอดมิน) — รันหลัง 01_schema.sql
-- รันซ้ำได้: เติมเฉพาะตารางที่ยังว่าง
-- =====================================================================

insert into app_settings (key, value) values
  ('gacha_cost', '30'),          -- เหรียญต่อ 1 ครั้ง
  ('pity_max', '10'),            -- สุ่มครบกี่ครั้งการันตี SR ขึ้นไป
  ('daily_quest_count', '3'),    -- จำนวนเควสประจำวันที่สุ่มให้
  ('show_scores', '1')           -- 1 = นักเรียนเห็นคะแนนของตัวเอง
on conflict (key) do nothing;

-- บัญชีครูที่เข้าหน้าแอดมินได้ (ต้องสร้างผู้ใช้อีเมลเดียวกันใน Authentication ด้วย)
insert into teachers (email) values ('noppawit@nonghanwit.ac.th') on conflict do nothing;

-- ห้องเรียนปีการศึกษา 2569 (รหัสห้องใช้ตอนนักเรียนล็อกอิน)
insert into classes (code, name, subject_code, subject_name)
select * from (values
  ('M6-2',  'ม.6/2',  'ว33225', 'เคมี'),
  ('M6-4',  'ม.6/4',  'ว33225', 'เคมี'),
  ('M6-6',  'ม.6/6',  'ว33225', 'เคมี'),
  ('M2-16', 'ม.2/16', 'ว20204', 'เชื้อเพลิงเพื่อการคมนาคม'),
  ('M2-17', 'ม.2/17', 'ว20204', 'เชื้อเพลิงเพื่อการคมนาคม'),
  ('M1-1',  'ม.1/1',  'ว20201', 'เคมี')
) v(code, name, subject_code, subject_name)
where not exists (select 1 from classes);

-- สิทธิพิเศษ (ตัวอย่าง — ปรับ/ปิดได้ตามที่ครูเห็นสมควร)
insert into privileges (name, description, emoji, cost)
select * from (values
  ('เลือกที่นั่ง 1 คาบ',       'เลือกที่นั่งเองได้ 1 คาบเรียน',                 '💺', 40),
  ('ต่อเวลาส่งงาน 1 วัน',      'ขอขยายเวลาส่งงาน 1 ชิ้นออกไปอีก 1 วัน',          '⏰', 80),
  ('คะแนนพิเศษ +1',            'ขอรับคะแนนพิเศษ 1 คะแนน (รวมไม่เกินเพดานที่ครูกำหนด)', '⭐', null::int)
) v(name, description, emoji, cost)
where not exists (select 1 from privileges);

-- ไอเทมกาชา
insert into gacha_items (name, rarity, kind, value, emoji, weight, privilege_id)
select v.name, v.rarity, v.kind, v.value, v.emoji, v.weight,
       (select id from privileges p where p.name = v.priv)
from (values
  ('เหรียญ +10',            'N',   'coins',     10, '🪙', 30, null),
  ('EXP +10',               'N',   'exp',       10, '✨', 25, null),
  ('เหรียญ +25',            'R',   'coins',     25, '💰', 15, null),
  ('EXP +30',               'R',   'exp',       30, '🌟', 12, null),
  ('อวาตาร์ หลอดทดลอง',     'R',   'cosmetic',   0, '🧫', 6,  null),
  ('อวาตาร์ DNA',           'SR',  'cosmetic',   0, '🧬', 4,  null),
  ('อวาตาร์ ขวดกลั่น',      'SR',  'cosmetic',   0, '⚗️', 4,  null),
  ('คูปองเลือกที่นั่ง',      'SR',  'privilege',  0, '💺', 3,  'เลือกที่นั่ง 1 คาบ'),
  ('คูปองต่อเวลาส่งงาน',     'SSR', 'privilege',  0, '⏰', 1,  'ต่อเวลาส่งงาน 1 วัน'),
  ('คูปองคะแนนพิเศษ +1',    'SSR', 'privilege',  0, '⭐', 1,  'คะแนนพิเศษ +1'),
  ('อวาตาร์ นักเล่นแร่แปรธาตุ','SSR', 'cosmetic',  0, '🧙', 1,  null)
) v(name, rarity, kind, value, emoji, weight, priv)
where not exists (select 1 from gacha_items);

-- Achievement (ด้าน "เก็บเวลา" = มาเรียนตรงเวลา / สตรีค / ส่งงานตรงเวลา)
insert into achievements (key, name, description, emoji, metric, threshold, reward_exp, reward_coins)
select * from (values
  ('present_5',   'ตรงเวลาสไตล์ธาตุเฉื่อย', 'มาเรียนตรงเวลาครบ 5 คาบ',          '⏱️', 'present_count',      5,  30, 10),
  ('present_20',  'นาฬิกาอะตอม',            'มาเรียนตรงเวลาครบ 20 คาบ',         '⌚', 'present_count',      20, 100, 30),
  ('streak_5',    'สตรีคไฟลุก',             'มาตรงเวลาติดต่อกัน 5 คาบ',          '🔥', 'attendance_streak',  5,  50, 15),
  ('streak_10',   'ปฏิกิริยาลูกโซ่',         'มาตรงเวลาติดต่อกัน 10 คาบ',         '⚡', 'attendance_streak',  10, 120, 40),
  ('ontime_3',    'ส่งงานทันใจ',            'ส่งงานตรงเวลา 3 ชิ้น',              '📬', 'ontime_submissions', 3,  30, 10),
  ('ontime_10',   'นักส่งงานมือโปร',         'ส่งงานตรงเวลา 10 ชิ้น',             '📦', 'ontime_submissions', 10, 100, 30),
  ('quest_5',     'นักผจญภัยฝึกหัด',         'ทำเควสสำเร็จ 5 ครั้ง',              '🗺️', 'quests_done',        5,  40, 10),
  ('quest_20',    'ฮีโร่แห่งเคมีเรีย',       'ทำเควสสำเร็จ 20 ครั้ง',             '🛡️', 'quests_done',        20, 150, 50),
  ('gacha_10',    'สายสุ่ม',                'สุ่มกาชาครบ 10 ครั้ง',              '🎰', 'gacha_pulls',        10, 30, 0),
  ('level_5',     'เลเวล 5',                'ไปถึงเลเวล 5',                      '🏆', 'level',              5,  0,  30),
  ('level_10',    'เลเวล 10',               'ไปถึงเลเวล 10',                     '👑', 'level',              10, 0,  80)
) v(key, name, description, emoji, metric, threshold, reward_exp, reward_coins)
where not exists (select 1 from achievements);

-- เควส (ประจำวันสุ่มวันละ 3 ข้อ / รายสัปดาห์แสดงทุกข้อ)
insert into quests (title, description, kind, exp, coins, needs_approval)
select * from (values
  ('อ่านบทเรียนก่อนเข้าเรียน', 'อ่านเนื้อหาที่จะเรียนวันนี้ แล้วแจ้งครูเมื่อพร้อม',      'daily', 10, 3, true),
  ('ถามคำถามที่น่าสนใจ',       'ถามคำถามเกี่ยวกับเคมี 1 ข้อในคาบ',                      'daily', 15, 5, true),
  ('ช่วยเพื่อนเข้าใจ',          'อธิบายเรื่องที่เรียนให้เพื่อนฟัง 1 คน',                  'daily', 15, 5, true),
  ('จดโน้ตสรุป',               'สรุปเนื้อหาวันนี้ลงสมุด/โน้ตของตัวเอง',                  'daily', 10, 3, true),
  ('เก็บของให้เรียบร้อย',       'ช่วยจัดห้อง/เก็บอุปกรณ์หลังคาบ',                          'daily', 8,  2, true),
  ('ตอบคำถามท้ายคาบถูก',       'ตอบคำถามท้ายคาบได้ถูกต้อง',                              'daily', 12, 4, true),
  ('ส่งงานครบทุกชิ้นในสัปดาห์', 'ส่งงานทุกชิ้นที่ครูมอบหมายภายในสัปดาห์นี้',              'weekly', 40, 15, true)
) v(title, description, kind, exp, coins, needs_approval)
where not exists (select 1 from quests);


-- ---------- แรงค์ (สไตล์ LoL: แต่ละแรงค์มีดิวิชัน IV→I; Master ขึ้นไปไม่มีดิวิชัน) ----------
insert into ch_ranks (key, name, sort, min_exp, divisions, image)
select * from (values
  ('iron',        'Iron',         1,    0, 4, 'assets/ranks/iron.png'),
  ('bronze',      'Bronze',       2,  100, 4, 'assets/ranks/bronze.png'),
  ('silver',      'Silver',       3,  250, 4, 'assets/ranks/silver.png'),
  ('gold',        'Gold',         4,  450, 4, 'assets/ranks/gold.png'),
  ('platinum',    'Platinum',     5,  700, 4, 'assets/ranks/platinum.png'),
  ('emerald',     'Emerald',      6, 1000, 4, 'assets/ranks/emerald.png'),
  ('diamond',     'Diamond',      7, 1400, 4, 'assets/ranks/diamond.png'),
  ('master',      'Master',       8, 1900, 1, 'assets/ranks/master.png'),
  ('grandmaster', 'Grandmaster',  9, 2500, 1, 'assets/ranks/grandmaster.png'),
  ('challenger',  'Challenger',  10, 3200, 1, 'assets/ranks/challenger.png')
) v(key, name, sort, min_exp, divisions, image)
where not exists (select 1 from ch_ranks);

-- ---------- คลาสตัวละคร (ผลของความสามารถกำหนดตามรหัส key ในฐานข้อมูล แก้ชื่อ/คำอธิบาย/รูปได้ในแอดมิน) ----------
insert into char_classes (key, name, emoji, description, ability, image, sort)
select * from (values
  ('alchemist', 'นักเล่นแร่แปรธาตุ', '⚗️', 'เปลี่ยนความขยันเป็นทอง', 'ได้เหรียญจากเช็คชื่อ ส่งงาน และเควส เพิ่ม +25%', 'assets/avatars/alchemist.png', 1),
  ('scientist', 'นักทดลอง',          '🧪', 'ยิ่งทดลอง ยิ่งเก่ง',        'ได้ EXP จากเช็คชื่อ ส่งงาน และเควส เพิ่ม +15%',    'assets/avatars/scientist.png', 2),
  ('guardian',  'ผู้พิทักษ์',         '🛡️', 'ไม่ทิ้งใครไว้ข้างหลัง',    'มาสาย/ส่งงานช้า ได้รางวัลเต็ม เหมือนตรงเวลา',        'assets/avatars/guardian.png',  3),
  ('seeker',    'นักล่าโชค',          '🍀', 'โชคดีเข้าข้างคนกล้า',       'กาชาการันตี SR ขึ้นไปเร็วขึ้น 2 ครั้ง (ทุก 8 ครั้งแทน 10)', 'assets/avatars/seeker.png',    4)
) v(key, name, emoji, description, ability, image, sort)
where not exists (select 1 from char_classes);

insert into app_settings (key, value) values ('class_change_cost', '100') on conflict (key) do nothing;

-- ---------- ภาพไอเทมกาชา (ใส่เฉพาะไอเทมที่ยังไม่มีรูป) ----------
update gacha_items g set image_url = v.img
from (values
  ('เหรียญ +10',               'assets/items/pouch.png'),
  ('EXP +10',                  'assets/items/crystal.png'),
  ('เหรียญ +25',               'assets/items/chest.png'),
  ('EXP +30',                  'assets/items/wand.png'),
  ('อวาตาร์ หลอดทดลอง',        'assets/items/potion_green.png'),
  ('อวาตาร์ DNA',              'assets/items/microscope.png'),
  ('อวาตาร์ ขวดกลั่น',         'assets/items/potion_red.png'),
  ('คูปองเลือกที่นั่ง',         'assets/items/tile.png'),
  ('คูปองต่อเวลาส่งงาน',        'assets/items/hourglass.png'),
  ('คูปองคะแนนพิเศษ +1',       'assets/items/ticket.png'),
  ('อวาตาร์ นักเล่นแร่แปรธาตุ', 'assets/items/crown.png')
) v(name, img)
where g.name = v.name and g.image_url is null;
