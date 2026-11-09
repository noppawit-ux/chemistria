-- 39: ตรวจสุขภาพระบบ (เฉพาะครู) + เก็บกวาดสิทธิ์ (รันซ้ำได้)
-- 1) เก็บกวาดสิทธิ์: view สมุดคะแนนไม่ให้ anon แตะเลย (เดิมปลอดภัยอยู่แล้วเพราะ security_invoker + RLS แต่ปิดซ้ำอีกชั้น)
revoke all on v_gradebook from anon;
-- 2) health_check(): ส่งรายการตรวจ [{key,label,level,count,detail}] level = ok | warn | bad
create or replace function health_check() returns json
language plpgsql stable security definer set search_path = public as $$
declare out jsonb := '[]'; n int; missing text; fn text;
  need text[] := array['student_login','student_dashboard','student_extras','game_status','quiz_today','quiz_submit','match_submit',
    'spell_status','spell_submit','kb_status','kb_submit','run_status','run_submit','battle_start','battle_answer','battle_defend',
    'duel_lobby','duel_state','gacha_pull','boss_status','boss_claim','news_list','timetable_list','promo_status','hall_of_fame',
    'board_list','team_board','claim_quest','submit_assignment','buy_decor','buy_privilege','admin_adjust','admin_mark_attendance'];
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;

  -- ข้อมูลเพี้ยน
  select count(*) into n from students where exp < 0 or coins < 0 or coalesce(free_pulls,0) < 0;
  out := out || jsonb_build_object('key','neg','label','ตัวเลขติดลบ (EXP/เหรียญ/ตั๋วกาชา)','level',case when n>0 then 'bad' else 'ok' end,'count',n,'detail','ควรเป็น 0');
  select count(*) into n from (select s.id from students s left join ledger l on l.student_id=s.id group by s.id, s.exp having s.exp <> greatest(0, coalesce(sum(l.exp),0))) x;
  out := out || jsonb_build_object('key','ledger','label','EXP ในตัวนักเรียนไม่ตรงกับยอดรวมในบัญชีรางวัล','level',case when n>0 then 'warn' else 'ok' end,'count',n,'detail','อาจเกิดจากครูแก้ตัวเลขตรงๆ หรือถูกปัดเป็น 0');
  select count(*) into n from students where pin_hash is null;
  out := out || jsonb_build_object('key','nopin','label','นักเรียนที่ยังไม่มี PIN','level',case when n>0 then 'warn' else 'ok' end,'count',n,'detail','เข้าสู่ระบบไม่ได้จนกว่าจะตั้ง PIN');
  select count(*) into n from students where locked_until is not null and locked_until > now();
  out := out || jsonb_build_object('key','locked','label','บัญชีที่ถูกล็อกชั่วคราว (ใส่ PIN ผิดหลายครั้ง)','level',case when n>0 then 'warn' else 'ok' end,'count',n,'detail','ปลดเองใน 10 นาที');
  select count(*) into n from students where class_id is null or not exists (select 1 from classes c where c.id = students.class_id);
  out := out || jsonb_build_object('key','orphan','label','นักเรียนที่ไม่มีห้อง','level',case when n>0 then 'bad' else 'ok' end,'count',n,'detail','');
  select count(*) into n from (select class_id, no from students group by 1,2 having count(*) > 1) x;
  out := out || jsonb_build_object('key','dupno','label','เลขที่ซ้ำในห้องเดียวกัน','level',case when n>0 then 'bad' else 'ok' end,'count',n,'detail','ทำให้ล็อกอินสับสน');

  -- เซสชัน
  select count(*) into n from student_sessions where expires_at < now() - interval '30 days';
  out := out || jsonb_build_object('key','oldsess','label','เซสชันหมดอายุเกิน 30 วัน (ควรลบ)','level',case when n>500 then 'warn' else 'ok' end,'count',n,'detail','กดล้างได้ในหน้านี้');
  select count(*) into n from student_sessions where observer and expires_at > now();
  out := out || jsonb_build_object('key','peek','label','เซสชันโหมดส่องที่ยังใช้ได้อยู่','level','ok','count',n,'detail','ดูอย่างเดียว');

  -- ฟังก์ชันที่ระบบต้องใช้
  select string_agg(f, ', ') into missing from unnest(need) f where not exists (select 1 from pg_proc p where p.proname = f and p.pronamespace = 'public'::regnamespace);
  out := out || jsonb_build_object('key','rpc','label','ฟังก์ชันหลักที่ขาดหาย (ยังไม่ได้รัน SQL ครบ)','level',case when missing is not null then 'bad' else 'ok' end,'count',coalesce(array_length(string_to_array(missing, ', '),1),0),'detail',coalesce(missing,''));

  -- ตั้งค่า
  select count(*) into n from app_settings where key in ('promo_on') and value = '1' and (select value from app_settings where key='promo_until') < to_char(today_th(),'YYYY-MM-DD');
  out := out || jsonb_build_object('key','promo','label','โปรโมชันเปิดอยู่แต่เลยวันสิ้นสุดแล้ว','level',case when n>0 then 'warn' else 'ok' end,'count',n,'detail','ปิด promo_on หรือขยายวัน');
  select count(*) into n from news_posts where ends_at is not null and ends_at < today_th();
  out := out || jsonb_build_object('key','oldnews','label','ประกาศที่หมดอายุแล้ว (ยังค้างในตาราง)','level','ok','count',n,'detail','ไม่แสดงให้นักเรียนอยู่แล้ว');
  select count(*) into n from bosses where coalesce(active,true);
  out := out || jsonb_build_object('key','boss','label','บอสที่เปิดใช้งาน','level',case when n=0 then 'warn' else 'ok' end,'count',n,'detail','ควรมีอย่างน้อย 1');

  return json_build_object('checked_at', now(), 'items', out);
end $$;
revoke execute on function health_check() from public, anon;
grant execute on function health_check() to authenticated;

-- 3) ล้างเซสชันเก่า (เฉพาะครู)
create or replace function admin_purge_sessions() returns int
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  delete from student_sessions where expires_at < now() - interval '7 days';
  get diagnostics n = row_count;
  return n;
end $$;
revoke execute on function admin_purge_sessions() from public, anon;
grant execute on function admin_purge_sessions() to authenticated;
