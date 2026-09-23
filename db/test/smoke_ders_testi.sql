-- =====================================================================
--  smoke_ders_testi.sql : 222 - «ders:» nisani ile test yigilirmi?
--
--  Uc hal yoxlanilir:
--    A) nisanli sual app.ders_min()-den AZ  -> FESIL testi (kohne hal)
--    B) nisanli sual tam heddde            -> DERS testi
--    C) yigilan testde YALNIZ nisanli sual olur (yad sual sizmir)
--  Ayrica: qapi ile generatorun suzgeci EYNI saymalidir - yoxsa qapi
--  «var» deyer, generator «yoxdur» deye xeta atar.
--
--  ISTIFADE:  psql -f db/test/smoke_ders_testi.sql
--  Oz melumatini yaradir ve SONUNDA GERI QAYTARIR (rollback).
-- =====================================================================
\set ON_ERROR_STOP on
begin;

do $$
declare
  v_subj uuid; v_lev uuid;
  v_fesil uuid; v_az uuid; v_bol uuid;
  v_q uuid; i int;
  v_n int; v_hedd int;
begin
  v_hedd := app.ders_min();

  select id into v_subj from public.subjects where slug = 'riyaziyyat';
  select id into v_lev  from public.levels   where code = '8';
  if v_lev is null then select id into v_lev from public.levels limit 1; end if;

  --  fesil + iki ders
  insert into public.topics (subject_id, level_id, parent_id, name, slug, sort)
       values (v_subj, v_lev, null, 'SINAQ fəsil', 'sq-fesil', 990)
    returning id into v_fesil;
  insert into public.topics (subject_id, level_id, parent_id, name, slug, sort)
       values (v_subj, v_lev, v_fesil, 'SINAQ az dərs', 'sq-az', 991)
    returning id into v_az;
  insert into public.topics (subject_id, level_id, parent_id, name, slug, sort)
       values (v_subj, v_lev, v_fesil, 'SINAQ bol dərs', 'sq-bol', 992)
    returning id into v_bol;

  --  «az» dersine hedddən BIR AZ suali, «bol» dersine tam hedd qeder.
  --  Ayrica nisansiz suallar - fesil hovuzunu doldurur.
  for i in 1 .. (v_hedd - 1) loop
    insert into public.questions (owner_type, subject_id, level_id,
                                  topic_id, kind, body, status, tags)
         values ('platform', v_subj, v_lev, v_fesil, 'single',
                 'AZ sual ' || i, 'published', array[app.ders_tag('sq-az')])
      returning id into v_q;
    insert into public.question_options (question_id, ord, body, is_correct)
         values (v_q, 1, 'düz', true), (v_q, 2, 'səhv', false);
  end loop;

  for i in 1 .. v_hedd loop
    insert into public.questions (owner_type, subject_id, level_id,
                                  topic_id, kind, body, status, tags)
         values ('platform', v_subj, v_lev, v_fesil, 'single',
                 'BOL sual ' || i, 'published', array[app.ders_tag('sq-bol')])
      returning id into v_q;
    insert into public.question_options (question_id, ord, body, is_correct)
         values (v_q, 1, 'düz', true), (v_q, 2, 'səhv', false);
  end loop;

  --  ---- 1. sayim duzgundur
  v_n := app.ders_sual_sayi(v_fesil, 'sq-az');
  if v_n <> v_hedd - 1 then
    raise exception 'SEHV 1: «az» dersinde % sual gozlenilirdi, % tapildi',
      v_hedd - 1, v_n;
  end if;
  v_n := app.ders_sual_sayi(v_fesil, 'sq-bol');
  if v_n <> v_hedd then
    raise exception 'SEHV 2: «bol» dersinde % sual gozlenilirdi, % tapildi',
      v_hedd, v_n;
  end if;
  raise notice 'OK  1 · app.ders_sual_sayi duzgun sayir (% / %)',
    v_hedd - 1, v_hedd;

  --  ---- 2. hedd: biri asagi, biri tam ustunde
  if app.ders_sual_sayi(v_fesil, 'sq-az') >= app.ders_min() then
    raise exception 'SEHV 3: hedddən az olan ders «hazir» sayildi';
  end if;
  if app.ders_sual_sayi(v_fesil, 'sq-bol') < app.ders_min() then
    raise exception 'SEHV 4: hedde catan ders «hazir» sayilmadi';
  end if;
  raise notice 'OK  2 · hedd (%) deqiq yerinde isleyir', v_hedd;

  --  ---- 3. test olcusu hovuzdan BOYUK ola bilmez (xeta qaynagi)
  if app.ders_test_count() > app.ders_min() then
    raise exception 'SEHV 5: test olcusu (%) hedddən (%) boyukdur - '
      'generator «kifayet sual yoxdur» xetasi atacaq',
      app.ders_test_count(), app.ders_min();
  end if;
  raise notice 'OK  3 · test olcusu (%) hedddən (%) kicikdir - xeta riski yoxdur',
    app.ders_test_count(), app.ders_min();

  --  ---- 4. nisan yazilisi bir yerdedir
  if app.ders_tag('abc') <> 'ders:abc' then
    raise exception 'SEHV 6: nisan yazilisi deyisib: %', app.ders_tag('abc');
  end if;
  raise notice 'OK  4 · nisan yazilisi «ders:<slug>»';
end $$;

rollback;
