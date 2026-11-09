/* แท็บ: teams */
TAB.teams = async function (v) {
  const h0 = holder(v, "🧪 ทีมแข่ง EXP", "สุ่มแบ่งทีมทั้งห้อง (ทีมเดิมของห้องนี้จะถูกแทนที่) หรือแก้ชื่อ/ย้ายสมาชิกด้านล่าง · นักเรียนเห็นอันดับทีมเรียงตาม EXP เฉลี่ยต่อคนของสัปดาห์นี้");
  h0.innerHTML = `<div class="row"><div style="width:140px"><label>จำนวนทีม</label><input id="nT" type="number" min="2" max="12" value="6"></div>
    <button class="btn gold" id="rndT">🎲 สุ่มแบ่งทีมทั้งห้อง</button></div>`;
  $("#rndT").onclick = async () => {
    if (!confirm("สุ่มแบ่งทีมใหม่ทั้งห้อง " + clsName() + " ?")) return;
    const n = await run(() => rpc("admin_random_teams", { p_class: S.cls, p_n: Number($("#nT").value) }), null);
    toast(`แบ่งทีมให้ ${n} คนแล้ว ✅`); renderTab();
  };
  const h1 = holder(v, "รายชื่อทีม");
  await crud(h1, { table: "teams", filter: { class_id: S.cls }, order: "sort", defaults: { emoji: "🧪", sort: 0 },
    cols: [{ k: "emoji", label: "ไอคอน", w: 50 }, { k: "name", label: "ชื่อทีม", w: 160 }, { k: "sort", label: "ลำดับ", t: "number", w: 60 }] });
  const teams = must(await sb.from("teams").select("id,name,emoji").eq("class_id", S.cls).order("sort"));
  const st = must(await sb.from("students").select("id,no,name,team_id").eq("class_id", S.cls).order("no"));
  const h2 = holder(v, "สมาชิกในทีม");
  h2.innerHTML = `<div class="scroll"><table><tbody>${st.map((s) => `<tr><td>${s.no}</td><td>${esc(s.name)}</td><td><select data-stid="${s.id}">
    <option value="">— ไม่มีทีม —</option>${teams.map((t) => `<option value="${t.id}" ${t.id === s.team_id ? "selected" : ""}>${esc(t.emoji)} ${esc(t.name)}</option>`).join("")}</select></td></tr>`).join("")}</tbody></table></div>`;
  h2.onchange = async (e) => { const id = e.target.dataset.stid; if (!id) return;
    await run(async () => must(await sb.from("students").update({ team_id: e.target.value || null }).eq("id", id)), "บันทึกแล้ว ✅"); };
};
