"""ตัดพื้นหลังตัวละครเต็มตัวจาก Canva (art_src/chars/<ชื่อ>.png) → web/assets/chars/<ชื่อ>.png (โปร่งใส 2:3)
ชื่อไฟล์ = <คลาส> หรือ <คลาส>_<สไตล์ชุด>  เช่น alchemist.png, alchemist_space.png, novice.png
ถ้าได้ภาพความละเอียดสูงมาแทน ให้วางทับใน art_src/chars/ แล้วรันใหม่: python3 tools/process_chars.py"""
from PIL import Image, ImageFilter
import numpy as np, os, glob
from scipy import ndimage as ndi
ROOT = os.path.join(os.path.dirname(__file__), '..')
import sys
SUB = sys.argv[1] if len(sys.argv) > 1 else 'chars'            # chars (ค่าเริ่มต้น) หรือ monsters
SRC = os.path.join(ROOT, 'art_src', SUB); OUT = os.path.join(ROOT, 'web', 'assets', SUB)
os.makedirs(OUT, exist_ok=True)
W, H = 300, 450                                  # ขนาดผลลัพธ์ (2:3)
for f in sorted(glob.glob(os.path.join(SRC, '*.png'))):
    name = os.path.basename(f)
    im = Image.open(f).convert('RGB')
    scale = max(1, 900 / im.height)               # ขยายก่อนตัด เพื่อให้ขอบเนียน
    if scale > 1: im = im.resize((round(im.width * scale), round(im.height * scale)), Image.LANCZOS)
    a = np.array(im).astype(float)
    bgc = np.median(np.concatenate([a[:4].reshape(-1, 3), a[-4:].reshape(-1, 3), a[:, :4].reshape(-1, 3), a[:, -4:].reshape(-1, 3)]), axis=0)
    d = np.sqrt(((a - bgc) ** 2).sum(2))
    lab, _ = ndi.label(d < 40)
    edge = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    alpha = np.where(np.isin(lab, list(edge)), 0.0, 1.0)
    alpha = ndi.binary_opening(alpha > 0.5, iterations=2).astype(float)
    lab2, n2 = ndi.label(ndi.binary_dilation(alpha > 0.5, iterations=6))
    if n2 > 1:
        sizes = ndi.sum(alpha > 0.5, lab2, range(1, n2 + 1)); alpha *= (lab2 == int(np.argmax(sizes)) + 1)
    alpha = ndi.gaussian_filter(alpha, 1.4); alpha = np.clip((alpha - 0.3) / 0.4, 0, 1)
    rgba = Image.fromarray(np.dstack([a.astype(np.uint8), (alpha * 255).astype(np.uint8)]), 'RGBA')
    rgba = rgba.crop(rgba.getbbox())
    s = min((W * 0.94) / rgba.width, (H * 0.96) / rgba.height)
    rgba = rgba.resize((round(rgba.width * s), round(rgba.height * s)), Image.LANCZOS)
    rgba = rgba.filter(ImageFilter.UnsharpMask(radius=1.2, percent=60, threshold=2))
    canvas = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    canvas.alpha_composite(rgba, ((W - rgba.width) // 2, H - rgba.height - 4))   # ชิดล่าง กึ่งกลางแนวนอน
    canvas.save(os.path.join(OUT, name), optimize=True)
print('done', len(glob.glob(os.path.join(OUT, '*.png'))))
