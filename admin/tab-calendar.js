/* แท็บ: calendar */
TAB.calendar = async function (v) {
  const h = holder(v, "📅 ปฏิทินรายวิชา", "เว้นห้องว่างไว้ = แสดงให้ทุกห้อง · วันกำหนดส่งงานจะขึ้นในปฏิทินนักเรียนอัตโนมัติ");
  await crud(h, { table: "events", order: "event_date", defaults: { kind: "lesson", event_date: todayStr(), class_id: S.cls },
    cols: [{ k: "event_date", label: "วันที่", t: "date" }, { k: "end_date", label: "ถึงวันที่", t: "date" }, { k: "title", label: "หัวข้อ", w: 200 },
      { k: "kind", label: "ประเภท", t: "select", opts: () => Object.entries(KIND_LABEL) }, { k: "class_id", label: "ห้อง", t: "select", opts: classOpts("ทุกห้อง") }, { k: "note", label: "หมายเหตุ", w: 160 }] });
};
