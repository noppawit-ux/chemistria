-- =====================================================================
-- 91: ช่องอุปกรณ์ใหม่ "สร้อย" (neck) และ "แหวน" (ring) + ไอเทม 13 ชิ้น (แหวน 6 · สร้อย 7) (รันซ้ำได้ · ต้องรัน 81 ก่อน)
--  แหวน = เพิ่มพลังโจมตี (+สเตตัสพลังโจมตี) · สร้อย = เพิ่มป้องกัน/HP (+สเตตัสโชค) · มีธาตุตามสีพลอย/ลูกปัด · ขายในร้านค้าด้วยเหรียญ
--  ภาพ: assets/px/ring_*.png, neck_*.png (Shikashi's Fantasy Icons — ดัดแปลงสีพลอย/ลูกปัด · ดูเครดิตใน assets/CREDITS.md)
-- =====================================================================
alter table decor_items drop constraint if exists decor_items_slot_check;
alter table decor_items add constraint decor_items_slot_check
  check (slot in ('frame','bg','hat','pet','title','outfit','fx','item','neck','ring'));

create or replace function equip_decor(p_token uuid, p_slot text, p_item uuid) returns void
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  if p_slot not in ('frame','bg','hat','pet','title','outfit','fx','item','neck','ring') then raise exception 'ช่องไม่ถูกต้อง'; end if;
  if p_item is null then
    update students set decor = decor - p_slot where id = sid;
    return;
  end if;
  if not exists (select 1 from student_decor sd join decor_items d on d.id = sd.item_id
                  where sd.student_id = sid and sd.item_id = p_item and d.slot = p_slot) then
    raise exception 'ยังไม่มีไอเทมนี้';
  end if;
  update students set decor = decor || jsonb_build_object(p_slot, p_item::text) where id = sid;
end $$;

create or replace function _gear(p_sid uuid) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare sc numeric := _setting_int('gear_fx_pct', 100) / 100.0; a numeric := 0; d numeric := 0; h numeric := 0; el jsonb := '{}'::jsonb; parts jsonb := '[]'::jsonb; r record;
begin
  for r in
    select 'item' src, di.name, di.emoji, di.element el,
           di.fx_atk * (1 + 0.15 * (coalesce(sd.lvl, 1) - 1)) fa, di.fx_def * (1 + 0.15 * (coalesce(sd.lvl, 1) - 1)) fd, di.fx_hp * (1 + 0.15 * (coalesce(sd.lvl, 1) - 1)) fh
      from students s cross join lateral jsonb_each_text(s.decor) e
      join decor_items di on di.id = e.value::uuid and di.slot = e.key and di.slot in ('hat', 'outfit', 'item', 'fx', 'pet', 'neck', 'ring')
      left join student_decor sd on sd.student_id = s.id and sd.item_id = di.id
     where s.id = p_sid
    union all
    select 'card', c.name, c.emoji, c.element, (case when c.fx_kind = 'atk' then c.fx_pct else 0 end)::numeric, (case when c.fx_kind = 'def' then c.fx_pct else 0 end)::numeric,
           (case when c.fx_kind = 'hp' then c.fx_pct else 0 end)::numeric
      from student_card_slots sl join cards c on c.id = sl.card_id and c.active where sl.student_id = p_sid
  loop
    a := a + r.fa; d := d + r.fd; h := h + r.fh;
    if r.el is not null then el := jsonb_set(el, array[r.el], to_jsonb(coalesce((el->>r.el)::int, 0) + 1)); end if;
    parts := parts || jsonb_build_object('src', r.src, 'name', r.name, 'emoji', r.emoji, 'el', r.el);
  end loop;
  return jsonb_build_object('atk', least(_setting_int('gear_cap_atk', 25), round(a * sc, 1)), 'def', least(_setting_int('gear_cap_def', 20), round(d * sc, 1)),
    'hp', least(_setting_int('gear_cap_hp', 30), round(h * sc, 1)), 'el', el, 'parts', parts);
end $$;

insert into decor_items (slot, key, name, emoji, rarity, price, sort, image, element, fx_atk, fx_def, fx_hp, st_str, st_luk, ability)
select v.slot, 'img', v.name, v.emoji, v.rarity, v.price, v.sort, v.img, v.el, v.atk, v.def, v.hp,
       case when v.slot = 'ring' then v.st else 0 end, case when v.slot = 'neck' then v.st else 0 end,
       case when v.slot = 'ring' then 'แหวน: เพิ่มพลังโจมตีตอนสู้มอนสเตอร์' else 'สร้อย: เพิ่มป้องกันและ HP ตอนสู้มอนสเตอร์' end
  from (values
    ('ring', 'แหวนทองเรียบ', '💍', 'N', 120, 50, 'assets/px/ring_gold.png', null, 1, 0, 0, 1),
    ('ring', 'แหวนเพชรสายน้ำ', '💍', 'R', 240, 51, 'assets/px/ring_water.png', 'water', 2, 0, 0, 1),
    ('ring', 'แหวนทับทิมเพลิง', '💍', 'R', 240, 52, 'assets/px/ring_fire.png', 'fire', 2, 0, 0, 1),
    ('ring', 'แหวนมรกตพงไพร', '💍', 'R', 240, 53, 'assets/px/ring_plant.png', 'plant', 2, 0, 0, 1),
    ('ring', 'แหวนโทแพซสายฟ้า', '💍', 'SR', 480, 54, 'assets/px/ring_thunder.png', 'thunder', 3, 0, 0, 2),
    ('ring', 'แหวนอเมทิสต์สารเคมี', '💍', 'SR', 480, 55, 'assets/px/ring_chem.png', 'chem', 3, 0, 0, 2),
    ('neck', 'สร้อยเขี้ยวป่า', '📿', 'N', 120, 60, 'assets/px/neck_fang.png', null, 0, 1, 1, 1),
    ('neck', 'สร้อยจี้ทองคำ', '📿', 'R', 260, 61, 'assets/px/neck_gold.png', null, 0, 1, 2, 1),
    ('neck', 'สร้อยลูกปัดเพลิง', '📿', 'R', 240, 62, 'assets/px/neck_fire.png', 'fire', 0, 1, 2, 1),
    ('neck', 'สร้อยลูกปัดสายน้ำ', '📿', 'R', 240, 63, 'assets/px/neck_water.png', 'water', 0, 1, 2, 1),
    ('neck', 'สร้อยลูกปัดพงไพร', '📿', 'R', 240, 64, 'assets/px/neck_plant.png', 'plant', 0, 1, 2, 1),
    ('neck', 'สร้อยลูกปัดสายฟ้า', '📿', 'SR', 480, 65, 'assets/px/neck_thunder.png', 'thunder', 0, 2, 3, 2),
    ('neck', 'สร้อยลูกปัดสารเคมี', '📿', 'SR', 480, 66, 'assets/px/neck_chem.png', 'chem', 0, 2, 3, 2)
  ) v(slot, name, emoji, rarity, price, sort, img, el, atk, def, hp, st)
 where not exists (select 1 from decor_items d where d.slot = v.slot and d.name = v.name);
