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
  -- เวลา 17 วินาทีฝั่งเซิร์ฟเวอร์ (เผื่อเน็ตช้า) — ถ้าหาจุดแก้ไม่เจอจะข้าม (ฝั่งหน้าเว็บจำกัด 15 วินาทีอยู่แล้ว)
  select pg_get_functiondef('battle_answer(uuid,uuid,int)'::regprocedure) into d;
  if d !~ 'b\.trial_rank is not null then 17' and d ~ 'elapsed\s*<=\s*40' then
    execute regexp_replace(d, 'elapsed\s*<=\s*40', 'elapsed <= case when b.trial_rank is not null then 17 else 40 end');
  elsif d !~ 'b\.trial_rank is not null then 17' then
    raise notice 'ข้ามการแก้เวลาฝั่งเซิร์ฟเวอร์ (ไม่พบจุดแก้) — ไม่กระทบส่วนอื่น';
  end if;
end $$;

-- ตอบผิดในด่านบอส → บอสฟื้น 5% (ใช้ trigger แทนการแก้ฟังก์ชันตอบ จึงไม่ขึ้นกับหน้าตาของฟังก์ชัน)
create or replace function trg_trial_regen() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.trial_rank is not null and new.status = 'active' and old.cur_q is not null and new.cur_q is null
     and new.correct = old.correct and new.m_hp = old.m_hp then
    new.m_hp := least(new.m_max, new.m_hp + round(new.m_max * 0.05)::int);
  end if;
  return new;
end $$;
drop trigger if exists trial_regen on battles;
create trigger trial_regen before update on battles for each row execute function trg_trial_regen();
revoke execute on function trg_trial_regen() from public, anon, authenticated;
