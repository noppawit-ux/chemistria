-- SQL 126 · ห้องสมุด 📚 — บทความ/วิดีโอให้นักเรียนอ่านหรือดูจนครบแล้วรับ EXP/เหรียญ
-- ต้องรันหลัง 125 · รันซ้ำได้ · ครูเพิ่มเนื้อหาที่หน้าครู → แท็บมินิเกม → ห้องสมุด
-- กติกา: เปิดอ่านแล้วเริ่มจับเวลา (ฝั่งเซิร์ฟเวอร์) · กดรับรางวัลได้เมื่อครบเวลาขั้นต่ำ (min_secs) และตอบคำถามท้ายเรื่องถูก (ถ้าครูตั้งไว้)
--        รับได้ครั้งเดียวต่อเรื่อง (ref lib:*) · จำกัดจำนวนเรื่องที่ได้รางวัลต่อวัน library_daily_max (ตั้งเป็น 0 = ไม่จำกัด)
--        รางวัลห้องสมุดไม่ถูกเพดาน EXP/เหรียญจากการเล่นเกม

insert into app_settings(key, value) values ('library_daily_max', '5') on conflict (key) do nothing;

create table if not exists library_items (
  id uuid primary key default gen_random_uuid(),
  class_id uuid references classes(id) on delete cascade,      -- ว่าง = ทุกห้อง
  kind text not null default 'article' check (kind in ('article', 'video')),
  title text not null, summary text, icon text not null default '📖', category text,
  body text,                                                     -- บทความ (ขึ้นบรรทัดใหม่ได้ · บรรทัดขึ้นต้น "# " = หัวข้อ)
  url text check (url is null or url = '' or url ~ '^https?://'),            -- วิดีโอ YouTube หรือลิงก์ภายนอก
  min_secs int not null default 60 check (min_secs >= 0),
  exp int not null default 10 check (exp >= 0), coins int not null default 5 check (coins >= 0),
  q_text text, q_opts text, q_ans int check (q_ans is null or q_ans >= 1),   -- ตัวเลือกคั่นด้วย | · q_ans เริ่มที่ 1
  sort int not null default 0, active boolean not null default true, created_at timestamptz not null default now());
create table if not exists library_reads (
  student_id uuid not null references students(id) on delete cascade,
  item_id uuid not null references library_items(id) on delete cascade,
  started_at timestamptz not null default now(), done_at timestamptz, exp int not null default 0, coins int not null default 0,
  primary key (student_id, item_id));
do $$ declare t text; begin
  foreach t in array array['library_items', 'library_reads'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists teacher_all on public.%I', t);
    execute format('create policy teacher_all on public.%I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on public.%I from anon', t);
  end loop; end $$;

create or replace function library_list(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cls uuid;
begin
  select class_id into cls from students where id = sid;
  return json_build_object(
    'today', (select count(*) from library_reads where student_id = sid and done_at >= today_th()::timestamp at time zone 'Asia/Bangkok'),
    'limit', _setting_int('library_daily_max', 5),
    'items', (select coalesce(json_agg(json_build_object('id', i.id, 'kind', i.kind, 'title', i.title, 'summary', i.summary, 'icon', i.icon, 'category', i.category, 'url', i.url,
          'min_secs', i.min_secs, 'exp', i.exp, 'coins', i.coins, 'quiz', nullif(btrim(i.q_text), '') is not null, 'started', r.started_at is not null, 'done', r.done_at is not null)
          order by (r.done_at is not null), i.sort desc, i.created_at desc), '[]'::json)
        from library_items i left join library_reads r on r.item_id = i.id and r.student_id = sid
       where i.active and (i.class_id is null or i.class_id = cls)));
end $$;

create or replace function library_open(p_token uuid, p_item uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cls uuid; i library_items%rowtype; r library_reads%rowtype;
begin
  select class_id into cls from students where id = sid;
  select * into i from library_items where id = p_item and active and (class_id is null or class_id = cls);
  if not found then raise exception 'ไม่พบเนื้อหานี้'; end if;
  insert into library_reads (student_id, item_id) values (sid, i.id) on conflict do nothing;
  select * into r from library_reads where student_id = sid and item_id = i.id;
  return json_build_object('id', i.id, 'kind', i.kind, 'title', i.title, 'icon', i.icon, 'summary', i.summary, 'body', i.body, 'url', i.url,
    'min_secs', i.min_secs, 'exp', i.exp, 'coins', i.coins, 'done', r.done_at is not null,
    'elapsed', greatest(0, floor(extract(epoch from now() - r.started_at))::int),
    'q', case when nullif(btrim(i.q_text), '') is null then null else json_build_object('text', i.q_text, 'opts', string_to_array(coalesce(i.q_opts, ''), '|')) end,
    'got', case when r.done_at is not null then json_build_object('exp', r.exp, 'coins', r.coins) end);
end $$;

create or replace function library_finish(p_token uuid, p_item uuid, p_pick int default null) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cls uuid; i library_items%rowtype; r library_reads%rowtype; lim int := _setting_int('library_daily_max', 5); n int; el int;
begin
  select class_id into cls from students where id = sid;
  select * into i from library_items where id = p_item and active and (class_id is null or class_id = cls);
  if not found then raise exception 'ไม่พบเนื้อหานี้'; end if;
  select * into r from library_reads where student_id = sid and item_id = i.id for update;
  if not found then raise exception 'ต้องเปิดอ่านก่อน'; end if;
  if r.done_at is not null then return json_build_object('already', true, 'exp', r.exp, 'coins', r.coins); end if;
  el := floor(extract(epoch from now() - r.started_at))::int;
  if el < i.min_secs then raise exception 'ยังอ่าน/ดูไม่ครบเวลา (อีก % วินาที)', i.min_secs - el; end if;
  if nullif(btrim(i.q_text), '') is not null and (p_pick is null or p_pick <> i.q_ans) then raise exception 'ตอบคำถามท้ายเรื่องยังไม่ถูก ลองอ่านทบทวนแล้วตอบใหม่'; end if;
  select count(*) into n from library_reads where student_id = sid and done_at >= today_th()::timestamp at time zone 'Asia/Bangkok';
  if lim > 0 and n >= lim then raise exception 'วันนี้รับรางวัลห้องสมุดครบ % เรื่องแล้ว พรุ่งนี้มาอ่านต่อ', lim; end if;
  perform award(sid, i.exp, i.coins, 'ห้องสมุด: ' || i.title, 'lib:' || i.id || ':' || sid);
  update library_reads set done_at = now(), exp = i.exp, coins = i.coins where student_id = sid and item_id = i.id;
  return json_build_object('exp', i.exp, 'coins', i.coins);
end $$;

revoke execute on function library_list(uuid), library_open(uuid, uuid), library_finish(uuid, uuid, int) from public;
grant execute on function library_list(uuid), library_open(uuid, uuid), library_finish(uuid, uuid, int) to anon, authenticated;

-- เนื้อหาตัวอย่าง 2 เรื่อง (ครูแก้/ลบได้)
insert into library_items (kind, title, summary, icon, category, body, min_secs, exp, coins, q_text, q_opts, q_ans, sort)
select 'article', 'อะตอมคืออะไร', 'อนุภาคเล็กที่สุดของธาตุ ประกอบด้วยโปรตอน นิวตรอน และอิเล็กตรอน', '⚛️', 'พื้นฐานเคมี',
  E'# อะตอม\nสารทุกอย่างรอบตัวประกอบด้วยอะตอม อะตอมเป็นหน่วยเล็กที่สุดของธาตุที่ยังคงสมบัติของธาตุนั้นไว้\n# ส่วนประกอบของอะตอม\n• โปรตอน (p) มีประจุบวก อยู่ในนิวเคลียส\n• นิวตรอน (n) ไม่มีประจุ อยู่ในนิวเคลียส\n• อิเล็กตรอน (e) มีประจุลบ เคลื่อนที่รอบนิวเคลียส\n# เลขอะตอม\nเลขอะตอมคือจำนวนโปรตอนในนิวเคลียส ธาตุแต่ละชนิดมีเลขอะตอมไม่เหมือนกัน เช่น ไฮโดรเจนมี 1 โปรตอน คาร์บอนมี 6 โปรตอน\nอะตอมที่เป็นกลางทางไฟฟ้ามีจำนวนอิเล็กตรอนเท่ากับจำนวนโปรตอน',
  30, 5, 3, 'อะตอมของคาร์บอนมีกี่โปรตอน', 'ไม่มีโปรตอน|1 ตัว|6 ตัว|12 ตัวเสมอ', 3, 10
 where not exists (select 1 from library_items where title = 'อะตอมคืออะไร');
insert into library_items (kind, title, summary, icon, category, body, min_secs, exp, coins, q_text, q_opts, q_ans, sort)
select 'article', 'อ่านตารางธาตุให้เป็น', 'คาบ หมู่ และตำแหน่งของธาตุบอกอะไรเราได้บ้าง', '🧪', 'พื้นฐานเคมี',
  E'# ตารางธาตุจัดอย่างไร\nตารางธาตุเรียงธาตุตามเลขอะตอมจากน้อยไปมาก\n• แถวแนวนอนเรียกว่า คาบ\n• แถวแนวตั้งเรียกว่า หมู่\n# ธาตุในหมู่เดียวกัน\nธาตุที่อยู่หมู่เดียวกันมีสมบัติทางเคมีคล้ายกัน เพราะมีจำนวนเวเลนซ์อิเล็กตรอนเท่ากัน เช่น ลิเทียม โซเดียม โพแทสเซียม อยู่หมู่ 1 ทำปฏิกิริยากับน้ำได้รุนแรง\n# โลหะ อโลหะ และกึ่งโลหะ\nธาตุส่วนใหญ่เป็นโลหะอยู่ด้านซ้ายและกลางตาราง อโลหะอยู่ด้านขวาบน และมีกึ่งโลหะคั่นอยู่ตามแนวขั้นบันได',
  30, 5, 3, 'ธาตุที่อยู่หมู่เดียวกันมีสมบัติคล้ายกัน เพราะเหตุใด', 'มีเลขอะตอมเท่ากัน|มีเวเลนซ์อิเล็กตรอนเท่ากัน|อยู่คาบเดียวกัน|มีมวลเท่ากัน', 2, 9
 where not exists (select 1 from library_items where title = 'อ่านตารางธาตุให้เป็น');

-- ข่าวหน้าแรก
delete from news_posts where ends_at is not null and ends_at < today_th();
insert into news_posts (kind, title, summary, body, image, sort, active, ends_at)
select 'news', 'เปิดห้องสมุดแล้ว 📚 อ่าน/ดูแล้วรับ EXP และเหรียญ',
  'อ่านบทความหรือดูวิดีโอให้ครบ ตอบคำถามท้ายเรื่อง รับ EXP + เหรียญ',
  E'• เข้าได้จาก หอสมุดอะตอม ในแผนที่เมือง หรือรายการเกม\n• อ่าน/ดูให้ครบเวลาที่กำหนด แล้วตอบคำถามท้ายเรื่องให้ถูก\n• รับรางวัลได้ครั้งเดียวต่อเรื่อง และไม่เกิน 5 เรื่องต่อวัน\n• ต้องรีเฟรชหน้าเว็บให้เป็นเวอร์ชัน 2.82',
  'assets/news/promo.jpg', 130, true, today_th() + 30
 where not exists (select 1 from news_posts where title = 'เปิดห้องสมุดแล้ว 📚 อ่าน/ดูแล้วรับ EXP และเหรียญ');
