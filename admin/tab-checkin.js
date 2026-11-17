/* แท็บ: checkin — เปิดอีเว้นท์เช็คอินรับของรางวัล (นักเรียนทุกคนกดรับได้คนละครั้ง) */
TAB.checkin = async function (v) {
  const [decs, cds] = await Promise.all([sb.from("decor_items").select("id,name,emoji,rarity").order("name"), sb.from("cards").select("id,name,emoji,rarity").order("name")]).then((r) => r.map(must));
  const h = holder(v, "🎟️ เช็คอินรับของรางวัล", "เปิดอีเว้นท์ทันทีตามจำนวนชั่วโมงที่กำหนด — นักเรียนทุกห้องจะเห็นแบนเนอร์ที่หน้าแรกและกด “เช็คอินรับรางวัล” ได้คนละ 1 ครั้ง · ปิดก่อนเวลาได้");
  const opt = (a) => `<option value="">— ไม่มี —</option>` + a.map((x) => `<option value="${x.id}">${esc(x.emoji || "")} ${esc(x.name)} (${esc(x.rarity || "")})</option>`).join("");
  h.innerHTML = `<div class="card"><div class="grid2">
      <div class="field"><label>ชื่ออีเว้นท์</label><input id="ctitle" maxlength="80" placeholder="เช่น เช็คอินต้อนรับเปิดเทอม"></div>
      <div class="field"><label>เปิดนาน (ชั่วโมง)</label><input id="chours" type="number" min="1" max="1440" value="24"></div>
      <div class="field"><label>⭐ EXP</label><input id="cexp" type="number" min="0" max="10000" value="0"></div>
      <div class="field"><label>🪙 เหรียญ</label><input id="ccoin" type="number" min="0" max="10000" value="0"></div>
      <div class="field"><label>🎟️ ตั๋วกาชาฟรี</label><input id="cpull" type="number" min="0" max="50" value="0"></div>
      <div class="field"><label>🎨 ไอเทมตกแต่ง</label><select id="cdec">${opt(decs)}</select></div>
      <div class="field"><label>🃏 การ์ด (1 ใบ)</label><select id="ccard">${opt(cds)}</select></div>
      <div class="field"><label>💬 ข้อความ (ไม่บังคับ)</label><input id="cmsg" maxlength="200"></div></div>
    <button class="btn gold" id="copen">🎟️ เปิดอีเว้นท์</button></div><div id="clist" style="margin-top:10px"></div>`;
  const draw = async () => {
    const ev = must(await sb.from("checkin_events").select("*").order("created_at", { ascending: false }).limit(30));
    const cl = must(await sb.from("checkin_claims").select("event_id"));
    const cnt = {}; cl.forEach((c) => (cnt[c.event_id] = (cnt[c.event_id] || 0) + 1));
    const nStu = (must(await sb.from("students").select("id", { count: "exact", head: false }).eq("is_gm", false))).length;
    $("#clist", h).innerHTML = ev.length ? ev.map((e) => {
      const live = !e.closed && new Date(e.ends_at) > new Date() && new Date(e.starts_at) <= new Date();
      const prize = [e.exp && `⭐${e.exp}`, e.coins && `🪙${e.coins}`, e.pulls && `🎟️×${e.pulls}`, e.decor_id && "🎨", e.card_id && "🃏"].filter(Boolean).join(" ");
      return `<div class="card"><div class="row" style="align-items:center;gap:8px;flex-wrap:wrap"><div class="grow"><b>${esc(e.title)}</b> ${live ? '<span class="pill ok">เปิดอยู่</span>' : '<span class="pill">ปิดแล้ว</span>'}
        <div class="muted" style="font-size:.82rem">${prize} · ถึง ${new Date(e.ends_at).toLocaleString("th-TH")} · รับแล้ว ${cnt[e.id] || 0}/${nStu} คน</div></div>
        ${live ? `<button class="btn ghost small" data-close="${e.id}">ปิดตอนนี้</button>` : ""}<button class="btn ghost small" data-del="${e.id}">ลบ</button></div></div>`;
    }).join("") : '<p class="muted">ยังไม่เคยเปิดอีเว้นท์</p>';
    $$("[data-close]", h).forEach((b) => (b.onclick = async () => { await run(async () => must(await sb.from("checkin_events").update({ closed: true }).eq("id", b.dataset.close)), "ปิดแล้ว"); draw(); }));
    $$("[data-del]", h).forEach((b) => (b.onclick = async () => { if (!confirm("ลบอีเว้นท์นี้ (รางวัลที่แจกไปแล้วไม่ถูกดึงคืน)?")) return; await run(async () => must(await sb.from("checkin_events").delete().eq("id", b.dataset.del)), "ลบแล้ว"); draw(); }));
  };
  $("#copen", h).onclick = async () => {
    const n = (id) => Math.max(0, parseInt($(id, h).value, 10) || 0), title = $("#ctitle", h).value.trim();
    if (!title) return toast("ใส่ชื่ออีเว้นท์ก่อน");
    if (!confirm(`เปิดอีเว้นท์ “${title}” นาน ${$("#chours", h).value} ชม. ให้นักเรียนทุกคนกดรับ?`)) return;
    await run(() => rpc("admin_checkin_open", { p_title: title, p_message: $("#cmsg", h).value, p_hours: Number($("#chours", h).value) || 24, p_exp: n("#cexp"), p_coins: n("#ccoin"), p_pulls: n("#cpull"), p_decor: $("#cdec", h).value || null, p_card: $("#ccard", h).value || null }), "เปิดอีเว้นท์แล้ว");
    $("#ctitle", h).value = ""; draw();
  };
  draw();
};
