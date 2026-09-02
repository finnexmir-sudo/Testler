-- =====================================================================
--  smoke_siyahi_variant.sql : bank siyahisi variantlari da qaytarir
--                             (db/106_bank_siyahi_variantlar.sql)
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.class_plan_items; delete from public.class_plans;
delete from public.question_reports;
delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments;     delete from public.student_sessions;
delete from public.students;        delete from public.classes;
delete from public.subscriptions;
delete from public.test_questions tq using public.tests t
 where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.question_options o using public.questions q
 where q.id = o.question_id and q.owner_type = 'educator';
delete from public.questions where owner_type = 'educator';
delete from public.account_members; delete from public.accounts;
delete from public.user_roles;      delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-0000000000c1','s@t.az','{"full_name":"Siyahi Muellim"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000c1','tutor','S hesabi',
   '11110000-0000-0000-0000-0000000000c1');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000c1','11110000-0000-0000-0000-0000000000c1',true);
--  Variantlar ABUNE ile gelir - hesaba aktiv paket veririk
insert into public.subscriptions (account_id, plan_id, status, seats, current_period_end)
  select 'aaaa0000-0000-0000-0000-0000000000c1', id, 'active', 25, now() + interval '30 days'
    from public.plans where slug = 'repetitor-25' limit 1;

\echo '--- hazirliq tamam'

set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000c1';

-- =====================================================================
--  1. Her setirde variantlar var
-- =====================================================================
do $$
declare v jsonb; n int;
begin
  v := public.rpc_bank_list(
         jsonb_build_object('subject','riyaziyyat','level','8','pool','platform'),
         10, 0, null);
  assert jsonb_array_length(v->'items') > 0, 'siyahi bosdur';
  --  DIQQET: acar YOXDURSA x->'options' NULL verir ve NULL <> 'array'
  --  de NULL olur - setir sayilmir, yoxlama kohne kodda da kecerdi.
  --  coalesce olmasa bu test hec ne subut etmir.
  select count(*) into n from jsonb_array_elements(v->'items') x
   where coalesce(jsonb_typeof(x->'options'), 'YOXDUR') <> 'array';
  assert n = 0, n || ' setirde variant massivi yoxdur';
  select count(*) into n from jsonb_array_elements(v->'items') x
   where coalesce(jsonb_array_length(x->'options'), 0) < 2;
  assert n = 0, n || ' setirde 2-den az variant var';
end $$;
\echo 'OK  1 · her setirde variant massivi gelir'

-- =====================================================================
--  2. Duz cavab isarelenib - ekran onu yasil gostere bilsin
-- =====================================================================
do $$
declare v jsonb; n int;
begin
  v := public.rpc_bank_list(
         jsonb_build_object('subject','riyaziyyat','level','8','pool','platform'),
         10, 0, null);
  --  HER sualin en azi bir duz cavabi olmalidir
  select count(*) into n from jsonb_array_elements(v->'items') x
   where not exists (select 1 from jsonb_array_elements(x->'options') o
                      where (o->>'correct')::boolean);
  assert n = 0, n || ' sualda duz cavab isarelenmeyib';
end $$;
\echo 'OK  2 · her sualda duz cavab isarelenib'

-- =====================================================================
--  3. Variantlarin sirasi ord-a gore - ekran hemise eyni gostersin
-- =====================================================================
do $$
declare qid uuid; v jsonb; a text; b text;
begin
  select q.id into qid from public.questions q
   where q.owner_type='platform' and q.status='published' limit 1;
  select string_agg(o.body, '|' order by o.ord) into a
    from public.question_options o where o.question_id = qid;
  v := public.rpc_bank_list(jsonb_build_object('pool','platform'), 100, 0, null);
  select string_agg(o->>'body', '|') into b
    from jsonb_array_elements(v->'items') x,
         jsonb_array_elements(x->'options') o
   where (x->>'id')::uuid = qid;
  if b is not null then
    assert a = b, 'variant sirasi ord ile uzlasmir: [' || a || '] <> [' || b || ']';
  end if;
end $$;
\echo 'OK  3 · variantlar ord sirasi ile gelir'

-- =====================================================================
--  4. Suzgecler ve sayğac deyismeyib
-- =====================================================================
do $$
declare v jsonb; t1 int; t2 int;
begin
  v  := public.rpc_bank_list(
          jsonb_build_object('subject','riyaziyyat','level','8','pool','platform'),
          5, 0, null);
  t1 := (v->>'total')::int;
  assert jsonb_array_length(v->'items') = 5, 'limit isləmir';
  assert (v->>'offset')::int = 0, 'offset yanlisdir';
  --  ikinci sehife: ayri setirler, eyni cemi
  v  := public.rpc_bank_list(
          jsonb_build_object('subject','riyaziyyat','level','8','pool','platform'),
          5, 5, null);
  t2 := (v->>'total')::int;
  assert t1 = t2, 'sehifeleme cemi deyisdirir: ' || t1 || ' <> ' || t2;
  assert (v->>'offset')::int = 5, 'ikinci sehifenin offset-i yanlisdir';
end $$;
\echo 'OK  4 · suzgec, limit, offset ve cemi deyismeyib'

-- =====================================================================
--  5. Oz hovuzu bos - basqasinin suallari (ve cavablari) sizmir
-- =====================================================================
do $$
declare v jsonb;
begin
  v := public.rpc_bank_list(jsonb_build_object('pool','mine'), 50, 0, null);
  assert (v->>'total')::int = 0,
    'oz hovuzu bos ikən setir geldi: ' || (v->>'total')::text;
  assert jsonb_array_length(v->'items') = 0, 'bos hovuzda setir var';
end $$;
\echo 'OK  5 · "oz suallarim" hovuzuna platforma cavablari sizmir'

-- =====================================================================
--  6. ABUNE BITENDE variantlar da kesilir
--     (pulsuz hesab banki cavablari ile yukleye bilmesin)
-- =====================================================================
--  Abuneni sondurmek RLS altinda olmur - rolu buraxib edirik
reset role; reset request.jwt.claim.sub;
update public.subscriptions set status = 'canceled',
       current_period_end = now() - interval '1 day'
 where account_id = 'aaaa0000-0000-0000-0000-0000000000c1';
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000c1';
do $$
declare v jsonb; n int;
begin
  v := public.rpc_bank_list(
         jsonb_build_object('subject','riyaziyyat','level','8','pool','platform'),
         10, 0, null);
  assert jsonb_array_length(v->'items') > 0, 'abune bitende setirler de itdi';
  select count(*) into n from jsonb_array_elements(v->'items') x
   where jsonb_array_length(coalesce(x->'options','[]'::jsonb)) > 0;
  assert n = 0, 'abunesiz hesaba ' || n || ' setirde variant geldi';
  assert v::text not like '%"correct"%', 'abunesiz hesab duz cavabi gorur';
end $$;
\echo 'OK  6 · abune bitende variantlar kesilir, setirler qalir'

-- =====================================================================
--  7. Anon cagira bilmir - duz cavablar sagirde catmasin
-- =====================================================================
reset role; reset request.jwt.claim.sub;
do $$
begin
  if has_function_privilege('anon',
      'public.rpc_bank_list(jsonb, int, int, uuid)', 'EXECUTE') then
    raise exception 'anon bank siyahisini (ve duz cavablari) gore bilir';
  end if;
end $$;
\echo 'OK  7 · anon siyahidan kenardadir'

\echo 'SIYAHI VARIANTLARI: BUTUN YOXLAMALAR KECDI'
