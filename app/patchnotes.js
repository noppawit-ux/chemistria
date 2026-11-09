/* ประกาศอัปเดต — ส่วนหนึ่งของหน้านักเรียน (index.html) โหลดต่อกันตามลำดับใน index.html */
/* ---------------- ประกาศอัปเดต (patch notes) ---------------- */
const APP_VERSION = "1.80";
const PATCH = {
  id: "2026-11-07d", ver: APP_VERSION, title: "โปรโมชันเปิดระบบใหม่! 🎉", date: "7 พ.ย. 2569", img: "assets/news/promo.jpg",
  items: [
    ["🎁", "ของขวัญต้อนรับ รับฟรีคนละ 1 ครั้ง", "เหรียญ + EXP + ตั๋วสุ่มกาชา กดรับที่การ์ดโปรบนหน้าหลัก"],
    ["⚡", "โบนัส EXP +25% ช่วงเปิดระบบ", "ทุกการเช็คชื่อ ส่งงาน และเควสได้ EXP เพิ่ม 25% จนถึงวันสิ้นสุดโปร"],
    ["📚", "ตารางสอนขึ้นในปฏิทินแล้ว", "เห็นคาบเรียนของห้องตัวเองทุกสัปดาห์ และการ์ดคาบเรียนวันนี้บนหน้าหลัก"],
    ["🏃", "มินิเกมเคมีรัน + บอสแบบใหม่", "แตะการ์ดบอสดูภาพใหญ่ ความสามารถ และสถิติเพื่อนที่ช่วยโจมตี"],
  ],
};
document.addEventListener("visibilitychange", () => document.documentElement.classList.toggle("anim-off", document.hidden));
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
function patchClose() { try { localStorage.setItem(PATCH_KEY, PATCH.id); } catch (e) {} document.getElementById("patchov")?.remove(); }
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

async function load() {
  if (!tk()) return showLogin();
  try {
    const prev = D;
    // โหลดพร้อมกัน (เดิมโหลดทีละอัน ช้ากว่า 3–4 เท่า); แดชบอร์ดผิดพลาด = เข้าสู่ระบบใหม่ ส่วนที่เหลือพลาดได้
    const [dash, hof, ext, brd, nws, ttl, prm, gld] = await Promise.all([
      rpc("student_dashboard", { p_token: tk() }),
      rpc("hall_of_fame", { p_token: tk() }).catch(() => []),
      rpc("student_extras", { p_token: tk() }).catch(() => ({})),
      rpc("board_list", { p_token: tk() }).catch(() => ({ posts: [], unread: 0 })),
      rpc("news_list", { p_token: tk() }).catch(() => []),
      rpc("timetable_list", { p_token: tk() }).catch(() => []),
      rpc("promo_status", { p_token: tk() }).catch(() => ({ active: false })),
      rpc("guild_status", { p_token: tk() }).catch(() => null),
    ]);
    GLD = gld;
    NEWS = nws || []; TT = ttl || []; PROMO = prm || { active: false };
    D = dash; HOF = hof || []; X = ext || {}; B = brd || { posts: [], unread: 0 };
    DRAFT = null; if (!prev) document.getElementById("fxlayer")?.replaceChildren(); setTimeout(() => document.querySelectorAll("#fxlayer .pfxg[data-loop]").forEach((e) => e.remove()), 600);
    render(); if (PEEK) peekBar(); else { kbAuto(); fxDiff(prev); celCheck(); if (!prev) patchShow(); }
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
