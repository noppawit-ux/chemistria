/* แท็บ 💝 เพื่อน — ส่งของขวัญเพิ่มคะแนนความสัมพันธ์ (RP) · ปลดล็อกความสัมพันธ์ · แสดงบนหน้าหลัก */
let FR = null, FR_STALE = true, FR_BUSY = false;
async function friendsLoad() {
  if (FR_BUSY || (FR && !FR_STALE)) return;
  FR_BUSY = true;
  try { FR = await rpc("friend_list", { p_token: tk() }); } catch (e) { FR = { error: e.message }; }
  FR_STALE = false; FR_BUSY = false;
  if (tab === "friends") { const v = $("#view"); if (v) v.innerHTML = friendsHtml(); }
}
const frAct = (fn, msg) => act(async () => { const r = await fn(); FR_STALE = true; return r; }, msg);
const frNext = (rp) => (FR.types || []).find((t) => t.need_rp > rp);
const frPrev = (rp) => [...(FR.types || [])].reverse().find((t) => t.need_rp <= rp);
function frBar(rp) {
  const nx = frNext(rp), pv = frPrev(rp), a = pv ? pv.need_rp : 0;
  if (!nx) return `<div class="bar"><i style="width:100%"></i></div><small class="muted">RP ${rp} · ปลดล็อกครบทุกระดับแล้ว</small>`;
  const p = Math.min(100, Math.round(((rp - a) / (nx.need_rp - a)) * 100));
  return `<div class="bar"><i style="width:${p}%"></i></div><small class="muted">RP ${rp}/${nx.need_rp} → ปลดล็อก ${esc(nx.emoji)} ${esc(nx.name)}</small>`;
}
function friendsHtml() {
  if (!FR) return '<div class="card"><p class="muted">กำลังโหลด…</p></div>';
  if (FR.error) return `<div class="card"><h3>💝 เพื่อน</h3><p class="muted">${esc(FR.error)}</p></div>`;
  const inbox = (FR.inbox || []).map((g) => `<div class="item"><span style="font-size:24px">${esc(g.emoji)}</span><div class="grow"><b>${esc(g.from)}</b> ส่ง ${esc(g.name)} <small class="muted">+${g.points} RP</small>${g.msg ? `<div class="muted">“${esc(g.msg)}”</div>` : ""}</div>${g.seen ? "" : '<span class="tag wait">ใหม่</span>'}</div>`).join("") || '<p class="muted">ยังไม่มีของขวัญที่ได้รับ</p>';
  const mates = (FR.mates || []).map((m) => `<div class="card frrow" style="margin:6px 0">
      <div class="row" style="align-items:center;gap:8px"><b class="grow">${esc(m.name)} <small class="muted">เลขที่ ${m.no}</small></b>${m.rel ? `<span class="tag ok">${esc(m.rel_emoji)} ${esc(m.rel_name)}</span>` : ""}${m.pend ? `<span class="tag wait">${m.pend.by_me ? "รอเพื่อนตอบ" : "เพื่อนขอ"} ${esc(m.pend.emoji)}</span>` : ""}</div>
      ${frBar(m.rp)}
      <div class="row" style="gap:6px;margin-top:6px"><button class="btn small gold" onclick="giftOpen(${m.no})">🎁 ส่งของขวัญ</button><button class="btn small ghost" onclick="relOpen(${m.no})">💞 ความสัมพันธ์</button></div></div>`).join("") || '<p class="muted">ยังไม่มีเพื่อนในห้อง</p>';
  return `<div class="card"><h3>💝 เพื่อนและของขวัญ</h3><p class="muted" style="margin:0">ส่งของขวัญให้เพื่อนในห้อง → ได้คะแนนมิตรภาพ (RP) ร่วมกัน · ครบเกณฑ์ปลดล็อกความสัมพันธ์ แล้วเลือกได้ว่าจะเป็นอะไรกัน<br>
      วันนี้ส่งแล้ว <b>${FR.sent_today}/${FR.send_limit}</b> ชิ้น · RP ต่อคู่ไม่เกิน ${FR.pair_cap}/วัน · เหรียญ <b>${D.student.coins}</b> 🪙</p></div>
    <div class="card"><h3>🎁 ของขวัญที่ได้รับ</h3>${inbox}</div>
    <div class="card"><h3>👥 เพื่อนในห้อง</h3>${mates}</div>`;
}
function frModal(html) {
  eqClose();
  const ov = document.createElement("div"); ov.id = "eqov"; ov.setAttribute("role", "dialog");
  ov.innerHTML = `<div class="eqbox"><button class="patchx" aria-label="ปิด" onclick="eqClose()">✕</button>${html}</div>`;
  ov.addEventListener("click", (e) => { if (e.target === ov) eqClose(); });
  document.body.appendChild(ov);
}
let GIFT_PICK = null;
function giftOpen(no) {
  const m = (FR.mates || []).find((x) => x.no === no); if (!m) return; GIFT_PICK = null;
  frModal(`<h3>🎁 ส่งของขวัญให้ ${esc(m.name)}</h3><p class="muted" style="margin:0 0 6px">วันนี้ให้คู่นี้ได้อีก ${m.day_left} RP · เหรียญ ${D.student.coins} 🪙</p>
    <div class="eqgrid">${(FR.gifts || []).map((g) => `<button class="eqt rar-${esc(g.rarity)}" id="gp${g.id}" onclick="giftPick('${g.id}')"><span class="eqi">${esc(g.emoji)}</span><small><b>${esc(g.name)}</b><br>${g.price}🪙 · +${g.points} RP</small></button>`).join("")}</div>
    <input id="giftmsg" maxlength="60" placeholder="ข้อความถึงเพื่อน (ไม่บังคับ ไม่เกิน 60 ตัวอักษร)" style="width:100%;margin:4px 0 8px">
    <div class="row" style="justify-content:center"><button class="btn gold" onclick="giftSend(${no})">ส่งของขวัญ 💝</button></div>`);
}
const giftPick = (id) => { GIFT_PICK = id; document.querySelectorAll("#eqov .eqt").forEach((b) => b.classList.toggle("worn", b.id === "gp" + id)); };
function giftSend(no) {
  if (!GIFT_PICK) return toast("เลือกของขวัญก่อน");
  const g = (FR.gifts || []).find((x) => x.id === GIFT_PICK), msg = ($("#giftmsg") || {}).value || "";
  if (!confirm(`ส่ง ${g.name} (${g.price} เหรียญ) ?`)) return;
  eqClose();
  frAct(() => rpc("gift_send", { p_token: tk(), p_to_no: no, p_gift: GIFT_PICK, p_msg: msg }).then((r) => { toast(`ส่งให้ ${r.to} แล้ว +${r.points} RP 💝`); return r; }));
}
function relOpen(no) {
  const m = (FR.mates || []).find((x) => x.no === no); if (!m) return;
  const rows = (FR.types || []).map((t) => {
    const ok = m.rp >= t.need_rp, cur = m.rel === t.key;
    return `<div class="eqpick" style="opacity:${ok ? 1 : 0.5}"><span style="font-size:26px">${esc(t.emoji)}</span><div class="grow"><b>${esc(t.name)}</b><div class="muted" style="font-size:.85em">ต้องมี ${t.need_rp} RP</div></div>
      ${cur ? '<span class="tag ok">เป็นอยู่</span>' : ok ? `<button class="btn small gold" onclick="relPropose(${no},'${t.key}')">เสนอ</button>` : "🔒"}</div>`;
  }).join("");
  const pend = m.pend ? (m.pend.by_me ? `<div class="eqdet">รอ ${esc(m.name)} ตอบรับ “${esc(m.pend.emoji)} ${esc(m.pend.name)}” <button class="btn small ghost" onclick="relEnd(${no})">ยกเลิกคำขอ</button></div>`
    : `<div class="eqdet">${esc(m.name)} ขอเป็น “${esc(m.pend.emoji)} ${esc(m.pend.name)}” <button class="btn small gold" onclick="relRespond(${no},true)">ตกลง</button> <button class="btn small ghost" onclick="relRespond(${no},false)">ไม่เป็นไร</button></div>`) : "";
  frModal(`<h3>💞 ความสัมพันธ์กับ ${esc(m.name)}</h3><p class="muted" style="margin:0 0 6px">RP ตอนนี้ ${m.rp} · ฝ่ายหนึ่งเสนอ อีกฝ่ายต้องกดตกลงถึงจะเป็นกัน</p>${pend}${rows}
    ${m.rel ? `<div class="row" style="justify-content:center;margin-top:8px"><button class="btn small ghost" onclick="relEnd(${no})">เลิกความสัมพันธ์นี้ (คะแนนยังอยู่)</button></div>` : ""}`);
}
const relPropose = (no, k) => { eqClose(); frAct(() => rpc("rel_propose", { p_token: tk(), p_to_no: no, p_rel: k }).then((r) => { toast(`ส่งคำขอเป็น “${r.rel}” แล้ว รอเพื่อนตอบรับ`); return r; })); };
const relRespond = (no, ok) => { eqClose(); frAct(() => rpc("rel_respond", { p_token: tk(), p_from_no: no, p_accept: ok }).then((r) => { toast(ok ? "ตอบรับแล้ว 💞" : "ปฏิเสธแล้ว"); return r; })); };
const relEnd = (no) => { eqClose(); frAct(() => rpc("rel_end", { p_token: tk(), p_no: no }), "เรียบร้อย"); };
/* การ์ดบนหน้าหลัก */
function relHomeHtml() {
  const r = X.relations; if (!r) return "";
  const rels = r.rels || [], inc = r.incoming || [], ng = r.new_gifts || 0;
  if (!rels.length && !inc.length && !ng) return `<div class="card" style="padding:10px 14px"><div class="row" style="align-items:center;gap:8px"><span>💝</span><span class="grow muted">ส่งของขวัญให้เพื่อน สะสมคะแนนมิตรภาพ ปลดล็อกความสัมพันธ์</span><button class="btn small ghost" onclick="go('friends')">ไปดู</button></div></div>`;
  return `<div class="card relhome"><div class="row" style="align-items:center"><h3 class="grow" style="margin:0">💞 ความสัมพันธ์ของฉัน</h3><button class="btn small ghost" onclick="go('friends')">💝 เพื่อน</button></div>
    ${ng ? `<p style="margin:6px 0 0">🎁 ได้รับของขวัญใหม่ <b>${ng}</b> ชิ้น</p>` : ""}
    ${inc.map((i) => `<div class="row" style="gap:6px;align-items:center;margin-top:6px"><span class="grow"><b>${esc(i.name)}</b> ขอเป็น ${esc(i.rel_emoji)} ${esc(i.rel_name)}</span><button class="btn small gold" onclick="relHomeResp(${i.no},true)">ตกลง</button><button class="btn small ghost" onclick="relHomeResp(${i.no},false)">ไม่</button></div>`).join("")}
    <div class="relchips">${rels.map((x) => `<span class="relchip"><b>${esc(x.rel_emoji)}</b> ${esc(x.name)} <small>${esc(x.rel_name)}</small></span>`).join("")}</div></div>`;
}
const relHomeResp = (no, ok) => act(() => rpc("rel_respond", { p_token: tk(), p_from_no: no, p_accept: ok }).then((r) => { FR_STALE = true; return r; }), ok ? "ตอบรับแล้ว 💞" : "ปฏิเสธแล้ว");
VIEWS.friends = () => { friendsLoad(); return friendsHtml(); };
