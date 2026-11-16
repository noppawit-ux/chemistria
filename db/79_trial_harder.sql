-- 79: เพิ่มความยากด่านบอสเลื่อนแรงค์ (ต้องรันหลัง 69 และ 17)
--  1) บอสแรงขึ้น: HP ×1.3, พลังโจมตี ×1.5 (ปรับเฉพาะบอสที่ครูยังไม่เคยแก้ค่าเดิม)
--  2) ผู้เล่นเข้าด่านด้วย HP สูงสุด 85% ของปกติ
--  3) เวลาตอบคำถามในด่านบอส 15 วินาที (ปกติ 20)
--  4) ตอบผิด/หมดเวลาในด่านบอส → บอสฟื้น HP 5% ของ HP สูงสุด
-- รันซ้ำได้ ไม่ทับค่าที่ครูแก้เอง

update monsters m set hp = v.nh, atk = v.na
  from (values ('trial_silver',170,14,220,21), ('trial_gold',230,16,300,24), ('trial_platinum',310,18,400,27),
               ('trial_emerald',390,20,510,30), ('trial_diamond',490,22,640,33), ('trial_master',610,24,790,36),
               ('trial_grandmaster',770,27,1000,40), ('trial_challenger',960,30,1250,45)) v(k, oh, oa, nh, na)
 where m.key = v.k and m.hp = v.oh and m.atk = v.oa;

do $$
declare d text;
begin
  -- ผู้เล่น HP 85% ในด่านบอส
  select pg_get_functiondef('rank_trial_start(uuid)'::regprocedure) into d;
  if d not like '%0.85%' then
    d := replace(d, 'update battles set trial_rank = g, rewarded = false where id = bid;',
                    'update battles set trial_rank = g, rewarded = false, p_max = round(p_max * 0.85)::int, p_hp = round(p_max * 0.85)::int where id = bid;');
    if d not like '%0.85%' then raise exception 'แก้ rank_trial_start ไม่สำเร็จ (ต้องรัน 69 ก่อน)'; end if;
    execute d;
  end if;
  -- เวลา 17 วินาทีฝั่งเซิร์ฟเวอร์ (เผื่อเน็ตช้า) + บอสฟื้นเมื่อตอบผิด
  select pg_get_functiondef('battle_answer(uuid,uuid,int)'::regprocedure) into d;
  if d not like '%b.trial_rank is not null%' then
    d := replace(d, 'p_pick = q.answer and elapsed <= 40;',
                    'p_pick = q.answer and elapsed <= case when b.trial_rank is not null then 17 else 40 end;');
    d := replace(d, E'    b.correct := b.correct + 1;\n  end if;\n  ev := ev || jsonb_build_object(''dmg'', dmg, ''heal'', heal, ''crit'', crit, ''fast'', fast);',
                    E'    b.correct := b.correct + 1;\n  elsif b.trial_rank is not null then\n    regen := round(b.m_max * 0.05)::int; b.m_hp := least(b.m_max, b.m_hp + regen);\n  end if;\n  ev := ev || jsonb_build_object(''dmg'', dmg, ''heal'', heal, ''crit'', crit, ''fast'', fast, ''regen'', regen);');
    d := replace(d, E'declare\n', E'declare\n  regen int := 0;\n');
    if d not like '%regen := round%' or d not like '%then 17 else 40%' or d not like '%regen int := 0%' then
      raise exception 'แก้ battle_answer ไม่สำเร็จ (ต้องรัน 17 ก่อน)';
    end if;
    execute d;
  end if;
end $$;
