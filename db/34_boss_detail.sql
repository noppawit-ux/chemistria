-- รอบ 53: บอสประจำสัปดาห์ — ความสามารถของบอส + รายชื่อผู้โจมตีทั้งห้อง
alter table bosses add column if not exists abilities jsonb;

update bosses set abilities = '[{"icon": "🧪", "name": "พ่นกรดกัดกร่อน", "desc": "ละลายเกราะของนักเรียนที่ขี้เกียจ ใครทำเควสไม่ครบจะถูกมังกรเยาะเย้ย"}, {"icon": "🔥", "name": "เกล็ดทนไฟ", "desc": "เกล็ดป้องกันความร้อนสูง ต้องสะสมการโจมตีต่อเนื่องหลายวัน"}, {"icon": "☁️", "name": "ไอกรดหมอกหนา", "desc": "ซ่อนตัวในหมอกกรด โจมตีให้ทุกวันถึงจะเห็นจุดอ่อน"}]'::jsonb where name = 'มังกรกรดซัลฟิวริก' and abilities is null;
update bosses set abilities = '[{"icon": "🟣", "name": "ของเหลวเดือดพล่าน", "desc": "ยิ่งโดนโจมตีมาก ของเหลวยิ่งเดือด จนแตกกระจายในที่สุด"}, {"icon": "🛡️", "name": "กระจกบอโรซิลิเกต", "desc": "ทนทานสูง ต้องช่วยกันทั้งห้องจึงจะทำลายได้"}, {"icon": "☠️", "name": "ไอพิษม่วง", "desc": "ทำให้ผู้ที่หยุดทำเควสเสียสมาธิ"}]'::jsonb where name = 'โกเลมบีกเกอร์พิษ' and abilities is null;
update bosses set abilities = '[{"icon": "⚡", "name": "สายฟ้าวงโคจร", "desc": "ปล่อยสายฟ้าตามวงโคจร ป้องกันได้เฉพาะคนที่ไม่ขยัน"}, {"icon": "🌀", "name": "ควอนตัมเทเลพอร์ต", "desc": "หลบการโจมตีที่ไม่สม่ำเสมอ ต้องทำเควสทุกวัน"}, {"icon": "🔋", "name": "ดูดพลังงาน", "desc": "ดูดพลังงานจากห้องที่เงียบเหงา"}]'::jsonb where name = 'จอมเวทอิเล็กตรอน' and abilities is null;
update bosses set abilities = '[{"icon": "🧱", "name": "เกราะตารางธาตุ", "desc": "เกราะแต่ละแผ่นคือธาตุหนึ่ง ต้องใช้ความรู้เคมีจึงจะพังได้"}, {"icon": "⚙️", "name": "ระบบซ่อมตัวเอง", "desc": "ฟื้นฟูตัวเองหากห้องหยุดโจมตี"}, {"icon": "📡", "name": "สแกนจุดอ่อน", "desc": "เปิดจุดอ่อนให้ผู้ที่ทำควิซเต็ม"}]'::jsonb where name = 'หุ่นยนต์ธาตุจักรกล' and abilities is null;
update bosses set abilities = '[{"icon": "🔥", "name": "เปลวไฟลุกลาม", "desc": "ยิ่งปล่อยไว้นาน ไฟยิ่งแรง รีบสะสมเควสให้ครบ"}, {"icon": "💨", "name": "ควันพราง", "desc": "ซ่อนตัวในควัน ต้องโจมตีต่อเนื่อง"}, {"icon": "🧯", "name": "แพ้การสะสม", "desc": "ดับได้ด้วยการทำเควสพร้อมกันทั้งห้อง"}]'::jsonb where name = 'ปีศาจตะเกียงเพลิง' and abilities is null;
update bosses set abilities = '[{"icon": "🦠", "name": "แพร่พันธุ์", "desc": "งอกหัวใหม่ทุกวันที่ห้องไม่โจมตี"}, {"icon": "🔬", "name": "แปดตาจุลทรรศน์", "desc": "มองเห็นทุกการโจมตี ไม่มีใครหลบหน้าที่ได้"}, {"icon": "🤝", "name": "อ่อนแอต่อความร่วมมือ", "desc": "ต้องช่วยกันทั้งห้องถึงจะปราบได้"}]'::jsonb where name = 'ไฮดราเชื้อโรคแปดตา' and abilities is null;

create or replace function boss_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cls uuid; b bosses%rowtype; n int; mx int; dmg int; mine int; end_d date; done boolean; claimed boolean;
begin
  select class_id into cls from students where id = sid;
  b := _boss_for(cls);
  if b.id is null then return null; end if;
  select count(*) into n from students where class_id = cls;
  mx := b.hp_per_student * greatest(n, 1);
  dmg := _boss_damage(b, cls);
  mine := _boss_damage(b, cls, sid);
  end_d := b.start_date + b.days - 1;
  done := dmg >= mx;
  claimed := exists (select 1 from ledger where student_id = sid and ref_key = 'boss:' || b.id);
  return json_build_object(
    'id', b.id, 'name', b.name, 'emoji', b.emoji, 'image', b.image, 'description', b.description,
    'max_hp', mx, 'damage', least(dmg, mx), 'hp', greatest(mx - dmg, 0), 'defeated', done,
    'my_damage', mine, 'start', b.start_date, 'end', end_d, 'ended', today_th() > end_d,
    'days_left', greatest(end_d - today_th() + 1, 0),
    'reward_exp', b.reward_exp, 'reward_coins', b.reward_coins,
    'abilities', coalesce(b.abilities, '[]'::jsonb),
    'claimed', claimed, 'can_claim', done and mine > 0 and not claimed,
    'top', (select coalesce(json_agg(x), '[]'::json) from (
        select st.name, sum(coalesce(cl.dmg, greatest(q.exp, 1)))::int as dmg, (st.id = sid) as me
          from quest_claims cl join quests q on q.id = cl.quest_id join students st on st.id = cl.student_id
         where st.class_id = cls and cl.status = 'approved'
           and cl.claim_date between b.start_date and end_d
         group by st.id, st.name order by sum(coalesce(cl.dmg, greatest(q.exp, 1))) desc limit 5) x),
    'attackers', (select coalesce(json_agg(x), '[]'::json) from (
        select st.name, sum(coalesce(cl.dmg, greatest(q.exp, 1)))::int as dmg, count(*)::int as hits, (st.id = sid) as me
          from quest_claims cl join quests q on q.id = cl.quest_id join students st on st.id = cl.student_id
         where st.class_id = cls and cl.status = 'approved'
           and cl.claim_date between b.start_date and end_d
         group by st.id, st.name order by sum(coalesce(cl.dmg, greatest(q.exp, 1))) desc, st.name) x));
end $$;
