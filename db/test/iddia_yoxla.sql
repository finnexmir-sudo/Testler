-- =====================================================================
--  iddia_yoxla.sql : SAYTDA YAZILAN REQEMLER BAZA ILE UYUSURMU?
--
--  NIYE LAZIMDIR
--  22.09: «Tapsiriq» ekraninda «test bazasina bu sinif materiallari
--  elave olunmayib» yazilirdi.  24 avqustda DOGRU idi (bank yalniz
--  3-cu sinif idi), sonra bank boyudu, cumle yerinde qaldi ve YALANA
--  cevrildi.  Muellim onu oxuyub «testler yoxdur» deye rəy yazdi.
--
--  Bu, tek hadise deyil - SINIFDIR: koda yazilmis, bazanin veziyyetini
--  iddia eden cumle.  Baza deyisir, cumle deyismir.
--
--  Bu sorgu saytdaki reqemleri bazadan cixarir ki muqayise edilsin.
--  Hazirda index.html iki yerde «12 fənn» yazir.
--
--  ISTIFADE: Supabase -> SQL Editor -> yapisdir -> Run.  Hec ne deyismir.
-- =====================================================================
with sual as (
  select q.id, t.subject_id, t.level_id
    from public.questions q
    join public.topics t on t.id = q.topic_id
   where q.owner_type = 'platform' and q.status = 'published'
)
select olcu, baza, saytda from (
  select 1 as sira, 'Sualı olan FƏNN sayı' as olcu,
         count(distinct subject_id)::text as baza,
         'index.html: «12 fənn»' as saytda
    from sual
  union all
  select 2, 'Sualı olan SİNİF aralığı',
         min(l.code) || '–' || max(l.code),
         'index.html: «1–11-ci siniflər»'
    from sual s join public.levels l on l.id = s.level_id
  union all
  select 3, 'Platforma sual sayı', count(*)::text, '(saytda yazılmır)'
    from sual
  union all
  select 4, 'Hazır PLATFORMA testi', count(*)::text,
         '(«Hazır sual bankı» deyilir — test yox, sual)'
    from public.tests where owner_type = 'platform'
  union all
  --  fenn adlari: «12» hansi 12-dir, qerari insan versin
  select 5, 'Fənn adı', s.name, ''
    from public.subjects s
   where exists (select 1 from sual x where x.subject_id = s.id)
) z
order by sira, olcu, baza;
