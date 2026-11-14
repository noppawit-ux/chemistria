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
