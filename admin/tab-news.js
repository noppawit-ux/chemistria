/* แท็บ: news */
TAB.news = async function (v) {
  const h = holder(v, "📣 ข่าวสาร/อีเว้นท์ (สไลด์หน้าแรกของนักเรียน)", "💡 ข่าวที่ชื่อหรือสรุปมีคำว่า “กาชา” หรือ “ตู้ตำนาน” จะแสดงที่หน้ากาชาของนักเรียนด้วย · ใส่รูปเป็นพาธในเว็บ (เช่น assets/news/rank.jpg) หรือลิงก์รูป https://… ขนาดแนะนำ 920×340 · ลำดับ: เลขมากขึ้นก่อน · “แสดงถึงวันที่” ว่าง = แสดงตลอด · รายละเอียดเต็มขึ้นเมื่อนักเรียนกดสไลด์ · สไลด์แรก “อัปเดตใหม่” ระบบสร้างเอง");
  await crud(h, { table: "news_posts", order: "sort", defaults: { kind: "news", sort: 0, active: true }, addLabel: "เพิ่มข่าว",
    cols: [{ k: "kind", label: "ชนิด", t: "select", opts: () => [["news", "ข่าว"], ["event", "อีเว้นท์"]] }, { k: "title", label: "หัวข้อ", w: 180 }, { k: "summary", label: "ข้อความสั้นบนสไลด์", w: 220 }, { k: "body", label: "รายละเอียดเต็ม", w: 280 },
      { k: "image", label: "รูป (พาธ/URL)", w: 190 }, { k: "starts_at", label: "เริ่ม", t: "date" }, { k: "ends_at", label: "แสดงถึงวันที่", t: "date" }, { k: "sort", label: "ลำดับ", t: "number", w: 60 }, { k: "active", label: "เปิด", t: "bool" }] });
};
