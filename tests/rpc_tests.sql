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
select pg_temp.t('quiz_submit สำเร็จครั้งแรก', (select quiz_submit((select a from _tok), '[0,0,0,0,0]'::jsonb) is not null));
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
declare r record; allowed text[] := array['student_dashboard','student_extras','hall_of_fame','board_list','celebrations_feed','game_status','spell_status','kb_status','news_list','run_status','timetable_list','promo_status'];
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

-- ================= สรุป =================
do $$ declare p int; f int; begin select count(*) filter (where ok), count(*) filter (where not ok) into p, f from _res;
  raise notice 'SUMMARY  ผ่าน % ข้อ · ไม่ผ่าน % ข้อ', p, f; end $$;
