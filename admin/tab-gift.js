/* แท็บ: gift — แจกของขวัญให้นักเรียนหลายคนพร้อมกัน (EXP · เหรียญ · ตั๋วกาชา · ไอเทมตกแต่ง · สิทธิพิเศษ) */
TAB.gift = async function (v) {
  const [cls, stu, decs, privs, cds] = await Promise.all([
    sb.from("classes").select("id,name,code").order("name"), sb.from("students").select("id,class_id,no,name,is_gm").order("no"),
    sb.from("decor_items").select("id,name,emoji,rarity").order("name"), sb.from("privileges").select("id,name,emoji,active").order("name"), sb.from("cards").select("id,name,emoji,rarity,symbol").order("name")]).then((r) => r.map(must));
  const classes = cls.filter((c) => c.code !== "GM"), ok = new Set(classes.map((c) => c.id));
  const list = stu.filter((s) => ok.has(s.class_id) && !s.is_gm);
  const sel = new Set();
  const h = holder(v, "🎁 แจกของขวัญ", "เลือกนักเรียนหลายคน (หรือทั้งห้อง) แล้วกำหนดของขวัญ — นักเรียนจะเห็นป๊อปอัปตอนเปิดแอปครั้งถัดไป");
  h.innerHTML = `<div id="gpick"></div>
    <div class="grid2" style="margin-top:10px">
      <div class="field"><label>⭐ EXP</label><input id="gexp" type="number" min="0" max="10000" value="0"></div>
      <div class="field"><label>🪙 เหรียญ</label><input id="gcoin" type="number" min="0" max="10000" value="0"></div>
      <div class="field"><label>🎟️ ตั๋วสุ่มกาชาฟรี</label><input id="gpull" type="number" min="0" max="50" value="0"></div>
      <div class="field"><label>🎨 ไอเทมตกแต่ง</label><select id="gdec"><option value="">— ไม่ให้ —</option>${decs.map((d) => `<option value="${d.id}">${esc(d.emoji || "")} ${esc(d.name)} (${esc(d.rarity || "")})</option>`).join("")}</select></div>
      <div class="field"><label>🎫 สิทธิพิเศษ</label><select id="gpriv"><option value="">— ไม่ให้ —</option>${privs.map((p) => `<option value="${p.id}">${esc(p.emoji || "")} ${esc(p.name)}</option>`).join("")}</select></div>
      <div class="field"><label>🃏 การ์ดสะสม</label><select id="gcard"><option value="">— ไม่ให้ —</option>${cds.map((c) => `<option value="${c.id}">${esc(c.emoji || "")} ${esc(c.name)} (${esc(c.rarity)})</option>`).join("")}</select></div>
      <div class="field"><label>จำนวนใบ</label><input id="gcardn" type="number" min="1" max="10" value="1"></div>
    </div>
    <div class="field"><label>💬 ข้อความถึงนักเรียน (ไม่บังคับ)</label><input id="gmsg" maxlength="200" placeholder="เช่น ขอบคุณที่ตั้งใจเรียนนะ"></div>
    <button class="btn gold" id="gsend">🎁 ส่งของขวัญ</button> <span class="muted" id="gcount"></span><div id="gres" style="margin-top:8px"></div>`;
  const pick = $("#gpick", h);
  const draw = () => {
    pick.innerHTML = `<div class="row" style="gap:6px;flex-wrap:wrap"><button class="btn ghost small" data-all="1">เลือกทั้งหมด</button><button class="btn ghost small" data-all="0">ล้างทั้งหมด</button></div>` +
      classes.map((c) => { const m = list.filter((s) => s.class_id === c.id), n = m.filter((s) => sel.has(s.id)).length;
        return `<details style="margin-top:6px"><summary><b>${esc(c.name)}</b> <span class="muted">${n}/${m.length}</span> <button class="btn ghost small" data-cls="${c.id}">${n === m.length && m.length ? "ล้างห้องนี้" : "เลือกทั้งห้อง"}</button></summary>
          <div style="display:flex;flex-wrap:wrap;gap:4px 12px;padding:6px 0">${m.map((s) => `<label style="white-space:nowrap"><input type="checkbox" data-s="${s.id}" ${sel.has(s.id) ? "checked" : ""}> ${s.no}. ${esc(s.name)}</label>`).join("")}</div></details>`; }).join("");
    $("#gcount", h).textContent = `เลือกแล้ว ${sel.size} คน`;
    $$("[data-s]", pick).forEach((i) => (i.onchange = () => { i.checked ? sel.add(i.dataset.s) : sel.delete(i.dataset.s); $("#gcount", h).textContent = `เลือกแล้ว ${sel.size} คน`; }));
    $$("[data-all]", pick).forEach((b) => (b.onclick = () => { sel.clear(); if (b.dataset.all === "1") list.forEach((s) => sel.add(s.id)); draw(); }));
    $$("[data-cls]", pick).forEach((b) => (b.onclick = (e) => { e.preventDefault(); const m = list.filter((s) => s.class_id === b.dataset.cls), all = m.every((s) => sel.has(s.id)); m.forEach((s) => (all ? sel.delete(s.id) : sel.add(s.id))); draw(); }));
  };
  draw();
  $("#gsend", h).onclick = async () => {
    const n = (id) => Math.max(0, parseInt($(id, h).value, 10) || 0), exp = n("#gexp"), coins = n("#gcoin"), pulls = n("#gpull"), dec = $("#gdec", h).value || null, pv = $("#gpriv", h).value || null, cd = $("#gcard", h).value || null, cdn = Math.min(10, Math.max(1, parseInt($("#gcardn", h).value, 10) || 1)), msg = $("#gmsg", h).value.trim();
    if (!sel.size) return toast("ยังไม่ได้เลือกนักเรียน");
    if (!(exp || coins || pulls || dec || pv || cd)) return toast("ยังไม่ได้ใส่ของขวัญ");
    const parts = [exp && `⭐${exp} EXP`, coins && `🪙${coins}`, pulls && `🎟️×${pulls}`, dec && "🎨 " + $("#gdec", h).selectedOptions[0].text, pv && "🎫 " + $("#gpriv", h).selectedOptions[0].text, cd && "🃏 " + $("#gcard", h).selectedOptions[0].text + " ×" + cdn].filter(Boolean);
    if (!confirm(`ส่งให้ ${sel.size} คน:\n${parts.join("\n")}${msg ? "\n“" + msg + "”" : ""}\n\n(ย้อนไม่ได้ — ยืนยัน?)`)) return;
    const r = await run(() => rpc("admin_gift", { p_students: [...sel], p_exp: exp, p_coins: coins, p_pulls: pulls, p_decor: dec, p_priv: pv, p_message: msg, p_card: cd, p_card_n: cdn }), "ส่งของขวัญแล้ว 🎁");
    $("#gres", h).innerHTML = `<div class="card">✅ ส่งให้ <b>${r.given}</b> คน${r.decor_already_owned ? ` · มี ${r.decor_already_owned} คนมีไอเทมตกแต่งนี้อยู่แล้ว (ข้าม)` : ""}</div>`;
    sel.clear(); draw();
  };
};
