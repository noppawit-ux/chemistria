-- 68: ของขวัญเพื่อน + คะแนนความสัมพันธ์ + เลือกความสัมพันธ์ (v2.02) · รันซ้ำได้
--  · ซื้อ-ส่งของขวัญให้เพื่อนห้องเดียวกันด้วยเหรียญ → คะแนนความสัมพันธ์ (RP) ของคู่นั้นเพิ่ม
--  · RP ถึงเกณฑ์ → ปลดล็อกชนิดความสัมพันธ์ (เพื่อน / เพื่อนสนิท / คู่หูติว ฯลฯ) · ฝ่ายหนึ่งเสนอ อีกฝ่ายกดยอมรับ
--  · กันโกง: ของขวัญหักเหรียญจริง · RP ต่อคู่ต่อวันมีเพดาน (gift_pair_cap) · ส่งได้ไม่เกิน gift_daily_limit ชิ้น/วัน · ส่งได้เฉพาะเพื่อนในห้องเดียวกัน
create table if not exists gift_items (
  id uuid primary key default gen_random_uuid(),
  key text unique not null, name text not null, emoji text not null default '🎁',
  rarity text not null default 'N' check (rarity in ('N','R','SR','SSR')),
  price int not null check (price >= 0), points int not null check (points > 0),
  descr text, sort int not null default 0, active boolean not null default true
);
create table if not exists relation_types (
  key text primary key, name text not null, emoji text not null default '🤝',
  need_rp int not null check (need_rp >= 0), sort int not null default 0, active boolean not null default true
);
create table if not exists friendships (
  a uuid not null references students(id) on delete cascade, b uuid not null references students(id) on delete cascade,
  rp int not null default 0, rel text, pend_rel text, pend_by uuid,
  day date, day_rp int not null default 0, updated_at timestamptz not null default now(),
  primary key (a, b), check (a < b)
);
create table if not exists gift_log (
  id uuid primary key default gen_random_uuid(),
  from_id uuid not null references students(id) on delete cascade, to_id uuid not null references students(id) on delete cascade,
  name text not null, emoji text not null, points int not null, msg text,
  at timestamptz not null default now(), seen boolean not null default false
);
create index if not exists gift_log_to on gift_log (to_id, at desc);
create index if not exists gift_log_from on gift_log (from_id, at desc);
do $$ declare t text; begin
  foreach t in array array['gift_items', 'relation_types', 'friendships', 'gift_log'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists teacher_all on public.%I', t);
    execute format('create policy teacher_all on public.%I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;
insert into app_settings (key, value) values ('gift_daily_limit', '5'), ('gift_pair_cap', '40') on conflict (key) do nothing;

insert into gift_items (key, name, emoji, rarity, price, points, descr, sort)
select v.* from (values
  ('candy',  'ลูกอมน้ำใจ',        '🍬', 'N',  15,  3, 'ของขวัญชิ้นเล็กๆ ส่งความรู้สึกดีๆ', 10),
  ('choco',  'ช็อกโกแลตแท่ง',     '🍫', 'N',  30,  7, 'หวานนิดๆ เพิ่มมิตรภาพ', 20),
  ('flower', 'ช่อดอกไม้ทดลอง',    '🌸', 'R',  50, 12, 'ดอกไม้จากห้องแล็บ หอมไม่เป็นพิษ', 30),
  ('bear',   'ตุ๊กตาหมีนักเคมี',   '🧸', 'R',  80, 20, 'กอดแล้วสบายใจ เหมาะกับเพื่อนสนิท', 40),
  ('crystal','ผลึกแห่งมิตรภาพ',   '💎', 'SR', 150, 38, 'ผลึกหายาก เปล่งประกายเมื่อมีเพื่อนแท้', 50)
) v(key, name, emoji, rarity, price, points, descr, sort)
where not exists (select 1 from gift_items g where g.key = v.key);

insert into relation_types (key, name, emoji, need_rp, sort)
select v.* from (values
  ('friend',  'เพื่อน',              '🤝',  30, 10),
  ('bestie',  'เพื่อนสนิท',           '😎',  80, 20),
  ('study',   'คู่หูติวเข้ม',         '📚',  80, 21),
  ('rival',   'คู่แข่งสุดซี้',        '⚔️',  80, 22),
  ('bff',     'เพื่อนซี้',            '🫶', 160, 30),
  ('mischief','คู่หูตัวแสบ',          '😈', 160, 31),
  ('lab',     'คู่หูห้องแล็บ',        '🧪', 160, 32),
  ('forever', 'เพื่อนแท้ตลอดกาล',    '💎', 300, 40),
  ('legend',  'คู่หูในตำนาน',         '👑', 300, 41),
  ('family',  'พี่น้องห้องเคมี',      '🧬', 300, 42)
) v(key, name, emoji, need_rp, sort)
where not exists (select 1 from relation_types r where r.key = v.key);

-- ---------- ตัวช่วย ----------
create or replace function _rel_pair(x uuid, y uuid) returns uuid[]
language sql immutable as $$ select case when x < y then array[x, y] else array[y, x] end $$;

create or replace function _rel_home(p_sid uuid) returns json
language sql stable security definer set search_path = public as $$
  select json_build_object(
    'rels', coalesce((select json_agg(json_build_object('no', o.no, 'name', o.name, 'rp', f.rp, 'rel', f.rel, 'rel_name', t.name, 'rel_emoji', t.emoji) order by f.rp desc)
        from friendships f join students o on o.id = case when f.a = p_sid then f.b else f.a end left join relation_types t on t.key = f.rel
       where (f.a = p_sid or f.b = p_sid) and f.rel is not null), '[]'::json),
    'incoming', coalesce((select json_agg(json_build_object('no', o.no, 'name', o.name, 'rel', f.pend_rel, 'rel_name', t.name, 'rel_emoji', t.emoji))
        from friendships f join students o on o.id = f.pend_by join relation_types t on t.key = f.pend_rel
       where (f.a = p_sid or f.b = p_sid) and f.pend_by is not null and f.pend_by <> p_sid), '[]'::json),
    'new_gifts', (select count(*) from gift_log where to_id = p_sid and not seen))
$$;
revoke execute on function _rel_pair(uuid, uuid), _rel_home(uuid) from public, anon, authenticated;

-- student_extras: เพิ่ม relations (ครอบฟังก์ชันเดิม)
do $$ begin
  if exists (select 1 from pg_proc where proname = 'student_extras' and pronamespace = 'public'::regnamespace)
     and not exists (select 1 from pg_proc where proname = '_student_extras' and pronamespace = 'public'::regnamespace) then
    alter function student_extras(uuid) rename to _student_extras;
  end if;
end $$;
revoke execute on function _student_extras(uuid) from public, anon, authenticated;
create or replace function student_extras(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare r jsonb;
begin
  r := _student_extras(p_token)::jsonb;
  return (r || jsonb_build_object('relations', _rel_home(_sid(p_token))))::json;
end $$;
revoke execute on function student_extras(uuid) from public;
grant execute on function student_extras(uuid) to anon, authenticated;

-- ---------- RPC นักเรียน ----------
create or replace function friend_list(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cid uuid; today date := today_th(); res json; cap int := _setting_int('gift_pair_cap', 40);
begin
  select class_id into cid from students where id = sid;
  res := json_build_object(
    'coins', (select coins from students where id = sid),
    'gifts', coalesce((select json_agg(json_build_object('id', g.id, 'name', g.name, 'emoji', g.emoji, 'rarity', g.rarity, 'price', g.price, 'points', g.points, 'descr', g.descr) order by g.sort, g.price) from gift_items g where g.active), '[]'::json),
    'types', coalesce((select json_agg(json_build_object('key', t.key, 'name', t.name, 'emoji', t.emoji, 'need_rp', t.need_rp) order by t.need_rp, t.sort) from relation_types t where t.active), '[]'::json),
    'sent_today', (select count(*) from gift_log where from_id = sid and (at at time zone 'Asia/Bangkok')::date = today),
    'send_limit', _setting_int('gift_daily_limit', 5), 'pair_cap', cap,
    'mates', coalesce((select json_agg(json_build_object('no', o.no, 'name', o.name, 'rp', coalesce(f.rp, 0), 'rel', f.rel, 'rel_name', t.name, 'rel_emoji', t.emoji,
          'day_left', greatest(0, cap - case when f.day = today then f.day_rp else 0 end),
          'pend', case when f.pend_rel is null then null else json_build_object('rel', f.pend_rel, 'name', pt.name, 'emoji', pt.emoji, 'by_me', f.pend_by = sid) end) order by o.no)
        from students o left join friendships f on f.a = (_rel_pair(sid, o.id))[1] and f.b = (_rel_pair(sid, o.id))[2]
        left join relation_types t on t.key = f.rel left join relation_types pt on pt.key = f.pend_rel
       where o.class_id = cid and o.id <> sid), '[]'::json),
    'inbox', coalesce((select json_agg(x) from (select json_build_object('from', o.name, 'emoji', l.emoji, 'name', l.name, 'msg', l.msg, 'points', l.points, 'at', l.at, 'seen', l.seen) x
        from gift_log l join students o on o.id = l.from_id where l.to_id = sid order by l.at desc limit 12) z), '[]'::json));
  update gift_log set seen = true where to_id = sid and not seen;
  return res;
end $$;

create or replace function gift_send(p_token uuid, p_to_no int, p_gift uuid, p_msg text default null) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); me students%rowtype; o students%rowtype; g gift_items%rowtype; pr uuid[]; f friendships%rowtype; today date := today_th();
        cap int := _setting_int('gift_pair_cap', 40); lim int := _setting_int('gift_daily_limit', 5); sent int; used int; m text;
begin
  select * into me from students where id = sid for update;
  select * into o from students where class_id = me.class_id and no = p_to_no;
  if not found or o.id = sid then raise exception 'เลือกเพื่อนในห้องเดียวกันเท่านั้น'; end if;
  select * into g from gift_items where id = p_gift and active;
  if not found then raise exception 'ไม่พบของขวัญ'; end if;
  select count(*) into sent from gift_log where from_id = sid and (at at time zone 'Asia/Bangkok')::date = today;
  if sent >= lim then raise exception 'วันนี้ส่งของขวัญครบ % ชิ้นแล้ว พรุ่งนี้ส่งใหม่ได้', lim; end if;
  m := nullif(left(btrim(coalesce(p_msg, '')), 60), '');
  pr := _rel_pair(sid, o.id);
  insert into friendships (a, b) values (pr[1], pr[2]) on conflict (a, b) do nothing;
  select * into f from friendships where a = pr[1] and b = pr[2] for update;
  used := case when f.day = today then f.day_rp else 0 end;
  if used + g.points > cap then raise exception 'วันนี้ให้คะแนนมิตรภาพกับเพื่อนคนนี้ได้อีกแค่ % แต้ม (ลองของขวัญชิ้นเล็กลงหรือพรุ่งนี้)', greatest(cap - used, 0); end if;
  if me.coins < g.price then raise exception 'เหรียญไม่พอ (ต้องใช้ % เหรียญ)', g.price; end if;
  perform award(sid, 0, -g.price, 'ส่งของขวัญให้เพื่อน: ' || g.name, null);
  update friendships set rp = rp + g.points, day = today, day_rp = used + g.points, updated_at = now() where a = pr[1] and b = pr[2];
  insert into gift_log (from_id, to_id, name, emoji, points, msg) values (sid, o.id, g.name, g.emoji, g.points, m);
  return json_build_object('to', o.name, 'gift', g.name, 'points', g.points, 'rp', f.rp + g.points);
end $$;

create or replace function rel_propose(p_token uuid, p_to_no int, p_rel text) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); me students%rowtype; o students%rowtype; t relation_types%rowtype; pr uuid[]; f friendships%rowtype;
begin
  select * into me from students where id = sid;
  select * into o from students where class_id = me.class_id and no = p_to_no and id <> sid;
  if not found then raise exception 'เลือกเพื่อนในห้องเดียวกันเท่านั้น'; end if;
  select * into t from relation_types where key = p_rel and active;
  if not found then raise exception 'ไม่พบชนิดความสัมพันธ์'; end if;
  pr := _rel_pair(sid, o.id);
  select * into f from friendships where a = pr[1] and b = pr[2] for update;
  if not found or f.rp < t.need_rp then raise exception 'คะแนนมิตรภาพยังไม่ถึง % แต้ม', t.need_rp; end if;
  if f.rel = t.key then raise exception 'เป็นความสัมพันธ์นี้อยู่แล้ว'; end if;
  update friendships set pend_rel = t.key, pend_by = sid, updated_at = now() where a = pr[1] and b = pr[2];
  return json_build_object('to', o.name, 'rel', t.name);
end $$;

create or replace function rel_respond(p_token uuid, p_from_no int, p_accept boolean) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); me students%rowtype; o students%rowtype; pr uuid[]; f friendships%rowtype;
begin
  select * into me from students where id = sid;
  select * into o from students where class_id = me.class_id and no = p_from_no and id <> sid;
  if not found then raise exception 'ไม่พบเพื่อน'; end if;
  pr := _rel_pair(sid, o.id);
  select * into f from friendships where a = pr[1] and b = pr[2] for update;
  if not found or f.pend_rel is null or f.pend_by is distinct from o.id then raise exception 'ไม่มีคำขอจากเพื่อนคนนี้'; end if;
  if p_accept then update friendships set rel = pend_rel, pend_rel = null, pend_by = null, updated_at = now() where a = pr[1] and b = pr[2];
  else update friendships set pend_rel = null, pend_by = null, updated_at = now() where a = pr[1] and b = pr[2]; end if;
  return json_build_object('from', o.name, 'accepted', p_accept);
end $$;

-- ยกเลิกคำขอของตัวเอง หรือเลิกความสัมพันธ์ (คะแนนยังอยู่)
create or replace function rel_end(p_token uuid, p_no int) returns void
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); me students%rowtype; o students%rowtype; pr uuid[];
begin
  select * into me from students where id = sid;
  select * into o from students where class_id = me.class_id and no = p_no and id <> sid;
  if not found then raise exception 'ไม่พบเพื่อน'; end if;
  pr := _rel_pair(sid, o.id);
  update friendships set rel = case when pend_by = sid then rel else null end, pend_rel = null, pend_by = null, updated_at = now() where a = pr[1] and b = pr[2];
end $$;

create or replace function admin_gift_log(p_limit int default 60) returns json
language plpgsql security definer set search_path = public as $$
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  return coalesce((select json_agg(x) from (select json_build_object('at', l.at, 'class', c.name, 'from', f.name, 'to', t.name, 'gift', l.emoji || ' ' || l.name, 'points', l.points, 'msg', l.msg) x
      from gift_log l join students f on f.id = l.from_id join students t on t.id = l.to_id left join classes c on c.id = f.class_id order by l.at desc limit least(greatest(p_limit, 1), 300)) z), '[]'::json);
end $$;

revoke execute on function friend_list(uuid), gift_send(uuid, int, uuid, text), rel_propose(uuid, int, text), rel_respond(uuid, int, boolean), rel_end(uuid, int) from public;
grant execute on function friend_list(uuid), gift_send(uuid, int, uuid, text), rel_propose(uuid, int, text), rel_respond(uuid, int, boolean), rel_end(uuid, int) to anon, authenticated;
revoke execute on function admin_gift_log(int) from public, anon;
grant execute on function admin_gift_log(int) to authenticated;
