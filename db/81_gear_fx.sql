-- =====================================================================
-- 81: โบนัสโจมตี/ป้องกัน/HP จากอุปกรณ์สวมใส่ + การ์ดสวมใส่ 3 ช่อง + ระบบธาตุ 5 ธาตุ (รันซ้ำได้)
--  ธาตุ: fire 🔥ไฟ · water 💧น้ำ · plant 🌿พืช · thunder ⚡ไฟฟ้า · chem 🧪สารเคมี
--  วงจรแพ้ทาง: น้ำ→ไฟ→พืช→สารเคมี→ไฟฟ้า→น้ำ (ลูกศร = ชนะ) เช่น น้ำดับไฟ · ไฟเผาพืช · พืชดูดซับสารเคมี · สารเคมีกัดกร่อนวงจรไฟฟ้า · ไฟฟ้าแยกน้ำ (อิเล็กโทรลิซิส)
--  แต่ละชิ้นที่ใส่ (อุปกรณ์/การ์ด) ที่ธาตุชนะธาตุมอนสเตอร์ = โจมตีเพิ่ม · ธาตุแพ้มอนสเตอร์ = โดนแรงขึ้น (ชิ้นละเล็กน้อย มีเพดาน)
--  ปรับตัวเลขได้ที่ ⚙️ ตั้งค่า: gear_fx_pct, gear_cap_atk/def/hp, elem_adv_pct, elem_weak_pct, elem_cap_pct
--  ต้องรันหลัง 54 (การ์ด) · 66 (ไอเทม/อัปเกรด) · 69 (ด่านแรงค์) · 79
-- =====================================================================
alter table decor_items add column if not exists element text check (element in ('fire','water','plant','thunder','chem'));
alter table decor_items add column if not exists fx_atk int not null default 0;   -- โจมตี +%
alter table decor_items add column if not exists fx_def int not null default 0;   -- ลดดาเมจที่โดน %
alter table decor_items add column if not exists fx_hp  int not null default 0;   -- HP สูงสุด +%
alter table cards add column if not exists element text check (element in ('fire','water','plant','thunder','chem'));
alter table cards add column if not exists fx_kind text check (fx_kind in ('atk','def','hp'));
alter table cards add column if not exists fx_pct int not null default 0;
alter table monsters add column if not exists element text check (element in ('fire','water','plant','thunder','chem'));

create table if not exists student_card_slots (
  student_id uuid not null references students(id) on delete cascade,
  slot smallint not null check (slot between 1 and 3),
  card_id uuid not null references cards(id) on delete cascade,
  primary key (student_id, slot),
  unique (student_id, card_id)
);
alter table student_card_slots enable row level security;
drop policy if exists teacher_all on student_card_slots;
create policy teacher_all on student_card_slots for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on student_card_slots from anon;
grant select, insert, update, delete on student_card_slots to authenticated;

insert into app_settings (key, value) values ('gear_fx_pct', '100'), ('gear_cap_atk', '25'), ('gear_cap_def', '20'), ('gear_cap_hp', '30'),
  ('elem_adv_pct', '4'), ('elem_weak_pct', '4'), ('elem_cap_pct', '20') on conflict (key) do nothing;

-- ---------- ใส่ค่าเริ่มต้นให้ของเดิม (ทำครั้งเดียว ครูแก้ภายหลังได้ในหน้าครู) ----------
do $$
declare r int;
begin
  if exists (select 1 from app_settings where key = 'gear_fx_seeded') then return; end if;
  -- ธาตุ: จับคำในชื่อก่อน ที่เหลือกระจายด้วย md5 (คงที่)
  update decor_items set element = case
      when name ~ 'ไฟ(?!ฟ้า)|เพลิง|ลาวา|ร้อน|มังกร|ฟีนิกซ์|เตา' then 'fire'
      when name ~ 'น้ำ|ทะเล|คลื่น|ฟอง|หยด|เงือก|ปลา' then 'water'
      when name ~ 'พืช|ใบไม้|ดอก|ป่า|เห็ด|ต้นไม้|สวน|เขียว' then 'plant'
      when name ~ 'ฟ้า|ไฟฟ้า|สายฟ้า|ประจุ|อิเล็ก|แม่เหล็ก|พลาสมา' then 'thunder'
      when name ~ 'สาร|แล็บ|ขวด|ฟลาสก์|กรด|เบส|เคมี|ทดลอง|ผลึก|อะตอม|ตารางธาตุ' then 'chem'
      else (array['fire','water','plant','thunder','chem'])[1 + get_byte(decode(md5(name), 'hex'), 0) % 5] end
   where element is null and slot in ('hat', 'outfit', 'item', 'fx', 'pet');
  -- โบนัส: ระดับ R=1 SR=2 SSR=3 LEG=4 (N ไม่มี) · ไอเทมถือ/เอฟเฟค=โจมตี · หมวก/สัตว์เลี้ยง=ป้องกัน · ชุด=HP×2
  update decor_items d set
      fx_atk = case when slot in ('item', 'fx') then v.r else 0 end,
      fx_def = case when slot in ('hat', 'pet') then v.r else 0 end,
      fx_hp  = case when slot = 'outfit' then 2 * v.r else 0 end
    from (select id, case rarity when 'R' then 1 when 'SR' then 2 when 'SSR' then 3 when 'LEG' then 4 else 0 end r from decor_items) v
   where v.id = d.id and d.slot in ('hat', 'outfit', 'item', 'fx', 'pet') and d.fx_atk + d.fx_def + d.fx_hp = 0;
  -- การ์ด: ธาตุและชนิดโบนัสกระจายด้วย md5 · แรงตามระดับ N=1 R=2 SR=3 SSR=5 (HP ×2)
  update cards set element = (array['fire','water','plant','thunder','chem'])[1 + get_byte(decode(md5(name), 'hex'), 0) % 5],
      fx_kind = (array['atk','def','hp'])[1 + get_byte(decode(md5(name), 'hex'), 1) % 3]
   where element is null;
  update cards set fx_pct = (case rarity when 'N' then 1 when 'R' then 2 when 'SR' then 3 else 5 end) * (case when fx_kind = 'hp' then 2 else 1 end) where fx_pct = 0;
  -- มอนสเตอร์
  update monsters set element = case key
      when 'bubble' then 'water' when 'fog' then 'water' when 'frost' then 'water' when 'cryo' then 'water'
      when 'lava' then 'fire' when 'ash' then 'fire' when 'lemon' then 'plant' when 'geode' then 'plant'
      when 'rust' then 'thunder' when 'ozone' then 'thunder' when 'plasma' then 'thunder'
      when 'salt' then 'chem' when 'sludge' then 'chem' when 'toxic' then 'chem' when 'quartz' then 'chem'
      when 'trial_silver' then 'chem' when 'trial_gold' then 'fire' when 'trial_platinum' then 'water' when 'trial_emerald' then 'plant'
      when 'trial_diamond' then 'thunder' when 'trial_master' then 'chem' when 'trial_grandmaster' then 'fire' when 'trial_challenger' then 'water'
      else (array['fire','water','plant','thunder','chem'])[1 + get_byte(decode(md5(key), 'hex'), 0) % 5] end
   where element is null;
  insert into app_settings (key, value) values ('gear_fx_seeded', '1');
end $$;

-- ---------- ตัวช่วยธาตุ/โบนัส (ภายใน) ----------
create or replace function _elem_beats(a text, b text) returns boolean language sql immutable as $$
  select (a, b) in (('water', 'fire'), ('fire', 'plant'), ('plant', 'chem'), ('chem', 'thunder'), ('thunder', 'water')) $$;

-- รวมโบนัสของผู้เล่น: {atk, def, hp (%, หลังคูณ gear_fx_pct และจำกัดเพดาน), el: {ธาตุ: จำนวนชิ้น}, parts: [...]}
create or replace function _gear(p_sid uuid) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare sc numeric := _setting_int('gear_fx_pct', 100) / 100.0; a numeric := 0; d numeric := 0; h numeric := 0; el jsonb := '{}'::jsonb; parts jsonb := '[]'::jsonb; r record;
begin
  for r in
    select 'item' src, di.name, di.emoji, di.element el,
           di.fx_atk * (1 + 0.15 * (coalesce(sd.lvl, 1) - 1)) fa, di.fx_def * (1 + 0.15 * (coalesce(sd.lvl, 1) - 1)) fd, di.fx_hp * (1 + 0.15 * (coalesce(sd.lvl, 1) - 1)) fh
      from students s cross join lateral jsonb_each_text(s.decor) e
      join decor_items di on di.id = e.value::uuid and di.slot = e.key and di.slot in ('hat', 'outfit', 'item', 'fx', 'pet')
      left join student_decor sd on sd.student_id = s.id and sd.item_id = di.id
     where s.id = p_sid
    union all
    select 'card', c.name, c.emoji, c.element, (case when c.fx_kind = 'atk' then c.fx_pct else 0 end)::numeric, (case when c.fx_kind = 'def' then c.fx_pct else 0 end)::numeric,
           (case when c.fx_kind = 'hp' then c.fx_pct else 0 end)::numeric
      from student_card_slots sl join cards c on c.id = sl.card_id and c.active where sl.student_id = p_sid
  loop
    a := a + r.fa; d := d + r.fd; h := h + r.fh;
    if r.el is not null then el := jsonb_set(el, array[r.el], to_jsonb(coalesce((el->>r.el)::int, 0) + 1)); end if;
    parts := parts || jsonb_build_object('src', r.src, 'name', r.name, 'emoji', r.emoji, 'el', r.el);
  end loop;
  return jsonb_build_object('atk', least(_setting_int('gear_cap_atk', 25), round(a * sc, 1)), 'def', least(_setting_int('gear_cap_def', 20), round(d * sc, 1)),
    'hp', least(_setting_int('gear_cap_hp', 30), round(h * sc, 1)), 'el', el, 'parts', parts);
end $$;

-- ตัวคูณในศึกกับมอนสเตอร์ธาตุ m_el (null = ไม่มีธาตุ)
create or replace function _gear_battle(p_sid uuid, m_el text) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare g jsonb := _gear(p_sid); adv int := 0; weak int := 0; k text; n int; cap numeric := _setting_int('elem_cap_pct', 20);
begin
  if m_el is not null then
    for k, n in select key, value::int from jsonb_each_text(g->'el') loop
      if _elem_beats(k, m_el) then adv := adv + n; elsif _elem_beats(m_el, k) then weak := weak + n; end if;
    end loop;
  end if;
  return jsonb_build_object(
    'atk_mult', 1 + (g->>'atk')::numeric / 100 + least(cap, adv * _setting_int('elem_adv_pct', 4)) / 100,
    'in_mult', (1 - (g->>'def')::numeric / 100) * (1 + least(cap, weak * _setting_int('elem_weak_pct', 4)) / 100),
    'hp_mult', 1 + (g->>'hp')::numeric / 100, 'adv', adv, 'weak', weak);
end $$;
revoke execute on function _elem_beats(text, text), _gear(uuid), _gear_battle(uuid, text) from public, anon, authenticated;

-- ---------- RPC นักเรียน ----------
create or replace function gear_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); g jsonb := _gear(sid);
begin
  return json_build_object('gear', g,
    'slots', (select coalesce(json_agg(json_build_object('slot', sl.slot, 'card', sl.card_id) order by sl.slot), '[]'::json) from student_card_slots sl join cards c on c.id = sl.card_id and c.active where sl.student_id = sid),
    'cards', (select coalesce(json_object_agg(c.id, json_build_object('el', c.element, 'kind', c.fx_kind, 'pct', c.fx_pct)), '{}'::json) from cards c where c.active and (c.element is not null or c.fx_pct > 0)),
    'items', (select coalesce(json_object_agg(d.id, json_build_object('el', d.element, 'atk', d.fx_atk, 'def', d.fx_def, 'hp', d.fx_hp)), '{}'::json) from decor_items d where d.active and (d.element is not null or d.fx_atk + d.fx_def + d.fx_hp > 0)),
    'monsters', (select coalesce(json_object_agg(m.id, m.element), '{}'::json) from monsters m where m.element is not null),
    'cfg', json_build_object('adv', _setting_int('elem_adv_pct', 4), 'weak', _setting_int('elem_weak_pct', 4), 'cap', _setting_int('elem_cap_pct', 20)));
end $$;

-- ใส่/ถอดการ์ด (p_card = null → ถอด) · ต้องเป็นการ์ดที่มี · ใบเดียวกันใส่ได้ช่องเดียว
create or replace function card_equip(p_token uuid, p_slot int, p_card uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  if p_slot is null or p_slot not between 1 and 3 then raise exception 'ช่องการ์ดไม่ถูกต้อง'; end if;
  if p_card is null then
    delete from student_card_slots where student_id = sid and slot = p_slot;
  else
    if not exists (select 1 from student_cards where student_id = sid and card_id = p_card and qty > 0) then raise exception 'ยังไม่มีการ์ดใบนี้'; end if;
    if not exists (select 1 from cards where id = p_card and active) then raise exception 'การ์ดใบนี้ปิดใช้งาน'; end if;
    delete from student_card_slots where student_id = sid and (slot = p_slot or card_id = p_card);
    insert into student_card_slots (student_id, slot, card_id) values (sid, p_slot, p_card);
  end if;
  return gear_status(p_token);
end $$;
revoke execute on function gear_status(uuid), card_equip(uuid, int, uuid) from public;
grant execute on function gear_status(uuid), card_equip(uuid, int, uuid) to anon, authenticated;

-- ---------- ฟังก์ชันศึก (แทนที่ทั้งฟังก์ชัน — เพิ่มเฉพาะบรรทัดที่มีคอมเมนต์ “SQL 81”) ----------
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
  insert into battles (student_id, monster_id, p_hp, p_max, m_hp, m_max, rewarded)
  values (sid, m.id, pm, pm, m.hp, m.hp, used < lim) returning id into bid;
  return _battle_view(bid);
end $function$;

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
  luk int; critp numeric; intl int; pct numeric := 1;
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
      mult := 1 + coalesce((st->'effects'->>'boss_pct')::int, 0) / 100.0;       -- พลัง (STR)
      if fast then mult := mult * 1.25; end if;
      mult := mult * (_gear_battle(sid, m.element)->>'atk_mult')::numeric;   -- โบนัสโจมตี + ธาตุได้เปรียบ (SQL 81)
      if coalesce((bf->>'atk_up')::int, 0) > 0 then mult := mult * 1.5; bf := jsonb_set(bf, '{atk_up}', to_jsonb((bf->>'atk_up')::int - 1)); end if;
      if coalesce((bf->>'weak')::int, 0) > 0 then mult := mult * 1.4; end if;
      critp := case when sk.effect = 'crit' then least(0.85, 0.3 + luk * 0.03) else least(0.3, luk * 0.01) end;
      if coalesce((bf->>'crit_up')::int, 0) > 0 then crit := true; bf := jsonb_set(bf, '{crit_up}', to_jsonb((bf->>'crit_up')::int - 1));
      else crit := random() < critp; end if;
      if crit then mult := mult * 2; end if;
      dmg := greatest(1, round(sk.power * mult * (0.9 + random() * 0.2) + intl / 2)::int);
      b.m_hp := greatest(0, b.m_hp - dmg);
    elsif sk.kind = 'heal' then
      heal := round(sk.power * (1 + intl * 0.02))::int;
      heal := least(heal, b.p_max - b.p_hp); b.p_hp := b.p_hp + heal;
    else
      bf := jsonb_set(bf, array[sk.effect], to_jsonb(case sk.effect when 'weak' then 3 else 2 end));
    end if;
    b.correct := b.correct + 1;
  end if;
  ev := ev || jsonb_build_object('dmg', dmg, 'heal', heal, 'crit', crit, 'fast', fast);
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
  intl int; mult numeric;
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
    fin := round(dmg * (1 - hits::numeric / n))::int;
  else
    fin := round(dmg * 0.7)::int;
  end if;
  if coalesce((bf->>'shield')::int, 0) > 0 then
    shield := true; fin := round(fin * 0.5)::int; bf := jsonb_set(bf, '{shield}', to_jsonb((bf->>'shield')::int - 1));
  end if;
  fin := round(fin * (_gear_battle(sid, m.element)->>'in_mult')::numeric)::int;   -- ป้องกัน + ธาตุแพ้ทาง (SQL 81)
  fin := greatest(case when perfect then 0 else 1 end, fin);
  if coalesce((bf->>'weak')::int, 0) > 0 then bf := jsonb_set(bf, '{weak}', to_jsonb((bf->>'weak')::int - 1)); end if;
  b.p_hp := greatest(0, b.p_hp - fin);
  -- ปัดป้องสมบูรณ์: สวนกลับ + ฟื้น HP (สวนกลับไม่ฆ่า เหลือ HP อย่างน้อย 1)
  if perfect and b.p_hp > 0 then
    st := _stats(sid); intl := coalesce((st->'int'->>'total')::int, 0);
    mult := 1 + coalesce((st->'effects'->>'boss_pct')::int, 0) / 100.0;
    if coalesce((bf->>'weak')::int, 0) > 0 then mult := mult * 1.4; end if;
    mult := mult * (_gear_battle(sid, m.element)->>'atk_mult')::numeric;
    ctr := greatest(1, round((20 + intl / 2.0) * mult)::int);
    ctr := least(ctr, greatest(0, b.m_hp - 1));
    b.m_hp := b.m_hp - ctr;
    hl := least(b.p_max - b.p_hp, round(b.p_max * 0.08)::int); b.p_hp := b.p_hp + hl;
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
