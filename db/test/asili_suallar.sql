-- =====================================================================
--  asili_suallar.sql : SUALLAR ANA MOVZUDA ILISIB?
--
--  NIYE LAZIMDIR
--  22.09: bos_fenn.sql dedi ki Riyaziyyat 1-ci sinif 0% ortuludur.
--  Amma riy1 banki yuklenib. Demeli suallar var, gorunmur.
--  Sebeb ehtimali: e-derslik TOC importu kohne movzunun ALTINA usaq
--  movzu elave etmisdir -> kohne movzu artiq yarpaq deyil -> generator
--  (yarpaqla islyir) onu gormur -> muellime «test yoxdur» deyir.
--
--  Bu sorgu hemin ehtimali yoxlayir. Fenn x sinif uzre:
--    sual        - butun platform/published sual sayi
--    yarpaqda    - yarpaq movzuya bagli olanlar (GORUNUR)
--    anada       - alt movzusu olan movzuya bagli olanlar (ITIB)
--    movzusuz    - topic_id bos (ITIB)
--  «anada» sifirdan boyukse ehtimal tesdiqlenir, is kod terefindedir,
--  bank terefinde deyil.
--
--  ISTIFADE: Supabase -> SQL Editor -> yapisdir -> Run.  Hec ne deyismir.
--  Birinci setir xulasedir.
-- =====================================================================
with s as (
  select coalesce(sub.name, '(fənn yox)') as fenn,
         coalesce(lv.code, '?')           as sinif,
         coalesce(lv.sort, 0)             as lsort,
         case
           when q.topic_id is null then 'movzusuz'
           when exists (select 1 from public.topics c where c.parent_id = q.topic_id)
             then 'anada'
           else 'yarpaqda'
         end as yer
    from public.questions q
    left join public.topics   t   on t.id  = q.topic_id
    left join public.subjects sub on sub.id = coalesce(t.subject_id, q.subject_id)
    left join public.levels   lv  on lv.id  = coalesce(t.level_id, q.level_id)
   where q.owner_type = 'platform'
     and q.status = 'published'
)
select fenn, sinif, sual, yarpaqda, anada, movzusuz from (
  select 0 as sira, 'XULASE — hamısı' as fenn, '' as sinif, 0 as lsort,
         count(*)                                    as sual,
         count(*) filter (where yer = 'yarpaqda')    as yarpaqda,
         count(*) filter (where yer = 'anada')       as anada,
         count(*) filter (where yer = 'movzusuz')    as movzusuz
    from s
  union all
  select 1, fenn, sinif, lsort,
         count(*),
         count(*) filter (where yer = 'yarpaqda'),
         count(*) filter (where yer = 'anada'),
         count(*) filter (where yer = 'movzusuz')
    from s
   group by fenn, sinif, lsort
) z
order by sira, anada + movzusuz desc, fenn, lsort;
