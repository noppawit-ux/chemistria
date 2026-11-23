-- SQL 118 · เพดานเหรียญจากการเล่นต่อวัน (ต่อจาก 117)
-- ต้องรันหลัง 117 · รันซ้ำได้ · ไม่แก้ award/battle_* (ใช้ทริกเกอร์เดิมของ 117 ขยายให้ตัดเหรียญด้วย)
-- play_daily_cap_coins = 150 เหรียญ/วัน (0 = ไม่จำกัด) · นับแถวเดียวกับเพดาน EXP: มินิเกม · ต่อสู้ · ท้าดวล · ดันเจี้ยน · หีบ/ดรอป · ประลองครูบุ๊ค
-- ไม่นับ เช็คชื่อ/ส่งงาน/เควส/สอบ/ของขวัญครู/Achievement/การคืนเงิน (เหรียญติดลบไม่ถูกจำกัด)

insert into app_settings (key, value) values ('play_daily_cap_coins', '150') on conflict (key) do nothing;

create or replace function _play_coins_today(p_sid uuid) returns int
language sql stable security definer set search_path = public as $$
  select coalesce(sum(coins), 0)::int from ledger
   where student_id = p_sid and coins > 0 and (created_at at time zone 'Asia/Bangkok')::date = today_th()
     and _is_play_ledger(ref_key, reason)
$$;
revoke execute on function _play_coins_today(uuid) from public, anon, authenticated;

create or replace function trg_play_cap() returns trigger
language plpgsql security definer set search_path = public as $$
declare capx int := _setting_int('play_daily_cap_exp', 100); capc int := _setting_int('play_daily_cap_coins', 150);
        roomx int; roomc int; cutx int := 0; cutc int := 0; note text := '';
begin
  if (new.exp <= 0 and new.coins <= 0) or not _is_play_ledger(new.ref_key, new.reason) then return new; end if;
  if new.ref_key is not null and exists (select 1 from ledger where student_id = new.student_id and ref_key = new.ref_key) then return new; end if;  -- ซ้ำ: ถูกข้ามอยู่แล้ว
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

create or replace function trg_play_cap_apply() returns trigger
language plpgsql security definer set search_path = public as $$
declare v text := current_setting('ch.play_cut', true); cx int; cc int;
begin
  if coalesce(v, '') = '' or split_part(v, ':', 1) <> new.id::text then return new; end if;
  perform set_config('ch.play_cut', '', true);
  cx := coalesce(nullif(split_part(v, ':', 2), '')::int, 0);
  cc := coalesce(nullif(split_part(v, ':', 3), '')::int, 0);
  if cx > 0 and new.exp > old.exp then new.exp := greatest(old.exp, new.exp - cx); end if;
  if cc > 0 and new.coins > old.coins then new.coins := greatest(old.coins, new.coins - cc); end if;
  return new;
end $$;
drop trigger if exists play_cap_apply on students;
create trigger play_cap_apply before update of exp, coins on students for each row execute function trg_play_cap_apply();

create or replace function play_exp_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  return json_build_object('cap', _setting_int('play_daily_cap_exp', 100), 'used', _play_exp_today(sid),
                           'coin_cap', _setting_int('play_daily_cap_coins', 150), 'coin_used', _play_coins_today(sid));
end $$;
revoke execute on function trg_play_cap() from public, anon, authenticated;
revoke execute on function trg_play_cap_apply() from public, anon, authenticated;
