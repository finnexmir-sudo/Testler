-- =====================================================================
--  smoke_hedefli.sql : test qrupun SECILMIS sagirdlerine (db/934)
--  A, B, D - F qrupunda; C - F ikinci qrupunda
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
   'Ferdi Uc','Ferdi U.','FERD0003'),
  ('5555000f-0000-0000-0000-0000000000f4','aaaa0000-0000-0000-0000-0000000000f1',
   'cccc0000-0000-0000-0000-0000000000f1','11110000-0000-0000-0000-0000000000f1',
   'Ferdi Dord','Ferdi D.','FERD0004');

insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-0000000000f1', p.id, 'active', now() + interval '30 days'
  from public.plans p where p.slug = 'repetitor-25';

\echo '--- hazirliq tamam'

-- 1 · A ve D-ye: iki ferdi setir, B gormur, A ve D gorur
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f1';
do $$
declare t1 uuid; v jsonb;
begin
  select id into t1 from public.tests where slug = 'riy-3-vurma-1';
  perform set_config('smoke.t1', t1::text, false);
  v := public.rpc_assign_test_many('cccc0000-0000-0000-0000-0000000000f1', t1,
         array['5555000f-0000-0000-0000-0000000000f1','5555000f-0000-0000-0000-0000000000f4',
               '5555000f-0000-0000-0000-0000000000f1']::uuid[],   -- tekrar id atilir
         now() + interval '7 days', 1);
  assert (v->>'count')::int = 2, 'say 2 olmali idi: ' || v::text;
  assert v->'students' = '["Ferdi B.", "Ferdi D."]'::jsonb, 'adlar: ' || (v->'students')::text;
  assert (select count(*) from public.assignments where test_id = t1) = 2, 'iki setir olmali idi';
  assert not exists (select 1 from public.assignments where test_id = t1 and student_id is null), 'qrup setri yarandi';
end $$;
reset role; reset request.jwt.claim.sub;
do $$
declare tA text; tB text; tD text;
begin
  tA := public.rpc_student_login('FERD0001')->>'token';
  tB := public.rpc_student_login('FERD0002')->>'token';
  tD := public.rpc_student_login('FERD0004')->>'token';
  assert jsonb_array_length(public.rpc_student_tests(tA)->'assigned') = 1, 'A testi gormur';
  assert jsonb_array_length(public.rpc_student_tests(tD)->'assigned') = 1, 'D testi gormur';
  assert jsonb_array_length(public.rpc_student_tests(tB)->'assigned') = 0, 'B (secilmeyib) testi gorur';
  assert (public.rpc_student_tests(tA)->'assigned'->0->>'personal')::boolean, 'A-da ferdi sayilmadi';
end $$;
\echo 'OK  1 · secilmis 2 sagird gorur, secilmeyen gormur, tekrar id bir defe'

-- 2 · basqa qrupun sagirdi (C) siyahida - HEC BIRI yazilmir (atomik)
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f1';
do $$
declare t2 uuid; ok boolean := false;
begin
  select id into t2 from public.tests where owner_type = 'platform' and is_free and status = 'published'
     and id <> current_setting('smoke.t1')::uuid order by slug limit 1;
  perform set_config('smoke.t2', t2::text, false);
  begin
    perform public.rpc_assign_test_many('cccc0000-0000-0000-0000-0000000000f1', t2,
      array['5555000f-0000-0000-0000-0000000000f2','5555000f-0000-0000-0000-0000000000f3']::uuid[]);
  exception when others then ok := true; end;
  assert ok, 'basqa qrupun sagirdi kecdi';
  assert not exists (select 1 from public.assignments where test_id = t2), 'yarimciq yazildi (atomik deyil)';
  ok := false;
  begin perform public.rpc_assign_test_many('cccc0000-0000-0000-0000-0000000000f1', t2,
          array['99999999-0000-0000-0000-000000000000']::uuid[]);
  exception when others then ok := true; end;
  assert ok, 'movcud olmayan sagird kecdi';
  ok := false;
  begin perform public.rpc_assign_test_many('cccc0000-0000-0000-0000-0000000000f1', t2, '{}'::uuid[]);
  exception when others then ok := true; end;
  assert ok, 'bos siyahi kecdi';
end $$;
\echo 'OK  2 · basqa qrupun / movcud olmayan sagird, bos siyahi - redd, hec ne yazilmir'

-- 3 · test butun qrupa verilibse - redd
do $$
declare t2 uuid := current_setting('smoke.t2')::uuid; ok boolean := false;
begin
  perform public.rpc_assign_test('cccc0000-0000-0000-0000-0000000000f1', t2, null, 1);
  begin perform public.rpc_assign_test_many('cccc0000-0000-0000-0000-0000000000f1', t2,
          array['5555000f-0000-0000-0000-0000000000f2']::uuid[]);
  exception when others then ok := true; end;
  assert ok, 'qrupa verilmis teste ferdi siyahi kecdi';
end $$;
\echo 'OK  3 · butun qrupa verilmis teste hedefli siyahi verilmir'

-- 4 · muellimin siyahisi: iki ferdi setir, her biri oz sagirdi ile
do $$
declare v jsonb; n int;
begin
  v := public.rpc_class_assignments('cccc0000-0000-0000-0000-0000000000f1');
  select count(*) into n from jsonb_array_elements(v->'items') x
   where x->>'test_id' = current_setting('smoke.t1') and x->>'student_id' is not null;
  assert n = 2, 'siyahida ferdi setir sayi: ' || n;
end $$;
\echo 'OK  4 · rpc_class_assignments iki ferdi setri verir (panel bir setire yigir)'
reset role; reset request.jwt.claim.sub;

-- 5 · yad muellim
insert into auth.users (id, email) values ('11110000-0000-0000-0000-0000000000f9','yad@t.az');
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f9';
do $$
declare ok boolean := false;
begin
  begin perform public.rpc_assign_test_many('cccc0000-0000-0000-0000-0000000000f1', current_setting('smoke.t1')::uuid,
          array['5555000f-0000-0000-0000-0000000000f2']::uuid[]);
  exception when insufficient_privilege then ok := true; end;
  assert ok, 'yad muellim teyin etdi';
end $$;
reset role; reset request.jwt.claim.sub;
\echo 'OK  5 · yad muellim tapsiriq vere bilmir'
set role anon;
do $$ declare ok boolean := false;
begin
  begin perform public.rpc_assign_test_many(gen_random_uuid(), gen_random_uuid(), array[gen_random_uuid()]);
  exception when insufficient_privilege then ok := true; end;
  assert ok, 'anon cagira bildi';
end $$;
reset role;
\echo 'OK  6 · anon cagira bilmir'
\echo 'HEDEFLI TAPSIRIQ: BUTUN YOXLAMALAR KECDI'
