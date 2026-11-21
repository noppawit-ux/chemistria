/* แผนที่เมือง Chemistria — หน้าแรกของแท็บ 🎮 เกม: แตะสถานที่ (เรืองแสง) → ป็อบอัพ → เข้าเล่นเกม
   ภาพพื้นหลังเดียว assets/city/map.jpg · แต่ละสถานที่ = สำเนาภาพที่ตัดตามรูปหลายเหลี่ยม (clip-path) + เรืองแสงเต้นช้าๆ */
const CITY = (() => {
  const W = 768, H = 432;
  const L = [
    { id: "tower", emoji: "🔮", name: "หอคอยเวทย์", sub: "ห้องฝึกเวทย์ผสมธาตุ", desc: "ร่ายคาถาด้วยการผสมอะตอมในหม้อต้มให้ตรงสูตรสาร มี 3 ระดับ ผสมถูกได้ EXP และเหรียญ",
      poly: [[112, 60], [122, 12], [150, 0], [215, 5], [212, 70], [192, 128], [140, 128], [112, 100]], acts: () => [["🔮 เข้าห้องเวทย์", "SPELL.open()", 1]] },
    { id: "arena", emoji: "⚔️", name: "ลานประลอง", sub: "ล่ามอนสเตอร์ · ท้าครูบุ๊ค", desc: "เลือกสกิลตามคลาสแล้วตอบคำถามเพื่อโจมตีมอนสเตอร์ หรือท้าครูบุ๊ค 8 รอบสุดโหด",
      poly: [[295, 30], [330, 5], [460, 5], [485, 40], [480, 100], [430, 125], [335, 125], [295, 100]], acts: () => [["⚔️ ล่ามอนสเตอร์", "BATTLE.open()", 1], ["🏆 ท้าครูบุ๊ค (ยากมาก)", "KB.open()", 0]] },
    { id: "hall", emoji: "🧠", name: "หอสมุดอะตอม", sub: "ควิซประจำวัน", desc: "ตอบคำถามเคมีประจำวัน ถูกข้อละ +EXP ถูกหมดมีโบนัส วันละ 1 ครั้ง ทำติดต่อกันได้เหรียญโบนัส",
      poly: [[535, 60], [580, 25], [690, 30], [700, 100], [640, 140], [560, 135], [535, 110]],
      acts: (s) => (s && s.quiz_done ? [[`✔ ทำแล้ววันนี้ ${s.quiz_score}/${s.quiz_total} ข้อ`, "", 2]] : [["🧠 เริ่มควิซ", "GAMES.startQuiz()", 1]]), dot: (s) => s && !s.quiz_done },
    { id: "dojo", emoji: "🤝", name: "โดโจท้าดวล", sub: "ท้าดวลเพื่อนเรียลไทม์", desc: "ท้าเพื่อนในห้องที่ออนไลน์ ตอบคำถามพร้อมกัน ใครถูก/ไวกว่าทำดาเมจใส่อีกฝ่าย",
      poly: [[45, 185], [75, 140], [180, 130], [200, 200], [190, 235], [70, 240], [45, 225]], acts: () => [["🤝 เข้าห้องท้าดวล", "DUEL.open()", 1]] },
    { id: "plaza", emoji: "⚗️", name: "หม้อต้มกลางเมือง", sub: "จับคู่ธาตุ", desc: "จับคู่สัญลักษณ์กับชื่อธาตุให้เร็วและผิดน้อย เลือกระดับความยาก ได้รางวัลตามคะแนน",
      poly: [[310, 200], [340, 160], [430, 160], [460, 200], [430, 235], [340, 235]], acts: () => [["ง่าย (6 คู่)", "GAMES.startMatch('easy')", 0], ["กลาง (8 คู่)", "GAMES.startMatch('mid')", 1], ["ยาก (10 คู่)", "GAMES.startMatch('hard')", 0]] },
    { id: "track", emoji: "🏃", name: "สนามเคมีรัน", sub: "วิ่งเก็บเหรียญ", desc: "วิ่งเก็บเหรียญ กระโดดหลบอุปสรรคแล็บ สไลด์ใต้เมฆพิษ เก็บยาเติมพลังและดาวบูสต์",
      poly: [[535, 195], [560, 150], [640, 128], [745, 150], [745, 235], [665, 265], [555, 255]], acts: () => [["🏃 ไปวิ่งกัน", "RUN.open()", 1]] },
    { id: "portal", emoji: "🌀", name: "ประตูมิติ", sub: "ดันเจี้ยนหลายชั้น · ปริศนา · โบนัส", desc: "ก้าวเข้าประตูมิติสู่ดันเจี้ยนหลายชั้น แต่ละชั้นไขปริศนาก่อนสู้มอนสเตอร์ พอชนะได้เลือกโบนัส 1 ใน 3 สะสมพลังไปจนถึงบอส เปิดหีบสมบัติ วันละ 2 รอบ",
      at: [252, 228], acts: () => [["🌀 เข้าประตูมิติ", "BATTLE.dgGate()", 1]] },
    { id: "farm", emoji: "🌱", name: "ฟาร์มผักเคมี", sub: "เร็วๆ นี้", desc: "ปลูกผัก ใส่ปุ๋ยด้วยความรู้เคมี เก็บเกี่ยวแล้วนำไปขายที่ตลาด — กำลังสร้าง",
      poly: [[25, 300], [85, 265], [160, 285], [190, 330], [160, 370], [60, 380], [25, 350]], locked: true },
    { id: "market", emoji: "🛍️", name: "ตลาดเมือง", sub: "เร็วๆ นี้", desc: "ขายผลผลิตจากฟาร์มและปลาที่ตกได้ ซื้อเมล็ดพันธุ์และเหยื่อ — กำลังสร้าง",
      poly: [[265, 330], [330, 290], [470, 290], [485, 340], [450, 385], [290, 385]], locked: true },
    { id: "lake", emoji: "🎣", name: "ท่าตกปลา", sub: "เร็วๆ นี้", desc: "เหวี่ยงเบ็ดรอจังหวะปลากิน สะสมปลาหายากเข้าสมุดสะสม — กำลังสร้าง",
      poly: [[520, 320], [600, 275], [768, 275], [768, 400], [540, 400]], locked: true },
  ];
  const clip = (p) => "polygon(" + p.map(([x, y]) => `${(x / W * 100).toFixed(2)}% ${(y / H * 100).toFixed(2)}%`).join(",") + ")";
  const centroid = (p) => [p.reduce((a, q) => a + q[0], 0) / p.length / W * 100, p.reduce((a, q) => a + q[1], 0) / p.length / H * 100];
  function html(s) {
    const locs = L.map((l, i) => l.at ? `<button class="cportal" style="left:${(l.at[0] / W * 100).toFixed(2)}%;top:${(l.at[1] / H * 100).toFixed(2)}%" aria-label="${esc(l.name)}" onclick="CITY.open('${l.id}')"><i class="cp3"></i><i class="cp2"></i><i class="cp1"></i><b>🌀</b></button>` : `<div class="cl ${l.locked ? "locked" : ""}" style="--d:${(i * 0.37).toFixed(2)}s"><img class="climg" src="assets/city/map.jpg" alt="${esc(l.name)}" draggable="false" role="button" tabindex="0" aria-label="${esc(l.name)}" style="clip-path:${clip(l.poly)}" onclick="CITY.open('${l.id}')"></div>`).join("");
    const pins = L.map((l) => { const [x, y] = l.at ? [l.at[0] / W * 100, l.at[1] / H * 100 + 7] : centroid(l.poly), dot = l.dot && l.dot(s);
      return `<div class="clpin ${l.locked ? "locked" : ""}" style="left:${x}%;top:${y}%"><span>${l.locked ? "🔒" : l.emoji} ${esc(l.name)}</span>${dot ? '<i class="cldot"></i>' : ""}</div>`; }).join("");
    return `<div class="citywrap" id="citywrap"><div class="citymap"><img class="citybg" src="assets/city/map.jpg" alt="แผนที่เมือง Chemistria" draggable="false" onload="CITY.center()">${locs}${pins}</div></div>
      <div class="row" style="justify-content:center;margin:6px 0"><span class="muted" style="font-size:.85em">แตะสถานที่ที่เรืองแสงเพื่อเข้าเล่น · เลื่อนแผนที่ไปซ้าย-ขวาได้</span>
      <button class="btn small ghost" onclick="GAMES.setList(true)">📋 ดูเป็นรายการ</button></div>`;
  }
  const center = () => { const w = document.getElementById("citywrap"); if (w) w.scrollLeft = (w.scrollWidth - w.clientWidth) / 2; };
  function open(id) {
    const l = L.find((x) => x.id === id); if (!l) return; eqClose();
    const s = GAMES.status && GAMES.status();
    const acts = l.locked ? '<button class="btn" disabled>🔒 เปิดเร็วๆ นี้</button>'
      : l.acts(s).map(([t, fn, k]) => (fn ? `<button class="btn ${k === 1 ? "gold" : "ghost"}" onclick="eqClose();${fn}">${esc(t)}</button>` : `<span class="tag ok">${esc(t)}</span>`)).join(" ");
    const ov = document.createElement("div"); ov.id = "eqov"; ov.className = "cityov"; ov.setAttribute("role", "dialog");
    ov.innerHTML = `<div class="eqbox center citypop"><button class="patchx" aria-label="ปิด" onclick="eqClose()">✕</button>
      <div class="cpemo">${l.locked ? "🔒" : l.emoji}</div><h3 style="margin:2px 0">${esc(l.name)}</h3><div class="muted" style="margin-bottom:6px">${esc(l.sub)}</div>
      <p style="margin:6px 0 12px">${esc(l.desc)}</p><div class="row" style="justify-content:center;gap:8px">${acts}</div></div>`;
    ov.addEventListener("click", (e) => { if (e.target === ov) eqClose(); });
    document.body.appendChild(ov);
  }
  return { html, open, center, L };
})();
