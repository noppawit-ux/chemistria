-- 41: สถิติเกมและรางวัล (เฉพาะครู) — ดูว่าเกมไหนมีคนเล่น/แจกรางวัลสูงเกินไปหรือไม่
-- game_stats(p_days) คืน {days, students, active, sources:[{src, grants, players, exp, coins, avg_exp, share_exp}],
--                          spent_coins, promo_claims, top_students:[...]}
create or replace function _ledger_src(p_reason text) returns text
language sql immutable as $$
  select case
    when p_reason is null then 'อื่นๆ'
    when p_reason like 'ควิซประจำวัน%' then '🧠 ควิซประจำวัน'
    when p_reason like 'จับคู่ธาตุ%' then '🧩 จับคู่ธาตุ'
    when p_reason like 'ห้องฝึกเวทย์%' then '⚗️ ห้องฝึกเวทย์'
    when p_reason like 'เคมีรัน%' then '🏃 เคมีรัน'
    when p_reason like '%ประลองครูบุ๊ค%' then '🎓 ประลองครูบุ๊ค'
    when p_reason like '%มอนสเตอร์%' and p_reason not like 'ดรอป%' then '👾 ล่ามอนสเตอร์'
    when p_reason like 'ท้าดวล%' then '⚔️ ท้าดวล'
    when p_reason like 'ปราบบอส%' then '🐉 บอสประจำสัปดาห์'
    when p_reason like 'ของขวัญเปิดระบบ%' then '🎁 โปรโมชันเปิดระบบ'
    when p_reason like 'มาเรียน%' then '📋 เช็คชื่อ'
    when p_reason like 'ส่งงาน%' then '📝 ส่งงาน'
    when p_reason like 'เควส:%' then '🎯 เควส'
    when p_reason like 'Achievement:%' then '🏅 เหรียญรางวัล'
    when p_reason like 'กาชา:%' or p_reason like 'ดรอป%' or p_reason like 'ไอเทมตกแต่งซ้ำ%' then '🎰 กาชา/ของดรอป'
    when p_reason like 'ครูปรับให้%' or p_reason like 'ครูส่งคืนงาน%' then '👩‍🏫 ครูปรับ'
    else 'อื่นๆ' end
$$;

create or replace function game_stats(p_days int default 7) returns json
language plpgsql stable security definer set search_path = public as $$
declare d int := greatest(1, least(coalesce(p_days, 7), 120)); since timestamptz := now() - make_interval(days => d);
        n_stu int; n_act int; srcs json; spent bigint; promo int; top json;
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  select count(*) into n_stu from students;
  select count(distinct student_id) into n_act from ledger where created_at >= since;
  select coalesce(json_agg(r order by r.exp desc), '[]'::json) into srcs from (
    select _ledger_src(reason) as src, count(*) as grants, count(distinct student_id) as players,
           sum(exp) filter (where exp > 0) as exp, sum(coins) filter (where coins > 0) as coins,
           round(avg(exp) filter (where exp > 0), 1) as avg_exp,
           round(100.0 * sum(exp) filter (where exp > 0) / nullif(sum(sum(exp) filter (where exp > 0)) over (), 0), 1) as share_exp
      from ledger where created_at >= since group by 1) r;
  select coalesce(-sum(coins) filter (where coins < 0), 0) into spent from ledger where created_at >= since;
  select count(*) into promo from ledger where ref_key = 'promo:launch';
  select coalesce(json_agg(t), '[]'::json) into top from (
    select s.name, c.name as room, sum(l.exp) as exp, sum(l.coins) filter (where l.coins > 0) as coins
      from ledger l join students s on s.id = l.student_id left join classes c on c.id = s.class_id
     where l.created_at >= since group by s.id, s.name, c.name order by sum(l.exp) desc limit 5) t;
  return json_build_object('days', d, 'students', n_stu, 'active', n_act, 'sources', srcs,
                           'spent_coins', spent, 'promo_claims', promo, 'top_students', top);
end $$;
revoke execute on function game_stats(int) from public, anon;
revoke execute on function _ledger_src(text) from public, anon, authenticated;
grant execute on function game_stats(int) to authenticated;
