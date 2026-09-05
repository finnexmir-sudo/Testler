-- =====================================================================
--  smoke_bu_gun.sql : «Bu gunun dersi» - rpc_lesson_prep (db/126)
--
--  Iddialar: plansiz -> has_plan false, pending isleyir · plan qurulur
--  -> next 1-ci ders, last yox · "kecildi" -> last dolur, next 2-ci ·
--  tapsiriq: etmeyenler adbaad, eden cixir, ferdi teyinat yalniz oz
--  sahibinde, bagli teyinat sayilmir · yad muellim gore bilmir.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers;  delete from public.attempts;
delete from public.assignments;      delete from public.student_sessions;
delete from public.students;         delete from public.classes;
delete from public.subscriptions;
delete from public.test_questions tq using public.tests t
 where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-0000000000c1','bg@t.az','{"full_name":"Bugun Muellim"}'),
  ('11110000-0000-0000-0000-0000000000c2','yad@t.az','{"full_name":"Yad Muellim"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000c1','tutor','BG hesabi','11110000-0000-0000-0000-0000000000c1'),
  ('aaaa0000-0000-0000-0000-0000000000c2','tutor','Yad hesab','11110000-0000-0000-0000-0000000000c2');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000c1','11110000-0000-0000-0000-0000000000c1',true),
  ('aaaa0000-0000-0000-0000-0000000000c2','11110000-0000-0000-0000-0000000000c2',true);
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-0000000000c1', p.id, 'active', now() + interval '30 days'
  from public.plans p where p.slug = 'repetitor-25';
insert into public.classes (id, account_id, teacher_id, kind, name, join_code, level_id)
select 'cccc0000-0000-0000-0000-0000000000c1','aaaa0000-0000-0000-0000-0000000000c1',
       '11110000-0000-0000-0000-0000000000c1','tutor_group','BG qrup','KODBG001', l.id
  from public.levels l where l.code = '3';
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code) values
  ('5555000c-0000-0000-0000-0000000000c1','aaaa0000-0000-0000-0000-0000000000c1',
   'cccc0000-0000-0000-0000-0000000000c1','11110000-0000-0000-0000-0000000000c1','Ayan Bir','Ayan B.','BGUN0001'),
  ('5555000c-0000-0000-0000-0000000000c2','aaaa0000-0000-0000-0000-0000000000c1',
   'cccc0000-0000-0000-0000-0000000000c1','11110000-0000-0000-0000-0000000000c1','Murad Iki','Murad I.','BGUN0002');

create or replace function pg_temp.cavablar(p_test uuid) returns jsonb language sql as $$
  select coalesce(jsonb_agg(jsonb_build_object('q', q.id, 'o', jsonb_build_array(
           (select o.id from public.question_options o
             where o.question_id = q.id and o.is_correct order by o.ord limit 1)))), '[]'::jsonb)
    from public.test_questions tq join public.questions q on q.id = tq.question_id
   where tq.test_id = p_test
$$;

\echo '--- hazirliq tamam'

-- =====================================================================
--  1. Plansiz, tapsiriqsiz: sakit kart
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000c1';
do $$
declare v jsonb;
begin
  v := public.rpc_lesson_prep('cccc0000-0000-0000-0000-0000000000c1');
  assert (v->>'has_plan')::boolean = false, 'plan olmamali';
  assert v->'next' = 'null'::jsonb and v->'last' = 'null'::jsonb, 'next/last bos olmali';
  assert (v->>'open')::int = 0 and jsonb_array_length(v->'pending') = 0, 'tapsiriq yox';
  assert (v->>'students')::int = 2, 'sagird sayi';
end $$;
\echo 'OK  1 · plansiz ve tapsiriqsiz: bos kart'

-- =====================================================================
--  2. Plan qurulur: next = 1-ci ders; "kecildi" -> last dolur
-- =====================================================================
do $$
declare v jsonb; it uuid; first text;
begin
  perform public.rpc_plan_create('cccc0000-0000-0000-0000-0000000000c1', 'riyaziyyat', '3');
  v := public.rpc_lesson_prep('cccc0000-0000-0000-0000-0000000000c1');
  assert (v->>'has_plan')::boolean, 'plan gorunmur';
  assert v->>'subject' = 'riyaziyyat' and v->>'level' = '3', 'fenn/sinif';
  assert v->'next'->>'topic' is not null and v->'last' = 'null'::jsonb, 'next var, last yox';
  first := v->'next'->>'topic';
  it := (v->'next'->>'item_id')::uuid;
  perform public.rpc_plan_done(it);
  v := public.rpc_lesson_prep('cccc0000-0000-0000-0000-0000000000c1');
  assert v->'last'->>'topic' = first, 'last = kecilen';
  assert (v->'last'->>'done_at') is not null, 'done_at';
  assert v->'next'->>'topic' <> first, 'next ireli getdi';
  assert (v->'next'->>'topic_id') is not null, 'topic_id (fesil) generator ucun';
end $$;
\echo 'OK  2 · plan: next 1-ci ders, kecildi -> last, next 2-ci'

-- =====================================================================
--  3. Tapsiriq: etmeyenler adbaad; eden cixir; ferdi yalniz sahibinde
-- =====================================================================
do $$
declare v jsonb; t1 uuid; t2 uuid;
begin
  select id into t1 from public.tests where slug = 'riy-3-vurma-1';
  select id into t2 from public.tests where slug = 'riy-3-qarisiq-1';
  perform public.rpc_assign_test('cccc0000-0000-0000-0000-0000000000c1', t1, null, 1, null);
  perform public.rpc_assign_test('cccc0000-0000-0000-0000-0000000000c1', t2, null, 1,
                                 '5555000c-0000-0000-0000-0000000000c2');
  v := public.rpc_lesson_prep('cccc0000-0000-0000-0000-0000000000c1');
  assert (v->>'open')::int = 2, 'acıq teyinat 2';
  assert jsonb_array_length(v->'pending') = 2, 'iki sagird etmeyib';
  --  Murad: qrup + ferdi = 2, birinci gelir; Ayan: 1
  assert v->'pending'->0->>'name' = 'Murad Iki' and (v->'pending'->0->>'n')::int = 2, 'Murad 2 tapsiriq';
  assert v->'pending'->1->>'name' = 'Ayan Bir' and (v->'pending'->1->>'n')::int = 1, 'Ayan 1 tapsiriq';
end $$;
reset role; reset request.jwt.claim.sub;
do $$
declare tok text; t1 uuid; att uuid;
begin
  select id into t1 from public.tests where slug = 'riy-3-vurma-1';
  tok := public.rpc_student_login('BGUN0001')->>'token';
  att := (public.rpc_start_attempt(tok, t1)->>'attempt_id')::uuid;
  perform public.rpc_submit_attempt(tok, att, pg_temp.cavablar(t1));
end $$;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000c1';
do $$
declare v jsonb;
begin
  v := public.rpc_lesson_prep('cccc0000-0000-0000-0000-0000000000c1');
  assert jsonb_array_length(v->'pending') = 1 and v->'pending'->0->>'name' = 'Murad Iki',
         'Ayan edib, yalniz Murad qalmali';
end $$;
\echo 'OK  3 · etmeyenler adbaad, eden cixir, ferdi yalniz sahibinde'

-- =====================================================================
--  4. Bagli (vaxti bitmis) teyinat sayilmir
-- =====================================================================
reset role; reset request.jwt.claim.sub;
update public.assignments set opens_at = now() - interval '2 hours', closes_at = now() - interval '1 minute';
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000c1';
do $$
declare v jsonb;
begin
  v := public.rpc_lesson_prep('cccc0000-0000-0000-0000-0000000000c1');
  assert (v->>'open')::int = 0 and jsonb_array_length(v->'pending') = 0, 'bagli teyinat sayildi';
end $$;
\echo 'OK  4 · bagli teyinat sayilmir'

-- =====================================================================
--  5. Yad muellim gore bilmir
-- =====================================================================
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000c2';
do $$
declare ok boolean := false;
begin
  begin
    perform public.rpc_lesson_prep('cccc0000-0000-0000-0000-0000000000c1');
  exception when insufficient_privilege then ok := true; end;
  assert ok, 'yad muellim gordu';
end $$;
\echo 'OK  5 · yad muellim gore bilmir'
