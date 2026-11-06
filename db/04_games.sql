-- =====================================================================
-- Chemistria · รอบที่ 3: มินิเกม (ควิซประจำวัน + จับคู่ธาตุ)
-- รันซ้ำได้ (idempotent) · ต้องรัน 01_schema.sql และ 02_seed.sql ก่อน
-- =====================================================================

create table if not exists quiz_questions (
  id uuid primary key default gen_random_uuid(),
  topic text not null default 'ทั่วไป',
  question text not null,
  a text not null, b text not null, c text not null, d text not null,
  answer int not null default 0 check (answer between 0 and 3),   -- 0=ก 1=ข 2=ค 3=ง
  explain text,
  active boolean not null default true
);

create table if not exists game_plays (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  game text not null check (game in ('quiz','match')),
  play_date date not null default today_th(),
  score int not null default 0,
  correct int,
  exp int not null default 0,
  coins int not null default 0,
  created_at timestamptz default now()
);
create unique index if not exists uq_quiz_once_a_day on game_plays(student_id, play_date) where game = 'quiz';
create index if not exists idx_game_plays_day on game_plays(student_id, play_date);

do $$
declare t text;
begin
  foreach t in array array['quiz_questions','game_plays'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists teacher_all on public.%I', t);
    execute format('create policy teacher_all on public.%I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;

insert into app_settings (key, value) values
  ('game_daily_cap_exp', '40'),     -- EXP รวมจากมินิเกมสูงสุดต่อวัน
  ('quiz_count', '5'),              -- จำนวนข้อควิซประจำวัน
  ('quiz_exp_per_correct', '4'),    -- EXP ต่อข้อที่ตอบถูก
  ('quiz_perfect_bonus', '5'),      -- โบนัส EXP เมื่อถูกทุกข้อ
  ('match_max_exp', '10'),          -- EXP สูงสุดต่อรอบเกมจับคู่ธาตุ
  ('match_plays_per_day', '3')      -- เล่นจับคู่ที่ได้รางวัลสูงสุดกี่รอบต่อวัน
on conflict (key) do nothing;

-- ---------------------------------------------------------------------
-- ฟังก์ชันภายใน
-- ---------------------------------------------------------------------
create or replace function _setting_int(p_key text, p_def int) returns int
language sql stable security definer set search_path = public as $$
  select coalesce((select nullif(value, '')::int from app_settings where key = p_key), p_def)
$$;

create or replace function _game_exp_today(p_sid uuid) returns int
language sql stable security definer set search_path = public as $$
  select coalesce(sum(exp), 0)::int from game_plays where student_id = p_sid and play_date = today_th()
$$;

-- ชุดคำถามของนักเรียนวันนั้น: สุ่มแบบคงที่ต่อคนต่อวัน (เปิดกี่ครั้งก็ได้ชุดเดิม)
create or replace function _quiz_ids(p_sid uuid, p_date date) returns uuid[]
language sql stable security definer set search_path = public as $$
  select coalesce(array_agg(id order by k), '{}') from (
    select id, md5(id::text || p_sid::text || p_date::text) as k
      from quiz_questions where active order by k limit _setting_int('quiz_count', 5)
  ) s
$$;

create or replace function _quiz_streak(p_sid uuid) returns int
language plpgsql stable security definer set search_path = public as $$
declare d date := today_th(); n int := 0;
begin
  if not exists (select 1 from game_plays where student_id = p_sid and game = 'quiz' and play_date = d) then
    d := d - 1;
  end if;
  while exists (select 1 from game_plays where student_id = p_sid and game = 'quiz' and play_date = d) loop
    n := n + 1; d := d - 1;
  end loop;
  return n;
end $$;

-- ---------------------------------------------------------------------
-- RPC นักเรียน
-- ---------------------------------------------------------------------
create or replace function game_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); d date := today_th(); qp game_plays%rowtype;
begin
  select * into qp from game_plays where student_id = sid and game = 'quiz' and play_date = d;
  return json_build_object(
    'exp_today', _game_exp_today(sid),
    'cap', _setting_int('game_daily_cap_exp', 40),
    'quiz_done', found,
    'quiz_score', qp.correct,
    'quiz_exp', qp.exp,
    'quiz_total', coalesce(array_length(_quiz_ids(sid, d), 1), 0),
    'streak', _quiz_streak(sid),
    'per_correct', _setting_int('quiz_exp_per_correct', 4),
    'perfect_bonus', _setting_int('quiz_perfect_bonus', 5),
    'match_plays', (select count(*) from game_plays where student_id = sid and game = 'match' and play_date = d),
    'match_max_plays', _setting_int('match_plays_per_day', 3),
    'match_max_exp', _setting_int('match_max_exp', 10),
    'match_best', (select max(score) from game_plays where student_id = sid and game = 'match' and play_date = d)
  );
end $$;

create or replace function quiz_today(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); d date := today_th(); ids uuid[]; qs json;
begin
  if exists (select 1 from game_plays where student_id = sid and game = 'quiz' and play_date = d) then
    return json_build_object('done', true);
  end if;
  ids := _quiz_ids(sid, d);
  select json_agg(json_build_object('id', q.id, 'topic', q.topic, 'question', q.question,
           'choices', json_build_array(q.a, q.b, q.c, q.d)) order by u.pos)
    into qs
    from unnest(ids) with ordinality as u(id, pos) join quiz_questions q on q.id = u.id;
  return json_build_object('done', false, 'questions', coalesce(qs, '[]'::json));
end $$;

-- ตรวจคำตอบฝั่งเซิร์ฟเวอร์: p_answers = [0..3, ...] เรียงตามข้อที่แสดง (-1 = ไม่ตอบ)
create or replace function quiz_submit(p_token uuid, p_answers jsonb) returns json
language plpgsql security definer set search_path = public as $$
declare
  sid uuid := _sid(p_token); d date := today_th(); ids uuid[]; q quiz_questions%rowtype;
  total int; i int; pick int; corr int := 0; res jsonb := '[]'::jsonb;
  raw int; e int; c int := 0; stk int; cap int := _setting_int('game_daily_cap_exp', 40);
begin
  if p_answers is null or jsonb_typeof(p_answers) <> 'array' then raise exception 'ข้อมูลคำตอบไม่ถูกต้อง'; end if;
  ids := _quiz_ids(sid, d);
  total := coalesce(array_length(ids, 1), 0);
  if total = 0 then raise exception 'ยังไม่มีคำถามในระบบ'; end if;
  if exists (select 1 from game_plays where student_id = sid and game = 'quiz' and play_date = d) then
    raise exception 'วันนี้ทำควิซไปแล้ว พรุ่งนี้มาใหม่นะ';
  end if;
  for i in 1..total loop
    select * into q from quiz_questions where id = ids[i];
    begin pick := coalesce((p_answers ->> (i - 1))::int, -1); exception when others then pick := -1; end;
    if pick = q.answer then corr := corr + 1; end if;
    res := res || jsonb_build_object('id', q.id, 'pick', pick, 'answer', q.answer,
             'ok', pick = q.answer, 'explain', q.explain);
  end loop;
  raw := corr * _setting_int('quiz_exp_per_correct', 4)
         + case when corr = total then _setting_int('quiz_perfect_bonus', 5) else 0 end;
  e := least(raw, greatest(0, cap - _game_exp_today(sid)));
  begin
    insert into game_plays (student_id, game, play_date, score, correct, exp, coins)
    values (sid, 'quiz', d, round(100.0 * corr / total), corr, e, 0);
  exception when unique_violation then
    raise exception 'วันนี้ทำควิซไปแล้ว พรุ่งนี้มาใหม่นะ';
  end;
  stk := _quiz_streak(sid);
  if corr > 0 then c := corr + least(stk - 1, 5); end if;   -- เหรียญ 1/ข้อ + โบนัสทำติดกันหลายวัน (สูงสุด +5)
  update game_plays set coins = c where student_id = sid and game = 'quiz' and play_date = d;
  perform award(sid, e, c, 'ควิซประจำวัน ' || corr || '/' || total, 'game:quiz:' || d);
  return json_build_object('correct', corr, 'total', total, 'exp', e, 'coins', c, 'raw_exp', raw,
                           'capped', e < raw, 'streak', stk, 'results', res);
end $$;

-- เกมจับคู่ธาตุ: เล่นฝั่งเบราว์เซอร์ ส่งผลคะแนน 0-100 มาให้เซิร์ฟเวอร์ (มีเพดานจำนวนรอบ + EXP ต่อวันกันโกง)
create or replace function match_submit(p_token uuid, p_score int, p_pairs int, p_seconds int) returns json
language plpgsql security definer set search_path = public as $$
declare
  sid uuid := _sid(p_token); d date := today_th(); n int; mx int; raw int; e int; c int := 0;
  cap int := _setting_int('game_daily_cap_exp', 40);
begin
  if p_score is null or p_score < 0 or p_score > 100 or p_pairs not between 4 and 12 or p_seconds is null or p_seconds < p_pairs then
    raise exception 'ผลการเล่นไม่ถูกต้อง';
  end if;
  select count(*) into n from game_plays where student_id = sid and game = 'match' and play_date = d;
  mx := _setting_int('match_plays_per_day', 3);
  raw := round(_setting_int('match_max_exp', 10) * p_score / 100.0);
  if n >= mx then
    -- เล่นต่อได้ แต่ไม่ได้รางวัลแล้ว
    insert into game_plays (student_id, game, play_date, score, exp, coins) values (sid, 'match', d, p_score, 0, 0);
    return json_build_object('exp', 0, 'coins', 0, 'score', p_score, 'capped', true, 'no_reward', true, 'plays', n + 1, 'max_plays', mx);
  end if;
  e := least(raw, greatest(0, cap - _game_exp_today(sid)));
  if p_score >= 90 then c := 1; end if;
  insert into game_plays (student_id, game, play_date, score, exp, coins) values (sid, 'match', d, p_score, e, c);
  perform award(sid, e, c, 'จับคู่ธาตุ (' || p_score || ' คะแนน)', 'game:match:' || d || ':' || (n + 1));
  return json_build_object('exp', e, 'coins', c, 'score', p_score, 'capped', e < raw, 'no_reward', false, 'plays', n + 1, 'max_plays', mx);
end $$;

-- ---------------------------------------------------------------------
-- สิทธิ์การเรียกใช้
-- ---------------------------------------------------------------------
revoke execute on function _setting_int(text, int) from public, anon, authenticated;
revoke execute on function _game_exp_today(uuid) from public, anon, authenticated;
revoke execute on function _quiz_ids(uuid, date) from public, anon, authenticated;
revoke execute on function _quiz_streak(uuid) from public, anon, authenticated;
revoke execute on function game_status(uuid) from public;
revoke execute on function quiz_today(uuid) from public;
revoke execute on function quiz_submit(uuid, jsonb) from public;
revoke execute on function match_submit(uuid, int, int, int) from public;
grant execute on function game_status(uuid) to anon, authenticated;
grant execute on function quiz_today(uuid) to anon, authenticated;
grant execute on function quiz_submit(uuid, jsonb) to anon, authenticated;
grant execute on function match_submit(uuid, int, int, int) to anon, authenticated;

-- ---------------------------------------------------------------------
-- คำถามตัวอย่าง 46 ข้อ (เพิ่ม/แก้/ปิดได้ที่หน้าแอดมิน → 🎮 มินิเกม) — ใส่เฉพาะตอนตารางยังว่าง
-- answer: 0=ก 1=ข 2=ค 3=ง
-- ---------------------------------------------------------------------
do $$
begin
  if exists (select 1 from quiz_questions) then return; end if;
  insert into quiz_questions (topic, question, a, b, c, d, answer, explain) values
  ('ตารางธาตุ','ธาตุที่มีสัญลักษณ์ Na คือธาตุใด','โพแทสเซียม','โซเดียม','ไนโตรเจน','นีออน',1,'Na มาจากชื่อละติน natrium คือโซเดียม ส่วนโพแทสเซียมคือ K'),
  ('ตารางธาตุ','ธาตุหมู่ 1 (ยกเว้นไฮโดรเจน) เรียกว่าอะไร','โลหะอัลคาไล','ฮาโลเจน','แก๊สเฉื่อย','โลหะแทรนซิชัน',0,'หมู่ 1 คือโลหะอัลคาไล เช่น Li Na K ทำปฏิกิริยากับน้ำรุนแรง'),
  ('ตารางธาตุ','ธาตุหมู่ 17 เรียกว่าอะไร','แอลคาไลน์เอิร์ท','ฮาโลเจน','แก๊สเฉื่อย','แคลโคเจน',1,'หมู่ 17 คือฮาโลเจน เช่น F Cl Br I มีเวเลนซ์อิเล็กตรอน 7'),
  ('ตารางธาตุ','ข้อใดเป็นแก๊สเฉื่อย','ออกซิเจน','ฮีเลียม','ไนโตรเจน','คลอรีน',1,'แก๊สเฉื่อยอยู่หมู่ 18 มีเวเลนซ์อิเล็กตรอนครบ จึงไม่ค่อยทำปฏิกิริยา'),
  ('ตารางธาตุ','ธาตุใดมีเลขอะตอมน้อยที่สุด','ฮีเลียม','ไฮโดรเจน','ลิเทียม','คาร์บอน',1,'ไฮโดรเจนมีเลขอะตอม 1'),
  ('ตารางธาตุ','ในคาบเดียวกัน จากซ้ายไปขวา ขนาดอะตอมโดยทั่วไปเป็นอย่างไร','เพิ่มขึ้น','ลดลง','เท่าเดิม','เพิ่มแล้วลดสลับกัน',1,'ประจุนิวเคลียสเพิ่ม ดึงอิเล็กตรอนเข้าหาแน่นขึ้น อะตอมจึงเล็กลง'),
  ('ตารางธาตุ','สัญลักษณ์ของธาตุเหล็กคือข้อใด','Ir','F','Fe','Au',2,'Fe มาจากภาษาละติน ferrum'),
  ('ตารางธาตุ','ธาตุใดเป็นโลหะที่เป็นของเหลวที่อุณหภูมิห้อง','ปรอท','เหล็ก','ทองแดง','ซิลิคอน',0,'ปรอท (Hg) เป็นโลหะเพียงชนิดเดียวที่เป็นของเหลวที่อุณหภูมิห้อง'),
  ('ตารางธาตุ','ธาตุใดมีค่าอิเล็กโทรเนกาติวิตีสูงที่สุด','ออกซิเจน','ฟลูออรีน','คลอรีน','ไนโตรเจน',1,'ฟลูออรีนดึงอิเล็กตรอนได้แรงที่สุดในตารางธาตุ'),
  ('โครงสร้างอะตอม','อนุภาคใดในอะตอมมีประจุบวก','อิเล็กตรอน','นิวตรอน','โปรตอน','ไม่มีข้อถูก',2,'โปรตอน (+) นิวตรอน (0) อิเล็กตรอน (−)'),
  ('โครงสร้างอะตอม','เลขอะตอมบอกจำนวนอะไร','นิวตรอน','โปรตอน','นิวคลีออนทั้งหมด','มวลอะตอม',1,'เลขอะตอม = จำนวนโปรตอน (ในอะตอมกลางเท่ากับจำนวนอิเล็กตรอน)'),
  ('โครงสร้างอะตอม','อะตอมหนึ่งมีโปรตอน 6 และนิวตรอน 6 เลขมวลเท่าใด','6','12','18','0',1,'เลขมวล = โปรตอน + นิวตรอน = 6 + 6 = 12'),
  ('โครงสร้างอะตอม','ไอโซโทปของธาตุเดียวกันต่างกันที่อะไร','จำนวนโปรตอน','จำนวนเวเลนซ์อิเล็กตรอน','จำนวนนิวตรอน','ชื่อธาตุ',2,'ไอโซโทปมีโปรตอนเท่ากันแต่นิวตรอนต่างกัน จึงมีเลขมวลต่างกัน'),
  ('โครงสร้างอะตอม','การจัดเรียงอิเล็กตรอนของ Na (เลขอะตอม 11) คือข้อใด','2, 8, 1','2, 8, 2','2, 9','2, 7, 2',0,'ชั้นแรกจุ 2 ชั้นที่สองจุ 8 เหลือ 1 ที่ชั้นนอกสุด'),
  ('โครงสร้างอะตอม','คลอรีน (เลขอะตอม 17) มีเวเลนซ์อิเล็กตรอนกี่ตัว','5','6','7','8',2,'การจัดเรียง 2, 8, 7 จึงมีเวเลนซ์อิเล็กตรอน 7 ตัว'),
  ('พันธะเคมี','NaCl เกิดจากพันธะชนิดใด','โคเวเลนต์','ไอออนิก','โลหะ','ไฮโดรเจน',1,'Na ให้อิเล็กตรอนแก่ Cl เกิดไอออน Na⁺ และ Cl⁻ ดึงดูดกัน'),
  ('พันธะเคมี','พันธะโคเวเลนต์เกิดจากอะไร','การให้และรับอิเล็กตรอน','การใช้อิเล็กตรอนร่วมกัน','แรงดึงดูดของแม่เหล็ก','การแลกเปลี่ยนนิวเคลียส',1,'อะตอมอโลหะใช้อิเล็กตรอนร่วมกันเพื่อให้เวเลนซ์ครบ 8'),
  ('พันธะเคมี','โมเลกุล H₂O มีพันธะระหว่างอะตอมเป็นแบบใด','ไอออนิก','โลหะ','โคเวเลนต์','ไม่มีพันธะ',2,'H และ O เป็นอโลหะ จึงใช้อิเล็กตรอนร่วมกัน'),
  ('พันธะเคมี','สารประกอบไอออนิกโดยทั่วไปมีสมบัติใด','จุดหลอมเหลวต่ำ','จุดหลอมเหลวสูง','เป็นแก๊สที่อุณหภูมิห้อง','นำไฟฟ้าได้ดีเมื่อเป็นของแข็ง',1,'แรงยึดเหนี่ยวระหว่างไอออนแข็งแรงมาก จึงต้องใช้พลังงานสูงในการหลอมเหลว'),
  ('พันธะเคมี','ในโมเลกุล CO₂ มีพันธะคู่ (C=O) กี่พันธะ','1','2','3','4',1,'โครงสร้าง O=C=O มีพันธะคู่ 2 พันธะ'),
  ('ปริมาณสารสัมพันธ์','สาร 1 โมลมีจำนวนอนุภาคเท่าใด','6.02 × 10²³ อนุภาค','6.02 × 10³² อนุภาค','3.01 × 10²³ อนุภาค','1.66 × 10⁻²⁴ อนุภาค',0,'เลขอโวคาโดร = 6.02 × 10²³ ต่อโมล'),
  ('ปริมาณสารสัมพันธ์','มวลโมเลกุลของน้ำ (H = 1, O = 16) เท่าใด','16','17','18','20',2,'(2 × 1) + 16 = 18'),
  ('ปริมาณสารสัมพันธ์','มวลโมเลกุลของ CO₂ (C = 12, O = 16) เท่าใด','28','44','32','56',1,'12 + (2 × 16) = 44'),
  ('ปริมาณสารสัมพันธ์','สารละลายที่มีตัวถูกละลาย 0.5 โมลในสารละลาย 1 ลิตร มีความเข้มข้นกี่โมลาร์','0.5 โมลาร์','2 โมลาร์','5 โมลาร์','1 โมลาร์',0,'โมลาร์ = โมลตัวถูกละลาย ÷ ปริมาตรสารละลาย (ลิตร)'),
  ('ปริมาณสารสัมพันธ์','แก๊สอุดมคติ 1 โมลที่ STP มีปริมาตรกี่ลิตร','11.2','22.4','24.0','44.8',1,'ที่ STP (0 °C, 1 atm) แก๊ส 1 โมล = 22.4 ลิตร'),
  ('กรด-เบส','สารละลายที่มี pH = 3 มีสมบัติอย่างไร','เบส','กลาง','กรด','บอกไม่ได้',2,'pH < 7 เป็นกรด'),
  ('กรด-เบส','น้ำบริสุทธิ์ที่ 25 °C มี pH เท่าใด','0','7','14','1',1,'น้ำบริสุทธิ์เป็นกลาง pH = 7'),
  ('กรด-เบส','ปฏิกิริยาระหว่างกรดกับเบสเรียกว่าอะไร','การเผาไหม้','การสลายตัว','การสะเทิน','การรีดักชัน',2,'กรด + เบส → เกลือ + น้ำ เรียกว่าปฏิกิริยาสะเทิน'),
  ('กรด-เบส','กระดาษลิตมัสสีน้ำเงินเมื่อสัมผัสกรดจะเปลี่ยนเป็นสีใด','แดง','เขียว','เหลือง','ไม่เปลี่ยนสี',0,'กรดทำให้ลิตมัสน้ำเงินเป็นสีแดง เบสทำให้ลิตมัสแดงเป็นสีน้ำเงิน'),
  ('กรด-เบส','HCl จัดเป็นสารประเภทใด','กรดแก่','เบสแก่','เกลือ','สารกลาง',0,'HCl แตกตัวเป็นไอออนได้เกือบสมบูรณ์ในน้ำ จึงเป็นกรดแก่'),
  ('สมบัติของสาร','การเปลี่ยนสถานะจากของแข็งเป็นแก๊สโดยตรงเรียกว่าอะไร','การระเหย','การระเหิด','การควบแน่น','การหลอมเหลว',1,'เช่น น้ำแข็งแห้ง การบูร ลูกเหม็น'),
  ('สมบัติของสาร','น้ำแข็งแห้งคือของแข็งของสารใด','O₂','N₂','CO₂','H₂O',2,'น้ำแข็งแห้งคือคาร์บอนไดออกไซด์ในสถานะของแข็ง'),
  ('สมบัติของสาร','ส่วนผสมที่เป็นเนื้อเดียวกันตลอด เรียกว่าอะไร','สารแขวนลอย','สารละลาย','ธาตุ','สารประกอบ',1,'สารละลายเป็นสารเนื้อเดียว เช่น น้ำเกลือ'),
  ('สมบัติของสาร','ข้อใดเป็นการเปลี่ยนแปลงทางเคมี','น้ำแข็งละลาย','เหล็กเป็นสนิม','น้ำระเหย','ตัดกระดาษ',1,'เหล็กเป็นสนิมเกิดสารใหม่คือเหล็กออกไซด์'),
  ('เคมีอินทรีย์','สารประกอบที่ประกอบด้วย C และ H เท่านั้น เรียกว่าอะไร','คาร์โบไฮเดรต','ไฮโดรคาร์บอน','แอลกอฮอล์','กรดอินทรีย์',1,'ไฮโดรคาร์บอน (Hydro = H, Carbon = C)'),
  ('เคมีอินทรีย์','แอลเคนที่มีคาร์บอน 1 อะตอมคือสารใด','อีเทน','มีเทน','โพรเพน','บิวเทน',1,'มีเทน CH₄ เป็นแอลเคนที่เล็กที่สุด'),
  ('เคมีอินทรีย์','สูตรทั่วไปของแอลเคนคือข้อใด','CₙH₂ₙ','CₙH₂ₙ₊₂','CₙH₂ₙ₋₂','CₙHₙ',1,'เช่น n = 3 → C₃H₈ (โพรเพน)'),
  ('เคมีอินทรีย์','หมู่ฟังก์ชันของแอลกอฮอล์คือข้อใด','–COOH','–OH','–CHO','–NH₂',1,'แอลกอฮอล์มีหมู่ไฮดรอกซิล –OH'),
  ('เคมีอินทรีย์','หมู่ฟังก์ชันของกรดคาร์บอกซิลิกคือข้อใด','–OH','–CHO','–COOH','–CO–',2,'เช่น กรดแอซีติก CH₃COOH ในน้ำส้มสายชู'),
  ('เคมีอินทรีย์','แอลคีนมีลักษณะเฉพาะคือข้อใด','พันธะเดี่ยวทั้งหมด','มีพันธะคู่ C=C','มีพันธะสาม C≡C','มีพันธะไอออนิก',1,'แอลคีนมีพันธะคู่ระหว่างคาร์บอนอย่างน้อย 1 พันธะ สูตร CₙH₂ₙ'),
  ('เคมีอินทรีย์','โพรเพนมีสูตรโมเลกุลใด','C₂H₆','C₃H₈','C₄H₁₀','C₃H₆',1,'แอลเคน C₃ → C₃H₂(₃)₊₂ = C₃H₈'),
  ('เคมีอินทรีย์','เอทานอลมีสูตรโครงสร้างข้อใด','CH₃CH₂OH','CH₃COOH','CH₃CHO','CH₃OCH₃',0,'เอทานอลคือแอลกอฮอล์ที่มี C 2 อะตอม'),
  ('ความปลอดภัย','ก่อนใช้สารเคมีควรอ่านอะไรเป็นอันดับแรก','สลากและข้อมูลความปลอดภัย (SDS)','ราคาสินค้า','สีของขวด','ไม่ต้องอ่าน',0,'อ่านสลากและ SDS เพื่อรู้ความเป็นอันตรายและวิธีใช้อย่างปลอดภัย'),
  ('ความปลอดภัย','ถ้ากรดกระเด็นถูกผิวหนัง ควรทำอย่างไรก่อน','ทาแป้ง','ล้างด้วยน้ำสะอาดปริมาณมากทันที','เช็ดด้วยผ้าแห้ง','รอครู',1,'ล้างด้วยน้ำปริมาณมากทันทีอย่างน้อย 15 นาที แล้วแจ้งครู'),
  ('ความปลอดภัย','ข้อใดห้ามทำในห้องปฏิบัติการ','สวมแว่นตานิรภัย','ชิมสารเคมี','รวบผมยาว','ล้างมือหลังเสร็จ',1,'ห้ามชิมหรือสัมผัสสารเคมีโดยตรง'),
  ('ความปลอดภัย','การเจือจางกรดเข้มข้นควรทำอย่างไร','เทน้ำลงในกรดอย่างรวดเร็ว','เทกรดลงในน้ำอย่างช้าๆ พร้อมคน','ผสมสองอย่างพร้อมกัน','ไม่ต้องคน',1,'เติมกรดลงน้ำเพื่อให้ความร้อนที่เกิดขึ้นกระจายตัวและไม่กระเด็น');
end $$;
