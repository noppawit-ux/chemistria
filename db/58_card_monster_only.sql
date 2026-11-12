-- 58: การ์ดสะสมดรอปจากมอนสเตอร์เท่านั้น + โควต้าต่อวัน + รูปหลังการ์ด (v1.89)
-- • card_roll รับเฉพาะ 'battle' (ต้องมีรอบชนะมอนสเตอร์จริงที่เซิร์ฟเวอร์บันทึก) เกมอื่นไม่ดรอป
-- • โควต้าต่อวัน = card_daily_cap (ค่าเริ่ม 3 ถ้ายังเป็นค่าเดิม 5) · ใบแรกได้แน่นอน · pity ยังทำงาน
-- • กาชาไม่แถมการ์ดอีก · ครูแจกการ์ดให้นักเรียนยังทำได้ตามเดิม
create or replace function card_roll(p_token uuid, p_game text) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); used int; cap int := _setting_int('card_daily_cap', 3); pct int; card jsonb;
begin
  if p_game in ('quiz', 'match', 'spell', 'kb', 'run') then
    return json_build_object('drop', false, 'reason', 'monster_only');
  elsif p_game <> 'battle' then raise exception 'เกมนี้ไม่มีการ์ดดรอป'; end if;
  update battles set card_rolled = true where id = (select id from battles where student_id = sid and status = 'won' and play_date = today_th() and not card_rolled
      order by created_at limit 1 for update skip locked);
  if not found then return json_build_object('drop', false, 'reason', 'no_play'); end if;
  select count(*) into used from card_drops where student_id = sid and play_date = today_th() and source = 'game';
  if used >= cap then return json_build_object('drop', false, 'reason', 'cap', 'cap', cap, 'left', 0); end if;
  pct := least(90, _setting_int('card_drop_pct', 50));
  if not exists (select 1 from student_cards where student_id = sid) then pct := 100; end if;
  if random() * 100 >= pct then return json_build_object('drop', false, 'reason', 'miss', 'cap', cap, 'left', cap - used); end if;
  card := _card_draw(sid, 'game', 'battle');
  if card is null then return json_build_object('drop', false, 'reason', 'empty'); end if;
  return json_build_object('drop', true, 'card', card, 'cap', cap, 'left', cap - used - 1);
end $$;
revoke execute on function card_roll(uuid, text) from public;
grant execute on function card_roll(uuid, text) to anon, authenticated;

-- กาชาไม่แถมการ์ด (ห่อไว้เหมือนเดิม คืน cards เป็นอาร์เรย์ว่าง)
create or replace function gacha_pull(p_token uuid, p_n int default 1) returns json
language plpgsql security definer set search_path = public as $$
declare r json;
begin
  r := _gacha_pull(p_token, p_n);
  return (r::jsonb || jsonb_build_object('cards', '[]'::jsonb))::json;
end $$;
revoke execute on function gacha_pull(uuid, int) from public;
grant execute on function gacha_pull(uuid, int) to anon, authenticated;

-- ค่าเริ่มต้นใหม่ (เปลี่ยนเฉพาะที่ครูยังไม่เคยแก้)
update app_settings set value = '3'  where key = 'card_daily_cap' and value = '5';
update app_settings set value = '50' where key = 'card_drop_pct'  and value = '30';
update app_settings set value = '0'  where key = 'card_gacha_pct';

create or replace function card_album(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); res json; s students%rowtype;
begin
  select * into s from students where id = sid;
  select json_build_object('shards', s.shards, 'pity', s.card_pity, 'pity_max', _setting_int('card_pity', 4),
    'cap', _setting_int('card_daily_cap', 3), 'used', (select count(*) from card_drops where student_id = sid and play_date = today_th() and source = 'game'),
    'sets', coalesce((select json_agg(json_build_object('id', cs.id, 'title', cs.title, 'emoji', cs.emoji, 'color', cs.color,
        'reward', json_build_object('coins', cs.reward_coins, 'pulls', cs.reward_pulls, 'decor', (select d.name from decor_items d where d.id = cs.reward_decor)),
        'claimed', exists (select 1 from student_set_claims x where x.student_id = sid and x.set_id = cs.id),
        'cards', (select coalesce(json_agg(json_build_object('id', c.id, 'no', c.no, 'rarity', c.rarity, 'symbol', c.symbol, 'emoji', c.emoji,
              'own', sc.card_id is not null, 'qty', coalesce(sc.qty, 0), 'name', case when sc.card_id is not null then c.name end,
              'fact', case when sc.card_id is not null then c.fact end, 'image', case when sc.card_id is not null then c.image_url end) order by c.no), '[]'::json)
            from cards c left join student_cards sc on sc.card_id = c.id and sc.student_id = sid where c.set_id = cs.id and c.active))
        order by cs.sort, cs.title) from card_sets cs where cs.active), '[]'::json)) into res;
  return res;
end $$;
revoke execute on function card_album(uuid) from public;
grant execute on function card_album(uuid) to anon, authenticated;

insert into news_posts (kind, title, summary, body, sort, active)
select 'news', 'ปรับกติกาการ์ดสะสม: ดรอปจากมอนสเตอร์ 🐲🃏',
  'การ์ดสุ่มได้จากการ "ชนะมอนสเตอร์" เท่านั้น วันละไม่เกิน 3 ใบ · พร้อมหลังการ์ดลายใหม่!',
  'ตั้งแต่นี้ การ์ดสะสมจะสุ่มได้จากการชนะมอนสเตอร์ในโหมดต่อสู้เท่านั้น (เล่นควิซ/จับคู่/เกมอื่นและสุ่มกาชาไม่ได้การ์ดแล้ว) · จำกัดวันละ 3 ใบต่อคน · ใบแรกของทุกคนได้แน่นอน · ใบซ้ำกลายเป็นเศษธาตุเหมือนเดิม · ครูยังแจกการ์ดเป็นของขวัญได้ · และการ์ดทุกใบมีหลังการ์ดลายใหม่ตอนพลิกเปิดแล้ว!',
  5, true
where not exists (select 1 from news_posts where title like 'ปรับกติกาการ์ดสะสม%');

-- ประกาศเดิมอธิบายกติกาเก่า → ปิด แล้วใช้ประกาศใหม่แทน
update news_posts set active = false where title = 'สมุดการ์ดสะสมเปิดแล้ว! 📖🃏';
