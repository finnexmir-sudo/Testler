-- =====================================================================
--  smoke_kurikulum.sql : kurikulum paketi (db/135)
--
--  Iddialar: isinme kecilmemis movzuya yigilir (5 asan/orta sual, 1 gun,
--  1 cehd), ikinci defe reddedilir · ev tapsirigi yalniz kecilmis
--  movzuya (movcud) · rub sinagi son sinaqdan beri kecilmis movzulardan,
--  ikinci sinaq yalniz yeni movzular, p_all hamisi · paket ekrani ve
--  "bu gunun dersi" isinmeni gorur · yad hesab gore bilmir.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.plan_exams;
delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers;  delete from public.attempts;
delete from public.assignments;      delete from public.student_sessions;
delete from public.students;         delete from public.classes;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.subscriptions;
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-00000000c0d1','kp@t.az','{"full_name":"Paket Muellim"}'),
  ('11110000-0000-0000-0000-00000000c0d2','kp2@t.az','{"full_name":"Yad Muellim"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-00000000c0d1','tutor','KP hesabi','11110000-0000-0000-0000-00000000c0d1'),
  ('aaaa0000-0000-0000-0000-00000000c0d2','tutor','Yad hesabi','11110000-0000-0000-0000-00000000c0d2');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-00000000c0d1','11110000-0000-0000-0000-00000000c0d1',true),
  ('aaaa0000-0000-0000-0000-00000000c0d2','11110000-0000-0000-0000-00000000c0d2',true);
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-00000000c0d1', p.id, 'active', now() + interval '30 days'
  from public.plans p where p.slug = 'repetitor-25';
insert into public.classes (id, account_id, teacher_id, kind, name, join_code, level_id) values
  ('cccc0000-0000-0000-0000-00000000c0d1','aaaa0000-0000-0000-0000-00000000c0d1',
   '11110000-0000-0000-0000-00000000c0d1','tutor_group','KP qrup','KODKP001',
   (select id from public.levels where code = '3' order by sort limit 1));
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code) values
  ('5555000c-0000-0000-0000-00000000c0d1','aaaa0000-0000-0000-0000-00000000c0d1',
   'cccc0000-0000-0000-0000-00000000c0d1','11110000-0000-0000-0000-00000000c0d1','Ayan Bir','Ayan B.','KPFT0001');

set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-00000000c0d1';
do $$
begin
  perform public.rpc_plan_create('cccc0000-0000-0000-0000-00000000c0d1', 'riyaziyyat', '3');
end $$;
reset role;
select set_config('smoke.plan', (select id::text from public.class_plans limit 1), false);
select set_config('smoke.i1', (select id::text from public.class_plan_items order by ord limit 1), false);
select set_config('smoke.i2', (select id::text from public.class_plan_items order by ord offset 1 limit 1), false);
select set_config('smoke.i3', (select id::text from public.class_plan_items order by ord offset 2 limit 1), false);
\echo '--- hazirliq tamam'

-- =====================================================================
--  1. Isinme: kecilmemis movzuya, 5 asan/orta sual, 1 gun, 1 cehd; tekrar yox
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-00000000c0d1';
do $$
declare i1 uuid := current_setting('smoke.i1')::uuid; v jsonb; bad boolean := false;
begin
  v := public.rpc_pack_warm(i1, 5);
  assert (v->>'count')::int = 5, 'isinme 5 sual: ' || (v->>'count');
  perform set_config('smoke.t1', v->>'test_id', false);
  begin perform public.rpc_pack_warm(i1, 5); exception when others then bad := true; end;
  assert bad, 'ikinci isinme qebul olundu';
end $$;
reset role;
do $$
declare t uuid := current_setting('smoke.t1')::uuid; n int;
begin
  assert (select warm_test_id from public.class_plan_items where id = current_setting('smoke.i1')::uuid) = t, 'warm_test_id yazilmadi';
  assert (select title from public.tests where id = t) like 'İsinmə — %', 'ad';
  select count(*) into n from public.test_questions tq join public.questions q on q.id = tq.question_id
   where tq.test_id = t and q.difficulty = 3;
  assert n = 0, 'isinmede cetin sual olmamali';
  assert (select max_attempts = 1 and closes_at between now() + interval '23 hours' and now() + interval '25 hours'
            from public.assignments where test_id = t), 'teyinat 1 gun, 1 cehd';
  assert (select gen_rule->>'pack' from public.tests where id = t) = 'warm', 'gen_rule pack';
end $$;
\echo 'OK  1 · isinme: 5 asan/orta sual, 1 gun, 1 cehd, tekrar yox'

-- =====================================================================
--  2. Sinaq: kecilmis movzu yoxdur -> xeta; 2 movzu kecildi -> sinaq 2
--     movzudan; ikinci sinaq yalniz yeni movzudan; p_all hamisi
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-00000000c0d1';
do $$
declare p uuid := current_setting('smoke.plan')::uuid; v jsonb; bad boolean := false; g jsonb;
begin
  begin perform public.rpc_pack_exam(p, 20, false); exception when others then bad := true; end;
  assert bad, 'kecilmis movzusuz sinaq yigildi';
  perform public.rpc_plan_done(current_setting('smoke.i1')::uuid);
  perform public.rpc_plan_done(current_setting('smoke.i2')::uuid);
  g := public.rpc_pack_get(p);
  assert (g->>'exam_pending')::int = 2, 'sinaq gozleyen 2';
  v := public.rpc_pack_exam(p, 20, false);
  perform set_config('smoke.t2', v->>'test_id', false);
  assert (v->>'items')::int = 2 and (v->>'count')::int between 5 and 20, 'sinaq 2 movzudan: ' || v::text;
  g := public.rpc_pack_get(p);
  assert (g->>'exam_pending')::int = 0 and jsonb_array_length(g->'exams') = 1, 'sinaqdan sonra gozleyen 0';
  assert g->'exams'->0->>'title' like 'Rüb sınağı — Riyaziyyat · 2 mövzu', 'sinaq adi: ' || (g->'exams'->0->>'title');
  --  ucuncu movzu kecildi -> yeni sinaq yalniz ondan
  perform public.rpc_plan_done(current_setting('smoke.i3')::uuid);
  v := public.rpc_pack_exam(p, 10, false);
  assert (v->>'items')::int = 1, 'ikinci sinaq yalniz yeni movzudan: ' || (v->>'items');
  v := public.rpc_pack_exam(p, 15, true);
  assert (v->>'items')::int = 3, 'p_all 3 movzu';
end $$;
reset role;
do $$
declare t uuid := current_setting('smoke.t2')::uuid;
begin
  assert (select cardinality(item_ids) = 2 from public.plan_exams where test_id = t), 'plan_exams';
  assert (select max_attempts = 1 and closes_at > now() + interval '6 days' from public.assignments where test_id = t), 'sinaq teyinati 7 gun';
  assert (select gen_rule->>'pack' = 'exam' and gen_rule->>'plan' = current_setting('smoke.plan') from public.tests where id = t), 'sinaq gen_rule';
end $$;
\echo 'OK  2 · sinaq: son sinaqdan beri kecilenler, ikinci yalniz yeni, p_all hamisi'

-- =====================================================================
--  3. Paket ekrani + bu gunun dersi; yad hesab gore bilmir
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-00000000c0d1';
do $$
declare p uuid := current_setting('smoke.plan')::uuid; g jsonb; d jsonb; it jsonb; i int;
begin
  g := public.rpc_pack_get(p);
  assert g->'plan'->>'subject' = 'Riyaziyyat' and (g->'plan'->>'done')::int = 3, 'plan basligi';
  assert (g->>'paid')::boolean and (g->>'students')::int = 1, 'paid/students';
  assert jsonb_array_length(g->'exams') = 3, '3 sinaq';
  for i in 0..jsonb_array_length(g->'items') - 1 loop
    if g->'items'->i->>'id' = current_setting('smoke.i1') then it := g->'items'->i; end if;
  end loop;
  assert it->'warm'->>'test_id' is not null and (it->>'done')::boolean and (it->>'examined')::boolean and jsonb_typeof(it->'hw') = 'null', 'ilk movzu: isinme var, ev tapsirigi yox, sinaqda';
  assert jsonb_typeof(g->'items'->3->'warm') = 'null' and not (g->'items'->3->>'done')::boolean, 'dorduncu movzu bos';
  --  bu gunun dersi: novbeti movzunun isinmesi yoxdur; plan_id gelir
  d := public.rpc_lesson_prep('cccc0000-0000-0000-0000-00000000c0d1');
  assert d->>'plan_id' = p::text, 'prep plan_id';
  assert d->'next'->'warm_test_id' = 'null'::jsonb, 'novbeti movzuda isinme hele yoxdur';
  perform public.rpc_pack_warm((d->'next'->>'item_id')::uuid, 5);
  d := public.rpc_lesson_prep('cccc0000-0000-0000-0000-00000000c0d1');
  assert d->'next'->>'warm_test_id' is not null and (d->'next'->>'warm_takers')::int = 0, 'novbeti movzunun isinmesi gorunur';
  --  plan_get de warm_test_id verir
  d := public.rpc_plan_get('cccc0000-0000-0000-0000-00000000c0d1');
  assert d->'plans'->0->'items'->0->>'warm_test_id' is not null, 'plan_get warm_test_id';
end $$;
set request.jwt.claim.sub = '11110000-0000-0000-0000-00000000c0d2';
do $$
declare bad boolean := false;
begin
  begin perform public.rpc_pack_get(current_setting('smoke.plan')::uuid); exception when others then bad := true; end;
  assert bad, 'yad hesab paketi gordu';
  bad := false;
  begin perform public.rpc_pack_warm(current_setting('smoke.i1')::uuid, 5); exception when others then bad := true; end;
  assert bad, 'yad hesab isinme yigdi';
end $$;
reset role;
\echo 'OK  3 · paket ekrani, bu gunun dersi, plan_get; yad hesab gore bilmir'

\echo 'KURIKULUM: BUTUN YOXLAMALAR KECDI'
