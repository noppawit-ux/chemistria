/* แทนอิโมจิด้วยไอคอนภาพ — ส่วนหนึ่งของหน้านักเรียน (index.html) โหลดต่อกันตามลำดับใน index.html */
/* ---------------- แทนอิโมจิด้วยไอคอนภาพ (ทั้งหน้า อัตโนมัติ) ---------------- */
const EMO = { "🧠": "quiz", "⚗️": "match", "⚗": "match", "🔮": "spell", "🏆": "trophy", "⚔️": "battle", "⚔": "battle", "🤝": "duel", "💪": "muscle", "🍀": "clover", "🔥": "fire", "⏰": "alarm", "📷": "camera", "🎨": "palette", "🎁": "giftbox", "🎟️": "ticket", "🎟": "ticket", "👹": "boss", "🪙": "coin", "❤️": "heart", "✅": "check", "🔒": "lock", "🔔": "bell" };
const EMO_RE = new RegExp(Object.keys(EMO).sort((a, b) => b.length - a.length).join("|"), "g");
let EMO_Q = false;
function emoSwap(root) {
  const w = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, { acceptNode: (n) => !n.nodeValue || !/[\u2600-\u27BF\u{1F300}-\u{1FAFF}]/u.test(n.nodeValue) || n.parentNode.closest("svg,script,style,textarea,option,select,title") ? NodeFilter.FILTER_REJECT : NodeFilter.FILTER_ACCEPT });
  const list = []; while (w.nextNode()) list.push(w.currentNode);
  for (const n of list) {
    const t = n.nodeValue; EMO_RE.lastIndex = 0; if (!EMO_RE.test(t)) continue;
    const f = document.createDocumentFragment(); let last = 0; EMO_RE.lastIndex = 0; let m;
    while ((m = EMO_RE.exec(t))) { if (m.index > last) f.append(t.slice(last, m.index)); const i = document.createElement("img"); i.className = "em"; i.alt = ""; i.draggable = false; i.src = `assets/icons/${EMO[m[0]]}.png`; f.append(i); last = m.index + m[0].length; }
    if (last < t.length) f.append(t.slice(last)); n.replaceWith(f);
  }
}
new MutationObserver(() => { if (EMO_Q) return; EMO_Q = true; requestAnimationFrame(() => { EMO_Q = false; try { emoSwap(document.body); } catch (e) {} }); }).observe(document.body || document.documentElement, { childList: true, subtree: true, characterData: true });

/* ---------------- ไอคอนภาพแทนอิโมจิ ---------------- */
const ic = (k, c = "") => `<img class="ico ${c}" src="assets/icons/${k}.png" alt="" draggable="false" onerror="this.replaceWith(document.createTextNode(''))">`;
const tabHtml = ([k, l]) => `${ic(k)}<span>${esc(l.replace(/^\S+\s/, ""))}</span>`;
