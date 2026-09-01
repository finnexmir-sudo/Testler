-- =====================================================================
--  86_alt_movzular_fizika6_11.sql : FIZIKA 6-11 - ALT MOVZULAR
--
--  NIYE
--  Dorduncu fenn.  Riyaziyyat, heyat bilgisi ve informatika hazirdir.
--  Fizika 6-cı sinifden baslayir (1-5-de yoxdur).
--
--  MENBE: e-derslik.edu.az "Movzular" agaci - kitab id 546 (6),
--  867/868 (7), 931/932 (8), 472 (9), 734 (10), 282 (11).  Adlar
--  EYNILE goturulub.
--
--  DERSLIYIN QURULUSU BIZIMKINDEN FERQLIDIR - HER SINIFDE AYRI SEBEB:
--
--  6-cı sinif: derslikde 4 bolme, bazada 6 movzu - iki bolme
--  SEHIFEYE GORE ikiye bolunur ("1 FIZIKA NEYI OYRENIR?" ->
--  fiz-6-giris + fiz-6-olcmeler, sehife 22-den; "4 QARSILIQLI
--  TESIRLER VE HEREKET" -> fiz-6-hereket + fiz-6-enerji, sehife 83-den).
--
--  7-ci sinif: kitab 867-nin "Giris" bolmesi (3 hemin dersin adi ile -
--  "Fizikler tebiet haqqinda ne bilirler?" ve s.) NOMRESIZ ve derslikde
--  ayri "==" bolme kimi gorunur, amma bazada ayri movzusu yoxdur -
--  ilk movzuya (fiz-7-olcme) elave edilib.  Daha ciddi tele: kitabin
--  öz mundericat sehifesinde "Bolme 4. Atomun qurulusu ve olcusu"
--  basligi mundericat SCRAPER-inde "==" kimi DEYIL, adi bir sətir
--  kimi "Bolme 3. Eyrixetli hereket"in daxilinde gorunur (portal
--  qusuru).  Bu setir ozu XARIC edilib (movzu deyil, basliqdir),
--  sehife 76-dan sonrasi fiz-7-atom-a gedir.
--
--  9-cu sinif: 4 fesil, bazada 6 movzu.  Fesil 3 (ISIQ HADISELERI)
--  ISIQ ve GUZGU-LINZA arasinda İKİ DEFE novbelesir (dersler movzu
--  uzre deyil, dersliyin oz ardicilligi ilə düzülüb): yayilma+qayitma
--  (isiq) -> guzgu (guzgu-linza) -> sinma+tam-daxili-qayitma (isiq) ->
--  linza+goz (guzgu-linza).  Sehife serhedleri: 123, 133, 145.
--  Fesil 4 (ATOM VE ATOM NUVESI) bir sehifede (193) radioaktivlik/
--  nuve arasinda bolunur.
--
--  10-cu sinif: derslikde 7 fesil, bazada 6 movzu - V fesil
--  (RELYATIVISTIK MEXANIKA, cemi 2 ders: nisbilik nezeriyyesi ve
--  enerji-kutle elaqesi) III fesle (SAXLANMA QANUNLARI) birlesir -
--  hər ikisi enerjinin saxlanmasi movzusudur.
--
--  11-ci sinif: 4 fesil, bazada 6 movzu.  I fesil (ELEKTROMAQNIT
--  SAHESI) sehife 31-den ELEKTROSTATIKA/MAQNIT-INDUKSIYA arasinda,
--  III fesil (ELEKTROMAQNIT REQSLERI VE DALGALARI) sehife 128-den
--  REQS/OPTIKA arasinda bolunur.
--
--  "•" ILE BASLAYAN BENDLER (6-cı sinif: "• Ümumiləşdirici
--  tapşırıqlar"): dusterin ozu, movzu adinin hissesi deyil - silinir.
--
--  BURAXILAN BOLMELER: yoxdur - hamisi hardasa bir movzuya baglanir.
--  Arxa hisse (Sozluk/Terminler lugeti/fesil cavab acari/Elaveler)
--  xaric edilir.
--
--  ELLE YAZILMIR: tools/alt_movzular.py cixarir.  Duzelis skriptde
--  edilir, sonra SQL yeniden yaradilir.
--
--  XARIC EDILEN BENDLER: kitabin sonundaki aparat - "Sozluk",
--  "Cavablar", "Ozunuzu yoxlayin", "Mesele hellline numune",
--  "yarimil / sinif uzre umumilesdirici tapsiriqlar".  Bolmenin
--  dersi deyil.  db/74 de eyni qaydani tutub.
--
--  DIQQET
--   * questions cedveline TOXUNULMUR - suallar alt movzulara
--     baglanmir, teqler deyismir.  O, ayri merhelendir.
--   * Movcud ust movzu setirleri deyismir - yalniz parent kimi
--     islenir.  programs/levels-e de toxunulmur.
--   * Tekrar isledile biler (on conflict do update).
--   * db/102 movzu silmeyi bloklayir - bu fayl hec ne silmir.
-- =====================================================================
set search_path = public, extensions;

--  AD DUZELISLERI (mezmun deyismeyib):
--   * yazi (1): yazi qusuru (bosluq, herf)
--       8-ci   s.30   1.7 Elastiklik quvvesi.
--                    -> Elastiklik quvvesi

insert into public.topics (subject_id, level_id, parent_id, slug, name, sort)
select p.subject_id, p.level_id, p.id, v.slug, v.name, v.sort
  from (values
    --  ============  6-ci sinif  ============
    --  1 FIZIKA NEYI OYRENIR?  (fiz-6-giris)
    ('fiz-6-giris', 'fiz-6-giris-hansi-hadiseleri',
     'Fizika hansı hadisələri öyrənir?', 10),
    ('fiz-6-giris', 'fiz-6-giris-tebiet-hadiselerini',
     'Fizika təbiət hadisələrini nə üçün öyrənir?', 20),
    ('fiz-6-giris', 'fiz-6-giris-fizikada-oyrenme',
     'Fizikada öyrənmə metodları', 30),
    --  1 FIZIKA NEYI OYRENIR?  (fiz-6-olcmeler)
    ('fiz-6-olcmeler', 'fiz-6-olcmeler-fiziki-kemiyyetler',
     'Fiziki kəmiyyətlər və onların ölçülməsi', 10),
    ('fiz-6-olcmeler', 'fiz-6-olcmeler-olcu-cihazlari',
     'Ölçü cihazları', 20),
    ('fiz-6-olcmeler', 'fiz-6-olcmeler-deqiqlik',
     'Ölçmələrdə dəqiqlik', 30),
    ('fiz-6-olcmeler', 'fiz-6-olcmeler-umumi',
     'Ümumiləşdirici tapşırıqlar', 40),
    --  2 MATERIYA  (fiz-6-materiya)
    ('fiz-6-materiya', 'fiz-6-materiya-fiziki-sahe',
     'Materiya: maddə və fiziki sahə', 10),
    ('fiz-6-materiya', 'fiz-6-materiya-madde-cisim',
     'Maddə və cisim', 20),
    ('fiz-6-materiya', 'fiz-6-materiya-elaqeli-sistemler',
     'Əlaqəli sistemlər. Atom. Atom nüvəsi', 30),
    ('fiz-6-materiya', 'fiz-6-materiya-molekul',
     'Molekul', 40),
    ('fiz-6-materiya', 'fiz-6-materiya-maddenin-aqreqat',
     'Maddənin aqreqat halları', 50),
    ('fiz-6-materiya', 'fiz-6-materiya-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    --  3 MADDE VE ONUN XASSELERI  (fiz-6-madde)
    ('fiz-6-madde', 'fiz-6-madde-diffuziya',
     'Diffuziya', 10),
    ('fiz-6-madde', 'fiz-6-madde-istiden-genislenmesi',
     'Maddələrin istidən genişlənməsi', 20),
    ('fiz-6-madde', 'fiz-6-madde-olcule-bilen',
     'Maddənin ölçülə bilən xassələri: həcm və onun ölçülməsi', 30),
    ('fiz-6-madde', 'fiz-6-madde-kutle-olculmesi',
     'Kütlə və onun ölçülməsi', 40),
    ('fiz-6-madde', 'fiz-6-madde-sixligi-teyin',
     'Maddənin sıxlığı və onun təyin edilməsi', 50),
    ('fiz-6-madde', 'fiz-6-madde-temperatur-olculmesi',
     'Temperatur və onun ölçülməsi', 60),
    ('fiz-6-madde', 'fiz-6-madde-meseleler',
     'Məsələlər', 70),
    ('fiz-6-madde', 'fiz-6-madde-umumi',
     'Ümumiləşdirici tapşırıqlar', 80),
    --  4 QARSILIQLI TESIRLER VE HEREKET  (fiz-6-hereket)
    ('fiz-6-hereket', 'fiz-6-hereket-toxunma-bas',
     'Toxunma ilə baş verən təsirlər', 10),
    ('fiz-6-hereket', 'fiz-6-hereket-qravitasiya-gunes',
     'Qravitasiya qarşılıqlı təsiri - Günəş sistemi', 20),
    ('fiz-6-hereket', 'fiz-6-hereket-elektrik-tesiri',
     'Elektrik qarşılıqlı təsiri', 30),
    ('fiz-6-hereket', 'fiz-6-hereket-maqnit-tesiri',
     'Maqnit qarşılıqlı təsiri', 40),
    --  4 QARSILIQLI TESIRLER VE HEREKET  (fiz-6-enerji)
    ('fiz-6-enerji', 'fiz-6-enerji-mexaniki-hereket',
     'Mexaniki hərəkət', 10),
    ('fiz-6-enerji', 'fiz-6-enerji-elektrik-yuklerinin',
     'Elektrik yüklərinin hərəkəti: elektrik cərəyanı', 20),
    ('fiz-6-enerji', 'fiz-6-enerji-enerji',
     'Enerji', 30),
    ('fiz-6-enerji', 'fiz-6-enerji-umumi',
     'Ümumiləşdirici tapşırıqlar', 40),
    --  ============  7-ci sinif  ============
    --  Giris. Fizika neyi oyrenir?  (fiz-7-olcme)
    ('fiz-7-olcme', 'fiz-7-olcme-tebiet-haqqinda',
     'Fiziklər təbiət haqqında nə bilirlər?', 10),
    ('fiz-7-olcme', 'fiz-7-olcme-tebieti-nece',
     'Fiziklər təbiəti necə öyrənirlər?', 20),
    ('fiz-7-olcme', 'fiz-7-olcme-fizikanin-ehemiyyeti',
     'Fizikanın əhəmiyyəti', 30),
    --  Bolme 1. Fiziki kemiyyetler ve onlarin olculmesi  (fiz-7-olcme)
    ('fiz-7-olcme', 'fiz-7-olcme-fiziki-kemiyyetler',
     'Fiziki kəmiyyətlər', 40),
    ('fiz-7-olcme', 'fiz-7-olcme-kemiyyetlerin-olculmesi',
     'Fiziki kəmiyyətlərin ölçülməsi', 50),
    ('fiz-7-olcme', 'fiz-7-olcme-deqiqlik',
     'Ölçmədə dəqiqlik', 60),
    ('fiz-7-olcme', 'fiz-7-olcme-skalyar-vektorial',
     'Skalyar və vektorial kəmiyyətlər', 70),
    ('fiz-7-olcme', 'fiz-7-olcme-elm-texnologiya',
     'Elm, texnologiya, həyat', 80),
    ('fiz-7-olcme', 'fiz-7-olcme-xulase',
     'Xülasə', 90),
    ('fiz-7-olcme', 'fiz-7-olcme-umumi',
     'Ümumiləşdirici tapşırıqlar', 100),
    --  Bolme 2. Duzxetli hereket  (fiz-7-duzxetli)
    ('fiz-7-duzxetli', 'fiz-7-duzxetli-trayektoriya-yol',
     'Trayektoriya, yol və yerdəyişmə', 10),
    ('fiz-7-duzxetli', 'fiz-7-duzxetli-suret',
     'Sürət', 20),
    ('fiz-7-duzxetli', 'fiz-7-duzxetli-berabersuretli-hereket',
     'Düzxətli bərabərsürətli hərəkət', 30),
    ('fiz-7-duzxetli', 'fiz-7-duzxetli-yolun-yola',
     'Yolun və yola görə sürətin qrafik təsviri', 40),
    ('fiz-7-duzxetli', 'fiz-7-duzxetli-deyisensuretli-hereket',
     'Düzxətli dəyişənsürətli hərəkət', 50),
    ('fiz-7-duzxetli', 'fiz-7-duzxetli-tecil',
     'Təcil', 60),
    ('fiz-7-duzxetli', 'fiz-7-duzxetli-orta-suret',
     'Orta sürət', 70),
    ('fiz-7-duzxetli', 'fiz-7-duzxetli-elm-texnologiya',
     'Elm, texnologiya, həyat', 80),
    ('fiz-7-duzxetli', 'fiz-7-duzxetli-xulase',
     'Xülasə', 90),
    ('fiz-7-duzxetli', 'fiz-7-duzxetli-umumi',
     'Ümumiləşdirici tapşırıqlar', 100),
    --  Bolme 3. Eyrixetli hereket  (fiz-7-eyrixetli)
    ('fiz-7-eyrixetli', 'fiz-7-eyrixetli-cevre-hereket',
     'Çevrə üzrə bərabərsürətli hərəkət', 10),
    ('fiz-7-eyrixetli', 'fiz-7-eyrixetli-hereketde-suret',
     'Çevrə üzrə bərabərsürətli hərəkətdə sürət', 20),
    ('fiz-7-eyrixetli', 'fiz-7-eyrixetli-periodik-reqsi',
     'Periodik rəqsi hərəkət', 30),
    ('fiz-7-eyrixetli', 'fiz-7-eyrixetli-elm-texnologiya',
     'Elm, texnologiya, həyat', 40),
    ('fiz-7-eyrixetli', 'fiz-7-eyrixetli-xulase',
     'Xülasə', 50),
    ('fiz-7-eyrixetli', 'fiz-7-eyrixetli-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    --  Bolme 3. Eyrixetli hereket  (fiz-7-atom)
    ('fiz-7-atom', 'fiz-7-atom-qurulusu',
     'Atomun quruluşu', 10),
    ('fiz-7-atom', 'fiz-7-atom-olcusu',
     'Atomun ölçüsü', 20),
    ('fiz-7-atom', 'fiz-7-atom-elm-texnologiya',
     'Elm, texnologiya, həyat', 30),
    ('fiz-7-atom', 'fiz-7-atom-xulase',
     'Xülasə', 40),
    ('fiz-7-atom', 'fiz-7-atom-umumi',
     'Ümumiləşdirici tapşırıqlar', 50),
    --  Bolme 5. Elektrik yuku ve elektrik sahesi  (fiz-7-elektrik-sahe)
    ('fiz-7-elektrik-sahe', 'fiz-7-elektrik-sahe-cisimlerin-yuku',
     'Cisimlərin elektrik yükü', 10),
    ('fiz-7-elektrik-sahe', 'fiz-7-elektrik-sahe-surtunme',
     'Sürtünmə ilə elektriklənmə', 20),
    ('fiz-7-elektrik-sahe', 'fiz-7-elektrik-sahe-elektroskop',
     'Elektroskop', 30),
    ('fiz-7-elektrik-sahe', 'fiz-7-elektrik-sahe-keciriciler-dielektrikler',
     'Keçiricilər və dielektriklər', 40),
    ('fiz-7-elektrik-sahe', 'fiz-7-elektrik-sahe-elektrik-sahesi',
     'Elektrik sahəsi', 50),
    ('fiz-7-elektrik-sahe', 'fiz-7-elektrik-sahe-induksiya',
     'İnduksiya ilə elektriklənmə', 60),
    ('fiz-7-elektrik-sahe', 'fiz-7-elektrik-sahe-elm-texnologiya',
     'Elm, texnologiya, həyat', 70),
    ('fiz-7-elektrik-sahe', 'fiz-7-elektrik-sahe-xulase',
     'Xülasə', 80),
    ('fiz-7-elektrik-sahe', 'fiz-7-elektrik-sahe-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    --  Bolme 6. Elektrik dovresi ve dovre elementleri  (fiz-7-dovre)
    ('fiz-7-dovre', 'fiz-7-dovre-elektrik-elementleri',
     'Elektrik dövrəsi və dövrə elementləri', 10),
    ('fiz-7-dovre', 'fiz-7-dovre-elektrik-cereyani',
     'Elektrik cərəyanı', 20),
    ('fiz-7-dovre', 'fiz-7-dovre-gerginlik',
     'Gərginlik', 30),
    ('fiz-7-dovre', 'fiz-7-dovre-qanunu',
     'Om qanunu', 40),
    ('fiz-7-dovre', 'fiz-7-dovre-naqilin-muqavimeti',
     'Naqilin müqaviməti nədən asılıdır?', 50),
    ('fiz-7-dovre', 'fiz-7-dovre-lampalarin-ardicil',
     'Lampaların ardıcıl və paralel birləşdirilməsi', 60),
    ('fiz-7-dovre', 'fiz-7-dovre-elm-texnologiya',
     'Elm, texnologiya, həyat', 70),
    ('fiz-7-dovre', 'fiz-7-dovre-xulase',
     'Xülasə', 80),
    ('fiz-7-dovre', 'fiz-7-dovre-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    --  Bolme 7. Sabit maqnit ve maqnit sahesi  (fiz-7-maqnit)
    ('fiz-7-maqnit', 'fiz-7-maqnit-sabit',
     'Sabit maqnit', 10),
    ('fiz-7-maqnit', 'fiz-7-maqnit-sahesi',
     'Maqnit sahəsi', 20),
    ('fiz-7-maqnit', 'fiz-7-maqnit-elm-texnologiya',
     'Elm, texnologiya, həyat', 30),
    ('fiz-7-maqnit', 'fiz-7-maqnit-xulase',
     'Xülasə', 40),
    ('fiz-7-maqnit', 'fiz-7-maqnit-umumi',
     'Ümumiləşdirici tapşırıqlar', 50),
    --  ============  8-ci sinif  ============
    --  Bolme 1 Quvve  (fiz-8-quvve)
    ('fiz-8-quvve', 'fiz-8-quvve-novleri',
     'Qüvvə və onun növləri', 10),
    ('fiz-8-quvve', 'fiz-8-quvve-evezleyici',
     'Əvəzləyici qüvvə', 20),
    ('fiz-8-quvve', 'fiz-8-quvve-birinci-qanunu',
     'Nyutonun birinci qanunu', 30),
    ('fiz-8-quvve', 'fiz-8-quvve-ikinci-qanunu',
     'Nyutonun ikinci qanunu', 40),
    ('fiz-8-quvve', 'fiz-8-quvve-agirliq-ceki',
     'Ağırlıq qüvvəsi və çəki', 50),
    ('fiz-8-quvve', 'fiz-8-quvve-ucuncu-qanunu',
     'Nyutonun üçüncü qanunu', 60),
    ('fiz-8-quvve', 'fiz-8-quvve-elastiklik',
     'Elastiklik qüvvəsi', 70),
    ('fiz-8-quvve', 'fiz-8-quvve-surtunme',
     'Sürtünmə qüvvəsi', 80),
    ('fiz-8-quvve', 'fiz-8-quvve-momenti',
     'Qüvvə momenti', 90),
    ('fiz-8-quvve', 'fiz-8-quvve-merkezi-tarazliq',
     'Ağırlıq mərkəzi və tarazlıq', 100),
    ('fiz-8-quvve', 'fiz-8-quvve-elm-texnologiya',
     'Elm, texnologiya, həyat', 110),
    ('fiz-8-quvve', 'fiz-8-quvve-xulase',
     'Xülasə', 120),
    ('fiz-8-quvve', 'fiz-8-quvve-umumi',
     'Ümumiləşdirici tapşırıqlar', 130),
    --  Bolme 2 Is ve enerji  (fiz-8-is-enerji)
    ('fiz-8-is-enerji', 'fiz-8-is-enerji-mexaniki',
     'Mexaniki iş', 10),
    ('fiz-8-is-enerji', 'fiz-8-is-enerji-guc',
     'Güc', 20),
    ('fiz-8-is-enerji', 'fiz-8-is-enerji-potensial-kinetik',
     'Potensial və kinetik enerji', 30),
    ('fiz-8-is-enerji', 'fiz-8-is-enerji-neden-asilidir',
     'Potensial və kinetik enerji nədən asılıdır?', 40),
    ('fiz-8-is-enerji', 'fiz-8-is-enerji-tam-mexaniki',
     'Tam mexaniki enerji', 50),
    ('fiz-8-is-enerji', 'fiz-8-is-enerji-elm-texnologiya',
     'Elm, texnologiya, həyat', 60),
    ('fiz-8-is-enerji', 'fiz-8-is-enerji-xulase',
     'Xülasə', 70),
    ('fiz-8-is-enerji', 'fiz-8-is-enerji-umumi',
     'Ümumiləşdirici tapşırıqlar', 80),
    --  Bolme 3 Tezyiq  (fiz-8-tezyiq)
    ('fiz-8-tezyiq', 'fiz-8-tezyiq-berk-cisimlerin',
     'Bərk cisimlərin təzyiqi', 10),
    ('fiz-8-tezyiq', 'fiz-8-tezyiq-maye-qazlarin',
     'Maye və qazların təzyiqi', 20),
    ('fiz-8-tezyiq', 'fiz-8-tezyiq-arximed-quvvesi',
     'Arximed qüvvəsi', 30),
    ('fiz-8-tezyiq', 'fiz-8-tezyiq-elm-texnologiya',
     'Elm, texnologiya, həyat', 40),
    ('fiz-8-tezyiq', 'fiz-8-tezyiq-xulase',
     'Xülasə', 50),
    ('fiz-8-tezyiq', 'fiz-8-tezyiq-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    --  Bolme 4 Dalgalar  (fiz-8-dalgalar)
    ('fiz-8-dalgalar', 'fiz-8-dalgalar-mexaniki-onlarin',
     'Mexaniki dalğalar və onların növləri', 10),
    ('fiz-8-dalgalar', 'fiz-8-dalgalar-dalgani-xarakterize',
     'Dalğanı xarakterizə edən fiziki kəmiyyətlər', 20),
    ('fiz-8-dalgalar', 'fiz-8-dalgalar-ses-dalgasi',
     'Səs dalğası', 30),
    ('fiz-8-dalgalar', 'fiz-8-dalgalar-sesin-xarakteristika',
     'Səsin xarakteristikaları', 40),
    ('fiz-8-dalgalar', 'fiz-8-dalgalar-xasseleri',
     'Dalğaların xassələri', 50),
    ('fiz-8-dalgalar', 'fiz-8-dalgalar-elektromaqnit-skalasi',
     'Elektromaqnit dalğaları. Elektromaqnit dalğaları şkalası', 60),
    ('fiz-8-dalgalar', 'fiz-8-dalgalar-elm-texnologiya',
     'Elm, texnologiya, həyat', 70),
    ('fiz-8-dalgalar', 'fiz-8-dalgalar-xulase',
     'Xülasə', 80),
    ('fiz-8-dalgalar', 'fiz-8-dalgalar-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    --  Bolme 5 Molekullarin istilik hereketi. Daxili enerji  (fiz-8-istilik)
    ('fiz-8-istilik', 'fiz-8-istilik-molekullarin-hereketi',
     'Molekulların istilik hərəkəti. Temperatur', 10),
    ('fiz-8-istilik', 'fiz-8-istilik-cisimlerin-istiden',
     'Cisimlərin istidən genişlənməsi', 20),
    ('fiz-8-istilik', 'fiz-8-istilik-tarazligi-skalalari',
     'İstilik tarazlığı. Temperatur şkalaları', 30),
    ('fiz-8-istilik', 'fiz-8-istilik-daxili-enerji',
     'Daxili enerji. Daxili enerjinin dəyişmə üsulları', 40),
    ('fiz-8-istilik', 'fiz-8-istilik-novleri-konveksiya',
     'İstilikvermənin növləri: istilikkeçirmə, konveksiya və şüalanma', 50),
    ('fiz-8-istilik', 'fiz-8-istilik-elm-texnologiya',
     'Elm, texnologiya, həyat', 60),
    ('fiz-8-istilik', 'fiz-8-istilik-xulase',
     'Xülasə', 70),
    ('fiz-8-istilik', 'fiz-8-istilik-umumi',
     'Ümumiləşdirici tapşırıqlar', 80),
    --  Bolme 6 Istilik hadiselerinde enerjinin saxlanmasi qanunu  (fiz-8-istilik-qanun)
    ('fiz-8-istilik-qanun', 'fiz-8-istilik-qanun-miqdari-tutumu',
     'İstilik miqdarı. Xüsusi istilik tutumu', 10),
    ('fiz-8-istilik-qanun', 'fiz-8-istilik-qanun-enerjinin-saxlanmasi',
     'İstilik proseslərində enerjinin saxlanması qanunu', 20),
    ('fiz-8-istilik-qanun', 'fiz-8-istilik-qanun-berk-cismin',
     'Bərk cismin xüsusi istilik tutumunun təyini (praktik iş)', 30),
    ('fiz-8-istilik-qanun', 'fiz-8-istilik-qanun-erime-berkime',
     'Maddənin aqreqat halının dəyişməsi: ərimə və bərkimə', 40),
    ('fiz-8-istilik-qanun', 'fiz-8-istilik-qanun-buxarlanma-kondensasiya',
     'Maddənin aqreqat halının dəyişməsi: buxarlanma və kondensasiya', 50),
    ('fiz-8-istilik-qanun', 'fiz-8-istilik-qanun-hallarinin-deyisme',
     'Maddənin aqreqat hallarının dəyişmə proseslərində tələb olunan istilik miqdarı', 60),
    ('fiz-8-istilik-qanun', 'fiz-8-istilik-qanun-muherrikinin-faydali',
     'İstilik mühərriki. İstilik mühərrikinin faydalı iş əmsalı', 70),
    ('fiz-8-istilik-qanun', 'fiz-8-istilik-qanun-buxar-muherriki',
     'Buxar mühərriki', 80),
    ('fiz-8-istilik-qanun', 'fiz-8-istilik-qanun-daxiliyanma-muherriki',
     'Daxiliyanma mühərriki', 90),
    ('fiz-8-istilik-qanun', 'fiz-8-istilik-qanun-reaktiv-muherrik',
     'Reaktiv mühərrik', 100),
    ('fiz-8-istilik-qanun', 'fiz-8-istilik-qanun-muherrikleri-ekoloji',
     'İstilik mühərrikləri və ekoloji problemlər', 110),
    ('fiz-8-istilik-qanun', 'fiz-8-istilik-qanun-elm-texnologiya',
     'Elm, texnologiya, həyat', 120),
    ('fiz-8-istilik-qanun', 'fiz-8-istilik-qanun-xulase',
     'Xülasə', 130),
    ('fiz-8-istilik-qanun', 'fiz-8-istilik-qanun-umumi',
     'Ümumiləşdirici tapşırıqlar', 140),
    --  ============  9-cu sinif  ============
    --  Fesil 1. MUXTELIF MUHITLERDE ELEKTRIK CEREYANI  (fiz-9-cereyan-muhit)
    ('fiz-9-cereyan-muhit', 'fiz-9-cereyan-muhit-keciriciliyini-klassik',
     'Metalların elektrik keçiriciliyinin klassik elektron nəzəriyyəsi', 10),
    ('fiz-9-cereyan-muhit', 'fiz-9-cereyan-muhit-muqavimetinin-temperaturdan',
     'Metalların müqavimətinin temperaturdan asılılığı', 20),
    ('fiz-9-cereyan-muhit', 'fiz-9-cereyan-muhit-calisma-1',
     'Çalışma – 1.1.', 30),
    ('fiz-9-cereyan-muhit', 'fiz-9-cereyan-muhit-elektrolitlerd-elektrik',
     'Elektrolitlərdə elektrik cərəyanı', 40),
    ('fiz-9-cereyan-muhit', 'fiz-9-cereyan-muhit-calisma-2',
     'Çalışma – 1.2.', 50),
    ('fiz-9-cereyan-muhit', 'fiz-9-cereyan-muhit-praktik-elektroliz',
     'Praktik iş – 1. Elektroliz hadisəsinin araşdırılması', 60),
    ('fiz-9-cereyan-muhit', 'fiz-9-cereyan-muhit-vakuumda-elektrik',
     'Vakuumda elektrik cərəyanı', 70),
    ('fiz-9-cereyan-muhit', 'fiz-9-cereyan-muhit-calisma-3',
     'Çalışma – 1.3.', 80),
    ('fiz-9-cereyan-muhit', 'fiz-9-cereyan-muhit-qazlarda-qeyri',
     'Qazlarda elektrik cərəyanı. Qeyri-müstəqil boşalma', 90),
    ('fiz-9-cereyan-muhit', 'fiz-9-cereyan-muhit-qaz-bosalmasi',
     'Müstəqil qaz boşalması və onun növləri', 100),
    ('fiz-9-cereyan-muhit', 'fiz-9-cereyan-muhit-calisma-4',
     'Çalışma – 1.4.', 110),
    ('fiz-9-cereyan-muhit', 'fiz-9-cereyan-muhit-mexsusi-keciriciliyi',
     'Yarımkeçiricilər. Yarımkeçiricilərin məxsusi elektrik keçiriciliyi', 120),
    ('fiz-9-cereyan-muhit', 'fiz-9-cereyan-muhit-asqar-keciriciliyi',
     'Yarımkeçiricilərin aşqar keçiriciliyi', 130),
    ('fiz-9-cereyan-muhit', 'fiz-9-cereyan-muhit-kecidi-diod',
     'p-n keçidi. Yarımkeçirici diod (əlavə oxu materialı)', 140),
    ('fiz-9-cereyan-muhit', 'fiz-9-cereyan-muhit-yarimkecirici-cihazlar',
     'Yarımkeçirici cihazlar', 150),
    ('fiz-9-cereyan-muhit', 'fiz-9-cereyan-muhit-calisma-5',
     'Çalışma-1.5.', 160),
    ('fiz-9-cereyan-muhit', 'fiz-9-cereyan-muhit-muxtelif-ders',
     'Müxtəlif mühitlərdə elektrik cərəyanı (dərs-təqdimat)', 170),
    ('fiz-9-cereyan-muhit', 'fiz-9-cereyan-muhit-umumi',
     'Ümumiləşdirici tapşırıqlar', 180),
    --  Fesil 2. MAQNIT SAHESI  (fiz-9-maqnit-sahe)
    ('fiz-9-maqnit-sahe', 'fiz-9-maqnit-sahe-hadiseleri-sabit',
     'Maqnit hadisələri. Sabit maqnitlər', 10),
    ('fiz-9-maqnit-sahe', 'fiz-9-maqnit-sahe-menseyi',
     'Maqnit sahəsi. Maqnit sahəsinin mənşəyi', 20),
    ('fiz-9-maqnit-sahe', 'fiz-9-maqnit-sahe-calisma-1',
     'Çalışma – 2.1', 30),
    ('fiz-9-maqnit-sahe', 'fiz-9-maqnit-sahe-induksiyasi',
     'Maqnit sahəsinin induksiyası', 40),
    ('fiz-9-maqnit-sahe', 'fiz-9-maqnit-sahe-yerin',
     'Yerin maqnit sahəsi', 50),
    ('fiz-9-maqnit-sahe', 'fiz-9-maqnit-sahe-naqilin-induksiyasi',
     'Cərəyanlı düz naqilin maqnit induksiyası', 60),
    ('fiz-9-maqnit-sahe', 'fiz-9-maqnit-sahe-calisma-2',
     'Çalışma – 2.2.', 70),
    ('fiz-9-maqnit-sahe', 'fiz-9-maqnit-sahe-dairevi-cereyanin',
     'Dairəvi cərəyanın və cərəyanlı sarğacın maqnit sahəsi', 80),
    ('fiz-9-maqnit-sahe', 'fiz-9-maqnit-sahe-elektromaqnit-tetbiqleri',
     'Elektromaqnit və onun tətbiqləri', 90),
    ('fiz-9-maqnit-sahe', 'fiz-9-maqnit-sahe-calisma-3',
     'Çalışma – 2.3.', 100),
    ('fiz-9-maqnit-sahe', 'fiz-9-maqnit-sahe-cereyanlarin-qarsiliqli',
     'Cərəyanların maqnit qarşılıqlı təsiri', 110),
    ('fiz-9-maqnit-sahe', 'fiz-9-maqnit-sahe-naqile-induksiyasinin',
     'Maqnit sahəsinin cərəyanlı düz naqilə təsiri. Maqnit induksiyasının modulu', 120),
    ('fiz-9-maqnit-sahe', 'fiz-9-maqnit-sahe-calisma-4',
     'Çalışma – 2.4.', 130),
    ('fiz-9-maqnit-sahe', 'fiz-9-maqnit-sahe-cerciveye-tesiri',
     'Maqnit sahəsinin cərəyanlı çərçivəyə təsiri', 140),
    ('fiz-9-maqnit-sahe', 'fiz-9-maqnit-sahe-amper-quvvesinin',
     'Amper qüvvəsinin tətbiqləri: elektrik mühərriki və elektrik ölçü cihazları', 150),
    ('fiz-9-maqnit-sahe', 'fiz-9-maqnit-sahe-calisma-5',
     'Çalışma – 2.5.', 160),
    ('fiz-9-maqnit-sahe', 'fiz-9-maqnit-sahe-hereketde-yuklu',
     'Maqnit sahəsinin hərəkətdə olan yüklü zərrəciklərə təsiri. Lorens qüvvəsi', 170),
    ('fiz-9-maqnit-sahe', 'fiz-9-maqnit-sahe-calisma-6',
     'Çalışma – 2.6.', 180),
    ('fiz-9-maqnit-sahe', 'fiz-9-maqnit-sahe-elektromaqnit-hadisesi',
     'Elektromaqnit induksiya hadisəsi', 190),
    ('fiz-9-maqnit-sahe', 'fiz-9-maqnit-sahe-cereyaninin-istiqameti',
     'İnduksiya cərəyanının istiqaməti', 200),
    ('fiz-9-maqnit-sahe', 'fiz-9-maqnit-sahe-praktik-hadisesinin',
     'Praktik iş – 2. Elektromaqnit induksiya hadisəsinin öyrənilməsi', 210),
    ('fiz-9-maqnit-sahe', 'fiz-9-maqnit-sahe-calisma-7',
     'Çalışma – 2.7.', 220),
    ('fiz-9-maqnit-sahe', 'fiz-9-maqnit-sahe-maddenin-nufuzlugu',
     'Maddənin maqnit nüfuzluğu', 230),
    ('fiz-9-maqnit-sahe', 'fiz-9-maqnit-sahe-muqayisesi-teqdimat',
     'Qravitasiya, elektrik və maqnit sahələrinin müqayisəsi (dərs-təqdimat)', 240),
    ('fiz-9-maqnit-sahe', 'fiz-9-maqnit-sahe-biz-hansi',
     'Biz Yerin qravitasiya, elektrik və maqnit sahəsinin hansı təsiri altındayıq? (dərs-debat)', 250),
    ('fiz-9-maqnit-sahe', 'fiz-9-maqnit-sahe-umumi',
     'Ümumiləşdirici tapşırıqlar', 260),
    --  Fesil 3. ISIQ HADISELERI  (fiz-9-isiq)
    ('fiz-9-isiq', 'fiz-9-isiq-menbeleri',
     'İşıq mənbələri', 10),
    ('fiz-9-isiq', 'fiz-9-isiq-duz-xett',
     'İşığın düz xətt boyunca yayılması', 20),
    ('fiz-9-isiq', 'fiz-9-isiq-duzxetli-qanununun',
     'İşığın düzxətli yayılma qanununun izah etdiyi hadisələr', 30),
    ('fiz-9-isiq', 'fiz-9-isiq-calisma-1',
     'Çalışma – 3.1.', 40),
    ('fiz-9-isiq', 'fiz-9-isiq-sureti-usullari',
     'İşığın yayılma sürəti və onun təyini üsulları', 50),
    ('fiz-9-isiq', 'fiz-9-isiq-calisma-2',
     'Çalışma – 3.2.', 60),
    ('fiz-9-isiq', 'fiz-9-isiq-isigin-qanunu',
     'İşığın qayıtma qanunu', 70),
    ('fiz-9-isiq', 'fiz-9-isiq-sinmasi-sinma',
     'İşığın sınması. İşığın sınma qanunu', 80),
    ('fiz-9-isiq', 'fiz-9-isiq-calisma-4',
     'Çalışma 3.4.', 90),
    ('fiz-9-isiq', 'fiz-9-isiq-paralel-uzlu',
     'İşığın paralel üzlü şüşə lövhədən və üçüzlü şüşə prizmadan keçməsi', 100),
    ('fiz-9-isiq', 'fiz-9-isiq-praktik-susenin',
     'Praktik iş 3. Şüşənin sındırma əmsalının təyini', 110),
    ('fiz-9-isiq', 'fiz-9-isiq-tam-daxili',
     'Tam daxili qayıtma', 120),
    ('fiz-9-isiq', 'fiz-9-isiq-calisma-5',
     'Çalışma 3.5.', 130),
    --  Fesil 3. ISIQ HADISELERI  (fiz-9-guzgu-linza)
    ('fiz-9-guzgu-linza', 'fiz-9-guzgu-linza-mustevi-qurulmasi',
     'Müstəvi güzgüdə xəyalın qurulması', 10),
    ('fiz-9-guzgu-linza', 'fiz-9-guzgu-linza-calisma-3',
     'Çalışma – 3.3.', 20),
    ('fiz-9-guzgu-linza', 'fiz-9-guzgu-linza-sferik',
     'Sferik güzgü', 30),
    ('fiz-9-guzgu-linza', 'fiz-9-guzgu-linza-sferik-qurulmasi',
     'Sferik güzgüdə xəyalın qurulması', 40),
    ('fiz-9-guzgu-linza', 'fiz-9-guzgu-linza-linzalar',
     'Linzalar', 50),
    ('fiz-9-guzgu-linza', 'fiz-9-guzgu-linza-cismin-xeyalinin',
     'Nazik linzada cismin xəyalının qurulması', 60),
    ('fiz-9-guzgu-linza', 'fiz-9-guzgu-linza-calisma-6',
     'Çalışma 3.6.', 70),
    ('fiz-9-guzgu-linza', 'fiz-9-guzgu-linza-nazik-dusturu',
     'Nazik linza düsturu', 80),
    ('fiz-9-guzgu-linza', 'fiz-9-guzgu-linza-praktik-4',
     'Praktik iş – 4: Toplayıcı linzanın baş fokus məsafəsinin və optik qüvvəsinin təyini', 90),
    ('fiz-9-guzgu-linza', 'fiz-9-guzgu-linza-calisma-7',
     'Çalışma – 3.7.', 100),
    ('fiz-9-guzgu-linza', 'fiz-9-guzgu-linza-goz-gorme',
     'Göz və görmə', 110),
    ('fiz-9-guzgu-linza', 'fiz-9-guzgu-linza-qusurlari-eynek',
     'Görmə qüsurları. Eynək', 120),
    ('fiz-9-guzgu-linza', 'fiz-9-guzgu-linza-fotoaparat',
     'Fotoaparat', 130),
    ('fiz-9-guzgu-linza', 'fiz-9-guzgu-linza-calisma-8',
     'Çalışma – 3.8.', 140),
    ('fiz-9-guzgu-linza', 'fiz-9-guzgu-linza-umumi',
     'Ümumiləşdirici tapşırıqlar', 150),
    --  Fesil 4. ATOM VE ATOM NUVESI  (fiz-9-radioaktivlik)
    ('fiz-9-radioaktivlik', 'fiz-9-radioaktivlik-radioaktivlik',
     'Radioaktivlik', 10),
    ('fiz-9-radioaktivlik', 'fiz-9-radioaktivlik-murekkeb-sistemdir',
     'Atom mürəkkəb əlaqəli sistemdir', 20),
    ('fiz-9-radioaktivlik', 'fiz-9-radioaktivlik-lazer',
     'Lazer', 30),
    ('fiz-9-radioaktivlik', 'fiz-9-radioaktivlik-calisma-1',
     'Çalışma 4.1.', 40),
    ('fiz-9-radioaktivlik', 'fiz-9-radioaktivlik-nuvesi-nuvenin',
     'Atom nüvəsi əlaqəli sistemdir. Nüvənin kütlə və yük ədədi', 50),
    ('fiz-9-radioaktivlik', 'fiz-9-radioaktivlik-izotoplar',
     'İzotoplar', 60),
    ('fiz-9-radioaktivlik', 'fiz-9-radioaktivlik-izotoplarin-tetbiqleri',
     'İzotopların tətbiqləri (dərs-təqdimat)', 70),
    ('fiz-9-radioaktivlik', 'fiz-9-radioaktivlik-calisma-2',
     'Çalışma 4.2.', 80),
    ('fiz-9-radioaktivlik', 'fiz-9-radioaktivlik-nuvelerinin-cevrilmeleri',
     'Atom nüvələrinin radioaktiv çevrilmələri: α-, β- və γ- şüalanma. Radioaktiv yerdəyişmə qaydası', 90),
    ('fiz-9-radioaktivlik', 'fiz-9-radioaktivlik-calisma-3',
     'Çalışma 4.3.', 100),
    ('fiz-9-radioaktivlik', 'fiz-9-radioaktivlik-cevrilme-qanunu',
     'Radioaktiv çevrilmə qanunu', 110),
    ('fiz-9-radioaktivlik', 'fiz-9-radioaktivlik-nuve-hadiselerinde',
     'Atom-nüvə hadisələrində bəzi fiziki kəmiyyətlər və onların vahidləri', 120),
    --  Fesil 4. ATOM VE ATOM NUVESI  (fiz-9-nuve)
    ('fiz-9-nuve', 'fiz-9-nuve-calisma-4',
     'Çalışma 4.4.', 10),
    ('fiz-9-nuve', 'fiz-9-nuve-rabite-enerjisi',
     'Nüvənin rabitə enerjisi. Kütlə defekti', 20),
    ('fiz-9-nuve', 'fiz-9-nuve-reaksiyalari',
     'Nüvə reaksiyaları', 30),
    ('fiz-9-nuve', 'fiz-9-nuve-calisma-5',
     'Çalışma 4.5.', 40),
    ('fiz-9-nuve', 'fiz-9-nuve-uran-bolunmesi',
     'Uran nüvəsinin bölünməsi', 50),
    ('fiz-9-nuve', 'fiz-9-nuve-zencirvari-reaksiyasi',
     'Zəncirvari nüvə reaksiyası. Atom bombası', 60),
    ('fiz-9-nuve', 'fiz-9-nuve-calisma-6',
     'Çalışma 4.6.', 70),
    ('fiz-9-nuve', 'fiz-9-nuve-sualanmanin-bioloji',
     'Şüalanmanın bioloji təsiri. Şüalanmanın udulma dozası', 80),
    ('fiz-9-nuve', 'fiz-9-nuve-reaktoru',
     'Nüvə reaktoru', 90),
    ('fiz-9-nuve', 'fiz-9-nuve-calisma-7',
     'Çalışma 4.7.', 100),
    ('fiz-9-nuve', 'fiz-9-nuve-alternativ-enerji',
     'Alternativ enerji mənbələri (dərs-təqdimat)', 110),
    ('fiz-9-nuve', 'fiz-9-nuve-istilik-reaksiyalari',
     'İstilik nüvə reaksiyaları', 120),
    ('fiz-9-nuve', 'fiz-9-nuve-calisma-8',
     'Çalışma 4.8.', 130),
    ('fiz-9-nuve', 'fiz-9-nuve-silahi-beynelxalq',
     'Nüvə silahı beynəlxalq sülhün qarantıdırmı? (dərs-debat)', 140),
    ('fiz-9-nuve', 'fiz-9-nuve-umumi',
     'Ümumiləşdirici tapşırıqlar', 150),
    --  ============  10-cu sinif  ============
    --  I fesil KINEMATIKANIN ESASLARI  (fiz-10-kinematika)
    ('fiz-10-kinematika', 'fiz-10-kinematika-mexaniki-tesviri',
     'Mexaniki hərəkət və onun təsviri', 10),
    ('fiz-10-kinematika', 'fiz-10-kinematika-yol-yerdeyisme',
     'Yol və yerdəyişmə', 20),
    ('fiz-10-kinematika', 'fiz-10-kinematika-duzxetli-suret',
     'Düzxətli bərabərsürətli hərəkət. Sürət', 30),
    ('fiz-10-kinematika', 'fiz-10-kinematika-deyisensuretli-tecil',
     'Düzxətli dəyişənsürətli hərəkət. Təcil', 40),
    ('fiz-10-kinematika', 'fiz-10-kinematika-hereketde-yerdeyisme',
     'Düzxətli bərabərtəcilli hərəkətdə sürət və yerdəyişmə', 50),
    ('fiz-10-kinematika', 'fiz-10-kinematika-praktik-yollar',
     'PRAKTİK İŞ. BƏRABƏRTƏCİLLİ HƏRƏKƏT ÜÇÜN "YOLLAR QANUNU"', 60),
    ('fiz-10-kinematika', 'fiz-10-kinematika-cismin-serbestdusmesi',
     'Cismin sərbəstdüşməsi', 70),
    ('fiz-10-kinematika', 'fiz-10-kinematika-hereketin-nisbiliyi',
     'Mexaniki hərəkətin nisbiliyi', 80),
    ('fiz-10-kinematika', 'fiz-10-kinematika-cevre-hereket',
     'Çevrə üzrə bərabərsürətli hərəkət', 90),
    ('fiz-10-kinematika', 'fiz-10-kinematika-fesle-meseleler',
     'I fəslə aid məsələlər', 100),
    --  II fesil DINAMIKANIN ESASLARI  (fiz-10-dinamika)
    ('fiz-10-dinamika', 'fiz-10-dinamika-meselesi-quvve',
     'Dinamikanın əsas məsələsi. Qüvvə. Əvəzləyici qüvvə. Kütlə', 10),
    ('fiz-10-dinamika', 'fiz-10-dinamika-etaletle-qanunu',
     'Ətalətlə hərəkət: Nyutonun I qanunu', 20),
    ('fiz-10-dinamika', 'fiz-10-dinamika-esas-nyutonun',
     'Dinamikanın əsas qanunu: Nyutonun II qanunu', 30),
    ('fiz-10-dinamika', 'fiz-10-dinamika-tesir-eks',
     'Təsir və əks təsir. Nyutonun III qanunu', 40),
    ('fiz-10-dinamika', 'fiz-10-dinamika-umumdunya-cazibe',
     'Ümumdünya cazibə qanunu', 50),
    ('fiz-10-dinamika', 'fiz-10-dinamika-agirliq-qravitasiya',
     'Ağırlıq qüvvəsi. Qravitasiya sahəsinin intensivliyi', 60),
    ('fiz-10-dinamika', 'fiz-10-dinamika-ceki-cekisizlik',
     'Çəki və çəkisizlik', 70),
    ('fiz-10-dinamika', 'fiz-10-dinamika-elastiklik-quvvesi',
     'Elastiklik qüvvəsi', 80),
    ('fiz-10-dinamika', 'fiz-10-dinamika-surtunme-quvvesinin',
     'Sürtünmə qüvvəsi. Sürtünmə qüvvəsinin təsiri altında hərəkət', 90),
    ('fiz-10-dinamika', 'fiz-10-dinamika-cismin-tarazliq',
     'Cismin tarazlıq şərtləri', 100),
    ('fiz-10-dinamika', 'fiz-10-dinamika-fesle-meseleler',
     'II fəslə aid məsələlər', 110),
    --  III fesil SAXLANMA QANUNLARI  (fiz-10-saxlanma)
    ('fiz-10-saxlanma', 'fiz-10-saxlanma-qapali-sistem',
     'Qapalı sistem. İmpulsun saxlanması qanunu', 10),
    ('fiz-10-saxlanma', 'fiz-10-saxlanma-mexaniki-guc',
     'Mexaniki iş və güc', 20),
    ('fiz-10-saxlanma', 'fiz-10-saxlanma-sistemin-isgorme',
     'Sistemin işgörmə qabiliyyəti - enerjidir. Kinetik enerji', 30),
    ('fiz-10-saxlanma', 'fiz-10-saxlanma-potensial-enerji',
     'Potensial enerji', 40),
    ('fiz-10-saxlanma', 'fiz-10-saxlanma-tam-enerjinin',
     'Tam mexaniki enerji. Enerjinin saxlanması qanunu', 50),
    ('fiz-10-saxlanma', 'fiz-10-saxlanma-azerbaycanda-alternativ',
     'Azərbaycanda alternativ enerji mənbələrindən istifadə (Təqdimat dərs)', 60),
    ('fiz-10-saxlanma', 'fiz-10-saxlanma-iii-fesle',
     'III fəslə aid məsələlər', 70),
    --  IV fesil MEXANIKI REQSLER VE DALGALAR  (fiz-10-reqs-dalga)
    ('fiz-10-reqs-dalga', 'fiz-10-reqs-dalga-hereket-serbest',
     'Rəqsi hərəkət. Sərbəst rəqslər', 10),
    ('fiz-10-reqs-dalga', 'fiz-10-reqs-dalga-yayli-harmonik',
     'Yaylı rəqqasda harmonik rəqslər', 20),
    ('fiz-10-reqs-dalga', 'fiz-10-reqs-dalga-riyazi-harmonik',
     'Riyazi rəqqasda harmonik rəqslər', 30),
    ('fiz-10-reqs-dalga', 'fiz-10-reqs-dalga-praktik-reqqas',
     'PRAKTİK İŞ. Riyazi rəqqas vasitəsilə sərbəstdüşmə təcilinin təyini', 40),
    ('fiz-10-reqs-dalga', 'fiz-10-reqs-dalga-enerji-cevrilmeleri',
     'Harmonik rəqslərdə enerji çevrilmələri (Təqdimat dərs)', 50),
    ('fiz-10-reqs-dalga', 'fiz-10-reqs-dalga-mecburi-rezonans',
     'Məcburi rəqslər. Rezonans', 60),
    ('fiz-10-reqs-dalga', 'fiz-10-reqs-dalga-elastik-muhitde',
     'Rəqslərin elastik mühitdə yayılması: mexaniki dalğa', 70),
    ('fiz-10-reqs-dalga', 'fiz-10-reqs-dalga-fesle-meseleler',
     'IV fəslə aid məsələlər', 80),
    --  V fesil RELYATIVISTIK MEXANIKA  (fiz-10-saxlanma)
    ('fiz-10-saxlanma', 'fiz-10-saxlanma-nisbilik-nezeriyyesinin',
     'Nisbilik nəzəriyyəsinin əsasları', 80),
    ('fiz-10-saxlanma', 'fiz-10-saxlanma-enerji-kutle',
     'Enerji ilə kütlə arasında qarşılıqlı əlaqə qanunu', 90),
    ('fiz-10-saxlanma', 'fiz-10-saxlanma-fesle-meseleler',
     'V fəslə aid məsələlər', 100),
    --  VI fesil MOLEKULYAR-KINETIK NEZERIYYE  (fiz-10-molekulyar)
    ('fiz-10-molekulyar', 'fiz-10-molekulyar-nezeriyye-muddealari',
     'Molekulyar-kinetik nəzəriyyə və onun əsas müddəaları', 10),
    ('fiz-10-molekulyar', 'fiz-10-molekulyar-nezeriyyesinin-tenliyi',
     'İdeal qaz. İdeal qazın molekulyar-kinetik nəzəriyyəsinin əsas tənliyi', 20),
    ('fiz-10-molekulyar', 'fiz-10-molekulyar-istilik-tarazligi',
     'İstilik tarazlığı - temperatur', 30),
    ('fiz-10-molekulyar', 'fiz-10-molekulyar-hal-tenliyi',
     'İdeal qazın hal tənliyi', 40),
    ('fiz-10-molekulyar', 'fiz-10-molekulyar-qaz-qanunlari',
     'Qaz qanunları', 50),
    ('fiz-10-molekulyar', 'fiz-10-molekulyar-buxarlarin-doyan',
     'Buxarların xassələri: doyan və doymayan buxar', 60),
    ('fiz-10-molekulyar', 'fiz-10-molekulyar-havanin-rutubetliliyi',
     'Havanın rütubətliliyi. Şeh nöqtəsi', 70),
    ('fiz-10-molekulyar', 'fiz-10-molekulyar-mayelerin-sethi',
     'Mayelərin səthi gərilməsi. Kapilyar hadisələr', 80),
    ('fiz-10-molekulyar', 'fiz-10-molekulyar-berk-cisimler',
     'Bərk cisimlər və onların bəzi xassələri', 90),
    ('fiz-10-molekulyar', 'fiz-10-molekulyar-fesle-meseleler',
     'VI fəslə aid məsələlər', 100),
    --  VII fesil TERMODINAMIKANIN ESASLARI  (fiz-10-termodinamika)
    ('fiz-10-termodinamika', 'fiz-10-termodinamika-sistem-daxili',
     'Termodinamik sistem. Daxili enerji', 10),
    ('fiz-10-termodinamika', 'fiz-10-termodinamika-birinci-qanunu',
     'Termodinamikanın birinci qanunu', 20),
    ('fiz-10-termodinamika', 'fiz-10-termodinamika-ikinci-muherriklerini',
     'Termodinamikanın ikinci qanunu. İstilik mühərriklərinin iş prinsipi', 30),
    ('fiz-10-termodinamika', 'fiz-10-termodinamika-layihe-muherrikleri',
     'Layihə. İstilik mühərrikləri və ətraf mühit', 40),
    ('fiz-10-termodinamika', 'fiz-10-termodinamika-vii-fesle',
     'VII fəslə aid məsələlər', 50),
    --  ============  11-ci sinif  ============
    --  I fesil ELEKTROMAQNIT SAHESI  (fiz-11-elektrostatika)
    ('fiz-11-elektrostatika', 'fiz-11-elektrostatika-yuku-elektromaqnit',
     'Elektrik yükü. Elektromaqnit sahəsi', 10),
    ('fiz-11-elektrostatika', 'fiz-11-elektrostatika-sahe-sahenin',
     'Elektrostatik sahə. Elektrostatik sahənin intensivliyi', 20),
    ('fiz-11-elektrostatika', 'fiz-11-elektrostatika-bircins-sahesinin',
     'Bircins elektrik sahəsinin işi. Potensial. Gərginlik', 30),
    ('fiz-11-elektrostatika', 'fiz-11-elektrostatika-kondensator-tutumu',
     'Kondensator. Elektrik tutumu', 40),
    ('fiz-11-elektrostatika', 'fiz-11-elektrostatika-kondensatorlar-birlesdirilmes',
     'Kondensatorların birləşdirilməsi', 50),
    --  I fesil ELEKTROMAQNIT SAHESI  (fiz-11-maqnit-induksiya)
    ('fiz-11-maqnit-induksiya', 'fiz-11-maqnit-induksiya-yuklu-zerreciyin',
     'Yüklü zərrəciyin maqnit sahəsində hərəkəti. Lorens qüvvəsi', 10),
    ('fiz-11-maqnit-induksiya', 'fiz-11-maqnit-induksiya-cereyanli-naqile',
     'Maqnit sahəsinin cərəyanlı naqilə təsiri. Amper qüvvəsi', 20),
    ('fiz-11-maqnit-induksiya', 'fiz-11-maqnit-induksiya-seli-hadisesi',
     'Maqnit seli. Elektromaqnit induksiyası hadisəsi', 30),
    ('fiz-11-maqnit-induksiya', 'fiz-11-maqnit-induksiya-qanunu-hereket',
     'Elektromaqnit induksiyası qanunu. Maqnit sahəsində hərəkət edən naqillərdə induksiya elektrik hərəkət qüvvəsi', 40),
    ('fiz-11-maqnit-induksiya', 'fiz-11-maqnit-induksiya-ozune-ehq',
     'Öz-özünə induksiya EHQ. Maqnit sahəsinin enerjisi', 50),
    ('fiz-11-maqnit-induksiya', 'fiz-11-maqnit-induksiya-fesle-meseleler',
     'I fəslə aid məsələlər', 60),
    --  II fesil MUXTELIF MUHITLERDE SABIT CEREYAN QANUNLARI  (fiz-11-cereyan-qanunlari)
    ('fiz-11-cereyan-qanunlari', 'fiz-11-cereyan-qanunlari-metallarin-keciriciliyini',
     'Metalların elektrik keçiriciliyinin elektron nəzəriyyəsinin elementləri', 10),
    ('fiz-11-cereyan-qanunlari', 'fiz-11-cereyan-qanunlari-hissesi-muqavimet',
     'Dövrə hissəsi üçün Om qanunu. Müqavimət. İfrat keçiricilik', 20),
    ('fiz-11-cereyan-qanunlari', 'fiz-11-cereyan-qanunlari-hereket-quvvesi',
     'Elektrik hərəkət qüvvəsi. Tam dövrə üçün Om qanunu', 30),
    ('fiz-11-cereyan-qanunlari', 'fiz-11-cereyan-qanunlari-vakuumda-elektrik',
     'Vakuumda elektrik cərəyanı', 40),
    ('fiz-11-cereyan-qanunlari', 'fiz-11-cereyan-qanunlari-qazlarda-elektrik',
     'Qazlarda elektrik cərəyanı', 50),
    ('fiz-11-cereyan-qanunlari', 'fiz-11-cereyan-qanunlari-elektrolit-mehlullarinda',
     'Elektrolit məhlullarında elektrik cərəyanı. Elektroliz qanunu', 60),
    ('fiz-11-cereyan-qanunlari', 'fiz-11-cereyan-qanunlari-yarimkeciricil-elektrik',
     'Yarımkeçiricilərdə elektrik cərəyanı', 70),
    ('fiz-11-cereyan-qanunlari', 'fiz-11-cereyan-qanunlari-diod-tranzistor',
     'Yarımkeçirici diod. Tranzistor', 80),
    ('fiz-11-cereyan-qanunlari', 'fiz-11-cereyan-qanunlari-qurgular-onlarin',
     'Yarımkeçirici qurğular: onların elm, texnika və istehsalatda tətbiqi (təqdimat dərs)', 90),
    ('fiz-11-cereyan-qanunlari', 'fiz-11-cereyan-qanunlari-fesle-meseleler',
     'II fəslə aid məsələlər', 100),
    --  III fesil ELEKTROMAQNIT REQSLERI VE DALGALARI  (fiz-11-em-reqs)
    ('fiz-11-em-reqs', 'fiz-11-em-reqs-serbest-elektromaqnit',
     'Sərbəst elektromaqnit rəqsləri', 10),
    ('fiz-11-em-reqs', 'fiz-11-em-reqs-enerji-cevrilmeleri',
     'Elektromaqnit rəqslərində enerji çevrilmələri (təqdimat dərs)', 20),
    ('fiz-11-em-reqs', 'fiz-11-em-reqs-mecburi-cereyan',
     'Məcburi elektromaqnit rəqsləri: dəyişən cərəyan', 30),
    ('fiz-11-em-reqs', 'fiz-11-em-reqs-rezistor-kondensator',
     'Rezistor, kondensator və sarğac qoşulmuş dəyişən cərəyan dövrələri', 40),
    ('fiz-11-em-reqs', 'fiz-11-em-reqs-aktiv-induktiv',
     'Aktiv, induktiv və tutum müqavimətlərinin ardıcıl birləşdirildiyi dəyişən cərəyan dövrəsi üçün Om qanunu', 50),
    ('fiz-11-em-reqs', 'fiz-11-em-reqs-elektrik-enerjisinin',
     'Elektrik enerjisinin ötürülməsi. Transformator', 60),
    ('fiz-11-em-reqs', 'fiz-11-em-reqs-elektromaqnit-dalgalari',
     'Elektromaqnit dalğaları', 70),
    ('fiz-11-em-reqs', 'fiz-11-em-reqs-dalgasinin-enerjisi',
     'Elektromaqnit dalğasının enerjisi. Elektromaqnit dalğaları şkalası (təqdimat dərs)', 80),
    ('fiz-11-em-reqs', 'fiz-11-em-reqs-radiorabitenin-prinsipleri',
     'Radiorabitənin prinsipləri', 90),
    --  III fesil ELEKTROMAQNIT REQSLERI VE DALGALARI  (fiz-11-optika)
    ('fiz-11-optika', 'fiz-11-optika-dalga-tebieti',
     'İşığın dalğa təbiəti. İşığın dispersiyası', 10),
    ('fiz-11-optika', 'fiz-11-optika-dalgalarin-interferensiya',
     'Dalğaların interferensiyası. İşığın interferensiyası', 20),
    ('fiz-11-optika', 'fiz-11-optika-difraksiyasi-isigin',
     'Dalğaların difraksiyası. İşığın difraksiyası', 30),
    ('fiz-11-optika', 'fiz-11-optika-isigin-polyarlasmasi',
     'İşığın polyarlaşması', 40),
    ('fiz-11-optika', 'fiz-11-optika-iii-fesle',
     'III fəslə aid məsələlər', 50),
    --  IV fesil ATOM FIZIKASI  (fiz-11-atom)
    ('fiz-11-atom', 'fiz-11-atom-elektromaqnit-sualanmasinin',
     'Elektromaqnit şüalanmasının kvant təbiəti. Foton', 10),
    ('fiz-11-atom', 'fiz-11-atom-fotoeffekt-nezeriyye',
     'Fotoeffekt. Fotoeffekt nəzəriyyə', 20),
    ('fiz-11-atom', 'fiz-11-atom-kompton-effekti',
     'Kompton effekti və de Broyl dalğaları (təqdimat dərs)', 30),
    ('fiz-11-atom', 'fiz-11-atom-haqqinda-borun',
     'Atomun quruluşu haqqında Borun kvant postulatları. Atomun enerji səviyyələri', 40),
    ('fiz-11-atom', 'fiz-11-atom-sualanmanin-novleri',
     'Şüalanmanın növləri və onların tətbiqləri (təqdimat dərs)', 50),
    ('fiz-11-atom', 'fiz-11-atom-nuvesi-qurulusu',
     'Atom nüvəsi. Atom nüvəsinin quruluşu', 60),
    ('fiz-11-atom', 'fiz-11-atom-nuvenin-rabite',
     'Nüvənin rabitə enerjisi', 70),
    ('fiz-11-atom', 'fiz-11-atom-radioaktivlik-nuvelerin',
     'Radioaktivlik. Nüvələrin radioaktiv çevrilməsi', 80),
    ('fiz-11-atom', 'fiz-11-atom-cevrilme-qanunu',
     'Radioaktiv çevrilmə qanunu', 90),
    ('fiz-11-atom', 'fiz-11-atom-nuve-reaksiyasi',
     'Nüvə reaksiyası', 100),
    ('fiz-11-atom', 'fiz-11-atom-uran-bolunmesi',
     'Uran nüvəsinin bölünməsi. Zəncirvarı nüvə reaksiyası', 110),
    ('fiz-11-atom', 'fiz-11-atom-istilik-reaksiyasi',
     'İstilik nüvə reaksiyası', 120),
    ('fiz-11-atom', 'fiz-11-atom-elementar-zerrecikler',
     'Elementar zərrəciklər və onların qeydəalınma üsulları', 130),
    ('fiz-11-atom', 'fiz-11-atom-fizika-muasir',
     'Fizika və müasir həyat (təqdimat dərs)', 140),
    ('fiz-11-atom', 'fiz-11-atom-fesle-meseleler',
     'IV fəslə aid məsələlər', 150)
  ) as v(parent_slug, slug, name, sort)
  join public.topics p on p.slug = v.parent_slug
   and p.subject_id = (select id from public.subjects where slug = 'fizika')
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort,
      parent_id = excluded.parent_id, level_id = excluded.level_id;

do $$
declare k int;
begin
  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'fizika'
    join public.levels   l on l.id = p.level_id and l.code = '6';
  if k <> 29 then
    raise exception 'fizika 6-ci alt movzulari: 29 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'fizika'
    join public.levels   l on l.id = p.level_id and l.code = '7';
  if k <> 54 then
    raise exception 'fizika 7-ci alt movzulari: 54 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'fizika'
    join public.levels   l on l.id = p.level_id and l.code = '8';
  if k <> 58 then
    raise exception 'fizika 8-ci alt movzulari: 58 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'fizika'
    join public.levels   l on l.id = p.level_id and l.code = '9';
  if k <> 99 then
    raise exception 'fizika 9-cu alt movzulari: 99 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'fizika'
    join public.levels   l on l.id = p.level_id and l.code = '10';
  if k <> 54 then
    raise exception 'fizika 10-cu alt movzulari: 54 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'fizika'
    join public.levels   l on l.id = p.level_id and l.code = '11';
  if k <> 50 then
    raise exception 'fizika 11-ci alt movzulari: 50 gozlenilirdi, % tapildi', k;
  end if;

  --  alt movzuda sual OLMAMALIDIR
  select count(*) into k from public.questions q
    join public.topics t on t.id = q.topic_id
   where t.parent_id is not null;
  if k > 0 then
    raise exception '% sual alt movzuya baglanib - bu merhelede olmamalidir', k;
  end if;

  --  ust movzu sayi deyismemelidir
  select count(*) into k from public.topics t
    join public.subjects s on s.id = t.subject_id and s.slug = 'fizika'
    join public.levels   l on l.id = t.level_id
   where t.parent_id is null and true;
  if k <> 37 then
    raise exception 'Fizika ust movzu sayi 37 deyil: %', k;
  end if;

  raise notice 'Fizika 6-11: 344 alt movzu hazir.';
end $$;
