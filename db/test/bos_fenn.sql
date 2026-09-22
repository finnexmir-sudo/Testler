-- =====================================================================
--  bos_fenn.sql : BANK ORTUYU - FESIL SEVIYYESINDE
--
--  BU FAYLIN BIRINCI VARIANTI YANLIS IDI - OXU, TEKRARLAMA
--  22.09-da bu sorgu «yarpaq movzuda en azi 5 sual olmalidir» ferziyyesi
--  ile yazildi ve «3313 movzu BOS», «Riyaziyyat 1 → 0%» dedi.
--  Ferziyye yanlisdir.  101_ders_plani_alt.sql-de qesden yazilib:
--  sual hovuzu FESILDEDIR, alt movzunun oz sualı yoxdur - alt movzu
--  plan ritmi ucundur.  «Test yig» fesil bitende cixir ve VALIDEYNIN
--  movzusundan yigir.  app.diag_topics de parent_id is null ile islyir.
--  Yani yarpagi bos gormek NORMALDIR, nasazliq deyil.
--
--  DUZGUN SUAL: muellim bir FESIL ucun test yigmaq isteyende alinir?
--  Cavab: hemin feslin ALT AGACINDA (ozu + butun alt movzulari)
--  en azi 5 platform/published sual varmi.
--
--  ISTIFADE: Supabase -> SQL Editor -> yapisdir -> Run.  Hec ne deyismir.
--  0% olan setir muellime «testler yoxdur» deyen yerdir - is oradadir.
-- =====================================================================
with recursive nesil as (
  -- her ust seviyye fesil ucun ozu + butun nesli
  select t.id as kok, t.id as uzv
    from public.topics t
   where t.parent_id is null
  union all
  select n.kok, c.id
    from nesil n
    join public.topics c on c.parent_id = n.uzv
),
fesil as (
  select t.id,
         coalesce(sub.name, '?') as fenn,
         coalesce(lv.code, '?')  as sinif,
         coalesce(lv.sort, 0)    as lsort,
         (select count(*) from public.questions q
           where q.owner_type = 'platform'
             and q.status = 'published'
             and q.topic_id in (select uzv from nesil n where n.kok = t.id)) as n
    from public.topics t
    left join public.subjects sub on sub.id = t.subject_id
    left join public.levels   lv  on lv.id  = t.level_id
   where t.parent_id is null
)
select fenn, sinif,
       count(*)                        as fesil,
       count(*) filter (where n >= 5)  as hazir,
       count(*) filter (where n between 1 and 4) as az,
       count(*) filter (where n = 0)   as bos,
       round(100.0 * count(*) filter (where n >= 5) / count(*))::text || '%' as ortuk,
       sum(n)                          as sual
  from fesil
 group by fenn, sinif, lsort
 order by ortuk, fenn, lsort;
