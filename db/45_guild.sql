-- 45: Mini Guild — กิจกรรมกิลด์ 15–30 พ.ย. (ห้องเดียวกัน · จัดอันดับรวมทุกห้อง · ซ่อนอันดับวันสุดท้าย · ครูสุ่มจัดคนที่ยังไม่มีกิลด์)
-- แต้มกิลด์ (GP) = EXP จริงจากเกม/เควส/เช็คชื่อ/ส่งงานในช่วงกิจกรรม (จาก ledger) จำกัดต่อคนต่อวัน · อันดับ = GP เฉลี่ยต่อคน
insert into app_settings(key, value) values
  ('guild_start','2026-11-15'), ('guild_end','2026-11-30'), ('guild_reg_from','2026-11-12'), ('guild_join_until','2026-11-17'),
  ('guild_hide_days','1'), ('guild_min_members','3'), ('guild_max_members','5'), ('guild_gp_cap_day','60'), ('guild_min_personal_gp','40'),
  ('guild_room_bonus_coins','30'),
  ('guild_banned','ควย,เหี้ย,สัส,เย็ด,ไอ้สัตว์,fuck,shit,porn,sex')
on conflict (key) do nothing;

create table if not exists guilds (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references classes(id) on delete cascade,
  name text not null,
  leader_id uuid references students(id) on delete set null,
  renamed boolean not null default false,
  auto boolean not null default false,
  created_at timestamptz not null default now()
);
create unique index if not exists guilds_name_uq on guilds (lower(name));
create table if not exists guild_members (
  student_id uuid primary key references students(id) on delete cascade,
  guild_id uuid not null references guilds(id) on delete cascade,
  joined_at timestamptz not null default now()
);
create index if not exists guild_members_g on guild_members(guild_id);
create table if not exists guild_tiers (
  tier int primary key, label text not null, emoji text not null default '🏅',
  min_avg int not null, coins int not null default 0, pulls int not null default 0, exp int not null default 0
);
create table if not exists guild_prizes (
  rank int primary key, label text not null, coins int not null default 0, pulls int not null default 0, exp int not null default 0
);
insert into guild_tiers(tier,label,emoji,min_avg,coins,pulls,exp) values
  (1,'บรอนซ์','🥉',150,20,0,0), (2,'ซิลเวอร์','🥈',300,30,1,0), (3,'โกลด์','🥇',500,40,2,0), (4,'เลเจนด์','👑',700,60,3,50)
on conflict (tier) do nothing;
insert into guild_prizes(rank,label,coins,pulls,exp) values
  (1,'กิลด์แชมป์เปี้ยน 🏆',100,3,0), (2,'รองแชมป์ 🥈',60,2,0), (3,'อันดับ 3 🥉',40,1,0)
on conflict (rank) do nothing;
-- แท็บแอดมินแก้ตารางผ่านคอลัมน์ id
alter table guild_tiers add column if not exists id uuid not null default gen_random_uuid();
alter table guild_prizes add column if not exists id uuid not null default gen_random_uuid();
create unique index if not exists guild_tiers_id on guild_tiers(id);
create unique index if not exists guild_prizes_id on guild_prizes(id);
do $$ declare t text; begin
  foreach t in array array['guilds','guild_members','guild_tiers','guild_prizes'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists teacher_all on public.%I', t);
    execute format('create policy teacher_all on public.%I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;

-- ---------- ตัวช่วยภายใน ----------
create or replace function _gd(p_key text, p_def text) returns text language sql stable security definer set search_path = public as $$
  select coalesce(nullif((select value from app_settings where key = p_key), ''), p_def) $$;
create or replace function _gp_ok(p_reason text) returns boolean language sql immutable as $$
  -- นับเฉพาะ EXP จากการลงแรงจริง (เกม เควส เช็คชื่อ ส่งงาน บอส) — ไม่นับกาชา/ของดรอป/เหรียญรางวัล/โปรโมชัน/ครูปรับ และเหตุผลที่ไม่รู้จัก (เช่น ครูปรับด้วยข้อความเอง)
  select p_reason is not null and p_reason not like 'Mini Guild%'
     and _ledger_src(p_reason) not in ('อื่นๆ', '🎰 กาชา/ของดรอป', '🏅 เหรียญรางวัล', '🎁 โปรโมชันเปิดระบบ', '👩‍🏫 ครูปรับ') $$;
create or replace function _guild_cfg() returns jsonb language plpgsql stable security definer set search_path = public as $$
declare t date := today_th(); st date := _gd('guild_start','2026-11-15')::date; en date := _gd('guild_end','2026-11-30')::date;
        rf date := _gd('guild_reg_from','2026-11-12')::date; ju date := _gd('guild_join_until','2026-11-17')::date; hd int := _gd('guild_hide_days','1')::int;
begin
  return jsonb_build_object('today', t, 'start', st, 'end', en, 'reg_from', rf, 'join_until', ju, 'hide_days', hd,
    'min_members', _gd('guild_min_members','3')::int, 'max_members', _gd('guild_max_members','5')::int,
    'cap_day', _gd('guild_gp_cap_day','60')::int, 'min_personal', _gd('guild_min_personal_gp','40')::int,
    'phase', case when t < rf then 'soon' when t < st then 'reg' when t <= en then 'running' else 'ended' end,
    'can_edit', (t >= rf and t <= ju and t <= en),
    'hidden', (t <= en and t >= en - (greatest(hd,0) - 1) and hd > 0),
    'days_left', greatest(0, en - t + 1));
end $$;

-- GP รายคนของสมาชิกกิลด์ทุกคน
create or replace function _guild_member_gp() returns table(guild_id uuid, student_id uuid, gp numeric)
language sql stable security definer set search_path = public as $$
  with c as (select _guild_cfg() j),
  w as (select ((j->>'start')::date)::timestamp at time zone 'Asia/Bangkok' st, (((j->>'end')::date + 1)::timestamp at time zone 'Asia/Bangkok') en, (j->>'cap_day')::int cap from c),
  d as (select l.student_id, (l.created_at at time zone 'Asia/Bangkok')::date dt, sum(l.exp) e
          from ledger l, w where l.exp > 0 and l.created_at >= w.st and l.created_at < w.en and _gp_ok(l.reason)
           and l.student_id in (select student_id from guild_members) group by 1, 2)
  select gm.guild_id, gm.student_id, coalesce(sum(least((select cap from w), coalesce(d.e, 0))), 0)::numeric
    from guild_members gm left join d on d.student_id = gm.student_id group by gm.guild_id, gm.student_id $$;

create or replace function _guild_ranks() returns table(guild_id uuid, class_id uuid, name text, size int, total numeric, avg numeric, ranked boolean, rank int, room_rank int)
language sql stable security definer set search_path = public as $$
  with mn as (select (_guild_cfg()->>'min_members')::int m),
  s as (select g.id, g.class_id, g.name, count(mg.student_id)::int size, coalesce(sum(mg.gp),0) total,
               round(coalesce(sum(mg.gp),0) / nullif(count(mg.student_id),0), 1) avg
          from guilds g left join _guild_member_gp() mg on mg.guild_id = g.id group by g.id),
  r as (select s.*, (s.size >= (select m from mn)) ranked from s)
  select r.id, r.class_id, r.name, r.size, r.total, coalesce(r.avg,0), r.ranked,
         case when r.ranked then (rank() over (partition by r.ranked order by coalesce(r.avg,0) desc, r.total desc))::int end,
         case when r.ranked then (rank() over (partition by r.class_id, r.ranked order by coalesce(r.avg,0) desc, r.total desc))::int end
    from r $$;

create or replace function _guild_name_ok(p_name text) returns text language plpgsql stable security definer set search_path = public as $$
declare n text := btrim(coalesce(p_name,'')); w text;
begin
  if char_length(n) < 2 or char_length(n) > 16 then raise exception 'ชื่อกิลด์ต้องยาว 2–16 ตัวอักษร'; end if;
  if n ~ '[[:cntrl:]]' then raise exception 'ชื่อกิลด์มีอักขระที่ใช้ไม่ได้'; end if;
  for w in select btrim(x) from unnest(string_to_array(_gd('guild_banned',''), ',')) x where btrim(x) <> '' loop
    if lower(n) like '%' || lower(w) || '%' then raise exception 'ชื่อกิลด์ไม่เหมาะสม กรุณาตั้งชื่อใหม่'; end if;
  end loop;
  if exists (select 1 from guilds where lower(name) = lower(n)) then raise exception 'ชื่อกิลด์นี้มีคนใช้แล้ว'; end if;
  return n;
end $$;

-- ---------- ฝั่งนักเรียน ----------
create or replace function guild_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cfg jsonb := _guild_cfg(); s students%rowtype; gid uuid; me jsonb := null; hid boolean := (cfg->>'hidden')::boolean;
        rk record; v_avg numeric := 0; tiers jsonb; v_open jsonb := '[]'; pr jsonb := null; mygp numeric := 0; t date := (cfg->>'today')::date;
        en date := (cfg->>'end')::date; ph text := cfg->>'phase';
begin
  select * into s from students where id = sid;
  select guild_id into gid from guild_members where student_id = sid;
  select * into rk from _guild_ranks() where guild_id = gid;
  if gid is not null then
    v_avg := coalesce(rk.avg, 0);
    select coalesce(gp,0) into mygp from _guild_member_gp() where student_id = sid;
    me := jsonb_build_object('id', gid, 'name', rk.name, 'size', rk.size, 'ranked', rk.ranked,
      'leader', exists (select 1 from guilds where id = gid and leader_id = sid),
      'can_rename', exists (select 1 from guilds where id = gid and leader_id = sid and not renamed) and t <= en,
      'auto', (select auto from guilds where id = gid),
      'personal_gp', case when hid then null else mygp end,
      'avg', case when hid then null else v_avg end, 'total', case when hid then null else rk.total end,
      'rank', case when hid then null else rk.rank end, 'room_rank', case when hid then null else rk.room_rank end,
      'members', (select coalesce(jsonb_agg(jsonb_build_object('no', st.no, 'name', st.name, 'avatar', st.avatar, 'me', st.id = sid,
            'leader', gl.leader_id = st.id, 'gp', case when hid then null else mg.gp end) order by (gl.leader_id = st.id) desc, st.no), '[]')
          from guild_members gm join students st on st.id = gm.student_id join guilds gl on gl.id = gm.guild_id
          left join _guild_member_gp() mg on mg.student_id = st.id where gm.guild_id = gid));
  elsif (cfg->>'can_edit')::boolean then
    select coalesce(jsonb_agg(jsonb_build_object('id', g.id, 'name', g.name, 'size', x.n) order by g.name), '[]') into v_open
      from guilds g join (select guild_id, count(*)::int n from guild_members group by guild_id) x on x.guild_id = g.id
     where g.class_id = s.class_id and x.n < (cfg->>'max_members')::int;
  end if;
  select coalesce(jsonb_agg(jsonb_build_object('tier', gt.tier, 'label', gt.label, 'emoji', gt.emoji, 'min_avg', gt.min_avg, 'coins', gt.coins, 'pulls', gt.pulls, 'exp', gt.exp,
      'reached', gid is not null and v_avg >= gt.min_avg,
      'claimed', exists (select 1 from ledger l where l.student_id = sid and l.ref_key = 'guild:tier:' || gt.tier),
      'claimable', gid is not null and v_avg >= gt.min_avg and mygp >= (cfg->>'min_personal')::int and ph in ('running','ended') and t <= en + 3
                   and not exists (select 1 from ledger l where l.student_id = sid and l.ref_key = 'guild:tier:' || gt.tier)) order by gt.tier), '[]') into tiers from guild_tiers gt;
  if ph = 'ended' and gid is not null and rk.rank is not null then
    pr := jsonb_build_object('rank', rk.rank, 'room_rank', rk.room_rank,
      'prize', (select to_jsonb(p) from guild_prizes p where p.rank = rk.rank),
      'room_bonus', case when rk.room_rank = 1 then (_gd('guild_room_bonus_coins','30'))::int else null end,
      'eligible', mygp >= (cfg->>'min_personal')::int and t <= en + 14,
      'claimed_rank', exists (select 1 from ledger l where l.student_id = sid and l.ref_key = 'guild:prize:rank'),
      'claimed_room', exists (select 1 from ledger l where l.student_id = sid and l.ref_key = 'guild:prize:room'));
  end if;
  return json_build_object('cfg', cfg, 'my', me, 'open', v_open, 'tiers', tiers, 'prize', pr, 'class_name', (select name from classes where id = s.class_id));
end $$;

create or replace function guild_board(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cfg jsonb := _guild_cfg(); mygid uuid; rws jsonb;
begin
  select guild_id into mygid from guild_members where student_id = sid;
  if (cfg->>'hidden')::boolean then return json_build_object('cfg', cfg, 'hidden', true, 'rows', '[]'::json); end if;
  select coalesce(jsonb_agg(x order by x.rank), '[]') into rws from (
    select r.rank, r.name, c.name as class_name, r.size, r.avg, (r.guild_id = mygid) as mine, r.room_rank
      from _guild_ranks() r join classes c on c.id = r.class_id where r.ranked order by r.rank limit 30) x;
  return json_build_object('cfg', cfg, 'hidden', false, 'rows', rws,
    'unranked', (select count(*) from _guild_ranks() where not ranked), 'total', (select count(*) from guilds));
end $$;

create or replace function guild_create(p_token uuid, p_name text) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); s students%rowtype; n text; gid uuid;
begin
  if not (_guild_cfg()->>'can_edit')::boolean then raise exception 'ช่วงรับสมัครกิลด์ยังไม่เปิดหรือปิดแล้ว'; end if;
  select * into s from students where id = sid for update;
  if exists (select 1 from guild_members where student_id = sid) then raise exception 'คุณมีกิลด์อยู่แล้ว'; end if;
  n := _guild_name_ok(p_name);
  insert into guilds(class_id, name, leader_id) values (s.class_id, n, sid) returning id into gid;
  insert into guild_members(student_id, guild_id) values (sid, gid);
  return json_build_object('id', gid, 'name', n);
end $$;

create or replace function guild_join(p_token uuid, p_guild uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); s students%rowtype; g guilds%rowtype; n int;
begin
  if not (_guild_cfg()->>'can_edit')::boolean then raise exception 'ช่วงรับสมัครกิลด์ยังไม่เปิดหรือปิดแล้ว'; end if;
  select * into s from students where id = sid for update;
  if exists (select 1 from guild_members where student_id = sid) then raise exception 'คุณมีกิลด์อยู่แล้ว'; end if;
  select * into g from guilds where id = p_guild for update;
  if not found or g.class_id <> s.class_id then raise exception 'ไม่พบกิลด์นี้ในห้องของคุณ'; end if;
  select count(*) into n from guild_members where guild_id = g.id;
  if n >= (_guild_cfg()->>'max_members')::int then raise exception 'กิลด์นี้เต็มแล้ว'; end if;
  insert into guild_members(student_id, guild_id) values (sid, g.id);
  return json_build_object('id', g.id, 'name', g.name);
end $$;

create or replace function guild_leave(p_token uuid) returns void
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); g guilds%rowtype; nxt uuid;
begin
  if not (_guild_cfg()->>'can_edit')::boolean then raise exception 'ช่วงเปลี่ยนกิลด์ปิดแล้ว (ล็อกสมาชิก) ถ้าจำเป็นให้แจ้งครู'; end if;
  select g2.* into g from guilds g2 join guild_members m on m.guild_id = g2.id where m.student_id = sid for update of g2;
  if not found then raise exception 'คุณยังไม่มีกิลด์'; end if;
  delete from guild_members where student_id = sid;
  select student_id into nxt from guild_members where guild_id = g.id order by joined_at limit 1;
  if nxt is null then delete from guilds where id = g.id;
  elsif g.leader_id = sid then update guilds set leader_id = nxt where id = g.id; end if;
end $$;

create or replace function guild_rename(p_token uuid, p_name text) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); g guilds%rowtype; n text;
begin
  if today_th() > (_guild_cfg()->>'end')::date then raise exception 'กิจกรรมจบแล้ว'; end if;
  select * into g from guilds where leader_id = sid for update;
  if not found then raise exception 'เฉพาะหัวหน้ากิลด์เท่านั้น'; end if;
  if g.renamed then raise exception 'เปลี่ยนชื่อได้เพียง 1 ครั้ง (ถ้าจำเป็นให้แจ้งครู)'; end if;
  n := _guild_name_ok(p_name);
  update guilds set name = n, renamed = true where id = g.id;
  return json_build_object('name', n);
end $$;

create or replace function _guild_give(p_sid uuid, p_ref text, p_label text, p_coins int, p_pulls int, p_exp int) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not award(p_sid, p_exp, p_coins, 'Mini Guild: ' || p_label, p_ref) then raise exception 'รับรางวัลนี้ไปแล้ว'; end if;
  if p_pulls > 0 then update students set free_pulls = coalesce(free_pulls, 0) + p_pulls where id = p_sid; end if;
end $$;

create or replace function guild_claim_tier(p_token uuid, p_tier int) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); st json := guild_status(p_token); tr json; gt guild_tiers%rowtype;
begin
  select x into tr from json_array_elements(st->'tiers') x where (x->>'tier')::int = p_tier;
  if tr is null then raise exception 'ไม่พบขั้นรางวัลนี้'; end if;
  if (tr->>'claimed')::boolean then raise exception 'รับรางวัลนี้ไปแล้ว'; end if;
  if not (tr->>'claimable')::boolean then raise exception 'ยังรับไม่ได้ (กิลด์ยังไม่ถึงขั้นนี้ หรือแต้มส่วนตัวของคุณยังไม่ถึงเกณฑ์)'; end if;
  select * into gt from guild_tiers where tier = p_tier;
  perform _guild_give(sid, 'guild:tier:' || p_tier, gt.label, gt.coins, gt.pulls, gt.exp);
  return json_build_object('label', gt.label, 'coins', gt.coins, 'pulls', gt.pulls, 'exp', gt.exp);
end $$;

create or replace function guild_claim_prize(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); st json := guild_status(p_token); pz json := st->'prize'; p guild_prizes%rowtype; got json := '{}'; bc int; any_ boolean := false;
begin
  if pz is null then raise exception 'ยังไม่มีรางวัลอันดับ (กิจกรรมยังไม่จบ หรือกิลด์ไม่ติดอันดับ)'; end if;
  if not (pz->>'eligible')::boolean then raise exception 'แต้มส่วนตัวยังไม่ถึงเกณฑ์ หรือหมดเวลารับรางวัลแล้ว'; end if;
  select * into p from guild_prizes where rank = (pz->>'rank')::int;
  if found and not (pz->>'claimed_rank')::boolean then
    perform _guild_give(sid, 'guild:prize:rank', p.label, p.coins, p.pulls, p.exp); any_ := true;
    got := json_build_object('rank', p.label, 'coins', p.coins, 'pulls', p.pulls, 'exp', p.exp);
  end if;
  bc := nullif(pz->>'room_bonus','')::int;
  if bc is not null and not (pz->>'claimed_room')::boolean then
    perform _guild_give(sid, 'guild:prize:room', 'กิลด์อันดับ 1 ของห้อง', bc, 0, 0); any_ := true;
    got := (got::jsonb || jsonb_build_object('room_coins', bc))::json;
  end if;
  if not any_ then raise exception 'ไม่มีรางวัลอันดับที่ต้องรับ หรือรับไปแล้ว'; end if;
  return got;
end $$;

-- ---------- ฝั่งครู ----------
create or replace function admin_guild_list() returns json
language plpgsql stable security definer set search_path = public as $$
begin
  if not is_teacher() then raise exception 'เฉพาะครูเท่านั้น'; end if;
  return json_build_object('cfg', _guild_cfg(),
    'unassigned', (select coalesce(json_agg(json_build_object('class_id', c.id, 'class', c.name, 'n', x.n) order by c.name), '[]') from classes c
                    join (select s.class_id, count(*)::int n from students s where not coalesce(s.is_gm,false) and not exists (select 1 from guild_members m where m.student_id = s.id) group by s.class_id) x on x.class_id = c.id
                   where c.code <> 'GM'),
    'guilds', (select coalesce(json_agg(json_build_object('id', r.guild_id, 'name', r.name, 'class', c.name, 'class_id', r.class_id, 'size', r.size, 'total', r.total, 'avg', r.avg, 'rank', r.rank, 'room_rank', r.room_rank,
        'auto', g.auto, 'renamed', g.renamed,
        'members', (select coalesce(json_agg(json_build_object('id', st.id, 'no', st.no, 'name', st.name, 'gp', mg.gp, 'leader', g.leader_id = st.id) order by st.no), '[]')
                     from guild_members gm join students st on st.id = gm.student_id left join _guild_member_gp() mg on mg.student_id = st.id where gm.guild_id = r.guild_id))
        order by r.rank nulls last, c.name, r.name), '[]')
      from _guild_ranks() r join guilds g on g.id = r.guild_id join classes c on c.id = r.class_id));
end $$;

create or replace function admin_guild_random(p_class uuid default null) returns json
language plpgsql security definer set search_path = public as $$
declare c record; ids uuid[]; n int; i int; g record; rem int; groups int; base int; extra int; k int; sz int; gid uuid; nm text; seq int; mx int := (_guild_cfg()->>'max_members')::int;
        assigned int := 0; created int := 0; sid uuid; idx int;
begin
  if not is_teacher() then raise exception 'เฉพาะครูเท่านั้น'; end if;
  for c in select cl.id, cl.code from classes cl where (p_class is null or cl.id = p_class) and cl.code <> 'GM' loop
    select coalesce(array_agg(s.id order by random()), '{}') into ids from students s
     where s.class_id = c.id and not coalesce(s.is_gm, false) and not exists (select 1 from guild_members m where m.student_id = s.id);
    n := coalesce(cardinality(ids), 0); i := 1;
    if n = 0 then continue; end if;
    -- 1) เติมกิลด์ที่ยังไม่ถึง 4 คนให้ครบ 4 ก่อน
    for g in select gl.id, count(m.student_id)::int sz from guilds gl left join guild_members m on m.guild_id = gl.id where gl.class_id = c.id group by gl.id having count(m.student_id) < 4 order by count(m.student_id) loop
      sz := g.sz;
      while sz < 4 and i <= n loop insert into guild_members(student_id, guild_id) values (ids[i], g.id); i := i + 1; sz := sz + 1; assigned := assigned + 1; end loop;
    end loop;
    rem := n - i + 1;
    if rem > 0 and rem < 3 then
      -- 2) เหลือน้อยกว่า 3 คน: ใส่กิลด์ที่เล็กที่สุดของห้อง (ถ้ายังไม่มีกิลด์เลย สร้างกิลด์เล็ก)
      while i <= n loop
        select gl.id into gid from guilds gl left join guild_members m on m.guild_id = gl.id where gl.class_id = c.id group by gl.id order by count(m.student_id) limit 1;
        if gid is null then
          seq := 1; loop nm := 'กิลด์ ' || c.code || '-' || seq; exit when not exists (select 1 from guilds where lower(name) = lower(nm)); seq := seq + 1; end loop;
          insert into guilds(class_id, name, leader_id, auto) values (c.id, nm, ids[i], true) returning id into gid; created := created + 1;
        end if;
        insert into guild_members(student_id, guild_id) values (ids[i], gid); i := i + 1; assigned := assigned + 1;
      end loop;
    elsif rem >= 3 then
      -- 3) แบ่งกลุ่มใหม่ขนาด 4–5 คนให้เท่าๆ กัน
      groups := ceil(rem / 5.0)::int; base := rem / groups; extra := rem % groups;
      for k in 1..groups loop
        sz := base + case when k <= extra then 1 else 0 end;
        seq := 1; loop nm := 'กิลด์ ' || c.code || '-' || seq; exit when not exists (select 1 from guilds where lower(name) = lower(nm)); seq := seq + 1; end loop;
        insert into guilds(class_id, name, leader_id, auto) values (c.id, nm, ids[i], true) returning id into gid; created := created + 1;
        for idx in 1..sz loop insert into guild_members(student_id, guild_id) values (ids[i], gid); i := i + 1; assigned := assigned + 1; end loop;
      end loop;
    end if;
  end loop;
  insert into security_events(kind, sev, detail, seen) values ('guild_random', 'info', 'ครูสุ่มจัดนักเรียนเข้ากิลด์ ' || assigned || ' คน (สร้างกิลด์ใหม่ ' || created || ')', true);
  return json_build_object('assigned', assigned, 'created', created);
end $$;

create or replace function admin_guild_rename(p_guild uuid, p_name text) returns void
language plpgsql security definer set search_path = public as $$
declare n text;
begin
  if not is_teacher() then raise exception 'เฉพาะครูเท่านั้น'; end if;
  n := _guild_name_ok(p_name);
  update guilds set name = n where id = p_guild;
end $$;
create or replace function admin_guild_disband(p_guild uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not is_teacher() then raise exception 'เฉพาะครูเท่านั้น'; end if;
  delete from guilds where id = p_guild;
end $$;
create or replace function admin_guild_move(p_student uuid, p_guild uuid default null) returns void
language plpgsql security definer set search_path = public as $$
declare g guilds%rowtype; old uuid; nxt uuid; oldl uuid;
begin
  if not is_teacher() then raise exception 'เฉพาะครูเท่านั้น'; end if;
  select guild_id into old from guild_members where student_id = p_student;
  if p_guild is not null then
    select * into g from guilds where id = p_guild;
    if not found or g.class_id <> (select class_id from students where id = p_student) then raise exception 'กิลด์ต้องอยู่ห้องเดียวกับนักเรียน'; end if;
  end if;
  delete from guild_members where student_id = p_student;
  if p_guild is not null then insert into guild_members(student_id, guild_id) values (p_student, p_guild); end if;
  if old is not null then
    select leader_id into oldl from guilds where id = old;
    select student_id into nxt from guild_members where guild_id = old order by joined_at limit 1;
    if nxt is null then delete from guilds where id = old; elsif oldl = p_student or oldl is null then update guilds set leader_id = nxt where id = old; end if;
  end if;
end $$;

-- ---------- ชื่อกิลด์แสดงบนชื่อนักเรียน: ห่อฟังก์ชันเดิม (เปลี่ยนชื่อเดิมเป็น _xxx) ----------
do $$ begin
  if not exists (select 1 from pg_proc where proname = '_student_dashboard' and pronamespace = 'public'::regnamespace) then
    alter function student_dashboard(uuid) rename to _student_dashboard; end if;
  if not exists (select 1 from pg_proc where proname = '_hall_of_fame' and pronamespace = 'public'::regnamespace) then
    alter function hall_of_fame(uuid) rename to _hall_of_fame; end if;
end $$;

create or replace function student_dashboard(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); r jsonb; tag text;
begin
  r := _student_dashboard(p_token)::jsonb;
  select g.name into tag from guild_members gm join guilds g on g.id = gm.guild_id where gm.student_id = sid;
  if jsonb_typeof(r->'leaderboard') = 'array' then
    r := jsonb_set(r, '{leaderboard}', coalesce((select jsonb_agg(t || jsonb_build_object('guild',
          (select g.name from students s2 join guild_members gm on gm.student_id = s2.id join guilds g on g.id = gm.guild_id
            where s2.class_id = (select class_id from students where id = sid) and s2.name = t->>'name' limit 1))) from jsonb_array_elements(r->'leaderboard') t), '[]'::jsonb));
  end if;
  return jsonb_set(r, '{student,guild}', coalesce(to_jsonb(tag), 'null'::jsonb))::json;
end $$;

create or replace function hall_of_fame(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); r jsonb; o jsonb;
begin
  r := _hall_of_fame(p_token)::jsonb;
  select coalesce(jsonb_agg(
    case when jsonb_typeof(h->'top') = 'array' then
      jsonb_set(h, '{top}', coalesce((select jsonb_agg(t || jsonb_build_object('guild',
          (select g.name from students s join guild_members gm on gm.student_id = s.id join guilds g on g.id = gm.guild_id
            where s.class_id = (h->>'id')::uuid and s.no = (t->>'no')::int))) from jsonb_array_elements(h->'top') t), '[]'::jsonb))
    else h end), '[]'::jsonb) into o from jsonb_array_elements(r) h;
  return o::json;
end $$;

-- โหมดส่องดูกิลด์ได้ (อ่านอย่างเดียว) — ต่อจากรายการเดิมใน 43
create or replace function _sid(p_token uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare v uuid; o boolean; fn text; n int; lim int := _setting_int('sec_rpc_per_min', 240);
begin
  update student_sessions
     set win_n = case when win_start is null or win_start < now() - interval '1 minute' then 1 else win_n + 1 end,
         win_start = case when win_start is null or win_start < now() - interval '1 minute' then now() else win_start end
   where token = p_token and expires_at > now()
  returning student_id, observer, win_n into v, o, n;
  if v is null then raise exception 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่'; end if;
  if n > lim then raise exception 'ส่งคำสั่งถี่เกินไป กรุณารอสักครู่'; end if;
  if n = lim then
    perform _sec_log('rate_abuse', 'high', v, 'ส่งคำสั่งถึง ' || lim || ' ครั้งใน 1 นาที (อาจเป็นสคริปต์/บอท)', 'rate:' || v || ':' || to_char(now(), 'YYYYMMDDHH24MI'));
  end if;
  if o then
    fn := regexp_replace(coalesce(current_setting('request.path', true), ''), '^.*/', '');
    if fn not in ('student_dashboard','student_extras','hall_of_fame','board_list','celebrations_feed','game_status','spell_status','kb_status','news_list','run_status','timetable_list','promo_status','guild_status','guild_board') then
      raise exception 'โหมดส่องนักเรียน: ดูได้อย่างเดียว';
    end if;
  end if;
  return v;
end $$;

-- ---------- สิทธิ์ ----------
do $$ declare f text; begin
  foreach f in array array['_gd(text,text)','_gp_ok(text)','_guild_cfg()','_guild_member_gp()','_guild_ranks()','_guild_name_ok(text)','_guild_give(uuid,text,text,int,int,int)','_student_dashboard(uuid)','_hall_of_fame(uuid)'] loop
    execute format('revoke execute on function %s from public, anon, authenticated', f);
  end loop;
  foreach f in array array['student_dashboard(uuid)','hall_of_fame(uuid)'] loop
    execute format('revoke execute on function %s from public', f);
    execute format('grant execute on function %s to anon, authenticated', f);
  end loop;
  foreach f in array array['guild_status(uuid)','guild_board(uuid)','guild_create(uuid,text)','guild_join(uuid,uuid)','guild_leave(uuid)','guild_rename(uuid,text)','guild_claim_tier(uuid,int)','guild_claim_prize(uuid)'] loop
    execute format('revoke execute on function %s from public', f);
    execute format('grant execute on function %s to anon, authenticated', f);
  end loop;
  foreach f in array array['admin_guild_list()','admin_guild_random(uuid)','admin_guild_rename(uuid,text)','admin_guild_disband(uuid)','admin_guild_move(uuid,uuid)'] loop
    execute format('revoke execute on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

-- ประกาศบนสไลด์ข่าว: เปลี่ยนจาก "เร็วๆ นี้" เป็นรายละเอียดจริง
update news_posts set
  title = 'Mini Guild · 15–30 พ.ย. 🏰',
  summary = 'รวมกิลด์ 4–5 คนในห้องเดียวกัน เก็บแต้มแข่งอันดับรวมทุกห้อง สมัครได้ตั้งแต่ 12 พ.ย.',
  body = E'🏰 Mini Guild · 15–30 พ.ย.\n\n• สมัคร/ตั้งกิลด์ได้ตั้งแต่ 12–17 พ.ย. (ล็อกสมาชิกหลัง 17 พ.ย.)\n• กิลด์ละ 4–5 คน ต้องเป็นห้องเดียวกัน ตั้งชื่อกิลด์เองได้ ชื่อจะโชว์หน้าชื่อของสมาชิก\n• ใครยังไม่มีกิลด์ ครูจะสุ่มจัดให้\n• แต้มกิลด์มาจาก EXP ที่ได้จากเกม เควส เช็คชื่อ และส่งงาน (จำกัดต่อคนต่อวัน ทุกคนต้องช่วยกัน) จัดอันดับด้วยแต้มเฉลี่ยต่อคน เทียบทุกห้อง\n• แต้มยิ่งสูง ยิ่งปลดล็อกรางวัล 4 ขั้น: 🥉 บรอนซ์ 🥈 ซิลเวอร์ 🥇 โกลด์ 👑 เลเจนด์ และมีรางวัลกิลด์อันดับ 1–3 กับอันดับ 1 ของแต่ละห้อง\n• วันที่ 30 พ.ย. ซ่อนอันดับเพื่อความลุ้น ประกาศผลหลังจบกิจกรรม\n\nไปที่เมนู 🏰 กิลด์ ได้เลย!',
  starts_at = '2026-11-12', ends_at = '2026-11-30'
 where title like 'Mini Guild · เร็วๆ นี้%';
