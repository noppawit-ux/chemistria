/* แท็บ: guild — Mini Guild (ตั้งค่า · สุ่มจัดกิลด์ · จัดการกิลด์ · ขั้นรางวัล) */
TAB.guild = async function (v) {
  const KEYS = [["guild_reg_from", "เปิดรับสมัครกิลด์ (วันที่)", "date"], ["guild_start", "วันเริ่มกิจกรรม", "date"], ["guild_join_until", "ล็อกสมาชิกหลังวันที่", "date"], ["guild_end", "วันจบกิจกรรม", "date"],
    ["guild_hide_days", "ซ่อนอันดับกี่วันสุดท้าย", "number"], ["guild_min_members", "สมาชิกขั้นต่ำเพื่อติดอันดับ", "number"], ["guild_max_members", "สมาชิกสูงสุดต่อกิลด์", "number"],
    ["guild_gp_cap_day", "เพดานแต้มต่อคนต่อวัน", "number"], ["guild_min_personal_gp", "แต้มส่วนตัวขั้นต่ำเพื่อรับรางวัล", "number"], ["guild_room_bonus_coins", "โบนัสเหรียญกิลด์อันดับ 1 ของห้อง", "number"],
    ["guild_banned", "คำต้องห้ามในชื่อกิลด์ (คั่นด้วย ,)", "text"]];
  const cfg = Object.fromEntries(must(await sb.from("app_settings").select("key,value").like("key", "guild\\_%")).map((r) => [r.key, r.value]));
  const st = holder(v, "⚙️ ตั้งค่ากิจกรรม Mini Guild", "ระยะเวลา กติกา และเพดานแต้ม — เปลี่ยนแล้วมีผลทันที (แต้มคำนวณจากสมุดบัญชี EXP ในช่วงวันเริ่ม–จบ)");
  st.innerHTML = `<div class="grid2">${KEYS.map(([k, l, t]) => `<div class="field"><label>${l}</label><input data-k="${k}" type="${t}" value="${esc(cfg[k] ?? "")}"></div>`).join("")}</div><button class="btn gold" id="gsave">💾 บันทึกการตั้งค่า</button>`;
  $("#gsave", st).onclick = async () => { await run(async () => must(await sb.from("app_settings").upsert($$("[data-k]", st).map((i) => ({ key: i.dataset.k, value: i.value })))), "บันทึกแล้ว ✅"); TAB.guild(v.replaceChildren() || v); };

  /* ⚔️ Guild Battle (SQL 80) */
  const gbh = holder(v, "⚔️ Guild Battle — จับคู่กิลด์แข่งกดลูกศรตามจังหวะ", "สร้างรอบ → จับคู่ → นักเรียนเล่นเวลาไหนก็ได้ภายในช่วงเวลา · คะแนนกิลด์ = เฉลี่ย 3 คนที่ดีที่สุด · กิลด์ที่ไม่มีคู่สู้ผีกิลด์");
  let GL = null; try { GL = await rpc("admin_gb_list"); } catch (e) { gbh.innerHTML = `<span style="color:var(--red)">${esc(e.message)}<br>ถ้าเพิ่งอัปเดต ให้รัน SQL 80_guild_battle.sql ใน Supabase</span>`; }
  if (GL) {
    const reB = () => { v.innerHTML = ""; TAB.guild(v); };
    const stName = { soon: "เร็วๆ นี้", unpaired: "ยังไม่จับคู่", open: "🟢 เปิดแข่ง", counting: "⏳ นับคะแนน", final: "🏁 จบแล้ว" };
    const gopt = (GL.guilds || []).map((g) => `<option value="${g.id}">${esc(g.class)} · ${esc(g.name)}</option>`).join("");
    const sideT = (x) => x.ghost ? "👻 ผีกิลด์" : `${esc(x.name)} <b>${x.score}</b> <small class="muted">(เล่น ${x.played}/${x.size})</small>`;
    gbh.innerHTML = `<div class="grid2">${[["gbt", "ชื่อรอบ", "text", "รอบที่ 1"], ["gbb", "BPM (60–140)", "number", 100], ["gbn", "จำนวนโน้ต (16–80)", "number", 40], ["gbh", "เปิดกี่ชั่วโมง", "number", 48], ["gba", "เล่นได้กี่ครั้ง/คน", "number", 3],
        ["gbwc", "ชนะ: เหรียญ", "number", 40], ["gbwp", "ชนะ: ตั๋วกาชา", "number", 1], ["gblc", "แพ้/ร่วมแข่ง: เหรียญ", "number", 15], ["gbg", "คะแนนผีกิลด์ (0–1000)", "number", 600]]
      .map(([id, l, t, d]) => `<div class="field"><label>${l}</label><input id="${id}" type="${t}" value="${d}"></div>`).join("")}</div>
      <button class="btn gold" id="gbnew">➕ สร้างรอบใหม่ (สุ่มโน้ตให้)</button>
      ${(GL.rounds || []).map((r) => `<div style="padding:10px 0;border-top:1px solid var(--line)">
        <div class="row" style="gap:8px;align-items:center;flex-wrap:wrap"><b>${esc(r.title)}</b> <span class="pill">${stName[r.state] || r.state}</span>
          <span class="muted">${r.notes} โน้ต · ${r.bpm} BPM · ${r.attempts} ครั้ง · ถึง ${new Date(r.ends_at).toLocaleString("th-TH", { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" })} · ผู้เล่น ${r.players} คน · รับรางวัลแล้ว ${r.claims} คน</span>
          <span class="grow"></span>
          <button class="btn small" data-pair="${r.id}" data-m="rank">🎯 จับคู่ตามอันดับ</button><button class="btn small ghost" data-pair="${r.id}" data-m="random">🎲 สุ่มคู่</button>
          ${r.state === "open" || r.state === "unpaired" ? `<button class="btn small ghost" data-end="${r.id}">⏹ จบรอบเดี๋ยวนี้</button>` : ""}<button class="btn red small" data-del="${r.id}">ลบ</button></div>
        <div style="margin-top:6px">${(r.matches || []).length ? r.matches.map((m) => `<div class="row" style="gap:8px;padding:3px 0;align-items:center"><span>${sideT(m.a)}</span><b>VS</b><span>${sideT(m.b)}</span>
            ${m.result ? `<span class="pill">${m.result === "draw" ? "เสมอ" : m.result === "a" ? "ซ้ายชนะ" : "ขวาชนะ"}</span>` : ""}<button class="btn ghost small" data-dm="${m.id}">✕</button></div>`).join("")
          : '<span class="muted">ยังไม่มีคู่ — กด “จับคู่” (เฉพาะกิลด์ที่มีสมาชิกถึงเกณฑ์)</span>'}
          <div class="row" style="gap:6px;margin-top:6px;flex-wrap:wrap"><select data-ma="${r.id}" style="width:auto">${gopt}</select> VS <select data-mb="${r.id}" style="width:auto"><option value="">👻 ผีกิลด์</option>${gopt}</select><button class="btn small ghost" data-am="${r.id}">+ เพิ่ม/แก้คู่เอง</button></div></div></div>`).join("")}`;
    const val = (id) => $("#" + id, gbh).value;
    $("#gbnew", gbh).onclick = () => run(() => rpc("admin_gb_create", { p_title: val("gbt"), p_bpm: +val("gbb"), p_notes: +val("gbn"), p_hours: +val("gbh"), p_attempts: +val("gba"), p_win_coins: +val("gbwc"), p_win_pulls: +val("gbwp"), p_lose_coins: +val("gblc"), p_ghost: +val("gbg") }), "สร้างรอบแล้ว ✅").then(reB);
    $$("[data-pair]", gbh).forEach((b) => (b.onclick = () => run(async () => { const n = await rpc("admin_gb_pair", { p_round: b.dataset.pair, p_mode: b.dataset.m }); if (!n) throw new Error("ยังไม่มีกิลด์ที่มีสมาชิกถึงเกณฑ์"); }, "จับคู่แล้ว ✅").then(reB)));
    $$("[data-end]", gbh).forEach((b) => (b.onclick = () => confirm("จบรอบนี้เดี๋ยวนี้? (นักเรียนที่กำลังเล่นยังส่งคะแนนได้ภายใน 3 นาที)") && run(() => rpc("admin_gb_end", { p_round: b.dataset.end }), "จบรอบแล้ว").then(reB)));
    $$("[data-del]", gbh).forEach((b) => (b.onclick = () => confirm("ลบรอบนี้พร้อมคะแนนทั้งหมด? (เหรียญที่แจกไปแล้วไม่ถูกเรียกคืน)") && run(() => rpc("admin_gb_delete", { p_round: b.dataset.del }), "ลบแล้ว").then(reB)));
    $$("[data-dm]", gbh).forEach((b) => (b.onclick = () => run(() => rpc("admin_gb_del_match", { p_match: b.dataset.dm }), "ลบคู่แล้ว").then(reB)));
    $$("[data-am]", gbh).forEach((b) => (b.onclick = () => run(() => rpc("admin_gb_add_match", { p_round: b.dataset.am, p_a: $(`[data-ma="${b.dataset.am}"]`, gbh).value, p_b: $(`[data-mb="${b.dataset.am}"]`, gbh).value || null }), "บันทึกคู่แล้ว ✅").then(reB)));
  }

  let L; try { L = await rpc("admin_guild_list"); } catch (e) { holder(v, "🏰 กิลด์", `<span style="color:var(--red)">${esc(e.message)}<br>ถ้าเพิ่งอัปเดต ให้รัน SQL 45_guild.sql ก่อน</span>`); return; }
  const un = L.unassigned || [], tot = un.reduce((a, x) => a + x.n, 0);
  const rd = holder(v, "🎲 สุ่มจัดนักเรียนที่ยังไม่มีกิลด์", `ช่วง ${L.cfg.phase === "soon" || L.cfg.phase === "reg" ? "สมัครยังไม่ปิด — แนะนำสุ่มหลังวันล็อกสมาชิก" : "ตอนนี้"} · ระบบเติมกิลด์ที่ยังไม่ถึง 4 คนก่อน แล้วแบ่งกลุ่มใหม่ 4–5 คนในห้องเดียวกัน (ชื่อ “กิลด์ รหัสห้อง-เลข” หัวหน้าเปลี่ยนชื่อได้ 1 ครั้ง)`);
  rd.innerHTML = un.length ? un.map((x) => `<div class="row" style="justify-content:space-between;padding:4px 0"><span>${esc(x.class)}: ยังไม่มีกิลด์ <b>${x.n}</b> คน</span><button class="btn small" data-rc="${x.class_id}">🎲 สุ่มห้องนี้</button></div>`).join("") + `<button class="btn gold" id="rall" style="margin-top:8px">🎲 สุ่มทุกห้อง (${tot} คน)</button>` : '<span class="pill">✅ ทุกคนมีกิลด์แล้ว</span>';
  const doRand = async (id) => { if (!confirm("สุ่มจัดกิลด์ให้นักเรียนที่ยังไม่มีกิลด์? (ย้อนไม่ได้ แต่ครูย้ายคนได้ทีหลัง)")) return; const r = await run(() => rpc("admin_guild_random", { p_class: id }), "สุ่มจัดแล้ว ✅"); toast(`จัดนักเรียน ${r.assigned} คน สร้างกิลด์ใหม่ ${r.created} กิลด์`); v.innerHTML = ""; TAB.guild(v); };
  $$("[data-rc]", rd).forEach((b) => (b.onclick = () => doRand(b.dataset.rc))); $("#rall", rd) && ($("#rall", rd).onclick = () => doRand(null));

  const gh = holder(v, `🏰 กิลด์ทั้งหมด (${L.guilds.length})`, "เรียงตามอันดับรวม · ย้ายสมาชิกได้เฉพาะกิลด์ในห้องเดียวกัน · กิลด์ที่ไม่ครบขั้นต่ำจะไม่ติดอันดับ");
  const byClass = {}; L.guilds.forEach((g) => (byClass[g.class_id] ||= []).push(g));
  gh.innerHTML = L.guilds.length ? L.guilds.map((g) => `<div style="padding:8px 0;border-bottom:1px solid var(--line)">
      <div class="row" style="gap:8px;align-items:center;flex-wrap:wrap"><b>${g.rank ? "#" + g.rank : "—"}</b> <b>${esc(g.name)}</b> <span class="muted">${esc(g.class)} · ${g.size} คน · เฉลี่ย ${g.avg} · รวม ${g.total}${g.room_rank ? " · ห้อง #" + g.room_rank : ""}${g.auto ? " · สุ่มจัด" : ""}</span>
        <span class="grow"></span><button class="btn ghost small" data-rn="${g.id}">✏️ ชื่อ</button><button class="btn red small" data-dis="${g.id}">ยุบ</button></div>
      <div class="muted" style="margin-top:4px">${g.members.map((m) => `<span style="display:inline-block;margin:2px 8px 2px 0">${m.leader ? "👑" : ""}${esc(m.name)} (${m.gp}) <select data-mv="${m.id}" style="width:auto;padding:2px"><option value="">ย้าย…</option>${(byClass[g.class_id] || []).filter((o) => o.id !== g.id).map((o) => `<option value="${o.id}">→ ${esc(o.name)}</option>`).join("")}<option value="__none">(ออกจากกิลด์)</option></select></span>`).join("")}</div></div>`).join("") : '<span class="muted">ยังไม่มีกิลด์</span>';
  const re = () => { v.innerHTML = ""; TAB.guild(v); };
  $$("[data-rn]", gh).forEach((b) => (b.onclick = async () => { const n = prompt("ชื่อกิลด์ใหม่"); if (n) { await run(() => rpc("admin_guild_rename", { p_guild: b.dataset.rn, p_name: n }), "เปลี่ยนชื่อแล้ว"); re(); } }));
  $$("[data-dis]", gh).forEach((b) => (b.onclick = async () => { if (confirm("ยุบกิลด์นี้? สมาชิกจะกลายเป็นยังไม่มีกิลด์")) { await run(() => rpc("admin_guild_disband", { p_guild: b.dataset.dis }), "ยุบกิลด์แล้ว"); re(); } }));
  $$("[data-mv]", gh).forEach((s) => (s.onchange = async () => { if (!s.value) return; await run(() => rpc("admin_guild_move", { p_student: s.dataset.mv, p_guild: s.value === "__none" ? null : s.value }), "ย้ายแล้ว ✅"); re(); }));

  const th = holder(v, "🎁 ขั้นรางวัลของกิลด์", "เกณฑ์ = แต้มเฉลี่ยต่อคนของกิลด์ · สมาชิกแต่ละคนกดรับเองเมื่อแต้มส่วนตัวถึงเกณฑ์ · ตั้งตัวเลขหลังดู 📊 สถิติเกม (แท็บระบบ) เพื่อไม่ให้แจกเยอะเกิน");
  await crud(th, { table: "guild_tiers", order: "tier", defaults: { tier: 5, label: "", emoji: "🏅", min_avg: 800, coins: 0, pulls: 0, exp: 0 },
    cols: [{ k: "tier", label: "ขั้น", t: "number", w: 50 }, { k: "emoji", label: "ไอคอน", w: 50 }, { k: "label", label: "ชื่อ", w: 100 }, { k: "min_avg", label: "เฉลี่ย ≥", t: "number", w: 70 },
      { k: "coins", label: "เหรียญ", t: "number", w: 60 }, { k: "pulls", label: "ตั๋วกาชา", t: "number", w: 60 }, { k: "exp", label: "EXP", t: "number", w: 60 }] });
  const ph = holder(v, "🏆 รางวัลอันดับกิลด์ (หลังจบกิจกรรม)", "อันดับรวมทุกห้อง · ส่วนอันดับ 1 ของแต่ละห้องได้โบนัสเหรียญตามค่าด้านบน");
  await crud(ph, { table: "guild_prizes", order: "rank", defaults: { rank: 4, label: "", coins: 0, pulls: 0, exp: 0 },
    cols: [{ k: "rank", label: "อันดับ", t: "number", w: 60 }, { k: "label", label: "ชื่อรางวัล", w: 160 }, { k: "coins", label: "เหรียญ", t: "number", w: 60 }, { k: "pulls", label: "ตั๋วกาชา", t: "number", w: 60 }, { k: "exp", label: "EXP", t: "number", w: 60 }] });
  const qh = holder(v, "🎯 ภารกิจกิลด์ (ชุดเดียวทั้งอีเวนต์)", "เป้าหมาย = ต่อคน × จำนวนสมาชิก (ภารกิจ allplay = จำนวนวัน) · cap% = สัดส่วนสูงสุดที่ 1 คนช่วยได้ · MP = แต้มเต็มของภารกิจ · kind: correct/monster/attend/allplay");
  await crud(qh, { table: "guild_quests", order: "sort", defaults: { kind: "correct", title: "", emoji: "🎯", per_member: 10, mp: 100, cap_pct: 40, sort: 9, active: true },
    cols: [{ k: "kind", label: "ชนิด", t: "select", w: 80, opts: () => [["correct", "ตอบถูกรวม"], ["monster", "ล่ามอนสเตอร์"], ["attend", "เช็คชื่อ"], ["allplay", "เล่นครบทุกคน"]] }, { k: "emoji", label: "ไอคอน", w: 50 }, { k: "title", label: "ชื่อ", w: 140 },
      { k: "per_member", label: "ต่อคน", t: "number", w: 60 }, { k: "mp", label: "MP", t: "number", w: 60 }, { k: "cap_pct", label: "cap%", t: "number", w: 60 }, { k: "sort", label: "ลำดับ", t: "number", w: 50 }, { k: "active", label: "เปิด", t: "bool", w: 50 }] });
  const pt = holder(v, "🎁 รางวัลตามแถบ MP", "need_mp = MP รวมของกิลด์ที่ต้องถึง · รับได้เฉพาะคนที่ช่วยอย่างน้อย 1 ภารกิจ · อย่าให้ need_mp สูงกว่า MP รวมของทุกภารกิจ");
  await crud(pt, { table: "guild_pass_tiers", order: "tier", defaults: { tier: 7, need_mp: 450, label: "", emoji: "🏅", coins: 0, pulls: 0, exp: 0 },
    cols: [{ k: "tier", label: "ขั้น", t: "number", w: 50 }, { k: "emoji", label: "ไอคอน", w: 50 }, { k: "label", label: "ชื่อ", w: 100 }, { k: "need_mp", label: "MP ≥", t: "number", w: 70 },
      { k: "coins", label: "เหรียญ", t: "number", w: 60 }, { k: "pulls", label: "ตั๋วกาชา", t: "number", w: 60 }, { k: "exp", label: "EXP", t: "number", w: 60 }] });
};
