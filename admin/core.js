/* แกนกลางหน้าแอดมิน: สถานะ ตัวช่วย ล็อกอิน โครงหน้า เฝ้าระวังความปลอดภัย — แต่ละแท็บอยู่ในไฟล์ admin/tab-ชื่อ.js */
const app = $("#app");
const S = { classes: [], cls: null, tab: "students", attDate: todayStr(), asg: null, item: null };
const TABS = [
  ["all", "🏫 ทุกห้อง"], ["students", "👥 นักเรียน"], ["attend", "📋 เช็คชื่อ"], ["assign", "📝 งาน/การส่ง"], ["calendar", "📅 ปฏิทิน"],
  ["scores", "🧮 คะแนน"], ["quests", "🗺️ เควส"], ["gacha", "🎰 กาชา"], ["privs", "🎟️ สิทธิพิเศษ"],
  ["achv", "🏅 Achievement"], ["decor", "🎨 ตกแต่ง"], ["games", "🎮 มินิเกม"], ["teams", "🧪 ทีม"], ["boss", "👹 บอส"],
  ["board", "📢 บอร์ด"], ["news", "📣 ข่าว/อีเว้นท์"], ["timetable", "🕒 ตารางสอน"], ["digest", "📊 สรุปสัปดาห์"], ["export", "📤 ส่งออก Excel"], ["security", "🛡️ ความปลอดภัย"], ["system", "🩺 ระบบ/สำรองข้อมูล"], ["settings", "⚙️ ตั้งค่า"],
];
const clsName = () => S.classes.find((c) => c.id === S.cls)?.name || "";
const run = async (fn, ok) => { try { const r = await fn(); if (ok) toast(ok); return r; } catch (e) { toast(e.message); throw e; } };
const must = ({ data, error }) => { if (error) throw new Error(error.message); return data; };


/* ---------------- เฝ้าระวังความปลอดภัย: แบนเนอร์แจ้งเตือน + แจ้งเตือนเบราว์เซอร์ ---------------- */
const SEC = { last: -1, timer: null, scanAt: 0, sum: null };
const SEV = { critical: ["🚨", "#b3122a", "วิกฤต"], high: ["🔴", "#d1432f", "สูง"], warn: ["🟠", "#c98a14", "เตือน"], info: ["ℹ️", "#4a6fa5", "ข้อมูล"] };
async function secWatch(force) {
  clearTimeout(SEC.timer);
  const bar = $("#secbar"); if (!bar) return;
  try {
    if (force || Date.now() - SEC.scanAt > 10 * 60 * 1000) { SEC.scanAt = Date.now(); await rpc("security_scan"); }
    const r = SEC.sum = await rpc("security_summary");
    const n = (r.unseen || 0);
    const base = document.title.replace(/^🚨 \(\d+\) /, "");
    document.title = n ? `🚨 (${n}) ${base}` : base;
    if (r.lockdown) bar.innerHTML = `<div class="card" style="background:#7a4b00;color:#fff;margin-bottom:8px">🔒 <b>โหมดฉุกเฉินเปิดอยู่</b> — นักเรียนเข้าสู่ระบบไม่ได้ · <a href="#" id="secGo" style="color:#ffd">เปิดหน้าความปลอดภัย</a></div>`;
    else if (n) bar.innerHTML = `<div class="card" style="background:${r.critical ? "#b3122a" : "#d1432f"};color:#fff;margin-bottom:8px">🚨 <b>พบเหตุผิดปกติ ${n} รายการ${r.critical ? " (มีระดับวิกฤต)" : ""}</b> · <a href="#" id="secGo" style="color:#ffd">ดูรายละเอียด</a></div>`;
    else bar.innerHTML = "";
    $("#secGo") && ($("#secGo").onclick = (e) => { e.preventDefault(); S.tab = "security"; $$(".navgrid .tab").forEach((x) => x.classList.toggle("on", x.dataset.t === "security")); $("#navlbl").textContent = "🛡️ ความปลอดภัย"; renderTab(); });
    if (SEC.last >= 0 && n > SEC.last && "Notification" in window && Notification.permission === "granted") {
      try { new Notification("🚨 Chemistria: พบเหตุผิดปกติ", { body: `มีเหตุที่ยังไม่ได้ตรวจ ${n} รายการ${r.critical ? " (วิกฤต)" : ""}` }); } catch (e) {}
    }
    SEC.last = n;
  } catch (e) { /* ยังไม่ได้รัน SQL 42 หรือออฟไลน์: ไม่แสดงอะไร */ }
  SEC.timer = setTimeout(() => secWatch(), 60000);
}

/* ---------------- ล็อกอินครู ---------------- */
function showLogin(msg) {
  app.innerHTML = `<div class="login"><div class="card"><h2 class="center">🔐 แอดมินครูบุ๊ค</h2>
    ${msg ? `<p class="center" style="color:var(--red)">${esc(msg)}</p>` : ""}
    <div class="field"><label>อีเมล</label><input id="em" type="email" autocomplete="username"></div>
    <div class="field"><label>รหัสผ่าน</label><div style="position:relative"><input id="pw" type="password" autocomplete="current-password" style="padding-right:44px"><button type="button" id="eye" title="แสดง/ซ่อนรหัสผ่าน" style="position:absolute;right:6px;top:50%;transform:translateY(-50%);background:none;border:0;cursor:pointer;font-size:18px">👁</button></div></div>
    <button class="btn gold" style="width:100%" id="go">เข้าสู่ระบบ</button></div></div>`;
  const go = async () => {
    const { error } = await sb.auth.signInWithPassword({ email: $("#em").value.trim(), password: $("#pw").value });
    if (error) return toast("เข้าสู่ระบบไม่สำเร็จ: " + error.message);
    start();
  };
  $("#eye").onclick = () => { const p = $("#pw"); p.type = p.type === "password" ? "text" : "password"; p.focus(); };
  $("#go").onclick = go; $("#pw").addEventListener("keydown", (e) => { if (e.key === "Enter") go(); });
}

async function start() {
  const { data } = await sb.auth.getSession();
  if (!data.session) return showLogin();
  let ok = false;
  try { ok = await rpc("is_teacher"); } catch (e) {}
  if (!ok) { await sb.auth.signOut(); return showLogin("บัญชีนี้ไม่ได้อยู่ในรายชื่อครู (ตาราง teachers)"); }
  S.classes = must(await sb.from("classes").select("*").order("name"));
  S.cls ||= S.classes[0]?.id;
  shell();
}

function shell() {
  app.innerHTML = `
    <div class="row" style="margin-bottom:10px">
      <h2 class="grow" style="margin:0">⚗️ Chemistria · แอดมินครูบุ๊ค</h2>
      <select id="clsSel" style="width:auto">${S.classes.map((c) => `<option value="${c.id}" ${c.id === S.cls ? "selected" : ""}>${esc(c.name)} · ${esc(c.subject_code || "")}</option>`).join("")}</select>
      <a class="btn ghost small" href="index.html" target="_blank">หน้านักเรียน</a>
      <button class="btn ghost small" id="out">ออกจากระบบ</button></div>
    <div class="navwrap" id="nav"><div class="navbar"><button class="navbtn" id="navbtn">☰ <b id="navlbl">${esc((TABS.find((t) => t[0] === S.tab) || ["", ""])[1])}</b> <span class="car">▾</span></button></div>
      <div class="navgrid">${TABS.map(([k, l]) => `<button class="tab ${k === S.tab ? "on" : ""}" data-t="${k}">${l}</button>`).join("")}</div></div>
    <div id="secbar"></div>
    <div id="view"></div>`;
  $("#clsSel").onchange = (e) => { S.cls = e.target.value; S.asg = S.item = null; renderTab(); };
  $("#out").onclick = async () => { await sb.auth.signOut(); showLogin(); };
  $("#navbtn").onclick = () => $("#nav").classList.toggle("open");
  $$(".navgrid .tab").forEach((b) => (b.onclick = () => { S.tab = b.dataset.t; $$(".navgrid .tab").forEach((x) => x.classList.toggle("on", x === b)); $("#navlbl").textContent = b.textContent; $("#nav").classList.remove("open"); window.scrollTo({ top: 0 }); renderTab(); }));
  renderTab();
  secWatch();
}

async function renderTab() {
  const v = $("#view"); v.innerHTML = '<p class="muted">กำลังโหลด…</p>';
  v.onclick = v.onchange = null; // ล้างตัวจัดการของแท็บก่อนหน้า กันทำงานซ้อนกัน
  try { await TAB[S.tab](v); } catch (e) { v.innerHTML = `<div class="card" style="color:var(--red)">${esc(e.message)}</div>`; }
}

/* ---------------- ตัวช่วย CRUD แก้ไขได้ในตาราง ---------------- */
function cellInput(c, val, id) {
  const a = `data-id="${id}" data-k="${c.k}" data-t="${c.t || "text"}"`;
  if (c.t === "bool") return `<input type="checkbox" ${a} ${val ? "checked" : ""}>`;
  if (c.t === "select")
    return `<select ${a}>${c.opts().map(([v, l]) => `<option value="${esc(v)}" ${String(v) === String(val ?? "") ? "selected" : ""}>${esc(l)}</option>`).join("")}</select>`;
  if (c.t === "abil") { const s = Array.isArray(val) ? val.map((x) => [x.icon, x.name, x.desc].join("|")).join(" ;; ") : ""; return `<input type="text" ${a} value="${esc(s)}" placeholder="ไอคอน|ชื่อ|คำอธิบาย ;; อีกอัน" style="min-width:${c.w || 80}px">`; }
  const type = c.t === "number" ? "number" : c.t === "date" ? "date" : "text";
  return `<input type="${type}" ${c.t === "number" ? 'step="any"' : ""} value="${esc(val ?? "")}" ${a} style="min-width:${c.w || 80}px">`;
}
const conv = (el) => {
  const t = el.dataset.t;
  if (t === "bool") return el.checked;
  if (t === "number") return el.value === "" ? null : Number(el.value);
  if (t === "abil") { const l = el.value.split(";;").map((x) => x.split("|").map((y) => y.trim())).filter((p) => p[1]).map((p) => ({ icon: p[0] || "💥", name: p[1], desc: p[2] || "" })); return l.length ? l : null; }
  if (t === "date" || t === "select") return el.value === "" ? null : el.value;
  return el.value;
};

async function crud(host, { table, cols, filter = {}, defaults = {}, order, noDelete, addLabel = "เพิ่มรายการ" }) {
  let q = sb.from(table).select("*");
  for (const [k, v] of Object.entries(filter)) q = v === null ? q.is(k, null) : q.eq(k, v);
  if (order) q = q.order(order);
  const rows = must(await q);
  host.innerHTML = `<div class="scroll"><table><thead><tr>${cols.map((c) => `<th>${c.label}</th>`).join("")}<th></th></tr></thead>
    <tbody>${rows.map((r) => `<tr>${cols.map((c) => `<td>${cellInput(c, r[c.k], r.id)}</td>`).join("")}
      <td>${noDelete ? "" : `<button class="btn red small" data-del="${r.id}">ลบ</button>`}</td></tr>`).join("")}
    <tr style="background:#1b1238">${cols.map((c) => `<td>${cellInput(c, defaults[c.k] ?? (c.t === "bool" ? true : ""), "new")}</td>`).join("")}
      <td><button class="btn mint small" data-add="1">${addLabel}</button></td></tr></tbody></table></div>`;
  host.onchange = async (e) => {
    const el = e.target; if (!el.dataset.id || el.dataset.id === "new") return;
    await run(async () => must(await sb.from(table).update({ [el.dataset.k]: conv(el) }).eq("id", el.dataset.id)), "บันทึกแล้ว ✅");
  };
  host.onclick = async (e) => {
    const d = e.target.dataset;
    if (d.del) {
      if (!confirm("ลบรายการนี้? (ข้อมูลที่เกี่ยวข้องอาจถูกลบด้วย)")) return;
      await run(async () => must(await sb.from(table).delete().eq("id", d.del)), "ลบแล้ว");
      crud(host, arguments[1]);
    } else if (d.add) {
      const obj = { ...filter, ...defaults };
      $$('[data-id="new"]', host).forEach((el) => { const v = conv(el); if (v !== "" && v !== null) obj[el.dataset.k] = v; });
      await run(async () => must(await sb.from(table).insert(obj)), "เพิ่มแล้ว ✅");
      crud(host, arguments[1]);
    }
  };
}
const holder = (v, title, note = "") => {
  const c = document.createElement("div"); c.className = "card";
  c.innerHTML = `<h3>${title}</h3>${note ? `<p class="muted">${note}</p>` : ""}<div></div>`;
  v.appendChild(c); return c.lastElementChild;
};
const classOpts = (allLabel) => () => [["", allLabel], ...S.classes.map((c) => [c.id, c.name])];

/* ---------------- แต่ละแท็บ ---------------- */
const TAB = {};
