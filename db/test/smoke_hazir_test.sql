-- =====================================================================
--  smoke_hazir_test.sql : 225 - her fesilden bir hazir test
--
--  ESL MIQRASIYA FAYLI isledilir (\i), suretı yox - yoxsa fayl deyiser,
--  test kohne suretı yoxlamaqda davam eder.
--
--  Yoxlanilir:
--    1. hedddən AZ sualı olan fesilde test YARANMIR
--    2. hedde catan fesilde test yaranir, DEQIQ 10 sual olur
--    3. test «is_free = false» - bank arxa qapidan pulsuz verilmir
--    4. suallar cavaba gore secilir: eyni duzgun cavab yigilmir
--    5. IKINCI defe islediləndə tekrar yaranmır (idempotent)
--
--  ISTIFADE:  cd db && psql -f test/smoke_hazir_test.sql
--  Oz melumatini yaradir ve SONUNDA GERI QAYTARIR (rollback).
-- =====================================================================
\set ON_ERROR_STOP on
begin;

--  ---------------------------------------------------- sinaq melumati
do $$
declare
  v_subj uuid; v_lev uuid; v_az uuid; v_bol uuid; v_q uuid; i int;
  qelib text[] := array['%s ədədinin kvadratı neçədir?',
                        'Tənliyi həll edin: x - %s = 0',
                        '%s ədədini 3-ə vurun',
                        '%s ilə 7-nin fərqi nədir?',
                        '%s ədədinin yarısı nədir?'];
begin
  select id into v_subj from public.subjects where slug = 'riyaziyyat';
  select id into v_lev  from public.levels   limit 1;

  insert into public.topics (subject_id, level_id, parent_id, name, slug, sort)
       values (v_subj, v_lev, null, 'HZ az fəsil', 'hz-az', 980) returning id into v_az;
  insert into public.topics (subject_id, level_id, parent_id, name, slug, sort)
       values (v_subj, v_lev, null, 'HZ bol fəsil', 'hz-bol', 981) returning id into v_bol;

  --  «az»: hedddən bir az.  «bol»: hedddən cox.
  for i in 1 .. 9 loop
    insert into public.questions (owner_type, subject_id, level_id, topic_id,
                                  kind, body, status, ext_key)
         values ('platform', v_subj, v_lev, v_az, 'single',
                 'AZ · ' || format(qelib[1 + (i % 5)], i * 3 + 7), 'published',
                 'hz-az-' || i) returning id into v_q;
    insert into public.question_options (question_id, ord, body, is_correct)
         values (v_q, 1, (i * 11 + 13)::text, true), (v_q, 2, (i * 11 + 14)::text, false);
  end loop;

  for i in 1 .. 14 loop
    insert into public.questions (owner_type, subject_id, level_id, topic_id,
                                  kind, body, status, ext_key)
         values ('platform', v_subj, v_lev, v_bol, 'single',
                 'BOL · ' || format(qelib[1 + (i % 5)], i * 3 + 7), 'published',
                 'hz-bol-' || i) returning id into v_q;
    --  ILK 4 sualin cavabi EYNIDIR - secim onlardan yalniz birini
    --  one cekmelidir (cav_rn qaydasi)
    insert into public.question_options (question_id, ord, body, is_correct)
         values (v_q, 1, case when i <= 4 then '42' else (i * 11 + 13)::text end, true),
                (v_q, 2, (i * 11 + 99)::text, false);
  end loop;
end $$;

--  ---------------------------------------------------- MIQRASIYA
\i 225_hazir_fesil_testleri.sql

--  ---------------------------------------------------- yoxlamalar
do $$
declare
  v_az uuid; v_bol uuid; n int; nf boolean; ferqli int;
begin
  select id into v_az  from public.topics where slug = 'hz-az';
  select id into v_bol from public.topics where slug = 'hz-bol';

  --  1. hedddən az
  if exists (select 1 from public.tests where slug = 'haz-' || v_az::text) then
    raise exception 'SEHV 1: hedddən AZ sualı olan fesilde test yarandi';
  end if;
  raise notice 'OK  1 · 9 sualı olan fesilde test YARANMIR (hedd %)', app.hazir_min();

  --  2. hedde catan
  select count(*) into n from public.test_questions x
    join public.tests t on t.id = x.test_id
   where t.slug = 'haz-' || v_bol::text;
  if n <> app.hazir_min() then
    raise exception 'SEHV 2: testde % sual var, % gozlenilirdi', n, app.hazir_min();
  end if;
  raise notice 'OK  2 · 14 sualı olan fesilde test yarandi, deqiq % sual', n;

  --  3. qiymet qapisi
  select is_free into nf from public.tests where slug = 'haz-' || v_bol::text;
  if nf then
    raise exception 'SEHV 3: hazir test PULSUZ yaradilib - bank arxa qapidan gedir';
  end if;
  raise notice 'OK  3 · «is_free = false» - abunesiz teyin olunmur';

  --  4. eyni cavab yigilmayib.  4 sualin cavabi «42» idi; secim onlardan
  --  en coxu 1-ni goturmelidir (qalan 10 ferqli cavab var).
  select count(*) into n
    from public.test_questions x
    join public.tests t on t.id = x.test_id
    join public.question_options o on o.question_id = x.question_id and o.is_correct
   where t.slug = 'haz-' || v_bol::text and lower(btrim(o.body)) = '42';
  if n > 1 then
    raise exception 'SEHV 4: eyni cavab («42») testde % defe var - secim cavaba '
      'gore islemir', n;
  end if;
  select count(distinct lower(btrim(o.body))) into ferqli
    from public.test_questions x
    join public.tests t on t.id = x.test_id
    join public.question_options o on o.question_id = x.question_id and o.is_correct
   where t.slug = 'haz-' || v_bol::text;
  raise notice 'OK  4 · «42» cavabi % defe, cemi % ferqli cavab', n, ferqli;
end $$;

--  ---------------------------------------------------- 5. idempotent
\i 225_hazir_fesil_testleri.sql

do $$
declare v_bol uuid; n int; t int;
begin
  select id into v_bol from public.topics where slug = 'hz-bol';
  select count(*) into t from public.tests where slug = 'haz-' || v_bol::text;
  select count(*) into n from public.test_questions x
    join public.tests tt on tt.id = x.test_id
   where tt.slug = 'haz-' || v_bol::text;
  if t <> 1 or n <> app.hazir_min() then
    raise exception 'SEHV 5: ikinci islemeden sonra % test, % sual (1 ve % olmali)',
      t, n, app.hazir_min();
  end if;
  raise notice 'OK  5 · ikinci defe islediləndə tekrar yaranmadi';
end $$;

rollback;
