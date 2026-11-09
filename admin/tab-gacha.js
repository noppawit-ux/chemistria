/* แท็บ: gacha */
TAB.gacha = async function (v) {
  const items = must(await sb.from("gacha_items").select("rarity,weight,active"));
  const tot = items.filter((i) => i.active).reduce((a, i) => a + i.weight, 0) || 1;
  const by = {}; items.filter((i) => i.active).forEach((i) => (by[i.rarity] = (by[i.rarity] || 0) + i.weight));
  const privs = must(await sb.from("privileges").select("id,name").order("name"));
  const decs = must(await sb.from("decor_items").select("id,name").order("name"));
  const h = holder(v, "🎰 ไอเทมในตู้กาชา",
    `โอกาสออกต่อชนิด: ${["N", "R", "SR", "SSR"].map((r) => `${r} ${(((by[r] || 0) / tot) * 100).toFixed(1)}%`).join(" · ")} (ยังไม่รวมการันตี) · ชนิด coins/exp ใช้ช่อง “ค่า” เป็นจำนวน · ชนิด privilege เลือกสิทธิพิเศษ · ชนิด “ไอเทมตกแต่ง” เลือกไอเทมจากแท็บ 🎨 ตกแต่ง · cosmetic = อีโมจิอวาตาร์`);
  await crud(h, { table: "gacha_items", order: "rarity", defaults: { rarity: "N", kind: "coins", value: 10, weight: 10, active: true, emoji: "🎁" },
    cols: [{ k: "emoji", label: "อีโมจิ", w: 50 }, { k: "name", label: "ชื่อ", w: 160 }, { k: "rarity", label: "ระดับ", t: "select", opts: () => ["N", "R", "SR", "SSR"].map((x) => [x, x]) },
      { k: "kind", label: "ชนิด", t: "select", opts: () => [["coins", "เหรียญ"], ["exp", "EXP"], ["cosmetic", "อวาตาร์"], ["privilege", "สิทธิพิเศษ"], ["decor", "ไอเทมตกแต่ง"]] },
      { k: "value", label: "ค่า", t: "number", w: 60 }, { k: "privilege_id", label: "สิทธิพิเศษ", t: "select", opts: () => [["", "—"], ...privs.map((p) => [p.id, p.name])] },
      { k: "decor_id", label: "ไอเทมตกแต่ง", t: "select", opts: () => [["", "—"], ...decs.map((p) => [p.id, p.name])] },
      { k: "image_url", label: "รูป (assets/items/…png)", w: 190 }, { k: "weight", label: "น้ำหนัก", t: "number", w: 60 }, { k: "active", label: "เปิด", t: "bool" }] });
};
