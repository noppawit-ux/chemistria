/* ปริศนา/มินิเกมก่อนสู้ของดันเจี้ยน (ประตูมิติ) — 5 แบบ เน้นไหวพริบ + ความเร็ว
   ใช้: DGPZ.mount(type, hostElement, (ok, secs) => …) · DGPZ.stop() ตอนออกจากหน้า · DGPZ.INFO[type] = ชื่อ/วิธีเล่น
   ผลเป็นของฝั่งเครื่องนักเรียน (เซิร์ฟเวอร์ตรวจแค่เวลาขั้นต่ำ) — ผลดีที่ได้จำกัดมาก (ลดเลือดมอนสเตอร์) */
const DGPZ = (() => {
  const EL = [[1, "H", "ไฮโดรเจน"], [2, "He", "ฮีเลียม"], [3, "Li", "ลิเทียม"], [4, "Be", "เบริลเลียม"], [5, "B", "โบรอน"], [6, "C", "คาร์บอน"], [7, "N", "ไนโตรเจน"], [8, "O", "ออกซิเจน"], [9, "F", "ฟลูออรีน"], [10, "Ne", "นีออน"],
    [11, "Na", "โซเดียม"], [12, "Mg", "แมกนีเซียม"], [13, "Al", "อะลูมิเนียม"], [14, "Si", "ซิลิคอน"], [15, "P", "ฟอสฟอรัส"], [16, "S", "กำมะถัน"], [17, "Cl", "คลอรีน"], [18, "Ar", "อาร์กอน"], [19, "K", "โพแทสเซียม"], [20, "Ca", "แคลเซียม"]];
  const WORDS = [["HYDROGEN", "ไฮโดรเจน"], ["OXYGEN", "ออกซิเจน"], ["CARBON", "คาร์บอน"], ["SODIUM", "โซเดียม"], ["NITROGEN", "ไนโตรเจน"], ["HELIUM", "ฮีเลียม"], ["CALCIUM", "แคลเซียม"], ["SILICON", "ซิลิคอน"],
    ["CHLORINE", "คลอรีน"], ["MAGNESIUM", "แมกนีเซียม"], ["NEON", "นีออน"], ["BORON", "โบรอน"], ["LITHIUM", "ลิเทียม"], ["SULFUR", "กำมะถัน"], ["ARGON", "อาร์กอน"], ["IRON", "เหล็ก"]];
  const PAIRS = [["Na", "โซเดียม"], ["Fe", "เหล็ก"], ["Cu", "ทองแดง"], ["Au", "ทองคำ"], ["Ag", "เงิน"], ["K", "โพแทสเซียม"], ["Hg", "ปรอท"], ["Pb", "ตะกั่ว"], ["Zn", "สังกะสี"], ["Sn", "ดีบุก"]];
  const INFO = {
    tap: { ico: "⚡", name: "ไวสายฟ้า", how: "แตะช่องที่สว่างให้ครบ 8 ครั้งภายใน 9 วินาที (แตะผิดเสียเวลา)" },
    decode: { ico: "🧬", name: "ถอดรหัสธาตุ", how: "ดูเลขอะตอมแล้วเลือกสัญลักษณ์ธาตุให้ถูก 3 จาก 4 ข้อ (ข้อละ 6 วินาที)" },
    scramble: { ico: "🔤", name: "อักษรปริศนา", how: "เรียงตัวอักษรให้เป็นชื่อธาตุภาษาอังกฤษ ถูก 2 จาก 3 คำ ภายใน 45 วินาที" },
    memory: { ico: "🃏", name: "จับคู่ความจำ", how: "จำตำแหน่งการ์ดสัญลักษณ์ธาตุกับชื่อไทย แล้วจับคู่ให้ครบภายใน 30 วินาที" },
    pattern: { ico: "🔢", name: "เลขปริศนา", how: "หาเลขตัวถัดไปของแบบรูปให้ถูก 2 จาก 3 ข้อ (ข้อละ 12 วินาที)" },
  };
  const R = (n) => Math.floor(Math.random() * n);
  const shuf = (a) => { a = a.slice(); for (let i = a.length - 1; i > 0; i--) { const j = R(i + 1); [a[i], a[j]] = [a[j], a[i]]; } return a; };
  const pick = (a, n) => shuf(a).slice(0, n);
  let cur = null;
  function stop() { if (cur) { cur.tm.forEach(clearTimeout); cur.iv.forEach(clearInterval); cur.dead = true; cur = null; } }

  function mount(type, host, done) {
    stop();
    const c = (cur = { tm: [], iv: [], dead: false, t0: Date.now(), fin: false });
    const T = (f, ms) => { const id = setTimeout(() => { if (!c.dead) f(); }, ms); c.tm.push(id); return id; };
    const I = (f, ms) => { const id = setInterval(() => { if (!c.dead) f(); }, ms); c.iv.push(id); return id; };
    const inf = INFO[type] || INFO.tap;
    host.innerHTML = `<div class="pz pz-${type}"><div class="pz-top"><b>${inf.ico} ${inf.name}</b><span class="pz-time" id="pztime">⏱</span></div><div class="pz-sub" id="pzsub"></div><div class="pz-body" id="pzbody"></div><div class="pz-end" id="pzend" hidden></div></div>`;
    const $ = (id) => host.querySelector("#" + id), body = $("pzbody"), sub = $("pzsub"), tm = $("pztime");
    const setTime = (s) => { tm.textContent = "⏱ " + Math.max(0, s).toFixed(1) + " วิ"; tm.classList.toggle("low", s <= 3); };
    function finish(ok, msg) {
      if (c.fin) return; c.fin = true; c.iv.forEach(clearInterval); c.tm.forEach(clearTimeout);
      const secs = (Date.now() - c.t0) / 1000, e = $("pzend");
      body.classList.add("off"); e.hidden = false; e.className = "pz-end " + (ok ? "ok" : "no");
      e.innerHTML = ok ? `✅ ผ่านปริศนา! ${msg || ""}` : `❌ ไม่ผ่าน ${msg || ""}`;
      setTimeout(() => { if (!c.dead) done(ok, secs); }, 1300);
    }
    /* ---- ไวสายฟ้า ---- */
    if (type === "tap") {
      let hit = 0, lit = -1, left = 9; const NEED = 8;
      body.innerHTML = `<div class="pz-grid">${Array.from({ length: 9 }, (_, i) => `<button class="pz-cell" data-i="${i}" aria-label="ช่อง ${i + 1}"></button>`).join("")}</div>`;
      const cells = [...body.querySelectorAll(".pz-cell")];
      const show = () => { cells.forEach((b, i) => b.classList.toggle("on", i === lit)); sub.textContent = `แตะที่สว่าง ${hit}/${NEED}`; };
      const move = () => { let n; do n = R(9); while (n === lit); lit = n; show(); };
      body.addEventListener("click", (e) => { const b = e.target.closest(".pz-cell"); if (!b || c.fin) return; if (+b.dataset.i === lit) { hit++; if (hit >= NEED) { lit = -1; show(); return finish(true, "ไวมาก!"); } move(); } else { left -= 0.6; b.classList.add("bad"); setTimeout(() => b.classList.remove("bad"), 200); } });
      move(); I(move, 850);
      I(() => { left -= 0.1; setTime(left); if (left <= 0) finish(false, `แตะได้ ${hit}/${NEED}`); }, 100);
    }
    /* ---- ถอดรหัสธาตุ ---- */
    else if (type === "decode") {
      let q = 0, right = 0, left = 6; const N = 4, qs = pick(EL, N);
      const ask = () => {
        if (c.fin) return; const el = qs[q]; left = 6;
        const opts = shuf([el, ...pick(EL.filter((x) => x[0] !== el[0]), 3)]);
        sub.textContent = `ข้อ ${q + 1}/${N} · ถูก ${right}`;
        body.innerHTML = `<div class="pz-big">เลขอะตอม <b>${el[0]}</b> คือธาตุใด?</div><div class="pz-opts">${opts.map((o) => `<button class="pz-opt" data-a="${o[0]}">${o[1]} <small>${o[2]}</small></button>`).join("")}</div>`;
      };
      const next = (ok) => { if (ok) right++; q++; if (right >= 3) return finish(true, `ถูก ${right}/${N}`); if (q >= N || right + (N - q) < 3) return finish(right >= 3, `ถูก ${right}/${N}`); T(ask, 450); };
      body.addEventListener("click", (e) => { const b = e.target.closest(".pz-opt"); if (!b || c.fin || b.disabled) return; const ok = +b.dataset.a === qs[q][0]; [...body.querySelectorAll(".pz-opt")].forEach((x) => { x.disabled = true; if (+x.dataset.a === qs[q][0]) x.classList.add("ok"); }); if (!ok) b.classList.add("no"); left = 99; next(ok); });
      ask(); I(() => { if (left > 50) return; left -= 0.1; setTime(left); if (left <= 0) { left = 99; [...body.querySelectorAll(".pz-opt")].forEach((x) => (x.disabled = true)); next(false); } }, 100);
    }
    /* ---- อักษรปริศนา ---- */
    else if (type === "scramble") {
      const ws = pick(WORDS, 3); let w = 0, solved = 0, got = [], used = [], left = 45, tiles = [];
      const setup = () => {
        const word = ws[w][0]; let t; do t = shuf(word.split("")); while (t.join("") === word);
        tiles = t; got = []; used = [];
        sub.textContent = `คำที่ ${w + 1}/3 · ถูก ${solved} · คำใบ้: ${ws[w][1]}`;
        draw();
      };
      const draw = () => {
        const word = ws[w][0];
        body.innerHTML = `<div class="pz-slots">${word.split("").map((_, i) => `<span class="pz-slot ${got[i] ? "f" : ""}">${got[i] || ""}</span>`).join("")}</div>
          <div class="pz-tiles">${tiles.map((ch, i) => `<button class="pz-tile" data-i="${i}" ${used.includes(i) ? "disabled" : ""}>${ch}</button>`).join("")}</div>
          <div class="row" style="justify-content:center;gap:8px"><button class="btn small ghost" data-act="back">⌫ ลบ</button><button class="btn small ghost" data-act="skip">⏭ ข้ามคำนี้</button></div>`;
      };
      const advance = () => { w++; if (w >= 3 || solved + (3 - w) < 2) return finish(solved >= 2, `ถูก ${solved}/3`); T(setup, 500); };
      body.addEventListener("click", (e) => {
        if (c.fin) return; const t = e.target.closest(".pz-tile"), a = e.target.closest("[data-act]");
        if (t) { used.push(+t.dataset.i); got.push(tiles[+t.dataset.i]); draw();
          if (got.length === ws[w][0].length) { if (got.join("") === ws[w][0]) { solved++; sub.textContent = "✅ ถูก!"; if (solved >= 2) return finish(true, `ถูก ${solved}/3`); advance(); } else { body.classList.add("shake"); setTimeout(() => body.classList.remove("shake"), 350); got = []; used = []; draw(); } } }
        else if (a && a.dataset.act === "back") { used.pop(); got.pop(); draw(); }
        else if (a && a.dataset.act === "skip") advance();
      });
      setup(); I(() => { left -= 0.1; setTime(left); if (left <= 0) finish(solved >= 2, `ถูก ${solved}/3`); }, 100);
    }
    /* ---- จับคู่ความจำ ---- */
    else if (type === "memory") {
      const ps = pick(PAIRS, 4); let cards = shuf(ps.flatMap((p, i) => [{ k: i, t: p[0], s: "sym" }, { k: i, t: p[1], s: "name" }])), open = [], found = 0, lock = true, left = 30;
      const draw = () => { body.innerHTML = `<div class="pz-mem">${cards.map((cd, i) => `<button class="pz-mc ${cd.up ? "up" : ""} ${cd.ok ? "ok" : ""} ${cd.s}" data-i="${i}" ${cd.ok ? "disabled" : ""}><span>${cd.up || cd.ok ? cd.t : "?"}</span></button>`).join("")}</div>`; sub.textContent = `จับคู่แล้ว ${found}/4`; };
      cards.forEach((cd) => (cd.up = true)); draw(); sub.textContent = "จำให้ดี! การ์ดจะคว่ำใน 3 วินาที";
      T(() => { cards.forEach((cd) => (cd.up = false)); lock = false; draw(); }, 3000);
      body.addEventListener("click", (e) => {
        const b = e.target.closest(".pz-mc"); if (!b || lock || c.fin) return; const i = +b.dataset.i, cd = cards[i]; if (cd.up || cd.ok) return;
        cd.up = true; open.push(i); draw();
        if (open.length === 2) { lock = true; const [x, y] = open.map((j) => cards[j]);
          if (x.k === y.k) { x.ok = y.ok = true; x.up = y.up = false; found++; open = []; lock = false; draw(); if (found >= 4) finish(true, "จำแม่น!"); }
          else T(() => { x.up = y.up = false; open = []; lock = false; draw(); }, 800); }
      });
      setTime(30);
      // เริ่มนับเวลาหลังการ์ดคว่ำ
      T(() => I(() => { left -= 0.1; setTime(left); if (left <= 0) finish(false, `จับคู่ได้ ${found}/4`); }, 100), 3000);
    }
    /* ---- เลขปริศนา ---- */
    else if (type === "pattern") {
      const gen = () => { const k = R(6); let s, ans;
        if (k === 0) { const a = 1 + R(9), d = 2 + R(8); s = [a, a + d, a + 2 * d, a + 3 * d]; ans = a + 4 * d; }
        else if (k === 1) { const a = 1 + R(3), r = 2 + R(2); s = [a, a * r, a * r * r, a * r * r * r]; ans = a * r ** 4; }
        else if (k === 2) { const n = 1 + R(5); s = [n * n, (n + 1) ** 2, (n + 2) ** 2, (n + 3) ** 2]; ans = (n + 4) ** 2; }
        else if (k === 3) { const a = 1 + R(4), b = 1 + R(4); s = [a, b, a + b, a + 2 * b, 2 * a + 3 * b]; s = s.slice(0, 5); ans = 3 * a + 5 * b; }
        else if (k === 4) { const a = 2 + R(4), b = 1 + R(3), st = 3 + R(8); s = [st, st + a, st + a - b, st + 2 * a - b]; ans = st + 2 * a - 2 * b; }
        else { s = [2, 3, 5, 7, 11]; ans = 13; }
        const wrong = new Set(); while (wrong.size < 3) { const w = ans + (R(9) - 4); if (w !== ans && w > 0) wrong.add(w); }
        return { s, ans, opts: shuf([ans, ...wrong]) }; };
      const qs = [gen(), gen(), gen()]; let q = 0, right = 0, left = 12;
      const ask = () => { if (c.fin) return; left = 12; const p = qs[q]; sub.textContent = `ข้อ ${q + 1}/3 · ถูก ${right}`;
        body.innerHTML = `<div class="pz-big">${p.s.join(" , ")} , <b>?</b></div><div class="pz-opts">${p.opts.map((o) => `<button class="pz-opt" data-a="${o}">${o}</button>`).join("")}</div>`; };
      const next = (ok) => { if (ok) right++; q++; if (right >= 2) return finish(true, `ถูก ${right}/3`); if (q >= 3) return finish(false, `ถูก ${right}/3`); T(ask, 450); };
      body.addEventListener("click", (e) => { const b = e.target.closest(".pz-opt"); if (!b || c.fin || b.disabled) return; const ok = +b.dataset.a === qs[q].ans; [...body.querySelectorAll(".pz-opt")].forEach((x) => { x.disabled = true; if (+x.dataset.a === qs[q].ans) x.classList.add("ok"); }); if (!ok) b.classList.add("no"); left = 99; next(ok); });
      ask(); I(() => { if (left > 50) return; left -= 0.1; setTime(left); if (left <= 0) { left = 99; [...body.querySelectorAll(".pz-opt")].forEach((x) => (x.disabled = true)); next(false); } }, 100);
    }
    else finish(true, "");
  }
  return { mount, stop, INFO, TYPES: Object.keys(INFO) };
})();
