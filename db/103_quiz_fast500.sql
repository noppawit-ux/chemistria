-- 103: คำถามเน้นตอบเร็วและจำ 500 ข้อ สำหรับการต่อสู้/ควิซประจำวัน (v2.49) · รันซ้ำได้ (หัวข้อ + โจทย์ซ้ำจะไม่ถูกเพิ่ม)
--  · ทุกห้อง (class_id ว่าง) · เปิดใช้งานอัตโนมัติ · ปิดรายข้อได้ในแท็บ 🎮 มินิเกม
--  · หัวข้อ: สัญลักษณ์และชื่อธาตุ 24 · เลขอะตอมและคาบ 24 · หมู่และตระกูลธาตุ 24 · โลหะ อโลหะ กึ่งโลหะ 24 · อนุภาคในอะตอม 24 · การจัดอิเล็กตรอน 24 · ประจุไอออนตามหมู่ 9 · สูตรสารประกอบไอออนิก 24 · สูตรสารเคมีท่องจำ 25 · ชื่อสามัญของสาร 25 · มวลโมเลกุลคำนวณไว 25 · โมลและค่าคงที่ 25 · กรด-เบส และ pH 25 · สีอินดิเคเตอร์ 16 · ปฏิกิริยากรด-เบส 13 · หน่วยและคำนำหน้า 25 · การใช้อุปกรณ์ 23 · ความปลอดภัยเบื้องต้น 9 · นักวิทยาศาสตร์ผู้ค้นพบ 12 · พันธะเคมี 25 · สารอินทรีย์เบื้องต้น 25 · เลขออกซิเดชันและปฏิกิริยา 25 · ความรู้เคมีรอบตัว 25

insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์และชื่อธาตุ$t$, $t$Ca คือธาตุอะไร$t$, $t$แมงกานีส$t$, $t$ทองคำ$t$, $t$แคลเซียม$t$, $t$ซัลเฟอร์ (กำมะถัน)$t$, 2, $t$Ca = แคลเซียม$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์และชื่อธาตุ$t$ and question = $t$Ca คือธาตุอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์และชื่อธาตุ$t$, $t$O คือธาตุอะไร$t$, $t$แพลทินัม$t$, $t$สารหนู$t$, $t$ทองคำ$t$, $t$ออกซิเจน$t$, 3, $t$O = ออกซิเจน$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์และชื่อธาตุ$t$ and question = $t$O คือธาตุอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์และชื่อธาตุ$t$, $t$Na คือธาตุอะไร$t$, $t$ลิเทียม$t$, $t$สแกนเดียม$t$, $t$เรเดียม$t$, $t$โซเดียม$t$, 3, $t$Na = โซเดียม$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์และชื่อธาตุ$t$ and question = $t$Na คือธาตุอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์และชื่อธาตุ$t$, $t$Mg คือธาตุอะไร$t$, $t$แมงกานีส$t$, $t$ไทเทเนียม$t$, $t$เงิน$t$, $t$แมกนีเซียม$t$, 3, $t$Mg = แมกนีเซียม$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์และชื่อธาตุ$t$ and question = $t$Mg คือธาตุอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์และชื่อธาตุ$t$, $t$Fe คือธาตุอะไร$t$, $t$ฟอสฟอรัส$t$, $t$เจอร์เมเนียม$t$, $t$ทองแดง$t$, $t$เหล็ก$t$, 3, $t$Fe = เหล็ก$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์และชื่อธาตุ$t$ and question = $t$Fe คือธาตุอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์และชื่อธาตุ$t$, $t$I คือธาตุอะไร$t$, $t$ไอโอดีน$t$, $t$สแกนเดียม$t$, $t$โคบอลต์$t$, $t$คาร์บอน$t$, 0, $t$I = ไอโอดีน$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์และชื่อธาตุ$t$ and question = $t$I คือธาตุอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์และชื่อธาตุ$t$, $t$P คือธาตุอะไร$t$, $t$แบเรียม$t$, $t$ฟอสฟอรัส$t$, $t$แคลเซียม$t$, $t$ปรอท$t$, 1, $t$P = ฟอสฟอรัส$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์และชื่อธาตุ$t$ and question = $t$P คือธาตุอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์และชื่อธาตุ$t$, $t$Au คือธาตุอะไร$t$, $t$แบเรียม$t$, $t$ทองคำ$t$, $t$ปรอท$t$, $t$ซัลเฟอร์ (กำมะถัน)$t$, 1, $t$Au = ทองคำ$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์และชื่อธาตุ$t$ and question = $t$Au คือธาตุอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์และชื่อธาตุ$t$, $t$H คือธาตุอะไร$t$, $t$ไฮโดรเจน$t$, $t$ซีเซียม$t$, $t$พลวง$t$, $t$คริปทอน$t$, 0, $t$H = ไฮโดรเจน$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์และชื่อธาตุ$t$ and question = $t$H คือธาตุอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์และชื่อธาตุ$t$, $t$ฟลูออรีน เขียนสัญลักษณ์ว่า$t$, $t$Cu$t$, $t$Fe$t$, $t$B$t$, $t$F$t$, 3, $t$ฟลูออรีน = F$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์และชื่อธาตุ$t$ and question = $t$ฟลูออรีน เขียนสัญลักษณ์ว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์และชื่อธาตุ$t$, $t$โครเมียม เขียนสัญลักษณ์ว่า$t$, $t$Cl$t$, $t$Cr$t$, $t$Ca$t$, $t$C$t$, 1, $t$โครเมียม = Cr$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์และชื่อธาตุ$t$ and question = $t$โครเมียม เขียนสัญลักษณ์ว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์และชื่อธาตุ$t$, $t$ตะกั่ว เขียนสัญลักษณ์ว่า$t$, $t$Pb$t$, $t$N$t$, $t$P$t$, $t$Pt$t$, 0, $t$ตะกั่ว = Pb$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์และชื่อธาตุ$t$ and question = $t$ตะกั่ว เขียนสัญลักษณ์ว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์และชื่อธาตุ$t$, $t$คาร์บอน เขียนสัญลักษณ์ว่า$t$, $t$C$t$, $t$Cr$t$, $t$Cl$t$, $t$Ca$t$, 0, $t$คาร์บอน = C$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์และชื่อธาตุ$t$ and question = $t$คาร์บอน เขียนสัญลักษณ์ว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์และชื่อธาตุ$t$, $t$อะลูมิเนียม เขียนสัญลักษณ์ว่า$t$, $t$Ag$t$, $t$Ar$t$, $t$As$t$, $t$Al$t$, 3, $t$อะลูมิเนียม = Al$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์และชื่อธาตุ$t$ and question = $t$อะลูมิเนียม เขียนสัญลักษณ์ว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์และชื่อธาตุ$t$, $t$ยูเรเนียม เขียนสัญลักษณ์ว่า$t$, $t$Ra$t$, $t$Ga$t$, $t$U$t$, $t$Xe$t$, 2, $t$ยูเรเนียม = U$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์และชื่อธาตุ$t$ and question = $t$ยูเรเนียม เขียนสัญลักษณ์ว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์และชื่อธาตุ$t$, $t$เจอร์เมเนียม เขียนสัญลักษณ์ว่า$t$, $t$Rn$t$, $t$Ga$t$, $t$Au$t$, $t$Ge$t$, 3, $t$เจอร์เมเนียม = Ge$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์และชื่อธาตุ$t$ and question = $t$เจอร์เมเนียม เขียนสัญลักษณ์ว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์และชื่อธาตุ$t$, $t$แมกนีเซียม เขียนสัญลักษณ์ว่า$t$, $t$Mg$t$, $t$Xe$t$, $t$Mn$t$, $t$Cu$t$, 0, $t$แมกนีเซียม = Mg$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์และชื่อธาตุ$t$ and question = $t$แมกนีเซียม เขียนสัญลักษณ์ว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์และชื่อธาตุ$t$, $t$เรดอน เขียนสัญลักษณ์ว่า$t$, $t$Rn$t$, $t$Ra$t$, $t$Ba$t$, $t$Rb$t$, 0, $t$เรดอน = Rn$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์และชื่อธาตุ$t$ and question = $t$เรดอน เขียนสัญลักษณ์ว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์และชื่อธาตุ$t$, $t$เรเดียม เขียนสัญลักษณ์ว่า$t$, $t$Rb$t$, $t$Rn$t$, $t$Ra$t$, $t$Cs$t$, 2, $t$เรเดียม = Ra$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์และชื่อธาตุ$t$ and question = $t$เรเดียม เขียนสัญลักษณ์ว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์และชื่อธาตุ$t$, $t$เบริลเลียม เขียนสัญลักษณ์ว่า$t$, $t$B$t$, $t$Ba$t$, $t$Br$t$, $t$Be$t$, 3, $t$เบริลเลียม = Be$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์และชื่อธาตุ$t$ and question = $t$เบริลเลียม เขียนสัญลักษณ์ว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์และชื่อธาตุ$t$, $t$ไนโตรเจน เขียนสัญลักษณ์ว่า$t$, $t$N$t$, $t$Ni$t$, $t$Ne$t$, $t$Na$t$, 0, $t$ไนโตรเจน = N$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์และชื่อธาตุ$t$ and question = $t$ไนโตรเจน เขียนสัญลักษณ์ว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์และชื่อธาตุ$t$, $t$สัญลักษณ์ Au ย่อมาจากชื่อละติน aurum คือธาตุใด$t$, $t$ฮีเลียม$t$, $t$แคลเซียม$t$, $t$ทองคำ$t$, $t$ซีเซียม$t$, 2, $t$Au มาจาก aurum (ออรัม) คือทองคำ$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์และชื่อธาตุ$t$ and question = $t$สัญลักษณ์ Au ย่อมาจากชื่อละติน aurum คือธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์และชื่อธาตุ$t$, $t$สัญลักษณ์ Pb ย่อมาจากชื่อละติน plumbum คือธาตุใด$t$, $t$ตะกั่ว$t$, $t$ทองคำ$t$, $t$สารหนู$t$, $t$รูบิเดียม$t$, 0, $t$Pb มาจาก plumbum (พลัมบัม) คือตะกั่ว$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์และชื่อธาตุ$t$ and question = $t$สัญลักษณ์ Pb ย่อมาจากชื่อละติน plumbum คือธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สัญลักษณ์และชื่อธาตุ$t$, $t$สัญลักษณ์ Sb ย่อมาจากชื่อละติน stibium คือธาตุใด$t$, $t$โซเดียม$t$, $t$ออกซิเจน$t$, $t$ซีนอน$t$, $t$พลวง$t$, 3, $t$Sb มาจาก stibium (สติเบียม) คือพลวง$t$
where not exists (select 1 from quiz_questions where topic = $t$สัญลักษณ์และชื่อธาตุ$t$ and question = $t$สัญลักษณ์ Sb ย่อมาจากชื่อละติน stibium คือธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอมและคาบ$t$, $t$เลขอะตอมของ O คือ$t$, $t$6$t$, $t$10$t$, $t$8$t$, $t$7$t$, 2, $t$ออกซิเจน (O) เลขอะตอม 8$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอมและคาบ$t$ and question = $t$เลขอะตอมของ O คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอมและคาบ$t$, $t$เลขอะตอมของ Al คือ$t$, $t$14$t$, $t$11$t$, $t$13$t$, $t$12$t$, 2, $t$อะลูมิเนียม (Al) เลขอะตอม 13$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอมและคาบ$t$ and question = $t$เลขอะตอมของ Al คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอมและคาบ$t$, $t$เลขอะตอมของ B คือ$t$, $t$8$t$, $t$6$t$, $t$4$t$, $t$5$t$, 3, $t$โบรอน (B) เลขอะตอม 5$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอมและคาบ$t$ and question = $t$เลขอะตอมของ B คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอมและคาบ$t$, $t$เลขอะตอมของ N คือ$t$, $t$10$t$, $t$7$t$, $t$6$t$, $t$9$t$, 1, $t$ไนโตรเจน (N) เลขอะตอม 7$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอมและคาบ$t$ and question = $t$เลขอะตอมของ N คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอมและคาบ$t$, $t$เลขอะตอมของ H คือ$t$, $t$-1$t$, $t$4$t$, $t$0$t$, $t$1$t$, 3, $t$ไฮโดรเจน (H) เลขอะตอม 1$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอมและคาบ$t$ and question = $t$เลขอะตอมของ H คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอมและคาบ$t$, $t$เลขอะตอมของ Li คือ$t$, $t$4$t$, $t$3$t$, $t$1$t$, $t$2$t$, 1, $t$ลิเทียม (Li) เลขอะตอม 3$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอมและคาบ$t$ and question = $t$เลขอะตอมของ Li คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอมและคาบ$t$, $t$เลขอะตอมของ F คือ$t$, $t$7$t$, $t$10$t$, $t$12$t$, $t$9$t$, 3, $t$ฟลูออรีน (F) เลขอะตอม 9$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอมและคาบ$t$ and question = $t$เลขอะตอมของ F คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอมและคาบ$t$, $t$เลขอะตอมของ Na คือ$t$, $t$12$t$, $t$13$t$, $t$9$t$, $t$11$t$, 3, $t$โซเดียม (Na) เลขอะตอม 11$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอมและคาบ$t$ and question = $t$เลขอะตอมของ Na คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอมและคาบ$t$, $t$เลขอะตอมของ S คือ$t$, $t$14$t$, $t$17$t$, $t$16$t$, $t$18$t$, 2, $t$ซัลเฟอร์ (กำมะถัน) (S) เลขอะตอม 16$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอมและคาบ$t$ and question = $t$เลขอะตอมของ S คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอมและคาบ$t$, $t$ธาตุเลขอะตอม 15 คือ$t$, $t$เบริลเลียม (Be)$t$, $t$ซิลิคอน (Si)$t$, $t$ฟอสฟอรัส (P)$t$, $t$ซัลเฟอร์ (S)$t$, 2, $t$เลขอะตอม 15 = ฟอสฟอรัส (P)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอมและคาบ$t$ and question = $t$ธาตุเลขอะตอม 15 คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอมและคาบ$t$, $t$ธาตุเลขอะตอม 12 คือ$t$, $t$แมกนีเซียม (Mg)$t$, $t$นีออน (Ne)$t$, $t$โซเดียม (Na)$t$, $t$แคลเซียม (Ca)$t$, 0, $t$เลขอะตอม 12 = แมกนีเซียม (Mg)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอมและคาบ$t$ and question = $t$ธาตุเลขอะตอม 12 คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอมและคาบ$t$, $t$ธาตุเลขอะตอม 9 คือ$t$, $t$โพแทสเซียม (K)$t$, $t$แมกนีเซียม (Mg)$t$, $t$ซัลเฟอร์ (S)$t$, $t$ฟลูออรีน (F)$t$, 3, $t$เลขอะตอม 9 = ฟลูออรีน (F)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอมและคาบ$t$ and question = $t$ธาตุเลขอะตอม 9 คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอมและคาบ$t$, $t$ธาตุเลขอะตอม 5 คือ$t$, $t$ฮีเลียม (He)$t$, $t$ไนโตรเจน (N)$t$, $t$คลอรีน (Cl)$t$, $t$โบรอน (B)$t$, 3, $t$เลขอะตอม 5 = โบรอน (B)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอมและคาบ$t$ and question = $t$ธาตุเลขอะตอม 5 คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอมและคาบ$t$, $t$ธาตุเลขอะตอม 6 คือ$t$, $t$ฟอสฟอรัส (P)$t$, $t$แคลเซียม (Ca)$t$, $t$คาร์บอน (C)$t$, $t$ฟลูออรีน (F)$t$, 2, $t$เลขอะตอม 6 = คาร์บอน (C)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอมและคาบ$t$ and question = $t$ธาตุเลขอะตอม 6 คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอมและคาบ$t$, $t$ธาตุเลขอะตอม 1 คือ$t$, $t$คาร์บอน (C)$t$, $t$ไฮโดรเจน (H)$t$, $t$ไนโตรเจน (N)$t$, $t$ออกซิเจน (O)$t$, 1, $t$เลขอะตอม 1 = ไฮโดรเจน (H)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอมและคาบ$t$ and question = $t$ธาตุเลขอะตอม 1 คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอมและคาบ$t$, $t$ธาตุเลขอะตอม 16 คือ$t$, $t$โพแทสเซียม (K)$t$, $t$นีออน (Ne)$t$, $t$ฟอสฟอรัส (P)$t$, $t$ซัลเฟอร์ (S)$t$, 3, $t$เลขอะตอม 16 = ซัลเฟอร์ (กำมะถัน) (S)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอมและคาบ$t$ and question = $t$ธาตุเลขอะตอม 16 คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอมและคาบ$t$, $t$K อยู่ในคาบที่เท่าใด$t$, $t$คาบ 1$t$, $t$คาบ 3$t$, $t$คาบ 4$t$, $t$คาบ 2$t$, 2, $t$K เลขอะตอม 19 อยู่คาบ 4 (จำนวนระดับพลังงานที่มีอิเล็กตรอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอมและคาบ$t$ and question = $t$K อยู่ในคาบที่เท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอมและคาบ$t$, $t$S อยู่ในคาบที่เท่าใด$t$, $t$คาบ 3$t$, $t$คาบ 2$t$, $t$คาบ 1$t$, $t$คาบ 4$t$, 0, $t$S เลขอะตอม 16 อยู่คาบ 3 (จำนวนระดับพลังงานที่มีอิเล็กตรอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอมและคาบ$t$ and question = $t$S อยู่ในคาบที่เท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอมและคาบ$t$, $t$H อยู่ในคาบที่เท่าใด$t$, $t$คาบ 4$t$, $t$คาบ 1$t$, $t$คาบ 3$t$, $t$คาบ 2$t$, 1, $t$H เลขอะตอม 1 อยู่คาบ 1 (จำนวนระดับพลังงานที่มีอิเล็กตรอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอมและคาบ$t$ and question = $t$H อยู่ในคาบที่เท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอมและคาบ$t$, $t$Be อยู่ในคาบที่เท่าใด$t$, $t$คาบ 2$t$, $t$คาบ 3$t$, $t$คาบ 4$t$, $t$คาบ 1$t$, 0, $t$Be เลขอะตอม 4 อยู่คาบ 2 (จำนวนระดับพลังงานที่มีอิเล็กตรอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอมและคาบ$t$ and question = $t$Be อยู่ในคาบที่เท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอมและคาบ$t$, $t$Ar อยู่ในคาบที่เท่าใด$t$, $t$คาบ 1$t$, $t$คาบ 4$t$, $t$คาบ 2$t$, $t$คาบ 3$t$, 3, $t$Ar เลขอะตอม 18 อยู่คาบ 3 (จำนวนระดับพลังงานที่มีอิเล็กตรอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอมและคาบ$t$ and question = $t$Ar อยู่ในคาบที่เท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอมและคาบ$t$, $t$B อยู่ในคาบที่เท่าใด$t$, $t$คาบ 2$t$, $t$คาบ 4$t$, $t$คาบ 1$t$, $t$คาบ 3$t$, 0, $t$B เลขอะตอม 5 อยู่คาบ 2 (จำนวนระดับพลังงานที่มีอิเล็กตรอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอมและคาบ$t$ and question = $t$B อยู่ในคาบที่เท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอมและคาบ$t$, $t$Li อยู่ในคาบที่เท่าใด$t$, $t$คาบ 1$t$, $t$คาบ 2$t$, $t$คาบ 3$t$, $t$คาบ 4$t$, 1, $t$Li เลขอะตอม 3 อยู่คาบ 2 (จำนวนระดับพลังงานที่มีอิเล็กตรอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอมและคาบ$t$ and question = $t$Li อยู่ในคาบที่เท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขอะตอมและคาบ$t$, $t$Cl อยู่ในคาบที่เท่าใด$t$, $t$คาบ 2$t$, $t$คาบ 1$t$, $t$คาบ 3$t$, $t$คาบ 4$t$, 2, $t$Cl เลขอะตอม 17 อยู่คาบ 3 (จำนวนระดับพลังงานที่มีอิเล็กตรอน)$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขอะตอมและคาบ$t$ and question = $t$Cl อยู่ในคาบที่เท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่และตระกูลธาตุ$t$, $t$Na อยู่หมู่ที่$t$, $t$หมู่ 2$t$, $t$หมู่ 17$t$, $t$หมู่ 14$t$, $t$หมู่ 1$t$, 3, $t$Na อยู่หมู่ 1$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่และตระกูลธาตุ$t$ and question = $t$Na อยู่หมู่ที่$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่และตระกูลธาตุ$t$, $t$P อยู่หมู่ที่$t$, $t$หมู่ 2$t$, $t$หมู่ 15$t$, $t$หมู่ 1$t$, $t$หมู่ 16$t$, 1, $t$P อยู่หมู่ 15$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่และตระกูลธาตุ$t$ and question = $t$P อยู่หมู่ที่$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่และตระกูลธาตุ$t$, $t$Si อยู่หมู่ที่$t$, $t$หมู่ 15$t$, $t$หมู่ 18$t$, $t$หมู่ 14$t$, $t$หมู่ 1$t$, 2, $t$Si อยู่หมู่ 14$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่และตระกูลธาตุ$t$ and question = $t$Si อยู่หมู่ที่$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่และตระกูลธาตุ$t$, $t$S อยู่หมู่ที่$t$, $t$หมู่ 1$t$, $t$หมู่ 14$t$, $t$หมู่ 16$t$, $t$หมู่ 2$t$, 2, $t$S อยู่หมู่ 16$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่และตระกูลธาตุ$t$ and question = $t$S อยู่หมู่ที่$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่และตระกูลธาตุ$t$, $t$Cl อยู่หมู่ที่$t$, $t$หมู่ 13$t$, $t$หมู่ 17$t$, $t$หมู่ 2$t$, $t$หมู่ 1$t$, 1, $t$Cl อยู่หมู่ 17$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่และตระกูลธาตุ$t$ and question = $t$Cl อยู่หมู่ที่$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่และตระกูลธาตุ$t$, $t$B อยู่หมู่ที่$t$, $t$หมู่ 17$t$, $t$หมู่ 13$t$, $t$หมู่ 16$t$, $t$หมู่ 2$t$, 1, $t$B อยู่หมู่ 13$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่และตระกูลธาตุ$t$ and question = $t$B อยู่หมู่ที่$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่และตระกูลธาตุ$t$, $t$Mg อยู่หมู่ที่$t$, $t$หมู่ 13$t$, $t$หมู่ 2$t$, $t$หมู่ 1$t$, $t$หมู่ 16$t$, 1, $t$Mg อยู่หมู่ 2$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่และตระกูลธาตุ$t$ and question = $t$Mg อยู่หมู่ที่$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่และตระกูลธาตุ$t$, $t$H อยู่หมู่ที่$t$, $t$หมู่ 18$t$, $t$หมู่ 2$t$, $t$หมู่ 1$t$, $t$หมู่ 17$t$, 2, $t$H อยู่หมู่ 1$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่และตระกูลธาตุ$t$ and question = $t$H อยู่หมู่ที่$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่และตระกูลธาตุ$t$, $t$K อยู่หมู่ที่$t$, $t$หมู่ 17$t$, $t$หมู่ 14$t$, $t$หมู่ 16$t$, $t$หมู่ 1$t$, 3, $t$K อยู่หมู่ 1$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่และตระกูลธาตุ$t$ and question = $t$K อยู่หมู่ที่$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่และตระกูลธาตุ$t$, $t$He อยู่หมู่ที่$t$, $t$หมู่ 16$t$, $t$หมู่ 13$t$, $t$หมู่ 18$t$, $t$หมู่ 17$t$, 2, $t$He อยู่หมู่ 18$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่และตระกูลธาตุ$t$ and question = $t$He อยู่หมู่ที่$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่และตระกูลธาตุ$t$, $t$O อยู่หมู่ที่$t$, $t$หมู่ 18$t$, $t$หมู่ 14$t$, $t$หมู่ 16$t$, $t$หมู่ 1$t$, 2, $t$O อยู่หมู่ 16$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่และตระกูลธาตุ$t$ and question = $t$O อยู่หมู่ที่$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่และตระกูลธาตุ$t$, $t$หมู่ 1 (ยกเว้น H) เรียกว่า$t$, $t$แฮโลเจน$t$, $t$โลหะแอลคาไล$t$, $t$โลหะแอลคาไลน์เอิร์ท$t$, $t$แก๊สเฉื่อย$t$, 1, $t$โลหะแอลคาไล$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่และตระกูลธาตุ$t$ and question = $t$หมู่ 1 (ยกเว้น H) เรียกว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่และตระกูลธาตุ$t$, $t$Ca เป็นธาตุตระกูลใด$t$, $t$แก๊สเฉื่อย$t$, $t$โลหะแอลคาไลน์เอิร์ท$t$, $t$โลหะแอลคาไล$t$, $t$แฮโลเจน$t$, 1, $t$โลหะแอลคาไลน์เอิร์ท$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่และตระกูลธาตุ$t$ and question = $t$Ca เป็นธาตุตระกูลใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่และตระกูลธาตุ$t$, $t$Cl เป็นธาตุตระกูลใด$t$, $t$โลหะแอลคาไลน์เอิร์ท$t$, $t$แฮโลเจน$t$, $t$แก๊สเฉื่อย$t$, $t$โลหะแอลคาไล$t$, 1, $t$แฮโลเจน$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่และตระกูลธาตุ$t$ and question = $t$Cl เป็นธาตุตระกูลใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่และตระกูลธาตุ$t$, $t$Ne เป็นธาตุตระกูลใด$t$, $t$โลหะแอลคาไลน์เอิร์ท$t$, $t$โลหะแอลคาไล$t$, $t$แก๊สเฉื่อย$t$, $t$แฮโลเจน$t$, 2, $t$แก๊สเฉื่อย$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่และตระกูลธาตุ$t$ and question = $t$Ne เป็นธาตุตระกูลใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่และตระกูลธาตุ$t$, $t$K เป็นธาตุตระกูลใด$t$, $t$โลหะแอลคาไลน์เอิร์ท$t$, $t$โลหะแอลคาไล$t$, $t$แก๊สเฉื่อย$t$, $t$แฮโลเจน$t$, 1, $t$โลหะแอลคาไล$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่และตระกูลธาตุ$t$ and question = $t$K เป็นธาตุตระกูลใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่และตระกูลธาตุ$t$, $t$Br เป็นธาตุตระกูลใด$t$, $t$โลหะแอลคาไล$t$, $t$โลหะแอลคาไลน์เอิร์ท$t$, $t$แฮโลเจน$t$, $t$แก๊สเฉื่อย$t$, 2, $t$แฮโลเจน$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่และตระกูลธาตุ$t$ and question = $t$Br เป็นธาตุตระกูลใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่และตระกูลธาตุ$t$, $t$Mg เป็นธาตุตระกูลใด$t$, $t$โลหะแอลคาไลน์เอิร์ท$t$, $t$แก๊สเฉื่อย$t$, $t$แฮโลเจน$t$, $t$โลหะแอลคาไล$t$, 0, $t$โลหะแอลคาไลน์เอิร์ท$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่และตระกูลธาตุ$t$ and question = $t$Mg เป็นธาตุตระกูลใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่และตระกูลธาตุ$t$, $t$ธาตุหมู่ 3-12 เรียกว่า$t$, $t$แฮโลเจน$t$, $t$แก๊สเฉื่อย$t$, $t$ธาตุแทรนซิชัน$t$, $t$โลหะแอลคาไล$t$, 2, $t$ธาตุแทรนซิชัน$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่และตระกูลธาตุ$t$ and question = $t$ธาตุหมู่ 3-12 เรียกว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่และตระกูลธาตุ$t$, $t$ธาตุในหมู่เดียวกันมีสิ่งใดเท่ากัน$t$, $t$จำนวนเวเลนซ์อิเล็กตรอน$t$, $t$จำนวนนิวตรอน$t$, $t$มวลอะตอม$t$, $t$จำนวนโปรตอน$t$, 0, $t$จำนวนเวเลนซ์อิเล็กตรอน$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่และตระกูลธาตุ$t$ and question = $t$ธาตุในหมู่เดียวกันมีสิ่งใดเท่ากัน$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่และตระกูลธาตุ$t$, $t$ธาตุในคาบเดียวกันมีสิ่งใดเท่ากัน$t$, $t$จำนวนโปรตอน$t$, $t$มวลอะตอม$t$, $t$จำนวนเวเลนซ์อิเล็กตรอน$t$, $t$จำนวนระดับพลังงาน$t$, 3, $t$จำนวนระดับพลังงาน$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่และตระกูลธาตุ$t$ and question = $t$ธาตุในคาบเดียวกันมีสิ่งใดเท่ากัน$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่และตระกูลธาตุ$t$, $t$ตารางธาตุปัจจุบันเรียงธาตุตามอะไร$t$, $t$เลขอะตอมจากน้อยไปมาก$t$, $t$ชื่อธาตุ$t$, $t$ความหนาแน่น$t$, $t$มวลอะตอม$t$, 0, $t$เลขอะตอมจากน้อยไปมาก$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่และตระกูลธาตุ$t$ and question = $t$ตารางธาตุปัจจุบันเรียงธาตุตามอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่และตระกูลธาตุ$t$, $t$ตารางธาตุมีกี่หมู่ (ระบบ 1-18)$t$, $t$18 หมู่$t$, $t$8 หมู่$t$, $t$10 หมู่$t$, $t$7 หมู่$t$, 0, $t$18 หมู่$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่และตระกูลธาตุ$t$ and question = $t$ตารางธาตุมีกี่หมู่ (ระบบ 1-18)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หมู่และตระกูลธาตุ$t$, $t$ตารางธาตุมีกี่คาบ$t$, $t$7 คาบ$t$, $t$6 คาบ$t$, $t$8 คาบ$t$, $t$18 คาบ$t$, 0, $t$7 คาบ$t$
where not exists (select 1 from quiz_questions where topic = $t$หมู่และตระกูลธาตุ$t$ and question = $t$ตารางธาตุมีกี่คาบ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โลหะ อโลหะ กึ่งโลหะ$t$, $t$I (ไอโอดีน) เป็นธาตุประเภทใด$t$, $t$กึ่งโลหะ$t$, $t$แก๊สเฉื่อย$t$, $t$อโลหะ$t$, $t$โลหะ$t$, 2, $t$I เป็นอโลหะ$t$
where not exists (select 1 from quiz_questions where topic = $t$โลหะ อโลหะ กึ่งโลหะ$t$ and question = $t$I (ไอโอดีน) เป็นธาตุประเภทใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โลหะ อโลหะ กึ่งโลหะ$t$, $t$Cl (คลอรีน) เป็นธาตุประเภทใด$t$, $t$อโลหะ$t$, $t$แก๊สเฉื่อย$t$, $t$กึ่งโลหะ$t$, $t$โลหะ$t$, 0, $t$Cl เป็นอโลหะ$t$
where not exists (select 1 from quiz_questions where topic = $t$โลหะ อโลหะ กึ่งโลหะ$t$ and question = $t$Cl (คลอรีน) เป็นธาตุประเภทใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โลหะ อโลหะ กึ่งโลหะ$t$, $t$P (ฟอสฟอรัส) เป็นธาตุประเภทใด$t$, $t$อโลหะ$t$, $t$กึ่งโลหะ$t$, $t$โลหะ$t$, $t$แก๊สเฉื่อย$t$, 0, $t$P เป็นอโลหะ$t$
where not exists (select 1 from quiz_questions where topic = $t$โลหะ อโลหะ กึ่งโลหะ$t$ and question = $t$P (ฟอสฟอรัส) เป็นธาตุประเภทใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โลหะ อโลหะ กึ่งโลหะ$t$, $t$K (โพแทสเซียม) เป็นธาตุประเภทใด$t$, $t$อโลหะ$t$, $t$โลหะ$t$, $t$กึ่งโลหะ$t$, $t$แก๊สเฉื่อย$t$, 1, $t$K เป็นโลหะ$t$
where not exists (select 1 from quiz_questions where topic = $t$โลหะ อโลหะ กึ่งโลหะ$t$ and question = $t$K (โพแทสเซียม) เป็นธาตุประเภทใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โลหะ อโลหะ กึ่งโลหะ$t$, $t$Si (ซิลิคอน) เป็นธาตุประเภทใด$t$, $t$อโลหะ$t$, $t$โลหะ$t$, $t$แก๊สเฉื่อย$t$, $t$กึ่งโลหะ$t$, 3, $t$Si เป็นกึ่งโลหะ$t$
where not exists (select 1 from quiz_questions where topic = $t$โลหะ อโลหะ กึ่งโลหะ$t$ and question = $t$Si (ซิลิคอน) เป็นธาตุประเภทใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โลหะ อโลหะ กึ่งโลหะ$t$, $t$Fe (เหล็ก) เป็นธาตุประเภทใด$t$, $t$แก๊สเฉื่อย$t$, $t$โลหะ$t$, $t$กึ่งโลหะ$t$, $t$อโลหะ$t$, 1, $t$Fe เป็นโลหะ$t$
where not exists (select 1 from quiz_questions where topic = $t$โลหะ อโลหะ กึ่งโลหะ$t$ and question = $t$Fe (เหล็ก) เป็นธาตุประเภทใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โลหะ อโลหะ กึ่งโลหะ$t$, $t$B (โบรอน) เป็นธาตุประเภทใด$t$, $t$กึ่งโลหะ$t$, $t$แก๊สเฉื่อย$t$, $t$โลหะ$t$, $t$อโลหะ$t$, 0, $t$B เป็นกึ่งโลหะ$t$
where not exists (select 1 from quiz_questions where topic = $t$โลหะ อโลหะ กึ่งโลหะ$t$ and question = $t$B (โบรอน) เป็นธาตุประเภทใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โลหะ อโลหะ กึ่งโลหะ$t$, $t$Ge (เจอร์เมเนียม) เป็นธาตุประเภทใด$t$, $t$แก๊สเฉื่อย$t$, $t$อโลหะ$t$, $t$โลหะ$t$, $t$กึ่งโลหะ$t$, 3, $t$Ge เป็นกึ่งโลหะ$t$
where not exists (select 1 from quiz_questions where topic = $t$โลหะ อโลหะ กึ่งโลหะ$t$ and question = $t$Ge (เจอร์เมเนียม) เป็นธาตุประเภทใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โลหะ อโลหะ กึ่งโลหะ$t$, $t$Ag (เงิน) เป็นธาตุประเภทใด$t$, $t$โลหะ$t$, $t$แก๊สเฉื่อย$t$, $t$อโลหะ$t$, $t$กึ่งโลหะ$t$, 0, $t$Ag เป็นโลหะ$t$
where not exists (select 1 from quiz_questions where topic = $t$โลหะ อโลหะ กึ่งโลหะ$t$ and question = $t$Ag (เงิน) เป็นธาตุประเภทใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โลหะ อโลหะ กึ่งโลหะ$t$, $t$Pb (ตะกั่ว) เป็นธาตุประเภทใด$t$, $t$แก๊สเฉื่อย$t$, $t$โลหะ$t$, $t$อโลหะ$t$, $t$กึ่งโลหะ$t$, 1, $t$Pb เป็นโลหะ$t$
where not exists (select 1 from quiz_questions where topic = $t$โลหะ อโลหะ กึ่งโลหะ$t$ and question = $t$Pb (ตะกั่ว) เป็นธาตุประเภทใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โลหะ อโลหะ กึ่งโลหะ$t$, $t$Zn (สังกะสี) เป็นธาตุประเภทใด$t$, $t$แก๊สเฉื่อย$t$, $t$อโลหะ$t$, $t$กึ่งโลหะ$t$, $t$โลหะ$t$, 3, $t$Zn เป็นโลหะ$t$
where not exists (select 1 from quiz_questions where topic = $t$โลหะ อโลหะ กึ่งโลหะ$t$ and question = $t$Zn (สังกะสี) เป็นธาตุประเภทใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โลหะ อโลหะ กึ่งโลหะ$t$, $t$Sn (ดีบุก) เป็นธาตุประเภทใด$t$, $t$แก๊สเฉื่อย$t$, $t$กึ่งโลหะ$t$, $t$โลหะ$t$, $t$อโลหะ$t$, 2, $t$Sn เป็นโลหะ$t$
where not exists (select 1 from quiz_questions where topic = $t$โลหะ อโลหะ กึ่งโลหะ$t$ and question = $t$Sn (ดีบุก) เป็นธาตุประเภทใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โลหะ อโลหะ กึ่งโลหะ$t$, $t$Hg (ปรอท) เป็นธาตุประเภทใด$t$, $t$โลหะ$t$, $t$อโลหะ$t$, $t$แก๊สเฉื่อย$t$, $t$กึ่งโลหะ$t$, 0, $t$Hg เป็นโลหะ$t$
where not exists (select 1 from quiz_questions where topic = $t$โลหะ อโลหะ กึ่งโลหะ$t$ and question = $t$Hg (ปรอท) เป็นธาตุประเภทใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โลหะ อโลหะ กึ่งโลหะ$t$, $t$N (ไนโตรเจน) เป็นธาตุประเภทใด$t$, $t$โลหะ$t$, $t$อโลหะ$t$, $t$กึ่งโลหะ$t$, $t$แก๊สเฉื่อย$t$, 1, $t$N เป็นอโลหะ$t$
where not exists (select 1 from quiz_questions where topic = $t$โลหะ อโลหะ กึ่งโลหะ$t$ and question = $t$N (ไนโตรเจน) เป็นธาตุประเภทใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โลหะ อโลหะ กึ่งโลหะ$t$, $t$He (ฮีเลียม) เป็นธาตุประเภทใด$t$, $t$แก๊สเฉื่อย$t$, $t$อโลหะ$t$, $t$โลหะ$t$, $t$กึ่งโลหะ$t$, 1, $t$He เป็นอโลหะ$t$
where not exists (select 1 from quiz_questions where topic = $t$โลหะ อโลหะ กึ่งโลหะ$t$ and question = $t$He (ฮีเลียม) เป็นธาตุประเภทใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โลหะ อโลหะ กึ่งโลหะ$t$, $t$Cu (ทองแดง) เป็นธาตุประเภทใด$t$, $t$อโลหะ$t$, $t$กึ่งโลหะ$t$, $t$แก๊สเฉื่อย$t$, $t$โลหะ$t$, 3, $t$Cu เป็นโลหะ$t$
where not exists (select 1 from quiz_questions where topic = $t$โลหะ อโลหะ กึ่งโลหะ$t$ and question = $t$Cu (ทองแดง) เป็นธาตุประเภทใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โลหะ อโลหะ กึ่งโลหะ$t$, $t$Au (ทองคำ) เป็นธาตุประเภทใด$t$, $t$กึ่งโลหะ$t$, $t$โลหะ$t$, $t$อโลหะ$t$, $t$แก๊สเฉื่อย$t$, 1, $t$Au เป็นโลหะ$t$
where not exists (select 1 from quiz_questions where topic = $t$โลหะ อโลหะ กึ่งโลหะ$t$ and question = $t$Au (ทองคำ) เป็นธาตุประเภทใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โลหะ อโลหะ กึ่งโลหะ$t$, $t$Sb (พลวง) เป็นธาตุประเภทใด$t$, $t$โลหะ$t$, $t$อโลหะ$t$, $t$กึ่งโลหะ$t$, $t$แก๊สเฉื่อย$t$, 2, $t$Sb เป็นกึ่งโลหะ$t$
where not exists (select 1 from quiz_questions where topic = $t$โลหะ อโลหะ กึ่งโลหะ$t$ and question = $t$Sb (พลวง) เป็นธาตุประเภทใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โลหะ อโลหะ กึ่งโลหะ$t$, $t$Na (โซเดียม) เป็นธาตุประเภทใด$t$, $t$โลหะ$t$, $t$แก๊สเฉื่อย$t$, $t$กึ่งโลหะ$t$, $t$อโลหะ$t$, 0, $t$Na เป็นโลหะ$t$
where not exists (select 1 from quiz_questions where topic = $t$โลหะ อโลหะ กึ่งโลหะ$t$ and question = $t$Na (โซเดียม) เป็นธาตุประเภทใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โลหะ อโลหะ กึ่งโลหะ$t$, $t$As (สารหนู) เป็นธาตุประเภทใด$t$, $t$อโลหะ$t$, $t$โลหะ$t$, $t$กึ่งโลหะ$t$, $t$แก๊สเฉื่อย$t$, 2, $t$As เป็นกึ่งโลหะ$t$
where not exists (select 1 from quiz_questions where topic = $t$โลหะ อโลหะ กึ่งโลหะ$t$ and question = $t$As (สารหนู) เป็นธาตุประเภทใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โลหะ อโลหะ กึ่งโลหะ$t$, $t$Ca (แคลเซียม) เป็นธาตุประเภทใด$t$, $t$แก๊สเฉื่อย$t$, $t$โลหะ$t$, $t$กึ่งโลหะ$t$, $t$อโลหะ$t$, 1, $t$Ca เป็นโลหะ$t$
where not exists (select 1 from quiz_questions where topic = $t$โลหะ อโลหะ กึ่งโลหะ$t$ and question = $t$Ca (แคลเซียม) เป็นธาตุประเภทใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โลหะ อโลหะ กึ่งโลหะ$t$, $t$F (ฟลูออรีน) เป็นธาตุประเภทใด$t$, $t$โลหะ$t$, $t$แก๊สเฉื่อย$t$, $t$อโลหะ$t$, $t$กึ่งโลหะ$t$, 2, $t$F เป็นอโลหะ$t$
where not exists (select 1 from quiz_questions where topic = $t$โลหะ อโลหะ กึ่งโลหะ$t$ and question = $t$F (ฟลูออรีน) เป็นธาตุประเภทใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โลหะ อโลหะ กึ่งโลหะ$t$, $t$Al (อะลูมิเนียม) เป็นธาตุประเภทใด$t$, $t$โลหะ$t$, $t$กึ่งโลหะ$t$, $t$อโลหะ$t$, $t$แก๊สเฉื่อย$t$, 0, $t$Al เป็นโลหะ$t$
where not exists (select 1 from quiz_questions where topic = $t$โลหะ อโลหะ กึ่งโลหะ$t$ and question = $t$Al (อะลูมิเนียม) เป็นธาตุประเภทใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โลหะ อโลหะ กึ่งโลหะ$t$, $t$C (คาร์บอน) เป็นธาตุประเภทใด$t$, $t$อโลหะ$t$, $t$โลหะ$t$, $t$แก๊สเฉื่อย$t$, $t$กึ่งโลหะ$t$, 0, $t$C เป็นอโลหะ$t$
where not exists (select 1 from quiz_questions where topic = $t$โลหะ อโลหะ กึ่งโลหะ$t$ and question = $t$C (คาร์บอน) เป็นธาตุประเภทใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อนุภาคในอะตอม$t$, $t$¹²C มีนิวตรอนกี่ตัว$t$, $t$5$t$, $t$7$t$, $t$6$t$, $t$4$t$, 2, $t$นิวตรอน = เลขมวล − เลขอะตอม = 12 − 6 = 6$t$
where not exists (select 1 from quiz_questions where topic = $t$อนุภาคในอะตอม$t$ and question = $t$¹²C มีนิวตรอนกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อนุภาคในอะตอม$t$, $t$¹⁴N มีนิวตรอนกี่ตัว$t$, $t$8$t$, $t$6$t$, $t$7$t$, $t$10$t$, 2, $t$นิวตรอน = เลขมวล − เลขอะตอม = 14 − 7 = 7$t$
where not exists (select 1 from quiz_questions where topic = $t$อนุภาคในอะตอม$t$ and question = $t$¹⁴N มีนิวตรอนกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อนุภาคในอะตอม$t$, $t$¹⁶O มีนิวตรอนกี่ตัว$t$, $t$8$t$, $t$7$t$, $t$9$t$, $t$10$t$, 0, $t$นิวตรอน = เลขมวล − เลขอะตอม = 16 − 8 = 8$t$
where not exists (select 1 from quiz_questions where topic = $t$อนุภาคในอะตอม$t$ and question = $t$¹⁶O มีนิวตรอนกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อนุภาคในอะตอม$t$, $t$¹⁹F มีนิวตรอนกี่ตัว$t$, $t$12$t$, $t$8$t$, $t$10$t$, $t$9$t$, 2, $t$นิวตรอน = เลขมวล − เลขอะตอม = 19 − 9 = 10$t$
where not exists (select 1 from quiz_questions where topic = $t$อนุภาคในอะตอม$t$ and question = $t$¹⁹F มีนิวตรอนกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อนุภาคในอะตอม$t$, $t$²³Na มีนิวตรอนกี่ตัว$t$, $t$14$t$, $t$15$t$, $t$10$t$, $t$12$t$, 3, $t$นิวตรอน = เลขมวล − เลขอะตอม = 23 − 11 = 12$t$
where not exists (select 1 from quiz_questions where topic = $t$อนุภาคในอะตอม$t$ and question = $t$²³Na มีนิวตรอนกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อนุภาคในอะตอม$t$, $t$²⁷Al มีนิวตรอนกี่ตัว$t$, $t$16$t$, $t$17$t$, $t$15$t$, $t$14$t$, 3, $t$นิวตรอน = เลขมวล − เลขอะตอม = 27 − 13 = 14$t$
where not exists (select 1 from quiz_questions where topic = $t$อนุภาคในอะตอม$t$ and question = $t$²⁷Al มีนิวตรอนกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อนุภาคในอะตอม$t$, $t$³²S มีนิวตรอนกี่ตัว$t$, $t$16$t$, $t$18$t$, $t$19$t$, $t$17$t$, 0, $t$นิวตรอน = เลขมวล − เลขอะตอม = 32 − 16 = 16$t$
where not exists (select 1 from quiz_questions where topic = $t$อนุภาคในอะตอม$t$ and question = $t$³²S มีนิวตรอนกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อนุภาคในอะตอม$t$, $t$³⁵Cl มีนิวตรอนกี่ตัว$t$, $t$19$t$, $t$17$t$, $t$18$t$, $t$16$t$, 2, $t$นิวตรอน = เลขมวล − เลขอะตอม = 35 − 17 = 18$t$
where not exists (select 1 from quiz_questions where topic = $t$อนุภาคในอะตอม$t$ and question = $t$³⁵Cl มีนิวตรอนกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อนุภาคในอะตอม$t$, $t$⁵⁶Fe มีนิวตรอนกี่ตัว$t$, $t$30$t$, $t$28$t$, $t$31$t$, $t$33$t$, 0, $t$นิวตรอน = เลขมวล − เลขอะตอม = 56 − 26 = 30$t$
where not exists (select 1 from quiz_questions where topic = $t$อนุภาคในอะตอม$t$ and question = $t$⁵⁶Fe มีนิวตรอนกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อนุภาคในอะตอม$t$, $t$¹⁴C มีโปรตอนกี่ตัว$t$, $t$5$t$, $t$7$t$, $t$6$t$, $t$9$t$, 2, $t$โปรตอน = เลขอะตอม = 6$t$
where not exists (select 1 from quiz_questions where topic = $t$อนุภาคในอะตอม$t$ and question = $t$¹⁴C มีโปรตอนกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อนุภาคในอะตอม$t$, $t$⁷Li มีโปรตอนกี่ตัว$t$, $t$5$t$, $t$1$t$, $t$2$t$, $t$3$t$, 3, $t$โปรตอน = เลขอะตอม = 3$t$
where not exists (select 1 from quiz_questions where topic = $t$อนุภาคในอะตอม$t$ and question = $t$⁷Li มีโปรตอนกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อนุภาคในอะตอม$t$, $t$Mg²⁺ มีอิเล็กตรอนกี่ตัว$t$, $t$10$t$, $t$13$t$, $t$9$t$, $t$11$t$, 0, $t$Mg²⁺: อิเล็กตรอน = 12 − (2) = 10$t$
where not exists (select 1 from quiz_questions where topic = $t$อนุภาคในอะตอม$t$ and question = $t$Mg²⁺ มีอิเล็กตรอนกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อนุภาคในอะตอม$t$, $t$Al³⁺ มีอิเล็กตรอนกี่ตัว$t$, $t$11$t$, $t$12$t$, $t$13$t$, $t$10$t$, 3, $t$Al³⁺: อิเล็กตรอน = 13 − (3) = 10$t$
where not exists (select 1 from quiz_questions where topic = $t$อนุภาคในอะตอม$t$ and question = $t$Al³⁺ มีอิเล็กตรอนกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อนุภาคในอะตอม$t$, $t$Ca²⁺ มีอิเล็กตรอนกี่ตัว$t$, $t$17$t$, $t$20$t$, $t$21$t$, $t$18$t$, 3, $t$Ca²⁺: อิเล็กตรอน = 20 − (2) = 18$t$
where not exists (select 1 from quiz_questions where topic = $t$อนุภาคในอะตอม$t$ and question = $t$Ca²⁺ มีอิเล็กตรอนกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อนุภาคในอะตอม$t$, $t$O²⁻ มีอิเล็กตรอนกี่ตัว$t$, $t$8$t$, $t$9$t$, $t$12$t$, $t$10$t$, 3, $t$O²⁻: อิเล็กตรอน = 8 − (-2) = 10$t$
where not exists (select 1 from quiz_questions where topic = $t$อนุภาคในอะตอม$t$ and question = $t$O²⁻ มีอิเล็กตรอนกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อนุภาคในอะตอม$t$, $t$F⁻ มีอิเล็กตรอนกี่ตัว$t$, $t$8$t$, $t$10$t$, $t$12$t$, $t$11$t$, 1, $t$F⁻: อิเล็กตรอน = 9 − (-1) = 10$t$
where not exists (select 1 from quiz_questions where topic = $t$อนุภาคในอะตอม$t$ and question = $t$F⁻ มีอิเล็กตรอนกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อนุภาคในอะตอม$t$, $t$N³⁻ มีอิเล็กตรอนกี่ตัว$t$, $t$8$t$, $t$10$t$, $t$11$t$, $t$13$t$, 1, $t$N³⁻: อิเล็กตรอน = 7 − (-3) = 10$t$
where not exists (select 1 from quiz_questions where topic = $t$อนุภาคในอะตอม$t$ and question = $t$N³⁻ มีอิเล็กตรอนกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อนุภาคในอะตอม$t$, $t$Li⁺ มีอิเล็กตรอนกี่ตัว$t$, $t$4$t$, $t$0$t$, $t$3$t$, $t$2$t$, 3, $t$Li⁺: อิเล็กตรอน = 3 − (1) = 2$t$
where not exists (select 1 from quiz_questions where topic = $t$อนุภาคในอะตอม$t$ and question = $t$Li⁺ มีอิเล็กตรอนกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อนุภาคในอะตอม$t$, $t$โปรตอนมีประจุเท่าใด$t$, $t$+1$t$, $t$−1$t$, $t$+2$t$, $t$0$t$, 0, $t$โปรตอนมีประจุบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$อนุภาคในอะตอม$t$ and question = $t$โปรตอนมีประจุเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อนุภาคในอะตอม$t$, $t$อนุภาคใดอยู่ในนิวเคลียส$t$, $t$โปรตอนและอิเล็กตรอน$t$, $t$อิเล็กตรอนและนิวตรอน$t$, $t$โปรตอนและนิวตรอน$t$, $t$อิเล็กตรอนอย่างเดียว$t$, 2, $t$นิวเคลียส = โปรตอน + นิวตรอน$t$
where not exists (select 1 from quiz_questions where topic = $t$อนุภาคในอะตอม$t$ and question = $t$อนุภาคใดอยู่ในนิวเคลียส$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อนุภาคในอะตอม$t$, $t$อนุภาคใดเคลื่อนที่รอบนิวเคลียส$t$, $t$นิวตรอน$t$, $t$อิเล็กตรอน$t$, $t$นิวคลีออน$t$, $t$โปรตอน$t$, 1, $t$อิเล็กตรอนอยู่นอกนิวเคลียส$t$
where not exists (select 1 from quiz_questions where topic = $t$อนุภาคในอะตอม$t$ and question = $t$อนุภาคใดเคลื่อนที่รอบนิวเคลียส$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อนุภาคในอะตอม$t$, $t$เลขมวลเท่ากับผลรวมของอนุภาคใด$t$, $t$โปรตอน + อิเล็กตรอน$t$, $t$โปรตอน + นิวตรอน$t$, $t$โปรตอนอย่างเดียว$t$, $t$นิวตรอน + อิเล็กตรอน$t$, 1, $t$เลขมวล (A) = p + n$t$
where not exists (select 1 from quiz_questions where topic = $t$อนุภาคในอะตอม$t$ and question = $t$เลขมวลเท่ากับผลรวมของอนุภาคใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อนุภาคในอะตอม$t$, $t$ไอออนบวกเกิดจากอะตอมทำอย่างไร$t$, $t$เสียอิเล็กตรอน$t$, $t$รับอิเล็กตรอน$t$, $t$เสียโปรตอน$t$, $t$รับนิวตรอน$t$, 0, $t$เสีย e⁻ → ประจุบวก$t$
where not exists (select 1 from quiz_questions where topic = $t$อนุภาคในอะตอม$t$ and question = $t$ไอออนบวกเกิดจากอะตอมทำอย่างไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$อนุภาคในอะตอม$t$, $t$มวลส่วนใหญ่ของอะตอมอยู่ที่ใด$t$, $t$ระดับพลังงานนอกสุด$t$, $t$ทั่วอะตอมเท่าๆ กัน$t$, $t$อิเล็กตรอน$t$, $t$นิวเคลียส$t$, 3, $t$นิวเคลียสหนักกว่าอิเล็กตรอนมาก$t$
where not exists (select 1 from quiz_questions where topic = $t$อนุภาคในอะตอม$t$ and question = $t$มวลส่วนใหญ่ของอะตอมอยู่ที่ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การจัดอิเล็กตรอน$t$, $t$Li (เลขอะตอม 3) จัดอิเล็กตรอนเป็น$t$, $t$2$t$, $t$1,2$t$, $t$2,2$t$, $t$2,1$t$, 3, $t$Li: 2,1$t$
where not exists (select 1 from quiz_questions where topic = $t$การจัดอิเล็กตรอน$t$ and question = $t$Li (เลขอะตอม 3) จัดอิเล็กตรอนเป็น$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การจัดอิเล็กตรอน$t$, $t$B (เลขอะตอม 5) จัดอิเล็กตรอนเป็น$t$, $t$1,4$t$, $t$2,3$t$, $t$2,4$t$, $t$2,2$t$, 1, $t$B: 2,3$t$
where not exists (select 1 from quiz_questions where topic = $t$การจัดอิเล็กตรอน$t$ and question = $t$B (เลขอะตอม 5) จัดอิเล็กตรอนเป็น$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การจัดอิเล็กตรอน$t$, $t$C (เลขอะตอม 6) จัดอิเล็กตรอนเป็น$t$, $t$2,3$t$, $t$2,4$t$, $t$2,5$t$, $t$1,5$t$, 1, $t$C: 2,4$t$
where not exists (select 1 from quiz_questions where topic = $t$การจัดอิเล็กตรอน$t$ and question = $t$C (เลขอะตอม 6) จัดอิเล็กตรอนเป็น$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การจัดอิเล็กตรอน$t$, $t$N (เลขอะตอม 7) จัดอิเล็กตรอนเป็น$t$, $t$2,6$t$, $t$2,5$t$, $t$2,4$t$, $t$1,6$t$, 1, $t$N: 2,5$t$
where not exists (select 1 from quiz_questions where topic = $t$การจัดอิเล็กตรอน$t$ and question = $t$N (เลขอะตอม 7) จัดอิเล็กตรอนเป็น$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การจัดอิเล็กตรอน$t$, $t$F (เลขอะตอม 9) จัดอิเล็กตรอนเป็น$t$, $t$2,7$t$, $t$2,6$t$, $t$1,8$t$, $t$2,8$t$, 0, $t$F: 2,7$t$
where not exists (select 1 from quiz_questions where topic = $t$การจัดอิเล็กตรอน$t$ and question = $t$F (เลขอะตอม 9) จัดอิเล็กตรอนเป็น$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การจัดอิเล็กตรอน$t$, $t$Ne (เลขอะตอม 10) จัดอิเล็กตรอนเป็น$t$, $t$2,7$t$, $t$2,8,1$t$, $t$2,8$t$, $t$1,9$t$, 2, $t$Ne: 2,8$t$
where not exists (select 1 from quiz_questions where topic = $t$การจัดอิเล็กตรอน$t$ and question = $t$Ne (เลขอะตอม 10) จัดอิเล็กตรอนเป็น$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การจัดอิเล็กตรอน$t$, $t$Mg (เลขอะตอม 12) จัดอิเล็กตรอนเป็น$t$, $t$2,7,3$t$, $t$2,8,1$t$, $t$2,8,3$t$, $t$2,8,2$t$, 3, $t$Mg: 2,8,2$t$
where not exists (select 1 from quiz_questions where topic = $t$การจัดอิเล็กตรอน$t$ and question = $t$Mg (เลขอะตอม 12) จัดอิเล็กตรอนเป็น$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การจัดอิเล็กตรอน$t$, $t$Si (เลขอะตอม 14) จัดอิเล็กตรอนเป็น$t$, $t$2,7,5$t$, $t$2,8,5$t$, $t$2,8,3$t$, $t$2,8,4$t$, 3, $t$Si: 2,8,4$t$
where not exists (select 1 from quiz_questions where topic = $t$การจัดอิเล็กตรอน$t$ and question = $t$Si (เลขอะตอม 14) จัดอิเล็กตรอนเป็น$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การจัดอิเล็กตรอน$t$, $t$P (เลขอะตอม 15) จัดอิเล็กตรอนเป็น$t$, $t$2,7,6$t$, $t$2,8,4$t$, $t$2,8,5$t$, $t$2,8,6$t$, 2, $t$P: 2,8,5$t$
where not exists (select 1 from quiz_questions where topic = $t$การจัดอิเล็กตรอน$t$ and question = $t$P (เลขอะตอม 15) จัดอิเล็กตรอนเป็น$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การจัดอิเล็กตรอน$t$, $t$Cl (เลขอะตอม 17) จัดอิเล็กตรอนเป็น$t$, $t$2,8,7$t$, $t$2,8,8$t$, $t$2,7,8$t$, $t$2,8,6$t$, 0, $t$Cl: 2,8,7$t$
where not exists (select 1 from quiz_questions where topic = $t$การจัดอิเล็กตรอน$t$ and question = $t$Cl (เลขอะตอม 17) จัดอิเล็กตรอนเป็น$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การจัดอิเล็กตรอน$t$, $t$O มีเวเลนซ์อิเล็กตรอนกี่ตัว$t$, $t$6$t$, $t$8$t$, $t$7$t$, $t$3$t$, 0, $t$O จัด 2,6 → เวเลนซ์ = 6$t$
where not exists (select 1 from quiz_questions where topic = $t$การจัดอิเล็กตรอน$t$ and question = $t$O มีเวเลนซ์อิเล็กตรอนกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การจัดอิเล็กตรอน$t$, $t$F มีเวเลนซ์อิเล็กตรอนกี่ตัว$t$, $t$3$t$, $t$6$t$, $t$7$t$, $t$8$t$, 2, $t$F จัด 2,7 → เวเลนซ์ = 7$t$
where not exists (select 1 from quiz_questions where topic = $t$การจัดอิเล็กตรอน$t$ and question = $t$F มีเวเลนซ์อิเล็กตรอนกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การจัดอิเล็กตรอน$t$, $t$B มีเวเลนซ์อิเล็กตรอนกี่ตัว$t$, $t$4$t$, $t$2$t$, $t$3$t$, $t$7$t$, 2, $t$B จัด 2,3 → เวเลนซ์ = 3$t$
where not exists (select 1 from quiz_questions where topic = $t$การจัดอิเล็กตรอน$t$ and question = $t$B มีเวเลนซ์อิเล็กตรอนกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การจัดอิเล็กตรอน$t$, $t$Mg มีเวเลนซ์อิเล็กตรอนกี่ตัว$t$, $t$2$t$, $t$8$t$, $t$5$t$, $t$1$t$, 0, $t$Mg จัด 2,8,2 → เวเลนซ์ = 2$t$
where not exists (select 1 from quiz_questions where topic = $t$การจัดอิเล็กตรอน$t$ and question = $t$Mg มีเวเลนซ์อิเล็กตรอนกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การจัดอิเล็กตรอน$t$, $t$He มีเวเลนซ์อิเล็กตรอนกี่ตัว$t$, $t$1$t$, $t$2$t$, $t$4$t$, $t$8$t$, 1, $t$He จัด 2 → เวเลนซ์ = 2$t$
where not exists (select 1 from quiz_questions where topic = $t$การจัดอิเล็กตรอน$t$ and question = $t$He มีเวเลนซ์อิเล็กตรอนกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การจัดอิเล็กตรอน$t$, $t$Ar มีเวเลนซ์อิเล็กตรอนกี่ตัว$t$, $t$6$t$, $t$1$t$, $t$3$t$, $t$8$t$, 3, $t$Ar จัด 2,8,8 → เวเลนซ์ = 8$t$
where not exists (select 1 from quiz_questions where topic = $t$การจัดอิเล็กตรอน$t$ and question = $t$Ar มีเวเลนซ์อิเล็กตรอนกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การจัดอิเล็กตรอน$t$, $t$P มีเวเลนซ์อิเล็กตรอนกี่ตัว$t$, $t$7$t$, $t$1$t$, $t$5$t$, $t$2$t$, 2, $t$P จัด 2,8,5 → เวเลนซ์ = 5$t$
where not exists (select 1 from quiz_questions where topic = $t$การจัดอิเล็กตรอน$t$ and question = $t$P มีเวเลนซ์อิเล็กตรอนกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การจัดอิเล็กตรอน$t$, $t$การจัดอิเล็กตรอน 2,8,1 เป็นของธาตุใด$t$, $t$Na$t$, $t$Li$t$, $t$N$t$, $t$Si$t$, 0, $t$2,8,1 คือ Na$t$
where not exists (select 1 from quiz_questions where topic = $t$การจัดอิเล็กตรอน$t$ and question = $t$การจัดอิเล็กตรอน 2,8,1 เป็นของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การจัดอิเล็กตรอน$t$, $t$การจัดอิเล็กตรอน 2,8,8 เป็นของธาตุใด$t$, $t$Ar$t$, $t$Na$t$, $t$Mg$t$, $t$Si$t$, 0, $t$2,8,8 คือ Ar$t$
where not exists (select 1 from quiz_questions where topic = $t$การจัดอิเล็กตรอน$t$ and question = $t$การจัดอิเล็กตรอน 2,8,8 เป็นของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การจัดอิเล็กตรอน$t$, $t$การจัดอิเล็กตรอน 2,1 เป็นของธาตุใด$t$, $t$F$t$, $t$Si$t$, $t$Ar$t$, $t$Li$t$, 3, $t$2,1 คือ Li$t$
where not exists (select 1 from quiz_questions where topic = $t$การจัดอิเล็กตรอน$t$ and question = $t$การจัดอิเล็กตรอน 2,1 เป็นของธาตุใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การจัดอิเล็กตรอน$t$, $t$ระดับพลังงานชั้น K (n=1) บรรจุอิเล็กตรอนได้สูงสุดกี่ตัว$t$, $t$18$t$, $t$32$t$, $t$8$t$, $t$2$t$, 3, $t$2n² = 2$t$
where not exists (select 1 from quiz_questions where topic = $t$การจัดอิเล็กตรอน$t$ and question = $t$ระดับพลังงานชั้น K (n=1) บรรจุอิเล็กตรอนได้สูงสุดกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การจัดอิเล็กตรอน$t$, $t$ระดับพลังงานชั้น L (n=2) บรรจุอิเล็กตรอนได้สูงสุดกี่ตัว$t$, $t$18$t$, $t$8$t$, $t$2$t$, $t$32$t$, 1, $t$2n² = 8$t$
where not exists (select 1 from quiz_questions where topic = $t$การจัดอิเล็กตรอน$t$ and question = $t$ระดับพลังงานชั้น L (n=2) บรรจุอิเล็กตรอนได้สูงสุดกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การจัดอิเล็กตรอน$t$, $t$เวเลนซ์อิเล็กตรอนอยู่ในระดับพลังงานใด$t$, $t$นิวเคลียส$t$, $t$ระดับกลาง$t$, $t$ระดับในสุด$t$, $t$ระดับนอกสุด$t$, 3, $t$ระดับพลังงานนอกสุด$t$
where not exists (select 1 from quiz_questions where topic = $t$การจัดอิเล็กตรอน$t$ and question = $t$เวเลนซ์อิเล็กตรอนอยู่ในระดับพลังงานใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การจัดอิเล็กตรอน$t$, $t$ธาตุเลขอะตอม 11 มีเวเลนซ์อิเล็กตรอนกี่ตัว$t$, $t$2$t$, $t$3$t$, $t$1$t$, $t$11$t$, 2, $t$Na จัด 2,8,1$t$
where not exists (select 1 from quiz_questions where topic = $t$การจัดอิเล็กตรอน$t$ and question = $t$ธาตุเลขอะตอม 11 มีเวเลนซ์อิเล็กตรอนกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ประจุไอออนตามหมู่$t$, $t$ธาตุหมู่ 1 มักเกิดไอออนประจุเท่าใด$t$, $t$+1$t$, $t$+2$t$, $t$−2$t$, $t$+3$t$, 0, $t$หมู่ 1 เสียอิเล็กตรอน 1 ตัว → ประจุ +1$t$
where not exists (select 1 from quiz_questions where topic = $t$ประจุไอออนตามหมู่$t$ and question = $t$ธาตุหมู่ 1 มักเกิดไอออนประจุเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ประจุไอออนตามหมู่$t$, $t$ธาตุหมู่ 2 มักเกิดไอออนประจุเท่าใด$t$, $t$−2$t$, $t$+3$t$, $t$+1$t$, $t$+2$t$, 3, $t$หมู่ 2 เสียอิเล็กตรอน 2 ตัว → ประจุ +2$t$
where not exists (select 1 from quiz_questions where topic = $t$ประจุไอออนตามหมู่$t$ and question = $t$ธาตุหมู่ 2 มักเกิดไอออนประจุเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ประจุไอออนตามหมู่$t$, $t$ธาตุหมู่ 13 มักเกิดไอออนประจุเท่าใด$t$, $t$+2$t$, $t$−2$t$, $t$−1$t$, $t$+3$t$, 3, $t$หมู่ 13 เสียอิเล็กตรอน 3 ตัว → ประจุ +3$t$
where not exists (select 1 from quiz_questions where topic = $t$ประจุไอออนตามหมู่$t$ and question = $t$ธาตุหมู่ 13 มักเกิดไอออนประจุเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ประจุไอออนตามหมู่$t$, $t$ธาตุหมู่ 15 มักเกิดไอออนประจุเท่าใด$t$, $t$+3$t$, $t$−3$t$, $t$−1$t$, $t$+1$t$, 1, $t$หมู่ 15 รับอิเล็กตรอน 3 ตัว → ประจุ −3$t$
where not exists (select 1 from quiz_questions where topic = $t$ประจุไอออนตามหมู่$t$ and question = $t$ธาตุหมู่ 15 มักเกิดไอออนประจุเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ประจุไอออนตามหมู่$t$, $t$ธาตุหมู่ 16 มักเกิดไอออนประจุเท่าใด$t$, $t$−2$t$, $t$+1$t$, $t$−1$t$, $t$+3$t$, 0, $t$หมู่ 16 รับอิเล็กตรอน 2 ตัว → ประจุ −2$t$
where not exists (select 1 from quiz_questions where topic = $t$ประจุไอออนตามหมู่$t$ and question = $t$ธาตุหมู่ 16 มักเกิดไอออนประจุเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ประจุไอออนตามหมู่$t$, $t$ธาตุหมู่ 17 มักเกิดไอออนประจุเท่าใด$t$, $t$+2$t$, $t$+3$t$, $t$−1$t$, $t$+1$t$, 2, $t$หมู่ 17 รับอิเล็กตรอน 1 ตัว → ประจุ −1$t$
where not exists (select 1 from quiz_questions where topic = $t$ประจุไอออนตามหมู่$t$ and question = $t$ธาตุหมู่ 17 มักเกิดไอออนประจุเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ประจุไอออนตามหมู่$t$, $t$ธาตุหมู่ 18 เกิดไอออนได้หรือไม่$t$, $t$ไม่เกิด (เสถียรอยู่แล้ว)$t$, $t$เกิดไอออน +2$t$, $t$เกิดไอออน −1$t$, $t$เกิดไอออน +1$t$, 0, $t$แก๊สเฉื่อยมีเวเลนซ์ครบ$t$
where not exists (select 1 from quiz_questions where topic = $t$ประจุไอออนตามหมู่$t$ and question = $t$ธาตุหมู่ 18 เกิดไอออนได้หรือไม่$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ประจุไอออนตามหมู่$t$, $t$โลหะมักเกิดไอออนชนิดใด$t$, $t$ไอออนลบ$t$, $t$ไอออนบวก$t$, $t$ได้ทั้งบวกและลบเท่ากัน$t$, $t$ไม่เกิดไอออน$t$, 1, $t$โลหะเสียอิเล็กตรอน$t$
where not exists (select 1 from quiz_questions where topic = $t$ประจุไอออนตามหมู่$t$ and question = $t$โลหะมักเกิดไอออนชนิดใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ประจุไอออนตามหมู่$t$, $t$อโลหะมักเกิดไอออนชนิดใด$t$, $t$ไม่เกิดไอออน$t$, $t$ไอออนบวกเสมอ$t$, $t$ไอออนบวก$t$, $t$ไอออนลบ$t$, 3, $t$อโลหะรับอิเล็กตรอน$t$
where not exists (select 1 from quiz_questions where topic = $t$ประจุไอออนตามหมู่$t$ and question = $t$อโลหะมักเกิดไอออนชนิดใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารประกอบไอออนิก$t$, $t$สูตรของสารที่ได้จาก Na⁺ กับ Cl⁻$t$, $t$Na₂Cl$t$, $t$NaCl$t$, $t$Na₃Cl$t$, $t$Na₂Cl₃$t$, 1, $t$NaCl: ประจุรวมเป็นศูนย์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารประกอบไอออนิก$t$ and question = $t$สูตรของสารที่ได้จาก Na⁺ กับ Cl⁻$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารประกอบไอออนิก$t$, $t$สูตรของสารที่ได้จาก Mg²⁺ กับ Cl⁻$t$, $t$MgCl₂$t$, $t$Mg₂Cl₃$t$, $t$Mg₃Cl$t$, $t$MgCl$t$, 0, $t$MgCl₂: ประจุรวมเป็นศูนย์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารประกอบไอออนิก$t$ and question = $t$สูตรของสารที่ได้จาก Mg²⁺ กับ Cl⁻$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารประกอบไอออนิก$t$, $t$สูตรของสารที่ได้จาก Ca²⁺ กับ O²⁻$t$, $t$Ca₂O$t$, $t$Ca₃O$t$, $t$Ca₂O₃$t$, $t$CaO$t$, 3, $t$CaO: ประจุรวมเป็นศูนย์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารประกอบไอออนิก$t$ and question = $t$สูตรของสารที่ได้จาก Ca²⁺ กับ O²⁻$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารประกอบไอออนิก$t$, $t$สูตรของสารที่ได้จาก Al³⁺ กับ O²⁻$t$, $t$Al₂O₃$t$, $t$AlO$t$, $t$Al₃O$t$, $t$Al₂O$t$, 0, $t$Al₂O₃: ประจุรวมเป็นศูนย์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารประกอบไอออนิก$t$ and question = $t$สูตรของสารที่ได้จาก Al³⁺ กับ O²⁻$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารประกอบไอออนิก$t$, $t$สูตรของสารที่ได้จาก Al³⁺ กับ Cl⁻$t$, $t$AlCl$t$, $t$AlCl₃$t$, $t$Al₂Cl₃$t$, $t$Al₃Cl$t$, 1, $t$AlCl₃: ประจุรวมเป็นศูนย์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารประกอบไอออนิก$t$ and question = $t$สูตรของสารที่ได้จาก Al³⁺ กับ Cl⁻$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารประกอบไอออนิก$t$, $t$สูตรของสารที่ได้จาก Mg²⁺ กับ O²⁻$t$, $t$Mg₂O$t$, $t$MgO$t$, $t$Mg₃O$t$, $t$Mg₂O₃$t$, 1, $t$MgO: ประจุรวมเป็นศูนย์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารประกอบไอออนิก$t$ and question = $t$สูตรของสารที่ได้จาก Mg²⁺ กับ O²⁻$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารประกอบไอออนิก$t$, $t$สูตรของสารที่ได้จาก K⁺ กับ S²⁻$t$, $t$KS$t$, $t$K₃S$t$, $t$K₂S₃$t$, $t$K₂S$t$, 3, $t$K₂S: ประจุรวมเป็นศูนย์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารประกอบไอออนิก$t$ and question = $t$สูตรของสารที่ได้จาก K⁺ กับ S²⁻$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารประกอบไอออนิก$t$, $t$สูตรของสารที่ได้จาก Ca²⁺ กับ Cl⁻$t$, $t$CaCl$t$, $t$CaCl₂$t$, $t$Ca₂Cl₃$t$, $t$Ca₃Cl$t$, 1, $t$CaCl₂: ประจุรวมเป็นศูนย์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารประกอบไอออนิก$t$ and question = $t$สูตรของสารที่ได้จาก Ca²⁺ กับ Cl⁻$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารประกอบไอออนิก$t$, $t$สูตรของสารที่ได้จาก Li⁺ กับ F⁻$t$, $t$Li₂F₃$t$, $t$Li₂F$t$, $t$LiF$t$, $t$Li₃F$t$, 2, $t$LiF: ประจุรวมเป็นศูนย์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารประกอบไอออนิก$t$ and question = $t$สูตรของสารที่ได้จาก Li⁺ กับ F⁻$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารประกอบไอออนิก$t$, $t$สูตรของสารที่ได้จาก Al³⁺ กับ S²⁻$t$, $t$Al₃S$t$, $t$AlS$t$, $t$Al₂S₃$t$, $t$Al₂S$t$, 2, $t$Al₂S₃: ประจุรวมเป็นศูนย์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารประกอบไอออนิก$t$ and question = $t$สูตรของสารที่ได้จาก Al³⁺ กับ S²⁻$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารประกอบไอออนิก$t$, $t$สูตรของสารที่ได้จาก Mg²⁺ กับ N³⁻$t$, $t$Mg₂N₃$t$, $t$MgN$t$, $t$Mg₃N₂$t$, $t$Mg₃N$t$, 2, $t$Mg₃N₂: ประจุรวมเป็นศูนย์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารประกอบไอออนิก$t$ and question = $t$สูตรของสารที่ได้จาก Mg²⁺ กับ N³⁻$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารประกอบไอออนิก$t$, $t$สูตรของสารที่ได้จาก Zn²⁺ กับ Cl⁻$t$, $t$Zn₂Cl₃$t$, $t$ZnCl$t$, $t$ZnCl₂$t$, $t$Zn₃Cl$t$, 2, $t$ZnCl₂: ประจุรวมเป็นศูนย์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารประกอบไอออนิก$t$ and question = $t$สูตรของสารที่ได้จาก Zn²⁺ กับ Cl⁻$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารประกอบไอออนิก$t$, $t$สูตรของสารที่ได้จาก Ag⁺ กับ Cl⁻$t$, $t$Ag₂Cl$t$, $t$Ag₂Cl₃$t$, $t$Ag₃Cl$t$, $t$AgCl$t$, 3, $t$AgCl: ประจุรวมเป็นศูนย์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารประกอบไอออนิก$t$ and question = $t$สูตรของสารที่ได้จาก Ag⁺ กับ Cl⁻$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารประกอบไอออนิก$t$, $t$สูตรของสารที่ได้จาก Ca²⁺ กับ OH⁻$t$, $t$Ca(OH)₂$t$, $t$CaOH$t$, $t$CaOH₂$t$, $t$Ca₂OH₃$t$, 0, $t$Ca(OH)₂: ประจุรวมเป็นศูนย์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารประกอบไอออนิก$t$ and question = $t$สูตรของสารที่ได้จาก Ca²⁺ กับ OH⁻$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารประกอบไอออนิก$t$, $t$สูตรของสารที่ได้จาก Na⁺ กับ SO₄²⁻$t$, $t$Na₂SO₄$t$, $t$NaSO₄$t$, $t$Na₂SO₄₃$t$, $t$Na₃SO₄$t$, 0, $t$Na₂SO₄: ประจุรวมเป็นศูนย์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารประกอบไอออนิก$t$ and question = $t$สูตรของสารที่ได้จาก Na⁺ กับ SO₄²⁻$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารประกอบไอออนิก$t$, $t$สูตรของสารที่ได้จาก K⁺ กับ NO₃⁻$t$, $t$KNO₃$t$, $t$K₂NO₃₃$t$, $t$K₂NO₃$t$, $t$K₃NO₃$t$, 0, $t$KNO₃: ประจุรวมเป็นศูนย์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารประกอบไอออนิก$t$ and question = $t$สูตรของสารที่ได้จาก K⁺ กับ NO₃⁻$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารประกอบไอออนิก$t$, $t$สูตรของสารที่ได้จาก Al³⁺ กับ OH⁻$t$, $t$Al(OH)₃$t$, $t$AlOH$t$, $t$AlOH₃$t$, $t$Al₂OH₃$t$, 0, $t$Al(OH)₃: ประจุรวมเป็นศูนย์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารประกอบไอออนิก$t$ and question = $t$สูตรของสารที่ได้จาก Al³⁺ กับ OH⁻$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารประกอบไอออนิก$t$, $t$สูตรของสารที่ได้จาก NH₄⁺ กับ Cl⁻$t$, $t$NH₄₂Cl$t$, $t$NH₄Cl$t$, $t$NH₄₂Cl₃$t$, $t$NH₄₃Cl$t$, 1, $t$NH₄Cl: ประจุรวมเป็นศูนย์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารประกอบไอออนิก$t$ and question = $t$สูตรของสารที่ได้จาก NH₄⁺ กับ Cl⁻$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารประกอบไอออนิก$t$, $t$สูตรของสารที่ได้จาก Al³⁺ กับ SO₄²⁻$t$, $t$Al₂SO₄₃$t$, $t$AlSO₄$t$, $t$Al₂(SO₄)₃$t$, $t$Al₃SO₄$t$, 2, $t$Al₂(SO₄)₃: ประจุรวมเป็นศูนย์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารประกอบไอออนิก$t$ and question = $t$สูตรของสารที่ได้จาก Al³⁺ กับ SO₄²⁻$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารประกอบไอออนิก$t$, $t$สูตรของสารที่ได้จาก Ca²⁺ กับ PO₄³⁻$t$, $t$CaPO₄$t$, $t$Ca₂PO₄₃$t$, $t$Ca₃PO₄₂$t$, $t$Ca₃(PO₄)₂$t$, 3, $t$Ca₃(PO₄)₂: ประจุรวมเป็นศูนย์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารประกอบไอออนิก$t$ and question = $t$สูตรของสารที่ได้จาก Ca²⁺ กับ PO₄³⁻$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารประกอบไอออนิก$t$, $t$สูตรของสารที่ได้จาก Ba²⁺ กับ SO₄²⁻$t$, $t$Ba₂SO₄₃$t$, $t$Ba₂SO₄$t$, $t$BaSO₄$t$, $t$Ba₃SO₄$t$, 2, $t$BaSO₄: ประจุรวมเป็นศูนย์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารประกอบไอออนิก$t$ and question = $t$สูตรของสารที่ได้จาก Ba²⁺ กับ SO₄²⁻$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารประกอบไอออนิก$t$, $t$สูตรของสารที่ได้จาก K⁺ กับ Br⁻$t$, $t$KBr$t$, $t$K₂Br₃$t$, $t$K₂Br$t$, $t$K₃Br$t$, 0, $t$KBr: ประจุรวมเป็นศูนย์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารประกอบไอออนิก$t$ and question = $t$สูตรของสารที่ได้จาก K⁺ กับ Br⁻$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารประกอบไอออนิก$t$, $t$สูตรของสารที่ได้จาก Na⁺ กับ CO₃²⁻$t$, $t$Na₂CO₃₃$t$, $t$Na₂CO₃$t$, $t$NaCO₃$t$, $t$Na₃CO₃$t$, 1, $t$Na₂CO₃: ประจุรวมเป็นศูนย์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารประกอบไอออนิก$t$ and question = $t$สูตรของสารที่ได้จาก Na⁺ กับ CO₃²⁻$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารประกอบไอออนิก$t$, $t$สูตรของสารที่ได้จาก Mg²⁺ กับ OH⁻$t$, $t$Mg₂OH₃$t$, $t$Mg(OH)₂$t$, $t$MgOH$t$, $t$MgOH₂$t$, 1, $t$Mg(OH)₂: ประจุรวมเป็นศูนย์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารประกอบไอออนิก$t$ and question = $t$สูตรของสารที่ได้จาก Mg²⁺ กับ OH⁻$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารเคมีท่องจำ$t$, $t$NaCl คือสารอะไร$t$, $t$เกลือแกง$t$, $t$แอมโมเนียมไนเตรต$t$, $t$โซเดียมไนเตรต$t$, $t$ตะกั่ว(II) ไอโอไดด์$t$, 0, $t$NaCl = เกลือแกง$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารเคมีท่องจำ$t$ and question = $t$NaCl คือสารอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารเคมีท่องจำ$t$, $t$น้ำตาลกลูโคส สูตรอะไร$t$, $t$CH₃COOH$t$, $t$C₆H₁₂O₆$t$, $t$Al(OH)₃$t$, $t$AlCl₃$t$, 1, $t$น้ำตาลกลูโคส = C₆H₁₂O₆$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารเคมีท่องจำ$t$ and question = $t$น้ำตาลกลูโคส สูตรอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารเคมีท่องจำ$t$, $t$C₁₂H₂₂O₁₁ คือสารอะไร$t$, $t$ซิลเวอร์คลอไรด์$t$, $t$คอปเปอร์(II) ซัลเฟต$t$, $t$ไนโตรเจนไดออกไซด์$t$, $t$น้ำตาลทราย (ซูโครส)$t$, 3, $t$C₁₂H₂₂O₁₁ = น้ำตาลทราย (ซูโครส)$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารเคมีท่องจำ$t$ and question = $t$C₁₂H₂₂O₁₁ คือสารอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารเคมีท่องจำ$t$, $t$เอทานอล สูตรอะไร$t$, $t$O₃$t$, $t$C₂H₅OH$t$, $t$N₂O$t$, $t$NaCl$t$, 1, $t$เอทานอล = C₂H₅OH$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารเคมีท่องจำ$t$ and question = $t$เอทานอล สูตรอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารเคมีท่องจำ$t$, $t$CH₃OH คือสารอะไร$t$, $t$ไฮโดรเจนเปอร์ออกไซด์$t$, $t$เอทานอล$t$, $t$โพแทสเซียมไฮดรอกไซด์$t$, $t$เมทานอล$t$, 3, $t$CH₃OH = เมทานอล$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารเคมีท่องจำ$t$ and question = $t$CH₃OH คือสารอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารเคมีท่องจำ$t$, $t$C₃H₈ คือสารอะไร$t$, $t$ไฮโดรเจนเปอร์ออกไซด์$t$, $t$โพรเพน$t$, $t$แคลเซียมซัลเฟต$t$, $t$ซิลเวอร์คลอไรด์$t$, 1, $t$C₃H₈ = โพรเพน$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารเคมีท่องจำ$t$ and question = $t$C₃H₈ คือสารอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารเคมีท่องจำ$t$, $t$เอไทน์ (อะเซทิลีน) สูตรอะไร$t$, $t$FeS$t$, $t$C₂H₂$t$, $t$AgCl$t$, $t$CH₃COOH$t$, 1, $t$เอไทน์ (อะเซทิลีน) = C₂H₂$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารเคมีท่องจำ$t$ and question = $t$เอไทน์ (อะเซทิลีน) สูตรอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารเคมีท่องจำ$t$, $t$AgCl คือสารอะไร$t$, $t$โอโซน$t$, $t$ซิลเวอร์คลอไรด์$t$, $t$บิวเทน$t$, $t$แคลเซียมคาร์ไบด์$t$, 1, $t$AgCl = ซิลเวอร์คลอไรด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารเคมีท่องจำ$t$ and question = $t$AgCl คือสารอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารเคมีท่องจำ$t$, $t$แมกนีเซียมคลอไรด์ สูตรอะไร$t$, $t$C₂H₄$t$, $t$C₃H₈$t$, $t$Cl₂$t$, $t$MgCl₂$t$, 3, $t$แมกนีเซียมคลอไรด์ = MgCl₂$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารเคมีท่องจำ$t$ and question = $t$แมกนีเซียมคลอไรด์ สูตรอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารเคมีท่องจำ$t$, $t$AlCl₃ คือสารอะไร$t$, $t$อะลูมิเนียมคลอไรด์$t$, $t$เอไทน์ (อะเซทิลีน)$t$, $t$กรดแอซีติก$t$, $t$ซิลเวอร์คลอไรด์$t$, 0, $t$AlCl₃ = อะลูมิเนียมคลอไรด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารเคมีท่องจำ$t$ and question = $t$AlCl₃ คือสารอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารเคมีท่องจำ$t$, $t$โซเดียมไนเตรต สูตรอะไร$t$, $t$C₄H₁₀$t$, $t$AgCl$t$, $t$NaNO₃$t$, $t$Ca₃(PO₄)₂$t$, 2, $t$โซเดียมไนเตรต = NaNO₃$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารเคมีท่องจำ$t$ and question = $t$โซเดียมไนเตรต สูตรอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารเคมีท่องจำ$t$, $t$MgSO₄ คือสารอะไร$t$, $t$ไฮโดรเจนเปอร์ออกไซด์$t$, $t$แมกนีเซียมซัลเฟต$t$, $t$โพรเพน$t$, $t$โซเดียมไนเตรต$t$, 1, $t$MgSO₄ = แมกนีเซียมซัลเฟต$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารเคมีท่องจำ$t$ and question = $t$MgSO₄ คือสารอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารเคมีท่องจำ$t$, $t$CuSO₄ คือสารอะไร$t$, $t$คอปเปอร์(II) ซัลเฟต$t$, $t$ซิลเวอร์คลอไรด์$t$, $t$อะลูมิเนียมไฮดรอกไซด์$t$, $t$ไฮโดรเจนเปอร์ออกไซด์$t$, 0, $t$CuSO₄ = คอปเปอร์(II) ซัลเฟต$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารเคมีท่องจำ$t$ and question = $t$CuSO₄ คือสารอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารเคมีท่องจำ$t$, $t$เหล็ก(II) ซัลไฟด์ สูตรอะไร$t$, $t$FeS$t$, $t$C₃H₈$t$, $t$AlCl₃$t$, $t$CaSO₄$t$, 0, $t$เหล็ก(II) ซัลไฟด์ = FeS$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารเคมีท่องจำ$t$ and question = $t$เหล็ก(II) ซัลไฟด์ สูตรอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารเคมีท่องจำ$t$, $t$ตะกั่ว(II) ไอโอไดด์ สูตรอะไร$t$, $t$NaClO$t$, $t$PbI₂$t$, $t$MgCl₂$t$, $t$Ca₃(PO₄)₂$t$, 1, $t$ตะกั่ว(II) ไอโอไดด์ = PbI₂$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารเคมีท่องจำ$t$ and question = $t$ตะกั่ว(II) ไอโอไดด์ สูตรอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารเคมีท่องจำ$t$, $t$NO₂ คือสารอะไร$t$, $t$คอปเปอร์(II) ซัลเฟต$t$, $t$แคลเซียมคาร์ไบด์$t$, $t$ไนโตรเจนไดออกไซด์$t$, $t$แมกนีเซียมคลอไรด์$t$, 2, $t$NO₂ = ไนโตรเจนไดออกไซด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารเคมีท่องจำ$t$ and question = $t$NO₂ คือสารอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารเคมีท่องจำ$t$, $t$ไดไนโตรเจนมอนอกไซด์ สูตรอะไร$t$, $t$N₂O$t$, $t$MgSO₄$t$, $t$NaNO₃$t$, $t$KI$t$, 0, $t$ไดไนโตรเจนมอนอกไซด์ = N₂O$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารเคมีท่องจำ$t$ and question = $t$ไดไนโตรเจนมอนอกไซด์ สูตรอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารเคมีท่องจำ$t$, $t$โอโซน สูตรอะไร$t$, $t$CH₃OH$t$, $t$CH₃COOH$t$, $t$O₃$t$, $t$C₆H₁₂O₆$t$, 2, $t$โอโซน = O₃$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารเคมีท่องจำ$t$ and question = $t$โอโซน สูตรอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารเคมีท่องจำ$t$, $t$H₂O₂ คือสารอะไร$t$, $t$คอปเปอร์(II) ซัลเฟต$t$, $t$ไฮโดรเจนเปอร์ออกไซด์$t$, $t$เอไทน์ (อะเซทิลีน)$t$, $t$เหล็ก(II) ซัลไฟด์$t$, 1, $t$H₂O₂ = ไฮโดรเจนเปอร์ออกไซด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารเคมีท่องจำ$t$ and question = $t$H₂O₂ คือสารอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารเคมีท่องจำ$t$, $t$แอมโมเนียมไนเตรต สูตรอะไร$t$, $t$CuSO₄$t$, $t$C₃H₈$t$, $t$CH₃COOH$t$, $t$NH₄NO₃$t$, 3, $t$แอมโมเนียมไนเตรต = NH₄NO₃$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารเคมีท่องจำ$t$ and question = $t$แอมโมเนียมไนเตรต สูตรอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารเคมีท่องจำ$t$, $t$แคลเซียมฟอสเฟต สูตรอะไร$t$, $t$HF$t$, $t$H₂O$t$, $t$C₂H₅OH$t$, $t$Ca₃(PO₄)₂$t$, 3, $t$แคลเซียมฟอสเฟต = Ca₃(PO₄)₂$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารเคมีท่องจำ$t$ and question = $t$แคลเซียมฟอสเฟต สูตรอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารเคมีท่องจำ$t$, $t$Al(OH)₃ คือสารอะไร$t$, $t$อะลูมิเนียมไฮดรอกไซด์$t$, $t$น้ำ$t$, $t$โซเดียมไนเตรต$t$, $t$คลอรีนแก๊ส$t$, 0, $t$Al(OH)₃ = อะลูมิเนียมไฮดรอกไซด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารเคมีท่องจำ$t$ and question = $t$Al(OH)₃ คือสารอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารเคมีท่องจำ$t$, $t$โซเดียมซัลไฟด์ สูตรอะไร$t$, $t$NH₄NO₃$t$, $t$Na₂S$t$, $t$C₁₂H₂₂O₁₁$t$, $t$CH₃OH$t$, 1, $t$โซเดียมซัลไฟด์ = Na₂S$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารเคมีท่องจำ$t$ and question = $t$โซเดียมซัลไฟด์ สูตรอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารเคมีท่องจำ$t$, $t$CCl₄ คือสารอะไร$t$, $t$น้ำ$t$, $t$คาร์บอนเตตระคลอไรด์$t$, $t$แมกนีเซียมไนไตรด์$t$, $t$เมทานอล$t$, 1, $t$CCl₄ = คาร์บอนเตตระคลอไรด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารเคมีท่องจำ$t$ and question = $t$CCl₄ คือสารอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สูตรสารเคมีท่องจำ$t$, $t$CaC₂ คือสารอะไร$t$, $t$ซิลเวอร์คลอไรด์$t$, $t$แคลเซียมคาร์ไบด์$t$, $t$ไดไนโตรเจนมอนอกไซด์$t$, $t$แมกนีเซียมซัลเฟต$t$, 1, $t$CaC₂ = แคลเซียมคาร์ไบด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สูตรสารเคมีท่องจำ$t$ and question = $t$CaC₂ คือสารอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ชื่อสามัญของสาร$t$, $t$เกลือแกง คือสารใด$t$, $t$CH₄$t$, $t$HCl$t$, $t$NaCl$t$, $t$KMnO₄$t$, 2, $t$เกลือแกง = โซเดียมคลอไรด์ (NaCl)$t$
where not exists (select 1 from quiz_questions where topic = $t$ชื่อสามัญของสาร$t$ and question = $t$เกลือแกง คือสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ชื่อสามัญของสาร$t$, $t$ด่างทับทิม คือสารใด$t$, $t$KMnO₄$t$, $t$SiO₂$t$, $t$CaSO₄·2H₂O$t$, $t$CH₃COOH$t$, 0, $t$ด่างทับทิม = โพแทสเซียมเปอร์แมงกาเนต (KMnO₄)$t$
where not exists (select 1 from quiz_questions where topic = $t$ชื่อสามัญของสาร$t$ and question = $t$ด่างทับทิม คือสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ชื่อสามัญของสาร$t$, $t$โซดาไฟ คือสารใด$t$, $t$SiO₂$t$, $t$CaCO₃$t$, $t$(NH₂)₂CO$t$, $t$NaOH$t$, 3, $t$โซดาไฟ = โซเดียมไฮดรอกไซด์ (NaOH)$t$
where not exists (select 1 from quiz_questions where topic = $t$ชื่อสามัญของสาร$t$ and question = $t$โซดาไฟ คือสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ชื่อสามัญของสาร$t$, $t$ปูนเผา (ปูนไม่ดับ) คือสารใด$t$, $t$CH₃COOH$t$, $t$NaHCO₃$t$, $t$(NH₂)₂CO$t$, $t$CaO$t$, 3, $t$ปูนเผา (ปูนไม่ดับ) = แคลเซียมออกไซด์ (CaO)$t$
where not exists (select 1 from quiz_questions where topic = $t$ชื่อสามัญของสาร$t$ and question = $t$ปูนเผา (ปูนไม่ดับ) คือสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ชื่อสามัญของสาร$t$, $t$หินปูน คือสารใด$t$, $t$NaHCO₃$t$, $t$CaCO₃$t$, $t$N₂O$t$, $t$(NH₂)₂CO$t$, 1, $t$หินปูน = แคลเซียมคาร์บอเนต (CaCO₃)$t$
where not exists (select 1 from quiz_questions where topic = $t$ชื่อสามัญของสาร$t$ and question = $t$หินปูน คือสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ชื่อสามัญของสาร$t$, $t$ดินประสิว คือสารใด$t$, $t$KNO₃$t$, $t$N₂O$t$, $t$C₂H₅OH$t$, $t$NaClO$t$, 0, $t$ดินประสิว = โพแทสเซียมไนเตรต (KNO₃)$t$
where not exists (select 1 from quiz_questions where topic = $t$ชื่อสามัญของสาร$t$ and question = $t$ดินประสิว คือสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ชื่อสามัญของสาร$t$, $t$น้ำแข็งแห้ง คือสารใด$t$, $t$NaOH$t$, $t$CO₂$t$, $t$CH₄$t$, $t$NaHCO₃$t$, 1, $t$น้ำแข็งแห้ง = คาร์บอนไดออกไซด์ (ของแข็ง) (CO₂)$t$
where not exists (select 1 from quiz_questions where topic = $t$ชื่อสามัญของสาร$t$ and question = $t$น้ำแข็งแห้ง คือสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ชื่อสามัญของสาร$t$, $t$เบกกิ้งโซดา คือสารใด$t$, $t$Fe₂O₃$t$, $t$NaHCO₃$t$, $t$HCl$t$, $t$CH₄$t$, 1, $t$เบกกิ้งโซดา = โซเดียมไฮโดรเจนคาร์บอเนต (NaHCO₃)$t$
where not exists (select 1 from quiz_questions where topic = $t$ชื่อสามัญของสาร$t$ and question = $t$เบกกิ้งโซดา คือสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ชื่อสามัญของสาร$t$, $t$สารส้ม คือสารใด$t$, $t$CaSO₄·2H₂O$t$, $t$KAl(SO₄)₂·12H₂O$t$, $t$Fe₂O₃$t$, $t$Na₂CO₃$t$, 1, $t$สารส้ม = โพแทสเซียมอะลูมิเนียมซัลเฟต (KAl(SO₄)₂·12H₂O)$t$
where not exists (select 1 from quiz_questions where topic = $t$ชื่อสามัญของสาร$t$ and question = $t$สารส้ม คือสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ชื่อสามัญของสาร$t$, $t$ยิปซัม คือสารใด$t$, $t$KMnO₄$t$, $t$(NH₂)₂CO$t$, $t$CaSO₄·2H₂O$t$, $t$CH₃COOH$t$, 2, $t$ยิปซัม = แคลเซียมซัลเฟตไดไฮเดรต (CaSO₄·2H₂O)$t$
where not exists (select 1 from quiz_questions where topic = $t$ชื่อสามัญของสาร$t$ and question = $t$ยิปซัม คือสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ชื่อสามัญของสาร$t$, $t$กรดเกลือ คือสารใด$t$, $t$KAl(SO₄)₂·12H₂O$t$, $t$HCl$t$, $t$CaCO₃$t$, $t$C₂H₅OH$t$, 1, $t$กรดเกลือ = กรดไฮโดรคลอริก (HCl)$t$
where not exists (select 1 from quiz_questions where topic = $t$ชื่อสามัญของสาร$t$ and question = $t$กรดเกลือ คือสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ชื่อสามัญของสาร$t$, $t$น้ำกรด (กรดแบตเตอรี่) คือสารใด$t$, $t$H₂SO₄$t$, $t$N₂O$t$, $t$NaClO$t$, $t$KMnO₄$t$, 0, $t$น้ำกรด (กรดแบตเตอรี่) = กรดซัลฟิวริก (H₂SO₄)$t$
where not exists (select 1 from quiz_questions where topic = $t$ชื่อสามัญของสาร$t$ and question = $t$น้ำกรด (กรดแบตเตอรี่) คือสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ชื่อสามัญของสาร$t$, $t$แอลกอฮอล์ล้างแผล คือสารใด$t$, $t$CuSO₄·5H₂O$t$, $t$KMnO₄$t$, $t$HCl$t$, $t$C₂H₅OH$t$, 3, $t$แอลกอฮอล์ล้างแผล = เอทานอล (C₂H₅OH)$t$
where not exists (select 1 from quiz_questions where topic = $t$ชื่อสามัญของสาร$t$ and question = $t$แอลกอฮอล์ล้างแผล คือสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ชื่อสามัญของสาร$t$, $t$น้ำส้มสายชู คือสารใด$t$, $t$C₂H₅OH$t$, $t$CH₃COOH$t$, $t$KMnO₄$t$, $t$H₂SO₄$t$, 1, $t$น้ำส้มสายชู = กรดแอซีติก (CH₃COOH)$t$
where not exists (select 1 from quiz_questions where topic = $t$ชื่อสามัญของสาร$t$ and question = $t$น้ำส้มสายชู คือสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ชื่อสามัญของสาร$t$, $t$แก๊สหัวเราะ คือสารใด$t$, $t$CH₄$t$, $t$KNO₃$t$, $t$NaClO$t$, $t$N₂O$t$, 3, $t$แก๊สหัวเราะ = ไดไนโตรเจนมอนอกไซด์ (N₂O)$t$
where not exists (select 1 from quiz_questions where topic = $t$ชื่อสามัญของสาร$t$ and question = $t$แก๊สหัวเราะ คือสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ชื่อสามัญของสาร$t$, $t$สาร CH₄ มีชื่อสามัญว่า$t$, $t$แก๊สธรรมชาติ (หลัก)$t$, $t$ดินประสิว$t$, $t$หินปูน$t$, $t$ด่างทับทิม$t$, 0, $t$CH₄ = แก๊สธรรมชาติ (หลัก)$t$
where not exists (select 1 from quiz_questions where topic = $t$ชื่อสามัญของสาร$t$ and question = $t$สาร CH₄ มีชื่อสามัญว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ชื่อสามัญของสาร$t$, $t$สาร Fe₂O₃ มีชื่อสามัญว่า$t$, $t$ปูนขาว$t$, $t$น้ำปูนใส$t$, $t$แก๊สหัวเราะ$t$, $t$สนิมเหล็ก$t$, 3, $t$Fe₂O₃ = สนิมเหล็ก$t$
where not exists (select 1 from quiz_questions where topic = $t$ชื่อสามัญของสาร$t$ and question = $t$สาร Fe₂O₃ มีชื่อสามัญว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ชื่อสามัญของสาร$t$, $t$สาร SiO₂ มีชื่อสามัญว่า$t$, $t$ทราย (หลัก)$t$, $t$สนิมเหล็ก$t$, $t$โซดาซักผ้า$t$, $t$แอลกอฮอล์ล้างแผล$t$, 0, $t$SiO₂ = ทราย (หลัก)$t$
where not exists (select 1 from quiz_questions where topic = $t$ชื่อสามัญของสาร$t$ and question = $t$สาร SiO₂ มีชื่อสามัญว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ชื่อสามัญของสาร$t$, $t$สาร NaClO มีชื่อสามัญว่า$t$, $t$ดินประสิว$t$, $t$ด่างทับทิม$t$, $t$ตัวฟอกขาว (ไฮเตอร์)$t$, $t$สนิมเหล็ก$t$, 2, $t$NaClO = ตัวฟอกขาว (ไฮเตอร์)$t$
where not exists (select 1 from quiz_questions where topic = $t$ชื่อสามัญของสาร$t$ and question = $t$สาร NaClO มีชื่อสามัญว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ชื่อสามัญของสาร$t$, $t$สาร (NH₂)₂CO มีชื่อสามัญว่า$t$, $t$เกลือแกง$t$, $t$โซดาไฟ$t$, $t$น้ำส้มสายชู$t$, $t$ยูเรีย$t$, 3, $t$(NH₂)₂CO = ยูเรีย$t$
where not exists (select 1 from quiz_questions where topic = $t$ชื่อสามัญของสาร$t$ and question = $t$สาร (NH₂)₂CO มีชื่อสามัญว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ชื่อสามัญของสาร$t$, $t$สาร Ca(OH)₂ มีชื่อสามัญว่า$t$, $t$ตัวฟอกขาว (ไฮเตอร์)$t$, $t$ยูเรีย$t$, $t$น้ำปูนใส$t$, $t$ยิปซัม$t$, 2, $t$Ca(OH)₂ = น้ำปูนใส$t$
where not exists (select 1 from quiz_questions where topic = $t$ชื่อสามัญของสาร$t$ and question = $t$สาร Ca(OH)₂ มีชื่อสามัญว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ชื่อสามัญของสาร$t$, $t$สาร NaCl มีชื่อสามัญว่า$t$, $t$แอลกอฮอล์ล้างแผล$t$, $t$ด่างทับทิม$t$, $t$ปูนขาว$t$, $t$เกลือแกง$t$, 3, $t$NaCl = เกลือแกง$t$
where not exists (select 1 from quiz_questions where topic = $t$ชื่อสามัญของสาร$t$ and question = $t$สาร NaCl มีชื่อสามัญว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ชื่อสามัญของสาร$t$, $t$สาร NaOH มีชื่อสามัญว่า$t$, $t$ตัวฟอกขาว (ไฮเตอร์)$t$, $t$โซดาไฟ$t$, $t$เกลือแกง$t$, $t$ดินประสิว$t$, 1, $t$NaOH = โซดาไฟ$t$
where not exists (select 1 from quiz_questions where topic = $t$ชื่อสามัญของสาร$t$ and question = $t$สาร NaOH มีชื่อสามัญว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ชื่อสามัญของสาร$t$, $t$สาร CaO มีชื่อสามัญว่า$t$, $t$ยูเรีย$t$, $t$ปูนเผา (ปูนไม่ดับ)$t$, $t$กรดเกลือ$t$, $t$สนิมเหล็ก$t$, 1, $t$CaO = ปูนเผา (ปูนไม่ดับ)$t$
where not exists (select 1 from quiz_questions where topic = $t$ชื่อสามัญของสาร$t$ and question = $t$สาร CaO มีชื่อสามัญว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ชื่อสามัญของสาร$t$, $t$สาร CaCO₃ มีชื่อสามัญว่า$t$, $t$หินปูน$t$, $t$น้ำแข็งแห้ง$t$, $t$แก๊สหัวเราะ$t$, $t$แอลกอฮอล์ล้างแผล$t$, 0, $t$CaCO₃ = หินปูน$t$
where not exists (select 1 from quiz_questions where topic = $t$ชื่อสามัญของสาร$t$ and question = $t$สาร CaCO₃ มีชื่อสามัญว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$มวลโมเลกุลคำนวณไว$t$, $t$มวลโมเลกุลของ O₂ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$, $t$32$t$, $t$22$t$, $t$28$t$, $t$30$t$, 0, $t$ออกซิเจน O₂ = 32$t$
where not exists (select 1 from quiz_questions where topic = $t$มวลโมเลกุลคำนวณไว$t$ and question = $t$มวลโมเลกุลของ O₂ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$มวลโมเลกุลคำนวณไว$t$, $t$มวลโมเลกุลของ N₂ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$, $t$44$t$, $t$28$t$, $t$38$t$, $t$24$t$, 1, $t$ไนโตรเจน N₂ = 28$t$
where not exists (select 1 from quiz_questions where topic = $t$มวลโมเลกุลคำนวณไว$t$ and question = $t$มวลโมเลกุลของ N₂ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$มวลโมเลกุลคำนวณไว$t$, $t$มวลโมเลกุลของ Cl₂ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$, $t$79$t$, $t$71$t$, $t$87$t$, $t$67$t$, 1, $t$คลอรีน Cl₂ = 71$t$
where not exists (select 1 from quiz_questions where topic = $t$มวลโมเลกุลคำนวณไว$t$ and question = $t$มวลโมเลกุลของ Cl₂ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$มวลโมเลกุลคำนวณไว$t$, $t$มวลโมเลกุลของ CO₂ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$, $t$52$t$, $t$44$t$, $t$42$t$, $t$48$t$, 1, $t$คาร์บอนไดออกไซด์ CO₂ = 44$t$
where not exists (select 1 from quiz_questions where topic = $t$มวลโมเลกุลคำนวณไว$t$ and question = $t$มวลโมเลกุลของ CO₂ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$มวลโมเลกุลคำนวณไว$t$, $t$มวลโมเลกุลของ NH₃ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$, $t$25$t$, $t$17$t$, $t$7$t$, $t$21$t$, 1, $t$แอมโมเนีย NH₃ = 17$t$
where not exists (select 1 from quiz_questions where topic = $t$มวลโมเลกุลคำนวณไว$t$ and question = $t$มวลโมเลกุลของ NH₃ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$มวลโมเลกุลคำนวณไว$t$, $t$มวลโมเลกุลของ CH₄ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$, $t$16$t$, $t$6$t$, $t$32$t$, $t$18$t$, 0, $t$มีเทน CH₄ = 16$t$
where not exists (select 1 from quiz_questions where topic = $t$มวลโมเลกุลคำนวณไว$t$ and question = $t$มวลโมเลกุลของ CH₄ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$มวลโมเลกุลคำนวณไว$t$, $t$มวลโมเลกุลของ KOH (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$, $t$58$t$, $t$72$t$, $t$56$t$, $t$52$t$, 2, $t$โพแทสเซียมไฮดรอกไซด์ KOH = 56$t$
where not exists (select 1 from quiz_questions where topic = $t$มวลโมเลกุลคำนวณไว$t$ and question = $t$มวลโมเลกุลของ KOH (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$มวลโมเลกุลคำนวณไว$t$, $t$มวลโมเลกุลของ CaO (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$, $t$56$t$, $t$64$t$, $t$60$t$, $t$72$t$, 0, $t$แคลเซียมออกไซด์ CaO = 56$t$
where not exists (select 1 from quiz_questions where topic = $t$มวลโมเลกุลคำนวณไว$t$ and question = $t$มวลโมเลกุลของ CaO (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$มวลโมเลกุลคำนวณไว$t$, $t$มวลโมเลกุลของ CaCO₃ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$, $t$100$t$, $t$110$t$, $t$90$t$, $t$98$t$, 0, $t$แคลเซียมคาร์บอเนต CaCO₃ = 100$t$
where not exists (select 1 from quiz_questions where topic = $t$มวลโมเลกุลคำนวณไว$t$ and question = $t$มวลโมเลกุลของ CaCO₃ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$มวลโมเลกุลคำนวณไว$t$, $t$มวลโมเลกุลของ MgO (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$, $t$36$t$, $t$38$t$, $t$48$t$, $t$40$t$, 3, $t$แมกนีเซียมออกไซด์ MgO = 40$t$
where not exists (select 1 from quiz_questions where topic = $t$มวลโมเลกุลคำนวณไว$t$ and question = $t$มวลโมเลกุลของ MgO (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$มวลโมเลกุลคำนวณไว$t$, $t$มวลโมเลกุลของ H₂SO₄ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$, $t$88$t$, $t$114$t$, $t$102$t$, $t$98$t$, 3, $t$กรดซัลฟิวริก H₂SO₄ = 98$t$
where not exists (select 1 from quiz_questions where topic = $t$มวลโมเลกุลคำนวณไว$t$ and question = $t$มวลโมเลกุลของ H₂SO₄ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$มวลโมเลกุลคำนวณไว$t$, $t$มวลโมเลกุลของ HNO₃ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$, $t$59$t$, $t$65$t$, $t$67$t$, $t$63$t$, 3, $t$กรดไนตริก HNO₃ = 63$t$
where not exists (select 1 from quiz_questions where topic = $t$มวลโมเลกุลคำนวณไว$t$ and question = $t$มวลโมเลกุลของ HNO₃ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$มวลโมเลกุลคำนวณไว$t$, $t$มวลโมเลกุลของ H₃PO₄ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$, $t$98$t$, $t$100$t$, $t$102$t$, $t$106$t$, 0, $t$กรดฟอสฟอริก H₃PO₄ = 98$t$
where not exists (select 1 from quiz_questions where topic = $t$มวลโมเลกุลคำนวณไว$t$ and question = $t$มวลโมเลกุลของ H₃PO₄ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$มวลโมเลกุลคำนวณไว$t$, $t$มวลโมเลกุลของ Ca(OH)₂ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$, $t$82$t$, $t$74$t$, $t$70$t$, $t$78$t$, 1, $t$แคลเซียมไฮดรอกไซด์ Ca(OH)₂ = 74$t$
where not exists (select 1 from quiz_questions where topic = $t$มวลโมเลกุลคำนวณไว$t$ and question = $t$มวลโมเลกุลของ Ca(OH)₂ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$มวลโมเลกุลคำนวณไว$t$, $t$มวลโมเลกุลของ Na₂CO₃ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$, $t$106$t$, $t$114$t$, $t$110$t$, $t$102$t$, 0, $t$โซเดียมคาร์บอเนต Na₂CO₃ = 106$t$
where not exists (select 1 from quiz_questions where topic = $t$มวลโมเลกุลคำนวณไว$t$ and question = $t$มวลโมเลกุลของ Na₂CO₃ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$มวลโมเลกุลคำนวณไว$t$, $t$มวลโมเลกุลของ Al₂O₃ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$, $t$102$t$, $t$104$t$, $t$118$t$, $t$100$t$, 0, $t$อะลูมิเนียมออกไซด์ Al₂O₃ = 102$t$
where not exists (select 1 from quiz_questions where topic = $t$มวลโมเลกุลคำนวณไว$t$ and question = $t$มวลโมเลกุลของ Al₂O₃ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$มวลโมเลกุลคำนวณไว$t$, $t$มวลโมเลกุลของ C₂H₅OH (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$, $t$54$t$, $t$46$t$, $t$50$t$, $t$36$t$, 1, $t$เอทานอล C₂H₅OH = 46$t$
where not exists (select 1 from quiz_questions where topic = $t$มวลโมเลกุลคำนวณไว$t$ and question = $t$มวลโมเลกุลของ C₂H₅OH (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$มวลโมเลกุลคำนวณไว$t$, $t$มวลโมเลกุลของ CH₃COOH (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$, $t$70$t$, $t$56$t$, $t$60$t$, $t$50$t$, 2, $t$กรดแอซีติก CH₃COOH = 60$t$
where not exists (select 1 from quiz_questions where topic = $t$มวลโมเลกุลคำนวณไว$t$ and question = $t$มวลโมเลกุลของ CH₃COOH (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$มวลโมเลกุลคำนวณไว$t$, $t$มวลโมเลกุลของ SO₂ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$, $t$54$t$, $t$64$t$, $t$68$t$, $t$72$t$, 1, $t$ซัลเฟอร์ไดออกไซด์ SO₂ = 64$t$
where not exists (select 1 from quiz_questions where topic = $t$มวลโมเลกุลคำนวณไว$t$ and question = $t$มวลโมเลกุลของ SO₂ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$มวลโมเลกุลคำนวณไว$t$, $t$มวลโมเลกุลของ SO₃ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$, $t$80$t$, $t$82$t$, $t$84$t$, $t$78$t$, 0, $t$ซัลเฟอร์ไตรออกไซด์ SO₃ = 80$t$
where not exists (select 1 from quiz_questions where topic = $t$มวลโมเลกุลคำนวณไว$t$ and question = $t$มวลโมเลกุลของ SO₃ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$มวลโมเลกุลคำนวณไว$t$, $t$มวลโมเลกุลของ CaCl₂ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$, $t$121$t$, $t$111$t$, $t$109$t$, $t$127$t$, 1, $t$แคลเซียมคลอไรด์ CaCl₂ = 111$t$
where not exists (select 1 from quiz_questions where topic = $t$มวลโมเลกุลคำนวณไว$t$ and question = $t$มวลโมเลกุลของ CaCl₂ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$มวลโมเลกุลคำนวณไว$t$, $t$มวลโมเลกุลของ KMnO₄ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$, $t$158$t$, $t$168$t$, $t$166$t$, $t$174$t$, 0, $t$โพแทสเซียมเปอร์แมงกาเนต KMnO₄ = 158$t$
where not exists (select 1 from quiz_questions where topic = $t$มวลโมเลกุลคำนวณไว$t$ and question = $t$มวลโมเลกุลของ KMnO₄ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$มวลโมเลกุลคำนวณไว$t$, $t$มวลโมเลกุลของ Na₂SO₄ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$, $t$142$t$, $t$132$t$, $t$138$t$, $t$152$t$, 0, $t$โซเดียมซัลเฟต Na₂SO₄ = 142$t$
where not exists (select 1 from quiz_questions where topic = $t$มวลโมเลกุลคำนวณไว$t$ and question = $t$มวลโมเลกุลของ Na₂SO₄ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$มวลโมเลกุลคำนวณไว$t$, $t$มวลโมเลกุลของ BaSO₄ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$, $t$237$t$, $t$233$t$, $t$229$t$, $t$223$t$, 1, $t$แบเรียมซัลเฟต BaSO₄ = 233$t$
where not exists (select 1 from quiz_questions where topic = $t$มวลโมเลกุลคำนวณไว$t$ and question = $t$มวลโมเลกุลของ BaSO₄ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$มวลโมเลกุลคำนวณไว$t$, $t$มวลโมเลกุลของ C₁₂H₂₂O₁₁ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$, $t$346$t$, $t$342$t$, $t$358$t$, $t$352$t$, 1, $t$ซูโครส C₁₂H₂₂O₁₁ = 342$t$
where not exists (select 1 from quiz_questions where topic = $t$มวลโมเลกุลคำนวณไว$t$ and question = $t$มวลโมเลกุลของ C₁₂H₂₂O₁₁ (ตัวเลขมวลอะตอมปกติ) เท่ากับ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและค่าคงที่$t$, $t$H₂O หนัก 36 กรัม เท่ากับกี่โมล$t$, $t$4 โมล$t$, $t$8 โมล$t$, $t$1 โมล$t$, $t$2 โมล$t$, 3, $t$โมล = มวล ÷ Mr = 36 ÷ 18 = 2$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและค่าคงที่$t$ and question = $t$H₂O หนัก 36 กรัม เท่ากับกี่โมล$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและค่าคงที่$t$, $t$H₂O หนัก 9 กรัม เท่ากับกี่โมล$t$, $t$1 โมล$t$, $t$0.25 โมล$t$, $t$2 โมล$t$, $t$0.5 โมล$t$, 3, $t$โมล = มวล ÷ Mr = 9 ÷ 18 = 0.5$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและค่าคงที่$t$ and question = $t$H₂O หนัก 9 กรัม เท่ากับกี่โมล$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและค่าคงที่$t$, $t$CO₂ หนัก 88 กรัม เท่ากับกี่โมล$t$, $t$2 โมล$t$, $t$1 โมล$t$, $t$8 โมล$t$, $t$4 โมล$t$, 0, $t$โมล = มวล ÷ Mr = 88 ÷ 44 = 2$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและค่าคงที่$t$ and question = $t$CO₂ หนัก 88 กรัม เท่ากับกี่โมล$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและค่าคงที่$t$, $t$CO₂ หนัก 22 กรัม เท่ากับกี่โมล$t$, $t$2 โมล$t$, $t$0.25 โมล$t$, $t$0.5 โมล$t$, $t$1 โมล$t$, 2, $t$โมล = มวล ÷ Mr = 22 ÷ 44 = 0.5$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและค่าคงที่$t$ and question = $t$CO₂ หนัก 22 กรัม เท่ากับกี่โมล$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและค่าคงที่$t$, $t$NaCl หนัก 117 กรัม เท่ากับกี่โมล$t$, $t$4 โมล$t$, $t$2 โมล$t$, $t$1 โมล$t$, $t$8 โมล$t$, 1, $t$โมล = มวล ÷ Mr = 117 ÷ 58.5 = 2$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและค่าคงที่$t$ and question = $t$NaCl หนัก 117 กรัม เท่ากับกี่โมล$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและค่าคงที่$t$, $t$NaCl หนัก 29.25 กรัม เท่ากับกี่โมล$t$, $t$0.5 โมล$t$, $t$0.25 โมล$t$, $t$1 โมล$t$, $t$2 โมล$t$, 0, $t$โมล = มวล ÷ Mr = 29.25 ÷ 58.5 = 0.5$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและค่าคงที่$t$ and question = $t$NaCl หนัก 29.25 กรัม เท่ากับกี่โมล$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและค่าคงที่$t$, $t$O₂ หนัก 64 กรัม เท่ากับกี่โมล$t$, $t$8 โมล$t$, $t$4 โมล$t$, $t$1 โมล$t$, $t$2 โมล$t$, 3, $t$โมล = มวล ÷ Mr = 64 ÷ 32 = 2$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและค่าคงที่$t$ and question = $t$O₂ หนัก 64 กรัม เท่ากับกี่โมล$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและค่าคงที่$t$, $t$H₂ หนัก 4 กรัม เท่ากับกี่โมล$t$, $t$8 โมล$t$, $t$1 โมล$t$, $t$4 โมล$t$, $t$2 โมล$t$, 3, $t$โมล = มวล ÷ Mr = 4 ÷ 2 = 2$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและค่าคงที่$t$ and question = $t$H₂ หนัก 4 กรัม เท่ากับกี่โมล$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและค่าคงที่$t$, $t$N₂ หนัก 56 กรัม เท่ากับกี่โมล$t$, $t$8 โมล$t$, $t$4 โมล$t$, $t$2 โมล$t$, $t$1 โมล$t$, 2, $t$โมล = มวล ÷ Mr = 56 ÷ 28 = 2$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและค่าคงที่$t$ and question = $t$N₂ หนัก 56 กรัม เท่ากับกี่โมล$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและค่าคงที่$t$, $t$CH₄ หนัก 32 กรัม เท่ากับกี่โมล$t$, $t$8 โมล$t$, $t$4 โมล$t$, $t$1 โมล$t$, $t$2 โมล$t$, 3, $t$โมล = มวล ÷ Mr = 32 ÷ 16 = 2$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและค่าคงที่$t$ and question = $t$CH₄ หนัก 32 กรัม เท่ากับกี่โมล$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและค่าคงที่$t$, $t$CaCO₃ หนัก 200 กรัม เท่ากับกี่โมล$t$, $t$2 โมล$t$, $t$4 โมล$t$, $t$8 โมล$t$, $t$1 โมล$t$, 0, $t$โมล = มวล ÷ Mr = 200 ÷ 100 = 2$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและค่าคงที่$t$ and question = $t$CaCO₃ หนัก 200 กรัม เท่ากับกี่โมล$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและค่าคงที่$t$, $t$NaOH หนัก 20 กรัม เท่ากับกี่โมล$t$, $t$2 โมล$t$, $t$0.5 โมล$t$, $t$0.25 โมล$t$, $t$1 โมล$t$, 1, $t$โมล = มวล ÷ Mr = 20 ÷ 40 = 0.5$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและค่าคงที่$t$ and question = $t$NaOH หนัก 20 กรัม เท่ากับกี่โมล$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและค่าคงที่$t$, $t$NaOH หนัก 80 กรัม เท่ากับกี่โมล$t$, $t$2 โมล$t$, $t$8 โมล$t$, $t$4 โมล$t$, $t$1 โมล$t$, 0, $t$โมล = มวล ÷ Mr = 80 ÷ 40 = 2$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและค่าคงที่$t$ and question = $t$NaOH หนัก 80 กรัม เท่ากับกี่โมล$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและค่าคงที่$t$, $t$NH₃ หนัก 34 กรัม เท่ากับกี่โมล$t$, $t$1 โมล$t$, $t$4 โมล$t$, $t$2 โมล$t$, $t$8 โมล$t$, 2, $t$โมล = มวล ÷ Mr = 34 ÷ 17 = 2$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและค่าคงที่$t$ and question = $t$NH₃ หนัก 34 กรัม เท่ากับกี่โมล$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและค่าคงที่$t$, $t$HCl หนัก 73 กรัม เท่ากับกี่โมล$t$, $t$8 โมล$t$, $t$1 โมล$t$, $t$2 โมล$t$, $t$4 โมล$t$, 2, $t$โมล = มวล ÷ Mr = 73 ÷ 36.5 = 2$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและค่าคงที่$t$ and question = $t$HCl หนัก 73 กรัม เท่ากับกี่โมล$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและค่าคงที่$t$, $t$H₂SO₄ หนัก 49 กรัม เท่ากับกี่โมล$t$, $t$0.25 โมล$t$, $t$1 โมล$t$, $t$2 โมล$t$, $t$0.5 โมล$t$, 3, $t$โมล = มวล ÷ Mr = 49 ÷ 98 = 0.5$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและค่าคงที่$t$ and question = $t$H₂SO₄ หนัก 49 กรัม เท่ากับกี่โมล$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและค่าคงที่$t$, $t$Mg หนัก 12 กรัม เท่ากับกี่โมล$t$, $t$1 โมล$t$, $t$0.25 โมล$t$, $t$2 โมล$t$, $t$0.5 โมล$t$, 3, $t$โมล = มวล ÷ Mr = 12 ÷ 24 = 0.5$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและค่าคงที่$t$ and question = $t$Mg หนัก 12 กรัม เท่ากับกี่โมล$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและค่าคงที่$t$, $t$แก๊สใดๆ 1 โมล ที่ STP มีปริมาตรกี่ dm³$t$, $t$24 dm³$t$, $t$44.8 dm³$t$, $t$22.4 dm³$t$, $t$11.2 dm³$t$, 2, $t$V = n × 22.4 = 22.4 dm³$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและค่าคงที่$t$ and question = $t$แก๊สใดๆ 1 โมล ที่ STP มีปริมาตรกี่ dm³$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและค่าคงที่$t$, $t$แก๊สใดๆ 3 โมล ที่ STP มีปริมาตรกี่ dm³$t$, $t$33.6 dm³$t$, $t$134.4 dm³$t$, $t$67.2 dm³$t$, $t$72 dm³$t$, 2, $t$V = n × 22.4 = 67.2 dm³$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและค่าคงที่$t$ and question = $t$แก๊สใดๆ 3 โมล ที่ STP มีปริมาตรกี่ dm³$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและค่าคงที่$t$, $t$แก๊สใดๆ 0.25 โมล ที่ STP มีปริมาตรกี่ dm³$t$, $t$11.2 dm³$t$, $t$6 dm³$t$, $t$2.8 dm³$t$, $t$5.6 dm³$t$, 3, $t$V = n × 22.4 = 5.6 dm³$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและค่าคงที่$t$ and question = $t$แก๊สใดๆ 0.25 โมล ที่ STP มีปริมาตรกี่ dm³$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและค่าคงที่$t$, $t$สาร 0.5 โมล มีกี่อนุภาค$t$, $t$6.02 × 10²³$t$, $t$6.02 × 10²¹$t$, $t$3.01 × 10²³$t$, $t$3.01 × 10²⁴$t$, 2, $t$จำนวนอนุภาค = n × 6.02 × 10²³ = 3.01 × 10²³$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและค่าคงที่$t$ and question = $t$สาร 0.5 โมล มีกี่อนุภาค$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและค่าคงที่$t$, $t$สาร 3 โมล มีกี่อนุภาค$t$, $t$6.02 × 10²³$t$, $t$1.806 × 10²⁴$t$, $t$3.01 × 10²⁴$t$, $t$6.02 × 10²⁴$t$, 1, $t$จำนวนอนุภาค = n × 6.02 × 10²³ = 1.806 × 10²⁴$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและค่าคงที่$t$ and question = $t$สาร 3 โมล มีกี่อนุภาค$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและค่าคงที่$t$, $t$จำนวนอนุภาคใน 1 โมลคือ$t$, $t$1.0 × 10²³$t$, $t$3.01 × 10²³$t$, $t$6.02 × 10²³$t$, $t$6.02 × 10²²$t$, 2, $t$เลขอาโวกาโดร$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและค่าคงที่$t$ and question = $t$จำนวนอนุภาคใน 1 โมลคือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและค่าคงที่$t$, $t$โมล = มวล ÷ อะไร$t$, $t$มวลโมเลกุล (มวลโมลาร์)$t$, $t$ปริมาตร$t$, $t$จำนวนอนุภาค$t$, $t$ความหนาแน่น$t$, 0, $t$n = m ÷ M$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและค่าคงที่$t$ and question = $t$โมล = มวล ÷ อะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$โมลและค่าคงที่$t$, $t$ความเข้มข้นโมลาร์ (M) มีหน่วยเป็น$t$, $t$โมลต่อลิตร (mol/dm³)$t$, $t$โมลต่อกิโลกรัม$t$, $t$ร้อยละ$t$, $t$กรัมต่อลิตร$t$, 0, $t$M = mol ÷ V (dm³)$t$
where not exists (select 1 from quiz_questions where topic = $t$โมลและค่าคงที่$t$ and question = $t$ความเข้มข้นโมลาร์ (M) มีหน่วยเป็น$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส และ pH$t$, $t$pH เท่ากับ 7 แสดงว่า$t$, $t$เป็นเบส$t$, $t$เป็นกรดแก่$t$, $t$เป็นกลาง$t$, $t$เป็นกรด$t$, 2, $t$pH 7 กลาง (ที่ 25 °C)$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส และ pH$t$ and question = $t$pH เท่ากับ 7 แสดงว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส และ pH$t$, $t$pH มากกว่า 7 แสดงว่า$t$, $t$เป็นกลาง$t$, $t$เป็นเบส$t$, $t$เป็นกรดอ่อน$t$, $t$เป็นกรด$t$, 1, $t$pH > 7 เบส$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส และ pH$t$ and question = $t$pH มากกว่า 7 แสดงว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส และ pH$t$, $t$pH ของน้ำบริสุทธิ์ที่ 25 °C คือ$t$, $t$1$t$, $t$7$t$, $t$14$t$, $t$0$t$, 1, $t$กลาง$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส และ pH$t$ and question = $t$pH ของน้ำบริสุทธิ์ที่ 25 °C คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส และ pH$t$, $t$pH 1 เป็นกรดแรงกว่า pH 4 กี่เท่า (ความเข้มข้น H⁺)$t$, $t$1,000 เท่า$t$, $t$10 เท่า$t$, $t$3 เท่า$t$, $t$100 เท่า$t$, 0, $t$ต่างกัน 3 หน่วย = 10³$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส และ pH$t$ and question = $t$pH 1 เป็นกรดแรงกว่า pH 4 กี่เท่า (ความเข้มข้น H⁺)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส และ pH$t$, $t$pH ที่ลดลง 1 หน่วย [H⁺] เปลี่ยนไปอย่างไร$t$, $t$ลดลง 10 เท่า$t$, $t$เท่าเดิม$t$, $t$เพิ่มขึ้น 2 เท่า$t$, $t$เพิ่มขึ้น 10 เท่า$t$, 3, $t$pH = −log[H⁺]$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส และ pH$t$ and question = $t$pH ที่ลดลง 1 หน่วย [H⁺] เปลี่ยนไปอย่างไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส และ pH$t$, $t$[H⁺] = 1 × 10⁻³ M มี pH เท่าใด$t$, $t$7$t$, $t$−3$t$, $t$11$t$, $t$3$t$, 3, $t$pH = −log 10⁻³ = 3$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส และ pH$t$ and question = $t$[H⁺] = 1 × 10⁻³ M มี pH เท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส และ pH$t$, $t$[H⁺] = 1 × 10⁻⁹ M มี pH เท่าใด$t$, $t$−9$t$, $t$7$t$, $t$9$t$, $t$5$t$, 2, $t$pH = 9 เป็นเบส$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส และ pH$t$ and question = $t$[H⁺] = 1 × 10⁻⁹ M มี pH เท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส และ pH$t$, $t$กรดแก่ในข้อใด$t$, $t$HCl$t$, $t$CH₃COOH$t$, $t$H₂CO₃$t$, $t$NH₃$t$, 0, $t$HCl แตกตัวสมบูรณ์$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส และ pH$t$ and question = $t$กรดแก่ในข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส และ pH$t$, $t$กรดอ่อนในข้อใด$t$, $t$CH₃COOH$t$, $t$H₂SO₄$t$, $t$HCl$t$, $t$HNO₃$t$, 0, $t$กรดแอซีติกแตกตัวบางส่วน$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส และ pH$t$ and question = $t$กรดอ่อนในข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส และ pH$t$, $t$เบสอ่อนในข้อใด$t$, $t$HCl$t$, $t$NH₃$t$, $t$KOH$t$, $t$NaOH$t$, 1, $t$แอมโมเนียเป็นเบสอ่อน$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส และ pH$t$ and question = $t$เบสอ่อนในข้อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส และ pH$t$, $t$กรดตามแนวคิดอาร์เรเนียสให้อะไรในน้ำ$t$, $t$H⁺ (H₃O⁺)$t$, $t$e⁻$t$, $t$Na⁺$t$, $t$OH⁻$t$, 0, $t$อาร์เรเนียส: กรดให้ H⁺$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส และ pH$t$ and question = $t$กรดตามแนวคิดอาร์เรเนียสให้อะไรในน้ำ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส และ pH$t$, $t$เบสตามแนวคิดอาร์เรเนียสให้อะไรในน้ำ$t$, $t$H⁺$t$, $t$Cl⁻$t$, $t$OH⁻$t$, $t$e⁻$t$, 2, $t$อาร์เรเนียส: เบสให้ OH⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส และ pH$t$ and question = $t$เบสตามแนวคิดอาร์เรเนียสให้อะไรในน้ำ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส และ pH$t$, $t$กรดตามแนวคิดเบรินสเตด-ลาวรีคือ$t$, $t$ตัวรับอิเล็กตรอน$t$, $t$ตัวให้โปรตอน$t$, $t$ตัวให้อิเล็กตรอน$t$, $t$ตัวรับโปรตอน$t$, 1, $t$BL: กรดให้ H⁺$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส และ pH$t$ and question = $t$กรดตามแนวคิดเบรินสเตด-ลาวรีคือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส และ pH$t$, $t$เบสตามแนวคิดเบรินสเตด-ลาวรีคือ$t$, $t$ตัวรับโปรตอน$t$, $t$ตัวให้โปรตอน$t$, $t$ตัวรับอิเล็กตรอน$t$, $t$ตัวให้อิเล็กตรอน$t$, 0, $t$BL: เบสรับ H⁺$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส และ pH$t$ and question = $t$เบสตามแนวคิดเบรินสเตด-ลาวรีคือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส และ pH$t$, $t$น้ำมะนาวมี pH ประมาณเท่าใด$t$, $t$7$t$, $t$2$t$, $t$10$t$, $t$13$t$, 1, $t$เป็นกรดซิตริก$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส และ pH$t$ and question = $t$น้ำมะนาวมี pH ประมาณเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส และ pH$t$, $t$น้ำส้มสายชูเป็นสารประเภทใด$t$, $t$กรด$t$, $t$เกลือ$t$, $t$กลาง$t$, $t$เบส$t$, 0, $t$กรดแอซีติก$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส และ pH$t$ and question = $t$น้ำส้มสายชูเป็นสารประเภทใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส และ pH$t$, $t$น้ำสบู่มีสมบัติเป็น$t$, $t$เบสอ่อน$t$, $t$กรดอ่อน$t$, $t$กลาง$t$, $t$กรดแก่$t$, 0, $t$pH ประมาณ 9-10$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส และ pH$t$ and question = $t$น้ำสบู่มีสมบัติเป็น$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส และ pH$t$, $t$ยาลดกรด (เช่น Al(OH)₃) มีสมบัติเป็น$t$, $t$เกลือกรด$t$, $t$เบส$t$, $t$กลาง$t$, $t$กรด$t$, 1, $t$ใช้ทำปฏิกิริยากับกรดในกระเพาะ$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส และ pH$t$ and question = $t$ยาลดกรด (เช่น Al(OH)₃) มีสมบัติเป็น$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส และ pH$t$, $t$น้ำฝนที่เป็นฝนกรดมี pH ต่ำกว่า$t$, $t$5.6$t$, $t$7$t$, $t$10$t$, $t$8.5$t$, 0, $t$น้ำฝนปกติ pH ≈ 5.6$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส และ pH$t$ and question = $t$น้ำฝนที่เป็นฝนกรดมี pH ต่ำกว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส และ pH$t$, $t$น้ำอัดลมมีสมบัติเป็น$t$, $t$เบสอ่อน$t$, $t$กรดอ่อน$t$, $t$เบสแก่$t$, $t$กลาง$t$, 1, $t$มี H₂CO₃$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส และ pH$t$ and question = $t$น้ำอัดลมมีสมบัติเป็น$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส และ pH$t$, $t$เลือดคนปกติมี pH ประมาณ$t$, $t$10$t$, $t$5$t$, $t$7.4$t$, $t$1.5$t$, 2, $t$เบสอ่อนเล็กน้อย$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส และ pH$t$ and question = $t$เลือดคนปกติมี pH ประมาณ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส และ pH$t$, $t$น้ำยาล้างห้องน้ำ (กรดเกลือ) มีสมบัติเป็น$t$, $t$กรดแรง$t$, $t$เบสอ่อน$t$, $t$กลาง$t$, $t$เบสแรง$t$, 0, $t$HCl เจือจาง$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส และ pH$t$ and question = $t$น้ำยาล้างห้องน้ำ (กรดเกลือ) มีสมบัติเป็น$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส และ pH$t$, $t$น้ำยาล้างท่อ (โซดาไฟ) มีสมบัติเป็น$t$, $t$กรดแรง$t$, $t$กรดอ่อน$t$, $t$กลาง$t$, $t$เบสแรง$t$, 3, $t$NaOH$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส และ pH$t$ and question = $t$น้ำยาล้างท่อ (โซดาไฟ) มีสมบัติเป็น$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส และ pH$t$, $t$น้ำกระเพาะอาหารมี pH ประมาณ$t$, $t$12$t$, $t$9$t$, $t$1-2$t$, $t$7$t$, 2, $t$มี HCl$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส และ pH$t$ and question = $t$น้ำกระเพาะอาหารมี pH ประมาณ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$กรด-เบส และ pH$t$, $t$ยาสีฟันส่วนใหญ่มีสมบัติเป็น$t$, $t$เบสอ่อน$t$, $t$เบสแก่$t$, $t$กรดอ่อน$t$, $t$กรดแก่$t$, 0, $t$ช่วยลดกรดในช่องปาก$t$
where not exists (select 1 from quiz_questions where topic = $t$กรด-เบส และ pH$t$ and question = $t$ยาสีฟันส่วนใหญ่มีสมบัติเป็น$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สีอินดิเคเตอร์$t$, $t$ลิตมัสสีน้ำเงิน ในสารละลายกรด จะเป็นสีใด$t$, $t$สีเขียว$t$, $t$สีแดง$t$, $t$สีเหลือง$t$, $t$ไม่มีสี$t$, 1, $t$ลิตมัสสีน้ำเงิน: กรด → สีแดง$t$
where not exists (select 1 from quiz_questions where topic = $t$สีอินดิเคเตอร์$t$ and question = $t$ลิตมัสสีน้ำเงิน ในสารละลายกรด จะเป็นสีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สีอินดิเคเตอร์$t$, $t$ลิตมัสสีแดง ในสารละลายเบส จะเป็นสีใด$t$, $t$สีม่วง$t$, $t$ไม่มีสี$t$, $t$สีน้ำเงิน$t$, $t$สีเหลือง$t$, 2, $t$ลิตมัสสีแดง: เบส → สีน้ำเงิน$t$
where not exists (select 1 from quiz_questions where topic = $t$สีอินดิเคเตอร์$t$ and question = $t$ลิตมัสสีแดง ในสารละลายเบส จะเป็นสีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สีอินดิเคเตอร์$t$, $t$ฟีนอล์ฟทาลีน ในสารละลายเบส จะเป็นสีใด$t$, $t$สีแดง$t$, $t$สีชมพู$t$, $t$สีน้ำเงิน$t$, $t$สีเหลือง$t$, 1, $t$ฟีนอล์ฟทาลีน: เบส → สีชมพู$t$
where not exists (select 1 from quiz_questions where topic = $t$สีอินดิเคเตอร์$t$ and question = $t$ฟีนอล์ฟทาลีน ในสารละลายเบส จะเป็นสีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สีอินดิเคเตอร์$t$, $t$ฟีนอล์ฟทาลีน ในสารละลายกรด จะเป็นสีใด$t$, $t$สีน้ำเงิน$t$, $t$สีเหลือง$t$, $t$สีชมพู$t$, $t$ไม่มีสี$t$, 3, $t$ฟีนอล์ฟทาลีน: กรด → ไม่มีสี$t$
where not exists (select 1 from quiz_questions where topic = $t$สีอินดิเคเตอร์$t$ and question = $t$ฟีนอล์ฟทาลีน ในสารละลายกรด จะเป็นสีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สีอินดิเคเตอร์$t$, $t$BTB (โบรมไทมอลบลู) ในสารละลายกรด จะเป็นสีใด$t$, $t$สีแดง$t$, $t$ไม่มีสี$t$, $t$สีเหลือง$t$, $t$สีน้ำเงิน$t$, 2, $t$BTB (โบรมไทมอลบลู): กรด → สีเหลือง$t$
where not exists (select 1 from quiz_questions where topic = $t$สีอินดิเคเตอร์$t$ and question = $t$BTB (โบรมไทมอลบลู) ในสารละลายกรด จะเป็นสีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สีอินดิเคเตอร์$t$, $t$BTB (โบรมไทมอลบลู) ในสารละลายเบส จะเป็นสีใด$t$, $t$สีแดง$t$, $t$สีน้ำเงิน$t$, $t$ไม่มีสี$t$, $t$สีเหลือง$t$, 1, $t$BTB (โบรมไทมอลบลู): เบส → สีน้ำเงิน$t$
where not exists (select 1 from quiz_questions where topic = $t$สีอินดิเคเตอร์$t$ and question = $t$BTB (โบรมไทมอลบลู) ในสารละลายเบส จะเป็นสีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สีอินดิเคเตอร์$t$, $t$BTB (โบรมไทมอลบลู) ในสารละลายกลาง จะเป็นสีใด$t$, $t$สีแดง$t$, $t$สีเหลือง$t$, $t$สีเขียว$t$, $t$ไม่มีสี$t$, 2, $t$BTB (โบรมไทมอลบลู): สารละลายกลาง → สีเขียว$t$
where not exists (select 1 from quiz_questions where topic = $t$สีอินดิเคเตอร์$t$ and question = $t$BTB (โบรมไทมอลบลู) ในสารละลายกลาง จะเป็นสีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สีอินดิเคเตอร์$t$, $t$เมทิลออเรนจ์ ในสารละลายกรด จะเป็นสีใด$t$, $t$สีน้ำเงิน$t$, $t$ไม่มีสี$t$, $t$สีเหลือง$t$, $t$สีแดง$t$, 3, $t$เมทิลออเรนจ์: กรด → สีแดง$t$
where not exists (select 1 from quiz_questions where topic = $t$สีอินดิเคเตอร์$t$ and question = $t$เมทิลออเรนจ์ ในสารละลายกรด จะเป็นสีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สีอินดิเคเตอร์$t$, $t$เมทิลออเรนจ์ ในสารละลายเบส จะเป็นสีใด$t$, $t$สีแดง$t$, $t$สีเหลือง$t$, $t$สีน้ำเงิน$t$, $t$ไม่มีสี$t$, 1, $t$เมทิลออเรนจ์: เบส → สีเหลือง$t$
where not exists (select 1 from quiz_questions where topic = $t$สีอินดิเคเตอร์$t$ and question = $t$เมทิลออเรนจ์ ในสารละลายเบส จะเป็นสีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สีอินดิเคเตอร์$t$, $t$น้ำคั้นกะหล่ำปลีม่วง ในสารละลายกรด จะเป็นสีใด$t$, $t$สีเหลือง$t$, $t$สีเขียว$t$, $t$สีแดง-ชมพู$t$, $t$ไม่มีสี$t$, 2, $t$น้ำคั้นกะหล่ำปลีม่วง: กรด → สีแดง-ชมพู$t$
where not exists (select 1 from quiz_questions where topic = $t$สีอินดิเคเตอร์$t$ and question = $t$น้ำคั้นกะหล่ำปลีม่วง ในสารละลายกรด จะเป็นสีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สีอินดิเคเตอร์$t$, $t$น้ำคั้นกะหล่ำปลีม่วง ในสารละลายเบส จะเป็นสีใด$t$, $t$สีเขียว-เหลือง$t$, $t$สีชมพู$t$, $t$ไม่มีสี$t$, $t$สีแดง$t$, 0, $t$น้ำคั้นกะหล่ำปลีม่วง: เบส → สีเขียว-เหลือง$t$
where not exists (select 1 from quiz_questions where topic = $t$สีอินดิเคเตอร์$t$ and question = $t$น้ำคั้นกะหล่ำปลีม่วง ในสารละลายเบส จะเป็นสีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สีอินดิเคเตอร์$t$, $t$ขมิ้นชัน ในสารละลายเบส จะเป็นสีใด$t$, $t$สีเหลืองเข้มขึ้น$t$, $t$สีแดงอมน้ำตาล$t$, $t$ไม่มีสี$t$, $t$สีเขียว$t$, 1, $t$ขมิ้นชัน: เบส → สีแดงอมน้ำตาล$t$
where not exists (select 1 from quiz_questions where topic = $t$สีอินดิเคเตอร์$t$ and question = $t$ขมิ้นชัน ในสารละลายเบส จะเป็นสีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สีอินดิเคเตอร์$t$, $t$กระดาษ pH (ยูนิเวอร์แซลอินดิเคเตอร์) ใช้ทำอะไร$t$, $t$วัดมวลสาร$t$, $t$แยกสาร$t$, $t$บอกค่า pH โดยประมาณจากสี$t$, $t$วัดอุณหภูมิ$t$, 2, $t$เทียบสีกับแถบมาตรฐาน$t$
where not exists (select 1 from quiz_questions where topic = $t$สีอินดิเคเตอร์$t$ and question = $t$กระดาษ pH (ยูนิเวอร์แซลอินดิเคเตอร์) ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สีอินดิเคเตอร์$t$, $t$pH meter ใช้ทำอะไร$t$, $t$ชั่งมวล$t$, $t$วัดความหนาแน่น$t$, $t$วัดปริมาตร$t$, $t$วัดค่า pH ได้ละเอียดกว่ากระดาษ$t$, 3, $t$อ่านค่าเป็นตัวเลข$t$
where not exists (select 1 from quiz_questions where topic = $t$สีอินดิเคเตอร์$t$ and question = $t$pH meter ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สีอินดิเคเตอร์$t$, $t$ไทเทรตกรด-เบสใช้อุปกรณ์หลักใด$t$, $t$กรวยแยก$t$, $t$บิวเรตและขวดรูปชมพู่$t$, $t$จานระเหย$t$, $t$กระบอกตวงและบีกเกอร์$t$, 1, $t$บิวเรตหยดสารละลายมาตรฐาน$t$
where not exists (select 1 from quiz_questions where topic = $t$สีอินดิเคเตอร์$t$ and question = $t$ไทเทรตกรด-เบสใช้อุปกรณ์หลักใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สีอินดิเคเตอร์$t$, $t$จุดยุติ (end point) ของการไทเทรตสังเกตจากอะไร$t$, $t$มีตะกอนเสมอ$t$, $t$อุณหภูมิลด$t$, $t$มวลเพิ่ม$t$, $t$สีอินดิเคเตอร์เปลี่ยน$t$, 3, $t$สีเปลี่ยนแสดงว่าเกือบสมดุลแล้ว$t$
where not exists (select 1 from quiz_questions where topic = $t$สีอินดิเคเตอร์$t$ and question = $t$จุดยุติ (end point) ของการไทเทรตสังเกตจากอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ปฏิกิริยากรด-เบส$t$, $t$HCl + NaOH ให้ผลิตภัณฑ์ใด$t$, $t$NaClO + H₂$t$, $t$NaCl + H₂O$t$, $t$NaH + HClO$t$, $t$Na₂O + HCl$t$, 1, $t$HCl + NaOH → NaCl + H₂O$t$
where not exists (select 1 from quiz_questions where topic = $t$ปฏิกิริยากรด-เบส$t$ and question = $t$HCl + NaOH ให้ผลิตภัณฑ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ปฏิกิริยากรด-เบส$t$, $t$H₂SO₄ + 2NaOH ให้ผลิตภัณฑ์ใด$t$, $t$NaHSO₄ + NaOH$t$, $t$NaSO₄ + H₂O$t$, $t$Na₂S + H₂O$t$, $t$Na₂SO₄ + 2H₂O$t$, 3, $t$H₂SO₄ + 2NaOH → Na₂SO₄ + 2H₂O$t$
where not exists (select 1 from quiz_questions where topic = $t$ปฏิกิริยากรด-เบส$t$ and question = $t$H₂SO₄ + 2NaOH ให้ผลิตภัณฑ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ปฏิกิริยากรด-เบส$t$, $t$HNO₃ + KOH ให้ผลิตภัณฑ์ใด$t$, $t$K₂O + HNO$t$, $t$KNO + H₂O₂$t$, $t$KN + H₂O₃$t$, $t$KNO₃ + H₂O$t$, 3, $t$HNO₃ + KOH → KNO₃ + H₂O$t$
where not exists (select 1 from quiz_questions where topic = $t$ปฏิกิริยากรด-เบส$t$ and question = $t$HNO₃ + KOH ให้ผลิตภัณฑ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ปฏิกิริยากรด-เบส$t$, $t$2HCl + Ca(OH)₂ ให้ผลิตภัณฑ์ใด$t$, $t$CaCl₂ + 2H₂O$t$, $t$CaCl + H₂O$t$, $t$Ca + 2HClO$t$, $t$CaO + 2HCl$t$, 0, $t$2HCl + Ca(OH)₂ → CaCl₂ + 2H₂O$t$
where not exists (select 1 from quiz_questions where topic = $t$ปฏิกิริยากรด-เบส$t$ and question = $t$2HCl + Ca(OH)₂ ให้ผลิตภัณฑ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ปฏิกิริยากรด-เบส$t$, $t$HCl + NaHCO₃ ให้ผลิตภัณฑ์ใด$t$, $t$NaClO + H₂O$t$, $t$NaOH + CO$t$, $t$NaCl + H₂$t$, $t$NaCl + H₂O + CO₂$t$, 3, $t$HCl + NaHCO₃ → NaCl + H₂O + CO₂$t$
where not exists (select 1 from quiz_questions where topic = $t$ปฏิกิริยากรด-เบส$t$ and question = $t$HCl + NaHCO₃ ให้ผลิตภัณฑ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ปฏิกิริยากรด-เบส$t$, $t$2HCl + Mg ให้ผลิตภัณฑ์ใด$t$, $t$MgCl + H$t$, $t$MgO + HCl$t$, $t$MgCl₂ + H₂$t$, $t$Mg(OH)₂ + Cl₂$t$, 2, $t$2HCl + Mg → MgCl₂ + H₂$t$
where not exists (select 1 from quiz_questions where topic = $t$ปฏิกิริยากรด-เบส$t$ and question = $t$2HCl + Mg ให้ผลิตภัณฑ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ปฏิกิริยากรด-เบส$t$, $t$2HCl + CaCO₃ ให้ผลิตภัณฑ์ใด$t$, $t$Ca(OH)₂ + CO$t$, $t$CaCl₂ + H₂O + CO₂$t$, $t$CaO + Cl₂$t$, $t$CaCl₂ + H₂$t$, 1, $t$2HCl + CaCO₃ → CaCl₂ + H₂O + CO₂$t$
where not exists (select 1 from quiz_questions where topic = $t$ปฏิกิริยากรด-เบส$t$ and question = $t$2HCl + CaCO₃ ให้ผลิตภัณฑ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ปฏิกิริยากรด-เบส$t$, $t$2HCl + Zn ให้ผลิตภัณฑ์ใด$t$, $t$ZnCl + H$t$, $t$ZnCl₂ + H₂$t$, $t$ZnO + HCl$t$, $t$Zn(OH)₂ + Cl₂$t$, 1, $t$2HCl + Zn → ZnCl₂ + H₂$t$
where not exists (select 1 from quiz_questions where topic = $t$ปฏิกิริยากรด-เบส$t$ and question = $t$2HCl + Zn ให้ผลิตภัณฑ์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ปฏิกิริยากรด-เบส$t$, $t$กรด + เบส → ผลิตภัณฑ์คือ$t$, $t$เกลือ + น้ำ$t$, $t$แก๊สเฉื่อย$t$, $t$เบสใหม่ + กรดใหม่$t$, $t$เกลือ + แก๊สไฮโดรเจน$t$, 0, $t$ปฏิกิริยาสะเทิน$t$
where not exists (select 1 from quiz_questions where topic = $t$ปฏิกิริยากรด-เบส$t$ and question = $t$กรด + เบส → ผลิตภัณฑ์คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ปฏิกิริยากรด-เบส$t$, $t$กรด + โลหะที่ว่องไว → ผลิตภัณฑ์คือ$t$, $t$เกลือ + แก๊สไฮโดรเจน$t$, $t$เกลือ + น้ำ$t$, $t$เกลือ + ออกซิเจน$t$, $t$เบส + น้ำ$t$, 0, $t$H₂ เกิดขึ้น (ฟองแก๊ส)$t$
where not exists (select 1 from quiz_questions where topic = $t$ปฏิกิริยากรด-เบส$t$ and question = $t$กรด + โลหะที่ว่องไว → ผลิตภัณฑ์คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ปฏิกิริยากรด-เบส$t$, $t$กรด + คาร์บอเนต → ผลิตภัณฑ์คือ$t$, $t$เกลือ + H₂$t$, $t$เกลือ + น้ำ + CO₂$t$, $t$เกลือ + O₂$t$, $t$เบส + CO$t$, 1, $t$เกิดฟองแก๊ส CO₂$t$
where not exists (select 1 from quiz_questions where topic = $t$ปฏิกิริยากรด-เบส$t$ and question = $t$กรด + คาร์บอเนต → ผลิตภัณฑ์คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ปฏิกิริยากรด-เบส$t$, $t$ปฏิกิริยาสะเทินคือปฏิกิริยาระหว่าง$t$, $t$กรดกับเบส$t$, $t$เบสกับเกลือ$t$, $t$กรดกับกรด$t$, $t$โลหะกับอโลหะ$t$, 0, $t$ได้เกลือและน้ำ$t$
where not exists (select 1 from quiz_questions where topic = $t$ปฏิกิริยากรด-เบส$t$ and question = $t$ปฏิกิริยาสะเทินคือปฏิกิริยาระหว่าง$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ปฏิกิริยากรด-เบส$t$, $t$เกลือเกิดจากอะไร$t$, $t$ไอออนบวกจากเบส + ไอออนลบจากกรด$t$, $t$กรด + กรด$t$, $t$โลหะ + น้ำเท่านั้น$t$, $t$เบส + เบส$t$, 0, $t$เช่น Na⁺ + Cl⁻ = NaCl$t$
where not exists (select 1 from quiz_questions where topic = $t$ปฏิกิริยากรด-เบส$t$ and question = $t$เกลือเกิดจากอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและคำนำหน้า$t$, $t$คำนำหน้า เมกะ (M) มีค่าเท่าใด$t$, $t$10⁹$t$, $t$10³$t$, $t$10⁶$t$, $t$10⁻⁶$t$, 2, $t$เมกะ (M) = 10⁶$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและคำนำหน้า$t$ and question = $t$คำนำหน้า เมกะ (M) มีค่าเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและคำนำหน้า$t$, $t$คำนำหน้า กิกะ (G) มีค่าเท่าใด$t$, $t$10⁹$t$, $t$10¹²$t$, $t$10⁻⁹$t$, $t$10⁶$t$, 0, $t$กิกะ (G) = 10⁹$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและคำนำหน้า$t$ and question = $t$คำนำหน้า กิกะ (G) มีค่าเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและคำนำหน้า$t$, $t$คำนำหน้า เซนติ (c) มีค่าเท่าใด$t$, $t$10⁻²$t$, $t$10⁻³$t$, $t$10⁻¹$t$, $t$10²$t$, 0, $t$เซนติ (c) = 10⁻²$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและคำนำหน้า$t$ and question = $t$คำนำหน้า เซนติ (c) มีค่าเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและคำนำหน้า$t$, $t$คำนำหน้า ไมโคร (μ) มีค่าเท่าใด$t$, $t$10⁻⁶$t$, $t$10⁻⁹$t$, $t$10⁻³$t$, $t$10⁶$t$, 0, $t$ไมโคร (μ) = 10⁻⁶$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและคำนำหน้า$t$ and question = $t$คำนำหน้า ไมโคร (μ) มีค่าเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและคำนำหน้า$t$, $t$คำนำหน้า เดซิ (d) มีค่าเท่าใด$t$, $t$10⁻²$t$, $t$10⁻¹$t$, $t$10⁻³$t$, $t$10¹$t$, 1, $t$เดซิ (d) = 10⁻¹$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและคำนำหน้า$t$ and question = $t$คำนำหน้า เดซิ (d) มีค่าเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและคำนำหน้า$t$, $t$คำนำหน้า พิโก (p) มีค่าเท่าใด$t$, $t$10⁻⁶$t$, $t$10⁻¹²$t$, $t$10⁻⁹$t$, $t$10¹²$t$, 1, $t$พิโก (p) = 10⁻¹²$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและคำนำหน้า$t$ and question = $t$คำนำหน้า พิโก (p) มีค่าเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและคำนำหน้า$t$, $t$500 มิลลิลิตร (mL) กี่ลิตร$t$, $t$50 L$t$, $t$0.05 L$t$, $t$5 L$t$, $t$0.5 L$t$, 3, $t$500 มิลลิลิตร (mL) ลิตร → 0.5 L$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและคำนำหน้า$t$ and question = $t$500 มิลลิลิตร (mL) กี่ลิตร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและคำนำหน้า$t$, $t$3 กิโลกรัม (kg) กี่กรัม$t$, $t$30 g$t$, $t$300 g$t$, $t$30,000 g$t$, $t$3,000 g$t$, 3, $t$3 กิโลกรัม (kg) กรัม → 3,000 g$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและคำนำหน้า$t$ and question = $t$3 กิโลกรัม (kg) กี่กรัม$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและคำนำหน้า$t$, $t$1 เมตร (m) กี่เซนติเมตร$t$, $t$1,000 cm$t$, $t$10,000 cm$t$, $t$100 cm$t$, $t$10 cm$t$, 2, $t$1 เมตร (m) เซนติเมตร → 100 cm$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและคำนำหน้า$t$ and question = $t$1 เมตร (m) กี่เซนติเมตร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและคำนำหน้า$t$, $t$1 เซนติเมตร (cm) กี่มิลลิเมตร$t$, $t$1,000 mm$t$, $t$100 mm$t$, $t$10 mm$t$, $t$1 mm$t$, 2, $t$1 เซนติเมตร (cm) มิลลิเมตร → 10 mm$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและคำนำหน้า$t$ and question = $t$1 เซนติเมตร (cm) กี่มิลลิเมตร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและคำนำหน้า$t$, $t$1 ลิตร (L) เท่ากับกี่ cm³$t$, $t$10,000 cm³$t$, $t$100 cm³$t$, $t$1,000 cm³$t$, $t$10 cm³$t$, 2, $t$1 ลิตร (L) เท่ากับ cm³ → 1,000 cm³$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและคำนำหน้า$t$ and question = $t$1 ลิตร (L) เท่ากับกี่ cm³$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและคำนำหน้า$t$, $t$1 mL เท่ากับกี่ cm³$t$, $t$1 cm³$t$, $t$0.1 cm³$t$, $t$10 cm³$t$, $t$1,000 cm³$t$, 0, $t$1 mL เท่ากับ cm³ → 1 cm³$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและคำนำหน้า$t$ and question = $t$1 mL เท่ากับกี่ cm³$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและคำนำหน้า$t$, $t$0 °C เท่ากับกี่เคลวิน (K)$t$, $t$273 K$t$, $t$100 K$t$, $t$0 K$t$, $t$373 K$t$, 0, $t$0 °C เท่ากับเคลวิน (K) → 273 K$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและคำนำหน้า$t$ and question = $t$0 °C เท่ากับกี่เคลวิน (K)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและคำนำหน้า$t$, $t$100 °C เท่ากับกี่เคลวิน (K)$t$, $t$100 K$t$, $t$473 K$t$, $t$373 K$t$, $t$273 K$t$, 2, $t$100 °C เท่ากับเคลวิน (K) → 373 K$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและคำนำหน้า$t$ and question = $t$100 °C เท่ากับกี่เคลวิน (K)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและคำนำหน้า$t$, $t$0 เคลวินเรียกว่า$t$, $t$จุดเยือกแข็งของน้ำ$t$, $t$ศูนย์สัมบูรณ์$t$, $t$อุณหภูมิห้อง$t$, $t$จุดเดือดของน้ำ$t$, 1, $t$0 เคลวินเรียกว่า → ศูนย์สัมบูรณ์$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและคำนำหน้า$t$ and question = $t$0 เคลวินเรียกว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและคำนำหน้า$t$, $t$1 atm เท่ากับกี่ mmHg$t$, $t$1,000 mmHg$t$, $t$76 mmHg$t$, $t$760 mmHg$t$, $t$100 mmHg$t$, 2, $t$1 atm เท่ากับ mmHg → 760 mmHg$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและคำนำหน้า$t$ and question = $t$1 atm เท่ากับกี่ mmHg$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและคำนำหน้า$t$, $t$1 กิโลจูล (kJ) กี่จูล (J)$t$, $t$1,000 J$t$, $t$100 J$t$, $t$10 J$t$, $t$1 J$t$, 0, $t$1 กิโลจูล (kJ) จูล (J) → 1,000 J$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและคำนำหน้า$t$ and question = $t$1 กิโลจูล (kJ) กี่จูล (J)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและคำนำหน้า$t$, $t$1 แคลอรี (cal) ≈ กี่จูล$t$, $t$1 J$t$, $t$0.24 J$t$, $t$4.18 J$t$, $t$10 J$t$, 2, $t$1 แคลอรี (cal) ≈ จูล → 4.18 J$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและคำนำหน้า$t$ and question = $t$1 แคลอรี (cal) ≈ กี่จูล$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและคำนำหน้า$t$, $t$1 ชั่วโมงกี่วินาที$t$, $t$360 s$t$, $t$60 s$t$, $t$6,000 s$t$, $t$3,600 s$t$, 3, $t$1 ชั่วโมงวินาที → 3,600 s$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและคำนำหน้า$t$ and question = $t$1 ชั่วโมงกี่วินาที$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและคำนำหน้า$t$, $t$หน่วย SI ของมวลคือ$t$, $t$นิวตัน$t$, $t$กรัม (g)$t$, $t$กิโลกรัม (kg)$t$, $t$ปอนด์$t$, 2, $t$หน่วย SI ของมวลคือ → กิโลกรัม (kg)$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและคำนำหน้า$t$ and question = $t$หน่วย SI ของมวลคือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและคำนำหน้า$t$, $t$หน่วย SI ของปริมาณสาร (จำนวนอนุภาค) คือ$t$, $t$มวลอะตอม$t$, $t$ลิตร$t$, $t$กรัม$t$, $t$โมล (mol)$t$, 3, $t$หน่วย SI ของปริมาณสาร (จำนวนอนุภาค) คือ → โมล (mol)$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและคำนำหน้า$t$ and question = $t$หน่วย SI ของปริมาณสาร (จำนวนอนุภาค) คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและคำนำหน้า$t$, $t$หน่วย SI ของความยาวคือ$t$, $t$ฟุต$t$, $t$เซนติเมตร$t$, $t$กิโลเมตร$t$, $t$เมตร (m)$t$, 3, $t$หน่วย SI ของความยาวคือ → เมตร (m)$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและคำนำหน้า$t$ and question = $t$หน่วย SI ของความยาวคือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและคำนำหน้า$t$, $t$หน่วยของความหนาแน่นคือ$t$, $t$g/s$t$, $t$g/cm³$t$, $t$mol/g$t$, $t$cm³/g$t$, 1, $t$หน่วยของความหนาแน่นคือ → g/cm³$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและคำนำหน้า$t$ and question = $t$หน่วยของความหนาแน่นคือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและคำนำหน้า$t$, $t$สาร 20 g ปริมาตร 10 cm³ มีความหนาแน่นเท่าใด$t$, $t$0.5 g/cm³$t$, $t$2 g/cm³$t$, $t$200 g/cm³$t$, $t$10 g/cm³$t$, 1, $t$สาร 20 g ปริมาตร 10 cm³ มีความหนาแน่นเท่าใด → 2 g/cm³$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและคำนำหน้า$t$ and question = $t$สาร 20 g ปริมาตร 10 cm³ มีความหนาแน่นเท่าใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$หน่วยและคำนำหน้า$t$, $t$ตัวเลข 0.00450 มีเลขนัยสำคัญกี่ตัว$t$, $t$6 ตัว$t$, $t$3 ตัว$t$, $t$5 ตัว$t$, $t$2 ตัว$t$, 1, $t$ตัวเลข 0.00450 มีเลขนัยสำคัญตัว → 3 ตัว$t$
where not exists (select 1 from quiz_questions where topic = $t$หน่วยและคำนำหน้า$t$ and question = $t$ตัวเลข 0.00450 มีเลขนัยสำคัญกี่ตัว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การใช้อุปกรณ์$t$, $t$บีกเกอร์ ใช้ทำอะไร$t$, $t$ส่องเซลล์$t$, $t$แยกของเหลวสองชั้น$t$, $t$วัดมวลสาร$t$, $t$ใส่และให้ความร้อนสารปริมาณไม่ต้องแม่นยำ$t$, 3, $t$บีกเกอร์: ใส่และให้ความร้อนสารปริมาณไม่ต้องแม่นยำ$t$
where not exists (select 1 from quiz_questions where topic = $t$การใช้อุปกรณ์$t$ and question = $t$บีกเกอร์ ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การใช้อุปกรณ์$t$, $t$กระบอกตวง ใช้ทำอะไร$t$, $t$หยดสารละลายทีละหยด$t$, $t$ต้มสาร$t$, $t$วัดปริมาตรของเหลวโดยประมาณ$t$, $t$ชั่งมวล$t$, 2, $t$กระบอกตวง: วัดปริมาตรของเหลวโดยประมาณ$t$
where not exists (select 1 from quiz_questions where topic = $t$การใช้อุปกรณ์$t$ and question = $t$กระบอกตวง ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การใช้อุปกรณ์$t$, $t$ปิเปต ใช้ทำอะไร$t$, $t$บดสาร$t$, $t$ดูดของเหลวในปริมาตรที่แน่นอน$t$, $t$เผาสาร$t$, $t$ชั่งสาร$t$, 1, $t$ปิเปต: ดูดของเหลวในปริมาตรที่แน่นอน$t$
where not exists (select 1 from quiz_questions where topic = $t$การใช้อุปกรณ์$t$ and question = $t$ปิเปต ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การใช้อุปกรณ์$t$, $t$บิวเรต ใช้ทำอะไร$t$, $t$หยดสารละลายในการไทเทรต$t$, $t$บดสาร$t$, $t$เก็บแก๊ส$t$, $t$ชั่งสาร$t$, 0, $t$บิวเรต: หยดสารละลายในการไทเทรต$t$
where not exists (select 1 from quiz_questions where topic = $t$การใช้อุปกรณ์$t$ and question = $t$บิวเรต ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การใช้อุปกรณ์$t$, $t$ขวดรูปชมพู่ ใช้ทำอะไร$t$, $t$ใส่สารละลายขณะไทเทรตและผสมสาร$t$, $t$ตัดสาร$t$, $t$วัดมวล$t$, $t$เก็บแก๊สเท่านั้น$t$, 0, $t$ขวดรูปชมพู่: ใส่สารละลายขณะไทเทรตและผสมสาร$t$
where not exists (select 1 from quiz_questions where topic = $t$การใช้อุปกรณ์$t$ and question = $t$ขวดรูปชมพู่ ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การใช้อุปกรณ์$t$, $t$ขวดกำหนดปริมาตร ใช้ทำอะไร$t$, $t$ต้มน้ำ$t$, $t$ชั่งสาร$t$, $t$แยกของแข็ง$t$, $t$เตรียมสารละลายความเข้มข้นแน่นอน$t$, 3, $t$ขวดกำหนดปริมาตร: เตรียมสารละลายความเข้มข้นแน่นอน$t$
where not exists (select 1 from quiz_questions where topic = $t$การใช้อุปกรณ์$t$ and question = $t$ขวดกำหนดปริมาตร ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การใช้อุปกรณ์$t$, $t$หลอดทดลอง ใช้ทำอะไร$t$, $t$ชั่งสาร$t$, $t$ทำปฏิกิริยาปริมาณน้อย$t$, $t$กลั่นน้ำปริมาณมาก$t$, $t$วัดอุณหภูมิ$t$, 1, $t$หลอดทดลอง: ทำปฏิกิริยาปริมาณน้อย$t$
where not exists (select 1 from quiz_questions where topic = $t$การใช้อุปกรณ์$t$ and question = $t$หลอดทดลอง ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การใช้อุปกรณ์$t$, $t$เทอร์มอมิเตอร์ ใช้ทำอะไร$t$, $t$วัดอุณหภูมิ$t$, $t$วัด pH$t$, $t$วัดมวล$t$, $t$วัดปริมาตร$t$, 0, $t$เทอร์มอมิเตอร์: วัดอุณหภูมิ$t$
where not exists (select 1 from quiz_questions where topic = $t$การใช้อุปกรณ์$t$ and question = $t$เทอร์มอมิเตอร์ ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การใช้อุปกรณ์$t$, $t$เครื่องชั่ง ใช้ทำอะไร$t$, $t$วัดมวลสาร$t$, $t$วัดปริมาตร$t$, $t$วัดความดัน$t$, $t$วัดอุณหภูมิ$t$, 0, $t$เครื่องชั่ง: วัดมวลสาร$t$
where not exists (select 1 from quiz_questions where topic = $t$การใช้อุปกรณ์$t$ and question = $t$เครื่องชั่ง ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การใช้อุปกรณ์$t$, $t$ตะเกียงแอลกอฮอล์ ใช้ทำอะไร$t$, $t$ให้ความร้อน$t$, $t$กรองสาร$t$, $t$วัดปริมาตร$t$, $t$ชั่งมวล$t$, 0, $t$ตะเกียงแอลกอฮอล์: ให้ความร้อน$t$
where not exists (select 1 from quiz_questions where topic = $t$การใช้อุปกรณ์$t$ and question = $t$ตะเกียงแอลกอฮอล์ ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การใช้อุปกรณ์$t$, $t$ตะแกรงลวด ใช้ทำอะไร$t$, $t$ดูดสาร$t$, $t$กระจายความร้อนให้ภาชนะ$t$, $t$ผสมสาร$t$, $t$วัดมวล$t$, 1, $t$ตะแกรงลวด: กระจายความร้อนให้ภาชนะ$t$
where not exists (select 1 from quiz_questions where topic = $t$การใช้อุปกรณ์$t$ and question = $t$ตะแกรงลวด ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การใช้อุปกรณ์$t$, $t$ที่จับหลอดทดลอง ใช้ทำอะไร$t$, $t$จับหลอดทดลองขณะให้ความร้อน$t$, $t$วัดความร้อน$t$, $t$ชั่งสาร$t$, $t$ผสมสาร$t$, 0, $t$ที่จับหลอดทดลอง: จับหลอดทดลองขณะให้ความร้อน$t$
where not exists (select 1 from quiz_questions where topic = $t$การใช้อุปกรณ์$t$ and question = $t$ที่จับหลอดทดลอง ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การใช้อุปกรณ์$t$, $t$กรวยกรอง ใช้ทำอะไร$t$, $t$ใช้กรองแยกของแข็งออกจากของเหลว$t$, $t$ชั่งมวล$t$, $t$วัดปริมาตร$t$, $t$ต้มสาร$t$, 0, $t$กรวยกรอง: ใช้กรองแยกของแข็งออกจากของเหลว$t$
where not exists (select 1 from quiz_questions where topic = $t$การใช้อุปกรณ์$t$ and question = $t$กรวยกรอง ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การใช้อุปกรณ์$t$, $t$กรวยแยก ใช้ทำอะไร$t$, $t$ชั่งมวล$t$, $t$แยกของเหลวที่ไม่ผสมกัน$t$, $t$วัดอุณหภูมิ$t$, $t$กรองของแข็ง$t$, 1, $t$กรวยแยก: แยกของเหลวที่ไม่ผสมกัน$t$
where not exists (select 1 from quiz_questions where topic = $t$การใช้อุปกรณ์$t$ and question = $t$กรวยแยก ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การใช้อุปกรณ์$t$, $t$แท่งแก้วคนสาร ใช้ทำอะไร$t$, $t$คนให้สารละลายผสมหรือช่วยรินสาร$t$, $t$วัดอุณหภูมิ$t$, $t$ชั่งมวล$t$, $t$กรองสาร$t$, 0, $t$แท่งแก้วคนสาร: คนให้สารละลายผสมหรือช่วยรินสาร$t$
where not exists (select 1 from quiz_questions where topic = $t$การใช้อุปกรณ์$t$ and question = $t$แท่งแก้วคนสาร ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การใช้อุปกรณ์$t$, $t$ครกบดสาร ใช้ทำอะไร$t$, $t$วัดมวล$t$, $t$แยกของเหลว$t$, $t$ต้มสาร$t$, $t$บดของแข็งให้ละเอียด$t$, 3, $t$ครกบดสาร: บดของแข็งให้ละเอียด$t$
where not exists (select 1 from quiz_questions where topic = $t$การใช้อุปกรณ์$t$ and question = $t$ครกบดสาร ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การใช้อุปกรณ์$t$, $t$จานระเหย ใช้ทำอะไร$t$, $t$วัดอุณหภูมิ$t$, $t$ชั่งมวล$t$, $t$ระเหยตัวทำละลายออกจากสารละลาย$t$, $t$ดูดสาร$t$, 2, $t$จานระเหย: ระเหยตัวทำละลายออกจากสารละลาย$t$
where not exists (select 1 from quiz_questions where topic = $t$การใช้อุปกรณ์$t$ and question = $t$จานระเหย ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การใช้อุปกรณ์$t$, $t$หลอดหยด ใช้ทำอะไร$t$, $t$บดสาร$t$, $t$ดูดและหยดสารปริมาณเล็กน้อย$t$, $t$ชั่งมวล$t$, $t$ต้มสาร$t$, 1, $t$หลอดหยด: ดูดและหยดสารปริมาณเล็กน้อย$t$
where not exists (select 1 from quiz_questions where topic = $t$การใช้อุปกรณ์$t$ and question = $t$หลอดหยด ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การใช้อุปกรณ์$t$, $t$ที่ล้างตา ใช้ทำอะไร$t$, $t$ต้มสาร$t$, $t$ล้างตาเมื่อสารเคมีเข้าตา$t$, $t$ชั่งมวล$t$, $t$ล้างอุปกรณ์เท่านั้น$t$, 1, $t$ที่ล้างตา: ล้างตาเมื่อสารเคมีเข้าตา$t$
where not exists (select 1 from quiz_questions where topic = $t$การใช้อุปกรณ์$t$ and question = $t$ที่ล้างตา ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การใช้อุปกรณ์$t$, $t$ตู้ดูดควัน ใช้ทำอะไร$t$, $t$ให้ความร้อน$t$, $t$ป้องกันแก๊สพิษขณะทดลอง$t$, $t$เก็บสาร$t$, $t$ชั่งมวล$t$, 1, $t$ตู้ดูดควัน: ป้องกันแก๊สพิษขณะทดลอง$t$
where not exists (select 1 from quiz_questions where topic = $t$การใช้อุปกรณ์$t$ and question = $t$ตู้ดูดควัน ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การใช้อุปกรณ์$t$, $t$แก้วนาฬิกา ใช้ทำอะไร$t$, $t$ใส่สารปริมาณน้อยหรือปิดบีกเกอร์$t$, $t$ชั่งมวล$t$, $t$วัดเวลา$t$, $t$ต้มน้ำ$t$, 0, $t$แก้วนาฬิกา: ใส่สารปริมาณน้อยหรือปิดบีกเกอร์$t$
where not exists (select 1 from quiz_questions where topic = $t$การใช้อุปกรณ์$t$ and question = $t$แก้วนาฬิกา ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การใช้อุปกรณ์$t$, $t$กระดาษกรอง ใช้ทำอะไร$t$, $t$กั้นอนุภาคของแข็งไว้ขณะกรอง$t$, $t$ดูดความร้อน$t$, $t$วัด pH$t$, $t$ชั่งมวล$t$, 0, $t$กระดาษกรอง: กั้นอนุภาคของแข็งไว้ขณะกรอง$t$
where not exists (select 1 from quiz_questions where topic = $t$การใช้อุปกรณ์$t$ and question = $t$กระดาษกรอง ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$การใช้อุปกรณ์$t$, $t$เครื่องกลั่น (คอนเดนเซอร์) ใช้ทำอะไร$t$, $t$วัด pH$t$, $t$กรองของแข็ง$t$, $t$ชั่งมวล$t$, $t$ควบแน่นไอกลับเป็นของเหลว$t$, 3, $t$เครื่องกลั่น (คอนเดนเซอร์): ควบแน่นไอกลับเป็นของเหลว$t$
where not exists (select 1 from quiz_questions where topic = $t$การใช้อุปกรณ์$t$ and question = $t$เครื่องกลั่น (คอนเดนเซอร์) ใช้ทำอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยเบื้องต้น$t$, $t$ก่อนทำการทดลองควรทำสิ่งใดเป็นอันดับแรก$t$, $t$อ่านขั้นตอนและฉลากสาร$t$, $t$ถอดแว่นตานิรภัย$t$, $t$ผสมสารทุกชนิดเข้าด้วยกัน$t$, $t$ชิมสารดู$t$, 0, $t$อ่านก่อนทำ$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยเบื้องต้น$t$ and question = $t$ก่อนทำการทดลองควรทำสิ่งใดเป็นอันดับแรก$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยเบื้องต้น$t$, $t$เมื่อกรดเข้มข้นหกใส่มือควรทำอย่างไรก่อน$t$, $t$ล้างด้วยน้ำสะอาดปริมาณมากทันที$t$, $t$ปล่อยไว้$t$, $t$ทาน้ำมัน$t$, $t$เช็ดด้วยกระดาษแห้ง$t$, 0, $t$ล้างน้ำนานอย่างน้อย 10-15 นาที$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยเบื้องต้น$t$ and question = $t$เมื่อกรดเข้มข้นหกใส่มือควรทำอย่างไรก่อน$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยเบื้องต้น$t$, $t$การเจือจางกรดเข้มข้นต้องทำอย่างไร$t$, $t$เทน้ำลงกรดเข้มข้น$t$, $t$เทพร้อมกันเร็วๆ$t$, $t$เทกรดลงน้ำช้าๆ$t$, $t$ใช้ขวดปิดฝาแน่นเขย่า$t$, 2, $t$Acid into water$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยเบื้องต้น$t$ and question = $t$การเจือจางกรดเข้มข้นต้องทำอย่างไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยเบื้องต้น$t$, $t$เมื่อให้ความร้อนหลอดทดลอง ปากหลอดควรหันไปทางใด$t$, $t$หันเข้าหาเพื่อน$t$, $t$ไม่หันเข้าหาตนเองหรือผู้อื่น$t$, $t$หันเข้าหาตัวเอง$t$, $t$ปิดจุกแน่น$t$, 1, $t$ป้องกันสารกระเด็น$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยเบื้องต้น$t$ and question = $t$เมื่อให้ความร้อนหลอดทดลอง ปากหลอดควรหันไปทางใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยเบื้องต้น$t$, $t$สัญลักษณ์เปลวไฟบนฉลากสารหมายถึง$t$, $t$สารกัมมันตรังสี$t$, $t$สารไวไฟ$t$, $t$สารพิษ$t$, $t$สารกัดกร่อน$t$, 1, $t$ห่างจากไฟ$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยเบื้องต้น$t$ and question = $t$สัญลักษณ์เปลวไฟบนฉลากสารหมายถึง$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยเบื้องต้น$t$, $t$สัญลักษณ์หัวกะโหลกไขว้บนฉลากหมายถึง$t$, $t$สารระเบิด$t$, $t$สารไวไฟ$t$, $t$สารพิษ$t$, $t$สารออกซิไดส์$t$, 2, $t$เป็นอันตรายถึงตาย$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยเบื้องต้น$t$ and question = $t$สัญลักษณ์หัวกะโหลกไขว้บนฉลากหมายถึง$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยเบื้องต้น$t$, $t$ของเสียจากการทดลองควรทำอย่างไร$t$, $t$แยกทิ้งตามประเภทที่ครูกำหนด$t$, $t$เทลงอ่างทั้งหมด$t$, $t$ทิ้งถังขยะทั่วไปเสมอ$t$, $t$ซ่อนไว้ใต้โต๊ะ$t$, 0, $t$กำจัดอย่างถูกต้อง$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยเบื้องต้น$t$ and question = $t$ของเสียจากการทดลองควรทำอย่างไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยเบื้องต้น$t$, $t$เมื่อมีไฟลุกไหม้บนโต๊ะทดลองเล็กน้อย ควรแจ้งใครทันที$t$, $t$ไม่ต้องแจ้งใคร$t$, $t$เพื่อนข้างๆ เท่านั้น$t$, $t$ผู้ปกครอง$t$, $t$ครูผู้สอน$t$, 3, $t$แจ้งครูและใช้อุปกรณ์ดับเพลิงตามคำแนะนำ$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยเบื้องต้น$t$ and question = $t$เมื่อมีไฟลุกไหม้บนโต๊ะทดลองเล็กน้อย ควรแจ้งใครทันที$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความปลอดภัยเบื้องต้น$t$, $t$แว่นตานิรภัยใช้เมื่อใด$t$, $t$เฉพาะตอนผสมกรด$t$, $t$ไม่จำเป็น$t$, $t$ตลอดเวลาที่ทำการทดลอง$t$, $t$เมื่อครูสั่งเท่านั้น$t$, 2, $t$ปกป้องดวงตา$t$
where not exists (select 1 from quiz_questions where topic = $t$ความปลอดภัยเบื้องต้น$t$ and question = $t$แว่นตานิรภัยใช้เมื่อใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์ผู้ค้นพบ$t$, $t$ใครเสนอทฤษฎีอะตอมแบบทรงกลมตัน$t$, $t$จอห์น ดาลตัน$t$, $t$อองรี เบ็กเคอเรล$t$, $t$กิลเบิร์ต ลิวอิส$t$, $t$นีลส์ โบร์$t$, 0, $t$จอห์น ดาลตัน: เสนอทฤษฎีอะตอมแบบทรงกลมตัน$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์ผู้ค้นพบ$t$ and question = $t$ใครเสนอทฤษฎีอะตอมแบบทรงกลมตัน$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์ผู้ค้นพบ$t$, $t$ใครค้นพบนิวเคลียสจากการทดลองแผ่นทองคำ$t$, $t$เออร์เนสต์ รัทเทอร์ฟอร์ด$t$, $t$ไลนัส พอลิง$t$, $t$ออยเกน โกลด์ชไตน์$t$, $t$โรเบิร์ต มิลลิแกน$t$, 0, $t$เออร์เนสต์ รัทเทอร์ฟอร์ด: ค้นพบนิวเคลียสจากการทดลองแผ่นทองคำ$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์ผู้ค้นพบ$t$ and question = $t$ใครค้นพบนิวเคลียสจากการทดลองแผ่นทองคำ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์ผู้ค้นพบ$t$, $t$ใครเสนอว่าอิเล็กตรอนอยู่ในระดับพลังงานเฉพาะ$t$, $t$เออร์เนสต์ รัทเทอร์ฟอร์ด$t$, $t$จอห์น ดาลตัน$t$, $t$นีลส์ โบร์$t$, $t$โรเบิร์ต บอยล์$t$, 2, $t$นีลส์ โบร์: เสนอว่าอิเล็กตรอนอยู่ในระดับพลังงานเฉพาะ$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์ผู้ค้นพบ$t$ and question = $t$ใครเสนอว่าอิเล็กตรอนอยู่ในระดับพลังงานเฉพาะ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์ผู้ค้นพบ$t$, $t$ใครจัดตารางธาตุตามมวลอะตอมและทำนายธาตุใหม่$t$, $t$ดิมิทรี เมนเดเลเยฟ$t$, $t$โรเบิร์ต บอยล์$t$, $t$เจมส์ แชดวิก$t$, $t$อันตวน ลาวัวซีเย$t$, 0, $t$ดิมิทรี เมนเดเลเยฟ: จัดตารางธาตุตามมวลอะตอมและทำนายธาตุใหม่$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์ผู้ค้นพบ$t$ and question = $t$ใครจัดตารางธาตุตามมวลอะตอมและทำนายธาตุใหม่$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์ผู้ค้นพบ$t$, $t$ใครเสนอว่าแก๊สปริมาตรเท่ากันมีจำนวนโมเลกุลเท่ากัน$t$, $t$อาโวกาโดร$t$, $t$ไลนัส พอลิง$t$, $t$อองรี เบ็กเคอเรล$t$, $t$โรเบิร์ต บอยล์$t$, 0, $t$อาโวกาโดร: เสนอว่าแก๊สปริมาตรเท่ากันมีจำนวนโมเลกุลเท่ากัน$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์ผู้ค้นพบ$t$ and question = $t$ใครเสนอว่าแก๊สปริมาตรเท่ากันมีจำนวนโมเลกุลเท่ากัน$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์ผู้ค้นพบ$t$, $t$ใครศึกษาความสัมพันธ์ P กับ V ของแก๊ส$t$, $t$โรเบิร์ต บอยล์$t$, $t$นีลส์ โบร์$t$, $t$โรเบิร์ต มิลลิแกน$t$, $t$อันตวน ลาวัวซีเย$t$, 0, $t$โรเบิร์ต บอยล์: ศึกษาความสัมพันธ์ P กับ V ของแก๊ส$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์ผู้ค้นพบ$t$ and question = $t$ใครศึกษาความสัมพันธ์ P กับ V ของแก๊ส$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์ผู้ค้นพบ$t$, $t$ใครค้นพบธาตุพอโลเนียมและเรเดียม$t$, $t$โรเบิร์ต บอยล์$t$, $t$มารี คูรี$t$, $t$เจมส์ แชดวิก$t$, $t$อาโวกาโดร$t$, 1, $t$มารี คูรี: ค้นพบธาตุพอโลเนียมและเรเดียม$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์ผู้ค้นพบ$t$ and question = $t$ใครค้นพบธาตุพอโลเนียมและเรเดียม$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์ผู้ค้นพบ$t$, $t$ใครค้นพบโปรตอน (รังสีแคแนล)$t$, $t$จอห์น ดาลตัน$t$, $t$มารี คูรี$t$, $t$เจ.เจ. ทอมสัน$t$, $t$ออยเกน โกลด์ชไตน์$t$, 3, $t$ออยเกน โกลด์ชไตน์: ค้นพบโปรตอน (รังสีแคแนล)$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์ผู้ค้นพบ$t$ and question = $t$ใครค้นพบโปรตอน (รังสีแคแนล)$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์ผู้ค้นพบ$t$, $t$ใครค้นพบกัมมันตภาพรังสี$t$, $t$มารี คูรี$t$, $t$โรเบิร์ต บอยล์$t$, $t$อองรี เบ็กเคอเรล$t$, $t$อาโวกาโดร$t$, 2, $t$อองรี เบ็กเคอเรล: ค้นพบกัมมันตภาพรังสี$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์ผู้ค้นพบ$t$ and question = $t$ใครค้นพบกัมมันตภาพรังสี$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์ผู้ค้นพบ$t$, $t$ใครหาประจุของอิเล็กตรอน$t$, $t$กิลเบิร์ต ลิวอิส$t$, $t$โรเบิร์ต มิลลิแกน$t$, $t$เออร์เนสต์ รัทเทอร์ฟอร์ด$t$, $t$อาโวกาโดร$t$, 1, $t$โรเบิร์ต มิลลิแกน: หาประจุของอิเล็กตรอน$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์ผู้ค้นพบ$t$ and question = $t$ใครหาประจุของอิเล็กตรอน$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์ผู้ค้นพบ$t$, $t$ใครเสนอโครงสร้างจุดของพันธะโคเวเลนต์$t$, $t$เจ.เจ. ทอมสัน$t$, $t$มารี คูรี$t$, $t$อันตวน ลาวัวซีเย$t$, $t$กิลเบิร์ต ลิวอิส$t$, 3, $t$กิลเบิร์ต ลิวอิส: เสนอโครงสร้างจุดของพันธะโคเวเลนต์$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์ผู้ค้นพบ$t$ and question = $t$ใครเสนอโครงสร้างจุดของพันธะโคเวเลนต์$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$นักวิทยาศาสตร์ผู้ค้นพบ$t$, $t$ใครเสนอค่าอิเล็กโทรเนกาทิวิตี$t$, $t$จอห์น ดาลตัน$t$, $t$อาโวกาโดร$t$, $t$ไลนัส พอลิง$t$, $t$เฮนรี มอสลีย์$t$, 2, $t$ไลนัส พอลิง: เสนอค่าอิเล็กโทรเนกาทิวิตี$t$
where not exists (select 1 from quiz_questions where topic = $t$นักวิทยาศาสตร์ผู้ค้นพบ$t$ and question = $t$ใครเสนอค่าอิเล็กโทรเนกาทิวิตี$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$พันธะเคมี$t$, $t$NaCl มีพันธะชนิดใดเป็นหลัก$t$, $t$พันธะโคเวเลนต์$t$, $t$พันธะไฮโดรเจน$t$, $t$พันธะโลหะ$t$, $t$พันธะไอออนิก$t$, 3, $t$NaCl: โลหะ + อโลหะ → ไอออนิก$t$
where not exists (select 1 from quiz_questions where topic = $t$พันธะเคมี$t$ and question = $t$NaCl มีพันธะชนิดใดเป็นหลัก$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$พันธะเคมี$t$, $t$Al₂O₃ มีพันธะชนิดใดเป็นหลัก$t$, $t$พันธะโคเวเลนต์$t$, $t$พันธะโลหะ$t$, $t$พันธะไฮโดรเจน$t$, $t$พันธะไอออนิก$t$, 3, $t$Al₂O₃: โลหะ + อโลหะ → ไอออนิก$t$
where not exists (select 1 from quiz_questions where topic = $t$พันธะเคมี$t$ and question = $t$Al₂O₃ มีพันธะชนิดใดเป็นหลัก$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$พันธะเคมี$t$, $t$KI มีพันธะชนิดใดเป็นหลัก$t$, $t$พันธะโคเวเลนต์$t$, $t$พันธะไอออนิก$t$, $t$พันธะไฮโดรเจน$t$, $t$พันธะโลหะ$t$, 1, $t$KI: โลหะ + อโลหะ → ไอออนิก$t$
where not exists (select 1 from quiz_questions where topic = $t$พันธะเคมี$t$ and question = $t$KI มีพันธะชนิดใดเป็นหลัก$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$พันธะเคมี$t$, $t$KBr มีพันธะชนิดใดเป็นหลัก$t$, $t$พันธะไอออนิก$t$, $t$พันธะโคเวเลนต์$t$, $t$พันธะไฮโดรเจน$t$, $t$พันธะโลหะ$t$, 0, $t$KBr: โลหะ + อโลหะ → ไอออนิก$t$
where not exists (select 1 from quiz_questions where topic = $t$พันธะเคมี$t$ and question = $t$KBr มีพันธะชนิดใดเป็นหลัก$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$พันธะเคมี$t$, $t$MgO มีพันธะชนิดใดเป็นหลัก$t$, $t$พันธะโลหะ$t$, $t$พันธะไอออนิก$t$, $t$พันธะไฮโดรเจน$t$, $t$พันธะโคเวเลนต์$t$, 1, $t$MgO: โลหะ + อโลหะ → ไอออนิก$t$
where not exists (select 1 from quiz_questions where topic = $t$พันธะเคมี$t$ and question = $t$MgO มีพันธะชนิดใดเป็นหลัก$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$พันธะเคมี$t$, $t$LiF มีพันธะชนิดใดเป็นหลัก$t$, $t$พันธะโคเวเลนต์$t$, $t$พันธะไฮโดรเจน$t$, $t$พันธะโลหะ$t$, $t$พันธะไอออนิก$t$, 3, $t$LiF: โลหะ + อโลหะ → ไอออนิก$t$
where not exists (select 1 from quiz_questions where topic = $t$พันธะเคมี$t$ and question = $t$LiF มีพันธะชนิดใดเป็นหลัก$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$พันธะเคมี$t$, $t$CaCl₂ มีพันธะชนิดใดเป็นหลัก$t$, $t$พันธะไฮโดรเจน$t$, $t$พันธะไอออนิก$t$, $t$พันธะโลหะ$t$, $t$พันธะโคเวเลนต์$t$, 1, $t$CaCl₂: โลหะ + อโลหะ → ไอออนิก$t$
where not exists (select 1 from quiz_questions where topic = $t$พันธะเคมี$t$ and question = $t$CaCl₂ มีพันธะชนิดใดเป็นหลัก$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$พันธะเคมี$t$, $t$HF มีพันธะชนิดใดเป็นหลัก$t$, $t$พันธะไอออนิก$t$, $t$พันธะโลหะ$t$, $t$พันธะโคเวเลนต์$t$, $t$พันธะไฮโดรเจน$t$, 2, $t$HF: อโลหะ + อโลหะ → โคเวเลนต์$t$
where not exists (select 1 from quiz_questions where topic = $t$พันธะเคมี$t$ and question = $t$HF มีพันธะชนิดใดเป็นหลัก$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$พันธะเคมี$t$, $t$Cl₂ มีพันธะชนิดใดเป็นหลัก$t$, $t$พันธะโลหะ$t$, $t$พันธะไฮโดรเจน$t$, $t$พันธะไอออนิก$t$, $t$พันธะโคเวเลนต์$t$, 3, $t$Cl₂: อโลหะ + อโลหะ → โคเวเลนต์$t$
where not exists (select 1 from quiz_questions where topic = $t$พันธะเคมี$t$ and question = $t$Cl₂ มีพันธะชนิดใดเป็นหลัก$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$พันธะเคมี$t$, $t$CO มีพันธะชนิดใดเป็นหลัก$t$, $t$พันธะโคเวเลนต์$t$, $t$พันธะโลหะ$t$, $t$พันธะไฮโดรเจน$t$, $t$พันธะไอออนิก$t$, 0, $t$CO: อโลหะ + อโลหะ → โคเวเลนต์$t$
where not exists (select 1 from quiz_questions where topic = $t$พันธะเคมี$t$ and question = $t$CO มีพันธะชนิดใดเป็นหลัก$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$พันธะเคมี$t$, $t$N₂ มีพันธะชนิดใดเป็นหลัก$t$, $t$พันธะไอออนิก$t$, $t$พันธะโลหะ$t$, $t$พันธะไฮโดรเจน$t$, $t$พันธะโคเวเลนต์$t$, 3, $t$N₂: อโลหะ + อโลหะ → โคเวเลนต์$t$
where not exists (select 1 from quiz_questions where topic = $t$พันธะเคมี$t$ and question = $t$N₂ มีพันธะชนิดใดเป็นหลัก$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$พันธะเคมี$t$, $t$NH₃ มีพันธะชนิดใดเป็นหลัก$t$, $t$พันธะโลหะ$t$, $t$พันธะไฮโดรเจน$t$, $t$พันธะโคเวเลนต์$t$, $t$พันธะไอออนิก$t$, 2, $t$NH₃: อโลหะ + อโลหะ → โคเวเลนต์$t$
where not exists (select 1 from quiz_questions where topic = $t$พันธะเคมี$t$ and question = $t$NH₃ มีพันธะชนิดใดเป็นหลัก$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$พันธะเคมี$t$, $t$H₂S มีพันธะชนิดใดเป็นหลัก$t$, $t$พันธะไอออนิก$t$, $t$พันธะไฮโดรเจน$t$, $t$พันธะโลหะ$t$, $t$พันธะโคเวเลนต์$t$, 3, $t$H₂S: อโลหะ + อโลหะ → โคเวเลนต์$t$
where not exists (select 1 from quiz_questions where topic = $t$พันธะเคมี$t$ and question = $t$H₂S มีพันธะชนิดใดเป็นหลัก$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$พันธะเคมี$t$, $t$SO₃ มีพันธะชนิดใดเป็นหลัก$t$, $t$พันธะโคเวเลนต์$t$, $t$พันธะไฮโดรเจน$t$, $t$พันธะโลหะ$t$, $t$พันธะไอออนิก$t$, 0, $t$SO₃: อโลหะ + อโลหะ → โคเวเลนต์$t$
where not exists (select 1 from quiz_questions where topic = $t$พันธะเคมี$t$ and question = $t$SO₃ มีพันธะชนิดใดเป็นหลัก$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$พันธะเคมี$t$, $t$O₂ มีพันธะชนิดใดเป็นหลัก$t$, $t$พันธะไอออนิก$t$, $t$พันธะโคเวเลนต์$t$, $t$พันธะโลหะ$t$, $t$พันธะไฮโดรเจน$t$, 1, $t$O₂: อโลหะ + อโลหะ → โคเวเลนต์$t$
where not exists (select 1 from quiz_questions where topic = $t$พันธะเคมี$t$ and question = $t$O₂ มีพันธะชนิดใดเป็นหลัก$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$พันธะเคมี$t$, $t$พันธะที่เกิดจากแรงดึงดูดระหว่างไอออนบวกกับไอออนลบคือ$t$, $t$พันธะโคเวเลนต์$t$, $t$พันธะโลหะ$t$, $t$พันธะไฮโดรเจน$t$, $t$พันธะไอออนิก$t$, 3, $t$ไอออนบวก + ไอออนลบ$t$
where not exists (select 1 from quiz_questions where topic = $t$พันธะเคมี$t$ and question = $t$พันธะที่เกิดจากแรงดึงดูดระหว่างไอออนบวกกับไอออนลบคือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$พันธะเคมี$t$, $t$พันธะที่เกิดจากการใช้อิเล็กตรอนร่วมกันคือ$t$, $t$พันธะไฮโดรเจน$t$, $t$พันธะไอออนิก$t$, $t$พันธะโคเวเลนต์$t$, $t$พันธะโลหะ$t$, 2, $t$ใช้ e⁻ ร่วมกัน$t$
where not exists (select 1 from quiz_questions where topic = $t$พันธะเคมี$t$ and question = $t$พันธะที่เกิดจากการใช้อิเล็กตรอนร่วมกันคือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$พันธะเคมี$t$, $t$โลหะ + อโลหะ มักเกิดพันธะชนิดใด$t$, $t$โลหะ$t$, $t$ไฮโดรเจน$t$, $t$โคเวเลนต์$t$, $t$ไอออนิก$t$, 3, $t$ถ่ายโอนอิเล็กตรอน$t$
where not exists (select 1 from quiz_questions where topic = $t$พันธะเคมี$t$ and question = $t$โลหะ + อโลหะ มักเกิดพันธะชนิดใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$พันธะเคมี$t$, $t$N₂ มีพันธะโคเวเลนต์ระหว่างอะตอมแบบใด$t$, $t$ไม่มีพันธะ$t$, $t$พันธะเดี่ยว$t$, $t$พันธะสาม$t$, $t$พันธะคู่$t$, 2, $t$N≡N$t$
where not exists (select 1 from quiz_questions where topic = $t$พันธะเคมี$t$ and question = $t$N₂ มีพันธะโคเวเลนต์ระหว่างอะตอมแบบใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$พันธะเคมี$t$, $t$O₂ มีพันธะโคเวเลนต์ระหว่างอะตอมแบบใด$t$, $t$พันธะสาม$t$, $t$ไม่มีพันธะ$t$, $t$พันธะเดี่ยว$t$, $t$พันธะคู่$t$, 3, $t$O=O$t$
where not exists (select 1 from quiz_questions where topic = $t$พันธะเคมี$t$ and question = $t$O₂ มีพันธะโคเวเลนต์ระหว่างอะตอมแบบใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$พันธะเคมี$t$, $t$สารไอออนิกเป็นของแข็งที่จุดหลอมเหลวเป็นอย่างไร$t$, $t$ต่ำกว่า 0 °C เสมอ$t$, $t$สูง$t$, $t$ต่ำมาก$t$, $t$ไม่มี$t$, 1, $t$แรงดึงดูดไอออนแรง$t$
where not exists (select 1 from quiz_questions where topic = $t$พันธะเคมี$t$ and question = $t$สารไอออนิกเป็นของแข็งที่จุดหลอมเหลวเป็นอย่างไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$พันธะเคมี$t$, $t$H₂O เป็นโมเลกุลมีขั้วหรือไม่มีขั้ว$t$, $t$มีขั้ว$t$, $t$เป็นโลหะ$t$, $t$เป็นไอออน$t$, $t$ไม่มีขั้ว$t$, 0, $t$รูปงอ$t$
where not exists (select 1 from quiz_questions where topic = $t$พันธะเคมี$t$ and question = $t$H₂O เป็นโมเลกุลมีขั้วหรือไม่มีขั้ว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$พันธะเคมี$t$, $t$CO₂ เป็นโมเลกุลมีขั้วหรือไม่มีขั้ว$t$, $t$ไม่มีขั้ว$t$, $t$เป็นไอออน$t$, $t$เป็นโลหะ$t$, $t$มีขั้ว$t$, 0, $t$เส้นตรง สมมาตร$t$
where not exists (select 1 from quiz_questions where topic = $t$พันธะเคมี$t$ and question = $t$CO₂ เป็นโมเลกุลมีขั้วหรือไม่มีขั้ว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$พันธะเคมี$t$, $t$NH₃ เป็นโมเลกุลมีขั้วหรือไม่มีขั้ว$t$, $t$ไม่มีขั้ว$t$, $t$มีขั้ว$t$, $t$เป็นไอออน$t$, $t$เป็นโลหะ$t$, 1, $t$พีระมิดฐานสามเหลี่ยม$t$
where not exists (select 1 from quiz_questions where topic = $t$พันธะเคมี$t$ and question = $t$NH₃ เป็นโมเลกุลมีขั้วหรือไม่มีขั้ว$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$พันธะเคมี$t$, $t$พันธะไฮโดรเจนเกิดระหว่างโมเลกุลที่มี H ต่อกับธาตุใดได้$t$, $t$He, Ne, Ar$t$, $t$Na, K, Li$t$, $t$F, O, N$t$, $t$C, S, P$t$, 2, $t$FON$t$
where not exists (select 1 from quiz_questions where topic = $t$พันธะเคมี$t$ and question = $t$พันธะไฮโดรเจนเกิดระหว่างโมเลกุลที่มี H ต่อกับธาตุใดได้$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารอินทรีย์เบื้องต้น$t$, $t$แอลเคนที่มีคาร์บอน 1 อะตอมชื่อ$t$, $t$โพรเพน$t$, $t$อีเทน$t$, $t$บิวเทน$t$, $t$มีเทน$t$, 3, $t$C1 = มีเทน$t$
where not exists (select 1 from quiz_questions where topic = $t$สารอินทรีย์เบื้องต้น$t$ and question = $t$แอลเคนที่มีคาร์บอน 1 อะตอมชื่อ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารอินทรีย์เบื้องต้น$t$, $t$แอลเคนที่มีคาร์บอน 2 อะตอมชื่อ$t$, $t$อีเทน$t$, $t$บิวเทน$t$, $t$โนเนน$t$, $t$โพรเพน$t$, 0, $t$C2 = อีเทน$t$
where not exists (select 1 from quiz_questions where topic = $t$สารอินทรีย์เบื้องต้น$t$ and question = $t$แอลเคนที่มีคาร์บอน 2 อะตอมชื่อ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารอินทรีย์เบื้องต้น$t$, $t$แอลเคนที่มีคาร์บอน 3 อะตอมชื่อ$t$, $t$เดเคน$t$, $t$อีเทน$t$, $t$โพรเพน$t$, $t$มีเทน$t$, 2, $t$C3 = โพรเพน$t$
where not exists (select 1 from quiz_questions where topic = $t$สารอินทรีย์เบื้องต้น$t$ and question = $t$แอลเคนที่มีคาร์บอน 3 อะตอมชื่อ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารอินทรีย์เบื้องต้น$t$, $t$แอลเคนที่มีคาร์บอน 10 อะตอมชื่อ$t$, $t$เฮปเทน$t$, $t$มีเทน$t$, $t$เดเคน$t$, $t$โนเนน$t$, 2, $t$C10 = เดเคน$t$
where not exists (select 1 from quiz_questions where topic = $t$สารอินทรีย์เบื้องต้น$t$ and question = $t$แอลเคนที่มีคาร์บอน 10 อะตอมชื่อ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารอินทรีย์เบื้องต้น$t$, $t$สูตรโมเลกุลของมีเทนคือ$t$, $t$CH₂$t$, $t$CH₄$t$, $t$C₁H₆$t$, $t$C₁H₂$t$, 1, $t$แอลเคน CₙH₂ₙ₊₂ ; n = 1$t$
where not exists (select 1 from quiz_questions where topic = $t$สารอินทรีย์เบื้องต้น$t$ and question = $t$สูตรโมเลกุลของมีเทนคือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารอินทรีย์เบื้องต้น$t$, $t$สูตรโมเลกุลของอีเทนคือ$t$, $t$C₂H₆$t$, $t$C₂H₄$t$, $t$C₂H₂$t$, $t$C₂H₈$t$, 0, $t$แอลเคน CₙH₂ₙ₊₂ ; n = 2$t$
where not exists (select 1 from quiz_questions where topic = $t$สารอินทรีย์เบื้องต้น$t$ and question = $t$สูตรโมเลกุลของอีเทนคือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารอินทรีย์เบื้องต้น$t$, $t$สูตรโมเลกุลของบิวเทนคือ$t$, $t$C₄H₁₂$t$, $t$C₄H₁₀$t$, $t$C₄H₈$t$, $t$C₄H₆$t$, 1, $t$แอลเคน CₙH₂ₙ₊₂ ; n = 4$t$
where not exists (select 1 from quiz_questions where topic = $t$สารอินทรีย์เบื้องต้น$t$ and question = $t$สูตรโมเลกุลของบิวเทนคือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารอินทรีย์เบื้องต้น$t$, $t$สูตรโมเลกุลของเพนเทนคือ$t$, $t$C₅H₁₀$t$, $t$C₅H₁₂$t$, $t$C₅H₈$t$, $t$C₅H₁₄$t$, 1, $t$แอลเคน CₙH₂ₙ₊₂ ; n = 5$t$
where not exists (select 1 from quiz_questions where topic = $t$สารอินทรีย์เบื้องต้น$t$ and question = $t$สูตรโมเลกุลของเพนเทนคือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารอินทรีย์เบื้องต้น$t$, $t$สูตรทั่วไปของแอลไคน์คือ$t$, $t$CₙHₙ$t$, $t$CₙH₂ₙ$t$, $t$CₙH₂ₙ₋₂$t$, $t$CₙH₂ₙ₊₂$t$, 2, $t$มี C≡C$t$
where not exists (select 1 from quiz_questions where topic = $t$สารอินทรีย์เบื้องต้น$t$ and question = $t$สูตรทั่วไปของแอลไคน์คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารอินทรีย์เบื้องต้น$t$, $t$หมู่ฟังก์ชัน –OH คือสารกลุ่มใด$t$, $t$แอลดีไฮด์$t$, $t$กรดคาร์บอกซิลิก$t$, $t$แอลกอฮอล์$t$, $t$คีโตน$t$, 2, $t$–OH$t$
where not exists (select 1 from quiz_questions where topic = $t$สารอินทรีย์เบื้องต้น$t$ and question = $t$หมู่ฟังก์ชัน –OH คือสารกลุ่มใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารอินทรีย์เบื้องต้น$t$, $t$หมู่ฟังก์ชัน –COOH คือสารกลุ่มใด$t$, $t$เอสเทอร์$t$, $t$กรดคาร์บอกซิลิก$t$, $t$แอลกอฮอล์$t$, $t$อีเทอร์$t$, 1, $t$–COOH$t$
where not exists (select 1 from quiz_questions where topic = $t$สารอินทรีย์เบื้องต้น$t$ and question = $t$หมู่ฟังก์ชัน –COOH คือสารกลุ่มใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารอินทรีย์เบื้องต้น$t$, $t$หมู่ฟังก์ชัน C=O กลางสายคาร์บอน คือสารกลุ่มใด$t$, $t$แอลดีไฮด์$t$, $t$เอสเทอร์$t$, $t$แอลกอฮอล์$t$, $t$คีโตน$t$, 3, $t$C=O อยู่ระหว่าง C$t$
where not exists (select 1 from quiz_questions where topic = $t$สารอินทรีย์เบื้องต้น$t$ and question = $t$หมู่ฟังก์ชัน C=O กลางสายคาร์บอน คือสารกลุ่มใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารอินทรีย์เบื้องต้น$t$, $t$หมู่ฟังก์ชัน –COO– คือสารกลุ่มใด$t$, $t$กรดคาร์บอกซิลิก$t$, $t$เอสเทอร์$t$, $t$เอไมด์$t$, $t$อีเทอร์$t$, 1, $t$กลิ่นหอมผลไม้$t$
where not exists (select 1 from quiz_questions where topic = $t$สารอินทรีย์เบื้องต้น$t$ and question = $t$หมู่ฟังก์ชัน –COO– คือสารกลุ่มใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารอินทรีย์เบื้องต้น$t$, $t$หมู่ฟังก์ชัน –O– (เชื่อมสองหมู่แอลคิล) คือสารกลุ่มใด$t$, $t$แอลกอฮอล์$t$, $t$เอสเทอร์$t$, $t$อีเทอร์$t$, $t$คีโตน$t$, 2, $t$R–O–R$t$
where not exists (select 1 from quiz_questions where topic = $t$สารอินทรีย์เบื้องต้น$t$ and question = $t$หมู่ฟังก์ชัน –O– (เชื่อมสองหมู่แอลคิล) คือสารกลุ่มใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารอินทรีย์เบื้องต้น$t$, $t$หมู่ฟังก์ชัน –NH₂ คือสารกลุ่มใด$t$, $t$เอมีน$t$, $t$เอสเทอร์$t$, $t$แอลดีไฮด์$t$, $t$แอลกอฮอล์$t$, 0, $t$มีไนโตรเจน$t$
where not exists (select 1 from quiz_questions where topic = $t$สารอินทรีย์เบื้องต้น$t$ and question = $t$หมู่ฟังก์ชัน –NH₂ คือสารกลุ่มใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารอินทรีย์เบื้องต้น$t$, $t$สารที่มีพันธะสาม C≡C คือสารกลุ่มใด$t$, $t$แอลคีน$t$, $t$แอลเคน$t$, $t$แอลไคน์$t$, $t$แอลกอฮอล์$t$, 2, $t$ไม่อิ่มตัว$t$
where not exists (select 1 from quiz_questions where topic = $t$สารอินทรีย์เบื้องต้น$t$ and question = $t$สารที่มีพันธะสาม C≡C คือสารกลุ่มใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารอินทรีย์เบื้องต้น$t$, $t$เอทานอล (C₂H₅OH) เป็นสารกลุ่มใด$t$, $t$แอลคีน$t$, $t$กรดคาร์บอกซิลิก$t$, $t$แอลกอฮอล์$t$, $t$เอสเทอร์$t$, 2, $t$หมู่ –OH$t$
where not exists (select 1 from quiz_questions where topic = $t$สารอินทรีย์เบื้องต้น$t$ and question = $t$เอทานอล (C₂H₅OH) เป็นสารกลุ่มใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารอินทรีย์เบื้องต้น$t$, $t$กรดแอซีติกเป็นสารกลุ่มใด$t$, $t$แอลกอฮอล์$t$, $t$เอสเทอร์$t$, $t$กรดคาร์บอกซิลิก$t$, $t$แอลดีไฮด์$t$, 2, $t$CH₃COOH$t$
where not exists (select 1 from quiz_questions where topic = $t$สารอินทรีย์เบื้องต้น$t$ and question = $t$กรดแอซีติกเป็นสารกลุ่มใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารอินทรีย์เบื้องต้น$t$, $t$กรดฟอร์มิก (HCOOH) พบในสิ่งใด$t$, $t$นมเปรี้ยว$t$, $t$พิษมดและแมลงบางชนิด$t$, $t$น้ำส้มสายชู$t$, $t$ผลไม้ตระกูลส้ม$t$, 1, $t$กรดมด$t$
where not exists (select 1 from quiz_questions where topic = $t$สารอินทรีย์เบื้องต้น$t$ and question = $t$กรดฟอร์มิก (HCOOH) พบในสิ่งใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารอินทรีย์เบื้องต้น$t$, $t$พอลิเมอร์คืออะไร$t$, $t$ไอออนบวก$t$, $t$สารโมเลกุลเดี่ยว$t$, $t$แก๊สเฉื่อย$t$, $t$สารโมเลกุลใหญ่เกิดจากมอนอเมอร์ต่อกัน$t$, 3, $t$มอนอเมอร์ → พอลิเมอร์$t$
where not exists (select 1 from quiz_questions where topic = $t$สารอินทรีย์เบื้องต้น$t$ and question = $t$พอลิเมอร์คืออะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารอินทรีย์เบื้องต้น$t$, $t$พอลิเอทิลีน (PE) ผลิตจากมอนอเมอร์ใด$t$, $t$เอทีน (เอทิลีน)$t$, $t$เอไทน์$t$, $t$โพรพีน$t$, $t$มีเทน$t$, 0, $t$ถุงพลาสติก$t$
where not exists (select 1 from quiz_questions where topic = $t$สารอินทรีย์เบื้องต้น$t$ and question = $t$พอลิเอทิลีน (PE) ผลิตจากมอนอเมอร์ใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารอินทรีย์เบื้องต้น$t$, $t$แป้งและเซลลูโลสเป็นพอลิเมอร์ของสารใด$t$, $t$เอทิลีน$t$, $t$กลูโคส$t$, $t$กรดอะมิโน$t$, $t$กลีเซอรอล$t$, 1, $t$คาร์โบไฮเดรต$t$
where not exists (select 1 from quiz_questions where topic = $t$สารอินทรีย์เบื้องต้น$t$ and question = $t$แป้งและเซลลูโลสเป็นพอลิเมอร์ของสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารอินทรีย์เบื้องต้น$t$, $t$โปรตีนเป็นพอลิเมอร์ของสารใด$t$, $t$เอทิลีน$t$, $t$กรดอะมิโน$t$, $t$กรดไขมัน$t$, $t$กลูโคส$t$, 1, $t$พันธะเพปไทด์$t$
where not exists (select 1 from quiz_questions where topic = $t$สารอินทรีย์เบื้องต้น$t$ and question = $t$โปรตีนเป็นพอลิเมอร์ของสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารอินทรีย์เบื้องต้น$t$, $t$ยางธรรมชาติเป็นพอลิเมอร์ของสารใด$t$, $t$กรดอะมิโน$t$, $t$กลูโคส$t$, $t$เอทิลีน$t$, $t$ไอโซพรีน$t$, 3, $t$พอลิไอโซพรีน$t$
where not exists (select 1 from quiz_questions where topic = $t$สารอินทรีย์เบื้องต้น$t$ and question = $t$ยางธรรมชาติเป็นพอลิเมอร์ของสารใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$สารอินทรีย์เบื้องต้น$t$, $t$น้ำมันดิบแยกเป็นส่วนต่างๆ ด้วยวิธีใด$t$, $t$การกลั่นลำดับส่วน$t$, $t$การกรอง$t$, $t$การตกผลึก$t$, $t$การระเหิด$t$, 0, $t$ต่างจุดเดือด$t$
where not exists (select 1 from quiz_questions where topic = $t$สารอินทรีย์เบื้องต้น$t$ and question = $t$น้ำมันดิบแยกเป็นส่วนต่างๆ ด้วยวิธีใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขออกซิเดชันและปฏิกิริยา$t$, $t$เลขออกซิเดชันของ Na ใน NaCl คือ$t$, $t$−1$t$, $t$+6$t$, $t$+1$t$, $t$−4$t$, 2, $t$Na ใน NaCl = +1$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขออกซิเดชันและปฏิกิริยา$t$ and question = $t$เลขออกซิเดชันของ Na ใน NaCl คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขออกซิเดชันและปฏิกิริยา$t$, $t$เลขออกซิเดชันของ Cl ใน NaCl คือ$t$, $t$+7$t$, $t$−1$t$, $t$0$t$, $t$+5$t$, 1, $t$Cl ใน NaCl = −1$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขออกซิเดชันและปฏิกิริยา$t$ and question = $t$เลขออกซิเดชันของ Cl ใน NaCl คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขออกซิเดชันและปฏิกิริยา$t$, $t$เลขออกซิเดชันของ S ใน H₂SO₄ คือ$t$, $t$+3$t$, $t$−3$t$, $t$+6$t$, $t$−1$t$, 2, $t$S ใน H₂SO₄ = +6$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขออกซิเดชันและปฏิกิริยา$t$ and question = $t$เลขออกซิเดชันของ S ใน H₂SO₄ คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขออกซิเดชันและปฏิกิริยา$t$, $t$เลขออกซิเดชันของ N ใน NH₃ คือ$t$, $t$−1$t$, $t$−3$t$, $t$+6$t$, $t$+3$t$, 1, $t$N ใน NH₃ = −3$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขออกซิเดชันและปฏิกิริยา$t$ and question = $t$เลขออกซิเดชันของ N ใน NH₃ คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขออกซิเดชันและปฏิกิริยา$t$, $t$เลขออกซิเดชันของ N ใน NO₂ คือ$t$, $t$+4$t$, $t$−2$t$, $t$+6$t$, $t$0$t$, 0, $t$N ใน NO₂ = +4$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขออกซิเดชันและปฏิกิริยา$t$ and question = $t$เลขออกซิเดชันของ N ใน NO₂ คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขออกซิเดชันและปฏิกิริยา$t$, $t$เลขออกซิเดชันของ Mn ใน KMnO₄ คือ$t$, $t$+3$t$, $t$+6$t$, $t$+7$t$, $t$+5$t$, 2, $t$Mn ใน KMnO₄ = +7$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขออกซิเดชันและปฏิกิริยา$t$ and question = $t$เลขออกซิเดชันของ Mn ใน KMnO₄ คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขออกซิเดชันและปฏิกิริยา$t$, $t$เลขออกซิเดชันของ Fe ใน Fe₂O₃ คือ$t$, $t$+7$t$, $t$0$t$, $t$+5$t$, $t$+3$t$, 3, $t$Fe ใน Fe₂O₃ = +3$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขออกซิเดชันและปฏิกิริยา$t$ and question = $t$เลขออกซิเดชันของ Fe ใน Fe₂O₃ คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขออกซิเดชันและปฏิกิริยา$t$, $t$เลขออกซิเดชันของ Mg ใน MgO คือ$t$, $t$+3$t$, $t$−2$t$, $t$+2$t$, $t$+7$t$, 2, $t$Mg ใน MgO = +2$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขออกซิเดชันและปฏิกิริยา$t$ and question = $t$เลขออกซิเดชันของ Mg ใน MgO คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขออกซิเดชันและปฏิกิริยา$t$, $t$เลขออกซิเดชันของ Al ใน Al₂O₃ คือ$t$, $t$+1$t$, $t$0$t$, $t$+3$t$, $t$−1$t$, 2, $t$Al ใน Al₂O₃ = +3$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขออกซิเดชันและปฏิกิริยา$t$ and question = $t$เลขออกซิเดชันของ Al ใน Al₂O₃ คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขออกซิเดชันและปฏิกิริยา$t$, $t$เลขออกซิเดชันของ C ใน CH₄ คือ$t$, $t$−1$t$, $t$−4$t$, $t$+4$t$, $t$−2$t$, 1, $t$C ใน CH₄ = −4$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขออกซิเดชันและปฏิกิริยา$t$ and question = $t$เลขออกซิเดชันของ C ใน CH₄ คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขออกซิเดชันและปฏิกิริยา$t$, $t$เลขออกซิเดชันของ Cl ใน HClO₄ คือ$t$, $t$+7$t$, $t$+1$t$, $t$+5$t$, $t$+6$t$, 0, $t$Cl ใน HClO₄ = +7$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขออกซิเดชันและปฏิกิริยา$t$ and question = $t$เลขออกซิเดชันของ Cl ใน HClO₄ คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขออกซิเดชันและปฏิกิริยา$t$, $t$ปฏิกิริยารีดอกซ์คือปฏิกิริยาที่มีอะไรเกิดขึ้น$t$, $t$ไม่มีการเปลี่ยนแปลง$t$, $t$การถ่ายโอนโปรตอนเท่านั้น$t$, $t$การถ่ายโอนอิเล็กตรอน$t$, $t$การถ่ายโอนนิวตรอน$t$, 2, $t$ออกซิเดชัน + รีดักชัน$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขออกซิเดชันและปฏิกิริยา$t$ and question = $t$ปฏิกิริยารีดอกซ์คือปฏิกิริยาที่มีอะไรเกิดขึ้น$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขออกซิเดชันและปฏิกิริยา$t$, $t$ตัวออกซิไดส์ (oxidizing agent) คือสารที่$t$, $t$ให้อิเล็กตรอน$t$, $t$เป็นตัวเร่ง$t$, $t$ไม่ทำปฏิกิริยา$t$, $t$รับอิเล็กตรอน (ถูกรีดิวซ์)$t$, 3, $t$ทำให้สารอื่นถูกออกซิไดส์$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขออกซิเดชันและปฏิกิริยา$t$ and question = $t$ตัวออกซิไดส์ (oxidizing agent) คือสารที่$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขออกซิเดชันและปฏิกิริยา$t$, $t$OIL RIG หมายถึง$t$, $t$Oxidation Is Loss, Reduction Is Gain$t$, $t$Oxide Is Light$t$, $t$Only Ions Lose$t$, $t$Oxygen In Liquid$t$, 0, $t$ออกซิเดชัน = สูญเสีย e⁻$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขออกซิเดชันและปฏิกิริยา$t$ and question = $t$OIL RIG หมายถึง$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขออกซิเดชันและปฏิกิริยา$t$, $t$การเผาไหม้สมบูรณ์ของไฮโดรคาร์บอนให้ผลิตภัณฑ์$t$, $t$CO และ H₂$t$, $t$CO และ O₂$t$, $t$CO₂ และ H₂O$t$, $t$C และ H₂O$t$, 2, $t$ออกซิเจนเพียงพอ$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขออกซิเดชันและปฏิกิริยา$t$ and question = $t$การเผาไหม้สมบูรณ์ของไฮโดรคาร์บอนให้ผลิตภัณฑ์$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขออกซิเดชันและปฏิกิริยา$t$, $t$ปฏิกิริยาดูดความร้อนทำให้สิ่งแวดล้อมเป็นอย่างไร$t$, $t$อุณหภูมิสูงขึ้น$t$, $t$เกิดไฟลุก$t$, $t$อุณหภูมิลดลง$t$, $t$ไม่เปลี่ยน$t$, 2, $t$ดูดพลังงาน$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขออกซิเดชันและปฏิกิริยา$t$ and question = $t$ปฏิกิริยาดูดความร้อนทำให้สิ่งแวดล้อมเป็นอย่างไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขออกซิเดชันและปฏิกิริยา$t$, $t$ตัวเร่งปฏิกิริยาทำหน้าที่อะไร$t$, $t$เพิ่มอัตราปฏิกิริยาโดยไม่ถูกใช้หมด$t$, $t$เพิ่มปริมาณผลิตภัณฑ์เสมอ$t$, $t$ถูกใช้จนหมด$t$, $t$ลดอุณหภูมิ$t$, 0, $t$ลดพลังงานก่อกัมมันต์$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขออกซิเดชันและปฏิกิริยา$t$ and question = $t$ตัวเร่งปฏิกิริยาทำหน้าที่อะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขออกซิเดชันและปฏิกิริยา$t$, $t$การเพิ่มอุณหภูมิมักทำให้อัตราปฏิกิริยา$t$, $t$หยุด$t$, $t$เท่าเดิม$t$, $t$ลดลง$t$, $t$เพิ่มขึ้น$t$, 3, $t$ชนกันบ่อยและแรงขึ้น$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขออกซิเดชันและปฏิกิริยา$t$ and question = $t$การเพิ่มอุณหภูมิมักทำให้อัตราปฏิกิริยา$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขออกซิเดชันและปฏิกิริยา$t$, $t$2Mg + O₂ → ?MgO สัมประสิทธิ์ของ MgO คือ$t$, $t$3$t$, $t$1$t$, $t$2$t$, $t$4$t$, 2, $t$2Mg + O₂ → 2MgO$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขออกซิเดชันและปฏิกิริยา$t$ and question = $t$2Mg + O₂ → ?MgO สัมประสิทธิ์ของ MgO คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขออกซิเดชันและปฏิกิริยา$t$, $t$2KClO₃ → 2KCl + ?O₂ สัมประสิทธิ์ของ O₂ คือ$t$, $t$4$t$, $t$1$t$, $t$3$t$, $t$2$t$, 2, $t$O 6 อะตอม$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขออกซิเดชันและปฏิกิริยา$t$ and question = $t$2KClO₃ → 2KCl + ?O₂ สัมประสิทธิ์ของ O₂ คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขออกซิเดชันและปฏิกิริยา$t$, $t$2Na + 2H₂O → 2NaOH + ?H₂ สัมประสิทธิ์ของ H₂ คือ$t$, $t$4$t$, $t$2$t$, $t$1$t$, $t$3$t$, 2, $t$H₂ 1 โมเลกุล$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขออกซิเดชันและปฏิกิริยา$t$ and question = $t$2Na + 2H₂O → 2NaOH + ?H₂ สัมประสิทธิ์ของ H₂ คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขออกซิเดชันและปฏิกิริยา$t$, $t$Fe₂O₃ + ?CO → 2Fe + 3CO₂ สัมประสิทธิ์ของ CO คือ$t$, $t$4$t$, $t$1$t$, $t$2$t$, $t$3$t$, 3, $t$ได้ CO₂ 3 โมเลกุล$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขออกซิเดชันและปฏิกิริยา$t$ and question = $t$Fe₂O₃ + ?CO → 2Fe + 3CO₂ สัมประสิทธิ์ของ CO คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขออกซิเดชันและปฏิกิริยา$t$, $t$กฎทรงมวลระบุว่า$t$, $t$มวลหลังปฏิกิริยามากกว่าเสมอ$t$, $t$มวลรวมก่อนและหลังปฏิกิริยาเท่ากัน$t$, $t$มวลก่อนมากกว่าเสมอ$t$, $t$มวลหายไปเมื่อเกิดแก๊ส$t$, 1, $t$Lavoisier$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขออกซิเดชันและปฏิกิริยา$t$ and question = $t$กฎทรงมวลระบุว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขออกซิเดชันและปฏิกิริยา$t$, $t$การสังเคราะห์ด้วยแสงใช้สารตั้งต้นใด$t$, $t$O₂ และ H₂O$t$, $t$CO และ O₂$t$, $t$N₂ และ H₂$t$, $t$CO₂ และ H₂O$t$, 3, $t$ได้กลูโคสกับ O₂$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขออกซิเดชันและปฏิกิริยา$t$ and question = $t$การสังเคราะห์ด้วยแสงใช้สารตั้งต้นใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$เลขออกซิเดชันและปฏิกิริยา$t$, $t$ผลิตภัณฑ์ของการสังเคราะห์ด้วยแสงคือ$t$, $t$กลูโคสและออกซิเจน$t$, $t$CO₂ และน้ำ$t$, $t$เอทานอลและ CO₂$t$, $t$แป้งและ N₂$t$, 0, $t$ใช้แสงเป็นพลังงาน$t$
where not exists (select 1 from quiz_questions where topic = $t$เลขออกซิเดชันและปฏิกิริยา$t$ and question = $t$ผลิตภัณฑ์ของการสังเคราะห์ด้วยแสงคือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความรู้เคมีรอบตัว$t$, $t$แก๊สเป็นของแข็งโดยตรงเรียกว่า$t$, $t$การต้ม$t$, $t$การหลอมเหลว$t$, $t$การระเหิดกลับ (การจับแข็ง)$t$, $t$การระเหย$t$, 2, $t$เช่น น้ำค้างแข็ง$t$
where not exists (select 1 from quiz_questions where topic = $t$ความรู้เคมีรอบตัว$t$ and question = $t$แก๊สเป็นของแข็งโดยตรงเรียกว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความรู้เคมีรอบตัว$t$, $t$ของเหลวเป็นแก๊สที่ผิวหน้าของเหลวเรียกว่า$t$, $t$การเดือด$t$, $t$การระเหย$t$, $t$การระเหิด$t$, $t$การควบแน่น$t$, 1, $t$ที่ผิวหน้าเท่านั้น$t$
where not exists (select 1 from quiz_questions where topic = $t$ความรู้เคมีรอบตัว$t$ and question = $t$ของเหลวเป็นแก๊สที่ผิวหน้าของเหลวเรียกว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความรู้เคมีรอบตัว$t$, $t$อนุภาคในของแข็งเคลื่อนที่อย่างไร$t$, $t$สั่นอยู่กับที่$t$, $t$ไหลได้$t$, $t$เคลื่อนที่อิสระ$t$, $t$หยุดนิ่ง$t$, 0, $t$เรียงชิดกัน$t$
where not exists (select 1 from quiz_questions where topic = $t$ความรู้เคมีรอบตัว$t$ and question = $t$อนุภาคในของแข็งเคลื่อนที่อย่างไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความรู้เคมีรอบตัว$t$, $t$อนุภาคในแก๊สอยู่ห่างกันมากหรือน้อย$t$, $t$ห่างกันมาก$t$, $t$ชิดกันมาก$t$, $t$เรียงเป็นระเบียบ$t$, $t$ไม่เคลื่อนที่$t$, 0, $t$เคลื่อนที่เร็วอิสระ$t$
where not exists (select 1 from quiz_questions where topic = $t$ความรู้เคมีรอบตัว$t$ and question = $t$อนุภาคในแก๊สอยู่ห่างกันมากหรือน้อย$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความรู้เคมีรอบตัว$t$, $t$สารบริสุทธิ์มีจุดเดือดเป็นอย่างไร$t$, $t$ไม่มีจุดเดือด$t$, $t$เปลี่ยนไปเรื่อยๆ$t$, $t$ต่ำลงเรื่อยๆ$t$, $t$คงที่$t$, 3, $t$อุณหภูมิคงที่ขณะเดือด$t$
where not exists (select 1 from quiz_questions where topic = $t$ความรู้เคมีรอบตัว$t$ and question = $t$สารบริสุทธิ์มีจุดเดือดเป็นอย่างไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความรู้เคมีรอบตัว$t$, $t$สารละลายประกอบด้วยตัวทำละลายและอะไร$t$, $t$ตัวละลาย$t$, $t$ตะกอน$t$, $t$ตัวเร่ง$t$, $t$ไอออนเท่านั้น$t$, 0, $t$เช่น น้ำ + เกลือ$t$
where not exists (select 1 from quiz_questions where topic = $t$ความรู้เคมีรอบตัว$t$ and question = $t$สารละลายประกอบด้วยตัวทำละลายและอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความรู้เคมีรอบตัว$t$, $t$สารผสมที่ไม่สม่ำเสมอ เช่น น้ำโคลน เรียกว่า$t$, $t$สารบริสุทธิ์$t$, $t$สารเนื้อผสม$t$, $t$ธาตุ$t$, $t$สารละลาย$t$, 1, $t$แยกชนิดได้ด้วยตา$t$
where not exists (select 1 from quiz_questions where topic = $t$ความรู้เคมีรอบตัว$t$ and question = $t$สารผสมที่ไม่สม่ำเสมอ เช่น น้ำโคลน เรียกว่า$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความรู้เคมีรอบตัว$t$, $t$ธาตุและสารประกอบจัดเป็นสารประเภทใด$t$, $t$คอลลอยด์$t$, $t$สารผสม$t$, $t$สารบริสุทธิ์$t$, $t$สารละลายเสมอ$t$, 2, $t$ส่วนประกอบแน่นอน$t$
where not exists (select 1 from quiz_questions where topic = $t$ความรู้เคมีรอบตัว$t$ and question = $t$ธาตุและสารประกอบจัดเป็นสารประเภทใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความรู้เคมีรอบตัว$t$, $t$น้ำมันกับน้ำแยกกันด้วย$t$, $t$การตกผลึก$t$, $t$กรวยกรอง$t$, $t$กรวยแยก$t$, $t$การระเหิด$t$, 2, $t$ไม่ผสมกัน$t$
where not exists (select 1 from quiz_questions where topic = $t$ความรู้เคมีรอบตัว$t$ and question = $t$น้ำมันกับน้ำแยกกันด้วย$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความรู้เคมีรอบตัว$t$, $t$แยกเกลือจากน้ำเกลือได้โดยวิธี$t$, $t$การใช้แม่เหล็ก$t$, $t$ใช้กรวยแยก$t$, $t$การระเหยแห้ง$t$, $t$การกรอง$t$, 2, $t$ระเหยน้ำออก$t$
where not exists (select 1 from quiz_questions where topic = $t$ความรู้เคมีรอบตัว$t$ and question = $t$แยกเกลือจากน้ำเกลือได้โดยวิธี$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความรู้เคมีรอบตัว$t$, $t$แยกน้ำออกจากน้ำเกลือเพื่อเก็บน้ำบริสุทธิ์ใช้วิธี$t$, $t$การกลั่น$t$, $t$การตกผลึก$t$, $t$การกรอง$t$, $t$ใช้แม่เหล็ก$t$, 0, $t$ต้มแล้วควบแน่น$t$
where not exists (select 1 from quiz_questions where topic = $t$ความรู้เคมีรอบตัว$t$ and question = $t$แยกน้ำออกจากน้ำเกลือเพื่อเก็บน้ำบริสุทธิ์ใช้วิธี$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความรู้เคมีรอบตัว$t$, $t$แยกสีหมึกในปากกาด้วยวิธี$t$, $t$การกลั่น$t$, $t$การกรอง$t$, $t$โครมาโทกราฟี$t$, $t$การระเหย$t$, 2, $t$ต่างอัตราการเคลื่อนที่$t$
where not exists (select 1 from quiz_questions where topic = $t$ความรู้เคมีรอบตัว$t$ and question = $t$แยกสีหมึกในปากกาด้วยวิธี$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความรู้เคมีรอบตัว$t$, $t$แก๊สที่ทำให้น้ำปูนใสขุ่นคือ$t$, $t$CO₂$t$, $t$O₂$t$, $t$N₂$t$, $t$H₂$t$, 0, $t$เกิด CaCO₃$t$
where not exists (select 1 from quiz_questions where topic = $t$ความรู้เคมีรอบตัว$t$ and question = $t$แก๊สที่ทำให้น้ำปูนใสขุ่นคือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความรู้เคมีรอบตัว$t$, $t$แก๊สโอโซนช่วยป้องกันอะไรจากดวงอาทิตย์$t$, $t$ลม$t$, $t$รังสี UV$t$, $t$รังสีแกมมา$t$, $t$ความร้อน$t$, 1, $t$ชั้นสตราโตสเฟียร์$t$
where not exists (select 1 from quiz_questions where topic = $t$ความรู้เคมีรอบตัว$t$ and question = $t$แก๊สโอโซนช่วยป้องกันอะไรจากดวงอาทิตย์$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความรู้เคมีรอบตัว$t$, $t$ไอโอดีนช่วยป้องกันโรคอะไร$t$, $t$คอพอก$t$, $t$ฟันผุ$t$, $t$โลหิตจาง$t$, $t$กระดูกพรุน$t$, 0, $t$ต่อมไทรอยด์$t$
where not exists (select 1 from quiz_questions where topic = $t$ความรู้เคมีรอบตัว$t$ and question = $t$ไอโอดีนช่วยป้องกันโรคอะไร$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความรู้เคมีรอบตัว$t$, $t$ธาตุหลักในกระดูกและฟันคือ$t$, $t$เหล็ก$t$, $t$แคลเซียม$t$, $t$โซเดียม$t$, $t$ทองแดง$t$, 1, $t$Ca$t$
where not exists (select 1 from quiz_questions where topic = $t$ความรู้เคมีรอบตัว$t$ and question = $t$ธาตุหลักในกระดูกและฟันคือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความรู้เคมีรอบตัว$t$, $t$ธาตุในฮีโมโกลบินของเลือดคือ$t$, $t$สังกะสี$t$, $t$แคลเซียม$t$, $t$ทองแดง$t$, $t$เหล็ก$t$, 3, $t$Fe ขนส่งออกซิเจน$t$
where not exists (select 1 from quiz_questions where topic = $t$ความรู้เคมีรอบตัว$t$ and question = $t$ธาตุในฮีโมโกลบินของเลือดคือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความรู้เคมีรอบตัว$t$, $t$โลหะที่นำไฟฟ้าดีที่สุดคือ$t$, $t$เงิน$t$, $t$เหล็ก$t$, $t$ทองคำ$t$, $t$ทองแดง$t$, 0, $t$Ag$t$
where not exists (select 1 from quiz_questions where topic = $t$ความรู้เคมีรอบตัว$t$ and question = $t$โลหะที่นำไฟฟ้าดีที่สุดคือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความรู้เคมีรอบตัว$t$, $t$ธาตุที่เบาที่สุดคือ$t$, $t$ลิเทียม$t$, $t$ฮีเลียม$t$, $t$ไฮโดรเจน$t$, $t$คาร์บอน$t$, 2, $t$Z = 1$t$
where not exists (select 1 from quiz_questions where topic = $t$ความรู้เคมีรอบตัว$t$ and question = $t$ธาตุที่เบาที่สุดคือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความรู้เคมีรอบตัว$t$, $t$โลหะที่เบาที่สุดคือ$t$, $t$โซเดียม$t$, $t$อะลูมิเนียม$t$, $t$ตะกั่ว$t$, $t$ลิเทียม$t$, 3, $t$Li$t$
where not exists (select 1 from quiz_questions where topic = $t$ความรู้เคมีรอบตัว$t$ and question = $t$โลหะที่เบาที่สุดคือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความรู้เคมีรอบตัว$t$, $t$ธาตุกึ่งโลหะที่ใช้ทำชิปคอมพิวเตอร์คือ$t$, $t$ซิลิคอน$t$, $t$ทองแดง$t$, $t$คาร์บอน$t$, $t$เหล็ก$t$, 0, $t$Si$t$
where not exists (select 1 from quiz_questions where topic = $t$ความรู้เคมีรอบตัว$t$ and question = $t$ธาตุกึ่งโลหะที่ใช้ทำชิปคอมพิวเตอร์คือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความรู้เคมีรอบตัว$t$, $t$โลหะแอลคาไลเมื่อทำปฏิกิริยากับน้ำได้แก๊สใด$t$, $t$ไฮโดรเจน$t$, $t$คลอรีน$t$, $t$ไนโตรเจน$t$, $t$ออกซิเจน$t$, 0, $t$และได้สารละลายเบส$t$
where not exists (select 1 from quiz_questions where topic = $t$ความรู้เคมีรอบตัว$t$ and question = $t$โลหะแอลคาไลเมื่อทำปฏิกิริยากับน้ำได้แก๊สใด$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความรู้เคมีรอบตัว$t$, $t$แฮโลเจนที่เป็นแก๊สสีเขียวอมเหลืองคือ$t$, $t$คลอรีน$t$, $t$โบรมีน$t$, $t$ฟลูออรีน$t$, $t$ไอโอดีน$t$, 0, $t$Cl₂$t$
where not exists (select 1 from quiz_questions where topic = $t$ความรู้เคมีรอบตัว$t$ and question = $t$แฮโลเจนที่เป็นแก๊สสีเขียวอมเหลืองคือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความรู้เคมีรอบตัว$t$, $t$แฮโลเจนที่เป็นของเหลวสีน้ำตาลแดงคือ$t$, $t$ฟลูออรีน$t$, $t$คลอรีน$t$, $t$โบรมีน$t$, $t$ไอโอดีน$t$, 2, $t$Br₂$t$
where not exists (select 1 from quiz_questions where topic = $t$ความรู้เคมีรอบตัว$t$ and question = $t$แฮโลเจนที่เป็นของเหลวสีน้ำตาลแดงคือ$t$);
insert into quiz_questions (topic, question, a, b, c, d, answer, explain)
select $t$ความรู้เคมีรอบตัว$t$, $t$ธาตุที่อิเล็กโทรเนกาทิวิตีสูงที่สุดคือ$t$, $t$ฟลูออรีน$t$, $t$ไนโตรเจน$t$, $t$คลอรีน$t$, $t$ออกซิเจน$t$, 0, $t$F$t$
where not exists (select 1 from quiz_questions where topic = $t$ความรู้เคมีรอบตัว$t$ and question = $t$ธาตุที่อิเล็กโทรเนกาทิวิตีสูงที่สุดคือ$t$);
