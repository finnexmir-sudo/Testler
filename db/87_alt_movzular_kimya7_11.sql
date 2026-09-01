-- =====================================================================
--  87_alt_movzular_kimya7_11.sql : KIMYA 7-11 - ALT MOVZULAR
--
--  NIYE
--  Altinci fenn.  Riyaziyyat, heyat bilgisi, informatika, fizika
--  hazirdir.  Kimya 7-ci sinifden baslayir (1-6-da yoxdur).
--
--  MENBE: e-derslik.edu.az "Movzular" agaci - kitab id 871/872 (7),
--  935/936 (8), 505 (9), 739 (10), 349 (11).  Adlar EYNILE goturulub.
--
--  DERSLIYIN QURULUSU 9 VE 11-CI SINIFDE COX PILLELIDIR:
--
--  9-cu sinif: derslikde YALNIZ 3 boyuk boluk var ("I. METALLAR",
--  "II. QEYRİ-METALLAR", "III. ÜZVİ KİMYAYA GİRİŞ...") - hər biri
--  ozunun icinde "Fəsil N." basliqlari ile bolunub, bazada ise 6
--  movzu var.  "I" boluk sehife 23-den iki movzuya (metal-umumi/
--  metallar), "II" boluk sehife 89 ve 121-den UC movzuya (halogen-
--  kukurd/azot-fosfor/karbon-silisium) bolunur.  "Fəsil N." basliqlari
--  ozleri movzu deyil - novbeti derslə eyni sehifede olsalar da,
--  bezen basqa sehifede oldugu ucun umumi qaydayla (bolmebasliq)
--  tutulmur, ona gore herfi mетnleri xaric siyahisindadir.
--
--  11-ci sinif: daha da derindir - "I. Hissə" YEGANE boluk daxilinde
--  DORD movzu gizlenib (spirtler/aldehid-tursu/efir-yag/karbohidrat),
--  sehife 50/97/118-den bolunur.  "fəsil N." basliqlari (kicik herflə)
--  eyni sebeble xaric siyahisindadir.  Bir yazi qusuru var:
--  "Ümumiləşdİrİcl sual və tapşırıqlar" (s.47) - boyuk/kicik herf
--  qarisigi. "3.5.Sabun..." bosluqsuz nomrelidir (s.109).
--
--  7-ci sinifin "Giriş" bolmesi (1 ders - laboratoriya tehlukesizliyi)
--  nomresiz ayri "==" bolme kimi gelir, bazada ayri movzusu yoxdur -
--  ilk movzuya (kim-7-elementler) elave edildi.
--
--  10-cu sinifin "Kimya" / "Giriş" bolmesi (1 ders, dersliyin ozunun
--  "bu kitabla nece isləmeli" tipli girisidir - real kimya mezmunu
--  deyil) ATILIB, informatika 5-in "Giriş"i kimi.
--
--  10-cu sinifde III BÖLMƏ (Alkadienlər) ve V BÖLMƏ (Tsikloalkanlar)
--  EYNI movzuya (kim-10-dien-tsiklo) gedir, aralarinda IV BÖLMƏ
--  (Alkinler, oz movzusu) olsa da - setirler birlesir, sort davam edir.
--
--  ELLE YAZILMIR: tools/alt_movzular.py cixarir.
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
--   * yazi (3): yazi qusuru (bosluq, herf)
--       7-ci   s.55   3.2 Meisetde istifade edilen muhum kimyevi birlesmeler.
--                    -> Meisetde istifade edilen muhum kimyevi birlesmeler
--       11-ci  s.47   UmumilesdIrIcl sual ve tapsiriqlar
--                    -> Umumilesdirici sual ve tapsiriqlar
--       11-ci  s.109  3.5.Sabun ve sintetik yuyucu maddeler
--                    -> Sabun ve sintetik yuyucu maddeler

insert into public.topics (subject_id, level_id, parent_id, slug, name, sort)
select p.subject_id, p.level_id, p.id, v.slug, v.name, v.sort
  from (values
    --  ============  7-ci sinif  ============
    --  Giris. Kimya neyi oyrenir?  (kim-7-elementler)
    ('kim-7-elementler', 'kim-7-elementler-kimya-laboratoriyasi',
     'Kimya laboratoriyasının avadanlıqları və laboratoriyada təhlükəsizlik qaydaları', 10),
    --  Bolme 1. Kimyevi elementler  (kim-7-elementler)
    ('kim-7-elementler', 'kim-7-elementler-kimyevi-simvollari',
     'Kimyəvi elementlər və onların simvolları', 20),
    ('kim-7-elementler', 'kim-7-elementler-bioelementler',
     'Bioelementlər', 30),
    ('kim-7-elementler', 'kim-7-elementler-cansiz-tebietde',
     'Cansız təbiətdə olan mühüm elementlər', 40),
    ('kim-7-elementler', 'kim-7-elementler-metallar-xasseleri',
     'Metallar və onların xassələri', 50),
    ('kim-7-elementler', 'kim-7-elementler-qeyri-allotropiya',
     'Qeyri-metallar və onların xassələri. Allotropiya', 60),
    ('kim-7-elementler', 'kim-7-elementler-elm-texnologiya',
     'Elm, texnologiya, həyat', 70),
    ('kim-7-elementler', 'kim-7-elementler-layihe',
     'Layihə', 80),
    ('kim-7-elementler', 'kim-7-elementler-xulase',
     'Xülasə', 90),
    ('kim-7-elementler', 'kim-7-elementler-umumi',
     'Ümumiləşdirici tapşırıqlar', 100),
    --  Bolme 2. Atomun qurulusu  (kim-7-atom)
    ('kim-7-atom', 'kim-7-atom-qurulusu',
     'Atomun quruluşu', 10),
    ('kim-7-atom', 'kim-7-atom-nuve-yuku',
     'Nüvə yükü və kütlə ədədi', 20),
    ('kim-7-atom', 'kim-7-atom-izotoplar-ionlar',
     'İzotoplar və ionlar', 30),
    ('kim-7-atom', 'kim-7-atom-elm-texnologiya',
     'Elm, texnologiya, həyat', 40),
    ('kim-7-atom', 'kim-7-atom-layihe',
     'Layihə', 50),
    ('kim-7-atom', 'kim-7-atom-xulase',
     'Xülasə', 60),
    ('kim-7-atom', 'kim-7-atom-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    --  Bolme 3. Kimyevi birlesmeler  (kim-7-birlesmeler)
    ('kim-7-birlesmeler', 'kim-7-birlesmeler-onlarin-formullari',
     'Kimyəvi birləşmələr, onların formulları və adları', 10),
    ('kim-7-birlesmeler', 'kim-7-birlesmeler-meisetde-istifade',
     'Məişətdə istifadə edilən mühüm kimyəvi birləşmələr', 20),
    ('kim-7-birlesmeler', 'kim-7-birlesmeler-tebietde-serbest',
     'Təbiətdə sərbəst şəkildə tapılan mühüm kimyəvi birləşmələr', 30),
    ('kim-7-birlesmeler', 'kim-7-birlesmeler-elm-texnologiya',
     'Elm, texnologiya, həyat', 40),
    ('kim-7-birlesmeler', 'kim-7-birlesmeler-layihe',
     'Layihə', 50),
    ('kim-7-birlesmeler', 'kim-7-birlesmeler-xulase',
     'Xülasə', 60),
    ('kim-7-birlesmeler', 'kim-7-birlesmeler-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    --  Bolme 4. Qarisiqlar  (kim-7-qarisiqlar)
    ('kim-7-qarisiqlar', 'kim-7-qarisiqlar-novleri',
     'Qarışıqların növləri', 10),
    ('kim-7-qarisiqlar', 'kim-7-qarisiqlar-kimyevi-birlesmelerin',
     'Kimyəvi birləşmələrin və qarışıqların fərqli xüsusiyyətləri', 20),
    ('kim-7-qarisiqlar', 'kim-7-qarisiqlar-hellolma-hellolmaya',
     'Həllolma. Həllolmaya təsir edən amillər', 30),
    ('kim-7-qarisiqlar', 'kim-7-qarisiqlar-elm-texnologiya',
     'Elm, texnologiya, həyat', 40),
    ('kim-7-qarisiqlar', 'kim-7-qarisiqlar-layihe',
     'Layihə', 50),
    ('kim-7-qarisiqlar', 'kim-7-qarisiqlar-xulase',
     'Xülasə', 60),
    ('kim-7-qarisiqlar', 'kim-7-qarisiqlar-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    --  Bolme 5. Qarisiqlarin ayrilma usullari  (kim-7-ayrilma)
    ('kim-7-ayrilma', 'kim-7-ayrilma-kristallasdirm-usulu',
     'Kristallaşdırma üsulu', 10),
    ('kim-7-ayrilma', 'kim-7-ayrilma-sade-distille',
     'Sadə distillə və fraksiyalı distillə üsulları', 20),
    ('kim-7-ayrilma', 'kim-7-ayrilma-durultma-usulu',
     'Durultma üsulu', 30),
    ('kim-7-ayrilma', 'kim-7-ayrilma-kagiz-xromatoqrafiya',
     'Kağız xromatoqrafiyası', 40),
    ('kim-7-ayrilma', 'kim-7-ayrilma-elm-texnologiya',
     'Elm, texnologiya, həyat', 50),
    ('kim-7-ayrilma', 'kim-7-ayrilma-layihe',
     'Layihə', 60),
    ('kim-7-ayrilma', 'kim-7-ayrilma-xulase',
     'Xülasə', 70),
    ('kim-7-ayrilma', 'kim-7-ayrilma-umumi',
     'Ümumiləşdirici tapşırıqlar', 80),
    --  Bolme 6. Kimyevi reaksiyalar  (kim-7-reaksiyalar)
    ('kim-7-reaksiyalar', 'kim-7-reaksiyalar-fiziki-hadiseler',
     'Fiziki və kimyəvi hadisələr', 10),
    ('kim-7-reaksiyalar', 'kim-7-reaksiyalar-kimyevi-elametleri',
     'Kimyəvi reaksiyaların əlamətləri', 20),
    ('kim-7-reaksiyalar', 'kim-7-reaksiyalar-ekzotermik-endotermik',
     'Ekzotermik və endotermik reaksiyalar', 30),
    ('kim-7-reaksiyalar', 'kim-7-reaksiyalar-elm-texnologiya',
     'Elm, texnologiya, həyat', 40),
    ('kim-7-reaksiyalar', 'kim-7-reaksiyalar-layihe',
     'Layihə', 50),
    ('kim-7-reaksiyalar', 'kim-7-reaksiyalar-xulase',
     'Xülasə', 60),
    ('kim-7-reaksiyalar', 'kim-7-reaksiyalar-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    --  Bolme 7. Tursular ve esaslar  (kim-7-tursu-esas)
    ('kim-7-tursu-esas', 'kim-7-tursu-esas-muhit',
     'Turşular və turş mühit', 10),
    ('kim-7-tursu-esas', 'kim-7-tursu-esas-esaslar-esasi',
     'Əsaslar və əsasi mühit', 20),
    ('kim-7-tursu-esas', 'kim-7-tursu-esas-indikatorlar-skalasi',
     'İndikatorlar və pH şkalası', 30),
    ('kim-7-tursu-esas', 'kim-7-tursu-esas-neytrallasma-reaksiyalari',
     'Neytrallaşma reaksiyaları', 40),
    ('kim-7-tursu-esas', 'kim-7-tursu-esas-elm-texnologiya',
     'Elm, texnologiya, həyat', 50),
    ('kim-7-tursu-esas', 'kim-7-tursu-esas-layihe',
     'Layihə', 60),
    ('kim-7-tursu-esas', 'kim-7-tursu-esas-xulase',
     'Xülasə', 70),
    ('kim-7-tursu-esas', 'kim-7-tursu-esas-umumi',
     'Ümumiləşdirici tapşırıqlar', 80),
    --  ============  8-ci sinif  ============
    --  Bolme 1. Atomun qurulusu ve dovri cedvel  (kim-8-dovri-cedvel)
    ('kim-8-dovri-cedvel', 'kim-8-dovri-cedvel-atomun-elektron',
     'Atomun elektron örtüyü', 10),
    ('kim-8-dovri-cedvel', 'kim-8-dovri-cedvel-elektronlarin-energetik',
     'Elektronların energetik səviyyələr üzrə paylanması', 20),
    ('kim-8-dovri-cedvel', 'kim-8-dovri-cedvel-tarixi',
     'Dövri cədvəlin tarixi', 30),
    ('kim-8-dovri-cedvel', 'kim-8-dovri-cedvel-muasir',
     'Müasir dövri cədvəl', 40),
    ('kim-8-dovri-cedvel', 'kim-8-dovri-cedvel-elementlerin-xasselerinin',
     'Elementlərin xassələrinin dövriliyi', 50),
    ('kim-8-dovri-cedvel', 'kim-8-dovri-cedvel-elm-texnologiya',
     'Elm, texnologiya, həyat', 60),
    ('kim-8-dovri-cedvel', 'kim-8-dovri-cedvel-layihe',
     'Layihə', 70),
    ('kim-8-dovri-cedvel', 'kim-8-dovri-cedvel-xulase',
     'Xülasə', 80),
    ('kim-8-dovri-cedvel', 'kim-8-dovri-cedvel-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    --  Bolme 2. Kimyevi rabite  (kim-8-rabite)
    ('kim-8-rabite', 'kim-8-rabite-kimyevi-oktet',
     'Kimyəvi rabitə. Oktet qaydası', 10),
    ('kim-8-rabite', 'kim-8-rabite-ion',
     'İon rabitəsi', 20),
    ('kim-8-rabite', 'kim-8-rabite-kovalent',
     'Kovalent rabitə', 30),
    ('kim-8-rabite', 'kim-8-rabite-metal',
     'Metal rabitəsi', 40),
    ('kim-8-rabite', 'kim-8-rabite-kristal-qefesin',
     'Kristal qəfəsin tipləri', 50),
    ('kim-8-rabite', 'kim-8-rabite-elm-texnologiya',
     'Elm, texnologiya, həyat', 60),
    ('kim-8-rabite', 'kim-8-rabite-layihe',
     'Layihə', 70),
    ('kim-8-rabite', 'kim-8-rabite-xulase',
     'Xülasə', 80),
    ('kim-8-rabite', 'kim-8-rabite-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    --  Bolme 3. Kimyevi reaksiyalarin tesnifati  (kim-8-reaksiya-tesnifat)
    ('kim-8-reaksiya-tesnifat', 'kim-8-reaksiya-tesnifat-kimyevi-tenlikler',
     'Kimyəvi tənliklər', 10),
    ('kim-8-reaksiya-tesnifat', 'kim-8-reaksiya-tesnifat-madde-kutlesinin',
     'Maddə kütləsinin saxlanması qanunu', 20),
    ('kim-8-reaksiya-tesnifat', 'kim-8-reaksiya-tesnifat-tenliklerin-emsallasdirilm',
     'Kimyəvi tənliklərin əmsallaşdırılması', 30),
    ('kim-8-reaksiya-tesnifat', 'kim-8-reaksiya-tesnifat-birlesme-parcalanma',
     'Birləşmə, parçalanma, əvəzetmə və mübadilə reaksiyaları', 40),
    ('kim-8-reaksiya-tesnifat', 'kim-8-reaksiya-tesnifat-homogen-heterogen',
     'Homogen və heterogen reaksiyalar', 50),
    ('kim-8-reaksiya-tesnifat', 'kim-8-reaksiya-tesnifat-elm-texnologiya',
     'Elm, texnologiya, həyat', 60),
    ('kim-8-reaksiya-tesnifat', 'kim-8-reaksiya-tesnifat-layihe',
     'Layihə', 70),
    ('kim-8-reaksiya-tesnifat', 'kim-8-reaksiya-tesnifat-xulase',
     'Xülasə', 80),
    ('kim-8-reaksiya-tesnifat', 'kim-8-reaksiya-tesnifat-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    --  Bolme 4. Kimyevi reaksiyalarin sureti ve ona tesir eden amiller  (kim-8-reaksiya-sureti)
    ('kim-8-reaksiya-sureti', 'kim-8-reaksiya-sureti-kimyevi',
     'Kimyəvi reaksiyaların sürəti', 10),
    ('kim-8-reaksiya-sureti', 'kim-8-reaksiya-sureti-olculmesi',
     'Reaksiya sürətinin ölçülməsi', 20),
    ('kim-8-reaksiya-sureti', 'kim-8-reaksiya-sureti-qatiligin-tesiri',
     'Reaksiya sürətinin dəyişdirilməsi: qatılığın təsiri', 30),
    ('kim-8-reaksiya-sureti', 'kim-8-reaksiya-sureti-temperaturun-tesiri',
     'Reaksiya sürətinin dəyişdirilməsi: temperaturun təsiri', 40),
    ('kim-8-reaksiya-sureti', 'kim-8-reaksiya-sureti-daxil-maddenin',
     'Reaksiya sürətinin dəyişdirilməsi: reaksiyaya daxil olan maddənin səthinin sahəsinin təsiri', 50),
    ('kim-8-reaksiya-sureti', 'kim-8-reaksiya-sureti-katalizatorun-tesiri',
     'Reaksiya sürətinin dəyişdirilməsi: katalizatorun təsiri', 60),
    ('kim-8-reaksiya-sureti', 'kim-8-reaksiya-sureti-elm-texnologiya',
     'Elm, texnologiya, həyat', 70),
    ('kim-8-reaksiya-sureti', 'kim-8-reaksiya-sureti-layihe',
     'Layihə', 80),
    ('kim-8-reaksiya-sureti', 'kim-8-reaksiya-sureti-xulase',
     'Xülasə', 90),
    ('kim-8-reaksiya-sureti', 'kim-8-reaksiya-sureti-umumi',
     'Ümumiləşdirici tapşırıqlar', 100),
    --  Bolme 5. Oksidlesme ve reduksiya prosesleri  (kim-8-oksidlesme)
    ('kim-8-oksidlesme', 'kim-8-oksidlesme-yanma-reaksiyalari',
     'Yanma reaksiyaları', 10),
    ('kim-8-oksidlesme', 'kim-8-oksidlesme-oksidler',
     'Oksidlər', 20),
    ('kim-8-oksidlesme', 'kim-8-oksidlesme-reduksiya-reaksiyalari',
     'Oksidləşmə-reduksiya reaksiyaları', 30),
    ('kim-8-oksidlesme', 'kim-8-oksidlesme-elm-texnologiya',
     'Elm, texnologiya, həyat', 40),
    ('kim-8-oksidlesme', 'kim-8-oksidlesme-layihe',
     'Layihə', 50),
    ('kim-8-oksidlesme', 'kim-8-oksidlesme-xulase',
     'Xülasə', 60),
    ('kim-8-oksidlesme', 'kim-8-oksidlesme-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    --  Bolme 6. Tursular ve esaslar  (kim-8-tursu-esas)
    ('kim-8-tursu-esas', 'kim-8-tursu-esas-tursular',
     'Turşular', 10),
    ('kim-8-tursu-esas', 'kim-8-tursu-esas-esaslar',
     'Əsaslar', 20),
    ('kim-8-tursu-esas', 'kim-8-tursu-esas-umumi-alinma',
     'Turşular və əsasların ümumi alınma reaksiyaları', 30),
    ('kim-8-tursu-esas', 'kim-8-tursu-esas-duzlar',
     'Duzlar', 40),
    ('kim-8-tursu-esas', 'kim-8-tursu-esas-duzlarin-alinmasi',
     'Duzların alınması', 50),
    ('kim-8-tursu-esas', 'kim-8-tursu-esas-ion-tenlikleri',
     'İon tənlikləri', 60),
    ('kim-8-tursu-esas', 'kim-8-tursu-esas-ionlarin-teyini',
     'İonların təyini', 70),
    ('kim-8-tursu-esas', 'kim-8-tursu-esas-elm-texnologiya',
     'Elm, texnologiya, həyat', 80),
    ('kim-8-tursu-esas', 'kim-8-tursu-esas-layihe',
     'Layihə', 90),
    ('kim-8-tursu-esas', 'kim-8-tursu-esas-xulase',
     'Xülasə', 100),
    ('kim-8-tursu-esas', 'kim-8-tursu-esas-umumi',
     'Ümumiləşdirici tapşırıqlar', 110),
    --  ============  9-cu sinif  ============
    --  I. METALLAR  (kim-9-metal-umumi)
    ('kim-9-metal-umumi', 'kim-9-metal-umumi-icmali-tebietde',
     'Metalların icmalı, təbiətdə tapılması və alınmasının ümumi üsulları. Metalların ərintiləri', 10),
    ('kim-9-metal-umumi', 'kim-9-metal-umumi-fiziki-kimyevi',
     'Metalların ümumi fiziki və kimyəvi xassələri. Metalların elektrokimyəvi gərginlik sırası', 20),
    ('kim-9-metal-umumi', 'kim-9-metal-umumi-korroziyasi-korroziyadan',
     'Metalların korroziyası. Korroziyadan mühafizə', 30),
    ('kim-9-metal-umumi', 'kim-9-metal-umumi-umumi',
     'Ümumiləşdirici tapşırıqlar', 40),
    --  I. METALLAR  (kim-9-metallar)
    ('kim-9-metallar', 'kim-9-metallar-litium-natrium',
     'Litium yarımqrupu elementləri. Natrium, kalium və onların birləşmələri', 10),
    ('kim-9-metallar', 'kim-9-metallar-berillium-kalsium',
     'Berillium yarımqrupu elementləri. Kalsium', 20),
    ('kim-9-metallar', 'kim-9-metallar-kalsiumun-senayede',
     'Kalsiumun sənayedə alınan mühüm birləşmələri. Suyun codluğu və onun aradan qaldırılması üsulları', 30),
    ('kim-9-metallar', 'kim-9-metallar-bor-aluminium',
     'Bor yarımqrupu elementləri. Alüminium və onun birləşmələri', 40),
    ('kim-9-metallar', 'kim-9-metallar-umumi',
     'Ümumiləşdirici tapşırıqlar', 50),
    ('kim-9-metallar', 'kim-9-metallar-elave-yarimqrup',
     'Əlavə yarımqrup metallarının qısa icmalı. Dəmir. Dəmirin oksid və hidroksidləri', 60),
    ('kim-9-metallar', 'kim-9-metallar-cuqun-polad',
     'Çuqun və polad istehsalı', 70),
    ('kim-9-metallar', 'kim-9-metallar-mis-sink',
     'Mis, sink və xrom', 80),
    ('kim-9-metallar', 'kim-9-metallar-praktik-1',
     'Praktik iş – 1. Metalların və onların birləşmələrinin xassələri', 90),
    ('kim-9-metallar', 'kim-9-metallar-umumi-2',
     'Ümumiləşdirici tapşırıqlar', 100),
    --  II. QEYRI-METALLAR  (kim-9-halogen-kukurd)
    ('kim-9-halogen-kukurd', 'kim-9-halogen-kukurd-qeyri-metallarin',
     'Qeyri-metalların ümumi xarakteristikası', 10),
    ('kim-9-halogen-kukurd', 'kim-9-halogen-kukurd-fluor-icmali',
     'Flüor yarımqrupu elementlərinin icmalı', 20),
    ('kim-9-halogen-kukurd', 'kim-9-halogen-kukurd-xlor',
     'Xlor', 30),
    ('kim-9-halogen-kukurd', 'kim-9-halogen-kukurd-xlorid-tursusu',
     'Hidrogen-xlorid və xlorid turşusu', 40),
    ('kim-9-halogen-kukurd', 'kim-9-halogen-kukurd-muqayiseli-xarakteristika',
     'Halogenlərin müqayisəli xarakteristikası', 50),
    ('kim-9-halogen-kukurd', 'kim-9-halogen-kukurd-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    ('kim-9-halogen-kukurd', 'kim-9-halogen-kukurd-oksigen-icmali',
     'Oksigen yarımqrupu elementlərinin icmalı', 70),
    ('kim-9-halogen-kukurd', 'kim-9-halogen-kukurd-kukurd',
     'Kükürd', 80),
    ('kim-9-halogen-kukurd', 'kim-9-halogen-kukurd-hidrogen-sulfid',
     'Hidrogen-sulfid', 90),
    ('kim-9-halogen-kukurd', 'kim-9-halogen-kukurd-dioksid-sulfit',
     'Kükürd-dioksid. Sulfit turşusu. Kükürd-trioksid', 100),
    ('kim-9-halogen-kukurd', 'kim-9-halogen-kukurd-sulfat-tursusu',
     'Sulfat turşusu', 110),
    ('kim-9-halogen-kukurd', 'kim-9-halogen-kukurd-umumi-2',
     'Ümumiləşdirici tapşırıqlar', 120),
    --  II. QEYRI-METALLAR  (kim-9-azot-fosfor)
    ('kim-9-azot-fosfor', 'kim-9-azot-fosfor-yarimqrupu-elementlerinin',
     'Azot yarımqrupu elementlərinin icmalı. Azot və onun oksidləri', 10),
    ('kim-9-azot-fosfor', 'kim-9-azot-fosfor-ammonyak',
     'Ammonyak', 20),
    ('kim-9-azot-fosfor', 'kim-9-azot-fosfor-ammonium-duzlari',
     'Ammonium duzları', 30),
    ('kim-9-azot-fosfor', 'kim-9-azot-fosfor-nitrat-tursusu',
     'Nitrat turşusu', 40),
    ('kim-9-azot-fosfor', 'kim-9-azot-fosfor-tursusunun-tebietde',
     'Nitrat turşusunun duzları. Təbiətdə azot dövranı', 50),
    ('kim-9-azot-fosfor', 'kim-9-azot-fosfor-fosfor',
     'Fosfor', 60),
    ('kim-9-azot-fosfor', 'kim-9-azot-fosfor-difosfor-pentaoksid',
     'Difosfor-pentaoksid və ortofosfat turşusu', 70),
    ('kim-9-azot-fosfor', 'kim-9-azot-fosfor-praktik-2',
     'Praktik iş – 2. Qeyri-metalların və onların birləşmələrinin xassələri', 80),
    ('kim-9-azot-fosfor', 'kim-9-azot-fosfor-mineral-tesnifati',
     'Mineral gübrələr və onların təsnifatı. Azotlu gübrələr', 90),
    ('kim-9-azot-fosfor', 'kim-9-azot-fosfor-kaliumlu-gubreler',
     'Fosforlu və kaliumlu gübrələr', 100),
    ('kim-9-azot-fosfor', 'kim-9-azot-fosfor-umumi',
     'Ümumiləşdirici tapşırıqlar', 110),
    --  II. QEYRI-METALLAR  (kim-9-karbon-silisium)
    ('kim-9-karbon-silisium', 'kim-9-karbon-silisium-yarimqrupu-elementlerinin',
     'Karbon yarımqrupu elementlərinin icmalı. Karbon', 10),
    ('kim-9-karbon-silisium', 'kim-9-karbon-silisium-oksidleri',
     'Karbon oksidləri', 20),
    ('kim-9-karbon-silisium', 'kim-9-karbon-silisium-duzlari-tebietde',
     'Karbonat turşusu və onun duzları. Təbiətdə karbon dövranı', 30),
    ('kim-9-karbon-silisium', 'kim-9-karbon-silisium-silisium',
     'Silisium', 40),
    ('kim-9-karbon-silisium', 'kim-9-karbon-silisium-dioksid-metasilikat',
     'Silisium-dioksid və metasilikat turşusu', 50),
    ('kim-9-karbon-silisium', 'kim-9-karbon-silisium-tebii-birlesmeleri',
     'Silisiumun təbii birləşmələri və onların texnikada tətbiqi', 60),
    ('kim-9-karbon-silisium', 'kim-9-karbon-silisium-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    --  III. UZVI KIMYAYA GIRIS SADE UZVI BIRLESMELERLE TANISLIQ  (kim-9-uzvi)
    ('kim-9-uzvi', 'kim-9-uzvi-kimya-neyi',
     'Üzvi kimya nəyi öyrənir', 10),
    ('kim-9-uzvi', 'kim-9-uzvi-kimyevi-qurulus',
     'Üzvi birləşmələrin kimyəvi quruluş nəzəriyyəsi. Üzvi birləşmələrin təsnifatı', 20),
    ('kim-9-uzvi', 'kim-9-uzvi-alkanlar-metan',
     'Doymuş karbohidrogenlər (alkanlar). Metan', 30),
    ('kim-9-uzvi', 'kim-9-uzvi-doymamis-etilen',
     'Doymamış karbohidrogenlər. Etilen sırası karbohidrogenləri (alkenlər). Etilen', 40),
    ('kim-9-uzvi', 'kim-9-uzvi-asetilen-dien',
     'Asetilen və dien karbohidrogenləri. Asetilen', 50),
    ('kim-9-uzvi', 'kim-9-uzvi-tsiklik-tsikloparafinl',
     'Tsiklik karbohidrogenlər – tsikloparafinlər və aromatik karbohidrogenlər', 60),
    ('kim-9-uzvi', 'kim-9-uzvi-tebii-menbeleri',
     'Karbohidrogenlərin təbii mənbələri və onların emalı', 70),
    ('kim-9-uzvi', 'kim-9-uzvi-umumi',
     'Ümumiləşdirici tapşırıqlar', 80),
    ('kim-9-uzvi', 'kim-9-uzvi-spirtler-etanol',
     'Doymuş spirtlər. Etanol, etilenqlikol və qliserin', 90),
    ('kim-9-uzvi', 'kim-9-uzvi-aldehidler-aldehidi',
     'Doymuş aldehidlər. Sirkə aldehidi', 100),
    ('kim-9-uzvi', 'kim-9-uzvi-karbon-tursulari',
     'Karbon turşuları. Sirkə turşusu və ali karbon turşuları', 110),
    ('kim-9-uzvi', 'kim-9-uzvi-murekkeb-efirler',
     'Mürəkkəb efirlər. Yağlar. Sabun və digər yuyucu vasitələr', 120),
    ('kim-9-uzvi', 'kim-9-uzvi-karbohidratlar',
     'Karbohidratlar', 130),
    ('kim-9-uzvi', 'kim-9-uzvi-zulallar',
     'Zülallar', 140),
    ('kim-9-uzvi', 'kim-9-uzvi-irimolekullu-birlesmeler',
     'İrimolekullu birləşmələr – polimerlər', 150),
    ('kim-9-uzvi', 'kim-9-uzvi-praktik-3',
     'Praktik iş 3. Üzvi birləşmələrin xassələri', 160),
    ('kim-9-uzvi', 'kim-9-uzvi-umumi-2',
     'Ümumiləşdirici tapşırıqlar', 170),
    --  ============  10-cu sinif  ============
    --  I BOLME. Alkanlar  (kim-10-alkan)
    ('kim-10-alkan', 'kim-10-alkan-homoloji-sirasi',
     'Alkanların quruluşu və homoloji sırası', 10),
    ('kim-10-alkan', 'kim-10-alkan-molekullarinin-feza',
     'Alkanların molekullarının fəza quruluşu', 20),
    ('kim-10-alkan', 'kim-10-alkan-izomerliyi-alkil',
     'Alkanların izomerliyi və alkil radikallar', 30),
    ('kim-10-alkan', 'kim-10-alkan-adlandirilmasi',
     'Alkanların adlandırılması', 40),
    ('kim-10-alkan', 'kim-10-alkan-tebietde-tapilmasi',
     'Alkanların təbiətdə tapılması və alınması', 50),
    ('kim-10-alkan', 'kim-10-alkan-fiziki-xasseleri',
     'Alkanların fiziki və kimyəvi xassələri', 60),
    ('kim-10-alkan', 'kim-10-alkan-kimyevi-xasseleri',
     'Alkanların kimyəvi xassələri', 70),
    ('kim-10-alkan', 'kim-10-alkan-praktik-karbohidrogenl',
     'Praktik iş. Karbohidrogenlərin keyfiyyət tərkibinin təyini', 80),
    --  II BOLME. Alkenler  (kim-10-alken)
    ('kim-10-alken', 'kim-10-alken-homoloji-sirasi',
     'Alkenlərin homoloji sırası, molekullarının elektron və qrafik formulu', 10),
    ('kim-10-alken', 'kim-10-alken-feza-qurulusu',
     'Alkenlərin molekullarının fəza quruluşu', 20),
    ('kim-10-alken', 'kim-10-alken-adlandirilmasi',
     'Alkenlərin adlandırılması', 30),
    ('kim-10-alken', 'kim-10-alken-izomerliyi',
     'Alkenlərin izomerliyi', 40),
    ('kim-10-alken', 'kim-10-alken-alinmasi-fiziki',
     'Alkenlərin alınması və fiziki xassələri', 50),
    ('kim-10-alken', 'kim-10-alken-kimyevi-xasseleri',
     'Alkenlərin kimyəvi xassələri', 60),
    --  III BOLME. Alkadienler  (kim-10-dien-tsiklo)
    ('kim-10-dien-tsiklo', 'kim-10-dien-tsiklo-homoloji-sirasi',
     'Alkadienlərin homoloji sırası, qrafik formulları və molekullarının fəza quruluşu', 10),
    ('kim-10-dien-tsiklo', 'kim-10-dien-tsiklo-adlandirilmasi-izomerliyi',
     'Alkadienlərin adlandırılması və izomerliyi', 20),
    ('kim-10-dien-tsiklo', 'kim-10-dien-tsiklo-alinmasi-fiziki',
     'Alkadienlərin alınması və fiziki xassələri', 30),
    ('kim-10-dien-tsiklo', 'kim-10-dien-tsiklo-kimyevi-xasseleri',
     'Alkadienlərin kimyəvi xassələri', 40),
    --  IV BOLME. Alkinler  (kim-10-alkin)
    ('kim-10-alkin', 'kim-10-alkin-homoloji-sirasi',
     'Alkinlərin homoloji sırası, qrafik formulları və molekullarının fəza quruluşu', 10),
    ('kim-10-alkin', 'kim-10-alkin-adlandirilmasi-izomerliyi',
     'Alkinlərin adlandırılması və izomerliyi', 20),
    ('kim-10-alkin', 'kim-10-alkin-alinmasi-fiziki',
     'Alkinlərin alınması, fiziki xassələri və yanma reaksiyaları', 30),
    ('kim-10-alkin', 'kim-10-alkin-kimyevi-xasseleri',
     'Alkinlərin kimyəvi xassələri', 40),
    --  V BOLME. Tsikloalkanlar  (kim-10-dien-tsiklo)
    ('kim-10-dien-tsiklo', 'kim-10-dien-tsiklo-homoloji-sirasi-qrafik',
     'Tsikloalkanların homoloji sırası, qrafik formulları və molekullarının fəza quruluşu', 50),
    ('kim-10-dien-tsiklo', 'kim-10-dien-tsiklo-tsikloalkanlar-izomerliyi',
     'Tsikloalkanların adlandırılması və izomerliyi', 60),
    ('kim-10-dien-tsiklo', 'kim-10-dien-tsiklo-alinmasi-xasseleri',
     'Tsikloalkanların alınması və fiziki xassələri', 70),
    ('kim-10-dien-tsiklo', 'kim-10-dien-tsiklo-kimyevi',
     'Tsikloalkanların kimyəvi xassələri', 80),
    --  VI BOLME. Aromatik karbohidrogenler  (kim-10-aromatik)
    ('kim-10-aromatik', 'kim-10-aromatik-molekulunun-feza',
     'Aromatik karbohidrogenlər. Benzol molekulunun fəza quruluşu', 10),
    ('kim-10-aromatik', 'kim-10-aromatik-benzolun-homoloqlarinin',
     'Benzolun homoloqlarının adlandırılması və İzomerliyi', 20),
    ('kim-10-aromatik', 'kim-10-aromatik-alinmasi-fiziki',
     'Benzol sırası karbohidrogenlərin alınması və fiziki xassələri', 30),
    ('kim-10-aromatik', 'kim-10-aromatik-kimyevi-xasseleri',
     'Benzol sırası karbohidrogenlərin kimyəvi xassələri', 40),
    ('kim-10-aromatik', 'kim-10-aromatik-stirol',
     'Stirol', 50),
    --  VII BOLME. Karbohidrogenlerin tebii menbeleri  (kim-10-neft)
    ('kim-10-neft', 'kim-10-neft-karbohidrogenl-tebii',
     'Karbohidrogenlərin təbii mənbələri haqqında ümumi məlumat', 10),
    ('kim-10-neft', 'kim-10-neft-ilkin-emali',
     'Neft və onun ilkin emalı', 20),
    ('kim-10-neft', 'kim-10-neft-mehsullarinin-tekrar',
     'Neft məhsullarının təkrar emalı', 30),
    ('kim-10-neft', 'kim-10-neft-benzinin-keyfiyyeti',
     'Benzinin keyfiyyəti və oktan ədədi', 40),
    ('kim-10-neft', 'kim-10-neft-das-komurun',
     'Daş kömürün emalı', 50),
    --  ============  11-ci sinif  ============
    --  I. Hisse. OKSIGENLI UZVI BIRLESMELER  (kim-11-spirtler)
    ('kim-11-spirtler', 'kim-11-spirtler-ilkin',
     'İlkin yoxlama', 10),
    ('kim-11-spirtler', 'kim-11-spirtler-doymus-biratomlu',
     'Doymuş biratomlu spirtlər', 20),
    ('kim-11-spirtler', 'kim-11-spirtler-adlandirilmasi-izomerliyi',
     'Adlandırılması və izomerliyi', 30),
    ('kim-11-spirtler', 'kim-11-spirtler-alinmasi',
     'Alınması', 40),
    ('kim-11-spirtler', 'kim-11-spirtler-qurulusu-xasseleri',
     'Quruluşu və fiziki xassələri', 50),
    ('kim-11-spirtler', 'kim-11-spirtler-kimyevi-tetbiqi',
     'Kimyəvi xassələri və tətbiqi', 60),
    ('kim-11-spirtler', 'kim-11-spirtler-praktik-ders',
     'Praktik dərs. Etanolun məhkəməsi', 70),
    ('kim-11-spirtler', 'kim-11-spirtler-doymus-coxatomlu',
     'Doymuş çoxatomlu spirtlər', 80),
    ('kim-11-spirtler', 'kim-11-spirtler-etilenqlikol',
     'Etilenqlikol', 90),
    ('kim-11-spirtler', 'kim-11-spirtler-qliserin',
     'Qliserin', 100),
    ('kim-11-spirtler', 'kim-11-spirtler-fenollar-fenol',
     'Fenollar. Fenol', 110),
    ('kim-11-spirtler', 'kim-11-spirtler-alinmasi-xasseleri',
     'Alınması, quruluşu və fiziki xassələri', 120),
    ('kim-11-spirtler', 'kim-11-spirtler-kimyevi-xasseleri-tetbiqi',
     'Kimyəvi xassələri və tətbiqi', 130),
    ('kim-11-spirtler', 'kim-11-spirtler-fesle-dair',
     'I fəslə dair ümumi nəticələr', 140),
    ('kim-11-spirtler', 'kim-11-spirtler-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 150),
    --  I. Hisse. OKSIGENLI UZVI BIRLESMELER  (kim-11-aldehid-tursu)
    ('kim-11-aldehid-tursu', 'kim-11-aldehid-tursu-ilkin',
     'İlkin yoxlama', 10),
    ('kim-11-aldehid-tursu', 'kim-11-aldehid-tursu-aldehidler',
     'Aldehidlər', 20),
    ('kim-11-aldehid-tursu', 'kim-11-aldehid-tursu-adlandirilmasi-izomerliyi',
     'Adlandırılması və izomerliyi', 30),
    ('kim-11-aldehid-tursu', 'kim-11-aldehid-tursu-alinmasi-xasseleri',
     'Alınması, quruluşu və fiziki xassələri', 40),
    ('kim-11-aldehid-tursu', 'kim-11-aldehid-tursu-kimyevi-tetbiqi',
     'Kimyəvi xassələri və tətbiqi', 50),
    ('kim-11-aldehid-tursu', 'kim-11-aldehid-tursu-praktik-1',
     'Praktik İş -1. Spirtlər, fenol və aldehidlərin kimyəvi xassələri', 60),
    ('kim-11-aldehid-tursu', 'kim-11-aldehid-tursu-fesle-dair',
     'II fəslə dair ümumi nəticələr', 70),
    ('kim-11-aldehid-tursu', 'kim-11-aldehid-tursu-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 80),
    ('kim-11-aldehid-tursu', 'kim-11-aldehid-tursu-ilkin-2',
     'İlkin yoxlama', 90),
    ('kim-11-aldehid-tursu', 'kim-11-aldehid-tursu-biresasli-karbon',
     'Birəsaslı karbon turşuları', 100),
    ('kim-11-aldehid-tursu', 'kim-11-aldehid-tursu-adlandirilmasi-izomerliyi-2',
     'Adlandırılması və izomerliyi', 110),
    ('kim-11-aldehid-tursu', 'kim-11-aldehid-tursu-alinmasi',
     'Alınması', 120),
    ('kim-11-aldehid-tursu', 'kim-11-aldehid-tursu-qurulusu-xasseleri',
     'Quruluşu və fiziki xassələri', 130),
    ('kim-11-aldehid-tursu', 'kim-11-aldehid-tursu-kimyevi-xasseleri-tetbiqi',
     'Kimyəvi xassələri və tətbiqi', 140),
    ('kim-11-aldehid-tursu', 'kim-11-aldehid-tursu-doymus-doymamis',
     'Doymuş və doymamış ali karbon turşuları', 150),
    ('kim-11-aldehid-tursu', 'kim-11-aldehid-tursu-ikiesasli-karbon',
     'İkiəsaslı karbon turşuları', 160),
    --  I. Hisse. OKSIGENLI UZVI BIRLESMELER  (kim-11-efir-yag)
    ('kim-11-efir-yag', 'kim-11-efir-yag-murekkeb',
     'Mürəkkəb efirlər', 10),
    ('kim-11-efir-yag', 'kim-11-efir-yag-adlandirilmasi-izomerliyi',
     'Adlandırılması və izomerliyi', 20),
    ('kim-11-efir-yag', 'kim-11-efir-yag-alinmasi-xasseleri',
     'Alınması və xassələri', 30),
    ('kim-11-efir-yag', 'kim-11-efir-yag-yaglar',
     'Yağlar', 40),
    ('kim-11-efir-yag', 'kim-11-efir-yag-sabun-sintetik',
     'Sabun və sintetik yuyucu maddələr', 50),
    ('kim-11-efir-yag', 'kim-11-efir-yag-iii-fesle',
     'III fəslə dair ümumi nəticələr', 60),
    ('kim-11-efir-yag', 'kim-11-efir-yag-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 70),
    --  I. Hisse. OKSIGENLI UZVI BIRLESMELER  (kim-11-karbohidrat)
    ('kim-11-karbohidrat', 'kim-11-karbohidrat-ilkin',
     'İlkin yoxlama', 10),
    ('kim-11-karbohidrat', 'kim-11-karbohidrat-monosaxaridler',
     'Monosaxaridlər', 20),
    ('kim-11-karbohidrat', 'kim-11-karbohidrat-qurulusu-fiziki',
     'Qlükoza: quruluşu və fiziki xassələri', 30),
    ('kim-11-karbohidrat', 'kim-11-karbohidrat-qlukoza-tetbiqi',
     'Qlükoza: kimyəvi xassələri və tətbiqi', 40),
    ('kim-11-karbohidrat', 'kim-11-karbohidrat-fruktoza-riboza',
     'Fruktoza, riboza və dezoksiriboza', 50),
    ('kim-11-karbohidrat', 'kim-11-karbohidrat-disaxaridler-saxaroza',
     'Disaxaridlər.Saxaroza', 60),
    ('kim-11-karbohidrat', 'kim-11-karbohidrat-polisaxaridler',
     'Polisaxaridlər', 70),
    ('kim-11-karbohidrat', 'kim-11-karbohidrat-nisasta',
     'Nişasta', 80),
    ('kim-11-karbohidrat', 'kim-11-karbohidrat-selluloza',
     'Sellüloza', 90),
    ('kim-11-karbohidrat', 'kim-11-karbohidrat-praktik-2',
     'Praktik iş - 2. Karbon turşuları, mürəkkəb efirlər, yuyucu maddələr və karbohidratların kimyəvi xassələri', 100),
    ('kim-11-karbohidrat', 'kim-11-karbohidrat-fesle-dair',
     'IV fəslə dair ümumi nəticələr', 110),
    ('kim-11-karbohidrat', 'kim-11-karbohidrat-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 120),
    --  II HISSE. AZOTLU UZVI BIRLESMELER  (kim-11-azotlu)
    ('kim-11-azotlu', 'kim-11-azotlu-ilkin',
     'İlkin yoxlama', 10),
    ('kim-11-azotlu', 'kim-11-azotlu-nitrobirlesmel',
     'Nitrobirləşmələr', 20),
    ('kim-11-azotlu', 'kim-11-azotlu-aminler',
     'Aminlər', 30),
    ('kim-11-azotlu', 'kim-11-azotlu-adlandirilmasi-izomerliyi',
     'Adlandırılması və izomerliyi', 40),
    ('kim-11-azotlu', 'kim-11-azotlu-fiziki-xasseleri',
     'Alınması, quruluşu və fiziki xassələri', 50),
    ('kim-11-azotlu', 'kim-11-azotlu-kimyevi-tetbiqi',
     'Kimyəvi xassələri və tətbiqi', 60),
    ('kim-11-azotlu', 'kim-11-azotlu-anilin',
     'Anilin', 70),
    ('kim-11-azotlu', 'kim-11-azotlu-amintursular',
     'Aminturşular', 80),
    ('kim-11-azotlu', 'kim-11-azotlu-adlandirilmasi-qurulusu',
     'Adlandırılması, izomerliyi, alınması və quruluşu', 90),
    ('kim-11-azotlu', 'kim-11-azotlu-xasseleri-tetbiqi',
     'Xassələri və tətbiqi', 100),
    ('kim-11-azotlu', 'kim-11-azotlu-zulallar',
     'Zülallar', 110),
    ('kim-11-azotlu', 'kim-11-azotlu-qurulusu',
     'Quruluşu', 120),
    ('kim-11-azotlu', 'kim-11-azotlu-xasseleri-tetbiqi-2',
     'Xassələri və tətbiqi', 130),
    ('kim-11-azotlu', 'kim-11-azotlu-fesle-dair',
     'V fəslə dair ümumi nəticələr', 140),
    ('kim-11-azotlu', 'kim-11-azotlu-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 150),
    --  III HISSE. IRIMOLEKULLU BIRLESMELER  (kim-11-polimer)
    ('kim-11-polimer', 'kim-11-polimer-ilkin',
     'İlkin yoxlama', 10),
    ('kim-11-polimer', 'kim-11-polimer-qurulusu-plastik',
     'Polimerlərin quruluşu və fiziki xassələri. Plastik kütlələr', 20),
    ('kim-11-polimer', 'kim-11-polimer-tebii-sintetik',
     'Təbii və sintetik kauçuklar', 30),
    ('kim-11-polimer', 'kim-11-polimer-lifler',
     'Liflər', 40),
    ('kim-11-polimer', 'kim-11-polimer-etraf-muhitin',
     'Ətraf mühitin polimer maddələrlə çirklənmədən mühafizəsi', 50),
    ('kim-11-polimer', 'kim-11-polimer-debat-ders',
     'Debat dərs. Polimerlərin faydası və zərəri', 60),
    ('kim-11-polimer', 'kim-11-polimer-praktik-3',
     'Praktik iş - 3. Zülallar və polimerlərin fiziki və kimyəvi xassələri', 70),
    ('kim-11-polimer', 'kim-11-polimer-fesle-dair',
     'VI fəslə dair ümumi nəticələr', 80),
    ('kim-11-polimer', 'kim-11-polimer-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 90)
  ) as v(parent_slug, slug, name, sort)
  join public.topics p on p.slug = v.parent_slug
   and p.subject_id = (select id from public.subjects where slug = 'kimya')
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort,
      parent_id = excluded.parent_id, level_id = excluded.level_id;

do $$
declare k int;
begin
  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'kimya'
    join public.levels   l on l.id = p.level_id and l.code = '7';
  if k <> 54 then
    raise exception 'kimya 7-ci alt movzulari: 54 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'kimya'
    join public.levels   l on l.id = p.level_id and l.code = '8';
  if k <> 55 then
    raise exception 'kimya 8-ci alt movzulari: 55 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'kimya'
    join public.levels   l on l.id = p.level_id and l.code = '9';
  if k <> 61 then
    raise exception 'kimya 9-cu alt movzulari: 61 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'kimya'
    join public.levels   l on l.id = p.level_id and l.code = '10';
  if k <> 36 then
    raise exception 'kimya 10-cu alt movzulari: 36 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'kimya'
    join public.levels   l on l.id = p.level_id and l.code = '11';
  if k <> 74 then
    raise exception 'kimya 11-ci alt movzulari: 74 gozlenilirdi, % tapildi', k;
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
    join public.subjects s on s.id = t.subject_id and s.slug = 'kimya'
    join public.levels   l on l.id = t.level_id
   where t.parent_id is null and true;
  if k <> 31 then
    raise exception 'Kimya ust movzu sayi 31 deyil: %', k;
  end if;

  raise notice 'Kimya 7-11: 280 alt movzu hazir.';
end $$;
