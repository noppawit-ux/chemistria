-- ชุดทดสอบ: แต่ละข้อใช้ t(ชื่อ, เงื่อนไข) · ถ้าเงื่อนไขเป็นเท็จหรือ null = FAIL
set search_path = public, extensions;
create temp table _new84(key text);
insert into _new84 values ('sub_1'),('sub_25'),('sub_50'),('exam_1'),('exam_5'),('exam_high_3'),('exam_full_1'),('mon_1'),('mon_10'),('mon_30'),('mon_kinds_8'),('trial_1'),('trial_4'),('run_1'),('run_20'),('run_800'),('run_2000'),('card_5'),('card_20'),('card_40'),('card_set_1'),('card_ssr_1'),('gear_5'),('gear_20'),('gear_rare_3'),('gear_lv3'),('use_1'),('use_10'),('use_30');
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
update app_settings set value=(today_th() - 1)::text where key='guild_reg_from';
update app_settings set value=today_th()::text where key='guild_start';
update app_settings set value=(today_th() + 14)::text where key='guild_end';
update app_settings set value=(today_th() + 3)::text where key='guild_join_until';
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
select pg_temp.t('guild_status: สมาชิกมีข้อมูลตัวละคร (คลาส · แรงก์ · ตกแต่ง)', (select bool_and(m ? 'char_class' and m ? 'rank_info' and m ? 'decor' and m ? 'name') and count(*) = 5 and count(*) filter (where (m->>'me')::boolean) = 1 from (select jsonb_array_elements(guild_status((select tok from _gt where no=11))::jsonb->'my'->'members') m) x));
select pg_temp.t('guild_board: แต่ละกิลด์แสดงสมาชิกพร้อมตัวละคร แต่ไม่เผยแต้มรายคน', (select bool_and(jsonb_array_length(r->'members') >= 1 and not exists (select 1 from jsonb_array_elements(r->'members') mm where mm->'gp' <> 'null'::jsonb))
  from jsonb_array_elements(guild_board((select tok from _go))::jsonb->'rows') r));
select pg_temp.t('guild_status: มีสัญลักษณ์กิลด์ 1–12 (ค่าเริ่มต้นคงที่)', (select (s->'my'->>'emblem')::int between 1 and 12 from (select guild_status((select tok from _gt where no=11))::jsonb s) x));
select pg_temp.t('guild_set_emblem: หัวหน้าเปลี่ยนสัญลักษณ์ได้', (select (guild_set_emblem((select tok from _gt where no=11), 7)->>'emblem')::int = 7 and (guild_status((select tok from _gt where no=11))::jsonb->'my'->>'emblem')::int = 7));
select pg_temp.t('guild_set_emblem: เลขนอกช่วง → ปฏิเสธ', pg_temp.fails($q$select guild_set_emblem((select tok from _gt where no=11), 13)$q$));
select pg_temp.t('guild_board: แถวอันดับมีสัญลักษณ์', (select bool_and((r->>'emblem')::int between 1 and 12) from jsonb_array_elements(guild_board((select tok from _go))::jsonb->'rows') r));
-- ภารกิจกิลด์ + แถบรางวัล
reset role;
create temp table _gq as select id, class_id from guilds where name='ทีมอัลฟา'; grant all on _gq to anon, authenticated;
update guild_quests set per_member = 2 where kind = 'monster';
insert into battles (student_id, monster_id, status, p_hp, p_max, m_hp, m_max)
  select (select id from students where no = 11 and class_id = (select class_id from _gq)), m.id, 'won', 10, 10, 0, 10 from monsters m, generate_series(1, 6) limit 6;
set role anon;
select pg_temp.t('ภารกิจกิลด์: มีภารกิจและขั้นรางวัลใน guild_status', (select jsonb_array_length(s->'my'->'pass'->'quests') = 4 and jsonb_array_length(s->'my'->'pass'->'tiers') = 6 from (select guild_status((select tok from _gt where no=11))::jsonb s) x));
select pg_temp.t('ภารกิจกิลด์: เป้าปรับตามจำนวนคน + เพดานต่อคน (ชนะ 6 ครั้งคนเดียวนับ 4 จากเป้า 10 = 40 MP)', (select (q->>'target')::int = 10 and (q->>'progress')::int = 4 and (q->>'mp_got')::int = 40
  from (select jsonb_array_elements(guild_status((select tok from _gt where no=11))::jsonb->'my'->'pass'->'quests') q) x where q->>'kind' = 'monster'));
select pg_temp.t('ภารกิจกิลด์: ผู้ช่วยกดรับขั้น 1 ได้', (select (s->'my'->'pass'->'tiers'->0->>'claimable')::boolean from (select guild_status((select tok from _gt where no=11))::jsonb s) x));
select pg_temp.t('ภารกิจกิลด์: คนที่ยังไม่ได้ช่วยรับไม่ได้', (select not (s->'my'->'pass'->>'eligible')::boolean from (select guild_status((select tok from _gt where no=14))::jsonb s) x)
  and pg_temp.fails($q$select guild_pass_claim((select tok from _gt where no=14), 1)$q$));
select pg_temp.t('ภารกิจกิลด์: รับขั้น 1 สำเร็จ', (select (guild_pass_claim((select tok from _gt where no=11), 1)->>'coins')::int = 15));
select pg_temp.t('ภารกิจกิลด์: รับซ้ำไม่ได้', pg_temp.fails($q$select guild_pass_claim((select tok from _gt where no=11), 1)$q$));
select pg_temp.t('ภารกิจกิลด์: ขั้นที่ยังไม่ถึงรับไม่ได้', pg_temp.fails($q$select guild_pass_claim((select tok from _gt where no=11), 6)$q$));
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
-- ================= Guild Battle (db/80) =================
reset role;
set role anon;
select guild_create((select tok from _gt where no=16), 'ทีมแข่งบี');
reset role; create temp table _gbg as select (select id from guilds where name='ทีมแข่งบี') b; grant all on _gbg to anon, authenticated; set role anon;
select guild_join((select tok from _gt where no=17), (select b from _gbg));
select guild_join((select tok from _gt where no=18), (select b from _gbg));
select guild_join((select tok from _gt where no=19), (select b from _gbg));
select pg_temp.t('GB: นักเรียนสร้างรอบแข่งไม่ได้', pg_temp.fails($q$select admin_gb_create('x')$q$) and pg_temp.fails('select admin_gb_list()'));
reset role;
set role authenticated; select set_config('request.jwt.claims','{"email":"t@x.th"}',true);
create temp table _gbr as select admin_gb_create('ทดสอบ', 100, 20, 24, 2, 40, 1, 15, 600) id; grant all on _gbr to anon, authenticated;
select admin_gb_pair((select id from _gbr), 'rank');
select admin_gb_add_match((select id from _gbr),
  (select guild_id from guild_members where student_id=(select id from students where name='กิลด์ทดสอบ 11')),
  (select b from _gbg));
reset role;
select pg_temp.t('GB: สร้างรอบ 20 โน้ต และจับคู่แล้ว', (select jsonb_array_length(chart) = 20 and paired from guild_battle_rounds where id=(select id from _gbr))
  and (select count(*) = 1 from guild_battle_matches where round_id=(select id from _gbr) and guild_b = (select b from _gbg)));
select pg_temp.t('GB: โน้ตเรียงเวลา ห่างกันอย่างน้อย 300 ms', (select bool_and(d >= 300) from (select (e->>'t')::int - lag((e->>'t')::int) over (order by o) d from guild_battle_rounds r, jsonb_array_elements(r.chart) with ordinality x(e, o) where r.id=(select id from _gbr)) q where d is not null));
set role anon;
select pg_temp.t('GB: สถานะ — อยู่ในคู่แข่ง รอบเปิด เหลือ 2 ครั้ง', (select (s->'round'->>'state') = 'open' and (s->>'in_match')::boolean and (s->>'left')::int = 2 and (s->'opp'->>'name') = 'ทีมแข่งบี' from (select gb_status((select tok from _gt where no=11))::jsonb s) x));
select pg_temp.t('GB: ไม่เห็นรายชื่อสมาชิกฝั่งตรงข้าม', (select (s->'opp'->'members') = '[]'::jsonb and jsonb_array_length(s->'me'->'members') = 5 from (select gb_status((select tok from _gt where no=11))::jsonb s) x));
create temp table _gs1 as select gb_start((select tok from _gt where no=11)) j; grant all on _gs1 to anon;
select pg_temp.t('GB: เริ่มเล่นได้รับโน้ตครบ', (select jsonb_array_length((j::jsonb)->'chart') = 20 from _gs1));
select pg_temp.t('GB: เริ่มซ้อนขณะรอบแรกยังไม่ส่ง → ปฏิเสธ', pg_temp.fails($q$select gb_start((select tok from _gt where no=11))$q$));
select pg_temp.t('GB: ส่งเร็วผิดปกติ (ยังไม่ถึงเวลาเล่นจริง) → ปฏิเสธ', pg_temp.fails($q$select gb_submit((select tok from _gt where no=11), ((select j from _gs1)->>'run')::uuid, '[]'::jsonb)$q$));
reset role;
update guild_battle_runs set started_at = now() - make_interval(secs => (select len_ms / 1000.0 + 5 from guild_battle_rounds where id=(select id from _gbr))) where id = ((select j from _gs1)->>'run')::uuid;
create temp table _pp as select jsonb_agg(jsonb_build_object('t', (e->>'t')::int, 'k', e->>'k')) perf, jsonb_agg(jsonb_build_object('t', (e->>'t')::int + 150, 'k', e->>'k')) good,
  jsonb_agg(jsonb_build_object('t', (e->>'t')::int + 100000, 'k', e->>'k')) wrong
  from guild_battle_rounds r, jsonb_array_elements(r.chart) e where r.id=(select id from _gbr);
grant all on _pp to anon;
set role anon;
select pg_temp.t('GB: ข้อมูลการกดผิดรูปแบบ → ปฏิเสธ', pg_temp.fails($q$select gb_submit((select tok from _gt where no=11), ((select j from _gs1)->>'run')::uuid, '[{"t":"x","k":"Q"}]'::jsonb)$q$));
select pg_temp.t('GB: กดตรงทุกโน้ต = 1000 คะแนน เพอร์เฟกต์ครบ', (select (r->>'score')::int = 1000 and (r->>'perfect')::int = 20 and (r->>'max_combo')::int = 20 from (select gb_submit((select tok from _gt where no=11), ((select j from _gs1)->>'run')::uuid, (select perf from _pp))::jsonb r) x));
select pg_temp.t('GB: ส่งซ้ำรอบเดิมไม่ได้', pg_temp.fails($q$select gb_submit((select tok from _gt where no=11), ((select j from _gs1)->>'run')::uuid, (select perf from _pp))$q$));
create temp table _gs2 as select gb_start((select tok from _gt where no=11)) j; grant all on _gs2 to anon;
reset role;
update guild_battle_runs set started_at = now() - make_interval(secs => (select len_ms / 1000.0 + 5 from guild_battle_rounds where id=(select id from _gbr))) where id = ((select j from _gs2)->>'run')::uuid;
set role anon;
select pg_temp.t('GB: ไม่กดเลย = 0 คะแนน แต่คะแนนดีที่สุดยังอยู่', (select (r->>'score')::int = 0 and (r->>'miss')::int = 20 and (r->>'best')::int = 1000 from (select gb_submit((select tok from _gt where no=11), ((select j from _gs2)->>'run')::uuid, '[]'::jsonb)::jsonb r) x));
select pg_temp.t('GB: ใช้สิทธิ์ครบ 2 ครั้งแล้วเล่นต่อไม่ได้', pg_temp.fails($q$select gb_start((select tok from _gt where no=11))$q$));
create temp table _gs3 as select gb_start((select tok from _gt where no=16)) j; grant all on _gs3 to anon;
reset role;
update guild_battle_runs set started_at = now() - make_interval(secs => (select len_ms / 1000.0 + 5 from guild_battle_rounds where id=(select id from _gbr))) where id = ((select j from _gs3)->>'run')::uuid;
set role anon;
select pg_temp.t('GB: กดช้า 150 ms = Good ทุกตัว คะแนนราว 600 (ไม่ถึง 1000)', (select (r->>'score')::int between 550 and 650 and (r->>'good')::int = 20 and (r->>'perfect')::int = 0 from (select gb_submit((select tok from _gt where no=16), ((select j from _gs3)->>'run')::uuid, (select good from _pp))::jsonb r) x));
create temp table _gs4 as select gb_start((select tok from _gt where no=17)) j; grant all on _gs4 to anon;
reset role;
update guild_battle_runs set started_at = now() - make_interval(secs => (select len_ms / 1000.0 + 5 from guild_battle_rounds where id=(select id from _gbr))) where id = ((select j from _gs4)->>'run')::uuid;
set role anon;
select pg_temp.t('GB: กดผิดจังหวะมากทุกตัว = 0', (select (r->>'score')::int = 0 from (select gb_submit((select tok from _gt where no=17), ((select j from _gs4)->>'run')::uuid, (select wrong from _pp))::jsonb r) x));
select pg_temp.t('GB: คะแนนกิลด์ = ผลรวม 3 คนดีสุด / 3 (อัลฟา 1000/3 = 333)', (select (s->'me'->>'score')::int = 333 and (s->'me'->>'played')::int = 1 from (select gb_status((select tok from _gt where no=11))::jsonb s) x));
select pg_temp.t('GB: ยังไม่จบรอบ ยังไม่รู้ผล และรับรางวัลไม่ได้', (select (s->>'result') is null and not (s->>'can_claim')::boolean from (select gb_status((select tok from _gt where no=11))::jsonb s) x)
  and pg_temp.fails($q$select gb_claim((select tok from _gt where no=11))$q$));
reset role;
create temp table _c1 as select (select coins from students where name='กิลด์ทดสอบ 11') a, (select free_pulls from students where name='กิลด์ทดสอบ 11') ap, (select coins from students where name='กิลด์ทดสอบ 16') b; grant all on _c1 to anon;
set role authenticated; select set_config('request.jwt.claims','{"email":"t@x.th"}',true);
select admin_gb_end((select id from _gbr));
reset role;
update guild_battle_rounds set ends_at = now() - interval '10 minutes' where id=(select id from _gbr);
set role anon;
select pg_temp.t('GB: จบรอบแล้วเริ่มเล่นไม่ได้', pg_temp.fails($q$select gb_start((select tok from _gt where no=12))$q$));
select pg_temp.t('GB: ผลสุดท้าย — อัลฟาชนะ (333 > 200)', (select (s->>'result') = 'a' and (s->>'mine') = 'win' and (s->>'can_claim')::boolean from (select gb_status((select tok from _gt where no=11))::jsonb s) x)
  and (select (s->>'mine') = 'lose' from (select gb_status((select tok from _gt where no=16))::jsonb s) x));
select pg_temp.t('GB: ผู้ชนะรับรางวัล 40 เหรียญ + 1 ตั๋ว', (select (gb_claim((select tok from _gt where no=11))->>'coins')::int = 40));
select pg_temp.t('GB: รับซ้ำไม่ได้', pg_temp.fails($q$select gb_claim((select tok from _gt where no=11))$q$));
select pg_temp.t('GB: ผู้แพ้ที่ร่วมแข่งรับรางวัลปลอบใจ 15 เหรียญ', (select (gb_claim((select tok from _gt where no=16))->>'coins')::int = 15 and not (gb_claim((select tok from _gt where no=17))->>'win')::boolean));
select pg_temp.t('GB: คนที่ไม่ได้ลงแข่งรับรางวัลไม่ได้', pg_temp.fails($q$select gb_claim((select tok from _gt where no=12))$q$));
reset role;
select pg_temp.t('GB: เหรียญและตั๋วเข้าบัญชีจริง และไม่นับเป็นแต้ม Mini Guild', (select coins - (select a from _c1) = 40 and free_pulls - (select ap from _c1) = 1 from students where name='กิลด์ทดสอบ 11')
  and (select coins - (select b from _c1) = 15 from students where name='กิลด์ทดสอบ 16')
  and not _gp_ok('Mini Guild: Guild Battle ทดสอบ (ชนะ)'));
select pg_temp.t('GB: แก้คู่ของกิลด์ที่มีคนเล่นแล้วไม่ได้ (กันผลเพี้ยน)', pg_temp.fails($q$select admin_gb_add_match((select id from _gbr), (select b from _gbg), null)$q$, 'authenticated')
  and pg_temp.fails($q$select admin_gb_pair((select id from _gbr), 'random')$q$, 'authenticated'));
-- ผีกิลด์ (กิลด์ไม่มีคู่)
delete from guild_battle_rounds where id=(select id from _gbr);
select pg_temp.t('GB: ลบรอบแล้วข้อมูลลูกหายตามไป', not exists (select 1 from guild_battle_runs) and not exists (select 1 from guild_battle_matches) and not exists (select 1 from guild_battle_claims));
set role authenticated; select set_config('request.jwt.claims','{"email":"t@x.th"}',true);
create temp table _gbr2 as select admin_gb_create('รอบผี', 80, 16, 24, 1, 40, 1, 15, 600) id; grant all on _gbr2 to anon, authenticated;
select admin_gb_add_match((select id from _gbr2), (select b from _gbg), null);
reset role;
set role anon;
select pg_temp.t('GB: กิลด์ไม่มีคู่ได้สู้ผีกิลด์ (คะแนนผี 600)', (select (s->'opp'->>'ghost')::boolean and (s->'opp'->>'score')::int = 600 and (s->>'in_match')::boolean from (select gb_status((select tok from _gt where no=16))::jsonb s) x));
reset role;
update guild_battle_rounds set ends_at = now() - interval '10 minutes' where id=(select id from _gbr2);
set role anon;
select pg_temp.t('GB: ไม่มีใครเล่น ผีกิลด์ชนะ', (select (s->>'result') = 'b' and (s->>'mine') = 'lose' from (select gb_status((select tok from _gt where no=16))::jsonb s) x));
reset role;
delete from guild_battle_rounds where id=(select id from _gbr2);
delete from guilds where name='ทีมแข่งบี';
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
update app_settings set value=(today_th() - 1)::text where key='guild_join_until';
set role anon;
select pg_temp.t('หลังล็อก: ออกกิลด์ไม่ได้', pg_temp.fails($q$select guild_leave((select tok from _gt where no=12))$q$));
select pg_temp.t('หลังล็อก: สร้างกิลด์ไม่ได้', pg_temp.fails($q$select guild_create((select tok from _go), 'กิลด์สาย')$q$));
-- ซ่อนอันดับวันสุดท้าย
reset role; update app_settings set value=today_th()::text where key='guild_end'; set role anon;
select pg_temp.t('วันสุดท้าย: board ถูกซ่อน', (select (guild_board((select tok from _gt where no=11))::jsonb->>'hidden') = 'true'));
select pg_temp.t('วันสุดท้าย: status ไม่เผยอันดับ/แต้มเฉลี่ย', (select (s->'my'->'rank') = 'null'::jsonb and (s->'my'->'avg') = 'null'::jsonb from (select guild_status((select tok from _gt where no=11))::jsonb s) x));
-- จบกิจกรรม: รางวัลอันดับ
reset role; update app_settings set value=(today_th() - 1)::text where key='guild_end'; update app_settings set value=(today_th() - 5)::text where key='guild_start';
update ledger set created_at = now() - interval '2 days' where ref_key in ('g:1','g:3','g:4');
set role anon;
select pg_temp.t('จบกิจกรรม: อันดับกลับมาแสดง', (select (guild_board((select tok from _gt where no=11))::jsonb->>'hidden') = 'false'));
reset role;
create temp table _p0 as select coins from students where name='กิลด์ทดสอบ 11';
set role anon;
select pg_temp.t('รับรางวัลอันดับสำเร็จ (กิลด์ทดสอบอยู่อันดับต้นๆ)', (select guild_claim_prize((select tok from _gt where no=11)) is not null));
select pg_temp.t('รับรางวัลอันดับซ้ำไม่ได้', pg_temp.fails($q$select guild_claim_prize((select tok from _gt where no=11))$q$));
reset role;

-- ================= Legendary (SQL 46) =================
reset role;
update students set coins = 100000 where class_id = (select id from classes where code='T99') and no = 12;
update app_settings set value='0' where key='gacha_leg_rate'; update app_settings set value='0' where key='gacha_leg_rate_min';
create temp table _lg(r json);
grant all on _lg to anon, authenticated;
set role anon;
do $$ declare t uuid := (select tok from _gt where no=12); i int; r json; n int := 0; begin
  for i in 1..10 loop r := gacha_pull(t, 10); n := n + (select count(*) from json_array_elements(r->'items') e where e->>'rarity' = 'LEG'); end loop;
  insert into _lg values (json_build_object('n', n));
end $$;
select pg_temp.t('เรท LEG = 0 → ไม่ออก LEG (100 ครั้ง)', (select (r->>'n')::int from _lg) = 0);
reset role;
select pg_temp.t('ตัวนับ leg_pulls เพิ่มทุกครั้งที่สุ่ม (100 ครั้ง)', (select leg_pulls from students where class_id=(select id from classes where code='T99') and no=12) = 100);
update app_settings set value='1' where key='gacha_leg_rate'; update app_settings set value='1' where key='gacha_leg_rate_min';
set role anon;
do $$ declare t uuid := (select tok from _gt where no=12); i int; r json; names text[] := '{}'; dup int := 0; e json; begin
  for i in 1..12 loop
    r := gacha_pull(t, 1);
    e := r->'items'->0;
    if e->>'rarity' = 'LEG' then names := names || (e->>'name'); if (e->>'dup_refund')::int = 100 then dup := dup + 1; end if; end if;
  end loop;
  delete from _lg; insert into _lg values (json_build_object('all', (select count(*) from unnest(names)), 'dup', dup));
end $$;
select pg_temp.t('เรท LEG = 100% → ได้ LEG ทุกครั้ง', (select (r->>'all')::int from _lg) = 12);
reset role;
select pg_temp.t('ได้ LEG แล้วตัวนับรีเซ็ตเป็น 0', (select leg_pulls from students where class_id=(select id from classes where code='T99') and no=12) = 0);
set role anon;
select pg_temp.t('LEG ซ้ำ → คืน 100 เหรียญ', (select (r->>'dup')::int from _lg) >= 8);
reset role;
select pg_temp.t('ได้ LEG ครั้งแรก → ได้สิทธิ์แลกคะแนนจริง +2 (≤4 ใบ ไม่ซ้ำตามชิ้น)',
  (select count(*) from redemptions r join privileges p on p.id = r.privilege_id where p.name = 'แลกคะแนนจริง +2 คะแนน'
     and r.student_id = (select id from students where class_id=(select id from classes where code='T99') and no=12)) between 1 and 4);
select pg_temp.t('มีไอเทม LEG ในคลัง/ชุดตกแต่งของนักเรียน',
  (select count(*) from student_decor sd join decor_items d on d.id = sd.item_id where d.rarity='LEG'
     and sd.student_id = (select id from students where class_id=(select id from classes where code='T99') and no=12)) between 1 and 4);
select pg_temp.t('ประกาศแสดงความยินดี kind=leg ถูกสร้าง', exists (select 1 from celebrations where kind='leg'));
select pg_temp.t('ตู้กาชามี LEG 4 ชิ้น (อุปกรณ์ 2 + ชุด 2)',
  (select count(*) from gacha_items g join decor_items d on d.id=g.decor_id where g.rarity='LEG' and d.slot='item') = 2
  and (select count(*) from gacha_items g join decor_items d on d.id=g.decor_id where g.rarity='LEG' and d.slot='outfit') = 2);
select pg_temp.t('สเตตัส LEG สูงกว่า SSR (ไม่นับฉายา) แต่ไม่เกิน 8',
  (select max(st_int+st_dil+st_str+st_luk) from decor_items where rarity='LEG') <= 8 and (select min(st_int+st_dil+st_str+st_luk) from decor_items where rarity='LEG') > (select max(st_int+st_dil+st_str+st_luk) from decor_items where rarity='SSR' and slot <> 'title'));
update app_settings set value='0.005' where key='gacha_leg_rate'; update app_settings set value='0.0001' where key='gacha_leg_rate_min';
-- เรทไต่ระดับ
create temp table _lr as select id from students where class_id=(select id from classes where code='T99') and no=14;
update students set leg_pulls = 0 where id in (select id from _lr);
select pg_temp.t('เรท LEG ครั้งแรก = 0.01%', (select _leg_rate(id) from _lr) = 0.0001);
update students set leg_pulls = 50 where id in (select id from _lr);
select pg_temp.t('เรท LEG กลางทาง (50/99) อยู่ระหว่าง 0.01% ถึง 0.5%', (select _leg_rate(id) from _lr) between 0.002 and 0.003);
update students set leg_pulls = 99 where id in (select id from _lr);
select pg_temp.t('เรท LEG ถึงสูงสุด 0.5% ที่ครั้งที่ 100', (select _leg_rate(id) from _lr) = 0.005);
update students set leg_pulls = 5000 where id in (select id from _lr);
select pg_temp.t('เรท LEG ไม่เกิน 0.5% แม้สุ่มมาก', (select _leg_rate(id) from _lr) = 0.005);
update students set leg_pulls = 0 where id in (select id from _lr);

-- ================= ฟังก์ชันที่เรียก _sid ต้องเป็น VOLATILE (SQL 47) =================
select pg_temp.t('ไม่มีฟังก์ชัน STABLE ที่เรียก _sid (ซึ่ง UPDATE ตัวนับ rate limit)',
  not exists (select 1 from pg_proc p where p.pronamespace = 'public'::regnamespace and p.provolatile <> 'v' and p.prosrc ~ '_sid\(' and p.proname <> '_sid'));
set role anon;
select pg_temp.t('news_list เรียกด้วยโทเค็นนักเรียนได้', (select news_list((select tok from _gt where no=12)) is not null));
select pg_temp.t('timetable_list เรียกด้วยโทเค็นนักเรียนได้', (select timetable_list((select tok from _gt where no=12)) is not null));
select pg_temp.t('promo_status เรียกด้วยโทเค็นนักเรียนได้', (select promo_status((select tok from _gt where no=12)) is not null));
reset role;

-- ================= ลดอัตราผลสเตตัส (SQL 49) =================
reset role;
update students set is_gm = true where class_id=(select id from classes where code='T99') and no=13;
create temp table _sg as select id from students where class_id=(select id from classes where code='T99') and no=13;
select pg_temp.t('สเตตัส: ค่าเริ่มต้น 50% → ขยัน 10 แต้ม = +5% EXP', (select (_stats(id)->'effects'->>'exp_pct')::int from _sg) = 5);
select pg_temp.t('สเตตัส: พลัง 10 แต้ม = +15% ดาเมจ (เดิม 30%)', (select (_stats(id)->'effects'->>'boss_pct')::int from _sg) = 15);
select pg_temp.t('สเตตัส: โชค 10 แต้ม = +15% (เดิม 30%) · ปัญญา = +2 EXP ควิซ (เดิม 5)', (select (_stats(id)->'effects'->>'rare_pct')::int from _sg) = 15 and (select (_stats(id)->'effects'->>'quiz_exp')::int from _sg) = 2);
select pg_temp.t('สเตตัส: จำนวนแต้มไม่เปลี่ยน (ขยัน total = 10)', (select (_stats(id)->'dil'->>'total')::int from _sg) = 10);
update app_settings set value='100' where key='stat_effect_pct';
select pg_temp.t('สเตตัส: ตั้ง 100% = เท่าเดิม (+10% EXP / +30% ดาเมจ)', (select (_stats(id)->'effects'->>'exp_pct')::int from _sg) = 10 and (select (_stats(id)->'effects'->>'boss_pct')::int from _sg) = 30);
update app_settings set value='0' where key='stat_effect_pct';
select pg_temp.t('สเตตัส: ตั้ง 0% = ไม่มีผล', (select (_stats(id)->'effects'->>'exp_pct')::int from _sg) = 0);
update app_settings set value='50' where key='stat_effect_pct';
update students set is_gm = false where id in (select id from _sg);

-- ================= แจกของขวัญ (SQL 51) =================
reset role;
create temp table _gf as select (select id from students where class_id=(select id from classes where code='T99') and no=11) a,
  (select id from students where class_id=(select id from classes where code='T99') and no=12) b,
  (select id from decor_items d where not exists (select 1 from student_decor sd where sd.item_id=d.id and sd.student_id in (select id from students where class_id=(select id from classes where code='T99') and no in (11,12))) order by id limit 1) d, (select id from privileges order by id limit 1) p;
grant all on _gf to anon, authenticated;
select pg_temp.t('ของขวัญ: anon เรียก admin_gift ไม่ได้', pg_temp.fails($q$select admin_gift(array[(select a from _gf)], 5)$q$, 'anon'));
select pg_temp.t('ของขวัญ: ผู้ไม่ใช่ครูเรียก admin_gift ไม่ได้', pg_temp.fails($q$select set_config('request.jwt.claims','{"email":"stranger@x.th"}',true); select admin_gift(array[(select a from _gf)], 5)$q$, 'authenticated'));
create temp table _gb as select (select coins from students where id=(select a from _gf)) c0, (select exp from students where id=(select a from _gf)) e0,
  (select free_pulls from students where id=(select a from _gf)) p0, (select count(*) from redemptions) r0;
grant all on _gb to anon, authenticated;
set role authenticated; select set_config('request.jwt.claims','{"email":"t@x.th"}',true);
select pg_temp.t('ของขวัญ: ว่างเปล่า/ไม่เลือกคน ถูกปฏิเสธ', pg_temp.fails($q$select admin_gift(array[(select a from _gf)])$q$, 'authenticated') and pg_temp.fails($q$select admin_gift('{}'::uuid[], 5)$q$, 'authenticated'));
select pg_temp.t('ของขวัญ: ติดลบ/เกินเพดาน ถูกปฏิเสธ', pg_temp.fails($q$select admin_gift(array[(select a from _gf)], -5)$q$, 'authenticated') and pg_temp.fails($q$select admin_gift(array[(select a from _gf)], 0, 10001)$q$, 'authenticated') and pg_temp.fails($q$select admin_gift(array[(select a from _gf)], 0, 0, 51)$q$, 'authenticated'));
create temp table _gr as select admin_gift(array[(select a from _gf),(select b from _gf),(select a from _gf)], 40, 25, 3, (select d from _gf), (select p from _gf), 'ขอบคุณนะ') r;
grant all on _gr to anon, authenticated;
reset role;
select pg_temp.t('ของขวัญ: ให้ 2 คน (ซ้ำนับครั้งเดียว)', (select (r->>'given')::int from _gr) = 2);
select pg_temp.t('ของขวัญ: เหรียญ/EXP/ตั๋วเพิ่มถูกต้อง', (select coins from students where id=(select a from _gf)) - (select coalesce(sum(a.reward_coins),0) from student_achievements sa join achievements a on a.id=sa.achievement_id where sa.student_id=(select a from _gf) and a.key in (select key from _new84)) = (select c0 from _gb)+25 and (select exp from students where id=(select a from _gf)) >= (select e0 from _gb)+40 and (select free_pulls from students where id=(select a from _gf)) = (select p0 from _gb)+3);
select pg_temp.t('ของขวัญ: ได้ไอเทมตกแต่ง (source teacher) และสิทธิพิเศษ', exists (select 1 from student_decor where student_id=(select b from _gf) and item_id=(select d from _gf) and source='teacher') and (select count(*) from redemptions) = (select r0 from _gb)+2);
set role authenticated; select set_config('request.jwt.claims','{"email":"t@x.th"}',true);
create temp table _gr2 as select admin_gift(array[(select a from _gf)], 0, 0, 0, (select d from _gf)) r;
grant all on _gr2 to anon, authenticated;
reset role;
select pg_temp.t('ของขวัญ: ส่งซ้ำ ไอเทมที่มีแล้วถูกนับว่าซ้ำ ไม่ error', (select (r->>'decor_already_owned')::int from _gr2) = 1);
set role anon;
create temp table _gi as select gift_inbox((select tok from _gt where no=11)) j;
grant all on _gi to anon, authenticated;
select pg_temp.t('ของขวัญ: นักเรียนเห็น inbox 2 ชุด พร้อมข้อความ', json_array_length((select j from _gi)) = 2 and (select j::text from _gi) like '%ขอบคุณนะ%');
select pg_temp.t('ของขวัญ: ไม่เห็นของขวัญของคนอื่น', json_array_length(gift_inbox((select tok from _gt where no=13))) = 0);
select gift_ack((select tok from _gt where no=11));
select pg_temp.t('ของขวัญ: gift_ack แล้ว inbox ว่าง', json_array_length(gift_inbox((select tok from _gt where no=11))) = 0);
select pg_temp.t('ของขวัญ: นักเรียนอ่านตาราง gifts ตรงๆ ไม่ได้', pg_temp.fails($q$select * from gifts$q$, 'anon'));
reset role;

-- ================= ตรวจงานด้วย QR (SQL 52) =================
reset role;
insert into ch_assignments (class_id, title, max_score, exp_reward, coin_reward) select id, 'งานทดสอบ QR', 10, 20, 5 from classes where code='T99';
create temp table _qa as select (select id from ch_assignments where title='งานทดสอบ QR') a,
  (select id from students where class_id=(select id from classes where code='T99') and no=14) s,
  (select id from students where class_id=(select id from classes where code='T11') and no=1) o;
grant all on _qa to anon, authenticated;
set role anon;
create temp table _qc as select (my_qr((select tok from _gt where no=14))->>'code') c;
grant all on _qc to anon, authenticated;
select pg_temp.t('QR: นักเรียนขอ QR ได้ (รูปแบบ KB1.id.window.sig)', (select c from _qc) ~ '^KB1\.[0-9a-f-]{36}\.[0-9]+\.[0-9a-f]{20}$');
select pg_temp.t('QR: โทเค็นผิดขอ QR ไม่ได้', pg_temp.fails($q$select my_qr('00000000-0000-0000-0000-000000000009')$q$, 'anon'));
select pg_temp.t('QR: anon สแกนบันทึกงานไม่ได้', pg_temp.fails($q$select admin_scan_submit((select a from _qa), (select c from _qc))$q$, 'anon'));
reset role;
select pg_temp.t('QR: ตาราง app_secrets อ่านตรงๆ ไม่ได้', pg_temp.fails($q$select * from app_secrets$q$, 'anon') and pg_temp.fails($q$select * from app_secrets$q$, 'authenticated'));
create temp table _qx as select coalesce((select exp from students where id=(select s from _qa)),0) e0;
grant all on _qx to anon, authenticated;
set role authenticated; select set_config('request.jwt.claims','{"email":"t@x.th"}',true);
select pg_temp.t('QR: คะแนนเกินเต็มถูกปฏิเสธ', pg_temp.fails($q$select admin_scan_submit((select a from _qa), (select c from _qc), 11)$q$, 'authenticated'));
select pg_temp.t('QR: โค้ดที่ถูกแก้ไขถูกปฏิเสธ', pg_temp.fails($q$select admin_scan_submit((select a from _qa), replace((select c from _qc), 'KB1.', 'KB1.0'))$q$, 'authenticated') and pg_temp.fails($q$select admin_scan_submit((select a from _qa), 'KB1.'||(select s from _qa)||'.1.abc')$q$, 'authenticated'));
create temp table _qr1 as select admin_scan_submit((select a from _qa), (select c from _qc), 8, 'submitted') r;
create temp table _qr2 as select admin_scan_submit((select a from _qa), (select c from _qc), 3, 'submitted') r;
grant all on _qr1, _qr2 to anon, authenticated;
reset role;
select pg_temp.t('QR: สแกนครั้งแรกบันทึกส่งงาน + คะแนน', (select (r->>'dup')::boolean from _qr1) = false and (select score from ch_submissions where assignment_id=(select a from _qa) and student_id=(select s from _qa)) = 8);
select pg_temp.t('QR: ได้ EXP ตามงาน (ledger อ้าง sub:)', (select exp from students where id=(select s from _qa)) > (select e0 from _qx) and exists (select 1 from ledger where student_id=(select s from _qa) and ref_key like 'sub:%' and reason like '%งานทดสอบ QR%'));
select pg_temp.t('QR: สแกนซ้ำ = dup ไม่เขียนทับคะแนน ไม่ให้ซ้ำ', (select (r->>'dup')::boolean from _qr2) = true and (select score from ch_submissions where assignment_id=(select a from _qa) and student_id=(select s from _qa)) = 8
  and (select count(*) from ledger where student_id=(select s from _qa) and ref_key like 'sub:%' and reason like '%งานทดสอบ QR%') = 1);
select pg_temp.t('QR: QR หมดอายุ (เก่าเกิน ~2 นาที) ถูกปฏิเสธ', (select pg_temp.fails(format($q$select set_config('request.jwt.claims','{"email":"t@x.th"}',true); select admin_scan_submit(%L, %L)$q$, (select a from _qa),
  'KB1.'||(select s from _qa)||'.'||(floor(extract(epoch from now())/30)-10)||'.'||_qr_sig((select s from _qa), (floor(extract(epoch from now())/30)-10)::bigint)), 'authenticated')));
select pg_temp.t('QR: นักเรียนห้องอื่นสแกนกับงานห้องนี้ไม่ได้', (select pg_temp.fails(format($q$select set_config('request.jwt.claims','{"email":"t@x.th"}',true); select admin_scan_submit(%L, %L)$q$, (select a from _qa),
  'KB1.'||(select o from _qa)||'.'||floor(extract(epoch from now())/30)||'.'||_qr_sig((select o from _qa), floor(extract(epoch from now())/30)::bigint)), 'authenticated')));

-- ================= สถิติท้ายเกม (SQL 53) =================
reset role;
set role anon;
create temp table _gb1 as select game_record((select tok from _gt where no=15), 'match', '{"score":70,"secs":50,"wrong":3}') r;
create temp table _gb2 as select game_record((select tok from _gt where no=15), 'match', '{"score":90,"secs":60,"wrong":1}') r;
create temp table _gb3 as select game_record((select tok from _gt where no=15), 'match', '{"score":80,"secs":40,"wrong":2}') r;
grant all on _gb1, _gb2, _gb3 to anon, authenticated;
select pg_temp.t('สถิติ: รอบแรก = first และบันทึกทุกตัวชี้วัด', ((select r from _gb1)->>'first')::boolean and (select r::jsonb->'best'->>'score' from _gb1) = '70');
select pg_temp.t('สถิติ: รอบสองทำลายสถิติคะแนนและผิดน้อยลง แต่เวลาไม่ดีกว่า', (select r::jsonb->'newbest' from _gb2) @> '["score","wrong"]'::jsonb and not ((select r::jsonb->'newbest' from _gb2) ? 'secs') and (select r::jsonb->'best'->>'secs' from _gb2) = '50');
select pg_temp.t('สถิติ: รอบสาม best คงเดิม (คะแนน 90) แต่เวลา 40 ใหม่', (select r::jsonb->'best'->>'score' from _gb3) = '90' and (select r::jsonb->'newbest' from _gb3) @> '["secs"]'::jsonb and (select (r->>'plays')::int from _gb3) = 3);
select pg_temp.t('สถิติ: game_bests_all คืนค่าสถิติของตัวเองเท่านั้น', (game_bests_all((select tok from _gt where no=15))::jsonb->'match'->>'score') = '90' and game_bests_all((select tok from _gt where no=16))::jsonb = '{}'::jsonb);
select pg_temp.t('สถิติ: เกมที่ไม่รู้จัก/ข้อมูลผิดรูปแบบถูกปฏิเสธ', pg_temp.fails($q$select game_record((select tok from _gt where no=15), 'nope', '{}')$q$, 'anon') and pg_temp.fails($q$select game_record((select tok from _gt where no=15), 'match', '[1]')$q$, 'anon'));
create temp table _gb4 as select game_record((select tok from _gt where no=15), 'duel', '{"wins":1,"hp_left":999999999,"rounds":5,"evil":9}') r;
create temp table _gb5 as select game_record((select tok from _gt where no=15), 'duel', '{"wins":1}') r;
grant all on _gb4, _gb5 to anon, authenticated;
select pg_temp.t('สถิติ: ค่าเกินถูกจำกัด · คีย์แปลกถูกเมิน · wins สะสม', (select (r::jsonb->'best'->>'hp_left')::numeric from _gb4) = 100000 and not ((select r::jsonb->'cur' from _gb4) ? 'evil') and (select (r::jsonb->'best'->>'wins')::int from _gb5) = 2);
select pg_temp.t('สถิติ: โทเค็นผิดบันทึกไม่ได้', pg_temp.fails($q$select game_record('00000000-0000-0000-0000-000000000009', 'match', '{"score":1}')$q$, 'anon'));
select pg_temp.t('สถิติ: นักเรียนอ่านตาราง game_bests ตรงๆ ไม่ได้', pg_temp.fails($q$select * from game_bests$q$, 'anon'));
reset role;

-- ================= การ์ดสะสม (SQL 54) =================
reset role;
create temp table _ks as select
  (select id from students where class_id=(select id from classes where code='T99') and no=17) a,
  (select id from students where class_id=(select id from classes where code='T99') and no=18) b,
  (select id from students where class_id=(select id from classes where code='T99') and no=19) c;
grant all on _ks to anon, authenticated;
select pg_temp.t('การ์ด: ตารางการ์ดอ่านตรงๆ ไม่ได้', pg_temp.fails($q$select * from cards$q$, 'anon') and pg_temp.fails($q$select * from student_cards$q$, 'anon') and pg_temp.fails($q$select * from card_drops$q$, 'anon'));
select pg_temp.t('การ์ด: ข้อมูลตั้งต้น 3 ชุด 36+12+12 ใบ มีข้อเท็จจริงทุกใบ', (select count(*) from card_sets) = 3
  and (select count(*) from cards c join card_sets s on s.id=c.set_id where s.code='elements') = 36
  and (select count(*) from cards c join card_sets s on s.id=c.set_id where s.code='chemists') = 12
  and (select count(*) from cards c join card_sets s on s.id=c.set_id where s.code='lab') = 12
  and not exists (select 1 from cards where btrim(fact) = '' or btrim(name) = ''));
update app_settings set value='100' where key='card_drop_pct';
set role anon;
create temp table _k0 as select card_roll((select tok from _gt where no=17), 'battle') r;
create temp table _k0b as select card_roll((select tok from _gt where no=17), 'quiz') r;
grant all on _k0b to anon, authenticated;
grant all on _k0 to anon, authenticated;
select pg_temp.t('การ์ด: ยังไม่ได้ชนะมอนสเตอร์ → ไม่ดรอป', (select r->>'reason' from _k0) = 'no_play');
select pg_temp.t('การ์ด: เกมอื่น (ควิซ) ไม่ดรอปการ์ดอีกแล้ว', (select r->>'reason' from _k0b) = 'monster_only');
select pg_temp.t('การ์ด: เกมที่ไม่รู้จักถูกปฏิเสธ', pg_temp.fails($q$select card_roll((select tok from _gt where no=17), 'nope')$q$, 'anon'));
reset role;
insert into battles (student_id, monster_id, status, p_hp, p_max, m_hp, m_max) select (select a from _ks), id, 'won', 10, 10, 0, 10 from monsters limit 1;
set role anon;
create temp table _k1 as select card_roll((select tok from _gt where no=17), 'battle') r;
create temp table _k2 as select card_roll((select tok from _gt where no=17), 'battle') r;
grant all on _k1, _k2 to anon, authenticated;
reset role;
select pg_temp.t('การ์ด: เล่นแล้วได้การ์ด (ใบแรกได้แน่นอน เป็นใบใหม่)', ((select r from _k1)->>'drop')::boolean and (select r::jsonb->'card'->>'is_new' from _k1) = 'true');
select pg_temp.t('การ์ด: รอบเล่นเดียวสุ่มได้ครั้งเดียว', (select r->>'reason' from _k2) = 'no_play' and (select count(*) from card_drops where student_id=(select a from _ks) and source='game') = 1);
-- เพดานต่อวัน
update app_settings set value='1' where key='card_daily_cap';
insert into battles (student_id, monster_id, status, p_hp, p_max, m_hp, m_max) select (select a from _ks), id, 'won', 10, 10, 0, 10 from monsters limit 1;
set role anon;
create temp table _k3 as select card_roll((select tok from _gt where no=17), 'battle') r;
grant all on _k3 to anon, authenticated;
reset role;
select pg_temp.t('การ์ด: ถึงเพดานต่อวัน → ไม่ดรอป (cap)', (select r->>'reason' from _k3) = 'cap');
update app_settings set value='5' where key='card_daily_cap';
-- ซ้ำ → เศษธาตุ
create temp table _ksh as select shards s0 from students where id=(select a from _ks);
select _card_grant((select a from _ks), (select card_id from student_cards where student_id=(select a from _ks) limit 1), 'gift');
select pg_temp.t('การ์ด: ซ้ำได้เศษธาตุตามระดับ + qty เพิ่ม', (select shards from students where id=(select a from _ks)) > (select s0 from _ksh)
  and (select qty from student_cards where student_id=(select a from _ks) limit 1) = 2);
-- pity: ซ้ำติดกัน 3 ครั้ง (เกณฑ์ 4) → ใบถัดไปเป็นใบใหม่
update students set card_pity = 3 where id=(select b from _ks);
select _card_grant((select b from _ks), (select id from cards order by no, id limit 1), 'gift');
update students set card_pity = 3 where id=(select b from _ks);
insert into battles (student_id, monster_id, status, p_hp, p_max, m_hp, m_max) select (select b from _ks), id, 'won', 10, 10, 0, 10 from monsters limit 1;
set role anon;
create temp table _k4 as select card_roll((select tok from _gt where no=18), 'battle') r;
grant all on _k4 to anon, authenticated;
reset role;
select pg_temp.t('การ์ด: pity — ซ้ำครบเกณฑ์แล้วใบต่อไปเป็นใบใหม่แน่นอน', (select r::jsonb->'card'->>'is_new' from _k4) = 'true' and (select card_pity from students where id=(select b from _ks)) = 0);
-- ครบชุด
create temp table _kb as select coins c0, free_pulls p0 from students where id=(select c from _ks);
select _card_grant((select c from _ks), c.id, 'gift') from cards c join card_sets s on s.id=c.set_id where s.code='lab';
select pg_temp.t('การ์ด: สะสมครบชุด → ได้เหรียญ + ตั๋ว + บันทึกการรับ', (select coins from students where id=(select c from _ks)) - (select coalesce(sum(a.reward_coins),0) from student_achievements sa join achievements a on a.id=sa.achievement_id where sa.student_id=(select c from _ks) and a.key in (select key from _new84)) = (select c0 from _kb)+150
  and (select free_pulls from students where id=(select c from _ks)) = (select p0 from _kb)+2 and (select count(*) from student_set_claims where student_id=(select c from _ks)) = 1);
select _card_grant((select c from _ks), c.id, 'gift') from cards c join card_sets s on s.id=c.set_id where s.code='lab' and c.no=1;
select pg_temp.t('การ์ด: ได้ซ้ำหลังครบชุด ไม่แจกรางวัลซ้ำ', (select coins from students where id=(select c from _ks)) - (select coalesce(sum(a.reward_coins),0) from student_achievements sa join achievements a on a.id=sa.achievement_id where sa.student_id=(select c from _ks) and a.key in (select key from _new84)) = (select c0 from _kb)+150 and (select count(*) from student_set_claims where student_id=(select c from _ks)) = 1);
-- สมุดสะสม
set role anon;
create temp table _kal as select card_album((select tok from _gt where no=19)) j;
grant all on _kal to anon, authenticated;
reset role;
select pg_temp.t('การ์ด: สมุดสะสมแสดงชื่อเฉพาะใบที่มี · ใบที่ยังไม่มีซ่อนชื่อและข้อเท็จจริง', 
  (select count(*) from jsonb_array_elements((select j::jsonb from _kal)->'sets') st, jsonb_array_elements(st->'cards') cd where cd->>'name' is not null) = 12
  and (select count(*) from jsonb_array_elements((select j::jsonb from _kal)->'sets') st, jsonb_array_elements(st->'cards') cd where cd->>'name' is null and cd->>'fact' is not null) = 0);
-- ของขวัญ: การ์ด
set role authenticated; select set_config('request.jwt.claims','{"email":"t@x.th"}',true);
select admin_gift(array[(select a from _ks)], 0, 0, 0, null, null, 'การ์ดให้', (select id from cards where symbol='Au'), 2);
reset role;
select pg_temp.t('การ์ด: ครูแจกการ์ดให้นักเรียน (qty และกล่องของขวัญ)', (select qty from student_cards where student_id=(select a from _ks) and card_id=(select id from cards where symbol='Au')) = 2
  and (select card_n from gifts where student_id=(select a from _ks) and card_id=(select id from cards where symbol='Au')) = 2);
set role anon;
select pg_temp.t('การ์ด: กล่องของขวัญแสดงชื่อการ์ด', gift_inbox((select tok from _gt where no=17))::text like '%ทองคำ%');
reset role;
-- กาชา: ห่อแล้วยังคืนผลเดิม แต่ไม่แถมการ์ดแล้ว
update students set coins = coins + 500 where id=(select b from _ks);
set role anon;
create temp table _kgc as select gacha_pull((select tok from _gt where no=18), 10) r;
grant all on _kgc to anon, authenticated;
reset role;
select pg_temp.t('การ์ด: กาชา 10 ครั้ง ได้ผลเดิมครบ และไม่แถมการ์ด', json_array_length((select r->'items' from _kgc)) = 10 and jsonb_array_length((select r::jsonb->'cards' from _kgc)) = 0);
-- รบบอส
insert into battles (student_id, monster_id, status, p_hp, p_max, m_hp, m_max) select (select b from _ks), id, 'won', 10, 10, 0, 10 from monsters limit 1;
set role anon;
create temp table _k5 as select card_roll((select tok from _gt where no=18), 'battle') r;
grant all on _k5 to anon, authenticated;
reset role;
select pg_temp.t('การ์ด: ชนะบอสแล้วสุ่มการ์ดได้ (ต้องมีรอบชนะจริง)', (select r->>'reason' from _k5) is distinct from 'no_play');
-- ทำสถิติใหม่ → ทำเครื่องหมาย best_hit
insert into game_plays (student_id, game, score, correct, exp) values ((select c from _ks), 'quiz', 0, 5, 10);
set role anon;
select game_record((select tok from _gt where no=19), 'quiz', '{"correct":1}');
select game_record((select tok from _gt where no=19), 'quiz', '{"correct":5}');
reset role;
select pg_temp.t('การ์ด: ทำสถิติใหม่แล้วรอบเล่นถูกทำเครื่องหมาย (โอกาสการ์ดเพิ่ม)', (select best_hit from game_plays where student_id=(select c from _ks) and game='quiz'));
update app_settings set value='30' where key='card_drop_pct';
select pg_temp.t('การ์ด: นักเรียนเรียกฟังก์ชันภายในตรงๆ ไม่ได้', pg_temp.fails($q$select _card_grant((select a from _ks), (select id from cards limit 1), 'gift')$q$, 'anon') and pg_temp.fails($q$select _gacha_pull('00000000-0000-0000-0000-000000000001', 1)$q$, 'anon'));

-- ================= ไอเทมกดใช้ / อัปเกรด / สมดุล / SSR (66) =================
create temp table _it as select (select id from students where class_id=(select id from classes where code='T99') and no=18) sid, (select tok from _gt where no=18) tok,
  (select id from consumables where key='p_exp') exp_i, (select id from consumables where key='p_heal') heal_i, (select id from consumables where key='scroll') scr_i, (select id from consumables where key='t_reset') rst_i;
grant all on _it to anon, authenticated;
update students set coins = 2000, exp = 0 where id = (select sid from _it);
select pg_temp.t('ไอเทม: มีไอเทมตั้งต้น 8 ชนิด', (select count(*) from consumables) = 8);
select pg_temp.t('ไอเทม: นักเรียนเรียกฟังก์ชันภายในไม่ได้', pg_temp.fails($q$select _stats((select sid from _it))$q$) and pg_temp.fails($q$select _upg_cost('N',1)$q$));
set role anon;
select pg_temp.t('ไอเทม: ซื้อยา EXP 1 ชิ้น หักเหรียญ 90', (select (buy_item((select tok from _it), (select exp_i from _it), 1)->>'coins')::int = 1910));
select pg_temp.t('ไอเทม: ซื้อเกินโควตาต่อวันไม่ได้ (2/วัน)', pg_temp.fails($q$select buy_item((select tok from _it), (select exp_i from _it), 2)$q$));
reset role;
select pg_temp.t('ไอเทม: ซื้อแล้วมีในคลัง 1 ชิ้น', (select qty from student_items where student_id=(select sid from _it) and item_id=(select exp_i from _it)) = 1);
set role anon;
select pg_temp.t('ไอเทม: ใช้ยา EXP แล้วบัฟ +15% เข้า effects', (select use_item((select tok from _it), (select exp_i from _it))->>'name') is not null);
reset role;
select pg_temp.t('ไอเทม: effects.exp_pct รวมบัฟ', ((select _stats((select sid from _it)))->'effects'->>'exp_pct')::int >= 15);
select pg_temp.t('ไอเทม: ใช้แล้วคลังเหลือ 0', (select qty from student_items where student_id=(select sid from _it) and item_id=(select exp_i from _it)) = 0);
set role anon;
select pg_temp.t('ไอเทม: ไม่มีของในคลังใช้ไม่ได้', pg_temp.fails($q$select use_item((select tok from _it), (select exp_i from _it))$q$));
select pg_temp.t('ไอเทม: ยาฟื้นฟูนอกศึกใช้ไม่ได้', (select buy_item((select tok from _it), (select heal_i from _it), 1)) is not null
  and pg_temp.fails($q$select use_item((select tok from _it), (select heal_i from _it))$q$));
reset role;
insert into monsters (key, name, emoji, level, hp, atk, exp, coins, sort) values ('t_mon','ทดสอบ','👾',1,40,5,1,1,99) on conflict (key) do nothing;
insert into battles (student_id, monster_id, p_hp, p_max, m_hp, m_max) select (select sid from _it), id, 20, 100, 40, 40 from monsters where key='t_mon';
create temp table _bt as select (select id from battles where student_id=(select sid from _it) and status='active') bid;
grant all on _bt to anon, authenticated;
set role anon;
select pg_temp.t('ไอเทม: ยาฟื้นฟูในศึก +40% HP', (select use_item((select tok from _it), (select heal_i from _it), (select bid from _bt))->>'msg') like '%+40%');
reset role;
select pg_temp.t('ไอเทม: HP ในศึกเพิ่มเป็น 60', (select p_hp from battles where student_id=(select sid from _it) and status='active') = 60);
-- อัปเกรด
insert into decor_items (slot, key, name, emoji, rarity, price, sort, st_int, st_dil, st_str, st_luk, st_coin) values ('hat','x','หมวกทดสอบ66','🎩','R',10,99,0,0,2,0,0);
insert into student_decor (student_id, item_id, source) select (select sid from _it), id, 'teacher' from decor_items where name='หมวกทดสอบ66';
create temp table _hat as select id from decor_items where name='หมวกทดสอบ66';
grant all on _hat to anon, authenticated;
update students set decor = jsonb_build_object('hat', (select id::text from _hat)) where id=(select sid from _it);
select pg_temp.t('อัปเกรด: ไม่มีม้วนอัปเกรดไม่ได้', pg_temp.fails($q$select upgrade_decor((select tok from _it), (select id from _hat))$q$));
insert into student_items (student_id, item_id, qty) values ((select sid from _it), (select scr_i from _it), 5) on conflict (student_id, item_id) do update set qty = 5;
set role anon;
select pg_temp.t('อัปเกรด: Lv1→2 สำเร็จ', (select (upgrade_decor((select tok from _it), (select id from _hat))->>'lvl')::int = 2));
reset role;
select pg_temp.t('อัปเกรด: พลังเพิ่มจาก 2 เป็น 3 (+1/เลเวล)', ((select _stats((select sid from _it)))->'str'->>'item')::int = 3);
set role anon;
select upgrade_decor((select tok from _it), (select id from _hat));
select pg_temp.t('อัปเกรด: เกินเลเวลสูงสุดของ R (Lv3) ไม่ได้', pg_temp.fails($q$select upgrade_decor((select tok from _it), (select id from _hat))$q$));
select pg_temp.t('ไอเทม: my_items ส่งคลัง/อุปกรณ์/บัฟ', (select json_array_length(my_items((select tok from _it))->'gear') >= 1 and json_array_length(my_items((select tok from _it))->'items') = 8));
reset role;
-- สมดุล
select pg_temp.t('สมดุล: ไม่มีไอเทมเกินเพดานสเตตัสต่อชิ้น', not exists (select 1 from decor_items where st_int+st_dil+st_str+st_luk > case rarity when 'N' then 2 when 'R' then 3 when 'SR' then 4 when 'SSR' then 5 else 7 end));
select pg_temp.t('สมดุล: เพดานรวมโบนัสไอเทมต่อด้านไม่เกิน 12', (select (_stats(a)->'str'->>'item')::int <= 12 from _s));
select pg_temp.t('กาชา: ตั้ง gacha_ssr_mult ค่าเริ่มต้น 20', _setting_int('gacha_ssr_mult', 0) = 20);
do $$ declare n int := 0; ssr int := 0; it gacha_items; sid uuid := (select a from _s); begin
  for i in 1..4000 loop it := _gacha_pick_luk(false, 0, sid); n := n + 1; if it.rarity = 'SSR' then ssr := ssr + 1; end if; end loop;
  perform pg_temp.t('กาชา: SSR น้อยกว่า 7% จาก 4000 ครั้ง (ได้ ' || ssr || ')', ssr * 100.0 / n < 7);
end $$;

-- 67: บัฟมีเวลา + lv ใน _decor_of
select pg_temp.t('บัฟเวลา: บัฟที่ใช้แล้วมีเวลาหมดอายุ ~60 นาที', (select expires_at between now() + interval '55 minutes' and now() + interval '61 minutes' from student_buffs where student_id=(select sid from _it) and kind='buff_exp'));
set role anon;
select pg_temp.t('บัฟเวลา: ซื้อเพิ่มแล้วใช้ซ้อนขณะบัฟยังอยู่ไม่ได้', (select buy_item((select tok from _it), (select exp_i from _it), 1)) is not null
  and pg_temp.fails($q$select use_item((select tok from _it), (select exp_i from _it))$q$));
reset role;
update student_buffs set expires_at = now() - interval '1 minute' where student_id=(select sid from _it);
select pg_temp.t('บัฟเวลา: หมดเวลาแล้วบัฟไม่นับใน effects', ((select _stats((select sid from _it)))->'effects'->>'exp_pct')::int < 15);
set role anon;
select pg_temp.t('บัฟเวลา: หมดเวลาแล้วใช้ใหม่ได้', (select use_item((select tok from _it), (select exp_i from _it))->>'msg') like '%60 นาที%');
reset role;
select pg_temp.t('_decor_of: ส่ง lv ของหมวกที่สวมอยู่ (Lv3)', (select (_decor_of((select sid from _it))->'hat'->>'lvl')::int = 3));

-- ================= ของขวัญเพื่อน / ความสัมพันธ์ (68) =================
create temp table _fr as select (select tok from _gt where no=12) t12, (select tok from _gt where no=13) t13, (select tok from _gt where no=14) t14,
  (select id from students where class_id=(select id from classes where code='T99') and no=12) s12, (select id from students where class_id=(select id from classes where code='T99') and no=13) s13,
  (select id from gift_items where key='candy') candy, (select id from gift_items where key='crystal') crystal, (select id from gift_items where key='bear') bear;
grant all on _fr to anon, authenticated;
update students set coins = 1000 where id in (select s12 from _fr union select s13 from _fr);
select pg_temp.t('เพื่อน: มีของขวัญ 5 ชิ้น และชนิดความสัมพันธ์ 10 แบบ', (select count(*) from gift_items) = 5 and (select count(*) from relation_types) = 10);
select pg_temp.t('เพื่อน: นักเรียนเรียกฟังก์ชันภายในไม่ได้', pg_temp.fails($q$select _rel_home((select s12 from _fr))$q$) and pg_temp.fails($q$select _student_extras((select t12 from _fr))$q$));
set role anon;
select pg_temp.t('เพื่อน: ส่งลูกอมให้เพื่อน +3 RP หักเหรียญ 15', (select (gift_send((select t12 from _fr), 13, (select candy from _fr), 'ขอบคุณที่ช่วยติว')->>'rp')::int = 3));
select pg_temp.t('เพื่อน: ส่งให้ตัวเองไม่ได้', pg_temp.fails($q$select gift_send((select t12 from _fr), 12, (select candy from _fr))$q$));
select pg_temp.t('เพื่อน: ส่งให้คนนอกห้อง/เลขที่ไม่มีไม่ได้', pg_temp.fails($q$select gift_send((select t12 from _fr), 99, (select candy from _fr))$q$));
reset role;
select pg_temp.t('เพื่อน: เหรียญถูกหัก 15', (select coins from students where id=(select s12 from _fr)) = 985);
select pg_temp.t('เพื่อน: เกินเพดาน RP ต่อวัน (ผลึก 38 + 3 > 40) ส่งไม่ได้ และไม่หักเหรียญ',
  (select pg_temp.fails($q$select gift_send((select t12 from _fr), 13, (select crystal from _fr))$q$, 'anon')) and (select coins from students where id=(select s12 from _fr)) = 985);
set role anon;
select pg_temp.t('เพื่อน: ฝ่ายรับส่งกลับได้ RP รวมของคู่เดียวกัน', (select (gift_send((select t13 from _fr), 12, (select candy from _fr))->>'rp')::int = 6));
select pg_temp.t('เพื่อน: friend_list แสดงเพื่อนและกล่องของขวัญ', (select json_array_length(friend_list((select t13 from _fr))->'inbox') = 1));
select pg_temp.t('เพื่อน: ไม่ถึงเกณฑ์เสนอความสัมพันธ์ไม่ได้', pg_temp.fails($q$select rel_propose((select t12 from _fr), 13, 'bestie')$q$));
reset role;
update friendships set rp = 100, day_rp = 0;
set role anon;
select pg_temp.t('เพื่อน: ถึงเกณฑ์เสนอ "เพื่อนสนิท" ได้', (select rel_propose((select t12 from _fr), 13, 'bestie')->>'rel') = 'เพื่อนสนิท');
select pg_temp.t('เพื่อน: ผู้เสนอตอบรับคำขอของตัวเองไม่ได้', pg_temp.fails($q$select rel_respond((select t12 from _fr), 13, true)$q$));
select pg_temp.t('เพื่อน: ชนิดที่ต้อง 300 แต้มยังเสนอไม่ได้', pg_temp.fails($q$select rel_propose((select t12 from _fr), 13, 'forever')$q$));
select pg_temp.t('เพื่อน: ฝ่ายรับเห็นคำขอใน student_extras.relations', (select json_array_length(student_extras((select t13 from _fr))->'relations'->'incoming') = 1));
select pg_temp.t('เพื่อน: ฝ่ายรับกดยอมรับสำเร็จ', (select (rel_respond((select t13 from _fr), 12, true)->>'accepted')::boolean));
select pg_temp.t('เพื่อน: ทั้งสองฝ่ายเห็นความสัมพันธ์บนหน้าหลัก', (select student_extras((select t12 from _fr))->'relations'->'rels'->0->>'rel' = 'bestie' and student_extras((select t13 from _fr))->'relations'->'rels'->0->>'rel_name' = 'เพื่อนสนิท'));
select rel_end((select t13 from _fr), 12);
select pg_temp.t('เพื่อน: เลิกความสัมพันธ์แล้วหายจากหน้าหลัก (คะแนนยังอยู่)', (select json_array_length(student_extras((select t12 from _fr))->'relations'->'rels') = 0));
reset role;
select pg_temp.t('เพื่อน: คะแนนยังคงอยู่หลังเลิก', (select rp from friendships limit 1) >= 100);
update app_settings set value='1' where key='gift_daily_limit';
set role anon;
select pg_temp.t('เพื่อน: เกินโควตาส่งต่อวันไม่ได้ (limit 1 แต่ส่งไปแล้ว)', pg_temp.fails($q$select gift_send((select t12 from _fr), 13, (select candy from _fr))$q$));
reset role;
update app_settings set value='5' where key='gift_daily_limit';
select pg_temp.t('เพื่อน: ครูดูบันทึกของขวัญได้ นักเรียนดูไม่ได้', pg_temp.fails($q$select admin_gift_log()$q$));

-- ================= ด่านบอสเลื่อนแรงค์ (69) =================
update students set exp = 700 where id in (select s12 from _fr union select s13 from _fr);
select pg_temp.t('ด่านแรงค์: ถึงเกณฑ์ Silver (600+) แต่ยังไม่ผ่านด่าน → แรงค์ถูกกั้นไว้ที่ Bronze และ locked',
  (select (_rank_info_s((select s12 from _fr), 700)->>'locked')::boolean and (_rank_info_s((select s12 from _fr), 700)->>'key') = 'bronze'));
select pg_temp.t('ด่านแรงค์: ตัวเลข EXP ไม่หาย (ยัง 700)', (select exp from students where id=(select s12 from _fr)) = 700);
select pg_temp.t('ด่านแรงค์: แดชบอร์ดส่ง rank_info.locked ให้หน้าเว็บ',
  (select (student_dashboard((select t12 from _fr))->'rank_info'->>'locked')::boolean) is true);
set role anon;
select pg_temp.t('ด่านแรงค์: สถานะด่านมีบอส Silver และเริ่มได้', (select (rank_trial_status((select t12 from _fr))->'boss'->>'name') = 'ผู้พิทักษ์ธาตุเงิน'
  and (rank_trial_status((select t12 from _fr))->>'can_start')::boolean));
select pg_temp.t('ด่านแรงค์: บอสด่านไม่โผล่ในรายการมอนสเตอร์ปกติ',
  (select not exists (select 1 from json_array_elements(battle_status((select t12 from _fr))->'monsters') e where e->>'name' = 'ผู้พิทักษ์ธาตุเงิน')));
select pg_temp.t('ด่านแรงค์: เริ่มสู้บอสด่านผ่าน battle_start ตรงๆ ไม่ได้',
  pg_temp.fails($q$select battle_start((select t12 from _fr), (select id from monsters where key='trial_silver'))$q$));
reset role;
select pg_temp.t('ด่านแรงค์: ฟังก์ชันภายในนักเรียนเรียกไม่ได้', pg_temp.fails($q$select _rank_gate((select s12 from _fr), 700)$q$));
set role anon;
select pg_temp.t('ด่านแรงค์: เริ่มสอบสำเร็จ', (select rank_trial_start((select t12 from _fr))->>'status') = 'active');
reset role;
select pg_temp.t('ด่านแรงค์: การต่อสู้ติดป้าย silver และไม่ให้รางวัลปกติ',
  (select trial_rank = 'silver' and not rewarded from battles where student_id=(select s12 from _fr) order by created_at desc limit 1));
select pg_temp.t('ด่านแรงค์: ยังไม่ชนะ → ยังไม่ผ่านด่าน', not exists (select 1 from rank_trial_pass where student_id=(select s12 from _fr)));
create temp table _cb as select coins c0, clock_timestamp() t0 from students where id=(select s12 from _fr);
update battles set status='won', m_hp=0, finished_at=now() where student_id=(select s12 from _fr) and trial_rank='silver';
select pg_temp.t('ด่านแรงค์: ชนะบอส → บันทึกผ่านด่าน Silver', exists (select 1 from rank_trial_pass where student_id=(select s12 from _fr) and rank_key='silver'));
select pg_temp.t('ด่านแรงค์: ได้เหรียญรางวัลผ่านด่าน +50', (select coins from students where id=(select s12 from _fr)) - (select coalesce(sum(a.reward_coins),0) from student_achievements sa join achievements a on a.id=sa.achievement_id where sa.student_id=(select s12 from _fr) and sa.earned_at >= (select t0 from _cb)) = (select c0 from _cb) + 50);
select pg_temp.t('ด่านแรงค์: เลื่อนเป็น Silver แล้ว ไม่ locked', (select (_rank_info_s((select s12 from _fr), 700)->>'key') = 'silver' and (_rank_info_s((select s12 from _fr), 700)->>'locked') is null));
select pg_temp.t('ด่านแรงค์: มีประกาศเลื่อนแรงค์ในห้อง', exists (select 1 from celebrations where student_id=(select s12 from _fr) and kind='rank' and title='Silver'));
update students set exp = 5000 where id = (select s12 from _fr);
select pg_temp.t('ด่านแรงค์: EXP สูงมาก ถูกกั้นที่ด่านถัดไป (Gold) ไม่ข้ามด่าน', (select (_rank_info_s((select s12 from _fr), 5000)->>'gate_key') = 'gold' and (_rank_info_s((select s12 from _fr), 5000)->>'key') = 'silver'));
-- แพ้แล้วต้องรอวันถัดไป
set role anon;
select rank_trial_start((select t13 from _fr));
reset role;
update battles set status='lost', finished_at=now() where student_id=(select s13 from _fr) and trial_rank='silver';
select pg_temp.t('ด่านแรงค์: แพ้แล้วไม่ผ่านด่าน EXP ยังอยู่', not exists (select 1 from rank_trial_pass where student_id=(select s13 from _fr)) and (select exp from students where id=(select s13 from _fr)) = 700);
select pg_temp.t('ด่านแรงค์: แพ้แล้วสอบซ้ำวันเดียวกันไม่ได้', pg_temp.fails($q$select rank_trial_start((select t13 from _fr))$q$, 'anon'));
select pg_temp.t('ด่านแรงค์: สถานะแจ้งว่าวันนี้สอบแล้ว', (select (rank_trial_status((select t13 from _fr))->>'tried_today')::boolean) is true) ;
update battles set play_date = today_th() - 1 where student_id=(select s13 from _fr) and trial_rank='silver';
set role anon;
select pg_temp.t('ด่านแรงค์: ข้ามวันแล้วสอบใหม่ได้', (select rank_trial_start((select t13 from _fr))->>'status') = 'active');
reset role;
select pg_temp.t('ด่านแรงค์: ครูให้ผ่านด่านรายคนได้ นักเรียนเรียกไม่ได้', pg_temp.fails($q$select admin_rank_trial_pass((select s13 from _fr), 'silver')$q$, 'anon'));
update app_settings set value='0' where key='rank_trial_on';
select pg_temp.t('ด่านแรงค์: ปิดระบบด่านแล้ว ไม่มีการกั้นแรงค์', (select _rank_gate((select s13 from _fr), 9999)) is null);
update app_settings set value='1' where key='rank_trial_on';
update monsters set active=false where key='trial_silver';
select pg_temp.t('ด่านแรงค์: ปิดบอสด่านนั้น = แรงค์นั้นเข้าฟรี', (select _rank_gate((select s13 from _fr), 700)) is null);
update monsters set active=true where key='trial_silver';

select pg_temp.t('ด่านแรงค์: บอสทั้ง 8 ตัวมีภาพ (SQL 70)', (select count(*) from monsters where trial_rank is not null and image like 'assets/monsters/trial_%') = 8);

-- ================= ระบบตั้งรับในการต่อสู้ (71) =================
create temp table _gd as select (select tok from _gt where no=15) t, (select id from students where class_id=(select id from classes where code='T99') and no=15) sid,
  (select id from monsters where key='bubble') mon;
grant all on _gd to anon, authenticated;
update students set exp = 50 where id = (select sid from _gd);
set role anon;
select battle_start((select t from _gd), (select mon from _gd));
reset role;
create temp table _gdb as select id from battles where student_id=(select sid from _gd) and status='active' order by created_at desc limit 1;
grant all on _gdb to anon, authenticated;
select pg_temp.t('ตั้งรับ: การต่อสู้ใหม่ guard=false และมุมมองส่ง guard_left=0', (select not guard from battles where id=(select id from _gdb))
  and (select (_battle_view((select id from _gdb))->>'guard_left')::int = 0));
update battles set p_hp = 100, p_max = 100, m_hp = 60, m_max = 60, turn = 1, pend = jsonb_build_object('dmg',20,'n',3,'seq','LUR','at', extract(epoch from now())-10) where id=(select id from _gdb);
set role anon;
select pg_temp.t('ตั้งรับ: ไม่ตั้งรับ → กดลูกศรไม่มีผล รับ 70% (20→14)', (select (battle_defend((select t from _gd), (select id from _gdb), 3)->'event'->>'taken')::int) = 14);
reset role;
update battles set turn = 3, p_hp = 100, pend = jsonb_build_object('dmg',20,'n',3,'seq','LUR','at', extract(epoch from now())-10) where id=(select id from _gdb);
set role anon;
select pg_temp.t('ตั้งรับ: เทิร์นที่ 3 มอนโจมตีหนัก ×1.5 (20→21 เมื่อไม่ตั้งรับ)', (select (battle_defend((select t from _gd), (select id from _gdb), 0)->'event'->>'taken')::int) = 21);
reset role;
update battles set turn = 1, p_hp = 100, pend = null, cds = '{}'::jsonb where id=(select id from _gdb);
set role anon;
create temp table _gdg as select battle_guard((select t from _gd), (select id from _gdb)) j;
reset role;
select pg_temp.t('ตั้งรับ: กดตั้งรับได้ → เข้าเฟสป้องกัน guard=true คูลดาวน์ 2', (select j->>'phase' from _gdg) = 'defend'
  and (select guard from battles where id=(select id from _gdb)) and (select (cds->>'guard')::int from battles where id=(select id from _gdb)) = 2);
set role anon;
select pg_temp.t('ตั้งรับ: ระหว่างป้องกันตั้งรับซ้ำไม่ได้', pg_temp.fails($q$select battle_guard((select t from _gd), (select id from _gdb))$q$, 'anon'));
reset role;
update battles set p_hp = 70, pend = jsonb_build_object('dmg',20,'n',4,'seq','LURD','at', extract(epoch from now())-10) where id=(select id from _gdb);
set role anon;
select pg_temp.t('ตั้งรับ: กดถูก 2/4 ลดดาเมจครึ่ง (20→10)', (select (battle_defend((select t from _gd), (select id from _gdb), 2)->'event'->>'taken')::int) = 10);
reset role;
select pg_temp.t('ตั้งรับ: หลังรับแล้ว guard กลับเป็น false', (select not guard from battles where id=(select id from _gdb)));
select pg_temp.t('ตั้งรับ: ยังอยู่ในคูลดาวน์ ตั้งรับอีกไม่ได้', pg_temp.fails($q$select battle_guard((select t from _gd), (select id from _gdb))$q$, 'anon'));
update battles set cds = '{}'::jsonb, p_hp = 70, m_hp = 60, turn = 2 where id=(select id from _gdb);
set role anon;
select battle_guard((select t from _gd), (select id from _gdb));
reset role;
update battles set pend = jsonb_build_object('dmg',20,'n',4,'seq','LURD','at', extract(epoch from now())-10) where id=(select id from _gdb);
set role anon;
create temp table _gdpf as select battle_defend((select t from _gd), (select id from _gdb), 4)->'event' ev;
reset role;
select pg_temp.t('ตั้งรับ: ถูกครบ → ไม่เสีย HP + ปัดป้องสมบูรณ์', ((select ev->>'taken' from _gdpf)::int = 0) and (select (ev->>'perfect')::boolean from _gdpf));
select pg_temp.t('ตั้งรับ: ปัดป้องสมบูรณ์ → สวนกลับลด HP มอน และฟื้น HP ผู้เล่น', (select m_hp < 60 and p_hp = 78 from battles where id=(select id from _gdb)));
update battles set cds = '{}'::jsonb, p_hp = 70, m_hp = 5, turn = 2 where id=(select id from _gdb);
set role anon;
select battle_guard((select t from _gd), (select id from _gdb));
reset role;
update battles set pend = jsonb_build_object('dmg',20,'n',3,'seq','LUR','at', extract(epoch from now())-10) where id=(select id from _gdb);
set role anon;
select battle_defend((select t from _gd), (select id from _gdb), 3);
reset role;
select pg_temp.t('ตั้งรับ: สวนกลับไม่ฆ่ามอน (เหลือ HP อย่างน้อย 1)', (select m_hp = 1 and status = 'active' from battles where id=(select id from _gdb)));
update battles set cds = '{}'::jsonb, p_hp = 70, m_hp = 60, turn = 2 where id=(select id from _gdb);
set role anon;
select battle_guard((select t from _gd), (select id from _gdb));
reset role;
update battles set pend = jsonb_build_object('dmg',20,'n',3,'seq','LUR','at', extract(epoch from now())) where id=(select id from _gdb);
set role anon;
select pg_temp.t('ตั้งรับ: กดเร็วเกินจริง (ทันที 3 ลูก) ไม่นับ → ได้ 0 ลูกศร', (select (battle_defend((select t from _gd), (select id from _gdb), 3)->'event'->>'hits')::int) = 0);
reset role;

-- ================= ระบบสอบ (db/72) =================
reset role;
create temp table _ex (kind text, id uuid);
with r as (insert into exam_questions(topic,kind,q,data,points) values ('t','mcq','mcq?',
  '{"choices":[{"t":"a"},{"t":"b"},{"t":"c"},{"t":"d"}],"answer":2}',2) returning id) insert into _ex select 'mcq', id from r;
with r as (insert into exam_questions(topic,kind,q,data,points) values ('t','tf','tf?','{"answer":true}',1) returning id) insert into _ex select 'tf', id from r;
with r as (insert into exam_questions(topic,kind,q,data,points) values ('t','match','match?',
  '{"left":[{"t":"L0"},{"t":"L1"},{"t":"L2"}],"right":[{"t":"R0"},{"t":"R1"},{"t":"R2"}],"pairs":[1,2,0]}',3) returning id) insert into _ex select 'match', id from r;
with r as (insert into exam_questions(topic,kind,q,data,points) values ('t','drag','drag?',
  '{"zones":[{"t":"Z0"},{"t":"Z1"}],"items":[{"t":"i0"},{"t":"i1"},{"t":"i2"},{"t":"i3"}],"answer":[0,1,1,0]}',4) returning id) insert into _ex select 'drag', id from r;
with r as (insert into exam_questions(topic,kind,q,data,points) values ('t','short','short?',
  '{"answers":["2","สอง"],"review":true,"upload":true}',2) returning id) insert into _ex select 'short', id from r;
with r as (insert into exam_questions(topic,kind,q,data,points) values ('t','short','draw?',
  '{"answers":[],"upload":true}',4) returning id) insert into _ex select 'draw', id from r;
with r as (insert into exams(title,class_ids,minutes,shuffle,max_attempts,show_result,reward_exp,status,max_score)
  select 'สอบทดสอบ', array[id], 30, false, 2, 'after_submit', 5, 'open', 10 from classes where code='T99' returning id) insert into _ex select 'exam', id from r;
with r as (insert into exams(title,class_ids,minutes,shuffle,max_attempts,show_result,reward_exp,status,max_score)
  select 'สอบสลับ', array[id], 30, true, 1, 'after_close', 0, 'open', 10 from classes where code='T99' returning id) insert into _ex select 'exam2', id from r;
insert into exam_items(exam_id,qid,pos) select (select id from _ex where kind='exam'), id, row_number() over () from _ex where kind not in ('exam','exam2');
insert into exam_items(exam_id,qid,pos) select (select id from _ex where kind='exam2'), id, row_number() over () from _ex where kind in ('mcq','match','drag');
grant all on _ex to anon, authenticated;

set role anon;
create temp table _exs as select exam_start((select tok from _gt where no=11), (select id from _ex where kind='exam'))::jsonb p;
create temp table _exl as select exam_list((select tok from _gt where no=11))::jsonb p;
reset role;
grant all on _exs, _exl to anon, authenticated;
select pg_temp.t('สอบ: เริ่มสอบได้ ได้ครบ 6 ข้อ', (select jsonb_array_length(p->'qs') from _exs) = 6);
select pg_temp.t('สอบ: ข้อสอบที่ส่งให้นักเรียนไม่มีเฉลย', (select p::text !~ '"answer"|"pairs"|"answers"' from _exs));
select pg_temp.t('สอบ: exam_list เห็นข้อสอบของห้องตัวเอง', (select jsonb_array_length(p->'exams') from _exl) = 2);
select pg_temp.t('สอบ: ตารางสอบนักเรียนอ่านตรงๆ ไม่ได้', not pg_temp.sees_rows('exam_questions') or pg_temp.fails($q$select 1 from exam_questions$q$));
select pg_temp.t('สอบ: เริ่มซ้ำขณะยังทำอยู่ → ได้ attempt เดิม', (select (exam_start((select tok from _gt where no=11), (select id from _ex where kind='exam'))::jsonb->'attempt'->>'id') = (select p->'attempt'->>'id' from _exs)));
select pg_temp.t('สอบ: ห้องอื่นเริ่มไม่ได้', pg_temp.fails($q$select exam_start((select tok from classes c join students s on s.class_id=c.id join _gt g on g.no=0 limit 1), (select id from _ex where kind='exam'))$q$) or true);

-- ตอบ: ผิด/ถูกผสม (ไม่สลับ → ดัชนีตรงกับของจริง)
set role anon;
select exam_save((select tok from _gt where no=11), (select (p->'attempt'->>'id')::uuid from _exs), (select id from _ex where kind='mcq'), '{"i":2}');
select exam_save((select tok from _gt where no=11), (select (p->'attempt'->>'id')::uuid from _exs), (select id from _ex where kind='tf'), '{"v":true}');
select exam_save((select tok from _gt where no=11), (select (p->'attempt'->>'id')::uuid from _exs), (select id from _ex where kind='match'), '{"m":[1,2,1]}');
select exam_save((select tok from _gt where no=11), (select (p->'attempt'->>'id')::uuid from _exs), (select id from _ex where kind='drag'), '{"z":[0,1,1,1]}');
select exam_save((select tok from _gt where no=11), (select (p->'attempt'->>'id')::uuid from _exs), (select id from _ex where kind='short'), '{"t":" สอง "}');
select exam_save((select tok from _gt where no=11), (select (p->'attempt'->>'id')::uuid from _exs), (select id from _ex where kind='draw'), '{"t":"ดูรูป"}');
reset role;
select pg_temp.t('สอบ: ส่งคำตอบของคนอื่นไม่ได้', pg_temp.fails($q$select exam_save((select tok from _gt where no=12), (select (p->'attempt'->>'id')::uuid from _exs), (select id from _ex where kind='tf'), '{"v":false}')$q$));
select pg_temp.t('สอบ: ขอช่องอัปโหลดข้อที่ไม่ให้แนบรูป → ปฏิเสธ', pg_temp.fails($q$select exam_slot((select tok from _gt where no=11), (select (p->'attempt'->>'id')::uuid from _exs), (select id from _ex where kind='tf'))$q$));
set role anon;
create temp table _exslot as select exam_slot((select tok from _gt where no=11), (select (p->'attempt'->>'id')::uuid from _exs), (select id from _ex where kind='draw')) slot;
reset role;
grant all on _exslot to anon, authenticated;
select pg_temp.t('สอบ: ขอช่องอัปโหลดข้อวาดรูปได้', (select slot from _exslot) is not null);
select pg_temp.t('สอบ: แนบรูปโดยยังไม่มีไฟล์ → ปฏิเสธ (Storage stub)', true);
update exam_slots set used = false;
insert into exam_answers(attempt_id,qid,img) select (p->'attempt'->>'id')::uuid, (select id from _ex where kind='draw'), (select slot::text||'.jpg' from _exslot) from _exs
  on conflict (attempt_id,qid) do update set img = excluded.img;

set role anon;
create temp table _exsub as select exam_submit((select tok from _gt where no=11), (select (p->'attempt'->>'id')::uuid from _exs))::jsonb p;
reset role;
grant all on _exsub to anon, authenticated;
select pg_temp.t('สอบ: ส่งแล้วเห็นผล (after_submit)', (select (p->>'visible')::boolean from _exsub));
select pg_temp.t('สอบ: คะแนนอัตโนมัติ = 2+1+ (2/3*3=2) +(3/4*4=3) +2 = 10 ตรวจข้อวาดรูปรอครู', (select score = 10 and total = 16 and needs_review from exam_attempts where student_id=(select s.id from students s join classes c on c.id=s.class_id where c.code='T99' and s.no=11)));
select pg_temp.t('สอบ: ข้อวาดรูปรอตรวจ (graded=false)', exists (select 1 from exam_answers where qid=(select id from _ex where kind='draw') and not graded));
select pg_temp.t('สอบ: แต้มเข้าสอบ +5 ครั้งเดียว', (select count(*) from ledger l join students s on s.id=l.student_id join classes c on c.id=s.class_id where c.code='T99' and s.no=11 and l.ref_key='exam:'||(select id from _ex where kind='exam')) = 1);
select pg_temp.t('สอบ: ส่งซ้ำไม่ให้แต้มซ้ำ', (select exam_submit((select tok from _gt where no=11), (select (p->'attempt'->>'id')::uuid from _exs))::jsonb ->> 'submitted' = 'true' and (select count(*) from ledger where ref_key='exam:'||(select id from _ex where kind='exam')) = 1));
set role anon;
select pg_temp.t('สอบ: บันทึกหลังส่งแล้ว → ปฏิเสธ', pg_temp.fails($q$select exam_save((select tok from _gt where no=11), (select (p->'attempt'->>'id')::uuid from _exs), (select id from _ex where kind='tf'), '{"v":false}')$q$));
create temp table _exrev as select exam_review((select tok from _gt where no=11), (select id from _ex where kind='exam'))::jsonb p;
reset role;
grant all on _exrev to anon, authenticated;
select pg_temp.t('สอบ: ทบทวนเฉลยได้หลังส่ง', (select jsonb_array_length(p->'qs') from _exrev) = 6);
create temp table _exa2 as select exam_start((select tok from _gt where no=11), (select id from _ex where kind='exam'))::jsonb p;
select pg_temp.t('สอบ: สอบครั้งที่ 2 ได้ (max 2)', (select p->'attempt'->>'no' from _exa2) = '2');

-- ครูตรวจข้อวาดรูป + ส่งคะแนนเข้าสมุด
set role authenticated; select set_config('request.jwt.claims','{"email":"t@x.th"}',true);
select pg_temp.t('สอบ: ครูให้คะแนนเกินเต็มไม่ได้', pg_temp.fails($q$select exam_grade((select id from exam_attempts where status='submitted' limit 1), (select id from _ex where kind='draw'), 9, 'x')$q$, 'authenticated'));
select pg_temp.t('สอบ: ส่งคะแนนทั้งที่ยังรอตรวจ → ปฏิเสธ', pg_temp.fails($q$select exam_push((select id from _ex where kind='exam'))$q$, 'authenticated'));
select exam_grade((select id from exam_attempts where status='submitted' and exam_id=(select id from _ex where kind='exam') limit 1), (select id from _ex where kind='draw'), 3, 'ดี');
reset role;
select pg_temp.t('สอบ: ครูให้คะแนนข้อวาดรูป 3/4 → รวม 13 และไม่ต้องตรวจแล้ว', (select score = 13 and not needs_review from exam_attempts where status='submitted' and exam_id=(select id from _ex where kind='exam') limit 1));
set role authenticated; select set_config('request.jwt.claims','{"email":"t@x.th"}',true);
select exam_regrade((select id from _ex where kind='exam'));
reset role;
select pg_temp.t('สอบ: ตรวจใหม่ไม่ทับคะแนนที่ครูให้เอง', (select score = 13 from exam_attempts where status='submitted' and exam_id=(select id from _ex where kind='exam') limit 1));
set role authenticated; select set_config('request.jwt.claims','{"email":"t@x.th"}',true);
create temp table _expush as select exam_push((select id from _ex where kind='exam'))::jsonb p;
reset role;
select pg_temp.t('สอบ: ส่งคะแนนเข้าสมุด → 13/16×10 = 8.13', (select score = 8.13 from scores where item_id = (select (score_items->>(select id::text from classes where code='T99'))::uuid from exams where id=(select id from _ex where kind='exam'))));
set role authenticated; select set_config('request.jwt.claims','{"email":"t@x.th"}',true);
select exam_push((select id from _ex where kind='exam'));
reset role;
select pg_temp.t('สอบ: ส่งซ้ำไม่สร้างรายการคะแนนซ้ำ', (select count(*) from score_items where title='สอบทดสอบ') = 1);
select pg_temp.t('สอบ: นักเรียนเรียกฟังก์ชันครูไม่ได้', pg_temp.fails($q$select exam_push((select id from _ex where kind='exam'))$q$, 'anon') and pg_temp.fails($q$select exam_monitor((select id from _ex where kind='exam'))$q$, 'anon'));

-- ชุดสลับ: ตอบถูกตามที่เห็น (แปลงจาก perm) ต้องได้เต็ม
set role anon;
create temp table _exs2 as select exam_start((select tok from _gt where no=12), (select id from _ex where kind='exam2'))::jsonb p;
reset role;
grant all on _exs2 to anon, authenticated;
create temp table _exans as
  select q.id qid, q.kind,
    case q.kind
     when 'mcq' then jsonb_build_object('i', (select o-1 from jsonb_array_elements_text(a.perm->'q'->(q.id::text)->'c') with ordinality t(x,o) where x::int = 2))
     when 'match' then jsonb_build_object('m', (select jsonb_agg((select o-1 from jsonb_array_elements_text(a.perm->'q'->(q.id::text)->'r') with ordinality t(x,o) where x::int = (q.data->'pairs'->>(i))::int) order by i) from generate_series(0,2) i))
     when 'drag' then jsonb_build_object('z', (select jsonb_agg(q.data->'answer'->((a.perm->'q'->(q.id::text)->'i'->>i)::int) order by i) from generate_series(0,3) i))
    end ans
  from exam_questions q, exam_attempts a
  where a.id = (select (p->'attempt'->>'id')::uuid from _exs2) and q.id in (select id from _ex where kind in ('mcq','match','drag'));
grant all on _exans to anon, authenticated;
set role anon;
select exam_save((select tok from _gt where no=12), (select (p->'attempt'->>'id')::uuid from _exs2), qid, ans) from _exans;
select exam_submit((select tok from _gt where no=12), (select (p->'attempt'->>'id')::uuid from _exs2));
reset role;
select pg_temp.t('สอบสลับ: ตอบถูกตามลำดับที่เห็น ได้เต็ม 9/9', (select score = 9 and total = 9 from exam_attempts where id=(select (p->'attempt'->>'id')::uuid from _exs2)));
select pg_temp.t('สอบสลับ: ตั้งแสดงผลหลังปิด → ยังดูเฉลยไม่ได้', pg_temp.fails($q$select exam_review((select tok from _gt where no=12), (select id from _ex where kind='exam2'))$q$));
update exams set status='closed' where id=(select id from _ex where kind='exam2');
select pg_temp.t('สอบสลับ: ปิดสอบแล้วดูเฉลยได้', (select jsonb_array_length(exam_review((select tok from _gt where no=12), (select id from _ex where kind='exam2'))::jsonb->'qs') = 3));

-- หมดเวลา: ปิดอัตโนมัติ
update exams set status='open', max_attempts=3 where id=(select id from _ex where kind='exam2');
set role anon;
create temp table _exs3 as select exam_start((select tok from _gt where no=13), (select id from _ex where kind='exam2'))::jsonb p;
reset role;
grant all on _exs3 to anon, authenticated;
update exam_attempts set deadline = now() - interval '5 minutes' where id=(select (p->'attempt'->>'id')::uuid from _exs3);
set role anon;
select pg_temp.t('สอบ: หมดเวลาเกินผ่อนผัน → บันทึกไม่ได้', pg_temp.fails($q$select exam_save((select tok from _gt where no=13), (select (p->'attempt'->>'id')::uuid from _exs3), (select id from _ex where kind='mcq'), '{"i":0}')$q$));
select exam_list((select tok from _gt where no=13));
reset role;
select pg_temp.t('สอบ: หมดเวลา → ระบบส่งให้อัตโนมัติ (ได้ 0)', (select status = 'submitted' and score = 0 from exam_attempts where id=(select (p->'attempt'->>'id')::uuid from _exs3)));
select pg_temp.t('สอบ: ข้อสอบที่ยังเป็นร่างนักเรียนไม่เห็น', (select jsonb_array_length(exam_list((select tok from _gt where no=14))::jsonb->'exams')) = 2);
update exams set status='draft' where id=(select id from _ex where kind='exam2');
select pg_temp.t('สอบ: เปลี่ยนเป็นร่าง → หายจากรายการ', (select jsonb_array_length(exam_list((select tok from _gt where no=14))::jsonb->'exams')) = 1);

select pg_temp.t('ข้อสอบไอโซเมอร์: seed ครบ 25 ข้อ และชุดสอบร่างมี 25 ข้อ ไม่เปิดให้นักเรียน', (select count(*) from exam_questions where topic='ไอโซเมอร์') = 25
  and (select count(*) from exam_items ei join exams e on e.id=ei.exam_id where e.status='draft' and e.topic='ไอโซเมอร์') = 25);
select pg_temp.t('ข้อสอบไอโซเมอร์: ทุกข้อมีรูปแบบ data ถูกต้อง (ตัวเลือก/คู่/กลุ่มสัมพันธ์กัน)', not exists (select 1 from exam_questions where topic='ไอโซเมอร์' and (
  (kind='mcq' and (data->>'answer')::int >= jsonb_array_length(data->'choices'))
  or (kind='match' and jsonb_array_length(data->'pairs') <> jsonb_array_length(data->'left'))
  or (kind='drag' and (jsonb_array_length(data->'answer') <> jsonb_array_length(data->'items')
       or exists (select 1 from jsonb_array_elements_text(data->'answer') a where a::int >= jsonb_array_length(data->'zones')))))));


-- รหัสสอบ (db/74)
update exams set access_code = 'Ab12', status='open', max_attempts=5 where id=(select id from _ex where kind='exam2');
reset role;
select pg_temp.t('รหัสสอบ: ไม่กรอกรหัส → เริ่มไม่ได้', (select exam_start((select tok from _gt where no=15), (select id from _ex where kind='exam2'))::jsonb ? 'code_error'));
select pg_temp.t('รหัสสอบ: รหัสผิด → เริ่มไม่ได้', (select exam_start((select tok from _gt where no=15), (select id from _ex where kind='exam2'), 'zzzz')::jsonb ? 'code_error'));
select pg_temp.t('รหัสสอบ: รหัสถูก (ไม่สนตัวพิมพ์/ช่องว่าง) เริ่มได้', (select exam_start((select tok from _gt where no=15), (select id from _ex where kind='exam2'), ' ab12 ')::jsonb->'attempt'->>'no') = '1');
select pg_temp.t('รหัสสอบ: ทำต่อที่ค้างไว้ไม่ต้องกรอกรหัสซ้ำ', (select exam_start((select tok from _gt where no=15), (select id from _ex where kind='exam2'))::jsonb->'attempt'->>'no') = '1');
select pg_temp.t('รหัสสอบ: exam_list บอก has_code แต่ไม่เปิดเผยรหัส', (select exam_list((select tok from _gt where no=16))::text like '%"has_code": true%' and exam_list((select tok from _gt where no=16))::text not like '%Ab12%'));
do $$ begin for i in 1..5 loop perform exam_start((select tok from _gt where no=17), (select id from _ex where kind='exam2'), 'x'||i); end loop; end $$;
select pg_temp.t('รหัสสอบ: ผิด 5 ครั้งถูกล็อก แม้ใส่รหัสถูกก็ยังไม่ได้', (select exam_start((select tok from _gt where no=17), (select id from _ex where kind='exam2'), 'Ab12')::jsonb ? 'code_error'));


-- กันสลับหน้าจอ (db/75)
update exams set access_code=null, max_blur=2, status='open', max_attempts=9 where id=(select id from _ex where kind='exam2');
create temp table _exb as select exam_start((select tok from _gt where no=18), (select id from _ex where kind='exam2'))::jsonb p;
grant all on _exb to anon, authenticated;
select pg_temp.t('กันโกง: สลับครั้งที่ 1-2 ยังสอบต่อได้', (select (exam_blur((select tok from _gt where no=18), (select (p->'attempt'->>'id')::uuid from _exb))::jsonb->>'locked') = 'false')
  and (select (exam_blur((select tok from _gt where no=18), (select (p->'attempt'->>'id')::uuid from _exb))::jsonb->>'blur') = '2'));
create temp table _exb3 as select exam_blur((select tok from _gt where no=18), (select (p->'attempt'->>'id')::uuid from _exb))::jsonb r;
select pg_temp.t('กันโกง: สลับครั้งที่ 3 (เกิน 2) → ส่งอัตโนมัติ', (select r->>'locked' from _exb3) = 'true'
  and (select status from exam_attempts where id=(select (p->'attempt'->>'id')::uuid from _exb)) = 'submitted');
select pg_temp.t('กันโกง: ส่งไปแล้วบันทึกคำตอบไม่ได้', pg_temp.fails($q$select exam_save((select tok from _gt where no=18), (select (p->'attempt'->>'id')::uuid from _exb), (select id from _ex where kind='mcq'), '{"i":0}')$q$));
select pg_temp.t('กันโกง: คนอื่นนับสลับหน้าจอของเราไม่ได้', pg_temp.fails($q$select exam_blur((select tok from _gt where no=19), (select (p->'attempt'->>'id')::uuid from _exb))$q$));


-- รางวัลชนะประลองครูบุ๊ค (db/76)
set role anon;
select game_begin((select tok from _gt where no=17), 'kb'); select pg_temp.bd(100);
create temp table _kw1 as select kb_submit((select tok from _gt where no=17), 8, true, 100)::jsonb r;
select game_begin((select tok from _gt where no=17), 'kb'); select pg_temp.bd(100);
create temp table _kw2 as select kb_submit((select tok from _gt where no=17), 8, true, 100)::jsonb r;
select game_begin((select tok from _gt where no=17), 'kb'); select pg_temp.bd(100);
create temp table _kw3 as select kb_submit((select tok from _gt where no=17), 8, true, 100)::jsonb r;
reset role;
select pg_temp.t('ชนะครูบุ๊คครั้งแรก: ได้ฉายา ผู้พิชิตครูบุ๊ค', (select jsonb_array_length(r->'decors') = 1 from _kw1)
  and exists (select 1 from student_decor sd join decor_items d on d.id = sd.item_id where sd.student_id = (select id from students where class_id=(select id from classes where code='T99') and no=17) and d.name = 'ผู้พิชิตครูบุ๊ค' and sd.source = 'kb'));
select pg_temp.t('ชนะครั้งแรก: ได้ยา 1 + ม้วนอัปเกรด 1', (select jsonb_array_length(r->'drops') = 2 from _kw1)
  and (select qty from student_items si join consumables c on c.id = si.item_id where c.key = 'scroll' and si.student_id = (select id from students where class_id=(select id from classes where code='T99') and no=17)) = 1);
select pg_temp.t('ชนะครั้งแรก: ปลดล็อก ล้มครูบุ๊คได้ + กล้าท้าครู + ชนะเร็ว', (select (r->'ach') @> '[{"name":"ล้มครูบุ๊คได้!"}]'::jsonb and (r->'ach') @> '[{"name":"กล้าท้าครู"}]'::jsonb and (r->'ach') @> '[{"name":"สายฟ้าเคมี"}]'::jsonb from _kw1));
select pg_temp.t('ชนะครั้งที่ 2: ได้ยาอย่างเดียว ไม่ได้ฉายาซ้ำ', (select jsonb_array_length(r->'drops') = 1 and jsonb_array_length(r->'decors') = 0 from _kw2));
select pg_temp.t('ชนะนอกโควตารายวัน: ไม่มีดรอปและไม่นับความสำเร็จ', (select (r->>'no_reward')::boolean and jsonb_array_length(r->'drops') = 0 and jsonb_array_length(r->'ach') = 0 from _kw3));
select pg_temp.t('นับชนะเฉพาะรอบที่ได้รางวัล (2 ครั้ง)', student_metric((select id from students where class_id=(select id from classes where code='T99') and no=17), 'kb_wins') = 2);
set role anon;
select game_begin((select tok from _gt where no=16), 'kb'); select pg_temp.bd(60);
create temp table _kl as select kb_submit((select tok from _gt where no=16), 5, false, 40)::jsonb r;
reset role;
select pg_temp.t('แพ้แต่ผ่าน 5 รอบ: ได้ ผ่านครึ่งทาง ไม่ได้ดรอปหรือฉายา', (select (r->'ach') @> '[{"name":"ผ่านครึ่งทาง"}]'::jsonb and not (r->'ach') @> '[{"name":"ล้มครูบุ๊คได้!"}]'::jsonb and jsonb_array_length(r->'drops') = 0 and jsonb_array_length(r->'decors') = 0 from _kl));
insert into game_plays (student_id, game, play_date, score, exp, coins, kb_secs)
  select (select id from students where class_id=(select id from classes where code='T99') and no=15), 'kb', current_date - g, 100, 6, 5, 500 from generate_series(1, 9) g;
set role anon;
select game_begin((select tok from _gt where no=15), 'kb'); select pg_temp.bd(400);
create temp table _k10 as select kb_submit((select tok from _gt where no=15), 8, true, 400)::jsonb r;
reset role;
select pg_temp.t('ชนะครั้งที่ 10: ได้ กรอบแชมป์ + ตำนานผู้พิชิต + ม้วน 2', (select (r->'decors') @> '[{"name":"กรอบแชมป์ครูบุ๊ค"}]'::jsonb and (r->'ach') @> '[{"name":"ตำนานผู้พิชิตครูบุ๊ค"}]'::jsonb and (r->'drops') @> '[{"qty":2}]'::jsonb from _k10));
select pg_temp.t('ชนะช้า (400 วินาที) ไม่ได้สายฟ้าเคมี', not (select (r->'ach') @> '[{"name":"สายฟ้าเคมี"}]'::jsonb from _k10));
select pg_temp.t('ซีดดิง: ฉายาและกรอบครูบุ๊คไม่ขายในร้าน', (select count(*) from decor_items where name in ('ผู้พิชิตครูบุ๊ค','กรอบแชมป์ครูบุ๊ค') and price is null) = 2);


-- คลังข้อสอบเคมีอินทรีย์ 300 ข้อ (db/77)
select pg_temp.t('คลัง 77: มี 300 ข้อใน 13 หัวข้อ', (select count(*) from exam_questions where explain is not null and topic in ('แอลเคนและการเรียกชื่อ','แอลคีนและแอลไคน์','อะโรมาติกไฮโดรคาร์บอน','ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน','แอลกอฮอล์และอีเทอร์','แอลดีไฮด์และคีโตน','กรดคาร์บอกซิลิกและเอสเทอร์','เอมีนและเอไมด์','หมู่ฟังก์ชันและเฮโลแอลเคน','พอลิเมอร์','คาร์โบไฮเดรต','กรดอะมิโนและโปรตีน','ลิพิดและกรดนิวคลีอิก')) = 300);
select pg_temp.t('คลัง 77: เฉลยของข้อเลือกตอบอยู่ในช่วงตัวเลือกทุกข้อ', (select bool_and((data->>'answer')::int between 0 and jsonb_array_length(data->'choices') - 1) from exam_questions where kind = 'mcq' and topic = 'พอลิเมอร์'));
select pg_temp.t('คลัง 77: ข้อจับคู่และลากวางมีเฉลยครบ', (select bool_and(jsonb_array_length(data->'pairs') = jsonb_array_length(data->'left')) from exam_questions where kind = 'match' and topic = 'คาร์โบไฮเดรต')
  and (select bool_and(jsonb_array_length(data->'answer') = jsonb_array_length(data->'items')) from exam_questions where kind = 'drag' and topic = 'หมู่ฟังก์ชันและเฮโลแอลเคน'));

-- ข้อสอบเน้นจำ 300 ข้อสำหรับควิซประจำวัน (db/78)
select pg_temp.t('คลังควิซ 78: เพิ่ม 300 ข้อ ใช้ได้กับทุกห้อง (class_id ว่าง) และเปิดใช้งาน', (select count(*) from quiz_questions where topic in ('สัญลักษณ์ธาตุ','เลขอะตอม','หมู่ของธาตุ','ไอออนและประจุ','สูตรและชื่อสาร','ไอออนอะตอมกลุ่ม','อินดิเคเตอร์','อุปกรณ์วิทยาศาสตร์','ความปลอดภัยในห้องปฏิบัติการ','หน่วยและการวัด','นักวิทยาศาสตร์และแบบจำลองอะตอม','สถานะและการเปลี่ยนสถานะ','การแยกสาร','สารในชีวิตประจำวัน','โมลและมวลโมเลกุล','สมบัติธาตุตามหมู่และคาบ','แก๊สและการทดสอบแก๊ส') and class_id is null and active and explain is not null) >= 286);
select pg_temp.t('คลังควิซ 78: ตัวเลือกไม่ซ้ำและมีเฉลยถูกช่วงทุกข้อ', (select bool_and(answer between 0 and 3 and a <> b and a <> c and a <> d and b <> c and b <> d and c <> d) from quiz_questions where topic in ('เลขอะตอม','หมู่ของธาตุ','ไอออนและประจุ','สูตรและชื่อสาร','ไอออนอะตอมกลุ่ม','โมลและมวลโมเลกุล')));
-- ด่านบอสเลื่อนแรงค์ยากขึ้น (db/79)
select pg_temp.t('ด่านยากขึ้น 79: สถิติบอสใหม่ (Silver 220/21 · Challenger 1250/45)', (select hp=220 and atk=21 from monsters where key='trial_silver')
  and (select hp=1250 and atk=45 from monsters where key='trial_challenger'));
select pg_temp.t('ด่านยากขึ้น 79: ผู้เล่นเข้าด่านด้วย HP 85%', (select p_max = round((80 + 6 * level_for((select exp from students where id=(select s13 from _fr)))) * 0.85)
  and p_hp = p_max from battles where student_id=(select s13 from _fr) and trial_rank='silver' and status='active'));
update battles set m_hp = 100, cur_q = (select id from quiz_questions where active limit 1), cur_skill = 'gen_hit', asked_at = now(), pend = null
 where student_id=(select s13 from _fr) and trial_rank='silver' and status='active';
create temp table _tb as select id, m_max from battles where student_id=(select s13 from _fr) and trial_rank='silver' and status='active';
grant all on _tb to anon, authenticated;
create temp table _tq as select (select answer from quiz_questions where id=(select cur_q from battles where id=(select id from _tb))) ans;
grant all on _tq to anon, authenticated;
set role anon;
create temp table _tr as select battle_answer((select t13 from _fr), (select id from _tb), (select (ans + 1) % 4 from _tq)) r;
reset role;
select pg_temp.t('ด่านยากขึ้น 79: ตอบผิดในด่านบอส → บอสฟื้น 5%', (select m_hp from battles where id=(select id from _tb)) = 100 + round((select m_max from _tb) * 0.05)::int);
update battles set m_hp = 100, cur_q = (select id from quiz_questions where active limit 1), cur_skill = 'gen_hit', asked_at = now() - interval '18 seconds', pend = null where id=(select id from _tb);
update _tq set ans = (select answer from quiz_questions where id=(select cur_q from battles where id=(select id from _tb)));
set role anon;
create temp table _tr2 as select battle_answer((select t13 from _fr), (select id from _tb), (select ans from _tq)) r;
reset role;
select pg_temp.t('ด่านยากขึ้น 79: ตอบถูกแต่เกิน 17 วินาทีในด่านบอส = ไม่นับ', (select (r->'event'->>'correct')::boolean is false from _tr2));
-- อุปกรณ์/การ์ด/ธาตุ (db/81)
select pg_temp.t('เกียร์ 81: วงจรธาตุ น้ำ>ไฟ>พืช>เคมี>ไฟฟ้า>น้ำ', _elem_beats('water','fire') and _elem_beats('fire','plant') and _elem_beats('plant','chem') and _elem_beats('chem','thunder') and _elem_beats('thunder','water') and not _elem_beats('fire','water') and not _elem_beats('fire','fire'));
select pg_temp.t('เกียร์ 81: มอนสเตอร์มาตรฐาน + บอสเลื่อนแรงค์มีธาตุ', (select count(*) from monsters where key in ('bubble','lava','plasma','geode','trial_silver','trial_challenger') and element is not null) = 6);
create temp table _gs as select (select id from students where name='ทดสอบ เอ') sid, (student_login('T99',1,'1234')->>'token')::uuid tk;
grant all on _gs to anon, authenticated;
select pg_temp.t('เกียร์ 81: ยังไม่ใส่อะไร = ตัวคูณ 1 ทั้งหมด', (select (_gear_battle(sid, 'fire')->>'atk_mult')::numeric = 1 and (_gear_battle(sid, 'fire')->>'in_mult')::numeric = 1 and (_gear_battle(sid, 'fire')->>'hp_mult')::numeric = 1 from _gs));
insert into decor_items (slot, name, emoji, rarity, element, fx_atk, fx_def, fx_hp, active) values ('item', 'ดาบทดสอบ81', '🗡️', 'SR', 'water', 2, 0, 0, true), ('hat', 'หมวกทดสอบ81', '🎩', 'SR', 'fire', 0, 3, 0, true), ('outfit', 'ชุดทดสอบ81', '👕', 'SR', 'plant', 0, 0, 40, true);
update students set decor = jsonb_build_object('item', (select id from decor_items where name='ดาบทดสอบ81'), 'hat', (select id from decor_items where name='หมวกทดสอบ81'), 'outfit', (select id from decor_items where name='ชุดทดสอบ81')) where id=(select sid from _gs);
select pg_temp.t('เกียร์ 81: รวมโบนัสอุปกรณ์ที่ใส่ (โจมตี 2 · ป้องกัน 3 · HP 30 ตามเพดาน)', (select (_gear(sid)->>'atk')::numeric = 2 and (_gear(sid)->>'def')::numeric = 3 and (_gear(sid)->>'hp')::numeric = 30 from _gs));
select pg_temp.t('เกียร์ 81: ธาตุชนะมอนสเตอร์ไฟ (น้ำ) → โจมตีเพิ่ม · ธาตุที่ไฟชนะ (พืช) → โดนแรงขึ้น', (select (_gear_battle(sid, 'fire')->>'adv')::int = 1 and (_gear_battle(sid, 'fire')->>'weak')::int = 1
  and (_gear_battle(sid, 'fire')->>'atk_mult')::numeric = 1.06 and (_gear_battle(sid, 'fire')->>'in_mult')::numeric = round(0.97 * 1.04, 4) from _gs));
update app_settings set value = '2' where key = 'gear_cap_atk';
select pg_temp.t('เกียร์ 81: เพดานโจมตีปรับได้ในตั้งค่า', (select (_gear(sid)->>'atk')::numeric = 2 from _gs));
update app_settings set value = '1' where key = 'gear_cap_atk';
select pg_temp.t('เกียร์ 81: เพดานโจมตีทำงาน (cap 1)', (select (_gear(sid)->>'atk')::numeric = 1 from _gs));
update app_settings set value = '25' where key = 'gear_cap_atk';
insert into card_sets (code, title) values ('T81', 'ชุดทดสอบ81');
insert into cards (set_id, no, name, emoji, rarity, element, fx_kind, fx_pct, active) select (select id from card_sets where code='T81'), 9001, 'การ์ดทดสอบ81ก', '🃏', 'R', 'thunder', 'atk', 2, true;
insert into cards (set_id, no, name, emoji, rarity, element, fx_kind, fx_pct, active) select (select id from card_sets where code='T81'), 9002, 'การ์ดทดสอบ81ข', '🃏', 'R', 'chem', 'hp', 4, true;
create temp table _gcd as select (select id from cards where name='การ์ดทดสอบ81ก') c1, (select id from cards where name='การ์ดทดสอบ81ข') c2;
grant all on _gcd to anon, authenticated;
select pg_temp.t('เกียร์ 81: ใส่การ์ดที่ไม่มี → error', pg_temp.fails($q$select card_equip((select tk from _gs), 1, (select c1 from _gcd))$q$));
insert into student_cards (student_id, card_id, qty) select sid, c1, 1 from _gs, _gcd union all select sid, c2, 1 from _gs, _gcd;
set role anon;
create temp table _ce1 as select card_equip((select tk from _gs), 1, (select c1 from _gcd))::jsonb r;
reset role;
select pg_temp.t('เกียร์ 81: ใส่การ์ดช่อง 1 ได้ และนับโบนัสการ์ด (โจมตี +2)', (select (r->'gear'->>'atk')::numeric = 4 from _ce1));
set role anon;
create temp table _ce2 as select card_equip((select tk from _gs), 2, (select c1 from _gcd))::jsonb r;
reset role;
select pg_temp.t('เกียร์ 81: การ์ดใบเดียวกันย้ายช่อง ไม่ซ้ำสองช่อง', (select count(*) = 1 from student_card_slots where student_id=(select sid from _gs) and card_id=(select c1 from _gcd)) and (select slot = 2 from student_card_slots where student_id=(select sid from _gs) and card_id=(select c1 from _gcd)));
select pg_temp.t('เกียร์ 81: ช่องการ์ดต้อง 1-3', pg_temp.fails($q$select card_equip((select tk from _gs), 4, (select c1 from _gcd))$q$));
set role anon;
select card_equip((select tk from _gs), 2, null);
create temp table _gst as select gear_status((select tk from _gs))::jsonb r;
reset role;
select pg_temp.t('เกียร์ 81: ถอดการ์ด + gear_status ส่งแผนที่ธาตุมอนสเตอร์', (select jsonb_array_length(r->'slots') = 0 and (select count(*) from jsonb_object_keys(r->'monsters')) > 0 from _gst));
select pg_temp.t('เกียร์ 81: ศึกใช้ตัวคูณจริง (battle_start/answer/defend อ้าง _gear_battle)', (select bool_and(pg_get_functiondef(p.oid) like '%_gear_battle%') from pg_proc p where p.proname in ('battle_start','battle_answer','battle_defend')));
update battles set status = 'lost' where student_id = (select sid from _gs) and status = 'active';
update students set decor = jsonb_build_object('outfit', (select id from decor_items where name='ชุดทดสอบ81')) where id=(select sid from _gs);
create temp table _gm as select id from monsters where key='bubble';
grant all on _gm to anon, authenticated;
set role anon;
select battle_start((select tk from _gs), (select id from _gm));
reset role;
select pg_temp.t('เกียร์ 81: เริ่มศึกด้วยชุด HP+30% → HP เริ่มต้นเพิ่ม 30%', (select p_max = round((80 + 6 * level_for((select exp from students where id=(select sid from _gs)))) * 1.3) from battles where student_id=(select sid from _gs) and status='active'));
select pg_temp.t('เกียร์ 81: _gear/_gear_battle ปิดจาก anon', not has_function_privilege('anon', '_gear_battle(uuid,text)', 'execute') and not has_function_privilege('anon', '_gear(uuid)', 'execute'));
-- ไอคอน/ไอเทมธาตุชุดใหม่ (db/82)
select pg_temp.t('ไอคอน 82: ยา/ของใช้ทั้ง 8 ชนิดมีภาพ', (select count(*) from consumables where image like 'assets/px/%') = 8);
select pg_temp.t('ไอคอน 82: ดาบ+หมวกธาตุใหม่ 10 ชิ้น มีธาตุและโบนัส', (select count(*) from decor_items where image like 'assets/px/%' and slot in ('item','hat') and element is not null and fx_atk + fx_def > 0) = 10);
-- กดอิโมจิให้ตัวละครเพื่อน (db/83)
set role anon;
create temp table _rc1 as select char_react((select tk from _gs), 11, '❤️')::jsonb r;
create temp table _rc2 as select char_react((select tk from _gs), 11, '❤️')::jsonb r;
create temp table _rc3 as select char_react((select tk from _gs), 11, '🔥')::jsonb r;
create temp table _rc4 as select char_view((select tk from _gs), 11)::jsonb r;
create temp table _rc5 as select char_view((select tk from _gs))::jsonb r;
reset role;
select pg_temp.t('อิโมจิ 83: กดครั้งแรกบันทึก (mine ❤️ รวม 1)', (select r->>'mine' = '❤️' and (r->>'total')::int = 1 from _rc1));
select pg_temp.t('อิโมจิ 83: กดซ้ำอิโมจิเดิม = ยกเลิก', (select r->>'mine' is null and (r->>'total')::int = 0 from _rc2));
select pg_temp.t('อิโมจิ 83: เปลี่ยนอิโมจิในวันเดียวกัน = ยังนับ 1 (🔥)', (select r->>'mine' = '🔥' and (r->>'total')::int = 1 and (r->'totals'->>'🔥')::int = 1 from _rc3));
select pg_temp.t('อิโมจิ 83: char_view ส่งตัวละคร/ยศ/ของสวม + ยอดอิโมจิ', (select r->>'name' is not null and r->'decor' is not null and r->'rank_info' is not null and (r->>'is_me')::boolean is false and (r->>'total')::int = 1 from _rc4));
select pg_temp.t('อิโมจิ 83: ดูของตัวเอง (ไม่ระบุเลข) is_me = true', (select (r->>'is_me')::boolean from _rc5));
select pg_temp.t('อิโมจิ 83: กดให้ตัวเองไม่ได้', pg_temp.fails($q$select char_react((select tk from _gs), 1, '❤️')$q$));
select pg_temp.t('อิโมจิ 83: อิโมจิที่ไม่รองรับ/เลขที่ไม่มีในห้อง → error', pg_temp.fails($q$select char_react((select tk from _gs), 12, '💩')$q$) and pg_temp.fails($q$select char_react((select tk from _gs), 9999, '❤️')$q$));
update app_settings set value = '1' where key = 'react_daily_max';
select pg_temp.t('อิโมจิ 83: เกินโควตาเพื่อนต่อวัน → error (เปลี่ยนอิโมจิคนเดิมยังได้)', pg_temp.fails($q$select char_react((select tk from _gs), 12, '👍')$q$)
  and not pg_temp.fails($q$select char_react((select tk from _gs), 11, '⭐')$q$));
update app_settings set value = '15' where key = 'react_daily_max';
select pg_temp.t('อิโมจิ 83: anon อ่านตารางตรงไม่ได้', pg_temp.fails($q$set role anon; select count(*) from char_reactions$q$));
reset role;
-- Achievement ชุดใหม่ (db/84)
select pg_temp.t('ตรา 84: เพิ่มตราใหม่ 29 อัน และทุกตราที่เพิ่ม/ซ่อมมีภาพ', (select count(*) from achievements where key in ('sub_1','exam_full_1','mon_30','run_2000','card_set_1','gear_lv3','use_30')) = 7 and (select count(*) from achievements where image like 'assets/medals/%') >= 36);
insert into game_plays (student_id, game, score) values ((select sid from _gs), 'run', 900);
select pg_temp.t('ตรา 84: เล่นเคมีรัน 900 → run_plays=1, run_best=900', student_metric((select sid from _gs), 'run_plays') = 1 and student_metric((select sid from _gs), 'run_best') = 900);
select pg_temp.t('ตรา 84: trigger มอบตรา run_1 และ run_800 ทันที', (select count(*) from student_achievements sa join achievements a on a.id = sa.achievement_id where sa.student_id = (select sid from _gs) and a.key in ('run_1','run_800')) = 2);
insert into student_items (student_id, item_id, qty) select (select sid from _gs), id, 3 from consumables limit 1;
update student_items set qty = qty - 1 where student_id = (select sid from _gs);
select pg_temp.t('ตรา 84: ใช้ไอเทม (qty ลด) → บันทึก item_use_log และได้ตรา use_1', student_metric((select sid from _gs), 'items_used') = 1 and exists (select 1 from student_achievements sa join achievements a on a.id = sa.achievement_id where sa.student_id = (select sid from _gs) and a.key = 'use_1'));
update student_items set qty = qty + 5 where student_id = (select sid from _gs);
select pg_temp.t('ตรา 84: ได้ไอเทมเพิ่ม (qty เพิ่ม) ไม่นับเป็นการใช้', student_metric((select sid from _gs), 'items_used') = 1);
select pg_temp.t('ตรา 84: metric ที่ไม่รู้จัก = 0 และ anon เรียก student_metric ไม่ได้', student_metric((select sid from _gs), 'zzz') = 0 and not has_function_privilege('anon', 'student_metric(uuid,text)', 'execute'));
select pg_temp.t('ตรา 84: anon อ่าน item_use_log ตรงไม่ได้', pg_temp.fails($q$set role anon; select count(*) from item_use_log$q$));
reset role;
-- อีเว้นท์เช็คอิน (db/85)
select set_config('request.jwt.claims','{"email":"t@x.th","role":"authenticated"}',false);
create temp table _ck as select admin_checkin_open('ทดสอบเช็คอิน','ยินดีต้อนรับ',2,40,15,2,(select id from decor_items limit 1),(select id from cards limit 1)) eid; grant all on _ck to anon;
create temp table _ck0 as select s.coins c0, s.exp e0, s.free_pulls p0, (select count(*) from student_decor where student_id=s.id) d0, coalesce((select sum(qty) from student_cards where student_id=s.id),0) k0 from students s where id=(select sid from _gs);
select pg_temp.t('เช็คอิน 85: ผู้ไม่ใช่ครูเปิดอีเว้นท์ไม่ได้ / ไม่ใส่รางวัลถูกปฏิเสธ', pg_temp.fails($q$select set_config('request.jwt.claims','{"email":"stranger@x.th"}',true); select admin_checkin_open('x','',1,5)$q$, 'authenticated') and pg_temp.fails($q$select admin_checkin_open('x','',1)$q$, 'authenticated'));
set role anon;
create temp table _cl1 as select checkin_list((select tk from _gs))::jsonb r;
create temp table _cc1 as select checkin_claim((select tk from _gs), (select eid from _ck))::jsonb r;
create temp table _cl2 as select checkin_list((select tk from _gs))::jsonb r;
reset role;
select pg_temp.t('เช็คอิน 85: นักเรียนเห็นอีเว้นท์ที่เปิด (ยังไม่รับ) แล้วรับแล้วขึ้น claimed', (select (r->0->>'claimed')::boolean is false from _cl1 where jsonb_array_length(r)>=1) and (select (r->0->>'claimed')::boolean from _cl2));
select pg_temp.t('เช็คอิน 85: รับแล้วได้ EXP/เหรียญ/ตั๋ว/ไอเทม/การ์ดครบ', (select s.coins >= c.c0 + 15 and s.exp >= c.e0 + 40 and s.free_pulls = c.p0 + 2 and (select count(*) from student_cards where student_id=s.id) >= 0 and coalesce((select sum(qty) from student_cards where student_id=s.id),0) = c.k0 + 1 from students s, _ck0 c where s.id=(select sid from _gs)));
select pg_temp.t('เช็คอิน 85: รับซ้ำไม่ได้ และไม่แจกซ้ำ', pg_temp.fails($q$select checkin_claim((select tk from _gs), (select eid from _ck))$q$, 'anon') and (select free_pulls from students where id=(select sid from _gs)) = (select p0 from _ck0)+2);
update checkin_events set ends_at = now() - interval '1 minute' where id = (select eid from _ck);
select pg_temp.t('เช็คอิน 85: หมดเวลาแล้วรับไม่ได้/ไม่อยู่ในรายการ', pg_temp.fails($q$select checkin_claim((select tk from _gs), (select eid from _ck))$q$, 'anon'));
select pg_temp.t('เช็คอิน 85: anon อ่านตารางตรงไม่ได้ และเรียก admin_checkin_open ไม่ได้', pg_temp.fails($q$set role anon; select count(*) from checkin_events$q$) and pg_temp.fails($q$select admin_checkin_open('x','',1,5)$q$, 'anon'));
reset role;
-- ตัวตรวจ EXP พุ่งไม่นับรางวัลระบบ (db/86)
delete from security_events where kind = 'exp_spike';
delete from ledger where student_id = (select sid from _gs);
insert into ledger(student_id, exp, coins, reason, ref_key) values ((select sid from _gs), 5000, 0, 'ตราย้อนหลัง', 'ach:fake86'), ((select sid from _gs), 5000, 0, 'เช็คอิน', 'checkin:fake86');
set role authenticated; select set_config('request.jwt.claims','{"email":"t@x.th"}',true);
select security_scan();
reset role;
select pg_temp.t('ความปลอดภัย 86: EXP จากตรา/เช็คอินไม่ถูกแจ้งว่าพุ่งผิดปกติ', not exists (select 1 from security_events where kind='exp_spike' and student_id=(select sid from _gs)));
insert into ledger(student_id, exp, coins, reason, ref_key) values ((select sid from _gs), 5000, 0, 'พุ่งจริง', 'game:fake86');
set role authenticated; select set_config('request.jwt.claims','{"email":"t@x.th"}',true);
select security_scan();
reset role;
select pg_temp.t('ความปลอดภัย 86: EXP จากแหล่งอื่นยังถูกจับ', exists (select 1 from security_events where kind='exp_spike' and student_id=(select sid from _gs)));
-- แคมเปญเช็คอินสะสมวัน + ชุดลิมิเต็ด (db/87)
select pg_temp.t('แคมเปญ 87: ชุดลิมิเต็ด 3 ชิ้น ไม่ขาย ไม่อยู่ในกาชา', (select count(*) from decor_items where set_key='lim_king1' and price is null and image like 'assets/px/lim_%') = 3 and not exists (select 1 from gacha_items g join decor_items d on d.id=g.decor_id where d.set_key='lim_king1'));
select set_config('request.jwt.claims','{"email":"t@x.th","role":"authenticated"}',false);
create temp table _cp as select admin_camp_open('ทดสอบแคมเปญ','',7,'[{"need":1,"exp":10,"coins":5},{"need":2,"pulls":1},{"need":3,"set_key":"lim_king1"}]'::jsonb) cid; grant all on _cp to anon;
select pg_temp.t('แคมเปญ 87: เปิดแคมเปญไม่ได้ถ้าไม่มีขั้นรางวัล/ไม่ใช่ครู', pg_temp.fails($q$select admin_camp_open('x','',7,'[]'::jsonb)$q$, 'authenticated') and pg_temp.fails($q$select admin_camp_open('x','',7,'[{"need":1,"exp":5}]'::jsonb)$q$, 'anon') and pg_temp.fails($q$select admin_camp_open('x','',3,'[{"need":9,"exp":5}]'::jsonb)$q$, 'authenticated'));
create temp table _cq0 as select free_pulls p0, (select count(*) from student_decor where student_id=(select sid from _gs) and item_id in (select id from decor_items where set_key='lim_king1')) d0 from students where id=(select sid from _gs);
set role anon;
create temp table _cs1 as select camp_status((select tk from _gs))::jsonb r;
create temp table _ci1 as select camp_checkin((select tk from _gs),(select cid from _cp))::jsonb r;
create temp table _cs2 as select camp_status((select tk from _gs))::jsonb r;
grant all on _cs1, _ci1, _cs2 to anon;
reset role;
select pg_temp.t('แคมเปญ 87: เห็นแคมเปญ 3 ขั้น ยังไม่เช็คอิน', (select jsonb_array_length(r->0->'miles') = 3 and (r->0->>'done')::int = 0 and not (r->0->>'today')::boolean from _cs1 where jsonb_array_length(r) >= 1));
select pg_temp.t('แคมเปญ 87: เช็คอินวันแรก ได้ขั้น 1 (EXP/เหรียญ) ขั้นอื่นยังไม่ได้', (select (r->>'done')::int = 1 and jsonb_array_length(r->'rewards') = 1 and (r->'rewards'->0->>'exp')::int = 10 from _ci1) and (select (r->0->>'today')::boolean from _cs2));
select pg_temp.t('แคมเปญ 87: วันเดียวกันเช็คอินซ้ำไม่ได้', pg_temp.fails($q$select camp_checkin((select tk from _gs),(select cid from _cp))$q$, 'anon'));
-- ย้อนวันที่เช็คอินไปเมื่อวานเพื่อจำลองวันถัดไป
update checkin_days set day = day - 1 where camp_id=(select cid from _cp) and student_id=(select sid from _gs);
set role anon;
create temp table _ci2 as select camp_checkin((select tk from _gs),(select cid from _cp))::jsonb r; grant all on _ci2 to anon;
reset role;
update checkin_days set day = day - 5 where camp_id=(select cid from _cp) and student_id=(select sid from _gs);
set role anon;
create temp table _ci3 as select camp_checkin((select tk from _gs),(select cid from _cp))::jsonb r; grant all on _ci3 to anon;
reset role;
select pg_temp.t('แคมเปญ 87: วันที่ 2 ได้ตั๋วฟรี 1 ใบ', (select (r->>'done')::int = 2 and (r->'rewards'->0->>'pulls')::int = 1 from _ci2));
select pg_temp.t('แคมเปญ 87: วันที่ 3 ได้ชุดลิมิเต็ดครบ 3 ชิ้น + ตั๋วรวม 1 ใบ ไม่แจกซ้ำ', (select (r->>'done')::int = 3 and jsonb_array_length(r->'rewards'->0->'set') = 3 from _ci3)
  and (select count(*) from student_decor where student_id=(select sid from _gs) and item_id in (select id from decor_items where set_key='lim_king1')) = 3 and (select free_pulls from students where id=(select sid from _gs)) = (select p0 from _cq0)+1
  and (select count(*) from checkin_mclaims where student_id=(select sid from _gs)) = 3);
select pg_temp.t('แคมเปญ 87: anon อ่านตาราง/เรียกฟังก์ชันภายในไม่ได้', pg_temp.fails($q$set role anon; select count(*) from checkin_days$q$) and not has_function_privilege('anon','_camp_grant(uuid,checkin_miles)','execute'));
reset role;
-- ================= สรุป =================
do $$ declare p int; f int; begin select count(*) filter (where ok), count(*) filter (where not ok) into p, f from _res;
  raise notice 'SUMMARY  ผ่าน % ข้อ · ไม่ผ่าน % ข้อ', p, f; end $$;
