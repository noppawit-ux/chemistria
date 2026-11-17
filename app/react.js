/* กดอิโมจิให้ตัวละครเพื่อน + ดูตัวละครเพื่อน (v2.25) */
const REACTS = ["❤️", "👍", "🔥", "😄", "⭐", "👏"];
let MYREACT = null, REACT_BUSY = false, CVIEW = null;
async function myReactLoad(force) {
  if (REACT_BUSY || (MYREACT && !force) || (typeof PEEK !== "undefined" && PEEK)) return; REACT_BUSY = true;
  try { MYREACT = await rpc("char_view", { p_token: tk(), p_no: null }); } catch (e) { MYREACT = { error: true }; }
  REACT_BUSY = false;
  try { if (typeof tab !== "undefined" && tab === "home") render(); } catch (e) {}
}
function reactChips(totals) {
  const e = Object.entries(totals || {}).filter(([, n]) => +n > 0);
  return e.length ? e.map(([k, n]) => `<span class="rchip">${k}<b>${n}</b></span>`).join("") : '<span class="muted">ยังไม่มีใครกดให้ — ลองไปกดให้เพื่อนก่อนนะ</span>';
}
function reactBox() {
  if (typeof PEEK !== "undefined" && PEEK) return "";
  if (!MYREACT) { myReactLoad(); return ""; }
  if (MYREACT.error) return "";
  return `<div class="reactbox"><div class="muted center" style="margin-bottom:4px">💌 อิโมจิที่เพื่อนกดให้ตัวละครของฉัน (${MYREACT.total})</div><div class="row" style="gap:6px;justify-content:center;flex-wrap:wrap">${reactChips(MYREACT.totals)}</div></div>`;
}
function cvClose() { document.getElementById("cvov")?.remove(); }
function cvPaint() {
  const v = CVIEW; if (!v) return; let ov = document.getElementById("cvov");
  if (!ov) { ov = document.createElement("div"); ov.id = "cvov"; ov.setAttribute("role", "dialog"); document.body.appendChild(ov); }
  const dc = v.decor || {};
  ov.innerHTML = `<div class="np-bg" onclick="cvClose()"></div><div class="cvbox"><button class="patchx" aria-label="ปิด" onclick="cvClose()">✕</button>
    <h3 style="margin:0">${esc(v.name)} <small class="muted">เลขที่ ${v.no}</small></h3>
    <div class="muted" style="margin-bottom:6px">${esc(rankName(v.rank_info))} · Lv.${v.level}</div>
    <div class="cvstage">${stage(v.char_class, v.rank_info, dc, "lg")}</div><div style="margin:6px 0">${titleTag(dc)}</div>
    <div class="cveq">${SLOTS.filter(([k]) => k !== "title" && dc[k]).map(([k, , lb]) => `<span class="cvit rar-${esc(dc[k].rarity || "N")}" title="${esc(lb)}: ${esc(dc[k].name)}">${slotIco(k, dc[k], v.char_class)}</span>`).join("")}</div>
    ${v.is_me ? "" : `<div class="muted" style="margin:8px 0 4px">กดอิโมจิให้เพื่อน (วันละ 1 อิโมจิ · ${v.sent_today}/${v.limit} คนวันนี้)</div>
    <div class="reactrow">${REACTS.map((e) => `<button class="rbtn ${v.mine === e ? "on" : ""}" onclick="cvReact('${e}')" aria-label="${e}">${e}</button>`).join("")}</div>`}
    <div class="row" style="gap:6px;justify-content:center;flex-wrap:wrap;margin-top:8px">${reactChips(v.totals)}</div></div>`;
}
async function cvOpen(no) {
  try { CVIEW = await rpc("char_view", { p_token: tk(), p_no: no }); cvPaint(); } catch (e) { toast(e.message); }
}
async function cvReact(e) {
  if (!CVIEW) return; const no = CVIEW.no, was = CVIEW.mine;
  try { CVIEW = await rpc("char_react", { p_token: tk(), p_no: no, p_emoji: e }); try { SFX.play("pop"); } catch (x) {} cvPaint();
    if (CVIEW.mine && CVIEW.mine !== was) cvBurst(CVIEW.mine); } catch (x) { toast(x.message); }
}
function cvBurst(e) {
  const box = document.querySelector("#cvov .cvstage"); if (!box) return;
  for (let i = 0; i < 8; i++) { const s = document.createElement("span"); s.className = "cvfly"; s.textContent = e; s.style.left = 20 + Math.random() * 60 + "%"; s.style.animationDelay = i * 70 + "ms"; box.appendChild(s); setTimeout(() => s.remove(), 1800); }
}
