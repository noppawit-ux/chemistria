/* แท็บ: export */
TAB.export = async function (v) {
  v.innerHTML = `<div class="card"><h3>📤 ส่งออกเป็น Excel (.xlsx)</h3>
    <p class="muted">ไฟล์ของห้อง <b>${esc(clsName())}</b> มี 5 ชีต: สมุดคะแนนรวม · รายการคะแนน · เช็คชื่อ · งาน · EXP/เหรียญ — ใช้ตัดเกรดหรือส่งฝ่ายวิชาการได้ทันที</p>
    <div class="row"><button class="btn gold" id="xCls">⬇️ ดาวน์โหลดห้อง ${esc(clsName())}</button>
    <button class="btn ghost" id="xAll">⬇️ คะแนนรวมทุกห้อง (1 ชีตต่อห้อง)</button></div></div>`;
  const need = () => { if (!window.XLSX) { toast("โหลดตัวสร้าง Excel ไม่สำเร็จ (ตรวจอินเทอร์เน็ต)"); return false; } return true; };
  const save = (wb, name) => XLSX.writeFile(wb, name + "_" + todayStr() + ".xlsx");
  const sheet = (rows, widths) => { const ws = XLSX.utils.aoa_to_sheet(rows); ws["!cols"] = (widths || rows[0].map((_, i) => (i === 1 ? 26 : 12))).map((w) => ({ wch: w })); return ws; };
  const gbRows = (gb) => [["เลขที่", "ชื่อ", "ก่อนกลางภาค", "กลางภาค", "หลังกลางภาค", "ปลายภาค", "จิตพิสัย", "คะแนนพิเศษ", "รวม (ไม่รวมพิเศษ)", "รวมพิเศษ"],
    ...gb.map((r) => [r.no, r.name, r.pre_mid, r.midterm, r.post_mid, r.final, r.behavior, r.bonus, r.total, r.total_with_bonus])];
  $("#xCls").onclick = async () => {
    if (!need()) return;
    const [st, gb, items, sc, att, asg, sub] = await Promise.all([
      sb.from("students").select("id,no,name,exp,coins").eq("class_id", S.cls).order("no").then(must),
      sb.from("v_gradebook").select("*").eq("class_id", S.cls).order("no").then(must),
      sb.from("score_items").select("*").eq("class_id", S.cls).order("created_at").then(must),
      sb.from("scores").select("item_id,student_id,score").then(must),
      sb.from("ch_attendance").select("student_id,att_date,status").eq("class_id", S.cls).order("att_date").then(must),
      sb.from("ch_assignments").select("id,title,due_date,max_score").eq("class_id", S.cls).order("due_date").then(must),
      sb.from("ch_submissions").select("assignment_id,student_id,status,score").then(must),
    ]);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, sheet(gbRows(gb)), "สมุดคะแนนรวม");
    const scm = {}; sc.forEach((x) => (scm[x.item_id + x.student_id] = x.score));
    XLSX.utils.book_append_sheet(wb, sheet([["เลขที่", "ชื่อ", ...items.map((i) => `${CAT_LABEL[i.category]}: ${i.title} (เต็ม ${i.max_score})`)],
      ...st.map((s) => [s.no, s.name, ...items.map((i) => scm[i.id + s.id] ?? "")])], [8, 26, ...items.map(() => 18)]), "รายการคะแนน");
    const dates = [...new Set(att.map((a) => a.att_date))].sort(), am = {}; att.forEach((a) => (am[a.student_id + a.att_date] = a.status));
    const L = { present: "ม", late: "ส", absent: "ข", leave: "ล" };
    XLSX.utils.book_append_sheet(wb, sheet([["เลขที่", "ชื่อ", ...dates.map(fmtDate), "มา", "สาย", "ขาด", "ลา"],
      ...st.map((s) => { const row = dates.map((d) => am[s.id + d]); const n = (k) => row.filter((x) => x === k).length;
        return [s.no, s.name, ...row.map((x) => L[x] || ""), n("present"), n("late"), n("absent"), n("leave")]; })], [8, 26, ...dates.map(() => 9), 6, 6, 6, 6]), "เช็คชื่อ");
    const smm = {}; sub.forEach((x) => (smm[x.assignment_id + x.student_id] = x));
    const SL = { submitted: "ส่ง", late: "ส่งช้า", missing: "ไม่ส่ง" };
    XLSX.utils.book_append_sheet(wb, sheet([["เลขที่", "ชื่อ", ...asg.map((a) => `${a.title}${a.due_date ? " (ส่ง " + fmtDate(a.due_date) + ")" : ""}`)],
      ...st.map((s) => [s.no, s.name, ...asg.map((a) => { const x = smm[a.id + s.id]; return x ? SL[x.status] + (x.score != null ? ` (${x.score}/${a.max_score})` : "") : ""; })])], [8, 26, ...asg.map(() => 20)]), "งาน");
    XLSX.utils.book_append_sheet(wb, sheet([["เลขที่", "ชื่อ", "เลเวล", "EXP", "เหรียญ"], ...st.map((s) => [s.no, s.name, Math.floor(Math.sqrt(s.exp / 40)) + 1, s.exp, s.coins])], [8, 26, 8, 10, 10]), "EXP-เหรียญ");
    save(wb, "Chemistria_" + clsName().replace(/[\\/:*?\[\]]/g, "-")); toast("ดาวน์โหลดแล้ว ✅");
  };
  $("#xAll").onclick = async () => {
    if (!need()) return;
    const wb = XLSX.utils.book_new();
    for (const c of S.classes) {
      const gb = must(await sb.from("v_gradebook").select("*").eq("class_id", c.id).order("no"));
      XLSX.utils.book_append_sheet(wb, sheet(gbRows(gb)), c.name.replace(/[\\/:*?\[\]]/g, "-").slice(0, 30));
    }
    save(wb, "Chemistria_คะแนนทุกห้อง"); toast("ดาวน์โหลดแล้ว ✅");
  };
};
