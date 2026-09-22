-- =====================================================================
--  hazir_testler.sql : «TAPSIRIQ» EKRANINDA MUELLIM NE GORUR?
--
--  22.09: Qizbest muellim «Bəzi mövzularda testlər yoxdur» yazdi.
--  rey_haradan.sql gosterdi: rəy «Tapşırıq» ekranindan yazilib ve
--  muellimin HEC BIR ders plani yoxdur.  Demeli plan setri ile bagli
--  deyil.
--
--  «Tapsiriq» ekrani sual BANKINI gostermir - hazir TEST siyahisini
--  gosterir.  Axtaris qutusu da yalniz fenn + test ADI + sinif uzre
--  axtarir, MOVZUYA gore yox.  Yani muellim movzu adi yazanda siyahi
--  bos qalir - bankda hemin movzudan 50 sual olsa bele.
--
--  Bu sorgu hemin siyahini oldugu kimi cixarir: hansi fenn/sinifde
--  nece hazir test var ve adlari nedir.
--
--  ISTIFADE: Supabase -> SQL Editor -> yapisdir -> Run.  Hec ne deyismir.
--  Birinci setir xulase, sonra fenn x sinif, sonra ADLAR.
-- =====================================================================
with t as (
  select coalesce(s.name, '(fənn yox)') as fenn,
         coalesce(l.code, '(sinif yox)') as sinif,
         coalesce(l.sort, 0) as lsort,
         te.title, te.created_at
    from public.tests te
    left join public.subjects s on s.id = te.subject_id
    left join public.levels   l on l.id = te.level_id
   where te.owner_type = 'platform'
     and coalesce(te.status, 'published') = 'published'
)
select bolme, fenn, sinif, ad from (
  select 0 as sira, 'XULASE' as bolme,
         count(*)::text || ' hazır test' as fenn,
         count(distinct fenn)::text || ' fənn' as sinif,
         count(distinct fenn || sinif)::text || ' fənn/sinif cütü' as ad,
         0 as lsort, '' as t2
    from t
  union all
  --  fenn x sinif: nece test
  select 1, 'SAY', fenn, sinif, count(*)::text || ' test', min(lsort), ''
    from t group by fenn, sinif
  union all
  --  adlar: muellim siyahida MEHZ bunlari gorur
  select 2, 'AD', fenn, sinif, title, lsort, title
    from t
) z
order by sira, fenn, lsort, t2;
