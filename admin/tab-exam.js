/* แท็บ: exam — ระบบสอบเก็บคะแนน (คลังข้อ · สร้างชุดสอบ · ติดตาม/ตรวจข้อเขียน · ส่งคะแนนเข้าสมุด) */
TAB.exam = async function (v) {
  v.innerHTML = "";
  const KD = { mcq: "เลือกตอบ", tf: "จริง/เท็จ", short: "ข้อเขียน/วาดรูป", match: "จับคู่", drag: "ลากวาง" };
  const CAT = { pre_mid: "ก่อนกลางภาค", midterm: "สอบกลางภาค", post_mid: "หลังกลางภาค", final: "สอบปลายภาค", behavior: "จิตพิสัย", bonus: "โบนัส" };
  const SHOW = { after_close: "หลังปิดสอบ", after_submit: "ทันทีที่ส่ง", never: "ไม่แสดง (ครูแจ้งเอง)" };
  const st = { sub: "exams", topic: "", kind: "" };
  const fmtD = (d) => (d ? new Date(d).toLocaleString("th-TH", { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" }) : "—");
  const toLocal = (d) => { if (!d) return ""; const x = new Date(d); x.setMinutes(x.getMinutes() - x.getTimezoneOffset()); return x.toISOString().slice(0, 16); };
  const sub = (t) => (t == null ? "" : esc(String(t)).replace(/([A-Za-z\)\]])(\d+)/g, "$1<sub>$2</sub>"));
  const root = document.createElement("div"); v.appendChild(root);
  const overlay = (html) => {
    const o = document.createElement("div"); o.className = "overlay on"; o.style.overflow = "auto";
    o.innerHTML = `<div class="card" style="max-width:900px;margin:0 auto;position:relative;text-align:left"><button class="btn small ghost" style="position:absolute;right:8px;top:8px" data-x>✕ ปิด</button>${html}</div>`;
    o.addEventListener("click", (e) => { if (e.target === o || e.target.dataset.x != null) { o.remove(); } });
    document.body.appendChild(o); return o;
  };
  const sideParse = (s) => { const [t, img] = String(s).split("@@").map((x) => x.trim()); return img ? { t: t || "", img } : { t: t || "" }; };
  const sideFmt = (o) => (o.img ? `${o.t || ""} @@ ${o.img}` : o.t || "");
  const upImg = async (file) => {
    const blob = await shrink(file, 1400, 0.85); const ext = "jpg", path = `q/${crypto.randomUUID()}.${ext}`;
    const up = await sb.storage.from("examimg").upload(path, blob, { contentType: "image/jpeg" });
    if (up.error) throw new Error(up.error.message);
    return sb.storage.from("examimg").getPublicUrl(path).data.publicUrl;
  };

  /* ---------- คลังข้อ ---------- */
  async function bank() {
    const rows = must(await sb.from("exam_questions").select("*").order("topic").order("created_at"));
    const topics = [...new Set(rows.map((r) => r.topic))];
    const list = rows.filter((r) => (!st.topic || r.topic === st.topic) && (!st.kind || r.kind === st.kind));
    root.innerHTML = `${subBar()}<div class="card"><div class="row"><div style="width:200px"><label>หัวข้อ</label><select id="xt"><option value="">ทั้งหมด</option>${topics.map((t) => `<option ${st.topic === t ? "selected" : ""}>${esc(t)}</option>`).join("")}</select></div>
      <div style="width:160px"><label>ชนิด</label><select id="xk"><option value="">ทั้งหมด</option>${Object.entries(KD).map(([k, l]) => `<option value="${k}" ${st.kind === k ? "selected" : ""}>${l}</option>`).join("")}</select></div>
      <div style="align-self:end"><button class="btn mint" id="xnew">➕ เพิ่มข้อ</button></div></div>
      <div class="scroll"><table><thead><tr><th>หัวข้อ</th><th>ชนิด</th><th>โจทย์</th><th>คะแนน</th><th>เปิดใช้</th><th></th></tr></thead><tbody>
      ${list.map((r) => `<tr><td>${esc(r.topic)}</td><td>${KD[r.kind]}</td><td style="min-width:260px">${sub(r.q).slice(0, 140)}${r.img ? " 🖼️" : ""}</td><td>${r.points}</td>
        <td><input type="checkbox" data-act="${r.id}" ${r.active ? "checked" : ""}></td><td style="white-space:nowrap"><button class="btn small" data-edit="${r.id}">แก้</button> <button class="btn red small" data-del="${r.id}">ลบ</button></td></tr>`).join("") || '<tr><td colspan="6" class="muted">ยังไม่มีข้อ</td></tr>'}</tbody></table></div>
      <p class="muted">${list.length} ข้อ (ทั้งหมด ${rows.length})</p></div>`;
    bindSub();
    $("#xt", root).onchange = (e) => { st.topic = e.target.value; bank(); };
    $("#xk", root).onchange = (e) => { st.kind = e.target.value; bank(); };
    $("#xnew", root).onclick = () => qEdit(null, bank);
    root.querySelectorAll("[data-act]").forEach((el) => (el.onchange = () => run(async () => must(await sb.from("exam_questions").update({ active: el.checked }).eq("id", el.dataset.act)), "บันทึกแล้ว ✅")));
    root.querySelectorAll("[data-edit]").forEach((el) => (el.onclick = () => qEdit(rows.find((r) => r.id === el.dataset.edit), bank)));
    root.querySelectorAll("[data-del]").forEach((el) => (el.onclick = async () => {
      if (!confirm("ลบข้อนี้? (ถ้าข้อถูกใช้ในชุดสอบแล้วจะลบไม่ได้ ให้ปิดใช้งานแทน)")) return;
      try { must(await sb.from("exam_questions").delete().eq("id", el.dataset.del)); toast("ลบแล้ว"); bank(); } catch (e) { toast("ลบไม่ได้: " + e.message); }
    }));
  }
  function qEdit(r, back) {
    const q = r || { topic: st.topic || "ไอโซเมอร์", kind: "mcq", q: "", img: "", data: {}, points: 1, explain: "", explain_img: "", active: true };
    const d = q.data || {};
    const o = overlay(`<h3>${r ? "แก้ข้อสอบ" : "เพิ่มข้อสอบ"}</h3><div id="qf"></div>`);
    const f = $("#qf", o);
    const paint = (kind) => {
      let body = "";
      if (kind === "mcq") body = `<label>ตัวเลือก (บรรทัดละข้อ · ใส่รูปด้วย <code>ข้อความ @@ path</code>)</label><textarea id="f_ch" rows="5">${esc((d.choices || []).map(sideFmt).join("\n"))}</textarea>
        <label>ข้อที่ถูก (ลำดับที่ เริ่ม 1)</label><input id="f_ans" type="number" min="1" value="${(d.answer ?? 0) + 1}">`;
      else if (kind === "tf") body = `<label>เฉลย</label><select id="f_tf"><option value="1" ${d.answer !== false ? "selected" : ""}>ถูก</option><option value="0" ${d.answer === false ? "selected" : ""}>ผิด</option></select>`;
      else if (kind === "short") body = `<label>คำตอบที่ถือว่าถูก (บรรทัดละคำตอบ — เว้นว่าง = ครูตรวจเองทั้งหมด)</label><textarea id="f_sa" rows="3">${esc((d.answers || []).join("\n"))}</textarea>
        <label><input type="checkbox" id="f_up" ${d.upload ? "checked" : ""}> ให้แนบรูป (วาดโครงสร้างแล้วถ่ายรูป)</label>
        <label><input type="checkbox" id="f_rv" ${d.review !== false ? "checked" : ""}> ถ้าพิมพ์ไม่ตรงเฉลย ให้รอครูตรวจ (ไม่ใช่ 0 ทันที)</label>
        <label>คำใบ้ (ไม่บังคับ)</label><input id="f_hint" value="${esc(d.hint || "")}">`;
      else if (kind === "match") body = `<label>คู่ที่ถูก (บรรทัดละคู่: <code>ซ้าย | ขวา</code> · ใส่รูป <code>ข้อความ @@ path</code>)</label>
        <textarea id="f_pairs" rows="5">${esc((d.left || []).map((l, i) => sideFmt(l) + " | " + sideFmt(d.right[d.pairs[i]])).join("\n"))}</textarea>
        <label>ตัวลวงฝั่งขวา (ถ้ามี บรรทัดละข้อ)</label><textarea id="f_extra" rows="2">${esc((d.right || []).filter((_, i) => !(d.pairs || []).includes(i)).map(sideFmt).join("\n"))}</textarea>`;
      else if (kind === "drag") body = `<label>กลุ่ม/ช่อง (บรรทัดละกลุ่ม · ใส่รูปได้ด้วย <code>@@ path</code>)</label><textarea id="f_zones" rows="3">${esc((d.zones || []).map(sideFmt).join("\n"))}</textarea>
        <label>รายการที่ต้องลาก (บรรทัดละรายการ: <code>ข้อความ @@ path | เลขกลุ่มที่ถูก (เริ่ม 1)</code>)</label>
        <textarea id="f_items" rows="6">${esc((d.items || []).map((it, i) => sideFmt(it) + " | " + (d.answer[i] + 1)).join("\n"))}</textarea>`;
      $("#kb", f).innerHTML = body;
    };
    f.innerHTML = `<div class="row"><div style="width:180px"><label>หัวข้อ</label><input id="f_topic" value="${esc(q.topic)}"></div>
      <div style="width:170px"><label>ชนิด</label><select id="f_kind">${Object.entries(KD).map(([k, l]) => `<option value="${k}" ${q.kind === k ? "selected" : ""}>${l}</option>`).join("")}</select></div>
      <div style="width:100px"><label>คะแนน</label><input id="f_pts" type="number" step="0.5" min="0" value="${q.points}"></div></div>
      <label>โจทย์ (สูตรเคมี เช่น C4H10 จะแสดงตัวห้อยให้เอง)</label><textarea id="f_q" rows="3">${esc(q.q)}</textarea>
      <label>รูปประกอบโจทย์ (URL/path) <input type="file" accept="image/*" id="f_qup" style="width:auto"></label><input id="f_img" value="${esc(q.img || "")}">
      <div id="kb"></div>
      <label>เฉลยอธิบาย (แสดงหลังเปิดผล)</label><textarea id="f_ex" rows="2">${esc(q.explain || "")}</textarea>
      <label>รูปเฉลย (URL/path) <input type="file" accept="image/*" id="f_exup" style="width:auto"></label><input id="f_eximg" value="${esc(q.explain_img || "")}">
      <label><input type="checkbox" id="f_active" ${q.active ? "checked" : ""}> เปิดใช้งาน</label>
      <div style="margin-top:10px"><button class="btn gold" id="f_save">💾 บันทึก</button></div>`;
    paint(q.kind);
    $("#f_kind", f).onchange = (e) => { d.__k = e.target.value; paint(e.target.value); };
    $("#f_qup", f).onchange = async (e) => { try { $("#f_img", f).value = await upImg(e.target.files[0]); toast("อัปโหลดรูปแล้ว"); } catch (er) { toast(er.message); } };
    $("#f_exup", f).onchange = async (e) => { try { $("#f_eximg", f).value = await upImg(e.target.files[0]); toast("อัปโหลดรูปแล้ว"); } catch (er) { toast(er.message); } };
    $("#f_save", f).onclick = async () => {
      const kind = $("#f_kind", f).value, lines = (id) => ($(id, f).value || "").split("\n").map((x) => x.trim()).filter(Boolean);
      let data = {};
      try {
        if (kind === "mcq") { const ch = lines("#f_ch").map(sideParse); const ans = +$("#f_ans", f).value - 1; if (ch.length < 2 || ans < 0 || ans >= ch.length) throw new Error("ตัวเลือกต้องมี ≥2 ข้อ และเลือกข้อถูกให้ตรง"); data = { choices: ch, answer: ans }; }
        else if (kind === "tf") data = { answer: $("#f_tf", f).value === "1" };
        else if (kind === "short") data = { answers: lines("#f_sa"), upload: $("#f_up", f).checked, review: $("#f_rv", f).checked, hint: $("#f_hint", f).value.trim() || undefined };
        else if (kind === "match") {
          const pr = lines("#f_pairs").map((l) => l.split("|")); if (pr.length < 2 || pr.some((p) => p.length < 2)) throw new Error("ต้องมีอย่างน้อย 2 คู่ รูปแบบ ซ้าย | ขวา");
          const right = pr.map((p) => sideParse(p.slice(1).join("|"))).concat(lines("#f_extra").map(sideParse));
          data = { left: pr.map((p) => sideParse(p[0])), right, pairs: pr.map((_, i) => i) };
        } else if (kind === "drag") {
          const zones = lines("#f_zones").map(sideParse), it = lines("#f_items").map((l) => { const k = l.lastIndexOf("|"); return [sideParse(l.slice(0, k)), +l.slice(k + 1)]; });
          if (zones.length < 2 || it.length < 2 || it.some((x) => !(x[1] >= 1 && x[1] <= zones.length))) throw new Error("ต้องมี ≥2 กลุ่ม ≥2 รายการ และเลขกลุ่มให้ถูกช่วง");
          data = { zones, items: it.map((x) => x[0]), answer: it.map((x) => x[1] - 1) };
        }
      } catch (e) { return toast(e.message); }
      if (!$("#f_q", f).value.trim()) return toast("กรอกโจทย์ก่อน");
      const row = { topic: $("#f_topic", f).value.trim() || "ทั่วไป", kind, q: $("#f_q", f).value.trim(), img: $("#f_img", f).value.trim() || null, data, points: +$("#f_pts", f).value || 1,
        explain: $("#f_ex", f).value.trim() || null, explain_img: $("#f_eximg", f).value.trim() || null, active: $("#f_active", f).checked };
      await run(async () => must(r ? await sb.from("exam_questions").update(row).eq("id", r.id) : await sb.from("exam_questions").insert(row)), "บันทึกแล้ว ✅");
      o.remove(); back();
    };
  }

  /* ---------- ชุดสอบ ---------- */
  const subBar = () => `<div class="row" style="margin-bottom:8px"><button class="btn ${st.sub === "exams" ? "gold" : "ghost"}" id="sx1">📝 ชุดสอบ</button><button class="btn ${st.sub === "bank" ? "gold" : "ghost"}" id="sx2">📚 คลังข้อสอบ</button></div>`;
  const bindSub = () => { const a = $("#sx1", root), b = $("#sx2", root); if (a) a.onclick = () => { st.sub = "exams"; exams(); }; if (b) b.onclick = () => { st.sub = "bank"; bank(); }; };
  async function exams() {
    const rows = must(await sb.from("exams").select("*").order("created_at", { ascending: false }));
    const cnt = must(await sb.from("exam_items").select("exam_id"));
    const nq = {}; cnt.forEach((c) => (nq[c.exam_id] = (nq[c.exam_id] || 0) + 1));
    const cn = (ids) => (ids || []).map((id) => S.classes.find((c) => c.id === id)?.name || "?").join(", ");
    root.innerHTML = `${subBar()}<div class="card"><button class="btn mint" id="xe_new">➕ สร้างชุดสอบ</button>
      <div class="scroll"><table><thead><tr><th>ชื่อ</th><th>ห้อง</th><th>ข้อ</th><th>เวลา</th><th>สถานะ</th><th>เปิด–ปิด</th><th></th></tr></thead><tbody>
      ${rows.map((e) => `<tr><td><b>${esc(e.title)}</b><br><small class="muted">${CAT[e.score_cat]} · เต็ม ${e.max_score}${e.pushed_at ? " · ส่งคะแนนแล้ว" : ""}</small></td><td>${esc(cn(e.class_ids))}</td><td>${nq[e.id] || 0}</td><td>${e.minutes} น.${e.access_code ? `<br><b title="รหัสเข้าสอบ">🔑 ${esc(e.access_code)}</b>` : ""}</td>
        <td>${{ draft: "ร่าง", open: "เปิด", closed: "ปิด" }[e.status]}</td><td><small>${fmtD(e.open_at)}<br>${fmtD(e.close_at)}</small></td>
        <td style="white-space:nowrap"><button class="btn small gold" data-mon="${e.id}">ติดตาม/ตรวจ</button> <button class="btn small" data-ed="${e.id}">แก้</button> <button class="btn red small" data-del="${e.id}">ลบ</button></td></tr>`).join("") || '<tr><td colspan="7" class="muted">ยังไม่มีชุดสอบ</td></tr>'}</tbody></table></div></div>`;
    bindSub();
    $("#xe_new", root).onclick = () => examEdit(null);
    root.querySelectorAll("[data-ed]").forEach((el) => (el.onclick = () => examEdit(rows.find((r) => r.id === el.dataset.ed))));
    root.querySelectorAll("[data-mon]").forEach((el) => (el.onclick = () => monitor(rows.find((r) => r.id === el.dataset.mon))));
    root.querySelectorAll("[data-del]").forEach((el) => (el.onclick = async () => {
      if (!confirm("ลบชุดสอบนี้พร้อมผลสอบของนักเรียนทั้งหมด? (คะแนนที่ส่งเข้าสมุดแล้วจะไม่ถูกลบ)")) return;
      await run(async () => must(await sb.from("exams").delete().eq("id", el.dataset.del)), "ลบแล้ว"); exams();
    }));
  }
  async function examEdit(e) {
    const bankRows = must(await sb.from("exam_questions").select("id,topic,kind,q,points,active").order("topic").order("created_at"));
    const cur = e ? must(await sb.from("exam_items").select("qid,pos").eq("exam_id", e.id).order("pos")).map((x) => x.qid) : [];
    const x = e || { title: "", topic: "", class_ids: S.cls ? [S.cls] : [], score_cat: "pre_mid", max_score: 10, minutes: 30, shuffle: true, max_attempts: 1, show_result: "after_close", reward_exp: 0, status: "draft" };
    const picked = new Set(cur);
    const o = overlay(`<h3>${e ? "แก้ชุดสอบ" : "สร้างชุดสอบ"}</h3><div id="ef"></div>`), f = $("#ef", o);
    f.innerHTML = `<label>ชื่อชุดสอบ</label><input id="e_title" value="${esc(x.title)}">
      <label>🔑 รหัสเข้าสอบ (นักเรียนต้องกรอกทุกครั้งที่เริ่มสอบ · ครูบอกในห้อง) <button class="btn small ghost" type="button" id="e_gen">สุ่มใหม่</button></label><input id="e_code" value="${esc(x.access_code || String(Math.floor(1000 + Math.random() * 9000)))}" style="max-width:200px;font-size:1.2em;letter-spacing:.15em">
      <label>ห้องที่สอบ</label><div>${S.classes.map((c) => `<label style="display:inline-block;margin-right:12px"><input type="checkbox" class="e_cls" value="${c.id}" ${(x.class_ids || []).includes(c.id) ? "checked" : ""}> ${esc(c.name)}</label>`).join("")}</div>
      <div class="row"><div style="width:170px"><label>ประเภทคะแนนในสมุด</label><select id="e_cat">${Object.entries(CAT).map(([k, l]) => `<option value="${k}" ${x.score_cat === k ? "selected" : ""}>${l}</option>`).join("")}</select></div>
        <div style="width:110px"><label>คะแนนเต็มในสมุด</label><input id="e_max" type="number" step="0.5" value="${x.max_score}"></div>
        <div style="width:110px"><label>เวลา (นาที)</label><input id="e_min" type="number" value="${x.minutes}"></div>
        <div style="width:110px"><label>สอบได้ (ครั้ง)</label><input id="e_att" type="number" min="1" max="10" value="${x.max_attempts}"></div>
        <div style="width:110px"><label>EXP เข้าสอบ</label><input id="e_exp" type="number" min="0" value="${x.reward_exp}"></div></div>
      <div class="row"><div style="width:220px"><label>เปิดสอบ</label><input id="e_open" type="datetime-local" value="${toLocal(x.open_at)}"></div>
        <div style="width:220px"><label>ปิดสอบ</label><input id="e_close" type="datetime-local" value="${toLocal(x.close_at)}"></div>
        <div style="width:200px"><label>แสดงผล/เฉลย</label><select id="e_show">${Object.entries(SHOW).map(([k, l]) => `<option value="${k}" ${x.show_result === k ? "selected" : ""}>${l}</option>`).join("")}</select></div>
        <div style="width:140px"><label>สถานะ</label><select id="e_st">${[["draft", "ร่าง (ซ่อน)"], ["open", "เปิดให้สอบ"], ["closed", "ปิด"]].map(([k, l]) => `<option value="${k}" ${x.status === k ? "selected" : ""}>${l}</option>`).join("")}</select></div></div>
      <div class="row"><div style="width:240px"><label>สลับหน้าจอได้ไม่เกิน (ครั้ง · 0 = ไม่จำกัด แต่นับให้ครู)</label><input id="e_blur" type="number" min="0" max="20" value="${x.max_blur ?? 3}"></div></div>
      <label><input type="checkbox" id="e_shuf" ${x.shuffle ? "checked" : ""}> สลับลำดับข้อ/ตัวเลือกของแต่ละคน</label>
      <label>เลือกข้อสอบ <small class="muted" id="e_cnt"></small></label>
      <div class="row" style="align-items:flex-end;gap:8px"><div style="width:190px"><label>หัวข้อ</label><select id="e_ft"><option value="">ทั้งหมด</option>${[...new Set(bankRows.map((r) => r.topic))].map((t) => `<option>${esc(t)}</option>`).join("")}</select></div>
        <div style="width:130px"><label>ชนิด</label><select id="e_fk"><option value="">ทั้งหมด</option>${Object.entries(KD).map(([k, l]) => `<option value="${k}">${l}</option>`).join("")}</select></div>
        <div style="width:80px"><label>สุ่มกี่ข้อ</label><input id="e_rn" type="number" min="1" value="10"></div>
        <button class="btn ghost small" id="e_rand" type="button">🎲 สุ่มเพิ่มจากที่แสดง</button><button class="btn ghost small" id="e_all" type="button">เลือกทั้งหมดที่แสดง</button><button class="btn ghost small" id="e_none" type="button">ล้างที่เลือก</button></div>
      <div class="scroll" style="max-height:280px"><table><tbody id="e_qs"></tbody></table></div>
      <div style="margin-top:10px"><button class="btn gold" id="e_save">💾 บันทึก</button></div>`;
    $("#e_gen", f).onclick = () => { $("#e_code", f).value = String(Math.floor(1000 + Math.random() * 9000)); };
    const cntUpd = () => { const pts = bankRows.filter((r) => picked.has(r.id)).reduce((a, r) => a + +r.points, 0); $("#e_cnt", f).textContent = `เลือก ${picked.size} ข้อ · รวม ${pts} คะแนน`; };
    const visible = () => bankRows.filter((r) => (!$("#e_ft", f).value || r.topic === $("#e_ft", f).value) && (!$("#e_fk", f).value || r.kind === $("#e_fk", f).value));
    const drawQs = () => { $("#e_qs", f).innerHTML = visible().map((r) => `<tr><td><input type="checkbox" data-q="${r.id}" ${picked.has(r.id) ? "checked" : ""}></td><td><small>${esc(r.topic)}</small></td><td><small>${KD[r.kind]}</small></td><td>${sub(r.q).slice(0, 110)}</td><td>${r.points}</td></tr>`).join(""); cntUpd(); };
    $("#e_ft", f).onchange = $("#e_fk", f).onchange = drawQs;
    $("#e_all", f).onclick = () => { visible().forEach((r) => picked.add(r.id)); drawQs(); };
    $("#e_none", f).onclick = () => { picked.clear(); drawQs(); };
    $("#e_rand", f).onclick = () => { const pool = visible().filter((r) => !picked.has(r.id)).sort(() => Math.random() - 0.5); pool.slice(0, Math.max(1, +$("#e_rn", f).value || 10)).forEach((r) => picked.add(r.id)); drawQs(); };
    drawQs();
    $("#e_qs", f).onchange = (ev) => { const id = ev.target.dataset.q; if (!id) return; ev.target.checked ? picked.add(id) : picked.delete(id); cntUpd(); };
    cntUpd();
    $("#e_save", f).onclick = async () => {
      const ids = [...f.querySelectorAll(".e_cls:checked")].map((c) => c.value);
      if (!$("#e_title", f).value.trim() || !ids.length || !picked.size) return toast("ใส่ชื่อ เลือกห้อง และเลือกข้อสอบอย่างน้อย 1 ข้อ");
      const row = { max_blur: Math.max(0, +$("#e_blur", f).value || 0), access_code: $("#e_code", f).value.trim() || null, title: $("#e_title", f).value.trim(), class_ids: ids, score_cat: $("#e_cat", f).value, max_score: +$("#e_max", f).value || 10, minutes: +$("#e_min", f).value || 30,
        max_attempts: +$("#e_att", f).value || 1, reward_exp: +$("#e_exp", f).value || 0, show_result: $("#e_show", f).value, status: $("#e_st", f).value, shuffle: $("#e_shuf", f).checked,
        open_at: $("#e_open", f).value ? new Date($("#e_open", f).value).toISOString() : null, close_at: $("#e_close", f).value ? new Date($("#e_close", f).value).toISOString() : null };
      await run(async () => {
        let id = e && e.id;
        if (e) must(await sb.from("exams").update(row).eq("id", id)); else id = must(await sb.from("exams").insert(row).select("id").single()).id;
        must(await sb.from("exam_items").delete().eq("exam_id", id));
        const order = bankRows.filter((r) => picked.has(r.id));
        must(await sb.from("exam_items").insert(order.map((r, i) => ({ exam_id: id, qid: r.id, pos: i + 1 }))));
      }, "บันทึกชุดสอบแล้ว ✅");
      o.remove(); exams();
    };
  }

  /* ---------- ติดตามผล/ตรวจ ---------- */
  async function monitor(e) {
    let m; try { m = await rpc("exam_monitor", { p_exam: e.id }); } catch (er) { return toast(er.message); }
    const best = (att) => (att || []).filter((a) => a.status === "submitted").sort((a, b) => b.score - a.score)[0];
    const o = overlay(`<h3>📊 ${esc(e.title)}</h3>${e.access_code ? `<p style="font-size:1.6em;margin:4px 0">🔑 รหัสเข้าสอบ: <b style="letter-spacing:.15em">${esc(e.access_code)}</b></p>` : '<p class="muted">⚠️ ชุดนี้ยังไม่ตั้งรหัสเข้าสอบ</p>'}
      <div class="row"><button class="btn small" id="m_re">🔄 โหลดใหม่</button><button class="btn small" id="m_rg">♻️ ตรวจใหม่ทั้งชุด</button><button class="btn small red" id="m_cl">⏹ ปิดสอบทันที</button>
        <button class="btn small gold" id="m_push">📤 ส่งคะแนนเข้าสมุด</button><button class="btn small ghost" id="m_csv">⬇️ CSV</button></div>
      <div class="scroll"><table><thead><tr><th>ห้อง</th><th>เลขที่</th><th>ชื่อ</th><th>สถานะ</th><th>คะแนนดีที่สุด</th><th>สลับหน้าจอ</th><th></th></tr></thead><tbody>
      ${m.rows.map((s) => { const b = best(s.att), act = (s.att || []).find((a) => a.status === "active"), last = (s.att || []).slice(-1)[0];
        return `<tr><td>${esc(s.class)}</td><td>${s.no}</td><td>${esc(s.name)}</td><td>${act ? "🟡 กำลังสอบ" : b ? "✅ ส่งแล้ว" + (b.review ? " ⚠️รอตรวจ" : "") : "⬜ ยังไม่สอบ"}</td>
        <td>${b ? `<b>${b.score}</b>/${b.total}` : "—"}</td><td>${(s.att || []).reduce((n, a) => n + a.blur, 0) || ""}</td>
        <td>${(s.att || []).filter((a) => a.status === "submitted").map((a) => `<button class="btn small" data-att="${a.id}">ครั้งที่ ${a.no}</button>`).join(" ")}</td></tr>`; }).join("")}</tbody></table></div>
      <h4>สถิติรายข้อ</h4><div class="scroll"><table><thead><tr><th>#</th><th>ชนิด</th><th>โจทย์</th><th>คะแนน</th><th>ตอบแล้ว</th><th>ได้เฉลี่ย %</th></tr></thead><tbody>
      ${m.qs.map((q) => `<tr><td>${q.pos}</td><td>${KD[q.kind]}</td><td>${sub(q.q).slice(0, 90)}</td><td>${q.points}</td><td>${q.n}</td><td>${q.avg ?? "—"}</td></tr>`).join("")}</tbody></table></div>`);
    $("#m_re", o).onclick = () => { o.remove(); monitor(e); };
    $("#m_rg", o).onclick = async () => { const n = await run(() => rpc("exam_regrade", { p_exam: e.id })); toast(`ตรวจใหม่ ${n} ชุด ✅`); o.remove(); monitor(e); };
    $("#m_cl", o).onclick = async () => { if (!confirm("ปิดสอบทันที? ผู้ที่ยังทำอยู่จะถูกส่งอัตโนมัติ")) return; const n = await run(() => rpc("exam_close", { p_exam: e.id })); toast(`ปิดสอบแล้ว (ส่งอัตโนมัติ ${n} คน)`); o.remove(); monitor(e); };
    $("#m_push", o).onclick = async () => {
      try { const r = await rpc("exam_push", { p_exam: e.id }); toast(`ส่งคะแนนเข้าสมุดแล้ว ${r.students} คน ✅`); }
      catch (er) { if (/รอตรวจ/.test(er.message) && confirm(er.message + "\n\nส่งทั้งที่ยังไม่ครบเลยไหม?")) { const r = await run(() => rpc("exam_push", { p_exam: e.id, p_force: true })); toast(`ส่งแล้ว ${r.students} คน (ยังมีรอตรวจ ${r.pending})`); } else if (!/รอตรวจ/.test(er.message)) toast(er.message); }
    };
    $("#m_csv", o).onclick = () => {
      const lines = [["ห้อง", "เลขที่", "ชื่อ", "คะแนนดีที่สุด", "เต็ม", "คะแนนสมุด", "สลับหน้าจอ"]];
      m.rows.forEach((s) => { const b = best(s.att); lines.push([s.class, s.no, s.name, b ? b.score : "", b ? b.total : "", b ? Math.round((b.score / b.total) * e.max_score * 100) / 100 : "", (s.att || []).reduce((n, a) => n + a.blur, 0)]); });
      const blob = new Blob(["﻿" + lines.map((r) => r.map((c) => `"${String(c).replace(/"/g, '""')}"`).join(",")).join("\n")], { type: "text/csv" });
      const a = document.createElement("a"); a.href = URL.createObjectURL(blob); a.download = `exam_${e.title}.csv`; a.click();
    };
    o.querySelectorAll("[data-att]").forEach((b) => (b.onclick = () => attempt(b.dataset.att, () => { o.remove(); monitor(e); })));
  }
  async function attempt(id, back) {
    let r; try { r = await rpc("exam_attempt_detail", { p_attempt: id }); } catch (er) { return toast(er.message); }
    const L = (k) => "ABCDEFGH"[k] || k + 1;
    const view = (q) => {
      const v = q.view, a = q.ans || {}, k = q.key, p = q.perm || {};
      if (q.kind === "mcq") return [a.i != null ? `${L(a.i)}. ${sub(v.choices[a.i]?.t)}` : "—", sub(k.choices[k.answer].t)];
      if (q.kind === "tf") return [a.v == null ? "—" : a.v ? "ถูก" : "ผิด", k.answer ? "ถูก" : "ผิด"];
      if (q.kind === "short") return [sub(a.t || "") || "—", (k.answers || []).length ? esc(k.answers.join(" / ")) : "ครูตรวจเอง"];
      if (q.kind === "match") return [(a.m || []).map((x, l) => `${sub(v.left[l].t)} → ${x == null ? "?" : sub(v.right[x]?.t)}`).join("<br>"), v.left.map((l, i) => `${sub(l.t)} → ${sub(k.right[k.pairs[i]].t)}`).join("<br>")];
      if (q.kind === "drag") return [(a.z || []).map((z, i) => `${sub(v.items[i].t)} → ${z == null ? "?" : sub(v.zones[z]?.t)}`).join("<br>"), v.items.map((it, i) => `${sub(it.t)} → ${sub(v.zones[k.answer[p.i[i]]].t)}`).join("<br>")];
      return ["", ""];
    };
    const o = overlay(`<h3>${esc(r.student)} — ${esc(r.exam)} (ครั้งที่ ${r.attempt.no}) · ${r.attempt.score}/${r.attempt.total}</h3>
      ${r.qs.map((q, i) => { const [mine, key] = view(q); return `<div class="card" style="border-left:4px solid ${q.graded ? (q.score >= q.points - 0.001 ? "#4fd08a" : "#e0566b") : "#f6c453"}">
        <b>ข้อ ${i + 1}</b> <small class="muted">${KD[q.kind]} · ${q.points} คะแนน</small><div>${sub(q.q)}</div>
        ${q.img ? `<img src="${esc(q.img)}" style="max-height:140px;background:#fff;border-radius:8px">` : ""}
        <p style="margin:4px 0"><small class="muted">นักเรียนตอบ:</small><br>${mine}</p>
        ${q.img_path ? `<div><button class="btn small" data-photo="${esc(q.img_path)}">🖼️ ดูรูปที่แนบ</button></div>` : ""}
        <p style="margin:4px 0"><small class="muted">เฉลย:</small><br><b>${key}</b></p>
        <div class="row" style="align-items:end"><div style="width:100px"><label>คะแนน</label><input type="number" step="0.5" min="0" max="${q.points}" value="${q.score ?? ""}" data-s="${q.id}"></div>
        <div style="flex:1;min-width:180px"><label>ความเห็น</label><input data-n="${q.id}" value="${esc(q.note || "")}"></div>
        <button class="btn small gold" data-g="${q.id}">บันทึก</button> ${q.manual ? '<small class="muted">ครูให้เอง</small>' : q.graded ? "" : '<small style="color:#f6c453">รอตรวจ</small>'}</div></div>`; }).join("")}`);
    o.querySelectorAll("[data-photo]").forEach((b) => (b.onclick = async () => {
      const { data, error } = await sb.storage.from("exam").createSignedUrl(b.dataset.photo, 3600); if (error) return toast(error.message);
      const z = document.createElement("div"); z.className = "overlay on"; z.style.cursor = "zoom-out"; z.style.zIndex = 80; z.innerHTML = `<img src="${data.signedUrl}" style="max-width:96vw;max-height:92vh;border-radius:12px;background:#fff">`; z.onclick = () => z.remove(); document.body.appendChild(z);
    }));
    o.querySelectorAll("[data-g]").forEach((b) => (b.onclick = async () => {
      const qid = b.dataset.g, s = o.querySelector(`[data-s="${qid}"]`).value, n = o.querySelector(`[data-n="${qid}"]`).value;
      if (s === "") return toast("ใส่คะแนนก่อน");
      await run(() => rpc("exam_grade", { p_attempt: id, p_qid: qid, p_score: +s, p_note: n }), "บันทึกคะแนนแล้ว ✅");
    }));
    const xb = o.querySelector("[data-x]"); xb.addEventListener("click", () => back && back());
  }

  await exams();
};
