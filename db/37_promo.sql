-- 37: โปรโมชันเปิดระบบใหม่ (รันซ้ำได้) — ต้องรัน 09_stats.sql ก่อน
--  · ของขวัญเปิดระบบ (รับได้คนละ 1 ครั้ง): เหรียญ + EXP + ตั๋วกาชาฟรี
--  · EXP x2 (ค่าตั้งต้น) จากเช็คชื่อ/ส่งงาน/เควส ระหว่างโปร
--  ตั้งค่าได้ในแอดมิน → ตั้งค่า: promo_on, promo_until, promo_exp_mult, promo_coins, promo_exp, promo_pulls
insert into app_settings (key, value) values
  ('promo_on', '1'), ('promo_exp_mult', '2'), ('promo_coins', '200'), ('promo_exp', '50'), ('promo_pulls', '3'),
  ('promo_until', to_char(today_th() + 7, 'YYYY-MM-DD'))
on conflict (key) do nothing;

create or replace function _promo_until() returns date
language sql stable security definer set search_path = public as $$
  select case when coalesce((select value from app_settings where key = 'promo_on'), '0') = '1'
              then nullif((select value from app_settings where key = 'promo_until'), '')::date end
$$;
create or replace function _promo_mult() returns int
language sql stable security definer set search_path = public as $$
  select case when _promo_until() >= today_th() then greatest(1, _setting_int('promo_exp_mult', 1)) else 1 end
$$;
revoke execute on function _promo_until() from public, anon, authenticated;
revoke execute on function _promo_mult() from public, anon, authenticated;

create or replace function award(p_student uuid, p_exp int, p_coins int, p_reason text, p_ref text default null)
returns boolean language plpgsql security definer set search_path = public as $$
declare v uuid; pm int; cls text; e int := p_exp; c int := p_coins; rs text := p_reason; dil int; e2 int; cp int; c2 int;
begin
  -- ความสามารถคลาส: โบนัสเฉพาะรางวัลจากเช็คชื่อ / ส่งงาน / เควส
  if p_ref ~ '^(att|sub|quest):' then
    cls := student_class(p_student);
    if cls = 'scientist' and e > 0 then e := ceil(e * 1.15)::int; rs := rs || ' (โบนัสนักทดลอง)'; end if;
    if cls = 'alchemist' and c > 0 then c := ceil(c * 1.25)::int; rs := rs || ' (โบนัสนักเล่นแร่แปรธาตุ)'; end if;
    -- สเตตัสความขยัน: +1% ต่อแต้ม (เฉพาะรางวัลเช็คชื่อ/ส่งงาน/เควส)
    if e > 0 then
      dil := coalesce((_stats(p_student)->'dil'->>'total')::int, 0);
      e2 := round(e * (1 + dil / 100.0))::int;
      if e2 > e then e := e2; rs := rs || ' (ขยัน +' || dil || '%)'; end if;
    end if;
    -- โปรโมชัน: คูณ EXP (ตั้งใน app_settings: promo_exp_mult / promo_until)
    pm := _promo_mult();
    if pm > 1 and e > 0 then e := e * pm; rs := rs || ' (โปรเปิดระบบ x' || pm || ')'; end if;
    -- ความสามารถฉายา/ไอเทม: โบนัสเหรียญ %
    if c > 0 then
      cp := coalesce((_stats(p_student)->'effects'->>'coin_pct')::int, 0);
      c2 := round(c * (1 + cp / 100.0))::int;
      if c2 > c then c := c2; rs := rs || ' (เหรียญ +' || cp || '%)'; end if;
    end if;
  end if;
  insert into ledger (student_id, exp, coins, reason, ref_key)
  values (p_student, e, c, rs, p_ref)
  on conflict (student_id, ref_key) do nothing
  returning id into v;
  if v is null then return false; end if;
  update students
     set exp = greatest(0, exp + e),
         coins = greatest(0, coins + c)
   where id = p_student;
  return true;
end $$;
revoke execute on function award(uuid, int, int, text, text) from public, anon, authenticated;

create or replace function promo_status(p_token uuid) returns json
language plpgsql stable security definer set search_path = public as $$
declare sid uuid := _sid(p_token); u date := _promo_until();
begin
  if u is null or u < today_th() then return json_build_object('active', false); end if;
  return json_build_object('active', true, 'until', u, 'days_left', u - today_th() + 1,
    'mult', _promo_mult(),
    'gift', json_build_object('coins', _setting_int('promo_coins', 0), 'exp', _setting_int('promo_exp', 0), 'pulls', _setting_int('promo_pulls', 0)),
    'claimed', exists (select 1 from ledger where student_id = sid and ref_key = 'promo:launch'));
end $$;

create or replace function promo_claim(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); u date := _promo_until(); c int := _setting_int('promo_coins', 0);
        e int := _setting_int('promo_exp', 0); pl int := _setting_int('promo_pulls', 0); ok boolean;
begin
  if u is null or u < today_th() then raise exception 'โปรโมชันนี้สิ้นสุดแล้ว'; end if;
  ok := award(sid, e, c, 'ของขวัญเปิดระบบใหม่ 🎁', 'promo:launch');
  if not ok then raise exception 'รับของขวัญไปแล้ว'; end if;
  if pl > 0 then update students set free_pulls = free_pulls + pl where id = sid; end if;
  return json_build_object('coins', c, 'exp', e, 'pulls', pl);
end $$;
revoke execute on function promo_status(uuid) from public;
revoke execute on function promo_claim(uuid) from public;
grant execute on function promo_status(uuid) to anon, authenticated;
grant execute on function promo_claim(uuid) to anon, authenticated;

-- ให้ผู้สังเกตการณ์ (โหมดส่อง) เรียก promo_status ได้
create or replace function _sid(p_token uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare v uuid; o boolean; fn text;
begin
  select student_id, observer into v, o from student_sessions where token = p_token and expires_at > now();
  if v is null then raise exception 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่'; end if;
  if o then
    fn := regexp_replace(coalesce(current_setting('request.path', true), ''), '^.*/', '');
    if fn not in ('student_dashboard','student_extras','hall_of_fame','board_list','celebrations_feed','game_status','spell_status','kb_status','news_list','run_status','timetable_list','promo_status') then
      raise exception 'โหมดส่องนักเรียน: ดูได้อย่างเดียว';
    end if;
  end if;
  return v;
end $$;

-- ประกาศบนสไลด์ข่าว
insert into news_posts (kind, title, summary, body, image, sort, ends_at)
select 'event', 'โปรโมชันเปิดระบบใหม่ Chemistria! 🎉', 'รับของขวัญต้อนรับฟรี + EXP x2 จากเช็คชื่อ ส่งงาน และเควส ช่วงเปิดตัว',
 E'ฉลองเปิดระบบ Chemistria ใหม่!\n🎁 ของขวัญต้อนรับ: กดรับที่หน้าหลักได้คนละ 1 ครั้ง (เหรียญ + EXP + ตั๋วสุ่มกาชาฟรี)\n⚡ EXP x2 จากเช็คชื่อ ส่งงาน และเควส ตลอดช่วงโปร\nรีบกดรับก่อนโปรหมดนะ!',
 'assets/news/promo.jpg', 20, nullif((select value from app_settings where key = 'promo_until'), '')::date
where not exists (select 1 from news_posts where title = 'โปรโมชันเปิดระบบใหม่ Chemistria! 🎉');
