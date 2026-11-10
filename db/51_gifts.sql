-- =====================================================================
-- 51: แจกของขวัญให้นักเรียนหลายคนพร้อมกัน (แอดมิน → แท็บ 🎁 ของขวัญ) · รันซ้ำได้
--  ของขวัญ = EXP / เหรียญ / ตั๋วกาชาฟรี / ไอเทมตกแต่ง / สิทธิพิเศษ + ข้อความจากครู · นักเรียนเห็นป๊อปอัปครั้งเดียวเมื่อเปิดแอป
-- =====================================================================
create table if not exists gifts (
  id uuid primary key default gen_random_uuid(),
  batch uuid not null,
  student_id uuid not null references students(id) on delete cascade,
  message text not null default '',
  exp int not null default 0, coins int not null default 0, pulls int not null default 0,
  decor_id uuid references decor_items(id) on delete set null,
  privilege_id uuid references privileges(id) on delete set null,
  seen boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists gifts_student on gifts(student_id, seen);
alter table gifts enable row level security;
drop policy if exists teacher_all on gifts;
create policy teacher_all on gifts for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on gifts from anon;

-- แจกของขวัญ: p_students = รายชื่อนักเรียน (uuid[])
create or replace function admin_gift(p_students uuid[], p_exp int default 0, p_coins int default 0, p_pulls int default 0,
                                      p_decor uuid default null, p_priv uuid default null, p_message text default '')
returns json language plpgsql security definer set search_path = public as $$
declare sid uuid; b uuid := gen_random_uuid(); n int := 0; dup int := 0; ids uuid[]; msg text := left(coalesce(btrim(p_message), ''), 200);
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  select array_agg(distinct x) into ids from unnest(coalesce(p_students, '{}')) x;
  if ids is null or cardinality(ids) = 0 then raise exception 'ยังไม่ได้เลือกนักเรียน'; end if;
  if cardinality(ids) > 600 then raise exception 'เลือกนักเรียนได้ครั้งละไม่เกิน 600 คน'; end if;
  if coalesce(p_exp, 0) < 0 or coalesce(p_coins, 0) < 0 or coalesce(p_pulls, 0) < 0 then raise exception 'จำนวนต้องไม่ติดลบ (ถ้าจะหักให้ใช้ ± EXP/เหรียญ ในแท็บนักเรียน)'; end if;
  if p_exp > 10000 or p_coins > 10000 or p_pulls > 50 then raise exception 'จำนวนมากเกินไป (EXP/เหรียญ ≤ 10000 · ตั๋ว ≤ 50)'; end if;
  if coalesce(p_exp, 0) = 0 and coalesce(p_coins, 0) = 0 and coalesce(p_pulls, 0) = 0 and p_decor is null and p_priv is null then raise exception 'ยังไม่ได้เลือกของขวัญ'; end if;
  if p_decor is not null and not exists (select 1 from decor_items where id = p_decor) then raise exception 'ไม่พบไอเทมตกแต่ง'; end if;
  if p_priv is not null and not exists (select 1 from privileges where id = p_priv) then raise exception 'ไม่พบสิทธิพิเศษ'; end if;
  for sid in select id from students where id = any(ids) loop
    if coalesce(p_exp, 0) > 0 or coalesce(p_coins, 0) > 0 then
      perform award(sid, coalesce(p_exp, 0), coalesce(p_coins, 0), '🎁 ของขวัญจากครู' || case when msg <> '' then ': ' || msg else '' end, 'gift:' || b);
    end if;
    if coalesce(p_pulls, 0) > 0 then update students set free_pulls = free_pulls + p_pulls where id = sid; end if;
    if p_decor is not null then
      insert into student_decor (student_id, item_id, source) values (sid, p_decor, 'teacher') on conflict do nothing;
      if not found then dup := dup + 1; end if;
    end if;
    if p_priv is not null then insert into redemptions (student_id, privilege_id, source) values (sid, p_priv, 'teacher'); end if;
    insert into gifts (batch, student_id, message, exp, coins, pulls, decor_id, privilege_id)
    values (b, sid, msg, coalesce(p_exp, 0), coalesce(p_coins, 0), coalesce(p_pulls, 0), p_decor, p_priv);
    n := n + 1;
  end loop;
  perform check_achievements(s.id) from students s where s.id = any(ids);
  return json_build_object('given', n, 'decor_already_owned', dup, 'batch', b);
end $$;
revoke execute on function admin_gift(uuid[], int, int, int, uuid, uuid, text) from public, anon;
grant execute on function admin_gift(uuid[], int, int, int, uuid, uuid, text) to authenticated;

-- นักเรียน: ของขวัญที่ยังไม่เคยเห็น + กดรับทราบ
create or replace function gift_inbox(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  return coalesce((select json_agg(json_build_object('id', g.id, 'message', g.message, 'exp', g.exp, 'coins', g.coins, 'pulls', g.pulls,
            'decor', d.name, 'decor_emoji', d.emoji, 'privilege', p.name, 'at', g.created_at) order by g.created_at)
          from gifts g left join decor_items d on d.id = g.decor_id left join privileges p on p.id = g.privilege_id
         where g.student_id = sid and not g.seen), '[]'::json);
end $$;
create or replace function gift_ack(p_token uuid) returns void
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin update gifts set seen = true where student_id = sid and not seen; end $$;
revoke execute on function gift_inbox(uuid), gift_ack(uuid) from public;
grant execute on function gift_inbox(uuid), gift_ack(uuid) to anon, authenticated;
