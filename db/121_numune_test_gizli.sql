-- =====================================================================
--  121  YER TUTUCU TEST GIZLEDILIR
--
--  07_seed_tests.sql-deki 'riy-3-analiz' ("Genislendirilmis analiz testi")
--  ilk qurulusda kilidli testin gorunusunu yoxlamaq ucun qoyulmus yer
--  tutucu idi.  Diaqnostik test (118) onun heqiqi halidir; bu ise sagird
--  siyahisinda menasiz kilidli kart kimi qalirdi ("bu nedir?" - iki defe
--  sorusuldu).  Status 'draft' - siyahidan itir, neticeler silinmir.
--  Yerli testler onu 'published' gozleyir (kilid yoxlamasi) - test
--  bazasi qurulanda run.sh --local bu fayli KECIR.
-- =====================================================================
update public.tests set status = 'draft', title = 'Nümunə — ödənişli test'
 where slug = 'riy-3-analiz' and owner_type = 'platform';
