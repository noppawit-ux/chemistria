-- 102: ระบบคลาสแบบใหม่ — เลเวลคลาส (แต้มความชำนาญ) + โบนัสสเตตัสตามเลเวล + คลาสขั้นสูง (2 สายต่อคลาส)
-- ต้องรันหลัง 66 (สเตตัส), 69 (ด่านแรงค์), 99, 101 · รันซ้ำได้
-- • แต้มความชำนาญเก็บแยกตามคลาส: ได้จาก EXP ที่ได้รับ (EXP ÷ 5) + ชนะมอน +10 + ชนะบอสด่านแรงค์ +25 · เพดานต่อวัน 40 แต้ม (กันปั๊ม)
-- • เลเวลคลาส 1–10 (สะสม 0/20/50/90/140/200/280/380/500/650 แต้ม) · เปลี่ยนคลาสแล้วแต้มของคลาสเดิมยังอยู่
-- • โบนัสสเตตัสรายเลเวล: สเตตัสหลัก +(เลเวล+1)÷2 · สเตตัสรอง +เลเวล÷3 (ปัดลง) ใช้ได้ทุกที่ที่ใช้สเตตัส (ดาเมจ ฮีล คริ HP EXP)
-- • คลาสขั้นสูง: เลเวลคลาส ≥ 5 และผ่านด่านแรงค์ Gold ขึ้นไป → เลือก 1 ใน 2 สาย ได้สเตตัสหลัก +3 รอง +1 และสกิลไม้ตายในศึก (CD 4) · เปลี่ยนสายเสียเหรียญเท่าเปลี่ยนคลาส
-- • ปรับค่าได้ใน app_settings: class_pts_daily (40), class_pts_exp_div (5), class_pts_battle (10), class_pts_trial (25)

insert into app_settings (key, value) values ('class_pts_daily','40'), ('class_pts_exp_div','5'), ('class_pts_battle','10'), ('class_pts_trial','25') on conflict (key) do nothing;

alter table char_classes add column if not exists main_stat text;
alter table char_classes add column if not exists sub_stat text;
update char_classes set main_stat = v.m, sub_stat = v.s
  from (values ('alchemist','dil','int'), ('scientist','int','luk'), ('guardian','dil','str'), ('seeker','luk','str')) v(key, m, s)
 where char_classes.key = v.key and char_classes.main_stat is null;

-- คลาสขั้นสูง (แยกตาราง เพื่อไม่ปนกับตัวเลือกคลาสพื้นฐาน)
create table if not exists adv_classes (
  key text primary key,
  parent text not null references char_classes(key) on delete cascade,
  name text not null, emoji text not null default '🌟', descr text, ability text,
  main_stat text not null, sub_stat text not null,
  min_lv int not null default 5, min_rank text not null default 'gold',
  sort int not null default 0, active boolean not null default true
);
create table if not exists class_mastery (
  student_id uuid not null references students(id) on delete cascade,
  class_key text not null,
  pts int not null default 0 check (pts >= 0),
  day date, day_pts int not null default 0,
  primary key (student_id, class_key)
);
alter table students add column if not exists adv_class text references adv_classes(key) on delete set null;

do $$ declare t text; begin
  foreach t in array array['adv_classes', 'class_mastery'] loop
    execute format('alter table %I enable row level security', t);
    execute format('drop policy if exists teacher_all on %I', t);
    execute format('create policy teacher_all on %I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on %I from anon', t);
    execute format('grant select, insert, update, delete on %I to authenticated', t);
  end loop;
end $$;

insert into adv_classes (key, parent, name, emoji, descr, ability, main_stat, sub_stat, sort) values
  ('alc_gold',  'alchemist', 'ปรมาจารย์ทองคำ',     '🪙', 'ยกระดับการแปรธาตุสู่ทองคำบริสุทธิ์',  'ขยัน +3 · โชค +1 · ไม้ตาย “ทองคำบริสุทธิ์” ฟื้น HP มาก', 'dil', 'luk', 1),
  ('alc_bomb',  'alchemist', 'จอมระเบิดสารเคมี',    '💣', 'ปฏิกิริยารุนแรง ทำลายล้างศัตรู',        'พลัง +3 · ขยัน +1 · ไม้ตาย “ระเบิดปฏิกิริยาลูกโซ่” ดาเมจสูง', 'str', 'dil', 2),
  ('sci_sage',  'scientist', 'นักวิจัยอัจฉริยะ',    '🔭', 'วิเคราะห์ทุกจุดอ่อนของศัตรู',           'ปัญญา +3 · ขยัน +1 · ไม้ตาย “สูตรสมบูรณ์” ศัตรูอ่อนแอ', 'int', 'dil', 3),
  ('sci_volt',  'scientist', 'ศาสตราจารย์สายฟ้า',   '⚡', 'ควบคุมพลังงานไฟฟ้าระดับสูง',            'พลัง +3 · ปัญญา +1 · ไม้ตาย “พายุสายฟ้า” ดาเมจสูง', 'str', 'int', 4),
  ('gua_knight','guardian',  'อัศวินโมล',          '🏰', 'ปราการที่ไม่มีวันล้ม',                 'ขยัน +3 · พลัง +1 · ไม้ตาย “ปราสาทฟื้นฟู” ฟื้น HP มาก', 'dil', 'str', 5),
  ('gua_light', 'guardian',  'ผู้พิทักษ์แห่งแสง',   '✨', 'โล่แห่งแสงปกป้องทุกคน',                'ปัญญา +3 · ขยัน +1 · ไม้ตาย “โล่แสงสว่าง” ลดดาเมจ', 'int', 'dil', 6),
  ('see_fate',  'seeker',    'จอมโชคชะตา',         '🎰', 'ทอยโชคให้เป็นใจ',                      'โชค +3 · ปัญญา +1 · ไม้ตาย “แจ็กพอตชะตา” คริติคอลสูง', 'luk', 'int', 7),
  ('see_hunt',  'seeker',    'นักล่าสมบัติ',        '🗝️', 'ล่าขุมทรัพย์ในทุกสมรภูมิ',             'โชค +3 · พลัง +1 · ไม้ตาย “ล่าสมบัติล้ำค่า” ดาเมจสูง', 'luk', 'str', 8)
on conflict (key) do nothing;

insert into battle_skills (key, class_key, name, emoji, kind, power, effect, cd, descr, sort) values
  ('alc_gold_u',  'alc_gold',  'ทองคำบริสุทธิ์',       '🪙', 'heal',   60, null,      4, 'ไม้ตายขั้นสูง: ฟื้นฟู HP มาก', 4),
  ('alc_bomb_u',  'alc_bomb',  'ระเบิดปฏิกิริยาลูกโซ่', '💣', 'attack', 40, null,      4, 'ไม้ตายขั้นสูง: ดาเมจสูงมาก', 4),
  ('sci_sage_u',  'sci_sage',  'สูตรสมบูรณ์',          '🔭', 'buff',    0, 'weak',    4, 'ไม้ตายขั้นสูง: มอนสเตอร์อ่อนแอ +40% นาน 3 เทิร์น', 4),
  ('sci_volt_u',  'sci_volt',  'พายุสายฟ้า',           '⚡', 'attack', 40, null,      4, 'ไม้ตายขั้นสูง: ดาเมจสูงมาก', 4),
  ('gua_knight_u','gua_knight','ปราสาทฟื้นฟู',         '🏰', 'heal',   62, null,      4, 'ไม้ตายขั้นสูง: ฟื้นฟู HP มาก', 4),
  ('gua_light_u', 'gua_light', 'โล่แสงสว่าง',          '✨', 'buff',    0, 'shield',  4, 'ไม้ตายขั้นสูง: ลดดาเมจที่ได้รับ 50% ใน 2 การโจมตี', 4),
  ('see_fate_u',  'see_fate',  'แจ็กพอตชะตา',          '🎰', 'attack', 36, 'crit',    4, 'ไม้ตายขั้นสูง: โอกาสคริติคอลสูงมาก', 4),
  ('see_hunt_u',  'see_hunt',  'ล่าสมบัติล้ำค่า',       '🗝️', 'attack', 40, null,      4, 'ไม้ตายขั้นสูง: ดาเมจสูงมาก', 4)
on conflict (key) do nothing;

-- สกิลในศึก = สกิลของคลาสพื้นฐาน + ไม้ตายของคลาสขั้นสูง (ถ้ามี)
create or replace function _battle_skillset(p_sid uuid) returns setof battle_skills
language sql stable security definer set search_path = public as $$
  select * from battle_skills
   where class_key is not distinct from (
     case when exists (select 1 from battle_skills k join students s on s.char_class = k.class_key where s.id = p_sid)
          then (select char_class from students where id = p_sid) else null end)
      or (class_key is not null and class_key = (select adv_class from students where id = p_sid))
   order by sort
$$;
revoke execute on function _battle_skillset(uuid) from public, anon, authenticated;

-- เปลี่ยนคลาสพื้นฐาน → ถอดคลาสขั้นสูง (ต้องตรงสายเดิม)
create or replace function trg_class_adv_reset() returns trigger language plpgsql as $$
begin
  if new.char_class is distinct from old.char_class and new.adv_class is not null
     and not exists (select 1 from adv_classes a where a.key = new.adv_class and a.parent = new.char_class) then
    new.adv_class := null;
  end if;
  return new;
end $$;
drop trigger if exists trg_class_adv_reset on students;
create trigger trg_class_adv_reset before update of char_class on students for each row execute function trg_class_adv_reset();
revoke execute on function trg_class_adv_reset() from public, anon, authenticated;

-- ---------- เลเวล / แต้ม ----------
create or replace function _class_lv(p_pts int) returns int
language sql immutable as $$
  select coalesce((select max(i) from unnest(array[0,20,50,90,140,200,280,380,500,650]) with ordinality t(v, i) where v <= greatest(p_pts, 0)), 1)::int
$$;
create or replace function _class_lv_need(p_lv int) returns int   -- แต้มสะสมที่ต้องมีเพื่อถึงเลเวลนั้น (null = เลเวลสูงสุดแล้ว)
language sql immutable as $$ select (array[0,20,50,90,140,200,280,380,500,650])[p_lv]::int $$;
revoke execute on function _class_lv(int), _class_lv_need(int) from public, anon, authenticated;

create or replace function _class_pts(p_sid uuid, p_n int) returns void
language plpgsql security definer set search_path = public as $$
declare ck text; d date := today_th(); cap int := _setting_int('class_pts_daily', 40); cur int; add int;
begin
  if p_n <= 0 then return; end if;
  select char_class into ck from students where id = p_sid;
  if ck is null then return; end if;
  insert into class_mastery (student_id, class_key, day) values (p_sid, ck, d) on conflict do nothing;
  select case when day = d then day_pts else 0 end into cur from class_mastery where student_id = p_sid and class_key = ck for update;
  add := least(p_n, greatest(0, cap - cur));
  if add > 0 then
    update class_mastery set pts = pts + add, day = d, day_pts = cur + add where student_id = p_sid and class_key = ck;
  end if;
end $$;
revoke execute on function _class_pts(uuid, int) from public, anon, authenticated;

-- ได้ EXP → ได้แต้มความชำนาญ
create or replace function trg_class_pts_ledger() returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.exp > 0 then perform _class_pts(new.student_id, ceil(new.exp::numeric / greatest(1, _setting_int('class_pts_exp_div', 5)))::int); end if;
  return new;
end $$;
drop trigger if exists trg_class_pts_ledger on ledger;
create trigger trg_class_pts_ledger after insert on ledger for each row execute function trg_class_pts_ledger();
revoke execute on function trg_class_pts_ledger() from public, anon, authenticated;

-- ชนะมอนสเตอร์ → แต้มความชำนาญ
create or replace function trg_class_pts_battle() returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'won' and old.status is distinct from 'won' then
    perform _class_pts(new.student_id, case when new.trial_rank is not null then _setting_int('class_pts_trial', 25) else _setting_int('class_pts_battle', 10) end);
  end if;
  return new;
end $$;
drop trigger if exists trg_class_pts_battle on battles;
create trigger trg_class_pts_battle after update on battles for each row execute function trg_class_pts_battle();
revoke execute on function trg_class_pts_battle() from public, anon, authenticated;

-- ---------- โบนัสสเตตัสจากคลาส ----------
create or replace function _class_bonus(p_sid uuid) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare s students%rowtype; m text; sb text; lv int; mp int := 0; r jsonb := jsonb_build_object('int', 0, 'dil', 0, 'str', 0, 'luk', 0); a adv_classes%rowtype;
begin
  select * into s from students where id = p_sid;
  if s.char_class is null then return r; end if;
  select main_stat, sub_stat into m, sb from char_classes where key = s.char_class;
  select _class_lv(coalesce((select pts from class_mastery where student_id = p_sid and class_key = s.char_class), 0)) into lv;
  mp := (lv + 1) / 2;
  if m is not null then r := jsonb_set(r, array[m], to_jsonb(mp)); end if;
  if sb is not null then r := jsonb_set(r, array[sb], to_jsonb(coalesce((r->>sb)::int, 0) + lv / 3)); end if;
  if s.adv_class is not null then
    select * into a from adv_classes where key = s.adv_class and parent = s.char_class;
    if found then
      -- คลาสขั้นสูงเปลี่ยนจุดโฟกัสเป็นของสายนั้น + โบนัสเพิ่ม
      r := jsonb_build_object('int', 0, 'dil', 0, 'str', 0, 'luk', 0);
      r := jsonb_set(r, array[a.main_stat], to_jsonb((lv + 1) / 2 + 3));
      r := jsonb_set(r, array[a.sub_stat], to_jsonb(coalesce((r->>a.sub_stat)::int, 0) + lv / 3 + 1));
    end if;
  end if;
  return r;
end $$;
revoke execute on function _class_bonus(uuid) from public, anon, authenticated;

-- ครอบ _stats อีกชั้น: บวกโบนัสคลาสเข้าสเตตัส + ผลลัพธ์ (effects)
do $$ begin
  if not exists (select 1 from pg_proc where proname = '_stats_rel' and pronamespace = 'public'::regnamespace) then
    alter function _stats(uuid) rename to _stats_rel;
  end if;
end $$;
revoke execute on function _stats_rel(uuid) from public, anon, authenticated;
create or replace function _stats(p_sid uuid) returns json
language plpgsql stable security definer set search_path = public as $$
declare r jsonb := _stats_rel(p_sid)::jsonb; cb jsonb := _class_bonus(p_sid); k numeric := _setting_int('stat_effect_pct', 50) / 100.0;
        ti int; td int; ts int; tl int; ci int := (cb->>'int')::int; cd int := (cb->>'dil')::int; cs int := (cb->>'str')::int; cl int := (cb->>'luk')::int;
        ef jsonb := r->'effects';
begin
  if ci + cd + cs + cl = 0 then return (r || jsonb_build_object('cls', cb))::json; end if;
  ti := (r->'int'->>'total')::int; td := (r->'dil'->>'total')::int; ts := (r->'str'->>'total')::int; tl := (r->'luk'->>'total')::int;
  ef := ef || jsonb_build_object(
    'quiz_exp', (ef->>'quiz_exp')::int + floor((ti + ci) / 2.0 * k)::int - floor(ti / 2.0 * k)::int,
    'exp_pct',  (ef->>'exp_pct')::int  + round((td + cd) * k)::int - round(td * k)::int,
    'boss_pct', (ef->>'boss_pct')::int + round(3 * (ts + cs) * k)::int - round(3 * ts * k)::int,
    'rare_pct', (ef->>'rare_pct')::int + round(3 * (tl + cl) * k)::int - round(3 * tl * k)::int);
  r := jsonb_set(r, '{int}', (r->'int') || jsonb_build_object('cls', ci, 'total', ti + ci));
  r := jsonb_set(r, '{dil}', (r->'dil') || jsonb_build_object('cls', cd, 'total', td + cd));
  r := jsonb_set(r, '{str}', (r->'str') || jsonb_build_object('cls', cs, 'total', ts + cs));
  r := jsonb_set(r, '{luk}', (r->'luk') || jsonb_build_object('cls', cl, 'total', tl + cl));
  return (r || jsonb_build_object('effects', ef, 'cls', cb))::json;
end $$;
revoke execute on function _stats(uuid) from public, anon, authenticated;

-- ---------- RPC นักเรียน ----------
create or replace function class_info(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); s students%rowtype; k char_classes%rowtype; v_pts int := 0; lv int; d date := today_th(); v_dp int := 0;
        cap int := _setting_int('class_pts_daily', 40); cb jsonb; res json;
begin
  select * into s from students where id = sid;
  select * into k from char_classes where key = s.char_class;
  if s.char_class is null then return json_build_object('class', null); end if;
  select m.pts, case when m.day = d then m.day_pts else 0 end into v_pts, v_dp from class_mastery m where m.student_id = sid and m.class_key = s.char_class;
  v_pts := coalesce(v_pts, 0); v_dp := coalesce(v_dp, 0); lv := _class_lv(v_pts); cb := _class_bonus(sid);
  return json_build_object(
    'class', json_build_object('key', k.key, 'name', k.name, 'emoji', k.emoji, 'main', k.main_stat, 'sub', k.sub_stat),
    'lv', lv, 'max_lv', 10, 'pts', v_pts, 'lv_from', _class_lv_need(lv), 'lv_next', case when lv >= 10 then null else _class_lv_need(lv + 1) end,
    'day_pts', v_dp, 'day_cap', cap, 'bonus', cb,
    'adv', (select json_build_object('key', a.key, 'name', a.name, 'emoji', a.emoji, 'descr', a.descr, 'ability', a.ability, 'main', a.main_stat, 'sub', a.sub_stat)
              from adv_classes a where a.key = s.adv_class and a.parent = s.char_class),
    'options', coalesce((select json_agg(json_build_object('key', a.key, 'name', a.name, 'emoji', a.emoji, 'descr', a.descr, 'ability', a.ability, 'main', a.main_stat, 'sub', a.sub_stat,
          'need_lv', a.min_lv, 'lv_ok', lv >= a.min_lv, 'need_rank', a.min_rank, 'need_rank_name', (select r.name from ch_ranks r where r.key = a.min_rank),
          'rank_ok', exists (select 1 from rank_trial_pass p join ch_ranks r on r.key = p.rank_key where p.student_id = sid and r.sort >= (select r2.sort from ch_ranks r2 where r2.key = a.min_rank)),
          'skill', (select json_build_object('name', b.name, 'emoji', b.emoji, 'descr', b.descr) from battle_skills b where b.class_key = a.key limit 1),
          'current', a.key = s.adv_class) order by a.sort)
        from adv_classes a where a.parent = s.char_class and a.active), '[]'::json),
    'switch_cost', _setting_int('class_change_cost', 100),
    'mastery', coalesce((select json_agg(json_build_object('key', c.key, 'name', c.name, 'emoji', c.emoji, 'pts', m.pts, 'lv', _class_lv(m.pts)) order by m.pts desc)
        from class_mastery m join char_classes c on c.key = m.class_key where m.student_id = sid and m.pts > 0), '[]'::json));
end $$;

create or replace function choose_adv(p_token uuid, p_key text) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); s students%rowtype; a adv_classes%rowtype; lv int; cost int := _setting_int('class_change_cost', 100); paid int := 0;
begin
  select * into s from students where id = sid for update;
  select * into a from adv_classes where key = p_key and active;
  if not found or a.parent is distinct from s.char_class then raise exception 'คลาสขั้นสูงนี้ใช้กับคลาสปัจจุบันไม่ได้'; end if;
  if s.adv_class = p_key then raise exception 'คุณเป็นคลาสขั้นสูงนี้อยู่แล้ว'; end if;
  lv := _class_lv(coalesce((select pts from class_mastery where student_id = sid and class_key = s.char_class), 0));
  if lv < a.min_lv then raise exception 'ต้องมีเลเวลคลาสอย่างน้อย % (ตอนนี้ %)', a.min_lv, lv; end if;
  if not exists (select 1 from rank_trial_pass p join ch_ranks r on r.key = p.rank_key where p.student_id = sid and r.sort >= (select r2.sort from ch_ranks r2 where r2.key = a.min_rank)) then
    raise exception 'ต้องผ่านด่านเลื่อนแรงค์ % ก่อน', (select name from ch_ranks where key = a.min_rank);
  end if;
  if s.adv_class is not null then
    if s.coins < cost then raise exception 'เหรียญไม่พอ (เปลี่ยนสายต้องใช้ % เหรียญ)', cost; end if;
    update students set coins = coins - cost where id = sid;
    insert into ledger (student_id, exp, coins, reason) values (sid, 0, -cost, 'เปลี่ยนคลาสขั้นสูงเป็น ' || a.name);
    paid := cost;
  end if;
  update students set adv_class = p_key where id = sid;
  return json_build_object('name', a.name, 'emoji', a.emoji, 'paid', paid);
end $$;
revoke execute on function class_info(uuid), choose_adv(uuid, text) from public;
grant execute on function class_info(uuid), choose_adv(uuid, text) to anon, authenticated;
