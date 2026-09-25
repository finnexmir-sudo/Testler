-- =====================================================================
--  smoke_numune_gc.sql : 901 - numune nusxelerinin yigisdirilmasi
--
--  Iddialar:
--    1. app.demo_gc porsiya-porsiya silir (limit gozlenilir)
--    2. «left» qalan sayi duzgun deyir - is axini ona baxir
--    3. PAYLASILAN esas numune HEC VAXT silinmir
--    4. 24 saatdan TEZE nusxe silinmir
--    5. hesabsiz anonim istifadeci (yetim) de yigisdirilir
--    6. rpc_demo_reset-in oz vaxt heddi var (timeout-a dusmesin)
--    7. temp cedvel ISLEDILMIR (Supabase hovuzlanmis baglanti)
--
--  ISTIFADE: psql -f db/test/smoke_numune_gc.sql
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = notice;

--  Oz sinaq nusxelerimizi temizleyirik (tekrar isletmek ucun)
do $$
declare v_acc uuid[]; v_own uuid[];
begin
  select array_agg(a.id), array_agg(a.owner_id) into v_acc, v_own
    from public.accounts a where a.is_demo and a.id <> app.demo_account();
  if v_acc is not null then
    delete from public.classes  c where c.account_id = any(v_acc);
    delete from public.students s where s.account_id = any(v_acc);
    delete from public.accounts a where a.id = any(v_acc);
    delete from auth.users      u where u.id = any(v_own);
  end if;
end $$;

--  7 kohne + 1 teze nusxe qurulur
do $$
declare u uuid; a uuid; i int;
begin
  for i in 1..7 loop
    u := gen_random_uuid();
    insert into auth.users (id, email, created_at) values (u, null, now() - interval '3 days');
    insert into public.accounts (owner_id, name, type, is_demo, created_at)
         values (u, 'Nümunə hesabı', 'tutor', true, now() - interval '3 days')
      returning id into a;
    insert into public.classes (account_id, teacher_id, kind, name, join_code)
         values (a, u, 'tutor_group', 'Nümunə qrup', 'GC' || i || substr(md5(random()::text), 1, 6));
  end loop;
  --  TEZE nusxe - toxunulmamalidir
  u := gen_random_uuid();
  insert into auth.users (id, email, created_at) values (u, null, now());
  insert into public.accounts (owner_id, name, type, is_demo, created_at)
       values (u, 'Nümunə hesabı', 'tutor', true, now());
  --  YETIM anonim istifadeci - hesabi yoxdur
  insert into auth.users (id, email, created_at)
       values (gen_random_uuid(), null, now() - interval '3 days');
end $$;

\echo '--- hazirliq: 7 kohne + 1 teze nusxe + 1 yetim'

do $$
declare v jsonb; v_hami int; v_esas uuid := app.demo_account();
begin
  --  ---- 1-2: porsiya ve «left»
  v := app.demo_gc(3);
  assert (v->>'deleted')::int = 3, 'SEHV 1: 3 gozlenilirdi, silindi ' || (v->>'deleted');
  assert (v->>'left')::int = 4, 'SEHV 2: qalan 4 olmalidir, geldi ' || (v->>'left');
  raise notice 'OK  1 · porsiya isleyir - 3 silindi';
  raise notice 'OK  2 · «left» = 4 (is axini buna baxir)';

  --  ---- 5: yetim anonim istifadeci de yigisdirildi
  assert (v->>'orphans')::int >= 1, 'SEHV 5: yetim anonim istifadeci silinmedi';
  raise notice 'OK  5 · hesabsiz anonim istifadeci de yigisdirilir';

  --  ---- sifira qeder
  v := app.demo_gc(50);
  assert (v->>'left')::int = 0, 'SEHV: sonda 0 gozlenilir, geldi ' || (v->>'left');
  raise notice 'OK  3 · «left» sifira dusur';

  --  ---- 3: paylasilan esas numune YERINDEDIR
  assert exists (select 1 from public.accounts where id = v_esas),
    'SEHV 3: PAYLASILAN esas numune hesabi silinib!';
  raise notice 'OK  4 · paylasilan esas numune toxunulmayib';

  --  ---- 4: 24 saatdan teze nusxe silinmeyib
  select count(*) into v_hami from public.accounts a
   where a.is_demo and a.id <> v_esas;
  assert v_hami = 1, 'SEHV 4: teze nusxe silinib (qalan ' || v_hami || ')';
  raise notice 'OK  5b · 24 saatdan teze nusxe saxlanilir';
end $$;

--  ---- 6-7: funksiyanin OZU
do $$
declare v_def text;
begin
  select pg_get_functiondef(p.oid) into v_def
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'rpc_demo_reset';
  assert position('statement_timeout' in v_def) > 0,
    'SEHV 6: rpc_demo_reset-in oz vaxt heddi yoxdur - yene timeout-a dusecek';
  raise notice 'OK  6 · rpc_demo_reset-in oz statement_timeout-u var';

  assert position('temp table' in lower(v_def)) = 0,
    'SEHV 7: muveqqeti cedvel qalib - Supabase hovuzlanmis baglantida sinir';
  raise notice 'OK  7 · muveqqeti cedvel islenmir';

  select pg_get_functiondef(p.oid) into v_def
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'app' and p.proname = 'demo_gc';
  assert position('temp table' in lower(v_def)) = 0,
    'SEHV 7: app.demo_gc-de muveqqeti cedvel var';
  raise notice 'OK  7b · app.demo_gc-de de yoxdur';
end $$;

\echo 'HAMISI OK - 901 numune yigisdiricisi'
