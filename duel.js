/* ท้าดวลเพื่อนแบบเรียลไทม์: ห้องรอ (เพื่อนออนไลน์ในห้อง) → ส่งคำท้า → ตอบคำถามพร้อมกันทุกรอบ → ตอบถูก/ไวกว่า = ทำดาเมจ
   เรียลไทม์ด้วยการโพลล์ RPC (~1 วิตอนดวล, ~2.5 วิตอนรอ) · เซิร์ฟเวอร์ตัดสินทุกอย่าง · ใช้ฉาก/เอฟเฟกต์ร่วมกับ BATTLE */
const DUEL = (() => {
  const S = { lobby: null, d: null, screen: "lobby", arena: "lab", busy: false, picked: null, skillOn: false, t: null, qint: null,
    sig: "", round: 0, revFor: -1, shown: null, hpDelay: 0, fin: false, finAt: 0, seenInv: {}, msg: "" };
  const LET = "กขคง";
  const paint = () => GAMES.paint();
  const alive = () => GAMES.mode() === "duel" && document.body.dataset.tab === "game";
  const stop = () => { clearTimeout(S.t); clearInterval(S.qint); S.t = null; };
  const thumb = (f) => { const cls = f.char_class || "novice", dc = f.decor || {}; return `assets/chars/${cls}${altGender(cls, dc.gender) ? "_alt" : ""}${dc.outfit ? "_" + dc.outfit.key : ""}.png`; };
  const face = (f, cls = "dl-av") => `<img class="${cls}" src="${esc(thumb(f))}" alt="" onerror="this.onerror=null;this.src='assets/chars/${esc(f.char_class || "novice")}.png'">`;

  async function open() {
    S.screen = "lobby"; S.d = null; S.fin = false; S.msg = ""; S.sig = ""; GAMES.setMode("duel"); paint();
    try { S.lobby = await rpc("duel_lobby", { p_token: tk() }); } catch (e) { toast(e.message); }
    if (S.lobby && S.lobby.active) enter(S.lobby.active);
    paint(); loop();
  }
  function enter(v) { S.d = v; S.screen = "fight"; S.fin = false; S.picked = null; S.skillOn = false; S.round = 0; S.revFor = -1; S.shown = null; S.sig = ""; }
  function loop() {
    stop(); if (!alive()) return;
    S.t = setTimeout(async () => {
      if (!alive()) return stop();
      try {
        if (S.screen === "fight" && S.d && S.d.status === "active") apply(await rpc("duel_state", { p_token: tk(), p_duel: S.d.id }));
        else if (S.screen === "lobby") {
          const l = await rpc("duel_lobby", { p_token: tk() }); S.lobby = l;
          for (const iv of l.invites) if (!S.seenInv[iv.id]) { S.seenInv[iv.id] = 1; toast(`🤝 ${iv.from.name} ท้าคุณดวล!`, 4000); try { navigator.vibrate && navigator.vibrate(120); } catch (e) {} }
          if (l.active) { enter(l.active); paint(); } else sigPaint("L" + JSON.stringify([l.invites.map((i) => i.id), l.sent && l.sent.id, l.online.map((o) => o.f.id + o.busy), l.used]));
        }
      } catch (e) { /* ปล่อยให้โพลล์รอบหน้าลองใหม่ */ }
      loop();
    }, S.screen === "fight" && S.d && S.d.status === "active" ? 900 : 2500);
  }
  function sigPaint(sig) { if (sig !== S.sig) { S.sig = sig; paint(); } }

  /* ----- รับสถานะดวลใหม่ ----- */
  function apply(v) {
    const old = S.d; S.d = v;
    if (v.round !== S.round) { S.round = v.round; S.picked = null; S.skillOn = false; qTimer(v.elapsed || 0); }
    const reveal = (v.phase === "reveal" || v.status === "done") && v.last && S.revFor !== v.round;
    if (reveal) { S.revFor = v.round; S.hpDelay = 0; S.shown = old ? { me: old.me_hp, opp: old.opp_hp } : S.shown; paint(); setTimeout(() => playReveal(v), 40); }
    if (v.status === "done" && !S.fin) { S.fin = true; S.finAt = Date.now() + 3600; setTimeout(() => { S.screen = "result"; paint(); if (v.result && v.result.win) FX.victory(); else if (v.result && !v.result.draw) FX.screen("curse", 0.5, 0.45, { scale: 3 }); setTimeout(() => { try { load(); } catch (e) {} }, 300); }, 3600); }
    if (v.status === "cancelled" || v.status === "expired") { toast("การดวลถูกยกเลิก (ไม่มีการตอบ)"); toLobby(); return; }
    sigPaint(["F", v.status, v.phase, v.round, v.answered, v.opp_answered, S.picked, S.skillOn, reveal].join("|"));
  }
  function qTimer(el) {
    clearInterval(S.qint); const t0 = performance.now() - el * 1000;
    S.qint = setInterval(() => {
      const d = S.d; const e = document.getElementById("dlt"); if (!d || !alive()) return clearInterval(S.qint);
      if (e && d.phase === "q") e.textContent = "⏱️ " + Math.max(0, Math.ceil(20 - (performance.now() - t0) / 1000)) + " วิ";
      const w = document.getElementById("dlw"); if (w && d.phase === "reveal") { const left = Math.max(0, Math.ceil(d.wait - (performance.now() - S.revT) / 1000)); w.textContent = left > 0 ? `รอบถัดไปใน ${left} วิ` : "กำลังเริ่มรอบถัดไป…"; }
    }, 250);
  }

  /* ----- แอ็กชัน ----- */
  async function invite(to) {
    if (S.busy) return; S.busy = true;
    try { await rpc("duel_invite", { p_token: tk(), p_to: to, p_arena: S.arena }); toast("ส่งคำท้าแล้ว ⚔️ รอเพื่อนกดรับ", 2500); S.lobby = await rpc("duel_lobby", { p_token: tk() }); }
    catch (e) { toast(e.message); }
    S.busy = false; S.sig = ""; paint();
  }
  async function respond(id, ok) {
    if (S.busy) return; S.busy = true;
    try { const v = await rpc("duel_respond", { p_token: tk(), p_duel: id, p_accept: ok }); if (ok) { enter(v); qTimer(0); S.round = v.round; toast("เริ่มดวล! ตอบให้ไวและแม่น ⚡", 2200); } else S.lobby = await rpc("duel_lobby", { p_token: tk() }); }
    catch (e) { toast(e.message); try { S.lobby = await rpc("duel_lobby", { p_token: tk() }); } catch (x) {} }
    S.busy = false; S.sig = ""; paint(); loop();
  }
  async function cancelSent(id) { try { await rpc("duel_leave", { p_token: tk(), p_duel: id }); S.lobby = await rpc("duel_lobby", { p_token: tk() }); } catch (e) { toast(e.message); } S.sig = ""; paint(); }
  async function pick(i) {
    const d = S.d; if (!d || d.phase !== "q" || d.answered || S.busy) return; S.busy = true; S.picked = i; paint();
    try { apply(await rpc("duel_answer", { p_token: tk(), p_duel: d.id, p_pick: i, p_skill: !!S.skillOn })); } catch (e) { toast(e.message); S.picked = null; }
    S.busy = false; paint();
  }
  const toggleSkill = () => { if (S.d && S.d.skill_ready && !S.d.answered) { S.skillOn = !S.skillOn; paint(); } };
  async function leave() {
    const d = S.d; if (!d) return toLobby();
    if (d.status === "active" && !confirm("ยอมแพ้และออกจากการดวล? (ถือว่าแพ้)")) return;
    try { if (d.status === "active") await rpc("duel_leave", { p_token: tk(), p_duel: d.id }); } catch (e) {}
    toLobby(); try { load(); } catch (e) {}
  }
  function toLobby() { S.screen = "lobby"; S.d = null; S.fin = false; S.sig = ""; clearInterval(S.qint); rpc("duel_lobby", { p_token: tk() }).then((l) => { S.lobby = l; paint(); loop(); }).catch(() => { paint(); loop(); }); paint(); loop(); }
  const exit = () => { stop(); GAMES.home(); };
  const pickArena = (k) => { const a = ((S.lobby || {}).arenas || []).find((x) => x.key === k); if (!a || a.locked) return toast(a ? `ปลดล็อกที่เลเวล ${a.min_level} 🔒` : ""); S.arena = k; S.sig = ""; paint(); };

  /* ----- เอฟเฟกต์ตอนเฉลยรอบ ----- */
  function strike(from, to, skKey, x, delay) {
    BATTLE.later(delay, () => {
      const f = document.getElementById("btfx"); if (!f) return;
      const impact = (zx, zy) => {
        const fx = BATTLE.SKFX[skKey] || BATTLE.SKFX.gen_hit;
        if (fx.hit) BATTLE.pfx(fx.hit[0], zx, zy, { scale: fx.hit[1] }); else BATTLE.pfx("hit-spark", zx, zy, { scale: 1.6 });
        if (fx.extra) BATTLE.pfx(fx.extra[0], zx, zy, { scale: fx.extra[1] });
        if (x.crit) BATTLE.pfx("crit-hit", zx, zy, { scale: 1.9 });
        if (x.skill) BATTLE.pfx("small-explosion", zx, zy, { scale: 1.2 });
        BATTLE.pop("shake", document.querySelector(to + " .bt-spr")); BATTLE.flash(x.crit || x.skill ? "flashbig" : "flash");
        BATTLE.num((x.crit ? "💥 " : x.skill ? "🔥 " : "") + "-" + x.dmg, zx, zy - 50, x.crit || x.skill ? "crit" : "dmg");
        if (x.fast) BATTLE.num("⚡ ไว!", zx, zy - 86, "fast");
      };
      const col = BATTLE.COL[skKey] || "#ffb347";
      if (fx0(skKey).shot) BATTLE.shot(from, to, fx0(skKey).shot, x.crit || x.skill, col, impact);
      else if (fx0(skKey).span) BATTLE.span(from, to, fx0(skKey).span, fx0(skKey).scale, impact);
      else { const A = document.querySelector(to), b = f.getBoundingClientRect(), r = A.getBoundingClientRect(); impact(r.left + r.width / 2 - b.left, r.top + r.height * 0.45 - b.top); }
    });
  }
  const fx0 = (k) => BATTLE.SKFX[k] || BATTLE.SKFX.gen_hit;
  function playReveal(v) {
    const L = v.last, me = L.a, op = L.b; S.revT = performance.now();
    S.hpDelay = 0;
    const mk = (v.skill || {}).key, ok = (v.opp_skill || {}).key;
    if (me.dmg > 0) strike(".bt-pl", ".bt-op", mk, me, 150);
    else if (me.skill_try) BATTLE.num("ท่าไม้ตายพลาด!", 120, 90, "miss");
    if (op.dmg > 0) strike(".bt-op", ".bt-pl", ok, op, me.dmg > 0 ? 950 : 250);
    if (!me.ok) BATTLE.later(200, () => { const f = document.getElementById("btfx"); if (f) BATTLE.put('<span class="fizz">💨</span>', 900, 110, 190); });
  }

  /* ----- หน้าจอ ----- */
  function lobbyView() {
    const l = S.lobby; if (!l) return '<div class="card"><p class="muted">กำลังโหลด…</p></div>';
    const left = Math.max(0, l.limit - l.used);
    const arenas = `<div class="ar-grid">${l.arenas.map((a) => `<div class="ar-card t-${esc(a.theme)} ${S.arena === a.key ? "on" : ""} ${a.locked ? "lock" : ""}" onclick="DUEL.arena('${a.key}')"><div class="ae">${a.locked ? "🔒" : esc(a.emoji)}</div><b>${esc(a.name)}</b><small>${a.locked ? "Lv." + a.min_level : ""}</small></div>`).join("")}</div>`;
    const inv = l.invites.map((i) => `<div class="dl-inv dl-row">${face(i.from)}<div class="grow"><b>${esc(i.from.name)}</b> ท้าคุณดวล!<br><small class="muted">สนาม ${esc(i.arena_name || i.arena)} · เหลือเวลา ${i.secs} วิ</small></div>
        <button class="btn small gold" onclick="DUEL.respond('${i.id}',true)">⚔️ รับคำท้า</button><button class="btn small ghost" onclick="DUEL.respond('${i.id}',false)">ปฏิเสธ</button></div>`).join("");
    const sent = l.sent ? `<div class="dl-inv dl-row">${face(l.sent.to)}<div class="grow">⏳ รอ <b>${esc(l.sent.to.name)}</b> ตอบรับ… <small class="muted">(${l.sent.secs} วิ)</small></div><button class="btn small ghost" onclick="DUEL.cancel('${l.sent.id}')">ยกเลิก</button></div>` : "";
    const on = l.online.map((o) => `<div class="dl-row">${face(o.f)}<div class="grow"><span class="dl-on"></span><b>${esc(o.f.name)}</b> <small class="muted">Lv.${o.f.level}</small>${o.busy ? ' <small class="muted">· กำลังดวล</small>' : ""}</div>
        <button class="btn small gold" ${o.busy || l.sent || S.busy ? "disabled" : ""} onclick="DUEL.invite('${o.f.id}')">⚔️ ท้าดวล</button></div>`).join("")
      || '<p class="muted center" style="margin:10px 0">ยังไม่มีเพื่อนออนไลน์ในห้อง<br><small>ชวนเพื่อนเปิดหน้านี้ไว้พร้อมกัน แล้วท้าดวลได้เลย</small></p>';
    return `<div class="card"><div class="row"><h3 style="margin:0" class="grow">🤝 ท้าดวลเพื่อน</h3><button class="btn ghost small" onclick="DUEL.exit()">‹ กลับ</button></div>
      <div class="run-info"><section><h4>🎮 วิธีเล่น</h4><ul><li>ตอบคำถามพร้อมกัน 8 รอบ</li><li>ตอบถูกทำดาเมจใส่อีกฝ่าย</li><li>ตอบไว (≤6 วิ) และตอบก่อนได้โบนัส</li></ul></section><section><h4>💥 ท่าไม้ตาย</h4><ul><li>ประจำคลาส ใช้ได้ 1 ครั้ง/แมตช์</li><li>ตอบผิด = เสียสิทธิ์</li></ul></section></div>
      <p><span class="pill">🏆 ชนะ ${l.wins}</span> <span class="pill">💀 แพ้ ${l.losses}</span> ${left > 0 ? `<span class="pill">🎁 รอบที่ได้รางวัลวันนี้เหลือ ${left}/${l.limit}</span>` : '<span class="pill">โควตารางวัลวันนี้หมดแล้ว — เล่นเพื่อความสนุกได้</span>'}</p></div>
      ${inv ? `<div class="card"><h3 style="margin:0 0 4px">📨 คำท้าที่ได้รับ</h3>${inv}</div>` : ""}
      <div class="card"><h3 style="margin:0 0 4px">🏟️ เลือกสนามที่จะท้าดวล</h3>${arenas}</div>
      <div class="card"><h3 style="margin:0 0 4px">🟢 เพื่อนในห้องที่ออนไลน์ (${l.online.length})</h3>${sent}${on}</div>`;
  }

  function arenaHtml(d, extra) {
    const th = d.theme || "lab", me = D.student, sh = S.shown || { me: d.me_hp, opp: d.opp_hp }; S.shown = { me: d.me_hp, opp: d.opp_hp };
    return `<div class="card bt-field dl ar-${esc(th)}">${BATTLE.skyHtml(th)}<div class="bt-floor"></div><div class="bt-arname">${esc(d.arena_name || "")} · รอบ ${Math.min(d.round, d.rounds)}/${d.rounds}</div>
      <div class="bt-plate dl-po"><b>${esc(d.opp.name)}</b> <small>Lv.${d.opp.level}</small>${BATTLE.hp(d.opp_hp, d.hp_max, "mon", sh.opp, 900)}</div>
      <div class="dl-vs">VS</div>
      <div class="bt-op"><div class="bt-shadow"></div>${BATTLE.sprite(d.opp)}</div>
      <div class="bt-pl dl-pl"><div class="bt-shadow"></div>${BATTLE.sprite(Object.assign({}, me, { decor: d.me.decor, char_class: d.me.char_class }))}</div>
      <div class="bt-plate dl-pp"><b>${esc(d.me.name)}</b> <small>คุณ</small>${BATTLE.hp(d.me_hp, d.hp_max, "me", sh.me, 1500)}</div>
      <div id="btfx" class="bt-fxl"></div></div>${extra || ""}`;
  }

  function fightView() {
    const d = S.d; if (!d) return '<div class="card"><p class="muted">กำลังโหลด…</p></div>';
    if (S.screen === "result") return resultView();
    if (d.phase === "q" && d.q && d.status === "active") {
      const sk = d.skill || {}, left = Math.max(0.5, 20 - (d.elapsed || 0));
      const ch = d.q.choices.map((c, i) => `<button class="gm-choice ${S.picked === i ? "pk" : ""}" ${d.answered || S.busy ? "disabled" : ""} onclick="DUEL.pick(${i})"><b>${LET[i]}</b> ${esc(c)}</button>`).join("");
      return arenaHtml(d, `<div class="card gm-q dl-q"><div class="row"><span class="pill">รอบ ${d.round}/${d.rounds}</span><span class="muted grow">${esc(d.q.topic)}</span><span class="pill" id="dlt">⏱️ ${Math.ceil(left)} วิ</span><button class="btn ghost small" onclick="DUEL.leave()">🏳️ ยอมแพ้</button></div>
        <div class="bt-timer"><i style="animation-duration:${left}s"></i></div>
        <h3 style="margin:12px 0">${esc(d.q.question)}</h3>
        ${d.skill_ready && !d.answered ? `<button class="btn small ${S.skillOn ? "gold dl-skillbtn on" : "ghost dl-skillbtn"}" onclick="DUEL.skill()">${S.skillOn ? "🔥 เตรียมใช้" : (sk.emoji || "💥")} ท่าไม้ตาย: ${esc(sk.name || "")} ×1.7 ${S.skillOn ? "(เปิดอยู่ — ถ้าตอบผิดเสียสิทธิ์)" : ""}</button>` : ""}
        <div class="gm-choices">${ch}</div>
        <p class="dl-wait">${d.answered ? (d.opp_answered ? "กำลังตัดสิน…" : `✅ ส่งคำตอบแล้ว — รอ ${esc(d.opp.name)}…`) : d.opp_answered ? `⚡ ${esc(d.opp.name)} ตอบแล้ว! รีบหน่อย` : "เลือกคำตอบให้ไวและแม่น"}</p></div>`);
    }
    const L = d.last;
    if (!L) return arenaHtml(d, '<div class="card center"><p class="muted">กำลังเริ่มรอบถัดไป…</p></div>');
    const me = L.a, op = L.b, line = (n, x) => `${x.ok ? "✅" : x.pick == null ? "⌛ ไม่ตอบ" : "❌"} <b>${esc(n)}</b> ${x.ok ? `ทำดาเมจ <b>${x.dmg}</b>${x.skill ? " 🔥ท่าไม้ตาย" : ""}${x.crit ? " 💥คริ" : ""}${x.fast ? " ⚡ไว" : ""}${x.first ? " 🥇ตอบก่อน" : ""}` : x.skill_try ? "· ท่าไม้ตายพลาด" : "· ไม่ทำดาเมจ"}`;
    const fin = d.status === "done";
    return arenaHtml(d, `<div class="card center ${me.ok ? "bt-ok" : "bt-bad"}"><p style="margin:0 0 4px">คำตอบที่ถูก: <b style="color:var(--mint)">${LET[L.answer]}</b></p>
      <p style="margin:4px 0">${line("คุณ", me)}</p><p style="margin:4px 0">${line(d.opp.name, op)}</p>
      ${L.explain ? `<p class="muted" style="margin:6px 0">💡 ${esc(L.explain)}</p>` : ""}<p class="dl-wait" id="dlw">${fin ? "จบการดวล…" : "รอบถัดไปเริ่มเร็วๆ นี้…"}</p></div>`);
  }

  function resultView() {
    const d = S.d, r = d.result || {}, win = r.win, draw = r.draw;
    return `<div class="card center gm-res ${win ? "perfect" : ""}"><div style="font-size:54px">${win ? "🏆" : draw ? "🤝" : "💀"}</div>
      <h2>${win ? `ชนะ ${esc(d.opp.name)}!` : draw ? `เสมอกับ ${esc(d.opp.name)}` : `แพ้ให้ ${esc(d.opp.name)}`}</h2>
      <p>HP คุณ ${d.me_hp} · ${esc(d.opp.name)} ${d.opp_hp}</p>
      <p>${r.exp || r.coins ? `<span class="pill">+${r.exp} EXP</span> ${r.coins ? `<span class="pill">+${r.coins} 🪙</span>` : ""}` : '<span class="pill">ไม่ได้รางวัล (โควตาหมด/เล่นน้อยกว่า 3 รอบ/ดวลคู่เดิมซ้ำ)</span>'}</p>
      <div class="row" style="justify-content:center"><button class="btn gold" onclick="DUEL.lobby()">🤝 กลับห้องท้าดวล</button><button class="btn ghost" onclick="DUEL.exit()">ออก</button></div></div>`;
  }

  const view = () => (S.screen === "lobby" ? lobbyView() : fightView());
  return { open, view, invite, respond, cancel: cancelSent, pick, skill: toggleSkill, leave, lobby: toLobby, exit, arena: pickArena };
})();
