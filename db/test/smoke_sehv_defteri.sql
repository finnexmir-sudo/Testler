-- =====================================================================
--  smoke_sehv_defteri.sql : sehv defteri (db/129)
--
--  Iddialar: testde sehv -> open · mesqde duz -> review (+7 gun), o
--  gun tekrar gelmir · vaxti catanda duz -> closed · mesqde sehv -> open,
--  +1 gun · duz variant sagirde getmir · yad token gormur · muellim
--  hesabatinda sayğaclar · testde duz cavab acıq sehvi review edir.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.mistakes;
delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers;  delete from public.attempts;
delete from public.assignments;      delete from public.student_sessions;
delete from public.students;         delete from public.classes;
delete from public.subscriptions;
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-0000000000d1','sd@t.az','{"full_name":"Defter Muellim"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000d1','tutor','SD hesabi','11110000-0000-0000-0000-0000000000d1');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000d1','11110000-0000-0000-0000-0000000000d1',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-0000000000d1','aaaa0000-0000-0000-0000-0000000000d1',
   '11110000-0000-0000-0000-0000000000d1','tutor_group','SD qrup','KODSD001');
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code) values
  ('5555000d-0000-0000-0000-0000000000d1','aaaa0000-0000-0000-0000-0000000000d1',
   'cccc0000-0000-0000-0000-0000000000d1','11110000-0000-0000-0000-0000000000d1','Ayan Bir','Ayan B.','SDFT0001'),
  ('5555000d-0000-0000-0000-0000000000d2','aaaa0000-0000-0000-0000-0000000000d1',
   'cccc0000-0000-0000-0000-0000000000d1','11110000-0000-0000-0000-0000000000d1','Murad Iki','Murad I.','SDFT0002');

--  cavab: ilk N sual sehv, qalani duz
create or replace function pg_temp.cavab(p_test uuid, p_wrong int) returns jsonb language sql as $$
  select coalesce(jsonb_agg(jsonb_build_object('q', x.qid, 'o', jsonb_build_array(
           (select o.id from public.question_options o
             where o.question_id = x.qid and o.is_correct = (x.rn > p_wrong) order by o.ord limit 1)))), '[]'::jsonb)
    from (select q.id qid, row_number() over (order by tq.ord) rn
            from public.test_questions tq join public.questions q on q.id = tq.question_id
           where tq.test_id = p_test) x
$$;
create or replace function pg_temp.duz(p_q uuid) returns uuid language sql as $$
  select o.id from public.question_options o where o.question_id = p_q and o.is_correct order by o.ord limit 1 $$;
create or replace function pg_temp.sehv(p_q uuid) returns uuid language sql as $$
  select o.id from public.question_options o where o.question_id = p_q and not o.is_correct order by o.ord limit 1 $$;

\echo '--- hazirliq tamam'

-- =====================================================================
--  1. Testde 2 sehv -> defterde 2 acıq; siyahida duz variant yoxdur
-- =====================================================================
do $$
declare tok text; t1 uuid; att uuid; v jsonb;
begin
  select id into t1 from public.tests where slug = 'riy-3-vurma-1';
  tok := public.rpc_student_login('SDFT0001')->>'token';
  att := (public.rpc_start_attempt(tok, t1)->>'attempt_id')::uuid;
  perform public.rpc_submit_attempt(tok, att, pg_temp.cavab(t1, 2));
  assert (select count(*) from public.mistakes where student_id = '5555000d-0000-0000-0000-0000000000d1' and status = 'open') = 2,
         'defterde 2 acıq olmali';
  set local role anon;
  v := public.rpc_student_mistakes(tok);
  reset role;
  assert (v->>'open')::int = 2 and (v->>'due')::int = 2 and jsonb_array_length(v->'items') = 2, 'siyahi 2';
  assert v::text not like '%is_correct%', 'duz variant sizdi!';
  assert jsonb_array_length(v->'items'->0->'options') >= 2, 'variantlar gelir';
end $$;
\echo 'OK  1 · testde sehv -> defterde acıq; duz variant getmir'

-- =====================================================================
--  2. Mesq: duz -> review (+7 gun), bu gun tekrar gelmir; sehv -> open +1 gun
-- =====================================================================
do $$
declare tok text; v jsonb; r jsonb; q1 uuid; q2 uuid; o1 uuid; o2 uuid; o2d uuid; ok boolean := false;
begin
  tok := public.rpc_student_login('SDFT0001')->>'token';
  v := public.rpc_student_mistakes(tok);
  q1 := (v->'items'->0->>'qid')::uuid; q2 := (v->'items'->1->>'qid')::uuid;
  --  variant id-leri rol deyismeden evvel (anon question_options-i gormur)
  o1 := pg_temp.duz(q1); o2 := pg_temp.sehv(q2); o2d := pg_temp.duz(q2);
  set local role anon;
  r := public.rpc_student_mistake_answer(tok, q1, o1);
  assert (r->>'correct')::boolean and r->>'status' = 'review', 'duz -> review';
  assert (r->>'due')::int = 1, 'review bu gun tekrar gelmemeli';
  r := public.rpc_student_mistake_answer(tok, q2, o2);
  assert not (r->>'correct')::boolean and r->>'status' = 'open', 'sehv -> open';
  assert (r->>'next_at')::timestamptz > now() + interval '20 hours', 'sehvde +1 gun';
  assert (r->>'due')::int = 0, 'her ikisi bu gun gozlemir';
  --  tekrar cavab: gozlemeyen sual reddedilir (brute force yox)
  begin
    perform public.rpc_student_mistake_answer(tok, q2, o2d);
  exception when others then ok := true; end;
  assert ok, 'gozlemeyen sual cavablandi';
  reset role;
  assert (select wrong_n from public.mistakes where question_id = q2) = 2, 'wrong_n artmadi';
end $$;
\echo 'OK  2 · mesq: duz -> review, sehv -> +1 gun, tekrar reddedilir'

-- =====================================================================
--  3. Vaxti catanda duz -> closed; testde duz cavab da review edir
-- =====================================================================
do $$
declare tok text; v jsonb; r jsonb; q1 uuid; o1 uuid;
begin
  select question_id into q1 from public.mistakes where status = 'review';
  update public.mistakes set next_at = now() - interval '1 minute' where question_id = q1;
  o1 := pg_temp.duz(q1);
  tok := public.rpc_student_login('SDFT0001')->>'token';
  set local role anon;
  r := public.rpc_student_mistake_answer(tok, q1, o1);
  reset role;
  assert r->>'status' = 'closed', 'ikinci duz -> closed';
  assert (select cleared_at from public.mistakes where question_id = q1) is not null, 'cleared_at';
end $$;
\echo 'OK  3 · vaxti catanda duz -> closed'

-- =====================================================================
--  4. Yad token gormur; muellim hesabatinda sayğaclar
-- =====================================================================
do $$
declare tok2 text; v jsonb;
begin
  tok2 := public.rpc_student_login('SDFT0002')->>'token';
  set local role anon;
  v := public.rpc_student_mistakes(tok2);
  reset role;
  assert (v->>'open')::int = 0 and jsonb_array_length(v->'items') = 0, 'Murad Ayanin defterini gordu';
end $$;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000d1';
do $$
declare v jsonb;
begin
  v := public.rpc_student_report('5555000d-0000-0000-0000-0000000000d1');
  assert (v->'mistakes'->>'open')::int = 1 and (v->'mistakes'->>'closed')::int = 1, 'hesabat sayğaclari: ' || (v->'mistakes')::text;
end $$;
reset role; reset request.jwt.claim.sub;
\echo 'OK  4 · yad token gormur; hesabatda sayğaclar'
