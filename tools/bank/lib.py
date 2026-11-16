import random
Q = []
_T = [""]
def topic(t): _T[0] = t
def M(q, ok, wrong, ex, pts=1):
    ch = [ok] + list(wrong); assert len(ch) >= 3 and len(set(ch)) == len(ch), q
    r = random.Random(hash_s(q)); order = list(range(len(ch))); r.shuffle(order)
    Q.append(dict(topic=_T[0], kind="mcq", q=q, data={"choices": [{"t": ch[i]} for i in order], "answer": order.index(0)}, points=pts, explain=ex))
def F(q, a, ex, pts=1):
    Q.append(dict(topic=_T[0], kind="tf", q=q, data={"answer": bool(a)}, points=pts, explain=ex))
def MT(q, pairs, extra, ex, pts=None):
    """จับคู่: pairs=[(ซ้าย,ขวา)...] extra=ตัวลวงฝั่งขวา"""
    r = random.Random(hash_s(q)); right = [p[1] for p in pairs] + list(extra); idx = list(range(len(right))); r.shuffle(idx)
    Q.append(dict(topic=_T[0], kind="match", q=q, data={"left": [{"t": p[0]} for p in pairs], "right": [{"t": right[i]} for i in idx], "pairs": [idx.index(k) for k in range(len(pairs))]}, points=pts or len(pairs), explain=ex))
def DG(q, zones, items, ex):
    """ลากวาง: items=[(ข้อความ, index โซน)]"""
    Q.append(dict(topic=_T[0], kind="drag", q=q, data={"zones": [{"t": z} for z in zones], "items": [{"t": t} for t, _ in items], "answer": [z for _, z in items]}, points=len(items), explain=ex))
def hash_s(s):
    h = 7
    for ch in s: h = (h * 131 + ord(ch)) % 1000003
    return h
