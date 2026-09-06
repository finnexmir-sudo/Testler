-- =====================================================================
--  smoke_keyfiyyet.sql : sual keyfiyyeti tehlili (db/134)
--
--  Iddialar: acar-subheli sual (distraktor duzden cox, gucluler sehv)
--  acar+menfi+cetin siqnali · normal sual yalniz "olu" (secilmeyen
--  variant) · n<20 siqnalsiz · admin siyahisi sira ile, suzgec, baxildi
--  · admin olmayan gore bilmir · muellim oz sualinin statistikasini
--  redaktorda gorur.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.question_stats;
delete from public.practice; delete from public.mistakes;
delete from public.attempt_answers;  delete from public.attempts;
delete from public.assignments;      delete from public.student_sessions;
delete from public.students;         delete from public.classes;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.question_options o using public.questions q where o.question_id = q.id and q.owner_type = 'educator';
delete from public.questions where owner_type = 'educator';
delete from public.subscriptions;
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-00000000c0b1','kf@t.az','{"full_name":"Keyfiyyet Admin"}'),
  ('11110000-0000-0000-0000-00000000c0b2','kf2@t.az','{"full_name":"Adi Muellim"}');
insert into public.user_roles (user_id, role) values ('11110000-0000-0000-0000-00000000c0b1', 'admin');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-00000000c0b1','tutor','KF hesabi','11110000-0000-0000-0000-00000000c0b1'),
  ('aaaa0000-0000-0000-0000-00000000c0b2','tutor','KF2 hesabi','11110000-0000-0000-0000-00000000c0b2');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-00000000c0b1','11110000-0000-0000-0000-00000000c0b1',true),
  ('aaaa0000-0000-0000-0000-00000000c0b2','11110000-0000-0000-0000-00000000c0b2',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-00000000c0b1','aaaa0000-0000-0000-0000-00000000c0b1',
   '11110000-0000-0000-0000-00000000c0b1','tutor_group','KF qrup','KODKF001');
--  25 sagird - yer limiti ucun abune (repetitor-25)
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-00000000c0b1', p.id, 'active', now() + interval '30 days'
  from public.plans p where p.slug = 'repetitor-25';
insert into public.students (account_id, class_id, created_by, full_name, display_name, login_code)
select 'aaaa0000-0000-0000-0000-00000000c0b1', 'cccc0000-0000-0000-0000-00000000c0b1',
       '11110000-0000-0000-0000-00000000c0b1', 'Sagird ' || i, 'S' || i || '.', 'KFST' || lpad(i::text, 4, '0')
  from generate_series(1, 25) i;

--  iki platforma suali (vurma testi) + muellimin oz suali
create or replace function pg_temp.opt(p_q uuid, p_ok boolean, p_k int) returns uuid language sql as $$
  select o.id from public.question_options o where o.question_id = p_q and o.is_correct = p_ok order by o.ord offset p_k limit 1 $$;
do $$
declare q1 uuid; q2 uuid; q3 uuid; t1 uuid; st record; i int := 0; att uuid; ok boolean; sel uuid; pc numeric;
begin
  select t.id into t1 from public.tests t where t.slug = 'riy-3-vurma-1';
  select tq.question_id into q1 from public.test_questions tq where tq.test_id = t1 order by tq.ord limit 1;
  select tq.question_id into q2 from public.test_questions tq where tq.test_id = t1 order by tq.ord offset 1 limit 1;
  perform set_config('smoke.q1', q1::text, false); perform set_config('smoke.q2', q2::text, false);
  --  oz sual (12 cavab - siqnalsiz)
  insert into public.questions (owner_type, owner_id, account_id, subject_id, kind, body, status, created_by)
  values ('educator', '11110000-0000-0000-0000-00000000c0b2', 'aaaa0000-0000-0000-0000-00000000c0b2',
          (select id from public.subjects where slug = 'riyaziyyat'), 'single', 'Oz sual 5+5', 'published',
          '11110000-0000-0000-0000-00000000c0b2') returning id into q3;
  insert into public.question_options (question_id, ord, body, is_correct) values (q3, 1, '10', true), (q3, 2, '11', false);
  perform set_config('smoke.q3', q3::text, false);
  for st in select s.id, row_number() over (order by s.login_code) rn from public.students s loop
    i := i + 1;
    --  guclu sagirdler (rn <= 15): faiz 80-95; zeifler: 30-50
    pc := case when st.rn <= 15 then 80 + st.rn else 30 + st.rn end;
    insert into public.attempts (student_id, test_id, class_id, status, finished_at, score, max_score, percent)
    values (st.id, t1, 'cccc0000-0000-0000-0000-00000000c0b1', 'submitted', now(), pc, 100, pc) returning id into att;
    --  Q1 "acar subheli": guclulerin hamisi ve zeiflerin coxu D1 secir; 4 nefer duz
    ok := st.rn in (16, 17, 18, 19);
    sel := case when ok then pg_temp.opt(q1, true, 0) else pg_temp.opt(q1, false, 0) end;
    insert into public.attempt_answers (attempt_id, question_id, selected_option_ids, is_correct, points)
    values (att, q1, array[sel], ok, case when ok then 1 else 0 end);
    --  Q2 normal: gucluler duz, zeifler D1 (D2, D3 hec secilmir)
    ok := st.rn <= 18;
    sel := case when ok then pg_temp.opt(q2, true, 0) else pg_temp.opt(q2, false, 0) end;
    insert into public.attempt_answers (attempt_id, question_id, selected_option_ids, is_correct, points)
    values (att, q2, array[sel], ok, case when ok then 1 else 0 end);
    --  Q3 oz sual: 12 cavab
    if st.rn <= 12 then
      ok := st.rn <= 9;
      sel := case when ok then pg_temp.opt(q3, true, 0) else pg_temp.opt(q3, false, 0) end;
      insert into public.attempt_answers (attempt_id, question_id, selected_option_ids, is_correct, points)
      values (att, q3, array[sel], ok, case when ok then 1 else 0 end);
    end if;
  end loop;
end $$;
\echo '--- hazirliq tamam'

-- =====================================================================
--  1. Hesablama: Q1 acar+menfi+cetin, Q2 yalniz olu, Q3 siqnalsiz
-- =====================================================================
do $$
declare r record; n int;
begin
  n := app.qstat_refresh();
  assert n = 3, 'uc sual hesablanmali: ' || n;
  select * into r from public.question_stats where question_id = current_setting('smoke.q1')::uuid;
  assert r.n = 25 and r.p = 16.0, 'q1 n/p: ' || r.n || '/' || r.p;
  assert r.rpb < 0, 'q1 menfi ayirdetme olmali: ' || r.rpb;
  assert r.flags @> array['acar','menfi','cetin'] and r.sev = 4, 'q1 siqnallar: ' || array_to_string(r.flags, ',');
  assert (select sum((o->>'n')::int) from jsonb_array_elements(r.opts) o) = 25, 'q1 variant sayi';
  assert (select (o->>'pct')::int from jsonb_array_elements(r.opts) o where (o->>'correct')::boolean) = 16, 'q1 duz variant 16%';
  select * into r from public.question_stats where question_id = current_setting('smoke.q2')::uuid;
  assert r.n = 25 and r.p = 72.0 and r.rpb > 0.5, 'q2 n/p/rpb: ' || r.n || '/' || r.p || '/' || r.rpb;
  assert r.flags = array['olu'] and r.sev = 1, 'q2 yalniz olu: ' || array_to_string(r.flags, ',');
  select * into r from public.question_stats where question_id = current_setting('smoke.q3')::uuid;
  assert r.n = 12 and r.p = 75.0 and cardinality(r.flags) = 0 and r.sev = 0, 'q3 siqnalsiz';
end $$;
\echo 'OK  1 · acar+menfi+cetin, olu, n<20 siqnalsiz'

-- =====================================================================
--  2. Admin siyahisi: sira, sayğaclar, suzgec, baxildi; admin olmayan gore bilmir
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-00000000c0b1';
do $$
declare v jsonb; t0 timestamptz;
begin
  v := public.rpc_admin_qstats(null, 50, false);
  assert (v->>'rated')::int = 2, 'rated 2: ' || (v->>'rated');
  --  q1-in de secilmeyen distraktorlari var - olu 2
  assert (v->'counts'->>'all')::int = 2 and (v->'counts'->>'acar')::int = 1 and (v->'counts'->>'olu')::int = 2
     and (v->'counts'->>'hidden')::int = 0, 'sayğaclar: ' || (v->'counts')::text;
  assert jsonb_array_length(v->'items') = 2 and v->'items'->0->>'question_id' = current_setting('smoke.q1'), 'sira: acar birinci';
  assert v->'items'->0->'options'->0 ? 'pct' and v->'items'->0->>'subject' is not null, 'kart melumati';
  v := public.rpc_admin_qstats('acar', 50, false);
  assert jsonb_array_length(v->'items') = 1 and v->'items'->0->>'question_id' = current_setting('smoke.q1'), 'suzgec acar';
  v := public.rpc_admin_qstats('olu', 50, false);
  assert jsonb_array_length(v->'items') = 2 and v->'items'->1->>'question_id' = current_setting('smoke.q2'), 'suzgec olu';
  --  baxildi
  perform public.rpc_admin_qstat_hide(current_setting('smoke.q2')::uuid, true);
  v := public.rpc_admin_qstats(null, 50, false);
  assert jsonb_array_length(v->'items') = 1 and (v->'counts'->>'hidden')::int = 1, 'baxildi siyahidan cixdi';
  v := public.rpc_admin_qstats('hidden', 50, false);
  assert jsonb_array_length(v->'items') = 1 and (v->'items'->0->>'hidden')::boolean, 'baxilanlar siyahisi';
  --  yeniden hesablama gizlini geri getirmir
  t0 := (v->>'computed_at')::timestamptz;
  perform pg_sleep(0.05);
  v := public.rpc_admin_qstats(null, 50, true);
  assert (v->>'computed_at')::timestamptz > t0 and jsonb_array_length(v->'items') = 1, 'yenile: gizli qalir';
  perform public.rpc_admin_qstat_hide(current_setting('smoke.q2')::uuid, false);
  v := public.rpc_admin_qstats(null, 50, false);
  assert jsonb_array_length(v->'items') = 2, 'geri qaytarildi';
end $$;
\echo 'OK  2 · admin siyahisi: sira, sayğaclar, suzgec, baxildi, yenile'

set request.jwt.claim.sub = '11110000-0000-0000-0000-00000000c0b2';
do $$
declare bad boolean := false; q jsonb;
begin
  begin perform public.rpc_admin_qstats(null, 50, false); exception when others then bad := true; end;
  assert bad, 'admin olmayan siyahini gordu';
  bad := false;
  begin perform public.rpc_admin_qstat_hide(current_setting('smoke.q1')::uuid, true); exception when others then bad := true; end;
  assert bad, 'admin olmayan gizletdi';
  --  muellim oz sualinin statistikasini gorur
  q := public.rpc_bank_question(current_setting('smoke.q3')::uuid);
  assert (q->'stats'->>'n')::int = 12 and (q->'stats'->>'p')::numeric = 75.0 and jsonb_array_length(q->'stats'->'flags') = 0,
         'oz sual statistikasi: ' || (q->'stats')::text;
end $$;
reset role;
\echo 'OK  3 · admin olmayan gore bilmir; muellim oz sualinin statistikasini gorur'

\echo 'KEYFIYYET: BUTUN YOXLAMALAR KECDI'
