-- =====================================================================
--  smoke_katalog.sql : bankin ehate gorüntüsü ve numune suallar
--                      (db/29_bank_katalog.sql)
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
  ('11110000-0000-0000-0000-0000000000ca','k@t.az','{"full_name":"Katalog Muellim"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000ca','tutor','K hesabi',
   '11110000-0000-0000-0000-0000000000ca');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000ca','11110000-0000-0000-0000-0000000000ca',true);

\echo '--- hazirliq tamam'

-- =====================================================================
--  1. Sinifsiz cagiris: siniflər ve saylar gelir, movzular GELMIR
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000ca';
do $$
declare v jsonb; n int; s int;
begin
  v := public.rpc_bank_coverage('riyaziyyat', null, 'platform');
  assert v->'topics' = 'null'::jsonb,
    'sinif verilmeyib, movzular yene geldi: ' || (v->'topics')::text;
  assert jsonb_array_length(v->'levels') >= 1, 'sinif siyahisi bosdur';
  --  Setirlerin cemi + sinifsizler = cemi.  Uzlasmirsa ekran yalan danisir.
  select sum((x->>'n')::int) into n from jsonb_array_elements(v->'levels') x;
  s := (v->>'no_level')::int;
  assert coalesce(n,0) + s = (v->>'total')::int,
    'setirlerin cemi cemi ile uzlasmir: ' || coalesce(n,0) || '+' || s ||
    ' <> ' || (v->>'total')::text;
end $$;
\echo 'OK  1 · sinifsiz cagiris: saylar uzlasir, movzular gelmir'

-- =====================================================================
--  2. Sinifle cagiris: movzular + cetinlik bolgusu
-- =====================================================================
do $$
declare v jsonb; k text; n int; d int;
begin
  select (x->>'code') into k
    from jsonb_array_elements(
           public.rpc_bank_coverage('riyaziyyat', null, 'platform')->'levels') x
   order by (x->>'n')::int desc limit 1;
  assert k is not null, 'sayli sinif tapilmadi';

  v := public.rpc_bank_coverage('riyaziyyat', k, 'platform');
  assert jsonb_array_length(v->'topics') >= 1, 'movzu siyahisi bosdur';
  --  Cetinlik bolgusu movzunun oz sayini vermelidir
  select (x->>'n')::int, ((x->>'d1')::int + (x->>'d2')::int + (x->>'d3')::int)
    into n, d
    from jsonb_array_elements(v->'topics') x limit 1;
  assert n = d, 'cetinlik bolgusu movzu sayi ile uzlasmir: ' || n || ' <> ' || d;
  --  Cemi indi YALNIZ o sinfin sayidir
  assert (v->>'total')::int > 0, 'sinif cemi sifirdir';
  assert (v->>'level') = k, 'cavabda sinif kodu qayitmir';
end $$;
\echo 'OK  2 · sinifle cagiris: movzular ve cetinlik bolgusu duzdur'

-- =====================================================================
--  3. Numune: en coxu 3, variantlari ile, duz cavab isarelenmis
-- =====================================================================
do $$
declare tid uuid; v jsonb; nopt int;
begin
  select t.id into tid
    from public.topics t
    join public.questions q on q.topic_id = t.id
   where q.owner_type = 'platform' and q.status = 'published'
   group by t.id having count(*) >= 2 limit 1;
  assert tid is not null, 'numune ucun movzu tapilmadi';

  --  p_limit 50 gonderilse de server 3-de kesir
  v := public.rpc_bank_samples(tid, 50, 'platform');
  assert jsonb_array_length(v) <= 3,
    'numune heddi asilib: ' || jsonb_array_length(v)::text;
  assert jsonb_array_length(v) >= 1, 'numune gelmedi';
  select jsonb_array_length(v->0->'options') into nopt;
  assert nopt >= 2, 'numunenin variantlari yoxdur';
  assert exists (select 1 from jsonb_array_elements(v->0->'options') o
                  where (o->>'correct')::boolean),
    'numunede duz cavab isarelenmeyib';
end $$;
\echo 'OK  3 · numune 3-le mehdud, variantlar ve duz cavab gelir'

-- =====================================================================
--  4. Oz hovuzu bosdursa sifir qaytarir - basqasinin suallari sizmir
-- =====================================================================
do $$
declare v jsonb; n int;
begin
  v := public.rpc_bank_coverage('riyaziyyat', null, 'mine');
  assert (v->>'total')::int = 0,
    'oz hovuzu bos ikən say geldi: ' || (v->>'total')::text;
  select coalesce(sum((x->>'n')::int), 0) into n
    from jsonb_array_elements(v->'levels') x;
  assert n = 0, 'oz hovuzunda platforma suallari saylanib: ' || n::text;
end $$;
\echo 'OK  4 · "oz suallarim" hovuzunda platforma suallari saylanmir'

-- =====================================================================
--  5. Yanlis giris deyerleri reddedilir
-- =====================================================================
do $$
declare ok boolean := false;
begin
  begin
    perform public.rpc_bank_coverage('riyaziyyat', null, 'hamisi-filan');
  exception when others then ok := true;
  end;
  assert ok, 'yanlis hovuz adi qebul olundu';

  ok := false;
  begin
    perform public.rpc_bank_coverage('bele-fenn-yoxdur', null, 'platform');
  exception when others then ok := true;
  end;
  assert ok, 'olmayan fenn qebul olundu';

  ok := false;
  begin
    perform public.rpc_bank_samples(null, 3, 'platform');
  exception when others then ok := true;
  end;
  assert ok, 'movzusuz numune sorgusu qebul olundu';
end $$;
\echo 'OK  5 · yanlis hovuz / fenn / bos movzu reddedilir'

-- =====================================================================
--  6. Anon hec birini cagira bilmir
-- =====================================================================
reset role; reset request.jwt.claim.sub;
do $$
begin
  if has_function_privilege('anon',
      'public.rpc_bank_coverage(text, text, text)', 'EXECUTE') then
    raise exception 'anon ehate gorüntüsünü cagira bilir';
  end if;
  if has_function_privilege('anon',
      'public.rpc_bank_samples(uuid, int, text)', 'EXECUTE') then
    raise exception 'anon numune suallari cagira bilir';
  end if;
end $$;
\echo 'OK  6 · anon her iki funksiyadan kenardadir'

\echo 'KATALOG: BUTUN YOXLAMALAR KECDI'
