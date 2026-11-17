-- =====================================================================
-- 83: กดอิโมจิให้ตัวละครเพื่อนในห้อง (❤️ 👍 🔥 😄 ⭐ 👏) (รันซ้ำได้)
--  - ดูตัวละครเพื่อน (char_view) · กดอิโมจิ (char_react) · วันละ 1 อิโมจิต่อเพื่อน 1 คน (กดใหม่ = เปลี่ยนอิโมจิ, กดซ้ำ = ยกเลิก)
--  - จำกัดจำนวนเพื่อนที่กดให้ได้ต่อวัน (ตั้งค่า react_daily_max, ค่าเริ่มต้น 15) · ไม่มีเหรียญ/คะแนน
--  - เจ้าของเห็นยอดรวมอิโมจิที่ได้รับที่หน้าตัวละครของตัวเอง
-- =====================================================================
create table if not exists char_reactions (
  from_id uuid not null references students(id) on delete cascade,
  to_id uuid not null references students(id) on delete cascade,
  day date not null,
  emoji text not null check (emoji in ('❤️', '👍', '🔥', '😄', '⭐', '👏')),
  created_at timestamptz not null default now(),
  primary key (from_id, to_id, day),
  check (from_id <> to_id)
);
create index if not exists char_reactions_to on char_reactions (to_id);
alter table char_reactions enable row level security;
drop policy if exists teacher_all on char_reactions;
create policy teacher_all on char_reactions for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on char_reactions from anon;
grant select, insert, update, delete on char_reactions to authenticated;
insert into app_settings (key, value) values ('react_daily_max', '15') on conflict (key) do nothing;

create or replace function _char_view(p_sid uuid, p_target uuid) returns json
language plpgsql stable security definer set search_path = public as $$
declare t students%rowtype; today date := today_th();
begin
  select * into t from students where id = p_target;
  return json_build_object('no', t.no, 'name', t.name, 'avatar', t.avatar, 'char_class', t.char_class, 'level', level_for(t.exp),
    'rank_info', _rank_info_s(t.id, t.exp), 'decor', _decor_of(t.id), 'is_me', t.id = p_sid,
    'totals', coalesce((select json_object_agg(emoji, n) from (select emoji, count(*) n from char_reactions where to_id = t.id group by emoji) x), '{}'::json),
    'total', (select count(*) from char_reactions where to_id = t.id),
    'mine', (select emoji from char_reactions where from_id = p_sid and to_id = t.id and day = today),
    'sent_today', (select count(*) from char_reactions where from_id = p_sid and day = today),
    'limit', _setting_int('react_daily_max', 15));
end $$;

create or replace function char_view(p_token uuid, p_no int default null) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); tid uuid;
begin
  if p_no is null then tid := sid;
  else select o.id into tid from students o where o.no = p_no and o.class_id = (select class_id from students where id = sid);
    if tid is null then raise exception 'ไม่พบเพื่อนคนนี้ในห้อง'; end if;
  end if;
  return _char_view(sid, tid);
end $$;

create or replace function char_react(p_token uuid, p_no int, p_emoji text) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); tid uuid; today date := today_th(); cur text;
begin
  select o.id into tid from students o where o.no = p_no and o.class_id = (select class_id from students where id = sid);
  if tid is null then raise exception 'ไม่พบเพื่อนคนนี้ในห้อง'; end if;
  if tid = sid then raise exception 'กดให้ตัวละครของตัวเองไม่ได้'; end if;
  if p_emoji is not null and p_emoji not in ('❤️', '👍', '🔥', '😄', '⭐', '👏') then raise exception 'อิโมจินี้ไม่รองรับ'; end if;
  select emoji into cur from char_reactions where from_id = sid and to_id = tid and day = today;
  if p_emoji is null or p_emoji = cur then
    delete from char_reactions where from_id = sid and to_id = tid and day = today;
  elsif cur is not null then
    update char_reactions set emoji = p_emoji, created_at = now() where from_id = sid and to_id = tid and day = today;
  else
    if (select count(*) from char_reactions where from_id = sid and day = today) >= _setting_int('react_daily_max', 15) then
      raise exception 'วันนี้กดให้เพื่อนครบ % คนแล้ว พรุ่งนี้มาใหม่นะ', _setting_int('react_daily_max', 15);
    end if;
    insert into char_reactions (from_id, to_id, day, emoji) values (sid, tid, today, p_emoji);
  end if;
  return _char_view(sid, tid);
end $$;

revoke execute on function _char_view(uuid, uuid) from public, anon, authenticated;
revoke execute on function char_view(uuid, int), char_react(uuid, int, text) from public;
grant execute on function char_view(uuid, int), char_react(uuid, int, text) to anon, authenticated;
