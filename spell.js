/* มินิเกม: ห้องฝึกเวทย์ผสมธาตุ — แตะอะตอมใส่หม้อต้มให้ตรงสูตรสาร แล้วกด “ร่ายเวทย์” */
const SPELL = (() => {
  const SUB = "₀₁₂₃₄₅₆₇₈₉";
  const sub = (n) => (n > 1 ? String(n).replace(/\d/g, (d) => SUB[d]) : "");
  const fm = (a) => Object.entries(a).map(([k, v]) => k + sub(v)).join("");
  const EN = { H: "ไฮโดรเจน", He: "ฮีเลียม", C: "คาร์บอน", N: "ไนโตรเจน", O: "ออกซิเจน", F: "ฟลูออรีน", Na: "โซเดียม", Mg: "แมกนีเซียม", Al: "อะลูมิเนียม", Si: "ซิลิคอน", P: "ฟอสฟอรัส", S: "กำมะถัน", Cl: "คลอรีน", K: "โพแทสเซียม", Ca: "แคลเซียม", Fe: "เหล็ก", Cu: "ทองแดง", Zn: "สังกะสี", Mn: "แมงกานีส", I: "ไอโอดีน" };
  // [ชื่อเวทย์, ชื่อสาร, อะตอม]
  const R = {
    easy: [["เวทย์วารี", "น้ำ", { H: 2, O: 1 }], ["เวทย์เกลือ", "โซเดียมคลอไรด์", { Na: 1, Cl: 1 }], ["ลมหายใจมังกร", "คาร์บอนไดออกไซด์", { C: 1, O: 2 }],
      ["ไอหมอกกรด", "ไฮโดรเจนคลอไรด์", { H: 1, Cl: 1 }], ["แก๊สชีวิต", "ออกซิเจน", { O: 2 }], ["ลูกโป่งลอยฟ้า", "ไฮโดรเจน", { H: 2 }],
      ["ควันพิษเงียบ", "คาร์บอนมอนอกไซด์", { C: 1, O: 1 }], ["เปลวไฟเมทาโนส", "มีเทน", { C: 1, H: 4 }], ["กลิ่นแอมโมนิกา", "แอมโมเนีย", { N: 1, H: 3 }],
      ["ผงปูนเผา", "แคลเซียมออกไซด์", { Ca: 1, O: 1 }], ["ผงเมจิกขาว", "แมกนีเซียมออกไซด์", { Mg: 1, O: 1 }]],
    mid: [["ไฟสะเทินดำ", "โซเดียมไฮดรอกไซด์", { Na: 1, O: 1, H: 1 }], ["น้ำยาฟอกเวท", "ไฮโดรเจนเปอร์ออกไซด์", { H: 2, O: 2 }], ["ผงเกลือสองประกาย", "แคลเซียมคลอไรด์", { Ca: 1, Cl: 2 }],
      ["กลิ่นไข่เน่า", "ไฮโดรเจนซัลไฟด์", { H: 2, S: 1 }], ["ควันกำมะถัน", "ซัลเฟอร์ไดออกไซด์", { S: 1, O: 2 }], ["ผงฟูมหัศจรรย์", "โซเดียมไฮโดรเจนคาร์บอเนต", { Na: 1, H: 1, C: 1, O: 3 }],
      ["สนิมแดง", "เหล็ก(III)ออกไซด์", { Fe: 2, O: 3 }], ["เกราะอะลูมินา", "อะลูมิเนียมออกไซด์", { Al: 2, O: 3 }], ["ไอสีม่วง", "ไอโอดีนโมเลกุล", { I: 2 }],
      ["เลือดมังกรเขียว", "คอปเปอร์(II)ออกไซด์", { Cu: 1, O: 1 }], ["แก๊สหัวเราะ", "ไดไนโตรเจนมอนอกไซด์", { N: 2, O: 1 }]],
    hard: [["กรดแห่งอสูร", "กรดซัลฟิวริก", { H: 2, S: 1, O: 4 }], ["หินปูนโบราณ", "แคลเซียมคาร์บอเนต", { Ca: 1, C: 1, O: 3 }], ["น้ำกรดสลาย", "กรดไนตริก", { H: 1, N: 1, O: 3 }],
      ["น้ำหวานสวรรค์", "กลูโคส", { C: 6, H: 12, O: 6 }], ["สุราเวทย์", "เอทานอล", { C: 2, H: 6, O: 1 }], ["กรดเปรี้ยวนิรันดร์", "กรดแอซีติก", { C: 2, H: 4, O: 2 }],
      ["ผงม่วงชำระล้าง", "โพแทสเซียมเปอร์แมงกาเนต", { K: 1, Mn: 1, O: 4 }], ["ผลึกวิเศษสีฟ้า", "คอปเปอร์(II)ซัลเฟต", { Cu: 1, S: 1, O: 4 }], ["ปุ๋ยเทพ", "แอมโมเนียมไนเตรต", { N: 2, H: 4, O: 3 }],
      ["ผงฟอสฟอรัสสว่าง", "ไดฟอสฟอรัสเพนทอกไซด์", { P: 2, O: 5 }], ["ยาลดกรดเวท", "แมกนีเซียมไฮดรอกไซด์", { Mg: 1, O: 2, H: 2 }]],
  };
  const LV = { easy: { label: "ง่าย", n: 5, hint: "formula" }, mid: { label: "กลาง", n: 6, hint: "elems" }, hard: { label: "ยาก", n: 7, hint: "name" } };
  const ALL = Object.keys(EN);
  const S = { screen: "home", level: "mid", spells: [], i: 0, bowl: {}, wrong: 0, hints: 0, shown: false, t0: 0, msg: "", res: null, busy: false, pal: [], over: false };
  const shuffle = (a) => { a = a.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; };
  const paint = () => GAMES.paint();
  const cur = () => S.spells[S.i];
  const same = (a, b) => { const k = new Set([...Object.keys(a), ...Object.keys(b)]); for (const x of k) if ((a[x] || 0) !== (b[x] || 0)) return false; return true; };

  async function open() { S.screen = "home"; S.st = null; GAMES.setMode("spell"); paint(); try { S.st = await rpc("spell_status", { p_token: tk() }); } catch (e) {} paint(); }
  function start(level) {
    const L = LV[level]; S.level = level; S.spells = shuffle(R[level]).slice(0, L.n); S.i = 0; S.wrong = 0; S.hints = 0; S.over = false; S.busy = false;
    S.t0 = Date.now(); S.screen = "play"; S.msg = ""; setPal(); paint();
  }
  function setPal() {
    const s = cur(); S.bowl = {}; S.shown = false;
    const need = Object.keys(s[2]), decoy = shuffle(ALL.filter((x) => !need.includes(x))).slice(0, Math.max(2, 7 - need.length));
    S.pal = shuffle(need.concat(decoy));
  }
  function add(sym) { if (S.over || S.busy) return; S.bowl[sym] = (S.bowl[sym] || 0) + 1; S.msg = ""; paint(); const b = document.querySelector(".sp-pot"); if (b) FX.at(b, "collect-burst", { scale: 1.2 }); }
  function remove(sym) { if (S.over || S.busy) return; if (S.bowl[sym] > 1) S.bowl[sym]--; else delete S.bowl[sym]; paint(); }
  function clear() { if (S.busy) return; S.bowl = {}; S.msg = ""; paint(); }
  function hint() { if (S.shown || S.busy) return; S.shown = true; S.hints++; paint(); }
  async function cast() {
    if (S.over || S.busy || !Object.keys(S.bowl).length) return;
    const s = cur(), pot = document.querySelector(".sp-pot");
    if (same(S.bowl, s[2])) {
      S.busy = true; S.msg = "✨ ร่ายเวทย์สำเร็จ! " + s[1] + " (" + fm(s[2]) + ")"; paint();
      if (pot) { FX.at(pot, "mana-burst", { scale: 2 }); FX.at(pot, "power-star", { scale: 1.6 }); }
      setTimeout(async () => { S.i++; if (S.i >= S.spells.length) return finish(); setPal(); S.busy = false; paint(); }, 900);
    } else {
      S.wrong++; S.msg = "💥 สูตรยังไม่ถูก — หม้อระเบิดเบาๆ ลองปรับอะตอมใหม่"; paint();
      if (pot) FX.at(pot, "hit-spark", { scale: 1.8 });
    }
  }
  async function finish() {
    S.over = true; const n = S.spells.length, secs = Math.max(n * 2, Math.round((Date.now() - S.t0) / 1000));
    const score = Math.max(10, Math.min(100, Math.round(100 - S.wrong * 8 - S.hints * 6 - Math.max(0, secs - n * 18))));
    try {
      const r = await rpc("spell_submit", { p_token: tk(), p_score: score, p_spells: n, p_seconds: secs });
      S.res = { ...r, secs, wrong: S.wrong, hints: S.hints, level: S.level }; S.screen = "res"; await load();
      setTimeout(() => (score >= 90 ? FX.victory() : FX.screen("confetti", 0.5, 0.7, { scale: 3 })), 300);
    } catch (e) { toast(e.message); S.screen = "home"; }
    S.busy = false; go("game");
  }
  const quit = () => { if (S.screen === "play" && !confirm("ออกจากเกม? ความคืบหน้าจะไม่ถูกบันทึก")) return; S.screen = "home"; S.over = true; GAMES.home(); };

  function view() {
    if (S.screen === "play") return playView();
    if (S.screen === "res") return resView();
    const t = S.st;
    return `<div class="card center"><div class="gm-ico">🔮</div><h3>ห้องฝึกเวทย์ผสมธาตุ</h3>
      <p class="muted">คาถาแต่ละบทคือสารเคมี! แตะอะตอมใส่หม้อต้มให้ตรงสูตร แล้วกด “ร่ายเวทย์” · ยิ่งเร็วและผิดน้อย ยิ่งได้คะแนนสูง${t ? ` · สูงสุด +${t.max_exp} EXP/รอบ · ได้รางวัล ${t.max_plays} รอบ/วัน (เล่นแล้ว ${Math.min(t.plays, t.max_plays)}/${t.max_plays}${t.best != null ? ` · ดีที่สุด ${t.best}` : ""})` : ""}</p>
      <div class="row" style="justify-content:center">${Object.entries(LV).map(([k, l]) => `<button class="btn small ${k === "mid" ? "gold" : "ghost"}" onclick="SPELL.start('${k}')">${l.label} (${l.n} คาถา)</button>`).join("")}</div>
      <p class="muted" style="margin-top:8px">ง่าย: เห็นสูตร · กลาง: เห็นเฉพาะธาตุที่ใช้ · ยาก: เห็นแค่ชื่อสาร (ขอใบ้ได้ แต่หักคะแนน)</p>
      <button class="btn ghost small" onclick="GAMES.home()">กลับ</button></div>`;
  }
  function playView() {
    const s = cur(), L = LV[S.level], n = S.spells.length;
    const clue = L.hint === "formula" ? `สูตร: <b class="sp-f">${fm(s[2])}</b>` : L.hint === "elems" ? `ธาตุที่ใช้: ${Object.keys(s[2]).map((k) => `<b>${k}</b> (${EN[k]})`).join(" · ")}` : (S.shown ? `สูตร: <b class="sp-f">${fm(s[2])}</b>` : '<span class="muted">ใช้ความรู้ของคุณ! (กด 💡 เพื่อขอใบ้ −6 คะแนน)</span>');
    const bowl = Object.keys(S.bowl).length ? Object.entries(S.bowl).map(([k, v]) => `<button class="sp-atom" onclick="SPELL.remove('${k}')" title="แตะเพื่อเอาออก 1 ตัว">${k}<sup>×${v}</sup></button>`).join("") : '<span class="muted">หม้อยังว่างอยู่…</span>';
    return `<div class="card sp-play"><div class="row"><span class="pill">คาถาที่ ${Math.min(S.i + 1, n)}/${n}</span><span class="pill">ผิด ${S.wrong}</span><span class="grow"></span><button class="btn ghost small" onclick="SPELL.quit()">ออก</button></div>
      <div class="sp-scroll"><div class="sp-spell">📜 ${esc(s[0])}</div><div>จงผสมสาร: <b>${esc(s[1])}</b></div><div class="sp-clue">${clue}</div></div>
      <div class="sp-pot"><div class="sp-bowl">${bowl}</div><div class="sp-live">${Object.keys(S.bowl).length ? fm(S.bowl) : ""}</div></div>
      <p class="sp-msg">${S.msg}</p>
      <div class="sp-pal">${S.pal.map((k) => `<button class="sp-el" onclick="SPELL.add('${k}')"><b>${k}</b><small>${EN[k]}</small></button>`).join("")}</div>
      <div class="row" style="justify-content:center;margin-top:10px"><button class="btn ghost small" onclick="SPELL.clear()">🧹 ล้างหม้อ</button>
        ${L.hint === "name" ? `<button class="btn ghost small" ${S.shown ? "disabled" : ""} onclick="SPELL.hint()">💡 ใบ้</button>` : ""}
        <button class="btn gold" onclick="SPELL.cast()">🔮 ร่ายเวทย์</button></div></div>`;
  }
  function resView() {
    const r = S.res;
    return `<div class="card center gm-res ${r.score >= 90 ? "perfect" : ""}"><div style="font-size:54px">${r.score >= 90 ? "🧙‍♂️" : r.score >= 60 ? "🎉" : "💪"}</div>
      <h2>คะแนน ${r.score}/100</h2><p class="muted">ใช้เวลา ${r.secs} วินาที · ผิด ${r.wrong} ครั้ง · ขอใบ้ ${r.hints} ครั้ง</p>
      <p>${r.no_reward ? '<span class="pill">ครบรอบที่ได้รางวัลของวันนี้แล้ว (เล่นฝึกได้ไม่จำกัด)</span>' : `<span class="pill">+${r.exp} EXP</span> ${r.coins ? `<span class="pill">+${r.coins} 🪙</span>` : ""}`}</p>
      ${r.capped && !r.no_reward ? '<p class="muted">EXP จากเกมวันนี้ถึงเพดานแล้ว</p>' : ""}
      <div class="row" style="justify-content:center"><button class="btn gold" onclick="SPELL.start('${r.level}')">เล่นอีกครั้ง</button><button class="btn ghost" onclick="SPELL.open()">เมนูเวทย์</button><button class="btn ghost" onclick="GAMES.home()">กลับหน้าเกม</button></div></div>`;
  }
  return { open, view, start, add, remove, clear, hint, cast, quit };
})();
