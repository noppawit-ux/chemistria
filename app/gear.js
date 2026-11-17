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
