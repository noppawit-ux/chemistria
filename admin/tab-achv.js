/* แท็บ: achv */
TAB.achv = async function (v) {
  const privs = must(await sb.from("privileges").select("id,name").order("name"));
  const h = holder(v, "🏅 Achievement", "“เก็บเวลา” = มาตรงเวลา/สตรีคการมาเรียน/ส่งงานตรงเวลา · ได้รับอัตโนมัติเมื่อถึงเกณฑ์ พร้อมรางวัล EXP/เหรียญ/สิทธิพิเศษ");
  await crud(h, { table: "achievements", order: "metric", defaults: { metric: "present_count", threshold: 5, reward_exp: 20, reward_coins: 5, active: true, emoji: "🏅" },
    cols: [{ k: "emoji", label: "อีโมจิ", w: 50 }, { k: "image", label: "ภาพเหรียญ", w: 140 }, { k: "key", label: "รหัส(ไม่ซ้ำ)", w: 100 }, { k: "name", label: "ชื่อ", w: 150 }, { k: "description", label: "คำอธิบาย", w: 180 },
      { k: "metric", label: "เงื่อนไข", t: "select", opts: () => [["present_count", "มาตรงเวลา (คาบ)"], ["attendance_count", "มาเรียนทั้งหมด"], ["attendance_streak", "มาตรงเวลาติดกัน"], ["ontime_submissions", "ส่งงานตรงเวลา"],
        ["quests_done", "ทำเควสสำเร็จ"], ["gacha_pulls", "สุ่มกาชา"], ["total_exp", "EXP รวม"], ["level", "เลเวล"]] },
      { k: "threshold", label: "ถึง", t: "number", w: 60 }, { k: "reward_exp", label: "+EXP", t: "number", w: 60 }, { k: "reward_coins", label: "+เหรียญ", t: "number", w: 60 },
      { k: "reward_privilege_id", label: "+สิทธิพิเศษ", t: "select", opts: () => [["", "—"], ...privs.map((p) => [p.id, p.name])] }, { k: "active", label: "เปิด", t: "bool" }] });
};
