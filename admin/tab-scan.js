/* แท็บ: scan — สแกน QR นักเรียนเพื่อตรวจงาน (บันทึกส่ง + คะแนน + EXP ตามงาน) */
let SCAN = { stream: null, timer: null, busy: false, last: "", lastAt: 0 };
function scanStop() { clearInterval(SCAN.timer); SCAN.timer = null; if (SCAN.stream) SCAN.stream.getTracks().forEach((t) => t.stop()); SCAN.stream = null; }
function scanBeep(ok) { try { const c = (scanBeep.c ||= new (window.AudioContext || window.webkitAudioContext)()), o = c.createOscillator(), g = c.createGain(); o.frequency.value = ok ? 880 : 220; g.gain.value = 0.15; o.connect(g); g.connect(c.destination); o.start(); o.stop(c.currentTime + 0.12); } catch (e) {} }
TAB.scan = async function (v) {
  scanStop();
  const as = must(await sb.from("ch_assignments").select("id,title,max_score,exp_reward,coin_reward,due_date").eq("class_id", S.cls).order("due_date", { ascending: false }));
  const h = holder(v, "📷 สแกนตรวจงาน", `ห้อง ${esc(clsName())} — เลือกงาน ตั้งคะแนน แล้วสแกน QR จากมือถือนักเรียน (ในแอป → งาน → 📱 QR ของฉัน) · สแกนแล้วบันทึกส่ง + คะแนน + EXP/เหรียญตามงานอัตโนมัติ`);
  if (!as.length) { h.innerHTML = '<p class="muted">ห้องนี้ยังไม่มีงาน — สร้างในแท็บ “งาน/การส่ง” ก่อน</p>'; return; }
  S.asg = as.find((a) => a.id === S.asg) ? S.asg : as[0].id;
  const stu = must(await sb.from("students").select("id,no,name").eq("class_id", S.cls).order("no"));
  let done = {};
  const loadDone = async () => { done = Object.fromEntries(must(await sb.from("ch_submissions").select("student_id,status,score").eq("assignment_id", S.asg).in("status", ["submitted", "late"])).map((r) => [r.student_id, r])); };
  await loadDone();
  const cur = () => as.find((a) => a.id === S.asg);
  h.innerHTML = `<div class="row" style="gap:8px;flex-wrap:wrap;align-items:end">
      <div class="field" style="margin:0"><label>งาน</label><select id="sasg">${as.map((a) => `<option value="${a.id}" ${a.id === S.asg ? "selected" : ""}>${esc(a.title)}</option>`).join("")}</select></div>
      <div class="field" style="margin:0"><label>คะแนนที่ให้ (เต็ม <span id="smax"></span>)</label><input id="sscore" type="number" step="any" min="0" style="width:100px"></div>
      <div class="field" style="margin:0"><label>นับเป็น</label><select id="sst"><option value="submitted">ส่งปกติ</option><option value="late">ส่งช้า</option></select></div>
    </div>
    <div class="muted" id="sinfo" style="margin:6px 0"></div>
    <button class="btn gold" id="scam">📷 เปิดกล้องสแกน</button> <button class="btn ghost" id="sstop" style="display:none">⏹ หยุด</button>
    <div id="svwrap" style="display:none;margin-top:8px;position:relative;max-width:420px"><video id="svid" playsinline muted style="width:100%;border-radius:12px;background:#000"></video><div id="sflash" style="position:absolute;inset:0;border-radius:12px;pointer-events:none;border:6px solid transparent;transition:border-color .2s"></div></div>
    <div id="smsg" style="margin:8px 0;font-weight:600"></div>
    <div class="muted" id="scnt"></div><div id="sroster" style="display:flex;flex-wrap:wrap;gap:4px 10px;margin-top:6px"></div>`;
  const msg = (t, ok) => { const m = $("#smsg", h); m.textContent = t; m.style.color = ok ? "var(--green, #2e9e5b)" : "var(--red)"; const f = $("#sflash", h); f.style.borderColor = ok ? "#2e9e5b" : "#e5484d"; setTimeout(() => (f.style.borderColor = "transparent"), 450); };
  const paint = () => { const a = cur(); $("#smax", h).textContent = a.max_score; $("#sinfo", h).textContent = `รางวัลต่อคน: ${a.exp_reward} EXP · ${a.coin_reward} เหรียญ (ครึ่งหนึ่งถ้านับเป็นส่งช้า)`;
    const n = stu.filter((s) => done[s.id]).length; $("#scnt", h).textContent = `ส่งแล้ว ${n} / ${stu.length} คน`;
    $("#sroster", h).innerHTML = stu.map((s) => `<span style="white-space:nowrap;${done[s.id] ? "color:var(--green,#2e9e5b);font-weight:600" : "opacity:.6"}">${done[s.id] ? "✅" : "⬜"} ${s.no}. ${esc(s.name)}</span>`).join(""); };
  const setScore = () => { $("#sscore", h).value = cur().max_score; };
  setScore(); paint();
  $("#sasg", h).onchange = async (e) => { S.asg = e.target.value; await loadDone(); setScore(); paint(); };
  const handle = async (code) => {
    SCAN.busy = true;
    try {
      const sc = $("#sscore", h).value;
      const r = await rpc("admin_scan_submit", { p_assignment: S.asg, p_code: code, p_score: sc === "" ? null : Number(sc), p_status: $("#sst", h).value });
      done[r.sid] = { status: r.status, score: r.score };
      if (r.dup) { scanBeep(false); msg(`⚠️ ${r.no}. ${r.name} สแกนไปแล้ว (คะแนน ${r.score ?? "—"})`, false); }
      else { scanBeep(true); msg(`✅ ${r.no}. ${r.name} · ${r.score ?? "ไม่มีคะแนน"} · +${r.exp} EXP`, true); }
      paint();
    } catch (e) { scanBeep(false); msg("❌ " + e.message, false); }
    SCAN.busy = false;
  };
  $("#sstop", h).onclick = () => { scanStop(); $("#svwrap", h).style.display = "none"; $("#sstop", h).style.display = "none"; $("#scam", h).style.display = ""; };
  $("#scam", h).onclick = async () => {
    try {
      await new Promise((ok, no) => { if (window.jsQR) return ok(); const s = document.createElement("script"); s.src = "vendor/jsQR.js?v=1.84"; s.onload = ok; s.onerror = () => no(new Error("โหลดตัวอ่าน QR ไม่ได้")); document.head.appendChild(s); });
      SCAN.stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: { ideal: "environment" } }, audio: false });
    } catch (e) { return msg("เปิดกล้องไม่ได้: " + (e.message || e) + " (ต้องอนุญาตกล้องให้เบราว์เซอร์)", false); }
    const vid = $("#svid", h); vid.srcObject = SCAN.stream; await vid.play().catch(() => {});
    $("#svwrap", h).style.display = ""; $("#sstop", h).style.display = ""; $("#scam", h).style.display = "none";
    const cv = document.createElement("canvas"), cx = cv.getContext("2d", { willReadFrequently: true });
    SCAN.timer = setInterval(() => {
      if (!document.getElementById("svid")) return scanStop();
      if (SCAN.busy || !vid.videoWidth) return;
      const w = 480, hh = Math.round((vid.videoHeight / vid.videoWidth) * w); cv.width = w; cv.height = hh; cx.drawImage(vid, 0, 0, w, hh);
      const q = jsQR(cx.getImageData(0, 0, w, hh).data, w, hh, { inversionAttempts: "dontInvert" });
      if (q && q.data && (q.data !== SCAN.last || Date.now() - SCAN.lastAt > 4000)) { SCAN.last = q.data; SCAN.lastAt = Date.now(); handle(q.data); }
    }, 160);
  };
};
