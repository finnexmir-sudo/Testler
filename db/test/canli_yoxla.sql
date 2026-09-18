-- =====================================================================
--  canli_yoxla.sql : CANLI bazada hansi miqrasiyalar var / yoxdur
--
--  NIYE LAZIMDIR
--  Miqrasiyalar Supabase SQL Editor-a EL ILE yapisdirilir.  Bir fayl
--  atlanirsa hec bir xeta cixmir - sadece hemin imkan islemir ve biz
--  bunu aylar sonra, tesadufen goruruk.  2026-09-18-de mehz bele oldu:
--  210 ve 211 atlanmisdi, sagird «Səhv dəftəri»ndeki 17 sualı isləyə
--  bilmirdi, ekranda ise «Mövzunu seç» yazirdi.
--
--  ISTIFADE:  Supabase -> SQL Editor -> bunu yapisdir -> Run.
--  «var_mi = false» olan HER SETIR isledilmemis fayldir.
--  Yeni miqrasiya yazanda buraya BIR SETIR elave et (barmaq izi:
--  funksiyanin govdesinde YALNIZ hemin faylda olan bir soz, ve ya yeni
--  sutun/cedvel).  Reqem sirasi ile isled: kicikden boyuye.
-- =====================================================================
with f as (
  select p.proname, pg_get_functiondef(p.oid) def
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname in ('public','app')
)
select * from (values
 ('196 məşq həddi 5',
    (select exists (select 1 from f where proname='practice_daily_limit' and def like '%select 5%'))),
 ('197 demo reset where true',
    (select exists (select 1 from f where proname='rpc_demo_reset' and def like '%where true%'))),
 ('198 nümunə «Bizə yaz» yetim',
    (select exists (select 1 from f where proname='feedback_is_demo'))),
 ('200 İcmal həftə',
    (select exists (select 1 from f where proname='rpc_home' and def like '%attempts_w%'))),
 ('201 Diqqət mövzu',
    (select exists (select 1 from f where proname='rpc_home' and def like '%weak_n%'))),
 ('202 Huni',
    (select exists (select 1 from f where proname='rpc_admin_huni'))),
 ('203 anonim hesab',
    (select exists (select 1 from f where proname='rpc_demo_start' and def like '%advisory%'))),
 ('204 mənbə (src)',
    (select exists (select 1 from information_schema.columns
                     where table_schema='public' and table_name='profiles' and column_name='src'))),
 ('205 şagird siyahısı',
    (select exists (select 1 from f where proname='rpc_class_students'))),
 ('206 indi saytda',
    (select exists (select 1 from f where proname='rpc_seen' and def like '%2 minutes%'))),
 ('207 keyfiyyət köhnə sətir',
    (select exists (select 1 from f where proname='qstat_refresh' and def like '%qs_new%'))),
 ('208 cavab şagirdə',
    (select exists (select 1 from information_schema.columns
                     where table_schema='public' and table_name='feedback' and column_name='reply_seen_at'))),
 ('209 «Bu gün» kartı',
    (select exists (select 1 from f where proname='rpc_quick_assign'))),
 ('210 səhvini bağla',
    (select exists (select 1 from f where proname='rpc_student_mistakes' and def like '%topics%'))),
 ('211 səhv abunə',
    (select exists (select 1 from f where proname='rpc_student_mistakes' and def like '%has_active_subscription%'))),
 ('212 gündəlik 5 sual',
    (select to_regclass('public.daily_packs') is not null)),
 ('213 təkrar itələməsi',
    (select exists (select 1 from f where proname='rpc_home' and def like '%tekrar_plansiz%'))),
 ('215 girən müəllim sayğacı',
    (select exists (select 1 from f where proname='rpc_admin_stats' and def like '%215b: IKI MENBE MOTERIZEDE%')))
) as t(miqrasiya, var_mi)
order by var_mi, miqrasiya;
