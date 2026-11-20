/* แท็บ: คลังข้อสอบดันเจี้ยน + คลังไอเทมดันเจี้ยน/ประลองครูบุ๊ค (SQL 115) — แสดงต่อท้ายหน้า "เกม" */
TAB.banks = async function (v) {
  const dgs = must(await sb.from("dungeons").select("key,name,emoji").order("sort"));
  const cons = must(await sb.from("consumables").select("key,name,emoji").order("sort"));
  const decs = must(await sb.from("decor_items").select("id,name").order("name"));
  const dgOpts = [["", "ทุกดันเจี้ยน"], ...dgs.map((d) => [d.key, `${d.emoji} ${d.name}`])];

  const hq = holder(v, "🏰 คลังข้อสอบดันเจี้ยน",
    "ศึกในดันเจี้ยนสุ่มคำถามจากคลังนี้ (ไม่ปนกับคลังควิซรายวัน) · เลือกตามระดับชั้นของนักเรียน (ม.ต้น = ม.1–3, นอกนั้นเป็น ม.ปลาย) และความยากของชั้น: ชั้น 1–2 ใช้ข้อง่าย, 3–4 ใช้ข้อกลาง, ชั้นบอสใช้ข้อยาก (ดันเจี้ยนระดับ ⭐4 ขึ้นไปยากขึ้นอีกขั้น) · ถ้าปิดข้อไว้ทั้งหมดหรือคลังว่าง ระบบจะใช้คลังควิซเดิม");
  await crud(hq, { table: "quiz_questions", order: "topic", filter: { pool: "dungeon" }, defaults: { topic: "ดันเจี้ยน", answer: 0, active: false, pool_on: true, lvl: 1, grade: "all" },
    cols: [{ k: "topic", label: "หัวข้อ", w: 90 },
      { k: "grade", label: "ระดับชั้น", t: "select", opts: () => [["all", "ทุกระดับ"], ["jr", "ม.ต้น"], ["hs", "ม.ปลาย"]] },
      { k: "lvl", label: "ความยาก", t: "select", opts: () => [["1", "1 ง่าย"], ["2", "2 กลาง"], ["3", "3 ยาก"]] },
      { k: "dungeon_key", label: "ดันเจี้ยน", t: "select", opts: () => dgOpts },
      { k: "question", label: "คำถาม", w: 260 }, { k: "a", label: "ก", w: 100 }, { k: "b", label: "ข", w: 100 }, { k: "c", label: "ค", w: 100 }, { k: "d", label: "ง", w: 100 },
      { k: "answer", label: "ข้อที่ถูก", t: "select", opts: () => [["0", "ก"], ["1", "ข"], ["2", "ค"], ["3", "ง"]] },
      { k: "explain", label: "คำอธิบายเฉลย", w: 220 }, { k: "pool_on", label: "เปิดใช้", t: "bool" }] });

  const hl = holder(v, "🎁 คลังไอเทมรางวัล (หีบดันเจี้ยน / ชนะครูบุ๊ค)",
    "แหล่ง: เลือกดันเจี้ยนแต่ละแห่ง, “dungeon:*” = ใช้กับทุกดันเจี้ยน, “kb” = สุ่มให้เมื่อชนะประลองครูบุ๊ค · ชนิด: เหรียญ/EXP ใส่จำนวนในช่อง “ค่า” · ไอเทมใช้ (ยา/ม้วน) เลือกรหัสไอเทมในช่อง “ไอเทมใช้” · ไอเทมตกแต่ง เลือกในช่อง “ไอเทมตกแต่ง” (ซ้ำจะแปลงเป็นเหรียญ) · น้ำหนักยิ่งมาก ยิ่งออกบ่อย · “เฉพาะบอส” = ออกจากหีบหลังพิชิตเท่านั้น · หีบดันเจี้ยนแต่ละใบ: ใบแรกการันตี ใบที่สองสุ่มตามโชค · ถ้าแหล่งนั้นไม่มีรายการเปิดใช้ ระบบใช้ตู้ดรอปเดิม");
  await crud(hl, { table: "loot_items", order: "source", defaults: { source: "kb", kind: "coins", emoji: "🎁", rarity: "R", value: 20, weight: 10, boss_only: false, active: true, sort: 9 },
    cols: [{ k: "source", label: "แหล่ง", t: "select", opts: () => [["kb", "🏆 ชนะครูบุ๊ค"], ["dungeon:*", "🏰 ทุกดันเจี้ยน"], ...dgs.map((d) => [`dungeon:${d.key}`, `${d.emoji} ${d.name}`])] },
      { k: "kind", label: "ชนิด", t: "select", opts: () => [["coins", "เหรียญ"], ["exp", "EXP"], ["consumable", "ไอเทมใช้"], ["decor", "ไอเทมตกแต่ง"]] },
      { k: "emoji", label: "อีโมจิ", w: 50 }, { k: "name", label: "ชื่อที่แสดง", w: 150 },
      { k: "rarity", label: "ระดับ", t: "select", opts: () => ["N", "R", "SR", "SSR"].map((x) => [x, x]) },
      { k: "value", label: "ค่า", t: "number", w: 60 },
      { k: "ref_key", label: "ไอเทมใช้", t: "select", opts: () => [["", "—"], ...cons.map((c) => [c.key, `${c.emoji} ${c.name}`])] },
      { k: "decor_id", label: "ไอเทมตกแต่ง", t: "select", opts: () => [["", "—"], ...decs.map((d) => [d.id, d.name])] },
      { k: "image", label: "รูป (ไม่บังคับ)", w: 140 }, { k: "weight", label: "น้ำหนัก", t: "number", w: 60 },
      { k: "boss_only", label: "เฉพาะบอส", t: "bool" }, { k: "active", label: "เปิด", t: "bool" }] });
};
