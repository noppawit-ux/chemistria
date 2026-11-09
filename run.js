/* มินิเกม: เคมีรัน — วิ่งเก็บเหรียญ หลบอุปสรรคแล็บ (สไตล์ Cookie Run) · ตัวละครคือชุดที่นักเรียนสวมอยู่
   กด/แตะ "กระโดด" (กระโดดซ้อนได้ 2 ครั้ง) · กดค้าง "สไลด์" ลอดใต้เมฆพิษ · พลังชีวิตลดเรื่อยๆ ต้องเก็บยาฟื้นพลัง
   เซิร์ฟเวอร์ตรวจคะแนนกับเวลา (run_submit) แล้วให้ EXP ตามคะแนน */
const RUN = (() => {
  const W = 560, H = 420, GY = 350;               // พิกัดตรรกะของแคนวาส · GY = ระดับพื้น
  const IMGS = {};
  const need = ["icons/coin", "icons/star", "icons/heart", "items/tile", "items/potion_red", "items/burner", "items/rack", "items/shield", "items/hourglass", "items/flask",
    "arenas/lab", "arenas/storm", "arenas/volcano", "arenas/crystal", "arenas/ice", "arenas/swamp"];
  const img = (k) => { if (!IMGS[k]) { const i = new Image(); i.src = `assets/${k}.${k.startsWith("arenas/") ? "jpg" : "png"}`; IMGS[k] = i; } return IMGS[k]; };
  const ARENAS = ["lab", "storm", "volcano", "crystal", "ice", "swamp"];
  const S = { screen: "home", st: null, res: null, g: null, raf: 0, keys: {} };

  const spriteSrc = () => {
    const s = D.student, dc = s.decor || {}, cls = s.char_class || "novice";
    return "assets/chars/" + cls + (altGender(cls, dc.gender) ? "_alt" : "") + (dc.outfit ? "_" + dc.outfit.key : "") + ".png";
  };
  const paint = () => GAMES.paint();
  async function open() {
    cancelAnimationFrame(S.raf); S.screen = "home"; S.st = null; GAMES.setMode("run"); paint();
    try { S.st = await rpc("run_status", { p_token: tk() }); } catch (e) {} paint();
  }

  /* ---------- เริ่มเกม ---------- */
  function start() {
    GB("run");
    cancelAnimationFrame(S.raf); need.forEach(img);
    const me = new Image(); me.src = spriteSrc(); me.onerror = () => { me.onerror = null; me.src = "assets/chars/" + (D.student.char_class || "novice") + ".png"; };
    const dc = D.student.decor || {}; let pet = null; if (dc.pet && dc.pet.image) { pet = new Image(); pet.src = dc.pet.image; }
    S.g = { me, pet, t0: 0, last: 0, cd: 3, cdT: performance.now(), over: false, x: 0, dist: 0, speed: 300, hp: 100,
      y: GY, vy: 0, jumps: 0, slide: 0, slideHold: false, inv: 0, boost: 0, shield: false, slow: 0, mag: 0, combo: 0, bestCombo: 0, warnT: 0, coins: 0, tiles: 0, hits: 0, hurt: 0, pots: 0, nextX: 700, things: [], fx: [], shake: 0, anim: 0, time: 0 };
    S.screen = "play"; paint();
    requestAnimationFrame(() => { bind(); S.raf = requestAnimationFrame(loop); });
  }

  /* ---------- ควบคุม ---------- */
  function jump() {
    const g = S.g; if (!g || g.over || g.cd > 0) return;
    if (g.jumps < 2) { g.vy = g.jumps === 0 ? -830 : -760; g.jumps++; g.slide = 0; try { SFX.play("pop"); } catch (e) {} }
  }
  function slide(on) { const g = S.g; if (!g || g.over) return; g.slideHold = on; if (on && g.y >= GY && g.cd <= 0) g.slide = Math.max(g.slide, 0.55); }
  let bound = false;
  function bind() {
    if (bound) return; bound = true;
    document.addEventListener("keydown", (e) => {
      if (S.screen !== "play" || !S.g) return;
      if (["Space", "ArrowUp", "KeyW"].includes(e.code)) { e.preventDefault(); if (!e.repeat) jump(); }
      if (["ArrowDown", "KeyS"].includes(e.code)) { e.preventDefault(); slide(true); }
    });
    document.addEventListener("keyup", (e) => { if (["ArrowDown", "KeyS"].includes(e.code)) slide(false); });
  }

  /* ---------- สร้างด่าน ---------- */
  function spawn(g) {
    const x = g.nextX, r = Math.random(), L = g.things;
    const coinRow = (n, y, dx = 44) => { for (let i = 0; i < n; i++) L.push({ k: Math.random() < 0.12 ? "tile" : "coin", x: x + i * dx, y, w: 34, h: 34 }); };
    if (r < 0.22) { coinRow(6, GY - 50); g.nextX += 520; }
    else if (r < 0.46) {      // เตาไฟเตี้ย + เหรียญโค้งเหนือ
      L.push({ k: "low", x: x + 120, y: GY - 46, w: 46, h: 46 });
      for (let i = 0; i < 6; i++) L.push({ k: "coin", x: x + 40 + i * 44, y: GY - 60 - Math.sin((i / 5) * Math.PI) * 120, w: 34, h: 34 });
      g.nextX += 560;
    } else if (r < 0.64) {    // เมฆพิษลอยสูง ต้องสไลด์
      L.push({ k: "cloud", x: x + 100, y: 0, w: 120, h: GY - 62 });
      coinRow(4, GY - 30, 40); g.nextX += 540;
    } else if (r < 0.80) {    // ชั้นหลอดทดลองสูง ต้องกระโดดสองชั้น
      L.push({ k: "tall", x: x + 120, y: GY - 92, w: 52, h: 92 });
      for (let i = 0; i < 5; i++) L.push({ k: "coin", x: x + 60 + i * 50, y: GY - 215 + (i === 2 ? -16 : 0) + Math.abs(i - 2) * 18, w: 34, h: 34 });
      g.nextX += 600;
    } else if (r < 0.88 && g.hp < 80) { L.push({ k: "pot", x: x + 40, y: GY - 80, w: 38, h: 44 }); coinRow(3, GY - 50); g.nextX += 480; }
    else if (r < 0.93) { L.push({ k: "star", x: x + 40, y: GY - 130, w: 44, h: 44 }); coinRow(5, GY - 50); g.nextX += 520; }
    else { L.push({ k: "low", x: x + 80, y: GY - 46, w: 46, h: 46 }); L.push({ k: "low", x: x + 360, y: GY - 46, w: 46, h: 46 }); coinRow(4, GY - 160, 60); g.nextX += 620; }
    if (g.hp < 55 && Math.random() < 0.25) L.push({ k: "pot", x: x + 260, y: GY - 120, w: 38, h: 44 });
    // ===== อุปสรรคชุดใหม่ (เริ่มหลังวิ่งไป 120 เมตร) + ไอเทมพิเศษ =====
    if (g.dist > 120 && Math.random() < Math.min(0.55, 0.25 + g.dist / 3000)) {
      const hx = g.nextX + 60, q = Math.random();
      if (q < 0.25) { L.push({ k: "drop", x: hx + 40, y: -50, w: 26, h: 40, fall: false }); L.push({ k: "drop", x: hx + 190, y: -50, w: 26, h: 40, fall: false }); }
      else if (q < 0.5) { L.push({ k: "roll", x: hx + 260, y: GY - 40, w: 40, h: 40 }); coinRow(4, GY - 150, 46); }
      else if (q < 0.75) { L.push({ k: "gas", x: hx + 40, y: GY - 28, w: 160, h: 28 }); for (let i = 0; i < 5; i++) L.push({ k: "coin", x: hx + 40 + i * 34, y: GY - 130 - Math.sin((i / 4) * Math.PI) * 50, w: 34, h: 34 }); }
      else { L.push({ k: "orb", x: hx + 120, y: GY - 120, by: GY - 120, ph: Math.random() * 6, w: 36, h: 36 }); L.push({ k: "orb", x: hx + 330, y: GY - 120, by: GY - 120, ph: Math.random() * 6 + 2, w: 36, h: 36 }); }
      g.nextX += 520;
    }
    if (Math.random() < 0.09) { const kk = ["shield", "slow", "mag"][Math.floor(Math.random() * 3)]; L.push({ k: kk, x: x + 300, y: GY - 120, w: 40, h: 40 }); }
  }

  /* ---------- วนเกม ---------- */
  function loop(now) {
    const cv = document.getElementById("runcv"); const g = S.g;
    if (!cv || !cv.isConnected || !g || S.screen !== "play") return;
    const ctx = cv.getContext("2d");
    if (g.cd > 0) {
      const el = (now - g.cdT) / 1000; g.cd = 3 - el; if (g.cd <= 0) { g.cd = 0; g.t0 = now; g.last = now; }
      draw(ctx, g, now); S.raf = requestAnimationFrame(loop); return;
    }
    const dt = Math.min(0.05, (now - g.last) / 1000); g.last = now; g.time = (now - g.t0) / 1000;
    update(g, dt);
    draw(ctx, g, now);
    if (g.over) return end();
    S.raf = requestAnimationFrame(loop);
  }

  const PX = 92;                                  // ตำแหน่งแนวนอนของผู้เล่นบนจอ
  function hitbox(g) { const sl = g.slide > 0 && g.y >= GY - 1; return sl ? { x: PX + 4, y: g.y - 44, w: 62, h: 44 } : { x: PX + 14, y: g.y - 96, w: 40, h: 96 }; }
  function update(g, dt) {
    const ts = g.slow > 0 ? 0.65 : 1, sp = g.speed * (g.boost > 0 ? 1.55 : 1) * ts;
    g.x += sp * dt; g.dist += sp * dt / 50;
    g.speed = Math.min(640, 300 + g.time * 5.5);
    g.hp -= (3.2 + g.time * 0.025) * dt * (g.boost > 0 ? 0 : 1);
    if (g.hp <= 0) { g.hp = 0; g.over = true; }
    // ฟิสิกส์ผู้เล่น
    g.vy += 2500 * dt; g.y += g.vy * dt;
    if (g.y >= GY) { if (g.vy > 400) g.shake = Math.max(g.shake, 2); g.y = GY; g.vy = 0; g.jumps = 0; }
    if (g.slide > 0) { g.slide -= dt; if (g.slideHold) g.slide = Math.max(g.slide, 0.05); if (g.y < GY) g.slide = 0; }
    if (g.slow > 0) g.slow -= dt; if (g.mag > 0) g.mag -= dt; if (g.inv > 0) g.inv -= dt; if (g.hurt > 0) g.hurt = Math.max(0, g.hurt - dt); if (g.boost > 0) { g.boost -= dt; g.inv = Math.max(g.inv, 0.1); }
    if (g.shake > 0) g.shake = Math.max(0, g.shake - 20 * dt);
    g.anim += dt * (8 + sp / 90);
    // สร้างด่านล่วงหน้า
    while (g.nextX < g.x + W + 300) spawn(g);
    // ชน/เก็บ
    const hb = hitbox(g), magnet = g.boost > 0 || g.mag > 0;
    for (const o of g.things) {
      if (o.dead) continue;
      if (o.k === "roll") o.x -= 200 * dt * ts;
      else if (o.k === "orb") o.y = o.by + Math.sin(g.time * 3 + o.ph) * 70;
      else if (o.k === "drop") {
        if (!o.fall && o.x - g.x < 430) o.fall = true;
        if (o.fall && !o.splash) { o.y += 600 * dt; if (o.y >= GY - o.h) { o.y = GY - o.h; o.splash = 0.001; } }
        else if (o.splash) { o.splash += dt; if (o.splash > 0.35) o.dead = true; }
      }
      const sx = o.x - g.x;
      if (sx < -160) { o.dead = true; continue; }
      let ox = sx, oy = o.y;
      if (magnet && (o.k === "coin" || o.k === "tile") && sx < 360) { o.x -= (sx - 60) * 4 * dt; o.y += (hb.y + 30 - o.y) * 4 * dt; ox = o.x - g.x; oy = o.y; }
      const inter = ox < hb.x + hb.w && ox + o.w > hb.x && oy < hb.y + hb.h && oy + o.h > hb.y;
      if (!inter) continue;
      if (o.k === "drop" && o.splash) continue;
      if (o.k === "coin") { o.dead = true; g.coins++; g.combo++; g.bestCombo = Math.max(g.bestCombo, g.combo); pop(g, ox, oy, "+10", "#ffd75a"); try { SFX.play("coin"); } catch (e) {}
        if (g.combo % 10 === 0) { g.hp = Math.min(100, g.hp + 3); pop(g, PX, hb.y - 24, `คอมโบ x${g.combo}! +3HP`, "#9be21b"); } }
      else if (o.k === "shield") { o.dead = true; g.shield = true; pop(g, ox, oy, "โล่!", "#7dd3fc"); try { SFX.play("rank"); } catch (e) {} }
      else if (o.k === "slow") { o.dead = true; g.slow = 5; pop(g, ox, oy, "ชะลอเวลา!", "#c4b5fd"); try { SFX.play("rank"); } catch (e) {} }
      else if (o.k === "mag") { o.dead = true; g.mag = 6; pop(g, ox, oy, "แม่เหล็ก!", "#fca5a5"); try { SFX.play("rank"); } catch (e) {} }
      else if (o.k === "tile") { o.dead = true; g.tiles++; pop(g, ox, oy, "+25", "#7ee0b0"); try { SFX.play("ok"); } catch (e) {} }
      else if (o.k === "pot") { o.dead = true; g.pots++; g.hp = Math.min(100, g.hp + 28); pop(g, ox, oy, "+HP", "#ff7a90"); try { SFX.play("levelup"); } catch (e) {} }
      else if (o.k === "star") { o.dead = true; g.boost = 4; pop(g, ox, oy, "บูสต์!", "#fff3a0"); try { SFX.play("rank"); } catch (e) {} }
      else if (g.inv <= 0 && g.shield) { g.shield = false; g.inv = 1.0; g.shake = 5; g.hurt = 0.5; pop(g, hb.x, hb.y - 10, "โล่แตก!", "#7dd3fc"); try { SFX.play("pop"); } catch (e) {} }
      else if (g.inv <= 0) { g.hp -= 18; g.inv = 1.25; g.shake = 9; g.hurt = 0.6; g.hits++; g.combo = 0; g.speed = Math.max(300, g.speed - 60); g.time = Math.max(0, g.time - 4); pop(g, hb.x, hb.y - 10, "-18", "#ff6b81"); try { SFX.play("bad"); } catch (e) {} if (g.hp <= 0) { g.hp = 0; g.over = true; } }
    }
    g.things = g.things.filter((o) => !o.dead);
    g.fx = g.fx.filter((f) => (f.t += dt) < 0.8); g.fx.forEach((f) => { f.y -= 50 * dt; });
  }
  const pop = (g, x, y, t, c) => g.fx.push({ x, y, t: 0, s: t, c });
  const score = (g) => Math.floor(g.dist) + g.coins * 10 + g.tiles * 25;

  /* ---------- วาด ---------- */
  function draw(ctx, g, now) {
    ctx.save(); ctx.clearRect(0, 0, W, H);
    if (g.shake > 0) ctx.translate((Math.random() - 0.5) * g.shake, (Math.random() - 0.5) * g.shake);
    // ฉากหลัง: เปลี่ยนสนามทุก 800 เมตร พร้อมเลื่อนแบบพาราแลกซ์
    const ai = Math.floor(g.dist / 800) % ARENAS.length, bg = img("arenas/" + ARENAS[ai]);
    if (bg.complete && bg.naturalWidth) {
      const sc = H / bg.naturalHeight, bw = bg.naturalWidth * sc, off = (g.x * 0.18) % bw;
      for (let x = -off; x < W; x += bw) ctx.drawImage(bg, x, 0, bw + 1, H);
    } else { ctx.fillStyle = "#241254"; ctx.fillRect(0, 0, W, H); }
    ctx.fillStyle = "rgba(10,5,30,.35)"; ctx.fillRect(0, 0, W, H);
    // พื้น
    const gr = ctx.createLinearGradient(0, GY, 0, H); gr.addColorStop(0, "#4a2f8f"); gr.addColorStop(1, "#1a0f3a");
    ctx.fillStyle = gr; ctx.fillRect(0, GY, W, H - GY);
    ctx.fillStyle = "#b08cff"; ctx.fillRect(0, GY, W, 4);
    ctx.strokeStyle = "rgba(255,255,255,.12)"; ctx.lineWidth = 2; const so = (g.x % 80);
    for (let x = -so; x < W; x += 80) { ctx.beginPath(); ctx.moveTo(x, GY + 4); ctx.lineTo(x - 30, H); ctx.stroke(); }
    if (g.boost > 0) { ctx.fillStyle = "rgba(255,230,120,.16)"; ctx.fillRect(0, 0, W, H); for (let i = 0; i < 8; i++) { const y = (i * 53 + now * 0.9) % GY; ctx.fillStyle = "rgba(255,255,255,.35)"; ctx.fillRect((W - ((now * 1.6 + i * 97) % W)), y, 70, 2); } }
    // ของในด่าน
    for (const o of g.things) {
      const x = o.x - g.x; if (x > W + 60 || x < -160) continue;
      if (o.k === "coin") { const b = Math.sin(now / 160 + o.x) * 3; ctx.drawImage(img("icons/coin"), x, o.y + b, o.w, o.h); }
      else if (o.k === "tile") { const b = Math.sin(now / 150 + o.x) * 3; ctx.drawImage(img("items/tile"), x, o.y + b, o.w, o.h); }
      else if (o.k === "pot") ctx.drawImage(img("items/potion_red"), x, o.y + Math.sin(now / 200) * 4, o.w, o.h);
      else if (o.k === "star") { ctx.save(); ctx.translate(x + 22, o.y + 22); ctx.rotate(now / 600); ctx.drawImage(img("icons/star"), -26, -26, 52, 52); ctx.restore(); }
      else if (o.k === "low") ctx.drawImage(img("items/burner"), x - 6, o.y - 8, o.w + 12, o.h + 12);
      else if (o.k === "tall") ctx.drawImage(img("items/rack"), x - 14, o.y - 6, o.w + 28, o.h + 6);
      else if (o.k === "cloud") cloud(ctx, x, o, now);
      else if (o.k === "shield") ctx.drawImage(img("items/shield"), x, o.y + Math.sin(now / 200) * 4, o.w, o.h);
      else if (o.k === "slow") ctx.drawImage(img("items/hourglass"), x, o.y + Math.sin(now / 200) * 4, o.w, o.h);
      else if (o.k === "mag") { ctx.font = "34px serif"; ctx.textAlign = "left"; ctx.fillText("🧲", x, o.y + 32 + Math.sin(now / 200) * 4); }
      else if (o.k === "roll") { ctx.save(); ctx.translate(x + 20, o.y + 20); ctx.rotate(-(now / 120)); ctx.drawImage(img("items/flask"), -24, -24, 48, 48); ctx.restore(); }
      else if (o.k === "gas") gas(ctx, x, o, now);
      else if (o.k === "orb") orb(ctx, x, o, now);
      else if (o.k === "drop") drop(ctx, x, o, now);
    }
    // สัตว์เลี้ยงวิ่งตาม
    if (g.pet && g.pet.complete && g.pet.naturalWidth) ctx.drawImage(g.pet, PX - 52, GY - 46 - Math.abs(Math.sin(g.anim * 0.9)) * 8 - (GY - g.y) * 0.6, 42, 42);
    // ผู้เล่น
    player(ctx, g, now);
    // ข้อความลอย
    ctx.font = "800 22px Prompt, Sarabun, sans-serif"; ctx.textAlign = "center";
    for (const f of g.fx) { ctx.globalAlpha = 1 - f.t / 0.8; ctx.fillStyle = f.c; ctx.strokeStyle = "#1b1238"; ctx.lineWidth = 4; ctx.strokeText(f.s, f.x + 20, f.y); ctx.fillText(f.s, f.x + 20, f.y); }
    ctx.globalAlpha = 1; ctx.restore();
    hud(ctx, g);
  }
  function gas(ctx, x, o, now) {
    ctx.save(); ctx.fillStyle = "rgba(120,220,60,.55)"; ctx.shadowColor = "#a3e635"; ctx.shadowBlur = 18;
    for (let i = 0; i < 6; i++) { const bx = x + 14 + i * 26, p = Math.sin(now / 260 + i) * 5; ctx.beginPath(); ctx.arc(bx, o.y + 16 + p, 20 + (i % 2) * 4, 0, 7); ctx.fill(); }
    ctx.shadowBlur = 0; ctx.fillStyle = "#dfffa0"; ctx.font = "700 14px Prompt, Sarabun, sans-serif"; ctx.textAlign = "center"; ctx.fillText("☠", x + o.w / 2, o.y + 8); ctx.restore();
  }
  function orb(ctx, x, o, now) {
    ctx.save(); const cx = x + 18, cy = o.y + 18, gr = ctx.createRadialGradient(cx, cy, 2, cx, cy, 26);
    gr.addColorStop(0, "#fff"); gr.addColorStop(0.4, "#7dd3fc"); gr.addColorStop(1, "rgba(56,189,248,0)");
    ctx.fillStyle = gr; ctx.beginPath(); ctx.arc(cx, cy, 26, 0, 7); ctx.fill();
    ctx.strokeStyle = "#e0f7ff"; ctx.lineWidth = 2; ctx.beginPath();
    for (let k = 0; k < 4; k++) { const a = now / 90 + k * 1.57; ctx.moveTo(cx, cy); ctx.lineTo(cx + Math.cos(a) * 26, cy + Math.sin(a * 1.3) * 26); } ctx.stroke(); ctx.restore();
  }
  function drop(ctx, x, o, now) {
    ctx.save();
    if (!o.fall) { const a = 0.5 + Math.sin(now / 90) * 0.4; ctx.globalAlpha = a; ctx.fillStyle = "#ff6b81"; ctx.beginPath(); ctx.moveTo(x + 13, GY - 30); ctx.lineTo(x + 28, GY - 4); ctx.lineTo(x - 2, GY - 4); ctx.closePath(); ctx.fill(); ctx.globalAlpha = 1; ctx.fillStyle = "#fff"; ctx.font = "800 14px Prompt, sans-serif"; ctx.textAlign = "center"; ctx.fillText("!", x + 13, GY - 8); ctx.restore(); return; }
    if (o.splash) { ctx.fillStyle = "rgba(160,255,60,.7)"; ctx.beginPath(); ctx.ellipse(x + 13, GY - 3, 28 * (1 + o.splash * 2), 7, 0, 0, 7); ctx.fill(); ctx.restore(); return; }
    ctx.fillStyle = "#a3e635"; ctx.shadowColor = "#a3e635"; ctx.shadowBlur = 14; ctx.beginPath(); ctx.moveTo(x + 13, o.y); ctx.quadraticCurveTo(x + 32, o.y + 26, x + 13, o.y + 40); ctx.quadraticCurveTo(x - 6, o.y + 26, x + 13, o.y); ctx.fill(); ctx.restore();
  }
  function cloud(ctx, x, o, now) {
    ctx.save(); const cy = o.h - 20, p = Math.sin(now / 300) * 4;
    const blobs = [[0.15, 0.55, 46], [0.4, 0.4, 56], [0.7, 0.55, 50], [0.5, 0.75, 44], [0.9, 0.8, 34]];
    ctx.fillStyle = "rgba(125,60,170,.94)"; ctx.shadowColor = "#b46bff"; ctx.shadowBlur = 24;
    for (const [bx, by, r] of blobs) { ctx.beginPath(); ctx.arc(x + bx * o.w, cy - 36 + by * 50 + p, r, 0, 7); ctx.fill(); }
    ctx.shadowBlur = 0; ctx.fillStyle = "#1b1238"; ctx.beginPath(); ctx.arc(x + o.w * 0.35, cy + 4 + p, 5, 0, 7); ctx.arc(x + o.w * 0.62, cy + 4 + p, 5, 0, 7); ctx.fill();
    ctx.strokeStyle = "rgba(180,120,255,.7)"; ctx.lineWidth = 4;     // ควันห้อยลงมาจากเพดาน
    ctx.beginPath(); ctx.moveTo(x + o.w * 0.3, 0); ctx.lineTo(x + o.w * 0.3, cy - 40); ctx.moveTo(x + o.w * 0.7, 0); ctx.lineTo(x + o.w * 0.7, cy - 40); ctx.stroke();
    ctx.restore();
  }
  function player(ctx, g, now) {
    const im = g.me; if (!im.complete || !im.naturalWidth) return;
    const sl = g.slide > 0 && g.y >= GY - 1, h = 112, w = h * im.naturalWidth / im.naturalHeight;
    if (g.inv > 0 && g.boost <= 0 && Math.floor(now / 90) % 2) ctx.globalAlpha = 0.4;
    const hp = g.hurt > 0 ? g.hurt / 0.6 : 0, hdy = hp ? -Math.abs(Math.sin((1 - hp) * Math.PI * 2.2)) * 30 * hp : 0, hdx = -16 * hp;     // เด้งถอยหลังตอนโดนชน
    ctx.save(); ctx.translate(PX + 34 + hdx, g.y + hdy);
    if (hp && Math.floor(now / 60) % 2) { try { ctx.filter = "brightness(2.6) saturate(.4)"; } catch (e) {} }
    if (g.boost > 0) { ctx.shadowColor = "#ffe27a"; ctx.shadowBlur = 26; }
    if (sl) { ctx.rotate(-1.25); ctx.translate(0, -w * 0.15); ctx.drawImage(im, -w / 2, -h * 0.78, w, h * 0.78); }
    else if (g.y < GY) { ctx.rotate(Math.max(-0.2, Math.min(0.2, g.vy / 5000))); ctx.drawImage(im, -w / 2, -h, w, h); }
    else { const b = Math.abs(Math.sin(g.anim)) * 7; ctx.rotate(Math.sin(g.anim) * 0.05); ctx.drawImage(im, -w / 2, -h - b + 4, w, h); }
    ctx.restore(); ctx.globalAlpha = 1; try { ctx.filter = "none"; } catch (e) {}
    if (g.shield) { ctx.save(); ctx.strokeStyle = "rgba(125,211,252,.9)"; ctx.fillStyle = "rgba(125,211,252,.18)"; ctx.lineWidth = 3; ctx.beginPath(); ctx.arc(PX + 34, g.y - 52, 62, 0, 7); ctx.fill(); ctx.stroke(); ctx.restore(); }
    // เงา
    ctx.fillStyle = "rgba(0,0,0,.3)"; const sh = 30 * (1 - Math.min(1, (GY - g.y) / 220) * 0.5); ctx.beginPath(); ctx.ellipse(PX + 34, GY + 3, sh, 6, 0, 0, 7); ctx.fill();
  }
  function hud(ctx, g) {
    ctx.save(); ctx.textBaseline = "middle";
    // แถบพลังชีวิต
    ctx.fillStyle = "rgba(10,5,30,.65)"; rr(ctx, 12, 12, 210, 26, 13); ctx.fill();
    const hpc = g.hp > 50 ? "#4fe3b0" : g.hp > 25 ? "#ffd75a" : "#ff6b81";
    ctx.fillStyle = hpc; rr(ctx, 15, 15, Math.max(8, 204 * g.hp / 100), 20, 10); ctx.fill();
    ctx.drawImage(img("icons/heart"), 8, 8, 32, 32);
    ctx.fillStyle = "#fff"; ctx.font = "700 14px Prompt, Sarabun, sans-serif"; ctx.textAlign = "left"; ctx.fillText(Math.ceil(g.hp), 46, 26);
    // คะแนน
    ctx.textAlign = "right"; ctx.font = "800 26px Prompt, Sarabun, sans-serif"; ctx.strokeStyle = "#1b1238"; ctx.lineWidth = 5;
    ctx.strokeText(score(g), W - 14, 26); ctx.fillStyle = "#ffe48a"; ctx.fillText(score(g), W - 14, 26);
    ctx.font = "700 14px Prompt, Sarabun, sans-serif"; ctx.fillStyle = "#fff"; ctx.strokeText(`${Math.floor(g.dist)} ม. · เหรียญ ${g.coins}`, W - 14, 52); ctx.fillText(`${Math.floor(g.dist)} ม. · เหรียญ ${g.coins}`, W - 14, 52);
    { let ey = 58; const eff = [g.shield && "🛡️ โล่พร้อม", g.slow > 0 && `⏳ ชะลอ ${g.slow.toFixed(1)}`, g.mag > 0 && `🧲 แม่เหล็ก ${g.mag.toFixed(1)}`, g.combo >= 5 && `🔥 คอมโบ x${g.combo}`].filter(Boolean);
      ctx.textAlign = "left"; ctx.font = "800 15px Prompt, Sarabun, sans-serif"; ctx.strokeStyle = "#1b1238"; ctx.lineWidth = 4;
      eff.forEach((t) => { ctx.strokeText(t, 14, ey + 14); ctx.fillStyle = "#fff"; ctx.fillText(t, 14, ey + 14); ey += 20; });
      if (g.boost > 0) { ctx.fillStyle = "#fff3a0"; ctx.strokeText(`⚡ บูสต์ ${g.boost.toFixed(1)}`, 14, ey + 14); ctx.fillText(`⚡ บูสต์ ${g.boost.toFixed(1)}`, 14, ey + 14); } }
    if (g.cd > 0) { ctx.textAlign = "center"; ctx.font = "800 96px Prompt, Sarabun, sans-serif"; ctx.strokeStyle = "#1b1238"; ctx.lineWidth = 10; const n = Math.ceil(g.cd); ctx.strokeText(n, W / 2, H / 2 - 20); ctx.fillStyle = "#ffe48a"; ctx.fillText(n, W / 2, H / 2 - 20); }
    ctx.restore();
  }
  function rr(ctx, x, y, w, h, r) { ctx.beginPath(); ctx.moveTo(x + r, y); ctx.arcTo(x + w, y, x + w, y + h, r); ctx.arcTo(x + w, y + h, x, y + h, r); ctx.arcTo(x, y + h, x, y, r); ctx.arcTo(x, y, x + w, y, r); ctx.closePath(); }

  /* ---------- จบเกม ---------- */
  async function end() {
    const g = S.g, secs = Math.round(g.time), sc = score(g);
    S.res = { score: sc, dist: Math.floor(g.dist), coins: g.coins, tiles: g.tiles, hits: g.hits, combo: g.bestCombo, secs, busy: true }; S.screen = "res"; paint();
    try {
      if (secs < 5) throw new Error("เล่นสั้นเกินไป ไม่นับรางวัล");
      const r = await rpc("run_submit", { p_token: tk(), p_score: sc, p_seconds: secs });
      S.res = { ...S.res, exp: r.exp, award: r.coins, capped: r.capped, no_reward: r.no_reward, busy: false }; await load();
      try { SFX.play(r.exp > 0 ? "levelup" : "click"); } catch (e) {}
    } catch (e) { S.res = { ...S.res, busy: false, err: e.message }; }
    if (GAMES.mode() === "run") { S.screen = "res"; paint(); }
  }
  const quit = () => { if (S.screen === "play" && !confirm("ออกจากเกม? จะไม่ได้รางวัลจากรอบนี้")) return; cancelAnimationFrame(S.raf); S.screen = "home"; S.g = null; GAMES.home(); };

  /* ---------- หน้าจอ ---------- */
  function view() {
    if (S.screen === "play") return playView();
    if (S.screen === "res") return resView();
    const s = S.st;
    return `<div class="card center run-home"><div class="gm-ico">🏃</div><h2 style="margin:4px 0">เคมีรัน <span class="pill" style="background:#2a7a5a">วิ่งเก็บเหรียญ</span></h2>
      <p class="muted">วิ่งให้ไกลที่สุด เก็บเหรียญและแผ่นธาตุให้ได้มากที่สุด</p>
      <div class="run-info">
        <section><h4>🎯 วิธีเล่น</h4><ul><li>เก็บเหรียญและแผ่นธาตุ</li><li>เก็บ ❤️ ยาแดงเติมพลังชีวิต (พลังลดลงเรื่อยๆ)</li><li>เก็บ ⭐ ดาว = บูสต์วิ่งทะลุ 4 วินาที</li><li>เหรียญติดกัน 10 เหรียญ = คอมโบ +3 HP</li></ul></section>
        <section><h4>⚠️ สิ่งที่ต้องระวัง</h4><ul><li>เตาไฟ · ชั้นหลอดทดลอง · เมฆพิษ</li><li>หยดกรดตกจากเพดาน (มีเครื่องหมายเตือน)</li><li>หลอดแก้วกลิ้งใส่ · ก๊าซพิษ · ลูกไฟฟ้าลอยขึ้นลง</li></ul></section>
        <section><h4>✨ ไอเทมพิเศษ</h4><ul><li>🛡️ โล่กันชน 1 ครั้ง</li><li>⏳ ชะลอเวลา</li><li>🧲 แม่เหล็กดูดเหรียญ</li></ul></section>
      </div>
      <div class="run-how"><div><b>⬆ กระโดด</b><small>แตะซ้ำ = กระโดด 2 ชั้น (ข้ามชั้นหลอดทดลอง)</small></div><div><b>⬇ สไลด์</b><small>ลอดใต้เมฆพิษ (กดค้างได้)</small></div></div>
      ${s ? `<div class="run-info"><section><h4>🏆 รางวัล</h4><ul><li>EXP สูงสุด <b>+${s.max_exp}</b> เมื่อได้ ${s.target} คะแนน</li><li>เล่นรับรางวัลแล้ว ${Math.min(s.plays, s.max_plays)}/${s.max_plays} รอบวันนี้</li>${s.best != null ? `<li>คะแนนดีที่สุด <b>${s.best}</b></li>` : ""}</ul></section></div>` : '<p class="muted">กำลังโหลด...</p>'}
      <div class="row" style="justify-content:center"><button class="btn gold" onclick="RUN.start()">▶ เริ่มวิ่ง</button><button class="btn ghost" onclick="GAMES.home()">กลับหน้าเกม</button></div></div>`;
  }
  function playView() {
    return `<div class="card run-card"><div class="row" style="margin-bottom:6px"><b class="grow">🏃 เคมีรัน</b><button class="btn ghost small" onclick="RUN.quit()">ออก</button></div>
      <div class="run-wrap"><canvas id="runcv" width="${W}" height="${H}" onpointerdown="RUN.jump()"></canvas></div>
      <div class="run-btns">
        <button class="run-b slide" onpointerdown="event.preventDefault();RUN.slide(true)" onpointerup="RUN.slide(false)" onpointerleave="RUN.slide(false)" onpointercancel="RUN.slide(false)" oncontextmenu="return false">⬇<small>สไลด์</small></button>
        <button class="run-b jump" onpointerdown="event.preventDefault();RUN.jump()" oncontextmenu="return false">⬆<small>กระโดด (ซ้อนได้)</small></button>
      </div><p class="muted center" style="margin:6px 0 0;font-size:.8rem">คีย์บอร์ด: Space/↑ กระโดด · ↓ สไลด์</p></div>`;
  }
  function resView() {
    const r = S.res;
    return `<div class="card center gm-res ${r.score >= (S.st ? S.st.target : 2500) ? "perfect" : ""}"><div style="font-size:54px">${r.score >= 2500 ? "🏅" : r.score >= 1000 ? "🎉" : "💪"}</div>
      <h2>${r.score} คะแนน</h2><p class="muted">วิ่งได้ ${r.dist} เมตร · เหรียญ ${r.coins} · แผ่นธาตุ ${r.tiles} · ชนอุปสรรค ${r.hits} ครั้ง · คอมโบสูงสุด ${r.combo || 0} · ${r.secs} วินาที</p>
      ${r.busy ? '<p class="muted">กำลังบันทึกผล...</p>' : r.err ? `<p class="tag no" style="display:inline-block">${esc(r.err)}</p>` : `<p>${r.no_reward ? '<span class="pill">ครบรอบที่ได้รางวัลของวันนี้แล้ว (เล่นฝึกได้ไม่จำกัด)</span>' : `ได้ <b style="color:var(--gold2)">+${r.exp} EXP</b>${r.award > 0 ? ` · +${r.award} 🪙` : ""}`}</p>
      ${r.capped && !r.no_reward ? '<p class="muted">EXP จากเกมวันนี้ถึงเพดานแล้ว</p>' : ""}`}
      <div class="row" style="justify-content:center"><button class="btn gold" ${r.busy ? "disabled" : ""} onclick="RUN.again()">วิ่งอีกครั้ง</button><button class="btn ghost" onclick="GAMES.home()">กลับหน้าเกม</button></div></div>`;
  }
  async function again() { try { S.st = await rpc("run_status", { p_token: tk() }); } catch (e) {} start(); }
  return { open, view, start, jump, slide, quit, again };
})();
