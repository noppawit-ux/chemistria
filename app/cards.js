/* การ์ดสะสม 📖 — สมุดสะสม · เปิดการ์ด (พลิกการ์ด) · สุ่มการ์ดหลังชนะมอนสเตอร์ */
let ALBUM = null, ALBUM_BUSY = false, CARDQ = [];
const RAR_TH = { N: "ธรรมดา", R: "หายาก", SR: "หายากมาก", SSR: "ตำนาน" };
async function cardAlbumLoad() {
  if (ALBUM_BUSY) return; ALBUM_BUSY = true; try { gearLoad(true); } catch (e) {}
  try { ALBUM = await rpc("card_album", { p_token: tk() }); }
  catch (e) { ALBUM = { error: PEEK ? "โหมดแอบดูไม่แสดงสมุดสะสม" : e.message, sets: [] }; }
  ALBUM_BUSY = false;
  if (tab === "cards") { const v = $("#view"); if (v) v.innerHTML = albumHtml(); }
}
const cardFace = (c, own = true) => {
  const sym = own ? esc(c.symbol || c.emoji) : "?", big = own && (c.symbol || "").length <= 2;
  const im = own && c.image ? `<img class="cimg" src="${esc(c.image)}" alt="" loading="lazy" onerror="this.parentNode.classList.remove('has-img');this.remove()">` : "";
  return `<div class="cf rar-${c.rarity} ${own ? "" : "locked"} ${im ? "has-img" : ""}">${im}<div class="ce">${own ? esc(c.emoji) : esc(c.emoji)}</div><div class="cs ${big ? "big" : ""}">${sym}</div>
    <div class="cn">${own ? esc(c.name) : "???"}</div><div class="cr">${c.rarity}</div>${own && typeof GEARS !== "undefined" && GEARS && GEARS.cards && GEARS.cards[c.id] && GEARS.cards[c.id].el ? `<span class="cel">${ELEM[GEARS.cards[c.id].el][0]}</span>` : ""}</div>`;
};
function albumHtml() {
  const A = ALBUM;
  if (!A) return '<div class="card"><p class="muted center" style="padding:30px 0">กำลังโหลดสมุดสะสม…</p></div>';
  if (A.error) return `<div class="card"><p class="muted center" style="padding:30px 0">${esc(A.error)}</p></div>`;
  const tot = A.sets.reduce((a, s) => a + s.cards.length, 0), own = A.sets.reduce((a, s) => a + s.cards.filter((c) => c.own).length, 0);
  return `<div class="card"><h3 style="margin:0 0 4px">📖 สมุดสะสมการ์ด</h3>${gearBox()}
    <div class="row" style="gap:8px;flex-wrap:wrap"><span class="pill">🃏 สะสมแล้ว ${own}/${tot}</span><span class="pill">✨ เศษธาตุ ${A.shards}</span><span class="pill">🐲 ได้จากมอนสเตอร์วันนี้ ${A.used}/${A.cap}</span></div>
    <p class="muted" style="margin:8px 0 0">ชนะมอนสเตอร์มีโอกาสได้การ์ด (จำกัดวันละ ${A.cap} ใบ) · ใบซ้ำเก็บเป็นใบสำรอง ย่อยเป็นเศษธาตุแล้วหลอมการ์ดใหม่ได้ · ซ้ำติดกัน ${A.pity_max - 1} ครั้ง ใบถัดไปได้ใบใหม่แน่นอน</p></div>
    ${forgeHtml()}
    ${A.sets.map((s, si) => { const n = s.cards.filter((c) => c.own).length, pc = s.cards.length ? Math.round((n / s.cards.length) * 100) : 0;
      return `<div class="card cset" style="--sc:${esc(s.color)}"><div class="row"><h3 class="grow" style="margin:0">${esc(s.emoji)} ${esc(s.title)}</h3>
        ${s.claimed ? '<span class="tag ok">✅ ครบชุดแล้ว</span>' : `<span class="muted">${n}/${s.cards.length}</span>`}</div>
        <div class="lvgauge" style="margin:6px 0"><i style="width:${pc}%"></i></div>
        <div class="muted" style="margin-bottom:8px">รางวัลครบชุด: 🪙 ${s.reward.coins}${s.reward.pulls ? ` · 🎟️ ×${s.reward.pulls}` : ""}${s.reward.decor ? ` · 🎨 ${esc(s.reward.decor)}` : ""}</div>
        <div class="cgrid">${s.cards.map((c, ci) => `<button class="cbtn" onclick="cardDetail(${si},${ci})" aria-label="${c.own ? esc(c.name) : "การ์ดที่ยังไม่มี"}">${cardFace(c, c.own)}${c.spare > 0 ? `<span class="cq">+${c.spare}</span>` : ""}</button>`).join("")}</div></div>`; }).join("")}`;
}
function forgeHtml() {
  const A = ALBUM; if (!A || !A.forge || (typeof PEEK !== "undefined" && PEEK)) return "";
  return `<div class="card"><h3 style="margin:0 0 4px">⚗️ โรงหลอมการ์ด</h3>
    <p class="muted" style="margin:0 0 8px">ย่อยการ์ดซ้ำเป็น ✨ เศษธาตุ แล้วหลอมเป็นการ์ดใบใหม่ที่ยังไม่มี (สุ่มในระดับที่เลือก)</p>
    <div class="row" style="gap:8px;flex-wrap:wrap;align-items:center">
      <button class="btn small ${A.spare_total ? "gold" : "ghost"}" ${A.spare_total ? "" : "disabled"} onclick="cardDismantle(null)">♻️ ย่อยการ์ดซ้ำทั้งหมด${A.spare_total ? ` (${A.spare_total} ใบ → +${A.spare_shards} ✨)` : " (ยังไม่มีใบซ้ำ)"}</button></div>
    <div class="cgrid" style="margin-top:10px;grid-template-columns:repeat(2,1fr);gap:8px">${A.forge.map((f) => `<button class="btn ${A.shards >= f.cost && f.left ? "gold" : "ghost"}" ${A.shards >= f.cost && f.left ? "" : "disabled"} onclick="cardForge('${f.rarity}')">
      <b>${f.rarity}</b> ${RAR_TH[f.rarity]}<br><span class="muted">${f.left ? `${f.cost} ✨ · ยังไม่มี ${f.left} ใบ` : "ครบทุกใบแล้ว"}</span></button>`).join("")}</div></div>`;
}
async function cardDismantle(card) {
  if (PEEK) return;
  try { const r = await rpc("card_dismantle", { p_token: tk(), p_card: card, p_n: null }); try { SFX.play("pop"); } catch (e) {}
    toast(`ย่อย ${r.cards} ใบ ได้ +${r.gained} ✨ เศษธาตุ (รวม ${r.shards})`); cardClose(); ALBUM = null; cardAlbumLoad(); } catch (e) { toast(e.message); }
}
async function cardForge(rarity) {
  if (PEEK) return;
  try { const r = await rpc("card_forge", { p_token: tk(), p_rarity: rarity }); r.card.forged = true; CARDQ.push(r.card); ALBUM = null; cardAlbumLoad(); cardQueueShow(); }
  catch (e) { toast(e.message); }
}
function cardDetail(si, ci) {
  if (!ALBUM || !ALBUM.sets[si]) return;
  const s = ALBUM.sets[si], c = s.cards[ci]; document.getElementById("cardov")?.remove();
  const el = document.createElement("div"); el.id = "cardov"; el.className = "cardov";
  el.innerHTML = `<div class="np-bg" onclick="cardClose()"></div><div class="cbox">${cardFace(c, c.own)}
    <div class="cmeta"><b>${c.own ? esc(c.name) : "ยังไม่มีการ์ดใบนี้"}</b><div class="muted">${esc(s.emoji)} ${esc(s.title)} · #${c.no} · ${RAR_TH[c.rarity]}${c.spare > 0 ? ` · ใบสำรอง ${c.spare}` : ""}</div>
    ${c.own ? `<div style="margin:4px 0">${cardFxText(c.id)}</div>${(typeof PEEK !== "undefined" && PEEK) ? "" : `<div class="row" style="gap:4px;justify-content:center">${[1, 2, 3].map((n) => `<button class="btn small ${GEARS && (GEARS.slots || []).some((x) => x.slot === n && x.card === c.id) ? "gold" : "ghost"}" onclick="cardEquip(${n},'${c.id}')">ช่อง ${n}</button>`).join("")}${GEARS && (GEARS.slots || []).some((x) => x.card === c.id) ? `<button class="btn small ghost" onclick="cardEquip(${(GEARS.slots.find((x) => x.card === c.id) || {}).slot || 1},null)">ถอด</button>` : ""}</div>`}${c.spare > 0 && !(typeof PEEK !== "undefined" && PEEK) ? `<button class="btn small ghost" onclick="cardDismantle('${c.id}')">♻️ ย่อยใบสำรอง ${c.spare} ใบ → +${c.spare * ({ N: 1, R: 3, SR: 10, SSR: 30 })[c.rarity]} ✨</button>` : ""}<p class="cfact">💡 ${esc(c.fact)}</p>` : '<p class="muted">เล่นเกมหรือสุ่มกาชาเพื่อสะสมให้ครบ!</p>'}</div><button class="btn ghost" onclick="cardClose()">ปิด</button></div>`;
  document.body.appendChild(el);
}
function cardClose() { document.getElementById("cardov")?.remove(); cardQueueShow(); }
/* เปิดการ์ดที่ได้ (พลิกการ์ด) — เข้าคิวแล้วแสดงทีละใบ */
function cardQueueShow() {
  if (document.getElementById("cardov") || !CARDQ.length) return;
  const c = CARDQ.shift(), el = document.createElement("div"); el.id = "cardov"; el.className = "cardov";
  el.innerHTML = `<div class="np-bg"></div><div class="cbox"><h3 style="margin:0 0 8px">${c.forged ? "⚗️ หลอมสำเร็จ!" : "🃏 ได้การ์ดสะสม!"}</h3>
    <div class="flipc"><div class="flipin"><div class="cback"></div><div class="cfront">${cardFace(c, true)}</div></div></div>
    <div class="cmeta"><b>${esc(c.name)}</b> ${c.is_new ? '<span class="tag ok">🆕 ใหม่!</span>' : `<span class="tag wait">ซ้ำ → เก็บเป็นใบสำรอง (ย่อยเป็น ✨ เศษธาตุได้ในสมุดสะสม)</span>`}
      <div class="muted">${esc(c.set_emoji || "")} ${esc(c.set)} · ${RAR_TH[c.rarity]}</div><p class="cfact">💡 ${esc(c.fact)}</p>
      ${c.set_done ? `<div class="notice gold" style="cursor:default">🎉 สะสมครบชุด “${esc(c.set_done.title)}” รับ 🪙 ${c.set_done.coins}${c.set_done.pulls ? ` + 🎟️ ×${c.set_done.pulls}` : ""}</div>` : ""}</div>
    <button class="btn gold" onclick="cardClose()">${CARDQ.length ? "ใบถัดไป ›" : "เก็บเข้าสมุด"}</button></div>`;
  document.body.appendChild(el);
  setTimeout(() => el.querySelector(".flipin")?.classList.add("flip"), 450);
  setTimeout(() => { try { FX.gacha(".flipc", c.rarity === "N" ? "R" : c.rarity); } catch (e) {} }, 700);
  try { SFX.play(c.rarity === "SSR" ? "levelup" : "blip"); } catch (e) {}
  if (tab === "cards") cardAlbumLoad(); else ALBUM = null;
  if (c.set_done) load();
}
/* หลังจบเกม: ขอสุ่มการ์ด (เซิร์ฟเวอร์ตรวจว่ามีรอบเล่นจริง) */
async function cardAfter(game) {
  if (PEEK) return;
  try { const r = await rpc("card_roll", { p_token: tk(), p_game: game }); if (r && r.drop) { CARDQ.push(r.card); setTimeout(cardQueueShow, 900); } } catch (e) {}
}
