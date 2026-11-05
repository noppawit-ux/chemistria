"""ตัดภาพจากชีต Canva (กริด) ออกเป็นไฟล์ย่อย — ถ้าได้ไฟล์ความละเอียดสูงมาแทน ให้วางทับใน art_src/ แล้วรันใหม่
ใช้: python3 tools/slice_art.py  (ต้องมี Pillow)"""
from PIL import Image
import numpy as np, os
from scipy import ndimage as ndi
ROOT = os.path.join(os.path.dirname(__file__), '..')
SRC = os.path.join(ROOT, 'art_src'); OUT = os.path.join(ROOT, 'web', 'assets')
SHEETS = {
  'avatars': (2, 2, ['alchemist', 'scientist', 'guardian', 'seeker'], 360),
  'ranks':   (5, 2, ['iron','bronze','silver','gold','platinum','emerald','diamond','master','grandmaster','challenger'], 200),
  'items':   (4, 3, ['pouch','crystal','potion_red','potion_green','tile','burner','microscope','wand','chest','ticket','hourglass','crown'], 200),
  'hats':    (3, 2, ['bow','cap','grad','tophat','crown','goggles'], 200),
  'bosses':  (3, 2, ['acid_dragon','beaker_golem','electron_wizard','element_robot','flame_demon','germ_hydra'], 360),
  'medals':  (4, 3, ['present_5','present_20','streak_5','streak_10','ontime_3','ontime_10','quest_5','quest_20','gacha_10','level_5','level_10','master'], 200),
  'items2':  (4, 3, ['scroll','magnifier','rack','spellbook','flask','sword','shield','dnastaff','rocket','trophy','torch','scepter'], 200),
  'pets':    (3, 2, ['frog','cat','dog','fox','dragon','owl'], 240),
}
for name, (cols, rows, keys, target) in SHEETS.items():
    im = Image.open(os.path.join(SRC, f'{name}_sheet.png')).convert('RGB')
    W, H = im.size; cw, ch = W / cols, H / rows
    os.makedirs(os.path.join(OUT, 'items' if name=='items2' else name), exist_ok=True)
    for i, k in enumerate(keys):
        r, c = divmod(i, cols)
        pad = 0
        box = (int(c*cw)+pad, int(r*ch)+pad, int((c+1)*cw)-pad, int((r+1)*ch)-pad)
        t = im.crop(box)
        sc = target / max(t.size)                 # ย่อ/ขยายให้ด้านยาวสุดเท่ากับ target พิกเซล
        if abs(sc - 1) > 0.02: t = t.resize((round(t.width*sc), round(t.height*sc)), Image.LANCZOS)
        if True:                       # ตัดพื้นหลังม่วงออก (โปร่งใส) เฉพาะส่วนที่ต่อกับขอบภาพ
            a = np.array(t).astype(float)
            bgc = np.median(np.concatenate([a[:3].reshape(-1, 3), a[-3:].reshape(-1, 3)]), axis=0)
            d = np.sqrt(((a - bgc) ** 2).sum(2))
            near = d < 34
            lab, _ = ndi.label(near)
            edge = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
            bgmask = np.isin(lab, list(edge))
            alpha = np.where(bgmask, 0.0, 1.0)
            alpha = ndi.gaussian_filter(alpha, 0.8)
            alpha = np.clip((alpha - 0.2) / 0.6, 0, 1)
            # เก็บเฉพาะชิ้นหลัก (ตัดเศษของช่องข้างเคียงที่ติดมาที่ขอบ)
            solid = ndi.binary_dilation(alpha > 0.3, iterations=max(3, t.width // 40))
            lab2, n2 = ndi.label(solid)
            if n2 > 1:
                sizes = ndi.sum(alpha > 0.3, lab2, range(1, n2 + 1))
                alpha = alpha * (lab2 == (int(np.argmax(sizes)) + 1))
            t = Image.fromarray(np.dstack([a.astype(np.uint8), (alpha * 255).astype(np.uint8)]), 'RGBA')
        t.save(os.path.join(OUT, 'items' if name=='items2' else name, f'{k}.png'), optimize=True)
print('done')
