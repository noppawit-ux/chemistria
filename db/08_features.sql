-- =====================================================================
-- Chemistria · รอบที่ 7: ฟังก์ชันแนะนำ 8 ข้อ
--  1 รางวัลทันทีหลังเช็คชื่อ/ส่งงาน (ตั๋วสุ่มกาชาฟรี + เควสอัตโนมัติ)   2 ตัวเตือนงานค้าง (ฝั่งหน้าเว็บ)
--  3 ทีม/ห้องแข่ง EXP   4 สรุปรายสัปดาห์ของครู   5 ควิซตามบทเรียน
--  6 ส่งออก Excel (ฝั่งหน้าเว็บ)   7 ส่งงานเป็นรูปภาพ/ออนไลน์   8 บอสประจำสัปดาห์
-- รันซ้ำได้ · ต้องรันหลัง 01–07 (setup_all.sql รวมให้แล้ว) · ฟังก์ชัน gacha_pull/trg_attendance/trg_submission/_quiz_ids ในไฟล์นี้ใช้แทนเวอร์ชันเดิม
-- =====================================================================

-- ---------------------------------------------------------------------
-- ตาราง/คอลัมน์ใหม่
-- ---------------------------------------------------------------------
alter table students add column if not exists free_pulls int not null default 0;
alter table quests add column if not exists auto_trigger text;
alter table quests drop constraint if exists quests_auto_trigger_check;
alter table quests add constraint quests_auto_trigger_check check (auto_trigger is null or auto_trigger in
  ('attendance','login','quiz','quiz_perfect','match','submit','gacha','decorate'));

alter table ch_assignments add column if not exists submit_mode text not null default 'teacher';
alter table ch_assignments drop constraint if exists ch_assignments_submit_mode_check;
alter table ch_assignments add constraint ch_assignments_submit_mode_check check (submit_mode in ('teacher','online','photo'));
alter table ch_submissions add column if not exists image_path text;
alter table ch_submissions add column if not exists note text;
alter table ch_submissions add column if not exists attempt int not null default 1;
alter table ch_submissions add column if not exists via text not null default 'teacher';

create table if not exists upload_slots (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  assignment_id uuid not null references ch_assignments(id) on delete cascade,
  expires_at timestamptz not null default now() + interval '15 minutes',
  used boolean not null default false
);

create table if not exists teams (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references classes(id) on delete cascade,
  name text not null,
  emoji text not null default '🧪',
  sort int not null default 0
);
alter table students add column if not exists team_id uuid references teams(id) on delete set null;

alter table quiz_questions add column if not exists class_id uuid references classes(id) on delete cascade;   -- null = ทุกห้อง
alter table classes add column if not exists quiz_topic text;                                                 -- บทที่กำลังเรียน (ควิซจะเน้นหัวข้อนี้)

create table if not exists bosses (
  id uuid primary key default gen_random_uuid(),
  class_id uuid references classes(id) on delete cascade,          -- null = ทุกห้อง
  name text not null,
  emoji text not null default '👹',
  image text,                                                      -- ภาพมอนสเตอร์ เช่น assets/bosses/acid_dragon.png (ว่าง = ใช้อีโมจิ)
  description text,
  hp_per_student int not null default 150 check (hp_per_student > 0),   -- เลือดบอส = ค่านี้ × จำนวนนักเรียนในห้อง
  start_date date not null default (date_trunc('week', today_th()))::date,
  days int not null default 7 check (days between 1 and 31),
  reward_exp int not null default 50,
  reward_coins int not null default 30,
  active boolean not null default true
);

do $$
declare t text;
begin
  foreach t in array array['upload_slots','teams','bosses'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists teacher_all on public.%I', t);
    execute format('create policy teacher_all on public.%I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;
alter table bosses add column if not exists image text;
alter table quest_claims add column if not exists dmg int;      -- ความเสียหายต่อบอส (บันทึกตอนอนุมัติ รวมโบนัสพลังโจมตี)
alter table bosses alter column hp_per_student set default 150;
create index if not exists idx_quest_claims_day on quest_claims(claim_date, status);
create index if not exists idx_students_team on students(team_id);

-- ---------------------------------------------------------------------
-- ข้อ 1: รางวัลทันทีหลังเช็คชื่อ
-- ---------------------------------------------------------------------
create or replace function trg_attendance() returns trigger
language plpgsql security definer set search_path = public as $$
declare v uuid;
begin
  if new.status = 'present' then
    perform award(new.student_id, 5, 2, 'มาเรียนตรงเวลา ' || new.att_date, 'att:' || new.id);
  elsif new.status = 'late' then
    if student_class(new.student_id) = 'guardian' then
      perform award(new.student_id, 5, 2, 'มาเรียน (สาย — ผู้พิทักษ์ได้เต็ม) ' || new.att_date, 'att:' || new.id);
    else
      perform award(new.student_id, 2, 1, 'มาเรียน (สาย) ' || new.att_date, 'att:' || new.id);
    end if;
  end if;

  if new.status in ('present', 'late') and new.att_date >= today_th() - 3 then
    -- ตั๋วสุ่มกาชาฟรี 1 ใบต่อการเข้าเรียนหนึ่งครั้ง (กันซ้ำด้วย ledger)
    v := null;
    insert into ledger (student_id, exp, coins, reason, ref_key)
    values (new.student_id, 0, 0, 'ตั๋วสุ่มกาชาฟรี (เช็คชื่อ ' || new.att_date || ')', 'attticket:' || new.id)
    on conflict (student_id, ref_key) do nothing returning id into v;
    if v is not null then update students set free_pulls = free_pulls + 1 where id = new.student_id; end if;

    -- เควสที่ตั้งเป็น “สำเร็จอัตโนมัติเมื่อเช็คชื่อ”
    perform _auto_quests(new.student_id, 'attendance', new.att_date);
  end if;
  perform check_achievements(new.student_id);
  return new;
end $$;

create or replace function trg_submission() returns trigger
language plpgsql security definer set search_path = public as $$
declare a ch_assignments%rowtype; ref text;
begin
  select * into a from ch_assignments where id = new.assignment_id;
  ref := 'sub:' || new.id || case when new.attempt > 1 then ':' || new.attempt else '' end;
  if new.status = 'submitted' then
    perform award(new.student_id, a.exp_reward, a.coin_reward, 'ส่งงาน: ' || a.title, ref);
  elsif new.status = 'late' then
    if student_class(new.student_id) = 'guardian' then
      perform award(new.student_id, a.exp_reward, a.coin_reward, 'ส่งงาน (ช้า — ผู้พิทักษ์ได้เต็ม): ' || a.title, ref);
    else
      perform award(new.student_id, a.exp_reward / 2, a.coin_reward / 2, 'ส่งงาน (ช้า): ' || a.title, ref);
    end if;
  end if;
  if new.status in ('submitted', 'late') then perform _auto_quests(new.student_id, 'submit'); end if;
  perform check_achievements(new.student_id);
  return new;
end $$;

-- กาชา: ถ้ามีตั๋วฟรี สุ่ม ×1 จะใช้ตั๋วก่อน (ไม่เสียเหรียญ)
create or replace function gacha_pull(p_token uuid, p_n int default 1) returns json
language plpgsql security definer set search_path = public as $$
declare
  sid uuid := _sid(p_token); s students%rowtype;
  unit int := coalesce((select value::int from app_settings where key = 'gacha_cost'), 30);
  pity_max int := coalesce((select value::int from app_settings where key = 'pity_max'), 10);
  cost int; i int; it gacha_items%rowtype; high boolean; res jsonb := '[]'::jsonb; refund int := 0; free boolean := false;
begin
  if student_class(sid) = 'seeker' then pity_max := greatest(3, pity_max - 2); end if;
  if p_n not in (1, 10) then raise exception 'จำนวนครั้งไม่ถูกต้อง'; end if;
  select * into s from students where id = sid for update;
  if p_n = 1 and s.free_pulls > 0 then
    free := true; cost := 0;
    update students set free_pulls = free_pulls - 1 where id = sid;
  else
    cost := unit * p_n;
    if s.coins < cost then raise exception 'เหรียญไม่พอ (ต้องใช้ % เหรียญ)', cost; end if;
    update students set coins = coins - cost where id = sid;
  end if;
  for i in 1..p_n loop
    select * into s from students where id = sid;
    high := s.gacha_pity + 1 >= pity_max;
    it := _gacha_pick_luk(high, coalesce((_stats(sid)->'luk'->>'total')::int, 0));
    if it.rarity in ('SR','SSR') then
      update students set gacha_pity = 0 where id = sid;
    else
      update students set gacha_pity = gacha_pity + 1 where id = sid;
    end if;
    insert into gacha_pulls (student_id, item_id, cost) values (sid, it.id, case when free then 0 else unit end);
    if it.kind = 'coins' then
      perform award(sid, 0, it.value, 'กาชา: ' || it.name, null);
    elsif it.kind = 'exp' then
      perform award(sid, it.value, 0, 'กาชา: ' || it.name, null);
    elsif it.kind = 'cosmetic' then
      insert into inventory (student_id, item_id) values (sid, it.id)
      on conflict (student_id, item_id) do update set qty = inventory.qty + 1;
    elsif it.kind = 'privilege' and it.privilege_id is not null then
      insert into redemptions (student_id, privilege_id, source) values (sid, it.privilege_id, 'gacha');
    elsif it.kind = 'decor' and it.decor_id is not null then
      if exists (select 1 from student_decor where student_id = sid and item_id = it.decor_id) then
        refund := case it.rarity when 'SSR' then 40 when 'SR' then 20 when 'R' then 10 else 5 end;
        perform award(sid, 0, refund, 'ไอเทมตกแต่งซ้ำ: ' || it.name, null);
      else
        insert into student_decor (student_id, item_id, source) values (sid, it.decor_id, 'gacha');
        refund := 0;
      end if;
    end if;
    res := res || jsonb_build_object('name', it.name, 'rarity', it.rarity, 'kind', it.kind,
                                     'value', it.value, 'emoji', it.emoji, 'image', it.image_url,
                                     'dup_refund', case when it.kind = 'decor' then refund else 0 end);
  end loop;
  perform check_achievements(sid);
  select * into s from students where id = sid;
  return json_build_object('items', res, 'coins', s.coins, 'exp', s.exp, 'pity', s.gacha_pity, 'used_free', free, 'free_pulls', s.free_pulls);
end $$;

-- ---------------------------------------------------------------------
-- ข้อ 7: ส่งงานออนไลน์ / ถ่ายรูป
-- ---------------------------------------------------------------------
create or replace function _slot_ok(p_name text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from upload_slots where (id::text || '.jpg') = p_name and not used and expires_at > now())
$$;
revoke execute on function _slot_ok(text) from public;
grant execute on function _slot_ok(text) to anon, authenticated;

create or replace function begin_upload(p_token uuid, p_assignment uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); a ch_assignments%rowtype; v uuid;
begin
  select a2.* into a from ch_assignments a2 join students s on s.class_id = a2.class_id
   where a2.id = p_assignment and s.id = sid;
  if not found then raise exception 'ไม่พบงานนี้'; end if;
  if a.submit_mode <> 'photo' then raise exception 'งานนี้ไม่ต้องอัปโหลดรูป'; end if;
  delete from upload_slots where expires_at < now() - interval '1 day';
  insert into upload_slots (student_id, assignment_id) values (sid, a.id) returning id into v;
  return v;
end $$;

create or replace function submit_assignment(p_token uuid, p_assignment uuid, p_slot uuid default null) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); a ch_assignments%rowtype; ex ch_submissions%rowtype; st text; path text;
begin
  select a2.* into a from ch_assignments a2 join students s on s.class_id = a2.class_id
   where a2.id = p_assignment and s.id = sid;
  if not found then raise exception 'ไม่พบงานนี้'; end if;
  if a.submit_mode = 'teacher' then raise exception 'งานนี้ครูเป็นผู้บันทึกการส่ง'; end if;
  st := case when a.due_date is not null and today_th() > a.due_date then 'late' else 'submitted' end;

  select * into ex from ch_submissions where assignment_id = a.id and student_id = sid;
  if found and ex.status in ('submitted', 'late') then raise exception 'ส่งงานนี้แล้ว'; end if;

  if a.submit_mode = 'photo' then
    if p_slot is null then raise exception 'กรุณาแนบรูปงาน'; end if;
    perform 1 from upload_slots where id = p_slot and student_id = sid and assignment_id = a.id and not used and expires_at > now();
    if not found then raise exception 'ช่องอัปโหลดหมดอายุ ลองใหม่อีกครั้ง'; end if;
    path := p_slot::text || '.jpg';
    if not exists (select 1 from storage.objects where bucket_id = 'submissions' and name = path) then
      raise exception 'ยังไม่พบรูปที่อัปโหลด ลองใหม่อีกครั้ง';
    end if;
    update upload_slots set used = true where id = p_slot;
  end if;

  insert into ch_submissions (assignment_id, student_id, status, image_path, via, note)
  values (a.id, sid, st, path, 'student', null)
  on conflict (assignment_id, student_id)
    do update set status = excluded.status, image_path = excluded.image_path, via = 'student', note = null, submitted_at = now();
  return json_build_object('status', st, 'exp', case when st = 'late' then a.exp_reward / 2 else a.exp_reward end);
end $$;

-- ครูส่งคืนงาน (ไม่ผ่าน): หัก EXP/เหรียญที่ให้ไปคืน แล้วให้นักเรียนส่งใหม่ได้
create or replace function admin_return_submission(p_sub uuid, p_note text default null) returns void
language plpgsql security definer set search_path = public as $$
declare s ch_submissions%rowtype; ref text; l ledger%rowtype; a ch_assignments%rowtype;
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  select * into s from ch_submissions where id = p_sub;
  if not found then raise exception 'ไม่พบการส่งงาน'; end if;
  select * into a from ch_assignments where id = s.assignment_id;
  ref := 'sub:' || s.id || case when s.attempt > 1 then ':' || s.attempt else '' end;
  select * into l from ledger where student_id = s.student_id and ref_key = ref;
  if found and (l.exp <> 0 or l.coins <> 0) then
    perform award(s.student_id, -l.exp, -l.coins, 'ครูส่งคืนงาน: ' || a.title, 'subret:' || s.id || ':' || s.attempt);
  end if;
  update ch_submissions set status = 'missing', note = coalesce(nullif(p_note, ''), 'ครูส่งคืนให้แก้ไข'), attempt = attempt + 1, score = null where id = s.id;
end $$;

-- ที่เก็บรูป (Supabase Storage): ส่วนตัว, ไฟล์ละไม่เกิน 1.5MB, เฉพาะ JPEG · นักเรียนอัปโหลดได้เฉพาะช่องที่ระบบเปิดให้ · ครูอ่าน/ลบได้
do $$
begin
  if to_regclass('storage.buckets') is not null then
    insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
    values ('submissions', 'submissions', false, 1572864, array['image/jpeg'])
    on conflict (id) do update set public = false, file_size_limit = 1572864, allowed_mime_types = array['image/jpeg'];
    drop policy if exists chem_sub_upload on storage.objects;
    create policy chem_sub_upload on storage.objects for insert to anon, authenticated
      with check (bucket_id = 'submissions' and public._slot_ok(name));
    drop policy if exists chem_sub_teacher on storage.objects;
    create policy chem_sub_teacher on storage.objects for all to authenticated
      using (bucket_id = 'submissions' and public.is_teacher()) with check (bucket_id = 'submissions' and public.is_teacher());
  end if;
exception when others then
  raise notice 'ตั้งค่า Storage ไม่สำเร็จ (%): ไปสร้าง bucket ชื่อ submissions แบบ Private ใน Storage เอง แล้วดูวิธีใน README', sqlerrm;
end $$;

-- ---------------------------------------------------------------------
-- เควสที่ระบบเช็คให้อัตโนมัติ: ตั้งที่แท็บเควส คอลัมน์ “อัตโนมัติ” (ทำเงื่อนไขเมื่อไหร่ ระบบให้รางวัลทันที ไม่ต้องกดขอและไม่ต้องรอครู)
--   attendance=ครูเช็คชื่อว่ามา · login=เข้าสู่ระบบวันนี้ · quiz=ทำควิซประจำวัน · quiz_perfect=ควิซถูกทุกข้อ
--   match=เล่นเกมจับคู่ธาตุ · submit=ส่งงาน 1 ชิ้น · gacha=สุ่มกาชา · decorate=เปลี่ยนชุด/ไอเทมตกแต่งตัวละคร
-- ---------------------------------------------------------------------
create or replace function _auto_quests(p_sid uuid, p_trigger text, p_date date default null) returns void
language plpgsql security definer set search_path = public as $$
declare cls uuid; q record; d date := coalesce(p_date, today_th());
begin
  select class_id into cls from students where id = p_sid;
  for q in select * from quests where active and auto_trigger = p_trigger and (class_id is null or class_id = cls) loop
    insert into quest_claims (quest_id, student_id, claim_date, status)
    values (q.id, p_sid, quest_period(q.kind, d), 'approved')
    on conflict (quest_id, student_id, claim_date) do nothing;
  end loop;
end $$;

create or replace function trg_auto_game() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.game = 'quiz' then
    perform _auto_quests(new.student_id, 'quiz', new.play_date);
    if new.score >= 100 then perform _auto_quests(new.student_id, 'quiz_perfect', new.play_date); end if;
  else
    perform _auto_quests(new.student_id, 'match', new.play_date);
  end if;
  return new;
end $$;
drop trigger if exists auto_game on game_plays;
create trigger auto_game after insert on game_plays for each row execute function trg_auto_game();

create or replace function trg_auto_login() returns trigger
language plpgsql security definer set search_path = public as $$
begin perform _auto_quests(new.id, 'login'); return new; end $$;
drop trigger if exists auto_login on students;
create trigger auto_login after update of last_login on students
  for each row when (new.last_login is distinct from old.last_login) execute function trg_auto_login();

create or replace function trg_auto_decor() returns trigger
language plpgsql security definer set search_path = public as $$
begin perform _auto_quests(new.id, 'decorate'); return new; end $$;
drop trigger if exists auto_decor on students;
create trigger auto_decor after update of decor on students
  for each row when (new.decor is distinct from old.decor and new.decor <> '{}'::jsonb) execute function trg_auto_decor();

create or replace function trg_auto_gacha() returns trigger
language plpgsql security definer set search_path = public as $$
begin perform _auto_quests(new.student_id, 'gacha'); return new; end $$;
drop trigger if exists auto_gacha on gacha_pulls;
create trigger auto_gacha after insert on gacha_pulls for each row execute function trg_auto_gacha();

-- เควสอัตโนมัติ: แสดงในรายการเสมอ (ไม่นับโควตาสุ่มรายวัน) แต่นักเรียนกดเองไม่ได้ (กันกดโดยไม่ได้มาเรียน)
create or replace function todays_quests(p_class uuid, p_date date)
returns setof quests language sql stable security definer set search_path = public as $$
  (select * from quests
    where active and auto_trigger is null and kind = 'daily' and (class_id is null or class_id = p_class)
    order by md5(id::text || p_date::text)
    limit coalesce((select value::int from app_settings where key = 'daily_quest_count'), 3))
  union all
  (select * from quests
    where active and auto_trigger is null and kind = 'weekly' and (class_id is null or class_id = p_class))
  union all
  (select * from quests
    where active and auto_trigger is not null and (class_id is null or class_id = p_class))
$$;

create or replace function claim_quest(p_token uuid, p_quest uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); s students%rowtype; q quests%rowtype; st text; per date;
begin
  select * into s from students where id = sid;
  select * into q from todays_quests(s.class_id, today_th()) t where t.id = p_quest;
  if not found then raise exception 'เควสนี้ไม่ได้เปิดให้ทำวันนี้'; end if;
  if q.auto_trigger is not null then raise exception 'เควสนี้ระบบเช็คให้อัตโนมัติ ไม่ต้องกดเอง'; end if;
  per := quest_period(q.kind, today_th());
  st := case when q.needs_approval then 'pending' else 'approved' end;
  begin
    insert into quest_claims (quest_id, student_id, claim_date, status) values (q.id, sid, per, st);
  exception when unique_violation then
    raise exception 'ทำเควสนี้ไปแล้ว';
  end;
  return json_build_object('status', st);
end $$;

-- ---------------------------------------------------------------------
-- ข้อ 3: ทีม / ห้องแข่ง EXP (นับจาก EXP ที่ได้ “สัปดาห์นี้” จากสมุดบัญชี)
-- ---------------------------------------------------------------------
create or replace function team_board(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); s students%rowtype; wk date := date_trunc('week', today_th())::date; r json;
begin
  select * into s from students where id = sid;
  select json_build_object(
    'week_start', wk,
    'my_team', s.team_id,
    'teams', (select coalesce(json_agg(t order by t.avg_week desc, t.exp_week desc, t.name), '[]'::json) from (
        select tm.id, tm.name, tm.emoji, (tm.id = s.team_id) as mine,
               count(st.id)::int as members,
               coalesce(sum(w.x), 0)::int as exp_week,
               case when count(st.id) = 0 then 0 else round(coalesce(sum(w.x), 0)::numeric / count(st.id), 1) end as avg_week,
               (select coalesce(json_agg(json_build_object('name', m.name, 'exp_week', coalesce(mw.x, 0), 'me', m.id = sid)
                        order by coalesce(mw.x, 0) desc, m.no), '[]'::json)
                  from students m
                  left join lateral (select sum(l.exp)::int as x from ledger l
                       where l.student_id = m.id and (l.created_at at time zone 'Asia/Bangkok')::date >= wk) mw on true
                 where m.team_id = tm.id and tm.id = s.team_id) as roster
          from teams tm
          left join students st on st.team_id = tm.id
          left join lateral (select sum(l.exp) as x from ledger l
               where l.student_id = st.id and (l.created_at at time zone 'Asia/Bangkok')::date >= wk) w on true
         where tm.class_id = s.class_id
         group by tm.id, tm.name, tm.emoji
    ) t),
    'rooms', (select coalesce(json_agg(x order by x.avg_week desc), '[]'::json) from (
        select c.name, (c.id = s.class_id) as mine, count(st.id)::int as students,
               case when count(st.id) = 0 then 0 else round(coalesce(sum(w.x), 0)::numeric / count(st.id), 1) end as avg_week
          from classes c
          left join students st on st.class_id = c.id
          left join lateral (select sum(l.exp) as x from ledger l
               where l.student_id = st.id and (l.created_at at time zone 'Asia/Bangkok')::date >= wk) w on true
         group by c.id, c.name
        having count(st.id) > 0
    ) x)
  ) into r;
  return r;
end $$;

-- ครู: สุ่มแบ่งทีมทั้งห้อง (ลบทีมเดิมของห้อง)
create or replace function admin_random_teams(p_class uuid, p_n int) returns int
language plpgsql security definer set search_path = public as $$
declare
  names text[] := array['ไฮโดรเจน','ฮีเลียม','ลิเทียม','คาร์บอน','ไนโตรเจน','ออกซิเจน','นีออน','โซเดียม','แมกนีเซียม','ทองคำ','เงิน','ทองแดง'];
  emos text[] := array['💧','🎈','🔋','💎','🌫️','🫧','💡','🧂','✨','🥇','🥈','🥉'];
  ids uuid[] := '{}'; tid uuid; i int := 0; sid uuid;
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  if p_n < 2 or p_n > 12 then raise exception 'จำนวนทีมต้องอยู่ระหว่าง 2–12'; end if;
  update students set team_id = null where class_id = p_class;
  delete from teams where class_id = p_class;
  for i in 1..p_n loop
    insert into teams (class_id, name, emoji, sort) values (p_class, 'ทีม' || names[i], emos[i], i) returning id into tid;
    ids := ids || tid;
  end loop;
  i := 0;
  for sid in select id from students where class_id = p_class order by random() loop
    update students set team_id = ids[(i % p_n) + 1] where id = sid;
    i := i + 1;
  end loop;
  return i;
end $$;

-- ---------------------------------------------------------------------
-- ข้อ 4: สรุปรายสัปดาห์สำหรับครู
-- ---------------------------------------------------------------------
create or replace function admin_weekly_digest(p_class uuid, p_days int default 7) returns json
language plpgsql security definer set search_path = public as $$
declare d0 date := today_th() - (greatest(p_days, 1) - 1); today date := today_th(); r json;
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  select json_build_object(
    'from', d0, 'to', today, 'days', p_days,
    'students', (select count(*) from students where class_id = p_class),
    'attendance', (select json_build_object(
        'days_marked', count(distinct att_date),
        'present', count(*) filter (where status = 'present'), 'late', count(*) filter (where status = 'late'),
        'absent', count(*) filter (where status = 'absent'), 'leave', count(*) filter (where status = 'leave'))
        from ch_attendance where class_id = p_class and att_date between d0 and today),
    'absent', (select coalesce(json_agg(x order by x.absent_week desc, x.no), '[]'::json) from (
        select s.no, s.name,
               count(*) filter (where a.att_date between d0 and today and a.status = 'absent')::int as absent_week,
               count(*) filter (where a.att_date >= today - 29 and a.status = 'absent')::int as absent_30,
               count(*) filter (where a.att_date >= today - 29 and a.status = 'late')::int as late_30
          from students s left join ch_attendance a on a.student_id = s.id
         where s.class_id = p_class group by s.id, s.no, s.name
        having count(*) filter (where a.att_date between d0 and today and a.status = 'absent') > 0
            or count(*) filter (where a.att_date >= today - 29 and a.status = 'absent') >= 3
    ) x),
    'missing', (select coalesce(json_agg(x order by x.missing desc, x.no), '[]'::json) from (
        select s.no, s.name, count(*)::int as missing, json_agg(a.title order by a.due_date) as titles
          from students s
          join ch_assignments a on a.class_id = s.class_id and a.due_date is not null and a.due_date < today
          left join ch_submissions sb on sb.assignment_id = a.id and sb.student_id = s.id and sb.status in ('submitted','late')
         where s.class_id = p_class and sb.id is null
         group by s.id, s.no, s.name
    ) x),
    'inactive', (select coalesce(json_agg(x order by x.last_login nulls first, x.no), '[]'::json) from (
        select no, name, last_login from students
         where class_id = p_class and (last_login is null or last_login < now() - make_interval(days => p_days))
    ) x),
    'top', (select coalesce(json_agg(x order by x.exp_week desc), '[]'::json) from (
        select s.no, s.name, sum(l.exp)::int as exp_week
          from ledger l join students s on s.id = l.student_id
         where s.class_id = p_class and (l.created_at at time zone 'Asia/Bangkok')::date between d0 and today
         group by s.id, s.no, s.name order by sum(l.exp) desc limit 5
    ) x),
    'exp_total', (select coalesce(sum(l.exp), 0)::int from ledger l join students s on s.id = l.student_id
                   where s.class_id = p_class and (l.created_at at time zone 'Asia/Bangkok')::date between d0 and today)
  ) into r;
  return r;
end $$;

-- ---------------------------------------------------------------------
-- ข้อ 5: ควิซตามบทเรียน — ข้อของบทที่ห้องกำลังเรียนมาก่อน, ข้อเฉพาะห้องมาถัดไป, แล้วเติมด้วยข้อทั่วไป
-- ---------------------------------------------------------------------
create or replace function _quiz_ids(p_sid uuid, p_date date) returns uuid[]
language sql stable security definer set search_path = public as $$
  select coalesce(array_agg(id order by pri, k), '{}') from (
    select q.id, md5(q.id::text || p_sid::text || p_date::text) as k,
           case when c.quiz_topic is not null and q.topic = c.quiz_topic then 0
                when q.class_id is not null then 1 else 2 end as pri
      from quiz_questions q
      join students s on s.id = p_sid
      join classes c on c.id = s.class_id
     where q.active and (q.class_id is null or q.class_id = s.class_id)
     order by pri, k
     limit _setting_int('quiz_count', 5)
  ) z
$$;

-- ---------------------------------------------------------------------
-- ข้อ 8: บอสประจำสัปดาห์ — ความเสียหาย = EXP ของเควสที่ได้รับอนุมัติในช่วงของบอส (ทั้งห้องรวมกัน)
-- ---------------------------------------------------------------------
create or replace function _boss_for(p_class uuid) returns bosses
language sql stable security definer set search_path = public as $$
  select * from bosses
   where active and (class_id is null or class_id = p_class)
     and today_th() between start_date and start_date + days - 1 + 7        -- แสดงต่ออีก 7 วันหลังหมดเวลา เพื่อรับรางวัล
   order by (class_id is null), start_date desc limit 1
$$;

create or replace function _boss_damage(p_boss bosses, p_class uuid, p_student uuid default null) returns int
language sql stable security definer set search_path = public as $$
  select coalesce(sum(coalesce(cl.dmg, greatest(q.exp, 1))), 0)::int
    from quest_claims cl
    join quests q on q.id = cl.quest_id
    join students st on st.id = cl.student_id
   where st.class_id = p_class and cl.status = 'approved'
     and cl.claim_date between p_boss.start_date and p_boss.start_date + p_boss.days - 1
     and (p_student is null or cl.student_id = p_student)
$$;

create or replace function boss_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cls uuid; b bosses%rowtype; n int; mx int; dmg int; mine int; end_d date; done boolean; claimed boolean;
begin
  select class_id into cls from students where id = sid;
  b := _boss_for(cls);
  if b.id is null then return null; end if;
  select count(*) into n from students where class_id = cls;
  mx := b.hp_per_student * greatest(n, 1);
  dmg := _boss_damage(b, cls);
  mine := _boss_damage(b, cls, sid);
  end_d := b.start_date + b.days - 1;
  done := dmg >= mx;
  claimed := exists (select 1 from ledger where student_id = sid and ref_key = 'boss:' || b.id);
  return json_build_object(
    'id', b.id, 'name', b.name, 'emoji', b.emoji, 'image', b.image, 'description', b.description,
    'max_hp', mx, 'damage', least(dmg, mx), 'hp', greatest(mx - dmg, 0), 'defeated', done,
    'my_damage', mine, 'start', b.start_date, 'end', end_d, 'ended', today_th() > end_d,
    'days_left', greatest(end_d - today_th() + 1, 0),
    'reward_exp', b.reward_exp, 'reward_coins', b.reward_coins,
    'claimed', claimed, 'can_claim', done and mine > 0 and not claimed,
    'top', (select coalesce(json_agg(x), '[]'::json) from (
        select st.name, sum(coalesce(cl.dmg, greatest(q.exp, 1)))::int as dmg, (st.id = sid) as me
          from quest_claims cl join quests q on q.id = cl.quest_id join students st on st.id = cl.student_id
         where st.class_id = cls and cl.status = 'approved'
           and cl.claim_date between b.start_date and end_d
         group by st.id, st.name order by sum(coalesce(cl.dmg, greatest(q.exp, 1))) desc limit 5) x));
end $$;

create or replace function boss_claim(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cls uuid; b bosses%rowtype; n int; ok boolean;
begin
  select class_id into cls from students where id = sid;
  b := _boss_for(cls);
  if b.id is null then raise exception 'ไม่มีบอสในตอนนี้'; end if;
  select count(*) into n from students where class_id = cls;
  if _boss_damage(b, cls) < b.hp_per_student * greatest(n, 1) then raise exception 'ยังปราบบอสไม่สำเร็จ'; end if;
  if _boss_damage(b, cls, sid) <= 0 then raise exception 'ต้องช่วยทำเควสอย่างน้อย 1 ครั้งจึงจะรับรางวัลได้'; end if;
  ok := award(sid, b.reward_exp, b.reward_coins, 'ปราบบอส: ' || b.name, 'boss:' || b.id);
  if not ok then raise exception 'รับรางวัลไปแล้ว'; end if;
  perform check_achievements(sid);
  return json_build_object('exp', b.reward_exp, 'coins', b.reward_coins);
end $$;

-- ---------------------------------------------------------------------
-- ข้อมูลเสริมสำหรับหน้านักเรียน (เรียกครั้งเดียวตอนโหลด)
-- ---------------------------------------------------------------------
create or replace function student_extras(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); s students%rowtype;
begin
  select * into s from students where id = sid;
  return json_build_object(
    'free_pulls', s.free_pulls,
    'submit', (select coalesce(json_object_agg(a.id, json_build_object('mode', a.submit_mode, 'note', sb.note,
                 'has_image', sb.image_path is not null, 'via', sb.via)), '{}'::json)
                 from ch_assignments a left join ch_submissions sb on sb.assignment_id = a.id and sb.student_id = sid
                where a.class_id = s.class_id),
    'stats', _stats(sid),
    'stats_abilities', (select coalesce(json_agg(a), '[]'::json) from (select d.name || ' — ' || (to_jsonb(d)->>'ability') as a
        from students sx cross join lateral jsonb_each_text(sx.decor) e join decor_items d on d.id = e.value::uuid and d.slot = e.key
       where sx.id = sid and coalesce(to_jsonb(d)->>'ability', '') <> '') z),
    'item_stats', (select coalesce(json_object_agg(d.id, json_build_object('int', d.st_int, 'dil', d.st_dil, 'str', d.st_str, 'luk', d.st_luk, 'coin', to_jsonb(d)->>'st_coin', 'ability', to_jsonb(d)->>'ability')), '{}'::json)
                     from decor_items d where d.active and (d.st_int + d.st_dil + d.st_str + d.st_luk > 0 or coalesce((to_jsonb(d)->>'st_coin')::int, 0) > 0)),
    'auto', (select coalesce(json_object_agg(q.id, q.auto_trigger), '{}'::json) from todays_quests(s.class_id, today_th()) q where q.auto_trigger is not null),
    'teams', team_board(p_token),
    'boss', boss_status(p_token));
end $$;

revoke execute on function _boss_for(uuid) from public, anon, authenticated;
revoke execute on function _boss_damage(bosses, uuid, uuid) from public, anon, authenticated;
revoke execute on function trg_attendance() from public, anon, authenticated;
revoke execute on function trg_submission() from public, anon, authenticated;
revoke execute on function gacha_pull(uuid, int) from public;
revoke execute on function begin_upload(uuid, uuid) from public;
revoke execute on function submit_assignment(uuid, uuid, uuid) from public;
revoke execute on function team_board(uuid) from public;
revoke execute on function boss_status(uuid) from public;
revoke execute on function boss_claim(uuid) from public;
revoke execute on function student_extras(uuid) from public;
revoke execute on function admin_return_submission(uuid, text) from public, anon;
revoke execute on function admin_random_teams(uuid, int) from public, anon;
revoke execute on function admin_weekly_digest(uuid, int) from public, anon;
revoke execute on function _auto_quests(uuid, text, date) from public, anon, authenticated;
grant execute on function gacha_pull(uuid, int), begin_upload(uuid, uuid), submit_assignment(uuid, uuid, uuid), team_board(uuid),
  boss_status(uuid), boss_claim(uuid), student_extras(uuid) to anon, authenticated;
grant execute on function admin_return_submission(uuid, text), admin_random_teams(uuid, int), admin_weekly_digest(uuid, int) to authenticated;

-- ---------------------------------------------------------------------
-- ตัวอย่างเริ่มต้น (ใส่เฉพาะตอนยังไม่มี)
-- ---------------------------------------------------------------------
do $$
begin
  -- บอสหมุนเวียนรายสัปดาห์ 6 ตัว (เพิ่มเฉพาะชื่อที่ยังไม่มี · เริ่มสัปดาห์นี้ ตัวถัดไปทุกวันจันทร์ · ครูแก้/ปิด/เพิ่มได้ที่แท็บบอส)
  insert into bosses (name, emoji, image, description, hp_per_student, start_date, reward_exp, reward_coins)
  select v.n, v.e, 'assets/bosses/' || v.i || '.png', v.d, 150, (date_trunc('week', today_th()))::date + 7 * v.w, 50, 30
    from (values
      (0, 'มังกรกรดซัลฟิวริก', '🐲', 'acid_dragon', 'มังกรพ่นกรดที่ขดตัวรอบขวดทดลอง! ทุกเควสที่ทำสำเร็จคือการโจมตี ช่วยกันทั้งห้องก่อนหมดสัปดาห์'),
      (1, 'โกเลมบีกเกอร์พิษ', '🧪', 'beaker_golem', 'หุ่นแก้วบรรจุของเหลวสีม่วงเดือดพล่าน ใครทำเควสเยอะ ยิ่งแตกเร็ว'),
      (2, 'จอมเวทอิเล็กตรอน', '⚡', 'electron_wizard', 'ผู้ควบคุมอะตอมและสายฟ้า วงโคจรของมันป้องกันได้แค่คนที่ไม่ขยัน'),
      (3, 'หุ่นยนต์ธาตุจักรกล', '🤖', 'element_robot', 'เกราะทำจากแผ่นธาตุในตารางธาตุ ต้องใช้ความรู้เคมีจึงจะพังได้'),
      (4, 'ปีศาจตะเกียงเพลิง', '🔥', 'flame_demon', 'วิญญาณเปลวไฟจากตะเกียงแอลกอฮอล์ ดับมันด้วยการสะสมเควสให้ครบ'),
      (5, 'ไฮดราเชื้อโรคแปดตา', '🦠', 'germ_hydra', 'เชื้อโรคจอมแพร่พันธุ์ที่มีกล้องจุลทรรศน์เป็นตา ต้องช่วยกันทั้งห้องถึงจะปราบได้')
    ) v(w, n, e, i, d)
   where not exists (select 1 from bosses b where b.name = v.n);
  update bosses set image = 'assets/bosses/acid_dragon.png' where name = 'มังกรกรดซัลฟิวริก' and image is null;
  -- เควสประจำวันที่ระบบเช็คให้เอง (เพิ่มเฉพาะที่ยังไม่มีเงื่อนไขนั้น ครูแก้/ปิดได้ที่แท็บเควส)
  insert into quests (class_id, title, description, kind, exp, coins, needs_approval, auto_trigger)
  select null, v.t, v.d, 'daily', v.e, v.c, false, v.a from (values
    ('attendance', 'มาเรียนวันนี้', 'สำเร็จอัตโนมัติเมื่อครูเช็คชื่อว่ามา', 3, 1),
    ('login', 'เข้าห้องแล็บวันนี้', 'เข้าสู่ระบบ Chemistria วันนี้', 2, 1),
    ('quiz', 'ทำควิซประจำวัน', 'ทำควิซประจำวันให้ครบ (ไปที่แท็บเกม)', 3, 1),
    ('quiz_perfect', 'ควิซเต็ม!', 'ตอบควิซประจำวันถูกทุกข้อ', 5, 2),
    ('match', 'จับคู่ธาตุ', 'เล่นเกมจับคู่ธาตุ 1 รอบ', 3, 1),
    ('submit', 'ส่งงานวันนี้', 'ส่งงาน 1 ชิ้นในวันนี้ (ออนไลน์/ส่งรูป หรือครูบันทึกให้)', 5, 2),
    ('gacha', 'ลองดวงกาชา', 'สุ่มกาชา 1 ครั้ง (ใช้ตั๋วฟรีได้)', 2, 1),
    ('decorate', 'แต่งตัวละคร', 'เปลี่ยนชุด/เอฟเฟค/ไอเทมของตัวละคร', 2, 1)
  ) v(a, t, d, e, c)
  where not exists (select 1 from quests q where q.auto_trigger = v.a);
  update bosses set hp_per_student = 150 where name = 'มังกรกรดซัลฟิวริก' and hp_per_student = 60;
end $$;
