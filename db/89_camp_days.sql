-- =====================================================================
-- 89: camp_status ส่งรายการ "วันที่เช็คอินแล้ว" + วันนี้ เพื่อแสดงแบนเนอร์เป็นแถวรายวัน (รันซ้ำได้ · ต้องรัน SQL 87 ก่อน)
-- =====================================================================
create or replace function camp_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); td date := today_th();
begin
  return coalesce((select json_agg(json_build_object(
      'id', c.id, 'title', c.title, 'message', c.message, 'start_day', c.start_day, 'end_day', c.end_day,
      'days_total', c.end_day - c.start_day + 1, 'days_left', c.end_day - td,
      'done', (select count(*) from checkin_days k where k.camp_id = c.id and k.student_id = sid),
      'checked', (select coalesce(json_agg(k.day order by k.day), '[]'::json) from checkin_days k where k.camp_id = c.id and k.student_id = sid),
      'today_date', td,
      'today', exists (select 1 from checkin_days k where k.camp_id = c.id and k.student_id = sid and k.day = td),
      'miles', (select json_agg(json_build_object('need', m.need, 'exp', m.exp, 'coins', m.coins, 'pulls', m.pulls,
                  'decor', d.name, 'card', cd.name,
                  'set', (select json_agg(json_build_object('name', x.name, 'emoji', x.emoji, 'image', x.image) order by x.sort) from decor_items x where x.set_key = m.set_key),
                  'got', exists (select 1 from checkin_mclaims q where q.mile_id = m.id and q.student_id = sid)) order by m.need)
                from checkin_miles m left join decor_items d on d.id = m.decor_id left join cards cd on cd.id = m.card_id where m.camp_id = c.id)
    ) order by c.end_day)
    from checkin_camps c where not c.closed and td between c.start_day and c.end_day), '[]'::json);
end $$;
