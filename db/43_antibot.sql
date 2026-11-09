-- 43: ป้องกันสคริปต์/บอท/AI ช่วยเจาะเกม
--  1) ล็อก PIN แบบทวีคูณ  2) จำกัดจำนวนคำสั่งต่อนาทีต่อเซสชัน  3) เกมต้อง "เริ่มเล่น" ที่เซิร์ฟเวอร์ก่อนส่งคะแนน และเวลาต้องสมเหตุสมผล
alter table students add column if not exists lock_level int not null default 0;
alter table student_sessions add column if not exists win_start timestamptz;
alter table student_sessions add column if not exists win_n int not null default 0;

-- ครูเปลี่ยน PIN ใหม่ → ปลดล็อกและรีเซ็ตระดับการล็อกอัตโนมัติ
create or replace function _trg_pin_reset() returns trigger language plpgsql as $$
begin
  if new.pin_hash is distinct from old.pin_hash then new.lock_level := 0; new.fail_count := 0; new.locked_until := null; end if;
  return new;
end $$;
drop trigger if exists students_pin_reset on students;
create trigger students_pin_reset before update of pin_hash on students for each row execute function _trg_pin_reset();

-- ล็อกอินนักเรียน (รอบ 2): ล็อกแบบทวีคูณ 10 นาที → 30 นาที → 90 นาที … สูงสุด 24 ชม. กันเดา PIN 4 หลักด้วยสคริปต์
create or replace function student_login(p_class_code text, p_no int, p_pin text)
returns json language plpgsql security definer set search_path = public, extensions as $$
declare s students%rowtype; t uuid; v_ip text := _req_ip(); acct text; nfail int; naccts int;
        lim int := _setting_int('sec_ip_limit', 60); sweep int := _setting_int('sec_sweep_accts', 20);
        bucket text := to_char(date_trunc('hour', now()) + floor(extract(minute from now())/10) * interval '10 minutes', 'HH24MI');
begin
  if coalesce((select value from app_settings where key = 'sec_lockdown'), '0') = '1' then
    raise exception 'ระบบนักเรียนปิดชั่วคราว (ครูกำลังตรวจสอบความปลอดภัย)';
  end if;
  if v_ip is not null and (select count(*) from login_attempts la where la.ip = v_ip and la.at > now() - interval '10 minutes') >= lim then
    raise exception 'พยายามเข้าสู่ระบบผิดมากเกินไป กรุณารอ 10 นาทีแล้วลองใหม่';
  end if;
  acct := upper(trim(coalesce(p_class_code,''))) || '#' || coalesce(p_no::text, '?');
  select st.* into s from students st join classes c on c.id = st.class_id
   where upper(c.code) = upper(trim(p_class_code)) and st.no = p_no;
  if not found then
    insert into login_attempts(ip, acct) values (v_ip, acct);
    perform _sec_ip_check(v_ip);
    return json_build_object('error', 'ไม่พบห้องหรือเลขที่นี้');
  end if;
  if s.locked_until is not null and s.locked_until > now() then
    raise exception 'ใส่ PIN ผิดหลายครั้ง กรุณารอสักครู่แล้วลองใหม่';
  end if;
  if s.pin_hash is null or crypt(p_pin, s.pin_hash) <> s.pin_hash then
    update students
       set locked_until = case when fail_count + 1 >= 5 then now() + least(interval '24 hours', interval '10 minutes' * power(3, least(lock_level, 6))::int) else locked_until end,
           lock_level = case when fail_count + 1 >= 5 then lock_level + 1 else lock_level end,
           fail_count = case when fail_count + 1 >= 5 then 0 else fail_count + 1 end
     where id = s.id;
    insert into login_attempts(ip, acct) values (v_ip, acct);
    delete from login_attempts where at < now() - interval '2 days' and id % 50 = 0;
    if s.fail_count + 1 >= 5 then
      perform _sec_log('pin_lock', case when s.lock_level >= 2 then 'high' else 'warn' end, s.id, 'ใส่ PIN ผิดครบ 5 ครั้ง ล็อกรอบที่ ' || (s.lock_level + 1) || ' (นานขึ้นทุกรอบ)', 'pinlock:' || s.id || ':' || to_char(now(), 'YYYYMMDDHH24') || bucket);
    end if;
    perform _sec_ip_check(v_ip);
    return json_build_object('error', 'PIN ไม่ถูกต้อง');
  end if;
  if s.fail_count >= 3 then
    perform _sec_log('login_after_fails', 'warn', s.id, 'เข้าสู่ระบบสำเร็จหลังใส่ PIN ผิด ' || s.fail_count || ' ครั้ง', 'laf:' || s.id || ':' || to_char(now(), 'YYYYMMDDHH24'));
  end if;
  update students set fail_count = 0, locked_until = null, lock_level = 0, last_login = now() where id = s.id;
  insert into student_sessions (student_id) values (s.id) returning token into t;
  delete from student_sessions where student_id = s.id and expires_at < now();
  return json_build_object('token', t, 'name', s.name);
end $$;


-- จำกัดอัตราเรียกคำสั่งต่อนาทีต่อเซสชัน (ค่าเริ่มต้น 240/นาที ปรับที่ app_settings.sec_rpc_per_min)
create or replace function _sid(p_token uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare v uuid; o boolean; fn text; n int; lim int := _setting_int('sec_rpc_per_min', 240);
begin
  update student_sessions
     set win_n = case when win_start is null or win_start < now() - interval '1 minute' then 1 else win_n + 1 end,
         win_start = case when win_start is null or win_start < now() - interval '1 minute' then now() else win_start end
   where token = p_token and expires_at > now()
  returning student_id, observer, win_n into v, o, n;
  if v is null then raise exception 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่'; end if;
  if n > lim then raise exception 'ส่งคำสั่งถี่เกินไป กรุณารอสักครู่'; end if;
  if n = lim then
    perform _sec_log('rate_abuse', 'high', v, 'ส่งคำสั่งถึง ' || lim || ' ครั้งใน 1 นาที (อาจเป็นสคริปต์/บอท)', 'rate:' || v || ':' || to_char(now(), 'YYYYMMDDHH24MI'));
  end if;
  if o then
    fn := regexp_replace(coalesce(current_setting('request.path', true), ''), '^.*/', '');
    if fn not in ('student_dashboard','student_extras','hall_of_fame','board_list','celebrations_feed','game_status','spell_status','kb_status','news_list','run_status','timetable_list','promo_status') then
      raise exception 'โหมดส่องนักเรียน: ดูได้อย่างเดียว';
    end if;
  end if;
  return v;
end $$;

-- เกม: ต้องเรียก game_begin ตอนเริ่มเล่น แล้วเซิร์ฟเวอร์เทียบเวลาจริงกับเวลาที่ส่งคะแนน
create table if not exists game_starts (
  student_id uuid not null references students(id) on delete cascade,
  game text not null,
  started_at timestamptz not null default now(),
  primary key (student_id, game)
);
alter table game_starts enable row level security;
drop policy if exists teacher_all on game_starts;
create policy teacher_all on game_starts for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on game_starts from anon;
grant select, insert, update, delete on game_starts to authenticated;

create or replace function game_begin(p_token uuid, p_game text) returns void
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  if p_game not in ('quiz','match','spell','kb','run') then raise exception 'เกมไม่ถูกต้อง'; end if;
  insert into game_starts(student_id, game, started_at) values (sid, p_game, now())
  on conflict (student_id, game) do update set started_at = excluded.started_at;
end $$;

-- ตรวจเวลา: คืนเมื่อผ่าน (และ "ใช้" การเริ่มเกมครั้งนั้น) / error เมื่อไม่ผ่าน
create or replace function _game_check(p_sid uuid, p_game text, p_floor numeric, p_claimed numeric) returns void
language plpgsql security definer set search_path = public as $$
declare st timestamptz; el numeric; need numeric;
begin
  if coalesce((select value from app_settings where key = 'sec_game_timing'), '1') = '0' then return; end if;
  select started_at into st from game_starts where student_id = p_sid and game = p_game;
  if st is null then raise exception 'ยังไม่ได้เริ่มเกม — กรุณารีเฟรชหน้าแล้วเล่นใหม่'; end if;
  el := extract(epoch from (now() - st));
  need := greatest(p_floor, coalesce(p_claimed, 0) * 0.5 - 2);
  if el < need then raise exception 'ผลการเล่นไม่ถูกต้อง (เวลาเล่นสั้นเกินจริง)'; end if;
  delete from game_starts where student_id = p_sid and game = p_game;
end $$;

-- ห่อฟังก์ชันส่งคะแนนเดิม: เปลี่ยนชื่อเดิมเป็น _xxx (ภายใน) แล้วสร้างตัวห่อชื่อเดิมที่ตรวจเวลาก่อน
do $$ begin
  if not exists (select 1 from pg_proc where proname = '_match_submit' and pronamespace = 'public'::regnamespace) then
    alter function match_submit(uuid, int, int, int) rename to _match_submit; end if;
  if not exists (select 1 from pg_proc where proname = '_spell_submit' and pronamespace = 'public'::regnamespace) then
    alter function spell_submit(uuid, int, int, int) rename to _spell_submit; end if;
  if not exists (select 1 from pg_proc where proname = '_kb_submit' and pronamespace = 'public'::regnamespace) then
    alter function kb_submit(uuid, int, boolean, int) rename to _kb_submit; end if;
  if not exists (select 1 from pg_proc where proname = '_run_submit' and pronamespace = 'public'::regnamespace) then
    alter function run_submit(uuid, int, int) rename to _run_submit; end if;
  if not exists (select 1 from pg_proc where proname = '_quiz_submit' and pronamespace = 'public'::regnamespace) then
    alter function quiz_submit(uuid, jsonb) rename to _quiz_submit; end if;
end $$;

create or replace function match_submit(p_token uuid, p_score int, p_pairs int, p_seconds int) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin perform _game_check(sid, 'match', greatest(6, coalesce(p_pairs, 4) * 1.5), p_seconds); return _match_submit(p_token, p_score, p_pairs, p_seconds); end $$;
create or replace function spell_submit(p_token uuid, p_score int, p_spells int, p_seconds int) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin perform _game_check(sid, 'spell', greatest(6, coalesce(p_spells, 1) * 3), p_seconds); return _spell_submit(p_token, p_score, p_spells, p_seconds); end $$;
create or replace function kb_submit(p_token uuid, p_cleared int, p_won boolean, p_seconds int) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin perform _game_check(sid, 'kb', greatest(6, coalesce(p_cleared, 0) * 2), p_seconds); return _kb_submit(p_token, p_cleared, p_won, p_seconds); end $$;
create or replace function run_submit(p_token uuid, p_score int, p_seconds int) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin perform _game_check(sid, 'run', 5, p_seconds); return _run_submit(p_token, p_score, p_seconds); end $$;
create or replace function quiz_submit(p_token uuid, p_answers jsonb) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin perform _game_check(sid, 'quiz', _setting_int('quiz_min_seconds', 8), 0); return _quiz_submit(p_token, p_answers); end $$;

do $$ declare f text; begin
  foreach f in array array['_match_submit(uuid,int,int,int)','_spell_submit(uuid,int,int,int)','_kb_submit(uuid,int,boolean,int)','_run_submit(uuid,int,int)','_quiz_submit(uuid,jsonb)',
                            '_game_check(uuid,text,numeric,numeric)','_trg_pin_reset()'] loop
    execute format('revoke execute on function %s from public, anon, authenticated', f);
  end loop;
  foreach f in array array['match_submit(uuid,int,int,int)','spell_submit(uuid,int,int,int)','kb_submit(uuid,int,boolean,int)','run_submit(uuid,int,int)','quiz_submit(uuid,jsonb)','game_begin(uuid,text)'] loop
    execute format('revoke execute on function %s from public', f);
    execute format('grant execute on function %s to anon, authenticated', f);
  end loop;
end $$;
