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
--  Sagird tetbiqi 8, valideyn tetbiqi 3 funksiya cagirir - basqa hec ne.
--
--  IKI ISTIQAMETDE ISLEYIR:
--    a) siyahida OLMAYAN her funksiyadan anon-un huququ geri alinir.
--       Supabase yeni funksiyaya avtomatik EXECUTE verir; bele olanda
--       sonradan yazilan her muellim funksiyasi OZ-OZUNE bagli olur.
--    b) siyahida OLAN her funksiyaya EXECUTE verilir.
--
--  (b) evvel YOX IDI - ve bu, canli bazada real xetaya cevrildi.
--  107_valideyn.sql valideyn funksiyalarini yaradib huquq verir, amma
--  ondan sonra KOHNE (valideyni tanimayan) 05_grants.sql isledilende
--  huquq geri alinirdi:  "permission denied for function
--  rpc_parent_login".  Fayli tekrar isletmek de komek etmirdi, cunki
--  o yalniz geri alirdi, hec ne vermirdi.
--
--  Indi netice fayllarin sirasindan ASILI DEYIL: bu fayl ne vaxt
--  islense, anon-un huququ tam olaraq asagidaki siyahiya beraberlenir.
--  Ag siyahi BIR yerde saxlanilir (v_ok) - evvel uc yere kopyalanmisdi
--  ve biri unudulsa sessizce ferqli davranirdi.
do $$
declare
  v_ok text[] := array[
        --  sagird tetbiqi (db/03_rpc.sql)
        'rpc_student_login','rpc_student_tests',
        'rpc_start_attempt','rpc_submit_attempt',
        'rpc_leaderboard','rpc_test_result',
        'rpc_report_question_student','rpc_student_my_results',
        --  valideyn tetbiqi (db/107_valideyn.sql): eynen sagird kimi
        --  anon-la, giris kodu ile isleyir.  rpc_parent_home DUZ CAVABI
        --  ve usagin giris kodunu QAYTARMIR.
        'rpc_parent_login','rpc_parent_home','rpc_parent_logout'];
  fn text;
begin
  --  a) artiq acilmis olani bagla.  "from public" VACIBDIR: Postgres
  --  yeni funksiyaya susmaya gore PUBLIC-e EXECUTE verir, anon ise
  --  PUBLIC-in icindedir.  Yalniz "from anon" yazilanda huquq
  --  PUBLIC vasitesile yerinde qalirdi - yeni funksiyani "oz-ozune
  --  baglanir" saymaq sehv idi.  authenticated her funksiyada acig
  --  qrantla saxlanir, ona gore ona toxunmur.
  for fn in
    select p.oid::regprocedure::text
      from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public'
       and has_function_privilege('anon', p.oid, 'EXECUTE')
       and not (p.proname = any(v_ok))
  loop
    execute format('revoke all on function %s from public, anon', fn);
  end loop;

  --  b) catismayani ver
  for fn in
    select p.oid::regprocedure::text
      from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public'
       and p.prokind = 'f'
       and p.proname = any(v_ok)
       and not has_function_privilege('anon', p.oid, 'EXECUTE')
  loop
    execute format('grant execute on function %s to anon, authenticated', fn);
    raise notice 'huquq berpa olundu: %', fn;
  end loop;
end $$;

-- ------------------------------------------------------------ 6. hesabat
do $$
declare
  v_ok text[] := array[
        'rpc_student_login','rpc_student_tests',
        'rpc_start_attempt','rpc_submit_attempt',
        'rpc_leaderboard','rpc_test_result',
        'rpc_report_question_student','rpc_student_my_results',
        'rpc_parent_login','rpc_parent_home','rpc_parent_logout'];
  leak text;
  v_say int;
begin
  select string_agg(distinct table_name, ', ') into leak
    from information_schema.role_table_grants
   where grantee = 'anon' and table_schema = 'public'
     and table_name not in ('programs','subjects','program_subjects',
                            'levels','topics','plans');
  if leak is not null then
    raise exception 'anon-a hele de aciq cedveller var: %', leak;
  end if;

  --  cox olan
  select string_agg(p.oid::regprocedure::text, ', ') into leak
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public'
     and has_function_privilege('anon', p.oid, 'EXECUTE')
     and not (p.proname = any(v_ok));
  if leak is not null then
    raise exception 'anon bu funksiyalari cagira bilir: %', leak;
  end if;

  --  az olan.  Bu yoxlama evvel yox idi: huquq itende fayl "OK" deyib
  --  kecirdi, sagird/valideyn tetbiqi ise canlida 401 alirdi.
  select string_agg(x, ', ') into leak
    from unnest(v_ok) x
   where exists (select 1 from pg_proc p
                   join pg_namespace n on n.oid = p.pronamespace
                  where n.nspname = 'public' and p.proname = x)
     and not exists (select 1 from pg_proc p
                       join pg_namespace n on n.oid = p.pronamespace
                      where n.nspname = 'public' and p.proname = x
                        and has_function_privilege('anon', p.oid, 'EXECUTE'));
  if leak is not null then
    raise exception 'anon bu funksiyalari cagira BILMIR: %', leak;
  end if;

  select count(*) into v_say
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public'
     and has_function_privilege('anon', p.oid, 'EXECUTE');
  raise notice 'Huquqlar quruldu: anon kataloqu ve % RPC-ni gorur.', v_say;
end $$;
