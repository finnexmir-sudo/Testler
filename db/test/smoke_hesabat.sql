-- =====================================================================
--  smoke_hesabat.sql : derin hesabat - movzu esiksiz, cavab vereqi,
--                      sehvler uzerinde is testi
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.class_plan_items; delete from public.class_plans;
delete from public.question_reports;
delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments;     delete from public.student_sessions;
delete from public.students;        delete from public.classes;
delete from public.subscriptions;
delete from public.test_questions tq using public.tests t
 where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.account_members; delete from public.accounts;
delete from public.user_roles;      delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-0000000000a1','h@t.az','{"full_name":"Hesabat Muellim"}'),
  ('11110000-0000-0000-0000-0000000000a2','ozge@t.az','{"full_name":"Ozge"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000a1','tutor','H hesabi',
   '11110000-0000-0000-0000-0000000000a1'),
  ('aaaa0000-0000-0000-0000-0000000000a2','tutor','Ozge hesab',
   '11110000-0000-0000-0000-0000000000a2');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000a1','11110000-0000-0000-0000-0000000000a1',true),
  ('aaaa0000-0000-0000-0000-0000000000a2','11110000-0000-0000-0000-0000000000a2',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-0000000000a1','aaaa0000-0000-0000-0000-0000000000a1',
   '11110000-0000-0000-0000-0000000000a1','tutor_group','H qrupu','KODHES01');
insert into public.students (id, account_id, class_id, created_by,
                             full_name, display_name, login_code) values
  ('5555000a-0000-0000-0000-0000000000a1','aaaa0000-0000-0000-0000-0000000000a1',
   'cccc0000-0000-0000-0000-0000000000a1','11110000-0000-0000-0000-0000000000a1',
   'Hesabat Sagird','Hesabat S.','HESA0001');

-- Sagird testi isleyir: 4 duz, 2 sehv
do $$
declare tok text; att uuid; ans jsonb := '[]'::jsonb; r record; k int := 0; oid uuid;
begin
  tok := public.rpc_student_login('HESA0001')->>'token';
  att := (public.rpc_start_attempt(tok,
           (select id from public.tests where slug='riy-3-vurma-1'))->>'attempt_id')::uuid;
  for r in select q.id from public.questions q
             join public.test_questions tq on tq.question_id=q.id
             join public.tests t on t.id=tq.test_id and t.slug='riy-3-vurma-1'
            order by tq.ord loop
    k := k + 1;
    select o.id into oid from public.question_options o
     where o.question_id = r.id and o.is_correct = (k <= 4) limit 1;
    ans := ans || jsonb_build_array(jsonb_build_object('q', r.id, 'o', jsonb_build_array(oid)));
  end loop;
  perform public.rpc_submit_attempt(tok, att, ans);
end $$;

\echo '--- hazirliq tamam'

-- =====================================================================
--  1. Odenissiz: derin hisseler bagli
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000a1';
do $$
declare v jsonb; ok1 boolean := false; ok2 boolean := false; att uuid;
begin
  v := public.rpc_student_report('5555000a-0000-0000-0000-0000000000a1');
  assert v->'topics' = 'null'::jsonb, 'odenissiz topics acildi';
  att := (v->'attempts'->0->>'id')::uuid;
  begin
    perform public.rpc_attempt_sheet(att);
  exception when insufficient_privilege then ok1 := true; end;
  begin
    perform public.rpc_remedial_test('5555000a-0000-0000-0000-0000000000a1');
  exception when insufficient_privilege then ok2 := true; end;
  assert ok1 and ok2, 'odenissiz derin funksiya acildi';
end $$;
\echo 'OK  1 · odenissiz derin analitika bagli qalir'

-- =====================================================================
--  2. Abune ile: esiksiz movzular, weak-de movzu ve qid
-- =====================================================================
reset role; reset request.jwt.claim.sub;
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-0000000000a1', p.id, 'active', now() + interval '30 days'
  from public.plans p where p.slug = 'repetitor-25';
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000a1';
do $$
declare v jsonb;
begin
  v := public.rpc_student_report('5555000a-0000-0000-0000-0000000000a1');
  assert (v->>'min_answers')::int >= 1, 'min_answers yoxdur';
  --  6 cavab var, esik olmadan movzu(lar) gorunmelidir
  assert jsonb_array_length(v->'topics') >= 1, 'movzular bosdur';
  assert jsonb_array_length(v->'weak') = 2, 'sehv sual sayi 2 deyil';
  assert v->'weak'->0->>'qid' is not null, 'weak-de qid yoxdur';
  assert v->'weak'->0 ? 'topic', 'weak-de movzu yoxdur';
end $$;
\echo 'OK  2 · movzular esiksiz, sehvlerde qid + movzu var'

-- =====================================================================
--  3. Cavab vereqi: secilen ve duz cavablar
-- =====================================================================
do $$
declare v jsonb; s jsonb; nok int := 0; i int;
begin
  v := public.rpc_student_report('5555000a-0000-0000-0000-0000000000a1');
  s := public.rpc_attempt_sheet((v->'attempts'->0->>'id')::uuid);
  assert jsonb_array_length(s->'items') = 6, 'vereqde 6 setir yoxdur';
  for i in 0..5 loop
    assert length(s->'items'->i->>'chosen') > 0, 'secilen cavab bosdur';
    assert length(s->'items'->i->>'correct') > 0, 'duz cavab bosdur';
    if (s->'items'->i->>'ok')::boolean then nok := nok + 1; end if;
  end loop;
  assert nok = 4, format('duz cavab sayi: %s / 4', nok);
end $$;
\echo 'OK  3 · cavab vereqi: 6 setir, 4 duz / 2 sehv'

-- =====================================================================
--  4. Sehvler uzerinde is: test mehz sehv suallardan yigilir
-- =====================================================================
do $$
declare v jsonb; tid uuid;
begin
  v := public.rpc_remedial_test('5555000a-0000-0000-0000-0000000000a1', 10);
  tid := (v->>'test_id')::uuid;
  assert (v->>'count')::int = 2, 'sual sayi 2 deyil';

  reset role; reset request.jwt.claim.sub;
  assert (select count(*) from public.test_questions where test_id = tid) = 2,
         'testde 2 sual yoxdur';
  --  yalniz sehv edilen suallar
  assert not exists (
    select 1 from public.test_questions tq
     where tq.test_id = tid
       and tq.question_id not in (
         select aa.question_id from public.attempt_answers aa
           join public.attempts a on a.id = aa.attempt_id
          where a.student_id = '5555000a-0000-0000-0000-0000000000a1'
            and aa.is_correct is not true)),
    'kenar sual dusdu';
  assert (select title from public.tests where id = tid) like '%səhvlər%',
         'test adi sehvler islemesini gostermir';
  assert exists (select 1 from public.assignments
                  where test_id = tid
                    and class_id = 'cccc0000-0000-0000-0000-0000000000a1'),
         'tapsiriq verilmedi';
end $$;
\echo 'OK  4 · sehv suallardan test + tapsiriq'

-- =====================================================================
--  5. Ozge muellim toxuna bilmir; anon gormur
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000a2';
do $$
declare ok1 boolean := false;
begin
  begin
    perform public.rpc_remedial_test('5555000a-0000-0000-0000-0000000000a1');
  exception when insufficient_privilege then ok1 := true; end;
  assert ok1, 'ozge muellim sehv testi yigdi!';
end $$;
reset role; reset request.jwt.claim.sub;
do $$
begin
  assert not has_function_privilege('anon', 'public.rpc_attempt_sheet(uuid)', 'EXECUTE'),
         'anon vereqi gorur';
  assert not has_function_privilege('anon', 'public.rpc_remedial_test(uuid, int)', 'EXECUTE'),
         'anon sehv testi yigir';
end $$;
\echo 'OK  5 · ozge muellim ve anon kecmir'
