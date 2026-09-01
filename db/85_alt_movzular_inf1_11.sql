-- =====================================================================
--  85_alt_movzular_inf1_11.sql : INFORMATIKA 1-11 - ALT MOVZULAR
--
--  NIYE
--  Ucuncu fenn.  Riyaziyyat (74/82/83) ve heyat bilgisi (84) hazirdir;
--  informatika ile IBTIDAI SINIFLER de tam bitir (az dili istisnadir -
--  derslik temaya gore bolunub, bizim agac qrammatikadir).
--
--  MENBE: e-derslik.edu.az "Movzular" agaci - kitab id 417 (1),
--  520 (2), 676 (3), 360 (4), 846 (5), 912 (6), 708 (7), 797 (8),
--  884 (9), 736 (10), 822 (11).  Adlar EYNILE goturulub.
--
--  DERSLIYIN QURULUSU UC YERDE BIZIMKINDEN FERQLIDIR:
--
--  1) 1, 3 ve 4-cu sinifde bolmenin icinde ALT BASLIQ var - nomresiz,
--     ozunden sonraki dersle EYNI sehifede ("QRAFIK REDAKTOR" s.52,
--     "20. PAINT PROQRAMI" s.52).  O, ders deyil, ona gore siyahiya
--     dusmur; bizim iki movzuya bolunen bolmelerde ise sarhed kimi
--     islenir (inf-3-kompyuter | inf-3-qrafik).
--  2) 2-ci sinifde alt basliq YOXDUR, amma bazada "Kompüter" ve
--     "Proqramlarla iş" ayri movzudur.  Sarhed s.53-dur: 21-ci ders
--     "Metn redaktoru"ndan etibaren proqramlarla is baslayir; 20-ci
--     ders ("İş masası və proqram pəncərəsi") hele komputerin ozudur.
--  3) 10 ve 11-ci sinifde derslikde bolme COXDUR: 10-da "Veb-
--     proqramlasdirma" + "Informasiya cemiyyeti" bizde bir movzudur
--     ("Veb və informasiya cəmiyyəti"), 11-de "Komputer" + "Veb-
--     layihe" birdir.  Setirler birlesir, sira davam edir.
--
--  BURAXILAN BOLMELER: 5-ci sinifde "Giriş" (derslikle nece
--  islemeli), 11-ci sinifde "Layihələr üçün yardımçı materiallar" ve
--  "Informatika kursu uzre testler" - ders deyil, elavedir.
--
--  ADLARIN BOYUK HERFLE YAZILISI DEYISDIRILMIR: 1, 3 ve 4-cu sinif
--  dersliyi basliqlari kitabin OZUNDE de tam boyuk herfle verib
--  (s.6 basligi <h3>1. INSAN VE INFORMASIYA</h3>).  Bu, portal
--  qusuru deyil - dersliyin dizaynidir, ona gore toxunulmur.
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
--   * yazi (12): yazi qusuru (bosluq, herf)
--       1-ci   s.15   4.Esyalarinmuqayisesi
--                    -> Esyalarin muqayisesi
--       1-ci   s.62   21. Fiqurlarincekilmesi
--                    -> Fiqurlarin cekilmesi
--       4-cu   s.28   8. ?VE?, ?VE YA" SOZLERI OLAN MUREKKEB MULAHIZELER
--                    -> ?VE?, ?VE YA? SOZLERI OLAN MUREKKEB MULAHIZELER
--       4-cu   s.34   10. ?EGER - ONDA" QAYDASI
--                    -> ?EGER - ONDA? QAYDASI
--       9-cu   s.54   12. Verilenlerin vizuallasdirilmasi.Diaqramlar
--                    -> Verilenlerin vizuallasdirilmasi. Diaqramlar
--       10-cu  s.118  3.8. Verilenlelrin axtarisi ve cesidlenmesi
--                    -> Verilenlerin axtarisi ve cesidlenmesi
--       11-ci  s.11   1.1. informasiya sistemi ve onun elementleri
--                    -> Informasiya sistemi ve onun elementleri
--       11-ci  s.15   1.2. informasiya sistemlerinin tesnifati
--                    -> Informasiya sistemlerinin tesnifati
--       11-ci  s.33   1.7. "Boyuk verilenler"texnologiyasi
--                    -> "Boyuk verilenler" texnologiyasi
--       11-ci  s.36   1.8. informasiya cemiyyeti
--                    -> Informasiya cemiyyeti
--       11-ci  s.109  4.5. internet xidmetleri
--                    -> Internet xidmetleri
--       11-ci  s.117  5.1. idareetme paneli
--                    -> Idareetme paneli

insert into public.topics (subject_id, level_id, parent_id, slug, name, sort)
select p.subject_id, p.level_id, p.id, v.slug, v.name, v.sort
  from (values
    --  ============  1-ci sinif  ============
    --  1. ESYALARIN TESVIRI VE MUQAYISESI  (inf-1-esyalar)
    ('inf-1-esyalar', 'inf-1-esyalar-rengi-formasi',
     'Əşyanın rəngi və forması', 10),
    ('inf-1-esyalar', 'inf-1-esyalar-hisseleri-hereketi',
     'Əşyanın hissələri və hərəkəti', 20),
    ('inf-1-esyalar', 'inf-1-esyalar-esyanin-tesviri',
     'Əşyanın təsviri', 30),
    ('inf-1-esyalar', 'inf-1-esyalar-muqayisesi',
     'Əşyaların müqayisəsi', 40),
    ('inf-1-esyalar', 'inf-1-esyalar-yuxari-asagi',
     'Yuxarı, aşağı, sağ, sol', 50),
    ('inf-1-esyalar', 'inf-1-esyalar-ozumuzu-yoxlayaq',
     'Özümüzü yoxlayaq', 60),
    --  2. HADISELER VE HEREKETLER ARDICILLIGI  (inf-1-ardicilliq)
    ('inf-1-ardicilliq', 'inf-1-ardicilliq-evvel-sonra',
     'Əvvəl - sonra', 10),
    ('inf-1-ardicilliq', 'inf-1-ardicilliq-hadiseler-ardicilligi',
     'Hadisələr ardıcıllığı', 20),
    ('inf-1-ardicilliq', 'inf-1-ardicilliq-hereketler-ardicilligi',
     'Hərəkətlər ardıcıllığı', 30),
    ('inf-1-ardicilliq', 'inf-1-ardicilliq-eks-elametler',
     'Əks əlamətlər', 40),
    ('inf-1-ardicilliq', 'inf-1-ardicilliq-dogru-yalan',
     'Doğru və yalan', 50),
    ('inf-1-ardicilliq', 'inf-1-ardicilliq-ozumuzu-yoxlayaq',
     'Özümüzü yoxlayaq', 60),
    --  3. INFORMASIYA  (inf-1-informasiya)
    ('inf-1-informasiya', 'inf-1-informasiya-nedir',
     'İnformasiya nədir', 10),
    ('inf-1-informasiya', 'inf-1-informasiya-teqdim-olar',
     'İnformasiyanı necə təqdim etmək olar', 20),
    ('inf-1-informasiya', 'inf-1-informasiya-haradan-aliriq',
     'İnformasiyanı haradan alırıq', 30),
    ('inf-1-informasiya', 'inf-1-informasiya-nece-oturulur',
     'İnformasiya necə ötürülür', 40),
    ('inf-1-informasiya', 'inf-1-informasiya-istifade-olar',
     'İnformasiyadan necə istifadə etmək olar', 50),
    ('inf-1-informasiya', 'inf-1-informasiya-ozumuzu-yoxlayaq',
     'Özümüzü yoxlayaq', 60),
    --  4. KOMPUTER  (inf-1-kompyuter)
    ('inf-1-kompyuter', 'inf-1-kompyuter-komputer-nedir',
     'Kompüter nədir', 10),
    ('inf-1-kompyuter', 'inf-1-kompyuter-komputerin-esas',
     'Kompüterin əsas hissələri', 20),
    ('inf-1-kompyuter', 'inf-1-kompyuter-komputerle-nece',
     'Kompüterlə necə davranmalı', 30),
    ('inf-1-kompyuter', 'inf-1-kompyuter-komputerde-islemeye',
     'Kompüterdə işləməyə başlayırıq', 40),
    --  4. KOMPUTER  (inf-1-komp-imkanlar)
    ('inf-1-komp-imkanlar', 'inf-1-komp-imkanlar-sekil-cekirem',
     'Kompüterdə şəkil çəkirəm', 10),
    ('inf-1-komp-imkanlar', 'inf-1-komp-imkanlar-fiqurlarin-cekilmesi',
     'Fiqurların çəkilməsi', 20),
    ('inf-1-komp-imkanlar', 'inf-1-komp-imkanlar-yaziram',
     'Kompüterdə yazıram', 30),
    ('inf-1-komp-imkanlar', 'inf-1-komp-imkanlar-metnde-sehvlerin',
     'Mətndə səhvlərin düzəldilməsi', 40),
    ('inf-1-komp-imkanlar', 'inf-1-komp-imkanlar-hesablayiram',
     'Kompüterdə hesablayıram', 50),
    ('inf-1-komp-imkanlar', 'inf-1-komp-imkanlar-ozumuzu-yoxlayaq',
     'Özümüzü yoxlayaq', 60),
    --  ============  2-ci sinif  ============
    --  1 OBYEKT  (inf-2-obyekt)
    ('inf-2-obyekt', 'inf-2-obyekt-nedir',
     'Obyekt nədir', 10),
    ('inf-2-obyekt', 'inf-2-obyekt-oxsar-elametler',
     'Oxşar əlamətlər', 20),
    ('inf-2-obyekt', 'inf-2-obyekt-qruplasdirma',
     'Qruplaşdırma', 30),
    ('inf-2-obyekt', 'inf-2-obyekt-ferqlendirici-elametler',
     'Fərqləndirici əlamətlər', 40),
    ('inf-2-obyekt', 'inf-2-obyekt-tapmacalar',
     'Tapmacalar', 50),
    ('inf-2-obyekt', 'inf-2-obyekt-sual-tapsiriqlar',
     'Sual və tapşırıqlar', 60),
    --  2 INFORMASIYA  (inf-2-informasiya)
    ('inf-2-informasiya', 'inf-2-informasiya-novleri',
     'İnformasiyanın növləri', 10),
    ('inf-2-informasiya', 'inf-2-informasiya-alinmasi',
     'İnformasiyanın alınması', 20),
    ('inf-2-informasiya', 'inf-2-informasiya-teqdim-olunmasi',
     'İnformasiyanın təqdim olunması', 30),
    ('inf-2-informasiya', 'inf-2-informasiya-saxlanmasi',
     'İnformasiyanın saxlanması', 40),
    ('inf-2-informasiya', 'inf-2-informasiya-oturulmesi',
     'İnformasiyanın ötürülməsi', 50),
    ('inf-2-informasiya', 'inf-2-informasiya-sual-tapsiriqlar',
     'Sual və tapşırıqlar', 60),
    --  3 ALQORITM  (inf-2-alqoritm)
    ('inf-2-alqoritm', 'inf-2-alqoritm-hereketler-hadiseler',
     'Hərəkətlər və hadisələr ardıcıllığı', 10),
    ('inf-2-alqoritm', 'inf-2-alqoritm-alqoritm',
     'Alqoritm', 20),
    ('inf-2-alqoritm', 'inf-2-alqoritm-icrasi',
     'Alqoritmin icrası', 30),
    ('inf-2-alqoritm', 'inf-2-alqoritm-dogru-yalan',
     'Doğru və yalan mülahizələr', 40),
    ('inf-2-alqoritm', 'inf-2-alqoritm-qeyri-mueyyen',
     'Qeyri-müəyyən mülahizə', 50),
    ('inf-2-alqoritm', 'inf-2-alqoritm-sade-qisa',
     'Ən sadə və ən qısa yol', 60),
    ('inf-2-alqoritm', 'inf-2-alqoritm-sual-tapsiriqlar',
     'Sual və tapşırıqlar', 70),
    --  4 KOMPUTER  (inf-2-kompyuter)
    ('inf-2-kompyuter', 'inf-2-kompyuter-komputer-hisseleri',
     'Kompüter və onun hissələri', 10),
    ('inf-2-kompyuter', 'inf-2-kompyuter-sinfinde-davranis',
     'Kompüter sinfində davranış qaydaları', 20),
    ('inf-2-kompyuter', 'inf-2-kompyuter-klaviatura-sican',
     'Klaviatura və siçan qurğusu', 30),
    ('inf-2-kompyuter', 'inf-2-kompyuter-masasi-proqram',
     'İş masası və proqram pəncərəsi', 40),
    --  4 KOMPUTER  (inf-2-proqramlar)
    ('inf-2-proqramlar', 'inf-2-proqramlar-metn-redaktoru',
     'Mətn redaktoru', 10),
    ('inf-2-proqramlar', 'inf-2-proqramlar-metnin-formatlanmasi',
     'Mətnin formatlanması', 20),
    ('inf-2-proqramlar', 'inf-2-proqramlar-qrafik-redaktor',
     'Qrafik redaktor', 30),
    ('inf-2-proqramlar', 'inf-2-proqramlar-metnli-sekiller',
     'Mətnli şəkillər', 40),
    ('inf-2-proqramlar', 'inf-2-proqramlar-kalkulyator-proqraminda',
     'Kalkulyator proqramında hesablamalar', 50),
    ('inf-2-proqramlar', 'inf-2-proqramlar-sual-tapsiriqlar',
     'Sual və tapşırıqlar', 60),
    --  ============  3-cu sinif  ============
    --  1 INFORMASIYA  (inf-3-informasiya)
    ('inf-3-informasiya', 'inf-3-informasiya-insan',
     'İNSAN VƏ İNFORMASİYA', 10),
    ('inf-3-informasiya', 'inf-3-informasiya-tebietde',
     'TƏBİƏTDƏ İNFORMASİYA', 20),
    ('inf-3-informasiya', 'inf-3-informasiya-prosesleri',
     'İNFORMASİYA PROSESLƏRİ', 30),
    ('inf-3-informasiya', 'inf-3-informasiya-oturulmesi',
     'İNFORMASİYANIN ÖTÜRÜLMƏSİ', 40),
    ('inf-3-informasiya', 'inf-3-informasiya-kodlasdirilmas',
     'İNFORMASİYANIN KODLAŞDIRILMASI', 50),
    ('inf-3-informasiya', 'inf-3-informasiya-rebus',
     'REBUS', 60),
    ('inf-3-informasiya', 'inf-3-informasiya-emali',
     'İNFORMASİYANIN EMALI', 70),
    ('inf-3-informasiya', 'inf-3-informasiya-sual-tapsiriqlar',
     'Sual və tapşırıqlar', 80),
    --  2 ALQORITM  (inf-3-alqoritm)
    ('inf-3-alqoritm', 'inf-3-alqoritm-obyektler-qrupu',
     'OBYEKTLƏR QRUPU', 10),
    ('inf-3-alqoritm', 'inf-3-alqoritm-obyektin-ferqlendirici',
     'OBYEKTİN FƏRQLƏNDİRİCİ ƏLAMƏTLƏRİ', 20),
    ('inf-3-alqoritm', 'inf-3-alqoritm-hamisi-hec',
     '“HAMISI”, “HEÇ BİRİ”, “BƏZİSİ”', 30),
    ('inf-3-alqoritm', 'inf-3-alqoritm-qanunauygunluq',
     'QANUNAUYĞUNLUQ', 40),
    ('inf-3-alqoritm', 'inf-3-alqoritm-alqoritm',
     'ALQORİTM', 50),
    ('inf-3-alqoritm', 'inf-3-alqoritm-xetti',
     'XƏTTİ ALQORİTM', 60),
    ('inf-3-alqoritm', 'inf-3-alqoritm-budaqlanma',
     'BUDAQLANMA', 70),
    ('inf-3-alqoritm', 'inf-3-alqoritm-meqsedeuygun-yolun',
     'MƏQSƏDƏUYĞUN YOLUN SEÇİLMƏSİ', 80),
    ('inf-3-alqoritm', 'inf-3-alqoritm-tekrarlanan-hereketler',
     'TƏKRARLANAN HƏRƏKƏTLƏR', 90),
    ('inf-3-alqoritm', 'inf-3-alqoritm-sual-tapsiriqlar',
     'Sual və tapşırıqlar', 100),
    --  3 KOMPUTER  (inf-3-kompyuter)
    ('inf-3-kompyuter', 'inf-3-kompyuter-komputer-informasiya',
     'KOMPÜTER VƏ İNFORMASİYA', 10),
    ('inf-3-kompyuter', 'inf-3-kompyuter-masasi',
     'İŞ MASASI', 20),
    ('inf-3-kompyuter', 'inf-3-kompyuter-qovluq',
     'QOVLUQ', 30),
    --  3 KOMPUTER  (inf-3-qrafik)
    ('inf-3-qrafik', 'inf-3-qrafik-paint-proqrami',
     'PAINT PROQRAMI', 10),
    ('inf-3-qrafik', 'inf-3-qrafik-palitra',
     'PALİTRA', 20),
    ('inf-3-qrafik', 'inf-3-qrafik-seklin-fraqmenti',
     'ŞƏKLİN FRAQMENTİ İLƏ İŞ', 30),
    ('inf-3-qrafik', 'inf-3-qrafik-sekillerin-komputerde',
     'ŞƏKİLLƏRİN KOMPÜTERDƏ SAXLANMASI', 40),
    ('inf-3-qrafik', 'inf-3-qrafik-sual-tapsiriqlar',
     'Sual və tapşırıqlar', 50),
    --  METN REDAKTORU  (inf-3-metn)
    ('inf-3-metn', 'inf-3-metn-wordpad-proqrami',
     'WORDPAD PROQRAMI', 10),
    ('inf-3-metn', 'inf-3-metn-metnlerle',
     'MƏTNLƏRLƏ İŞ', 20),
    ('inf-3-metn', 'inf-3-metn-seklin-elave',
     'MƏTNƏ ŞƏKLİN ƏLAVƏ EDİLMƏSİ', 30),
    ('inf-3-metn', 'inf-3-metn-sozlerin-evez',
     'MƏTNDƏ SÖZLƏRİN ƏVƏZ OLUNMASI', 40),
    ('inf-3-metn', 'inf-3-metn-komputerde-hesablamalarin',
     'KOMPÜTERDƏ HESABLAMALARIN APARILMASI', 50),
    ('inf-3-metn', 'inf-3-metn-sual-tapsiriqlar',
     'Sual və tapşırıqlar', 60),
    --  ============  4-cu sinif  ============
    --  1. INFORMASIYA  (inf-4-informasiya)
    ('inf-4-informasiya', 'inf-4-informasiya-texnikada',
     'TEXNİKADA İNFORMASİYA', 10),
    ('inf-4-informasiya', 'inf-4-informasiya-texnologiyalar',
     'İNFORMASİYA TEXNOLOGİYALARI', 20),
    ('inf-4-informasiya', 'inf-4-informasiya-komputer',
     'KOMPÜTER VƏ İNFORMASİYA', 30),
    ('inf-4-informasiya', 'inf-4-informasiya-oturme-vasiteleri',
     'İNFORMASİYANI ÖTÜRMƏ VASİTƏLƏRİ', 40),
    ('inf-4-informasiya', 'inf-4-informasiya-elektron-poct',
     'ELEKTRON POÇT VƏ İNTERNET', 50),
    ('inf-4-informasiya', 'inf-4-informasiya-yoxlama-suallari',
     'Yoxlama sualları', 60),
    --  2. ALQORITM  (inf-4-mentiq)
    ('inf-4-mentiq', 'inf-4-mentiq-elametlerin-cedvel',
     'ƏLAMƏTLƏRİN CƏDVƏL ŞƏKLİNDƏ TƏSVİRİ', 10),
    ('inf-4-mentiq', 'inf-4-mentiq-qrup-altqrup',
     'QRUP VƏ ALTQRUP', 20),
    ('inf-4-mentiq', 'inf-4-mentiq-sozleri-murekkeb',
     '“VƏ”, “VƏ YA” SÖZLƏRİ OLAN MÜRƏKKƏB MÜLAHİZƏLƏR', 30),
    ('inf-4-mentiq', 'inf-4-mentiq-mulahizelerin-sxemlerle',
     'MÜLAHİZƏLƏRİN SXEMLƏRLƏ GÖSTƏRİLMƏSİ', 40),
    ('inf-4-mentiq', 'inf-4-mentiq-eger-onda',
     '“ƏGƏR - ONDA” QAYDASI', 50),
    ('inf-4-mentiq', 'inf-4-mentiq-muhakimeler',
     'MƏNTİQİ MÜHAKİMƏLƏR', 60),
    --  2. ALQORITM  (inf-4-alqoritm)
    ('inf-4-alqoritm', 'inf-4-alqoritm-icracisi',
     'ALQORİTMİN İCRAÇISI', 10),
    ('inf-4-alqoritm', 'inf-4-alqoritm-meshur-icracilar',
     'MƏŞHUR İCRAÇILAR', 20),
    ('inf-4-alqoritm', 'inf-4-alqoritm-budaqlanma',
     'ALQORİTMLƏRDƏ BUDAQLANMA', 30),
    ('inf-4-alqoritm', 'inf-4-alqoritm-dovri',
     'DÖVRİ ALQORİTMLƏR', 40),
    ('inf-4-alqoritm', 'inf-4-alqoritm-yoxlama-suallar',
     'Yoxlama suallar', 50),
    --  3. KOMPUTERDE IS  (inf-4-qrafik)
    ('inf-4-qrafik', 'inf-4-qrafik-redaktorun-aletleri',
     'QRAFİK REDAKTORUN ALƏTLƏRİ', 10),
    ('inf-4-qrafik', 'inf-4-qrafik-seklin-formasinin',
     'ŞƏKLİN FORMASININ DƏYİŞDİRİLMƏSİ', 20),
    ('inf-4-qrafik', 'inf-4-qrafik-simmetrik-fiqurlarin',
     'SİMMETRİK FİQURLARIN ÇƏKİLMƏSİ', 30),
    ('inf-4-qrafik', 'inf-4-qrafik-mozaika-naxislarin',
     'MOZAİKA VƏ NAXIŞLARIN QURULMASI', 40),
    ('inf-4-qrafik', 'inf-4-qrafik-resmin-cap',
     'RƏSMİN ÇAP EDİLMƏSİ', 50),
    ('inf-4-qrafik', 'inf-4-qrafik-metnli-sekiller',
     'MƏTNLİ ŞƏKİLLƏR', 60),
    --  3. KOMPUTERDE IS  (inf-4-kompyuter)
    ('inf-4-kompyuter', 'inf-4-kompyuter-metnlerin-yigilmasi',
     'MƏTNLƏRİN YIĞILMASI', 10),
    ('inf-4-kompyuter', 'inf-4-kompyuter-metnlerle',
     'MƏTNLƏRLƏ İŞ', 20),
    ('inf-4-kompyuter', 'inf-4-kompyuter-metnin-nizamlanmasi',
     'MƏTNİN NİZAMLANMASI', 30),
    ('inf-4-kompyuter', 'inf-4-kompyuter-senedin-capa',
     'SƏNƏDİN ÇAPA HAZIRLANMASI', 40),
    ('inf-4-kompyuter', 'inf-4-kompyuter-kitab-nece',
     'BU KİTAB NECƏ HAZIRLANIB', 50),
    ('inf-4-kompyuter', 'inf-4-kompyuter-yoxlama-suallar',
     'Yoxlama suallar', 60),
    --  ============  5-ci sinif  ============
    --  1. INFORMASIYA  (inf-5-informasiya)
    ('inf-5-informasiya', 'inf-5-informasiya-nedir',
     'İnformasiya nədir', 10),
    ('inf-5-informasiya', 'inf-5-informasiya-kodlasdirilmas',
     'İnformasiyanın kodlaşdırılması', 20),
    ('inf-5-informasiya', 'inf-5-informasiya-modeli',
     'İnformasiya modeli', 30),
    ('inf-5-informasiya', 'inf-5-informasiya-olcmek-olarmi',
     'İnformasiyanı ölçmək olarmı?', 40),
    ('inf-5-informasiya', 'inf-5-informasiya-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 50),
    --  2. KOMPUTER  (inf-5-kompyuter)
    ('inf-5-kompyuter', 'inf-5-kompyuter-ferdi-komputerler',
     'Fərdi kompüterlər', 10),
    ('inf-5-kompyuter', 'inf-5-kompyuter-komputer-nece',
     'Kompüter necə işləyir', 20),
    ('inf-5-kompyuter', 'inf-5-kompyuter-masasi',
     'İş masası', 30),
    ('inf-5-kompyuter', 'inf-5-kompyuter-menyu',
     'Menyu', 40),
    ('inf-5-kompyuter', 'inf-5-kompyuter-fayllar-qovluqlar',
     'Fayllar və qovluqlar', 50),
    ('inf-5-kompyuter', 'inf-5-kompyuter-pencere',
     'Pəncərə', 60),
    ('inf-5-kompyuter', 'inf-5-kompyuter-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 70),
    --  3. TETBIQI PROQRAMLAR  (inf-5-tetbiqi)
    ('inf-5-tetbiqi', 'inf-5-tetbiqi-komputerde-sekil',
     'Kompüterdə şəkil çəkirəm', 10),
    ('inf-5-tetbiqi', 'inf-5-tetbiqi-seklin-fraqmenti',
     'Şəklin fraqmenti ilə iş', 20),
    ('inf-5-tetbiqi', 'inf-5-tetbiqi-fraqmentin-eyilmesi',
     'Fraqmentin əyilməsi və döndərilməsi', 30),
    ('inf-5-tetbiqi', 'inf-5-tetbiqi-metn-redaktoru',
     'Mətn redaktoru', 40),
    ('inf-5-tetbiqi', 'inf-5-tetbiqi-sekilli-metnler',
     'Şəkilli mətnlər', 50),
    ('inf-5-tetbiqi', 'inf-5-tetbiqi-redaktorunda-sekli',
     'Mətn redaktorunda şəkli necə çəkmək olar', 60),
    ('inf-5-tetbiqi', 'inf-5-tetbiqi-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 70),
    --  4. ALQORITM VE PROQRAM  (inf-5-alqoritm)
    ('inf-5-alqoritm', 'inf-5-alqoritm-alqoritm',
     'Alqoritm', 10),
    ('inf-5-alqoritm', 'inf-5-alqoritm-nece-teqdim',
     'Alqoritmi necə təqdim etmək olar', 20),
    ('inf-5-alqoritm', 'inf-5-alqoritm-eylenceli-meseleler',
     'Əyləncəli məsələlər', 30),
    ('inf-5-alqoritm', 'inf-5-alqoritm-proqram-nedir',
     'Proqram nədir', 40),
    ('inf-5-alqoritm', 'inf-5-alqoritm-ise-baslayir',
     'Bağa işə başlayır', 50),
    ('inf-5-alqoritm', 'inf-5-alqoritm-sade-fiqurlar',
     'Bağa sadə fiqurlar çəkir', 60),
    ('inf-5-alqoritm', 'inf-5-alqoritm-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 70),
    --  5. INTERNET  (inf-5-internet)
    ('inf-5-internet', 'inf-5-internet-informasiya-resurslari',
     'İnformasiya resursları', 10),
    ('inf-5-internet', 'inf-5-internet-internet',
     'İnternet', 20),
    ('inf-5-internet', 'inf-5-internet-dunya-horumcek',
     'Dünya hörümçək toru', 30),
    ('inf-5-internet', 'inf-5-internet-informasiyanin-axtarisi',
     'İnternetdə informasiyanın axtarışı', 40),
    ('inf-5-internet', 'inf-5-internet-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 50),
    --  ============  6-ci sinif  ============
    --  1. KOMPUTER  (inf-6-kompyuter)
    ('inf-6-kompyuter', 'inf-6-kompyuter-komputer-isleyir',
     'Kompüter necə işləyir', 10),
    ('inf-6-kompyuter', 'inf-6-kompyuter-harada-saxlanilir',
     'İnformasiya harada saxlanılır', 20),
    ('inf-6-kompyuter', 'inf-6-kompyuter-ededi-kodlasdirilir',
     'Ədədi informasiya necə kodlaşdırılır', 30),
    ('inf-6-kompyuter', 'inf-6-kompyuter-qeder-yer',
     'İnformasiya nə qədər yer tutur', 40),
    --  2. PROQRAM TEMINATI  (inf-6-proqram-teminati)
    ('inf-6-proqram-teminati', 'inf-6-proqram-teminati-baslatmagin-nece',
     'Proqramı başlatmağın bir neçə üsulu', 10),
    ('inf-6-proqram-teminati', 'inf-6-proqram-teminati-seklin-komputerde',
     'Şəklin kompüterdə saxlanması və çapı', 20),
    ('inf-6-proqram-teminati', 'inf-6-proqram-teminati-metnin-gorunusunun',
     'Mətnin görünüşünün yaxşılaşdırılması', 30),
    ('inf-6-proqram-teminati', 'inf-6-proqram-teminati-abzasin-formatlanmasi',
     'Abzasın formatlanması', 40),
    ('inf-6-proqram-teminati', 'inf-6-proqram-teminati-elektron-teqdimatlar',
     'Elektron təqdimatlar', 50),
    ('inf-6-proqram-teminati', 'inf-6-proqram-teminati-slaydlarla',
     'Slaydlarla iş', 60),
    ('inf-6-proqram-teminati', 'inf-6-proqram-teminati-obyektin-informasiya',
     'Obyektin informasiya modeli', 70),
    --  3. ALQORITM  (inf-6-alqoritm)
    ('inf-6-alqoritm', 'inf-6-alqoritm-xasseleri',
     'Alqoritmin xassələri', 10),
    ('inf-6-alqoritm', 'inf-6-alqoritm-novleri',
     'Alqoritmin növləri', 20),
    ('inf-6-alqoritm', 'inf-6-alqoritm-dovri',
     'Dövri alqoritmlər', 30),
    ('inf-6-alqoritm', 'inf-6-alqoritm-eylenceli-meseleler',
     'Əyləncəli məsələlər', 40),
    --  4. PROQRAMLASDIRMA  (inf-6-proqramlasdirma)
    ('inf-6-proqramlasdirma', 'inf-6-proqramlasdirma-proqramda-deyisenler',
     'Proqramda dəyişənlər', 10),
    ('inf-6-proqramlasdirma', 'inf-6-proqramlasdirma-muhitinde-secim',
     'Proqramlaşdırma mühitində seçim', 20),
    ('inf-6-proqramlasdirma', 'inf-6-proqramlasdirma-muhitinde-dovr',
     'Proqramlaşdırma mühitində dövr', 30),
    ('inf-6-proqramlasdirma', 'inf-6-proqramlasdirma-dovrler-naxislar',
     'Dövrlər və naxışlar', 40),
    ('inf-6-proqramlasdirma', 'inf-6-proqramlasdirma-muhitinde-musiqi',
     'Proqramlaşdırma mühitində musiqi', 50),
    --  5. INTERNET  (inf-6-internet)
    ('inf-6-internet', 'inf-6-internet-informasiya-resurslari',
     'İnformasiya resursları ilə iş mərhələləri', 10),
    ('inf-6-internet', 'inf-6-internet-dunya-horumcek',
     'Dünya hörümçək torunda gəzişmə', 20),
    ('inf-6-internet', 'inf-6-internet-axtaris',
     'İnternetdə axtarış', 30),
    ('inf-6-internet', 'inf-6-internet-elektron-poct',
     'Elektron poçt', 40),
    ('inf-6-internet', 'inf-6-internet-poctla-mektublasma',
     'Elektron poçtla məktublaşma', 50),
    --  ============  7-ci sinif  ============
    --  1. KOMPUTER  (inf-7-kompyuter)
    ('inf-7-kompyuter', 'inf-7-kompyuter-komputerin-merkezi',
     'Kompüterin mərkəzi qurğusu - prosessor', 10),
    ('inf-7-kompyuter', 'inf-7-kompyuter-giris-qurgulari',
     'Giriş qurğuları', 20),
    ('inf-7-kompyuter', 'inf-7-kompyuter-cixis-qurgulari',
     'Çıxış qurğuları', 30),
    ('inf-7-kompyuter', 'inf-7-kompyuter-proqram-teminatinin',
     'Proqram təminatının növləri', 40),
    ('inf-7-kompyuter', 'inf-7-kompyuter-fayl-qovluq',
     'Fayl və qovluq', 50),
    ('inf-7-kompyuter', 'inf-7-kompyuter-fayl-qovluqlarla',
     'Fayl və qovluqlarla iş', 60),
    --  2. TETBIQI PROQRAMLAR  (inf-7-tetbiqi)
    ('inf-7-tetbiqi', 'inf-7-tetbiqi-informasiya-modeli',
     'Cədvəl informasiya modeli', 10),
    ('inf-7-tetbiqi', 'inf-7-tetbiqi-metn-cedvel',
     'Mətn redaktorunda cədvəl', 20),
    ('inf-7-tetbiqi', 'inf-7-tetbiqi-metn-diaqram',
     'Mətn redaktorunda diaqram', 30),
    ('inf-7-tetbiqi', 'inf-7-tetbiqi-seklin-atributlari',
     'Şəklin atributları', 40),
    ('inf-7-tetbiqi', 'inf-7-tetbiqi-slaydlarla',
     'Slaydlarla iş', 50),
    --  3. INFORMASIYA  (inf-7-informasiya)
    ('inf-7-informasiya', 'inf-7-informasiya-esas-xasseleri',
     'İnformasiyanın əsas xassələri', 10),
    ('inf-7-informasiya', 'inf-7-informasiya-xassesine-qruplasdirilma',
     'Xassəsinə görə informasiyanın qruplaşdırılması', 20),
    ('inf-7-informasiya', 'inf-7-informasiya-say-sistemleri',
     'Say sistemləri', 30),
    ('inf-7-informasiya', 'inf-7-informasiya-kodlasdirilmis-hecmi',
     'Kodlaşdırılmış informasiyanın həcmi', 40),
    ('inf-7-informasiya', 'inf-7-informasiya-bagli-meseleler',
     'Say sistemləri ilə bağlı məsələlər', 50),
    --  4. PROQRAMLASDIRMA  (inf-7-proqramlasdirma)
    ('inf-7-proqramlasdirma', 'inf-7-proqramlasdirma-komputerde-meselelerin',
     'Kompüterdə məsələlərin həlli', 10),
    ('inf-7-proqramlasdirma', 'inf-7-proqramlasdirma-riyaziyyatci-baga',
     'Riyaziyyatçı Bağa', 20),
    ('inf-7-proqramlasdirma', 'inf-7-proqramlasdirma-altproqram',
     'Altproqram', 30),
    ('inf-7-proqramlasdirma', 'inf-7-proqramlasdirma-altproqramda-deyisenler',
     'Altproqramda dəyişənlər', 40),
    ('inf-7-proqramlasdirma', 'inf-7-proqramlasdirma-mesele-helli',
     'Məsələ həlli', 50),
    --  5. INTERNET  (inf-7-internet)
    ('inf-7-internet', 'inf-7-internet-nece-baglanmali',
     'İnternetə necə bağlanmalı', 10),
    ('inf-7-internet', 'inf-7-internet-fayllarin-elektron',
     'Faylların elektron poçtla göndərilməsi', 20),
    ('inf-7-internet', 'inf-7-internet-daxil-mektublarla',
     'Daxil olan məktublarla iş', 30),
    ('inf-7-internet', 'inf-7-internet-informasiya-kommunikasiya',
     'İnformasiya-kommunikasiya texnologiyaları', 40),
    ('inf-7-internet', 'inf-7-internet-ikt-heyatimizda',
     'İKT həyatımızda. Debat dərs', 50),
    --  ============  8-ci sinif  ============
    --  1. INFORMASIYA  (inf-8-informasiya)
    ('inf-8-informasiya', 'inf-8-informasiya-kodlasdirilmas',
     'İnformasiyanın kodlaşdırılması', 10),
    ('inf-8-informasiya', 'inf-8-informasiya-2-lik',
     '2-lik, 8-lik və 16-lıq say sistemləri', 20),
    ('inf-8-informasiya', 'inf-8-informasiya-sisteminden-basqasina',
     'Bir say sistemindən başqasına keçid', 30),
    ('inf-8-informasiya', 'inf-8-informasiya-olculmesi',
     'İnformasiyanın ölçülməsi', 40),
    ('inf-8-informasiya', 'inf-8-informasiya-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 50),
    --  2. MULTIMEDIA  (inf-8-multimedia)
    ('inf-8-multimedia', 'inf-8-multimedia-qurgulari',
     'Multimedia qurğuları', 10),
    ('inf-8-multimedia', 'inf-8-multimedia-elektron-animasiya',
     'Elektron təqdimatda animasiya', 20),
    ('inf-8-multimedia', 'inf-8-multimedia-ses-video',
     'Təqdimatda səs və video', 30),
    ('inf-8-multimedia', 'inf-8-multimedia-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 40),
    --  3. PROQRAMLASDIRMA  (inf-8-proqramlasdirma)
    ('inf-8-proqramlasdirma', 'inf-8-proqramlasdirma-nece-hazirlanir',
     'Proqram necə hazırlanır', 10),
    ('inf-8-proqramlasdirma', 'inf-8-proqramlasdirma-python-dilinde',
     'Python dilində ilk proqram', 20),
    ('inf-8-proqramlasdirma', 'inf-8-proqramlasdirma-proqramda-kemiyyetler',
     'Proqramda kəmiyyətlər', 30),
    ('inf-8-proqramlasdirma', 'inf-8-proqramlasdirma-sert-operatoru',
     'Şərt operatoru', 40),
    ('inf-8-proqramlasdirma', 'inf-8-proqramlasdirma-proqramda-dovr',
     'Proqramda dövr', 50),
    ('inf-8-proqramlasdirma', 'inf-8-proqramlasdirma-saygacli-dovrler',
     'Sayğaclı dövrlər', 60),
    ('inf-8-proqramlasdirma', 'inf-8-proqramlasdirma-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 70),
    --  4. KOMPUTER  (inf-8-kompyuter)
    ('inf-8-kompyuter', 'inf-8-kompyuter-masasinin-nizamlanmasi',
     'İş masasının nizamlanması', 10),
    ('inf-8-kompyuter', 'inf-8-kompyuter-informasiya-modelinin',
     'İnformasiya modelinin ağac forması', 20),
    ('inf-8-kompyuter', 'inf-8-kompyuter-fayllarin-axtarisi',
     'Faylların axtarışı', 30),
    ('inf-8-kompyuter', 'inf-8-kompyuter-agacsekilli-struktur',
     'Ağacşəkilli struktur əsasında məsələ həlli', 40),
    ('inf-8-kompyuter', 'inf-8-kompyuter-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 50),
    --  5. TETBIQI PROQRAMLAR  (inf-8-tetbiqi)
    ('inf-8-tetbiqi', 'inf-8-tetbiqi-ucolculu-qrafika',
     'Üçölçülü qrafika', 10),
    ('inf-8-tetbiqi', 'inf-8-tetbiqi-tiller-uzler',
     'Tillər və üzlər', 20),
    ('inf-8-tetbiqi', 'inf-8-tetbiqi-modellerin-qurulmasi',
     'Üçölçülü modellərin qurulması', 30),
    ('inf-8-tetbiqi', 'inf-8-tetbiqi-metn-redaktorunun',
     'Mətn redaktorunun obyektləri', 40),
    ('inf-8-tetbiqi', 'inf-8-tetbiqi-elektron-cedvel',
     'Elektron cədvəl', 50),
    ('inf-8-tetbiqi', 'inf-8-tetbiqi-dusturlarla',
     'Düsturlarla iş', 60),
    ('inf-8-tetbiqi', 'inf-8-tetbiqi-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 70),
    --  6. INFORMASIYA CEMIYYETI VE INTERNET  (inf-8-internet)
    ('inf-8-internet', 'inf-8-internet-cemiyyetin-informasiyalas',
     'Cəmiyyətin informasiyalaşdırılması', 10),
    ('inf-8-internet', 'inf-8-internet-komputer-sebekeleri',
     'Kompüter şəbəkələri', 20),
    ('inf-8-internet', 'inf-8-internet-xidmetleri',
     'İnternet xidmətləri', 30),
    ('inf-8-internet', 'inf-8-internet-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 40),
    --  ============  9-cu sinif  ============
    --  1. KODLASDIRMA  (inf-9-kodlasdirma)
    ('inf-9-kodlasdirma', 'inf-9-kodlasdirma-rastr-qrafikasi',
     'Rastr qrafikası', 10),
    ('inf-9-kodlasdirma', 'inf-9-kodlasdirma-vektor-qrafikasi',
     'Vektor qrafikası', 20),
    ('inf-9-kodlasdirma', 'inf-9-kodlasdirma-vektor-redaktorunda',
     'Vektor redaktorunda iş', 30),
    ('inf-9-kodlasdirma', 'inf-9-kodlasdirma-qrafik-informasiyanin',
     'Qrafik informasiyanın kodlaşdırılması', 40),
    ('inf-9-kodlasdirma', 'inf-9-kodlasdirma-ses-informasiyasin',
     'Səs informasiyasının kodlaşdırılması', 50),
    ('inf-9-kodlasdirma', 'inf-9-kodlasdirma-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 60),
    --  2. KOMPUTER  (inf-9-komputer)
    ('inf-9-komputer', 'inf-9-komputer-esas-xarakteristika',
     'Kompüterin əsas xarakteristikaları', 10),
    ('inf-9-komputer', 'inf-9-komputer-idareetme-paneli',
     'İdarəetmə paneli', 20),
    ('inf-9-komputer', 'inf-9-komputer-xidmeti-defraqmentleme',
     'Xidməti proqramlar. Defraqmentləmə', 30),
    ('inf-9-komputer', 'inf-9-komputer-diskin-temizlenmesi',
     'Xidməti proqramlar. Diskin təmizlənməsi', 40),
    ('inf-9-komputer', 'inf-9-komputer-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 50),
    --  3. ELEKTRON CEDVELLER  (inf-9-cedvel)
    ('inf-9-cedvel', 'inf-9-cedvel-mutleq-nisbi',
     'Mütləq və nisbi istinadlar', 10),
    ('inf-9-cedvel', 'inf-9-cedvel-elektron-funksiyalar',
     'Elektron cədvəldə funksiyalar', 20),
    ('inf-9-cedvel', 'inf-9-cedvel-verilenlerin-vizuallasdiril',
     'Verilənlərin vizuallaşdırılması. Diaqramlar', 30),
    ('inf-9-cedvel', 'inf-9-cedvel-mesele-helli',
     'Məsələ həlli', 40),
    ('inf-9-cedvel', 'inf-9-cedvel-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 50),
    --  4. PROQRAMLASDIRMA  (inf-9-proqramlasdirma)
    ('inf-9-proqramlasdirma', 'inf-9-proqramlasdirma-ededlerle',
     'Ədədlərlə iş', 10),
    ('inf-9-proqramlasdirma', 'inf-9-proqramlasdirma-setirler',
     'Sətirlər', 20),
    ('inf-9-proqramlasdirma', 'inf-9-proqramlasdirma-siyahilar',
     'Siyahılar', 30),
    ('inf-9-proqramlasdirma', 'inf-9-proqramlasdirma-funksiya',
     'Funksiya', 40),
    ('inf-9-proqramlasdirma', 'inf-9-proqramlasdirma-mesele-helli',
     'Məsələ həlli', 50),
    ('inf-9-proqramlasdirma', 'inf-9-proqramlasdirma-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 60),
    --  5. INFORMASIYA TEXNOLOGIYALARI  (inf-9-texnologiya)
    ('inf-9-texnologiya', 'inf-9-texnologiya-informasiya-modeli',
     'Qraf informasiya modeli', 10),
    ('inf-9-texnologiya', 'inf-9-texnologiya-qraf-meseleleri',
     'Qraf məsələləri', 20),
    ('inf-9-texnologiya', 'inf-9-texnologiya-sebeke-topologiyalari',
     'Şəbəkə topologiyaları', 30),
    ('inf-9-texnologiya', 'inf-9-texnologiya-veb-sayt',
     'Veb-sayt', 40),
    ('inf-9-texnologiya', 'inf-9-texnologiya-veb-sablonlari',
     'Veb-sayt şablonları', 50),
    ('inf-9-texnologiya', 'inf-9-texnologiya-proqramlasdirm-dilleri',
     'Veb-proqramlaşdırma dilləri', 60),
    ('inf-9-texnologiya', 'inf-9-texnologiya-internetde-unvanlama',
     'İnternetdə ünvanlama', 70),
    ('inf-9-texnologiya', 'inf-9-texnologiya-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 80),
    --  ============  10-cu sinif  ============
    --  1. INFORMASIYA  (inf-10-informasiya)
    ('inf-10-informasiya', 'inf-10-informasiya-informatika',
     'İnformasiya və informatika', 10),
    ('inf-10-informasiya', 'inf-10-informasiya-prosesleri',
     'İnformasiya prosesləri', 20),
    ('inf-10-informasiya', 'inf-10-informasiya-miqdari',
     'İnformasiyanın miqdarı', 30),
    ('inf-10-informasiya', 'inf-10-informasiya-qorunmasi',
     'İnformasiyanın qorunması', 40),
    ('inf-10-informasiya', 'inf-10-informasiya-komputer-viruslari',
     'Kompüter virusları', 50),
    ('inf-10-informasiya', 'inf-10-informasiya-antivirus-proqramlari',
     'Antivirus proqramları', 60),
    ('inf-10-informasiya', 'inf-10-informasiya-komputer-cinayetkarligi',
     'Kompüter cinayətkarlığı', 70),
    ('inf-10-informasiya', 'inf-10-informasiya-kriptoqrafiya',
     'Kriptoqrafiya', 80),
    ('inf-10-informasiya', 'inf-10-informasiya-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 90),
    --  2. MODELLESDIRME  (inf-10-model)
    ('inf-10-model', 'inf-10-model-anlayisi',
     '"Model" anlayışı', 10),
    ('inf-10-model', 'inf-10-model-novleri',
     'Modellərin növləri', 20),
    ('inf-10-model', 'inf-10-model-informasiya-teqdimolunmasi',
     'İnformasiya modellərinin təqdimolunması', 30),
    ('inf-10-model', 'inf-10-model-informasiya-hazirlanmasi',
     'İnformasiya modelinin hazırlanması', 40),
    ('inf-10-model', 'inf-10-model-komputer',
     'Kompüter modeli', 50),
    ('inf-10-model', 'inf-10-model-interaktiv-komputer',
     'İnteraktiv kompüter modelləri', 60),
    ('inf-10-model', 'inf-10-model-komputer-qrafikasi',
     'Kompüter qrafikası', 70),
    ('inf-10-model', 'inf-10-model-ucolculu-hazirlanmasi',
     'Üçölçülü kompüter modellərinin hazırlanması', 80),
    ('inf-10-model', 'inf-10-model-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 90),
    --  3. VERILENLER BAZASI  (inf-10-baza)
    ('inf-10-baza', 'inf-10-baza-verilenler-anlayisi',
     '"Verilənlər bazası" anlayışı', 10),
    ('inf-10-baza', 'inf-10-baza-verilenler-modeli',
     'Verilənlər modeli', 20),
    ('inf-10-baza', 'inf-10-baza-idareolunmasi-sistemi',
     'Verilənlər bazasının idarəolunması sistemi', 30),
    ('inf-10-baza', 'inf-10-baza-cedvel-strukturunun',
     'Cədvəl strukturunun yaradılması', 40),
    ('inf-10-baza', 'inf-10-baza-cedvellerarasi-elaqeler',
     'Cədvəllərarası əlaqələr', 50),
    ('inf-10-baza', 'inf-10-baza-sorgular',
     'Sorğular', 60),
    ('inf-10-baza', 'inf-10-baza-formalar',
     'Formalar', 70),
    ('inf-10-baza', 'inf-10-baza-verilenlerin-axtarisi',
     'Verilənlərin axtarışı və çeşidlənməsi', 80),
    ('inf-10-baza', 'inf-10-baza-hesabatlar',
     'Hesabatlar', 90),
    ('inf-10-baza', 'inf-10-baza-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 100),
    --  4. SEBEKELER  (inf-10-sebeke)
    ('inf-10-sebeke', 'inf-10-sebeke-komputer-onlarin',
     'Kompüter şəbəkələri və onların təsnifatı', 10),
    ('inf-10-sebeke', 'inf-10-sebeke-avadanliqlari',
     'Şəbəkə avadanlıqları', 20),
    ('inf-10-sebeke', 'inf-10-sebeke-lokal-qosulmasi',
     'Kompüterin lokal şəbəkəyə qoşulması', 30),
    ('inf-10-sebeke', 'inf-10-sebeke-qurgularindan-birge',
     'Şəbəkə qurğularından birgə istifadə', 40),
    ('inf-10-sebeke', 'inf-10-sebeke-fiziki-olaraq',
     'Kompüterin fiziki olaraq İnternetə bağlanması', 50),
    ('inf-10-sebeke', 'inf-10-sebeke-emeliyyat-sisteminin',
     'Əməliyyat sisteminin köməyi ilə İnternetə qoşulma', 60),
    ('inf-10-sebeke', 'inf-10-sebeke-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 70),
    --  5. VEB-PROQRAMLASDIRMA  (inf-10-veb)
    ('inf-10-veb', 'inf-10-veb-veb-proqramlasdirm',
     'Veb-proqramlaşdırma nədir', 10),
    ('inf-10-veb', 'inf-10-veb-hipermetni-nisanlama',
     'Hipermətni nişanlama dili - HTML', 20),
    ('inf-10-veb', 'inf-10-veb-saytin-tertibatinin',
     'Saytın tərtibatının özəllikləri', 30),
    ('inf-10-veb', 'inf-10-veb-cedveller-istinadlar',
     'Cədvəllər və istinadlar', 40),
    ('inf-10-veb', 'inf-10-veb-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 50),
    --  6. INFORMASIYA CEMIYYETI  (inf-10-veb)
    ('inf-10-veb', 'inf-10-veb-cemiyyetinin-inkisaf',
     'İnformasiya cəmiyyətinin inkişaf mərhələləri', 60),
    ('inf-10-veb', 'inf-10-veb-informasiya-medeniyyeti',
     'İnformasiya mədəniyyəti', 70),
    ('inf-10-veb', 'inf-10-veb-internetde-unsiyyet',
     'İnternetdə ünsiyyət. Şəbəkə etikası', 80),
    ('inf-10-veb', 'inf-10-veb-telekonfrans',
     'Telekonfrans', 90),
    ('inf-10-veb', 'inf-10-veb-elektron-hokumet',
     'Elektron hökumət', 100),
    ('inf-10-veb', 'inf-10-veb-elektron-tehsil',
     'Elektron təhsil', 110),
    ('inf-10-veb', 'inf-10-veb-kitabxana-secki',
     'E-kitabxana, e-seçki, e-ticarət', 120),
    ('inf-10-veb', 'inf-10-veb-umumilesdirici-sual-tapsiriqlar',
     'Ümumiləşdirici sual və tapşırıqlar', 130),
    --  ============  11-ci sinif  ============
    --  1. INFORMASIYA SISTEMLERI  (inf-11-sistemler)
    ('inf-11-sistemler', 'inf-11-sistemler-sistemi-elementleri',
     'İnformasiya sistemi və onun elementləri', 10),
    ('inf-11-sistemler', 'inf-11-sistemler-informasiya-tesnifati',
     'İnformasiya sistemlərinin təsnifatı', 20),
    ('inf-11-sistemler', 'inf-11-sistemler-cografi-informasiya',
     'Coğrafi informasiya sistemləri', 30),
    ('inf-11-sistemler', 'inf-11-sistemler-suni-intellekt',
     'Süni intellekt', 40),
    ('inf-11-sistemler', 'inf-11-sistemler-ekspert',
     'Ekspert sistemləri', 50),
    ('inf-11-sistemler', 'inf-11-sistemler-axtaris',
     'Axtarış sistemləri', 60),
    ('inf-11-sistemler', 'inf-11-sistemler-boyuk-verilenler',
     '"Böyük verilənlər" texnologiyası', 70),
    ('inf-11-sistemler', 'inf-11-sistemler-informasiya-cemiyyeti',
     'İnformasiya cəmiyyəti', 80),
    ('inf-11-sistemler', 'inf-11-sistemler-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 90),
    --  2. MODELLESDIRME  (inf-11-modellesdirme)
    ('inf-11-modellesdirme', 'inf-11-modellesdirme-komputer',
     'Kompüter modelləşdirməsi', 10),
    ('inf-11-modellesdirme', 'inf-11-modellesdirme-elektron-cedvel',
     'Elektron cədvəl proqramında modelləşdirmə', 20),
    ('inf-11-modellesdirme', 'inf-11-modellesdirme-statistik-verilenler',
     'Statistik verilənlər əsasında proseslərin modelləşdirilməsi', 30),
    ('inf-11-modellesdirme', 'inf-11-modellesdirme-proqramlasdirm-dillerinin',
     'Proqramlaşdırma dillərinin köməyi ilə riyazi məsələlərin modelləşdirilməsi', 40),
    ('inf-11-modellesdirme', 'inf-11-modellesdirme-ucolculu-qrafik',
     'Üçölçülü qrafik modellər', 50),
    ('inf-11-modellesdirme', 'inf-11-modellesdirme-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 60),
    --  3. VERILENLER BAZASI  (inf-11-baza-layihe)
    ('inf-11-baza-layihe', 'inf-11-baza-layihe-merheleleri',
     'Layihə və onun mərhələləri', 10),
    ('inf-11-baza-layihe', 'inf-11-baza-layihe-verilenler',
     'Verilənlər bazasının layihələndirilməsi', 20),
    ('inf-11-baza-layihe', 'inf-11-baza-layihe-telebeler-verilenler',
     '"Tələbələr" verilənlər bazası layihəsi', 30),
    ('inf-11-baza-layihe', 'inf-11-baza-layihe-azerbaycan-kinosu',
     '"Azərbaycan kinosu" verilənlər bazası', 40),
    ('inf-11-baza-layihe', 'inf-11-baza-layihe-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 50),
    --  4. SEBEKE TEXNOLOGIYALARI  (inf-11-sebeke-tex)
    ('inf-11-sebeke-tex', 'inf-11-sebeke-tex-komputerlerin-unsiyyeti',
     'Şəbəkədə kompüterlərin "ünsiyyəti"', 10),
    ('inf-11-sebeke-tex', 'inf-11-sebeke-tex-arxitekturasi',
     'Şəbəkə arxitekturası', 20),
    ('inf-11-sebeke-tex', 'inf-11-sebeke-tex-simsiz-texnologiyalar',
     'Simsiz şəbəkə texnologiyaları', 30),
    ('inf-11-sebeke-tex', 'inf-11-sebeke-tex-mobil-rabite',
     'Mobil rabitə texnologiyaları', 40),
    ('inf-11-sebeke-tex', 'inf-11-sebeke-tex-internet-xidmetleri',
     'İnternet xidmətləri', 50),
    ('inf-11-sebeke-tex', 'inf-11-sebeke-tex-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 60),
    --  5. KOMPUTER  (inf-11-komputer-veb)
    ('inf-11-komputer-veb', 'inf-11-komputer-veb-idareetme-paneli',
     'İdarəetmə paneli', 10),
    ('inf-11-komputer-veb', 'inf-11-komputer-veb-sesin-edilmesi',
     'Səsin idarə edilməsi', 20),
    ('inf-11-komputer-veb', 'inf-11-komputer-veb-elektrik-enerjisi',
     'Kompüterin elektrik enerjisi sərfiyyatının idarə edilməsi', 30),
    ('inf-11-komputer-veb', 'inf-11-komputer-veb-istifadeci-hesablari',
     'İstifadəçi hesabları və ailə təhlükəsizliyi', 40),
    ('inf-11-komputer-veb', 'inf-11-komputer-veb-uzaqdan-edilmesi',
     'Kompüterin uzaqdan idarə edilməsi', 50),
    ('inf-11-komputer-veb', 'inf-11-komputer-veb-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 60),
    --  6. VEB-LAYIHE  (inf-11-komputer-veb)
    ('inf-11-komputer-veb', 'inf-11-komputer-veb-sayt-layihesi',
     'Veb-sayt layihəsi', 70),
    ('inf-11-komputer-veb', 'inf-11-komputer-veb-word-sehifenin',
     'Word proqramında veb-səhifənin hazırlanması', 80),
    ('inf-11-komputer-veb', 'inf-11-komputer-veb-excel-cedvellerinin',
     'Excel cədvəllərinin veb-səhifə kimi saxlanması', 90),
    ('inf-11-komputer-veb', 'inf-11-komputer-veb-powerpoint-teqdimat',
     'PowerPoint proqramında veb-təqdimat', 100),
    ('inf-11-komputer-veb', 'inf-11-komputer-veb-saytlarin-internetde',
     'Saytların internetdə nəşri və onların qiymətləndirilməsi', 110),
    ('inf-11-komputer-veb', 'inf-11-komputer-veb-umumilesdirici-sual-tapsiriqlar',
     'Ümumiləşdirici sual və tapşırıqlar', 120)
  ) as v(parent_slug, slug, name, sort)
  join public.topics p on p.slug = v.parent_slug
   and p.subject_id = (select id from public.subjects where slug = 'informatika')
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort,
      parent_id = excluded.parent_id, level_id = excluded.level_id;

do $$
declare k int;
begin
  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'informatika'
    join public.levels   l on l.id = p.level_id and l.code = '1';
  if k <> 28 then
    raise exception 'informatika 1-ci alt movzulari: 28 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'informatika'
    join public.levels   l on l.id = p.level_id and l.code = '2';
  if k <> 29 then
    raise exception 'informatika 2-ci alt movzulari: 29 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'informatika'
    join public.levels   l on l.id = p.level_id and l.code = '3';
  if k <> 32 then
    raise exception 'informatika 3-cu alt movzulari: 32 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'informatika'
    join public.levels   l on l.id = p.level_id and l.code = '4';
  if k <> 29 then
    raise exception 'informatika 4-cu alt movzulari: 29 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'informatika'
    join public.levels   l on l.id = p.level_id and l.code = '5';
  if k <> 31 then
    raise exception 'informatika 5-ci alt movzulari: 31 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'informatika'
    join public.levels   l on l.id = p.level_id and l.code = '6';
  if k <> 25 then
    raise exception 'informatika 6-ci alt movzulari: 25 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'informatika'
    join public.levels   l on l.id = p.level_id and l.code = '7';
  if k <> 26 then
    raise exception 'informatika 7-ci alt movzulari: 26 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'informatika'
    join public.levels   l on l.id = p.level_id and l.code = '8';
  if k <> 32 then
    raise exception 'informatika 8-ci alt movzulari: 32 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'informatika'
    join public.levels   l on l.id = p.level_id and l.code = '9';
  if k <> 30 then
    raise exception 'informatika 9-cu alt movzulari: 30 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'informatika'
    join public.levels   l on l.id = p.level_id and l.code = '10';
  if k <> 48 then
    raise exception 'informatika 10-cu alt movzulari: 48 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'informatika'
    join public.levels   l on l.id = p.level_id and l.code = '11';
  if k <> 38 then
    raise exception 'informatika 11-ci alt movzulari: 38 gozlenilirdi, % tapildi', k;
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
    join public.subjects s on s.id = t.subject_id and s.slug = 'informatika'
    join public.levels   l on l.id = t.level_id
   where t.parent_id is null and true;
  if k <> 56 then
    raise exception 'Informatika ust movzu sayi 56 deyil: %', k;
  end if;

  raise notice 'Informatika 1-11: 348 alt movzu hazir.';
end $$;
