-- =====================================================================
--  smoke_netice_sekli.sql : 900 - sekil neticede ve hesabatda
--
--  Iddialar:
--    1. rpc_submit_attempt  -> sekilli sualda media_url gelir
--    2. rpc_submit_attempt  -> sekilsiz sualda media_url NULL (bos yer
--       yox: ekran fig() ile hec ne cizmir)
--    3. rpc_test_result     -> eyni ikisi (sonradan baxis)
--    4. rpc_student_report  -> 'weak' setrinde media_url
--    5. UCUNDE DE is_correct qaytarilmir - cavab hele de sizmir
--    6. rpc_test_preview (muellimin kagiz vereqi) - 224-de itmis
--       media_url setri qaytarilib; vaxt limiti de yerinde qalir
--
--  ISTIFADE:  psql -f db/test/smoke_netice_sekli.sql
--  Cedvelleri temizleyir (yerli sinaq bazasi ucundur).
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = notice;

delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers;  delete from public.attempts;
delete from public.assignments;      delete from public.student_sessions;
delete from public.students;         delete from public.classes;
delete from public.subscriptions;
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from public.profiles;
delete from auth.users;

--  Oz sinaq movzusu/suallari/testi - tekrar isledilende qalmasin
--  (yuxaridaki silme yalniz hesab terefini temizleyir).
delete from public.test_questions
 where test_id in (select id from public.tests where slug = 'sm900-sekil');
delete from public.tests where slug = 'sm900-sekil';
delete from public.question_options
 where question_id in (select id from public.questions
                        where topic_id in (select id from public.topics where slug = 'sm900-qrafik'));
delete from public.questions
 where topic_id in (select id from public.topics where slug = 'sm900-qrafik');
delete from public.topics where slug = 'sm900-qrafik';

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-0000000009f1','sek@t.az','{"full_name":"Sekil Muellim"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000009f1','tutor','Sekil hesabi','11110000-0000-0000-0000-0000000009f1');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000009f1','11110000-0000-0000-0000-0000000009f1',true);
--  'weak' ve 'topics' YALNIZ odenisli hesabda qayidir (133) - abune lazimdir
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-0000000009f1', p.id, 'active', now() + interval '30 days'
  from public.plans p where p.slug = 'repetitor-25';
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-0000000009f1','aaaa0000-0000-0000-0000-0000000009f1',
   '11110000-0000-0000-0000-0000000009f1','tutor_group','Sekil qrup','KODSEK01');
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code) values
  ('5555000f-0000-0000-0000-0000000009f1','aaaa0000-0000-0000-0000-0000000009f1',
   'cccc0000-0000-0000-0000-0000000009f1','11110000-0000-0000-0000-0000000009f1',
   'Qrafik Sagird','Qrafik S.','SEKL0001');

--  ---- iki PLATFORMA suali: biri sekilli, biri sekilsiz.
--  media_url yalniz platforma sualinda ola biler (188-deki CHECK).
do $$
declare v_subj uuid; v_lev uuid; v_prg uuid; v_top uuid; v_q1 uuid; v_q2 uuid; v_t uuid;
begin
  select id into v_subj from public.subjects where slug = 'riyaziyyat';
  select id into v_lev  from public.levels   limit 1;
  select id into v_prg  from public.programs where slug = 'orta';
  insert into public.topics (subject_id, level_id, parent_id, name, slug, sort)
       values (v_subj, v_lev, null, 'SINAQ qrafik 900', 'sm900-qrafik', 994)
    returning id into v_top;

  insert into public.questions (owner_type, subject_id, level_id, topic_id, kind, body, media_url, points)
       values ('platform', v_subj, v_lev, v_top, 'single',
               'Qrafikde hansi xett artandir?',
               app.svg_uri($svg$<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 40"><path d="M4 36 L36 4" stroke="#087f75" fill="none"/></svg>$svg$),
               1)
    returning id into v_q1;
  insert into public.question_options (question_id, ord, body, is_correct) values
    (v_q1, 1, 'Yuxari qalxan xett', true),
    (v_q1, 2, 'Asagi enen xett', false);

  insert into public.questions (owner_type, subject_id, level_id, topic_id, kind, body, points)
       values ('platform', v_subj, v_lev, v_top, 'single', 'Iki uste uc nece edir?', 1)
    returning id into v_q2;
  insert into public.question_options (question_id, ord, body, is_correct) values
    (v_q2, 1, 'Bes', true),
    (v_q2, 2, 'Dord', false);

  insert into public.tests (owner_type, owner_id, program_id, subject_id, level_id,
                            slug, title, status, pass_percent)
       values ('educator', '11110000-0000-0000-0000-0000000009f1', v_prg, v_subj, v_lev,
               'sm900-sekil', 'Sekil sinagi', 'published', 50)
    returning id into v_t;
  insert into public.test_questions (test_id, question_id, ord) values (v_t, v_q1, 1), (v_t, v_q2, 2);

  insert into public.assignments (test_id, class_id, assigned_by, opens_at)
       values (v_t, 'cccc0000-0000-0000-0000-0000000009f1',
               '11110000-0000-0000-0000-0000000009f1', now() - interval '1 hour');
end $$;

\echo '--- hazirliq tamam'

-- =====================================================================
--  1-2-5.  Testi yaz ve bitir - submit cavabini yoxla
-- =====================================================================
do $$
declare
  tok text; t1 uuid; att uuid; v jsonb; qs jsonb;
  v_sekilli jsonb; v_sekilsiz jsonb;
begin
  select id into t1 from public.tests where slug = 'sm900-sekil';
  tok := public.rpc_student_login('SEKL0001')->>'token';
  att := (public.rpc_start_attempt(tok, t1)->>'attempt_id')::uuid;

  --  Birinci suala DUZ, ikinciye SEHV cavab - hesabatda 'weak' ucun
  --  sekilli sual sehv olmalidir, ona gore tersine: sekilliye sehv.
  v := public.rpc_submit_attempt(tok, att, (
    select jsonb_agg(jsonb_build_object('q', q.id, 'o', jsonb_build_array(
             (select o.id from public.question_options o
               where o.question_id = q.id and not o.is_correct order by o.ord limit 1))))
      from public.test_questions tq join public.questions q on q.id = tq.question_id
     where tq.test_id = t1));

  qs := v->'questions';
  assert jsonb_array_length(qs) = 2, 'submit: 2 sual gozlenilirdi';

  select x into v_sekilli   from jsonb_array_elements(qs) x where x->>'body' like 'Qrafikde%';
  select x into v_sekilsiz  from jsonb_array_elements(qs) x where x->>'body' like 'Iki uste%';

  assert v_sekilli ? 'media_url',
    'SEHV 1: submit cavabinda media_url sahesi yoxdur';
  assert (v_sekilli->>'media_url') like 'data:image/svg+xml%',
    'SEHV 1: sekilli sualda media_url bos geldi: ' || coalesce(v_sekilli->>'media_url','(null)');
  raise notice 'OK  1 · rpc_submit_attempt sekilli sualda media_url qaytarir';

  assert jsonb_typeof(v_sekilsiz->'media_url') = 'null',
    'SEHV 2: sekilsiz sualda media_url null olmalidir, geldi: '
    || coalesce(v_sekilsiz->>'media_url','(yoxdur)');
  raise notice 'OK  2 · sekilsiz sualda media_url null - ekranda bos yer cixmir';

  assert not (v::text like '%is_correct%'),
    'SEHV 5: submit cavabinda is_correct var - dogru variant sizir!';
  raise notice 'OK  5a · submit cavabinda is_correct yoxdur';
end $$;

-- =====================================================================
--  3.  Sonradan baxis - rpc_test_result
-- =====================================================================
do $$
declare tok text; t1 uuid; v jsonb; v_sekilli jsonb; v_sekilsiz jsonb;
begin
  select id into t1 from public.tests where slug = 'sm900-sekil';
  tok := public.rpc_student_login('SEKL0001')->>'token';
  v := public.rpc_test_result(tok, t1);

  select x into v_sekilli  from jsonb_array_elements(v->'questions') x where x->>'body' like 'Qrafikde%';
  select x into v_sekilsiz from jsonb_array_elements(v->'questions') x where x->>'body' like 'Iki uste%';

  assert (v_sekilli->>'media_url') like 'data:image/svg+xml%',
    'SEHV 3: rpc_test_result-da sekil yoxdur - «iki yerde eyni RPC» telesi';
  assert jsonb_typeof(v_sekilsiz->'media_url') = 'null',
    'SEHV 3: result-da sekilsiz sualda media_url dolu geldi';
  raise notice 'OK  3 · rpc_test_result (sonradan baxis) da sekli qaytarir';

  assert not (v::text like '%is_correct%'),
    'SEHV 5: rpc_test_result-da is_correct var!';
  raise notice 'OK  5b · rpc_test_result-da is_correct yoxdur';
end $$;

-- =====================================================================
--  4.  Muellimin sagird hesabati - 'weak' siyahisi
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000009f1';
do $$
declare v jsonb; w jsonb;
begin
  v := public.rpc_student_report('5555000f-0000-0000-0000-0000000009f1');
  assert jsonb_typeof(v->'weak') = 'array',
    'weak siyahisi gelmedi (abune yoxdur?): ' || jsonb_typeof(v->'weak');

  select x into w from jsonb_array_elements(v->'weak') x where x->>'body' like 'Qrafikde%';
  assert w is not null, 'SEHV 4: sehv edilmis sekilli sual weak siyahisinda yoxdur';
  assert (w->>'media_url') like 'data:image/svg+xml%',
    'SEHV 4: hesabatda media_url yoxdur: ' || coalesce(w->>'media_url','(null)');
  raise notice 'OK  4 · rpc_student_report weak setrinde media_url var';

  assert not (v::text like '%is_correct%'),
    'SEHV 5: hesabatda is_correct var!';
  raise notice 'OK  5c · rpc_student_report-da is_correct yoxdur';
end $$;

-- =====================================================================
--  6.  Muellimin vereqi - rpc_test_preview
--      (224 bu setri itirmisdi; 224-un oz isi - time_limit_sec - qalmalidir)
-- =====================================================================
do $$
declare v jsonb; t1 uuid; q1 jsonb;
begin
  select id into t1 from public.tests where slug = 'sm900-sekil';
  v := public.rpc_test_preview(t1);
  select x into q1 from jsonb_array_elements(v->'questions') x where x->>'body' like 'Qrafikde%';
  assert (q1->>'media_url') like 'data:image/svg+xml%',
    'SEHV 6: vereqde media_url yoxdur: ' || coalesce(q1->>'media_url','(null)');
  raise notice 'OK  6 · rpc_test_preview sekli qaytarir';
  assert v ? 'time_limit_sec',
    'SEHV 6: 224-un time_limit_sec sahesi itdi - govde sehv goturulub';
  raise notice 'OK  6b · 224-un time_limit_sec sahesi yerindedir';
end $$;
reset role; reset request.jwt.claim.sub;

\echo 'HAMISI OK - 900 sekil neticede ve hesabatda'
