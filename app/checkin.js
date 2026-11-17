/* อีเว้นท์เช็คอินรับของรางวัล — ครูเปิดจากแท็บ 🎟️ เช็คอิน ในแอดมิน · นักเรียนกดรับได้คนละครั้งต่ออีเว้นท์ */
let CHK = [], CAMP = [], CHKBUSY = false;
function chkChips(g) {
  return [g.exp ? `⭐ +${g.exp} EXP` : "", g.coins ? `🪙 +${g.coins} เหรียญ` : "", g.pulls ? `🎟️ ตั๋วสุ่มฟรี ×${g.pulls}` : "",
    g.decor ? `${esc(g.decor_emoji || "🎨")} ${esc(g.decor)}` : "", g.card ? `${esc(g.card_emoji || "🃏")} การ์ด ${esc(g.card)}` : ""].filter(Boolean);
}
function chkLeft(iso) {
  const m = Math.max(0, Math.round((new Date(iso) - Date.now()) / 60000));
  return m >= 1440 ? `อีก ${Math.floor(m / 1440)} วัน` : m >= 60 ? `อีก ${Math.floor(m / 60)} ชม.` : `อีก ${m} นาที`;
}
function campPrize(m) {
  const t = chkChips({ exp: m.exp, coins: m.coins, pulls: m.pulls, decor: m.decor, card: m.card });
  if (m.set && m.set.length) t.push(`👑 ชุดลิมิเต็ด ${m.set.map((x) => (x.image ? `<img src="${esc(x.image)}" alt="" style="width:18px;height:18px;image-rendering:pixelated;vertical-align:-4px">` : esc(x.emoji || ""))).join("")}`);
  return t;
}
function campIcons(m) {   // ไอคอนรางวัลแบบย่อสำหรับช่องรายวัน
  const a = []; if (m.set && m.set.length) a.push("👑"); if (m.card) a.push("🃏"); if (m.decor) a.push("🎨"); if (m.pulls) a.push("🎟️"); if (m.coins) a.push("🪙"); if (m.exp) a.push("⭐");
  return a.slice(0, 3).join("");
}
function campHtml() {
  return (CAMP || []).map((c) => {
    const start = new Date(c.start_day + "T00:00:00"), chk = new Set(c.checked || []), td = c.today_date || "";
    const cells = Array.from({ length: c.days_total }, (_, i) => {
      const d = new Date(start); d.setDate(d.getDate() + i); const ds = d.toISOString ? `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}` : "";
      const done = chk.has(ds), isToday = ds === td, past = ds < td, ms = c.miles.filter((m) => m.need === i + 1);
      const setM = ms.find((m) => m.set && m.set.length), show = setM ? `<span class="chkshow">${setM.set.map((x) => (x.image ? `<img src="${esc(x.image)}" alt="${esc(x.name)}">` : esc(x.emoji || "👑"))).join("")}</span>` : "";
      const st = done ? "ok" : isToday ? "now" : past ? "miss" : "next", ico = done ? "✅" : isToday ? "⭐" : past ? "💤" : "🔒";
      const tip = ms.map((m) => `ครบ ${m.need} วัน: ` + campPrize(m).join(" ").replace(/<[^>]+>/g, "")).join(" | ");
      return `<div class="chkday ${st} ${ms.length ? "ms" : ""} ${setM ? "big" : ""}" data-d="${i + 1}" title="${esc(tip)}"><small>วัน ${i + 1}</small><span class="chkico">${show ? show : ico}</span><span class="chkpz">${ms.length ? (ms[0].got ? "🎁✔" : "🎁" + campIcons(ms[0])) : "&nbsp;"}</span></div>`;
    }).join("");
    const set = c.miles.find((m) => m.set && m.set.length), prizes = c.miles.map((m) => `<span class="ghchip ${m.got ? "gotchip" : ""}">${m.got ? "✅" : "🎁"} ${m.need} วัน: ${campPrize(m).join(" ")}</span>`).join("");
    return `<div class="card chkcard"><div class="row" style="align-items:center;gap:10px;flex-wrap:wrap"><div class="chkbig">🎟️</div>
      <div class="grow"><b>${esc(c.title)}</b> <small class="muted">· เช็คอินแล้ว ${c.done}/${c.days_total} วัน · เหลือ ${c.days_left + 1} วัน</small>${c.message ? `<div class="muted" style="font-size:.82rem">${esc(c.message)}</div>` : ""}</div>
      ${c.today ? `<span class="pill ok">✔ เช็คอินวันนี้แล้ว</span>` : `<button class="btn gold" onclick="campGo('${c.id}')">เช็คอินวันนี้</button>`}</div>
      <div class="chkrow">${cells}</div><div class="giftchips" style="margin-top:6px">${prizes}</div>${set ? `<div class="muted" style="font-size:.78rem;margin-top:4px">👑 ชุดลิมิเต็ด: ${set.set.map((x) => esc(x.name)).join(" · ")}</div>` : ""}</div>`;
  }).join("");
}
async function campGo(id) {
  if (CHKBUSY) return; CHKBUSY = true;
  try {
    const r = await rpc("camp_checkin", { p_token: tk(), p_camp: id });
    const rw = r.rewards || [];
    await chkStamp(r.done, rw.length > 0);
    const ov = document.createElement("div"); ov.id = "giftov"; ov.className = "giftov"; ov.setAttribute("role", "dialog"); ov.setAttribute("aria-modal", "true");
    ov.innerHTML = `<div class="giftbox"><div class="giftbig">🎟️</div><h2>เช็คอินวันที่ ${r.done}!</h2><p class="giftmsg">${esc(r.title)}</p>
      ${rw.length ? rw.map((m) => `<div class="giftitem"><b>🎉 ครบ ${m.need} วัน!</b><div class="giftchips">${campPrize({ exp: m.exp, coins: m.coins, pulls: m.pulls, decor: m.decor, card: m.card, set: (m.set || []).map((x) => ({ emoji: x.emoji })) }).map((c) => `<span class="ghchip">${c}</span>`).join("")}</div>${m.set ? `<div class="muted" style="font-size:.82rem">ได้ชุด: ${m.set.map((x) => esc(x.name)).join(" · ")}</div>` : ""}</div>`).join("") : `<p class="muted">สะสมต่อเนื่องไปเรื่อยๆ รางวัลใหญ่รออยู่!</p>`}
      <button class="btn gold" onclick="document.getElementById('giftov')?.remove();load()">ไปต่อ 🎉</button></div>`;
    document.body.appendChild(ov); try { FX.victory(); } catch (e) {} try { SFX.play(rw.length ? "levelup" : "coin"); } catch (e) {}
  } catch (e) { toast(e.message || "เช็คอินไม่สำเร็จ"); load(); }
  CHKBUSY = false;
}
function checkinHtml() {
  if (typeof PEEK !== "undefined" && PEEK) return "";
  return campHtml() + checkinOneHtml();
}
function checkinOneHtml() {
  const open = (CHK || []).filter((e) => !e.claimed);
  if (!open.length) return "";
  return open.map((e) => `<div class="card chkcard"><div class="row" style="align-items:center;gap:10px;flex-wrap:wrap"><div class="chkbig">🎟️</div>
    <div class="grow"><b>${esc(e.title)}</b> <small class="muted">· ${chkLeft(e.ends_at)}</small>${e.message ? `<div class="muted" style="font-size:.82rem">${esc(e.message)}</div>` : ""}
    <div class="giftchips" style="margin-top:4px">${chkChips(e).map((c) => `<span class="ghchip">${c}</span>`).join("")}</div></div>
    <button class="btn gold" onclick="chkClaim('${e.id}')">เช็คอินรับรางวัล</button></div></div>`).join("");
}
async function chkLoad() {
  if (typeof PEEK !== "undefined" && PEEK) return;
  try { CHK = (await rpc("checkin_list", { p_token: tk() })) || []; } catch (e) { CHK = []; }
  try { CAMP = (await rpc("camp_status", { p_token: tk() })) || []; } catch (e) { CAMP = []; }
}
async function chkClaim(id) {
  if (CHKBUSY) return; CHKBUSY = true;
  try {
    const r = await rpc("checkin_claim", { p_token: tk(), p_event: id });
    const chips = chkChips({ exp: r.exp, coins: r.coins, pulls: r.pulls, decor: r.decor, card: r.card });
    const ov = document.createElement("div"); ov.id = "giftov"; ov.className = "giftov"; ov.setAttribute("role", "dialog"); ov.setAttribute("aria-modal", "true");
    ov.innerHTML = `<div class="giftbox"><div class="giftbig">🎟️</div><h2>เช็คอินสำเร็จ!</h2><p class="giftmsg">${esc(r.title)}</p>
      <div class="giftitem"><div class="giftchips">${chips.map((c) => `<span class="ghchip">${c}</span>`).join("")}</div></div>
      <button class="btn gold" onclick="document.getElementById('giftov')?.remove();load()">รับรางวัล 🎉</button></div>`;
    document.body.appendChild(ov); try { FX.victory(); } catch (e) {} try { SFX.play("levelup"); } catch (e) {}
    CHK = CHK.map((x) => (x.id === id ? { ...x, claimed: true } : x));
  } catch (e) { toast(e.message || "รับไม่สำเร็จ"); load(); }
  CHKBUSY = false;
}

/* เอฟเฟกต์เช็คอิน: ตราประทับเด้งที่ช่องวันนี้ + ประกายกระจาย (ขั้นรางวัลได้ประกายทองมากกว่า) แล้วค่อยเด้งป๊อปอัป */
async function chkStamp(day, big) {
  try {
    if (window.matchMedia && matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const cell = document.querySelector(`.chkday[data-d="${day}"]`) || document.querySelector(".chkday.now");
    if (!cell) return;
    cell.classList.remove("now"); cell.classList.add("ok", "stamp");
    const ico = cell.querySelector(".chkico"); if (ico && !ico.querySelector(".chkshow")) ico.textContent = "✅";
    const r = cell.getBoundingClientRect(), n = big ? 26 : 14, cols = ["#ffd54a", "#ff9f43", "#fff3b0", "#5fd38a", "#7dd3fc"], box = document.createElement("div");
    box.className = "chkfx"; box.style.cssText = `left:${r.left + r.width / 2}px;top:${r.top + r.height / 2}px`;
    for (let i = 0; i < n; i++) {
      const a = (Math.PI * 2 * i) / n + Math.random() * 0.4, d = (big ? 70 : 46) + Math.random() * (big ? 70 : 34), p = document.createElement("i");
      p.style.cssText = `--dx:${Math.cos(a) * d}px;--dy:${Math.sin(a) * d - 10}px;background:${cols[i % cols.length]};animation-delay:${Math.random() * 0.08}s`;
      box.appendChild(p);
    }
    document.body.appendChild(box); try { SFX.play("coin"); } catch (e) {}
    await new Promise((res) => setTimeout(res, big ? 900 : 650));
    box.remove();
  } catch (e) {}
}
