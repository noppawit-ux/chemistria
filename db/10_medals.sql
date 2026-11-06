-- รอบที่ 10: ภาพเหรียญรางวัลของ Achievement (รันซ้ำได้)
alter table achievements add column if not exists image text;
update achievements set image = 'assets/medals/' || key || '.png' where image is null and key in
  ('present_5','present_20','streak_5','streak_10','ontime_3','ontime_10','quest_5','quest_20','gacha_10','level_5','level_10');
