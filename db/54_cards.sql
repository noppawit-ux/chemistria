-- =====================================================================
-- 54: การ์ดสะสม (📖 สมุดสะสม) · รันซ้ำได้
--  • ชุดการ์ดเคมี 3 ชุดตั้งต้น (ธาตุ 36 · นักเคมี 12 · อุปกรณ์แล็บ 12) พร้อมข้อเท็จจริง 1 บรรทัดต่อใบ — ครูเพิ่ม/แก้ได้ในแอดมิน
--  • ได้การ์ดจาก: จบเกม (สุ่ม · เพดานต่อวัน · โอกาสเพิ่มเมื่อทำสถิติใหม่) · กาชา · ครูแจก
--  • ซ้ำ → เศษธาตุ (ใช้อัปอุปกรณ์ในเฟสถัดไป) · pity รับประกันใบใหม่ · สะสมครบชุดรับรางวัล
-- =====================================================================
create table if not exists card_sets (
  id uuid primary key default gen_random_uuid(),
  code text not null unique, title text not null, emoji text not null default '📖', color text not null default '#7c4dff',
  reward_coins int not null default 100, reward_pulls int not null default 1,
  reward_decor uuid references decor_items(id) on delete set null,
  sort int not null default 0, active boolean not null default true
);
create table if not exists cards (
  id uuid primary key default gen_random_uuid(),
  set_id uuid not null references card_sets(id) on delete cascade,
  no int not null, name text not null, symbol text not null default '', emoji text not null default '🃏',
  rarity text not null check (rarity in ('N', 'R', 'SR', 'SSR')),
  fact text not null default '', image_url text, active boolean not null default true,
  unique (set_id, no)
);
create table if not exists student_cards (
  student_id uuid not null references students(id) on delete cascade,
  card_id uuid not null references cards(id) on delete cascade,
  qty int not null default 1, first_at timestamptz not null default now(),
  primary key (student_id, card_id)
);
create table if not exists student_set_claims (
  student_id uuid not null references students(id) on delete cascade,
  set_id uuid not null references card_sets(id) on delete cascade,
  claimed_at timestamptz not null default now(), primary key (student_id, set_id)
);
create table if not exists card_drops (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  card_id uuid references cards(id) on delete set null,
  source text not null check (source in ('game', 'gacha', 'gift')), game text,
  is_new boolean, shards int not null default 0,
  play_date date not null default today_th(), created_at timestamptz not null default now()
);
create index if not exists card_drops_day on card_drops(student_id, play_date, source);
alter table students add column if not exists shards int not null default 0;
alter table students add column if not exists card_pity int not null default 0;
alter table game_plays add column if not exists card_rolled boolean not null default false;
alter table game_plays add column if not exists best_hit boolean not null default false;
alter table battles add column if not exists card_rolled boolean not null default false;
alter table gifts add column if not exists card_id uuid references cards(id) on delete set null;
alter table gifts add column if not exists card_n int not null default 0;

do $$ declare t text; begin
  foreach t in array array['card_sets', 'cards', 'student_cards', 'student_set_claims', 'card_drops'] loop
    execute format('alter table %I enable row level security', t);
    execute format('drop policy if exists teacher_all on %I', t);
    execute format('create policy teacher_all on %I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on %I from anon', t);
  end loop;
end $$;

insert into app_settings (key, value) values
  ('card_drop_pct', '30'), ('card_best_bonus', '25'), ('card_daily_cap', '5'), ('card_pity', '4'), ('card_gacha_pct', '40'),
  ('card_w_n', '60'), ('card_w_r', '28'), ('card_w_sr', '10'), ('card_w_ssr', '2')
on conflict (key) do nothing;

-- ---------- ชุดการ์ดตั้งต้น ----------
insert into card_sets (code, title, emoji, color, reward_coins, reward_pulls, sort) values
  ('elements', 'ธาตุรอบตัว', '⚛️', '#4dabf7', 300, 3, 1),
  ('chemists', 'นักเคมีผู้ยิ่งใหญ่', '🧑‍🔬', '#ffb300', 200, 2, 2),
  ('lab', 'อุปกรณ์ห้องแล็บ', '🧪', '#51cf66', 150, 2, 3)
on conflict (code) do nothing;

insert into cards (set_id, no, name, symbol, emoji, rarity, fact)
select s.id, v.no, v.name, v.symbol, v.emoji, v.rarity, v.fact
from (values
 ('elements', 1, 'ไฮโดรเจน', 'H', '🎈', 'N', 'ธาตุที่เบาที่สุด และมีมากที่สุดในเอกภพ'),
 ('elements', 2, 'ฮีเลียม', 'He', '🎈', 'N', 'ไม่ติดไฟ จึงใช้บรรจุลูกโป่งให้ลอยได้อย่างปลอดภัย'),
 ('elements', 3, 'ลิเทียม', 'Li', '🔋', 'R', 'โลหะที่เบาที่สุด ใช้ทำแบตเตอรี่ในโทรศัพท์และรถยนต์ไฟฟ้า'),
 ('elements', 4, 'คาร์บอน', 'C', '✏️', 'N', 'เพชรและไส้ดินสอ (แกรไฟต์) ล้วนเป็นคาร์บอนเหมือนกัน'),
 ('elements', 5, 'ไนโตรเจน', 'N', '💨', 'N', 'เป็นก๊าซประมาณ 78% ของอากาศที่เราหายใจ'),
 ('elements', 6, 'ออกซิเจน', 'O', '🫁', 'N', 'จำเป็นต่อการหายใจและการเผาไหม้'),
 ('elements', 7, 'ฟลูออรีน', 'F', '🦷', 'R', 'สารประกอบของฟลูออรีนในยาสีฟันช่วยป้องกันฟันผุ'),
 ('elements', 8, 'นีออน', 'Ne', '💡', 'R', 'เรืองแสงสีส้มแดงในหลอดป้ายไฟนีออน'),
 ('elements', 9, 'โซเดียม', 'Na', '🧂', 'N', 'ทำปฏิกิริยารุนแรงกับน้ำ แต่รวมกับคลอรีนเป็นเกลือแกงที่เรากินได้'),
 ('elements', 10, 'แมกนีเซียม', 'Mg', '🎆', 'N', 'เผาไหม้ด้วยแสงสว่างจ้า จึงใช้ทำพลุและแฟลชรุ่นเก่า'),
 ('elements', 11, 'อะลูมิเนียม', 'Al', '🥫', 'N', 'เบาและไม่เป็นสนิม ใช้ทำกระป๋องเครื่องดื่มและฟอยล์'),
 ('elements', 12, 'ซิลิคอน', 'Si', '💻', 'R', 'วัสดุหลักของชิปคอมพิวเตอร์และเซลล์สุริยะ'),
 ('elements', 13, 'ฟอสฟอรัส', 'P', '🧬', 'R', 'เป็นส่วนประกอบของ DNA กระดูก และพลังงาน ATP ในร่างกาย'),
 ('elements', 14, 'กำมะถัน', 'S', '🌋', 'N', 'ใช้ผลิตกรดซัลฟิวริก ซึ่งเป็นสารเคมีที่ผลิตมากที่สุดในโลก'),
 ('elements', 15, 'คลอรีน', 'Cl', '🏊', 'N', 'ใช้ฆ่าเชื้อโรคในน้ำประปาและสระว่ายน้ำ'),
 ('elements', 16, 'อาร์กอน', 'Ar', '🔆', 'R', 'ก๊าซเฉื่อยที่มีมากเป็นอันดับสามในอากาศ ใช้บรรจุในหลอดไฟ'),
 ('elements', 17, 'โพแทสเซียม', 'K', '🍌', 'N', 'พบมากในกล้วย และจำเป็นต่อการทำงานของเส้นประสาทและกล้ามเนื้อ'),
 ('elements', 18, 'แคลเซียม', 'Ca', '🥛', 'N', 'สร้างกระดูกและฟัน พบมากในนมและเปลือกไข่'),
 ('elements', 19, 'ไทเทเนียม', 'Ti', '🦿', 'R', 'แข็งแรงแต่เบา และเข้ากับร่างกายได้ดี ใช้ทำรากฟันเทียม'),
 ('elements', 20, 'โครเมียม', 'Cr', '🚗', 'R', 'ให้ผิวเงาวับของชิ้นส่วนโครเมียมบนรถและก๊อกน้ำ'),
 ('elements', 21, 'เหล็ก', 'Fe', '🩸', 'N', 'อยู่ในฮีโมโกลบินของเลือด ช่วยลำเลียงออกซิเจนทั่วร่างกาย'),
 ('elements', 22, 'โคบอลต์', 'Co', '🔵', 'R', 'ให้สีน้ำเงินสดในเครื่องเคลือบและแก้ว'),
 ('elements', 23, 'นิกเกิล', 'Ni', '🪙', 'N', 'ใช้ทำเหรียญและผสมเป็นโลหะผสมสเตนเลส'),
 ('elements', 24, 'ทองแดง', 'Cu', '🔌', 'N', 'นำไฟฟ้าได้ดีมาก จึงใช้ทำสายไฟ'),
 ('elements', 25, 'สังกะสี', 'Zn', '🏠', 'R', 'ใช้เคลือบเหล็กกันสนิม เช่น หลังคาสังกะสี'),
 ('elements', 26, 'โบรมีน', 'Br', '🧪', 'R', 'อโลหะชนิดเดียวที่เป็นของเหลวที่อุณหภูมิห้อง'),
 ('elements', 27, 'เงิน', 'Ag', '🥈', 'R', 'นำไฟฟ้าและความร้อนได้ดีที่สุดในบรรดาโลหะทั้งหมด'),
 ('elements', 28, 'ดีบุก', 'Sn', '🥫', 'N', 'ใช้เคลือบกระป๋องอาหารกันสนิม จึงเรียกว่า “กระป๋องดีบุก”'),
 ('elements', 29, 'ไอโอดีน', 'I', '🧂', 'R', 'จำเป็นต่อต่อมไทรอยด์ พบในเกลือเสริมไอโอดีน'),
 ('elements', 30, 'ทังสเตน', 'W', '💡', 'SR', 'โลหะที่มีจุดหลอมเหลวสูงที่สุด ใช้ทำไส้หลอดไฟ'),
 ('elements', 31, 'แพลทินัม', 'Pt', '💍', 'SR', 'ใช้เป็นตัวเร่งปฏิกิริยาในท่อไอเสียรถยนต์ และทำเครื่องประดับ'),
 ('elements', 32, 'ทองคำ', 'Au', '🥇', 'SR', 'ไม่ทำปฏิกิริยากับอากาศ จึงไม่หมองและเงางามมานับพันปี'),
 ('elements', 33, 'ปรอท', 'Hg', '🌡️', 'SR', 'โลหะชนิดเดียวที่เป็นของเหลวที่อุณหภูมิห้อง (แต่เป็นพิษ ห้ามสัมผัส)'),
 ('elements', 34, 'ตะกั่ว', 'Pb', '⚖️', 'R', 'หนักและอ่อน เคยใช้ทำท่อน้ำ ปัจจุบันจำกัดการใช้เพราะเป็นพิษ'),
 ('elements', 35, 'เรเดียม', 'Ra', '☢️', 'SSR', 'มารี คูรี ค้นพบ สารประกอบของมันเรืองแสงจาง ๆ ในที่มืด'),
 ('elements', 36, 'ยูเรเนียม', 'U', '⚡', 'SSR', 'เชื้อเพลิงของโรงไฟฟ้านิวเคลียร์'),
 ('chemists', 1, 'โรเบิร์ต บอยล์', 'Boyle', '🧑‍🔬', 'N', 'ค้นพบว่าก๊าซความดันสูงขึ้นปริมาตรจะลดลง (กฎของบอยล์)'),
 ('chemists', 2, 'หลุยส์ ปาสเตอร์', 'Pasteur', '🧑‍🔬', 'N', 'คิดวิธีพาสเจอไรซ์ ฆ่าเชื้อในนมและเครื่องดื่มด้วยความร้อน'),
 ('chemists', 3, 'อาเมเดโอ อาโวกาโดร', 'Avogadro', '🧑‍🔬', 'N', 'เลขอาโวกาโดร (6.02×10²³) ตั้งชื่อเป็นเกียรติแก่เขา'),
 ('chemists', 4, 'จอห์น ดอลตัน', 'Dalton', '⚛️', 'N', 'เสนอทฤษฎีอะตอมว่าสสารประกอบด้วยอะตอมเล็ก ๆ'),
 ('chemists', 5, 'อ็องตวน ลาวัวซีเย', 'Lavoisier', '⚖️', 'R', 'บิดาแห่งเคมีสมัยใหม่ ชี้ว่ามวลสารก่อนและหลังทำปฏิกิริยาเท่ากัน'),
 ('chemists', 6, 'เออร์เนสต์ รัทเทอร์ฟอร์ด', 'Rutherford', '☄️', 'R', 'ค้นพบนิวเคลียสของอะตอมจากการยิงอนุภาคแอลฟาใส่แผ่นทองคำ'),
 ('chemists', 7, 'นีลส์ โบร์', 'Bohr', '🌀', 'R', 'เสนอแบบจำลองอะตอมที่อิเล็กตรอนวิ่งตามระดับพลังงาน'),
 ('chemists', 8, 'โดโรธี ฮอดจ์กิน', 'Hodgkin', '🔬', 'R', 'ใช้รังสีเอกซ์หาโครงสร้างเพนิซิลลินและอินซูลิน ได้รางวัลโนเบลสาขาเคมี'),
 ('chemists', 9, 'ดิมิทรี เมนเดเลเยฟ', 'Mendeleev', '📊', 'SR', 'จัดตารางธาตุและเว้นช่องว่างไว้ทำนายธาตุที่ยังไม่ถูกค้นพบ'),
 ('chemists', 10, 'อัลเฟรด โนเบล', 'Nobel', '🏅', 'SR', 'นักเคมีผู้ประดิษฐ์ไดนาไมต์ และตั้งรางวัลโนเบลจากพินัยกรรมของเขา'),
 ('chemists', 11, 'ไลนัส พอลิง', 'Pauling', '🧬', 'SR', 'ได้รางวัลโนเบลสองครั้ง คือสาขาเคมีและสาขาสันติภาพ'),
 ('chemists', 12, 'มารี คูรี', 'Curie', '☢️', 'SSR', 'ได้รางวัลโนเบลสองสาขา (ฟิสิกส์และเคมี) ค้นพบธาตุพอโลเนียมและเรเดียม'),
 ('lab', 1, 'บีกเกอร์', 'Beaker', '🥛', 'N', 'ใช้ใส่และผสมสาร ขีดบอกปริมาตรข้างแก้วเป็นเพียงค่าโดยประมาณ'),
 ('lab', 2, 'ขวดรูปกรวย', 'Flask', '⚗️', 'N', 'ทรงกรวยช่วยให้เขย่าสารได้โดยไม่กระฉอกออก'),
 ('lab', 3, 'กระบอกตวง', 'Cylinder', '📏', 'N', 'วัดปริมาตรของเหลวได้แม่นกว่าบีกเกอร์ ให้อ่านค่าที่ระดับสายตา'),
 ('lab', 4, 'หลอดทดลอง', 'Tube', '🧪', 'N', 'ใช้ทดสอบปฏิกิริยาของสารปริมาณน้อย'),
 ('lab', 5, 'ตะเกียงแอลกอฮอล์', 'Lamp', '🔥', 'N', 'ให้ความร้อนในห้องปฏิบัติการ ห้ามเติมแอลกอฮอล์ขณะไฟยังติดอยู่'),
 ('lab', 6, 'แว่นตานิรภัย', 'Goggles', '🥽', 'N', 'ต้องสวมทุกครั้งที่ทดลอง ป้องกันสารกระเด็นเข้าตา'),
 ('lab', 7, 'ปิเปตต์', 'Pipette', '💧', 'R', 'ดูดและถ่ายของเหลวในปริมาตรที่แม่นยำ'),
 ('lab', 8, 'บิวเรตต์', 'Burette', '🧴', 'R', 'ใช้หยดสารละลายทีละน้อยเพื่อไทเทรต'),
 ('lab', 9, 'เครื่องชั่งละเอียด', 'Balance', '⚖️', 'R', 'ชั่งมวลสารได้ละเอียดหลายตำแหน่งทศนิยม'),
 ('lab', 10, 'ตู้ดูดควัน', 'Hood', '🌬️', 'R', 'ดูดไอสารพิษออกจากโต๊ะทดลองเพื่อความปลอดภัย'),
 ('lab', 11, 'เครื่องเหวี่ยงแยก', 'Centrifuge', '🌀', 'SR', 'ใช้แรงเหวี่ยงแยกตะกอนออกจากของเหลว'),
 ('lab', 12, 'เครื่อง NMR', 'NMR', '🧲', 'SSR', 'ตรวจโครงสร้างโมเลกุลด้วยสนามแม่เหล็กแรงสูง หลักการเดียวกับเครื่อง MRI')
) as v(code, no, name, symbol, emoji, rarity, fact)
join card_sets s on s.code = v.code
on conflict (set_id, no) do nothing;

-- ---------- ฟังก์ชันภายใน ----------
create or replace function _card_shards(p_rarity text) returns int language sql immutable as
$$ select case p_rarity when 'SSR' then 30 when 'SR' then 10 when 'R' then 3 else 1 end $$;

-- เลือกการ์ด: สุ่มระดับตามน้ำหนัก แล้วสุ่มใบในระดับนั้น (p_new = เฉพาะใบที่ยังไม่มี)
create or replace function _card_pick(p_sid uuid, p_new boolean) returns uuid
language plpgsql security definer set search_path = public as $$
declare rs text[] := array['N', 'R', 'SR', 'SSR'];
  ws numeric[] := array[_setting_int('card_w_n', 60), _setting_int('card_w_r', 28), _setting_int('card_w_sr', 10), _setting_int('card_w_ssr', 2)];
  av numeric[] := array[0, 0, 0, 0]; i int; tot numeric := 0; r numeric; acc numeric := 0; pick text; cid uuid;
begin
  for i in 1..4 loop
    if ws[i] > 0 and exists (select 1 from cards c join card_sets s on s.id = c.set_id where c.active and s.active and c.rarity = rs[i]
         and (not p_new or not exists (select 1 from student_cards sc where sc.student_id = p_sid and sc.card_id = c.id))) then
      av[i] := ws[i]; tot := tot + ws[i];
    end if;
  end loop;
  if tot <= 0 then return null; end if;
  r := random() * tot;
  for i in 1..4 loop
    if av[i] > 0 then pick := rs[i]; acc := acc + av[i]; if r < acc then exit; end if; end if;
  end loop;
  select c.id into cid from cards c join card_sets s on s.id = c.set_id where c.active and s.active and c.rarity = pick
     and (not p_new or not exists (select 1 from student_cards sc where sc.student_id = p_sid and sc.card_id = c.id)) order by random() limit 1;
  return cid;
end $$;

-- มอบการ์ด 1 ใบ: ซ้ำ → เศษธาตุ · ครบชุด → รางวัล (ครั้งเดียวต่อชุด)
create or replace function _card_grant(p_sid uuid, p_card uuid, p_source text, p_game text default null) returns jsonb
language plpgsql security definer set search_path = public as $$
declare c cards%rowtype; st card_sets%rowtype; isnew boolean; sh int := 0; done jsonb := null; tot int; own int;
begin
  select * into c from cards where id = p_card;
  if c.id is null then raise exception 'ไม่พบการ์ด'; end if;
  select * into st from card_sets where id = c.set_id;
  insert into student_cards (student_id, card_id) values (p_sid, p_card)
    on conflict (student_id, card_id) do update set qty = student_cards.qty + 1 returning (xmax = 0) into isnew;
  if isnew then update students set card_pity = 0 where id = p_sid;
  else sh := _card_shards(c.rarity); update students set shards = shards + sh, card_pity = card_pity + 1 where id = p_sid; end if;
  insert into card_drops (student_id, card_id, source, game, is_new, shards) values (p_sid, p_card, p_source, p_game, isnew, sh);
  if isnew then
    select count(*) into tot from cards where set_id = c.set_id and active;
    select count(*) into own from student_cards sc join cards x on x.id = sc.card_id where sc.student_id = p_sid and x.set_id = c.set_id and x.active;
    if tot > 0 and own >= tot and not exists (select 1 from student_set_claims where student_id = p_sid and set_id = c.set_id) then
      insert into student_set_claims (student_id, set_id) values (p_sid, c.set_id);
      if st.reward_coins > 0 then perform award(p_sid, 0, st.reward_coins, '📖 สะสมการ์ดครบชุด ' || st.title, 'cardset:' || c.set_id); end if;
      if st.reward_pulls > 0 then update students set free_pulls = free_pulls + st.reward_pulls where id = p_sid; end if;
      if st.reward_decor is not null then insert into student_decor (student_id, item_id, source) values (p_sid, st.reward_decor, 'teacher') on conflict do nothing; end if;
      done := jsonb_build_object('title', st.title, 'coins', st.reward_coins, 'pulls', st.reward_pulls);
    end if;
  end if;
  return jsonb_build_object('id', c.id, 'name', c.name, 'symbol', c.symbol, 'emoji', c.emoji, 'rarity', c.rarity, 'fact', c.fact,
                            'image', c.image_url, 'set', st.title, 'set_emoji', st.emoji, 'is_new', isnew, 'shards', sh, 'set_done', done);
end $$;

-- สุ่มการ์ด 1 ใบให้นักเรียน (pity: ซ้ำติดกันครบเกณฑ์ → ใบถัดไปเป็นใบใหม่แน่นอน)
create or replace function _card_draw(p_sid uuid, p_source text, p_game text) returns jsonb
language plpgsql security definer set search_path = public as $$
declare pity int := greatest(1, _setting_int('card_pity', 4)); pt int; cid uuid; force boolean;
begin
  select card_pity into pt from students where id = p_sid;
  force := coalesce(pt, 0) >= pity - 1 or not exists (select 1 from student_cards where student_id = p_sid);
  cid := _card_pick(p_sid, force);
  if cid is null and force then cid := _card_pick(p_sid, false); end if;
  if cid is null then return null; end if;
  return _card_grant(p_sid, cid, p_source, p_game);
end $$;
revoke execute on function _card_shards(text), _card_pick(uuid, boolean), _card_grant(uuid, uuid, text, text), _card_draw(uuid, text, text) from public, anon, authenticated;

-- ---------- นักเรียน: สุ่มการ์ดหลังจบเกม (ต้องมีรอบเล่นจริงที่ยังไม่เคยสุ่ม) ----------
create or replace function card_roll(p_token uuid, p_game text) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); hit boolean := false; got boolean := false; used int; cap int := _setting_int('card_daily_cap', 5);
  pct int; card jsonb;
begin
  if p_game in ('quiz', 'match', 'spell', 'kb', 'run') then
    update game_plays set card_rolled = true where id = (select id from game_plays where student_id = sid and game = p_game and play_date = today_th() and not card_rolled
        order by best_hit desc, created_at limit 1 for update skip locked) returning best_hit into hit;
    got := found;
  elsif p_game = 'battle' then
    update battles set card_rolled = true where id = (select id from battles where student_id = sid and status = 'won' and play_date = today_th() and not card_rolled
        order by created_at limit 1 for update skip locked);
    got := found;
  else raise exception 'เกมนี้ไม่มีการ์ดดรอป'; end if;
  if not got then return json_build_object('drop', false, 'reason', 'no_play'); end if;
  select count(*) into used from card_drops where student_id = sid and play_date = today_th() and source = 'game';
  if used >= cap then return json_build_object('drop', false, 'reason', 'cap', 'cap', cap, 'left', 0); end if;
  pct := least(90, _setting_int('card_drop_pct', 30) + case when hit then _setting_int('card_best_bonus', 25) else 0 end);
  if not exists (select 1 from student_cards where student_id = sid) then pct := 100; end if;   -- ใบแรกได้แน่นอน
  if random() * 100 >= pct then return json_build_object('drop', false, 'reason', 'miss', 'cap', cap, 'left', cap - used); end if;
  card := _card_draw(sid, 'game', p_game);
  if card is null then return json_build_object('drop', false, 'reason', 'empty'); end if;
  return json_build_object('drop', true, 'card', card, 'cap', cap, 'left', cap - used - 1, 'bonus', hit);
end $$;
revoke execute on function card_roll(uuid, text) from public;
grant execute on function card_roll(uuid, text) to anon, authenticated;

-- ---------- นักเรียน: สมุดสะสม ----------
create or replace function card_album(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); res json; s students%rowtype;
begin
  select * into s from students where id = sid;
  select json_build_object('shards', s.shards, 'pity', s.card_pity, 'pity_max', _setting_int('card_pity', 4),
    'cap', _setting_int('card_daily_cap', 5), 'used', (select count(*) from card_drops where student_id = sid and play_date = today_th() and source = 'game'),
    'sets', coalesce((select json_agg(json_build_object('id', cs.id, 'title', cs.title, 'emoji', cs.emoji, 'color', cs.color,
        'reward', json_build_object('coins', cs.reward_coins, 'pulls', cs.reward_pulls, 'decor', (select d.name from decor_items d where d.id = cs.reward_decor)),
        'claimed', exists (select 1 from student_set_claims x where x.student_id = sid and x.set_id = cs.id),
        'cards', (select coalesce(json_agg(json_build_object('id', c.id, 'no', c.no, 'rarity', c.rarity, 'symbol', c.symbol, 'emoji', c.emoji,
              'own', sc.card_id is not null, 'qty', coalesce(sc.qty, 0), 'name', case when sc.card_id is not null then c.name end,
              'fact', case when sc.card_id is not null then c.fact end, 'image', case when sc.card_id is not null then c.image_url end) order by c.no), '[]'::json)
            from cards c left join student_cards sc on sc.card_id = c.id and sc.student_id = sid where c.set_id = cs.id and c.active))
        order by cs.sort, cs.title) from card_sets cs where cs.active), '[]'::json)) into res;
  return res;
end $$;
revoke execute on function card_album(uuid) from public;
grant execute on function card_album(uuid) to anon, authenticated;

-- ---------- game_record: ทำเครื่องหมาย "ทำสถิติใหม่" ที่รอบเล่นล่าสุด (โอกาสการ์ดเพิ่ม) ----------
create or replace function game_record(p_token uuid, p_game text, p_stats jsonb) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); g jsonb; k text; dir text; v numeric; old numeric; n numeric;
  cur jsonb := '{}'::jsonb; bst jsonb := '{}'::jsonb; nb text[] := '{}';
  cfg jsonb := '{"quiz":{"correct":"max","exp":"max","secs":"min"},
    "match":{"score":"max","secs":"min","wrong":"min"},
    "spell":{"score":"max","secs":"min","combo":"max","wrong":"min","hints":"min"},
    "kb":{"cleared":"max","secs":"min","wins":"sum"},
    "run":{"score":"max","dist":"max","secs":"max","combo":"max","coins":"max"},
    "battle":{"correct":"max","hp_left":"max","turns":"min","wins":"sum"},
    "duel":{"hp_left":"max","rounds":"min","wins":"sum"}}';
begin
  g := cfg -> p_game;
  if g is null then raise exception 'ไม่รู้จักเกมนี้'; end if;
  if p_stats is null or jsonb_typeof(p_stats) <> 'object' then raise exception 'ข้อมูลสถิติไม่ถูกต้อง'; end if;
  insert into game_bests (student_id, game, metric, best) values (sid, p_game, 'plays', 1)
    on conflict (student_id, game, metric) do update set best = game_bests.best + 1, updated_at = now() returning best into n;
  for k, dir in select key, value #>> '{}' from jsonb_each(g) loop
    begin v := (p_stats ->> k)::numeric; exception when others then v := null; end;
    if v is null then continue; end if;
    v := least(greatest(v, 0), case when k = 'secs' then 86400 else 100000 end);
    if k = 'secs' and v = 0 then continue; end if;
    select best into old from game_bests where student_id = sid and game = p_game and metric = k;
    if dir = 'sum' then
      if v > 0 then
        insert into game_bests (student_id, game, metric, best) values (sid, p_game, k, v)
          on conflict (student_id, game, metric) do update set best = game_bests.best + excluded.best, updated_at = now() returning best into old;
      end if;
      cur := cur || jsonb_build_object(k, v); bst := bst || jsonb_build_object(k, coalesce(old, 0));
      continue;
    end if;
    cur := cur || jsonb_build_object(k, v);
    if old is null or (dir = 'max' and v > old) or (dir = 'min' and v < old) then
      insert into game_bests (student_id, game, metric, best) values (sid, p_game, k, v)
        on conflict (student_id, game, metric) do update set best = excluded.best, updated_at = now();
      nb := nb || k; old := v;
    end if;
    bst := bst || jsonb_build_object(k, old);
  end loop;
  if cardinality(nb) > 0 and n > 1 and p_game in ('quiz', 'match', 'spell', 'kb', 'run') then
    update game_plays set best_hit = true where id = (select id from game_plays where student_id = sid and game = p_game and play_date = today_th()
       and not card_rolled order by created_at desc limit 1);
  end if;
  return json_build_object('game', p_game, 'plays', n, 'first', n <= 1, 'cur', cur, 'best', bst, 'newbest', to_json(nb));
end $$;
revoke execute on function game_record(uuid, text, jsonb) from public;
grant execute on function game_record(uuid, text, jsonb) to anon, authenticated;

-- ---------- กาชา: ห่อฟังก์ชันเดิม แล้วแถมการ์ดสะสม (สุ่ม 1 ครั้ง = มีโอกาส · สุ่ม 10 ครั้ง = ได้ 1 ใบแน่นอน + โอกาสอีก 1) ----------
do $$ begin
  if not exists (select 1 from pg_proc where proname = '_gacha_pull' and pronamespace = 'public'::regnamespace) then
    alter function gacha_pull(uuid, int) rename to _gacha_pull; end if;
end $$;
revoke execute on function _gacha_pull(uuid, int) from public, anon, authenticated;
create or replace function gacha_pull(p_token uuid, p_n int default 1) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); r json; cards jsonb := '[]'::jsonb; k int; n int; pct int := _setting_int('card_gacha_pct', 40); c jsonb;
begin
  r := _gacha_pull(p_token, p_n);
  n := case when p_n = 10 then 1 else 0 end + case when random() * 100 < pct then 1 else 0 end;
  for k in 1..n loop
    c := _card_draw(sid, 'gacha', 'gacha');
    if c is not null then cards := cards || c; end if;
  end loop;
  return (r::jsonb || jsonb_build_object('cards', cards))::json;
end $$;
revoke execute on function gacha_pull(uuid, int) from public;
grant execute on function gacha_pull(uuid, int) to anon, authenticated;

-- ---------- ของขวัญ: เพิ่ม "การ์ดสะสม" ----------
drop function if exists admin_gift(uuid[], int, int, int, uuid, uuid, text);
create or replace function admin_gift(p_students uuid[], p_exp int default 0, p_coins int default 0, p_pulls int default 0,
                                      p_decor uuid default null, p_priv uuid default null, p_message text default '',
                                      p_card uuid default null, p_card_n int default 1)
returns json language plpgsql security definer set search_path = public as $$
declare sid uuid; b uuid := gen_random_uuid(); n int := 0; dup int := 0; ids uuid[]; msg text := left(coalesce(btrim(p_message), ''), 200);
        cn int := case when p_card is null then 0 else greatest(1, coalesce(p_card_n, 1)) end; i int;
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  select array_agg(distinct x) into ids from unnest(coalesce(p_students, '{}')) x;
  if ids is null or cardinality(ids) = 0 then raise exception 'ยังไม่ได้เลือกนักเรียน'; end if;
  if cardinality(ids) > 600 then raise exception 'เลือกนักเรียนได้ครั้งละไม่เกิน 600 คน'; end if;
  if coalesce(p_exp, 0) < 0 or coalesce(p_coins, 0) < 0 or coalesce(p_pulls, 0) < 0 or coalesce(p_card_n, 1) < 0 then raise exception 'จำนวนต้องไม่ติดลบ (ถ้าจะหักให้ใช้ ± EXP/เหรียญ ในแท็บนักเรียน)'; end if;
  if p_exp > 10000 or p_coins > 10000 or p_pulls > 50 or cn > 10 then raise exception 'จำนวนมากเกินไป (EXP/เหรียญ ≤ 10000 · ตั๋ว ≤ 50 · การ์ด ≤ 10 ใบ)'; end if;
  if coalesce(p_exp, 0) = 0 and coalesce(p_coins, 0) = 0 and coalesce(p_pulls, 0) = 0 and p_decor is null and p_priv is null and p_card is null then raise exception 'ยังไม่ได้เลือกของขวัญ'; end if;
  if p_decor is not null and not exists (select 1 from decor_items where id = p_decor) then raise exception 'ไม่พบไอเทมตกแต่ง'; end if;
  if p_priv is not null and not exists (select 1 from privileges where id = p_priv) then raise exception 'ไม่พบสิทธิพิเศษ'; end if;
  if p_card is not null and not exists (select 1 from cards where id = p_card) then raise exception 'ไม่พบการ์ด'; end if;
  for sid in select id from students where id = any(ids) loop
    if coalesce(p_exp, 0) > 0 or coalesce(p_coins, 0) > 0 then
      perform award(sid, coalesce(p_exp, 0), coalesce(p_coins, 0), '🎁 ของขวัญจากครู' || case when msg <> '' then ': ' || msg else '' end, 'gift:' || b);
    end if;
    if coalesce(p_pulls, 0) > 0 then update students set free_pulls = free_pulls + p_pulls where id = sid; end if;
    if p_decor is not null then
      insert into student_decor (student_id, item_id, source) values (sid, p_decor, 'teacher') on conflict do nothing;
      if not found then dup := dup + 1; end if;
    end if;
    if p_priv is not null then insert into redemptions (student_id, privilege_id, source) values (sid, p_priv, 'teacher'); end if;
    for i in 1..cn loop perform _card_grant(sid, p_card, 'gift', null); end loop;
    insert into gifts (batch, student_id, message, exp, coins, pulls, decor_id, privilege_id, card_id, card_n)
    values (b, sid, msg, coalesce(p_exp, 0), coalesce(p_coins, 0), coalesce(p_pulls, 0), p_decor, p_priv, p_card, cn);
    n := n + 1;
  end loop;
  perform check_achievements(s.id) from students s where s.id = any(ids);
  return json_build_object('given', n, 'decor_already_owned', dup, 'batch', b);
end $$;
revoke execute on function admin_gift(uuid[], int, int, int, uuid, uuid, text, uuid, int) from public, anon;
grant execute on function admin_gift(uuid[], int, int, int, uuid, uuid, text, uuid, int) to authenticated;

create or replace function gift_inbox(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  return coalesce((select json_agg(json_build_object('id', g.id, 'message', g.message, 'exp', g.exp, 'coins', g.coins, 'pulls', g.pulls,
            'decor', d.name, 'decor_emoji', d.emoji, 'privilege', p.name, 'card', c.name, 'card_emoji', c.emoji, 'card_rarity', c.rarity, 'card_n', g.card_n,
            'at', g.created_at) order by g.created_at)
          from gifts g left join decor_items d on d.id = g.decor_id left join privileges p on p.id = g.privilege_id left join cards c on c.id = g.card_id
         where g.student_id = sid and not g.seen), '[]'::json);
end $$;
revoke execute on function gift_inbox(uuid) from public;
grant execute on function gift_inbox(uuid) to anon, authenticated;
