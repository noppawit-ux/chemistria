-- =====================================================================
-- 52: ตรวจงานด้วย QR — นักเรียนโชว์ QR (เปลี่ยนรหัสทุก 30 วินาที) ครูสแกนแล้วบันทึกส่งงาน + คะแนน + EXP · รันซ้ำได้
-- =====================================================================
create table if not exists app_secrets (key text primary key, value text not null);
alter table app_secrets enable row level security;
revoke all on app_secrets from anon, authenticated;
insert into app_secrets (key, value) values ('qr', gen_random_uuid()::text || gen_random_uuid()::text) on conflict do nothing;

create or replace function _qr_sig(p_sid uuid, p_w bigint) returns text
language sql stable security definer set search_path = public as $$
  select left(encode(sha256(convert_to((select value from app_secrets where key = 'qr') || p_sid::text || ':' || p_w::text, 'utf8')), 'hex'), 20) $$;
revoke execute on function _qr_sig(uuid, bigint) from public, anon, authenticated;

-- นักเรียน: ขอ QR ของตัวเอง (หมดอายุเร็ว — แคปภาพส่งต่อไม่ได้)
create or replace function my_qr(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); w bigint := floor(extract(epoch from now()) / 30);
begin
  return json_build_object('code', 'KB1.' || sid || '.' || w || '.' || _qr_sig(sid, w), 'ttl', 30 - (extract(epoch from now())::bigint % 30));
end $$;
revoke execute on function my_qr(uuid) from public;
grant execute on function my_qr(uuid) to anon, authenticated;

-- ครู: สแกน QR แล้วบันทึกส่งงาน (ได้ EXP/เหรียญตามงานโดยอัตโนมัติ) · สแกนซ้ำ = ไม่ให้ซ้ำ
create or replace function admin_scan_submit(p_assignment uuid, p_code text, p_score numeric default null, p_status text default 'submitted')
returns json language plpgsql security definer set search_path = public as $$
declare a ch_assignments%rowtype; parts text[]; sid uuid; w bigint; nw bigint := floor(extract(epoch from now()) / 30);
        s students%rowtype; ex ch_submissions%rowtype;
begin
  if not is_teacher() then raise exception 'ไม่มีสิทธิ์'; end if;
  if p_status not in ('submitted', 'late') then raise exception 'สถานะไม่ถูกต้อง'; end if;
  select * into a from ch_assignments where id = p_assignment;
  if a.id is null then raise exception 'ไม่พบงาน'; end if;
  if p_score is not null and (p_score < 0 or p_score > a.max_score) then raise exception 'คะแนนต้องอยู่ระหว่าง 0–%', a.max_score; end if;
  parts := string_to_array(coalesce(p_code, ''), '.');
  if coalesce(array_length(parts, 1), 0) <> 4 or parts[1] <> 'KB1' then raise exception 'QR ไม่ถูกต้อง'; end if;
  begin sid := parts[2]::uuid; w := parts[3]::bigint; exception when others then raise exception 'QR ไม่ถูกต้อง'; end;
  if parts[4] <> _qr_sig(sid, w) then raise exception 'QR ไม่ถูกต้อง'; end if;
  if w < nw - 3 or w > nw + 1 then raise exception 'QR หมดอายุ — ให้นักเรียนเปิดใหม่'; end if;
  select * into s from students where id = sid;
  if s.id is null then raise exception 'ไม่พบนักเรียน'; end if;
  if s.class_id <> a.class_id then raise exception '% ไม่ใช่นักเรียนห้องของงานนี้', s.name; end if;
  select * into ex from ch_submissions where assignment_id = a.id and student_id = sid;
  if ex.id is not null and ex.status in ('submitted', 'late') then
    return json_build_object('ok', true, 'dup', true, 'sid', s.id, 'no', s.no, 'name', s.name, 'status', ex.status, 'score', ex.score);
  end if;
  insert into ch_submissions (assignment_id, student_id, status, score, via) values (a.id, sid, p_status, p_score, 'teacher')
  on conflict (assignment_id, student_id) do update set status = excluded.status, score = excluded.score, submitted_at = now(), via = 'teacher';
  return json_build_object('ok', true, 'dup', false, 'sid', s.id, 'no', s.no, 'name', s.name, 'status', p_status, 'score', p_score, 'exp', a.exp_reward, 'coins', a.coin_reward);
end $$;
revoke execute on function admin_scan_submit(uuid, text, numeric, text) from public, anon;
grant execute on function admin_scan_submit(uuid, text, numeric, text) to authenticated;
