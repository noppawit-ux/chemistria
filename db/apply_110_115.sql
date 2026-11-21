-- 110: ระบบท้าทายดันเจี้ยน (ต้นแบบ 1 ดันเจี้ยน 5 ชั้น) — ต่อยอดระบบศึกเดิม ไม่แก้ฟังก์ชัน battle_* ที่ใช้งานอยู่
-- แนวคิด: 1 ชั้น = 1 แถวใน battles (สู้ด้วยสกิล/คำถาม/ตั้งรับเดิม) ผูกกับ dungeon_runs ผ่าน battles.dungeon_run
--   · มอนสเตอร์ของแต่ละชั้นเป็นแถวใน monsters ที่ซ่อนด้วย trial_rank = 'dg1:N' (ไม่โผล่ในรายการศึกปกติ — กลไกเดียวกับบอสด่านเลื่อนแรงค์)
--   · HP ยกต่อชั้น (ฟื้นให้ dungeon_heal_pct % ของ HP สูงสุดระหว่างชั้น) · ตายหรือออกกลางคัน = ได้รางวัลสะสม dungeon_fail_pct %
--   · ผ่านครบทุกชั้น = รางวัลเต็ม + หีบบอส (สุ่มไอเทมจาก _battle_drop 2 ครั้ง)
--   · จำกัดรอบต่อวัน dungeon_runs_per_day (ค่าเริ่มต้น 2) · บันทึกชั้นสูงสุด + อันดับในห้องเดียวกัน
-- ตั้งค่าได้ในตาราง settings ฝั่งครู (ถ้ามี): dungeon_runs_per_day, dungeon_heal_pct, dungeon_fail_pct

create table if not exists dungeons (
  key text primary key, name text not null, emoji text not null default '🏰', descr text,
  min_level int not null default 1, floors int not null default 5 check (floors between 1 and 20),
  active boolean not null default true, sort int not null default 0);

create table if not exists dungeon_floors (
  dungeon_key text not null references dungeons(key) on delete cascade, floor int not null check (floor >= 1),
  monster_key text not null, bg text,                      -- bg = ฉากพื้นหลังของชั้น (assets/bg/…)
  exp int not null default 10, coins int not null default 5, boss boolean not null default false,
  primary key (dungeon_key, floor));

create table if not exists dungeon_runs (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  dungeon_key text not null references dungeons(key),
  status text not null default 'active' check (status in ('active', 'cleared', 'failed', 'left')),
  floor int not null default 1, cleared int not null default 0,        -- floor = ชั้นปัจจุบัน · cleared = ชั้นที่ผ่านแล้ว (ชั้นสูงสุดของรอบนี้)
  p_hp int, exp int not null default 0, coins int not null default 0,   -- สะสมระหว่างวิ่ง (ยังไม่จ่าย)
  paid_exp int not null default 0, paid_coins int not null default 0, chest jsonb,
  battle_id uuid, run_date date not null default today_th(),
  started_at timestamptz not null default now(), finished_at timestamptz);
create index if not exists idx_dg_runs_student on dungeon_runs (student_id, run_date);
create index if not exists idx_dg_runs_board on dungeon_runs (dungeon_key, cleared desc);
create unique index if not exists uq_dg_run_active on dungeon_runs (student_id) where status = 'active';   -- วิ่งได้ทีละรอบ

alter table battles add column if not exists dungeon_run uuid references dungeon_runs(id) on delete set null;
create index if not exists idx_battles_dungeon on battles (dungeon_run) where dungeon_run is not null;

do $$ declare t text; begin
  foreach t in array array['dungeons', 'dungeon_floors', 'dungeon_runs'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists teacher_all on public.%I', t);
    execute format('create policy teacher_all on public.%I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;

-- ---------- ข้อมูลตั้งต้น: ดันเจี้ยน "ถ้ำคริสตัลเคมี" 5 ชั้น ----------
insert into dungeons (key, name, emoji, descr, min_level, floors, sort) values
  ('crystal_cave', 'ถ้ำคริสตัลเคมี', '💎', 'ไต่ 5 ชั้น ผ่านป่าสนและป่าเห็ดเรืองแสง สู่ถ้ำคริสตัล เลือด/สถานะยกต่อชั้น ชั้นสุดท้ายคือบอส', 1, 5, 1)
on conflict (key) do nothing;

-- มอนสเตอร์ประจำชั้น (คัดลอกหน้าตา/ธาตุจากมอนสเตอร์เดิม ปรับพลัง) · ซ่อนจากรายการศึกปกติด้วย trial_rank
insert into monsters (key, name, emoji, image, level, hp, atk, exp, coins, atk_name, descr, sort, active, arena, element, trial_rank)
select v.k, v.n, b.emoji, b.image, v.lv, v.hp, v.atk, 0, 0, b.atk_name, 'มอนสเตอร์ดันเจี้ยน ชั้น ' || v.fl, 900 + v.fl, true, b.arena, b.element, 'dg1:' || v.fl
  from (values ('dg1_f1', 'บับเบิลโซดาจอมซ่า', 'bubble', 1, 70, 9, 1), ('dg1_f2', 'น้ำแข็งแห้งหนาวเหน็บ', 'frost', 2, 120, 13, 2),
               ('dg1_f3', 'กรดมะนาวเหลืองจัด', 'lemon', 3, 160, 17, 3), ('dg1_f4', 'ควอตซ์ผลึกคมกริบ', 'quartz', 4, 210, 20, 4),
               ('dg1_f5', 'ราชาผลึกแห่งถ้ำ', 'geode', 5, 380, 26, 5)) v(k, n, base, lv, hp, atk, fl)
  join monsters b on b.key = v.base
on conflict (key) do nothing;

insert into dungeon_floors (dungeon_key, floor, monster_key, bg, exp, coins, boss) values
  ('crystal_cave', 1, 'dg1_f1', 'assets/bg/a1.webp', 12, 6, false),
  ('crystal_cave', 2, 'dg1_f2', 'assets/bg/a1.webp', 20, 10, false),
  ('crystal_cave', 3, 'dg1_f3', 'assets/bg/s5.webp', 30, 15, false),
  ('crystal_cave', 4, 'dg1_f4', 'assets/bg/s5.webp', 42, 20, false),
  ('crystal_cave', 5, 'dg1_f5', 'assets/bg/s6.webp', 80, 40, true)
on conflict (dungeon_key, floor) do nothing;

-- ---------- ตัวช่วยภายใน ----------
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
    'waiting_next', r.status = 'active' and r.cleared >= r.floor,          -- ชั้นนี้ชนะแล้ว รอกดไปชั้นต่อไป
    'map', (select coalesce(json_agg(json_build_object('floor', x.floor, 'boss', x.boss, 'bg', x.bg, 'exp', x.exp, 'coins', x.coins,
              'monster', json_build_object('name', m.name, 'emoji', m.emoji, 'image', m.image), 'done', x.floor <= r.cleared) order by x.floor), '[]'::json)
              from dungeon_floors x join monsters m on m.key = x.monster_key where x.dungeon_key = r.dungeon_key),
    'battle', case when r.battle_id is null then null else _battle_view(r.battle_id) end);
end $$;

-- จบรอบ: จ่ายรางวัลสะสม (ผ่านครบ 100% · ตาย/ออกกลางคัน dungeon_fail_pct %) + หีบบอสเมื่อผ่านครบ
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
      dr := _battle_drop(r.student_id, coalesce(p_battle, r.battle_id));
      if dr is not null then ch := ch || jsonb_build_array(dr::jsonb); end if;
    end loop;
  end if;
  update dungeon_runs set status = p_status, paid_exp = e, paid_coins = c, chest = case when p_status = 'cleared' then ch else null end,
         finished_at = now() where id = r.id;
end $$;

-- เริ่มศึกของชั้นปัจจุบัน (ใช้ battle_start เดิมผ่านกลไก app.trial_ok เหมือนบอสด่านเลื่อนแรงค์ แล้วปรับให้เป็นศึกดันเจี้ยน)
create or replace function _dungeon_floor_start(p_token uuid, p_run uuid) returns void
language plpgsql security definer set search_path = public as $$
declare r dungeon_runs%rowtype; f dungeon_floors%rowtype; m monsters%rowtype; res json; bid uuid; heal int; php int;
begin
  select * into r from dungeon_runs where id = p_run for update;
  select * into f from dungeon_floors where dungeon_key = r.dungeon_key and floor = r.floor;
  if not found then raise exception 'ไม่พบข้อมูลชั้น % ของดันเจี้ยน', r.floor; end if;
  select * into m from monsters where key = f.monster_key and active;
  if not found then raise exception 'มอนสเตอร์ของชั้นนี้ถูกปิดใช้งาน'; end if;
  perform set_config('app.trial_ok', '1', true);
  res := battle_start(p_token, m.id);
  perform set_config('app.trial_ok', '0', true);
  bid := (res->>'id')::uuid;
  heal := ceil((res->>'p_max')::int * _setting_int('dungeon_heal_pct', 30) / 100.0)::int;
  php := case when r.p_hp is null then (res->>'p_max')::int else least((res->>'p_max')::int, greatest(1, r.p_hp) + heal) end;
  update battles set dungeon_run = r.id, rewarded = false, p_hp = php where id = bid;
  update dungeon_runs set battle_id = bid, p_hp = php where id = r.id;
end $$;

-- ผลศึกของชั้น → อัปเดตรอบ (ชนะ: เก็บรางวัลชั้น/จบถ้าเป็นชั้นสุดท้าย · แพ้/หนี: จบรอบ)
create or replace function trg_dungeon_battle() returns trigger
language plpgsql security definer set search_path = public as $$
declare r dungeon_runs%rowtype; d dungeons%rowtype; f dungeon_floors%rowtype;
begin
  select * into r from dungeon_runs where id = new.dungeon_run for update;
  if not found or r.status <> 'active' then return new; end if;
  select * into d from dungeons where key = r.dungeon_key;
  if new.status = 'won' then
    select * into f from dungeon_floors where dungeon_key = r.dungeon_key and floor = r.floor;
    update dungeon_runs set cleared = greatest(cleared, r.floor), exp = exp + coalesce(f.exp, 0), coins = coins + coalesce(f.coins, 0), p_hp = new.p_hp where id = r.id;
    if r.floor >= d.floors then perform _dungeon_finish(r.id, 'cleared', new.id); end if;
  else
    perform _dungeon_finish(r.id, case when new.status = 'lost' then 'failed' else 'left' end, new.id);
  end if;
  return new;
end $$;
drop trigger if exists dungeon_battle on battles;
create trigger dungeon_battle after update of status on battles
  for each row when (new.dungeon_run is not null and old.status = 'active' and new.status in ('won', 'lost', 'fled'))
  execute function trg_dungeon_battle();

-- ---------- RPC ฝั่งนักเรียน ----------
create or replace function dungeon_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); lv int := level_for((select exp from students where id = sid)); cid uuid := (select class_id from students where id = sid);
        lim int := _setting_int('dungeon_runs_per_day', 2); used int; act uuid;
begin
  select count(*) into used from dungeon_runs where student_id = sid and run_date = today_th();
  select id into act from dungeon_runs where student_id = sid and status = 'active';
  return json_build_object('used', used, 'limit', lim, 'level', lv,
    'active', case when act is null then null else _dungeon_view(act) end,
    'dungeons', (select coalesce(json_agg(json_build_object('key', d.key, 'name', d.name, 'emoji', d.emoji, 'descr', d.descr,
        'floors', d.floors, 'min_level', d.min_level, 'locked', d.min_level > lv,
        'best', coalesce((select max(r.cleared) from dungeon_runs r where r.student_id = sid and r.dungeon_key = d.key), 0),
        'clears', (select count(*) from dungeon_runs r where r.student_id = sid and r.dungeon_key = d.key and r.status = 'cleared'),
        'map', (select coalesce(json_agg(json_build_object('floor', x.floor, 'boss', x.boss, 'bg', x.bg, 'exp', x.exp, 'coins', x.coins,
                  'monster', json_build_object('name', m.name, 'emoji', m.emoji, 'image', m.image)) order by x.floor), '[]'::json)
                  from dungeon_floors x join monsters m on m.key = x.monster_key where x.dungeon_key = d.key),
        'board', (select coalesce(json_agg(b order by b.best desc, b.clears desc, b.name), '[]'::json) from (
                    select st.name, st.avatar, max(r.cleared) as best, count(*) filter (where r.status = 'cleared') as clears, (st.id = sid) as mine
                      from dungeon_runs r join students st on st.id = r.student_id
                     where r.dungeon_key = d.key and st.class_id = cid and r.cleared > 0
                     group by st.id, st.name, st.avatar order by max(r.cleared) desc, count(*) filter (where r.status = 'cleared') desc, st.name limit 10) b)
      ) order by d.sort), '[]'::json) from dungeons d where d.active));
end $$;

create or replace function dungeon_start(p_token uuid, p_key text) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); d dungeons%rowtype; lv int := level_for((select exp from students where id = sid));
        lim int := _setting_int('dungeon_runs_per_day', 2); used int; r dungeon_runs%rowtype;
begin
  select * into r from dungeon_runs where student_id = sid and status = 'active';
  if found then return _dungeon_view(r.id); end if;                          -- มีรอบค้างอยู่ → เล่นต่อ
  select * into d from dungeons where key = p_key and active;
  if not found then raise exception 'ไม่พบดันเจี้ยนนี้'; end if;
  if d.min_level > lv then raise exception 'ยังเข้าดันเจี้ยนนี้ไม่ได้ (ต้องถึงเลเวล %)', d.min_level; end if;
  select count(*) into used from dungeon_runs where student_id = sid and run_date = today_th();
  if used >= lim then raise exception 'วันนี้เข้าดันเจี้ยนครบ % รอบแล้ว พรุ่งนี้มาใหม่นะ', lim; end if;
  insert into dungeon_runs (student_id, dungeon_key) values (sid, d.key) returning * into r;
  perform _dungeon_floor_start(p_token, r.id);
  return _dungeon_view(r.id);
end $$;

create or replace function dungeon_next(p_token uuid, p_run uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); r dungeon_runs%rowtype; d dungeons%rowtype;
begin
  select * into r from dungeon_runs where id = p_run and student_id = sid for update;
  if not found or r.status <> 'active' then raise exception 'ไม่พบรอบดันเจี้ยนที่กำลังเล่นอยู่'; end if;
  select * into d from dungeons where key = r.dungeon_key;
  if r.cleared < r.floor then return _dungeon_view(r.id); end if;           -- ชั้นนี้ยังไม่ชนะ (กดซ้ำ/กลับมาเล่นต่อ)
  if r.floor >= d.floors then raise exception 'ผ่านครบทุกชั้นแล้ว'; end if;
  update dungeon_runs set floor = r.floor + 1 where id = r.id;
  perform _dungeon_floor_start(p_token, r.id);
  return _dungeon_view(r.id);
end $$;

create or replace function dungeon_leave(p_token uuid, p_run uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); r dungeon_runs%rowtype;
begin
  select * into r from dungeon_runs where id = p_run and student_id = sid for update;
  if not found or r.status <> 'active' then raise exception 'ไม่พบรอบดันเจี้ยนที่กำลังเล่นอยู่'; end if;
  if r.battle_id is not null and exists (select 1 from battles where id = r.battle_id and status = 'active') then
    update battles set status = 'fled', finished_at = now() where id = r.battle_id;    -- ทริกเกอร์จะจบรอบให้ (left)
  else
    perform _dungeon_finish(r.id, 'left', r.battle_id);
  end if;
  return _dungeon_view(r.id);
end $$;

-- ดูสถานะรอบหนึ่ง (ใช้ตอนศึกของชั้นจบ เพื่อดูรางวัลที่จ่าย/หีบบอส) — ดูได้เฉพาะรอบของตัวเอง
create or replace function dungeon_run(p_token uuid, p_run uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  if not exists (select 1 from dungeon_runs where id = p_run and student_id = sid) then raise exception 'ไม่พบรอบดันเจี้ยน'; end if;
  return _dungeon_view(p_run);
end $$;

revoke execute on function _dungeon_view(uuid), _dungeon_finish(uuid, text, uuid), _dungeon_floor_start(uuid, uuid), trg_dungeon_battle() from public, anon, authenticated;
revoke execute on function dungeon_status(uuid), dungeon_start(uuid, text), dungeon_next(uuid, uuid), dungeon_leave(uuid, uuid), dungeon_run(uuid, uuid) from public;
grant execute on function dungeon_status(uuid), dungeon_start(uuid, text), dungeon_next(uuid, uuid), dungeon_leave(uuid, uuid), dungeon_run(uuid, uuid) to anon, authenticated;
-- SQL 111 · ดันเจี้ยนเพิ่ม 3 แห่ง (ต่อจาก 110) — รันซ้ำได้ (on conflict do nothing)
--   โรงหลอมภูเขาไฟ 🌋 (เลเวล 3+) · บึงก๊าซพิษ ☣️ (เลเวล 6+) · ห้องแล็บอวกาศ 🚀 (เลเวล 10+)
--   โครงสร้างเหมือน crystal_cave: 5 ชั้น ชั้นสุดท้ายเป็นบอส · มอนสเตอร์ซ่อนด้วย trial_rank = 'dgN:ชั้น'
insert into dungeons (key, name, emoji, descr, min_level, floors, sort) values
  ('volcano_forge', 'โรงหลอมภูเขาไฟ', '🌋', 'ผ่านเมืองยามเย็นลงสู่โรงหลอมลาวา เจอสนิม เขม่า และลาวาโซเดียม ชั้นสุดท้ายคือราชาลาวา', 3, 5, 2),
  ('toxic_swamp', 'บึงก๊าซพิษ', '☣️', 'บึงหมอกแอมโมเนียและเมือกกรด ตอบเร็วลดดาเมจให้ทัน ชั้นสุดท้ายคือเจ้าแห่งก๊าซคลอรีน', 6, 5, 3),
  ('space_lab', 'ห้องแล็บอวกาศ', '🚀', 'ด่านสุดท้ายของเหล่านักเคมี ไนโตรเจนเหลว โอโซน และพลาสมา ชั้นสุดท้ายคือมหาพลาสมาแห่งจักรวาล', 10, 5, 4)
on conflict (key) do nothing;

insert into monsters (key, name, emoji, image, level, hp, atk, exp, coins, atk_name, descr, sort, active, arena, element, trial_rank)
select v.k, v.n, b.emoji, b.image, least(v.lv, 5), v.hp, v.atk, 0, 0, b.atk_name, 'มอนสเตอร์ดันเจี้ยน ชั้น ' || v.fl, 900 + v.dg * 10 + v.fl, true, b.arena, b.element, 'dg' || v.dg || ':' || v.fl
  from (values
    ('dg2_f1', 'สนิมเหล็กจอมกัดกร่อน', 'rust', 3, 150, 14, 1, 2), ('dg2_f2', 'เขม่าคาร์บอนมืดมิด', 'ash', 4, 200, 18, 2, 2),
    ('dg2_f3', 'ลาวาโซเดียมระเบิด', 'lava', 5, 260, 22, 3, 2), ('dg2_f4', 'พลาสมาไฟนรก', 'plasma', 6, 330, 26, 4, 2),
    ('dg2_f5', 'ราชาลาวาแห่งโรงหลอม', 'lava', 7, 600, 34, 5, 2),
    ('dg3_f1', 'หมอกแอมโมเนียหลอน', 'fog', 6, 190, 18, 1, 3), ('dg3_f2', 'เมือกกรดซัลฟิวริกเดือด', 'sludge', 7, 250, 22, 2, 3),
    ('dg3_f3', 'เกลือพิษจอมซ่า', 'salt', 8, 320, 26, 3, 3), ('dg3_f4', 'ก๊าซคลอรีนพิษร้าย', 'toxic', 9, 400, 30, 4, 3),
    ('dg3_f5', 'เจ้าแห่งก๊าซคลอรีน', 'toxic', 10, 720, 40, 5, 3),
    ('dg4_f1', 'ไนโตรเจนเหลวนักล่า', 'cryo', 10, 260, 24, 1, 4), ('dg4_f2', 'โอโซนพายุจักรวาล', 'ozone', 11, 340, 28, 2, 4),
    ('dg4_f3', 'น้ำแข็งแห้งดวงดาว', 'frost', 12, 420, 33, 3, 4), ('dg4_f4', 'ไข่ธรณีผลึกอวกาศ', 'geode', 13, 520, 38, 4, 4),
    ('dg4_f5', 'มหาพลาสมาแห่งจักรวาล', 'plasma', 15, 900, 48, 5, 4)
  ) v(k, n, base, lv, hp, atk, fl, dg)
  join monsters b on b.key = v.base
on conflict (key) do nothing;

insert into dungeon_floors (dungeon_key, floor, monster_key, bg, exp, coins, boss) values
  ('volcano_forge', 1, 'dg2_f1', 'assets/bg/a4.webp', 25, 12, false), ('volcano_forge', 2, 'dg2_f2', 'assets/bg/a4.webp', 40, 20, false),
  ('volcano_forge', 3, 'dg2_f3', 'assets/bg/s4.webp', 60, 30, false), ('volcano_forge', 4, 'dg2_f4', 'assets/bg/s4.webp', 85, 42, false),
  ('volcano_forge', 5, 'dg2_f5', 'assets/bg/s6.webp', 160, 80, true),
  ('toxic_swamp', 1, 'dg3_f1', 'assets/bg/a3.webp', 40, 20, false), ('toxic_swamp', 2, 'dg3_f2', 'assets/bg/a3.webp', 65, 32, false),
  ('toxic_swamp', 3, 'dg3_f3', 'assets/bg/s3.webp', 95, 47, false), ('toxic_swamp', 4, 'dg3_f4', 'assets/bg/s5.webp', 130, 65, false),
  ('toxic_swamp', 5, 'dg3_f5', 'assets/bg/s5.webp', 250, 125, true),
  ('space_lab', 1, 'dg4_f1', 'assets/bg/a2.webp', 60, 30, false), ('space_lab', 2, 'dg4_f2', 'assets/bg/a2.webp', 95, 47, false),
  ('space_lab', 3, 'dg4_f3', 'assets/bg/s7.webp', 140, 70, false), ('space_lab', 4, 'dg4_f4', 'assets/bg/s7.webp', 190, 95, false),
  ('space_lab', 5, 'dg4_f5', 'assets/bg/s7.webp', 360, 180, true)
on conflict (dungeon_key, floor) do nothing;
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
-- SQL 113 · เคมีรัน: ระดับความยากของแต่ละด่าน (⭐1–5) + โบนัส EXP ตามความยาก (คำนวณที่เซิร์ฟเวอร์)
--   · ไม่แก้ run_submit เดิม: ฟังก์ชันใหม่ run_submit_v2(token, score, seconds, stage) เรียก run_submit แล้วเติมโบนัส
--   · โบนัส = EXP ที่ได้จากรอบนั้น × bonus_pct/100 (ปัดเศษ) · ไม่เกินเพดาน EXP จากเกมต่อวัน · ไม่ได้ EXP รอบนั้น = ไม่มีโบนัส
--   · ครูแก้ดาว/โบนัสได้ที่ตาราง run_stages · รันซ้ำได้
create table if not exists run_stages (
  stage text primary key, name text not null, stars int not null check (stars between 1 and 5),
  bonus_pct int not null default 0 check (bonus_pct between 0 and 100), sort int not null default 0);
alter table run_stages enable row level security;
drop policy if exists teacher_all on run_stages;
create policy teacher_all on run_stages for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on run_stages from anon;
grant select, insert, update, delete on run_stages to authenticated;

insert into run_stages (stage, name, stars, bonus_pct, sort) values
  ('lab', 'ห้องแล็บ', 1, 0, 1), ('sea', 'ทะเลหลากสี', 2, 10, 2), ('fall', 'น้ำตกเวทมนตร์', 2, 10, 3),
  ('mtn', 'ภูเขายามเช้า', 3, 20, 4), ('night', 'ป่าเงียบยามค่ำ', 3, 20, 5),
  ('space', 'อวกาศ', 4, 35, 6), ('ice', 'ธารน้ำแข็ง', 5, 50, 7), ('rand', 'สุ่มด่าน', 3, 15, 8)
on conflict (stage) do nothing;

create or replace function run_stage_info(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
begin
  perform _sid(p_token);
  return (select coalesce(json_object_agg(stage, json_build_object('stars', stars, 'bonus_pct', bonus_pct)), '{}'::json) from run_stages);
end $$;

create or replace function run_submit_v2(p_token uuid, p_score int, p_seconds int, p_stage text) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); d date := today_th(); r jsonb; rs run_stages%rowtype; e int; bonus int := 0;
        cap int := _setting_int('game_daily_cap_exp', 25); room int; pid uuid;
begin
  r := run_submit(p_token, p_score, p_seconds)::jsonb;
  select * into rs from run_stages where stage = coalesce(p_stage, 'rand');
  if not found then select * into rs from run_stages where stage = 'rand'; end if;
  e := coalesce((r->>'exp')::int, 0);
  if found and e > 0 and coalesce((r->>'no_reward')::boolean, false) = false and rs.bonus_pct > 0 then
    room := greatest(0, cap - _game_exp_today(sid));
    bonus := least(round(e * rs.bonus_pct / 100.0)::int, room);
    if bonus > 0 then
      select id into pid from game_plays where student_id = sid and game = 'run' and play_date = d order by created_at desc limit 1;
      update game_plays set exp = exp + bonus where id = pid;
      perform award(sid, bonus, 0, 'เคมีรัน โบนัสด่าน ' || rs.name || ' ' || repeat('⭐', rs.stars), 'game:runbonus:' || pid);
    end if;
  end if;
  return (r || jsonb_build_object('bonus', bonus, 'stars', coalesce(rs.stars, 1), 'stage', coalesce(rs.stage, 'rand')))::json;
end $$;

revoke execute on function run_stage_info(uuid), run_submit_v2(uuid, int, int, text) from public;
grant execute on function run_stage_info(uuid), run_submit_v2(uuid, int, int, text) to anon, authenticated;
-- SQL 114 · ดันเจี้ยน: ระดับความยาก ⭐1–5 (แสดงป้ายดาวในหน้าเกม) · ต้องรันหลัง 110/111 · รันซ้ำได้
alter table dungeons add column if not exists stars int not null default 1 check (stars between 1 and 5);
update dungeons set stars = v.s from (values ('crystal_cave', 2), ('volcano_forge', 3), ('toxic_swamp', 4), ('space_lab', 5)) v(k, s) where dungeons.key = v.k;

create or replace function dungeon_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); lv int := level_for((select exp from students where id = sid)); cid uuid := (select class_id from students where id = sid);
        lim int := _setting_int('dungeon_runs_per_day', 2); used int; act uuid;
begin
  select count(*) into used from dungeon_runs where student_id = sid and run_date = today_th();
  select id into act from dungeon_runs where student_id = sid and status = 'active';
  return json_build_object('used', used, 'limit', lim, 'level', lv,
    'active', case when act is null then null else _dungeon_view(act) end,
    'dungeons', (select coalesce(json_agg(json_build_object('key', d.key, 'name', d.name, 'emoji', d.emoji, 'descr', d.descr,
        'floors', d.floors, 'stars', d.stars, 'min_level', d.min_level, 'locked', d.min_level > lv,
        'best', coalesce((select max(r.cleared) from dungeon_runs r where r.student_id = sid and r.dungeon_key = d.key), 0),
        'clears', (select count(*) from dungeon_runs r where r.student_id = sid and r.dungeon_key = d.key and r.status = 'cleared'),
        'map', (select coalesce(json_agg(json_build_object('floor', x.floor, 'boss', x.boss, 'bg', x.bg, 'exp', x.exp, 'coins', x.coins,
                  'monster', json_build_object('name', m.name, 'emoji', m.emoji, 'image', m.image)) order by x.floor), '[]'::json)
                  from dungeon_floors x join monsters m on m.key = x.monster_key where x.dungeon_key = d.key),
        'board', (select coalesce(json_agg(b order by b.best desc, b.clears desc, b.name), '[]'::json) from (
                    select st.name, st.avatar, max(r.cleared) as best, count(*) filter (where r.status = 'cleared') as clears, (st.id = sid) as mine
                      from dungeon_runs r join students st on st.id = r.student_id
                     where r.dungeon_key = d.key and st.class_id = cid and r.cleared > 0
                     group by st.id, st.name, st.avatar order by max(r.cleared) desc, count(*) filter (where r.status = 'cleared') desc, st.name limit 10) b)
      ) order by d.sort), '[]'::json) from dungeons d where d.active));
end $$;

revoke execute on function dungeon_status(uuid) from public;
grant execute on function dungeon_status(uuid) to anon, authenticated;
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
