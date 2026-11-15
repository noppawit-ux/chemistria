-- 69: ด่านบอสเลื่อนแรงค์ — EXP ถึงเกณฑ์แรงค์หลักแล้ว ต้องชนะบอสด่านนั้นก่อนจึงเลื่อนแรงค์
-- ต้องรันหลัง 17 (battle), 21 (celebrate), 61 (guild_avatars) และ 68
-- กติกา: EXP ไม่หาย · แพ้/หนี = สอบใหม่ได้วันถัดไป (นับ 1 ครั้งต่อด่านต่อวัน) · นักเรียนที่ถึงแรงค์อยู่แล้วตอนรันไฟล์นี้ได้สิทธิ์ผ่านด่านให้โดยอัตโนมัติ

alter table monsters add column if not exists trial_rank text;   -- รหัสแรงค์ใน ch_ranks ที่มอนนี้เป็นบอสด่านเลื่อนแรงค์
alter table battles  add column if not exists trial_rank text;

create table if not exists rank_trial_pass (
  student_id uuid not null references students(id) on delete cascade,
  rank_key text not null,
  passed_at timestamptz not null default now(),
  primary key (student_id, rank_key)
);
alter table rank_trial_pass enable row level security;
drop policy if exists teacher_all on rank_trial_pass;
create policy teacher_all on rank_trial_pass for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on rank_trial_pass from anon;
grant select, insert, update, delete on rank_trial_pass to authenticated;

insert into app_settings (key, value) values ('rank_trial_on', '1'), ('rank_trial_coins', '50') on conflict (key) do nothing;

-- บอสด่านเลื่อนแรงค์ (Silver ขึ้นไป · Bronze เข้าฟรี) ครูแก้ HP/พลัง หรือปิด active เพื่อยกเลิกด่านนั้นได้ที่แท็บมอนสเตอร์
insert into monsters (key, name, emoji, level, hp, atk, exp, coins, atk_name, descr, sort, active, arena, trial_rank) values
 ('trial_silver',      'ผู้พิทักษ์ธาตุเงิน',     '🥈', 3, 170, 14, 0, 0, 'ประกายเงินวาบ',   'ด่านเลื่อนแรงค์ Silver',      900, true, 'lab', 'silver'),
 ('trial_gold',        'ราชันทองคำเรืองแสง',    '🥇', 4, 230, 16, 0, 0, 'คลื่นทองแผดเผา',  'ด่านเลื่อนแรงค์ Gold',        901, true, 'lab', 'gold'),
 ('trial_platinum',    'อสูรแพลทินัมไร้ปฏิกิริยา','⚪', 4, 310, 18, 0, 0, 'เกราะเฉื่อยทลาย',  'ด่านเลื่อนแรงค์ Platinum',    902, true, 'lab', 'platinum'),
 ('trial_emerald',     'มรกตพิษมรณะ',           '🟢', 4, 390, 20, 0, 0, 'ผลึกเขียวทิ่มแทง', 'ด่านเลื่อนแรงค์ Emerald',     903, true, 'lab', 'emerald'),
 ('trial_diamond',     'ราชาเพชรพันธะโควาเลนต์','💎', 5, 490, 22, 0, 0, 'แสงหักเหมรณะ',    'ด่านเลื่อนแรงค์ Diamond',     904, true, 'lab', 'diamond'),
 ('trial_master',      'จอมปราชญ์ตารางธาตุ',    '🧙', 5, 610, 24, 0, 0, 'สมการสะท้านฟ้า',  'ด่านเลื่อนแรงค์ Master',      905, true, 'lab', 'master'),
 ('trial_grandmaster', 'มหาอสูรปฏิกิริยาลูกโซ่', '☢️', 5, 770, 27, 0, 0, 'ระเบิดลูกโซ่',     'ด่านเลื่อนแรงค์ Grandmaster', 906, true, 'lab', 'grandmaster'),
 ('trial_challenger',  'ราชันย์แห่งเคมีนิรันดร์','👑', 5, 960, 30, 0, 0, 'พิโรธนิรันดร์',    'ด่านสุดท้าย Challenger',      907, true, 'lab', 'challenger')
on conflict (key) do nothing;

-- ---------- แกนกลาง ----------
-- รหัสแรงค์ที่ยังขวางอยู่ (EXP ถึงเกณฑ์แต่ยังไม่ผ่านด่าน) · null = ไม่มี
create or replace function _rank_gate(p_sid uuid, p_exp int) returns text
language sql stable security definer set search_path = public as $$
  select r.key from ch_ranks r
   where _setting_int('rank_trial_on', 1) = 1 and r.sort > 1 and r.min_exp <= greatest(p_exp, 0)
     and exists (select 1 from monsters m where m.trial_rank = r.key and m.active)
     and not exists (select 1 from rank_trial_pass p where p.student_id = p_sid and p.rank_key = r.key)
   order by r.sort limit 1
$$;
-- EXP ที่ใช้คำนวณแรงค์ (ถูกกั้นไว้ก่อนเกณฑ์ของด่านที่ยังไม่ผ่าน)
create or replace function _rank_exp(p_sid uuid, p_exp int) returns int
language sql stable security definer set search_path = public as $$
  select coalesce((select least(greatest(p_exp, 0), r.min_exp - 1) from ch_ranks r where r.key = _rank_gate(p_sid, p_exp)), p_exp)
$$;
-- rank_info + สถานะล็อกด่าน
create or replace function _rank_info_s(p_sid uuid, p_exp int) returns json
language plpgsql stable security definer set search_path = public as $$
declare g text := _rank_gate(p_sid, p_exp); gr ch_ranks%rowtype; j jsonb;
begin
  j := rank_info(case when g is null then p_exp else _rank_exp(p_sid, p_exp) end)::jsonb;
  if g is not null then
    select * into gr from ch_ranks where key = g;
    j := j || jsonb_build_object('locked', true, 'gate_key', gr.key, 'gate_name', gr.name, 'gate_image', gr.image, 'gate_exp', gr.min_exp);
  end if;
  return j::json;
end $$;
revoke execute on function _rank_gate(uuid, int), _rank_exp(uuid, int), _rank_info_s(uuid, int) from public, anon, authenticated;

-- ---------- ย้ายทุกจุดที่เรียก rank_info(x.exp) ไปใช้ตัวที่คิดด่านแล้ว ----------
do $$
declare f record; def text; n int := 0;
begin
  for f in select p.oid, p.proname from pg_proc p where p.pronamespace = 'public'::regnamespace and p.prokind = 'f'
            and p.proname not in ('rank_info', '_rank_info_s', '_rank_exp', '_rank_gate')
            and pg_get_functiondef(p.oid) ~ 'rank_info\(\w+\.exp\)' loop
    def := pg_get_functiondef(f.oid);
    def := regexp_replace(def, 'rank_info\((\w+)\.exp\)', '_rank_info_s(\1.id, \1.exp)', 'g');
    execute def; n := n + 1;
  end loop;
  if n = 0 and not exists (select 1 from pg_proc where proname = 'trg_cel_rank' and pg_get_functiondef(oid) like '%_rank_info_s%') then
    raise exception 'ไม่พบฟังก์ชันที่ต้องแก้ rank_info (ต้องรันไฟล์ก่อนหน้าให้ครบ)';
  end if;
end $$;

-- ซ่อนบอสด่านจากรายการมอนสเตอร์ปกติ + กันเริ่มสู้บอสด่านตรงๆ
do $$
declare d text;
begin
  select pg_get_functiondef('battle_status(uuid)'::regprocedure) into d;
  if d not like '%trial_rank%' then
    d := replace(d, 'from monsters m where m.active', 'from monsters m where m.active and m.trial_rank is null');
    if d not like '%m.trial_rank is null%' then raise exception 'แก้ battle_status ไม่สำเร็จ'; end if;
    execute d;
  end if;
  select pg_get_functiondef('battle_start(uuid,uuid)'::regprocedure) into d;
  if d not like '%trial_rank%' then
    d := replace(d, 'select * into m from monsters where id = p_monster and active;',
                    'select * into m from monsters where id = p_monster and active and (trial_rank is null or current_setting(''app.trial_ok'', true) = ''1'');');
    if d not like '%app.trial_ok%' then raise exception 'แก้ battle_start ไม่สำเร็จ'; end if;
    execute d;
  end if;
end $$;

-- ---------- ผ่านด่านเมื่อชนะบอส ----------
create or replace function trg_rank_trial() returns trigger
language plpgsql security definer set search_path = public as $$
declare st students%rowtype; gr ch_ranks%rowtype; ri json; c int := _setting_int('rank_trial_coins', 50);
begin
  if new.status = 'won' and old.status is distinct from 'won' and new.trial_rank is not null then
    insert into rank_trial_pass (student_id, rank_key) values (new.student_id, new.trial_rank) on conflict do nothing;
    if found then
      select * into gr from ch_ranks where key = new.trial_rank;
      if c > 0 then perform award(new.student_id, 0, c, 'ผ่านด่านเลื่อนแรงค์ ' || gr.name || ' 🎖️', 'trial:' || new.trial_rank); end if;
      select * into st from students where id = new.student_id;
      ri := _rank_info_s(st.id, st.exp);
      if _setting_int('celebrate_enabled', 1) = 1 then
        insert into celebrations (class_id, student_id, kind, title, image) values (st.class_id, st.id, 'rank', ri->>'name', ri->>'image');
      end if;
    end if;
  end if;
  return new;
end $$;
drop trigger if exists trial_win on battles;
create trigger trial_win after update of status on battles for each row execute function trg_rank_trial();
revoke execute on function trg_rank_trial() from public, anon, authenticated;

-- ---------- RPC นักเรียน ----------
create or replace function rank_trial_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); s students%rowtype; g text; r ch_ranks%rowtype; m monsters%rowtype; tried boolean := false; act text;
begin
  select * into s from students where id = sid;
  g := _rank_gate(sid, s.exp);
  select b.trial_rank into act from battles b where b.student_id = sid and b.status = 'active' and b.trial_rank is not null limit 1;
  if g is null then return json_build_object('gate', null, 'active_trial', act); end if;
  select * into r from ch_ranks where key = g;
  select * into m from monsters where trial_rank = g and active order by sort limit 1;
  select exists (select 1 from battles b where b.student_id = sid and b.trial_rank = g and b.play_date = today_th()) into tried;
  return json_build_object('gate', json_build_object('key', r.key, 'name', r.name, 'image', r.image, 'min_exp', r.min_exp),
    'exp', s.exp, 'extra', greatest(0, s.exp - r.min_exp + 1), 'reward_coins', _setting_int('rank_trial_coins', 50),
    'boss', json_build_object('id', m.id, 'name', m.name, 'emoji', m.emoji, 'image', m.image, 'level', m.level, 'hp', m.hp, 'atk', m.atk, 'descr', m.descr),
    'tried_today', tried and act is null, 'can_start', (not tried) or act is not null, 'active_trial', act);
end $$;

create or replace function rank_trial_start(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); s students%rowtype; g text; m monsters%rowtype; act uuid; r json; bid uuid;
begin
  select * into s from students where id = sid;
  select b.id into act from battles b where b.student_id = sid and b.status = 'active' and b.trial_rank is not null limit 1;
  if act is not null then return _battle_view(act); end if;
  g := _rank_gate(sid, s.exp);
  if g is null then raise exception 'ตอนนี้ไม่มีด่านเลื่อนแรงค์ที่ต้องสอบ'; end if;
  if exists (select 1 from battles b where b.student_id = sid and b.trial_rank = g and b.play_date = today_th()) then
    raise exception 'วันนี้สอบด่านนี้ไปแล้ว พรุ่งนี้มาลองใหม่ได้ (EXP ของคุณไม่หาย)';
  end if;
  select * into m from monsters where trial_rank = g and active order by sort limit 1;
  perform set_config('app.trial_ok', '1', true);
  r := battle_start(p_token, m.id);
  perform set_config('app.trial_ok', '0', true);
  bid := (r->>'id')::uuid;
  update battles set trial_rank = g, rewarded = false where id = bid;
  return _battle_view(bid);
end $$;

revoke execute on function rank_trial_status(uuid), rank_trial_start(uuid) from public;
grant execute on function rank_trial_status(uuid), rank_trial_start(uuid) to anon, authenticated;

-- ครู: ให้ผ่านด่าน/ยกเลิกสิทธิ์ผ่านด่านรายคน
create or replace function admin_rank_trial_pass(p_student uuid, p_rank text, p_pass boolean default true) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not is_teacher() then raise exception 'เฉพาะครู'; end if;
  if p_pass then insert into rank_trial_pass (student_id, rank_key) values (p_student, p_rank) on conflict do nothing;
  else delete from rank_trial_pass where student_id = p_student and rank_key = p_rank; end if;
end $$;
revoke execute on function admin_rank_trial_pass(uuid, text, boolean) from public, anon;
grant execute on function admin_rank_trial_pass(uuid, text, boolean) to authenticated;

-- ปลดล็อกย้อนหลัง: คนที่ถึงแรงค์ไปแล้วก่อนมีระบบนี้ ไม่ต้องกลับมาสอบ
insert into rank_trial_pass (student_id, rank_key)
select s.id, r.key from students s join ch_ranks r on r.min_exp <= s.exp where r.sort > 1
on conflict do nothing;
