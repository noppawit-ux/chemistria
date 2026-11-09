/* มินิเกม: ห้องฝึกเวทย์ผสมธาตุ — แตะอะตอมใส่หม้อต้มให้ตรงสูตรสาร แล้วกด “ร่ายเวทย์” */
const SPELL = (() => {
  const SUB = "₀₁₂₃₄₅₆₇₈₉";
  const sub = (n) => (n > 1 ? String(n).replace(/\d/g, (d) => SUB[d]) : "");
  const fm = (a) => Object.entries(a).map(([k, v]) => k + sub(v)).join("");
  const EN = { H: "ไฮโดรเจน", He: "ฮีเลียม", C: "คาร์บอน", N: "ไนโตรเจน", O: "ออกซิเจน", F: "ฟลูออรีน", Na: "โซเดียม", Mg: "แมกนีเซียม", Al: "อะลูมิเนียม", Si: "ซิลิคอน", P: "ฟอสฟอรัส", S: "กำมะถัน", Cl: "คลอรีน", K: "โพแทสเซียม", Ca: "แคลเซียม", Fe: "เหล็ก", Cu: "ทองแดง", Zn: "สังกะสี", Mn: "แมงกานีส", I: "ไอโอดีน" };
  // [ชื่อเวทย์, ชื่อสาร, อะตอม]
  const R = {
    easy: [["เวทย์วารี", "น้ำ", { H: 2, O: 1 }], ["เวทย์เกลือ", "โซเดียมคลอไรด์", { Na: 1, Cl: 1 }], ["ลมหายใจมังกร", "คาร์บอนไดออกไซด์", { C: 1, O: 2 }],
      ["ไอหมอกกรด", "ไฮโดรเจนคลอไรด์", { H: 1, Cl: 1 }], ["แก๊สชีวิต", "ออกซิเจน", { O: 2 }], ["ลูกโป่งลอยฟ้า", "ไฮโดรเจน", { H: 2 }],
      ["ควันพิษเงียบ", "คาร์บอนมอนอกไซด์", { C: 1, O: 1 }], ["เปลวไฟเมทาโนส", "มีเทน", { C: 1, H: 4 }], ["กลิ่นแอมโมนิกา", "แอมโมเนีย", { N: 1, H: 3 }],
      ["ผงปูนเผา", "แคลเซียมออกไซด์", { Ca: 1, O: 1 }], ["ผงเมจิกขาว", "แมกนีเซียมออกไซด์", { Mg: 1, O: 1 }]],
    mid: [["ไฟสะเทินดำ", "โซเดียมไฮดรอกไซด์", { Na: 1, O: 1, H: 1 }], ["น้ำยาฟอกเวท", "ไฮโดรเจนเปอร์ออกไซด์", { H: 2, O: 2 }], ["ผงเกลือสองประกาย", "แคลเซียมคลอไรด์", { Ca: 1, Cl: 2 }],
      ["กลิ่นไข่เน่า", "ไฮโดรเจนซัลไฟด์", { H: 2, S: 1 }], ["ควันกำมะถัน", "ซัลเฟอร์ไดออกไซด์", { S: 1, O: 2 }], ["ผงฟูมหัศจรรย์", "โซเดียมไฮโดรเจนคาร์บอเนต", { Na: 1, H: 1, C: 1, O: 3 }],
      ["สนิมแดง", "เหล็ก(III)ออกไซด์", { Fe: 2, O: 3 }], ["เกราะอะลูมินา", "อะลูมิเนียมออกไซด์", { Al: 2, O: 3 }], ["ไอสีม่วง", "ไอโอดีนโมเลกุล", { I: 2 }],
      ["เลือดมังกรเขียว", "คอปเปอร์(II)ออกไซด์", { Cu: 1, O: 1 }], ["แก๊สหัวเราะ", "ไดไนโตรเจนมอนอกไซด์", { N: 2, O: 1 }]],
    hard: [["กรดแห่งอสูร", "กรดซัลฟิวริก", { H: 2, S: 1, O: 4 }], ["หินปูนโบราณ", "แคลเซียมคาร์บอเนต", { Ca: 1, C: 1, O: 3 }], ["น้ำกรดสลาย", "กรดไนตริก", { H: 1, N: 1, O: 3 }],
      ["น้ำหวานสวรรค์", "กลูโคส", { C: 6, H: 12, O: 6 }], ["สุราเวทย์", "เอทานอล", { C: 2, H: 6, O: 1 }], ["กรดเปรี้ยวนิรันดร์", "กรดแอซีติก", { C: 2, H: 4, O: 2 }],
      ["ผงม่วงชำระล้าง", "โพแทสเซียมเปอร์แมงกาเนต", { K: 1, Mn: 1, O: 4 }], ["ผลึกวิเศษสีฟ้า", "คอปเปอร์(II)ซัลเฟต", { Cu: 1, S: 1, O: 4 }], ["ปุ๋ยเทพ", "แอมโมเนียมไนเตรต", { N: 2, H: 4, O: 3 }],
      ["ผงฟอสฟอรัสสว่าง", "ไดฟอสฟอรัสเพนทอกไซด์", { P: 2, O: 5 }], ["ยาลดกรดเวท", "แมกนีเซียมไฮดรอกไซด์", { Mg: 1, O: 2, H: 2 }]],
  };
  /* โจทย์โครงสร้างลิวอิส: [ชื่อผนึก, ชื่อสาร, สูตร, อะตอมกลาง, [[อะตอมรอบ, อันดับพันธะ, คู่โดดเดี่ยวของอะตอมรอบ]...], คู่โดดเดี่ยวของอะตอมกลาง] */
  const LW = {
    easy: [["ผนึกสายฟ้า", "ไฮโดรเจนคลอไรด์", "HCl", "H", [["Cl", 1, 3]], 0], ["ผนึกวารี", "น้ำ", "H₂O", "O", [["H", 1, 0], ["H", 1, 0]], 2], ["ผนึกควันขาว", "แอมโมเนีย", "NH₃", "N", [["H", 1, 0], ["H", 1, 0], ["H", 1, 0]], 1],
      ["ผนึกเปลวไฟ", "มีเทน", "CH₄", "C", [["H", 1, 0], ["H", 1, 0], ["H", 1, 0], ["H", 1, 0]], 0], ["ผนึกลูกโป่ง", "ไฮโดรเจน", "H₂", "H", [["H", 1, 0]], 0]],
    mid: [["ผนึกมังกร", "คาร์บอนไดออกไซด์", "CO₂", "C", [["O", 2, 2], ["O", 2, 2]], 0], ["ผนึกชีวิต", "ออกซิเจน", "O₂", "O", [["O", 2, 2]], 2], ["ผนึกอากาศ", "ไนโตรเจน", "N₂", "N", [["N", 3, 1]], 1],
      ["ผนึกไข่เน่า", "ไฮโดรเจนซัลไฟด์", "H₂S", "S", [["H", 1, 0], ["H", 1, 0]], 2], ["ผนึกโบรอน", "โบรอนไตรฟลูออไรด์", "BF₃", "B", [["F", 1, 3], ["F", 1, 3], ["F", 1, 3]], 0], ["ผนึกกัดแก้ว", "ไฮโดรเจนฟลูออไรด์", "HF", "H", [["F", 1, 3]], 0]],
    hard: [["ผนึกพิษเงียบ", "ไฮโดรเจนไซยาไนด์", "HCN", "C", [["H", 1, 0], ["N", 3, 1]], 0], ["ผนึกน้ำยาดอง", "ฟอร์มาลดีไฮด์", "CH₂O", "C", [["H", 1, 0], ["H", 1, 0], ["O", 2, 2]], 0],
      ["ผนึกตัวทำละลาย", "คาร์บอนเตตระคลอไรด์", "CCl₄", "C", [["Cl", 1, 3], ["Cl", 1, 3], ["Cl", 1, 3], ["Cl", 1, 3]], 0], ["ผนึกแก๊สสงคราม", "คาร์บอนิลคลอไรด์", "COCl₂", "C", [["O", 2, 2], ["Cl", 1, 3], ["Cl", 1, 3]], 0],
      ["ผนึกไนโตรเจนฟลูออไรด์", "ไนโตรเจนไตรฟลูออไรด์", "NF₃", "N", [["F", 1, 3], ["F", 1, 3], ["F", 1, 3]], 1], ["ผนึกกลิ่นฉุน", "คาร์บอนไดซัลไฟด์", "CS₂", "C", [["S", 2, 2], ["S", 2, 2]], 0]],
  };
  const LV = { easy: { label: "ง่าย", n: 5, lw: 1, hint: "formula" }, mid: { label: "กลาง", n: 6, lw: 2, hint: "elems" }, hard: { label: "ยาก", n: 7, lw: 3, hint: "name" } };
  const POS = [[232, 110], [68, 110], [150, 32], [150, 188]];     // ตำแหน่งอะตอมรอบ (ขวา ซ้าย บน ล่าง)
  const CEN = [150, 110];
  const GRP = (k) => (["Na", "Mg", "Al", "K", "Ca", "Fe", "Cu", "Zn", "Mn"].includes(k) ? "m" : ["F", "Cl", "I", "Br"].includes(k) ? "h" : "n");
  const ALL = Object.keys(EN);
  const S = { screen: "home", level: "mid", spells: [], i: 0, bowl: {}, wrong: 0, hints: 0, shown: false, t0: 0, msg: "", res: null, busy: false, pal: [], over: false, combo: 0, best: 0, lw: null };
  const shuffle = (a) => { a = a.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; };
  const paint = () => GAMES.paint();
  const cur = () => S.spells[S.i];
  /* เอฟเฟกต์ในกล่อง: วางในพิกัดของกล่อง (หม้อ/กระดานลิวอิส) แล้วตัดขอบ ไม่ให้ล้นออกนอกกล่อง · fx=สัดส่วน 0–1 ของกว้าง/สูงกล่อง */
  function box(el, name, fx = 0.5, fy = 0.5, o = {}) {
    if (!el) return null; el.style.position = "relative"; el.style.overflow = "hidden";
    return FX.play(name, el.clientWidth * fx + (o.dx || 0), el.clientHeight * fy + (o.dy || 0), { ...o, parent: el });
  }
  const same = (a, b) => { const k = new Set([...Object.keys(a), ...Object.keys(b)]); for (const x of k) if ((a[x] || 0) !== (b[x] || 0)) return false; return true; };

  async function open() { S.screen = "home"; S.st = null; GAMES.setMode("spell"); paint(); try { S.st = await rpc("spell_status", { p_token: tk() }); } catch (e) {} paint(); }
  function start(level) {
    GB("spell");
    const L = LV[level]; S.level = level; S.i = 0; S.wrong = 0; S.hints = 0; S.over = false; S.busy = false; S.combo = 0; S.best = 0;
    // ผสมโจทย์สูตรผสมธาตุกับโจทย์โครงสร้างลิวอิส สลับตำแหน่งแบบสุ่ม
    const sp = shuffle(R[level]).slice(0, L.n - L.lw).map((x) => ({ t: "mix", d: x })), lw = shuffle(LW[level]).slice(0, L.lw).map((x) => ({ t: "lew", d: x }));
    S.spells = shuffle(sp.concat(lw));
    S.t0 = Date.now(); S.screen = "play"; S.msg = ""; setPal(); paint();
  }
  function setPal() {
    const c = cur(); S.bowl = {}; S.shown = false; S.lw = null;
    if (c.t === "lew") { const d = c.d; S.lw = { b: d[4].map(() => 1), a: [0].concat(d[4].map(() => 0)) }; return; }   // a[0] = อะตอมกลาง
    const s = c.d;
    const need = Object.keys(s[2]), decoy = shuffle(ALL.filter((x) => !need.includes(x))).slice(0, Math.max(2, 7 - need.length));
    S.pal = shuffle(need.concat(decoy));
  }
  /* ---------- เอฟเฟกต์ ---------- */
  const $q = (q) => document.querySelector(q);
  function fly(fromEl, toEl, txt) {                       // อะตอมบินจากปุ่มเข้าหม้อ
    if (!fromEl || !toEl || !fromEl.getBoundingClientRect) return;
    const a = fromEl.getBoundingClientRect(), b = toEl.getBoundingClientRect(), el = document.createElement("div");
    el.className = "sp-fly"; el.textContent = txt; el.style.left = a.left + a.width / 2 - 20 + "px"; el.style.top = a.top + a.height / 2 - 20 + "px";
    document.body.appendChild(el);
    const dx = b.left + b.width / 2 - (a.left + a.width / 2), dy = b.top + b.height / 2 - (a.top + a.height / 2);
    if (el.animate) { const an = el.animate([{ transform: "translate(0,0) scale(1)", opacity: 1 }, { transform: `translate(${dx * 0.5}px,${dy * 0.5 - 40}px) scale(1.3)`, opacity: 1, offset: 0.5 }, { transform: `translate(${dx}px,${dy}px) scale(.4)`, opacity: 0.2 }], { duration: 420, easing: "ease-in" }); an.onfinish = () => el.remove(); } else el.remove();
    setTimeout(() => el.remove(), 600);
  }
  function popText(t, cls) {
    const w = $q(".sp-play"); if (!w) return; const e = document.createElement("div"); e.className = "sp-pop " + (cls || ""); e.textContent = t; w.appendChild(e); setTimeout(() => e.remove(), 1300);
  }
  const cls = (q, c, ms) => { const e = $q(q); if (!e) return; e.classList.remove(c); void e.offsetWidth; e.classList.add(c); setTimeout(() => e.classList.remove(c), ms || 600); };
  function okFx(bx) {
    S.combo++; S.best = Math.max(S.best, S.combo);
    cls(".sp-play", "sp-flash", 700); cls(bx === $q(".sp-lew") ? ".sp-lew" : ".sp-pot", "sp-glow", 900);
    SFX.play("ok");
    box(bx, "spell-charge", 0.5, 0.62, { scale: 1.1 });
    setTimeout(() => { box(bx, "mana-burst", 0.5, 0.6, { scale: 1.5 }); box(bx, "collect-burst", 0.3, 0.55, { scale: 1.1 }); box(bx, "collect-burst", 0.7, 0.55, { scale: 1.1 }); }, 200);
    if (S.combo >= 2) { popText("🔥 COMBO ×" + S.combo, "combo"); setTimeout(() => { box(bx, S.combo >= 4 ? "firework-burst" : "star-fall", 0.5, 0.7, { scale: 1.0 }); SFX.play("star"); }, 380); }
    else popText("✨ สำเร็จ!", "good");
  }
  function badFx(bx) {
    S.combo = 0; cls(".sp-play", "sp-shake", 500); cls(bx === $q(".sp-lew") ? ".sp-lew" : ".sp-pot", "sp-boom", 600);
    SFX.play("bad"); box(bx, "small-explosion", 0.5, 0.75, { scale: 0.9 }); box(bx, "hit-spark", 0.5, 0.5, { scale: 1.2 }); popText("💥 พลาด!", "bad");
  }

  /* ---------- สูตรผสมธาตุ ---------- */
  function add(sym, btn) { if (S.over || S.busy) return; S.bowl[sym] = (S.bowl[sym] || 0) + 1; S.msg = ""; const pot = $q(".sp-pot"); fly(btn, pot, sym); paint(); cls(".sp-pot", "sp-pulse", 350); box($q(".sp-pot"), "collect-burst", 0.5, 0.7, { scale: 0.9 }); }
  function remove(sym) { if (S.over || S.busy) return; if (S.bowl[sym] > 1) S.bowl[sym]--; else delete S.bowl[sym]; paint(); }
  function clear() { if (S.busy) return; if (S.lw) { S.lw = { b: S.lw.b.map(() => 1), a: S.lw.a.map(() => 0) }; } else S.bowl = {}; S.msg = ""; paint(); }
  function hint() { if (S.shown || S.busy) return; S.shown = true; S.hints++; paint(); }

  /* ---------- โครงสร้างลิวอิส ---------- */
  function lwBond(i) { if (S.over || S.busy) return; S.lw.b[i] = (S.lw.b[i] % 3) + 1; S.msg = ""; paint(); cls(".sp-lew", "sp-pulse", 300); const e = $q(".sp-lew"), pr = (POS[i][0] + CEN[0]) / 2 / 300, py = (POS[i][1] + CEN[1]) / 2 / 220; box(e, "zap-hit", 0.05 + pr * 0.9, 0.12 + py * 0.78, { scale: 0.7 }); SFX.play("zap"); }
  function lwAtom(i) { if (S.over || S.busy) return; S.lw.a[i] = (S.lw.a[i] + 1) % 5; S.msg = ""; paint(); const e = $q(".sp-lew"), ax = (i ? POS[i - 1][0] : CEN[0]) / 300, ay = (i ? POS[i - 1][1] : CEN[1]) / 220; box(e, "collect-burst", 0.05 + ax * 0.9, 0.12 + ay * 0.78, { scale: 0.8 }); }
  const lwTotal = () => S.lw.b.reduce((x, y) => x + y * 2, 0) + S.lw.a.reduce((x, y) => x + y * 2, 0);
  const lwWant = (d) => d[4].reduce((x, t) => x + t[1] * 2 + t[2] * 2, 0) + d[5] * 2;
  const lwOk = (d) => S.lw.a[0] === d[5] && d[4].every((t, i) => S.lw.b[i] === t[1] && S.lw.a[i + 1] === t[2]);

  async function cast() {
    const c = cur(); if (S.over || S.busy || !c) return;
    if (c.t === "mix" && !Object.keys(S.bowl).length) return;
    const pot = c.t === "mix" ? $q(".sp-pot") : $q(".sp-lew");
    const ok = c.t === "mix" ? same(S.bowl, c.d[2]) : lwOk(c.d);
    if (ok) {
      S.busy = true; S.msg = c.t === "mix" ? "✨ ร่ายเวทย์สำเร็จ! " + c.d[1] + " (" + fm(c.d[2]) + ")" : "🔓 ปลดผนึกสำเร็จ! " + c.d[1] + " (" + c.d[2] + ")"; paint();
      okFx(c.t === "mix" ? $q(".sp-pot") : $q(".sp-lew"));
      setTimeout(async () => { S.i++; if (S.i >= S.spells.length) return finish(); setPal(); S.busy = false; paint(); }, 1000);
    } else {
      S.wrong++; S.msg = c.t === "mix" ? "💥 สูตรยังไม่ถูก — หม้อระเบิดเบาๆ ลองปรับอะตอมใหม่" : "💥 โครงสร้างยังไม่ถูก — ตรวจพันธะและคู่อิเล็กตรอนไม่ใช้ร่วม (ตรวจจำนวนอิเล็กตรอนรวม)"; paint();
      badFx($q(c.t === "mix" ? ".sp-pot" : ".sp-lew"));
    }
  }
  async function finish() {
    S.over = true; const n = S.spells.length, secs = Math.max(n * 2, Math.round((Date.now() - S.t0) / 1000));
    const score = Math.max(10, Math.min(100, Math.round(100 - S.wrong * 8 - S.hints * 6 - Math.max(0, secs - n * 18))));
    try {
      const r = await rpc("spell_submit", { p_token: tk(), p_score: score, p_spells: n, p_seconds: secs });
      S.res = { ...r, secs, wrong: S.wrong, hints: S.hints, level: S.level, combo: S.best }; S.screen = "res"; await load();
      setTimeout(() => { if (score >= 90) { FX.victory(); SFX.play("win"); } else FX.victory(); }, 300);
    } catch (e) { toast(e.message); S.screen = "home"; }
    S.busy = false; go("game");
  }
  const quit = () => { if (S.screen === "play" && !confirm("ออกจากเกม? ความคืบหน้าจะไม่ถูกบันทึก")) return; S.screen = "home"; S.over = true; GAMES.home(); };

  function view() {
    if (S.screen === "play") return playView();
    if (S.screen === "res") return resView();
    const t = S.st;
    return `<div class="card center"><div class="gm-ico">🔮</div><h3>ห้องฝึกเวทย์ผสมธาตุ</h3>
      <div class="run-info">
        <section><h4>🎮 วิธีเล่น</h4><ul><li>คาถาแต่ละบทคือสารเคมี!</li><li>ผสมอะตอมในหม้อให้ตรงสูตร</li><li>ปลดผนึกด้วยการวาดโครงสร้างลิวอิส</li><li>ยิ่งเร็วและผิดน้อย ยิ่งได้คะแนนสูง</li></ul></section>
        <section><h4>📊 ระดับความยาก</h4><ul><li><b>ง่าย:</b> เห็นสูตร</li><li><b>กลาง:</b> เห็นเฉพาะธาตุที่ใช้</li><li><b>ยาก:</b> เห็นแค่ชื่อสาร (ขอใบ้ได้ แต่หักคะแนน)</li></ul></section>
        ${t ? `<section><h4>🏆 รางวัล</h4><ul><li>สูงสุด <b>+${t.max_exp} EXP</b>/รอบ</li><li>ได้รางวัล ${t.max_plays} รอบ/วัน (เล่นแล้ว ${Math.min(t.plays, t.max_plays)}/${t.max_plays})</li>${t.best != null ? `<li>ดีที่สุด ${t.best}</li>` : ""}</ul></section>` : ""}
      </div>
      <div class="row" style="justify-content:center">${Object.entries(LV).map(([k, l]) => `<button class="btn small ${k === "mid" ? "gold" : "ghost"}" onclick="SPELL.start('${k}')">${l.label} (${l.n} โจทย์)</button>`).join("")}</div>
      <button class="btn ghost small" onclick="GAMES.home()">กลับ</button></div>`;
  }
  function lewSvg(d) {
    const L = S.lw, cx = CEN[0], cy = CEN[1], R0 = 20, dots = (x, y, n, big) => { let o = ""; const off = [[-14, -14], [14, -14], [-14, 14], [14, 14]]; for (let k = 0; k < n; k++) { const [ox, oy] = off[k]; const ho = k % 2 === 0; o += `<circle class="lp" cx="${x + ox + (ho ? -3 : -3)}" cy="${y + oy - 3}" r="2.6"/><circle class="lp" cx="${x + ox + 3}" cy="${y + oy + 3}" r="2.6"/>`; } return o; };
    let svg = `<svg viewBox="0 0 300 220" class="sp-lew-svg">`;
    d[4].forEach((t, i) => {
      const [x, y] = POS[i], n = L.b[i], vert = Math.abs(x - cx) < 5, ox = vert ? 5 : 0, oy = vert ? 0 : 5;
      for (let k = 0; k < n; k++) { const off = (k - (n - 1) / 2) * 7; svg += `<line class="bd" x1="${cx + (vert ? off : 0) + (x > cx ? R0 : x < cx ? -R0 : 0)}" y1="${cy + (vert ? (y > cy ? R0 : -R0) : off)}" x2="${x + (vert ? off : x > cx ? -R0 : R0)}" y2="${y + (vert ? (y > cy ? -R0 : R0) : off)}"/>`; }
      svg += `<line class="hit" data-b="${i}" x1="${cx}" y1="${cy}" x2="${x}" y2="${y}" onclick="SPELL.bond(${i})"/>`;
    });
    svg += `<g class="atm" onclick="SPELL.atom(0)"><circle cx="${cx}" cy="${cy}" r="${R0}"/><text x="${cx}" y="${cy + 6}">${d[3]}</text></g>${dots(cx, cy, L.a[0])}`;
    d[4].forEach((t, i) => { const [x, y] = POS[i]; svg += `<g class="atm" onclick="SPELL.atom(${i + 1})"><circle cx="${x}" cy="${y}" r="${R0}"/><text x="${x}" y="${y + 6}">${t[0]}</text></g>${dots(x, y, L.a[i + 1])}`; });
    return svg + "</svg>";
  }
  function playView() {
    const c = cur(), L = LV[S.level], n = S.spells.length;
    const head = `<div class="row"><span class="pill">โจทย์ที่ ${Math.min(S.i + 1, n)}/${n}</span><span class="pill">ผิด ${S.wrong}</span>${S.combo >= 2 ? `<span class="pill sp-cb">🔥 คอมโบ ×${S.combo}</span>` : ""}<span class="grow"></span><button class="btn ghost small" onclick="SPELL.quit()">ออก</button></div>`;
    if (c.t === "lew") {
      const d = c.d, tot = lwTotal(), want = lwWant(d), ok = tot === want;
      const info = L.hint === "name" && !S.shown ? '<span class="muted">ใช้ความรู้ของคุณ! (กด 💡 เพื่อขอใบ้ −6 คะแนน)</span>' : `อิเล็กตรอนวาเลนซ์รวมของสาร = <b class="sp-f">${want}</b> ตัว`;
      return `<div class="card sp-play">${head}
        <div class="sp-scroll lew"><div class="sp-spell">🔒 ${esc(d[0])}</div><div>จงวาด<b>โครงสร้างลิวอิส</b>ของ <b>${esc(d[1])}</b> ${L.hint === "name" && !S.shown ? "" : `(${d[2]})`}</div><div class="sp-clue">${info}</div></div>
        <div class="sp-lew"><div class="sp-lew-note">แตะ<b>เส้นพันธะ</b> = เปลี่ยนเดี่ยว/คู่/สาม · แตะ<b>อะตอม</b> = เพิ่มคู่อิเล็กตรอนไม่ใช้ร่วม (●●) ได้ 0–4 คู่</div>${lewSvg(d)}
          <div class="sp-lew-cnt ${ok ? "ok" : ""}">อิเล็กตรอนที่วาดแล้ว ${tot}${L.hint !== "name" || S.shown ? ` / ${want}` : ""} ตัว</div></div>
        <p class="sp-msg">${S.msg}</p>
        <div class="row" style="justify-content:center;margin-top:10px"><button class="btn ghost small" onclick="SPELL.clear()">🧹 รีเซ็ต</button>
          ${L.hint === "name" ? `<button class="btn ghost small" ${S.shown ? "disabled" : ""} onclick="SPELL.hint()">💡 ใบ้</button>` : ""}
          <button class="btn gold" onclick="SPELL.cast()">🔓 ปลดผนึก</button></div></div>`;
    }
    const s = c.d;
    const clue = L.hint === "formula" ? `สูตร: <b class="sp-f">${fm(s[2])}</b>` : L.hint === "elems" ? `ธาตุที่ใช้: ${Object.keys(s[2]).map((k) => `<b>${k}</b> (${EN[k]})`).join(" · ")}` : (S.shown ? `สูตร: <b class="sp-f">${fm(s[2])}</b>` : '<span class="muted">ใช้ความรู้ของคุณ! (กด 💡 เพื่อขอใบ้ −6 คะแนน)</span>');
    const bowl = Object.keys(S.bowl).length ? Object.entries(S.bowl).map(([k, v]) => `<button class="sp-atom g-${GRP(k)}" onclick="SPELL.remove('${k}')" title="แตะเพื่อเอาออก 1 ตัว">${k}<sup>×${v}</sup></button>`).join("") : '<span class="muted">หม้อยังว่างอยู่…</span>';
    return `<div class="card sp-play">${head}
      <div class="sp-scroll"><div class="sp-spell">📜 ${esc(s[0])}</div><div>จงผสมสาร: <b>${esc(s[1])}</b></div><div class="sp-clue">${clue}</div></div>
      <div class="sp-pot"><i class="sp-bub b1"></i><i class="sp-bub b2"></i><i class="sp-bub b3"></i><div class="sp-bowl">${bowl}</div><div class="sp-live">${Object.keys(S.bowl).length ? fm(S.bowl) : ""}</div></div>
      <p class="sp-msg">${S.msg}</p>
      <div class="sp-pal">${S.pal.map((k) => `<button class="sp-el g-${GRP(k)}" onclick="SPELL.add('${k}', this)"><b>${k}</b><small>${EN[k]}</small></button>`).join("")}</div>
      <div class="row" style="justify-content:center;margin-top:10px"><button class="btn ghost small" onclick="SPELL.clear()">🧹 ล้างหม้อ</button>
        ${L.hint === "name" ? `<button class="btn ghost small" ${S.shown ? "disabled" : ""} onclick="SPELL.hint()">💡 ใบ้</button>` : ""}
        <button class="btn gold" onclick="SPELL.cast()">🔮 ร่ายเวทย์</button></div></div>`;
  }
  function resView() {
    const r = S.res;
    return `<div class="card center gm-res ${r.score >= 90 ? "perfect" : ""}"><div style="font-size:54px">${r.score >= 90 ? "🧙‍♂️" : r.score >= 60 ? "🎉" : "💪"}</div>
      <h2>คะแนน ${r.score}/100</h2><p class="muted">ใช้เวลา ${r.secs} วินาที · ผิด ${r.wrong} ครั้ง · ขอใบ้ ${r.hints} ครั้ง${r.combo >= 2 ? ` · คอมโบสูงสุด ×${r.combo} 🔥` : ""}</p>
      <p>${r.no_reward ? '<span class="pill">ครบรอบที่ได้รางวัลของวันนี้แล้ว (เล่นฝึกได้ไม่จำกัด)</span>' : `<span class="pill">+${r.exp} EXP</span> ${r.coins ? `<span class="pill">+${r.coins} 🪙</span>` : ""}`}</p>
      ${r.capped && !r.no_reward ? '<p class="muted">EXP จากเกมวันนี้ถึงเพดานแล้ว</p>' : ""}
      <div class="row" style="justify-content:center"><button class="btn gold" onclick="SPELL.start('${r.level}')">เล่นอีกครั้ง</button><button class="btn ghost" onclick="SPELL.open()">เมนูเวทย์</button><button class="btn ghost" onclick="GAMES.home()">กลับหน้าเกม</button></div></div>`;
  }
  return { open, view, start, add, remove, clear, hint, cast, quit, bond: lwBond, atom: lwAtom };
})();
