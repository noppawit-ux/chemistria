-- 77: คลังข้อสอบเคมีอินทรีย์ ม.6 จำนวน 300 ข้อ (v2.18) · รันซ้ำได้ (ข้อที่โจทย์ + หัวข้อซ้ำจะไม่ถูกเพิ่มอีก)
--  · ชนิด: เลือกตอบ / จริง-เท็จ / จับคู่ / ลากวาง · มีเฉลยอธิบายทุกข้อ · แยก 13 หัวข้อ
--  · แอลเคนและการเรียกชื่อ 24 · แอลคีนและแอลไคน์ 25 · อะโรมาติกไฮโดรคาร์บอน 20 · ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน 25 · แอลกอฮอล์และอีเทอร์ 25 · แอลดีไฮด์และคีโตน 23 · กรดคาร์บอกซิลิกและเอสเทอร์ 25 · เอมีนและเอไมด์ 20 · หมู่ฟังก์ชันและเฮโลแอลเคน 22 · พอลิเมอร์ 24 · คาร์โบไฮเดรต 23 · กรดอะมิโนและโปรตีน 21 · ลิพิดและกรดนิวคลีอิก 23
--  · อยู่ใน 'คลังข้อสอบ' แท็บ 📝 ข้อสอบ ครูเลือกข้อเข้าชุดสอบได้เอง

insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$สูตรทั่วไปของแอลเคนสายเปิดคือข้อใด$t$, $j${"choices": [{"t": "CnH2n"}, {"t": "CnH2n-2"}, {"t": "CnHn"}, {"t": "CnH2n+2"}], "answer": 3}$j$::jsonb, 1, $t$แอลเคนสายเปิดเป็นสารอิ่มตัว มี H = 2n+2$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$สูตรทั่วไปของแอลเคนสายเปิดคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$แอลเคนที่มีคาร์บอน 8 อะตอมมีสูตรโมเลกุลใด$t$, $j${"choices": [{"t": "C8H18"}, {"t": "C8H14"}, {"t": "C8H16"}, {"t": "C8H20"}], "answer": 0}$j$::jsonb, 1, $t$n = 8 → H = 2(8)+2 = 18$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$แอลเคนที่มีคาร์บอน 8 อะตอมมีสูตรโมเลกุลใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$แอลเคนสายตรงที่มีคาร์บอน 5 อะตอมชื่อว่าอะไร$t$, $j${"choices": [{"t": "เพนเทน"}, {"t": "เพนทีน"}, {"t": "เฮกเซน"}, {"t": "บิวเทน"}], "answer": 0}$j$::jsonb, 1, $t$C1-C5 คือ มีเทน อีเทน โพรเพน บิวเทน เพนเทน$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$แอลเคนสายตรงที่มีคาร์บอน 5 อะตอมชื่อว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$CH3CH(CH3)CH2CH3 มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "3-เมทิลบิวเทน"}, {"t": "เพนเทน"}, {"t": "2-เมทิลโพรเพน"}, {"t": "2-เมทิลบิวเทน"}], "answer": 3}$j$::jsonb, 1, $t$โซ่หลักยาว 4 C (บิวเทน) มีเมทิลที่ C2$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$CH3CH(CH3)CH2CH3 มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$(CH3)3C-CH3 มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "2-เมทิลบิวเทน"}, {"t": "1,1-ไดเมทิลโพรเพน"}, {"t": "เพนเทน"}, {"t": "2,2-ไดเมทิลโพรเพน"}], "answer": 3}$j$::jsonb, 1, $t$โซ่หลัก 3 C มีเมทิล 2 หมู่ที่ C2$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$(CH3)3C-CH3 มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$หมู่อัลคิลที่ได้จากเอทเทน (ตัด H ออก 1 อะตอม) คือข้อใด$t$, $j${"choices": [{"t": "เอทิล"}, {"t": "โพรพิล"}, {"t": "เมทิล"}, {"t": "บิวทิล"}], "answer": 0}$j$::jsonb, 1, $t$-CH2CH3 เรียกเอทิล$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$หมู่อัลคิลที่ได้จากเอทเทน (ตัด H ออก 1 อะตอม) คือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$หมู่ -CH(CH3)2 มีชื่อเรียกว่าอะไร$t$, $j${"choices": [{"t": "เอทิล"}, {"t": "ไอโซโพรพิล"}, {"t": "บิวทิล"}, {"t": "โพรพิล"}], "answer": 1}$j$::jsonb, 1, $t$หมู่โพรพิลที่ต่อที่คาร์บอนตัวกลางเรียกไอโซโพรพิล$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$หมู่ -CH(CH3)2 มีชื่อเรียกว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$แอลเคนข้อใดมีจุดเดือดสูงที่สุด (เปรียบเทียบไอโซเมอร์ C5H12)$t$, $j${"choices": [{"t": "2-เมทิลบิวเทน"}, {"t": "2,2-ไดเมทิลโพรเพน"}, {"t": "เพนเทน"}, {"t": "ทุกตัวเท่ากัน"}], "answer": 2}$j$::jsonb, 1, $t$โซ่ตรงมีพื้นที่ผิวสัมผัสมากกว่า แรงลอนดอนมากกว่า จุดเดือดสูงกว่าไอโซเมอร์ที่แตกกิ่ง$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$แอลเคนข้อใดมีจุดเดือดสูงที่สุด (เปรียบเทียบไอโซเมอร์ C5H12)$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$เหตุใดแอลเคนจึงไม่ละลายน้ำ$t$, $j${"choices": [{"t": "แอลเคนทำปฏิกิริยากับน้ำจนหมด"}, {"t": "แอลเคนมีมวลโมเลกุลน้อยเกินไป"}, {"t": "แอลเคนเป็นไอออนิก"}, {"t": "แอลเคนไม่มีขั้ว แต่น้ำมีขั้ว"}], "answer": 3}$j$::jsonb, 1, $t$สารไม่มีขั้วไม่ละลายในตัวทำละลายมีขั้ว (like dissolves like)$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$เหตุใดแอลเคนจึงไม่ละลายน้ำ$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$แอลเคนที่มีคาร์บอน 1-4 อะตอมมีสถานะใดที่อุณหภูมิห้อง$t$, $j${"choices": [{"t": "ของแข็ง"}, {"t": "แก๊ส"}, {"t": "พลาสมา"}, {"t": "ของเหลว"}], "answer": 1}$j$::jsonb, 1, $t$C1-C4 มีมวลโมเลกุลน้อย แรงลอนดอนน้อย จุดเดือดต่ำกว่าอุณหภูมิห้อง$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$แอลเคนที่มีคาร์บอน 1-4 อะตอมมีสถานะใดที่อุณหภูมิห้อง$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$เมื่อจำนวนคาร์บอนในแอลเคนสายตรงเพิ่มขึ้น จุดเดือดเปลี่ยนแปลงอย่างไร$t$, $j${"choices": [{"t": "ต่ำลง เพราะพันธะอ่อนลง"}, {"t": "สูงขึ้น เพราะแรงลอนดอนมากขึ้น"}, {"t": "ไม่เปลี่ยนแปลง"}, {"t": "ต่ำลง เพราะขั้วเพิ่มขึ้น"}], "answer": 1}$j$::jsonb, 1, $t$โมเลกุลใหญ่ขึ้นมีแรงยึดเหนี่ยวระหว่างโมเลกุลมากขึ้น$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$เมื่อจำนวนคาร์บอนในแอลเคนสายตรงเพิ่มขึ้น จุดเดือดเปลี่ยนแปลงอย่างไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$ปฏิกิริยาสำคัญของแอลเคนคือข้อใด$t$, $j${"choices": [{"t": "การเผาไหม้และการแทนที่ด้วยฮาโลเจน"}, {"t": "การหมัก"}, {"t": "การเกิดพอลิเมอร์แบบเติม"}, {"t": "การเติมไฮโดรเจน"}], "answer": 0}$j$::jsonb, 1, $t$แอลเคนอิ่มตัว ไม่ให้ปฏิกิริยาการเติม จึงเกิดแทนที่และเผาไหม้$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$ปฏิกิริยาสำคัญของแอลเคนคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$3-เมทิลเฮกเซนมีสูตรโมเลกุลใด$t$, $j${"choices": [{"t": "C8H18"}, {"t": "C7H14"}, {"t": "C7H16"}, {"t": "C6H14"}], "answer": 2}$j$::jsonb, 1, $t$โซ่หลัก 6 C + เมทิล 1 C = 7 C และเป็นแอลเคน → H = 16$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$3-เมทิลเฮกเซนมีสูตรโมเลกุลใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$2,3-ไดเมทิลบิวเทนมีไฮโดรเจนกี่อะตอม$t$, $j${"choices": [{"t": "10 อะตอม"}, {"t": "12 อะตอม"}, {"t": "14 อะตอม"}, {"t": "16 อะตอม"}], "answer": 2}$j$::jsonb, 1, $t$C ทั้งหมด 4+2 = 6 → C6H14$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$2,3-ไดเมทิลบิวเทนมีไฮโดรเจนกี่อะตอม$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$CH3CH2CH(CH3)CH2CH3 มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "3-เมทิลเพนเทน"}, {"t": "2-เมทิลเพนเทน"}, {"t": "เฮกเซน"}, {"t": "2-เอทิลบิวเทน"}], "answer": 0}$j$::jsonb, 1, $t$โซ่หลักยาว 5 C เมทิลอยู่ C3$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$CH3CH2CH(CH3)CH2CH3 มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$สูตรทั่วไปของไซโคลแอลเคนคือข้อใด$t$, $j${"choices": [{"t": "CnH2n+2"}, {"t": "CnH2n-2"}, {"t": "CnH2n"}, {"t": "CnH2n-6"}], "answer": 2}$j$::jsonb, 1, $t$การเป็นวงแหวนทำให้ H ลดลง 2 อะตอมเทียบกับแอลเคนสายเปิด$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$สูตรทั่วไปของไซโคลแอลเคนคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$ไซโคลเฮกเซนมีสูตรโมเลกุลใด$t$, $j${"choices": [{"t": "C6H14"}, {"t": "C6H10"}, {"t": "C6H12"}, {"t": "C6H6"}], "answer": 2}$j$::jsonb, 1, $t$CnH2n เมื่อ n = 6$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$ไซโคลเฮกเซนมีสูตรโมเลกุลใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$สารใดต่อไปนี้เป็นแอลเคน$t$, $j${"choices": [{"t": "C3H6"}, {"t": "C6H6"}, {"t": "C3H8"}, {"t": "C2H2"}], "answer": 2}$j$::jsonb, 1, $t$แอลเคนสายเปิดต้องเป็น CnH2n+2$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$สารใดต่อไปนี้เป็นแอลเคน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'mcq', $t$แอลเคนมีคาร์บอน 20 อะตอม จะมีไฮโดรเจนกี่อะตอม$t$, $j${"choices": [{"t": "40 อะตอม"}, {"t": "44 อะตอม"}, {"t": "42 อะตอม"}, {"t": "38 อะตอม"}], "answer": 2}$j$::jsonb, 1, $t$2(20)+2 = 42$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$แอลเคนมีคาร์บอน 20 อะตอม จะมีไฮโดรเจนกี่อะตอม$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'tf', $t$แอลเคนเป็นสารไฮโดรคาร์บอนอิ่มตัว$t$, $j${"answer": true}$j$::jsonb, 1, $t$มีเฉพาะพันธะเดี่ยว C-C และ C-H$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$แอลเคนเป็นสารไฮโดรคาร์บอนอิ่มตัว$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'tf', $t$ไซโคลแอลเคนทุกชนิดมีสูตรทั่วไป CnH2n+2$t$, $j${"answer": false}$j$::jsonb, 1, $t$ไซโคลแอลเคนมีสูตร CnH2n ส่วน CnH2n+2 เป็นของแอลเคนสายเปิด$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$ไซโคลแอลเคนทุกชนิดมีสูตรทั่วไป CnH2n+2$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'tf', $t$การเรียกชื่อ IUPAC ต้องเลือกโซ่คาร์บอนต่อเนื่องที่ยาวที่สุดเป็นโซ่หลัก$t$, $j${"answer": true}$j$::jsonb, 1, $t$เป็นหลักการข้อแรกของการเรียกชื่อ$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$การเรียกชื่อ IUPAC ต้องเลือกโซ่คาร์บอนต่อเนื่องที่ยาวที่สุดเป็นโซ่หลัก$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'tf', $t$มีเทนเป็นแอลเคนที่มีมวลโมเลกุลน้อยที่สุด$t$, $j${"answer": true}$j$::jsonb, 1, $t$CH4 มวลโมเลกุล 16$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$มีเทนเป็นแอลเคนที่มีมวลโมเลกุลน้อยที่สุด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลเคนและการเรียกชื่อ$t$, 'match', $t$จับคู่ชื่อแอลเคนกับสูตรโมเลกุล$t$, $j${"left": [{"t": "มีเทน"}, {"t": "อีเทน"}, {"t": "โพรเพน"}, {"t": "บิวเทน"}], "right": [{"t": "C2H6"}, {"t": "C3H8"}, {"t": "C5H12"}, {"t": "C4H10"}, {"t": "CH4"}], "pairs": [4, 0, 1, 3]}$j$::jsonb, 4, $t$CnH2n+2: n = 1, 2, 3, 4$t$
where not exists (select 1 from exam_questions where topic = $t$แอลเคนและการเรียกชื่อ$t$ and q = $t$จับคู่ชื่อแอลเคนกับสูตรโมเลกุล$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$สูตรทั่วไปของแอลคีนสายเปิด (มีพันธะคู่ 1 พันธะ) คือข้อใด$t$, $j${"choices": [{"t": "CnH2n"}, {"t": "CnH2n-2"}, {"t": "CnHn"}, {"t": "CnH2n+2"}], "answer": 0}$j$::jsonb, 1, $t$แอลคีน = CnH2n$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$สูตรทั่วไปของแอลคีนสายเปิด (มีพันธะคู่ 1 พันธะ) คือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$สูตรทั่วไปของแอลไคน์สายเปิด (มีพันธะสาม 1 พันธะ) คือข้อใด$t$, $j${"choices": [{"t": "CnH2n-2"}, {"t": "CnH2n-6"}, {"t": "CnH2n+2"}, {"t": "CnH2n"}], "answer": 0}$j$::jsonb, 1, $t$แอลไคน์ = CnH2n-2$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$สูตรทั่วไปของแอลไคน์สายเปิด (มีพันธะสาม 1 พันธะ) คือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$C2H4 มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "เอไทน์"}, {"t": "เอเทน"}, {"t": "เอทานอล"}, {"t": "เอทีน"}], "answer": 3}$j$::jsonb, 1, $t$เอทีน (เอทิลีน) เป็นแอลคีนที่เล็กที่สุด$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$C2H4 มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$C2H2 มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "เบนซีน"}, {"t": "เอไทน์"}, {"t": "เอเทน"}, {"t": "เอทีน"}], "answer": 1}$j$::jsonb, 1, $t$เอไทน์ (อะเซทิลีน) เป็นแอลไคน์ที่เล็กที่สุด$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$C2H2 มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$CH3CH=CH2 มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "โพรไพน์"}, {"t": "ไซโคลโพรเพน"}, {"t": "โพรเพน"}, {"t": "โพรพีน"}], "answer": 3}$j$::jsonb, 1, $t$มีพันธะคู่ 3 คาร์บอน → โพรพีน$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$CH3CH=CH2 มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$CH3C≡CH มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "โพรไพน์"}, {"t": "โพรพีน"}, {"t": "เอไทน์"}, {"t": "โพรเพน"}], "answer": 0}$j$::jsonb, 1, $t$มีพันธะสาม 3 คาร์บอน → โพรไพน์$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$CH3C≡CH มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$CH3CH=CHCH3 มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "บิวเทน"}, {"t": "2-บิวทีน"}, {"t": "1-บิวทีน"}, {"t": "2-บิวไทน์"}], "answer": 1}$j$::jsonb, 1, $t$พันธะคู่อยู่ระหว่างคาร์บอนตำแหน่งที่ 2 และ 3 ให้เลขต่ำสุด = 2$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$CH3CH=CHCH3 มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$ปฏิกิริยาเฉพาะของแอลคีนคือข้อใด$t$, $j${"choices": [{"t": "ปฏิกิริยาการแทนที่"}, {"t": "ปฏิกิริยาการเติม"}, {"t": "ปฏิกิริยาการหมัก"}, {"t": "ปฏิกิริยาสะปอนนิฟิเคชัน"}], "answer": 1}$j$::jsonb, 1, $t$พันธะ π ของ C=C ถูกเปิดออกเพื่อรับอะตอมใหม่$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$ปฏิกิริยาเฉพาะของแอลคีนคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$เติม Br2 ลงในเอทีน ได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "1,1-ไดโบรโมเอเทน"}, {"t": "เอทานอล"}, {"t": "โบรโมเอเทน"}, {"t": "1,2-ไดโบรโมเอเทน"}], "answer": 3}$j$::jsonb, 1, $t$Br ต่อเข้าที่คาร์บอนทั้งสองของพันธะคู่$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$เติม Br2 ลงในเอทีน ได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$การทดสอบสารไม่อิ่มตัวด้วยน้ำโบรมีน จะสังเกตการเปลี่ยนแปลงใด$t$, $j${"choices": [{"t": "สีส้มแดงของน้ำโบรมีนจางหายไป"}, {"t": "เกิดตะกอนสีขาว"}, {"t": "สีเปลี่ยนจากไม่มีสีเป็นน้ำเงิน"}, {"t": "เกิดฟองแก๊สมาก"}], "answer": 0}$j$::jsonb, 1, $t$Br2 ถูกใช้ไปในปฏิกิริยาการเติม สีจึงจางหาย$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$การทดสอบสารไม่อิ่มตัวด้วยน้ำโบรมีน จะสังเกตการเปลี่ยนแปลงใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$ทดสอบแอลคีนด้วยสารละลาย KMnO4 เจือจางที่เป็นเบส จะสังเกตเห็นอะไร$t$, $j${"choices": [{"t": "ไม่มีการเปลี่ยนแปลง"}, {"t": "สีม่วงจางหายไป และเกิดตะกอนสีน้ำตาล"}, {"t": "เกิดตะกอนสีขาว"}, {"t": "สารละลายเป็นสีเหลือง"}], "answer": 1}$j$::jsonb, 1, $t$MnO4- ถูกรีดิวซ์เป็น MnO2 (ตะกอนน้ำตาล)$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$ทดสอบแอลคีนด้วยสารละลาย KMnO4 เจือจางที่เป็นเบส จะสังเกตเห็นอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$การเติม H2 ลงในแอลคีนโดยใช้ Ni หรือ Pt เป็นตัวเร่ง ได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "แอลไคน์"}, {"t": "แอลกอฮอล์"}, {"t": "กรดคาร์บอกซิลิก"}, {"t": "แอลเคน"}], "answer": 3}$j$::jsonb, 1, $t$ไฮโดรจีเนชันทำให้พันธะคู่กลายเป็นพันธะเดี่ยว$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$การเติม H2 ลงในแอลคีนโดยใช้ Ni หรือ Pt เป็นตัวเร่ง ได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$เติม HBr ลงในโพรพีน ผลิตภัณฑ์หลักตามกฎของมาร์คอฟนิคอฟคือข้อใด$t$, $j${"choices": [{"t": "โพรเพน"}, {"t": "1,2-ไดโบรโมโพรเพน"}, {"t": "1-โบรโมโพรเพน"}, {"t": "2-โบรโมโพรเพน"}], "answer": 3}$j$::jsonb, 1, $t$H เข้าที่คาร์บอนที่มี H มากกว่า Br จึงไปอยู่ที่ C2$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$เติม HBr ลงในโพรพีน ผลิตภัณฑ์หลักตามกฎของมาร์คอฟนิคอฟคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$เติมน้ำ (H2O) ในสภาวะกรดลงในเอทีน ได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "เอทานัล"}, {"t": "กรดเอทาโนอิก"}, {"t": "เอทานอล"}, {"t": "เอทิลีนไกลคอล"}], "answer": 2}$j$::jsonb, 1, $t$ไฮเดรชันของแอลคีนให้แอลกอฮอล์$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$เติมน้ำ (H2O) ในสภาวะกรดลงในเอทีน ได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$เติม H2 ให้ครบ (มากเกินพอ) ลงในเอไทน์ ได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "เอทานอล"}, {"t": "เบนซีน"}, {"t": "เอเทน"}, {"t": "เอทีน"}], "answer": 2}$j$::jsonb, 1, $t$พันธะสามรับ H2 2 โมล กลายเป็นพันธะเดี่ยว$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$เติม H2 ให้ครบ (มากเกินพอ) ลงในเอไทน์ ได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$พันธะระหว่างคาร์บอนในเอไทน์ประกอบด้วยพันธะชนิดใดบ้าง$t$, $j${"choices": [{"t": "ซิกมา 3 พันธะ"}, {"t": "พาย 3 พันธะ"}, {"t": "ซิกมา 2 พันธะ และพาย 1 พันธะ"}, {"t": "ซิกมา 1 พันธะ และพาย 2 พันธะ"}], "answer": 3}$j$::jsonb, 1, $t$พันธะสามคือ 1σ + 2π$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$พันธะระหว่างคาร์บอนในเอไทน์ประกอบด้วยพันธะชนิดใดบ้าง$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$มุมพันธะรอบคาร์บอนของเอทีนมีค่าประมาณเท่าใด$t$, $j${"choices": [{"t": "90 องศา"}, {"t": "120 องศา"}, {"t": "180 องศา"}, {"t": "109.5 องศา"}], "answer": 1}$j$::jsonb, 1, $t$คาร์บอนไฮบริไดซ์แบบ sp2 รูปร่างสามเหลี่ยมแบนราบ$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$มุมพันธะรอบคาร์บอนของเอทีนมีค่าประมาณเท่าใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$โมเลกุลเอไทน์มีรูปร่างเป็นอย่างไร$t$, $j${"choices": [{"t": "เส้นตรง (มุม 180 องศา)"}, {"t": "เตตระฮีดรอล"}, {"t": "งอ"}, {"t": "สามเหลี่ยมแบนราบ"}], "answer": 0}$j$::jsonb, 1, $t$คาร์บอน sp ให้มุม H-C≡C เท่ากับ 180°$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$โมเลกุลเอไทน์มีรูปร่างเป็นอย่างไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$1-บิวทีนมีสูตรโมเลกุลใด$t$, $j${"choices": [{"t": "C4H8"}, {"t": "C4H6"}, {"t": "C4H4"}, {"t": "C4H10"}], "answer": 0}$j$::jsonb, 1, $t$แอลคีน CnH2n เมื่อ n = 4$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$1-บิวทีนมีสูตรโมเลกุลใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$เพนต์-1-อีนมีไฮโดรเจนกี่อะตอม$t$, $j${"choices": [{"t": "8 อะตอม"}, {"t": "6 อะตอม"}, {"t": "10 อะตอม"}, {"t": "12 อะตอม"}], "answer": 2}$j$::jsonb, 1, $t$C5H10$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$เพนต์-1-อีนมีไฮโดรเจนกี่อะตอม$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'mcq', $t$เฮกไซน์ (C6) มีไฮโดรเจนกี่อะตอม$t$, $j${"choices": [{"t": "14 อะตอม"}, {"t": "8 อะตอม"}, {"t": "10 อะตอม"}, {"t": "12 อะตอม"}], "answer": 2}$j$::jsonb, 1, $t$CnH2n-2 เมื่อ n = 6 → H = 10$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$เฮกไซน์ (C6) มีไฮโดรเจนกี่อะตอม$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'tf', $t$แอลคีนและแอลไคน์จัดเป็นไฮโดรคาร์บอนไม่อิ่มตัว$t$, $j${"answer": true}$j$::jsonb, 1, $t$มีพันธะคู่หรือพันธะสามระหว่างคาร์บอน$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$แอลคีนและแอลไคน์จัดเป็นไฮโดรคาร์บอนไม่อิ่มตัว$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'tf', $t$เอทีนเป็นฮอร์โมนพืชชนิดหนึ่งที่ช่วยให้ผลไม้สุก$t$, $j${"answer": true}$j$::jsonb, 1, $t$เอทิลีน (C2H4) กระตุ้นการสุกของผลไม้$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$เอทีนเป็นฮอร์โมนพืชชนิดหนึ่งที่ช่วยให้ผลไม้สุก$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'tf', $t$แอลไคน์ทุกชนิดมีพันธะสามอยู่ที่ปลายโซ่เท่านั้น$t$, $j${"answer": false}$j$::jsonb, 1, $t$เช่น 2-บิวไทน์ มีพันธะสามอยู่กลางโซ่$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$แอลไคน์ทุกชนิดมีพันธะสามอยู่ที่ปลายโซ่เท่านั้น$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลคีนและแอลไคน์$t$, 'match', $t$จับคู่ชื่อกับสูตรโมเลกุล$t$, $j${"left": [{"t": "เอทีน"}, {"t": "เอไทน์"}, {"t": "โพรพีน"}, {"t": "โพรไพน์"}], "right": [{"t": "C2H4"}, {"t": "C3H8"}, {"t": "C2H2"}, {"t": "C3H4"}, {"t": "C3H6"}], "pairs": [0, 2, 4, 3]}$j$::jsonb, 4, $t$แอลคีน CnH2n · แอลไคน์ CnH2n-2$t$
where not exists (select 1 from exam_questions where topic = $t$แอลคีนและแอลไคน์$t$ and q = $t$จับคู่ชื่อกับสูตรโมเลกุล$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$เบนซีนมีสูตรโมเลกุลใด$t$, $j${"choices": [{"t": "C6H6"}, {"t": "C5H6"}, {"t": "C6H12"}, {"t": "C6H14"}], "answer": 0}$j$::jsonb, 1, $t$วงแหวนคาร์บอน 6 อะตอม แต่ละอะตอมต่อกับ H 1 อะตอม$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$เบนซีนมีสูตรโมเลกุลใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$ข้อใดอธิบายโครงสร้างของเบนซีนได้ถูกต้องที่สุด$t$, $j${"choices": [{"t": "มีพันธะเดี่ยวและพันธะคู่สลับกันโดยมีความยาวต่างกัน"}, {"t": "วงแหวนหกเหลี่ยมแบนราบ พันธะ C-C ทุกพันธะยาวเท่ากันเพราะเรโซแนนซ์"}, {"t": "เป็นวงแหวนอิ่มตัวเช่นเดียวกับไซโคลเฮกเซน"}, {"t": "เป็นโซ่ตรงที่มีพันธะคู่ 3 พันธะ"}], "answer": 1}$j$::jsonb, 1, $t$อิเล็กตรอน π แบ่งปันรอบวงแหวน (เรโซแนนซ์)$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$ข้อใดอธิบายโครงสร้างของเบนซีนได้ถูกต้องที่สุด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$ความยาวพันธะ C-C ในเบนซีนเมื่อเทียบกับพันธะเดี่ยวและพันธะคู่ C=C ปกติเป็นอย่างไร$t$, $j${"choices": [{"t": "เท่ากับพันธะคู่"}, {"t": "ยาวกว่าพันธะเดี่ยว"}, {"t": "เท่ากับพันธะเดี่ยว"}, {"t": "อยู่ระหว่างพันธะเดี่ยวกับพันธะคู่"}], "answer": 3}$j$::jsonb, 1, $t$พันธะมีลักษณะกึ่งกลางเนื่องจากเรโซแนนซ์$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$ความยาวพันธะ C-C ในเบนซีนเมื่อเทียบกับพันธะเดี่ยวและพันธะคู่ C=C ปกติเป็นอย่างไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$ปฏิกิริยาที่เบนซีนเกิดได้ง่ายที่สุดคือข้อใด$t$, $j${"choices": [{"t": "ปฏิกิริยาการแทนที่"}, {"t": "ปฏิกิริยาการเติม"}, {"t": "ปฏิกิริยาการหมัก"}, {"t": "ปฏิกิริยาการเกิดเอสเทอร์"}], "answer": 0}$j$::jsonb, 1, $t$ต้องการรักษาระบบเรโซแนนซ์ของวงแหวน$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$ปฏิกิริยาที่เบนซีนเกิดได้ง่ายที่สุดคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$เบนซีนทำปฏิกิริยากับ Br2 โดยมี FeBr3 เป็นตัวเร่ง ได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "โบรโมเบนซีนและ HBr"}, {"t": "เฮกเซน"}, {"t": "1,2-ไดโบรโมไซโคลเฮกเซน"}, {"t": "ฟีนอล"}], "answer": 0}$j$::jsonb, 1, $t$เป็นปฏิกิริยาการแทนที่ H ด้วย Br$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$เบนซีนทำปฏิกิริยากับ Br2 โดยมี FeBr3 เป็นตัวเร่ง ได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$เบนซีนทำปฏิกิริยากับกรดไนตริกและกรดซัลฟิวริกเข้มข้น ได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "ไนโตรเบนซีน"}, {"t": "โทลูอีน"}, {"t": "ไซโคลเฮกเซน"}, {"t": "แอนิลีน"}], "answer": 0}$j$::jsonb, 1, $t$ปฏิกิริยาไนเตรชัน ใส่หมู่ -NO2$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$เบนซีนทำปฏิกิริยากับกรดไนตริกและกรดซัลฟิวริกเข้มข้น ได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$โทลูอีนมีสูตรโมเลกุลใด$t$, $j${"choices": [{"t": "C8H10"}, {"t": "C6H6"}, {"t": "C7H8"}, {"t": "C7H14"}], "answer": 2}$j$::jsonb, 1, $t$C6H5CH3 = C7H8$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$โทลูอีนมีสูตรโมเลกุลใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$ฟีนอลมีสูตรโครงสร้างตามข้อใด$t$, $j${"choices": [{"t": "C6H5CH3"}, {"t": "C6H5OH"}, {"t": "C6H5COOH"}, {"t": "C6H5NH2"}], "answer": 1}$j$::jsonb, 1, $t$หมู่ -OH ต่อกับวงแหวนเบนซีน$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$ฟีนอลมีสูตรโครงสร้างตามข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$แอนิลีนมีหมู่ฟังก์ชันใดต่ออยู่กับวงแหวนเบนซีน$t$, $j${"choices": [{"t": "หมู่ไนโตร (-NO2)"}, {"t": "หมู่เมทิล (-CH3)"}, {"t": "หมู่ไฮดรอกซิล (-OH)"}, {"t": "หมู่อะมิโน (-NH2)"}], "answer": 3}$j$::jsonb, 1, $t$แอนิลีน = C6H5NH2$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$แอนิลีนมีหมู่ฟังก์ชันใดต่ออยู่กับวงแหวนเบนซีน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$ไดเมทิลเบนซีน (ไซลีน) มีไอโซเมอร์ตำแหน่งกี่แบบ$t$, $j${"choices": [{"t": "3 แบบ (ออร์โท เมทา พารา)"}, {"t": "4 แบบ"}, {"t": "1 แบบ"}, {"t": "2 แบบ"}], "answer": 0}$j$::jsonb, 1, $t$หมู่เมทิล 2 หมู่บนวงแหวนอยู่ตำแหน่ง 1,2 / 1,3 / 1,4$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$ไดเมทิลเบนซีน (ไซลีน) มีไอโซเมอร์ตำแหน่งกี่แบบ$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$หมู่แทนที่สองหมู่บนวงแหวนเบนซีนที่อยู่ตำแหน่ง 1,4 เรียกว่าอะไร$t$, $j${"choices": [{"t": "เมทา (meta)"}, {"t": "ไอโซ (iso)"}, {"t": "พารา (para)"}, {"t": "ออร์โท (ortho)"}], "answer": 2}$j$::jsonb, 1, $t$1,2 = ออร์โท · 1,3 = เมทา · 1,4 = พารา$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$หมู่แทนที่สองหมู่บนวงแหวนเบนซีนที่อยู่ตำแหน่ง 1,4 เรียกว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$สารใดต่อไปนี้เป็นสารประกอบอะโรมาติก$t$, $j${"choices": [{"t": "โทลูอีน"}, {"t": "1-เฮกซีน"}, {"t": "เฮกเซน"}, {"t": "ไซโคลเฮกเซน"}], "answer": 0}$j$::jsonb, 1, $t$มีวงแหวนเบนซีน$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$สารใดต่อไปนี้เป็นสารประกอบอะโรมาติก$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$อัตราส่วนอะตอม C : H ของเบนซีนเท่ากับเท่าใด (สูตรเอมพิริคัล)$t$, $j${"choices": [{"t": "2 : 1"}, {"t": "1 : 2"}, {"t": "1 : 3"}, {"t": "1 : 1 (CH)"}], "answer": 3}$j$::jsonb, 1, $t$C6H6 ลดทอนเป็น CH$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$อัตราส่วนอะตอม C : H ของเบนซีนเท่ากับเท่าใด (สูตรเอมพิริคัล)$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$แนฟทาลีนมีสูตรโมเลกุลใด$t$, $j${"choices": [{"t": "C6H6"}, {"t": "C10H8"}, {"t": "C12H10"}, {"t": "C10H18"}], "answer": 1}$j$::jsonb, 1, $t$วงแหวนเบนซีน 2 วงหลอมรวมกัน$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$แนฟทาลีนมีสูตรโมเลกุลใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$มวลโมเลกุลของเบนซีน (C=12, H=1) เท่ากับเท่าใด$t$, $j${"choices": [{"t": "78"}, {"t": "72"}, {"t": "84"}, {"t": "66"}], "answer": 0}$j$::jsonb, 1, $t$6×12 + 6×1 = 78$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$มวลโมเลกุลของเบนซีน (C=12, H=1) เท่ากับเท่าใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'mcq', $t$สไตรีน (ไวนิลเบนซีน, C6H5CH=CH2) มีสูตรโมเลกุลใด$t$, $j${"choices": [{"t": "C7H8"}, {"t": "C8H10"}, {"t": "C8H8"}, {"t": "C8H6"}], "answer": 2}$j$::jsonb, 1, $t$วงแหวน C6H5 + CH=CH2 → C8H8$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$สไตรีน (ไวนิลเบนซีน, C6H5CH=CH2) มีสูตรโมเลกุลใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'tf', $t$เบนซีนทำปฏิกิริยาการเติมกับ Br2 ได้ง่ายเหมือนแอลคีน$t$, $j${"answer": false}$j$::jsonb, 1, $t$เบนซีนเสถียรกว่าเพราะเรโซแนนซ์ จึงเกิดแทนที่แทนการเติม$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$เบนซีนทำปฏิกิริยาการเติมกับ Br2 ได้ง่ายเหมือนแอลคีน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'tf', $t$น้ำโบรมีนไม่จางสีเมื่อเขย่ากับเบนซีนที่อุณหภูมิห้อง$t$, $j${"answer": true}$j$::jsonb, 1, $t$เบนซีนไม่ทำปฏิกิริยาการเติมในสภาวะนี้$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$น้ำโบรมีนไม่จางสีเมื่อเขย่ากับเบนซีนที่อุณหภูมิห้อง$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'tf', $t$เบนซีนเป็นสารก่อมะเร็ง ควรหลีกเลี่ยงการสูดดมและสัมผัส$t$, $j${"answer": true}$j$::jsonb, 1, $t$เบนซีนเป็นสารก่อมะเร็งในมนุษย์$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$เบนซีนเป็นสารก่อมะเร็ง ควรหลีกเลี่ยงการสูดดมและสัมผัส$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$อะโรมาติกไฮโดรคาร์บอน$t$, 'match', $t$จับคู่ชื่อสารอะโรมาติกกับสูตร$t$, $j${"left": [{"t": "เบนซีน"}, {"t": "โทลูอีน"}, {"t": "ฟีนอล"}, {"t": "แอนิลีน"}], "right": [{"t": "C6H5CH3"}, {"t": "C6H6"}, {"t": "C6H5NH2"}, {"t": "C6H5COOH"}, {"t": "C6H5OH"}], "pairs": [1, 0, 4, 2]}$j$::jsonb, 4, $t$ดูหมู่ที่ต่ออยู่กับวงแหวนเบนซีน$t$
where not exists (select 1 from exam_questions where topic = $t$อะโรมาติกไฮโดรคาร์บอน$t$ and q = $t$จับคู่ชื่อสารอะโรมาติกกับสูตร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$การเผาไหม้ไฮโดรคาร์บอนอย่างสมบูรณ์ให้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "CO2 และ H2"}, {"t": "CO2 และ H2O"}, {"t": "CO และ H2O"}, {"t": "C และ H2"}], "answer": 1}$j$::jsonb, 1, $t$ออกซิเจนเพียงพอ C → CO2, H → H2O$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$การเผาไหม้ไฮโดรคาร์บอนอย่างสมบูรณ์ให้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$การเผาไหม้ไม่สมบูรณ์ของไฮโดรคาร์บอนอาจเกิดสารใดเพิ่ม$t$, $j${"choices": [{"t": "NH3"}, {"t": "SO3"}, {"t": "CO และเขม่า (C)"}, {"t": "O3"}], "answer": 2}$j$::jsonb, 1, $t$ออกซิเจนไม่เพียงพอ$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$การเผาไหม้ไม่สมบูรณ์ของไฮโดรคาร์บอนอาจเกิดสารใดเพิ่ม$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$การเผาไหม้มีเทนสมบูรณ์ CH4 + O2 → CO2 + H2O เมื่อดุลสมการแล้ว ใช้ O2 กี่โมลต่อ CH4 1 โมล$t$, $j${"choices": [{"t": "3 โมล"}, {"t": "1 โมล"}, {"t": "2 โมล"}, {"t": "4 โมล"}], "answer": 2}$j$::jsonb, 1, $t$CH4 + 2O2 → CO2 + 2H2O$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$การเผาไหม้มีเทนสมบูรณ์ CH4 + O2 → CO2 + H2O เมื่อดุลสมการแล้ว ใช้ O2 กี่โมลต่อ CH4 1 โมล$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$เผาโพรเพน (C3H8) 1 โมลอย่างสมบูรณ์ ใช้ O2 กี่โมล$t$, $j${"choices": [{"t": "7 โมล"}, {"t": "5 โมล"}, {"t": "3 โมล"}, {"t": "4 โมล"}], "answer": 1}$j$::jsonb, 1, $t$C3H8 + 5O2 → 3CO2 + 4H2O$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$เผาโพรเพน (C3H8) 1 โมลอย่างสมบูรณ์ ใช้ O2 กี่โมล$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$เผาบิวเทน (C4H10) 1 โมลอย่างสมบูรณ์ ใช้ O2 กี่โมล$t$, $j${"choices": [{"t": "8 โมล"}, {"t": "6.5 โมล"}, {"t": "4 โมล"}, {"t": "5 โมล"}], "answer": 1}$j$::jsonb, 1, $t$C4H10 + 13/2 O2 → 4CO2 + 5H2O$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$เผาบิวเทน (C4H10) 1 โมลอย่างสมบูรณ์ ใช้ O2 กี่โมล$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$เผาอีเทน (C2H6) 1 โมลอย่างสมบูรณ์ ได้ CO2 กี่โมล$t$, $j${"choices": [{"t": "3 โมล"}, {"t": "6 โมล"}, {"t": "1 โมล"}, {"t": "2 โมล"}], "answer": 3}$j$::jsonb, 1, $t$คาร์บอน 2 อะตอมทุกอะตอมกลายเป็น CO2$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$เผาอีเทน (C2H6) 1 โมลอย่างสมบูรณ์ ได้ CO2 กี่โมล$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$เผาเอทีน (C2H4) 1 โมลอย่างสมบูรณ์ ใช้ O2 กี่โมล$t$, $j${"choices": [{"t": "2.5 โมล"}, {"t": "3 โมล"}, {"t": "4 โมล"}, {"t": "2 โมล"}], "answer": 1}$j$::jsonb, 1, $t$C2H4 + 3O2 → 2CO2 + 2H2O$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$เผาเอทีน (C2H4) 1 โมลอย่างสมบูรณ์ ใช้ O2 กี่โมล$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$ไฮโดรคาร์บอนข้อใดเมื่อเผาไหม้แล้วให้เขม่ามากที่สุด$t$, $j${"choices": [{"t": "อีเทน"}, {"t": "เบนซีน"}, {"t": "โพรเพน"}, {"t": "มีเทน"}], "answer": 1}$j$::jsonb, 1, $t$เบนซีนมีร้อยละโดยมวลของคาร์บอนสูงที่สุด จึงเผาไหม้ไม่สมบูรณ์ง่ายและเกิดเขม่า$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$ไฮโดรคาร์บอนข้อใดเมื่อเผาไหม้แล้วให้เขม่ามากที่สุด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$แก๊สพิษที่ไม่มีสีและไม่มีกลิ่น เกิดจากการเผาไหม้ไม่สมบูรณ์คือข้อใด$t$, $j${"choices": [{"t": "SO2"}, {"t": "NO2"}, {"t": "CO2"}, {"t": "CO"}], "answer": 3}$j$::jsonb, 1, $t$CO ไปจับฮีโมโกลบินแทนออกซิเจน$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$แก๊สพิษที่ไม่มีสีและไม่มีกลิ่น เกิดจากการเผาไหม้ไม่สมบูรณ์คือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$ปฏิกิริยาแทนที่ของมีเทนกับคลอรีนต้องมีสภาวะใด$t$, $j${"choices": [{"t": "ตัวเร่ง Ni"}, {"t": "กรดซัลฟิวริกเข้มข้น"}, {"t": "ความเย็นจัด"}, {"t": "แสงอัลตราไวโอเลต"}], "answer": 3}$j$::jsonb, 1, $t$แสง UV ทำให้ Cl2 แตกเป็นอนุมูล$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$ปฏิกิริยาแทนที่ของมีเทนกับคลอรีนต้องมีสภาวะใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$ผลิตภัณฑ์ขั้นแรกของ CH4 + Cl2 (แสง) คือข้อใด$t$, $j${"choices": [{"t": "CCl4 เท่านั้น"}, {"t": "CH3Cl และ HCl"}, {"t": "CH2Cl2 และ H2"}, {"t": "C2H6"}], "answer": 1}$j$::jsonb, 1, $t$แทนที่ H 1 อะตอมด้วย Cl$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$ผลิตภัณฑ์ขั้นแรกของ CH4 + Cl2 (แสง) คือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$ปฏิกิริยาการเติม (addition) มีลักษณะอย่างไร$t$, $j${"choices": [{"t": "สารแตกตัวเป็นโมเลกุลเล็กลง"}, {"t": "อะตอม H ถูกแทนที่ด้วยอะตอมอื่น"}, {"t": "อะตอมหรือหมู่อะตอมเข้าต่อที่พันธะคู่หรือพันธะสาม ได้ผลิตภัณฑ์เพียงชนิดเดียว"}, {"t": "สารสองชนิดรวมกันและเสียน้ำ"}], "answer": 2}$j$::jsonb, 1, $t$พันธะ π ถูกเปิดออก$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$ปฏิกิริยาการเติม (addition) มีลักษณะอย่างไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$ไฮโดรจีเนชันคือปฏิกิริยาที่เติมสารใด$t$, $j${"choices": [{"t": "ไฮโดรเจนเฮไลด์ (HX)"}, {"t": "น้ำ (H2O)"}, {"t": "ออกซิเจน (O2)"}, {"t": "ไฮโดรเจน (H2)"}], "answer": 3}$j$::jsonb, 1, $t$hydro = ไฮโดรเจน$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$ไฮโดรจีเนชันคือปฏิกิริยาที่เติมสารใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$เติม Cl2 ลงในเอไทน์ 2 โมล (มากเกินพอ) ได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "1,1-ไดคลอโรเอเทน"}, {"t": "คลอโรเอเทน"}, {"t": "1,1,2,2-เตตระคลอโรเอเทน"}, {"t": "1,2-ไดคลอโรเอทีน"}], "answer": 2}$j$::jsonb, 1, $t$พันธะสามรับ Cl2 2 โมล กลายเป็นพันธะเดี่ยว$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$เติม Cl2 ลงในเอไทน์ 2 โมล (มากเกินพอ) ได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$เผา CH4 1 ลิตรอย่างสมบูรณ์ที่ T และ P เดียวกัน ได้ CO2 กี่ลิตร$t$, $j${"choices": [{"t": "1 ลิตร"}, {"t": "2 ลิตร"}, {"t": "0.5 ลิตร"}, {"t": "3 ลิตร"}], "answer": 0}$j$::jsonb, 1, $t$CH4 : CO2 = 1 : 1 โดยโมล (และโดยปริมาตรของแก๊ส)$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$เผา CH4 1 ลิตรอย่างสมบูรณ์ที่ T และ P เดียวกัน ได้ CO2 กี่ลิตร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$เผา C2H6 1 ลิตรอย่างสมบูรณ์ต้องใช้ O2 กี่ลิตรที่ T และ P เดียวกัน$t$, $j${"choices": [{"t": "2 ลิตร"}, {"t": "3.5 ลิตร"}, {"t": "7 ลิตร"}, {"t": "5 ลิตร"}], "answer": 1}$j$::jsonb, 1, $t$C2H6 + 7/2 O2 → 2CO2 + 3H2O$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$เผา C2H6 1 ลิตรอย่างสมบูรณ์ต้องใช้ O2 กี่ลิตรที่ T และ P เดียวกัน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$องค์ประกอบหลักของแก๊สธรรมชาติคือข้อใด$t$, $j${"choices": [{"t": "เบนซีน"}, {"t": "ออกซิเจน"}, {"t": "มีเทน"}, {"t": "เอทีน"}], "answer": 2}$j$::jsonb, 1, $t$มีเทนประมาณ 70-95%$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$องค์ประกอบหลักของแก๊สธรรมชาติคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$แก๊สหุงต้ม (LPG) ประกอบด้วยไฮโดรคาร์บอนหลักชนิดใด$t$, $j${"choices": [{"t": "เอทีนและโพรพีน"}, {"t": "เบนซีนและโทลูอีน"}, {"t": "โพรเพนและบิวเทน"}, {"t": "มีเทนและอีเทน"}], "answer": 2}$j$::jsonb, 1, $t$อัดเป็นของเหลวภายใต้ความดัน$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$แก๊สหุงต้ม (LPG) ประกอบด้วยไฮโดรคาร์บอนหลักชนิดใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$น้ำมันดิบถูกแยกเป็นส่วนต่างๆ ด้วยกระบวนการใด$t$, $j${"choices": [{"t": "การกลั่นลำดับส่วน"}, {"t": "การกรอง"}, {"t": "การตกผลึก"}, {"t": "การระเหิด"}], "answer": 0}$j$::jsonb, 1, $t$แยกตามความแตกต่างของจุดเดือด$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$น้ำมันดิบถูกแยกเป็นส่วนต่างๆ ด้วยกระบวนการใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$ผลิตภัณฑ์จากการกลั่นน้ำมันดิบส่วนใดมีจุดเดือดต่ำสุด$t$, $j${"choices": [{"t": "แอสฟอลต์"}, {"t": "น้ำมันดีเซล"}, {"t": "น้ำมันหล่อลื่น"}, {"t": "แก๊สปิโตรเลียม"}], "answer": 3}$j$::jsonb, 1, $t$โมเลกุลเล็กที่สุด (C1-C4)$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$ผลิตภัณฑ์จากการกลั่นน้ำมันดิบส่วนใดมีจุดเดือดต่ำสุด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'mcq', $t$ค่าออกเทนของน้ำมันเบนซินบอกสมบัติใด$t$, $j${"choices": [{"t": "ปริมาณกำมะถัน"}, {"t": "ความสามารถในการต้านการน็อกของเครื่องยนต์"}, {"t": "ปริมาณน้ำ"}, {"t": "จุดเยือกแข็ง"}], "answer": 1}$j$::jsonb, 1, $t$ออกเทนสูงจุดระเบิดช้ากว่า น็อกน้อยลง$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$ค่าออกเทนของน้ำมันเบนซินบอกสมบัติใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'tf', $t$การแตกสลายด้วยความร้อน (cracking) เปลี่ยนไฮโดรคาร์บอนโมเลกุลใหญ่ให้เป็นโมเลกุลเล็กลง$t$, $j${"answer": true}$j$::jsonb, 1, $t$เพิ่มปริมาณน้ำมันเบนซินและแอลคีน$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$การแตกสลายด้วยความร้อน (cracking) เปลี่ยนไฮโดรคาร์บอนโมเลกุลใหญ่ให้เป็นโมเลกุลเล็กลง$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'tf', $t$การเผาไหม้ของไฮโดรคาร์บอนเป็นปฏิกิริยาดูดความร้อน$t$, $j${"answer": false}$j$::jsonb, 1, $t$เป็นปฏิกิริยาคายความร้อน ใช้เป็นเชื้อเพลิง$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$การเผาไหม้ของไฮโดรคาร์บอนเป็นปฏิกิริยาดูดความร้อน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'tf', $t$แอลเคนทำปฏิกิริยาการเติมกับ Br2 ได้ในที่มืด$t$, $j${"answer": false}$j$::jsonb, 1, $t$แอลเคนอิ่มตัว ไม่เกิดการเติม ต้องแทนที่ด้วยแสง$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$แอลเคนทำปฏิกิริยาการเติมกับ Br2 ได้ในที่มืด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$, 'match', $t$จับคู่สารตั้งต้นกับชนิดของปฏิกิริยา$t$, $j${"left": [{"t": "CH4 + Cl2 (แสง)"}, {"t": "CH2=CH2 + Br2"}, {"t": "C3H8 + O2 (มากเกินพอ)"}, {"t": "C6H14 (ความร้อนสูง/ตัวเร่ง)"}], "right": [{"t": "การหมัก"}, {"t": "การแทนที่"}, {"t": "การเผาไหม้"}, {"t": "การแตกสลาย"}, {"t": "การเติม"}], "pairs": [1, 4, 2, 3]}$j$::jsonb, 4, $t$สอดคล้องกับลักษณะของปฏิกิริยา$t$
where not exists (select 1 from exam_questions where topic = $t$ปฏิกิริยาและเชื้อเพลิงไฮโดรคาร์บอน$t$ and q = $t$จับคู่สารตั้งต้นกับชนิดของปฏิกิริยา$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$หมู่ฟังก์ชันของแอลกอฮอล์คือข้อใด$t$, $j${"choices": [{"t": "-OH (ไฮดรอกซิล)"}, {"t": "-COOH"}, {"t": "-CHO"}, {"t": "-O- (ระหว่างคาร์บอน)"}], "answer": 0}$j$::jsonb, 1, $t$แอลกอฮอล์มี -OH ต่อกับคาร์บอนอิ่มตัว$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$หมู่ฟังก์ชันของแอลกอฮอล์คือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$CH3CH2OH มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "เอทานอยด์"}, {"t": "เอทานอล"}, {"t": "เอทานัล"}, {"t": "เมทานอล"}], "answer": 1}$j$::jsonb, 1, $t$2 คาร์บอน + ลงท้าย -ออล$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$CH3CH2OH มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$CH3CH2CH2OH มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "โพรพานัล"}, {"t": "โพรพาโนน"}, {"t": "1-โพรพานอล"}, {"t": "2-โพรพานอล"}], "answer": 2}$j$::jsonb, 1, $t$OH อยู่ที่คาร์บอนปลายโซ่ (C1)$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$CH3CH2CH2OH มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$CH3CH(OH)CH3 มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "2-โพรพานอล"}, {"t": "ไดเมทิลอีเทอร์"}, {"t": "โพรพานัล"}, {"t": "1-โพรพานอล"}], "answer": 0}$j$::jsonb, 1, $t$OH อยู่ที่ C2$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$CH3CH(OH)CH3 มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$แอลกอฮอล์ปฐมภูมิ (1°) หมายถึงข้อใด$t$, $j${"choices": [{"t": "คาร์บอนที่ต่อกับ -OH ต่ออยู่กับคาร์บอนอื่น 3 อะตอม"}, {"t": "มี -OH 1 หมู่ในโมเลกุลเท่านั้น"}, {"t": "คาร์บอนที่ต่อกับ -OH ต่ออยู่กับคาร์บอนอื่น 2 อะตอม"}, {"t": "คาร์บอนที่ต่อกับ -OH ต่ออยู่กับคาร์บอนอื่นอีก 1 อะตอม"}], "answer": 3}$j$::jsonb, 1, $t$นับจำนวนคาร์บอนที่ต่อกับคาร์บอนที่มี -OH$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$แอลกอฮอล์ปฐมภูมิ (1°) หมายถึงข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$2-โพรพานอลจัดเป็นแอลกอฮอล์ประเภทใด$t$, $j${"choices": [{"t": "ทุติยภูมิ (2°)"}, {"t": "ปฐมภูมิ (1°)"}, {"t": "ตติยภูมิ (3°)"}, {"t": "ไม่จัดเป็นแอลกอฮอล์"}], "answer": 0}$j$::jsonb, 1, $t$C2 ต่อกับคาร์บอนอื่น 2 อะตอม$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$2-โพรพานอลจัดเป็นแอลกอฮอล์ประเภทใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$2-เมทิล-2-โพรพานอลจัดเป็นแอลกอฮอล์ประเภทใด$t$, $j${"choices": [{"t": "ตติยภูมิ (3°)"}, {"t": "ไม่ใช่แอลกอฮอล์"}, {"t": "ทุติยภูมิ (2°)"}, {"t": "ปฐมภูมิ (1°)"}], "answer": 0}$j$::jsonb, 1, $t$คาร์บอนที่มี -OH ต่อกับคาร์บอนอื่น 3 อะตอม$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$2-เมทิล-2-โพรพานอลจัดเป็นแอลกอฮอล์ประเภทใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$เหตุใดเอทานอลมีจุดเดือดสูงกว่าไดเมทิลอีเทอร์ ทั้งที่เป็นไอโซเมอร์กัน$t$, $j${"choices": [{"t": "ไดเมทิลอีเทอร์เป็นไอออนิก"}, {"t": "เอทานอลสร้างพันธะไฮโดรเจนระหว่างโมเลกุลได้"}, {"t": "เอทานอลมีมวลโมเลกุลมากกว่า"}, {"t": "เอทานอลมีพันธะคู่"}], "answer": 1}$j$::jsonb, 1, $t$อีเทอร์ไม่มี O-H จึงไม่เกิดพันธะไฮโดรเจนระหว่างโมเลกุลกันเอง$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$เหตุใดเอทานอลมีจุดเดือดสูงกว่าไดเมทิลอีเทอร์ ทั้งที่เป็นไอโซเมอร์กัน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$แอลกอฮอล์ที่มีคาร์บอนน้อยๆ (เช่น เมทานอล เอทานอล) ละลายน้ำได้ดีเพราะเหตุใด$t$, $j${"choices": [{"t": "สร้างพันธะไฮโดรเจนกับน้ำได้"}, {"t": "มีพันธะไอออนิก"}, {"t": "มีมวลโมเลกุลมาก"}, {"t": "เป็นสารไม่มีขั้ว"}], "answer": 0}$j$::jsonb, 1, $t$หมู่ -OH มีขั้วและสร้างพันธะไฮโดรเจนกับน้ำ$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$แอลกอฮอล์ที่มีคาร์บอนน้อยๆ (เช่น เมทานอล เอทานอล) ละลายน้ำได้ดีเพราะเหตุใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$เมื่อจำนวนคาร์บอนของแอลกอฮอล์สายตรงเพิ่มขึ้น การละลายน้ำเปลี่ยนแปลงอย่างไร$t$, $j${"choices": [{"t": "เพิ่มขึ้น เพราะมีพันธะคู่มากขึ้น"}, {"t": "ไม่เปลี่ยนแปลง"}, {"t": "เพิ่มขึ้น เพราะมวลโมเลกุลมากขึ้น"}, {"t": "ลดลง เพราะส่วนที่ไม่มีขั้ว (ไฮโดรคาร์บอน) ยาวขึ้น"}], "answer": 3}$j$::jsonb, 1, $t$ส่วนหางที่ไม่มีขั้วมีอิทธิพลมากขึ้น$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$เมื่อจำนวนคาร์บอนของแอลกอฮอล์สายตรงเพิ่มขึ้น การละลายน้ำเปลี่ยนแปลงอย่างไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$แอลกอฮอล์ทำปฏิกิริยากับโลหะโซเดียมให้แก๊สใด$t$, $j${"choices": [{"t": "H2"}, {"t": "Cl2"}, {"t": "O2"}, {"t": "CO2"}], "answer": 0}$j$::jsonb, 1, $t$2ROH + 2Na → 2RONa + H2$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$แอลกอฮอล์ทำปฏิกิริยากับโลหะโซเดียมให้แก๊สใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$การออกซิไดส์แอลกอฮอล์ปฐมภูมิอย่างอ่อนให้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "เอสเทอร์"}, {"t": "แอลคีน"}, {"t": "คีโตน"}, {"t": "แอลดีไฮด์"}], "answer": 3}$j$::jsonb, 1, $t$RCH2OH → RCHO$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$การออกซิไดส์แอลกอฮอล์ปฐมภูมิอย่างอ่อนให้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$การออกซิไดส์แอลกอฮอล์ทุติยภูมิให้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "คีโตน"}, {"t": "อีเทอร์"}, {"t": "กรดคาร์บอกซิลิก"}, {"t": "แอลดีไฮด์"}], "answer": 0}$j$::jsonb, 1, $t$R2CHOH → R2C=O$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$การออกซิไดส์แอลกอฮอล์ทุติยภูมิให้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$แอลกอฮอล์ตติยภูมิถูกออกซิไดส์ด้วยตัวออกซิไดส์ทั่วไปได้หรือไม่$t$, $j${"choices": [{"t": "ได้เป็นกรดคาร์บอกซิลิก"}, {"t": "ไม่ได้ เพราะคาร์บอนที่มี -OH ไม่มี H"}, {"t": "ได้เป็นคีโตน"}, {"t": "ได้เป็นแอลดีไฮด์"}], "answer": 1}$j$::jsonb, 1, $t$ไม่มี H ที่คาร์บอนให้ถูกดึงออก$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$แอลกอฮอล์ตติยภูมิถูกออกซิไดส์ด้วยตัวออกซิไดส์ทั่วไปได้หรือไม่$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$การออกซิไดส์เอทานอลอย่างสมบูรณ์ได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "โพรพาโนน"}, {"t": "เอทานัล"}, {"t": "ไดเอทิลอีเทอร์"}, {"t": "กรดเอทาโนอิก (กรดแอซีติก)"}], "answer": 3}$j$::jsonb, 1, $t$เอทานอล → เอทานัล → กรดเอทาโนอิก$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$การออกซิไดส์เอทานอลอย่างสมบูรณ์ได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$เมื่อทำให้เอทานอลขาดน้ำด้วย H2SO4 เข้มข้นที่ประมาณ 170 องศาเซลเซียส ได้ผลิตภัณฑ์หลักใด$t$, $j${"choices": [{"t": "เอไทน์"}, {"t": "เอทีน"}, {"t": "เอทานัล"}, {"t": "ไดเอทิลอีเทอร์"}], "answer": 1}$j$::jsonb, 1, $t$การกำจัดน้ำภายในโมเลกุล (intramolecular dehydration)$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$เมื่อทำให้เอทานอลขาดน้ำด้วย H2SO4 เข้มข้นที่ประมาณ 170 องศาเซลเซียส ได้ผลิตภัณฑ์หลักใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$เมื่อทำให้เอทานอลขาดน้ำด้วย H2SO4 เข้มข้นที่ประมาณ 140 องศาเซลเซียส ได้ผลิตภัณฑ์หลักใด$t$, $j${"choices": [{"t": "เอทีน"}, {"t": "ไดเอทิลอีเทอร์"}, {"t": "เอทานัล"}, {"t": "เอทิลเอทาโนเอต"}], "answer": 1}$j$::jsonb, 1, $t$ขาดน้ำระหว่างโมเลกุลสองโมเลกุล$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$เมื่อทำให้เอทานอลขาดน้ำด้วย H2SO4 เข้มข้นที่ประมาณ 140 องศาเซลเซียส ได้ผลิตภัณฑ์หลักใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$กระบวนการหมักน้ำตาลกลูโคสโดยยีสต์ให้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "เอทานอลและ CO2"}, {"t": "กรดแอซีติกและ H2"}, {"t": "เอทีนและ H2O"}, {"t": "เมทานอลและ O2"}], "answer": 0}$j$::jsonb, 1, $t$C6H12O6 → 2C2H5OH + 2CO2$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$กระบวนการหมักน้ำตาลกลูโคสโดยยีสต์ให้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$แอลกอฮอล์ชนิดใดเป็นพิษมาก ดื่มแล้วอาจทำให้ตาบอดหรือเสียชีวิต$t$, $j${"choices": [{"t": "เมทานอล"}, {"t": "น้ำตาล"}, {"t": "กลีเซอรอล"}, {"t": "เอทานอลเจือจาง"}], "answer": 0}$j$::jsonb, 1, $t$เมทานอลถูกเปลี่ยนเป็นฟอร์มาลดีไฮด์และกรดฟอร์มิกในร่างกาย$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$แอลกอฮอล์ชนิดใดเป็นพิษมาก ดื่มแล้วอาจทำให้ตาบอดหรือเสียชีวิต$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$เอทิลีนไกลคอล (1,2-เอทานไดออล) ใช้ประโยชน์ในข้อใด$t$, $j${"choices": [{"t": "เครื่องดื่มบำรุงกำลัง"}, {"t": "ยาสลบ"}, {"t": "สารกันเสียในอาหาร"}, {"t": "สารป้องกันการแข็งตัวของน้ำในหม้อน้ำรถยนต์"}], "answer": 3}$j$::jsonb, 1, $t$เป็นสารพิษ ห้ามบริโภค$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$เอทิลีนไกลคอล (1,2-เอทานไดออล) ใช้ประโยชน์ในข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$กลีเซอรอล (โพรเพน-1,2,3-ไตรออล) มีหมู่ -OH กี่หมู่$t$, $j${"choices": [{"t": "1 หมู่"}, {"t": "4 หมู่"}, {"t": "2 หมู่"}, {"t": "3 หมู่"}], "answer": 3}$j$::jsonb, 1, $t$ไตรออล = 3 หมู่ -OH$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$กลีเซอรอล (โพรเพน-1,2,3-ไตรออล) มีหมู่ -OH กี่หมู่$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'mcq', $t$CH3OCH3 มีชื่อเรียกว่าอะไร$t$, $j${"choices": [{"t": "ไดเมทิลอีเทอร์"}, {"t": "เมทานอล"}, {"t": "เอทานอล"}, {"t": "เอทิลเมทานอล"}], "answer": 0}$j$::jsonb, 1, $t$R-O-R' ที่ R = R' = CH3$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$CH3OCH3 มีชื่อเรียกว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'tf', $t$อีเทอร์ไม่สามารถสร้างพันธะไฮโดรเจนกับโมเลกุลอีเทอร์ด้วยกันเองได้$t$, $j${"answer": true}$j$::jsonb, 1, $t$ไม่มีไฮโดรเจนต่ออยู่กับออกซิเจน (ไม่มี O-H)$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$อีเทอร์ไม่สามารถสร้างพันธะไฮโดรเจนกับโมเลกุลอีเทอร์ด้วยกันเองได้$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'tf', $t$เอทานอลและไดเมทิลอีเทอร์มีสมบัติทางกายภาพเหมือนกันเพราะสูตรโมเลกุลเดียวกัน$t$, $j${"answer": false}$j$::jsonb, 1, $t$หมู่ฟังก์ชันต่างกัน จุดเดือดและความสามารถในการละลายน้ำต่างกัน$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$เอทานอลและไดเมทิลอีเทอร์มีสมบัติทางกายภาพเหมือนกันเพราะสูตรโมเลกุลเดียวกัน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลกอฮอล์และอีเทอร์$t$, 'match', $t$จับคู่แอลกอฮอล์กับสูตร$t$, $j${"left": [{"t": "เมทานอล"}, {"t": "เอทานอล"}, {"t": "1-โพรพานอล"}, {"t": "2-โพรพานอล"}], "right": [{"t": "CH3CH2CH2OH"}, {"t": "CH3CH2OH"}, {"t": "CH3OCH3"}, {"t": "CH3CH(OH)CH3"}, {"t": "CH3OH"}], "pairs": [4, 1, 0, 3]}$j$::jsonb, 4, $t$ดูตำแหน่ง -OH และจำนวนคาร์บอน$t$
where not exists (select 1 from exam_questions where topic = $t$แอลกอฮอล์และอีเทอร์$t$ and q = $t$จับคู่แอลกอฮอล์กับสูตร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$หมู่ฟังก์ชันของแอลดีไฮด์คือข้อใด$t$, $j${"choices": [{"t": "-CO- ระหว่างคาร์บอน"}, {"t": "-OH"}, {"t": "-CHO"}, {"t": "-COOH"}], "answer": 2}$j$::jsonb, 1, $t$หมู่คาร์บอนิลที่ปลายโซ่ ต่อกับ H$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$หมู่ฟังก์ชันของแอลดีไฮด์คือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$หมู่ฟังก์ชันของคีโตนคือข้อใด$t$, $j${"choices": [{"t": "-OH"}, {"t": "-COO-"}, {"t": "C=O ที่ปลายโซ่ต่อกับ H"}, {"t": "หมู่คาร์บอนิล (C=O) ที่อยู่ระหว่างคาร์บอนสองอะตอม"}], "answer": 3}$j$::jsonb, 1, $t$R-CO-R'$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$หมู่ฟังก์ชันของคีโตนคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$HCHO มีชื่อเรียกว่าอะไร$t$, $j${"choices": [{"t": "เมทานัล (ฟอร์มาลดีไฮด์)"}, {"t": "เมทิลอีเทอร์"}, {"t": "เมทานอล"}, {"t": "กรดฟอร์มิก"}], "answer": 0}$j$::jsonb, 1, $t$แอลดีไฮด์ที่มี 1 คาร์บอน$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$HCHO มีชื่อเรียกว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$CH3CHO มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "กรดเอทาโนอิก"}, {"t": "โพรพาโนน"}, {"t": "เอทานอล"}, {"t": "เอทานัล"}], "answer": 3}$j$::jsonb, 1, $t$ลงท้ายแอลดีไฮด์ -นัล$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$CH3CHO มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$CH3COCH3 มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "2-โพรพานอล"}, {"t": "เอทานัล"}, {"t": "โพรพาโนน (แอซีโทน)"}, {"t": "โพรพานัล"}], "answer": 2}$j$::jsonb, 1, $t$คีโตนลงท้าย -โนน$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$CH3COCH3 มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$แอลดีไฮด์ที่มี 3 คาร์บอนมีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "กรดโพรพาโนอิก"}, {"t": "โพรพานอล"}, {"t": "โพรพาโนน"}, {"t": "โพรพานัล"}], "answer": 3}$j$::jsonb, 1, $t$CH3CH2CHO$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$แอลดีไฮด์ที่มี 3 คาร์บอนมีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$คีโตนที่เล็กที่สุดมีคาร์บอนกี่อะตอม$t$, $j${"choices": [{"t": "1 อะตอม"}, {"t": "3 อะตอม"}, {"t": "2 อะตอม"}, {"t": "4 อะตอม"}], "answer": 1}$j$::jsonb, 1, $t$ต้องมีคาร์บอนอยู่ทั้งสองข้างของ C=O จึงเริ่มที่โพรพาโนน$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$คีโตนที่เล็กที่สุดมีคาร์บอนกี่อะตอม$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$แอลดีไฮด์และคีโตนที่มีจำนวนคาร์บอนเท่ากันเป็นไอโซเมอร์ชนิดใด$t$, $j${"choices": [{"t": "ไอโซเมอร์ตำแหน่ง"}, {"t": "ไอโซเมอร์โซ่คาร์บอน"}, {"t": "ไอโซเมอร์ต่างหมู่ฟังก์ชัน"}, {"t": "ไอโซเมอร์เรขาคณิต"}], "answer": 2}$j$::jsonb, 1, $t$เช่น โพรพานัลกับโพรพาโนน (C3H6O)$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$แอลดีไฮด์และคีโตนที่มีจำนวนคาร์บอนเท่ากันเป็นไอโซเมอร์ชนิดใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$สารละลายเบเนดิกต์ (Benedict) ใช้ทดสอบสมบัติใดของแอลดีไฮด์$t$, $j${"choices": [{"t": "การเกิดเอสเทอร์ ได้กลิ่นหอม"}, {"t": "การไม่อิ่มตัว สีจางหาย"}, {"t": "ความสามารถในการรีดิวซ์ ได้ตะกอนสีแดงอิฐ"}, {"t": "ความเป็นกรด ได้สารละลายสีเหลือง"}], "answer": 2}$j$::jsonb, 1, $t$แอลดีไฮด์ถูกออกซิไดส์เป็นกรด และ Cu2+ ถูกรีดิวซ์เป็น Cu2O (ตะกอนแดงอิฐ)$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$สารละลายเบเนดิกต์ (Benedict) ใช้ทดสอบสมบัติใดของแอลดีไฮด์$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$ปฏิกิริยากระจกเงิน (ทอลเลนส์) ให้ผลบวกกับสารใด$t$, $j${"choices": [{"t": "แอลคีน"}, {"t": "คีโตน"}, {"t": "อีเทอร์"}, {"t": "แอลดีไฮด์"}], "answer": 3}$j$::jsonb, 1, $t$Ag+ ถูกรีดิวซ์เป็นโลหะ Ag เกาะผนังเป็นกระจกเงา$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$ปฏิกิริยากระจกเงิน (ทอลเลนส์) ให้ผลบวกกับสารใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$ข้อใดแยกเอทานัลออกจากโพรพาโนนได้ด้วยสารละลายเบเนดิกต์$t$, $j${"choices": [{"t": "ทั้งสองให้ตะกอนสีแดงอิฐ"}, {"t": "ทั้งสองไม่เกิดการเปลี่ยนแปลง"}, {"t": "เอทานัลให้ตะกอนสีแดงอิฐ ส่วนโพรพาโนนไม่เกิดตะกอน"}, {"t": "โพรพาโนนให้ตะกอนสีแดงอิฐ ส่วนเอทานัลไม่เกิด"}], "answer": 2}$j$::jsonb, 1, $t$คีโตนไม่ถูกออกซิไดส์ง่ายเหมือนแอลดีไฮด์$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$ข้อใดแยกเอทานัลออกจากโพรพาโนนได้ด้วยสารละลายเบเนดิกต์$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$การออกซิไดส์แอลดีไฮด์ให้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "อีเทอร์"}, {"t": "คีโตน"}, {"t": "แอลกอฮอล์ตติยภูมิ"}, {"t": "กรดคาร์บอกซิลิก"}], "answer": 3}$j$::jsonb, 1, $t$RCHO → RCOOH$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$การออกซิไดส์แอลดีไฮด์ให้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$การรีดิวซ์โพรพาโนนด้วย H2 (ตัวเร่ง) ได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "โพรพานัล"}, {"t": "2-โพรพานอล"}, {"t": "1-โพรพานอล"}, {"t": "โพรเพน"}], "answer": 1}$j$::jsonb, 1, $t$คีโตนรีดิวซ์เป็นแอลกอฮอล์ทุติยภูมิ$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$การรีดิวซ์โพรพาโนนด้วย H2 (ตัวเร่ง) ได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$การรีดิวซ์แอลดีไฮด์ให้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "กรดคาร์บอกซิลิก"}, {"t": "แอลกอฮอล์ปฐมภูมิ"}, {"t": "คีโตน"}, {"t": "แอลกอฮอล์ทุติยภูมิ"}], "answer": 1}$j$::jsonb, 1, $t$RCHO + H2 → RCH2OH$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$การรีดิวซ์แอลดีไฮด์ให้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$ฟอร์มาลีน (สารละลายฟอร์มาลดีไฮด์ในน้ำ) ใช้ประโยชน์ในข้อใด$t$, $j${"choices": [{"t": "ใช้เป็นเชื้อเพลิงรถยนต์"}, {"t": "ใช้เป็นสารให้ความหวาน"}, {"t": "ผสมในเครื่องดื่ม"}, {"t": "ดองรักษาสภาพตัวอย่างสิ่งมีชีวิต"}], "answer": 3}$j$::jsonb, 1, $t$ฟอร์มาลีนเป็นพิษ ห้ามใช้กับอาหาร$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$ฟอร์มาลีน (สารละลายฟอร์มาลดีไฮด์ในน้ำ) ใช้ประโยชน์ในข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$แอซีโทนมีประโยชน์หลักในข้อใด$t$, $j${"choices": [{"t": "เป็นตัวทำละลาย เช่น ล้างน้ำยาทาเล็บ"}, {"t": "เป็นสารกันบูดในอาหาร"}, {"t": "เป็นปุ๋ยพืช"}, {"t": "เป็นสารให้ความหวาน"}], "answer": 0}$j$::jsonb, 1, $t$แอซีโทนละลายสารอินทรีย์ได้ดีและระเหยง่าย$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$แอซีโทนมีประโยชน์หลักในข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$เหตุใดแอลดีไฮด์ที่มีคาร์บอนน้อยๆ จึงละลายน้ำได้$t$, $j${"choices": [{"t": "เป็นสารไม่มีขั้ว"}, {"t": "มีไฮโดรเจนต่อกับออกซิเจน"}, {"t": "ออกซิเจนของ C=O สร้างพันธะไฮโดรเจนกับน้ำได้"}, {"t": "มีพันธะไอออนิก"}], "answer": 2}$j$::jsonb, 1, $t$แอลดีไฮด์และคีโตนไม่มี O-H ในโมเลกุลตัวเอง แต่รับพันธะไฮโดรเจนจากน้ำได้$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$เหตุใดแอลดีไฮด์ที่มีคาร์บอนน้อยๆ จึงละลายน้ำได้$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$จุดเดือดของแอลดีไฮด์/คีโตนเมื่อเทียบกับแอลกอฮอล์ที่มีมวลโมเลกุลใกล้เคียงกันเป็นอย่างไร$t$, $j${"choices": [{"t": "ต่ำกว่า เพราะไม่มีพันธะไฮโดรเจนระหว่างโมเลกุลชนิดเดียวกัน"}, {"t": "สูงกว่า เพราะมีพันธะคู่"}, {"t": "เท่ากัน"}, {"t": "สูงกว่า เพราะมีพันธะไอออนิก"}], "answer": 0}$j$::jsonb, 1, $t$มีขั้วจึงสูงกว่าแอลเคน แต่ต่ำกว่าแอลกอฮอล์$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$จุดเดือดของแอลดีไฮด์/คีโตนเมื่อเทียบกับแอลกอฮอล์ที่มีมวลโมเลกุลใกล้เคียงกันเป็นอย่างไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'mcq', $t$เบนซัลดีไฮด์ต่างจากเบนซีนที่หมู่ฟังก์ชันใด$t$, $j${"choices": [{"t": "มีหมู่ -OH"}, {"t": "มีหมู่ -CHO ต่ออยู่กับวงแหวน"}, {"t": "มีหมู่ -NH2"}, {"t": "มีหมู่ -COOH"}], "answer": 1}$j$::jsonb, 1, $t$C6H5CHO เป็นแอลดีไฮด์อะโรมาติก (กลิ่นอัลมอนด์)$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$เบนซัลดีไฮด์ต่างจากเบนซีนที่หมู่ฟังก์ชันใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'tf', $t$คีโตนให้ผลบวกกับปฏิกิริยากระจกเงาของทอลเลนส์$t$, $j${"answer": false}$j$::jsonb, 1, $t$คีโตนไม่ถูกออกซิไดส์ง่าย จึงไม่ให้กระจกเงา$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$คีโตนให้ผลบวกกับปฏิกิริยากระจกเงาของทอลเลนส์$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'tf', $t$แอลดีไฮด์ถูกออกซิไดส์เป็นกรดคาร์บอกซิลิกได้ง่าย$t$, $j${"answer": true}$j$::jsonb, 1, $t$เป็นเหตุผลที่แอลดีไฮด์ให้ผลบวกกับเบเนดิกต์และทอลเลนส์$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$แอลดีไฮด์ถูกออกซิไดส์เป็นกรดคาร์บอกซิลิกได้ง่าย$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'tf', $t$แอซีโทนเป็นแอลดีไฮด์ที่เล็กที่สุด$t$, $j${"answer": false}$j$::jsonb, 1, $t$แอซีโทนเป็นคีโตน ส่วนแอลดีไฮด์ที่เล็กที่สุดคือเมทานัล$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$แอซีโทนเป็นแอลดีไฮด์ที่เล็กที่สุด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$แอลดีไฮด์และคีโตน$t$, 'match', $t$จับคู่ชื่อแอลดีไฮด์และคีโตนกับสูตร$t$, $j${"left": [{"t": "เมทานัล"}, {"t": "เอทานัล"}, {"t": "โพรพาโนน"}, {"t": "เบนซัลดีไฮด์"}], "right": [{"t": "C6H5CHO"}, {"t": "CH3COOH"}, {"t": "CH3COCH3"}, {"t": "HCHO"}, {"t": "CH3CHO"}], "pairs": [3, 4, 2, 0]}$j$::jsonb, 4, $t$ดูหมู่คาร์บอนิล$t$
where not exists (select 1 from exam_questions where topic = $t$แอลดีไฮด์และคีโตน$t$ and q = $t$จับคู่ชื่อแอลดีไฮด์และคีโตนกับสูตร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$หมู่ฟังก์ชันของกรดคาร์บอกซิลิกคือข้อใด$t$, $j${"choices": [{"t": "-OH"}, {"t": "-COOH"}, {"t": "-COO- ระหว่างคาร์บอน"}, {"t": "-CHO"}], "answer": 1}$j$::jsonb, 1, $t$หมู่คาร์บอกซิล$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$หมู่ฟังก์ชันของกรดคาร์บอกซิลิกคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$CH3COOH มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "เอทานัล"}, {"t": "กรดเอทาโนอิก"}, {"t": "กรดเมทาโนอิก"}, {"t": "เอทานอล"}], "answer": 1}$j$::jsonb, 1, $t$2 คาร์บอน (รวมคาร์บอนของ -COOH) ลงท้าย -โนอิก$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$CH3COOH มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$HCOOH มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "เมทานอล"}, {"t": "กรดเอทาโนอิก"}, {"t": "เมทานัล"}, {"t": "กรดเมทาโนอิก"}], "answer": 3}$j$::jsonb, 1, $t$กรดฟอร์มิก พบในมดและต่อ$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$HCOOH มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$CH3CH2COOH มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "โพรพาโนน"}, {"t": "กรดโพรพาโนอิก"}, {"t": "กรดบิวทาโนอิก"}, {"t": "โพรพานัล"}], "answer": 1}$j$::jsonb, 1, $t$3 คาร์บอน$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$CH3CH2COOH มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$น้ำส้มสายชูมีกรดชนิดใดเป็นองค์ประกอบหลัก$t$, $j${"choices": [{"t": "กรดไฮโดรคลอริก"}, {"t": "กรดเอทาโนอิก (แอซีติก)"}, {"t": "กรดเมทาโนอิก"}, {"t": "กรดซิตริก"}], "answer": 1}$j$::jsonb, 1, $t$น้ำส้มสายชูมีกรดแอซีติกประมาณ 4-7%$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$น้ำส้มสายชูมีกรดชนิดใดเป็นองค์ประกอบหลัก$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$กรดคาร์บอกซิลิกจัดเป็นกรดประเภทใด$t$, $j${"choices": [{"t": "กรดแก่"}, {"t": "สารที่เป็นกลาง"}, {"t": "กรดอ่อน"}, {"t": "เบสอ่อน"}], "answer": 2}$j$::jsonb, 1, $t$แตกตัวเป็นไอออนได้บางส่วนในน้ำ$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$กรดคาร์บอกซิลิกจัดเป็นกรดประเภทใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$กรดเอทาโนอิกทำปฏิกิริยากับ NaOH ได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "เอทิลเอทาโนเอตและน้ำ"}, {"t": "เอทานัลและน้ำ"}, {"t": "เอทานอลและโซเดียม"}, {"t": "โซเดียมเอทาโนเอตและน้ำ"}], "answer": 3}$j$::jsonb, 1, $t$CH3COOH + NaOH → CH3COONa + H2O$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$กรดเอทาโนอิกทำปฏิกิริยากับ NaOH ได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$กรดเอทาโนอิกทำปฏิกิริยากับ NaHCO3 ได้แก๊สใด$t$, $j${"choices": [{"t": "CO2"}, {"t": "NH3"}, {"t": "O2"}, {"t": "H2"}], "answer": 0}$j$::jsonb, 1, $t$กรดคาร์บอกซิลิกแรงกว่ากรดคาร์บอนิก จึงดันให้เกิด CO2$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$กรดเอทาโนอิกทำปฏิกิริยากับ NaHCO3 ได้แก๊สใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$กรดคาร์บอกซิลิกมีจุดเดือดสูงกว่าแอลกอฮอล์ที่มีมวลโมเลกุลใกล้เคียงกัน เพราะเหตุใด$t$, $j${"choices": [{"t": "ไม่มีขั้ว"}, {"t": "สร้างพันธะไฮโดรเจนได้แข็งแรงกว่า (เกิดคู่โมเลกุลไดเมอร์)"}, {"t": "มีพันธะไอออนิก"}, {"t": "มีพันธะคู่ C=C"}], "answer": 1}$j$::jsonb, 1, $t$หมู่ -COOH สร้างพันธะไฮโดรเจนระหว่างโมเลกุล 2 จุด$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$กรดคาร์บอกซิลิกมีจุดเดือดสูงกว่าแอลกอฮอล์ที่มีมวลโมเลกุลใกล้เคียงกัน เพราะเหตุใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$ปฏิกิริยาระหว่างกรดคาร์บอกซิลิกกับแอลกอฮอล์เรียกว่าอะไร$t$, $j${"choices": [{"t": "ไฮโดรจีเนชัน"}, {"t": "ไนเตรชัน"}, {"t": "การหมัก"}, {"t": "เอสเทอริฟิเคชัน"}], "answer": 3}$j$::jsonb, 1, $t$ได้เอสเทอร์และน้ำ$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$ปฏิกิริยาระหว่างกรดคาร์บอกซิลิกกับแอลกอฮอล์เรียกว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$เอสเทอริฟิเคชันมักใช้ตัวเร่งปฏิกิริยาใด$t$, $j${"choices": [{"t": "FeBr3"}, {"t": "กรดซัลฟิวริกเข้มข้น"}, {"t": "โลหะนิกเกิล"}, {"t": "โพแทสเซียมเปอร์แมงกาเนต"}], "answer": 1}$j$::jsonb, 1, $t$H2SO4 เข้มข้นเป็นทั้งตัวเร่งและดูดน้ำ$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$เอสเทอริฟิเคชันมักใช้ตัวเร่งปฏิกิริยาใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$CH3COOH + CH3OH → (H2SO4) ได้เอสเทอร์ชื่อใด$t$, $j${"choices": [{"t": "เมทิลเมทาโนเอต"}, {"t": "เอทิลเมทาโนเอต"}, {"t": "เอทิลเอทาโนเอต"}, {"t": "เมทิลเอทาโนเอต"}], "answer": 3}$j$::jsonb, 1, $t$ชื่อหมู่อัลคิลจากแอลกอฮอล์ + ชื่อส่วนกรดลงท้าย -โนเอต$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$CH3COOH + CH3OH → (H2SO4) ได้เอสเทอร์ชื่อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$เอสเทอร์ที่ได้จากกรดเมทาโนอิกและเอทานอลชื่อว่าอะไร$t$, $j${"choices": [{"t": "เอทิลเอทาโนเอต"}, {"t": "เมทิลเอทาโนเอต"}, {"t": "เอทิลเมทาโนเอต"}, {"t": "เมทิลเมทาโนเอต"}], "answer": 2}$j$::jsonb, 1, $t$เอทิลจากเอทานอล + เมทาโนเอตจากกรดเมทาโนอิก$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$เอสเทอร์ที่ได้จากกรดเมทาโนอิกและเอทานอลชื่อว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$เอสเทอร์ CH3COOCH2CH3 มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "เมทิลเอทาโนเอต"}, {"t": "เอทิลโพรพาโนเอต"}, {"t": "เมทิลโพรพาโนเอต"}, {"t": "เอทิลเอทาโนเอต"}], "answer": 3}$j$::jsonb, 1, $t$กรดเอทาโนอิก + เอทานอล$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$เอสเทอร์ CH3COOCH2CH3 มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$หมู่ฟังก์ชันของเอสเทอร์คือข้อใด$t$, $j${"choices": [{"t": "-CO- ระหว่างคาร์บอน"}, {"t": "-COOH"}, {"t": "-COO- (ต่อกับหมู่อัลคิลทั้งสองด้าน)"}, {"t": "-CONH2"}], "answer": 2}$j$::jsonb, 1, $t$R-COO-R'$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$หมู่ฟังก์ชันของเอสเทอร์คือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$เอสเทอร์มีสมบัติเด่นข้อใด$t$, $j${"choices": [{"t": "มักมีกลิ่นหอมคล้ายผลไม้"}, {"t": "เป็นสารที่ละลายน้ำได้ดีมาก"}, {"t": "มีกลิ่นฉุนเหมือนปลา"}, {"t": "มีรสเปรี้ยวจัด"}], "answer": 0}$j$::jsonb, 1, $t$ใช้เป็นสารแต่งกลิ่นรส$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$เอสเทอร์มีสมบัติเด่นข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$เอสเทอร์ที่ให้กลิ่นกล้วยหอมคือข้อใด$t$, $j${"choices": [{"t": "เอทิลเมทาโนเอต"}, {"t": "กรดบิวทาโนอิก"}, {"t": "เมทิลซาลิไซเลต"}, {"t": "เพนทิลเอทาโนเอต"}], "answer": 3}$j$::jsonb, 1, $t$เพนทิลแอซีเตต ใช้แต่งกลิ่นกล้วย$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$เอสเทอร์ที่ให้กลิ่นกล้วยหอมคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$ปฏิกิริยาไฮโดรไลซิสของเอสเทอร์ด้วยกรดให้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "คีโตนและแก๊สไฮโดรเจน"}, {"t": "แอลคีนและน้ำ"}, {"t": "กรดคาร์บอกซิลิกและแอลกอฮอล์"}, {"t": "แอลดีไฮด์และน้ำ"}], "answer": 2}$j$::jsonb, 1, $t$ย้อนกลับของเอสเทอริฟิเคชัน$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$ปฏิกิริยาไฮโดรไลซิสของเอสเทอร์ด้วยกรดให้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$ปฏิกิริยาของเอสเทอร์กับสารละลาย NaOH (สะปอนนิฟิเคชัน) ได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "กรดคาร์บอกซิลิกและแอลกอฮอล์"}, {"t": "แอลดีไฮด์และเกลือ"}, {"t": "เกลือของกรดคาร์บอกซิลิกและแอลกอฮอล์"}, {"t": "แอลเคนและเกลือ"}], "answer": 2}$j$::jsonb, 1, $t$RCOOR' + NaOH → RCOONa + R'OH$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$ปฏิกิริยาของเอสเทอร์กับสารละลาย NaOH (สะปอนนิฟิเคชัน) ได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$C2H4O2 มีไอโซเมอร์ที่เป็นกรดและเอสเทอร์ ได้แก่คู่ใด$t$, $j${"choices": [{"t": "เอทานอล กับ เอทานัล"}, {"t": "โพรพาโนน กับ โพรพานัล"}, {"t": "เอทีน กับ เอเทน"}, {"t": "กรดเอทาโนอิก กับ เมทิลเมทาโนเอต"}], "answer": 3}$j$::jsonb, 1, $t$CH3COOH กับ HCOOCH3$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$C2H4O2 มีไอโซเมอร์ที่เป็นกรดและเอสเทอร์ ได้แก่คู่ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'mcq', $t$สารใดมีจุดเดือดสูงที่สุด (มวลโมเลกุลใกล้เคียงกัน)$t$, $j${"choices": [{"t": "แอลเคน"}, {"t": "แอลดีไฮด์"}, {"t": "กรดคาร์บอกซิลิก"}, {"t": "เอสเทอร์"}], "answer": 2}$j$::jsonb, 1, $t$กรดมีพันธะไฮโดรเจนระหว่างโมเลกุลแข็งแรงที่สุด$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$สารใดมีจุดเดือดสูงที่สุด (มวลโมเลกุลใกล้เคียงกัน)$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'tf', $t$กรดคาร์บอกซิลิกเปลี่ยนสีกระดาษลิตมัสสีน้ำเงินเป็นสีแดง$t$, $j${"answer": true}$j$::jsonb, 1, $t$มีสมบัติเป็นกรด$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$กรดคาร์บอกซิลิกเปลี่ยนสีกระดาษลิตมัสสีน้ำเงินเป็นสีแดง$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'tf', $t$เอสเทอริฟิเคชันเป็นปฏิกิริยาที่เกิดน้ำเป็นผลพลอยได้$t$, $j${"answer": true}$j$::jsonb, 1, $t$RCOOH + R'OH ⇌ RCOOR' + H2O$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$เอสเทอริฟิเคชันเป็นปฏิกิริยาที่เกิดน้ำเป็นผลพลอยได้$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'tf', $t$กรดแอซีติกเป็นกรดแก่ที่แตกตัวได้สมบูรณ์ในน้ำ$t$, $j${"answer": false}$j$::jsonb, 1, $t$เป็นกรดอ่อน แตกตัวได้เพียงบางส่วน$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$กรดแอซีติกเป็นกรดแก่ที่แตกตัวได้สมบูรณ์ในน้ำ$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$, 'match', $t$จับคู่ชื่อสารกับสูตร$t$, $j${"left": [{"t": "กรดเมทาโนอิก"}, {"t": "กรดเอทาโนอิก"}, {"t": "เมทิลเอทาโนเอต"}, {"t": "เอทิลเอทาโนเอต"}], "right": [{"t": "CH3COOCH2CH3"}, {"t": "CH3COOCH3"}, {"t": "HCOOCH3"}, {"t": "CH3COOH"}, {"t": "HCOOH"}], "pairs": [4, 3, 1, 0]}$j$::jsonb, 4, $t$ชื่อเอสเทอร์เรียงอัลคิลจากแอลกอฮอล์ก่อน$t$
where not exists (select 1 from exam_questions where topic = $t$กรดคาร์บอกซิลิกและเอสเทอร์$t$ and q = $t$จับคู่ชื่อสารกับสูตร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$หมู่ฟังก์ชันของเอมีนคือข้อใด$t$, $j${"choices": [{"t": "หมู่ที่มีไนโตรเจนต่ออยู่กับหมู่อัลคิลหรืออะริล เช่น -NH2"}, {"t": "-CHO"}, {"t": "-OH"}, {"t": "-COOH"}], "answer": 0}$j$::jsonb, 1, $t$เอมีนเป็นอนุพันธ์ของแอมโมเนีย$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$หมู่ฟังก์ชันของเอมีนคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$CH3NH2 มีชื่อเรียกว่าอะไร$t$, $j${"choices": [{"t": "เมทานอล"}, {"t": "เมทานามีน (เมทิลเอมีน)"}, {"t": "เมทานัล"}, {"t": "กรดเมทาโนอิก"}], "answer": 1}$j$::jsonb, 1, $t$เอมีนปฐมภูมิที่เล็กที่สุด$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$CH3NH2 มีชื่อเรียกว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$CH3CH2NH2 มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "เอทานามีน"}, {"t": "เอไมด์"}, {"t": "เอทานอล"}, {"t": "เอทานัล"}], "answer": 0}$j$::jsonb, 1, $t$2 คาร์บอน + เอมีน$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$CH3CH2NH2 มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$(CH3)2NH จัดเป็นเอมีนประเภทใด$t$, $j${"choices": [{"t": "เอไมด์"}, {"t": "เอมีนปฐมภูมิ (1°)"}, {"t": "เอมีนตติยภูมิ (3°)"}, {"t": "เอมีนทุติยภูมิ (2°)"}], "answer": 3}$j$::jsonb, 1, $t$ไนโตรเจนต่อกับหมู่อัลคิล 2 หมู่$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$(CH3)2NH จัดเป็นเอมีนประเภทใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$(CH3)3N จัดเป็นเอมีนประเภทใด$t$, $j${"choices": [{"t": "เอไมด์"}, {"t": "เอมีนปฐมภูมิ (1°)"}, {"t": "เอมีนทุติยภูมิ (2°)"}, {"t": "เอมีนตติยภูมิ (3°)"}], "answer": 3}$j$::jsonb, 1, $t$ไนโตรเจนต่อกับหมู่อัลคิล 3 หมู่$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$(CH3)3N จัดเป็นเอมีนประเภทใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$เอมีนมีสมบัติทางเคมีข้อใด$t$, $j${"choices": [{"t": "เป็นกลางเสมอ"}, {"t": "เป็นกรดแก่"}, {"t": "เป็นเบสอ่อน"}, {"t": "เป็นตัวออกซิไดส์รุนแรง"}], "answer": 2}$j$::jsonb, 1, $t$คู่อิเล็กตรอนอิสระบนไนโตรเจนรับโปรตอนได้$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$เอมีนมีสมบัติทางเคมีข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$เมื่อเอมีนทำปฏิกิริยากับ HCl จะได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "แอลกอฮอล์"}, {"t": "เอไมด์"}, {"t": "กรดคาร์บอกซิลิก"}, {"t": "เกลือแอมโมเนียม (เอมีนไฮโดรคลอไรด์)"}], "answer": 3}$j$::jsonb, 1, $t$RNH2 + HCl → RNH3+Cl-$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$เมื่อเอมีนทำปฏิกิริยากับ HCl จะได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$เอมีนโมเลกุลเล็กมักมีกลิ่นลักษณะใด$t$, $j${"choices": [{"t": "กลิ่นคาวปลา"}, {"t": "ไม่มีกลิ่น"}, {"t": "กลิ่นหอมหวานผลไม้"}, {"t": "กลิ่นน้ำส้มสายชู"}], "answer": 0}$j$::jsonb, 1, $t$เช่น ไตรเมทิลเอมีนในปลาเน่า$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$เอมีนโมเลกุลเล็กมักมีกลิ่นลักษณะใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$เอมีนชนิดใดที่ไม่สามารถสร้างพันธะไฮโดรเจนกับโมเลกุลชนิดเดียวกัน$t$, $j${"choices": [{"t": "เอมีนทุติยภูมิ"}, {"t": "เอมีนปฐมภูมิ"}, {"t": "เอมีนตติยภูมิ"}, {"t": "ทุกชนิดสร้างได้"}], "answer": 2}$j$::jsonb, 1, $t$ไม่มี N-H$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$เอมีนชนิดใดที่ไม่สามารถสร้างพันธะไฮโดรเจนกับโมเลกุลชนิดเดียวกัน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$หมู่ฟังก์ชันของเอไมด์คือข้อใด$t$, $j${"choices": [{"t": "-COOR"}, {"t": "-NH2"}, {"t": "-COOH"}, {"t": "-CONH2 (หรือ -CONHR, -CONR2)"}], "answer": 3}$j$::jsonb, 1, $t$คาร์บอนิลต่อกับไนโตรเจน$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$หมู่ฟังก์ชันของเอไมด์คือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$CH3CONH2 มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "กรดเอทาโนอิก"}, {"t": "เอทานามีน"}, {"t": "เมทิลเอทาโนเอต"}, {"t": "เอทานาไมด์"}], "answer": 3}$j$::jsonb, 1, $t$ชื่อเอไมด์ลงท้าย -าไมด์$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$CH3CONH2 มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$เอไมด์เกิดจากปฏิกิริยาระหว่างสารคู่ใด$t$, $j${"choices": [{"t": "แอลดีไฮด์กับแอลกอฮอล์"}, {"t": "แอลคีนกับน้ำ"}, {"t": "กรดคาร์บอกซิลิกกับแอลกอฮอล์"}, {"t": "กรดคาร์บอกซิลิกกับเอมีนหรือแอมโมเนีย"}], "answer": 3}$j$::jsonb, 1, $t$เกิดพันธะเอไมด์ พร้อมเสียน้ำ$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$เอไมด์เกิดจากปฏิกิริยาระหว่างสารคู่ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$พันธะเปปไทด์ในโปรตีนคือพันธะชนิดใดทางเคมีอินทรีย์$t$, $j${"choices": [{"t": "พันธะเอไมด์"}, {"t": "พันธะไกลโคซิดิก"}, {"t": "พันธะอีเทอร์"}, {"t": "พันธะเอสเทอร์"}], "answer": 0}$j$::jsonb, 1, $t$-CO-NH-$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$พันธะเปปไทด์ในโปรตีนคือพันธะชนิดใดทางเคมีอินทรีย์$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$ยูเรีย (NH2)2CO มีหมู่ฟังก์ชันใดเด่นชัด$t$, $j${"choices": [{"t": "เอสเทอร์"}, {"t": "เอไมด์"}, {"t": "อีเทอร์"}, {"t": "แอลดีไฮด์"}], "answer": 1}$j$::jsonb, 1, $t$คาร์บอนิลต่อกับ -NH2 สองหมู่$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$ยูเรีย (NH2)2CO มีหมู่ฟังก์ชันใดเด่นชัด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$เอไมด์โดยทั่วไปมีสมบัติทางกรด-เบสอย่างไร$t$, $j${"choices": [{"t": "เกือบเป็นกลาง (เป็นเบสอ่อนมาก)"}, {"t": "เป็นกรดแก่"}, {"t": "เป็นเบสแก่"}, {"t": "เป็นกรดอ่อนกว่ากรดคาร์บอกซิลิกมาก"}], "answer": 0}$j$::jsonb, 1, $t$คู่อิเล็กตรอนของ N เกิดเรโซแนนซ์กับ C=O$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$เอไมด์โดยทั่วไปมีสมบัติทางกรด-เบสอย่างไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$แอนิลีนจัดเป็นเอมีนประเภทใด$t$, $j${"choices": [{"t": "เอไมด์"}, {"t": "เอมีนอะโรมาติกปฐมภูมิ"}, {"t": "เอสเทอร์"}, {"t": "เอมีนทุติยภูมิ"}], "answer": 1}$j$::jsonb, 1, $t$C6H5NH2$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$แอนิลีนจัดเป็นเอมีนประเภทใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'mcq', $t$สารกลุ่มไนโตรเจนใดมีจุดเดือดสูงที่สุด (มวลโมเลกุลใกล้เคียงกัน)$t$, $j${"choices": [{"t": "อีเทอร์"}, {"t": "แอลเคน"}, {"t": "เอไมด์ปฐมภูมิ"}, {"t": "เอมีนตติยภูมิ"}], "answer": 2}$j$::jsonb, 1, $t$เอไมด์สร้างพันธะไฮโดรเจนหลายตำแหน่ง$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$สารกลุ่มไนโตรเจนใดมีจุดเดือดสูงที่สุด (มวลโมเลกุลใกล้เคียงกัน)$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'tf', $t$เอมีนเกิดจากการแทนที่ H ในโมเลกุลแอมโมเนียด้วยหมู่อัลคิล$t$, $j${"answer": true}$j$::jsonb, 1, $t$เช่น NH3 → CH3NH2$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$เอมีนเกิดจากการแทนที่ H ในโมเลกุลแอมโมเนียด้วยหมู่อัลคิล$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'tf', $t$เอไมด์มีสมบัติเป็นเบสแรงกว่าเอมีนเสมอ$t$, $j${"answer": false}$j$::jsonb, 1, $t$เอมีนเป็นเบสแรงกว่าเอไมด์$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$เอไมด์มีสมบัติเป็นเบสแรงกว่าเอมีนเสมอ$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$เอมีนและเอไมด์$t$, 'match', $t$จับคู่สารกับหมู่ฟังก์ชัน$t$, $j${"left": [{"t": "CH3NH2"}, {"t": "CH3CONH2"}, {"t": "CH3COOH"}, {"t": "CH3COOCH3"}], "right": [{"t": "เอมีน"}, {"t": "เอไมด์"}, {"t": "แอลดีไฮด์"}, {"t": "เอสเทอร์"}, {"t": "กรดคาร์บอกซิลิก"}], "pairs": [0, 1, 4, 3]}$j$::jsonb, 4, $t$ดูอะตอมที่ต่อกับคาร์บอนิล$t$
where not exists (select 1 from exam_questions where topic = $t$เอมีนและเอไมด์$t$ and q = $t$จับคู่สารกับหมู่ฟังก์ชัน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$CH3CH2Cl จัดเป็นสารประกอบประเภทใด$t$, $j${"choices": [{"t": "แอลกอฮอล์"}, {"t": "เอไมด์"}, {"t": "เฮโลแอลเคน (แอลคิลเฮไลด์)"}, {"t": "เอสเทอร์"}], "answer": 2}$j$::jsonb, 1, $t$มีอะตอมฮาโลเจนต่อกับคาร์บอนอิ่มตัว$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$CH3CH2Cl จัดเป็นสารประกอบประเภทใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$CH3Cl มีชื่อ IUPAC ว่าอะไร$t$, $j${"choices": [{"t": "ไดคลอโรมีเทน"}, {"t": "เมทิลคลอไรด์เมทานอล"}, {"t": "คลอโรอีเทน"}, {"t": "คลอโรมีเทน"}], "answer": 3}$j$::jsonb, 1, $t$ใช้ชื่อฮาโลเจนนำหน้าชื่อแอลเคน$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$CH3Cl มีชื่อ IUPAC ว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$CCl4 มีชื่อเรียกว่าอะไร$t$, $j${"choices": [{"t": "เตตระคลอโรมีเทน (คาร์บอนเตตระคลอไรด์)"}, {"t": "คลอโรมีเทน"}, {"t": "ไตรคลอโรมีเทน"}, {"t": "ไดคลอโรมีเทน"}], "answer": 0}$j$::jsonb, 1, $t$คาร์บอน 1 อะตอมต่อ Cl 4 อะตอม$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$CCl4 มีชื่อเรียกว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$CHCl3 มีชื่อสามัญว่าอะไร$t$, $j${"choices": [{"t": "แอซีโทน"}, {"t": "ฟอร์มาลีน"}, {"t": "คลอโรฟอร์ม"}, {"t": "เอทานอล"}], "answer": 2}$j$::jsonb, 1, $t$ไตรคลอโรมีเทน เคยใช้เป็นยาสลบ$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$CHCl3 มีชื่อสามัญว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$CFC (คลอโรฟลูออโรคาร์บอน) ส่งผลเสียต่อสิ่งแวดล้อมในข้อใด$t$, $j${"choices": [{"t": "ทำให้ดินเป็นด่าง"}, {"t": "ทำให้เกิดฝนกรดโดยตรง"}, {"t": "ทำให้น้ำทะเลเค็มขึ้น"}, {"t": "ทำลายชั้นโอโซนในบรรยากาศ"}], "answer": 3}$j$::jsonb, 1, $t$อะตอม Cl ถูกปล่อยออกมาทำลาย O3$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$CFC (คลอโรฟลูออโรคาร์บอน) ส่งผลเสียต่อสิ่งแวดล้อมในข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$เฮโลแอลเคนโดยทั่วไปละลายในน้ำได้หรือไม่$t$, $j${"choices": [{"t": "แตกตัวเป็นไอออนในน้ำสมบูรณ์"}, {"t": "ละลายได้น้อยมาก"}, {"t": "ละลายได้ดีมาก"}, {"t": "ทำปฏิกิริยากับน้ำรุนแรงเสมอ"}], "answer": 1}$j$::jsonb, 1, $t$มีขั้วเล็กน้อย ไม่สร้างพันธะไฮโดรเจนกับน้ำได้ดี$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$เฮโลแอลเคนโดยทั่วไปละลายในน้ำได้หรือไม่$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$สารใดต่อไปนี้เป็นเอสเทอร์$t$, $j${"choices": [{"t": "CH3CONH2"}, {"t": "CH3COOCH3"}, {"t": "CH3CH2CHO"}, {"t": "CH3CH2OCH3"}], "answer": 1}$j$::jsonb, 1, $t$มีหมู่ -COO- ต่อกับหมู่อัลคิลสองด้าน$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$สารใดต่อไปนี้เป็นเอสเทอร์$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$สารใดต่อไปนี้เป็นอีเทอร์$t$, $j${"choices": [{"t": "CH3COCH3"}, {"t": "CH3COOCH3"}, {"t": "CH3OCH2CH3"}, {"t": "CH3CH2CH2OH"}], "answer": 2}$j$::jsonb, 1, $t$R-O-R' ไม่มี C=O$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$สารใดต่อไปนี้เป็นอีเทอร์$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$สารใดต่อไปนี้มีทั้งหมู่ -OH และ -COOH ในโมเลกุลเดียวกัน$t$, $j${"choices": [{"t": "กรดแลกติก CH3CH(OH)COOH"}, {"t": "เมทิลเอทาโนเอต"}, {"t": "เอทานอล"}, {"t": "กรดเอทาโนอิก"}], "answer": 0}$j$::jsonb, 1, $t$เป็นกรดไฮดรอกซี$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$สารใดต่อไปนี้มีทั้งหมู่ -OH และ -COOH ในโมเลกุลเดียวกัน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$เรียงลำดับจุดเดือดจากต่ำไปสูงของสารที่มีมวลโมเลกุลใกล้เคียงกัน ข้อใดถูกต้อง$t$, $j${"choices": [{"t": "แอลกอฮอล์ < กรดคาร์บอกซิลิก < แอลเคน < อีเทอร์"}, {"t": "อีเทอร์ < แอลเคน < กรดคาร์บอกซิลิก < แอลกอฮอล์"}, {"t": "แอลเคน < อีเทอร์ < แอลดีไฮด์/คีโตน < แอลกอฮอล์ < กรดคาร์บอกซิลิก"}, {"t": "กรดคาร์บอกซิลิก < แอลกอฮอล์ < คีโตน < แอลเคน"}], "answer": 2}$j$::jsonb, 1, $t$ขึ้นกับขั้วและพันธะไฮโดรเจน$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$เรียงลำดับจุดเดือดจากต่ำไปสูงของสารที่มีมวลโมเลกุลใกล้เคียงกัน ข้อใดถูกต้อง$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$สารใดมีสมบัติเป็นกรดต่อสารละลาย NaHCO3 แล้วเกิดฟองแก๊ส$t$, $j${"choices": [{"t": "CH3CH2OH"}, {"t": "CH3CHO"}, {"t": "CH3COCH3"}, {"t": "CH3COOH"}], "answer": 3}$j$::jsonb, 1, $t$กรดคาร์บอกซิลิกให้ CO2$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$สารใดมีสมบัติเป็นกรดต่อสารละลาย NaHCO3 แล้วเกิดฟองแก๊ส$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$สารใดต่อไปนี้ถูกออกซิไดส์ได้ง่ายที่สุดด้วยตัวออกซิไดส์อ่อน$t$, $j${"choices": [{"t": "CH3COCH3"}, {"t": "CH3OCH3"}, {"t": "CH3COOH"}, {"t": "CH3CHO"}], "answer": 3}$j$::jsonb, 1, $t$แอลดีไฮด์ถูกออกซิไดส์เป็นกรด$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$สารใดต่อไปนี้ถูกออกซิไดส์ได้ง่ายที่สุดด้วยตัวออกซิไดส์อ่อน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$สาร C3H6O มีไอโซเมอร์ที่เป็นแอลดีไฮด์และคีโตน คือคู่ใด$t$, $j${"choices": [{"t": "เมทิลอีเทอร์และเอทานอล"}, {"t": "กรดและเอสเทอร์"}, {"t": "โพรพานัลและโพรพาโนน"}, {"t": "โพรพานอลและโพรพีน"}], "answer": 2}$j$::jsonb, 1, $t$CH3CH2CHO และ CH3COCH3$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$สาร C3H6O มีไอโซเมอร์ที่เป็นแอลดีไฮด์และคีโตน คือคู่ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$หมู่ฟังก์ชันของสาร CH3CH2CH2NH2 คือข้อใด$t$, $j${"choices": [{"t": "อีเทอร์"}, {"t": "เอมีน"}, {"t": "เอไมด์"}, {"t": "แอลกอฮอล์"}], "answer": 1}$j$::jsonb, 1, $t$-NH2 ต่อกับหมู่อัลคิล$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$หมู่ฟังก์ชันของสาร CH3CH2CH2NH2 คือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$ข้อใดจัดเป็นสารประกอบอินทรีย์$t$, $j${"choices": [{"t": "CO2"}, {"t": "NaCl"}, {"t": "CaCO3"}, {"t": "CH4"}], "answer": 3}$j$::jsonb, 1, $t$สารอินทรีย์ส่วนใหญ่มีคาร์บอนต่อกับไฮโดรเจน (CO2 และคาร์บอเนตจัดเป็นอนินทรีย์)$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$ข้อใดจัดเป็นสารประกอบอินทรีย์$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$ทำไมสารประกอบอินทรีย์ส่วนใหญ่จุดหลอมเหลวต่ำกว่าสารประกอบไอออนิก$t$, $j${"choices": [{"t": "ไม่มีอิเล็กตรอนวาเลนซ์"}, {"t": "มีพันธะโลหะ"}, {"t": "แรงยึดเหนี่ยวระหว่างโมเลกุลอ่อนกว่าพันธะไอออนิก"}, {"t": "มีมวลโมเลกุลมากกว่าเสมอ"}], "answer": 2}$j$::jsonb, 1, $t$สารโมเลกุลโคเวเลนต์ใช้พลังงานน้อยกว่าในการแยกโมเลกุล$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$ทำไมสารประกอบอินทรีย์ส่วนใหญ่จุดหลอมเหลวต่ำกว่าสารประกอบไอออนิก$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$คาร์บอนมีเวเลนซ์อิเล็กตรอนกี่ตัว และสร้างพันธะโคเวเลนต์ได้กี่พันธะ$t$, $j${"choices": [{"t": "4 ตัว และ 4 พันธะ"}, {"t": "4 ตัว และ 8 พันธะ"}, {"t": "6 ตัว และ 2 พันธะ"}, {"t": "2 ตัว และ 2 พันธะ"}], "answer": 0}$j$::jsonb, 1, $t$เลขอะตอม 6 (2,4)$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$คาร์บอนมีเวเลนซ์อิเล็กตรอนกี่ตัว และสร้างพันธะโคเวเลนต์ได้กี่พันธะ$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'mcq', $t$รูปร่างโมเลกุลรอบคาร์บอนของมีเทนเป็นแบบใด$t$, $j${"choices": [{"t": "เส้นตรง"}, {"t": "พีระมิดฐานสี่เหลี่ยม"}, {"t": "สามเหลี่ยมแบนราบ"}, {"t": "เตตระฮีดรัล (มุม 109.5 องศา)"}], "answer": 3}$j$::jsonb, 1, $t$คาร์บอน sp3$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$รูปร่างโมเลกุลรอบคาร์บอนของมีเทนเป็นแบบใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'tf', $t$สารที่มีสูตร C3H8O เป็นได้ทั้งแอลกอฮอล์และอีเทอร์$t$, $j${"answer": true}$j$::jsonb, 1, $t$1-โพรพานอล 2-โพรพานอล และเอทิลเมทิลอีเทอร์$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$สารที่มีสูตร C3H8O เป็นได้ทั้งแอลกอฮอล์และอีเทอร์$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'tf', $t$CO2 จัดเป็นสารประกอบอินทรีย์เพราะมีคาร์บอน$t$, $j${"answer": false}$j$::jsonb, 1, $t$จัดเป็นสารอนินทรีย์$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$CO2 จัดเป็นสารประกอบอินทรีย์เพราะมีคาร์บอน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'drag', $t$ลากสารแต่ละชนิดไปยังหมู่ฟังก์ชันที่ถูกต้อง$t$, $j${"zones": [{"t": "แอลกอฮอล์"}, {"t": "แอลดีไฮด์"}, {"t": "กรดคาร์บอกซิลิก"}, {"t": "เอสเทอร์"}], "items": [{"t": "CH3CH2OH"}, {"t": "CH3CHO"}, {"t": "CH3COOH"}, {"t": "CH3COOCH3"}, {"t": "CH3CH2CH2OH"}, {"t": "HCOOH"}], "answer": [0, 1, 2, 3, 0, 2]}$j$::jsonb, 6, $t$ดู -OH, -CHO, -COOH และ -COO-$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$ลากสารแต่ละชนิดไปยังหมู่ฟังก์ชันที่ถูกต้อง$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$, 'drag', $t$ลากสารแต่ละชนิดไปยังกลุ่มที่ถูกต้อง: ไฮโดรคาร์บอนอิ่มตัว / ไม่อิ่มตัว$t$, $j${"zones": [{"t": "อิ่มตัว"}, {"t": "ไม่อิ่มตัว"}], "items": [{"t": "CH3CH3"}, {"t": "CH2=CH2"}, {"t": "CH3CH2CH3"}, {"t": "HC≡CH"}, {"t": "CH3CH=CH2"}, {"t": "ไซโคลเฮกเซน"}], "answer": [0, 1, 0, 1, 1, 0]}$j$::jsonb, 6, $t$พันธะเดี่ยวล้วน = อิ่มตัว · มีพันธะคู่/สาม = ไม่อิ่มตัว$t$
where not exists (select 1 from exam_questions where topic = $t$หมู่ฟังก์ชันและเฮโลแอลเคน$t$ and q = $t$ลากสารแต่ละชนิดไปยังกลุ่มที่ถูกต้อง: ไฮโดรคาร์บอนอิ่มตัว / ไม่อิ่มตัว$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$มอนอเมอร์คืออะไร$t$, $j${"choices": [{"t": "หน่วยย่อยที่เป็นโมเลกุลเล็กซึ่งนำมาต่อกันเป็นพอลิเมอร์"}, {"t": "พอลิเมอร์ที่มีมวลโมเลกุลสูงมาก"}, {"t": "ตัวเร่งปฏิกิริยา"}, {"t": "ผลิตภัณฑ์พลอยได้ (น้ำ)"}], "answer": 0}$j$::jsonb, 1, $t$poly = มาก, mono = หนึ่งหน่วย$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$มอนอเมอร์คืออะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$พอลิเอทิลีนมีมอนอเมอร์ชนิดใด$t$, $j${"choices": [{"t": "เอทีน"}, {"t": "โพรพีน"}, {"t": "เอไทน์"}, {"t": "ไวนิลคลอไรด์"}], "answer": 0}$j$::jsonb, 1, $t$nCH2=CH2 → -(CH2CH2)n-$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พอลิเอทิลีนมีมอนอเมอร์ชนิดใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$พอลิโพรพิลีนมีมอนอเมอร์ชนิดใด$t$, $j${"choices": [{"t": "เอทีน"}, {"t": "โพรพีน"}, {"t": "สไตรีน"}, {"t": "บิวทีน"}], "answer": 1}$j$::jsonb, 1, $t$CH3CH=CH2$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พอลิโพรพิลีนมีมอนอเมอร์ชนิดใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$พอลิไวนิลคลอไรด์ (PVC) มีมอนอเมอร์ชนิดใด$t$, $j${"choices": [{"t": "สไตรีน"}, {"t": "เอทีน"}, {"t": "ไวนิลคลอไรด์ (CH2=CHCl)"}, {"t": "เตตระฟลูออโรเอทีน"}], "answer": 2}$j$::jsonb, 1, $t$ใช้ทำท่อน้ำ$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พอลิไวนิลคลอไรด์ (PVC) มีมอนอเมอร์ชนิดใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$พอลิสไตรีนมีมอนอเมอร์ชนิดใด$t$, $j${"choices": [{"t": "สไตรีน (C6H5CH=CH2)"}, {"t": "เอทีน"}, {"t": "โทลูอีน"}, {"t": "เบนซีน"}], "answer": 0}$j$::jsonb, 1, $t$ใช้ทำโฟมเม็ด/กล่องโฟม$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พอลิสไตรีนมีมอนอเมอร์ชนิดใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$เทฟลอน (PTFE) มีมอนอเมอร์ชนิดใด$t$, $j${"choices": [{"t": "โพรพีน"}, {"t": "ไวนิลคลอไรด์"}, {"t": "เตตระฟลูออโรเอทีน (CF2=CF2)"}, {"t": "เอทีน"}], "answer": 2}$j$::jsonb, 1, $t$ใช้เคลือบกระทะไม่ติด$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$เทฟลอน (PTFE) มีมอนอเมอร์ชนิดใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$พอลิเมอร์ชนิดเติม (addition polymer) เกิดจากมอนอเมอร์ที่มีลักษณะใด$t$, $j${"choices": [{"t": "มีหมู่ -NH2 เท่านั้น"}, {"t": "มีพันธะคู่ระหว่างคาร์บอน"}, {"t": "มีหมู่ -OH 2 หมู่"}, {"t": "มีหมู่ -COOH 2 หมู่"}], "answer": 1}$j$::jsonb, 1, $t$พันธะ π เปิดออกเพื่อต่อโซ่$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พอลิเมอร์ชนิดเติม (addition polymer) เกิดจากมอนอเมอร์ที่มีลักษณะใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$พอลิเมอร์ชนิดควบแน่น (condensation polymer) มีลักษณะสำคัญข้อใด$t$, $j${"choices": [{"t": "เกิดจากแอลเคนเท่านั้น"}, {"t": "ไม่มีผลิตภัณฑ์พลอยได้"}, {"t": "เกิดจากการเปิดพันธะคู่"}, {"t": "มอนอเมอร์ต่อกันพร้อมเสียโมเลกุลเล็ก เช่น น้ำ"}], "answer": 3}$j$::jsonb, 1, $t$เช่น ไนลอน พอลิเอสเทอร์$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พอลิเมอร์ชนิดควบแน่น (condensation polymer) มีลักษณะสำคัญข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$ไนลอน-6,6 เกิดจากมอนอเมอร์คู่ใด$t$, $j${"choices": [{"t": "กลูโคสและฟรุกโทส"}, {"t": "เอทีน และ โพรพีน"}, {"t": "กรดเทเรฟทาลิก และเอทิลีนไกลคอล"}, {"t": "กรดเฮกเซนไดโอิก และ เฮกเซน-1,6-ไดเอมีน"}], "answer": 3}$j$::jsonb, 1, $t$ต่อกันด้วยพันธะเอไมด์ เสียน้ำ$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$ไนลอน-6,6 เกิดจากมอนอเมอร์คู่ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$พันธะที่เชื่อมมอนอเมอร์ในไนลอนคือพันธะใด$t$, $j${"choices": [{"t": "พันธะอีเทอร์"}, {"t": "พันธะไกลโคซิดิก"}, {"t": "พันธะเอสเทอร์"}, {"t": "พันธะเอไมด์"}], "answer": 3}$j$::jsonb, 1, $t$-CO-NH-$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พันธะที่เชื่อมมอนอเมอร์ในไนลอนคือพันธะใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$พอลิเอทิลีนเทเรฟทาเลต (PET) เกิดจากพันธะใดเชื่อมมอนอเมอร์$t$, $j${"choices": [{"t": "พันธะเอสเทอร์"}, {"t": "พันธะเปปไทด์"}, {"t": "พันธะไกลโคซิดิก"}, {"t": "พันธะเอไมด์"}], "answer": 0}$j$::jsonb, 1, $t$PET เป็นพอลิเอสเทอร์ ใช้ทำขวดน้ำดื่ม$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พอลิเอทิลีนเทเรฟทาเลต (PET) เกิดจากพันธะใดเชื่อมมอนอเมอร์$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$ยางธรรมชาติมีมอนอเมอร์ชนิดใด$t$, $j${"choices": [{"t": "เอทีน"}, {"t": "บิวทาไดอีน"}, {"t": "สไตรีน"}, {"t": "ไอโซพรีน"}], "answer": 3}$j$::jsonb, 1, $t$2-เมทิล-1,3-บิวทาไดอีน$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$ยางธรรมชาติมีมอนอเมอร์ชนิดใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$การทำให้ยางวัลคาไนซ์ใช้สารใด$t$, $j${"choices": [{"t": "คลอรีน"}, {"t": "ไฮโดรเจน"}, {"t": "กำมะถัน (ซัลเฟอร์)"}, {"t": "โซเดียมไฮดรอกไซด์"}], "answer": 2}$j$::jsonb, 1, $t$เกิดพันธะเชื่อมขวางระหว่างโซ่ ยางแข็งแรงและยืดหยุ่นขึ้น$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$การทำให้ยางวัลคาไนซ์ใช้สารใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$พลาสติกเทอร์โมเซต (thermosetting) มีสมบัติอย่างไร$t$, $j${"choices": [{"t": "อ่อนตัวและหลอมได้เมื่อให้ความร้อนซ้ำ"}, {"t": "สลายตัวเป็นมอนอเมอร์เมื่อโดนแสง"}, {"t": "ละลายน้ำได้"}, {"t": "แข็ง เมื่อขึ้นรูปแล้วไม่หลอมเหลวเมื่อให้ความร้อนซ้ำ"}], "answer": 3}$j$::jsonb, 1, $t$มีพันธะเชื่อมขวางสามมิติ เช่น เบกาไลต์$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พลาสติกเทอร์โมเซต (thermosetting) มีสมบัติอย่างไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$พลาสติกเทอร์โมพลาสติกมีสมบัติอย่างไร$t$, $j${"choices": [{"t": "ระเหยเป็นไอเมื่อได้รับความร้อน"}, {"t": "ไม่เปลี่ยนแปลงเมื่อได้รับความร้อน"}, {"t": "อ่อนตัวและหลอมเมื่อได้รับความร้อน นำกลับมาขึ้นรูปใหม่ได้"}, {"t": "แข็งและไม่หลอมเมื่อได้รับความร้อน"}], "answer": 2}$j$::jsonb, 1, $t$โซ่ไม่มีพันธะเชื่อมขวาง เช่น PE PP PVC$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พลาสติกเทอร์โมพลาสติกมีสมบัติอย่างไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$พอลิเมอร์ชนิดใดต่อไปนี้เป็นพอลิเมอร์ธรรมชาติ$t$, $j${"choices": [{"t": "PVC"}, {"t": "แป้ง"}, {"t": "เทฟลอน"}, {"t": "ไนลอน"}], "answer": 1}$j$::jsonb, 1, $t$แป้งเป็นพอลิเมอร์ของกลูโคส$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พอลิเมอร์ชนิดใดต่อไปนี้เป็นพอลิเมอร์ธรรมชาติ$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$พอลิเมอร์ที่ย่อยสลายได้ทางชีวภาพคือข้อใด$t$, $j${"choices": [{"t": "PVC"}, {"t": "พอลิแลกติกแอซิด (PLA)"}, {"t": "เทฟลอน"}, {"t": "พอลิสไตรีน"}], "answer": 1}$j$::jsonb, 1, $t$ผลิตจากกรดแลกติก ย่อยสลายได้ภายใต้สภาวะที่เหมาะสม$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พอลิเมอร์ที่ย่อยสลายได้ทางชีวภาพคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$พอลิเอทิลีนที่มีโซ่ตรงอัดแน่นกว่าและแข็งกว่าเรียกว่าอะไร$t$, $j${"choices": [{"t": "PET"}, {"t": "HDPE"}, {"t": "PVC"}, {"t": "LDPE"}], "answer": 1}$j$::jsonb, 1, $t$High-density polyethylene$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พอลิเอทิลีนที่มีโซ่ตรงอัดแน่นกว่าและแข็งกว่าเรียกว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$ถ้าพอลิเอทิลีนสายหนึ่งมี n = 1000 หน่วยซ้ำ มวลโมเลกุลประมาณเท่าไร (C = 12, H = 1)$t$, $j${"choices": [{"t": "28,000"}, {"t": "56,000"}, {"t": "2,800"}, {"t": "14,000"}], "answer": 0}$j$::jsonb, 1, $t$หน่วยซ้ำ CH2CH2 = 28 → 28 × 1000$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$ถ้าพอลิเอทิลีนสายหนึ่งมี n = 1000 หน่วยซ้ำ มวลโมเลกุลประมาณเท่าไร (C = 12, H = 1)$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'mcq', $t$ปัญหาสิ่งแวดล้อมหลักของพลาสติกส่วนใหญ่คืออะไร$t$, $j${"choices": [{"t": "เป็นสารกัมมันตรังสี"}, {"t": "ย่อยสลายยากและตกค้างเป็นเวลานาน"}, {"t": "ละลายหมดในน้ำฝน"}, {"t": "ทำให้ดินมีสภาพเป็นกรดจัด"}], "answer": 1}$j$::jsonb, 1, $t$ควรลดการใช้ นำกลับมาใช้ซ้ำ และรีไซเคิล$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$ปัญหาสิ่งแวดล้อมหลักของพลาสติกส่วนใหญ่คืออะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'tf', $t$พอลิเมอร์ชนิดเติมมักไม่เกิดผลิตภัณฑ์พลอยได้$t$, $j${"answer": true}$j$::jsonb, 1, $t$มอนอเมอร์ต่อกันโดยไม่เสียโมเลกุลเล็ก$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พอลิเมอร์ชนิดเติมมักไม่เกิดผลิตภัณฑ์พลอยได้$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'tf', $t$ไนลอนเป็นพอลิเมอร์ชนิดเติม$t$, $j${"answer": false}$j$::jsonb, 1, $t$ไนลอนเป็นพอลิเมอร์ชนิดควบแน่น$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$ไนลอนเป็นพอลิเมอร์ชนิดเติม$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'tf', $t$พอลิเมอร์มีมวลโมเลกุลสูงเพราะประกอบด้วยหน่วยซ้ำจำนวนมาก$t$, $j${"answer": true}$j$::jsonb, 1, $t$n มักเป็นหลักร้อยถึงหลักล้าน$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$พอลิเมอร์มีมวลโมเลกุลสูงเพราะประกอบด้วยหน่วยซ้ำจำนวนมาก$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$พอลิเมอร์$t$, 'match', $t$จับคู่พอลิเมอร์กับมอนอเมอร์$t$, $j${"left": [{"t": "พอลิเอทิลีน"}, {"t": "พอลิโพรพิลีน"}, {"t": "PVC"}, {"t": "พอลิสไตรีน"}], "right": [{"t": "ไอโซพรีน"}, {"t": "สไตรีน"}, {"t": "โพรพีน"}, {"t": "ไวนิลคลอไรด์"}, {"t": "เอทีน"}], "pairs": [4, 2, 3, 1]}$j$::jsonb, 4, $t$ชื่อพอลิเมอร์มักบอกมอนอเมอร์$t$
where not exists (select 1 from exam_questions where topic = $t$พอลิเมอร์$t$ and q = $t$จับคู่พอลิเมอร์กับมอนอเมอร์$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$กลูโคสมีสูตรโมเลกุลใด$t$, $j${"choices": [{"t": "C6H12O6"}, {"t": "C6H10O5"}, {"t": "C5H10O5"}, {"t": "C12H22O11"}], "answer": 0}$j$::jsonb, 1, $t$โมโนแซ็กคาไรด์หกคาร์บอน$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$กลูโคสมีสูตรโมเลกุลใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$คาร์โบไฮเดรตมีสูตรทั่วไปตามข้อใด$t$, $j${"choices": [{"t": "CnH2n+2"}, {"t": "CnH2n-2"}, {"t": "CnH2nO2"}, {"t": "Cn(H2O)m"}], "answer": 3}$j$::jsonb, 1, $t$ชื่อ "คาร์บอนที่มีน้ำ"$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$คาร์โบไฮเดรตมีสูตรทั่วไปตามข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$กลูโคสและฟรุกโทสเป็นไอโซเมอร์กัน เพราะเหตุใด$t$, $j${"choices": [{"t": "มีมวลโมเลกุลต่างกัน"}, {"t": "เป็นพอลิเมอร์ทั้งคู่"}, {"t": "สูตรโมเลกุลเดียวกัน (C6H12O6) แต่โครงสร้างต่างกัน"}, {"t": "มีหมู่ฟังก์ชันเหมือนกันทุกประการ"}], "answer": 2}$j$::jsonb, 1, $t$กลูโคสมีหมู่แอลดีไฮด์ ส่วนฟรุกโทสมีหมู่คีโตน$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$กลูโคสและฟรุกโทสเป็นไอโซเมอร์กัน เพราะเหตุใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$ซูโครสเป็นไดแซ็กคาไรด์ที่เกิดจากมอนอเมอร์คู่ใด$t$, $j${"choices": [{"t": "ฟรุกโทสและกาแล็กโทส"}, {"t": "กลูโคสและฟรุกโทส"}, {"t": "กลูโคสและกาแล็กโทส"}, {"t": "กลูโคสและกลูโคส"}], "answer": 1}$j$::jsonb, 1, $t$น้ำตาลทราย$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$ซูโครสเป็นไดแซ็กคาไรด์ที่เกิดจากมอนอเมอร์คู่ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$มอลโทสเป็นไดแซ็กคาไรด์ที่เกิดจากมอนอเมอร์คู่ใด$t$, $j${"choices": [{"t": "ฟรุกโทสและกาแล็กโทส"}, {"t": "กลูโคสและฟรุกโทส"}, {"t": "กลูโคสและกาแล็กโทส"}, {"t": "กลูโคสและกลูโคส"}], "answer": 3}$j$::jsonb, 1, $t$น้ำตาลมอลต์$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$มอลโทสเป็นไดแซ็กคาไรด์ที่เกิดจากมอนอเมอร์คู่ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$แล็กโทสซึ่งพบในนมเกิดจากมอนอเมอร์คู่ใด$t$, $j${"choices": [{"t": "ฟรุกโทสและฟรุกโทส"}, {"t": "กลูโคสและฟรุกโทส"}, {"t": "กลูโคสและกลูโคส"}, {"t": "กลูโคสและกาแล็กโทส"}], "answer": 3}$j$::jsonb, 1, $t$น้ำตาลนม$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$แล็กโทสซึ่งพบในนมเกิดจากมอนอเมอร์คู่ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$พันธะที่เชื่อมแซ็กคาไรด์สองหน่วยเข้าด้วยกันเรียกว่าอะไร$t$, $j${"choices": [{"t": "พันธะไกลโคซิดิก"}, {"t": "พันธะเอสเทอร์"}, {"t": "พันธะไฮโดรเจน"}, {"t": "พันธะเปปไทด์"}], "answer": 0}$j$::jsonb, 1, $t$เกิดจากการเสียน้ำระหว่างหมู่ -OH$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$พันธะที่เชื่อมแซ็กคาไรด์สองหน่วยเข้าด้วยกันเรียกว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$เมื่อกลูโคส 2 โมเลกุลรวมกันเป็นมอลโทส จะเกิดผลิตภัณฑ์พลอยได้ใด$t$, $j${"choices": [{"t": "น้ำ 1 โมเลกุล"}, {"t": "แก๊สไฮโดรเจน"}, {"t": "ไม่มีผลิตภัณฑ์พลอยได้"}, {"t": "CO2 1 โมเลกุล"}], "answer": 0}$j$::jsonb, 1, $t$2C6H12O6 → C12H22O11 + H2O$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$เมื่อกลูโคส 2 โมเลกุลรวมกันเป็นมอลโทส จะเกิดผลิตภัณฑ์พลอยได้ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$น้ำตาลชนิดใดไม่เป็นน้ำตาลรีดิวซ์ (ไม่ให้ผลบวกกับเบเนดิกต์โดยตรง)$t$, $j${"choices": [{"t": "ซูโครส"}, {"t": "กลูโคส"}, {"t": "มอลโทส"}, {"t": "ฟรุกโทส"}], "answer": 0}$j$::jsonb, 1, $t$ซูโครสไม่มีหมู่แอลดีไฮด์หรือคีโตนอิสระ$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$น้ำตาลชนิดใดไม่เป็นน้ำตาลรีดิวซ์ (ไม่ให้ผลบวกกับเบเนดิกต์โดยตรง)$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$น้ำตาลชนิดใดให้ผลบวกกับสารละลายเบเนดิกต์$t$, $j${"choices": [{"t": "แป้ง"}, {"t": "เซลลูโลส"}, {"t": "กลูโคส"}, {"t": "ซูโครส"}], "answer": 2}$j$::jsonb, 1, $t$น้ำตาลรีดิวซ์ให้ตะกอนแดงอิฐ$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$น้ำตาลชนิดใดให้ผลบวกกับสารละลายเบเนดิกต์$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$สารละลายไอโอดีนใช้ทดสอบสารใด และให้สีอะไร$t$, $j${"choices": [{"t": "แป้ง ให้สีน้ำเงินเข้ม (ม่วงเข้ม)"}, {"t": "โปรตีน ให้สีม่วง"}, {"t": "กลูโคส ให้สีแดง"}, {"t": "เซลลูโลส ให้สีเขียว"}], "answer": 0}$j$::jsonb, 1, $t$แป้ง + I2 → สารเชิงซ้อนสีน้ำเงินเข้ม$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$สารละลายไอโอดีนใช้ทดสอบสารใด และให้สีอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$พอลิแซ็กคาไรด์ที่พืชใช้สะสมพลังงานคือข้อใด$t$, $j${"choices": [{"t": "ไกลโคเจน"}, {"t": "เซลลูโลส"}, {"t": "ซูโครส"}, {"t": "แป้ง"}], "answer": 3}$j$::jsonb, 1, $t$สะสมในเมล็ด หัว ราก$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$พอลิแซ็กคาไรด์ที่พืชใช้สะสมพลังงานคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$พอลิแซ็กคาไรด์ที่เป็นโครงสร้างผนังเซลล์พืชคือข้อใด$t$, $j${"choices": [{"t": "เซลลูโลส"}, {"t": "ไกลโคเจน"}, {"t": "มอลโทส"}, {"t": "แป้ง"}], "answer": 0}$j$::jsonb, 1, $t$ประกอบด้วยกลูโคสต่อกันเป็นโซ่ตรงยาว$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$พอลิแซ็กคาไรด์ที่เป็นโครงสร้างผนังเซลล์พืชคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$พอลิแซ็กคาไรด์ที่สัตว์ใช้สะสมพลังงานในตับและกล้ามเนื้อคือข้อใด$t$, $j${"choices": [{"t": "ไกลโคเจน"}, {"t": "ไคติน"}, {"t": "เซลลูโลส"}, {"t": "แป้ง"}], "answer": 0}$j$::jsonb, 1, $t$คล้ายอะไมโลเพกตินแต่แตกกิ่งมากกว่า$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$พอลิแซ็กคาไรด์ที่สัตว์ใช้สะสมพลังงานในตับและกล้ามเนื้อคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$เหตุใดมนุษย์ย่อยเซลลูโลสไม่ได้$t$, $j${"choices": [{"t": "เซลลูโลสละลายในน้ำมาก"}, {"t": "ไม่มีเอนไซม์เซลลูเลสสำหรับย่อยพันธะ β-ไกลโคซิดิก"}, {"t": "เซลลูโลสเป็นไขมัน"}, {"t": "เซลลูโลสเป็นโปรตีน"}], "answer": 1}$j$::jsonb, 1, $t$สัตว์เคี้ยวเอื้องย่อยได้เพราะจุลินทรีย์ในกระเพาะ$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$เหตุใดมนุษย์ย่อยเซลลูโลสไม่ได้$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$เมื่อไฮโดรไลซ์แป้งอย่างสมบูรณ์ด้วยกรดหรือเอนไซม์ ได้ผลิตภัณฑ์สุดท้ายใด$t$, $j${"choices": [{"t": "ฟรุกโทส"}, {"t": "กลูโคส"}, {"t": "กรดอะมิโน"}, {"t": "กลีเซอรอล"}], "answer": 1}$j$::jsonb, 1, $t$แป้งเป็นพอลิเมอร์ของกลูโคส$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$เมื่อไฮโดรไลซ์แป้งอย่างสมบูรณ์ด้วยกรดหรือเอนไซม์ ได้ผลิตภัณฑ์สุดท้ายใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$เมื่อไฮโดรไลซ์ซูโครส ได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "กลูโคส 2 โมเลกุล"}, {"t": "กลูโคสและกาแล็กโทส"}, {"t": "กลูโคสและฟรุกโทส"}, {"t": "กลีเซอรอลและกรดไขมัน"}], "answer": 2}$j$::jsonb, 1, $t$ได้น้ำตาลอินเวิร์ต$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$เมื่อไฮโดรไลซ์ซูโครส ได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$น้ำตาลชนิดใดมีรสหวานมากที่สุดในกลุ่มมอนอแซ็กคาไรด์$t$, $j${"choices": [{"t": "กลูโคส"}, {"t": "ไรโบส"}, {"t": "กาแล็กโทส"}, {"t": "ฟรุกโทส"}], "answer": 3}$j$::jsonb, 1, $t$พบในน้ำผึ้งและผลไม้$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$น้ำตาลชนิดใดมีรสหวานมากที่สุดในกลุ่มมอนอแซ็กคาไรด์$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$เอนไซม์อะไมเลสในน้ำลายช่วยย่อยสารใด$t$, $j${"choices": [{"t": "ไขมัน"}, {"t": "โปรตีน"}, {"t": "แป้ง"}, {"t": "เซลลูโลส"}], "answer": 2}$j$::jsonb, 1, $t$แป้งถูกย่อยเป็นมอลโทสและกลูโคส$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$เอนไซม์อะไมเลสในน้ำลายช่วยย่อยสารใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'mcq', $t$ไรโบสมีจำนวนคาร์บอนกี่อะตอม$t$, $j${"choices": [{"t": "5 อะตอม"}, {"t": "4 อะตอม"}, {"t": "6 อะตอม"}, {"t": "12 อะตอม"}], "answer": 0}$j$::jsonb, 1, $t$เพนโทส C5H10O5 เป็นส่วนประกอบของ RNA$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$ไรโบสมีจำนวนคาร์บอนกี่อะตอม$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'tf', $t$แป้งและเซลลูโลสเป็นพอลิเมอร์ของกลูโคสทั้งคู่$t$, $j${"answer": true}$j$::jsonb, 1, $t$ต่างกันที่รูปแบบพันธะไกลโคซิดิก (α และ β)$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$แป้งและเซลลูโลสเป็นพอลิเมอร์ของกลูโคสทั้งคู่$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'tf', $t$ซูโครสให้ผลบวกกับเบเนดิกต์ทันทีโดยไม่ต้องไฮโดรไลซ์$t$, $j${"answer": false}$j$::jsonb, 1, $t$ซูโครสไม่ใช่น้ำตาลรีดิวซ์ ต้องถูกไฮโดรไลซ์ก่อน$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$ซูโครสให้ผลบวกกับเบเนดิกต์ทันทีโดยไม่ต้องไฮโดรไลซ์$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$คาร์โบไฮเดรต$t$, 'match', $t$จับคู่คาร์โบไฮเดรตกับชนิด$t$, $j${"left": [{"t": "กลูโคส"}, {"t": "ซูโครส"}, {"t": "แป้ง"}, {"t": "เซลลูโลส"}], "right": [{"t": "มอนอแซ็กคาไรด์"}, {"t": "ไดแซ็กคาไรด์"}, {"t": "พอลิแซ็กคาไรด์ (โครงสร้างพืช)"}, {"t": "โปรตีน"}, {"t": "พอลิแซ็กคาไรด์"}], "pairs": [0, 1, 4, 2]}$j$::jsonb, 4, $t$จำนวนหน่วยน้ำตาล: 1, 2, จำนวนมาก$t$
where not exists (select 1 from exam_questions where topic = $t$คาร์โบไฮเดรต$t$ and q = $t$จับคู่คาร์โบไฮเดรตกับชนิด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$กรดอะมิโนมีหมู่ฟังก์ชันใดอยู่ในโมเลกุล$t$, $j${"choices": [{"t": "-CO- และ -OH"}, {"t": "หมู่อะมิโน (-NH2) และหมู่คาร์บอกซิล (-COOH)"}, {"t": "-COOR และ -NH2 เท่านั้น"}, {"t": "-OH และ -CHO"}], "answer": 1}$j$::jsonb, 1, $t$ต่อที่คาร์บอนตัวเดียวกัน (α-คาร์บอน)$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$กรดอะมิโนมีหมู่ฟังก์ชันใดอยู่ในโมเลกุล$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$โครงสร้างทั่วไปของ α-กรดอะมิโนคือข้อใด$t$, $j${"choices": [{"t": "H2N-CH(R)-COOH"}, {"t": "H2N-CH2-CH2-COOH เสมอ"}, {"t": "R-CO-NH2"}, {"t": "HOOC-R-COOH"}], "answer": 0}$j$::jsonb, 1, $t$R คือหมู่ข้างเคียงที่ต่างกันในแต่ละกรดอะมิโน$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$โครงสร้างทั่วไปของ α-กรดอะมิโนคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$กรดอะมิโนชนิดใดที่ R เป็น H$t$, $j${"choices": [{"t": "ไกลซีน"}, {"t": "อะลานีน"}, {"t": "ไลซีน"}, {"t": "ซีสเตอีน"}], "answer": 0}$j$::jsonb, 1, $t$H2N-CH2-COOH ไม่มีไครัลคาร์บอน$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$กรดอะมิโนชนิดใดที่ R เป็น H$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$พันธะที่เชื่อมกรดอะมิโนเข้าด้วยกันในโปรตีนเรียกว่าอะไร$t$, $j${"choices": [{"t": "พันธะไกลโคซิดิก"}, {"t": "พันธะไฮโดรเจน"}, {"t": "พันธะเอสเทอร์"}, {"t": "พันธะเปปไทด์"}], "answer": 3}$j$::jsonb, 1, $t$เกิดระหว่างหมู่ -COOH กับ -NH2 พร้อมเสียน้ำ$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$พันธะที่เชื่อมกรดอะมิโนเข้าด้วยกันในโปรตีนเรียกว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$กรดอะมิโน 2 โมเลกุลรวมกันเป็นไดเปปไทด์ จะเสียน้ำกี่โมเลกุล$t$, $j${"choices": [{"t": "2 โมเลกุล"}, {"t": "0 โมเลกุล"}, {"t": "1 โมเลกุล"}, {"t": "3 โมเลกุล"}], "answer": 2}$j$::jsonb, 1, $t$สร้างพันธะเปปไทด์ 1 พันธะ$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$กรดอะมิโน 2 โมเลกุลรวมกันเป็นไดเปปไทด์ จะเสียน้ำกี่โมเลกุล$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$โพลีเปปไทด์สายตรงที่ประกอบด้วยกรดอะมิโน 10 หน่วยมีพันธะเปปไทด์กี่พันธะ$t$, $j${"choices": [{"t": "11 พันธะ"}, {"t": "9 พันธะ"}, {"t": "10 พันธะ"}, {"t": "8 พันธะ"}], "answer": 1}$j$::jsonb, 1, $t$n หน่วย → n − 1 พันธะ$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$โพลีเปปไทด์สายตรงที่ประกอบด้วยกรดอะมิโน 10 หน่วยมีพันธะเปปไทด์กี่พันธะ$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$เมื่อกรดอะมิโน 5 โมเลกุลรวมเป็นสายตรง จะเสียน้ำกี่โมเลกุล$t$, $j${"choices": [{"t": "6 โมเลกุล"}, {"t": "3 โมเลกุล"}, {"t": "4 โมเลกุล"}, {"t": "5 โมเลกุล"}], "answer": 2}$j$::jsonb, 1, $t$n − 1 = 4$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$เมื่อกรดอะมิโน 5 โมเลกุลรวมเป็นสายตรง จะเสียน้ำกี่โมเลกุล$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$การทดสอบไบยูเรต (biuret) ใช้ตรวจสารใด และผลบวกให้สีอะไร$t$, $j${"choices": [{"t": "น้ำตาลรีดิวซ์ ให้ตะกอนแดงอิฐ"}, {"t": "โปรตีน (พันธะเปปไทด์) ให้สีม่วง"}, {"t": "ไขมัน ให้สีเหลือง"}, {"t": "แป้ง ให้สีน้ำเงินเข้ม"}], "answer": 1}$j$::jsonb, 1, $t$Cu2+ เกิดสารเชิงซ้อนกับพันธะเปปไทด์$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$การทดสอบไบยูเรต (biuret) ใช้ตรวจสารใด และผลบวกให้สีอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$การเสียสภาพของโปรตีน (denaturation) เกิดจากปัจจัยใด$t$, $j${"choices": [{"t": "การแช่แข็งเฉยๆ"}, {"t": "การเติมน้ำเปล่า"}, {"t": "การเติมแป้ง"}, {"t": "ความร้อน กรดหรือเบสแก่ ตัวทำละลายอินทรีย์ หรือโลหะหนัก"}], "answer": 3}$j$::jsonb, 1, $t$โครงสร้างสามมิติถูกทำลาย แต่ลำดับกรดอะมิโนยังอยู่$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$การเสียสภาพของโปรตีน (denaturation) เกิดจากปัจจัยใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$เมื่อต้มไข่ขาวจนขาวขุ่นแข็งเป็นตัวอย่างของอะไร$t$, $j${"choices": [{"t": "การไฮโดรไลซ์แป้ง"}, {"t": "การเสียสภาพของโปรตีน"}, {"t": "การหมัก"}, {"t": "การเกิดเอสเทอร์"}], "answer": 1}$j$::jsonb, 1, $t$ความร้อนทำให้โครงสร้างสามมิติเปลี่ยน$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$เมื่อต้มไข่ขาวจนขาวขุ่นแข็งเป็นตัวอย่างของอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$โครงสร้างปฐมภูมิของโปรตีนหมายถึงข้อใด$t$, $j${"choices": [{"t": "ลำดับของกรดอะมิโนในสายโพลีเปปไทด์"}, {"t": "การรวมของหลายสายโพลีเปปไทด์"}, {"t": "การพับตัวสามมิติรวม"}, {"t": "การม้วนเป็นเกลียวแอลฟา"}], "answer": 0}$j$::jsonb, 1, $t$ลำดับกำหนดโดยรหัสพันธุกรรม$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$โครงสร้างปฐมภูมิของโปรตีนหมายถึงข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$เกลียวแอลฟา (α-helix) และแผ่นเบตา (β-sheet) จัดเป็นโครงสร้างระดับใดของโปรตีน$t$, $j${"choices": [{"t": "ทุติยภูมิ"}, {"t": "ตติยภูมิ"}, {"t": "ปฐมภูมิ"}, {"t": "จตุตถภูมิ"}], "answer": 0}$j$::jsonb, 1, $t$เสถียรด้วยพันธะไฮโดรเจนระหว่างหมู่ C=O กับ N-H ของแกนหลัก$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$เกลียวแอลฟา (α-helix) และแผ่นเบตา (β-sheet) จัดเป็นโครงสร้างระดับใดของโปรตีน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$พันธะชนิดใดหลักที่ทำให้โครงสร้างทุติยภูมิของโปรตีนเสถียร$t$, $j${"choices": [{"t": "พันธะโลหะ"}, {"t": "พันธะไฮโดรเจน"}, {"t": "พันธะไอออนิกล้วน"}, {"t": "พันธะคู่ C=C"}], "answer": 1}$j$::jsonb, 1, $t$ระหว่าง C=O และ N-H ของแกนหลัก$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$พันธะชนิดใดหลักที่ทำให้โครงสร้างทุติยภูมิของโปรตีนเสถียร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$เอนไซม์ส่วนใหญ่เป็นสารชีวโมเลกุลประเภทใด$t$, $j${"choices": [{"t": "คาร์โบไฮเดรต"}, {"t": "ไขมัน"}, {"t": "กรดนิวคลีอิก"}, {"t": "โปรตีน"}], "answer": 3}$j$::jsonb, 1, $t$ทำหน้าที่เป็นตัวเร่งปฏิกิริยาในสิ่งมีชีวิต$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$เอนไซม์ส่วนใหญ่เป็นสารชีวโมเลกุลประเภทใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$ฮีโมโกลบินทำหน้าที่ใด$t$, $j${"choices": [{"t": "สะสมไขมัน"}, {"t": "ย่อยแป้ง"}, {"t": "ต้านทานการแข็งตัวของเลือดเท่านั้น"}, {"t": "ลำเลียงออกซิเจนในเลือด"}], "answer": 3}$j$::jsonb, 1, $t$เป็นโปรตีนที่มีฮีม (เหล็ก)$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$ฮีโมโกลบินทำหน้าที่ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$กรดอะมิโนที่จำเป็น (essential amino acid) หมายถึงข้อใด$t$, $j${"choices": [{"t": "กรดอะมิโนที่ร่างกายสร้างเองไม่ได้ ต้องได้รับจากอาหาร"}, {"t": "กรดอะมิโนที่ร่างกายสร้างได้มากเกินพอ"}, {"t": "กรดอะมิโนที่ไม่พบในโปรตีน"}, {"t": "กรดอะมิโนที่มีหมู่ -OH"}], "answer": 0}$j$::jsonb, 1, $t$ผู้ใหญ่มี 9 ชนิด$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$กรดอะมิโนที่จำเป็น (essential amino acid) หมายถึงข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$เอนไซม์เพปซินในกระเพาะอาหารย่อยสารใด$t$, $j${"choices": [{"t": "โปรตีน"}, {"t": "ไขมัน"}, {"t": "แป้ง"}, {"t": "เซลลูโลส"}], "answer": 0}$j$::jsonb, 1, $t$ทำงานได้ดีในสภาพกรดของกระเพาะ$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$เอนไซม์เพปซินในกระเพาะอาหารย่อยสารใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'mcq', $t$โปรตีนจากเนื้อสัตว์เมื่อถูกย่อยอย่างสมบูรณ์ได้ผลิตภัณฑ์ใด$t$, $j${"choices": [{"t": "กรดอะมิโน"}, {"t": "กลีเซอรอล"}, {"t": "กรดไขมัน"}, {"t": "กลูโคส"}], "answer": 0}$j$::jsonb, 1, $t$พันธะเปปไทด์ถูกไฮโดรไลซ์$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$โปรตีนจากเนื้อสัตว์เมื่อถูกย่อยอย่างสมบูรณ์ได้ผลิตภัณฑ์ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'tf', $t$ไกลซีนเป็นกรดอะมิโนที่ไม่มีคาร์บอนไครัล$t$, $j${"answer": true}$j$::jsonb, 1, $t$R = H คาร์บอนต่อกับ H 2 อะตอมเหมือนกัน$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$ไกลซีนเป็นกรดอะมิโนที่ไม่มีคาร์บอนไครัล$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'tf', $t$การเสียสภาพของโปรตีนทำให้ลำดับกรดอะมิโนเปลี่ยนไป$t$, $j${"answer": false}$j$::jsonb, 1, $t$เปลี่ยนเฉพาะโครงสร้างสามมิติ ลำดับกรดอะมิโนคงเดิม$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$การเสียสภาพของโปรตีนทำให้ลำดับกรดอะมิโนเปลี่ยนไป$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$กรดอะมิโนและโปรตีน$t$, 'match', $t$จับคู่หัวข้อกับข้อมูลของโปรตีน$t$, $j${"left": [{"t": "พันธะเชื่อมกรดอะมิโน"}, {"t": "ตรวจโปรตีนด้วยสารละลายคอปเปอร์(II)"}, {"t": "โครงสร้างปฐมภูมิ"}, {"t": "เกลียวแอลฟา"}], "right": [{"t": "พันธะไกลโคซิดิก"}, {"t": "โครงสร้างทุติยภูมิ"}, {"t": "ไบยูเรต สีม่วง"}, {"t": "พันธะเปปไทด์"}, {"t": "ลำดับกรดอะมิโน"}], "pairs": [3, 2, 4, 1]}$j$::jsonb, 4, $t$เชื่อมโยงสมบัติกับโครงสร้างโปรตีน$t$
where not exists (select 1 from exam_questions where topic = $t$กรดอะมิโนและโปรตีน$t$ and q = $t$จับคู่หัวข้อกับข้อมูลของโปรตีน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$ไขมันและน้ำมัน (ไตรกลีเซอไรด์) เกิดจากสารคู่ใด$t$, $j${"choices": [{"t": "เอทานอล 3 โมเลกุล และกรด 1 โมเลกุล"}, {"t": "กรดไขมัน 1 โมเลกุลและกลีเซอรอล 3 โมเลกุล"}, {"t": "กลีเซอรอล 1 โมเลกุล และกรดไขมัน 3 โมเลกุล"}, {"t": "กลูโคส 1 โมเลกุล และกรดอะมิโน 3 โมเลกุล"}], "answer": 2}$j$::jsonb, 1, $t$พันธะเอสเทอร์ 3 พันธะ$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$ไขมันและน้ำมัน (ไตรกลีเซอไรด์) เกิดจากสารคู่ใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$ในโมเลกุลไตรกลีเซอไรด์ 1 โมเลกุล มีพันธะเอสเทอร์กี่พันธะ$t$, $j${"choices": [{"t": "1 พันธะ"}, {"t": "3 พันธะ"}, {"t": "6 พันธะ"}, {"t": "2 พันธะ"}], "answer": 1}$j$::jsonb, 1, $t$กลีเซอรอล 3 หมู่ -OH รวมกับกรดไขมัน 3 โมเลกุล$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$ในโมเลกุลไตรกลีเซอไรด์ 1 โมเลกุล มีพันธะเอสเทอร์กี่พันธะ$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$กรดไขมันอิ่มตัวต่างจากกรดไขมันไม่อิ่มตัวอย่างไร$t$, $j${"choices": [{"t": "กรดไขมันอิ่มตัวมีพันธะคู่หลายพันธะ"}, {"t": "กรดไขมันอิ่มตัวไม่มีพันธะคู่ C=C ในสายไฮโดรคาร์บอน"}, {"t": "กรดไขมันอิ่มตัวมีไนโตรเจน"}, {"t": "กรดไขมันอิ่มตัวไม่มีหมู่ -COOH"}], "answer": 1}$j$::jsonb, 1, $t$ไขมันสัตว์มีกรดไขมันอิ่มตัวสูง$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$กรดไขมันอิ่มตัวต่างจากกรดไขมันไม่อิ่มตัวอย่างไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$น้ำมันพืชมักเป็นของเหลวที่อุณหภูมิห้อง เพราะเหตุใด$t$, $j${"choices": [{"t": "มีน้ำเป็นองค์ประกอบมาก"}, {"t": "มีโปรตีนมาก"}, {"t": "มีกรดไขมันไม่อิ่มตัวมาก โซ่งอ จัดเรียงชิดกันได้ยาก จุดหลอมเหลวต่ำ"}, {"t": "มีกรดไขมันอิ่มตัวมาก"}], "answer": 2}$j$::jsonb, 1, $t$พันธะคู่แบบซิสทำให้โซ่งอ$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$น้ำมันพืชมักเป็นของเหลวที่อุณหภูมิห้อง เพราะเหตุใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$ปฏิกิริยาไฮโดรจีเนชันของน้ำมันพืชทำให้เกิดอะไร$t$, $j${"choices": [{"t": "ได้น้ำมันที่เหลวขึ้น"}, {"t": "ได้โปรตีน"}, {"t": "ได้กลูโคส"}, {"t": "ได้ไขมันที่แข็งขึ้น (เช่น มาร์การีน)"}], "answer": 3}$j$::jsonb, 1, $t$เติม H2 ที่พันธะคู่ ทำให้อิ่มตัวมากขึ้น$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$ปฏิกิริยาไฮโดรจีเนชันของน้ำมันพืชทำให้เกิดอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$สะปอนนิฟิเคชันคือปฏิกิริยาระหว่างไตรกลีเซอไรด์กับสารใด$t$, $j${"choices": [{"t": "สารละลายเบสแก่ เช่น NaOH"}, {"t": "สารละลายกรดอ่อน"}, {"t": "น้ำเย็น"}, {"t": "แก๊สไฮโดรเจน"}], "answer": 0}$j$::jsonb, 1, $t$ได้สบู่และกลีเซอรอล$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$สะปอนนิฟิเคชันคือปฏิกิริยาระหว่างไตรกลีเซอไรด์กับสารใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$ผลิตภัณฑ์จากสะปอนนิฟิเคชันของน้ำมันพืชด้วย NaOH คือข้อใด$t$, $j${"choices": [{"t": "สบู่ (โซเดียมเกลือของกรดไขมัน) และกลีเซอรอล"}, {"t": "กรดไขมันและน้ำ"}, {"t": "แป้งและน้ำ"}, {"t": "กลูโคสและเอทานอล"}], "answer": 0}$j$::jsonb, 1, $t$RCOONa + C3H5(OH)3$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$ผลิตภัณฑ์จากสะปอนนิฟิเคชันของน้ำมันพืชด้วย NaOH คือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$โมเลกุลสบู่ส่วนหัวชอบน้ำและส่วนหางชอบน้ำมัน ลักษณะนี้เรียกว่าอะไร$t$, $j${"choices": [{"t": "ไอโซเมอริก"}, {"t": "แอมฟิพาทิก (ส่วนหัวมีขั้ว ส่วนหางไม่มีขั้ว)"}, {"t": "โมโนเมอริก"}, {"t": "รีดิวซ์"}], "answer": 1}$j$::jsonb, 1, $t$หัว -COO-Na+ ชอบน้ำ · หาง R ชอบไขมัน$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$โมเลกุลสบู่ส่วนหัวชอบน้ำและส่วนหางชอบน้ำมัน ลักษณะนี้เรียกว่าอะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$สบู่ขจัดคราบไขมันได้ด้วยกลไกใด$t$, $j${"choices": [{"t": "ทำปฏิกิริยากับไขมันให้กลายเป็นแก๊ส"}, {"t": "ย่อยไขมันเป็นกลูโคส"}, {"t": "ทำให้ไขมันเป็นไอออนิก"}, {"t": "หางจับคราบไขมันเกิดไมเซลล์ ส่วนหัวหันออกสู่น้ำ"}], "answer": 3}$j$::jsonb, 1, $t$ไมเซลล์ลอยไปกับน้ำล้างออกได้$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$สบู่ขจัดคราบไขมันได้ด้วยกลไกใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$เหตุใดสบู่ทำงานไม่ดีในน้ำกระด้าง$t$, $j${"choices": [{"t": "Ca2+ และ Mg2+ ทำให้เกิดตะกอนเกลือของกรดไขมันที่ไม่ละลาย"}, {"t": "น้ำกระด้างทำให้สบู่ไหม้"}, {"t": "น้ำกระด้างเป็นกรดแก่มาก"}, {"t": "น้ำกระด้างมีไขมันสูง"}], "answer": 0}$j$::jsonb, 1, $t$เกิดคราบสบู่ (scum)$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$เหตุใดสบู่ทำงานไม่ดีในน้ำกระด้าง$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$ผงซักฟอกสังเคราะห์ทำงานได้ดีในน้ำกระด้าง เพราะเหตุใด$t$, $j${"choices": [{"t": "เกลือแคลเซียมและแมกนีเซียมของผงซักฟอกละลายน้ำได้"}, {"t": "ไม่มีส่วนหางที่ไม่มีขั้ว"}, {"t": "เป็นกรดแก่"}, {"t": "เป็นเบสแก่"}], "answer": 0}$j$::jsonb, 1, $t$ไม่เกิดตะกอนกับ Ca2+/Mg2+$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$ผงซักฟอกสังเคราะห์ทำงานได้ดีในน้ำกระด้าง เพราะเหตุใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$ไขมันให้พลังงานต่อกรัมโดยประมาณเท่าใด$t$, $j${"choices": [{"t": "12 กิโลแคลอรี"}, {"t": "2 กิโลแคลอรี"}, {"t": "9 กิโลแคลอรี"}, {"t": "4 กิโลแคลอรี"}], "answer": 2}$j$::jsonb, 1, $t$คาร์โบไฮเดรตและโปรตีนให้ประมาณ 4 กิโลแคลอรีต่อกรัม$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$ไขมันให้พลังงานต่อกรัมโดยประมาณเท่าใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$โคเลสเตอรอลจัดเป็นลิพิดชนิดใด$t$, $j${"choices": [{"t": "สเตอรอยด์"}, {"t": "แว็กซ์"}, {"t": "ไตรกลีเซอไรด์"}, {"t": "ฟอสโฟลิพิด"}], "answer": 0}$j$::jsonb, 1, $t$โครงสร้างวงแหวนหลายวงหลอมรวมกัน$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$โคเลสเตอรอลจัดเป็นลิพิดชนิดใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$ส่วนประกอบของนิวคลีโอไทด์ 1 หน่วยคือข้อใด$t$, $j${"choices": [{"t": "น้ำตาลเฮกโซสและกรดอะมิโน"}, {"t": "กรดอะมิโน กรดไขมัน และฟอสเฟต"}, {"t": "กลูโคส กรดไขมัน และกลีเซอรอล"}, {"t": "น้ำตาลเพนโทส หมู่ฟอสเฟต และเบสไนโตรเจน"}], "answer": 3}$j$::jsonb, 1, $t$เป็นหน่วยย่อยของ DNA และ RNA$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$ส่วนประกอบของนิวคลีโอไทด์ 1 หน่วยคือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$น้ำตาลเพนโทสใน DNA คืออะไร$t$, $j${"choices": [{"t": "ไรโบส"}, {"t": "กลูโคส"}, {"t": "ฟรุกโทส"}, {"t": "ดีออกซีไรโบส"}], "answer": 3}$j$::jsonb, 1, $t$RNA มีไรโบส$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$น้ำตาลเพนโทสใน DNA คืออะไร$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$เบสไนโตรเจนที่พบใน DNA ได้แก่ข้อใด$t$, $j${"choices": [{"t": "A, T, G, C"}, {"t": "A, T, U, C"}, {"t": "A, U, G, C"}, {"t": "A, T, G, U"}], "answer": 0}$j$::jsonb, 1, $t$อะดีนีน ไทมีน กวานีน ไซโทซีน$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$เบสไนโตรเจนที่พบใน DNA ได้แก่ข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$เบสไนโตรเจนที่พบใน RNA แต่ไม่พบใน DNA คือข้อใด$t$, $j${"choices": [{"t": "ไทมีน (T)"}, {"t": "ยูราซิล (U)"}, {"t": "อะดีนีน (A)"}, {"t": "กวานีน (G)"}], "answer": 1}$j$::jsonb, 1, $t$U แทนที่ T ใน RNA$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$เบสไนโตรเจนที่พบใน RNA แต่ไม่พบใน DNA คือข้อใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$การจับคู่เบสใน DNA ข้อใดถูกต้อง$t$, $j${"choices": [{"t": "A กับ T และ G กับ C"}, {"t": "A กับ U และ G กับ T"}, {"t": "A กับ G และ T กับ C"}, {"t": "A กับ C และ G กับ T"}], "answer": 0}$j$::jsonb, 1, $t$ด้วยพันธะไฮโดรเจน$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$การจับคู่เบสใน DNA ข้อใดถูกต้อง$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$คู่เบส G-C มีพันธะไฮโดรเจนกี่พันธะ$t$, $j${"choices": [{"t": "1 พันธะ"}, {"t": "2 พันธะ"}, {"t": "3 พันธะ"}, {"t": "4 พันธะ"}], "answer": 2}$j$::jsonb, 1, $t$A-T มี 2 พันธะ$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$คู่เบส G-C มีพันธะไฮโดรเจนกี่พันธะ$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'mcq', $t$ถ้าสาย DNA สายหนึ่งมีลำดับเบส ATGC สายคู่สมที่จับคู่เบสตรงกันทีละตำแหน่งมีลำดับเบสใด$t$, $j${"choices": [{"t": "ATGC"}, {"t": "UACG"}, {"t": "TACG"}, {"t": "GCAT"}], "answer": 2}$j$::jsonb, 1, $t$A→T, T→A, G→C, C→G (DNA ไม่มี U)$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$ถ้าสาย DNA สายหนึ่งมีลำดับเบส ATGC สายคู่สมที่จับคู่เบสตรงกันทีละตำแหน่งมีลำดับเบสใด$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'tf', $t$DNA เป็นสายเกลียวคู่ ส่วน RNA โดยทั่วไปเป็นสายเดี่ยว$t$, $j${"answer": true}$j$::jsonb, 1, $t$เป็นความแตกต่างสำคัญของ DNA และ RNA$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$DNA เป็นสายเกลียวคู่ ส่วน RNA โดยทั่วไปเป็นสายเดี่ยว$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'tf', $t$ไขมันอิ่มตัวมีพันธะคู่ C=C ในสายกรดไขมัน$t$, $j${"answer": false}$j$::jsonb, 1, $t$ไขมันอิ่มตัวไม่มีพันธะคู่ C=C$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$ไขมันอิ่มตัวมีพันธะคู่ C=C ในสายกรดไขมัน$t$);
insert into exam_questions (topic, kind, q, data, points, explain)
select $t$ลิพิดและกรดนิวคลีอิก$t$, 'match', $t$จับคู่ส่วนประกอบกับกรดนิวคลีอิก$t$, $j${"left": [{"t": "น้ำตาลดีออกซีไรโบส"}, {"t": "น้ำตาลไรโบส"}, {"t": "เบสไทมีน (T)"}, {"t": "เบสยูราซิล (U)"}], "right": [{"t": "DNA"}, {"t": "DNA"}, {"t": "RNA"}, {"t": "RNA"}, {"t": "โปรตีน"}], "pairs": [1, 2, 0, 3]}$j$::jsonb, 4, $t$ใช้ความแตกต่างของน้ำตาลและเบส$t$
where not exists (select 1 from exam_questions where topic = $t$ลิพิดและกรดนิวคลีอิก$t$ and q = $t$จับคู่ส่วนประกอบกับกรดนิวคลีอิก$t$);
