/* อีเว้นท์เช็คอินรับของรางวัล — ครูเปิดจากแท็บ 🎟️ เช็คอิน ในแอดมิน · นักเรียนกดรับได้คนละครั้งต่ออีเว้นท์ */
let CHK = [], CAMP = [], CHKBUSY = false;
function chkChips(g) {
  return [g.exp ? `⭐ +${g.exp} EXP` : "", g.coins ? `🪙 +${g.coins} เหรียญ` : "", g.pulls ? `🎟️ ตั๋วสุ่มฟรี ×${g.pulls}` : "",
    g.decor ? `${esc(g.decor_emoji || "🎨")} ${esc(g.decor)}` : "", g.card ? `${esc(g.card_emoji || "🃏")} การ์ด ${esc(g.card)}` : ""].filter(Boolean);
}
function chkLeft(iso) {
  const m = Math.max(0, Math.round((new Date(iso) - Date.now()) / 60000));
  return m >= 1440 ? `อีก ${Math.floor(m / 1440)} วัน` : m >= 60 ? `อีก ${Math.floor(m / 60)} ชม.` : `อีก ${m} นาที`;
}
function campPrize(m) {
  const t = chkChips({ exp: m.exp, coins: m.coins, pulls: m.pulls, decor: m.decor, card: m.card });
  if (m.set && m.set.length) t.push(`👑 ชุดลิมิเต็ด ${m.set.map((x) => (x.image ? `<img src="${esc(x.image)}" alt="" style="width:18px;height:18px;image-rendering:pixelated;vertical-align:-4px">` : esc(x.emoji || ""))).join("")}`);
  return t;
}
function campHtml() {
  return (CAMP || []).map((c) => {
    const pct = Math.min(100, Math.round((c.done / Math.max(1, c.miles[c.miles.length - 1].need)) * 100));
    return `<div class="card chkcard"><div class="row" style="align-items:center;gap:10px;flex-wrap:wrap"><div class="chkbig">📅</div>
      <div class="grow"><b>${esc(c.title)}</b> <small class="muted">· เช็คอินแล้ว ${c.done}/${c.days_total} วัน · เหลือ ${c.days_left + 1} วัน</small>${c.message ? `<div class="muted" style="font-size:.82rem">${esc(c.message)}</div>` : ""}</div>
      ${c.today ? `<span class="pill ok">✔ เช็คอินวันนี้แล้ว</span>` : `<button class="btn gold" onclick="campGo('${c.id}')">เช็คอินวันนี้</button>`}</div>
      <div class="chkbar"><i style="width:${pct}%"></i></div>
      <div class="chkmiles">${c.miles.map((m) => `<div class="chkm ${m.got ? "got" : c.done >= m.need ? "got" : ""}"><b>${m.got ? "✅" : "🎁"} ${m.need} วัน</b><div class="giftchips">${campPrize(m).map((x) => `<span class="ghchip">${x}</span>`).join("")}</div></div>`).join("")}</div></div>`;
  }).join("");
}
async function campGo(id) {
  if (CHKBUSY) return; CHKBUSY = true;
  try {
    const r = await rpc("camp_checkin", { p_token: tk(), p_camp: id });
    const rw = r.rewards || [];
    const ov = document.createElement("div"); ov.id = "giftov"; ov.className = "giftov"; ov.setAttribute("role", "dialog"); ov.setAttribute("aria-modal", "true");
    ov.innerHTML = `<div class="giftbox"><div class="giftbig">📅</div><h2>เช็คอินวันที่ ${r.done}!</h2><p class="giftmsg">${esc(r.title)}</p>
      ${rw.length ? rw.map((m) => `<div class="giftitem"><b>🎉 ครบ ${m.need} วัน!</b><div class="giftchips">${campPrize({ exp: m.exp, coins: m.coins, pulls: m.pulls, decor: m.decor, card: m.card, set: (m.set || []).map((x) => ({ emoji: x.emoji })) }).map((c) => `<span class="ghchip">${c}</span>`).join("")}</div>${m.set ? `<div class="muted" style="font-size:.82rem">ได้ชุด: ${m.set.map((x) => esc(x.name)).join(" · ")}</div>` : ""}</div>`).join("") : `<p class="muted">สะสมต่อเนื่องไปเรื่อยๆ รางวัลใหญ่รออยู่!</p>`}
      <button class="btn gold" onclick="document.getElementById('giftov')?.remove();load()">ไปต่อ 🎉</button></div>`;
    document.body.appendChild(ov); try { FX.victory(); } catch (e) {} try { SFX.play(rw.length ? "levelup" : "coin"); } catch (e) {}
  } catch (e) { toast(e.message || "เช็คอินไม่สำเร็จ"); load(); }
  CHKBUSY = false;
}
function checkinHtml() {
  if (typeof PEEK !== "undefined" && PEEK) return "";
  return campHtml() + checkinOneHtml();
}
function checkinOneHtml() {
  const open = (CHK || []).filter((e) => !e.claimed);
  if (!open.length) return "";
  return open.map((e) => `<div class="card chkcard"><div class="row" style="align-items:center;gap:10px;flex-wrap:wrap"><div class="chkbig">🎟️</div>
    <div class="grow"><b>${esc(e.title)}</b> <small class="muted">· ${chkLeft(e.ends_at)}</small>${e.message ? `<div class="muted" style="font-size:.82rem">${esc(e.message)}</div>` : ""}
    <div class="giftchips" style="margin-top:4px">${chkChips(e).map((c) => `<span class="ghchip">${c}</span>`).join("")}</div></div>
    <button class="btn gold" onclick="chkClaim('${e.id}')">เช็คอินรับรางวัล</button></div></div>`).join("");
}
async function chkLoad() {
  if (typeof PEEK !== "undefined" && PEEK) return;
  try { CHK = (await rpc("checkin_list", { p_token: tk() })) || []; } catch (e) { CHK = []; }
  try { CAMP = (await rpc("camp_status", { p_token: tk() })) || []; } catch (e) { CAMP = []; }
}
async function chkClaim(id) {
  if (CHKBUSY) return; CHKBUSY = true;
  try {
    const r = await rpc("checkin_claim", { p_token: tk(), p_event: id });
    const chips = chkChips({ exp: r.exp, coins: r.coins, pulls: r.pulls, decor: r.decor, card: r.card });
    const ov = document.createElement("div"); ov.id = "giftov"; ov.className = "giftov"; ov.setAttribute("role", "dialog"); ov.setAttribute("aria-modal", "true");
    ov.innerHTML = `<div class="giftbox"><div class="giftbig">🎟️</div><h2>เช็คอินสำเร็จ!</h2><p class="giftmsg">${esc(r.title)}</p>
      <div class="giftitem"><div class="giftchips">${chips.map((c) => `<span class="ghchip">${c}</span>`).join("")}</div></div>
      <button class="btn gold" onclick="document.getElementById('giftov')?.remove();load()">รับรางวัล 🎉</button></div>`;
    document.body.appendChild(ov); try { FX.victory(); } catch (e) {} try { SFX.play("levelup"); } catch (e) {}
    CHK = CHK.map((x) => (x.id === id ? { ...x, claimed: true } : x));
  } catch (e) { toast(e.message || "รับไม่สำเร็จ"); load(); }
  CHKBUSY = false;
}
