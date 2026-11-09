-- =====================================================================
-- 50: เรท Legendary แบบไต่ระดับ — ครั้งแรก 0.01% ยิ่งสุ่มไม่ได้ยิ่งเพิ่ม สูงสุด 0.5% (รันซ้ำได้ · ต้องรันหลัง 46)
--  ตั้งค่า app_settings: gacha_leg_rate_min (0.0001 = 0.01%) · gacha_leg_rate (0.005 = 0.5% สูงสุด) · gacha_leg_ramp (100 = สุ่มกี่ครั้งถึงเรทสูงสุด)
--  ตัวนับ students.leg_pulls: +1 ทุกครั้งที่สุ่ม · รีเซ็ตเป็น 0 เมื่อได้ LEG (กลับไปเริ่มที่เรทต่ำ)
-- =====================================================================
alter table students add column if not exists leg_pulls int not null default 0;
insert into app_settings (key, value) values ('gacha_leg_rate_min', '0.0001'), ('gacha_leg_ramp', '100') on conflict (key) do nothing;

create or replace function _leg_rate(p_sid uuid) returns numeric
language plpgsql security definer set search_path = public as $$
declare mx numeric := least(greatest(coalesce((select value::numeric from app_settings where key = 'gacha_leg_rate'), 0.005), 0), 1);
        mn numeric := least(greatest(coalesce((select value::numeric from app_settings where key = 'gacha_leg_rate_min'), 0.0001), 0), 1);
        ramp int := greatest(coalesce(_setting_int('gacha_leg_ramp', 100), 100), 2);
        n int := coalesce((select leg_pulls from students where id = p_sid), 0);
begin
  mn := least(mn, mx);
  return mn + (mx - mn) * least(n, ramp - 1)::numeric / (ramp - 1);
end $$;
revoke execute on function _leg_rate(uuid) from public, anon, authenticated;

-- สุ่มของ (ใช้เรท LEG ตามจำนวนครั้งที่สุ่มสะสมของนักเรียน)
create or replace function _gacha_pick_luk(p_high boolean, p_luk int, p_sid uuid) returns gacha_items
language plpgsql security definer set search_path = public as $$
declare total numeric; r numeric; acc numeric := 0; it gacha_items%rowtype; last_it gacha_items%rowtype; w numeric;
        rate numeric := _leg_rate(p_sid); n int;
        k numeric := 0.03 * _setting_int('stat_effect_pct', 50) / 100.0;
begin
  select count(*) into n from gacha_items where active and rarity = 'LEG';
  if n > 0 and random() < rate then
    select * into it from gacha_items where active and rarity = 'LEG' order by random() limit 1;
    return it;
  end if;
  select coalesce(sum(weight * case when rarity in ('SR','SSR') then 1 + k * greatest(p_luk, 0) else 1 end), 0) into total
    from gacha_items where active and rarity <> 'LEG' and (not p_high or rarity in ('SR','SSR'));
  if total = 0 then raise exception 'ยังไม่มีไอเทมในกาชา'; end if;
  r := random() * total;
  for it in select * from gacha_items where active and rarity <> 'LEG' and (not p_high or rarity in ('SR','SSR')) order by id loop
    w := it.weight * case when it.rarity in ('SR','SSR') then 1 + k * greatest(p_luk, 0) else 1 end;
    acc := acc + w; last_it := it;
    if r < acc then return it; end if;
  end loop;
  return last_it;
end $$;
revoke execute on function _gacha_pick_luk(boolean, int, uuid) from public, anon, authenticated;

-- gacha_pull: ส่ง sid เข้าไปคำนวณเรท + อัปเดตตัวนับ
do $$ declare d text; n text; begin
  d := pg_get_functiondef('gacha_pull(uuid,int)'::regprocedure);
  if d not like '%leg_pulls%' then
    n := replace(d, '_gacha_pick_luk(high, coalesce((_stats(sid)->''luk''->>''total'')::int, 0))', '_gacha_pick_luk(high, coalesce((_stats(sid)->''luk''->>''total'')::int, 0), sid)');
    n := replace(n, 'first_leg := false;', 'first_leg := false;' || chr(10) || '    update students set leg_pulls = case when it.rarity = ''LEG'' then 0 else leg_pulls + 1 end where id = sid;');
    if n = d or n not like '%leg_pulls%' or n not like '%, sid)%' then raise exception 'gacha_pull: ไม่พบข้อความที่ต้องแก้ (ต้องรัน 46 ก่อน)'; end if;
    execute n;
  end if;
end $$;
drop function if exists _gacha_pick_luk(boolean, int);

-- อัปเดตข้อความประกาศ
update news_posts set summary = 'ของระดับตำนานกรอบสีแดง อุปกรณ์ 2 + ชุด 2 · เรทเริ่ม 0.01% ยิ่งสุ่มยิ่งเพิ่มสูงสุด 0.5%',
  body = replace(body, '• โอกาสออกรวม 0.5% ต่อการสุ่ม 1 ครั้ง (กรอบสีแดง)', '• โอกาสออกเริ่มที่ 0.01% แล้วยิ่งสุ่มยิ่งเพิ่มขึ้นจนสูงสุด 0.5% ต่อครั้ง (ได้แล้วเริ่มนับใหม่) · กรอบสีแดง')
 where title like 'เปิดตู้ตำนาน!%';
