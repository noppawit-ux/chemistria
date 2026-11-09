/* บอร์ดและตัวเตือน — ส่วนหนึ่งของหน้านักเรียน (index.html) โหลดต่อกันตามลำดับใน index.html */
/* ---------------- บอร์ดกระดาน ---------------- */
async function markBoardSeen() { try { await rpc("board_mark_seen", { p_token: tk() }); B.unread = 0; const bg = document.querySelector("#nav .navgrid .bdg"); if (bg) bg.remove(); } catch (e) {} }
async function postBoard() {
  const t = $("#bt").value, b = $("#bb").value;
  try { await rpc("board_post", { p_token: tk(), p_title: t, p_body: b }); toast("โพสต์แล้ว ✅"); await load(); } catch (e) { toast(e.message); }
}
async function delBoard(id) {
  if (!confirm("ลบโพสต์นี้?")) return;
  try { await rpc("board_delete", { p_token: tk(), p_id: id }); toast("ลบแล้ว"); await load(); } catch (e) { toast(e.message); }
}
const ago = (iso) => { const m = Math.max(0, Math.round((Date.now() - new Date(iso)) / 60000)); return m < 1 ? "เมื่อสักครู่" : m < 60 ? m + " นาทีที่แล้ว" : m < 1440 ? Math.round(m / 60) + " ชม.ที่แล้ว" : Math.round(m / 1440) + " วันที่แล้ว"; };
function boardHtml() {
  return `<div class="card"><h3>✏️ โพสต์ในบอร์ดห้อง</h3>
    <input id="bt" maxlength="80" placeholder="หัวข้อ (ไม่ใส่ก็ได้)"><textarea id="bb" rows="3" maxlength="500" placeholder="พิมพ์ข้อความ… (ไม่เกิน 500 ตัวอักษร · โพสต์ได้วันละ 3 ครั้ง · ใช้ถ้อยคำสุภาพ)" style="margin-top:6px"></textarea>
    <button class="btn gold" style="margin-top:8px" onclick="postBoard()">📮 โพสต์</button></div>
    ${B.posts.map((p) => `<div class="card post ${p.author_kind} ${p.pinned ? "pin" : ""}">
      <div class="row"><b class="grow">${p.pinned ? "📌 " : ""}${p.author_kind === "teacher" ? "👨‍🏫 " : ""}${esc(p.author)}${p.all_classes ? ' <span class="tag late">ทุกห้อง</span>' : ""}</b>
        <span class="muted">${ago(p.created_at)}</span>${p.mine ? `<button class="btn ghost small" onclick="delBoard('${p.id}')">🗑️</button>` : ""}</div>
      ${p.title ? `<h3 style="margin:6px 0 2px">${esc(p.title)}</h3>` : ""}<div class="pbody">${esc(p.body).replace(/\n/g, "<br>")}</div></div>`).join("") || '<p class="muted">ยังไม่มีโพสต์</p>'}`;
}

const statusTag = (st) => ({
  present: '<span class="tag ok">มา</span>', late: '<span class="tag late">สาย</span>',
  absent: '<span class="tag no">ขาด</span>', leave: '<span class="tag leave">ลา</span>',
  submitted: '<span class="tag ok">ส่งแล้ว</span>', missing: '<span class="tag no">ไม่ส่ง</span>',
  pending: '<span class="tag wait">รอครูตรวจ</span>', approved: '<span class="tag ok">สำเร็จ ✔</span>',
  rejected: '<span class="tag no">ไม่ผ่าน</span>',
}[st] || "");

/* หอเกียรติยศ: Top 3 ของห้องตัวเอง (ตัวละครเต็มตัว) */
function hallHtml() {
  const r = (HOF || [])[0]; if (!r) return "";
  const pod = (x, place) => !x ? '<div class="pod empty"></div>' : `<div class="pod p${place}">
      ${place === 1 ? '<div class="crown">👑</div>' : ""}${stage(x.char_class, x.rank_info, x.decor, place === 1 ? "md" : "sm")}
      <div class="pn ${x.me ? "me" : ""}">${esc(x.name)}</div>${titleTag(x.decor)}
      <div class="muted" style="color:var(--rc)" ><span class="rk-${x.rank_info.key}">${esc(rankName(x.rank_info))}</span></div>
      <div class="muted">Lv.${x.level} · ${x.exp} EXP</div><div class="base">${place}</div></div>`;
  return `<div class="card hof"><h3>🏆 หอเกียรติยศ ${esc(r.name)}</h3>
    <div class="podium">${pod(r.top[1], 2)}${pod(r.top[0], 1)}${pod(r.top[2], 3)}</div></div>`;
}

/* ---------------- ตัวเตือนงาน · ทีม · บอส ---------------- */
const dayDiff = (d) => Math.round((new Date(String(d).slice(0, 10) + "T00:00:00") - new Date(todayStr() + "T00:00:00")) / 86400000);
const subInfo = (id) => (X.submit || {})[id] || {};
const canSubmit = (a) => ["online", "photo"].includes(subInfo(a.id).mode) && (!a.status || a.status === "missing");
function submitBtn(a) {
  const m = subInfo(a.id).mode;
  if (!canSubmit(a)) return "";
  if (m === "photo") return `<label class="btn small mint" style="cursor:pointer">📷 ส่งรูปงาน<input type="file" accept="image/*" hidden onchange="submitPhoto('${a.id}',this)"></label>`;
  return `<button class="btn small mint" onclick="submitOnline('${a.id}','${esc(a.title).replace(/'/g, "")}')">ส่งงาน ✔</button>`;
}
