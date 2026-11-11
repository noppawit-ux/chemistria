/* เควส — ส่วนหนึ่งของหน้านักเรียน (index.html) โหลดต่อกันตามลำดับใน index.html */
/* ---------- เควส: แถวการ์ด (ไอคอน · ชื่อ · ชิปรางวัล · ปุ่ม) ---------- */
function questRow(q, full) {
  const auto = autoOf(q), st = q.status, done = st === "approved", pend = st === "pending";
  const icon = done ? "check" : pend ? "alarm" : auto ? "star" : "quest";
  const act = st ? statusTag(st) : auto ? "" : full ? `<button class="btn small mint" onclick="claim('${q.id}')">ทำแล้ว ✔</button>` : '<span class="tag wait">ยังไม่ทำ</span>';
  return `<div class="qrow ${done ? "done" : ""} ${auto && !st ? "auto" : ""}"><div class="qic">${ic(icon)}</div>
    <div class="qm"><div class="qt"><b>${esc(q.title)}</b>${q.kind === "weekly" ? '<span class="pill">รายสัปดาห์</span>' : ""}</div>
      ${full && q.description ? `<div class="muted qd">${esc(q.description)}</div>` : ""}
      <div class="qchips"><span class="qchip exp">+${q.exp} EXP</span><span class="qchip coin">${ic("coin", "sm")} +${q.coins}</span>${auto && !st ? `<span class="qchip auto">⚡ ${esc(AUTO_HINT[auto] || "อัตโนมัติ")}</span>` : ""}</div></div>
    ${act ? `<div class="qa">${act}</div>` : ""}</div>`;
}
const questsSorted = () => D.quests.map((q, i) => [q, i]).sort((a, b) => (a[0].status === "approved") - (b[0].status === "approved") || a[1] - b[1]).map((x) => x[0]);
const questProg = () => { const n = D.quests.length, d = D.quests.filter((q) => q.status === "approved").length; return n ? `<span class="qprog">สำเร็จ ${d}/${n}</span>` : ""; };

const questAct = (q) => q.status ? statusTag(q.status) : autoOf(q) ? `<span class="tag wait">⚡ อัตโนมัติ: ${esc(AUTO_HINT[autoOf(q)] || "")}</span>` : null;

const VIEWS = {
  board() { markBoardSeen(); return boardHtml(); },
  guild() { return guildHtml(); },
  game() { return GAMES.view(); },
  home() {
    const a = D.attendance_summary;
    const me = D.student;
    return `${newsHtml()}<div class="card mychar"><h3 style="margin-bottom:6px">ตัวละครของฉัน <small class="muted" style="font-weight:400">แตะช่องอุปกรณ์เพื่อเปลี่ยน</small></h3>
      <div class="charrow"><div class="stagecol"><div class="paperdoll">${stage(me.char_class, D.rank_info, me.decor, "lg")}${eqPanel(me)}</div><div style="margin-top:8px">${titleTag(me.decor)}</div>
        <button class="btn small gold" style="margin-top:8px" onclick="go('decor')">🎨 แต่งตัวละคร</button></div>
        <div class="radarcol">${radarHtml(me.decor)}</div></div></div>
    ${alertsChip()}${todayLessonsHtml()}${bossHtml(false)}
    <div class="grid">
      <div class="card stat"><span class="muted">มาตรงเวลา</span><b>${a.present}</b>คาบ</div>
      <div class="card stat"><span class="muted">สตรีค 🔥</span><b>${a.streak}</b>คาบติด</div>
      <div class="card stat"><span class="muted">มาสาย / ขาด</span><b>${a.late} / ${a.absent}</b>ครั้ง</div>
    </div>
    <div class="card quests"><h3>🗺️ เควสวันนี้ ${questProg()}</h3>
      ${questsSorted().map((q) => questRow(q, false)).join("") || '<p class="muted">วันนี้ยังไม่มีเควส</p>'}
      <button class="btn small ghost" onclick="go('quest')">ไปหน้าเควส</button></div>
    <div class="card"><h3>📜 ความเคลื่อนไหวล่าสุด</h3>
      ${D.ledger.slice(0, 8).map((l) => `<div class="item"><div class="grow">${esc(l.reason)}</div>
        <span class="muted">${l.exp ? `+${l.exp} EXP ` : ""}${l.coins ? `${l.coins > 0 ? "+" : ""}${l.coins} 🪙` : ""}</span></div>`).join("") || '<p class="muted">ยังไม่มีรายการ</p>'}</div>
    <div class="row"><button class="btn ghost" onclick="patchShow(true)">📢 ประกาศอัปเดต v${APP_VERSION}</button><button class="btn ghost" onclick="changePin()">🔑 เปลี่ยน PIN</button><button class="btn ghost" onclick="logout()">ออกจากระบบ</button></div>`;
  },

  att() {
    const today = todayStr();
    const todo = D.assignments.filter((a) => !a.status);
    const done = D.assignments.filter((a) => a.status);
    const row = (a) => {
      const overdue = !a.status && a.due_date && a.due_date < today;
      return `<div class="item"><div class="grow"><b>${esc(a.title)}</b>
        <div class="muted">${a.due_date ? "กำหนดส่ง " + fmtDate(a.due_date) : "ไม่กำหนดวันส่ง"} · ${a.exp} EXP${subInfo(a.id).mode === "photo" ? " · 📷 ส่งเป็นรูป" : subInfo(a.id).mode === "online" ? " · 💻 ส่งออนไลน์" : ""}</div></div>
        ${a.score != null ? `<span class="pill">${a.score}/${a.max_score}</span>` : ""}
        ${a.status === "late" ? '<span class="tag late">ส่งช้า</span>' : a.status ? statusTag(a.status) : overdue ? '<span class="tag no">เลยกำหนด</span>' : '<span class="tag wait">ยังไม่ส่ง</span>'}${submitBtn(a)}</div>
        ${subInfo(a.id).note && (!a.status || a.status === "missing") ? `<div class="muted" style="padding:0 0 8px;color:var(--gold2)">↩️ ครูส่งคืน: ${esc(subInfo(a.id).note)} — แก้ไขแล้วส่งใหม่ได้</div>` : ""}`;
    };
    return `${remindHtml()}
    <div class="card"><h3>📝 งาน</h3><button class="btn mint small" onclick="qrOpen()">📱 QR ของฉัน (ให้ครูสแกนตรวจงาน)</button>${todo.map(row).join("")}${done.map(row).join("") || ""}
      ${D.assignments.length ? "" : '<p class="muted">ยังไม่มีงาน</p>'}</div>
    <div class="card"><h3>📋 ประวัติการเข้าเรียน</h3>
      <div class="row">${D.attendance.map((a) => `<span class="pill">${fmtDate(a.date)} ${statusTag(a.status)}</span>`).join("") || '<span class="muted">ยังไม่มีข้อมูล</span>'}</div></div>`;
  },

  cal() {
    const y = calMonth.getFullYear(), m = calMonth.getMonth();
    const first = new Date(y, m, 1), start = new Date(y, m, 1 - first.getDay());
    const byDay = {};
    const add = (d, o) => ((byDay[String(d).slice(0, 10)] ||= []).push(o));
    D.events.forEach((e) => {
      const s = new Date(e.date), en = e.end_date ? new Date(e.end_date) : s;
      for (let d = new Date(s); d <= en; d.setDate(d.getDate() + 1)) add(ymd(d), { kind: e.kind, title: e.title, note: e.note });
    });
    D.assignments.forEach((a) => a.due_date && add(a.due_date, { kind: "assignment", title: "ส่งงาน: " + a.title, note: a.status ? "" : "ยังไม่ส่ง" }));
    D.attendance.forEach((a) => add(a.date, { kind: "att", title: "เช็คชื่อ: " + STATUS_LABEL[a.status], note: "" }));
    for (let i = 0; i < 42; i++) { const d = new Date(start); d.setDate(start.getDate() + i); const L = lessonsOn(d); if (L.length) (byDay[ymd(d)] ||= []).unshift(...L); }
    let cells = "";
    for (let i = 0; i < 42; i++) {
      const d = new Date(start); d.setDate(start.getDate() + i); const k = ymd(d);
      const items = byDay[k] || [];
      cells += `<div class="d ${d.getMonth() !== m ? "out" : ""} ${k === todayStr() ? "today" : ""} ${k === calSel ? "sel" : ""}" onclick="calSel='${k}';render()">
        <b>${d.getDate()}</b><br>${items.filter((x) => x.kind !== "att").slice(0, 4).map((x) => `<span class="dot k-${x.kind}"></span>`).join("")}${items.some((x) => x.kind === "att") ? "✓" : ""}</div>`;
    }
    const sel = byDay[calSel] || [];
    return `<div class="card">
      <div class="row" style="justify-content:space-between;margin-bottom:8px">
        <button class="btn small ghost" onclick="calMonth=new Date(${y},${m - 1},1);render()">◀</button>
        <h3 style="margin:0">${TH_MONTHS[m]} ${y + 543}</h3>
        <button class="btn small ghost" onclick="calMonth=new Date(${y},${m + 1},1);render()">▶</button></div>
      <div class="cal">${TH_DAYS.map((d) => `<div class="h">${d}</div>`).join("")}${cells}</div>
      <div class="row muted" style="margin-top:8px">${Object.entries(KIND_LABEL).map(([k, l]) => `<span><span class="dot k-${k}"></span>${l}</span>`).join("")}</div></div>
      <div class="card"><h3>${fmtDate(calSel)}</h3>${sel.map((x) => `<div class="item"><span class="dot k-${x.kind === "att" ? "lesson" : x.kind}"></span><div class="grow">${esc(x.title)}<div class="muted">${esc(x.note || "")}</div></div></div>`).join("") || '<p class="muted">ไม่มีรายการ</p>'}</div>`;
  },

  score() {
    if (!D.settings.show_scores) return '<div class="card"><p class="muted">ครูปิดการแสดงคะแนนไว้ชั่วคราว</p></div>';
    const g = {};
    D.scores.forEach((s) => (g[s.category] ||= []).push(s));
    return Object.keys(CAT_LABEL).filter((c) => g[c]).map((c) => {
      const got = g[c].reduce((a, s) => a + (s.score ?? 0), 0), max = g[c].reduce((a, s) => a + Number(s.max), 0);
      return `<div class="card"><h3>${CAT_LABEL[c]} <span class="pill">${got} / ${max}</span></h3>
        ${g[c].map((s) => `<div class="item"><div class="grow">${esc(s.title)}</div><b>${s.score ?? "–"}</b><span class="muted">/ ${s.max}</span></div>`).join("")}</div>`;
    }).join("") || '<div class="card"><p class="muted">ยังไม่มีคะแนน</p></div>';
  },

  class() {
    const s = D.student, cost = D.class_change_cost;
    return `<div class="card"><h3>⚔️ เลือกคลาสของคุณ</h3>
      <p class="muted">แต่ละคลาสมีความสามารถพิเศษต่างกัน เลือกครั้งแรกฟรี หลังจากนั้นเปลี่ยนคลาสครั้งละ ${cost} 🪙</p>
      <div class="clsgrid">${D.classes.map((c) => `<div class="clscard ${c.key === s.char_class ? "on" : ""}">
        <img src="${esc(c.image)}" alt="" onerror="this.replaceWith(document.createTextNode('${esc(c.emoji)}'))">
        <h3 style="margin:.2em 0">${esc(c.emoji)} ${esc(c.name)}</h3>
        <div class="muted">${esc(c.description || "")}</div>
        <div class="ability">✨ ${esc(c.ability || "")}</div>
        ${c.key === s.char_class ? '<span class="tag ok">คลาสปัจจุบัน</span>'
          : `<button class="btn small gold" ${!D.class_free && s.coins < cost ? "disabled" : ""} onclick="pickClass('${c.key}','${esc(c.name)}')">${D.class_free ? "เลือกคลาสนี้ (ฟรี)" : `เปลี่ยน (${cost} 🪙)`}</button>`}
      </div>`).join("")}</div></div>`;
  },

  quest() {
    return `${bossHtml(true)}<div class="card quests"><h3>🗺️ เควสวันนี้ & รายสัปดาห์ ${questProg()}</h3><p class="muted">เควส ⚡ อัตโนมัติทั้งหมด: ระบบเช็คให้เอง ทำตามเงื่อนไขแล้วได้รางวัลทันที ไม่ต้องกดรับ · ทุกเควสที่สำเร็จคือการโจมตีบอส ✨</p>
      ${questsSorted().map((q) => questRow(q, true)).join("") || '<p class="muted">วันนี้ยังไม่มีเควส</p>'}</div>`;
  },

  gacha() {
    const c = D.settings.gacha_cost, s = D.student, pm = D.settings.pity_max;
    const fr = X.free_pulls || 0, pct = Math.min(100, (s.pity / pm) * 100);
    return gachaNotes() + `<div class="card gh center"><div class="ghglow"></div>
      <img class="ghm" src="assets/gacha-machine.jpg" alt="" draggable="false">
      <h3 class="ghh">🎰 กาชาห้องทดลอง</h3>
      <div class="ghchips"><span class="ghchip">เหรียญของคุณ <span class="coin">🪙 ${s.coins}</span></span><span class="ghchip">ครั้งละ <b>${c}</b> 🪙</span>${fr > 0 ? `<span class="ghchip fr">🎟️ ตั๋วฟรี <b>${fr}</b> ใบ</span>` : ""}</div>
      ${fr > 0 ? "" : '<p class="muted small">🎟️ เข้าเรียนแล้วครูเช็คชื่อ → ได้ตั๋วสุ่มฟรี 1 ใบ</p>'}
      <div class="ghpity"><div class="bar"><i style="width:${pct}%"></i></div><small class="muted">การันตี SR ขึ้นไปเมื่อสุ่มไม่ได้ครบ ${pm} ครั้ง (สะสม ${s.pity}/${pm - 1})</small></div>
      <div class="row" style="justify-content:center;margin-top:10px">
        <button class="btn gold ghbtn" ${s.coins < c && !(fr > 0) ? "disabled" : ""} onclick="pull(1)">${fr > 0 ? "🎟️ ใช้ตั๋วฟรี ×1" : `สุ่ม ×1 · ${c}🪙`}</button>
        <button class="btn gold ghbtn big" ${s.coins < c * 10 ? "disabled" : ""} onclick="pull(10)">สุ่ม ×10 · ${c * 10}🪙</button></div></div>
      <div class="card"><h3>ของรางวัลที่มีในตู้</h3><div class="row">
      <p class="muted" style="margin:0 0 8px">🔴 <b style="color:#ff5a68">LEGENDARY</b> เริ่ม 0.01% ยิ่งสุ่มยิ่งเพิ่มสูงสุด 0.5% · ได้ครั้งแรก = แลกคะแนนจริง +2 คะแนน</p>${[...D.gacha_pool].sort((a, b) => ["LEG", "SSR", "SR", "R", "N"].indexOf(a.rarity) - ["LEG", "SSR", "SR", "R", "N"].indexOf(b.rarity)).map((g) => `<span class="pill rar-${g.rarity}" style="border-color:var(--c)">${itemImg(g.image, g.emoji)} ${esc(g.name)} <b class="rar">${g.rarity}</b></span>`).join("")}</div></div>`;
  },

  bag() {
    return `<div class="card"><h3>🏅 Achievement</h3><div class="grid">
      ${D.achievements.map((a) => {
        const p = Math.min(100, Math.round((a.progress / a.threshold) * 100));
        return `<div class="card" style="margin:0;${a.earned_at ? "border-color:var(--gold)" : "opacity:.8"}">
          <div class="medal ${a.earned_at ? "" : "off"}">${a.image ? `<img src="${esc(a.image)}" alt="">` : `<span style="font-size:30px">${esc(a.emoji)}</span>`}</div><b>${esc(a.name)}</b>
          <div class="muted">${esc(a.description || "")}</div>
          ${a.earned_at ? `<span class="tag ok">ได้รับแล้ว ${fmtDate(a.earned_at)}</span>`
            : `<div class="bar" style="margin-top:6px"><i style="width:${p}%"></i></div><span class="muted">${Math.min(a.progress, a.threshold)}/${a.threshold}</span>`}
          <div class="muted">รางวัล ${a.reward_exp ? `+${a.reward_exp} EXP ` : ""}${a.reward_coins ? `+${a.reward_coins} 🪙` : ""}</div></div>`;
      }).join("")}</div></div>
    <div class="card"><h3>🎟️ สิทธิพิเศษของฉัน</h3>
      ${D.privileges.map((p) => `<div class="item"><span style="font-size:26px">${esc(p.emoji)}</span><div class="grow"><b>${esc(p.name)}</b>
        <div class="muted">${esc(p.description || "")}</div></div>
        ${p.status === "available" ? `<button class="btn small gold" onclick="usePriv('${p.id}')">ขอใช้สิทธิ์</button>`
          : p.status === "requested" ? '<span class="tag wait">รอครูอนุมัติ</span>'
          : p.status === "approved" ? '<span class="tag ok">ใช้แล้ว</span>' : '<span class="tag no">ไม่อนุมัติ</span>'}</div>`).join("") || '<p class="muted">ยังไม่มีสิทธิพิเศษ ลองสุ่มกาชาหรือแลกในร้านค้า</p>'}</div>
    <div class="card"><h3>🧑‍🔬 อวาตาร์ที่สะสม</h3><div class="row">
      <button class="btn small ghost" onclick="setAv(null)">🧪 ค่าเริ่มต้น</button>
      ${D.inventory.map((i) => `<button class="btn small ${i.equipped ? "gold" : "ghost"}" onclick="setAv('${i.item_id}')">${itemImg(i.image, i.emoji)} ${esc(i.name)}${i.qty > 1 ? " ×" + i.qty : ""}</button>`).join("")}</div></div>`;
  },

  decor() {
    const s = D.student, eq = s.decor || {}, ri = D.rank_info, cat = D.decor_catalog || [];
    if (!DRAFT) { DRAFT = {}; SLOTS.forEach(([k]) => { if (eq[k]) DRAFT[k] = eq[k]; }); }
    const idOf = (o, k) => (o && o[k] ? o[k].id : null);
    const changed = SLOTS.filter(([k]) => idOf(DRAFT, k) !== idOf(eq, k)).map(([k]) => k);
    const prevDc = { ...DRAFT, gender: eq.gender };
    let items = cat.filter((d) => d.slot === decSlot);
    if (decSlot === "outfit") items = [{ id: null, slot: "outfit", name: "ชุดเริ่มต้น", emoji: "👤", rarity: "N", owned: true, price: null }, ...items];
    const owned = cat.filter((d) => d.owned).length;
    const stBadge = (d) => { const t = (X.item_stats || {})[d.id]; if (!t) return ""; const parts = STN.filter(([k]) => t[k]).map(([k, ic]) => `${ic}+${t[k]}`); if (+t.coin) parts.push(`🪙+${t.coin}%`); return `<span class="stb">${parts.join(" ")}</span>${t.ability ? `<span class="abl">${esc(t.ability)}</span>` : ""}`; };
    const tile = (d) => {
      const sel = d.id === null ? !DRAFT.outfit : DRAFT[d.slot] && DRAFT[d.slot].id === d.id;
      const next = { ...DRAFT, gender: eq.gender }; if (d.id === null) delete next.outfit; else next[d.slot] = d;
      // หน้าไอเทม: แสดงเฉพาะรูป/ไอคอนของไอเทม (ตัวอย่างเต็มตัวอยู่ด้านบนของหน้า) — กรอบ/พื้นหลังแสดงบนอวาตาร์วงเล็กเพื่อให้เห็นลาย
      const big = d.image ? `<img class="dimg" src="${esc(d.image)}" alt="" onerror="this.replaceWith(Object.assign(document.createElement('span'),{className:'demo',textContent:'${esc(d.emoji || "🎁")}'}))">` : `<span class="demo">${esc(d.emoji || "🎁")}</span>`;
      const oimg = (cls0, d0) => `assets/chars/${cls0 || "novice"}${d0.id === null ? (altGender(cls0, eq.gender) ? "_alt" : "") : "_" + d0.key}.png`;
      const outfitPrev = d.slot === "outfit" ? `<img class="dimg outfit" src="${esc(oimg(s.char_class, d))}" alt="" onerror="this.replaceWith(Object.assign(document.createElement('span'),{className:'demo',textContent:'${esc(d.emoji || "👕")}'}))">` : null;
      const prev = outfitPrev ? outfitPrev : d.slot === "title" ? titleTag({ title: d }) : (d.slot === "frame" || d.slot === "bg") ? frame(s.avatar, s.char_class, ri, 0, true, next) : big;
      const act = d.owned ? (sel ? (d.id === null ? '<span class="tag ok">เลือกอยู่</span>' : `<button class="btn small ghost" onclick="pickDecor('${d.slot}',null)">ถอดออก</button>`)
            : `<button class="btn small gold" onclick="pickDecor('${d.slot}',${d.id === null ? "null" : `'${d.id}'`})">เลือก</button>`)
          : d.price != null ? `<button class="btn small" ${s.coins < d.price ? "disabled" : ""} onclick="buyDecor('${d.id}','${esc(d.name)}',${d.price})">ซื้อ ${d.price} 🪙</button>`
          : '<span class="muted">ล็อก · ได้จากกาชา</span>';
      return `<div class="dtile rar-${d.rarity} ${sel ? "worn" : ""} ${d.owned ? "" : "locked"}">
        <div class="dprev">${prev}</div><b>${d.slot === "title" ? esc(d.emoji) + " " : ""}${esc(d.name)}</b><span class="rar">${d.id === null ? "" : d.rarity}</span>${stBadge(d)}${act}</div>`;
    };
    const slotBtn = ([k, ic, lb]) => { const it = DRAFT[k]; const ch = changed.includes(k);
      return `<button class="slotbtn ${k === decSlot ? "on" : ""} ${ch ? "chg" : ""}" onclick="decSlot='${k}';render()">
        <span class="si">${it ? (it.image ? `<img src="${esc(it.image)}" alt="">` : k === "outfit" ? `<img src="assets/chars/${esc(s.char_class || "novice")}_${esc(it.key)}.png" alt="" onerror="this.replaceWith(document.createTextNode('${esc(it.emoji)}'))">` : esc(it.emoji)) : ic}</span><span class="sl">${lb}</span><small>${it ? esc(it.name) : k === "outfit" ? "ชุดเริ่มต้น" : "— ว่าง —"}</small></button>`; };
    return `<div class="card"><h3>ตัวละครของฉัน</h3>
      <div class="charrow"><div class="stagecol">${stage(s.char_class, ri, prevDc, "lg")}${titleTag(DRAFT)}
        <div class="row" style="justify-content:center;gap:6px;margin-top:8px"><span class="muted">เพศ</span>
        ${[["m", "👦 ชาย"], ["f", "👧 หญิง"]].map(([g, l]) => `<button class="btn small ${gOf(s.char_class, eq) === g ? "gold" : "ghost"}" onclick="setGender('${g}')">${l}</button>`).join("")}</div>
        ${altGender(s.char_class, eq.gender) && DRAFT.outfit ? '<p class="muted" style="font-size:12px">* ชุดนี้ยังไม่มีภาพของเพศที่เลือก จึงแสดงตัวพื้นฐานแทนไปก่อน</p>' : ""}</div>
        <div class="radarcol"><div class="muted center" style="margin-bottom:2px">📊 สเตตัสประกอบ${changed.length ? " (ตัวอย่างตามที่เลือก)" : ""}</div>${radarHtml(DRAFT)}</div></div>
      <div class="slotbar">${SLOTS.map(slotBtn).join("")}</div>
      <div class="savebar ${changed.length ? "on" : ""}"><span>${changed.length ? `✏️ เปลี่ยน ${changed.length} ช่อง ยังไม่ได้บันทึก` : "เลือกไอเทมด้านล่างเพื่อลองใส่ แล้วกดบันทึก"}</span>
        <span><button class="btn ghost small" ${changed.length ? "" : "disabled"} onclick="resetDraft()">↩︎ ยกเลิก</button>
        <button class="btn gold" ${changed.length ? "" : "disabled"} onclick="saveDraft()">💾 บันทึก</button></span></div>
      <p class="muted center" style="margin:6px 0 0">สะสมแล้ว ${owned}/${cat.length} ชิ้น · เหรียญ <span class="coin">🪙 ${s.coins}</span> · ได้ไอเทมจาก <a href="#" onclick="go('gacha');return false" style="color:var(--gold2)">กาชา</a> หรือซื้อด้านล่าง</p></div>
      <div class="card"><h3>${(SLOTS.find((x) => x[0] === decSlot) || [])[1]} ${(SLOTS.find((x) => x[0] === decSlot) || [])[2]}</h3><div class="dgrid">${items.map(tile).join("") || '<p class="muted">ยังไม่มีไอเทมในหมวดนี้</p>'}</div></div>
      ${statsHtml()}`;
  },

  shop() {
    return `<div class="card"><h3>🛒 ร้านสิทธิพิเศษ</h3><p class="muted">เหรียญของคุณ <span class="coin">🪙 ${D.student.coins}</span></p>
      ${D.shop.map((p) => `<div class="item"><span style="font-size:26px">${esc(p.emoji)}</span><div class="grow"><b>${esc(p.name)}</b>
        <div class="muted">${esc(p.description || "")}</div></div>
        <button class="btn small gold" ${D.student.coins < p.cost ? "disabled" : ""} onclick="buy('${p.id}')">${p.cost} 🪙</button></div>`).join("") || '<p class="muted">ยังไม่มีสินค้า</p>'}</div>`;
  },

  rank() {
    const me = D.rank_info;
    return `${hallHtml() || '<div class="card hof center"><h3>🏆 หอเกียรติยศ</h3><p class="muted">ยังไม่มีอันดับ — สะสม EXP จากเช็คชื่อ ส่งงาน เควส และมินิเกมเพื่อขึ้นโพเดียม</p></div>'}
    <div class="card"><h3>🏆 อันดับห้อง ${esc(D.class.name)} (Top 10)</h3>
      <div class="lb">${D.leaderboard.map((l, i) => `<div class="lbrow ${l.me ? "me" : ""}">
        <span class="lbn n${i + 1}">${i + 1}</span>${frame(l.avatar, l.char_class, l.rank_info, 0, true, l.decor)}
        <div class="lbm"><b class="lbname">${gtag(l.guild)}${esc(l.name)}</b>${titleTag(l.decor)}<small class="rk-${l.rank_info.key}" style="color:var(--rc)">${esc(rankName(l.rank_info))}${clsOf(l.char_class) ? " · " + esc(clsOf(l.char_class).name) : ""}</small></div>
        <div class="lbr"><span class="pill">Lv.${l.level}</span><b>${l.exp}</b><small class="muted">EXP</small></div></div>`).join("")}</div></div>
      ${teamsHtml()}
      <div class="card"><h3>🎖️ บันไดแรงค์</h3><p class="muted">ได้ EXP จากเช็คชื่อ ส่งงาน เควส และ Achievement เพื่อไต่แรงค์ (แต่ละแรงค์มีดิวิชัน IV → I)</p>
      <div class="ranktable">${(D.ranks || []).map((r) => `<div class="rk-${r.key} ${r.key === me.key ? "me" : ""}"><img src="${esc(r.image)}" alt=""><br><b style="color:var(--rc)">${esc(r.name)}</b><br><span class="muted">${r.min_exp}+ EXP</span></div>`).join("")}</div></div>`;
  },
};
