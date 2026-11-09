-- =====================================================================
-- Chemistria · รอบที่ 79: ไอเทมระดับ Legendary (LEG) — เรทรวม 0.5% กรอบสีแดง (รันซ้ำได้)
--  · อุปกรณ์ถือ 2 ชิ้น + ชุดสวมใส่ 2 ชุด สเตตัสสูงกว่า SSR เล็กน้อย ได้จากกาชาเท่านั้น
--  · ได้ครั้งแรกของแต่ละชิ้น → แถมสิทธิ์ "แลกคะแนนจริง +2 คะแนน" (ครูอนุมัติในแท็บสิทธิพิเศษ) · ซ้ำ = คืน 100 เหรียญ
--  · เรทปรับได้ที่ app_settings.gacha_leg_rate (ค่าเริ่มต้น 0.005 = 0.5%) · ต้องรันหลัง 42–45
-- =====================================================================
insert into app_settings (key, value) values ('gacha_leg_rate', '0.005') on conflict (key) do nothing;

-- เพิ่มระดับ LEG ในตาราง
do $$ declare c record; begin
  for c in select conrelid::regclass t, conname from pg_constraint
            where contype = 'c' and conrelid in ('gacha_items'::regclass, 'decor_items'::regclass) and pg_get_constraintdef(oid) like '%SSR%' loop
    execute format('alter table %s drop constraint %I', c.t, c.conname);
  end loop;
  alter table gacha_items add constraint gacha_items_rarity_chk check (rarity in ('N','R','SR','SSR','LEG'));
  alter table decor_items add constraint decor_items_rarity_chk check (rarity in ('N','R','SR','SSR','LEG'));
  for c in select conname from pg_constraint where contype = 'c' and conrelid = 'celebrations'::regclass and pg_get_constraintdef(oid) like '%ssr%' loop
    execute format('alter table celebrations drop constraint %I', c.conname);
  end loop;
  alter table celebrations add constraint celebrations_kind_chk check (kind in ('ssr','rank','leg'));
end $$;

-- สิทธิ์แลกคะแนนจริง
insert into privileges (name, description, emoji, cost, active)
select 'แลกคะแนนจริง +2 คะแนน', 'ได้จากไอเทม Legendary — กดใช้สิทธิ์แล้วครูอนุมัติ เพิ่มคะแนนเก็บจริง 2 คะแนน', '🎓', null, true
 where not exists (select 1 from privileges where name = 'แลกคะแนนจริง +2 คะแนน');

-- ไอเทม LEG 4 ชิ้น (ภาพ: assets/items/leg_*.png · assets/chars/<คลาส>_crimson*.png)
insert into decor_items (slot, key, name, emoji, rarity, price, sort, image, st_int, st_dil, st_str, st_luk, st_coin, ability)
select v.* from (values
  ('item','img','ดาบผลึกอัคนีโลหิต','🗡️','LEG',null::int,90,'assets/items/leg_sword.png',0,1,4,2,2,'ตำนานแห่งห้องแล็บ · แลกคะแนนจริง +2 คะแนน'),
  ('item','img','คัมภีร์อะตอมโลหิต','📕','LEG',null,91,'assets/items/leg_book.png',4,1,0,2,2,'ตำนานแห่งห้องแล็บ · แลกคะแนนจริง +2 คะแนน'),
  ('outfit','crimsonknight','ชุดอัศวินมังกรโลหิต','🐉','LEG',null,90,null,1,2,3,1,3,'ตำนานแห่งห้องแล็บ · แลกคะแนนจริง +2 คะแนน'),
  ('outfit','crimsonmage','ชุดราชันจอมเวทสีชาด','🔴','LEG',null,91,null,3,2,1,1,3,'ตำนานแห่งห้องแล็บ · แลกคะแนนจริง +2 คะแนน')
) v(slot,key,name,emoji,rarity,price,sort,image,st_int,st_dil,st_str,st_luk,st_coin,ability)
where not exists (select 1 from decor_items d where d.slot = v.slot and d.name = v.name);

insert into gacha_items (name, rarity, kind, value, emoji, weight, decor_id)
select d.name, 'LEG', 'decor', 0, d.emoji, 1, d.id from decor_items d
 where d.rarity = 'LEG' and not exists (select 1 from gacha_items g where g.decor_id = d.id);

-- สุ่ม: ทอย LEG ก่อนด้วยเรทคงที่ (ไม่ขึ้นกับจำนวนไอเทมอื่นในตู้) แล้วค่อยสุ่มปกติ (ไม่รวม LEG)
create or replace function _gacha_pick_luk(p_high boolean, p_luk int) returns gacha_items
language plpgsql security definer set search_path = public as $$
declare total numeric; r numeric; acc numeric := 0; it gacha_items%rowtype; last_it gacha_items%rowtype; w numeric;
        rate numeric := least(greatest(coalesce((select value::numeric from app_settings where key = 'gacha_leg_rate'), 0.005), 0), 1); n int;
begin
  select count(*) into n from gacha_items where active and rarity = 'LEG';
  if n > 0 and random() < rate then
    select * into it from gacha_items where active and rarity = 'LEG' order by random() limit 1;
    return it;
  end if;
  select coalesce(sum(weight * case when rarity in ('SR','SSR') then 1 + 0.03 * greatest(p_luk, 0) else 1 end), 0) into total
    from gacha_items where active and rarity <> 'LEG' and (not p_high or rarity in ('SR','SSR'));
  if total = 0 then raise exception 'ยังไม่มีไอเทมในกาชา'; end if;
  r := random() * total;
  for it in select * from gacha_items where active and rarity <> 'LEG' and (not p_high or rarity in ('SR','SSR')) order by id loop
    w := it.weight * case when it.rarity in ('SR','SSR') then 1 + 0.03 * greatest(p_luk, 0) else 1 end;
    acc := acc + w; last_it := it;
    if r < acc then return it; end if;
  end loop;
  return last_it;
end $$;
revoke execute on function _gacha_pick_luk(boolean, int) from public, anon, authenticated;

-- สุ่มกาชา (ฉบับ LEG: รีเซ็ตการันตี · ซ้ำคืน 100 เหรียญ · ได้ครั้งแรกแถมสิทธิ์แลกคะแนน)
create or replace function gacha_pull(p_token uuid, p_n int default 1) returns json
language plpgsql security definer set search_path = public as $$
declare
  sid uuid := _sid(p_token); s students%rowtype;
  unit int := coalesce((select value::int from app_settings where key = 'gacha_cost'), 30);
  pity_max int := coalesce((select value::int from app_settings where key = 'pity_max'), 10);
  cost int; i int; it gacha_items%rowtype; high boolean; res jsonb := '[]'::jsonb; refund int := 0; free boolean := false; first_leg boolean; leg_priv uuid := (select id from privileges where name = 'แลกคะแนนจริง +2 คะแนน' and active limit 1);
begin
  if student_class(sid) = 'seeker' then pity_max := greatest(3, pity_max - 2); end if;
  if p_n not in (1, 10) then raise exception 'จำนวนครั้งไม่ถูกต้อง'; end if;
  select * into s from students where id = sid for update;
  if p_n = 1 and s.free_pulls > 0 then
    free := true; cost := 0;
    update students set free_pulls = free_pulls - 1 where id = sid;
  else
    cost := unit * p_n;
    if s.coins < cost then raise exception 'เหรียญไม่พอ (ต้องใช้ % เหรียญ)', cost; end if;
    update students set coins = coins - cost where id = sid;
  end if;
  for i in 1..p_n loop
    select * into s from students where id = sid;
    high := s.gacha_pity + 1 >= pity_max;
    it := _gacha_pick_luk(high, coalesce((_stats(sid)->'luk'->>'total')::int, 0));
    first_leg := false;
    if it.rarity in ('SR','SSR','LEG') then
      update students set gacha_pity = 0 where id = sid;
    else
      update students set gacha_pity = gacha_pity + 1 where id = sid;
    end if;
    insert into gacha_pulls (student_id, item_id, cost) values (sid, it.id, case when free then 0 else unit end);
    if it.kind = 'coins' then
      perform award(sid, 0, it.value, 'กาชา: ' || it.name, null);
    elsif it.kind = 'exp' then
      perform award(sid, it.value, 0, 'กาชา: ' || it.name, null);
    elsif it.kind = 'cosmetic' then
      insert into inventory (student_id, item_id) values (sid, it.id)
      on conflict (student_id, item_id) do update set qty = inventory.qty + 1;
    elsif it.kind = 'privilege' and it.privilege_id is not null then
      insert into redemptions (student_id, privilege_id, source) values (sid, it.privilege_id, 'gacha');
    elsif it.kind = 'decor' and it.decor_id is not null then
      if exists (select 1 from student_decor where student_id = sid and item_id = it.decor_id) then
        refund := case it.rarity when 'LEG' then 100 when 'SSR' then 40 when 'SR' then 20 when 'R' then 10 else 5 end;
        perform award(sid, 0, refund, 'ไอเทมตกแต่งซ้ำ: ' || it.name, null);
      else
        insert into student_decor (student_id, item_id, source) values (sid, it.decor_id, 'gacha');
        refund := 0;
        if it.rarity = 'LEG' and leg_priv is not null then   -- ได้ไอเทมตำนานครั้งแรก: แถมสิทธิ์แลกคะแนนจริง 2 คะแนน
          insert into redemptions (student_id, privilege_id, source) values (sid, leg_priv, 'gacha');
        end if;
      end if;
    end if;
    res := res || jsonb_build_object('name', it.name, 'rarity', it.rarity, 'kind', it.kind,
                                     'value', it.value, 'emoji', it.emoji, 'image', it.image_url,
                                     'dup_refund', case when it.kind = 'decor' then refund else 0 end);
  end loop;
  perform check_achievements(sid);
  select * into s from students where id = sid;
  return json_build_object('items', res, 'coins', s.coins, 'exp', s.exp, 'pity', s.gacha_pity, 'used_free', free, 'free_pulls', s.free_pulls);
end $$;
revoke execute on function gacha_pull(uuid, int) from public;
grant execute on function gacha_pull(uuid, int) to anon, authenticated;

-- ประกาศแสดงความยินดี: ได้ SSR / LEG
create or replace function trg_cel_ssr() returns trigger
language plpgsql security definer set search_path = public as $$
declare it gacha_items%rowtype; cid uuid;
begin
  if _setting_int('celebrate_enabled', 1) = 0 then return new; end if;
  select * into it from gacha_items where id = new.item_id;
  if found and it.rarity in ('SSR','LEG') then
    select class_id into cid from students where id = new.student_id;
    insert into celebrations (class_id, student_id, kind, title, emoji, image)
    values (cid, new.student_id, case when it.rarity = 'LEG' then 'leg' else 'ssr' end, it.name, it.emoji, it.image_url);
  end if;
  return new;
end $$;
revoke execute on function trg_cel_ssr() from public, anon, authenticated;

-- ประกาศข่าว/อีเว้นท์
insert into news_posts (kind, title, summary, body, image, starts_at, ends_at, sort, active)
select 'event', 'เปิดตู้ตำนาน! Legendary 0.5% 🔴', 'ของระดับตำนานกรอบสีแดง อุปกรณ์ 2 + ชุด 2 สเตตัสสูงกว่า SSR เล็กน้อย แลกคะแนนจริงได้ 2 คะแนน', E'🔴 เปิดตู้ตำนาน! ไอเทมระดับ LEGENDARY\n\n• โอกาสออกรวม 0.5% ต่อการสุ่ม 1 ครั้ง (กรอบสีแดง)\n• อุปกรณ์ในตำนาน 2 ชิ้น: 🗡️ ดาบผลึกอัคนีโลหิต · 📕 คัมภีร์อะตอมโลหิต\n• ชุดสวมใส่ในตำนาน 2 ชุด: 🐉 ชุดอัศวินมังกรโลหิต · 🔴 ชุดราชันจอมเวทสีชาด\n• เพิ่มสเตตัสสูงกว่า SSR เล็กน้อยกว่าไอเทมทุกระดับ (ปัญญา/ขยัน/พลัง/โชค + โบนัสเหรียญ)\n• ได้ครั้งแรกของแต่ละชิ้น แถมสิทธิ์ "แลกคะแนนจริง +2 คะแนน" ให้กดขอครูในเมนู 🎟️ สิทธิพิเศษ\n• ซ้ำจะคืนเหรียญ 100 🪙\n\nไปสุ่มที่เมนู 🎰 กาชา ได้เลย — ขอให้โชคดี!', 'assets/news/legendary.jpg', today_th(), today_th() + 30, 1, true
 where not exists (select 1 from news_posts where title like 'เปิดตู้ตำนาน!%');
