/* ประกาศอัปเดต — ส่วนหนึ่งของหน้านักเรียน (index.html) โหลดต่อกันตามลำดับใน index.html */
/* ---------------- ประกาศอัปเดต (patch notes) ---------------- */
const APP_VERSION = "2.80";
const PATCH = {
  id: "2026-11-26", ver: APP_VERSION, title: "โหมดประลอง: เดิมพัน + ลีก 🏆", date: "26 พ.ย. 2569", img: "assets/news/promo.jpg",
  items: [
    ["💰", "ท้าดวลมีเดิมพัน", "เลือกเดิมพันเหรียญก่อนท้า ทั้งสองฝ่ายวางเท่ากัน ผู้ชนะได้เหรียญทั้งกอง + EXP · เสมอหรือออกก่อน 3 รอบ = คืนเดิมพัน"],
    ["🚀", "โบนัสผู้ท้าชิง", "ชนะคนที่ EXP สูงกว่ามาก ได้ EXP เพิ่ม"],
    ["🏆", "ลีกประลองประจำสัปดาห์", "ทุกดวลสะสมแต้ม (ชนะคนแต้มสูงกว่าได้โบนัส) จบสัปดาห์ อันดับ 1–3 ของห้องรับ EXP + เหรียญ"],
    ["🔄", "รีเฟรชหน้าเว็บ (หรือล้างแคช) ก่อนเล่น", "ต้องเป็นเวอร์ชัน 2.80 ถึงจะเห็นโหมดใหม่"],
  ],
};
const PATCH_KEY = "chem_patch_seen";
function patchShow(force) {
  if (PEEK || !D) return;
  let seen = null; try { seen = localStorage.getItem(PATCH_KEY); } catch (e) {}
  if (!force && seen === PATCH.id) return;
  if (document.getElementById("patchov")) return;
  const ov = document.createElement("div"); ov.id = "patchov"; ov.setAttribute("role", "dialog"); ov.setAttribute("aria-modal", "true");
  ov.innerHTML = `<div class="patchbox"><button class="patchx" aria-label="ปิด" onclick="patchClose()">✕</button>
    <div class="patchimgw"><img class="patchimg" src="${esc(PATCH.img || "assets/patch-banner.jpg")}" alt="" onerror="this.parentNode.remove()"></div><div class="patchh">📢 ${esc(PATCH.title)} <span class="patchver">v${esc(PATCH.ver)}</span></div><div class="muted" style="text-align:center">ประกาศอัปเดต · ${esc(PATCH.date)}</div>
    <div class="patchl">${PATCH.items.map((i) => `<div class="patchi"><span>${i[0]}</span><div><b>${esc(i[1])}</b><div class="muted">${esc(i[2])}</div></div></div>`).join("")}</div>
    <div class="row" style="justify-content:center"><button class="btn gold" onclick="patchClose()">รับทราบ ปิดหน้านี้</button></div></div>`;
  ov.addEventListener("click", (e) => { if (e.target === ov) patchClose(); });
  document.body.appendChild(ov);
}
function patchClose() { try { localStorage.setItem(PATCH_KEY, PATCH.id); } catch (e) {} document.getElementById("patchov")?.remove(); if (typeof giftShow === "function") giftShow(); if (typeof alertsAuto === "function") alertsAuto(); }
document.addEventListener("keydown", (e) => { if (e.key === "Escape") patchClose(); });
function peekBar() {
  let b = document.getElementById("peekbar"); if (!b) { b = document.createElement("div"); b.id = "peekbar"; document.body.appendChild(b); document.body.classList.add("peeking"); }
  b.innerHTML = `👁 โหมดส่องนักเรียน: <b>${esc(D.student.name)}</b> (อ่านอย่างเดียว · ไม่มีผลต่อคะแนน/อันดับ) <button onclick="window.close();setTimeout(()=>{location.href='admin.html'},200)">ปิด</button>`;
}
function logout() { localStorage.removeItem(TOKEN_KEY); D = null; try { sessionStorage.removeItem("kb_seen"); } catch (e) {} const k = document.getElementById("kbpop"); if (k) k.remove(); showLogin(); }
async function changePin() {
  const o = prompt("PIN เดิม"); if (o === null) return;
  const n = prompt("PIN ใหม่ (ตัวเลข 4-6 หลัก)"); if (n === null) return;
  try { await rpc("change_pin", { p_token: tk(), p_old: o, p_new: n }); toast("เปลี่ยน PIN แล้ว ✅"); }
  catch (e) { toast(e.message); }
}
const tk = () => PEEK || localStorage.getItem(TOKEN_KEY);
// v2.50: แคชชั่วคราวของข้อมูลที่ไม่เปลี่ยนบ่อย (ข่าว ตารางเรียน กิลด์ ฯลฯ) — load() ที่เรียกหลังทุกการกดจะไม่ยิงซ้ำถ้ายังสดอยู่
const LC = {}, lcFresh = (k, ms) => !!LC[k] && Date.now() - LC[k] < ms, lcMark = (k) => { LC[k] = Date.now(); };
const lcAct = (fn) => {   // เรียกจาก act(): ล้างแคชเฉพาะส่วนที่การกระทำนี้อาจเปลี่ยน
  const t = String(fn);
  LC.cls = LC.hst = LC.gbest = 0;
  if (/guild/i.test(t)) LC.guild = 0;
  if (/gift/i.test(t)) LC.gift = 0;
  if (/decor|card|gear|equip|item|gacha|upgrade|stat/i.test(t)) LC.gear = 0;
  if (/board/i.test(t)) LC.board = 0;
  if (/promo/i.test(t)) LC.promo = 0;
};

async function load() {
  if (!tk()) return showLogin();
  try {
    try { if ((typeof PEEK === "undefined" || !PEEK) && !lcFresh("gear", 60000)) { lcMark("gear"); setTimeout(() => gearLoad(true), 0); } } catch (e) {}
    const prev = D;
    // โหลดพร้อมกัน (เดิมโหลดทีละอัน ช้ากว่า 3–4 เท่า); แดชบอร์ดผิดพลาด = เข้าสู่ระบบใหม่ ส่วนที่เหลือพลาดได้
    // v2.49: โหลด 2 ชั้น — ชั้นแรก (หน้าหลักขั้นต่ำ) แล้วแสดงเลย ส่วนที่เหลือโหลดตามหลัง กันหมุนค้างเมื่อเซิร์ฟเวอร์ช้า
    const tmo = (p, ms = 20000) => Promise.race([p, new Promise((_, rej) => setTimeout(() => rej(new Error("เซิร์ฟเวอร์ตอบช้า ลองกดโหลดใหม่อีกครั้ง")), ms))]);
    const [, dash, ext] = await tmo(Promise.all([
      chkLoad(),
      rpc("student_dashboard", { p_token: tk() }),
      rpc("student_extras", { p_token: tk() }).catch(() => ({})),
    ]));
    D = dash; X = ext || {};
    DRAFT = null; if (!prev) document.getElementById("fxlayer")?.replaceChildren(); setTimeout(() => document.querySelectorAll("#fxlayer .pfxg[data-loop]").forEach((e) => e.remove()), 600);
    render(); if (PEEK) peekBar(); else { kbAuto(); fxDiff(prev); celCheck(); if (!prev) patchShow(); }
    const L = (n) => tmo(rpc(n, { p_token: tk() }), 25000);
    const jobs = []; let giftRan = false;
    const job = (k, ms, name, set) => { if (lcFresh(k, ms)) return; jobs.push(L(name).then((v) => { set(v); lcMark(k); if (k === "gift") giftRan = true; }).catch(() => {})); };
    job("hof", 180000, "hall_of_fame", (v) => { HOF = v || []; });
    job("board", 60000, "board_list", (v) => { B = v || { posts: [], unread: 0 }; });
    job("news", 180000, "news_list", (v) => { NEWS = v || []; });
    job("notices", 45000, "my_notices", (v) => { NOTICES = v || []; });
    job("tt", 180000, "timetable_list", (v) => { TT = v || []; });
    job("promo", 120000, "promo_status", (v) => { PROMO = v || { active: false }; });
    job("guild", 60000, "guild_status", (v) => { GLD = v || null; });
    job("hst", 45000, "home_stats", (v) => { HST = v || null; });
    if (!PEEK) {
      job("gift", 45000, "gift_inbox", (v) => { GIFTS = v || []; });
      job("gbest", 60000, "game_bests_all", (v) => { if (v) GBEST = v; });
      job("cls", 45000, "class_info", (v) => { CLS = v || null; });
    } else { GIFTS = []; }
    await Promise.all(jobs);
    if (!jobs.length) return;
    render(); if (!PEEK && giftRan) giftShow();
  } catch (e) {
    if (!PEEK && /เซสชัน|หมดอายุ|JWT/.test(e.message || "")) localStorage.removeItem(TOKEN_KEY);   // ไม่ล้างล็อกอินเมื่อแค่เน็ตหลุด
    showLogin(e.message);
  }
}


/* ประกาศ popup แสดงความยินดี: ได้ SSR / เลื่อนแรงค์ (ของเพื่อนร่วมห้อง) */
const CEL_KEY = "chem_cel_seen"; let CELQ = [], CELBUSY = false, CELTIMER = null;
async function celCheck() {
  if (!tk()) return;
  try {
    let since = null; try { const v = localStorage.getItem(CEL_KEY); since = v === null ? null : Number(v); } catch (e) {}
    const r = await rpc("celebrations_feed", { p_token: tk(), p_since: since });
    try { localStorage.setItem(CEL_KEY, String(r.max || 0)); } catch (e) {}
    (r.items || []).forEach((x) => CELQ.push(x));
    celNext();
  } catch (e) {}
  clearTimeout(CELTIMER); CELTIMER = setTimeout(celCheck, 60000);
}
function celNext() {
  CELQ.splice(0).slice(-4).forEach((x) => {
    const who = x.mine ? "คุณ" : x.name;
    if (x.kind === "leg") NOTE.show({ kind: "leg", icon: x.emoji || "🔴", title: `🔴 ${who} ได้ LEGENDARY!`, text: x.title, ms: 6000 });
    else if (x.kind === "ssr") NOTE.show({ kind: "ssr", icon: x.emoji || "🎁", title: `🎉 ${who} ได้ SSR!`, text: x.title, ms: 4500 });
    else NOTE.show({ kind: "cel", icon: "🏆", title: `🎉 ${who} เลื่อนแรงค์!`, text: x.title, ms: 4500 });
  });
}
/* เอฟเฟกต์พิกเซลเมื่อค่าเปลี่ยน: เลเวล/แรงก์/เหรียญ/EXP/เหรียญตรา */
/* popup แจ้งรางวัล/เลื่อนขั้นที่มุมบนของจอ แล้วหายเอง (แทนเอฟเฟกต์เต็มจอ) */
const NOTE = (() => {
  let box = null; const MAX = 3;
  const SND = { level: "levelup", rank: "rank", reward: "coin", ach: "chime", ssr: "chime", leg: "chime", cel: "toast" };
  function show(o) {                       // o: {kind, icon, title, text, ms}
    if (!box) { box = document.createElement("div"); box.id = "notes"; document.body.appendChild(box); }
    while (box.children.length >= MAX) box.firstChild.remove();
    const el = document.createElement("div"); el.className = "note n-" + (o.kind || "reward");
    el.innerHTML = `<span class="n-ic">${o.icon || "🎁"}</span><span class="n-tx"><b>${esc(o.title || "")}</b>${o.text ? `<small>${esc(o.text)}</small>` : ""}</span>`;
    const close = () => { el.classList.add("out"); setTimeout(() => el.remove(), 300); };
    el.onclick = close; box.appendChild(el); setTimeout(close, o.ms || 3800);
    try { if (typeof SFX !== "undefined") SFX.play(SND[o.kind] || "toast", { gap: 200 }); } catch (e) {}
  }
  return { show };
})();
function fxDiff(o) {
  if (typeof FX === "undefined" || !o || !o.student || !D || !D.student || o.student.id !== D.student.id) return;
  const a = o.student, b = D.student;
  setTimeout(() => {
    const gain = [];
    if (b.exp > a.exp) gain.push(`+${b.exp - a.exp} EXP`);
    if (b.coins > a.coins) gain.push(`+${b.coins - a.coins} 🪙`);
    if (b.level > a.level) NOTE.show({ kind: "level", icon: "⬆️", title: `เลเวลอัป! Lv.${b.level}`, text: gain.join(" · ") }), FX.levelUp();
    else if (o.rank_info && D.rank_info && o.rank_info.key !== D.rank_info.key) NOTE.show({ kind: "rank", icon: "🏆", title: `เลื่อนแรงค์เป็น ${D.rank_info.name}!`, text: gain.join(" · ") }), FX.rankUp();
    else if (gain.length) NOTE.show({ kind: "reward", icon: "🎁", title: "ได้รับรางวัล", text: gain.join(" · "), ms: 2800 });
    const had = new Set((o.achievements || []).filter((x) => x.earned_at).map((x) => x.id));
    (D.achievements || []).filter((x) => x.earned_at && !had.has(x.id)).forEach((x) => NOTE.show({ kind: "ach", icon: x.emoji || "🏅", title: "ปลดล็อกความสำเร็จ", text: x.name }));
  }, 250);
}
