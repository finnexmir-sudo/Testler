-- =====================================================================
--  05_grants.sql : huquqlar - HER MIQRASIYADAN SONRA ISLEDILIR
--
--  Yanasma: evvelce her seyi bagla, sonra yalniz lazim olani ver.
--  Bele olanda fayllarin isledilme sirasi ehemiyyet kesb etmir -
--  netice hemise eynidir. Siyahi ile "geri al" yanasmasi kovrek idi:
--  Supabase yeni cedvele avtomatik huquq verir ve siyahida olmayan
--  cedvel sessizce aciq qalirdi.
--
--  RLS ile birlikde iki qat mudafie: siyaset sizsa bele huquq yoxdur.
-- =====================================================================

-- ------------------------------------------------------- 1. hamisini bagla
revoke all on all tables    in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;

-- Geleceke: Supabase yeni cedvele default huquq vermesin.
alter default privileges in schema public revoke all on tables    from anon, authenticated;
alter default privileges in schema public revoke all on sequences from anon, authenticated;
do $$ begin
  execute 'alter default privileges for role postgres in schema public
             revoke all on tables from anon, authenticated';
  execute 'alter default privileges for role postgres in schema public
             revoke all on sequences from anon, authenticated';
exception when others then null;   -- lokal yoxlamada postgres rolu ferqli ola biler
end $$;

-- --------------------------------------------------- 2. kataloq - hamiya
-- Proqram/fenn/seviyye siyahisi giris etmeden de gorunmelidir.
grant select on public.programs, public.subjects, public.program_subjects,
                public.levels, public.topics, public.plans
  to anon, authenticated;

-- ------------------------------------------ 3. muellim/valideyn - oxumaq
-- RLS setirleri suzur; bu grant yalniz "cedvele baxa biler" deməkdir.
grant select on public.profiles, public.user_roles, public.accounts,
                public.account_members, public.schools, public.classes,
                public.students, public.consents, public.tests,
                public.questions, public.question_options,
                public.test_questions,
                public.attempts, public.attempt_answers,
                public.assignments,
                public.subscriptions, public.payments
  to authenticated;

-- ------------------------------------------- 4. muellim - yazmaq huququ
grant insert, update, delete on public.assignments to authenticated;

grant insert, update, delete on public.classes, public.schools,
                                public.tests, public.questions,
                                public.question_options,
                                public.test_questions
  to authenticated;

grant update, delete on public.students to authenticated;
grant insert          on public.consents to authenticated;
grant update          on public.profiles to authenticated;
grant update          on public.accounts to authenticated;

-- students-e INSERT bilerekden verilmir: sagird yalniz rpc_add_student()
-- ile elave olunur ki, giris kodu hemise serverde yaransin.

-- ------------------------------------------------------- 5. baglі qalanlar
--  student_sessions  - yalniz SECURITY DEFINER funksiyalar
--  accounts INSERT   - yalniz rpc_create_account()
--  subscriptions/payments yazmaq - yalniz service_role (shluz webhook-u)
--  anon ucun HEC BIR cedvel - sagird terefi tamamile RPC ile isleyir

-- ============================================================ funksiyalar
--  Sagird tetbiqi 8, valideyn tetbiqi 3 funksiya cagirir - basqa hec ne.  Supabase yeni
--  funksiyalara anon ucun EXECUTE-u avtomatik verdiyi ucun burda hamisi
--  geri alinir, sonra 03_rpc.sql-in verdiyi alti dene yerinde qalir.
--  Beleliklə sonradan yazilan her yeni muellim funksiyasi OZ-OZUNE
--  bagli olur - unudulsa da sizmir.
do $$
declare fn text;
begin
  for fn in
    select p.oid::regprocedure::text
      from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public'
       and has_function_privilege('anon', p.oid, 'EXECUTE')
       and p.proname not in ('rpc_student_login','rpc_student_tests',
                             'rpc_start_attempt','rpc_submit_attempt',
                             'rpc_leaderboard','rpc_test_result',
                             'rpc_report_question_student',
                             'rpc_student_my_results',
                             --  valideyn tetbiqi (db/107_valideyn.sql):
                             --  eynen sagird kimi anon-la isleyir, giris
                             --  kodladir.  rpc_parent_home DUZ CAVAB ve
                             --  usagin giris kodunu QAYTARMIR.
                             'rpc_parent_login','rpc_parent_home',
                             'rpc_parent_logout')
  loop
    execute format('revoke all on function %s from anon', fn);
  end loop;
end $$;

-- ------------------------------------------------------------ 6. hesabat
do $$
declare leak text;
begin
  select string_agg(distinct table_name, ', ') into leak
    from information_schema.role_table_grants
   where grantee = 'anon' and table_schema = 'public'
     and table_name not in ('programs','subjects','program_subjects',
                            'levels','topics','plans');
  if leak is not null then
    raise exception 'anon-a hele de aciq cedveller var: %', leak;
  end if;
  select string_agg(p.oid::regprocedure::text, ', ') into leak
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public'
     and has_function_privilege('anon', p.oid, 'EXECUTE')
     and p.proname not in ('rpc_student_login','rpc_student_tests',
                           'rpc_start_attempt','rpc_submit_attempt',
                           'rpc_leaderboard','rpc_test_result',
                             'rpc_report_question_student',
                             'rpc_student_my_results',
                             'rpc_parent_login','rpc_parent_home',
                             'rpc_parent_logout');
  if leak is not null then
    raise exception 'anon bu funksiyalari cagira bilir: %', leak;
  end if;

  raise notice 'Huquqlar quruldu: anon kataloqu, 8 sagird ve 3 valideyn RPC-sini gorur.';
end $$;
