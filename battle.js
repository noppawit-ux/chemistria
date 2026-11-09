/* มินิเกมต่อสู้มอนสเตอร์เคมี: เลือกสกิลตามคลาส → ตอบคำถามเพื่อใช้สกิล → มอนสเตอร์โต้กลับ กดลูกศรลดดาเมจ
   (ดาเมจ/เฉลย/รางวัล คำนวณที่เซิร์ฟเวอร์ทั้งหมด) */
const BATTLE = (() => {
  const S = { screen: "list", data: null, bat: null, fb: null, msg: "", busy: false, def: null, qtimer: null, hit: "", drop: null, shown: {}, hpDelay: 0 };
  const ARW = { L: "⬅️", U: "⬆️", R: "➡️", D: "⬇️" };
  const KEYS = { ArrowLeft: "L", ArrowUp: "U", ArrowRight: "R", ArrowDown: "D" };
  const KIND = { attack: ["⚔️", "โจมตี"], buff: ["📈", "บัพ"], heal: ["💚", "ฮีล"] };
  const BUFF = { atk_up: "🔥 พลังโจมตี +50%", crit_up: "🍀 คริติคอลแน่นอน", shield: "🛡️ โล่ลดดาเมจ 50%", weak: "🔬 มอนสเตอร์อ่อนแอ +40%" };
  const paint = () => { GAMES.paint(); setTimeout(syncLoops, 0); };
  const mimg = (m, cls = "") => m.image ? `<img class="bt-mimg ${cls}" src="${esc(m.image)}" alt="${esc(m.name)}" onerror="this.outerHTML='<div class=&quot;bt-memo ${cls}&quot;>${esc(m.emoji)}</div>'">` : `<div class="bt-memo ${cls}">${esc(m.emoji)}</div>`;
  const hp = (v, mx, cls, from, delay) => { const to = Math.max(0, Math.round((100 * v) / mx)), fr = from == null ? to : Math.max(0, Math.round((100 * from) / mx));
    return `<div class="bt-hp ${cls}"><i style="width:${to}%;--from:${fr}%;animation-delay:${fr === to ? 0 : delay || 0}ms" class="${fr === to ? "" : "shift"}"></i><span>${v} / ${mx}</span></div>`; };
  function sprite(me) {
    const dc = me.decor || {}, cls = me.char_class || "novice", o = dc.outfit, base = "assets/chars/" + cls + (altGender(cls, dc.gender) ? "_alt" : "");
    const pet = dc.pet ? (dc.pet.image ? `<img class="bt-pet" src="${esc(dc.pet.image)}" alt="">` : `<span class="bt-pet">${esc(dc.pet.emoji)}</span>`) : "";
    return `<img class="bt-spr" src="${base}${o ? "_" + esc(o.key) : ""}.png" alt="" onerror="this.onerror=null;this.src='${base}.png'">${pet}`;
  }

  const SKY = { lab: ["🧪", "⚗️", "🔬", "🫧", "🫧", "🫧", "🫧"], ice: ["❄️", "🧊", "❄️", "❄", "❄", "❄", "❄"], volcano: ["🌋", "🔥", "🌋", "🔥", "🔥", "🔥", "🔥"],
    swamp: ["☣️", "🧫", "☣️", "🟢", "🟢", "🫧", "🟢"], storm: ["⛈️", "⚡", "☁️", "⚡", "💧", "💧", "⚡"], crystal: ["💎", "🔮", "💎", "✨", "✨", "✨", "✨"] };
  const skyHtml = (t) => `<div class="bt-sky">${(SKY[t] || SKY.lab).map((e) => `<i>${e}</i>`).join("")}</div>`;
  const arNow = () => { const d = S.data; if (!d || !d.arenas || !d.arenas.length) return null; return d.arenas.find((a) => a.key === S.arena && !a.locked) || d.arenas.find((a) => !a.locked) || d.arenas[0]; };
  const pickArena = (k) => { const a = (S.data.arenas || []).find((x) => x.key === k); if (!a) return; if (a.locked) return toast(`ปลดล็อกที่เลเวล ${a.min_level} 🔒`); S.arena = k; paint(); };

  async function open() {
    S.screen = "list"; S.fb = null; S.msg = ""; S.drop = null; GAMES.setMode("battle"); paint();
    try {
      S.data = await rpc("battle_status", { p_token: tk() });
      if (S.data.active && S.data.active.status === "active") { S.bat = S.data.active; S.screen = "fight"; resume(); }
    } catch (e) { toast(e.message); }
    paint();
  }
  function resume() { clearTimeout(S.qtimer); S.def = null; if (S.bat && S.bat.phase === "question") armQ(S.bat.q.elapsed || 0); if (S.bat && S.bat.phase === "defend") startDef(); }

  async function start(id) {
    if (S.busy) return; S.busy = true;
    try { S.bat = await rpc("battle_start", { p_token: tk(), p_monster: id }); S.screen = "fight"; S.fb = null; S.msg = "การต่อสู้เริ่มขึ้น! เลือกสกิลแล้วตอบคำถามให้ถูกเพื่อใช้สกิล"; S.drop = null; }
    catch (e) { toast(e.message); }
    S.busy = false; paint();
  }
  async function useSkill(key) {
    if (S.busy) return; S.busy = true; paint();
    try { S.bat = await rpc("battle_ask", { p_token: tk(), p_battle: S.bat.id, p_skill: key }); S.fb = null; armQ(0); }
    catch (e) { toast(e.message); }
    S.busy = false; paint();
  }
  const QSECS = 20;
  function armQ(el) { clearTimeout(S.qtimer); clearInterval(S.qint);
    S.qint = setInterval(() => { const e = document.getElementById("bqt"); if (!e || !S.bat || S.bat.phase !== "question") return clearInterval(S.qint); e.textContent = "⏱️ " + Math.max(0, Math.ceil(QSECS - (Date.now() - S.qstart) / 1000)); }, 250); S.qtimer = setTimeout(() => answer(-1), Math.max(300, (QSECS - el) * 1000)); S.qstart = Date.now() - el * 1000; }
  async function answer(i) {
    if (S.busy || !S.bat || S.bat.phase !== "question") return; S.busy = true; clearTimeout(S.qtimer); paint();
    try {
      const r = await rpc("battle_answer", { p_token: tk(), p_battle: S.bat.id, p_pick: i });
      const q = S.bat.q; S.bat = r.state; S.fb = { ...r.event, q }; S.drop = r.drop || null;
      S.hit = ""; S.hpDelay = 520;
      if (S.bat.status !== "active") finishLoad();
      S.busy = false; paint(); setTimeout(() => playSkill(r.event), 30); return;
    } catch (e) { toast(e.message); }
    S.busy = false; paint();
  }
  function afterFb() { S.fb = null; S.hit = ""; if (S.bat.status !== "active") S.screen = "result"; else if (S.bat.phase === "defend") startDef(); paint(); }

  /* ----- ป้องกันด้วยลูกศร ----- */
  function startDef() {
    const p = S.bat.pend; clearTimeout(S.def && S.def.t);
    S.def = { i: 0, hits: 0, marks: [], seq: p.seq.split(""), n: p.n, open: true, state: "ready" };
    S.def.t = setTimeout(nextArrow, 900); paint();
  }
  /* เวลากดต่อ 1 ลูกศร: มอนสเตอร์เก่งขึ้น (เลเวล 1→5) เวลาลดลง 1400→600 ms และช่วงพักระหว่างลูกศรสั้นลง 380→180 ms */
  const winOf = (lv) => Math.max(550, 1400 - 200 * ((lv || 1) - 1));
  const gapOf = (lv) => Math.max(160, 380 - 50 * ((lv || 1) - 1));
  const curWin = () => winOf(S.bat && S.bat.monster && S.bat.monster.level);
  function nextArrow() {
    const d = S.def; if (!d) return;
    if (d.i >= d.n) return endDef();
    d.state = "go"; d.t0 = Date.now();
    d.win = curWin(); d.t = setTimeout(() => judge(null), d.win); paint();
  }
  function judge(k) {
    const d = S.def; if (!d || d.state !== "go") return; clearTimeout(d.t);
    const ok = k === d.seq[d.i]; d.marks.push(ok ? 1 : 0); if (ok) d.hits++; d.state = ok ? "ok" : "miss";
    paint(); d.i++; d.t = setTimeout(nextArrow, gapOf(S.bat && S.bat.monster && S.bat.monster.level));
  }
  async function endDef() {
    const d = S.def; if (!d || d.sent) return; d.sent = true; d.state = "send"; paint();
    try {
      const r = await rpc("battle_defend", { p_token: tk(), p_battle: S.bat.id, p_hits: d.hits });
      S.bat = r.state; const e = r.event;
      S.msg = `🏹 ${S.bat.monster.atk_name}! กดถูก ${e.hits}/${e.n} → รับดาเมจ ${e.taken}${e.shield ? " (โล่ช่วยลดอีกครึ่ง 🛡️)" : ""}`;
      S.hit = "";
      if (S.bat.status !== "active") { S.screen = "result"; finishLoad(); }
      S.def = null; S.hpDelay = 520; paint(); const mo = S.bat.monster; setTimeout(() => playMonster(e, mo.atk_name, mo.emoji), 30); return;
    } catch (x) { toast(x.message); }
    S.def = null; paint();
  }
  window.addEventListener("keydown", (e) => {
    if (S.screen === "fight" && S.def && S.def.state === "go" && KEYS[e.key]) { e.preventDefault(); judge(KEYS[e.key]); }
  });
  const tapArrow = (k) => judge(k);

  function finishLoad() { setTimeout(async () => { try { await load(); } catch (e) {} }, 2400); }   // รอให้เอฟเฟกต์เล่นจบก่อนรีเฟรชข้อมูล
  async function flee() {
    if (!confirm("หนีจากการต่อสู้? จะนับเป็น 1 รอบของวันนี้และไม่ได้รางวัล")) return;
    clearTimeout(S.qtimer); if (S.def) clearTimeout(S.def.t); S.def = null;
    try { await rpc("battle_flee", { p_token: tk(), p_battle: S.bat.id }); } catch (e) {}
    S.bat = null; open();
  }
  const back = () => { clearTimeout(S.qtimer); if (S.def) clearTimeout(S.def.t); S.def = null; S.bat = null; S.fb = null; open(); };
  const exit = () => { clearTimeout(S.qtimer); if (S.def) clearTimeout(S.def.t); S.def = null; GAMES.home(); };


  /* ---------- เอฟเฟกต์เคลื่อนไหวในสนาม ---------- */
  const $f = () => document.getElementById("btfx");
  const ctr = (el, fx) => { const a = el.getBoundingClientRect(), b = fx.getBoundingClientRect(); return [a.left + a.width / 2 - b.left, a.top + a.height * 0.45 - b.top]; };
  function put(html, ms, x, y) { const f = $f(); if (!f) return null; const d = document.createElement("div"); d.className = "fxe"; d.innerHTML = html; if (x != null) { d.style.left = x + "px"; d.style.top = y + "px"; } f.appendChild(d); setTimeout(() => d.remove(), ms); return d; }
  const pop = (cls, el) => { if (!el) return; el.classList.remove(cls); void el.offsetWidth; el.classList.add(cls); setTimeout(() => el.classList.remove(cls), 600); };
  /* ----- สไปรต์พิกเซลจาก pixelfx (MIT) ----- */
  function pfx(name, x, y, o = {}) {
    if (typeof SFX !== "undefined") SFX.fromFx(name, o);
    if (typeof PFX_DATA === "undefined" || !PFX_DATA[name]) return null;
    const m = PFX_DATA[name], sc = o.scale || 1, W = m.w * sc, H = m.h * sc, el = document.createElement("div"); el.className = "pfx";
    Object.assign(el.style, { position: "absolute", width: W + "px", height: H + "px", backgroundImage: `url(assets/pixelfx/${name}.png)`, backgroundSize: `${m.cols * W}px auto`, imageRendering: "pixelated", pointerEvents: "none" });
    if (o.parent) { el.style.left = -m.ox * sc + "px"; el.style.top = -m.oy * sc + "px"; o.parent.appendChild(el); }
    else { const L = $f(); if (!L) return null; el.style.left = x - m.ox * sc + "px"; el.style.top = y - m.oy * sc + "px"; L.appendChild(el); }
    el.style.transformOrigin = `${m.ox * sc}px ${m.oy * sc}px`; if (o.rot != null || o.flip) el.style.transform = `${o.rot != null ? `rotate(${o.rot}rad)` : ""} ${o.flip ? "scaleX(-1)" : ""}`;
    if (o.opacity) el.style.opacity = o.opacity; if (o.stretch) { el.style.transformOrigin = `0 ${m.oy * sc}px`; el.style.left = x + "px"; el.style.transform = `rotate(${o.rot || 0}rad) scale(${o.stretch},1)`; }
    const t0 = performance.now(), ms = m.ms / (o.speed || 1), total = o.loop ? Infinity : ms * m.n * (o.loops || 1);
    const tick = (t) => { if (!el.isConnected) return; const e = t - t0; if (e >= total) { if (!o.keep) el.remove(); return; }
      const i = Math.floor(e / ms) % m.n; el.style.backgroundPosition = `${-(i % m.cols) * W}px ${-Math.floor(i / m.cols) * H}px`; requestAnimationFrame(tick); };
    requestAnimationFrame(tick); return el;
  }
  const later = (ms, fn) => setTimeout(fn, ms);
  function shot(from, to, sprite, big, color, done) {
    const f = $f(); if (!f) return done && done();
    const q = (sel) => f.parentNode.querySelector(sel); const A = q(from), Z = q(to); if (!A || !Z) return done && done();
    const [ax, ay] = ctr(A, f), [zx, zy] = ctr(Z, f);
    const d = put("", 900, ax, ay); if (!d) return done && done();
    d.classList.add("shot", "pix"); d.style.setProperty("--dx", zx - ax + "px"); d.style.setProperty("--dy", zy - ay + "px"); d.style.setProperty("--c", color || "#ffb347");
    if (!pfx(sprite, 0, 0, { parent: d, scale: big ? 2.4 : 1.8, loop: true, rot: Math.atan2(zy - ay, zx - ax) })) d.innerHTML = "<span>💥</span>";
    setTimeout(() => done && done(zx, zy), 520);
  }
  function span(from, to, name, scale, done) {      // เอฟเฟกต์ที่ลากจากผู้ร่ายไปเป้าหมาย (สายฟ้า/ลูกเวทมนตร์)
    const f = $f(); if (!f) return; const A = f.parentNode.querySelector(from), Z = f.parentNode.querySelector(to); if (!A || !Z) return;
    const [ax, ay] = ctr(A, f), [zx, zy] = ctr(Z, f), m = PFX_DATA[name]; if (!m) return;
    const dist = Math.hypot(zx - ax, zy - ay), st = Math.max(0.5, dist / (m.w * (scale || 1)));
    pfx(name, ax, ay, { scale: scale || 1, stretch: st, rot: Math.atan2(zy - ay, zx - ax) }); later(380, () => done && done(zx, zy));
  }
  const num = (txt, x, y, cls) => put(`<span class="fxn ${cls || ""}">${txt}</span>`, 1200, x, y);
  function flash(cls) { const fl = document.querySelector(".bt-field"); if (fl) { fl.classList.remove(cls); void fl.offsetWidth; fl.classList.add(cls); setTimeout(() => fl.classList.remove(cls), 600); } }
  const foot = (el, f) => { const a = el.getBoundingClientRect(), b = f.getBoundingClientRect(); return [a.left + a.width / 2 - b.left, a.bottom - b.top - 10]; };
  const COL = { alc_fire: "#ff7a3d", alc_boost: "#c18cff", alc_heal: "#5ee6a8", sci_shock: "#6ad7ff", sci_scan: "#7aa8ff", sci_heal: "#5ee6a8", gua_strike: "#ffd86b", gua_shield: "#6aa8ff", gua_heal: "#5ee6a8", see_dice: "#ffd86b", see_luck: "#8aff8a", see_heal: "#b0ffd8", gen_hit: "#ffb347", gen_focus: "#ffd86b", gen_heal: "#5ee6a8" };
  /* สกิล → เอฟเฟกต์ */
  const SKFX = {
    alc_fire: { shot: "fireball", hit: ["small-explosion", 0.9] },
    sci_shock: { span: "zap-hit", scale: 1.1 },
    gua_strike: { hit: ["sword-slash", 1.7], extra: ["hit-spark", 1.4] },
    see_dice: { span: "magic-missile", scale: 1.1 },
    gen_hit: { hit: ["blunt-hit", 1.7] },
  };
  const MONFX = { bubble: ["hit-spark", 1.5], rust: ["blunt-hit", 1.5], salt: ["hit-spark", 1.8], lemon: ["acid-splash", 1.4], fog: ["poison-cloud", 1.0] };
  function playSkill(ev) {
    const f = $f(); if (!f) return; const sk = ev.skill, col = COL[sk.key] || "#ffb347", root = f.parentNode, PL = root.querySelector(".bt-pl"), MO = root.querySelector(".bt-mo");
    const [px, py] = ctr(PL, f), [mx, my] = ctr(MO, f), [fx0, fy0] = foot(PL, f);
    const killed = S.bat.status === "won";
    S.hpDelay = 520;
    if (!ev.correct) { num("พลาด!", px, py - 60, "miss"); put('<span class="fizz">💨</span>', 900, px, py - 20); return; }
    if (sk.kind === "attack") {
      pop("lunge2", PL);
      const impact = (zx, zy) => {
        const fx = SKFX[sk.key] || SKFX.gen_hit; if (fx.hit) pfx(fx.hit[0], zx, zy, { scale: fx.hit[1] }); if (fx.extra) pfx(fx.extra[0], zx, zy, { scale: fx.extra[1] });
        if (ev.crit) pfx("crit-hit", zx, zy, { scale: 1.9 });
        pop("hurt", MO.querySelector(".bt-mimg,.bt-memo")); flash(ev.crit ? "flashbig" : "flash");
        num((ev.crit ? "💥 " : "") + "-" + ev.dmg, zx, zy - 50, ev.crit ? "crit" : "dmg");
        if (ev.fast) num("⚡ ตอบไว!", zx, zy - 86, "fast");
        if (killed) later(500, () => { pfx("shatter-death", zx, zy + 20, { scale: 2.2 }); MO.classList.add("dead"); later(350, () => pfx("collect-burst", zx, zy, { scale: 2 })); });
      };
      const fx = SKFX[sk.key] || SKFX.gen_hit;
      if (fx.shot) shot(".bt-pl", ".bt-mo", fx.shot, ev.crit, col, impact);
      else if (fx.span) span(".bt-pl", ".bt-mo", fx.span, fx.scale, impact);
      else later(250, () => impact(mx, my));
    } else if (sk.kind === "heal") {
      S.hpDelay = 400;
      pfx("heal-aoe", fx0, fy0 + 8, { scale: 1.3 }); num("+" + ev.heal + " HP", px, py - 50, "heal");
      put(Array.from({ length: 8 }, (_, i) => `<b class="up" style="--x:${(i - 4) * 12}px;--d:${i * 80}ms">${i % 2 ? "✚" : "✨"}</b>`).join(""), 1500, px, py + 20);
    } else {
      S.hpDelay = 0; pop("glow", PL); num(sk.emoji + " " + sk.name, px, py - 72, "buff");
      if (sk.effect === "weak" || sk.key === "sci_scan") pfx("curse", mx, my, { scale: 2 });
      else if (sk.key === "gua_shield") pfx("divine-shield", px, py, { scale: 2.4, loops: 2 });
      else if (sk.key === "see_luck") pfx("star-fall", px, py - 30, { scale: 1.5 });
      else pfx("rage", px, py, { scale: 2.2, loops: 2 });
    }
  }
  function playMonster(e, name, emoji) {
    const f = $f(); if (!f) return; const root = f.parentNode, PL = root.querySelector(".bt-pl"), key = ((S.bat.monster.image || "").match(/([a-z]+)\.png/) || [])[1];
    S.hpDelay = 520;
    span(".bt-mo", ".bt-pl", "magic-missile", 0.9, (zx, zy) => {
      if (e.taken <= 0) { num("🌀 หลบได้!", zx, zy - 50, "heal"); pfx("shield-block", zx, zy, { scale: 1.4 }); }
      else { const h = MONFX[key] || ["hit-spark", 1.5]; pfx(h[0], zx, zy, { scale: h[1] }); pop("hurt", PL.querySelector(".bt-spr")); flash("flashred"); num("-" + e.taken, zx, zy - 40, "dmg"); }
      if (e.hits > 0 && e.taken > 0) num("🛡️ ลดดาเมจ " + Math.round((80 * e.hits) / e.n) + "%", zx, zy - 74, "fast");
    });
  }
  function syncLoops() {   // เอฟเฟกต์วนต่อเนื่อง: ชาร์จสกิลระหว่างตอบคำถาม + ออร่าบัพที่ยังติดอยู่
    const b = S.bat, f = $f(); if (!b || !f || S.screen !== "fight" || b.status !== "active") return;
    const PL = f.parentNode.querySelector(".bt-pl"); if (!PL) return; const [px, py] = ctr(PL, f);
    if (b.phase === "question") pfx("spell-charge", px, py + 10, { scale: 1.7, loop: true, opacity: 0.9 });
    if ((b.buffs.shield || 0) > 0) pfx("divine-shield", px, py, { scale: 2.5, loop: true, opacity: 0.7 });
    if ((b.buffs.atk_up || 0) > 0 || (b.buffs.crit_up || 0) > 0) pfx("rage", px, py + 6, { scale: 2.3, loop: true, opacity: 0.55 });
  }

  /* ---------- หน้าจอ ---------- */
  function arenaPicker() {
    const d = S.data, cur = arNow(); if (!d.arenas || !d.arenas.length) return "";
    return `<div class="card"><div class="row"><h3 style="margin:0" class="grow">🏟️ เลือกสนามต่อสู้</h3><span class="pill">เลเวลของคุณ Lv.${d.level}</span></div>
      <div class="ar-grid">${d.arenas.map((a) => `<div class="ar-card t-${esc(a.theme)} ${cur && cur.key === a.key ? "on" : ""} ${a.locked ? "lock" : ""}" onclick="BATTLE.arena('${a.key}')">
        <div class="ae">${a.locked ? "🔒" : esc(a.emoji)}</div><b>${esc(a.name)}</b><small>${a.locked ? "ปลดล็อกที่ Lv." + a.min_level : "รางวัล ×" + (a.reward_pct / 100).toFixed(2).replace(/0$/, "")}</small></div>`).join("")}</div>
      ${cur ? `<p class="muted" style="margin:0">${esc(cur.descr || "")}</p>` : ""}</div>`;
  }
  function listView() {
    const d = S.data; if (!d) return '<div class="card"><p class="muted">กำลังโหลด…</p></div>';
    const left = Math.max(0, d.limit - d.used);
    return `<div class="card"><div class="row"><h3 style="margin:0" class="grow">⚔️ ล่ามอนสเตอร์เคมี</h3><button class="btn ghost small" onclick="BATTLE.exit()">‹ กลับ</button></div>
      <div class="run-info"><section><h4>🎮 วิธีเล่น</h4><ul><li>ตอบคำถามเพื่อใช้สกิล</li><li>มอนสเตอร์โจมตีกลับ ให้กดลูกศรลดดาเมจ</li></ul></section><section><h4>🏆 รางวัล</h4><ul><li>ชนะได้ EXP + เหรียญ</li><li>สุ่มดรอปไอเทม</li></ul></section></div>
      <p>${left > 0 ? `<span class="pill">🎁 รอบที่ได้รางวัลวันนี้เหลือ ${left}/${d.limit}</span>` : '<span class="pill">รอบที่ได้รางวัลวันนี้หมดแล้ว — เล่นฝึกได้ไม่จำกัด (ไม่ได้รางวัล)</span>'} <span class="pill">❤️ HP ${d.p_max}</span></p>
      <div class="bt-skills">${d.skills.map((s) => `<span class="bt-sk ${s.kind}" title="${esc(s.descr || "")}">${s.emoji} <b>${esc(s.name)}</b> <small>${KIND[s.kind][1]}</small></span>`).join("")}</div></div>
      ${arenaPicker()}
      <div class="bt-mgrid">${d.monsters.filter((m) => !d.arenas || !d.arenas.length || (m.arena || "lab") === (arNow() || {}).key).map((m) => `<div class="card bt-mcard">${mimg(m)}<h3>${esc(m.name)} <small class="muted">Lv.${m.level}</small></h3>
        <p class="muted" style="margin:2px 0">${esc(m.descr || "")}</p><p style="margin:4px 0"><span class="pill">❤️ ${m.hp}</span> <span class="pill">🗡️ ${m.atk}</span></p>
        <p class="muted" style="margin:2px 0 8px">รางวัล +${m.exp} EXP · +${m.coins} 🪙 · ดรอปไอเทม</p>
        <button class="btn gold" onclick="BATTLE.start('${m.id}')">⚔️ ท้าสู้</button></div>`).join("") || '<div class="card"><p class="muted">ยังไม่มีมอนสเตอร์ในระบบ</p></div>'}</div>`;
  }

  function fightView() {
    const b = S.bat, m = b.monster, me = D.student;
    const buffs = Object.entries(b.buffs || {}).filter(([, v]) => v > 0).map(([k, v]) => `<span class="bt-buff">${BUFF[k] || k} ×${v}</span>`).join("");
    const ph = b.phase, cs = ph === "question" && b.q ? (b.skills.find((x) => x.key === b.q.skill) || {}) : null;
    const fm = S.shown.m, fp = S.shown.p; S.shown = { m: b.m_hp, p: b.p_hp };
    const th = m.theme || "lab";
    const arena = `<div class="card bt-field ar-${esc(th)} ${cs ? "charge" : ""} ${ph === "defend" ? "alert" : ""}">
      ${skyHtml(th)}<div class="bt-floor"></div>${m.arena_name ? `<div class="bt-arname">${esc(m.arena_name)}</div>` : ""}
      <div class="bt-plate bt-pm"><b>${esc(m.name)}</b> <small>Lv.${m.level}</small>${hp(b.m_hp, b.m_max, "mon", fm, S.hpDelay)}</div>
      <div class="bt-mo ${ph === "defend" ? "lunge" : ""}"><div class="bt-shadow"></div>${mimg(m, "float")}</div>
      <div class="bt-pl ${cs ? "charging" : ""}"><div class="bt-shadow"></div>${sprite(me)}${cs ? `<div class="bt-chg">${cs.emoji}</div>` : ""}</div>
      <div class="bt-plate bt-pp"><b>${esc(me.name)}</b> <small>เทิร์น ${b.turn}</small>${hp(b.p_hp, b.p_max, "me", fp, S.hpDelay)}<div class="bt-buffs">${buffs}</div></div>
      <div id="btfx" class="bt-fxl"></div></div>`;
    if (S.fb) return arena + fbView();
    if (b.status !== "active") return arena + resultView();
    if (b.phase === "question") return arena + questionView();
    if (b.phase === "defend") return arena + defendView();
    const skills = b.skills.map((s) => `<button class="bt-skill ${s.kind}" ${s.left > 0 || S.busy ? "disabled" : ""} onclick="BATTLE.skill('${s.key}')">
        <span class="bt-sico">${s.emoji}</span><b>${esc(s.name)}</b><small>${KIND[s.kind][1]}${s.kind !== "buff" ? ` ${s.power}` : ""}${s.left > 0 ? ` · รอ ${s.left} เทิร์น` : s.cd ? ` · CD ${s.cd}` : ""}</small>
        <em>${esc(s.descr || "")}</em></button>`).join("");
    return arena + `<div class="card"><div class="row"><b class="grow">${S.msg ? esc(S.msg) : "เลือกสกิลของคุณ"}</b><button class="btn ghost small" onclick="BATTLE.flee()">🏃 หนี</button></div>
      <p class="muted" style="margin:4px 0 8px">เลือกสกิล แล้วตอบคำถามให้ถูก (ภายใน 20 วิ) สกิลถึงจะออกผล · ตอบภายใน 8 วิ ดาเมจโจมตี +25% ⚡</p><div class="bt-skillrow">${skills}</div>
      ${b.rewarded ? "" : '<p class="muted" style="margin:8px 0 0">โหมดฝึก: รอบนี้ไม่ได้รางวัล</p>'}</div>`;
  }

  function questionView() {
    const q = S.bat.q, sk = S.bat.skills.find((s) => s.key === q.skill) || {};
    const left = Math.max(0.5, QSECS - (q.elapsed || 0));
    return `<div class="card gm-q"><div class="row"><span class="pill">${sk.emoji || ""} ${esc(sk.name || "")}</span><span class="muted grow">${esc(q.topic)}</span><span class="pill" id="bqt">⏱️ ${QSECS}</span></div>
      <div class="bt-timer"><i style="animation-duration:${left}s"></i></div>
      <h3 style="margin:12px 0">${esc(q.question)}</h3>
      <div class="gm-choices">${q.choices.map((c, i) => `<button class="gm-choice" ${S.busy ? "disabled" : ""} onclick="BATTLE.pick(${i})"><b>${"กขคง"[i]}</b> ${esc(c)}</button>`).join("")}</div></div>`;
  }
  function fbView() {
    const f = S.fb, q = f.q, sk = f.skill; let txt;
    if (!f.correct) txt = `❌ ตอบผิด — ${sk.emoji} ${sk.name} พลาด!`;
    else if (sk.kind === "attack") txt = `${sk.emoji} ${sk.name}! ดาเมจ ${f.dmg}${f.crit ? " 💥 คริติคอล!" : ""}${f.fast ? " ⚡ ตอบไว +25%" : ""}`;
    else if (sk.kind === "heal") txt = `${sk.emoji} ${sk.name}! ฟื้นฟู +${f.heal} HP`;
    else txt = `${sk.emoji} ${sk.name}! ได้รับบัพ`;
    const nextTxt = S.bat.status !== "active" ? "ดูผลการต่อสู้ ▶" : "ป้องกันการโจมตี ▶";
    return `<div class="card center ${f.correct ? "bt-ok" : "bt-bad"}"><h2 style="margin:0">${esc(txt)}</h2>
      <p class="muted" style="margin:8px 0">${f.correct ? "✅ ตอบถูก" : `คำตอบที่ถูก: <b style="color:var(--mint)">${"กขคง"[f.answer]}. ${esc(q.choices[f.answer])}</b>`}</p>
      ${f.explain ? `<p class="muted">💡 ${esc(f.explain)}</p>` : ""}<button class="btn gold" onclick="BATTLE.next()">${nextTxt}</button></div>`;
  }
  function defendView() {
    const d = S.def, p = S.bat.pend; if (!d) return '<div class="card"><p class="muted">…</p></div>';
    const cur = d.seq[d.i];
    const marks = d.seq.map((_, i) => `<span class="bt-mk ${d.marks[i] === 1 ? "ok" : d.marks[i] === 0 ? "no" : i === d.i ? "now" : ""}">${d.marks[i] === 1 ? "✔" : d.marks[i] === 0 ? "✖" : "•"}</span>`).join("");
    const big = d.state === "go" ? `<div class="bt-arrow go">${ARW[cur]}<div class="bt-ring" style="animation-duration:${d.win || curWin()}ms"></div></div>`
      : d.state === "ok" ? '<div class="bt-arrow ok">✔</div>' : d.state === "miss" ? '<div class="bt-arrow no">✖</div>'
      : d.state === "send" ? '<div class="bt-arrow">…</div>' : '<div class="bt-arrow">⚠️</div>';
    return `<div class="card center bt-def"><h3 style="margin:0">⚠️ ${esc(p.name)}! ดาเมจ ~${p.dmg}</h3>
      <p class="muted" style="margin:4px 0 8px">กดลูกศรให้ตรงตามที่ปรากฏ (คีย์บอร์ด ← ↑ → ↓ หรือแตะปุ่มด้านล่าง) ยิ่งถูกมาก ดาเมจยิ่งลด (สูงสุด 80%) · มอนสเตอร์ยิ่งเก่ง เวลากดยิ่งสั้น (${((d.win || curWin()) / 1000).toFixed(1)} วิ/ลูกศร)</p>
      <div class="bt-marks">${marks}</div>${big}
      <div class="bt-pad"><button onclick="BATTLE.arrow('U')">⬆️</button><div><button onclick="BATTLE.arrow('L')">⬅️</button><button onclick="BATTLE.arrow('D')">⬇️</button><button onclick="BATTLE.arrow('R')">➡️</button></div></div></div>`;
  }
  function resultView() {
    const b = S.bat, win = b.status === "won", dr = S.drop, m = b.monster;
    if (S.fxFor !== b.id && b.status !== "fled") { S.fxFor = b.id; setTimeout(() => {
      if (win) { FX.victory(); if (dr) { FX.screen("loot-beam", 0.5, 0.5, { scale: 3 }); FX.later(400, () => FX.screen("chest-open", 0.5, 0.55, { scale: 3 })); } }
      else FX.screen("curse", 0.5, 0.45, { scale: 3 }); }, 400); }
    if (b.status === "fled") return `<div class="card center"><p>หนีจากการต่อสู้แล้ว</p><button class="btn" onclick="BATTLE.back()">กลับ</button></div>`;
    return `<div class="card center gm-res ${win ? "perfect" : ""}"><div style="font-size:54px">${win ? "🏆" : "💀"}</div>
      <h2>${win ? `ปราบ ${esc(m.name)} สำเร็จ!` : `พ่ายแพ้ให้ ${esc(m.name)}`}</h2>
      <p>${b.rewarded ? (b.exp || b.coins ? `<span class="pill">+${b.exp} EXP</span> ${b.coins ? `<span class="pill">+${b.coins} 🪙</span>` : ""}` : '<span class="pill">ไม่มีรางวัลรอบนี้</span>')
        : '<span class="pill">โหมดฝึก — ไม่ได้รางวัล</span>'}</p>
      ${dr ? `<div class="bt-drop ${dr.rarity}">${dr.image ? `<img src="${esc(dr.image)}" alt="" onerror="this.remove()">` : ""}<div>🎁 ดรอป! <b>${esc(dr.emoji || "")} ${esc(dr.name)}</b> <span class="tag">${dr.rarity}</span></div></div>`
        : win && b.rewarded ? '<p class="muted">รอบนี้ไม่มีไอเทมดรอป — ลองใหม่นะ</p>' : ""}
      ${!win && b.rewarded && b.exp ? '<p class="muted">รับ EXP ให้กำลังใจจากข้อที่ตอบถูก</p>' : ""}
      <div class="row" style="justify-content:center"><button class="btn gold" onclick="BATTLE.start('${m.id}')">⚔️ สู้อีกครั้ง</button><button class="btn ghost" onclick="BATTLE.back()">เลือกมอนสเตอร์</button></div></div>`;
  }

  const view = () => (S.screen === "list" || !S.bat ? listView() : fightView());
  return { arena: pickArena, sprite, hp, skyHtml, pfx, num, pop, flash, shot, span, put, ctr, later, SKFX, COL, open, view, start, skill: useSkill, pick: answer, next: afterFb, arrow: tapArrow, flee, back, exit };
})();
