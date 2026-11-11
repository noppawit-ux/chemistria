-- =====================================================================
-- 53: สถิติท้ายเกม + สถิติที่ดีที่สุดของแต่ละคน (ควิซ จับคู่ สเปลล์ KB เคมีรัน ต่อสู้ ดวล) · รันซ้ำได้
--  ใช้เพื่อ "แสดงผล" เท่านั้น — ไม่ผูกกับรางวัล (รางวัลยังคำนวณจากระบบเดิมฝั่งเซิร์ฟเวอร์)
-- =====================================================================
create table if not exists game_bests (
  student_id uuid not null references students(id) on delete cascade,
  game text not null, metric text not null,
  best numeric not null, updated_at timestamptz not null default now(),
  primary key (student_id, game, metric)
);
alter table game_bests enable row level security;
drop policy if exists teacher_all on game_bests;
create policy teacher_all on game_bests for all to authenticated using (is_teacher()) with check (is_teacher());
revoke all on game_bests from anon;

-- ตั้งต้นจากประวัติการเล่นเดิม (game_plays): จำนวนครั้ง + คะแนน/ตอบถูก/EXP สูงสุด
insert into game_bests (student_id, game, metric, best)
  select student_id, game, 'plays', count(*) from game_plays group by student_id, game on conflict do nothing;
insert into game_bests (student_id, game, metric, best)
  select student_id, 'quiz', 'correct', max(correct) from game_plays where game = 'quiz' and correct is not null group by student_id on conflict do nothing;
insert into game_bests (student_id, game, metric, best)
  select student_id, 'quiz', 'exp', max(exp) from game_plays where game = 'quiz' and exp > 0 group by student_id on conflict do nothing;
insert into game_bests (student_id, game, metric, best)
  select student_id, game, 'score', max(score) from game_plays where game in ('match', 'spell', 'run') and score > 0 group by student_id, game on conflict do nothing;

-- บันทึกผลรอบนี้ → คืนผลรอบนี้ / สถิติดีที่สุด / ตัวชี้วัดที่ทำลายสถิติ
create or replace function game_record(p_token uuid, p_game text, p_stats jsonb) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); g jsonb; k text; dir text; v numeric; old numeric; n numeric;
  cur jsonb := '{}'::jsonb; bst jsonb := '{}'::jsonb; nb text[] := '{}';
  cfg jsonb := '{"quiz":{"correct":"max","exp":"max","secs":"min"},
    "match":{"score":"max","secs":"min","wrong":"min"},
    "spell":{"score":"max","secs":"min","combo":"max","wrong":"min","hints":"min"},
    "kb":{"cleared":"max","secs":"min","wins":"sum"},
    "run":{"score":"max","dist":"max","secs":"max","combo":"max","coins":"max"},
    "battle":{"correct":"max","hp_left":"max","turns":"min","wins":"sum"},
    "duel":{"hp_left":"max","rounds":"min","wins":"sum"}}';
begin
  g := cfg -> p_game;
  if g is null then raise exception 'ไม่รู้จักเกมนี้'; end if;
  if p_stats is null or jsonb_typeof(p_stats) <> 'object' then raise exception 'ข้อมูลสถิติไม่ถูกต้อง'; end if;
  insert into game_bests (student_id, game, metric, best) values (sid, p_game, 'plays', 1)
    on conflict (student_id, game, metric) do update set best = game_bests.best + 1, updated_at = now() returning best into n;
  for k, dir in select key, value #>> '{}' from jsonb_each(g) loop
    begin v := (p_stats ->> k)::numeric; exception when others then v := null; end;
    if v is null then continue; end if;
    v := least(greatest(v, 0), case when k = 'secs' then 86400 else 100000 end);
    if k = 'secs' and v = 0 then continue; end if;
    select best into old from game_bests where student_id = sid and game = p_game and metric = k;
    if dir = 'sum' then
      if v > 0 then
        insert into game_bests (student_id, game, metric, best) values (sid, p_game, k, v)
          on conflict (student_id, game, metric) do update set best = game_bests.best + excluded.best, updated_at = now() returning best into old;
      end if;
      cur := cur || jsonb_build_object(k, v); bst := bst || jsonb_build_object(k, coalesce(old, 0));
      continue;
    end if;
    cur := cur || jsonb_build_object(k, v);
    if old is null or (dir = 'max' and v > old) or (dir = 'min' and v < old) then
      insert into game_bests (student_id, game, metric, best) values (sid, p_game, k, v)
        on conflict (student_id, game, metric) do update set best = excluded.best, updated_at = now();
      nb := nb || k; old := v;
    end if;
    bst := bst || jsonb_build_object(k, old);
  end loop;
  return json_build_object('game', p_game, 'plays', n, 'first', n <= 1, 'cur', cur, 'best', bst, 'newbest', to_json(nb));
end $$;
revoke execute on function game_record(uuid, text, jsonb) from public;
grant execute on function game_record(uuid, text, jsonb) to anon, authenticated;

-- สถิติดีที่สุดทั้งหมดของฉัน (ใช้แสดงในหน้าหลักของแต่ละเกม): {game: {metric: best}}
create or replace function game_bests_all(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token);
begin
  return coalesce((select json_object_agg(x.game, x.m) from (select game, json_object_agg(metric, best) m from game_bests where student_id = sid group by game) x), '{}'::json);
end $$;
revoke execute on function game_bests_all(uuid) from public;
grant execute on function game_bests_all(uuid) to anon, authenticated;
