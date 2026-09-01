-- =====================================================================
--  88_alt_movzular_biologiya6_11.sql : BIOLOGIYA 6-11 - ALT MOVZULAR
--
--  NIYE
--  Yeddinci fenn.  Riyaziyyat, heyat bilgisi, informatika, fizika,
--  kimya hazirdir.  Biologiya 6-ci sinifden baslayir (1-5-de yoxdur).
--
--  MENBE: e-derslik.edu.az "Movzular" agaci - kitab id 538 (6),
--  863/864 (7), 927/928 (8), 727 (10), 276 (11).  Adlar EYNILE
--  goturulub.
--
--  9-CU SINIF BU FAYLDA YOXDUR: kitab id 467-nin server terefi
--  BOS qayidir (Cemi sehife: 0) - portal bu derslik ucun meznunu
--  hele yuklemeyib, umumi mundericat.py scraperi de bunu tesdiq edir.
--  Ust movzular (bio-9-*) ondan evvel, basqa menbeden qurulub -
--  toxunulmur, sadece bu merhelede alt movzu almir.  Portal
--  meznunu yukleyende elave olunacaq.
--
--  DERSLIYIN QURULUSU:
--
--  6-ci sinif: 8 Fesil, hamisi bire-bir movzuya (birbasa).
--
--  7-ci sinif: kitab 863-un "Giris" bolmesi (2 ders, basliq yoxdur)
--  ayri "==" bolme kimi gelir, bazada ayri movzusu yoxdur - ilk
--  movzuya (bio-7-huceyre-orqanizm) elave edildi.
--
--  8-ci sinif: 8 Bolme, hamisi bire-bir movzuya (birbasa).
--
--  10-cu sinif: derslikde 5 boyuk boluk (I-V), bazada 8 movzu -
--  ILK boluk ("I. Biosferde istehsal ve istehlak") sehife 31-den
--  IKI movzuya bolunur (heyat-prosesleri/istehsal).  "II" ve "III"
--  boluklerin ICINDE nomresiz "Bolme N." alt-basliqlari var (novbeti
--  dersle EYNI sehifede, alt-basliq qaydasi ile tutulur) - "II"
--  UC movzuya (deyiskenlik/saglam-heyat/epidemiologiya), "III" ISE
--  IKI alt-basliqla da EYNI movzuya (tekamul) gedir - dersllik iki
--  hisseye bolse de bazada tek movzudur.  "IV" ve "V" birbasa.
--
--  11-ci sinif: derslikde 7 boyuk boluk (I-VII), bazada 8 movzu -
--  "II. Mikrobiologiya"nin 9 dersi TAM bakteriyalar movzusuna
--  (bio-11-bakteriyalar) yonledi.  Sebeb: dersliyin mundericat
--  panelinde bu bolmenin icinde virus-a aid AYRI basliq YOXDUR (butun
--  9 ders "Mikroorqanizmler/menfur muhit/infeksion proses" basliqli,
--  sehife araliqlari da bolunme gostermir) - uydurma sehife serhedi
--  qoymaqdansa, movcud movzunun (bio-11-viruslar) bu merhelede 0 alt
--  movzu qalmasi seçildi.  Qalan 6 boluk birbasa bire-bir movzuya.
--
--  BURAXILAN BENDLER: "Layihə", "Təqdimat mövzuları" / "Təqdimat və
--  referat mövzuları" / "Təqdimat üçün mövzular" - ders deyil, elavedir
--  (10 ve 11-ci sinifde tekrar-tekrar cixir).  "İstifadə edilmiş
--  ədəbiyyat" da eyni sebeble xaric edilib.
--
--  "•" ILE BASLAYAN BENDLER (6-ci sinif): dusterin ozu, silinir.
--
--  YAZI QUSURLARI: 6-ci sinifde "Xəstəliktörədən" (bosluq dusub),
--  7-ci sinifde iki bend sonunda artiq nöqte ("Tozlanma.",
--  "Çiçək və onun quruluşu."), 8-ci sinifde bir bend sonunda ("İnsan
--  ürəyinin quruluşu və işi."), 7-ci sinif II hissede iki bendde
--  noqteden sonra bosluq yoxdur ("hissələri.Buğumayaqlılar",
--  "hissələri.Molyusklar").
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
--       6-ci   s.32   9. Bakteriyalarin yayilmasi ve tebietde rolu. Xesteliktoreden bakteriyalar. Viruslar
--                    -> Bakteriyalarin yayilmasi ve tebietde rolu. Xestelik toreden bakteriyalar. Viruslar
--       7-ci   s.54   3.1 Cicek ve onun qurulusu.
--                    -> Cicek ve onun qurulusu
--       7-ci   s.57   3.2 Tozlanma.
--                    -> Tozlanma
--       7-ci   s.15   4.4 Onurgasiz heyvanlarda bedenin esas hisseleri.Bugumayaqlilar
--                    -> Onurgasiz heyvanlarda bedenin esas hisseleri. Bugumayaqlilar
--       7-ci   s.19   4.5 Onurgasiz heyvanlarda bedenin esas hisseleri.Molyusklar
--                    -> Onurgasiz heyvanlarda bedenin esas hisseleri. Molyusklar
--       8-ci   s.58   3.2 Insan ureyinin qurulusu ve isi.
--                    -> Insan ureyinin qurulusu ve isi

insert into public.topics (subject_id, level_id, parent_id, slug, name, sort)
select p.subject_id, p.level_id, p.id, v.slug, v.name, v.sort
  from (values
    --  ============  6-ci sinif  ============
    --  Fesil 1. Biologiyanin tedqiqat obyektleri  (bio-6-tedqiqat)
    ('bio-6-tedqiqat', 'bio-6-tedqiqat-vetenimizin-tebieti',
     'Vətənimizin təbiəti', 10),
    ('bio-6-tedqiqat', 'bio-6-tedqiqat-biologiya-orqanizmleri',
     'Biologiya canlı orqanizmləri öyrənən elmdir', 20),
    ('bio-6-tedqiqat', 'bio-6-tedqiqat-orqanizmlerin-esas',
     'Canlı orqanizmlərin əsas xüsusiyyətləri', 30),
    ('bio-6-tedqiqat', 'bio-6-tedqiqat-canlilarin-tesnifati',
     'Canlıların təsnifatı', 40),
    ('bio-6-tedqiqat', 'bio-6-tedqiqat-insanin-tesnifat',
     'İnsanın təsnifat sistemində yeri', 50),
    ('bio-6-tedqiqat', 'bio-6-tedqiqat-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    --  Fesil 2. Orqanizmlerin huceyrevi qurulusu. Toxumalar, orqanlar ve orqanlar sistemi  (bio-6-huceyre)
    ('bio-6-huceyre', 'bio-6-huceyre-laboratoriya-avadanliqlari',
     'Laboratoriya avadanlıqları', 10),
    ('bio-6-huceyre', 'bio-6-huceyre-umumi-qurulusu',
     'Hüceyrənin ümumi quruluşu', 20),
    ('bio-6-huceyre', 'bio-6-huceyre-prokariot-orqanizmler',
     'Prokariot orqanizmlər', 30),
    ('bio-6-huceyre', 'bio-6-huceyre-bakteriyalarin-yayilmasi',
     'Bakteriyaların yayılması və təbiətdə rolu. Xəstəlik törədən bakteriyalar. Viruslar', 40),
    ('bio-6-huceyre', 'bio-6-huceyre-bolunmesi-inkisafi',
     'Hüceyrələrin bölünməsi və inkişafı', 50),
    ('bio-6-huceyre', 'bio-6-huceyre-birhuceyreli-coxhuceyreli',
     'Birhüceyrəli və çoxhüceyrəli orqanizmlər', 60),
    ('bio-6-huceyre', 'bio-6-huceyre-toredici-ortuk',
     'Bitkinin törədici, örtük və mexaniki toxumaları', 70),
    ('bio-6-huceyre', 'bio-6-huceyre-oturucu-esas',
     'Bitkinin ötürücü, əsas və ifrazat toxumaları', 80),
    ('bio-6-huceyre', 'bio-6-huceyre-heyvan-toxumalari',
     'Heyvan toxumaları', 90),
    ('bio-6-huceyre', 'bio-6-huceyre-heyvanlarin-orqanlari',
     'Heyvanların orqanları və orqanlar sistemi', 100),
    ('bio-6-huceyre', 'bio-6-huceyre-umumi',
     'Ümumiləşdirici tapşırıqlar', 110),
    --  Fesil 3. Bitkilerin vegetativ orqanlari  (bio-6-vegetativ)
    ('bio-6-vegetativ', 'bio-6-vegetativ-cicekli-bitkilerin',
     'Çiçəkli bitkilərin əsas orqanları', 10),
    ('bio-6-vegetativ', 'bio-6-vegetativ-zog-tumurcugun',
     'Zoğ və tumurcuğun quruluşu. Tumurcuğun inkişafı', 20),
    ('bio-6-vegetativ', 'bio-6-vegetativ-govdenin-daxili',
     'Gövdənin daxili quruluşu', 30),
    ('bio-6-vegetativ', 'bio-6-vegetativ-xarici-yarpaqlarin',
     'Yarpağın xarici quruluşu. Yarpaqların düzülüşü', 40),
    ('bio-6-vegetativ', 'bio-6-vegetativ-huceyrevi-qurulusu',
     'Yarpağın hüceyrəvi quruluşu', 50),
    ('bio-6-vegetativ', 'bio-6-vegetativ-kokun-novleri',
     'Kökün quruluşu. Kökün növləri və sistemləri', 60),
    ('bio-6-vegetativ', 'bio-6-vegetativ-yeralti-sekildeyismele',
     'Bitki orqanlarının yeraltı şəkildəyişmələri', 70),
    ('bio-6-vegetativ', 'bio-6-vegetativ-yerustu-sekildeyismele',
     'Bitki orqanlarının yerüstü şəkildəyişmələri', 80),
    ('bio-6-vegetativ', 'bio-6-vegetativ-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    --  Fesil 4. Bitkilerin generativ orqanlari  (bio-6-generativ)
    ('bio-6-generativ', 'bio-6-generativ-cicek',
     'Çiçək', 10),
    ('bio-6-generativ', 'bio-6-generativ-cicek-qruplari',
     'Çiçək qrupları', 20),
    ('bio-6-generativ', 'bio-6-generativ-toxumun-qurulusu',
     'Toxumun quruluşu', 30),
    ('bio-6-generativ', 'bio-6-generativ-meyve',
     'Meyvə', 40),
    ('bio-6-generativ', 'bio-6-generativ-umumi',
     'Ümumiləşdirici tapşırıqlar', 50),
    --  Fesil 5. Canlilarda hereket, dayaq, qidalanma ve teneffus  (bio-6-hereket-qida)
    ('bio-6-hereket-qida', 'bio-6-hereket-qida-heyvanlarda-dayaqsistemi',
     'Heyvanlarda hərəkət və dayaqsistemi', 10),
    ('bio-6-hereket-qida', 'bio-6-hereket-qida-dayaq-sistemi',
     'Bitkilərdə dayaq sistemi', 20),
    ('bio-6-hereket-qida', 'bio-6-hereket-qida-bitkilerin-yeralti',
     'Bitkilərin yeraltı qidalanması', 30),
    ('bio-6-hereket-qida', 'bio-6-hereket-qida-havadan-fotosintez',
     'Bitkilərin havadan qidalanması. Fotosintez', 40),
    ('bio-6-hereket-qida', 'bio-6-hereket-qida-heyvanlarin',
     'Heyvanların qidalanması', 50),
    ('bio-6-hereket-qida', 'bio-6-hereket-qida-bakteriya-gobeleklerin',
     'Bakteriya və göbələklərin qidalanması', 60),
    ('bio-6-hereket-qida', 'bio-6-hereket-qida-bitkilerde-teneffus',
     'Bitkilərdə tənəffüs', 70),
    ('bio-6-hereket-qida', 'bio-6-hereket-qida-heyvanlarda-teneffus',
     'Heyvanlarda tənəffüs', 80),
    ('bio-6-hereket-qida', 'bio-6-hereket-qida-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    --  Fesil 6. Orqanizmlerde maddelerin dasinmasi, ifrazat, coxalma ve inkisaf  (bio-6-dasinma-coxalma)
    ('bio-6-dasinma-coxalma', 'bio-6-dasinma-coxalma-bitkilerin-suyu',
     'Bitkilərin suyu buxarlandırması. Xəzan', 10),
    ('bio-6-dasinma-coxalma', 'bio-6-dasinma-coxalma-dasiyici-sistem',
     'Heyvanlarda daşıyıcı sistem', 20),
    ('bio-6-dasinma-coxalma', 'bio-6-dasinma-coxalma-ifrazat',
     'İfrazat', 30),
    ('bio-6-dasinma-coxalma', 'bio-6-dasinma-coxalma-qeyri-cinsi',
     'Qeyri-cinsi çoxalma', 40),
    ('bio-6-dasinma-coxalma', 'bio-6-dasinma-coxalma-cicekli-bitkilerde',
     'Çiçəkli bitkilərdə vegetativ çoxalma', 50),
    ('bio-6-dasinma-coxalma', 'bio-6-dasinma-coxalma-tozlanma',
     'Tozlanma', 60),
    ('bio-6-dasinma-coxalma', 'bio-6-dasinma-coxalma-orqanizmlerin-cinsi',
     'Orqanizmlərin cinsi çoxalması', 70),
    ('bio-6-dasinma-coxalma', 'bio-6-dasinma-coxalma-toxumun-cucermesi',
     'Toxumun cücərməsi', 80),
    ('bio-6-dasinma-coxalma', 'bio-6-dasinma-coxalma-boyume-inkisaf',
     'Heyvanlarda böyümə və inkişaf', 90),
    ('bio-6-dasinma-coxalma', 'bio-6-dasinma-coxalma-umumi',
     'Ümumiləşdirici tapşırıqlar', 100),
    --  Fesil 7. Orqanizm ve tebii birliklere muhitin tesiri  (bio-6-muhit)
    ('bio-6-muhit', 'bio-6-muhit-meskunlasmasi-yayilmasi',
     'Canlı orqanizmlərin məskunlaşması və yayılması', 10),
    ('bio-6-muhit', 'bio-6-muhit-qarsiliqli-elaqe',
     'Orqanizmlərin mühitlə qarşılıqlı əlaqə', 20),
    ('bio-6-muhit', 'bio-6-muhit-tebii-birlikler',
     'Təbii birliklər', 30),
    ('bio-6-muhit', 'bio-6-muhit-insan-tebiet',
     'İnsan və canlı təbiət', 40),
    ('bio-6-muhit', 'bio-6-muhit-azerbaycan-qoruqlari',
     'Azərbaycan qoruqları', 50),
    ('bio-6-muhit', 'bio-6-muhit-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    --  Fesil 8. Bitki ve heyvanlarin insan heyatinda rolu  (bio-6-rol)
    ('bio-6-rol', 'bio-6-rol-medeni-bitkilerin',
     'Mədəni bitkilərin insan həyatında əhəmiyyəti', 10),
    ('bio-6-rol', 'bio-6-rol-derman-bitkileri',
     'Dərman bitkiləri', 20),
    ('bio-6-rol', 'bio-6-rol-heyvanlarin-ehlilesdirilme',
     'Heyvanların əhliləşdirilməsi və insan həyatında rolu', 30),
    ('bio-6-rol', 'bio-6-rol-canlilarin-saglamliginda',
     'Canlıların insan sağlamlığında rolu', 40),
    ('bio-6-rol', 'bio-6-rol-duzgun-qidalanma',
     'Düzgün qidalanma', 50),
    ('bio-6-rol', 'bio-6-rol-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    --  ============  7-ci sinif  ============
    --  Giris  (bio-7-huceyre-orqanizm)
    ('bio-7-huceyre-orqanizm', 'bio-7-huceyre-orqanizm-biologiya-neyi',
     'Biologiya nəyi öyrənir', 10),
    ('bio-7-huceyre-orqanizm', 'bio-7-huceyre-orqanizm-biologiyani-oyrenmek',
     'Biologiyanı öyrənmək bizə nə verir', 20),
    --  Bolme 1. Huceyre ve orqanizm  (bio-7-huceyre-orqanizm)
    ('bio-7-huceyre-orqanizm', 'bio-7-huceyre-orqanizm-canlilarin-esas',
     'Canlıların əsas xüsusiyyətləri', 30),
    ('bio-7-huceyre-orqanizm', 'bio-7-huceyre-orqanizm-mikroskopunun-qurulusu',
     'İşıq mikroskopunun quruluşu', 40),
    ('bio-7-huceyre-orqanizm', 'bio-7-huceyre-orqanizm-mikroskopundan-istifade',
     'İşıq mikroskopundan istifadə', 50),
    ('bio-7-huceyre-orqanizm', 'bio-7-huceyre-orqanizm-umumi-qurulusu',
     'Hüceyrənin ümumi quruluşu', 60),
    ('bio-7-huceyre-orqanizm', 'bio-7-huceyre-orqanizm-bitki-heyvan',
     'Bitki və heyvan hüceyrələrinin quruluşu', 70),
    ('bio-7-huceyre-orqanizm', 'bio-7-huceyre-orqanizm-bakteriyalar',
     'Bakteriyalar', 80),
    ('bio-7-huceyre-orqanizm', 'bio-7-huceyre-orqanizm-ixtisaslasmis',
     'İxtisaslaşmış hüceyrələr', 90),
    ('bio-7-huceyre-orqanizm', 'bio-7-huceyre-orqanizm-elm-texnologiya',
     'Elm, texnologiya, həyat', 100),
    ('bio-7-huceyre-orqanizm', 'bio-7-huceyre-orqanizm-xulase',
     'Xülasə', 110),
    ('bio-7-huceyre-orqanizm', 'bio-7-huceyre-orqanizm-umumi',
     'Ümumiləşdirici tapşırıqlar', 120),
    --  Bolme 2. Bitki orqanizmi  (bio-7-bitki)
    ('bio-7-bitki', 'bio-7-bitki-orqanizmin-teskili',
     'Orqanizmin təşkili səviyyələri', 10),
    ('bio-7-bitki', 'bio-7-bitki-cicekli-kok',
     'Çiçəkli bitkilərin orqanları. Kök', 20),
    ('bio-7-bitki', 'bio-7-bitki-cicekli-govde',
     'Çiçəkli bitkilərin orqanları. Gövdə', 30),
    ('bio-7-bitki', 'bio-7-bitki-cicekli-yarpaq',
     'Çiçəkli bitkilərin orqanları. Yarpaq', 40),
    ('bio-7-bitki', 'bio-7-bitki-elm-texnologiya',
     'Elm, texnologiya, həyat', 50),
    ('bio-7-bitki', 'bio-7-bitki-xulase',
     'Xülasə', 60),
    ('bio-7-bitki', 'bio-7-bitki-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    --  Bolme 3. Bitkilerde coxalma  (bio-7-coxalma)
    ('bio-7-coxalma', 'bio-7-coxalma-cicek-qurulusu',
     'Çiçək və onun quruluşu', 10),
    ('bio-7-coxalma', 'bio-7-coxalma-tozlanma',
     'Tozlanma', 20),
    ('bio-7-coxalma', 'bio-7-coxalma-cinsiyyetli-mayalanma',
     'Çiçəkli bitkilərdə cinsiyyətli çoxalma. Mayalanma', 30),
    ('bio-7-coxalma', 'bio-7-coxalma-toxumun-qurulusu',
     'Toxumun quruluşu', 40),
    ('bio-7-coxalma', 'bio-7-coxalma-toxumlarin-cucermesi',
     'Toxumların cücərməsi', 50),
    ('bio-7-coxalma', 'bio-7-coxalma-meyve',
     'Meyvə', 60),
    ('bio-7-coxalma', 'bio-7-coxalma-meyve-yayilmasi',
     'Meyvə və toxumların yayılması', 70),
    ('bio-7-coxalma', 'bio-7-coxalma-qeyri-cinsi',
     'Çiçəkli bitkilərdə qeyri-cinsi çoxalma', 80),
    ('bio-7-coxalma', 'bio-7-coxalma-bitkilerin-dovru',
     'Bitkilərin həyat dövrü', 90),
    ('bio-7-coxalma', 'bio-7-coxalma-elm-texnologiya',
     'Elm, texnologiya, həyat', 100),
    ('bio-7-coxalma', 'bio-7-coxalma-xulase',
     'Xülasə', 110),
    ('bio-7-coxalma', 'bio-7-coxalma-umumi',
     'Ümumiləşdirici tapşırıqlar', 120),
    --  Bolme 4. Heyvanlarin beden ortukleri ve beden qurulusu  (bio-7-heyvanlar)
    ('bio-7-heyvanlar', 'bio-7-heyvanlar-xarici-ortukleri',
     'Onurğalı heyvanların xarici bədən örtükləri', 10),
    ('bio-7-heyvanlar', 'bio-7-heyvanlar-onurgali-hisseleri',
     'Onurğalı heyvanların bədən hissələri', 20),
    ('bio-7-heyvanlar', 'bio-7-heyvanlar-helqevi-qurdlar',
     'Onurğasız heyvanlarda bədənin əsas hissələri. Həlqəvi qurdlar və bağırsaqboşluqlular', 30),
    ('bio-7-heyvanlar', 'bio-7-heyvanlar-onurgasiz-bugumayaqlilar',
     'Onurğasız heyvanlarda bədənin əsas hissələri. Buğumayaqlılar', 40),
    ('bio-7-heyvanlar', 'bio-7-heyvanlar-onurgasiz-molyusklar',
     'Onurğasız heyvanlarda bədənin əsas hissələri. Molyusklar', 50),
    ('bio-7-heyvanlar', 'bio-7-heyvanlar-elm-texnologiya',
     'Elm, texnologiya, həyat', 60),
    ('bio-7-heyvanlar', 'bio-7-heyvanlar-xulase',
     'Xülasə', 70),
    ('bio-7-heyvanlar', 'bio-7-heyvanlar-umumi',
     'Ümumiləşdirici tapşırıqlar', 80),
    --  Bolme 5. Bioloji muxteliflik  (bio-7-muxteliflik)
    ('bio-7-muxteliflik', 'bio-7-muxteliflik-ekoloji-amiller',
     'Ekoloji amillər', 10),
    ('bio-7-muxteliflik', 'bio-7-muxteliflik-tebii-yasayis',
     'Təbii yaşayış mühitləri', 20),
    ('bio-7-muxteliflik', 'bio-7-muxteliflik-biomuxteliflik',
     'Biomüxtəliflik', 30),
    ('bio-7-muxteliflik', 'bio-7-muxteliflik-elm-texnologiya',
     'Elm, texnologiya, həyat', 40),
    ('bio-7-muxteliflik', 'bio-7-muxteliflik-xulase',
     'Xülasə', 50),
    ('bio-7-muxteliflik', 'bio-7-muxteliflik-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    --  Bolme 6. Ekosistemlerde enerji axini  (bio-7-ekosistem)
    ('bio-7-ekosistem', 'bio-7-ekosistem-qida-zencirleri',
     'Ekosistemlərdə qida münasibətləri. Qida zəncirləri', 10),
    ('bio-7-ekosistem', 'bio-7-ekosistem-qida-sebekesi',
     'Ekosistemlərdə qida münasibətləri. Qida şəbəkəsi', 20),
    ('bio-7-ekosistem', 'bio-7-ekosistem-quru-sebekeleri',
     'Su və quru ekosistemlərində qida şəbəkələri', 30),
    ('bio-7-ekosistem', 'bio-7-ekosistem-ekoloji-piramidalar',
     'Ekoloji piramidalar', 40),
    ('bio-7-ekosistem', 'bio-7-ekosistem-elm-texnologiya',
     'Elm, texnologiya, həyat', 50),
    ('bio-7-ekosistem', 'bio-7-ekosistem-xulase',
     'Xülasə', 60),
    ('bio-7-ekosistem', 'bio-7-ekosistem-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    --  Bolme 7. Saglam heyat terzi  (bio-7-saglam-heyat)
    ('bio-7-saglam-heyat', 'bio-7-saglam-heyat-fiziki',
     'Fiziki sağlamlıq', 10),
    ('bio-7-saglam-heyat', 'bio-7-saglam-heyat-beden-kutle',
     'Bədən kütlə indeksi və sağlamlıq', 20),
    ('bio-7-saglam-heyat', 'bio-7-saglam-heyat-psixi',
     'Psixi sağlamlıq', 30),
    ('bio-7-saglam-heyat', 'bio-7-saglam-heyat-zererli-verdisler',
     'Zərərli vərdişlər və sağlamlıq', 40),
    ('bio-7-saglam-heyat', 'bio-7-saglam-heyat-elm-texnologiya',
     'Elm, texnologiya, həyat', 50),
    ('bio-7-saglam-heyat', 'bio-7-saglam-heyat-xulase',
     'Xülasə', 60),
    ('bio-7-saglam-heyat', 'bio-7-saglam-heyat-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    --  ============  8-ci sinif  ============
    --  Bolme 1. Heyatin kimyasi  (bio-8-heyat-kimyasi)
    ('bio-8-heyat-kimyasi', 'bio-8-heyat-kimyasi-kimyevi-terkibi',
     'Hüceyrənin kimyəvi tərkibi. Su', 10),
    ('bio-8-heyat-kimyasi', 'bio-8-heyat-kimyasi-uzvi-birlesmeleri',
     'Hüceyrənin üzvi birləşmələri', 20),
    ('bio-8-heyat-kimyasi', 'bio-8-heyat-kimyasi-fermentler',
     'Fermentlər', 30),
    ('bio-8-heyat-kimyasi', 'bio-8-heyat-kimyasi-maddelerin-huceyre',
     'Maddələrin hüceyrə membranında daşınması', 40),
    ('bio-8-heyat-kimyasi', 'bio-8-heyat-kimyasi-elm-texnologiya',
     'Elm, texnologiya, həyat', 50),
    ('bio-8-heyat-kimyasi', 'bio-8-heyat-kimyasi-xulase',
     'Xülasə', 60),
    ('bio-8-heyat-kimyasi', 'bio-8-heyat-kimyasi-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    --  Bolme 2. Bitki orqanizmi  (bio-8-bitki)
    ('bio-8-bitki', 'bio-8-bitki-orqanizmi-qazlar',
     'Bitki orqanizmi və qazlar mübadiləsi', 10),
    ('bio-8-bitki', 'bio-8-bitki-fotosintez',
     'Fotosintez', 20),
    ('bio-8-bitki', 'bio-8-bitki-orqanizminde-maddelerin',
     'Bitki orqanizmində maddələrin daşınması', 30),
    ('bio-8-bitki', 'bio-8-bitki-elm-texnologiya',
     'Elm, texnologiya, həyat', 40),
    ('bio-8-bitki', 'bio-8-bitki-xulase',
     'Xülasə', 50),
    ('bio-8-bitki', 'bio-8-bitki-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    --  Bolme 3. Qan dovrani sistemi  (bio-8-qan-dovrani)
    ('bio-8-qan-dovrani', 'bio-8-qan-dovrani-heyvanlarda-qan',
     'Heyvanlarda qan dövranı', 10),
    ('bio-8-qan-dovrani', 'bio-8-qan-dovrani-insan-ureyinin',
     'İnsan ürəyinin quruluşu və işi', 20),
    ('bio-8-qan-dovrani', 'bio-8-qan-dovrani-insanin-qan',
     'İnsanın qan dövranı', 30),
    ('bio-8-qan-dovrani', 'bio-8-qan-dovrani-qanin-terkibi',
     'Qanın tərkibi və funksiyaları', 40),
    ('bio-8-qan-dovrani', 'bio-8-qan-dovrani-qankocurme-qruplari',
     'Qanköçürmə və qan qrupları', 50),
    ('bio-8-qan-dovrani', 'bio-8-qan-dovrani-elm-texnologiya',
     'Elm, texnologiya, həyat', 60),
    ('bio-8-qan-dovrani', 'bio-8-qan-dovrani-xulase',
     'Xülasə', 70),
    ('bio-8-qan-dovrani', 'bio-8-qan-dovrani-umumi',
     'Ümumiləşdirici tapşırıqlar', 80),
    --  Bolme 4. Teneffus sistemi  (bio-8-teneffus)
    ('bio-8-teneffus', 'bio-8-teneffus-heyvanlarda',
     'Heyvanlarda tənəffüs', 10),
    ('bio-8-teneffus', 'bio-8-teneffus-insanda-sistemi',
     'İnsanda tənəffüs sistemi', 20),
    ('bio-8-teneffus', 'bio-8-teneffus-hereketleri-qazlar',
     'Tənəffüs hərəkətləri və qazlar mübadiləsi', 30),
    ('bio-8-teneffus', 'bio-8-teneffus-elm-texnologiya',
     'Elm, texnologiya, həyat', 40),
    ('bio-8-teneffus', 'bio-8-teneffus-xulase',
     'Xülasə', 50),
    ('bio-8-teneffus', 'bio-8-teneffus-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    --  Bolme 5. Hezm ve qidalanma  (bio-8-hezm)
    ('bio-8-hezm', 'bio-8-hezm-orqanizmde-maddeler',
     'Orqanizmdə maddələr mübadiləsi', 10),
    ('bio-8-hezm', 'bio-8-hezm-sisteminin-qurulusu',
     'Həzm sisteminin quruluşu və funksiyaları', 20),
    ('bio-8-hezm', 'bio-8-hezm-insan-orqanizminde',
     'İnsan orqanizmində həzm prosesi', 30),
    ('bio-8-hezm', 'bio-8-hezm-elm-texnologiya',
     'Elm, texnologiya, həyat', 40),
    ('bio-8-hezm', 'bio-8-hezm-xulase',
     'Xülasə', 50),
    ('bio-8-hezm', 'bio-8-hezm-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    --  Bolme 6. Heyvanlarda ve insanda coxalma  (bio-8-coxalma)
    ('bio-8-coxalma', 'bio-8-coxalma-qeyri-cinsi',
     'Heyvanlarda qeyri-cinsi çoxalma', 10),
    ('bio-8-coxalma', 'bio-8-coxalma-heyvanlarda-cinsi',
     'Heyvanlarda cinsi çoxalma', 20),
    ('bio-8-coxalma', 'bio-8-coxalma-onurgali-heyvanlarin',
     'Onurğalı heyvanların həyat dövriyyəsi', 30),
    ('bio-8-coxalma', 'bio-8-coxalma-cinsiyyet-sistemi',
     'İnsanın cinsiyyət sistemi', 40),
    ('bio-8-coxalma', 'bio-8-coxalma-mayalanma-prosesi',
     'Mayalanma prosesi və bətndaxili inkişaf', 50),
    ('bio-8-coxalma', 'bio-8-coxalma-yas-dovrleri',
     'İnsanın yaş dövrləri', 60),
    ('bio-8-coxalma', 'bio-8-coxalma-elm-texnologiya',
     'Elm, texnologiya, həyat', 70),
    ('bio-8-coxalma', 'bio-8-coxalma-xulase',
     'Xülasə', 80),
    ('bio-8-coxalma', 'bio-8-coxalma-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    --  Bolme 7. Canli alemin tesnifati  (bio-8-tesnifat)
    ('bio-8-tesnifat', 'bio-8-tesnifat-canli-orqanizmlerin',
     'Canlı orqanizmlərin təsnifatı', 10),
    ('bio-8-tesnifat', 'bio-8-tesnifat-heyvanlar-aleminin',
     'Heyvanlar aləminin təsnifatı', 20),
    ('bio-8-tesnifat', 'bio-8-tesnifat-bitkiler-aleminin',
     'Bitkilər aləminin təsnifatı', 30),
    ('bio-8-tesnifat', 'bio-8-tesnifat-elm-texnologiya',
     'Elm, texnologiya, həyat', 40),
    ('bio-8-tesnifat', 'bio-8-tesnifat-xulase',
     'Xülasə', 50),
    ('bio-8-tesnifat', 'bio-8-tesnifat-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    --  Bolme 8. Insan saglamligi ve etraf muhit  (bio-8-saglamliq)
    ('bio-8-saglamliq', 'bio-8-saglamliq-orqanizmin-qoruyucu',
     'Orqanizmin qoruyucu sistemi', 10),
    ('bio-8-saglamliq', 'bio-8-saglamliq-qidalanma',
     'Sağlam qidalanma', 20),
    ('bio-8-saglamliq', 'bio-8-saglamliq-saglamliga-tesir',
     'Sağlamlığa təsir edən amillər', 30),
    ('bio-8-saglamliq', 'bio-8-saglamliq-insan-fealiyyetinin',
     'İnsan fəaliyyətinin karbon və azot dövriyyəsinə təsiri', 40),
    ('bio-8-saglamliq', 'bio-8-saglamliq-elm-texnologiya',
     'Elm, texnologiya, həyat', 50),
    ('bio-8-saglamliq', 'bio-8-saglamliq-xulase',
     'Xülasə', 60),
    ('bio-8-saglamliq', 'bio-8-saglamliq-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    --  ============  10-cu sinif  ============
    --  I. Biosferde istehsal ve istehlak  (bio-10-heyat-prosesleri)
    ('bio-10-heyat-prosesleri', 'bio-10-heyat-prosesleri-canlilarda-qidalanma',
     'Canlılarda qidalanma', 10),
    ('bio-10-heyat-prosesleri', 'bio-10-heyat-prosesleri-canlilarda-teneffus',
     'Canlılarda tənəffüs', 20),
    ('bio-10-heyat-prosesleri', 'bio-10-heyat-prosesleri-canlilarda-ifrazat',
     'Canlılarda ifrazat', 30),
    ('bio-10-heyat-prosesleri', 'bio-10-heyat-prosesleri-canlilarda-coxalma',
     'Canlılarda çoxalma', 40),
    ('bio-10-heyat-prosesleri', 'bio-10-heyat-prosesleri-canlilarda-qiciqlanma',
     'Canlılarda qıcıqlanma', 50),
    --  I. Biosferde istehsal ve istehlak  (bio-10-istehsal)
    ('bio-10-istehsal', 'bio-10-istehsal-uzvi-madde',
     'Üzvi maddə istehsalçıları', 10),
    ('bio-10-istehsal', 'bio-10-istehsal-zulal-biosintezinin',
     'Zülal biosintezinin mexanizmi', 20),
    ('bio-10-istehsal', 'bio-10-istehsal-huceyrenin-enerji',
     'Hüceyrənin enerji mənbəyi - ATF', 30),
    ('bio-10-istehsal', 'bio-10-istehsal-energetik-mubadilenin',
     'Energetik mübadilənin mexanizmi', 40),
    ('bio-10-istehsal', 'bio-10-istehsal-fotosintezin-mexanizmi',
     'Fotosintezin mexanizmi', 50),
    ('bio-10-istehsal', 'bio-10-istehsal-xemosintez',
     'Xemosintez', 60),
    --  II. Canlilarda bas veren deyiskenlikler  (bio-10-deyiskenlik)
    ('bio-10-deyiskenlik', 'bio-10-deyiskenlik-canlilarda-bas',
     'Canlılarda baş verən mövsüm dəyişkənlikləri. Fotoperiodizm', 10),
    ('bio-10-deyiskenlik', 'bio-10-deyiskenlik-modifikasiya-deyiskenliyi',
     'Modifikasiya dəyişkənliyi', 20),
    ('bio-10-deyiskenlik', 'bio-10-deyiskenlik-mutasiya-irsi',
     'Mutasiya irsi dəyişkənlikdir', 30),
    ('bio-10-deyiskenlik', 'bio-10-deyiskenlik-kombinativ-korelyativ',
     'Kombinativ və korelyativ dəyişkənlik', 40),
    --  II. Canlilarda bas veren deyiskenlikler  (bio-10-saglam-heyat)
    ('bio-10-saglam-heyat', 'bio-10-saglam-heyat-maddeler-mubadilesi',
     'Maddələr mübadiləsi', 10),
    ('bio-10-saglam-heyat', 'bio-10-saglam-heyat-mubadilesine-amiller',
     'Maddələr mübadiləsinə təsir edən amillər', 20),
    ('bio-10-saglam-heyat', 'bio-10-saglam-heyat-mubadilesinde-bas',
     'Maddələr mübadiləsində baş verən dəyişikliklər', 30),
    ('bio-10-saglam-heyat', 'bio-10-saglam-heyat-canlilara-abiotik',
     'Canlılara təsir edən abiotik amillər', 40),
    ('bio-10-saglam-heyat', 'bio-10-saglam-heyat-ali-sinir',
     'Ali sinir fəaliyyətinin pozulması və onun qarşısının alınması', 50),
    ('bio-10-saglam-heyat', 'bio-10-saglam-heyat-hereket',
     'Hərəkət sağlamlıqdır', 60),
    ('bio-10-saglam-heyat', 'bio-10-saglam-heyat-duzgun-istirahet',
     'Düzgün istirahət', 70),
    --  II. Canlilarda bas veren deyiskenlikler  (bio-10-epidemiologiya)
    ('bio-10-epidemiologiya', 'bio-10-epidemiologiya-epidemioloji-usullar',
     'Epidemiologiya və epidemioloji üsullar', 10),
    ('bio-10-epidemiologiya', 'bio-10-epidemiologiya-infeksiya-menbeleri',
     'İnfeksiya mənbələri və yoluxma mexanizmi', 20),
    ('bio-10-epidemiologiya', 'bio-10-epidemiologiya-virus-xestelikleri',
     'Virus xəstəlikləri', 30),
    ('bio-10-epidemiologiya', 'bio-10-epidemiologiya-bakterial-xestelikler',
     'Bakterial xəstəliklər', 40),
    ('bio-10-epidemiologiya', 'bio-10-epidemiologiya-gobeleklerin-xestelikler',
     'Göbələklərin törətdiyi xəstəliklər', 50),
    ('bio-10-epidemiologiya', 'bio-10-epidemiologiya-birhuceyreli-ibtidai',
     'Birhüceyrəli (ibtidai) heyvanların törətdiyi xəstəliklər', 60),
    ('bio-10-epidemiologiya', 'bio-10-epidemiologiya-parazit-qurdlarla',
     'Parazit qurdlarla yoluxma', 70),
    ('bio-10-epidemiologiya', 'bio-10-epidemiologiya-bugumayaqlilar-yaydigi',
     'Buğumayaqlıların törətdiyi və yaydığı xəstəliklər', 80),
    ('bio-10-epidemiologiya', 'bio-10-epidemiologiya-yoluxucu-xesteliklere',
     'Yoluxucu xəstəliklərə qarşı mübarizə', 90),
    --  III. Uzvi alemin tekamulu  (bio-10-tekamul)
    ('bio-10-tekamul', 'bio-10-tekamul-makrotekamulu-deliller',
     'Makrotəkamülü isbat edən paleontoloji dəlillər', 10),
    ('bio-10-tekamul', 'bio-10-tekamul-makrotekamulu-isbat-eden',
     'Makrotəkamülü isbat edən embrioloji dəlillər', 20),
    ('bio-10-tekamul', 'bio-10-tekamul-makrotekamul-delilleri',
     'Makrotəkamül - müqayisəli anatomiya dəlilləri', 30),
    ('bio-10-tekamul', 'bio-10-tekamul-muasir-sistematika',
     'Müasir sistematika və təkamül', 40),
    ('bio-10-tekamul', 'bio-10-tekamul-istiqametleri-yollari',
     'Təkamülün istiqamətləri və yolları', 50),
    ('bio-10-tekamul', 'bio-10-tekamul-yer-uzerinde',
     'Yer üzərində canlıların inkişaf tarixi', 60),
    ('bio-10-tekamul', 'bio-10-tekamul-insanin',
     'İnsanın təkamülü', 70),
    ('bio-10-tekamul', 'bio-10-tekamul-insan-delilleri',
     'İnsan təkamülü. Embrioloji və müqayisəli anatomiya dəlilləri', 80),
    ('bio-10-tekamul', 'bio-10-tekamul-insan-deliller',
     'İnsan təkamülü. Paleontoloji dəlillər', 90),
    ('bio-10-tekamul', 'bio-10-tekamul-qedim-insanlar',
     'Ən qədim insanlar', 100),
    ('bio-10-tekamul', 'bio-10-tekamul-ilk-insanlar',
     'Qədim və ilk müasir insanlar', 110),
    --  IV. Genetika  (bio-10-genetika)
    ('bio-10-genetika', 'bio-10-genetika-deyiskenlik-haqqinda',
     'Genetika irsiyyət və dəyişkənlik haqqında elmdir. Monohibrid çarpazlaşma', 10),
    ('bio-10-genetika', 'bio-10-genetika-dihibrid-polihibrid',
     'Dihibrid və polihibrid çarpazlaşma', 20),
    ('bio-10-genetika', 'bio-10-genetika-ilisikli-irsiyyet',
     'İlişikli irsiyyət', 30),
    ('bio-10-genetika', 'bio-10-genetika-cinsiyyetin',
     'Cinsiyyətin genetikası', 40),
    ('bio-10-genetika', 'bio-10-genetika-insan-tibb',
     'İnsan genetikası və tibb elmi', 50),
    ('bio-10-genetika', 'bio-10-genetika-genotip-tam',
     'Genotip tam bir sistem kimi', 60),
    ('bio-10-genetika', 'bio-10-genetika-tekamul-nezeriyyesi',
     'Genetika və təkamül nəzəriyyəsi', 70),
    --  V. Etraf muhitin qorunmasi ve berpasi  (bio-10-ekologiya)
    ('bio-10-ekologiya', 'bio-10-ekologiya-orqanizmlerin-qarsiliqli',
     'Orqanizmlərin qarşılıqlı təsiri', 10),
    ('bio-10-ekologiya', 'bio-10-ekologiya-biomuxteliflik-qorunmasi',
     'Biomüxtəliflik və onun qorunması yolları', 20),
    ('bio-10-ekologiya', 'bio-10-ekologiya-qida-zenciri',
     'Qida zənciri və ekoloji piramida', 30),
    ('bio-10-ekologiya', 'bio-10-ekologiya-havanin-cirklenmesi',
     'Havanın çirklənməsi qlobal ekoloji problem kimi', 40),
    ('bio-10-ekologiya', 'bio-10-ekologiya-maddeler-dovrani',
     'Maddələr dövranı', 50),
    --  ============  11-ci sinif  ============
    --  I. Heyatin yaranmasi  (bio-11-heyatin-yaranmasi)
    ('bio-11-heyatin-yaranmasi', 'bio-11-heyatin-yaranmasi-yer-planetinin',
     'Yer planetinin yaranması. Həyat anlayışı', 10),
    ('bio-11-heyatin-yaranmasi', 'bio-11-heyatin-yaranmasi-haqqinda-ferziyyeler',
     'Həyatın yaranması haqqında fərziyyələr', 20),
    ('bio-11-heyatin-yaranmasi', 'bio-11-heyatin-yaranmasi-tesevvurlerin-inkisafi',
     'Həyatın yaranması haqqında təsəvvürlərin inkişafı', 30),
    ('bio-11-heyatin-yaranmasi', 'bio-11-heyatin-yaranmasi-emele-gelmesi',
     'Həyatın əmələ gəlməsi haqqında müasir təsəvvürlər', 40),
    ('bio-11-heyatin-yaranmasi', 'bio-11-heyatin-yaranmasi-bioloji-monomer',
     'Bioloji monomer və polimerlərin yaranması', 50),
    ('bio-11-heyatin-yaranmasi', 'bio-11-heyatin-yaranmasi-coxhuceyrelili-dogru',
     'Çoxhüceyrəliliyə doğru yol', 60),
    ('bio-11-heyatin-yaranmasi', 'bio-11-heyatin-yaranmasi-tebii-secmenin',
     'Təbii seçmənin formaları', 70),
    ('bio-11-heyatin-yaranmasi', 'bio-11-heyatin-yaranmasi-orqanizmlerde-uygunlasmalar',
     'Orqanizmlərdə uyğunlaşmalar', 80),
    --  II. Mikrobiologiya  (bio-11-bakteriyalar)
    ('bio-11-bakteriyalar', 'bio-11-bakteriyalar-mikroorqanizml',
     'Mikroorqanizmlər', 10),
    ('bio-11-bakteriyalar', 'bio-11-bakteriyalar-mikrobiologiya-sobeleri',
     'Mikrobiologiyanın şöbələri', 20),
    ('bio-11-bakteriyalar', 'bio-11-bakteriyalar-etraf-torpagin',
     'Mikroorqanizmlər və ətraf mühit. Torpağın mikroflorası', 30),
    ('bio-11-bakteriyalar', 'bio-11-bakteriyalar-suyun-mikroflorasi',
     'Suyun mikroflorası', 40),
    ('bio-11-bakteriyalar', 'bio-11-bakteriyalar-atmosfer-havasinin',
     'Atmosfer havasının mikroflorası', 50),
    ('bio-11-bakteriyalar', 'bio-11-bakteriyalar-qida-mehsullarinin',
     'Qida məhsullarının mikroflorası', 60),
    ('bio-11-bakteriyalar', 'bio-11-bakteriyalar-gedisinde-rolu',
     'İnfeksion proseslərin gedişində mikroorqanizmlərin rolu', 70),
    ('bio-11-bakteriyalar', 'bio-11-bakteriyalar-bas-vermesinde',
     'İnfeksion proseslərin baş verməsində sahib orqanizmin rolu', 80),
    ('bio-11-bakteriyalar', 'bio-11-bakteriyalar-seraitinin-xesteliklerin',
     'Mühit şəraitinin infeksion xəstəliklərin gedişinə təsiri', 90),
    --  III. Seleksiya  (bio-11-seleksiya)
    ('bio-11-seleksiya', 'bio-11-seleksiya-vezifeleri',
     'Seleksiyanın vəzifələri', 10),
    ('bio-11-seleksiya', 'bio-11-seleksiya-suni-secme',
     'Süni seçmə', 20),
    ('bio-11-seleksiya', 'bio-11-seleksiya-medeni-bitkilerin',
     'Mədəni bitkilərin mənşə mərkəzləri', 30),
    ('bio-11-seleksiya', 'bio-11-seleksiya-metodlari',
     'Seleksiyanın metodları', 40),
    ('bio-11-seleksiya', 'bio-11-seleksiya-dominantligin-idare',
     'Dominantlığın idarə edilməsi. Seleksiyanın digər nailiyyətləri', 50),
    --  IV. Biotexnologiya ve bionika  (bio-11-biotexnologiya)
    ('bio-11-biotexnologiya', 'bio-11-biotexnologiya-biologiyanin-inkisafi',
     'Biologiyanın inkişafı', 10),
    ('bio-11-biotexnologiya', 'bio-11-biotexnologiya-biologiya-texnika',
     'Biologiya və texnika', 20),
    ('bio-11-biotexnologiya', 'bio-11-biotexnologiya-mikroorqanizml-seleksiyasi',
     'Mikroorqanizmlərin seleksiyası. Biotexnologiya', 30),
    ('bio-11-biotexnologiya', 'bio-11-biotexnologiya-bitkicilik-heyvandarliqda',
     'Bitkiçilik və heyvandarlıqda istifadə olunan müasir metodlar', 40),
    ('bio-11-biotexnologiya', 'bio-11-biotexnologiya-canlilarda-klonlasdirma',
     'Canlılarda klonlaşdırma', 50),
    ('bio-11-biotexnologiya', 'bio-11-biotexnologiya-heyatimizda',
     'Biotexnologiya həyatımızda', 60),
    ('bio-11-biotexnologiya', 'bio-11-biotexnologiya-bionika',
     'Bionika', 70),
    --  V. Biosfer  (bio-11-biosfer)
    ('bio-11-biosfer', 'bio-11-biosfer-serhedleri-orada',
     'Biosferin sərhədləri və orada baş verən dəyişikliklərin qlobal xarakteri', 10),
    ('bio-11-biosfer', 'bio-11-biosfer-canli-madde',
     'Biosferdə canlı maddə', 20),
    ('bio-11-biosfer', 'bio-11-biosfer-enerji-cevrilmeleri',
     'Biosferdə enerji çevrilmələri', 30),
    ('bio-11-biosfer', 'bio-11-biosfer-quru-okean',
     'Quru və okean sahəsinin biokütləsi', 40),
    ('bio-11-biosfer', 'bio-11-biosfer-insan',
     'İnsan və biosfer', 50),
    ('bio-11-biosfer', 'bio-11-biosfer-ekoloji-problemler',
     'Qlobal ekoloji problemlər', 60),
    --  VI. Xordalilarin ali numayendesi - insan. Onun inkisafi ve muhit  (bio-11-insan-muhit)
    ('bio-11-insan-muhit', 'bio-11-insan-muhit-xordalilarin-inkisafi',
     'Xordalıların embrional inkişafı', 10),
    ('bio-11-insan-muhit', 'bio-11-insan-muhit-embrional-inkisafi',
     'İnsanın embrional inkişafı', 20),
    ('bio-11-insan-muhit', 'bio-11-insan-muhit-psixikasinin-inkisaf',
     'İnsan psixikasının inkişaf xüsusiyyətləri', 30),
    ('bio-11-insan-muhit', 'bio-11-insan-muhit-tesvis-pozuntulari',
     'Təşviş pozuntuları', 40),
    ('bio-11-insan-muhit', 'bio-11-insan-muhit-depressiyalar',
     'Depressiyalar', 50),
    ('bio-11-insan-muhit', 'bio-11-insan-muhit-psixozlar',
     'Psixozlar', 60),
    ('bio-11-insan-muhit', 'bio-11-insan-muhit-ailede-munasibetler',
     'Ailədə sağlam münasibətlər', 70),
    ('bio-11-insan-muhit', 'bio-11-insan-muhit-heyat-terzi',
     'Sağlam həyat tərzi - sağlam ailə', 80),
    --  VII. Huceyrenin nezaretli ve nezaretsiz bolunmesi  (bio-11-bolunme-nezaret)
    ('bio-11-bolunme-nezaret', 'bio-11-bolunme-nezaret-prosesinde-bitki',
     'Mitoz prosesində bitki və heyvan hüceyrəsində sitoplazmanın bölünməsi', 10),
    ('bio-11-bolunme-nezaret', 'bio-11-bolunme-nezaret-hezm-prosesinin',
     'Həzm prosesinin gedişində müxtəliflik', 20),
    ('bio-11-bolunme-nezaret', 'bio-11-bolunme-nezaret-huceyrenin-sisler',
     'Hüceyrənin nəzarətsiz bölünməsi. Şişlər', 30),
    ('bio-11-bolunme-nezaret', 'bio-11-bolunme-nezaret-xerceng',
     'Xərçəng', 40),
    ('bio-11-bolunme-nezaret', 'bio-11-bolunme-nezaret-meyoz-oxsar',
     'Mitoz və meyoz bölünmələrin oxşar və fərqli cəhətləri', 50)
  ) as v(parent_slug, slug, name, sort)
  join public.topics p on p.slug = v.parent_slug
   and p.subject_id = (select id from public.subjects where slug = 'biologiya')
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort,
      parent_id = excluded.parent_id, level_id = excluded.level_id;

do $$
declare k int;
begin
  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'biologiya'
    join public.levels   l on l.id = p.level_id and l.code = '6';
  if k <> 62 then
    raise exception 'biologiya 6-ci alt movzulari: 62 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'biologiya'
    join public.levels   l on l.id = p.level_id and l.code = '7';
  if k <> 59 then
    raise exception 'biologiya 7-ci alt movzulari: 59 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'biologiya'
    join public.levels   l on l.id = p.level_id and l.code = '8';
  if k <> 55 then
    raise exception 'biologiya 8-ci alt movzulari: 55 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'biologiya'
    join public.levels   l on l.id = p.level_id and l.code = '10';
  if k <> 54 then
    raise exception 'biologiya 10-cu alt movzulari: 54 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'biologiya'
    join public.levels   l on l.id = p.level_id and l.code = '11';
  if k <> 48 then
    raise exception 'biologiya 11-ci alt movzulari: 48 gozlenilirdi, % tapildi', k;
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
    join public.subjects s on s.id = t.subject_id and s.slug = 'biologiya'
    join public.levels   l on l.id = t.level_id
   where t.parent_id is null and true;
  if k <> 47 then
    raise exception 'Biologiya ust movzu sayi 47 deyil: %', k;
  end if;

  raise notice 'Biologiya 6-11 (9-cu sinif menbesi bos): 278 alt movzu hazir.';
end $$;
