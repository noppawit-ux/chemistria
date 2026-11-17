-- =====================================================================
-- 85: อีเว้นท์เช็คอินรับของรางวัล (ครูเปิด-ปิดเป็นช่วงเวลา · นักเรียนทุกคนกดรับได้คนละ 1 ครั้งต่ออีเว้นท์) · รันซ้ำได้
--  รางวัล: EXP / เหรียญ / ตั๋วกาชาฟรี / ไอเทมตกแต่ง 1 ชิ้น / การ์ด 1 ใบ (ไม่บังคับ แต่ต้องมีอย่างน้อย 1 อย่าง)
-- =====================================================================
create table if not exists checkin_events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  message text not null default '',
  starts_at timestamptz not null default now(),
  ends_at timestamptz not null,
  exp int not null default 0 check (exp >= 0),
  coins int not null default 0 check (coins >= 0),
  pulls int not null default 0 check (pulls >= 0),
  decor_id uuid references decor_items(id) on delete set null,
  card_id uuid references cards(id) on delete set null,
  closed boolean not null default false,
  created_at timestamptz not null default now()
);
create table if not exists checkin_claims (
  event_id uuid not null references checkin_events(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  claimed_at timestamptz not null default now(),
  primary key (event_id, student_id)
);
create index if not exists checkin_claims_st on checkin_claims (student_id);
alter table checkin_events enable row level security;
alter table checkin_claims enable row level security;
drop policy if exists teacher_all on checkin_events;
create policy teacher_all on checkin_events for all to authenticated using (is_teacher()) with check (is_teacher());
drop policy if exists teacher_all on checkin_claims;
create policy teacher_all on checkin_claims for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on checkin_events, checkin_claims from anon;

-- ครู: เปิดอีเว้นท์ทันที p_hours ชั่วโมง
create or replace function admin_checkin_open(p_title text, p_message text, p_hours numeric, p_exp int default 0, p_coins int default 0,
                                              p_pulls int default 0, p_decor uuid default null, p_card uuid default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare id uuid;
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  if btrim(coalesce(p_title, '')) = '' then raise exception 'ใส่ชื่ออีเว้นท์ก่อน'; end if;
  if coalesce(p_hours, 0) <= 0 or p_hours > 24 * 60 then raise exception 'ระยะเวลาต้องอยู่ระหว่าง 0–1440 ชั่วโมง'; end if;
  if coalesce(p_exp, 0) < 0 or coalesce(p_coins, 0) < 0 or coalesce(p_pulls, 0) < 0 or p_exp > 10000 or p_coins > 10000 or p_pulls > 50 then
    raise exception 'จำนวนรางวัลไม่ถูกต้อง (EXP/เหรียญ ≤ 10000 · ตั๋ว ≤ 50)'; end if;
  if coalesce(p_exp, 0) = 0 and coalesce(p_coins, 0) = 0 and coalesce(p_pulls, 0) = 0 and p_decor is null and p_card is null then
    raise exception 'ยังไม่ได้เลือกรางวัล'; end if;
  insert into checkin_events (title, message, ends_at, exp, coins, pulls, decor_id, card_id)
  values (left(btrim(p_title), 80), left(btrim(coalesce(p_message, '')), 200), now() + make_interval(secs => (p_hours * 3600)::int),
          coalesce(p_exp, 0), coalesce(p_coins, 0), coalesce(p_pulls, 0), p_decor, p_card) returning checkin_events.id into id;
  return id;
end $$;
revoke execute on function admin_checkin_open(text, text, numeric, int, int, int, uuid, uuid) from public, anon;
grant execute on function admin_checkin_open(text, text, numeric, int, int, int, uuid, uuid) to authenticated;

-- นักเรียน: อีเว้นท์ที่เปิดอยู่ตอนนี้ + สถานะว่ารับแล้วหรือยัง
create or replace function checkin_list(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  return coalesce((select json_agg(json_build_object('id', e.id, 'title', e.title, 'message', e.message, 'ends_at', e.ends_at,
            'exp', e.exp, 'coins', e.coins, 'pulls', e.pulls, 'decor', d.name, 'decor_emoji', d.emoji, 'card', c.name, 'card_emoji', c.emoji,
            'claimed', exists (select 1 from checkin_claims k where k.event_id = e.id and k.student_id = sid)) order by e.ends_at)
          from checkin_events e left join decor_items d on d.id = e.decor_id left join cards c on c.id = e.card_id
         where not e.closed and now() >= e.starts_at and now() < e.ends_at), '[]'::json);
end $$;

-- นักเรียน: กดรับรางวัล (คนละ 1 ครั้งต่ออีเว้นท์)
create or replace function checkin_claim(p_token uuid, p_event uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); e checkin_events%rowtype; dn text; cn text;
begin
  select * into e from checkin_events where id = p_event for share;
  if not found or e.closed or now() < e.starts_at or now() >= e.ends_at then raise exception 'อีเว้นท์นี้ปิดแล้ว หรือยังไม่เปิด'; end if;
  insert into checkin_claims (event_id, student_id) values (e.id, sid) on conflict do nothing;
  if not found then raise exception 'คุณรับรางวัลอีเว้นท์นี้แล้ว'; end if;
  if e.exp > 0 or e.coins > 0 then perform award(sid, e.exp, e.coins, '🎟️ เช็คอิน: ' || e.title, 'checkin:' || e.id); end if;
  if e.pulls > 0 then update students set free_pulls = free_pulls + e.pulls where id = sid; end if;
  if e.decor_id is not null then
    insert into student_decor (student_id, item_id, source) values (sid, e.decor_id, 'teacher') on conflict do nothing;
    select name into dn from decor_items where id = e.decor_id;
  end if;
  if e.card_id is not null then
    insert into student_cards (student_id, card_id, qty) values (sid, e.card_id, 1)
    on conflict (student_id, card_id) do update set qty = student_cards.qty + 1;
    select name into cn from cards where id = e.card_id;
  end if;
  perform check_achievements(sid);
  return json_build_object('title', e.title, 'exp', e.exp, 'coins', e.coins, 'pulls', e.pulls, 'decor', dn, 'card', cn);
end $$;
revoke execute on function checkin_list(uuid), checkin_claim(uuid, uuid) from public;
grant execute on function checkin_list(uuid), checkin_claim(uuid, uuid) to anon, authenticated;
