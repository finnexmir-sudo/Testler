-- =====================================================================
--  bos_movzular.sql : HANSI MOVZUDA TEST YIGILA BILMIR?
--
--  NIYE LAZIMDIR
--  22.09: Qizbest muellim yazdi - «Bəzi mövzularda testlər yoxdur».
--  Bu sorgu hemin movzulari adbaad sayir: generator BES sual teleb
--  edir, ondan azi olan movzuda «test yig» islemir.
--
--  YALNIZ YARPAQ movzular sayilir (alt movzusu olmayan) - ders plani
--  ve generator elə onlarla islek qurur; fesil basligi sual tutmur.
--  Sayim YALNIZ hazir bankdir (owner_type='platform', status='published');
--  muellimin oz suallari basqa muellime kecmir.
--
--  ISTIFADE: Supabase -> SQL Editor -> yapisdir -> Run.  Hec ne deyismir.
--  Birinci setir umumi menzere, sonra movzular - en bosu yuxarida.
-- =====================================================================
with yarpaq as (
  select t.id, t.name as movzu, t.sort,
         coalesce(sub.name, '?') as fenn,
         coalesce(lv.code, '?')  as sinif,
         coalesce(lv.sort, 0)    as lsort,
         coalesce(par.name, '')  as fesil
    from public.topics t
    left join public.subjects sub on sub.id = t.subject_id
    left join public.levels   lv  on lv.id  = t.level_id
    left join public.topics   par on par.id = t.parent_id
   where not exists (select 1 from public.topics c where c.parent_id = t.id)
),
say as (
  select y.*, (select count(*) from public.questions q
                where q.topic_id = y.id
                  and q.owner_type = 'platform'
                  and q.status = 'published') as n
    from yarpaq y
)
select hal, fenn, sinif, movzu, fesil, say from (
  select 0 as sira, 'XULASE' as hal, null::text as fenn, null::text as sinif,
         null::text as movzu, null::text as fesil, 0 as lsort, 0 as tsort,
         count(*) filter (where n = 0)::text || ' mövzu BOŞ · ' ||
         count(*) filter (where n between 1 and 4)::text || ' mövzu AZ (1-4) · ' ||
         count(*)::text || ' yarpaq mövzu' as say
    from say
  union all
  select case when n = 0 then 1 else 2 end,
         case when n = 0 then 'BOŞ' else 'AZ' end,
         fenn, sinif, movzu, fesil, lsort, sort, n::text
    from say
   where n < 5
) z
order by sira, fenn, lsort, tsort, movzu;
