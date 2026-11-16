"""สร้าง db/77_exam_bank300.sql จากคลังข้อสอบใน tools/bank (เคมีอินทรีย์ ม.6) — รันซ้ำได้ (ข้อที่มีอยู่แล้วไม่ซ้ำ)"""
import sys, os, json, importlib, collections
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "bank"))
import lib
for m in ["s1","s2","s3","s4","s5","s6","s7","s8","s9","s10","s11","s12","s13"]: importlib.import_module(m)
DROP = ["แก๊สเรือนกระจกที่เกิดจากการเผาไหม้เชื้อเพลิงฟอสซิล", "มวลโมเลกุลของโพรเพน (C3H8)", "หลักการ 3R"]
Q = [q for q in lib.Q if not any(q["q"].startswith(d) for d in DROP)]
assert len(Q) == 300, len(Q)
assert len({q["q"] for q in Q}) == 300, "ข้อความโจทย์ซ้ำ"
for q in Q:
    d = q["data"]
    if q["kind"] == "mcq": assert 0 <= d["answer"] < len(d["choices"]) and len(d["choices"]) >= 3
    if q["kind"] == "match": assert sorted(d["pairs"]) == sorted(set(d["pairs"])) and len(d["pairs"]) == len(d["left"]) and max(d["pairs"]) < len(d["right"])
    if q["kind"] == "drag": assert max(d["answer"]) < len(d["zones"]) and len(d["answer"]) == len(d["items"])
cnt = collections.Counter(q["topic"] for q in Q)
out = ["-- 77: คลังข้อสอบเคมีอินทรีย์ ม.6 จำนวน 300 ข้อ (v2.18) · รันซ้ำได้ (ข้อที่โจทย์ + หัวข้อซ้ำจะไม่ถูกเพิ่มอีก)",
       "--  · ชนิด: เลือกตอบ / จริง-เท็จ / จับคู่ / ลากวาง · มีเฉลยอธิบายทุกข้อ · แยก 13 หัวข้อ",
       "--  · " + " · ".join(f"{t} {n}" for t, n in cnt.items()),
       "--  · อยู่ใน 'คลังข้อสอบ' แท็บ 📝 ข้อสอบ ครูเลือกข้อเข้าชุดสอบได้เอง", ""]
for q in Q:
    j = json.dumps(q["data"], ensure_ascii=False)
    assert "$j$" not in j and "$t$" not in q["q"]
    out.append("insert into exam_questions (topic, kind, q, data, points, explain)\n"
               f"select $t${q['topic']}$t$, '{q['kind']}', $t${q['q']}$t$, $j${j}$j$::jsonb, {q['points']}, $t${q['explain']}$t$\n"
               f"where not exists (select 1 from exam_questions where topic = $t${q['topic']}$t$ and q = $t${q['q']}$t$);")
open(os.path.join(os.path.dirname(__file__), "..", "db", "77_exam_bank300.sql"), "w", encoding="utf-8").write("\n".join(out) + "\n")
print("ok", len(Q), dict(cnt))
