/* แท็บ: decor */
TAB.decor = async function (v) {
  const h = holder(v, "🎨 ไอเทมตกแต่งตัวละคร",
    "ใส่ราคา = วางขายในร้านของนักเรียน · เว้นราคาว่าง = ได้จากกาชาเท่านั้น (ต้องไปเพิ่มในแท็บกาชา ชนิด “ไอเทมตกแต่ง” ด้วย) · สไตล์ที่ใช้ได้: กรอบ = solid(ใส่สี) ice flame neon gold rainbow · พื้นหลัง = solid(ใส่สี) sunset forest lab galaxy aurora · หมวก/สัตว์เลี้ยง = ใช้ emoji ในช่อง “อีโมจิ” (สไตล์ emoji) · ฉายา = text · ชุด = ใส่ชื่อไฟล์ท้ายในช่องสไตล์ (เช่น space → assets/chars/<คลาส>_space.png) · เอฟเฟค = sparkle bubbles flame ice lightning orbit · ไอเทมถือ = สไตล์ img + ใส่พาธภาพ เช่น assets/items/wand.png");
  await crud(h, { table: "decor_items", order: "slot", defaults: { slot: "frame", key: "solid", rarity: "N", sort: 0, st_int: 0, st_dil: 0, st_str: 0, st_luk: 0, st_coin: 0, emoji: "✨", active: true },
    cols: [{ k: "slot", label: "ช่อง", t: "select", opts: () => [["frame", "กรอบ"], ["bg", "พื้นหลัง"], ["hat", "หมวก"], ["pet", "สัตว์เลี้ยง"], ["title", "ฉายา"], ["outfit", "ชุด"], ["fx", "เอฟเฟค"], ["item", "ไอเทมถือ"]] },
      { k: "name", label: "ชื่อ", w: 140 }, { k: "emoji", label: "อีโมจิ", w: 50 }, { k: "key", label: "สไตล์", w: 80 }, { k: "color", label: "สี (#hex)", w: 80 },
      { k: "rarity", label: "ระดับ", t: "select", opts: () => ["N", "R", "SR", "SSR"].map((x) => [x, x]) }, { k: "price", label: "ราคา(เหรียญ)", t: "number", w: 80 },
      { k: "image", label: "ภาพ (ไอเทมถือ)", w: 150 }, { k: "st_int", label: "🧠ปัญญา", t: "number", w: 55 }, { k: "st_dil", label: "💪ขยัน", t: "number", w: 55 }, { k: "st_str", label: "⚔️พลัง", t: "number", w: 55 }, { k: "st_luk", label: "🍀โชค", t: "number", w: 55 }, { k: "st_coin", label: "🪙เหรียญ%", t: "number", w: 60 }, { k: "ability", label: "ความสามารถ (ข้อความ)", w: 180 },
      { k: "sort", label: "ลำดับ", t: "number", w: 60 }, { k: "active", label: "เปิด", t: "bool" }] });
};
