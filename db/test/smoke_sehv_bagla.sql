-- =====================================================================
--  smoke_sehv_bagla.sql : sehv defteri movzu-movzu (210)
--
--  Iddialar: 'topics' movzu uzre gozleyen sual sayini verir; p_topic
--  suzgeci yalniz hemin movzunun suallarini qaytarir; p_limit isleyir;
--  kohne imza (tek parametr) QALMAYIB - anon sayi pozulmasin.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

--  kohne imza qalmamalidir (drop edilib)
do $$
declare v_n int;
begin
  select count(*) into v_n from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'rpc_student_mistakes';
  if v_n <> 1 then
    raise exception '210: rpc_student_mistakes % imza (1 gozlenilir)', v_n;
  end if;
end $$;
\echo 'OK  1 · (210) tək imza qalıb (köhnəsi drop edilib)'

delete from public.mistakes;
delete from public.student_sessions;
delete from public.students where login_code = 'SBAG0001';
delete from public.classes where join_code = 'KODSB001';
delete from public.accounts where name = 'SB hesabi';

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-0000000005b1','sb@t.az','{"full_name":"SB Muellim"}')
on conflict (id) do nothing;
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000005b1','tutor','SB hesabi','11110000-0000-0000-0000-0000000005b1')
on conflict (id) do nothing;
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000005b1','11110000-0000-0000-0000-0000000005b1',true)
on conflict do nothing;
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-0000000005b1','aaaa0000-0000-0000-0000-0000000005b1',
   '11110000-0000-0000-0000-0000000005b1','tutor_group','SB qrup','KODSB001')
on conflict (id) do nothing;
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code) values
  ('5555000c-0000-0000-0000-0000000005b1','aaaa0000-0000-0000-0000-0000000005b1',
   'cccc0000-0000-0000-0000-0000000005b1','11110000-0000-0000-0000-0000000005b1','SB Sagird','SB S.','SBAG0001')
on conflict (id) do nothing;
insert into public.student_sessions (token_hash, student_id, expires_at)
values (app.hash_token('sb-token'),'5555000c-0000-0000-0000-0000000005b1', now() + interval '1 day')
on conflict (token_hash) do nothing;

--  Iki movzudan sehv: birincide 3, ikincide 1
do $$
declare v_t1 uuid; v_t2 uuid; q record; k int := 0;
begin
  select t.id into v_t1 from public.topics t
   where exists (select 1 from public.questions q2 where q2.topic_id = t.id and q2.status = 'published'
                   and (select count(*) from public.question_options o where o.question_id = q2.id) > 1)
   order by t.name limit 1;
  select t.id into v_t2 from public.topics t
   where t.id <> v_t1
     and exists (select 1 from public.questions q2 where q2.topic_id = t.id and q2.status = 'published'
                   and (select count(*) from public.question_options o where o.question_id = q2.id) > 1)
   order by t.name limit 1;
  perform set_config('smoke.t1', v_t1::text, false);
  perform set_config('smoke.t2', v_t2::text, false);
  for q in select id from public.questions where topic_id = v_t1 and status = 'published' limit 3 loop
    insert into public.mistakes (student_id, question_id, status, next_at)
    values ('5555000c-0000-0000-0000-0000000005b1', q.id, 'open', now() - interval '1 hour')
    on conflict do nothing;
    k := k + 1;
  end loop;
  if k < 3 then raise exception '210 test fikstur: birinci movzuda 3 sual lazimdir (%)', k; end if;
  for q in select id from public.questions where topic_id = v_t2 and status = 'published' limit 1 loop
    insert into public.mistakes (student_id, question_id, status, next_at)
    values ('5555000c-0000-0000-0000-0000000005b1', q.id, 'open', now() - interval '1 hour')
    on conflict do nothing;
  end loop;
end $$;

--  211: mesq abune paketine daxildir - 2-4-cu bolmeler ucun abune acilir
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-0000000005b1', id, 'active', now() + interval '30 days'
  from public.plans where slug = 'repetitor-25'
on conflict do nothing;

set role anon;
-- =====================================================================
--  2. 'topics': movzu uzre gozleyen sual sayi
-- =====================================================================
do $$
declare r jsonb; a jsonb;
begin
  r := public.rpc_student_mistakes('sb-token');
  assert (r->>'due')::int = 4, '210 due: ' || r::text;
  assert jsonb_array_length(r->'topics') = 2, '210 movzu sayi: ' || (r->'topics')::text;
  --  en cox gozleyen birinci
  a := r->'topics'->0;
  assert (a->>'due')::int = 3 and a->>'id' = current_setting('smoke.t1'), '210 sira: ' || (r->'topics')::text;
  assert a->>'name' is not null, '210 movzu adi yoxdur';
  assert jsonb_array_length(r->'items') = 4, '210 butun suallar: ' || (r->'items')::text;
end $$;
\echo 'OK  2 · (210) mövzu üzrə sayğac, ən çox gözləyən birinci'

-- =====================================================================
--  3. p_topic suzgeci + p_limit
-- =====================================================================
do $$
declare r jsonb; v_t2 uuid := current_setting('smoke.t2')::uuid;
begin
  r := public.rpc_student_mistakes('sb-token', current_setting('smoke.t1')::uuid, 3);
  assert jsonb_array_length(r->'items') = 3, '210 movzu suzgeci: ' || (r->'items')::text;
  r := public.rpc_student_mistakes('sb-token', v_t2, 3);
  assert jsonb_array_length(r->'items') = 1, '210 ikinci movzu: ' || (r->'items')::text;
  --  limit
  r := public.rpc_student_mistakes('sb-token', current_setting('smoke.t1')::uuid, 2);
  assert jsonb_array_length(r->'items') = 2, '210 limit: ' || (r->'items')::text;
  --  duz cavab GETMIR
  assert not (r->'items'->0->'options'->0 ? 'correct'), '210 duz variant sizdi!';
end $$;
\echo 'OK  3 · (210) mövzu süzgəci və limit işləyir, düz cavab sızmır'

-- =====================================================================
--  4. Yanlis token
-- =====================================================================
do $$
begin
  begin
    perform public.rpc_student_mistakes('yoxdur', null, 3);
    raise exception '210: yanlis token kecdi';
  exception when sqlstate '28000' then null; end;
end $$;
reset role;
delete from public.mistakes where student_id = '5555000c-0000-0000-0000-0000000005b1';
\echo 'OK  4 · (210) yanlış token rədd edilir'
\echo ''
\echo '=============================='
\echo ' SEHV BAGLA: HAMISI KECDI'
\echo '=============================='

-- =====================================================================
--  5. (211) Abune qapisi: sayğaclar gorunur, mesq baglidir
-- =====================================================================
reset role;
delete from public.subscriptions where account_id = 'aaaa0000-0000-0000-0000-0000000005b1';
--  fikstur yeniden (4-cu bolmede silinmisdi)
do $$
declare v_t1 uuid := current_setting('smoke.t1')::uuid; q record;
begin
  for q in select id from public.questions where topic_id = v_t1 and status = 'published' limit 3 loop
    insert into public.mistakes (student_id, question_id, status, next_at)
    values ('5555000c-0000-0000-0000-0000000005b1', q.id, 'open', now() - interval '1 hour')
    on conflict (student_id, question_id) do update set status = 'open', next_at = now() - interval '1 hour';
  end loop;
end $$;
set role anon;
do $$
declare r jsonb;
begin
  r := public.rpc_student_mistakes('sb-token');
  assert (r->>'paid')::boolean = false, '211 paid bayragi: ' || r::text;
  --  usaq NE ITIRDIYINI gorur: sayğaclar ve movzu siyahisi qalir
  assert (r->>'due')::int = 3, '211 sayğac gorunmelidir: ' || r::text;
  assert jsonb_array_length(r->'topics') = 1, '211 movzu siyahisi gorunmelidir: ' || (r->'topics')::text;
  --  amma suallar GELMIR
  assert jsonb_array_length(r->'items') = 0, '211 abunesiz sual gondermemelidir: ' || (r->'items')::text;
end $$;
--  cavab yazmaq da baglidir (cedvel oxumaq ucun anon-dan cixiriq)
reset role;
do $$
declare v_q uuid;
begin
  select question_id into v_q from public.mistakes
   where student_id = '5555000c-0000-0000-0000-0000000005b1' limit 1;
  perform set_config('smoke.q211', v_q::text, false);
end $$;
set role anon;
do $$
begin
  begin
    perform public.rpc_student_mistake_answer('sb-token',
      current_setting('smoke.q211')::uuid, gen_random_uuid());
    raise exception '211: abunesiz cavab yazildi';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
--  abune acilir: her sey qayidir
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-0000000005b1', id, 'active', now() + interval '30 days'
  from public.plans where slug = 'repetitor-25';
set role anon;
do $$
declare r jsonb;
begin
  r := public.rpc_student_mistakes('sb-token');
  assert (r->>'paid')::boolean, '211 abune sonra paid true olmali';
  assert jsonb_array_length(r->'items') = 3, '211 abune sonra suallar gelmeli: ' || (r->'items')::text;
end $$;
reset role;
delete from public.subscriptions where account_id = 'aaaa0000-0000-0000-0000-0000000005b1';
delete from public.mistakes where student_id = '5555000c-0000-0000-0000-0000000005b1';
\echo 'OK  5 · (211) abunəsiz: sayğac görünür, məşq bağlı; abunə ilə açılır'
