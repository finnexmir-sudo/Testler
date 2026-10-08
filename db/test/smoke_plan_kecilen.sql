-- =====================================================================
--  smoke_plan_kecilen.sql : 928 - «Kecilen dersler den test» FESIL hovuzu yox, dersin nisani ile
--
--  Fixture: fesil + 4 ders (hamisinin suallari ders nisanli):
--    kt-d1 25 sual (hazir, KECILIB)   kt-d2 25 sual (hazir, KECILIB)
--    kt-d3  5 sual (HAZIR DEYIL, KECILIB)   kt-d4 25 sual (hazir, KECILMEYIB)
--  Yoxlanir:
--    1) rpc_plan_test_done(plan, 20): 2 ders, 1 kecilmis-hazir-olmayan 'skipped', 20 sual;
--       10 d1 + 10 d2; d3 ve d4-un SUALI YOXDUR (kecilmemis dersin sualı dusmur);
--       qrupa tapsirilib
--    2) anon cagira bilmir; sual sayi 5-50 hedi
--    3) hazir kecilmis ders yoxdursa - xeta
--    4) abunesiz hesab - xeta
--
--  ISTIFADE:  psql -f db/test/smoke_plan_kecilen.sql   (oz bazasinda; yoxla.sh)
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
delete from public.questions where topic_id in (select id from public.topics where slug = 'kt-fesil');   -- tekrar isletmek ucun
delete from public.topics where slug like 'kt-d%' or slug = 'kt-fesil';
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-0000000009a8','kt@t.az','{"full_name":"Sablon Muellim"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000009a8','tutor','KT hesabi','11110000-0000-0000-0000-0000000009a8');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000009a8','11110000-0000-0000-0000-0000000009a8',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code, level_id)
select 'cccc0000-0000-0000-0000-0000000009a8','aaaa0000-0000-0000-0000-0000000009a8',
       '11110000-0000-0000-0000-0000000009a8','tutor_group','KT qrupu','KODKT928', l.id
  from public.levels l where l.code = '3' and l.code ~ '^[0-9]+$';
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-0000000009a8', p.id, 'active', now() + interval '30 days'
  from public.plans p where p.slug = 'repetitor-25';

-- ------------------------------------------------- fixture: fesil + 4 ders + suallar
do $$
declare
  v_subj uuid; v_lev uuid; v_f uuid; v_d uuid; v_q uuid; i int; k int;
  v_cfg jsonb := '[["kt-d1",0,25],["kt-d2",0,25],["kt-d3",0,5],["kt-d4",0,25]]';
  x jsonb; v_slug text; v_p int; v_a int;
  v_say int := 0;
begin
  select id into v_subj from public.subjects where slug = 'riyaziyyat';
  select id into v_lev  from public.levels   where code = '3';
  insert into public.topics (subject_id, level_id, parent_id, name, slug, sort)
       values (v_subj, v_lev, null, 'KT fəsil 926', 'kt-fesil', 996) returning id into v_f;
  for x in select * from jsonb_array_elements(v_cfg) loop
    v_slug := x->>0; v_p := (x->>1)::int; v_a := (x->>2)::int;
    insert into public.topics (subject_id, level_id, parent_id, name, slug, sort)
         values (v_subj, v_lev, v_f, 'KT ' || v_slug, v_slug, 996 + (v_say % 5) + 1) returning id into v_d;
    v_say := v_say + 1;
    --  sablon suallar: her biri ferqli sozle + ferqli duz cavab ifadesi (generatorun oxsarliq/cavab suzgeci kecsin)
    for i in 1 .. v_p loop
      insert into public.questions (owner_type, subject_id, level_id, topic_id, kind, body, status, tags, params)
           values ('platform', v_subj, v_lev, v_f, 'single',
                   (array['Hesablayın: {a} + {b} ifadəsi neçədir',
                          '{a} ədədinə {b} əlavə edin',
                          'Cəmi tapın: {a} və {b}',
                          '{a} ilə {b}-nin cəmi hansıdır',
                          'Sayları toplayın: {a}, {b}'])[1 + (i % 5)] || ' (şablon ' || v_slug || ' ' || i || ')',
                   'published', array[app.ders_tag(v_slug)],
                   '{"vars":{"a":[100,999],"b":[100,999]}}'::jsonb)
        returning id into v_q;
      insert into public.question_options (question_id, ord, body, is_correct)
           values (v_q, 1, '{a+b+' || (i * 3) || '}', true),
                  (v_q, 2, '{a+b+' || (i * 3 + 1) || '}', false),
                  (v_q, 3, '{a+b+' || (i * 3 + 2) || '}', false);
    end loop;
    for i in 1 .. v_a loop
      insert into public.questions (owner_type, subject_id, level_id, topic_id, kind, body, status, tags)
           values ('platform', v_subj, v_lev, v_f, 'single',
                   (array['%s ədədinin kvadratı neçədir?','Tənliyi həll edin: x - %s = 0','%s ədədini 3-ə vurun',
                          '%s ilə 7-nin fərqi nədir?','%s ədədinin yarısı nədir?'])[1 + (i % 5)] || ' (adi ' || v_slug || ' ' || i || ')',
                   'published', array[app.ders_tag(v_slug)])
        returning id into v_q;
      insert into public.question_options (question_id, ord, body, is_correct)
           values (v_q, 1, (i * 17 + v_say * 101)::text, true),
                  (v_q, 2, (i * 17 + v_say * 101 + 1)::text, false),
                  (v_q, 3, (i * 17 + v_say * 101 + 2)::text, false);
    end loop;
  end loop;
end $$;


-- ------------------------------------------------- plan qur, d1-d3 «kecildi» (d4 yox)
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000009a8';
select (public.rpc_plan_create('cccc0000-0000-0000-0000-0000000009a8','riyaziyyat','3')->>'ok') as plan_qurdu;
reset role; reset request.jwt.claim.sub;
update public.class_plan_items i set done_at = now()
  from public.topics t where t.id = i.topic_id and t.slug in ('kt-d1','kt-d2','kt-d3');

-- ------------------------------------------------- 1) normal yigim
select set_config('kt.plan', (select id::text from public.class_plans where class_id = 'cccc0000-0000-0000-0000-0000000009a8'), false);
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000009a8';
select set_config('kt.res', public.rpc_plan_test_done(
         current_setting('kt.plan')::uuid, 20)::text, false);
reset role; reset request.jwt.claim.sub;
do $$
declare
  v jsonb := current_setting('kt.res')::jsonb;
  v_t uuid := (v->>'test_id')::uuid;
  n1 int; n2 int; n3 int; n4 int; n_all int;
begin
  assert (v->>'lessons')::int = 2, 'lessons=2: ' || v::text;
  assert (v->>'skipped')::int = 1, 'skipped=1 (d3 hazir deyil): ' || v::text;
  assert (v->>'count')::int = 20, 'count=20: ' || v::text;
  select count(*), count(*) filter (where q.tags @> array['ders:kt-d1']),
         count(*) filter (where q.tags @> array['ders:kt-d2']),
         count(*) filter (where q.tags @> array['ders:kt-d3']),
         count(*) filter (where q.tags @> array['ders:kt-d4'])
    into n_all, n1, n2, n3, n4
    from public.test_questions tq join public.questions q on q.id = tq.question_id
   where tq.test_id = v_t;
  assert n_all = 20, 'testde 20 sual: ' || n_all;
  assert n1 = 10 and n2 = 10, 'her dersden 10: ' || n1 || '/' || n2;
  assert n3 = 0 and n4 = 0, 'kecilmemis / hazir olmayan dersin sualı YOXDUR: d3=' || n3 || ' d4=' || n4;
  assert exists (select 1 from public.assignments a
                  where a.test_id = v_t and a.class_id = 'cccc0000-0000-0000-0000-0000000009a8'), 'qrupa tapsirilib';
  assert (select count(distinct question_id) from public.test_questions where test_id = v_t) = 20, 'suallar ferqlidir';
end $$;
\echo 'OK  1 · 2 kecilmis hazir dersden 10+10 sual; d3 (hazir deyil) skipped; d4 (kecilmemis) sualı YOXDUR; qrupa tapsirilib'

-- ------------------------------------------------- 2) huquq ve hedd
do $$
begin
  assert not has_function_privilege('anon', 'public.rpc_plan_test_done(uuid,int,uuid[])', 'execute'), 'anon cagira bilmez';
  assert has_function_privilege('authenticated', 'public.rpc_plan_test_done(uuid,int,uuid[])', 'execute'), 'authenticated cagira biler';
end $$;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000009a8';
do $$
declare v_p uuid := current_setting('kt.plan')::uuid;
        v_ok boolean := false;
begin
  begin perform public.rpc_plan_test_done(v_p, 4);  exception when others then v_ok := true; end;
  assert v_ok, '4 sual - xeta';
  v_ok := false;
  begin perform public.rpc_plan_test_done(v_p, 51); exception when others then v_ok := true; end;
  assert v_ok, '51 sual - xeta';
end $$;
reset role; reset request.jwt.claim.sub;
\echo 'OK  2 · anon cagira bilmir; 5-50 hedi'

-- ------------------------------------------------- 3) hazir kecilmis ders yoxdur
update public.class_plan_items i set done_at = null
  from public.topics t where t.id = i.topic_id and t.slug in ('kt-d1','kt-d2');
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000009a8';
do $$
declare v_p uuid := current_setting('kt.plan')::uuid;
        v_ok boolean := false; v_msg text;
begin
  begin perform public.rpc_plan_test_done(v_p, 20);
  exception when others then v_ok := true; v_msg := sqlerrm; end;
  assert v_ok, 'yalniz hazir olmayan kecilmis ders - xeta';
  assert v_msg like '%hazir sual yoxdur%', 'xeta metni: ' || v_msg;
end $$;
reset role; reset request.jwt.claim.sub;
\echo 'OK  3 · hazir kecilmis ders yoxdursa xeta (sessizce fesile dusmur)'

-- ------------------------------------------------- 3b) secilmis dersler: YALNIZ d1
select set_config('kt.d1', (select i.id::text from public.class_plan_items i join public.topics t on t.id = i.topic_id where t.slug = 'kt-d1'), false);
update public.class_plan_items i set done_at = now()
  from public.topics t where t.id = i.topic_id and t.slug in ('kt-d1','kt-d2');
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000009a8';
select set_config('kt.res2', public.rpc_plan_test_done(current_setting('kt.plan')::uuid, 10,
         array[current_setting('kt.d1')::uuid])::text, false);
reset role; reset request.jwt.claim.sub;
do $$
declare v jsonb := current_setting('kt.res2')::jsonb; v_t uuid := (v->>'test_id')::uuid;
begin
  assert (v->>'lessons')::int = 1 and (v->>'count')::int = 10, 'secilmis 1 ders, 10 sual: ' || v::text;
  assert (select count(*) from public.test_questions tq join public.questions q on q.id = tq.question_id
           where tq.test_id = v_t and q.tags @> array['ders:kt-d1']) = 10, 'hamisi d1-in sualıdır (d2 secilmeyib)';
end $$;
\echo 'OK  3b · secilmis dersler: yalniz secilen dersin sualı'

-- ------------------------------------------------- 4) abunesiz
update public.class_plan_items i set done_at = now()
  from public.topics t where t.id = i.topic_id and t.slug in ('kt-d1','kt-d2');
delete from public.subscriptions;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000009a8';
do $$
declare v_p uuid := current_setting('kt.plan')::uuid;
        v_ok boolean := false;
begin
  begin perform public.rpc_plan_test_done(v_p, 20); exception when others then v_ok := true; end;
  assert v_ok, 'abunesiz - xeta';
end $$;
reset role; reset request.jwt.claim.sub;
\echo 'OK  4 · abunesiz hesab - xeta'

delete from public.class_plan_items; delete from public.class_plans;
delete from public.assignments;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.questions where topic_id in (select id from public.topics where slug = 'kt-fesil');
delete from public.topics where slug like 'kt-d%' or slug = 'kt-fesil';
delete from public.classes; delete from public.account_members; delete from public.accounts;
delete from public.user_roles; delete from public.profiles; delete from auth.users;
