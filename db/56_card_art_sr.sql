-- 56: ผูกภาพการ์ด SR (ภาพวางที่ assets/cards/ — ถ้าไฟล์ยังไม่มี จะใช้หน้าการ์ด CSS แทนอัตโนมัติ)
update cards c set image_url = 'assets/cards/' || v.f
from (values ('elements', 30, 'sr-tungsten.jpg'), ('elements', 31, 'sr-platinum.jpg'),
             ('elements', 32, 'sr-gold.jpg'), ('elements', 33, 'sr-mercury.jpg'),
             ('chemists', 9, 'sr-mendeleev.jpg'), ('chemists', 10, 'sr-nobel.jpg'),
             ('chemists', 11, 'sr-pauling.jpg'), ('lab', 11, 'sr-centrifuge.jpg')) v(code, no, f)
join card_sets s on s.code = v.code
where c.set_id = s.id and c.no = v.no and c.image_url is null;
