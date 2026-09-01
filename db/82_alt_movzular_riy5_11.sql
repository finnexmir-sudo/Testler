-- =====================================================================
--  82_alt_movzular_riy5_11.sql : RIYAZIYYAT 5-7, 9-11 - ALT MOVZULAR
--
--  NIYE
--  db/74 8-ci sinif ucun alt movzu agacini qurdu; muellim onu
--  yoxlayib tesdiqledi (derslik 11 bolme = baza 74 setir = panel
--  74 ders).  Bu fayl EYNI qelible riyaziyyatin qalan
--  siniflerini bitirir - bir fenn sona qeder, muellime gostermeye
--  tam bir sey olsun.
--
--  EHATE: yalniz Riyaziyyat, 5, 6, 7, 9, 10, 11-ci sinifler.
--  8-ci sinif db/74-dedir, 1-4 ise db/83-de.
--
--  MENBE: e-derslik.edu.az sag paneldeki "Movzular" agaci -
--  kitab id 840/841 (5), 906/907 (6), 714 (7), 507 (9), 741 (10),
--  817 (11).  Adlar EYNILE goturulub.  Derslikdeki sira sort-a
--  dusub; her valideyn altinda 10-dan baslayir.
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
--   * duster (12): portal mundericatinda dusen duster simvollari - dogru ad kitabin oz sehife basligindan
--       9-cu   s.62   = + + funksiyasinin qrafikinin qurulmasi
--                    -> y = ax^2 + bx + c funksiyasinin qrafikinin qurulmasi
--       9-cu   s.64   = + + funksiyasinin arasdirilmasi
--                    -> y = ax^2 + bx + c funksiyasinin arasdirilmasi
--       9-cu   s.70   = || funksiyasi ve onun qrafiki
--                    -> y = |x| funksiyasi ve onun qrafiki
--       9-cu   s.74   = funksiyasi ve onun qrafiki
--                    -> y = x^3 funksiyasi ve onun qrafiki
--       9-cu   s.195  Ededi silsilenin -ci heddinin dusturu
--                    -> Ededi silsilenin n-ci heddinin dusturu
--       9-cu   s.201  Ededi silsilenin ilk heddinin cemi dusturu
--                    -> Ededi silsilenin ilk n heddinin cemi dusturu
--       9-cu   s.207  Hendesi silsilenin -ci heddinin dusturu
--                    -> Hendesi silsilenin n-ci heddinin dusturu
--       9-cu   s.211  Hendesi silsilenin ilk heddinin cemi dusturu
--                    -> Hendesi silsilenin ilk n heddinin cemi dusturu
--       9-cu   s.229  Permutasiya-yerdeyisme, P
--                    -> Permutasiya-yerdeyisme, nPn
--       9-cu   s.231  Permutasiya-yerlesdirme, P
--                    -> Permutasiya-yerlesdirme, nPk
--       9-cu   s.233  Kombinezon, C
--                    -> Kombinezon, nCk
--       10-cu  s.21   y = xn (n in N) quvvet funksiyalar
--                    -> y = x^n (n in N) quvvet funksiyasi
--   * rusca (16): portal 10-cu sinfin 9/10-cu bolmesini rus nesrinden yigib - dogru ad kitabin oz sehife basligindan
--       10-cu  s.245  Stepen s deystvitelnym pokazatelem
--                    -> Heqiqi ustlu quvvet
--       10-cu  s.248  Pokazatelnaya funktsiya
--                    -> Ustlu funksiya
--       10-cu  s.258  Logarifm chisla
--                    -> Ededin loqarifmi
--       10-cu  s.260  Logarifmicheskaya funktsiya
--                    -> Loqarifmik funksiya
--       10-cu  s.262  Svoystva logarifmov
--                    -> Loqarifmin xasseleri
--       10-cu  s.266  Logarifmicheskaya shkala.Reshenie zadach
--                    -> Loqarifmik skala ve mesele helli
--       10-cu  s.268  Pokazatelnye uravneniya
--                    -> Ustlu tenlikler
--       10-cu  s.271  Logarifmicheskie uravneniya
--                    -> Loqarifmik tenlikler
--       10-cu  s.275  Pokazatelnye neravenstva
--                    -> Ustlu berabersizlikler
--       10-cu  s.277  Logarifmicheskie neravenstva
--                    -> Loqarifmik berabersizlikler
--       10-cu  s.280  Obobschayuschie zadaniya
--                    -> Umumilesdirici tapsiriqlar
--       10-cu  s.283  Sovokupnost i vyborka. Sluchaynaya vyborka i eyo raznovidnosti
--                    -> Kulliyyat ve secim. Tesadufi secim ve novleri
--       10-cu  s.287  Predstavlenie informatsii
--                    -> Melumatin teqdimi
--       10-cu  s.293  Razlojenie binoma
--                    -> Binomial acilis
--       10-cu  s.297  Ispytaniya Bernulli
--                    -> Bernulli sinaqlari
--       10-cu  s.304  Obobschayuschie zadaniya
--                    -> Umumilesdirici tapsiriqlar
--   * yazi (15): yazi qusuru (bosluq, herf)
--       5-ci   s.18   1.4 Natural ededlerin toplanmasi va cixilmasi
--                    -> Natural ededlerin toplanmasi ve cixilmasi
--       5-ci   s.21   1.5 Natural ededin kvadrati va kubu
--                    -> Natural ededin kvadrati ve kubu
--       5-ci   s.47   2.3 Mexrecleri muxtelif olan kesrlerin toplanmasi va cixilmasi
--                    -> Mexrecleri muxtelif olan kesrlerin toplanmasi ve cixilmasi
--       5-ci   s.103  3.7 Onluq kesrin natural edede vurulmasi
--                    -> Onluq kesrin natural edede vurulmasi   [ASCII-de eyni gorunur: diakritik duzelisi]
--       5-ci   s.63   7.1 Kub ve kuboidin sethinin sahesi
--                    -> Kub ve kuboidin sethinin sahesi   [ASCII-de eyni gorunur: diakritik duzelisi]
--       5-ci   s.84   STEAM. "Quslar bizim dostlarimizdir".
--                    -> STEAM. "Quslar bizim dostlarimizdir"
--       7-ci   s.33   1. Rasioanl ededlerin yazilisi ve oxunusu
--                    -> Rasional ededlerin yazilisi ve oxunusu
--       7-ci   s.168  1. Ikidayisenli xetti tenlikler sistemi
--                    -> Ikideyisenli xetti tenlikler sistemi
--       9-cu   s.18   Vurugun kok isaresi altindan cixarilmasi
--                    -> Vurugun kok isaresi altindan cixarilmasi   [ASCII-de eyni gorunur: diakritik duzelisi]
--       9-cu   s.19   Vurugun kok isaresi altina daxil edilmesi
--                    -> Vurugun kok isaresi altina daxil edilmesi   [ASCII-de eyni gorunur: diakritik duzelisi]
--       10-cu  s.58   Mustevilerin qarsiliqli veziyyeti.Ikiuzlu bucaqlar
--                    -> Mustevilerin qarsiliqli veziyyeti. Ikiuzlu bucaqlar
--       10-cu  s.79   Xett suret, bucaq sureti
--                    -> Xetti suret, bucaq sureti
--       10-cu  s.103  Toplama dusturlar
--                    -> Toplama dusturlari
--       11-ci  s.222  Ibtidai funksiya.Qeyri-mueyyen inteqral
--                    -> Ibtidai funksiya. Qeyri-mueyyen inteqral
--       11-ci  s.269  Melumatin paylanma formalari
--                    -> Melumatin paylanma formalari   [ASCII-de eyni gorunur: diakritik duzelisi]

insert into public.topics (subject_id, level_id, parent_id, slug, name, sort)
select p.subject_id, p.level_id, p.id, v.slug, v.name, v.sort
  from (values
    --  ============  5-ci sinif  ============
    --  Bolme 1. Natural ededler ve onlar uzerinde emeller  (riy-5-natural-ededler)
    ('riy-5-natural-ededler', 'riy-5-natural-ededler-ilkin',
     'İlkin yoxlama', 10),
    ('riy-5-natural-ededler', 'riy-5-natural-ededler-natural-ededler',
     'Natural ədədlər', 20),
    ('riy-5-natural-ededler', 'riy-5-natural-ededler-muqayise-siralama',
     'Müqayisə və sıralama', 30),
    ('riy-5-natural-ededler', 'riy-5-natural-ededler-yuvarlaqlasdir',
     'Natural ədədlərin yuvarlaqlaşdırılması', 40),
    ('riy-5-natural-ededler', 'riy-5-natural-ededler-toplanmasi-cixilmasi',
     'Natural ədədlərin toplanması və çıxılması', 50),
    ('riy-5-natural-ededler', 'riy-5-natural-ededler-kvadrati-kubu',
     'Natural ədədin kvadratı və kubu', 60),
    ('riy-5-natural-ededler', 'riy-5-natural-ededler-vurulmasi-bolunmesi',
     'Natural ədədlərin vurulması və bölünməsi', 70),
    ('riy-5-natural-ededler', 'riy-5-natural-ededler-ededi-ifadeler',
     'Ədədi ifadələr', 80),
    ('riy-5-natural-ededler', 'riy-5-natural-ededler-bolen-bolunenleri',
     'Ədədin bölən və bölünənləri', 90),
    ('riy-5-natural-ededler', 'riy-5-natural-ededler-xulase',
     'Xülasə', 100),
    ('riy-5-natural-ededler', 'riy-5-natural-ededler-umumi',
     'Ümumiləşdirici tapşırıqlar', 110),
    ('riy-5-natural-ededler', 'riy-5-natural-ededler-parker-gunes',
     'STEAM. "Parker" Günəş Zondu', 120),
    --  Bolme 2. Adi kesrler  (riy-5-adi-kesrler)
    ('riy-5-adi-kesrler', 'riy-5-adi-kesrler-ilkin',
     'İlkin yoxlama', 10),
    ('riy-5-adi-kesrler', 'riy-5-adi-kesrler-duzgun-olmayan',
     'Düzgün kəsrlər və düzgün olmayan kəsrlər', 20),
    ('riy-5-adi-kesrler', 'riy-5-adi-kesrler-muqayise-siralama',
     'Müqayisə və sıralama', 30),
    ('riy-5-adi-kesrler', 'riy-5-adi-kesrler-mexrecleri-muxtelif',
     'Məxrəcləri müxtəlif olan kəsrlərin toplanması və çıxılması', 40),
    ('riy-5-adi-kesrler', 'riy-5-adi-kesrler-qarisiq-toplanmasi',
     'Qarışıq ədədlərin toplanması', 50),
    ('riy-5-adi-kesrler', 'riy-5-adi-kesrler-qarisiq-cixilmasi',
     'Qarışıq ədədlərin çıxılması', 60),
    ('riy-5-adi-kesrler', 'riy-5-adi-kesrler-meseleler',
     'Məsələ və misallar', 70),
    ('riy-5-adi-kesrler', 'riy-5-adi-kesrler-adi-vurulmasi',
     'Adi kəsrlərin vurulması', 80),
    ('riy-5-adi-kesrler', 'riy-5-adi-kesrler-qarisiq-vurulmasi',
     'Qarışıq ədədlərin vurulması', 90),
    ('riy-5-adi-kesrler', 'riy-5-adi-kesrler-adi-bolunmesi',
     'Adi kəsrlərin bölünməsi', 100),
    ('riy-5-adi-kesrler', 'riy-5-adi-kesrler-qarisiq-bolunmesi',
     'Qarışıq ədədlərin bölünməsi', 110),
    ('riy-5-adi-kesrler', 'riy-5-adi-kesrler-ededin-hissesinin',
     'Ədədin hissəsinin və hissəsinə görə ədədin tapılması', 120),
    ('riy-5-adi-kesrler', 'riy-5-adi-kesrler-xulase',
     'Xülasə', 130),
    ('riy-5-adi-kesrler', 'riy-5-adi-kesrler-umumi',
     'Ümumiləşdirici tapşırıqlar', 140),
    ('riy-5-adi-kesrler', 'riy-5-adi-kesrler-qurama',
     'STEAM. Qurama', 150),
    --  Bolme 3. Onluq kesrler  (riy-5-onluq-kesrler)
    ('riy-5-onluq-kesrler', 'riy-5-onluq-kesrler-ilkin',
     'İlkin yoxlama', 10),
    ('riy-5-onluq-kesrler', 'riy-5-onluq-kesrler-onluq-kesrler',
     'Onluq kəsrlər', 20),
    ('riy-5-onluq-kesrler', 'riy-5-onluq-kesrler-muqayise-siralama',
     'Müqayisə və sıralama', 30),
    ('riy-5-onluq-kesrler', 'riy-5-onluq-kesrler-yuvarlaqlasdir',
     'Onluq kəsrlərin yuvarlaqlaşdırılması', 40),
    ('riy-5-onluq-kesrler', 'riy-5-onluq-kesrler-adi-cevrilmesi',
     'Adi kəsrin onluq kəsrə, onluq kəsrin adi kəsrə çevrilməsi', 50),
    ('riy-5-onluq-kesrler', 'riy-5-onluq-kesrler-toplanmasi-cixilmasi',
     'Onluq kəsrlərin toplanması və çıxılması', 60),
    ('riy-5-onluq-kesrler', 'riy-5-onluq-kesrler-meseleler',
     'Məsələ və misallar', 70),
    ('riy-5-onluq-kesrler', 'riy-5-onluq-kesrler-10-quvvetlerine',
     'Onluq kəsrlərin 10-un qüvvətlərinə vurulması və bölünməsi', 80),
    ('riy-5-onluq-kesrler', 'riy-5-onluq-kesrler-kesrin-vurulmasi',
     'Onluq kəsrin natural ədədə vurulması', 90),
    ('riy-5-onluq-kesrler', 'riy-5-onluq-kesrler-vurulmasi',
     'Onluq kəsrlərin vurulması', 100),
    ('riy-5-onluq-kesrler', 'riy-5-onluq-kesrler-kesrin-bolunmesi',
     'Onluq kəsrin natural ədədə bölünməsi', 110),
    ('riy-5-onluq-kesrler', 'riy-5-onluq-kesrler-ededin-bolunmesi',
     'Ədədin onluq kəsrə bölünməsi', 120),
    ('riy-5-onluq-kesrler', 'riy-5-onluq-kesrler-uzerinde-emeller',
     'Adi və onluq kəsrlər üzərində əməllər', 130),
    ('riy-5-onluq-kesrler', 'riy-5-onluq-kesrler-xulase',
     'Xülasə', 140),
    ('riy-5-onluq-kesrler', 'riy-5-onluq-kesrler-umumi',
     'Ümumiləşdirici tapşırıqlar', 150),
    ('riy-5-onluq-kesrler', 'riy-5-onluq-kesrler-yukseksuretli-qatarlar',
     'STEAM. Yüksəksürətli qatarlar', 160),
    --  Bolme 4. Faiz  (riy-5-faiz)
    ('riy-5-faiz', 'riy-5-faiz-ilkin',
     'İlkin yoxlama', 10),
    ('riy-5-faiz', 'riy-5-faiz-adi-kesr',
     'Faiz, adi kəsr, onluq kəsr', 20),
    ('riy-5-faiz', 'riy-5-faiz-ededin',
     'Ədədin faizi', 30),
    ('riy-5-faiz', 'riy-5-faiz-ededin-tapilmasi',
     'Faizə görə ədədin tapılması', 40),
    ('riy-5-faiz', 'riy-5-faiz-kemiyyetin-qiymetinin',
     'Kəmiyyətin qiymətinin müəyyən faiz artırılması və azaldılması', 50),
    ('riy-5-faiz', 'riy-5-faiz-xulase',
     'Xülasə', 60),
    ('riy-5-faiz', 'riy-5-faiz-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    ('riy-5-faiz', 'riy-5-faiz-genealogiya',
     'STEAM. Genealogiya', 80),
    --  Bolme 5. Deyiseni olan ifadeler. Tenlik. Berabersizlik  (riy-5-ifade-tenlik)
    ('riy-5-ifade-tenlik', 'riy-5-ifade-tenlik-ilkin',
     'İlkin yoxlama', 10),
    ('riy-5-ifade-tenlik', 'riy-5-ifade-tenlik-deyiseni',
     'Dəyişəni olan ifadələr', 20),
    ('riy-5-ifade-tenlik', 'riy-5-ifade-tenlik-birdeyisenli-sadelesdirilme',
     'Birdəyişənli ifadələrin sadələşdirilməsi', 30),
    ('riy-5-ifade-tenlik', 'riy-5-ifade-tenlik-beraberlik',
     'Bərabərlik və tənlik', 40),
    ('riy-5-ifade-tenlik', 'riy-5-ifade-tenlik-qurmaqla-mesele',
     'Tənlik qurmaqla məsələ həlli', 50),
    ('riy-5-ifade-tenlik', 'riy-5-ifade-tenlik-berabersizlikl',
     'Bərabərsizliklər', 60),
    ('riy-5-ifade-tenlik', 'riy-5-ifade-tenlik-asili-deyisenler',
     'Asılı dəyişənlər və asılı olmayan dəyişənlər', 70),
    ('riy-5-ifade-tenlik', 'riy-5-ifade-tenlik-xulase',
     'Xülasə', 80),
    ('riy-5-ifade-tenlik', 'riy-5-ifade-tenlik-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    ('riy-5-ifade-tenlik', 'riy-5-ifade-tenlik-qlobal-istilesme',
     'STEAM. Qlobal istiləşmə', 100),
    --  Bolme 6. Mustevi fiqurlar  (riy-5-mustevi-fiqurlar)
    ('riy-5-mustevi-fiqurlar', 'riy-5-mustevi-fiqurlar-ilkin',
     'İlkin yoxlama', 10),
    ('riy-5-mustevi-fiqurlar', 'riy-5-mustevi-fiqurlar-konqruyent-bucagin',
     'Konqruyent bucaqlar. Bucağın tənböləni', 20),
    ('riy-5-mustevi-fiqurlar', 'riy-5-mustevi-fiqurlar-qonsu-qarsiliqli',
     'Qonşu və qarşılıqlı bucaqlar', 30),
    ('riy-5-mustevi-fiqurlar', 'riy-5-mustevi-fiqurlar-meseleler',
     'Məsələlər', 40),
    ('riy-5-mustevi-fiqurlar', 'riy-5-mustevi-fiqurlar-duzbucaqli-sahesi',
     'Düzbucaqlı üçbucağın sahəsi', 50),
    ('riy-5-mustevi-fiqurlar', 'riy-5-mustevi-fiqurlar-ucbucaqdan-teskil',
     'Düzbucaqlı və düzbucaqlı üçbucaqdan təşkil olunmuş fiqurun sahəsi', 60),
    ('riy-5-mustevi-fiqurlar', 'riy-5-mustevi-fiqurlar-paralel-perpendikulyar',
     'Paralel və perpendikulyar düz xətlərin çəkilməsi', 70),
    ('riy-5-mustevi-fiqurlar', 'riy-5-mustevi-fiqurlar-ucbucagin-cekilmesi',
     'Üçbucağın çəkilməsi', 80),
    ('riy-5-mustevi-fiqurlar', 'riy-5-mustevi-fiqurlar-xulase',
     'Xülasə', 90),
    ('riy-5-mustevi-fiqurlar', 'riy-5-mustevi-fiqurlar-umumi',
     'Ümumiləşdirici tapşırıqlar', 100),
    ('riy-5-mustevi-fiqurlar', 'riy-5-mustevi-fiqurlar-avtomobil-dayanacagi',
     'STEAM. Avtomobil dayanacağı', 110),
    --  Bolme 7. Feza fiqurlari  (riy-5-feza-fiqurlari)
    ('riy-5-feza-fiqurlari', 'riy-5-feza-fiqurlari-ilkin',
     'İlkin yoxlama', 10),
    ('riy-5-feza-fiqurlari', 'riy-5-feza-fiqurlari-kub-kuboidin',
     'Kub və kuboidin səthinin sahəsi', 20),
    ('riy-5-feza-fiqurlari', 'riy-5-feza-fiqurlari-oturacagi-duzbucaqli',
     'Oturacağı düzbucaqlı üçbucaq olan düz prizmanın səthinin sahəsi', 30),
    ('riy-5-feza-fiqurlari', 'riy-5-feza-fiqurlari-meseleler',
     'Məsələlər', 40),
    ('riy-5-feza-fiqurlari', 'riy-5-feza-fiqurlari-duz-hecmi',
     'Düz prizmanın həcmi', 50),
    ('riy-5-feza-fiqurlari', 'riy-5-feza-fiqurlari-sahe-vahidleri',
     'Sahə vahidləri', 60),
    ('riy-5-feza-fiqurlari', 'riy-5-feza-fiqurlari-hecm-vahidleri',
     'Həcm vahidləri', 70),
    ('riy-5-feza-fiqurlari', 'riy-5-feza-fiqurlari-xulase',
     'Xülasə', 80),
    ('riy-5-feza-fiqurlari', 'riy-5-feza-fiqurlari-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    ('riy-5-feza-fiqurlari', 'riy-5-feza-fiqurlari-quslar-bizim',
     'STEAM. "Quşlar bizim dostlarımızdır"', 100),
    --  Bolme 8. Statistika ve melumatlarin tesviri  (riy-5-statistika)
    ('riy-5-statistika', 'riy-5-statistika-ilkin',
     'İlkin yoxlama', 10),
    ('riy-5-statistika', 'riy-5-statistika-ededi-orta',
     'Ədədi orta', 20),
    ('riy-5-statistika', 'riy-5-statistika-dairevi-diaqram',
     'Dairəvi diaqram', 30),
    ('riy-5-statistika', 'riy-5-statistika-melumatlarin-tesviri',
     'Məlumatların təsviri', 40),
    ('riy-5-statistika', 'riy-5-statistika-xulase',
     'Xülasə', 50),
    ('riy-5-statistika', 'riy-5-statistika-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    ('riy-5-statistika', 'riy-5-statistika-covid-19',
     'STEAM. "COVİD-19" infeksiyasının yayılma statistikası', 70),
    --  ============  6-ci sinif  ============
    --  Bolme 1. Natural ededler ve onlar uzerinde emeller  (riy-6-natural-ededler)
    ('riy-6-natural-ededler', 'riy-6-natural-ededler-ilkin',
     'İlkin yoxlama', 10),
    ('riy-6-natural-ededler', 'riy-6-natural-ededler-ededin-quvveti',
     'Natural ədədin qüvvəti', 20),
    ('riy-6-natural-ededler', 'riy-6-natural-ededler-sade-murekkeb',
     'Sadə və mürəkkəb ədədlər', 30),
    ('riy-6-natural-ededler', 'riy-6-natural-ededler-boyuk-bolen',
     'Ən böyük ortaq bölən (ƏBOB)', 40),
    ('riy-6-natural-ededler', 'riy-6-natural-ededler-kicik-bolunen',
     'Ən kiçik ortaq bölünən (ƏKOB)', 50),
    ('riy-6-natural-ededler', 'riy-6-natural-ededler-xulase',
     'Xülasə', 60),
    ('riy-6-natural-ededler', 'riy-6-natural-ededler-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    ('riy-6-natural-ededler', 'riy-6-natural-ededler-kriptoqrafiya',
     'STEAM. "Kriptoqrafiya"', 80),
    --  Bolme 2. Nisbet. Tenasub. Faiz  (riy-6-nisbet-faiz)
    ('riy-6-nisbet-faiz', 'riy-6-nisbet-faiz-ilkin',
     'İlkin yoxlama', 10),
    ('riy-6-nisbet-faiz', 'riy-6-nisbet-faiz-nisbet',
     'Nisbət', 20),
    ('riy-6-nisbet-faiz', 'riy-6-nisbet-faiz-kemiyyetlerin',
     'Kəmiyyətlərin nisbəti', 30),
    ('riy-6-nisbet-faiz', 'riy-6-nisbet-faiz-verilen-bolunmesi',
     'Kəmiyyətin verilən nisbətdə bölünməsi', 40),
    ('riy-6-nisbet-faiz', 'riy-6-nisbet-faiz-tenasub',
     'Tənasüb', 50),
    ('riy-6-nisbet-faiz', 'riy-6-nisbet-faiz-miqyas',
     'Miqyas', 60),
    ('riy-6-nisbet-faiz', 'riy-6-nisbet-faiz-duz-asililiq',
     'Düz mütənasib asılılıq', 70),
    ('riy-6-nisbet-faiz', 'riy-6-nisbet-faiz-ters-asililiq',
     'Tərs mütənasib asılılıq', 80),
    ('riy-6-nisbet-faiz', 'riy-6-nisbet-faiz-meseleler',
     'Məsələ və misallar', 90),
    ('riy-6-nisbet-faiz', 'riy-6-nisbet-faiz-ifadesi',
     'Nisbətin faizlə ifadəsi', 100),
    ('riy-6-nisbet-faiz', 'riy-6-nisbet-faiz-deyismesinin-ifadesi',
     'Kəmiyyətin dəyişməsinin faizlə ifadəsi', 110),
    ('riy-6-nisbet-faiz', 'riy-6-nisbet-faiz-xulase',
     'Xülasə', 120),
    ('riy-6-nisbet-faiz', 'riy-6-nisbet-faiz-umumi',
     'Ümumiləşdirici tapşırıqlar', 130),
    ('riy-6-nisbet-faiz', 'riy-6-nisbet-faiz-ekran-cozumluluk',
     'STEAM. "Ekran nisbəti və çözümlülük"', 140),
    --  Bolme 3. Tam ededler  (riy-6-tam-ededler)
    ('riy-6-tam-ededler', 'riy-6-tam-ededler-ilkin',
     'İlkin yoxlama', 10),
    ('riy-6-tam-ededler', 'riy-6-tam-ededler-tam',
     'Tam ədədlər', 20),
    ('riy-6-tam-ededler', 'riy-6-tam-ededler-muqayisesi-siralanmasi',
     'Tam ədədlərin müqayisəsi və sıralanması', 30),
    ('riy-6-tam-ededler', 'riy-6-tam-ededler-ededin-qiymeti',
     'Ədədin mütləq qiyməti', 40),
    ('riy-6-tam-ededler', 'riy-6-tam-ededler-tam-toplanmasi',
     'Tam ədədlərin toplanması', 50),
    ('riy-6-tam-ededler', 'riy-6-tam-ededler-tam-cixilmasi',
     'Tam ədədlərin çıxılması', 60),
    ('riy-6-tam-ededler', 'riy-6-tam-ededler-meseleler',
     'Məsələ və misallar', 70),
    ('riy-6-tam-ededler', 'riy-6-tam-ededler-vurulmasi-bolunmesi',
     'Tam ədədlərin vurulması və bölünməsi', 80),
    ('riy-6-tam-ededler', 'riy-6-tam-ededler-uzerinde-emeller',
     'Tam ədədlər üzərində əməllər', 90),
    ('riy-6-tam-ededler', 'riy-6-tam-ededler-xulase',
     'Xülasə', 100),
    ('riy-6-tam-ededler', 'riy-6-tam-ededler-umumi',
     'Ümumiləşdirici tapşırıqlar', 110),
    ('riy-6-tam-ededler', 'riy-6-tam-ededler-ekstremal-temperatur',
     'STEAM. "Ekstremal temperatur və mütləq sıfır"', 120),
    --  Bolme 4. Duzbucaqli koordinat sistemi  (riy-6-koordinat)
    ('riy-6-koordinat', 'riy-6-koordinat-ilkin',
     'İlkin yoxlama', 10),
    ('riy-6-koordinat', 'riy-6-koordinat-duzbucaqli-sistemi',
     'Düzbucaqlı koordinat sistemi', 20),
    ('riy-6-koordinat', 'riy-6-koordinat-duzbucaqli-mesafe',
     'Düzbucaqlı koordinat sistemində məsafə', 30),
    ('riy-6-koordinat', 'riy-6-koordinat-simmetriya-yerdeyisme',
     'Düzbucaqlı koordinat sistemində simmetriya və yerdəyişmə', 40),
    ('riy-6-koordinat', 'riy-6-koordinat-xulase',
     'Xülasə', 50),
    ('riy-6-koordinat', 'riy-6-koordinat-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    ('riy-6-koordinat', 'riy-6-koordinat-kriptoqrafiya',
     'STEAM. "Kriptoqrafiya"', 70),
    --  Bolme 5. Coxluqlar ve onlar uzerinde emeller  (riy-6-coxluqlar)
    ('riy-6-coxluqlar', 'riy-6-coxluqlar-ilkin',
     'İlkin yoxlama', 10),
    ('riy-6-coxluqlar', 'riy-6-coxluqlar-coxluq',
     'Çoxluq', 20),
    ('riy-6-coxluqlar', 'riy-6-coxluqlar-uzerinde-emeller',
     'Çoxluqlar üzərində əməllər', 30),
    ('riy-6-coxluqlar', 'riy-6-coxluqlar-eyler-venn',
     'Eyler-Venn diaqramının köməyi ilə məsələ həlli', 40),
    ('riy-6-coxluqlar', 'riy-6-coxluqlar-xulase',
     'Xülasə', 50),
    ('riy-6-coxluqlar', 'riy-6-coxluqlar-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    ('riy-6-coxluqlar', 'riy-6-coxluqlar-axtaris-sistemleri',
     'STEAM. "Axtarış sistemləri"', 70),
    --  Bolme 6. Deyiseni olan ifadeler. Tenlik. Berabersizlik  (riy-6-ifade-tenlik)
    ('riy-6-ifade-tenlik', 'riy-6-ifade-tenlik-ilkin',
     'İlkin yoxlama', 10),
    ('riy-6-ifade-tenlik', 'riy-6-ifade-tenlik-deyiseni',
     'Dəyişəni olan ifadələr', 20),
    ('riy-6-ifade-tenlik', 'riy-6-ifade-tenlik-moterizelerin-acilmasi',
     'Riyazi ifadələrdə mötərizələrin açılması', 30),
    ('riy-6-ifade-tenlik', 'riy-6-ifade-tenlik-deyisenli-sadelesdirilme',
     'Dəyişənli ifadələrin sadələşdirilməsi', 40),
    ('riy-6-ifade-tenlik', 'riy-6-ifade-tenlik-tenlikler',
     'Tənliklər', 50),
    ('riy-6-ifade-tenlik', 'riy-6-ifade-tenlik-qurmaqla-mesele',
     'Tənlik qurmaqla məsələ həlli', 60),
    ('riy-6-ifade-tenlik', 'riy-6-ifade-tenlik-berabersizlikl',
     'Bərabərsizliklər', 70),
    ('riy-6-ifade-tenlik', 'riy-6-ifade-tenlik-xulase',
     'Xülasə', 80),
    ('riy-6-ifade-tenlik', 'riy-6-ifade-tenlik-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    ('riy-6-ifade-tenlik', 'riy-6-ifade-tenlik-riyazi-modellesdirme',
     'STEAM. "Riyazi modelləşdirmə"', 100),
    --  Bolme 7. Ucbucaqlar  (riy-6-ucbucaqlar)
    ('riy-6-ucbucaqlar', 'riy-6-ucbucaqlar-ilkin',
     'İlkin yoxlama', 10),
    ('riy-6-ucbucaqlar', 'riy-6-ucbucaqlar-mediani-tenboleni',
     'Üçbucağın medianı, tənböləni və hündürlüyü', 20),
    ('riy-6-ucbucaqlar', 'riy-6-ucbucaqlar-konqruyentlik-elametleri',
     'Üçbucaqların konqruyentlik əlamətləri', 30),
    ('riy-6-ucbucaqlar', 'riy-6-ucbucaqlar-duz-xetlerin',
     'Düz xətlərin paralelliyi', 40),
    ('riy-6-ucbucaqlar', 'riy-6-ucbucaqlar-bucaqlarinin-cemi',
     'Üçbucağın bucaqlarının cəmi', 50),
    ('riy-6-ucbucaqlar', 'riy-6-ucbucaqlar-terefine-qurulmasi',
     'Üç tərəfinə görə üçbucağın qurulması', 60),
    ('riy-6-ucbucaqlar', 'riy-6-ucbucaqlar-xulase',
     'Xülasə', 70),
    ('riy-6-ucbucaqlar', 'riy-6-ucbucaqlar-umumi',
     'Ümumiləşdirici tapşırıqlar', 80),
    ('riy-6-ucbucaqlar', 'riy-6-ucbucaqlar-geodeziya-qubbeleri',
     'STEAM. "Geodeziya qübbələri"', 90),
    --  Bolme 8. Hendesi fiqurlarin sahesi ve hecmi  (riy-6-sahe-hecm)
    ('riy-6-sahe-hecm', 'riy-6-sahe-hecm-ilkin',
     'İlkin yoxlama', 10),
    ('riy-6-sahe-hecm', 'riy-6-sahe-hecm-ucbucagin',
     'Üçbucağın sahəsi', 20),
    ('riy-6-sahe-hecm', 'riy-6-sahe-hecm-paraleloqram-rombun',
     'Paraleloqram və rombun sahəsi', 30),
    ('riy-6-sahe-hecm', 'riy-6-sahe-hecm-cevrenin-uzunlugu',
     'Çevrənin uzunluğu. Dairənin sahəsi', 40),
    ('riy-6-sahe-hecm', 'riy-6-sahe-hecm-meseleler',
     'Məsələlər', 50),
    ('riy-6-sahe-hecm', 'riy-6-sahe-hecm-duz-sethinin',
     'Düz üçbucaqlı prizmanın və silindrin səthinin sahəsi', 60),
    ('riy-6-sahe-hecm', 'riy-6-sahe-hecm-duz-silindrin',
     'Düz üçbucaqlı prizmanın və silindrin həcmi', 70),
    ('riy-6-sahe-hecm', 'riy-6-sahe-hecm-xulase',
     'Xülasə', 80),
    ('riy-6-sahe-hecm', 'riy-6-sahe-hecm-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    ('riy-6-sahe-hecm', 'riy-6-sahe-hecm-mars-seherciyi',
     'STEAM. "Mars şəhərciyi"', 100),
    --  Bolme 9. Statistika ve ehtimal  (riy-6-statistika)
    ('riy-6-statistika', 'riy-6-statistika-ilkin',
     'İlkin yoxlama', 10),
    ('riy-6-statistika', 'riy-6-statistika-median-moda',
     'Median və moda', 20),
    ('riy-6-statistika', 'riy-6-statistika-tesadufi-hadise',
     'Təsadüfi hadisə', 30),
    ('riy-6-statistika', 'riy-6-statistika-hadisenin-ehtimali',
     'Hadisənin ehtimalı', 40),
    ('riy-6-statistika', 'riy-6-statistika-melumatlarin-tesviri',
     'Məlumatların təsviri', 50),
    ('riy-6-statistika', 'riy-6-statistika-xulase',
     'Xülasə', 60),
    ('riy-6-statistika', 'riy-6-statistika-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    ('riy-6-statistika', 'riy-6-statistika-genealoji-dnt',
     'STEAM. "Genealoji DNT testi və ehtimal nəzəriyyəsi"', 80),
    --  ============  7-ci sinif  ============
    --  BOLME 1. STATISTIKA. EHTIMAL  (riy-7-statistika)
    ('riy-7-statistika', 'riy-7-statistika-melumatin-toplanmasi',
     'Məlumatın toplanması', 10),
    ('riy-7-statistika', 'riy-7-statistika-melumatin-teqdimati',
     'Məlumatın təqdimatı', 20),
    ('riy-7-statistika', 'riy-7-statistika-proqnozlasdirm',
     'Proqnozlaşdırma', 30),
    ('riy-7-statistika', 'riy-7-statistika-hadisenin-ehtimali',
     'Hadisənin ehtimalı', 40),
    ('riy-7-statistika', 'riy-7-statistika-hadiselerin-cemi',
     'Hadisələrin cəmi', 50),
    ('riy-7-statistika', 'riy-7-statistika-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    --  BOLME 2. RASIONAL EDEDLER  (riy-7-rasional)
    ('riy-7-rasional', 'riy-7-rasional-yazilisi-oxunusu',
     'Rasional ədədlərin yazılışı və oxunuşu', 10),
    ('riy-7-rasional', 'riy-7-rasional-dovri-kesrler',
     'Dövri onluq kəsrlər', 20),
    ('riy-7-rasional', 'riy-7-rasional-kesrin-adi',
     'Dövri onluq kəsrin adi kəsrə çevrilməsi', 30),
    ('riy-7-rasional', 'riy-7-rasional-eded-oxunda',
     'Rasional ədədlərin ədəd oxunda göstərilməsi', 40),
    ('riy-7-rasional', 'riy-7-rasional-ededlerin-muqayisesi',
     'Rasional ədədlərin müqayisəsi', 50),
    ('riy-7-rasional', 'riy-7-rasional-modullu-ikiqat',
     'Modullu və ikiqat bərabərsizliklər', 60),
    ('riy-7-rasional', 'riy-7-rasional-ededler-uzerinde',
     'Rasional ədədlər üzərində əməllər və xassələri', 70),
    ('riy-7-rasional', 'riy-7-rasional-umumi',
     'Ümumiləşdirici tapşırıqlar', 80),
    --  BOLME 3. PARALELLIK. PERPENDIKULYARLIQ  (riy-7-paralellik)
    ('riy-7-paralellik', 'riy-7-paralellik-perpendikulyar-mail',
     'Perpendikulyar və mail', 10),
    ('riy-7-paralellik', 'riy-7-paralellik-parcanin-orta',
     'Parçanın orta perpendikulyarı', 20),
    ('riy-7-paralellik', 'riy-7-paralellik-merkezi-simmetriya',
     'Mərkəzi simmetriya', 30),
    ('riy-7-paralellik', 'riy-7-paralellik-xettin-ucuncu',
     'İki düz xəttin üçüncü ilə kəsişməsindən alınan bucaqlar', 40),
    ('riy-7-paralellik', 'riy-7-paralellik-xetlerin-elametleri',
     'Düz xətlərin paralellik əlamətləri', 50),
    ('riy-7-paralellik', 'riy-7-paralellik-uygun-terefleri',
     'Uyğun tərəfləri paralel və ya perpendikulyar olan bucaqlar', 60),
    ('riy-7-paralellik', 'riy-7-paralellik-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    --  BOLME 4. BIRHEDLILER. COXHEDLILER  (riy-7-coxhedliler)
    ('riy-7-coxhedliler', 'riy-7-coxhedliler-birhedliler-onlarin',
     'Birhədlilər və onların hasili', 10),
    ('riy-7-coxhedliler', 'riy-7-coxhedliler-birhedlilerin-nisbeti',
     'Birhədlilərin nisbəti', 20),
    ('riy-7-coxhedliler', 'riy-7-coxhedliler-hasilinin-nisbetinin',
     'Birhədlilərin hasilinin və nisbətinin qüvvətə yüksəldilməsi', 30),
    ('riy-7-coxhedliler', 'riy-7-coxhedliler-standart-sekli',
     'Çoxhədli və onun standart şəkli', 40),
    ('riy-7-coxhedliler', 'riy-7-coxhedliler-toplanmasi-cixilmasi',
     'Çoxhədlilərin toplanması və çıxılması', 50),
    ('riy-7-coxhedliler', 'riy-7-coxhedliler-birhedlinin-vurulmasi',
     'Birhədlinin çoxhədliyə vurulması', 60),
    ('riy-7-coxhedliler', 'riy-7-coxhedliler-coxhedlinin-vurulmasi',
     'Çoxhədlinin çoxhədliyə vurulması', 70),
    ('riy-7-coxhedliler', 'riy-7-coxhedliler-vuruqlara-ayrilmasi',
     'Çoxhədlinin vuruqlara ayrılması', 80),
    ('riy-7-coxhedliler', 'riy-7-coxhedliler-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    --  BOLME 5. UCBUCAQLAR  (riy-7-ucbucaqlar)
    ('riy-7-ucbucaqlar', 'riy-7-ucbucaqlar-terefine-qurulmasi',
     'Üç tərəfinə görə üçbucağın qurulması', 10),
    ('riy-7-ucbucaqlar', 'riy-7-ucbucaqlar-bucaqlari-terefleri',
     'Üçbucağın bucaqları və tərəfləri', 20),
    ('riy-7-ucbucaqlar', 'riy-7-ucbucaqlar-elementleri-tenbolen',
     'Üçbucağın elementləri: tənbölən, median, hündürlük', 30),
    ('riy-7-ucbucaqlar', 'riy-7-ucbucaqlar-umumi',
     'Ümumiləşdirici tapşırıqlar', 40),
    --  BOLM9 6. MUXTESER VURMA DUSTURLARI  (riy-7-muxteser)
    ('riy-7-muxteser', 'riy-7-muxteser-ikihedlilerin-kvadrata',
     'İkihədlilərin kvadrata yüksəldilməsi', 10),
    ('riy-7-muxteser', 'riy-7-muxteser-kvadrati-dusturlarindan',
     'İkihədlinin kvadratı düsturlarından istifadə edərək üçhədlinin vuruqlara ayrılması', 20),
    ('riy-7-muxteser', 'riy-7-muxteser-kvadratlari-ferqi',
     'İki ifadənin kvadratları fərqi', 30),
    ('riy-7-muxteser', 'riy-7-muxteser-kuba-yukseldilmesi',
     'İkihədlinin kuba yüksəldilməsi', 40),
    ('riy-7-muxteser', 'riy-7-muxteser-kublari-cemi',
     'İki ifadənin kubları cəmi və kubları fərqi', 50),
    ('riy-7-muxteser', 'riy-7-muxteser-vurma-dusturlarinin',
     'Müxtəsər vurma düsturlarının tətbiqi', 60),
    ('riy-7-muxteser', 'riy-7-muxteser-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    --  BULM9 7. FUNKSIYA  (riy-7-funksiya)
    ('riy-7-funksiya', 'riy-7-funksiya-verilmesi',
     'Funksiyanın verilməsi', 10),
    ('riy-7-funksiya', 'riy-7-funksiya-xetti',
     'Xətti funksiya', 20),
    ('riy-7-funksiya', 'riy-7-funksiya-qrafiklerinin-qarsiliqli',
     'Xətti funksiyaların qrafiklərinin qarşılıqlı vəziyyəti', 30),
    ('riy-7-funksiya', 'riy-7-funksiya-ikideyisenli-tenlik',
     'İkidəyişənli xətti tənlik və onun qrafiki', 40),
    ('riy-7-funksiya', 'riy-7-funksiya-umumi',
     'Ümumiləşdirici tapşırıqlar', 50),
    --  BOLME 8. XETTI TENLIKLER SISTEMI  (riy-7-tenlikler-sistemi)
    ('riy-7-tenlikler-sistemi', 'riy-7-tenlikler-sistemi-ikideyisenli-xetti',
     'İkidəyişənli xətti tənliklər sistemi', 10),
    ('riy-7-tenlikler-sistemi', 'riy-7-tenlikler-sistemi-qrafik-usulla',
     'İkidəyişənli xətti tənliklər sisteminin qrafik üsulla həlli', 20),
    ('riy-7-tenlikler-sistemi', 'riy-7-tenlikler-sistemi-evezetme-helli',
     'İkidəyişənli xətti tənliklər sisteminin əvəzetmə üsulu ilə həlli', 30),
    ('riy-7-tenlikler-sistemi', 'riy-7-tenlikler-sistemi-toplama-helli',
     'İkidəyişənli xətti tənliklər sisteminin toplama üsulu ilə həlli', 40),
    ('riy-7-tenlikler-sistemi', 'riy-7-tenlikler-sistemi-qurmaqla-mesele',
     'İkidəyişənli xətti tənliklər sistemi qurmaqla məsələ həlli', 50),
    ('riy-7-tenlikler-sistemi', 'riy-7-tenlikler-sistemi-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    --  BOLME 9. UCBUCAQLARIN KONQRUYENTLIYI  (riy-7-konqruyentlik)
    ('riy-7-konqruyentlik', 'riy-7-konqruyentlik-ucbucaqlar',
     'Konqruyent üçbucaqlar', 10),
    ('riy-7-konqruyentlik', 'riy-7-konqruyentlik-birinci-elameti',
     'Üçbucaqların konqruyentliyinin birinci əlaməti', 20),
    ('riy-7-konqruyentlik', 'riy-7-konqruyentlik-ikinci-elameti',
     'Üçbucaqların konqruyentliyinin ikinci əlaməti', 30),
    ('riy-7-konqruyentlik', 'riy-7-konqruyentlik-ucuncu-elameti',
     'Üçbucaqların konqruyentliyinin üçüncü əlaməti', 40),
    ('riy-7-konqruyentlik', 'riy-7-konqruyentlik-beraberyanli-beraberterefli',
     'Bərabəryanlı və bərabərtərəfli üçbucağın xassələri', 50),
    ('riy-7-konqruyentlik', 'riy-7-konqruyentlik-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    --  BOLME 10.SITUASIYA MESELELERI  (riy-7-situasiya)
    ('riy-7-situasiya', 'riy-7-situasiya-xeta-mutleq',
     'Xəta məsələləri. Mütləq xəta', 10),
    ('riy-7-situasiya', 'riy-7-situasiya-nisbi-xeta',
     'Nisbi xəta', 20),
    ('riy-7-situasiya', 'riy-7-situasiya-faiz-meseleleri',
     'Faiz məsələləri', 30),
    ('riy-7-situasiya', 'riy-7-situasiya-coxluqlar-uzerinde',
     'Çoxluqlar üzərində əməllər', 40),
    ('riy-7-situasiya', 'riy-7-situasiya-arasdirma-meseleleri',
     'Araşdırma məsələləri', 50),
    --  ============  9-cu sinif  ============
    --  1. -ci dereceden kok. Rasional ustlu quvvet  (riy-9-kok)
    ('riy-9-kok', 'riy-9-kok-heqiqi-ededler',
     'Həqiqi ədədlər', 10),
    ('riy-9-kok', 'riy-9-kok-eded-oxu',
     'Ədəd oxu', 20),
    ('riy-9-kok', 'riy-9-kok-ededin-mutleq',
     'Həqiqi ədədin mütləq qiyməti', 30),
    ('riy-9-kok', 'riy-9-kok-ededi-coxluqlar',
     'Ədədi çoxluqlar və təqdim formaları', 40),
    ('riy-9-kok', 'riy-9-kok-dereceden-kok',
     'n-ci dərəcədən kök', 50),
    ('riy-9-kok', 'riy-9-kok-kokun-xasseleri',
     'n-ci dərəcədən kökün xassələri', 60),
    ('riy-9-kok', 'riy-9-kok-altindan-cixarilmasi',
     'Vuruğun kök işarəsi altından çıxarılması', 70),
    ('riy-9-kok', 'riy-9-kok-altina-daxil',
     'Vuruğun kök işarəsi altına daxil edilməsi', 80),
    ('riy-9-kok', 'riy-9-kok-rasional-quvvet',
     'Rasional üstlü qüvvət', 90),
    ('riy-9-kok', 'riy-9-kok-quvvetin-xasseleri',
     'Rasional üstlü qüvvətin xassələri', 100),
    ('riy-9-kok', 'riy-9-kok-umumi',
     'Bölmə üzrə ümumiləşdirici tapşırıqlar', 110),
    --  2. Cevre  (riy-9-cevre)
    ('riy-9-cevre', 'riy-9-cevre-merkezi-qovsu',
     'Mərkəzi bucaq. Çevrə qövsü', 10),
    ('riy-9-cevre', 'riy-9-cevre-qovsun-uzunlugu',
     'Qövsün uzunluğu', 20),
    ('riy-9-cevre', 'riy-9-cevre-veterin-xasseleri',
     'Vətərin xassələri', 30),
    ('riy-9-cevre', 'riy-9-cevre-daxiline-bucaq',
     'Çevrə daxilinə çəkilmiş bucaq', 40),
    ('riy-9-cevre', 'riy-9-cevre-toxunan',
     'Çevrəyə toxunan', 50),
    ('riy-9-cevre', 'riy-9-cevre-toxunanlar-kesenler',
     'Çevrəyə çəkilmiş toxunanlar və kəsənlər arasındakı bucaqlar', 60),
    ('riy-9-cevre', 'riy-9-cevre-veter-kesenlerin',
     'Çevrədə vətər və kəsənlərin parçalarının mütənasibliyi', 70),
    ('riy-9-cevre', 'riy-9-cevre-umumi',
     'Bölmə üzrə ümumiləşdirici tapşırıqlar', 80),
    --  3. Funksiyalar. Qrafikler  (riy-9-funksiya)
    ('riy-9-funksiya', 'riy-9-funksiya-kvadratik-qrafiki',
     'Kvadratik funksiya və onun qrafiki', 10),
    ('riy-9-funksiya', 'riy-9-funksiya-muxtelif-formalarda',
     'Kvadratik funksiyanın müxtəlif formalarda təqdimi', 20),
    ('riy-9-funksiya', 'riy-9-funksiya-qrafikinin-qurulmasi',
     'y = ax² + bx + c funksiyasının qrafikinin qurulması', 30),
    ('riy-9-funksiya', 'riy-9-funksiya-ax2-arasdirilmasi',
     'y = ax² + bx + c funksiyasının araşdırılması', 40),
    ('riy-9-funksiya', 'riy-9-funksiya-tetbiqi-mesele',
     'Kvadratik funksiyanın tətbiqi ilə məsələ həlli', 50),
    ('riy-9-funksiya', 'riy-9-funksiya-qrafiki',
     'y = |x| funksiyası və onun qrafiki', 60),
    ('riy-9-funksiya', 'riy-9-funksiya-funksiyasi-qrafiki',
     'y = x³ funksiyası və onun qrafiki', 70),
    ('riy-9-funksiya', 'riy-9-funksiya-umumi',
     'Bölmə üzrə ümumiləşdirici tapşırıqlar', 80),
    --  4. Cevrenin tenliyi  (riy-9-cevre-tenliyi)
    ('riy-9-cevre-tenliyi', 'riy-9-cevre-tenliyi-noqte-arasindaki',
     'İki nöqtə arasındakı məsafə düsturu', 10),
    ('riy-9-cevre-tenliyi', 'riy-9-cevre-tenliyi-cevrenin-tenliyi',
     'Çevrənin tənliyi', 20),
    ('riy-9-cevre-tenliyi', 'riy-9-cevre-tenliyi-uzerindeki-noqtelerin',
     'Çevrə üzərindəki nöqtələrin koordinatları və triqonometrik nisbətlər', 30),
    ('riy-9-cevre-tenliyi', 'riy-9-cevre-tenliyi-daire-sektoru',
     'Dairə sektoru və seqmentinin sahəsi', 40),
    ('riy-9-cevre-tenliyi', 'riy-9-cevre-tenliyi-umumi',
     'Bölmə üzrə ümumiləşdirici tapşırıqlar', 50),
    --  5. Tenlikler. Tenlikler sistemi  (riy-9-tenlikler)
    ('riy-9-tenlikler', 'riy-9-tenlikler-yuksek-dereceli',
     'Yüksək dərəcəli tənliklər', 10),
    ('riy-9-tenlikler', 'riy-9-tenlikler-rasional-tetbiqi',
     'Rasional tənliklər. Rasional tənliklərin tətbiqi ilə məsələ həlli', 20),
    ('riy-9-tenlikler', 'riy-9-tenlikler-modullu',
     'Modullu tənliklər', 30),
    ('riy-9-tenlikler', 'riy-9-tenlikler-irrasional',
     'İrrasional tənliklər', 40),
    ('riy-9-tenlikler', 'riy-9-tenlikler-sistemi',
     'Tənliklər sistemi', 50),
    ('riy-9-tenlikler', 'riy-9-tenlikler-birdereceli-digeri',
     'Bir tənliyi birdərəcəli, digəri ikidərəcəli olan tənliklər sistemi', 60),
    ('riy-9-tenlikler', 'riy-9-tenlikler-sisteminin-cebri',
     'Tənliklər sisteminin cəbri üsulla həlli', 70),
    ('riy-9-tenlikler', 'riy-9-tenlikler-tenliyi-sistemi',
     'Hər iki tənliyi ikidərəcəli olan tənliklər sistemi', 80),
    ('riy-9-tenlikler', 'riy-9-tenlikler-sistemine-getirilen',
     'Tənliklər sisteminə gətirilən məsələlər həlli', 90),
    ('riy-9-tenlikler', 'riy-9-tenlikler-umumi',
     'Bölmə üzrə ümumiləşdirici tapşırıqlar', 100),
    --  6. Coxbucaqlilar  (riy-9-coxbucaqli)
    ('riy-9-coxbucaqli', 'riy-9-coxbucaqli-coxbucaqlilar',
     'Çoxbucaqlılar', 10),
    ('riy-9-coxbucaqli', 'riy-9-coxbucaqli-qabariq-daxili',
     'Qabarıq çoxbucaqlının daxili və xarici bucaqlarının cəmi', 20),
    ('riy-9-coxbucaqli', 'riy-9-coxbucaqli-cevrenin-cekilmis',
     'Çevrənin daxilinə və xaricinə çəkilmiş çoxbucaqlılar', 30),
    ('riy-9-coxbucaqli', 'riy-9-coxbucaqli-ucbucagin-cevreler',
     'Üçbucağın daxilinə və xaricinə çəkilmiş çevrələr', 40),
    ('riy-9-coxbucaqli', 'riy-9-coxbucaqli-dordbucaqlinin-xasseleri',
     'Çevrənin daxilinə və xaricinə çəkilmiş dördbucaqlının xassələri', 50),
    ('riy-9-coxbucaqli', 'riy-9-coxbucaqli-duzgun-cevreler',
     'Düzgün çoxbucaqlının daxilinə və xaricinə çəkilmiş çevrələr', 60),
    ('riy-9-coxbucaqli', 'riy-9-coxbucaqli-duzgun-sahesi',
     'Düzgün çoxbucaqlının sahəsi', 70),
    ('riy-9-coxbucaqli', 'riy-9-coxbucaqli-umumi',
     'Bölmə üzrə ümumiləşdirici tapşırıqlar', 80),
    --  7. Berabersizlikler  (riy-9-berabersizlik)
    ('riy-9-berabersizlik', 'riy-9-berabersizlik-xetti-sistemi',
     'Xətti bərabərsizliklər sistemi. Bərabərsizliklər heyəti', 10),
    ('riy-9-berabersizlik', 'riy-9-berabersizlik-modullu',
     'Modullu bərabərsizliklər', 20),
    ('riy-9-berabersizlik', 'riy-9-berabersizlik-kvadrat',
     'Kvadrat bərabərsizliklər', 30),
    ('riy-9-berabersizlik', 'riy-9-berabersizlik-intervallar-usulu',
     'İntervallar üsulu', 40),
    ('riy-9-berabersizlik', 'riy-9-berabersizlik-rasional-helli',
     'Rasional bərabərsizliklərin intervallar üsulu ilə həlli', 50),
    ('riy-9-berabersizlik', 'riy-9-berabersizlik-irrasional',
     'İrrasional bərabərsizliklər', 60),
    ('riy-9-berabersizlik', 'riy-9-berabersizlik-umumi',
     'Bölmə üzrə ümumiləşdirici tapşırıqlar', 70),
    --  8. Vektorlar  (riy-9-vektorlar)
    ('riy-9-vektorlar', 'riy-9-vektorlar-vektorlar',
     'Vektorlar', 10),
    ('riy-9-vektorlar', 'riy-9-vektorlar-dekart-koordinat',
     'Dekart koordinat müstəvisində vektorlar', 20),
    ('riy-9-vektorlar', 'riy-9-vektorlar-istiqameti-meyil',
     'Vektorun istiqaməti. Meyil bucağı', 30),
    ('riy-9-vektorlar', 'riy-9-vektorlar-triqonometrik-nisbetler',
     'Triqonometrik nisbətlər və vektorun komponentləri', 40),
    ('riy-9-vektorlar', 'riy-9-vektorlar-toplanmasi-cixilmasi',
     'Vektorların toplanması və çıxılması', 50),
    ('riy-9-vektorlar', 'riy-9-vektorlar-kollinear-toplanmasi',
     'Kollinear vektorların toplanması', 60),
    ('riy-9-vektorlar', 'riy-9-vektorlar-olmayan-cixilmasi',
     'Kollinear olmayan vektorların toplanması və çıxılması', 70),
    ('riy-9-vektorlar', 'riy-9-vektorlar-komponentlerin-istifade',
     'Vektorların komponentlərindən istifadə etməklə toplanması', 80),
    ('riy-9-vektorlar', 'riy-9-vektorlar-edede-vurulmasi',
     'Vektorun ədədə vurulması', 90),
    ('riy-9-vektorlar', 'riy-9-vektorlar-verilmis-uzerinde',
     'Komponentləri ilə verilmiş vektorlar üzərində əməllər', 100),
    ('riy-9-vektorlar', 'riy-9-vektorlar-paralel-kocurme',
     'Paralel köçürmə', 110),
    ('riy-9-vektorlar', 'riy-9-vektorlar-hereket-konqruyent',
     'Hərəkət və konqruyent fiqurlar', 120),
    ('riy-9-vektorlar', 'riy-9-vektorlar-umumi',
     'Bölmə üzrə ümumiləşdirici tapşırıqlar', 130),
    --  9. Ededi ardicilliqlar  (riy-9-silsile)
    ('riy-9-silsile', 'riy-9-silsile-ededi-ardicilliq',
     'Ədədi ardıcıllıq', 10),
    ('riy-9-silsile', 'riy-9-silsile-ededi',
     'Ədədi silsilə', 20),
    ('riy-9-silsile', 'riy-9-silsile-ededi-dusturu',
     'Ədədi silsilənin n-ci həddinin düsturu', 30),
    ('riy-9-silsile', 'riy-9-silsile-ededi-xasseleri',
     'Ədədi silsilənin xassələri', 40),
    ('riy-9-silsile', 'riy-9-silsile-ededi-ilk-heddinin',
     'Ədədi silsilənin ilk n həddinin cəmi düsturu', 50),
    ('riy-9-silsile', 'riy-9-silsile-hendesi',
     'Həndəsi silsilə', 60),
    ('riy-9-silsile', 'riy-9-silsile-hendesi-dusturu',
     'Həndəsi silsilənin n-ci həddinin düsturu', 70),
    ('riy-9-silsile', 'riy-9-silsile-hendesi-xasseleri',
     'Həndəsi silsilənin xassələri', 80),
    ('riy-9-silsile', 'riy-9-silsile-hendesi-ilk-heddinin',
     'Həndəsi silsilənin ilk n həddinin cəmi düsturu', 90),
    ('riy-9-silsile', 'riy-9-silsile-sonsuz-azalan',
     'Sonsuz azalan həndəsi silsilənin cəmi', 100),
    ('riy-9-silsile', 'riy-9-silsile-umumi',
     'Bölmə üzrə ümumiləşdirici tapşırıqlar', 110),
    --  10. Melumatin teqdimi. Birlesmeler. Ehtimal  (riy-9-ehtimal)
    ('riy-9-ehtimal', 'riy-9-ehtimal-paylanmasi-cedveli',
     'Tezlik paylanması cədvəli', 10),
    ('riy-9-ehtimal', 'riy-9-ehtimal-nisbi-tezlik',
     'Nisbi tezlik', 20),
    ('riy-9-ehtimal', 'riy-9-ehtimal-histoqrami-poliqonu',
     'Tezlik histoqramı. Tezlik poliqonu', 30),
    ('riy-9-ehtimal', 'riy-9-ehtimal-paylanmasina-ededi',
     'Tezlik paylanmasına görə ədədi orta', 40),
    ('riy-9-ehtimal', 'riy-9-ehtimal-birlesmeler',
     'Birləşmələr', 50),
    ('riy-9-ehtimal', 'riy-9-ehtimal-yerdeyisme-npn',
     'Permutasiya-yerdəyişmə, nPn', 60),
    ('riy-9-ehtimal', 'riy-9-ehtimal-tekrarli-permutasiyalar',
     'Təkrarlı permutasiyalar', 70),
    ('riy-9-ehtimal', 'riy-9-ehtimal-yerlesdirme-npk',
     'Permutasiya-yerləşdirmə, nPk', 80),
    ('riy-9-ehtimal', 'riy-9-ehtimal-kombinezon-nck',
     'Kombinezon, nCk', 90),
    ('riy-9-ehtimal', 'riy-9-ehtimal-hesablanmasina-mesele',
     'Ehtimalın hesablanmasına aid məsələ həlli', 100),
    ('riy-9-ehtimal', 'riy-9-ehtimal-umumi',
     'Bölmə üzrə ümumiləşdirici tapşırıqlar', 110),
    --  ============  10-cu sinif  ============
    --  1.Funksiyalar  (riy-10-funksiya)
    ('riy-10-funksiya', 'riy-10-funksiya-verilme-usullari',
     'Funksiya və onun verilmə üsulları', 10),
    ('riy-10-funksiya', 'riy-10-funksiya-xasseleri',
     'Funksiyaların xassələri', 20),
    ('riy-10-funksiya', 'riy-10-funksiya-cut-tek',
     'Cüt funksiya, tək funksiya', 30),
    ('riy-10-funksiya', 'riy-10-funksiya-qrafiki-xasseleri',
     'Bəzi funksiyaların qrafiki və xassələri', 40),
    ('riy-10-funksiya', 'riy-10-funksiya-quvvet',
     'y = xⁿ (n ∈ N) qüvvət funksiyası', 50),
    ('riy-10-funksiya', 'riy-10-funksiya-hisse-verilmis',
     'Hissə-hissə verilmiş funksiyalar', 60),
    ('riy-10-funksiya', 'riy-10-funksiya-qrafiklerin-cevrilmesi',
     'Qrafiklərin çevrilməsi', 70),
    ('riy-10-funksiya', 'riy-10-funksiya-murekkeb',
     'Mürəkkəb funksiya', 80),
    ('riy-10-funksiya', 'riy-10-funksiya-ters',
     'Tərs funksiya', 90),
    ('riy-10-funksiya', 'riy-10-funksiya-teyin-oblasti',
     'Bəzi funksiyaların təyin oblastı və qiymətlər çoxluğu', 100),
    ('riy-10-funksiya', 'riy-10-funksiya-umumi',
     'Ümumiləşdirici tapşırıqlar', 110),
    --  2. Fezada noqte, duz xett, mustevi  (riy-10-feza)
    ('riy-10-feza', 'riy-10-feza-noqte-xett',
     'Fəzada nöqtə, düz xətt və müstəvi', 10),
    ('riy-10-feza', 'riy-10-feza-duz-paralelliyi',
     'Düz xəttin müstəviyə paralelliyi', 20),
    ('riy-10-feza', 'riy-10-feza-duz-perpendikulyar',
     'Düz xəttin müstəviyə perpendikulyarlığı', 30),
    ('riy-10-feza', 'riy-10-feza-perpendikulyar-mailler',
     'Perpendikulyar və maillər', 40),
    ('riy-10-feza', 'riy-10-feza-perpendikulyar-teoremi',
     'Üç perpendikulyar teoremi', 50),
    ('riy-10-feza', 'riy-10-feza-mustevilerin-qarsiliqli',
     'Müstəvilərin qarşılıqlı vəziyyəti. İkiüzlü bucaqlar', 60),
    ('riy-10-feza', 'riy-10-feza-perpendikulyar-musteviler',
     'Perpendikulyar müstəvilər', 70),
    ('riy-10-feza', 'riy-10-feza-paralel-musteviler',
     'Paralel müstəvilər', 80),
    ('riy-10-feza', 'riy-10-feza-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    --  3. Triqonometrik ifadeler ve onlarin cevrilmeleri  (riy-10-triq-ifade)
    ('riy-10-triq-ifade', 'riy-10-triq-ifade-donme-bucaqlari',
     'Dönmə bucaqları', 10),
    ('riy-10-triq-ifade', 'riy-10-triq-ifade-bucagin-radian',
     'Bucağın radian və dərəcə ölçüsü', 20),
    ('riy-10-triq-ifade', 'riy-10-triq-ifade-qovsun-uzunlugu',
     'Qövsün uzunluğu. Sektorun sahəsi', 30),
    ('riy-10-triq-ifade', 'riy-10-triq-ifade-xetti-suret',
     'Xətti sürət, bucaq sürəti', 40),
    ('riy-10-triq-ifade', 'riy-10-triq-ifade-funksiyalar',
     'Triqonometrik funksiyalar', 50),
    ('riy-10-triq-ifade', 'riy-10-triq-ifade-vahid-cevre',
     'Vahid çevrə və triqonometrik funksiyalar', 60),
    ('riy-10-triq-ifade', 'riy-10-triq-ifade-cevirme-dusturlari',
     'Çevirmə düsturları', 70),
    ('riy-10-triq-ifade', 'riy-10-triq-ifade-eynilikler',
     'Triqonometrik eyniliklər', 80),
    ('riy-10-triq-ifade', 'riy-10-triq-ifade-toplama-dusturlari',
     'Toplama düsturları', 90),
    ('riy-10-triq-ifade', 'riy-10-triq-ifade-dusturlarindan-alinan',
     'Toplama düsturlarından alınan nəticələr', 100),
    ('riy-10-triq-ifade', 'riy-10-triq-ifade-sadelesdirilme',
     'Triqonometrik ifadələrin sadələşdirilməsi', 110),
    ('riy-10-triq-ifade', 'riy-10-triq-ifade-umumi',
     'Ümumiləşdirici tapşırıqlar', 120),
    --  4.Sinuslar teoremi ve kosinuslar teoremi  (riy-10-sinus-kosinus)
    ('riy-10-sinus-kosinus', 'riy-10-sinus-kosinus-teoremi',
     'Sinuslar teoremi', 10),
    ('riy-10-sinus-kosinus', 'riy-10-sinus-kosinus-kosinuslar-teoremi',
     'Kosinuslar teoremi', 20),
    ('riy-10-sinus-kosinus', 'riy-10-sinus-kosinus-umumi',
     'Ümumiləşdirici tapşırıqlar', 30),
    --  5. Triqonometrik funksiyalar ve onlarin qrafikleri  (riy-10-triq-qrafik)
    ('riy-10-triq-qrafik', 'riy-10-triq-qrafik-dovri-funksiyalar',
     'Dövri funksiyalar', 10),
    ('riy-10-triq-qrafik', 'riy-10-triq-qrafik-sin-funksiyalarini',
     'y = sin x və y = cos x funksiyalarının qrafikləri', 20),
    ('riy-10-triq-qrafik', 'riy-10-triq-qrafik-sin-cevrilmeleri',
     'y = sin x və y = cos x funksiyalarının qrafiklərinin çevrilmələri', 30),
    ('riy-10-triq-qrafik', 'riy-10-triq-qrafik-funksiyalar-hadiseler',
     'Triqonometrik funksiyalar və dövri hadisələr', 40),
    ('riy-10-triq-qrafik', 'riy-10-triq-qrafik-tan-ctg',
     'y = tan x və y = ctg x funksiyalarının qrafikləri', 50),
    ('riy-10-triq-qrafik', 'riy-10-triq-qrafik-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    --  6. Coxuzluler  (riy-10-coxuzlu)
    ('riy-10-coxuzlu', 'riy-10-coxuzlu-coxuzluler',
     'Çoxüzlülər', 10),
    ('riy-10-coxuzlu', 'riy-10-coxuzlu-prizmalar',
     'Prizmalar', 20),
    ('riy-10-coxuzlu', 'riy-10-coxuzlu-onlarin-muxtelif',
     'Çoxüzlülər və onların müxtəlif tərəflərdən görünüşləri', 30),
    ('riy-10-coxuzlu', 'riy-10-coxuzlu-prizmanin-sahesi',
     'Prizmanın səthinin sahəsi', 40),
    ('riy-10-coxuzlu', 'riy-10-coxuzlu-mustevi-kesikleri',
     'Prizmanın müstəvi kəsikləri', 50),
    ('riy-10-coxuzlu', 'riy-10-coxuzlu-piramidanin-yan',
     'Piramida. Piramidanın yan səthinin və tam səthinin sahəsi', 60),
    ('riy-10-coxuzlu', 'riy-10-coxuzlu-kesik-piramida',
     'Kəsik piramida', 70),
    ('riy-10-coxuzlu', 'riy-10-coxuzlu-umumi',
     'Ümumiləşdirici tapşırıqlar', 80),
    --  7. Triqonometrik tenlikler  (riy-10-triq-tenlik)
    ('riy-10-triq-tenlik', 'riy-10-triq-tenlik-ters-funksiyalar',
     'Tərs triqonometrik funksiyalar', 10),
    ('riy-10-triq-tenlik', 'riy-10-triq-tenlik-sade',
     'Sadə triqonometrik tənliklər', 20),
    ('riy-10-triq-tenlik', 'riy-10-triq-tenlik-hell-usullari',
     'Triqonometrik tənliklərin həll üsulları', 30),
    ('riy-10-triq-tenlik', 'riy-10-triq-tenlik-tetbiqi-mesele',
     'Triqonometrik tənliklərin tətbiqi ilə məsələ həlli', 40),
    ('riy-10-triq-tenlik', 'riy-10-triq-tenlik-umumi',
     'Ümumiləşdirici tapşırıqlar', 50),
    --  8. Feza fiqurlarinin hecmi  (riy-10-hecm)
    ('riy-10-hecm', 'riy-10-hecm-prizmanin',
     'Prizmanın həcmi', 10),
    ('riy-10-hecm', 'riy-10-hecm-piramidanin',
     'Piramidanın həcmi', 20),
    ('riy-10-hecm', 'riy-10-hecm-feza-oxsarligi',
     'Fəza fiqurlarının oxşarlığı', 30),
    ('riy-10-hecm', 'riy-10-hecm-oxsar-sethleri',
     'Oxşar fəza fiqurlarının səthləri və həcmləri', 40),
    ('riy-10-hecm', 'riy-10-hecm-kesik-piramidanin',
     'Kəsik piramidanın həcmi', 50),
    ('riy-10-hecm', 'riy-10-hecm-fezada-simmetriya',
     'Fəzada simmetriya', 60),
    ('riy-10-hecm', 'riy-10-hecm-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    --  9. Pokazatelnaya i logarifmicheskaya funktsii  (riy-10-ustlu-loqarifm)
    ('riy-10-ustlu-loqarifm', 'riy-10-ustlu-loqarifm-heqiqi-quvvet',
     'Həqiqi üstlü qüvvət', 10),
    ('riy-10-ustlu-loqarifm', 'riy-10-ustlu-loqarifm-funksiya',
     'Üstlü funksiya', 20),
    ('riy-10-ustlu-loqarifm', 'riy-10-ustlu-loqarifm-ededin',
     'Ədədin loqarifmi', 30),
    ('riy-10-ustlu-loqarifm', 'riy-10-ustlu-loqarifm-loqarifmik-funksiya',
     'Loqarifmik funksiya', 40),
    ('riy-10-ustlu-loqarifm', 'riy-10-ustlu-loqarifm-xasseleri',
     'Loqarifmin xassələri', 50),
    ('riy-10-ustlu-loqarifm', 'riy-10-ustlu-loqarifm-skala-mesele',
     'Loqarifmik şkala və məsələ həlli', 60),
    ('riy-10-ustlu-loqarifm', 'riy-10-ustlu-loqarifm-tenlikler',
     'Üstlü tənliklər', 70),
    ('riy-10-ustlu-loqarifm', 'riy-10-ustlu-loqarifm-loqarifmik-tenlikler',
     'Loqarifmik tənliklər', 80),
    ('riy-10-ustlu-loqarifm', 'riy-10-ustlu-loqarifm-berabersizlikl',
     'Üstlü bərabərsizliklər', 90),
    ('riy-10-ustlu-loqarifm', 'riy-10-ustlu-loqarifm-loqarifmik-berabersizlikl',
     'Loqarifmik bərabərsizliklər', 100),
    ('riy-10-ustlu-loqarifm', 'riy-10-ustlu-loqarifm-umumi',
     'Ümumiləşdirici tapşırıqlar', 110),
    --  10.Informatsiya i prognoz  (riy-10-statistika)
    ('riy-10-statistika', 'riy-10-statistika-kulliyyat-secim',
     'Külliyyat və seçim. Təsadüfi seçim və növləri', 10),
    ('riy-10-statistika', 'riy-10-statistika-melumatin-teqdimi',
     'Məlumatın təqdimi', 20),
    ('riy-10-statistika', 'riy-10-statistika-binomial-acilis',
     'Binomial açılış', 30),
    ('riy-10-statistika', 'riy-10-statistika-bernulli-sinaqlari',
     'Bernulli sınaqları', 40),
    ('riy-10-statistika', 'riy-10-statistika-umumi',
     'Ümumiləşdirici tapşırıqlar', 50),
    --  ============  11-ci sinif  ============
    --  1. Coxhedliler  (riy-11-coxhedli)
    ('riy-11-coxhedli', 'riy-11-coxhedli-bolunmesi',
     'Çoxhədlinin çoxhədliyə bölünməsi', 10),
    ('riy-11-coxhedli', 'riy-11-coxhedli-qaliq-teorem',
     'Qalıq haqqında teorem', 20),
    ('riy-11-coxhedli', 'riy-11-coxhedli-vuruqlari-teorem',
     'Çoxhədlinin vuruqları haqqında teorem', 30),
    ('riy-11-coxhedli', 'riy-11-coxhedli-koklerin-tapilmasi',
     'Rasional köklərin tapılması', 40),
    ('riy-11-coxhedli', 'riy-11-coxhedli-kompleks-ededler',
     'Kompleks ədədlər haqqında', 50),
    ('riy-11-coxhedli', 'riy-11-coxhedli-cebrin-esas',
     'Cəbrin əsas teoremi', 60),
    ('riy-11-coxhedli', 'riy-11-coxhedli-funksiya',
     'Çoxhədli funksiya', 70),
    ('riy-11-coxhedli', 'riy-11-coxhedli-rasional-funksiya',
     'Rasional funksiya', 80),
    ('riy-11-coxhedli', 'riy-11-coxhedli-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    --  2. Fezada vektorlar  (riy-11-feza-vektor)
    ('riy-11-feza-vektor', 'riy-11-feza-vektor-dekart-koordinat',
     'Fəzada Dekart koordinat sistemi', 10),
    ('riy-11-feza-vektor', 'riy-11-feza-vektor-fezada-vektorlar',
     'Fəzada vektorlar', 20),
    ('riy-11-feza-vektor', 'riy-11-feza-vektor-skalyar-hasili',
     'İki vektorun skalyar hasili', 30),
    ('riy-11-feza-vektor', 'riy-11-feza-vektor-duz-xettin',
     'Düz xəttin ümumi tənliyi', 40),
    ('riy-11-feza-vektor', 'riy-11-feza-vektor-mustevinin-tenliyi',
     'Müstəvinin tənliyi', 50),
    ('riy-11-feza-vektor', 'riy-11-feza-vektor-mustevilerin-qarsiliqli',
     'Müstəvilərin qarşılıqlı vəziyyəti', 60),
    ('riy-11-feza-vektor', 'riy-11-feza-vektor-sferanin-tenliyi',
     'Sferanın tənliyi', 70),
    ('riy-11-feza-vektor', 'riy-11-feza-vektor-mustevide-cevrilmeler',
     'Fəzada və müstəvidə çevrilmələr', 80),
    ('riy-11-feza-vektor', 'riy-11-feza-vektor-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    --  3. Limit  (riy-11-limit)
    ('riy-11-limit', 'riy-11-limit-funksiyanin-noqtede',
     'Funksiyanın nöqtədə limiti', 10),
    ('riy-11-limit', 'riy-11-limit-xasseleri',
     'Limitin xassələri', 20),
    ('riy-11-limit', 'riy-11-limit-funksiyanin-kesilmezliyi',
     'Funksiyanın kəsilməzliyi', 30),
    ('riy-11-limit', 'riy-11-limit-triqonometrik-funksiyalara',
     'Triqonometrik funksiyalara aid xüsusi limitlər', 40),
    ('riy-11-limit', 'riy-11-limit-sonsuz-sonsuzluqda',
     'Sonsuz limitlər və sonsuzluqda limit. Şaquli və üfüqi asimptotlar', 50),
    ('riy-11-limit', 'riy-11-limit-ededi-ardicilligin',
     'Ədədi ardıcıllığın limiti', 60),
    ('riy-11-limit', 'riy-11-limit-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    --  4. Firlanma fiqurlari. Silindr, konus, kure  (riy-11-firlanma)
    ('riy-11-firlanma', 'riy-11-firlanma-fiqurlari',
     'Fırlanma fiqurları', 10),
    ('riy-11-firlanma', 'riy-11-firlanma-silindr',
     'Silindr', 20),
    ('riy-11-firlanma', 'riy-11-firlanma-silindrin-sahesi',
     'Silindrin səthinin sahəsi', 30),
    ('riy-11-firlanma', 'riy-11-firlanma-konus',
     'Konus', 40),
    ('riy-11-firlanma', 'riy-11-firlanma-konusun-sahesi',
     'Konusun səthinin sahəsi', 50),
    ('riy-11-firlanma', 'riy-11-firlanma-mustevi-kesikleri',
     'Silindrin və konusun müstəvi kəsikləri', 60),
    ('riy-11-firlanma', 'riy-11-firlanma-kesik-sahesi',
     'Kəsik konus və səthinin sahəsi', 70),
    ('riy-11-firlanma', 'riy-11-firlanma-kure-hisselerinin',
     'Kürə və hissələrinin səthinin sahəsi', 80),
    ('riy-11-firlanma', 'riy-11-firlanma-murekkeb-sahesi',
     'Mürəkkəb fiqurların səthinin sahəsi', 90),
    ('riy-11-firlanma', 'riy-11-firlanma-oxsar-sahesi',
     'Oxşar fiqurların səthinin sahəsi', 100),
    ('riy-11-firlanma', 'riy-11-firlanma-umumi',
     'Ümumiləşdirici tapşırıqlar', 110),
    --  5. Funksiyanin toremesi  (riy-11-toreme)
    ('riy-11-toreme', 'riy-11-toreme-deyismenin-orta',
     'Dəyişmənin orta sürəti, dəyişmənin ani sürəti', 10),
    ('riy-11-toreme', 'riy-11-toreme-funksiyanin',
     'Funksiyanın törəməsi', 20),
    ('riy-11-toreme', 'riy-11-toreme-diferensiallam-qaydalari',
     'Diferensiallama qaydaları', 30),
    ('riy-11-toreme', 'riy-11-toreme-hasilin',
     'Hasilin törəməsi', 40),
    ('riy-11-toreme', 'riy-11-toreme-nisbetin',
     'Nisbətin törəməsi', 50),
    ('riy-11-toreme', 'riy-11-toreme-murekkeb-funksiyanin',
     'Mürəkkəb funksiyanın törəməsi', 60),
    ('riy-11-toreme', 'riy-11-toreme-tetbiqi-mesele',
     'Törəmənin tətbiqi ilə məsələ həlli', 70),
    ('riy-11-toreme', 'riy-11-toreme-ikinci-tertib',
     'İkinci tərtib törəmə', 80),
    ('riy-11-toreme', 'riy-11-toreme-ustlu-funksiyanin',
     'Üstlü funksiyanın törəməsi', 90),
    ('riy-11-toreme', 'riy-11-toreme-loqarifmik-funksiyanin',
     'Loqarifmik funksiyanın törəməsi', 100),
    ('riy-11-toreme', 'riy-11-toreme-triqonometrik-funksiyalarin',
     'Triqonometrik funksiyaların törəməsi', 110),
    ('riy-11-toreme', 'riy-11-toreme-umumi',
     'Ümumiləşdirici tapşırıqlar', 120),
    --  6. Firlanma fiqurlarinin hecmi  (riy-11-firlanma-hecm)
    ('riy-11-firlanma-hecm', 'riy-11-firlanma-hecm-silindrin',
     'Silindrin həcmi', 10),
    ('riy-11-firlanma-hecm', 'riy-11-firlanma-hecm-konusun',
     'Konusun həcmi', 20),
    ('riy-11-firlanma-hecm', 'riy-11-firlanma-hecm-kesik-konusun',
     'Kəsik konusun həcmi', 30),
    ('riy-11-firlanma-hecm', 'riy-11-firlanma-hecm-kure-hisselerinin',
     'Kürə və hissələrinin həcmi', 40),
    ('riy-11-firlanma-hecm', 'riy-11-firlanma-hecm-oxsar-fiqurlarin',
     'Oxşar fiqurların həcmi', 50),
    ('riy-11-firlanma-hecm', 'riy-11-firlanma-hecm-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    --  7. Toremenin tetbiqi ile funksiyanin arasdirilmasi  (riy-11-arasdirma)
    ('riy-11-arasdirma', 'riy-11-arasdirma-artma-azalma',
     'Funksiyanın artma və azalma aralıqlarının tapılması', 10),
    ('riy-11-arasdirma', 'riy-11-arasdirma-bohran-noqteleri',
     'Funksiyanın böhran nöqtələri və ekstremumları', 20),
    ('riy-11-arasdirma', 'riy-11-arasdirma-toremenin-tetbiqi',
     'Törəmənin tətbiqi ilə funksiyanın qrafikinin qurulması', 30),
    ('riy-11-arasdirma', 'riy-11-arasdirma-ekstremumun-tapilmasina',
     'Ekstremumun tapılmasına aid məsələ həlli. Optimallaşdırma', 40),
    ('riy-11-arasdirma', 'riy-11-arasdirma-umumi',
     'Ümumiləşdirici tapşırıqlar', 50),
    --  8. Inteqral  (riy-11-inteqral)
    ('riy-11-inteqral', 'riy-11-inteqral-ibtidai-funksiya',
     'İbtidai funksiya. Qeyri-müəyyən inteqral', 10),
    ('riy-11-inteqral', 'riy-11-inteqral-mueyyen-sahe',
     'Müəyyən inteqral və sahə', 20),
    ('riy-11-inteqral', 'riy-11-inteqral-eyrinin-ehate',
     'Əyrinin əhatə etdiyi sahə', 30),
    ('riy-11-inteqral', 'riy-11-inteqral-nyuton-leybnis',
     'Müəyyən inteqral. Nyuton-Leybnis düsturu', 40),
    ('riy-11-inteqral', 'riy-11-inteqral-mueyyen-xasseleri',
     'Müəyyən inteqralın xassələri', 50),
    ('riy-11-inteqral', 'riy-11-inteqral-eyrilerle-hududlanmis',
     'Əyrilərlə hüdudlanmış fiqurun sahəsi', 60),
    ('riy-11-inteqral', 'riy-11-inteqral-firlanmadan-alinan',
     'Müəyyən inteqral və fırlanmadan alınan fiqurların həcmi', 70),
    ('riy-11-inteqral', 'riy-11-inteqral-umumi',
     'Ümumiləşdirici tapşırıqlar', 80),
    --  9. Statistika ve ehtimal  (riy-11-statistika)
    ('riy-11-statistika', 'riy-11-statistika-gostericiler',
     'Statistik göstəricilər', 10),
    ('riy-11-statistika', 'riy-11-statistika-melumatin-formalari',
     'Məlumatın paylanma formaları', 20),
    ('riy-11-statistika', 'riy-11-statistika-normal-paylanma',
     'Normal paylanma', 30),
    ('riy-11-statistika', 'riy-11-statistika-qutu-qulp',
     'Qutu-qulp diaqramı', 40),
    ('riy-11-statistika', 'riy-11-statistika-tesadufi-hadiseler',
     'Təsadüfi hadisələr və ehtimal', 50),
    ('riy-11-statistika', 'riy-11-statistika-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    --  10. Tenlikler, berabersizlikler, tenlikler sistemi  (riy-11-tenlikler)
    ('riy-11-tenlikler', 'riy-11-tenlikler-irrasional-berabersizlikl',
     'İrrasional tənliklər və bərabərsizliklər', 10),
    ('riy-11-tenlikler', 'riy-11-tenlikler-ustlu-sistemi',
     'Üstlü tənliklər sistemi', 20),
    ('riy-11-tenlikler', 'riy-11-tenlikler-loqarifmik-sistemi',
     'Loqarifmik tənliklər sistemi', 30),
    ('riy-11-tenlikler', 'riy-11-tenlikler-umumi',
     'Ümumiləşdirici tapşırıqlar', 40)
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
    join public.levels   l on l.id = p.level_id and l.code = '5';
  if k <> 89 then
    raise exception 'Riyaziyyat 5-ci alt movzulari: 89 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'riyaziyyat'
    join public.levels   l on l.id = p.level_id and l.code = '6';
  if k <> 85 then
    raise exception 'Riyaziyyat 6-ci alt movzulari: 85 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'riyaziyyat'
    join public.levels   l on l.id = p.level_id and l.code = '7';
  if k <> 63 then
    raise exception 'Riyaziyyat 7-ci alt movzulari: 63 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'riyaziyyat'
    join public.levels   l on l.id = p.level_id and l.code = '9';
  if k <> 92 then
    raise exception 'Riyaziyyat 9-cu alt movzulari: 92 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'riyaziyyat'
    join public.levels   l on l.id = p.level_id and l.code = '10';
  if k <> 77 then
    raise exception 'Riyaziyyat 10-cu alt movzulari: 77 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'riyaziyyat'
    join public.levels   l on l.id = p.level_id and l.code = '11';
  if k <> 77 then
    raise exception 'Riyaziyyat 11-ci alt movzulari: 77 gozlenilirdi, % tapildi', k;
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
   where t.parent_id is null and l.code in ('5','6','7','8','9','10','11');
  if k <> 68 then
    raise exception 'Riyaziyyat 5-11 ust movzu sayi 68 deyil: %', k;
  end if;

  raise notice 'Riyaziyyat 5-11 (8-ci sinif db/74-de): 483 alt movzu hazir.';
end $$;
