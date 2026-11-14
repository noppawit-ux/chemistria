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
}
const itemsAct = (fn, msg) => act(async () => { const r = await fn(); ITM_STALE = true; return r; }, msg);
const itemBuy = (id, n, p) => confirm(`ซื้อ “${n}” ราคา ${p} เหรียญ?`) && itemsAct(() => rpc("buy_item", { p_token: tk(), p_item: id, p_n: 1 }), "ซื้อแล้ว 🎒");
const itemUse = (id, n) => confirm(`ใช้ “${n}” ?`) && itemsAct(() => rpc("use_item", { p_token: tk(), p_item: id }).then((r) => { toast("✨ " + r.msg); return r; }));
const gearUp = (id, n, c, s) => confirm(`อัปเกรด “${n}” ใช้ ${c} เหรียญ + ม้วน ${s} ม้วน?`) && itemsAct(() => rpc("upgrade_decor", { p_token: tk(), p_item: id }), "อัปเกรดสำเร็จ ✨");
function itemsHtml() {
  if (!ITM) return '<div class="card"><p class="muted">กำลังโหลดไอเทม…</p></div>';
  if (ITM.error) return `<div class="card"><h3>🧪 ไอเทม</h3><p class="muted">${esc(ITM.error)}</p></div>`;
  const items = ITM.items || [], gear = ITM.gear || [], buffs = ITM.buffs || [];
  const scroll = items.find((i) => i.kind === "scroll"), sq = scroll ? scroll.qty : 0;
  const own = items.filter((i) => i.qty > 0);
  const chips = buffs.length ? buffs.map((b) => `<span class="tag ok">${BUFF_LBL[b.kind] || b.kind} +${b.power}${b.kind === "buff_luk" || b.kind === "buff_int" ? "" : "%"}</span>`).join(" ") : '<span class="muted">ยังไม่มีบัฟวันนี้</span>';
  const bag = own.map((i) => {
    const btn = i.kind === "heal" ? '<span class="muted">ใช้ในศึกมอนสเตอร์ (ปุ่ม 💚)</span>' : i.kind === "scroll" ? '<span class="muted">ใช้ที่ส่วนอัปเกรดด้านล่าง</span>'
      : i.used_today ? '<span class="tag wait">ใช้แล้ววันนี้</span>' : `<button class="btn small gold" onclick="itemUse('${i.id}','${esc(i.name)}')">ใช้</button>`;
    return `<div class="item"><span style="font-size:26px">${esc(i.emoji)}</span><div class="grow"><b>${esc(i.name)}</b> <span class="tag">×${i.qty}</span><div class="muted">${esc(i.descr || "")}</div></div>${btn}</div>`;
  }).join("") || '<p class="muted">กระเป๋าว่าง — ซื้อไอเทมจากร้านด้านล่างได้เลย</p>';
  const shop = items.filter((i) => i.price != null).map((i) => {
    const left = Math.max(0, i.daily_buy - i.bought), ok = left > 0 && D.student.coins >= i.price;
    return `<div class="item"><span style="font-size:26px">${esc(i.emoji)}</span><div class="grow"><b>${esc(i.name)}</b> <span class="tag">${esc(i.rarity)}</span><div class="muted">${esc(i.descr || "")}</div><small class="muted">วันนี้ซื้อได้อีก ${left}/${i.daily_buy}</small></div>
      <button class="btn small ${ok ? "gold" : "ghost"}" ${left > 0 ? "" : "disabled"} onclick="itemBuy('${i.id}','${esc(i.name)}',${i.price})">${i.price} 🪙</button></div>`;
  }).join("");
  const gl = gear.map((g) => {
    const c = g.cost, maxed = g.lvl >= c.max, noStat = !g.main;
    const btn = noStat ? '<span class="muted">ไม่มีสเตตัส</span>' : maxed ? '<span class="tag ok">เลเวลสูงสุด</span>'
      : `<button class="btn small ${sq >= c.scrolls && D.student.coins >= c.coins ? "gold" : "ghost"}" onclick="gearUp('${g.id}','${esc(g.name)}',${c.coins},${c.scrolls})">⬆ ${c.coins}🪙 + 📜${c.scrolls}</button>`;
    return `<div class="item"><span style="font-size:24px">${esc(g.emoji)}</span><div class="grow"><b>${esc(g.name)}</b> <span class="tag">${esc(g.rarity)}</span> <span class="tag ${g.lvl > 1 ? "ok" : ""}">Lv ${g.lvl}/${c.max}</span>${g.equipped ? ' <span class="tag wait">สวมอยู่</span>' : ""}
      <div class="muted">${g.main ? `สเตตัสหลัก ${ST_LBL[g.main]} +${g.stats[g.main]}${g.lvl > 1 ? ` (+${g.lvl - 1} จากเลเวล)` : ""}` : ""}</div></div>${btn}</div>`;
  }).join("") || '<p class="muted">ยังไม่มีของสวมใส่ — ซื้อจากแท็บ 🎨 ตกแต่ง หรือสุ่มกาชา</p>';
  return `<div class="card"><h3>🧪 ไอเทมของฉัน</h3><p class="muted" style="margin:0 0 6px">บัฟมีผลถึงสิ้นวันนี้ · ชนิดละ 1 ครั้ง/วัน · เหรียญของคุณ <b>${D.student.coins}</b> 🪙</p><div>${chips}</div></div>
    <div class="card"><h3>🎒 กระเป๋า</h3>${bag}</div>
    <div class="card"><h3>🛒 ร้านไอเทม</h3>${shop}</div>
    <div class="card"><h3>🛠️ อัปเกรดของสวมใส่</h3><p class="muted" style="margin:0 0 6px">ใช้ม้วนอัปเกรด 📜 (มี ${sq} ม้วน) + เหรียญ · ทุกเลเวล +1 สเตตัสหลักของชิ้นนั้น · เลเวลสูงสุดขึ้นกับความหายาก</p>${gl}</div>`;
}
VIEWS.items = () => { itemsLoad(); return itemsHtml(); };
