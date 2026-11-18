-- 97: ดาวพิชิตแรงค์ + สถิติหน้าหลัก (เวลาที่ใช้สู้ / มอนที่ชนะ / คำถามที่ตอบ)
-- ต้องรันหลัง 69 (ด่านบอสเลื่อนแรงค์) · รันซ้ำได้
-- กติกา: ชนะบอสด่านเลื่อนแรงค์ = "พิชิตแรงค์" → ได้ดาว ⭐ ตามที่ครูตั้งต่อแรงค์ (ch_ranks.star_bonus) · ได้ครั้งเดียวต่อแรงค์
--        จำนวนดาวบันทึกตามค่า ณ วันที่พิชิต (ครูแก้ค่าทีหลังไม่ย้อนไปเปลี่ยนของเดิม)
-- สถิติคิดจากตาราง battles (การสู้มอนสเตอร์) ไม่นับเกมอื่น · เวลาต่อการสู้ 1 ครั้งนับไม่เกิน 30 นาที (กันเปิดหน้าค้างไว้)

alter table ch_ranks add column if not exists star_bonus int not null default 0;

-- ค่าเริ่มต้นดาวต่อแรงค์ (ตั้งครั้งเดียว แก้ได้ที่แอดมิน → ตั้งค่า → แรงค์ คอลัมน์ "ดาวที่ได้")
do $$ begin
  if not exists (select 1 from ch_ranks where star_bonus > 0) then
    update ch_ranks set star_bonus = case key when 'silver' then 1 when 'gold' then 2 when 'platinum' then 3 when 'emerald' then 4
      when 'diamond' then 5 when 'master' then 6 when 'grandmaster' then 8 when 'challenger' then 10 else 0 end;
  end if;
end $$;

create table if not exists rank_stars (
  student_id uuid not null references students(id) on delete cascade,
  rank_key text not null,
  stars int not null check (stars >= 0),
  earned_at timestamptz not null default now(),
  primary key (student_id, rank_key)
);
alter table rank_stars enable row level security;
drop policy if exists teacher_all on rank_stars;
create policy teacher_all on rank_stars for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on rank_stars from anon;
grant select, insert, update, delete on rank_stars to authenticated;

-- ย้อนหลัง: คนที่เคยผ่านด่านไปแล้วได้ดาวตามค่าปัจจุบัน
insert into rank_stars (student_id, rank_key, stars, earned_at)
select p.student_id, p.rank_key, r.star_bonus, p.passed_at
  from rank_trial_pass p join ch_ranks r on r.key = p.rank_key
 where r.star_bonus > 0
on conflict do nothing;

-- ชนะบอสด่าน → ผ่านด่าน + เหรียญ + ดาว
create or replace function trg_rank_trial() returns trigger
language plpgsql security definer set search_path = public as $$
declare st students%rowtype; gr ch_ranks%rowtype; ri json; c int := _setting_int('rank_trial_coins', 50);
begin
  if new.status = 'won' and old.status is distinct from 'won' and new.trial_rank is not null then
    insert into rank_trial_pass (student_id, rank_key) values (new.student_id, new.trial_rank) on conflict do nothing;
    if found then
      select * into gr from ch_ranks where key = new.trial_rank;
      if c > 0 then perform award(new.student_id, 0, c, 'ผ่านด่านเลื่อนแรงค์ ' || gr.name || ' 🎖️', 'trial:' || new.trial_rank); end if;
      if gr.star_bonus > 0 then
        insert into rank_stars (student_id, rank_key, stars) values (new.student_id, gr.key, gr.star_bonus) on conflict do nothing;
      end if;
      select * into st from students where id = new.student_id;
      ri := _rank_info_s(st.id, st.exp);
      if _setting_int('celebrate_enabled', 1) = 1 then
        insert into celebrations (class_id, student_id, kind, title, image) values (st.class_id, st.id, 'rank', ri->>'name', ri->>'image');
      end if;
    end if;
  end if;
  return new;
end $$;
revoke execute on function trg_rank_trial() from public, anon, authenticated;

-- สถิติหน้าหลักของนักเรียน
create or replace function home_stats(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); v_st json; v_list json; v_nxt json; v_tot int;
begin
  select coalesce(sum(x.stars), 0) into v_tot from rank_stars x where x.student_id = sid;
  select coalesce(json_agg(json_build_object('key', r.key, 'name', r.name, 'image', r.image, 'stars', x.stars, 'at', x.earned_at) order by r.sort), '[]'::json)
    into v_list from rank_stars x join ch_ranks r on r.key = x.rank_key where x.student_id = sid;
  -- แรงค์ถัดไปที่ยังไม่พิชิตและมีดาวให้ (ด่านที่เปิดอยู่)
  select json_build_object('key', r.key, 'name', r.name, 'image', r.image, 'stars', r.star_bonus, 'min_exp', r.min_exp) into v_nxt
    from ch_ranks r
   where r.star_bonus > 0 and exists (select 1 from monsters m where m.trial_rank = r.key and m.active)
     and not exists (select 1 from rank_stars x where x.student_id = sid and x.rank_key = r.key)
   order by r.sort limit 1;
  select json_build_object(
      'fights',   count(*),
      'won',      count(*) filter (where status = 'won' and trial_rank is null),
      'lost',     count(*) filter (where status = 'lost'),
      'fled',     count(*) filter (where status = 'fled'),
      'monsters', count(distinct monster_id) filter (where status = 'won' and trial_rank is null),
      'bosses',   count(*) filter (where status = 'won' and trial_rank is not null),
      'secs',     coalesce(sum(least(1800, greatest(0, extract(epoch from (finished_at - created_at))))) filter (where finished_at is not null), 0)::int,
      'questions', coalesce(sum(greatest(0, cardinality(used_q) - case when status = 'active' and cur_q is not null then 1 else 0 end)), 0)::int,
      'correct',  coalesce(sum(correct), 0)::int)
    into v_st from battles where student_id = sid;
  return json_build_object('stars', v_tot, 'star_list', v_list, 'next', v_nxt, 'stats', v_st);
end $$;
revoke execute on function home_stats(uuid) from public;
grant execute on function home_stats(uuid) to anon, authenticated;
