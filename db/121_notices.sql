-- SQL 121 · แจ้งเตือนรายบุคคล (กระดิ่ง 🔔) + ข่าวหน้าแรกชุดใหม่ + ลบข่าว/อีเว้นท์ที่จบแล้ว
-- ต้องรันหลัง 120 · รันซ้ำได้ · ใช้แจ้งเรื่องปรับสมดุล EXP/เหรียญ (นักเรียนที่ถูกหัก EXP ย้อนหลังจะเห็นยอดของตัวเอง)

create table if not exists student_notices (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  ref text,                                   -- กันสร้างซ้ำ (student_id, ref)
  icon text not null default '📢', title text not null, body text,
  created_at timestamptz not null default now(), read_at timestamptz,
  unique (student_id, ref));
create index if not exists student_notices_sid on student_notices (student_id, created_at desc);
alter table student_notices enable row level security;
drop policy if exists teacher_all on student_notices;
create policy teacher_all on student_notices for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on student_notices from anon;

-- นักเรียนดูแจ้งเตือนของตัวเอง (ล่าสุด 30 รายการ)
create or replace function my_notices(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  return coalesce((select json_agg(x order by x.created_at desc) from (
    select id, icon, title, body, created_at, read_at is not null as read from student_notices
     where student_id = sid order by created_at desc limit 30) x), '[]'::json);
end $$;

-- ทำเครื่องหมายอ่านแล้ว (p_id ว่าง = ทั้งหมด)
create or replace function notice_read(p_token uuid, p_id uuid default null) returns void
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  update student_notices set read_at = now() where student_id = sid and read_at is null and (p_id is null or id = p_id);
end $$;
revoke execute on function my_notices(uuid), notice_read(uuid, uuid) from public;
grant execute on function my_notices(uuid), notice_read(uuid, uuid) to anon, authenticated;

-- สร้างประกาศปรับสมดุลให้นักเรียนทุกคน (+ ข้อความเฉพาะตัวถ้าโดนหัก EXP ย้อนหลัง) · ซ้ำไม่ได้
create or replace function _notice_balance() returns int
language plpgsql security definer set search_path = public as $$
declare r record; n int := 0; cx int := _setting_int('play_daily_cap_exp', 120); cc int := _setting_int('play_daily_cap_coins', 180);
begin
  for r in select s.id, coalesce(f.cut, 0) cut, coalesce(f.days, 0) days from students s
             left join (select student_id, sum(cut)::int cut, count(*)::int days from exp_fix_log group by student_id) f on f.student_id = s.id loop
    insert into student_notices (student_id, ref, icon, title, body) values (r.id, 'balance:2026-11', '⚖️', 'ปรับสมดุล EXP และเหรียญ',
      'EXP จากการเล่น (มินิเกม ต่อสู้ ท้าดวล ดันเจี้ยน หีบ) ได้สูงสุด ' || cx || ' ต่อวัน และเหรียญสูงสุด ' || cc || ' ต่อวัน · เช็คชื่อ/ส่งงาน/เควส/รางวัลครูไม่นับรวม · เกณฑ์แรงค์ Diamond ขึ้นไปยากขึ้นเล็กน้อย (Master 7,000 · Grandmaster 10,000 · Challenger 14,500) · รางวัล Achievement และดันเจี้ยนลดลงครึ่งหนึ่ง (ที่รับไปแล้วไม่เรียกคืน)')
      on conflict (student_id, ref) do nothing;
    if found then n := n + 1; end if;
    if r.cut > 0 then
      insert into student_notices (student_id, ref, icon, title, body) values (r.id, 'balance-cut:2026-11', '🔧', 'EXP ของคุณถูกปรับย้อนหลัง −' || r.cut,
        'ครูหัก EXP ส่วนที่เกินเพดานการเล่นรายวันออกบางส่วน (ครึ่งหนึ่งของส่วนที่เกิน) รวม ' || r.cut || ' EXP จาก ' || r.days || ' วัน · ดูรายการ "ปรับสมดุล EXP" ในประวัติ · เหรียญที่ใช้ไปแล้วไม่เรียกคืน · แรงค์อาจลดลงเล็กน้อยตามเกณฑ์ใหม่ ขอบคุณที่เข้าใจนะ 🙏')
        on conflict (student_id, ref) do nothing;
    end if;
  end loop;
  return n;
end $$;
revoke execute on function _notice_balance() from public, anon, authenticated;

do $$ begin
  if not exists (select 1 from bal_patch where key = 'notice_balance_121') then
    perform _notice_balance();
    -- ข่าวหน้าแรก: ลบที่จบแล้ว แล้วเพิ่มข่าวใหม่
    delete from news_posts where ends_at is not null and ends_at < today_th();
    insert into news_posts (kind, title, summary, body, sort, active, ends_at)
    select 'news', 'ปรับสมดุล EXP และเหรียญ ⚖️',
      'เล่นเกมได้ EXP สูงสุด 120 และเหรียญ 180 ต่อวัน · แรงค์ Diamond ขึ้นไปยากขึ้นเล็กน้อย',
      E'• EXP จากการเล่น (มินิเกม ต่อสู้ ท้าดวล ดันเจี้ยน หีบ) สูงสุด 120 ต่อวัน · เหรียญสูงสุด 180 ต่อวัน\n• เช็คชื่อ ส่งงาน เควส และรางวัลจากครู ไม่นับรวมในเพดาน\n• เกณฑ์แรงค์: Diamond 4,700 · Master 7,000 · Grandmaster 10,000 · Challenger 14,500 EXP\n• รางวัล Achievement และดันเจี้ยนลดลงครึ่งหนึ่ง (ที่รับไปแล้วไม่เรียกคืน)\n• วันที่ได้ EXP เกินเพดานมาก ครูหักส่วนเกินออกบางส่วน ดูในแจ้งเตือน 🔔 ของแต่ละคน',
      100, true, today_th() + 21
     where not exists (select 1 from news_posts where title = 'ปรับสมดุล EXP และเหรียญ ⚖️');
    insert into bal_patch (key) values ('notice_balance_121');
  end if;
end $$;
