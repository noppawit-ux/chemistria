-- =====================================================================
-- Chemistria · รอบที่ 9: สเตตัสนักเรียน (ปัญญา · ความขยัน · พลังโจมตี · โชค) + ไอเทมเพิ่มสเตตัส
--   ปัญญา  → โบนัส EXP ทุกครั้งที่ทำควิซประจำวัน (+1 EXP ต่อ 2 แต้ม)
--   ขยัน   → EXP จากเช็คชื่อ/ส่งงาน/เควส เพิ่มขึ้น +1% ต่อแต้ม
--   พลังโจมตี → ความเสียหายต่อบอส +3% ต่อแต้ม (คิดตอนเควสสำเร็จ)
--   โชค    → โอกาสออกของ SR/SSR ในกาชา +3% ต่อแต้ม
-- ค่าสเตตัส = ฐานจากการเรียน/เล่น (ต่อด้านสูงสุด 10) + โบนัสจากไอเทมที่สวมใส่
-- รันซ้ำได้ · ต้องรันหลัง 08 (setup_all.sql รวมให้แล้ว) · ฟังก์ชัน award/quiz_submit ในไฟล์นี้ใช้แทนเวอร์ชันเดิม
-- =====================================================================

alter table decor_items add column if not exists st_int int not null default 0;   -- ปัญญา
alter table decor_items add column if not exists st_dil int not null default 0;   -- ความขยัน
alter table decor_items add column if not exists st_str int not null default 0;   -- พลังโจมตี
alter table decor_items add column if not exists st_luk int not null default 0;   -- โชค
alter table decor_items add column if not exists st_coin int not null default 0;  -- โบนัสเหรียญ % (เช็คชื่อ/ส่งงาน/เควส) — ความสามารถพิเศษของฉายา/ไอเทม
alter table decor_items add column if not exists ability text;                   -- คำอธิบายความสามารถ (โชว์ให้นักเรียนเห็น)

create or replace function _stats(p_sid uuid) returns json
language plpgsql stable security definer set search_path = public as $$
declare
  b_int int; b_dil int; b_str int; b_luk int;
  i_int int := 0; i_dil int := 0; i_str int := 0; i_luk int := 0; i_coin int := 0;
begin
  b_int := least(10, coalesce((select sum(correct) from game_plays where student_id = p_sid and game = 'quiz'), 0)::int / 8);
  b_dil := least(10, student_metric(p_sid, 'present_count') / 4);
  b_str := least(10, student_metric(p_sid, 'quests_done') / 8);
  b_luk := least(10, student_metric(p_sid, 'gacha_pulls') / 6);
  if coalesce((select is_gm from students where id = p_sid), false) then b_int := 10; b_dil := 10; b_str := 10; b_luk := 10; end if;   -- ไอดี GM: ค่าพื้นฐานเต็ม
  select coalesce(sum(d.st_int), 0), coalesce(sum(d.st_dil), 0), coalesce(sum(d.st_str), 0), coalesce(sum(d.st_luk), 0), coalesce(sum(d.st_coin), 0)
    into i_int, i_dil, i_str, i_luk, i_coin
    from students s
    cross join lateral jsonb_each_text(s.decor) e
    join decor_items d on d.id = e.value::uuid and d.slot = e.key
   where s.id = p_sid;
  return json_build_object(
    'int', json_build_object('base', b_int, 'item', i_int, 'total', b_int + i_int),
    'dil', json_build_object('base', b_dil, 'item', i_dil, 'total', b_dil + i_dil),
    'str', json_build_object('base', b_str, 'item', i_str, 'total', b_str + i_str),
    'luk', json_build_object('base', b_luk, 'item', i_luk, 'total', b_luk + i_luk),
    'effects', json_build_object('quiz_exp', (b_int + i_int) / 2, 'exp_pct', b_dil + i_dil,
                                 'boss_pct', 3 * (b_str + i_str), 'rare_pct', 3 * (b_luk + i_luk), 'coin_pct', i_coin));
end $$;

-- ความเสียหายต่อบอสของเควสหนึ่งครั้ง: ฐาน = EXP ของเควส (อย่างน้อย 1) × (1 + 3% × พลังโจมตี) · บันทึกไว้ตอนอนุมัติ ไม่เปลี่ยนย้อนหลัง
create or replace function trg_claim_dmg() returns trigger
language plpgsql security definer set search_path = public as $$
declare base int; s int;
begin
  if new.status = 'approved' and new.dmg is null then
    select greatest(q.exp, 1) into base from quests q where q.id = new.quest_id;
    s := coalesce((_stats(new.student_id)->'str'->>'total')::int, 0);
    new.dmg := greatest(round(coalesce(base, 1) * (1 + 0.03 * s))::int, 1);
  end if;
  return new;
end $$;
drop trigger if exists claim_dmg on quest_claims;
create trigger claim_dmg before insert or update of status on quest_claims
  for each row execute function trg_claim_dmg();

-- กาชา: ค่าโชคเพิ่มน้ำหนักของ SR/SSR ทีละ 3% ต่อแต้ม
create or replace function _gacha_pick_luk(p_high boolean, p_luk int) returns gacha_items
language plpgsql security definer set search_path = public as $$
declare total numeric; r numeric; acc numeric := 0; it gacha_items%rowtype; last_it gacha_items%rowtype; w numeric;
begin
  select coalesce(sum(weight * case when rarity in ('SR','SSR') then 1 + 0.03 * greatest(p_luk, 0) else 1 end), 0) into total
    from gacha_items where active and (not p_high or rarity in ('SR','SSR'));
  if total = 0 then raise exception 'ยังไม่มีไอเทมในกาชา'; end if;
  r := random() * total;
  for it in select * from gacha_items where active and (not p_high or rarity in ('SR','SSR')) order by id loop
    w := it.weight * case when it.rarity in ('SR','SSR') then 1 + 0.03 * greatest(p_luk, 0) else 1 end;
    acc := acc + w; last_it := it;
    if r < acc then return it; end if;
  end loop;
  return last_it;
end $$;

create or replace function award(p_student uuid, p_exp int, p_coins int, p_reason text, p_ref text default null)
returns boolean language plpgsql security definer set search_path = public as $$
declare v uuid; cls text; e int := p_exp; c int := p_coins; rs text := p_reason; dil int; e2 int; cp int; c2 int;
begin
  -- ความสามารถคลาส: โบนัสเฉพาะรางวัลจากเช็คชื่อ / ส่งงาน / เควส
  if p_ref ~ '^(att|sub|quest):' then
    cls := student_class(p_student);
    if cls = 'scientist' and e > 0 then e := ceil(e * 1.15)::int; rs := rs || ' (โบนัสนักทดลอง)'; end if;
    if cls = 'alchemist' and c > 0 then c := ceil(c * 1.25)::int; rs := rs || ' (โบนัสนักเล่นแร่แปรธาตุ)'; end if;
    -- สเตตัสความขยัน: +1% ต่อแต้ม (เฉพาะรางวัลเช็คชื่อ/ส่งงาน/เควส)
    if e > 0 then
      dil := coalesce((_stats(p_student)->'dil'->>'total')::int, 0);
      e2 := round(e * (1 + dil / 100.0))::int;
      if e2 > e then e := e2; rs := rs || ' (ขยัน +' || dil || '%)'; end if;
    end if;
    -- ความสามารถฉายา/ไอเทม: โบนัสเหรียญ %
    if c > 0 then
      cp := coalesce((_stats(p_student)->'effects'->>'coin_pct')::int, 0);
      c2 := round(c * (1 + cp / 100.0))::int;
      if c2 > c then c := c2; rs := rs || ' (เหรียญ +' || cp || '%)'; end if;
    end if;
  end if;
  insert into ledger (student_id, exp, coins, reason, ref_key)
  values (p_student, e, c, rs, p_ref)
  on conflict (student_id, ref_key) do nothing
  returning id into v;
  if v is null then return false; end if;
  update students
     set exp = greatest(0, exp + e),
         coins = greatest(0, coins + c)
   where id = p_student;
  return true;
end $$;

create or replace function quiz_submit(p_token uuid, p_answers jsonb) returns json
language plpgsql security definer set search_path = public as $$
declare
  sid uuid := _sid(p_token); d date := today_th(); ids uuid[]; q quiz_questions%rowtype;
  total int; i int; pick int; corr int := 0; res jsonb := '[]'::jsonb;
  raw int; e int; c int := 0; stk int; cap int := _setting_int('game_daily_cap_exp', 40); sb int := 0;
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
  if corr > 0 then sb := coalesce((_stats(sid)->'int'->>'total')::int, 0) / 2; end if;     -- สเตตัสปัญญา: +1 EXP ต่อ 2 แต้ม
  raw := corr * _setting_int('quiz_exp_per_correct', 4)
         + case when corr = total then _setting_int('quiz_perfect_bonus', 5) else 0 end + sb;
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
  perform award(sid, e, c, 'ควิซประจำวัน ' || corr || '/' || total || case when sb > 0 then ' (+' || sb || ' ปัญญา)' else '' end, 'game:quiz:' || d);
  return json_build_object('correct', corr, 'total', total, 'exp', e, 'coins', c, 'raw_exp', raw,
                           'capped', e < raw, 'streak', stk, 'stat_bonus', sb, 'results', res);
end $$;

revoke execute on function _stats(uuid) from public, anon, authenticated;
revoke execute on function _gacha_pick_luk(boolean, int) from public, anon, authenticated;
revoke execute on function trg_claim_dmg() from public, anon, authenticated;
revoke execute on function award(uuid, int, int, text, text) from public, anon, authenticated;
revoke execute on function quiz_submit(uuid, jsonb) from public;
grant execute on function quiz_submit(uuid, jsonb) to anon, authenticated;

-- ---------------------------------------------------------------------
-- สเตตัสไอเทมตัวอย่าง (ใส่เฉพาะตอนยังไม่มีไอเทมชิ้นไหนมีสเตตัส · ครูแก้ได้ที่แท็บตกแต่ง)
--   หมวก→ปัญญา · ชุด→ขยัน · เอฟเฟค→พลังโจมตี · สัตว์เลี้ยง→โชค · กรอบ→ขยัน · พื้นหลัง→โชค · ไอเทมถือ→สลับปัญญา/พลัง · ฉายา→ไม่มี
--   ค่า: N=1 R=1 SR=2 SSR=3 (SSR ได้เพิ่ม +1 อีกด้านหนึ่ง)
-- ---------------------------------------------------------------------
do $$
begin
  if exists (select 1 from decor_items where st_int + st_dil + st_str + st_luk > 0) then return; end if;
  update decor_items d set
    st_int = case when d.slot = 'hat' or (d.slot = 'item' and d.sort % 2 = 1) then v.x else 0 end,
    st_dil = case when d.slot in ('outfit', 'frame') then v.x else 0 end,
    st_str = case when d.slot = 'fx' or (d.slot = 'item' and d.sort % 2 = 0) then v.x else 0 end,
    st_luk = case when d.slot in ('pet', 'bg') then v.x else 0 end
  from (select id, case rarity when 'N' then 1 when 'R' then 1 when 'SR' then 2 else 3 end as x from decor_items) v
  where v.id = d.id and d.slot <> 'title';
  -- SSR: โบนัสด้านรอง +1
  update decor_items set
    st_dil = st_dil + case when slot in ('hat', 'fx', 'item', 'pet', 'bg') then 1 else 0 end,
    st_luk = st_luk + case when slot in ('outfit', 'frame') then 1 else 0 end
   where rarity = 'SSR' and slot <> 'title';
end $$;
