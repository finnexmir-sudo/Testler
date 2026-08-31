-- =====================================================================
--  73_buraxilis_proqrami.sql : BOS 'buraxilis' PROQRAMI SILINIR
--
--  NIYE
--  57_sinif_dubli.sql-de qerar verilmisdi ki, 'buraxilis' slug-i esl
--  buraxilis imtahani hazirligi ucun bos qalsin.  Indi hemin hazirligin
--  DIZAYNI aydinlasdi ve gorunur ki, PROQRAM sehv formadir:
--
--    * 'programs -> levels -> classes' agaci muellimin QRUP yaratdigi
--      agacdir.  Repetitor "Buraxilis" qrupu yaratmir - o, "11-ci sinif"
--      qrupu yaradir ve ona buraxilis TIPLI test verir.
--    * Real buraxilis imtahani COXFENNLIDIR, 'tests' setrinde ise
--      subject_id tekdir ve not null - bir test setri tam imtahani
--      tuta bilmir.
--
--  Ona gore buraxilis proqram yox, IMTAHAN SABLONU kimi qurulacaq
--  (exam_blueprints / exam_sessions - ayri fayl).  Sablon MELUMATDIR:
--  DIM qaydasi deyisende SQL setri deyisir, kod yox.
--
--  Slug bosalir - lazim olsa 04_seed.sql-e bir setirle qaytarmaq olar.
--
--  TEHLUKESIZLIK: silmezden EVVEL proqramin bos oldugu yoxlanilir -
--  bir dene seviyye/qrup/test baglidirsa DAYANIR.
--  Tekrar isledile biler.
-- =====================================================================

do $$
declare k int;
begin
  if not exists (select 1 from public.programs where slug = 'buraxilis') then
    raise notice '"buraxilis" proqrami onsuz da yoxdur - deyisiklik olmadi.';
    return;
  end if;

  select count(*) into k from public.levels l
    join public.programs p on p.id = l.program_id and p.slug = 'buraxilis';
  if k > 0 then
    raise exception '"buraxilis" proqraminda % seviyye var - silinmir', k;
  end if;
  select count(*) into k from public.classes c
    join public.programs p on p.id = c.program_id and p.slug = 'buraxilis';
  if k > 0 then
    raise exception '"buraxilis" proqramina % qrup baglidir - silinmir', k;
  end if;
  select count(*) into k from public.tests t
    join public.programs p on p.id = t.program_id and p.slug = 'buraxilis';
  if k > 0 then
    raise exception '"buraxilis" proqramina % test baglidir - silinmir', k;
  end if;
end $$;

delete from public.program_subjects ps
 using public.programs p
 where p.id = ps.program_id and p.slug = 'buraxilis';

delete from public.programs where slug = 'buraxilis';

do $$
declare k int;
begin
  if exists (select 1 from public.programs where slug = 'buraxilis') then
    raise exception '"buraxilis" proqrami hele de var';
  end if;
  select count(*) into k from public.programs;
  if k <> 2 then
    raise exception 'Kataloqda 2 proqram qalmalidir (ibtidai, orta), % tapildi', k;
  end if;
  select count(*) into k from public.levels where code ~ '^[0-9]+$';
  if k <> 11 then
    raise exception 'Sinif sayi 11 olmalidir, % tapildi', k;
  end if;
  raise notice '"buraxilis" proqrami silindi. Kataloq: 2 proqram, 11 sinif. '
               'Buraxilis hazirligi imtahan sablonu kimi qurulacaq.';
end $$;
