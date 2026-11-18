-- 94: ย่อยการ์ดซ้ำเป็นเศษธาตุ → หลอมการ์ดใหม่ (รันซ้ำได้)
--  · การ์ดซ้ำไม่แปลงเป็นเศษอัตโนมัติอีกต่อไป: เก็บเป็น "ใบสำรอง" นักเรียนเลือกย่อยเอง (เก็บไว้แลก/แจกไม่ได้ ย่อยได้เท่านั้น)
--  · ย่อย: N=1 · R=3 · SR=10 · SSR=30 เศษต่อใบ (ตรงกับค่าเดิมของ _card_shards)
--  · หลอม: เลือกระดับ แล้วได้การ์ด "ใบที่ยังไม่มี" แบบสุ่มในระดับนั้นแน่นอน · ราคา N=5 R=12 SR=40 SSR=100 (ปรับได้ใน app_settings: forge_n/forge_r/forge_sr/forge_ssr)
--  · ใบที่ได้เคยถูกแปลงเป็นเศษไปแล้วก่อนหน้านี้ ไม่ถูกนับเป็นใบสำรอง (กันได้เศษซ้ำ)
alter table student_cards add column if not exists paid int not null default 0;

do $$ begin
  if not exists (select 1 from app_settings where key = 'card_forge_migrated') then
    update student_cards sc set paid = least(greatest(sc.qty - 1, 0), (select count(*) from card_drops d
        where d.student_id = sc.student_id and d.card_id = sc.card_id and d.is_new = false and d.shards > 0));
    insert into app_settings (key, value) values ('card_forge_migrated', '1');
  end if;
end $$;

insert into app_settings (key, value) values ('forge_n', '5'), ('forge_r', '12'), ('forge_sr', '40'), ('forge_ssr', '100') on conflict (key) do nothing;

alter table card_drops drop constraint if exists card_drops_source_check;
alter table card_drops add constraint card_drops_source_check check (source in ('game', 'gacha', 'gift', 'forge'));

create or replace function _forge_cost(p_rarity text) returns int language sql stable security definer set search_path = public as $$
  select case p_rarity when 'N' then _setting_int('forge_n', 5) when 'R' then _setting_int('forge_r', 12)
                       when 'SR' then _setting_int('forge_sr', 40) when 'SSR' then _setting_int('forge_ssr', 100) end $$;
revoke execute on function _forge_cost(text) from public, anon, authenticated;

-- มอบการ์ด: ซ้ำ → เป็นใบสำรอง (ไม่ให้เศษอัตโนมัติ) · ครบชุด → รางวัล (ครั้งเดียวต่อชุด)
create or replace function _card_grant(p_sid uuid, p_card uuid, p_source text, p_game text default null) returns jsonb
language plpgsql security definer set search_path = public as $$
declare c cards%rowtype; st card_sets%rowtype; isnew boolean; done jsonb := null; tot int; own int;
begin
  select * into c from cards where id = p_card;
  if c.id is null then raise exception 'ไม่พบการ์ด'; end if;
  select * into st from card_sets where id = c.set_id;
  insert into student_cards (student_id, card_id) values (p_sid, p_card)
    on conflict (student_id, card_id) do update set qty = student_cards.qty + 1 returning (xmax = 0) into isnew;
  if isnew then update students set card_pity = 0 where id = p_sid;
  else update students set card_pity = card_pity + 1 where id = p_sid; end if;
  insert into card_drops (student_id, card_id, source, game, is_new, shards) values (p_sid, p_card, p_source, p_game, isnew, 0);
  if isnew then
    select count(*) into tot from cards where set_id = c.set_id and active;
    select count(*) into own from student_cards sc join cards x on x.id = sc.card_id where sc.student_id = p_sid and x.set_id = c.set_id and x.active;
    if tot > 0 and own >= tot and not exists (select 1 from student_set_claims where student_id = p_sid and set_id = c.set_id) then
      insert into student_set_claims (student_id, set_id) values (p_sid, c.set_id);
      if st.reward_coins > 0 then perform award(p_sid, 0, st.reward_coins, '📖 สะสมการ์ดครบชุด ' || st.title, 'cardset:' || c.set_id); end if;
      if st.reward_pulls > 0 then update students set free_pulls = free_pulls + st.reward_pulls where id = p_sid; end if;
      if st.reward_decor is not null then insert into student_decor (student_id, item_id, source) values (p_sid, st.reward_decor, 'teacher') on conflict do nothing; end if;
      done := jsonb_build_object('title', st.title, 'coins', st.reward_coins, 'pulls', st.reward_pulls);
    end if;
  end if;
  return jsonb_build_object('id', c.id, 'name', c.name, 'symbol', c.symbol, 'emoji', c.emoji, 'rarity', c.rarity, 'fact', c.fact,
                            'image', c.image_url, 'set', st.title, 'set_emoji', st.emoji, 'is_new', isnew, 'shards', 0, 'spare', not isnew, 'set_done', done);
end $$;
revoke execute on function _card_grant(uuid, uuid, text, text) from public, anon, authenticated;

-- ย่อยใบสำรองเป็นเศษธาตุ: p_card = การ์ดใบนั้น (p_n = จำนวน, ว่าง = ทุกใบสำรอง) · p_card ว่าง = ทุกใบสำรองของทุกการ์ด
create or replace function card_dismantle(p_token uuid, p_card uuid default null, p_n int default null) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); r record; sp int; take int; gain int := 0; cnt int := 0; sh int;
begin
  perform 1 from students where id = sid for update;
  for r in select sc.card_id, sc.qty, sc.paid, c.rarity from student_cards sc join cards c on c.id = sc.card_id
            where sc.student_id = sid and (p_card is null or sc.card_id = p_card) order by c.rarity for update of sc loop
    sp := r.qty - 1 - r.paid;
    if sp <= 0 then continue; end if;
    take := case when p_card is null or p_n is null then sp else least(sp, greatest(p_n, 0)) end;
    if take <= 0 then continue; end if;
    update student_cards set qty = qty - take where student_id = sid and card_id = r.card_id;
    gain := gain + take * _card_shards(r.rarity); cnt := cnt + take;
  end loop;
  if cnt = 0 then raise exception 'ไม่มีการ์ดสำรองให้ย่อย'; end if;
  update students set shards = shards + gain where id = sid returning shards into sh;
  return json_build_object('cards', cnt, 'gained', gain, 'shards', sh);
end $$;
revoke execute on function card_dismantle(uuid, uuid, int) from public;
grant execute on function card_dismantle(uuid, uuid, int) to anon, authenticated;

-- หลอมการ์ดใหม่: เลือกระดับ → ได้ใบที่ยังไม่มีแบบสุ่มในระดับนั้น
create or replace function card_forge(p_token uuid, p_rarity text) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cost int; cid uuid; sh int; res jsonb;
begin
  if p_rarity not in ('N', 'R', 'SR', 'SSR') then raise exception 'ระดับการ์ดไม่ถูกต้อง'; end if;
  cost := _forge_cost(p_rarity);
  select shards into sh from students where id = sid for update;
  if sh < cost then raise exception 'เศษธาตุไม่พอ (ต้องใช้ % มี %)', cost, sh; end if;
  select c.id into cid from cards c join card_sets s on s.id = c.set_id
   where c.active and s.active and c.rarity = p_rarity
     and not exists (select 1 from student_cards x where x.student_id = sid and x.card_id = c.id)
   order by random() limit 1;
  if cid is null then raise exception 'คุณมีการ์ดระดับนี้ครบทุกใบแล้ว'; end if;
  update students set shards = shards - cost where id = sid returning shards into sh;
  res := _card_grant(sid, cid, 'forge');
  return json_build_object('card', res, 'cost', cost, 'shards', sh);
end $$;
revoke execute on function card_forge(uuid, text) from public;
grant execute on function card_forge(uuid, text) to anon, authenticated;

create or replace function card_album(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); res json; s students%rowtype;
begin
  select * into s from students where id = sid;
  select json_build_object('shards', s.shards, 'pity', s.card_pity, 'pity_max', _setting_int('card_pity', 4),
    'cap', _setting_int('card_daily_cap', 3), 'used', (select count(*) from card_drops where student_id = sid and play_date = today_th() and source = 'game'),
    'spare_total', (select coalesce(sum(greatest(sc.qty - 1 - sc.paid, 0)), 0) from student_cards sc where sc.student_id = sid),
    'spare_shards', (select coalesce(sum(greatest(sc.qty - 1 - sc.paid, 0) * _card_shards(c.rarity)), 0) from student_cards sc join cards c on c.id = sc.card_id where sc.student_id = sid),
    'forge', (select json_agg(json_build_object('rarity', r.k, 'cost', _forge_cost(r.k),
        'left', (select count(*) from cards c join card_sets cs on cs.id = c.set_id where c.active and cs.active and c.rarity = r.k
                   and not exists (select 1 from student_cards x where x.student_id = sid and x.card_id = c.id))) order by r.o)
        from (values ('N', 1), ('R', 2), ('SR', 3), ('SSR', 4)) r(k, o)),
    'sets', coalesce((select json_agg(json_build_object('id', cs.id, 'title', cs.title, 'emoji', cs.emoji, 'color', cs.color,
        'reward', json_build_object('coins', cs.reward_coins, 'pulls', cs.reward_pulls, 'decor', (select d.name from decor_items d where d.id = cs.reward_decor)),
        'claimed', exists (select 1 from student_set_claims x where x.student_id = sid and x.set_id = cs.id),
        'cards', (select coalesce(json_agg(json_build_object('id', c.id, 'no', c.no, 'rarity', c.rarity, 'symbol', c.symbol, 'emoji', c.emoji,
              'own', sc.card_id is not null, 'qty', coalesce(sc.qty, 0), 'spare', greatest(coalesce(sc.qty, 0) - 1 - coalesce(sc.paid, 0), 0),
              'name', case when sc.card_id is not null then c.name end,
              'fact', case when sc.card_id is not null then c.fact end, 'image', case when sc.card_id is not null then c.image_url end) order by c.no), '[]'::json)
            from cards c left join student_cards sc on sc.card_id = c.id and sc.student_id = sid where c.set_id = cs.id and c.active))
        order by cs.sort, cs.title) from card_sets cs where cs.active), '[]'::json)) into res;
  return res;
end $$;
revoke execute on function card_album(uuid) from public;
grant execute on function card_album(uuid) to anon, authenticated;
