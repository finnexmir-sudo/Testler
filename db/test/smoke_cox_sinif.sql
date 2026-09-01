-- =====================================================================
--  smoke_cox_sinif.sql : test yiganda bir nece sinif secmek
--                        (db/103_cox_sinif.sql)
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
  ('11110000-0000-0000-0000-0000000000fb','c@t.az','{"full_name":"Cox sinif M"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000fb','tutor','C hesabi',
   '11110000-0000-0000-0000-0000000000fb');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000fb','11110000-0000-0000-0000-0000000000fb',true);
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-0000000000fb', p.id, 'active', now() + interval '30 days'
  from public.plans p where p.slug = 'repetitor-25';

\echo '--- hazirliq tamam'

set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000fb';

-- =====================================================================
--  1. Iki sinif secilende testde HER IKISINDEN sual olur
--     (onizleme sayi 'want' ile mehdudlasir - hovuz olcusunu
--      olcmek ucun testin OZ mezmununa baxiriq, bu daha guclüdür)
-- =====================================================================
do $$
declare r jsonb; tid uuid; n3 int; n4 int; kenar int;
begin
  r := public.rpc_generate_test(jsonb_build_object(
         'pool','all','count',20,'subject','riyaziyyat',
         'levels', jsonb_build_array('3','4')), 'Uc-Dord testi');
  tid := (r->>'test_id')::uuid;
  select count(*) filter (where l.code = '3'),
         count(*) filter (where l.code = '4'),
         count(*) filter (where coalesce(l.code,'') not in ('3','4'))
    into n3, n4, kenar
    from public.test_questions tq
    join public.questions q on q.id = tq.question_id
    left join public.levels l on l.id = q.level_id
   where tq.test_id = tid;
  assert kenar = 0, 'testde KENAR sinifden ' || kenar || ' sual var';
  assert n3 > 0, '3-cu sinifden sual gelmedi';
  assert n4 > 0, '4-cu sinifden sual gelmedi';
end $$;
\echo 'OK  1 · iki sinif secilende ikisinden de sual gelir, kenar yoxdur'

-- =====================================================================
--  2. TEK sinif secilende yalniz o sinif gelir
-- =====================================================================
do $$
declare r jsonb; tid uuid; kenar int;
begin
  r := public.rpc_generate_test(jsonb_build_object(
         'pool','all','count',20,'subject','riyaziyyat',
         'levels', jsonb_build_array('3')), 'Tek uc testi');
  tid := (r->>'test_id')::uuid;
  select count(*) into kenar
    from public.test_questions tq
    join public.questions q on q.id = tq.question_id
    left join public.levels l on l.id = q.level_id
   where tq.test_id = tid and coalesce(l.code,'') <> '3';
  assert kenar = 0, 'tek sinif secilib, kenardan ' || kenar || ' sual gelib';
end $$;
\echo 'OK  2 · tek sinif secilende yalniz o sinif gelir'

-- =====================================================================
--  3. KOHNE qayda ('level' tek deyer) hele de isleyir
--     Movcud testlerin gen_rule-u belədir - "yenile" onu isledir
-- =====================================================================
do $$
declare r jsonb; tid uuid; kenar int;
begin
  r := public.rpc_generate_test(jsonb_build_object(
         'pool','all','count',20,'subject','riyaziyyat',
         'level','3'), 'Kohne qayda testi');
  tid := (r->>'test_id')::uuid;
  select count(*) into kenar
    from public.test_questions tq
    join public.questions q on q.id = tq.question_id
    left join public.levels l on l.id = q.level_id
   where tq.test_id = tid and coalesce(l.code,'') <> '3';
  assert kenar = 0, 'KOHNE qayda pozulub: kenardan ' || kenar || ' sual';
end $$;
\echo 'OK  3 · kohne "level" qaydasi pozulmayib'

-- =====================================================================
--  4. Testin OZ sinfi secilenlerin EN YUXARISIDIR
--     (8+7 testi 8-ci sinif testidir - rpc_available_tests onu
--      8-ci sinif qrupuna gostermelidir, 7-ci sinfe yox)
-- =====================================================================
do $$
declare kod text;
begin
  select l.code into kod from public.tests t
    join public.levels l on l.id = t.level_id
   where t.title = 'Uc-Dord testi';
  assert kod = '4', 'testin sinfi en yuxari deyil: ' || coalesce(kod,'null');
end $$;
\echo 'OK  4 · testin sinfi secilenlerin en yuxarisidir'

-- =====================================================================
--  5. Sinif verilmeyibse suzgec ISLEMIR - bir nece sinifden gelir
-- =====================================================================
do $$
declare r jsonb; tid uuid; nsinif int;
begin
  r := public.rpc_generate_test(jsonb_build_object(
         'pool','all','count',20,'subject','riyaziyyat'), 'Sinifsiz test');
  tid := (r->>'test_id')::uuid;
  select count(distinct l.code) into nsinif
    from public.test_questions tq
    join public.questions q on q.id = tq.question_id
    left join public.levels l on l.id = q.level_id
   where tq.test_id = tid;
  assert nsinif > 2, 'sinifsiz sorgu suzulub, yalniz ' || nsinif || ' sinif geldi';
end $$;
\echo 'OK  5 · sinif verilmeyende suzgec islemir'

-- =====================================================================
--  6. BOS massiv de suzgec kimi islemir
-- =====================================================================
do $$
declare r jsonb; tid uuid; nsinif int;
begin
  r := public.rpc_generate_test(jsonb_build_object(
         'pool','all','count',20,'subject','riyaziyyat',
         'levels', '[]'::jsonb), 'Bos massiv testi');
  tid := (r->>'test_id')::uuid;
  select count(distinct l.code) into nsinif
    from public.test_questions tq
    join public.questions q on q.id = tq.question_id
    left join public.levels l on l.id = q.level_id
   where tq.test_id = tid;
  assert nsinif > 2, 'bos massiv suzgec kimi isledi: ' || nsinif || ' sinif';
end $$;
\echo 'OK  6 · bos massiv suzgec kimi islemir'

-- =====================================================================
--  7. Anon test yiga bilmir
-- =====================================================================
reset role; reset request.jwt.claim.sub;
do $$
begin
  if has_function_privilege('anon',
      'public.rpc_generate_test(jsonb, text, uuid, uuid)', 'EXECUTE') then
    raise exception 'anon test yiga bilir';
  end if;
end $$;
\echo 'OK  7 · anon test yigmaqdan kenardadir'

\echo 'COX SINIF: BUTUN YOXLAMALAR KECDI'
