/* มินิเกมต่อสู้มอนสเตอร์เคมี: เลือกสกิลตามคลาส → ตอบคำถามเพื่อใช้สกิล → มอนสเตอร์โต้กลับ กดลูกศรลดดาเมจ
   (ดาเมจ/เฉลย/รางวัล คำนวณที่เซิร์ฟเวอร์ทั้งหมด) */
const BATTLE = (() => {
  const S = { screen: "list", data: null, bat: null, fb: null, msg: "", busy: false, def: null, qtimer: null, hit: "", drop: null, trial: null, shown: {}, hpDelay: 0, dg: null, dgs: null, dgBat: null, mab: null };
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
  /* ===== ดันเจี้ยน (SQL 110): ไต่ชั้นต่อเนื่อง · ศึกแต่ละชั้นใช้ระบบศึกเดิม · ฉากพื้นหลังจาก assets/bg ===== */
  /* สกิลยูนิคของมอนสเตอร์ (SQL 112) — แคตาล็อกโหลดจาก monster_ability_list · รหัสสกิลของศึกอยู่ใน b.buffs.mab */
  const abInfo = (k) => (S.mab && S.mab.cat && S.mab.cat[k]) || null;
  const abTag = (id) => { const a = abInfo(S.mab && S.mab.mons && S.mab.mons[id]); return a ? `<span class="bt-abtag" title="${esc(a.descr)}">${esc(a.emoji)} ${esc(a.name)}</span>` : ""; };
  const abStrip = (b) => {
    const a = abInfo(b.buffs && b.buffs.mab); if (!a) return "";
    const ev = b.buffs.mev && b.buffs.mev.t === b.turn ? `<div class="bt-abev">${esc(b.buffs.mev.txt)}</div>` : "";
    return `<div class="bt-ab"><b>${esc(a.emoji)} สกิลยูนิค: ${esc(a.name)}</b><small>${esc(a.descr)}</small>${ev}</div>`;
  };
  async function abLoad() { try { const r = await rpc("monster_ability_list", { p_token: tk() }); S.mab = { cat: Object.fromEntries((r.abilities || []).map((x) => [x.key, x])), mons: r.monsters || {} }; } catch (e) { /* ยังไม่ได้รัน SQL 112: ซ่อนสกิลยูนิคเฉยๆ */ } }
  const inDg = (bid) => !!(S.dg && S.dgBat && S.dgBat === bid);
  const dgBgStyle = () => { const bg = S.dg && S.dg.bg; return bg ? ` style="background-image:linear-gradient(rgba(6,3,20,.18),rgba(6,3,20,.18)),url(${esc(bg)})"` : ""; };
  const dgBgCls = () => { const bg = S.dg && S.dg.bg; return bg ? "bt-cbg" + (/\/a\d+\.webp$/.test(bg) ? " px" : "") : ""; };
  const dgPips = (r) => Array.from({ length: r.floors }, (_, i) => { const f = i + 1, m = (r.map || [])[i] || {}; return `<i class="dgp ${f <= r.cleared ? "done" : f === r.floor ? "now" : ""} ${m.boss ? "boss" : ""}">${m.boss ? "👑" : f}</i>`; }).join("");
  const dgStars = (key) => { const x = S.dgs && (S.dgs.dungeons || []).find((d) => d.key === key); return x && x.stars ? "⭐".repeat(x.stars) : ""; };
  const perkChips = (r) => (r && r.perks && r.perks.length ? `<span class="dg-perks">${r.perks.map((p) => `<i class="dgk" title="${esc(p.name)}: ${esc(p.descr)}">${p.emoji}${p.n > 1 ? `<sup>${p.n}</sup>` : ""}</i>`).join("")}</span>` : "");
  const dgBar = (bid) => inDg(bid) ? `<div class="dg-bar"><b>${esc(S.dg.dungeon.emoji)} ${esc(S.dg.dungeon.name)} <small>${dgStars(S.dg.dungeon.key)}</small></b><span class="dg-pips">${dgPips(S.dg)}</span>${perkChips(S.dg)}</div>` : "";
  async function dgLoad() { try { S.dgs = await rpc("dungeon_status", { p_token: tk() }); } catch (e) { S.dgs = null; } return S.dgs; }
  async function dgOpen() { S.screen = "dg"; S.bat = null; paint(); await dgLoad(); paint(); }
  function dgEnter(run) { S.dg = run; if (run.status === "active" && (run.phase === "puzzle" || run.phase === "perk")) { S.bat = null; S.dgBat = null; S.trial = null; S.fb = null; S.drop = null; S.screen = "dgph"; return; }
    S.bat = run.battle; S.dgBat = run.battle && run.battle.id; S.trial = null; S.fb = null; S.drop = null; S.screen = "fight"; resume(); }
  async function dgStart(key) {
    if (S.busy) return; S.busy = true;
    try { const r = await rpc("dungeon_start", { p_token: tk(), p_key: key }); dgEnter(r); S.msg = `เข้าสู่ ${r.dungeon.name} ชั้น ${r.floor}/${r.floors}! เลือกสกิลแล้วตอบคำถามให้ถูก`; }
    catch (e) { toast(e.message); }
    S.busy = false; if (S.screen === "fight" && S.bat) await scene(S.bat); else paint();
  }
  async function dgNext() {
    if (S.busy || !S.dg) return; S.busy = true;
    try { const r = await rpc("dungeon_next", { p_token: tk(), p_run: S.dg.id }); dgEnter(r); S.msg = `ชั้น ${r.floor}/${r.floors}${r.boss ? " — บอสประจำดันเจี้ยน! 👑" : ""} · ฟื้น HP ให้ ${r.heal_pct}%`; }
    catch (e) { toast(e.message); }
    S.busy = false; if (S.screen === "fight" && S.bat) await scene(S.bat); else paint();
  }
  async function dgLeave() {
    if (!S.dg || !confirm("ออกจากดันเจี้ยน? จะได้รางวัลที่สะสมไว้เพียง 60% และรอบนี้ถือว่าใช้โควตาวันนี้ไปแล้ว")) return;
    clearTimeout(S.qtimer); if (S.def) clearTimeout(S.def.t); S.def = null; S.busy = true;
    try { S.dg = await rpc("dungeon_leave", { p_token: tk(), p_run: S.dg.id }); } catch (e) { toast(e.message); }
    S.busy = false; S.bat = null; S.fb = null; S.dgBat = null; const r = S.dg; S.dg = null; if (r && r.paid_exp + r.paid_coins > 0) toast(`ออกจากดันเจี้ยน +${r.paid_exp} EXP +${r.paid_coins} 🪙`); open();
  }
  /* ---- ประตูมิติ: ปริศนาก่อนสู้ + เลือกโบนัสหลังจบชั้น ---- */
  const dgPh = () => { if (!S.dg) return; DGPZ.stop(); S.bat = null; S.dgBat = null; S.screen = "dgph"; paint(); };
  function dgPzGo() {
    const host = document.getElementById("dgpz"); if (!host || !S.dg || !S.dg.pz) return;
    DGPZ.mount(S.dg.pz.type, host, async (ok, secs) => {
      if (!document.getElementById("dgpz") || !S.dg) return;
      S.busy = true; host.innerHTML = '<div class="center"><i class="sk-spin"></i> <small class="muted">กำลังเข้าสู่ศึก…</small></div>';
      try { const r = await rpc("dungeon_puzzle", { p_token: tk(), p_run: S.dg.id, p_ok: ok, p_secs: Math.round(secs * 10) / 10 }); dgEnter(r); S.msg = ok ? "🧠 ผ่านปริศนา! มอนสเตอร์อ่อนแรงลง เลือกสกิลแล้วตอบคำถามให้ถูก" : "ปริศนาไม่ผ่าน… มอนสเตอร์ได้เปรียบเล็กน้อย สู้ๆ!"; }
      catch (e) { toast(e.message); }
      S.busy = false; if (S.screen === "fight" && S.bat) await scene(S.bat); else paint();
    });
  }
  async function dgPick(key) {
    if (S.busy || !S.dg) return; S.busy = true;
    try { const r = await rpc("dungeon_pick", { p_token: tk(), p_run: S.dg.id, p_key: key }); dgEnter(r); }
    catch (e) { toast(e.message); }
    S.busy = false; paint();
  }
  function dgPhView() {
    const r = S.dg; if (!r) return '<div class="card"><p class="muted">กำลังโหลด…</p></div>';
    const top = `<div class="dg-bar"><b>${esc(r.dungeon.emoji)} ${esc(r.dungeon.name)} <small>${dgStars(r.dungeon.key)}</small></b><span class="dg-pips">${dgPips(r)}</span>${perkChips(r)}</div>`;
    const leave = '<button class="btn ghost small" onclick="BATTLE.dgLeave()">🚪 รับรางวัลสะสมแล้วออก</button>';
    if (r.phase === "perk") return `${top}<div class="card center dg-ph"><div style="font-size:46px">🎁</div><h2 style="margin:4px 0">ผ่านชั้น ${r.floor} แล้ว! เลือกโบนัส 1 อย่าง</h2><p class="muted">โบนัสอยู่กับคุณจนจบรอบนี้ · เลือกให้เข้ากับแผนของคุณ</p>
      <div class="dg-perkrow">${(r.perk_offer || []).map((p) => `<button class="dg-perk" onclick="BATTLE.dgPick('${esc(p.key)}')"><span class="pe">${p.emoji}</span><b>${esc(p.name)}</b><small>${esc(p.descr)}</small><i>ระดับ ${p.n}/${p.max}</i></button>`).join("")}</div>${leave}</div>`;
    const t = (r.pz && DGPZ.INFO[r.pz.type]) || DGPZ.INFO.tap;
    return `${top}<div class="card center dg-ph"><div class="dg-portal">🌀</div><h2 style="margin:4px 0">ประตูมิติ ชั้น ${r.floor}/${r.floors}${r.boss ? " 👑 บอส" : ""}</h2>
      <div id="dgpz"><div class="pz-intro"><div style="font-size:40px">${t.ico}</div><h3 style="margin:2px 0">ปริศนา: ${t.name}</h3><p>${t.how}</p>
        <p class="muted" style="font-size:.85em">ผ่านปริศนา → เลือดมอนสเตอร์ −12% และรางวัลชั้น +10% · ไม่ผ่าน → มอนสเตอร์เลือด +8% (ยังสู้ต่อได้)</p>
        <div class="row" style="justify-content:center"><button class="btn gold" onclick="BATTLE.dgPzGo()">▶️ เริ่มปริศนา</button>${leave}</div></div></div></div>`;
  }
  const dgEntry = () => { const x = S.dgs; return `<div class="card dg-entry"><div class="row"><div class="grow"><h3 style="margin:0">🏰 ท้าดันเจี้ยน</h3><p class="muted" style="margin:2px 0 0">ไต่ทีละชั้น สู้บอส เปิดหีบสมบัติ${x ? ` · เข้าได้วันนี้อีก ${Math.max(0, x.limit - x.used)}/${x.limit} รอบ${x.active ? " · มีรอบค้างอยู่" : ""}` : ""}</p></div><button class="btn gold" onclick="BATTLE.dgOpen()">เข้าสู่ดันเจี้ยน</button></div></div>`; };
  async function dgGate() { GAMES.setMode("battle"); DGPZ.stop(); S.bat = null; S.dg = null; await dgOpen(); }
  const dgBack = () => { S.dgSkip = true; open(); };
  const dgDone = () => { S.dg = null; S.dgBat = null; S.bat = null; S.fb = null; S.drop = null; LC.cls = LC.hst = LC.gbest = LC.gear = 0; open(); };
  function dgChest(r) {
    const c = r.chest || [];
    return c.length ? `<div class="dg-chest">${c.map((d) => `<div class="bt-drop ${esc(d.rarity)}">${d.image ? `<img src="${esc(d.image)}" alt="" onerror="this.remove()">` : ""}<div>🎁 <b>${esc(d.emoji || "")} ${esc(d.name)}</b> <span class="tag">${esc(d.rarity)}</span></div></div>`).join("")}</div>` : '<p class="muted">หีบบอสรอบนี้ว่างเปล่า… โชคดีรอบหน้านะ</p>';
  }
  function dgResult(b) {
    const win = b.status === "won", r = S.dg;
    if (b.status === "fled") return `<div class="card center"><p>ออกจากดันเจี้ยนแล้ว</p><button class="btn" onclick="BATTLE.dgDone()">กลับ</button></div>`;
    if (!r || r.status === "active" && !r.waiting_next && win) return `<div class="card center"><i class="sk-spin"></i> <small class="muted">กำลังสรุปผลชั้น…</small></div>`;
    const head = `<div class="dg-pips big">${dgPips(r)}</div>`;
    if (win && r.status === "active") return `<div class="card center gm-res perfect"><div style="font-size:54px">🏆</div><h2>ผ่านชั้น ${r.floor}/${r.floors}!</h2>${head}
      <p><span class="pill">สะสม +${r.exp} EXP</span> <span class="pill">+${r.coins} 🪙</span></p><p class="muted">รับรางวัลสะสมเมื่อจบรอบ · HP จะฟื้นให้ ${r.heal_pct}% ของสูงสุดตอนเข้าชั้นต่อไป</p>
      <div class="row" style="justify-content:center">${r.phase === "perk" ? `<button class="btn gold" onclick="BATTLE.dgPh()">🎁 เลือกโบนัส แล้วเข้าประตูมิติชั้น ${r.floor + 1}${(r.map[r.floor] || {}).boss ? " 👑" : ""}</button>` : `<button class="btn gold" onclick="BATTLE.dgNext()">➡️ ไปชั้น ${r.floor + 1}${(r.map[r.floor] || {}).boss ? " 👑 บอส" : ""}</button>`}<button class="btn ghost" onclick="BATTLE.dgLeave()">🚪 รับรางวัล 60% แล้วออก</button></div></div>`;
    if (r.status === "cleared") return `<div class="card center gm-res perfect"><div style="font-size:54px">🎉</div><h2>พิชิต ${esc(r.dungeon.name)}!</h2>${head}
      <p><span class="pill">+${r.paid_exp} EXP</span> <span class="pill">+${r.paid_coins} 🪙</span></p>${dgChest(r)}
      <div class="row" style="justify-content:center"><button class="btn gold" onclick="BATTLE.dgDone()">กลับ</button></div></div>`;
    return `<div class="card center gm-res"><div style="font-size:54px">💀</div><h2>พ่ายที่ชั้น ${r.floor}</h2>${head}
      <p><span class="pill">ผ่านมาแล้ว ${r.cleared}/${r.floors} ชั้น</span> ${r.paid_exp + r.paid_coins > 0 ? `<span class="pill">+${r.paid_exp} EXP</span> <span class="pill">+${r.paid_coins} 🪙</span>` : ""}</p>
      <p class="muted">${r.paid_exp + r.paid_coins > 0 ? "ได้รางวัลที่สะสมไว้ 60%" : "ยังไม่ได้ผ่านชั้นไหน จึงไม่มีรางวัล"} — ลองใหม่ได้ถ้ายังเหลือโควตาวันนี้</p>
      <div class="row" style="justify-content:center"><button class="btn gold" onclick="BATTLE.dgDone()">กลับ</button></div></div>`;
  }
  function dgView() {
    const d = S.dgs; if (!d) return '<div class="card"><p class="muted">กำลังโหลด…</p></div>';
    const act = d.active, left = Math.max(0, d.limit - d.used);
    const resume = act ? `<div class="card gm-res perfect center"><h3 style="margin:0">${esc(act.dungeon.emoji)} ${esc(act.dungeon.name)} ${dgStars(act.dungeon.key)} — ค้างอยู่ชั้น ${act.floor}/${act.floors}</h3><div class="dg-pips big">${dgPips(act)}</div>
      <button class="btn gold" onclick="BATTLE.dgStart('${esc(act.dungeon.key)}')">▶️ เล่นต่อ</button> <button class="btn ghost" onclick="BATTLE.dgLeave()">🚪 ออก (ได้ 60%)</button></div>` : "";
    return `<div class="card"><div class="row"><h3 style="margin:0" class="grow">🏰 ท้าดันเจี้ยน</h3><button class="btn ghost small" onclick="BATTLE.dgBack()">⬅️ ศึกปกติ</button></div>
      <p><span class="pill">🗝️ เข้าได้วันนี้อีก ${left}/${d.limit} รอบ</span></p><p class="muted" style="margin:4px 0 0">ไต่ทีละชั้นให้ถึงบอส · HP ยกต่อชั้น (ฟื้นให้เล็กน้อย) · แพ้หรือออกกลางคันได้ 60% ของรางวัลสะสม · ผ่านครบได้หีบบอส</p></div>${resume}
      ${d.dungeons.map((x) => `<div class="card dg-card ${x.locked ? "locked" : ""}"><div class="row"><h3 style="margin:0" class="grow">${esc(x.emoji)} ${esc(x.name)}</h3><span class="tag">${x.stars ? "⭐".repeat(x.stars) + " · " : ""}${x.floors} ชั้น</span></div>
        <p class="muted" style="margin:2px 0 8px">${esc(x.descr || "")}</p>
        <div class="dg-map">${x.map.map((f) => `<div class="dg-fl ${f.boss ? "boss" : ""} ${f.floor <= x.best ? "done" : ""}"><div class="dg-fbg" style="background-image:url(${esc(f.bg || "")})"></div>${(f.monster.image ? `<img src="${esc(f.monster.image)}" alt="" onerror="this.replaceWith(Object.assign(document.createElement('span'),{textContent:'${esc(f.monster.emoji || "👾")}'}))">` : `<span>${esc(f.monster.emoji || "👾")}</span>`)}<small>${f.boss ? "👑 บอส" : "ชั้น " + f.floor}</small><small class="muted">+${f.exp}</small></div>`).join("")}</div>
        <p style="margin:8px 0"><span class="pill">🏅 ชั้นสูงสุด ${x.best}/${x.floors}</span> <span class="pill">🏆 พิชิต ${x.clears} ครั้ง</span></p>
        ${x.locked ? `<p class="muted">🔒 ต้องถึงเลเวล ${x.min_level}</p>` : act ? "" : left > 0 ? `<button class="btn gold" onclick="BATTLE.dgStart('${esc(x.key)}')">⚔️ เข้าดันเจี้ยน</button>` : '<p class="muted">วันนี้เข้าครบโควตาแล้ว พรุ่งนี้มาใหม่</p>'}
        ${x.board.length ? `<details class="clsdet" open><summary>🥇 อันดับในห้อง (ชั้นสูงสุด)</summary><div class="dg-board">${x.board.map((b, i) => `<div class="row ${b.mine ? "mine" : ""}"><span>${["🥇", "🥈", "🥉"][i] || i + 1}</span><span class="grow">${esc(b.avatar || "")} ${esc(b.name)}</span><b>${b.best}/${x.floors}</b><small class="muted">${b.clears ? "🏆" + b.clears : ""}</small></div>`).join("")}</div></details>` : ""}</div>`).join("")}`;
  }
  const preload = (urls, ms = 9000) => Promise.race([Promise.all(urls.filter(Boolean).map((u) => new Promise((r) => { const i = new Image(); i.onload = i.onerror = r; i.src = u; if (i.complete) r(); }))), new Promise((r) => setTimeout(r, ms))]);
  function sceneUrls(bat) {
    const m = bat.monster, html = sprite(D.student) + mimg(m);
    return [inDg(bat.id) && S.dg.bg ? S.dg.bg : `assets/arenas/${m.theme || "lab"}.jpg`, ...[...html.matchAll(/src="([^"]+)"/g)].map((x) => x[1])];
  }
  /* เตรียมภาพฉาก (พื้นหลัง/มอนสเตอร์/ตัวละคร) ให้ครบก่อนเริ่มแสดง: ถ้าโหลดเร็ว (แคชแล้ว) ไม่ขึ้นหน้าจอโหลดเลย ถ้าเกิน 0.2 วิ ขึ้นหน้าจอโหลดจนภาพมาครบ (รอสูงสุด 9 วิแล้วเข้าฉากต่อ) */
  async function scene(bat) {
    let done = false; const p = preload(sceneUrls(bat)).then(() => { done = true; });
    await Promise.race([p, new Promise((r) => setTimeout(r, 200))]);
    if (!done) { S.ldg = true; paint(); await p; S.ldg = false; }
    paint();
  }
  const loadView = () => `<div class="card bt-field bt-ldg" aria-busy="true"><div class="bt-ldin"><i class="sk-spin"></i><b>กำลังโหลดฉากต่อสู้…</b><small class="bt-ldslow">เน็ตช้านิดหน่อย รอสักครู่นะ</small></div></div>`;
  /* รายละเอียดสกิล (กดดูเพิ่มเติม) */
  function skInfo(key) {
    const g = { key: "guard", name: "ตั้งรับ", emoji: "🛡️", kind: "guard", descr: "แทนโจมตี 1 เทิร์น กดลูกศรลดดาเมจ ถูกครบ = ลดดาเมจสูงสุด 20% + ฟื้น HP 3% (ตอบไว/สเตตัสสำคัญกว่า)", cd: 2 };
    const s = key === "guard" ? g : ((S.bat && S.bat.skills) || (S.data && S.data.skills) || []).find((x) => x.key === key); if (!s) return;
    const kd = s.kind === "guard" ? "🛡️ ตั้งรับ" : KIND[s.kind] ? `${KIND[s.kind][0]} ${KIND[s.kind][1]}` : "";
    frModal(`<h3 style="display:flex;align-items:center;gap:10px"><span class="bt-big">${key === "guard" ? "🛡️" : aico(s.key, s.emoji)}</span>${esc(s.name)}</h3>
      <div class="stsrc"><div class="row"><span class="grow">ประเภท</span><b>${kd}</b></div>${s.kind !== "buff" && s.kind !== "guard" && s.power != null ? `<div class="row"><span class="grow">พลัง</span><b>${s.power}</b></div>` : ""}${s.cd ? `<div class="row"><span class="grow">คูลดาวน์</span><b>${s.cd} เทิร์น</b></div>` : ""}${s.left > 0 ? `<div class="row"><span class="grow">รออีก</span><b>${s.left} เทิร์น</b></div>` : ""}</div>
      <p style="margin:10px 0 0">${esc(s.descr || "")}</p>`);
  }
  const arNow = () => { const d = S.data; if (!d || !d.arenas || !d.arenas.length) return null; return d.arenas.find((a) => a.key === S.arena && !a.locked) || d.arenas.find((a) => !a.locked) || d.arenas[0]; };
  const pickArena = (k) => { const a = (S.data.arenas || []).find((x) => x.key === k); if (!a) return; if (a.locked) return toast(`ปลดล็อกที่เลเวล ${a.min_level} 🔒`); S.arena = k; paint(); };

  async function open() {
    DGPZ.stop(); S.screen = "list"; S.fb = null; S.msg = ""; S.drop = null; GAMES.setMode("battle"); paint(); try { gearLoad(true); } catch (e) {}
    try {
      S.data = await rpc("battle_status", { p_token: tk() });
      if (S.data.active && S.data.active.status === "active") { S.bat = S.data.active; S.screen = "fight"; resume();
        try { const ts = await rpc("rank_trial_status", { p_token: tk() }); S.trial = ts.active_trial && ts.gate ? { name: ts.gate.name } : null; } catch (e) {} }
      S.dg = null; S.dgBat = null; if (!S.mab) abLoad().then(() => { if (S.screen === "list" || S.screen === "fight") paint(); });
      const ds = await dgLoad(), act = ds && ds.active;
      if (act && S.screen === "fight" && S.bat && act.battle && act.battle.id === S.bat.id) { S.dg = act; S.dgBat = S.bat.id; S.trial = null; }
      else if (act && !S.dgSkip && !(S.screen === "fight" && S.bat)) { if (act.waiting_next || !act.battle || act.battle.status !== "active") S.screen = "dg"; else { S.dg = act; S.dgBat = act.battle.id; S.bat = act.battle; S.screen = "fight"; resume(); } }
    } catch (e) { toast(e.message); }
    S.dgSkip = false;
    if (S.screen === "fight" && S.bat) await scene(S.bat); else paint();
  }
  function resume() { clearTimeout(S.qtimer); S.def = null; if (S.bat && S.bat.phase === "question") armQ(S.bat.q.elapsed || 0); if (S.bat && S.bat.phase === "defend") startDef(); }

  async function start(id) {
    if (S.busy) return; S.busy = true;
    try { S.bat = await rpc("battle_start", { p_token: tk(), p_monster: id }); S.trial = null; S.screen = "fight"; S.fb = null; S.msg = "การต่อสู้เริ่มขึ้น! เลือกสกิลแล้วตอบคำถามให้ถูกเพื่อใช้สกิล"; S.drop = null; }
    catch (e) { toast(e.message); }
    S.busy = false; if (S.screen === "fight" && S.bat) await scene(S.bat); else paint();
  }
  function begin(bat, gname) {   // เริ่มด่านบอสเลื่อนแรงค์ (เรียกจาก trial.js)
    S.bat = bat; S.screen = "fight"; S.fb = null; S.drop = null; S.gs = null; S.trial = { name: gname };
    S.msg = "ด่านบอสเลื่อนแรงค์! เลือกสกิลเพื่อโจมตี"; GAMES.setMode("battle"); resume(); scene(bat);
  }
  async function useSkill(key) {
    if (S.busy) return; S.busy = true; paint();
    try { S.bat = await rpc("battle_ask", { p_token: tk(), p_battle: S.bat.id, p_skill: key }); S.fb = null; armQ(0); }
    catch (e) { toast(e.message); }
    S.busy = false; paint();
  }
  const QSECS_N = 20, QSECS_T = 15;   // ด่านบอสเลื่อนแรงค์เวลาสั้นลง
  const qs = () => (S.trial ? QSECS_T : QSECS_N);
  const heavyNow = () => !!(S.bat && S.bat.turn % 3 === 0);   // เทิร์นที่ 3,6,9… มอนสเตอร์โจมตีหนัก ×1.5
  async function guard() {
    if (S.busy || !S.bat) return; S.busy = true; paint();
    try { S.bat = await rpc("battle_guard", { p_token: tk(), p_battle: S.bat.id }); S.fb = null; S.msg = "🛡️ ตั้งรับ! เตรียมกดลูกศร"; startDef(); }
    catch (e) { toast(e.message); }
    S.busy = false; paint();
  }
  function armQ(el) { clearTimeout(S.qtimer); clearInterval(S.qint);
    S.qint = setInterval(() => { const e = document.getElementById("bqt"); if (!e || !S.bat || S.bat.phase !== "question") return clearInterval(S.qint); e.textContent = "⏱️ " + Math.max(0, Math.ceil(qs() - (Date.now() - S.qstart) / 1000)); }, 250); S.qtimer = setTimeout(() => answer(-1), Math.max(300, (qs() - el) * 1000)); S.qstart = Date.now() - el * 1000; }
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
    if (!S.bat.guard) {   // ไม่ได้ตั้งรับ: มอนสเตอร์โจมตีอัตโนมัติ (รับ 70%) ไม่ต้องกดลูกศร
      S.def = { i: 0, hits: 0, marks: [], seq: [], n: 0, state: "send", auto: true }; S.msg = heavyNow() ? "⚠️ โจมตีหนัก!" : "";
      S.def.t = setTimeout(endDef, 700); paint(); return;
    }
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
      const sh = e.shield ? " (โล่ช่วยลดอีกครึ่ง 🛡️)" : "";
      S.msg = !e.guard ? `💥 ${S.bat.monster.atk_name}${e.heavy ? " (โจมตีหนัก ⚠️)" : ""} → รับดาเมจ ${e.taken}${sh} — ลอง “🛡️ ตั้งรับ” เพื่อลดดาเมจ`
        : e.perfect ? `🛡️ ปัดป้องสมบูรณ์! ไม่โดนเลย · สวนกลับ -${e.counter}${e.heal ? " · ฟื้น +" + e.heal : ""}`
        : `🛡️ ตั้งรับ ${S.bat.monster.atk_name}! กดถูก ${e.hits}/${e.n} → รับดาเมจ ${e.taken}${sh}`;
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

  function recBattle() {
    const b = S.bat; if (!b || (b.status !== "won" && b.status !== "lost") || S.recFor === b.id) return; S.recFor = b.id; const win = b.status === "won";
    gsRecord("battle", { correct: b.correct, hp_left: win ? b.p_hp : undefined, turns: win ? b.turn : undefined, wins: win ? 1 : 0 }).then((r) => { if (r) { r.bid = b.id; S.gs = r; if (S.screen === "result") paint(); } if (win) cardAfter("battle"); });
  }
  function finishLoad() { recBattle(); setTimeout(async () => { try { LC.cls = LC.hst = LC.gbest = LC.gear = 0; await load(); } catch (e) {} }, 2400); }   // รอให้เอฟเฟกต์เล่นจบก่อนรีเฟรชข้อมูล
  async function flee() {
    if (S.dg && S.dgBat === (S.bat && S.bat.id)) return dgLeave();
    if (!confirm(S.trial ? "หนีจากด่านบอส? จะนับเป็นการสอบ 1 ครั้ง ต้องรอพรุ่งนี้ถึงท้าใหม่ได้" : "หนีจากการต่อสู้? จะนับเป็น 1 รอบของวันนี้และไม่ได้รางวัล")) return;
    clearTimeout(S.qtimer); if (S.def) clearTimeout(S.def.t); S.def = null;
    try { await rpc("battle_flee", { p_token: tk(), p_battle: S.bat.id }); } catch (e) {}
    S.bat = null; open();
  }
  async function heal() {
    if (S.busy || !S.bat) return; S.busy = true;
    try {
      const it = await rpc("my_items", { p_token: tk() }), h = (it.items || []).find((x) => x.kind === "heal");
      if (!h || h.qty < 1) toast("ไม่มียาฟื้นฟู — ซื้อได้ที่แท็บ 🧪 ไอเทม");
      else {
        const r = await rpc("use_item", { p_token: tk(), p_item: h.id, p_battle: S.bat.id });
        const d = await rpc("battle_status", { p_token: tk() }); if (d.active && d.active.status === "active") S.bat = d.active;
        S.msg = "💚 ใช้ยา " + r.msg; toast(r.msg);
      }
    } catch (e) { toast(e.message); }
    S.busy = false; paint();
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
    Object.assign(el.style, { position: "absolute", width: W + "px", height: H + "px", backgroundImage: `url(assets/pixelfx/${m.src || name + ".png"})`, backgroundSize: `${m.cols * W}px auto`, imageRendering: m.sm ? "auto" : "pixelated", pointerEvents: "none" });
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
  const ELFX = { fire: "small-explosion", water: "mana-burst", plant: "healing-bloom", thunder: "zap-hit", chem: "acid-splash" };
  const ELB = { water: "fire", fire: "plant", plant: "chem", chem: "thunder", thunder: "water" };
  function matchup() {   // นับของที่ใส่ที่ชนะ/แพ้ธาตุมอนสเตอร์ตัวนี้ (จาก gear_status)
    const o = { adv: 0, weak: 0, top: null }; try {
      const me = typeof monElem === "function" ? monElem(S.bat.monster.id) : null, el = GEARS && GEARS.gear && GEARS.gear.el; if (!me || !el) return o;
      for (const [k, n] of Object.entries(el)) { if (ELB[k] === me) { o.adv += n; o.top = k; } else if (ELB[me] === k) o.weak += n; }
    } catch (e) {} return o;
  }
  const MONFX = { bubble: ["hit-spark", 1.5], rust: ["blunt-hit", 1.5], salt: ["hit-spark", 1.8], lemon: ["acid-splash", 1.4], fog: ["poison-cloud", 1.0] };
  /* มอนสเตอร์ตาย: เอฟเฟกต์แตกสลายที่พื้นที่มันยืน (เท้า) + แสดงความยินดีกับผู้เล่น */
  function deathFx(MO0) {
    const f = $f(); if (!f) return; const root = f.parentNode, MO = root.querySelector(".bt-mo") || MO0, PL = root.querySelector(".bt-pl"); if (!MO) return;
    const [fx, fy] = foot(MO, f);
    pfx("shatter-death", fx, fy - 12, { scale: 2.2 }); S.mdead = S.bat && S.bat.id; MO.classList.add("dead");
    later(350, () => pfx("collect-burst", fx, fy - 22, { scale: 2 }));
    if (PL) { const [px, py] = ctr(PL, f); later(700, () => { pfx("level-up", px, py + 10, { scale: 2 }); pfx("halo", px, py - 50, { scale: 1.6 }); num("🎉 ชนะแล้ว!", px, py - 90, "fast"); }); later(1000, () => pfx("firework-burst", px, py - 60, { scale: 1.3 })); }
  }
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
        const mu = matchup();
        if (mu.adv) { const E = ELFX[mu.top]; if (E) later(120, () => pfx(E, zx, zy, { scale: 1.8 })); num("ธาตุได้เปรียบ!", zx, zy - 112, "fast"); pop("shakebig", $f() && $f().parentNode); }
        pop("hurt", MO.querySelector(".bt-mimg,.bt-memo")); flash(ev.crit ? "flashbig" : "flash");
        num((ev.crit ? "💥 " : "") + "-" + ev.dmg, zx, zy - 50, ev.crit ? "crit" : "dmg");
        if (ev.fast) num("⚡ ตอบไว +" + (ev.spd || 0) + "%", zx, zy - 86, "fast");
        if (killed) later(500, () => deathFx(MO));
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
      if (e.guard && e.hits > 0 && e.taken > 0) num("🛡️ ลดดาเมจ " + Math.round(10 * (1 + e.hits / e.n)) + "%", zx, zy - 74, "fast");
      if (e.heavy && !e.guard) num("⚠️ โจมตีหนัก", zx, zy - 74, "dmg");
      if (matchup().weak && e.taken > 0) num("ธาตุแพ้ทาง! โดนแรงขึ้น", zx, zy - 100, "dmg");
      if (e.perfect) { num("✨ ปัดป้องสมบูรณ์!", zx, zy - 74, "crit"); if (e.counter) setTimeout(() => { const t = document.querySelector(".bt-mo"); if (t) { const r = t.getBoundingClientRect(), fr = $f().getBoundingClientRect(); num("-" + e.counter, r.left - fr.left + r.width / 2, r.top - fr.top, "dmg"); } if (e.heal) num("+" + e.heal, zx, zy - 20, "heal"); }, 450); }
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
      <div class="run-info"><section><h4>🎮 วิธีเล่น</h4><ul><li>ตอบคำถามเพื่อใช้สกิล</li><li>ตอบไว ≤4 วิ ดาเมจ +50% · สเตตัสสูงตีแรงขึ้น</li><li>มอนสเตอร์โจมตีกลับ กดลูกศรลดดาเมจได้เล็กน้อย</li></ul></section><section><h4>🏆 รางวัล</h4><ul><li>ชนะได้ EXP + เหรียญ</li><li>สุ่มดรอปไอเทม</li></ul></section></div>
      <p>${left > 0 ? `<span class="pill">🎁 รอบที่ได้รางวัลวันนี้เหลือ ${left}/${d.limit}</span>` : '<span class="pill">รอบที่ได้รางวัลวันนี้หมดแล้ว — เล่นฝึกได้ไม่จำกัด (ไม่ได้รางวัล)</span>'} <span class="pill">❤️ HP ${d.p_max}</span></p>
      <p class="muted" style="margin:6px 0 4px">สกิลของคุณ · แตะไอคอนเพื่อดูรายละเอียด</p>
      <div class="bt-skgrid">${d.skills.map((s) => `<button class="bt-skt ${s.kind}" onclick="BATTLE.info('${s.key}')" aria-label="ดูรายละเอียด ${esc(s.name)}"><span class="bt-big">${aico(s.key, s.emoji)}</span><b>${esc(s.name)}</b></button>`).join("")}</div></div>
      ${dgEntry()}
      ${statsPanel(true)}${arenaPicker()}
      <div class="bt-mgrid">${d.monsters.filter((m) => !d.arenas || !d.arenas.length || (m.arena || "lab") === (arNow() || {}).key).map((m) => `<div class="card bt-mcard">${mimg(m)}<h3>${esc(m.name)} <small class="muted">Lv.${m.level}</small> ${elBadge(monElem(m.id))}</h3>${abTag(m.id)}
        <p class="muted" style="margin:2px 0">${esc(m.descr || "")}</p><p style="margin:4px 0"><span class="pill">❤️ ${m.hp}</span> <span class="pill">🗡️ ${m.atk}</span></p>
        <p class="muted" style="margin:2px 0 8px">รางวัล +${m.exp} EXP · +${m.coins} 🪙 · ดรอปไอเทม</p>
        <button class="btn gold" onclick="BATTLE.start('${m.id}')">⚔️ ท้าสู้</button></div>`).join("") || '<div class="card"><p class="muted">ยังไม่มีมอนสเตอร์ในระบบ</p></div>'}</div>`;
  }

  /* แผงสเตตัสในศึก: สเตตัส 4 ค่า + ผลจริงต่อการต่อสู้ + โบนัสอุปกรณ์/การ์ด + ธาตุเทียบกับมอนสเตอร์ตัวนี้ (อ่านจากข้อมูลที่โหลดไว้แล้ว ไม่เรียกเซิร์ฟเวอร์เพิ่ม) */
  function statsPanel(full) {
    try {
      const X_ = typeof X !== "undefined" ? X : null, T = X_ && X_.stats ? statTotals(D.student.decor) : null, g = GEARS && GEARS.gear, ef = (X_ && X_.stats && X_.stats.effects) || {};
      if (!T && !g) return "";
      const intl = T ? T.int.total : 0, luk = T ? T.luk.total : 0, cfg = (GEARS && GEARS.cfg) || { adv: 4, weak: 4, cap: 20 };
      const inF = S.screen === "fight" && S.bat, mu = inF ? matchup() : { adv: 0, weak: 0 }, advP = Math.min(cfg.cap, mu.adv * cfg.adv), weakP = Math.min(cfg.cap, mu.weak * cfg.weak);
      const chip = (ic, label, val, tip) => `<span class="btsc" title="${esc(tip || "")}"><i>${ic}</i><small>${label}</small><b>${val}</b></span>`;
      const row1 = T ? [chip("🧠", "ปัญญา", T.int.total, `ดาเมจโจมตี +${intl} ต่อครั้ง · ฮีลแรงขึ้น ${intl * 3}%`), chip("💪", "ขยัน", T.dil.total, "EXP จากกิจกรรม"), chip("⚔️", "พลัง", T.str.total, `ดาเมจ +${(ef.boss_pct || 0) * 2}%`), chip("🍀", "โชค", T.luk.total, `คริติคอล ~${Math.min(40, luk * 2)}%`)].join("") : "";
      const bonus = (T ? `<span class="btsx">⚔️ ดาเมจ +${(ef.boss_pct || 0) * 2}% · +${intl} ต่อครั้ง</span><span class="btsx">💥 คริติคอล ~${Math.min(40, luk * 2)}%</span>` : "")
        + (g ? `<span class="btsx">${gi("atk")} โจมตี +${g.atk}%</span><span class="btsx">${gi("def")} ลดดาเมจ −${g.def}%</span><span class="btsx">${gi("hp")} HP +${g.hp}%</span>` : "");
      const m = inF ? S.bat.monster : null, me = m && typeof monElem === "function" ? monElem(m.id) : null;
      const el = me ? `<span class="btsx">${elBadge(me)} มอนสเตอร์ตัวนี้${advP ? ` · เรา<span class="up">ได้เปรียบ +${advP}% ดาเมจ</span>` : ""}${weakP ? ` · เรา<span class="dn">แพ้ทาง โดนแรงขึ้น +${weakP}%</span>` : ""}${!advP && !weakP ? " · ธาตุเสมอ" : ""}</span>` : "";
      return `<div class="card btstat"><div class="btsrow">${row1}</div><div class="btsbonus">${bonus}${el}</div>${full ? `<p class="muted" style="margin:6px 0 0;font-size:12px">เพิ่มสเตตัสได้ที่หน้าตัวละคร · ใส่ไอเทม/การ์ดที่มีโบนัสโจมตี ป้องกัน และธาตุ เพื่อสู้มอนสเตอร์ง่ายขึ้น</p>` : ""}</div>`;
    } catch (e) { return ""; }
  }
  function fightView() {
    const b = S.bat, m = b.monster, me = D.student;
    const buffs = Object.entries(b.buffs || {}).filter(([, v]) => v > 0).map(([k, v]) => `<span class="bt-buff">${BUFF[k] || k} ×${v}</span>`).join("");
    const ph = b.phase, cs = ph === "question" && b.q ? (b.skills.find((x) => x.key === b.q.skill) || {}) : null;
    const fm = S.shown.m, fp = S.shown.p; S.shown = { m: b.m_hp, p: b.p_hp };
    const th = m.theme || "lab"; if (S.ldg) return loadView();
    const dgo = inDg(b.id), arena = dgBar(b.id) + `<div class="card bt-field ar-${esc(th)} ${dgo ? dgBgCls() : ""} ${cs ? "charge" : ""} ${ph === "defend" ? "alert" : ""}"${dgo ? dgBgStyle() : ""}>
      ${skyHtml(th)}<div class="bt-floor"></div>${m.arena_name ? `<div class="bt-arname">${esc(m.arena_name)}</div>` : ""}
      <div class="bt-plate bt-pm"><b>${esc(m.name)}</b> <small>Lv.${m.level}</small> ${elBadge(monElem(m.id))}${matchupNote(monElem(m.id))}${hp(b.m_hp, b.m_max, "mon", fm, S.hpDelay)}</div>
      <div class="bt-mo ${ph === "defend" ? "lunge" : ""} ${S.mdead === b.id ? "dead gone" : ""}"><div class="bt-shadow"></div>${mimg(m, "float")}</div>
      <div class="bt-pl ${cs ? "charging" : ""}"><div class="bt-shadow"></div>${sprite(me)}${cs ? `<div class="bt-chg">${cs.emoji}</div>` : ""}</div>
      <div class="bt-plate bt-pp"><b>${esc(me.name)}</b> <small>เทิร์น ${b.turn}</small>${hp(b.p_hp, b.p_max, "me", fp, S.hpDelay)}<div class="bt-buffs">${buffs}</div></div>
      <div id="btfx" class="bt-fxl"></div></div>`;
    const arenaF = arena + (b.status === "active" ? abStrip(b) : "");
    if (S.fb) return arenaF + fbView();
    if (b.status !== "active") return arena + resultView();
    if (b.phase === "question") return arenaF + questionView();
    if (b.phase === "defend") return arenaF + defendView();
    const skills = b.skills.map((s) => { return `<div class="bt-skw"><button class="bt-skill big ${s.kind}" ${s.left > 0 || S.busy ? "disabled" : ""} onclick="BATTLE.skill('${s.key}')"><span class="bt-big">${aico(s.key, s.emoji)}${s.left > 0 ? `<i class="bt-cd" aria-label="รออีก ${s.left} เทิร์น">${s.left}</i>` : ""}</span><b>${esc(s.name)}</b><small>${s.left > 0 ? `รอ ${s.left} เทิร์น` : s.kind === "buff" ? "บัพ" : `${KIND[s.kind][1]} ${s.power}`}</small></button><button class="bt-info" onclick="BATTLE.info('${s.key}')" aria-label="รายละเอียด ${esc(s.name)}">ℹ️</button></div>`; }).join("");
    const warn = heavyNow() ? '<p class="bt-warn">⚠️ มอนสเตอร์กำลังรวบรวมพลัง! การโจมตีครั้งหน้าแรง ×1.5 — “ตั้งรับ” คุ้มมาก</p>' : "";
    return arenaF + statsPanel(false) + `<div class="card bt-msg bt-m-choose">${warn}<div class="row"><b class="grow">${S.msg ? esc(S.msg) : "เลือกสกิลของคุณ"}</b><button class="btn ghost small" onclick="BATTLE.heal()">💚 ยา</button> <button class="btn ghost small" onclick="BATTLE.flee()">🏃 หนี</button></div>
      <details class="clsdet"><summary>วิธีเล่น</summary><ul><li>เลือกสกิล แล้วตอบคำถามให้ถูกภายใน ${qs()} วิ สกิลถึงจะออกผล</li><li>ตอบภายใน 8 วิ ดาเมจโจมตี +25% ⚡</li><li>มอนสเตอร์โจมตีเอง (รับ 70%) ทุกเทิร์นที่ 3 โจมตีหนัก</li></ul></details><div class="bt-skillrow">${skills}${guardBtn(b)}</div>
      ${S.trial ? '<p class="muted" style="margin:8px 0 0">🎖️ ด่านบอสเลื่อนแรงค์ — HP ของคุณ 85% · เวลา 15 วิ · ตอบผิดบอสจะฟื้น HP 5% · ชนะเพื่อเลื่อนแรงค์ (แพ้ท้าใหม่ได้พรุ่งนี้)</p>' : b.rewarded ? "" : '<p class="muted" style="margin:8px 0 0">โหมดฝึก: รอบนี้ไม่ได้รางวัล</p>'}</div>`;
  }

  function questionView() {
    const q = S.bat.q, sk = S.bat.skills.find((s) => s.key === q.skill) || {};
    const left = Math.max(0.5, qs() - (q.elapsed || 0));
    return `<div class="card gm-q bt-msg bt-m-q"><div class="row"><span class="pill">${sk.emoji || ""} ${esc(sk.name || "")}</span><span class="muted grow">${esc(q.topic)}</span><span class="pill" id="bqt">⏱️ ${qs()}</span></div>
      <div class="bt-timer"><i style="animation-duration:${left}s"></i></div>
      <h3 style="margin:12px 0">${esc(q.question)}</h3>
      <div class="gm-choices">${q.choices.map((c, i) => `<button class="gm-choice" ${S.busy ? "disabled" : ""} onclick="BATTLE.pick(${i})"><b>${"กขคง"[i]}</b> ${esc(c)}</button>`).join("")}</div></div>`;
  }
  function fbView() {
    const f = S.fb, q = f.q, sk = f.skill; let txt;
    if (!f.correct) txt = `❌ ตอบผิด — ${sk.emoji} ${sk.name} พลาด!`;
    else if (sk.kind === "attack") txt = `${sk.emoji} ${sk.name}! ดาเมจ ${f.dmg}${f.crit ? " 💥 คริติคอล!" : ""}${f.fast ? ` ⚡ ตอบไว +${f.spd || 0}%` : ""}`;
    else if (sk.kind === "heal") txt = `${sk.emoji} ${sk.name}! ฟื้นฟู +${f.heal} HP`;
    else txt = `${sk.emoji} ${sk.name}! ได้รับบัพ`;
    const nextTxt = S.bat.status !== "active" ? "ดูผลการต่อสู้ ▶" : "ป้องกันการโจมตี ▶";
    return `<div class="card center ${f.correct ? "bt-ok" : "bt-bad"}"><h2 style="margin:0">${esc(txt)}</h2>
      <p class="muted" style="margin:8px 0">${f.correct ? "✅ ตอบถูก" : `คำตอบที่ถูก: <b style="color:var(--mint)">${"กขคง"[f.answer]}. ${esc(q.choices[f.answer])}</b>`}</p>
      ${f.explain ? `<p class="muted">💡 ${esc(f.explain)}</p>` : ""}<button class="btn gold" onclick="BATTLE.next()">${nextTxt}</button></div>`;
  }
  function guardBtn(b) {
    const left = b.guard_left || 0;
    return `<div class="bt-skw"><button class="bt-skill big guard ${heavyNow() ? "hot" : ""}" ${left > 0 || S.busy ? "disabled" : ""} onclick="BATTLE.guard()"><span class="bt-big">🛡️${left > 0 ? `<i class="bt-cd" aria-label="รออีก ${left} เทิร์น">${left}</i>` : ""}</span><b>ตั้งรับ</b><small>${left > 0 ? `รอ ${left} เทิร์น` : "CD 2"}</small></button><button class="bt-info" onclick="BATTLE.info('guard')" aria-label="รายละเอียด ตั้งรับ">ℹ️</button></div>`;
  }
  function defendView() {
    const d = S.def, p = S.bat.pend; if (!d) return '<div class="card"><p class="muted">…</p></div>';
    if (d.auto) return `<div class="card center bt-def"><h3 style="margin:0">💥 ${esc(p.name)} โจมตี!${heavyNow() ? " (หนัก ⚠️)" : ""}</h3><p class="muted" style="margin:6px 0 0">ไม่ได้ตั้งรับ — รับดาเมจ ${heavyNow() ? "105" : "70"}% ของพลังโจมตี</p></div>`;
    const cur = d.seq[d.i];
    const marks = d.seq.map((_, i) => `<span class="bt-mk ${d.marks[i] === 1 ? "ok" : d.marks[i] === 0 ? "no" : i === d.i ? "now" : ""}">${d.marks[i] === 1 ? "✔" : d.marks[i] === 0 ? "✖" : "•"}</span>`).join("");
    const big = d.state === "go" ? `<div class="bt-arrow go">${ARW[cur]}<div class="bt-ring" style="animation-duration:${d.win || curWin()}ms"></div></div>`
      : d.state === "ok" ? '<div class="bt-arrow ok">✔</div>' : d.state === "miss" ? '<div class="bt-arrow no">✖</div>'
      : d.state === "send" ? '<div class="bt-arrow">…</div>' : '<div class="bt-arrow">⚠️</div>';
    return `<div class="card center bt-def"><h3 style="margin:0">🛡️ ตั้งรับ ${esc(p.name)}! ดาเมจ ~${heavyNow() ? Math.round(p.dmg * 1.5) : p.dmg}${heavyNow() ? " (หนัก ⚠️)" : ""}</h3>
      <p class="muted" style="margin:4px 0 8px">กดลูกศรให้ตรงตามที่ปรากฏ (คีย์บอร์ด ← ↑ → ↓ หรือแตะปุ่มด้านล่าง) ยิ่งถูกมาก ดาเมจยิ่งลด · ถูกครบ = ไม่โดนเลย + สวนกลับ & ฟื้น HP · มอนสเตอร์ยิ่งเก่ง เวลากดยิ่งสั้น (${((d.win || curWin()) / 1000).toFixed(1)} วิ/ลูกศร)</p>
      <div class="bt-marks">${marks}</div>${big}
      <div class="bt-pad"><button onclick="BATTLE.arrow('U')">⬆️</button><div><button onclick="BATTLE.arrow('L')">⬅️</button><button onclick="BATTLE.arrow('D')">⬇️</button><button onclick="BATTLE.arrow('R')">➡️</button></div></div></div>`;
  }
  function resultView() {
    const b = S.bat, win = b.status === "won", dr = S.drop, m = b.monster;
    if (inDg(b.id) && b.status !== "fled" && S.dgFetch !== b.id) { S.dgFetch = b.id; rpc("dungeon_run", { p_token: tk(), p_run: S.dg.id }).then((r) => { S.dg = r; if (S.screen === "result") paint(); }).catch(() => {}); }
    if (S.fxFor !== b.id && b.status !== "fled") { S.fxFor = b.id; setTimeout(() => {
      if (win && S.mdead !== b.id) deathFx(document.querySelector(".bt-mo"));
      if (win) { FX.victory(); if (dr) { FX.screen("loot-beam", 0.5, 0.5, { scale: 3 }); FX.later(400, () => FX.screen("chest-open", 0.5, 0.55, { scale: 3 })); } }
      else FX.screen("curse", 0.5, 0.45, { scale: 3 }); }, 400); }
    if (inDg(b.id)) return dgResult(b);
    if (b.status === "fled") return `<div class="card center"><p>หนีจากการต่อสู้แล้ว${S.trial ? " (นับเป็นการสอบ 1 ครั้งของวันนี้)" : ""}</p><button class="btn" onclick="BATTLE.${S.trial ? "endTrial" : "back"}()">กลับ</button></div>`;
    if (S.trial) return `<div class="card center gm-res ${win ? "perfect" : ""}"><div style="font-size:54px">${win ? "🎖️" : "💀"}</div>
      <h2>${win ? `ผ่านด่านเลื่อนแรงค์ ${esc(S.trial.name)}!` : `ยังไม่ผ่านด่าน ${esc(S.trial.name)}`}</h2>
      <p>${win ? '<span class="pill">🏅 เลื่อนแรงค์สำเร็จ + รับเหรียญรางวัล</span>' : '<span class="pill">EXP ไม่หาย</span> <span class="pill">🗓️ พรุ่งนี้ท้าใหม่ได้</span>'}</p>
      ${S.gs && S.gs.bid === b.id ? gsCard(S.gs) : ""}
      <div class="row" style="justify-content:center"><button class="btn gold" onclick="BATTLE.endTrial()">${win ? "ดูแรงค์ใหม่" : "กลับหน้าหลัก"}</button></div></div>`;
    return `<div class="card center gm-res ${win ? "perfect" : ""}"><div style="font-size:54px">${win ? "🏆" : "💀"}</div>
      <h2>${win ? `ปราบ ${esc(m.name)} สำเร็จ!` : `พ่ายแพ้ให้ ${esc(m.name)}`}</h2>
      <p>${b.rewarded ? (b.exp || b.coins ? `<span class="pill">+${b.exp} EXP</span> ${b.coins ? `<span class="pill">+${b.coins} 🪙</span>` : ""}` : '<span class="pill">ไม่มีรางวัลรอบนี้</span>')
        : '<span class="pill">โหมดฝึก — ไม่ได้รางวัล</span>'}</p>
      ${S.gs && S.gs.bid === b.id ? gsCard(S.gs) : ""}
      ${dr ? `<div class="bt-drop ${dr.rarity}">${dr.image ? `<img src="${esc(dr.image)}" alt="" onerror="this.remove()">` : ""}<div>🎁 ดรอป! <b>${esc(dr.emoji || "")} ${esc(dr.name)}</b> <span class="tag">${dr.rarity}</span></div></div>`
        : win && b.rewarded ? '<p class="muted">รอบนี้ไม่มีไอเทมดรอป — ลองใหม่นะ</p>' : ""}
      ${!win && b.rewarded && b.exp ? '<p class="muted">รับ EXP ให้กำลังใจจากข้อที่ตอบถูก</p>' : ""}
      <div class="row" style="justify-content:center"><button class="btn gold" onclick="BATTLE.start('${m.id}')">⚔️ สู้อีกครั้ง</button><button class="btn ghost" onclick="BATTLE.back()">เลือกมอนสเตอร์</button></div></div>`;
  }

  function endTrial() { S.trial = null; S.bat = null; S.screen = "list"; LC.cls = LC.hst = LC.gbest = LC.gear = 0; load().then(() => go("home")).catch(() => go("home")); }
  const view = () => (S.screen === "dgph" ? dgPhView() : S.screen === "dg" ? dgView() : S.screen === "list" || !S.bat ? listView() : fightView());
  return { dgGate, dgBack, dgOpen, dgStart, dgNext, dgLeave, dgDone, dgPh, dgPick, dgPzGo, deathFx, info: skInfo, arena: pickArena, sprite, hp, skyHtml, pfx, num, pop, flash, shot, span, put, ctr, later, SKFX, COL, open, view, start, guard, begin, endTrial, skill: useSkill, pick: answer, next: afterFb, arrow: tapArrow, flee, heal, back, exit };
})();
