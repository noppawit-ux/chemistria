/* แท็บ: quests */
TAB.quests = async function (v) {
  const inbox = holder(v, "📥 เควสรอตรวจ");
  const pend = must(await sb.from("quest_claims").select("id,claim_date,students(no,name,class_id),quests(title,exp,coins)").eq("status", "pending").order("created_at"));
  const mine = pend.filter((p) => p.students?.class_id === S.cls);
  inbox.className += " inbox";
  inbox.innerHTML = (mine.length ? `<button class="btn mint small" id="apAll">อนุมัติทั้งหมด (${mine.length})</button>` : "") +
    (mine.map((p) => `<div class="item"><div class="grow"><b>${p.students.no}. ${esc(p.students.name)}</b> — ${esc(p.quests.title)}
      <span class="muted">${fmtDate(p.claim_date)} · +${p.quests.exp} EXP +${p.quests.coins}🪙</span></div>
      <button class="btn mint small" data-ap="${p.id}">อนุมัติ</button><button class="btn red small" data-rj="${p.id}">ไม่ผ่าน</button></div>`).join("") || '<p class="muted">ไม่มีเควสรอตรวจ</p>');
  inbox.onclick = async (e) => {
    const d = e.target.dataset;
    if (d.ap || d.rj) { await run(() => rpc("admin_review_quest", { p_claim: d.ap || d.rj, p_approve: !!d.ap }), "ดำเนินการแล้ว"); renderTab(); }
    if (e.target.id === "apAll") { for (const p of mine) await rpc("admin_review_quest", { p_claim: p.id, p_approve: true }); toast("อนุมัติทั้งหมดแล้ว ✅"); renderTab(); }
  };
  const h = holder(v, "🗺️ คลังเควส", "ประจำวัน: ระบบสุ่มให้วันละ N ข้อ (ตั้ง N ในแท็บตั้งค่า) · รายสัปดาห์: แสดงทุกข้อ · ห้อง “ทุกห้อง” = ใช้กับทุกห้อง");
  await crud(h, { table: "quests", order: "title", defaults: { kind: "daily", exp: 10, coins: 3, needs_approval: true, active: true },
    cols: [{ k: "title", label: "ชื่อเควส", w: 180 }, { k: "description", label: "รายละเอียด", w: 200 }, { k: "kind", label: "ชนิด", t: "select", opts: () => [["daily", "ประจำวัน"], ["weekly", "รายสัปดาห์"]] },
      { k: "exp", label: "EXP", t: "number", w: 60 }, { k: "coins", label: "เหรียญ", t: "number", w: 60 }, { k: "needs_approval", label: "ครูตรวจ", t: "bool" },
      { k: "auto_trigger", label: "อัตโนมัติ", t: "select", opts: () => [["", "— (ผู้เล่นกดเอง) —"], ["attendance", "เมื่อครูเช็คชื่อว่ามา"], ["login", "เมื่อเข้าสู่ระบบวันนี้"], ["quiz", "เมื่อทำควิซประจำวัน"], ["quiz_perfect", "เมื่อควิซถูกทุกข้อ"], ["match", "เมื่อเล่นจับคู่ธาตุ"], ["submit", "เมื่อส่งงาน 1 ชิ้น"], ["gacha", "เมื่อสุ่มกาชา"], ["decorate", "เมื่อเปลี่ยนชุด/ไอเทมตัวละคร"]] },
      { k: "class_id", label: "ห้อง", t: "select", opts: classOpts("ทุกห้อง") }, { k: "active", label: "เปิด", t: "bool" }] });
};
