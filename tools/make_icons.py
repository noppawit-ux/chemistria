#!/usr/bin/env python3
"""ตัดไอคอนจากแพ็ก "Animated Rpg Icons Free version" (Vivid Motion Assets) -> assets/aic/s_<key>.webp (นิ่ง 128px) + a_<key>.webp (แถบ 8 เฟรม 1024x128)
ใช้: python3 tools/make_icons.py "<โฟลเดอร์แพ็ก>" """
import sys, os, glob
from PIL import Image
SRC = sys.argv[1]; OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "aic"); os.makedirs(OUT, exist_ok=True)
MAP = {  # key -> (หมวด, ชื่อไฟล์ส่วนท้าย)
 "arm_pyro": ("Armor", "PYRO_ROBE"), "arm_dragon": ("Armor", "DRAGON_SCALE"), "arm_plague": ("Armor", "PLAGUE_COAT"), "arm_electro": ("Armor", "ELECTRO_SUIT"),
 "arm_shadow": ("Armor", "SHADOW_SUIT"), "arm_solar": ("Armor", "SOLAR_PLATE"), "arm_kraken": ("Armor", "KRAKEN_SHELL"), "arm_hero": ("Armor", "HERO_PLATE"),
 "arm_crystal": ("Armor", "CRYSTAL_ROBES"), "arm_griffin": ("Armor", "GRIFFIN_PLATE"), "arm_jaguar": ("Armor", "JAGUAR_KNIGHT"), "arm_shogun": ("Armor", "SHOGUN_DAIMYO"),
 "pot_fire": ("Consumables", "FIRE_POTION"), "pot_health": ("Consumables", "HEALTH_POTION"), "pot_ice": ("Consumables", "ICE_POTION"),
 "pot_mana": ("Consumables", "MANA_POTION"), "pot_poison": ("Consumables", "POISON_POTION"), "pot_stamina": ("Consumables", "STAMINA_POTION"),
}
def find(cat, tail, static):
    for f in glob.glob(os.path.join(SRC, cat, "*", "*.png")):
        b = os.path.basename(f)
        if tail + "_128x128" in b and (b.endswith("_Static.png") == static): return f
for k, (cat, tail) in MAP.items():
    s, a = find(cat, tail, True), find(cat, tail, False)
    if not s or not a: print("ไม่พบ", k); continue
    Image.open(s).convert("RGBA").save(f"{OUT}/s_{k}.webp", "WEBP", quality=88, method=6)
    sheet = Image.open(a).convert("RGBA"); W, H = sheet.size; n = (W // 128) * (H // 128); strip = Image.new("RGBA", (128 * n, 128))
    for i in range(n): strip.paste(sheet.crop(((i % (W // 128)) * 128, (i // (W // 128)) * 128, (i % (W // 128) + 1) * 128, (i // (W // 128) + 1) * 128)), (i * 128, 0))
    strip.save(f"{OUT}/a_{k}.webp", "WEBP", quality=80, method=6); print(k, n)
