-- =====================================================================
--  smoke_ferdi.sql : tapsiriq tek sagirde de verilir
--                    (db/28_ferdi_tapsiriq.sql)
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
  ('11110000-0000-0000-0000-0000000000f1','f@t.az','{"full_name":"Ferdi Muellim"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000f1','tutor','F hesabi',
   '11110000-0000-0000-0000-0000000000f1');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000f1','11110000-0000-0000-0000-0000000000f1',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-0000000000f1','aaaa0000-0000-0000-0000-0000000000f1',
   '11110000-0000-0000-0000-0000000000f1','tutor_group','F qrupu','KODFER01'),
  ('cccc0000-0000-0000-0000-0000000000f2','aaaa0000-0000-0000-0000-0000000000f1',
   '11110000-0000-0000-0000-0000000000f1','tutor_group','F ikinci','KODFER02');
--  A ve B eyni qrupda, C basqa qrupda
insert into public.students (id, account_id, class_id, created_by,
                             full_name, display_name, login_code) values
  ('5555000f-0000-0000-0000-0000000000f1','aaaa0000-0000-0000-0000-0000000000f1',
   'cccc0000-0000-0000-0000-0000000000f1','11110000-0000-0000-0000-0000000000f1',
   'Ferdi Bir','Ferdi B.','FERD0001'),
  ('5555000f-0000-0000-0000-0000000000f2','aaaa0000-0000-0000-0000-0000000000f1',
   'cccc0000-0000-0000-0000-0000000000f1','11110000-0000-0000-0000-0000000000f1',
   'Ferdi Iki','Ferdi I.','FERD0002'),
  ('5555000f-0000-0000-0000-0000000000f3','aaaa0000-0000-0000-0000-0000000000f1',
   'cccc0000-0000-0000-0000-0000000000f2','11110000-0000-0000-0000-0000000000f1',
   'Ferdi Uc','Ferdi U.','FERD0003');

insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-0000000000f1', p.id, 'active', now() + interval '30 days'
  from public.plans p where p.slug = 'repetitor-25';

\echo '--- hazirliq tamam'

-- =====================================================================
--  1. Kohne davranis qalir: student_id bos = butun qrup gorur
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f1';
do $$
declare t1 uuid; v jsonb;
begin
  select id into t1 from public.tests where slug = 'riy-3-vurma-1';
  perform public.rpc_assign_test('cccc0000-0000-0000-0000-0000000000f1', t1,
                                 now() + interval '7 days', 1);
  v := (select jsonb_agg(a.student_id) from public.assignments a where a.test_id = t1);
  assert v = '[null]'::jsonb, 'qrup teyinatinda student_id dolu geldi: ' || v::text;
end $$;

reset role; reset request.jwt.claim.sub;
do $$
declare vA jsonb; vB jsonb; tA text; tB text;
begin
  --  DIQQET: login VOLATILE, tests STABLE - eyni ifadede cagirilsa
  --  stable funksiya sessiyani hele gormur.  Ayri addimda aliriq.
  tA := public.rpc_student_login('FERD0001')->>'token';
  tB := public.rpc_student_login('FERD0002')->>'token';
  vA := public.rpc_student_tests(tA);
  vB := public.rpc_student_tests(tB);
  assert jsonb_array_length(vA->'assigned') = 1, 'A qrup tapsirigini gormur';
  assert jsonb_array_length(vB->'assigned') = 1, 'B qrup tapsirigini gormur';
  assert (vA->'assigned'->0->>'personal')::boolean = false, 'qrup teyinati ferdi sayildi';
end $$;
\echo 'OK  1 · qrup teyinati (student_id bos) hamiya gorunur'

-- =====================================================================
--  2. Ferdi teyinat: yalniz sahibi gorur
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f1';
do $$
declare t2 uuid; r jsonb;
begin
  select id into t2 from public.tests where slug = 'riy-3-qarisiq-1';
  r := public.rpc_assign_test('cccc0000-0000-0000-0000-0000000000f1', t2,
                              now() + interval '7 days', 1,
                              '5555000f-0000-0000-0000-0000000000f1');
  assert r->>'student' = 'Ferdi B.', 'cavabda sagird adi yoxdur: ' || r::text;
end $$;

reset role; reset request.jwt.claim.sub;
do $$
declare vA jsonb; vB jsonb; pers boolean; tA text; tB text;
begin
  tA := public.rpc_student_login('FERD0001')->>'token';
  tB := public.rpc_student_login('FERD0002')->>'token';
  vA := public.rpc_student_tests(tA);
  vB := public.rpc_student_tests(tB);
  assert jsonb_array_length(vA->'assigned') = 2, 'A ferdi tapsirigi gormur';
  assert jsonb_array_length(vB->'assigned') = 1, 'B BASQASININ ferdi tapsirigini gorur';
  select bool_or((x->>'personal')::boolean) into pers
    from jsonb_array_elements(vA->'assigned') x;
  assert pers, 'ferdi nisani (personal) gelmir';
end $$;
\echo 'OK  2 · ferdi teyinat yalniz oz sagirdine gorunur'

-- =====================================================================
--  3. Eyni test iki sagirde ayri-ayri verile bilir
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f1';
do $$
declare t2 uuid; n int;
begin
  select id into t2 from public.tests where slug = 'riy-3-qarisiq-1';
  perform public.rpc_assign_test('cccc0000-0000-0000-0000-0000000000f1', t2,
                                 now() + interval '7 days', 1,
                                 '5555000f-0000-0000-0000-0000000000f2');
  select count(*) into n from public.assignments
   where test_id = t2 and student_id is not null;
  assert n = 2, 'eyni test iki sagirde verilmedi: ' || n;
end $$;
\echo 'OK  3 · eyni test iki sagirde ayrica verilir (unikallik dogru)'

-- =====================================================================
--  4. Yad sagirde teyinat rodd edilir
-- =====================================================================
do $$
declare t1 uuid; ok1 boolean := false; ok2 boolean := false;
begin
  select id into t1 from public.tests where slug = 'riy-3-vurma-1';
  --  C basqa qrupdadir
  begin
    perform public.rpc_assign_test('cccc0000-0000-0000-0000-0000000000f1', t1,
                                   null, 1, '5555000f-0000-0000-0000-0000000000f3');
  exception when others then ok1 := true; end;
  --  ummumiyyetle olmayan sagird
  begin
    perform public.rpc_assign_test('cccc0000-0000-0000-0000-0000000000f1', t1,
                                   null, 1, '00000000-0000-0000-0000-000000000999');
  exception when others then ok2 := true; end;
  assert ok1, 'basqa qrupun sagirdine teyinat kecdi';
  assert ok2, 'olmayan sagirde teyinat kecdi';
end $$;
\echo 'OK  4 · yad / olmayan sagirde teyinat rodd edilir'

-- =====================================================================
--  5. Muellim siyahisi: kime verildiyi gorunur
-- =====================================================================
do $$
declare v jsonb; nferdi int; ngrup int;
begin
  v := public.rpc_class_assignments('cccc0000-0000-0000-0000-0000000000f1');
  select count(*) into nferdi from jsonb_array_elements(v->'items') x
   where x->>'student_id' is not null;
  select count(*) into ngrup from jsonb_array_elements(v->'items') x
   where x->>'student_id' is null;
  assert ngrup = 1, 'qrup tapsirigi sayi 1 deyil: ' || ngrup;
  assert nferdi = 2, 'ferdi tapsiriq sayi 2 deyil: ' || nferdi;
  --  ferdi setirde ad ve mexrec 1 olmalidir
  assert exists (select 1 from jsonb_array_elements(v->'items') x
                  where x->>'student' = 'Ferdi B.' and (x->>'targets')::int = 1),
         'ferdi setirde ad / mexrec sehvdir';
  assert exists (select 1 from jsonb_array_elements(v->'items') x
                  where x->>'student_id' is null and (x->>'targets')::int = 2),
         'qrup setirinde mexrec sagird sayi deyil';
end $$;
\echo 'OK  5 · tapsiriq siyahisi kime verildiyini gosterir'

-- =====================================================================
--  6. Secim siyahisi: ferdi teyinat testi siyahidan cixarmir
-- =====================================================================
do $$
declare v jsonb; t2 uuid; row2 jsonb; t1 uuid; row1 jsonb;
begin
  select id into t1 from public.tests where slug = 'riy-3-vurma-1';
  select id into t2 from public.tests where slug = 'riy-3-qarisiq-1';
  v := public.rpc_available_tests('cccc0000-0000-0000-0000-0000000000f1');
  select x into row1 from jsonb_array_elements(v) x where x->>'id' = t1::text;
  select x into row2 from jsonb_array_elements(v) x where x->>'id' = t2::text;
  --  qrup teyinati olan test "assigned" ile isarelenir
  assert row1->>'assigned' is not null, 'qrup teyinati assigned kimi gelmir';
  --  yalniz ferdi verilen test hele de bosdur (basqasina da vermek olar)
  assert row2->>'assigned' is null, 'ferdi teyinat testi siyahidan cixdi';
  assert (row2->>'assigned_n')::int = 2, 'assigned_n sehvdir: ' || row2->>'assigned_n';
end $$;
\echo 'OK  6 · ferdi teyinat testi secim siyahisinda qalir (assigned_n ile)'

-- =====================================================================
--  7. Sehvler uzerinde is testi YALNIZ hemin sagirde gedir
-- =====================================================================
reset role; reset request.jwt.claim.sub;
do $$
declare tok text; att uuid; ans jsonb := '[]'::jsonb; r record; k int := 0; oid uuid;
begin
  --  A 4 duz / 2 sehv isleyir
  tok := public.rpc_student_login('FERD0001')->>'token';
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

set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f1';
do $$
declare v jsonb; rt uuid; sid uuid;
begin
  v  := public.rpc_remedial_test('5555000f-0000-0000-0000-0000000000f1');
  rt := (v->>'test_id')::uuid;
  select a.student_id into sid from public.assignments a where a.test_id = rt;
  assert sid = '5555000f-0000-0000-0000-0000000000f1',
         'duzelis testi ferdi verilmedi: ' || coalesce(sid::text, 'BOS (butun qrupa)');
end $$;

reset role; reset request.jwt.claim.sub;
do $$
declare vA jsonb; vB jsonb; nA int; nB int; tA text; tB text;
begin
  tA := public.rpc_student_login('FERD0001')->>'token';
  tB := public.rpc_student_login('FERD0002')->>'token';
  vA := public.rpc_student_tests(tA);
  vB := public.rpc_student_tests(tB);
  select count(*) into nA from jsonb_array_elements(vA->'assigned') x
   where x->>'title' like '%səhvlər üzərində iş%';
  select count(*) into nB from jsonb_array_elements(vB->'assigned') x
   where x->>'title' like '%səhvlər üzərində iş%';
  assert nA = 1, 'sagird oz duzelis testini gormur';
  assert nB = 0, 'BASQA sagird duzelis testini gorur - sizinti';
end $$;
\echo 'OK  7 · duzelis testi yalniz oz sagirdine gedir'

reset role; reset request.jwt.claim.sub;
\echo ''
\echo 'FERDI TAPSIRIQ: BUTUN YOXLAMALAR KECDI'
