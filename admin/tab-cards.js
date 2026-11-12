/* แท็บ: cards — ชุดการ์ดสะสม · การ์ด · ตั้งค่าอัตราดรอป */
TAB.cards = async function (v) {
  const set = Object.fromEntries(must(await sb.from("app_settings").select("*").like("key", "card\\_%")).map((x) => [x.key, x.value]));
  const f = [["card_drop_pct", "โอกาสได้การ์ดเมื่อชนะมอนสเตอร์ (%)", 30], ["card_best_bonus", "(ไม่ใช้แล้ว)", 25], ["card_daily_cap", "โควต้าการ์ดจากมอนสเตอร์ต่อคนต่อวัน", 5],
    ["card_pity", "pity: ซ้ำติดกันครบ (ครั้ง−1) → ใบถัดไปเป็นใบใหม่", 4], ["card_gacha_pct", "(ไม่ใช้แล้ว — กาชาไม่แถมการ์ด)", 40],
    ["card_w_n", "น้ำหนักสุ่ม N", 60], ["card_w_r", "น้ำหนักสุ่ม R", 28], ["card_w_sr", "น้ำหนักสุ่ม SR", 10], ["card_w_ssr", "น้ำหนักสุ่ม SSR", 2]];
  const st = holder(v, "🃏 ตั้งค่าการ์ดสะสม", "ใบซ้ำ → เศษธาตุ (N=1 · R=3 · SR=10 · SSR=30) · ใบแรกของนักเรียนแต่ละคนได้แน่นอน · การ์ดที่ปิดใช้งานจะไม่ถูกสุ่ม");
  st.innerHTML = `<div class="row">${f.map(([k, l, d]) => `<div style="width:250px"><label>${l}</label><input type="number" min="0" data-set="${k}" value="${esc(set[k] ?? d)}"></div>`).join("")}</div>`;
  st.onchange = async (e) => { const k = e.target.dataset.set; if (!k) return; await run(async () => must(await sb.from("app_settings").upsert({ key: k, value: String(Math.max(0, parseInt(e.target.value, 10) || 0)) })), "บันทึกแล้ว ✅"); };
  const decs = must(await sb.from("decor_items").select("id,name").order("name"));
  const sets = must(await sb.from("card_sets").select("id,title,emoji").order("sort"));
  const hs = holder(v, "📚 ชุดการ์ด", "รางวัลเมื่อสะสมครบทุกใบในชุด (ได้ครั้งเดียวต่อคน)");
  await crud(hs, { table: "card_sets", order: "sort", defaults: { emoji: "📖", color: "#7c4dff", reward_coins: 100, reward_pulls: 1, sort: 9, active: true }, addLabel: "เพิ่มชุด",
    cols: [{ k: "emoji", label: "อีโมจิ", w: 50 }, { k: "title", label: "ชื่อชุด", w: 160 }, { k: "code", label: "รหัส (อังกฤษ ไม่ซ้ำ)", w: 110 }, { k: "color", label: "สี", w: 80 },
      { k: "reward_coins", label: "🪙 รางวัล", t: "number", w: 70 }, { k: "reward_pulls", label: "🎟️ ตั๋ว", t: "number", w: 60 },
      { k: "reward_decor", label: "🎨 ไอเทม", t: "select", opts: () => [["", "—"], ...decs.map((d) => [d.id, d.name])] }, { k: "sort", label: "ลำดับ", t: "number", w: 55 }, { k: "active", label: "เปิด", t: "bool" }] });
  S.cset = sets.find((s) => s.id === S.cset) ? S.cset : sets[0]?.id;
  const hc = holder(v, "🃏 การ์ดในชุด", "ใส่ข้อเท็จจริงสั้น ๆ 1 บรรทัดให้ทุกใบ (นักเรียนอ่านตอนได้การ์ด) · symbol = ตัวอักษรใหญ่บนการ์ด เช่น H, Au");
  if (!sets.length) { hc.innerHTML = '<p class="muted">ยังไม่มีชุดการ์ด</p>'; return; }
  const cnt = must(await sb.from("cards").select("set_id,rarity")), by = (id) => ["N", "R", "SR", "SSR"].map((r) => `${r} ${cnt.filter((c) => c.set_id === id && c.rarity === r).length}`).join(" · ");
  hc.innerHTML = `<div class="row" style="margin-bottom:8px"><select id="cset">${sets.map((s) => `<option value="${s.id}" ${s.id === S.cset ? "selected" : ""}>${esc(s.emoji)} ${esc(s.title)}</option>`).join("")}</select><span class="muted">${by(S.cset)}</span></div><div id="chost"></div>`;
  const draw = () => crud($("#chost", hc), { table: "cards", order: "no", filter: { set_id: S.cset }, addLabel: "เพิ่มการ์ด", defaults: { rarity: "N", emoji: "🃏", active: true, no: 99 },
    cols: [{ k: "no", label: "#", t: "number", w: 45 }, { k: "emoji", label: "อีโมจิ", w: 50 }, { k: "symbol", label: "symbol", w: 70 }, { k: "name", label: "ชื่อ", w: 150 },
      { k: "rarity", label: "ระดับ", t: "select", opts: () => [["N", "N"], ["R", "R"], ["SR", "SR"], ["SSR", "SSR"]] }, { k: "fact", label: "ข้อเท็จจริง", w: 320 }, { k: "image_url", label: "รูป (ไม่บังคับ)", w: 130 }, { k: "active", label: "เปิด", t: "bool" }] });
  $("#cset", hc).onchange = (e) => { S.cset = e.target.value; draw(); };
  draw();
};
