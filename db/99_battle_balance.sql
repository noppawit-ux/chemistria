-- 99: ปรับสมดุลการสู้มอนสเตอร์ — ให้ "ตอบเร็ว" และ "สเตตัส" มีผลมากขึ้น ลดผลของ "การป้องกัน"
-- ต้องรันหลัง 79 (ด่านบอสยากขึ้น) และ 81 · รันซ้ำได้ · แทนที่ไฟล์ 98 (ซึ่งไม่ได้ผล — อ้างค่าบอสที่ไม่ตรงกับในระบบ)
--  • ตอบไว: ≤4 วิ ดาเมจ +50% · ≤8 วิ +30% · ≤12 วิ +15% (เดิมมีแค่ ≤8 วิ +25%)
--  • สเตตัส: พลัง(STR) ได้ผล x2 · ปัญญา(INT) +1 ดาเมจ/แต้ม (เดิม 0.5) และฮีลแรงขึ้น · โชค(LUK) คริ 2%/แต้ม สูงสุด 40% · ขยัน(DIL) +2% HP/แต้ม
--  • ป้องกัน: ลดดาเมจได้สูงสุด 20% เมื่อกดถูกครบ (ไม่ตั้งรับ 10%) (เดิมสูงสุด 100%) · ป้องกันสมบูรณ์ไม่เป็น 0 ดาเมจ ไม่สวนกลับ ฟื้น HP 3% (เดิม 8%)
--  • ปรับค่าได้ในตาราง app_settings: battle_guard_pct, battle_str_x, battle_int_x10, battle_int_heal_pct, battle_luk_crit_pct,
--    battle_dil_hp_pct, battle_counter_pct, battle_perfect_heal_pct (ไม่ตั้ง = ใช้ค่าข้างต้น; หน้าเกมแสดงตัวเลขตามค่าเริ่มต้นนี้)
--  • พลังบอสด่านเลื่อนแรงค์ปรับให้เข้ากับกติกาใหม่ (เขียนทับเฉพาะบอสที่ยังเป็นค่าจาก SQL 79 — ไม่ทับค่าที่ครูแก้เอง)

CREATE OR REPLACE FUNCTION public.battle_answer(p_token uuid, p_battle uuid, p_pick integer)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  sid uuid := _sid(p_token); b battles%rowtype; m monsters%rowtype; sk battle_skills%rowtype; q quiz_questions%rowtype;
  st json; elapsed numeric; ok boolean; dmg int := 0; heal int := 0; crit boolean := false; fast boolean := false; mult numeric;
  bf jsonb; cdz jsonb; k text; n int; seqs text := ''; i int; rw_exp int := 0; rw_coins int := 0; drop json := null; ev jsonb;
  luk int; critp numeric; intl int; pct numeric := 1; spd int := 0; sx int := _setting_int('battle_str_x', 2); ix numeric := _setting_int('battle_int_x10', 10) / 10.0;
begin
  select * into b from battles where id = p_battle and student_id = sid for update;
  if not found or b.status <> 'active' then raise exception 'ไม่พบการต่อสู้ที่กำลังเล่นอยู่'; end if;
  if b.cur_q is null or b.pend is not null then raise exception 'ยังไม่ได้เลือกสกิล'; end if;
  select * into m from monsters where id = b.monster_id;
  select * into sk from battle_skills where key = b.cur_skill;
  select * into q from quiz_questions where id = b.cur_q;
  select coalesce(a.reward_pct, 100) / 100.0 into pct from arenas a where a.key = m.arena;
  pct := coalesce(pct, 1);
  st := _stats(sid);
  luk := coalesce((st->'luk'->>'total')::int, 0); intl := coalesce((st->'int'->>'total')::int, 0);
  elapsed := extract(epoch from now() - b.asked_at);
  ok := p_pick is not null and p_pick = q.answer and elapsed <= case when b.trial_rank is not null then 17 else 40 end;
  bf := b.buffs; cdz := b.cds;
  -- คูลดาวน์ทุกสกิลลดลง 1 เทิร์น
  for k in select jsonb_object_keys(cdz) loop cdz := jsonb_set(cdz, array[k], to_jsonb(greatest(0, (cdz->>k)::int - 1))); end loop;
  ev := jsonb_build_object('correct', ok, 'answer', q.answer, 'explain', q.explain, 'pick', p_pick,
          'skill', jsonb_build_object('key', sk.key, 'name', sk.name, 'emoji', sk.emoji, 'kind', sk.kind));
  if ok then
    cdz := jsonb_set(cdz, array[sk.key], to_jsonb(sk.cd));
    if sk.kind = 'attack' then
      fast := elapsed <= 8;
      spd := case when elapsed <= 4 then 50 when elapsed <= 8 then 30 when elapsed <= 12 then 15 else 0 end;   -- ตอบไวได้โบนัสดาเมจเป็นขั้น (SQL 99)
      mult := 1 + sx * coalesce((st->'effects'->>'boss_pct')::int, 0) / 100.0;       -- พลัง (STR) คูณตามตั้งค่า
      mult := mult * (1 + spd / 100.0);
      mult := mult * (_gear_battle(sid, m.element)->>'atk_mult')::numeric;   -- โบนัสโจมตี + ธาตุได้เปรียบ (SQL 81)
      if coalesce((bf->>'atk_up')::int, 0) > 0 then mult := mult * 1.5; bf := jsonb_set(bf, '{atk_up}', to_jsonb((bf->>'atk_up')::int - 1)); end if;
      if coalesce((bf->>'weak')::int, 0) > 0 then mult := mult * 1.4; end if;
      critp := case when sk.effect = 'crit' then least(0.85, 0.3 + luk * 0.03) else least(0.4, luk * _setting_int('battle_luk_crit_pct', 2) / 100.0) end;
      if coalesce((bf->>'crit_up')::int, 0) > 0 then crit := true; bf := jsonb_set(bf, '{crit_up}', to_jsonb((bf->>'crit_up')::int - 1));
      else crit := random() < critp; end if;
      if crit then mult := mult * 2; end if;
      dmg := greatest(1, round(sk.power * mult * (0.9 + random() * 0.2) + intl * ix)::int);
      b.m_hp := greatest(0, b.m_hp - dmg);
    elsif sk.kind = 'heal' then
      heal := round(sk.power * (1 + intl * _setting_int('battle_int_heal_pct', 3) / 100.0))::int;
      heal := least(heal, b.p_max - b.p_hp); b.p_hp := b.p_hp + heal;
    else
      bf := jsonb_set(bf, array[sk.effect], to_jsonb(case sk.effect when 'weak' then 3 else 2 end));
    end if;
    b.correct := b.correct + 1;
  end if;
  ev := ev || jsonb_build_object('dmg', dmg, 'heal', heal, 'crit', crit, 'fast', fast, 'spd', spd);
  -- ชนะ
  if b.m_hp <= 0 then
    if b.rewarded then
      rw_exp := m.exp + case when b.p_hp >= 0.7 * b.p_max then round(m.exp * 0.25)::int else 0 end;
      rw_coins := round(m.coins * pct)::int;
      rw_exp := round(rw_exp * pct)::int;
      perform award(sid, rw_exp, rw_coins, 'ปราบมอนสเตอร์: ' || m.name, 'game:battle:' || b.id);
      drop := _battle_drop(sid, b.id);
    end if;
    update battles set status = 'won', finished_at = now(), m_hp = 0, p_hp = b.p_hp, correct = b.correct, exp = rw_exp, coins = rw_coins,
           cur_q = null, cur_skill = null, buffs = bf, cds = cdz where id = b.id;
    perform check_achievements(sid);
    return json_build_object('event', ev, 'drop', drop, 'state', _battle_view(b.id));
  end if;
  -- ตาของมอนสเตอร์: สร้างลำดับลูกศรให้ผู้เล่นกดป้องกัน
  n := least(5, 2 + m.level);
  for i in 1..n loop seqs := seqs || substr('LURD', 1 + floor(random() * 4)::int, 1); end loop;
  update battles set m_hp = b.m_hp, p_hp = b.p_hp, correct = b.correct, buffs = bf, cds = cdz, cur_q = null, cur_skill = null,
         pend = jsonb_build_object('dmg', greatest(1, round(m.atk * (0.85 + random() * 0.3))::int), 'n', n, 'seq', seqs,
                                   'at', extract(epoch from now())) where id = b.id;
  return json_build_object('event', ev, 'state', _battle_view(b.id));
end $function$;

CREATE OR REPLACE FUNCTION public.battle_defend(p_token uuid, p_battle uuid, p_hits integer)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  sid uuid := _sid(p_token); b battles%rowtype; m monsters%rowtype; n int; hits int := 0; dmg int; fin int; shield boolean := false;
  bf jsonb; el numeric; rw_exp int := 0; ev jsonb; heavy boolean; perfect boolean := false; ctr int := 0; hl int := 0; st json;
  intl int; mult numeric; gp numeric := _setting_int('battle_guard_pct', 20) / 100.0; sx int := _setting_int('battle_str_x', 2); ix numeric := _setting_int('battle_int_x10', 10) / 10.0;
begin
  select * into b from battles where id = p_battle and student_id = sid for update;
  if not found or b.status <> 'active' or b.pend is null then raise exception 'ไม่มีการโจมตีให้ป้องกัน'; end if;
  select * into m from monsters where id = b.monster_id;
  n := (b.pend->>'n')::int; dmg := (b.pend->>'dmg')::int;
  heavy := (b.turn % 3 = 0);
  if heavy then dmg := round(dmg * 1.5)::int; end if;
  bf := b.buffs;
  if b.guard then
    el := extract(epoch from now()) - (b.pend->>'at')::numeric;
    hits := greatest(0, least(coalesce(p_hits, 0), n));
    if el < 0.25 * hits then hits := 0; end if;            -- เร็วเกินคนกดไม่ทัน = ไม่นับ
    perfect := n > 0 and hits = n;
    fin := round(dmg * (1 - gp / 2 * (1 + hits::numeric / n)))::int;      -- ตั้งรับลดดาเมจได้สูงสุด battle_guard_pct (ถูกครบ) · ไม่ตั้งรับลดครึ่งหนึ่งของนั้น (SQL 99)
  else
    fin := round(dmg * (1 - gp / 2))::int;
  end if;
  if coalesce((bf->>'shield')::int, 0) > 0 then
    shield := true; fin := round(fin * 0.5)::int; bf := jsonb_set(bf, '{shield}', to_jsonb((bf->>'shield')::int - 1));
  end if;
  fin := round(fin * (_gear_battle(sid, m.element)->>'in_mult')::numeric)::int;   -- ป้องกัน + ธาตุแพ้ทาง (SQL 81)
  fin := greatest(1, fin);
  if coalesce((bf->>'weak')::int, 0) > 0 then bf := jsonb_set(bf, '{weak}', to_jsonb((bf->>'weak')::int - 1)); end if;
  b.p_hp := greatest(0, b.p_hp - fin);
  -- ปัดป้องสมบูรณ์: สวนกลับ + ฟื้น HP (สวนกลับไม่ฆ่า เหลือ HP อย่างน้อย 1)
  if perfect and b.p_hp > 0 then
    st := _stats(sid); intl := coalesce((st->'int'->>'total')::int, 0);
    mult := 1 + sx * coalesce((st->'effects'->>'boss_pct')::int, 0) / 100.0;
    if coalesce((bf->>'weak')::int, 0) > 0 then mult := mult * 1.4; end if;
    mult := mult * (_gear_battle(sid, m.element)->>'atk_mult')::numeric;
    ctr := round(_setting_int('battle_counter_pct', 0) / 100.0 * (20 + intl * ix) * mult)::int;
    ctr := least(ctr, greatest(0, b.m_hp - 1));
    b.m_hp := b.m_hp - ctr;
    hl := least(b.p_max - b.p_hp, round(b.p_max * _setting_int('battle_perfect_heal_pct', 3) / 100.0)::int); b.p_hp := b.p_hp + hl;
  end if;
  ev := jsonb_build_object('hits', hits, 'n', n, 'taken', fin, 'raw', dmg, 'shield', shield, 'guard', b.guard, 'heavy', heavy,
                           'perfect', perfect, 'counter', ctr, 'heal', hl);
  if b.p_hp <= 0 then
    if b.rewarded then
      rw_exp := least(6, b.correct * 2);
      if rw_exp > 0 then perform award(sid, rw_exp, 0, 'สู้มอนสเตอร์: ' || m.name || ' (ให้กำลังใจ)', 'game:battle:' || b.id); end if;
    end if;
    update battles set status = 'lost', finished_at = now(), p_hp = 0, pend = null, guard = false, buffs = bf, exp = rw_exp, turn = b.turn + 1 where id = b.id;
  else
    update battles set p_hp = b.p_hp, m_hp = b.m_hp, pend = null, guard = false, buffs = bf, turn = b.turn + 1 where id = b.id;
  end if;
  return json_build_object('event', ev, 'state', _battle_view(b.id));
end $function$;

CREATE OR REPLACE FUNCTION public.battle_start(p_token uuid, p_monster uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare sid uuid := _sid(p_token); m monsters%rowtype; used int; lim int := _setting_int('battle_rewards_per_day', 3); pm int; bid uuid; ar arenas%rowtype;
begin
  select * into m from monsters where id = p_monster and active and (trial_rank is null or current_setting('app.trial_ok', true) = '1');
  if not found then raise exception 'ไม่พบมอนสเตอร์'; end if;
  select * into ar from arenas where key = m.arena;
  if found and (not ar.active or ar.min_level > level_for((select exp from students where id = sid))) then raise exception 'ยังปลดล็อกสนามนี้ไม่ได้ (ต้องถึงเลเวล %)', ar.min_level; end if;
  update battles set status = 'fled', finished_at = now() where student_id = sid and status = 'active';
  select count(*) into used from battles where student_id = sid and play_date = today_th() and rewarded;
  pm := 80 + 6 * level_for((select exp from students where id = sid));
  pm := round(pm * (_gear_battle(sid, m.element)->>'hp_mult')::numeric)::int;   -- โบนัส HP จากอุปกรณ์/การ์ด (SQL 81)
  pm := round(pm * (1 + coalesce((_stats(sid)->'dil'->>'total')::int, 0) * _setting_int('battle_dil_hp_pct', 2) / 100.0))::int;   -- ขยัน → HP (SQL 99)
  insert into battles (student_id, monster_id, p_hp, p_max, m_hp, m_max, rewarded)
  values (sid, m.id, pm, pm, m.hp, m.hp, used < lim) returning id into bid;
  return _battle_view(bid);
end $function$;

-- พลังบอสด่านเลื่อนแรงค์ใหม่ (HP/ATK) — เขียนทับเฉพาะบอสที่ยังเป็นค่าจาก SQL 79 / 69 (ไม่ทับค่าที่ครูแก้เอง)
update monsters m set hp = v.nhp, atk = v.natk
  from (values ('trial_silver',130,12),('trial_gold',165,13),('trial_platinum',200,14),('trial_emerald',235,15),
               ('trial_diamond',270,15),('trial_master',310,16),('trial_grandmaster',355,16),('trial_challenger',405,17)) v(k, nhp, natk)
 where m.key = v.k
   and exists (select 1 from (values ('trial_silver',220,21),('trial_gold',300,24),('trial_platinum',400,27),('trial_emerald',510,30),
                                     ('trial_diamond',640,33),('trial_master',790,36),('trial_grandmaster',1000,40),('trial_challenger',1250,45),
                                     ('trial_silver',170,14),('trial_gold',230,16),('trial_platinum',310,18),('trial_emerald',390,20),
                                     ('trial_diamond',490,22),('trial_master',610,24),('trial_grandmaster',770,27),('trial_challenger',960,30)) o(k, ohp, oatk)
                where o.k = v.k and o.ohp = m.hp and o.oatk = m.atk);
