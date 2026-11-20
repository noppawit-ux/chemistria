/* โครงโหลดรูป (skeleton) ตอนเน็ตช้า — v2.55
   รูปไอเทม/ตัวละคร/ไอคอนที่ยังโหลดไม่เสร็จจะขึ้นแถบเงาวิบวับแทนช่องว่าง พอโหลดเสร็จก็เอาออกเอง
   ทำงานแบบรวมศูนย์: ดักรูปทุกตัวที่ถูกใส่เข้าหน้า (MutationObserver) จึงไม่ต้องแก้ทุกจุดที่เรนเดอร์รูป
   - <img>: เติมคลาส .isk จนกว่าจะเกิด load/error (รูปที่แคชไว้แล้ว complete ทันที จึงไม่กะพริบ)
   - ไอคอนเคลื่อนไหว .aic (พื้นหลัง CSS): โหลดล่วงหน้าด้วย Image() แล้วเติมคลาส .sk ระหว่างรอ
   ไม่แตะรูปประกอบตัวละคร (หมวก/สัตว์เลี้ยง/ของถือ/ออร่า) เพราะเป็นชั้นซ้อน โครงลอยๆ จะดูแปลก */
(() => {
  const SKIP = ".st-hat,.st-himg,.st-pimg,.st-pet,.st-neck,.st-ring,.st-item,.bt-pet,.pfxg,.eqfx,.lg-cast img,[data-nosk]";
  const doneUrl = new Set(), pend = new Map();
  const bgUrl = (el) => { const m = /url\(["']?([^"')]+)["']?\)/.exec(el.style.backgroundImage || ""); return m ? m[1] : ""; };

  const markImg = (i) => {
    if (i.complete || !i.getAttribute("src") || i.matches(SKIP)) return;
    i.classList.add("isk");
  };

  const loadUrl = (u) => {
    if (pend.has(u)) return pend.get(u);
    const im = new Image();
    const p = new Promise((res) => { im.onload = im.onerror = () => { doneUrl.add(u); res(); }; });
    pend.set(u, p);
    im.src = u;
    if (im.complete) doneUrl.add(u); // อยู่ในแคชหน่วยความจำแล้ว
    return p;
  };

  const markAic = (el) => {
    if (el.dataset.skd) return;
    const u = bgUrl(el);
    if (!u) return;
    el.dataset.skd = "1";
    const p = loadUrl(u);
    if (doneUrl.has(u)) return;
    el.classList.add("sk");
    p.then(() => el.classList.remove("sk"));
  };

  const scan = (root) => {
    if (root.nodeType !== 1) return;
    if (root.tagName === "IMG") markImg(root);
    else if (root.classList && root.classList.contains("aic")) markAic(root);
    root.querySelectorAll && root.querySelectorAll("img,.aic").forEach((n) => (n.tagName === "IMG" ? markImg(n) : markAic(n)));
  };

  const end = (e) => { const t = e.target; if (t && t.tagName === "IMG") t.classList.remove("isk"); };
  document.addEventListener("load", end, true);
  document.addEventListener("error", end, true);

  try {
    new MutationObserver((ms) => {
      for (const m of ms) {
        if (m.type === "attributes") { if (m.target.tagName === "IMG") { m.target.classList.remove("isk"); markImg(m.target); } continue; }
        m.addedNodes.forEach(scan);
      }
    }).observe(document.documentElement, { childList: true, subtree: true, attributes: true, attributeFilter: ["src"] });
  } catch (e) { /* เบราว์เซอร์เก่ามาก: ข้ามโครงโหลด รูปยังแสดงปกติ */ }
  if (document.body) scan(document.body); else document.addEventListener("DOMContentLoaded", () => scan(document.body));
})();
