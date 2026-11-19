/* แท็บ 🧪 ไอเทม — ไอเทมกดใช้ (ยา/บัฟ/ม้วนอัปเกรด) + อัปเกรดของสวมใส่ · ส่วนหนึ่งของหน้านักเรียน */
let ITM = null, ITM_STALE = true, ITM_BUSY = false;
const ST_LBL = { int: "🧠 ปัญญา", dil: "💪 ขยัน", str: "⚔️ พลัง", luk: "🍀 โชค" };
const BUFF_LBL = { buff_exp: "🧪 EXP", buff_coin: "💰 เหรียญ", buff_luk: "🍀 โชค", buff_str: "⚔️ ดาเมจบอส", buff_int: "🧠 EXP ควิซ" };
async function itemsLoad() {
  if (ITM_BUSY || (ITM && !ITM_STALE)) return;
  ITM_BUSY = true;
  try { ITM = await rpc("my_items", { p_token: tk() }); ITM_STALE = false; } catch (e) { ITM = { error: e.message }; ITM_STALE = false; }
  ITM_BUSY = false;
  if (tab === "items") { const v = $("#view"); if (v) v.innerHTML = itemsHtml(); }
  else if (tab === "home") { try { render(); } catch (e) {} }
}
// การ์ดหน้าหลัก: ไอเทมกดใช้ที่เหลือ + บัพที่มีผลอยู่ (ของตัวเอง + จากเพื่อน)
function homeItemsHtml() {
  if (typeof PEEK !== "undefined" && PEEK) return "";
  if (!ITM || ITM_STALE) itemsLoad();
  if (!ITM) return '<div class="card"><h3>🎒 ไอเทมของฉัน</h3><p class="muted">กำลังโหลด…</p></div>';
  if (ITM.error) return "";
  const own = (ITM.items || []).filter((i) => i.qty > 0), buffs = ITM.buffs || [], tot = typeof relTotals === "function" ? relTotals() : {};
  const total = own.reduce((a, i) => a + i.qty, 0);
  const tiles = own.map((i) => {
    const act = i.kind === "heal" ? '<small class="muted">ใช้ในศึก 💚</small>' : i.kind === "scroll" ? '<button class="btn small gold" onclick="scrollPick()">ใช้</button>'
      : i.kind === "stat_reset" ? '<small class="muted">รีเซ็ตแต้ม</small>'
      : i.active_until ? `<small class="tag wait">มีผล ${minsLeft(i.active_until)} น.</small>` : `<button class="btn small gold" onclick="itemUse('${i.id}','${esc(i.name)}')">ใช้</button>`;
    return `<div class="hi-tile" title="${esc(i.descr || "")}"><span class="hi-ico">${pxIco(i)}</span><b>${esc(i.name)}</b><span class="hi-q">×${i.qty}</span>${act}</div>`;
  }).join("");
  const mine = buffs.map((b) => `<span class="tag ok">${BUFF_LBL[b.kind] || b.kind} +${b.power}${b.kind === "buff_luk" || b.kind === "buff_int" ? "" : "%"} · ${minsLeft(b.until)} นาที</span>`).join(" ");
  const fr = Object.keys(tot).map((k) => `<span class="tag ok">💞 ${relBuffTxt(k, tot[k])}</span>`).join(" ");
  return `<div class="card hi-card"><div class="row" style="align-items:center"><h3 class="grow" style="margin:0">🎒 ไอเทมกดใช้ <small class="muted" style="font-weight:400">เหลือ ${total} ชิ้น</small></h3><button class="btn small ghost" onclick="go('items')">ร้าน/กระเป๋า</button></div>
    <div class="hi-buffs"><small class="muted">บัพที่มีผลอยู่:</small> ${mine || fr ? mine + " " + fr : '<small class="muted">ยังไม่มี</small>'}</div>
    ${tiles ? `<div class="hi-grid">${tiles}</div>` : '<p class="muted" style="margin:8px 0 0">ยังไม่มีไอเทม — ซื้อได้ที่ร้านไอเทม</p>'}</div>`;
}
const itemsAct = (fn, msg) => act(async () => { const r = await fn(); ITM_STALE = true; return r; }, msg);
const itemBuy = (id, n, p) => confirm(`ซื้อ “${n}” ราคา ${p} เหรียญ?`) && itemsAct(() => rpc("buy_item", { p_token: tk(), p_item: id, p_n: 1 }), "ซื้อแล้ว 🎒");
const itemUse = (id, n) => confirm(`ใช้ “${n}” ?`) && itemsAct(() => rpc("use_item", { p_token: tk(), p_item: id }).then((r) => { toast("✨ " + r.msg); return r; }));
const gearUp = (id, n, c, s) => confirm(`อัปเกรด “${n}” ใช้ ${c} เหรียญ + ม้วน ${s} ม้วน?`) && itemsAct(() => rpc("upgrade_decor", { p_token: tk(), p_item: id }), "อัปเกรดสำเร็จ ✨");
const minsLeft = (u) => Math.max(1, Math.ceil((new Date(u) - Date.now()) / 60000));
function scrollPick() {
  if (!ITM || !ITM.gear) return;
  document.getElementById("eqov")?.remove();
  const sc = (ITM.items || []).find((i) => i.kind === "scroll"), sq = sc ? sc.qty : 0;
  const rows = (ITM.gear || []).map((g) => {
    const c = g.cost, maxed = g.lvl >= c.max, can = g.main && !maxed;
    return `<div class="eqpick"><span style="font-size:26px">${pxIco(g)}</span><div class="grow"><b>${esc(g.name)}</b> <span class="tag">${esc(g.rarity)}</span> <span class="tag ${g.lvl > 1 ? "ok" : ""}">Lv ${g.lvl}/${c.max}</span>${g.equipped ? ' <span class="tag wait">สวมอยู่</span>' : ""}
      <div class="muted" style="font-size:.85em">${g.main ? `+1 ${ST_LBL[g.main]} ต่อเลเวล` : "ไม่มีสเตตัส"}</div></div>
      ${!g.main ? "" : maxed ? '<span class="tag ok">สูงสุด</span>' : `<button class="btn small gold" onclick="scrollApply('${g.id}','${esc(g.name)}',${c.coins},${c.scrolls})">${c.coins}🪙 +📜${c.scrolls}</button>`}</div>`;
  }).join("") || '<p class="muted center">ยังไม่มีอุปกรณ์ — ซื้อจากแท็บ 🎨 ตกแต่ง หรือสุ่มกาชา</p>';
  const ov = document.createElement("div"); ov.id = "eqov"; ov.setAttribute("role", "dialog");
  ov.innerHTML = `<div class="eqbox"><button class="patchx" aria-label="ปิด" onclick="eqClose()">✕</button><h3>📜 เลือกอุปกรณ์ที่จะอัปเกรด</h3><p class="muted" style="margin:0 0 6px">มีม้วนอัปเกรด ${sq} ม้วน · เหรียญ ${D.student.coins} 🪙</p>${rows}</div>`;
  ov.addEventListener("click", (e) => { if (e.target === ov) eqClose(); });
  document.body.appendChild(ov);
}
const scrollApply = async (id, n, c, sc) => {
  if (!confirm(`อัปเกรด “${n}” ใช้ ${c} เหรียญ + ม้วน ${sc} ม้วน?`)) return;
  try { await rpc("upgrade_decor", { p_token: tk(), p_item: id }); ITM_STALE = true; await load(); toast("อัปเกรดสำเร็จ ✨"); eqClose(); }
  catch (e) { toast(e.message); }
};
function itemsHtml() {
  if (!ITM) return '<div class="card"><p class="muted">กำลังโหลดไอเทม…</p></div>';
  if (ITM.error) return `<div class="card"><h3>🧪 ไอเทม</h3><p class="muted">${esc(ITM.error)}</p></div>`;
  const items = ITM.items || [], buffs = ITM.buffs || [];
  const scroll = items.find((i) => i.kind === "scroll"), sq = scroll ? scroll.qty : 0;
  const own = items.filter((i) => i.qty > 0);
  const chips = buffs.length ? buffs.map((b) => `<span class="tag ok">${BUFF_LBL[b.kind] || b.kind} +${b.power}${b.kind === "buff_luk" || b.kind === "buff_int" ? "" : "%"} · เหลือ ${minsLeft(b.until)} นาที</span>`).join(" ") : '<span class="muted">ยังไม่มีบัฟที่มีผลอยู่</span>';
  const bag = own.map((i) => {
    const btn = i.kind === "heal" ? '<span class="muted">ใช้ในศึกมอนสเตอร์ (ปุ่ม 💚)</span>' : i.kind === "scroll" ? '<button class="btn small gold" onclick="scrollPick()">ใช้ → เลือกอุปกรณ์</button>'
      : i.active_until ? `<span class="tag wait">มีผลอยู่ ${minsLeft(i.active_until)} นาที</span>` : `<button class="btn small gold" onclick="itemUse('${i.id}','${esc(i.name)}')">ใช้</button>`;
    return `<div class="item"><span style="font-size:26px">${pxIco(i)}</span><div class="grow"><b>${esc(i.name)}</b> <span class="tag">×${i.qty}</span><div class="muted">${esc(i.descr || "")}</div></div>${btn}</div>`;
  }).join("") || '<p class="muted">กระเป๋าว่าง — ซื้อไอเทมจากร้านด้านล่างได้เลย</p>';
  const shop = items.filter((i) => i.price != null).map((i) => {
    const left = Math.max(0, i.daily_buy - i.bought), ok = left > 0 && D.student.coins >= i.price;
    return `<div class="item"><span style="font-size:26px">${pxIco(i)}</span><div class="grow"><b>${esc(i.name)}</b> <span class="tag">${esc(i.rarity)}</span><div class="muted">${esc(i.descr || "")}</div><small class="muted">วันนี้ซื้อได้อีก ${left}/${i.daily_buy}</small></div>
      <button class="btn small ${ok ? "gold" : "ghost"}" ${left > 0 ? "" : "disabled"} onclick="itemBuy('${i.id}','${esc(i.name)}',${i.price})">${i.price} 🪙</button></div>`;
  }).join("");
  return `<div class="card"><h3>🧪 ไอเทมของฉัน</h3><p class="muted" style="margin:0 0 6px">บัฟมีผลตามเวลาที่กำหนด · ชนิดเดียวกันซ้อนไม่ได้ · เหรียญของคุณ <b>${D.student.coins}</b> 🪙</p><div>${chips}</div></div>
    <div class="card"><h3>🎒 กระเป๋า</h3>${bag}</div>
    <div class="card"><h3>🛒 ร้านไอเทม</h3>${shop}</div>`;
}
VIEWS.items = () => { itemsLoad(); return itemsHtml(); };
