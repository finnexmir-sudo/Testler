-- =====================================================================
--  92_alt_movzular_tarix5_8_9_11.sql : TARIX 5,6,8,9,11 - ALT MOVZULAR
--
--  NIYE
--  On birinci fenn.  Riyaziyyat, heyat bilgisi, informatika, fizika,
--  kimya, biologiya, ingilis dili, cografiya, edebiyyat hazirdir.
--  Bu, Azerbaycan tarixi dersliyidir (Umumi tarix ayri fenndir, ayri
--  merhelede - bax roadmap qeydi).  7 ve 10-cu sinifde "Tarix" yoxdur
--  (portalda o siniflər ucun yalniz "Umumi tarix" derslikdir).
--
--  MENBE: e-derslik.edu.az "Movzular" agaci - kitab id 844 (5),
--  910 (6), 801 (8), 877 (9), 807 (11).  Adlar EYNILE goturulub.
--
--  5-CI SINIF: 5 bolme, bire-bir movzuya - problemsiz.
--
--  6-CI SINIF: dersliyin oz mundericati COX SEYREKDIR (cemi 9 ders!),
--  bazada 6 movzu var.  "II Bolme. Azerbaycanda qedim dovletler"nin
--  4 dersi (Manna/Atropatena/Albaniya/umumi baxis) HƏR BİRİ artiq
--  bazada OZ AYRI ust movzusudur - alt movzu ucun daha derinlik
--  yoxdur, bu bolme BURAXILIR (None).  Qalan iki bolme (I - ibtidai
--  cemiyyet, III - erken orta esrler) bire-bir öz movzusuna gedir.
--
--  8-Cİ SINIF: 4 bolme, bazada 6 movzu - son bolme ("4. AZƏRBAYCAN
--  XIX ƏSRİN ƏVVƏLLƏRİNDƏ") İKİ movzuya bolunur: Gulustan (31) ve
--  Turkmencay (34) muqavileleri ozleri ile bağlı dersler ARADAN-ARADAN
--  sepelenib (34-cu ders 30-31-32-33-un arasindadir), COX SERHEDLI
--  (list) spec ile hər dersin oz sehifesi qeyd olunub - tesadufi
--  bolgu yoxdur, hər sinir muellifin/mueqavilenin oz sehifesidir.
--
--  9-CU SINIF: 4 bolme, icinde "I/II fesil" (ve b.) NOMRELENMIS
--  basliqlarla daha da bolunur - basliqlar HERFI basliq kimi xaric
--  edilmir (biologiya-11-in tələsi ile eyni sebeb: basqa sinifde
--  eyni metn HƏQIQI bolme ola bilerdi), sadece sehife serhedine gore
--  duz movzuya dusurler.  "I bolme" I fesil (xix) / II fesil
--  (xx-evvel) - sehife 50-den bolunur.  "II bolme" TAM cumhuriyyete
--  (III fesil tekdir).  "III bolme" TAM sovete (IV+V fesil EYNI
--  movzuya - hər ikisi sovet dovrudur).  "IV bolme" VI fesil
--  (musteqillik) / VII fesil (yeni-dovr) - sehife 172-den bolunur.
--
--  11-Cİ SINIF: 4 bolme, icinde "I/II/...XII fesil" basliqlarla
--  daha da bolunur (9-cu sinifle eyni qelib).  "I bolme" I fesil
--  (isgal) / II-V fesil (mustemleke - hamisi mustemleke dovrunun
--  fərqli teref-i: idare, sosial-iqtisadi, Cenubi Azerbaycan,
--  medeniyyet) - sehife 21-den bolunur.  "II bolme" TAM cumhuriyyete
--  (VI+VII fesil).  "III bolme" TAM sovete (VIII+IX fesil).
--  "IV bolme" X+XI fesil (musteqillik) / XII fesil (zefer - basliq
--  "Boyuk Zefer" movzu adi ile HƏRFI eynidir) - sehife 203-den.
--
--  YAZI QUSURLARI: 6-ci sinifde "1." evezine dotless "ı." (herf,
--  reqem deyil), 8-ci sinifde iki kesik/yanlis soz (Abbasm ->
--  Abbasın, yansı -> yarısı), 9-cu sinifde kesik soz (Azərbayca ->
--  Azərbaycanda) ve "Azarbaycan" (ə evezine a), 11-ci sinifde bir
--  bendde bosluqsuz nöqte (fəsil.Şimali -> fəsil. Şimali).
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
--   * yazi (6): yazi qusuru (bosluq, herf)
--       6-ci   s.8    i. Esas tarixi anlayislar ve zaman olcu vahidleri
--                    -> Esas tarixi anlayislar ve zaman olcu vahidleri
--       8-ci   s.20   3. Celaliler herekati. Sah I Abbasm herbi ugurlari
--                    -> Celaliler herekati. Sah I Abbasin herbi ugurlari
--       8-ci   s.26   4. XVI esrin ikinci yansi - XVII esrde sosial-iqtisadi ve ictimai heyat
--                    -> XVI esrin ikinci yarisi - XVII esrde sosial-iqtisadi ve ictimai heyat
--       9-cu   s.130  V fesil. Azarbaycan Ikinci dunya muharibesinden sonraki dovrde
--                    -> V fesil. Azerbaycan Ikinci dunya muharibesinden sonraki dovrde
--       9-cu   s.142  27. Iran Islam inqilabi ve Cenubi Azerbayca
--                    -> Iran Islam inqilabi ve Cenubi Azerbaycanda
--       11-ci  s.21   II fesil.Simali Azerbaycan Rusiya isgali dovrunde
--                    -> II fesil. Simali Azerbaycan Rusiya isgali dovrunde

insert into public.topics (subject_id, level_id, parent_id, slug, name, sort)
select p.subject_id, p.level_id, p.id, v.slug, v.name, v.sort
  from (values
    --  ============  5-ci sinif  ============
    --  I Bolme. Qedim Azerbaycan  (tarix-5-qedim)
    ('tarix-5-qedim', 'tarix-5-qedim-nece-oyrenilir',
     'Tarix necə öyrənilir?', 10),
    ('tarix-5-qedim', 'tarix-5-qedim-vetenim-azerbaycan',
     'Vətənim Azərbaycan', 20),
    ('tarix-5-qedim', 'tarix-5-qedim-azerbaycanda-ilk',
     'Azərbaycanda ilk insan məskənləri', 30),
    ('tarix-5-qedim', 'tarix-5-qedim-emek-aletleri',
     'Əmək alətləri necə yarandı?', 40),
    ('tarix-5-qedim', 'tarix-5-qedim-dovletler-lazimdir',
     'Dövlətlər nə üçün lazımdır?', 50),
    ('tarix-5-qedim', 'tarix-5-qedim-azerbaycanin-dovletleri',
     'Azərbaycanın qədim dövlətləri', 60),
    --  II Bolme. Azerbaycan dovletleri  (tarix-5-dovletler)
    ('tarix-5-dovletler', 'tarix-5-dovletler-esaretle-barismayan',
     'Əsarətlə barışmayan qəhrəman', 10),
    ('tarix-5-dovletler', 'tarix-5-dovletler-azerbaycani-birlesdiren',
     'Azərbaycanı birləşdirən ilk hökmdar', 20),
    ('tarix-5-dovletler', 'tarix-5-dovletler-selcuqlar-azerbaycan',
     'Səlcuqlar və Azərbaycan', 30),
    ('tarix-5-dovletler', 'tarix-5-dovletler-atabey-semseddin',
     'Atabəy Şəmsəddin Eldəniz', 40),
    ('tarix-5-dovletler', 'tarix-5-dovletler-qara-yusif',
     'Qara Yusif kim idi?', 50),
    ('tarix-5-dovletler', 'tarix-5-dovletler-hesen-padsah',
     'Həsən padşah Bayandur', 60),
    ('tarix-5-dovletler', 'tarix-5-dovletler-seyx-sah',
     'Şeyx necə şah oldu?', 70),
    ('tarix-5-dovletler', 'tarix-5-dovletler-qadinlar',
     'Tariximizdə qadınlar', 80),
    ('tarix-5-dovletler', 'tarix-5-dovletler-serqin-son',
     'Şərqin son fatehi', 90),
    ('tarix-5-dovletler', 'tarix-5-dovletler-birlik-yoxdursa',
     'Birlik yoxdursa, dirilik də yoxdur', 100),
    ('tarix-5-dovletler', 'tarix-5-dovletler-azerbaycan-parcalandi',
     'Azərbaycan necə parçalandı?', 110),
    --  III Bolme. Qalalar ve seherler  (tarix-5-qalalar)
    ('tarix-5-qalalar', 'tarix-5-qalalar-das-kesikciler',
     'Daş keşikçilər', 10),
    ('tarix-5-qalalar', 'tarix-5-qalalar-seherler-nece',
     'Şəhərlər necə yarandı?', 20),
    ('tarix-5-qalalar', 'tarix-5-qalalar-qedim-azerbaycan',
     'Qədim Azərbaycan şəhərləri', 30),
    ('tarix-5-qalalar', 'tarix-5-qalalar-azerbaycanin-taxti',
     'Azərbaycanın taxtı - Təbriz', 40),
    --  IV Bolme. Azerbaycan respublikalari  (tarix-5-respublika)
    ('tarix-5-respublika', 'tarix-5-respublika-muselman-serqinin',
     'Müsəlman Şərqinin ilk Cümhuriyyəti', 10),
    ('tarix-5-respublika', 'tarix-5-respublika-sovet-isgali',
     'Sovet işğalı', 20),
    ('tarix-5-respublika', 'tarix-5-respublika-azerbaycan-xalqi',
     'Azərbaycan xalqı faşizmə qarşı', 30),
    ('tarix-5-respublika', 'tarix-5-respublika-dovlet-musteqilliyini',
     'Dövlət müstəqilliyinin bərpası', 40),
    ('tarix-5-respublika', 'tarix-5-respublika-birinci-qarabag',
     'Birinci Qarabağ müharibəsi', 50),
    ('tarix-5-respublika', 'tarix-5-respublika-dovletin-xilaskari',
     'Dövlətin xilaskarı', 60),
    ('tarix-5-respublika', 'tarix-5-respublika-muzeffer-ali',
     'Müzəffər Ali Baş Komandan', 70),
    ('tarix-5-respublika', 'tarix-5-respublika-boyuk-zeferin',
     'Böyük Zəfərin ilk qaranquşu - Aprel döyüşləri', 80),
    ('tarix-5-respublika', 'tarix-5-respublika-qani-yazan',
     'Qanı ilə tarix yazan qəhrəmanlar', 90),
    ('tarix-5-respublika', 'tarix-5-respublika-veten-muharibesi',
     'Vətən müharibəsi', 100),
    ('tarix-5-respublika', 'tarix-5-respublika-qarabagda-quruculuq',
     'Qarabağda quruculuq', 110),
    --  V Bolme. Medeniyyet incileri  (tarix-5-medeniyyet)
    ('tarix-5-medeniyyet', 'tarix-5-medeniyyet-kitabi-dede',
     '“Kitabi-Dədə Qorqud”.', 10),
    ('tarix-5-medeniyyet', 'tarix-5-medeniyyet-nizami-gencevi',
     'Nizami Gəncəvi', 20),
    ('tarix-5-medeniyyet', 'tarix-5-medeniyyet-elmle-siyaset',
     'Elmlə siyasət yürüdən alimlər', 30),
    ('tarix-5-medeniyyet', 'tarix-5-medeniyyet-azerbaycan-atasi',
     'Azərbaycan tarixinin atası', 40),
    ('tarix-5-medeniyyet', 'tarix-5-medeniyyet-ekinci-den',
     '“Əkinçi”dən başlanan yol', 50),
    ('tarix-5-medeniyyet', 'tarix-5-medeniyyet-milli-operanin',
     'Milli operanın banisi', 60),
    ('tarix-5-medeniyyet', 'tarix-5-medeniyyet-lutfi-zade',
     'Lütfi Zadə', 70),
    --  ============  6-ci sinif  ============
    --  I Bolme. Azerbaycanda ibtidai cemiyyet  (tarix-6-ibtidai)
    ('tarix-6-ibtidai', 'tarix-6-ibtidai-esas-anlayislar',
     'Əsas tarixi anlayışlar və zaman ölçü vahidləri', 10),
    ('tarix-6-ibtidai', 'tarix-6-ibtidai-cemiyyet',
     'ibtidai cəmiyyət', 20),
    ('tarix-6-ibtidai', 'tarix-6-ibtidai-erken-dovletler',
     'Erkən dövlətlər', 30),
    --  III Bolme. Azerbaycan III-VI yuzilliklerde  (tarix-6-erken-orta)
    ('tarix-6-erken-orta', 'tarix-6-erken-orta-azerbaycanda-feodal',
     'Azərbaycanda feodal münasibətlərinin yaranması', 10),
    ('tarix-6-erken-orta', 'tarix-6-erken-orta-azerbaycan-sasani',
     'Azərbaycan Sasani imperiyası dövründə', 20),
    --  ============  8-ci sinif  ============
    --  1. AZERBAYCAN XVI ESRIN IKINCI YARISI - XVII ESRDE  (tarix-8-xvi-xvii)
    ('tarix-8-xvi-xvii', 'tarix-8-xvi-xvii-erazilerinin-osmanlilar',
     'Azərbaycan ərazilərinin Osmanlılar tərəfindən işğalı', 10),
    ('tarix-8-xvi-xvii', 'tarix-8-xvi-xvii-sah-islahatlari',
     'Şah I Abbasın islahatları', 20),
    ('tarix-8-xvi-xvii', 'tarix-8-xvi-xvii-celaliler-herekati',
     'Cəlalilər hərəkatı. Şah I Abbasın hərbi uğurları', 30),
    ('tarix-8-xvi-xvii', 'tarix-8-xvi-xvii-esrin-ikinci',
     'XVI əsrin ikinci yarısı - XVII əsrdə sosial-iqtisadi və ictimai həyat', 40),
    ('tarix-8-xvi-xvii', 'tarix-8-xvi-xvii-beynelxalq-ticaret',
     'Azərbaycan beynəlxalq ticarət əlaqələrində', 50),
    ('tarix-8-xvi-xvii', 'tarix-8-xvi-xvii-esrde-medeniyyeti',
     'XVII əsrdə Azərbaycan mədəniyyəti', 60),
    --  2. AZERBAYCAN XVIII ESRIN BIRINCI YARISINDA  (tarix-8-xviii-1)
    ('tarix-8-xviii-1', 'tarix-8-xviii-1-evvellerinde-azerbaycanda',
     'XVIII əsrin əvvəllərində Azərbaycanda iqtisadi və siyasi vəziyyət', 10),
    ('tarix-8-xviii-1', 'tarix-8-xviii-1-rusiyanin-xezer',
     'Rusiyanın Xəzər dənizi hövzəsinə yürüşə hazırlaşması', 20),
    ('tarix-8-xviii-1', 'tarix-8-xviii-1-imperiya-terefinden',
     'Azərbaycan torpaqlarının iki imperiya tərəfindən bölüşdürülməsi', 30),
    ('tarix-8-xviii-1', 'tarix-8-xviii-1-torpaqlari-rusiya',
     'Azərbaycan torpaqları Rusiya və Osmanlı dövlətlərinin hakimiyyəti altında', 40),
    ('tarix-8-xviii-1', 'tarix-8-xviii-1-azad-edilmesi',
     'Azərbaycan torpaqlarının azad edilməsi', 50),
    ('tarix-8-xviii-1', 'tarix-8-xviii-1-efsar-yaranmasi',
     'Əfşar imperiyasının yaranması', 60),
    ('tarix-8-xviii-1', 'tarix-8-xviii-1-30-40',
     'XVIII əsrin 30-40-cı illərində üsyanlar', 70),
    ('tarix-8-xviii-1', 'tarix-8-xviii-1-efsar-suqutu',
     'Əfşar imperiyasının süqutu', 80),
    --  3. AZERBAYCAN XVIII ESRIN IKINCI YARISINDA  (tarix-8-xanliqlar)
    ('tarix-8-xanliqlar', 'tarix-8-xanliqlar-ilk-musteqil',
     'Azərbaycanda ilk müstəqil xanlıq', 10),
    ('tarix-8-xanliqlar', 'tarix-8-xanliqlar-azerbaycanin-cenub',
     'Azərbaycanın cənub xanlıqları', 20),
    ('tarix-8-xanliqlar', 'tarix-8-xanliqlar-quba-xanligi',
     'Quba xanlığı', 30),
    ('tarix-8-xanliqlar', 'tarix-8-xanliqlar-simal-serqi',
     'Şimal-şərqi Azərbaycan torpaqlarının birləşdirilməsi', 40),
    ('tarix-8-xanliqlar', 'tarix-8-xanliqlar-qarabag-beylerbeyilikd',
     'Qarabağ - bəylərbəyilikdən xanlığa', 50),
    ('tarix-8-xanliqlar', 'tarix-8-xanliqlar-qerbi-azerbaycan',
     'Qərbi Azərbaycan xanlıqları', 60),
    ('tarix-8-xanliqlar', 'tarix-8-xanliqlar-ikihakimiyyetl',
     'İkihakimiyyətli xanlıqlar', 70),
    ('tarix-8-xanliqlar', 'tarix-8-xanliqlar-baki-lenkeran',
     'Bakı, Lənkəran və Dərbənd xanlıqları', 80),
    ('tarix-8-xanliqlar', 'tarix-8-xanliqlar-camaat-sultanliqlar',
     'Camaat, sultanlıqlar və məlikliklər', 90),
    ('tarix-8-xanliqlar', 'tarix-8-xanliqlar-aga-mehemmed',
     'Ağa Məhəmməd xan Qacarın birləşdirmə siyasəti', 100),
    ('tarix-8-xanliqlar', 'tarix-8-xanliqlar-xviii-esrin',
     'XVIII əsrin ikinci yarısında Azərbaycanda ictimai həyat', 110),
    ('tarix-8-xanliqlar', 'tarix-8-xanliqlar-iqtisadi-veziyyet',
     'İqtisadi vəziyyət. Sənətkarlıq. Ticarət', 120),
    --  4. AZERBAYCAN XIX ESRIN EVVELLERINDE  (tarix-8-xix)
    ('tarix-8-xix', 'tarix-8-xix-torpaqlarinin-isgalina',
     'Rusiyanın Azərbaycan torpaqlarının işğalına başlaması', 10),
    ('tarix-8-xix', 'tarix-8-xix-car-balakenin',
     'Car-Balakənin və Gəncə xanlığının Rusiya tərəfindən işğalı', 20),
    ('tarix-8-xix', 'tarix-8-xix-qarabag-seki',
     'Qarabağ, Şəki və Şamaxı xanlıqlarının Rusiya tərəfindən işğalı', 30),
    ('tarix-8-xix', 'tarix-8-xix-derbend-baki',
     'Dərbənd, Bakı və Quba xanlıqlarının işğalı', 40),
    ('tarix-8-xix', 'tarix-8-xix-azerbaycanin-simal',
     'Azərbaycanın şimal ərazilərində Rusiyanın müstəmləkə rejimi', 50),
    ('tarix-8-xix', 'tarix-8-xix-naxcivan-irevan',
     'Naxçıvan və İrəvan xanlıqlarının işğalı', 60),
    ('tarix-8-xix', 'tarix-8-xix-xviii-esrde',
     'XVIII əsrdə və XIX əsrin əvvəlində Azərbaycan mədəniyyəti', 70),
    --  4. AZERBAYCAN XIX ESRIN EVVELLERINDE  (tarix-8-muqavileler)
    ('tarix-8-muqavileler', 'tarix-8-muqavileler-gulustan-muqavilesi',
     'Gülüstan müqaviləsi', 10),
    ('tarix-8-muqavileler', 'tarix-8-muqavileler-turkmencay-muqavilesi',
     'Türkmənçay müqaviləsi', 20),
    ('tarix-8-muqavileler', 'tarix-8-muqavileler-azerbaycani-parcalayan',
     'Azərbaycanı parçalayan və müstəmləkəyə çevirən ədalətsiz müqavilələr', 30),
    --  ============  9-cu sinif  ============
    --  I bolme. Azerbaycan XIX-XX yuzilliyin evvellerinde  (tarix-9-xix)
    ('tarix-9-xix', 'tarix-9-xix-fesil-xix',
     'I fəsiL Azərbaycan XIX yüzillikdə', 10),
    ('tarix-9-xix', 'tarix-9-xix-simali-azerbaycanda',
     'Şimali Azərbaycanda müstəmləkə rejiminin yaradılması və möhkəmləndirilməsi', 20),
    ('tarix-9-xix', 'tarix-9-xix-burjua-islahatlari',
     'Burjua islahatları', 30),
    ('tarix-9-xix', 'tarix-9-xix-dunyanin-neft',
     'Dünyanın neft mərkəzi - Bakı', 40),
    ('tarix-9-xix', 'tarix-9-xix-senayenin-diger',
     'Sənayenin digər sahələri. Kənd təsərrüfatı', 50),
    ('tarix-9-xix', 'tarix-9-xix-milletin-formalasmasi',
     'Millətin formalaşması', 60),
    ('tarix-9-xix', 'tarix-9-xix-xalq-herekati',
     'Xalq hərəkatı', 70),
    ('tarix-9-xix', 'tarix-9-xix-cenubi-azerbaycan',
     'Cənubi Azərbaycan', 80),
    ('tarix-9-xix', 'tarix-9-xix-medeniyyet',
     'Mədəniyyət', 90),
    --  I bolme. Azerbaycan XIX-XX yuzilliyin evvellerinde  (tarix-9-xx-evvel)
    ('tarix-9-xx-evvel', 'tarix-9-xx-evvel-fesil-yuzilliyin',
     'II fəsil. Azərbaycan XX yüzilliyin əvvəllərində', 10),
    ('tarix-9-xx-evvel', 'tarix-9-xx-evvel-senayenin-veziyyeti',
     'Sənayenin vəziyyəti. Kənd təsərrüfatı', 20),
    ('tarix-9-xx-evvel', 'tarix-9-xx-evvel-demokratik-herekat',
     'Milli-demokratik hərəkat', 30),
    ('tarix-9-xx-evvel', 'tarix-9-xx-evvel-carizmin-qirgin',
     'Çarizmin milli qırğın siyasəti', 40),
    ('tarix-9-xx-evvel', 'tarix-9-xx-evvel-cenubi-azerbaycanda',
     'Cənubi Azərbaycanda Məşrutə inqilabı', 50),
    ('tarix-9-xx-evvel', 'tarix-9-xx-evvel-birinci-dunya',
     'Azərbaycan Birinci dünya müharibəsi illərində', 60),
    ('tarix-9-xx-evvel', 'tarix-9-xx-evvel-simali-fevral',
     'Şimali Azərbaycan Fevral inqilabından sonra', 70),
    ('tarix-9-xx-evvel', 'tarix-9-xx-evvel-medeniyyet',
     'Mədəniyyət', 80),
    --  II bolme. Azerbaycan 1918-1920-ci illerde. Birinci respublika  (tarix-9-cumhuriyyet)
    ('tarix-9-cumhuriyyet', 'tarix-9-cumhuriyyet-iii-fesil',
     'III fəsil. Azarbaycan Xalq Cümhuriyyəti', 10),
    ('tarix-9-cumhuriyyet', 'tarix-9-cumhuriyyet-baki-sovetinin',
     'Bakı Sovetinin azərbaycanlılara qarşı soyqırımı siyasəti', 20),
    ('tarix-9-cumhuriyyet', 'tarix-9-cumhuriyyet-azerbaycan-xalq',
     'Azərbaycan Xalq Cümhuriyyəti', 30),
    ('tarix-9-cumhuriyyet', 'tarix-9-cumhuriyyet-cenubi-azerbaycanda',
     'Cənubi Azərbaycanda milli azadlıq hərəkatı', 40),
    --  III bolme, Azerbaycan 1920-80-ci illerde. Ikinci respublika  (tarix-9-sovet)
    ('tarix-9-sovet', 'tarix-9-sovet-1920-40',
     'IV fəsil. Azərbaycan 1920-40-cı illərdə', 10),
    ('tarix-9-sovet', 'tarix-9-sovet-azerbaycan-yaradilmasi',
     'Azərbaycan SSR-in yaradılması', 20),
    ('tarix-9-sovet', 'tarix-9-sovet-musteqil-azerbaycani',
     '"Müstəqil sovet Azərbaycanı" şüarının iflası', 30),
    ('tarix-9-sovet', 'tarix-9-sovet-heyata-kecirilen',
     'Azərbaycan SSR-də həyata keçirilən İqtisadi, siyasi və mədəni tədbirlər', 40),
    ('tarix-9-sovet', 'tarix-9-sovet-muharibesi-illerinde',
     'Azərbaycan SSR ikinci dünya müharibəsi illərində', 50),
    ('tarix-9-sovet', 'tarix-9-sovet-milli-azadliq',
     'Cənubi Azərbaycanda milli azadlıq hərəkatı', 60),
    ('tarix-9-sovet', 'tarix-9-sovet-muharibesinden-sonraki',
     'V fəsil. Azərbaycan İkinci dünya müharibəsindən sonrakı dövrdə', 70),
    ('tarix-9-sovet', 'tarix-9-sovet-1940-illerin',
     'Azərbaycan SSR 1940-cı illərin ortalan - 60-cı illərdə', 80),
    ('tarix-9-sovet', 'tarix-9-sovet-1970-80',
     'Azərbaycan SSR 1970-80-ci illərdə', 90),
    ('tarix-9-sovet', 'tarix-9-sovet-yenidenqurma-siyaseti',
     'Yenidənqurma siyasəti. Qarabağ münaqişəsinin başlanması', 100),
    ('tarix-9-sovet', 'tarix-9-sovet-iran-islam',
     'İran İslam inqilabı və Cənubi Azərbaycanda', 110),
    ('tarix-9-sovet', 'tarix-9-sovet-medeniyyet',
     'Mədəniyyət', 120),
    --  IV bolme. Azerbaycan musteqillik dovrunde. Ucuncu respublika  (tarix-9-musteqillik)
    ('tarix-9-musteqillik', 'tarix-9-musteqillik-fesil-respublikasi',
     'VI fəsil. Azərbaycan Respublikası 1990-cı illərdə', 10),
    ('tarix-9-musteqillik', 'tarix-9-musteqillik-musteqilliyini-berpasi',
     'Dövlət müstəqilliyinin bərpası', 20),
    ('tarix-9-musteqillik', 'tarix-9-musteqillik-birinci-qarabag',
     'Birinci Qarabağ müharibəsi', 30),
    ('tarix-9-musteqillik', 'tarix-9-musteqillik-qurtulus-herekati',
     'Qurtuluş hərəkatı', 40),
    ('tarix-9-musteqillik', 'tarix-9-musteqillik-quruculugu-tedbirleri',
     'Dövlət quruculuğu tədbirləri. Sosial-iqtisadi islahatlar', 50),
    ('tarix-9-musteqillik', 'tarix-9-musteqillik-respublikasini-xarici',
     'Azərbaycan Respublikasının xarici siyasəti', 60),
    --  IV bolme. Azerbaycan musteqillik dovrunde. Ucuncu respublika  (tarix-9-yeni-dovr)
    ('tarix-9-yeni-dovr', 'tarix-9-yeni-dovr-vii-fesil',
     'VII fəsil. Azərbaycan yeni minillikdə', 10),
    ('tarix-9-yeni-dovr', 'tarix-9-yeni-dovr-respublikasi-inkisaf',
     'Azərbaycan Respublikası yeni inkişaf yolunda', 20),
    ('tarix-9-yeni-dovr', 'tarix-9-yeni-dovr-cebhe-xettinde',
     'Cəbhə xəttində toqquşmalar. Dördgünlük müharibə', 30),
    ('tarix-9-yeni-dovr', 'tarix-9-yeni-dovr-xarici-siyasetde',
     'Xarici siyasətdə uğurlar', 40),
    ('tarix-9-yeni-dovr', 'tarix-9-yeni-dovr-veten-muharibesi',
     'Vətən müharibəsi', 50),
    ('tarix-9-yeni-dovr', 'tarix-9-yeni-dovr-qarabagda-quruculuq',
     'Qarabağda quruculuq. Böyük qayıdışın ilk addımları', 60),
    ('tarix-9-yeni-dovr', 'tarix-9-yeni-dovr-medeniyyet',
     'Mədəniyyət', 70),
    --  ============  11-ci sinif  ============
    --  I bolme. Azerbaycan XIX esr - XX esrin evvellerinde  (tarix-11-isgal)
    ('tarix-11-isgal', 'tarix-11-isgal-fesil-terefinden',
     'I fəsil. Azərbaycanın şimal torpaqlarının Rusiya tərəfindən işğalı', 10),
    ('tarix-11-isgal', 'tarix-11-isgal-rusiya-baslanmasi',
     'Rusiya tərəfindən Azərbaycanın şimal torpaqlarının işğalına başlanması', 20),
    ('tarix-11-isgal', 'tarix-11-isgal-cenubi-qafqaz',
     'Cənubi Qafqaz uğrunda Rusiya imperiyası və Qacarlar dövləti arasında müharibələr', 30),
    --  I bolme. Azerbaycan XIX esr - XX esrin evvellerinde  (tarix-11-mustemleke)
    ('tarix-11-mustemleke', 'tarix-11-mustemleke-isgali-dovrunde',
     'II fəsil. Şimali Azərbaycan Rusiya işğalı dövründə', 10),
    ('tarix-11-mustemleke', 'tarix-11-mustemleke-imperiyasinin-siyaseti',
     'Rusiya imperiyasının müstəmləkə siyasəti', 20),
    ('tarix-11-mustemleke', 'tarix-11-mustemleke-40-kecirilen',
     'XIX əsrin 40-cı illərində keçirilən islahatlar', 30),
    ('tarix-11-mustemleke', 'tarix-11-mustemleke-iii-ikinci',
     'III fəsil. XIX əsrin ikinci yarısı - XX əsrin əvvəllərində Şimali Azərbaycanın sosial-iqtisadi və siyasi inkişaf xüsusiyyətləri', 40),
    ('tarix-11-mustemleke', 'tarix-11-mustemleke-yeni-munasibetlerin',
     'Yeni sosial münasibətlərin meydana gəlməsi', 50),
    ('tarix-11-mustemleke', 'tarix-11-mustemleke-simali-xususiyyetleri',
     'Şimali Azərbaycanın iqtisadi inkişaf xüsusiyyətləri', 60),
    ('tarix-11-mustemleke', 'tarix-11-mustemleke-eleyhine-cixislar',
     'Müstəmləkə əleyhinə çıxışlar. Milli demokratik hərəkat', 70),
    ('tarix-11-mustemleke', 'tarix-11-mustemleke-carizmin-qirgin',
     'Çarizmin milli qırğın siyasəti', 80),
    ('tarix-11-mustemleke', 'tarix-11-mustemleke-birinci-dunya',
     'Şimali Azərbaycan Birinci dünya müharibəsi illərində', 90),
    ('tarix-11-mustemleke', 'tarix-11-mustemleke-fesil-xususiyyetleri',
     'IV fəsil. Cənubi Azərbaycanın sosial-iqtisadi inkişaf xüsusiyyətləri', 100),
    ('tarix-11-mustemleke', 'tarix-11-mustemleke-cenubi-esrde',
     'Cənubi Azərbaycan XIX əsrdə', 110),
    ('tarix-11-mustemleke', 'tarix-11-mustemleke-mesrute-inqilabi',
     'Məşrutə inqilabı', 120),
    ('tarix-11-mustemleke', 'tarix-11-mustemleke-fesil-medeniyyeti',
     'V fəsil. Azərbaycan mədəniyyəti', 130),
    ('tarix-11-mustemleke', 'tarix-11-mustemleke-azerbaycan-evvellerinde',
     'Azərbaycan mədəniyyəti XIX-XX əsrin əvvəllərində', 140),
    --  II bolme. Birinci respublika - AXC  (tarix-11-cumhuriyyet)
    ('tarix-11-cumhuriyyet', 'tarix-11-cumhuriyyet-muselman-serqinin',
     'VI fəsil. Müsəlman Şərqinin ilk respublikası - Azərbaycan Xalq Cümhuriyyəti', 10),
    ('tarix-11-cumhuriyyet', 'tarix-11-cumhuriyyet-ikinci-rus',
     'İkinci rus inqilabı və onun Şimali Azərbaycana təsiri', 20),
    ('tarix-11-cumhuriyyet', 'tarix-11-cumhuriyyet-baki-sovetinin',
     'Bakı Sovetinin azərbaycanlılara qarşı soyqırımı siyasəti', 30),
    ('tarix-11-cumhuriyyet', 'tarix-11-cumhuriyyet-istiqlal-yolunda',
     'Şimali Azərbaycan istiqlal yolunda', 40),
    ('tarix-11-cumhuriyyet', 'tarix-11-cumhuriyyet-azerbaycan-xalq',
     'Azərbaycan Xalq Cümhuriyyəti', 50),
    ('tarix-11-cumhuriyyet', 'tarix-11-cumhuriyyet-vii-1917',
     'VII fəsil. Cənubi Azərbaycan 1917-1920-ci illərdə', 60),
    ('tarix-11-cumhuriyyet', 'tarix-11-cumhuriyyet-azerbaycanda-milli',
     'Cənubi Azərbaycanda milli-demokratik hərəkat. Ş.M.Xiyabani', 70),
    --  III bolme. Ikinci respublika - Azerbaycan SSR  (tarix-11-sovet)
    ('tarix-11-sovet', 'tarix-11-sovet-viii-illerinde',
     'VIII fəsil. Azərbaycan XX əsrin 20-40-cı illərində', 10),
    ('tarix-11-sovet', 'tarix-11-sovet-bolsevik-istilasi',
     'Bolşevik istilası və Azərbaycan SSR-in yaradılması', 20),
    ('tarix-11-sovet', 'tarix-11-sovet-musteqil-azerbaycani',
     '"Müstəqil sovet Azərbaycanı" şüarının iflası', 30),
    ('tarix-11-sovet', 'tarix-11-sovet-30-illerinde',
     'Azərbaycan SSR XX əsrin 20-30-cu illərində', 40),
    ('tarix-11-sovet', 'tarix-11-sovet-muharibesi-illerinde',
     'Azərbaycan SSR İkinci dünya müharibəsi illərində', 50),
    ('tarix-11-sovet', 'tarix-11-sovet-cenubi-illerinde',
     'Cənubi Azərbaycan XX əsrin 20-40-cı illərində', 60),
    ('tarix-11-sovet', 'tarix-11-sovet-muharibesinden-dovrde',
     'IX fəsil. Azərbaycan İkinci dünya müharibəsindən sonrakı dövrdə', 70),
    ('tarix-11-sovet', 'tarix-11-sovet-illerinin-ortalari',
     'Azərbaycan SSR XX əsrin 40-cı illərinin ortaları - 60-cı illərdə', 80),
    ('tarix-11-sovet', 'tarix-11-sovet-idareciliyin-mohkemlendiril',
     'İdarəçiliyin möhkəmləndirilməsi. 70-80-ci illərdə sosial-iqtisadi uğurlar', 90),
    ('tarix-11-sovet', 'tarix-11-sovet-yenidenqurma-askarliq',
     '"Yenidənqurma" və "aşkarlıq" siyasətinin iflasa uğraması. Qarabağ münaqişəsinin başlanması.', 100),
    ('tarix-11-sovet', 'tarix-11-sovet-iran-islam',
     'Cənubi Azərbaycan İran İslam inqilabı illəri və ondan sonrakı dövrdə', 110),
    ('tarix-11-sovet', 'tarix-11-sovet-medeniyyeti-illerinde',
     'Azərbaycan mədəniyyəti XX əsrin 40-80-ci illərində', 120),
    --  IV bolme. Ucuncu respublika - Azerbaycan Respublikasi  (tarix-11-musteqillik)
    ('tarix-11-musteqillik', 'tarix-11-musteqillik-respublikasi-berpasinin',
     'X fəsil. Azərbaycan Respublikası dövlət müstəqilliyinin bərpasının ilk illərində', 10),
    ('tarix-11-musteqillik', 'tarix-11-musteqillik-dovlet-berpasi',
     'Dövlət müstəqilliyinin bərpası', 20),
    ('tarix-11-musteqillik', 'tarix-11-musteqillik-birinci-qarabag',
     'Birinci Qarabağ müharibəsi', 30),
    ('tarix-11-musteqillik', 'tarix-11-musteqillik-xocali-soyqirimi',
     'Xocalı soyqırımı', 40),
    ('tarix-11-musteqillik', 'tarix-11-musteqillik-musteqilliyin-addimlari',
     'Müstəqilliyin ilk addımları', 50),
    ('tarix-11-musteqillik', 'tarix-11-musteqillik-milli-qurtulus',
     'Milli qurtuluş', 60),
    ('tarix-11-musteqillik', 'tarix-11-musteqillik-huquqi-demokratik',
     'XI fəsil. Hüquqi-demokratik dövlət quruculuğu yolunda', 70),
    ('tarix-11-musteqillik', 'tarix-11-musteqillik-istiqametinde-tedbirler',
     'Dövlət quruculuğu istiqamətində həyata keçirilən tədbirlər', 80),
    ('tarix-11-musteqillik', 'tarix-11-musteqillik-esrin-90',
     'XX əsrin 90-cı illərində həyata keçirilən sosial-iqtisadi islahatlar', 90),
    ('tarix-11-musteqillik', 'tarix-11-musteqillik-respublikasini-xarici',
     'Azərbaycan Respublikasının xarici siyasəti', 100),
    ('tarix-11-musteqillik', 'tarix-11-musteqillik-yeni-minillik',
     'Yeni minillik - Yeni Lider', 110),
    ('tarix-11-musteqillik', 'tarix-11-musteqillik-cebhe-xettinde',
     'Cəbhə xəttində toqquşmalar. 4 günlük müharibə', 120),
    ('tarix-11-musteqillik', 'tarix-11-musteqillik-medeniyyet',
     'Mədəniyyət', 130),
    --  IV bolme. Ucuncu respublika - Azerbaycan Respublikasi  (tarix-11-zefer)
    ('tarix-11-zefer', 'tarix-11-zefer-xii-fesil',
     'XII fəsil. Böyük Zəfər', 10),
    ('tarix-11-zefer', 'tarix-11-zefer-erefe',
     'Ərəfə', 20),
    ('tarix-11-zefer', 'tarix-11-zefer-veten-muharibesi',
     'Vətən müharibəsi', 30),
    ('tarix-11-zefer', 'tarix-11-zefer-qarabagda-quruculuq',
     'Qarabağda quruculuq. Böyük Qayıdışın ilk addımları', 40)
  ) as v(parent_slug, slug, name, sort)
  join public.topics p on p.slug = v.parent_slug
   and p.subject_id = (select id from public.subjects where slug = 'tarix')
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort,
      parent_id = excluded.parent_id, level_id = excluded.level_id;

do $$
declare k int;
begin
  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'tarix'
    join public.levels   l on l.id = p.level_id and l.code = '5';
  if k <> 39 then
    raise exception 'tarix 5-ci alt movzulari: 39 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'tarix'
    join public.levels   l on l.id = p.level_id and l.code = '6';
  if k <> 5 then
    raise exception 'tarix 6-ci alt movzulari: 5 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'tarix'
    join public.levels   l on l.id = p.level_id and l.code = '8';
  if k <> 36 then
    raise exception 'tarix 8-ci alt movzulari: 36 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'tarix'
    join public.levels   l on l.id = p.level_id and l.code = '9';
  if k <> 46 then
    raise exception 'tarix 9-cu alt movzulari: 46 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'tarix'
    join public.levels   l on l.id = p.level_id and l.code = '11';
  if k <> 53 then
    raise exception 'tarix 11-ci alt movzulari: 53 gozlenilirdi, % tapildi', k;
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
    join public.subjects s on s.id = t.subject_id and s.slug = 'tarix'
    join public.levels   l on l.id = t.level_id
   where t.parent_id is null and true;
  if k <> 29 then
    raise exception 'Tarix ust movzu sayi 29 deyil: %', k;
  end if;

  raise notice 'Tarix 5, 6, 8, 9, 11 (7 ve 10-da yoxdur): 179 alt movzu hazir.';
end $$;
