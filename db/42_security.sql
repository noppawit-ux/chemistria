-- 42: ระบบป้องกันและแจ้งเตือนการโจมตี
-- ส่วนประกอบ: บันทึกเหตุ (security_events) · จำกัดการเดา PIN ต่อ IP · สแกนหาช่องโหว่/ข้อมูลผิดปกติ
--            · เตือนเมื่อรายชื่อครูถูกแก้ · ปุ่มปิดระบบนักเรียนฉุกเฉิน (lockdown)
create table if not exists security_events (
  id bigserial primary key,
  at timestamptz not null default now(),
  kind text not null,
  sev text not null default 'warn' check (sev in ('info','warn','high','critical')),
  student_id uuid references students(id) on delete set null,
  ip text,
  detail text,
  dedupe_key text,
  seen boolean not null default false
);
create unique index if not exists security_events_dedupe on security_events(dedupe_key) where dedupe_key is not null;
create index if not exists security_events_at on security_events(at desc);

create table if not exists login_attempts (
  id bigserial primary key,
  at timestamptz not null default now(),
  ip text,
  acct text
);
create index if not exists login_attempts_ip_at on login_attempts(ip, at desc);

do $$ declare t text; begin
  foreach t in array array['security_events','login_attempts'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists teacher_all on public.%I', t);
    execute format('create policy teacher_all on public.%I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;

-- IP ของผู้เรียก (ถ้า PostgREST ส่งมา)
create or replace function _req_ip() returns text language plpgsql stable as $$
begin
  return nullif(trim(split_part(coalesce((current_setting('request.headers', true))::json->>'x-forwarded-for', ''), ',', 1)), '');
exception when others then return null; end $$;

create or replace function _sec_log(p_kind text, p_sev text, p_student uuid, p_detail text, p_key text default null) returns void
language plpgsql security definer set search_path = public as $$
begin
  insert into security_events(kind, sev, student_id, ip, detail, dedupe_key)
  values (p_kind, p_sev, p_student, _req_ip(), p_detail, p_key) on conflict do nothing;
end $$;
revoke execute on function _req_ip() from public, anon, authenticated;
revoke execute on function _sec_log(text, text, uuid, text, text) from public, anon, authenticated;

-- ตรวจพฤติกรรมเดา PIN ต่อ IP แล้วบันทึกเหตุ (เรียกหลังบันทึกความพยายามที่ผิดทุกครั้ง)
create or replace function _sec_ip_check(p_ip text) returns void
language plpgsql security definer set search_path = public as $$
declare nfail int; naccts int; lim int := _setting_int('sec_ip_limit', 60); sweep int := _setting_int('sec_sweep_accts', 20);
        bucket text := to_char(date_trunc('hour', now()) + floor(extract(minute from now())/10) * interval '10 minutes', 'YYYYMMDDHH24MI');
begin
  if p_ip is null then return; end if;
  select count(*), count(distinct a.acct) into nfail, naccts from login_attempts a where a.ip = p_ip and a.at > now() - interval '10 minutes';
  if naccts >= sweep then
    perform _sec_log('ip_sweep', 'high', null, 'เดา PIN หลายบัญชีจาก IP เดียว (' || naccts || ' บัญชี / ' || nfail || ' ครั้งใน 10 นาที)', 'sweep:' || p_ip || ':' || bucket);
  end if;
  if nfail >= lim then
    perform _sec_log('ip_blocked', 'high', null, 'IP นี้ถูกบล็อกชั่วคราว 10 นาที (ผิด ' || nfail || ' ครั้ง)', 'block:' || p_ip || ':' || bucket);
  end if;
end $$;
revoke execute on function _sec_ip_check(text) from public, anon, authenticated;

-- ล็อกอินนักเรียน: เพิ่มโหมดฉุกเฉิน · จำกัดต่อ IP · บันทึกเหตุผิดปกติ
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
       set locked_until = case when fail_count + 1 >= 5 then now() + interval '10 minutes' else locked_until end,
           fail_count = case when fail_count + 1 >= 5 then 0 else fail_count + 1 end
     where id = s.id;
    insert into login_attempts(ip, acct) values (v_ip, acct);
    delete from login_attempts where at < now() - interval '2 days' and id % 50 = 0;
    if s.fail_count + 1 >= 5 then
      perform _sec_log('pin_lock', 'warn', s.id, 'ใส่ PIN ผิดครบ 5 ครั้ง ล็อกบัญชี 10 นาที', 'pinlock:' || s.id || ':' || to_char(now(), 'YYYYMMDDHH24') || bucket);
    end if;
    perform _sec_ip_check(v_ip);
    return json_build_object('error', 'PIN ไม่ถูกต้อง');
  end if;
  if s.fail_count >= 3 then
    perform _sec_log('login_after_fails', 'warn', s.id, 'เข้าสู่ระบบสำเร็จหลังใส่ PIN ผิด ' || s.fail_count || ' ครั้ง', 'laf:' || s.id || ':' || to_char(now(), 'YYYYMMDDHH24'));
  end if;
  update students set fail_count = 0, locked_until = null, last_login = now() where id = s.id;
  insert into student_sessions (student_id) values (s.id) returning token into t;
  delete from student_sessions where student_id = s.id and expires_at < now();
  return json_build_object('token', t, 'name', s.name);
end $$;

-- ตรวจจับการแก้รายชื่อครู (ผู้โจมตีมักเพิ่มตัวเองเป็นครู)
create or replace function _trg_teachers_audit() returns trigger
language plpgsql security definer set search_path = public as $$
declare who text := coalesce(auth.jwt()->>'email', 'SQL Editor/ระบบ');
begin
  perform _sec_log('teachers_changed', 'critical', null,
    case TG_OP when 'INSERT' then 'เพิ่มครู ' || new.email when 'DELETE' then 'ลบครู ' || old.email else 'แก้ครู ' || old.email || ' → ' || new.email end || ' โดย ' || who,
    'teachers:' || md5(random()::text));
  return coalesce(new, old);
end $$;
drop trigger if exists teachers_audit on teachers;
create trigger teachers_audit after insert or update or delete on teachers for each row execute function _trg_teachers_audit();

-- สแกนความปลอดภัย (เฉพาะครู) — บันทึกเหตุใหม่ แล้วคืนจำนวนที่พบ
create or replace function security_scan() returns json
language plpgsql security definer set search_path = public as $$
declare r record; n int := 0; day text := to_char(now(), 'YYYYMMDD'); spike int := _setting_int('sec_exp_spike', 600);
begin
  if not is_teacher() then raise exception 'เฉพาะครูเท่านั้น'; end if;
  -- 1) ตารางที่ปิด RLS
  for r in select c.relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
            where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity
              and exists (select 1 from pg_policies pp where pp.schemaname = 'public' and pp.tablename = c.relname and pp.policyname = 'teacher_all') loop
    perform _sec_log('rls_off', 'critical', null, 'ตาราง ' || r.relname || ' ปิด RLS — ใครก็อ่านได้', 'rls:' || r.relname || ':' || day); n := n + 1;
  end loop;
  -- 2) ฟังก์ชันครูที่ anon เรียกได้
  for r in select p.proname from pg_proc p where p.pronamespace = 'public'::regnamespace
            and (p.proname like 'admin\_%' or p.proname in ('health_check','game_stats','security_scan','security_summary'))
            and has_function_privilege('anon', p.oid, 'execute') loop
    perform _sec_log('anon_admin_fn', 'critical', null, 'ฟังก์ชัน ' || r.proname || ' เปิดให้คนทั่วไปเรียกได้', 'fn:' || r.proname || ':' || day); n := n + 1;
  end loop;
  -- 3) anon อ่านตารางสำคัญได้
  for r in select t from unnest(array['students','ledger','student_sessions','teachers','security_events']) t
            where to_regclass('public.' || t) is not null and has_table_privilege('anon', 'public.' || t, 'select') loop
    perform _sec_log('anon_table', 'critical', null, 'anon มีสิทธิ์อ่านตาราง ' || r.t, 'tbl:' || r.t || ':' || day); n := n + 1;
  end loop;
  -- 4) EXP พุ่งผิดปกติใน 1 ชั่วโมง
  for r in select l.student_id, s.name, sum(l.exp) e from ledger l join students s on s.id = l.student_id
            where l.created_at > now() - interval '1 hour' group by 1, 2 having sum(l.exp) > spike loop
    perform _sec_log('exp_spike', 'high', r.student_id, r.name || ' ได้ EXP ' || r.e || ' ใน 1 ชั่วโมง (เกณฑ์ ' || spike || ')', 'spike:' || r.student_id || ':' || day || to_char(now(), 'HH24')); n := n + 1;
  end loop;
  -- 5) เซสชันนักเรียนคนเดียวมากผิดปกติ
  for r in select ss.student_id, count(*) c from student_sessions ss where not ss.observer and ss.expires_at > now() group by 1 having count(*) > 40 loop
    perform _sec_log('many_sessions', 'warn', r.student_id, 'มีเซสชันที่ใช้งานอยู่ ' || r.c || ' รายการ (อาจมีการเข้าซ้ำอัตโนมัติ)', 'sess:' || r.student_id || ':' || day); n := n + 1;
  end loop;
  -- 6) ค่าติดลบ
  if exists (select 1 from students where exp < 0 or coins < 0) then
    perform _sec_log('negative', 'high', null, 'พบ EXP/เหรียญติดลบ ตรวจสอบหน้าสุขภาพระบบ', 'neg:' || day); n := n + 1;
  end if;
  return json_build_object('found', n, 'at', now());
end $$;

-- สรุปให้แบนเนอร์/หน้าแดชบอร์ด
create or replace function security_summary() returns json
language plpgsql security definer set search_path = public as $$
declare ev json; blocked json;
begin
  if not is_teacher() then raise exception 'เฉพาะครูเท่านั้น'; end if;
  select coalesce(json_agg(x order by x.id desc), '[]') into ev from (
    select e.id, e.at, e.kind, e.sev, e.detail, e.ip, e.seen, s.name as student
      from security_events e left join students s on s.id = e.student_id order by e.id desc limit 40) x;
  select coalesce(json_agg(b), '[]') into blocked from (
    select ip, count(*) fails, count(distinct acct) accts from login_attempts
     where ip is not null and at > now() - interval '10 minutes' group by ip having count(*) >= _setting_int('sec_ip_limit', 60)) b;
  return json_build_object(
    'unseen', (select count(*) from security_events where not seen and sev in ('high','critical')),
    'unseen_warn', (select count(*) from security_events where not seen and sev = 'warn'),
    'critical', (select count(*) from security_events where not seen and sev = 'critical'),
    'lockdown', coalesce((select value from app_settings where key = 'sec_lockdown'), '0') = '1',
    'fails_1h', (select count(*) from login_attempts where at > now() - interval '1 hour'),
    'blocked', blocked, 'events', ev);
end $$;

create or replace function admin_sec_ack(p_ids bigint[] default null) returns int
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if not is_teacher() then raise exception 'เฉพาะครูเท่านั้น'; end if;
  update security_events set seen = true where not seen and (p_ids is null or id = any(p_ids));
  get diagnostics n = row_count; return n;
end $$;

create or replace function admin_lockdown(p_on boolean) returns json
language plpgsql security definer set search_path = public as $$
declare n int := 0;
begin
  if not is_teacher() then raise exception 'เฉพาะครูเท่านั้น'; end if;
  insert into app_settings(key, value) values ('sec_lockdown', case when p_on then '1' else '0' end)
    on conflict (key) do update set value = excluded.value;
  if p_on then delete from student_sessions where not observer; get diagnostics n = row_count; end if;
  insert into security_events(kind, sev, detail, seen) values ('lockdown', 'info', case when p_on then 'ครูเปิดโหมดฉุกเฉิน: ปิดระบบนักเรียน เตะเซสชัน ' || n || ' รายการ' else 'ครูปิดโหมดฉุกเฉิน: เปิดระบบนักเรียนแล้ว' end, true);
  return json_build_object('lockdown', p_on, 'kicked', n);
end $$;

create or replace function admin_unblock_ip(p_ip text) returns int
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if not is_teacher() then raise exception 'เฉพาะครูเท่านั้น'; end if;
  delete from login_attempts where ip = p_ip; get diagnostics n = row_count; return n;
end $$;

do $$ declare f text; begin
  foreach f in array array['security_scan()','security_summary()','admin_sec_ack(bigint[])','admin_lockdown(boolean)','admin_unblock_ip(text)'] loop
    execute format('revoke execute on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;
revoke execute on function _trg_teachers_audit() from public, anon, authenticated;
