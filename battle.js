/* มินิเกมต่อสู้มอนสเตอร์เคมี: เลือกสกิลตามคลาส → ตอบคำถามเพื่อใช้สกิล → มอนสเตอร์โต้กลับ กดลูกศรลดดาเมจ
   (ดาเมจ/เฉลย/รางวัล คำนวณที่เซิร์ฟเวอร์ทั้งหมด) */
const BATTLE = (() => {
  const S = { screen: "list", data: null, bat: null, fb: null, msg: "", busy: false, def: null, qtimer: null, hit: "", drop: null };
  const ARW = { L: "⬅️", U: "⬆️", R: "➡️", D: "⬇️" };
  const KEYS = { ArrowLeft: "L", ArrowUp: "U", ArrowRight: "R", ArrowDown: "D" };
  const KIND = { attack: ["⚔️", "โจมตี"], buff: ["📈", "บัพ"], heal: ["💚", "ฮีล"] };
  const BUFF = { atk_up: "🔥 พลังโจมตี +50%", crit_up: "🍀 คริติคอลแน่นอน", shield: "🛡️ โล่ลดดาเมจ 50%", weak: "🔬 มอนสเตอร์อ่อนแอ +40%" };
  const paint = () => GAMES.paint();
  const mimg = (m, cls = "") => m.image ? `<img class="bt-mimg ${cls}" src="${esc(m.image)}" alt="${esc(m.name)}" onerror="this.outerHTML='<div class=&quot;bt-memo ${cls}&quot;>${esc(m.emoji)}</div>'">` : `<div class="bt-memo ${cls}">${esc(m.emoji)}</div>`;
  const hp = (v, mx, cls) => `<div class="bt-hp ${cls}"><i style="width:${Math.max(0, Math.round((100 * v) / mx))}%"></i><span>${v} / ${mx}</span></div>`;

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
      S.hit = r.event.dmg > 0 ? "m" : "";
      if (S.bat.status !== "active") finishLoad();
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
  const WIN = 1700;
  function nextArrow() {
    const d = S.def; if (!d) return;
    if (d.i >= d.n) return endDef();
    d.state = "go"; d.t0 = Date.now();
    d.t = setTimeout(() => judge(null), WIN); paint();
  }
  function judge(k) {
    const d = S.def; if (!d || d.state !== "go") return; clearTimeout(d.t);
    const ok = k === d.seq[d.i]; d.marks.push(ok ? 1 : 0); if (ok) d.hits++; d.state = ok ? "ok" : "miss";
    paint(); d.i++; d.t = setTimeout(nextArrow, 380);
  }
  async function endDef() {
    const d = S.def; if (!d || d.sent) return; d.sent = true; d.state = "send"; paint();
    try {
      const r = await rpc("battle_defend", { p_token: tk(), p_battle: S.bat.id, p_hits: d.hits });
      S.bat = r.state; const e = r.event;
      S.msg = `🏹 ${S.bat.monster.atk_name}! กดถูก ${e.hits}/${e.n} → รับดาเมจ ${e.taken}${e.shield ? " (โล่ช่วยลดอีกครึ่ง 🛡️)" : ""}`;
      S.hit = e.taken > 0 ? "p" : "";
      if (S.bat.status !== "active") { S.screen = "result"; finishLoad(); }
    } catch (x) { toast(x.message); }
    S.def = null; paint(); setTimeout(() => { S.hit = ""; }, 700);
  }
  window.addEventListener("keydown", (e) => {
    if (S.screen === "fight" && S.def && S.def.state === "go" && KEYS[e.key]) { e.preventDefault(); judge(KEYS[e.key]); }
  });
  const tapArrow = (k) => judge(k);

  async function finishLoad() { try { await load(); } catch (e) {} }
  async function flee() {
    if (!confirm("หนีจากการต่อสู้? จะนับเป็น 1 รอบของวันนี้และไม่ได้รางวัล")) return;
    clearTimeout(S.qtimer); if (S.def) clearTimeout(S.def.t); S.def = null;
    try { await rpc("battle_flee", { p_token: tk(), p_battle: S.bat.id }); } catch (e) {}
    S.bat = null; open();
  }
  const back = () => { clearTimeout(S.qtimer); if (S.def) clearTimeout(S.def.t); S.def = null; S.bat = null; S.fb = null; open(); };
  const exit = () => { clearTimeout(S.qtimer); if (S.def) clearTimeout(S.def.t); S.def = null; GAMES.home(); };

  /* ---------- หน้าจอ ---------- */
  function listView() {
    const d = S.data; if (!d) return '<div class="card"><p class="muted">กำลังโหลด…</p></div>';
    const left = Math.max(0, d.limit - d.used);
    return `<div class="card"><div class="row"><h3 style="margin:0" class="grow">⚔️ ล่ามอนสเตอร์เคมี</h3><button class="btn ghost small" onclick="BATTLE.exit()">‹ กลับ</button></div>
      <p class="muted" style="margin:6px 0">ตอบคำถามเพื่อใช้สกิล · มอนสเตอร์โจมตีกลับให้กดลูกศรลดดาเมจ · ชนะได้ EXP + เหรียญ + สุ่มดรอปไอเทม</p>
      <p>${left > 0 ? `<span class="pill">🎁 รอบที่ได้รางวัลวันนี้เหลือ ${left}/${d.limit}</span>` : '<span class="pill">รอบที่ได้รางวัลวันนี้หมดแล้ว — เล่นฝึกได้ไม่จำกัด (ไม่ได้รางวัล)</span>'} <span class="pill">❤️ HP ${d.p_max}</span></p>
      <div class="bt-skills">${d.skills.map((s) => `<span class="bt-sk ${s.kind}" title="${esc(s.descr || "")}">${s.emoji} <b>${esc(s.name)}</b> <small>${KIND[s.kind][1]}</small></span>`).join("")}</div></div>
      <div class="bt-mgrid">${d.monsters.map((m) => `<div class="card bt-mcard">${mimg(m)}<h3>${esc(m.name)} <small class="muted">Lv.${m.level}</small></h3>
        <p class="muted" style="margin:2px 0">${esc(m.descr || "")}</p><p style="margin:4px 0"><span class="pill">❤️ ${m.hp}</span> <span class="pill">🗡️ ${m.atk}</span></p>
        <p class="muted" style="margin:2px 0 8px">รางวัล +${m.exp} EXP · +${m.coins} 🪙 · ดรอปไอเทม</p>
        <button class="btn gold" onclick="BATTLE.start('${m.id}')">⚔️ ท้าสู้</button></div>`).join("") || '<div class="card"><p class="muted">ยังไม่มีมอนสเตอร์ในระบบ</p></div>'}</div>`;
  }

  function fightView() {
    const b = S.bat, m = b.monster, me = D.student;
    const buffs = Object.entries(b.buffs || {}).filter(([, v]) => v > 0).map(([k, v]) => `<span class="bt-buff">${BUFF[k] || k} ×${v}</span>`).join("");
    const arena = `<div class="card bt-arena">
      <div class="bt-side bt-mon ${S.hit === "m" ? "hit" : ""}">${mimg(m, S.hit === "m" ? "shake" : "float")}<div class="bt-nm">${esc(m.name)} <small>Lv.${m.level}</small></div>${hp(b.m_hp, b.m_max, "mon")}</div>
      <div class="bt-vs">VS</div>
      <div class="bt-side bt-me ${S.hit === "p" ? "hit" : ""}"><div class="${S.hit === "p" ? "shake" : ""}">${stage(me.char_class, D.rank_info, me.decor, "sm")}</div><div class="bt-nm">${esc(me.name)} <small>เทิร์น ${b.turn}</small></div>${hp(b.p_hp, b.p_max, "me")}
        <div class="bt-buffs">${buffs}</div></div></div>`;
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
    const big = d.state === "go" ? `<div class="bt-arrow go">${ARW[cur]}<div class="bt-ring" style="animation-duration:${WIN}ms"></div></div>`
      : d.state === "ok" ? '<div class="bt-arrow ok">✔</div>' : d.state === "miss" ? '<div class="bt-arrow no">✖</div>'
      : d.state === "send" ? '<div class="bt-arrow">…</div>' : '<div class="bt-arrow">⚠️</div>';
    return `<div class="card center bt-def"><h3 style="margin:0">⚠️ ${esc(p.name)}! ดาเมจ ~${p.dmg}</h3>
      <p class="muted" style="margin:4px 0 8px">กดลูกศรให้ตรงตามที่ปรากฏ (คีย์บอร์ด ← ↑ → ↓ หรือแตะปุ่มด้านล่าง) ยิ่งถูกมาก ดาเมจยิ่งลด (สูงสุด 80%)</p>
      <div class="bt-marks">${marks}</div>${big}
      <div class="bt-pad"><button onclick="BATTLE.arrow('U')">⬆️</button><div><button onclick="BATTLE.arrow('L')">⬅️</button><button onclick="BATTLE.arrow('D')">⬇️</button><button onclick="BATTLE.arrow('R')">➡️</button></div></div></div>`;
  }
  function resultView() {
    const b = S.bat, win = b.status === "won", dr = S.drop, m = b.monster;
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
  return { open, view, start, skill: useSkill, pick: answer, next: afterFb, arrow: tapArrow, flee, back, exit };
})();
