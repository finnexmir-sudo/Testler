-- =====================================================================
--  smoke_huquq.sql : anon-un funksiya huquqlari (db/05_grants.sql)
--
--  NIYE VAR
--  --------
--  Canli bazada valideyn girisi "permission denied for function
--  rpc_parent_login" verdi.  Sebeb: 107_valideyn.sql-den SONRA kohne
--  05_grants.sql isledilmisdi - o, valideyn funksiyalarini taniyib
--  huququ geri almisdi.  Ustelik hemin fayl YALNIZ geri alirdi, hec ne
--  vermirdi; ona gore onu tekrar isletmek de duzeltmirdi.
--
--  Bu suite hem sizmani (cox huquq), hem de itmeni (az huquq) tutur.
--  Evvel yalniz birincisi yoxlanilirdi - ikincisi sessizce kecirdi.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

create temporary view t_anon as
  select p.proname,
         p.oid::regprocedure::text as sig,
         has_function_privilege('anon', p.oid, 'EXECUTE') as ac
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.prokind = 'f';

--  1 · susmaya gore tam olaraq 18 funksiya aciqdir
do $$
declare v_say int; v_ad text;
begin
  select count(*), string_agg(distinct proname, ', ' order by proname)
    into v_say, v_ad from t_anon where ac;
  if v_say <> 18 then
    raise exception 'anon % funksiya gorur (18 gozlenilir): %', v_say, v_ad;
  end if;
end $$;
\echo 'OK  1 · anon tam olaraq 18 RPC gorur'

--  2 · siyahinin OZU dogrudur - ad-ad
do $$
declare v_yox text;
begin
  select string_agg(x, ', ') into v_yox from unnest(array[
      'rpc_student_login','rpc_student_tests','rpc_start_attempt',
      'rpc_submit_attempt','rpc_leaderboard','rpc_test_result',
      'rpc_report_question_student','rpc_student_my_results',
      'rpc_parent_login','rpc_parent_home','rpc_parent_logout',
      'rpc_student_feedback','rpc_parent_feedback',
      'rpc_student_mistakes','rpc_student_mistake_answer',
      'rpc_student_practice_topics','rpc_student_practice_next','rpc_student_practice_answer']) x
   where not exists (select 1 from t_anon where proname = x and ac);
  if v_yox is not null then
    raise exception 'bu RPC-ler anon-a baglidir: %', v_yox;
  end if;
end $$;
\echo 'OK  2 · 8 sagird + 3 valideyn + 2 «bize yaz» + 3 mesq RPC-si adbaad aciqdir'

--  3 · SEHV SIRA senarisi: valideyn huququ itir
do $$
declare fn text;
begin
  for fn in select sig from t_anon
             where proname in ('rpc_parent_login','rpc_parent_home','rpc_parent_logout')
  loop
    execute format('revoke all on function %s from anon', fn);
  end loop;
end $$;
do $$
begin
  if exists (select 1 from t_anon
              where proname = 'rpc_parent_login' and ac) then
    raise exception 'senari qurulmadi: huquq hele de var';
  end if;
end $$;
\echo 'OK  3 · sinmis vəziyyət tekrar quruldu (401 senarisi)'

--  4 · 05_grants.sql oz-ozunu sagaldir
\i 05_grants.sql
do $$
declare v_yox text;
begin
  select string_agg(x, ', ') into v_yox from unnest(array[
      'rpc_parent_login','rpc_parent_home','rpc_parent_logout']) x
   where not exists (select 1 from t_anon where proname = x and ac);
  if v_yox is not null then
    raise exception '05_grants.sql berpa etmedi: %', v_yox;
  end if;
end $$;
\echo 'OK  4 · 05_grants.sql itmis huququ BERPA edir'

--  5 · 113_valideyn_huquq_berpa.sql tek basina da duzeldir
do $$
declare fn text;
begin
  for fn in select sig from t_anon
             where proname in ('rpc_parent_login','rpc_parent_home','rpc_parent_logout')
  loop
    execute format('revoke all on function %s from anon', fn);
  end loop;
end $$;
\i 113_valideyn_huquq_berpa.sql
do $$
declare v_yox text;
begin
  select string_agg(x, ', ') into v_yox from unnest(array[
      'rpc_parent_login','rpc_parent_home','rpc_parent_logout']) x
   where not exists (select 1 from t_anon where proname = x and ac);
  if v_yox is not null then
    raise exception '113 berpa etmedi: %', v_yox;
  end if;
end $$;
\echo 'OK  5 · 113_valideyn_huquq_berpa.sql tek basina isleyir'

--  6 · berpa faylini iki defe isletmek zerer vermir
\i 113_valideyn_huquq_berpa.sql
do $$
declare v_say int;
begin
  select count(*) into v_say from t_anon where ac;
  if v_say <> 18 then raise exception 'tekrar isletmek sayi deyisdi: %', v_say; end if;
end $$;
\echo 'OK  6 · berpa idempotentdir - ikinci defe hec ne deyismir'

--  7 · unudulmus yeni funksiya hele de OZ-OZUNE baglanir
create or replace function public.rpc_unudulmus_test() returns int
  language sql as $$ select 1 $$;
grant execute on function public.rpc_unudulmus_test() to anon;
\i 05_grants.sql
do $$
begin
  if exists (select 1 from t_anon where proname = 'rpc_unudulmus_test' and ac) then
    raise exception 'siyahida olmayan funksiya aciq qaldi';
  end if;
end $$;
drop function public.rpc_unudulmus_test();
\echo 'OK  7 · ag siyahida olmayan funksiya avtomatik baglanir'

--  8 · anon-a hec bir kataloqdan kenar cedvel aciq deyil
do $$
declare leak text;
begin
  select string_agg(distinct table_name, ', ') into leak
    from information_schema.role_table_grants
   where grantee = 'anon' and table_schema = 'public'
     and table_name not in ('programs','subjects','program_subjects',
                            'levels','topics','plans');
  if leak is not null then raise exception 'aciq cedvel: %', leak; end if;
end $$;
\echo 'OK  8 · anon yalniz kataloq cedvellerini gorur'
