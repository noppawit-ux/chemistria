-- 101: บัพจากความสัมพันธ์ — เพื่อนที่ผูกความสัมพันธ์กันได้บัพถาวรเล็กน้อยทั้งคู่ (ไม่ต้องใช้ไอเทม ไม่หมดเวลา)
-- ต้องรันหลัง 66 (ไอเทมบัพ), 68 (เพื่อน), 99 · รันซ้ำได้
-- แต่ละชนิดความสัมพันธ์ให้บัพ 1 ชนิด (relation_types.buff_kind / buff_power) · ครูแก้ได้ที่ตาราง relation_types
-- รวมบัพจากเพื่อนทุกคนแล้วตัดเพดาน: เปอร์เซ็นต์ (EXP/เหรียญ/ดาเมจบอส) ไม่เกิน rel_cap_pct (15) · ค่าคงที่ (EXP ควิซ, โอกาส SR) ไม่เกิน rel_cap_flat (6)
-- ผลต่อดาเมจบอสในศึกคูณ 2 ตามกติกา SQL 99 เหมือนสเตตัสพลัง

alter table relation_types add column if not exists buff_kind text;
alter table relation_types add column if not exists buff_power int not null default 0;

update relation_types set buff_kind = v.k, buff_power = v.p
  from (values ('friend','buff_exp',2),('bestie','buff_exp',4),('study','buff_int',3),('rival','buff_str',3),
               ('bff','buff_exp',6),('mischief','buff_coin',6),('lab','buff_luk',3),
               ('forever','buff_exp',8),('legend','buff_str',5),('family','buff_coin',8)) v(key, k, p)
 where relation_types.key = v.key and relation_types.buff_kind is null;

insert into app_settings (key, value) values ('rel_cap_pct','15'), ('rel_cap_flat','6') on conflict (key) do nothing;

-- บัพจากความสัมพันธ์ของนักเรียน (รายเพื่อน)
create or replace function _rel_buff_list(p_sid uuid) returns json
language sql stable security definer set search_path = public as $$
  select coalesce(json_agg(json_build_object('kind', t.buff_kind, 'power', t.buff_power, 'name', o.name, 'rel', t.name, 'emoji', t.emoji) order by t.buff_power desc, o.name), '[]'::json)
    from friendships f
    join relation_types t on t.key = f.rel and t.buff_kind is not null and t.buff_power > 0
    join students o on o.id = case when f.a = p_sid then f.b else f.a end
   where (f.a = p_sid or f.b = p_sid) and f.rel is not null
$$;
revoke execute on function _rel_buff_list(uuid) from public, anon, authenticated;

-- ครอบ _stats: บวกบัพความสัมพันธ์เข้า effects (ทุกที่ที่ใช้ effects ได้ผลอัตโนมัติ: EXP/เหรียญ/ดาเมจบอส/EXP ควิซ/โอกาส SR)
do $$ begin
  if not exists (select 1 from pg_proc where proname = '_stats_base' and pronamespace = 'public'::regnamespace) then
    alter function _stats(uuid) rename to _stats_base;
  end if;
end $$;
revoke execute on function _stats_base(uuid) from public, anon, authenticated;
create or replace function _stats(p_sid uuid) returns json
language plpgsql stable security definer set search_path = public as $$
declare r jsonb := _stats_base(p_sid)::jsonb; l json := _rel_buff_list(p_sid); cp int := _setting_int('rel_cap_pct', 15); cf int := _setting_int('rel_cap_flat', 6);
        e int; c int; s int; q int; u int; ef jsonb := r->'effects';
begin
  select least(cp, coalesce(sum((x->>'power')::int) filter (where x->>'kind' = 'buff_exp'), 0)),
         least(cp, coalesce(sum((x->>'power')::int) filter (where x->>'kind' = 'buff_coin'), 0)),
         least(cp, coalesce(sum((x->>'power')::int) filter (where x->>'kind' = 'buff_str'), 0)),
         least(cf, coalesce(sum((x->>'power')::int) filter (where x->>'kind' = 'buff_int'), 0)),
         least(cf, coalesce(sum((x->>'power')::int) filter (where x->>'kind' = 'buff_luk'), 0))
    into e, c, s, q, u from json_array_elements(l) x;
  ef := ef || jsonb_build_object('exp_pct', (ef->>'exp_pct')::int + e, 'coin_pct', (ef->>'coin_pct')::int + c, 'boss_pct', (ef->>'boss_pct')::int + s,
                                 'quiz_exp', (ef->>'quiz_exp')::int + q, 'rare_pct', (ef->>'rare_pct')::int + u);
  return (r || jsonb_build_object('effects', ef, 'rel_buffs', l::jsonb,
            'rel_total', jsonb_build_object('buff_exp', e, 'buff_coin', c, 'buff_str', s, 'buff_int', q, 'buff_luk', u)))::json;
end $$;
revoke execute on function _stats(uuid) from public, anon, authenticated;

-- หน้าหลัก: ส่งบัพของแต่ละความสัมพันธ์ + ตารางชนิดความสัมพันธ์ไปด้วย
create or replace function _rel_home(p_sid uuid) returns json
language sql stable security definer set search_path = public as $$
  select json_build_object(
    'rels', coalesce((select json_agg(json_build_object('no', o.no, 'name', o.name, 'rp', f.rp, 'rel', f.rel, 'rel_name', t.name, 'rel_emoji', t.emoji,
          'buff_kind', t.buff_kind, 'buff_power', t.buff_power) order by f.rp desc)
        from friendships f join students o on o.id = case when f.a = p_sid then f.b else f.a end left join relation_types t on t.key = f.rel
       where (f.a = p_sid or f.b = p_sid) and f.rel is not null), '[]'::json),
    'incoming', coalesce((select json_agg(json_build_object('no', o.no, 'name', o.name, 'rel', f.pend_rel, 'rel_name', t.name, 'rel_emoji', t.emoji, 'buff_kind', t.buff_kind, 'buff_power', t.buff_power))
        from friendships f join students o on o.id = f.pend_by join relation_types t on t.key = f.pend_rel
       where (f.a = p_sid or f.b = p_sid) and f.pend_by is not null and f.pend_by <> p_sid), '[]'::json),
    'types', coalesce((select json_agg(json_build_object('key', t.key, 'name', t.name, 'emoji', t.emoji, 'need_rp', t.need_rp, 'buff_kind', t.buff_kind, 'buff_power', t.buff_power) order by t.need_rp, t.sort)
        from relation_types t where t.active), '[]'::json),
    'caps', json_build_object('pct', _setting_int('rel_cap_pct', 15), 'flat', _setting_int('rel_cap_flat', 6)),
    'new_gifts', (select count(*) from gift_log where to_id = p_sid and not seen))
$$;
revoke execute on function _rel_home(uuid) from public, anon, authenticated;
