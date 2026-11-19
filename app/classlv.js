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
const clsBlocks = (lv, max) => `<div class="lvblk" title="เลเวลคลาส ${lv}/${max}">${Array.from({ length: max }, (_, i) => `<i class="${i < lv ? "on" : ""}"></i>`).join("")}</div>`;
const clsUnlocked = (c) => !c.adv && (c.options || []).some((o) => o.lv_ok && o.rank_ok);
// หน้าหลัก: แถบเลเวลคลาสใต้ตัวละคร
function classHomeHtml() {
  const c = CLS; if (typeof PEEK !== "undefined" && PEEK) return "";
  if (!c || !c.class) return `<div class="clshome" onclick="go('class')"><small class="muted">⚔️ ยังไม่ได้เลือกคลาส — แตะเพื่อเลือก</small></div>`;
  return `<div class="clshome" onclick="go('class')" title="แตะเพื่อดูรายละเอียดคลาส">
    <div class="row" style="align-items:center;gap:6px;justify-content:center"><b>${esc(c.class.emoji)} ${esc(c.class.name)}</b>${c.adv ? `<span class="tag ok">${esc(c.adv.emoji)} ${esc(c.adv.name)}</span>` : ""}<span class="tag">Lv.${c.lv}/${c.max_lv}</span></div>
    ${clsBlocks(c.lv, c.max_lv)}${clsBar(c)}
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
    ${clsBlocks(c.lv, c.max_lv)}${clsBar(c)}
    <p style="margin:6px 0 0">🎯 โบนัสสเตตัสตอนนี้: <b>${clsBonusTxt(c.bonus)}</b>${nxt ? `<br><small class="muted">เลเวลถัดไป: ${clsBonusTxt(nxt)}</small>` : ""}</p>
    <p class="muted" style="font-size:.88em;margin:6px 0 0">ได้แต้มชำนาญจาก EXP ที่ได้รับ (5 EXP = 1 แต้ม) · ชนะมอนสเตอร์ +10 · ชนะบอสด่านแรงค์ +25 · วันนี้ ${c.day_pts}/${c.day_cap} แต้ม · เปลี่ยนคลาสแล้วเลเวลของคลาสเดิมยังอยู่${ms ? `<br>คลาสอื่น: ${ms}` : ""}</p></div>
    <div class="card"><h3 style="margin:0 0 4px">🌟 คลาสขั้นสูง</h3><p class="muted" style="margin:0 0 8px">ต้องมีเลเวลคลาส 5 + ผ่านด่านเลื่อนแรงค์ Gold ได้สเตตัสหลัก +3 รอง +1 และสกิลไม้ตายในศึก (เลือกครั้งแรกฟรี · เปลี่ยนสาย ${c.switch_cost} 🪙)</p>
      <div class="clsgrid">${opts}</div></div>`;
}

// ---- ตารางสเตตัสละเอียด (ข้างเรดาร์) + ป๊อบอัพอธิบายรายค่า ----
const STX = [["int", "🧠", "ปัญญา"], ["dil", "💪", "ขยัน"], ["str", "⚔️", "พลัง"], ["luk", "🍀", "โชค"]];
function stRow(k) {
  const S = (X.stats || {})[k] || {}, T = statTotals(D.student.decor)[k] || {};
  const base = S.base || 0, pts = S.pts || 0, item = S.item != null ? S.item : T.item || 0, cls = S.cls || 0, buff = S.buff || 0;
  return { base, pts, item, cls, buff, total: S.total != null ? S.total : base + pts + item + cls + buff };
}
function statTableHtml() {
  if (!X.stats) return "";
  const P = X.stats.points || {}, c = CLS && CLS.class ? CLS : null;
  const head = c ? `<div class="stcls" onclick="go('class')" title="แตะเพื่อดูรายละเอียดคลาส"><b>${esc(c.class.emoji)} ${esc(c.class.name)}${c.adv ? " › " + esc(c.adv.emoji) + " " + esc(c.adv.name) : ""}</b> <span class="tag">Lv.${c.lv}/${c.max_lv}</span>${clsBlocks(c.lv, c.max_lv)}</div>` : "";
  const rows = STX.map(([k, ic, nm]) => { const r = stRow(k);
    return `<tr onclick="statPop('${k}')" tabindex="0" role="button" aria-label="อธิบาย${nm}"><td class="cb-n">${ic} ${nm}</td><td>${r.base}</td><td>${r.pts || "–"}</td><td>${r.item || "–"}</td><td class="cb-b">${r.cls ? "+" + r.cls : "–"}</td><td class="cb-b">${r.buff ? "+" + r.buff : "–"}</td><td class="cb-t">${r.total}</td></tr>`; }).join("");
  return `<div class="stbl">${head}<table class="cbt stt"><thead><tr><th></th><th>ฐาน</th><th>แต้ม</th><th>ของ</th><th>คลาส</th><th>บัพ</th><th>รวม</th></tr></thead><tbody>${rows}</tbody></table>
    <small class="muted">👆 แตะแถวเพื่อดูคำอธิบาย${P.left > 0 ? ` · <b style="color:var(--gold2,#ffd76a)">มีแต้มเหลือ ${P.left}</b>` : ""}</small></div>`;
}
function statPop(k) {
  const r = stRow(k), E = (X.stats || {}).effects || {}, P = (X.stats || {}).points || {}, nm = (STX.find((x) => x[0] === k) || [])[2], ic = (STX.find((x) => x[0] === k) || [])[1];
  const g = (typeof GEARS !== "undefined" && GEARS && GEARS.gear) || {}, c = CLS && CLS.class ? CLS : null;
  const src = [["📘 พื้นฐาน (การเรียน/เล่น · ด้านละสูงสุด 10)", r.base], ["➕ แต้มที่แจกเอง (สูงสุด " + (P.cap || 15) + ")", r.pts], ["🎒 อุปกรณ์/ไอเทมตกแต่ง (สูงสุด 12)", r.item],
    [`⚔️ โบนัสคลาส${c ? ` ${esc(c.class.name)} Lv.${c.lv}${c.adv ? " + " + esc(c.adv.name) : ""}` : ""}`, r.cls], ["🧪 บัพ (ไอเทมที่ใช้อยู่)", r.buff]].filter((x) => x[1] > 0 || x[0].startsWith("📘"));
  const luk = r.total, intl = r.total;
  const fx = {
    int: [`EXP ควิซ +${E.quiz_exp || 0} ต่อข้อ`, `ในศึก: ดาเมจโจมตี +${intl} ต่อครั้ง`, `ในศึก: ฮีลแรงขึ้น +${intl * 3}%`],
    dil: [`EXP จากกิจกรรม +${E.exp_pct || 0}%`, `ในศึก: HP สูงสุด +${r.total * 2}% (เสริมจากอุปกรณ์)`],
    str: [`ดาเมจบอส +${E.boss_pct || 0}% (ในศึกคูณ 2 = +${(E.boss_pct || 0) * 2}%)`],
    luk: [`โอกาส SR/SSR กาชา +${E.rare_pct || 0}%`, `ในศึก: โอกาสคริติคอล ${Math.min(40, luk * 2)}% (ดาเมจ ×2)`],
  }[k];
  const tip = { int: "เพิ่มได้จากแต้มสเตตัส · เลเวลคลาสสาย ปัญญา · อุปกรณ์ปัญญา", dil: "เพิ่มได้จากการมาเรียน · แต้มสเตตัส · เลเวลคลาสสายขยัน", str: "เพิ่มได้จากแต้มสเตตัส · เลเวลคลาสสายพลัง · อุปกรณ์พลัง", luk: "เพิ่มได้จากแต้มสเตตัส · เลเวลคลาสสายโชค · ไอเทมบัพโชค" }[k];
  frModal(`<h3>${ic} ${nm} <span class="tag ok">รวม ${r.total}</span></h3>
    <div class="stsrc">${src.map(([l, v]) => `<div class="row"><span class="grow">${l}</span><b>${v > 0 && !l.startsWith("📘") ? "+" : ""}${v}</b></div>`).join("")}<div class="row stsum"><span class="grow">รวม</span><b>${r.total}</b></div></div>
    <p style="margin:8px 0 2px"><b>ผลที่ได้</b></p><ul style="margin:0 0 8px 18px;padding:0">${fx.map((t) => `<li>${t}</li>`).join("")}</ul>
    <p class="muted" style="margin:0 0 8px;font-size:.88em">💡 ${tip}</p>
    ${!PEEK && P.left > 0 && r.pts < (P.cap || 15) ? `<div class="row" style="justify-content:center"><button class="btn gold" onclick="statAdd('${k}');eqClose()">＋ แจกแต้มให้ ${nm} (เหลือ ${P.left})</button></div>` : ""}`);
}
