-- Chemistria · รอบที่ 6: ภาพหมวก/เครื่องประดับ/สัตว์เลี้ยงแบบภาพวาด · รันซ้ำได้ (ต้องรันหลัง 06)
update decor_items set image = 'assets/hats/' || v.f || '.png' from (values
  ('โบว์ชมพู','bow'),('หมวกแก๊ป','cap'),('หมวกบัณฑิต','grad'),('หมวกทรงสูง','tophat'),('มงกุฎทอง','crown')) v(n,f)
 where decor_items.slot = 'hat' and decor_items.name = v.n;
update decor_items set image = 'assets/pets/' || v.f || '.png' from (values
  ('น้องกบ','frog'),('น้องแมว','cat'),('น้องหมา','dog'),('น้องจิ้งจอก','fox'),('มังกรน้อย','dragon')) v(n,f)
 where decor_items.slot = 'pet' and decor_items.name = v.n;

insert into decor_items (slot, key, name, emoji, rarity, price, sort, image)
select 'hat','emoji','แว่นนิรภัยแล็บ','🥽','R',150,6,'assets/hats/goggles.png'
 where not exists (select 1 from decor_items where slot='hat' and name='แว่นนิรภัยแล็บ');
insert into decor_items (slot, key, name, emoji, rarity, price, sort, image)
select 'pet','emoji','น้องฮูกนักวิชาการ','🦉','R',200,6,'assets/pets/owl.png'
 where not exists (select 1 from decor_items where slot='pet' and name='น้องฮูกนักวิชาการ');
