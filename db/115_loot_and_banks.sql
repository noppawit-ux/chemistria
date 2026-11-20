-- SQL 115 · คลังไอเทม + คลังข้อสอบ สำหรับ "ดันเจี้ยน" และ "ประลองครูบุ๊ค" (ต้องรันหลัง 110–114)
--   1) loot_items  — คลังไอเทมรางวัล แยกตามแหล่ง: 'dungeon:<key>' (หีบบอส) · 'dungeon:*' (ทุกดันเจี้ยน) · 'kb' (ชนะครูบุ๊ค)
--   2) คลังข้อสอบดันเจี้ยน — เก็บใน quiz_questions (pool = 'dungeon', active = false เพื่อไม่ปนกับควิซ/ศึก/ดวลทั่วไป)
--      ศึกในดันเจี้ยนสลับคำถามมาจากคลังนี้ตามระดับชั้นนักเรียน (ม.ต้น/ม.ปลาย) และความยากของชั้น — ด้วยทริกเกอร์ ไม่แก้ battle_ask เดิม
--   3) kb_submit_v2 — เรียก kb_submit เดิม แล้วสุ่มของรางวัลจากคลัง 'kb' เมื่อชนะ
--   รันซ้ำได้ · ไม่มีข้อมูลในคลัง = ระบบเดิมทำงานเหมือนเดิม

-- ---------- 1) คลังไอเทม ----------
create table if not exists loot_items (
  id uuid primary key default gen_random_uuid(),
  source text not null,                                        -- dungeon:<key> | dungeon:* | kb
  kind text not null check (kind in ('coins', 'exp', 'consumable', 'decor')),
  name text not null, emoji text not null default '🎁', image text,
  rarity text not null default 'R' check (rarity in ('N', 'R', 'SR', 'SSR')),
  value int not null default 0 check (value >= 0),             -- coins/exp = จำนวน
  ref_key text,                                                -- consumable: consumables.key
  decor_id uuid references decor_items(id) on delete cascade,  -- decor: ไอเทมตกแต่ง
  weight int not null default 10 check (weight > 0),
  boss_only boolean not null default false,                    -- true = ออกเฉพาะหีบบอส (ไม่ใช้กับ kb)
  active boolean not null default true,
  sort int not null default 0
);
create index if not exists idx_loot_source on loot_items (source) where active;
alter table loot_items enable row level security;
drop policy if exists teacher_all on loot_items;
create policy teacher_all on loot_items for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on loot_items from anon;
grant select, insert, update, delete on loot_items to authenticated;

insert into loot_items (source, kind, name, emoji, rarity, value, ref_key, weight, boss_only, sort)
select v.* from (values
  ('dungeon:crystal_cave', 'coins', 'ถุงเหรียญคริสตัล', '💰', 'R', 40, null, 20, false, 1),
  ('dungeon:crystal_cave', 'exp', 'ผลึกความรู้เล็ก', '💎', 'R', 30, null, 20, false, 2),
  ('dungeon:crystal_cave', 'consumable', 'ยาฟื้นฟู HP', '💚', 'N', 0, 'p_heal', 25, false, 3),
  ('dungeon:crystal_cave', 'consumable', 'ยาเพิ่มพลังสมอง', '🧪', 'R', 0, 'p_exp', 10, true, 4),
  ('dungeon:crystal_cave', 'consumable', 'ยาโชคสี่แฉก', '🍀', 'SR', 0, 'p_luck', 4, true, 5),
  ('dungeon:volcano_forge', 'coins', 'ทองหลอมเหลว', '🥇', 'R', 80, null, 20, false, 1),
  ('dungeon:volcano_forge', 'exp', 'แกนลาวาความรู้', '🌋', 'R', 60, null, 20, false, 2),
  ('dungeon:volcano_forge', 'consumable', 'ยาฟื้นฟู HP', '💚', 'N', 0, 'p_heal', 22, false, 3),
  ('dungeon:volcano_forge', 'consumable', 'ยากล้ามเคมี', '⚔️', 'R', 0, 'p_str', 12, false, 4),
  ('dungeon:volcano_forge', 'consumable', 'ยาเหรียญทอง', '💰', 'R', 0, 'p_coin', 10, true, 5),
  ('dungeon:volcano_forge', 'consumable', 'ม้วนอัปเกรด', '📜', 'SR', 0, 'scroll', 4, true, 6),
  ('dungeon:toxic_swamp', 'coins', 'เหรียญกรดทมิฬ', '☣️', 'R', 100, null, 20, false, 1),
  ('dungeon:toxic_swamp', 'exp', 'ผลึกพิษแห่งปัญญา', '🧫', 'R', 80, null, 20, false, 2),
  ('dungeon:toxic_swamp', 'consumable', 'ยาฟื้นฟู HP', '💚', 'N', 0, 'p_heal', 22, false, 3),
  ('dungeon:toxic_swamp', 'consumable', 'ยาอัจฉริยะ', '🧠', 'R', 0, 'p_int', 12, false, 4),
  ('dungeon:toxic_swamp', 'consumable', 'ยาโชคสี่แฉก', '🍀', 'SR', 0, 'p_luck', 5, true, 5),
  ('dungeon:toxic_swamp', 'consumable', 'ม้วนอัปเกรด', '📜', 'R', 0, 'scroll', 8, true, 6),
  ('dungeon:space_lab', 'coins', 'เหรียญจักรวาล', '🪐', 'SR', 150, null, 18, false, 1),
  ('dungeon:space_lab', 'exp', 'พลังงานดวงดาว', '🌟', 'SR', 120, null, 18, false, 2),
  ('dungeon:space_lab', 'consumable', 'ยาฟื้นฟู HP', '💚', 'N', 0, 'p_heal', 20, false, 3),
  ('dungeon:space_lab', 'consumable', 'ยาเพิ่มพลังสมอง', '🧪', 'R', 0, 'p_exp', 12, false, 4),
  ('dungeon:space_lab', 'consumable', 'ยาโชคสี่แฉก', '🍀', 'SR', 0, 'p_luck', 8, true, 5),
  ('dungeon:space_lab', 'consumable', 'ม้วนอัปเกรด', '📜', 'SR', 0, 'scroll', 8, true, 6),
  ('kb', 'coins', 'เหรียญรางวัลครูบุ๊ค', '🪙', 'N', 20, null, 25, false, 1),
  ('kb', 'exp', 'ใบประกาศความเก่ง', '📜', 'N', 15, null, 25, false, 2),
  ('kb', 'consumable', 'ยาฟื้นฟู HP', '💚', 'N', 0, 'p_heal', 18, false, 3),
  ('kb', 'consumable', 'ยาเพิ่มพลังสมอง', '🧪', 'R', 0, 'p_exp', 12, false, 4),
  ('kb', 'consumable', 'ยาอัจฉริยะ', '🧠', 'R', 0, 'p_int', 10, false, 5),
  ('kb', 'consumable', 'ม้วนอัปเกรด', '📜', 'R', 0, 'scroll', 8, false, 6),
  ('kb', 'consumable', 'ยาโชคสี่แฉก', '🍀', 'SR', 0, 'p_luck', 5, false, 7)
) v(source, kind, name, emoji, rarity, value, ref_key, weight, boss_only, sort)
where not exists (select 1 from loot_items);                   -- ใส่ครั้งแรกครั้งเดียว ครูลบ/แก้ได้ภายหลังโดยไม่ถูกใส่ซ้ำ

create or replace function _loot_has(p_source text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from loot_items where active and (source = p_source or source = 'dungeon:*') and p_source like 'dungeon:%')
      or exists (select 1 from loot_items where active and source = p_source and p_source not like 'dungeon:%')
$$;

-- สุ่ม 1 ชิ้นจากคลัง แล้วมอบให้ทันที · p_chance null = ตามโชค (50% + 2%/แต้มโชค สูงสุด 90%) · คืน null เมื่อสุ่มไม่ได้
create or replace function _loot_roll(p_sid uuid, p_source text, p_boss boolean, p_chance numeric default null) returns json
language plpgsql security definer set search_path = public as $$
declare it loot_items%rowtype; co consumables%rowtype; luk int := coalesce((_stats(p_sid)->'luk'->>'total')::int, 0); chance numeric; refund int; why text;
begin
  chance := coalesce(p_chance, least(0.9, 0.5 + luk * 0.02));
  if random() > chance then return null; end if;
  select * into it from loot_items
   where active and (boss_only = false or p_boss)
     and (source = p_source or (source = 'dungeon:*' and p_source like 'dungeon:%'))
   order by -ln(greatest(random(), 1e-9)) / weight limit 1;
  if not found then return null; end if;
  why := case when p_source = 'kb' then 'รางวัลจากครูบุ๊ค: ' else 'หีบดันเจี้ยน: ' end || it.name;
  if it.kind = 'coins' then perform award(p_sid, 0, it.value, why, null);
  elsif it.kind = 'exp' then perform award(p_sid, it.value, 0, why, null);
  elsif it.kind = 'consumable' then
    select * into co from consumables where key = it.ref_key and active;
    if not found then perform award(p_sid, 0, 20, why || ' (ไอเทมถูกปิดใช้งาน แปลงเป็นเหรียญ)', null);
    else insert into student_items (student_id, item_id, qty) values (p_sid, co.id, 1) on conflict (student_id, item_id) do update set qty = student_items.qty + 1; end if;
  elsif it.kind = 'decor' and it.decor_id is not null then
    if exists (select 1 from student_decor where student_id = p_sid and item_id = it.decor_id) then
      refund := case it.rarity when 'SSR' then 40 when 'SR' then 20 else 8 end;
      perform award(p_sid, 0, refund, 'ไอเทมตกแต่งซ้ำ: ' || it.name, null);
    else insert into student_decor (student_id, item_id, source) values (p_sid, it.decor_id, 'loot'); end if;
  end if;
  return json_build_object('name', it.name, 'rarity', it.rarity, 'kind', it.kind, 'value', it.value, 'emoji', it.emoji, 'image', it.image);
end $$;
revoke execute on function _loot_has(text), _loot_roll(uuid, text, boolean, numeric) from public, anon, authenticated;

create or replace function _dungeon_finish(p_run uuid, p_status text, p_battle uuid) returns void
language plpgsql security definer set search_path = public as $$
declare r dungeon_runs%rowtype; d dungeons%rowtype; pct numeric; e int; c int; dr json; ch jsonb := '[]'::jsonb; i int;
begin
  select * into r from dungeon_runs where id = p_run for update;
  if not found or r.status <> 'active' then return; end if;
  select * into d from dungeons where key = r.dungeon_key;
  pct := case when p_status = 'cleared' then 1 else least(100, greatest(0, _setting_int('dungeon_fail_pct', 60))) / 100.0 end;
  e := round(r.exp * pct)::int; c := round(r.coins * pct)::int;
  if e + c > 0 then
    perform award(r.student_id, e, c, 'ดันเจี้ยน ' || d.name || ' (ผ่าน ' || r.cleared || '/' || d.floors || ' ชั้น)', 'dungeon:' || r.id);
  end if;
  if p_status = 'cleared' then
    for i in 1..2 loop
      -- คลังไอเทมของดันเจี้ยน (SQL 115): ถ้าครูตั้งไว้ใช้คลังนั้น (หีบใบแรกการันตี) · ไม่มีก็ใช้ตู้ดรอปเดิม
      if _loot_has('dungeon:' || r.dungeon_key) then dr := _loot_roll(r.student_id, 'dungeon:' || r.dungeon_key, true, case when i = 1 then 1.0 else null end);
      else dr := _battle_drop(r.student_id, coalesce(p_battle, r.battle_id)); end if;
      if dr is not null then ch := ch || jsonb_build_array(dr::jsonb); end if;
    end loop;
  end if;
  update dungeon_runs set status = p_status, paid_exp = e, paid_coins = c, chest = case when p_status = 'cleared' then ch else null end,
         finished_at = now() where id = r.id;
end $$;

revoke execute on function _dungeon_finish(uuid, text, uuid) from public, anon, authenticated;

-- ---------- 2) คลังข้อสอบดันเจี้ยน ----------
alter table quiz_questions add column if not exists pool text check (pool is null or pool in ('dungeon'));
alter table quiz_questions add column if not exists lvl int not null default 1 check (lvl between 1 and 3);     -- ความยาก 1 ง่าย · 2 กลาง · 3 ยาก
alter table quiz_questions add column if not exists grade text not null default 'all' check (grade in ('all', 'jr', 'hs'));   -- jr = ม.ต้น (ม.1–3) · hs = ม.ปลาย
alter table quiz_questions add column if not exists dungeon_key text;                                          -- null = ใช้ได้ทุกดันเจี้ยน
alter table quiz_questions add column if not exists pool_on boolean not null default true;                     -- เปิด/ปิดข้อในคลังดันเจี้ยน
create index if not exists idx_qq_pool on quiz_questions (pool) where pool is not null;

create or replace function trg_dungeon_qpool() returns trigger
language plpgsql security definer set search_path = public as $$
declare r dungeon_runs%rowtype; d dungeons%rowtype; want int; gr text; qid uuid;
begin
  if new.dungeon_run is null or new.status <> 'active' or new.cur_q is null or old.cur_q is not null then return new; end if;
  select * into r from dungeon_runs where id = new.dungeon_run;
  if not found then return new; end if;
  select * into d from dungeons where key = r.dungeon_key;
  gr := coalesce(_kb_level(new.student_id), 'hs');
  want := least(3, 1 + (r.floor - 1) / 2 + case when coalesce(d.stars, 1) >= 4 then 1 else 0 end);
  select q.id into qid from quiz_questions q
   where q.pool = 'dungeon' and q.pool_on and (q.grade = 'all' or q.grade = gr) and (q.dungeon_key is null or q.dungeon_key = r.dungeon_key)
     and q.lvl <= want and q.id <> all (new.used_q)
   order by (q.lvl = want) desc, random() limit 1;
  if qid is null then
    select q.id into qid from quiz_questions q
     where q.pool = 'dungeon' and q.pool_on and (q.grade = 'all' or q.grade = gr) and (q.dungeon_key is null or q.dungeon_key = r.dungeon_key) and q.lvl <= want
     order by random() limit 1;
  end if;
  if qid is null then return new; end if;                      -- คลังว่าง: ใช้คำถามจากคลังควิซเดิม
  new.used_q := array_remove(new.used_q, new.cur_q) || qid;
  new.cur_q := qid;
  return new;
end $$;
drop trigger if exists dungeon_qpool on battles;
create trigger dungeon_qpool before update on battles for each row execute function trg_dungeon_qpool();
revoke execute on function trg_dungeon_qpool() from public, anon, authenticated;

insert into quiz_questions (topic, question, a, b, c, d, answer, explain, active, pool, lvl, grade, pool_on)
select 'ดันเจี้ยน ม.ต้น', v.q, v.a, v.b, v.c, v.d, v.ans, v.ex, false, 'dungeon', v.lv, 'jr', true
  from (values
  ('สารใดต่อไปนี้เป็นสารบริสุทธิ์', 'น้ำทะเล', 'น้ำกลั่น', 'อากาศ', 'น้ำเชื่อม', 1, 'น้ำกลั่นมีน้ำเพียงชนิดเดียว ส่วนที่เหลือเป็นสารผสม', 1),
  ('การระเหิดคือการเปลี่ยนสถานะแบบใด', 'ของเหลวเป็นแก๊ส', 'ของแข็งเป็นแก๊สโดยตรง', 'แก๊สเป็นของเหลว', 'ของเหลวเป็นของแข็ง', 1, 'เช่น น้ำแข็งแห้ง (CO₂ แข็ง) กลายเป็นแก๊สโดยไม่ผ่านของเหลว', 1),
  ('ข้อใดเป็นการเปลี่ยนแปลงทางเคมี', 'น้ำแข็งละลาย', 'เหล็กเป็นสนิม', 'ละลายน้ำตาลในน้ำ', 'ตัดกระดาษ', 1, 'เหล็กเป็นสนิมเกิดสารใหม่ (เหล็กออกไซด์)', 1),
  ('สัญลักษณ์ธาตุของโซเดียมคือข้อใด', 'Na', 'So', 'S', 'N', 0, 'Na มาจากภาษาละติน natrium', 1),
  ('สารละลายที่เปลี่ยนกระดาษลิตมัสสีน้ำเงินเป็นสีแดง มีสมบัติเป็นอะไร', 'กรด', 'เบส', 'กลาง', 'เกลือ', 0, 'กรดเปลี่ยนลิตมัสน้ำเงินเป็นแดง', 1),
  ('อนุภาคที่มีประจุบวกในอะตอมคือข้อใด', 'อิเล็กตรอน', 'โปรตอน', 'นิวตรอน', 'โมเลกุล', 1, 'โปรตอนมีประจุบวก อิเล็กตรอนมีประจุลบ นิวตรอนไม่มีประจุ', 1),
  ('ธาตุที่มีเลขอะตอม 6 คือธาตุใด', 'ไนโตรเจน', 'ออกซิเจน', 'คาร์บอน', 'โบรอน', 2, 'เลขอะตอมคือจำนวนโปรตอน คาร์บอนมี 6', 2),
  ('การแยกทรายออกจากน้ำควรใช้วิธีใด', 'การกรอง', 'การกลั่น', 'การตกผลึก', 'โครมาโทกราฟี', 0, 'ทรายไม่ละลายน้ำ แยกได้ด้วยการกรอง', 2),
  ('ข้อใดไม่ใช่สมบัติทางกายภาพของสาร', 'จุดเดือด', 'ความหนาแน่น', 'การติดไฟ', 'สี', 2, 'การติดไฟเป็นสมบัติทางเคมี เพราะเกิดสารใหม่', 2),
  ('สูตรเคมีของแก๊สคาร์บอนไดออกไซด์คือข้อใด', 'CO', 'CO₂', 'C₂O', 'H₂CO₃', 1, 'คาร์บอน 1 อะตอม ออกซิเจน 2 อะตอม', 2),
  ('สารละลายที่เป็นกลางที่ 25 °C มี pH เท่าใด', '0', '7', '10', '14', 1, 'pH 7 เป็นกลาง น้อยกว่า 7 เป็นกรด มากกว่า 7 เป็นเบส', 2),
  ('ธาตุหมู่ 1 (ยกเว้นไฮโดรเจน) เรียกว่าอะไร', 'โลหะอัลคาไล', 'ฮาโลเจน', 'แก๊สเฉื่อย', 'โลหะแทรนซิชัน', 0, 'เช่น Li, Na, K ว่องไวต่อน้ำมาก', 2),
  ('สารใดเป็นสารประกอบไอออนิก', 'CO₂', 'NaCl', 'H₂O', 'CH₄', 1, 'NaCl เกิดจากโลหะ (Na) รวมกับอโลหะ (Cl)', 3),
  ('ธาตุ X มีเลขอะตอม 11 และเลขมวล 23 มีนิวตรอนกี่ตัว', '11', '12', '23', '34', 1, 'นิวตรอน = เลขมวล − เลขอะตอม = 23 − 11 = 12', 3),
  ('2H₂ + O₂ → 2H₂O เป็นปฏิกิริยาประเภทใด', 'การสลายตัว', 'การรวมตัว', 'การแทนที่เดี่ยว', 'การแยกสลายด้วยไฟฟ้า', 1, 'สารตั้งต้นสองชนิดรวมกันเป็นสารเดียว', 3),
  ('ฮาโลเจนอยู่ในหมู่ใดของตารางธาตุ', 'หมู่ 1', 'หมู่ 2', 'หมู่ 17', 'หมู่ 18', 2, 'ฮาโลเจน เช่น F, Cl, Br, I อยู่หมู่ 17', 3),
  ('สารละลายน้ำตาลมีน้ำตาล 20 กรัม ในสารละลาย 200 กรัม ความเข้มข้นร้อยละโดยมวลเท่าใด', '5%', '10%', '20%', '40%', 1, '(20 ÷ 200) × 100 = 10%', 3),
  ('วิธีใดทำให้สารละลายเร็วขึ้น', 'ลดอุณหภูมิ', 'บดสารให้ละเอียดและคน', 'ใช้สารก้อนใหญ่', 'ไม่คน', 1, 'พื้นที่ผิวมากขึ้นและการคนช่วยให้ละลายเร็ว', 3)
  ) v(q, a, b, c, d, ans, ex, lv)
 where not exists (select 1 from quiz_questions x where x.question = v.q and x.pool = 'dungeon');

insert into quiz_questions (topic, question, a, b, c, d, answer, explain, active, pool, lvl, grade, pool_on)
select 'ดันเจี้ยน ม.6 อินทรีย์', v.q, v.a, v.b, v.c, v.d, v.ans, v.ex, false, 'dungeon', v.lv, 'hs', true
  from (values
  ('สารประกอบอินทรีย์มีธาตุใดเป็นองค์ประกอบหลัก', 'ไนโตรเจน', 'คาร์บอน', 'ซิลิคอน', 'กำมะถัน', 1, 'สารอินทรีย์มีคาร์บอนเป็นโครงหลัก', 1),
  ('แอลเคนที่มีคาร์บอน 1 อะตอมคือสารใด', 'มีเทน', 'อีเทน', 'โพรเพน', 'บิวเทน', 0, 'มีเทน CH₄', 1),
  ('สูตรทั่วไปของแอลเคนคือข้อใด', 'CnH2n', 'CnH2n+2', 'CnH2n−2', 'CnHn', 1, 'แอลเคนอิ่มตัว มี H 2n+2', 1),
  ('หมู่ฟังก์ชันของแอลกอฮอล์คือข้อใด', '–OH', '–COOH', '–CHO', '–NH₂', 0, 'หมู่ไฮดรอกซิล –OH', 1),
  ('ปฏิกิริยาที่มอนอเมอร์หลายหน่วยต่อกันเป็นพอลิเมอร์ เรียกว่าอะไร', 'พอลิเมอไรเซชัน', 'ไฮโดรไลซิส', 'การเผาไหม้', 'การกลั่น', 0, 'พอลิเมอไรเซชัน = ปฏิกิริยาสร้างพอลิเมอร์', 1),
  ('พอลิเมอร์ชนิดใดเกิดจากมอนอเมอร์เอทีน (เอทิลีน)', 'พอลิเอทิลีน', 'PVC', 'ไนลอน', 'เทฟลอน', 0, 'เอทีนต่อกันเป็นพอลิเอทิลีน', 1),
  ('ชื่อของ CH₃CH₂CH₃ คือข้อใด', 'เอเทน', 'โพรเพน', 'บิวเทน', 'เพนเทน', 1, 'คาร์บอน 3 อะตอม = โพร-', 2),
  ('แอลคีนมีพันธะชนิดใดที่เป็นเอกลักษณ์', 'พันธะคู่ระหว่างคาร์บอน', 'พันธะสามระหว่างคาร์บอน', 'พันธะไอออนิก', 'พันธะไฮโดรเจนเท่านั้น', 0, 'แอลคีนมี C=C', 2),
  ('กรดคาร์บอกซิลิกทำปฏิกิริยากับแอลกอฮอล์ได้ผลิตภัณฑ์ใด', 'เอสเทอร์และน้ำ', 'อีเทอร์', 'แอลคีน', 'อัลดีไฮด์', 0, 'ปฏิกิริยาเอสเทอริฟิเคชัน', 2),
  ('สารใดเป็นไอโซเมอร์ของบิวเทน (C₄H₁₀)', '2-เมทิลโพรเพน', 'โพรเพน', 'เพนเทน', 'บิวทีน', 0, 'สูตรโมเลกุลเดียวกันแต่โครงสร้างต่างกัน', 2),
  ('ข้อใดเป็นพอลิเมอร์ธรรมชาติ', 'ยางธรรมชาติ', 'PVC', 'ไนลอน', 'พอลิสไตรีน', 0, 'ยางธรรมชาติคือพอลิไอโซพรีน', 2),
  ('ปฏิกิริยาสะปอนนิฟิเคชันใช้ผลิตสิ่งใด', 'สบู่', 'น้ำมันเบนซิน', 'ไนลอน', 'แอลกอฮอล์', 0, 'ไขมัน/น้ำมันทำปฏิกิริยากับเบสได้สบู่และกลีเซอรอล', 2),
  ('การเผาไหม้สมบูรณ์ของแอลเคนให้ผลิตภัณฑ์ใด', 'CO₂ และ H₂O', 'CO และ H₂', 'C และ H₂O', 'CH₄ และ O₂', 0, 'เผาไหม้สมบูรณ์ได้ CO₂ และน้ำ', 3),
  ('ไนลอน-6,6 เกิดจากพอลิเมอไรเซชันแบบใด', 'แบบควบแน่น', 'แบบเติม', 'ไฮโดรไลซิส', 'สะปอนนิฟิเคชัน', 0, 'ควบแน่นระหว่างไดเอมีนกับกรดไดคาร์บอกซิลิก และเสียน้ำ', 3),
  ('พอลิเมอร์ที่ขึ้นรูปแล้วให้ความร้อนอีกจะไม่อ่อนตัว เรียกว่าอะไร', 'เทอร์โมพลาสติก', 'เทอร์โมเซต', 'พอลิเอทิลีน', 'สบู่', 1, 'เทอร์โมเซตมีพันธะเชื่อมขวาง', 3),
  ('1-บิวทีน กับ 2-บิวทีน เป็นไอโซเมอร์ชนิดใด', 'ไอโซเมอร์ตำแหน่งพันธะคู่', 'ไม่เป็นไอโซเมอร์กัน', 'ไอโซเมอร์ออพติคอล', 'เป็นสารเดียวกัน', 0, 'สูตรโมเลกุล C₄H₈ เท่ากัน แต่ตำแหน่ง C=C ต่างกัน', 3),
  ('มอนอเมอร์ของโปรตีนคือข้อใด', 'กรดอะมิโน', 'กลูโคส', 'กรดไขมัน', 'กลีเซอรอล', 0, 'กรดอะมิโนต่อกันด้วยพันธะเพปไทด์', 3),
  ('เมื่อออกซิไดซ์เอทานอลอย่างอ่อน จะได้สารใด', 'เอทานัล', 'เอทีน', 'เอทิลอะซีเตต', 'เอเทน', 0, 'แอลกอฮอล์ปฐมภูมิถูกออกซิไดซ์เป็นอัลดีไฮด์ (เอทานัล)', 3)
  ) v(q, a, b, c, d, ans, ex, lv)
 where not exists (select 1 from quiz_questions x where x.question = v.q and x.pool = 'dungeon');

-- ---------- 3) ประลองครูบุ๊ค: ข้อสอบเพิ่ม + ของรางวัลจากคลัง ----------
insert into kb_bank (level, kind, question, answer, wrong, explain)
select v.* from (values
  ('jr', 'quiz', 'ธาตุใดเป็นของเหลวที่อุณหภูมิห้อง (ไม่นับโบรมีน)', 'ปรอท', '["เหล็ก", "ทองแดง", "โซเดียม"]'::jsonb, 'ปรอท (Hg) เป็นโลหะที่เป็นของเหลวที่อุณหภูมิห้อง'),
  ('jr', 'quiz', 'พืชใช้แก๊สใดในการสังเคราะห์ด้วยแสง', 'คาร์บอนไดออกไซด์', '["ออกซิเจน", "ไนโตรเจน", "ไฮโดรเจน"]'::jsonb, 'พืชนำ CO₂ กับน้ำมาสร้างน้ำตาลและปล่อย O₂'),
  ('jr', 'tf', 'น้ำเดือดที่ 100 องศาเซลเซียส ที่ความดัน 1 บรรยากาศ', 'จริง', '[]'::jsonb, 'จุดเดือดปกติของน้ำคือ 100 °C'),
  ('jr', 'tf', 'อากาศเป็นสารบริสุทธิ์', 'เท็จ', '[]'::jsonb, 'อากาศเป็นสารผสมของแก๊สหลายชนิด'),
  ('jr', 'calc', 'น้ำตาล 15 กรัม ละลายในน้ำ 135 กรัม ได้สารละลายร้อยละโดยมวลเท่าใด', '10%', '["11.1%", "15%", "9%"]'::jsonb, 'สารละลายรวม 150 กรัม → 15 ÷ 150 × 100 = 10%'),
  ('jr', 'calc', 'อะตอมที่มี 8 โปรตอนและ 8 นิวตรอน มีเลขมวลเท่าใด', '16', '["8", "24", "0"]'::jsonb, 'เลขมวล = โปรตอน + นิวตรอน = 16'),
  ('jr', 'odd', 'ข้อใดแปลกแยกจากพวก (ธาตุ vs สารประกอบ)', 'เกลือแกง', '["ทองแดง", "เหล็ก", "ทอง"]'::jsonb, 'เกลือแกงเป็นสารประกอบ ที่เหลือเป็นธาตุ'),
  ('jr', 'odd', 'ข้อใดแปลกแยกจากพวก (ธาตุ vs สารประกอบ)', 'ไฮโดรเจน', '["น้ำ", "เกลือแกง", "น้ำตาล"]'::jsonb, 'ไฮโดรเจนเป็นธาตุ ที่เหลือเป็นสารประกอบ'),
  ('hs', 'quiz', 'หมู่ฟังก์ชันของกรดคาร์บอกซิลิกคือข้อใด', '–COOH', '["–OH", "–CHO", "–CO–"]'::jsonb, 'กรดคาร์บอกซิลิกมีหมู่ –COOH'),
  ('hs', 'quiz', 'สารใดเป็นแอลไคน์', 'เอทาย', '["เอทีน", "เอเทน", "เอทานอล"]'::jsonb, 'เอทายมีพันธะสาม C≡C'),
  ('hs', 'tf', 'พอลิเอทิลีนเป็นเทอร์โมพลาสติก', 'จริง', '[]'::jsonb, 'หลอมและขึ้นรูปใหม่ได้เมื่อให้ความร้อน'),
  ('hs', 'tf', 'แอลเคนทุกชนิดมีพันธะคู่ระหว่างคาร์บอน', 'เท็จ', '[]'::jsonb, 'แอลเคนมีเฉพาะพันธะเดี่ยว'),
  ('hs', 'calc', 'แอลเคนที่มีคาร์บอน 5 อะตอม มีไฮโดรเจนกี่อะตอม', '12', '["10", "11", "14"]'::jsonb, 'CnH2n+2 → n = 5 ได้ H = 12'),
  ('hs', 'calc', 'มวลโมเลกุลของ CH₄ (C = 12, H = 1) เท่ากับเท่าใด', '16', '["13", "14", "12"]'::jsonb, '12 + 4 × 1 = 16'),
  ('hs', 'odd', 'ข้อใดแปลกแยกจากพวก (แอลเคน vs แอลกอฮอล์)', 'เอทานอล', '["มีเทน", "เอเทน", "โพรเพน"]'::jsonb, 'เอทานอลเป็นแอลกอฮอล์ ที่เหลือเป็นแอลเคน'),
  ('hs', 'odd', 'ข้อใดแปลกแยกจากพวก (พอลิเมอร์สังเคราะห์ vs ธรรมชาติ)', 'ไนลอน', '["แป้ง", "เซลลูโลส", "โปรตีน"]'::jsonb, 'ไนลอนสังเคราะห์ ที่เหลือเป็นพอลิเมอร์ธรรมชาติ')
) v(level, kind, question, answer, wrong, explain)
where not exists (select 1 from kb_bank k where k.question = v.question and k.answer = v.answer);

create or replace function kb_submit_v2(p_token uuid, p_cleared int, p_won boolean, p_seconds int) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); r jsonb; dr json := null;
begin
  r := kb_submit(p_token, p_cleared, p_won, p_seconds)::jsonb;
  if p_won and coalesce((r->>'no_reward')::boolean, false) = false and _loot_has('kb') then
    dr := _loot_roll(sid, 'kb', false, null);
  end if;
  return (r || jsonb_build_object('drop', dr))::json;
end $$;
revoke execute on function kb_submit_v2(uuid, int, boolean, int) from public;
grant execute on function kb_submit_v2(uuid, int, boolean, int) to anon, authenticated;
