-- =====================================================================
-- Chemistria · รอบที่ 13: บอร์ดกระดานสาธารณะ (ประกาศครู + โพสต์นักเรียน) (รันซ้ำได้)
--  · ครู (แอดมิน) โพสต์ได้ทั้งห้องเดียวหรือทุกห้อง ปักหมุด/ซ่อน/ลบได้
--  · นักเรียนโพสต์ได้ในห้องตัวเอง (ไม่เกิน 3 โพสต์/วัน, ไม่เกิน 500 ตัวอักษร) ลบโพสต์ตัวเองได้
--  · นักเรียนเห็นประกาศของห้องตัวเอง + ประกาศทุกห้อง
-- =====================================================================
create table if not exists board_posts (
  id uuid primary key default gen_random_uuid(),
  class_id uuid references classes(id) on delete cascade,          -- null = ทุกห้อง
  author_kind text not null default 'student' check (author_kind in ('teacher','student')),
  student_id uuid references students(id) on delete cascade,
  title text,
  body text not null check (char_length(body) between 1 and 1000),
  pinned boolean not null default false,
  hidden boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists board_posts_idx on board_posts (class_id, created_at desc);
alter table students add column if not exists board_seen timestamptz;

alter table board_posts enable row level security;
drop policy if exists teacher_all on board_posts;
create policy teacher_all on board_posts for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on board_posts from anon;
grant select, insert, update, delete on board_posts to authenticated;

-- รายการบอร์ดสำหรับนักเรียน + จำนวนที่ยังไม่ได้อ่าน
create or replace function board_list(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); s students%rowtype;
begin
  select * into s from students where id = sid;
  return json_build_object(
    'unread', (select count(*) from board_posts b
                where not b.hidden and (b.class_id is null or b.class_id = s.class_id)
                  and coalesce(b.student_id, '00000000-0000-0000-0000-000000000000'::uuid) <> sid
                  and b.created_at > coalesce(s.board_seen, 'epoch'::timestamptz))::int,
    'posts', (select coalesce(json_agg(x order by x.pinned desc, x.created_at desc), '[]'::json) from (
        select b.id, b.title, b.body, b.pinned, b.created_at, b.author_kind,
               (b.class_id is null) as all_classes, (b.student_id = sid) as mine,
               case when b.author_kind = 'teacher' then 'ครูบุ๊ค' else st.name end as author,
               case when b.author_kind = 'student' then st.char_class end as char_class
          from board_posts b left join students st on st.id = b.student_id
         where not b.hidden and (b.class_id is null or b.class_id = s.class_id)
         order by b.pinned desc, b.created_at desc limit 60) x));
end $$;

create or replace function board_mark_seen(p_token uuid) returns void
language plpgsql security definer set search_path = public as $$
begin update students set board_seen = now() where id = _sid(p_token); end $$;

create or replace function board_post(p_token uuid, p_title text, p_body text) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); s students%rowtype; n int; b text := btrim(coalesce(p_body, '')); nid uuid;
begin
  select * into s from students where id = sid;
  if char_length(b) < 1 then raise exception 'พิมพ์ข้อความก่อนโพสต์'; end if;
  if char_length(b) > 500 then raise exception 'ข้อความยาวเกิน 500 ตัวอักษร'; end if;
  select count(*) into n from board_posts where student_id = sid and (created_at at time zone 'Asia/Bangkok')::date = today_th();
  if n >= 3 then raise exception 'โพสต์ได้วันละ 3 ครั้ง วันนี้ครบแล้ว'; end if;
  insert into board_posts (class_id, author_kind, student_id, title, body)
  values (s.class_id, 'student', sid, nullif(left(btrim(coalesce(p_title, '')), 80), ''), b) returning board_posts.id into nid;
  return json_build_object('ok', true, 'id', nid);
end $$;

create or replace function board_delete(p_token uuid, p_id uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  delete from board_posts where id = p_id and student_id = _sid(p_token) and author_kind = 'student';
  if not found then raise exception 'ลบไม่ได้ (ลบได้เฉพาะโพสต์ของตัวเอง)'; end if;
end $$;

revoke execute on function board_list(uuid), board_mark_seen(uuid), board_post(uuid, text, text), board_delete(uuid, uuid) from public;
grant execute on function board_list(uuid), board_mark_seen(uuid), board_post(uuid, text, text), board_delete(uuid, uuid) to anon, authenticated;

-- ประกาศตัวอย่าง (ใส่ครั้งเดียวตอนบอร์ดยังว่าง)
insert into board_posts (class_id, author_kind, title, body, pinned)
select null, 'teacher', '📢 ยินดีต้อนรับสู่บอร์ดเคมีเรีย', 'ที่นี่คือบอร์ดประกาศของห้อง — ครูจะแปะประกาศสำคัญไว้ด้านบน นักเรียนโพสต์ถามตอบหรือแชร์เทคนิคได้ (วันละ 3 โพสต์) ขอให้ใช้ถ้อยคำสุภาพนะ', true
where not exists (select 1 from board_posts);
