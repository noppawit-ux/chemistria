-- 71: ระบบป้องกันใหม่ในการต่อสู้ — "ตั้งรับ" เป็นแอคชันที่เลือกเอง แทนการกดลูกศรลดดาเมจทุกรอบ
--  • ปกติมอนสเตอร์โจมตีอัตโนมัติ รับดาเมจ 70% ของค่าพื้นฐาน (ไม่ต้องกดลูกศร)
--  • ทุกเทิร์นที่ 3 (3,6,9…) มอนสเตอร์ "โจมตีหนัก" ×1.5 (หน้าเว็บเตือนล่วงหน้า)
--  • ตั้งรับ (แทนการโจมตี 1 เทิร์น · ไม่ต้องตอบคำถาม · คูลดาวน์ 2 เทิร์น): กดลูกศรให้ตรง ยิ่งถูกยิ่งลดดาเมจ (ถูกหมด = 0)
--    ถูกครบทุกลูกศร = ปัดป้องสมบูรณ์ → สวนกลับ + ฟื้น HP 8%
--  • โล่โมล (บัพของ Guardian) ยังลดดาเมจ 50% และทำให้ตั้งรับมีลูกศรน้อยลง 1 ลูก
-- ต้องรันหลัง 17 (และ 69/70 ถ้าใช้ด่านบอส) — ไม่แตะข้อมูลเดิม
alter table battles add column if not exists guard boolean not null default false;

-- ให้มุมมองการต่อสู้ส่ง guard / guard_left ให้หน้าเว็บ
do $$
declare d text;
begin
  select pg_get_functiondef('_battle_view(uuid)'::regprocedure) into d;
  if d not like '%guard_left%' then
    d := replace(d, '''turn'', b.turn,', '''turn'', b.turn, ''guard'', b.guard, ''guard_left'', coalesce((b.cds->>''guard'')::int, 0),');
    if d not like '%guard_left%' then raise exception 'แก้ _battle_view ไม่สำเร็จ'; end if;
    execute d;
  end if;
end $$;

-- ตั้งรับ: ใช้แทนการโจมตี 1 เทิร์น แล้วเข้าสู่มินิเกมกดลูกศร
create or replace function battle_guard(p_token uuid, p_battle uuid) returns json
language plpgsql security definer set search_path = public as $$
declare
  sid uuid := _sid(p_token); b battles%rowtype; m monsters%rowtype; cdz jsonb; k text; n int; i int; seqs text := '';
begin
  select * into b from battles where id = p_battle and student_id = sid for update;
  if not found or b.status <> 'active' then raise exception 'ไม่พบการต่อสู้ที่กำลังเล่นอยู่'; end if;
  if b.pend is not null then raise exception 'ต้องป้องกันการโจมตีของมอนสเตอร์ก่อน'; end if;
  if b.cur_q is not null then raise exception 'กำลังตอบคำถามอยู่'; end if;
  cdz := b.cds;
  if coalesce((cdz->>'guard')::int, 0) > 0 then raise exception 'ตั้งรับยังรอคูลดาวน์'; end if;
  select * into m from monsters where id = b.monster_id;
  -- คูลดาวน์สกิลอื่นลด 1 เทิร์น (เหมือนการใช้สกิล) แล้วตั้งคูลดาวน์ตั้งรับ 2 เทิร์น
  for k in select jsonb_object_keys(cdz) loop cdz := jsonb_set(cdz, array[k], to_jsonb(greatest(0, (cdz->>k)::int - 1))); end loop;
  cdz := jsonb_set(cdz, '{guard}', to_jsonb(2));
  n := least(5, 2 + m.level);
  if coalesce((b.buffs->>'shield')::int, 0) > 0 then n := greatest(2, n - 1); end if;
  for i in 1..n loop seqs := seqs || substr('LURD', 1 + floor(random() * 4)::int, 1); end loop;
  update battles set guard = true, cds = cdz,
         pend = jsonb_build_object('dmg', greatest(1, round(m.atk * (0.85 + random() * 0.3))::int), 'n', n, 'seq', seqs, 'at', extract(epoch from now()))
   where id = b.id;
  return _battle_view(b.id);
end $$;

-- รับการโจมตีของมอนสเตอร์ (ไม่ตั้งรับ = ลูกศรไม่มีผล รับ 70%)
create or replace function battle_defend(p_token uuid, p_battle uuid, p_hits int) returns json
language plpgsql security definer set search_path = public as $$
declare
  sid uuid := _sid(p_token); b battles%rowtype; m monsters%rowtype; n int; hits int := 0; dmg int; fin int; shield boolean := false;
  bf jsonb; el numeric; rw_exp int := 0; ev jsonb; heavy boolean; perfect boolean := false; ctr int := 0; hl int := 0; st json;
  intl int; mult numeric;
begin
  select * into b from battles where id = p_battle and student_id = sid for update;
  if not found or b.status <> 'active' or b.pend is null then raise exception 'ไม่มีการโจมตีให้ป้องกัน'; end if;
  select * into m from monsters where id = b.monster_id;
  n := (b.pend->>'n')::int; dmg := (b.pend->>'dmg')::int;
  heavy := (b.turn % 3 = 0);
  if heavy then dmg := round(dmg * 1.5)::int; end if;
  bf := b.buffs;
  if b.guard then
    el := extract(epoch from now()) - (b.pend->>'at')::numeric;
    hits := greatest(0, least(coalesce(p_hits, 0), n));
    if el < 0.25 * hits then hits := 0; end if;            -- เร็วเกินคนกดไม่ทัน = ไม่นับ
    perfect := n > 0 and hits = n;
    fin := round(dmg * (1 - hits::numeric / n))::int;
  else
    fin := round(dmg * 0.7)::int;
  end if;
  if coalesce((bf->>'shield')::int, 0) > 0 then
    shield := true; fin := round(fin * 0.5)::int; bf := jsonb_set(bf, '{shield}', to_jsonb((bf->>'shield')::int - 1));
  end if;
  fin := greatest(case when perfect then 0 else 1 end, fin);
  if coalesce((bf->>'weak')::int, 0) > 0 then bf := jsonb_set(bf, '{weak}', to_jsonb((bf->>'weak')::int - 1)); end if;
  b.p_hp := greatest(0, b.p_hp - fin);
  -- ปัดป้องสมบูรณ์: สวนกลับ + ฟื้น HP (สวนกลับไม่ฆ่า เหลือ HP อย่างน้อย 1)
  if perfect and b.p_hp > 0 then
    st := _stats(sid); intl := coalesce((st->'int'->>'total')::int, 0);
    mult := 1 + coalesce((st->'effects'->>'boss_pct')::int, 0) / 100.0;
    if coalesce((bf->>'weak')::int, 0) > 0 then mult := mult * 1.4; end if;
    ctr := greatest(1, round((20 + intl / 2.0) * mult)::int);
    ctr := least(ctr, greatest(0, b.m_hp - 1));
    b.m_hp := b.m_hp - ctr;
    hl := least(b.p_max - b.p_hp, round(b.p_max * 0.08)::int); b.p_hp := b.p_hp + hl;
  end if;
  ev := jsonb_build_object('hits', hits, 'n', n, 'taken', fin, 'raw', dmg, 'shield', shield, 'guard', b.guard, 'heavy', heavy,
                           'perfect', perfect, 'counter', ctr, 'heal', hl);
  if b.p_hp <= 0 then
    if b.rewarded then
      rw_exp := least(6, b.correct * 2);
      if rw_exp > 0 then perform award(sid, rw_exp, 0, 'สู้มอนสเตอร์: ' || m.name || ' (ให้กำลังใจ)', 'game:battle:' || b.id); end if;
    end if;
    update battles set status = 'lost', finished_at = now(), p_hp = 0, pend = null, guard = false, buffs = bf, exp = rw_exp, turn = b.turn + 1 where id = b.id;
  else
    update battles set p_hp = b.p_hp, m_hp = b.m_hp, pend = null, guard = false, buffs = bf, turn = b.turn + 1 where id = b.id;
  end if;
  return json_build_object('event', ev, 'state', _battle_view(b.id));
end $$;

revoke execute on function battle_guard(uuid, uuid) from public;
grant execute on function battle_guard(uuid, uuid) to anon, authenticated;
