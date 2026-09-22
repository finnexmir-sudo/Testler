-- =====================================================================
--  bos_fenn.sql : BANK ORTUYU - FENN x SINIF
--
--  bos_movzular.sql adbaad siyahi verir (minlerle setir, oxunmur).
--  Bu sorgu hemin sayimi fenn ve sinif uzre yigir: bir bax, hansi
--  fennin hansi sinfi bos - novbeti bank isi oradadir.
--
--  «esl» = e-derslik sehife basliqlari cixarilmis yarpaq movzu sayi.
--  «hazir» = en azi 5 platform sualı olan movzu (generator islek qurur).
--  ORTUK faizi hazir/esl.  0% olan setir muellime «test yoxdur» deyir.
--
--  ISTIFADE: Supabase -> SQL Editor -> yapisdir -> Run.  Hec ne deyismir.
-- =====================================================================
with sayilmaz(nmn) as (
  values ('ümumiləşdirici%'), ('%xülasə%'), ('%yada salın%'),
         ('dəyərləndirmə%'), ('qiymətləndirmə%'), ('%summativ%'),
         ('sual və tapşırıq%'), ('ilkin yoxlama%'), ('layihə%'),
         ('steam%'), ('praktik dərs%'), ('elm%texnologiya%həyat%'),
         ('time to watch%'), ('use of english%'), ('mistake detector%'),
         ('nə öyrəndik%'), ('özünü yoxla%'), ('öyrəndiklərini%'),
         ('təkrarlama%'), ('%tapşırıqlar%')
),
say as (
  select coalesce(sub.name, '?') as fenn,
         coalesce(lv.code, '?')  as sinif,
         coalesce(lv.sort, 0)    as lsort,
         (select count(*) from public.questions q
           where q.topic_id = t.id
             and q.owner_type = 'platform'
             and q.status = 'published') as n
    from public.topics t
    left join public.subjects sub on sub.id = t.subject_id
    left join public.levels   lv  on lv.id  = t.level_id
   where not exists (select 1 from public.topics c where c.parent_id = t.id)
     and not exists (select 1 from sayilmaz z where lower(t.name) like z.nmn)
)
select fenn, sinif,
       count(*)                        as esl,
       count(*) filter (where n >= 5)  as hazir,
       count(*) filter (where n between 1 and 4) as az,
       count(*) filter (where n = 0)   as bos,
       round(100.0 * count(*) filter (where n >= 5) / count(*))::text || '%' as ortuk
  from say
 group by fenn, sinif, lsort
 order by fenn, lsort;
