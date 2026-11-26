-- SQL 122 · ยกเพดานเล่นต่อวัน + โบนัสไล่ตามทัน (catch-up) สำหรับคนที่ EXP ตามหลังห้อง
-- ต้องรันหลัง 121 · รันซ้ำได้ · ไม่แก้ award/battle_* (ขยายทริกเกอร์ trg_play_cap เดิม)
--  1) เพดานเล่นต่อวัน: EXP 120→150 · เหรียญ 180→200 (เปลี่ยนเฉพาะที่ยังเป็นค่า 120/180 ถ้าครูตั้งเองไว้จะไม่ทับ)
--  2) โบนัสไล่ตามทัน: เทียบ EXP ของนักเรียนกับค่ากลาง (median) ของห้อง (นับเฉพาะคนที่มี EXP > 0)
--       ต่ำกว่า 50% ของค่ากลาง → เพดาน ×2.0 · ต่ำกว่า 75% → ×1.5 · นอกนั้น ×1 (ครูแก้ได้: catchup_on = 1/0, catchup_t1/t2 = เปอร์เซ็นต์, catchup_m1/m2 = ตัวคูณ)
--       ใช้กับเพดาน EXP และเหรียญจากการเล่น · ไม่แตะรางวัลที่ครูกำหนด (เช็คชื่อ/ส่งงาน/เควส)

insert into app_settings (key, value) values
  ('catchup_on', '1'), ('catchup_t1', '50'), ('catchup_t2', '75'), ('catchup_m1', '2'), ('catchup_m2', '1.5')
on conflict (key) do nothing;
update app_settings set value = '150' where key = 'play_daily_cap_exp' and value = '120';
update app_settings set value = '200' where key = 'play_daily_cap_coins' and value = '180';

create or replace function _play_cap_mult(p_sid uuid) returns numeric
language plpgsql stable security definer set search_path = public as $$
declare me int; cls uuid; med numeric; r numeric;
begin
  if _setting_int('catchup_on', 1) <> 1 then return 1; end if;
  select exp, class_id into me, cls from students where id = p_sid;
  if me is null then return 1; end if;
  select percentile_cont(0.5) within group (order by exp) into med from students where class_id = cls and exp > 0;
  if med is null or med <= 0 then return 1; end if;
  r := me / med * 100;
  if r < _setting_int('catchup_t1', 50) then return coalesce(nullif((select value from app_settings where key = 'catchup_m1'), '')::numeric, 2); end if;
  if r < _setting_int('catchup_t2', 75) then return coalesce(nullif((select value from app_settings where key = 'catchup_m2'), '')::numeric, 1.5); end if;
  return 1;
end $$;
revoke execute on function _play_cap_mult(uuid) from public, anon, authenticated;

create or replace function trg_play_cap() returns trigger
language plpgsql security definer set search_path = public as $$
declare mult numeric; capx int := _setting_int('play_daily_cap_exp', 150); capc int := _setting_int('play_daily_cap_coins', 200);
        roomx int; roomc int; cutx int := 0; cutc int := 0; note text := '';
begin
  if (new.exp <= 0 and new.coins <= 0) or not _is_play_ledger(new.ref_key, new.reason) then return new; end if;
  if capx <= 0 and capc <= 0 then return new; end if;
  perform pg_advisory_xact_lock(hashtextextended('play_cap:' || new.student_id::text, 0));
  if new.ref_key is not null and exists (select 1 from ledger where student_id = new.student_id and ref_key = new.ref_key) then return new; end if;
  mult := _play_cap_mult(new.student_id);
  capx := ceil(capx * mult)::int; capc := ceil(capc * mult)::int;
  if capx > 0 and new.exp > 0 then
    roomx := greatest(0, capx - _play_exp_today(new.student_id));
    if new.exp > roomx then cutx := new.exp - roomx; new.exp := roomx; note := note || ' ตัด EXP ' || cutx; end if;
  end if;
  if capc > 0 and new.coins > 0 then
    roomc := greatest(0, capc - _play_coins_today(new.student_id));
    if new.coins > roomc then cutc := new.coins - roomc; new.coins := roomc; note := note || ' ตัดเหรียญ ' || cutc; end if;
  end if;
  if cutx > 0 or cutc > 0 then
    new.reason := coalesce(new.reason, '') || ' (ครบเพดานจากการเล่นวันนี้ —' || note || ')';
    perform set_config('ch.play_cut', new.student_id::text || ':' || cutx || ':' || cutc, true);
  end if;
  return new;
end $$;
revoke execute on function trg_play_cap() from public, anon, authenticated;

-- สถานะในแอป: cap/coin_cap รวมตัวคูณแล้ว + boost (1 = ไม่มีโบนัส)
create or replace function play_exp_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); m numeric := _play_cap_mult(sid); cx int := _setting_int('play_daily_cap_exp', 150); cc int := _setting_int('play_daily_cap_coins', 200);
begin
  return json_build_object('cap', case when cx > 0 then ceil(cx * m)::int else 0 end, 'used', _play_exp_today(sid),
                           'coin_cap', case when cc > 0 then ceil(cc * m)::int else 0 end, 'coin_used', _play_coins_today(sid), 'boost', m);
end $$;

-- แจ้งนักเรียน: ข่าวหน้าแรก + แจ้งเตือนรายบุคคล (ครั้งเดียว)
do $$ begin
  if not exists (select 1 from bal_patch where key = 'catchup_122') then
    insert into student_notices (student_id, ref, icon, title, body)
    select id, 'catchup:2026-11', '🚀', 'เพิ่มเพดาน EXP + โบนัสไล่ตามทัน',
      'เพดาน EXP จากการเล่นเพิ่มเป็น 150 ต่อวัน และเหรียญ 200 ต่อวัน · ใครที่ EXP ตามหลังค่ากลางของห้อง จะได้เพดาน ×1.5 (ต่ำกว่า 75% ของค่ากลาง) หรือ ×2 (ต่ำกว่า 50%) อัตโนมัติ · ดูเพดานของตัวเองที่หน้ามินิเกม · ยิ่งตามหลังยิ่งไล่ทันเร็ว'
    from students on conflict (student_id, ref) do nothing;
    insert into news_posts (kind, title, summary, body, sort, active, ends_at)
    select 'news', 'โบนัสไล่ตามทัน 🚀', 'เพดาน EXP 150/วัน · คนที่ตามหลังห้องได้เพดาน ×1.5–×2',
      E'• เพดาน EXP จากการเล่นเพิ่มเป็น 150 ต่อวัน · เหรียญ 200 ต่อวัน\n• EXP ต่ำกว่า 75% ของค่ากลางห้อง → เพดาน ×1.5\n• EXP ต่ำกว่า 50% ของค่ากลางห้อง → เพดาน ×2\n• คิดอัตโนมัติทุกวัน ดูเพดานของตัวเองที่หน้ามินิเกม', 110, true, today_th() + 21
     where not exists (select 1 from news_posts where title = 'โบนัสไล่ตามทัน 🚀');
    insert into bal_patch (key) values ('catchup_122');
  end if;
end $$;
