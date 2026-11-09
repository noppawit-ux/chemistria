/* เอฟเฟกต์พิกเซลทั่วทั้งแอป (สไปรต์จาก pixelfx · MIT) — ใช้ผ่าน FX.at(element|selector, "ชื่อ", {scale,loop,...}) หรือ FX.screen("ชื่อ", xส่วน, yส่วน) */
const FX = (() => {
  const off = () => matchMedia("(prefers-reduced-motion: reduce)").matches || typeof PFX_DATA === "undefined";
  let layer = null;
  const L = () => { if (!layer || !layer.isConnected) { layer = document.createElement("div"); layer.id = "fxlayer"; document.body.appendChild(layer); } return layer; };
  const cache = {};
  function play(name, x, y, o = {}) {              // x,y = พิกัดหน้าจอ (px) จุดยึดของเอฟเฟกต์
    if (typeof SFX !== "undefined") SFX.fromFx(name, o);
    const m = !off() && PFX_DATA[name]; if (!m) return null;
    if (!cache[name]) { cache[name] = new Image(); cache[name].src = `assets/pixelfx/${name}.png`; }
    const sc = o.scale || 2, W = m.w * sc, H = m.h * sc, el = document.createElement("div"); el.className = "pfxg";
    Object.assign(el.style, { width: W + "px", height: H + "px", left: x - m.ox * sc + "px", top: y - m.oy * sc + "px", backgroundImage: `url(assets/pixelfx/${name}.png)`, backgroundSize: `${m.cols * W}px auto`, opacity: o.opacity == null ? 1 : o.opacity });
    if (o.flip) el.style.transform = "scaleX(-1)";
    if (o.loop) el.dataset.loop = "1";
    (o.parent || L()).appendChild(el);
    const t0 = performance.now(), ms = m.ms / (o.speed || 1), total = o.loop ? Infinity : ms * m.n * (o.loops || 1);
    const tick = (t) => { if (!el.isConnected) return; const e = t - t0; if (e >= total) { el.remove(); return; }
      const i = Math.floor(e / ms) % m.n; el.style.backgroundPosition = `${-(i % m.cols) * W}px ${-Math.floor(i / m.cols) * H}px`; requestAnimationFrame(tick); };
    requestAnimationFrame(tick); return el;
  }
  const rect = (t) => { const e = typeof t === "string" ? document.querySelector(t) : t; return e && e.getBoundingClientRect ? e.getBoundingClientRect() : null; };
  function at(t, name, o = {}) {                   // ที่กึ่งกลางของ element (ปรับด้วย dx,dy หรือ foot:true = ฐานล่าง)
    const r = rect(t); if (!r) return null; return play(name, r.left + r.width / 2 + (o.dx || 0), (o.foot ? r.bottom - 6 : r.top + r.height / 2) + (o.dy || 0), o);
  }
  const screen = (name, fx = 0.5, fy = 0.5, o = {}) => play(name, innerWidth * fx + (o.dx || 0), innerHeight * fy + (o.dy || 0), o);
  const later = (ms, fn) => setTimeout(fn, ms);
  /* ชุดเอฟเฟกต์สำเร็จรูป */
  const kit = {
    // ลดเอฟเฟกต์: รางวัล/เลื่อนขั้นแสดงเป็น popup มุมจอ (NOTE ใน index.html) + ประกายเล็กๆ ที่มุมเดียวกัน
    levelUp() { screen("level-up", 0.86, 0.07, { scale: 1.3 }); },
    rankUp() { screen("level-up", 0.86, 0.07, { scale: 1.3 }); },
    victory() { screen("star-fall", 0.5, 0.2, { scale: 1.4 }); },
    coins() {},
    xp() {},
    gacha(el, rar) {
      const r = { N: () => at(el, "xp-orb", { scale: 2.4 }), R: () => at(el, "mana-burst", { scale: 1.6 }),
        SR: () => { at(el, "feather-burst", { scale: 2 }); at(el, "power-star", { scale: 2.4 }); },
        SSR: () => { at(el, "holy-pillar", { scale: 2.4, foot: true }); at(el, "sunburst", { scale: 3 }); later(300, () => screen("confetti", 0.5, 0.7, { scale: 4 })); later(450, () => screen("firework-burst", 0.3, 0.3, { scale: 2.2 })); later(700, () => screen("firework-burst", 0.72, 0.28, { scale: 2.2 })); } };
      (r[rar] || (rar === "LEG" ? r.SSR : r.N))();
    },
  };
  return { play, at, screen, later, ...kit };
})();
