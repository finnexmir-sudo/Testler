-- =====================================================================
--  rey_haradan.sql : MUELLIM REYI YAZANDA NEYE BAXIRDI?
--
--  feedback.page setri rəyin HANSI SEHIFEDEN yazildigini saxlayir.
--  Bu sorgu onu, muellimin adini ve HEMIN muellimin plan setirlerini
--  yan-yana qoyur: hansi dersde «test yig» duymesi var, hansinda yox.
--
--  «duyme» sutunu 101_ders_plani_alt.sql-deki can_test mentiqinin
--  eynisidir: ders kecilmelidir VE fesildeki SONUNCU ders olmalidir.
--  «-» olan setirler muellimin bos gordüyü yerlerdir.
--
--  ISTIFADE: Supabase -> SQL Editor -> asagidaki AXTARIS setrini
--  deyis (ad ve ya e-poct parcasi), yapisdir, Run.  Hec ne deyismir.
-- =====================================================================
with axtaris as (select 'Qızbəst'::text as nmn),     -- <<< BURANI DEYIS
rey as (
  select f.created_at, f.kind, f.page, f.body, f.status,
         f.user_id, f.account_id,
         coalesce(u.raw_user_meta_data->>'full_name', u.email) as muellim
    from public.feedback f
    left join auth.users u on u.id = f.user_id
   where f.author_type = 'teacher'
     and (coalesce(u.raw_user_meta_data->>'full_name','') ilike '%' || (select nmn from axtaris) || '%'
          or coalesce(u.email,'') ilike '%' || (select nmn from axtaris) || '%')
),
setir as (
  select c.name as qrup, s.name as fenn, l.code as sinif,
         i.ord, t.name as movzu, par.name as fesil,
         i.done_at is not null as kecilib,
         (i.done_at is not null and (
            par.id is null or not exists (
              select 1 from public.class_plan_items i3
                join public.topics t3 on t3.id = i3.topic_id
               where i3.plan_id = p.id and t3.parent_id = par.id
                 and i3.ord > i.ord))) as duyme,
         l.sort as lsort, p.id as pid
    from public.class_plans p
    join public.classes  c on c.id = p.class_id
    join public.subjects s on s.id = p.subject_id
    join public.levels   l on l.id = p.level_id
    join public.class_plan_items i on i.plan_id = p.id
    join public.topics t on t.id = i.topic_id
    left join public.topics par on par.id = t.parent_id
   where c.account_id in (select account_id from rey)
)
select bolme, a, b, c, d from (
  --  1) REY: ne yazib, HARADAN yazib
  select 1 as sira, 0 as ord2, 'REY' as bolme,
         to_char(r.created_at, 'DD.MM HH24:MI') as a,
         r.muellim as b,
         coalesce(nullif(r.page, ''), '(sehife qeyd olunmayib)') as c,
         left(r.body, 200) as d
    from rey r
  union all
  --  2) PLAN: her ders setri - duyme varmi
  select 2, s.ord, 'PLAN',
         s.fenn || ' ' || s.sinif || ' · ' || s.qrup,
         s.ord || '. ' || s.movzu,
         coalesce(s.fesil, '(fəsilsiz)'),
         case when not s.kecilib then 'keçilməyib'
              when s.duyme      then 'TEST YIĞ var'
              else                   '— BOŞ (müəllim burada heç nə görmür)' end
    from setir s
  union all
  --  3) XULASE
  select 3, 0, 'XULASE',
         count(*)::text || ' ders setri',
         count(*) filter (where kecilib and duyme)::text || ' duymeli',
         count(*) filter (where kecilib and not duyme)::text || ' BOS',
         count(*) filter (where not kecilib)::text || ' hele kecilmeyib'
    from setir
) z
order by sira, ord2;
