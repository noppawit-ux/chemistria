/* แท็บ: kbBank */
TAB.kbBank = async function (v) {
  const LV = { hs: "ม.ปลาย", jr: "ม.ต้น (ม.1–3)" }, KD = { quiz: "ควิซ", calc: "คำนวณ", tf: "จริง/เท็จ", odd: "หาตัวแปลกแยก" };
  const h = holder(v, "📚 คลังข้อสอบประลองครูบุ๊ค", "ห้อง ม.1–ม.3 จะได้ชุด “ม.ต้น” ส่วนห้องอื่นได้ชุด “ม.ปลาย” (ชุดม.ปลายรวมกับข้อที่ฝังในเกมอยู่แล้ว) · ควิซ/คำนวณ: ใส่ตัวลวง 3 ข้อ · จริง/เท็จ: ตอบ จริง หรือ เท็จ · หาตัวแปลกแยก: คำตอบ = ตัวที่แปลกแยก, ตัวลวง = สมาชิกกลุ่มเดียวกัน 3 ตัว");
  const st = { lv: "", kd: "" };
  const draw = async () => {
    let q = sb.from("kb_bank").select("*").order("created_at", { ascending: false }).limit(300);
    if (st.lv) q = q.eq("level", st.lv); if (st.kd) q = q.eq("kind", st.kd);
    const rows = must(await q);
    h.innerHTML = `<div class="row"><div style="width:160px"><label>ระดับ</label><select id="kbLv"><option value="">ทั้งหมด</option>${Object.entries(LV).map(([k, l]) => `<option value="${k}" ${st.lv === k ? "selected" : ""}>${l}</option>`).join("")}</select></div>
      <div style="width:160px"><label>ชนิด</label><select id="kbKd"><option value="">ทั้งหมด</option>${Object.entries(KD).map(([k, l]) => `<option value="${k}" ${st.kd === k ? "selected" : ""}>${l}</option>`).join("")}</select></div></div>
      <div class="scroll"><table><thead><tr><th>ระดับ</th><th>ชนิด</th><th>คำถาม</th><th>คำตอบถูก</th><th>ตัวลวง (คั่นด้วย |)</th><th>เฉลย</th><th>เปิด</th><th></th></tr></thead><tbody>
      ${rows.map((r) => `<tr><td>${LV[r.level]}</td><td>${KD[r.kind]}</td><td><input data-id="${r.id}" data-f="question" value="${esc(r.question)}" style="min-width:240px"></td>
        <td><input data-id="${r.id}" data-f="answer" value="${esc(r.answer)}" style="min-width:110px"></td><td><input data-id="${r.id}" data-f="wrong" value="${esc((r.wrong || []).join(" | "))}" style="min-width:200px"></td>
        <td><input data-id="${r.id}" data-f="explain" value="${esc(r.explain || "")}" style="min-width:180px"></td><td><input type="checkbox" data-id="${r.id}" data-f="active" ${r.active ? "checked" : ""}></td>
        <td><button class="btn red small" data-del="${r.id}">ลบ</button></td></tr>`).join("")}</tbody></table></div>
      <p class="muted">แสดงล่าสุด ${rows.length} ข้อ (สูงสุด 300)</p>
      <h4>เพิ่มหลายข้อพร้อมกัน</h4>
      <p class="muted">บรรทัดละข้อ คั่นด้วย | : <code>ระดับ(ต้น/ปลาย) | ชนิด(ควิซ/คำนวณ/จริงเท็จ/แปลกแยก) | คำถาม | คำตอบถูก | ผิด1 | ผิด2 | ผิด3 | เฉลย(ไม่บังคับ)</code><br>จริง/เท็จไม่ต้องมีตัวลวง เช่น <code>ต้น | จริงเท็จ | น้ำเป็นสารประกอบ | จริง</code></p>
      <textarea id="kbBulk" rows="6" placeholder="ต้น | ควิซ | สูตรเคมีของน้ำคือ | H₂O | CO₂ | O₂ | NaCl | น้ำมี H 2 อะตอม O 1 อะตอม"></textarea>
      <button class="btn mint" id="kbAdd" style="margin-top:8px">เพิ่มข้อสอบ</button>`;
    $("#kbLv", h).onchange = (e) => { st.lv = e.target.value; draw(); }; $("#kbKd", h).onchange = (e) => { st.kd = e.target.value; draw(); };
  };
  h.onchange = async (e) => {
    const el = e.target, f = el.dataset.f; if (!f) return;
    const val = f === "active" ? el.checked : f === "wrong" ? el.value.split("|").map((x) => x.trim()).filter(Boolean) : el.value.trim();
    await run(async () => must(await sb.from("kb_bank").update({ [f]: val }).eq("id", el.dataset.id)), "บันทึกแล้ว ✅");
  };
  h.onclick = async (e) => {
    const d = e.target.dataset;
    if (d.del) { if (!confirm("ลบข้อสอบนี้?")) return; await run(async () => must(await sb.from("kb_bank").delete().eq("id", d.del)), "ลบแล้ว"); draw(); }
    else if (e.target.id === "kbAdd") {
      const LM = { "ต้น": "jr", "ม.ต้น": "jr", "ปลาย": "hs", "ม.ปลาย": "hs" }, KM = { "ควิซ": "quiz", "คำนวณ": "calc", "จริงเท็จ": "tf", "จริง/เท็จ": "tf", "แปลกแยก": "odd" }, rows = [];
      for (const line of $("#kbBulk", h).value.split("\n")) {
        const c = line.split("|").map((x) => x.trim()); const level = LM[c[0]], kind = KM[c[1]]; if (!level || !kind || !c[2] || !c[3]) continue;
        const wrong = c.slice(4, 7).filter(Boolean);
        if (kind === "tf") { if (!["จริง", "เท็จ"].includes(c[3])) continue; rows.push({ level, kind, question: c[2], answer: c[3], wrong: [], explain: c[7] || null }); }
        else { if (wrong.length < 3) continue; rows.push({ level, kind, question: c[2], answer: c[3], wrong, explain: c[7] || null }); }
      }
      if (!rows.length) return toast("ไม่พบบรรทัดที่อ่านได้ (ตรวจระดับ/ชนิด และตัวลวงให้ครบ 3 ข้อ)");
      await run(async () => must(await sb.from("kb_bank").insert(rows)), `เพิ่มข้อสอบ ${rows.length} ข้อแล้ว ✅`); draw();
    }
  };
  await draw();
};
