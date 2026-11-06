-- รอบที่ 14: เลือกเพศตัวละคร (ชาย/หญิง) — ภาพตัวพื้นฐานของแต่ละคลาสมีทั้งสองเพศ (รันซ้ำได้)
--  ว่าง (null) = ใช้หน้าตาเดิมของคลาส · ชุดที่ยังไม่มีภาพของอีกเพศจะแสดงตัวพื้นฐานของเพศนั้นแทน
alter table students add column if not exists gender text;
do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'students_gender_chk') then
    alter table students add constraint students_gender_chk check (gender is null or gender in ('m','f'));
  end if;
end $$;

create or replace function _decor_of(p_sid uuid) returns json
language sql stable security definer set search_path = public as $$
  select (coalesce((select json_object_agg(d.slot, json_build_object('id', d.id, 'key', d.key, 'color', d.color,
           'emoji', d.emoji, 'name', d.name, 'rarity', d.rarity, 'image', d.image))
    from students s
    cross join lateral jsonb_each_text(s.decor) e
    join decor_items d on d.id = e.value::uuid and d.slot = e.key
   where s.id = p_sid), '{}'::json)::jsonb
   || jsonb_build_object('gender', (select gender from students where id = p_sid)))::json
$$;

create or replace function set_gender(p_token uuid, p_gender text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if p_gender is not null and p_gender not in ('m','f') then raise exception 'เพศไม่ถูกต้อง'; end if;
  update students set gender = p_gender where id = _sid(p_token);
end $$;

revoke execute on function _decor_of(uuid) from public, anon, authenticated;
revoke execute on function set_gender(uuid, text) from public;
grant execute on function set_gender(uuid, text) to anon, authenticated;
