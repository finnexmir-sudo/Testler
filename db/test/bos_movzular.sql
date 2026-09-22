-- =====================================================================
--  bos_movzular.sql : HANSI FESILDE TEST YIGILA BILMIR?  (adbaad)
--
--  BU FAYLIN BIRINCI VARIANTI YANLIS IDI - OXU, TEKRARLAMA
--  22.09-da yarpaq movzulari sayirdi ve «3313 movzu BOS» dedi.
--  Yanlis ferziyye: «yarpaqda sual olmalidir».  101_ders_plani_alt.sql
--  qesden eksini qurur - sual hovuzu FESILDEDIR, alt movzu plan
--  ritmi ucundur, «test yig» valideynin movzusundan yigir.
--  Yarpagin bos olmasi nasazliq DEYIL.
--
--  BU VARIANT: her UST SEVIYYE fesil ucun alt agacindaki (ozu + butun
--  nesli) platform/published sual sayi.  5-den azi generatorda islemir.
--  bos_fenn.sql eyni sayimin fenn x sinif xulasesidir - once onu isle,
--  bu fayl yalniz secilmis fenne baxanda lazimdir.
--
--  ISTIFADE: Supabase -> SQL Editor -> yapisdir -> Run.  Hec ne deyismir.
--  Birinci setir xulase, sonra fesiller - en bosu yuxarida.
-- =====================================================================
with recursive nesil as (
  select t.id as kok, t.id as uzv
    from public.topics t
   where t.parent_id is null
  union all
  select n.kok, c.id
    from nesil n
    join public.topics c on c.parent_id = n.uzv
),
fesil as (
  select t.id, t.name as fesil, t.sort,
         coalesce(sub.name, '?') as fenn,
         coalesce(lv.code, '?')  as sinif,
         coalesce(lv.sort, 0)    as lsort,
         (select count(*) from public.topics c where c.parent_id = t.id) as alt,
         (select count(*) from public.questions q
           where q.owner_type = 'platform'
             and q.status = 'published'
             and q.topic_id in (select uzv from nesil n where n.kok = t.id)) as n
    from public.topics t
    left join public.subjects sub on sub.id = t.subject_id
    left join public.levels   lv  on lv.id  = t.level_id
   where t.parent_id is null
)
select hal, fenn, sinif, fesil, alt, say from (
  select 0 as sira, 'XULASE' as hal, null::text as fenn, null::text as sinif,
         null::text as fesil, null::text as alt, 0 as lsort, 0 as tsort,
         count(*) filter (where n = 0)::text || ' fəsil BOŞ · ' ||
         count(*) filter (where n between 1 and 4)::text || ' fəsil AZ (1-4) · ' ||
         count(*) filter (where n >= 5)::text || ' fəsil hazır · ' ||
         count(*)::text || ' fəsil' as say
    from fesil
  union all
  select case when n = 0 then 1 else 2 end,
         case when n = 0 then 'BOŞ' else 'AZ' end,
         fenn, sinif, fesil, alt::text, lsort, sort, n::text
    from fesil
   where n < 5
) z
order by sira, fenn, lsort, tsort, fesil;
