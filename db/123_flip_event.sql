-- SQL 123 · กิจกรรมพลิกเกม ⚔️🔥 — ประลองเป็นช่วงๆ อันดับ 1–3 ของห้องรับ EXP + เหรียญก้อนใหญ่ (ไม่นับเพดานเล่นต่อวัน)
-- ต้องรันหลัง 122 · รันซ้ำได้ · ครูสร้างกิจกรรมที่หน้าครู → ตั้งค่า → กิจกรรมพลิกเกม
-- คะแนน: ดึงจาก game_plays ที่เซิร์ฟเวอร์ตรวจแล้ว (ควิซ/จับคู่/สเปลล์/ประลองครูบุ๊ค/เคมีรัน) ในช่วงวันที่ของกิจกรรม
--        เกมที่เลือก = เกมนั้นเกมเดียว (คะแนนสูงสุด) · เว้นว่าง = ทุกเกม (รวมคะแนนสูงสุดของแต่ละเกม → เก่งรอบด้าน)
-- พลิกเกม: คนที่ตามหลังค่ากลางห้อง (ตัวคูณไล่ตามทัน SQL 122) ได้คะแนนเพิ่ม ×1.25 ของ (ตัวคูณ−1) เช่น ×2 → +25% · ×1.5 → +12.5% (ปิดได้ที่ handicap)
-- จัดอันดับแยกตามห้อง (class) · จบกิจกรรมอัตโนมัติเมื่อพ้นวันสิ้นสุด (ครั้งแรกที่มีใครเปิดหน้าเกม) หรือครูสั่งปิดเอง · มอบรางวัลผ่านแจ้งเตือนรายบุคคล

create table if not exists flip_events (
  id uuid primary key default gen_random_uuid(),
  title text not null, descr text,
  game text check (game is null or game in ('quiz','match','spell','kb','run')),
  starts_on date not null default today_th(), ends_on date not null default today_th() + 6,
  handicap boolean not null default true,
  p1_exp int not null default 300, p1_coins int not null default 150,
  p2_exp int not null default 200, p2_coins int not null default 100,
  p3_exp int not null default 120, p3_coins int not null default 60,
  part_exp int not null default 20, part_coins int not null default 10,
  active boolean not null default true,
  finalized_at timestamptz, created_at timestamptz not null default now());
create table if not exists flip_results (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references flip_events(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  class_id uuid not null, rank int not null, score int not null, adj int not null,
  exp int not null default 0, coins int not null default 0,
  unique (event_id, student_id));
alter table flip_events enable row level security; alter table flip_results enable row level security;
drop policy if exists teacher_all on flip_events; drop policy if exists teacher_all on flip_results;
create policy teacher_all on flip_events for all to authenticated using (is_teacher()) with check (is_teacher());
create policy teacher_all on flip_results for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on flip_events, flip_results from anon;

-- อันดับสดของห้องหนึ่ง (ยังไม่ปิดกิจกรรม)
create or replace function _flip_board(p_event uuid, p_class uuid) returns table (student_id uuid, score int, adj int, rnk int)
language sql stable security definer set search_path = public as $$
  with e as (select * from flip_events where id = p_event),
  best as (
    select gp.student_id, gp.game, max(gp.score) s from game_plays gp
      join students st on st.id = gp.student_id and st.class_id = p_class, e
     where gp.play_date between e.starts_on and e.ends_on and gp.score > 0 and (e.game is null or gp.game = e.game)
     group by gp.student_id, gp.game),
  tot as (select b.student_id, sum(b.s)::int score from best b group by b.student_id)
  select t.student_id, t.score,
         round(t.score * (1 + case when (select handicap from e) then (_play_cap_mult(t.student_id) - 1) * 0.25 else 0 end))::int adj,
         (row_number() over (order by round(t.score * (1 + case when (select handicap from e) then (_play_cap_mult(t.student_id) - 1) * 0.25 else 0 end)) desc, t.score desc, t.student_id))::int rnk
    from tot t
$$;
revoke execute on function _flip_board(uuid, uuid) from public, anon, authenticated;

-- ปิดกิจกรรม: จัดอันดับทุกห้อง → แจกรางวัล + แจ้งเตือน (ซ้ำไม่ได้ ด้วย ref)
create or replace function _flip_finalize(p_event uuid) returns int
language plpgsql security definer set search_path = public as $$
declare e flip_events%rowtype; c record; r record; ex int; co int; n int := 0; lab text;
begin
  select * into e from flip_events where id = p_event for update;
  if not found or e.finalized_at is not null then return 0; end if;
  for c in select distinct class_id from students loop
    for r in select * from _flip_board(e.id, c.class_id) loop
      ex := e.part_exp + case r.rnk when 1 then e.p1_exp when 2 then e.p2_exp when 3 then e.p3_exp else 0 end;
      co := e.part_coins + case r.rnk when 1 then e.p1_coins when 2 then e.p2_coins when 3 then e.p3_coins else 0 end;
      lab := case r.rnk when 1 then '🥇 ชนะเลิศ' when 2 then '🥈 รองชนะเลิศ' when 3 then '🥉 อันดับ 3' else 'ร่วมกิจกรรม' end;
      insert into flip_results (event_id, student_id, class_id, rank, score, adj, exp, coins) values (e.id, r.student_id, c.class_id, r.rnk, r.score, r.adj, ex, co);
      perform award(r.student_id, ex, co, 'กิจกรรมพลิกเกม: ' || e.title || ' (' || lab || ')', 'flip:' || e.id || ':' || r.student_id);
      insert into student_notices (student_id, ref, icon, title, body) values (r.student_id, 'flip:' || e.id,
        case r.rnk when 1 then '🥇' when 2 then '🥈' when 3 then '🥉' else '🔥' end, 'ผลกิจกรรมพลิกเกม: ' || e.title,
        lab || ' · อันดับ ' || r.rnk || ' ของห้อง · คะแนน ' || r.adj || ' · ได้ ' || ex || ' EXP + ' || co || ' เหรียญ') on conflict (student_id, ref) do nothing;
      n := n + 1;
    end loop;
  end loop;
  update flip_events set finalized_at = now() where id = e.id;
  return n;
end $$;
revoke execute on function _flip_finalize(uuid) from public, anon, authenticated;

-- ครูกดปิดกิจกรรมเอง
create or replace function flip_close(p_event uuid) returns int
language plpgsql security definer set search_path = public as $$
begin
  if not is_teacher() then raise exception 'เฉพาะครู'; end if;
  return _flip_finalize(p_event);
end $$;
revoke execute on function flip_close(uuid) from public, anon; grant execute on function flip_close(uuid) to authenticated;

-- นักเรียนดูกิจกรรม (กำลังจัด + ที่จบใน 14 วัน) พร้อมอันดับห้องตัวเอง
create or replace function flip_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cls uuid; e record; out json[] := '{}'; top json; me json; fin boolean;
begin
  select class_id into cls from students where id = sid;
  for e in select * from flip_events where active and ends_on < today_th() and finalized_at is null loop perform _flip_finalize(e.id); end loop;
  for e in select * from flip_events where active and starts_on <= today_th() + 3 and (finalized_at is null or finalized_at > now() - interval '14 days') order by starts_on desc limit 3 loop
    fin := e.finalized_at is not null;
    if fin then
      select coalesce(json_agg(x order by x.rank), '[]'::json) into top from (
        select r.rank, s.name, s.avatar, r.adj as score from flip_results r join students s on s.id = r.student_id where r.event_id = e.id and r.class_id = cls and r.rank <= 10) x;
      select row_to_json(x) into me from (select rank, adj as score, exp, coins from flip_results where event_id = e.id and student_id = sid) x;
    else
      select coalesce(json_agg(x order by x.rank), '[]'::json) into top from (
        select b.rnk as rank, s.name, s.avatar, b.adj as score from _flip_board(e.id, cls) b join students s on s.id = b.student_id where b.rnk <= 10) x;
      select row_to_json(x) into me from (select rnk as rank, adj as score, score as raw from _flip_board(e.id, cls) where student_id = sid) x;
    end if;
    out := out || json_build_object('id', e.id, 'title', e.title, 'descr', e.descr, 'game', e.game, 'starts_on', e.starts_on, 'ends_on', e.ends_on,
      'handicap', e.handicap, 'done', fin, 'upcoming', e.starts_on > today_th(),
      'prizes', json_build_array(json_build_object('exp', e.p1_exp, 'coins', e.p1_coins), json_build_object('exp', e.p2_exp, 'coins', e.p2_coins), json_build_object('exp', e.p3_exp, 'coins', e.p3_coins)),
      'part', json_build_object('exp', e.part_exp, 'coins', e.part_coins),
      'top', top, 'me', me, 'boost', _play_cap_mult(sid));
  end loop;
  return array_to_json(out);
end $$;
revoke execute on function flip_status(uuid) from public; grant execute on function flip_status(uuid) to anon, authenticated;
