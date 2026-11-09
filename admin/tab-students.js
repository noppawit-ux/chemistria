/* แท็บ: students */
TAB.students = async function (v) {
  const st = must(await sb.from("students").select("*").eq("class_id", S.cls).order("no"));
  v.innerHTML = `<div class="card"><h3>นักเรียน ${esc(clsName())} (${st.length} คน)</h3>
    <div class="scroll"><table><thead><tr><th>เลขที่</th><th>ชื่อ</th><th>อวาตาร์</th><th>Lv</th><th>EXP</th><th>เหรียญ</th><th></th></tr></thead><tbody>
    ${st.map((s) => `<tr><td>${s.no}</td><td><input value="${esc(s.name)}" data-id="${s.id}" data-k="name" style="min-width:160px"></td>
      <td>${(s.avatar || "").startsWith("data:image/") ? `<img src="${esc(s.avatar)}" alt="" style="width:38px;height:38px;border-radius:50%;object-fit:cover;vertical-align:middle"> <button class="btn small ghost" data-clrph="${s.id}">ลบรูป</button>` : esc(s.avatar)}</td><td>${Math.floor(Math.sqrt(s.exp / 40)) + 1}</td><td>${s.exp}</td><td>${s.coins}</td>
      <td><button class="btn small gold" data-peek="${s.id}">👁 ส่อง</button>
      <button class="btn small ghost" data-adj="${s.id}">± EXP/เหรียญ</button>
      <button class="btn small ghost" data-pin="${s.id}">รีเซ็ต PIN</button>
      <button class="btn small red" data-del="${s.id}">ลบ</button></td></tr>`).join("")}</tbody></table></div></div>
  <div class="card"><h3>เพิ่ม/อัปเดตรายชื่อ (วางจาก Excel ได้)</h3>
    <p class="muted">บรรทัดละคน รูปแบบ: <code>เลขที่ ชื่อ-นามสกุล</code> (คั่นด้วยแท็บ จุลภาค หรือเว้นวรรค) ถ้าเลขที่ซ้ำจะอัปเดตชื่อ</p>
    <textarea id="paste" rows="6" placeholder="1&#9;สมชาย ใจดี&#10;2&#9;สมหญิง รักเรียน"></textarea>
    <div class="row" style="margin-top:8px"><div style="width:140px"><label>PIN เริ่มต้น</label><input id="pin0" value="1234"></div>
    <button class="btn gold" id="addSt">เพิ่มรายชื่อ</button></div></div>`;
  v.onchange = async (e) => { const el = e.target; if (el.dataset.k === "name")
    await run(async () => must(await sb.from("students").update({ name: el.value }).eq("id", el.dataset.id)), "บันทึกแล้ว ✅"); };
  v.onclick = async (e) => {
    const d = e.target.dataset;
    if (d.peek) {
      const w = window.open("", "_blank"); try { const t = await rpc("admin_peek", { p_student: d.peek }); if (w) w.location.href = "index.html#peek=" + t; else toast("เบราว์เซอร์บล็อกหน้าต่างใหม่ กรุณาอนุญาต popup"); } catch (err) { if (w) w.close(); toast(err.message); }
    } else if (d.adj) {
      const x = prompt("เพิ่ม/ลบ EXP (ใส่เลข เช่น 10 หรือ -5)", "0"); if (x === null) return;
      const c = prompt("เพิ่ม/ลบ เหรียญ", "0"); if (c === null) return;
      const r = prompt("เหตุผล", "ครูปรับให้"); if (r === null) return;
      await run(() => rpc("admin_adjust", { p_student: d.adj, p_exp: Number(x) || 0, p_coins: Number(c) || 0, p_reason: r }), "ปรับแล้ว ✅"); renderTab();
    } else if (d.clrph) {
      if (confirm("ลบรูปโปรไฟล์ที่นักเรียนอัปโหลด (กลับเป็นรูปเริ่มต้น)?")) { await run(async () => must(await sb.from("students").update({ avatar: "🧪" }).eq("id", d.clrph)), "ลบรูปแล้ว ✅"); renderTab(); }
    } else if (d.pin) {
      const p = prompt("PIN ใหม่ (ตัวเลข)", "1234"); if (!p) return;
      await run(() => rpc("admin_reset_pin", { p_student: d.pin, p_pin: p }), "รีเซ็ต PIN แล้ว ✅");
    } else if (d.del) {
      if (confirm("ลบนักเรียนคนนี้และข้อมูลทั้งหมดของเขา?")) { await run(async () => must(await sb.from("students").delete().eq("id", d.del)), "ลบแล้ว"); renderTab(); }
    }
  };
  $("#addSt").onclick = async () => {
    const list = $("#paste").value.split("\n").map((l) => l.match(/^\s*(\d+)[\s,.\t]+(.+?)\s*$/)).filter(Boolean).map((m) => ({ no: Number(m[1]), name: m[2] }));
    if (!list.length) return toast("ไม่พบรายชื่อที่อ่านได้");
    const n = await run(() => rpc("admin_add_students", { p_class: S.cls, p_students: list, p_pin: $("#pin0").value || "1234" }), null);
    toast(`เพิ่ม/อัปเดต ${n} คนแล้ว ✅`); renderTab();
  };
};
