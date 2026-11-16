-- 72: ระบบสอบเก็บคะแนน (เฟส 1) — สอบผ่านมือถือ/แท็บเล็ตที่โรงเรียน
--  ชนิดข้อ: mcq เลือกตอบ · tf จริง/เท็จ · short ข้อเขียน (พิมพ์ + แนบรูปที่วาดได้) · match จับคู่ · drag ลากวางใส่กลุ่ม
--  ต้องรันหลัง 71 · ไม่แตะข้อมูลเดิม · ผลสอบเข้า scores (สมุดคะแนนเดิม) เมื่อครูกด "ส่งคะแนน"
--
-- รูปแบบ data ของแต่ละชนิดข้อ (เก็บใน exam_questions.data — นักเรียนอ่านตรงๆ ไม่ได้):
--   mcq   {"choices":[{"t":"ข้อความ","img":"รูป"}], "answer":0}
--   tf    {"answer":true}
--   short {"answers":["2","สอง"], "review":true, "upload":true, "hint":"คำใบ้"}   (answers ว่าง = ครูตรวจเองทั้งหมด)
--   match {"left":[{"t","img"}], "right":[{"t","img"}], "pairs":[ดัชนี right ของแต่ละ left]}
--   drag  {"zones":[{"t","img"}], "items":[{"t","img"}], "answer":[ดัชนี zone ของแต่ละ item]}

create table if not exists exam_questions (
  id uuid primary key default gen_random_uuid(),
  topic text not null default 'ทั่วไป',
  kind text not null check (kind in ('mcq', 'tf', 'short', 'match', 'drag')),
  q text not null,
  img text,
  data jsonb not null default '{}'::jsonb,
  points numeric not null default 1 check (points >= 0),
  explain text,
  explain_img text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists exams (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  topic text,
  class_ids uuid[] not null default '{}',
  score_cat text not null default 'pre_mid' check (score_cat in ('pre_mid', 'midterm', 'post_mid', 'final', 'behavior', 'bonus')),
  max_score numeric not null default 10 check (max_score > 0),
  open_at timestamptz,
  close_at timestamptz,
  minutes int not null default 30 check (minutes between 1 and 240),
  shuffle boolean not null default true,
  max_attempts int not null default 1 check (max_attempts between 1 and 10),
  show_result text not null default 'after_close' check (show_result in ('after_submit', 'after_close', 'never')),
  reward_exp int not null default 0 check (reward_exp >= 0),
  status text not null default 'draft' check (status in ('draft', 'open', 'closed')),
  score_items jsonb not null default '{}'::jsonb,       -- {class_id: score_item_id} ที่ส่งคะแนนไปแล้ว
  pushed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists exam_items (
  exam_id uuid not null references exams(id) on delete cascade,
  qid uuid not null references exam_questions(id) on delete restrict,
  pos int not null default 0,
  points numeric check (points >= 0),                   -- null = ใช้คะแนนของข้อนั้น
  primary key (exam_id, qid)
);

create table if not exists exam_attempts (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references exams(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  no int not null default 1,
  started_at timestamptz not null default now(),
  deadline timestamptz not null,
  submitted_at timestamptz,
  status text not null default 'active' check (status in ('active', 'submitted')),
  perm jsonb not null default '{}'::jsonb,              -- {"order":[qid..], "q":{qid:{c|r|i:[..]}}} การสลับของแต่ละคน
  blur int not null default 0,
  score numeric,
  total numeric,
  needs_review boolean not null default false,
  unique (exam_id, student_id, no)
);
create index if not exists exam_attempts_exam on exam_attempts (exam_id);

create table if not exists exam_answers (
  attempt_id uuid not null references exam_attempts(id) on delete cascade,
  qid uuid not null references exam_questions(id) on delete restrict,
  ans jsonb,
  img text,                                             -- path รูปที่แนบใน bucket exam
  score numeric,
  graded boolean not null default false,
  manual boolean not null default false,                -- ครูให้คะแนนเอง (ตรวจใหม่อัตโนมัติจะไม่ทับ)
  note text,
  saved_at timestamptz not null default now(),
  primary key (attempt_id, qid)
);

create table if not exists exam_slots (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  attempt_id uuid not null references exam_attempts(id) on delete cascade,
  qid uuid not null,
  expires_at timestamptz not null default now() + interval '15 minutes',
  used boolean not null default false
);

do $$
declare t text;
begin
  foreach t in array array['exam_questions', 'exams', 'exam_items', 'exam_attempts', 'exam_answers', 'exam_slots'] loop
    execute format('alter table %I enable row level security', t);
    execute format('drop policy if exists teacher_all on %I', t);
    execute format('create policy teacher_all on %I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
    execute format('revoke all on %I from anon', t);
    execute format('grant select, insert, update, delete on %I to authenticated', t);
  end loop;
end $$;

insert into app_settings (key, value) values ('exam_grace_sec', '30') on conflict (key) do nothing;

-- ---------- Storage: รูปคำตอบของนักเรียน (private) + รูปโจทย์ของครู (public) ----------
create or replace function _exam_slot_ok(p_name text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from exam_slots where (id::text || '.jpg') = p_name and not used and expires_at > now())
$$;
revoke execute on function _exam_slot_ok(text) from public;
grant execute on function _exam_slot_ok(text) to anon, authenticated;

do $$
begin
  if to_regclass('storage.buckets') is not null then
    insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
    values ('exam', 'exam', false, 1572864, array['image/jpeg'])
    on conflict (id) do update set public = false, file_size_limit = 1572864, allowed_mime_types = array['image/jpeg'];
    insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
    values ('examimg', 'examimg', true, 2097152, array['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml'])
    on conflict (id) do update set public = true, file_size_limit = 2097152, allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml'];
    drop policy if exists chem_exam_upload on storage.objects;
    create policy chem_exam_upload on storage.objects for insert to anon, authenticated
      with check (bucket_id = 'exam' and public._exam_slot_ok(name));
    drop policy if exists chem_exam_teacher on storage.objects;
    create policy chem_exam_teacher on storage.objects for all to authenticated
      using (bucket_id in ('exam', 'examimg') and public.is_teacher()) with check (bucket_id in ('exam', 'examimg') and public.is_teacher());
    drop policy if exists chem_examimg_read on storage.objects;
    create policy chem_examimg_read on storage.objects for select to anon, authenticated using (bucket_id = 'examimg');
  end if;
exception when others then
  raise notice 'ตั้งค่า Storage ของระบบสอบไม่สำเร็จ (%): สร้าง bucket "exam" (Private) และ "examimg" (Public) เองใน Storage', sqlerrm;
end $$;

-- ---------- ฟังก์ชันภายใน ----------
-- สลับลำดับ 0..n-1 แบบสุ่ม (เป็น jsonb array)
create or replace function _exam_shuf(n int, p_on boolean) returns jsonb
language sql volatile as $$
  select coalesce(jsonb_agg(i order by case when p_on then random() else i end), '[]'::jsonb) from generate_series(0, n - 1) i
$$;

-- คะแนนต่อข้อของชุดสอบ
create or replace function _exam_pts(p_exam uuid, p_q uuid) returns numeric
language sql stable security definer set search_path = public as $$
  select coalesce(ei.points, q.points) from exam_items ei join exam_questions q on q.id = ei.qid where ei.exam_id = p_exam and ei.qid = p_q
$$;

-- มุมมองข้อสอบที่ส่งให้นักเรียน (ไม่มีเฉลย) ตามการสลับของ attempt นั้น
create or replace function _exam_qview(q exam_questions, pm jsonb, pts numeric) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare d jsonb := q.data; v jsonb := '{}'::jsonb; idx jsonb; e jsonb;
begin
  if q.kind = 'mcq' then
    select coalesce(jsonb_agg(d->'choices'->(x::int) order by o), '[]'::jsonb) into idx from jsonb_array_elements_text(pm->'c') with ordinality t(x, o);
    v := jsonb_build_object('choices', idx);
  elsif q.kind = 'match' then
    select coalesce(jsonb_agg(d->'right'->(x::int) order by o), '[]'::jsonb) into idx from jsonb_array_elements_text(pm->'r') with ordinality t(x, o);
    v := jsonb_build_object('left', d->'left', 'right', idx);
  elsif q.kind = 'drag' then
    select coalesce(jsonb_agg(d->'items'->(x::int) order by o), '[]'::jsonb) into idx from jsonb_array_elements_text(pm->'i') with ordinality t(x, o);
    v := jsonb_build_object('zones', d->'zones', 'items', idx);
  elsif q.kind = 'short' then
    v := jsonb_build_object('upload', coalesce((d->>'upload')::boolean, false), 'hint', d->>'hint');
  end if;
  return jsonb_build_object('id', q.id, 'kind', q.kind, 'q', q.q, 'img', q.img, 'topic', q.topic, 'points', pts, 'view', v);
end $$;

-- ตรวจ 1 ข้อ → {"f": เศษส่วนคะแนน 0..1, "graded": ตรวจเสร็จหรือยัง}
create or replace function _exam_grade_q(q exam_questions, pm jsonb, a jsonb) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare d jsonb := q.data; f numeric := 0; n int; ok int := 0; i int; r int; t text; acc text; hit boolean := false; cnt int;
begin
  if a is null then return jsonb_build_object('f', 0, 'graded', true); end if;
  if q.kind = 'mcq' then
    if a ? 'i' and (a->>'i') ~ '^\d+$' then
      f := case when (pm->'c'->>((a->>'i')::int)) is not null and (pm->'c'->>((a->>'i')::int))::int = (d->>'answer')::int then 1 else 0 end;
    end if;
  elsif q.kind = 'tf' then
    f := case when a ? 'v' and (a->>'v')::boolean = (d->>'answer')::boolean then 1 else 0 end;
  elsif q.kind = 'short' then
    t := lower(regexp_replace(coalesce(a->>'t', ''), '\s+', '', 'g'));
    cnt := jsonb_array_length(coalesce(d->'answers', '[]'::jsonb));
    if cnt = 0 then
      return jsonb_build_object('f', 0, 'graded', coalesce(a->>'t', '') = '' and not (a ? 'img'));      -- ว่างเปล่า = 0 คะแนนทันที
    end if;
    for acc in select lower(regexp_replace(x, '\s+', '', 'g')) from jsonb_array_elements_text(d->'answers') x loop
      if t <> '' and acc = t then hit := true; end if;
    end loop;
    if hit then return jsonb_build_object('f', 1, 'graded', true); end if;
    return jsonb_build_object('f', 0, 'graded', not (coalesce((d->>'review')::boolean, true) and (t <> '' or coalesce((d->>'upload')::boolean, false))));
  elsif q.kind = 'match' then
    n := jsonb_array_length(d->'left');
    for i in 0..n - 1 loop
      if a->'m'->>i is not null and (a->'m'->>i) ~ '^\d+$' then
        r := (pm->'r'->>((a->'m'->>i)::int))::int;
        if r is not null and r = (d->'pairs'->>i)::int then ok := ok + 1; end if;
      end if;
    end loop;
    f := case when n > 0 then ok::numeric / n else 0 end;
  elsif q.kind = 'drag' then
    n := jsonb_array_length(d->'items');
    for i in 0..n - 1 loop
      if a->'z'->>i is not null and (a->'z'->>i) ~ '^\d+$' then
        r := (pm->'i'->>i)::int;
        if (a->'z'->>i)::int = (d->'answer'->>r)::int then ok := ok + 1; end if;
      end if;
    end loop;
    f := case when n > 0 then ok::numeric / n else 0 end;
  end if;
  return jsonb_build_object('f', f, 'graded', true);
end $$;

-- ตรวจทั้งชุด (ข้ามข้อที่ครูให้คะแนนเองแล้ว) แล้วรวมคะแนน
create or replace function _exam_regrade(p_att uuid) returns void
language plpgsql security definer set search_path = public as $$
declare at exam_attempts%rowtype; qr exam_questions%rowtype; g jsonb; ans exam_answers%rowtype; tot numeric := 0; sc numeric := 0; need boolean := false; pts numeric;
begin
  select * into at from exam_attempts where id = p_att;
  for qr in select q.* from exam_items ei join exam_questions q on q.id = ei.qid where ei.exam_id = at.exam_id order by ei.pos loop
    pts := _exam_pts(at.exam_id, qr.id);
    tot := tot + pts;
    select * into ans from exam_answers where attempt_id = p_att and qid = qr.id;
    if not found then
      insert into exam_answers (attempt_id, qid, ans, score, graded) values (p_att, qr.id, null, 0, true);
      continue;
    end if;
    if ans.manual then
      sc := sc + coalesce(ans.score, 0);
      continue;
    end if;
    g := _exam_grade_q(qr, at.perm->'q'->(qr.id::text), case when ans.img is not null then coalesce(ans.ans, '{}'::jsonb) || jsonb_build_object('img', true) else ans.ans end);
    update exam_answers set score = round((g->>'f')::numeric * pts, 2), graded = (g->>'graded')::boolean where attempt_id = p_att and qid = qr.id;
    sc := sc + round((g->>'f')::numeric * pts, 2);
    if not (g->>'graded')::boolean then need := true; end if;
  end loop;
  update exam_attempts set score = sc, total = tot, needs_review = need or exists (select 1 from exam_answers where attempt_id = p_att and not graded) where id = p_att;
end $$;

-- ส่งข้อสอบ (ตรวจ + ให้ EXP เข้าสอบ)
create or replace function _exam_finish(p_att uuid) returns void
language plpgsql security definer set search_path = public as $$
declare at exam_attempts%rowtype; ex exams%rowtype;
begin
  select * into at from exam_attempts where id = p_att for update;
  if at.status = 'submitted' then return; end if;
  update exam_attempts set status = 'submitted', submitted_at = now() where id = p_att;
  perform _exam_regrade(p_att);
  select * into ex from exams where id = at.exam_id;
  if ex.reward_exp > 0 then
    perform award(at.student_id, ex.reward_exp, 0, 'เข้าสอบ: ' || ex.title, 'exam:' || ex.id);
  end if;
end $$;

-- ปิด attempt ที่หมดเวลา (เผื่อเวลาส่งอีกเล็กน้อย)
create or replace function _exam_expire(p_exam uuid default null) returns void
language plpgsql security definer set search_path = public as $$
declare r record;
begin
  for r in select id from exam_attempts where status = 'active' and (p_exam is null or exam_id = p_exam)
            and now() > deadline + make_interval(secs => _setting_int('exam_grace_sec', 30)) loop
    perform _exam_finish(r.id);
  end loop;
end $$;

-- สถานะเปิดสอบ: upcoming | open | closed
create or replace function _exam_state(e exams) returns text
language sql stable as $$
  select case when e.status = 'draft' then 'draft' when e.status = 'closed' then 'closed'
              when e.close_at is not null and now() > e.close_at then 'closed'
              when e.open_at is not null and now() < e.open_at then 'upcoming' else 'open' end
$$;

-- ผลสอบ/เฉลยเปิดให้นักเรียนดูได้หรือยัง
create or replace function _exam_visible(e exams, at exam_attempts) returns boolean
language sql stable as $$
  select at.status = 'submitted' and case e.show_result when 'after_submit' then true when 'after_close' then _exam_state(e) = 'closed' else false end
$$;

-- ---------- RPC นักเรียน ----------
create or replace function exam_list(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cid uuid; res jsonb := '[]'::jsonb; e exams%rowtype; atts jsonb; nq int; tot numeric; act uuid; best exam_attempts%rowtype; vis boolean;
begin
  select class_id into cid from students where id = sid;
  perform _exam_expire();
  for e in select * from exams where status <> 'draft' and cid = any (class_ids) order by coalesce(open_at, created_at) desc loop
    select count(*), coalesce(sum(coalesce(ei.points, q.points)), 0) into nq, tot from exam_items ei join exam_questions q on q.id = ei.qid where ei.exam_id = e.id;
    select coalesce(jsonb_agg(jsonb_build_object('id', a.id, 'no', a.no, 'status', a.status, 'submitted_at', a.submitted_at) order by a.no), '[]'::jsonb) into atts
      from exam_attempts a where a.exam_id = e.id and a.student_id = sid;
    select id into act from exam_attempts where exam_id = e.id and student_id = sid and status = 'active' limit 1;
    select * into best from exam_attempts where exam_id = e.id and student_id = sid and status = 'submitted' order by score desc nulls last limit 1;
    vis := best.id is not null and _exam_visible(e, best);
    res := res || jsonb_build_object('id', e.id, 'title', e.title, 'topic', e.topic, 'minutes', e.minutes, 'open_at', e.open_at, 'close_at', e.close_at,
      'state', _exam_state(e), 'nq', nq, 'total', tot, 'max_attempts', e.max_attempts, 'attempts', atts, 'active', act, 'show_result', e.show_result,
      'result', case when vis then jsonb_build_object('score', best.score, 'total', best.total, 'scaled', round(coalesce(best.score, 0) / nullif(best.total, 0) * e.max_score, 2),
                          'max', e.max_score, 'review', best.needs_review) else null end,
      'submitted', best.id is not null);
  end loop;
  return json_build_object('now', now(), 'exams', res);
end $$;

create or replace function _exam_payload(p_att uuid) returns json
language plpgsql security definer set search_path = public as $$
declare at exam_attempts%rowtype; e exams%rowtype; qs jsonb := '[]'::jsonb; qid uuid; q exam_questions%rowtype; a exam_answers%rowtype;
begin
  select * into at from exam_attempts where id = p_att;
  select * into e from exams where id = at.exam_id;
  for qid in select x::uuid from jsonb_array_elements_text(at.perm->'order') x loop
    select * into q from exam_questions where id = qid;
    select * into a from exam_answers where attempt_id = p_att and exam_answers.qid = q.id;
    qs := qs || (_exam_qview(q, at.perm->'q'->(q.id::text), _exam_pts(e.id, q.id)) || jsonb_build_object('ans', a.ans, 'photo', a.img is not null));
  end loop;
  return json_build_object('attempt', jsonb_build_object('id', at.id, 'no', at.no, 'deadline', at.deadline, 'now', now(), 'status', at.status),
    'exam', jsonb_build_object('id', e.id, 'title', e.title, 'minutes', e.minutes), 'qs', qs);
end $$;

create or replace function exam_start(p_token uuid, p_exam uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cid uuid; e exams%rowtype; at exam_attempts%rowtype; used int; pm jsonb; ord jsonb := '[]'::jsonb; qr record; n int; qmap jsonb := '{}'::jsonb; dl timestamptz;
begin
  select class_id into cid from students where id = sid;
  select * into e from exams where id = p_exam;
  if not found or not (cid = any (e.class_ids)) then raise exception 'ไม่พบข้อสอบนี้'; end if;
  perform _exam_expire(p_exam);
  select * into at from exam_attempts where exam_id = e.id and student_id = sid and status = 'active' limit 1;
  if found then return _exam_payload(at.id); end if;
  if _exam_state(e) <> 'open' then raise exception 'ข้อสอบนี้ยังไม่เปิดหรือปิดรับแล้ว'; end if;
  select count(*) into used from exam_attempts where exam_id = e.id and student_id = sid;
  if used >= e.max_attempts then raise exception 'คุณสอบครบจำนวนครั้งแล้ว'; end if;
  if not exists (select 1 from exam_items where exam_id = e.id) then raise exception 'ข้อสอบชุดนี้ยังไม่มีข้อ'; end if;
  -- ลำดับข้อ + การสลับตัวเลือกของแต่ละคน
  for qr in select q.* from exam_items ei join exam_questions q on q.id = ei.qid where ei.exam_id = e.id order by case when e.shuffle then random() else ei.pos end, ei.pos loop
    ord := ord || to_jsonb(qr.id::text);
    pm := '{}'::jsonb;
    if qr.kind = 'mcq' then pm := jsonb_build_object('c', _exam_shuf(jsonb_array_length(qr.data->'choices'), e.shuffle));
    elsif qr.kind = 'match' then pm := jsonb_build_object('r', _exam_shuf(jsonb_array_length(qr.data->'right'), e.shuffle));
    elsif qr.kind = 'drag' then pm := jsonb_build_object('i', _exam_shuf(jsonb_array_length(qr.data->'items'), e.shuffle)); end if;
    qmap := qmap || jsonb_build_object(qr.id::text, pm);
  end loop;
  dl := now() + make_interval(mins => e.minutes);
  if e.close_at is not null and e.close_at < dl then dl := e.close_at; end if;
  insert into exam_attempts (exam_id, student_id, no, deadline, perm) values (e.id, sid, used + 1, dl, jsonb_build_object('order', ord, 'q', qmap)) returning * into at;
  return _exam_payload(at.id);
end $$;

-- บันทึกคำตอบรายข้อ (เรียกบ่อย) — รับได้จนถึงเวลาหมด + เวลาผ่อนผัน
create or replace function exam_save(p_token uuid, p_attempt uuid, p_qid uuid, p_ans jsonb) returns void
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); at exam_attempts%rowtype;
begin
  select * into at from exam_attempts where id = p_attempt and student_id = sid;
  if not found or at.status <> 'active' then raise exception 'ส่งข้อสอบไปแล้วหรือหมดเวลา'; end if;
  if now() > at.deadline + make_interval(secs => _setting_int('exam_grace_sec', 30)) then raise exception 'หมดเวลาแล้ว'; end if;
  if not exists (select 1 from exam_items where exam_id = at.exam_id and qid = p_qid) then raise exception 'ไม่พบข้อนี้ในข้อสอบ'; end if;
  if length(coalesce(p_ans::text, '')) > 6000 then raise exception 'คำตอบยาวเกินไป'; end if;
  insert into exam_answers (attempt_id, qid, ans) values (p_attempt, p_qid, p_ans)
  on conflict (attempt_id, qid) do update set ans = excluded.ans, saved_at = now();
end $$;

create or replace function exam_blur(p_token uuid, p_attempt uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  update exam_attempts set blur = blur + 1 where id = p_attempt and student_id = _sid(p_token) and status = 'active';
end $$;

-- ขอช่องอัปโหลดรูปคำตอบ (ข้อเขียนที่เปิดให้แนบรูป)
create or replace function exam_slot(p_token uuid, p_attempt uuid, p_qid uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); at exam_attempts%rowtype; q exam_questions%rowtype; v uuid;
begin
  select * into at from exam_attempts where id = p_attempt and student_id = sid;
  if not found or at.status <> 'active' or now() > at.deadline + make_interval(secs => _setting_int('exam_grace_sec', 30)) then raise exception 'ส่งข้อสอบไปแล้วหรือหมดเวลา'; end if;
  select * into q from exam_questions where id = p_qid;
  if not found or q.kind <> 'short' or not coalesce((q.data->>'upload')::boolean, false) or not exists (select 1 from exam_items where exam_id = at.exam_id and qid = p_qid) then
    raise exception 'ข้อนี้ไม่ต้องแนบรูป';
  end if;
  delete from exam_slots where expires_at < now() - interval '1 day';
  insert into exam_slots (student_id, attempt_id, qid) values (sid, p_attempt, p_qid) returning id into v;
  return v;
end $$;

create or replace function exam_attach(p_token uuid, p_attempt uuid, p_qid uuid, p_slot uuid) returns void
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); path text := p_slot::text || '.jpg';
begin
  perform 1 from exam_slots where id = p_slot and student_id = sid and attempt_id = p_attempt and qid = p_qid and not used and expires_at > now();
  if not found then raise exception 'ช่องอัปโหลดหมดอายุ ลองใหม่อีกครั้ง'; end if;
  if to_regclass('storage.objects') is not null and not exists (select 1 from storage.objects where bucket_id = 'exam' and name = path) then
    raise exception 'ยังไม่พบรูปที่อัปโหลด ลองใหม่อีกครั้ง';
  end if;
  update exam_slots set used = true where id = p_slot;
  insert into exam_answers (attempt_id, qid, ans, img) values (p_attempt, p_qid, null, path)
  on conflict (attempt_id, qid) do update set img = excluded.img, saved_at = now();
end $$;

create or replace function exam_submit(p_token uuid, p_attempt uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); at exam_attempts%rowtype; e exams%rowtype;
begin
  select * into at from exam_attempts where id = p_attempt and student_id = sid;
  if not found then raise exception 'ไม่พบข้อสอบ'; end if;
  perform _exam_finish(at.id);
  select * into at from exam_attempts where id = p_attempt;
  select * into e from exams where id = at.exam_id;
  return json_build_object('submitted', true, 'visible', _exam_visible(e, at),
    'score', case when _exam_visible(e, at) then at.score end, 'total', case when _exam_visible(e, at) then at.total end);
end $$;

-- ทบทวนข้อสอบ + เฉลย (เมื่อเปิดผลแล้ว)
create or replace function exam_review(p_token uuid, p_exam uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); e exams%rowtype; at exam_attempts%rowtype; qs jsonb := '[]'::jsonb; q exam_questions%rowtype; a exam_answers%rowtype; qid uuid;
        pm jsonb; key jsonb; d jsonb; i int;
begin
  select * into e from exams where id = p_exam;
  if not found then raise exception 'ไม่พบข้อสอบ'; end if;
  select * into at from exam_attempts where exam_id = e.id and student_id = sid and status = 'submitted' order by score desc nulls last limit 1;
  if not found or not _exam_visible(e, at) then raise exception 'ยังไม่เปิดดูเฉลย'; end if;
  for qid in select x::uuid from jsonb_array_elements_text(at.perm->'order') x loop
    select * into q from exam_questions where id = qid;
    select * into a from exam_answers where attempt_id = at.id and exam_answers.qid = q.id;
    pm := at.perm->'q'->(q.id::text); d := q.data; key := 'null'::jsonb;
    if q.kind = 'mcq' then
      select to_jsonb(o - 1) into key from jsonb_array_elements_text(pm->'c') with ordinality t(x, o) where x::int = (d->>'answer')::int;
    elsif q.kind = 'tf' then key := d->'answer';
    elsif q.kind = 'short' then key := coalesce(d->'answers', '[]'::jsonb);
    elsif q.kind = 'match' then
      key := '[]'::jsonb;
      for i in 0..jsonb_array_length(d->'left') - 1 loop
        key := key || (select to_jsonb(o - 1) from jsonb_array_elements_text(pm->'r') with ordinality t(x, o) where x::int = (d->'pairs'->>i)::int);
      end loop;
    elsif q.kind = 'drag' then
      key := '[]'::jsonb;
      for i in 0..jsonb_array_length(d->'items') - 1 loop
        key := key || (d->'answer'->((pm->'i'->>i)::int));
      end loop;
    end if;
    qs := qs || (_exam_qview(q, pm, _exam_pts(e.id, q.id)) || jsonb_build_object('ans', a.ans, 'key', key, 'score', a.score, 'graded', a.graded, 'note', a.note,
                'explain', q.explain, 'explain_img', q.explain_img, 'has_photo', a.img is not null));
  end loop;
  return json_build_object('exam', jsonb_build_object('id', e.id, 'title', e.title, 'max', e.max_score),
    'score', at.score, 'total', at.total, 'review', at.needs_review, 'qs', qs);
end $$;

-- ---------- RPC ครู ----------
create or replace function exam_monitor(p_exam uuid) returns json
language plpgsql security definer set search_path = public as $$
declare e exams%rowtype; rows jsonb; qst jsonb;
begin
  if not is_teacher() then raise exception 'เฉพาะครู'; end if;
  select * into e from exams where id = p_exam;
  perform _exam_expire(p_exam);
  select coalesce(jsonb_agg(jsonb_build_object('sid', s.id, 'no', s.no, 'name', s.name, 'class', c.name, 'att', (
      select jsonb_agg(jsonb_build_object('id', a.id, 'no', a.no, 'status', a.status, 'score', a.score, 'total', a.total, 'blur', a.blur, 'review', a.needs_review,
             'started', a.started_at, 'submitted', a.submitted_at) order by a.no) from exam_attempts a where a.exam_id = e.id and a.student_id = s.id))
      order by c.name, s.no), '[]'::jsonb) into rows
    from students s join classes c on c.id = s.class_id where s.class_id = any (e.class_ids);
  select coalesce(jsonb_agg(jsonb_build_object('qid', q.id, 'q', q.q, 'kind', q.kind, 'pos', ei.pos, 'points', coalesce(ei.points, q.points),
      'n', (select count(*) from exam_answers a join exam_attempts t on t.id = a.attempt_id where t.exam_id = e.id and t.status = 'submitted' and a.qid = q.id),
      'avg', (select round(avg(a.score / nullif(coalesce(ei.points, q.points), 0)) * 100) from exam_answers a join exam_attempts t on t.id = a.attempt_id
               where t.exam_id = e.id and t.status = 'submitted' and a.qid = q.id and a.graded)) order by ei.pos), '[]'::jsonb) into qst
    from exam_items ei join exam_questions q on q.id = ei.qid where ei.exam_id = e.id;
  return json_build_object('rows', rows, 'qs', qst);
end $$;

create or replace function exam_attempt_detail(p_attempt uuid) returns json
language plpgsql security definer set search_path = public as $$
declare at exam_attempts%rowtype; e exams%rowtype; qs jsonb := '[]'::jsonb; q exam_questions%rowtype; a exam_answers%rowtype; qid uuid; pm jsonb; nm text;
begin
  if not is_teacher() then raise exception 'เฉพาะครู'; end if;
  select * into at from exam_attempts where id = p_attempt;
  if not found then raise exception 'ไม่พบการสอบ'; end if;
  select * into e from exams where id = at.exam_id;
  select name into nm from students where id = at.student_id;
  for qid in select x::uuid from jsonb_array_elements_text(at.perm->'order') x loop
    select * into q from exam_questions where id = qid;
    select * into a from exam_answers where attempt_id = at.id and exam_answers.qid = q.id;
    pm := at.perm->'q'->(q.id::text);
    qs := qs || (_exam_qview(q, pm, _exam_pts(e.id, q.id)) || jsonb_build_object('ans', a.ans, 'img_path', a.img, 'score', a.score, 'graded', a.graded, 'manual', a.manual,
                'note', a.note, 'key', q.data, 'perm', pm, 'explain', q.explain));
  end loop;
  return json_build_object('attempt', to_jsonb(at) - 'perm', 'student', nm, 'exam', e.title, 'qs', qs);
end $$;

create or replace function exam_grade(p_attempt uuid, p_qid uuid, p_score numeric, p_note text default null) returns void
language plpgsql security definer set search_path = public as $$
declare at exam_attempts%rowtype; pts numeric;
begin
  if not is_teacher() then raise exception 'เฉพาะครู'; end if;
  select * into at from exam_attempts where id = p_attempt;
  pts := _exam_pts(at.exam_id, p_qid);
  if p_score < 0 or p_score > pts then raise exception 'คะแนนต้องอยู่ระหว่าง 0 ถึง %', pts; end if;
  insert into exam_answers (attempt_id, qid, score, graded, manual, note) values (p_attempt, p_qid, p_score, true, true, nullif(p_note, ''))
  on conflict (attempt_id, qid) do update set score = excluded.score, graded = true, manual = true, note = nullif(p_note, '');
  update exam_attempts set score = (select coalesce(sum(score), 0) from exam_answers where attempt_id = p_attempt),
         needs_review = exists (select 1 from exam_answers where attempt_id = p_attempt and not graded) where id = p_attempt;
end $$;

-- ตรวจใหม่ทั้งชุดหลังแก้เฉลย (ข้อที่ครูให้คะแนนเองไม่ถูกทับ)
create or replace function exam_regrade(p_exam uuid) returns int
language plpgsql security definer set search_path = public as $$
declare r record; n int := 0;
begin
  if not is_teacher() then raise exception 'เฉพาะครู'; end if;
  for r in select id from exam_attempts where exam_id = p_exam and status = 'submitted' loop perform _exam_regrade(r.id); n := n + 1; end loop;
  return n;
end $$;

-- ปิดสอบทันที: ปิดการสอบที่ค้างอยู่ทั้งหมด
create or replace function exam_close(p_exam uuid) returns int
language plpgsql security definer set search_path = public as $$
declare r record; n int := 0;
begin
  if not is_teacher() then raise exception 'เฉพาะครู'; end if;
  update exams set status = 'closed' where id = p_exam;
  for r in select id from exam_attempts where exam_id = p_exam and status = 'active' loop perform _exam_finish(r.id); n := n + 1; end loop;
  return n;
end $$;

-- ส่งคะแนนเข้าสมุดคะแนน (score_items/scores) — ใช้คะแนนครั้งที่ดีที่สุด ปรับเป็นคะแนนเต็มของชุดสอบ
create or replace function exam_push(p_exam uuid, p_force boolean default false) returns json
language plpgsql security definer set search_path = public as $$
declare e exams%rowtype; cid uuid; iid uuid; map jsonb; n int := 0; pend int; r record;
begin
  if not is_teacher() then raise exception 'เฉพาะครู'; end if;
  select * into e from exams where id = p_exam;
  perform _exam_expire(p_exam);
  select count(*) into pend from exam_attempts where exam_id = p_exam and status = 'submitted' and needs_review;
  if pend > 0 and not p_force then raise exception 'ยังมี % การสอบที่รอตรวจข้อเขียน (ตรวจให้เสร็จก่อน หรือเลือกส่งทั้งที่ยังไม่ครบ)', pend; end if;
  map := e.score_items;
  foreach cid in array e.class_ids loop
    iid := nullif(map->>(cid::text), '')::uuid;
    if iid is null or not exists (select 1 from score_items where id = iid) then
      insert into score_items (class_id, category, title, max_score) values (cid, e.score_cat, e.title, e.max_score) returning id into iid;
      map := map || jsonb_build_object(cid::text, iid);
    else
      update score_items set max_score = e.max_score, title = e.title where id = iid;
    end if;
    for r in select distinct on (a.student_id) a.student_id, a.score, a.total from exam_attempts a join students s on s.id = a.student_id
              where a.exam_id = p_exam and a.status = 'submitted' and s.class_id = cid order by a.student_id, a.score desc nulls last loop
      insert into scores (item_id, student_id, score) values (iid, r.student_id, round(coalesce(r.score, 0) / nullif(r.total, 0) * e.max_score, 2))
      on conflict (item_id, student_id) do update set score = excluded.score;
      n := n + 1;
    end loop;
  end loop;
  update exams set score_items = map, pushed_at = now() where id = p_exam;
  return json_build_object('students', n, 'pending', pend);
end $$;

revoke execute on function _exam_shuf(int, boolean), _exam_pts(uuid, uuid), _exam_qview(exam_questions, jsonb, numeric), _exam_grade_q(exam_questions, jsonb, jsonb),
  _exam_regrade(uuid), _exam_finish(uuid), _exam_expire(uuid), _exam_state(exams), _exam_visible(exams, exam_attempts), _exam_payload(uuid) from public, anon, authenticated;
revoke execute on function exam_list(uuid), exam_start(uuid, uuid), exam_save(uuid, uuid, uuid, jsonb), exam_blur(uuid, uuid), exam_slot(uuid, uuid, uuid),
  exam_attach(uuid, uuid, uuid, uuid), exam_submit(uuid, uuid), exam_review(uuid, uuid) from public;
grant execute on function exam_list(uuid), exam_start(uuid, uuid), exam_save(uuid, uuid, uuid, jsonb), exam_blur(uuid, uuid), exam_slot(uuid, uuid, uuid),
  exam_attach(uuid, uuid, uuid, uuid), exam_submit(uuid, uuid), exam_review(uuid, uuid) to anon, authenticated;
revoke execute on function exam_monitor(uuid), exam_attempt_detail(uuid), exam_grade(uuid, uuid, numeric, text), exam_regrade(uuid), exam_close(uuid), exam_push(uuid, boolean) from public, anon;
grant execute on function exam_monitor(uuid), exam_attempt_detail(uuid), exam_grade(uuid, uuid, numeric, text), exam_regrade(uuid), exam_close(uuid), exam_push(uuid, boolean) to authenticated;
