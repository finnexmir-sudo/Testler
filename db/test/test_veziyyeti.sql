-- =====================================================================
--  test_veziyyeti.sql : BAZADA HANSI TESTLER VAR VE HANSI VEZIYYETDE?
--
--  22.09: «Tapsiriq» ekraninda hazir test siyahisi BOS cixdi.
--  tests.status ilkin deyeri 'draft'-dir - test bazada olsa da
--  qaralama qalsa siyahiya dusmur.  Bu sorgu SUZGECSIZ sayir:
--  owner_type x status - hansi qutuda nece test var.
--
--  Sonra: platforma testleri fenn/sinif uzre, veziyyeti ile birlikde.
--
--  ISTIFADE: Supabase -> SQL Editor -> yapisdir -> Run.  Hec ne deyismir.
-- =====================================================================
select bolme, a, b, c from (
  --  1) UMUMI: her owner_type x status qutusunda nece test
  select 1 as sira, 'QUTU' as bolme,
         te.owner_type::text as a,
         te.status::text as b,
         count(*)::text || ' test' as c, '' as s2
    from public.tests te
   group by te.owner_type, te.status
  union all
  --  2) PLATFORMA testleri: fenn/sinif ve veziyyet
  select 2, 'PLATFORMA',
         coalesce(s.name, '(fənn yox)') || ' ' || coalesce(l.code, '?'),
         te.status::text,
         count(*)::text || ' test',
         coalesce(s.name, '') || lpad(coalesce(l.sort, 0)::text, 3, '0')
    from public.tests te
    left join public.subjects s on s.id = te.subject_id
    left join public.levels   l on l.id = te.level_id
   where te.owner_type = 'platform'
   group by s.name, l.code, l.sort, te.status
  union all
  --  3) SUAL SAYI: testde sual varmi (bos test siyahida da yararsizdir)
  select 3, 'SUAL',
         case when n = 0 then 'sualsız test' else n::text || ' suallı test' end,
         '', count(*)::text || ' ədəd',
         lpad(n::text, 4, '0')
    from (select te.id, (select count(*) from public.test_questions x
                          where x.test_id = te.id) as n
            from public.tests te where te.owner_type = 'platform') z
   group by n
) y
order by sira, s2, a;
