-- =====================================================================
-- Chemistria · รอบที่ 26: ประกาศ popup แสดงความยินดี (ได้ SSR / เลื่อนแรงค์) (รันซ้ำได้)
--  · ระบบบันทึกเหตุการณ์อัตโนมัติ → เพื่อนร่วมห้องเห็น popup ตอนเปิดแอป (ย้อนหลัง ≤ 24 ชม.)
--  · ครูปิดได้ที่ตั้งค่า celebrate_enabled = 0
-- =====================================================================
insert into app_settings (key, value) values ('celebrate_enabled', '1') on conflict (key) do nothing;

create table if not exists celebrations (
  id bigint generated always as identity primary key,
  class_id uuid not null references classes(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  kind text not null check (kind in ('ssr', 'rank')),
  title text not null,          -- ชื่อไอเทม SSR หรือชื่อแรงค์ใหม่
  emoji text,
  image text,
  created_at timestamptz not null default now()
);
create index if not exists celebrations_idx on celebrations (class_id, id desc);
alter table celebrations enable row level security;
drop policy if exists teacher_all on celebrations;
create policy teacher_all on celebrations for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on celebrations from anon;
grant select, insert, update, delete on celebrations to authenticated;

-- ได้ SSR จากกาชา
create or replace function trg_cel_ssr() returns trigger
language plpgsql security definer set search_path = public as $$
declare it gacha_items%rowtype; cid uuid;
begin
  if _setting_int('celebrate_enabled', 1) = 0 then return new; end if;
  select * into it from gacha_items where id = new.item_id;
  if found and it.rarity = 'SSR' then
    select class_id into cid from students where id = new.student_id;
    insert into celebrations (class_id, student_id, kind, title, emoji, image)
    values (cid, new.student_id, 'ssr', it.name, it.emoji, it.image_url);
  end if;
  return new;
end $$;
drop trigger if exists cel_ssr on gacha_pulls;
create trigger cel_ssr after insert on gacha_pulls for each row execute function trg_cel_ssr();

-- เลื่อนแรงค์ (เปลี่ยนระดับแรงค์ เช่น Bronze → Silver)
create or replace function trg_cel_rank() returns trigger
language plpgsql security definer set search_path = public as $$
declare a json; b json;
begin
  if new.exp <= old.exp or _setting_int('celebrate_enabled', 1) = 0 then return new; end if;
  a := rank_info(old.exp); b := rank_info(new.exp);
  if (a->>'key') <> (b->>'key') then
    insert into celebrations (class_id, student_id, kind, title, image)
    values (new.class_id, new.id, 'rank', b->>'name', b->>'image');
  end if;
  return new;
end $$;
drop trigger if exists cel_rank on students;
create trigger cel_rank after update of exp on students for each row execute function trg_cel_rank();

-- ดึงประกาศของห้องตัวเอง: p_since = id ล่าสุดที่เคยเห็น (null = เฉพาะ 6 ชม.ล่าสุด)
create or replace function celebrations_feed(p_token uuid, p_since bigint default null) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cid uuid; mx bigint;
begin
  select class_id into cid from students where id = sid;
  select coalesce(max(id), 0) into mx from celebrations where class_id = cid;
  return json_build_object('max', mx, 'items', coalesce((
    select json_agg(x order by x.id) from (
      select c.id, c.kind, c.title, c.emoji, c.image, s.name, (c.student_id = sid) as mine,
             s.char_class
        from celebrations c join students s on s.id = c.student_id
       where c.class_id = cid
         and ((p_since is not null and c.id > p_since and c.created_at > now() - interval '24 hours')
              or (p_since is null and c.created_at > now() - interval '6 hours'))
       order by c.id desc limit 8) x), '[]'::json));
end $$;
revoke execute on function celebrations_feed(uuid, bigint) from public;
grant execute on function celebrations_feed(uuid, bigint) to anon, authenticated;
revoke execute on function trg_cel_ssr(), trg_cel_rank() from public, anon, authenticated;
