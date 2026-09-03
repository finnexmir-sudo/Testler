-- =====================================================================
--  113_valideyn_huquq_berpa.sql : anon-un RPC huquqlarini BERPA edir
--
--  NIYE LAZIM OLDU
--  ---------------
--  107_valideyn.sql valideyn funksiyalarini yaradib anon-a EXECUTE
--  verir.  Amma ondan SONRA kohne (valideyni tanimayan) 05_grants.sql
--  isledilse, o funksiyalar "siyahida yoxdur" sayilib huquqdan
--  mehrum olurdu.  Canli bazada netice:
--
--      rpc_parent_login  ->  401  permission denied for function
--
--  Daha pisi: kohne 05_grants.sql yalniz GERI ALIRDI, hec ne VERMIRDI -
--  ona gore onu tekrar isletmek de vəziyyəti duzeltmirdi.  Indi
--  05_grants.sql oz-ozunu sagaldir (asagi bax), bu fayl ise ONSUZ DA
--  sinmis bazani bir defeye qaldirmaq ucundur.
--
--  Tehlukesizlik: burda YALNIZ o 11 funksiya var ki, 05_grants.sql-in
--  ag siyahisinda artiq duran onlardir.  Yeni qapi acmir.
--
--  Istenilen sayda isledile biler - idempotentdir.
-- =====================================================================

do $$
declare
  --  Sagird tetbiqi (03_rpc.sql) 8, valideyn tetbiqi (107_valideyn.sql)
  --  3 funksiya cagirir.  Basqa hec ne.
  v_ok text[] := array[
        'rpc_student_login','rpc_student_tests',
        'rpc_start_attempt','rpc_submit_attempt',
        'rpc_leaderboard','rpc_test_result',
        'rpc_report_question_student','rpc_student_my_results',
        'rpc_parent_login','rpc_parent_home','rpc_parent_logout'];
  fn      text;
  v_say   int := 0;
  v_yox   text;
begin
  for fn in
    select p.oid::regprocedure::text
      from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public'
       and p.prokind = 'f'
       and p.proname = any(v_ok)
       and not has_function_privilege('anon', p.oid, 'EXECUTE')
  loop
    execute format('grant execute on function %s to anon, authenticated', fn);
    v_say := v_say + 1;
    raise notice 'berpa: %', fn;
  end loop;

  --  Siyahida olub bazada olmayan varsa - miqrasiya yarimciqdir.
  select string_agg(x, ', ') into v_yox
    from unnest(v_ok) x
   where not exists (select 1 from pg_proc p
                       join pg_namespace n on n.oid = p.pronamespace
                      where n.nspname = 'public' and p.proname = x);
  if v_yox is not null then
    raise exception 'Bu funksiyalar bazada yoxdur: %.  Evvelce miqrasiyalari isledin (107_valideyn.sql).', v_yox;
  end if;

  if v_say = 0 then
    raise notice 'Huquqlar onsuz da yerinde idi - hec ne deyismedi.';
  else
    raise notice '% funksiyanin huququ berpa olundu.', v_say;
  end if;
end $$;
