/* สถิติท้ายเกม + สถิติที่ดีที่สุด — ใช้แสดงผลเท่านั้น (รางวัลยังคิดจากระบบเดิมฝั่งเซิร์ฟเวอร์) */
let GBEST = {};   // { game: { metric: best, plays, wins } } จาก game_bests_all
const GS_DEF = {   // [คีย์, ชื่อ, หน่วย, ทิศทาง max|min|sum]
  quiz: [["correct", "ตอบถูก", "ข้อ"], ["exp", "EXP", ""], ["secs", "เวลา", "วิ", "min"]],
  match: [["score", "คะแนน", ""], ["secs", "เวลา", "วิ", "min"], ["wrong", "ผิด", "ครั้ง", "min"]],
  spell: [["score", "คะแนน", ""], ["secs", "เวลา", "วิ", "min"], ["combo", "คอมโบ", ""], ["wrong", "ผิด", "ครั้ง", "min"], ["hints", "ขอใบ้", "ครั้ง", "min"]],
  kb: [["cleared", "ผ่านรอบ", "/8"], ["secs", "เวลา", "วิ", "min"], ["wins", "ชนะรวม", "ครั้ง", "sum"]],
  run: [["score", "คะแนน", ""], ["dist", "ระยะ", "ม."], ["secs", "เวลารอด", "วิ"], ["combo", "คอมโบ", ""], ["coins", "เหรียญ", ""]],
  battle: [["correct", "ตอบถูก", "ข้อ"], ["hp_left", "HP เหลือ", ""], ["turns", "จำนวนเทิร์น", "", "min"], ["wins", "ชนะรวม", "ครั้ง", "sum"]],
  duel: [["hp_left", "HP เหลือ", ""], ["rounds", "จบที่รอบ", "", "min"], ["wins", "ชนะรวม", "ครั้ง", "sum"]],
};
const gsFmt = (d, v) => (v == null ? "—" : `${Math.round(v * 10) / 10}${d[2] ? " " + d[2] : ""}`);
async function gsRecord(game, stats) {
  if (typeof PEEK !== "undefined" && PEEK) return null;
  try {
    const r = await rpc("game_record", { p_token: tk(), p_game: game, p_stats: stats });
    GBEST[game] = { ...(GBEST[game] || {}), ...r.best, plays: r.plays };
    return r;
  } catch (e) { return null; }
}
/* ตารางผลรอบนี้ เทียบกับสถิติดีที่สุด + ป้าย NEW BEST */
function gsCard(r) {
  if (!r || !r.cur) return "";
  const defs = (GS_DEF[r.game] || []).filter((d) => d[3] !== "sum" && r.cur[d[0]] != null), nb = new Set(r.newbest || []);
  if (!defs.length) return "";
  const any = !r.first && defs.some((d) => nb.has(d[0])), wins = (GS_DEF[r.game] || []).find((d) => d[3] === "sum");
  return `<div class="gscard"><div class="gshead">📊 สถิติ <span class="muted">เล่นแล้ว ${r.plays} ครั้ง${wins && r.best[wins[0]] != null ? ` · ${wins[1]} ${r.best[wins[0]]}` : ""}</span>
      ${r.first ? '<span class="gsnew">🆕 สถิติแรก</span>' : any ? '<span class="gsnew">🏅 NEW BEST!</span>' : ""}</div>
    <table><thead><tr><th></th><th>รอบนี้</th><th>ดีที่สุด</th></tr></thead><tbody>
    ${defs.map((d) => { const n = nb.has(d[0]) && !r.first; return `<tr class="${n ? "gsup" : ""}"><td>${d[1]}</td><td><b>${gsFmt(d, r.cur[d[0]])}</b></td><td>${gsFmt(d, r.best[d[0]])}${n ? " 🏅" : ""}</td></tr>`; }).join("")}
    </tbody></table></div>`;
}
/* บรรทัดสถิติดีที่สุดในหน้าหลักของแต่ละเกม */
function gsBest(game) {
  const b = GBEST[game]; if (!b || !b.plays) return "";
  const parts = (GS_DEF[game] || []).filter((d) => d[3] !== "sum" && b[d[0]] != null).slice(0, 3).map((d) => `${d[1]} ${gsFmt(d, b[d[0]])}`);
  const w = (GS_DEF[game] || []).find((d) => d[3] === "sum");
  if (w && b[w[0]]) parts.push(`${w[1]} ${b[w[0]]}`);
  return parts.length ? `<p class="gsbest">🏅 ดีที่สุด: ${parts.join(" · ")} <span class="muted">(เล่น ${b.plays} ครั้ง)</span></p>` : "";
}
