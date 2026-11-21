-- SQL 116 · ประตูมิติ: ปริศนา/มินิเกมก่อนสู้ทุกชั้น + เลือกโบนัสแบบ roguelike หลังจบชั้น + มอนสเตอร์ดันเจี้ยนเก่งขึ้น
--   ต้องรันหลัง 110–115 · รันซ้ำได้ · ไม่แก้ฟังก์ชัน battle_* (ใช้ทริกเกอร์ BEFORE UPDATE บน battles + แทนที่ฟังก์ชัน dungeon_* ของเราเอง)
--   ลำดับของแต่ละชั้น: ปริศนา (phase=puzzle) → ศึก (phase=fight) → เลือกโบนัส 1 ใน 3 (phase=perk) → ชั้นถัดไป
--   ปิดระบบใหม่ได้: app_settings dungeon_roguelike = 0 (กลับไปเข้าศึกทันทีเหมือนเดิม ไม่มีปริศนา/โบนัส)
--   ข้อจำกัด: ผลปริศนาเป็นมินิเกมฝั่งเครื่องนักเรียน เซิร์ฟเวอร์ตรวจได้แค่เวลาขั้นต่ำ (เหมือนเกมอื่นของระบบ) ผลดีจำกัดแค่ลดเลือดมอนสเตอร์ ~12–20%

alter table dungeon_runs add column if not exists phase text not null default 'fight' check (phase in ('puzzle', 'perk', 'fight'));
alter table dungeon_runs add column if not exists perks jsonb not null default '{}'::jsonb;      -- {perk_key: จำนวนที่เลือกสะสม}
alter table dungeon_runs add column if not exists perk_offer jsonb;                              -- ["key1","key2","key3"] ที่เสนอให้เลือกอยู่
alter table dungeon_runs add column if not exists pz_ok boolean;                                 -- ผลปริศนาของชั้นปัจจุบัน

create table if not exists dungeon_perks (
  id uuid not null default gen_random_uuid() unique, key text primary key, name text not null, emoji text not null, descr text not null,
  max_stack int not null default 3 check (max_stack between 1 and 9), active boolean not null default true, sort int not null default 0);
alter table dungeon_perks add column if not exists id uuid not null default gen_random_uuid();
create unique index if not exists uq_dungeon_perks_id on dungeon_perks (id);
alter table dungeon_perks enable row level security;
drop policy if exists teacher_all on dungeon_perks;
create policy teacher_all on dungeon_perks for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on dungeon_perks from anon;
grant select, insert, update, delete on dungeon_perks to authenticated;
insert into dungeon_perks (key, name, emoji, descr, max_stack, sort) values
  ('sharp',  'คมเขี้ยวเคมี',     '⚔️', 'ชั้นถัดไปมอนสเตอร์มีเลือดน้อยลง 12% (สะสมได้)',                          3, 1),
  ('aegis',  'เกราะอะตอม',       '🛡️', 'ดาเมจที่โดนจากมอนสเตอร์ลดลง 12% (สะสมได้)',                               3, 2),
  ('vigor',  'ใจสู้',            '❤️', 'เลือดสูงสุดเพิ่ม 15% (สะสมได้)',                                           3, 3),
  ('mend',   'น้ำยาฟื้นฟู',      '🩹', 'ฟื้นเลือดตอนเข้าชั้นเพิ่มอีก 20% ของสูงสุด (สะสมได้)',                     3, 4),
  ('greed',  'นักล่าสมบัติ',     '💰', 'EXP และเหรียญที่ได้จากแต่ละชั้นเพิ่ม 25% (สะสมได้)',                       4, 5),
  ('key',    'กุญแจทอง',         '🗝️', 'ถ้าพิชิตดันเจี้ยนได้ จะเปิดหีบสมบัติเพิ่มอีก 1 ใบ',                         2, 6),
  ('wise',   'จิตแหลมคม',        '🧠', 'ถ้าผ่านปริศนาของชั้น ลดเลือดมอนสเตอร์เพิ่มอีก 8% (สะสมได้)',                2, 7),
  ('gamble', 'สัญญาเสี่ยงโชค',   '🎲', 'เสี่ยง: มอนสเตอร์เลือดมากขึ้น 25% และตีแรงขึ้น 15% แต่ได้ EXP/เหรียญเพิ่ม 50%', 2, 8)
on conflict (key) do nothing;

create or replace function _pk(p jsonb, k text) returns int language sql immutable as $$ select coalesce((p ->> k)::int, 0) $$;

-- สุ่มโบนัสให้เลือก 3 อย่าง (ไม่เกินขีดสะสมของแต่ละอย่าง) · ไม่มีให้เลือกเลย = null
create or replace function _dungeon_offer(pk jsonb) returns jsonb
language sql volatile security definer set search_path = public as $$
  select to_jsonb(array_agg(key)) from (select key from dungeon_perks where active and _pk(pk, key) < max_stack order by random() limit 3) x
$$;

-- ---------- มุมมองรอบ (เพิ่ม phase / perks / ตัวเลือกโบนัส / ปริศนา) ----------
create or replace function _dungeon_view(p_run uuid) returns json
language plpgsql stable security definer set search_path = public as $$
declare r dungeon_runs%rowtype; d dungeons%rowtype; f dungeon_floors%rowtype;
begin
  select * into r from dungeon_runs where id = p_run;
  if not found then return null; end if;
  select * into d from dungeons where key = r.dungeon_key;
  select * into f from dungeon_floors where dungeon_key = r.dungeon_key and floor = r.floor;
  return json_build_object('id', r.id, 'status', r.status, 'floor', r.floor, 'floors', d.floors, 'cleared', r.cleared,
    'dungeon', json_build_object('key', d.key, 'name', d.name, 'emoji', d.emoji),
    'exp', r.exp, 'coins', r.coins, 'paid_exp', r.paid_exp, 'paid_coins', r.paid_coins, 'chest', r.chest,
    'bg', f.bg, 'boss', coalesce(f.boss, false), 'heal_pct', _setting_int('dungeon_heal_pct', 30),
    'waiting_next', r.status = 'active' and r.cleared >= r.floor,
    'phase', case when r.status = 'active' then r.phase else 'fight' end, 'pz_ok', r.pz_ok,
    'pz', case when r.status = 'active' and r.phase = 'puzzle' then
            json_build_object('type', (array['tap', 'decode', 'scramble', 'memory', 'pattern'])[1 + (abs(hashtext(r.id::text)) + r.floor) % 5], 'floor', r.floor) else null end,
    'perks', (select coalesce(json_agg(json_build_object('key', p.key, 'name', p.name, 'emoji', p.emoji, 'descr', p.descr, 'n', _pk(r.perks, p.key)) order by p.sort), '[]'::json)
                from dungeon_perks p where _pk(r.perks, p.key) > 0),
    'perk_offer', case when r.perk_offer is null then null else
            (select json_agg(json_build_object('key', p.key, 'name', p.name, 'emoji', p.emoji, 'descr', p.descr, 'n', _pk(r.perks, p.key) + 1, 'max', p.max_stack) order by p.sort)
               from dungeon_perks p where r.perk_offer ? p.key) end,
    'map', (select coalesce(json_agg(json_build_object('floor', x.floor, 'boss', x.boss, 'bg', x.bg, 'exp', x.exp, 'coins', x.coins,
              'monster', json_build_object('name', m.name, 'emoji', m.emoji, 'image', m.image), 'done', x.floor <= r.cleared) order by x.floor), '[]'::json)
              from dungeon_floors x join monsters m on m.key = x.monster_key where x.dungeon_key = r.dungeon_key),
    'battle', case when r.battle_id is null then null else _battle_view(r.battle_id) end);
end $$;

-- ---------- เริ่มศึกของชั้น: ใส่ผลโบนัส/ปริศนา (เลือดมอนสเตอร์ · เลือดผู้เล่น · ฟื้นตอนเข้าชั้น) ----------
create or replace function _dungeon_floor_start(p_token uuid, p_run uuid) returns void
language plpgsql security definer set search_path = public as $$
declare r dungeon_runs%rowtype; f dungeon_floors%rowtype; m monsters%rowtype; res json; bid uuid; heal int; php int; pm int; mm int; mf numeric; pk jsonb;
begin
  select * into r from dungeon_runs where id = p_run for update;
  select * into f from dungeon_floors where dungeon_key = r.dungeon_key and floor = r.floor;
  if not found then raise exception 'ไม่พบข้อมูลชั้น % ของดันเจี้ยน', r.floor; end if;
  select * into m from monsters where key = f.monster_key and active;
  if not found then raise exception 'มอนสเตอร์ของชั้นนี้ถูกปิดใช้งาน'; end if;
  perform set_config('app.trial_ok', '1', true);
  res := battle_start(p_token, m.id);
  perform set_config('app.trial_ok', '0', true);
  bid := (res->>'id')::uuid; pk := coalesce(r.perks, '{}'::jsonb);
  pm := round((res->>'p_max')::int * (1 + 0.15 * _pk(pk, 'vigor')))::int;
  heal := ceil(pm * (_setting_int('dungeon_heal_pct', 30) + 20 * _pk(pk, 'mend')) / 100.0)::int;
  php := case when r.p_hp is null then pm else least(pm, greatest(1, r.p_hp) + heal) end;
  mf := (1 - 0.12 * _pk(pk, 'sharp')) * (1 + 0.25 * _pk(pk, 'gamble'));
  if r.pz_ok is true then mf := mf * (1 - 0.12 - 0.08 * _pk(pk, 'wise')); elsif r.pz_ok is false then mf := mf * 1.08; end if;
  mf := greatest(0.35, mf);
  select m_max into mm from battles where id = bid;
  update battles set dungeon_run = r.id, rewarded = false, p_max = pm, p_hp = php, m_max = greatest(1, round(mm * mf)::int), m_hp = greatest(1, round(mm * mf)::int) where id = bid;
  update dungeon_runs set battle_id = bid, p_hp = php, phase = 'fight' where id = r.id;
end $$;

-- ---------- ทริกเกอร์: โบนัส เกราะอะตอม / สัญญาเสี่ยงโชค (ปรับดาเมจที่ผู้เล่นโดนตอนจบเทิร์นมอนสเตอร์) ----------
create or replace function trg_dungeon_perk() returns trigger
language plpgsql security definer set search_path = public as $$
declare pk jsonb; a int; g int; k int;
begin
  if new.dungeon_run is null or new.status <> 'active' or old.status <> 'active' then return new; end if;
  if not (old.pend is not null and new.pend is null and new.turn = old.turn + 1 and new.p_hp < old.p_hp and new.p_hp > 0) then return new; end if;
  select perks into pk from dungeon_runs where id = new.dungeon_run;
  a := _pk(pk, 'aegis'); g := _pk(pk, 'gamble');
  if a = 0 and g = 0 then return new; end if;
  k := round((old.p_hp - new.p_hp) * greatest(0.2, 1 - 0.12 * a) * (1 + 0.15 * g))::int;
  new.p_hp := least(new.p_max, greatest(1, old.p_hp - k));
  return new;
end $$;
drop trigger if exists dungeon_perk on battles;
create trigger dungeon_perk before update on battles for each row when (new.dungeon_run is not null) execute function trg_dungeon_perk();

-- ---------- ผลศึกของชั้น: รางวัลตามโบนัส + เปิดตัวเลือกโบนัส ----------
create or replace function trg_dungeon_battle() returns trigger
language plpgsql security definer set search_path = public as $$
declare r dungeon_runs%rowtype; d dungeons%rowtype; f dungeon_floors%rowtype; g numeric;
begin
  select * into r from dungeon_runs where id = new.dungeon_run for update;
  if not found or r.status <> 'active' then return new; end if;
  select * into d from dungeons where key = r.dungeon_key;
  if new.status = 'won' then
    select * into f from dungeon_floors where dungeon_key = r.dungeon_key and floor = r.floor;
    g := 1 + 0.25 * _pk(r.perks, 'greed') + 0.5 * _pk(r.perks, 'gamble') + case when r.pz_ok is true then 0.10 else 0 end;
    update dungeon_runs set cleared = greatest(cleared, r.floor), exp = exp + round(coalesce(f.exp, 0) * g)::int, coins = coins + round(coalesce(f.coins, 0) * g)::int, p_hp = new.p_hp where id = r.id;
    if r.floor >= d.floors then perform _dungeon_finish(r.id, 'cleared', new.id);
    elsif _setting_int('dungeon_roguelike', 1) = 1 then update dungeon_runs set phase = 'perk', perk_offer = _dungeon_offer(r.perks) where id = r.id; end if;
  else
    perform _dungeon_finish(r.id, case when new.status = 'lost' then 'failed' else 'left' end, new.id);
  end if;
  return new;
end $$;

-- ---------- จบรอบ: หีบเพิ่มตามโบนัสกุญแจทอง ----------
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
    for i in 1..(2 + _pk(r.perks, 'key')) loop
      if _loot_has('dungeon:' || r.dungeon_key) then dr := _loot_roll(r.student_id, 'dungeon:' || r.dungeon_key, true, case when i = 1 then 1.0 else null end);
      else dr := _battle_drop(r.student_id, coalesce(p_battle, r.battle_id)); end if;
      if dr is not null then ch := ch || jsonb_build_array(dr::jsonb); end if;
    end loop;
  end if;
  update dungeon_runs set status = p_status, paid_exp = e, paid_coins = c, chest = case when p_status = 'cleared' then ch else null end,
         finished_at = now(), phase = 'fight', perk_offer = null where id = r.id;
end $$;

-- ---------- RPC ฝั่งนักเรียน ----------
create or replace function dungeon_start(p_token uuid, p_key text) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); d dungeons%rowtype; lv int := level_for((select exp from students where id = sid));
        lim int := _setting_int('dungeon_runs_per_day', 2); used int; r dungeon_runs%rowtype; rl boolean := _setting_int('dungeon_roguelike', 1) = 1;
begin
  select * into r from dungeon_runs where student_id = sid and status = 'active';
  if found then return _dungeon_view(r.id); end if;
  select * into d from dungeons where key = p_key and active;
  if not found then raise exception 'ไม่พบดันเจี้ยนนี้'; end if;
  if d.min_level > lv then raise exception 'ยังเข้าดันเจี้ยนนี้ไม่ได้ (ต้องถึงเลเวล %)', d.min_level; end if;
  select count(*) into used from dungeon_runs where student_id = sid and run_date = today_th();
  if used >= lim then raise exception 'วันนี้เข้าดันเจี้ยนครบ % รอบแล้ว พรุ่งนี้มาใหม่นะ', lim; end if;
  insert into dungeon_runs (student_id, dungeon_key, phase) values (sid, d.key, case when rl then 'puzzle' else 'fight' end) returning * into r;
  if not rl then perform _dungeon_floor_start(p_token, r.id); end if;
  return _dungeon_view(r.id);
end $$;

-- ส่งผลปริศนาของชั้น → เริ่มศึก (ชนะปริศนา: เลือดมอนสเตอร์ลด · แพ้: เพิ่มเล็กน้อย) · ต้องใช้เวลาอย่างน้อย 2.5 วินาที
create or replace function dungeon_puzzle(p_token uuid, p_run uuid, p_ok boolean, p_secs numeric) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); r dungeon_runs%rowtype;
begin
  select * into r from dungeon_runs where id = p_run and student_id = sid for update;
  if not found or r.status <> 'active' then raise exception 'ไม่พบรอบดันเจี้ยนที่กำลังเล่นอยู่'; end if;
  if r.phase <> 'puzzle' then return _dungeon_view(r.id); end if;
  update dungeon_runs set pz_ok = coalesce(p_ok, false) and coalesce(p_secs, 0) >= 2.5 where id = r.id;
  perform _dungeon_floor_start(p_token, r.id);
  return _dungeon_view(r.id);
end $$;

create or replace function _dungeon_advance(p_token uuid, p_run uuid) returns void
language plpgsql security definer set search_path = public as $$
declare r dungeon_runs%rowtype; rl boolean := _setting_int('dungeon_roguelike', 1) = 1;
begin
  select * into r from dungeon_runs where id = p_run for update;
  update dungeon_runs set floor = r.floor + 1, perk_offer = null, pz_ok = null, battle_id = case when rl then null else battle_id end,
         phase = case when rl then 'puzzle' else 'fight' end where id = r.id;
  if not rl then perform _dungeon_floor_start(p_token, r.id); end if;
end $$;

create or replace function dungeon_pick(p_token uuid, p_run uuid, p_key text) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); r dungeon_runs%rowtype; d dungeons%rowtype;
begin
  select * into r from dungeon_runs where id = p_run and student_id = sid for update;
  if not found or r.status <> 'active' then raise exception 'ไม่พบรอบดันเจี้ยนที่กำลังเล่นอยู่'; end if;
  if r.phase <> 'perk' or r.perk_offer is null then return _dungeon_view(r.id); end if;
  if not (r.perk_offer ? p_key) then raise exception 'โบนัสนี้ไม่อยู่ในตัวเลือก'; end if;
  select * into d from dungeons where key = r.dungeon_key;
  update dungeon_runs set perks = perks || jsonb_build_object(p_key, _pk(perks, p_key) + 1) where id = r.id;
  if r.floor < d.floors then perform _dungeon_advance(p_token, r.id); end if;
  return _dungeon_view(r.id);
end $$;

create or replace function dungeon_next(p_token uuid, p_run uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); r dungeon_runs%rowtype; d dungeons%rowtype;
begin
  select * into r from dungeon_runs where id = p_run and student_id = sid for update;
  if not found or r.status <> 'active' then raise exception 'ไม่พบรอบดันเจี้ยนที่กำลังเล่นอยู่'; end if;
  select * into d from dungeons where key = r.dungeon_key;
  if r.cleared < r.floor then return _dungeon_view(r.id); end if;
  if r.floor >= d.floors then raise exception 'ผ่านครบทุกชั้นแล้ว'; end if;
  if r.phase = 'perk' and r.perk_offer is not null then raise exception 'เลือกโบนัสก่อนไปชั้นต่อไป'; end if;
  if r.phase = 'puzzle' then return _dungeon_view(r.id); end if;
  perform _dungeon_advance(p_token, r.id);
  return _dungeon_view(r.id);
end $$;

revoke execute on function _pk(jsonb, text), _dungeon_offer(jsonb), _dungeon_advance(uuid, uuid), trg_dungeon_perk() from public, anon, authenticated;
revoke execute on function dungeon_puzzle(uuid, uuid, boolean, numeric), dungeon_pick(uuid, uuid, text) from public;
grant execute on function dungeon_puzzle(uuid, uuid, boolean, numeric), dungeon_pick(uuid, uuid, text) to anon, authenticated;
revoke execute on function dungeon_start(uuid, text), dungeon_next(uuid, uuid) from public;
grant execute on function dungeon_start(uuid, text), dungeon_next(uuid, uuid) to anon, authenticated;

-- ---------- มอนสเตอร์ดันเจี้ยนเก่งขึ้น (ทำครั้งเดียว): เลือด ×1.3 · พลังโจมตี ×1.2 + สกิลยูนิคเพิ่มในชั้นกลาง ----------
create table if not exists dg_patch (key text primary key, done_at timestamptz not null default now());
alter table dg_patch enable row level security;
drop policy if exists teacher_all on dg_patch;
create policy teacher_all on dg_patch for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on dg_patch from anon;
grant select, insert, update, delete on dg_patch to authenticated;
do $$ begin
  if not exists (select 1 from dg_patch where key = 'monster_boost_116') then
    update monsters set hp = round(hp * 1.3)::int, atk = round(atk * 1.2)::int where trial_rank ~ '^dg[0-9]+:';
    update monsters set ability = v.ab from (values
      ('dg1_f3', 'storm'), ('dg2_f2', 'regen'), ('dg3_f3', 'enrage'), ('dg4_f1', 'thorns'), ('dg4_f3', 'burn'), ('dg3_f1', 'armor')) v(k, ab)
     where monsters.key = v.k and monsters.ability is null;
    insert into dg_patch (key) values ('monster_boost_116');
  end if;
end $$;
