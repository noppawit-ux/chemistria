/* เลเวลคลาส + โบนัสสเตตัส + คลาสขั้นสูง (v2.47) — ส่วนหนึ่งของหน้านักเรียน · ข้อมูลจาก RPC class_info (SQL 102) */
let CLS = null;
const CLS_ST = { int: "🧠 ปัญญา", dil: "💪 ขยัน", str: "⚔️ พลัง", luk: "🍀 โชค" };
const clsBonusTxt = (b) => ["int", "dil", "str", "luk"].filter((k) => b && b[k] > 0).map((k) => `${CLS_ST[k]} +${b[k]}`).join(" · ") || "–";
// ตัวอย่างโบนัสเมื่อถึงเลเวล lv (สูตรเดียวกับฐานข้อมูล)
function clsBonusAt(lv, main, sub, adv) {
  const o = { int: 0, dil: 0, str: 0, luk: 0 };
  if (adv) { o[adv.main] = Math.floor((lv + 1) / 2) + 3; o[adv.sub] += Math.floor(lv / 3) + 1; }
  else { if (main) o[main] = Math.floor((lv + 1) / 2); if (sub) o[sub] += Math.floor(lv / 3); }
  return o;
}
const clsBar = (c) => { const span = c.lv_next == null ? 1 : c.lv_next - c.lv_from, p = c.lv_next == null ? 100 : Math.min(100, Math.round(((c.pts - c.lv_from) / span) * 100)); return `<div class="bar"><i style="width:${p}%"></i></div><small class="muted">${c.lv_next == null ? `แต้มชำนาญ ${c.pts} · เลเวลสูงสุด` : `แต้มชำนาญ ${c.pts}/${c.lv_next} → เลเวล ${c.lv + 1}`}</small>`; };
const clsUnlocked = (c) => !c.adv && (c.options || []).some((o) => o.lv_ok && o.rank_ok);
// หน้าหลัก: แถบเลเวลคลาสใต้ตัวละคร
function classHomeHtml() {
  const c = CLS; if (typeof PEEK !== "undefined" && PEEK) return "";
  if (!c || !c.class) return `<div class="clshome" onclick="go('class')"><small class="muted">⚔️ ยังไม่ได้เลือกคลาส — แตะเพื่อเลือก</small></div>`;
  return `<div class="clshome" onclick="go('class')" title="แตะเพื่อดูรายละเอียดคลาส">
    <div class="row" style="align-items:center;gap:6px;justify-content:center"><b>${esc(c.class.emoji)} ${esc(c.class.name)}</b>${c.adv ? `<span class="tag ok">${esc(c.adv.emoji)} ${esc(c.adv.name)}</span>` : ""}<span class="tag">Lv.${c.lv}</span></div>
    ${clsBar(c)}
    <div class="clsb">โบนัสคลาส: ${clsBonusTxt(c.bonus)}</div>
    ${clsUnlocked(c) ? '<div class="clsup">🌟 ปลดล็อกคลาสขั้นสูงแล้ว — แตะเพื่อเลือก!</div>' : ""}</div>`;
}
// หน้าคลาส: เลเวล โบนัส คลาสขั้นสูง ความชำนาญของคลาสอื่น
function classLvHtml() {
  const c = CLS; if (!c) return "";
  if (!c.class) return `<div class="card"><p class="muted" style="margin:0">เลือกคลาสด้านล่าง แล้วสะสมแต้มความชำนาญเพื่อเลเวลคลาสและโบนัสสเตตัส ✨</p></div>`;
  const cl = c.class, nxt = c.lv < c.max_lv ? clsBonusAt(c.lv + 1, cl.main, cl.sub, c.adv) : null;
  const opts = (c.options || []).map((o) => {
    const cur = o.current, ok = o.lv_ok && o.rank_ok;
    const need = [!o.lv_ok ? `เลเวลคลาส ${o.need_lv} (ตอนนี้ ${c.lv})` : "", !o.rank_ok ? `ผ่านด่านแรงค์ ${esc(o.need_rank_name || o.need_rank)}` : ""].filter(Boolean).join(" · ");
    return `<div class="advcard ${cur ? "on" : ""} ${ok || cur ? "" : "lock"}"><div class="advh">${esc(o.emoji)} <b>${esc(o.name)}</b></div><div class="muted">${esc(o.descr || "")}</div>
      <div class="ability">✨ ${esc(o.ability || "")}</div>
      ${o.skill ? `<div class="advsk">${esc(o.skill.emoji)} ไม้ตาย: <b>${esc(o.skill.name)}</b> <small class="muted">${esc(o.skill.descr || "")}</small></div>` : ""}
      ${cur ? '<span class="tag ok">สายปัจจุบัน</span>' : ok ? `<button class="btn small gold" onclick="pickAdv('${o.key}','${esc(o.name)}',${c.adv ? c.switch_cost : 0})">${c.adv ? `เปลี่ยนสาย (${c.switch_cost} 🪙)` : "เลือกสายนี้ (ฟรี)"}</button>` : `<span class="tag wait">🔒 ต้อง ${need}</span>`}</div>`;
  }).join("");
  const ms = (c.mastery || []).filter((m) => m.key !== cl.key).map((m) => `<span class="tag">${esc(m.emoji)} ${esc(m.name)} Lv.${m.lv}</span>`).join(" ");
  return `<div class="card clscard2"><h3 style="margin:0">${esc(cl.emoji)} ${esc(cl.name)} <span class="tag">Lv.${c.lv}/${c.max_lv}</span>${c.adv ? ` <span class="tag ok">${esc(c.adv.emoji)} ${esc(c.adv.name)}</span>` : ""}</h3>
    ${clsBar(c)}
    <p style="margin:6px 0 0">🎯 โบนัสสเตตัสตอนนี้: <b>${clsBonusTxt(c.bonus)}</b>${nxt ? `<br><small class="muted">เลเวลถัดไป: ${clsBonusTxt(nxt)}</small>` : ""}</p>
    <p class="muted" style="font-size:.88em;margin:6px 0 0">ได้แต้มชำนาญจาก EXP ที่ได้รับ (5 EXP = 1 แต้ม) · ชนะมอนสเตอร์ +10 · ชนะบอสด่านแรงค์ +25 · วันนี้ ${c.day_pts}/${c.day_cap} แต้ม · เปลี่ยนคลาสแล้วเลเวลของคลาสเดิมยังอยู่${ms ? `<br>คลาสอื่น: ${ms}` : ""}</p></div>
    <div class="card"><h3 style="margin:0 0 4px">🌟 คลาสขั้นสูง</h3><p class="muted" style="margin:0 0 8px">ต้องมีเลเวลคลาส 5 + ผ่านด่านเลื่อนแรงค์ Gold ได้สเตตัสหลัก +3 รอง +1 และสกิลไม้ตายในศึก (เลือกครั้งแรกฟรี · เปลี่ยนสาย ${c.switch_cost} 🪙)</p>
      <div class="clsgrid">${opts}</div></div>`;
}
