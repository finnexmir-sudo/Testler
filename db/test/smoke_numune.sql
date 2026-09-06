-- =====================================================================
--  smoke_numune.sql : numune (demo) hesab (db/136)
--
--  Iddialar: rpc_demo_reset paylasilan numuneni qurur (2 qrup, 20 sagird,
--  sabit kodlar, 9 movzu kecilib, acıq tapsiriqda 4 nefer etmeyib, zeif
--  movzu, sinaq, defter, sehv defteri) · sagird ve valideyn kodla girir ·
--  tekrar sifirlama eyni kodlarla, 10 deqiqe icinde atlanir · anonim
--  istifadeci rpc_demo_start ile OZ nusxesini alir, kodlari ferqlidir ·
--  oz hesabi olan istifadeci numune ala bilmir · 24 saatdan kohne nusxe
--  silinir · is_demo my_context-de gelir.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.app_state where key = 'demo_reset';
--  evvelki isden qalan fikstur: qruplar/testler -> hesablar -> istifadeciler (restrict FK-lar)
delete from public.classes c using public.accounts a where a.id = c.account_id and (a.is_demo or a.id = 'aaaa0000-0000-0000-0000-0000000000df');
delete from public.tests where owner_type = 'educator' and owner_id in (app.demo_owner(), '11110000-0000-0000-0000-0000000000de', '11110000-0000-0000-0000-0000000000df');
delete from public.students s using public.accounts a where a.id = s.account_id and (a.is_demo or a.id = 'aaaa0000-0000-0000-0000-0000000000df');
delete from public.accounts where is_demo or id = 'aaaa0000-0000-0000-0000-0000000000df';
delete from auth.users where id in (app.demo_owner(), '11110000-0000-0000-0000-0000000000de', '11110000-0000-0000-0000-0000000000df');

-- =====================================================================
--  1. Paylasilan numune qurulur
-- =====================================================================
do $$
declare v jsonb; c1 uuid; n int; p uuid; d jsonb;
begin
  v := public.rpc_demo_reset();
  assert (v->>'ok')::boolean and v->>'student_code' = 'DEMO0001' and v->>'parent_code' = 'VDEMO001', 'kodlar: ' || v::text;
  assert (select count(*) from public.classes where account_id = app.demo_account()) = 2, '2 qrup';
  assert (select count(*) from public.students where account_id = app.demo_account()) = 20, '20 sagird';
  assert (select is_demo from public.accounts where id = app.demo_account()), 'is_demo';
  assert app.has_active_subscription(app.demo_account()), 'abune';
  select id into c1 from public.classes where account_id = app.demo_account() and name like '3-cü%';
  select count(*) into n from public.class_plan_items i join public.class_plans pl on pl.id = i.plan_id
   where pl.class_id = c1 and i.done_at is not null;
  assert n = 9, '9 movzu kecilib: ' || n;
  assert (select count(*) from public.assignments a where a.class_id = c1 and app.assignment_open(a.*)) = 1, 'bir acıq tapsiriq';
  assert (select count(*) from public.plan_exams e join public.class_plans pl on pl.id = e.plan_id where pl.class_id = c1) = 1, 'bir sinaq';
  assert (select count(*) from public.tests t where t.owner_id = app.demo_owner() and t.is_diagnostic) = 1, 'diaqnostika';
  assert (select count(*) from public.attempts a join public.students s on s.id = a.student_id where s.account_id = app.demo_account()) > 100, 'cehdler';
  assert (select count(*) from public.mistakes m join public.students s on s.id = m.student_id where s.account_id = app.demo_account()) > 50, 'sehv defteri';
  assert (select count(*) from public.lessons where class_id = c1) >= 5, 'dersler';
  assert (select count(*) from public.fee_payments f join public.students s on s.id = f.student_id where s.class_id = c1 and f.paid) = 20, 'odenisler 8 + 12';
  assert (select count(*) from public.practice pr join public.students s on s.id = pr.student_id where s.account_id = app.demo_account()) = 6, 'movzu mesqi';
  assert (select count(*) from public.feedback where account_id = app.demo_account()) = 1, 'bize yaz';
  perform set_config('smoke.c1', c1::text, false);
end $$;
\echo 'OK  1 · paylasilan numune: 2 qrup, 20 sagird, tarixce, defter, sinaq'

-- =====================================================================
--  2. Sahib RPC-leri: bu gunun dersi (4 etmeyib), zeif movzu, my_context
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = 'd0000000-0000-4000-8000-000000000001';
do $$
declare d jsonb; r jsonb; c jsonb; w numeric;
begin
  d := public.rpc_lesson_prep(current_setting('smoke.c1')::uuid);
  assert (d->>'open')::int = 1 and jsonb_array_length(d->'pending') = 4, 'etmeyenler 4: ' || (d->'pending')::text;
  assert d->'next'->>'topic' is not null and d->'last'->>'avg' is not null, 'novbeti/son';
  r := public.rpc_class_report(current_setting('smoke.c1')::uuid);
  select min((t->>'ratio')::numeric) into w from jsonb_array_elements(r->'topics') t;
  assert w < 60, 'zeif movzu var: ' || w;
  c := public.rpc_my_context();
  assert (c->'accounts'->0->>'is_demo')::boolean and c->'accounts'->0->'demo_codes'->>'student' = 'DEMO0001'
     and c->'accounts'->0->'demo_codes'->>'parent' = 'VDEMO001', 'my_context is_demo/kodlar';
end $$;
reset role;
\echo 'OK  2 · sahib: etmeyenler 4, zeif movzu, my_context numune kodlari'

-- =====================================================================
--  3. Sagird ve valideyn kodla girir; tekrar sifirlama atlanir / eyni kodlar
-- =====================================================================
do $$
declare tok text; v jsonb; ptok text; h jsonb;
begin
  set local role anon;
  v := public.rpc_student_login('DEMO0001');
  assert (v->>'ok')::boolean, 'sagird girisi';
  tok := v->>'token';
  v := public.rpc_student_tests(tok);
  assert jsonb_array_length(v->'assigned') = 1 and jsonb_array_length(v->'weak') >= 1, 'sagird tapsiriq ve zeif movzu';
  ptok := public.rpc_parent_login('VDEMO001')->>'token';
  reset role;
  set local role anon;
  h := public.rpc_parent_home(ptok);
  reset role;
  assert (h->'attendance'->>'lessons')::int >= 1 and (h->'practice'->>'mastered')::int = 1, 'valideyn ekrani: ' || left(h::text, 200);
  v := public.rpc_demo_reset();
  assert (v->>'skipped')::boolean, '10 deqiqe icinde atlanmali';
  update public.app_state set val = jsonb_build_object('at', now() - interval '1 hour') where key = 'demo_reset';
  v := public.rpc_demo_reset();
  assert not coalesce((v->>'skipped')::boolean, false) and v->>'student_code' = 'DEMO0001', 'yeniden qurulur, eyni kod';
  assert (select count(*) from public.students where account_id = app.demo_account()) = 20, 'yeniden 20 sagird';
end $$;
\echo 'OK  3 · sagird/valideyn kodla girir; sifirlama atlanir ve eyni kodlarla qurulur'

-- =====================================================================
--  4. Anonim ziyaretci oz nusxesini alir; oz hesabi olan ala bilmir;
--     kohne nusxe silinir
-- =====================================================================
insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-0000000000de','anon-de@t.az','{}'),
  ('11110000-0000-0000-0000-0000000000df','real-df@t.az','{"full_name":"Real Muellim"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000df','tutor','Real hesab','11110000-0000-0000-0000-0000000000df');
insert into public.account_members values ('aaaa0000-0000-0000-0000-0000000000df','11110000-0000-0000-0000-0000000000df',true);
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000de';
do $$
declare v jsonb; c jsonb;
begin
  v := public.rpc_demo_start();
  assert (v->>'ok')::boolean and v->>'student_code' <> 'DEMO0001' and length(v->>'student_code') = 8, 'oz nusxe, ferqli kod: ' || v::text;
  c := public.rpc_my_context();
  assert (c->'accounts'->0->>'is_demo')::boolean and c->'accounts'->0->'demo_codes'->>'student' = v->>'student_code', 'nusxe my_context';
  perform set_config('smoke.acc', v->>'account_id', false);
end $$;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000df';
do $$
declare bad boolean := false;
begin
  begin perform public.rpc_demo_start(); exception when others then bad := true; end;
  assert bad, 'oz hesabi olan numune aldi';
end $$;
reset role;
do $$
declare v jsonb;
begin
  assert (select count(*) from public.students where account_id = current_setting('smoke.acc')::uuid) = 20, 'nusxede 20 sagird';
  assert (select count(*) from public.students where account_id = app.demo_account()) = 20, 'paylasilan toxunulmayib';
  --  kohne nusxe: 2 gun evvel yaradilmis kimi -> sifirlama silir
  update public.accounts set created_at = now() - interval '2 days' where id = current_setting('smoke.acc')::uuid;
  update public.app_state set val = jsonb_build_object('at', now() - interval '1 hour') where key = 'demo_reset';
  v := public.rpc_demo_reset();
  assert (v->>'deleted_copies')::int = 1, 'kohne nusxe silinmedi: ' || v::text;
  assert not exists (select 1 from public.accounts where id = current_setting('smoke.acc')::uuid), 'hesab silinib';
  assert not exists (select 1 from auth.users where id = '11110000-0000-0000-0000-0000000000de'), 'anonim istifadeci silinib';
  assert exists (select 1 from public.accounts where id = 'aaaa0000-0000-0000-0000-0000000000df'), 'real hesab qalib';
end $$;
\echo 'OK  4 · anonim nusxe ferqli kodla; oz hesabi olan ala bilmir; kohne nusxe silinir'

\echo 'NUMUNE: BUTUN YOXLAMALAR KECDI'
