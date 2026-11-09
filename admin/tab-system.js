/* แท็บ: system */
TAB.system = async function (v) {
  const LV = { ok: ["✅", "var(--mint)"], warn: ["⚠️", "var(--gold,#f6c453)"], bad: ["❌", "var(--red)"] };
  const lastBk = (() => { try { return localStorage.getItem("ch_last_backup") || ""; } catch (e) { return ""; } })();
  const days = lastBk ? Math.floor((Date.now() - new Date(lastBk).getTime()) / 864e5) : null;
  v.innerHTML = `<div class="card"><h3>🩺 ตรวจสุขภาพระบบ</h3><div id="hc" class="muted">กำลังตรวจ…</div>
    <div class="row" style="margin-top:8px"><button class="btn ghost small" id="hcRe">🔄 ตรวจอีกครั้ง</button><button class="btn ghost small" id="hcPurge">🧹 ล้างเซสชันเก่า</button></div></div>
    <div class="card"><h3>📊 สถิติเกมและรางวัล</h3><div class="row" style="margin-bottom:8px"><button class="btn small" data-d="7">7 วัน</button><button class="btn ghost small" data-d="30">30 วัน</button><button class="btn ghost small" data-d="90">90 วัน</button></div><div id="gst" class="muted">กำลังโหลด…</div></div>
    <div class="card"><h3>💾 สำรองข้อมูล</h3>
    <p class="muted">ข้อมูลทั้งหมดอยู่ที่ Supabase ที่เดียว แนะนำให้ดาวน์โหลดสำรองทุกสัปดาห์ (ไฟล์ .json ไม่มี PIN) เก็บไว้ใน Google Drive ของคุณเอง ห้ามอัปโหลดขึ้น GitHub เพราะมีข้อมูลนักเรียน</p>
    <p>${days === null ? '<span class="pill">ยังไม่เคยสำรองจากเครื่องนี้</span>' : days >= 7 ? `<span class="pill" style="background:#7a1020">⚠️ สำรองล่าสุด ${days} วันที่แล้ว — ถึงเวลาสำรองใหม่</span>` : `<span class="pill">✅ สำรองล่าสุด ${days === 0 ? "วันนี้" : days + " วันที่แล้ว"}</span>`}</p>
    <button class="btn gold" id="bk">⬇️ ดาวน์โหลดสำรองข้อมูลทั้งระบบ (.json)</button><div id="bkmsg" class="muted" style="margin-top:6px"></div></div>`;
  const draw = (r) => {
    $("#hc").innerHTML = `<div class="muted" style="margin-bottom:6px">ตรวจเมื่อ ${new Date(r.checked_at).toLocaleString("th-TH")}</div>` +
      r.items.map((i) => { const [ic, col] = LV[i.level] || LV.ok;
        return `<div style="display:flex;gap:8px;padding:6px 0;border-bottom:1px solid var(--line)"><span>${ic}</span><div class="grow"><div>${esc(i.label)}</div>${i.detail && i.level !== "ok" ? `<small class="muted">${esc(i.detail)}</small>` : ""}</div><b style="color:${col}">${i.count}</b></div>`; }).join("");
    const bad = r.items.filter((i) => i.level === "bad").length, warn = r.items.filter((i) => i.level === "warn").length;
    $("#hc").insertAdjacentHTML("afterbegin", `<div style="margin-bottom:8px;font-weight:700;color:${bad ? "var(--red)" : warn ? "var(--gold,#f6c453)" : "var(--mint)"}">${bad ? `พบปัญหา ${bad} รายการ` : warn ? `ควรดู ${warn} รายการ` : "ระบบปกติทุกข้อ"}</div>`);
  };
  const check = async () => { $("#hc").textContent = "กำลังตรวจ…"; try { draw(await rpc("health_check")); } catch (e) { $("#hc").innerHTML = `<span style="color:var(--red)">ตรวจไม่สำเร็จ: ${esc(e.message)}<br>ถ้าเพิ่งอัปเดต ให้รัน SQL 39_health.sql ก่อน</span>`; } };
  const stat = async (d) => {
    const box = $("#gst"); box.textContent = "กำลังโหลด…";
    try { const r = await rpc("game_stats", { p_days: d });
      const tot = r.sources.reduce((p, x) => p + (x.exp || 0), 0);
      box.innerHTML = `<div style="margin-bottom:6px">ย้อนหลัง ${r.days} วัน · นักเรียน ${r.students} คน · มีรางวัลเข้า ${r.active} คน (${r.students ? Math.round((r.active / r.students) * 100) : 0}%) · EXP แจกรวม <b>${tot}</b> · เหรียญที่ใช้จ่าย ${r.spent_coins} · รับของขวัญโปรแล้ว ${r.promo_claims} คน</div>
        <div class="scroll"><table><thead><tr><th>แหล่งรางวัล</th><th>ครั้ง</th><th>ผู้เล่น</th><th>EXP รวม</th><th>เฉลี่ย/ครั้ง</th><th>สัดส่วน</th><th>หมายเหตุ</th></tr></thead><tbody>${r.sources.map((x) => {
          const sh = Number(x.share_exp || 0), pl = r.students ? x.players / r.students : 0, notes = [];
          if (sh >= 40) notes.push("⚠️ แจกสัดส่วนสูง"); if ((x.avg_exp || 0) >= 40) notes.push("⚠️ รางวัล/ครั้งสูง"); if (pl < 0.1 && x.grants > 0) notes.push("ผู้เล่นน้อย");
          return `<tr><td>${esc(x.src)}</td><td>${x.grants}</td><td>${x.players}</td><td>${x.exp ?? 0}</td><td>${x.avg_exp ?? "—"}</td><td>${sh}%</td><td>${notes.join(" · ")}</td></tr>`; }).join("")}</tbody></table></div>
        <div class="muted" style="margin-top:6px">นับเฉพาะครั้งที่ได้รางวัลเข้าบัญชี · เกมที่ไม่ปรากฏในตารางแปลว่าไม่มีใครได้รางวัลในช่วงนี้ (อาจไม่มีคนเล่นหรือเกินเพดานรางวัลรายวัน)<br>5 อันดับ EXP สูงสุด: ${r.top_students.map((t) => esc(t.name) + " (" + esc(t.room || "—") + ") " + t.exp).join(" · ") || "—"}</div>`;
    } catch (e) { box.innerHTML = `<span style="color:var(--red)">โหลดไม่สำเร็จ: ${esc(e.message)}<br>ถ้าเพิ่งอัปเดต ให้รัน SQL 41_game_stats.sql ก่อน</span>`; }
  };
  v.querySelectorAll("[data-d]").forEach((b) => (b.onclick = () => { v.querySelectorAll("[data-d]").forEach((x) => x.classList.add("ghost")); b.classList.remove("ghost"); stat(Number(b.dataset.d)); }));
  stat(7);
  $("#hcRe").onclick = check;
  $("#hcPurge").onclick = async () => { const n = await run(() => rpc("admin_purge_sessions")); toast("ล้างเซสชันเก่า " + n + " รายการ"); check(); };
  check();
  const TABLES = [["classes", "*"], ["students", "id,class_id,no,name,avatar,exp,coins,gacha_pity,char_class,class_changes,decor,free_pulls,team_id,gender,is_gm,stat_pts,last_login,created_at"],
    ["ledger", "*"], ["score_items", "*"], ["scores", "*"], ["ch_attendance", "*"], ["ch_assignments", "*"], ["ch_submissions", "*"],
    ["quests", "*"], ["quest_claims", "*"], ["redemptions", "*"], ["privileges", "*"], ["inventory", "*"], ["student_achievements", "*"],
    ["gacha_pulls", "*"], ["game_plays", "*"], ["teams", "*"], ["board_posts", "*"], ["news_posts", "*"], ["timetable", "*"], ["app_settings", "*"], ["events", "*"]];
  $("#bk").onclick = async () => {
    const out = { exported_at: new Date().toISOString(), note: "ไม่รวม PIN ของนักเรียน", tables: {} }, msg = $("#bkmsg"); let fail = [];
    for (const [t, cols] of TABLES) {
      msg.textContent = "กำลังดึง " + t + "…"; const rows = []; let from = 0;
      try { for (;;) { const { data, error } = await sb.from(t).select(cols).range(from, from + 999); if (error) throw error; rows.push(...data); if (data.length < 1000) break; from += 1000; } out.tables[t] = rows; }
      catch (e) { fail.push(t); }
    }
    const blob = new Blob([JSON.stringify(out)], { type: "application/json" }), a = document.createElement("a");
    a.href = URL.createObjectURL(blob); a.download = "chemistria_backup_" + todayStr() + ".json"; a.click();
    try { localStorage.setItem("ch_last_backup", new Date().toISOString()); } catch (e) {}
    msg.innerHTML = "✅ ดาวน์โหลดแล้ว " + Object.keys(out.tables).length + " ตาราง, " + Object.values(out.tables).reduce((s, r) => s + r.length, 0) + " แถว" + (fail.length ? " · ดึงไม่สำเร็จ: " + fail.join(", ") : "")
      + '<div style="margin-top:8px"><button class="btn mint small" id="bkShare">📤 ส่งไปเก็บใน Google Drive (แชร์ไฟล์)</button><div class="muted" style="margin-top:4px">บนมือถือ: กดแล้วเลือก "Drive" · บนคอมพิวเตอร์: อัปโหลดไฟล์ที่ดาวน์โหลดไปที่ drive.google.com เอง</div></div>';
    const file = new File([blob], a.download, { type: "application/json" });
    $("#bkShare").onclick = async () => {
      try { if (navigator.canShare && navigator.canShare({ files: [file] })) { await navigator.share({ files: [file], title: "สำรองข้อมูล Chemistria" }); }
        else toast("เครื่องนี้แชร์ไฟล์ตรงไม่ได้ — ให้อัปโหลดไฟล์ที่ดาวน์โหลดไปที่ Google Drive เอง"); }
      catch (e) { if (e.name !== "AbortError") toast("แชร์ไม่สำเร็จ: " + e.message); }
    };
  };
};
