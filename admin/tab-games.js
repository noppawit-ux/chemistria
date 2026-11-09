/* แท็บ: games */
TAB.games = async function (v) {
  const set = Object.fromEntries(must(await sb.from("app_settings").select("*")).map((x) => [x.key, x.value]));
  const f = [["game_daily_cap_exp", "เพดาน EXP จากมินิเกมต่อวัน", 40], ["quiz_count", "จำนวนข้อควิซประจำวัน", 5], ["quiz_exp_per_correct", "EXP ต่อข้อที่ตอบถูก", 4],
    ["quiz_perfect_bonus", "โบนัส EXP เมื่อถูกทุกข้อ", 5], ["battle_rewards_per_day", "รอบต่อสู้มอนสเตอร์ที่ได้รางวัลต่อวัน", 3], ["duel_rewards_per_day", "รอบท้าดวลเพื่อนที่ได้รางวัลต่อวัน", 5], ["celebrate_enabled", "ประกาศ popup แสดงความยินดีเมื่อมีคนได้ SSR/เลื่อนแรงค์ (1=เปิด, 0=ปิด)", 1], ["allow_student_photo", "ให้นักเรียนอัปโหลดรูปโปรไฟล์เอง (1=เปิด, 0=ปิด)", 1], ["spell_max_exp", "EXP สูงสุดต่อรอบห้องฝึกเวทย์ผสมธาตุ", 10], ["spell_plays_per_day", "จำนวนรอบเวทย์ผสมธาตุที่ได้รางวัลต่อวัน", 3], ["kb_plays_per_day", "รอบประลองครูบุ๊คที่ได้รางวัลต่อวัน", 2], ["kb_exp_per_round", "EXP ต่อรอบที่ผ่าน (ประลองครูบุ๊ค)", 1], ["kb_win_exp", "EXP โบนัสเมื่อชนะครูบุ๊ค", 6], ["kb_win_coins", "เหรียญเมื่อชนะครูบุ๊ค", 5], ["match_max_exp", "EXP สูงสุดต่อรอบเกมจับคู่ธาตุ", 10], ["match_plays_per_day", "จำนวนรอบจับคู่ที่ได้รางวัลต่อวัน", 3]];
  const day = todayStr();
  const plays = must(await sb.from("game_plays").select("game,student_id,exp,students(class_id)").eq("play_date", day));
  const mine = plays.filter((p) => p.students?.class_id === S.cls);
  const q = new Set(mine.filter((p) => p.game === "quiz").map((p) => p.student_id)).size;
  const m = new Set(mine.filter((p) => p.game === "match").map((p) => p.student_id)).size;
  v.innerHTML = `<div class="card"><h3>🎮 ตั้งค่ามินิเกม</h3>
    <p class="muted">วันนี้ห้อง ${esc(clsName())}: ทำควิซแล้ว <b>${q}</b> คน · เล่นจับคู่ธาตุแล้ว <b>${m}</b> คน (ระบบตรวจคำตอบและจำกัด EXP ที่เซิร์ฟเวอร์)</p>
    <div class="row">${f.map(([k, l, d]) => `<div style="width:230px"><label>${l}</label><input type="number" data-set="${k}" value="${esc(set[k] ?? d)}"></div>`).join("")}</div></div>`;
  v.onchange = async (e) => { const k = e.target.dataset.set; if (!k) return;
    await run(async () => must(await sb.from("app_settings").upsert({ key: k, value: String(e.target.value) })), "บันทึกแล้ว ✅"); };
  const cl = must(await sb.from("classes").select("id,quiz_topic").eq("id", S.cls))[0];
  const allQ = must(await sb.from("quiz_questions").select("topic"));
  const topics = [...new Set(allQ.map((q) => q.topic))];
  const tp = holder(v, "📚 ควิซตามบทเรียน", `ตั้ง “บทที่กำลังเรียน” ของห้อง ${esc(clsName())} → ควิซประจำวันจะดึงข้อของบทนี้ก่อน (ถ้าข้อไม่พอจะเติมจากข้อทั่วไป) · ว่าง = สุ่มจากทุกหัวข้อ`);
  tp.innerHTML = `<div class="row"><div style="width:260px"><label>บทที่กำลังเรียน (หัวข้อ)</label><input id="qtopic" list="tplist" value="${esc(cl?.quiz_topic || "")}" placeholder="เช่น โมล"><datalist id="tplist">${topics.map((t) => `<option value="${esc(t)}">`).join("")}</datalist></div>
    <button class="btn gold" id="saveTopic">บันทึก</button></div>
    <h4>เพิ่มคำถามหลายข้อพร้อมกัน (วางจาก Excel/ข้อความได้)</h4>
    <p class="muted">บรรทัดละข้อ คั่นด้วย | หรือแท็บ: <code>คำถาม | ก | ข | ค | ง | ข้อที่ถูก (ก/ข/ค/ง หรือ 1-4) | คำอธิบายเฉลย(ไม่บังคับ)</code></p>
    <div class="row"><div style="width:200px"><label>หัวข้อ/บท</label><input id="bTopic" list="tplist" placeholder="เช่น โมล"></div>
      <div style="width:200px"><label>ใช้กับห้อง</label><select id="bClass">${classOpts("ทุกห้อง")().map(([v2, l]) => `<option value="${esc(v2)}" ${v2 === S.cls ? "selected" : ""}>${esc(l)}</option>`).join("")}</select></div></div>
    <textarea id="bulkQ" rows="6" placeholder="1 โมลของ H2O หนักกี่กรัม | 16 | 18 | 20 | 32 | ข | มวลโมเลกุลของน้ำ = 18"></textarea>
    <button class="btn mint" id="addBulk" style="margin-top:8px">เพิ่มคำถาม</button>`;
  $("#saveTopic").onclick = () => run(async () => must(await sb.from("classes").update({ quiz_topic: $("#qtopic").value.trim() || null }).eq("id", S.cls)), "บันทึกบทที่กำลังเรียนแล้ว ✅");
  $("#addBulk").onclick = async () => {
    const topic = $("#bTopic").value.trim() || "ทั่วไป", cls = $("#bClass").value || null, rows = [];
    for (const line of $("#bulkQ").value.split("\n")) {
      const c = line.split(/\t|\|/).map((x) => x.trim()); if (c.length < 6) continue;
      const ans = "กขคง".indexOf(c[5][0]) >= 0 ? "กขคง".indexOf(c[5][0]) : Number(c[5]) - 1;
      if (!(ans >= 0 && ans <= 3)) continue;
      rows.push({ topic, class_id: cls, question: c[0].replace(/^\d+[.)]\s*/, ""), a: c[1], b: c[2], c: c[3], d: c[4], answer: ans, explain: c[6] || null, active: true });
    }
    if (!rows.length) return toast("ไม่พบบรรทัดที่อ่านได้ (ต้องมีอย่างน้อย 6 ช่อง)");
    await run(async () => must(await sb.from("quiz_questions").insert(rows)), `เพิ่มคำถาม ${rows.length} ข้อแล้ว ✅`); renderTab();
  };
  const h = holder(v, "🧠 คลังคำถามควิซ", "นักเรียนแต่ละคนได้ชุดคำถามสุ่มต่างกันในแต่ละวัน · เฉลยตรวจที่เซิร์ฟเวอร์ ไม่ถูกส่งไปที่เครื่องนักเรียนก่อนส่งคำตอบ · ปิดข้อที่ไม่ต้องการได้ด้วยช่อง “เปิด”");
  await crud(h, { table: "quiz_questions", order: "topic", defaults: { topic: "ทั่วไป", answer: 0, active: true },
    cols: [{ k: "topic", label: "หัวข้อ/บท", w: 90 }, { k: "class_id", label: "ห้อง", t: "select", opts: classOpts("ทุกห้อง") }, { k: "question", label: "คำถาม", w: 260 }, { k: "a", label: "ก.", w: 110 }, { k: "b", label: "ข.", w: 110 }, { k: "c", label: "ค.", w: 110 }, { k: "d", label: "ง.", w: 110 },
      { k: "answer", label: "ข้อที่ถูก", t: "select", opts: () => [["0", "ก"], ["1", "ข"], ["2", "ค"], ["3", "ง"]] }, { k: "explain", label: "คำอธิบายเฉลย", w: 220 }, { k: "active", label: "เปิด", t: "bool" }] });
  await TAB.kbBank(v);
  await TAB.monstersAdmin(v);
  const ha = holder(v, "🏟️ สนามต่อสู้", "ธีม: lab / ice / volcano / swamp / storm / crystal · ปลดล็อกตามเลเวล · โบนัสรางวัล % ใช้กับโหมดล่ามอนสเตอร์ · ผูกมอนสเตอร์กับสนามด้วย “รหัสสนาม” ในตารางด้านบน");
  await crud(ha, { table: "arenas", order: "sort", defaults: { emoji: "🏟️", theme: "lab", min_level: 1, reward_pct: 100, active: true, sort: 9 },
    cols: [{ k: "key", label: "รหัส", w: 80 }, { k: "name", label: "ชื่อสนาม", w: 150 }, { k: "emoji", label: "อีโมจิ", w: 50 }, { k: "theme", label: "ธีม", w: 80 }, { k: "descr", label: "คำอธิบาย", w: 220 },
      { k: "min_level", label: "เลเวลปลดล็อก", t: "number", w: 80 }, { k: "reward_pct", label: "รางวัล %", t: "number", w: 70 }, { k: "sort", label: "ลำดับ", t: "number", w: 50 }, { k: "active", label: "เปิด", t: "bool" }] });
};
