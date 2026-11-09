/* แท็บ: security */
TAB.security = async function (v) {
  v.innerHTML = `<div class="card"><h3>🛡️ ความปลอดภัยและการแจ้งเตือนการโจมตี</h3><div id="sc" class="muted">กำลังโหลด…</div></div>
    <div class="card"><h3>🔔 วิธีที่ระบบป้องกันและแจ้งเตือน</h3>
    <ul style="margin:0 0 0 18px;line-height:1.7">
      <li>เดา PIN ผิดครบ 5 ครั้ง → ล็อกบัญชี 10 นาที และบันทึกเหตุ</li>
      <li>IP เดียวใส่ PIN ผิดเกิน 60 ครั้งใน 10 นาที → ถูกบล็อก 10 นาที (ปรับได้ที่ตาราง app_settings คีย์ <code>sec_ip_limit</code>); เดาหลายบัญชีจาก IP เดียวเกิน 20 บัญชี → แจ้งเตือนระดับสูง (<code>sec_sweep_accts</code>)</li>
      <li>ล็อก PIN แบบทวีคูณ: ผิดครบ 5 ครั้งล็อก 10 นาที → 30 นาที → 90 นาที … สูงสุด 24 ชม. (ครูเปลี่ยน PIN ใหม่แล้วปลดล็อกให้อัตโนมัติ) · ส่งคำสั่งเกิน 240 ครั้ง/นาทีต่อเซสชันถูกปฏิเสธและแจ้งเตือน (<code>sec_rpc_per_min</code>)</li>
      <li>เกมต้องเริ่มที่เซิร์ฟเวอร์ก่อนส่งคะแนน และเวลาจริงต้องสมเหตุสมผล สคริปต์ที่ส่งคะแนนทันทีจะถูกปฏิเสธ (ปิดได้ด้วย <code>sec_game_timing</code> = 0)</li>
      <li>มีการเพิ่ม/ลบ/แก้รายชื่อครู → แจ้งระดับวิกฤตทันที</li>
      <li>สแกนอัตโนมัติทุก 10 นาทีขณะเปิดหน้าแอดมิน: ตารางที่ปิด RLS · ฟังก์ชันครูที่คนทั่วไปเรียกได้ · EXP พุ่งผิดปกติ (<code>sec_exp_spike</code> ค่าเริ่มต้น 600/ชม.) · เซสชันซ้ำมากผิดปกติ · ตัวเลขติดลบ</li>
      <li>แจ้งเตือนผ่านแบนเนอร์สีแดง ตัวเลขบนชื่อแท็บ และการแจ้งเตือนของเบราว์เซอร์ <b>ขณะเปิดหน้าแอดมินค้างไว้</b> (ไม่มีการส่งอีเมล/LINE ถ้าปิดหน้านี้อยู่)</li></ul>
    <button class="btn ghost small" id="scNotif" style="margin-top:8px">🔔 เปิดการแจ้งเตือนของเบราว์เซอร์</button></div>`;
  const ago = (t) => { const m = Math.round((Date.now() - new Date(t)) / 60000); return m < 1 ? "เมื่อสักครู่" : m < 60 ? m + " นาทีก่อน" : m < 1440 ? Math.round(m / 60) + " ชม.ก่อน" : new Date(t).toLocaleString("th-TH"); };
  const draw = (r) => {
    $("#sc").innerHTML = `
      <div class="row" style="gap:8px;flex-wrap:wrap;margin-bottom:10px">
        <span class="pill" style="background:${r.unseen ? "#b3122a" : "#1c6b45"}">${r.unseen ? "🚨 ยังไม่ตรวจ " + r.unseen + " รายการ" : "✅ ไม่มีเหตุร้ายแรงค้าง"}</span>
        <span class="pill">เตือนทั่วไป ${r.unseen_warn}</span><span class="pill">PIN ผิด 1 ชม.ที่ผ่านมา ${r.fails_1h}</span>
        ${r.lockdown ? '<span class="pill" style="background:#7a4b00">🔒 โหมดฉุกเฉินเปิดอยู่</span>' : ""}</div>
      <div class="row" style="gap:8px;flex-wrap:wrap;margin-bottom:10px">
        <button class="btn small" id="scScan">🔍 สแกนตอนนี้</button>
        <button class="btn ghost small" id="scAck">✔️ รับทราบทั้งหมด</button>
        <button class="btn small" id="scLock" style="background:${r.lockdown ? "#1c6b45" : "#b3122a"};color:#fff">${r.lockdown ? "🔓 ปิดโหมดฉุกเฉิน (เปิดระบบนักเรียน)" : "🔒 โหมดฉุกเฉิน: ปิดระบบนักเรียนและเตะทุกเซสชัน"}</button></div>
      ${r.blocked.length ? `<div style="margin-bottom:10px"><b>IP ที่ถูกบล็อกอยู่:</b> ${r.blocked.map((b) => `<span class="pill">${esc(b.ip)} (${b.fails} ครั้ง/${b.accts} บัญชี) <button class="btn small" data-ub="${esc(b.ip)}" style="margin-left:6px">ปลดบล็อก</button></span>`).join(" ")}<div class="muted">ถ้าเป็น Wi-Fi โรงเรียน ทั้งห้องใช้ IP เดียวกัน ปลดบล็อกได้ถ้าเป็นนักเรียนพิมพ์ผิดจริง</div></div>` : ""}
      ${r.events.length ? r.events.map((e) => { const [ic, col, lb] = SEV[e.sev] || SEV.warn;
        return `<div style="padding:8px 0;border-bottom:1px solid var(--line);${e.seen ? "opacity:.55" : ""}"><div class="row" style="gap:8px;align-items:center"><span class="pill" style="background:${col};color:#fff">${ic} ${lb}</span><b>${esc(e.kind)}</b><small class="muted" style="margin-left:auto">${ago(e.at)}</small></div><div style="margin-top:4px">${esc(e.detail || "")}${e.student ? " · " + esc(e.student) : ""}${e.ip ? ` <small class="muted">IP ${esc(e.ip)}</small>` : ""}</div></div>`; }).join("") : '<div class="muted">ยังไม่มีเหตุผิดปกติที่บันทึกไว้ 👍</div>'}`;
    $("#scScan").onclick = async () => { await run(() => rpc("security_scan"), "สแกนเสร็จแล้ว"); load(); secWatch(); };
    $("#scAck").onclick = async () => { await run(() => rpc("admin_sec_ack", {})); load(); secWatch(); };
    $("#scLock").onclick = async () => { const on = !r.lockdown; if (!confirm(on ? "เปิดโหมดฉุกเฉิน? นักเรียนทุกคนจะถูกออกจากระบบและเข้าไม่ได้จนกว่าจะปิดโหมดนี้" : "ปิดโหมดฉุกเฉินและเปิดให้นักเรียนเข้าระบบ?")) return;
      const x = await run(() => rpc("admin_lockdown", { p_on: on }), on ? "เปิดโหมดฉุกเฉินแล้ว" : "เปิดระบบนักเรียนแล้ว"); load(); secWatch(true); };
    v.querySelectorAll("[data-ub]").forEach((a) => (a.onclick = async () => { await run(() => rpc("admin_unblock_ip", { p_ip: a.dataset.ub }), "ปลดบล็อกแล้ว"); load(); }));
  };
  const load = async () => { try { draw(await rpc("security_summary")); } catch (e) { $("#sc").innerHTML = `<span style="color:var(--red)">โหลดไม่สำเร็จ: ${esc(e.message)}<br>ถ้าเพิ่งอัปเดต ให้รัน SQL 42_security.sql ก่อน</span>`; } };
  $("#scNotif").onclick = async () => { if (!("Notification" in window)) return toast("เบราว์เซอร์นี้ไม่รองรับการแจ้งเตือน"); const p = await Notification.requestPermission(); toast(p === "granted" ? "เปิดการแจ้งเตือนแล้ว ✅" : "ไม่ได้อนุญาตการแจ้งเตือน"); };
  load();
};
