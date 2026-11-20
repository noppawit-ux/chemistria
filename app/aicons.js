/* ไอคอนจากแพ็ก Animated RPG Icons (assets/aic/a_*.webp แถบ 8 เฟรม) แทน emoji ของสกิลในศึก/คลาสขั้นสูง — ไม่มีในแผนที่ = ใช้ emoji เดิม */
const AICO = {
  gen_hit: "sw_chrono", gen_focus: "st_chrono", gen_heal: "pot_health",
  alc_fire: "pot_fire", alc_boost: "pot_mana", alc_heal: "pot_ice", alc_bomb_u: "st_nova", alc_gold_u: "res_gold", alc_bomb: "st_nova", alc_gold: "res_gold",
  gua_strike: "sw_blood", gua_shield: "sh_paladin", gua_heal: "pot_poison", gua_knight_u: "sh_dragon", gua_light_u: "sh_celestial", gua_knight: "sh_dragon", gua_light: "sh_celestial",
  sci_scan: "st_cyber", sci_shock: "st_voltage", sci_heal: "pot_stamina", sci_volt_u: "st_storm", sci_sage_u: "st_oracle", sci_volt: "st_storm", sci_sage: "st_oracle",
  see_dice: "st_chrono", see_luck: "res_dimer", see_heal: "st_divine", see_fate_u: "st_aurora", see_hunt_u: "res_silver", see_fate: "st_aurora", see_hunt: "res_silver",
};
const aico = (k, emoji, cls = "") => AICO[k] ? `<span class="aic ${cls}" style="background-image:url(assets/aic/a_${AICO[k]}.webp)" role="img" aria-hidden="true"></span>` : esc(emoji || "");
