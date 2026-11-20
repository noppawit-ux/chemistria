-- SQL 114 · ดันเจี้ยน: ระดับความยาก ⭐1–5 (แสดงป้ายดาวในหน้าเกม) · ต้องรันหลัง 110/111 · รันซ้ำได้
alter table dungeons add column if not exists stars int not null default 1 check (stars between 1 and 5);
update dungeons set stars = v.s from (values ('crystal_cave', 2), ('volcano_forge', 3), ('toxic_swamp', 4), ('space_lab', 5)) v(k, s) where dungeons.key = v.k;

create or replace function dungeon_status(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); lv int := level_for((select exp from students where id = sid)); cid uuid := (select class_id from students where id = sid);
        lim int := _setting_int('dungeon_runs_per_day', 2); used int; act uuid;
begin
  select count(*) into used from dungeon_runs where student_id = sid and run_date = today_th();
  select id into act from dungeon_runs where student_id = sid and status = 'active';
  return json_build_object('used', used, 'limit', lim, 'level', lv,
    'active', case when act is null then null else _dungeon_view(act) end,
    'dungeons', (select coalesce(json_agg(json_build_object('key', d.key, 'name', d.name, 'emoji', d.emoji, 'descr', d.descr,
        'floors', d.floors, 'stars', d.stars, 'min_level', d.min_level, 'locked', d.min_level > lv,
        'best', coalesce((select max(r.cleared) from dungeon_runs r where r.student_id = sid and r.dungeon_key = d.key), 0),
        'clears', (select count(*) from dungeon_runs r where r.student_id = sid and r.dungeon_key = d.key and r.status = 'cleared'),
        'map', (select coalesce(json_agg(json_build_object('floor', x.floor, 'boss', x.boss, 'bg', x.bg, 'exp', x.exp, 'coins', x.coins,
                  'monster', json_build_object('name', m.name, 'emoji', m.emoji, 'image', m.image)) order by x.floor), '[]'::json)
                  from dungeon_floors x join monsters m on m.key = x.monster_key where x.dungeon_key = d.key),
        'board', (select coalesce(json_agg(b order by b.best desc, b.clears desc, b.name), '[]'::json) from (
                    select st.name, st.avatar, max(r.cleared) as best, count(*) filter (where r.status = 'cleared') as clears, (st.id = sid) as mine
                      from dungeon_runs r join students st on st.id = r.student_id
                     where r.dungeon_key = d.key and st.class_id = cid and r.cleared > 0
                     group by st.id, st.name, st.avatar order by max(r.cleared) desc, count(*) filter (where r.status = 'cleared') desc, st.name limit 10) b)
      ) order by d.sort), '[]'::json) from dungeons d where d.active));
end $$;

revoke execute on function dungeon_status(uuid) from public;
grant execute on function dungeon_status(uuid) to anon, authenticated;
