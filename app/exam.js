/* แท็บ 📝 สอบ — สอบออนไลน์ในห้องเรียน (มือถือ/แท็บเล็ต)
   ชนิดข้อ: mcq เลือกตอบ · tf จริง/เท็จ · short ข้อเขียน (+แนบรูป) · match จับคู่ · drag ลากวางใส่กลุ่ม
   เวลานับตามเซิร์ฟเวอร์ · บันทึกอัตโนมัติทุกข้อ · สลับหน้าจอ/แอปจะถูกนับให้ครูเห็น */
let EXL = null, EXL_BUSY = false, EX = null, EX_TIMER = null, EX_SAVE = {}, EX_SKEW = 0;
const fm = (t) => esc(t == null ? "" : String(t)).replace(/([A-Za-z\)\]])(\d+)/g, "$1<sub>$2</sub>");
const exImg = (src, c = "") => (src ? `<img class="exim ${c}" src="${esc(src)}" alt="" loading="lazy" ${c ? "" : 'onclick="exZoom(this.src)"'} draggable="false" onerror="this.remove()">` : "");
const exFmtT = (s) => { s = Math.max(0, Math.floor(s)); return String(Math.floor(s / 60)).padStart(2, "0") + ":" + String(s % 60).padStart(2, "0"); };
function exZoom(src) {
  const z = document.createElement("div"); z.className = "exzoom"; z.innerHTML = `<img src="${esc(src)}" alt="">`;
  z.onclick = () => z.remove(); document.body.appendChild(z);
}

/* ---------- รายการสอบ ---------- */
async function examLoad(force) {
  if (EXL_BUSY || (EXL && !force)) return;
  EXL_BUSY = true;
  try { EXL = await rpc("exam_list", { p_token: tk() }); } catch (e) { EXL = { error: e.message }; }
  EXL_BUSY = false;
  if (tab === "exam") { const v = $("#view"); if (v) v.innerHTML = examListHtml(); }
}
function examListHtml() {
  if (!EXL) return '<div class="card"><p class="muted">กำลังโหลด…</p></div>';
  if (EXL.error) return `<div class="card"><h3>📝 สอบ</h3><p class="muted">${esc(EXL.error)}</p></div>`;
  const fmtD = (d) => (d ? new Date(d).toLocaleString("th-TH", { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" }) : "");
  const rows = (EXL.exams || []).map((e) => {
    const used = (e.attempts || []).length, left = e.max_attempts - used;
    let st = "", btn = "";
    if (e.active) { st = '<span class="tag wait">กำลังสอบ</span>'; btn = `<button class="btn gold" onclick="examGo('${e.id}')">▶️ ทำต่อ</button>`; }
    else if (e.state === "open" && left > 0) { st = '<span class="tag ok">เปิดสอบ</span>'; btn = `<button class="btn gold" onclick="examAsk('${e.id}', ${!!e.has_code})">${used ? "🔁 สอบอีกครั้ง" : "✏️ เริ่มสอบ"}</button>`; }
    else if (e.state === "upcoming") { st = '<span class="tag wait">ยังไม่เปิด</span>'; }
    else if (e.state === "open") { st = '<span class="tag">สอบครบครั้งแล้ว</span>'; }
    else { st = '<span class="tag">ปิดแล้ว</span>'; }
    const r = e.result;
    const res = r ? `<div class="exres"><b>${r.score}</b>/${r.total} <small class="muted">(= ${r.scaled}/${r.max} คะแนนเก็บ)</small>${r.review ? ' <span class="tag wait">รอครูตรวจข้อเขียน</span>' : ""} <button class="btn small ghost" onclick="examReview('${e.id}')">🔍 ดูเฉลย</button></div>`
      : e.submitted ? `<div class="muted exres">ส่งแล้ว ✅ ${e.show_result === "after_close" ? "— ผลและเฉลยจะแสดงหลังปิดสอบ" : e.show_result === "never" ? "— ครูจะแจ้งผลภายหลัง" : ""}</div>` : "";
    return `<div class="card exrow"><div class="row" style="align-items:center;gap:8px"><h3 class="grow" style="margin:0">${esc(e.title)}</h3>${st}</div>
      <p class="muted" style="margin:4px 0">${e.nq} ข้อ · ${e.total} คะแนน · ${e.minutes} นาที · สอบได้ ${e.max_attempts} ครั้ง (ใช้ไป ${used})${e.close_at ? ` · ปิด ${fmtD(e.close_at)}` : ""}${e.state === "upcoming" && e.open_at ? ` · เปิด ${fmtD(e.open_at)}` : ""}</p>
      ${res}${btn ? `<div style="margin-top:8px">${btn}</div>` : ""}</div>`;
  }).join("");
  return `<div class="card"><h3>📝 สอบเก็บคะแนน</h3><p class="muted" style="margin:0">ทำข้อสอบในห้องเรียนผ่านมือถือ/แท็บเล็ต · เวลานับตามเซิร์ฟเวอร์ ปิดหน้าจอแล้วเวลายังเดิน · ระบบบันทึกคำตอบให้ทุกข้อ · การสลับแอป/แท็บถูกบันทึกให้ครูเห็น</p>
    <button class="btn small ghost" style="margin-top:6px" onclick="examLoad(true)">🔄 รีเฟรช</button></div>${rows || '<div class="card"><p class="muted">ยังไม่มีข้อสอบของห้องนี้</p></div>'}`;
}
VIEWS.exam = () => { examLoad(true); return examListHtml(); };

/* ---------- ทำข้อสอบ ---------- */
/* เริ่มสอบแต่ละครั้งต้องกรอกรหัสสอบที่ครูบอก (ทำต่อที่ค้างไว้ไม่ต้องกรอก) */
function examAsk(id, hasCode, msg) {
  if (!hasCode) return examGo(id);
  eqClose();
  const ov = document.createElement("div"); ov.id = "eqov"; ov.setAttribute("role", "dialog");
  ov.innerHTML = `<div class="eqbox center"><button class="patchx" aria-label="ปิด" onclick="eqClose()">✕</button><h3>🔑 รหัสเข้าสอบ</h3>
    <p class="muted" style="margin:4px 0">ขอรหัสจากครูในห้องสอบ แล้วกรอกเพื่อเริ่มสอบ</p>
    ${msg ? `<p style="color:var(--red);margin:4px 0">${esc(msg)}</p>` : ""}
    <input id="excode" autocomplete="off" autocapitalize="off" style="text-align:center;font-size:1.4em;letter-spacing:.15em;max-width:240px" placeholder="รหัสสอบ">
    <div style="margin-top:10px"><button class="btn gold" id="exgo">✏️ เริ่มสอบ</button></div></div>`;
  ov.addEventListener("click", (e) => { if (e.target === ov) eqClose(); });
  document.body.appendChild(ov);
  const go1 = () => { const c = $("#excode").value.trim(); if (!c) return; eqClose(); examGo(id, c); };
  $("#exgo").onclick = go1; $("#excode").addEventListener("keydown", (e) => { if (e.key === "Enter") go1(); }); $("#excode").focus();
}
async function examGo(id, code) {
  let p;
  try { p = await rpc("exam_start", { p_token: tk(), p_exam: id, p_code: code || null }); } catch (e) { toast(e.message); examLoad(true); return; }
  if (p && p.code_error) return examAsk(id, true, p.code_error);
  EX_SKEW = Date.parse(p.attempt.now) - Date.now();
  const ans = {}, photo = {};
  p.qs.forEach((q) => { ans[q.id] = q.ans || null; photo[q.id] = !!q.photo; });
  EX = { att: p.attempt, exam: p.exam, qs: p.qs, i: 0, ans, photo, done: false, sel: null };
  EX.qs.forEach((q) => {
    if (q.kind === "match" && !(ans[q.id] && ans[q.id].m)) ans[q.id] = { m: q.view.left.map(() => null) };
    if (q.kind === "drag" && !(ans[q.id] && ans[q.id].z)) ans[q.id] = { z: q.view.items.map(() => null) };
  });
  document.getElementById("exov")?.remove();
  const ov = document.createElement("div"); ov.id = "exov"; document.body.appendChild(ov);
  document.body.classList.add("exlock");
  document.addEventListener("visibilitychange", exVis); window.addEventListener("blur", exAway); window.addEventListener("focus", exBack);
  ["copy", "cut", "paste", "contextmenu", "dragstart"].forEach((t) => ov.addEventListener(t, (e) => { if (!(t === "dragstart" && e.target.closest && e.target.closest(".exchip"))) e.preventDefault(); }));
  try { (ov.requestFullscreen || ov.webkitRequestFullscreen || (() => {})).call(ov); } catch (e) { /* ไม่รองรับ */ }
  clearInterval(EX_TIMER); EX_TIMER = setInterval(exTick, 1000);
  exRender();
}
/* กันสลับหน้าจอ: ออกจากหน้าสอบ (ยุบแอป/สลับแท็บ/แยกหน้าจอ) แล้วกลับมา = นับ 1 ครั้ง เกินที่ครูกำหนด → ส่งข้อสอบอัตโนมัติ
   (ถ่ายรูปคำตอบได้: เปิดกล้องแล้วกลับมาภายใน 90 วินาทีไม่นับ) */
function exAway() { if (EX && !EX.done && !EX.away) EX.away = Date.now(); }
const exVis = () => { if (document.hidden) exAway(); else exBack(); };
async function exBack() {
  if (!EX || EX.done || !EX.away || document.hidden) return;
  const t = EX.away; EX.away = 0;
  if (EX.cam && Date.now() - EX.cam < 90000 && t >= EX.cam - 1000) { EX.cam = 0; return; }
  if (Date.now() - t < 700) return; // กะพริบสั้นๆ (เช่น แจ้งเตือนระบบ)
  let r = null;
  try { r = await rpc("exam_blur", { p_token: tk(), p_attempt: EX.att.id }); } catch (e) { return; }
  if (!r) return;
  if (r.locked) return exLockedScreen(r);
  const w = document.createElement("div"); w.id = "exwarn"; w.className = "exwarn";
  w.innerHTML = `<div class="excard center"><div style="font-size:48px">⚠️</div><h3>ออกจากหน้าสอบ</h3>
    <p>ครั้งที่ <b>${r.blur}</b>${r.max ? ` จาก ${r.max}` : ""} — ครูเห็นการออกจากหน้าสอบทุกครั้ง${r.max ? `<br>ถ้าเกิน ${r.max} ครั้ง ระบบจะส่งข้อสอบให้อัตโนมัติ` : ""}</p>
    <button class="btn gold" onclick="document.getElementById('exwarn').remove()">กลับไปทำข้อสอบ</button></div>`;
  document.getElementById("exov")?.appendChild(w);
}
function exLockedScreen(r) {
  EX.done = true; clearInterval(EX_TIMER); document.getElementById("exwarn")?.remove();
  document.getElementById("exov").innerHTML = `<div class="exwrap"><div class="excard center"><div style="font-size:56px">🔒</div><h2 style="margin:4px 0">ส่งข้อสอบแล้ว</h2>
    <p class="muted">ออกจากหน้าสอบเกิน ${r.max} ครั้ง ระบบจึงส่งข้อสอบให้อัตโนมัติ (คำตอบที่บันทึกไว้ยังถูกนับ)</p><button class="btn gold" onclick="exClose()">กลับหน้าสอบ</button></div></div>`;
}
const exRemain = () => (Date.parse(EX.att.deadline) - (Date.now() + EX_SKEW)) / 1000;
function exTick() {
  if (!EX || EX.done) return;
  const r = exRemain(), t = document.getElementById("extimer");
  if (t) { t.textContent = "⏱ " + exFmtT(r); t.classList.toggle("low", r < 60); }
  if (r <= 0 && !EX.sending) { toast("หมดเวลา — กำลังส่งข้อสอบ…", 4000); exSubmit(true); }
}
function exClose() {
  clearInterval(EX_TIMER); document.removeEventListener("visibilitychange", exVis); window.removeEventListener("blur", exAway); window.removeEventListener("focus", exBack);
  try { if (document.fullscreenElement) document.exitFullscreen(); } catch (e) { /* ไม่เป็นไร */ }
  document.getElementById("exov")?.remove(); document.body.classList.remove("exlock"); EX = null;
  examLoad(true); if (tab === "exam") { const v = $("#view"); if (v) v.innerHTML = examListHtml(); }
}
const exAnswered = (q) => {
  const a = EX.ans[q.id];
  if (q.kind === "mcq") return a && a.i != null;
  if (q.kind === "tf") return a && a.v != null;
  if (q.kind === "short") return (a && (a.t || "").trim() !== "") || EX.photo[q.id];
  if (q.kind === "match") return a && a.m.some((x) => x != null);
  if (q.kind === "drag") return a && a.z.some((x) => x != null);
  return false;
};
function exSave(q) {
  clearTimeout(EX_SAVE[q.id]);
  EX_SAVE[q.id] = setTimeout(() => exFlush(q), 500);
  const d = document.getElementById("exdots"); if (d) d.innerHTML = exDots();
}
async function exFlush(q) {
  clearTimeout(EX_SAVE[q.id]); if (!EX) return;
  const st = document.getElementById("exsv");
  try { await rpc("exam_save", { p_token: tk(), p_attempt: EX.att.id, p_qid: q.id, p_ans: EX.ans[q.id] || {} }); if (st) st.textContent = "บันทึกแล้ว ✓"; }
  catch (e) { if (st) st.textContent = "⚠️ บันทึกไม่สำเร็จ: " + e.message; }
}
const exDots = () => EX.qs.map((q, k) => `<button class="exdot ${k === EX.i ? "cur" : ""} ${exAnswered(q) ? "done" : ""}" onclick="exJump(${k})">${k + 1}</button>`).join("");
const exJump = async (k) => { await exFlush(EX.qs[EX.i]); EX.i = k; EX.sel = null; exRender(); };

function exRender() {
  const ov = document.getElementById("exov"); if (!ov || !EX) return;
  if (EX.done) return;
  const q = EX.qs[EX.i], n = EX.qs.length, last = EX.i === n - 1;
  ov.innerHTML = `<div class="exwrap">
    <div class="exbar"><b class="grow">${esc(EX.exam.title)}</b><span id="extimer" class="extimer">⏱ ${exFmtT(exRemain())}</span></div>
    <div id="exdots" class="exdots">${exDots()}</div>
    <div class="excard"><div class="exqh"><span class="tag">ข้อ ${EX.i + 1}/${n}</span> <span class="tag">${q.points} คะแนน</span> <span class="muted" id="exsv" style="font-size:.8em"></span></div>
      <div class="exq">${fm(q.q)}</div>${exImg(q.img)}
      <div id="exbody">${exBody(q)}</div></div>
    <div class="exnav"><button class="btn ghost" ${EX.i === 0 ? "disabled" : ""} onclick="exJump(${EX.i - 1})">◀ ก่อนหน้า</button>
      ${last ? `<button class="btn gold" onclick="exReview1()">📤 ตรวจทานและส่ง</button>` : `<button class="btn gold" onclick="exJump(${EX.i + 1})">ถัดไป ▶</button>`}</div></div>`;
}
function exBody(q) {
  const a = EX.ans[q.id], v = q.view;
  if (q.kind === "mcq") return `<div class="exch">${v.choices.map((c, k) => `<button class="exc ${a && a.i === k ? "on" : ""}" onclick="exPick(${k})"><b>${"ABCDEFGH"[k] || k + 1}</b><span>${fm(c.t)}${exImg(c.img, "chimg")}</span></button>`).join("")}</div>`;
  if (q.kind === "tf") return `<div class="extf"><button class="exc ${a && a.v === true ? "on" : ""}" onclick="exTF(true)">✅ ถูก</button><button class="exc ${a && a.v === false ? "on" : ""}" onclick="exTF(false)">❌ ผิด</button></div>`;
  if (q.kind === "short") {
    const up = v.upload ? `<div class="exup"><label class="btn small ghost" onclick="EX.cam=Date.now()">📷 ${EX.photo[q.id] ? "เปลี่ยนรูป" : "ถ่าย/แนบรูปคำตอบ"}<input type="file" accept="image/*" hidden onchange="exPhoto(this)"></label>
      <span class="${EX.photo[q.id] ? "tag ok" : "muted"}" id="exphs">${EX.photo[q.id] ? "แนบรูปแล้ว ✓" : "วาดบนกระดาษแล้วถ่ายรูป หรือพิมพ์คำตอบ"}</span></div>` : "";
    return `${v.hint ? `<p class="muted">💡 ${fm(v.hint)}</p>` : ""}<textarea id="exta" class="exta" spellcheck="false" autocorrect="off" autocomplete="off" rows="${v.upload ? 3 : 2}" placeholder="พิมพ์คำตอบที่นี่" oninput="exText(this.value)">${esc((a && a.t) || "")}</textarea>${up}`;
  }
  if (q.kind === "match") {
    const used = {}; a.m.forEach((r, l) => { if (r != null) used[r] = l; });
    return `<p class="muted" style="margin:0 0 6px">แตะฝั่งซ้าย แล้วแตะคู่ของมันฝั่งขวา · แตะคู่ที่จับแล้วเพื่อยกเลิก</p>
      <div class="exmt"><div class="excol">${v.left.map((it, l) => `<button class="exm ${EX.sel === l ? "sel" : ""} ${a.m[l] != null ? "pair" : ""}" onclick="exL(${l})"><i>${l + 1}</i><span>${fm(it.t)}${exImg(it.img, "chimg")}</span>${a.m[l] != null ? `<em>→ ${"ABCDEFGH"[a.m[l]]}</em>` : ""}</button>`).join("")}</div>
      <div class="excol">${v.right.map((it, r) => `<button class="exm ${used[r] != null ? "pair" : ""}" onclick="exR(${r})"><i>${"ABCDEFGH"[r]}</i><span>${fm(it.t)}${exImg(it.img, "chimg")}</span>${used[r] != null ? `<em>${used[r] + 1}</em>` : ""}</button>`).join("")}</div></div>`;
  }
  if (q.kind === "drag") {
    const pool = []; a.z.forEach((z, k) => { if (z == null) pool.push(k); });
    const chip = (k) => `<span class="exchip ${EX.sel === "i" + k ? "sel" : ""}" data-k="${k}" onpointerdown="exDragStart(event,${k})">${fm(v.items[k].t)}${exImg(v.items[k].img, "chimg")}</span>`;
    return `<p class="muted" style="margin:0 0 6px">ลากรายการไปวางในกลุ่มที่ถูกต้อง (หรือแตะรายการ แล้วแตะกลุ่ม) · แตะรายการที่วางแล้วเพื่อนำออก</p>
      <div class="expool" data-z="-1" onclick="exZone(-1)">${pool.map(chip).join("") || '<small class="muted">วางครบแล้ว</small>'}</div>
      <div class="exzones">${v.zones.map((z, zi) => `<div class="exzone" data-z="${zi}" onclick="exZone(${zi})"><div class="exzt">${fm(z.t)}${exImg(z.img, "chimg")}</div><div class="exzi">${a.z.map((x, k) => (x === zi ? chip(k) : "")).join("")}</div></div>`).join("")}</div>`;
  }
  return "";
}
const exRedraw = () => { const q = EX.qs[EX.i], b = document.getElementById("exbody"); if (b) b.innerHTML = exBody(q); const d = document.getElementById("exdots"); if (d) d.innerHTML = exDots(); };
const exCur = () => EX.qs[EX.i];
function exPick(k) { const q = exCur(); EX.ans[q.id] = { i: k }; exRedraw(); exSave(q); }
function exTF(v) { const q = exCur(); EX.ans[q.id] = { v }; exRedraw(); exSave(q); }
function exText(t) { const q = exCur(); EX.ans[q.id] = { ...(EX.ans[q.id] || {}), t }; exSave(q); }
function exL(l) { const q = exCur(), a = EX.ans[q.id]; if (a.m[l] != null) { a.m[l] = null; EX.sel = null; exRedraw(); exSave(q); return; } EX.sel = EX.sel === l ? null : l; exRedraw(); }
function exR(r) {
  const q = exCur(), a = EX.ans[q.id], other = a.m.indexOf(r);
  if (EX.sel == null) { if (other >= 0) { a.m[other] = null; exRedraw(); exSave(q); } return; }
  if (other >= 0) a.m[other] = null;
  a.m[EX.sel] = r; EX.sel = null; exRedraw(); exSave(q);
}
function exZone(zi) {
  const q = exCur(), a = EX.ans[q.id];
  if (typeof EX.sel === "string" && EX.sel[0] === "i") { a.z[+EX.sel.slice(1)] = zi < 0 ? null : zi; EX.sel = null; exRedraw(); exSave(q); }
}
/* ลากวางด้วย pointer events (ใช้ได้ทั้งนิ้วและเมาส์) — ถ้าไม่ได้ลาก = ถือเป็นการแตะเพื่อเลือก */
function exDragStart(ev, k) {
  ev.stopPropagation(); if (ev.pointerType === "mouse") ev.preventDefault();
  const q = exCur(), a = EX.ans[q.id], el = ev.currentTarget, sx = ev.clientX, sy = ev.clientY;
  let ghost = null, moved = false;
  const mv = (e) => {
    if (!moved && Math.hypot(e.clientX - sx, e.clientY - sy) < 8) return;
    if (!moved) { moved = true; ghost = el.cloneNode(true); ghost.classList.add("exghost"); document.body.appendChild(ghost); el.classList.add("lift"); }
    ghost.style.left = e.clientX + "px"; ghost.style.top = e.clientY + "px"; e.preventDefault();
  };
  const up = (e) => {
    document.removeEventListener("pointermove", mv); document.removeEventListener("pointerup", up); document.removeEventListener("pointercancel", up);
    if (!moved) { // แตะ: ถ้าวางอยู่ในกลุ่มแล้ว → นำออก ไม่งั้นเลือกไว้
      if (a.z[k] != null) { a.z[k] = null; EX.sel = null; exRedraw(); exSave(q); } else { EX.sel = EX.sel === "i" + k ? null : "i" + k; exRedraw(); }
      return;
    }
    ghost.style.display = "none";
    const t = document.elementFromPoint(e.clientX, e.clientY), zone = t && t.closest && t.closest("[data-z]");
    ghost.remove();
    if (zone) { const zi = +zone.dataset.z; a.z[k] = zi < 0 ? null : zi; EX.sel = null; exSave(q); }
    exRedraw();
  };
  document.addEventListener("pointermove", mv, { passive: false }); document.addEventListener("pointerup", up); document.addEventListener("pointercancel", up);
}
async function exPhoto(input) {
  const f = input.files && input.files[0]; if (!f) return; const q = exCur(), s = document.getElementById("exphs");
  if (s) s.textContent = "กำลังอัปโหลด…";
  try {
    const blob = await shrink(f); if (!blob) throw new Error("อ่านรูปไม่สำเร็จ");
    if (blob.size > 1500000) throw new Error("รูปใหญ่เกินไป ลองถ่ายใหม่");
    const slot = await rpc("exam_slot", { p_token: tk(), p_attempt: EX.att.id, p_qid: q.id });
    const up = await sb.storage.from("exam").upload(slot + ".jpg", blob, { contentType: "image/jpeg", upsert: false });
    if (up.error) throw new Error("อัปโหลดไม่สำเร็จ: " + up.error.message);
    await rpc("exam_attach", { p_token: tk(), p_attempt: EX.att.id, p_qid: q.id, p_slot: slot });
    EX.photo[q.id] = true; exRedraw(); toast("แนบรูปแล้ว ✅");
  } catch (e) { toast(e.message); if (s) s.textContent = "แนบรูปไม่สำเร็จ"; }
  input.value = "";
}

/* ---------- ตรวจทานก่อนส่ง ---------- */
async function exReview1() {
  await exFlush(EX.qs[EX.i]);
  const un = EX.qs.map((q, k) => [q, k]).filter(([q]) => !exAnswered(q));
  const ov = document.getElementById("exov");
  ov.innerHTML = `<div class="exwrap"><div class="exbar"><b class="grow">${esc(EX.exam.title)}</b><span id="extimer" class="extimer">⏱ ${exFmtT(exRemain())}</span></div>
    <div class="excard"><h3 style="margin:0 0 6px">📤 ตรวจทานก่อนส่ง</h3>
      ${un.length ? `<p style="color:var(--red)">ยังไม่ได้ตอบ ${un.length} ข้อ: ${un.map(([, k]) => `<button class="exdot" onclick="exJump(${k})">${k + 1}</button>`).join(" ")}</p>` : '<p style="color:var(--green,#7be0a0)">ตอบครบทุกข้อแล้ว ✓</p>'}
      <p class="muted">เมื่อกดส่งแล้วจะแก้ไขไม่ได้${EX.exam.minutes ? "" : ""}</p>
      <div class="exnav"><button class="btn ghost" onclick="exJump(${EX.i})">◀ กลับไปแก้</button><button class="btn gold" onclick="exSubmit(false)">✅ ส่งข้อสอบ</button></div></div></div>`;
}
async function exSubmit(auto) {
  if (!EX || EX.sending) return;
  if (!auto && !confirm("ยืนยันส่งข้อสอบ? ส่งแล้วแก้ไขไม่ได้")) return;
  EX.sending = true;
  try { for (const q of EX.qs) if (EX_SAVE[q.id]) await exFlush(q); } catch (e) { /* ส่งต่อ */ }
  let r;
  try { r = await rpc("exam_submit", { p_token: tk(), p_attempt: EX.att.id }); }
  catch (e) { EX.sending = false; return toast(e.message); }
  EX.done = true; clearInterval(EX_TIMER);
  const ov = document.getElementById("exov");
  ov.innerHTML = `<div class="exwrap"><div class="excard center"><div style="font-size:56px">✅</div><h2 style="margin:4px 0">ส่งข้อสอบแล้ว</h2>
    ${r.visible ? `<p style="font-size:1.4em;margin:6px 0"><b>${r.score}</b> / ${r.total} คะแนน</p><p class="muted">ข้อเขียน/ข้อวาดรูปที่รอครูตรวจ อาจเพิ่มคะแนนภายหลัง</p>` : '<p class="muted">ผลสอบและเฉลยจะแสดงเมื่อครูเปิดให้ดู</p>'}
    <button class="btn gold" onclick="exClose()">กลับหน้าสอบ</button></div></div>`;
  load().catch(() => {});
}

/* ---------- ดูเฉลย ---------- */
async function examReview(id) {
  let r; try { r = await rpc("exam_review", { p_token: tk(), p_exam: id }); } catch (e) { return toast(e.message); }
  const L = (k) => "ABCDEFGH"[k] || k + 1;
  const one = (q, n) => {
    const v = q.view, a = q.ans || {}, key = q.key; let mine = "", ok = "";
    if (q.kind === "mcq") { mine = a.i != null ? `${L(a.i)}. ${fm(v.choices[a.i] && v.choices[a.i].t)}` : "—"; ok = `${L(key)}. ${fm(v.choices[key].t)}`; }
    else if (q.kind === "tf") { mine = a.v == null ? "—" : a.v ? "ถูก" : "ผิด"; ok = key ? "ถูก" : "ผิด"; }
    else if (q.kind === "short") { mine = (a.t ? fm(a.t) : "") + (q.has_photo ? " 📷(แนบรูป)" : "") || "—"; ok = (key && key.length) ? key.map(fm).join(" / ") : "ครูตรวจจากรูป/คำอธิบาย"; }
    else if (q.kind === "match") { mine = (a.m || []).map((x, l) => `${l + 1}→${x == null ? "?" : L(x)}`).join("  ") || "—"; ok = key.map((x, l) => `${l + 1}→${L(x)}`).join("  "); }
    else if (q.kind === "drag") { const zn = (z) => (z == null ? "?" : fm(v.zones[z].t)); mine = (a.z || []).map((z, k) => `${fm(v.items[k].t)} → ${zn(z)}`).join("<br>") || "—"; ok = key.map((z, k) => `${fm(v.items[k].t)} → ${zn(z)}`).join("<br>"); }
    const full = q.score != null && q.score >= q.points - 0.001;
    return `<div class="card exrv ${q.graded ? (full ? "good" : "bad") : "wait"}"><div class="row" style="gap:6px"><b class="grow">ข้อ ${n}</b><span class="tag">${q.graded ? `${q.score}/${q.points}` : "รอตรวจ"}</span></div>
      <div class="exq">${fm(q.q)}</div>${exImg(q.img)}
      <p style="margin:4px 0"><small class="muted">คำตอบของเรา:</small><br>${mine}</p>
      ${q.kind === "match" || q.kind === "mcq" ? exRvChoices(q) : ""}
      <p style="margin:4px 0"><small class="muted">เฉลย:</small><br><b>${ok}</b></p>
      ${q.note ? `<p class="muted">💬 ครู: ${esc(q.note)}</p>` : ""}
      ${q.explain ? `<p class="muted">📖 ${fm(q.explain)}</p>` : ""}${exImg(q.explain_img)}</div>`;
  };
  const ov = document.createElement("div"); ov.id = "eqov"; ov.setAttribute("role", "dialog");
  ov.innerHTML = `<div class="eqbox" style="max-height:88vh"><button class="patchx" aria-label="ปิด" onclick="eqClose()">✕</button>
    <h3>🔍 ${esc(r.exam.title)} — ${r.score}/${r.total}</h3>${r.review ? '<p class="muted">บางข้อยังรอครูตรวจ</p>' : ""}${r.qs.map((q, i) => one(q, i + 1)).join("")}</div>`;
  ov.addEventListener("click", (e) => { if (e.target === ov) eqClose(); });
  document.body.appendChild(ov);
}
const exRvChoices = (q) => (q.kind === "match"
  ? `<small class="muted">ซ้าย: ${q.view.left.map((x, k) => `${k + 1}=${fm(x.t)}`).join(" · ")}<br>ขวา: ${q.view.right.map((x, k) => `${"ABCDEFGH"[k]}=${fm(x.t)}`).join(" · ")}</small>`
  : "");
