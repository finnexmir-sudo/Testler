-- =====================================================================
--  smoke_icmal_hefte.sql : (200) rpc_home.stats heftelik ferq acarlari
--  Iddialar: acarlar var · son 7 gun sayilir, kohne sayilmir ·
--  avg_w / avg_pw ayri pencerelerden · ikinci tetbiq zerersizdir.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments; delete from public.student_sessions;
delete from public.students; delete from public.classes;
delete from public.tests where owner_type = 'educator';
delete from public.subscriptions;
delete from public.account_members; delete from public.accounts;
delete from public.user_roles; delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-0000000000e1','hef@t.az','{"full_name":"Hefte Muellim"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000e1','tutor','Hefte hesabi','11110000-0000-0000-0000-0000000000e1');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000e1','11110000-0000-0000-0000-0000000000e1',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-0000000000e1','aaaa0000-0000-0000-0000-0000000000e1',
   '11110000-0000-0000-0000-0000000000e1','tutor_group','Qrup H','KODHEF01');
--  3 sagird: 2 bu hefte, 1 kohne
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code, created_at) values
  ('5555000e-0000-0000-0000-000000000001','aaaa0000-0000-0000-0000-0000000000e1','cccc0000-0000-0000-0000-0000000000e1','11110000-0000-0000-0000-0000000000e1','S Bir','S Bir','KODHEF11', now() - interval '1 day'),
  ('5555000e-0000-0000-0000-000000000002','aaaa0000-0000-0000-0000-0000000000e1','cccc0000-0000-0000-0000-0000000000e1','11110000-0000-0000-0000-0000000000e1','S Iki','S Iki','KODHEF12', now() - interval '3 days'),
  ('5555000e-0000-0000-0000-000000000003','aaaa0000-0000-0000-0000-0000000000e1','cccc0000-0000-0000-0000-0000000000e1','11110000-0000-0000-0000-0000000000e1','S Uc','S Uc','KODHEF13', now() - interval '20 days');
--  2 test: 1 bu hefte, 1 kohne, 1 diaqnostik (sayilmir)
insert into public.tests (id, owner_type, owner_id, class_id, program_id, subject_id, level_id, slug, title, status, created_at, is_diagnostic)
select x.id, 'educator', '11110000-0000-0000-0000-0000000000e1', 'cccc0000-0000-0000-0000-0000000000e1', pt.program_id, pt.subject_id, pt.level_id, x.slug, x.title, 'published', x.at, x.diag
  from (select program_id, subject_id, level_id from public.tests where owner_type = 'platform' limit 1) pt,
       (values
  ('7777000e-0000-0000-0000-000000000001'::uuid,'hef-t1','T1', now() - interval '2 days', false),
  ('7777000e-0000-0000-0000-000000000002'::uuid,'hef-t2','T2', now() - interval '30 days', false),
  ('7777000e-0000-0000-0000-000000000003'::uuid,'hef-t3','T3', now() - interval '1 day', true)) as x(id, slug, title, at, diag);
--  cehdler: bu hefte 80, 60 (orta 70); evvelki hefte 50; 3 hefte evvel 10 (hec bir pencereye dusmur)
insert into public.attempts (student_id, test_id, class_id, status, started_at, finished_at, score, max_score, percent) values
  ('5555000e-0000-0000-0000-000000000001','7777000e-0000-0000-0000-000000000001','cccc0000-0000-0000-0000-0000000000e1','submitted', now() - interval '2 days', now() - interval '2 days', 8, 10, 80),
  ('5555000e-0000-0000-0000-000000000002','7777000e-0000-0000-0000-000000000001','cccc0000-0000-0000-0000-0000000000e1','submitted', now() - interval '1 day',  now() - interval '1 day',  6, 10, 60),
  ('5555000e-0000-0000-0000-000000000003','7777000e-0000-0000-0000-000000000002','cccc0000-0000-0000-0000-0000000000e1','submitted', now() - interval '10 days', now() - interval '10 days', 5, 10, 50),
  ('5555000e-0000-0000-0000-000000000003','7777000e-0000-0000-0000-000000000002','cccc0000-0000-0000-0000-0000000000e1','submitted', now() - interval '21 days', now() - interval '21 days', 1, 10, 10);

set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000e1';
do $$
declare v jsonb; s jsonb;
begin
  v := public.rpc_home(null);
  s := v->'stats';
  assert (s->>'students') = '3' and (s->>'students_w') = '2', 'sagird: ' || s::text;
  assert (s->>'tests') = '2' and (s->>'tests_w') = '1', 'test: ' || s::text;
  assert (s->>'attempts') = '4' and (s->>'attempts_w') = '2', 'cehd: ' || s::text;
  assert (s->>'avg_w') = '70' and (s->>'avg_pw') = '50', 'orta: ' || s::text;
  assert (s->>'avg') = '50', 'umumi orta: ' || s::text;
end $$;
reset role; reset request.jwt.claim.sub;
\echo 'OK  1 · rpc_home.stats: son 7 gun ve evvelki 7 gun ayri sayilir'

--  ikinci tetbiq: marker artiq genislenib - kecilir, funksiya pozulmur
\i 200_icmal_hefte.sql
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000e1';
do $$
begin
  assert (public.rpc_home(null)->'stats'->>'students_w') = '2', 'ikinci tetbiqden sonra pozuldu';
  assert position('tests_w' in pg_get_functiondef('public.rpc_home(uuid)'::regprocedure)) > 0;
end $$;
reset role; reset request.jwt.claim.sub;
\echo 'OK  2 · ikinci tetbiq zerersizdir'

-- =====================================================================
--  3. (201) topics: qrup + movzu uzre zeif yigimi
--     S Bir 1/5, S Iki 2/5 (zeif), S Uc 5/5 -> weak_n 2, n 3, orta 53
-- =====================================================================
--  topics yalniz abuneli hesabda (siqnallar kimi)
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-0000000000e1', p.id, 'active', now() + interval '30 days'
  from public.plans p where p.slug = 'repetitor-25';
insert into public.attempt_answers (attempt_id, question_id, topic_id, selected_option_ids, is_correct, points, question_body, question_explanation, answered_at)
select a.id, q.id,
       (select id from public.topics where parent_id is not null limit 1),
       '{}', q.k <= x.okn, 0, 'x', '', now()
  from (values ('5555000e-0000-0000-0000-000000000001'::uuid, 1), ('5555000e-0000-0000-0000-000000000002'::uuid, 2), ('5555000e-0000-0000-0000-000000000003'::uuid, 5)) x(sid, okn)
  join lateral (select id from public.attempts a2 where a2.student_id = x.sid order by finished_at desc limit 1) a on true
  cross join (select id, row_number() over (order by id) k from (select id from public.questions where owner_type = 'platform' order by id limit 5) z) q;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000e1';
do $$
declare v jsonb; tp jsonb;
begin
  v := public.rpc_home(null);
  assert jsonb_typeof(v->'topics') = 'array', 'topics yoxdur: ' || coalesce((v->'topics')::text, 'null');
  assert jsonb_array_length(v->'topics') = 1, 'topics sayi: ' || (v->'topics')::text;
  tp := v->'topics'->0;
  assert (tp->>'n') = '3' and (tp->>'weak_n') = '2' and (tp->>'avg') = '53', 'topics setri: ' || tp::text;
  assert jsonb_array_length(tp->'weak') = 2 and tp->'weak'->0->>'name' = 'S Bir', 'zeif adlar: ' || tp::text;
  assert (tp->>'class') = 'Qrup H' and (tp->>'subject_slug') is not null, 'qrup/fenn: ' || tp::text;
end $$;
reset role; reset request.jwt.claim.sub;
\echo 'OK  3 · (201) movzu uzre yigim: 3 sagirdden 2-si zeif'
\echo 'ICMAL HEFTE: BUTUN YOXLAMALAR KECDI'
