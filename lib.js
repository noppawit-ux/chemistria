// ฟังก์ชันที่ใช้ร่วมกันทั้งหน้านักเรียนและหน้าแอดมิน
const sb = window.supabase.createClient(KB_CONFIG.SUPABASE_URL, KB_CONFIG.SUPABASE_ANON_KEY);

const $ = (s, r = document) => r.querySelector(s);
const $$ = (s, r = document) => [...r.querySelectorAll(s)];
const esc = (v) => String(v ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

function toast(msg, ms = 2600) {
  let t = $("#toast");
  if (!t) { t = document.createElement("div"); t.id = "toast"; document.body.appendChild(t); }
  t.textContent = msg; t.style.display = "block";
  clearTimeout(toast._t); toast._t = setTimeout(() => (t.style.display = "none"), ms);
}

// เรียก RPC แล้วโยน error เป็นข้อความอ่านง่าย
async function rpc(name, args = {}) {
  const { data, error } = await sb.rpc(name, args);
  if (error) throw new Error(error.message);
  return data;
}

const TH_MONTHS = ["มกราคม","กุมภาพันธ์","มีนาคม","เมษายน","พฤษภาคม","มิถุนายน","กรกฎาคม","สิงหาคม","กันยายน","ตุลาคม","พฤศจิกายน","ธันวาคม"];
const TH_DAYS = ["อา","จ","อ","พ","พฤ","ศ","ส"];
const pad = (n) => String(n).padStart(2, "0");
const ymd = (d) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
const todayStr = () => ymd(new Date());
function fmtDate(s) {
  if (!s) return "";
  const [y, m, d] = String(s).slice(0, 10).split("-").map(Number);
  return `${d} ${TH_MONTHS[m - 1].slice(0, 3)}. ${(y + 543) % 100}`;
}

const CAT_LABEL = { pre_mid: "ก่อนกลางภาค", midterm: "กลางภาค", post_mid: "หลังกลางภาค", final: "ปลายภาค", behavior: "จิตพิสัย", bonus: "คะแนนพิเศษ" };
const KIND_LABEL = { lesson: "เรียน", assignment: "งาน", exam: "สอบ", holiday: "วันหยุด", activity: "กิจกรรม" };
const STATUS_LABEL = { present: "มา", late: "สาย", absent: "ขาด", leave: "ลา" };
