-- =====================================================================
--  verify.sql - qurulusun duzgunluyunu yoxlayir.
--  Supabase SQL Editor-a yapisdirib isletmek olar: hec ne deyismir,
--  yalniz oxuyur.
-- =====================================================================
with
tabs as (
  select count(*)::int n from information_schema.tables
   where table_schema='public' and table_type='BASE TABLE'),
norls as (
  select coalesce(string_agg(relname, ', '), '-') s
    from pg_class c join pg_namespace n on n.oid=c.relnamespace
   where n.nspname='public' and c.relkind='r' and not c.relrowsecurity),
pol as (select count(*)::int n from pg_policies where schemaname='public'),
-- Funksiyanin MOVCUD olmasi kifayet deyil: PostgREST EXECUTE huququ
-- olmayan funksiyani "yoxdur" kimi gosterir (404 / 42883). Ona gore
-- hem movcudluq, hem de cagirila bilme yoxlanilir.
expected(fn, who) as (values
  ('public.rpc_student_login(text)',                     'anon'),
  ('public.rpc_student_tests(text)',                     'anon'),
  ('public.rpc_start_attempt(text, uuid)',               'anon'),
  ('public.rpc_submit_attempt(text, uuid, jsonb)',       'anon'),
  ('public.rpc_leaderboard(text, uuid, int)',            'anon'),
  ('public.rpc_my_context()',                            'authenticated'),
  ('public.rpc_create_account(text, text)',              'authenticated'),
  ('public.rpc_create_class(uuid, text, text, text, text)', 'authenticated'),
  ('public.rpc_add_student(uuid, text, text, int)',      'authenticated'),
  ('public.rpc_reset_student_code(uuid)',                'authenticated'),
  ('public.rpc_bank_save_question(uuid, text, text, jsonb, text, text, uuid, text, int, int, int, text[], uuid)',
                                                         'authenticated'),
  ('public.rpc_bank_list(jsonb, int, int, uuid)',        'authenticated'),
  ('public.rpc_bank_question(uuid)',                     'authenticated'),
  ('public.rpc_bank_delete_question(uuid)',              'authenticated'),
  ('public.rpc_bank_facets(text, text, uuid)',           'authenticated'),
  ('public.rpc_assign_test(uuid, uuid, timestamptz, int)','authenticated'),
  ('public.rpc_available_tests(uuid)',                   'authenticated'),
  ('public.rpc_class_assignments(uuid)',                 'authenticated')),
missing as (
  select coalesce(string_agg(split_part(fn, '(', 1), ', '), '-') s
    from expected
   where to_regprocedure(fn) is null),
noexec as (
  select coalesce(string_agg(split_part(fn, '(', 1) || ' (' || who || ')', ', '), '-') s
    from expected
   where to_regprocedure(fn) is not null
     and not has_function_privilege(who, fn, 'EXECUTE')),
trg as (
  select count(*)::int n from pg_trigger
   where tgname in ('trg_auth_user_created','trg_students_seat_limit')
     and not tgisinternal),
bank as (
  select (select count(*) from public.questions)::int q,
         (select count(*) from public.test_questions)::int tq,
         (select count(*) from public.attempt_answers where question_body = '')::int nosnap,
         (select count(*) from information_schema.columns
           where table_schema='public' and table_name='questions'
             and column_name='test_id')::int oldcol),
seed as (
  select (select count(*) from public.programs)::int p,
         (select count(*) from public.subjects)::int s,
         (select count(*) from public.levels)::int l,
         (select count(*) from public.plans)::int pl),
leak as (
  select coalesce(string_agg(distinct table_name, ', '), '-') s
    from information_schema.role_table_grants
   where grantee='anon' and table_schema='public'
     and table_name in ('students','question_options','questions',
                        'attempts','attempt_answers','student_sessions','consents'))
select * from (
  select 1 ord, 'Cedvel sayi'          k, tabs.n::text v,
         case when tabs.n=24 then 'OK' else 'GOZLENILEN 24' end d from tabs
  union all select 2, 'RLS acilmayan',   norls.s,
         case when norls.s='-' then 'OK' else 'PROBLEM' end from norls
  union all select 3, 'RLS siyaseti',    pol.n::text,
         case when pol.n>=38 then 'OK' else 'AZDIR - 02 islenmeyib?' end from pol
  union all select 4, 'Catismayan RPC',  missing.s,
         case when missing.s='-' then 'OK' else 'PROBLEM - 03/06 islenmeyib?' end from missing
  union all select 5, 'Cagirila bilmeyen RPC', noexec.s,
         case when noexec.s='-' then 'OK'
              else 'PROBLEM - huquq yoxdur, 03/06 yeniden islet' end from noexec
  union all select 6, 'Trigerler',       trg.n::text,
         case when trg.n=2 then 'OK' else 'PROBLEM - 06 islenmeyib?' end from trg
  union all select 7, 'Seed: proqram/fenn/seviyye/paket',
         seed.p||' / '||seed.s||' / '||seed.l||' / '||seed.pl,
         case when seed.p>=5 and seed.s>=10 and seed.l>=15 and seed.pl>=7
              then 'OK' else 'PROBLEM - 04 islenmeyib?' end from seed
  union all select 8, 'anon-a acilan hessas cedvel', leak.s,
         case when leak.s='-' then 'OK' else 'TEHLUKE - 05 EN SONDA islenmelidir' end from leak
  union all select 9, 'Sual banki (sual / terkib)',
         bank.q::text || ' / ' || bank.tq::text,
         case when bank.oldcol > 0 then 'PROBLEM - 11 islenmeyib'
              when bank.nosnap > 0 then 'PROBLEM - ' || bank.nosnap || ' cavabda suret yoxdur'
              else 'OK' end from bank
) z order by ord;
