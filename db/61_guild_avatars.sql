-- 61: Mini Guild แสดงตัวละครสมาชิก (พร้อมพื้นหลัง/ชุด/กรอบ) ในหน้ากิลด์ และในตารางอันดับกิลด์ (v1.92)
do $$ begin
  if not exists (select 1 from pg_proc where proname = '_guild_status' and pronamespace = 'public'::regnamespace) then
    alter function guild_status(uuid) rename to _guild_status; end if;
end $$;
revoke execute on function _guild_status(uuid) from public, anon, authenticated;

create or replace function _guild_member_card(p_guild uuid, p_hid boolean) returns jsonb
language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(jsonb_build_object('no', st.no, 'name', st.name, 'avatar', st.avatar, 'char_class', st.char_class,
      'rank_info', rank_info(st.exp)::jsonb, 'decor', _decor_of(st.id)::jsonb, 'leader', gl.leader_id = st.id,
      'gp', case when p_hid then null else mg.gp end) order by (gl.leader_id = st.id) desc, st.no), '[]'::jsonb)
    from guild_members gm join students st on st.id = gm.student_id join guilds gl on gl.id = gm.guild_id
    left join _guild_member_gp() mg on mg.student_id = st.id where gm.guild_id = p_guild $$;
revoke execute on function _guild_member_card(uuid, boolean) from public, anon, authenticated;

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
           _guild_member_card(r.guild_id, true) as members
      from _guild_ranks() r join classes c on c.id = r.class_id where r.ranked order by r.rank limit 30) x;
  return json_build_object('cfg', cfg, 'hidden', false, 'rows', rws,
    'unranked', (select count(*) from _guild_ranks() where not ranked), 'total', (select count(*) from guilds));
end $$;
revoke execute on function guild_board(uuid) from public;
grant execute on function guild_board(uuid) to anon, authenticated;
