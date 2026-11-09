/* แท็บ: boss */
TAB.boss = async function (v) {
  const h = holder(v, "👹 บอสประจำสัปดาห์",
    "เลือดบอส = “เลือดต่อคน” × จำนวนนักเรียนในห้อง · ความเสียหาย = EXP ของเควสที่สำเร็จ (อนุมัติแล้ว) ของทั้งห้องในช่วงที่บอสเปิด (เควสอัตโนมัติก็นับ) · มีบอสหมุนเวียน 6 ตัวตั้งไว้ให้ ตัวละ 1 สัปดาห์ต่อเนื่องกัน · ปราบได้ → ทุกคนที่ช่วยโจมตีอย่างน้อย 1 ครั้งกดรับรางวัลได้ · เว้นห้องว่าง = บอสของทุกห้อง · วันเริ่มควรเป็นวันจันทร์ · ถ้ามีบอสเฉพาะห้องและบอสทุกห้องพร้อมกัน จะใช้บอสเฉพาะห้อง");
  await crud(h, { table: "bosses", order: "start_date", defaults: { emoji: "👹", hp_per_student: 150, days: 7, reward_exp: 50, reward_coins: 30, active: true, start_date: ymd(new Date(Date.now() - ((new Date().getDay() + 6) % 7) * 86400000)) },
    cols: [{ k: "image", label: "ภาพมอนสเตอร์", t: "select", opts: () => [["", "(ใช้อีโมจิ)"], ["assets/bosses/acid_dragon.png", "มังกรกรด"], ["assets/bosses/beaker_golem.png", "โกเลมบีกเกอร์"], ["assets/bosses/electron_wizard.png", "จอมเวทอิเล็กตรอน"], ["assets/bosses/element_robot.png", "หุ่นยนต์ธาตุ"], ["assets/bosses/flame_demon.png", "ปีศาจเพลิง"], ["assets/bosses/germ_hydra.png", "ไฮดราเชื้อโรค"]] }, { k: "emoji", label: "ไอคอนสำรอง", w: 50 }, { k: "abilities", label: "ความสามารถ (ไอคอน|ชื่อ|คำอธิบาย ;; ...)", t: "abil", w: 260 }, { k: "name", label: "ชื่อบอส", w: 160 }, { k: "description", label: "คำอธิบาย", w: 200 },
      { k: "class_id", label: "ห้อง", t: "select", opts: classOpts("ทุกห้อง") }, { k: "hp_per_student", label: "เลือด/คน", t: "number", w: 70 },
      { k: "start_date", label: "เริ่ม", t: "date" }, { k: "days", label: "กี่วัน", t: "number", w: 60 },
      { k: "reward_exp", label: "รางวัล EXP", t: "number", w: 70 }, { k: "reward_coins", label: "รางวัลเหรียญ", t: "number", w: 70 }, { k: "active", label: "เปิด", t: "bool" }] });
};
