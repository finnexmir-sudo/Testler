-- =====================================================================
--  90_alt_movzular_cografiya6_11.sql : COGRAFIYA 6-11 - ALT MOVZULAR
--
--  NIYE
--  Doqquzuncu fenn.  Riyaziyyat, heyat bilgisi, informatika, fizika,
--  kimya, biologiya, ingilis dili hazirdir.  Cografiya 6-ci sinifden
--  baslayir (1-5-de yoxdur).
--
--  MENBE: e-derslik.edu.az "Movzular" agaci - kitab id 859/860 (6),
--  922/923 (7), 799 (8), 881 (9), 729 (10), 814 (11).  Adlar EYNILE
--  goturulub.
--
--  DERSLIYIN QURULUSU HER SINIFDE FERQLIDIR:
--
--  6-ci sinif: kitab 859-un "Bolme 3. COL TEDQIQATI"-nin mundericat
--  sehifesinde "Bolme 4. KAINATI SEYR EDIREM" basligi "==" bolme kimi
--  DEYIL, adi bir setir kimi bolme 3-un daxilinde gorunur (fizika 7-
--  nin "Bolme 4" teləsi ile eyni portal qusuru, bax db/86).  Bu setir
--  ozu xaric edilib, sehife 68-den sonrasi cog-6-kainat-a gedir.
--
--  7-ci sinif: 7 bolme birbasa bire-bir - problemsiz.
--
--  8-ci sinif: dersliyde 10 Roma reqemli bolme (I-X) var, bazada 8
--  movzu - iki movzunun ozu birlesmeni gosterir: "Su tebeqesi ve
--  biosfer" (cog-8-hidrosfer) VI (Yerin su tebeqesi) + VII (Biosfer)
--  bolmelerini birlesdirir, "Dunya olkeleri ve ehali" (cog-8-olkeler)
--  ise VIII (Dunya olkelerinin tesnifati) + IX (Ehali ve tesserrufatin
--  erazi teskili) bolmelerini - IX-un basligindaki "Ehali" sozu movzu
--  adindaki "ehali" ile birbasa uygunlasir.
--
--  9-cu sinif: dersliyde 3 boyuk boluk var ("Giris", "I Bolme", "II
--  Bolme"), her BOLME oz icinde Roma reqemli alt-basliqlarla (I-VII)
--  bolunub - novbeti dersle EYNI sehifede olduqları ucun alt-basliq
--  qaydasi ile tutulur (informatika/kimya/biologiya-dan tanis
--  mexanizm).  "Giris" -> cog-9-xerite (movzuca uygun gelir), "I
--  Bolme" 4 alt-basliqla 4 movzuya (relyef/iqlim/sular/bioehtiyat),
--  "II Bolme" 3 alt-basliqla 3 movzuya (sivilizasiya/ehali/
--  iqtisadiyyat) - hamisi basligin ozunde adlanib.
--
--  10-cu sinif: dersliyde "Giris" + iki boyuk boluk ("1. YERIN
--  TEBIETI", "2. DUNYANIN SIYASI VE IQTISADI MENZERESI"), bunlarin da
--  icinde Roma reqemli alt-basliqlar (I-IX) var.  "Giris" ve "I.
--  YER SEMA CISMIDIR" eyni movzuya (cog-10-yer-kainat) gedir - adlari
--  demek olar eynidir.  "VII. Dunya ehalisi" ve "VIII. Siyasi
--  munasibetler" de eyni movzuye (cog-10-ehali-siyasi) - movzu adinin
--  ozu ("Ehali ve siyasi xeritə") hər ikisini eyni anda cagirir.
--
--  11-ci sinif: dersliyde 6 boyuk boluk (1-6), bazada 8 movzu.
--  "5. QLOBAL PROBLEMLER VE ONLARIN HELLI YOLLARI"-nin 6 dersi arasinda
--  enerji/erzaq ve ekoloji mövzular qarisiqdir (5.1 enerji, 5.4 erzaq,
--  qalanlari - bioloji ehtiyat/su/alicilq/tullanti - aydin ekoloji
--  deyil), sehife serhedi ile aydin bolunmur.  Boluk basliginin ozu
--  ("Qlobal problemler") cog-11-ekoloji-qlobal-in adina ("Qlobal
--  ekoloji problemler") daha yaxindir, ona gore 6 ders də ora getdi -
--  cog-11-enerji-erzaq hele 0 alt movzu qalir (biologiya-11-viruslar
--  ile eyni qerar: uydurma sehife serhedi qoyulmadi).
--  "6. BEYNELXALQ INTEQRASIYA VE QLOBALLASMA" ise aydindir - ilk ders
--  (6.1) hərfi-hərfinə "Beynelxalq inteqrasiya" adlanir, sehife 182-
--  den qalani cog-11-qloballasma-ya gedir.
--
--  BURAXILAN BENDLER: "SOZLUK" (boyuk herfle - XARIC_UMUMI-deki
--  "Sozluk" bunu tutmur, boyuk-kicik herf fərqlidir), "Terminlerin
--  izahli lugeti", "Terminler lugeti".
--
--  YAZI VE EDED QUSURLARI: 9-cu sinifde iki bend "20" evezine "2O"
--  (herf O reqem 0 evezine) yazilib - NOMRE bunlari tanimir, elle
--  duzeldildi.  Bir necə bend soz birlesmesi ("Amerikanındaxilisuları"),
--  kesik soz ("daxili sul" -> "daxili sulari", "sahə qurulus" ->
--  "sahə qurulusu", "iqlim tiplər" -> "iqlim tipləri") ve bosluqsuz
--  vergul/baglayici ("Avropa,Şimali Amerikavə") - hamisi mezmunu
--  deyismeden duzeldilib.  11-ci sinifde iki bend "Praktik ders"
--  evezine "Praktikders" yazilib.
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
--   * yazi (10): yazi qusuru (bosluq, herf)
--       6-ci   s.30   Azerbaycan tebietinin formalasmas
--                    -> Azerbaycan tebietinin formalasmasi
--       9-cu   s.74   2O. Praktik ders. Azerbaycanin iqlimi
--                    -> Praktik ders. Azerbaycanin iqlimi
--       9-cu   s.86   23. Simali Amerikanindaxilisulari
--                    -> Simali Amerikanin daxili sulari
--       9-cu   s.95   26. Avstraliyanin daxili sul
--                    -> Avstraliyanin daxili sulari
--       9-cu   s.165  47. Avropa,Simali Amerikave Avstraliyanin ehalisi
--                    -> Avropa, Simali Amerika ve Avstraliyanin ehalisi
--       9-cu   s.173  49. Teserrufatin sahe qurulus
--                    -> Teserrufatin sahe qurulusu
--       9-cu   s.178  5O. Istehsal ve qeyri-istehsal saheleri
--                    -> Istehsal ve qeyri-istehsal saheleri
--       10-cu  s.86   23. Azerbaycanin iqlim tipler
--                    -> Azerbaycanin iqlim tipleri
--       11-ci  s.124  4.6. Praktikders. Azerbaycanin iqtisadi rayonlarinin seciyyesi
--                    -> Praktik ders. Azerbaycanin iqtisadi rayonlarinin seciyyesi
--       11-ci  s.195  6.5. Praktikders.Turk dunyasi birliyi
--                    -> Praktik ders. Turk dunyasi birliyi

insert into public.topics (subject_id, level_id, parent_id, slug, name, sort)
select p.subject_id, p.level_id, p.id, v.slug, v.name, v.sort
  from (values
    --  ============  6-ci sinif  ============
    --  Bolme 1. MEKANI TANIYAQ  (cog-6-mekan)
    ('cog-6-mekan', 'cog-6-mekan-mekan',
     'Məkan', 10),
    ('cog-6-mekan', 'cog-6-mekan-harada-yasayiriq',
     'Harada yaşayırıq?', 20),
    ('cog-6-mekan', 'cog-6-mekan-cografi-ferqlenir',
     'Coğrafi məkan necə fərqlənir?', 30),
    ('cog-6-mekan', 'cog-6-mekan-yasadigimiz-ferqlendirmek',
     'Yaşadığımız məkanı necə fərqləndirmək olar?', 40),
    ('cog-6-mekan', 'cog-6-mekan-deyerlendirme',
     'Dəyərləndirmə', 50),
    ('cog-6-mekan', 'cog-6-mekan-miqyasi',
     'Məkanın miqyası', 60),
    ('cog-6-mekan', 'cog-6-mekan-miqyasi-ferqlenirmi',
     'Məkanın miqyası fərqlənirmi?', 70),
    ('cog-6-mekan', 'cog-6-mekan-lokal-qlobal',
     'Lokal məkandan qlobal məkana', 80),
    ('cog-6-mekan', 'cog-6-mekan-olkemizden-dunyaya',
     'Ölkəmizdən dünyaya', 90),
    ('cog-6-mekan', 'cog-6-mekan-deyerlendirme-2',
     'Dəyərləndirmə', 100),
    ('cog-6-mekan', 'cog-6-mekan-umumi',
     'Ümumiləşdirici tapşırıqlar', 110),
    --  Bolme 2. MEKANIN BELEDCISI  (cog-6-beledci)
    ('cog-6-beledci', 'cog-6-beledci-mekanin-edilmesi',
     'Məkanın təsvir edilməsi', 10),
    ('cog-6-beledci', 'cog-6-beledci-plan-etmek',
     'Plan tərtib etmək üçün hansı biliklər tələb olunur?', 20),
    ('cog-6-beledci', 'cog-6-beledci-planin-edilmesi',
     'Planın tərtib edilməsi', 30),
    ('cog-6-beledci', 'cog-6-beledci-deyerlendirme',
     'Dəyərləndirmə', 40),
    ('cog-6-beledci', 'cog-6-beledci-mekanin-kodlasdirilmas',
     'Məkanın kodlaşdırılması', 50),
    ('cog-6-beledci', 'cog-6-beledci-planetimiz-edilir',
     'Planetimiz necə təsvir edilir?', 60),
    ('cog-6-beledci', 'cog-6-beledci-derece-torunun',
     'Dərəcə torunun elementləri', 70),
    ('cog-6-beledci', 'cog-6-beledci-xerite-edilir',
     'Xəritə necə tərtib edilir?', 80),
    ('cog-6-beledci', 'cog-6-beledci-niye-muxtelif',
     'Xəritələr niyə müxtəlif rənglərdə çəkilir?', 90),
    ('cog-6-beledci', 'cog-6-beledci-muasir-edilir',
     'Müasir xəritələr necə tərtib edilir?', 100),
    ('cog-6-beledci', 'cog-6-beledci-cografi-informasiya',
     'Coğrafi informasiya sistemlərindən harada istifadə olunur?', 110),
    ('cog-6-beledci', 'cog-6-beledci-deyerlendirme-2',
     'Dəyərləndirmə', 120),
    ('cog-6-beledci', 'cog-6-beledci-umumi',
     'Ümumiləşdirici tapşırıqlar', 130),
    --  Bolme 3. COL TEDQIQATI  (cog-6-col)
    ('cog-6-col', 'cog-6-col-erazide-tedqiqat',
     'Ərazidə tədqiqat', 10),
    ('cog-6-col', 'cog-6-col-tedqiqati-nedir',
     'Çöl tədqiqatı nədir?', 20),
    ('cog-6-col', 'cog-6-col-cantaniz-varmi',
     'Tədqiqat çantanız varmı?', 30),
    ('cog-6-col', 'cog-6-col-mekteb-erazisinde',
     'Məktəb ərazisində çöl tədqiqatını necə aparmaq olar?', 40),
    ('cog-6-col', 'cog-6-col-deyerlendirme',
     'Dəyərləndirmə', 50),
    ('cog-6-col', 'cog-6-col-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    --  Bolme 3. COL TEDQIQATI  (cog-6-kainat)
    ('cog-6-kainat', 'cog-6-kainat-sema-cisimlerine',
     'Nə üçün səma cisimlərinə maraq göstəririk?', 10),
    ('cog-6-kainat', 'cog-6-kainat-semani-seyr',
     'Səmanı seyr edərkən nələri görürük?', 20),
    ('cog-6-kainat', 'cog-6-kainat-oxu-hereketi',
     'Yerin öz oxu ətrafında hərəkəti', 30),
    ('cog-6-kainat', 'cog-6-kainat-gunes-hereketi',
     'Yerin Günəş ətrafında hərəkəti', 40),
    ('cog-6-kainat', 'cog-6-kainat-movzu',
     'Ay', 50),
    ('cog-6-kainat', 'cog-6-kainat-cin-mutexessisleri',
     'Çin mütəxəssislərinin uğurları', 60),
    ('cog-6-kainat', 'cog-6-kainat-deyerlendirme',
     'Dəyərləndirmə', 70),
    ('cog-6-kainat', 'cog-6-kainat-umumi',
     'Ümumiləşdirici tapşırıqlar', 80),
    --  Bolme 5. TEBIETI KESF EDIREM  (cog-6-tebiet)
    ('cog-6-tebiet', 'cog-6-tebiet-muxteliflik',
     'Təbiətdəki müxtəliflik', 10),
    ('cog-6-tebiet', 'cog-6-tebiet-yer-kuresinin',
     'Yer kürəsinin təbii mənzərəsi', 20),
    ('cog-6-tebiet', 'cog-6-tebiet-hansi-var',
     'Təbiətdə hansı komponentlər var?', 30),
    ('cog-6-tebiet', 'cog-6-tebiet-ferqli-menzereler',
     'Təbii komponentlər fərqli mənzərələr yaradır', 40),
    ('cog-6-tebiet', 'cog-6-tebiet-deyerlendirme',
     'Dəyərləndirmə', 50),
    ('cog-6-tebiet', 'cog-6-tebiet-sistemdir',
     'Təbiət bir sistemdir', 60),
    ('cog-6-tebiet', 'cog-6-tebiet-sistemin-formalasmasi',
     'Təbii sistemin formalaşması', 70),
    ('cog-6-tebiet', 'cog-6-tebiet-fotosintezin-cografiyasi',
     'Fotosintezin coğrafiyası', 80),
    ('cog-6-tebiet', 'cog-6-tebiet-manqr-meseleri',
     'Manqr meşələri lokal təbii sistemdir', 90),
    ('cog-6-tebiet', 'cog-6-tebiet-deyerlendirme-2',
     'Dəyərləndirmə', 100),
    ('cog-6-tebiet', 'cog-6-tebiet-umumi',
     'Ümumiləşdirici tapşırıqlar', 110),
    --  Bolme 6. YURDUMUZUN TEBIETINE SEYAHET  (cog-6-yurdumuz)
    ('cog-6-yurdumuz', 'cog-6-yurdumuz-olkemizin-tebietini',
     'Ölkəmizin təbiətini tanıyaq', 10),
    ('cog-6-yurdumuz', 'cog-6-yurdumuz-tebietimizin-zenginlikleri',
     'Təbiətimizin zənginlikləri', 20),
    ('cog-6-yurdumuz', 'cog-6-yurdumuz-azerbaycan-tebietinin',
     'Azərbaycan təbiətinin formalaşması', 30),
    ('cog-6-yurdumuz', 'cog-6-yurdumuz-sirvan-qorugu',
     'Şirvan qoruğu nə üçün yaradıldı?', 40),
    ('cog-6-yurdumuz', 'cog-6-yurdumuz-deyerlendirme',
     'Dəyərləndirmə', 50),
    ('cog-6-yurdumuz', 'cog-6-yurdumuz-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    --  Bolme 7. DUNYA BIZIM EVIMIZDIR!  (cog-6-dunya)
    ('cog-6-dunya', 'cog-6-dunya-yer-kuresinin',
     'Yer kürəsinin sosial mənzərəsi', 10),
    ('cog-6-dunya', 'cog-6-dunya-sosial-nedir',
     'Sosial həyat nədir?', 20),
    ('cog-6-dunya', 'cog-6-dunya-ferdler-esasidir',
     'Fərdlər sosial həyatın əsasıdır', 30),
    ('cog-6-dunya', 'cog-6-dunya-aile-kicik',
     'Ailə kiçik dövlətdir', 40),
    ('cog-6-dunya', 'cog-6-dunya-cemiyyet-esas',
     'Cəmiyyət sosial həyatın əsas hissəsidir', 50),
    ('cog-6-dunya', 'cog-6-dunya-dovlet-siyasi',
     'Dövlət cəmiyyətin siyasi qurumudur', 60),
    ('cog-6-dunya', 'cog-6-dunya-novruz-senlikleri',
     'Novruz şənlikləri', 70),
    ('cog-6-dunya', 'cog-6-dunya-deyerlendirme',
     'Dəyərləndirmə', 80),
    ('cog-6-dunya', 'cog-6-dunya-inkisafinda-qurumlarin',
     'Cəmiyyətin inkişafında qurumların rolu', 90),
    ('cog-6-dunya', 'cog-6-dunya-muhiti-heyat',
     'İş mühiti və sosial həyat', 100),
    ('cog-6-dunya', 'cog-6-dunya-qeyri-hokumet',
     'Qeyri-hökumət təşkilatları', 110),
    ('cog-6-dunya', 'cog-6-dunya-sirketlerin-heyatdaki',
     'Şirkətlərin sosial həyatdakı rolu', 120),
    ('cog-6-dunya', 'cog-6-dunya-deyerlendirme-2',
     'Dəyərləndirmə', 130),
    ('cog-6-dunya', 'cog-6-dunya-lokal-qlobal',
     'Lokal və qlobal əlaqələr', 140),
    ('cog-6-dunya', 'cog-6-dunya-vetendasin-vezifeleri',
     'Vətəndaşın vəzifələri', 150),
    ('cog-6-dunya', 'cog-6-dunya-milli-mesuliyyet',
     'Milli məsuliyyət hissi', 160),
    ('cog-6-dunya', 'cog-6-dunya-heqiqeten-boyukdurmu',
     'Dünya həqiqətən də böyükdürmü?', 170),
    ('cog-6-dunya', 'cog-6-dunya-azerbaycanin-dovletleri',
     'Azərbaycanın dünya dövlətləri ilə münasibətləri', 180),
    ('cog-6-dunya', 'cog-6-dunya-deyerlendirme-3',
     'Dəyərləndirmə', 190),
    ('cog-6-dunya', 'cog-6-dunya-umumi',
     'Ümumiləşdirici tapşırıqlar', 200),
    --  ============  7-ci sinif  ============
    --  Bolme 1. Cografi movqe  (cog-7-movqe)
    ('cog-7-movqe', 'cog-7-movqe-cografi-teyini',
     'Coğrafi mövqeyin təyini', 10),
    ('cog-7-movqe', 'cog-7-movqe-teyin-etmek',
     'Coğrafi mövqeyi necə təyin etmək olar?', 20),
    ('cog-7-movqe', 'cog-7-movqe-azerbaycan-harada',
     'Azərbaycan harada yerləşir?', 30),
    ('cog-7-movqe', 'cog-7-movqe-ciapas-eyaletinde',
     'Çiapas əyalətində əkinçilik', 40),
    ('cog-7-movqe', 'cog-7-movqe-cis-teyini',
     'CİS-lə coğrafi mövqe təyini', 50),
    ('cog-7-movqe', 'cog-7-movqe-erazinin-tehlil',
     'Ərazinin mövqeyini CİS-lə necə təhlil edə bilərik?', 60),
    ('cog-7-movqe', 'cog-7-movqe-gelecek-perspektivleri',
     'Coğrafi mövqeyin gələcək perspektivləri nələrdir?', 70),
    ('cog-7-movqe', 'cog-7-movqe-turistler-xeritesinden',
     'Turistlər CİS xəritəsindən necə istifadə edirlər?', 80),
    ('cog-7-movqe', 'cog-7-movqe-deyerlendirme',
     'Dəyərləndirmə', 90),
    ('cog-7-movqe', 'cog-7-movqe-umumi',
     'Ümumiləşdirici tapşırıqlar', 100),
    --  Bolme 2. Yerin daxili prosesleri  (cog-7-daxili)
    ('cog-7-daxili', 'cog-7-daxili-yerin-qurulusu',
     'Yerin daxili quruluşu', 10),
    ('cog-7-daxili', 'cog-7-daxili-yerin-var',
     'Yerin daxilində nə var?', 20),
    ('cog-7-daxili', 'cog-7-daxili-yer-sethini',
     'Vulkanlar Yer səthini necə dəyişir?', 30),
    ('cog-7-daxili', 'cog-7-daxili-vulkanizm-prosesleri',
     'Vulkanizm prosesləri ölkəmizdə necə baş verir?', 40),
    ('cog-7-daxili', 'cog-7-daxili-yatmis-oyana',
     'Yatmış vulkanlar oyana bilərmi?', 50),
    ('cog-7-daxili', 'cog-7-daxili-deyerlendirme',
     'Dəyərləndirmə', 60),
    ('cog-7-daxili', 'cog-7-daxili-litosferin-hereketi',
     'Litosferin hərəkəti', 70),
    ('cog-7-daxili', 'cog-7-daxili-berk-tebeqesi',
     'Yerin bərk təbəqəsi necə hərəkət edir?', 80),
    ('cog-7-daxili', 'cog-7-daxili-zelzele-verir',
     'Zəlzələ necə baş verir?', 90),
    ('cog-7-daxili', 'cog-7-daxili-azerbaycanda-tektonik',
     'Azərbaycanda tektonik hərəkətlər baş verirmi?', 100),
    ('cog-7-daxili', 'cog-7-daxili-seysmik-dalgalar',
     'Seysmik dalğalar necə hərəkət edir?', 110),
    ('cog-7-daxili', 'cog-7-daxili-deyerlendirme-2',
     'Dəyərləndirmə', 120),
    ('cog-7-daxili', 'cog-7-daxili-umumi',
     'Ümumiləşdirici tapşırıqlar', 130),
    --  Bolme 3. Yer sethinin qurlusu  (cog-7-seth)
    ('cog-7-seth', 'cog-7-seth-relyef-nedir',
     'Relyef nədir?', 10),
    ('cog-7-seth', 'cog-7-seth-yer-ferqlenir',
     'Yer səthinin relyefi necə fərqlənir?', 20),
    ('cog-7-seth', 'cog-7-seth-daglarin-yarandigini',
     'Dağların necə yarandığını bilirikmi?', 30),
    ('cog-7-seth', 'cog-7-seth-duzenlikler-muxtelifdir',
     'Düzənliklər nə üçün müxtəlifdir?', 40),
    ('cog-7-seth', 'cog-7-seth-qrafikle-tesvir',
     'Relyefi qrafiklə təsvir etmək mümkündürmü?', 50),
    ('cog-7-seth', 'cog-7-seth-deyerlendirme',
     'Dəyərləndirmə', 60),
    ('cog-7-seth', 'cog-7-seth-qitelerin-okeanlarin',
     'Qitələrin və okeanların relyefi', 70),
    ('cog-7-seth', 'cog-7-seth-yeri-planeti',
     'Yeri su planeti adlandırmaq olarmı?', 80),
    ('cog-7-seth', 'cog-7-seth-quruda-paylanmisdir',
     'Quruda relyef formaları necə paylanmışdır?', 90),
    ('cog-7-seth', 'cog-7-seth-azerbaycanda-paylanmisdir',
     'Azərbaycanda relyef formaları necə paylanmışdır?', 100),
    ('cog-7-seth', 'cog-7-seth-sualti-dunya',
     'Sualtı dünya haqqında nə bilirik?', 110),
    ('cog-7-seth', 'cog-7-seth-antarktidanin-ferqlenir',
     'Antarktidanın relyefi nə ilə fərqlənir?', 120),
    ('cog-7-seth', 'cog-7-seth-deyerlendirme-2',
     'Dəyərləndirmə', 130),
    ('cog-7-seth', 'cog-7-seth-umumi',
     'Ümumiləşdirici tapşırıqlar', 140),
    --  Bolme 4 HAVA SERAITI  (cog-7-hava)
    ('cog-7-hava', 'cog-7-hava-deyisken',
     'Dəyişkən hava', 10),
    ('cog-7-hava', 'cog-7-hava-seraiti-nedir',
     'Hava şəraiti nədir?', 20),
    ('cog-7-hava', 'cog-7-hava-temperaturu-deyisir',
     'Havanın temperaturu necə dəyişir?', 30),
    ('cog-7-hava', 'cog-7-hava-axini-yaranir',
     'Hava axını necə yaranır?', 40),
    ('cog-7-hava', 'cog-7-hava-kulekler-seheri',
     '“Küləklər şəhəri”', 50),
    ('cog-7-hava', 'cog-7-hava-deyerlendirme',
     'Dəyərləndirmə', 60),
    ('cog-7-hava', 'cog-7-hava-havada',
     'Havada su', 70),
    ('cog-7-hava', 'cog-7-hava-buludlar-gelir',
     'Buludlar necə əmələ gəlir?', 80),
    ('cog-7-hava', 'cog-7-hava-yagintilar-gelir',
     'Yağıntılar necə əmələ gəlir?', 90),
    ('cog-7-hava', 'cog-7-hava-azerbaycanda-temperatur',
     'Azərbaycanda temperatur və yağıntı necə paylanır?', 100),
    ('cog-7-hava', 'cog-7-hava-melumatlarini-haradan',
     'Hava məlumatlarını haradan əldə edirik?', 110),
    ('cog-7-hava', 'cog-7-hava-deyerlendirme-2',
     'Dəyərləndirmə', 120),
    ('cog-7-hava', 'cog-7-hava-umumi',
     'Ümumiləşdirici tapşırıqlar', 130),
    --  Bolme 5. IQLIM  (cog-7-iqlim)
    ('cog-7-iqlim', 'cog-7-iqlim-mekanda',
     'Məkanda iqlim', 10),
    ('cog-7-iqlim', 'cog-7-iqlim-nece-yaranir',
     'İqlim necə yaranır?', 20),
    ('cog-7-iqlim', 'cog-7-iqlim-qursaqlari-nedir',
     'İqlim qurşaqları nədir və necə paylanır?', 30),
    ('cog-7-iqlim', 'cog-7-iqlim-azerbaycanda-necedir',
     'Azərbaycanda iqlim necədir?', 40),
    ('cog-7-iqlim', 'cog-7-iqlim-denizden-zirveye',
     'Dənizdən zirvəyə iqlim', 50),
    ('cog-7-iqlim', 'cog-7-iqlim-deyerlendirme',
     'Dəyərləndirmə', 60),
    ('cog-7-iqlim', 'cog-7-iqlim-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    --  Bolme 6. MAGARADAN GOYDELENE  (cog-7-mesken)
    ('cog-7-mesken', 'cog-7-mesken-yasayis-menteqeleri',
     'Əhali artımı və yaşayış məntəqələri', 10),
    ('cog-7-mesken', 'cog-7-mesken-artiminda-ferqler',
     'Əhalinin artımında fərqlər', 20),
    ('cog-7-mesken', 'cog-7-mesken-seherlesen-dunya',
     'Şəhərləşən dünya', 30),
    ('cog-7-mesken', 'cog-7-mesken-artsin-yoxsa',
     'Əhali artsın, yoxsa azalsın?', 40),
    ('cog-7-mesken', 'cog-7-mesken-deyerlendirme',
     'Dəyərləndirmə', 50),
    ('cog-7-mesken', 'cog-7-mesken-azix-magarasindan',
     'Azıx mağarasından "Alov qüllələri"nə', 60),
    ('cog-7-mesken', 'cog-7-mesken-azerbaycanda-meskunlasma',
     'Azərbaycanda əhali artımı və məskunlaşma', 70),
    ('cog-7-mesken', 'cog-7-mesken-rural-urban',
     'Azərbaycanda rural və urban', 80),
    ('cog-7-mesken', 'cog-7-mesken-sayinin-deyismesi',
     'Azərbaycanda əhalinin sayının dəyişməsi', 90),
    ('cog-7-mesken', 'cog-7-mesken-deyerlendirme-2',
     'Dəyərləndirmə', 100),
    ('cog-7-mesken', 'cog-7-mesken-umumi',
     'Ümumiləşdirici tapşırıqlar', 110),
    --  Bolme 7. IQTISADI FEALIYYET  (cog-7-iqtisadi)
    ('cog-7-iqtisadi', 'cog-7-iqtisadi-mekanin-menzeresi',
     'Məkanın iqtisadi mənzərəsi', 10),
    ('cog-7-iqtisadi', 'cog-7-iqtisadi-fealiyyet-nedir',
     'İqtisadi fəaliyyət nədir?', 20),
    ('cog-7-iqtisadi', 'cog-7-iqtisadi-sektorlar-nedir',
     'İqtisadi sektorlar nədir?', 30),
    ('cog-7-iqtisadi', 'cog-7-iqtisadi-ferqli-olkeler',
     'Fərqli ölkələr – fərqli iqtisadiyyat', 40),
    ('cog-7-iqtisadi', 'cog-7-iqtisadi-deyerlendirme',
     'Dəyərləndirmə', 50),
    ('cog-7-iqtisadi', 'cog-7-iqtisadi-azerbaycanin-menzeresi',
     'Azərbaycanın iqtisadi mənzərəsi', 60),
    ('cog-7-iqtisadi', 'cog-7-iqtisadi-azerbaycanda-sektorlar',
     'Azərbaycanda iqtisadi sektorlar', 70),
    ('cog-7-iqtisadi', 'cog-7-iqtisadi-azerbaycanda-rayonlar',
     'Azərbaycanda iqtisadi rayonlar', 80),
    ('cog-7-iqtisadi', 'cog-7-iqtisadi-ferqli-rayonlar',
     'Fərqli rayonlar – fərqli iqtisadiyyat', 90),
    ('cog-7-iqtisadi', 'cog-7-iqtisadi-deyerlendirme-2',
     'Dəyərləndirmə', 100),
    ('cog-7-iqtisadi', 'cog-7-iqtisadi-umumi',
     'Ümumiləşdirici tapşırıqlar', 110),
    --  ============  8-ci sinif  ============
    --  I. Cografi kesflerden tedqiqatlara dogru  (cog-8-kesfler)
    ('cog-8-kesfler', 'cog-8-kesfler-cografi-merhelesi',
     'Coğrafi kəşflərin yeni mərhələsi', 10),
    ('cog-8-kesfler', 'cog-8-kesfler-cografiya-inkisafi',
     'Coğrafiya elminin inkişafı', 20),
    ('cog-8-kesfler', 'cog-8-kesfler-muasir-saheleri',
     'Müasir coğrafiya elminin yeni sahələri', 30),
    ('cog-8-kesfler', 'cog-8-kesfler-cografiyada-biliklerin',
     'Coğrafiyada yeni biliklərin toplanması yolları', 40),
    ('cog-8-kesfler', 'cog-8-kesfler-azerbaycanda-inkisafi',
     'Azərbaycanda coğrafiya elminin inkişafı', 50),
    ('cog-8-kesfler', 'cog-8-kesfler-umumilesdirici-tapsiriqlar',
     'Ümumiləşdirici tapşırıqlar. Coğrafiyanın yeni sahələri və tədqiqat üsulları', 60),
    --  II. Xeriteler ve onlarin uzerinde tesvir usullari  (cog-8-xerite)
    ('cog-8-xerite', 'cog-8-xerite-tesvirlerin-ehemiyyeti',
     'Kartoqrafik təsvirlərin əhəmiyyəti', 10),
    ('cog-8-xerite', 'cog-8-xerite-tesvirler-melumat',
     'Kartoqrafik təsvirlər məlumat mənbəyidir', 20),
    ('cog-8-xerite', 'cog-8-xerite-tesvir-usullari',
     'Xəritələrdə təsvir üsulları', 30),
    ('cog-8-xerite', 'cog-8-xerite-tesnifati',
     'Xəritələrin təsnifatı', 40),
    ('cog-8-xerite', 'cog-8-xerite-mesafelerin-sahelerin',
     'Xəritələrdə məsafələrin və sahələrin hesablanması', 50),
    ('cog-8-xerite', 'cog-8-xerite-umumilesdirici-tapsiriqlar',
     'Ümumiləşdirici tapşırıqlar. Xəritə üzərində iş və hesablama aparılması', 60),
    --  III. Yerin hereketi ve onun cografi neticeleri  (cog-8-yer-hereketi)
    ('cog-8-yer-hereketi', 'cog-8-yer-hereketi-qursaq-vaxti',
     'Qurşaq vaxtı', 10),
    ('cog-8-yer-hereketi', 'cog-8-yer-hereketi-yerin-illik',
     'Yerin illik hərəkəti', 20),
    ('cog-8-yer-hereketi', 'cog-8-yer-hereketi-qutb-gece',
     'Qütb gecə və gündüzləri', 30),
    ('cog-8-yer-hereketi', 'cog-8-yer-hereketi-isiqlanma-qursaqlari',
     'İşıqlanma qurşaqları', 40),
    ('cog-8-yer-hereketi', 'cog-8-yer-hereketi-gunes-hesablanmasi',
     'Günəş şüalarının düşmə bucağının hesablanması', 50),
    ('cog-8-yer-hereketi', 'cog-8-yer-hereketi-umumilesdirici-tapsiriqlar',
     'Ümumiləşdirici tapşırıqlar. Qurşaq vaxtı və günəş şüalarının düşmə bucağının hesablanması', 60),
    --  IV. Yerin feal tektonik tebeqesi  (cog-8-tektonik)
    ('cog-8-tektonik', 'cog-8-tektonik-yerin-muasir',
     'Yerin müasir üfüqi və şaquli hərəkət sahələri', 10),
    ('cog-8-tektonik', 'cog-8-tektonik-litosfer-tavalari',
     'Litosfer tavaları', 20),
    ('cog-8-tektonik', 'cog-8-tektonik-litosfer-neticeleri',
     'Litosfer tavalarının hərəkətinin nəticələri', 30),
    ('cog-8-tektonik', 'cog-8-tektonik-qedim-quru',
     'Qədim quru və su sahələri', 40),
    ('cog-8-tektonik', 'cog-8-tektonik-umumilesdirici-tapsiriqlar',
     'Ümumiləşdirici tapşırıqlar. Litosfer tavalarının hərəkətinin nəticələri', 50),
    --  V. Atmosfer  (cog-8-atmosfer)
    ('cog-8-atmosfer', 'cog-8-atmosfer-hava-kutleleri',
     'Hava kütlələri və atmosfer cəbhələri', 10),
    ('cog-8-atmosfer', 'cog-8-atmosfer-daimi-movsumi',
     'Daimi və mövsümi cəbhələri', 20),
    ('cog-8-atmosfer', 'cog-8-atmosfer-siklon-antisiklonlar',
     'Siklon və antisiklonlar', 30),
    ('cog-8-atmosfer', 'cog-8-atmosfer-yagintilarin-paylanmasi',
     'Yağıntıların paylanması', 40),
    ('cog-8-atmosfer', 'cog-8-atmosfer-iqlim-yaranmasi',
     'İqlim və onun yaranması', 50),
    ('cog-8-atmosfer', 'cog-8-atmosfer-umumilesdirici-tapsiriqlar',
     'Ümumiləşdirici tapşırıqlar. Temperatur və yağıntıların illik gedişi', 60),
    --  VI. Yerin su tebeqesi  (cog-8-hidrosfer)
    ('cog-8-hidrosfer', 'cog-8-hidrosfer-dunya-okeaninin',
     'Dünya okeanının yaranması', 10),
    ('cog-8-hidrosfer', 'cog-8-hidrosfer-okeanlarin-oyrenilmesi',
     'Okeanların öyrənilməsi', 20),
    ('cog-8-hidrosfer', 'cog-8-hidrosfer-okean-temperaturu',
     'Okean suyunun temperaturu', 30),
    ('cog-8-hidrosfer', 'cog-8-hidrosfer-duzlulugu-seffafligi',
     'Okean suyunun duzluluğu və şəffaflığı', 40),
    ('cog-8-hidrosfer', 'cog-8-hidrosfer-okeanlarda-suyun',
     'Okeanlarda suyun hərəkəti', 50),
    ('cog-8-hidrosfer', 'cog-8-hidrosfer-umumilesdirici-tapsiriqlar',
     'Ümumiləşdirici tapşırıqlar. Okean suyunun temperaturu və duzluluğunun təyin olunması', 60),
    --  VII. Biosfer  (cog-8-hidrosfer)
    ('cog-8-hidrosfer', 'cog-8-hidrosfer-biosfer-yerin',
     'Biosfer Yerin təbəqələri sistemində', 70),
    ('cog-8-hidrosfer', 'cog-8-hidrosfer-cografi-tebeqe',
     'Coğrafi təbəqə', 80),
    ('cog-8-hidrosfer', 'cog-8-hidrosfer-heyvanlarin-yasayis',
     'Bitki və heyvanların yaşayış mühiti', 90),
    ('cog-8-hidrosfer', 'cog-8-hidrosfer-tebii-zonalar',
     'Təbii zonalar', 100),
    ('cog-8-hidrosfer', 'cog-8-hidrosfer-azerbaycanin-heyvanlar',
     'Azərbaycanın bitki və heyvanlar aləmi', 110),
    ('cog-8-hidrosfer', 'cog-8-hidrosfer-umumilesdirici-tapsiriqlar-qursaqlar',
     'Ümumiləşdirici tapşırıqlar. "Coğrafi qurşaqlar və təbii zonalar" xəritəsi üzərində iş', 120),
    --  VIII. Dunya olkelerinin tesnifati  (cog-8-olkeler)
    ('cog-8-olkeler', 'cog-8-olkeler-seviyyesine-tesnifati',
     'Ölkələrin inkişaf səviyyəsinə görə təsnifatı', 10),
    ('cog-8-olkeler', 'cog-8-olkeler-etmis-ieo',
     'İnkişaf etmiş ölkələr (İEÖ)', 20),
    ('cog-8-olkeler', 'cog-8-olkeler-etmekde-ieoo',
     'İnkişaf etməkdə olan ölkələr (İEOÖ)', 30),
    ('cog-8-olkeler', 'cog-8-olkeler-insan-inkisafi',
     'İnsan İnkişafı İndeksi', 40),
    ('cog-8-olkeler', 'cog-8-olkeler-umumilesdirici-tapsiriqlar',
     'Ümumiləşdirici tapşırıqlar. Ölkələrin inkişaf səviyyəsinin müqayisə edilməsi', 50),
    --  IX. Ehali ve teserrufatin erazi teskili  (cog-8-olkeler)
    ('cog-8-olkeler', 'cog-8-olkeler-ehalinin-sayi',
     'Əhalinin sayı', 60),
    ('cog-8-olkeler', 'cog-8-olkeler-artimi-miqrasiyasi',
     'Əhalinin təbii artımı və miqrasiyası', 70),
    ('cog-8-olkeler', 'cog-8-olkeler-tebii-ehtiyatlar',
     'Təbii ehtiyatlar', 80),
    ('cog-8-olkeler', 'cog-8-olkeler-tebii-ehemiyyeti',
     'Təbii ehtiyatların təsərrüfat əhəmiyyəti', 90),
    ('cog-8-olkeler', 'cog-8-olkeler-istehsalin-teskili',
     'İstehsalın təşkili formaları', 100),
    ('cog-8-olkeler', 'cog-8-olkeler-teserrufatin-iqtisadi',
     'Təsərrüfatın iqtisadi inkişaf yolları', 110),
    ('cog-8-olkeler', 'cog-8-olkeler-umumilesdirici-tapsiriqlar-tesnifati',
     'Ümumiləşdirici tapşırıqlar. Təbii ehtiyatların təsnifatı və təsərrüfat əhəmiyyəti', 120),
    --  X. Ekoloji muhit ve onun muhafizesi  (cog-8-ekologiya)
    ('cog-8-ekologiya', 'cog-8-ekologiya-muhiti-cirklendiren',
     'Ətraf mühiti çirkləndirən mənbələr', 10),
    ('cog-8-ekologiya', 'cog-8-ekologiya-teserrufat-saheleri',
     'Təsərrüfat sahələri və ekoloji mühit', 20),
    ('cog-8-ekologiya', 'cog-8-ekologiya-muhitin-muhafizesi',
     'Ətraf mühitin mühafizəsi yolları', 30),
    ('cog-8-ekologiya', 'cog-8-ekologiya-insanlarin-saglamliginin',
     'Ətraf mühit və insanların sağlamlığının qorunması', 40),
    ('cog-8-ekologiya', 'cog-8-ekologiya-azerbaycanin-veziyyeti',
     'Azərbaycanın ekoloji vəziyyəti və turizm-rekreasiya ehtiyatları', 50),
    ('cog-8-ekologiya', 'cog-8-ekologiya-umumilesdirici-tapsiriqlar',
     'Ümumiləşdirici tapşırıqlar. Ekoloji problemlər və onların aradan qaldırılması yolları', 60),
    --  ============  9-cu sinif  ============
    --  Giris. 1. Cografi informasiyanin teqdimolunma usullari  (cog-9-xerite)
    ('cog-9-xerite', 'cog-9-xerite-topoqrafik-nece',
     'Topoqrafik xəritələri necə oxumalı', 10),
    --  I Bolme. YER KURESININ TEBIETI VE ONUN TESERRUFAT EHEMIYYETI  (cog-9-relyef)
    ('cog-9-relyef', 'cog-9-relyef-avropanin',
     'Avropanın relyefi', 10),
    ('cog-9-relyef', 'cog-9-relyef-asiyanin',
     'Asiyanın relyefi', 20),
    ('cog-9-relyef', 'cog-9-relyef-simali-amerikanin',
     'Şimali Amerikanın relyefi', 30),
    ('cog-9-relyef', 'cog-9-relyef-cenubi-amerikanin',
     'Cənubi Amerikanın relyefi', 40),
    ('cog-9-relyef', 'cog-9-relyef-afrikanin',
     'Afrikanın relyefi', 50),
    ('cog-9-relyef', 'cog-9-relyef-avstraliyanin',
     'Avstraliyanın relyefi', 60),
    ('cog-9-relyef', 'cog-9-relyef-azerbaycanin-tektonik',
     'Azərbaycanın relyefi və tektonik quruluşu', 70),
    ('cog-9-relyef', 'cog-9-relyef-umumi',
     'Ümumiləşdirici tapşırıqlar', 80),
    --  I Bolme. YER KURESININ TEBIETI VE ONUN TESERRUFAT EHEMIYYETI  (cog-9-iqlim)
    ('cog-9-iqlim', 'cog-9-iqlim-isigi-istiliyinin',
     'Günəş işığı və istiliyinin Yer kürəsində paylanması', 10),
    ('cog-9-iqlim', 'cog-9-iqlim-gunesli-saatlardan',
     'Günəşli saatlardan istifadə', 20),
    ('cog-9-iqlim', 'cog-9-iqlim-saat-qursaqlari',
     'Praktik dərs.Saat qurşaqları', 30),
    ('cog-9-iqlim', 'cog-9-iqlim-gunes-radiasiyasi',
     'Günəş radiasiyası', 40),
    ('cog-9-iqlim', 'cog-9-iqlim-avropanin',
     'Avropanın iqlimi', 50),
    ('cog-9-iqlim', 'cog-9-iqlim-asiyanin',
     'Asiyanın iqlimi', 60),
    ('cog-9-iqlim', 'cog-9-iqlim-simali-amerikanin',
     'Şimali Amerikanın iqlimi', 70),
    ('cog-9-iqlim', 'cog-9-iqlim-cenubi-amerikanin',
     'Cənubi Amerikanın iqlimi', 80),
    ('cog-9-iqlim', 'cog-9-iqlim-afrikanin',
     'Afrikanın iqlimi', 90),
    ('cog-9-iqlim', 'cog-9-iqlim-avstraliyanin',
     'Avstraliyanın iqlimi', 100),
    ('cog-9-iqlim', 'cog-9-iqlim-praktik-azerbaycanin',
     'Praktik dərs. Azərbaycanın iqlimi', 110),
    ('cog-9-iqlim', 'cog-9-iqlim-umumi',
     'Ümumiləşdirici tapşırıqlar', 120),
    --  I Bolme. YER KURESININ TEBIETI VE ONUN TESERRUFAT EHEMIYYETI  (cog-9-sular)
    ('cog-9-sular', 'cog-9-sular-avropanin-daxili',
     'Avropanın daxili suları', 10),
    ('cog-9-sular', 'cog-9-sular-asiyanin-daxili',
     'Asiyanın daxili suları', 20),
    ('cog-9-sular', 'cog-9-sular-simali-daxili',
     'Şimali Amerikanın daxili suları', 30),
    ('cog-9-sular', 'cog-9-sular-cenubi-daxili',
     'Cənubi Amerikanın daxili suları', 40),
    ('cog-9-sular', 'cog-9-sular-afrikanin-daxili',
     'Afrikanın daxili suları', 50),
    ('cog-9-sular', 'cog-9-sular-avstraliyanin-daxili',
     'Avstraliyanın daxili suları', 60),
    ('cog-9-sular', 'cog-9-sular-dunya-okeanindan',
     'Dünya okeanından istifadə', 70),
    ('cog-9-sular', 'cog-9-sular-azerbaycanin-anbarlari',
     'Azərbaycanın su anbarları və kanalları', 80),
    ('cog-9-sular', 'cog-9-sular-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    --  I Bolme. YER KURESININ TEBIETI VE ONUN TESERRUFAT EHEMIYYETI  (cog-9-bioehtiyat)
    ('cog-9-bioehtiyat', 'cog-9-bioehtiyat-simal-materiklerinin',
     'Şimal materiklərinin bioehtiyatları', 10),
    ('cog-9-bioehtiyat', 'cog-9-bioehtiyat-cenub-materiklerinin',
     'Cənub materiklərinin bioehtiyatları', 20),
    ('cog-9-bioehtiyat', 'cog-9-bioehtiyat-praktik-ders',
     'Praktik dərs. Antarktida - bioloji ehtiyatlarla zəif təmin olunmuş materikdir', 30),
    ('cog-9-bioehtiyat', 'cog-9-bioehtiyat-azerbaycanin-landsafti',
     'Azərbaycanın landşaftı bioehtiyatların mənbəyidir', 40),
    ('cog-9-bioehtiyat', 'cog-9-bioehtiyat-ekoloji-siyaset',
     'Ekoloji siyasət', 50),
    ('cog-9-bioehtiyat', 'cog-9-bioehtiyat-ekoloji-monitorinq',
     'Ekoloji monitorinq', 60),
    ('cog-9-bioehtiyat', 'cog-9-bioehtiyat-tebiete-ekskursiya',
     'Təbiətə ekskursiya', 70),
    ('cog-9-bioehtiyat', 'cog-9-bioehtiyat-umumi',
     'Ümumiləşdirici tapşırıqlar', 80),
    --  II Bolme. CEMIYYET VE IQTISADIYYAT  (cog-9-sivilizasiya)
    ('cog-9-sivilizasiya', 'cog-9-sivilizasiya-tarixi-inkisafi',
     'Sivilizasiyaların tarixi-coğrafi inkişafı', 10),
    ('cog-9-sivilizasiya', 'cog-9-sivilizasiya-turk-dunyasinin',
     'Türk dünyasının sivilizasiyalararası əlaqələrdə rolu', 20),
    ('cog-9-sivilizasiya', 'cog-9-sivilizasiya-azerbaycanin-movqeyi',
     'Azərbaycanın sivilizasiyalararası mövqeyi', 30),
    ('cog-9-sivilizasiya', 'cog-9-sivilizasiya-debat-ders',
     'Debat dərs. Azərbaycan: Avropa, yoxsa Asiya?', 40),
    ('cog-9-sivilizasiya', 'cog-9-sivilizasiya-regionlarin-veziyyeti',
     'Tarixi-coğrafi regionların müasir vəziyyəti', 50),
    ('cog-9-sivilizasiya', 'cog-9-sivilizasiya-dunyanin-iqtisadi',
     'Müasir dünyanın “iqtisadi gücləri"', 60),
    ('cog-9-sivilizasiya', 'cog-9-sivilizasiya-yer-kuresinin',
     'Yer kürəsinin mənimsənilməsi', 70),
    ('cog-9-sivilizasiya', 'cog-9-sivilizasiya-umumi',
     'Ümumiləşdirici tapşırıqlar', 80),
    --  II Bolme. CEMIYYET VE IQTISADIYYAT  (cog-9-ehali)
    ('cog-9-ehali', 'cog-9-ehali-sayinin-artimi',
     'Əhalinin sayının artımı və onun tənzimlənməsi', 10),
    ('cog-9-ehali', 'cog-9-ehali-dunya-terkibi',
     'Dünya əhalisinin yaş-cins tərkibi. Əmək ehtiyatları', 20),
    ('cog-9-ehali', 'cog-9-ehali-piramidasinin-qurulmasi',
     'Praktik dərs. Yaş-cins piramidasının qurulması', 30),
    ('cog-9-ehali', 'cog-9-ehali-asiya-afrika',
     'Asiya, Afrika və Latın Amerikasının əhalisi', 40),
    ('cog-9-ehali', 'cog-9-ehali-avropa-simali',
     'Avropa, Şimali Amerika və Avstraliyanın əhalisi', 50),
    ('cog-9-ehali', 'cog-9-ehali-azerbaycanda-demoqrafik',
     'Praktik dərs. Azərbaycanda demoqrafik vəziyyət', 60),
    ('cog-9-ehali', 'cog-9-ehali-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    --  II Bolme. CEMIYYET VE IQTISADIYYAT  (cog-9-iqtisadiyyat)
    ('cog-9-iqtisadiyyat', 'cog-9-iqtisadiyyat-teserrufatin-sahe',
     'Təsərrüfatın sahə quruluşu', 10),
    ('cog-9-iqtisadiyyat', 'cog-9-iqtisadiyyat-istehsal-qeyri',
     'İstehsal və qeyri-istehsal sahələri', 20),
    ('cog-9-iqtisadiyyat', 'cog-9-iqtisadiyyat-nece-yerlesdirilir',
     'Sənaye sahələri necə yerləşdirilir?', 30),
    ('cog-9-iqtisadiyyat', 'cog-9-iqtisadiyyat-kend-teserrufati',
     'Kənd təsərrüfatı sahələrinin yerləşdirilmə prinsipləri', 40),
    ('cog-9-iqtisadiyyat', 'cog-9-iqtisadiyyat-bazar',
     'Bazar iqtisadiyyatı', 50),
    ('cog-9-iqtisadiyyat', 'cog-9-iqtisadiyyat-mulkiyyet-formalari',
     'Mülkiyyət formaları', 60),
    ('cog-9-iqtisadiyyat', 'cog-9-iqtisadiyyat-azerbaycanin-inkisafi',
     'Azərbaycanın iqtisadi inkişafı', 70),
    ('cog-9-iqtisadiyyat', 'cog-9-iqtisadiyyat-tustusuz-turizm',
     '“Tüstüsüz sənaye” - turizm', 80),
    ('cog-9-iqtisadiyyat', 'cog-9-iqtisadiyyat-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    --  ============  10-cu sinif  ============
    --  Giris  (cog-10-yer-kainat)
    ('cog-10-yer-kainat', 'cog-10-yer-kainat-tebiet-elmleri',
     'Coğrafiya təbiət elmləri sistemində', 10),
    ('cog-10-yer-kainat', 'cog-10-yer-kainat-elminin-tedqiqat',
     'Coğrafiya elminin tədqiqat metodları', 20),
    --  1. YERIN TEBIETI  (cog-10-yer-kainat)
    ('cog-10-yer-kainat', 'cog-10-yer-kainat-sisteminin-yaranmasi',
     'Kainat və Günəş sisteminin yaranması haqqında fərziyyələr. Diskussiya dərsi', 30),
    ('cog-10-yer-kainat', 'cog-10-yer-kainat-planetar-inkisaf',
     'Yerin planetar inkişaf mərhələsi', 40),
    ('cog-10-yer-kainat', 'cog-10-yer-kainat-yerin-maqnetizmi',
     'Yerin maqnetizmi', 50),
    ('cog-10-yer-kainat', 'cog-10-yer-kainat-formasi-olculeri',
     'Yerin forması və ölçüləri', 60),
    ('cog-10-yer-kainat', 'cog-10-yer-kainat-yer-sethinde',
     'Yer səthində günəş şüalarının düşmə bucağının və vaxt fərqlərinin hesablanması. Praktik dərs', 70),
    ('cog-10-yer-kainat', 'cog-10-yer-kainat-umumi',
     'Ümumiləşdirici tapşırıqlar', 80),
    --  1. YERIN TEBIETI  (cog-10-kartoqrafiya)
    ('cog-10-kartoqrafiya', 'cog-10-kartoqrafiya-kartoqrafik-proyeksiyalar',
     'Kartoqrafik proyeksiyalar və təhriflər', 10),
    ('cog-10-kartoqrafiya', 'cog-10-kartoqrafiya-xerite-umumilesdirilm',
     'Xəritə ümumiləşdirilmiş təsvirdir', 20),
    ('cog-10-kartoqrafiya', 'cog-10-kartoqrafiya-miqyas-praktik',
     'Miqyas və təhriflər. Praktik dərs', 30),
    ('cog-10-kartoqrafiya', 'cog-10-kartoqrafiya-umumi',
     'Ümumiləşdirici tapşırıqlar', 40),
    --  1. YERIN TEBIETI  (cog-10-geologiya)
    ('cog-10-geologiya', 'cog-10-geologiya-yerin-inkisafi',
     'Yerin geoloji inkişafı', 10),
    ('cog-10-geologiya', 'cog-10-geologiya-qirisiqliq-vilayetleri',
     'Qırışıqlıq vilayətləri və platformalar', 20),
    ('cog-10-geologiya', 'cog-10-geologiya-dagemelegeme-merheleleri',
     'Dağəmələgəmə mərhələləri', 30),
    ('cog-10-geologiya', 'cog-10-geologiya-azerbaycanin-qurulusu',
     'Azərbaycanın geoloji quruluşu', 40),
    ('cog-10-geologiya', 'cog-10-geologiya-endogen-formalari',
     'Azərbaycanın endogen relyef formaları', 50),
    ('cog-10-geologiya', 'cog-10-geologiya-ekzogen-formalari',
     'Azərbaycanın ekzogen relyef formaları', 60),
    ('cog-10-geologiya', 'cog-10-geologiya-faydali-qazintilari',
     'Azərbaycanın faydalı qazıntıları və onların geoloji quruluşla əlaqəsi. Praktik dərs', 70),
    ('cog-10-geologiya', 'cog-10-geologiya-umumi',
     'Ümumiləşdirici tapşırıqlar', 80),
    --  1. YERIN TEBIETI  (cog-10-iqlim-ehtiyat)
    ('cog-10-iqlim-ehtiyat', 'cog-10-iqlim-ehtiyat-yer-sethinde',
     'Yer səthində istilik və buxarlanma', 10),
    ('cog-10-iqlim-ehtiyat', 'cog-10-iqlim-ehtiyat-gunesli-saatlarin',
     'Azərbaycanda günəşli saatların və istiliyin paylanması', 20),
    ('cog-10-iqlim-ehtiyat', 'cog-10-iqlim-ehtiyat-havanin-nisbi',
     'Havanın nisbi və mütləq rütubətliliyinin, rütubətlilik əmsalının hesablanması. Praktik dərs', 30),
    ('cog-10-iqlim-ehtiyat', 'cog-10-iqlim-ehtiyat-rutubetin-paylanmasi',
     'Azərbaycanda rütubətin paylanması', 40),
    ('cog-10-iqlim-ehtiyat', 'cog-10-iqlim-ehtiyat-qursaqlari-tipleri',
     'Dünyanın iqlim qurşaqları və iqlim tipləri', 50),
    ('cog-10-iqlim-ehtiyat', 'cog-10-iqlim-ehtiyat-azerbaycanin-tipleri',
     'Azərbaycanın iqlim tipləri', 60),
    ('cog-10-iqlim-ehtiyat', 'cog-10-iqlim-ehtiyat-dunyanin-aqroiqlim',
     'Dünyanın aqroiqlim ehtiyatları', 70),
    ('cog-10-iqlim-ehtiyat', 'cog-10-iqlim-ehtiyat-qlobal-deyismeleri',
     'Qlobal iqlim dəyişmələri', 80),
    ('cog-10-iqlim-ehtiyat', 'cog-10-iqlim-ehtiyat-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    --  1. YERIN TEBIETI  (cog-10-quru-sulari)
    ('cog-10-quru-sulari', 'cog-10-quru-sulari-yer-kuresinin',
     'Yer kürəsinin çayları', 10),
    ('cog-10-quru-sulari', 'cog-10-quru-sulari-azerbaycanin-caylari',
     'Azərbaycanın çayları', 20),
    ('cog-10-quru-sulari', 'cog-10-quru-sulari-caylarin-hidroloji',
     'Çayların hidroloji xüsusiyyətlərinin təyini. Praktik dərs', 30),
    ('cog-10-quru-sulari', 'cog-10-quru-sulari-buzlaqlar-bataqliqlar',
     'Buzlaqlar və bataqlıqlar', 40),
    ('cog-10-quru-sulari', 'cog-10-quru-sulari-yeralti',
     'Yeraltı sular', 50),
    ('cog-10-quru-sulari', 'cog-10-quru-sulari-xezer-denizi',
     'Xəzər dənizi', 60),
    ('cog-10-quru-sulari', 'cog-10-quru-sulari-denizinin-iqtisadi',
     'Xəzər dənizinin iqtisadi əhəmiyyəti. Layihə dərsi', 70),
    ('cog-10-quru-sulari', 'cog-10-quru-sulari-umumi',
     'Ümumiləşdirici tapşırıqlar', 80),
    --  1. YERIN TEBIETI  (cog-10-tebeqe)
    ('cog-10-tebeqe', 'cog-10-tebeqe-cografi-inkisafi',
     'Coğrafi təbəqənin inkişafı', 10),
    ('cog-10-tebeqe', 'cog-10-tebeqe-cografi-qanunauygunluq',
     'Coğrafi təbəqənin qanunauyğunluqları', 20),
    ('cog-10-tebeqe', 'cog-10-tebeqe-qoruqlari-yasaqliqlari',
     'Azərbaycanın qoruqları və yasaqlıqları', 30),
    ('cog-10-tebeqe', 'cog-10-tebeqe-fiziki-boyuk',
     'Azərbaycanın fiziki-coğrafi vilayətləri: Böyük Qafqaz', 40),
    ('cog-10-tebeqe', 'cog-10-tebeqe-kur-dagarasi',
     'Kür dağarası çökəkliyi vilayəti', 50),
    ('cog-10-tebeqe', 'cog-10-tebeqe-kicik-vilayeti',
     'Kiçik Qafqaz vilayəti', 60),
    ('cog-10-tebeqe', 'cog-10-tebeqe-lenkeran-orta',
     'Lənkəran və Orta Araz (Naxçıvan) vilayətləri', 70),
    ('cog-10-tebeqe', 'cog-10-tebeqe-umumi',
     'Ümumiləşdirici tapşırıqlar', 80),
    --  2. DUNYANIN SIYASI VE IQTISADI MENZERESI  (cog-10-ehali-siyasi)
    ('cog-10-ehali-siyasi', 'cog-10-ehali-siyasi-artimi-yaratdigi',
     'Əhali artımı və onun yaratdığı problemlər', 10),
    ('cog-10-ehali-siyasi', 'cog-10-ehali-siyasi-yerlesmesi',
     'Əhalinin yerləşməsi', 20),
    ('cog-10-ehali-siyasi', 'cog-10-ehali-siyasi-boyuk-seherler',
     'Urbanizasiya. Böyük şəhərlər', 30),
    ('cog-10-ehali-siyasi', 'cog-10-ehali-siyasi-regional-ferqler',
     'Urbanizasiya. Regional fərqlər', 40),
    ('cog-10-ehali-siyasi', 'cog-10-ehali-siyasi-azerbaycanda-sixligi',
     'Azərbaycanda əhalinin sıxlığı və urbanizasiya', 50),
    ('cog-10-ehali-siyasi', 'cog-10-ehali-siyasi-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    ('cog-10-ehali-siyasi', 'cog-10-ehali-siyasi-dunyanin-xeritesinin',
     'Dünyanın siyasi xəritəsinin formalaşması', 70),
    ('cog-10-ehali-siyasi', 'cog-10-ehali-siyasi-olkelerin-movqeyi',
     'Ölkələrin geosiyasi mövqeyi', 80),
    ('cog-10-ehali-siyasi', 'cog-10-ehali-siyasi-azerbaycanin-turk',
     'Azərbaycanın türk dünyasında və dünyada geosiyasi mövqeyi. Layihə', 90),
    ('cog-10-ehali-siyasi', 'cog-10-ehali-siyasi-qarabag-qelebenin',
     'Qarabağ - qələbənin coğrafi amilləri', 100),
    ('cog-10-ehali-siyasi', 'cog-10-ehali-siyasi-umumi-2',
     'Ümumiləşdirici tapşırıqlar', 110),
    --  2. DUNYANIN SIYASI VE IQTISADI MENZERESI  (cog-10-eti)
    ('cog-10-eti', 'cog-10-eti-elmi-inqilab',
     'Elmi-texniki inqilab', 10),
    ('cog-10-eti', 'cog-10-eti-inqilabin-dunya',
     'Elmi-texniki inqilabın dünya təsərrüfatına təsiri', 20),
    ('cog-10-eti', 'cog-10-eti-hasilat-senayesinin',
     'Dünyada hasilat sənayesinin coğrafiyası', 30),
    ('cog-10-eti', 'cog-10-eti-emaledici-senayenin',
     'Dünyada emaledici sənayenin coğrafiyası', 40),
    ('cog-10-eti', 'cog-10-eti-dunyanin-kend',
     'Dünyanın kənd təsərrüfatı', 50),
    ('cog-10-eti', 'cog-10-eti-neqliyyatin-cografiyasi',
     'Nəqliyyatın coğrafiyası', 60),
    ('cog-10-eti', 'cog-10-eti-qlobal-problemler',
     'Qlobal ekoloji problemlər', 70),
    ('cog-10-eti', 'cog-10-eti-azerbaycanin-problemleri',
     'Azərbaycanın ekoloji problemləri. Layihə', 80),
    ('cog-10-eti', 'cog-10-eti-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    --  ============  11-ci sinif  ============
    --  1. XERITE-C0GRAFI INFORMASIYA VASITESIDIR  (cog-11-xerite-cis)
    ('cog-11-xerite-cis', 'cog-11-xerite-cis-diaqnostik-qiymetlendirme',
     'Diaqnostik qiymətləndirmə', 10),
    ('cog-11-xerite-cis', 'cog-11-xerite-cis-kartoqrafik-tedqiqat',
     'Kartoqrafik tədqiqat metodları', 20),
    ('cog-11-xerite-cis', 'cog-11-xerite-cis-vizual-tehlili',
     'Praktik dərs. Coğrafi xəritələrin vizual təhlili', 30),
    ('cog-11-xerite-cis', 'cog-11-xerite-cis-qarabag-iqtisadi',
     'Layihə: "Qarabağ iqtisadi rayonunun kompleks səciyyəsi', 40),
    ('cog-11-xerite-cis', 'cog-11-xerite-cis-qrafik-tesvirler',
     'Qrafik təsvirlər', 50),
    ('cog-11-xerite-cis', 'cog-11-xerite-cis-praktik-tehlili',
     'Praktik dərs. Coğrafi xəritələrin qrafik təhlili', 60),
    ('cog-11-xerite-cis', 'cog-11-xerite-cis-teserrufat-sahelerinin',
     'Təsərrüfat sahələrinin yerləşməsinin xəritələrə əsasən təhlili', 70),
    ('cog-11-xerite-cis', 'cog-11-xerite-cis-informasiya-sistemleri',
     'Coğrafi informasiya sistemləri', 80),
    ('cog-11-xerite-cis', 'cog-11-xerite-cis-cis-axtaris',
     'Layihə: "CİS-lə axtarış"', 90),
    ('cog-11-xerite-cis', 'cog-11-xerite-cis-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 100),
    --  2. TEBIETDEN SEMERELI ISTIFADE  (cog-11-tebii-ehtiyat)
    ('cog-11-tebii-ehtiyat', 'cog-11-tebii-ehtiyat-diaqnostik-qiymetlendirme',
     'Diaqnostik qiymətləndirmə', 10),
    ('cog-11-tebii-ehtiyat', 'cog-11-tebii-ehtiyat-tektonik-prosesler',
     'Tektonik proseslər və təsərrüfat', 20),
    ('cog-11-tebii-ehtiyat', 'cog-11-tebii-ehtiyat-vulkan-puskurmeleri',
     'Layihə: "Vulkan püskürmələri"', 30),
    ('cog-11-tebii-ehtiyat', 'cog-11-tebii-ehtiyat-mineral-istifade',
     'Mineral ehtiyatlardan istifadə', 40),
    ('cog-11-tebii-ehtiyat', 'cog-11-tebii-ehtiyat-meteoroloji-hadiseler',
     'Meteoroloji hadisələr', 50),
    ('cog-11-tebii-ehtiyat', 'cog-11-tebii-ehtiyat-praktik-ders',
     'Praktik dərs. İqlim xəritələrinin təhlili', 60),
    ('cog-11-tebii-ehtiyat', 'cog-11-tebii-ehtiyat-insan-saglamligi',
     'İqlim və insan sağlamlığı', 70),
    ('cog-11-tebii-ehtiyat', 'cog-11-tebii-ehtiyat-qlobal-istilesmenin',
     'Layihə: "Qlobal istiləşmənin Azərbaycanda təzahürü"', 80),
    ('cog-11-tebii-ehtiyat', 'cog-11-tebii-ehtiyat-tecrube-dersi',
     'Təcrübə dərsi. İstixana effekti', 90),
    ('cog-11-tebii-ehtiyat', 'cog-11-tebii-ehtiyat-quru-sularindan',
     'Quru sularından istifadə', 100),
    ('cog-11-tebii-ehtiyat', 'cog-11-tebii-ehtiyat-tehlukeli-hidroloji',
     'Təhlükəli hidroloji hadisələr və onlarla mübarizə', 110),
    ('cog-11-tebii-ehtiyat', 'cog-11-tebii-ehtiyat-azerbaycanin-fondu',
     'Dünyanın və Azərbaycanın torpaq fondu', 120),
    ('cog-11-tebii-ehtiyat', 'cog-11-tebii-ehtiyat-layihe-mulkiyyeti',
     'Layihə: "Torpaq mülkiyyəti', 130),
    ('cog-11-tebii-ehtiyat', 'cog-11-tebii-ehtiyat-onlardan-istifade',
     'Meşə ehtiyatları və onlardan istifadə', 140),
    ('cog-11-tebii-ehtiyat', 'cog-11-tebii-ehtiyat-layihe-fondu',
     'Layihə: "Dünyanın meşə fondu', 150),
    ('cog-11-tebii-ehtiyat', 'cog-11-tebii-ehtiyat-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 160),
    --  3. DUNYANIN DEMOQRAFIK MENZERESI  (cog-11-demoqrafiya)
    ('cog-11-demoqrafiya', 'cog-11-demoqrafiya-diaqnostik-qiymetlendirme',
     'Diaqnostik qiymətləndirmə', 10),
    ('cog-11-demoqrafiya', 'cog-11-demoqrafiya-etnos-etnogenez',
     'Etnos və etnogenez', 20),
    ('cog-11-demoqrafiya', 'cog-11-demoqrafiya-dil-aileleri',
     'Praktik dərs. Dünyada dil ailələri', 30),
    ('cog-11-demoqrafiya', 'cog-11-demoqrafiya-demoqrafik-kecid',
     'Demoqrafik keçid mərhələləri', 40),
    ('cog-11-demoqrafiya', 'cog-11-demoqrafiya-emek-ehtiyatlarinin',
     'Əmək ehtiyatlarının əsas göstəriciləri', 50),
    ('cog-11-demoqrafiya', 'cog-11-demoqrafiya-ehalinin-heyat',
     'Əhalinin həyat səviyyəsi', 60),
    ('cog-11-demoqrafiya', 'cog-11-demoqrafiya-issizlik-novleri',
     'İşsizlik və onun növləri', 70),
    ('cog-11-demoqrafiya', 'cog-11-demoqrafiya-muasir-miqrasiya',
     'Müasir dünyada miqrasiya axınları', 80),
    ('cog-11-demoqrafiya', 'cog-11-demoqrafiya-azerbaycanin-ehalisi',
     'Praktik dərs. Azərbaycanın əhalisi', 90),
    ('cog-11-demoqrafiya', 'cog-11-demoqrafiya-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 100),
    --  4. IQTISADI INKISAFIN ISTIQAMETLERI  (cog-11-iqtisadi-inkisaf)
    ('cog-11-iqtisadi-inkisaf', 'cog-11-iqtisadi-inkisaf-diaqnostik-qiymetlendirme',
     'Diaqnostik qiymətləndirmə', 10),
    ('cog-11-iqtisadi-inkisaf', 'cog-11-iqtisadi-inkisaf-dayaniqli',
     'Dayanıqlı inkişaf', 20),
    ('cog-11-iqtisadi-inkisaf', 'cog-11-iqtisadi-inkisaf-temin-etmek',
     'Layihə: "Dayanıqlı inkişafı təmin etmək üçün nə edə bilərəm?"', 30),
    ('cog-11-iqtisadi-inkisaf', 'cog-11-iqtisadi-inkisaf-yollari',
     'İqtisadi inkişaf yolları', 40),
    ('cog-11-iqtisadi-inkisaf', 'cog-11-iqtisadi-inkisaf-esas-gostericileri',
     'İqtisadi inkişafın əsas göstəriciləri', 50),
    ('cog-11-iqtisadi-inkisaf', 'cog-11-iqtisadi-inkisaf-investisiya-muhiti',
     'İnvestisiya mühiti', 60),
    ('cog-11-iqtisadi-inkisaf', 'cog-11-iqtisadi-inkisaf-senaye-kend',
     'Sənaye və kənd təsərrüfatının müasir vəziyyəti', 70),
    ('cog-11-iqtisadi-inkisaf', 'cog-11-iqtisadi-inkisaf-beseriyyet-gmo',
     'Layihə: "Bəşəriyyət GMO olmadan yaşaya bilərmi?"', 80),
    ('cog-11-iqtisadi-inkisaf', 'cog-11-iqtisadi-inkisaf-praktik-ders',
     'Praktik dərs. Azərbaycanın iqtisadi rayonlarının səciyyəsi', 90),
    ('cog-11-iqtisadi-inkisaf', 'cog-11-iqtisadi-inkisaf-neqliyyati-xarici',
     'Azərbaycanın nəqliyyatı və xarici ticarət əlaqələri', 100),
    ('cog-11-iqtisadi-inkisaf', 'cog-11-iqtisadi-inkisaf-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 110),
    --  5. QLOBAL PROBLEMLER VE ONLARIN HELLI YOLLARI  (cog-11-ekoloji-qlobal)
    ('cog-11-ekoloji-qlobal', 'cog-11-ekoloji-qlobal-diaqnostik-qiymetlendirme',
     'Diaqnostik qiymətləndirmə', 10),
    ('cog-11-ekoloji-qlobal', 'cog-11-ekoloji-qlobal-alternativ-enerji',
     'Alternativ enerji mənbələri', 20),
    ('cog-11-ekoloji-qlobal', 'cog-11-ekoloji-qlobal-bioloji-ehtiyatlar',
     'Bioloji ehtiyatlar və onlardan istifadə', 30),
    ('cog-11-ekoloji-qlobal', 'cog-11-ekoloji-qlobal-icmeli-problemi',
     'Dünyanın içməli su problemi', 40),
    ('cog-11-ekoloji-qlobal', 'cog-11-ekoloji-qlobal-hovzelerinin-cirklenmesi',
     'Layihə: "Su hövzələrinin çirklənməsi və mühafizə tədbirləri"', 50),
    ('cog-11-ekoloji-qlobal', 'cog-11-ekoloji-qlobal-erzaq-problemi',
     'Dünyanın ərzaq problemi', 60),
    ('cog-11-ekoloji-qlobal', 'cog-11-ekoloji-qlobal-insanlarin-aliciliq',
     'İnsanların alıcılıq qabiliyyəti', 70),
    ('cog-11-ekoloji-qlobal', 'cog-11-ekoloji-qlobal-istehlak-sebeti',
     'Layihə: "Ailənin istehlak səbəti"', 80),
    ('cog-11-ekoloji-qlobal', 'cog-11-ekoloji-qlobal-tullantilar-istifade',
     'Tullantılar və onlardan istifadə', 90),
    ('cog-11-ekoloji-qlobal', 'cog-11-ekoloji-qlobal-meiset-tullantilari',
     'Layihə:"Ailənin məişət tullantıları"', 100),
    ('cog-11-ekoloji-qlobal', 'cog-11-ekoloji-qlobal-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 110),
    --  6. BEYNELXALQ INTEQRASIYA VE QLOBALLASMA  (cog-11-inteqrasiya)
    ('cog-11-inteqrasiya', 'cog-11-inteqrasiya-diaqnostik-qiymetlendirme',
     'Diaqnostik qiymətləndirmə', 10),
    ('cog-11-inteqrasiya', 'cog-11-inteqrasiya-beynelxalq',
     'Beynəlxalq inteqrasiya', 20),
    --  6. BEYNELXALQ INTEQRASIYA VE QLOBALLASMA  (cog-11-qloballasma)
    ('cog-11-qloballasma', 'cog-11-qloballasma-beynelxalq-maliyye',
     'Beynəlxalq maliyyə mərkəzlərinin coğrafiyası', 10),
    ('cog-11-qloballasma', 'cog-11-qloballasma-azad-zonalar',
     'Azad iqtisadi zonalar', 20),
    ('cog-11-qloballasma', 'cog-11-qloballasma-dunyada-sulh',
     'Dünyada sülh problemi', 30),
    ('cog-11-qloballasma', 'cog-11-qloballasma-praktik-turk',
     'Praktik dərs. Türk dünyası birliyi', 40),
    ('cog-11-qloballasma', 'cog-11-qloballasma-konfrans-azerbaycanin',
     'Konfrans dərs. Azərbaycanın iqtisadi-mədəni əlaqələri', 50),
    ('cog-11-qloballasma', 'cog-11-qloballasma-umumilesdirici-sual',
     'Ümumiləşdirici sual və tapşırıqlar', 60)
  ) as v(parent_slug, slug, name, sort)
  join public.topics p on p.slug = v.parent_slug
   and p.subject_id = (select id from public.subjects where slug = 'cografiya')
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort,
      parent_id = excluded.parent_id, level_id = excluded.level_id;

do $$
declare k int;
begin
  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'cografiya'
    join public.levels   l on l.id = p.level_id and l.code = '6';
  if k <> 75 then
    raise exception 'cografiya 6-ci alt movzulari: 75 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'cografiya'
    join public.levels   l on l.id = p.level_id and l.code = '7';
  if k <> 79 then
    raise exception 'cografiya 7-ci alt movzulari: 79 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'cografiya'
    join public.levels   l on l.id = p.level_id and l.code = '8';
  if k <> 59 then
    raise exception 'cografiya 8-ci alt movzulari: 59 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'cografiya'
    join public.levels   l on l.id = p.level_id and l.code = '9';
  if k <> 62 then
    raise exception 'cografiya 9-cu alt movzulari: 62 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'cografiya'
    join public.levels   l on l.id = p.level_id and l.code = '10';
  if k <> 65 then
    raise exception 'cografiya 10-cu alt movzulari: 65 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'cografiya'
    join public.levels   l on l.id = p.level_id and l.code = '11';
  if k <> 66 then
    raise exception 'cografiya 11-ci alt movzulari: 66 gozlenilirdi, % tapildi', k;
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
    join public.subjects s on s.id = t.subject_id and s.slug = 'cografiya'
    join public.levels   l on l.id = t.level_id
   where t.parent_id is null and true;
  if k <> 46 then
    raise exception 'Cografiya ust movzu sayi 46 deyil: %', k;
  end if;

  raise notice 'Cografiya 6-11 (11-ci sinif enerji-erzaq hele bos): 406 alt movzu hazir.';
end $$;
