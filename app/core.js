/* แกนหน้านักเรียน: ตัวแปรกลาง ล็อกอิน — ส่วนหนึ่งของหน้านักเรียน (index.html) โหลดต่อกันตามลำดับใน index.html */
const TABS = [
  ["home", "🏠 หน้าหลัก"], ["att", "📋 เช็คชื่อ/งาน"], ["cal", "📅 ปฏิทิน"], ["score", "🧮 คะแนน"],
  ["class", "⚔️ คลาส"], ["decor", "🎨 ตกแต่ง"], ["game", "🎮 เกม"], ["quest", "🗺️ เควส"], ["gacha", "🎰 กาชา"], ["bag", "🎒 คลัง"], ["items", "🧪 ไอเทม"], ["cards", "📖 สมุดสะสม"], ["shop", "🛒 ร้านค้า"], ["rank", "🏆 อันดับ"], ["guild", "🏰 กิลด์"], ["board", "📢 บอร์ด"],
];
let PROMO = { active: false }, TT = [], NEWS = [], D = null, X = {}, B = { posts: [], unread: 0 }, NAVOPEN = false, HOF = [], DRAFT = null, decSlot = "outfit", tab = "home", calMonth = new Date(), calSel = todayStr();
const TOKEN_KEY = "kb_token";
/* โหมดส่องนักเรียน (ครูเปิดจากหน้าครู): ใช้โทเคนใน sessionStorage อ่านอย่างเดียว ไม่แตะ login จริง */
const PEEK = (() => { try { const m = location.hash.match(/peek=([0-9a-f-]{36})/); if (m) { sessionStorage.setItem("kb_peek", m[1]); history.replaceState(null, "", location.pathname); } return sessionStorage.getItem("kb_peek"); } catch (e) { return null; } })();
const PEEK_OK = ["guild_status", "guild_board", "student_dashboard", "student_extras", "hall_of_fame", "board_list", "celebrations_feed", "game_status", "spell_status", "kb_status", "run_status", "news_list", "timetable_list", "promo_status", "list_classes"];
if (PEEK) { const _r = rpc; rpc = async (n, a) => { if (!PEEK_OK.includes(n)) throw new Error("👁 โหมดส่องนักเรียน: ดูได้อย่างเดียว"); return _r(n, a); }; }
const app = $("#app");

/* ---------------- ล็อกอิน ---------------- */
async function showLogin(msg) {
  let classes = [];
  try { classes = (await rpc("list_classes")) || []; } catch (e) { msg = msg || e.message; }
  app.innerHTML = `
  <div class="login2">
    <div class="lg-orbs"><i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i></div>
    <div class="lg-sym"><span style="--i:0">H</span><span style="--i:1">C</span><span style="--i:2">O</span><span style="--i:3">N</span><span style="--i:4">Na</span><span style="--i:5">Fe</span></div>
    <div class="lg-cast">
      <img src="assets/avatars/alchemist.png" alt="" onerror="this.remove()"><img src="assets/avatars/scientist.png" alt="" onerror="this.remove()">
      <img class="kbstar" src="assets/chars/krubook.png" alt="ครูบุ๊ค" onerror="this.remove()">
      <img src="assets/avatars/guardian.png" alt="" onerror="this.remove()"><img src="assets/avatars/seeker.png" alt="" onerror="this.remove()">
    </div>
    <div class="lg-card">
      <div class="lg-logo"><img src="assets/icon/icon-192.png" alt="Chemistria" width="76" height="76"></div>
      <h1 class="lg-title">Chemistria</h1>
      <p class="lg-sub">ห้องเรียนเคมีผจญภัย · ครูบุ๊ค</p>
      ${msg ? `<p class="center" style="color:var(--red);margin:0 0 8px">${esc(msg)}</p>` : ""}
      <div class="lg-f"><span>🏫</span><select id="lc">${classes.map((c) => `<option value="${esc(c.code)}">${esc(c.name)} · ${esc(c.subject || "")}</option>`).join("")}</select></div>
      <div class="lg-f"><span>🎫</span><input id="ln" type="number" inputmode="numeric" min="1" placeholder="เลขที่"></div>
      <div class="lg-f"><span>🔑</span><input id="lp" type="password" inputmode="numeric" autocomplete="off" placeholder="PIN (ตัวเลข)"></div>
      <button class="btn gold lg-btn" id="lbtn">✨ เข้าสู่ห้องแล็บ</button>
      <p class="muted center" style="margin:12px 0 0;font-size:.8em">ครั้งแรกใช้ PIN ที่ครูแจก แล้วเปลี่ยนเองได้ในหน้า “หน้าหลัก”</p>
      <p class="center" style="margin:6px 0 0"><a href="#" id="gmlink" style="color:var(--muted,#9a8fc9);font-size:.75em;text-decoration:none">🛠️ ไอดี GM</a></p>
    </div>
  </div>`;
  const go = async () => {
    const btn = $("#lbtn"); btn.disabled = true;
    try {
      const r = await rpc("student_login", { p_class_code: $("#lc").value, p_no: Number($("#ln").value), p_pin: $("#lp").value });
      if (r.error) throw new Error(r.error);
      localStorage.setItem(TOKEN_KEY, r.token);
      await load();
    } catch (e) { toast(e.message); btn.disabled = false; }
  };
  $("#lbtn").onclick = go;
  setTimeout(() => { if (typeof FX === "undefined" || D || !$(".kbstar")) return; FX.at(".kbstar", "halo", { scale: 2, loop: true, dy: -40 }); FX.at(".lg-cast", "spirit-flame", { scale: 2, loop: true, dx: -150, foot: true }); FX.at(".lg-cast", "spirit-flame", { scale: 2, loop: true, dx: 150, foot: true }); }, 400);
  $("#gmlink").onclick = (e) => { e.preventDefault(); const sel = $("#lc"); if (![...sel.options].some((o) => o.value === "GM")) sel.add(new Option("🛠️ GM (ห้องทดสอบ)", "GM")); sel.value = "GM"; $("#ln").value = 1; $("#lp").focus(); };
  $("#lp").addEventListener("keydown", (e) => { if (e.key === "Enter") go(); });
}
