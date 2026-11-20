#!/usr/bin/env python3
"""สร้างสไปรต์เอฟเฟกต์ใหม่ (v2_*.webp) + vfxpack.js จากแพ็กพื้นผิวของครู
ใช้: python3 tools/make_vfx.py "<โฟลเดอร์ tex packed1>"   (ผลลัพธ์ -> assets/pixelfx/v2_*.webp, vfxpack.js)"""
import sys, os, glob, json
from PIL import Image
SRC = sys.argv[1]; OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "pixelfx")
def crop_cells(path, cols, rows, n=None):
    im = Image.open(path).convert("RGBA"); W, H = im.size; cw, ch = W // cols, H // rows; out = []
    for r in range(rows):
        for c in range(cols): out.append(im.crop((c*cw, r*ch, (c+1)*cw, (r+1)*ch)))
    return out[:n] if n else out
def frames_dir(d, key=lambda p: int(os.path.basename(p).split(".")[0])):
    return [Image.open(p).convert("RGBA") for p in sorted(glob.glob(os.path.join(SRC, d, "*.png")), key=key)]
def trim(frames, pad=2):
    bb = None
    for f in frames:
        b = f.split()[3].point(lambda a: 255 if a > 10 else 0).getbbox()
        if b: bb = b if not bb else (min(bb[0], b[0]), min(bb[1], b[1]), max(bb[2], b[2]), max(bb[3], b[3]))
    bb = (max(0, bb[0]-pad), max(0, bb[1]-pad), min(frames[0].width, bb[2]+pad), min(frames[0].height, bb[3]+pad))
    return [f.crop(bb) for f in frames]
META = {}
def pack(name, frames, w, ms, ox=0.5, oy=0.5, loop=False, cols=8, tint=None, **kw):
    frames = trim(frames); fw, fh = frames[0].size; h = max(1, round(w * fh / fw))
    sheet_w, sheet_h = w * 2, h * 2                      # เก็บ 2x ให้คมบนจอ retina แต่ใช้ขนาดแสดง w×h
    rows = (len(frames) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * sheet_w, rows * sheet_h), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        f = f.resize((sheet_w, sheet_h), Image.LANCZOS)
        if tint: f = tint(f)
        sheet.paste(f, ((i % cols) * sheet_w, (i // cols) * sheet_h))
    sheet.save(os.path.join(OUT, f"v2_{name}.webp"), "WEBP", quality=76, method=6)
    META[name] = dict(w=w, h=h, n=len(frames), cols=cols, ms=ms, ox=round(w*ox), oy=round(h*oy), loop=loop, src=f"v2_{name}.webp", sm=1, **kw)
def hue(rgb):                                             # ย้อมสี: คูณช่องสี (คงความโปร่งใส)
    def f(im):
        r, g, b, a = im.split(); k = lambda c, m: c.point(lambda v: min(255, int(v * m)))
        return Image.merge("RGBA", (k(r, rgb[0]), k(g, rgb[1]), k(b, rgb[2]), a))
    return f
# ---- เอฟเฟกต์ในเกม (แทนของเดิม) ----
pack("sword-slash",  crop_cells(f"{SRC}/42/atlas_42.png", 3, 3, 8), 80, 45, 0.5, 0.5)                # จันทร์เสี้ยวฟัน
pack("level-up",     frames_dir("40/frames_40d"), 130, 60, 0.5, 0.5)                                   # อะตอมโคจร
pack("divine-shield",crop_cells(f"{SRC}/56/atlas_56a.png", 3, 4), 84, 70, 0.5, 0.5, loop=True)         # เปลือกอิเล็กตรอน
pack("mana-burst",   crop_cells(f"{SRC}/20/atlas_20.png", 4, 2), 150, 45, 0.5, 0.5)                    # วงแหวนมานา
# ---- ออร่าอุปกรณ์ (ลูป) ----
pack("aura-ring",    crop_cells(f"{SRC}/56/atlas_56a.png", 3, 4), 96, 70, 0.5, 0.5, loop=True, cols=12)         # วงคลื่นที่พื้น
pack("aura-orbit",   frames_dir("40/frames_40d"), 96, 80, 0.5, 0.5, loop=True, cols=16)                          # วงโคจรรอบตัว
with open(os.path.join(os.path.dirname(__file__), "..", "vfxpack.js"), "w") as fh:
    fh.write("/* เอฟเฟกต์ชุดใหม่ v2 (สร้างโดย tools/make_vfx.py) — ทับ PFX_DATA ของเดิมตามชื่อ */\nObject.assign(PFX_DATA," + json.dumps(META, separators=(",", ":")) + ");\n")
print({k: (v["n"], v["w"], v["h"]) for k, v in META.items()})
