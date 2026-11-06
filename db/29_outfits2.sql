-- 29: ชุดตัวละครใหม่ 2 แบบ (ชุดฮาซ์แมท / ชุดซามูไรเคมี) ครบ 5 คลาส · รันซ้ำได้
-- ภาพ: web/assets/chars/<คลาส>_<hazmat|samurai>.png
insert into decor_items (slot, key, name, emoji, rarity, price, sort, st_int, st_dil, st_str, st_luk, st_coin, ability)
select v.* from (values
  ('outfit','hazmat','ชุดป้องกันสารเคมี (ฮาซ์แมท)','☣️','R',300,6,1,1,1,0,0,'ปลอดภัยไว้ก่อน ทำแล็บได้มั่นใจ'),
  ('outfit','samurai','ชุดซามูไรนักเคมี','⚔️','SSR',null,7,1,1,2,1,0,'เกราะทองแห่งห้องแล็บ')
) v(slot,key,name,emoji,rarity,price,sort,st_int,st_dil,st_str,st_luk,st_coin,ability)
where not exists (select 1 from decor_items d where d.slot = v.slot and d.key = v.key);

insert into gacha_items (name, rarity, kind, value, emoji, weight, decor_id)
select d.name, d.rarity, 'decor', 0, d.emoji, 1, d.id
  from decor_items d
 where d.slot='outfit' and d.key = 'samurai'
   and not exists (select 1 from gacha_items g where g.decor_id = d.id);
