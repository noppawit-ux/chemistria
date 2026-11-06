/* มินิเกม: ควิซประจำวัน + จับคู่ธาตุ (ตรวจคำตอบ/จำกัด EXP ที่เซิร์ฟเวอร์) */
const GAMES = (() => {
  const ELEMENTS = [
    ["H","ไฮโดรเจน"],["He","ฮีเลียม"],["Li","ลิเทียม"],["Be","เบริลเลียม"],["B","โบรอน"],["C","คาร์บอน"],["N","ไนโตรเจน"],["O","ออกซิเจน"],
    ["F","ฟลูออรีน"],["Ne","นีออน"],["Na","โซเดียม"],["Mg","แมกนีเซียม"],["Al","อะลูมิเนียม"],["Si","ซิลิคอน"],["P","ฟอสฟอรัส"],["S","กำมะถัน"],
    ["Cl","คลอรีน"],["Ar","อาร์กอน"],["K","โพแทสเซียม"],["Ca","แคลเซียม"],["Fe","เหล็ก"],["Cu","ทองแดง"],["Zn","สังกะสี"],["Ag","เงิน"],
    ["Au","ทอง"],["Hg","ปรอท"],["Pb","ตะกั่ว"],["Sn","ดีบุก"],["I","ไอโอดีน"],["Br","โบรมีน"],["Mn","แมงกานีส"],["Cr","โครเมียม"],["Ni","นิกเกิล"],["Ba","แบเรียม"],
  ];
  const LEVELS = { easy: { n: 6, pool: 20, label: "ง่าย" }, mid: { n: 8, pool: 28, label: "กลาง" }, hard: { n: 10, pool: 34, label: "ยาก" } };
  const st = { mode: "home", status: null, loading: false, qs: [], idx: 0, picks: [], res: null, mg: null, mres: null, busy: false };
  const shuffle = (a) => { a = a.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; };
  const paint = () => { const h = $("#gm"); if (h) h.innerHTML = inner(); };

  async function refresh() {
    if (st.loading) return; st.loading = true;
    try { st.status = await rpc("game_status", { p_token: tk() }); } catch (e) { toast(e.message); }
    st.loading = false; paint();
  }
  const view = () => { if (!st.status) refresh(); return `<div id="gm">${inner()}</div>`; };

  function head() {
    const s = st.status; if (!s) return '<div class="card"><p class="muted">กำลังโหลด…</p></div>';
    const pct = Math.min(100, Math.round(100 * s.exp_today / s.cap));
    return `<div class="card gm-head"><div class="row"><h3 style="margin:0" class="grow">🎮 มินิเกมเคมี</h3>
        <span class="pill" title="ทำควิซติดต่อกันหลายวัน ได้เหรียญโบนัส">🔥 ติดต่อกัน ${s.streak} วัน</span></div>
      <div class="lvrow" style="margin-top:8px"><span>EXP จากเกมวันนี้</span><b style="color:var(--text)">${s.exp_today} / ${s.cap}</b></div>
      <div class="lvgauge"><i style="width:${pct}%"></i></div>
      <p class="muted" style="margin:4px 0 0">${s.exp_today >= s.cap ? "วันนี้ได้ EXP จากเกมครบแล้ว พรุ่งนี้มาเล่นต่อนะ 🌙" : "เล่นให้ครบทุกวันเพื่อเก็บ EXP และสะสมวันติดต่อกัน"}</p></div>`;
  }

  function inner() {
    const s = st.status;
    if (st.mode === "quiz") return quizView();
    if (st.mode === "quizres") return quizResult();
    if (st.mode === "match") return matchView();
    if (st.mode === "matchres") return matchResult();
    if (st.mode === "battle") return BATTLE.view();
    if (st.mode === "duel") return DUEL.view();
    if (st.mode === "spell") return SPELL.view();
    if (!s) return head();
    return head() + `<div class="gm-grid">
      <div class="card gm-card">
        <div class="gm-ico">🧠</div><h3>ควิซประจำวัน</h3>
        <p class="muted">${s.quiz_total} ข้อ · ถูกข้อละ +${s.per_correct} EXP${s.perfect_bonus ? ` · ถูกหมดโบนัส +${s.perfect_bonus}` : ""} · วันละ 1 ครั้ง</p>
        ${s.quiz_done ? `<div class="tag ok" style="display:inline-block">ทำแล้ววันนี้ ✔ ${s.quiz_score}/${s.quiz_total} ข้อ (+${s.quiz_exp} EXP)</div>`
          : `<button class="btn gold" onclick="GAMES.startQuiz()">เริ่มควิซ</button>`}
      </div>
      <div class="card gm-card">
        <div class="gm-ico">⚗️</div><h3>จับคู่ธาตุ</h3>
        <p class="muted">จับคู่สัญลักษณ์กับชื่อธาตุให้เร็วและผิดน้อย · สูงสุด +${s.match_max_exp} EXP/รอบ · ได้รางวัล ${s.match_max_plays} รอบ/วัน
          (เล่นแล้ว ${Math.min(s.match_plays, s.match_max_plays)}/${s.match_max_plays}${s.match_best != null ? ` · ดีที่สุด ${s.match_best}` : ""})</p>
        <div class="row" style="justify-content:center">${Object.entries(LEVELS).map(([k, l]) => `<button class="btn small ${k === "mid" ? "gold" : "ghost"}" onclick="GAMES.startMatch('${k}')">${l.label} (${l.n} คู่)</button>`).join("")}</div>
      </div>
      <div class="card gm-card">
        <div class="gm-ico">🔮</div><h3>ห้องฝึกเวทย์ผสมธาตุ</h3>
        <p class="muted">ร่ายคาถาด้วยการผสมอะตอมในหม้อต้มให้ตรงสูตรสาร (น้ำ เกลือ กรด ฯลฯ) · 3 ระดับ · ผสมเร็ว ผิดน้อย ได้คะแนนสูง · ได้ EXP/เหรียญ</p>
        <button class="btn gold" onclick="SPELL.open()">🔮 เข้าห้องเวทย์</button>
      </div>
      <div class="card gm-card">
        <div class="gm-ico">⚔️</div><h3>ล่ามอนสเตอร์เคมี</h3>
        <p class="muted">เลือกสกิลตามคลาส ตอบคำถามเพื่อโจมตี บัพ และฮีล · มอนสเตอร์โต้กลับ กดลูกศรลดดาเมจ · ชนะได้ EXP เหรียญ และดรอปไอเทม</p>
        <button class="btn gold" onclick="BATTLE.open()">⚔️ เข้าต่อสู้</button>
      </div>
      <div class="card gm-card">
        <div class="gm-ico">🤝</div><h3>ท้าดวลเพื่อน (เรียลไทม์)</h3>
        <p class="muted">ท้าเพื่อนในห้องที่ออนไลน์ ตอบคำถามพร้อมกันทุกรอบ ตอบถูก/ไวกว่า = ทำดาเมจใส่อีกฝ่าย · มีท่าไม้ตายประจำคลาส · ชนะได้ EXP + เหรียญ</p>
        <button class="btn gold" onclick="DUEL.open()">🤝 เข้าห้องท้าดวล</button>
      </div></div>`;
  }

  /* ---------- ควิซ ---------- */
  async function startQuiz() {
    try {
      const r = await rpc("quiz_today", { p_token: tk() });
      if (r.done) { toast("วันนี้ทำควิซไปแล้ว"); st.status = null; return go("game"); }
      st.qs = r.questions; st.idx = 0; st.picks = []; st.mode = "quiz"; paint();
    } catch (e) { toast(e.message); }
  }
  function quizView() {
    const q = st.qs[st.idx], n = st.qs.length;
    return `<div class="card gm-q"><div class="row"><span class="pill">ข้อ ${st.idx + 1}/${n}</span><span class="muted grow">${esc(q.topic)}</span>
        <button class="btn ghost small" onclick="GAMES.quit()">ออก</button></div>
      <div class="lvgauge" style="margin:10px 0"><i style="width:${Math.round(100 * st.idx / n)}%"></i></div>
      <h3 style="margin:12px 0">${esc(q.question)}</h3>
      <div class="gm-choices">${q.choices.map((c, i) => `<button class="gm-choice" ${st.busy ? "disabled" : ""} onclick="GAMES.pick(${i})"><b>${"กขคง"[i]}</b> ${esc(c)}</button>`).join("")}</div></div>`;
  }
  async function pick(i) {
    if (st.busy) return;
    st.picks.push(i);
    if (st.idx + 1 < st.qs.length) { st.idx++; paint(); return; }
    st.busy = true; paint();
    try {
      st.res = await rpc("quiz_submit", { p_token: tk(), p_answers: st.picks });
      st.mode = "quizres"; st.status = null; await load();
      if (st.res.correct === st.res.total) setTimeout(() => FX.victory(), 300); else if (st.res.correct >= st.res.total / 2) setTimeout(() => FX.victory(), 300);
    } catch (e) { toast(e.message); st.mode = "home"; }
    st.busy = false; go("game");
  }
  function quizResult() {
    const r = st.res, perfect = r.correct === r.total;
    return `<div class="card center gm-res ${perfect ? "perfect" : ""}">
      <div style="font-size:54px">${perfect ? "🏆" : r.correct >= r.total / 2 ? "🎉" : "💪"}</div>
      <h2>ตอบถูก ${r.correct}/${r.total} ข้อ</h2>
      <p><span class="pill">+${r.exp} EXP</span> <span class="pill">+${r.coins} 🪙</span> ${r.streak > 1 ? `<span class="pill">🔥 ติดต่อกัน ${r.streak} วัน</span>` : ""}</p>
      ${r.capped ? '<p class="muted">EXP จากเกมวันนี้ถึงเพดานแล้ว</p>' : ""}</div>
      <div class="card"><h3>เฉลย</h3>${st.qs.map((q, i) => { const x = r.results[i];
        return `<div class="item" style="align-items:flex-start"><span style="font-size:20px">${x.ok ? "✅" : "❌"}</span><div class="grow">
          <b>${esc(q.question)}</b><div class="muted">คำตอบที่ถูก: <span style="color:var(--mint)">${"กขคง"[x.answer]}. ${esc(q.choices[x.answer])}</span>
          ${!x.ok ? ` · คุณตอบ: ${x.pick >= 0 ? esc(q.choices[x.pick]) : "—"}` : ""}</div>${x.explain ? `<div class="muted">💡 ${esc(x.explain)}</div>` : ""}</div></div>`; }).join("")}
        <div style="margin-top:10px"><button class="btn" onclick="GAMES.home()">กลับหน้าเกม</button></div></div>`;
  }

  /* ---------- จับคู่ธาตุ ---------- */
  function startMatch(level) {
    const L = LEVELS[level], pool = shuffle(ELEMENTS.slice(0, L.pool)).slice(0, L.n);
    st.mg = { level, n: L.n, left: shuffle(pool), right: shuffle(pool), done: {}, selL: null, selR: null, wrong: 0, t0: Date.now(), bad: null, over: false };
    st.mode = "match"; paint(); clearInterval(st.tm);
    st.tm = setInterval(() => { const el = $("#gt"); if (!el || st.mode !== "match") return clearInterval(st.tm); el.textContent = Math.floor((Date.now() - st.mg.t0) / 1000) + " วิ"; }, 500);
  }
  function matchView() {
    const g = st.mg, ok = Object.keys(g.done).length;
    const btn = (side, e) => { const d = g.done[e[0]], sel = g["sel" + side] === e[0], bad = g.bad && g.bad.includes(side + e[0]);
      return `<button class="gm-tile ${d ? "done" : ""} ${sel ? "sel" : ""} ${bad ? "bad" : ""}" ${d ? "disabled" : ""} onclick="GAMES.tap('${side}','${e[0]}')">${side === "L" ? `<b class="sym">${e[0]}</b>` : esc(e[1])}</button>`; };
    return `<div class="card"><div class="row"><span class="pill">จับคู่แล้ว ${ok}/${g.n}</span><span class="pill">ผิด ${g.wrong}</span>
      <span class="pill" id="gt">0 วิ</span><span class="grow"></span><button class="btn ghost small" onclick="GAMES.quit()">ออก</button></div>
      <p class="muted">แตะสัญลักษณ์ทางซ้าย แล้วแตะชื่อธาตุที่ตรงกันทางขวา</p>
      <div class="gm-board"><div>${g.left.map((e) => btn("L", e)).join("")}</div><div>${g.right.map((e) => btn("R", e)).join("")}</div></div></div>`;
  }
  async function tap(side, sym) {
    const g = st.mg; if (!g || g.over || g.bad) return;
    g["sel" + side] = g["sel" + side] === sym ? null : sym;
    if (g.selL && g.selR) {
      const q = (sd, sy) => document.querySelector(`[onclick="GAMES.tap('${sd}','${sy}')"]`);
      if (g.selL === g.selR) { FX.at(q("L", g.selL), "collect-burst", { scale: 1.4 }); FX.at(q("R", g.selR), "collect-burst", { scale: 1.4 }); g.done[g.selL] = 1; g.selL = g.selR = null; }
      else { FX.at(q("L", g.selL), "hit-spark", { scale: 1.6 }); FX.at(q("R", g.selR), "hit-spark", { scale: 1.6 }); g.wrong++; g.bad = ["L" + g.selL, "R" + g.selR]; g.selL = g.selR = null; paint();
        setTimeout(() => { g.bad = null; paint(); }, 450); return; }
    }
    paint();
    if (Object.keys(g.done).length === g.n) await finishMatch();
  }
  async function finishMatch() {
    const g = st.mg; g.over = true; clearInterval(st.tm);
    const secs = Math.max(g.n, Math.round((Date.now() - g.t0) / 1000));
    const score = Math.max(10, Math.min(100, Math.round(100 - g.wrong * 8 - Math.max(0, secs - g.n * 4))));
    try {
      const r = await rpc("match_submit", { p_token: tk(), p_score: score, p_pairs: g.n, p_seconds: secs });
      st.mres = { ...r, secs, wrong: g.wrong, level: g.level }; st.mode = "matchres"; st.status = null; await load();
      setTimeout(() => (score >= 90 ? FX.victory() : FX.victory()), 300);
    } catch (e) { toast(e.message); st.mode = "home"; }
    go("game");
  }
  function matchResult() {
    const r = st.mres;
    return `<div class="card center gm-res ${r.score >= 90 ? "perfect" : ""}"><div style="font-size:54px">${r.score >= 90 ? "🏆" : r.score >= 60 ? "🎉" : "💪"}</div>
      <h2>คะแนน ${r.score}/100</h2><p class="muted">ใช้เวลา ${r.secs} วินาที · ผิด ${r.wrong} ครั้ง</p>
      <p>${r.no_reward ? '<span class="pill">ครบรอบที่ได้รางวัลของวันนี้แล้ว (เล่นฝึกได้ไม่จำกัด)</span>'
        : `<span class="pill">+${r.exp} EXP</span> ${r.coins ? `<span class="pill">+${r.coins} 🪙</span>` : ""}`}</p>
      ${r.capped && !r.no_reward ? '<p class="muted">EXP จากเกมวันนี้ถึงเพดานแล้ว</p>' : ""}
      <div class="row" style="justify-content:center"><button class="btn gold" onclick="GAMES.startMatch('${r.level}')">เล่นอีกครั้ง</button>
      <button class="btn ghost" onclick="GAMES.home()">กลับหน้าเกม</button></div></div>`;
  }

  const home = () => { st.mode = "home"; st.status = null; go("game"); };
  const quit = () => { if (!confirm("ออกจากเกม? ความคืบหน้าจะไม่ถูกบันทึก")) return; clearInterval(st.tm); home(); };
  return { paint, mode: () => st.mode, setMode: (m) => { st.mode = m; }, view, startQuiz, pick, startMatch, tap, home, quit };
})();
