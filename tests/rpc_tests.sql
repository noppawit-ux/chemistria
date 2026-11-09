-- ชุดทดสอบ: แต่ละข้อใช้ t(ชื่อ, เงื่อนไข) · ถ้าเงื่อนไขเป็นเท็จหรือ null = FAIL
set search_path = public, extensions;
create temp table _res(ok boolean, name text);
create or replace function pg_temp.t(p_name text, p_ok boolean) returns void language plpgsql as $$
begin insert into _res values (coalesce(p_ok,false), p_name); raise notice '%', case when coalesce(p_ok,false) then 'PASS  '||p_name else 'FAIL  '||p_name end; end $$;
-- รันฟังก์ชันภายใต้บทบาท แล้วบอกว่า error หรือไม่ (true = ผ่านสำเร็จ)
create or replace function pg_temp.fails(p_sql text, p_role text default 'anon') returns boolean language plpgsql as $$
begin execute 'set local role ' || p_role; execute p_sql; reset role; return false;
exception when others then reset role; return true; end $$;

create or replace function pg_temp.sees_rows(p_table text) returns boolean language plpgsql as $$
declare n int; begin execute 'select count(*) from ' || p_table into n; return n > 0; exception when insufficient_privilege then return false; end $$;
create or replace function pg_temp.bd(p_secs int) returns void language sql security definer as $$ update public.game_starts set started_at = now() - make_interval(secs => p_secs) $$;
-- ================= ข้อมูลตั้งต้น =================
insert into teachers(email) values ('t@x.th');
insert into classes(name, code, subject_name) values ('ม.9/9','T99','ทดสอบ') ;
insert into classes(name, code, subject_name) values ('ม.1/1','T11','ทดสอบ');
insert into students(class_id, no, name, pin_hash) select id, 1, 'ทดสอบ เอ', crypt('1234', gen_salt('bf')) from classes where code='T99';
insert into students(class_id, no, name, pin_hash) select id, 1, 'ทดสอบ บี', crypt('5678', gen_salt('bf')) from classes where code='T11';
create temp table _s as select (select id from students where name='ทดสอบ เอ') a, (select id from students where name='ทดสอบ บี') b;
grant all on _res, _s to anon, authenticated;

-- ================= ความปลอดภัย =================
select pg_temp.t('ทุกตารางใน public เปิด RLS',
  not exists (select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind='r' and not c.relrowsecurity));
select pg_temp.t('ทุกนโยบาย RLS ผูกกับ is_teacher()',
  not exists (select 1 from pg_policies where schemaname='public' and coalesce(qual,'') not like '%is_teacher()%'));
select pg_temp.t('anon เรียกฟังก์ชัน admin_* ไม่ได้ (ทั้งหมด)',
  not exists (select 1 from pg_proc p where p.pronamespace='public'::regnamespace and p.proname like 'admin\_%' and has_function_privilege('anon', p.oid, 'execute')));
select pg_temp.t('ไม่มีฟังก์ชันเปิดให้ PUBLIC เรียก (ยกเว้นตัวช่วยล้วน)',
  not exists (select 1 from pg_proc p where p.pronamespace='public'::regnamespace and p.prokind='f' and has_function_privilege('public', p.oid, 'execute')
              and p.proname not in ('is_teacher','level_for','rank_for','quest_period','today_th')
              and p.prorettype <> 'trigger'::regtype));
select pg_temp.t('anon เรียก health_check/game_stats/admin_purge_sessions ไม่ได้',
  pg_temp.fails('select health_check()') and pg_temp.fails('select game_stats(7)') and pg_temp.fails('select admin_purge_sessions()'));
select pg_temp.t('authenticated ที่ไม่ใช่ครู เรียก health_check ไม่ผ่าน',
  pg_temp.fails($q$select set_config('request.jwt.claims','{"email":"stranger@x.th"}',true); select health_check()$q$, 'authenticated'));
set role anon;
select pg_temp.t('anon มองไม่เห็นแถวใน students', not pg_temp.sees_rows('students'));
select pg_temp.t('anon มองไม่เห็นแถวใน ledger', not pg_temp.sees_rows('ledger'));
select pg_temp.t('anon มองไม่เห็นแถวใน v_gradebook', not pg_temp.sees_rows('v_gradebook'));
reset role;

-- ================= ล็อกอินและล็อก PIN =================
select pg_temp.t('ล็อกอินด้วย PIN ถูกได้ token', (select (student_login('T99',1,'1234')->>'token') is not null));
select pg_temp.t('PIN ผิดได้ error ไม่ได้ token', (select student_login('T99',1,'0000')->>'error') is not null);
do $$ begin for i in 1..4 loop perform student_login('T99',1,'0000'); end loop; end $$;
select pg_temp.t('ใส่ PIN ผิดครบ 5 ครั้ง บัญชีถูกล็อก', (select locked_until > now() from students where name='ทดสอบ เอ'));
select pg_temp.t('ระหว่างล็อก แม้ PIN ถูกก็เข้าไม่ได้', pg_temp.fails($q$select student_login('T99',1,'1234')$q$));
update students set locked_until=null, fail_count=0 where name='ทดสอบ เอ';
create temp table _tok as select (student_login('T99',1,'1234')->>'token')::uuid a, (student_login('T11',1,'5678')->>'token')::uuid b;
grant all on _tok to anon, authenticated;

-- ================= รางวัล / ledger =================
create temp table _e0 as select exp from students where id=(select a from _s);
select pg_temp.t('award ครั้งแรกสำเร็จ', award((select a from _s), 10, 5, 'ทดสอบ', 'test:1'));
select pg_temp.t('award ref_key เดิมซ้ำ ไม่ให้ซ้ำ', not award((select a from _s), 10, 5, 'ทดสอบ', 'test:1'));
select pg_temp.t('EXP ถูกบวกครั้งเดียว', (select exp from students where id=(select a from _s)) - (select exp from _e0) = 10);
select award((select a from _s), -999, 0, 'ลองติดลบ', 'test:neg');
select pg_temp.t('EXP ไม่ติดลบแม้หักเยอะ', (select exp from students where id=(select a from _s)) >= 0);
update students set exp = 0, coins = 100 where id=(select a from _s);

-- เช็กชื่อ → ได้รางวัลอัตโนมัติ
insert into ch_attendance(class_id, student_id, att_date, status) select class_id, id, today_th(), 'present' from students where name='ทดสอบ เอ';
select pg_temp.t('เช็กชื่อมาเรียน → มีรางวัลเข้า ledger', exists (select 1 from ledger where student_id=(select a from _s) and ref_key like 'att:%'));

-- ================= โปรโมชัน =================
insert into app_settings(key,value) values ('promo_until', (today_th()+3)::text) on conflict (key) do update set value=excluded.value;
insert into app_settings(key,value) values ('promo_coins','50'),('promo_exp','20'),('promo_pulls','1') on conflict (key) do update set value=excluded.value;
update students set free_pulls = 0 where id=(select a from _s);
set role anon;
select pg_temp.t('promo_claim ครั้งแรกสำเร็จ', (select (promo_claim((select a from _tok))->>'coins')::int = 50));
select pg_temp.t('promo_claim ซ้ำ → error', pg_temp.fails($q$select promo_claim((select a from _tok))$q$));
reset role;
select pg_temp.t('ของขวัญให้ตั๋วกาชา 1 ใบ', (select free_pulls from students where id=(select a from _s)) = 1);
update app_settings set value=(today_th()-1)::text where key='promo_until';
set role anon;
select pg_temp.t('โปรหมดอายุแล้วรับไม่ได้', pg_temp.fails($q$select promo_claim((select b from _tok))$q$));
reset role;

-- ================= ควิซประจำวัน =================
insert into quiz_questions(topic, question, a, b, c, d, answer, explain, class_id, active) select 'ทดสอบ','ข้อเฉพาะห้อง ม.1/1 #'||g,'ก','ข','ค','ง',0,'-', (select id from classes where code='T11'), true from generate_series(1,6) g;
set role anon;
select pg_temp.t('quiz_today ส่งคำถามมาครบจำนวน', (select json_array_length(quiz_today((select a from _tok))->'questions') > 0));
select pg_temp.t('ห้อง ม.1/1 ได้เฉพาะข้อของห้องตัวเองก่อน',
  (select bool_and(q->>'question' like 'ข้อเฉพาะห้อง%') from json_array_elements(quiz_today((select b from _tok))->'questions') q));
select pg_temp.t('ห้องอื่นไม่เห็นข้อเฉพาะห้อง ม.1/1',
  (select bool_and(q->>'question' not like 'ข้อเฉพาะห้อง%') from json_array_elements(quiz_today((select a from _tok))->'questions') q));
select game_begin((select a from _tok), 'quiz'); select pg_temp.bd(60);
select pg_temp.t('quiz_submit สำเร็จครั้งแรก', (select quiz_submit((select a from _tok), '[0,0,0,0,0]'::jsonb) is not null));
select game_begin((select a from _tok), 'quiz'); select pg_temp.bd(60);
select pg_temp.t('ส่งควิซซ้ำในวันเดียวกัน → error', pg_temp.fails($q$select quiz_submit((select a from _tok), '[0,0,0,0,0]'::jsonb)$q$));
select pg_temp.t('หลังทำแล้ว quiz_today บอก done', (select (quiz_today((select a from _tok))->>'done')::boolean));
reset role;
select pg_temp.t('ควิซบันทึกรางวัลลง ledger ครั้งเดียว', (select count(*) from ledger where student_id=(select a from _s) and ref_key like 'game:quiz:%') = 1);

-- ================= กาชา =================
update students set coins = 0, free_pulls = 0 where id=(select b from _s);
set role anon;
select pg_temp.t('กาชาตอนเหรียญไม่พอ → error', pg_temp.fails($q$select gacha_pull((select b from _tok), 1)$q$));
reset role;

-- ================= โหมดส่อง (peek) =================
insert into student_sessions(token, student_id, expires_at, observer) values ('11111111-1111-1111-1111-111111111111', (select a from _s), now()+interval '1 hour', true);
do $$
declare r record; allowed text[] := array['student_dashboard','student_extras','hall_of_fame','board_list','celebrations_feed','game_status','spell_status','kb_status','news_list','run_status','timetable_list','promo_status','guild_status','guild_board'];
        bad text := ''; n int := 0;
begin
  for r in select p.proname from pg_proc p where p.pronamespace='public'::regnamespace and p.prosrc ilike '%_sid(%' and p.proname <> all(allowed)
            and pg_get_function_arguments(p.oid) ilike 'p_token uuid%' loop
    n := n + 1;
    begin perform set_config('request.path','/rpc/'||r.proname,true); perform _sid('11111111-1111-1111-1111-111111111111'); bad := bad || r.proname || ' ';
    exception when others then null; end;
  end loop;
  perform pg_temp.t('โหมดส่อง: ฟังก์ชันนอกรายการอนุญาตถูกบล็อกทั้งหมด (' || n || ' ฟังก์ชัน)' || case when bad<>'' then ' ผ่านได้: '||bad else '' end, bad = '' and n > 20);
end $$;
select pg_temp.t('โหมดส่อง: student_dashboard ผ่านได้',
  (select set_config('request.path','/rpc/student_dashboard',true) is not null) and (select _sid('11111111-1111-1111-1111-111111111111') is not null));

-- ================= ตรวจสุขภาพ / สถิติ (ครู) =================
select set_config('request.jwt.claims','{"email":"t@x.th","role":"authenticated"}',false);
set role authenticated;
select pg_temp.t('health_check ครูเรียกได้และมีรายการตรวจ', (select json_array_length(health_check()->'items') >= 8));
select pg_temp.t('health_check: ข้อมูลปกติ ไม่มี level bad', (select not exists (select 1 from json_array_elements(health_check()->'items') i where i->>'level'='bad')));
reset role;
update students set exp = -5 where id=(select a from _s);
set role authenticated;
select pg_temp.t('health_check จับ EXP ติดลบได้', (select exists (select 1 from json_array_elements(health_check()->'items') i where i->>'key'='neg' and i->>'level'='bad')));
select pg_temp.t('game_stats คืนแหล่งรางวัลของควิซ', (select exists (select 1 from json_array_elements(game_stats(30)->'sources') s where s->>'src' like '%ควิซ%')));
reset role;


-- ================= ระบบป้องกันการโจมตี (SQL 42) =================
reset role;
select pg_temp.t('anon เรียกฟังก์ชันความปลอดภัยของครูไม่ได้',
  pg_temp.fails('select security_scan()') and pg_temp.fails('select security_summary()') and pg_temp.fails($q$select admin_lockdown(true)$q$) and pg_temp.fails($q$select admin_sec_ack(null)$q$) and pg_temp.fails($q$select admin_unblock_ip('1.1.1.1')$q$));
set role anon;
select pg_temp.t('anon มองไม่เห็นแถวใน security_events', not pg_temp.sees_rows('security_events'));
select pg_temp.t('anon มองไม่เห็นแถวใน login_attempts', not pg_temp.sees_rows('login_attempts'));
reset role;
select pg_temp.t('เพิ่มครูใหม่ถูกบันทึกเป็นเหตุ critical', exists (select 1 from security_events where kind='teachers_changed' and sev='critical'));
-- จำลองการเดา PIN จาก IP เดียว
update students set locked_until=null, fail_count=0;
select set_config('request.headers', '{"x-forwarded-for":"9.9.9.9, 10.0.0.1"}', false);
update app_settings set value=value where false;
insert into app_settings(key,value) values ('sec_ip_limit','6'),('sec_sweep_accts','2') on conflict (key) do update set value=excluded.value;
select student_login('T99',1,'bad'); select student_login('T11',1,'bad'); select student_login('T99',1,'bad');
select pg_temp.t('เดาหลายบัญชีจาก IP เดียว ถูกบันทึก ip_sweep', exists (select 1 from security_events where kind='ip_sweep' and ip='9.9.9.9'));
select student_login('T11',1,'bad'); select student_login('T99',2,'x'); select student_login('T99',3,'x');
select pg_temp.t('IP ที่ผิดเกินเกณฑ์ ถูกบล็อกแม้ PIN ถูก', pg_temp.fails($q$select student_login('T11',1,'5678')$q$));
select pg_temp.t('การบล็อก IP ถูกบันทึกเป็นเหตุ', exists (select 1 from security_events where kind='ip_blocked'));
select pg_temp.t('IP อื่นยังล็อกอินได้ตามปกติ', (select set_config('request.headers','{"x-forwarded-for":"8.8.8.8"}',false) is not null) and (select student_login('T11',1,'5678')->>'token') is not null);
set role authenticated; select set_config('request.jwt.claims','{"email":"t@x.th"}',true);
select admin_unblock_ip('9.9.9.9');
reset role;
select pg_temp.t('ครูปลดบล็อก IP แล้วล็อกอินได้อีก', (select set_config('request.headers','{"x-forwarded-for":"9.9.9.9"}',false) is not null) and (select student_login('T11',1,'5678')->>'token') is not null);
-- สแกน
set role authenticated; select set_config('request.jwt.claims','{"email":"t@x.th"}',true);
select pg_temp.t('security_scan ครูเรียกได้', (select (security_scan()->>'found') is not null));
select pg_temp.t('ระบบปกติ: สแกนไม่พบ rls_off/anon_admin_fn/anon_table', not exists (select 1 from security_events where kind in ('rls_off','anon_admin_fn','anon_table')));
reset role;
-- ย้อนช่องโหว่: เปิดให้ anon เรียก admin_adjust แล้วสแกนต้องเจอ
grant execute on function admin_adjust(uuid,int,int,text) to anon;
set role authenticated; select set_config('request.jwt.claims','{"email":"t@x.th"}',true);
select security_scan();
reset role;
select pg_temp.t('สแกนจับฟังก์ชันครูที่ anon เรียกได้', exists (select 1 from security_events where kind='anon_admin_fn'));
revoke execute on function admin_adjust(uuid,int,int,text) from anon;
-- EXP พุ่ง
insert into ledger(student_id, exp, coins, reason, ref_key) select a, 5000, 0, 'ทดสอบพุ่ง', 'spike:t' from _s;
set role authenticated; select set_config('request.jwt.claims','{"email":"t@x.th"}',true);
select security_scan();
select pg_temp.t('สแกนจับ EXP พุ่งผิดปกติ', exists (select 1 from security_events where kind='exp_spike'));
select pg_temp.t('security_summary นับเหตุร้ายแรงที่ยังไม่อ่าน', (security_summary()->>'unseen')::int >= 1);
select admin_sec_ack(null);
select pg_temp.t('กดรับทราบแล้ว เหตุร้ายแรงที่ยังไม่อ่านเป็น 0', (security_summary()->>'unseen')::int = 0);
-- lockdown
select admin_lockdown(true);
reset role;
select pg_temp.t('lockdown: เตะเซสชันนักเรียนทั้งหมด', not exists (select 1 from student_sessions where not observer));
select pg_temp.t('lockdown: ล็อกอินไม่ได้', pg_temp.fails($q$select student_login('T11',1,'5678')$q$));
set role authenticated; select set_config('request.jwt.claims','{"email":"t@x.th"}',true);
select admin_lockdown(false);
reset role;
select pg_temp.t('ปิด lockdown แล้วล็อกอินได้', (select student_login('T11',1,'5678')->>'token') is not null);


-- ================= ป้องกันบอท/สคริปต์ (SQL 43) =================
reset role;
delete from app_settings where key in ('sec_ip_limit','sec_sweep_accts'); delete from login_attempts; select set_config('request.headers','{}',false);
update students set locked_until=null, fail_count=0, lock_level=0;
create temp table _tok2 as select (student_login('T99',1,'1234')->>'token')::uuid a, (student_login('T11',1,'5678')->>'token')::uuid b;
grant all on _tok2 to anon, authenticated;
-- เวลาเล่นเกม
select pg_temp.t('ส่งคะแนนเกมโดยไม่ได้เริ่มเกม → ถูกปฏิเสธ', pg_temp.fails($q$select match_submit((select b from _tok2), 80, 6, 60)$q$));
select game_begin((select b from _tok2), 'match');
select pg_temp.t('ส่งคะแนนทันทีหลังเริ่ม (เร็วเกินจริง) → ถูกปฏิเสธ', pg_temp.fails($q$select match_submit((select b from _tok2), 80, 6, 60)$q$));
select pg_temp.bd(90);
select pg_temp.t('เล่นนานพอ ส่งคะแนนผ่าน', (select match_submit((select b from _tok2), 80, 6, 60) is not null));
select pg_temp.t('ส่งคะแนนซ้ำด้วยการเริ่มเกมเดิม → ถูกปฏิเสธ (ใช้แล้วหมด)', pg_temp.fails($q$select match_submit((select b from _tok2), 80, 6, 60)$q$));
select game_begin((select b from _tok2), 'run'); select pg_temp.bd(4);
select pg_temp.t('อ้างว่าเล่น 120 วินาทีแต่จริงๆ 4 วินาที → ถูกปฏิเสธ', pg_temp.fails($q$select run_submit((select b from _tok2), 500, 120)$q$));
select pg_temp.t('ฟังก์ชันภายใน _match_submit เรียกตรงไม่ได้', pg_temp.fails($q$select _match_submit((select b from _tok2), 100, 6, 60)$q$));
set role anon;
select pg_temp.t('anon มองไม่เห็นแถวใน game_starts', not pg_temp.sees_rows('game_starts'));
reset role;
-- จำกัดอัตราต่อนาที
insert into app_settings(key,value) values ('sec_rpc_per_min','6') on conflict (key) do update set value=excluded.value;
update student_sessions set win_start=null, win_n=0;
create temp table _rl(n int, hit boolean); grant all on _rl to anon, authenticated;
do $$ declare i int; begin for i in 1..9 loop begin perform game_status((select b from _tok2)); insert into _rl values (i, false); exception when others then insert into _rl values (i, true); end; end loop; end $$;
select pg_temp.t('เรียกถี่เกินเกณฑ์ → ถูกปฏิเสธตั้งแต่ครั้งที่ 7', (select min(n) from _rl where hit) = 7);
select pg_temp.t('เรียกถี่ถึงเกณฑ์ → บันทึก rate_abuse', exists (select 1 from security_events where kind='rate_abuse'));
delete from app_settings where key='sec_rpc_per_min';
update student_sessions set win_start=null, win_n=0;
select pg_temp.t('ปรับเกณฑ์กลับแล้วเรียกได้ปกติ', (select game_status((select b from _tok2)) is not null));
-- ล็อก PIN ทวีคูณ
update students set locked_until=null, fail_count=0, lock_level=0 where name='ทดสอบ บี';
do $$ begin for i in 1..5 loop perform student_login('T11',1,'bad'); end loop; end $$;
select pg_temp.t('ล็อกรอบแรกประมาณ 10 นาที', (select locked_until between now()+interval '9 minutes' and now()+interval '11 minutes' from students where name='ทดสอบ บี'));
update students set locked_until=null where name='ทดสอบ บี';
do $$ begin for i in 1..5 loop perform student_login('T11',1,'bad'); end loop; end $$;
select pg_temp.t('ล็อกรอบสองนานขึ้นเป็นประมาณ 30 นาที', (select locked_until between now()+interval '29 minutes' and now()+interval '31 minutes' from students where name='ทดสอบ บี'));
update students set locked_until=null where name='ทดสอบ บี';
select student_login('T11',1,'5678');
select pg_temp.t('ใส่ PIN ถูกแล้ว ระดับล็อกกลับเป็น 0', (select lock_level = 0 and fail_count = 0 from students where name='ทดสอบ บี'));
update students set lock_level=3, locked_until=now()+interval '5 hours', fail_count=2 where name='ทดสอบ บี';
update students set pin_hash = crypt('9999', gen_salt('bf')) where name='ทดสอบ บี';
select pg_temp.t('ครูเปลี่ยน PIN → ปลดล็อกและรีเซ็ตระดับอัตโนมัติ', (select lock_level=0 and locked_until is null and fail_count=0 from students where name='ทดสอบ บี'));

select pg_temp.t('ประกาศ Mini Guild (coming soon) อยู่ในสไลด์ข่าว', exists (select 1 from news_posts where title like 'Mini Guild%' and kind='event' and active));


-- ================= Mini Guild (SQL 45) =================
reset role;
update app_settings set value=(current_date - 1)::text where key='guild_reg_from';
update app_settings set value=current_date::text where key='guild_start';
update app_settings set value=(current_date + 14)::text where key='guild_end';
update app_settings set value=(current_date + 3)::text where key='guild_join_until';
update app_settings set value='10' where key='guild_min_personal_gp';
insert into students(class_id, no, name, pin_hash) select c.id, n, 'กิลด์ทดสอบ '||n, crypt('1234', gen_salt('bf')) from classes c, generate_series(11,19) n where c.code='T99';
insert into students(class_id, no, name, pin_hash) select c.id, 11, 'อีกห้อง', crypt('1234', gen_salt('bf')) from classes c where c.code='T11';
create temp table _gt as select n as no, (student_login('T99', n, '1234')->>'token')::uuid tok from generate_series(11,19) n;
create temp table _go as select (student_login('T11', 11, '1234')->>'token')::uuid tok;
grant all on _gt, _go to anon, authenticated;
set role anon;
select pg_temp.t('anon เรียกฟังก์ชันกิลด์ของครู/ภายในไม่ได้',
  pg_temp.fails('select admin_guild_list()') and pg_temp.fails('select admin_guild_random(null)') and pg_temp.fails('select _guild_ranks()') and pg_temp.fails('select _guild_member_gp()') and pg_temp.fails($q$select admin_guild_disband('00000000-0000-0000-0000-000000000000')$q$));
select pg_temp.t('สร้างกิลด์สำเร็จ', (select guild_create((select tok from _gt where no=11), 'ทีมอัลฟา')->>'id') is not null);
select pg_temp.t('สร้างกิลด์ซ้ำคนเดียว → ปฏิเสธ', pg_temp.fails($q$select guild_create((select tok from _gt where no=11), 'อื่นๆ')$q$));
select pg_temp.t('ชื่อซ้ำ (ไม่สนตัวพิมพ์) → ปฏิเสธ', pg_temp.fails($q$select guild_create((select tok from _gt where no=12), 'ทีมอัลฟา')$q$));
select pg_temp.t('ชื่อไม่เหมาะสม → ปฏิเสธ', pg_temp.fails($q$select guild_create((select tok from _gt where no=12), 'fuck team')$q$));
select pg_temp.t('ชื่อสั้นเกิน/ยาวเกิน → ปฏิเสธ', pg_temp.fails($q$select guild_create((select tok from _gt where no=12), 'ก')$q$) and pg_temp.fails($q$select guild_create((select tok from _gt where no=12), 'ยาวเกินสิบหกตัวอักษรแน่นอนเลยนะ')$q$));
reset role;
create temp table _gid as select id from guilds where name='ทีมอัลฟา'; grant all on _gid to anon, authenticated;
set role anon;
select pg_temp.t('เข้ากิลด์ห้องเดียวกันได้', (select guild_join((select tok from _gt where no=12), (select id from _gid))->>'name') = 'ทีมอัลฟา');
select pg_temp.t('เข้ากิลด์ของห้องอื่นไม่ได้', pg_temp.fails($q$select guild_join((select tok from _go), (select id from _gid))$q$));
select guild_join((select tok from _gt where no=13), (select id from _gid)); select guild_join((select tok from _gt where no=14), (select id from _gid)); select guild_join((select tok from _gt where no=15), (select id from _gid));
select pg_temp.t('กิลด์เต็ม 5 คน คนที่ 6 เข้าไม่ได้', pg_temp.fails($q$select guild_join((select tok from _gt where no=16), (select id from _gid))$q$));
select pg_temp.t('ไม่มีกิลด์ ออกกิลด์ไม่ได้', pg_temp.fails($q$select guild_leave((select tok from _gt where no=16))$q$));
reset role;
delete from ledger where student_id in (select id from students where name like 'กิลด์ทดสอบ%');
-- แต้มกิลด์: ledger ปกติ นับ · ครูปรับให้ ไม่นับ · เพดานต่อวัน
insert into ledger(student_id, exp, coins, reason, ref_key) select id, 30, 0, 'เควส: ทดสอบ', 'g:1' from students where name='กิลด์ทดสอบ 11';
insert into ledger(student_id, exp, coins, reason, ref_key) select id, 500, 0, 'ครูปรับให้: ทดสอบ', 'g:2' from students where name='กิลด์ทดสอบ 12';
insert into ledger(student_id, exp, coins, reason, ref_key) select id, 300, 0, 'ส่งงาน: ทดสอบ', 'g:3' from students where name='กิลด์ทดสอบ 13';
insert into ledger(student_id, exp, coins, reason, ref_key) select id, 100, 0, 'โบนัสพิเศษจากครู (ข้อความเอง)', 'g:4' from students where name='กิลด์ทดสอบ 14';
select pg_temp.t('GP: ครูปรับด้วยข้อความเอง (เหตุผลไม่รู้จัก) ไม่นับ', (select gp = 0 from _guild_member_gp() where student_id=(select id from students where name='กิลด์ทดสอบ 14')));
select pg_temp.t('GP: เควสนับเต็ม', (select gp = 30 from _guild_member_gp() where student_id=(select id from students where name='กิลด์ทดสอบ 11')));
select pg_temp.t('GP: ครูปรับให้ไม่นับ', (select gp = 0 from _guild_member_gp() where student_id=(select id from students where name='กิลด์ทดสอบ 12')));
select pg_temp.t('GP: เพดานต่อวัน (300 → 60)', (select gp = 60 from _guild_member_gp() where student_id=(select id from students where name='กิลด์ทดสอบ 13')));
select pg_temp.t('อันดับ: เฉลี่ยต่อคน = 90/5 = 18', (select avg = 18 and size = 5 and ranked and rank = 1 from _guild_ranks() where name='ทีมอัลฟา'));
set role anon;
select pg_temp.t('guild_status: สมาชิกครบ และเห็นแต้มตนเอง', (select (s->'my'->>'size')::int = 5 and (s->'my'->>'personal_gp')::numeric = 30 from (select guild_status((select tok from _gt where no=11))::jsonb s) x));
select pg_temp.t('guild_board: มีกิลด์ติดอันดับ', (select jsonb_array_length((guild_board((select tok from _go)))::jsonb->'rows') >= 1));
select pg_temp.t('ชื่อกิลด์แสดงใน student_dashboard', (select student_dashboard((select tok from _gt where no=11))::jsonb->'student'->>'guild') = 'ทีมอัลฟา');
select pg_temp.t('ชื่อกิลด์แสดงใน leaderboard ของ dashboard', exists (select 1 from jsonb_array_elements(student_dashboard((select tok from _gt where no=11))::jsonb->'leaderboard') e where e->>'guild' = 'ทีมอัลฟา'));
select pg_temp.t('hall_of_fame ยังทำงานและไม่ error', (select hall_of_fame((select tok from _gt where no=11)) is not null));
-- รางวัลขั้น
select pg_temp.t('ขั้นที่ 1 ยังไม่ถึง (เฉลี่ย 18 < 150) รับไม่ได้', pg_temp.fails($q$select guild_claim_tier((select tok from _gt where no=11), 1)$q$));
reset role;
update guild_tiers set min_avg = 10 where tier = 2;
create temp table _c0 as select coins, free_pulls from students where name='กิลด์ทดสอบ 11'; grant all on _c0 to anon;
set role anon;
select pg_temp.t('รับรางวัลขั้นที่ 2 สำเร็จ (ได้เหรียญ+ตั๋วกาชา)', (select guild_claim_tier((select tok from _gt where no=11), 2)->>'pulls') = '1');
reset role;
select pg_temp.t('เหรียญและตั๋วเพิ่มตามรางวัล', (select s.coins - c.coins = 30 and s.free_pulls - c.free_pulls = 1 from students s, _c0 c where s.name='กิลด์ทดสอบ 11'));
set role anon;
select pg_temp.t('รับขั้นเดิมซ้ำไม่ได้', pg_temp.fails($q$select guild_claim_tier((select tok from _gt where no=11), 2)$q$));
select pg_temp.t('สมาชิกที่แต้มส่วนตัวไม่ถึงเกณฑ์ (0 < 10) รับไม่ได้', pg_temp.fails($q$select guild_claim_tier((select tok from _gt where no=12), 2)$q$));
-- หัวหน้าเปลี่ยนชื่อ 1 ครั้ง
select pg_temp.t('หัวหน้าเปลี่ยนชื่อกิลด์ได้', (select guild_rename((select tok from _gt where no=11), 'ทีมเบตา')->>'name') = 'ทีมเบตา');
select pg_temp.t('เปลี่ยนชื่อครั้งที่สองไม่ได้', pg_temp.fails($q$select guild_rename((select tok from _gt where no=11), 'ทีมแกมมา')$q$));
select pg_temp.t('สมาชิกทั่วไปเปลี่ยนชื่อไม่ได้', pg_temp.fails($q$select guild_rename((select tok from _gt where no=12), 'ทีมแกมมา')$q$));
-- โหมดส่อง: ดูกิลด์ได้ แต่สร้าง/เข้าไม่ได้
reset role;
insert into student_sessions(student_id, observer, expires_at) select id, true, now()+interval '1 hour' from students where name='กิลด์ทดสอบ 16';
create temp table _ob as select token from student_sessions where observer and student_id=(select id from students where name='กิลด์ทดสอบ 16') limit 1; grant all on _ob to anon;
select set_config('request.path','/rpc/guild_status',false);
set role anon;
select pg_temp.t('โหมดส่องเรียก guild_status ได้', (select guild_status((select token from _ob)) is not null));
reset role; select set_config('request.path','/rpc/guild_create',false); set role anon;
select pg_temp.t('โหมดส่องสร้างกิลด์ไม่ได้', pg_temp.fails($q$select guild_create((select token from _ob), 'แอบส่อง')$q$));
reset role; select set_config('request.path','',false);
-- สุ่มจัดคนที่ยังไม่มีกิลด์ (ครู)
set role authenticated; select set_config('request.jwt.claims','{"email":"t@x.th"}',true);
select admin_guild_random((select id from classes where code='T99'));
reset role;
select pg_temp.t('สุ่มจัด: นักเรียนทุกคนในห้องมีกิลด์', not exists (select 1 from students s where s.class_id=(select id from classes where code='T99') and not s.is_gm and not exists (select 1 from guild_members m where m.student_id=s.id)));
select pg_temp.t('สุ่มจัด: ทุกกิลด์ 3–5 คน', not exists (select 1 from (select g.id, count(m.student_id) n from guilds g left join guild_members m on m.guild_id=g.id where g.class_id=(select id from classes where code='T99') group by g.id) x where n < 3 or n > 5));
select pg_temp.t('สุ่มจัด: ไม่มีใครอยู่สองกิลด์ (คีย์หลัก)', (select count(*) = count(distinct student_id) from guild_members));
select pg_temp.t('สุ่มจัด: ห้องอื่นไม่ถูกแตะ', not exists (select 1 from guild_members m join students s on s.id=m.student_id join classes c on c.id=s.class_id where c.code='T11'));
-- ล็อกสมาชิกหลังหมดเวลารับสมัคร
update app_settings set value=(current_date - 1)::text where key='guild_join_until';
set role anon;
select pg_temp.t('หลังล็อก: ออกกิลด์ไม่ได้', pg_temp.fails($q$select guild_leave((select tok from _gt where no=12))$q$));
select pg_temp.t('หลังล็อก: สร้างกิลด์ไม่ได้', pg_temp.fails($q$select guild_create((select tok from _go), 'กิลด์สาย')$q$));
-- ซ่อนอันดับวันสุดท้าย
reset role; update app_settings set value=current_date::text where key='guild_end'; set role anon;
select pg_temp.t('วันสุดท้าย: board ถูกซ่อน', (select (guild_board((select tok from _gt where no=11))::jsonb->>'hidden') = 'true'));
select pg_temp.t('วันสุดท้าย: status ไม่เผยอันดับ/แต้มเฉลี่ย', (select (s->'my'->'rank') = 'null'::jsonb and (s->'my'->'avg') = 'null'::jsonb from (select guild_status((select tok from _gt where no=11))::jsonb s) x));
-- จบกิจกรรม: รางวัลอันดับ
reset role; update app_settings set value=(current_date - 1)::text where key='guild_end'; update app_settings set value=(current_date - 5)::text where key='guild_start';
update ledger set created_at = now() - interval '2 days' where ref_key in ('g:1','g:3','g:4');
set role anon;
select pg_temp.t('จบกิจกรรม: อันดับกลับมาแสดง', (select (guild_board((select tok from _gt where no=11))::jsonb->>'hidden') = 'false'));
reset role;
create temp table _p0 as select coins from students where name='กิลด์ทดสอบ 11';
set role anon;
select pg_temp.t('รับรางวัลอันดับสำเร็จ (กิลด์ทดสอบอยู่อันดับต้นๆ)', (select guild_claim_prize((select tok from _gt where no=11)) is not null));
select pg_temp.t('รับรางวัลอันดับซ้ำไม่ได้', pg_temp.fails($q$select guild_claim_prize((select tok from _gt where no=11))$q$));
reset role;

-- ================= สรุป =================
do $$ declare p int; f int; begin select count(*) filter (where ok), count(*) filter (where not ok) into p, f from _res;
  raise notice 'SUMMARY  ผ่าน % ข้อ · ไม่ผ่าน % ข้อ', p, f; end $$;
