-- 27: ข่าวสาร/อีเว้นท์ สไลด์หน้าแรก (ครูเพิ่ม/แก้ได้ในหน้าครู)
create table if not exists news_posts (
  id uuid primary key default gen_random_uuid(),
  kind text not null default 'news' check (kind in ('news','event')),
  title text not null,
  summary text,                       -- ข้อความสั้นบนสไลด์
  body text,                          -- รายละเอียดเต็มเมื่อกดดู
  image text,                         -- พาธรูป (เช่น assets/news/rank.jpg) หรือ URL https
  starts_at date,                     -- อีเว้นท์: วันเริ่ม (ไม่บังคับ)
  ends_at date,                       -- แสดงถึงวันนี้ (ไม่บังคับ)
  sort int not null default 0,        -- เลขมากขึ้นก่อน
  active boolean not null default true,
  created_at timestamptz default now()
);
alter table news_posts enable row level security;
drop policy if exists teacher_all on news_posts;
create policy teacher_all on news_posts for all using (is_teacher()) with check (is_teacher());
revoke all on news_posts from anon;

create or replace function news_list(p_token uuid) returns json
language plpgsql stable security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  return coalesce((select json_agg(x order by x.sort desc, x.created_at desc) from (
    select id, kind, title, summary, body, image, starts_at, ends_at, sort, created_at from news_posts
     where active and (ends_at is null or ends_at >= today_th()) order by sort desc, created_at desc limit 12) x), '[]'::json);
end $$;
revoke execute on function news_list(uuid) from public;
grant execute on function news_list(uuid) to anon, authenticated;

-- ให้ผู้สังเกตการณ์ (โหมดส่อง) เรียก news_list ได้
create or replace function _sid(p_token uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare v uuid; o boolean; fn text;
begin
  select student_id, observer into v, o from student_sessions where token = p_token and expires_at > now();
  if v is null then raise exception 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่'; end if;
  if o then
    fn := regexp_replace(coalesce(current_setting('request.path', true), ''), '^.*/', '');
    if fn not in ('student_dashboard','student_extras','hall_of_fame','board_list','celebrations_feed','game_status','spell_status','kb_status','news_list') then
      raise exception 'โหมดส่องนักเรียน: ดูได้อย่างเดียว';
    end if;
  end if;
  return v;
end $$;

insert into news_posts (kind,title,summary,body,image,sort)
select 'event','ประลองครูบุ๊ค เปิดแล้ว!','8 รอบ 8 มินิเกม เวลาลดทุกรอบ ชนะรับ EXP + เหรียญ',
 E'โหมดใหม่ในแท็บ เกม: ท้าสู้ครูบุ๊คสุดโหด\n• 8 รอบ 8 มินิเกม สลับลำดับทุกครั้ง\n• มีหัวใจ 3 ดวง ตอบผิดเสียหัวใจ\n• สู้ใน 4 สนาม เปลี่ยนตามรอบ\n• ชนะรับ EXP และเหรียญ (มีเพดานต่อวัน)\n• ห้อง ม.1–3 ได้ชุดข้อสอบ ม.ต้น','assets/news/challenge.jpg',30
where not exists (select 1 from news_posts where title='ประลองครูบุ๊ค เปิดแล้ว!');
insert into news_posts (kind,title,summary,body,image,sort)
select 'news','ปรับระบบแรงค์ใหม่','เกณฑ์ไต่แรงค์ยากขึ้น เพื่อให้แต่ละขั้นมีความหมาย',
 E'เกณฑ์ EXP ใหม่: Bronze 250 · Silver 600 · Gold 1,100 · Platinum 1,800 · Emerald 2,700 · Diamond 3,900 · Master 5,400 · Grandmaster 7,200 · Challenger 9,500\nเลเวลไม่เปลี่ยน แต่แรงค์ของบางคนอาจลดลงจากเดิม ใครอยากไต่แรงค์ ทำเควส ส่งงาน และเล่นเกมสม่ำเสมอ','assets/news/rank.jpg',20
where not exists (select 1 from news_posts where title='ปรับระบบแรงค์ใหม่');
insert into news_posts (kind,title,summary,body,image,sort)
select 'news','ช่องอุปกรณ์ข้างตัวละคร','แตะช่องเพื่อสลับชุด เอฟเฟกต์ หมวก สัตว์เลี้ยง ได้ทันที',
 E'ที่หน้าหลัก ข้างตัวละครมี 8 ช่องอุปกรณ์: ชุด เอฟเฟกต์ ไอเทม หมวก สัตว์เลี้ยง กรอบ พื้นหลัง และฉายา\nแตะช่องไหนก็เลือกไอเทมที่มีอยู่มาใส่ได้เลย ไม่ต้องเข้าหน้าแต่งตัว','assets/news/equip.jpg',10
where not exists (select 1 from news_posts where title='ช่องอุปกรณ์ข้างตัวละคร');
