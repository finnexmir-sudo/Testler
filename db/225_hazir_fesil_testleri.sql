-- =====================================================================
--  225 : HER FESILDEN BIR HAZIR TEST (2026-09-23)
--
--  NIYE
--  Yeni muellim «Tapşırıq» ekranini acir - siyahi BOSDUR.  Olculdu:
--  bazada 574 test var, HAMISI educator (muellimlerin oz yigdiqlari).
--  Hazir PLATFORMA testi hec vaxt olmayib.  Qizbest muellimin
--  «Bəzi mövzularda testlər yoxdur» reyinin koku budur: bank 22963
--  sualdir, amma ondan yigilmis HAZIR test sifirdir.
--
--  NE EDIR
--  Alt agacinda en azi 10 platform/published sual olan her UST
--  SEVIYYE fesil ucun bir test qurur: 10 sual, fesil adi ile.
--
--  QIYMET QAPISI: testler «is_free = false» yaradilir.
--  Sebeb: bankdan test yigmaq abune paketine daxildir
--  (13_generator.sql).  Hazir testleri pulsuz versek, eyni banki
--  arxa qapidan pulsuz vermis olardiq.  rpc_assign_test onsuz da
--  «is_free = false» olani abunesiz teyin etmir (28:99), interfeys
--  ise siyahida «abunə» nisani gosterir (app.js metaOf) - yeni
--  muellim DALANA dusmur, ne oldugunu gorur.
--
--  SUAL SECIMI
--  10 sual tesadufi deyil: evvel HER duzgun cavabdan BIRI goturulur,
--  sonra qalanlar doldurur.  Sebeb olculub - generatorun oz qaydasi:
--  eyni duzgun cavab 10 suallıq testde 2 defeden cox ola bilmez
--  (13_generator.sql, v_ansmax).  Hazir testde de eyni prinsip:
--  «0, 0, 0, 1, 0» kimi test olcmur.
--
--  TEKRAR ISLEDILE BILER: slug «haz-<topic_id>» sabitdir, ikinci
--  defe hec ne elave olunmur.
--
--  GERI QAYTARMAQ (lazim olsa - faylin sonundaki serhe bax).
--  ON SERT: 01 (tests), 11 (questions), 28 (rpc_assign_test).
-- =====================================================================

--  Hedd BIR yerdedir: miqrasiya da, yoxlama da eyni funksiyani cagirir.
--  10 sual = 10 suallıq test, yeni hovuz teste BERABERDIR: secim yoxdur.
--  Hazir test ucun bu qebul edilendir (o, bir defelik vitrindir, tekrar
--  yigilmir); generator ucun deyil - orada hedd 20-dir (app.ders_min).
create or replace function app.hazir_min() returns int
language sql immutable as $$ select 10 $$;

--  Feslin ALT AGACINDAKI yararli sual sayi.  «Yararli» = platform,
--  published VE duzgun cavabi olan.  Qapi ve sual secimi EYNI sayimi
--  cagirir - yoxsa qapi «var» deyer, secim 10 sual tapmaz ve test
--  yarimciq qalar.
create or replace function app.hazir_sual_sayi(p_fesil uuid) returns int
language sql stable security definer
set search_path = public, extensions, pg_temp as $$
  with recursive nesil as (
    select p_fesil as uzv
    union all
    select c.id from nesil n join public.topics c on c.parent_id = n.uzv
  )
  select count(*)::int
    from public.questions q
   where q.topic_id in (select uzv from nesil)
     and q.owner_type = 'platform' and q.status = 'published'
     and exists (select 1 from public.question_options o
                  where o.question_id = q.id and o.is_correct)
$$;

do $$
declare
  v_yeni int := 0;
  v_var  int := 0;
  v_sual int;
begin
  --  DIQQET: «create temporary table» ISLEDILMIR - Supabase SQL Editor
  --  hovuzlanmis baglantidadir, temp cedvel orada yasamaz (CLAUDE.md).
  --  Her sorgu oz CTE-sini qurur.
  select count(*) into v_sual from public.topics t
   where t.parent_id is null and t.subject_id is not null
     and app.hazir_sual_sayi(t.id) >= app.hazir_min();
  raise notice 'Namized fesil (>= % sual): %', app.hazir_min(), v_sual;

  --  ------------------------------------------------- testler
  with yeni as (
    insert into public.tests
      (owner_type, owner_id, program_id, subject_id, level_id,
       slug, title, description, is_free, status,
       shuffle_questions, shuffle_options, pass_percent)
    select 'platform', null,
           (select p.id from public.programs p
             where p.slug = case when coalesce(l.sort, 0) <= 4 then 'ibtidai'
                                 else 'orta' end
             limit 1),
           t.subject_id, t.level_id,
           'haz-' || t.id::text,
           t.name,
           'Hazır test — «' || t.name || '» fəslindən ' ||
             app.hazir_min()::text || ' sual.',
           false, 'published', true, true, 60
      from public.topics t
      left join public.levels l on l.id = t.level_id
     where t.parent_id is null
       and t.subject_id is not null
       and app.hazir_sual_sayi(t.id) >= app.hazir_min()
    on conflict (slug) do nothing
    returning id
  )
  select count(*) into v_yeni from yeni;

  --  ------------------------------------------------- suallar
  with recursive nesil as (
    select t.id as kok, t.id as uzv
      from public.topics t where t.parent_id is null
    union all
    select n.kok, c.id
      from nesil n join public.topics c on c.parent_id = n.uzv
  ),
  hovuz as (
    select n.kok, q.id as qid,
           --  eyni duzgun cavabdan BIRI one kecir (bax basliqdaki izah)
           row_number() over (
             partition by n.kok,
               coalesce((select string_agg(lower(btrim(o.body)), '|' order by o.body)
                           from public.question_options o
                          where o.question_id = q.id and o.is_correct), '')
             order by random()) as cav_rn
      from nesil n
      join public.questions q on q.topic_id = n.uzv
     where q.owner_type = 'platform' and q.status = 'published'
       and exists (select 1 from public.question_options o
                    where o.question_id = q.id and o.is_correct)
  ),
  secim as (
    select kok, qid, row_number() over (partition by kok
                                        order by cav_rn, random()) as rn
      from hovuz
  )
  insert into public.test_questions (test_id, question_id, ord)
  select t.id, s.qid, s.rn
    from secim s
    join public.tests t on t.slug = 'haz-' || s.kok::text
   where s.rn <= app.hazir_min()
     and not exists (select 1 from public.test_questions x where x.test_id = t.id)
  on conflict do nothing;

  select count(*) into v_var from public.tests
   where owner_type = 'platform' and slug like 'haz-%';

  raise notice 'Yeni test: %  ·  cemi hazir test: %', v_yeni, v_var;
end $$;

-- ---------------------------------------------------------------------
--  YOXLAMA: sualsiz test qalmamalidir
-- ---------------------------------------------------------------------
do $$
declare bos int;
begin
  select count(*) into bos from public.tests t
   where t.owner_type = 'platform' and t.slug like 'haz-%'
     and not exists (select 1 from public.test_questions x where x.test_id = t.id);
  if bos > 0 then
    raise exception 'SEHV: % hazir test SUALSIZ qaldi - bos test siyahida yararsizdir', bos;
  end if;
  raise notice 'OK - sualsiz hazir test yoxdur';
end $$;

-- =====================================================================
--  GERI QAYTARMAQ (lazim olsa, el ile islet):
--
--    delete from public.test_questions where test_id in (
--      select id from public.tests
--       where owner_type = 'platform' and slug like 'haz-%');
--    delete from public.assignments where test_id in (
--      select id from public.tests
--       where owner_type = 'platform' and slug like 'haz-%');
--    delete from public.tests
--     where owner_type = 'platform' and slug like 'haz-%';
-- =====================================================================
