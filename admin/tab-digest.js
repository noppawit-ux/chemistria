/* แท็บ: digest */
TAB.digest = async function (v) {
  v.innerHTML = `<div class="card"><div class="row"><h3 class="grow" style="margin:0">📊 สรุปห้อง ${esc(clsName())}</h3>
    <select id="dDays" style="width:auto"><option value="7">7 วันล่าสุด</option><option value="14">14 วันล่าสุด</option><option value="30">30 วันล่าสุด</option></select>
    <button class="btn small ghost" id="dCopy">📋 คัดลอกเป็นข้อความ</button></div><div id="dBody"><p class="muted">กำลังโหลด…</p></div></div>`;
  const days = Number(S.digDays || 7); $("#dDays").value = String(days);
  const r = await rpc("admin_weekly_digest", { p_class: S.cls, p_days: days });
  const A = r.attendance, tot = A.present + A.late + A.absent + A.leave;
  const rate = tot ? Math.round(((A.present + A.late) / tot) * 100) : 0;
  const sec = (title, rows, empty) => `<h4>${title}</h4>${rows.length ? rows.join("") : `<p class="muted">${empty}</p>`}`;
  const pill = (t, cls = "") => `<span class="pill ${cls}" style="margin:2px">${t}</span>`;
  const lines = [];
  lines.push(`สรุปห้อง ${clsName()} (${fmtDate(r.from)} – ${fmtDate(r.to)})`, `มาเรียน ${rate}% (มา ${A.present} สาย ${A.late} ขาด ${A.absent} ลา ${A.leave}) · EXP รวมที่นักเรียนได้ ${r.exp_total}`);
  const abs = r.absent.map((x) => `${x.no}. ${x.name} — ขาด ${x.absent_week} ครั้งในช่วงนี้ (30 วัน: ขาด ${x.absent_30} สาย ${x.late_30})`);
  const mis = r.missing.map((x) => `${x.no}. ${x.name} — ค้างส่ง ${x.missing} ชิ้น: ${x.titles.join(", ")}`);
  const ina = r.inactive.map((x) => `${x.no}. ${x.name} — ${x.last_login ? "เข้าล่าสุด " + fmtDate(x.last_login) : "ยังไม่เคยเข้า"}`);
  lines.push("", "ขาดเรียน:", ...(abs.length ? abs : ["— ไม่มี"]), "", "ค้างส่งงาน:", ...(mis.length ? mis : ["— ไม่มี"]), "", "ไม่ได้เข้าเว็บ:", ...(ina.length ? ina : ["— ไม่มี"]));
  $("#dBody").innerHTML = `<div class="grid">
      <div class="card stat"><span class="muted">มาเรียน</span><b>${rate}%</b>จาก ${tot} รายการ</div>
      <div class="card stat"><span class="muted">ขาด / สาย</span><b>${A.absent} / ${A.late}</b>ครั้ง</div>
      <div class="card stat"><span class="muted">EXP ที่นักเรียนได้</span><b>${r.exp_total}</b>รวมทั้งห้อง</div></div>
    ${sec("🚫 ขาดเรียน (ช่วงนี้ หรือสะสม ≥ 3 ครั้งใน 30 วัน)", r.absent.map((x) => `<div class="item"><div class="grow"><b>${x.no}. ${esc(x.name)}</b></div>${pill("ขาดช่วงนี้ " + x.absent_week, x.absent_week >= 2 ? "rar-SR" : "")}${pill("30 วัน: ขาด " + x.absent_30 + " สาย " + x.late_30)}</div>`), "ไม่มีนักเรียนขาด 🎉")}
    ${sec("📝 ค้างส่งงาน (เลยกำหนดและยังไม่ส่ง)", r.missing.map((x) => `<div class="item"><div class="grow"><b>${x.no}. ${esc(x.name)}</b><div class="muted">${x.titles.map(esc).join(" · ")}</div></div>${pill("ค้าง " + x.missing + " ชิ้น", x.missing >= 2 ? "rar-SR" : "")}</div>`), "ไม่มีงานค้าง 🎉")}
    ${sec("💤 ไม่ได้เข้าเว็บในช่วงนี้", r.inactive.map((x) => `<div class="item"><div class="grow"><b>${x.no}. ${esc(x.name)}</b></div><span class="muted">${x.last_login ? "เข้าล่าสุด " + fmtDate(x.last_login) : "ยังไม่เคยเข้า"}</span></div>`), "ทุกคนเข้าเว็บแล้ว 🎉")}
    ${sec("🏅 EXP สูงสุดช่วงนี้", r.top.map((x, i) => `<div class="item"><b style="width:28px">${i + 1}</b><div class="grow">${x.no}. ${esc(x.name)}</div><b>+${x.exp_week}</b></div>`), "ยังไม่มีข้อมูล")}`;
  $("#dDays").onchange = (e) => { S.digDays = e.target.value; renderTab(); };
  $("#dCopy").onclick = async () => { await navigator.clipboard.writeText(lines.join("\n")); toast("คัดลอกสรุปแล้ว ✅ นำไปวางใน LINE ได้"); };
};
