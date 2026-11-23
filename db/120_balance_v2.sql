-- SQL 120 · ปรับสมดุลรอบ 2: เพดานเพิ่มเล็กน้อย · ลดรางวัล Achievement/ดันเจี้ยน · ตัด EXP ที่ได้เกินเพดานย้อนหลัง
-- ต้องรันหลัง 119 · รันซ้ำได้ (แต่ละส่วนทำครั้งเดียว บันทึกใน bal_patch)
--   1) เพดานเล่นต่อวัน: EXP 100→120 · เหรียญ 150→180 (เปลี่ยนเฉพาะที่ยังเป็นค่าเริ่มต้น ถ้าครูตั้งเองไว้จะไม่ทับ)
--   2) รางวัล Achievement (EXP/เหรียญ) ลดเหลือ 50% (ผู้ที่รับไปแล้วไม่ถูกเรียกคืน)
--   3) ดันเจี้ยน: EXP/เหรียญต่อชั้น และ EXP/เหรียญในหีบ (loot_items ของ dungeon:*) ลดเหลือ 50%
--   4) ย้อนหลัง: แต่ละวันที่ EXP จากการเล่น (มินิเกม/ต่อสู้/ท้าดวล/ดันเจี้ยน/หีบ) เกินเพดานใหม่ → หักส่วนเกินออกจาก EXP นักเรียน
--      บันทึกรายวันใน exp_fix_log + แถว ledger "ปรับสมดุล EXP" (ref fix:exp120:<id>) · แก้เฉพาะ EXP ไม่เรียกคืนเหรียญที่ใช้ไปแล้ว
--
-- ดูตัวอย่างก่อนรันจริง (อ่านอย่างเดียว ไม่แก้ข้อมูล) — แต่ละแถวคือ นักเรียน/วัน ที่จะถูกหัก EXP:
--   select s.name, x.d, x.s as play_exp, x.s - 120 as cut from (
--     select student_id, (created_at at time zone 'Asia/Bangkok')::date d, sum(exp)::int s from ledger
--      where exp > 0 and (ref_key ~ '^(game|dungeon):' or (ref_key is null and reason ~ '^(ดรอปมอนสเตอร์|หีบดันเจี้ยน|รางวัลจากครูบุ๊ค)'))
--      group by 1, 2) x join students s on s.id = x.student_id where x.s > 120 order by cut desc;

create table if not exists bal_patch (key text primary key, done_at timestamptz not null default now());
alter table bal_patch enable row level security;
drop policy if exists teacher_all on bal_patch;
create policy teacher_all on bal_patch for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on bal_patch from anon;

create table if not exists exp_fix_log (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  day date not null, play_exp int not null, cap int not null, cut int not null,
  created_at timestamptz not null default now(), unique (student_id, day));
alter table exp_fix_log enable row level security;
drop policy if exists teacher_all on exp_fix_log;
create policy teacher_all on exp_fix_log for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on exp_fix_log from anon;

-- 1) เพดาน
update app_settings set value = '120' where key = 'play_daily_cap_exp' and value = '100';
update app_settings set value = '180' where key = 'play_daily_cap_coins' and value = '150';

-- 2) Achievement
do $$ begin
  if not exists (select 1 from bal_patch where key = 'ach_half') then
    update achievements set reward_exp = case when reward_exp > 0 then greatest(1, round(reward_exp * 0.5)::int) else 0 end,
                            reward_coins = case when reward_coins > 0 then greatest(1, round(reward_coins * 0.5)::int) else 0 end;
    insert into bal_patch (key) values ('ach_half');
  end if;
end $$;

-- 3) ดันเจี้ยน
do $$ begin
  if not exists (select 1 from bal_patch where key = 'dungeon_half') then
    update dungeon_floors set exp = greatest(1, round(exp * 0.5)::int), coins = greatest(1, round(coins * 0.5)::int);
    update loot_items set value = greatest(1, round(value * 0.5)::int) where source like 'dungeon:%' and kind in ('exp', 'coins');
    insert into bal_patch (key) values ('dungeon_half');
  end if;
end $$;

-- 4) แก้ประวัติ EXP เกินเพดานย้อนหลัง
create or replace function _fix_exp_history(p_cap int) returns int
language plpgsql security definer set search_path = public as $$
declare r record; n int := 0; tot int;
begin
  if p_cap <= 0 then return 0; end if;
  insert into exp_fix_log (student_id, day, play_exp, cap, cut)
  select student_id, d, s, p_cap, s - p_cap from (
    select student_id, (created_at at time zone 'Asia/Bangkok')::date d, sum(exp)::int s from ledger
     where exp > 0 and _is_play_ledger(ref_key, reason) group by 1, 2) x
   where s > p_cap
  on conflict (student_id, day) do nothing;
  for r in select student_id, sum(cut)::int cut, count(*)::int days from exp_fix_log group by student_id loop
    if award(r.student_id, -r.cut, 0, 'ปรับสมดุล EXP: ตัดส่วนที่เกินเพดานการเล่น ' || r.days || ' วัน (รวม ' || r.cut || ')', 'fix:exp120:' || r.student_id) then n := n + 1; end if;
  end loop;
  return n;
end $$;
revoke execute on function _fix_exp_history(int) from public, anon, authenticated;

do $$ begin
  if not exists (select 1 from bal_patch where key = 'exp_history_fix') then
    perform _fix_exp_history(_setting_int('play_daily_cap_exp', 120));
    insert into bal_patch (key) values ('exp_history_fix');
  end if;
end $$;
