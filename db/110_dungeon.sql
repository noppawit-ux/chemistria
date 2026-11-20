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
