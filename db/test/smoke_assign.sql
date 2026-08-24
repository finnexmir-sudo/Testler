-- =====================================================================
--  smoke_assign.sql : test teyinatlari
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments; delete from public.student_sessions;
delete from public.students; delete from public.classes;
delete from public.subscriptions; delete from public.account_members;
delete from public.accounts; delete from public.user_roles;
delete from public.profiles; delete from auth.users;

insert into auth.users (id, email) values
  ('11110000-0000-0000-0000-000000000001','a@t.az'),
  ('22220000-0000-0000-0000-000000000002','b@t.az');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-000000000001','tutor','A','11110000-0000-0000-0000-000000000001'),
  ('aaaa0000-0000-0000-0000-000000000002','tutor','B','22220000-0000-0000-0000-000000000002');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-000000000001','11110000-0000-0000-0000-000000000001',true),
  ('aaaa0000-0000-0000-0000-000000000002','22220000-0000-0000-0000-000000000002',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code, level_id)
select 'cccc0000-0000-0000-0000-000000000001','aaaa0000-0000-0000-0000-000000000001',
       '11110000-0000-0000-0000-000000000001','tutor_group','Sentyabr','KODSENT1', l.id
  from public.levels l join public.programs p on p.id = l.program_id
 where p.slug='ibtidai' and l.code='3';
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code)
values ('5555000a-0000-0000-0000-000000000001','aaaa0000-0000-0000-0000-000000000001',
        'cccc0000-0000-0000-0000-000000000001','11110000-0000-0000-0000-000000000001',
        'Eli Mirzeyev','Eli M.','ELI11111');

drop table if exists public.test_fixtures;
create table public.test_fixtures (k text primary key, v uuid);
insert into public.test_fixtures select slug, id from public.tests where slug in
  ('riy-3-vurma-1','riy-3-qarisiq-1','az-3-dil-1');
grant select on public.test_fixtures to anon, authenticated;

-- Duzgun cavab acari: anon rolu questions/question_options oxuya bilmir
drop table if exists public.answer_fixtures;
create table public.answer_fixtures (k text primary key, v jsonb);
insert into public.answer_fixtures
select t.slug,
       (select jsonb_agg(jsonb_build_object('q', q.id, 'o', jsonb_build_array(
                 (select o.id from public.question_options o
                   where o.question_id = q.id and o.is_correct limit 1))))
          from public.questions q where q.test_id = t.id)
  from public.tests t
 where t.slug in ('riy-3-vurma-1','riy-3-qarisiq-1','az-3-dil-1');
grant select on public.answer_fixtures to anon, authenticated;

\echo '--- hazirliq tamam'

set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-000000000001';

-- =====================================================================
--  1. Teyin edile bilen testler: sinife uygun suzulur
-- =====================================================================
do $$
declare v jsonb;
begin
  v := public.rpc_available_tests('cccc0000-0000-0000-0000-000000000001');
  assert jsonb_array_length(v) >= 3, format('test sayi: %s', jsonb_array_length(v));
  assert (select bool_and((x->>'assigned') is null) from jsonb_array_elements(v) x),
         'hele hec ne teyin olunmayib, amma assigned dolu';
  assert (select bool_and(x->>'subject' is not null) from jsonb_array_elements(v) x),
         'fenn adi yoxdur';
end $$;
\echo 'OK  1 · teyin edile bilen testler siyahisi'

-- =====================================================================
--  2. Teyinat yaratmaq
-- =====================================================================
do $$
declare v jsonb; t uuid;
begin
  select id into t from public.tests where slug = 'riy-3-vurma-1';
  v := public.rpc_assign_test('cccc0000-0000-0000-0000-000000000001', t,
                              now() + interval '3 days', 2);
  assert v->>'id' is not null, 'teyinat yaranmadi';
  assert v->>'test' is not null, 'test adi qayitmadi';

  -- Eyni testi tekrar teyin etmek yeni setir yaratmir, yenileyir
  v := public.rpc_assign_test('cccc0000-0000-0000-0000-000000000001', t,
                              now() + interval '7 days', 1);
  assert (select count(*) from public.assignments
           where class_id='cccc0000-0000-0000-0000-000000000001' and test_id=t) = 1,
         'tekrar teyinat ikinci setir yaratdi';
  assert (select max_attempts from public.assignments where test_id=t) = 1,
         'cehd sayi yenilenmedi';
end $$;
\echo 'OK  2 · teyinat yaranir, tekrar teyinat yenileyir'

-- =====================================================================
--  3. Yanlis giris redd edilir
-- =====================================================================
do $$
declare t uuid; ok1 boolean := false; ok2 boolean := false; ok3 boolean := false;
begin
  select id into t from public.tests where slug = 'riy-3-qarisiq-1';

  begin
    perform public.rpc_assign_test('cccc0000-0000-0000-0000-000000000001', t,
                                   now() - interval '1 day', 1);
    assert false, 'kecmis son tarix qebul edildi';
  exception when invalid_parameter_value then ok1 := true; end;

  begin
    perform public.rpc_assign_test('cccc0000-0000-0000-0000-000000000001', t, null, 99);
    assert false, 'cehd sayi 99 qebul edildi';
  exception when invalid_parameter_value then ok2 := true; end;

  begin
    perform public.rpc_assign_test('cccc0000-0000-0000-0000-000000000001',
                                   gen_random_uuid(), null, 1);
    assert false, 'olmayan test teyin edildi';
  exception when invalid_parameter_value then ok3 := true; end;

  assert ok1 and ok2 and ok3, 'yoxlamalar isləmedi';
end $$;
\echo 'OK  3 · kecmis tarix, hedden artiq cehd ve olmayan test redd edilir'

-- =====================================================================
--  4. Ozge muellim bu qrupa teyinat ede bilmir
-- =====================================================================
set request.jwt.claim.sub = '22220000-0000-0000-0000-000000000002';
do $$
declare t uuid; ok boolean := false;
begin
  select id into t from public.tests where slug = 'az-3-dil-1';
  begin
    perform public.rpc_assign_test('cccc0000-0000-0000-0000-000000000001', t, null, 1);
    assert false, 'ozge muellim teyinat etdi!';
  exception when insufficient_privilege then ok := true; end;
  assert ok, 'icaze xetasi gelmedi';

  begin
    perform public.rpc_class_assignments('cccc0000-0000-0000-0000-000000000001');
    assert false, 'ozge muellim teyinatlari gordu!';
  exception when insufficient_privilege then null; end;
end $$;
\echo 'OK  4 · ozge muellim teyinat ede ve gore bilmir'

-- =====================================================================
--  5. Sagird: tapsiriqlar ayrica, serbest mesq ayrica
-- =====================================================================
set role anon;
reset request.jwt.claim.sub;
do $$
declare tok text; v jsonb; n_a int; n_p int;
begin
  tok := public.rpc_student_login('ELI11111')->>'token';
  v := public.rpc_student_tests(tok);
  n_a := jsonb_array_length(v->'assigned');
  n_p := jsonb_array_length(v->'practice');
  assert n_a = 1, format('tapsiriq sayi: %s', n_a);
  assert v->'assigned'->0->>'closes_at' is not null, 'son tarix gorunmur';
  assert (v->'assigned'->0->>'max_attempts')::int = 1, 'teyinatin cehd sayi gelmir';
  assert n_p >= 2, format('serbest mesq sayi: %s', n_p);
  -- Teyin olunmuş test serbest mesqde TEKRARLANMAMALIDIR
  assert not exists (
    select 1 from jsonb_array_elements(v->'practice') x
     where x->>'id' = v->'assigned'->0->>'id'), 'teyin olunan test iki yerde gorunur';
end $$;
\echo 'OK  5 · tapsiriqlar ve serbest mesq ayri-ayri, tekrarlanma yoxdur'

-- =====================================================================
--  6. Serbest mesq baglananda yalniz tapsiriqlar qalir
-- =====================================================================
reset role;
update public.classes set free_practice = false
 where id = 'cccc0000-0000-0000-0000-000000000001';
set role anon;
do $$
declare tok text; v jsonb; ok boolean := false; t uuid;
begin
  tok := public.rpc_student_login('ELI11111')->>'token';
  v := public.rpc_student_tests(tok);
  assert jsonb_array_length(v->'assigned') = 1, 'tapsiriq itdi';
  assert jsonb_array_length(v->'practice') = 0, 'serbest mesq hele de gorunur';

  -- Serverde de bagli olmalidir
  select f.v into t from public.test_fixtures f where f.k = 'az-3-dil-1';
  begin
    perform public.rpc_start_attempt(tok, t);
    assert false, 'serbest mesq bagli, amma test acildi!';
  exception when insufficient_privilege then ok := true; end;
  assert ok, 'icaze xetasi gelmedi';
end $$;
\echo 'OK  6 · serbest mesq baglananda test serverde de acilmir'

-- =====================================================================
--  7. Teyinatin vaxti bitende test baglanir
-- =====================================================================
reset role;
update public.classes set free_practice = true
 where id = 'cccc0000-0000-0000-0000-000000000001';
update public.assignments set opens_at  = now() - interval '2 hour',
                             closes_at = now() - interval '1 hour';
set role anon;
do $$
declare tok text; v jsonb; t uuid; ok boolean := false;
begin
  tok := public.rpc_student_login('ELI11111')->>'token';
  v := public.rpc_student_tests(tok);
  assert jsonb_array_length(v->'assigned') = 0, 'vaxti bitmiş tapsiriq gorunur';
  -- Vaxti bitmis test serbest mesq hovuzuna qayidir
  assert exists (select 1 from jsonb_array_elements(v->'practice') x
                  where x->>'title' is not null), 'serbest mesq bosdur';

  select f.v into t from public.test_fixtures f where f.k = 'riy-3-vurma-1';
  -- Serbest mesq acıqdir, test platformanindir -> mesq kimi acilmalidir
  assert public.rpc_start_attempt(tok, t)->>'attempt_id' is not null,
         'vaxti bitenden sonra serbest mesq de islemir';
end $$;
\echo 'OK  7 · vaxti biten tapsiriq bağlanir, serbest mesq yolu acıq qalir'

-- =====================================================================
--  8. Teyinatin cehd limiti testin limitini EVEZ EDIR
-- =====================================================================
reset role;
delete from public.attempts;
update public.assignments set opens_at  = now() - interval '1 hour',
                             closes_at = now() + interval '1 day', max_attempts = 2;
set role anon;
do $$
declare tok text; t uuid; att uuid; ans jsonb; i int; ok boolean := false;
begin
  select f.v into t from public.test_fixtures f where f.k = 'riy-3-vurma-1';
  -- Testin ozunde max_attempts = 1, teyinatda 2 -> IKI defe islemek olmalidir
  for i in 1..2 loop
    tok := public.rpc_student_login('ELI11111')->>'token';
    att := (public.rpc_start_attempt(tok, t)->>'attempt_id')::uuid;
    select f.v into ans from public.answer_fixtures f where f.k = 'riy-3-vurma-1';
    perform public.rpc_submit_attempt(tok, att, ans);
  end loop;

  begin
    perform public.rpc_start_attempt(tok, t);
    assert false, 'ucuncu cehd acildi - teyinat limiti islemedi';
  exception when insufficient_privilege then ok := true; end;
  assert ok, 'limit xetasi gelmedi';
end $$;
\echo 'OK  8 · teyinatin cehd limiti testin limitini evez edir'

-- =====================================================================
--  9. Muellim teyinatin gedisatini gorur
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-000000000001';
do $$
declare v jsonb; it jsonb;
begin
  v := public.rpc_class_assignments('cccc0000-0000-0000-0000-000000000001');
  assert (v->>'students')::int = 1, 'sagird sayi';
  assert (v->>'free_practice')::boolean = true, 'serbest mesq ayari';
  assert jsonb_array_length(v->'items') = 1, 'teyinat sayi';
  it := v->'items'->0;
  assert (it->>'open')::boolean = true, 'teyinat acıq gorunmur';
  assert (it->>'done')::int = 1, format('bitiren sagird: %s', it->>'done');
  assert (it->>'avg')::numeric = 100, format('orta netice: %s', it->>'avg');
  assert it->>'closes_at' is not null, 'son tarix yoxdur';
end $$;
\echo 'OK  9 · muellim teyinatin gedisatini gorur'

-- =====================================================================
-- 10. Teyinati silmek
-- =====================================================================
do $$
declare v jsonb; aid uuid;
begin
  select id into aid from public.assignments limit 1;
  v := public.rpc_unassign_test(aid);
  assert (v->>'ok')::boolean, 'silinmedi';
  assert (select count(*) from public.assignments) = 0, 'teyinat qalib';
end $$;
\echo 'OK 10 · teyinat silinir'

reset role;
drop table if exists public.test_fixtures;
drop table if exists public.answer_fixtures;

\echo ''
\echo '=============================='
\echo ' TEYINATLAR: HAMISI KECDI'
\echo '=============================='
