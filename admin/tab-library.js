/* แท็บ: ห้องสมุด (SQL 126) — แสดงใต้แท็บมินิเกม */
TAB.library = async function (v) {
  const h = holder(v, "📚 ห้องสมุด",
    "เพิ่มบทความ/วิดีโอให้นักเรียนอ่านแล้วรับ EXP/เหรียญ · วิดีโอใส่ลิงก์ YouTube (แสดงเป็นภาพปก · นักเรียนต้องดูจนจบ ≥ 90% ถึงรับรางวัล · กรอข้ามไม่นับ) หรือไฟล์ .mp4 (เช่น assets/reels/xxx.mp4 ใน repo ต้องเป็นลิงก์เต็ม https://…) · บทความพิมพ์ในช่องเนื้อหา (บรรทัดขึ้นต้น \"# \" = หัวข้อ) · เว้นห้องว่าง = ทุกห้อง · คำถามท้ายเรื่อง: ตัวเลือกคั่นด้วย | และเฉลยเป็นเลขข้อ (เริ่มที่ 1) · ได้รางวัลครั้งเดียวต่อเรื่อง และไม่เกิน library_daily_max เรื่อง/วัน (ตั้งค่าในแท็บตั้งค่า)");
  const classes = must(await sb.from("classes").select("id,name").order("name"));
  await crud(h, { table: "library_items", order: "sort", defaults: { active: true, kind: "article", icon: "📖", min_secs: 60, exp: 10, coins: 5, sort: 0 }, addLabel: "➕ เพิ่มเนื้อหา",
    cols: [{ k: "title", label: "ชื่อเรื่อง", w: 160 }, { k: "icon", label: "ไอคอน", w: 50 },
      { k: "kind", label: "ประเภท", t: "select", opts: () => [["article", "บทความ"], ["video", "วิดีโอ"]] },
      { k: "class_id", label: "ห้อง", t: "select", opts: () => [["", "ทุกห้อง"], ...classes.map((c) => [c.id, c.name])] },
      { k: "category", label: "หมวด", w: 90 }, { k: "summary", label: "สรุปสั้น", w: 180 },
      { k: "url", label: "ลิงก์ (YouTube/เว็บ)", w: 200 }, { k: "body", label: "เนื้อหาบทความ", t: "area", w: 260 },
      { k: "min_secs", label: "เวลาขั้นต่ำ (วิ)", t: "number", w: 70 }, { k: "exp", label: "EXP", t: "number", w: 55 }, { k: "coins", label: "เหรียญ", t: "number", w: 55 },
      { k: "q_text", label: "คำถามท้ายเรื่อง", w: 180 }, { k: "q_opts", label: "ตัวเลือก (คั่น |)", w: 200 }, { k: "q_ans", label: "เฉลย (ข้อที่)", t: "number", w: 60 },
      { k: "sort", label: "ลำดับ", t: "number", w: 50 }, { k: "active", label: "เปิด", t: "bool" }] });
  const rows = must(await sb.from("library_reads").select("item_id,done_at").not("done_at", "is", null));
  const items = must(await sb.from("library_items").select("id,title")), cnt = {};
  rows.forEach((r) => cnt[r.item_id] = (cnt[r.item_id] || 0) + 1);
  const box = document.createElement("div"); box.className = "card";
  box.innerHTML = `<h4 style="margin:0 0 6px">📊 จำนวนนักเรียนที่อ่านจบ</h4>` + (items.length ? items.map((i) => `<div>${esc(i.title)} — <b>${cnt[i.id] || 0}</b> คน</div>`).join("") : '<span class="muted">ยังไม่มีเนื้อหา</span>');
  h.appendChild(box);
};
