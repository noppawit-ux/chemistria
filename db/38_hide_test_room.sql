-- 38: ซ่อนห้องทดสอบ (GM) ออกจากอันดับ "ห้องแข่งห้อง" (รันซ้ำได้) — ต้องรัน 08 และ 15 ก่อน
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
         where (not c.hidden or c.id = s.class_id)   -- ซ่อนห้องทดสอบ (GM) จากอันดับห้อง ยกเว้นตัวเองอยู่ในห้องนั้น
         group by c.id, c.name
        having count(st.id) > 0
    ) x)
  ) into r;
  return r;
end $$;
