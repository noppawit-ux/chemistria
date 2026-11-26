/* แท็บ: กิจกรรมพลิกเกม (SQL 123) — แสดงใต้แท็บมินิเกม */
TAB.flip = async function (v) {
  const h = holder(v, "🔥 กิจกรรมพลิกเกม",
    "ตั้งช่วงวันที่ + เกม (เว้นว่าง = รวมทุกเกม) · อันดับ 1–3 ของแต่ละห้องรับรางวัล ทุกคนที่ร่วมได้รางวัลร่วมกิจกรรม · รางวัลไม่นับเพดานเล่นต่อวัน · จบเองอัตโนมัติเมื่อพ้นวันสิ้นสุด หรือกดปุ่มปิดด้านล่าง");
  await crud(h, { table: "flip_events", order: "starts_on", defaults: { active: true, handicap: true, p1_exp: 300, p1_coins: 150, p2_exp: 200, p2_coins: 100, p3_exp: 120, p3_coins: 60, part_exp: 20, part_coins: 10 }, addLabel: "เพิ่มกิจกรรม",
    cols: [{ k: "title", label: "ชื่อกิจกรรม", w: 160 }, { k: "descr", label: "คำอธิบาย", w: 200 },
      { k: "game", label: "เกม", t: "select", opts: () => [["", "ทุกเกมรวมกัน"], ["quiz", "ควิซ"], ["match", "จับคู่"], ["spell", "สเปลล์"], ["kb", "ประลองครูบุ๊ค"], ["run", "เคมีรัน"]] },
      { k: "starts_on", label: "เริ่ม", t: "date" }, { k: "ends_on", label: "สิ้นสุด", t: "date" }, { k: "handicap", label: "โบนัสพลิกเกม", t: "bool" },
      { k: "p1_exp", label: "🥇EXP", t: "number", w: 60 }, { k: "p1_coins", label: "🥇เหรียญ", t: "number", w: 60 },
      { k: "p2_exp", label: "🥈EXP", t: "number", w: 60 }, { k: "p2_coins", label: "🥈เหรียญ", t: "number", w: 60 },
      { k: "p3_exp", label: "🥉EXP", t: "number", w: 60 }, { k: "p3_coins", label: "🥉เหรียญ", t: "number", w: 60 },
      { k: "part_exp", label: "ร่วม EXP", t: "number", w: 60 }, { k: "part_coins", label: "ร่วมเหรียญ", t: "number", w: 60 }, { k: "active", label: "เปิด", t: "bool" }] });
  const open = must(await sb.from("flip_events").select("id,title,ends_on").is("finalized_at", null).eq("active", true).order("starts_on"));
  const box = document.createElement("div"); box.className = "card";
  box.innerHTML = `<h4 style="margin:0 0 6px">ปิดกิจกรรมและแจกรางวัลเดี๋ยวนี้</h4>` + (open.length ? open.map((e) => `<div class="row" style="margin:4px 0"><span class="grow">${esc(e.title)} (สิ้นสุด ${e.ends_on})</span><button class="btn small gold" data-id="${e.id}">ปิด + แจกรางวัล</button></div>`).join("") : '<p class="muted">ไม่มีกิจกรรมที่กำลังเปิดอยู่</p>');
  box.querySelectorAll("button[data-id]").forEach((b) => b.onclick = async () => {
    if (!confirm("ปิดกิจกรรมและแจกรางวัลตามอันดับตอนนี้เลย? ทำซ้ำไม่ได้")) return;
    try { const n = must(await sb.rpc("flip_close", { p_event: b.dataset.id })); toast(`แจกรางวัลแล้ว ${n} คน`); b.closest(".row").remove(); } catch (e) { toast(e.message); }
  });
  h.appendChild(box);
};
