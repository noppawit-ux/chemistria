/* อีเว้นท์เช็คอินรับของรางวัล — ครูเปิดจากแท็บ 🎟️ เช็คอิน ในแอดมิน · นักเรียนกดรับได้คนละครั้งต่ออีเว้นท์ */
let CHK = [], CHKBUSY = false;
function chkChips(g) {
  return [g.exp ? `⭐ +${g.exp} EXP` : "", g.coins ? `🪙 +${g.coins} เหรียญ` : "", g.pulls ? `🎟️ ตั๋วสุ่มฟรี ×${g.pulls}` : "",
    g.decor ? `${esc(g.decor_emoji || "🎨")} ${esc(g.decor)}` : "", g.card ? `${esc(g.card_emoji || "🃏")} การ์ด ${esc(g.card)}` : ""].filter(Boolean);
}
function chkLeft(iso) {
  const m = Math.max(0, Math.round((new Date(iso) - Date.now()) / 60000));
  return m >= 1440 ? `อีก ${Math.floor(m / 1440)} วัน` : m >= 60 ? `อีก ${Math.floor(m / 60)} ชม.` : `อีก ${m} นาที`;
}
function checkinHtml() {
  if (typeof PEEK !== "undefined" && PEEK) return "";
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
