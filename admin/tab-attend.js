/* แท็บ: attend */
TAB.attend = async function (v) {
  const [st, at] = await Promise.all([
    sb.from("students").select("id,no,name").eq("class_id", S.cls).order("no").then(must),
    sb.from("ch_attendance").select("student_id,status").eq("class_id", S.cls).eq("att_date", S.attDate).then(must),
  ]);
  const cur = Object.fromEntries(at.map((a) => [a.student_id, a.status]));
  const opts = [["present", "มา"], ["late", "สาย"], ["leave", "ลา"], ["absent", "ขาด"]];
  v.innerHTML = `<div class="card"><div class="row"><h3 class="grow" style="margin:0">เช็คชื่อ ${esc(clsName())}</h3>
    <input type="date" id="ad" value="${S.attDate}" style="width:auto">
    <button class="btn ghost small" id="allp">ทุกคนมา</button><button class="btn gold" id="saveA">บันทึก</button></div>
    <p class="muted">มา = +5 EXP/+2 เหรียญ · สาย = +2 EXP/+1 เหรียญ (ให้อัตโนมัติ ไม่ซ้ำแม้บันทึกหลายรอบ) · แถวที่ไม่เลือกจะไม่ถูกบันทึก</p>
    <div class="scroll"><table><tbody>${st.map((s) => `<tr><td>${s.no}</td><td>${esc(s.name)}</td><td class="seg">
    ${opts.map(([k, l]) => `<label><input type="radio" name="a_${s.id}" value="${k}" ${cur[s.id] === k ? "checked" : ""}>${l}</label>`).join("")}</td></tr>`).join("")}</tbody></table></div></div>`;
  $("#ad").onchange = (e) => { S.attDate = e.target.value || todayStr(); renderTab(); };
  $("#allp").onclick = () => $$('input[value="present"]').forEach((r) => (r.checked = true));
  $("#saveA").onclick = async () => {
    const recs = st.map((s) => ({ student_id: s.id, status: $(`input[name="a_${s.id}"]:checked`)?.value })).filter((r) => r.status);
    if (!recs.length) return toast("ยังไม่ได้เลือกสถานะ");
    const n = await run(() => rpc("admin_mark_attendance", { p_class: S.cls, p_date: S.attDate, p_records: recs }), null);
    toast(`บันทึกเช็คชื่อ ${n} คนแล้ว ✅`);
  };
};
