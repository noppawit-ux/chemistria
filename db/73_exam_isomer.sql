-- 73: ข้อสอบหัวข้อ “ไอโซเมอร์” (โครงสร้าง + สเตอริโอ) — ต้องรัน 72 ก่อน · รันซ้ำได้ (ไม่เพิ่มข้อซ้ำ)
-- รูปโครงสร้างอยู่ที่ assets/exam/isomer/ (สร้างด้วย tools/make_isomer_imgs.py)

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$mcq$j$, $j$แอลเคนสูตรโมเลกุล C4H10 มีไอโซเมอร์โครงสร้างกี่แบบ$j$, null, $j${"choices": [{"t": "1 แบบ"}, {"t": "2 แบบ"}, {"t": "3 แบบ"}, {"t": "4 แบบ"}], "answer": 1}$j$::jsonb, 1, $j$C4H10 มี 2 แบบ คือ บิวเทน (โซ่ตรง) และ 2-เมทิลโพรเพน (โซ่กิ่ง)$j$, $j$assets/exam/isomer/p_chain.png$j$
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$แอลเคนสูตรโมเลกุล C4H10 มีไอโซเมอร์โครงสร้างกี่แบบ$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$mcq$j$, $j$แอลเคนสูตรโมเลกุล C5H12 มีไอโซเมอร์โครงสร้างกี่แบบ$j$, null, $j${"choices": [{"t": "2 แบบ"}, {"t": "3 แบบ"}, {"t": "4 แบบ"}, {"t": "5 แบบ"}], "answer": 1}$j$::jsonb, 1, $j$C5H12 มี 3 แบบ: เพนเทน, 2-เมทิลบิวเทน และ 2,2-ไดเมทิลโพรเพน$j$, $j$assets/exam/isomer/pentane.png$j$
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$แอลเคนสูตรโมเลกุล C5H12 มีไอโซเมอร์โครงสร้างกี่แบบ$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$mcq$j$, $j$สารคู่ในรูปเป็นไอโซเมอร์โครงสร้างชนิดใด$j$, $j$assets/exam/isomer/p_pos.png$j$, $j${"choices": [{"t": "โซ่คาร์บอน"}, {"t": "ตำแหน่งหมู่ฟังก์ชัน"}, {"t": "หมู่ฟังก์ชัน"}, {"t": "เรขาคณิต (cis-trans)"}], "answer": 1}$j$::jsonb, 1, $j$1-โพรพานอลและ 2-โพรพานอล มีหมู่ -OH เหมือนกันแต่ติดคนละตำแหน่ง จึงเป็นไอโซเมอร์ตำแหน่ง$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$สารคู่ในรูปเป็นไอโซเมอร์โครงสร้างชนิดใด$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$mcq$j$, $j$เอทานอล (CH3CH2OH) กับไดเมทิลอีเทอร์ (CH3OCH3) เป็นไอโซเมอร์ชนิดใด$j$, $j$assets/exam/isomer/p_func.png$j$, $j${"choices": [{"t": "โซ่คาร์บอน"}, {"t": "ตำแหน่งหมู่ฟังก์ชัน"}, {"t": "หมู่ฟังก์ชัน"}, {"t": "เรขาคณิต (cis-trans)"}], "answer": 2}$j$::jsonb, 1, $j$สูตรโมเลกุลเดียวกัน (C2H6O) แต่มีหมู่ฟังก์ชันต่างกัน (แอลกอฮอล์ vs อีเทอร์)$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$เอทานอล (CH3CH2OH) กับไดเมทิลอีเทอร์ (CH3OCH3) เป็นไอโซเมอร์ชนิดใด$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$mcq$j$, $j$บิวเทนกับ 2-เมทิลโพรเพน (ในรูป) เป็นไอโซเมอร์ชนิดใด$j$, $j$assets/exam/isomer/p_chain.png$j$, $j${"choices": [{"t": "โซ่คาร์บอน"}, {"t": "ตำแหน่งหมู่ฟังก์ชัน"}, {"t": "หมู่ฟังก์ชัน"}, {"t": "เรขาคณิต (cis-trans)"}], "answer": 0}$j$::jsonb, 1, $j$ต่างกันที่การจัดเรียงโซ่คาร์บอน (โซ่ตรง vs โซ่กิ่ง)$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$บิวเทนกับ 2-เมทิลโพรเพน (ในรูป) เป็นไอโซเมอร์ชนิดใด$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$mcq$j$, $j$สารในข้อใดแสดงไอโซเมอร์เรขาคณิต (cis-trans) ได้$j$, null, $j${"choices": [{"t": "", "img": "assets/exam/isomer/propene.png"}, {"t": "", "img": "assets/exam/isomer/isobutene.png"}, {"t": "", "img": "assets/exam/isomer/cis2butene.png"}, {"t": "", "img": "assets/exam/isomer/11dce.png"}], "answer": 2}$j$::jsonb, 1, $j$ต้องมี C=C ที่คาร์บอนแต่ละตัวต่อกับหมู่ที่ต่างกัน 2 หมู่ — บิวต์-2-อีนตรงเงื่อนไข ส่วนโพรพีน, 2-เมทิลโพรพีน และ 1,1-ไดคลอโรเอทีน มีคาร์บอนข้างหนึ่งต่อกับหมู่เหมือนกัน$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$สารในข้อใดแสดงไอโซเมอร์เรขาคณิต (cis-trans) ได้$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$mcq$j$, $j$สารในข้อใดมีคาร์บอนไครัล (chiral carbon)$j$, null, $j${"choices": [{"t": "", "img": "assets/exam/isomer/ethanol.png"}, {"t": "", "img": "assets/exam/isomer/2propanol.png"}, {"t": "", "img": "assets/exam/isomer/2butanol.png"}, {"t": "", "img": "assets/exam/isomer/3pentanol.png"}], "answer": 2}$j$::jsonb, 1, $j$C2 ของ 2-บิวทานอลต่อกับ 4 หมู่ต่างกัน: -OH, -H, -CH3, -CH2CH3$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$สารในข้อใดมีคาร์บอนไครัล (chiral carbon)$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$mcq$j$, $j$สารสูตร C4H8 มีไอโซเมอร์โครงสร้าง (นับรวมโครงสร้างวงแหวน แต่ไม่นับ cis-trans) กี่แบบ$j$, null, $j${"choices": [{"t": "3 แบบ"}, {"t": "4 แบบ"}, {"t": "5 แบบ"}, {"t": "6 แบบ"}], "answer": 2}$j$::jsonb, 2, $j$บิวต์-1-อีน, บิวต์-2-อีน, 2-เมทิลโพรพีน, ไซโคลบิวเทน, เมทิลไซโคลโพรเพน = 5 แบบ (ถ้านับ cis/trans แยก จะเป็น 6 สเตอริโอไอโซเมอร์)$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$สารสูตร C4H8 มีไอโซเมอร์โครงสร้าง (นับรวมโครงสร้างวงแหวน แต่ไม่นับ cis-trans) กี่แบบ$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$mcq$j$, $j$สารสูตร C4H10O มีไอโซเมอร์โครงสร้างกี่แบบ (แอลกอฮอล์ + อีเทอร์)$j$, null, $j${"choices": [{"t": "4 แบบ"}, {"t": "5 แบบ"}, {"t": "6 แบบ"}, {"t": "7 แบบ"}], "answer": 3}$j$::jsonb, 2, $j$แอลกอฮอล์ 4 แบบ (บิวทัน-1-ออล, บิวทัน-2-ออล, 2-เมทิลโพรพัน-1-ออล, 2-เมทิลโพรพัน-2-ออล) + อีเทอร์ 3 แบบ (ไดเอทิลอีเทอร์, เมทิลโพรพิลอีเทอร์, ไอโซโพรพิลเมทิลอีเทอร์) = 7$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$สารสูตร C4H10O มีไอโซเมอร์โครงสร้างกี่แบบ (แอลกอฮอล์ + อีเทอร์)$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$mcq$j$, $j$ข้อใดกล่าวถูกต้องเกี่ยวกับเอนันทิโอเมอร์ (enantiomer) คู่หนึ่ง$j$, $j$assets/exam/isomer/p_enan.png$j$, $j${"choices": [{"t": "จุดเดือดต่างกันมาก"}, {"t": "หมุนระนาบแสงโพลาไรซ์ในทิศตรงข้ามกัน องศาเท่ากัน"}, {"t": "เป็นโครงสร้างเดียวกัน ซ้อนทับกันได้"}, {"t": "ไม่มีคาร์บอนไครัลเลย"}], "answer": 1}$j$::jsonb, 1, $j$เอนันทิโอเมอร์เป็นภาพสะท้อนในกระจกที่ซ้อนทับกันไม่ได้ สมบัติทางกายภาพส่วนใหญ่เหมือนกัน แต่หมุนแสงโพลาไรซ์ตรงข้ามกัน$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$ข้อใดกล่าวถูกต้องเกี่ยวกับเอนันทิโอเมอร์ (enantiomer) คู่หนึ่ง$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$mcq$j$, $j$เงื่อนไขของ C=C ที่ทำให้เกิดไอโซเมอร์เรขาคณิตคือข้อใด$j$, null, $j${"choices": [{"t": "คาร์บอนตัวใดตัวหนึ่งของ C=C ต่อกับหมู่เหมือนกัน 2 หมู่"}, {"t": "คาร์บอนแต่ละตัวของ C=C ต่อกับหมู่ที่ต่างกัน 2 หมู่"}, {"t": "ต้องมีธาตุเฮไลด์อยู่ในโมเลกุล"}, {"t": "ต้องเป็นโมเลกุลวงแหวนเท่านั้น"}], "answer": 1}$j$::jsonb, 1, $j$พันธะคู่หมุนอิสระไม่ได้ ถ้าแต่ละ C ต่อกับหมู่ต่างกัน 2 หมู่จะเกิดรูป cis และ trans$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$เงื่อนไขของ C=C ที่ทำให้เกิดไอโซเมอร์เรขาคณิตคือข้อใด$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$mcq$j$, $j$สารที่มีคาร์บอนไครัลต่างกัน 2 อะตอม (เช่น 2,3-ไดโบรโมเพนเทน) มีสเตอริโอไอโซเมอร์ได้สูงสุดกี่แบบ$j$, $j$assets/exam/isomer/23dbp.png$j$, $j${"choices": [{"t": "2 แบบ"}, {"t": "3 แบบ"}, {"t": "4 แบบ"}, {"t": "8 แบบ"}], "answer": 2}$j$::jsonb, 2, $j$จำนวนสเตอริโอไอโซเมอร์สูงสุด = 2ⁿ เมื่อ n = จำนวนคาร์บอนไครัล → 2² = 4$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$สารที่มีคาร์บอนไครัลต่างกัน 2 อะตอม (เช่น 2,3-ไดโบรโมเพนเทน) มีสเตอริโอไอโซเมอร์ได้สูงสุดกี่แบบ$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$tf$j$, $j$บิวเทนและ 2-เมทิลโพรเพนเป็นไอโซเมอร์กัน$j$, null, $j${"answer": true}$j$::jsonb, 1, $j$สูตรโมเลกุลเดียวกัน (C4H10) แต่โครงสร้างต่างกัน$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$บิวเทนและ 2-เมทิลโพรเพนเป็นไอโซเมอร์กัน$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$tf$j$, $j$เอทานอลและไดเมทิลอีเทอร์มีสมบัติทางกายภาพ (เช่น จุดเดือด) เหมือนกัน เพราะสูตรโมเลกุลเดียวกัน$j$, null, $j${"answer": false}$j$::jsonb, 1, $j$หมู่ฟังก์ชันต่างกัน: เอทานอลมีพันธะไฮโดรเจนระหว่างโมเลกุล จุดเดือดสูงกว่าไดเมทิลอีเทอร์มาก$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$เอทานอลและไดเมทิลอีเทอร์มีสมบัติทางกายภาพ (เช่น จุดเดือด) เหมือนกัน เพราะสูตรโมเลกุลเดียวกัน$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$tf$j$, $j$โมเลกุลที่มีคาร์บอนไครัล 1 อะตอม จะมีเอนันทิโอเมอร์ (ภาพสะท้อนในกระจกที่ซ้อนทับไม่ได้) เสมอ$j$, null, $j${"answer": true}$j$::jsonb, 1, $j$คาร์บอนไครัลเดียวทำให้โมเลกุลไม่มีระนาบสมมาตร จึงมีคู่เอนันทิโอเมอร์เสมอ$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$โมเลกุลที่มีคาร์บอนไครัล 1 อะตอม จะมีเอนันทิโอเมอร์ (ภาพสะท้อนในกระจกที่ซ้อนทับไม่ได้) เสมอ$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$tf$j$, $j$1,1-ไดคลอโรเอทีนมีไอโซเมอร์เรขาคณิต (cis-trans)$j$, $j$assets/exam/isomer/11dce.png$j$, $j${"answer": false}$j$::jsonb, 1, $j$คาร์บอนตัวหนึ่งต่อกับ Cl เหมือนกัน 2 อะตอม จึงไม่เกิด cis-trans$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$1,1-ไดคลอโรเอทีนมีไอโซเมอร์เรขาคณิต (cis-trans)$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$match$j$, $j$จับคู่ชนิดของไอโซเมอร์กับสารคู่ตัวอย่างที่ถูกต้อง$j$, null, $j${"left": [{"t": "ไอโซเมอร์โซ่คาร์บอน"}, {"t": "ไอโซเมอร์ตำแหน่ง"}, {"t": "ไอโซเมอร์หมู่ฟังก์ชัน"}, {"t": "ไอโซเมอร์เรขาคณิต (cis-trans)"}], "right": [{"t": "", "img": "assets/exam/isomer/p_chain.png"}, {"t": "", "img": "assets/exam/isomer/p_pos.png"}, {"t": "", "img": "assets/exam/isomer/p_func.png"}, {"t": "", "img": "assets/exam/isomer/p_geo.png"}], "pairs": [0, 1, 2, 3]}$j$::jsonb, 4, $j$บิวเทน/ไอโซบิวเทน = โซ่ · 1-/2-โพรพานอล = ตำแหน่ง · เอทานอล/ไดเมทิลอีเทอร์ = หมู่ฟังก์ชัน · cis/trans-1,2-ไดคลอโรเอทีน = เรขาคณิต$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$จับคู่ชนิดของไอโซเมอร์กับสารคู่ตัวอย่างที่ถูกต้อง$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$match$j$, $j$จับคู่โครงสร้างของแอลเคน C5H12 กับชื่อ IUPAC$j$, null, $j${"left": [{"t": "", "img": "assets/exam/isomer/pentane.png"}, {"t": "", "img": "assets/exam/isomer/2mebutane.png"}, {"t": "", "img": "assets/exam/isomer/neopentane.png"}], "right": [{"t": "เพนเทน"}, {"t": "2-เมทิลบิวเทน"}, {"t": "2,2-ไดเมทิลโพรเพน"}, {"t": "3-เมทิลบิวเทน"}], "pairs": [0, 1, 2]}$j$::jsonb, 3, $j$เลือกโซ่หลักยาวที่สุดและเลขตำแหน่งต่ำสุด — “3-เมทิลบิวเทน” ไม่ใช่ชื่อที่ถูก (ต้องนับจากอีกด้านเป็น 2-เมทิลบิวเทน)$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$จับคู่โครงสร้างของแอลเคน C5H12 กับชื่อ IUPAC$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$drag$j$, $j$จัดสารคู่ต่อไปนี้ให้อยู่ในกลุ่มชนิดไอโซเมอร์โครงสร้างที่ถูกต้อง$j$, null, $j${"zones": [{"t": "ไอโซเมอร์โซ่คาร์บอน"}, {"t": "ไอโซเมอร์ตำแหน่ง"}, {"t": "ไอโซเมอร์หมู่ฟังก์ชัน"}], "items": [{"t": "", "img": "assets/exam/isomer/p_chain.png"}, {"t": "", "img": "assets/exam/isomer/p_chain2.png"}, {"t": "", "img": "assets/exam/isomer/p_pos.png"}, {"t": "", "img": "assets/exam/isomer/p_pos2.png"}, {"t": "", "img": "assets/exam/isomer/p_func.png"}, {"t": "", "img": "assets/exam/isomer/p_func2.png"}], "answer": [0, 0, 1, 1, 2, 2]}$j$::jsonb, 6, $j$บิวเทน/ไอโซบิวเทน และ เพนเทน/นีโอเพนเทน = โซ่ · 1-/2-โพรพานอล และ 1-/2-บิวทีน = ตำแหน่ง · เอทานอล/ไดเมทิลอีเทอร์ และ โพรพานัล/อะซีโตน = หมู่ฟังก์ชัน$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$จัดสารคู่ต่อไปนี้ให้อยู่ในกลุ่มชนิดไอโซเมอร์โครงสร้างที่ถูกต้อง$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$drag$j$, $j$ลากสารแต่ละชนิดไปยังกลุ่มว่า “มี cis-trans” หรือ “ไม่มี cis-trans”$j$, null, $j${"zones": [{"t": "มีไอโซเมอร์ cis-trans"}, {"t": "ไม่มีไอโซเมอร์ cis-trans"}], "items": [{"t": "", "img": "assets/exam/isomer/trans2butene.png"}, {"t": "", "img": "assets/exam/isomer/cisdce.png"}, {"t": "", "img": "assets/exam/isomer/2pentene.png"}, {"t": "", "img": "assets/exam/isomer/propene.png"}, {"t": "", "img": "assets/exam/isomer/11dce.png"}, {"t": "", "img": "assets/exam/isomer/2me2butene.png"}], "answer": [0, 0, 0, 1, 1, 1]}$j$::jsonb, 6, $j$ต้องมี C=C ที่คาร์บอนทั้งสองต่อกับหมู่ต่างกัน: บิวต์-2-อีน, 1,2-ไดคลอโรเอทีน, เพนต์-2-อีน มี · โพรพีน, 1,1-ไดคลอโรเอทีน, 2-เมทิลบิวต์-2-อีน ไม่มี$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$ลากสารแต่ละชนิดไปยังกลุ่มว่า “มี cis-trans” หรือ “ไม่มี cis-trans”$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$drag$j$, $j$ลากสารแต่ละชนิดไปยังกลุ่มว่า “มีคาร์บอนไครัล” หรือ “ไม่มีคาร์บอนไครัล”$j$, null, $j${"zones": [{"t": "มีคาร์บอนไครัล"}, {"t": "ไม่มีคาร์บอนไครัล"}], "items": [{"t": "", "img": "assets/exam/isomer/2butanol.png"}, {"t": "", "img": "assets/exam/isomer/lactic.png"}, {"t": "", "img": "assets/exam/isomer/2clbutane.png"}, {"t": "", "img": "assets/exam/isomer/3mehexane.png"}, {"t": "", "img": "assets/exam/isomer/2propanol.png"}, {"t": "", "img": "assets/exam/isomer/ethanol.png"}, {"t": "", "img": "assets/exam/isomer/3pentanol.png"}], "answer": [0, 0, 0, 0, 1, 1, 1]}$j$::jsonb, 7, $j$คาร์บอนไครัลต้องต่อกับ 4 หมู่ที่ต่างกัน: 2-บิวทานอล, กรดแลกติก, 2-คลอโรบิวเทน, 3-เมทิลเฮกเซน มี · 2-โพรพานอล, เอทานอล, 3-เพนทานอลไม่มี$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$ลากสารแต่ละชนิดไปยังกลุ่มว่า “มีคาร์บอนไครัล” หรือ “ไม่มีคาร์บอนไครัล”$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$short$j$, $j$วาดโครงสร้างไอโซเมอร์ของแอลเคนสูตร C5H12 ให้ครบทุกแบบ พร้อมเขียนชื่อกำกับ (วาดบนกระดาษแล้วถ่ายรูปแนบ)$j$, null, $j${"answers": [], "upload": true, "review": true, "hint": "ครบ 3 โครงสร้าง ชื่อต้องถูกด้วย"}$j$::jsonb, 4, $j$ต้องได้ 3 โครงสร้าง: เพนเทน, 2-เมทิลบิวเทน, 2,2-ไดเมทิลโพรเพน (1 คะแนนต่อโครงสร้างที่ถูก + 1 คะแนนชื่อถูกครบ)$j$, $j$assets/exam/isomer/pentane.png$j$
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$วาดโครงสร้างไอโซเมอร์ของแอลเคนสูตร C5H12 ให้ครบทุกแบบ พร้อมเขียนชื่อกำกับ (วาดบนกระดาษแล้วถ่ายรูปแนบ)$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$short$j$, $j$1-บิวทานอล (CH3CH2CH2CH2OH) กับไดเอทิลอีเทอร์ (CH3CH2OCH2CH3) เป็นไอโซเมอร์ชนิดใด (ตอบสั้นๆ)$j$, null, $j${"answers": ["ไอโซเมอร์หมู่ฟังก์ชัน", "หมู่ฟังก์ชัน", "functional group", "functional group isomer"], "upload": false, "review": true}$j$::jsonb, 2, $j$สูตรโมเลกุลเดียวกัน C4H10O แต่มีหมู่ฟังก์ชันต่างกัน (แอลกอฮอล์ vs อีเทอร์) จึงเป็นไอโซเมอร์หมู่ฟังก์ชัน$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$1-บิวทานอล (CH3CH2CH2CH2OH) กับไดเอทิลอีเทอร์ (CH3CH2OCH2CH3) เป็นไอโซเมอร์ชนิดใด (ตอบสั้นๆ)$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$short$j$, $j$2,3-ไดโบรโมเพนเทน (CH3CHBrCHBrCH2CH3) มีคาร์บอนไครัลกี่อะตอม (ตอบเป็นตัวเลข)$j$, $j$assets/exam/isomer/23dbp.png$j$, $j${"answers": ["2", "สอง", "2 อะตอม"], "upload": false, "review": false}$j$::jsonb, 1, $j$C2 และ C3 แต่ละตัวต่อกับ 4 หมู่ต่างกัน$j$, null
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$2,3-ไดโบรโมเพนเทน (CH3CHBrCHBrCH2CH3) มีคาร์บอนไครัลกี่อะตอม (ตอบเป็นตัวเลข)$j$);

insert into exam_questions (topic, kind, q, img, data, points, explain, explain_img)
select $j$ไอโซเมอร์$j$::text, $j$short$j$, $j$วาดโครงสร้าง cis- และ trans-1,2-ไดคลอโรเอทีน พร้อมอธิบายว่าสองโครงสร้างนี้ต่างกันอย่างไร และเหตุใดจึงเปลี่ยนรูปหากันไม่ได้ (วาดแล้วถ่ายรูปแนบ + พิมพ์อธิบาย)$j$, null, $j${"answers": [], "upload": true, "review": true}$j$::jsonb, 4, $j$cis: Cl อยู่ด้านเดียวกันของพันธะคู่ · trans: Cl อยู่คนละด้าน · พันธะคู่หมุนอิสระไม่ได้ จึงเปลี่ยนรูปหากันไม่ได้ (ต้องทำลายพันธะ π ก่อน)$j$, $j$assets/exam/isomer/p_geo.png$j$
where not exists (select 1 from exam_questions where topic = $j$ไอโซเมอร์$j$ and q = $j$วาดโครงสร้าง cis- และ trans-1,2-ไดคลอโรเอทีน พร้อมอธิบายว่าสองโครงสร้างนี้ต่างกันอย่างไร และเหตุใดจึงเปลี่ยนรูปหากันไม่ได้ (วาดแล้วถ่ายรูปแนบ + พิมพ์อธิบาย)$j$);

-- ชุดสอบฉบับร่าง (ยังไม่ระบุห้อง): เปิดแท็บ 📝 ข้อสอบ → แก้ → เลือกห้อง/เวลา → เปลี่ยนสถานะเป็น “เปิดให้สอบ”
with e as (
  insert into exams (title, topic, minutes, shuffle, max_attempts, show_result, max_score, status)
  select 'สอบเก็บคะแนน: ไอโซเมอร์ (โครงสร้าง + สเตอริโอ)', $j$ไอโซเมอร์$j$, 40, true, 1, 'after_close', 10, 'draft'
  where not exists (select 1 from exams where title = 'สอบเก็บคะแนน: ไอโซเมอร์ (โครงสร้าง + สเตอริโอ)')
  returning id)
insert into exam_items (exam_id, qid, pos)
select e.id, q.id, row_number() over (order by q.created_at, q.id) from e, exam_questions q where q.topic = $j$ไอโซเมอร์$j$;
