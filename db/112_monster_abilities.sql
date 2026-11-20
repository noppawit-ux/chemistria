-- SQL 112 · มอนสเตอร์ระดับสูง + "สกิลยูนิค" ของมอนสเตอร์ (ท้าทายขึ้น)
--   · ไม่แก้ฟังก์ชัน battle_* เดิม: สกิลยูนิคทำงานด้วยทริกเกอร์ BEFORE INSERT/UPDATE บนตาราง battles
--   · มอนสเตอร์ 1 ตัวมีสกิลยูนิคได้ 1 อย่าง (monsters.ability) · แสดงผลให้ผู้เล่นผ่านช่อง battles.buffs (mab = รหัสสกิล, mev = เหตุการณ์ล่าสุด)
--   · ขยายเลเวลมอนสเตอร์เป็น 1–10 + สนามใหม่ 3 แห่ง (เลเวล 11/13/15) + มอนสเตอร์ใหม่ 13 ตัว · ใส่สกิลยูนิคให้มอนสเตอร์ในดันเจี้ยน
--   ต้องรันหลัง 110 และ 111 · รันซ้ำได้
do $$ declare c text; begin
  for c in select conname from pg_constraint where conrelid = 'public.monsters'::regclass and contype = 'c' and conname <> 'monsters_level_1_10' and pg_get_constraintdef(oid) ~* 'level' and pg_get_constraintdef(oid) !~* 'hp|atk' loop
    execute format('alter table public.monsters drop constraint %I', c);
  end loop;
  if not exists (select 1 from pg_constraint where conrelid = 'public.monsters'::regclass and conname = 'monsters_level_1_10') then
    alter table public.monsters add constraint monsters_level_1_10 check (level between 1 and 10);
  end if;
end $$;

create table if not exists monster_abilities (
  key text primary key, name text not null, emoji text not null, descr text not null, sort int not null default 0);
alter table monster_abilities enable row level security;
drop policy if exists teacher_all on monster_abilities;
create policy teacher_all on monster_abilities for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on monster_abilities from anon;
grant select, insert, update, delete on monster_abilities to authenticated;

insert into monster_abilities (key, name, emoji, descr, sort) values
  ('regen',  'ฟื้นฟูตัวเอง',    '🩹', 'จบทุกเทิร์น ฟื้น HP ตัวเอง 4% ของพลังชีวิตสูงสุด — ต้องรีบจบเกม',                     1),
  ('armor',  'เกราะผลึก',       '🛡️', 'ลดดาเมจที่โดนทุกครั้งลง 25% — ใช้สกิลแรงๆ และตีคริติคอล',                             2),
  ('drain',  'ดูดพลังชีวิต',    '🧛', 'ฟื้น HP ให้ตัวเอง 35% ของดาเมจที่ทำกับคุณ — ตั้งรับให้แม่นจะได้ไม่เสียเปรียบ',        3),
  ('enrage', 'คลุ้มคลั่ง',      '💢', 'เมื่อ HP เหลือไม่เกินครึ่ง โจมตีแรงขึ้น 30% — เตรียมโล่หรือยาไว้',                      4),
  ('burn',   'พิษเผาไหม้',      '🔥', 'จบทุกเทิร์น คุณเสีย HP เพิ่ม 3% ของสูงสุด (ไม่ทำให้ตาย) — ยิ่งยืดเกมยิ่งเสียเปรียบ',   5),
  ('thorns', 'หนามสะท้อน',      '🌵', 'ทุกครั้งที่คุณโจมตี จะโดนสะท้อน 10% ของดาเมจ (ไม่ทำให้ตาย)',                            6),
  ('storm',  'สายฟ้าฟาด',       '⚡', 'การโจมตีมีโอกาส 30% ที่จะฟาดแรงขึ้น 60% — ระวังเทิร์นที่โจมตีหนัก',                     7)
on conflict (key) do nothing;

alter table monsters add column if not exists ability text references monster_abilities(key);

-- ---------- ทริกเกอร์: สกิลยูนิคของมอนสเตอร์ ----------
create or replace function trg_monster_ability() returns trigger
language plpgsql security definer set search_path = public as $$
declare ab text; d int; txt text := ''; k int; dm int;
begin
  select ability into ab from monsters where id = new.monster_id;
  if ab is null then return new; end if;
  if tg_op = 'INSERT' then
    new.buffs := coalesce(new.buffs, '{}'::jsonb) || jsonb_build_object('mab', ab);
    return new;
  end if;
  if new.status <> 'active' or old.status <> 'active' then return new; end if;

  if old.pend is null and new.pend is not null then
    -- ช่วงที่ผู้เล่นเพิ่งใช้สกิล: เกราะ / หนาม / เตรียมโจมตีกลับ
    d := old.m_hp - new.m_hp;
    if ab = 'armor' and d > 0 then
      k := floor(d * 0.25)::int; new.m_hp := least(new.m_max, new.m_hp + k);
      if k > 0 then txt := '🛡️ เกราะผลึกลดดาเมจ ' || k; end if;
    elsif ab = 'thorns' and d > 0 and new.p_hp > 1 then
      k := least(new.p_hp - 1, greatest(1, round(d * 0.10)::int)); new.p_hp := new.p_hp - k;
      txt := '🌵 หนามสะท้อน -' || k || ' HP';
    elsif ab = 'enrage' and new.m_hp * 2 <= new.m_max then
      dm := round((new.pend->>'dmg')::int * 1.3)::int; new.pend := jsonb_set(new.pend, '{dmg}', to_jsonb(dm));
      txt := '💢 คลุ้มคลั่ง! โจมตีแรงขึ้น';
    elsif ab = 'storm' and random() < 0.30 then
      dm := round((new.pend->>'dmg')::int * 1.6)::int; new.pend := jsonb_set(new.pend, '{dmg}', to_jsonb(dm));
      txt := '⚡ สายฟ้าฟาด! การโจมตีรอบนี้แรงกว่าปกติ';
    end if;
  elsif old.pend is not null and new.pend is null and new.turn = old.turn + 1 then
    -- จบเทิร์นของมอนสเตอร์: ฟื้นฟู / ดูดเลือด / พิษเผาไหม้
    if ab = 'regen' and new.m_hp < new.m_max then
      k := least(new.m_max - new.m_hp, greatest(1, round(new.m_max * 0.04)::int)); new.m_hp := new.m_hp + k;
      txt := '🩹 ฟื้นฟูตัวเอง +' || k || ' HP';
    elsif ab = 'drain' and new.p_hp < old.p_hp and new.m_hp < new.m_max then
      k := least(new.m_max - new.m_hp, greatest(1, round((old.p_hp - new.p_hp) * 0.35)::int)); new.m_hp := new.m_hp + k;
      txt := '🧛 ดูดพลังชีวิต +' || k || ' HP';
    elsif ab = 'burn' and new.p_hp > 1 then
      k := least(new.p_hp - 1, greatest(2, round(new.p_max * 0.03)::int)); new.p_hp := new.p_hp - k;
      txt := '🔥 พิษเผาไหม้ -' || k || ' HP';
    end if;
  end if;
  if txt <> '' then
    new.buffs := coalesce(new.buffs, '{}'::jsonb) || jsonb_build_object('mev', jsonb_build_object('t', new.turn, 'txt', txt));
  end if;
  return new;
end $$;
drop trigger if exists monster_ability on battles;
create trigger monster_ability before insert or update on battles for each row execute function trg_monster_ability();
revoke execute on function trg_monster_ability() from public, anon, authenticated;

-- ---------- สนามใหม่ + มอนสเตอร์ระดับสูง ----------
insert into arenas (key, name, emoji, theme, descr, min_level, reward_pct, sort) values
  ('core',   'แกนกลางโลกหลอมเหลว', '🔥', 'volcano', 'ความร้อนระดับแกนโลก มอนสเตอร์มีสกิลยูนิค รางวัลคุ้มมาก', 11, 160, 7),
  ('abyss',  'เหวลึกธาตุมืด',      '🌑', 'swamp',   'หมอกพิษและกรดกัดกร่อนไม่มีที่สิ้นสุด',                     13, 175, 8),
  ('cosmos', 'สถานีอวกาศเคมี',     '🚀', 'storm',   'ด่านสุดยอดของนักเคมี มอนสเตอร์ทรงพลังที่สุด',               15, 190, 9)
on conflict (key) do nothing;

insert into monsters (key, name, emoji, image, level, hp, atk, exp, coins, atk_name, descr, sort, active, arena, element, ability)
select v.k, v.n, b.emoji, b.image, v.lv, v.hp, v.atk, v.exp, v.coins, v.an, v.ds, 300 + v.so, true, v.ar, b.element, v.ab
  from (values
    ('hi_core1', 'หินหลอมเหลวสุดร้อน',     'lava',   6, 320, 27, 58, 30, 'ลาวาถล่ม',          'หินหนืดจากแกนโลก เดือดจัดเมื่อบาดเจ็บ',          'core',   'enrage', 1),
    ('hi_core2', 'เขม่านรกกลืนแสง',        'ash',    7, 380, 31, 70, 36, 'ควันดำกลืนกิน',     'เขม่าที่ฟื้นตัวเองได้เรื่อยๆ',                     'core',   'regen',  2),
    ('hi_core3', 'พลาสมาแกนโลก',           'plasma', 8, 440, 35, 82, 42, 'คลื่นความร้อนสูง',  'ไอออนร้อนจัด เผาผู้เล่นทุกเทิร์น',                'core',   'burn',   3),
    ('hi_core4', 'ราชามังกรเหล็กหลอม',     'rust',   9, 540, 38, 98, 50, 'เกล็ดเหล็กกล้า',    'เกราะสนิมหนา ลดดาเมจที่โดน',                       'core',   'armor',  4),
    ('hi_aby1',  'หมอกพิษหลอนประสาท',      'fog',    7, 400, 31, 72, 37, 'หมอกแอมโมเนีย',     'หมอกแสบจมูก เผาไหม้ต่อเนื่อง',                    'abyss',  'burn',   5),
    ('hi_aby2',  'เมือกกรดกลืนกิน',        'sludge', 8, 470, 35, 85, 43, 'น้ำกรดดูดกลืน',     'เมือกที่ดูดพลังชีวิตคุณมาเป็นของตัวเอง',          'abyss',  'drain',  6),
    ('hi_aby3',  'คลอรีนทมิฬ',            'toxic',  9, 540, 39, 100, 51, 'ไอพิษทมิฬ',        'ก๊าซพิษหนามสะท้อน ใครตีโดนเจ็บตัว',               'abyss',  'thorns', 7),
    ('hi_aby4',  'เกลือสาปแห่งเหวลึก',     'salt',  10, 700, 44, 120, 60, 'ผลึกเกลือสาป',     'ผลึกเกลือที่งอกฟื้นตัวเองอยู่เสมอ',                'abyss',  'regen',  8),
    ('hi_cos1',  'ไนโตรเจนเหลวนอกโลก',     'cryo',   8, 480, 36, 88, 44, 'ลมเย็นสุดขั้ว',     'เย็นจัดและฟาดแรงเป็นระยะ',                         'cosmos', 'storm',  9),
    ('hi_cos2',  'ผลึกควอตซ์จักรวาล',      'quartz', 9, 560, 40, 104, 52, 'เศษผลึกดวงดาว',    'เกราะผลึกแข็งกว่าเพชร',                            'cosmos', 'armor', 10),
    ('hi_cos3',  'ไข่ธรณีดาวตก',           'geode', 10, 680, 44, 122, 61, 'แสงอุกกาบาต',      'ผลึกดูดพลังจากดาวตก',                              'cosmos', 'drain', 11),
    ('hi_cos4',  'มหาโอโซนอสูร',           'ozone', 10, 800, 50, 135, 68, 'พายุโอโซน',        'พายุที่ฟาดไม่เลือกหน้า',                           'cosmos', 'storm', 12),
    ('hi_cos5',  'จักรพรรดิพลาสมา',        'plasma',10, 1000, 54, 160, 80, 'พลาสมาล้างจักรวาล','บอสสูงสุดของสถานีอวกาศ คลุ้มคลั่งเมื่อเหลือครึ่งเดียว', 'cosmos', 'enrage', 13)
  ) v(k, n, base, lv, hp, atk, exp, coins, an, ds, ar, ab, so)
  join monsters b on b.key = v.base
on conflict (key) do nothing;

-- ---------- สกิลยูนิคของมอนสเตอร์ในดันเจี้ยน (ชั้นกลาง/บอส) ----------
update monsters set ability = v.ab from (values
  ('dg1_f4', 'armor'), ('dg1_f5', 'regen'),
  ('dg2_f3', 'enrage'), ('dg2_f4', 'burn'), ('dg2_f5', 'enrage'),
  ('dg3_f2', 'drain'), ('dg3_f4', 'thorns'), ('dg3_f5', 'drain'),
  ('dg4_f2', 'storm'), ('dg4_f4', 'armor'), ('dg4_f5', 'storm')) v(k, ab)
 where monsters.key = v.k and monsters.ability is null;

-- ---------- RPC ฝั่งนักเรียน: แคตาล็อกสกิล + สกิลของมอนสเตอร์แต่ละตัว ----------
create or replace function monster_ability_list(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
begin
  perform _sid(p_token);
  return json_build_object(
    'abilities', (select coalesce(json_agg(json_build_object('key', a.key, 'name', a.name, 'emoji', a.emoji, 'descr', a.descr) order by a.sort), '[]'::json) from monster_abilities a),
    'monsters', (select coalesce(json_object_agg(m.id::text, m.ability), '{}'::json) from monsters m where m.ability is not null and m.active));
end $$;
revoke execute on function monster_ability_list(uuid) from public;
grant execute on function monster_ability_list(uuid) to anon, authenticated;
