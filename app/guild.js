/* Mini Guild — กิลด์ห้องเดียวกัน แข่งอันดับรวมทุกห้อง (SQL 45) — ส่วนหนึ่งของหน้านักเรียน โหลดต่อกันตามลำดับใน index.html */
let GLD = null, GLDB = null;   // GLD = guild_status (โหลดพร้อม load()) · GLDB = guild_board (โหลดเมื่อเปิดแท็บกิลด์)
const gtag = (n) => n ? `<span class="gtag">[${esc(n)}]</span> ` : "";
const gDate = (iso) => iso ? new Date(String(iso).slice(0, 10) + "T00:00:00").toLocaleDateString("th-TH", { day: "numeric", month: "short" }) : "";

const gmedal = (rk, cls = "") => rk >= 1 && rk <= 3 ? `<img class="gmedal ${cls}" src="assets/medals/rank${rk}.png" alt="อันดับ ${rk}">` : `<span class="lbn">${rk}</span>`;
const gem = (e) => ({ "🥇": 1, "🥈": 2, "🥉": 3 }[e] ? gmedal({ "🥇": 1, "🥈": 2, "🥉": 3 }[e], "sm") : esc(e || ""));
const gShort = (n) => { const t = String(n || "").replace(/^(นางสาว|เด็กชาย|เด็กหญิง|นาย|นาง|ด\.ช\.|ด\.ญ\.|น\.ส\.)\s*/, "").trim(); return t.split(/\s+/)[0] || n; };
const gChar = (x) => { const dc = x.decor || {}, o = dc.outfit, base = "assets/chars/" + (x.char_class || "novice") + (altGender(x.char_class, dc.gender) ? "_alt" : ""); return `<img class="gch" loading="lazy" decoding="async" src="${base}${o ? "_" + esc(o.key) : ""}.png" alt="" onerror="this.onerror=null;this.src='${base}.png'">`; };
/* ยืนเรียงแบบวงบอยแบนด์: หัวหน้ากลาง · ฉากหลังนิ่ง ไม่มีแอนิเมชัน/เอฟเฟกต์ เพื่อไม่ให้หน้าหน่วง */
const gStrip = (ms, showGp, seed) => { const a = (ms || []).slice(), li = a.findIndex((x) => x.leader); if (li >= 0) { const [l] = a.splice(li, 1); a.splice(Math.floor(a.length / 2), 0, l); } const mid = Math.floor((a.length - 1) / 2);
  return `<div class="gband gb${(seed || 0) % 5}"><div class="gstage">${a.map((x, i) => `<div class="gmem ${x.me ? "me" : ""} ${i === mid ? "mid" : ""}">${x.leader ? '<i class="gcrown">👑</i>' : ""}${gChar(x)}</div>`).join("")}</div><div class="gnames">${a.map((x) => `<div class="gnm ${x.me ? "me" : ""}"><b>${esc(gShort(x.name))}</b>${showGp && x.gp != null ? `<small>${x.gp} แต้ม</small>` : ""}</div>`).join("")}</div></div>`; };

function guildChip() {
  if (!GLD || !GLD.cfg) return "";
  const c = GLD.cfg, m = GLD.my;
  let t = "";
  if (m) {
    const claim = (GLD.tiers || []).some((x) => x.claimable) || (GLD.prize && GLD.prize.eligible && (!GLD.prize.claimed_rank || (GLD.prize.room_bonus && !GLD.prize.claimed_room)));
    t = `🏰 ${esc(m.name)} · ${c.hidden ? "🔒 อันดับถูกซ่อนวันสุดท้าย" : m.rank ? `อันดับ ${m.rank} · เฉลี่ย ${m.avg} แต้ม/คน` : `เฉลี่ย ${m.avg ?? 0} แต้ม/คน`}${claim ? " · 🎁 มีรางวัลให้รับ!" : ""}`;
  } else if (c.can_edit) t = `🏰 Mini Guild: ยังไม่มีกิลด์ — ตั้งหรือเข้ากิลด์ได้ถึง ${gDate(c.join_until)} (ไม่เลือก ครูจะสุ่มให้)`;
  else if (c.phase === "soon") t = `🏰 Mini Guild ${gDate(c.start)}–${gDate(c.end)} · เปิดรับสมัครกิลด์ ${gDate(c.reg_from)}`;
  else if (c.phase === "running") t = "🏰 Mini Guild กำลังดำเนินอยู่ — ครูกำลังจัดกิลด์ให้คุณ";
  else return "";
  return `<div class="notice" onclick="go('guild')">${t} — กดดู</div>`;
}

function guildBoardLoad() {
  GLDB = { loading: true };
  rpc("guild_board", { p_token: tk() }).then((r) => { GLDB = r; }).catch(() => { GLDB = { rows: [], err: true }; })
    .then(() => { if (tab === "guild") { const v = $("#view"); if (v) v.innerHTML = guildHtml(); } });
}

function guildHtml() {
  if (!GLD || !GLD.cfg) return `<div class="card"><h3>🏰 Mini Guild</h3><p class="muted">ยังไม่เปิดใช้งาน หรือกำลังโหลด… (ถ้าไม่ขึ้น ให้รีเฟรชหน้า)</p></div>`;
  if (GLDB === null) guildBoardLoad();
  const c = GLD.cfg, m = GLD.my, peek = !!PEEK;
  const phase = { soon: `เปิดรับสมัคร ${gDate(c.reg_from)} · กิจกรรม ${gDate(c.start)}–${gDate(c.end)}`, reg: `กิจกรรมเริ่ม ${gDate(c.start)} · สมัคร/เปลี่ยนกิลด์ได้ถึง ${gDate(c.join_until)}`,
    running: `กำลังแข่ง · เหลือ ${c.days_left} วัน (ถึง ${gDate(c.end)})${c.hidden ? " · 🔒 วันสุดท้าย ซ่อนอันดับเพื่อความลุ้น" : ""}`, ended: "กิจกรรมจบแล้ว · ประกาศผลและรับรางวัลได้" }[c.phase] || "";
  const head = `<div class="card"><h3>🏰 Mini Guild</h3><p class="muted" style="margin:0">${phase}</p>
    <p class="muted" style="margin:6px 0 0;font-size:.85em">กิลด์ 4–5 คนในห้องเดียวกัน · แต้มกิลด์มาจาก EXP ที่ได้จากเกม เควส เช็คชื่อ ส่งงาน (สูงสุด ${c.cap_day} แต้ม/คน/วัน) · จัดอันดับด้วยแต้มเฉลี่ยต่อคน เทียบทุกห้อง · ต้องมีแต้มส่วนตัว ≥ ${c.min_personal} ถึงรับรางวัลได้</p></div>`;
  let mine = "";
  if (!m) {
    if (c.can_edit && !peek) {
      mine = `<div class="card"><h3>ตั้งกิลด์ใหม่</h3>
        <div class="row"><input id="gname" maxlength="16" placeholder="ชื่อกิลด์ 2–16 ตัวอักษร" style="flex:1"><button class="btn gold" onclick="guildCreate()">ตั้งกิลด์</button></div>
        <p class="muted" style="font-size:.85em;margin:6px 0 0">ชื่อกิลด์จะแสดงหน้าชื่อของสมาชิกทุกคน · เปลี่ยนชื่อได้ 1 ครั้ง</p></div>
        <div class="card"><h3>เข้าร่วมกิลด์ในห้อง ${esc(GLD.class_name || "")}</h3>${(GLD.open || []).length
          ? (GLD.open || []).map((g) => `<div class="row" style="justify-content:space-between;padding:6px 0;border-bottom:1px solid var(--line)"><span><b>${esc(g.name)}</b> <small class="muted">${g.size}/${c.max_members} คน</small></span><button class="btn small" onclick="guildJoin('${g.id}')">เข้าร่วม</button></div>`).join("")
          : '<p class="muted">ยังไม่มีกิลด์ที่ว่างอยู่ — ตั้งกิลด์ใหม่ชวนเพื่อนได้เลย</p>'}</div>`;
    } else mine = `<div class="card"><p class="muted" style="margin:0">${c.phase === "soon" ? "ยังไม่เปิดรับสมัครกิลด์" : "คุณยังไม่มีกิลด์ — ครูจะสุ่มจัดให้ รอดูในหน้านี้"}</p></div>`;
  } else {
    const tiers = GLD.tiers || [], nxt = tiers.find((t) => !t.reached), avg = Number(m.avg || 0);
    const pct = m.avg == null ? 0 : nxt ? Math.min(100, Math.round((avg / nxt.min_avg) * 100)) : 100;
    mine = `<div class="card"><h3>${gtag(m.name)}${esc(m.name)} ${m.leader ? '<span class="pill">👑 หัวหน้า</span>' : ""}</h3>
      <div class="row" style="gap:8px;flex-wrap:wrap;margin:6px 0">${c.hidden ? '<span class="pill">🔒 อันดับถูกซ่อน</span>' : `<span class="pill">อันดับรวม ${m.rank ?? "—"}</span><span class="pill">ในห้อง ${m.room_rank ?? "—"}</span><span class="pill">เฉลี่ย ${m.avg ?? 0} แต้ม/คน</span><span class="pill">แต้มฉัน ${m.personal_gp ?? 0}</span>`}</div>
      ${!m.ranked ? `<p class="muted" style="font-size:.85em">กิลด์ต้องมีอย่างน้อย ${c.min_members} คนถึงติดอันดับ (ตอนนี้ ${m.size})</p>` : ""}
      ${c.hidden ? "" : `<div class="lvgauge" style="margin:8px 0"><i style="width:${pct}%"></i></div><div class="muted" style="font-size:.85em">${nxt ? `ขั้นถัดไป ${gem(nxt.emoji)} ${esc(nxt.label)} ที่ ${nxt.min_avg} แต้ม/คน (ตอนนี้ ${avg})` : "ปลดล็อกครบทุกขั้นแล้ว 🎉"}</div>`}
      ${gStrip(m.members, true, 0)}
      ${peek ? "" : `<div class="row" style="margin-top:10px;gap:8px;flex-wrap:wrap">${m.can_rename ? '<button class="btn small ghost" onclick="guildRename()">✏️ เปลี่ยนชื่อ (1 ครั้ง)</button>' : ""}${c.can_edit ? '<button class="btn small ghost" onclick="guildLeave()">ออกจากกิลด์</button>' : ""}</div>`}</div>
      <div class="card"><h3>🎁 รางวัลปลดล็อกของกิลด์</h3>${tiers.map((t) => `<div class="row" style="justify-content:space-between;align-items:center;padding:6px 0;border-bottom:1px solid var(--line);opacity:${t.reached ? 1 : .6}">
        <span>${gem(t.emoji)} <b>${esc(t.label)}</b> <small class="muted">เฉลี่ย ≥ ${t.min_avg}</small><br><small class="muted">${t.coins ? t.coins + " เหรียญ " : ""}${t.pulls ? "· ตั๋วกาชา " + t.pulls + " " : ""}${t.exp ? "· " + t.exp + " EXP" : ""}</small></span>
        ${t.claimed ? '<span class="pill">✅ รับแล้ว</span>' : t.claimable && !peek ? `<button class="btn small gold" onclick="guildClaimTier(${t.tier})">รับรางวัล</button>` : t.reached ? '<span class="muted" style="font-size:.8em">แต้มส่วนตัวยังไม่ถึงเกณฑ์</span>' : '<span class="muted">🔒</span>'}</div>`).join("")}</div>`;
    const p = GLD.prize;
    if (p) mine += `<div class="card"><h3>ผลสุดท้าย</h3><div class="row" style="align-items:center;gap:10px">${gmedal(p.rank, "big")}<p style="margin:0">กิลด์ของคุณได้อันดับ <b>${p.rank}</b> ของทุกห้อง · อันดับ ${p.room_rank} ในห้อง</p></div>
      ${p.prize ? `<p>${esc(p.prize.label)}: ${p.prize.coins} เหรียญ${p.prize.pulls ? " · ตั๋วกาชา " + p.prize.pulls : ""}${p.prize.exp ? " · " + p.prize.exp + " EXP" : ""}</p>` : ""}${p.room_bonus ? `<p>${gmedal(1, "sm")} โบนัสกิลด์อันดับ 1 ของห้อง: ${p.room_bonus} เหรียญ</p>` : ""}
      ${(p.prize && !p.claimed_rank) || (p.room_bonus && !p.claimed_room) ? (p.eligible && !peek ? '<button class="btn gold" onclick="guildClaimPrize()">รับรางวัลอันดับ</button>' : '<p class="muted">แต้มส่วนตัวไม่ถึงเกณฑ์ หรือหมดเวลารับรางวัลแล้ว</p>') : '<span class="pill">✅ รับรางวัลอันดับแล้ว</span>'}</div>`;
  }
  let board = "";
  if (GLDB && GLDB.loading) board = `<div class="card"><h3>${gmedal(1, 'sm')} อันดับกิลด์ทุกห้อง</h3><p class="muted">กำลังโหลด…</p></div>`;
  else if (GLDB && GLDB.hidden) board = `<div class="card"><h3>${gmedal(1, 'sm')} อันดับกิลด์ทุกห้อง</h3><p class="muted">🔒 วันสุดท้ายซ่อนอันดับเพื่อความลุ้น — ประกาศผลหลังจบกิจกรรม</p></div>`;
  else if (GLDB) board = `<div class="card"><h3>${gmedal(1, 'sm')} อันดับกิลด์ทุกห้อง</h3>${(GLDB.rows || []).length ? (GLDB.rows || []).map((r) => `<div class="gbrow ${r.mine ? "me" : ""}"><div class="lbrow gb">${gmedal(r.rank)}<div class="lbm"><b class="lbname">${esc(r.name)}</b><small class="muted">ห้อง ${esc(r.class_name)} · ${r.size} คน</small></div><div class="lbr"><b>${r.avg}</b><small class="muted">แต้ม/คน</small></div></div>${gStrip(r.members, false, r.rank)}</div>`).join("") : '<p class="muted">ยังไม่มีกิลด์ติดอันดับ (ต้องมีสมาชิก ≥ ' + c.min_members + ' คน)</p>'}${GLDB.unranked ? `<p class="muted" style="font-size:.85em">มี ${GLDB.unranked} กิลด์ที่สมาชิกยังไม่ครบ ${c.min_members} คน จึงยังไม่ติดอันดับ</p>` : ""}</div>`;
  return head + mine + board;
}

const guildCreate = () => { const n = ($("#gname") || {}).value || ""; if (n.trim().length < 2) return toast("ชื่อกิลด์ต้องยาว 2–16 ตัวอักษร"); GLDB = null; return act(() => rpc("guild_create", { p_token: tk(), p_name: n }), "ตั้งกิลด์แล้ว 🏰"); };
const guildJoin = (id) => { GLDB = null; return act(() => rpc("guild_join", { p_token: tk(), p_guild: id }), "เข้าร่วมกิลด์แล้ว 🏰"); };
const guildLeave = () => confirm("ออกจากกิลด์นี้?") && (GLDB = null, act(() => rpc("guild_leave", { p_token: tk() }), "ออกจากกิลด์แล้ว"));
const guildRename = () => { const n = prompt("ชื่อกิลด์ใหม่ (2–16 ตัวอักษร) — เปลี่ยนได้ครั้งเดียว"); if (!n) return; GLDB = null; return act(() => rpc("guild_rename", { p_token: tk(), p_name: n }), "เปลี่ยนชื่อกิลด์แล้ว ✨"); };
const guildClaimTier = (t) => act(() => rpc("guild_claim_tier", { p_token: tk(), p_tier: t }), "รับรางวัลกิลด์แล้ว 🎁").then((r) => { if (r && window.FX) FX.victory(); return r; });
const guildClaimPrize = () => act(() => rpc("guild_claim_prize", { p_token: tk() }), "รับรางวัลอันดับแล้ว 🏆").then((r) => { if (r && window.FX) FX.victory(); return r; });
