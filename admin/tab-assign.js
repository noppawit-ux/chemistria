/* แท็บ: assign */
TAB.assign = async function (v) {
  const h = holder(v, "📝 งานที่มอบหมาย", "วิธีส่ง: “นักเรียนกดส่ง/ส่งรูป” = นักเรียนส่งเองจากหน้าเว็บและได้ EXP ทันที (ครูส่งคืนได้ถ้ารูปไม่ผ่าน) · เลือกงานด้านล่างเพื่อบันทึกการส่ง · EXP/เหรียญจะให้อัตโนมัติเมื่อบันทึกสถานะ “ส่งแล้ว” (ส่งช้าได้ครึ่งหนึ่ง)");
  await crud(h, { table: "ch_assignments", filter: { class_id: S.cls }, order: "due_date", defaults: { max_score: 10, exp_reward: 20, coin_reward: 5 },
    cols: [{ k: "title", label: "ชื่องาน", w: 180 }, { k: "due_date", label: "กำหนดส่ง", t: "date" }, { k: "max_score", label: "เต็ม", t: "number", w: 60 },
      { k: "exp_reward", label: "EXP", t: "number", w: 60 }, { k: "coin_reward", label: "เหรียญ", t: "number", w: 60 },
      { k: "submit_mode", label: "วิธีส่ง", t: "select", opts: () => [["teacher", "ครูบันทึกเอง"], ["online", "นักเรียนกดส่งออนไลน์"], ["photo", "นักเรียนส่งรูป"]] }, { k: "description", label: "รายละเอียด", w: 160 }] });
  const as = must(await sb.from("ch_assignments").select("id,title").eq("class_id", S.cls).order("due_date"));
  if (!as.length) return;
  S.asg = as.find((a) => a.id === S.asg) ? S.asg : as[0].id;
  const [st, sub] = await Promise.all([
    sb.from("students").select("id,no,name").eq("class_id", S.cls).order("no").then(must),
    sb.from("ch_submissions").select("id,student_id,status,score,image_path,via,note").eq("assignment_id", S.asg).then(must),
  ]);
  const cur = Object.fromEntries(sub.map((s) => [s.student_id, s]));
  const g = holder(v, "✅ บันทึกการส่งงาน");
  g.innerHTML = `<div class="row"><select id="asel" style="width:auto">${as.map((a) => `<option value="${a.id}" ${a.id === S.asg ? "selected" : ""}>${esc(a.title)}</option>`).join("")}</select>
    <button class="btn ghost small" id="allS">ทุกคนส่งแล้ว</button><button class="btn gold" id="saveS">บันทึก</button></div>
    <div class="scroll"><table><thead><tr><th>#</th><th>ชื่อ</th><th>สถานะ</th><th>คะแนน</th><th>ส่งเอง/รูป</th></tr></thead><tbody>
    ${st.map((s) => `<tr><td>${s.no}</td><td>${esc(s.name)}</td><td class="seg">
      ${[["submitted", "ส่ง"], ["late", "ช้า"], ["missing", "ไม่ส่ง"]].map(([k, l]) => `<label><input type="radio" name="s_${s.id}" value="${k}" ${cur[s.id]?.status === k ? "checked" : ""}>${l}</label>`).join("")}</td>
      <td><input type="number" step="any" id="sc_${s.id}" value="${cur[s.id]?.score ?? ""}" style="width:80px"></td>
      <td>${cur[s.id]?.via === "student" ? '<span class="tag ok">ส่งเอง</span> ' : ""}${cur[s.id]?.image_path ? `<button class="btn small ghost" data-img="${esc(cur[s.id].image_path)}">🖼️ ดูรูป</button> ` : ""}${cur[s.id]?.via === "student" && ["submitted", "late"].includes(cur[s.id]?.status) ? `<button class="btn small red" data-ret="${cur[s.id].id}">↩️ ส่งคืน</button>` : ""}${cur[s.id]?.note ? `<div class="muted">${esc(cur[s.id].note)}</div>` : ""}</td></tr>`).join("")}</tbody></table></div>`;
  g.onclick = async (e) => {
    const d = e.target.dataset;
    if (d.img) {
      const { data, error } = await sb.storage.from("submissions").createSignedUrl(d.img, 3600);
      if (error) return toast("เปิดรูปไม่ได้: " + error.message);
      const o = document.createElement("div"); o.className = "overlay on"; o.style.cursor = "zoom-out";
      o.innerHTML = `<img src="${data.signedUrl}" style="max-width:96vw;max-height:92vh;border-radius:12px">`; o.onclick = () => o.remove(); document.body.appendChild(o);
    } else if (d.ret) {
      const note = prompt("เหตุผลที่ส่งคืน (นักเรียนจะเห็น และส่งใหม่ได้ · ระบบหัก EXP/เหรียญที่ให้ไปคืน)", "รูปไม่ชัด / งานไม่ครบ"); if (note === null) return;
      await run(() => rpc("admin_return_submission", { p_sub: d.ret, p_note: note }), "ส่งคืนแล้ว ↩️"); renderTab();
    }
  };
  $("#asel").onchange = (e) => { S.asg = e.target.value; renderTab(); };
  $("#allS").onclick = () => $$('input[value="submitted"]', g).forEach((r) => (r.checked = true));
  $("#saveS").onclick = async () => {
    const recs = st.map((s) => ({ student_id: s.id, status: $(`input[name="s_${s.id}"]:checked`)?.value, score: $("#sc_" + s.id).value })).filter((r) => r.status);
    if (!recs.length) return toast("ยังไม่ได้เลือกสถานะ");
    const n = await run(() => rpc("admin_mark_submissions", { p_assignment: S.asg, p_records: recs }), null);
    toast(`บันทึกการส่งงาน ${n} คนแล้ว ✅`);
  };
};
