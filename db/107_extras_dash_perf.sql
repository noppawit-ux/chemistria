-- 107: ลดงานซ้ำของ student_dashboard / student_extras (ผลลัพธ์ JSON เหมือนเดิมทุกไบต์)
-- ข้อมูลจริงบน prod: team_board.rooms สแกน ledger ทุกแถวของทุกคน (≈7,000 buffers, 45 ms/ครั้ง) เพราะเงื่อนไขวันที่ใช้ cast ที่ใช้ index ไม่ได้
--   และ achievements เรียก student_metric 47 ครั้ง/ครั้งที่เปิดหน้า ทั้งที่มีแค่ไม่กี่ชนิดของ metric
-- 1) team_board: คำนวณ EXP ของสัปดาห์นี้ต่อคนครั้งเดียวด้วยช่วงเวลา (ใช้ index ได้) แล้วนำไปใช้ทั้ง teams/roster/rooms
create or replace function team_board(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); s students%rowtype; wk date := date_trunc('week', today_th())::date;
        wkts timestamptz := wk::timestamp at time zone 'Asia/Bangkok'; r json;
begin
  select * into s from students where id = sid;
  with wx as materialized (select l.student_id, sum(l.exp) as x from ledger l where l.created_at >= wkts group by l.student_id)
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
                       where l.student_id = m.id and l.created_at >= wkts) mw on true
                 where m.team_id = tm.id and tm.id = s.team_id) as roster
          from teams tm
          left join students st on st.team_id = tm.id
          left join wx w on w.student_id = st.id
         where tm.class_id = s.class_id
         group by tm.id, tm.name, tm.emoji
    ) t),
    'rooms', (select coalesce(json_agg(x order by x.avg_week desc), '[]'::json) from (
        select c.name, (c.id = s.class_id) as mine, count(st.id)::int as students,
               case when count(st.id) = 0 then 0 else round(coalesce(sum(w.x), 0)::numeric / count(st.id), 1) end as avg_week
          from classes c
          left join students st on st.class_id = c.id
          left join wx w on w.student_id = st.id
         where (not c.hidden or c.id = s.class_id)
         group by c.id, c.name
        having count(st.id) > 0
    ) x)
  ) into r;
  return r;
end $$;
revoke execute on function team_board(uuid) from public;
grant execute on function team_board(uuid) to anon, authenticated;

-- 2) _student_dashboard: achievements คำนวณ student_metric ต่อชนิด metric ครั้งเดียว (แพตช์จากนิยามจริงในฐานข้อมูล จึงไม่ทับการแก้ไขอื่น)
do $$ declare d text; d2 text; oid_ oid;
begin
  select p.oid into oid_ from pg_proc p where p.proname = '_student_dashboard' and p.pronamespace = 'public'::regnamespace;
  d := pg_get_functiondef(oid_);
  if position('student_metric(sid, ac.metric)' in d) = 0 then return; end if;     -- แพตช์แล้ว
  d2 := regexp_replace(d, 'student_metric\(sid, ac\.metric\)', 'pm.v');
  d2 := regexp_replace(d2, 'from achievements ac(\s+)left join student_achievements sa',
        'from achievements ac\1join (select m.metric, student_metric(sid, m.metric) as v from (select distinct metric from achievements where active) m) pm on pm.metric is not distinct from ac.metric\1left join student_achievements sa');
  if d2 = d or position('pm.metric is not distinct from ac.metric' in d2) = 0 then raise exception '107: แพตช์ _student_dashboard ไม่สำเร็จ'; end if;
  execute d2;
end $$;
revoke execute on function _student_dashboard(uuid) from public, anon, authenticated;
