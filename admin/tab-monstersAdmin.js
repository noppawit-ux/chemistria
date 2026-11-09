/* แท็บ: monstersAdmin */
TAB.monstersAdmin = async function (v) {
  const h = holder(v, "👾 มอนสเตอร์เคมี (มินิเกมต่อสู้)", "ปรับ HP/พลังโจมตี/รางวัลได้ · คำถามในเกมใช้คลังคำถามควิซด้านบน · ภาพใส่ path เช่น assets/monsters/bubble.png");
  await crud(h, { table: "monsters", order: "sort", defaults: { emoji: "👾", level: 1, hp: 60, atk: 8, exp: 10, coins: 5, atk_name: "พุ่งชน", active: true, sort: 9 },
    cols: [{ k: "key", label: "รหัส", w: 80 }, { k: "name", label: "ชื่อ", w: 130 }, { k: "emoji", label: "อีโมจิ", w: 50 }, { k: "image", label: "ภาพ", w: 170 }, { k: "level", label: "เลเวล(1-5)", t: "number", w: 60 },
      { k: "hp", label: "HP", t: "number", w: 60 }, { k: "atk", label: "โจมตี", t: "number", w: 60 }, { k: "exp", label: "EXP", t: "number", w: 60 }, { k: "coins", label: "เหรียญ", t: "number", w: 60 },
      { k: "atk_name", label: "ชื่อท่าโจมตี", w: 120 }, { k: "descr", label: "คำอธิบาย", w: 200 }, { k: "arena", label: "สนาม (รหัส)", w: 80 }, { k: "sort", label: "ลำดับ", t: "number", w: 50 }, { k: "active", label: "เปิด", t: "bool" }] });
};
