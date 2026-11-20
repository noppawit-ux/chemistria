-- 106: (ก) แก้ถอยหลังจาก 105: การ์ดสมาชิกกิลด์ต้องใช้แรงค์ที่ผ่านด่านแล้ว (_rank_info_s) เหมือนเดิม — 105 เผลอเรียก rank_info(exp) ตรง ๆ
--      ทำให้คนที่ยังไม่ผ่านด่านแรงค์แสดงแรงค์สูงเกินจริงในกระดานกิลด์  (ข) ลดงานซ้ำเพิ่ม โดยผลลัพธ์ JSON เหมือนเดิมทุกไบต์
-- 1) _rank_exp: หาด่านครั้งเดียว (เดิม _rank_gate ถูกเรียกทุกแถวของ ch_ranks ≈ 11 ครั้ง)
create or replace function _rank_exp(p_sid uuid, p_exp int) returns int
language sql stable security definer set search_path = public as $$
  select coalesce((select least(greatest(p_exp, 0), r.min_exp - 1) from ch_ranks r where r.key = (select _rank_gate(p_sid, p_exp))), p_exp)
$$;
-- 2) _rank_info_s: คำนวณด่านครั้งเดียว (เดิมเรียก _rank_gate ซ้ำอีกรอบผ่าน _rank_exp)
create or replace function _rank_info_s(p_sid uuid, p_exp int) returns json
language plpgsql stable security definer set search_path = public as $$
declare g text := _rank_gate(p_sid, p_exp); gr ch_ranks%rowtype; j jsonb;
begin
  if g is null then return rank_info(p_exp)::jsonb::json; end if;
  select * into gr from ch_ranks where key = g;
  j := rank_info(least(greatest(p_exp, 0), gr.min_exp - 1))::jsonb
       || jsonb_build_object('locked', true, 'gate_key', gr.key, 'gate_name', gr.name, 'gate_image', gr.image, 'gate_exp', gr.min_exp);
  return j::json;
end $$;
revoke execute on function _rank_gate(uuid, int), _rank_exp(uuid, int), _rank_info_s(uuid, int) from public, anon, authenticated;
-- 3) _guild_member_card: ใช้ _rank_info_s (คืนพฤติกรรมเดิม) + ไม่สแกนคะแนนเมื่อซ่อนคะแนน
create or replace function _guild_member_card(p_guild uuid, p_hid boolean) returns jsonb
language plpgsql stable security definer set search_path = public as $$
begin
  if p_hid then
    return (select coalesce(jsonb_agg(jsonb_build_object('no', st.no, 'name', st.name, 'avatar', st.avatar, 'char_class', st.char_class,
        'rank_info', _rank_info_s(st.id, st.exp)::jsonb, 'decor', _decor_of(st.id)::jsonb, 'leader', gl.leader_id = st.id,
        'gp', null) order by (gl.leader_id = st.id) desc, st.no), '[]'::jsonb)
      from guild_members gm join students st on st.id = gm.student_id join guilds gl on gl.id = gm.guild_id
      where gm.guild_id = p_guild);
  end if;
  return (select coalesce(jsonb_agg(jsonb_build_object('no', st.no, 'name', st.name, 'avatar', st.avatar, 'char_class', st.char_class,
      'rank_info', _rank_info_s(st.id, st.exp)::jsonb, 'decor', _decor_of(st.id)::jsonb, 'leader', gl.leader_id = st.id,
      'gp', mg.gp) order by (gl.leader_id = st.id) desc, st.no), '[]'::jsonb)
    from guild_members gm join students st on st.id = gm.student_id join guilds gl on gl.id = gm.guild_id
    left join _guild_member_gp() mg on mg.student_id = st.id where gm.guild_id = p_guild);
end $$;
revoke execute on function _guild_member_card(uuid, boolean) from public, anon, authenticated;
-- 4) แต้มกิลด์ของคนเดียว (สูตรเดียวกับ _guild_member_gp แต่ดูเฉพาะ ledger ของคนนั้น) — guild_status ไม่ต้องสแกนทั้งตาราง
create or replace function _guild_gp_of(p_sid uuid) returns numeric
language sql stable security definer set search_path = public as $$
  with c as (select _guild_cfg() j),
  w as (select ((j->>'start')::date)::timestamp at time zone 'Asia/Bangkok' st, (((j->>'end')::date + 1)::timestamp at time zone 'Asia/Bangkok') en, (j->>'cap_day')::int cap from c),
  d as (select (l.created_at at time zone 'Asia/Bangkok')::date dt, sum(l.exp) e
          from ledger l, w where l.student_id = p_sid and l.exp > 0 and l.created_at >= w.st and l.created_at < w.en and _gp_ok(l.reason) group by 1)
  select coalesce(sum(least((select cap from w), coalesce(d.e, 0))), 0)::numeric from d
$$;
revoke execute on function _guild_gp_of(uuid) from public, anon, authenticated;
-- 5) _guild_status: ตัดส่วน members ที่ guild_status (ตัวห่อ) คำนวณทับอยู่แล้ว + ใช้ _guild_gp_of แทนการสแกนทั้งตาราง (3 รอบ → 1 รอบ)
create or replace function _guild_status(p_token uuid) returns json
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
    mygp := _guild_gp_of(sid);
    me := jsonb_build_object('id', gid, 'name', rk.name, 'size', rk.size, 'ranked', rk.ranked,
      'leader', exists (select 1 from guilds where id = gid and leader_id = sid),
      'can_rename', exists (select 1 from guilds where id = gid and leader_id = sid and not renamed) and t <= en,
      'auto', (select auto from guilds where id = gid),
      'personal_gp', case when hid then null else mygp end,
      'avg', case when hid then null else v_avg end, 'total', case when hid then null else rk.total end,
      'rank', case when hid then null else rk.rank end, 'room_rank', case when hid then null else rk.room_rank end,
      'members', '[]'::jsonb);   -- guild_status() ใส่รายชื่อสมาชิกจริงทับอยู่แล้ว
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
revoke execute on function _guild_status(uuid) from public, anon, authenticated;
