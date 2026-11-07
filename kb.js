/* โหมดประลองครูบุ๊ค (Extremely Hard) — 8 รอบ หลายมินิเกม เวลาลดเร็ว · หัวใจ 3 ดวง */
const KB = (() => {
  const $q = (q) => document.querySelector(q);
  const shuffle = (a) => { a = a.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; };
  const pick = (a, n) => shuffle(a).slice(0, n);
  const SUB = "₀₁₂₃₄₅₆₇₈₉";
  const FACTOR = [1, 0.9, 0.8, 0.7, 0.62, 0.55, 0.48, 0.42];               // เวลาที่เหลือในแต่ละรอบ (สัดส่วน)
  const BASE = { quiz: 16, calc: 28, balance: 32, pairs: 22, blitz: 4, react: 11, memory: 9, odd: 10 };   // วินาทีฐาน (blitz = ต่อข้อ)
  const SPD = ["react", "memory", "odd"];
  const TAUNT = {
    start: ["ฮึ่ม... กล้ามาท้าครูหรือ? 😏", "ครูไม่ออมมือนะ เตรียมตัวให้ดี!"],
    ok: ["อืม... ไม่เลวนี่", "โอ้โห ยังพอมีฝีมือ", "ถูกต้อง... แต่ยังไม่จบ!", "เก่งนี่! ลองข้อต่อไป"],
    bad: ["ฮ่าๆ ยังไม่ถึงขั้น!", "พลาดซะแล้ว~", "ทบทวนบทเรียนมาหรือยัง?", "เวลาไม่คอยท่านะ ⏱"],
    win: ["ครู... ยอมแพ้ 😭 เก่งมาก!", "เธอชนะครูแล้ว! ภูมิใจจริงๆ 🏆"],
    lose: ["ไว้มาท้าใหม่นะ ครูรออยู่ 😎", "ฝึกอีกหน่อย แล้วกลับมา!"],
  };
  const say = (k) => TAUNT[k][Math.floor(Math.random() * TAUNT[k].length)];

  /* ---------------- คลังโจทย์ ---------------- */
  // [โจทย์, คำตอบถูก, ตัวลวง×3, คำอธิบาย]
  const QZ = [
    ["ไอออนใดมีการจัดเรียงอิเล็กตรอนเหมือนอาร์กอน (Ar)", "Ca²⁺", "Na⁺", "Mg²⁺", "O²⁻", "Ar มี 18 อิเล็กตรอน Ca²⁺ = 20 − 2 = 18"],
    ["ธาตุใดในคาบที่ 3 มีพลังงานไอออไนเซชันลำดับที่ 1 ต่ำที่สุด", "Na", "Mg", "Al", "Ar", "โลหะแอลคาไลหลุดอิเล็กตรอนง่ายที่สุดในคาบ"],
    ["ข้อใดมีทั้งพันธะไอออนิกและพันธะโคเวเลนต์ในสารเดียวกัน", "NaOH", "HCl", "NaCl", "CO₂", "Na⁺ กับ OH⁻ เป็นไอออนิก ส่วน O–H เป็นโคเวเลนต์"],
    ["โมเลกุลใดไม่เป็นไปตามกฎออกเตต", "BF₃", "CH₄", "NH₃", "H₂O", "B ใน BF₃ มีเพียง 6 อิเล็กตรอนรอบอะตอม"],
    ["รูปร่างโมเลกุลของ SO₂ คือ", "มุมงอ", "เส้นตรง", "ทรงสี่หน้า", "พีระมิดฐานสามเหลี่ยม", "S มี 2 พันธะและ 1 คู่โดดเดี่ยว"],
    ["pH ของสารละลาย Ba(OH)₂ 0.005 mol/dm³ ที่ 25 °C", "12", "11", "2", "13", "[OH⁻] = 0.01 → pOH 2 → pH 12"],
    ["สารละลายบัฟเฟอร์ที่ดีประกอบด้วยคู่ใด", "CH₃COOH กับ CH₃COONa", "HCl กับ NaCl", "NaOH กับ NaCl", "H₂SO₄ กับ Na₂SO₄", "กรดอ่อนกับเกลือของกรดอ่อนนั้น"],
    ["N₂ + 3H₂ ⇌ 2NH₃ เมื่อเพิ่มความดัน สมดุลเลื่อนไปทางใด", "ขวา (เกิด NH₃ มากขึ้น)", "ซ้าย", "ไม่เปลี่ยน", "ปฏิกิริยาหยุด", "ด้านขวามีจำนวนโมลแก๊สน้อยกว่า (4 → 2)"],
    ["เลขออกซิเดชันของ Cr ใน K₂Cr₂O₇", "+6", "+3", "+7", "+2", "2(+1) + 2x + 7(−2) = 0 → x = +6"],
    ["เลขออกซิเดชันของ Mn ใน KMnO₄", "+7", "+4", "+2", "+6", "(+1) + x + 4(−2) = 0 → x = +7"],
    ["ที่แอโนดของเซลล์ไฟฟ้าเคมีทุกชนิดเกิดปฏิกิริยา", "ออกซิเดชัน", "รีดักชัน", "สะเทิน", "การตกตะกอน", "Anode = Oxidation เสมอ"],
    ["แอลคีนสูตร C₄H₈ มีไอโซเมอร์โครงสร้างกี่ชนิด (ไม่นับเรขาคณิต)", "3", "2", "4", "5", "1-บิวทีน, 2-บิวทีน, ไอโซบิวทีน"],
    ["C₅H₁₂ มีไอโซเมอร์โครงสร้างกี่ชนิด", "3", "2", "4", "5", "เพนเทน, 2-เมทิลบิวเทน, 2,2-ไดเมทิลโพรเพน"],
    ["เอทานอลทำปฏิกิริยากับกรดแอซีติก (ตัวเร่ง H₂SO₄) ได้ผลิตภัณฑ์หลักคือ", "เอทิลแอซีเทต", "ไดเอทิลอีเทอร์", "เอทานาล", "กรดโพรพาโนอิก", "เอสเทอริฟิเคชัน"],
    ["พอลิเมอร์ที่เกิดจากพอลิเมอไรเซชันแบบควบแน่น", "ไนลอน-6,6", "พอลิเอทิลีน", "พีวีซี", "พอลิสไตรีน", "ควบแน่นเกิดโมเลกุลเล็ก เช่น น้ำ"],
    ["พันธะที่เชื่อมกรดอะมิโนในโปรตีน", "พันธะเพปไทด์", "พันธะไฮโดรเจน", "พันธะไอออนิก", "พันธะโลหะ", "–CO–NH–"],
    ["ตามทฤษฎีเบรินสเตด–ลาวรี เบสคือ", "ตัวรับโปรตอน", "ตัวให้โปรตอน", "ตัวรับอิเล็กตรอน", "ตัวให้อิเล็กตรอน", "เบส = proton acceptor"],
    ["กรดสังยุค (conjugate acid) ของ NH₃ คือ", "NH₄⁺", "NH₂⁻", "OH⁻", "H₃O⁺", "NH₃ + H⁺ → NH₄⁺"],
    ["ธาตุที่มีอิเล็กโทรเนกาติวิตีสูงที่สุด", "F", "O", "Cl", "N", "ฟลูออรีนสูงสุดในตารางธาตุ"],
    ["สารใดมีจุดเดือดสูงที่สุด", "H₂O", "H₂S", "H₂Se", "H₂Te", "พันธะไฮโดรเจนในน้ำ"],
    ["แก๊สอุดมคติ 1 โมล ที่ 273 K, 1 atm ปริมาตร 22.4 dm³ ถ้าเพิ่มอุณหภูมิเป็น 546 K ที่ความดันเดิม ปริมาตรเป็น", "44.8 dm³", "22.4 dm³", "11.2 dm³", "89.6 dm³", "V ∝ T (กฎของชาร์ลส์)"],
    ["ของแข็งโครงร่างตาข่ายโคเวเลนต์ คือ", "เพชร", "น้ำแข็งแห้ง", "ไอโอดีน", "โซเดียมคลอไรด์", "เพชรเป็นผลึกโคเวเลนต์สามมิติ"],
    ["ค่าคงที่สมดุล K ของปฏิกิริยาหนึ่งขึ้นกับสิ่งใด", "อุณหภูมิ", "ความดัน", "ตัวเร่ง", "ความเข้มข้นเริ่มต้น", "K เปลี่ยนเฉพาะเมื่ออุณหภูมิเปลี่ยน"],
    ["เมื่อเติมตัวเร่งปฏิกิริยาในระบบสมดุล ค่า K เปลี่ยนอย่างไร", "ไม่เปลี่ยน", "เพิ่มขึ้น", "ลดลง", "เป็นศูนย์", "ตัวเร่งเพิ่มอัตราไปข้างหน้าและย้อนกลับเท่ากัน"],
    ["FeCl₃ มีชื่อว่า", "เหล็ก(III) คลอไรด์", "เหล็ก(II) คลอไรด์", "เหล็กไตรคลอรีน", "ไอรอนคลอรีน", "Fe³⁺ + 3Cl⁻"],
    ["สารประกอบของโลหะแทรนซิชันมักมีสี เพราะ", "อิเล็กตรอนในออร์บิทัล d ดูดกลืนแสงที่ตามองเห็น", "มีนิวตรอนมาก", "มีพันธะไอออนิกเท่านั้น", "สะท้อนรังสีแกมมา", "การเปลี่ยนระดับพลังงานของอิเล็กตรอน d"],
    ["ไอโซโทปที่ใช้หาอายุซากดึกดำบรรพ์คือ", "C-14", "H-2", "U-238 เท่านั้น", "O-16", "คาร์บอน-14 มีครึ่งชีวิตประมาณ 5,730 ปี"],
    ["กรดข้อใดแรงที่สุด", "HClO₄", "HClO", "HClO₂", "HClO₃", "ออกซิเจนมากกว่า → กรดแรงกว่า"],
    ["สารกลุ่มใดให้ผลบวกกับปฏิกิริยาทอลเลนส์ (กระจกเงา)", "อัลดีไฮด์", "คีโตน", "อีเทอร์", "แอลเคน", "อัลดีไฮด์ถูกออกซิไดซ์ได้ง่าย"],
    ["ออกซิเดชันแอลกอฮอล์ปฐมภูมิอย่างสมบูรณ์ได้", "กรดคาร์บอกซิลิก", "คีโตน", "อีเทอร์", "แอลเคน", "แอลกอฮอล์ → อัลดีไฮด์ → กรดคาร์บอกซิลิก"],
    ["ชื่อ IUPAC ของ CH₃CH(CH₃)CH₂CH₃", "2-เมทิลบิวเทน", "3-เมทิลบิวเทน", "เพนเทน", "2-เอทิลโพรเพน", "โซ่หลักยาว 4 คาร์บอน มีเมทิลที่ C-2"],
    ["จำนวนพันธะซิกมา (σ) และพันธะไพ (π) ใน C₂H₄", "σ 5, π 1", "σ 4, π 2", "σ 6, π 0", "σ 3, π 3", "C=C มี 1σ + 1π และ C–H 4σ"],
    ["ไฮบริไดเซชันของคาร์บอนใน CH≡CH", "sp", "sp²", "sp³", "dsp²", "พันธะสามเป็นเส้นตรง"],
    ["มุมพันธะ H–C–H ในมีเทนประมาณ", "109.5°", "120°", "180°", "90°", "ทรงสี่หน้าปกติ"],
    ["ΔH ของปฏิกิริยาคายความร้อนมีค่า", "เป็นลบ", "เป็นบวก", "เป็นศูนย์เสมอ", "เท่ากับอุณหภูมิ", "ผลิตภัณฑ์มีพลังงานต่ำกว่าสารตั้งต้น"],
    ["ข้อใดเป็นอัลโลโทรปของคาร์บอน", "แกรไฟต์", "ซิลิกา", "ถ่านหิน", "CO₂", "เพชร แกรไฟต์ ฟูลเลอรีน"],
    ["พันธะซิกมาเกิดจากการเen xen ซ้อนเหลื่อมของออร์บิทัลแบบใด", "ซ้อนเหลื่อมตามแนวแกนพันธะ", "ซ้อนเหลื่อมด้านข้าง", "ไม่มีการซ้อนเหลื่อม", "ซ้อนเหลื่อมแบบหมุน", "σ = head-on overlap"],
  ];
  QZ[QZ.length - 1][0] = "พันธะซิกมา (σ) เกิดจากการซ้อนเหลื่อมของออร์บิทัลแบบใด";
  const CL = [   // โจทย์คำนวณ [โจทย์, ถูก, ตัวลวง×3, วิธีคิด]
    ["NaOH 8 g (มวลโมลาร์ 40) ละลายเป็นสารละลาย 500 cm³ ความเข้มข้นกี่ mol/dm³", "0.4", "0.2", "0.8", "4", "0.2 mol ÷ 0.5 dm³ = 0.4"],
    ["ต้องใช้ HCl 0.1 mol/dm³ กี่ cm³ สะเทินกับ NaOH 0.1 mol/dm³ 25 cm³", "25", "50", "12.5", "100", "1 : 1 โมลเท่ากัน"],
    ["ต้องใช้ NaOH 0.1 mol/dm³ กี่ cm³ สะเทิน H₂SO₄ 0.1 mol/dm³ 20 cm³", "40", "20", "10", "80", "H₂SO₄ ให้ H⁺ 2 เท่า"],
    ["pH ของ HCl 0.001 mol/dm³", "3", "1", "11", "0.001", "−log 10⁻³ = 3"],
    ["pH ของ NaOH 0.01 mol/dm³ ที่ 25 °C", "12", "2", "10", "13", "pOH = 2 → pH = 12"],
    ["CaCO₃ 10 g (100) สลายตัวให้ CO₂ ที่ STP กี่ dm³", "2.24", "22.4", "4.48", "1.12", "0.1 mol × 22.4"],
    ["เผา C₃H₈ 4.4 g (44) อย่างสมบูรณ์ ได้ CO₂ กี่ g (C₃H₈ + 5O₂ → 3CO₂ + 4H₂O)", "13.2", "4.4", "8.8", "44", "0.1 mol → CO₂ 0.3 mol × 44"],
    ["เจือจางสารละลาย 2 mol/dm³ 50 cm³ เป็น 250 cm³ ได้ความเข้มข้น", "0.4 mol/dm³", "0.2 mol/dm³", "1 mol/dm³", "10 mol/dm³", "C₁V₁ = C₂V₂"],
    ["H₂ 4 g (มวลโมลาร์ 2) ที่ STP มีปริมาตรกี่ dm³", "44.8", "22.4", "89.6", "11.2", "2 mol × 22.4"],
    ["มวลโมเลกุลของ Ca(OH)₂ (Ca 40, O 16, H 1)", "74", "57", "58", "114", "40 + 2(17)"],
    ["Al₂(SO₄)₃ 1 โมล มีอะตอมรวมกี่โมล", "17", "12", "15", "5", "2 + 3 + 12"],
    ["ร้อยละโดยมวลของ N ใน NH₄NO₃ (N 14, H 1, O 16)", "35%", "17.5%", "28%", "46%", "28 ÷ 80 × 100"],
    ["กลูโคส 18 g (มวลโมลาร์ 180) ในสารละลาย 500 cm³ ความเข้มข้นกี่ mol/dm³", "0.2", "0.1", "0.4", "2", "0.1 mol ÷ 0.5 dm³"],
    ["Al 5.4 g (27) ทำปฏิกิริยากับ HCl เกินพอ (2Al + 6HCl → 2AlCl₃ + 3H₂) ได้ H₂ ที่ STP กี่ dm³", "6.72", "4.48", "2.24", "13.44", "0.2 mol Al → 0.3 mol H₂"],
    ["2H₂ + O₂ → 2H₂O มี H₂ 6 โมล O₂ 2 โมล ได้น้ำสูงสุดกี่โมล", "4", "6", "2", "8", "O₂ เป็นสารกำหนดปริมาณ"],
    ["ไอโซโทปมีครึ่งชีวิต 5 ปี ผ่านไป 15 ปี เหลือกี่ %", "12.5%", "25%", "6.25%", "50%", "3 ครึ่งชีวิต → ½³"],
    ["CO₂ 22 g (มวลโมลาร์ 44) มีอะตอมออกซิเจนกี่โมล", "1", "0.5", "2", "0.25", "0.5 mol CO₂ × 2"],
    ["ผสม HCl 0.2 mol/dm³ 100 cm³ กับ NaOH 0.2 mol/dm³ 100 cm³ สารละลายมี pH", "7", "1", "13", "0.7", "สะเทินพอดี"],
  ];
  const BL = [   // สมการ [สารตั้งต้น[], ผลิตภัณฑ์[], สัมประสิทธิ์]
    [["H₂", "O₂"], ["H₂O"], [2, 1, 2]], [["N₂", "H₂"], ["NH₃"], [1, 3, 2]], [["CH₄", "O₂"], ["CO₂", "H₂O"], [1, 2, 1, 2]], [["Fe", "O₂"], ["Fe₂O₃"], [4, 3, 2]],
    [["Al", "HCl"], ["AlCl₃", "H₂"], [2, 6, 2, 3]], [["C₂H₆", "O₂"], ["CO₂", "H₂O"], [2, 7, 4, 6]], [["C₃H₈", "O₂"], ["CO₂", "H₂O"], [1, 5, 3, 4]], [["KClO₃"], ["KCl", "O₂"], [2, 2, 3]],
    [["Na", "H₂O"], ["NaOH", "H₂"], [2, 2, 2, 1]], [["Ca(OH)₂", "HCl"], ["CaCl₂", "H₂O"], [1, 2, 1, 2]], [["Al", "O₂"], ["Al₂O₃"], [4, 3, 2]], [["C₆H₁₂O₆", "O₂"], ["CO₂", "H₂O"], [1, 6, 6, 6]],
    [["Fe₂O₃", "CO"], ["Fe", "CO₂"], [1, 3, 2, 3]], [["H₃PO₄", "NaOH"], ["Na₃PO₄", "H₂O"], [1, 3, 1, 3]],
  ];
  const ODD = [   // [พวกเดียวกัน×3, ตัวแปลกแยก, เหตุผล]
    [["Na", "K", "Ca"], "Cl", "ที่เหลือเป็นโลหะ Cl เป็นอโลหะ"], [["He", "Ne", "Ar"], "O", "ที่เหลือเป็นแก๊สเฉื่อย"], [["HCl", "HNO₃", "H₂SO₄"], "NaOH", "ที่เหลือเป็นกรด NaOH เป็นเบส"],
    [["NaCl", "KBr", "MgO"], "CO₂", "ที่เหลือเป็นสารไอออนิก CO₂ เป็นโคเวเลนต์"], [["CH₄", "C₂H₆", "C₃H₈"], "C₂H₄", "ที่เหลือเป็นแอลเคน C₂H₄ เป็นแอลคีน"], [["F", "Cl", "Br"], "Na", "ที่เหลือเป็นฮาโลเจน"],
    [["เพชร", "แกรไฟต์", "ฟูลเลอรีน"], "ซิลิกา", "ที่เหลือเป็นอัลโลโทรปของคาร์บอน"], [["CO₂", "BF₃", "CH₄"], "NH₃", "ที่เหลือไม่มีขั้ว NH₃ มีขั้ว"], [["เอทานอล", "เมทานอล", "โพรพานอล"], "แอซีโทน", "ที่เหลือเป็นแอลกอฮอล์ แอซีโทนเป็นคีโตน"],
    [["Li", "Na", "K"], "Be", "ที่เหลืออยู่หมู่ 1 Be อยู่หมู่ 2"], [["O₂", "N₂", "Cl₂"], "H₂O", "ที่เหลือเป็นสารบริสุทธิ์ชนิดธาตุ H₂O เป็นสารประกอบ"], [["พอลิเอทิลีน", "พีวีซี", "พอลิสไตรีน"], "ไนลอน", "ที่เหลือเกิดจากพอลิเมอไรเซชันแบบเติม"],
  ];
  const SYMS = ["H", "He", "Li", "C", "N", "O", "F", "Ne", "Na", "Mg", "Al", "Si", "P", "S", "Cl", "K", "Ca", "Fe", "Cu", "Zn"];
  const EL = [["โพแทสเซียม", "K"], ["ทังสเตน", "W"], ["ปรอท", "Hg"], ["ตะกั่ว", "Pb"], ["ดีบุก", "Sn"], ["พลวง", "Sb"], ["ทองแดง", "Cu"], ["เงิน", "Ag"], ["ทองคำ", "Au"], ["เหล็ก", "Fe"], ["โซเดียม", "Na"],
    ["แมงกานีส", "Mn"], ["โครเมียม", "Cr"], ["สังกะสี", "Zn"], ["นิกเกิล", "Ni"], ["โบรมีน", "Br"], ["ซีนอน", "Xe"], ["ฟอสฟอรัส", "P"], ["กำมะถัน", "S"], ["แคลเซียม", "Ca"], ["แมกนีเซียม", "Mg"], ["ไอโอดีน", "I"]];
  const TF = [   // [ข้อความ, จริง?]
    ["น้ำมีมุมพันธะ H–O–H ประมาณ 104.5°", 1], ["NaCl เป็นสารประกอบโคเวเลนต์", 0], ["ธาตุหมู่ 17 เรียกว่าฮาโลเจน", 1], ["ฮีเลียมมีเวเลนซ์อิเล็กตรอน 8 ตัว", 0], ["น้ำบริสุทธิ์ที่ 25 °C มี pH เท่ากับ 7", 1],
    ["กรดแก่ทุกชนิดต้องมีความเข้มข้นสูง", 0], ["เพชรกับแกรไฟต์เป็นอัลโลโทรปของคาร์บอน", 1], ["ไอโซโทปของธาตุเดียวกันมีจำนวนโปรตอนต่างกัน", 0], ["ปฏิกิริยาดูดความร้อนมี ΔH เป็นบวก", 1], ["ตัวเร่งปฏิกิริยาถูกใช้หมดเมื่อสิ้นสุดปฏิกิริยา", 0],
    ["การระเหิดคือของแข็งกลายเป็นแก๊สโดยตรง", 1], ["แอลเคนทุกชนิดมีพันธะคู่", 0], ["เอทานอลละลายน้ำได้ดี", 1], ["เลขออกซิเดชันของ O ใน H₂O₂ เท่ากับ −2", 0], ["CO₂ เป็นโมเลกุลไม่มีขั้ว", 1],
    ["1 โมลของสารใดๆ มีจำนวนอนุภาคเท่ากัน", 1], ["NH₃ เป็นกรดตามทฤษฎีอาร์เรเนียส", 0], ["เหล็กเป็นโลหะแทรนซิชัน", 1], ["พันธะไฮโดรเจนแข็งแรงกว่าพันธะโคเวเลนต์", 0], ["รัศมีอะตอมเพิ่มขึ้นจากซ้ายไปขวาในคาบเดียวกัน", 0],
    ["อิเล็กโทรเนกาติวิตีเพิ่มขึ้นจากซ้ายไปขวาในคาบเดียวกัน", 1], ["น้ำแข็งแห้งคือ CO₂ ที่เป็นของแข็ง", 1], ["สารละลาย pH 3 มี [H⁺] มากกว่า pH 5 เป็น 100 เท่า", 1], ["พอลิเอทิลีนเกิดจากพอลิเมอไรเซชันแบบควบแน่น", 0], ["การกลั่นลำดับส่วนอาศัยความต่างของจุดเดือด", 1],
    ["โซเดียมเก็บไว้ในน้ำเพื่อป้องกันการทำปฏิกิริยา", 0], ["โอโซนมีสูตรโมเลกุล O₃", 1], ["เมื่อเจือจางกรดซัลฟิวริกเข้มข้น ควรเทน้ำลงในกรด", 0], ["โซเดียมไฮโดรเจนคาร์บอเนตมีสมบัติเป็นเบสอ่อน", 1], ["เลขอะตอมเท่ากับจำนวนนิวตรอนเสมอ", 0],
  ];

  /* ---------------- สถานะ ---------------- */
  const JR_PAIRS = [["ไฮโดรเจน", "H"], ["ฮีเลียม", "He"], ["คาร์บอน", "C"], ["ไนโตรเจน", "N"], ["ออกซิเจน", "O"], ["โซเดียม", "Na"], ["แมกนีเซียม", "Mg"], ["อะลูมิเนียม", "Al"], ["กำมะถัน", "S"], ["คลอรีน", "Cl"], ["โพแทสเซียม", "K"], ["แคลเซียม", "Ca"], ["เหล็ก", "Fe"], ["ทองแดง", "Cu"], ["สังกะสี", "Zn"], ["เงิน", "Ag"], ["ทองคำ", "Au"]];
  const JR_SYM = JR_PAIRS.map((x) => x[1]);
  const S = { lv: "hs", bank: null, screen: "home", st: null, r: 0, types: [], hearts: 3, hp: 100, cleared: 0, rd: null, t0: 0, over: false, lock: false, msg: "", say: "", res: null, tmr: null, end: 0, total: 1, timeouts: 0 };
  const paint = () => GAMES.paint();
  const fmt = (n) => String(n).replace(/\d/g, (d) => SUB[d]);

  async function open() {
    S.screen = "home"; S.st = null; GAMES.setMode("kb"); paint();
    try { S.st = await rpc("kb_status", { p_token: tk() }); } catch (e) {}
    try { const b = await rpc("kb_bank", { p_token: tk() }); S.lv = b.level === "jr" ? "jr" : "hs"; S.bank = b.items || []; } catch (e) { S.lv = "hs"; S.bank = []; }
    paint();
  }
  const M = () => (S.lv === "jr" ? 1.4 : 1);                       // ระดับ ม.ต้น ได้เวลามากขึ้น 40%
  const bk = (k) => (S.bank || []).filter((x) => x.kind === k);
  const mcq = (k) => bk(k).filter((x) => (x.wrong || []).length >= 3).map((x) => [x.question, x.answer, x.wrong[0], x.wrong[1], x.wrong[2], x.explain || ""]);
  const draw = (name, src) => { if (!S[name] || !S[name].length) S[name] = shuffle(src); return S[name].pop(); };
  function start() {
    S.types = shuffle(["quiz", "calc", "balance", "pairs", "blitz", "react", "memory", "odd"]); S.r = 0; S.hearts = 3; S.hp = 100; S.cleared = 0; S.over = false; S.lock = false; S.t0 = Date.now(); S.msg = ""; S.say = say("start");
    const jr = S.lv === "jr";
    S.srcQ = jr ? mcq("quiz") : QZ.concat(mcq("quiz")); S.srcC = jr ? mcq("calc") : CL.concat(mcq("calc"));
    S.srcT = (jr ? [] : TF).concat(bk("tf").map((x) => [x.question, x.answer === "จริง" ? 1 : 0]));
    S.srcO = (jr ? [] : ODD).concat(bk("odd").filter((x) => (x.wrong || []).length >= 3).map((x) => [x.wrong.slice(0, 3), x.answer, x.explain || ""]));
    S.srcB = jr ? BL.slice(0, 6) : BL;
    if (!S.srcQ.length) S.srcQ = QZ; if (!S.srcC.length) S.srcC = CL; if (S.srcT.length < 5) S.srcT = TF; if (!S.srcO.length) S.srcO = ODD;
    S.quizPool = []; S.calcPool = []; S.balPool = []; S.tfPool = []; S.oddPool = [];
    S.screen = "play"; nextRound();
  }
  const secs = () => Math.max(2, Math.round(BASE[S.types[S.r]] * FACTOR[S.r] * M()));
  function nextRound() {
    clearInterval(S.tmr); const t = S.types[S.r], f = FACTOR[S.r];
    const rd = { type: t, done: false };
    if (t === "quiz" || t === "calc") {
      const q = t === "quiz" ? draw("quizPool", S.srcQ) : draw("calcPool", S.srcC);
      rd.q = q[0]; rd.ans = q[1]; rd.exp = q[5]; rd.opts = shuffle(q.slice(1, 5)); rd.pick = null;
    } else if (t === "balance") {
      const b = draw("balPool", S.srcB); rd.b = b; rd.co = b[0].concat(b[1]).map(() => 1);
    } else if (t === "pairs") {
      const set = pick(S.lv === "jr" ? JR_PAIRS : EL, 4); rd.names = set.map((x) => x[0]); rd.syms = shuffle(set.map((x) => x[1])); rd.set = set; rd.sel = null; rd.ok = new Set();
    } else if (t === "blitz") {
      rd.items = []; for (let i = 0; i < 5; i++) rd.items.push(draw("tfPool", S.srcT)); rd.i = 0; rd.right = 0;
    }
    else if (t === "odd") {
      const o = draw("oddPool", S.srcO); rd.q = "ข้อใดแปลกแยกจากพวก? (คิดเร็วๆ)"; rd.ans = o[1]; rd.exp = o[2]; rd.opts = shuffle(o[0].concat([o[1]])); rd.pick = null;
    } else if (t === "react") { rd.hit = 0; rd.need = 6; rd.cell = Math.floor(Math.random() * 9); }
    else if (t === "memory") { const n = S.r >= 4 ? 5 : 4; const SY = S.lv === "jr" ? JR_SYM : SYMS; rd.seq = pick(SY, n); rd.pool = shuffle(rd.seq.concat(pick(SY.filter((x) => !rd.seq.includes(x)), 6 - n + 2))); rd.in = []; rd.phase = "show"; }
    S.rd = rd; S.lock = false; S.msg = "";
    if (t === "memory") {
      const ms = Math.max(1300, Math.round(2800 * f * M())); S.total = ms / 1000; S.end = Date.now() + ms; S.show = true; S.tmr = setInterval(tick, 80); paint();
      setTimeout(() => { if (S.rd !== rd || S.over || S.lock) return; clearInterval(S.tmr); rd.phase = "rec"; S.show = false; const sec = Math.max(4, Math.round(BASE.memory * f * M())); S.total = sec; S.end = Date.now() + sec * 1000; S.tmr = setInterval(tick, 80); paint(); }, ms);
      return;
    }
    const sec = t === "blitz" ? Math.max(2, Math.round(BASE.blitz * f * M() * 10) / 10) : secs(); S.total = sec; S.end = Date.now() + sec * 1000;
    S.tmr = setInterval(tick, 80); paint();
  }
  function tick() {
    const left = Math.max(0, S.end - Date.now()), bar = $q(".kb-time i");
    if (bar) { bar.style.width = (left / (S.total * 1000)) * 100 + "%"; bar.parentElement.classList.toggle("low", left < S.total * 300); const n = $q(".kb-secs"); if (n) n.textContent = (left / 1000).toFixed(1) + " วิ"; }
    if (left <= 0 && !S.lock && !S.show) { S.timeouts++; if (S.rd.type === "blitz") blitzAns(null, true); else roundEnd(false, "⏱ หมดเวลา!"); }
  }
  function roundEnd(ok, msg) {
    if (S.lock) return; S.lock = true; clearInterval(S.tmr); S.msg = msg || "";
    if (ok) { S.cleared++; S.hp = Math.max(0, S.hp - 12.5); S.say = say("ok"); SFX.play("hit"); }
    else { S.hearts--; S.say = say("bad"); SFX.play("bad"); }
    clearTimeout(S.adv); S.adv = setTimeout(advance, ok ? 900 : 1500);
    paint();
    const pl = $q(".kb-play"), bs = $q(".kb-boss"), qq = $q(".kb-q");
    const cls = (el, c, ms) => { if (!el) return; el.classList.remove(c); void el.offsetWidth; el.classList.add(c); setTimeout(() => el.classList.remove(c), ms); };
    if (ok) {
      cls(pl, "kb-ok", 700); cls(bs, "kb-hurt", 700);
      if (bs) { FX.at(bs, "hit-spark", { scale: 1.6 }); setTimeout(() => FX.at(bs, "blunt-hit", { scale: 1.2 }), 120); }
      if (qq) FX.at(qq, "collect-burst", { scale: 1.8 });
      S.hp <= 0 && bs && FX.at(bs, "shatter-death", { scale: 1.2 });
    } else {
      cls(pl, "kb-bad", 700); cls(pl, "sp-shake", 500); cls(bs, "kb-laugh", 900);
      if (qq) FX.at(qq, "curse", { scale: 1.6 });
      const hs = $q(".kb-hearts"); if (hs) FX.at(hs, "small-explosion", { scale: 0.7 });
    }
    // พักสั้นๆ ให้อ่านเฉลย แล้วไปรอบต่อไปเอง — กด "ต่อไป ▶" / Enter / Space เพื่อข้ามได้ทันที
  }
  function advance() {
    clearTimeout(S.adv); S.adv = 0;
    if (!S.lock || S.over || S.screen !== "play") return;
    if (S.hearts <= 0) return finish(false);
    S.r++; if (S.r >= 8) return finish(true);
    S.enter = true; nextRound();
  }
  document.addEventListener("keydown", (e) => { if (S.adv && (e.key === "Enter" || e.key === " ") && !e.repeat) { e.preventDefault(); advance(); } });

  /* ---- ตอบแต่ละแบบ ---- */
  function pickOpt(i) { if (S.lock) return; const rd = S.rd; rd.pick = i; const ok = rd.opts[i] === rd.ans; roundEnd(ok, ok ? "✅ ถูกต้อง! " + rd.exp : "❌ เฉลย: " + rd.ans + " — " + rd.exp); }
  function tap(i) {
    if (S.lock) return; const rd = S.rd;
    if (i === rd.cell) { rd.hit++; SFX.play("ok"); if (rd.hit >= rd.need) return roundEnd(true, "⚡ เร็วมาก!"); let n; do { n = Math.floor(Math.random() * 9); } while (n === rd.cell); rd.cell = n; S.msg = ""; }
    else { S.end -= 1500; S.msg = "❌ พลาด! หักเวลา 1.5 วินาที"; SFX.play("bad"); if (S.end <= Date.now()) return; }
    paint();
  }
  function mem(s) {
    if (S.lock) return; const rd = S.rd; if (rd.phase !== "rec") return;
    if (rd.seq[rd.in.length] === s) { rd.in.push(s); SFX.play("ok"); if (rd.in.length === rd.seq.length) return roundEnd(true, "🧠 จำแม่น!"); paint(); }
    else roundEnd(false, "❌ ลำดับที่ถูก: " + rd.seq.join(" → "));
  }
  function bal(i, d) { if (S.lock) return; const c = S.rd.co; c[i] = Math.max(1, Math.min(20, c[i] + d)); SFX.play("click"); paint(); }
  const gcd = (a, b) => (b ? gcd(b, a % b) : a);
  function balCheck() {
    if (S.lock) return; const c = S.rd.co, ans = S.rd.b[2]; const g = c.reduce(gcd), cc = c.map((x) => x / g);
    const ok = cc.every((x, i) => x === ans[i]) && g === 1;
    roundEnd(ok, ok ? "✅ ดุลสมการถูกต้อง!" : "❌ เฉลย: " + ans.join(" , "));
  }
  function pairName(i) { if (S.lock) return; const rd = S.rd; if (rd.ok.has(rd.set.findIndex((x) => x[0] === rd.names[i]))) return; rd.sel = i; SFX.play("click"); paint(); }
  function pairSym(j) {
    if (S.lock) return; const rd = S.rd; if (rd.sel === null) return;
    const nm = rd.names[rd.sel], sym = rd.syms[j], idx = rd.set.findIndex((x) => x[0] === nm);
    if (rd.ok.has(idx)) return;
    if (rd.set[idx][1] === sym) { rd.ok.add(idx); rd.sel = null; SFX.play("ok"); if (rd.ok.size === 4) return roundEnd(true, "✅ จับคู่ครบ!"); }
    else { S.end -= 3000; rd.sel = null; S.msg = "❌ ผิด! หักเวลา 3 วินาที"; SFX.play("bad"); if (S.end <= Date.now()) return; }
    paint();
  }
  function blitzAns(v, timeout) {
    if (S.lock) return; const rd = S.rd, it = rd.items[rd.i];
    const ok = !timeout && ((v === 1) === !!it[1]); if (ok) { rd.right++; SFX.play("ok"); } else SFX.play("bad");
    rd.i++;
    if (rd.i >= 5) { const pass = rd.right >= 4; return roundEnd(pass, pass ? `✅ ถูก ${rd.right}/5` : `❌ ถูกแค่ ${rd.right}/5 (ต้อง ≥ 4)`); }
    S.end = Date.now() + S.total * 1000; S.msg = ok ? "✅" : timeout ? "⏱ หมดเวลา" : "❌"; paint();
  }

  async function finish(won) {
    clearInterval(S.tmr); clearTimeout(S.adv); S.adv = 0; S.over = true;
    const sec = Math.max(S.cleared * 3, Math.round((Date.now() - S.t0) / 1000));
    S.say = say(won ? "win" : "lose");
    try {
      const r = await rpc("kb_submit", { p_token: tk(), p_cleared: S.cleared, p_won: won, p_seconds: sec });
      S.res = { ...r, secs: sec }; S.screen = "res"; await load(); if (won) FX.victory();
    } catch (e) { toast(e.message); S.screen = "home"; }
    go("game");
  }
  const quit = () => { if (S.screen === "play" && !confirm("ยอมแพ้ครูบุ๊ค? จะไม่ได้รางวัลจากรอบนี้")) return; clearInterval(S.tmr); clearTimeout(S.adv); S.adv = 0; S.screen = "home"; S.over = true; GAMES.home(); };

  /* ---------------- มุมมอง ---------------- */
  const KIMG = '<img class="kb-img" src="assets/chars/krubook.png" alt="" onerror="this.replaceWith(document.createTextNode(\'👨‍🏫\'))">';
  const ARENA = ["lab", "lab", "storm", "storm", "volcano", "volcano", "crystal", "crystal"];
  const TYPE = { quiz: ["🧠", "ควิซสุดโหด"], react: ["⚡", "ไวแสง"], memory: ["🧩", "จำลำดับ"], odd: ["🔍", "หาตัวแปลกแยก"], calc: ["🧮", "คำนวณเคมี"], balance: ["⚖️", "ดุลสมการ"], pairs: ["🔗", "จับคู่ธาตุ"], blitz: ["⚡", "จริง/เท็จ สายฟ้า"] };
  function view() {
    if (S.screen === "play") return playView();
    if (S.screen === "res") return resView();
    const t = S.st;
    return `<div class="card center"><div class="kb-hero big">${KIMG}</div><h3>⚔️ ประลองครูบุ๊ค ${S.lv === "jr" ? '<span class="pill" style="background:#1f7a4d">ระดับ ม.ต้น (เนื้อหา ม.1)</span>' : '<span class="pill" style="background:#7a1020">EXTREMELY HARD</span>'}</h3>
      <p class="muted">8 รอบ 8 แบบเกม: ควิซสุดโหด · คำนวณ · ดุลสมการ · จับคู่ธาตุ · จริง/เท็จสายฟ้า · ไวแสง (วัดความเร็ว) · จำลำดับ · หาตัวแปลกแยก (วัดไหวพริบ) · <b>เวลาลดลงทุกรอบ</b> · มีหัวใจ 3 ดวง พลาดหรือหมดเวลาเสีย 1 ดวง${t ? `<br>ผ่านครบ 8 รอบได้ +${t.per_round * 8 + t.win_exp} EXP +${t.win_coins} 🪙 (ผ่านรอบละ +${t.per_round} EXP) · รับรางวัลได้ ${t.max_plays} รอบ/วัน (เล่นแล้ว ${Math.min(t.plays, t.max_plays)}/${t.max_plays}${t.wins ? ` · ชนะแล้ว ${t.wins} ครั้ง 🏆` : ""})` : ""}</p>
      <div class="row" style="justify-content:center"><button class="btn gold" onclick="KB.start()">ท้าครูบุ๊ค!</button><button class="btn ghost" onclick="GAMES.home()">กลับ</button></div></div>`;
  }
  function head() {
    return `<div class="kb-top"><div class="kb-boss">${KIMG}</div><div class="kb-info"><div class="kb-name">👨‍🏫 ครูบุ๊ค <small>รอบ ${Math.min(S.r + 1, 8)}/8</small></div>
      <div class="kb-hp"><i style="width:${S.hp}%"></i></div><div class="kb-say">💬 ${S.say}</div></div>
      <div class="kb-hearts">${[0, 1, 2].map((i) => (i < S.hearts ? "❤️" : "🖤")).join("")}</div></div>`;
  }
  function playView() {
    const rd = S.rd, ty = rd.type === "quiz" && S.lv === "jr" ? ["🧠", "ควิซ ม.ต้น"] : TYPE[rd.type];
    let body = "";
    if (rd.type === "quiz" || rd.type === "calc" || rd.type === "odd") {
      body = `<div class="kb-q">${esc(rd.q)}</div><div class="kb-opts">${rd.opts.map((o, i) => `<button class="kb-opt ${S.lock ? (o === rd.ans ? "ok" : rd.pick === i ? "no" : "") : ""}" ${S.lock ? "disabled" : ""} onclick="KB.pick(${i})">${esc(o)}</button>`).join("")}</div>`;
    } else if (rd.type === "react") {
      body = `<div class="kb-q">แตะช่องที่สว่างให้ครบ ${rd.need} ครั้ง · ถูก ${rd.hit}/${rd.need} · แตะพลาดหักเวลา</div><div class="kb-grid">${[0,1,2,3,4,5,6,7,8].map((i) => `<button class="kb-cell ${i === rd.cell ? "on" : ""}" onclick="KB.tap(${i})"></button>`).join("")}</div>`;
    } else if (rd.type === "memory") {
      body = rd.phase === "show" ? `<div class="kb-q">จำลำดับให้ดี!</div><div class="kb-seq">${rd.seq.map((s) => `<span>${s}</span>`).join("")}</div>`
        : `<div class="kb-q">กดตามลำดับที่เห็น (${rd.in.length}/${rd.seq.length})</div><div class="kb-seq done">${rd.seq.map((s, i) => `<span>${i < rd.in.length ? rd.in[i] : "?"}</span>`).join("")}</div><div class="kb-opts kb-mem">${rd.pool.map((s) => `<button class="kb-opt" ${S.lock ? "disabled" : ""} onclick="KB.mem('${s}')">${s}</button>`).join("")}</div>`;
    } else if (rd.type === "balance") {
      const all = rd.b[0].concat(rd.b[1]), nr = rd.b[0].length;
      body = `<div class="kb-q">ดุลสมการให้ถูกต้อง (สัมประสิทธิ์จำนวนเต็มน้อยที่สุด)</div><div class="kb-eq">${all.map((f, i) => `${i === nr ? '<span class="kb-arr">→</span>' : i ? '<span class="kb-arr">+</span>' : ""}<span class="kb-term"><button onclick="KB.bal(${i},1)">▲</button><b>${rd.co[i]}</b><button onclick="KB.bal(${i},-1)">▼</button><span class="kb-f">${f}</span></span>`).join("")}</div>
        <div class="row" style="justify-content:center"><button class="btn gold" ${S.lock ? "disabled" : ""} onclick="KB.balCheck()">ยืนยัน</button></div>`;
    } else if (rd.type === "pairs") {
      body = `<div class="kb-q">จับคู่ชื่อธาตุกับสัญลักษณ์ (แตะชื่อ แล้วแตะสัญลักษณ์) · ผิดเสียเวลา 3 วิ</div><div class="kb-pairs"><div>${rd.names.map((n, i) => { const idx = rd.set.findIndex((x) => x[0] === n); return `<button class="kb-pb ${rd.ok.has(idx) ? "done" : ""} ${rd.sel === i ? "sel" : ""}" ${S.lock ? "disabled" : ""} onclick="KB.pn(${i})">${n}</button>`; }).join("")}</div>
        <div>${rd.syms.map((sy, j) => { const idx = rd.set.findIndex((x) => x[1] === sy); return `<button class="kb-pb ${rd.ok.has(idx) ? "done" : ""}" ${S.lock ? "disabled" : ""} onclick="KB.ps(${j})">${sy}</button>`; }).join("")}</div></div>`;
    } else {
      const it = rd.items[Math.min(rd.i, 4)];
      body = `<div class="kb-q">ข้อ ${Math.min(rd.i + 1, 5)}/5 · ต้องถูก ≥ 4 (ข้อละ ${S.total} วินาที)</div><div class="kb-tf">${esc(it[0])}</div><div class="row" style="justify-content:center;gap:12px"><button class="kb-tfb t" ${S.lock ? "disabled" : ""} onclick="KB.tf(1)">✓ จริง</button><button class="kb-tfb f" ${S.lock ? "disabled" : ""} onclick="KB.tf(0)">✗ เท็จ</button></div>`;
    }
    const enter = S.enter; S.enter = false;
    return `<div class="card kb-play kb-field kb-ar-${ARENA[Math.min(S.r,7)]}${enter ? " kb-enter" : ""}"><div class="kb-fl" aria-hidden="true"></div>${head()}<div class="kb-type">${ty[0]} ${ty[1]}</div><div class="kb-time"><i style="width:${Math.max(0, (S.end - Date.now()) / (S.total * 10))}%"></i></div><div class="kb-secs">${Math.max(0, (S.end - Date.now()) / 1000).toFixed(1)} วิ</div>${body}<p class="kb-msg">${esc(S.msg)}</p><div class="row" style="justify-content:center;gap:8px">${S.lock && S.adv ? '<button class="btn gold small" onclick="KB.go()">ต่อไป ▶</button>' : ""}<button class="btn ghost small" onclick="KB.quit()">ยอมแพ้</button></div></div>`;
  }
  function resView() {
    const r = S.res;
    return `<div class="card center gm-res ${r.won ? "perfect" : ""}"><div class="kb-hero">${KIMG}</div><h2>${r.won ? "🏆 คุณชนะครูบุ๊ค!" : "💔 พ่ายแพ้ให้ครูบุ๊ค"}</h2><p class="kb-say">💬 ${S.say}</p>
      <p class="muted">ผ่าน ${r.cleared}/8 รอบ · ใช้เวลา ${r.secs} วินาที</p>
      <p>${r.no_reward ? '<span class="pill">ครบรอบที่ได้รางวัลของวันนี้แล้ว (ฝึกได้ไม่จำกัด)</span>' : `<span class="pill">+${r.exp} EXP</span> ${r.coins ? `<span class="pill">+${r.coins} 🪙</span>` : ""}`}</p>
      <div class="row" style="justify-content:center"><button class="btn gold" onclick="KB.start()">ท้าอีกครั้ง</button><button class="btn ghost" onclick="KB.open()">เมนู</button><button class="btn ghost" onclick="GAMES.home()">กลับหน้าเกม</button></div></div>`;
  }
  return { open, view, start, quit, pick: pickOpt, tap, mem, bal, balCheck, pn: pairName, ps: pairSym, tf: (v) => blitzAns(v), go: advance };
})();
