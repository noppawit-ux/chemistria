-- =====================================================================
-- 87: แคมเปญเช็คอินสะสมวัน — เช็คอินวันละครั้ง ยิ่งครบหลายวันยิ่งได้รางวัลมาก ท้ายสุดแจก "ชุดลิมิเต็ด" (รันซ้ำได้)
--  - นับ "จำนวนวันที่เช็คอิน" (ไม่ต้องติดกัน) · ถึงเป้าแต่ละขั้น = ได้รางวัลขั้นนั้นอัตโนมัติ (ครั้งเดียวต่อขั้น)
--  - รางวัลต่อขั้น: EXP / เหรียญ / ตั๋วกาชา / การ์ด 1 ใบ / ไอเทมตกแต่ง 1 ชิ้น / ชุดไอเทม (set_key)
--  - ชุดลิมิเต็ด "ราชันธาตุ" 3 ชิ้น (หมวก/ดาบ/เอฟเฟกต์) ได้จากแคมเปญเท่านั้น (ไม่ขาย ไม่อยู่ในกาชา)
-- =====================================================================
alter table decor_items add column if not exists set_key text;

insert into decor_items (slot, key, name, emoji, rarity, price, sort, image, element, fx_atk, fx_def, fx_hp, set_key, ability)
select v.slot, 'img', v.name, v.emoji, 'SSR', null, v.sort, v.img, null, v.atk, v.def, v.hp, 'lim_king1', 'ลิมิเต็ด · ชุดราชันธาตุ (ได้จากอีเว้นท์เช็คอินเท่านั้น)'
  from (values
    ('hat',  '[Limited] หมวกราชันธาตุ',    '👑', 95, 'assets/px/lim_hat.png',   0, 4, 3),
    ('item', '[Limited] ดาบราชันธาตุ',     '🗡️', 95, 'assets/px/lim_sword.png', 5, 0, 0),
    ('fx',   '[Limited] ออร่าราชันธาตุ',   '✨', 95, 'assets/px/lim_fx.png',    2, 2, 4)
  ) v(slot, name, emoji, sort, img, atk, def, hp)
where not exists (select 1 from decor_items d where d.slot = v.slot and d.name = v.name);
update decor_items set set_key = 'lim_king1' where name like '[Limited] %ราชันธาตุ' and set_key is null;

create table if not exists checkin_camps (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  message text not null default '',
  start_day date not null default today_th(),
  end_day date not null,
  closed boolean not null default false,
  created_at timestamptz not null default now()
);
create table if not exists checkin_miles (
  id uuid primary key default gen_random_uuid(),
  camp_id uuid not null references checkin_camps(id) on delete cascade,
  need int not null check (need > 0),
  exp int not null default 0 check (exp >= 0),
  coins int not null default 0 check (coins >= 0),
  pulls int not null default 0 check (pulls >= 0),
  decor_id uuid references decor_items(id) on delete set null,
  card_id uuid references cards(id) on delete set null,
  set_key text,
  unique (camp_id, need)
);
create table if not exists checkin_days (
  camp_id uuid not null references checkin_camps(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  day date not null,
  primary key (camp_id, student_id, day)
);
create table if not exists checkin_mclaims (
  mile_id uuid not null references checkin_miles(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  at timestamptz not null default now(),
  primary key (mile_id, student_id)
);
alter table checkin_camps enable row level security; alter table checkin_miles enable row level security;
alter table checkin_days enable row level security; alter table checkin_mclaims enable row level security;
do $$ declare t text; begin
  foreach t in array array['checkin_camps','checkin_miles','checkin_days','checkin_mclaims'] loop
    execute format('drop policy if exists teacher_all on %I', t);
    execute format('create policy teacher_all on %I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on %I from anon', t);
  end loop; end $$;

-- ภายใน: แจกรางวัลของ 1 ขั้น
create or replace function _camp_grant(p_sid uuid, m checkin_miles) returns void
language plpgsql security definer set search_path = public as $$
begin
  if m.exp > 0 or m.coins > 0 then perform award(p_sid, m.exp, m.coins, '🎟️ เช็คอินสะสม ' || m.need || ' วัน', 'checkin:' || m.id); end if;
  if m.pulls > 0 then update students set free_pulls = free_pulls + m.pulls where id = p_sid; end if;
  if m.decor_id is not null then insert into student_decor (student_id, item_id, source) values (p_sid, m.decor_id, 'teacher') on conflict do nothing; end if;
  if m.set_key is not null then
    insert into student_decor (student_id, item_id, source) select p_sid, d.id, 'teacher' from decor_items d where d.set_key = m.set_key on conflict do nothing;
  end if;
  if m.card_id is not null then
    insert into student_cards (student_id, card_id, qty) values (p_sid, m.card_id, 1) on conflict (student_id, card_id) do update set qty = student_cards.qty + 1;
  end if;
end $$;
revoke execute on function _camp_grant(uuid, checkin_miles) from public, anon, authenticated;

-- ครู: เปิดแคมเปญ (เริ่มวันนี้ นาน p_days วัน) พร้อมขั้นรางวัล p_miles = [{need,exp,coins,pulls,decor_id,card_id,set_key}]
create or replace function admin_camp_open(p_title text, p_message text, p_days int, p_miles jsonb) returns uuid
language plpgsql security definer set search_path = public as $$
declare cid uuid; m jsonb; mx int := 0;
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  if btrim(coalesce(p_title, '')) = '' then raise exception 'ใส่ชื่อแคมเปญก่อน'; end if;
  if coalesce(p_days, 0) < 1 or p_days > 120 then raise exception 'จำนวนวันต้องอยู่ระหว่าง 1–120'; end if;
  if jsonb_typeof(p_miles) <> 'array' or jsonb_array_length(p_miles) = 0 then raise exception 'ต้องมีขั้นรางวัลอย่างน้อย 1 ขั้น'; end if;
  insert into checkin_camps (title, message, end_day) values (left(btrim(p_title), 80), left(btrim(coalesce(p_message, '')), 200), today_th() + (p_days - 1)) returning id into cid;
  for m in select * from jsonb_array_elements(p_miles) loop
    if coalesce((m->>'need')::int, 0) < 1 or (m->>'need')::int > p_days then raise exception 'จำนวนวันของแต่ละขั้นต้องอยู่ระหว่าง 1–% วัน', p_days; end if;
    if coalesce((m->>'exp')::int, 0) > 10000 or coalesce((m->>'coins')::int, 0) > 10000 or coalesce((m->>'pulls')::int, 0) > 50 then raise exception 'จำนวนรางวัลมากเกินไป'; end if;
    if coalesce((m->>'exp')::int, 0) + coalesce((m->>'coins')::int, 0) + coalesce((m->>'pulls')::int, 0) = 0 and nullif(m->>'decor_id', '') is null and nullif(m->>'card_id', '') is null and nullif(m->>'set_key', '') is null then
      raise exception 'ขั้น % วัน ยังไม่ได้ใส่รางวัล', m->>'need'; end if;
    insert into checkin_miles (camp_id, need, exp, coins, pulls, decor_id, card_id, set_key)
    values (cid, (m->>'need')::int, coalesce((m->>'exp')::int, 0), coalesce((m->>'coins')::int, 0), coalesce((m->>'pulls')::int, 0),
            nullif(m->>'decor_id', '')::uuid, nullif(m->>'card_id', '')::uuid, nullif(m->>'set_key', ''));
  end loop;
  return cid;
end $$;
revoke execute on function admin_camp_open(text, text, int, jsonb) from public, anon;
grant execute on function admin_camp_open(text, text, int, jsonb) to authenticated;

-- นักเรียน: แคมเปญที่เปิดอยู่ + ความคืบหน้า
create or replace function camp_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); td date := today_th();
begin
  return coalesce((select json_agg(json_build_object(
      'id', c.id, 'title', c.title, 'message', c.message, 'start_day', c.start_day, 'end_day', c.end_day,
      'days_total', c.end_day - c.start_day + 1, 'days_left', c.end_day - td,
      'done', (select count(*) from checkin_days k where k.camp_id = c.id and k.student_id = sid),
      'today', exists (select 1 from checkin_days k where k.camp_id = c.id and k.student_id = sid and k.day = td),
      'miles', (select json_agg(json_build_object('need', m.need, 'exp', m.exp, 'coins', m.coins, 'pulls', m.pulls,
                  'decor', d.name, 'card', cd.name,
                  'set', (select json_agg(json_build_object('name', x.name, 'emoji', x.emoji, 'image', x.image) order by x.sort) from decor_items x where x.set_key = m.set_key),
                  'got', exists (select 1 from checkin_mclaims q where q.mile_id = m.id and q.student_id = sid)) order by m.need)
                from checkin_miles m left join decor_items d on d.id = m.decor_id left join cards cd on cd.id = m.card_id where m.camp_id = c.id)
    ) order by c.end_day)
    from checkin_camps c where not c.closed and td between c.start_day and c.end_day), '[]'::json);
end $$;

-- นักเรียน: เช็คอินวันนี้ (วันละครั้ง) → ได้รางวัลขั้นที่ถึงเป้าอัตโนมัติ
create or replace function camp_checkin(p_token uuid, p_camp uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); td date := today_th(); c checkin_camps%rowtype; n int; m checkin_miles%rowtype; got json[] := '{}'; sk json;
begin
  select * into c from checkin_camps where id = p_camp for share;
  if not found or c.closed or td < c.start_day or td > c.end_day then raise exception 'แคมเปญนี้ปิดแล้ว หรือยังไม่เปิด'; end if;
  insert into checkin_days (camp_id, student_id, day) values (c.id, sid, td) on conflict do nothing;
  if not found then raise exception 'วันนี้เช็คอินแล้ว พรุ่งนี้มาใหม่นะ'; end if;
  select count(*) into n from checkin_days where camp_id = c.id and student_id = sid;
  for m in select * from checkin_miles where camp_id = c.id and need <= n order by need loop
    insert into checkin_mclaims (mile_id, student_id) values (m.id, sid) on conflict do nothing;
    if found then
      perform _camp_grant(sid, m);
      select json_agg(json_build_object('name', x.name, 'emoji', x.emoji)) into sk from decor_items x where x.set_key = m.set_key;
      got := got || json_build_object('need', m.need, 'exp', m.exp, 'coins', m.coins, 'pulls', m.pulls,
               'decor', (select name from decor_items where id = m.decor_id), 'card', (select name from cards where id = m.card_id), 'set', sk);
    end if;
  end loop;
  perform check_achievements(sid);
  return json_build_object('title', c.title, 'done', n, 'rewards', to_json(got));
end $$;
revoke execute on function camp_status(uuid), camp_checkin(uuid, uuid) from public;
grant execute on function camp_status(uuid), camp_checkin(uuid, uuid) to anon, authenticated;
