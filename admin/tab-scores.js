/* แท็บ: scores */
TAB.scores = async function (v) {
  const h = holder(v, "🧮 หัวข้อคะแนน", "คะแนนหมวดเป็นผลรวมคะแนนดิบ (ไม่ปรับสัดส่วน) · คะแนนพิเศษรวมกันไม่เกินเพดานที่ตั้งในแท็บ “ตั้งค่า”");
  await crud(h, { table: "score_items", filter: { class_id: S.cls }, order: "created_at", defaults: { category: "pre_mid", max_score: 10 },
    cols: [{ k: "category", label: "หมวด", t: "select", opts: () => Object.entries(CAT_LABEL) }, { k: "title", label: "ชื่อรายการ", w: 200 }, { k: "max_score", label: "เต็ม", t: "number", w: 70 }] });
  const items = must(await sb.from("score_items").select("*").eq("class_id", S.cls).order("created_at"));
  const st = must(await sb.from("students").select("id,no,name").eq("class_id", S.cls).order("no"));
  if (items.length) {
    S.item = items.find((i) => i.id === S.item) ? S.item : items[0].id;
    const sc = must(await sb.from("scores").select("student_id,score").eq("item_id", S.item));
    const cur = Object.fromEntries(sc.map((s) => [s.student_id, s.score]));
    const it = items.find((i) => i.id === S.item);
    const g = holder(v, "✏️ กรอกคะแนน");
    g.innerHTML = `<div class="row"><select id="isel" style="width:auto">${items.map((i) => `<option value="${i.id}" ${i.id === S.item ? "selected" : ""}>${CAT_LABEL[i.category]} · ${esc(i.title)}</option>`).join("")}</select>
      <span class="muted">เต็ม ${it.max_score}</span><button class="btn gold" id="saveSc">บันทึกคะแนน</button></div>
      <div class="scroll"><table><tbody>${st.map((s) => `<tr><td>${s.no}</td><td>${esc(s.name)}</td><td><input type="number" step="any" max="${it.max_score}" id="sv_${s.id}" value="${cur[s.id] ?? ""}" style="width:90px"></td></tr>`).join("")}</tbody></table></div>`;
    $("#isel").onchange = (e) => { S.item = e.target.value; renderTab(); };
    $("#saveSc").onclick = async () => {
      const rows = st.map((s) => ({ item_id: S.item, student_id: s.id, score: $("#sv_" + s.id).value })).filter((r) => r.score !== "").map((r) => ({ ...r, score: Number(r.score) }));
      const bad = rows.find((r) => r.score > Number(it.max_score) || r.score < 0);
      if (bad) return toast("มีคะแนนเกินเต็มหรือติดลบ กรุณาตรวจสอบ");
      await run(async () => must(await sb.from("scores").upsert(rows, { onConflict: "item_id,student_id" })), `บันทึก ${rows.length} รายการแล้ว ✅`);
    };
  }
  const gb = must(await sb.from("v_gradebook").select("*").eq("class_id", S.cls).order("no"));
  const cols = [["pre_mid", "ก่อนกลาง"], ["midterm", "กลางภาค"], ["post_mid", "หลังกลาง"], ["final", "ปลายภาค"], ["behavior", "จิตพิสัย"], ["bonus", "พิเศษ"], ["total", "รวม"], ["total_with_bonus", "รวม+พิเศษ"]];
  const gh = holder(v, "📊 สมุดคะแนนรวม", "กดชื่อคอลัมน์เพื่อคัดลอกเป็นแนวตั้งตามเลขที่ ไปวางใน Google Sheet ได้ทันที");
  gh.innerHTML = `<div class="scroll"><table><thead><tr><th>#</th><th>ชื่อ</th>${cols.map(([k, l]) => `<th><button class="btn small ghost" data-copy="${k}">${l} 📋</button></th>`).join("")}</tr></thead>
    <tbody>${gb.map((r) => `<tr><td>${r.no}</td><td>${esc(r.name)}</td>${cols.map(([k]) => `<td>${r[k]}</td>`).join("")}</tr>`).join("")}</tbody></table></div>`;
  gh.onclick = async (e) => { const k = e.target.dataset.copy; if (!k) return;
    await navigator.clipboard.writeText(gb.map((r) => r[k]).join("\n")); toast("คัดลอกคอลัมน์แล้ว ✅"); };
};
