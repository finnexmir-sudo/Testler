-- =====================================================================
--  72_bos_fennler.sql : ISLENMEYEN BOS KATALOQ SETIRLERINI SILIR
--
--  NIYE
--  04_seed.sql kataloqu genis qurmusdu: 'kurikulum' fenni, 'miq' ve
--  'sertifikasiya' proqramlari (her birinde 4 ixtisas seviyyesi).
--  Bugune qeder onlarin HEC BIRINE movzu ve sual yazilmayib - muellim
--  paneldə bos fenn ve bos proqram gorur, bu ise mehsulun yarimciq
--  oldugu tesevvuru yaradir.
--
--  M I Q / sertifikasiya AYRI mehsuldur: menbeyi e-derslik derslikyi
--  deyil, DIM-in oz proqramidir; movzu agaci, cetinlik olcusu ve
--  qiymetlendirmə mentiqi de baskadir.  Ona gore hazir olana qeder
--  kataloqda yer tutmasin - slug-lar sonra ayni adla geri qaytarila
--  biler (04_seed.sql-de nümunə setirler serhde saxlanilib).
--
--  DIQQET: 'buraxilis' proqrami TOXUNULMUR - 57_sinif_dubli.sql-de
--  qerar verilmisdi ki, o slug esl buraxilis imtahani hazirligi ucun
--  bos qalsin (CLAUDE.md "Kataloq - her sinif BIR defe").
--
--  TEHLUKESIZLIK: fayl silmezden EVVEL her setrin bos oldugunu
--  yoxlayir - bir dene movzu/sual/qrup/test baglidirsa DAYANIR.
--  Tekrar isledile biler.
-- =====================================================================

do $$
declare k int; ad text;
begin
  --  1) bos olmayan bir sey varsa - dayan, sebebi ADI ile de
  select count(*) into k from public.topics t
    join public.subjects s on s.id = t.subject_id and s.slug = 'kurikulum';
  if k > 0 then
    raise exception 'kurikulum fenninde % movzu var - silinmir', k;
  end if;
  select count(*) into k from public.questions q
    join public.subjects s on s.id = q.subject_id and s.slug = 'kurikulum';
  if k > 0 then
    raise exception 'kurikulum fenninde % sual var - silinmir', k;
  end if;
  select count(*) into k from public.tests t
    join public.subjects s on s.id = t.subject_id and s.slug = 'kurikulum';
  if k > 0 then
    raise exception 'kurikulum fenninde % test var - silinmir', k;
  end if;

  select count(*) into k from public.topics t
    join public.levels l on l.id = t.level_id
    join public.programs p on p.id = l.program_id
   where p.slug in ('miq', 'sertifikasiya');
  if k > 0 then
    raise exception 'MIQ/sertifikasiya seviyyelerinde % movzu var - silinmir', k;
  end if;
  select count(*) into k from public.questions q
    join public.levels l on l.id = q.level_id
    join public.programs p on p.id = l.program_id
   where p.slug in ('miq', 'sertifikasiya');
  if k > 0 then
    raise exception 'MIQ/sertifikasiya seviyyelerinde % sual var - silinmir', k;
  end if;
  select count(*) into k from public.classes c
    join public.programs p on p.id = c.program_id
   where p.slug in ('miq', 'sertifikasiya');
  if k > 0 then
    raise exception 'MIQ/sertifikasiya proqramina % qrup baglidir - silinmir', k;
  end if;
  select count(*) into k from public.tests t
    join public.programs p on p.id = t.program_id
   where p.slug in ('miq', 'sertifikasiya');
  if k > 0 then
    raise exception 'MIQ/sertifikasiya proqramina % test baglidir - silinmir', k;
  end if;
  --  seviyyeye birbasa baglanmis qrup/test (program_id bos ola biler)
  select count(*) into k from public.classes c
    join public.levels l on l.id = c.level_id
    join public.programs p on p.id = l.program_id
   where p.slug in ('miq', 'sertifikasiya');
  if k > 0 then
    raise exception 'MIQ/sertifikasiya seviyyesine % qrup baglidir - silinmir', k;
  end if;
  select count(*) into k from public.tests t
    join public.levels l on l.id = t.level_id
    join public.programs p on p.id = l.program_id
   where p.slug in ('miq', 'sertifikasiya');
  if k > 0 then
    raise exception 'MIQ/sertifikasiya seviyyesine % test baglidir - silinmir', k;
  end if;
end $$;

--  2) silinme (bos oldugu yuxarida tesdiqlendi)
delete from public.program_subjects ps
 using public.subjects s
 where s.id = ps.subject_id and s.slug = 'kurikulum';

delete from public.subjects where slug = 'kurikulum';

delete from public.program_subjects ps
 using public.programs p
 where p.id = ps.program_id and p.slug in ('miq', 'sertifikasiya');

delete from public.levels l
 using public.programs p
 where p.id = l.program_id and p.slug in ('miq', 'sertifikasiya');

delete from public.programs where slug in ('miq', 'sertifikasiya');

--  3) yoxlama
do $$
declare k int; n int;
begin
  select count(*) into k from public.subjects where slug = 'kurikulum';
  if k <> 0 then
    raise exception 'kurikulum fenni hele de var';
  end if;
  select count(*) into k from public.programs
   where slug in ('miq', 'sertifikasiya');
  if k <> 0 then
    raise exception 'MIQ/sertifikasiya proqrami hele de var';
  end if;

  --  qalan kataloq toxunulmamis olmalidir
  select count(*) into k from public.subjects;
  if k <> 12 then
    raise exception 'Fenn sayi 12 olmalidir, % tapildi', k;
  end if;
  select count(*) into n from public.levels where code ~ '^[0-9]+$';
  if n <> 11 then
    raise exception 'Sinif sayi 11 olmalidir, % tapildi', n;
  end if;
  select count(*) into k from public.levels;
  if k <> n then
    raise exception 'Kataloqda % sinifden basqa % seviyye qalib', n, k;
  end if;

  raise notice 'Bos setirler silindi: kurikulum fenni, MIQ ve '
               'sertifikasiya proqramlari (8 seviyye). '
               'Kataloq: 12 fenn, 11 sinif.';
end $$;
