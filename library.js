/* ห้องสมุด 📚 (SQL 126): อ่านบทความ/ดูวิดีโอให้ครบเวลา + ตอบคำถามท้ายเรื่อง → รับ EXP/เหรียญ
   เซิร์ฟเวอร์จับเวลาและตรวจคำตอบ (ไม่ส่งเฉลยมาที่เครื่อง) · เรียกจากหอสมุดอะตอมในแผนที่เมือง */
const LIB = (() => {
  const S = { list: null, item: null, screen: "list", t0: 0, el: 0, tick: null, pick: null, busy: false, msg: "", err: "", yt: { id: "", played: 0, dur: 0, ended: false, ok: false, p: null, last: 0 } };
  const paint = () => GAMES.paint();
  const alive = () => GAMES.mode() === "lib" && document.body.dataset.tab === "game";
  const stop = () => { clearInterval(S.tick); S.tick = null; };
  const safeUrl = (u) => (/^https?:\/\//i.test(u || "") ? u : "");
  const ytId = (u) => { const m = String(u || "").match(/(?:youtu\.be\/|youtube\.com\/(?:watch\?(?:.*&)?v=|embed\/|shorts\/))([\w-]{11})/); return m ? m[1] : ""; };

  /* ----- วิดีโอ YouTube: บังคับดูจริงจนจบ (นับเวลาที่เล่นจริง ≥ 90% ของความยาว + เล่นถึงตอนจบ · กรอข้ามไม่นับ) ----- */
  let apiP = null;
  const api = () => apiP || (apiP = new Promise((res, rej) => {
    if (window.YT && YT.Player) return res();
    const s = document.createElement("script"); s.src = "https://www.youtube.com/iframe_api"; s.onerror = () => rej(new Error("โหลดตัวเล่นวิดีโอไม่ได้"));
    window.onYouTubeIframeAPIReady = () => res(); document.head.appendChild(s);
  }));
  const thumb = (id) => `https://i.ytimg.com/vi/${id}/hqdefault.jpg`;
  async function play(id) {
    S.yt.id = id; const box = document.getElementById("lbPlayer"); if (!box) return;
    box.innerHTML = '<div id="lbYT"></div>';
    try { await api(); } catch (e) { S.err = e.message; paint(); return; }
    S.yt.p = new YT.Player("lbYT", { videoId: id, width: "100%", height: "100%", playerVars: { rel: 0, playsinline: 1, modestbranding: 1, disablekb: 0 },
      events: { onReady: (e) => { S.yt.dur = e.target.getDuration() || 0; e.target.playVideo(); }, onStateChange: (e) => { S.yt.last = performance.now(); if (e.data === 0) { S.yt.ended = true; check(); } } } });
  }
  function check() {
    const y = S.yt; if (!y.id || y.ok) return;
    const dur = (y.p && y.p.getDuration && y.p.getDuration()) || y.dur;
    if (dur) y.dur = dur;
    if (y.ended && y.dur && y.played >= 0.9 * y.dur) { y.ok = true; paint(); }
  }
  function ytTick() {
    const y = S.yt; if (!y.p || !y.p.getPlayerState || y.ok) return;
    if (!document.getElementById("lbYT") && !document.querySelector("#lbPlayer iframe")) { y.p = null; return; }   // วาดหน้าใหม่แล้ว ตัวเล่นถูกทิ้ง
    const now = performance.now(), dt = Math.min(1.5, (now - (y.t || now)) / 1000); y.t = now;
    if (y.p.getPlayerState() === 0) y.ended = true;
    if (y.p.getPlayerState() === 1) y.played += dt * Math.min(2, y.p.getPlaybackRate ? y.p.getPlaybackRate() : 1);
    const el = document.getElementById("lbWatch"); if (el && y.dur) el.textContent = `🎬 ดูแล้ว ${Math.min(100, Math.round(y.played / y.dur * 100))}% (ต้องดูให้ถึงตอนจบ ≥ 90%)`;
    check();
  }

  async function open() { S.screen = "list"; S.item = null; S.msg = ""; S.err = ""; GAMES.setMode("lib"); paint(); await load(); }
  async function load() { try { S.list = await rpc("library_list", { p_token: tk() }); } catch (e) { toast(e.message); S.list = { items: [], today: 0, limit: 0 }; } paint(); }
  async function read(id) {
    if (S.busy) return; S.busy = true; S.err = "";
    try { S.item = await rpc("library_open", { p_token: tk(), p_item: id }); S.screen = "read"; S.yt = { id: "", played: 0, dur: 0, ended: false, ok: false, p: null, last: 0 }; S.pick = null; S.t0 = performance.now() - S.item.elapsed * 1000; startTick(); }
    catch (e) { toast(e.message); }
    S.busy = false; paint();
  }
  const isYt = () => !!(S.item && S.item.kind === "video" && ytId(S.item.url));
  function left() { return Math.max(0, Math.ceil(S.item.min_secs - (performance.now() - S.t0) / 1000)); }
  function startTick() {
    stop();
    S.tick = setInterval(() => {
      if (!alive() || !S.item) return stop();
      ytTick();
      const l = left(), b = document.getElementById("lbTimer"), f = document.getElementById("lbFin"), need = isYt() && !S.yt.ok;
      if (b) b.textContent = l > 0 ? `⏳ อ่าน/ดูต่ออีก ${l} วิ จึงรับรางวัลได้` : need ? "▶️ ดูวิดีโอให้จบก่อนถึงจะรับรางวัลได้" : "✅ ครบเงื่อนไขแล้ว";
      if (f) f.disabled = l > 0 || S.busy || need;
      if (l === 0 && !isYt()) { stop(); paint(); }
    }, 500);
  }
  async function finish() {
    if (S.busy || !S.item) return; S.busy = true; S.err = ""; paint();
    try {
      const r = await rpc("library_finish", { p_token: tk(), p_item: S.item.id, p_pick: S.pick });
      S.item.done = true; S.item.got = { exp: r.exp, coins: r.coins }; S.msg = `ได้รับ +${r.exp} EXP · +${r.coins} 🪙`; toast("📚 " + S.msg, 3000); try { FX.victory(); } catch (e) {}
      stop(); try { await GAMES.refreshProfile?.(); } catch (e) {}
    } catch (e) { S.err = e.message; }
    S.busy = false; paint();
  }
  const back = () => { stop(); try { S.yt.p && S.yt.p.destroy(); } catch (e) {} S.yt.p = null; S.screen = "list"; S.item = null; S.err = ""; load(); };
  const exit = () => { stop(); GAMES.home(); };
  const setPick = (i) => { S.pick = i; paint(); };

  const fmt = (txt) => esc(txt || "").split("\n").map((l) => l.startsWith("# ") ? `<h4 style="margin:12px 0 4px;color:var(--gold,#ffd24a)">${l.slice(2)}</h4>` : l.trim() === "" ? "" : `<p style="margin:4px 0;line-height:1.6">${l}</p>`).join("");

  function listView() {
    const l = S.list; if (!l) return '<div class="card"><p class="muted">กำลังโหลด…</p></div>';
    const cards = l.items.map((i) => `<div class="dl-row" style="padding:8px 0;border-top:1px solid rgba(255,255,255,.08)">${i.kind === "video" && ytId(i.url) ? `<div style="position:relative;flex:0 0 96px"><img src="${thumb(ytId(i.url))}" alt="" loading="lazy" style="width:96px;height:54px;object-fit:cover;border-radius:8px;display:block"><span style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center;font-size:22px;color:#fff;text-shadow:0 1px 4px #000">${i.done ? "✅" : "▶"}</span></div>` : `<div style="font-size:30px">${esc(i.icon)}</div>`}
      <div class="grow"><b>${esc(i.title)}</b> ${i.kind === "video" ? '<span class="pill">🎬 วิดีโอ</span>' : '<span class="pill">📖 บทความ</span>'}${i.category ? ` <small class="muted">${esc(i.category)}</small>` : ""}<br>
        <small class="muted">${esc(i.summary || "")}</small><br><small>${i.done ? "✅ อ่านแล้ว" : `🎁 +${i.exp} EXP · +${i.coins} 🪙 · ⏱️ ${i.min_secs} วิ${i.quiz ? " · ❓ มีคำถาม" : ""}`}</small></div>
      <button class="btn small ${i.done ? "ghost" : "gold"}" onclick="LIB.read('${i.id}')">${i.done ? "อ่านอีกครั้ง" : i.started ? "อ่านต่อ" : "เริ่มอ่าน"}</button></div>`).join("");
    return `<div class="card"><div class="row"><h3 style="margin:0" class="grow">📚 ห้องสมุด</h3><button class="btn ghost small" onclick="LIB.exit()">‹ กลับ</button></div>
      <p class="muted" style="margin:4px 0">อ่านหรือดูให้ครบเวลา ตอบคำถามท้ายเรื่องให้ถูก แล้วรับ EXP/เหรียญ (ได้ครั้งเดียวต่อเรื่อง)</p>
      <p><span class="pill">🎁 รับรางวัลวันนี้ ${l.today}${l.limit ? "/" + l.limit : ""} เรื่อง</span></p>${cards || '<p class="muted center">ยังไม่มีเนื้อหา — รอครูเพิ่มเร็วๆ นี้</p>'}</div>`;
  }
  function readView() {
    const i = S.item, l = left(), vid = ytId(i.url), ok = l === 0 && (!vid || S.yt.ok || i.done), url = safeUrl(i.url);
    const media = i.kind === "video" && vid ? `<div id="lbPlayer" style="position:relative;padding-top:56.25%;margin:8px 0;border-radius:10px;overflow:hidden;background:#000 url(${thumb(vid)}) center/cover no-repeat">${S.yt.id === vid && !S.yt.ok && S.yt.p ? "" : `<button onclick="LIB.play('${vid}')" aria-label="เล่นวิดีโอ" style="position:absolute;inset:0;width:100%;border:0;background:rgba(0,0,0,.25);color:#fff;font-size:58px;cursor:pointer">${S.yt.ok || i.done ? "✅ ▶" : "▶"}</button>`}</div>
        <p class="center muted" id="lbWatch" style="margin:2px 0">${S.yt.ok || i.done ? "✅ ดูจบแล้ว" : "🎬 กดเล่นแล้วดูให้ถึงตอนจบ (กรอข้ามไม่นับ)"}</p>`
      : i.kind === "video" && /\.(mp4|webm|mov)(\?.*)?$/i.test(url) ? `<video src="${esc(url)}" controls playsinline preload="metadata" style="width:100%;max-height:70vh;border-radius:10px;margin:8px 0;background:#000"></video>`
      : url ? `<p><a class="btn small" href="${esc(url)}" target="_blank" rel="noopener noreferrer">🔗 เปิดเนื้อหา${i.kind === "video" ? "วิดีโอ" : ""}ในแท็บใหม่</a> <small class="muted">แล้วกลับมาตอบคำถามที่นี่</small></p>` : "";
    const q = i.q ? `<div class="card" style="margin-top:10px"><h4 style="margin:0 0 6px">❓ ${esc(i.q.text)}</h4>${i.q.opts.map((o, k) => `<button class="btn small ${S.pick === k + 1 ? "gold" : "ghost"}" style="display:block;width:100%;text-align:left;margin:4px 0" ${i.done ? "disabled" : ""} onclick="LIB.pick(${k + 1})">${"กขคง"[k] || k + 1}. ${esc(o)}</button>`).join("")}</div>` : "";
    const act = i.done ? `<div class="card center bt-ok"><b>✅ รับรางวัลแล้ว</b> ${i.got ? `<span class="pill">+${i.got.exp} EXP</span> <span class="pill">+${i.got.coins} 🪙</span>` : ""}</div>`
      : `<p class="center muted" id="lbTimer">${ok ? "✅ ครบเงื่อนไขแล้ว" : l > 0 ? `⏳ อ่าน/ดูต่ออีก ${l} วิ จึงรับรางวัลได้` : "▶️ ดูวิดีโอให้จบก่อนถึงจะรับรางวัลได้"}</p>
         ${S.err ? `<p class="center" style="color:#ff8a8a">${esc(S.err)}</p>` : ""}<div class="center"><button class="btn gold" id="lbFin" ${!ok || S.busy || (i.q && !S.pick) ? "disabled" : ""} onclick="LIB.finish()">🎁 รับรางวัล +${i.exp} EXP · +${i.coins} 🪙</button></div>`;
    return `<div class="card"><div class="row"><h3 style="margin:0" class="grow">${esc(i.icon)} ${esc(i.title)}</h3><button class="btn ghost small" onclick="LIB.back()">‹ รายการ</button></div>
      ${media}${i.body ? `<div style="margin:6px 0">${fmt(i.body)}</div>` : ""}${q}${act}</div>`;
  }
  const view = () => (S.screen === "read" && S.item ? readView() : listView());
  return { open, view, read, play, finish, back, exit, pick: setPick };
})();
