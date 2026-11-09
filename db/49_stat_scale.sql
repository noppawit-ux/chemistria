-- =====================================================================
-- 49: ลดอัตราผลของสเตตัสโดยรวม (ค่าเริ่มต้น = 50% ของเดิม) · รันซ้ำได้
--  ตั้งค่า app_settings.stat_effect_pct (100 = เท่าเดิม · 50 = ครึ่งหนึ่ง · 0 = ปิดผลสเตตัส)
--  ผลที่ลดตามสัดส่วน: ขยัน (+EXP%), ปัญญา (+EXP ควิซ), พลัง (+ดาเมจบอส/ดวล), โชค (+โอกาส SR/SSR), โบนัสเหรียญ% ของไอเทม
--  ตัวเลขแต้มสเตตัสเองไม่เปลี่ยน แปลงเฉพาะ "ผล" ที่ได้ (แอปแสดงผลจากเซิร์ฟเวอร์อัตโนมัติ)
-- =====================================================================
insert into app_settings (key, value) values ('stat_effect_pct', '50') on conflict (key) do nothing;

do $$
declare d text; n text; k text := '_setting_int(''stat_effect_pct'', 50) / 100.0';
begin
  -- _stats: ลดค่า effects
  d := pg_get_functiondef('_stats(uuid)'::regprocedure);
  if d not like '%stat_effect_pct%' then
    n := d;
    n := replace(n, '''quiz_exp'', (b_int + p_int + i_int) / 2', '''quiz_exp'', floor((b_int + p_int + i_int) / 2.0 * ' || k || ')::int');
    n := replace(n, '''exp_pct'', b_dil + p_dil + i_dil', '''exp_pct'', round((b_dil + p_dil + i_dil) * ' || k || ')::int');
    n := replace(n, '''boss_pct'', 3 * (b_str + p_str + i_str)', '''boss_pct'', round(3 * (b_str + p_str + i_str) * ' || k || ')::int');
    n := replace(n, '''rare_pct'', 3 * (b_luk + p_luk + i_luk)', '''rare_pct'', round(3 * (b_luk + p_luk + i_luk) * ' || k || ')::int');
    n := replace(n, '''coin_pct'', i_coin', '''coin_pct'', round(i_coin * ' || k || ')::int');
    if n = d or n not like '%stat_effect_pct%' then raise exception '_stats: ไม่พบข้อความที่ต้องแก้'; end if;
    execute n;
  end if;
  -- award: โบนัส EXP ขยันใช้ค่า effects
  d := pg_get_functiondef('award(uuid,int,int,text,text)'::regprocedure);
  if d like '%''dil''->>''total''%' then
    n := replace(d, '(_stats(p_student)->''dil''->>''total'')::int', '(_stats(p_student)->''effects''->>''exp_pct'')::int');
    if n = d then raise exception 'award: ไม่พบข้อความที่ต้องแก้'; end if;
    execute n;
  end if;
  -- ควิซ: โบนัสปัญญา
  d := pg_get_functiondef('_quiz_submit(uuid,jsonb)'::regprocedure);
  if d like '%''int''->>''total''%' then
    n := replace(d, '(_stats(sid)->''int''->>''total'')::int, 0) / 2', '(_stats(sid)->''effects''->>''quiz_exp'')::int, 0)');
    if n = d then raise exception '_quiz_submit: ไม่พบข้อความที่ต้องแก้'; end if;
    execute n;
  end if;
  -- ดาเมจบอสจากเควส: พลัง
  d := pg_get_functiondef('trg_claim_dmg()'::regprocedure);
  if d like '%0.03 * s%' then
    n := replace(replace(d, '(_stats(new.student_id)->''str''->>''total'')::int', '(_stats(new.student_id)->''effects''->>''boss_pct'')::int'), '(1 + 0.03 * s)', '(1 + s / 100.0)');
    if n = d then raise exception 'trg_claim_dmg: ไม่พบข้อความที่ต้องแก้'; end if;
    execute n;
  end if;
  -- กาชา: โชคเพิ่มน้ำหนัก SR/SSR
  d := pg_get_functiondef('_gacha_pick_luk(boolean,int)'::regprocedure);
  if d not like '%stat_effect_pct%' then
    n := replace(d, '0.03 * greatest(p_luk, 0)', '(0.03 * _setting_int(''stat_effect_pct'', 50) / 100.0) * greatest(p_luk, 0)');
    if n = d then raise exception '_gacha_pick_luk: ไม่พบข้อความที่ต้องแก้'; end if;
    execute n;
  end if;
end $$;
revoke execute on function _stats(uuid) from public, anon, authenticated;
revoke execute on function award(uuid,int,int,text,text) from public, anon, authenticated;
revoke execute on function _gacha_pick_luk(boolean,int) from public, anon, authenticated;
