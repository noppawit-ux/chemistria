/* แท็บ: settings */
TAB.settings = async function (v) {
  const set = Object.fromEntries(must(await sb.from("app_settings").select("*")).map((s) => [s.key, s.value]));
  const f = [["gacha_cost", "ราคากาชาต่อครั้ง (เหรียญ)"], ["pity_max", "การันตี SR+ ทุกกี่ครั้ง"], ["daily_quest_count", "จำนวนเควสประจำวันที่สุ่มให้"], ["class_change_cost", "ราคาเปลี่ยนคลาส (เหรียญ) — เลือกครั้งแรกฟรี"], ["promo_exp_pct", "โปรเปิดระบบ: โบนัส EXP % (0 = ไม่โบนัส)"], ["promo_coins", "โปร: ของขวัญต้อนรับ เหรียญ"], ["promo_exp", "โปร: ของขวัญต้อนรับ EXP"], ["promo_pulls", "โปร: ของขวัญต้อนรับ ตั๋วกาชาฟรี (ใบ)"]];
  v.innerHTML = `<div class="card"><h3>⚙️ ตั้งค่าระบบ</h3><div class="row">${f.map(([k, l]) => `<div style="width:220px"><label>${l}</label><input type="number" data-set="${k}" value="${esc(set[k] ?? "")}"></div>`).join("")}
    <div style="width:220px"><label>โปรเปิดระบบ</label><select data-set="promo_on"><option value="1" ${set.promo_on === "1" ? "selected" : ""}>เปิด</option><option value="0" ${set.promo_on !== "1" ? "selected" : ""}>ปิด</option></select></div>
    <div style="width:220px"><label>โปรสิ้นสุดวันที่</label><input type="date" data-set="promo_until" value="${esc(set.promo_until ?? "")}"></div>
    <div style="width:220px"><label>ให้นักเรียนเห็นคะแนนตัวเอง</label><select data-set="show_scores"><option value="1" ${set.show_scores !== "0" ? "selected" : ""}>แสดง</option><option value="0" ${set.show_scores === "0" ? "selected" : ""}>ซ่อน</option></select></div></div></div>`;
  v.onchange = async (e) => { const k = e.target.dataset.set; if (!k) return;
    await run(async () => must(await sb.from("app_settings").upsert({ key: k, value: String(e.target.value) })), "บันทึกแล้ว ✅"); };
  const hg = holder(v, "🛠️ ไอดี GM (ปลดล็อคทุกอย่าง)", "บัญชีนักเรียนพิเศษสำหรับทดสอบ/สาธิต: ปลดล็อคไอเทมตกแต่ง ไอเทมกาชา Achievement สิทธิพิเศษ ทั้งหมด · EXP/เหรียญสูงสุด · สเตตัสเต็ม · อยู่ในห้องลับ “GM” แยกจากห้องจริง (ไม่ปรากฏในรายชื่อห้องหน้าล็อกอิน และไม่กระทบอันดับ/บอส/ทีม) · ล็อกอิน: รหัสห้อง GM · เลขที่ 1 · PIN ที่ตั้งไว้");
  hg.innerHTML = `<div class="row"><div style="width:200px"><label>PIN ของไอดี GM (ตัวเลข 4-8 หลัก)</label><input id="gmPin" type="password" inputmode="numeric" maxlength="8" autocomplete="new-password" placeholder="ตั้ง PIN เอง"></div>
    <button class="btn gold" id="gmMake">🛠️ สร้าง / รีเซ็ต PIN + ปลดล็อคทุกอย่าง</button><button class="btn ghost" id="gmSync">🔄 ซิงก์ของใหม่ให้ GM</button></div><p class="muted" id="gmMsg"></p>`;
  $("#gmMake").onclick = () => run(async () => {
    const pin = $("#gmPin").value.trim(); if (!/^[0-9]{4,8}$/.test(pin)) throw new Error("PIN ต้องเป็นตัวเลข 4-8 หลัก");
    must(await sb.rpc("admin_create_gm", { p_pin: pin })); $("#gmPin").value = "";
    $("#gmMsg").textContent = "✅ พร้อมใช้งาน — ล็อกอินที่หน้านักเรียนด้วยรหัสห้อง GM · เลขที่ 1 · PIN ที่ตั้งไว้ (รีโหลดหน้านี้เพื่อให้ห้อง GM ขึ้นในตัวเลือกห้อง)";
  }, "สร้างไอดี GM แล้ว ✅");
  $("#gmSync").onclick = () => run(async () => { const n = must(await sb.rpc("admin_gm_sync")); $("#gmMsg").textContent = n ? "ซิงก์ของใหม่แล้ว ✅" : "ยังไม่มีไอดี GM — กดสร้างก่อน"; }, "ซิงก์แล้ว");
  const h = holder(v, "🏫 ห้องเรียน", "รหัสห้องใช้ตอนนักเรียนล็อกอิน (เช่น M6-2) · เพดานคะแนนพิเศษคือคะแนนพิเศษสูงสุดที่รวมได้");
  await crud(h, { table: "classes", order: "name", noDelete: false, defaults: { bonus_cap: 5, term: "2569/2" },
    cols: [{ k: "code", label: "รหัสห้อง", w: 80 }, { k: "name", label: "ชื่อห้อง", w: 80 }, { k: "subject_code", label: "รหัสวิชา", w: 80 }, { k: "subject_name", label: "ชื่อวิชา", w: 160 },
      { k: "term", label: "ภาคเรียน", w: 80 }, { k: "bonus_cap", label: "เพดานคะแนนพิเศษ", t: "number", w: 80 }] });
  const hr = holder(v, "🎖️ แรงค์ (สไตล์ LoL)", "แต่ละแรงค์เริ่มที่ EXP ขั้นต่ำที่ตั้งไว้ · จำนวนดิวิชัน 4 = IV→I, 1 = ไม่มีดิวิชัน (เช่น Master) · แรงค์สุดท้ายคือสูงสุด");
  await crud(hr, { table: "ch_ranks", order: "sort", defaults: { divisions: 4, sort: 99, min_exp: 0 },
    cols: [{ k: "sort", label: "ลำดับ", t: "number", w: 60 }, { k: "key", label: "รหัส", w: 100 }, { k: "name", label: "ชื่อแรงค์", w: 120 },
      { k: "min_exp", label: "EXP เริ่ม", t: "number", w: 80 }, { k: "divisions", label: "ดิวิชัน", t: "number", w: 70 }, { k: "image", label: "รูป (assets/ranks/…png)", w: 200 }] });
  const hc = holder(v, "⚔️ คลาสตัวละคร", "ผลความสามารถ 4 คลาสผูกกับ “รหัส” (alchemist, scientist, guardian, seeker) — แก้ชื่อ/คำอธิบาย/รูปได้ แต่ไม่ควรเปลี่ยนรหัส");
  await crud(hc, { table: "char_classes", order: "sort", defaults: { sort: 99, active: true },
    cols: [{ k: "sort", label: "ลำดับ", t: "number", w: 60 }, { k: "key", label: "รหัส", w: 90 }, { k: "emoji", label: "อีโมจิ", w: 50 }, { k: "name", label: "ชื่อคลาส", w: 130 },
      { k: "description", label: "คำโปรย", w: 160 }, { k: "ability", label: "ความสามารถ (ข้อความอธิบาย)", w: 240 }, { k: "image", label: "รูป", w: 180 }, { k: "active", label: "เปิด", t: "bool" }] });
  const note = document.createElement("p"); note.className = "muted"; note.textContent = "หลังเพิ่ม/ลบห้อง ให้โหลดหน้าใหม่เพื่ออัปเดตรายการห้องด้านบน"; v.appendChild(note);
};
