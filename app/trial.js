/* ด่านบอสเลื่อนแรงค์: EXP ถึงเกณฑ์แรงค์หลักแล้วต้องชนะบอสก่อนจึงเลื่อน (EXP ไม่หาย · แพ้ท้าใหม่ได้วันถัดไป) */
let TRIAL = null;
function trialBanner(ri) {
  if (!ri || !ri.locked) return "";
  return `<div class="trialban" onclick="trialOpen()" role="button" tabindex="0">
    <img src="${esc(ri.gate_image || "")}" alt="" onerror="this.remove()"><div class="grow"><b>ด่านเลื่อนแรงค์ ${esc(ri.gate_name)}</b>
    <div class="muted" style="font-size:.85em">EXP ถึงเกณฑ์แล้ว — ชนะบอสเพื่อเลื่อนแรงค์ (EXP ไม่หาย)</div></div><span class="btn small gold">⚔️ ท้าด่าน</span></div>`;
}
async function trialOpen() {
  eqClose();
  try { TRIAL = await rpc("rank_trial_status", { p_token: tk() }); } catch (e) { return toast(e.message); }
  const t = TRIAL;
  if (!t.gate) return toast("ตอนนี้ไม่มีด่านที่ต้องสอบ");
  const b = t.boss, img = b.image ? `<img class="trialboss" src="${esc(b.image)}" alt="">` : `<div class="trialboss emo">${esc(b.emoji || "👾")}</div>`;
  const ov = document.createElement("div"); ov.id = "eqov"; ov.setAttribute("role", "dialog");
  ov.innerHTML = `<div class="eqbox center"><button class="patchx" aria-label="ปิด" onclick="eqClose()">✕</button>
    <h3>🎖️ ด่านเลื่อนแรงค์ ${esc(t.gate.name)}</h3>${img}
    <h3 style="margin:4px 0">${esc(b.name)} <small class="muted">Lv.${b.level}</small></h3>
    <p style="margin:4px 0"><span class="pill">❤️ ${b.hp}</span> <span class="pill">🗡️ ${b.atk}</span> <span class="pill">🎁 +${t.reward_coins} 🪙</span></p>
    <p class="muted" style="margin:6px 0">ชนะบอสตัวนี้เพื่อเลื่อนเป็น <b>${esc(t.gate.name)}</b> · EXP ที่สะสมไว้ไม่หาย${t.extra > 0 ? ` (รออยู่ ${t.extra} EXP)` : ""}<br>แพ้หรือหนี = ท้าใหม่ได้พรุ่งนี้</p>
    ${t.can_start ? `<button class="btn gold" onclick="trialGo()">${t.active_trial ? "▶️ สู้ต่อ" : "⚔️ เริ่มท้าด่าน"}</button>`
      : '<button class="btn" disabled>🗓️ วันนี้สอบแล้ว — พรุ่งนี้มาใหม่</button>'}</div>`;
  ov.addEventListener("click", (e) => { if (e.target === ov) eqClose(); });
  document.body.appendChild(ov);
}
async function trialGo() {
  const name = TRIAL && TRIAL.gate ? TRIAL.gate.name : "";
  try { const bat = await rpc("rank_trial_start", { p_token: tk() }); eqClose(); go("game"); BATTLE.begin(bat, name); }
  catch (e) { toast(e.message); }
}
