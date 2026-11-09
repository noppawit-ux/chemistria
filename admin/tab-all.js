/* แท็บ: all */
TAB.all = async function (v) {
  v.innerHTML = '<div class="card muted">กำลังโหลดข้อมูลทุกห้อง…</div>';
  const pageAll = async (t, cols) => { const out = []; for (let f = 0; ; f += 1000) { const { data, error } = await sb.from(t).select(cols).range(f, f + 999); if (error) throw new Error(t + ": " + error.message); out.push(...data); if (data.length < 1000) break; } return out; };
  const [cls, st, gb, att, asg, sub] = await Promise.all([
    pageAll("classes", "id,name,subject_code"), pageAll("students", "id,class_id,no,name,exp,coins,char_class,last_login,locked_until"),
    pageAll("v_gradebook", "student_id,total,total_with_bonus"), pageAll("ch_attendance", "student_id,status"),
    pageAll("ch_assignments", "id,class_id"), pageAll("ch_submissions", "assignment_id,student_id,status")]);
  const cn = Object.fromEntries(cls.map((c) => [c.id, c.name])), G = Object.fromEntries(gb.map((g) => [g.student_id, g]));
  const A = {}; att.forEach((a) => { const o = (A[a.student_id] ||= { n: 0, ok: 0 }); o.n++; if (a.status === "present" || a.status === "late") o.ok++; });
  const asgN = {}; asg.forEach((a) => (asgN[a.class_id] = (asgN[a.class_id] || 0) + 1));
  const sOk = {}; sub.forEach((x) => { if (x.status !== "missing") sOk[x.student_id] = (sOk[x.student_id] || 0) + 1; });
  const rows = st.map((s) => { const a = A[s.id], g = G[s.id], na = asgN[s.class_id] || 0;
    return { ...s, room: cn[s.class_id] || "—", total: g ? Number(g.total_with_bonus ?? g.total) : 0, attPct: a && a.n ? Math.round((a.ok / a.n) * 100) : null, sub: sOk[s.id] || 0, na }; });
  const avg = (xs) => (xs.length ? Math.round(xs.reduce((p, c) => p + c, 0) / xs.length) : 0);
  const sum = cls.map((c) => { const r = rows.filter((x) => x.class_id === c.id), at = r.filter((x) => x.attPct !== null);
    return `<div class="card" style="flex:1;min-width:150px"><b>${esc(c.name)}</b><div class="muted">${esc(c.subject_code || "")}</div>
      <div>👥 ${r.length} คน</div><div>⭐ EXP เฉลี่ย ${avg(r.map((x) => x.exp))}</div><div>🧮 คะแนนเฉลี่ย ${avg(r.map((x) => x.total))}</div>
      <div>📋 เข้าเรียน ${at.length ? avg(at.map((x) => x.attPct)) + "%" : "—"}</div><div>📝 ส่งงาน ${(asgN[c.id] || 0) && r.length ? Math.round((r.reduce((p, x) => p + x.sub, 0) / (r.length * asgN[c.id])) * 100) + "%" : "—"}</div></div>`; }).join("");
  let sortK = "room", dir = 1, q = "", room = "";
  v.innerHTML = `<div class="card"><h3>🏫 ภาพรวมทุกห้อง</h3><div class="row" style="gap:8px;flex-wrap:wrap">${sum}</div></div>
    <div class="card"><div class="row" style="gap:8px;flex-wrap:wrap;align-items:end"><h3 class="grow" style="margin:0">นักเรียนทั้งหมด <span id="cnt" class="muted"></span></h3>
      <div style="width:150px"><label>ห้อง</label><select id="fr"><option value="">ทุกห้อง</option>${cls.map((c) => `<option value="${c.id}">${esc(c.name)}</option>`).join("")}</select></div>
      <div style="width:190px"><label>ค้นหาชื่อ</label><input id="fq" placeholder="พิมพ์ชื่อ"></div>
      <button class="btn gold small" id="allx">⬇️ Excel ทุกห้อง</button></div>
    <div class="scroll" style="margin-top:8px"><table><thead><tr>${[["room", "ห้อง"], ["no", "เลขที่"], ["name", "ชื่อ"], ["exp", "EXP"], ["coins", "เหรียญ"], ["total", "คะแนนรวม"], ["attPct", "เข้าเรียน"], ["sub", "ส่งงาน"], ["last_login", "เข้าล่าสุด"]]
      .map(([k, l]) => `<th data-s="${k}" style="cursor:pointer">${l} ↕</th>`).join("")}</tr></thead><tbody id="tb"></tbody></table></div></div>`;
  const view = () => rows.filter((r) => (!room || r.class_id === room) && (!q || r.name.toLowerCase().includes(q))).sort((a, b) => {
    const x = a[sortK], y = b[sortK]; const c = typeof x === "string" || typeof y === "string" ? String(x ?? "").localeCompare(String(y ?? ""), "th") : (x ?? -1) - (y ?? -1);
    return (c || a.room.localeCompare(b.room, "th") || a.no - b.no) * dir; });
  const draw = () => { const L = view(); $("#cnt").textContent = "(" + L.length + " คน)";
    $("#tb").innerHTML = L.map((r) => `<tr${r.locked_until && new Date(r.locked_until) > new Date() ? ' style="opacity:.6"' : ""}><td>${esc(r.room)}</td><td>${r.no}</td><td>${esc(r.name)}</td><td>${r.exp}</td><td>${r.coins}</td><td>${r.total}</td>
      <td>${r.attPct === null ? "—" : r.attPct + "%"}</td><td>${r.na ? r.sub + "/" + r.na : "—"}</td><td>${r.last_login ? new Date(r.last_login).toLocaleDateString("th-TH") : "ยังไม่เคย"}</td></tr>`).join(""); };
  v.onclick = (e) => { const k = e.target.dataset.s; if (k) { dir = sortK === k ? -dir : 1; sortK = k; draw(); } };
  $("#fr").onchange = (e) => { room = e.target.value; draw(); }; $("#fq").oninput = (e) => { q = e.target.value.trim().toLowerCase(); draw(); };
  $("#allx").onclick = () => { if (!window.XLSX) return toast("โหลดตัวสร้าง Excel ไม่สำเร็จ");
    const wb = XLSX.utils.book_new(); XLSX.utils.book_append_sheet(wb, XLSX.utils.aoa_to_sheet([["ห้อง", "เลขที่", "ชื่อ", "EXP", "เหรียญ", "คะแนนรวม", "เข้าเรียน%", "ส่งงาน", "งานทั้งหมด"], ...view().map((r) => [r.room, r.no, r.name, r.exp, r.coins, r.total, r.attPct, r.sub, r.na])]), "ทุกห้อง");
    XLSX.writeFile(wb, "ทุกห้อง_" + todayStr() + ".xlsx"); };
  draw();
};
