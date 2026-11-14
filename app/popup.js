/* ป๊อปอัปครูบุ๊ค — ส่วนหนึ่งของหน้านักเรียน (index.html) โหลดต่อกันตามลำดับใน index.html */
/* ===== ป๊อปอัปครูบุ๊ค: คำแนะนำ/กำลังใจ ===== */
const KB_CHEER = ["ตั้งใจเรียนนะ แล้วเคมีจะเป็นเรื่องสนุก! ⚗️", "ผิดไม่เป็นไร ลองใหม่ได้เสมอ นักเคมีเก่งๆ ก็เริ่มจากทดลองพลาดมาก่อน 💪", "เก่งมากที่เข้ามาวันนี้ ครูภูมิใจนะ ✨", "สะสมไอเทมไปแต่งตัวให้เท่ที่สุดในห้อง 🎨", "ทำเควสประจำวันให้ครบ EXP จะขึ้นไวมาก 🗺️", "จำไว้นะ ความสม่ำเสมอชนะความเก่งเสมอ 🔥", "ถามครูได้ทุกเรื่องเลย ไม่มีคำถามโง่ๆ ในห้องแล็บของเรา 🧪"];
function kbMessages() {
  const m = [], now = D.assignments.filter((a) => !a.status && a.due_date).map((a) => ({ a, n: dayDiff(a.due_date) })).sort((x, y) => x.n - y.n);
  const late = now.filter((x) => x.n < 0), soon = now.filter((x) => x.n >= 0 && x.n <= 3);
  if (late.length) m.push(`📌 มีงานเลยกำหนด ${late.length} ชิ้น (${late[0].a.title || "งาน"}) ส่งช้ายังได้ EXP ครึ่งหนึ่งนะ รีบส่งเลย!`);
  if (soon.length) m.push(`⏰ “${soon[0].a.title || "งาน"}” ${soon[0].n === 0 ? "ครบกำหนดวันนี้" : "อีก " + soon[0].n + " วันครบกำหนด"} อย่าลืมส่งนะ`);
  if (!now.length) m.push("✅ ไม่มีงานค้างเลย เยี่ยมมาก! ไปทำเควสหรือเล่นมินิเกมต่อได้เลย");
  if ((X.free_pulls || 0) > 0) m.push(`🎟️ เธอมีตั๋วสุ่มกาชาฟรี ${X.free_pulls} ใบ อย่าลืมไปหมุนนะ`);
  const b = X.boss; if (b && !b.defeated && !b.ended) m.push(`⚔️ บอส ${b.name || "ประจำสัปดาห์"} เหลือ HP ${b.hp}/${b.max_hp} ช่วยกันทำเควสโจมตีเลย!`);
  if (b && b.can_claim) m.push("🎁 ปราบบอสสำเร็จแล้ว! กดรับรางวัลได้เลย");
  const st = (D.attendance_summary || {}).streak; if (st >= 2) m.push(`🔥 มาติดกัน ${st} คาบแล้ว รักษาสตรีคไว้นะ!`);
  if (D.rank_info && D.rank_info.next_exp != null && D.rank_info.exp_to_next != null && D.rank_info.exp_to_next <= 60) m.push(`🏆 อีกแค่ ${D.rank_info.exp_to_next} EXP ก็เลื่อนแรงค์แล้ว สู้ๆ!`);
  return m.concat(KB_CHEER.slice().sort(() => Math.random() - 0.5).slice(0, 3));
}
let KBI = 0, KBMSGS = [], KBT = null;
function kbShow(open) {
  let el = $("#kbpop"); if (!el) { el = document.createElement("div"); el.id = "kbpop"; document.body.appendChild(el); }
  if (!D) { el.remove(); return; }
  if (!KBMSGS.length) KBMSGS = kbMessages();
  const msg = KBMSGS[KBI % KBMSGS.length];
  el.className = "kbpop" + (open ? " open" : "");
  el.innerHTML = `<div class="kbbub"><button class="kbx" aria-label="ปิด" onclick="kbClose()">✕</button><div class="kbn">ครูบุ๊ค</div><div class="kbm">${esc(msg)}</div>
      <div class="kbb"><button class="btn small ghost" onclick="kbNext()">ข้อความถัดไป ›</button></div></div>
    <button class="kbav" aria-label="ครูบุ๊ค" onclick="kbToggle()"><img src="assets/chars/krubook.png" alt="" onerror="this.replaceWith(document.createTextNode('🧙'))"></button>`;
  if (open && typeof FX !== "undefined") FX.at(".kbav", "mana-burst", { scale: 1.2 });
  clearTimeout(KBT); if (open) KBT = setTimeout(kbClose, 14000);
}
const kbNext = () => { KBI++; kbShow(true); };
const kbClose = () => { clearTimeout(KBT); const e = $("#kbpop"); if (e) e.classList.remove("open"); };
const kbToggle = () => { const e = $("#kbpop"); if (e && e.classList.contains("open")) kbClose(); else { KBI++; kbShow(true); } };
function kbAuto() {   // เด้งอัตโนมัติ 1 ครั้งต่อการเข้าสู่ระบบ/โหลดหน้า เฉพาะหน้าหลัก
  KBMSGS = []; KBI = 0; kbShow(false);
  let seen = false; try { seen = sessionStorage.getItem("kb_seen") === "1"; } catch (e) {}
  if (!seen && tab === "home") { setTimeout(() => { if (tab === "home") kbShow(true); }, 700); try { sessionStorage.setItem("kb_seen", "1"); } catch (e) {} }
}
function remindHtml() {
  const list = D.assignments.filter((a) => !a.status && a.due_date).map((a) => ({ a, n: dayDiff(a.due_date) }))
    .filter((x) => x.n <= 3).sort((x, y) => x.n - y.n);
  const ptn = !PEEK && pointsLeft() > 0 ? `<div class="notice gold" onclick="go('decor');setTimeout(()=>document.getElementById('statcard')?.scrollIntoView({behavior:'smooth'}),60)">⭐ มีแต้มสเตตัส <b>${pointsLeft()}</b> แต้ม — กดเพื่อไปแจกแต้มเลย!</div>` : "";
  const tk0 = ptn + ((X.free_pulls || 0) > 0
    ? `<div class="notice gold" onclick="go('gacha')">🎟️ มีตั๋วสุ่มกาชาฟรี <b>${X.free_pulls}</b> ใบ — กดเพื่อไปสุ่มเลย!</div>` : "");
  if (!list.length) return tk0 + `<div class="card remind ok"><b>✅ ไม่มีงานค้างหรือใกล้ครบกำหนด</b> <span class="muted">เก่งมาก! ไปทำเควสหรือเล่นเกมสะสม EXP ต่อได้เลย</span></div>`;
  return tk0 + `<div class="card remind"><h3>⏰ งานที่ต้องส่ง</h3>${list.slice(0, 5).map(({ a, n }) => {
    const late = n < 0, tag = late ? `<span class="tag no">เลยกำหนด ${-n} วัน</span>` : n === 0 ? '<span class="tag late">ส่งวันนี้!</span>' : `<span class="tag wait">อีก ${n} วัน</span>`;
    const get = late ? `ส่งช้ายังได้ +${Math.floor(a.exp / 2)} EXP` : `ส่งแล้วได้ +${a.exp} EXP · +${a.coins} 🪙`;
    return `<div class="item"><div class="grow"><b>${esc(a.title)}</b><div class="muted">กำหนดส่ง ${fmtDate(a.due_date)} · ${get}</div></div>${tag}${submitBtn(a) || `<button class="btn small ghost" onclick="go('att')">ดูงาน</button>`}</div>`;
  }).join("")}</div>`;
}
const BOSS_FX = {
  acid_dragon: { c: "#9be21b", n: 14, k: "drip", glow: "#a3e635" },
  beaker_golem: { c: "#c084fc", n: 16, k: "rise", glow: "#a855f7" },
  electron_wizard: { c: "#7dd3fc", n: 14, k: "orbit", glow: "#38bdf8" },
  element_robot: { c: "#fbbf24", n: 12, k: "spark", glow: "#f59e0b" },
  flame_demon: { c: "#fb923c", n: 18, k: "rise", glow: "#ef4444" },
  germ_hydra: { c: "#d946ef", n: 14, k: "float", glow: "#a3e635" },
};
function bossFxKey(b) { const m = /bosses\/([a-z_]+)\./.exec((b && b.image) || ""); return m ? m[1] : ""; }
function bossFxHtml(b, n) {
  const f = BOSS_FX[bossFxKey(b)]; if (!f) return "";
  let h = "";
  const cnt = n || f.n;
  for (let i = 0; i < cnt; i++) {
    const x = Math.round(8 + Math.random() * 84), sz = 3 + Math.round(Math.random() * 6), d = (Math.random() * 3.2).toFixed(2), t = (2.2 + Math.random() * 2.4).toFixed(2), a = Math.round(Math.random() * 360);
    h += `<i style="--x:${x}%;--s:${sz}px;--d:${d}s;--t:${t}s;--a:${a}deg"></i>`;
  }
  return `<span class="bfx bfx-${f.k}" style="--c:${f.c}">${h}</span>`;
}
function bossGlow(b) { const f = BOSS_FX[bossFxKey(b)]; return f ? f.glow : "#ff6b81"; }
function bossHit(ev) {
  const w = document.querySelector("#bossov .bossbig"); if (!w) return;
  w.classList.remove("hit"); void w.offsetWidth; w.classList.add("hit");
  const r = w.getBoundingClientRect(); const d = document.createElement("b"); d.className = "bdmg";
  d.textContent = "-" + (10 + Math.floor(Math.random() * 40));
  d.style.left = ((ev.clientX || r.left + r.width / 2) - r.left) + "px"; d.style.top = ((ev.clientY || r.top + r.height / 2) - r.top) + "px";
  w.appendChild(d); setTimeout(() => d.remove(), 900);
  try { SFX.play("blip"); } catch (e) {}
}
function promoHtml() {
  const p = PROMO; if (!p || !p.active) return "";
  const g = p.gift || {};
  const gift = [g.coins ? `+${g.coins} 🪙` : "", g.exp ? `+${g.exp} EXP` : "", g.pulls ? `🎟️ ตั๋วกาชา ×${g.pulls}` : ""].filter(Boolean).join(" · ");
  return `<div class="card promo"><div class="row"><div class="grow"><h3 style="margin:0">🎉 โปรเปิดระบบใหม่!</h3>
    <div class="muted">${p.pct > 0 ? `⚡ โบนัส EXP +${p.pct}% จากเช็คชื่อ/ส่งงาน/เควส · ` : ""}เหลืออีก ${p.days_left} วัน (ถึง ${fmtDate(p.until)})</div></div></div>
    <div style="margin-top:8px">${p.claimed ? '<span class="tag ok">🎁 รับของขวัญต้อนรับแล้ว</span>' : `<div class="muted" style="margin-bottom:6px">🎁 ของขวัญต้อนรับ: <b style="color:var(--gold2)">${gift}</b></div>${PEEK ? "" : '<button class="btn gold" onclick="claimPromo()">🎁 รับของขวัญเลย</button>'}`}</div></div>`;
}
let promoBusy = false;
async function claimPromo() {
  if (promoBusy) return; promoBusy = true;
  try { await rpc("promo_claim", { p_token: tk() }); await load(); toast("รับของขวัญต้อนรับแล้ว 🎁"); try { FX.victory(); } catch (e) {} }
  catch (e) { toast(e.message); try { await load(); } catch (x) {} }   // รับไปแล้ว → รีเฟรชให้ปุ่มหายทันที
  promoBusy = false;
}
function lessonsOn(d) {
  const k = ymd(d), w = d.getDay() || 7;
  return (TT || []).filter((t) => t.dow === w && (!t.from || k >= String(t.from).slice(0, 10)) && (!t.to || k <= String(t.to).slice(0, 10)))
    .map((t) => ({ kind: "lesson", lesson: true, title: `${t.start}–${t.end} ${t.title}`, note: [t.period, t.room ? "ห้อง " + t.room : ""].filter(Boolean).join(" · ") }));
}
function todayLessonsHtml() {
  const L = lessonsOn(new Date()); if (!L.length) return "";
  return `<div class="card"><h3>📚 คาบเรียนวันนี้</h3>${L.map((x) => `<div class="item"><span class="dot k-lesson"></span><div class="grow"><b>${esc(x.title)}</b><div class="muted">${esc(x.note)}</div></div></div>`).join("")}</div>`;
}
function bossHtml(full) {
  const b = X.boss; if (!b) return "";
  const pct = Math.max(0, Math.min(100, (b.hp / b.max_hp) * 100));
  const state = b.defeated ? '<span class="tag ok">ปราบแล้ว 🎉</span>' : b.ended ? '<span class="tag no">บอสหนีไปแล้ว</span>' : `<span class="tag late">เหลือ ${b.days_left} วัน</span>`;
  const claim = b.can_claim ? `<button class="btn gold" onclick="claimBoss()">🎁 รับรางวัลปราบบอส (+${b.reward_exp} EXP · +${b.reward_coins} 🪙)</button>`
    : b.claimed ? '<span class="tag ok">รับรางวัลแล้ว ✔</span>' : "";
  return `<div class="card boss ${b.defeated ? "dead" : ""}" role="button" tabindex="0" onclick="bossOpen()" onkeydown="if(event.key==='Enter')bossOpen()"><div class="brow"><div class="bemoji" style="--g:${bossGlow(b)}">${bossFxHtml(b, 6)}${b.image ? `<img src="${esc(b.image)}" alt="" onerror="this.replaceWith(document.createTextNode('${esc(b.emoji)}'))">` : esc(b.emoji)}</div><div class="grow">
    <h3 style="margin:0">บอสประจำสัปดาห์: ${esc(b.name)} ${state}</h3>
    <div class="hpbar"><i style="width:${pct}%"></i><span>HP ${b.hp} / ${b.max_hp}</span></div>
    <div class="muted">${esc(b.description || "")}</div>
    <div class="muted">ฉันโจมตีไปแล้ว <b style="color:var(--gold2)">${b.my_damage}</b> · ปราบได้รับ +${b.reward_exp} EXP +${b.reward_coins} 🪙 ทั้งห้อง</div><div class="muted" style="color:var(--gold2)">👆 แตะเพื่อดูภาพบอส สถิติเพื่อน และความสามารถ</div></div></div>
    ${full && b.top.length ? `<div class="row" style="margin-top:8px">${b.top.map((t, i) => `<span class="pill ${t.me ? "me" : ""}">${["🥇", "🥈", "🥉"][i] || "⚔️"} ${esc(t.name)} ${t.dmg}</span>`).join("")}</div>` : ""}
    ${claim ? `<div style="margin-top:10px" onclick="event.stopPropagation()">${claim}</div>` : ""}</div>`;
}
function bossOpen() {
  const b = X && X.boss; if (!b || document.getElementById("bossov")) return;
  const pct = Math.max(0, Math.min(100, (b.hp / b.max_hp) * 100));
  const at = b.attackers || b.top || [];
  const tot = at.reduce((a, t) => a + t.dmg, 0) || 1;
  const mx = at.length ? at[0].dmg : 1;
  const ab = b.abilities || [];
  const ov = document.createElement("div"); ov.id = "bossov"; ov.className = "modalov"; ov.setAttribute("role", "dialog"); ov.setAttribute("aria-modal", "true");
  ov.innerHTML = `<div class="patchbox bossbox"><button class="patchx" aria-label="ปิด" onclick="bossClose()">✕</button>
    <div class="bossbig" style="--g:${bossGlow(b)}" onclick="bossHit(event)">${bossFxHtml(b)}<span class="baura"></span>${b.image ? `<img src="${esc(b.image)}" alt="${esc(b.name)}" onerror="this.replaceWith(document.createTextNode('${esc(b.emoji)}'))">` : esc(b.emoji)}</div>
    <div class="patchh">${esc(b.name)} ${b.defeated ? '<span class="tag ok">ปราบแล้ว 🎉</span>' : b.ended ? '<span class="tag no">หนีไปแล้ว</span>' : `<span class="tag late">เหลือ ${b.days_left} วัน</span>`}</div>
    <div class="hpbar"><i style="width:${pct}%"></i><span>HP ${b.hp} / ${b.max_hp}</span></div>
    <div class="muted" style="text-align:center;margin:6px 0">${esc(b.description || "")}</div>
    <div class="muted" style="text-align:center">รางวัลปราบบอส +${b.reward_exp} EXP · +${b.reward_coins} 🪙 · ฉันโจมตี <b style="color:var(--gold2)">${b.my_damage}</b></div>
    ${ab.length ? `<h4 class="bsec">✨ ความสามารถของบอส</h4><div class="babil">${ab.map((a) => `<div class="patchi"><span>${esc(a.icon || "💥")}</span><div><b>${esc(a.name)}</b><div class="muted">${esc(a.desc || "")}</div></div></div>`).join("")}</div>` : ""}
    <h4 class="bsec">⚔️ สถิติผู้โจมตีบอส (${at.length} คน)</h4>
    ${at.length ? `<div class="batk">${at.map((t, i) => `<div class="batkr ${t.me ? "me" : ""}"><b class="batkn">${["🥇", "🥈", "🥉"][i] || i + 1}</b><div class="grow"><div class="batkt"><span>${esc(t.name)}${t.me ? " (ฉัน)" : ""}</span><b>${t.dmg} <span class="muted">· ${Math.round((t.dmg / tot) * 100)}%</span></b></div><div class="batkb"><i style="width:${Math.max(4, (t.dmg / mx) * 100)}%"></i></div>${t.hits ? `<div class="muted" style="font-size:.75em">โจมตี ${t.hits} ครั้ง</div>` : ""}</div></div>`).join("")}</div>` : '<p class="muted" style="text-align:center">ยังไม่มีใครโจมตีบอส — ทำเควสเพื่อเป็นคนแรก!</p>'}
    <div class="row" style="justify-content:center;margin-top:10px"><button class="btn gold" onclick="bossClose()">ปิด</button></div></div>`;
  ov.addEventListener("click", (e) => { if (e.target === ov) bossClose(); });
  document.body.appendChild(ov);
  try { SFX.play("pop"); } catch (e) {}
}
function bossClose() { document.getElementById("bossov")?.remove(); }
document.addEventListener("keydown", (e) => { if (e.key === "Escape") bossClose(); });
function teamsHtml() {
  const T = X.teams; if (!T) return "";
  const rows = (T.teams || []);
  const my = rows.find((t) => t.mine);
  const rank = my ? rows.indexOf(my) + 1 : 0;
  const teamCard = rows.length ? `<div class="card"><h3>🧪 ทีมแข่ง EXP สัปดาห์นี้ <span class="muted" style="font-size:.7em">(เริ่ม ${fmtDate(T.week_start)} · จัดอันดับด้วย EXP เฉลี่ยต่อคน)</span></h3>
    ${rows.map((t, i) => `<div class="item ${t.mine ? "mine" : ""}"><b style="width:28px">${["🥇", "🥈", "🥉"][i] || i + 1}</b><span style="font-size:24px">${esc(t.emoji)}</span>
      <div class="grow"><b>${esc(t.name)}</b> ${t.mine ? '<span class="pill me">ทีมฉัน</span>' : ""}<div class="muted">${t.members} คน · รวม ${t.exp_week} EXP</div></div><b>${t.avg_week}</b><span class="muted">/คน</span></div>`).join("")}
    ${my && my.roster ? `<h4 style="margin:12px 0 4px">เพื่อนในทีม</h4><div class="row">${my.roster.map((m) => `<span class="pill ${m.me ? "me" : ""}">${esc(m.name)} +${m.exp_week}</span>`).join("")}</div>` : ""}</div>`
    : `<div class="card"><h3>🧪 ทีมแข่ง EXP</h3><p class="muted">ครูยังไม่ได้แบ่งทีมในห้องนี้</p></div>`;
  const roomCard = (T.rooms || []).length > 1 ? `<div class="card"><h3>🏫 ห้องแข่งห้อง <span class="muted" style="font-size:.7em">(EXP เฉลี่ยต่อคน สัปดาห์นี้)</span></h3>
    ${T.rooms.map((r, i) => `<div class="item ${r.mine ? "mine" : ""}"><b style="width:28px">${["🥇", "🥈", "🥉"][i] || i + 1}</b><div class="grow"><b>${esc(r.name)}</b> ${r.mine ? '<span class="pill me">ห้องฉัน</span>' : ""}<div class="muted">${r.students} คน</div></div><b>${r.avg_week}</b></div>`).join("")}</div>` : "";
  return teamCard + roomCard;
}
function teamChip() {
  const T = X.teams; const my = T && (T.teams || []).find((t) => t.mine); if (!my) return "";
  const i = T.teams.indexOf(my) + 1;
  return `<div class="notice" onclick="go('rank')">${esc(my.emoji)} ${esc(my.name)} · อันดับ ${i}/${T.teams.length} · เฉลี่ย ${my.avg_week} EXP/คน — กดดูอันดับทีม</div>`;
}

const AUTO_HINT = { attendance: "ครูเช็คชื่อว่ามาเรียน", login: "เข้าสู่ระบบวันนี้", quiz: "ทำควิซประจำวัน (แท็บเกม)", quiz_perfect: "ตอบควิซถูกทุกข้อ",
  match: "เล่นเกมจับคู่ธาตุ", submit: "ส่งงาน 1 ชิ้น", gacha: "สุ่มกาชา 1 ครั้ง", decorate: "เปลี่ยนชุด/ไอเทมตัวละคร" };
const STN = [["int", "🧠", "ปัญญา", "โบนัส EXP ควิซ"], ["dil", "💪", "ขยัน", "EXP เช็คชื่อ/งาน/เควส"], ["str", "⚔️", "พลังโจมตี", "ดาเมจบอส"], ["luk", "🍀", "โชค", "โอกาสได้ SR/SSR"]];
/* กราฟเรดาร์ค่าสเตตัส (5 แกน) — draft = ชุดที่กำลังเลือกอยู่ (ยังไม่บันทึก) */
const SLOTS = [["outfit", "👕", "ชุด"], ["fx", "✨", "เอฟเฟค"], ["item", "🧪", "ไอเทมถือ"], ["hat", "🎩", "หมวก"], ["pet", "🐾", "สัตว์เลี้ยง"], ["frame", "🖼️", "กรอบ"], ["bg", "🌄", "พื้นหลัง"], ["title", "🏷️", "ฉายา"]];
/* ช่องอุปกรณ์ข้างตัวละคร: แตะแล้วเลือกสลับไอเทมที่มีอยู่ได้ทันที */
const slotIco = (k, it, cls) => !it ? "" : it.image ? `<img src="${esc(it.image)}" alt="">`
  : k === "outfit" ? `<img src="assets/chars/${esc(cls || "novice")}_${esc(it.key)}.png" alt="" onerror="this.replaceWith(document.createTextNode('${esc(it.emoji || "👕")}'))">` : esc(it.emoji || "🎁");
function eqPanel(me) {   // ช่องอุปกรณ์ทั้งหมดอยู่ฝั่งขวาของตัวละคร (2 คอลัมน์ × 4 แถว) · ช่องว่างใช้ไอคอนเทา
  return `<div class="eqcol">${SLOTS.map(([k, ic, lb]) => { const it = (me.decor || {})[k];
    return `<button class="eqslot ${it ? "on rar-" + esc(it.rarity || "N") : ""}" onclick="eqOpen('${k}')" aria-label="${lb}${it ? ": " + esc(it.name) : ""}" title="${lb}${it ? ": " + esc(it.name) : ""}">${it ? `<i class="eqlv">Lv${it.lvl || 1}</i>` : ""}<span class="eqi">${it ? slotIco(k, it, me.char_class) : `<img class="eqgrey" src="assets/slots/${k}.png" alt="">`}</span><small>${lb}</small></button>`; }).join("")}</div>`;
}
function eqClose() { document.getElementById("eqov")?.remove(); }
function eqOpen(k) {
  if (!D) return; eqClose();
  const me = D.student, cur = (me.decor || {})[k], lb = (SLOTS.find((s) => s[0] === k) || [])[2] || "";
  const own = (D.decor_catalog || []).filter((d) => d.slot === k && d.owned);
  const tile = (d) => `<button class="eqt ${cur && d && cur.id === d.id ? "worn" : !cur && !d ? "worn" : ""} ${d ? "rar-" + esc(d.rarity || "N") : ""}" onclick="eqPick('${k}',${d ? `'${d.id}'` : "null"})">
    <span class="eqi">${d ? (k === "title" ? esc(d.emoji || "🏷️") : slotIco(k, d, me.char_class) || esc(d.emoji || "🎁")) : `<img class="eqgrey" src="assets/slots/${k}.png" alt="">`}</span><small>${d ? esc(d.name) : k === "outfit" ? "ชุดเริ่มต้น" : "ถอดออก"}</small></button>`;
  const ov = document.createElement("div"); ov.id = "eqov"; ov.setAttribute("role", "dialog");
  ov.innerHTML = `<div class="eqbox"><button class="patchx" aria-label="ปิด" onclick="eqClose()">✕</button><h3>เลือก${lb}</h3>
    ${cur ? `<div id="eqdet" class="eqdet"><small class="muted">กำลังโหลดรายละเอียด…</small></div>` : ""}
    <h4 style="margin:6px 0">${cur ? "สลับเป็นชิ้นอื่น" : "ยังไม่ได้สวมใส่"}</h4>
    <div class="eqgrid">${tile(null)}${own.map(tile).join("")}</div>
    ${own.length ? "" : `<p class="muted center">ยังไม่มีไอเทมช่องนี้ — ไปหาได้จากกาชา/ร้านค้า/ล่ามอนสเตอร์</p>`}
    <div class="row" style="justify-content:center"><button class="btn small ghost" onclick="eqClose();go('decor')">🎨 ไปหน้าแต่งตัวละคร</button></div></div>`;
  ov.addEventListener("click", (e) => { if (e.target === ov) eqClose(); });
  document.body.appendChild(ov);
  if (cur) eqDetail(cur.id);
}
async function eqDetail(id) {
  const box = document.getElementById("eqdet"); if (!box) return;
  try {
    const r = await rpc("my_items", { p_token: tk() }); ITM = r; ITM_STALE = false;
    const g = (r.gear || []).find((x) => x.id === id), sc = (r.items || []).find((i) => i.kind === "scroll"), sq = sc ? sc.qty : 0;
    if (!g || !document.getElementById("eqdet")) return;
    const c = g.cost, maxed = g.lvl >= c.max, up = Math.max(0, g.lvl - 1);
    const st = ["int", "dil", "str", "luk"].filter((k) => g.stats[k] > 0).map((k) => `${ST_LBL[k]} +${g.stats[k] + (g.main === k ? up : 0)}`).join(" · ") || "ไม่มีสเตตัส";
    const ok = !maxed && g.main && sq >= c.scrolls && D.student.coins >= c.coins;
    box.innerHTML = `<div class="row" style="gap:10px;align-items:center"><span style="font-size:34px">${esc(g.emoji)}</span><div class="grow"><b>${esc(g.name)}</b> <span class="tag">${esc(g.rarity)}</span> <span class="tag ok">Lv ${g.lvl}/${c.max}</span>
      <div class="muted" style="font-size:.85em">${st}${g.coin ? ` · 🪙 +${g.coin}%` : ""}</div>${g.ability ? `<div class="muted" style="font-size:.8em">${esc(g.ability)}</div>` : ""}</div></div>
      <div class="row" style="margin-top:8px;gap:8px;align-items:center;flex-wrap:wrap">${!g.main ? '<span class="muted">ไอเทมนี้ไม่มีสเตตัสให้อัปเกรด</span>' : maxed ? '<span class="tag ok">เลเวลสูงสุดแล้ว</span>'
        : `<button class="btn small ${ok ? "gold" : "ghost"}" onclick="eqUp('${g.id}','${esc(g.name)}',${c.coins},${c.scrolls},'${esc(id)}')">⬆ อัปเลเวล ${c.coins}🪙 + 📜${c.scrolls}</button><small class="muted">มีม้วน ${sq} · อัปแล้ว +1 ${ST_LBL[g.main]}</small>`}</div>`;
  } catch (e) { box.innerHTML = `<small class="muted">${esc(e.message)}</small>`; }
}
const eqUp = async (id, n, c, s, wid) => {
  if (!confirm(`อัปเกรด “${n}” ใช้ ${c} เหรียญ + ม้วน ${s} ม้วน?`)) return;
  try { await rpc("upgrade_decor", { p_token: tk(), p_item: id }); ITM_STALE = true; await load(); toast("อัปเกรดสำเร็จ ✨"); const k = Object.entries(D.student.decor || {}).find(([, v]) => v && v.id === id); if (k) eqOpen(k[0]); else eqClose(); }
  catch (e) { toast(e.message); }
};
const eqPick = (k, id) => { eqClose(); const cur = ((D.student.decor || {})[k] || {}).id || null; if (cur === id) return; equipDecor(k, id); };
document.addEventListener("keydown", (e) => { if (e.key === "Escape") eqClose(); });
function statTotals(dc) {
  const S = X.stats || {}, IS = X.item_stats || {}, o = {};
  const mainOf = (m) => { const v = ["int", "dil", "str", "luk"].map((x) => +m[x] || 0), mx = Math.max(...v); return mx <= 0 ? null : ["int", "dil", "str", "luk"][v.indexOf(mx)]; };
  const addRaw = (k) => Object.entries(dc || {}).reduce((a, [sl, it]) => a + (it && it.id && IS[it.id] ? (+IS[it.id][k] || 0) + (mainOf(IS[it.id]) === k ? Math.max(0, (it.lvl || 1) - 1) : 0) : 0), 0);
  const add = (k) => (k === "coin" ? Math.min(15, addRaw(k)) : Math.min(12, addRaw(k)));
  ["int", "dil", "str", "luk"].forEach((k) => { const b = ((S[k] || {}).base || 0) + ((S[k] || {}).pts || 0); o[k] = { base: b, item: add(k), total: b + add(k) }; });
  o.coin = add("coin");
  return o;
}
function radarHtml(dc, size = 250) {
  if (!X.stats) return "";
  const T = statTotals(dc), AX = [["int", "🧠", "ปัญญา", T.int.total], ["dil", "💪", "ขยัน", T.dil.total], ["str", "⚔️", "พลัง", T.str.total], ["luk", "🍀", "โชค", T.luk.total], ["coin", "🪙", "เหรียญ%", T.coin]];
  const MAXV = 20, cx = size / 2, cy = size / 2 + 4, R = size * 0.32, n = AX.length;
  const pt = (i, r) => { const a = -Math.PI / 2 + (i * 2 * Math.PI) / n; return [cx + r * Math.cos(a), cy + r * Math.sin(a)]; };
  const ring = (f) => AX.map((_, i) => pt(i, R * f).map((v) => v.toFixed(1)).join(",")).join(" ");
  const poly = AX.map(([, , , v], i) => pt(i, R * Math.min(1, v / MAXV)).map((x) => x.toFixed(1)).join(",")).join(" ");
  const grid = [0.25, 0.5, 0.75, 1].map((f) => `<polygon points="${ring(f)}" fill="none" stroke="#6a52c4" stroke-opacity="${f === 1 ? 0.9 : 0.45}" stroke-width="1"/>`).join("");
  const axes = AX.map((_, i) => { const [x, y] = pt(i, R); return `<line x1="${cx}" y1="${cy}" x2="${x.toFixed(1)}" y2="${y.toFixed(1)}" stroke="#6a52c4" stroke-opacity=".45"/>`; }).join("");
  const dots = AX.map(([, , , v], i) => { const [x, y] = pt(i, R * Math.min(1, v / MAXV)); return `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="3.5" fill="#ffd86b" stroke="#1b1238"/>`; }).join("");
  const labels = AX.map(([k, ic, nm, v], i) => { const [x, y] = pt(i, R + 26); return `<image href="assets/icons/${({ int: "quiz", dil: "muscle", str: "battle", luk: "clover", coin: "coin" })[k]}.png" x="${(x - 9).toFixed(1)}" y="${(y - 27).toFixed(1)}" width="18" height="18"/><text x="${x.toFixed(1)}" y="${y.toFixed(1)}" text-anchor="middle" font-size="11" fill="#e9e2ff"><tspan x="${x.toFixed(1)}">${nm}</tspan><tspan x="${x.toFixed(1)}" dy="13" font-weight="700" fill="#ffd86b">${v}${k !== "coin" && T[k].item ? `<tspan fill="#7ee0b0" font-size="10"> (+${T[k].item})</tspan>` : ""}</tspan></text>`; }).join("");
  const E = { quiz: Math.floor(T.int.total / 2), exp: T.dil.total, boss: 3 * T.str.total, rare: 3 * T.luk.total };
  return `<div class="radar"><svg viewBox="0 0 ${size} ${size + 14}" width="100%" style="max-width:${size + 40}px" role="img" aria-label="กราฟสเตตัส">${grid}${axes}
      <polygon points="${poly}" fill="#9b6bff" fill-opacity=".38" stroke="#c9a8ff" stroke-width="2" stroke-linejoin="round"/>${dots}${labels}</svg>
    <div class="radfx"><span>🧠 +${E.quiz} EXP/ควิซ</span><span>💪 +${E.exp}% EXP</span><span>⚔️ +${E.boss}% ดาเมจบอส</span><span>🍀 +${E.rare}% SR/SSR</span>${T.coin ? `<span>🪙 +${T.coin}% เหรียญ</span>` : ""}</div></div>`;
}
const pointsLeft = () => ((X.stats || {}).points || {}).left || 0;
async function statAdd(k) { try { X.stats = await rpc("stat_add", { p_token: tk(), p_stat: k, p_n: 1 }); try { SFX.play("pop"); } catch (e) {} render(); } catch (e) { toast(e.message); } }
async function statReset() {
  const P = (X.stats || {}).points || {}; if (!confirm(`รีเซ็ตแต้มสเตตัสทั้งหมด? ต้องเสีย ${P.reset_cost} เหรียญ (ได้แต้มคืนทั้งหมดไปแจกใหม่)`)) return;
  try { X.stats = await rpc("stat_reset", { p_token: tk() }); toast("รีเซ็ตแล้ว แจกแต้มใหม่ได้เลย"); await load(); } catch (e) { toast(e.message); }
}
function statsHtml() {
  const S = X.stats; if (!S) return "";
  const E = S.effects || {}, P = S.points || {};
  const eff = { int: `+${E.quiz_exp || 0} EXP/ควิซ`, dil: `+${E.exp_pct || 0}% EXP`, str: `+${E.boss_pct || 0}% ดาเมจ`, luk: `+${E.rare_pct || 0}% SR/SSR` };
  const can = !PEEK && P.left > 0;
  return `<div class="card" id="statcard"><h3>📊 สเตตัสของฉัน</h3>
    <div class="ptbar ${P.left > 0 ? "on" : ""}"><div><b>แต้มสเตตัสคงเหลือ <span class="ptn">${P.left || 0}</span></b><small>เลเวลอัพรับ +${P.per_level || 2} แต้ม · ใส่ได้ด้านละสูงสุด ${P.cap || 15} · ใช้แล้ว ${P.spent || 0}/${P.total || 0}</small></div>
      ${!PEEK && (P.spent || 0) > 0 ? `<button class="btn ghost small" onclick="statReset()">↺ รีเซ็ต (${P.reset_cost} 🪙)</button>` : ""}</div>
    ${STN.map(([k, ic, nm, ds]) => { const v = S[k] || { base: 0, pts: 0, item: 0, total: 0 };
      return `<div class="item"><span style="font-size:22px">${ic}</span><div class="grow"><b>${nm}</b> <span class="muted">${ds}</span>
        <div class="hpbar" style="height:10px"><i style="width:${Math.min(100, v.total * 5)}%"></i></div></div>
        <div style="text-align:right"><b>${v.total}</b><div class="muted" style="font-size:11px">${v.base}${v.pts ? ` +${v.pts} แต้ม` : ""}${v.item ? ` +${v.item} ไอเทม` : ""}<br>${eff[k]}</div></div>
        ${PEEK ? "" : `<button class="stplus" ${can && v.pts < (P.cap || 15) ? "" : "disabled"} onclick="statAdd('${k}')" aria-label="เพิ่ม${nm}">＋</button>`}</div>`; }).join("")}
    ${E.coin_pct ? `<div class="item"><span style="font-size:22px">🪙</span><div class="grow"><b>โบนัสเหรียญ</b> <span class="muted">จากเช็คชื่อ/ส่งงาน/เควส</span></div><b>+${E.coin_pct}%</b></div>` : ""}
    ${(X.stats_abilities || []).map((a) => `<div class="abl">✨ ${esc(a)}</div>`).join("")}
    <p class="muted" style="font-size:12px">ค่าพื้นฐานมาจากการเรียน/เล่น (ด้านละสูงสุด 10) · แต้มสเตตัสจากเลเวลแจกได้เอง · สวมไอเทมตกแต่งเพื่อเพิ่มสเตตัสอีกเล็กน้อย</p></div>`;
}
const autoOf = (q) => (X.auto || {})[q.id];
