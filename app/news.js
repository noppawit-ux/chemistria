/* สไลด์ข่าว/อีเว้นท์ — ส่วนหนึ่งของหน้านักเรียน (index.html) โหลดต่อกันตามลำดับใน index.html */
/* ---------------- สไลด์ข่าว/อีเว้นท์ หน้าแรก ---------------- */
let NEWS_I = 0, NEWS_T = null;
function newsSlides() {
  const sl = [{ kind: "update", title: `อัปเดตใหม่ v${APP_VERSION}`, summary: PATCH.items.map((i) => i[1]).slice(0, 2).join(" · "), image: PATCH.img || "assets/patch-banner.jpg", act: "patchShow(true)" }];
  NEWS.forEach((n, i) => sl.push({ ...n, act: `newsOpen(${i})` }));
  return sl;
}
function newsHtml() {
  const sl = newsSlides(); if (!sl.length) return "";
  const lab = { update: "อัปเดต", news: "ข่าว", event: "อีเว้นท์" };
  return `<div class="card newscard"><div class="newshead">${ic("news")}<b>ข่าวสาร &amp; อีเว้นท์</b></div>
    <div class="newsc" id="newsc">${sl.map((n, i) => `<button class="newss" data-i="${i}" onclick="${n.act}" aria-label="${esc(n.title)}">
      <img src="${esc(n.image || "assets/patch-banner.jpg")}" alt="" loading="lazy" draggable="false" onerror="this.style.display='none'">
      <span class="newsg"></span><span class="newsk k-${n.kind}">${ic(n.kind === "event" ? "event" : "news")}${lab[n.kind] || "ข่าว"}</span>
      <span class="newst"><b>${esc(n.title)}</b><small>${esc(n.summary || "")}</small></span></button>`).join("")}</div>
    <div class="newsd" id="newsd">${sl.map((_, i) => `<i class="${i === 0 ? "on" : ""}" onclick="newsTo(${i})"></i>`).join("")}</div></div>`;
}
function newsTo(i) { const c = document.getElementById("newsc"); if (c) c.scrollTo({ left: c.clientWidth * i, behavior: "smooth" }); }
function newsInit() {
  clearInterval(NEWS_T); const c = document.getElementById("newsc"); if (!c) return;
  const n = c.children.length, dots = document.querySelectorAll("#newsd i");
  c.onscroll = () => { NEWS_I = Math.round(c.scrollLeft / c.clientWidth); dots.forEach((d, i) => d.classList.toggle("on", i === NEWS_I)); };
  if (n > 1 && !matchMedia("(prefers-reduced-motion: reduce)").matches) NEWS_T = setInterval(() => {
    if (document.hidden || tab !== "home" || document.getElementById("newsov")) return;
    newsTo((Math.round(c.scrollLeft / c.clientWidth) + 1) % n);
  }, 5000);
}
function newsOpen(i) {
  const n = NEWS[i]; if (!n) return;
  const d = (x) => x ? new Date(x + "T00:00:00").toLocaleDateString("th-TH", { day: "numeric", month: "short", year: "2-digit" }) : "";
  const when = n.starts_at || n.ends_at ? `<div class="muted" style="text-align:center">${ic("cal", "sm")} ${n.starts_at ? d(n.starts_at) : ""}${n.starts_at && n.ends_at ? " – " : n.ends_at ? "ถึง " : ""}${n.ends_at ? d(n.ends_at) : ""}</div>` : "";
  const ov = document.createElement("div"); ov.id = "newsov"; ov.className = "patchov-like"; ov.setAttribute("role", "dialog"); ov.setAttribute("aria-modal", "true");
  ov.innerHTML = `<div class="patchbox"><button class="patchx" aria-label="ปิด" onclick="newsClose()">✕</button>
    ${n.image ? `<div class="patchimgw"><img class="patchimg" src="${esc(n.image)}" alt="" onerror="this.parentNode.remove()"></div>` : ""}
    <div class="patchh">${ic(n.kind === "event" ? "event" : "news")} ${esc(n.title)}</div>${when}
    <div class="newsbody">${esc(n.body || n.summary || "").replace(/\n/g, "<br>")}</div>
    <div class="row" style="justify-content:center"><button class="btn gold" onclick="newsClose()">ปิด</button></div></div>`;
  ov.addEventListener("click", (e) => { if (e.target === ov) newsClose(); });
  document.body.appendChild(ov);
}
function newsClose() { document.getElementById("newsov")?.remove(); }
document.addEventListener("keydown", (e) => { if (e.key === "Escape") newsClose(); });
