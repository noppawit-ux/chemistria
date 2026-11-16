-- 78: ข้อสอบพื้นฐานเคมี เน้นจำ 300 ข้อ สำหรับควิซประจำวัน (v2.19) · รันซ้ำได้ (ข้อที่หัวข้อ + โจทย์ซ้ำจะไม่ถูกเพิ่ม)
--  · ทุกห้อง (class_id ว่าง) · ปิดข้อที่ไม่เหมาะกับห้องได้ในแท็บ 🎮 มินิเกม
--  · สัญลักษณ์ธาตุ 37 · เลขอะตอม 15 · หมู่ของธาตุ 21 · ไอออนและประจุ 20 · สูตรและชื่อสาร 34 · ไอออนอะตอมกลุ่ม 18 · กรด-เบส 14 · อินดิเคเตอร์ 14 · อุปกรณ์วิทยาศาสตร์ 18 · ความปลอดภัยในห้องปฏิบัติการ 12 · หน่วยและการวัด 12 · นักวิทยาศาสตร์และแบบจำลองอะตอม 14 · สถานะและการเปลี่ยนสถานะ 6 · การแยกสาร 10 · สารในชีวิตประจำวัน 18 · โมลและมวลโมเลกุล 15 · สมบัติธาตุตามหมู่และคาบ 13 · แก๊สและการทดสอบแก๊ส 9

insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$H เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$โคบอลต์$t$, $t$คลอรีน$t$, $t$โครเมียม$t$, $t$ไฮโดรเจน$t$, 3, $t$H คือ ไฮโดรเจน$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$H เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของฮีเลียมคือข้อใด$t$, $t$H$t$, $t$He$t$, $t$Hg$t$, $t$Cr$t$, 1, $t$ฮีเลียม = He$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของฮีเลียมคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$Li เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$ออกซิเจน$t$, $t$เบริลเลียม$t$, $t$กำมะถัน (ซัลเฟอร์)$t$, $t$ลิเทียม$t$, 3, $t$Li คือ ลิเทียม$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$Li เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของเบริลเลียมคือข้อใด$t$, $t$Be$t$, $t$B$t$, $t$Ba$t$, $t$Br$t$, 0, $t$เบริลเลียม = Be$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของเบริลเลียมคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$B เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$แพลทินัม$t$, $t$ฟอสฟอรัส$t$, $t$ฮีเลียม$t$, $t$โบรอน$t$, 3, $t$B คือ โบรอน$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$B เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของคาร์บอนคือข้อใด$t$, $t$Ca$t$, $t$C$t$, $t$Cr$t$, $t$Cl$t$, 1, $t$คาร์บอน = C$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของคาร์บอนคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$N เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$ไนโตรเจน$t$, $t$เบริลเลียม$t$, $t$กำมะถัน (ซัลเฟอร์)$t$, $t$ซิลิคอน$t$, 0, $t$N คือ ไนโตรเจน$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$N เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของออกซิเจนคือข้อใด$t$, $t$O$t$, $t$Co$t$, $t$Cl$t$, $t$Si$t$, 0, $t$ออกซิเจน = O$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของออกซิเจนคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$F เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$แพลทินัม$t$, $t$ฟลูออรีน$t$, $t$ไฮโดรเจน$t$, $t$นิกเกิล$t$, 1, $t$F คือ ฟลูออรีน$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$F เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของนีออนคือข้อใด$t$, $t$O$t$, $t$Ne$t$, $t$N$t$, $t$Ni$t$, 1, $t$นีออน = Ne$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของนีออนคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$Mg เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$กำมะถัน (ซัลเฟอร์)$t$, $t$แมกนีเซียม$t$, $t$เบริลเลียม$t$, $t$ลิเทียม$t$, 1, $t$Mg คือ แมกนีเซียม$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$Mg เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของอะลูมิเนียมคือข้อใด$t$, $t$Al$t$, $t$Ar$t$, $t$Zn$t$, $t$Ca$t$, 0, $t$อะลูมิเนียม = Al$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของอะลูมิเนียมคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$Si เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$ฮีเลียม$t$, $t$กำมะถัน (ซัลเฟอร์)$t$, $t$ซิลิคอน$t$, $t$ออกซิเจน$t$, 2, $t$Si คือ ซิลิคอน$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$Si เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของฟอสฟอรัสคือข้อใด$t$, $t$Pt$t$, $t$Pb$t$, $t$P$t$, $t$F$t$, 2, $t$ฟอสฟอรัส = P$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของฟอสฟอรัสคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$S เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$ไทเทเนียม$t$, $t$ซีนอน$t$, $t$โบรมีน$t$, $t$กำมะถัน (ซัลเฟอร์)$t$, 3, $t$S คือ กำมะถัน (ซัลเฟอร์)$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$S เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของคลอรีนคือข้อใด$t$, $t$Cl$t$, $t$C$t$, $t$Ca$t$, $t$Cr$t$, 0, $t$คลอรีน = Cl$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของคลอรีนคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$Ar เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$นิกเกิล$t$, $t$อาร์กอน$t$, $t$ฟลูออรีน$t$, $t$ลิเทียม$t$, 1, $t$Ar คือ อาร์กอน$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$Ar เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของแคลเซียมคือข้อใด$t$, $t$C$t$, $t$Cr$t$, $t$Cl$t$, $t$Ca$t$, 3, $t$แคลเซียม = Ca$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของแคลเซียมคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$Zn เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$นิกเกิล$t$, $t$ฟลูออรีน$t$, $t$สังกะสี$t$, $t$นีออน$t$, 2, $t$Zn คือ สังกะสี$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$Zn เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของดีบุกคือข้อใด$t$, $t$S$t$, $t$Si$t$, $t$Be$t$, $t$Sn$t$, 3, $t$ดีบุก = Sn$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของดีบุกคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$Hg เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$แคลเซียม$t$, $t$ไทเทเนียม$t$, $t$โบรอน$t$, $t$ปรอท$t$, 3, $t$Hg คือ ปรอท$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$Hg เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของตะกั่วคือข้อใด$t$, $t$Pt$t$, $t$P$t$, $t$Pb$t$, $t$Zn$t$, 2, $t$ตะกั่ว = Pb$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของตะกั่วคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$Mn เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$แมงกานีส$t$, $t$ฟอสฟอรัส$t$, $t$คริปทอน$t$, $t$นิกเกิล$t$, 0, $t$Mn คือ แมงกานีส$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$Mn เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของโครเมียมคือข้อใด$t$, $t$Cr$t$, $t$C$t$, $t$Ca$t$, $t$Cl$t$, 0, $t$โครเมียม = Cr$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของโครเมียมคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$Ni เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$แมกนีเซียม$t$, $t$นิกเกิล$t$, $t$ฟลูออรีน$t$, $t$แบเรียม$t$, 1, $t$Ni คือ นิกเกิล$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$Ni เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของโบรมีนคือข้อใด$t$, $t$Be$t$, $t$Br$t$, $t$Ba$t$, $t$B$t$, 1, $t$โบรมีน = Br$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของโบรมีนคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$I เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$โคบอลต์$t$, $t$อะลูมิเนียม$t$, $t$ไอโอดีน$t$, $t$ดีบุก$t$, 2, $t$I คือ ไอโอดีน$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$I เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของแพลทินัมคือข้อใด$t$, $t$P$t$, $t$Kr$t$, $t$Pb$t$, $t$Pt$t$, 3, $t$แพลทินัม = Pt$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของแพลทินัมคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$U เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$คาร์บอน$t$, $t$ยูเรเนียม$t$, $t$ซีนอน$t$, $t$แมงกานีส$t$, 1, $t$U คือ ยูเรเนียม$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$U เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของแบเรียมคือข้อใด$t$, $t$B$t$, $t$Be$t$, $t$Ba$t$, $t$Br$t$, 2, $t$แบเรียม = Ba$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของแบเรียมคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$Co เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$ลิเทียม$t$, $t$แมกนีเซียม$t$, $t$โคบอลต์$t$, $t$แบเรียม$t$, 2, $t$Co คือ โคบอลต์$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$Co เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของไทเทเนียมคือข้อใด$t$, $t$O$t$, $t$Mn$t$, $t$Ti$t$, $t$Li$t$, 2, $t$ไทเทเนียม = Ti$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของไทเทเนียมคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$Kr เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$, $t$ฟลูออรีน$t$, $t$ฮีเลียม$t$, $t$คริปทอน$t$, $t$ไทเทเนียม$t$, 2, $t$Kr คือ คริปทอน$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$Kr เป็นสัญลักษณ์ทางเคมีของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$สัญลักษณ์ทางเคมีของซีนอนคือข้อใด$t$, $t$Xe$t$, $t$Be$t$, $t$Mn$t$, $t$Co$t$, 0, $t$ซีนอน = Xe$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$สัญลักษณ์ทางเคมีของซีนอนคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุทองแดงมีเลขอะตอมเท่าใด$t$, $t$28$t$, $t$30$t$, $t$31$t$, $t$29$t$, 3, $t$เลขอะตอมของทองแดง = 29 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุทองแดงมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุโซเดียมมีเลขอะตอมเท่าใด$t$, $t$12$t$, $t$11$t$, $t$10$t$, $t$13$t$, 1, $t$เลขอะตอมของโซเดียม = 11 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุโซเดียมมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุซิลิคอนมีเลขอะตอมเท่าใด$t$, $t$15$t$, $t$14$t$, $t$13$t$, $t$16$t$, 1, $t$เลขอะตอมของซิลิคอน = 14 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุซิลิคอนมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุโพแทสเซียมมีเลขอะตอมเท่าใด$t$, $t$20$t$, $t$21$t$, $t$18$t$, $t$19$t$, 3, $t$เลขอะตอมของโพแทสเซียม = 19 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุโพแทสเซียมมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุไฮโดรเจนมีเลขอะตอมเท่าใด$t$, $t$4$t$, $t$1$t$, $t$3$t$, $t$2$t$, 1, $t$เลขอะตอมของไฮโดรเจน = 1 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุไฮโดรเจนมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุกำมะถันมีเลขอะตอมเท่าใด$t$, $t$16$t$, $t$17$t$, $t$18$t$, $t$15$t$, 0, $t$เลขอะตอมของกำมะถัน = 16 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุกำมะถันมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุนีออนมีเลขอะตอมเท่าใด$t$, $t$10$t$, $t$11$t$, $t$9$t$, $t$12$t$, 0, $t$เลขอะตอมของนีออน = 10 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุนีออนมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุฟอสฟอรัสมีเลขอะตอมเท่าใด$t$, $t$14$t$, $t$16$t$, $t$15$t$, $t$17$t$, 2, $t$เลขอะตอมของฟอสฟอรัส = 15 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุฟอสฟอรัสมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุคาร์บอนมีเลขอะตอมเท่าใด$t$, $t$6$t$, $t$8$t$, $t$5$t$, $t$7$t$, 0, $t$เลขอะตอมของคาร์บอน = 6 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุคาร์บอนมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุอะลูมิเนียมมีเลขอะตอมเท่าใด$t$, $t$13$t$, $t$14$t$, $t$12$t$, $t$15$t$, 0, $t$เลขอะตอมของอะลูมิเนียม = 13 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุอะลูมิเนียมมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุอาร์กอนมีเลขอะตอมเท่าใด$t$, $t$20$t$, $t$18$t$, $t$19$t$, $t$17$t$, 1, $t$เลขอะตอมของอาร์กอน = 18 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุอาร์กอนมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุลิเทียมมีเลขอะตอมเท่าใด$t$, $t$3$t$, $t$2$t$, $t$5$t$, $t$4$t$, 0, $t$เลขอะตอมของลิเทียม = 3 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุลิเทียมมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุฮีเลียมมีเลขอะตอมเท่าใด$t$, $t$4$t$, $t$3$t$, $t$2$t$, $t$1$t$, 2, $t$เลขอะตอมของฮีเลียม = 2 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุฮีเลียมมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุเหล็กมีเลขอะตอมเท่าใด$t$, $t$28$t$, $t$27$t$, $t$25$t$, $t$26$t$, 3, $t$เลขอะตอมของเหล็ก = 26 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุเหล็กมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอม$t$, $t$ธาตุแคลเซียมมีเลขอะตอมเท่าใด$t$, $t$21$t$, $t$19$t$, $t$20$t$, $t$22$t$, 2, $t$เลขอะตอมของแคลเซียม = 20 (จำนวนโปรตอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอม$t$ and question = $t$ธาตุแคลเซียมมีเลขอะตอมเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$ลิเทียม (Li) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 1$t$, $t$หมู่ 18$t$, $t$หมู่ 2$t$, $t$หมู่ 16$t$, 0, $t$ลิเทียม อยู่หมู่ 1 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$ลิเทียม (Li) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$โซเดียม (Na) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 17$t$, $t$หมู่ 15$t$, $t$หมู่ 13$t$, $t$หมู่ 1$t$, 3, $t$โซเดียม อยู่หมู่ 1 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$โซเดียม (Na) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$โพแทสเซียม (K) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 2$t$, $t$หมู่ 17$t$, $t$หมู่ 15$t$, $t$หมู่ 1$t$, 3, $t$โพแทสเซียม อยู่หมู่ 1 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$โพแทสเซียม (K) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$เบริลเลียม (Be) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 1$t$, $t$หมู่ 2$t$, $t$หมู่ 18$t$, $t$หมู่ 17$t$, 1, $t$เบริลเลียม อยู่หมู่ 2 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$เบริลเลียม (Be) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$แมกนีเซียม (Mg) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 1$t$, $t$หมู่ 2$t$, $t$หมู่ 15$t$, $t$หมู่ 13$t$, 1, $t$แมกนีเซียม อยู่หมู่ 2 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$แมกนีเซียม (Mg) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$แคลเซียม (Ca) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 2$t$, $t$หมู่ 14$t$, $t$หมู่ 17$t$, $t$หมู่ 16$t$, 0, $t$แคลเซียม อยู่หมู่ 2 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$แคลเซียม (Ca) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$โบรอน (B) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 13$t$, $t$หมู่ 14$t$, $t$หมู่ 15$t$, $t$หมู่ 16$t$, 0, $t$โบรอน อยู่หมู่ 13 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$โบรอน (B) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$อะลูมิเนียม (Al) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 2$t$, $t$หมู่ 17$t$, $t$หมู่ 13$t$, $t$หมู่ 18$t$, 2, $t$อะลูมิเนียม อยู่หมู่ 13 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$อะลูมิเนียม (Al) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$คาร์บอน (C) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 14$t$, $t$หมู่ 13$t$, $t$หมู่ 17$t$, $t$หมู่ 18$t$, 0, $t$คาร์บอน อยู่หมู่ 14 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$คาร์บอน (C) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$ซิลิคอน (Si) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 13$t$, $t$หมู่ 14$t$, $t$หมู่ 16$t$, $t$หมู่ 1$t$, 1, $t$ซิลิคอน อยู่หมู่ 14 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$ซิลิคอน (Si) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$ไนโตรเจน (N) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 16$t$, $t$หมู่ 15$t$, $t$หมู่ 2$t$, $t$หมู่ 18$t$, 1, $t$ไนโตรเจน อยู่หมู่ 15 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$ไนโตรเจน (N) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$ฟอสฟอรัส (P) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 18$t$, $t$หมู่ 2$t$, $t$หมู่ 1$t$, $t$หมู่ 15$t$, 3, $t$ฟอสฟอรัส อยู่หมู่ 15 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$ฟอสฟอรัส (P) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$ออกซิเจน (O) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 14$t$, $t$หมู่ 15$t$, $t$หมู่ 16$t$, $t$หมู่ 18$t$, 2, $t$ออกซิเจน อยู่หมู่ 16 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$ออกซิเจน (O) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$กำมะถัน (S) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 16$t$, $t$หมู่ 13$t$, $t$หมู่ 15$t$, $t$หมู่ 2$t$, 0, $t$กำมะถัน อยู่หมู่ 16 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$กำมะถัน (S) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$ฟลูออรีน (F) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 2$t$, $t$หมู่ 16$t$, $t$หมู่ 17$t$, $t$หมู่ 13$t$, 2, $t$ฟลูออรีน อยู่หมู่ 17 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$ฟลูออรีน (F) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$คลอรีน (Cl) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 16$t$, $t$หมู่ 13$t$, $t$หมู่ 18$t$, $t$หมู่ 17$t$, 3, $t$คลอรีน อยู่หมู่ 17 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$คลอรีน (Cl) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$โบรมีน (Br) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 13$t$, $t$หมู่ 17$t$, $t$หมู่ 14$t$, $t$หมู่ 16$t$, 1, $t$โบรมีน อยู่หมู่ 17 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$โบรมีน (Br) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$ไอโอดีน (I) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 13$t$, $t$หมู่ 14$t$, $t$หมู่ 16$t$, $t$หมู่ 17$t$, 3, $t$ไอโอดีน อยู่หมู่ 17 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$ไอโอดีน (I) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$นีออน (Ne) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 1$t$, $t$หมู่ 18$t$, $t$หมู่ 15$t$, $t$หมู่ 2$t$, 1, $t$นีออน อยู่หมู่ 18 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$นีออน (Ne) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$อาร์กอน (Ar) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$, $t$หมู่ 18$t$, $t$หมู่ 13$t$, $t$หมู่ 17$t$, $t$หมู่ 14$t$, 0, $t$อาร์กอน อยู่หมู่ 18 (หมู่เดียวกันมีเวเลนซ์อิเล็กตรอนเท่ากันและสมบัติคล้ายกัน)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$อาร์กอน (Ar) อยู่ในหมู่ใดของตารางธาตุ (ระบบหมู่ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของโซเดียมมีสัญลักษณ์ใด$t$, $t$Na⁺$t$, $t$Na²⁻$t$, $t$Na⁻$t$, $t$Na²⁺$t$, 0, $t$Na⁺ — ให้ e⁻ เกิดไอออนบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของโซเดียมมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของโพแทสเซียมมีสัญลักษณ์ใด$t$, $t$K³⁺$t$, $t$K²⁻$t$, $t$K²⁺$t$, $t$K⁺$t$, 3, $t$K⁺ — ให้ e⁻ เกิดไอออนบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของโพแทสเซียมมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของลิเทียมมีสัญลักษณ์ใด$t$, $t$Li²⁺$t$, $t$Li⁺$t$, $t$Li²⁻$t$, $t$Li³⁺$t$, 1, $t$Li⁺ — ให้ e⁻ เกิดไอออนบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของลิเทียมมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของเงินมีสัญลักษณ์ใด$t$, $t$Ag²⁻$t$, $t$Ag³⁻$t$, $t$Ag⁺$t$, $t$Ag³⁺$t$, 2, $t$Ag⁺ — ให้ e⁻ เกิดไอออนบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของเงินมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของแมกนีเซียมมีสัญลักษณ์ใด$t$, $t$Mg²⁺$t$, $t$Mg⁻$t$, $t$Mg²⁻$t$, $t$Mg³⁻$t$, 0, $t$Mg²⁺ — ให้ e⁻ เกิดไอออนบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของแมกนีเซียมมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของแคลเซียมมีสัญลักษณ์ใด$t$, $t$Ca⁺$t$, $t$Ca²⁻$t$, $t$Ca³⁺$t$, $t$Ca²⁺$t$, 3, $t$Ca²⁺ — ให้ e⁻ เกิดไอออนบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของแคลเซียมมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของแบเรียมมีสัญลักษณ์ใด$t$, $t$Ba⁺$t$, $t$Ba³⁺$t$, $t$Ba⁻$t$, $t$Ba²⁺$t$, 3, $t$Ba²⁺ — ให้ e⁻ เกิดไอออนบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของแบเรียมมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของสังกะสีมีสัญลักษณ์ใด$t$, $t$Zn²⁻$t$, $t$Zn³⁺$t$, $t$Zn²⁺$t$, $t$Zn⁺$t$, 2, $t$Zn²⁺ — ให้ e⁻ เกิดไอออนบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของสังกะสีมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของอะลูมิเนียมมีสัญลักษณ์ใด$t$, $t$Al⁻$t$, $t$Al²⁺$t$, $t$Al⁺$t$, $t$Al³⁺$t$, 3, $t$Al³⁺ — ให้ e⁻ เกิดไอออนบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของอะลูมิเนียมมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของคลอรีนมีสัญลักษณ์ใด$t$, $t$Cl⁻$t$, $t$Cl⁺$t$, $t$Cl²⁺$t$, $t$Cl³⁺$t$, 0, $t$Cl⁻ — รับ e⁻ เกิดไอออนลบ$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของคลอรีนมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของโบรมีนมีสัญลักษณ์ใด$t$, $t$Br²⁻$t$, $t$Br⁻$t$, $t$Br²⁺$t$, $t$Br³⁺$t$, 1, $t$Br⁻ — รับ e⁻ เกิดไอออนลบ$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของโบรมีนมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของไอโอดีนมีสัญลักษณ์ใด$t$, $t$I⁻$t$, $t$I⁺$t$, $t$I²⁺$t$, $t$I³⁻$t$, 0, $t$I⁻ — รับ e⁻ เกิดไอออนลบ$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของไอโอดีนมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของฟลูออรีนมีสัญลักษณ์ใด$t$, $t$F⁻$t$, $t$F²⁻$t$, $t$F⁺$t$, $t$F²⁺$t$, 0, $t$F⁻ — รับ e⁻ เกิดไอออนลบ$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของฟลูออรีนมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของออกซิเจนมีสัญลักษณ์ใด$t$, $t$O²⁻$t$, $t$O⁺$t$, $t$O³⁺$t$, $t$O³⁻$t$, 0, $t$O²⁻ — รับ e⁻ เกิดไอออนลบ$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของออกซิเจนมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของกำมะถันมีสัญลักษณ์ใด$t$, $t$S³⁻$t$, $t$S²⁺$t$, $t$S²⁻$t$, $t$S⁻$t$, 2, $t$S²⁻ — รับ e⁻ เกิดไอออนลบ$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของกำมะถันมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของไนโตรเจนมีสัญลักษณ์ใด$t$, $t$N³⁺$t$, $t$N²⁺$t$, $t$N³⁻$t$, $t$N⁺$t$, 2, $t$N³⁻ — รับ e⁻ เกิดไอออนลบ$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของไนโตรเจนมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนที่เสถียรของซีเซียมมีสัญลักษณ์ใด$t$, $t$Cs⁻$t$, $t$Cs²⁻$t$, $t$Cs⁺$t$, $t$Cs³⁻$t$, 2, $t$Cs⁺ — ให้ e⁻ เกิดไอออนบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนที่เสถียรของซีเซียมมีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนของทองแดง(II)มีสัญลักษณ์ใด$t$, $t$Cu³⁺$t$, $t$Cu²⁻$t$, $t$Cu²⁺$t$, $t$Cu⁺$t$, 2, $t$Cu²⁺ — ให้ e⁻ เกิดไอออนบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนของทองแดง(II)มีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนของตะกั่ว(II)มีสัญลักษณ์ใด$t$, $t$Pb³⁺$t$, $t$Pb²⁻$t$, $t$Pb²⁺$t$, $t$Pb⁻$t$, 2, $t$Pb²⁺ — ให้ e⁻ เกิดไอออนบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนของตะกั่ว(II)มีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนและประจุ$t$, $t$ไอออนของเหล็ก(III)มีสัญลักษณ์ใด$t$, $t$Fe²⁺$t$, $t$Fe³⁺$t$, $t$Fe⁺$t$, $t$Fe²⁻$t$, 1, $t$Fe³⁺ — ให้ e⁻ เกิดไอออนบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนและประจุ$t$ and question = $t$ไอออนของเหล็ก(III)มีสัญลักษณ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร CO₂ มีชื่อว่าอะไร$t$, $t$แคลเซียมไฮดรอกไซด์$t$, $t$คาร์บอนไดออกไซด์$t$, $t$แมกนีเซียมไฮดรอกไซด์$t$, $t$กรดซัลฟิวริก$t$, 1, $t$CO₂ คือ คาร์บอนไดออกไซด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร CO₂ มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของแอมโมเนียคือข้อใด$t$, $t$NH₃$t$, $t$SO₃$t$, $t$P₂O₅$t$, $t$CaCO₃$t$, 0, $t$แอมโมเนีย = NH₃$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของแอมโมเนียคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร CH₄ มีชื่อว่าอะไร$t$, $t$โซเดียมไฮดรอกไซด์$t$, $t$แบเรียมซัลเฟต$t$, $t$คาร์บอนมอนอกไซด์$t$, $t$มีเทน$t$, 3, $t$CH₄ คือ มีเทน$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร CH₄ มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของโซเดียมคลอไรด์คือข้อใด$t$, $t$CaCO₃$t$, $t$H₂SO₄$t$, $t$NaOH$t$, $t$NaCl$t$, 3, $t$โซเดียมคลอไรด์ = NaCl$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของโซเดียมคลอไรด์คือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร H₂O₂ มีชื่อว่าอะไร$t$, $t$คาร์บอนไดออกไซด์$t$, $t$แคลเซียมคลอไรด์$t$, $t$ไฮโดรเจนเปอร์ออกไซด์$t$, $t$ซัลเฟอร์ไตรออกไซด์$t$, 2, $t$H₂O₂ คือ ไฮโดรเจนเปอร์ออกไซด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร H₂O₂ มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของโซเดียมไฮดรอกไซด์คือข้อใด$t$, $t$NH₃$t$, $t$NaOH$t$, $t$Fe₂O₃$t$, $t$NaHCO₃$t$, 1, $t$โซเดียมไฮดรอกไซด์ = NaOH$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของโซเดียมไฮดรอกไซด์คือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร HCl มีชื่อว่าอะไร$t$, $t$อะลูมิเนียมออกไซด์$t$, $t$โซเดียมคาร์บอเนต$t$, $t$โซเดียมซัลเฟต$t$, $t$กรดไฮโดรคลอริก$t$, 3, $t$HCl คือ กรดไฮโดรคลอริก$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร HCl มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของกรดซัลฟิวริกคือข้อใด$t$, $t$H₂SO₄$t$, $t$KCl$t$, $t$BaSO₄$t$, $t$CH₄$t$, 0, $t$กรดซัลฟิวริก = H₂SO₄$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของกรดซัลฟิวริกคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร HNO₃ มีชื่อว่าอะไร$t$, $t$น้ำ$t$, $t$แอมโมเนีย$t$, $t$กรดไนตริก$t$, $t$ซิลิคอนไดออกไซด์$t$, 2, $t$HNO₃ คือ กรดไนตริก$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร HNO₃ มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของแคลเซียมคาร์บอเนตคือข้อใด$t$, $t$CaCO₃$t$, $t$H₂S$t$, $t$HNO₃$t$, $t$H₂SO₄$t$, 0, $t$แคลเซียมคาร์บอเนต = CaCO₃$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของแคลเซียมคาร์บอเนตคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร CaO มีชื่อว่าอะไร$t$, $t$โพแทสเซียมเปอร์แมงกาเนต$t$, $t$แมกนีเซียมออกไซด์$t$, $t$แคลเซียมออกไซด์$t$, $t$แอมโมเนีย$t$, 2, $t$CaO คือ แคลเซียมออกไซด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร CaO มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของแมกนีเซียมออกไซด์คือข้อใด$t$, $t$CH₄$t$, $t$Mg(OH)₂$t$, $t$MgO$t$, $t$Fe₂O₃$t$, 2, $t$แมกนีเซียมออกไซด์ = MgO$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของแมกนีเซียมออกไซด์คือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร Fe₂O₃ มีชื่อว่าอะไร$t$, $t$ซัลเฟอร์ไตรออกไซด์$t$, $t$โพแทสเซียมคลอไรด์$t$, $t$ไดฟอสฟอรัสเพนตะออกไซด์$t$, $t$เหล็ก(III) ออกไซด์$t$, 3, $t$Fe₂O₃ คือ เหล็ก(III) ออกไซด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร Fe₂O₃ มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของอะลูมิเนียมออกไซด์คือข้อใด$t$, $t$CaCO₃$t$, $t$P₂O₅$t$, $t$Al₂O₃$t$, $t$Ca(OH)₂$t$, 2, $t$อะลูมิเนียมออกไซด์ = Al₂O₃$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของอะลูมิเนียมออกไซด์คือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร NaHCO₃ มีชื่อว่าอะไร$t$, $t$โซเดียมไฮโดรเจนคาร์บอเนต$t$, $t$ไฮโดรเจนเปอร์ออกไซด์$t$, $t$โซเดียมคาร์บอเนต$t$, $t$ซิลิคอนไดออกไซด์$t$, 0, $t$NaHCO₃ คือ โซเดียมไฮโดรเจนคาร์บอเนต$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร NaHCO₃ มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของโพแทสเซียมไนเตรตคือข้อใด$t$, $t$NaHCO₃$t$, $t$KNO₃$t$, $t$CaO$t$, $t$CO$t$, 1, $t$โพแทสเซียมไนเตรต = KNO₃$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของโพแทสเซียมไนเตรตคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร CaCl₂ มีชื่อว่าอะไร$t$, $t$แคลเซียมคลอไรด์$t$, $t$กรดฟอสฟอริก$t$, $t$โซเดียมคลอไรด์$t$, $t$แมกนีเซียมออกไซด์$t$, 0, $t$CaCl₂ คือ แคลเซียมคลอไรด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร CaCl₂ มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของซิงค์ออกไซด์คือข้อใด$t$, $t$H₂S$t$, $t$H₂SO₄$t$, $t$Al₂O₃$t$, $t$ZnO$t$, 3, $t$ซิงค์ออกไซด์ = ZnO$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของซิงค์ออกไซด์คือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร AgNO₃ มีชื่อว่าอะไร$t$, $t$แมกนีเซียมไฮดรอกไซด์$t$, $t$กรดไนตริก$t$, $t$ซิลิคอนไดออกไซด์$t$, $t$ซิลเวอร์ไนเตรต$t$, 3, $t$AgNO₃ คือ ซิลเวอร์ไนเตรต$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร AgNO₃ มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของโพแทสเซียมคลอไรด์คือข้อใด$t$, $t$CH₄$t$, $t$NaHCO₃$t$, $t$CO$t$, $t$KCl$t$, 3, $t$โพแทสเซียมคลอไรด์ = KCl$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของโพแทสเซียมคลอไรด์คือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร NH₄Cl มีชื่อว่าอะไร$t$, $t$แอมโมเนียมคลอไรด์$t$, $t$โพแทสเซียมคลอไรด์$t$, $t$โพแทสเซียมไนเตรต$t$, $t$คาร์บอนไดออกไซด์$t$, 0, $t$NH₄Cl คือ แอมโมเนียมคลอไรด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร NH₄Cl มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของคาร์บอนมอนอกไซด์คือข้อใด$t$, $t$SiO₂$t$, $t$CO$t$, $t$NaOH$t$, $t$NH₃$t$, 1, $t$คาร์บอนมอนอกไซด์ = CO$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของคาร์บอนมอนอกไซด์คือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร SO₂ มีชื่อว่าอะไร$t$, $t$กรดไฮโดรคลอริก$t$, $t$ซิงค์ออกไซด์$t$, $t$แคลเซียมไฮดรอกไซด์$t$, $t$ซัลเฟอร์ไดออกไซด์$t$, 3, $t$SO₂ คือ ซัลเฟอร์ไดออกไซด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร SO₂ มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของซัลเฟอร์ไตรออกไซด์คือข้อใด$t$, $t$HNO₃$t$, $t$MgO$t$, $t$H₃PO₄$t$, $t$SO₃$t$, 3, $t$ซัลเฟอร์ไตรออกไซด์ = SO₃$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของซัลเฟอร์ไตรออกไซด์คือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร SiO₂ มีชื่อว่าอะไร$t$, $t$โพแทสเซียมคลอไรด์$t$, $t$ไดฟอสฟอรัสเพนตะออกไซด์$t$, $t$โซเดียมไฮโดรเจนคาร์บอเนต$t$, $t$ซิลิคอนไดออกไซด์$t$, 3, $t$SiO₂ คือ ซิลิคอนไดออกไซด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร SiO₂ มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของโพแทสเซียมเปอร์แมงกาเนตคือข้อใด$t$, $t$H₂S$t$, $t$HCl$t$, $t$Na₂CO₃$t$, $t$KMnO₄$t$, 3, $t$โพแทสเซียมเปอร์แมงกาเนต = KMnO₄$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของโพแทสเซียมเปอร์แมงกาเนตคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร BaSO₄ มีชื่อว่าอะไร$t$, $t$มีเทน$t$, $t$คาร์บอนไดออกไซด์$t$, $t$แบเรียมซัลเฟต$t$, $t$แอมโมเนีย$t$, 2, $t$BaSO₄ คือ แบเรียมซัลเฟต$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร BaSO₄ มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของแคลเซียมไฮดรอกไซด์คือข้อใด$t$, $t$Ca(OH)₂$t$, $t$CaCO₃$t$, $t$HCl$t$, $t$H₂O₂$t$, 0, $t$แคลเซียมไฮดรอกไซด์ = Ca(OH)₂$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของแคลเซียมไฮดรอกไซด์คือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร Na₂CO₃ มีชื่อว่าอะไร$t$, $t$โซเดียมคาร์บอเนต$t$, $t$กรดไฮโดรคลอริก$t$, $t$น้ำ$t$, $t$โพแทสเซียมไนเตรต$t$, 0, $t$Na₂CO₃ คือ โซเดียมคาร์บอเนต$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร Na₂CO₃ มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของกรดฟอสฟอริกคือข้อใด$t$, $t$H₂O$t$, $t$H₃PO₄$t$, $t$NaHCO₃$t$, $t$H₂SO₄$t$, 1, $t$กรดฟอสฟอริก = H₃PO₄$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของกรดฟอสฟอริกคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร H₂S มีชื่อว่าอะไร$t$, $t$ไฮโดรเจนซัลไฟด์$t$, $t$แอมโมเนียมคลอไรด์$t$, $t$ซัลเฟอร์ไตรออกไซด์$t$, $t$แมกนีเซียมไฮดรอกไซด์$t$, 0, $t$H₂S คือ ไฮโดรเจนซัลไฟด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร H₂S มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของไดฟอสฟอรัสเพนตะออกไซด์คือข้อใด$t$, $t$NH₃$t$, $t$P₂O₅$t$, $t$MgO$t$, $t$NaCl$t$, 1, $t$ไดฟอสฟอรัสเพนตะออกไซด์ = P₂O₅$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของไดฟอสฟอรัสเพนตะออกไซด์คือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สาร Mg(OH)₂ มีชื่อว่าอะไร$t$, $t$อะลูมิเนียมออกไซด์$t$, $t$โซเดียมคาร์บอเนต$t$, $t$แมกนีเซียมไฮดรอกไซด์$t$, $t$โซเดียมซัลเฟต$t$, 2, $t$Mg(OH)₂ คือ แมกนีเซียมไฮดรอกไซด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สาร Mg(OH)₂ มีชื่อว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรและชื่อสาร$t$, $t$สูตรเคมีของโซเดียมซัลเฟตคือข้อใด$t$, $t$Mg(OH)₂$t$, $t$BaSO₄$t$, $t$Ca(OH)₂$t$, $t$Na₂SO₄$t$, 3, $t$โซเดียมซัลเฟต = Na₂SO₄$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรและชื่อสาร$t$ and question = $t$สูตรเคมีของโซเดียมซัลเฟตคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนไฮดรอกไซด์มีสูตรตามข้อใด$t$, $t$SO₃²⁻$t$, $t$CH₃COO⁻$t$, $t$PO₄³⁻$t$, $t$OH⁻$t$, 3, $t$ไฮดรอกไซด์ = OH⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนไฮดรอกไซด์มีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนไนเตรตมีสูตรตามข้อใด$t$, $t$CH₃COO⁻$t$, $t$NO₃⁻$t$, $t$CO₃²⁻$t$, $t$CrO₄²⁻$t$, 1, $t$ไนเตรต = NO₃⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนไนเตรตมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนซัลเฟตมีสูตรตามข้อใด$t$, $t$SO₃²⁻$t$, $t$CH₃COO⁻$t$, $t$C₂O₄²⁻$t$, $t$SO₄²⁻$t$, 3, $t$ซัลเฟต = SO₄²⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนซัลเฟตมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนคาร์บอเนตมีสูตรตามข้อใด$t$, $t$OH⁻$t$, $t$PO₄³⁻$t$, $t$SO₃²⁻$t$, $t$CO₃²⁻$t$, 3, $t$คาร์บอเนต = CO₃²⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนคาร์บอเนตมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนฟอสเฟตมีสูตรตามข้อใด$t$, $t$OH⁻$t$, $t$NO₃⁻$t$, $t$PO₄³⁻$t$, $t$H₃O⁺$t$, 2, $t$ฟอสเฟต = PO₄³⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนฟอสเฟตมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนแอมโมเนียมมีสูตรตามข้อใด$t$, $t$NH₄⁺$t$, $t$H₃O⁺$t$, $t$CO₃²⁻$t$, $t$NO₃⁻$t$, 0, $t$แอมโมเนียม = NH₄⁺$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนแอมโมเนียมมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนไฮโดรเจนคาร์บอเนตมีสูตรตามข้อใด$t$, $t$CO₃²⁻$t$, $t$MnO₄⁻$t$, $t$Cr₂O₇²⁻$t$, $t$HCO₃⁻$t$, 3, $t$ไฮโดรเจนคาร์บอเนต = HCO₃⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนไฮโดรเจนคาร์บอเนตมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนไนไตรต์มีสูตรตามข้อใด$t$, $t$CrO₄²⁻$t$, $t$NO₂⁻$t$, $t$OH⁻$t$, $t$HCO₃⁻$t$, 1, $t$ไนไตรต์ = NO₂⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนไนไตรต์มีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนซัลไฟต์มีสูตรตามข้อใด$t$, $t$CO₃²⁻$t$, $t$SO₄²⁻$t$, $t$NO₃⁻$t$, $t$SO₃²⁻$t$, 3, $t$ซัลไฟต์ = SO₃²⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนซัลไฟต์มีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนเปอร์แมงกาเนตมีสูตรตามข้อใด$t$, $t$HSO₄⁻$t$, $t$PO₄³⁻$t$, $t$MnO₄⁻$t$, $t$NO₂⁻$t$, 2, $t$เปอร์แมงกาเนต = MnO₄⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนเปอร์แมงกาเนตมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนไดโครเมตมีสูตรตามข้อใด$t$, $t$HCO₃⁻$t$, $t$OH⁻$t$, $t$NO₃⁻$t$, $t$Cr₂O₇²⁻$t$, 3, $t$ไดโครเมต = Cr₂O₇²⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนไดโครเมตมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนโครเมตมีสูตรตามข้อใด$t$, $t$NH₄⁺$t$, $t$CrO₄²⁻$t$, $t$CN⁻$t$, $t$HSO₄⁻$t$, 1, $t$โครเมต = CrO₄²⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนโครเมตมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนไฮโดรเนียมมีสูตรตามข้อใด$t$, $t$OH⁻$t$, $t$CrO₄²⁻$t$, $t$H₃O⁺$t$, $t$SO₄²⁻$t$, 2, $t$ไฮโดรเนียม = H₃O⁺$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนไฮโดรเนียมมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนแอซีเตตมีสูตรตามข้อใด$t$, $t$HSO₄⁻$t$, $t$CO₃²⁻$t$, $t$CH₃COO⁻$t$, $t$H₃O⁺$t$, 2, $t$แอซีเตต = CH₃COO⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนแอซีเตตมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนคลอเรตมีสูตรตามข้อใด$t$, $t$ClO₃⁻$t$, $t$CrO₄²⁻$t$, $t$HCO₃⁻$t$, $t$PO₄³⁻$t$, 0, $t$คลอเรต = ClO₃⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนคลอเรตมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนไฮโดรเจนซัลเฟตมีสูตรตามข้อใด$t$, $t$HSO₄⁻$t$, $t$OH⁻$t$, $t$ClO₃⁻$t$, $t$MnO₄⁻$t$, 0, $t$ไฮโดรเจนซัลเฟต = HSO₄⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนไฮโดรเจนซัลเฟตมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนไซยาไนด์มีสูตรตามข้อใด$t$, $t$CN⁻$t$, $t$MnO₄⁻$t$, $t$CH₃COO⁻$t$, $t$NO₃⁻$t$, 0, $t$ไซยาไนด์ = CN⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนไซยาไนด์มีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ไอออนอะตอมกลุ่ม$t$, $t$ไอออนออกซาเลตมีสูตรตามข้อใด$t$, $t$H₃O⁺$t$, $t$PO₄³⁻$t$, $t$CO₃²⁻$t$, $t$C₂O₄²⁻$t$, 3, $t$ออกซาเลต = C₂O₄²⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$ไอออนอะตอมกลุ่ม$t$ and question = $t$ไอออนออกซาเลตมีสูตรตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$กรดชนิดใดมีอยู่ในกระเพาะอาหารของมนุษย์$t$, $t$กรดซัลฟิวริก$t$, $t$กรดไฮโดรคลอริก (HCl)$t$, $t$กรดแอซีติก$t$, $t$กรดไนตริก$t$, 1, $t$ช่วยย่อยอาหารและฆ่าเชื้อโรค$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$กรดชนิดใดมีอยู่ในกระเพาะอาหารของมนุษย์$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$กรดที่ใช้ในแบตเตอรี่รถยนต์คือข้อใด$t$, $t$กรดแอซีติก$t$, $t$กรดไฮโดรคลอริก$t$, $t$กรดซิตริก$t$, $t$กรดซัลฟิวริก (H₂SO₄)$t$, 3, $t$แบตเตอรี่ตะกั่ว-กรดใช้สารละลาย H₂SO₄$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$กรดที่ใช้ในแบตเตอรี่รถยนต์คือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$กรดที่ทำให้น้ำมะนาวมีรสเปรี้ยวคือกรดชนิดใด$t$, $t$กรดซิตริก$t$, $t$กรดแอซีติก$t$, $t$กรดแลกติก$t$, $t$กรดฟอร์มิก$t$, 0, $t$พบในผลไม้ตระกูลส้ม$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$กรดที่ทำให้น้ำมะนาวมีรสเปรี้ยวคือกรดชนิดใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$สารละลายที่มีค่า pH เท่ากับ 7 ที่ 25 องศาเซลเซียส มีสมบัติเป็นอย่างไร$t$, $t$เป็นกลาง$t$, $t$เป็นเบสอ่อน$t$, $t$เป็นกรดแก่$t$, $t$เป็นกรดอ่อน$t$, 0, $t$น้ำบริสุทธิ์มี pH = 7$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$สารละลายที่มีค่า pH เท่ากับ 7 ที่ 25 องศาเซลเซียส มีสมบัติเป็นอย่างไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$สารละลายที่มี pH น้อยกว่า 7 มีสมบัติอย่างไร$t$, $t$เป็นเบส$t$, $t$เป็นกลาง$t$, $t$เป็นเกลือเท่านั้น$t$, $t$เป็นกรด$t$, 3, $t$pH ต่ำ = ความเป็นกรดสูง$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$สารละลายที่มี pH น้อยกว่า 7 มีสมบัติอย่างไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$สารละลายที่มี pH มากกว่า 7 มีสมบัติอย่างไร$t$, $t$เป็นกลาง$t$, $t$เป็นเกลือเสมอ$t$, $t$เป็นกรด$t$, $t$เป็นเบส$t$, 3, $t$pH สูง = ความเป็นเบสสูง$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$สารละลายที่มี pH มากกว่า 7 มีสมบัติอย่างไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$ปฏิกิริยาระหว่างกรดกับเบสเรียกว่าอะไร และได้ผลิตภัณฑ์ใด$t$, $t$การหมัก ได้เอทานอล$t$, $t$การสะเทิน ได้เกลือและน้ำ$t$, $t$การเติม ได้แอลเคน$t$, $t$การเผาไหม้ ได้ CO₂ และน้ำ$t$, 1, $t$กรด + เบส → เกลือ + น้ำ$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$ปฏิกิริยาระหว่างกรดกับเบสเรียกว่าอะไร และได้ผลิตภัณฑ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$เมื่อกรดทำปฏิกิริยากับโลหะ เช่น สังกะสี จะเกิดแก๊สใด$t$, $t$Cl₂$t$, $t$O₂$t$, $t$H₂$t$, $t$CO₂$t$, 2, $t$กรด + โลหะ → เกลือ + H₂$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$เมื่อกรดทำปฏิกิริยากับโลหะ เช่น สังกะสี จะเกิดแก๊สใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$เมื่อกรดทำปฏิกิริยากับหินปูน (CaCO₃) จะเกิดแก๊สใด$t$, $t$H₂$t$, $t$NH₃$t$, $t$CO₂$t$, $t$O₂$t$, 2, $t$กรด + คาร์บอเนต → เกลือ + น้ำ + CO₂$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$เมื่อกรดทำปฏิกิริยากับหินปูน (CaCO₃) จะเกิดแก๊สใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$ไอออนที่เกิดขึ้นเมื่อกรดละลายน้ำและทำให้สารละลายเป็นกรดคือข้อใด$t$, $t$Cl⁻$t$, $t$Na⁺$t$, $t$H₃O⁺$t$, $t$OH⁻$t$, 2, $t$ไฮโดรเนียมไอออน$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$ไอออนที่เกิดขึ้นเมื่อกรดละลายน้ำและทำให้สารละลายเป็นกรดคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$ข้อใดเป็นกรดแก่$t$, $t$CH₃COOH$t$, $t$NH₃$t$, $t$HCl$t$, $t$H₂CO₃$t$, 2, $t$HCl แตกตัวสมบูรณ์ ส่วนกรดแอซีติกเป็นกรดอ่อน$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$ข้อใดเป็นกรดแก่$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$ข้อใดเป็นเบสอ่อน$t$, $t$NaOH$t$, $t$HCl$t$, $t$KOH$t$, $t$NH₃$t$, 3, $t$แอมโมเนียแตกตัวบางส่วนในน้ำ$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$ข้อใดเป็นเบสอ่อน$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$น้ำบริสุทธิ์ที่ 25 องศาเซลเซียส มีค่า pH เท่าใด$t$, $t$14$t$, $t$1$t$, $t$0$t$, $t$7$t$, 3, $t$เป็นกลาง$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$น้ำบริสุทธิ์ที่ 25 องศาเซลเซียส มีค่า pH เท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส$t$, $t$กรดชนิดใดพบในมดและต่อ$t$, $t$กรดซิตริก$t$, $t$กรดแลกติก$t$, $t$กรดฟอร์มิก$t$, $t$กรดแอซีติก$t$, 2, $t$HCOOH (กรดเมทาโนอิก)$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส$t$ and question = $t$กรดชนิดใดพบในมดและต่อ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$กระดาษลิตมัสสีน้ำเงินเมื่อสัมผัสสารละลายกรดจะเปลี่ยนเป็นสีใด$t$, $t$ม่วง$t$, $t$เขียว$t$, $t$ไม่เปลี่ยนสี$t$, $t$แดง$t$, 3, $t$กรดเปลี่ยนลิตมัสน้ำเงินเป็นแดง$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$กระดาษลิตมัสสีน้ำเงินเมื่อสัมผัสสารละลายกรดจะเปลี่ยนเป็นสีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$กระดาษลิตมัสสีแดงเมื่อสัมผัสสารละลายเบสจะเปลี่ยนเป็นสีใด$t$, $t$ไม่มีสี$t$, $t$น้ำเงิน$t$, $t$เขียว$t$, $t$เหลือง$t$, 1, $t$เบสเปลี่ยนลิตมัสแดงเป็นน้ำเงิน$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$กระดาษลิตมัสสีแดงเมื่อสัมผัสสารละลายเบสจะเปลี่ยนเป็นสีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$ฟีนอล์ฟทาลีนในสารละลายเบสให้สีใด$t$, $t$เหลือง$t$, $t$ชมพู$t$, $t$น้ำเงิน$t$, $t$ไม่มีสี$t$, 1, $t$ในกรดและสารละลายกลางไม่มีสี$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$ฟีนอล์ฟทาลีนในสารละลายเบสให้สีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$ฟีนอล์ฟทาลีนในสารละลายกรดให้สีใด$t$, $t$ชมพู$t$, $t$ไม่มีสี$t$, $t$แดง$t$, $t$เหลือง$t$, 1, $t$จึงใช้ดูจุดยุติการไทเทรตกรดกับเบสได้$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$ฟีนอล์ฟทาลีนในสารละลายกรดให้สีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$เมทิลออเรนจ์ในสารละลายกรดให้สีใด$t$, $t$แดง$t$, $t$เหลือง$t$, $t$ไม่มีสี$t$, $t$น้ำเงิน$t$, 0, $t$ในเบสให้สีเหลือง$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$เมทิลออเรนจ์ในสารละลายกรดให้สีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$โบรมไทมอลบลู (BTB) ในสารละลายกรดให้สีใด$t$, $t$ชมพู$t$, $t$เขียว$t$, $t$เหลือง$t$, $t$น้ำเงิน$t$, 2, $t$กรด = เหลือง · กลาง = เขียว · เบส = น้ำเงิน$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$โบรมไทมอลบลู (BTB) ในสารละลายกรดให้สีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$โบรมไทมอลบลู (BTB) ในสารละลายเป็นกลางให้สีใด$t$, $t$ไม่มีสี$t$, $t$เขียว$t$, $t$น้ำเงิน$t$, $t$เหลือง$t$, 1, $t$จึงใช้ทดสอบ CO₂ ในน้ำที่ทำให้เป็นกรดได้$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$โบรมไทมอลบลู (BTB) ในสารละลายเป็นกลางให้สีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$อินดิเคเตอร์สากล (universal indicator) ใช้ทำอะไร$t$, $t$บอกค่า pH โดยประมาณจากสีที่เปลี่ยนไป$t$, $t$วัดปริมาตรของแก๊ส$t$, $t$วัดมวลของสาร$t$, $t$วัดอุณหภูมิของสาร$t$, 0, $t$เป็นอินดิเคเตอร์ผสมที่เปลี่ยนสีได้หลายช่วง pH$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$อินดิเคเตอร์สากล (universal indicator) ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$สารสกัดจากกะหล่ำปลีสีม่วงใช้ทำอะไรได้$t$, $t$เป็นอินดิเคเตอร์ธรรมชาติบอกกรด-เบส$t$, $t$ใช้วัดความหนาแน่น$t$, $t$เป็นเชื้อเพลิง$t$, $t$เป็นสารละลายบัฟเฟอร์เท่านั้น$t$, 0, $t$สีเปลี่ยนตาม pH (แดง-ม่วง-เขียว-เหลือง)$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$สารสกัดจากกะหล่ำปลีสีม่วงใช้ทำอะไรได้$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$น้ำปูนใสจะขุ่นขาวเมื่อรับแก๊สใด$t$, $t$O₂$t$, $t$H₂$t$, $t$CO₂$t$, $t$N₂$t$, 2, $t$Ca(OH)₂ + CO₂ → CaCO₃ (ตะกอนขาว) + H₂O$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$น้ำปูนใสจะขุ่นขาวเมื่อรับแก๊สใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$ข้อใดเป็นอินดิเคเตอร์ตามธรรมชาติ$t$, $t$น้ำมันพืช$t$, $t$ดอกอัญชัน$t$, $t$เกลือแกง$t$, $t$น้ำตาลทราย$t$, 1, $t$สารแอนโทไซยานินเปลี่ยนสีตามค่า pH$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$ข้อใดเป็นอินดิเคเตอร์ตามธรรมชาติ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$ขมิ้นชันเมื่อหยดสารละลายเบสจะเปลี่ยนเป็นสีใด$t$, $t$แดงน้ำตาล$t$, $t$เขียวใส$t$, $t$ไม่มีสี$t$, $t$น้ำเงิน$t$, 0, $t$ใช้เป็นอินดิเคเตอร์ธรรมชาติ$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$ขมิ้นชันเมื่อหยดสารละลายเบสจะเปลี่ยนเป็นสีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$สารละลายที่ทำให้ลิตมัสแดงเป็นน้ำเงินมีสมบัติเป็นอะไร$t$, $t$เกลือกรด$t$, $t$กลาง$t$, $t$เบส$t$, $t$กรด$t$, 2, $t$เบสเปลี่ยนลิตมัสแดงเป็นน้ำเงิน$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$สารละลายที่ทำให้ลิตมัสแดงเป็นน้ำเงินมีสมบัติเป็นอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อินดิเคเตอร์$t$, $t$หลังจากหยดฟีนอล์ฟทาลีนลงในสารละลายแล้วได้สีชมพู แสดงว่าสารละลายเป็นอะไร$t$, $t$กลาง$t$, $t$น้ำตาล$t$, $t$กรด$t$, $t$เบส$t$, 3, $t$เกินช่วง pH ประมาณ 8.3$t$
where not exists (select 1 from quiz_questions where topic = $t$อินดิเคเตอร์$t$ and question = $t$หลังจากหยดฟีนอล์ฟทาลีนลงในสารละลายแล้วได้สีชมพู แสดงว่าสารละลายเป็นอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$อุปกรณ์ใดใช้หยดสารละลายและวัดปริมาตรที่ใช้ในการไทเทรตได้แม่นยำ$t$, $t$บิวเรต$t$, $t$กระบอกตวง$t$, $t$ขวดรูปกรวย$t$, $t$บีกเกอร์$t$, 0, $t$ปริมาตรอ่านจากขีดบอกบนหลอดแก้วยาว มีก๊อกควบคุมการไหล$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$อุปกรณ์ใดใช้หยดสารละลายและวัดปริมาตรที่ใช้ในการไทเทรตได้แม่นยำ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$อุปกรณ์ใดเหมาะที่สุดสำหรับเตรียมสารละลายที่มีปริมาตรแน่นอน$t$, $t$ขวดกำหนดปริมาตร$t$, $t$บีกเกอร์$t$, $t$ขวดรูปชมพู่$t$, $t$หลอดทดลอง$t$, 0, $t$มีขีดบอกปริมาตรเดียวและมีความแม่นยำสูง$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$อุปกรณ์ใดเหมาะที่สุดสำหรับเตรียมสารละลายที่มีปริมาตรแน่นอน$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$อุปกรณ์ใดใช้วัดปริมาตรของเหลวโดยประมาณ$t$, $t$กระบอกตวง$t$, $t$ขวดกำหนดปริมาตร$t$, $t$บิวเรต$t$, $t$ปิเปตวัดปริมาตร$t$, 0, $t$ความแม่นยำปานกลาง ใช้งานง่าย$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$อุปกรณ์ใดใช้วัดปริมาตรของเหลวโดยประมาณ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$อุปกรณ์ใดใช้ถ่ายโอนสารละลายปริมาตรแน่นอน$t$, $t$บีกเกอร์$t$, $t$ปิเปต$t$, $t$เบ้าหลอม$t$, $t$กรวยแก้ว$t$, 1, $t$ดูดสารละลายตามปริมาตรที่ต้องการ$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$อุปกรณ์ใดใช้ถ่ายโอนสารละลายปริมาตรแน่นอน$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$อุปกรณ์ใดใช้ระเหยสารละลายให้แห้งเพื่อให้ได้ของแข็ง$t$, $t$ปิเปต$t$, $t$บิวเรต$t$, $t$กระบอกตวง$t$, $t$ถ้วยระเหย$t$, 3, $t$ทนความร้อนได้ ใช้ในการระเหยตัวทำละลาย$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$อุปกรณ์ใดใช้ระเหยสารละลายให้แห้งเพื่อให้ได้ของแข็ง$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$อุปกรณ์ใดใช้ให้ความร้อนสารที่อุณหภูมิสูงมาก เช่น เผาสารจนไหม้หมด$t$, $t$หลอดทดลอง$t$, $t$ขวดรูปชมพู่$t$, $t$เบ้าหลอม$t$, $t$บีกเกอร์$t$, 2, $t$ทำจากเซรามิก ทนความร้อนสูง$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$อุปกรณ์ใดใช้ให้ความร้อนสารที่อุณหภูมิสูงมาก เช่น เผาสารจนไหม้หมด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$อุปกรณ์ใดใช้จับหรือคีบถ้วยระเหยร้อน$t$, $t$ช้อนตักสาร$t$, $t$คีมคีบ$t$, $t$หลอดหยด$t$, $t$แท่งแก้ว$t$, 1, $t$ป้องกันความร้อนลวกมือ$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$อุปกรณ์ใดใช้จับหรือคีบถ้วยระเหยร้อน$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$อุปกรณ์ใดใช้ให้ความร้อนที่ให้เปลวไฟสีฟ้า ปรับอากาศและแก๊สได้$t$, $t$เตาไมโครเวฟ$t$, $t$ตะเกียงบุนเซน$t$, $t$ฮอตเพลต$t$, $t$ตะเกียงแอลกอฮอล์$t$, 1, $t$ใช้แก๊สเชื้อเพลิง เปลวไฟร้อนสูง$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$อุปกรณ์ใดใช้ให้ความร้อนที่ให้เปลวไฟสีฟ้า ปรับอากาศและแก๊สได้$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$ตะแกรงลวดที่วางบนขาตั้งสามขามีหน้าที่ใด$t$, $t$ใช้ผสมสาร$t$, $t$กระจายความร้อนให้ทั่วภาชนะ$t$, $t$ใช้วัดอุณหภูมิ$t$, $t$ใช้กรองสาร$t$, 1, $t$ป้องกันภาชนะแก้วร้อนไม่สม่ำเสมอ$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$ตะแกรงลวดที่วางบนขาตั้งสามขามีหน้าที่ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$อุปกรณ์ใดใช้แยกของแข็งที่ไม่ละลายออกจากของเหลว ควบคู่กับกระดาษกรอง$t$, $t$กรวยกรอง$t$, $t$ถ้วยระเหย$t$, $t$กรวยแยก$t$, $t$บิวเรต$t$, 0, $t$กระดาษกรองพับวางในกรวยแก้ว$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$อุปกรณ์ใดใช้แยกของแข็งที่ไม่ละลายออกจากของเหลว ควบคู่กับกระดาษกรอง$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$อุปกรณ์ใดใช้แยกของเหลวสองชนิดที่ไม่ละลายกัน เช่น น้ำมันกับน้ำ$t$, $t$กระบอกตวง$t$, $t$กรวยกรอง$t$, $t$กรวยแยก$t$, $t$ปิเปต$t$, 2, $t$ของเหลวชั้นล่างปล่อยออกทางก๊อก$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$อุปกรณ์ใดใช้แยกของเหลวสองชนิดที่ไม่ละลายกัน เช่น น้ำมันกับน้ำ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$อุปกรณ์ใดใช้ชั่งมวลสาร$t$, $t$เครื่องชั่ง$t$, $t$ปิเปต$t$, $t$เทอร์มอมิเตอร์$t$, $t$บิวเรต$t$, 0, $t$หน่วยมวลเป็นกรัม$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$อุปกรณ์ใดใช้ชั่งมวลสาร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$อุปกรณ์ใดใช้วัดอุณหภูมิ$t$, $t$บีกเกอร์$t$, $t$เทอร์มอมิเตอร์$t$, $t$กระบอกตวง$t$, $t$เครื่องชั่ง$t$, 1, $t$หน่วยเป็นองศาเซลเซียสหรือเคลวิน$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$อุปกรณ์ใดใช้วัดอุณหภูมิ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$กระจกนาฬิกา (watch glass) มักใช้ทำอะไร$t$, $t$ใช้กรองสาร$t$, $t$ใส่สารปริมาณน้อยเพื่อชั่งหรือสังเกต$t$, $t$ใช้วัดปริมาตร$t$, $t$ใช้ต้มสารละลาย$t$, 1, $t$เป็นแผ่นแก้วโค้งเล็กน้อย$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$กระจกนาฬิกา (watch glass) มักใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$หลอดหยดใช้ทำอะไร$t$, $t$วัดอุณหภูมิ$t$, $t$ถ่ายโอนของเหลวปริมาณน้อยเป็นหยดๆ$t$, $t$ให้ความร้อน$t$, $t$ชั่งมวล$t$, 1, $t$ควบคุมปริมาณสารได้ละเอียด$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$หลอดหยดใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$ขวดรูปชมพู่ (Erlenmeyer flask) นิยมใช้ทำอะไร$t$, $t$ผสมสารและไทเทรต เพราะเขย่าได้โดยไม่กระเด็น$t$, $t$กรองสาร$t$, $t$วัดปริมาตรแม่นยำ$t$, $t$ชั่งสาร$t$, 0, $t$ปากแคบกว่าก้น ลดการหกกระเด็น$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$ขวดรูปชมพู่ (Erlenmeyer flask) นิยมใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$แท่งแก้วคน (glass rod) ใช้ทำอะไร$t$, $t$ให้ความร้อน$t$, $t$กวนสารให้เข้ากันหรือช่วยนำทางเมื่อเท$t$, $t$วัดปริมาตร$t$, $t$ชั่งมวล$t$, 1, $t$ใช้ร่วมกับบีกเกอร์$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$แท่งแก้วคน (glass rod) ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อุปกรณ์วิทยาศาสตร์$t$, $t$ตัวอ่านปริมาตรของเหลวในหลอดแก้วควรอ่านที่ระดับใด$t$, $t$เหนือผิวของเหลว$t$, $t$ระดับสายตาตรงกับผิวโค้งต่ำสุด (เมนิสคัส)$t$, $t$ระดับก้นภาชนะ$t$, $t$จากด้านบนมองลงมา$t$, 1, $t$ลดความผิดพลาดจากพารัลแลกซ์$t$
where not exists (select 1 from quiz_questions where topic = $t$อุปกรณ์วิทยาศาสตร์$t$ and question = $t$ตัวอ่านปริมาตรของเหลวในหลอดแก้วควรอ่านที่ระดับใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยในห้องปฏิบัติการ$t$, $t$สัญลักษณ์รูปหัวกะโหลกไขว้ในฉลากสารเคมีบอกอันตรายใด$t$, $t$ระเบิดได้$t$, $t$ไวไฟ$t$, $t$เป็นพิษ$t$, $t$กัดกร่อน$t$, 2, $t$พิษร้ายแรงถึงตายหากสูดดมหรือกลืน$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยในห้องปฏิบัติการ$t$ and question = $t$สัญลักษณ์รูปหัวกะโหลกไขว้ในฉลากสารเคมีบอกอันตรายใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยในห้องปฏิบัติการ$t$, $t$สัญลักษณ์รูปเปลวไฟบนฉลากสารเคมีหมายถึงอะไร$t$, $t$ระเบิดได้$t$, $t$เป็นพิษ$t$, $t$กัดกร่อน$t$, $t$สารไวไฟ$t$, 3, $t$ห้ามอยู่ใกล้เปลวไฟหรือประกายไฟ$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยในห้องปฏิบัติการ$t$ and question = $t$สัญลักษณ์รูปเปลวไฟบนฉลากสารเคมีหมายถึงอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยในห้องปฏิบัติการ$t$, $t$สัญลักษณ์รูปมือถูกกัดและโลหะถูกกัดกร่อน หมายถึงอะไร$t$, $t$เป็นพิษ$t$, $t$ออกซิไดส์$t$, $t$กัดกร่อน$t$, $t$ไวไฟ$t$, 2, $t$ระวังกรดแก่และเบสแก่$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยในห้องปฏิบัติการ$t$ and question = $t$สัญลักษณ์รูปมือถูกกัดและโลหะถูกกัดกร่อน หมายถึงอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยในห้องปฏิบัติการ$t$, $t$ควรทำอย่างไรเมื่อต้องเจือจางกรดซัลฟิวริกเข้มข้นด้วยน้ำ$t$, $t$ค่อยๆ เทกรดลงในน้ำ พร้อมกวนเบาๆ$t$, $t$ใช้ความร้อนช่วย$t$, $t$เทน้ำลงในกรดอย่างรวดเร็ว$t$, $t$เทพร้อมกันทั้งสองอย่าง$t$, 0, $t$ปฏิกิริยาคายความร้อนสูง การเติมน้ำลงกรดอาจกระเด็นรุนแรง$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยในห้องปฏิบัติการ$t$ and question = $t$ควรทำอย่างไรเมื่อต้องเจือจางกรดซัลฟิวริกเข้มข้นด้วยน้ำ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยในห้องปฏิบัติการ$t$, $t$เมื่อกรดหกรดผิวหนัง ควรทำสิ่งใดก่อน$t$, $t$เช็ดด้วยกระดาษแห้ง$t$, $t$ทาด้วยเบสแก่$t$, $t$ล้างด้วยน้ำสะอาดปริมาณมากอย่างน้อย 15 นาที$t$, $t$ปล่อยให้แห้งเอง$t$, 2, $t$ล้างให้เจือจางก่อน แล้วแจ้งครูทันที$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยในห้องปฏิบัติการ$t$ and question = $t$เมื่อกรดหกรดผิวหนัง ควรทำสิ่งใดก่อน$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยในห้องปฏิบัติการ$t$, $t$วิธีดมกลิ่นสารเคมีที่ปลอดภัยคือข้อใด$t$, $t$ดมใกล้ๆ ทีละหลายครั้ง$t$, $t$ใช้ปากชิมรส$t$, $t$ใช้มือโบกไอสารเข้าหาจมูกเบาๆ$t$, $t$เอาจมูกจ่อปากภาชนะแล้วสูดแรงๆ$t$, 2, $t$หลีกเลี่ยงการสูดไอสารโดยตรง$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยในห้องปฏิบัติการ$t$ and question = $t$วิธีดมกลิ่นสารเคมีที่ปลอดภัยคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยในห้องปฏิบัติการ$t$, $t$อุปกรณ์ป้องกันดวงตาที่ต้องใส่ขณะทำการทดลองเคมีคือข้อใด$t$, $t$แว่นตานิรภัย$t$, $t$ผ้าปิดจมูกอย่างเดียว$t$, $t$หมวกกันน็อก$t$, $t$แว่นกันแดด$t$, 0, $t$ป้องกันสารเคมีกระเด็นเข้าตา$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยในห้องปฏิบัติการ$t$ and question = $t$อุปกรณ์ป้องกันดวงตาที่ต้องใส่ขณะทำการทดลองเคมีคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยในห้องปฏิบัติการ$t$, $t$ข้อใดเป็นการปฏิบัติที่ถูกต้องในห้องปฏิบัติการ$t$, $t$วิ่งเล่นในห้องแล็บ$t$, $t$กินอาหารระหว่างทดลอง$t$, $t$ชิมสารเพื่อทดสอบ$t$, $t$รวบผมให้เรียบร้อยและสวมเสื้อกาวน์$t$, 3, $t$เพื่อความปลอดภัยของตนเองและผู้อื่น$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยในห้องปฏิบัติการ$t$ and question = $t$ข้อใดเป็นการปฏิบัติที่ถูกต้องในห้องปฏิบัติการ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยในห้องปฏิบัติการ$t$, $t$เมื่อให้ความร้อนหลอดทดลองที่ใส่ของเหลว ควรหันปากหลอดไปทางใด$t$, $t$ไม่หันเข้าหาตนเองหรือผู้อื่น$t$, $t$ลงพื้นโดยตรง$t$, $t$เข้าหาตนเอง$t$, $t$เข้าหาเพื่อน$t$, 0, $t$ป้องกันของเหลวพุ่งออกมาลวก$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยในห้องปฏิบัติการ$t$ and question = $t$เมื่อให้ความร้อนหลอดทดลองที่ใส่ของเหลว ควรหันปากหลอดไปทางใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยในห้องปฏิบัติการ$t$, $t$ควรทำอย่างไรกับสารเคมีที่เหลือจากการทดลอง$t$, $t$เทกลับขวดเดิมทันที$t$, $t$นำกลับบ้าน$t$, $t$ทิ้งลงอ่างล้างมือทุกชนิด$t$, $t$ทิ้งในภาชนะรองรับของเสียตามที่ครูกำหนด$t$, 3, $t$ป้องกันการปนเปื้อนและมลพิษ$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยในห้องปฏิบัติการ$t$ and question = $t$ควรทำอย่างไรกับสารเคมีที่เหลือจากการทดลอง$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยในห้องปฏิบัติการ$t$, $t$สัญลักษณ์เครื่องหมายตกใจ (!) บนฉลากสารเคมีบ่งบอกถึงอะไร$t$, $t$ระคายเคือง/อันตรายต่อสุขภาพในระดับหนึ่ง$t$, $t$ปลอดภัยสมบูรณ์$t$, $t$เป็นพิษถึงตายเสมอ$t$, $t$สารกัมมันตรังสี$t$, 0, $t$ควรหลีกเลี่ยงการสัมผัสและสูดดม$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยในห้องปฏิบัติการ$t$ and question = $t$สัญลักษณ์เครื่องหมายตกใจ (!) บนฉลากสารเคมีบ่งบอกถึงอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยในห้องปฏิบัติการ$t$, $t$ก่อนใช้สารเคมีควรปฏิบัติสิ่งใดเป็นลำดับแรก$t$, $t$ผสมกับสารอื่นเพื่อดูผล$t$, $t$ชิมรสเพื่อเช็กชนิด$t$, $t$อ่านฉลากและคำเตือนบนภาชนะ$t$, $t$เทใส่มือก่อนใช้งาน$t$, 2, $t$ฉลากบอกชื่อสาร อันตราย และการเก็บรักษา$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยในห้องปฏิบัติการ$t$ and question = $t$ก่อนใช้สารเคมีควรปฏิบัติสิ่งใดเป็นลำดับแรก$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและการวัด$t$, $t$คำนำหน้าหน่วย กิโล (k) มีค่าเท่าใด$t$, $t$10⁶$t$, $t$10²$t$, $t$10³$t$, $t$10⁻³$t$, 2, $t$1 กิโลเมตร = 1000 เมตร$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและการวัด$t$ and question = $t$คำนำหน้าหน่วย กิโล (k) มีค่าเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและการวัด$t$, $t$คำนำหน้าหน่วย มิลลิ (m) มีค่าเท่าใด$t$, $t$10³$t$, $t$10⁻²$t$, $t$10⁻³$t$, $t$10⁻⁶$t$, 2, $t$1 มิลลิลิตร = 0.001 ลิตร$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและการวัด$t$ and question = $t$คำนำหน้าหน่วย มิลลิ (m) มีค่าเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและการวัด$t$, $t$คำนำหน้าหน่วย เซนติ (c) มีค่าเท่าใด$t$, $t$10⁻¹$t$, $t$10⁻²$t$, $t$10²$t$, $t$10⁻³$t$, 1, $t$1 เซนติเมตร = 0.01 เมตร$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและการวัด$t$ and question = $t$คำนำหน้าหน่วย เซนติ (c) มีค่าเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและการวัด$t$, $t$คำนำหน้าหน่วย ไมโคร (μ) มีค่าเท่าใด$t$, $t$10⁻⁹$t$, $t$10⁶$t$, $t$10⁻⁶$t$, $t$10⁻³$t$, 2, $t$1 ไมโครเมตร = 10⁻⁶ เมตร$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและการวัด$t$ and question = $t$คำนำหน้าหน่วย ไมโคร (μ) มีค่าเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและการวัด$t$, $t$คำนำหน้าหน่วย นาโน (n) มีค่าเท่าใด$t$, $t$10⁹$t$, $t$10⁻⁹$t$, $t$10⁻¹²$t$, $t$10⁻⁶$t$, 1, $t$1 นาโนเมตร = 10⁻⁹ เมตร$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและการวัด$t$ and question = $t$คำนำหน้าหน่วย นาโน (n) มีค่าเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและการวัด$t$, $t$คำนำหน้าหน่วย เมกะ (M) มีค่าเท่าใด$t$, $t$10⁻⁶$t$, $t$10³$t$, $t$10⁹$t$, $t$10⁶$t$, 3, $t$1 เมกะไบต์ ≈ 10⁶ ไบต์$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและการวัด$t$ and question = $t$คำนำหน้าหน่วย เมกะ (M) มีค่าเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและการวัด$t$, $t$1 ลิตร เท่ากับกี่มิลลิลิตร$t$, $t$100 มิลลิลิตร$t$, $t$10000 มิลลิลิตร$t$, $t$1000 มิลลิลิตร$t$, $t$10 มิลลิลิตร$t$, 2, $t$1 L = 1000 mL$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและการวัด$t$ and question = $t$1 ลิตร เท่ากับกี่มิลลิลิตร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและการวัด$t$, $t$1 มิลลิลิตร มีปริมาตรเท่ากับข้อใด$t$, $t$10 ลูกบาศก์เซนติเมตร$t$, $t$1 ลูกบาศก์เซนติเมตร$t$, $t$0.1 ลูกบาศก์เซนติเมตร$t$, $t$1 ลูกบาศก์เมตร$t$, 1, $t$1 mL = 1 cm³$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและการวัด$t$ and question = $t$1 มิลลิลิตร มีปริมาตรเท่ากับข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและการวัด$t$, $t$1 กิโลกรัม เท่ากับกี่กรัม$t$, $t$10 กรัม$t$, $t$1000 กรัม$t$, $t$10000 กรัม$t$, $t$100 กรัม$t$, 1, $t$1 kg = 1000 g$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและการวัด$t$ and question = $t$1 กิโลกรัม เท่ากับกี่กรัม$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและการวัด$t$, $t$หน่วย SI ของปริมาณสารคือข้อใด$t$, $t$โมล (mol)$t$, $t$กิโลกรัม$t$, $t$กรัม$t$, $t$ลิตร$t$, 0, $t$ใช้บอกจำนวนอนุภาคของสาร$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและการวัด$t$ and question = $t$หน่วย SI ของปริมาณสารคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและการวัด$t$, $t$หน่วย SI ของอุณหภูมิคือข้อใด$t$, $t$องศาเซลเซียส$t$, $t$เคลวิน (K)$t$, $t$องศาฟาเรนไฮต์$t$, $t$แคลอรี$t$, 1, $t$K = °C + 273$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและการวัด$t$ and question = $t$หน่วย SI ของอุณหภูมิคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและการวัด$t$, $t$0 องศาเซลเซียส เท่ากับกี่เคลวิน (ประมาณ)$t$, $t$0 K$t$, $t$100 K$t$, $t$373 K$t$, $t$273 K$t$, 3, $t$K = °C + 273$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและการวัด$t$ and question = $t$0 องศาเซลเซียส เท่ากับกี่เคลวิน (ประมาณ)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$ใครเสนอทฤษฎีอะตอมว่าอะตอมเป็นทรงกลมตัน แบ่งแยกไม่ได้$t$, $t$จอห์น ดาลตัน$t$, $t$เจ.เจ. ทอมสัน$t$, $t$นีลส์ โบร์$t$, $t$เออร์เนสต์ รัทเทอร์ฟอร์ด$t$, 0, $t$แบบจำลองอะตอมของดาลตัน (ค.ศ. 1803)$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$ใครเสนอทฤษฎีอะตอมว่าอะตอมเป็นทรงกลมตัน แบ่งแยกไม่ได้$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$ใครค้นพบอิเล็กตรอน$t$, $t$เจ.เจ. ทอมสัน$t$, $t$จอห์น ดาลตัน$t$, $t$โรเบิร์ต มิลลิแกน$t$, $t$เจมส์ แชดวิก$t$, 0, $t$จากการทดลองรังสีแคโทด$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$ใครค้นพบอิเล็กตรอน$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$แบบจำลองอะตอมแบบพุดดิ้งลูกเกด (plum pudding) เสนอโดยใคร$t$, $t$จอห์น ดาลตัน$t$, $t$เจ.เจ. ทอมสัน$t$, $t$เออร์วิน ชเรอดิงเงอร์$t$, $t$นีลส์ โบร์$t$, 1, $t$อะตอมเป็นทรงกลมมีประจุบวก มีอิเล็กตรอนฝังอยู่$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$แบบจำลองอะตอมแบบพุดดิ้งลูกเกด (plum pudding) เสนอโดยใคร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$ใครค้นพบนิวเคลียสของอะตอมจากการทดลองยิงอนุภาคแอลฟาใส่แผ่นทองคำ$t$, $t$เจ.เจ. ทอมสัน$t$, $t$เออร์เนสต์ รัทเทอร์ฟอร์ด$t$, $t$เจมส์ แชดวิก$t$, $t$นีลส์ โบร์$t$, 1, $t$อะตอมส่วนใหญ่เป็นที่ว่าง มีนิวเคลียสเล็กหนาแน่นประจุบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$ใครค้นพบนิวเคลียสของอะตอมจากการทดลองยิงอนุภาคแอลฟาใส่แผ่นทองคำ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$ใครเสนอแบบจำลองอะตอมที่อิเล็กตรอนโคจรในระดับพลังงานเฉพาะ$t$, $t$เจ.เจ. ทอมสัน$t$, $t$เออร์เนสต์ รัทเทอร์ฟอร์ด$t$, $t$นีลส์ โบร์$t$, $t$จอห์น ดาลตัน$t$, 2, $t$แบบจำลองอะตอมของโบร์$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$ใครเสนอแบบจำลองอะตอมที่อิเล็กตรอนโคจรในระดับพลังงานเฉพาะ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$ใครค้นพบนิวตรอน$t$, $t$นีลส์ โบร์$t$, $t$เจมส์ แชดวิก$t$, $t$เออร์เนสต์ รัทเทอร์ฟอร์ด$t$, $t$เจ.เจ. ทอมสัน$t$, 1, $t$ค.ศ. 1932$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$ใครค้นพบนิวตรอน$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$ใครเป็นผู้เรียงธาตุตามมวลอะตอมและจัดทำตารางธาตุฉบับแรกที่ทำนายธาตุที่ยังไม่พบได้$t$, $t$เฮนรี มอสลีย์$t$, $t$ดิมิทรี เมนเดเลเยฟ$t$, $t$จอห์น ดาลตัน$t$, $t$อันตวน ลาวัวซีเย$t$, 1, $t$ตารางธาตุของเมนเดเลเยฟ$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$ใครเป็นผู้เรียงธาตุตามมวลอะตอมและจัดทำตารางธาตุฉบับแรกที่ทำนายธาตุที่ยังไม่พบได้$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$ใครเสนอให้เรียงธาตุตามเลขอะตอม$t$, $t$นีลส์ โบร์$t$, $t$เฮนรี มอสลีย์$t$, $t$ดิมิทรี เมนเดเลเยฟ$t$, $t$จอห์น ดาลตัน$t$, 1, $t$ตารางธาตุปัจจุบันเรียงตามเลขอะตอม$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$ใครเสนอให้เรียงธาตุตามเลขอะตอม$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$ใครเสนอกฎทรงมวล (มวลรวมก่อนและหลังปฏิกิริยาเท่ากัน)$t$, $t$อันตวน ลาวัวซีเย$t$, $t$โรเบิร์ต บอยล์$t$, $t$อาโวกาโดร$t$, $t$จอห์น ดาลตัน$t$, 0, $t$มวลสารไม่สูญหายและไม่เกิดขึ้นใหม่$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$ใครเสนอกฎทรงมวล (มวลรวมก่อนและหลังปฏิกิริยาเท่ากัน)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$ใครเสนอกฎสัดส่วนคงที่ของสารประกอบ$t$, $t$อาโวกาโดร$t$, $t$โรเบิร์ต บอยล์$t$, $t$โจเซฟ พราวส์ท$t$, $t$ชาร์ลส์$t$, 2, $t$สารประกอบหนึ่งมีอัตราส่วนโดยมวลคงที่เสมอ$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$ใครเสนอกฎสัดส่วนคงที่ของสารประกอบ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$กฎของบอยล์ (Boyle) อธิบายความสัมพันธ์ระหว่างปริมาณใด$t$, $t$ปริมาตรกับอุณหภูมิ$t$, $t$ความดันกับอุณหภูมิ$t$, $t$มวลกับปริมาตร$t$, $t$ความดันกับปริมาตรของแก๊ส เมื่ออุณหภูมิคงที่$t$, 3, $t$P ∝ 1/V$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$กฎของบอยล์ (Boyle) อธิบายความสัมพันธ์ระหว่างปริมาณใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$กฎของชาร์ลส์ (Charles) อธิบายความสัมพันธ์ระหว่างปริมาณใด$t$, $t$มวลกับพลังงาน$t$, $t$ความดันกับจำนวนโมล$t$, $t$ความดันกับปริมาตร$t$, $t$ปริมาตรกับอุณหภูมิ (เคลวิน) เมื่อความดันคงที่$t$, 3, $t$V ∝ T$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$กฎของชาร์ลส์ (Charles) อธิบายความสัมพันธ์ระหว่างปริมาณใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$ใครเสนอว่าแก๊สที่ปริมาตรเท่ากัน ที่ T และ P เดียวกัน มีจำนวนโมเลกุลเท่ากัน$t$, $t$บอยล์$t$, $t$ชาร์ลส์$t$, $t$ดาลตัน$t$, $t$อาโวกาโดร$t$, 3, $t$กฎของอาโวกาโดร$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$ใครเสนอว่าแก๊สที่ปริมาตรเท่ากัน ที่ T และ P เดียวกัน มีจำนวนโมเลกุลเท่ากัน$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$, $t$แบบจำลองอะตอมแบบกลุ่มหมอก (กลุ่มหมอกอิเล็กตรอน) พัฒนาจากแนวคิดของใคร$t$, $t$เจ.เจ. ทอมสัน$t$, $t$เออร์วิน ชเรอดิงเงอร์$t$, $t$จอห์น ดาลตัน$t$, $t$เออร์เนสต์ รัทเทอร์ฟอร์ด$t$, 1, $t$แบบจำลองกลศาสตร์ควอนตัม$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์และแบบจำลองอะตอม$t$ and question = $t$แบบจำลองอะตอมแบบกลุ่มหมอก (กลุ่มหมอกอิเล็กตรอน) พัฒนาจากแนวคิดของใคร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สถานะและการเปลี่ยนสถานะ$t$, $t$การเปลี่ยนสถานะจากของเหลวเป็นแก๊สเรียกว่าอะไร$t$, $t$การระเหิด$t$, $t$การแข็งตัว$t$, $t$การกลายเป็นไอ (ระเหย/เดือด)$t$, $t$การหลอมเหลว$t$, 2, $t$น้ำเป็นไอน้ำ$t$
where not exists (select 1 from quiz_questions where topic = $t$สถานะและการเปลี่ยนสถานะ$t$ and question = $t$การเปลี่ยนสถานะจากของเหลวเป็นแก๊สเรียกว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สถานะและการเปลี่ยนสถานะ$t$, $t$การเปลี่ยนสถานะจากของเหลวเป็นของแข็งเรียกว่าอะไร$t$, $t$การระเหย$t$, $t$การควบแน่น$t$, $t$การแข็งตัว$t$, $t$การหลอมเหลว$t$, 2, $t$น้ำเป็นน้ำแข็ง$t$
where not exists (select 1 from quiz_questions where topic = $t$สถานะและการเปลี่ยนสถานะ$t$ and question = $t$การเปลี่ยนสถานะจากของเหลวเป็นของแข็งเรียกว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สถานะและการเปลี่ยนสถานะ$t$, $t$น้ำบริสุทธิ์เดือดที่อุณหภูมิกี่องศาเซลเซียส (ที่ความดัน 1 บรรยากาศ)$t$, $t$0$t$, $t$50$t$, $t$373$t$, $t$100$t$, 3, $t$จุดเดือดของน้ำ = 100 °C$t$
where not exists (select 1 from quiz_questions where topic = $t$สถานะและการเปลี่ยนสถานะ$t$ and question = $t$น้ำบริสุทธิ์เดือดที่อุณหภูมิกี่องศาเซลเซียส (ที่ความดัน 1 บรรยากาศ)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สถานะและการเปลี่ยนสถานะ$t$, $t$น้ำบริสุทธิ์แข็งตัวที่อุณหภูมิกี่องศาเซลเซียส (ที่ความดัน 1 บรรยากาศ)$t$, $t$10$t$, $t$−10$t$, $t$0$t$, $t$100$t$, 2, $t$จุดเยือกแข็ง/จุดหลอมเหลวของน้ำ = 0 °C$t$
where not exists (select 1 from quiz_questions where topic = $t$สถานะและการเปลี่ยนสถานะ$t$ and question = $t$น้ำบริสุทธิ์แข็งตัวที่อุณหภูมิกี่องศาเซลเซียส (ที่ความดัน 1 บรรยากาศ)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สถานะและการเปลี่ยนสถานะ$t$, $t$ขณะสารบริสุทธิ์กำลังเปลี่ยนสถานะ อุณหภูมิจะเป็นอย่างไร$t$, $t$เพิ่มขึ้นเรื่อยๆ$t$, $t$ผันผวนไม่แน่นอน$t$, $t$คงที่$t$, $t$ลดลงเรื่อยๆ$t$, 2, $t$พลังงานที่ให้ใช้ในการเปลี่ยนสถานะ$t$
where not exists (select 1 from quiz_questions where topic = $t$สถานะและการเปลี่ยนสถานะ$t$ and question = $t$ขณะสารบริสุทธิ์กำลังเปลี่ยนสถานะ อุณหภูมิจะเป็นอย่างไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สถานะและการเปลี่ยนสถานะ$t$, $t$สถานะใดของสารที่ไม่มีรูปร่างและปริมาตรคงที่ ขยายเต็มภาชนะ$t$, $t$ของแข็ง$t$, $t$ของเหลว$t$, $t$แก๊ส$t$, $t$ผลึก$t$, 2, $t$อนุภาคอยู่ห่างกันมากและเคลื่อนที่อิสระ$t$
where not exists (select 1 from quiz_questions where topic = $t$สถานะและการเปลี่ยนสถานะ$t$ and question = $t$สถานะใดของสารที่ไม่มีรูปร่างและปริมาตรคงที่ ขยายเต็มภาชนะ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การแยกสาร$t$, $t$เกลือละลายอยู่ในน้ำ ต้องการแยกเกลือออกมาควรใช้วิธีใด$t$, $t$การใช้แม่เหล็ก$t$, $t$การร่อน$t$, $t$การกรอง$t$, $t$การระเหยแห้ง (ต้มระเหยน้ำ)$t$, 3, $t$เกลือไม่ระเหย น้ำระเหยออกไป$t$
where not exists (select 1 from quiz_questions where topic = $t$การแยกสาร$t$ and question = $t$เกลือละลายอยู่ในน้ำ ต้องการแยกเกลือออกมาควรใช้วิธีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การแยกสาร$t$, $t$ทรายปนเหล็กผง ควรแยกด้วยวิธีใด$t$, $t$ใช้แม่เหล็กดูดเหล็ก$t$, $t$การตกผลึก$t$, $t$การกลั่น$t$, $t$การระเหยแห้ง$t$, 0, $t$เหล็กถูกแม่เหล็กดูด ทรายไม่ถูก$t$
where not exists (select 1 from quiz_questions where topic = $t$การแยกสาร$t$ and question = $t$ทรายปนเหล็กผง ควรแยกด้วยวิธีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การแยกสาร$t$, $t$น้ำขุ่นที่มีดินปน ควรแยกด้วยวิธีใด$t$, $t$การกรอง$t$, $t$การกลั่น$t$, $t$การตกผลึก$t$, $t$การระเหิด$t$, 0, $t$ของแข็งไม่ละลายถูกกรองไว้บนกระดาษกรอง$t$
where not exists (select 1 from quiz_questions where topic = $t$การแยกสาร$t$ and question = $t$น้ำขุ่นที่มีดินปน ควรแยกด้วยวิธีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การแยกสาร$t$, $t$การแยกน้ำบริสุทธิ์ออกจากน้ำทะเลที่มีเกลือละลายอยู่ ใช้วิธีใด$t$, $t$การกลั่น$t$, $t$การร่อน$t$, $t$การกรอง$t$, $t$การหยิบออก$t$, 0, $t$น้ำเดือดเป็นไอแล้วควบแน่นกลับเป็นน้ำบริสุทธิ์$t$
where not exists (select 1 from quiz_questions where topic = $t$การแยกสาร$t$ and question = $t$การแยกน้ำบริสุทธิ์ออกจากน้ำทะเลที่มีเกลือละลายอยู่ ใช้วิธีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การแยกสาร$t$, $t$การแยกน้ำมันพืชออกจากน้ำใช้วิธีใดได้ดี$t$, $t$ใช้กรวยแยก$t$, $t$การระเหยแห้ง$t$, $t$การตกผลึก$t$, $t$การใช้แม่เหล็ก$t$, 0, $t$ของเหลวสองชั้นไม่ละลายกัน$t$
where not exists (select 1 from quiz_questions where topic = $t$การแยกสาร$t$ and question = $t$การแยกน้ำมันพืชออกจากน้ำใช้วิธีใดได้ดี$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การแยกสาร$t$, $t$การแยกสีผสมในหมึกปากกาออกเป็นสีต่างๆ ใช้วิธีใด$t$, $t$โครมาโทกราฟี$t$, $t$การกรอง$t$, $t$การระเหิด$t$, $t$การกลั่น$t$, 0, $t$สารต่างๆ เคลื่อนที่บนตัวดูดซับได้ไม่เท่ากัน$t$
where not exists (select 1 from quiz_questions where topic = $t$การแยกสาร$t$ and question = $t$การแยกสีผสมในหมึกปากกาออกเป็นสีต่างๆ ใช้วิธีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การแยกสาร$t$, $t$การแยกน้ำมันดิบเป็นส่วนต่างๆ ใช้วิธีใด$t$, $t$การกรอง$t$, $t$การกลั่นลำดับส่วน$t$, $t$การร่อน$t$, $t$การตกผลึก$t$, 1, $t$แยกตามจุดเดือดที่ต่างกัน$t$
where not exists (select 1 from quiz_questions where topic = $t$การแยกสาร$t$ and question = $t$การแยกน้ำมันดิบเป็นส่วนต่างๆ ใช้วิธีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การแยกสาร$t$, $t$การทำให้สารละลายอิ่มตัวเย็นลงแล้วได้ผลึกของสารบริสุทธิ์ขึ้นมาเรียกว่าอะไร$t$, $t$การกลั่น$t$, $t$การระเหิด$t$, $t$การตกผลึก$t$, $t$การกรอง$t$, 2, $t$เช่น การทำผลึกสารส้ม$t$
where not exists (select 1 from quiz_questions where topic = $t$การแยกสาร$t$ and question = $t$การทำให้สารละลายอิ่มตัวเย็นลงแล้วได้ผลึกของสารบริสุทธิ์ขึ้นมาเรียกว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การแยกสาร$t$, $t$การแยกสารที่ระเหิดได้ เช่น ไอโอดีน ออกจากสารที่ไม่ระเหิด ใช้วิธีใด$t$, $t$การกรอง$t$, $t$การระเหิด$t$, $t$การร่อน$t$, $t$การกลั่น$t$, 1, $t$ไอโอดีนระเหิดเป็นไอสีม่วงแล้วกลับเป็นของแข็ง$t$
where not exists (select 1 from quiz_questions where topic = $t$การแยกสาร$t$ and question = $t$การแยกสารที่ระเหิดได้ เช่น ไอโอดีน ออกจากสารที่ไม่ระเหิด ใช้วิธีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การแยกสาร$t$, $t$ข้าวสารปนก้อนกรวด ควรแยกด้วยวิธีใด$t$, $t$การกลั่น$t$, $t$การหยิบออกหรือการร่อน$t$, $t$การระเหยแห้ง$t$, $t$การตกผลึก$t$, 1, $t$อนุภาคขนาดต่างกันแยกด้วยการร่อนได้$t$
where not exists (select 1 from quiz_questions where topic = $t$การแยกสาร$t$ and question = $t$ข้าวสารปนก้อนกรวด ควรแยกด้วยวิธีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$เบกกิ้งโซดามีสูตรเคมีตามข้อใด$t$, $t$NaOH$t$, $t$Na₂CO₃$t$, $t$NaHCO₃$t$, $t$NaCl$t$, 2, $t$โซเดียมไฮโดรเจนคาร์บอเนต$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$เบกกิ้งโซดามีสูตรเคมีตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$โซดาซักผ้ามีสูตรเคมีตามข้อใด$t$, $t$Na₂CO₃$t$, $t$NaOH$t$, $t$NaCl$t$, $t$NaHCO₃$t$, 0, $t$โซเดียมคาร์บอเนต$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$โซดาซักผ้ามีสูตรเคมีตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$เกลือแกงมีสูตรเคมีตามข้อใด$t$, $t$KCl$t$, $t$NaCl$t$, $t$Na₂SO₄$t$, $t$NaHCO₃$t$, 1, $t$โซเดียมคลอไรด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$เกลือแกงมีสูตรเคมีตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$โซดาไฟมีสูตรเคมีตามข้อใด$t$, $t$Ca(OH)₂$t$, $t$Na₂CO₃$t$, $t$NaOH$t$, $t$KOH$t$, 2, $t$โซเดียมไฮดรอกไซด์ เบสแก่$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$โซดาไฟมีสูตรเคมีตามข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$หินปูนและหินอ่อนมีองค์ประกอบหลักคือสารใด$t$, $t$Ca(OH)₂$t$, $t$CaCO₃$t$, $t$CaSO₄$t$, $t$CaO$t$, 1, $t$แคลเซียมคาร์บอเนต$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$หินปูนและหินอ่อนมีองค์ประกอบหลักคือสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$น้ำปูนใสคือสารละลายของสารใด$t$, $t$CaO$t$, $t$NaOH$t$, $t$Ca(OH)₂$t$, $t$CaCO₃$t$, 2, $t$แคลเซียมไฮดรอกไซด์ในน้ำ$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$น้ำปูนใสคือสารละลายของสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$น้ำส้มสายชูมีองค์ประกอบหลักคือสารใด$t$, $t$NaOH$t$, $t$CH₃COOH$t$, $t$HCl$t$, $t$H₂SO₄$t$, 1, $t$กรดแอซีติก$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$น้ำส้มสายชูมีองค์ประกอบหลักคือสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$แอมโมเนียมีกลิ่นอย่างไร$t$, $t$หอมหวาน$t$, $t$ฉุนแสบจมูก$t$, $t$กลิ่นไข่เน่า$t$, $t$ไม่มีกลิ่น$t$, 1, $t$NH₃ มีกลิ่นฉุนเฉพาะตัว$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$แอมโมเนียมีกลิ่นอย่างไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$ทรายและแก้วมีองค์ประกอบหลักเป็นสารใด$t$, $t$Fe₂O₃$t$, $t$NaCl$t$, $t$SiO₂$t$, $t$CaCO₃$t$, 2, $t$ซิลิคอนไดออกไซด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$ทรายและแก้วมีองค์ประกอบหลักเป็นสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$จุนสีเป็นผลึกสีฟ้าของสารใด$t$, $t$FeSO₄·7H₂O$t$, $t$CuSO₄·5H₂O$t$, $t$NaCl$t$, $t$CaSO₄·2H₂O$t$, 1, $t$คอปเปอร์(II) ซัลเฟตเพนตะไฮเดรต$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$จุนสีเป็นผลึกสีฟ้าของสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$ยิปซัม (ใช้ทำปูนปลาสเตอร์) คือสารใด$t$, $t$CaSO₄·2H₂O$t$, $t$CaCO₃$t$, $t$NaCl$t$, $t$CuSO₄·5H₂O$t$, 0, $t$แคลเซียมซัลเฟตไดไฮเดรต$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$ยิปซัม (ใช้ทำปูนปลาสเตอร์) คือสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$น้ำตาลทรายมีสารองค์ประกอบหลักคือสารใด$t$, $t$กลูโคส$t$, $t$ซูโครส$t$, $t$แป้ง$t$, $t$ฟรุกโทส$t$, 1, $t$ไดแซ็กคาไรด์ของกลูโคสและฟรุกโทส$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$น้ำตาลทรายมีสารองค์ประกอบหลักคือสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$แก๊สหัวเราะคือสารใด$t$, $t$N₂O$t$, $t$NO2$t$, $t$NO$t$, $t$N₂$t$, 0, $t$ไดไนโตรเจนมอนอกไซด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$แก๊สหัวเราะคือสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$น้ำยาฟอกขาวที่ใช้ซักผ้าขาวมักมีสารใดเป็นตัวออกซิไดส์หลัก$t$, $t$โซเดียมไฮโปคลอไรต์ (NaOCl)$t$, $t$โซเดียมไฮดรอกไซด์ (NaOH)$t$, $t$โซเดียมคลอไรด์ (NaCl)$t$, $t$น้ำตาล$t$, 0, $t$ฟอกสีและฆ่าเชื้อ$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$น้ำยาฟอกขาวที่ใช้ซักผ้าขาวมักมีสารใดเป็นตัวออกซิไดส์หลัก$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$ไฮโดรเจนเปอร์ออกไซด์เจือจาง (H₂O₂) ใช้ประโยชน์ในข้อใด$t$, $t$ฆ่าเชื้อบาดแผลหรือฟอกสี$t$, $t$ปุ๋ย$t$, $t$เชื้อเพลิงรถยนต์$t$, $t$ให้ความหวาน$t$, 0, $t$สลายตัวให้ออกซิเจนและน้ำ$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$ไฮโดรเจนเปอร์ออกไซด์เจือจาง (H₂O₂) ใช้ประโยชน์ในข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$แก๊สหุงต้ม (LPG) ประกอบด้วยแก๊สใดเป็นหลัก$t$, $t$ไฮโดรเจนและออกซิเจน$t$, $t$มีเทนและอีเทน$t$, $t$CO₂ และไนโตรเจน$t$, $t$โพรเพนและบิวเทน$t$, 3, $t$อัดเป็นของเหลวในถัง$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$แก๊สหุงต้ม (LPG) ประกอบด้วยแก๊สใดเป็นหลัก$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$สนิมเหล็กมีองค์ประกอบหลักเป็นสารใดโดยประมาณ$t$, $t$CaCO₃$t$, $t$Fe₂O₃$t$, $t$NaCl$t$, $t$CuO$t$, 1, $t$เหล็กรวมกับออกซิเจนและความชื้น$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$สนิมเหล็กมีองค์ประกอบหลักเป็นสารใดโดยประมาณ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารในชีวิตประจำวัน$t$, $t$ปุ๋ยยูเรียมีไนโตรเจนเป็นองค์ประกอบ มีสูตรคือข้อใด$t$, $t$(NH₂)₂CO$t$, $t$NaCl$t$, $t$CaCO₃$t$, $t$CH₄$t$, 0, $t$ยูเรียให้ธาตุไนโตรเจนแก่พืช$t$
where not exists (select 1 from quiz_questions where topic = $t$สารในชีวิตประจำวัน$t$ and question = $t$ปุ๋ยยูเรียมีไนโตรเจนเป็นองค์ประกอบ มีสูตรคือข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$เลขอาโวกาโดรมีค่าเท่าใด$t$, $t$6.02 × 10²³$t$, $t$3.01 × 10²³$t$, $t$6.02 × 10²⁴$t$, $t$6.02 × 10²²$t$, 0, $t$จำนวนอนุภาคใน 1 โมล$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$เลขอาโวกาโดรมีค่าเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$แก๊สใดๆ 1 โมล ที่ STP (0 °C, 1 atm) มีปริมาตรเท่าใด$t$, $t$1 ลิตร$t$, $t$24 ลิตร$t$, $t$22.4 ลิตร$t$, $t$11.2 ลิตร$t$, 2, $t$ปริมาตรมอลาร์ที่ STP$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$แก๊สใดๆ 1 โมล ที่ STP (0 °C, 1 atm) มีปริมาตรเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$H₂O 1 โมล มีกี่โมเลกุล$t$, $t$18 โมเลกุล$t$, $t$6.02 × 10²² โมเลกุล$t$, $t$6.02 × 10²³ โมเลกุล$t$, $t$1 โมเลกุล$t$, 2, $t$1 โมล = 6.02 × 10²³ อนุภาค$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$H₂O 1 โมล มีกี่โมเลกุล$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$มวลโมเลกุลของน้ำ (H₂O) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$, $t$36$t$, $t$20$t$, $t$18$t$, $t$16$t$, 2, $t$H₂O = 18$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$มวลโมเลกุลของน้ำ (H₂O) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$มวลโมเลกุลของคาร์บอนไดออกไซด์ (CO₂) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$, $t$42$t$, $t$88$t$, $t$44$t$, $t$46$t$, 2, $t$CO₂ = 44$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$มวลโมเลกุลของคาร์บอนไดออกไซด์ (CO₂) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$มวลโมเลกุลของโซเดียมคลอไรด์ (NaCl) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$, $t$56.5$t$, $t$60.5$t$, $t$117$t$, $t$58.5$t$, 3, $t$NaCl = 58.5$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$มวลโมเลกุลของโซเดียมคลอไรด์ (NaCl) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$มวลโมเลกุลของแอมโมเนีย (NH₃) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$, $t$34$t$, $t$15$t$, $t$19$t$, $t$17$t$, 3, $t$NH₃ = 17$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$มวลโมเลกุลของแอมโมเนีย (NH₃) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$มวลโมเลกุลของมีเทน (CH₄) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$, $t$16$t$, $t$18$t$, $t$14$t$, $t$32$t$, 0, $t$CH₄ = 16$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$มวลโมเลกุลของมีเทน (CH₄) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$มวลโมเลกุลของกรดซัลฟิวริก (H₂SO₄) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$, $t$98$t$, $t$100$t$, $t$88$t$, $t$96$t$, 0, $t$H₂SO₄ = 98$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$มวลโมเลกุลของกรดซัลฟิวริก (H₂SO₄) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$มวลโมเลกุลของแคลเซียมคาร์บอเนต (CaCO₃) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$, $t$90$t$, $t$102$t$, $t$100$t$, $t$98$t$, 2, $t$CaCO₃ = 100$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$มวลโมเลกุลของแคลเซียมคาร์บอเนต (CaCO₃) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$มวลโมเลกุลของโซเดียมไฮดรอกไซด์ (NaOH) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$, $t$40$t$, $t$80$t$, $t$42$t$, $t$38$t$, 0, $t$NaOH = 40$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$มวลโมเลกุลของโซเดียมไฮดรอกไซด์ (NaOH) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$มวลโมเลกุลของกลูโคส (C₆H₁₂O₆) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$, $t$170$t$, $t$178$t$, $t$180$t$, $t$182$t$, 2, $t$C₆H₁₂O₆ = 180$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$มวลโมเลกุลของกลูโคส (C₆H₁₂O₆) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$มวลโมเลกุลของแก๊สออกซิเจน (O₂) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$, $t$64$t$, $t$34$t$, $t$30$t$, $t$32$t$, 3, $t$O₂ = 32$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$มวลโมเลกุลของแก๊สออกซิเจน (O₂) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$มวลโมเลกุลของแก๊สไนโตรเจน (N₂) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$, $t$26$t$, $t$28$t$, $t$30$t$, $t$56$t$, 1, $t$N₂ = 28$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$มวลโมเลกุลของแก๊สไนโตรเจน (N₂) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและมวลโมเลกุล$t$, $t$มวลโมเลกุลของแคลเซียมไฮดรอกไซด์ (Ca(OH)₂) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$, $t$72$t$, $t$64$t$, $t$76$t$, $t$74$t$, 3, $t$Ca(OH)₂ = 74$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและมวลโมเลกุล$t$ and question = $t$มวลโมเลกุลของแคลเซียมไฮดรอกไซด์ (Ca(OH)₂) เท่ากับเท่าใด (H=1, C=12, N=14, O=16, Na=23, S=32, Cl=35.5, Ca=40)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สมบัติธาตุตามหมู่และคาบ$t$, $t$ธาตุใดมีค่าอิเล็กโทรเนกาติวิตีสูงที่สุดในตารางธาตุ$t$, $t$ซีเซียม$t$, $t$ออกซิเจน$t$, $t$ฟลูออรีน$t$, $t$คลอรีน$t$, 2, $t$อยู่มุมขวาบน (ไม่นับแก๊สเฉื่อย)$t$
where not exists (select 1 from quiz_questions where topic = $t$สมบัติธาตุตามหมู่และคาบ$t$ and question = $t$ธาตุใดมีค่าอิเล็กโทรเนกาติวิตีสูงที่สุดในตารางธาตุ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สมบัติธาตุตามหมู่และคาบ$t$, $t$ในหมู่เดียวกัน เมื่อเลื่อนลงล่าง ขนาดอะตอมเปลี่ยนแปลงอย่างไร$t$, $t$ใหญ่ขึ้น$t$, $t$เล็กลง$t$, $t$เล็กลงแล้วใหญ่ขึ้น$t$, $t$ไม่เปลี่ยน$t$, 0, $t$จำนวนระดับพลังงานเพิ่มขึ้น$t$
where not exists (select 1 from quiz_questions where topic = $t$สมบัติธาตุตามหมู่และคาบ$t$ and question = $t$ในหมู่เดียวกัน เมื่อเลื่อนลงล่าง ขนาดอะตอมเปลี่ยนแปลงอย่างไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สมบัติธาตุตามหมู่และคาบ$t$, $t$ในคาบเดียวกัน เมื่อไปทางขวา ขนาดอะตอมโดยทั่วไปเป็นอย่างไร$t$, $t$ใหญ่ขึ้น$t$, $t$ใหญ่ขึ้นแล้วเล็กลง$t$, $t$ไม่เปลี่ยน$t$, $t$เล็กลง$t$, 3, $t$ประจุนิวเคลียสเพิ่มขึ้น ดึงอิเล็กตรอนแรงขึ้น$t$
where not exists (select 1 from quiz_questions where topic = $t$สมบัติธาตุตามหมู่และคาบ$t$ and question = $t$ในคาบเดียวกัน เมื่อไปทางขวา ขนาดอะตอมโดยทั่วไปเป็นอย่างไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สมบัติธาตุตามหมู่และคาบ$t$, $t$พลังงานไอออไนเซชันของธาตุในคาบเดียวกันเมื่อไปทางขวาโดยทั่วไปเป็นอย่างไร$t$, $t$คงที่$t$, $t$เป็นศูนย์$t$, $t$ลดลง$t$, $t$เพิ่มขึ้น$t$, 3, $t$อะตอมเล็กลง ดึงอิเล็กตรอนแน่นขึ้น$t$
where not exists (select 1 from quiz_questions where topic = $t$สมบัติธาตุตามหมู่และคาบ$t$ and question = $t$พลังงานไอออไนเซชันของธาตุในคาบเดียวกันเมื่อไปทางขวาโดยทั่วไปเป็นอย่างไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สมบัติธาตุตามหมู่และคาบ$t$, $t$ในโลหะแอลคาไล ธาตุใดว่องไวต่อปฏิกิริยากับน้ำมากที่สุดในตัวเลือก$t$, $t$โซเดียม$t$, $t$ไฮโดรเจน$t$, $t$โพแทสเซียม$t$, $t$ลิเทียม$t$, 2, $t$ความว่องไวเพิ่มขึ้นจากบนลงล่าง$t$
where not exists (select 1 from quiz_questions where topic = $t$สมบัติธาตุตามหมู่และคาบ$t$ and question = $t$ในโลหะแอลคาไล ธาตุใดว่องไวต่อปฏิกิริยากับน้ำมากที่สุดในตัวเลือก$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สมบัติธาตุตามหมู่และคาบ$t$, $t$ธาตุหมู่ 18 เรียกว่าอะไร$t$, $t$โลหะแอลคาไล$t$, $t$โลหะแทรนซิชัน$t$, $t$ฮาโลเจน$t$, $t$แก๊สเฉื่อย$t$, 3, $t$เสถียร มีเวเลนซ์อิเล็กตรอนครบ$t$
where not exists (select 1 from quiz_questions where topic = $t$สมบัติธาตุตามหมู่และคาบ$t$ and question = $t$ธาตุหมู่ 18 เรียกว่าอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สมบัติธาตุตามหมู่และคาบ$t$, $t$ออกไซด์ของโลหะโดยทั่วไปมีสมบัติใด$t$, $t$เป็นกลางเสมอ$t$, $t$เป็นกรด$t$, $t$เป็นเบส$t$, $t$เป็นแก๊สสีน้ำเงิน$t$, 2, $t$ละลายน้ำได้สารละลายเบส เช่น Na₂O$t$
where not exists (select 1 from quiz_questions where topic = $t$สมบัติธาตุตามหมู่และคาบ$t$ and question = $t$ออกไซด์ของโลหะโดยทั่วไปมีสมบัติใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สมบัติธาตุตามหมู่และคาบ$t$, $t$ออกไซด์ของอโลหะโดยทั่วไปมีสมบัติใด$t$, $t$เป็นโลหะ$t$, $t$เป็นกรด$t$, $t$เป็นกลางเสมอ$t$, $t$เป็นเบส$t$, 1, $t$เช่น CO₂ SO₂ ละลายน้ำได้สารละลายกรด$t$
where not exists (select 1 from quiz_questions where topic = $t$สมบัติธาตุตามหมู่และคาบ$t$ and question = $t$ออกไซด์ของอโลหะโดยทั่วไปมีสมบัติใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สมบัติธาตุตามหมู่และคาบ$t$, $t$ข้อใดเป็นสมบัติของโลหะ$t$, $t$นำไฟฟ้าและนำความร้อนได้ดี$t$, $t$เป็นฉนวนความร้อน$t$, $t$เปราะแตกง่าย$t$, $t$ไม่มีความแวววาว$t$, 0, $t$โลหะมีอิเล็กตรอนอิสระ$t$
where not exists (select 1 from quiz_questions where topic = $t$สมบัติธาตุตามหมู่และคาบ$t$ and question = $t$ข้อใดเป็นสมบัติของโลหะ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สมบัติธาตุตามหมู่และคาบ$t$, $t$ธาตุกึ่งโลหะ (metalloid) ในข้อใด$t$, $t$คลอรีน$t$, $t$โซเดียม$t$, $t$ทองแดง$t$, $t$ซิลิคอน$t$, 3, $t$มีสมบัติกึ่งกลางระหว่างโลหะและอโลหะ$t$
where not exists (select 1 from quiz_questions where topic = $t$สมบัติธาตุตามหมู่และคาบ$t$ and question = $t$ธาตุกึ่งโลหะ (metalloid) ในข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สมบัติธาตุตามหมู่และคาบ$t$, $t$ธาตุแทรนซิชันมีสมบัติเด่นข้อใด$t$, $t$เป็นแก๊สทั้งหมด$t$, $t$สารประกอบมักมีสี$t$, $t$เป็นฉนวนไฟฟ้า$t$, $t$ไม่มีโลหะเลย$t$, 1, $t$เช่น Cu²⁺ สีฟ้า$t$
where not exists (select 1 from quiz_questions where topic = $t$สมบัติธาตุตามหมู่และคาบ$t$ and question = $t$ธาตุแทรนซิชันมีสมบัติเด่นข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$แก๊สและการทดสอบแก๊ส$t$, $t$แก๊สใดทำให้ไม้ขีดที่มีเพียงประกายไฟลุกขึ้นเป็นเปลวไฟได้$t$, $t$คาร์บอนไดออกไซด์$t$, $t$ฮีเลียม$t$, $t$ออกซิเจน$t$, $t$ไนโตรเจน$t$, 2, $t$ออกซิเจนช่วยให้ติดไฟ$t$
where not exists (select 1 from quiz_questions where topic = $t$แก๊สและการทดสอบแก๊ส$t$ and question = $t$แก๊สใดทำให้ไม้ขีดที่มีเพียงประกายไฟลุกขึ้นเป็นเปลวไฟได้$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$แก๊สและการทดสอบแก๊ส$t$, $t$แก๊สใดเมื่อจุดไฟให้เสียงปัง$t$, $t$คาร์บอนไดออกไซด์$t$, $t$ออกซิเจน$t$, $t$ไนโตรเจน$t$, $t$ไฮโดรเจน$t$, 3, $t$2H₂ + O₂ → 2H₂O$t$
where not exists (select 1 from quiz_questions where topic = $t$แก๊สและการทดสอบแก๊ส$t$ and question = $t$แก๊สใดเมื่อจุดไฟให้เสียงปัง$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$แก๊สและการทดสอบแก๊ส$t$, $t$แก๊สใดทำให้น้ำปูนใสขุ่น$t$, $t$ฮีเลียม$t$, $t$ออกซิเจน$t$, $t$คาร์บอนไดออกไซด์$t$, $t$ไฮโดรเจน$t$, 2, $t$เกิดตะกอนขาวของ CaCO₃$t$
where not exists (select 1 from quiz_questions where topic = $t$แก๊สและการทดสอบแก๊ส$t$ and question = $t$แก๊สใดทำให้น้ำปูนใสขุ่น$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$แก๊สและการทดสอบแก๊ส$t$, $t$แก๊สใดทำให้กระดาษลิตมัสแดงชื้นเปลี่ยนเป็นน้ำเงิน$t$, $t$ซัลเฟอร์ไดออกไซด์$t$, $t$คาร์บอนไดออกไซด์$t$, $t$คลอรีน$t$, $t$แอมโมเนีย$t$, 3, $t$แอมโมเนียเป็นเบส$t$
where not exists (select 1 from quiz_questions where topic = $t$แก๊สและการทดสอบแก๊ส$t$ and question = $t$แก๊สใดทำให้กระดาษลิตมัสแดงชื้นเปลี่ยนเป็นน้ำเงิน$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$แก๊สและการทดสอบแก๊ส$t$, $t$อากาศแห้งประกอบด้วยแก๊สชนิดใดมากที่สุด$t$, $t$ออกซิเจน (ประมาณ 78%)$t$, $t$อาร์กอน (ประมาณ 78%)$t$, $t$ไนโตรเจน (ประมาณ 78%)$t$, $t$คาร์บอนไดออกไซด์ (ประมาณ 78%)$t$, 2, $t$ออกซิเจนประมาณ 21%$t$
where not exists (select 1 from quiz_questions where topic = $t$แก๊สและการทดสอบแก๊ส$t$ and question = $t$อากาศแห้งประกอบด้วยแก๊สชนิดใดมากที่สุด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$แก๊สและการทดสอบแก๊ส$t$, $t$แก๊สใดเบากว่าอากาศและไม่ติดไฟ ใช้บรรจุบอลลูนอย่างปลอดภัย$t$, $t$ไฮโดรเจน$t$, $t$มีเทน$t$, $t$ฮีเลียม$t$, $t$คลอรีน$t$, 2, $t$ไฮโดรเจนเบาแต่ไวไฟ$t$
where not exists (select 1 from quiz_questions where topic = $t$แก๊สและการทดสอบแก๊ส$t$ and question = $t$แก๊สใดเบากว่าอากาศและไม่ติดไฟ ใช้บรรจุบอลลูนอย่างปลอดภัย$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$แก๊สและการทดสอบแก๊ส$t$, $t$แก๊สใดเป็นสาเหตุหลักของฝนกรดจากการเผาไหม้เชื้อเพลิงที่มีกำมะถัน$t$, $t$ไนโตรเจน$t$, $t$อาร์กอน$t$, $t$ซัลเฟอร์ไดออกไซด์$t$, $t$ฮีเลียม$t$, 2, $t$SO₂ ละลายน้ำเป็นกรด$t$
where not exists (select 1 from quiz_questions where topic = $t$แก๊สและการทดสอบแก๊ส$t$ and question = $t$แก๊สใดเป็นสาเหตุหลักของฝนกรดจากการเผาไหม้เชื้อเพลิงที่มีกำมะถัน$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$แก๊สและการทดสอบแก๊ส$t$, $t$แก๊สสีเหลืองอมเขียว กลิ่นฉุน ใช้ฆ่าเชื้อโรคในน้ำประปา คือแก๊สใด$t$, $t$คลอรีน$t$, $t$ไนโตรเจน$t$, $t$ออกซิเจน$t$, $t$ฟลูออรีน$t$, 0, $t$Cl₂$t$
where not exists (select 1 from quiz_questions where topic = $t$แก๊สและการทดสอบแก๊ส$t$ and question = $t$แก๊สสีเหลืองอมเขียว กลิ่นฉุน ใช้ฆ่าเชื้อโรคในน้ำประปา คือแก๊สใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$แก๊สและการทดสอบแก๊ส$t$, $t$แก๊สโอโซนมีสูตรใด$t$, $t$O$t$, $t$O₃$t$, $t$O₂$t$, $t$CO₂$t$, 1, $t$ชั้นโอโซนช่วยกรองรังสี UV$t$
where not exists (select 1 from quiz_questions where topic = $t$แก๊สและการทดสอบแก๊ส$t$ and question = $t$แก๊สโอโซนมีสูตรใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สมบัติธาตุตามหมู่และคาบ$t$, $t$อโลหะชนิดใดเป็นของเหลวที่อุณหภูมิห้อง$t$, $t$โบรมีน$t$, $t$คลอรีน$t$, $t$กำมะถัน$t$, $t$ไอโอดีน$t$, 0, $t$โบรมีนเป็นของเหลวสีแดงน้ำตาล (ปรอทเป็นโลหะเหลว)$t$
where not exists (select 1 from quiz_questions where topic = $t$สมบัติธาตุตามหมู่และคาบ$t$ and question = $t$อโลหะชนิดใดเป็นของเหลวที่อุณหภูมิห้อง$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สมบัติธาตุตามหมู่และคาบ$t$, $t$แก๊สเฉื่อยชนิดใดมีมวลอะตอมน้อยที่สุด$t$, $t$นีออน$t$, $t$ฮีเลียม$t$, $t$คริปทอน$t$, $t$อาร์กอน$t$, 1, $t$He มีเลขอะตอม 2$t$
where not exists (select 1 from quiz_questions where topic = $t$สมบัติธาตุตามหมู่และคาบ$t$ and question = $t$แก๊สเฉื่อยชนิดใดมีมวลอะตอมน้อยที่สุด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$ธาตุใดมีมากที่สุดในเปลือกโลกโดยมวล$t$, $t$อะลูมิเนียม$t$, $t$เหล็ก$t$, $t$ซิลิคอน$t$, $t$ออกซิเจน$t$, 3, $t$ประมาณ 46% โดยมวล รองลงมาคือซิลิคอน$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$ธาตุใดมีมากที่สุดในเปลือกโลกโดยมวล$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$ธาตุใดมีมากที่สุดในเอกภพ$t$, $t$คาร์บอน$t$, $t$ไฮโดรเจน$t$, $t$ออกซิเจน$t$, $t$ฮีเลียม$t$, 1, $t$H เป็นธาตุที่เบาที่สุดและพบมากที่สุดในดวงดาว$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$ธาตุใดมีมากที่สุดในเอกภพ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์ธาตุ$t$, $t$ธาตุใดเป็นองค์ประกอบหลักของสารอินทรีย์ทุกชนิด$t$, $t$ซิลิคอน$t$, $t$ไนโตรเจน$t$, $t$คาร์บอน$t$, $t$กำมะถัน$t$, 2, $t$สารอินทรีย์คือสารประกอบของคาร์บอน$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์ธาตุ$t$ and question = $t$ธาตุใดเป็นองค์ประกอบหลักของสารอินทรีย์ทุกชนิด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่ของธาตุ$t$, $t$เวเลนซ์อิเล็กตรอนคือข้อใด$t$, $t$อิเล็กตรอนทั้งหมดของอะตอม$t$, $t$อิเล็กตรอนในระดับพลังงานนอกสุดที่ใช้สร้างพันธะ$t$, $t$อิเล็กตรอนในนิวเคลียส$t$, $t$โปรตอนที่อยู่นอกสุด$t$, 1, $t$จำนวนเวเลนซ์อิเล็กตรอนเท่ากับเลขหมู่ (หมู่หลัก 1, 2 และ 13-18 ใช้หลักหน่วย)$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่ของธาตุ$t$ and question = $t$เวเลนซ์อิเล็กตรอนคือข้อใด$t$);
