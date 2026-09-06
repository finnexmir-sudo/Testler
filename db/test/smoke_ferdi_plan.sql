-- =====================================================================
--  smoke_ferdi_plan.sql : diaqnostikadan ferdi plan (db/131)
--
--  Iddialar: diaqnostikasiz qurulmur · zeif+orta fesiller kurikulum
--  sirasi ile · kecildi/geri · test yalniz bu sagirde · tekrar
--  diaqnostikadan sonra yenile: yaxsilasan cixir, kecilmis qalir ·
--  valideyn 2/5 gorur · yad muellim yox.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.student_plan_items; delete from public.student_plans;
delete from public.parent_sessions; delete from public.mistakes;
delete from public.attempt_answers;  delete from public.attempts;
delete from public.assignments;      delete from public.student_sessions;
delete from public.students;         delete from public.classes;
delete from public.subscriptions;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-0000000000f1','fp@t.az','{"full_name":"Ferdi Muellim"}'),
  ('11110000-0000-0000-0000-0000000000f2','yad@t.az','{"full_name":"Yad Muellim"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000f1','tutor','FP hesabi','11110000-0000-0000-0000-0000000000f1'),
  ('aaaa0000-0000-0000-0000-0000000000f2','tutor','Yad hesab','11110000-0000-0000-0000-0000000000f2');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000f1','11110000-0000-0000-0000-0000000000f1',true),
  ('aaaa0000-0000-0000-0000-0000000000f2','11110000-0000-0000-0000-0000000000f2',true);
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-0000000000f1', p.id, 'active', now() + interval '30 days'
  from public.plans p where p.slug = 'repetitor-25';
insert into public.classes (id, account_id, teacher_id, kind, name, join_code, level_id)
select 'cccc0000-0000-0000-0000-0000000000f1','aaaa0000-0000-0000-0000-0000000000f1',
       '11110000-0000-0000-0000-0000000000f1','tutor_group','FP qrup','KODFP001', l.id
  from public.levels l where l.code = '3';
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code) values
  ('5555000f-0000-0000-0000-0000000000f1','aaaa0000-0000-0000-0000-0000000000f1',
   'cccc0000-0000-0000-0000-0000000000f1','11110000-0000-0000-0000-0000000000f1','Kənan Əliyev','Kənan Ə.','FPLN0001');
insert into public.parent_sessions (token_hash, student_id, expires_at) values
  (app.hash_token('val-kenan'),'5555000f-0000-0000-0000-0000000000f1', now() + interval '1 day');

--  diaqnostika cavabi: fesil sirasina gore ilk N fesil tam sehv, sonraki M fesil 1/3 (orta), qalani duz
create or replace function pg_temp.diag_cavab(p_test uuid, p_weak int, p_mid int) returns jsonb language sql as $$
  with q as (
    select q.id qid, dense_rank() over (order by tp.sort, tp.name) rk,
           row_number() over (partition by q.topic_id order by q.id) k
      from public.test_questions tq join public.questions q on q.id = tq.question_id
      join public.topics tp on tp.id = q.topic_id where tq.test_id = p_test)
  select jsonb_agg(jsonb_build_object('q', qid, 'o', jsonb_build_array(
           (select o.id from public.question_options o where o.question_id = qid
             and o.is_correct = (case when rk <= p_weak then false
                                      when rk <= p_weak + p_mid then (k <> 1)
                                      else true end) order by o.ord limit 1))))
    from q
$$;

\echo '--- hazirliq tamam'

-- =====================================================================
--  1. Diaqnostikasiz plan qurulmur; diaqnostika: 2 zeif + 1 orta -> 3 setir
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f1';
do $$
declare ok boolean := false; v jsonb; t uuid;
begin
  begin
    perform public.rpc_student_plan_make('5555000f-0000-0000-0000-0000000000f1', 'riyaziyyat');
  exception when others then ok := true; end;
  assert ok, 'diaqnostikasiz plan quruldu';
  v := public.rpc_diagnostic_create('5555000f-0000-0000-0000-0000000000f1', 'riyaziyyat', 7);
  perform set_config('smoke.diag1', v->>'test_id', false);
end $$;
reset role; reset request.jwt.claim.sub;
do $$
declare tok text; att uuid; t uuid := current_setting('smoke.diag1')::uuid;
begin
  tok := public.rpc_student_login('FPLN0001')->>'token';
  att := (public.rpc_start_attempt(tok, t)->>'attempt_id')::uuid;
  perform public.rpc_submit_attempt(tok, att, pg_temp.diag_cavab(t, 2, 1));
end $$;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f1';
do $$
declare v jsonb; p jsonb;
begin
  v := public.rpc_student_plan_make('5555000f-0000-0000-0000-0000000000f1', 'riyaziyyat');
  assert (v->>'items')::int = 3, 'plan setirleri 3 olmali: ' || (v->>'items');
  p := public.rpc_student_plan_get('5555000f-0000-0000-0000-0000000000f1');
  assert jsonb_array_length(p) = 1 and p->0->>'subject_slug' = 'riyaziyyat', 'plan siyahisi';
  assert (p->0->>'total')::int = 3 and (p->0->>'done')::int = 0, 'total/done';
  assert p->0->'items'->0->>'kind' = 'weak' and p->0->'items'->2->>'kind' = 'mid', 'sira: zeifler evvel (kurikulum), sonra orta';
  assert (p->0->'items'->0->>'ord')::int = 1, 'ord';
end $$;
\echo 'OK  1 · diaqnostikasiz yox; 2 zeif + 1 orta -> 3 setirlik plan'

-- =====================================================================
--  2. Kecildi / geri; test yalniz bu sagirde
-- =====================================================================
do $$
declare p jsonb; i1 uuid; i2 uuid; r jsonb;
begin
  p := public.rpc_student_plan_get('5555000f-0000-0000-0000-0000000000f1');
  i1 := (p->0->'items'->0->>'id')::uuid; i2 := (p->0->'items'->1->>'id')::uuid;
  perform public.rpc_student_plan_done(i1, true);
  p := public.rpc_student_plan_get('5555000f-0000-0000-0000-0000000000f1');
  assert (p->0->>'done')::int = 1 and (p->0->'items'->0->>'done')::boolean, 'kecildi';
  perform public.rpc_student_plan_done(i1, false);
  p := public.rpc_student_plan_get('5555000f-0000-0000-0000-0000000000f1');
  assert (p->0->>'done')::int = 0, 'geri';
  perform public.rpc_student_plan_done(i1, true);
  r := public.rpc_student_plan_test(i2, 5);
  assert (r->>'test_id') is not null and (r->>'count')::int = 5, 'test yigilmadi';
  assert (select student_id = '5555000f-0000-0000-0000-0000000000f1' and max_attempts = 1
            from public.assignments where test_id = (r->>'test_id')::uuid), 'teyinat ferdi deyil';
  assert (select title from public.tests where id = (r->>'test_id')::uuid) like '% — Kənan', 'ad: fesil — ad';
  p := public.rpc_student_plan_get('5555000f-0000-0000-0000-0000000000f1');
  assert p->0->'items'->1->>'test_id' = r->>'test_id', 'setirde test_id';
end $$;
\echo 'OK  2 · kecildi/geri; test yalniz bu sagirde, adi ile'

-- =====================================================================
--  3. Valideyn: 1/3; yad muellim yox
-- =====================================================================
reset role; reset request.jwt.claim.sub;
do $$
declare v jsonb;
begin
  set local role anon;
  v := public.rpc_parent_home('val-kenan');
  reset role;
  assert (v->'plan'->>'total')::int = 3 and (v->'plan'->>'done')::int = 1, 'valideyn plan: ' || (v->'plan')::text;
end $$;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f2';
do $$
declare ok boolean := false;
begin
  begin
    perform public.rpc_student_plan_get('5555000f-0000-0000-0000-0000000000f1');
  exception when insufficient_privilege then ok := true; end;
  assert ok, 'yad muellim gordu';
end $$;
\echo 'OK  3 · valideyn 1/3 gorur; yad muellim yox'

-- =====================================================================
--  4. Tekrar diaqnostika (hamisi duz) -> yenile: yaxsilasan cixir, kecilmis qalir
-- =====================================================================
reset role; reset request.jwt.claim.sub;
--  evvelki diaqnostika teyinati baglanir (yeni yaradilsin deye); pencere serti ucun opens_at da geri
update public.assignments set opens_at = now() - interval '2 hours', closes_at = now() - interval '1 minute'
 where test_id = current_setting('smoke.diag1')::uuid;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f1';
do $$
declare v jsonb;
begin
  v := public.rpc_diagnostic_create('5555000f-0000-0000-0000-0000000000f1', 'riyaziyyat', 7);
  perform set_config('smoke.diag2', v->>'test_id', false);
end $$;
reset role; reset request.jwt.claim.sub;
do $$
declare tok text; att uuid; t uuid := current_setting('smoke.diag2')::uuid;
begin
  tok := public.rpc_student_login('FPLN0001')->>'token';
  att := (public.rpc_start_attempt(tok, t)->>'attempt_id')::uuid;
  --  1-ci fesil hele zeif, qalani duz
  perform public.rpc_submit_attempt(tok, att, pg_temp.diag_cavab(t, 1, 0));
end $$;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f1';
do $$
declare v jsonb; p jsonb;
begin
  v := public.rpc_student_plan_make('5555000f-0000-0000-0000-0000000000f1', 'riyaziyyat');
  assert (v->>'items')::int = 1, 'yenile: 1 setir qalmali: ' || (v->>'items');
  p := public.rpc_student_plan_get('5555000f-0000-0000-0000-0000000000f1');
  --  1-ci fesil evvel kecilmisdi - done qalir
  assert (p->0->'items'->0->>'done')::boolean, 'kecilmis setrin done_at-i itdi';
end $$;
\echo 'OK  4 · tekrar diaqnostikadan sonra yenile: yaxsilasan cixir, kecilmis qalir'
