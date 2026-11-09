/* ศูนย์แจ้งเตือน — ส่วนหนึ่งของหน้านักเรียน (index.html) โหลดต่อกันตามลำดับใน index.html */
/* ---------------- ศูนย์แจ้งเตือน (🔔) ---------------- */
function notifs() {
  const L = [];
  if ((X.free_pulls || 0) > 0) L.push({ k: "free" + X.free_pulls, ic: "🎟️", t: `มีตั๋วสุ่มกาชาฟรี ${X.free_pulls} ใบ`, d: "กดเพื่อไปสุ่มเลย", go: "gacha" });
  (D.assignments || []).filter((a) => !a.status && a.due_date).forEach((a) => {
    const n = dayDiff(a.due_date); if (n > 3) return;
    L.push({ k: "hw" + a.id + n, ic: n < 0 ? "🚨" : "⏰", t: `${a.title}`, d: n < 0 ? `เลยกำหนด ${-n} วัน — ส่งช้ายังได้ EXP ครึ่งหนึ่ง` : n === 0 ? "ส่งวันนี้!" : `อีก ${n} วันครบกำหนด`, go: "att" });
  });
  const b = X.boss;
  if (b && b.can_claim) L.push({ k: "bossc" + b.id, ic: "🎁", t: `ปราบ ${b.name} สำเร็จ!`, d: "กดรับรางวัลได้ที่หน้าเควส", go: "quest" });
  else if (b && !b.defeated && !b.ended) L.push({ k: "boss" + b.id, ic: "👹", t: `บอสประจำสัปดาห์: ${b.name}`, d: `HP เหลือ ${b.hp}/${b.max_hp} — ทำเควสเพื่อโจมตี`, go: "quest" });
  (D.quests || []).filter((q) => q.status === "pending").forEach((q) => L.push({ k: "qp" + q.id, ic: "🕒", t: `เควส “${q.title}” รอครูตรวจ`, d: "ครูจะอนุมัติเร็วๆ นี้", go: "quest" }));
  (D.privileges || []).filter((p) => p.status === "requested").forEach((p) => L.push({ k: "pv" + p.id, ic: "🎟️", t: `สิทธิ์ “${p.name}” รอครูอนุมัติ`, d: "", go: "bag" }));
  if (B.unread > 0) L.push({ k: "bd" + B.unread, ic: "📢", t: `มีโพสต์/ประกาศใหม่ในบอร์ด ${B.unread} รายการ`, d: "กดเพื่ออ่าน", go: "board" });
  return L;
}
const SEEN_KEY = "kb_notif_seen";
const seenSet = () => { try { return JSON.parse(localStorage.getItem(SEEN_KEY) || "[]"); } catch (e) { return []; } };
const notifCount = () => { const sn = seenSet(); return notifs().filter((n) => !sn.includes(n.k)).length; };
function openNotif() {
  const L = notifs(), sn = seenSet();
  $("#notifp")?.remove();
  const el = document.createElement("div"); el.id = "notifp"; el.className = "notifp";
  el.innerHTML = `<div class="np-bg" onclick="closeNotif()"></div><div class="np-box"><div class="row"><h3 class="grow" style="margin:0">🔔 การแจ้งเตือน</h3>
    <button class="btn ghost small" onclick="closeNotif()">✕</button></div>
    ${L.length ? L.map((n, i) => `<div class="item np-i ${sn.includes(n.k) ? "" : "new"}" onclick="goNotif(${i})"><span style="font-size:24px">${n.ic}</span>
      <div class="grow"><b>${esc(n.t)}</b><div class="muted">${esc(n.d)}</div></div><span class="muted">›</span></div>`).join("") : '<p class="muted center" style="padding:18px 0">ไม่มีการแจ้งเตือนใหม่ 🎉</p>'}
    ${L.length ? '<button class="btn small ghost" style="margin-top:8px" onclick="readAllNotif()">ทำเครื่องหมายว่าอ่านทั้งหมด</button>' : ""}</div>`;
  document.body.appendChild(el);
  window._np = L;
}
function closeNotif() { $("#notifp")?.remove(); }
function readAllNotif() { try { localStorage.setItem(SEEN_KEY, JSON.stringify(notifs().map((n) => n.k))); } catch (e) {} closeNotif(); render(); }
function goNotif(i) {
  const n = (window._np || [])[i]; if (!n) return;
  try { const sn = seenSet(); if (!sn.includes(n.k)) { sn.push(n.k); localStorage.setItem(SEEN_KEY, JSON.stringify(sn.slice(-80))); } } catch (e) {}
  go(n.go);
}
