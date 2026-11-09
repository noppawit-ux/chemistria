/* แท็บ: timetable */
TAB.timetable = async function (v) {
  const h = holder(v, "🕒 ตารางสอน (ขึ้นในปฏิทินและหน้าหลักของนักเรียนทุกสัปดาห์)", "วัน: 1=จันทร์ … 5=ศุกร์ · เวลาพิมพ์แบบ 08:40 · ใช้ตั้งแต่/ถึงวันที่ ใช้ปิดตารางเก่าเมื่อเปลี่ยนภาคเรียน (ปิดแถวด้วยติ๊กใช้งาน)");
  await crud(h, { table: "timetable", order: "dow", defaults: { dow: 1, start_time: "08:40", end_time: "09:30", effective_from: "2026-11-02", active: true, class_id: S.cls }, addLabel: "เพิ่มคาบ",
    cols: [{ k: "class_id", label: "ห้อง", t: "select", opts: classOpts("— เลือกห้อง —") }, { k: "dow", label: "วัน (1-7)", t: "number", w: 60 }, { k: "start_time", label: "เริ่ม", w: 70 }, { k: "end_time", label: "จบ", w: 70 },
      { k: "period", label: "คาบ", w: 80 }, { k: "title", label: "วิชา", w: 160 }, { k: "room", label: "ห้องเรียน", w: 70 },
      { k: "effective_from", label: "ใช้ตั้งแต่", t: "date" }, { k: "effective_to", label: "ถึง", t: "date" }, { k: "active", label: "ใช้งาน", t: "bool" }] });
};
