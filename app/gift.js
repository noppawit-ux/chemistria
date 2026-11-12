/* ของขวัญจากครู — ป๊อปอัปครั้งเดียวต่อชุดของขวัญ (ส่งโดยแท็บ 🎁 ของขวัญในแอดมิน) */
let GIFTS = [];
function giftShow() {
  if (PEEK || !GIFTS.length || document.getElementById("giftov") || document.getElementById("patchov")) return;
  const chips = (g) => [g.exp ? `⭐ +${g.exp} EXP` : "", g.coins ? `🪙 +${g.coins} เหรียญ` : "", g.pulls ? `🎟️ ตั๋วสุ่มฟรี ×${g.pulls}` : "",
    g.decor ? `${esc(g.decor_emoji || "🎨")} ${esc(g.decor)}` : "", g.privilege ? `🎫 สิทธิ์ “${esc(g.privilege)}”` : "", g.card ? `🃏 ${esc(g.card)}${g.card_n > 1 ? " ×" + g.card_n : ""}` : ""].filter(Boolean);
  const ov = document.createElement("div"); ov.id = "giftov"; ov.className = "giftov"; ov.setAttribute("role", "dialog"); ov.setAttribute("aria-modal", "true");
  ov.innerHTML = `<div class="giftbox"><div class="giftbig">🎁</div><h2>ครูส่งของขวัญให้!</h2>
    ${GIFTS.map((g) => `<div class="giftitem">${g.message ? `<p class="giftmsg">“${esc(g.message)}”</p>` : ""}<div class="giftchips">${chips(g).map((c) => `<span class="ghchip">${c}</span>`).join("")}</div></div>`).join("")}
    <button class="btn gold" onclick="giftClose()">รับของขวัญ 🎉</button></div>`;
  document.body.appendChild(ov); try { FX.victory(); } catch (e) {} try { SFX.play("levelup"); } catch (e) {}
}
async function giftClose() {
  document.getElementById("giftov")?.remove(); GIFTS = [];
  try { await rpc("gift_ack", { p_token: tk() }); } catch (e) {}
  load();
}
