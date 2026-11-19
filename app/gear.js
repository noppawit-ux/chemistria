/* อุปกรณ์/การ์ดสวมใส่ + ธาตุ (v2.22) — แผงโบนัส · ป้ายธาตุ · ใส่การ์ด 3 ช่อง */
let GEARS = null, GEAR_BUSY = false;
const gi = (k) => `<img class="gi" src="assets/gi/${k}.svg" alt="" aria-hidden="true">`;
const ELEM = { fire: [gi("fire"), "ไฟ"], water: [gi("water"), "น้ำ"], plant: [gi("plant"), "พืช"], thunder: [gi("thunder"), "ไฟฟ้า"], chem: [gi("chem"), "สารเคมี"] };
const ELEM_BEATS = { water: "fire", fire: "plant", plant: "chem", chem: "thunder", thunder: "water" };
const elBadge = (el) => (el && ELEM[el] ? `<span class="elb el-${el}" title="ธาตุ${ELEM[el][1]}">${ELEM[el][0]} ${ELEM[el][1]}</span>` : "");
const pxIco = (o) => (o && o.image ? `<img class="pxi" src="${esc(o.image)}" alt="" loading="lazy" onerror="this.replaceWith(document.createTextNode('${esc(o.emoji || "🎁")}'))">` : esc((o && o.emoji) || ""));
const FXK = { atk: gi("atk") + " โจมตี", def: gi("def") + " ลดดาเมจ", hp: gi("hp") + " HP" };
async function gearLoad(force) {
  if (GEAR_BUSY || (GEARS && !force)) return; GEAR_BUSY = true;
  try { GEARS = await rpc("gear_status", { p_token: tk() }); } catch (e) { GEARS = GEARS || { off: true }; }
  GEAR_BUSY = false;
  try { if (typeof tab !== "undefined" && ["home", "decor", "cards"].includes(tab)) render(); } catch (e) {}
}
const gearItemFx = (d) => { const t = GEARS && GEARS.items && GEARS.items[d.id]; if (!t) return ""; const p = []; if (t.atk) p.push(`${gi("atk")}+${t.atk}%`); if (t.def) p.push(`${gi("def")}-${t.def}%`); if (t.hp) p.push(`${gi("hp")}+${t.hp}%`); return `${elBadge(t.el)}${p.length ? `<span class="stb">${p.join(" ")}</span>` : ""}`; };
const cardFxText = (id) => { const t = GEARS && GEARS.cards && GEARS.cards[id]; return t ? `${elBadge(t.el)} <span class="stb">${t.kind ? (FXK[t.kind] || "") + " " + (t.kind === "def" ? "-" : "+") + t.pct + "%" : ""}</span>` : ""; };
// ตารางค่าการต่อสู้ของฉัน: พื้นฐาน + โบนัส = รวม (ตัวเลขตามกติกา SQL 99 ค่าเริ่มต้น)
function combatHtml() {
  if (typeof PEEK !== "undefined" && PEEK) return "";
  if (!X.stats || !GEARS || !GEARS.gear) { if (!GEARS) gearLoad(); return ""; }
  const T = statTotals(D.student.decor), g = GEARS.gear, ef = X.stats.effects || {}, lv = D.student.level || 1;
  const intl = T.int.total, dil = T.dil.total, luk = T.luk.total + ((X.stats.luk || {}).buff || 0);
  const hp0 = 80 + 6 * lv, hp1 = Math.round(Math.round(hp0 * (1 + g.hp / 100)) * (1 + dil * 0.02));
  const at0 = 20, at1 = Math.round(at0 * (1 + (ef.boss_pct || 0) * 2 / 100) * (1 + g.atk / 100) + intl);
  const gd0 = 20, gd1 = Math.round((1 - (1 - gd0 / 100) * (1 - g.def / 100)) * 100);
  const cr1 = Math.min(40, luk * 2), rare = ef.rare_pct || 0;
  const row = (ic, nm, b, bonus, tot, tip) => `<tr title="${esc(tip)}"><td class="cb-n">${ic} ${nm}</td><td>${b}</td><td class="cb-b">${bonus > 0 ? "+" + bonus : bonus < 0 ? bonus : "–"}</td><td class="cb-t">${tot}</td></tr>`;
  return `<div class="combatbox"><div class="muted center" style="margin-bottom:4px">📊 ค่าการต่อสู้ของฉัน</div>
    <table class="cbt"><thead><tr><th></th><th>พื้นฐาน</th><th>โบนัส</th><th>รวม</th></tr></thead><tbody>
    ${row("❤️", "HP", hp0, hp1 - hp0, hp1, `พื้นฐาน 80+6×เลเวล · โบนัสจากอุปกรณ์/การ์ด +${g.hp}% และขยัน ${dil} แต้ม (+2%/แต้ม) · ด่านเลื่อนแรงค์เริ่มที่ 85% ของค่านี้`)}
    ${row("⚔️", "โจมตี/ครั้ง", at0, at1 - at0, at1, `ดาเมจพื้นฐานสกิลโจมตี · พลัง +${(ef.boss_pct || 0) * 2}% · อุปกรณ์ +${g.atk}% · ปัญญา +${intl} · ตอบไว ≤4 วิ เพิ่มอีก 50%`)}
    ${row("🛡️", "ลดดาเมจ %", gd0, gd1 - gd0, gd1 + "%", `พื้นฐาน = ตั้งรับถูกครบสูงสุด ${gd0}% · อุปกรณ์/การ์ด −${g.def}% · ธาตุแพ้ทางจะโดนเพิ่ม`)}
    ${row("💥", "คริติคอล %", 0, cr1, cr1 + "%", `โชค ${luk} × 2% (สูงสุด 40%) · คริติคอล = ดาเมจ ×2`)}
    ${row("🍀", "ดวง (โชค)", T.luk.base, luk - T.luk.base, luk, `แต้มโชคที่แจก + อุปกรณ์ + บัพ · โอกาส SR/SSR กาชา +${rare}%`)}
    </tbody></table>
    <small class="muted">แตะ/ชี้แต่ละแถวเพื่อดูที่มาของตัวเลข · โอกาส SR/SSR +${rare}%${ef.exp_pct ? ` · EXP +${ef.exp_pct}%` : ""}</small></div>`;
}
function gearBox() {
  if (typeof PEEK !== "undefined" && PEEK) return "";
  if (!GEARS) { gearLoad(); return ""; }
  if (GEARS.off || !GEARS.gear) return "";
  const g = GEARS.gear, sl = GEARS.slots || [], cs = GEARS.cards || {}, nm = (id) => { const al = ALBUM && ALBUM.sets ? ALBUM.sets.flatMap((s) => s.cards).find((c) => c.id === id) : null; return al ? al.name : "การ์ด"; };
  const els = Object.entries(g.el || {}).map(([k, n]) => `<span class="elb el-${k}">${ELEM[k][0]}×${n}</span>`).join("") || '<span class="muted">ยังไม่มีธาตุ</span>';
  const slots = [1, 2, 3].map((n) => { const s = sl.find((x) => x.slot === n); const c = s && cs[s.card];
    return `<button class="gslot ${s ? "on" : ""}" onclick="go('cards')" title="แตะเพื่อจัดการการ์ด">${s ? `${c && c.el ? ELEM[c.el][0] : "🃏"}<small>${esc(nm(s.card))}</small>` : `<small>ช่อง ${n}</small>`}</button>`; }).join("");
  return `<div class="gearbox"><div class="muted center" style="margin-bottom:2px">⚔️ โบนัสจากอุปกรณ์ + การ์ด</div>
    <div class="radfx"><span>${gi("atk")} โจมตี +${g.atk}%</span><span>${gi("def")} ลดดาเมจ −${g.def}%</span><span>${gi("hp")} HP +${g.hp}%</span></div>
    <div class="row" style="gap:4px;justify-content:center;flex-wrap:wrap;margin:4px 0">${els}</div>
    <div class="gslots">${slots}</div>
    <p class="muted center" style="font-size:12px;margin:4px 0 0">ธาตุชนะมอนสเตอร์ = ดาเมจเพิ่ม · ธาตุแพ้ = โดนแรงขึ้น<br>${["water", "fire", "plant", "chem", "thunder", "water"].map((k) => ELEM[k][0]).join(" › ")}</p></div>`;
}
async function cardEquip(slot, id) {
  try { GEARS = await rpc("card_equip", { p_token: tk(), p_slot: slot, p_card: id }); try { SFX.play("pop"); } catch (e) {} toast(id ? "ใส่การ์ดแล้ว ✨" : "ถอดการ์ดแล้ว"); cardClose(); render(); } catch (e) { toast(e.message); }
}
const monElem = (id) => (GEARS && GEARS.monsters ? GEARS.monsters[id] : null);
function matchupNote(el) {
  if (!el || !GEARS || !GEARS.gear) return "";
  const k = Object.keys(GEARS.gear.el || {}); const adv = k.filter((x) => ELEM_BEATS[x] === el).reduce((a, x) => a + GEARS.gear.el[x], 0), weak = k.filter((x) => ELEM_BEATS[el] === x).reduce((a, x) => a + GEARS.gear.el[x], 0);
  return (adv ? `<span class="mu good">👍 ธาตุของคุณได้เปรียบ ×${adv}</span>` : "") + (weak ? `<span class="mu bad">⚠️ ธาตุของคุณแพ้ทาง ×${weak}</span>` : "");
}
const eqElem = (it) => { const t = GEARS && GEARS.items && it && GEARS.items[it.id]; return t && t.el && ELEM[t.el] ? `<span class="eqel el-${t.el}" title="ธาตุ${ELEM[t.el][1]}">${ELEM[t.el][0]}</span>` : ""; };
