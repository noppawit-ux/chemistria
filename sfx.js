/* เสียงเอฟเฟกต์ประกอบการใช้งานทั้งแอป — สังเคราะห์สดด้วย Web Audio (ไม่มีไฟล์เสียง)
   ผูกอัตโนมัติ: (1) แตะปุ่ม/แท็บ/การ์ด (2) เอฟเฟกต์พิกเซลทุกชนิดผ่าน FX.play (3) ข้อความ toast · เรียกตรงได้ด้วย SFX.play("ok") */
const SFX = (() => {
  const KEY = "chem_sfx";
  let ctx = null, out = null, noise = null;
  const st = { on: true, vol: 0.7 };
  try { const v = JSON.parse(localStorage.getItem(KEY) || "null"); if (v) { st.on = v.on !== false; st.vol = typeof v.vol === "number" ? v.vol : 0.7; } } catch (e) {}
  const save = () => { try { localStorage.setItem(KEY, JSON.stringify(st)); } catch (e) {} };
  const mtof = (m) => 440 * Math.pow(2, (m - 69) / 12);
  function init() {
    if (ctx) return true;
    const AC = window.AudioContext || window.webkitAudioContext; if (!AC) return false;
    ctx = new AC(); out = ctx.createGain(); out.gain.value = st.vol * 0.55;
    const comp = ctx.createDynamicsCompressor(); out.connect(comp); comp.connect(ctx.destination);
    const n = ctx.sampleRate / 2; noise = ctx.createBuffer(1, n, ctx.sampleRate); const d = noise.getChannelData(0); for (let i = 0; i < n; i++) d[i] = Math.random() * 2 - 1;
    return true;
  }
  /* โน้ต: ความถี่เริ่ม→จบ (สไลด์), ซองเสียงสั้น */
  function tone(t, f0, f1, dur, type = "square", g = 0.2, att = 0.004) {
    const o = ctx.createOscillator(), a = ctx.createGain(); o.type = type; o.frequency.setValueAtTime(f0, t);
    if (f1 && f1 !== f0) o.frequency.exponentialRampToValueAtTime(f1, t + dur);
    a.gain.setValueAtTime(0.0001, t); a.gain.linearRampToValueAtTime(g, t + att); a.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    o.connect(a); a.connect(out); o.start(t); o.stop(t + dur + 0.03);
  }
  function hiss(t, dur, g = 0.15, f = 3000, type = "bandpass", f1) {
    const s = ctx.createBufferSource(), fl = ctx.createBiquadFilter(), a = ctx.createGain(); s.buffer = noise; fl.type = type; fl.frequency.setValueAtTime(f, t); if (f1) fl.frequency.exponentialRampToValueAtTime(f1, t + dur);
    a.gain.setValueAtTime(g, t); a.gain.exponentialRampToValueAtTime(0.0001, t + dur); s.connect(fl); fl.connect(a); a.connect(out); s.start(t); s.stop(t + dur + 0.03);
  }
  const arp = (t, notes, step, type, g, dur) => notes.forEach((m, i) => tone(t + i * step, mtof(m), 0, dur || step * 1.6, type, g));
  const S = {
    click: (t) => tone(t, 900, 700, 0.05, "square", 0.08),
    tab: (t) => { tone(t, 520, 0, 0.06, "triangle", 0.12); tone(t + 0.05, 780, 0, 0.07, "triangle", 0.1); },
    pop: (t) => tone(t, 500, 1100, 0.09, "sine", 0.18),
    blip: (t) => tone(t, 1200, 1800, 0.07, "square", 0.07),
    toast: (t) => { tone(t, 880, 0, 0.08, "triangle", 0.1); tone(t + 0.07, 1175, 0, 0.12, "triangle", 0.1); },
    ok: (t) => arp(t, [72, 76, 79, 84], 0.07, "triangle", 0.16),
    bad: (t) => { tone(t, 220, 110, 0.28, "sawtooth", 0.16); tone(t + 0.05, 165, 82, 0.3, "square", 0.1); },
    coin: (t) => { tone(t, 988, 0, 0.07, "square", 0.1); tone(t + 0.07, 1319, 0, 0.22, "square", 0.1); },
    levelup: (t) => arp(t, [60, 64, 67, 72, 76, 79, 84], 0.085, "square", 0.12, 0.2),
    rank: (t) => { arp(t, [55, 62, 67, 71, 74, 79], 0.1, "triangle", 0.18, 0.35); tone(t + 0.6, mtof(79), 0, 0.8, "sine", 0.2, 0.05); },
    cheer: (t) => { hiss(t, 0.5, 0.1, 4000, "highpass"); arp(t, [72, 76, 79], 0.06, "triangle", 0.1); },
    firework: (t) => { tone(t, 300, 1400, 0.25, "sine", 0.1); hiss(t + 0.25, 0.45, 0.16, 2500, "bandpass", 500); },
    hit: (t) => { tone(t, 200, 70, 0.12, "square", 0.2); hiss(t, 0.08, 0.2, 1500); },
    crit: (t) => { tone(t, 260, 60, 0.2, "sawtooth", 0.22); hiss(t, 0.15, 0.25, 2200); tone(t + 0.04, 1400, 700, 0.15, "square", 0.1); },
    slash: (t) => hiss(t, 0.18, 0.2, 3500, "bandpass", 900),
    zap: (t) => { tone(t, 1800, 300, 0.14, "sawtooth", 0.1); hiss(t, 0.1, 0.12, 6000, "highpass"); },
    boom: (t) => { tone(t, 140, 35, 0.4, "sine", 0.35); hiss(t, 0.35, 0.22, 900, "lowpass", 120); },
    shield: (t) => { tone(t, 700, 500, 0.1, "square", 0.14); tone(t + 0.04, 1050, 800, 0.16, "triangle", 0.12); },
    magic: (t) => { tone(t, 500, 1600, 0.3, "sine", 0.14); tone(t + 0.04, 750, 2000, 0.3, "triangle", 0.08); },
    mana: (t) => { arp(t, [76, 79, 83, 88], 0.05, "sine", 0.14, 0.3); hiss(t, 0.2, 0.05, 6000, "highpass"); },
    charge: (t) => tone(t, 200, 900, 0.45, "sawtooth", 0.07),
    star: (t) => arp(t, [88, 91, 95], 0.06, "triangle", 0.1, 0.25),
    heal: (t) => arp(t, [67, 72, 76, 79], 0.09, "sine", 0.16, 0.3),
    holy: (t) => { arp(t, [60, 67, 72, 76], 0.12, "sine", 0.16, 0.7); tone(t, mtof(48), 0, 1, "sine", 0.18, 0.1); },
    chime: (t) => arp(t, [84, 88], 0.09, "sine", 0.14, 0.45),
    curse: (t) => { tone(t, 180, 90, 0.5, "sawtooth", 0.12); tone(t, 190, 95, 0.5, "square", 0.08); },
    chest: (t) => { hiss(t, 0.12, 0.12, 800, "lowpass"); arp(t + 0.1, [72, 79, 84, 91], 0.08, "triangle", 0.15, 0.3); },
    shatter: (t) => { hiss(t, 0.3, 0.22, 5000, "highpass"); tone(t, 600, 100, 0.25, "square", 0.1); },
    splash: (t) => hiss(t, 0.3, 0.16, 1500, "bandpass", 400),
    fire: (t) => hiss(t, 0.35, 0.16, 700, "bandpass", 1800),
    win: (t) => { arp(t, [67, 67, 67, 72, 76, 79, 84], 0.11, "square", 0.12, 0.25); },
    lose: (t) => arp(t, [67, 64, 60, 55], 0.17, "triangle", 0.16, 0.4),
    resurrect: (t) => { arp(t, [48, 55, 60, 64, 67, 72, 76], 0.1, "sine", 0.16, 0.5); },
    portal: (t) => { tone(t, 150, 600, 0.5, "sine", 0.14); tone(t, 155, 620, 0.5, "triangle", 0.08); },
  };
  // ชื่อเอฟเฟกต์พิกเซล → เสียง (loop ประดับ เช่น halo/spirit-flame/poison-cloud ไม่มีเสียง)
  const MAP = { "level-up": "levelup", confetti: "cheer", "firework-burst": "firework", "coin-spin": "coin", "xp-orb": "blip", "collect-burst": "pop", "hit-spark": "hit", "blunt-hit": "hit", "crit-hit": "crit",
    "sword-slash": "slash", "zap-hit": "zap", "small-explosion": "boom", "shield-block": "shield", "magic-missile": "magic", "heal-aoe": "heal", "healing-bloom": "heal", "mana-burst": "mana",
    "spell-charge": "charge", "power-star": "star", "star-fall": "star", curse: "curse", "holy-pillar": "holy", "feather-burst": "chime", resurrection: "resurrect", "chest-open": "chest",
    "loot-beam": "chime", "shatter-death": "shatter", "acid-splash": "splash", fireball: "fire", "heart-pickup": "chime", sunburst: "holy", portal: "portal", haste: "blip", rage: "hit" };
  const last = {}, recent = [];
  function play(name, o = {}) {
    if (!st.on || !name || !S[name]) return;
    if (!init()) return; if (ctx.state === "suspended") ctx.resume();
    const now = performance.now(), gap = o.gap == null ? 70 : o.gap;
    if (now - (last[name] || 0) < gap) return; last[name] = now;
    while (recent.length && now - recent[0] > 1000) recent.shift(); if (recent.length > 14) return; recent.push(now);   // กันเสียงถี่เกิน
    try { S[name](ctx.currentTime + (o.delay || 0)); } catch (e) {}
  }
  const fromFx = (fx, o) => { if (o && o.loop) return; play(MAP[fx], { gap: 90 }); };

  function boot() {
    const unlock = () => { if (init() && ctx.state === "suspended") ctx.resume(); };
    document.addEventListener("pointerdown", unlock, true); document.addEventListener("keydown", unlock, true);
    // แตะปุ่ม/แท็บ/ไทล์ → เสียงคลิก
    document.addEventListener("click", (e) => {
      const el = e.target.closest && e.target.closest("button,.btn,[onclick],a,.tab,.navbtn,label,summary,select"); if (!el || el.disabled || el.closest(".bgm-panel") || el.dataset.nosfx != null) return;
      play(el.closest("nav,.navwrap,.tabs") ? "tab" : "click", { gap: 40 });
    }, true);
    // toast
    if (typeof toast === "function") { const t0 = toast; window.toast = function (m, ms) { play("toast", { gap: 300 }); return t0.apply(this, arguments); }; }
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", boot); else boot();
  return { play, fromFx, names: Object.keys(S), state: () => ({ ...st }),
    set: (on, vol) => { if (on != null) st.on = !!on; if (vol != null) st.vol = vol; save(); if (out) out.gain.setTargetAtTime(st.vol * 0.55, ctx.currentTime, 0.03); } };
})();
