-- =====================================================================
-- 84: Achievement ใหม่ 29 รายการ (ส่งงาน · สอบ · ล่ามอนสเตอร์ · เคมีรัน · การ์ด · ไอเทม · ใช้ไอเทม) + ใส่ภาพตราให้ทุกอัน (รันซ้ำได้)
--  - เงื่อนไขใหม่ใน student_metric: submissions_total, exam_taken/exam_high/exam_full, monster_wins/monster_kinds/trial_passed,
--    run_plays/run_best, cards_owned/cards_ssr/card_sets, gear_owned/gear_rare/gear_maxlv, items_used
--  - นับการใช้ไอเทมตั้งแต่รันไฟล์นี้เป็นต้นไป (ตาราง item_use_log) · ผู้ที่ทำเงื่อนไขได้อยู่แล้วจะได้ตราตอนมีกิจกรรมครั้งถัดไป
--  - ใส่ภาพ assets/medals/*.png ให้เฉพาะตราที่ยังไม่มีภาพ
-- =====================================================================
create table if not exists item_use_log (
  id bigserial primary key,
  student_id uuid not null references students(id) on delete cascade,
  item_id uuid not null,
  used_at timestamptz not null default now()
);
create index if not exists item_use_log_st on item_use_log (student_id);
alter table item_use_log enable row level security;
drop policy if exists teacher_all on item_use_log;
create policy teacher_all on item_use_log for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on item_use_log from anon;
grant select, insert, update, delete on item_use_log to authenticated;
grant usage, select on sequence item_use_log_id_seq to authenticated;

alter table achievements drop constraint if exists achievements_metric_check;
alter table achievements add constraint achievements_metric_check check (metric in (
  'attendance_count', 'present_count', 'attendance_streak', 'ontime_submissions', 'total_exp', 'level', 'gacha_pulls', 'quests_done',
  'kb_plays', 'kb_cleared', 'kb_wins', 'kb_fast',
  'card_sets', 'cards_owned', 'cards_ssr', 'exam_full', 'exam_high', 'exam_taken', 'gear_maxlv', 'gear_owned', 'gear_rare', 'items_used', 'monster_kinds', 'monster_wins', 'run_best', 'run_plays', 'submissions_total', 'trial_passed'));

create or replace function student_metric(p_student uuid, p_metric text) returns int
language plpgsql stable security definer set search_path = public as $$
declare n int := 0; r record;
begin
  case p_metric
    when 'attendance_count' then
      select count(*) into n from ch_attendance where student_id = p_student and status in ('present','late');
    when 'present_count' then
      select count(*) into n from ch_attendance where student_id = p_student and status = 'present';
    when 'attendance_streak' then
      for r in select status from ch_attendance where student_id = p_student order by att_date desc loop
        exit when r.status = 'absent';
        if r.status = 'present' then n := n + 1; end if;
      end loop;
    when 'ontime_submissions' then
      select count(*) into n from ch_submissions where student_id = p_student and status = 'submitted';
    when 'total_exp' then
      select exp into n from students where id = p_student;
    when 'level' then
      select level_for(exp) into n from students where id = p_student;
    when 'gacha_pulls' then
      select count(*) into n from gacha_pulls where student_id = p_student;
    when 'quests_done' then
      select count(*) into n from quest_claims where student_id = p_student and status = 'approved';
    when 'kb_plays' then
      select count(*) into n from game_plays where student_id = p_student and game = 'kb' and (exp > 0 or coins > 0);
    when 'kb_cleared' then
      select coalesce(max(case when score = 100 then 8 else score / 12 end), 0) into n from game_plays where student_id = p_student and game = 'kb' and (exp > 0 or coins > 0);
    when 'kb_wins' then
      select count(*) into n from game_plays where student_id = p_student and game = 'kb' and score = 100 and (exp > 0 or coins > 0);
    when 'kb_fast' then
      select count(*) into n from game_plays where student_id = p_student and game = 'kb' and score = 100 and (exp > 0 or coins > 0) and kb_secs is not null and kb_secs <= 300;
    when 'submissions_total' then
      select count(*) into n from ch_submissions where student_id = p_student and status in ('submitted', 'late');
    when 'exam_taken' then
      select count(*) into n from exam_attempts where student_id = p_student and submitted_at is not null;
    when 'exam_high' then
      select count(*) into n from exam_attempts where student_id = p_student and submitted_at is not null and total > 0 and score is not null and score / total >= 0.8;
    when 'exam_full' then
      select count(*) into n from exam_attempts where student_id = p_student and submitted_at is not null and total > 0 and score is not null and score >= total;
    when 'monster_wins' then
      select count(*) into n from battles where student_id = p_student and status = 'won';
    when 'monster_kinds' then
      select count(distinct monster_id) into n from battles where student_id = p_student and status = 'won';
    when 'trial_passed' then
      select count(*) into n from rank_trial_pass where student_id = p_student;
    when 'run_plays' then
      select count(*) into n from game_plays where student_id = p_student and game = 'run';
    when 'run_best' then
      select coalesce(max(score), 0) into n from game_plays where student_id = p_student and game = 'run';
    when 'cards_owned' then
      select count(*) into n from student_cards where student_id = p_student and qty > 0;
    when 'cards_ssr' then
      select count(*) into n from student_cards sc join cards c on c.id = sc.card_id where sc.student_id = p_student and sc.qty > 0 and c.rarity = 'SSR';
    when 'card_sets' then
      select count(*) into n from student_set_claims where student_id = p_student;
    when 'gear_owned' then
      select count(*) into n from student_decor where student_id = p_student;
    when 'gear_rare' then
      select count(*) into n from student_decor sd join decor_items d on d.id = sd.item_id where sd.student_id = p_student and d.rarity in ('SR', 'SSR', 'LEG');
    when 'gear_maxlv' then
      select coalesce(max(lvl), 0) into n from student_decor where student_id = p_student;
    when 'items_used' then
      select count(*) into n from item_use_log where student_id = p_student;
    else n := 0;
  end case;
  return coalesce(n, 0);
end $$;
revoke execute on function student_metric(uuid, text) from public, anon, authenticated;

-- บันทึกการใช้ไอเทม: เมื่อจำนวนไอเทมสิ้นเปลืองลดลง 1 หน่วย = ใช้ 1 ครั้ง
create or replace function trg_item_use_log() returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.qty < old.qty then insert into item_use_log (student_id, item_id) select new.student_id, new.item_id from generate_series(1, old.qty - new.qty); end if;
  return new;
end $$;
drop trigger if exists item_use_log_t on student_items;
create trigger item_use_log_t after update of qty on student_items for each row when (new.qty < old.qty) execute function trg_item_use_log();

-- ตรวจ achievement ทันทีเมื่อมีกิจกรรมที่เกี่ยวข้อง
create or replace function trg_ach_student() returns trigger language plpgsql security definer set search_path = public as $$
begin perform check_achievements(new.student_id); return new; end $$;
revoke execute on function trg_item_use_log(), trg_ach_student() from public, anon, authenticated;
drop trigger if exists ach_chk on ch_submissions;   create trigger ach_chk after insert or update on ch_submissions for each row execute function trg_ach_student();
drop trigger if exists ach_chk on exam_attempts;    create trigger ach_chk after update on exam_attempts for each row when (new.submitted_at is not null) execute function trg_ach_student();
drop trigger if exists ach_chk on battles;          create trigger ach_chk after update on battles for each row when (new.status = 'won') execute function trg_ach_student();
drop trigger if exists ach_chk on rank_trial_pass;  create trigger ach_chk after insert on rank_trial_pass for each row execute function trg_ach_student();
drop trigger if exists ach_chk on game_plays;       create trigger ach_chk after insert on game_plays for each row execute function trg_ach_student();
drop trigger if exists ach_chk on student_cards;    create trigger ach_chk after insert or update on student_cards for each row execute function trg_ach_student();
drop trigger if exists ach_chk on student_set_claims; create trigger ach_chk after insert on student_set_claims for each row execute function trg_ach_student();
drop trigger if exists ach_chk on student_decor;    create trigger ach_chk after insert or update on student_decor for each row execute function trg_ach_student();
drop trigger if exists ach_chk on item_use_log;     create trigger ach_chk after insert on item_use_log for each row execute function trg_ach_student();

-- รายการ achievement ใหม่
insert into achievements (key, name, description, emoji, metric, threshold, reward_exp, reward_coins)
select v.* from (values
    ('sub_1', 'ส่งงานชิ้นแรก', 'ส่งงานครบ 1 ชิ้น (ตรงเวลาหรือสาย)', '📜', 'submissions_total', 1, 15, 5),
    ('sub_25', 'นักส่งงานตัวยง', 'ส่งงานสะสม 25 ชิ้น', '📨', 'submissions_total', 25, 60, 25),
    ('sub_50', 'ราชาแห่งการส่งงาน', 'ส่งงานสะสม 50 ชิ้น', '👑', 'submissions_total', 50, 120, 50),
    ('exam_1', 'นักสอบหน้าใหม่', 'ส่งข้อสอบออนไลน์ครั้งแรก', '📝', 'exam_taken', 1, 20, 10),
    ('exam_5', 'สนามสอบคุ้นเคย', 'ส่งข้อสอบออนไลน์ 5 ครั้ง', '📘', 'exam_taken', 5, 60, 25),
    ('exam_high_3', 'คะแนนสูงติดปีก', 'ได้คะแนนสอบตั้งแต่ 80% ขึ้นไป 3 ครั้ง', '🌟', 'exam_high', 3, 80, 30),
    ('exam_full_1', 'เต็มร้อย!', 'ทำข้อสอบได้คะแนนเต็มหนึ่งครั้ง', '🏆', 'exam_full', 1, 100, 50),
    ('mon_1', 'นักล่ามือใหม่', 'ชนะมอนสเตอร์ครั้งแรก', '🗡️', 'monster_wins', 1, 15, 5),
    ('mon_10', 'นักล่าตัวจริง', 'ชนะมอนสเตอร์ 10 ครั้ง', '⚔️', 'monster_wins', 10, 60, 25),
    ('mon_30', 'เจ้าแห่งสนามต่อสู้', 'ชนะมอนสเตอร์ 30 ครั้ง', '💀', 'monster_wins', 30, 150, 60),
    ('mon_kinds_8', 'นักสำรวจมอนสเตอร์', 'เคยปราบมอนสเตอร์ครบ 8 ชนิดที่ต่างกัน', '🧭', 'monster_kinds', 8, 100, 40),
    ('trial_1', 'ผ่านด่านแรงค์', 'ชนะบอสเลื่อนแรงค์ครั้งแรก', '🛡️', 'trial_passed', 1, 80, 30),
    ('trial_4', 'ผู้พิชิตด่านแรงค์', 'ชนะบอสเลื่อนแรงค์ 4 ด่าน', '🏰', 'trial_passed', 4, 200, 80),
    ('run_1', 'ออกสตาร์ท', 'เล่นเคมีรันครั้งแรก', '🏃', 'run_plays', 1, 10, 5),
    ('run_20', 'นักวิ่งเคมี', 'เล่นเคมีรัน 20 ครั้ง', '👟', 'run_plays', 20, 60, 25),
    ('run_800', 'ทะลุแปดร้อย', 'ทำคะแนนเคมีรันได้ 800 ขึ้นไป', '⚡', 'run_best', 800, 50, 20),
    ('run_2000', 'นักวิ่งตำนาน', 'ทำคะแนนเคมีรันได้ 2,000 ขึ้นไป', '🔥', 'run_best', 2000, 150, 60),
    ('card_5', 'นักสะสมมือใหม่', 'สะสมการ์ดได้ 5 ใบ (ไม่ซ้ำ)', '🃏', 'cards_owned', 5, 20, 10),
    ('card_20', 'สมุดการ์ดเริ่มหนา', 'สะสมการ์ดได้ 20 ใบ (ไม่ซ้ำ)', '📖', 'cards_owned', 20, 80, 30),
    ('card_40', 'ราชาการ์ด', 'สะสมการ์ดได้ 40 ใบ (ไม่ซ้ำ)', '💎', 'cards_owned', 40, 200, 80),
    ('card_set_1', 'ครบชุดแรก', 'สะสมการ์ดครบ 1 ชุดและรับรางวัลแล้ว', '🧩', 'card_sets', 1, 60, 30),
    ('card_ssr_1', 'การ์ดตำนาน', 'มีการ์ดระดับ SSR อย่างน้อย 1 ใบ', '✨', 'cards_ssr', 1, 80, 30),
    ('gear_5', 'นักสะสมอุปกรณ์', 'มีไอเทมแต่งตัว/อุปกรณ์ 5 ชิ้น', '🎒', 'gear_owned', 5, 30, 15),
    ('gear_20', 'ตู้โชว์เต็มห้อง', 'มีไอเทมแต่งตัว/อุปกรณ์ 20 ชิ้น', '🧰', 'gear_owned', 20, 100, 40),
    ('gear_rare_3', 'ของหายากเพียบ', 'มีไอเทมระดับ SR ขึ้นไป 3 ชิ้น', '💍', 'gear_rare', 3, 80, 30),
    ('gear_lv3', 'ช่างตีบวก', 'อัปเกรดอุปกรณ์ชิ้นใดชิ้นหนึ่งถึงเลเวล 3', '🔨', 'gear_maxlv', 3, 100, 40),
    ('use_1', 'ลองใช้ไอเทม', 'ใช้ไอเทมสิ้นเปลือง (ยา/ม้วน/ตั๋ว) ครั้งแรก', '🧪', 'items_used', 1, 10, 5),
    ('use_10', 'นักใช้ยา', 'ใช้ไอเทมสิ้นเปลืองสะสม 10 ครั้ง', '⚗️', 'items_used', 10, 50, 20),
    ('use_30', 'ปรมาจารย์ยา', 'ใช้ไอเทมสิ้นเปลืองสะสม 30 ครั้ง', '🧙', 'items_used', 30, 120, 50)
) v(key, name, description, emoji, metric, threshold, reward_exp, reward_coins)
on conflict (key) do nothing;

update achievements a set image = v.img
  from (values
    ('sub_1', 'assets/medals/sub_1.png'),
    ('sub_25', 'assets/medals/sub_25.png'),
    ('sub_50', 'assets/medals/sub_50.png'),
    ('exam_1', 'assets/medals/exam_1.png'),
    ('exam_5', 'assets/medals/exam_5.png'),
    ('exam_high_3', 'assets/medals/exam_high_3.png'),
    ('exam_full_1', 'assets/medals/exam_full_1.png'),
    ('mon_1', 'assets/medals/mon_1.png'),
    ('mon_10', 'assets/medals/mon_10.png'),
    ('mon_30', 'assets/medals/mon_30.png'),
    ('mon_kinds_8', 'assets/medals/mon_kinds_8.png'),
    ('trial_1', 'assets/medals/trial_1.png'),
    ('trial_4', 'assets/medals/trial_4.png'),
    ('run_1', 'assets/medals/run_1.png'),
    ('run_20', 'assets/medals/run_20.png'),
    ('run_800', 'assets/medals/run_800.png'),
    ('run_2000', 'assets/medals/run_2000.png'),
    ('card_5', 'assets/medals/card_5.png'),
    ('card_20', 'assets/medals/card_20.png'),
    ('card_40', 'assets/medals/card_40.png'),
    ('card_set_1', 'assets/medals/card_set_1.png'),
    ('card_ssr_1', 'assets/medals/card_ssr_1.png'),
    ('gear_5', 'assets/medals/gear_5.png'),
    ('gear_20', 'assets/medals/gear_20.png'),
    ('gear_rare_3', 'assets/medals/gear_rare_3.png'),
    ('gear_lv3', 'assets/medals/gear_lv3.png'),
    ('use_1', 'assets/medals/use_1.png'),
    ('use_10', 'assets/medals/use_10.png'),
    ('use_30', 'assets/medals/use_30.png'),
    ('kb_round4', 'assets/medals/kb_round4.png'),
    ('kb_round7', 'assets/medals/kb_round7.png'),
    ('kb_fast', 'assets/medals/kb_fast.png'),
    ('kb_play_1', 'assets/medals/kb_play_1.png'),
    ('kb_win_1', 'assets/medals/kb_win_1.png'),
    ('kb_win_3', 'assets/medals/kb_win_3.png'),
    ('kb_win_10', 'assets/medals/kb_win_10.png')
  ) v(k, img)
 where a.key = v.k and a.image is null;
