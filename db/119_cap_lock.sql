-- SQL 119 · ปิดช่องโหว่เพดานต่อวัน: ส่งคำขอพร้อมกันหลายคำขอ (race) แล้วได้ EXP/เหรียญเกินเพดาน
-- ต้องรันหลัง 118 · รันซ้ำได้ · ล็อกต่อนักเรียนก่อนนับยอดวันนี้ (advisory lock จนจบทรานแซกชัน)
-- ทดสอบก่อนแก้: ส่ง award 2 คำขอพร้อมกัน (80/80) ได้ 160/160 ทั้งที่เพดาน 100/150 → หลังแก้ได้ 100/150

create or replace function trg_play_cap() returns trigger
language plpgsql security definer set search_path = public as $$
declare capx int := _setting_int('play_daily_cap_exp', 100); capc int := _setting_int('play_daily_cap_coins', 150);
        roomx int; roomc int; cutx int := 0; cutc int := 0; note text := '';
begin
  if (new.exp <= 0 and new.coins <= 0) or not _is_play_ledger(new.ref_key, new.reason) then return new; end if;
  if capx <= 0 and capc <= 0 then return new; end if;
  perform pg_advisory_xact_lock(hashtextextended('play_cap:' || new.student_id::text, 0));   -- คิวต่อคน: คำขอที่มาพร้อมกันรอกัน แล้วนับยอดใหม่
  if new.ref_key is not null and exists (select 1 from ledger where student_id = new.student_id and ref_key = new.ref_key) then return new; end if;
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
