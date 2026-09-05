-- =====================================================================
--  smoke_teyinat_ikili.sql : eyni test qrupa VE ferdi (db/123)
--
--  Canli hadise: "Bitir" -> "more than one row returned by a subquery".
--  Iddialar: qrup + ferdi teyinat bir yerde -> baslamaq ve bitirmek
--  isleyir · ferdi hedd ustundur · basqa sagirdin ferdi teyinati
--  bu sagirde tesir etmir · yalniz-ferdi teyinatda qrup yoldasi baslaya
--  bilmir (serbest mesq bagli olanda).
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
  ('11110000-0000-0000-0000-0000000000e1','ik@t.az','{"full_name":"Ikili Muellim"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000e1','tutor','Ikili hesabi',
   '11110000-0000-0000-0000-0000000000e1');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000e1','11110000-0000-0000-0000-0000000000e1',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code, free_practice) values
  ('cccc0000-0000-0000-0000-0000000000e1','aaaa0000-0000-0000-0000-0000000000e1',
   '11110000-0000-0000-0000-0000000000e1','tutor_group','Ikili qrup','KODIKI01', false);
insert into public.students (id, account_id, class_id, created_by,
                             full_name, display_name, login_code) values
  ('5555000e-0000-0000-0000-0000000000e1','aaaa0000-0000-0000-0000-0000000000e1',
   'cccc0000-0000-0000-0000-0000000000e1','11110000-0000-0000-0000-0000000000e1',
   'Huseyn Bir','Huseyn B.','IKIL0001'),
  ('5555000e-0000-0000-0000-0000000000e2','aaaa0000-0000-0000-0000-0000000000e1',
   'cccc0000-0000-0000-0000-0000000000e1','11110000-0000-0000-0000-0000000000e1',
   'Ayan Iki','Ayan I.','IKIL0002');
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-0000000000e1', p.id, 'active', now() + interval '30 days'
  from public.plans p where p.slug = 'repetitor-25';

--  cavab siyahisi: butun suallara ilk DUZ varianti
create or replace function pg_temp.cavablar(p_test uuid) returns jsonb language sql as $$
  select coalesce(jsonb_agg(jsonb_build_object('q', q.id, 'o', jsonb_build_array(
           (select o.id from public.question_options o
             where o.question_id = q.id and o.is_correct order by o.ord limit 1)))), '[]'::jsonb)
    from public.test_questions tq join public.questions q on q.id = tq.question_id
   where tq.test_id = p_test
$$;

\echo '--- hazirliq tamam'

-- =====================================================================
--  1. Qrupa 1 cehd, Huseyne ferdi 3 cehd - basla + bitir isleyir
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000e1';
do $$
declare t1 uuid;
begin
  select id into t1 from public.tests where slug = 'riy-3-vurma-1';
  perform public.rpc_assign_test('cccc0000-0000-0000-0000-0000000000e1', t1, null, 1, null);
  perform public.rpc_assign_test('cccc0000-0000-0000-0000-0000000000e1', t1, null, 3,
                                 '5555000e-0000-0000-0000-0000000000e1');
  assert (select count(*) from public.assignments where test_id = t1) = 2, 'iki teyinat yaranmadi';
end $$;
reset role; reset request.jwt.claim.sub;
do $$
declare tok text; t1 uuid; att uuid; r jsonb;
begin
  select id into t1 from public.tests where slug = 'riy-3-vurma-1';
  tok := public.rpc_student_login('IKIL0001')->>'token';
  att := (public.rpc_start_attempt(tok, t1)->>'attempt_id')::uuid;
  r := public.rpc_submit_attempt(tok, att, pg_temp.cavablar(t1));   -- canlida burada partlayirdi
  assert (r->>'percent')::numeric = 100, 'bal hesablanmadi';
  assert (r->>'can_retry')::boolean, 'ferdi hedd 3 idi - tekrar icaze olmalidir';
end $$;
\echo 'OK  1 · qrup + ferdi teyinat: basla ve bitir isleyir, ferdi hedd ustundur'

-- =====================================================================
--  2. Ferdi heddin sonuna qeder gedir (3), 4-cu dayanir
-- =====================================================================
do $$
declare tok text; t1 uuid; att uuid; ok boolean := false;
begin
  select id into t1 from public.tests where slug = 'riy-3-vurma-1';
  tok := public.rpc_student_login('IKIL0001')->>'token';
  att := (public.rpc_start_attempt(tok, t1)->>'attempt_id')::uuid;
  perform public.rpc_submit_attempt(tok, att, pg_temp.cavablar(t1));
  att := (public.rpc_start_attempt(tok, t1)->>'attempt_id')::uuid;
  perform public.rpc_submit_attempt(tok, att, pg_temp.cavablar(t1));
  begin
    perform public.rpc_start_attempt(tok, t1);
  exception when others then ok := true; end;
  assert ok, '4-cu cehd kecdi - qrup heddi (1) yox, ferdi (3) islemelidir, amma 3-den cox yox';
end $$;
\echo 'OK  2 · ferdi hedd 3: ucuncu olur, dorduncu yox'

-- =====================================================================
--  3. Qrup yoldasi Ayan: ferdi teyinat ona aid deyil - qrup heddi 1
-- =====================================================================
do $$
declare tok text; t1 uuid; att uuid; r jsonb; ok boolean := false;
begin
  select id into t1 from public.tests where slug = 'riy-3-vurma-1';
  tok := public.rpc_student_login('IKIL0002')->>'token';
  att := (public.rpc_start_attempt(tok, t1)->>'attempt_id')::uuid;
  r := public.rpc_submit_attempt(tok, att, pg_temp.cavablar(t1));
  assert not (r->>'can_retry')::boolean, 'Ayana Huseynin ferdi heddi (3) tetbiq olundu!';
  begin
    perform public.rpc_start_attempt(tok, t1);
  exception when others then ok := true; end;
  assert ok, 'Ayan ikinci cehde basladi - qrup heddi 1 idi';
end $$;
\echo 'OK  3 · basqa sagirdin ferdi teyinati qrup yoldasina tesir etmir'

-- =====================================================================
--  4. Yalniz ferdi teyinat (Huseyne), serbest mesq bagli: Ayan baslaya bilmir
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000e1';
do $$
declare t2 uuid;
begin
  select id into t2 from public.tests where slug = 'riy-3-qarisiq-1';
  perform public.rpc_assign_test('cccc0000-0000-0000-0000-0000000000e1', t2, null, 2,
                                 '5555000e-0000-0000-0000-0000000000e1');
end $$;
reset role; reset request.jwt.claim.sub;
do $$
declare tok text; t2 uuid; ok boolean := false;
begin
  select id into t2 from public.tests where slug = 'riy-3-qarisiq-1';
  tok := public.rpc_student_login('IKIL0002')->>'token';
  begin
    perform public.rpc_start_attempt(tok, t2);
  exception when others then ok := true; end;
  assert ok, 'Ayan Huseynin ferdi teyinati ile testi basladi!';
  tok := public.rpc_student_login('IKIL0001')->>'token';
  perform public.rpc_start_attempt(tok, t2);
end $$;
\echo 'OK  4 · yalniz-ferdi teyinat: sahibi baslayir, qrup yoldasi yox'
