/* เคมีรัน — ด่าน ฉากหลังพาราแลกซ์ และสิ่งกีดขวางเฉพาะด่าน (v2.40)
   ภาพพื้นหลัง: Free Horizontal Game Backgrounds (Craftpix, license ฟรี) · Glacial Mountains (vnitti, CC BY 4.0) ·
   Space Background Pack (Ansimuz, CC0) · Ocean and Clouds pixel art (Craftpix, license ฟรี) — ดู assets/CREDITS.md
   ส่วนสิ่งกีดขวางวาดด้วยโค้ด (แคนวาส) ทั้งหมด · เป็นการแสดงผลล้วนๆ ไม่กระทบการให้รางวัลของเซิร์ฟเวอร์ */
const RUNST = (() => {
  const GY = 350, H = 420;
  const LAY = {"mtn1":{"L":[["mtn1_sky",0],["mtn1_c4",0.02],["mtn1_c3",0.035],["mtn1_c2",0.05],["mtn1_c1",0.07],["mtn1_r2",0.12],["mtn1_r1",0.2]],"P":[]},"mtn2":{"L":[["mtn2_sky",0],["mtn2_c3",0.02],["mtn2_c2",0.035],["mtn2_c1",0.05],["mtn2_bd",0.08],["mtn2_r3",0.09],["mtn2_r2",0.14],["mtn2_r1",0.2],["mtn2_pn",0.3]],"P":[]},"night":{"L":[["night_sky",0],["night_c2",0.03],["night_c1",0.05],["night_rk",0.09],["night_g3",0.15],["night_g2",0.22],["night_g1",0.3],["night_pl",0.4]],"P":[]},"fall":{"L":[["fall_sky",0],["fall_c2",0.03],["fall_c1",0.05],["fall_rk",0.1],["fall_gr",0.22]],"P":[]},"glacier":{"L":[["glacier_sky",0],["glacier_cb",0.015],["glacier_gm",0.06],["glacier_cl",0.09],["glacier_m3",0.1],["glacier_m2",0.14],["glacier_m1",0.19]],"P":[]},"sea4":{"L":[["sea4_l1",0],["sea4_l2",0.02],["sea4_l3",0.04],["sea4_l4",0.07],["sea4_l5",0.12]],"P":[]},"sea2":{"L":[["sea2_l2",0],["sea2_l3",0.02],["sea2_l4",0.04],["sea2_l5",0.07]],"P":[]},"sea6":{"L":[["sea6_l1",0],["sea6_l2",0.02],["sea6_l3",0.04],["sea6_l4",0.07],["sea6_l5",0.12]],"P":[]},"spaceb":{"L":[["spaceb_bk",0],["spaceb_st",0.03]],"P":[["spaceb_pb",0.1,70,3.2,900],["spaceb_a1",0.2,200,2.2,700],["spaceb_a2",0.28,120,2.2,560],["spaceb_ps",0.07,260,3,1100]]},"spaceo":{"L":[["spaceo_bk",0],["spaceo_fp",0.02],["spaceo_st",0.04]],"P":[["spaceo_bp",0.08,90,2.6,1000],["spaceo_rp",0.14,170,2.2,1300]]}};
  const PXV = { glacier: 1, sea4: 1, sea2: 1, sea6: 1, spaceb: 1, spaceo: 1 };   // ภาพพิกเซลอาร์ต: ปิด smoothing
  const STAGES = [
    { id: "lab", n: "ห้องแล็บ", e: "🧪", th: "lab", vars: ["lab"], rv: 200, hz: { drop: 1, roll: 1, gas: 1, orb: 1 }, sk: {},
      floor: ["#4a2f8f", "#1a0f3a", "#b08cff"], tint: 0.35, info: "เตาไฟ · ชั้นหลอด · เมฆพิษ · หยดกรด · ขวดกลิ้ง · ก๊าซพิษ · ลูกไฟฟ้า" },
    { id: "mtn", n: "ภูเขายามเช้า", e: "⛰️", th: "mtn", vars: ["mtn1", "mtn2"], rv: 230, hz: { drop: 2, roll: 2, gas: 1, orb: 1 },
      sk: { low: "rock", tall: "trunk", cloud: "storm", drop: "rock", roll: "boulder", gas: "spikes", orb: "ember" },
      floor: ["#6b5a47", "#2c2218", "#a8d86a"], tint: 0.06, info: "ก้อนหิน · ท่อนไม้สูง · เมฆฝน · หินร่วงจากหน้าผา · ลูกหินกลิ้ง · หนามพื้น" },
    { id: "night", n: "ป่าเงียบยามค่ำ", e: "🌲", th: "night", vars: ["night"], rv: 260, hz: { drop: 1, roll: 2, gas: 2, orb: 2 },
      sk: { low: "thorn", tall: "deadtree", cloud: "bats", drop: "cone", roll: "log", gas: "slime", orb: "firefly" },
      floor: ["#243545", "#0b131b", "#58809f"], tint: 0.1, info: "พุ่มหนาม · ต้นไม้ตาย · ฝูงค้างคาว · ลูกสนร่วง · ท่อนซุงกลิ้ง · หนองพิษ · หิ่งห้อยพิษ" },
    { id: "fall", n: "น้ำตกเวทมนตร์", e: "💧", th: "fall", vars: ["fall"], rv: 210, hz: { drop: 2, roll: 1, gas: 1, orb: 1, geyser: 2 },
      sk: { low: "mossrock", tall: "crystal", cloud: "mist", drop: "water", roll: "mossball", gas: "tealslime", orb: "spirit" },
      floor: ["#2d6585", "#0d2a40", "#86e8ff"], tint: 0.06, info: "หินตะไคร่ · ผลึกม่วง · หมอกพิษ · หยดน้ำใหญ่ · น้ำพุร้อนพุ่งขึ้น (จังหวะ) · วิญญาณน้ำ" },
    { id: "ice", n: "ธารน้ำแข็ง", e: "❄️", th: "ice", vars: ["glacier"], rv: 340, hz: { drop: 2, roll: 3, gas: 1, orb: 1 },
      sk: { low: "icespike", tall: "icepillar", cloud: "snow", drop: "icicle", roll: "snowball", gas: "icerow", orb: "flake" },
      floor: ["#a9d3ef", "#4f82ab", "#f0fbff"], tint: 0.02, info: "หนามน้ำแข็ง · เสาน้ำแข็ง · พายุหิมะ · น้ำแข็งแหลมร่วง · ก้อนหิมะกลิ้งเร็ว · เกล็ดหิมะลอย" },
    { id: "sea", n: "ทะเลหลากสี", e: "🌊", th: "sea", vars: ["sea4", "sea2", "sea6"], rv: 200, hz: { drop: 1, roll: 1, gas: 1, orb: 2, geyser: 3 },
      sk: { low: "crab", tall: "coral", cloud: "storm", drop: "water", roll: "urchin", gas: "firecoral", orb: "jelly" },
      floor: ["#8a6a43", "#3a2814", "#d9aa6a"], tint: 0.04, info: "ปูแดง · ปะการังสูง · เมฆพายุ · หอยเม่นกลิ้ง · แมงกะพรุนลอย · น้ำพุพุ่งขึ้น (จังหวะ) · ปะการังไฟ" },
    { id: "space", n: "อวกาศ", e: "🚀", th: "space", vars: ["spaceb", "spaceo"], rv: 300, hz: { drop: 2, roll: 1, gas: 1, orb: 1, laser: 3 },
      sk: { low: "moonrock", tall: "pylon", cloud: "nebula", drop: "meteor", roll: "asteroid", gas: "plasma", orb: "fire" },
      floor: ["#2b2b52", "#090912", "#7b8cff"], tint: 0.0, info: "หินดวงจันทร์ · เสาสถานี · กลุ่มก๊าซนีบูลา · อุกกาบาตตก · เลเซอร์กั้น (ติด-ดับเป็นจังหวะ) · ลูกไฟลอย" },
  ];
  const byId = {}; STAGES.forEach((s) => (byId[s.id] = s));
  const pickRand = (not) => { const L = STAGES.filter((s) => s.id !== not); const s = L[Math.floor(Math.random() * L.length)], v = s.vars[Math.floor(Math.random() * s.vars.length)]; return { st: s, vk: v }; };
  const need = (vk) => (LAY[vk] ? LAY[vk].L.concat(LAY[vk].P).map((l) => "run/" + l[0]) : []);

  /* ----- พื้นหลังพาราแลกซ์ (เรียงซ้ายขวาแบบกระจก ไม่มีรอยต่อ) ----- */
  function paintBg(ctx, vk, x, im, W, alpha) {
    const d = LAY[vk]; if (!d) return;
    ctx.save(); ctx.globalAlpha = alpha; ctx.imageSmoothingEnabled = !PXV[vk];
    for (const [n, f] of d.L) {
      const i = im("run/" + n); if (!i.complete || !i.naturalWidth) continue;
      const bw = Math.round(i.naturalWidth * H / i.naturalHeight);
      if (f === 0) { ctx.drawImage(i, 0, 0, Math.max(bw, W), H); continue; }
      const off = (x * f) % (bw * 2); let t = Math.floor(off / bw), px = t * bw - off;
      for (; px < W; px += bw, t++) {
        if (t % 2) { ctx.save(); ctx.translate(px + bw, 0); ctx.scale(-1, 1); ctx.drawImage(i, 0, 0, bw + 1, H); ctx.restore(); }
        else ctx.drawImage(i, px, 0, bw + 1, H);
      }
    }
    for (const [n, f, y, s, gap] of d.P) {
      const i = im("run/" + n); if (!i.complete || !i.naturalWidth) continue;
      const w = i.naturalWidth * s, h = i.naturalHeight * s, span = gap + w; let px = -((x * f) % span);
      for (; px < W; px += span) ctx.drawImage(i, px, y, w, h);
    }
    ctx.restore();
  }

  /* ----- ตัวช่วยวาด ----- */
  const pg = (c, pts, f, s, lw) => { c.beginPath(); pts.forEach(([a, b], i) => (i ? c.lineTo(a, b) : c.moveTo(a, b))); c.closePath(); if (f) { c.fillStyle = f; c.fill(); } if (s) { c.strokeStyle = s; c.lineWidth = lw || 2; c.stroke(); } };
  const ell = (c, x, y, rx, ry, f, s) => { c.beginPath(); c.ellipse(x, y, rx, ry, 0, 0, 7); if (f) { c.fillStyle = f; c.fill(); } if (s) { c.strokeStyle = s; c.lineWidth = 2; c.stroke(); } };
  const CLOUDP = { storm: { fill: "rgba(88,98,120,.95)", glow: "#9fb3d1", eyes: true, rain: true }, snow: { fill: "rgba(232,246,255,.96)", glow: "#bfe8ff", eyes: false, hang: "rgba(200,235,255,.8)" },
    mist: { fill: "rgba(100,196,184,.92)", glow: "#7ef0d8", eyes: true }, nebula: { fill: "rgba(150,70,200,.9)", glow: "#e879f9", eyes: true } };
  const D = { low: {}, tall: {}, cloud: {}, drop: {}, roll: {}, gas: {}, orb: {}, laser: {}, geyser: {} };
  const gl = (c, col, b) => { c.shadowColor = col; c.shadowBlur = b; };
  const tri = (c, x, y, w, h, f, s) => pg(c, [[x, y + h], [x + w / 2, y], [x + w, y + h]], f, s, 1.5);
  /* ---- เตี้ย (กระโดดข้าม) ---- */
  D.low.rock = (c, x, y, w, h) => { pg(c, [[x - 2, y + h], [x + 2, y + h * .45], [x + w * .35, y + 2], [x + w * .72, y + h * .2], [x + w + 2, y + h * .6], [x + w + 4, y + h]], "#8b8f9a", "#3b3f4a"); pg(c, [[x + 8, y + h * .5], [x + w * .35, y + 8], [x + w * .5, y + h * .5]], "rgba(255,255,255,.22)"); };
  D.low.thorn = (c, x, y, w, h) => { ell(c, x + w / 2, y + h * .72, w * .6, h * .32, "#1f3a2a", "#0c1a12"); for (let i = 0; i < 6; i++) tri(c, x + i * (w / 6) - 2, y + 4 + (i % 2) * 8, 12, h * .7, "#3c7a4e", "#0c1a12"); };
  D.low.mossrock = (c, x, y, w, h) => { D.low.rock(c, x, y, w, h); c.fillStyle = "#4fae6a"; c.beginPath(); c.ellipse(x + w * .45, y + 6, w * .35, 7, 0, 0, 7); c.fill(); };
  D.low.icespike = (c, x, y, w, h) => { tri(c, x - 4, y + 12, 22, h - 12, "#c8f0ff", "#4f9ccc"); tri(c, x + 12, y, 24, h, "#e6fbff", "#4f9ccc"); tri(c, x + 30, y + 14, 20, h - 14, "#b0e2fa", "#4f9ccc"); };
  D.low.crab = (c, x, y, w, h, t) => { const b = Math.sin(t / 110) * 3; ell(c, x + w / 2, y + h * .65, w * .5, h * .32, "#e0453a", "#7a1a14"); for (let i = 0; i < 3; i++) { c.strokeStyle = "#7a1a14"; c.lineWidth = 3; c.beginPath(); c.moveTo(x + 8 + i * 4, y + h * .8); c.lineTo(x + 2 + i * 3, y + h + b * (i % 2 ? 1 : -1)); c.moveTo(x + w - 8 - i * 4, y + h * .8); c.lineTo(x + w - 2 - i * 3, y + h - b * (i % 2 ? 1 : -1)); c.stroke(); }
    ell(c, x - 2, y + h * .3 + b, 9, 7, "#f0604f", "#7a1a14"); ell(c, x + w + 2, y + h * .3 - b, 9, 7, "#f0604f", "#7a1a14"); c.fillStyle = "#fff"; c.beginPath(); c.arc(x + w * .35, y + h * .35, 4, 0, 7); c.arc(x + w * .65, y + h * .35, 4, 0, 7); c.fill(); c.fillStyle = "#000"; c.beginPath(); c.arc(x + w * .35, y + h * .35, 2, 0, 7); c.arc(x + w * .65, y + h * .35, 2, 0, 7); c.fill(); };
  D.low.moonrock = (c, x, y, w, h) => { D.low.rock(c, x, y, w, h); c.fillStyle = "#8e92b8"; c.fillRect(x, y, 0, 0); ell(c, x + w * .35, y + h * .6, 6, 3.5, "rgba(40,40,80,.55)"); ell(c, x + w * .7, y + h * .45, 4, 2.5, "rgba(40,40,80,.55)"); };
  /* ---- สูง (กระโดดสองชั้น) ---- */
  D.tall.trunk = (c, x, y, w, h) => { c.fillStyle = "#7a4a26"; c.fillRect(x + 4, y, w - 8, h); c.fillStyle = "#5a3418"; for (let i = 0; i < 5; i++) c.fillRect(x + 4 + (i % 2) * 14, y + 8 + i * 17, 6, 12); ell(c, x + w / 2, y, w / 2 - 2, 6, "#c18a52", "#5a3418"); };
  D.tall.deadtree = (c, x, y, w, h) => { c.strokeStyle = "#2a2230"; c.lineCap = "round"; c.lineWidth = 12; c.beginPath(); c.moveTo(x + w / 2, y + h); c.lineTo(x + w / 2, y + 8); c.stroke(); c.lineWidth = 6; c.beginPath(); c.moveTo(x + w / 2, y + h * .5); c.lineTo(x - 6, y + h * .25); c.moveTo(x + w / 2, y + h * .35); c.lineTo(x + w + 8, y + 6); c.moveTo(x + w / 2, y + h * .7); c.lineTo(x + w + 4, y + h * .5); c.stroke(); c.lineCap = "butt"; };
  D.tall.crystal = (c, x, y, w, h) => { pg(c, [[x + 4, y + h], [x + 8, y + 24], [x + w / 2 - 4, y]], "#a06bff", "#4a2a8f"); pg(c, [[x + w / 2 - 6, y + h], [x + w / 2 - 6, y + 10], [x + w / 2 + 8, y + 18], [x + w - 8, y + h]], "#c9a0ff", "#4a2a8f"); pg(c, [[x + w - 12, y + h], [x + w - 2, y + 36], [x + w + 2, y + h]], "#8a54ee", "#4a2a8f"); };
  D.tall.icepillar = (c, x, y, w, h) => { pg(c, [[x + 4, y + h], [x + 4, y + 18], [x + w / 2, y], [x + w - 4, y + 18], [x + w - 4, y + h]], "#d6f4ff", "#4f9ccc", 2.5); c.fillStyle = "rgba(255,255,255,.55)"; c.fillRect(x + 12, y + 20, 6, h - 30); };
  D.tall.coral = (c, x, y, w, h) => { c.strokeStyle = "#ff7a59"; c.lineCap = "round"; c.lineWidth = 9; c.beginPath(); c.moveTo(x + w / 2, y + h); c.lineTo(x + w / 2, y + 14); c.moveTo(x + w / 2, y + h * .6); c.lineTo(x + 4, y + h * .35); c.lineTo(x + 4, y + 8); c.moveTo(x + w / 2, y + h * .45); c.lineTo(x + w - 4, y + h * .25); c.lineTo(x + w - 4, y + 4); c.stroke(); c.fillStyle = "#ffc2a8"; [[x + w / 2, y + 12], [x + 4, y + 6], [x + w - 4, y + 2]].forEach(([a, b]) => { c.beginPath(); c.arc(a, b, 5, 0, 7); c.fill(); }); c.lineCap = "butt"; };
  D.tall.pylon = (c, x, y, w, h, t) => { c.fillStyle = "#5a6086"; c.fillRect(x + 12, y + 14, w - 24, h - 14); c.fillStyle = "#3a3f62"; c.fillRect(x + 4, y + h - 10, w - 8, 10); c.fillRect(x + 8, y + 14, w - 16, 6); for (let i = 0; i < 4; i++) { c.fillStyle = "#8fa0ff"; c.fillRect(x + 20, y + 24 + i * 16, w - 40, 6); } const on = Math.floor(t / 300) % 2; c.fillStyle = on ? "#ff5a6a" : "#7a2a34"; c.beginPath(); c.arc(x + w / 2, y + 8, 7, 0, 7); c.fill(); };
  /* ---- ลอยสูง (ต้องสไลด์) ---- */
  function cloudP(c, x, o, t, P) {
    c.save(); const cy = o.h - 20, p = Math.sin(t / 300) * 4, bl = [[.15, .55, 46], [.4, .4, 56], [.7, .55, 50], [.5, .75, 44], [.9, .8, 34]];
    c.fillStyle = P.fill; gl(c, P.glow, 22); for (const [bx, by, r] of bl) { c.beginPath(); c.arc(x + bx * o.w, cy - 36 + by * 50 + p, r, 0, 7); c.fill(); } c.shadowBlur = 0;
    if (P.bats) { c.fillStyle = "#17121f"; for (let i = 0; i < 5; i++) { const bx = x + 14 + i * 24, by = cy - 14 + (i % 2) * 22 + p + Math.sin(t / 90 + i) * 3, f = Math.sin(t / 70 + i) * 7; c.beginPath(); c.moveTo(bx, by); c.quadraticCurveTo(bx + 8, by - 10 - f, bx + 18, by); c.quadraticCurveTo(bx + 9, by - 2, bx, by); c.fill(); } }
    if (P.eyes) { c.fillStyle = P.bats ? "#ff4a5a" : "#1b1238"; c.beginPath(); c.arc(x + o.w * .35, cy + 4 + p, 5, 0, 7); c.arc(x + o.w * .62, cy + 4 + p, 5, 0, 7); c.fill(); }
    c.strokeStyle = P.hang || "rgba(180,200,230,.55)"; c.lineWidth = 4; c.beginPath(); c.moveTo(x + o.w * .3, 0); c.lineTo(x + o.w * .3, cy - 40); c.moveTo(x + o.w * .7, 0); c.lineTo(x + o.w * .7, cy - 40); c.stroke();
    if (P.rain) { c.strokeStyle = "rgba(170,210,255,.8)"; c.lineWidth = 2; for (let i = 0; i < 6; i++) { const rx = x + 14 + i * 20, ry = cy + 20 + ((t / 4 + i * 37) % 40); c.beginPath(); c.moveTo(rx, ry); c.lineTo(rx - 4, ry + 12); c.stroke(); } }
    c.restore();
  }
  CLOUDP.bats = { fill: "rgba(52,38,78,.92)", glow: "#8a5fd0", eyes: true, bats: true };
  /* ---- วัตถุตกจากเพดาน (26x40) ---- */
  const DROPC = { rock: "#b0b4c0", cone: "#a0663a", water: "#5ac8ff", icicle: "#bff0ff", meteor: "#ff9a3c" };
  D.drop.rock = (c, x, o) => pg(c, [[x + 13, o.y + 40], [x - 1, o.y + 18], [x + 6, o.y], [x + 20, o.y + 2], [x + 28, o.y + 20]], "#8b8f9a", "#3b3f4a");
  D.drop.cone = (c, x, o) => { ell(c, x + 13, o.y + 24, 12, 16, "#a0663a", "#4a2c14"); c.strokeStyle = "#6a4020"; c.lineWidth = 1.5; for (let i = 0; i < 4; i++) { c.beginPath(); c.moveTo(x + 3, o.y + 12 + i * 7); c.lineTo(x + 23, o.y + 12 + i * 7); c.stroke(); } };
  D.drop.water = (c, x, o) => { gl(c, "#5ac8ff", 14); c.fillStyle = "#5ac8ff"; c.beginPath(); c.moveTo(x + 13, o.y); c.quadraticCurveTo(x + 34, o.y + 28, x + 13, o.y + 42); c.quadraticCurveTo(x - 8, o.y + 28, x + 13, o.y); c.fill(); c.shadowBlur = 0; c.fillStyle = "rgba(255,255,255,.6)"; c.beginPath(); c.arc(x + 8, o.y + 26, 3, 0, 7); c.fill(); };
  D.drop.icicle = (c, x, o) => pg(c, [[x - 2, o.y], [x + 28, o.y], [x + 13, o.y + 44]], "#d6f4ff", "#4f9ccc", 2);
  D.drop.meteor = (c, x, o, t) => { gl(c, "#ff7a2a", 18); c.fillStyle = "rgba(255,150,60,.55)"; c.beginPath(); c.moveTo(x + 4, o.y - 28); c.lineTo(x + 22, o.y - 28); c.lineTo(x + 18, o.y + 20); c.lineTo(x + 8, o.y + 20); c.fill(); c.shadowBlur = 0; ell(c, x + 13, o.y + 26, 13, 14, "#7a4a2a", "#ffb45a"); };
  D.dropSplash = (sk) => ({ rock: "rgba(200,200,210,.7)", cone: "rgba(180,130,80,.7)", water: "rgba(120,210,255,.7)", icicle: "rgba(210,240,255,.8)", meteor: "rgba(255,140,50,.75)" })[sk] || "rgba(160,255,60,.7)";
  /* ---- กลิ้ง (รัศมี 20 · วาดที่จุดกลางหลังหมุนแล้ว) ---- */
  D.roll.boulder = (c) => { ell(c, 0, 0, 22, 21, "#8b8f9a", "#3b3f4a"); c.strokeStyle = "#4a4f5a"; c.lineWidth = 2; c.beginPath(); c.moveTo(-10, -8); c.lineTo(2, 0); c.lineTo(-4, 12); c.moveTo(8, -14); c.lineTo(12, -2); c.stroke(); };
  D.roll.log = (c) => { ell(c, 0, 0, 22, 22, "#b07a44", "#5a3418"); ell(c, 0, 0, 14, 14, null, "#7a4a26"); ell(c, 0, 0, 6, 6, null, "#7a4a26"); c.fillStyle = "#5a3418"; c.fillRect(-1, 8, 2, 8); };
  D.roll.mossball = (c) => { ell(c, 0, 0, 22, 21, "#5f9a6a", "#2a5a3a"); c.fillStyle = "#8fd89a"; for (let i = 0; i < 6; i++) { c.beginPath(); c.arc(Math.cos(i * 1.05) * 12, Math.sin(i * 1.05) * 12, 4, 0, 7); c.fill(); } };
  D.roll.snowball = (c) => { ell(c, 0, 0, 22, 22, "#f4fbff", "#8ac4e6"); c.fillStyle = "#cfe8f6"; c.beginPath(); c.arc(-6, -5, 5, 0, 7); c.arc(7, 6, 4, 0, 7); c.fill(); };
  D.roll.urchin = (c) => { c.strokeStyle = "#3a1a5a"; c.lineWidth = 3; for (let i = 0; i < 12; i++) { const a = i * .5236; c.beginPath(); c.moveTo(Math.cos(a) * 12, Math.sin(a) * 12); c.lineTo(Math.cos(a) * 24, Math.sin(a) * 24); c.stroke(); } ell(c, 0, 0, 14, 14, "#7a3aa8", "#3a1a5a"); };
  D.roll.asteroid = (c) => { pg(c, [[-22, -4], [-12, -20], [6, -22], [22, -6], [18, 14], [0, 22], [-16, 16]], "#6b6f8e", "#2f3150"); ell(c, -6, -4, 5, 4, "rgba(30,30,60,.6)"); ell(c, 8, 8, 4, 3, "rgba(30,30,60,.6)"); };
  /* ---- พื้นอันตราย (กว้าง 160 สูง 28) ---- */
  const row = (c, x, o, n, fn) => { for (let i = 0; i < n; i++) fn(x + 6 + i * (o.w - 12) / (n - 1), i); };
  D.gas.spikes = (c, x, o) => row(c, x, o, 7, (px) => tri(c, px - 10, o.y, 20, o.h, "#a8adbb", "#3b3f4a"));
  D.gas.slime = (c, x, o, t) => { gl(c, "#7ee03a", 12); ell(c, x + o.w / 2, o.y + 20, o.w / 2, 9, "rgba(100,210,50,.85)"); c.shadowBlur = 0; c.fillStyle = "#c8ff90"; for (let i = 0; i < 4; i++) { c.beginPath(); c.arc(x + 24 + i * 38, o.y + 12 - Math.abs(Math.sin(t / 300 + i * 2)) * 10, 5, 0, 7); c.fill(); } };
  D.gas.tealslime = (c, x, o, t) => { gl(c, "#4ff0d0", 12); ell(c, x + o.w / 2, o.y + 20, o.w / 2, 9, "rgba(40,200,180,.85)"); c.shadowBlur = 0; c.fillStyle = "#b0fff0"; for (let i = 0; i < 4; i++) { c.beginPath(); c.arc(x + 24 + i * 38, o.y + 12 - Math.abs(Math.sin(t / 300 + i * 2)) * 10, 5, 0, 7); c.fill(); } };
  D.gas.icerow = (c, x, o) => row(c, x, o, 9, (px, i) => tri(c, px - 8, o.y + (i % 2) * 6, 16, o.h - (i % 2) * 6, "#d6f4ff", "#4f9ccc"));
  D.gas.firecoral = (c, x, o, t) => row(c, x, o, 6, (px, i) => { const f = Math.sin(t / 120 + i) * 4; gl(c, "#ff6a2a", 10); pg(c, [[px - 9, o.y + o.h], [px - 4 + f, o.y + 8], [px, o.y - 4], [px + 5 - f, o.y + 10], [px + 9, o.y + o.h]], "#ff8a3a", "#a02a0a", 1.5); c.shadowBlur = 0; });
  D.gas.plasma = (c, x, o, t) => { gl(c, "#e879f9", 16); for (let i = 0; i < 5; i++) { const px = x + 16 + i * 32, r = 14 + Math.sin(t / 200 + i) * 4; c.fillStyle = i % 2 ? "rgba(232,121,249,.8)" : "rgba(120,160,255,.8)"; c.beginPath(); c.arc(px, o.y + 16, r, 0, 7); c.fill(); } c.shadowBlur = 0; };
  /* ---- ลูกลอยขึ้นลง (36) ---- */
  const halo = (c, cx, cy, a, b, r) => { const g = c.createRadialGradient(cx, cy, 2, cx, cy, r); g.addColorStop(0, "#fff"); g.addColorStop(.4, a); g.addColorStop(1, b); c.fillStyle = g; c.beginPath(); c.arc(cx, cy, r, 0, 7); c.fill(); };
  D.orb.ember = (c, x, o) => halo(c, x + 18, o.y + 18, "#ffb04a", "rgba(255,120,30,0)", 26);
  D.orb.fire = (c, x, o, t) => { halo(c, x + 18, o.y + 18, "#ff6a3a", "rgba(255,60,30,0)", 26); pg(c, [[x + 8, o.y + 30], [x + 12 + Math.sin(t / 80) * 3, o.y + 6], [x + 20, o.y + 20], [x + 26, o.y + 4], [x + 30, o.y + 30]], "#ffd36a", null); };
  D.orb.firefly = (c, x, o, t) => { halo(c, x + 18, o.y + 18, "#d8ff5a", "rgba(200,255,60,0)", 22); const f = Math.sin(t / 40) * 4; ell(c, x + 8, o.y + 12 + f, 8, 4, "rgba(255,255,255,.7)"); ell(c, x + 28, o.y + 12 - f, 8, 4, "rgba(255,255,255,.7)"); };
  D.orb.spirit = (c, x, o, t) => { halo(c, x + 18, o.y + 14, "#8ff6ff", "rgba(80,220,255,0)", 24); c.fillStyle = "rgba(160,245,255,.85)"; c.beginPath(); c.moveTo(x + 6, o.y + 14); c.quadraticCurveTo(x + 18, o.y - 14, x + 30, o.y + 14); c.lineTo(x + 30, o.y + 36); for (let i = 0; i < 3; i++) c.lineTo(x + 30 - (i + 1) * 8, o.y + 30 + (i % 2 ? 0 : 6)); c.lineTo(x + 6, o.y + 36); c.fill(); c.fillStyle = "#124a60"; c.beginPath(); c.arc(x + 13, o.y + 16, 2.5, 0, 7); c.arc(x + 23, o.y + 16, 2.5, 0, 7); c.fill(); };
  D.orb.flake = (c, x, o, t) => { c.save(); c.translate(x + 18, o.y + 18); c.rotate(t / 500); c.strokeStyle = "#e8fbff"; gl(c, "#8fdcff", 10); c.lineWidth = 3; for (let i = 0; i < 6; i++) { c.rotate(1.0472); c.beginPath(); c.moveTo(0, 0); c.lineTo(0, -20); c.moveTo(0, -12); c.lineTo(6, -17); c.moveTo(0, -12); c.lineTo(-6, -17); c.stroke(); } c.restore(); };
  D.orb.jelly = (c, x, o, t) => { gl(c, "#ff7ad0", 12); c.fillStyle = "rgba(255,130,210,.85)"; c.beginPath(); c.arc(x + 18, o.y + 16, 16, Math.PI, 0); c.lineTo(x + 34, o.y + 22); c.lineTo(x + 2, o.y + 22); c.fill(); c.shadowBlur = 0; c.strokeStyle = "rgba(255,170,225,.9)"; c.lineWidth = 3; for (let i = 0; i < 4; i++) { c.beginPath(); c.moveTo(x + 7 + i * 7, o.y + 22); c.quadraticCurveTo(x + 7 + i * 7 + Math.sin(t / 150 + i) * 5, o.y + 30, x + 7 + i * 7, o.y + 38); c.stroke(); } };
  /* ---- เลเซอร์ (กว้าง 110, ติด-ดับ) และน้ำพุพุ่ง (กว้าง 44, สูง 110) ---- */
  const phase = (o, t) => { if (o.k === "laser") { const u = (t + o.ph) % 2.2; return u < 1.1 ? 2 : u > 0.75 + 1.1 ? 1 : 0; } const u = (t + o.ph) % 2.4; return u >= 1.4 && u < 2.2 ? 2 : u >= 1.0 && u < 1.4 ? 1 : 0; };
  D.laser = (c, x, o, t, ph) => {
    for (const px of [x, x + o.w - 10]) { c.fillStyle = "#4a4f78"; c.fillRect(px - 2, GY - 78, 12, 78); c.fillStyle = "#8f9bff"; c.fillRect(px, GY - 76, 8, 6); c.fillStyle = ph === 2 ? "#ff5a6a" : "#5a2a3a"; c.beginPath(); c.arc(px + 4, GY - 62, 4, 0, 7); c.fill(); }
    if (ph === 2) { gl(c, "#ff4a6a", 18); c.fillStyle = "#ff5a7a"; c.fillRect(x + 8, GY - 66, o.w - 16, 8); c.shadowBlur = 0; c.fillStyle = "#fff"; c.fillRect(x + 8, GY - 64, o.w - 16, 3); }
    else if (ph === 1 && Math.floor(t * 14) % 2) { c.fillStyle = "rgba(255,90,120,.5)"; c.fillRect(x + 8, GY - 63, o.w - 16, 2); }
  };
  D.geyser = (c, x, o, t, ph, col) => {
    ell(c, x + o.w / 2, GY - 2, 26, 6, "rgba(0,0,0,.35)"); ell(c, x + o.w / 2, GY - 3, 18, 4, col[1]);
    if (ph === 1) { c.fillStyle = col[0]; for (let i = 0; i < 4; i++) { const by = GY - 6 - ((t * 60 + i * 17) % 30); c.globalAlpha = .7; c.beginPath(); c.arc(x + 10 + (i * 9) % 26, by, 3 + (i % 2), 0, 7); c.fill(); } c.globalAlpha = 1; }
    if (ph === 2) { gl(c, col[0], 14); const g = c.createLinearGradient(0, GY - 110, 0, GY); g.addColorStop(0, "rgba(255,255,255,.85)"); g.addColorStop(1, col[0]); c.fillStyle = g; c.beginPath(); c.moveTo(x + 6, GY - 2); c.lineTo(x + 12 + Math.sin(t * 20) * 2, GY - 108); c.lineTo(x + o.w - 12 - Math.sin(t * 20) * 2, GY - 108); c.lineTo(x + o.w - 6, GY - 2); c.fill(); c.shadowBlur = 0; }
  };
  const STC = { fall: ["#8ae0ff", "#2d6585"], sea: ["#ff9a4a", "#8a4a22"] };

  /* ----- ส่วนที่ run.js เรียกใช้ ----- */
  function drawThing(c, o, x, t, g) {
    const sk = (byId[o.st] || {}).sk || {}, k = o.k, s = sk[k];
    if (k === "low" && s) D.low[s](c, x, o.y, o.w, o.h, t);
    else if (k === "tall" && s) D.tall[s](c, x, o.y, o.w, o.h, t);
    else if (k === "cloud" && s) cloudP(c, x, o, t, CLOUDP[s]);
    else if (k === "roll" && s) { c.save(); c.translate(x + 20, o.y + 20); c.rotate(-(t / 120)); D.roll[s](c); c.restore(); }
    else if (k === "gas" && s) D.gas[s](c, x, o, t);
    else if (k === "orb" && s) D.orb[s](c, x, o, t);
    else if (k === "laser") D.laser(c, x, o, t, phase(o, g.time));
    else if (k === "geyser") D.geyser(c, x, o, t, phase(o, g.time), STC[o.st] || STC.fall);
    else return false;
    return true;
  }
  const active = (o, t) => phase(o, t) === 2;
  return { STAGES, byId, pickRand, need, paintBg, drawThing, drop: D.drop, dropSplash: D.dropSplash, DROPC, active, GYV: GY };
})();
