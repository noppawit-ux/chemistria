/* การกระทำ — ส่วนหนึ่งของหน้านักเรียน (index.html) โหลดต่อกันตามลำดับใน index.html */
/* ---------------- การกระทำ ---------------- */
async function act(fn, okMsg) {
  try { const r = await fn(); await load(); if (okMsg) toast(okMsg); return r; }
  catch (e) { toast(e.message); }
}
const claim = (id) => act(() => rpc("claim_quest", { p_token: tk(), p_quest: id }), "ส่งเควสแล้ว รอครูตรวจ ✅");
const buy = (id) => confirm("ยืนยันการแลกสิทธิพิเศษ?") && act(() => rpc("buy_privilege", { p_token: tk(), p_privilege: id }), "แลกสำเร็จ 🎉 ดูได้ในหน้า “คลัง”");
const usePriv = (id) => confirm("ขอใช้สิทธิ์นี้ ครูจะเป็นผู้อนุมัติ")
  && act(() => rpc("request_privilege", { p_token: tk(), p_redemption: id }), "ส่งคำขอให้ครูแล้ว");
const pickClass = (k, n) => confirm("เลือกคลาส “" + n + "” ?") && act(() => rpc("choose_class", { p_token: tk(), p_key: k }), "เปลี่ยนคลาสแล้ว ⚔️");
const buyDecor = (id, n, p) => confirm(`ซื้อ “${n}” ราคา ${p} เหรียญ?`) && act(() => rpc("buy_decor", { p_token: tk(), p_item: id }), "ซื้อสำเร็จ 🎉 กด “สวมใส่” ได้เลย").then(() => FX.coins(".coin", 4));
const pickDecor = (slot, id) => { const it = id ? (D.decor_catalog || []).find((d) => d.id === id) : null; if (it) DRAFT[slot] = it; else delete DRAFT[slot]; render(); if (it) FX.at(".stg", "spirit-flame", { scale: 1.6, foot: true }); };
const resetDraft = () => { DRAFT = null; render(); };
const saveDraft = () => act(async () => {
  const eq = D.student.decor || {};
  for (const [k] of SLOTS) { const cur = eq[k] ? eq[k].id : null, nxt = DRAFT[k] ? DRAFT[k].id : null; if (cur !== nxt) await rpc("equip_decor", { p_token: tk(), p_slot: k, p_item: nxt }); }
}, "บันทึกการแต่งตัวแล้ว ✨").then(() => setTimeout(() => FX.at(".stg", "mana-burst", { scale: 2.2 }), 300));
const setGender = (g) => act(() => rpc("set_gender", { p_token: tk(), p_gender: g }), "เปลี่ยนเพศตัวละครแล้ว ✨");
const equipDecor = (slot, id) => act(() => rpc("equip_decor", { p_token: tk(), p_slot: slot, p_item: id }), id ? "สวมใส่แล้ว ✨" : "ถอดออกแล้ว");
const claimBoss = () => act(() => rpc("boss_claim", { p_token: tk() }), "รับรางวัลปราบบอสแล้ว 🎉").then((r) => { FX.victory(); return r; });
const submitOnline = (id, t) => confirm(`ส่งงาน “${t}” ?`) && act(async () => { const r = await rpc("submit_assignment", { p_token: tk(), p_assignment: id }); toast(`ส่งแล้ว ✅ ได้ +${r.exp} EXP ทันที`, 3500); return r; });
async function shrink(file, max = 1280, q = 0.72) {
  let bmp; try { bmp = await createImageBitmap(file, { imageOrientation: "from-image" }); } catch (e) { bmp = await createImageBitmap(file); }
  const sc = Math.min(1, max / Math.max(bmp.width, bmp.height)), c = document.createElement("canvas");
  c.width = Math.round(bmp.width * sc); c.height = Math.round(bmp.height * sc);
  c.getContext("2d").drawImage(bmp, 0, 0, c.width, c.height);
  return new Promise((res) => c.toBlob(res, "image/jpeg", q));
}
async function submitPhoto(id, input) {
  const f = input.files && input.files[0]; if (!f) return;
  toast("กำลังอัปโหลดรูป…", 12000);
  try {
    const blob = await shrink(f); if (!blob) throw new Error("อ่านรูปไม่สำเร็จ");
    if (blob.size > 1500000) throw new Error("รูปใหญ่เกินไป ลองถ่ายใหม่");
    const slot = await rpc("begin_upload", { p_token: tk(), p_assignment: id });
    const up = await sb.storage.from("submissions").upload(slot + ".jpg", blob, { contentType: "image/jpeg", upsert: false });
    if (up.error) throw new Error("อัปโหลดไม่สำเร็จ: " + up.error.message);
    const r = await rpc("submit_assignment", { p_token: tk(), p_assignment: id, p_slot: slot });
    await load(); toast(`ส่งงานแล้ว ✅ ได้ +${r.exp} EXP ทันที`, 3500);
  } catch (e) { toast(e.message); }
  input.value = "";
}
