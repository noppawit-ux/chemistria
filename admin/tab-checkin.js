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
    <button class="btn gold" id="copen">🎟️ เปิดอีเว้นท์</button></div><div id="clist" style="margin-top:10px"></div>
    <h3 style="margin-top:18px">📅 แคมเปญเช็คอินสะสมวัน (ยิ่งครบหลายวันยิ่งได้มาก)</h3><div class="card" id="campform"></div><div id="camplist" style="margin-top:10px"></div>`;
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
  const sets = must(await sb.from("decor_items").select("set_key,name").not("set_key", "is", null)), skeys = [...new Set(sets.map((x) => x.set_key))];
  const setOpt = `<option value="">— ไม่มี —</option>` + skeys.map((k) => `<option value="${esc(k)}">ชุด ${esc(k)} (${sets.filter((x) => x.set_key === k).map((x) => esc(x.name)).join(", ")})</option>`).join("");
  const DEF = [[3, 30, 20, 0, 0], [5, 50, 50, 1, 0], [7, 100, 100, 2, 1]];
  const mrow = (d, i) => `<tr data-m="${i}"><td><input type="number" min="1" class="mneed" value="${d[0]}" style="width:60px"></td><td><input type="number" min="0" class="mexp" value="${d[1]}" style="width:70px"></td><td><input type="number" min="0" class="mcoin" value="${d[2]}" style="width:70px"></td><td><input type="number" min="0" class="mpull" value="${d[3]}" style="width:55px"></td><td><select class="mdec" style="max-width:150px">${opt(decs)}</select></td><td><select class="mcard" style="max-width:150px">${opt(cds)}</select></td><td><select class="mset" style="max-width:190px">${setOpt}</select></td></tr>`;
  $("#campform", h).innerHTML = `<div class="grid2"><div class="field"><label>ชื่อแคมเปญ</label><input id="kt" maxlength="80" placeholder="เช่น เช็คอิน 7 วัน รับชุดลิมิเต็ด"></div><div class="field"><label>จำนวนวัน (เริ่มวันนี้)</label><input id="kd" type="number" min="1" max="120" value="7"></div><div class="field"><label>💬 ข้อความ (ไม่บังคับ)</label><input id="km" maxlength="200"></div></div>
    <div style="overflow:auto"><table class="tbl"><tr><th>ครบ (วัน)</th><th>⭐ EXP</th><th>🪙 เหรียญ</th><th>🎟️ ตั๋ว</th><th>🎨 ไอเทม</th><th>🃏 การ์ด</th><th>👑 ชุดลิมิเต็ด</th></tr>${DEF.map((d, i) => mrow(d, i)).join("")}</table></div>
    <p class="muted" style="font-size:.8rem">นับจำนวนวันที่เช็คอิน (ไม่ต้องติดกัน) · เว้นแถวที่ไม่ใช้ให้ “ครบ” เป็น 0 · ตั้งขั้นสุดท้ายให้ได้ชุดลิมิเต็ด</p>
    <button class="btn gold" id="kopen">📅 เปิดแคมเปญ</button>`;
  $$("#campform tr[data-m]", h).forEach((r, i) => { if (i === DEF.length - 1) $(".mset", r).value = skeys[0] || ""; });
  const dr = async () => {
    const cs = must(await sb.from("checkin_camps").select("*").order("created_at", { ascending: false }).limit(20)), dy = must(await sb.from("checkin_days").select("camp_id,student_id"));
    const sets2 = {}; dy.forEach((x) => (sets2[x.camp_id] = sets2[x.camp_id] || new Set()).add(x.student_id)); const cnt = {}; Object.keys(sets2).forEach((k) => (cnt[k] = sets2[k].size));
    const td = new Date().toISOString().slice(0, 10);
    $("#camplist", h).innerHTML = cs.length ? cs.map((c) => { const live = !c.closed && c.end_day >= td && c.start_day <= td;
      return `<div class="card"><div class="row" style="align-items:center;gap:8px;flex-wrap:wrap"><div class="grow"><b>${esc(c.title)}</b> ${live ? '<span class="pill ok">เปิดอยู่</span>' : '<span class="pill">ปิดแล้ว</span>'}<div class="muted" style="font-size:.82rem">${c.start_day} → ${c.end_day} · นักเรียนที่เข้าร่วม ${cnt[c.id] || 0} คน</div></div>${live ? `<button class="btn ghost small" data-kc="${c.id}">ปิดตอนนี้</button>` : ""}<button class="btn ghost small" data-kd="${c.id}">ลบ</button></div></div>`; }).join("") : '<p class="muted">ยังไม่เคยเปิดแคมเปญ</p>';
    $$("[data-kc]", h).forEach((b) => (b.onclick = async () => { await run(async () => must(await sb.from("checkin_camps").update({ closed: true }).eq("id", b.dataset.kc)), "ปิดแล้ว"); dr(); }));
    $$("[data-kd]", h).forEach((b) => (b.onclick = async () => { if (!confirm("ลบแคมเปญนี้ (รางวัลที่แจกไปแล้วไม่ถูกดึงคืน)?")) return; await run(async () => must(await sb.from("checkin_camps").delete().eq("id", b.dataset.kd)), "ลบแล้ว"); dr(); }));
  };
  $("#kopen", h).onclick = async () => {
    const title = $("#kt", h).value.trim(); if (!title) return toast("ใส่ชื่อแคมเปญก่อน");
    const miles = $$("#campform tr[data-m]", h).map((r) => ({ need: parseInt($(".mneed", r).value, 10) || 0, exp: parseInt($(".mexp", r).value, 10) || 0, coins: parseInt($(".mcoin", r).value, 10) || 0, pulls: parseInt($(".mpull", r).value, 10) || 0, decor_id: $(".mdec", r).value || null, card_id: $(".mcard", r).value || null, set_key: $(".mset", r).value || null })).filter((m) => m.need > 0);
    if (!confirm(`เปิดแคมเปญ “${title}” นาน ${$("#kd", h).value} วัน (${miles.length} ขั้นรางวัล) เริ่มวันนี้?`)) return;
    await run(() => rpc("admin_camp_open", { p_title: title, p_message: $("#km", h).value, p_days: parseInt($("#kd", h).value, 10) || 7, p_miles: miles }), "เปิดแคมเปญแล้ว");
    $("#kt", h).value = ""; dr();
  };
  dr();
};
