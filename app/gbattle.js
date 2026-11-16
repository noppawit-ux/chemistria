/* Guild Battle — จับคู่กิลด์แข่งเกมกดลูกศรตามจังหวะ (SQL 80)
   ทุกคนเล่นโน้ตชุดเดียวกันในรอบนั้น · คะแนนกิลด์ = เฉลี่ย 3 คนที่ดีที่สุด · เซิร์ฟเวอร์ตรวจคะแนนจากลำดับการกดที่ส่งขึ้นไป */
let GBX = null;
const GB_ARW = { L: "⬅️", D: "⬇️", U: "⬆️", R: "➡️" }, GB_LANES = ["L", "D", "U", "R"], GB_KEYS = { ArrowLeft: "L", ArrowDown: "D", ArrowUp: "U", ArrowRight: "R", a: "L", s: "D", w: "U", d: "R" };
const GB_TT = 1500, GB_GOOD = 220, GB_PERFECT = 90;   // เวลาโน้ตตกถึงเส้น · ช่วงกดที่นับ (ms) — ต้องตรงกับฝั่งเซิร์ฟเวอร์

function gbHold() { setTimeout(gbLoad, 0); return `<div id="gbcard">${GBX ? gbCardHtml() : ""}</div>`; }
async function gbLoad() {
  try { GBX = await rpc("gb_status", { p_token: tk() }); } catch (e) { GBX = null; }
  const el = document.getElementById("gbcard"); if (el) el.innerHTML = gbCardHtml();
}
function gbLeft(iso) {
  const ms = new Date(iso).getTime() - Date.now(); if (ms <= 0) return "หมดเวลาแล้ว";
  const m = Math.ceil(ms / 60000), d = Math.floor(m / 1440), h = Math.floor((m % 1440) / 60);
  return d ? `เหลือ ${d} วัน ${h} ชม.` : h ? `เหลือ ${h} ชม. ${m % 60} นาที` : `เหลือ ${m} นาที`;
}
function gbSide(s, mine) {
  if (!s) return "";
  const nm = s.ghost ? `<b>${esc(s.name)}</b>` : gnameF(s.name, s.emblem);
  return `<div class="gbside ${mine ? "me" : ""}">${nm}<div class="gbsc">${s.score}</div><small class="muted">${s.ghost ? "คะแนนคงที่" : `เล่นแล้ว ${s.played}/${s.size} คน`}</small></div>`;
}
function gbCardHtml() {
  const g = GBX; if (!g || !g.round || !g.has_guild) return "";
  const r = g.round, st = r.state;
  const head = `<h3 style="margin:0 0 4px">⚔️ Guild Battle <small class="muted" style="font-weight:400">${esc(r.title)}</small></h3>`;
  if (!g.in_match) return `<div class="card gbcard">${head}<p class="muted" style="margin:0">${st === "unpaired" ? "ครูกำลังจับคู่กิลด์ — รอสักครู่" : "กิลด์ของคุณไม่ได้อยู่ในการแข่งรอบนี้ (ต้องมีสมาชิกครบตามเกณฑ์)"}</p></div>`;
  const stTxt = { open: `🟢 เปิดแข่งอยู่ · ${gbLeft(r.ends_at)}`, counting: "⏳ หมดเวลาแล้ว กำลังนับคะแนน…", final: "🏁 จบรอบแล้ว", soon: "เร็วๆ นี้" }[st] || "";
  let res = "";
  if (st === "final" && g.mine) res = `<div class="gbres ${g.mine}">${g.result === "draw" ? "🤝 เสมอ — นับเป็นชนะทั้งคู่!" : g.mine === "win" ? "🏆 กิลด์ของคุณชนะ!" : "💪 รอบนี้แพ้ ครั้งหน้าเอาคืน!"}</div>`;
  const mem = ((g.me && g.me.members) || []).map((x) => `<div class="gbm"><span>${x.leader ? "👑 " : ""}${esc(gShort(x.name))}</span><span class="gbmbar"><i style="width:${Math.round(x.best / 10)}%"></i></span><b>${x.best}</b></div>`).join("");
  let act = "";
  if (st === "open") act = g.left > 0 ? `<button class="btn gold" onclick="gbPlay()">🎵 เริ่มเล่น (เหลือ ${g.left} ครั้ง)</button>` : '<button class="btn" disabled>ใช้สิทธิ์ครบแล้ว</button>';
  if (st === "final" && g.can_claim) act = `<button class="btn gold" onclick="gbClaim()">🎁 รับรางวัล (${g.reward.coins} 🪙${g.reward.pulls ? " + ตั๋วกาชา " + g.reward.pulls : ""})</button>`;
  else if (st === "final" && g.claimed) act = '<span class="pill">✅ รับรางวัลแล้ว</span>';
  else if (st === "final" && !g.best) act = '<span class="muted">ต้องลงแข่งอย่างน้อย 1 ครั้งจึงรับรางวัลได้</span>';
  const hist = (g.history || []).length ? `<h4 style="margin:12px 0 4px">รอบก่อนๆ</h4>${g.history.map((h) => `<div class="row" style="justify-content:space-between;padding:3px 0;border-top:1px solid var(--line)"><span>${esc(h.title)} <small class="muted">vs ${esc(h.opp_name)}</small></span><b style="color:${h.me >= h.opp ? "var(--mint)" : "var(--red)"}">${h.me} : ${h.opp}</b></div>`).join("")}` : "";
  return `<div class="card gbcard">${head}<p class="muted" style="margin:0 0 8px">${stTxt} · เล่นได้ ${r.attempts} ครั้ง (นับครั้งที่ดีที่สุด) · ${r.notes} โน้ต</p>
    <div class="gbvs">${gbSide(g.me, true)}<div class="gbx">VS</div>${gbSide(g.opp, false)}</div>${res}
    <p class="muted" style="margin:8px 0 6px;font-size:.85em">คะแนนกิลด์ = เฉลี่ยของ 3 คนที่ทำคะแนนสูงสุด (คนที่ไม่ได้เล่นนับ 0) — ชวนเพื่อนในกิลด์มาเล่นให้ครบ!</p>
    <div class="gbmem">${mem}</div>
    <div class="row" style="margin-top:10px;align-items:center;gap:8px;flex-wrap:wrap">${act}<span class="muted">คะแนนดีที่สุดของคุณ: <b>${g.best}</b></span></div>${hist}</div>`;
}
async function gbClaim() {
  const r = await act(() => rpc("gb_claim", { p_token: tk() }), "รับรางวัล Guild Battle แล้ว 🎁");
  if (r && window.FX) FX.victory(); GBX = null; gbLoad();
}

/* ---------- เกมกดลูกศร ---------- */
let GBG = null;
async function gbPlay() {
  if (GBG) return;
  let j; try { j = await rpc("gb_start", { p_token: tk() }); } catch (e) { return toast(e.message); }
  eqClose(); gbRun(j);
}
function gbRun(j) {
  const ov = document.createElement("div"); ov.id = "gbov"; ov.setAttribute("role", "dialog");
  ov.innerHTML = `<div class="gbhud"><button class="gbquit" aria-label="ออก" onclick="gbQuit()">✕</button><div class="gbscore"><small>คะแนน</small> <b id="gbs">0</b></div><div id="gbc" class="gbcombo"></div><div class="gbprog"><i id="gbp"></i></div></div>
    <div class="gbfield" id="gbf">${GB_LANES.map((k, i) => `<div class="gblane" style="left:${i * 25}%"></div>`).join("")}<div class="gbline"></div><div id="gbfb" class="gbfb"></div><div id="gbcd" class="gbcd">3</div></div>
    <div class="gbpad">${GB_LANES.map((k) => `<button data-k="${k}" aria-label="${k}">${GB_ARW[k]}</button>`).join("")}</div>
    <p class="gbhint">กดปุ่มลูกศร (หรือ ← ↓ ↑ → / A S W D) เมื่อโน้ตตกถึงเส้นทอง</p>`;
  document.body.appendChild(ov); document.body.classList.add("gbplaying");
  const f = ov.querySelector("#gbf"), H = f.clientHeight, hitY = H * 0.82;
  const notes = j.chart.map((n) => { const e = document.createElement("div"); e.className = "gbn k" + n.k; e.textContent = GB_ARW[n.k]; e.style.left = GB_LANES.indexOf(n.k) * 25 + "%"; e.style.transform = "translateY(-120px)"; f.appendChild(e); return { t: n.t, k: n.k, e, done: false }; });
  const G = GBG = { j, notes, presses: [], score: 0, combo: 0, maxc: 0, perfect: 0, good: 0, miss: 0, T0: performance.now() + 3000, raf: 0, over: false, ov, f, hitY };
  const $s = ov.querySelector("#gbs"), $c = ov.querySelector("#gbc"), $p = ov.querySelector("#gbp"), $fb = ov.querySelector("#gbfb"), $cd = ov.querySelector("#gbcd");
  const speed = hitY / GB_TT;
  const fb = (t, cls) => { $fb.textContent = t; $fb.className = "gbfb " + cls; $fb.style.animation = "none"; void $fb.offsetWidth; $fb.style.animation = ""; };
  const mult = (n) => 1 + Math.min(n, 20) * 0.02;
  G.press = (k) => {
    if (G.over) return;
    const t = performance.now() - G.T0; if (t < -300) return;
    G.presses.push({ t: Math.round(t), k });
    const pad = ov.querySelector(`.gbpad [data-k="${k}"]`); if (pad) { pad.classList.add("on"); setTimeout(() => pad.classList.remove("on"), 90); }
    let best = null, bd = GB_GOOD + 1;
    for (const n of notes) if (!n.done && n.k === k) { const d = Math.abs(n.t - t); if (d < bd) { bd = d; best = n; } }
    if (!best) { if (window.SFX) SFX.play("gb_miss", { gap: 60 }); return; }
    best.done = true; best.e.classList.add("hit"); setTimeout(() => best.e.remove(), 250);
    G.combo++; G.maxc = Math.max(G.maxc, G.combo);
    const perfect = bd <= GB_PERFECT; if (perfect) G.perfect++; else G.good++;
    G.score += (perfect ? 100 : 60) * mult(G.combo);
    if (window.SFX) SFX.play("gb_" + k, { gap: 0 });
    fb(perfect ? "PERFECT!" : "GOOD", perfect ? "pf" : "gd");
  };
  const frame = () => {
    if (!GBG || G.over) return;
    const now = performance.now() - G.T0;
    if (now < 0) { const c = String(Math.ceil(-now / 1000)); if ($cd.textContent !== c) $cd.textContent = c; }
    else if ($cd.style.display !== "none") $cd.style.display = "none";
    for (const n of notes) {
      if (n.done) continue;
      if (now > n.t + GB_GOOD) { n.done = true; G.combo = 0; G.miss++; n.e.classList.add("miss"); setTimeout(() => n.e.remove(), 400); fb("MISS", "ms"); continue; }
      n.e.style.transform = `translateY(${(hitY - (n.t - now) * speed).toFixed(1)}px)`;
    }
    $s.textContent = Math.round(G.score); $c.textContent = G.combo >= 3 ? G.combo + " COMBO" : ""; $p.style.width = Math.max(0, Math.min(100, (now / j.len_ms) * 100)) + "%";
    if (now > j.len_ms - 500) return gbFinish();
    G.raf = requestAnimationFrame(frame);
  };
  ov.querySelectorAll(".gbpad button").forEach((b) => b.addEventListener("pointerdown", (e) => { e.preventDefault(); G.press(b.dataset.k); }));
  G.onKey = (e) => { const k = GB_KEYS[e.key]; if (k) { e.preventDefault(); if (!e.repeat) G.press(k); } };
  document.addEventListener("keydown", G.onKey);
  G.raf = requestAnimationFrame(frame);
}
function gbClose() { const G = GBG; if (!G) return; G.over = true; cancelAnimationFrame(G.raf); document.removeEventListener("keydown", G.onKey); G.ov.remove(); document.body.classList.remove("gbplaying"); GBG = null; }
function gbQuit() { if (GBG && !GBG.over && !confirm("ออกกลางคัน? จะเสียสิทธิ์เล่นครั้งนี้ไป 1 ครั้ง")) return; gbClose(); GBX = null; gbLoad(); }
async function gbFinish() {
  const G = GBG; if (!G || G.over) return; G.over = true; cancelAnimationFrame(G.raf);
  const box = document.createElement("div"); box.className = "gbend"; box.innerHTML = '<div class="gbendbox center"><h3>กำลังตรวจคะแนน…</h3></div>'; G.ov.appendChild(box);
  let r = null, err = "";
  try { await new Promise((ok) => setTimeout(ok, 700)); r = await rpc("gb_submit", { p_token: tk(), p_run: G.j.run, p_presses: G.presses }); } catch (e) { err = e.message; }
  box.innerHTML = r ? `<div class="gbendbox center"><h2 style="margin:0">🎉 จบเพลง!</h2><div class="gbbig">${r.score}</div><small class="muted">/ 1000</small>
      <p style="margin:8px 0"><span class="pill">✨ Perfect ${r.perfect}</span> <span class="pill">👍 Good ${r.good}</span> <span class="pill">💨 Miss ${r.miss}</span> <span class="pill">🔥 คอมโบ ${r.max_combo}</span></p>
      <p class="muted" style="margin:4px 0 10px">คะแนนดีที่สุดของคุณ: <b>${r.best}</b>${r.score >= r.best ? " (สถิติใหม่ 🎊)" : ""}</p><button class="btn gold" onclick="gbDone()">ปิด</button></div>`
    : `<div class="gbendbox center"><h3>ส่งคะแนนไม่สำเร็จ</h3><p class="muted">${esc(err)}</p><button class="btn" onclick="gbDone()">ปิด</button></div>`;
  if (r && window.FX && r.score >= 800) FX.victory();
}
function gbDone() { gbClose(); GBX = null; gbLoad(); }
