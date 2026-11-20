-- 105: ลดงานซ้ำของกระดานกิลด์ (guild_board) และ rank gate — ผลลัพธ์ JSON เหมือนเดิมทุกประการ
-- สาเหตุที่ช้า: _guild_member_card() สแกน ledger ทั้งก้อน (_guild_member_gp) ใหม่ทุกกิลด์ แม้โหมดซ่อนคะแนนไม่ได้ใช้ค่า gp
--   → กระดาน 30 กิลด์ = สแกน ~30 รอบต่อ 1 คำขอ (ในข้อมูลจำลอง 170 คน: 355 ms → ลดเหลือหลักสิบ ms)
-- 1) _guild_member_card: ถ้า p_hid = true ไม่ join _guild_member_gp เลย (gp เป็น null อยู่แล้ว)
create or replace function _guild_member_card(p_guild uuid, p_hid boolean) returns jsonb
language plpgsql stable security definer set search_path = public as $$
begin
  if p_hid then
    return (select coalesce(jsonb_agg(jsonb_build_object('no', st.no, 'name', st.name, 'avatar', st.avatar, 'char_class', st.char_class,
        'rank_info', rank_info(st.exp)::jsonb, 'decor', _decor_of(st.id)::jsonb, 'leader', gl.leader_id = st.id,
        'gp', null) order by (gl.leader_id = st.id) desc, st.no), '[]'::jsonb)
      from guild_members gm join students st on st.id = gm.student_id join guilds gl on gl.id = gm.guild_id
      where gm.guild_id = p_guild);
  end if;
  return (select coalesce(jsonb_agg(jsonb_build_object('no', st.no, 'name', st.name, 'avatar', st.avatar, 'char_class', st.char_class,
      'rank_info', rank_info(st.exp)::jsonb, 'decor', _decor_of(st.id)::jsonb, 'leader', gl.leader_id = st.id,
      'gp', mg.gp) order by (gl.leader_id = st.id) desc, st.no), '[]'::jsonb)
    from guild_members gm join students st on st.id = gm.student_id join guilds gl on gl.id = gm.guild_id
    left join _guild_member_gp() mg on mg.student_id = st.id where gm.guild_id = p_guild);
end $$;
revoke execute on function _guild_member_card(uuid, boolean) from public, anon, authenticated;

-- 2) guild_board: คำนวณอันดับครั้งเดียว (เดิมเรียก _guild_ranks 2 รอบ)
create or replace function guild_board(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cfg jsonb := _guild_cfg(); mygid uuid; rws jsonb; unr bigint;
begin
  select guild_id into mygid from guild_members where student_id = sid;
  if (cfg->>'hidden')::boolean then return json_build_object('cfg', cfg, 'hidden', true, 'rows', '[]'::json); end if;
  with rk as materialized (select * from _guild_ranks())
  select (select coalesce(jsonb_agg(x order by x.rank), '[]') from (
            select r.rank, r.name, c.name as class_name, r.size, r.avg, (r.guild_id = mygid) as mine, r.room_rank,
                   _guild_emb(gl.id, gl.emblem) as emblem, _guild_member_card(r.guild_id, true) as members
              from rk r join classes c on c.id = r.class_id join guilds gl on gl.id = r.guild_id where r.ranked order by r.rank limit 30) x),
         (select count(*) from rk where not ranked)
    into rws, unr;
  return json_build_object('cfg', cfg, 'hidden', false, 'rows', rws, 'unranked', unr, 'total', (select count(*) from guilds));
end $$;
revoke execute on function guild_board(uuid) from public;
grant execute on function guild_board(uuid) to anon, authenticated;

-- 3) _rank_gate: อ่านค่า rank_trial_on ครั้งเดียวต่อคำสั่ง (เดิมอ่านทุกแถวของ ch_ranks ≈ 11 ครั้ง/การเรียก)
create or replace function _rank_gate(p_sid uuid, p_exp int) returns text
language sql stable security definer set search_path = public as $$
  select r.key from ch_ranks r
   where (select _setting_int('rank_trial_on', 1)) = 1 and r.sort > 1 and r.min_exp <= greatest(p_exp, 0)
     and exists (select 1 from monsters m where m.trial_rank = r.key and m.active)
     and not exists (select 1 from rank_trial_pass p where p.student_id = p_sid and p.rank_key = r.key)
   order by r.sort limit 1
$$;
