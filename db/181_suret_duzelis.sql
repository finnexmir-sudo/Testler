-- =====================================================================
--  181_suret_duzelis.sql - kirli olculeri silir
--
--  NIYE
--  db/180 canliya cixan gun ilk iki olcu 11,5 saniye ve 16 saniye
--  yazdi.  Sayt yavas deyildi: telefonda ILK giris idi, istifadeci
--  giris formasinda e-poct ve parol YAZIRDI, olcu ise sehife
--  acilan andan sayirdi.  Insanin yazma sureti olcuye qarisdi.
--
--  Kod duzeldildi (muellim/app.js): giris ekrani gorunende olcu
--  sondurulur, giris ugurlu olandan sonra yeniden baslayir; arxa
--  fonda qalmis sehifenin olcusu de atilir.
--
--  Bu fayl KOHNE, KIRLI setirleri silir.  Saxlasaydiq, ortalama
--  aylarla sisik qalardi ve kart yalan danisardi - olcu aletinin
--  yalan danismasi olcmemekden pisdir.
-- =====================================================================

delete from public.perf_days where day <= '2026-09-11'::date;
