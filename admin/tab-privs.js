/* แท็บ: privs */
TAB.privs = async function (v) {
  const inbox = holder(v, "📥 คำขอใช้สิทธิพิเศษ");
  const rq = must(await sb.from("redemptions").select("id,created_at,students(no,name,class_id),privileges(name,emoji)").eq("status", "requested").order("created_at"));
  const mine = rq.filter((p) => p.students?.class_id === S.cls);
  inbox.className += " inbox";
  inbox.innerHTML = mine.map((p) => `<div class="item"><div class="grow"><b>${p.students.no}. ${esc(p.students.name)}</b> ขอใช้ ${esc(p.privileges.emoji)} ${esc(p.privileges.name)}</div>
    <button class="btn mint small" data-ap="${p.id}">อนุมัติ</button><button class="btn red small" data-rj="${p.id}">ไม่อนุมัติ</button></div>`).join("") || '<p class="muted">ไม่มีคำขอ</p>';
  inbox.onclick = async (e) => { const d = e.target.dataset; if (!(d.ap || d.rj)) return;
    await run(() => rpc("admin_review_privilege", { p_redemption: d.ap || d.rj, p_approve: !!d.ap }), "ดำเนินการแล้ว"); renderTab(); };
  const h = holder(v, "🎟️ รายการสิทธิพิเศษ", "ใส่ราคา = วางขายในร้านค้า · เว้นราคาว่าง = ได้จากกาชา/achievement เท่านั้น · ครูเป็นผู้อนุมัติการใช้สิทธิ์ทุกครั้ง");
  await crud(h, { table: "privileges", order: "name", defaults: { active: true, emoji: "🎟️" },
    cols: [{ k: "emoji", label: "อีโมจิ", w: 50 }, { k: "name", label: "ชื่อ", w: 180 }, { k: "description", label: "รายละเอียด", w: 240 }, { k: "cost", label: "ราคา(เหรียญ)", t: "number", w: 80 }, { k: "active", label: "เปิด", t: "bool" }] });
};
