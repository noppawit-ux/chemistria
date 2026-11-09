/* ตัวช่วยภาพและวาดหน้า — ส่วนหนึ่งของหน้านักเรียน (index.html) โหลดต่อกันตามลำดับใน index.html */
/* ---------------- ตัวช่วยภาพ ---------------- */
const clsOf = (k) => (D?.classes || []).find((c) => c.key === k);
function avHtml(avatar, classKey) {
  if (avatar && (avatar.startsWith("assets/") || avatar.startsWith("data:image/"))) return `<img src="${esc(avatar)}" alt="">`;
  if ((!avatar || avatar === "🧪") && clsOf(classKey)?.image) return `<img src="${esc(clsOf(classKey).image)}" alt="">`;
  return esc(avatar || "🧪");
}
/* กรอบ/พื้นหลัง/หมวก/สัตว์เลี้ยง จากระบบตกแต่ง · sz: true=เล็ก, "md", "lg" */
const dcVar = (d) => (d && d.color ? `--dc:${esc(d.color)}` : "");
function frame(avatar, classKey, ri, lv, sz, dc) {
  dc = dc || {}; const f = dc.frame, b = dc.bg, size = sz === true ? "sm" : sz || "";
  return `<div class="avf rk-${ri.key} ${size} ${f ? "dc-f-" + esc(f.key) : ""}" style="${dcVar(f)}">
    <div class="av ${b ? "dc-b-" + esc(b.key) : ""}" style="${dcVar(b)}">${avHtml(avatar, classKey)}</div>
    ${dc.hat ? `<span class="dc-hat">${esc(dc.hat.emoji)}</span>` : ""}${dc.pet ? `<span class="dc-pet">${esc(dc.pet.emoji)}</span>` : ""}
    ${lv && !size ? `<span class="lv">Lv.${lv}</span>` : ""}</div>`;
}
const titleTag = (dc) => (dc && dc.title ? `<span class="pill dc-title">${esc(dc.title.emoji)} ${esc(dc.title.name)}</span>` : "");

/* ตัวละครเต็มตัว: ชุด + เอฟเฟค + ไอเทมลอย + หมวก + สัตว์เลี้ยง บนพื้นหลังและกรอบ · sz: "sm" | "md" | "lg" */
function fxHtml(fx) {
  if (!fx) return "";
  const n = fx.key === "orbit" || fx.key === "lightning" ? 4 : 11;
  let h = "";
  for (let k = 0; k < n; k++) h += `<i style="--x:${(k * 37 + 11) % 86 + 6}%;--sz:${3 + (k % 4) * 2}px;--t:${2.6 + (k % 5) * 0.6}s;--dl:-${(k * 0.55).toFixed(2)}s;--k:${k}"></i>`;
  return `<div class="fx fx-${esc(fx.key)}">${h}</div>`;
}
const GDEF = { novice: "m", alchemist: "m", scientist: "f", guardian: "m", seeker: "m" };   // เพศของภาพต้นฉบับแต่ละคลาส
const altGender = (cls, g) => !!g && g !== (GDEF[cls || "novice"] || "m");               // true = ใช้ภาพอีกเพศ (*_alt.png)
const gOf = (cls, dc) => (dc && dc.gender) || GDEF[cls || "novice"] || "m";
function stage(cls, ri, dc, sz) {
  dc = dc || {}; const f = dc.frame, b = dc.bg, o = dc.outfit, base = "assets/chars/" + (cls || "novice") + (altGender(cls, dc.gender) ? "_alt" : "");
  return `<div class="avf stg rk-${ri.key} ${sz || "md"} ${f ? "dc-f-" + esc(f.key) : ""}" style="${dcVar(f)}">
    <div class="av stage ${b ? "dc-b-" + esc(b.key) : "stg-default"}" style="${dcVar(b)}">
      ${fxHtml(dc.fx)}<div class="st-floor"></div>
      <img class="st-char" src="${base}${o ? "_" + esc(o.key) : ""}.png" alt="" onerror="this.onerror=null;this.src='${base}.png'">
      ${dc.hat ? (dc.hat.image ? `<img class="st-hat st-himg" src="${esc(dc.hat.image)}" alt="">` : `<span class="st-hat">${esc(dc.hat.emoji)}</span>`) : ""}${dc.pet ? (dc.pet.image ? `<img class="st-pet st-pimg" src="${esc(dc.pet.image)}" alt="">` : `<span class="st-pet">${esc(dc.pet.emoji)}</span>`) : ""}
      ${dc.item && dc.item.image ? `<img class="st-item" src="${esc(dc.item.image)}" alt="">` : ""}</div></div>`;
}
const itemImg = (img, emoji, cls = "ico") => img ? `<img class="${cls}" src="${esc(img)}" alt="">` : esc(emoji || "🎁");
const rankName = (ri) => ri.name + (ri.division ? " " + ri.division : "");

/* ---------------- วาดหน้า ---------------- */
function render() {
  document.body.dataset.tab = tab;
  const s = D.student, ri = D.rank_info, cls = clsOf(s.char_class);
  const span = s.exp_next_level - s.exp_this_level;
  const pct = Math.min(100, Math.round(((s.exp - s.exp_this_level) / span) * 100));
  const lp = ri.top ? "" : `<div class="lpbar"><i style="width:${ri.lp}%"></i></div>
      <div class="lvrow"><span>LP ${ri.lp} / ${ri.lp_max}</span><span>ถัดไป: ${esc(ri.next)} (EXP ${ri.exp_hi})</span></div>`;
  app.innerHTML = `
    <div class="card profile rk-${ri.key}">
      <div class="avwrap">${frame(s.avatar, s.char_class, ri, s.level, "", s.decor)}
        <label class="camb" title="อัปโหลด/ครอปรูปโปรไฟล์ของฉัน">📷<input type="file" accept="image/*" hidden onchange="photoOpen(this)"></label>
        ${(s.avatar || "").startsWith("data:image/") ? '<button class="camb rst" title="กลับไปใช้รูปเดิม" onclick="photoReset()">↺</button>' : ""}</div>
      <div class="grow">
        <h2 style="margin:0">${esc(s.name)} <span class="muted">เลขที่ ${s.no} · ${esc(D.class.name)}</span></h2>
        ${titleTag(s.decor)}
        <div class="row" style="margin:6px 0">
          ${cls ? `<span class="pill" style="color:var(--gold2);cursor:pointer" onclick="go('class')">${esc(cls.emoji)} ${esc(cls.name)}</span>`
                : `<button class="btn small gold" onclick="go('class')">⚔️ เลือกคลาส</button>`}
          <span class="coin">${ic("coin","sm")} ${s.coins}</span><span class="muted">EXP ${s.exp}</span>
        </div>
        <div class="lvrow"><b style="color:var(--text)">Lv.${s.level}</b><span>${s.exp - s.exp_this_level} / ${span} EXP ถึงเลเวล ${s.level + 1}</span></div>
        <div class="lvgauge"><i style="width:${pct}%"></i></div>
      </div>
      <div class="rankcard" style="flex-basis:100%">
        <img class="emb" src="${esc(ri.image)}" alt="${esc(ri.name)}" onerror="this.remove()">
        <div class="grow"><div class="rn">${esc(rankName(ri))}</div>${lp || `<div class="muted">แรงค์สูงสุด · LP ${ri.lp}</div>`}</div>
      </div>
    </div>
    <div class="navwrap ${NAVOPEN ? "open" : ""}" id="nav">
      <div class="hudbar rk-${ri.key}" aria-label="สถานะของฉัน">
        <span class="hc rank"><img src="${esc(ri.image)}" alt="" onerror="this.remove()"><b>${esc(rankName(ri))}</b></span>
        <span class="hc"><small>Lv</small><b>${s.level}</b></span>
        <span class="hc"><small>EXP</small><b>${s.exp}</b></span>
        <span class="hc coinc">${ic("coin", "sm")}<b>${s.coins}</b></span>
      </div>
      <div class="navbar">
        <button class="navbtn" onclick="toggleNav()">☰ <b>${tabHtml(TABS.find((t) => t[0] === tab) || ["home", ""])}</b> <span class="car">▾</span></button>
        <span class="grow"></span>
        <button class="bellbtn" onclick="openNotif()" aria-label="การแจ้งเตือน">${ic("bell")}${notifCount() ? `<i class="bdg">${notifCount()}</i>` : ""}</button>
      </div>
      <div class="navgrid">${TABS.map(([k, l]) => `<button class="tab ${k === tab ? "on" : ""}" onclick="go('${k}')">${tabHtml([k, l])}${k === "board" && B.unread ? `<i class="bdg">${B.unread}</i>` : ""}</button>`).join("")}</div>
    </div>
    <div id="view"></div>`;
  $("#view").innerHTML = VIEWS[tab]();
  newsInit();
}
const go = (k) => { tab = k; NAVOPEN = false; closeNotif(); render(); window.scrollTo({ top: 0 }); };
const toggleNav = () => { NAVOPEN = !NAVOPEN; $("#nav").classList.toggle("open", NAVOPEN); };
