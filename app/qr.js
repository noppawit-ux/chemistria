/* QR ของฉัน — โชว์ให้ครูสแกนตรวจงาน (รหัสเปลี่ยนทุก 30 วินาที แคปภาพส่งต่อไม่ได้) */
let QRT = null;
function loadLib(src) { return new Promise((ok, no) => { if (document.querySelector(`script[data-lib="${src}"]`)) return ok(); const s = document.createElement("script"); s.src = src; s.dataset.lib = src; s.onload = ok; s.onerror = () => no(new Error("โหลดไลบรารี QR ไม่ได้")); document.head.appendChild(s); }); }
async function qrOpen() {
  if (PEEK) return toast("👁 โหมดแอบดูใช้ QR ไม่ได้");
  document.getElementById("qrov")?.remove();
  const ov = document.createElement("div"); ov.id = "qrov"; ov.className = "giftov"; ov.setAttribute("role", "dialog"); ov.setAttribute("aria-modal", "true");
  ov.innerHTML = `<div class="giftbox" style="background:#fff;color:#111;border-color:#7c4dff"><h2 style="margin:0 0 4px;color:#111">📱 QR ของฉัน</h2><div class="muted" style="color:#555">${esc(D?.student?.name || "")}</div>
    <div id="qrimg" style="margin:10px auto;width:min(80vw,300px);min-height:200px;display:grid;place-items:center">กำลังสร้าง…</div>
    <div id="qrnote" style="font-size:.85em;color:#555">แสดงให้ครูสแกน · รหัสเปลี่ยนอัตโนมัติ — แคปภาพไปส่งต่อไม่ได้</div>
    <button class="btn ghost" style="margin-top:10px" onclick="qrClose()">ปิด</button></div>`;
  document.body.appendChild(ov);
  const draw = async () => {
    try {
      await loadLib("vendor/qrcode.js?v=1.84");
      const r = await rpc("my_qr", { p_token: tk() }); const q = qrcode(0, "M"); q.addData(r.code); q.make();
      const el = document.getElementById("qrimg"); if (!el) return; el.innerHTML = q.createSvgTag({ cellSize: 6, margin: 2, scalable: true }); const sv = el.querySelector("svg"); if (sv) { sv.style.width = "100%"; sv.style.height = "auto"; }
      QRT = setTimeout(draw, Math.max(5, Math.min(25, r.ttl - 3)) * 1000);
    } catch (e) { const el = document.getElementById("qrimg"); if (el) el.textContent = "สร้าง QR ไม่ได้: " + e.message; QRT = setTimeout(draw, 8000); }
  };
  draw();
}
function qrClose() { clearTimeout(QRT); document.getElementById("qrov")?.remove(); }
