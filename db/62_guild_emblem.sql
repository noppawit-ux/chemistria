-- 62: สัญลักษณ์กิลด์ (เลือกได้ 12 แบบ) แสดงข้างชื่อกิลด์ในหน้ากิลด์/อันดับ/หน้าแรก (v1.97)
alter table guilds add column if not exists emblem smallint check (emblem between 1 and 12);

-- ค่าเริ่มต้นของกิลด์ที่ยังไม่เลือก: สุ่มแบบคงที่จากรหัสกิลด์ (1–12)
create or replace function _guild_emb(p_id uuid, p_emblem smallint) returns int
language sql immutable as $$ select coalesce(p_emblem::int, 1 + abs(hashtext(p_id::text)) % 12) $$;
revoke execute on function _guild_emb(uuid, smallint) from public, anon, authenticated;

create or replace function guild_set_emblem(p_token uuid, p_emblem int) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); g guilds%rowtype;
begin
  if today_th() > (_guild_cfg()->>'end')::date then raise exception 'กิจกรรมจบแล้ว'; end if;
  if p_emblem is null or p_emblem < 1 or p_emblem > 12 then raise exception 'สัญลักษณ์ไม่ถูกต้อง'; end if;
  select * into g from guilds where leader_id = sid for update;
  if not found then raise exception 'เฉพาะหัวหน้ากิลด์เท่านั้น'; end if;
  update guilds set emblem = p_emblem where id = g.id;
  return json_build_object('emblem', p_emblem);
end $$;
revoke execute on function guild_set_emblem(uuid, int) from public;
grant execute on function guild_set_emblem(uuid, int) to anon, authenticated;

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

create or replace function guild_board(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cfg jsonb := _guild_cfg(); mygid uuid; rws jsonb;
begin
  select guild_id into mygid from guild_members where student_id = sid;
  if (cfg->>'hidden')::boolean then return json_build_object('cfg', cfg, 'hidden', true, 'rows', '[]'::json); end if;
  select coalesce(jsonb_agg(x order by x.rank), '[]') into rws from (
    select r.rank, r.name, c.name as class_name, r.size, r.avg, (r.guild_id = mygid) as mine, r.room_rank,
           _guild_emb(gl.id, gl.emblem) as emblem, _guild_member_card(r.guild_id, true) as members
      from _guild_ranks() r join classes c on c.id = r.class_id join guilds gl on gl.id = r.guild_id where r.ranked order by r.rank limit 30) x;
  return json_build_object('cfg', cfg, 'hidden', false, 'rows', rws,
    'unranked', (select count(*) from _guild_ranks() where not ranked), 'total', (select count(*) from guilds));
end $$;
revoke execute on function guild_board(uuid) from public;
grant execute on function guild_board(uuid) to anon, authenticated;
