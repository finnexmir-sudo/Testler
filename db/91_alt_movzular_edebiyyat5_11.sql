-- =====================================================================
--  91_alt_movzular_edebiyyat5_11.sql : EDEBIYYAT 5-11 - ALT MOVZULAR
--
--  NIYE
--  Onuncu fenn.  Riyaziyyat, heyat bilgisi, informatika, fizika,
--  kimya, biologiya, ingilis dili, cografiya hazirdir.
--
--  MENBE: e-derslik.edu.az "Movzular" agaci - kitab id 845 (5),
--  911 (6), 701 (7), 793 (8), 883 (9), 732 (10), 821 (11).  Adlar
--  EYNILE goturulub.
--
--  DERSLIYIN QURULUSU HER SINIFDE FERQLIDIR - movzu adlari 5-7-de
--  TEMA (Yurd sevgisi, Tebietin gozelliyi), 8-11-de DOVR uzredir
--  (bu, derslikdeki bolgu - suni deyil).
--
--  5-7-ci sinif: "Giris"/"Edebiyyat" basliqli ilk bolme (dersliklo
--  nece isleməli - meznun deyil) ve son bolme ("Insani nece yazmali"
--  / "Insa ve esseni nece yazmali") - hər ikisi BURAXILIR (None).
--  Qalan bolmeler bire-bir movzuya.  5-ci sinifde son (7-ci) movzunun
--  bendleri arasina kitabin sonundaki aparat (Layihələr, Luget ve s.)
--  qarisib - xaric edilib; 6 ve 7-ci sinifde bu aparat dusen bolmenin
--  daxilindedir, ayrica xaric lazim gelmir.
--
--  8-ci sinif: ilk ve son bolme (Dərsliklə/İnformasiya xarakterli)
--  buraxilir.  Qalan 6 bolmeden 5-i bire-bir, "TƏNQİDİ REALİZM VƏ
--  ROMANTİZM DÖVRÜ" bolmesi ise İKİ movzuya bolunur - muellif adlari
--  ozu sinir cekir: Memmedquluzade+Sabir (tenqidi realizm) sehife
--  123-e qeder, Hadi+Cavid (romantizm, dunya edebiyyatindan Ersoy
--  daxil) sonrasi.
--
--  9-cu sinif: dersliyde 4 boyuk boluk var, ICINDE nomrelenmis
--  "merhele"lerlə (I-III) daha da bolunur.  "II merhele"nin ICINDƏ
--  3 alt-dovr var (repressiya 1920-40, muharibe 1941-60, ozunuderk
--  1961-90) - ve ozunuderk ozu bazada İKİ movzuya (poeziya/nesr)
--  ayrilib.  Muellifleri janrina gore taniyiriq (R.Rza, Kurcayli,
--  Araz, Azeroglu, Eli Kerim, Rustemxanli = seir; Sixli, Huseynov,
--  Anar, Elcin = nesr) - sehife sirasi bunlari NOVBELESDIRIR (aydin
--  bir kesim yoxdur), ona gore COX SERHEDLI (list) spec ile hər
--  muellifin oz sehifesi ayri-ayri qeyd olunub (biologiya-11-in
--  Mikrobiologiya teleside olan kimi tesadufi bolunme YOXDUR - bu,
--  hər addimda meydana cixan real sehife serhedidir).
--  "III merhele" de eyni qelible 3 movzuya bolunur (mustaqillik/
--  cenub/dunya) - "CƏNUBİ AZƏRBAYCAN ƏDƏBİYYATI" ve "DÜNYA
--  ƏDƏBİYYATI" basliqlari sehife serhedine gore duz movzuya dusur;
--  xaric edilmir, cunki EYNI metn 11-ci sinifde HƏQIQI bolmə
--  basligidir (xaric etsək 11-ci sinifin bolmesi yox olardi - bir
--  defe belə oldu, tapilib duzeldildi).
--
--  10-cu sinif: derslikde CEMI BIR bolme var ("bölmə: 1") - butun
--  kitab boyu 6 boyuk dovr basligi (AZƏRBAYCAN ŞİFAHİ.../QƏDİM
--  DOVR.../İNTİBAH.../ORTA ƏSRLƏR.../ERKƏN YENİ DOVR.../MAARİFÇİ-
--  REALİZM...) novbeti bendlə EYNI sehifede DEYIL (basliq-teleside
--  olan "eyni sehife" qaydasi bunu tutmur).  Bu basliqlar 8-ci
--  sinifin bezi bolme adlari ilə HƏRFİ EYNIDIR (herfi xaric etmek
--  8-ci sinifin real bolmelerini de silerdi - bir defe belə oldu,
--  tapilib duzeldildi) - ona gore xaric edilmir, sadece butun kitab
--  TEK bir COX SERHEDLI (list) spec ile 8 movzuya bolunur; basliqlar
--  ozleri hər movzunun ilk (bir az artiq) bendi kimi qalir.
--  "ORTA ƏSRLƏR" Nesimi+Xetayi / Fuzuli-ye,
--  "MAARİFÇİ-REALİZM" ise Zakir+Elesger+Sirvani+Vezirov / Axundzade-
--  ye bolunur - Axundzadenin bendleri (sehife 125-153) Zakirlə
--  Elesger arasinda YERLESIB (üç seqmentli list: Zakir <125,
--  Axundzade 125-153, qalanlari >=154 - iki qonsu seqment eyni
--  movzuya (maarifci) gedir).
--
--  11-ci sinif: derslikde 6 bolme, bazada 8 movzu.  "TƏNQİDİ REALİZM
--  VƏ ROMANTİZM DÖVRÜ" bolmesi 8-ci sinifdəki eyni prinsiple bolunur
--  (Memmedquluzade+Sabir / Cavid+Ehmed Cavad, sehife 37-den).
--  "CƏNUBİ AZƏRBAYCAN ƏDƏBİYYATI" (Şəhriyar) ve son bolme "DÜNYA
--  ƏDƏBİYYATINDAN SEÇMƏ" (Aytmatov) EYNI movzuya (cenub-dunya) gedir
--  - iki bolme arasinda basqa heç bir elaqe yoxdur, sadece hər ikisi
--  movzu adinin ("Cənubi Azərbaycan və dünya ədəbiyyatı") iki yarisidir.
--  "SOVET DÖVRÜ..." bolmesi Cabbarli+Vurgun / R.Rza+Mir Celala bolunur
--  (sehife 108-den).  edeb-11-nezeriyye (Edebi cereyanlar ve
--  nezeriyye) ucun mundericatda HEC bir isare yoxdur - biologiya-11-
--  viruslar ile eyni qerar: uydurma sehife qoyulmadi, 0 alt movzu
--  qalir.
--
--  YAZI QUSURLARI: bir necə muellif adinda bosluq/herf sehvi
--  (CəfərCabbarlı -> Cəfər Cabbarlı, SViktor Hüqo -> Viktor Hüqo,
--  İlsmayıl -> İsmayıl, İldınm -> İldırım) ve tirnaqdan sonra
--  bosluq (dastanında/poemasından bitisik yazilib) - mezmun
--  deyismeden duzeldilib.
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
--   * yazi (8): yazi qusuru (bosluq, herf)
--       6-ci   s.42   SViktor Huqo. KOZETTA
--                    -> Viktor Huqo. KOZETTA
--       8-ci   s.12   Qazan beyin oglu Uruz beyin dustaq oldugu boy ("Kitabi-Dede Qorqud"dastaninda)
--                    -> Qazan beyin oglu Uruz beyin dustaq oldugu boy ("Kitabi-Dede Qorqud" dastaninda)
--       8-ci   s.31   Nizami Gencevi. Sultan Sencer ve qari ("Sirler xezinesi"poemasindan)
--                    -> Nizami Gencevi. Sultan Sencer ve qari ("Sirler xezinesi" poemasindan)
--       8-ci   s.44   Sah Ilsmayil Xetayi. Bahariyye("Dehname"poemasindan)
--                    -> Sah Ismayil Xetayi. Bahariyye ("Dehname" poemasindan)
--       9-cu   s.15   CeferCabbarli. Ana
--                    -> Cefer Cabbarli. Ana
--       9-cu   s.33   Almas Ildinm. Esir Azerbaycanim
--                    -> Almas Ildirim. Esir Azerbaycanim
--       9-cu   s.104  Eli Kerim .Qaytar ana borcunu
--                    -> Eli Kerim. Qaytar ana borcunu
--       9-cu   s.181  Hebib Sahir.Sehend dagi (qiymetlendirme materiali)
--                    -> Hebib Sahir. Sehend dagi (qiymetlendirme materiali)

insert into public.topics (subject_id, level_id, parent_id, slug, name, sort)
select p.subject_id, p.level_id, p.id, v.slug, v.name, v.sort
  from (values
    --  ============  5-ci sinif  ============
    --  1. SIFAHI XALQ EDEBIYYATI INCILERI  (edeb-5-sifahi)
    ('edeb-5-sifahi', 'edeb-5-sifahi-ana-maral',
     'Ana maral (əfsanə)', 10),
    ('edeb-5-sifahi', 'edeb-5-sifahi-xalq-vetenini',
     'Xalq öz vətənini necə tapdı (Şimali Amerika əfsanəsi)', 20),
    ('edeb-5-sifahi', 'edeb-5-sifahi-yetim-ibrahimin',
     'Yetim İbrahimin nağılı', 30),
    ('edeb-5-sifahi', 'edeb-5-sifahi-qardas-ozbek',
     'Üç qardaş (özbək nağılı)', 40),
    --  2. YURD SEVGISI, ANA MEHEBBETI  (edeb-5-yurd)
    ('edeb-5-yurd', 'edeb-5-yurd-ehmed-cavad',
     'Əhməd Cavad. Azərbaycan! Azərbaycan!', 10),
    ('edeb-5-yurd', 'edeb-5-yurd-eli-tude',
     'Əli Tudə. Yaşayanlar görəcəkdir', 20),
    ('edeb-5-yurd', 'edeb-5-yurd-huseyn-arif',
     'Hüseyn Arif. Analar', 30),
    --  3. MENEVI DEYERLER, HEMISEYASAR HIKMETLER  (edeb-5-menevi)
    ('edeb-5-menevi', 'edeb-5-menevi-enver-elibeyli',
     'Ənvər Əlibəyli. İlan və Qurbağa', 10),
    ('edeb-5-menevi', 'edeb-5-menevi-cek-london',
     'Cek London. Kiş haqqında hekayət', 20),
    --  4. MUHARIBE VE INSAN HAQQI  (edeb-5-muharibe)
    ('edeb-5-muharibe', 'edeb-5-muharibe-xelil-rza',
     'Xəlil Rza Ulutürk. Oğul həsrəti', 10),
    ('edeb-5-muharibe', 'edeb-5-muharibe-maqsud-ibrahimbeyov',
     'Maqsud İbrahimbəyov. Püstə ağacı', 20),
    ('edeb-5-muharibe', 'edeb-5-muharibe-elcin-huseynbeyli',
     'Elçin Hüseynbəyli. Firuzə qaşlı xəncər', 30),
    --  5. USAQ DUNYASI, USAQ TALEYI  (edeb-5-usaq)
    ('edeb-5-usaq', 'edeb-5-usaq-ehmed-cemil',
     'Əhməd Cəmil. Can nənə, bir nağıl de', 10),
    ('edeb-5-usaq', 'edeb-5-usaq-mark-tven',
     'Mark Tven. Fərasətli oğlan', 20),
    --  6. EMEYE MEHEBBET, ZEHMETE CAGIRIS  (edeb-5-emek)
    ('edeb-5-emek', 'edeb-5-emek-nizami-gencevi',
     'Nizami Gəncəvi. Kərpickəsən kişinin dastanı', 10),
    ('edeb-5-emek', 'edeb-5-emek-suleyman-rehimov',
     'Süleyman Rəhimov. Qara torpaq və sarı qızıl', 20),
    --  7. TEBIETIN GOZELLIYI, TEBIETE QAYGI  (edeb-5-tebiet)
    ('edeb-5-tebiet', 'edeb-5-tebiet-abdulla-saiq',
     'Abdulla Şaiq. Köç', 10),
    ('edeb-5-tebiet', 'edeb-5-tebiet-semed-vurgun',
     'Səməd Vurğun. Çinarın şikayəti', 20),
    ('edeb-5-tebiet', 'edeb-5-tebiet-fikret-qoca',
     'Fikrət Qoca. Şuşa', 30),
    --  ============  6-ci sinif  ============
    --  1. SIFAHI XALQ EDEBIYYATINDAN NUMUNELER  (edeb-6-sifahi)
    ('edeb-6-sifahi', 'edeb-6-sifahi-hesreti',
     'Su həsrəti', 10),
    ('edeb-6-sifahi', 'edeb-6-sifahi-qanli-das',
     'Qanlı daş', 20),
    ('edeb-6-sifahi', 'edeb-6-sifahi-ilyas',
     'İlyas', 30),
    ('edeb-6-sifahi', 'edeb-6-sifahi-ali-kisi',
     'Alı kişi (“Koroğlu” dastanından)', 40),
    --  2. USAQ DUSUNCESI, USAQ DUNYASI  (edeb-6-usaq)
    ('edeb-6-usaq', 'edeb-6-usaq-viktor-huqo',
     'Viktor Hüqo. KOZETTA', 10),
    ('edeb-6-usaq', 'edeb-6-usaq-naibe-yusif',
     'Naibə Yusif. DƏRS', 20),
    ('edeb-6-usaq', 'edeb-6-usaq-zahid-xelil',
     'Zahid Xəlil. DOSTLAR', 30),
    --  3. YURD SEVGISI, QEHREMANLIQ SEHIFELERI  (edeb-6-yurd)
    ('edeb-6-yurd', 'edeb-6-yurd-suleyman-abdulla',
     'Süleyman Abdulla. AZƏRBAYCAN BAYRAĞI', 10),
    ('edeb-6-yurd', 'edeb-6-yurd-memmed-ismayil',
     'Məmməd İsmayıl. VƏTƏN SEÇİLMƏZ', 20),
    ('edeb-6-yurd', 'edeb-6-yurd-nebi-xezri',
     'Nəbi Xəzri. İSTİQLAL MARŞI', 30),
    ('edeb-6-yurd', 'edeb-6-yurd-mikayil-rzaquluzade',
     'Mikayıl Rzaquluzadə. AND', 40),
    ('edeb-6-yurd', 'edeb-6-yurd-eyvaz-zeynalli',
     'Eyvaz Zeynallı. TƏNHA NAR AĞACI', 50),
    --  4. MENEVI DEYERLER, YASAYAN HIKMETLER  (edeb-6-menevi)
    ('edeb-6-menevi', 'edeb-6-menevi-abbasqulu-aga',
     'Abbasqulu ağa Bakıxanov. QURD VƏ İLBİZ', 10),
    ('edeb-6-menevi', 'edeb-6-menevi-seyid-ezim',
     'Seyid Əzim Şirvani. QAZ VƏ DURNA', 20),
    ('edeb-6-menevi', 'edeb-6-menevi-xelil-rza',
     'Xəlil Rza Ulutürk. LAYLAM MƏNİM, NƏRƏM MƏNİM', 30),
    ('edeb-6-menevi', 'edeb-6-menevi-mahire-nagiqizi',
     'Mahirə Nağıqızı. ANA DİLİM', 40),
    ('edeb-6-menevi', 'edeb-6-menevi-semed-behrengi',
     'Səməd Behrəngi. BALACA QARA BALIQ', 50),
    --  5. TEBIETIN GOZELLIYI, TEBIETE QAYGI  (edeb-6-tebiet)
    ('edeb-6-tebiet', 'edeb-6-tebiet-elcin-huseynbeyli',
     'Elçin Hüseynbəyli. QƏSD EDİLMİŞ GÖZƏLLİK', 10),
    ('edeb-6-tebiet', 'edeb-6-tebiet-ramiz-qusarcayli',
     'Ramiz Qusarçaylı. PAYIZ', 20),
    ('edeb-6-tebiet', 'edeb-6-tebiet-rahil-memmed',
     'Rahil Məmməd. İLİN QIZIL FƏSLİ', 30),
    ('edeb-6-tebiet', 'edeb-6-tebiet-bayram-hesenov',
     'Bayram Həsənov. BULAQ BAŞINDA', 40),
    --  ============  7-ci sinif  ============
    --  SIFAHI XALQ EDEBIYYATINDAN SECMELER  (edeb-7-sifahi)
    ('edeb-7-sifahi', 'edeb-7-sifahi-derzi-sagirdi',
     'Dərzi şagirdi Əhməd (nağıl)', 10),
    ('edeb-7-sifahi', 'edeb-7-sifahi-durna-teli',
     'Durna teli (“Koroğlu” dastanından)', 20),
    ('edeb-7-sifahi', 'edeb-7-sifahi-xezineqaya-efsanesi',
     'Xəzinəqaya əfsanəsi (tətbiq və ümumiləşdirmə)', 30),
    ('edeb-7-sifahi', 'edeb-7-sifahi-arilarin-qezebi',
     'Arıların qəzəbi (qiymətləndirmə materialı)', 40),
    --  VETEN SEVGISI, QEHREMANLIQ SEHIFELERI  (edeb-7-veten)
    ('edeb-7-veten', 'edeb-7-veten-semed-vurgun',
     'Səməd Vurğun. Azərbaycan', 10),
    ('edeb-7-veten', 'edeb-7-veten-eyvaz-zeynalli',
     'Eyvaz Zeynallı. Kəşfiyyatçılar', 20),
    ('edeb-7-veten', 'edeb-7-veten-mirze-ibrahimov',
     'Mirzə İbrahimov. Azad', 30),
    ('edeb-7-veten', 'edeb-7-veten-rahil-memmed',
     'Rahil Məmməd. Qələbə müjdəsi', 40),
    ('edeb-7-veten', 'edeb-7-veten-zahid-xelil',
     'Zahid Xəlil. Sonuncu güllə (tətbiq və ümumiləşdirmə)', 50),
    ('edeb-7-veten', 'edeb-7-veten-mikayil-rzaquluzade',
     'Mikayıl Rzaquluzadə. Babəkin andı (qiymətləndirmə materialı)', 60),
    --  MENEVI DEYERLER, HEMISEYASAR HIKMETLER  (edeb-7-menevi)
    ('edeb-7-menevi', 'edeb-7-menevi-abbasqulu-aga',
     'Abbasqulu ağa Bakıxanov. Hikmətin fəziləti', 10),
    ('edeb-7-menevi', 'edeb-7-menevi-cingiz-aytmatov',
     'Çingiz Aytmatov. Manqurt (“Gün var əsrə bərabər” əsərindən)', 20),
    ('edeb-7-menevi', 'edeb-7-menevi-hikmet-ziya',
     'Hikmət Ziya. Kərgədan və qarışqa', 30),
    ('edeb-7-menevi', 'edeb-7-menevi-fikret-qoca',
     'Fikrət Qoca. Anamın sözləri (tətbiq və ümumiləşdirmə)', 40),
    ('edeb-7-menevi', 'edeb-7-menevi-abdulla-saiq',
     'Abdulla Şaiq. Usta Bəxtiyar (qiymətləndirmə materialı)', 50),
    --  USAQ ALEMI, USAQ TALEYI  (edeb-7-usaq)
    ('edeb-7-usaq', 'edeb-7-usaq-suleyman-sani',
     'Süleyman Sani Axundov. Nurəddin', 10),
    ('edeb-7-usaq', 'edeb-7-usaq-enver-memmedxanli',
     'Ənvər Məmmədxanlı. Qızıl qönçələr', 20),
    ('edeb-7-usaq', 'edeb-7-usaq-elcin-huseynbeyli',
     'Elçin Hüseynbəyli. Nəvə', 30),
    ('edeb-7-usaq', 'edeb-7-usaq-mir-celal',
     'Mir Cəlal. Bahar (tətbiq və ümumiləşdirmə)', 40),
    ('edeb-7-usaq', 'edeb-7-usaq-viktor-huqo',
     'Viktor Hüqo. Qavroş (qiymətləndirmə materialı)', 50),
    --  TEBIETE VURGUNLUQ, TEBIETE QAYGI  (edeb-7-tebiet)
    ('edeb-7-tebiet', 'edeb-7-tebiet-mikayil-musfiq',
     'Mikayıl Müşfiq. Yağış yağarkən', 10),
    ('edeb-7-tebiet', 'edeb-7-tebiet-bayram-hesenov',
     'Bayram Həsənov. İki bala', 20),
    ('edeb-7-tebiet', 'edeb-7-tebiet-eliaga-kurcayli',
     'Əliağa Kürçaylı. Qaranquş', 30),
    ('edeb-7-tebiet', 'edeb-7-tebiet-ilyas-efendiyev',
     'İlyas Əfəndiyev. Şəhərdən gələn ovçu (tətbiq və ümumiləşdirmə)', 40),
    ('edeb-7-tebiet', 'edeb-7-tebiet-huseyn-arif',
     'Hüseyn Arif. Yaşıl işıq (qiymətləndirmə materialı)', 50),
    --  ============  8-ci sinif  ============
    --  QEDIM DOVR AZERBAYCAN EDEBIYYATI  (edeb-8-qedim)
    ('edeb-8-qedim', 'edeb-8-qedim-qazan-beyin',
     'Qazan bəyin oğlu Uruz bəyin dustaq olduğu boy ("Kitabi-Dədə Qorqud" dastanında)', 10),
    --  INTIBAH DOVRU AZERBAYCAN EDEBIYYATI  (edeb-8-intibah)
    ('edeb-8-intibah', 'edeb-8-intibah-xaqani-sirvani',
     'Xaqani Şirvani. Gənclərə nəsihət', 10),
    ('edeb-8-intibah', 'edeb-8-intibah-nizami-gencevi',
     'Nizami Gəncəvi. Sultan Səncər və qarı ("Sirlər xəzinəsi" poemasından)', 20),
    ('edeb-8-intibah', 'edeb-8-intibah-qaziliq-qoca',
     'Qazılıq Qoca oğlu Yeynək boyu (qiymətləndirmə materialı)', 30),
    --  ORTA ESRLER AZERBAYCAN EDEBIYYATI  (edeb-8-orta)
    ('edeb-8-orta', 'edeb-8-orta-imadeddin-nesimi',
     'İmadəddin Nəsimi. Ağrımaz', 10),
    ('edeb-8-orta', 'edeb-8-orta-sah-ismayil',
     'Şah İsmayıl Xətayi. Bahariyyə ("Dəhnamə" poemasından)', 20),
    ('edeb-8-orta', 'edeb-8-orta-mehemmed-fuzuli',
     'Məhəmməd Füzuli. Söz', 30),
    ('edeb-8-orta', 'edeb-8-orta-qurbani-benovseni',
     'Qurbani. Bənövşəni (qiymətləndirmə materialı)', 40),
    --  ERKEN YENI DOVR AZERBAYCAN EDEBIYYATI  (edeb-8-erken)
    ('edeb-8-erken', 'edeb-8-erken-koroglu-bolu',
     'Koroğlu ilə Bolu bəy ("Koroğlu" dastanından)', 10),
    ('edeb-8-erken', 'edeb-8-erken-molla-penah',
     'Molla Pənah Vaqif. Hayıf ki, yoxdur...', 20),
    ('edeb-8-erken', 'edeb-8-erken-saib-tebrizi',
     'Saib Təbrizi. Söz (qiymətləndirmə materialı)', 30),
    --  AZERBAYCAN EDEBIYYATINDA MAARIFCI REALIZM DOVRU  (edeb-8-maarifci)
    ('edeb-8-maarifci', 'edeb-8-maarifci-qasim-bey',
     'Qasım bəy Zakir. Durnalar', 10),
    ('edeb-8-maarifci', 'edeb-8-maarifci-elesger-daglar',
     'Aşıq Ələsgər. Dağlar', 20),
    ('edeb-8-maarifci', 'edeb-8-maarifci-seyid-ezim',
     'Seyid Əzim Şirvani. Qafqaz müsəlmanlarına xitab', 30),
    ('edeb-8-maarifci', 'edeb-8-maarifci-ali-benzersen',
     'Aşıq Alı. Bənzərsən (qiymətləndirmə materialı)', 40),
    --  TENQIDI REALIZM VE ROMANTIZM DOVRU  (edeb-8-tenqidi)
    ('edeb-8-tenqidi', 'edeb-8-tenqidi-celil-memmedquluzade',
     'Cəlil Məmmədquluzadə. Qurbanəli bəy', 10),
    ('edeb-8-tenqidi', 'edeb-8-tenqidi-mirze-elekber',
     'Mirzə Ələkbər Sabir. Əkinçi', 20),
    ('edeb-8-tenqidi', 'edeb-8-tenqidi-ebdurrehim-haqverdiyev',
     'Əbdürrəhim bəy Haqverdiyev. Bomba', 30),
    ('edeb-8-tenqidi', 'edeb-8-tenqidi-abdulla-saiq',
     'Abdulla Şaiq. Məktub yetişmədi (qiymətləndirmə materialı)', 40),
    --  TENQIDI REALIZM VE ROMANTIZM DOVRU  (edeb-8-romantizm)
    ('edeb-8-romantizm', 'edeb-8-romantizm-mehemmed-hadi',
     'Məhəmməd Hadi. Türkün nəğməsi', 10),
    ('edeb-8-romantizm', 'edeb-8-romantizm-huseyn-cavid',
     'Hüseyn Cavid. Ana', 20),
    ('edeb-8-romantizm', 'edeb-8-romantizm-mehmet-akif',
     'Məhmət Akif Ərsoy. İstiqlal marşı (dünya ədəbiyyatından seçmə)', 30),
    ('edeb-8-romantizm', 'edeb-8-romantizm-yusif-vezir',
     'Yusif Vəzir Çəmənzəminli. Zeynal bəy (qiymətləndirmə materialı)', 40),
    --  ============  9-cu sinif  ============
    --  MILLI-DEMOKRATIK HEREKAT, SOVET DONEMI VE DOVLET MUSTEQILLIYI DOVRUNDE AZERBAYCAN EDEBIYYATI  (edeb-9-milli-demokratik)
    ('edeb-9-milli-demokratik', 'edeb-9-milli-demokratik-merhele-azerbaycanda',
     'I mərhələ. AZƏRBAYCANDA MİLLİ-DEMOKRATİK HƏRƏKAT DÖVRÜNDƏ ƏDƏBİYYAT', 10),
    ('edeb-9-milli-demokratik', 'edeb-9-milli-demokratik-ehmed-cavad',
     'Əhməd Cavad. Azərbaycan bayrağına', 20),
    ('edeb-9-milli-demokratik', 'edeb-9-milli-demokratik-cefer-cabbarli',
     'Cəfər Cabbarlı. Ana', 30),
    --  II merhele. SOVET DOVRU AZERBAYCAN EDEBIYYATI  (edeb-9-repressiya)
    ('edeb-9-repressiya', 'edeb-9-repressiya-proletkultculu-dovrunde',
     'Proletkultçuluq və repressiya dövründə ədəbiyyat (1920-1940)', 10),
    ('edeb-9-repressiya', 'edeb-9-repressiya-abdulla-saiq',
     'Abdulla Şaiq. Anabacı', 20),
    ('edeb-9-repressiya', 'edeb-9-repressiya-yusif-vezir',
     'Yusif Vəzir Çəmənzəminli. Zeybək qızı', 30),
    ('edeb-9-repressiya', 'edeb-9-repressiya-almas-ildirim',
     'Almas İldırım. Əsir Azərbaycanım', 40),
    ('edeb-9-repressiya', 'edeb-9-repressiya-mikayil-musfiq',
     'Mikayıl Müşfiq. Həyat sevgisi', 50),
    ('edeb-9-repressiya', 'edeb-9-repressiya-seyid-huseyn',
     'Seyid Hüseyn. İki həyat arasında (qiymətləndirmə materialı)', 60),
    --  II merhele. SOVET DOVRU AZERBAYCAN EDEBIYYATI  (edeb-9-muharibe)
    ('edeb-9-muharibe', 'edeb-9-muharibe-ikinci-dunya',
     'İkinci Dünya müharibəsi, şəxsiyyətə pərəstiş və mülayimləşmə dövründə ədəbiyyat (1941-1960)', 10),
    ('edeb-9-muharibe', 'edeb-9-muharibe-semed-vurgun',
     'Səməd Vurğun. Ananın öyüdü', 20),
    ('edeb-9-muharibe', 'edeb-9-muharibe-suleyman-rustem',
     'Süleyman Rüstəm. Təbrizim', 30),
    ('edeb-9-muharibe', 'edeb-9-muharibe-mir-celal',
     'Mir Cəlal. Vətən yaraları', 40),
    ('edeb-9-muharibe', 'edeb-9-muharibe-mirze-ibrahimov',
     'Mirzə İbrahimov. Gələcək gün (romandan parçalar)', 50),
    ('edeb-9-muharibe', 'edeb-9-muharibe-mehdi-huseyn',
     'Mehdi Hüseyn. Nişan üzüyü (qiymətləndirmə materialı)', 60),
    --  II merhele. SOVET DOVRU AZERBAYCAN EDEBIYYATI  (edeb-9-ozunuderk-seir)
    ('edeb-9-ozunuderk-seir', 'edeb-9-ozunuderk-seir-milli-menevi',
     'Milli-mənəvi özünüdərk dövründə ədəbiyyat (1961-1990)', 10),
    ('edeb-9-ozunuderk-seir', 'edeb-9-ozunuderk-seir-resul-rza',
     'Rəsul Rza. Çinar ömrü', 20),
    ('edeb-9-ozunuderk-seir', 'edeb-9-ozunuderk-seir-eliaga-kurcayli',
     'Əliağa Kürçaylı. Şəhid meşə (qiymətləndirmə materialı)', 30),
    ('edeb-9-ozunuderk-seir', 'edeb-9-ozunuderk-seir-memmed-araz',
     'Məmməd Araz. Əsgər məktubu', 40),
    ('edeb-9-ozunuderk-seir', 'edeb-9-ozunuderk-seir-balas-azeroglu',
     'Balaş Azəroğlu. Buludlar (qiymətləndirmə materialı)', 50),
    ('edeb-9-ozunuderk-seir', 'edeb-9-ozunuderk-seir-eli-kerim',
     'Əli Kərim. Qaytar ana borcunu', 60),
    ('edeb-9-ozunuderk-seir', 'edeb-9-ozunuderk-seir-sabir-rustemxanli',
     'Sabir Rüstəmxanlı. Sağ ol, ana dilim! (qiymətləndirmə materialı)', 70),
    --  II merhele. SOVET DOVRU AZERBAYCAN EDEBIYYATI  (edeb-9-ozunuderk-nesr)
    ('edeb-9-ozunuderk-nesr', 'edeb-9-ozunuderk-nesr-ismayil-sixli',
     'İsmayıl Şıxlı. Namərd gülləsi', 10),
    ('edeb-9-ozunuderk-nesr', 'edeb-9-ozunuderk-nesr-isa-huseynov',
     'İsa Hüseynov. Zəhər', 20),
    ('edeb-9-ozunuderk-nesr', 'edeb-9-ozunuderk-nesr-anar-kecen',
     'Anar. Keçən ilin son gecəsi', 30),
    ('edeb-9-ozunuderk-nesr', 'edeb-9-ozunuderk-nesr-elcin-talvar',
     'Elçin. Talvar', 40),
    --  III merhele. DOVLET MUSTEQILLIYI DOVRUNDE AZERBAYCAN EDEBIYYATI (1991-ci ilden gunumuze qeder)  (edeb-9-mustaqillik)
    ('edeb-9-mustaqillik', 'edeb-9-mustaqillik-qilman-ilkin',
     'Qılman İlkin. İntiqam', 10),
    ('edeb-9-mustaqillik', 'edeb-9-mustaqillik-bextiyar-vahabzade',
     'Bəxtiyar Vahabzadə. İstiqlal', 20),
    ('edeb-9-mustaqillik', 'edeb-9-mustaqillik-xelil-rza',
     'Xəlil Rza Ulutürk. Qaytar mənim qüdrətimi, Azərbaycan!', 30),
    ('edeb-9-mustaqillik', 'edeb-9-mustaqillik-sabir-ehmedov',
     'Sabir Əhmədov. Dənizdən gələn səda (qiymətləndirmə materialı)', 40),
    --  III merhele. DOVLET MUSTEQILLIYI DOVRUNDE AZERBAYCAN EDEBIYYATI (1991-ci ilden gunumuze qeder)  (edeb-9-cenub)
    ('edeb-9-cenub', 'edeb-9-cenub-azerbaycan',
     'CƏNUBİ AZƏRBAYCAN ƏDƏBİYYATI', 10),
    ('edeb-9-cenub', 'edeb-9-cenub-mehemmedhuseyn-sehriyar',
     'Məhəmmədhüseyn Şəhriyar. Heydərbabaya salam', 20),
    --  III merhele. DOVLET MUSTEQILLIYI DOVRUNDE AZERBAYCAN EDEBIYYATI (1991-ci ilden gunumuze qeder)  (edeb-9-dunya)
    ('edeb-9-dunya', 'edeb-9-dunya-dunya-edebiyyati',
     'DÜNYA ƏDƏBİYYATI', 10),
    ('edeb-9-dunya', 'edeb-9-dunya-ernest-heminquey',
     'Ernest Heminquey. Qoca və dəniz', 20),
    ('edeb-9-dunya', 'edeb-9-dunya-hebib-sahir',
     'Həbib Sahir. Səhənd dağı (qiymətləndirmə materialı)', 30),
    --  ============  10-cu sinif  ============
    --  Edebiyyat  (edeb-10-sifahi)
    ('edeb-10-sifahi', 'edeb-10-sifahi-soz-senetimiz',
     'Söz sənətimiz - mənəvi sərvətimiz', 10),
    ('edeb-10-sifahi', 'edeb-10-sifahi-azerbaycan-xalq',
     'AZƏRBAYCAN ŞİFAHİ XALQ ƏDƏBİYYATI', 20),
    ('edeb-10-sifahi', 'edeb-10-sifahi-azerbaycan-yaradiciligi',
     'Azərbaycan şifahi xalq yaradıcılığı', 30),
    --  Edebiyyat  (edeb-10-dede-qorqud)
    ('edeb-10-dede-qorqud', 'edeb-10-dede-qorqud-qedim-dovr',
     'QƏDİM DÖVR AZƏRBAYCAN ƏDƏBİYYATI', 10),
    ('edeb-10-dede-qorqud', 'edeb-10-dede-qorqud-kitabi-eposu',
     '"Kitabi-Dədə Qorqud" eposu', 20),
    ('edeb-10-dede-qorqud', 'edeb-10-dede-qorqud-salur-qazanin',
     'Salur Qazanın evinin yağmalandığı boy', 30),
    --  Edebiyyat  (edeb-10-nizami)
    ('edeb-10-nizami', 'edeb-10-nizami-intibah-dovru',
     'İNTİBAH DÖVRÜ AZƏRBAYCAN ƏDƏBİYYATI', 10),
    ('edeb-10-nizami', 'edeb-10-nizami-gencevi-heyati',
     'Nizami Gəncəvi. Həyatı, yaradıcılıq yolu', 20),
    ('edeb-10-nizami', 'edeb-10-nizami-iskendername',
     'İskəndərnamə', 30),
    --  Edebiyyat  (edeb-10-nesimi-xetayi)
    ('edeb-10-nesimi-xetayi', 'edeb-10-nesimi-xetayi-orta-esrler',
     'ORTA ƏSRLƏR AZƏRBAYCAN ƏDƏBİYYATI', 10),
    ('edeb-10-nesimi-xetayi', 'edeb-10-nesimi-xetayi-imadeddin-yolu',
     'İmadəddin Nəsimi. Həyatı, yaradıcılıq yolu', 20),
    ('edeb-10-nesimi-xetayi', 'edeb-10-nesimi-xetayi-sigmazam',
     'Sığmazam', 30),
    ('edeb-10-nesimi-xetayi', 'edeb-10-nesimi-xetayi-sah-ismayil',
     'Şah İsmayıl Xətayi. Həyatı, yaradıcılıq yolu', 40),
    ('edeb-10-nesimi-xetayi', 'edeb-10-nesimi-xetayi-dehname',
     'Dəhnamə', 50),
    --  Edebiyyat  (edeb-10-fuzuli)
    ('edeb-10-fuzuli', 'edeb-10-fuzuli-mehemmed-heyati',
     'Məhəmməd Füzuli. Həyatı, yaradıcılıq yolu', 10),
    ('edeb-10-fuzuli', 'edeb-10-fuzuli-meni-candan',
     'Məni candan usandırdı...', 20),
    ('edeb-10-fuzuli', 'edeb-10-fuzuli-leyli-mecnun',
     'Leyli və Məcnun', 30),
    --  Edebiyyat  (edeb-10-koroglu-vaqif)
    ('edeb-10-koroglu-vaqif', 'edeb-10-koroglu-vaqif-erken-yeni',
     'ERKƏN YENİ DÖVR AZƏRBAYCAN ƏDƏBİYYATI', 10),
    ('edeb-10-koroglu-vaqif', 'edeb-10-koroglu-vaqif-eposu',
     '"Koroğlu" eposu', 20),
    ('edeb-10-koroglu-vaqif', 'edeb-10-koroglu-vaqif-hemzenin-qirati',
     'Həmzənin Qıratı qaçırması', 30),
    ('edeb-10-koroglu-vaqif', 'edeb-10-koroglu-vaqif-molla-penah',
     'Molla Pənah Vaqif. Həyatı, yaradıcılıq yolu', 40),
    ('edeb-10-koroglu-vaqif', 'edeb-10-koroglu-vaqif-peri',
     'Pəri', 50),
    --  Edebiyyat  (edeb-10-maarifci)
    ('edeb-10-maarifci', 'edeb-10-maarifci-azerbaycan-realizm',
     'AZƏRBAYCAN ƏDƏBİYYATINDA MAARİFÇİ-REALİZM DÖVRÜ', 10),
    ('edeb-10-maarifci', 'edeb-10-maarifci-qasim-zakir',
     'Qasım bəy Zakir. Həyatı, yaradıcılıq yolu', 20),
    ('edeb-10-maarifci', 'edeb-10-maarifci-badi-seba',
     'Badi-səba, mənim dərdi-dilimi', 30),
    ('edeb-10-maarifci', 'edeb-10-maarifci-asiq-elesger',
     'Aşıq Ələsgər. Həyatı, yaradıcılıq yolu', 40),
    ('edeb-10-maarifci', 'edeb-10-maarifci-daglar',
     'Dağlar', 50),
    ('edeb-10-maarifci', 'edeb-10-maarifci-seyid-ezim',
     'Seyid Əzim Şirvani. Həyatı, yaradıcılıq yolu', 60),
    ('edeb-10-maarifci', 'edeb-10-maarifci-gus-qil',
     'Guş qıl', 70),
    ('edeb-10-maarifci', 'edeb-10-maarifci-necef-vezirov',
     'Nəcəf bəy Vəzirov Həyatı, yaradıcılıq yolu', 80),
    ('edeb-10-maarifci', 'edeb-10-maarifci-musibeti-fexreddin',
     'Müsibəti-Fəxrəddin', 90),
    --  Edebiyyat  (edeb-10-axundzade)
    ('edeb-10-axundzade', 'edeb-10-axundzade-mirze-feteli',
     'Mirzə Fətəli Axundzadə. Həyatı, yaradıcılıq yolu', 10),
    ('edeb-10-axundzade', 'edeb-10-axundzade-hekayeti-musyo',
     'Hekayəti-müsyö Jordan həkimi-nəbatat və dərviş Məstəli şah caduküni-məşhur', 20),
    ('edeb-10-axundzade', 'edeb-10-axundzade-aldanmis-kevakib',
     'Aldanmış kəvakib', 30),
    --  ============  11-ci sinif  ============
    --  AZERBAYCAN EDEBIYYATINDA TENQIDI REALIZM VE ROMANTIZM DOVRU  (edeb-11-tenqidi-realizm)
    ('edeb-11-tenqidi-realizm', 'edeb-11-tenqidi-realizm-xix-esrin',
     '(XIX əsrin 90-cı illərindən 1920-ci ilədək)', 10),
    ('edeb-11-tenqidi-realizm', 'edeb-11-tenqidi-realizm-celil-memmedquluzade',
     'Cəlil Məmmədquluzadə', 20),
    ('edeb-11-tenqidi-realizm', 'edeb-11-tenqidi-realizm-heyati-yolu',
     'Həyatı, yaradıcılıq yolu', 30),
    ('edeb-11-tenqidi-realizm', 'edeb-11-tenqidi-realizm-anamin-kitabi',
     'Anamın kitabı', 40),
    ('edeb-11-tenqidi-realizm', 'edeb-11-tenqidi-realizm-mirze-elekber',
     'Mirzə Ələkbər Sabir', 50),
    ('edeb-11-tenqidi-realizm', 'edeb-11-tenqidi-realizm-heyati-yaradiciliq-yolu',
     'Həyatı, yaradıcılıq yolu', 60),
    ('edeb-11-tenqidi-realizm', 'edeb-11-tenqidi-realizm-neylerdin-ilahi',
     'Neylərdin, ilahi?!', 70),
    --  AZERBAYCAN EDEBIYYATINDA TENQIDI REALIZM VE ROMANTIZM DOVRU  (edeb-11-romantizm)
    ('edeb-11-romantizm', 'edeb-11-romantizm-huseyn-cavid',
     'Hüseyn Cavid', 10),
    ('edeb-11-romantizm', 'edeb-11-romantizm-heyati-yolu',
     'Həyatı, yaradıcılıq yolu', 20),
    ('edeb-11-romantizm', 'edeb-11-romantizm-iblis',
     'İblis', 30),
    ('edeb-11-romantizm', 'edeb-11-romantizm-ehmed-cavad',
     'Əhməd Cavad', 40),
    ('edeb-11-romantizm', 'edeb-11-romantizm-heyati-yaradiciliq-yolu',
     'Həyatı, yaradıcılıq yolu', 50),
    ('edeb-11-romantizm', 'edeb-11-romantizm-sesli-qiz',
     'Səsli qız', 60),
    --  CENUBI AZERBAYCAN EDEBIYYATI  (edeb-11-cenub-dunya)
    ('edeb-11-cenub-dunya', 'edeb-11-cenub-dunya-mehemmedhuseyn-sehriyar',
     'Məhəmmədhüseyn Şəhriyar', 10),
    ('edeb-11-cenub-dunya', 'edeb-11-cenub-dunya-heyati-yaradiciliq',
     'Həyatı, yaradıcılıq yolu', 20),
    ('edeb-11-cenub-dunya', 'edeb-11-cenub-dunya-turkun-dili',
     'Türkün dili', 30),
    --  SOVET DOVRU AZERBAYCAN EDEBIYYATI (1920-1991-ci iller) Azerbaycan edebiyyatinda sosialist realizmi merhelesi (1920-1960-ci iller)  (edeb-11-cabbarli-vurgun)
    ('edeb-11-cabbarli-vurgun', 'edeb-11-cabbarli-vurgun-cefer',
     'Cəfər Cabbarlı', 10),
    ('edeb-11-cabbarli-vurgun', 'edeb-11-cabbarli-vurgun-heyati-yolu',
     'Həyatı, yaradıcılıq yolu', 20),
    ('edeb-11-cabbarli-vurgun', 'edeb-11-cabbarli-vurgun-oqtay-eloglu',
     'Oqtay Eloğlu', 30),
    ('edeb-11-cabbarli-vurgun', 'edeb-11-cabbarli-vurgun-semed',
     'Səməd Vurğun', 40),
    ('edeb-11-cabbarli-vurgun', 'edeb-11-cabbarli-vurgun-heyati-yaradiciliq-yolu',
     'Həyatı, yaradıcılıq yolu', 50),
    ('edeb-11-cabbarli-vurgun', 'edeb-11-cabbarli-vurgun-vaqif',
     'Vaqif', 60),
    --  SOVET DOVRU AZERBAYCAN EDEBIYYATI (1920-1991-ci iller) Azerbaycan edebiyyatinda sosialist realizmi merhelesi (1920-1960-ci iller)  (edeb-11-rza-mircelal)
    ('edeb-11-rza-mircelal', 'edeb-11-rza-mircelal-resul-rza',
     'Rəsul Rza', 10),
    ('edeb-11-rza-mircelal', 'edeb-11-rza-mircelal-heyati-yolu',
     'Həyatı, yaradıcılıq yolu', 20),
    ('edeb-11-rza-mircelal', 'edeb-11-rza-mircelal-qizilgul-olmayaydi',
     'Qızılgül olmayaydı', 30),
    ('edeb-11-rza-mircelal', 'edeb-11-rza-mircelal-celal',
     'Mir Cəlal', 40),
    ('edeb-11-rza-mircelal', 'edeb-11-rza-mircelal-heyati-yaradiciliq-yolu',
     'Həyatı, yaradıcılıq yolu', 50),
    ('edeb-11-rza-mircelal', 'edeb-11-rza-mircelal-aciq-kitab',
     'Açıq kitab', 60),
    --  Milli menevi ozunuderk ve istiqlal edebiyyati merhelesi (1960-1980-ci iller)  (edeb-11-ozunuderk)
    ('edeb-11-ozunuderk', 'edeb-11-ozunuderk-ilyas-efendiyev',
     'İlyas Əfəndiyev', 10),
    ('edeb-11-ozunuderk', 'edeb-11-ozunuderk-heyati-yolu',
     'Həyatı, yaradıcılıq yolu', 20),
    ('edeb-11-ozunuderk', 'edeb-11-ozunuderk-xursidbanu-natevan',
     'Xurşidbanu Natəvan', 30),
    ('edeb-11-ozunuderk', 'edeb-11-ozunuderk-ismayil-sixli',
     'İsmayıl Şıxlı', 40),
    ('edeb-11-ozunuderk', 'edeb-11-ozunuderk-heyati-yaradiciliq-yolu',
     'Həyatı, yaradıcılıq yolu', 50),
    ('edeb-11-ozunuderk', 'edeb-11-ozunuderk-deli-kur',
     'Dəli Kür', 60),
    --  MUSTEQILLIK DOVRU COXMETODLU AZERBAYCAN EDEBIYYATI (1991-ci ilden bu gune qeder)  (edeb-11-istiqlal)
    ('edeb-11-istiqlal', 'edeb-11-istiqlal-bextiyar-vahabzade',
     'Bəxtiyar Vahabzadə', 10),
    ('edeb-11-istiqlal', 'edeb-11-istiqlal-heyati-yaradiciliq',
     'Həyatı,yaradıcılıq yolu', 20),
    ('edeb-11-istiqlal', 'edeb-11-istiqlal-sehidler',
     'Şəhidlər', 30),
    --  DUNYA EDEBIYYATINDAN SECME  (edeb-11-cenub-dunya)
    ('edeb-11-cenub-dunya', 'edeb-11-cenub-dunya-cingiz-aytmatov',
     'Çingiz Aytmatov', 40),
    ('edeb-11-cenub-dunya', 'edeb-11-cenub-dunya-heyati-yaradiciliq-yolu',
     'Həyatı, yaradıcılıq yolu', 50),
    ('edeb-11-cenub-dunya', 'edeb-11-cenub-dunya-gun-var',
     'Gün var əsrə bərabər', 60)
  ) as v(parent_slug, slug, name, sort)
  join public.topics p on p.slug = v.parent_slug
   and p.subject_id = (select id from public.subjects where slug = 'edebiyyat')
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort,
      parent_id = excluded.parent_id, level_id = excluded.level_id;

do $$
declare k int;
begin
  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'edebiyyat'
    join public.levels   l on l.id = p.level_id and l.code = '5';
  if k <> 19 then
    raise exception 'edebiyyat 5-ci alt movzulari: 19 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'edebiyyat'
    join public.levels   l on l.id = p.level_id and l.code = '6';
  if k <> 21 then
    raise exception 'edebiyyat 6-ci alt movzulari: 21 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'edebiyyat'
    join public.levels   l on l.id = p.level_id and l.code = '7';
  if k <> 25 then
    raise exception 'edebiyyat 7-ci alt movzulari: 25 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'edebiyyat'
    join public.levels   l on l.id = p.level_id and l.code = '8';
  if k <> 23 then
    raise exception 'edebiyyat 8-ci alt movzulari: 23 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'edebiyyat'
    join public.levels   l on l.id = p.level_id and l.code = '9';
  if k <> 35 then
    raise exception 'edebiyyat 9-cu alt movzulari: 35 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'edebiyyat'
    join public.levels   l on l.id = p.level_id and l.code = '10';
  if k <> 34 then
    raise exception 'edebiyyat 10-cu alt movzulari: 34 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'edebiyyat'
    join public.levels   l on l.id = p.level_id and l.code = '11';
  if k <> 40 then
    raise exception 'edebiyyat 11-ci alt movzulari: 40 gozlenilirdi, % tapildi', k;
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
    join public.subjects s on s.id = t.subject_id and s.slug = 'edebiyyat'
    join public.levels   l on l.id = t.level_id
   where t.parent_id is null and true;
  if k <> 48 then
    raise exception 'Edebiyyat ust movzu sayi 48 deyil: %', k;
  end if;

  raise notice 'Edebiyyat 5-11 (11-ci sinif nezeriyye hele bos): 197 alt movzu hazir.';
end $$;
