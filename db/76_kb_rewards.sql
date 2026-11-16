-- 76: รางวัล + ความสำเร็จ "ชนะประลองครูบุ๊ค" (v2.15) · รันซ้ำได้
--  · Achievement ใหม่ 8 อัน (เล่นครั้งแรก / ผ่านครึ่งทาง / เกือบชนะ / ชนะ 1-3-10 ครั้ง / ชนะเร็ว ≤ 5 นาที)
--  · ชนะ (รอบที่ได้รางวัล) ดรอปยาสุ่ม 1 ชิ้น · ชนะครั้งแรกได้ฉายา "ผู้พิชิตครูบุ๊ค" + ม้วนอัปเกรด
--    ชนะครั้งที่ 3 / ทุก 5 ครั้งได้ม้วนอัปเกรดเพิ่ม · ชนะครบ 10 ครั้งได้กรอบ "กรอบแชมป์ครูบุ๊ค"
--  · ชนะนอกโควตารายวัน (ฝึกซ้อม) ไม่ได้ดรอปและไม่นับ Achievement

-- ---------- ตาราง ----------
alter table game_plays add column if not exists kb_secs int;
do $$ declare c text; begin
  for c in select conname from pg_constraint where conrelid = 'public.achievements'::regclass and contype = 'c' and pg_get_constraintdef(oid) like '%attendance_count%' loop
    execute format('alter table achievements drop constraint %I', c);
  end loop;
  alter table achievements add constraint achievements_metric_check check (metric in
    ('attendance_count','present_count','attendance_streak','ontime_submissions','total_exp','level','gacha_pulls','quests_done',
     'kb_plays','kb_cleared','kb_wins','kb_fast'));
  for c in select conname from pg_constraint where conrelid = 'public.student_decor'::regclass and contype = 'c' and pg_get_constraintdef(oid) like '%gacha%' loop
    execute format('alter table student_decor drop constraint %I', c);
  end loop;
  alter table student_decor add constraint student_decor_source_check check (source in ('shop','gacha','teacher','kb'));
end $$;

-- ---------- ตัวชี้วัดใหม่ ----------
do $$ declare def text; nd text; begin
  def := pg_get_functiondef('student_metric(uuid,text)'::regprocedure);
  if position('kb_wins' in def) > 0 then return; end if;
  if position(E'else n := 0;' in def) = 0 then raise exception 'student_metric: ไม่พบจุดแทนที่'; end if;
  nd := replace(def, E'else n := 0;', $r$when 'kb_plays' then
      select count(*) into n from game_plays where student_id = p_student and game = 'kb' and (exp > 0 or coins > 0);
    when 'kb_cleared' then
      select coalesce(max(case when score = 100 then 8 else score / 12 end), 0) into n from game_plays where student_id = p_student and game = 'kb' and (exp > 0 or coins > 0);
    when 'kb_wins' then
      select count(*) into n from game_plays where student_id = p_student and game = 'kb' and score = 100 and (exp > 0 or coins > 0);
    when 'kb_fast' then
      select count(*) into n from game_plays where student_id = p_student and game = 'kb' and score = 100 and (exp > 0 or coins > 0) and kb_secs is not null and kb_secs <= 300;
    else n := 0;$r$);
  execute nd;
end $$;

-- ---------- ของรางวัล ----------
insert into decor_items (slot, key, color, name, emoji, rarity, price, sort, st_int, st_dil, st_str, st_luk, st_coin)
select 'title', 'text', null, 'ผู้พิชิตครูบุ๊ค', '🏆', 'SSR', null, 900, 2, 0, 1, 1, 3
where not exists (select 1 from decor_items where slot = 'title' and name = 'ผู้พิชิตครูบุ๊ค');
insert into decor_items (slot, key, color, name, emoji, rarity, price, sort, st_int, st_dil, st_str, st_luk, st_coin)
select 'frame', 'solid', '#f5b301', 'กรอบแชมป์ครูบุ๊ค', '🥇', 'SSR', null, 901, 1, 1, 1, 1, 2
where not exists (select 1 from decor_items where slot = 'frame' and name = 'กรอบแชมป์ครูบุ๊ค');

insert into achievements (key, name, description, emoji, metric, threshold, reward_exp, reward_coins)
select * from (values
  ('kb_play_1',  'กล้าท้าครู',            'ลงสนามประลองครูบุ๊คครั้งแรก',               '⚔️', 'kb_plays',   1,  10, 5),
  ('kb_round4',  'ผ่านครึ่งทาง',           'ผ่านครบ 4 รอบในประลองครูบุ๊ค',               '🛡️', 'kb_cleared', 4,  30, 10),
  ('kb_round7',  'อีกแค่ก้าวเดียว',        'ผ่าน 7 รอบ เหลือแค่รอบสุดท้าย',              '🔥', 'kb_cleared', 7,  60, 20),
  ('kb_win_1',   'ล้มครูบุ๊คได้!',         'ชนะประลองครูบุ๊คครั้งแรก (ได้ฉายา ผู้พิชิตครูบุ๊ค)', '🏆', 'kb_wins', 1, 150, 50),
  ('kb_win_3',   'ศิษย์เอกท้าครู',         'ชนะครูบุ๊คครบ 3 ครั้ง',                      '🥋', 'kb_wins',    3,  200, 80),
  ('kb_win_10',  'ตำนานผู้พิชิตครูบุ๊ค',   'ชนะครูบุ๊คครบ 10 ครั้ง (ได้กรอบแชมป์)',        '👑', 'kb_wins',    10, 500, 200),
  ('kb_fast',    'สายฟ้าเคมี',             'ชนะครูบุ๊คภายใน 5 นาที',                     '⚡', 'kb_fast',    1,  120, 40)
) v(key, name, description, emoji, metric, threshold, reward_exp, reward_coins)
where not exists (select 1 from achievements a where a.key = v.key);

-- ---------- ตัวห่อ kb_submit: ตรวจเวลา (เดิม) → ส่งผล (_kb_submit) → ดรอป/Achievement ----------
create or replace function kb_submit(p_token uuid, p_cleared int, p_won boolean, p_seconds int) returns json
language plpgsql security definer set search_path = public as $$
declare
  sid uuid := _sid(p_token); r jsonb; before uuid[]; w int; cid uuid; drops jsonb := '[]'::jsonb; decs jsonb := '[]'::jsonb; ach jsonb;
  pot record; sc int := 0; did uuid;
begin
  perform _game_check(sid, 'kb', greatest(6, coalesce(p_cleared, 0) * 2), p_seconds);
  select array(select achievement_id from student_achievements where student_id = sid) into before;
  r := _kb_submit(p_token, p_cleared, p_won, p_seconds)::jsonb;
  update game_plays set kb_secs = p_seconds
   where id = (select id from game_plays where student_id = sid and game = 'kb' order by created_at desc, id limit 1);

  if p_won and not coalesce((r->>'no_reward')::boolean, false) then
    select count(*) into w from game_plays where student_id = sid and game = 'kb' and score = 100 and (exp > 0 or coins > 0);
    -- ยาสุ่ม 1 ชิ้นทุกครั้งที่ชนะ
    select * into pot from consumables where key in ('p_exp','p_coin','p_luck','p_str','p_int') and active order by random() limit 1;
    if pot.id is not null then
      insert into student_items (student_id, item_id, qty) values (sid, pot.id, 1)
        on conflict (student_id, item_id) do update set qty = student_items.qty + 1;
      drops := drops || jsonb_build_array(jsonb_build_object('emoji', pot.emoji, 'name', pot.name, 'qty', 1));
    end if;
    -- ม้วนอัปเกรด: ชนะครั้งแรก 1 · ครั้งที่ 3 → 1 · ทุก 5 ครั้ง → 2
    sc := case when w = 1 then 1 when w = 3 then 1 when w >= 5 and w % 5 = 0 then 2 else 0 end;
    if sc > 0 then
      select id into cid from consumables where key = 'scroll';
      if cid is not null then
        insert into student_items (student_id, item_id, qty) values (sid, cid, sc)
          on conflict (student_id, item_id) do update set qty = student_items.qty + sc;
        drops := drops || jsonb_build_array(jsonb_build_object('emoji', '📜', 'name', 'ม้วนอัปเกรด', 'qty', sc));
      end if;
    end if;
    -- ฉายา (ชนะครั้งแรก) · กรอบแชมป์ (ชนะ 10 ครั้ง)
    if w >= 1 then
      select id into did from decor_items where slot = 'title' and name = 'ผู้พิชิตครูบุ๊ค';
      if did is not null then
        insert into student_decor (student_id, item_id, source) values (sid, did, 'kb') on conflict do nothing;
        if found then decs := decs || jsonb_build_array(jsonb_build_object('emoji', '🏆', 'name', 'ฉายา ผู้พิชิตครูบุ๊ค')); end if;
      end if;
    end if;
    if w >= 10 then
      select id into did from decor_items where slot = 'frame' and name = 'กรอบแชมป์ครูบุ๊ค';
      if did is not null then
        insert into student_decor (student_id, item_id, source) values (sid, did, 'kb') on conflict do nothing;
        if found then decs := decs || jsonb_build_array(jsonb_build_object('emoji', '🥇', 'name', 'กรอบแชมป์ครูบุ๊ค')); end if;
      end if;
    end if;
    r := r || jsonb_build_object('wins', w);
  end if;

  perform check_achievements(sid);
  select coalesce(jsonb_agg(jsonb_build_object('emoji', a.emoji, 'name', a.name, 'exp', a.reward_exp, 'coins', a.reward_coins) order by a.threshold), '[]'::jsonb) into ach
    from student_achievements sa join achievements a on a.id = sa.achievement_id
   where sa.student_id = sid and a.metric like 'kb\_%' and sa.achievement_id <> all (before);
  return (r || jsonb_build_object('drops', drops, 'decors', decs, 'ach', ach))::json;
end $$;
revoke execute on function kb_submit(uuid, int, boolean, int) from public;
grant execute on function kb_submit(uuid, int, boolean, int) to anon, authenticated;
