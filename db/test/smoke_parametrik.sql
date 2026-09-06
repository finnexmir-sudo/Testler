-- =====================================================================
--  smoke_parametrik.sql : parametrik (sablon) suallar (db/132)
--
--  Iddialar: ifade hesablanir, inyeksiya kecmir · sablon sual yazilir,
--  yararsiz sablon reddedilir · cehd baslayanda reqemler secilir ve
--  davam edende eyni qalir · dogru variant ID ile bal alir, hesabatda
--  render olunmus metn · yazili sablon sual · sehv defteri ve vereq
--  render olunur · adi sualda { } toxunulmur.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.mistakes;
delete from public.attempt_answers;  delete from public.attempts;
delete from public.assignments;      delete from public.student_sessions;
delete from public.students;         delete from public.classes;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.question_options o using public.questions q
 where o.question_id = q.id and q.owner_type = 'educator';
delete from public.questions where owner_type = 'educator';
delete from public.subscriptions;
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-0000000000f1','pq@t.az','{"full_name":"Sablon Muellim"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000f1','tutor','PQ hesabi','11110000-0000-0000-0000-0000000000f1');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000f1','11110000-0000-0000-0000-0000000000f1',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-0000000000f1','aaaa0000-0000-0000-0000-0000000000f1',
   '11110000-0000-0000-0000-0000000000f1','tutor_group','PQ qrup','KODPQ001');
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code) values
  ('5555000f-0000-0000-0000-0000000000f1','aaaa0000-0000-0000-0000-0000000000f1',
   'cccc0000-0000-0000-0000-0000000000f1','11110000-0000-0000-0000-0000000000f1','Ayan Bir','Ayan B.','PQFT0001');

\echo '--- hazirliq tamam'

-- =====================================================================
--  1. Hesablama ve tehlukesizlik
-- =====================================================================
do $$
declare bad boolean;
begin
  assert app.pq_eval('a+b', '{"a":245,"b":138}') = '383', 'toplama';
  assert app.pq_eval('a/b', '{"a":7,"b":2}') = '3.5', 'bolme deqiq';
  assert app.pq_eval('a%b', '{"a":7,"b":2}') = '1', 'qaliq';
  assert app.pq_eval('(a-b)*2', '{"a":3,"b":5}') = '-4', 'menfi';
  assert app.pq_render('{a} + {b} = ?', '{"a":245,"b":138}') = '245 + 138 = ?', 'render';
  assert app.pq_render('{a} + {b} = ?', null) = '{a} + {b} = ?', 'adi sualda { } toxunulmur';
  assert app.pq_cond('a>b and a%b=0', '{"a":9,"b":3}'), 'sert';
  -- inyeksiya: yalniz reqem/operator kecir
  bad := false;
  begin perform app.pq_eval('1; drop table x', '{}'); exception when others then bad := true; end;
  assert bad, 'inyeksiya kecdi!';
  bad := false;
  begin perform app.pq_eval('a', '{"a":"1) union select 1"}'); exception when others then bad := true; end;
  assert bad, 'deyisen deyeri ile inyeksiya kecdi!';
  bad := false;
  begin perform app.pq_eval('c', '{"a":1}'); exception when others then bad := true; end;
  assert bad, 'namelum deyisen kecdi';
  bad := false;
  begin perform app.pq_spec('{"vars":{"ab":[1,2]}}'); exception when others then bad := true; end;
  assert bad, 'iki herfli ad kecdi';
  bad := false;
  begin perform app.pq_spec('{"vars":{"a":[9,1]}}'); exception when others then bad := true; end;
  assert bad, 'ters araliq kecdi';
end $$;
\echo 'OK  1 · hesablama duzdur, inyeksiya kecmir'

set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f1';

-- =====================================================================
--  2. Sablon sual yazilir; yararsiz sablon reddedilir; numune render
-- =====================================================================
do $$
declare v jsonb; q jsonb; bad boolean; p jsonb;
begin
  v := public.rpc_bank_save_question(
    null, 'riyaziyyat', '{a} + {b} neçə edər?',
    '[{"body":"{a+b}","correct":true},{"body":"{a+b+10}"},{"body":"{a+b-10}"},{"body":"{a-b}"}]'::jsonb,
    'single', '3', null, 'Cavab: {a+b}.', 2, null, null, array['toplama'], null,
    '{"vars":{"a":[100,999],"b":[100,999]},"cond":"a>b"}'::jsonb);
  perform set_config('smoke.q1', v->>'id', false);
  q := public.rpc_bank_question((v->>'id')::uuid);
  assert q->'params'->'vars' ? 'a' and q->'params'->>'cond' = 'a>b', 'params yazilmadi';
  assert q->>'body' = '{a} + {b} neçə edər?', 'sablon metni olduğu kimi saxlanir';

  --  yer tutucusuz sablon
  bad := false;
  begin
    perform public.rpc_bank_save_question(null, 'riyaziyyat', '2 + 2', '[{"body":"4","correct":true},{"body":"5"}]'::jsonb,
      'single', '3', null, '', 2, null, null, '{}', null, '{"vars":{"a":[1,9]}}'::jsonb);
  exception when others then bad := true; end;
  assert bad, 'yer tutucusuz sablon qebul olundu';
  --  namelum deyisen
  bad := false;
  begin
    perform public.rpc_bank_save_question(null, 'riyaziyyat', '{a} + {c}', '[{"body":"{a+c}","correct":true},{"body":"1"}]'::jsonb,
      'single', '3', null, '', 2, null, null, '{}', null, '{"vars":{"a":[1,9]}}'::jsonb);
  exception when others then bad := true; end;
  assert bad, 'namelum deyisen qebul olundu';
  --  eyni cixan variantlar
  bad := false;
  begin
    perform public.rpc_bank_save_question(null, 'riyaziyyat', '{a} + {b}', '[{"body":"{a+b}","correct":true},{"body":"{b+a}"}]'::jsonb,
      'single', '3', null, '', 2, null, null, '{}', null, '{"vars":{"a":[1,9],"b":[1,9]}}'::jsonb);
  exception when others then bad := true; end;
  assert bad, 'eyni cixan variantlar qebul olundu';

  --  numune
  p := public.rpc_pq_preview('{"vars":{"a":[10,20],"b":[1,9]}}'::jsonb, '{a} - {b}',
         '[{"body":"{a-b}","correct":true},{"body":"{a+b}"}]'::jsonb, '');
  assert p->>'body' !~ '\{' and (p->'vars'->>'a')::int between 10 and 20, 'numune render olunmadi';
  assert (p->'options'->0->>'body')::int = (p->'vars'->>'a')::int - (p->'vars'->>'b')::int, 'numune variant';

  --  yazili sablon sual
  v := public.rpc_bank_save_question(
    null, 'riyaziyyat', '{a} × {b} = ?', '[{"body":"{a*b}"}]'::jsonb,
    'text', '3', null, '', 2, null, null, '{}', null, '{"vars":{"a":[2,9],"b":[2,9]}}'::jsonb);
  perform set_config('smoke.q2', v->>'id', false);
  --  adi sual (muqayise ucun) - icinde { } var, toxunulmamalidir
  v := public.rpc_bank_save_question(
    null, 'riyaziyyat', 'Çoxluq {1, 2} neçə elementlidir?', '[{"body":"2","correct":true},{"body":"1"}]'::jsonb,
    'single', '3', null, '', 2, null, null, '{}', null, null);
  perform set_config('smoke.q3', v->>'id', false);
end $$;
\echo 'OK  2 · sablon sual yazilir, yararsiz sablon reddedilir, numune render'

reset role;

--  test + teyinat
insert into public.tests (id, owner_type, owner_id, program_id, subject_id, level_id, title, status, shuffle_questions, shuffle_options, max_attempts)
select '7e570000-0000-0000-0000-0000000000f1', 'educator', '11110000-0000-0000-0000-0000000000f1',
       (select id from public.programs order by id limit 1),
       (select id from public.subjects where slug = 'riyaziyyat'),
       (select l.id from public.levels l where l.code = '3' order by l.sort limit 1),
       'Sablon test', 'published', false, false, 0;
insert into public.test_questions (test_id, question_id, ord) values
  ('7e570000-0000-0000-0000-0000000000f1', current_setting('smoke.q1')::uuid, 1),
  ('7e570000-0000-0000-0000-0000000000f1', current_setting('smoke.q2')::uuid, 2),
  ('7e570000-0000-0000-0000-0000000000f1', current_setting('smoke.q3')::uuid, 3);
insert into public.assignments (class_id, test_id, assigned_by, max_attempts) values
  ('cccc0000-0000-0000-0000-0000000000f1', '7e570000-0000-0000-0000-0000000000f1',
   '11110000-0000-0000-0000-0000000000f1', 3);

-- =====================================================================
--  3. Cehd: reqemler secilir, araliqda ve sertle; davam edende eyni;
--     { } sagirde getmir; adi sualin { } toxunulmur; is_correct sizmir
-- =====================================================================
do $$
declare tok text; s jsonb; s2 jsonb; att uuid; q1 jsonb; q3 jsonb; pr jsonb; a int; b int; i int;
begin
  tok := public.rpc_student_login('PQFT0001')->>'token';
  set local role anon;
  s := public.rpc_start_attempt(tok, '7e570000-0000-0000-0000-0000000000f1');
  s2 := public.rpc_start_attempt(tok, '7e570000-0000-0000-0000-0000000000f1');
  reset role;
  att := (s->>'attempt_id')::uuid;
  assert s2->>'attempt_id' = s->>'attempt_id', 'davam etdirilen cehd';
  assert s2->'questions' = s->'questions', 'davam edende eyni reqemler olmali';
  assert s::text not like '%is_correct%', 'is_correct sizdi!';
  for i in 0..2 loop
    if s->'questions'->i->>'id' = current_setting('smoke.q1') then q1 := s->'questions'->i; end if;
    if s->'questions'->i->>'id' = current_setting('smoke.q3') then q3 := s->'questions'->i; end if;
  end loop;
  assert q1->>'body' !~ '\{' and q1->>'body' ~ '^[0-9]+ \+ [0-9]+ neçə edər\?$', 'sablon render olunmadi: ' || (q1->>'body');
  assert q3->>'body' = 'Çoxluq {1, 2} neçə elementlidir?', 'adi sualin { } deyisdi';
  select params into pr from public.attempts where id = att;
  a := (pr->current_setting('smoke.q1')->>'a')::int;
  b := (pr->current_setting('smoke.q1')->>'b')::int;
  assert a between 100 and 999 and b between 100 and 999 and a > b, 'qiymetler araliqda ve sertle deyil';
  assert q1->>'body' = a || ' + ' || b || ' neçə edər?', 'metn saxlanan qiymetlerle uygun deyil';
  --  4 variant ferqli ve icinde dogru cavab var
  assert (select count(distinct o->>'body') from jsonb_array_elements(q1->'options') o) = 4, 'variantlar ferqli deyil';
  assert exists (select 1 from jsonb_array_elements(q1->'options') o where o->>'body' = (a + b)::text), 'dogru cavab variantlar arasinda yoxdur';
  perform set_config('smoke.att', att::text, false);
end $$;
\echo 'OK  3 · cehd baslayanda reqemler secilir, davam edende eyni, sizinti yoxdur'

-- =====================================================================
--  4. Cavab: dogru variant ID ile bal; yazili cavab render ile muqayise;
--     hesabatda render olunmus metn
-- =====================================================================
do $$
declare tok text; att uuid; pr jsonb; o_ok uuid; o_no uuid; r jsonb; a int; b int; c int; d int; ans jsonb; res jsonb; sh jsonb;
begin
  att := current_setting('smoke.att')::uuid;
  select params into pr from public.attempts where id = att;
  a := (pr->current_setting('smoke.q1')->>'a')::int; b := (pr->current_setting('smoke.q1')->>'b')::int;
  c := (pr->current_setting('smoke.q2')->>'a')::int; d := (pr->current_setting('smoke.q2')->>'b')::int;
  select id into o_ok from public.question_options where question_id = current_setting('smoke.q1')::uuid and is_correct;
  select id into o_no from public.question_options where question_id = current_setting('smoke.q1')::uuid and not is_correct order by ord limit 1;
  ans := jsonb_build_array(
    jsonb_build_object('q', current_setting('smoke.q1'), 'o', jsonb_build_array(o_ok)),
    jsonb_build_object('q', current_setting('smoke.q2'), 't', (c * d)::text),
    jsonb_build_object('q', current_setting('smoke.q3'), 'o', jsonb_build_array(
      (select id from public.question_options where question_id = current_setting('smoke.q3')::uuid and not is_correct limit 1))));
  tok := public.rpc_student_login('PQFT0001')->>'token';
  set local role anon;
  r := public.rpc_submit_attempt(tok, att, ans);
  res := public.rpc_test_result(tok, '7e570000-0000-0000-0000-0000000000f1');
  reset role;
  assert (r->>'score')::numeric = 2, 'bal 2 olmali (sablon + yazili), aldi: ' || (r->>'score');
  assert (select is_correct from public.attempt_answers where attempt_id = att and question_id = current_setting('smoke.q1')::uuid), 'variant ID ile dogru';
  assert (select is_correct from public.attempt_answers where attempt_id = att and question_id = current_setting('smoke.q2')::uuid), 'yazili render ile dogru';
  assert (select question_body from public.attempt_answers where attempt_id = att and question_id = current_setting('smoke.q1')::uuid)
         = a || ' + ' || b || ' neçə edər?', 'question_body render olunmus olmali';
  assert (select question_explanation from public.attempt_answers where attempt_id = att and question_id = current_setting('smoke.q1')::uuid)
         = 'Cavab: ' || (a + b) || '.', 'izah render olunmali';
  --  neticede secilmis variant render olunmus
  assert res::text not like '%{a+b}%' and res::text like '%' || (a + b) || '%', 'neticede picked render olunmali';
  assert res::text not like '%is_correct%', 'neticede is_correct sizdi';
  --  cavab vereqi (abune lazimdir)
  insert into public.subscriptions (account_id, plan_id, status, current_period_end)
  select 'aaaa0000-0000-0000-0000-0000000000f1', p.id, 'active', now() + interval '30 days'
    from public.plans p where p.slug = 'repetitor-25';
  set local role authenticated;
  set local request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f1';
  sh := public.rpc_attempt_sheet(att);
  reset role;
  assert sh::text not like '%{a+b}%' and sh::text like '%' || (a + b) || '%', 'vereqde render: ' || left(sh::text, 200);
end $$;
\echo 'OK  4 · dogru variant ID ile bal, yazili cavab render ile, hesabat render olunmus'

-- =====================================================================
--  5. Ikinci cehd BASQA reqemler (ezberlemek olmur); sehv defteri ve
--     muellim vereqi render olunur
-- =====================================================================
do $$
declare tok text; s jsonb; q1 jsonb; i int; a int; b int; m jsonb; pv jsonb; tries int := 0; same boolean := true; att uuid;
begin
  tok := public.rpc_student_login('PQFT0001')->>'token';
  select params into m from public.attempts where id = current_setting('smoke.att')::uuid;
  a := (m->current_setting('smoke.q1')->>'a')::int; b := (m->current_setting('smoke.q1')->>'b')::int;
  --  809*899 kombinasiya: 3 cehdde ucu de eyni olsa tesadufden cox sey
  while same and tries < 3 loop
    tries := tries + 1;
    set local role anon;
    s := public.rpc_start_attempt(tok, '7e570000-0000-0000-0000-0000000000f1');
    reset role;
    att := (s->>'attempt_id')::uuid;
    select params into m from public.attempts where id = att;
    same := (m->current_setting('smoke.q1')->>'a')::int = a and (m->current_setting('smoke.q1')->>'b')::int = b;
    update public.attempts set status = 'submitted', finished_at = now() where id = att;
  end loop;
  assert not same, 'yeni cehdde eyni reqemler';
  --  sehv defteri: q3 sehv idi -> siyahida; sablon sual defterde olsa render olunardi
  set local role anon;
  m := public.rpc_student_mistakes(tok);
  reset role;
  assert (m->>'open')::int = 1, 'defterde 1 acıq';
  assert m::text not like '%is_correct%', 'defterde is_correct sizdi';
  --  muellim vereqi
  set local role authenticated;
  set local request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f1';
  pv := public.rpc_test_preview('7e570000-0000-0000-0000-0000000000f1');
  reset role;
  for i in 0..2 loop
    if pv->'questions'->i->>'id' = current_setting('smoke.q1') then q1 := pv->'questions'->i; end if;
  end loop;
  assert (q1->>'tpl')::boolean and q1->>'body' !~ '\{' and (q1->'options'->0->>'body') ~ '^[0-9]+$', 'vereqde sablon render olunmali: ' || (q1->>'body');
end $$;
\echo 'OK  5 · yeni cehdde basqa reqemler; defter ve vereq render olunur'

\echo 'SABLON: BUTUN YOXLAMALAR KECDI'
