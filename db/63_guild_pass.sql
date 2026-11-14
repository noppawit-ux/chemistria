-- 63: ภารกิจกิลด์ + แถบรางวัลแบบ Battle Pass (v1.98)
-- ภารกิจร่วมกันในกิลด์ (เริ่มชุดแรก: ตอบถูกรวม · ล่ามอนสเตอร์ · มาเรียนครบทีม · ครบทุกคนเล่นเกมในวันเดียว)
-- เป้าหมายปรับตามจำนวนสมาชิก · เพดานต่อคนต่อภารกิจ (cap_pct) กันคนเก่งคนเดียวแบก · ความคืบหน้านับจากข้อมูลจริงที่เซิร์ฟเวอร์บันทึก
-- รางวัลขั้นบาร์: ปลดล็อกเมื่อ MP รวมของกิลด์ถึงเกณฑ์ · กดรับได้เฉพาะคนที่ช่วยอย่างน้อย 1 ภารกิจ
create table if not exists guild_quests (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('correct', 'monster', 'attend', 'allplay')),
  title text not null, emoji text not null default '🎯',
  per_member int not null default 10 check (per_member > 0),   -- เป้าต่อสมาชิก 1 คน (allplay = จำนวนวันของทั้งทีม)
  mp int not null default 100 check (mp >= 0),                 -- MP ที่ได้เมื่อครบเป้า (ได้ตามสัดส่วน)
  cap_pct int not null default 40 check (cap_pct between 10 and 100), -- คนเดียวนับได้ไม่เกินกี่ % ของเป้า
  sort int not null default 0, active boolean not null default true
);
create table if not exists guild_pass_tiers (
  tier int primary key, need_mp int not null check (need_mp >= 0), label text not null, emoji text not null default '🏅',
  coins int not null default 0, pulls int not null default 0, exp int not null default 0
);
create table if not exists guild_pass_claims (
  student_id uuid not null references students(id) on delete cascade, tier int not null, claimed_at timestamptz not null default now(),
  primary key (student_id, tier)
);
do $$ declare t text; begin
  foreach t in array array['guild_quests', 'guild_pass_tiers', 'guild_pass_claims'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists teacher_all on public.%I', t);
    execute format('create policy teacher_all on public.%I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;

insert into guild_quests (kind, title, emoji, per_member, mp, cap_pct, sort)
select * from (values
  ('correct', 'รวมพลังตอบโจทย์', '🧪', 40, 100, 40, 1),
  ('monster', 'ล่ามอนสเตอร์ร่วมกัน', '🐲', 6, 100, 40, 2),
  ('attend', 'มาเรียนครบทีม', '🏫', 4, 100, 60, 3),
  ('allplay', 'ครบทุกคนวันนี้', '🤝', 6, 100, 100, 5)) v(kind, title, emoji, per_member, mp, cap_pct, sort)
where not exists (select 1 from guild_quests);
insert into guild_pass_tiers (tier, need_mp, label, emoji, coins, pulls, exp)
select * from (values
  (1, 40, 'ก้าวแรก', '🥉', 15, 0, 0), (2, 100, 'ร่วมแรง', '🥉', 20, 0, 0), (3, 180, 'ใจเดียวกัน', '🥈', 25, 1, 0),
  (4, 260, 'ทีมแกร่ง', '🥈', 30, 1, 0), (5, 340, 'เกือบสุดทาง', '🥇', 40, 2, 0), (6, 400, 'ครบทุกภารกิจ', '👑', 50, 2, 50)) v(tier, need_mp, label, emoji, coins, pulls, exp)
where not exists (select 1 from guild_pass_tiers);

-- ความคืบหน้าของกิลด์ (คืน jsonb) — ภายในเท่านั้น
create or replace function _gq_calc(p_guild uuid) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare cfg jsonb := _guild_cfg(); st date := (cfg->>'start')::date; en date := least((cfg->>'end')::date, today_th());
        g guilds%rowtype; size int; q guild_quests%rowtype; tgt int; capn int; per jsonb; prog int; qs jsonb := '[]'; tot int := 0; mpq int; ids uuid[];
        r record; days int; sh jsonb; n numeric; mem jsonb := '{}'; helped jsonb := '{}';
begin
  select * into g from guilds where id = p_guild;
  select array_agg(student_id) into ids from guild_members where guild_id = p_guild;
  size := coalesce(cardinality(ids), 0);
  if not found or size = 0 or st > en then
    for q in select * from guild_quests where active order by sort, title loop
      qs := qs || jsonb_build_object('id', q.id, 'kind', q.kind, 'title', q.title, 'emoji', q.emoji, 'target', case when q.kind = 'allplay' then q.per_member else q.per_member * greatest(size, 1) end,
        'progress', 0, 'mp', q.mp, 'mp_got', 0, 'cap', q.cap_pct);
    end loop;
    return jsonb_build_object('quests', qs, 'total_mp', 0, 'share', '{}'::jsonb);
  end if;
  for q in select * from guild_quests where active order by sort, title loop
    per := '{}'::jsonb;
    if q.kind = 'allplay' then
      tgt := q.per_member;
      select count(*) into days from generate_series(st, en, interval '1 day') d
       where not exists (select 1 from unnest(ids) s where not exists (select 1 from game_plays gp where gp.student_id = s and gp.play_date = d::date)
                                                      and not exists (select 1 from battles b where b.student_id = s and b.play_date = d::date));
      prog := least(tgt, days);
      for r in select s from unnest(ids) s loop per := per || jsonb_build_object(r.s::text, case when prog > 0 then prog::numeric / size else 0 end); end loop;
    else
      tgt := q.per_member * size; capn := greatest(1, ceil(tgt * q.cap_pct / 100.0)::int);
      for r in select s from unnest(ids) s loop
        n := case q.kind
          when 'correct' then coalesce((select sum(correct) from game_plays where student_id = r.s and play_date between st and en), 0)
                            + coalesce((select sum(correct) from battles where student_id = r.s and play_date between st and en), 0)
          when 'monster' then (select count(*) from battles where student_id = r.s and status = 'won' and play_date between st and en)
          else (select count(*) from ch_attendance where student_id = r.s and class_id = g.class_id and status in ('present', 'late') and att_date between st and en) end;
        per := per || jsonb_build_object(r.s::text, least(n, capn));
      end loop;
      select least(tgt, coalesce(sum(value::numeric), 0)::int) into prog from jsonb_each_text(per);
    end if;
    mpq := floor(q.mp * prog::numeric / tgt)::int; tot := tot + mpq;
    for r in select key, value::numeric v from jsonb_each_text(per) loop
      mem := jsonb_set(mem, array[r.key], to_jsonb(coalesce((mem->>r.key)::numeric, 0) + case when tgt > 0 then q.mp * r.v / tgt else 0 end));
      if r.v > 0 then helped := jsonb_set(helped, array[r.key], 'true'::jsonb); end if;
    end loop;
    qs := qs || jsonb_build_object('id', q.id, 'kind', q.kind, 'title', q.title, 'emoji', q.emoji, 'target', tgt, 'progress', prog, 'mp', q.mp, 'mp_got', mpq, 'cap', q.cap_pct);
  end loop;
  return jsonb_build_object('quests', qs, 'total_mp', tot, 'share', mem, 'helped', helped);
end $$;
revoke execute on function _gq_calc(uuid) from public, anon, authenticated;

create or replace function _gq_status(p_guild uuid, p_sid uuid) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare c jsonb := _gq_calc(p_guild); tot int := (c->>'total_mp')::int; tiers jsonb; mx int; ok boolean := coalesce((c->'helped'->>p_sid::text)::boolean, false); mem jsonb;
begin
  select coalesce(jsonb_agg(jsonb_build_object('tier', t.tier, 'need_mp', t.need_mp, 'label', t.label, 'emoji', t.emoji, 'coins', t.coins, 'pulls', t.pulls, 'exp', t.exp,
      'reached', tot >= t.need_mp, 'claimed', exists (select 1 from guild_pass_claims x where x.student_id = p_sid and x.tier = t.tier),
      'claimable', tot >= t.need_mp and ok and not exists (select 1 from guild_pass_claims x where x.student_id = p_sid and x.tier = t.tier)) order by t.tier), '[]'::jsonb) into tiers from guild_pass_tiers t;
  select coalesce(sum((q->>'mp')::int), 0) into mx from jsonb_array_elements(c->'quests') q;
  select coalesce(jsonb_agg(jsonb_build_object('name', st.name, 'leader', gl.leader_id = st.id, 'me', st.id = p_sid,
        'mp', round(coalesce((c->'share'->>st.id::text)::numeric, 0))::int) order by coalesce((c->'share'->>st.id::text)::numeric, 0) desc, st.no), '[]'::jsonb) into mem
    from guild_members gm join students st on st.id = gm.student_id join guilds gl on gl.id = gm.guild_id where gm.guild_id = p_guild;
  return jsonb_build_object('quests', c->'quests', 'total_mp', tot, 'max_mp', greatest(mx, coalesce((select max(need_mp) from guild_pass_tiers), 0)), 'tiers', tiers, 'eligible', ok, 'members', mem);
end $$;
revoke execute on function _gq_status(uuid, uuid) from public, anon, authenticated;

create or replace function guild_pass_claim(p_token uuid, p_tier int) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); gid uuid; s jsonb; t jsonb; gt guild_pass_tiers%rowtype;
begin
  if (_guild_cfg()->>'phase') not in ('running', 'ended') then raise exception 'กิจกรรมยังไม่เริ่ม'; end if;
  select guild_id into gid from guild_members where student_id = sid;
  if gid is null then raise exception 'คุณยังไม่มีกิลด์'; end if;
  s := _gq_status(gid, sid);
  select x into t from jsonb_array_elements(s->'tiers') x where (x->>'tier')::int = p_tier;
  if t is null then raise exception 'ไม่พบขั้นรางวัลนี้'; end if;
  if (t->>'claimed')::boolean then raise exception 'รับรางวัลนี้ไปแล้ว'; end if;
  if not (t->>'reached')::boolean then raise exception 'กิลด์ยังไม่ถึงขั้นนี้'; end if;
  if not (s->>'eligible')::boolean then raise exception 'ต้องช่วยภารกิจอย่างน้อย 1 อย่างก่อนถึงจะรับรางวัลได้'; end if;
  select * into gt from guild_pass_tiers where tier = p_tier;
  perform _guild_give(sid, 'guild:pass:' || p_tier, 'ภารกิจกิลด์ · ' || gt.label, gt.coins, gt.pulls, gt.exp);
  insert into guild_pass_claims (student_id, tier) values (sid, p_tier) on conflict do nothing;
  return json_build_object('label', gt.label, 'coins', gt.coins, 'pulls', gt.pulls, 'exp', gt.exp);
end $$;
revoke execute on function guild_pass_claim(uuid, int) from public;
grant execute on function guild_pass_claim(uuid, int) to anon, authenticated;

-- guild_status: เพิ่ม my.pass (ภารกิจ + แถบรางวัล) — โหมดส่องดูได้เพราะอยู่ในฟังก์ชันที่อนุญาตอยู่แล้ว
create or replace function guild_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare r jsonb; sid uuid := _sid(p_token); hid boolean; gid uuid;
begin
  r := _guild_status(p_token)::jsonb;
  if r->'my' is not null and jsonb_typeof(r->'my') = 'object' then
    hid := coalesce((r#>>'{cfg,hidden}')::boolean, false);
    gid := (r#>>'{my,id}')::uuid;
    r := jsonb_set(r, '{my,members}', (
      select coalesce(jsonb_agg(m || jsonb_build_object('me', (select st.id = sid from students st where st.no = (m->>'no')::int
            and st.id in (select student_id from guild_members where guild_id = gid)))), '[]'::jsonb)
        from jsonb_array_elements(_guild_member_card(gid, hid)) m));
    r := jsonb_set(r, '{my,emblem}', to_jsonb((select _guild_emb(id, emblem) from guilds where id = gid)));
    if (r#>>'{cfg,phase}') in ('running', 'ended') then r := jsonb_set(r, '{my,pass}', _gq_status(gid, sid)); end if;
  end if;
  if jsonb_typeof(r->'open') = 'array' then
    r := jsonb_set(r, '{open}', (select coalesce(jsonb_agg(o || jsonb_build_object('emblem',
          coalesce((select _guild_emb(gl.id, gl.emblem) from guilds gl where gl.id = (o->>'id')::uuid), 1))), '[]'::jsonb)
        from jsonb_array_elements(r->'open') o));
  end if;
  return r::json;
end $$;
revoke execute on function guild_status(uuid) from public;
grant execute on function guild_status(uuid) to anon, authenticated;
