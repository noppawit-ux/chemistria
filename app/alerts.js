/* แจ้งเตือนหน้าหลัก (โปรเปิดระบบ · ตั๋วกาชา · งานค้าง · กิลด์ · ทีม) → ป๊อปอัปด้านบนของตัวละคร เด้งอัตโนมัติ 1 ครั้งต่อการเข้าสู่ระบบ */
const alertsHtml = () => promoHtml() + remindHtml() + teamChip() + guildChip();
function alertsCount() { const d = document.createElement("div"); d.innerHTML = alertsHtml(); return d.children.length; }
function alertsChip() { const n = alertsCount(); return n ? `<div class="notice" onclick="alertsShow()">🔔 แจ้งเตือนวันนี้ ${n} รายการ — กดดู</div>` : ""; }
function alertsShow() {
  if (document.getElementById("alertpop")) return;
  const el = document.createElement("div"); el.id = "alertpop"; el.className = "alertpop"; el.setAttribute("role", "dialog");
  el.innerHTML = `<div class="np-bg" onclick="alertsClose()"></div><div class="np-box ap-box"><div class="row"><h3 class="grow" style="margin:0">📌 แจ้งเตือนวันนี้</h3><button class="btn ghost small" onclick="alertsClose()">✕</button></div>
    <div class="ap-body" onclick="if(event.target.closest('.notice,[onclick*=&quot;go(&quot;]'))alertsClose()">${alertsHtml()}</div>
    <button class="btn small ghost" style="margin-top:6px" onclick="alertsClose()">ปิด</button></div>`;
  document.body.appendChild(el);
}
function alertsClose() { document.getElementById("alertpop")?.remove(); }
function alertsAuto() {
  const el = document.getElementById("alertpop");
  if (el) { if (tab !== "home") return el.remove(); const b = el.querySelector(".ap-body"); if (b) b.innerHTML = alertsHtml(); return; }
  if (PEEK || tab !== "home" || document.getElementById("patchov") || document.getElementById("giftov") || !D) return;
  try { if (sessionStorage.getItem("kb_alert_done") === "1") return; sessionStorage.setItem("kb_alert_done", "1"); } catch (e) {}
  if (alertsCount()) alertsShow();
}
