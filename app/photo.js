/* รูปโปรไฟล์ — ส่วนหนึ่งของหน้านักเรียน (index.html) โหลดต่อกันตามลำดับใน index.html */
/* ---------------- รูปโปรไฟล์ของนักเรียน: เลือกรูป → ซูม/เลื่อนครอป → บันทึก (เก็บ JPEG 160px เล็กๆ) ---------------- */
const CR = { img: null, z: 1, x: 0, y: 0, base: 1, drag: null }, CRV = 260;
function photoOpen(input) {
  const f = input.files && input.files[0]; input.value = ""; if (!f) return;
  if (!/^image\//.test(f.type)) return toast("เลือกไฟล์รูปภาพเท่านั้น");
  const url = URL.createObjectURL(f), im = new Image();
  im.onload = () => { CR.img = im; CR.base = CRV / Math.min(im.width, im.height); CR.z = 1; CR.x = CR.y = 0; URL.revokeObjectURL(url); cropShow(); };
  im.onerror = () => toast("อ่านรูปไม่สำเร็จ"); im.src = url;
}
function cropClamp() {
  const s = CR.base * CR.z, mx = Math.max(0, (CR.img.width * s - CRV) / 2), my = Math.max(0, (CR.img.height * s - CRV) / 2);
  CR.x = Math.max(-mx, Math.min(mx, CR.x)); CR.y = Math.max(-my, Math.min(my, CR.y));
}
function cropDraw(cv, size) {
  const k = size / CRV, s = CR.base * CR.z * k, w = CR.img.width * s, h = CR.img.height * s, c = cv.getContext("2d");
  c.fillStyle = "#fff"; c.fillRect(0, 0, size, size); c.imageSmoothingQuality = "high";
  c.drawImage(CR.img, size / 2 - w / 2 + CR.x * k, size / 2 - h / 2 + CR.y * k, w, h);
}
function cropShow() {
  let ov = document.getElementById("cropov"); if (!ov) { ov = document.createElement("div"); ov.id = "cropov"; ov.className = "overlay"; document.body.appendChild(ov); }
  ov.innerHTML = `<div class="card cropbox"><h3 style="margin:0 0 6px">📷 ปรับรูปโปรไฟล์</h3><p class="muted" style="margin:0 0 8px">ลากเพื่อเลื่อนรูป · เลื่อนแถบหรือหมุนเมาส์เพื่อซูม</p>
    <div class="crwrap"><canvas id="crcv" width="${CRV}" height="${CRV}"></canvas><div class="crmask"></div></div>
    <div class="row" style="justify-content:center;margin:10px 0"><span>🔍−</span><input type="range" id="crz" min="1" max="4" step="0.01" value="1" style="width:180px"><span>+</span></div>
    <div class="row" style="justify-content:center"><button class="btn gold" onclick="cropSave()">💾 บันทึกรูปนี้</button><button class="btn ghost" onclick="cropClose()">ยกเลิก</button></div></div>`;
  ov.classList.add("on");
  const cv = document.getElementById("crcv"), redraw = () => { cropClamp(); cropDraw(cv, CRV); };
  redraw();
  document.getElementById("crz").oninput = (e) => { CR.z = Number(e.target.value); redraw(); };
  cv.addEventListener("wheel", (e) => { e.preventDefault(); CR.z = Math.max(1, Math.min(4, CR.z * (e.deltaY < 0 ? 1.08 : 0.93))); document.getElementById("crz").value = CR.z; redraw(); }, { passive: false });
  cv.onpointerdown = (e) => { CR.drag = [e.clientX, e.clientY, CR.x, CR.y]; cv.setPointerCapture(e.pointerId); };
  cv.onpointermove = (e) => { if (!CR.drag) return; CR.x = CR.drag[2] + e.clientX - CR.drag[0]; CR.y = CR.drag[3] + e.clientY - CR.drag[1]; redraw(); };
  cv.onpointerup = cv.onpointercancel = () => { CR.drag = null; };
}
const cropClose = () => { document.getElementById("cropov")?.classList.remove("on"); CR.img = null; };
async function cropSave() {
  try {
    const out = document.createElement("canvas"); out.width = out.height = 160; cropDraw(out, 160);
    let q = 0.85, data = out.toDataURL("image/jpeg", q);
    while (data.length > 26000 && q > 0.35) { q -= 0.1; data = out.toDataURL("image/jpeg", q); }
    if (data.length > 29000) throw new Error("รูปใหญ่เกินไป ลองรูปอื่น");
    await rpc("set_photo", { p_token: tk(), p_data: data });
    cropClose(); await load(); toast("เปลี่ยนรูปโปรไฟล์แล้ว ✨");
  } catch (e) { toast(e.message); }
}
const photoReset = () => act(() => rpc("set_photo", { p_token: tk(), p_data: null }), "กลับไปใช้รูปเดิมแล้ว");
const setAv = (id) => act(() => rpc("set_avatar", { p_token: tk(), p_item: id }), "เปลี่ยนอวาตาร์แล้ว");

async function pull(n) {
  try {
    const r = await rpc("gacha_pull", { p_token: tk(), p_n: n });
    const ov = $("#overlay");
    ov.innerHTML = `<h2>✨ ผลการสุ่ม</h2><div id="cards">${r.items.map((it, i) => `
      <div class="gcard rar-${it.rarity}" id="gc${i}"><div class="in"><div class="b"></div>
      <div class="f"><div><div class="e">${itemImg(it.image, it.emoji, "gi")}</div><div class="rar">${it.rarity}</div><div class="n">${esc(it.name)}</div>${it.kind === "decor" ? `<div class="n muted">${it.dup_refund ? "ซ้ำ! คืน +" + it.dup_refund + "🪙" : "🎨 ไอเทมตกแต่งใหม่!"}</div>` : ""}</div></div></div></div>`).join("")}</div>
      <p><button class="btn gold" onclick="closeOv()">รับของ</button></p>`;
    ov.classList.add("on");
    r.items.forEach((it, i) => { setTimeout(() => $("#gc" + i)?.classList.add("flip"), 350 + i * 330); setTimeout(() => FX.gacha("#gc" + i, it.rarity), 600 + i * 330); });
    await load();
  } catch (e) { toast(e.message); }
}
function closeOv() { $("#overlay").classList.remove("on"); }
