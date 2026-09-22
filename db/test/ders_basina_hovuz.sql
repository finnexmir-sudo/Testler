-- =====================================================================
--  ders_basina_hovuz.sql : HER DERSE NECE SUAL DUSUR?
--
--  NIYE LAZIMDIR
--  22.09: Qizbest muellim «Bəzi mövzularda testlər yoxdur» yazdi.
--  Bank bos deyil (bos_fenn.sql: her fenn/sinif 100%).  Sebeb basqadir:
--  «test yig» duymesi YALNIZ feslin SON yarpaginda cixir (101-deki
--  can_test qapisi).  Riyaziyyat 10-da 10 fesil var, plan setri ise 67 -
--  demeli 57 dersde duyme yoxdur.  Muellim bunu «test yoxdur» kimi yazir.
--
--  Qapini her yarpaga acmaq ucun bir sual var: HOVUZ BOLUNURMU?
--  Fesilde 48 sual varsa ve 5 dersi varsa, hər derse ~9 sual dusur -
--  5 suallik ferqli test cixarmaq mumkundur.  2 dusurse mumkun deyil.
--
--  ders  - plan setri sayi (yarpaq; alt movzusu olmayan fesil ozu 1 setir)
--  hovuz - fesildeki sual (alt agac butov)
--  pay   - hovuz / ders, yani bir derse dusen sual
--  «PAY<10» sutunu: neçe fesilde pay 10-dan azdir (5 suallik test dar olur)
--
--  ISTIFADE: Supabase -> SQL Editor -> yapisdir -> Run.  Hec ne deyismir.
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
  select t.id,
         coalesce(sub.name, '?') as fenn,
         coalesce(lv.code, '?')  as sinif,
         coalesce(lv.sort, 0)    as lsort,
         --  plan setri: alt agacdaki yarpaqlar; yarpaq yoxdursa fesil ozu
         greatest(1, (select count(*) from nesil n
                       join public.topics y on y.id = n.uzv
                      where n.kok = t.id
                        and not exists (select 1 from public.topics c
                                         where c.parent_id = y.id))) as ders,
         (select count(*) from public.questions q
           where q.owner_type = 'platform'
             and q.status = 'published'
             and q.topic_id in (select uzv from nesil n where n.kok = t.id)) as hovuz
    from public.topics t
    left join public.subjects sub on sub.id = t.subject_id
    left join public.levels   lv  on lv.id  = t.level_id
   where t.parent_id is null
)
select fenn, sinif,
       count(*)      as fesil,
       sum(ders)     as ders,
       sum(hovuz)    as hovuz,
       round(sum(hovuz)::numeric / greatest(1, sum(ders)), 1) as pay,
       count(*) filter (where hovuz::numeric / greatest(1, ders) < 10) as pay_az,
       sum(ders) - count(*) as duymesiz
  from fesil
 group by fenn, sinif, lsort
 order by pay, fenn, lsort;
