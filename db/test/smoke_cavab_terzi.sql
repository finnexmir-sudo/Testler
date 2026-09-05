-- =====================================================================
--  smoke_cavab_terzi.sql : cavab terzi + "ne edim" (db/128)
--
--  Iddialar: s/c saheleri yazilir, kohne payload null qalir · hesabatda
--  style: hasty / guess_ok / sure_wrong · weak setrinde hasty ·
--  qrup hesabatinda movzunun weak_students siyahisi.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers;  delete from public.attempts;
delete from public.assignments;      delete from public.student_sessions;
delete from public.students;         delete from public.classes;
delete from public.subscriptions;
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-0000000000e1','ct@t.az','{"full_name":"Terz Muellim"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000e1','tutor','CT hesabi','11110000-0000-0000-0000-0000000000e1');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000e1','11110000-0000-0000-0000-0000000000e1',true);
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-0000000000e1', p.id, 'active', now() + interval '30 days'
  from public.plans p where p.slug = 'repetitor-25';
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-0000000000e1','aaaa0000-0000-0000-0000-0000000000e1',
   '11110000-0000-0000-0000-0000000000e1','tutor_group','CT qrup','KODCT001');
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code) values
  ('5555000e-0000-0000-0000-0000000000e1','aaaa0000-0000-0000-0000-0000000000e1',
   'cccc0000-0000-0000-0000-0000000000e1','11110000-0000-0000-0000-0000000000e1','Ayan Bir','Ayan B.','CTRZ0001'),
  ('5555000e-0000-0000-0000-0000000000e2','aaaa0000-0000-0000-0000-0000000000e1',
   'cccc0000-0000-0000-0000-0000000000e1','11110000-0000-0000-0000-0000000000e1','Murad Iki','Murad I.','CTRZ0002');

--  cavab siyahisi: p_ok = duz/sehv, p_s saniye, p_c eminlik (null = gonderilmir)
create or replace function pg_temp.cavab(p_test uuid, p_ok boolean, p_s int, p_c boolean) returns jsonb language sql as $$
  select coalesce(jsonb_agg(
           jsonb_build_object('q', q.id, 'o', jsonb_build_array(
             (select o.id from public.question_options o
               where o.question_id = q.id and o.is_correct = p_ok order by o.ord limit 1)))
           || case when p_s is null then '{}'::jsonb else jsonb_build_object('s', p_s) end
           || case when p_c is null then '{}'::jsonb else jsonb_build_object('c', p_c) end
         ), '[]'::jsonb)
    from public.test_questions tq join public.questions q on q.id = tq.question_id
   where tq.test_id = p_test
$$;

\echo '--- hazirliq tamam'

-- =====================================================================
--  1. Ayan: hamisi sehv, 3 saniye, "eminem" -> hasty ve sure_wrong
--     Murad: hamisi duz, 20 saniye, "emin deyilem" -> guess_ok;
--     kohne payload (s/c yox) -> null
-- =====================================================================
do $$
declare tok text; t1 uuid; att uuid; n int;
begin
  select id into t1 from public.tests where slug = 'riy-3-vurma-1';
  tok := public.rpc_student_login('CTRZ0001')->>'token';
  att := (public.rpc_start_attempt(tok, t1)->>'attempt_id')::uuid;
  perform public.rpc_submit_attempt(tok, att, pg_temp.cavab(t1, false, 3, true));
  select count(*) into n from public.attempt_answers where attempt_id = att and seconds = 3 and sure = true;
  assert n = (select count(*) from public.test_questions where test_id = t1), 'Ayan: s/c yazilmadi';

  tok := public.rpc_student_login('CTRZ0002')->>'token';
  att := (public.rpc_start_attempt(tok, t1)->>'attempt_id')::uuid;
  perform public.rpc_submit_attempt(tok, att, pg_temp.cavab(t1, true, 20, false));
  select count(*) into n from public.attempt_answers where attempt_id = att and seconds = 20 and sure = false;
  assert n > 0, 'Murad: s/c yazilmadi';

  --  kohne tetbiq: s/c yoxdur - null, xeta yox
  select id into t1 from public.tests where slug = 'riy-3-qarisiq-1';
  att := (public.rpc_start_attempt(tok, t1)->>'attempt_id')::uuid;
  perform public.rpc_submit_attempt(tok, att, pg_temp.cavab(t1, true, null, null));
  select count(*) into n from public.attempt_answers where attempt_id = att and seconds is null and sure is null;
  assert n > 0, 'kohne payload null olmali';
end $$;
\echo 'OK  1 · s/c yazilir; kohne payload null'

--  sual sayi rol deyismeden evvel (authenticated RLS ile test_questions-i gormur)
select set_config('smoke.nq', (select count(*)::text from public.test_questions tq
                                 join public.tests t on t.id = tq.test_id
                                where t.slug = 'riy-3-vurma-1'), false);

-- =====================================================================
--  2. Sagird hesabati: style sayğaclari ve weak setrinde hasty
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000e1';
do $$
declare v jsonb; nq int;
begin
  nq := current_setting('smoke.nq')::int;
  v := public.rpc_student_report('5555000e-0000-0000-0000-0000000000e1');
  assert (v->'style'->>'hasty')::int = nq, 'Ayan hasty = ' || (v->'style'->>'hasty');
  assert (v->'style'->>'sure_wrong')::int = nq, 'Ayan sure_wrong';
  assert (v->'style'->>'guess_ok')::int = 0, 'Ayan guess_ok 0';
  assert (v->'weak'->0->>'hasty')::int = 1 and (v->'weak'->0->>'sure_wrong')::int = 1, 'weak setri hasty/sure_wrong';
  v := public.rpc_student_report('5555000e-0000-0000-0000-0000000000e2');
  assert (v->'style'->>'guess_ok')::int = nq, 'Murad guess_ok = ' || (v->'style'->>'guess_ok');
  assert (v->'style'->>'hasty')::int = 0, 'Murad hasty 0';
  assert (v->'style'->>'n_meta')::int = nq, 'n_meta yalniz s olanlar';
end $$;
\echo 'OK  2 · style: hasty / guess_ok / sure_wrong; weak setrinde hasty'

-- =====================================================================
--  3. Qrup hesabati: movzuda zeif sagirdler adbaad (Ayan var, Murad yox)
-- =====================================================================
do $$
declare v jsonb; t jsonb;
begin
  v := public.rpc_class_report('cccc0000-0000-0000-0000-0000000000e1');
  select x into t from jsonb_array_elements(v->'topics') x
   where jsonb_array_length(x->'weak_students') > 0 limit 1;
  assert t is not null, 'weak_students bos';
  assert t->'weak_students'->0->>'name' = 'Ayan Bir', 'Ayan zeif olmali';
  assert jsonb_array_length(t->'weak_students') = 1, 'Murad zeif deyil';
end $$;
\echo 'OK  3 · qrup hesabatinda weak_students'
