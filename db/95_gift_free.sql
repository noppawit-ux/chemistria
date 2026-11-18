-- 95: ส่งของขวัญฟรีรายวัน (รันซ้ำได้)
--  · ทุกคนส่งของขวัญชิ้นเล็ก (ราคาไม่เกิน gift_free_max_price เหรียญ) ให้เพื่อนได้ฟรี วันละ gift_free_daily ครั้ง ไม่หักเหรียญ
--  · ยังนับรวมในลิมิตส่งต่อวัน (gift_daily_limit) และเพดาน RP ต่อคู่ต่อวัน (gift_pair_cap) เหมือนเดิม
--  · ตั้งค่า: app_settings gift_free_daily (ค่าเริ่มต้น 1 · ตั้ง 0 = ปิด) · gift_free_max_price (ค่าเริ่มต้น 30)
alter table gift_log add column if not exists free boolean not null default false;
insert into app_settings (key, value) values ('gift_free_daily', '1'), ('gift_free_max_price', '30') on conflict (key) do nothing;

create or replace function friend_list(p_token uuid) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); cid uuid; today date := today_th(); res json; cap int := _setting_int('gift_pair_cap', 40);
        fdaily int := _setting_int('gift_free_daily', 1); fused int;
begin
  select class_id into cid from students where id = sid;
  select count(*) into fused from gift_log where from_id = sid and free and (at at time zone 'Asia/Bangkok')::date = today;
  res := json_build_object(
    'coins', (select coins from students where id = sid),
    'gifts', coalesce((select json_agg(json_build_object('id', g.id, 'name', g.name, 'emoji', g.emoji, 'rarity', g.rarity, 'price', g.price, 'points', g.points, 'descr', g.descr) order by g.sort, g.price) from gift_items g where g.active), '[]'::json),
    'types', coalesce((select json_agg(json_build_object('key', t.key, 'name', t.name, 'emoji', t.emoji, 'need_rp', t.need_rp) order by t.need_rp, t.sort) from relation_types t where t.active), '[]'::json),
    'sent_today', (select count(*) from gift_log where from_id = sid and (at at time zone 'Asia/Bangkok')::date = today),
    'send_limit', _setting_int('gift_daily_limit', 5), 'pair_cap', cap,
    'free_daily', fdaily, 'free_left', greatest(0, fdaily - fused), 'free_max_price', _setting_int('gift_free_max_price', 30),
    'mates', coalesce((select json_agg(json_build_object('no', o.no, 'name', o.name, 'rp', coalesce(f.rp, 0), 'rel', f.rel, 'rel_name', t.name, 'rel_emoji', t.emoji,
          'day_left', greatest(0, cap - case when f.day = today then f.day_rp else 0 end),
          'pend', case when f.pend_rel is null then null else json_build_object('rel', f.pend_rel, 'name', pt.name, 'emoji', pt.emoji, 'by_me', f.pend_by = sid) end) order by o.no)
        from students o left join friendships f on f.a = (_rel_pair(sid, o.id))[1] and f.b = (_rel_pair(sid, o.id))[2]
        left join relation_types t on t.key = f.rel left join relation_types pt on pt.key = f.pend_rel
       where o.class_id = cid and o.id <> sid), '[]'::json),
    'inbox', coalesce((select json_agg(x) from (select json_build_object('from', o.name, 'emoji', l.emoji, 'name', l.name, 'msg', l.msg, 'points', l.points, 'at', l.at, 'seen', l.seen) x
        from gift_log l join students o on o.id = l.from_id where l.to_id = sid order by l.at desc limit 12) z), '[]'::json));
  update gift_log set seen = true where to_id = sid and not seen;
  return res;
end $$;

create or replace function gift_send(p_token uuid, p_to_no int, p_gift uuid, p_msg text default null) returns json
language plpgsql security definer set search_path = public as $$
declare sid uuid := _sid(p_token); me students%rowtype; o students%rowtype; g gift_items%rowtype; pr uuid[]; f friendships%rowtype; today date := today_th();
        cap int := _setting_int('gift_pair_cap', 40); lim int := _setting_int('gift_daily_limit', 5); sent int; used int; m text;
        fdaily int := _setting_int('gift_free_daily', 1); fused int; isfree boolean;
begin
  select * into me from students where id = sid for update;
  select * into o from students where class_id = me.class_id and no = p_to_no;
  if not found or o.id = sid then raise exception 'เลือกเพื่อนในห้องเดียวกันเท่านั้น'; end if;
  select * into g from gift_items where id = p_gift and active;
  if not found then raise exception 'ไม่พบของขวัญ'; end if;
  select count(*), count(*) filter (where free) into sent, fused from gift_log where from_id = sid and (at at time zone 'Asia/Bangkok')::date = today;
  if sent >= lim then raise exception 'วันนี้ส่งของขวัญครบ % ชิ้นแล้ว พรุ่งนี้ส่งใหม่ได้', lim; end if;
  isfree := fused < fdaily and g.price <= _setting_int('gift_free_max_price', 30);
  m := nullif(left(btrim(coalesce(p_msg, '')), 60), '');
  pr := _rel_pair(sid, o.id);
  insert into friendships (a, b) values (pr[1], pr[2]) on conflict (a, b) do nothing;
  select * into f from friendships where a = pr[1] and b = pr[2] for update;
  used := case when f.day = today then f.day_rp else 0 end;
  if used + g.points > cap then raise exception 'วันนี้ให้คะแนนมิตรภาพกับเพื่อนคนนี้ได้อีกแค่ % แต้ม (ลองของขวัญชิ้นเล็กลงหรือพรุ่งนี้)', greatest(cap - used, 0); end if;
  if not isfree then
    if me.coins < g.price then raise exception 'เหรียญไม่พอ (ต้องใช้ % เหรียญ)', g.price; end if;
    perform award(sid, 0, -g.price, 'ส่งของขวัญให้เพื่อน: ' || g.name, null);
  end if;
  update friendships set rp = rp + g.points, day = today, day_rp = used + g.points, updated_at = now() where a = pr[1] and b = pr[2];
  insert into gift_log (from_id, to_id, name, emoji, points, msg, free) values (sid, o.id, g.name, g.emoji, g.points, m, isfree);
  return json_build_object('to', o.name, 'gift', g.name, 'points', g.points, 'rp', f.rp + g.points, 'free', isfree);
end $$;
revoke execute on function friend_list(uuid), gift_send(uuid, int, uuid, text) from public;
grant execute on function friend_list(uuid), gift_send(uuid, int, uuid, text) to anon, authenticated;
