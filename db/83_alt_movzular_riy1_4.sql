-- =====================================================================
--  83_alt_movzular_riy1_4.sql : RIYAZIYYAT 1, 3, 4 - ALT MOVZULAR
--
--  NIYE
--  db/74 (8-ci sinif) ve db/82 (5-7, 9-11) yuxari sinifleri bitirdi.
--  Ibtidai derslikler de IKIPILLELIDIR - bolmenin icinde 4-12 ders
--  var, movzu tek ders deyil.  Bu fayl 1, 3 ve 4-cu sinfi elave edir;
--  bununla riyaziyyat sona catir.
--
--  2-Cİ SINIF YOXDUR - qesden.  Portaldaki nesr kohnedir (yalniz
--  20-ye qeder gedir, cemi 2 bolme), bazadaki 9 movzu ile
--  uygunlasmir.  Portal yeni nesri qoyanda elave olunacaq.
--
--  MENBE: e-derslik.edu.az "Movzular" agaci - kitab id 419/420 (1),
--  680/681 (3), 774/775 (4).  Adlar EYNILE goturulub.
--
--  BIR BOLME IKI MOVZUYA BOLUNUB: derslikde 4-cu sinfin 7-ci bolmesi
--  "Adi ve onluq kesrler" birdir, bazada ise iki movzudur.  Kitabin
--  oz nomrelemesi ayirir - 33-cu ders "Onluq kesrler"den etibaren
--  ikinci movzuya gedir (s.19-dan sonrasi).
--
--  "Metn meseleleri" (riy-3-mesele, riy-4-mesele) derslikde bolme
--  deyil - bizim elave movzumuzdur, ona gore alt movzusu yoxdur.
--  Plan yarpaqlarla islediyi ucun o, tek ders kimi qalir.
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
--   * yazi (6): yazi qusuru (bosluq, herf)
--       1-ci   s.58   Gun, hefte, ay.
--                    -> Gun, hefte, ay
--       3-cu   s.73   51. Melumatlarin tesviri.Praktik ders
--                    -> Melumatlarin tesviri. Praktik ders
--       4-cu   s.69   20. Ikireqemli ededin ikireqemli edede bolunmesi.
--                    -> Ikireqemli ededin ikireqemli edede bolunmesi
--       4-cu   s.78   22. Sade hendesi fiqurlar.Cevre
--                    -> Sade hendesi fiqurlar. Cevre
--       4-cu   s.81   23. Bucaq.Bucagin olcusu
--                    -> Bucaq. Bucagin olcusu
--       4-cu   s.83   24. Bucagin olculmesi.Transportir
--                    -> Bucagin olculmesi. Transportir

insert into public.topics (subject_id, level_id, parent_id, slug, name, sort)
select p.subject_id, p.level_id, p.id, v.slug, v.name, v.sort
  from (values
    --  ============  1-ci sinif  ============
    --  Esyanin elameti  (riy-1-elamet)
    ('riy-1-elamet', 'riy-1-elamet-esyanin-yeri',
     'Əşyanın yeri', 10),
    ('riy-1-elamet', 'riy-1-elamet-esyanin',
     'Əşyanın əlaməti', 20),
    ('riy-1-elamet', 'riy-1-elamet-umumi',
     'Ümumiləşdirici tapşırıqlar', 30),
    --  Ededler (10-a qeder)  (riy-1-ededler-10)
    ('riy-1-ededler-10', 'riy-1-ededler-10-qeder-sayma',
     '10-a qədər sayma', 10),
    ('riy-1-ededler-10', 'riy-1-ededler-10-0-1',
     '0, 1 və 2 ədədləri', 20),
    ('riy-1-ededler-10', 'riy-1-ededler-10-3-4',
     '3, 4 və 5 ədədləri', 30),
    ('riy-1-ededler-10', 'riy-1-ededler-10-meseleler',
     'Məsələlər', 40),
    ('riy-1-ededler-10', 'riy-1-ededler-10-6-7',
     '6, 7 və 8 ədədləri', 50),
    ('riy-1-ededler-10', 'riy-1-ededler-10-9-10',
     '9 və 10 ədədləri', 60),
    ('riy-1-ededler-10', 'riy-1-ededler-10-sira-saylari',
     'Sıra sayları', 70),
    ('riy-1-ededler-10', 'riy-1-ededler-10-umumi',
     'Ümumiləşdirici tapşırıqlar', 80),
    --  Ededlerin muqayisesi  (riy-1-muqayise)
    ('riy-1-muqayise', 'riy-1-muqayise-azdir-coxdur',
     'Azdır, çoxdur', 10),
    ('riy-1-muqayise', 'riy-1-muqayise-ededlerin',
     'Ədədlərin müqayisəsi', 20),
    ('riy-1-muqayise', 'riy-1-muqayise-eded-oxu',
     'Ədəd oxu', 30),
    ('riy-1-muqayise', 'riy-1-muqayise-siralama',
     'Sıralama', 40),
    ('riy-1-muqayise', 'riy-1-muqayise-umumi',
     'Ümumiləşdirici tapşırıqlar', 50),
    --  Toplama (10-a qeder)  (riy-1-toplama-10)
    ('riy-1-toplama-10', 'riy-1-toplama-10-eded-ucluyu',
     'Ədəd üçlüyü', 10),
    ('riy-1-toplama-10', 'riy-1-toplama-10-elave-etmek',
     'Əlavə etmək, artırmaq', 20),
    ('riy-1-toplama-10', 'riy-1-toplama-10-ededlerin-toplanmasi',
     'Ədədlərin toplanması', 30),
    ('riy-1-toplama-10', 'riy-1-toplama-10-meseleler',
     'Məsələlər', 40),
    ('riy-1-toplama-10', 'riy-1-toplama-10-oxu-uzerinde',
     'Ədəd oxu üzərində toplama', 50),
    ('riy-1-toplama-10', 'riy-1-toplama-10-toplananli-ifadeler',
     'Üç toplananlı ifadələr', 60),
    ('riy-1-toplama-10', 'riy-1-toplama-10-diger-usullari',
     'Toplamanın digər üsulları', 70),
    ('riy-1-toplama-10', 'riy-1-toplama-10-umumi',
     'Ümumiləşdirici tapşırıqlar', 80),
    --  Cixma (10-a qeder)  (riy-1-cixma-10)
    ('riy-1-cixma-10', 'riy-1-cixma-10-azaltmaq',
     'Azaltmaq, çıxmaq', 10),
    ('riy-1-cixma-10', 'riy-1-cixma-10-ededlerin-cixilmasi',
     'Ədədlərin çıxılması', 20),
    ('riy-1-cixma-10', 'riy-1-cixma-10-meseleler',
     'Məsələlər', 30),
    ('riy-1-cixma-10', 'riy-1-cixma-10-eded-oxu',
     'Ədəd oxu üzərində çıxma', 40),
    ('riy-1-cixma-10', 'riy-1-cixma-10-toplama-elaqesi',
     'Toplama və çıxmanın əlaqəsi', 50),
    ('riy-1-cixma-10', 'riy-1-cixma-10-mechulun-tapilmasi',
     'Məchulun tapılması', 60),
    ('riy-1-cixma-10', 'riy-1-cixma-10-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    --  Ededler (20-ye qeder)  (riy-1-ededler-20)
    ('riy-1-ededler-20', 'riy-1-ededler-20-20-qeder',
     '20-yə qədər sayma', 10),
    ('riy-1-ededler-20', 'riy-1-ededler-20-ireli-geri',
     'İrəli və geri sayma', 20),
    ('riy-1-ededler-20', 'riy-1-ededler-20-onluq-teklik',
     'Onluq və təklik', 30),
    ('riy-1-ededler-20', 'riy-1-ededler-20-meseleler',
     'Məsələlər', 40),
    ('riy-1-ededler-20', 'riy-1-ededler-20-muqayisesi',
     'Ədədlərin müqayisəsi', 50),
    ('riy-1-ededler-20', 'riy-1-ededler-20-siralama',
     'Sıralama', 60),
    ('riy-1-ededler-20', 'riy-1-ededler-20-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    --  Hendesi fiqurlar  (riy-1-fiqurlar)
    ('riy-1-fiqurlar', 'riy-1-fiqurlar-ucbucaq-daire',
     'Üçbucaq, dairə, kvadrat, düzbucaqlı', 10),
    ('riy-1-fiqurlar', 'riy-1-fiqurlar-feza',
     'Fəza fiqurları', 20),
    ('riy-1-fiqurlar', 'riy-1-fiqurlar-tam-yari',
     'Tam, yarı', 30),
    ('riy-1-fiqurlar', 'riy-1-fiqurlar-umumi',
     'Ümumiləşdirici tapşırıqlar', 40),
    --  Toplama (20-ye qeder)  (riy-1-toplama-20)
    ('riy-1-toplama-20', 'riy-1-toplama-20-ededlerin-toplanmasi',
     'Ədədlərin toplanması', 10),
    ('riy-1-toplama-20', 'riy-1-toplama-20-10-tamamlamaqla',
     '10-a tamamlamaqla toplama', 20),
    ('riy-1-toplama-20', 'riy-1-toplama-20-meseleler',
     'Məsələlər', 30),
    ('riy-1-toplama-20', 'riy-1-toplama-20-diger-usullari',
     'Toplamanın digər üsulları', 40),
    ('riy-1-toplama-20', 'riy-1-toplama-20-umumi',
     'Ümumiləşdirici tapşırıqlar', 50),
    --  Cixma (20-ye qeder)  (riy-1-cixma-20)
    ('riy-1-cixma-20', 'riy-1-cixma-20-ededlerin-cixilmasi',
     'Ədədlərin çıxılması', 10),
    ('riy-1-cixma-20', 'riy-1-cixma-20-10-qeder',
     '10-a qədər azaltmaqla çıxma', 20),
    ('riy-1-cixma-20', 'riy-1-cixma-20-meseleler',
     'Məsələlər', 30),
    ('riy-1-cixma-20', 'riy-1-cixma-20-toplama-elaqesi',
     'Toplama və çıxmanın əlaqəsi', 40),
    ('riy-1-cixma-20', 'riy-1-cixma-20-meseleler-2',
     'Məsələlər', 50),
    ('riy-1-cixma-20', 'riy-1-cixma-20-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    --  Ededler (100-e qeder). Pullar  (riy-1-ededler-100)
    ('riy-1-ededler-100', 'riy-1-ededler-100-100-qeder',
     '100-ə qədər sayma', 10),
    ('riy-1-ededler-100', 'riy-1-ededler-100-onluq-teklik',
     'Onluq və təklik', 20),
    ('riy-1-ededler-100', 'riy-1-ededler-100-qepik-manat',
     'Qəpik, manat', 30),
    ('riy-1-ededler-100', 'riy-1-ededler-100-alis-veris',
     'Alış-veriş', 40),
    ('riy-1-ededler-100', 'riy-1-ededler-100-umumi',
     'Ümumiləşdirici tapşırıqlar', 50),
    --  Olcme  (riy-1-olcme)
    ('riy-1-olcme', 'riy-1-olcme-uzun-qisa',
     'Uzun, qısa', 10),
    ('riy-1-olcme', 'riy-1-olcme-santimetr',
     'Santimetr', 20),
    ('riy-1-olcme', 'riy-1-olcme-agir-yungul',
     'Ağır, yüngül', 30),
    ('riy-1-olcme', 'riy-1-olcme-tutum',
     'Tutum', 40),
    ('riy-1-olcme', 'riy-1-olcme-meseleler',
     'Məsələlər', 50),
    ('riy-1-olcme', 'riy-1-olcme-gun-hefte',
     'Gün, həftə, ay', 60),
    ('riy-1-olcme', 'riy-1-olcme-saat',
     'Saat', 70),
    ('riy-1-olcme', 'riy-1-olcme-umumi',
     'Ümumiləşdirici tapşırıqlar', 80),
    --  Melumatlarin tesviri  (riy-1-melumat)
    ('riy-1-melumat', 'riy-1-melumat-cedvel-piktoqram',
     'Cədvəl, piktoqram', 10),
    ('riy-1-melumat', 'riy-1-melumat-meseleler',
     'Məsələlər', 20),
    ('riy-1-melumat', 'riy-1-melumat-diaqram',
     'Diaqram', 30),
    ('riy-1-melumat', 'riy-1-melumat-umumi',
     'Ümumiləşdirici tapşırıqlar', 40),
    --  ============  3-cu sinif  ============
    --  1 Ededler (1000-e qeder)  (riy-3-ededler-1000)
    ('riy-3-ededler-1000', 'riy-3-ededler-1000-yada-salin',
     'Yada salın', 10),
    ('riy-3-ededler-1000', 'riy-3-ededler-1000-ucreqemli',
     'Üçrəqəmli ədədlər', 20),
    ('riy-3-ededler-1000', 'riy-3-ededler-1000-ededin-yazilis',
     'Ədədin yazılış formaları', 30),
    ('riy-3-ededler-1000', 'riy-3-ededler-1000-meseleler',
     'Məsələ və misallar', 40),
    ('riy-3-ededler-1000', 'riy-3-ededler-1000-muqayisesi-siralama',
     'Ədədlərin müqayisəsi və sıralama', 50),
    ('riy-3-ededler-1000', 'riy-3-ededler-1000-yuvarlaqlasdir',
     'Yuvarlaqlaşdırma', 60),
    ('riy-3-ededler-1000', 'riy-3-ededler-1000-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    --  2 Toplama (1000-e qeder)  (riy-3-toplama)
    ('riy-3-toplama', 'riy-3-toplama-yada-salin',
     'Yada salın', 10),
    ('riy-3-toplama', 'riy-3-toplama-ucreqemli-toplanmasi',
     'Üçrəqəmli ədədlərin toplanması', 20),
    ('riy-3-toplama', 'riy-3-toplama-onlugun-yaranmasi',
     'Üçrəqəmli ədədlərin toplanması (yeni onluğun yaranması)', 30),
    ('riy-3-toplama', 'riy-3-toplama-ucreqemli-yaranmasi',
     'Üçrəqəmli ədədlərin toplanması (yeni yüzlüyün yaranması)', 40),
    ('riy-3-toplama', 'riy-3-toplama-meseleler',
     'Məsələ və misallar', 50),
    ('riy-3-toplama', 'riy-3-toplama-onluq-yaranmasi',
     'Üçrəqəmli ədədlərin toplanması (yeni onluq və yüzlüyün yaranması)', 60),
    ('riy-3-toplama', 'riy-3-toplama-daha-cox',
     'Üç və daha çox ədədin toplanması', 70),
    ('riy-3-toplama', 'riy-3-toplama-diger-usullari',
     'Toplamanın digər üsulları', 80),
    ('riy-3-toplama', 'riy-3-toplama-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    --  3 Cixma (1000-e qeder)  (riy-3-cixma)
    ('riy-3-cixma', 'riy-3-cixma-yada-salin',
     'Yada salın', 10),
    ('riy-3-cixma', 'riy-3-cixma-ucreqemli-cixilmasi',
     'Üçrəqəmli ədədlərin çıxılması', 20),
    ('riy-3-cixma', 'riy-3-cixma-onlugun-ayrilmasi',
     'Üçrəqəmli ədədlərin çıxılması (onluğun ayrılması)', 30),
    ('riy-3-cixma', 'riy-3-cixma-ucreqemli-ayrilmasi',
     'Üçrəqəmli ədədlərin çıxılması (yüzlüyün ayrılması)', 40),
    ('riy-3-cixma', 'riy-3-cixma-meseleler',
     'Məsələlər', 50),
    ('riy-3-cixma', 'riy-3-cixma-onluq-ayrilmasi',
     'Üçrəqəmli ədədlərin çıxılması (onluq və yüzlüyün ayrılması)', 60),
    ('riy-3-cixma', 'riy-3-cixma-diger-usullari',
     'Çıxmanın digər üsulları', 70),
    ('riy-3-cixma', 'riy-3-cixma-teqribi-toplama',
     'Təqribi toplama və çıxma', 80),
    ('riy-3-cixma', 'riy-3-cixma-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    --  4 Vurma ve bolme  (riy-3-vurma-bolme)
    ('riy-3-vurma-bolme', 'riy-3-vurma-bolme-yada-salin',
     'Yada salın', 10),
    ('riy-3-vurma-bolme', 'riy-3-vurma-bolme-6-7',
     '6-ya və 7-yə vurma', 20),
    ('riy-3-vurma-bolme', 'riy-3-vurma-bolme-8-10',
     '8, 9 və 10-a vurma', 30),
    ('riy-3-vurma-bolme', 'riy-3-vurma-bolme-meseleler',
     'Məsələ və misallar', 40),
    ('riy-3-vurma-bolme', 'riy-3-vurma-bolme-2-3',
     '2, 3, 4 və 5-ə bölmə', 50),
    ('riy-3-vurma-bolme', 'riy-3-vurma-bolme-6-bolme',
     '6-ya və 7-yə bölmə', 60),
    ('riy-3-vurma-bolme', 'riy-3-vurma-bolme-8-9-10',
     '8, 9 və 10-a bölmə', 70),
    ('riy-3-vurma-bolme', 'riy-3-vurma-bolme-mechulun-tapilmasi',
     'Məchulun tapılması', 80),
    ('riy-3-vurma-bolme', 'riy-3-vurma-bolme-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    --  5 Riyazi ifadeler. Tenlik  (riy-3-ifade-tenlik)
    ('riy-3-ifade-tenlik', 'riy-3-ifade-tenlik-emeller-ardicilligi',
     'Əməllər ardıcıllığı', 10),
    ('riy-3-ifade-tenlik', 'riy-3-ifade-tenlik-deyiseni',
     'Dəyişəni olan ifadələr', 20),
    ('riy-3-ifade-tenlik', 'riy-3-ifade-tenlik-tenlik',
     'Tənlik', 30),
    ('riy-3-ifade-tenlik', 'riy-3-ifade-tenlik-umumi',
     'Ümumiləşdirici tapşırıqlar', 40),
    --  6 Hendesi fiqurlar  (riy-3-fiqurlar)
    ('riy-3-fiqurlar', 'riy-3-fiqurlar-yada-salin',
     'Yada salın', 10),
    ('riy-3-fiqurlar', 'riy-3-fiqurlar-kesisen-paralel',
     'Kəsişən və paralel düz xətlər', 20),
    ('riy-3-fiqurlar', 'riy-3-fiqurlar-mustevi',
     'Müstəvi fiqurlar', 30),
    ('riy-3-fiqurlar', 'riy-3-fiqurlar-simmetriya-yerdeyisme',
     'Simmetriya və yerdəyişmə', 40),
    ('riy-3-fiqurlar', 'riy-3-fiqurlar-feza',
     'Fəza fiqurları', 50),
    ('riy-3-fiqurlar', 'riy-3-fiqurlar-mustevi-elaqesi',
     'Müstəvi və fəza fiqurlarının əlaqəsi', 60),
    ('riy-3-fiqurlar', 'riy-3-fiqurlar-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    --  7 Vurma ve bolme  (riy-3-vurma-bolme-2)
    ('riy-3-vurma-bolme-2', 'riy-3-vurma-bolme-2-xasseleri',
     'Vurmanın xassələri', 10),
    ('riy-3-vurma-bolme-2', 'riy-3-vurma-bolme-2-ikireqemli-vurulmasi',
     'İkirəqəmli ədədin birrəqəmli ədədə vurulması', 20),
    ('riy-3-vurma-bolme-2', 'riy-3-vurma-bolme-2-ucreqemli-vurulmasi',
     'Üçrəqəmli ədədin birrəqəmli ədədə vurulması', 30),
    ('riy-3-vurma-bolme-2', 'riy-3-vurma-bolme-2-meseleler',
     'Məsələ və misallar', 40),
    ('riy-3-vurma-bolme-2', 'riy-3-vurma-bolme-2-qaliqli',
     'Qalıqlı bölmə', 50),
    ('riy-3-vurma-bolme-2', 'riy-3-vurma-bolme-2-ikireqemli-bolunmesi',
     'İkirəqəmli ədədin birrəqəmli ədədə bölünməsi', 60),
    ('riy-3-vurma-bolme-2', 'riy-3-vurma-bolme-2-ucreqemli-bolunmesi',
     'Üçrəqəmli ədədin birrəqəmli ədədə bölünməsi', 70),
    ('riy-3-vurma-bolme-2', 'riy-3-vurma-bolme-2-diger-usullari',
     'Vurma və bölmənin digər üsulları', 80),
    ('riy-3-vurma-bolme-2', 'riy-3-vurma-bolme-2-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    --  8 Kesrler  (riy-3-kesr)
    ('riy-3-kesr', 'riy-3-kesr-tam-beraber',
     'Tam və bərabər hissələr. Kəsr', 10),
    ('riy-3-kesr', 'riy-3-kesr-ededin-hissesi',
     'Ədədin hissəsi', 20),
    ('riy-3-kesr', 'riy-3-kesr-muqayisesi',
     'Kəsrlərin müqayisəsi', 30),
    ('riy-3-kesr', 'riy-3-kesr-umumi',
     'Ümumiləşdirici tapşırıqlar', 40),
    --  9 Ededler (10 000-e qeder) Pullar  (riy-3-ededler-10000)
    ('riy-3-ededler-10000', 'riy-3-ededler-10000-dordreqemli',
     'Dördrəqəmli ədədlər', 10),
    ('riy-3-ededler-10000', 'riy-3-ededler-10000-pullarla-hesablamalar',
     'Pullarla hesablamalar', 20),
    ('riy-3-ededler-10000', 'riy-3-ededler-10000-gelir-xerc',
     'Gəlir, xərc, qazanc', 30),
    ('riy-3-ededler-10000', 'riy-3-ededler-10000-umumi',
     'Ümumiləşdirici tapşırıqlar', 40),
    --  10 Olcme  (riy-3-olcme)
    ('riy-3-olcme', 'riy-3-olcme-uzunluq',
     'Uzunluq', 10),
    ('riy-3-olcme', 'riy-3-olcme-perimetr-sahe',
     'Perimetr və sahə', 20),
    ('riy-3-olcme', 'riy-3-olcme-meseleler',
     'Məsələlər', 30),
    ('riy-3-olcme', 'riy-3-olcme-kutle',
     'Kütlə', 40),
    ('riy-3-olcme', 'riy-3-olcme-tutum',
     'Tutum', 50),
    ('riy-3-olcme', 'riy-3-olcme-saat',
     'Saat', 60),
    ('riy-3-olcme', 'riy-3-olcme-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    --  11 Melumatlarin tesviri. Hadiseler  (riy-3-melumat)
    ('riy-3-melumat', 'riy-3-melumat-xetti-diaqram',
     'Xətti diaqram', 10),
    ('riy-3-melumat', 'riy-3-melumat-hadiseler',
     'Hadisələr', 20),
    ('riy-3-melumat', 'riy-3-melumat-tesviri-praktik',
     'Məlumatların təsviri. Praktik dərs', 30),
    ('riy-3-melumat', 'riy-3-melumat-umumi',
     'Ümumiləşdirici tapşırıqlar', 40),
    --  ============  4-cu sinif  ============
    --  1. Ededler (1 000 000-a qeder)  (riy-4-coxreqemli)
    ('riy-4-coxreqemli', 'riy-4-coxreqemli-yada-salin',
     'Yada salın', 10),
    ('riy-4-coxreqemli', 'riy-4-coxreqemli-ededler',
     'Çoxrəqəmli ədədlər', 20),
    ('riy-4-coxreqemli', 'riy-4-coxreqemli-muqayise-siralama',
     'Müqayisə və sıralama', 30),
    ('riy-4-coxreqemli', 'riy-4-coxreqemli-yuvarlaqlasdir',
     'Yuvarlaqlaşdırma', 40),
    ('riy-4-coxreqemli', 'riy-4-coxreqemli-umumi',
     'Ümumiləşdirici tapşırıqlar', 50),
    --  2. Toplama ve cixma  (riy-4-toplama-cixma)
    ('riy-4-toplama-cixma', 'riy-4-toplama-cixma-yada-salin',
     'Yada salın', 10),
    ('riy-4-toplama-cixma', 'riy-4-toplama-cixma-coxreqemli-toplanmasi',
     'Çoxrəqəmli ədədlərin toplanması', 20),
    ('riy-4-toplama-cixma', 'riy-4-toplama-cixma-coxreqemli-cixilmasi',
     'Çoxrəqəmli ədədlərin çıxılması', 30),
    ('riy-4-toplama-cixma', 'riy-4-toplama-cixma-meseleler',
     'Məsələ və misallar', 40),
    ('riy-4-toplama-cixma', 'riy-4-toplama-cixma-diger-usullari',
     'Toplama və çıxmanın digər üsulları', 50),
    ('riy-4-toplama-cixma', 'riy-4-toplama-cixma-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    --  3. Vurma ve bolme  (riy-4-vurma-bolme)
    ('riy-4-vurma-bolme', 'riy-4-vurma-bolme-yada-salin',
     'Yada salın', 10),
    ('riy-4-vurma-bolme', 'riy-4-vurma-bolme-dordreqemli-vurulmasi',
     'Dördrəqəmli ədədin birrəqəmli ədədə vurulması', 20),
    ('riy-4-vurma-bolme', 'riy-4-vurma-bolme-coxreqemli-vurulmasi',
     'Çoxrəqəmli ədədin birrəqəmli ədədə vurulması', 30),
    ('riy-4-vurma-bolme', 'riy-4-vurma-bolme-meseleler',
     'Məsələ və misallar', 40),
    ('riy-4-vurma-bolme', 'riy-4-vurma-bolme-dordreqemli-bolunmesi',
     'Dördrəqəmli ədədin birrəqəmli ədədə bölünməsi', 50),
    ('riy-4-vurma-bolme', 'riy-4-vurma-bolme-coxreqemli-bolunmesi',
     'Çoxrəqəmli ədədin birrəqəmli ədədə bölünməsi', 60),
    ('riy-4-vurma-bolme', 'riy-4-vurma-bolme-bolenleri-bolunenleri',
     'Ədədin bölənləri və bölünənləri', 70),
    ('riy-4-vurma-bolme', 'riy-4-vurma-bolme-diger-usullari',
     'Vurma və bölmənin digər üsulları', 80),
    ('riy-4-vurma-bolme', 'riy-4-vurma-bolme-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    --  4. Riyazi ifadeler. Tenlik  (riy-4-ifade-tenlik)
    ('riy-4-ifade-tenlik', 'riy-4-ifade-tenlik-ededi',
     'Ədədi ifadələr', 10),
    ('riy-4-ifade-tenlik', 'riy-4-ifade-tenlik-deyiseni',
     'Dəyişəni olan ifadələr', 20),
    ('riy-4-ifade-tenlik', 'riy-4-ifade-tenlik-tenlik',
     'Tənlik', 30),
    ('riy-4-ifade-tenlik', 'riy-4-ifade-tenlik-qurmaqla-mesele',
     'Tənlik qurmaqla məsələ həlli', 40),
    ('riy-4-ifade-tenlik', 'riy-4-ifade-tenlik-riyazi-qanunauygunluq',
     'Riyazi qanunauyğunluq', 50),
    ('riy-4-ifade-tenlik', 'riy-4-ifade-tenlik-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    --  5. Vurma ve bolme  (riy-4-vurma-bolme-2)
    ('riy-4-vurma-bolme-2', 'riy-4-vurma-bolme-2-ikireqemli-edede',
     'İkirəqəmli ədədə vurma', 10),
    ('riy-4-vurma-bolme-2', 'riy-4-vurma-bolme-2-ucreqemli-edede',
     'Üçrəqəmli ədədə vurma', 20),
    ('riy-4-vurma-bolme-2', 'riy-4-vurma-bolme-2-meseleler',
     'Məsələ və misallar', 30),
    ('riy-4-vurma-bolme-2', 'riy-4-vurma-bolme-2-ikireqemli-bolunmesi',
     'İkirəqəmli ədədin ikirəqəmli ədədə bölünməsi', 40),
    ('riy-4-vurma-bolme-2', 'riy-4-vurma-bolme-2-coxreqemli-bolunmesi',
     'Çoxrəqəmli ədədin ikirəqəmli ədədə bölünməsi', 50),
    ('riy-4-vurma-bolme-2', 'riy-4-vurma-bolme-2-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    --  6. Hendesi fiqurlar  (riy-4-fiqurlar)
    ('riy-4-fiqurlar', 'riy-4-fiqurlar-yada-salin',
     'Yada salın', 10),
    ('riy-4-fiqurlar', 'riy-4-fiqurlar-sade-cevre',
     'Sadə həndəsi fiqurlar. Çevrə', 20),
    ('riy-4-fiqurlar', 'riy-4-fiqurlar-bucaq-olcusu',
     'Bucaq. Bucağın ölçüsü', 30),
    ('riy-4-fiqurlar', 'riy-4-fiqurlar-olculmesi-transportir',
     'Bucağın ölçülməsi. Transportir', 40),
    ('riy-4-fiqurlar', 'riy-4-fiqurlar-koordinat-sebekesi',
     'Koordinat şəbəkəsi', 50),
    ('riy-4-fiqurlar', 'riy-4-fiqurlar-hendesi-ornamentler',
     'Həndəsi ornamentlər', 60),
    ('riy-4-fiqurlar', 'riy-4-fiqurlar-meseleler',
     'Məsələlər', 70),
    ('riy-4-fiqurlar', 'riy-4-fiqurlar-feza-acilisi',
     'Fəza fiqurlarının açılışı', 80),
    ('riy-4-fiqurlar', 'riy-4-fiqurlar-muxtelif-tereflerden',
     'Fiqurların müxtəlif tərəflərdən görünüşü', 90),
    ('riy-4-fiqurlar', 'riy-4-fiqurlar-umumi',
     'Ümumiləşdirici tapşırıqlar', 100),
    --  7. Adi ve onluq kesrler  (riy-4-kesr)
    ('riy-4-kesr', 'riy-4-kesr-yada-salin',
     'Yada salın', 10),
    ('riy-4-kesr', 'riy-4-kesr-beraber',
     'Bərabər kəsrlər', 20),
    ('riy-4-kesr', 'riy-4-kesr-muqayisesi',
     'Kəsrlərin müqayisəsi', 30),
    ('riy-4-kesr', 'riy-4-kesr-mexrecleri-toplanmasi',
     'Məxrəcləri bərabər olan kəsrlərin toplanması və çıxılması', 40),
    ('riy-4-kesr', 'riy-4-kesr-qarisiq-ededler',
     'Qarışıq ədədlər', 50),
    ('riy-4-kesr', 'riy-4-kesr-meseleler',
     'Məsələ və misallar', 60),
    --  7. Adi ve onluq kesrler  (riy-4-onluq-kesr)
    ('riy-4-onluq-kesr', 'riy-4-onluq-kesr-onluq-kesrler',
     'Onluq kəsrlər', 10),
    ('riy-4-onluq-kesr', 'riy-4-onluq-kesr-muqayisesi',
     'Onluq kəsrlərin müqayisəsi', 20),
    ('riy-4-onluq-kesr', 'riy-4-onluq-kesr-toplanmasi-cixilmasi',
     'Onluq kəsrlərin toplanması və çıxılması', 30),
    ('riy-4-onluq-kesr', 'riy-4-onluq-kesr-umumi',
     'Ümumiləşdirici tapşırıqlar', 40),
    ('riy-4-onluq-kesr', 'riy-4-onluq-kesr-mesele-hellinin',
     'Məsələ həllinin bəzi üsulları', 50),
    --  8. Pullar  (riy-4-pullar)
    ('riy-4-pullar', 'riy-4-pullar-onluq-kesrler',
     'Pullar və onluq kəsrlər', 10),
    ('riy-4-pullar', 'riy-4-pullar-hesablamalar',
     'Pullarla hesablamalar', 20),
    ('riy-4-pullar', 'riy-4-pullar-deyisen-deyismeyen',
     'Dəyişən və dəyişməyən xərclər', 30),
    ('riy-4-pullar', 'riy-4-pullar-umumi',
     'Ümumiləşdirici tapşırıqlar', 40),
    --  9. Olcme  (riy-4-olcme)
    ('riy-4-olcme', 'riy-4-olcme-uzunluq',
     'Uzunluq', 10),
    ('riy-4-olcme', 'riy-4-olcme-perimetr',
     'Perimetr', 20),
    ('riy-4-olcme', 'riy-4-olcme-sahe',
     'Sahə', 30),
    ('riy-4-olcme', 'riy-4-olcme-kutle-tutum',
     'Kütlə və tutum', 40),
    ('riy-4-olcme', 'riy-4-olcme-hecm',
     'Həcm', 50),
    ('riy-4-olcme', 'riy-4-olcme-meseleler',
     'Məsələlər', 60),
    ('riy-4-olcme', 'riy-4-olcme-zaman',
     'Zaman', 70),
    ('riy-4-olcme', 'riy-4-olcme-suret',
     'Sürət', 80),
    ('riy-4-olcme', 'riy-4-olcme-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    --  10. Melumatlarin tesviri  (riy-4-melumat)
    ('riy-4-melumat', 'riy-4-melumat-cedvel-piktoqram',
     'Cədvəl. Piktoqram', 10),
    ('riy-4-melumat', 'riy-4-melumat-dairevi-diaqram',
     'Dairəvi diaqram', 20),
    ('riy-4-melumat', 'riy-4-melumat-xetti-diaqram',
     'Xətti diaqram', 30)
  ) as v(parent_slug, slug, name, sort)
  join public.topics p on p.slug = v.parent_slug
   and p.subject_id = (select id from public.subjects where slug = 'riyaziyyat')
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort,
      parent_id = excluded.parent_id, level_id = excluded.level_id;

do $$
declare k int;
begin
  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'riyaziyyat'
    join public.levels   l on l.id = p.level_id and l.code = '1';
  if k <> 70 then
    raise exception 'Riyaziyyat 1-ci alt movzulari: 70 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'riyaziyyat'
    join public.levels   l on l.id = p.level_id and l.code = '3';
  if k <> 73 then
    raise exception 'Riyaziyyat 3-cu alt movzulari: 73 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'riyaziyyat'
    join public.levels   l on l.id = p.level_id and l.code = '4';
  if k <> 69 then
    raise exception 'Riyaziyyat 4-cu alt movzulari: 69 gozlenilirdi, % tapildi', k;
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
    join public.subjects s on s.id = t.subject_id and s.slug = 'riyaziyyat'
    join public.levels   l on l.id = t.level_id
   where t.parent_id is null and l.code in ('1','2','3','4');
  if k <> 45 then
    raise exception 'Riyaziyyat 1-4 ust movzu sayi 45 deyil: %', k;
  end if;

  raise notice 'Riyaziyyat 1, 3, 4 (2-ci sinif portalda kohnedir): 212 alt movzu hazir.';
end $$;
