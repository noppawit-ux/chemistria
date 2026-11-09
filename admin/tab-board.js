/* แท็บ: board */
TAB.board = async function (v) {
  const h = holder(v, "📢 บอร์ดประกาศ", "โพสต์ประกาศถึงห้องที่เลือกอยู่ หรือทุกห้อง · ปักหมุดไว้บนสุดได้ · ซ่อน/ลบโพสต์นักเรียนที่ไม่เหมาะสมได้ · นักเรียนโพสต์ได้วันละ 3 ครั้ง");
  const load = async () => must(await sb.from("board_posts").select("*, students(name,no)").or(`class_id.eq.${S.cls},class_id.is.null`).order("pinned", { ascending: false }).order("created_at", { ascending: false }).limit(100));
  const draw = async () => {
    const L = await load();
    h.innerHTML = `<input id="bt" maxlength="80" placeholder="หัวข้อประกาศ"><textarea id="bb" rows="3" maxlength="1000" placeholder="ข้อความประกาศ…" style="margin-top:6px"></textarea>
      <div class="row" style="margin-top:8px"><select id="bs" style="width:auto"><option value="cls">ห้อง ${esc(clsName())}</option><option value="all">ทุกห้อง</option></select>
      <label class="row" style="gap:6px"><input type="checkbox" id="bp" style="width:auto"> 📌 ปักหมุด</label><button class="btn gold" id="bpost">📮 โพสต์ประกาศ</button></div><hr style="border-color:var(--line)">
      ${L.map((p) => `<div class="item ${p.hidden ? "muted" : ""}" style="align-items:flex-start"><div class="grow"><b>${p.pinned ? "📌 " : ""}${p.title ? esc(p.title) : "(ไม่มีหัวข้อ)"}</b>
        <span class="tag ${p.author_kind === "teacher" ? "late" : "wait"}">${p.author_kind === "teacher" ? "ครู" : esc(p.students?.name || "นักเรียน")}</span>${p.class_id ? "" : ' <span class="tag ok">ทุกห้อง</span>'}${p.hidden ? ' <span class="tag no">ซ่อนอยู่</span>' : ""}
        <div>${esc(p.body)}</div><div class="muted" style="font-size:12px">${new Date(p.created_at).toLocaleString("th-TH")}</div></div>
        <button class="btn small ghost" data-a="pin" data-id="${p.id}" data-v="${p.pinned}">${p.pinned ? "เลิกปักหมุด" : "📌"}</button>
        <button class="btn small ghost" data-a="hide" data-id="${p.id}" data-v="${p.hidden}">${p.hidden ? "แสดง" : "ซ่อน"}</button>
        <button class="btn small ghost" data-a="del" data-id="${p.id}">🗑️</button></div>`).join("") || '<p class="muted">ยังไม่มีโพสต์</p>'}`;
    $("#bpost").onclick = () => run(async () => {
      const body = $("#bb").value.trim(); if (!body) throw new Error("พิมพ์ข้อความก่อน");
      must(await sb.from("board_posts").insert({ class_id: $("#bs").value === "all" ? null : S.cls, author_kind: "teacher", title: $("#bt").value.trim() || null, body, pinned: $("#bp").checked }));
      await draw();
    }, "โพสต์แล้ว ✅");
  };
  h.onclick = (e) => { const b = e.target.closest("button[data-a]"); if (!b) return; const id = b.dataset.id, a = b.dataset.a;
    run(async () => {
      if (a === "del") { if (!confirm("ลบโพสต์นี้ถาวร?")) return; must(await sb.from("board_posts").delete().eq("id", id)); }
      else if (a === "pin") must(await sb.from("board_posts").update({ pinned: b.dataset.v !== "true" }).eq("id", id));
      else must(await sb.from("board_posts").update({ hidden: b.dataset.v !== "true" }).eq("id", id));
      await draw();
    });
  };
  await draw();
};
