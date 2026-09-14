-- =====================================================================
--  smoke_vaxtli_test.sql : vaxtli test (db/192)
--
--  Iddialar: muellim oz testine limit qoyur (yad muellim yox, 180+ yox) ·
--  rpc_start_attempt qalan saniyeni server saati ile verir · limit kecib
--  amma guzestdedir -> bal hesablanir, timed_out · guzest de kecib ->
--  cavablar sayilmir (0), late · limitsiz test -> timed_out false ·
--  rpc_test_result timed_out qaytarir.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.attempt_answers; delete from public.attempts; delete from public.assignments;
delete from public.student_sessions; delete from public.students; delete from public.classes;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.question_options o using public.questions q where q.id = o.question_id and q.owner_type = 'educator';
delete from public.questions where owner_type = 'educator';
delete from public.subscriptions; delete from public.account_members; delete from public.accounts;
delete from public.user_roles; delete from public.profiles; delete from auth.users;
insert into auth.users (id, email) values
  ('11110000-0000-0000-0000-0000000000f1','vaxt-muellim@t.az'),
  ('11110000-0000-0000-0000-0000000000f2','vaxt-basqa@t.az');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000f1','tutor','Vaxt hesabi','11110000-0000-0000-0000-0000000000f1');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000f1','11110000-0000-0000-0000-0000000000f1',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-0000000000f1','aaaa0000-0000-0000-0000-0000000000f1',
   '11110000-0000-0000-0000-0000000000f1','tutor_group','Vaxt qrupu','VAXTQR01');
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code) values
  ('dddd0000-0000-0000-0000-0000000000f1','aaaa0000-0000-0000-0000-0000000000f1','cccc0000-0000-0000-0000-0000000000f1',
   '11110000-0000-0000-0000-0000000000f1','Vaxt Sagird','Vaxt','VAXTSAG1');
--  muellimin oz testi: 2 sual, hamisi duz cavablanacaq
insert into public.questions (id, owner_type, owner_id, account_id, subject_id, kind, body, points)
select x.id, 'educator', '11110000-0000-0000-0000-0000000000f1', 'aaaa0000-0000-0000-0000-0000000000f1', s.id, 'single', x.body, 1
  from (values ('eeee0000-0000-0000-0000-0000000000f1'::uuid, '2+2?'),
               ('eeee0000-0000-0000-0000-0000000000f2'::uuid, '3+3?')) x(id, body),
       (select id from public.subjects where slug = 'riyaziyyat' limit 1) s;
insert into public.question_options (id, question_id, body, is_correct, ord) values
  ('0000f000-0000-0000-0000-0000000000a1','eeee0000-0000-0000-0000-0000000000f1','4',true,1),
  ('0000f000-0000-0000-0000-0000000000a2','eeee0000-0000-0000-0000-0000000000f1','5',false,2),
  ('0000f000-0000-0000-0000-0000000000b1','eeee0000-0000-0000-0000-0000000000f2','6',true,1),
  ('0000f000-0000-0000-0000-0000000000b2','eeee0000-0000-0000-0000-0000000000f2','7',false,2);
insert into public.tests (id, owner_type, owner_id, program_id, subject_id, title, status, max_attempts)
select 'ffff0000-0000-0000-0000-0000000000f1', 'educator', '11110000-0000-0000-0000-0000000000f1',
       (select id from public.programs order by sort limit 1), (select id from public.subjects where slug = 'riyaziyyat' limit 1),
       'Vaxtli test', 'published', 0;
insert into public.test_questions (test_id, question_id, ord) values
  ('ffff0000-0000-0000-0000-0000000000f1','eeee0000-0000-0000-0000-0000000000f1',1),
  ('ffff0000-0000-0000-0000-0000000000f1','eeee0000-0000-0000-0000-0000000000f2',2);
insert into public.assignments (class_id, test_id, assigned_by, max_attempts) values
  ('cccc0000-0000-0000-0000-0000000000f1','ffff0000-0000-0000-0000-0000000000f1','11110000-0000-0000-0000-0000000000f1',0);

--  1. limit qoymaq: sahib olar, yad olmaz, 180+ olmaz, 0 = limitsiz
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f1';
do $$
declare r jsonb; e boolean := false;
begin
  r := public.rpc_test_time_limit('ffff0000-0000-0000-0000-0000000000f1', 1);
  assert (r->>'time_limit_sec')::int = 60, 'limit yazilmadi: ' || r::text;
  begin perform public.rpc_test_time_limit('ffff0000-0000-0000-0000-0000000000f1', 181);
  exception when others then e := true; end;
  assert e, '181 deq qebul olundu';
end $$;
reset role; reset request.jwt.claim.sub;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f2';
do $$
declare e boolean := false;
begin
  begin perform public.rpc_test_time_limit('ffff0000-0000-0000-0000-0000000000f1', 5);
  exception when insufficient_privilege then e := true; end;
  assert e, 'yad muellim limit qoydu';
end $$;
reset role; reset request.jwt.claim.sub;

--  2. sagird: qalan saniye server saati ile; guzestde -> bal var, timed_out
set role anon;
do $$
declare tok text; d jsonb; att uuid; r jsonb;
begin
  tok := (public.rpc_student_login('VAXTSAG1'))->>'token';
  d := public.rpc_start_attempt(tok, 'ffff0000-0000-0000-0000-0000000000f1');
  assert (d->'test'->>'time_limit_sec')::int = 60, 'test limiti gelmedi';
  assert (d->>'remaining_sec')::int between 58 and 60, 'qalan saniye: ' || (d->>'remaining_sec');
  att := (d->>'attempt_id')::uuid;
  --  90 saniye evvel baslayib: limit kecib, guzest (60+60) kecmeyib
  perform set_config('role', 'postgres', true);
  update public.attempts set started_at = now() - interval '90 seconds' where id = att;
  perform set_config('role', 'anon', true);
  d := public.rpc_start_attempt(tok, 'ffff0000-0000-0000-0000-0000000000f1');
  assert (d->>'remaining_sec')::int = 0, 'kecmis limitde qalan 0 olmalidir: ' || (d->>'remaining_sec');
  assert (d->>'attempt_id')::uuid = att, 'eyni cehd davam etmelidir';
  r := public.rpc_submit_attempt(tok, att, '[{"q":"eeee0000-0000-0000-0000-0000000000f1","o":["0000f000-0000-0000-0000-0000000000a1"]},
                                            {"q":"eeee0000-0000-0000-0000-0000000000f2","o":["0000f000-0000-0000-0000-0000000000b1"]}]'::jsonb);
  assert (r->>'timed_out')::boolean, 'timed_out yoxdur';
  assert not (r->>'late')::boolean, 'guzestde late olmamalidir';
  assert (r->>'percent')::numeric = 100, 'guzestde bal hesablanmali idi: ' || (r->>'percent');
  r := public.rpc_test_result(tok, 'ffff0000-0000-0000-0000-0000000000f1');
  assert (r->>'timed_out')::boolean, 'rpc_test_result timed_out vermir';
end $$;
reset role;

--  3. guzest de kecib -> cavablar sayilmir
set role anon;
do $$
declare tok text; d jsonb; att uuid; r jsonb;
begin
  tok := (public.rpc_student_login('VAXTSAG1'))->>'token';
  d := public.rpc_start_attempt(tok, 'ffff0000-0000-0000-0000-0000000000f1');
  att := (d->>'attempt_id')::uuid;
  perform set_config('role', 'postgres', true);
  update public.attempts set started_at = now() - interval '200 seconds' where id = att;
  perform set_config('role', 'anon', true);
  r := public.rpc_submit_attempt(tok, att, '[{"q":"eeee0000-0000-0000-0000-0000000000f1","o":["0000f000-0000-0000-0000-0000000000a1"]},
                                            {"q":"eeee0000-0000-0000-0000-0000000000f2","o":["0000f000-0000-0000-0000-0000000000b1"]}]'::jsonb);
  assert (r->>'late')::boolean and (r->>'timed_out')::boolean, 'late olmalidir: ' || r::text;
  assert (r->>'percent')::numeric = 0, 'gec cavablar sayildi: ' || (r->>'percent');
end $$;
reset role;

--  4. limitsiz test: hec ne deyismir
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f1';
do $$ begin perform public.rpc_test_time_limit('ffff0000-0000-0000-0000-0000000000f1', 0); end $$;
reset role; reset request.jwt.claim.sub;
set role anon;
do $$
declare tok text; d jsonb; att uuid; r jsonb;
begin
  tok := (public.rpc_student_login('VAXTSAG1'))->>'token';
  d := public.rpc_start_attempt(tok, 'ffff0000-0000-0000-0000-0000000000f1');
  assert d->>'remaining_sec' is null, 'limitsiz testde remaining_sec null olmalidir';
  att := (d->>'attempt_id')::uuid;
  perform set_config('role', 'postgres', true);
  update public.attempts set started_at = now() - interval '2 hours' where id = att;
  perform set_config('role', 'anon', true);
  r := public.rpc_submit_attempt(tok, att, '[{"q":"eeee0000-0000-0000-0000-0000000000f1","o":["0000f000-0000-0000-0000-0000000000a1"]}]'::jsonb);
  assert not (r->>'timed_out')::boolean and not (r->>'late')::boolean, 'limitsiz testde vaxt bitdi cixdi';
  assert (r->>'percent')::numeric = 50, 'limitsiz bal: ' || (r->>'percent');
end $$;
reset role;

\echo 'OK  1 · vaxtli test: limit sahibde, qalan saniye serverde, guzestde bal var, gec cavab sayilmir, limitsiz toxunulmur'
