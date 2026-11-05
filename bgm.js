/* เพลงประกอบพื้นหลัง — สังเคราะห์สดด้วย Web Audio API (ไม่มีไฟล์เสียง ไม่ติดลิขสิทธิ์)
   ธีมเปลี่ยนตามหน้า: หน้าหลัก (สงบ) · มินิเกม (เวทมนตร์) · ต่อสู้มอนสเตอร์ · ท้าดวลเพื่อน · เปิด/ปิดและปรับเสียงได้ที่ปุ่ม 🎵 */
const BGM = (() => {
  const KEY = "chem_bgm";
  const mtof = (m) => 440 * Math.pow(2, (m - 69) / 12);
  // chords: คอร์ดละ 1 ห้อง (16 จังหวะย่อย) · arp: ดัชนีโน้ตในคอร์ด (null = เงียบ) · bass: จังหวะเบส · dr: k=กลอง s=แสนร์ h=ไฮแฮท
  const T = {
    calm:   { bpm: 76, lead: "triangle", bassW: "sine", pad: 0.05, arp: [0, null, 2, null, 1, null, 3, null, 2, null, 1, null, 0, null, 2, null], arpOct: 12, arpG: 0.07, bass: [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0], bassG: 0.12, dr: "",
              chords: [[60, 64, 67, 71], [57, 60, 64, 67], [53, 57, 60, 64], [55, 59, 62, 65]] },
    magic:  { bpm: 104, lead: "sine", bassW: "triangle", pad: 0.05, arp: [0, 2, 1, 3, 2, 1, 3, 2, 0, 2, 1, 3, 2, 3, 1, 2], arpOct: 12, arpG: 0.075, bass: [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0], bassG: 0.12, dr: "h.h.h.h.h.h.h.hh",
              chords: [[57, 60, 64, 67], [53, 57, 60, 64], [55, 59, 62, 65], [52, 56, 59, 64]] },
    battle: { bpm: 144, lead: "square", bassW: "sawtooth", pad: 0.03, arp: [0, null, 2, 3, 0, null, 2, 3, 1, null, 3, 2, 1, null, 3, 2], arpOct: 12, arpG: 0.05, bass: [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1], bassG: 0.1, dr: "k.h.s.h.k.hks.h.",
              chords: [[50, 53, 57, 62], [46, 50, 53, 58], [48, 52, 55, 60], [45, 49, 52, 57]] },
    duel:   { bpm: 156, lead: "square", bassW: "sawtooth", pad: 0.03, arp: [0, 2, 3, 2, 0, 2, 3, 2, 1, 3, 2, 3, 1, 3, 2, 3], arpOct: 12, arpG: 0.05, bass: [1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0], bassG: 0.1, dr: "k.hks.hkk.hks.hs",
              chords: [[52, 55, 59, 64], [48, 52, 55, 60], [50, 54, 57, 62], [47, 51, 54, 59]] },
  };
  let ctx = null, master = null, noiseBuf = null, timer = null, nextT = 0, step = 0, cur = null, want = "calm", started = false;
  const st = { on: true, vol: 0.45 };
  try { const v = JSON.parse(localStorage.getItem(KEY) || "null"); if (v) { st.on = v.on !== false; st.vol = typeof v.vol === "number" ? v.vol : 0.45; } } catch (e) {}
  const save = () => { try { localStorage.setItem(KEY, JSON.stringify(st)); } catch (e) {} };

  function init() {
    if (ctx) return true;
    const AC = window.AudioContext || window.webkitAudioContext; if (!AC) return false;
    ctx = new AC(); master = ctx.createGain(); master.gain.value = st.on ? st.vol * 0.5 : 0; master.connect(ctx.destination);
    const len = ctx.sampleRate; noiseBuf = ctx.createBuffer(1, len, ctx.sampleRate); const d = noiseBuf.getChannelData(0); for (let i = 0; i < len; i++) d[i] = Math.random() * 2 - 1;
    return true;
  }
  function note(t, midi, dur, type, g, att = 0.01) {
    const o = ctx.createOscillator(), a = ctx.createGain(); o.type = type; o.frequency.value = mtof(midi);
    a.gain.setValueAtTime(0.0001, t); a.gain.linearRampToValueAtTime(g, t + att); a.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    o.connect(a); a.connect(master); o.start(t); o.stop(t + dur + 0.05);
  }
  function drum(t, k) {
    if (k === "k") { const o = ctx.createOscillator(), a = ctx.createGain(); o.frequency.setValueAtTime(140, t); o.frequency.exponentialRampToValueAtTime(40, t + 0.12); a.gain.setValueAtTime(0.28, t); a.gain.exponentialRampToValueAtTime(0.001, t + 0.15); o.connect(a); a.connect(master); o.start(t); o.stop(t + 0.18); return; }
    const s = ctx.createBufferSource(), f = ctx.createBiquadFilter(), a = ctx.createGain(); s.buffer = noiseBuf; f.type = k === "h" ? "highpass" : "bandpass"; f.frequency.value = k === "h" ? 7000 : 1800;
    a.gain.setValueAtTime(k === "h" ? 0.05 : 0.14, t); a.gain.exponentialRampToValueAtTime(0.001, t + (k === "h" ? 0.04 : 0.12)); s.connect(f); f.connect(a); a.connect(master); s.start(t); s.stop(t + 0.15);
  }
  function tick() {
    if (!ctx || !cur) return;
    const P = T[cur], sd = 60 / P.bpm / 4;
    while (nextT < ctx.currentTime + 0.3) {
      const bar = Math.floor(step / 16) % P.chords.length, s = step % 16, ch = P.chords[bar];
      if (s === 0) ch.forEach((m) => note(nextT, m, sd * 16 * 0.98, "sine", P.pad, 0.25));          // แพด
      const ai = P.arp[s]; if (ai !== null && ai !== undefined) note(nextT, ch[ai] + P.arpOct, sd * 2.2, P.lead, P.arpG);
      if (P.bass[s]) note(nextT, ch[0] - 12, sd * 1.8, P.bassW, P.bassG, 0.005);
      const d = P.dr[s]; if (d && d !== ".") drum(nextT, d);
      nextT += sd; step++;
    }
  }
  function play(name) {
    if (!init()) return; want = name;
    if (!st.on || document.hidden) return;
    if (ctx.state === "suspended") ctx.resume();
    if (cur === name && timer) return;
    cur = name; step = 0; nextT = ctx.currentTime + 0.12; clearInterval(timer); timer = setInterval(tick, 90);
  }
  function stop() { clearInterval(timer); timer = null; cur = null; }
  function apply() {
    if (!ctx) return;
    master.gain.setTargetAtTime(st.on ? st.vol * 0.5 : 0, ctx.currentTime, 0.05);
    if (st.on) play(want); else stop();
    paintBtn();
  }
  function pick() {                                   // เลือกธีมจากหน้าที่เปิดอยู่
    const tab = document.body.dataset.tab || "";
    const gm = typeof GAMES !== "undefined" && GAMES.mode ? GAMES.mode() : "home";
    let n = "calm";
    if (tab === "game") n = gm === "battle" ? "battle" : gm === "duel" ? "duel" : gm === "home" ? "calm" : "magic";
    return n;
  }
  function loop() { const n = pick(); if (n !== want || (st.on && started && !timer && !document.hidden)) { want = n; if (started && st.on) play(n); } }

  /* ---------- UI ---------- */
  let btn = null, panel = null;
  function paintBtn() { if (btn) btn.textContent = st.on ? "🎵" : "🔇"; const sw = panel && panel.querySelector("input[type=checkbox]"); if (sw) sw.checked = st.on; }
  function ui() {
    btn = document.createElement("button"); btn.className = "bgm-btn"; btn.type = "button"; btn.title = "เพลงประกอบ"; btn.setAttribute("aria-label", "ตั้งค่าเพลงประกอบ");
    panel = document.createElement("div"); panel.className = "bgm-panel"; panel.hidden = true;
    panel.innerHTML = `<label class="bgm-row"><span>🎵 เพลงประกอบ</span><input type="checkbox"></label><label class="bgm-row"><span>🔈</span><input type="range" min="0" max="100"><span>🔊</span></label><small>เพลงสังเคราะห์สด ไม่ใช้ไฟล์เสียง</small>`;
    document.body.appendChild(btn); document.body.appendChild(panel);
    const sw = panel.querySelector("input[type=checkbox]"), rg = panel.querySelector("input[type=range]"); rg.value = Math.round(st.vol * 100);
    btn.onclick = (e) => { e.stopPropagation(); panel.hidden = !panel.hidden; };
    document.addEventListener("click", (e) => { if (!panel.hidden && !panel.contains(e.target) && e.target !== btn) panel.hidden = true; });
    sw.onchange = () => { st.on = sw.checked; save(); started = true; init(); if (ctx.state === "suspended") ctx.resume(); apply(); };
    rg.oninput = () => { st.vol = rg.value / 100; save(); if (ctx) master.gain.setTargetAtTime(st.on ? st.vol * 0.5 : 0, ctx.currentTime, 0.03); };
    paintBtn();
  }
  function boot() {
    ui();
    // เบราว์เซอร์ต้องมีการแตะก่อนถึงเล่นเสียงได้
    const first = () => { document.removeEventListener("pointerdown", first, true); document.removeEventListener("keydown", first, true); started = true; if (init()) { if (ctx.state === "suspended") ctx.resume(); want = pick(); if (st.on) play(want); } };
    document.addEventListener("pointerdown", first, true); document.addEventListener("keydown", first, true);
    document.addEventListener("visibilitychange", () => { if (document.hidden) { stop(); } else if (started && st.on) play(want); });
    setInterval(loop, 1000);
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", boot); else boot();
  return { play, set: (on) => { st.on = !!on; save(); apply(); }, state: () => ({ ...st, track: cur }) };
})();
