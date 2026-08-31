#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Umumi tarix 10 banki -> db/69_bank_tarix_umumi10.sql

    6 movzu x 31 sual = 186

Movzular 68_movzular_umumi_tarix10.sql agacina uygundur; agac
e-derslik portalindaki "Umumi tarix 10" (book_id 745) mundericatinin
4 bolmesinden cixir - iki en boyuk bolme ikiye bolunub, dorduncu
bolmenin oz "Medeniyyet" movzulari ayrica movzuda toplanib.

10-cu sinif TEKRAR (survey) kursudur: eyni dovrler 6-8-ci sinifde de
kecilir.  Ona gore sual yazanda ikiqat diqqet lazimdir - pg_trgm
tekrari umumi-tarix fenni uzre yoxlanilir.  Ferqlendirici:
10-cu sinif derslikde TURK ve SERQ dovletleri (Hun, Goyturk, Xezer,
Selcuq, Osmanli, Teymuri, Qizil Ordu, Boyuk Mogol), Rusiya ve
Otuzillik muharibe genis verilir - 6-8-ci sinifde bunlar demek olar
yoxdur.

CETINLIK BOLGUSU her movzuda:  4 asan + 15 orta + 12 cetin.

Isletmek:
    python3 tools/tarix_umumi10.py
    python3 tools/cetinlik_analiz.py utarix10
"""
import io
import os

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CIXIS = os.path.join(KOK, "db", "69_bank_tarix_umumi10.sql")

MOVZULAR = [
    ("utarix-10-qedim-serq",  1),
    ("utarix-10-antik",       1),
    ("utarix-10-erken-orta",  2),
    ("utarix-10-orta-esrler", 3),
    ("utarix-10-yeni-dovr",   4),
    ("utarix-10-medeniyyet",  4),
]

BOLGU = {1: 4, 2: 15, 3: 12}

SUALLAR = {}

HISSE_1 = {
"utarix-10-qedim-serq": [
 # ---- asan (4)
 ("Böyük Hun dövlətinin ən məşhur xaqanı kim olmuşdur?",
  "Böyük Hun dövlətinin ən məşhur xaqanı Mete olmuşdur.",
  ["Mete xaqan", "Sarqon", "Aşoka", "Ramzes II"], 1, None, 1),
 ("Qədim Misirdə dövlət başçısı hansı adla tanınırdı?",
  "Qədim Misirdə dövlət başçısı firon adlanırdı.",
  ["Firon", "Satrap", "Konsul", "Xaqan"], 1, None, 1),
 ("Hammurapi qanunları hansı dövlətdə tərtib olunmuşdur?",
  "Hammurapi qanunları Babil dövlətində tərtib olunmuşdur.",
  ["Babildə", "Misirdə", "Çində", "Makedoniyada"], 1, None, 1),
 ("Qədim Hindistanda yaranan dünya dini hansıdır?",
  "Qədim Hindistanda buddizm dini yaranmışdır.",
  ["Buddizm", "Xristianlıq", "İslam", "Sinto"], 1, None, 1),

 # ---- orta (15)
 ("Mete xaqan Böyük Hun dövlətində hakimiyyətə hansı ildə gəlmişdir?",
  "Mete xaqan e.ə. 209-cu ildə hakimiyyətə gəlmişdir.",
  ["E.ə. 209-cu ildə", "E.ə. 330-cu ildə",
   "E.ə. 27-ci ildə", "Eramızın 476-cı ilində"], 1, None, 2),
 ("Mete xaqanın ordunu bölüşdürdüyü hərbi quruluş necə adlanır?",
  "Mete ordunu onluq sistemlə - on, yüz, min və tümən hissələrinə bölmüşdü.",
  ["Onluq sistem", "Satraplıq sistemi", "Timar sistemi", "Kasta sistemi"], 1, None, 2),
 ("Çin torpaqlarını vahid imperiyada birləşdirən hökmdar kimdir?",
  "Çin torpaqlarını Sin Şi Huandi vahid imperiyada birləşdirmişdir.",
  ["Sin Şi Huandi", "Mete xaqan", "Dara I", "Sarqon"], 1, None, 2),
 ("Əhəməni imperiyasında inzibati vahidlər hansı adla tanınırdı?",
  "Əhəməni imperiyası satraplıq adlanan inzibati vahidlərə bölünmüşdü.",
  ["Satraplıq", "Polis", "Knyazlıq", "Vilayət şurası"], 1, None, 2),
 ("Əhəməni imperiyasına son qoyan sərkərdə kimdir?",
  "Əhəməni imperiyasına Makedoniyalı İskəndərin yürüşü son qoymuşdur.",
  ["Makedoniyalı İskəndər", "Hannibal", "Mete xaqan", "Yuli Sezar"], 1, None, 2),
 ("Qədim İranda yayılmış zərdüştiliyin müqəddəs kitabı hansıdır?",
  "Zərdüştiliyin müqəddəs kitabı «Avesta»dır.",
  ["«Avesta»", "«Talmud»", "«İliada»", "«Ramayana»"], 1, None, 2),
 ("Hindistanda Maurya dövlətinin ən tanınmış hökmdarı kimdir?",
  "Maurya dövlətinin ən tanınmış hökmdarı Aşoka olmuşdur.",
  ["Aşoka", "Kir II", "Navuxodonosor", "Tutmos III"], 1, None, 2),
 ("Aşoka hansı dini dövlət səviyyəsində himayə edirdi?",
  "Aşoka buddizmi dövlət səviyyəsində himayə edirdi.",
  ["Buddizmi", "Zərdüştiliyi", "Xristianlığı", "Konfutsiçiliyi"], 1, None, 2),
 ("Qədeş döyüşü hansı iki dövlət arasında baş vermişdir?",
  "Qədeş döyüşü Misir ilə Het dövləti arasında baş vermişdir.",
  ["Misir və Het dövləti", "Babil və Assuriya",
   "Çin və Hindistan", "Makedoniya və Karfagen"], 1, None, 2),
 ("Mesopotamiyada Akkad dövlətinin əsasını kim qoymuşdur?",
  "Akkad dövlətinin əsasını Sarqon qoymuşdur.",
  ["Sarqon", "Hammurapi", "Aşoka", "Mete xaqan"], 1, None, 2),
 ("Yeni Babil dövlətinin ən məşhur hökmdarı kimdir?",
  "Yeni Babil dövlətinin ən məşhur hökmdarı II Navuxodonosordur.",
  ["II Navuxodonosor", "Sin Şi Huandi", "Ramzes II", "Kir II"], 1, None, 2),
 ("Assuriya dövləti Mesopotamiyanın hansı hissəsində yerləşirdi?",
  "Assuriya dövləti Mesopotamiyanın şimal hissəsində yerləşirdi.",
  ["Şimal hissəsində", "Cənub sahillərində",
   "Şərq dağlarında", "Qərb səhralarında"], 1, None, 2),
 ("Neolit inqilabı dedikdə nə başa düşülür?",
  "Neolit inqilabı yığıcılıq və ovçuluqdan əkinçilik və maldarlığa keçidi bildirir.",
  ["Əkinçilik və maldarlığa keçid", "Dəmir alətlərin kəşfi",
   "Şəhər dövlətlərinin süqutu", "Yazının unudulması"], 1, None, 2),
 ("İnsanların əmək alətləri üçün istifadə etdiyi ilk metal hansıdır?",
  "İnsanlar ilk dəfə misdən istifadə etməyə başlamışlar.",
  ["Mis", "Dəmir", "Alüminium", "Nikel"], 1, None, 2),
 ("Kuşan imperiyası əsasən hansı ərazidə mövcud olmuşdur?",
  "Kuşan imperiyası Şimali Hindistan və Orta Asiya ərazisində mövcud olmuşdur.",
  ["Şimali Hindistan və Orta Asiyada", "Şimali Afrikada",
   "Balkan yarımadasında", "Britaniya adalarında"], 1, None, 2),

 # ---- cetin (12)
 ("Aşağıdakı hadisələri xronoloji ardıcıllıqla düzün: 1. Mete xaqanın hakimiyyətə gəlməsi 2. Çinin vahid imperiyada birləşdirilməsi 3. Əhəməni imperiyasının süqutu",
  "Əhəməni imperiyası e.ə. 330-cu ildə, Çinin birləşdirilməsi e.ə. 221-ci ildə, Metenin hakimiyyətə gəlməsi isə e.ə. 209-cu ildə olmuşdur.",
  ["3 - 2 - 1", "1 - 2 - 3", "2 - 3 - 1", "3 - 1 - 2"], 1, None, 3),
 ("Qədim Şərq üçün «hökmdar - dövlət» uyğunluğu hansı sırada düzgün verilmişdir?",
  "Mete Böyük Hun dövlətinin, Aşoka Mauryanın, Sarqon Akkadın, Dara I isə Əhəmənilərin hökmdarıdır.",
  ["Mete - Böyük Hun dövləti", "Aşoka - Əhəməni imperiyası",
   "Sarqon - Maurya dövləti", "Dara I - Akkad dövləti"], 1, None, 3),
 ("Qədim Şərq sivilizasiyaları haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "Hammurapi qanunları Misirdə deyil, Babil dövlətində tərtib olunmuşdur.",
  ["Hammurapi qanunları Misirdə tərtib olunmuşdur",
   "Əhəməni imperiyası satraplıqlara bölünmüşdü",
   "Aşoka buddizmi himayə edirdi",
   "Mete xaqan orduda onluq sistem tətbiq etmişdi"], 1, None, 3),
 ("Böyük Çin səddinin şimal sərhədi boyunca ucaldılmasının başlıca səbəbi nə idi?",
  "Sədd şimaldan gələn hun süvari dəstələrinin basqınlarının qarşısını almaq üçün ucaldılmışdı.",
  ["Hun basqınlarının qarşısını almaq", "Karvan yollarını qısaltmaq",
   "Şəhərləri daşqından qorumaq", "Məbədləri bir yerə toplamaq"], 1, None, 3),
 ("Mete xaqanın hərbi islahatının mahiyyətini düzgün göstərən fikir hansıdır?",
  "O, ordunu onluq bölmələrə ayıraraq hər bölməni birbaşa mərkəzi hakimiyyətə tabe etmişdi.",
  ["Ordu onluq bölmələrə ayrılıb mərkəzə tabe edilmişdi",
   "Ordu tayfa başçılarının sərəncamına verilmişdi",
   "Süvari qoşundan tamam imtina olunmuşdu",
   "Hərbi xidmət yalnız əcnəbilərə həvalə edilmişdi"], 1, None, 3),
 ("Əhəməni satraplıq sistemi ilə Hun onluq sisteminin başlıca fərqi nədir?",
  "Satraplıq ərazi üzrə mülki-inzibati bölgü, onluq sistem isə ordunun say üzrə hərbi quruluşudur.",
  ["Biri ərazi-inzibati, digəri hərbi bölgüdür",
   "Biri dini, digəri ticarət təşkilatıdır",
   "Biri məhkəmə, digəri məktəb sistemidir",
   "Hər ikisi yalnız vergi toplamaq üçün idi"], 1, None, 3),
 ("Hammurapi qanunlarının dünya tarixi üçün əhəmiyyətini düzgün göstərən fikir hansıdır?",
  "Bu qanunlar yazılı hüquq normalarının bizə gəlib çatmış ən dolğun erkən nümunəsidir.",
  ["Yazılı hüquq normalarının erkən dolğun nümunəsidir",
   "İlk əlifba sistemini ortaya qoymuşdur",
   "Buddizmin əsas müddəalarını toplamışdır",
   "Satraplıq bölgüsünü müəyyən etmişdir"], 1, None, 3),
 ("Neolit inqilabının cəmiyyət quruluşuna təsirini düzgün göstərən fikir hansıdır?",
  "Oturaq həyata keçid artıq məhsul yaratdı, bu isə əmlak bərabərsizliyinə yol açdı.",
  ["Oturaq həyat, artıq məhsul və əmlak bərabərsizliyi yarandı",
   "Əhali tamam köçəri həyata qayıtdı",
   "İcma daxilində əmək bölgüsü aradan qalxdı",
   "Metal alətlərdən istifadə dayandırıldı"], 1, None, 3),
 ("Qədim Şərq dövlətləri haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "Akkad dövlətinin banisi Navuxodonosor deyil, Sarqondur; Navuxodonosor Yeni Babil hökmdarıdır.",
  ["Akkad dövlətinin banisi Navuxodonosordur",
   "Assuriya Mesopotamiyanın şimalında yerləşirdi",
   "Kuşan imperiyası Orta Asiyanı da əhatə edirdi",
   "Qədeş döyüşü Misirlə Het dövləti arasında olmuşdur"], 1, None, 3),
 ("Böyük Hun dövlətinin şimal və cənub hissələrinə parçalanmasının nəticəsi nə oldu?",
  "Parçalanmadan sonra dövlət zəiflədi, cənub hunları isə Çin təsiri altına düşdü.",
  ["Dövlət zəiflədi, hunların bir hissəsi Çindən asılı oldu",
   "Dövlətin ərazisi daha da genişləndi",
   "Çin imperiyası hunlara xərac verməyə başladı",
   "Hunlar Hindistanı bütövlükdə ələ keçirdilər"], 1, None, 3),
 ("Qədim Şərqdə İpək yolunun açılmasının uzunmüddətli nəticəsini düzgün göstərən fikir hansıdır?",
  "Yol yalnız mal deyil, texnologiya, din və yazı sistemlərinin də Şərqlə Qərb arasında yayılmasını təmin etdi.",
  ["Mallarla yanaşı bilik və dinlər də yayıldı",
   "Ölkələr arasında əlaqə tamam kəsildi",
   "Yalnız hərbi yürüşlər üçün istifadə olundu",
   "Dəniz ticarətini əvəz edə bilmədi"], 1, None, 3),
 ("Aşokanın buddizmi himayə etməsinin dövlət üçün əhəmiyyəti nə idi?",
  "Ortaq din geniş və çoxdilli imperiyada birləşdirici amilə çevrildi.",
  ["Çoxdilli imperiyada birləşdirici amil oldu",
   "Ordunun sayını iki dəfə artırdı",
   "Kasta bölgüsünü tam ləğv etdi",
   "Ticarət yollarını bağladı"], 1, None, 3)],

"utarix-10-antik": [
 # ---- asan (4)
 ("Qədim dünyada demokratik idarəçilik hansı yunan şəhərində formalaşmışdır?",
  "Demokratik idarəçilik Afinada formalaşmışdır.",
  ["Afinada", "Spartada", "Karfagendə", "Babildə"], 1, None, 1),
 ("Makedoniyalı İskəndərin atası kim olmuşdur?",
  "Makedoniyalı İskəndərin atası II Filipp olmuşdur.",
  ["II Filipp", "Perikl", "Solon", "Hannibal"], 1, None, 1),
 ("Roma imperiyasının ilk imperatoru kim sayılır?",
  "Roma imperiyasının ilk imperatoru Avqust sayılır.",
  ["Avqust", "Yuli Sezar", "Konstantin", "Dara III"], 1, None, 1),
 ("Roma respublikasında ali məşvərət orqanı hansı idi?",
  "Roma respublikasında ali məşvərət orqanı senat idi.",
  ["Senat", "Xalq yığıncağı", "Areopaq", "Parlament"], 1, None, 1),

 # ---- orta (15)
 ("Yunan sivilizasiyasının ən erkən mərkəzləri hansılardır?",
  "Yunan sivilizasiyasının ən erkən mərkəzləri Krit və Miken olmuşdur.",
  ["Krit və Miken", "Karfagen və Numidiya",
   "Babil və Assuriya", "Sparta və Korinf"], 1, None, 2),
 ("Afinada ilk geniş ictimai islahatları kim həyata keçirmişdir?",
  "Afinada ilk geniş islahatları Solon həyata keçirmişdir.",
  ["Solon", "Perikl", "II Filipp", "Avqust"], 1, None, 2),
 ("Afina demokratiyasının çiçəklənmə dövrü kimin adı ilə bağlıdır?",
  "Afina demokratiyasının çiçəklənməsi Periklin adı ilə bağlıdır.",
  ["Perikl", "Solon", "Hannibal", "Konstantin"], 1, None, 2),
 ("II Filipp yunan polislərini hansı döyüşdə məğlub etmişdir?",
  "II Filipp yunan polislərini Xeroneya döyüşündə məğlub etmişdir.",
  ["Xeroneya döyüşündə", "Kann döyüşündə",
   "Qavqamela döyüşündə", "Marafon döyüşündə"], 1, None, 2),
 ("Makedoniyalı İskəndər Əhəmənilər üzərində həlledici qələbəni harada qazanmışdır?",
  "Həlledici qələbə Qavqamela döyüşündə qazanılmışdır.",
  ["Qavqamela döyüşündə", "Xeroneya döyüşündə",
   "Fermopil keçidində", "Nesbi döyüşündə"], 1, None, 2),
 ("İskəndərin yürüşlərindən sonra formalaşan mədəniyyət necə adlanır?",
  "Yunan və Şərq mədəniyyətlərinin qovuşmasından yaranan dövr ellinizm adlanır.",
  ["Ellinizm", "Sxolastika", "İntibah", "Romanizm"], 1, None, 2),
 ("Puni müharibələri Roma ilə hansı dövlət arasında gedirdi?",
  "Puni müharibələri Roma ilə Karfagen arasında gedirdi.",
  ["Karfagenlə", "Misirlə", "Makedoniya ilə", "Babillə"], 1, None, 2),
 ("Kann döyüşündə Roma ordusunu kim məğlub etmişdir?",
  "Kann döyüşündə Roma ordusunu Hannibal məğlub etmişdir.",
  ["Hannibal", "II Filipp", "Perikl", "Sarqon"], 1, None, 2),
 ("Roma respublikasının süqutu hansı sərkərdənin adı ilə bağlıdır?",
  "Respublikanın süqutu Yuli Sezarın adı ilə bağlıdır.",
  ["Yuli Sezar", "Solon", "Aşoka", "Hannibal"], 1, None, 2),
 ("Milan ediktı ilə Roma imperiyasında nə tanındı?",
  "Milan ediktı ilə xristianlığın sərbəst yayılmasına icazə verildi.",
  ["Xristianlığın sərbəst yayılması", "Qulların azad edilməsi",
   "Senatın ləğvi", "Yeni vergi sisteminin qurulması"], 1, None, 2),
 ("Roma imperiyası hansı ildə Qərb və Şərq hissələrinə bölünmüşdür?",
  "Roma imperiyası 395-ci ildə iki hissəyə bölünmüşdür.",
  ["395-ci ildə", "313-cü ildə", "476-cı ildə", "1453-cü ildə"], 1, None, 2),
 ("Qərbi Roma imperiyası hansı ildə süqut etmişdir?",
  "Qərbi Roma imperiyası 476-cı ildə süqut etmişdir.",
  ["476-cı ildə", "395-ci ildə", "800-cü ildə", "1066-cı ildə"], 1, None, 2),
 ("Sparta idarəçiliyinin səciyyəvi cəhəti nə idi?",
  "Spartada eyni vaxtda iki çar hökm sürür, idarəçilik hərbi aristokratiyanın əlində olurdu.",
  ["İki çarlı hərbi aristokratiya", "Seçkili prezident idarəçiliyi",
   "Kahinlərin tam hakimiyyəti", "Ticarət gildiyalarının hakimiyyəti"], 1, None, 2),
 ("Roma respublikasında ali icra vəzifəsi necə adlanırdı?",
  "Roma respublikasında ali icra vəzifəsi konsul adlanırdı.",
  ["Konsul", "Satrap", "Arxont", "Xaqan"], 1, None, 2),
 ("Roma hüququnun sonrakı dövrlər üçün əhəmiyyəti nədir?",
  "Roma hüququ Avropa hüquq sistemlərinin əsasını təşkil etmişdir.",
  ["Avropa hüquq sistemlərinin əsası olmuşdur",
   "Yazının ilk nümunəsini vermişdir",
   "Xristianlığı qadağan etmişdir",
   "Ticarəti tamam dayandırmışdır"], 1, None, 2),

 # ---- cetin (12)
 ("Aşağıdakı hadisələri xronoloji ardıcıllıqla düzün: 1. Qərbi Roma imperiyasının süqutu 2. Xeroneya döyüşü 3. Roma imperiyasının qurulması",
  "Xeroneya döyüşü e.ə. 338, Roma imperiyasının qurulması e.ə. 27, Qərbi Romanın süqutu isə 476-cı ilə aiddir.",
  ["2 - 3 - 1", "1 - 2 - 3", "3 - 2 - 1", "2 - 1 - 3"], 1, None, 3),
 ("Antik dövr üçün «döyüş - qarşı-qarşıya duran tərəflər» uyğunluğu hansı sırada düzgündür?",
  "Qavqamelada İskəndər Dara III ilə, Xeroneyada Makedoniya yunan polisləri ilə, Kannda isə Roma Karfagenlə üzləşmişdi.",
  ["Qavqamela - İskəndər və Dara III", "Xeroneya - Roma və Karfagen",
   "Kann - Afina və Sparta", "Marafon - Makedoniya və Hindistan"], 1, None, 3),
 ("Antik dünya haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "Roma imperiyasının ilk imperatoru Hannibal deyil, Avqustdur; Hannibal Karfagen sərkərdəsi olmuşdur.",
  ["Roma imperiyasının ilk imperatoru Hannibal olmuşdur",
   "Afina demokratiyası Periklin dövründə çiçəklənmişdir",
   "Ellinizm yunan və Şərq mədəniyyətlərinin qovuşmasıdır",
   "Qərbi Roma 476-cı ildə süqut etmişdir"], 1, None, 3),
 ("Puni müharibələrinin Roma üçün başlıca nəticəsi nə oldu?",
  "Karfagenin məğlubiyyətindən sonra Roma Aralıq dənizi hövzəsində hakim dövlətə çevrildi.",
  ["Aralıq dənizi hövzəsində hakim dövlətə çevrildi",
   "Öz dəniz üstünlüyünü itirdi",
   "Şərqə bütün yürüşlərdən əl çəkdi",
   "Karfagenlə ittifaq müqaviləsi bağladı"], 1, None, 3),
 ("Afina ilə Spartanın idarə formalarını düzgün müqayisə edən fikir hansıdır?",
  "Afinada qərarları vətəndaşların xalq yığıncağı verirdi, Spartada isə hakimiyyət hərbi aristokratiyanın əlində idi.",
  ["Afinada xalq yığıncağı, Spartada hərbi aristokratiya həlledici idi",
   "Hər ikisində hakimiyyət kahinlərə məxsus idi",
   "Afinada iki çar, Spartada bir arxont hakim idi",
   "Hər ikisində hökmdar irsi qaydada dəyişirdi"], 1, None, 3),
 ("Aşağıdakı hadisələrdən hansı digərlərindən əvvəl baş vermişdir?",
  "Xeroneya döyüşü e.ə. 338, Qavqamela e.ə. 331, İskəndərin ölümü e.ə. 323, Roma imperiyasının qurulması isə e.ə. 27-ci ilə aiddir.",
  ["Xeroneya döyüşü", "Qavqamela döyüşü",
   "Makedoniyalı İskəndərin ölümü", "Roma imperiyasının qurulması"], 1, None, 3),
 ("Antik dövr üçün «şəxs - fəaliyyət sahəsi» uyğunluğu hansı sırada düzgündür?",
  "Solon Afinada islahat keçirmiş, Hannibal Karfagen ordusuna başçılıq etmiş, Avqust isə imperiyanı qurmuşdur.",
  ["Solon - Afinada islahatlar", "Hannibal - Afinada islahatlar",
   "Avqust - Karfagen ordusunun başçısı", "Perikl - Makedoniya ordusunun başçısı"], 1, None, 3),
 ("Ellinizm dövrünün mahiyyətini düzgün göstərən fikir hansıdır?",
  "Ellinizm yunan mədəniyyəti ilə Şərq ənənələrinin qarşılıqlı təsirdə qovuşduğu dövrdür.",
  ["Yunan və Şərq mədəniyyətlərinin qovuşması dövrüdür",
   "Yunan mədəniyyətinin tam unudulması dövrüdür",
   "Şərq dillərinin Avropada qadağan olunması dövrüdür",
   "Roma hüququnun formalaşdığı dövrdür"], 1, None, 3),
 ("Antik dövr haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "İskəndər Əhəmənilər üzərində həlledici qələbəni Xeroneyada deyil, Qavqamelada qazanmışdır; Xeroneyada yunan polisləri məğlub olmuşdu.",
  ["İskəndər Əhəmənilər üzərində qələbəni Xeroneyada qazanmışdır",
   "Milan ediktı xristianlığa sərbəstlik verdi",
   "Roma imperiyası 395-ci ildə ikiyə bölündü",
   "Puni müharibələri Roma ilə Karfagen arasında getmişdir"], 1, None, 3),
 ("Roma imperiyasının 395-ci ildə bölünməsinin uzunmüddətli nəticəsi nə oldu?",
  "Qərb hissəsi tezliklə süqut etdi, Şərq hissəsi isə Bizans adı ilə min ilə yaxın davam etdi.",
  ["Şərq hissəsi Bizans kimi uzun müddət yaşadı",
   "Hər iki hissə eyni vaxtda süqut etdi",
   "İmperiya bir əsr sonra yenidən birləşdi",
   "Qərb hissəsi Bizansı özünə tabe etdi"], 1, None, 3),
 ("Milan ediktının qəbulunun Roma dövləti üçün əhəmiyyəti nə idi?",
  "Təqib olunan xristianlıq qanuni dinə çevrildi və dövlətlə kilsə arasında yaxınlaşma başladı.",
  ["Xristianlıq qanuniləşdi, dövlətlə kilsə yaxınlaşdı",
   "Bütün qədim məbədlər dağıdıldı",
   "Senatın səlahiyyətləri genişləndirildi",
   "İmperiya paytaxtı Karfagenə köçürüldü"], 1, None, 3),
 ("Romada respublikadan imperiyaya keçidin başlıca səbəbini düzgün göstərən fikir hansıdır?",
  "Genişlənmiş ərazini və çoxsaylı ordunu köhnə respublika orqanları idarə edə bilmirdi.",
  ["Genişlənmiş dövləti respublika orqanları idarə edə bilmirdi",
   "Senat özünü könüllü buraxmışdı",
   "Xarici işğal ölkəni bütövlükdə tutmuşdu",
   "Əhali imperator hakimiyyətini səsvermə ilə seçmişdi"], 1, None, 3)],
}
SUALLAR.update(HISSE_1)

HISSE_2 = {
"utarix-10-erken-orta": [
 # ---- asan (4)
 ("Avropa Hun dövlətinin ən məşhur hökmdarı kim olmuşdur?",
  "Avropa Hun dövlətinin ən məşhur hökmdarı Atilla olmuşdur.",
  ["Atilla", "Bumın xaqan", "Xlodviq", "Yustinian"], 1, None, 1),
 ("Göytürk xaqanlığının əsasını kim qoymuşdur?",
  "Göytürk xaqanlığının əsasını Bumın xaqan qoymuşdur.",
  ["Bumın xaqan", "Batı xan", "Sultan Mahmud", "Kiril"], 1, None, 1),
 ("Bizans imperiyası hansı şəhərdən idarə olunurdu?",
  "Bizans imperiyasının paytaxtı Konstantinopol idi.",
  ["Konstantinopol", "Dəməşq", "Bağdad", "Səmərqənd"], 1, None, 1),
 ("Frank dövlətini imperiyaya çevirən hökmdar kimdir?",
  "Frank dövləti Karl Böyükün dövründə imperiyaya çevrilmişdir.",
  ["Karl Böyük", "Atilla", "Tonyukuk", "I Xosrov"], 1, None, 1),

 # ---- orta (15)
 ("Göytürk xaqanlığı hansı ildə qurulmuşdur?",
  "Göytürk xaqanlığı 552-ci ildə qurulmuşdur.",
  ["552-ci ildə", "744-cü ildə", "800-cü ildə", "1055-ci ildə"], 1, None, 2),
 ("Göytürklərdən qalan daş üzərindəki yazılı abidələr necə adlanır?",
  "Bu abidələr Orxon-Yenisey abidələri adlanır.",
  ["Orxon-Yenisey abidələri", "Rozetta daşı",
   "Behistun kitabəsi", "Kann lövhələri"], 1, None, 2),
 ("Göytürk abidələrində müdrik dövlət xadimi kimi anılan şəxs kimdir?",
  "Göytürk abidələrində müdrik dövlət xadimi kimi Tonyukuk anılır.",
  ["Tonyukuk", "Nizamülmülk", "Mefodi", "Sarqon"], 1, None, 2),
 ("Uyğur xaqanlığı hansı ildə qurulmuşdur?",
  "Uyğur xaqanlığı 744-cü ildə qurulmuşdur.",
  ["744-cü ildə", "552-ci ildə", "651-ci ildə", "843-cü ildə"], 1, None, 2),
 ("Xəzər xaqanlığı əsasən hansı ərazidə mövcud olmuşdur?",
  "Xəzər xaqanlığı Şimali Qafqaz və Volqaboyu ərazilərində mövcud olmuşdur.",
  ["Şimali Qafqaz və Volqaboyunda", "Britaniya adalarında",
   "Şimali Afrikada", "Yapon adalarında"], 1, None, 2),
 ("Sasani dövləti hansı ildə süqut etmişdir?",
  "Sasani dövləti 651-ci ildə süqut etmişdir.",
  ["651-ci ildə", "476-cı ildə", "762-ci ildə", "843-cü ildə"], 1, None, 2),
 ("Sasani hökmdarı I Xosrov nə ilə tarixdə qalmışdır?",
  "I Xosrov inzibati və vergi islahatları ilə tarixdə qalmışdır.",
  ["İnzibati və vergi islahatları ilə", "Amerikanın kəşfi ilə",
   "Xaçlı yürüşləri ilə", "Mətbəənin ixtirası ilə"], 1, None, 2),
 ("Əməvilər xilafətinin paytaxtı hansı şəhər olmuşdur?",
  "Əməvilər xilafətinin paytaxtı Dəməşq olmuşdur.",
  ["Dəməşq", "Bağdad", "Qahirə", "Buxara"], 1, None, 2),
 ("Abbasilər xilafətinin paytaxtı kimi salınan şəhər hansıdır?",
  "Abbasilər xilafətinin paytaxtı kimi Bağdad şəhəri salınmışdır.",
  ["Bağdad", "Dəməşq", "Konstantinopol", "Səmərqənd"], 1, None, 2),
 ("Bizans imperatoru Yustinianın tikdirdiyi ən məşhur məbəd hansıdır?",
  "Yustinianın tikdirdiyi ən məşhur məbəd Ayasofyadır.",
  ["Ayasofya", "Notr-Dam", "Parfenon", "Kolizey"], 1, None, 2),
 ("Yustinianın göstərişi ilə hazırlanan hüquq toplusu necə adlanır?",
  "Bu toplu mülki hüquq məcəlləsi kimi tanınır.",
  ["Mülki hüquq məcəlləsi", "Böyük azadlıq fərmanı",
   "Hammurapi qanunları", "Siyasətnamə"], 1, None, 2),
 ("Slavyan xalqları üçün əlifba yaradan qardaşlar kimlərdir?",
  "Slavyan əlifbasını Kiril və Mefodi qardaşları yaratmışdır.",
  ["Kiril və Mefodi", "Bumın və İstəmi", "Osman və Orxan", "Kir və Dara"], 1, None, 2),
 ("Tarixdə ilk müsəlman türk dövləti hansı sayılır?",
  "Tarixdə ilk müsəlman türk dövləti Qaraxanlılar sayılır.",
  ["Qaraxanlılar", "Göytürklər", "Uyğurlar", "Xəzərlər"], 1, None, 2),
 ("Qəznəli dövlətinin ən güclü hökmdarı kim olmuşdur?",
  "Qəznəli dövlətinin ən güclü hökmdarı Sultan Mahmud olmuşdur.",
  ["Sultan Mahmud", "Toğrul bəy", "Batı xan", "Karl Böyük"], 1, None, 2),
 ("Kataloniya düzündəki döyüş hansı hökmdarın yürüşü ilə bağlıdır?",
  "Kataloniya düzündəki döyüş Atillanın Qərbə yürüşü ilə bağlıdır.",
  ["Atillanın", "Yustinianın", "Xlodviqin", "Sultan Mahmudun"], 1, None, 2),

 # ---- cetin (12)
 ("Aşağıdakı hadisələri xronoloji ardıcıllıqla düzün: 1. Abbasilər xilafətinin qurulması 2. Göytürk xaqanlığının yaranması 3. Karl Böyükün imperator elan olunması",
  "Göytürk xaqanlığı 552-ci ildə, Abbasilər 750-ci ildə, Karl Böyük isə 800-cü ildə imperator elan olunmuşdur.",
  ["2 - 1 - 3", "1 - 2 - 3", "3 - 2 - 1", "2 - 3 - 1"], 1, None, 3),
 ("III-XI yüzilliklər üçün «dövlət - paytaxt» uyğunluğu hansı sırada düzgündür?",
  "Bağdad Abbasilərin, Dəməşq Əməvilərin, Konstantinopol isə Bizansın paytaxtı olmuşdur.",
  ["Abbasilər xilafəti - Bağdad", "Əməvilər xilafəti - Bağdad",
   "Bizans imperiyası - Dəməşq", "Frank dövləti - Konstantinopol"], 1, None, 3),
 ("III-XI yüzilliklərin tarixi haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "Slavyan əlifbasını Bumın xaqan deyil, Kiril və Mefodi qardaşları yaratmışdır.",
  ["Slavyan əlifbasını Bumın xaqan yaratmışdır",
   "Göytürk xaqanlığı 552-ci ildə qurulmuşdur",
   "Sasani dövləti 651-ci ildə süqut etmişdir",
   "Ayasofya Yustinianın dövründə tikilmişdir"], 1, None, 3),
 ("Xalqların böyük köçünün Qərbi Avropa üçün nəticəsini düzgün göstərən fikir hansıdır?",
  "Köç Qərbi Roma imperiyasının süqutunu tezləşdirdi, onun yerində barbar krallıqları yarandı.",
  ["Qərbi Roma süqut etdi, yerində yeni krallıqlar yarandı",
   "Roma imperiyası bütövlükdə möhkəmləndi",
   "Avropada şəhər həyatı sürətlə çiçəkləndi",
   "Bizans imperiyası dağıldı"], 1, None, 3),
 ("Göytürk və Uyğur xaqanlıqlarının bir-biri ilə əlaqəsini düzgün göstərən fikir hansıdır?",
  "Uyğur xaqanlığı Göytürk xaqanlığının süqutundan sonra həmin ərazidə qurulmuşdur.",
  ["Uyğurlar Göytürklərin ərazisində, onlardan sonra dövlət qurdular",
   "Uyğurlar Göytürklərdən əvvəl dövlət qurmuşdular",
   "İki xaqanlıq eyni vaxtda mövcud olmuşdur",
   "Uyğurlar Bizans ərazisində dövlət qurmuşdular"], 1, None, 3),
 ("III-XI yüzilliklərin hansı hadisəsi digərlərindən əvvəl olmuşdur?",
  "Əməvilər 661-ci ildə, Uyğur xaqanlığı 744-cü ildə, Abbasilər 750-ci ildə, Bağdad isə 762-ci ildə salınmışdır.",
  ["Əməvilərin hakimiyyətə gəlməsi", "Uyğur xaqanlığının qurulması",
   "Abbasilərin hakimiyyətə gəlməsi", "Bağdad şəhərinin salınması"], 1, None, 3),
 ("III-XI yüzilliklər üçün «hökmdar - gördüyü iş» uyğunluğu hansı sırada düzgündür?",
  "I Xosrov vergi islahatı aparmış, Yustinian hüquq toplusu hazırlatmış, Karl Böyük isə imperator elan olunmuşdur.",
  ["I Xosrov - vergi islahatı", "Yustinian - Bağdadın salınması",
   "Karl Böyük - mülki hüquq məcəlləsi", "Sultan Mahmud - slavyan əlifbası"], 1, None, 3),
 ("Orxon-Yenisey abidələrinin tarixi əhəmiyyətini düzgün göstərən fikir hansıdır?",
  "Abidələr həm türk dilinin ən qədim yazılı nümunəsi, həm də dövrün siyasi salnaməsidir.",
  ["Türk dilinin ən qədim yazısı və dövrün salnaməsidir",
   "Bizans hüququnun əsas mənbəyidir",
   "Ərəb riyaziyyatının ilk kitabıdır",
   "Slavyan əlifbasının ilk nümunəsidir"], 1, None, 3),
 ("Ərəb xilafətində Əməvilərdən Abbasilərə keçidin mahiyyətini düzgün göstərən fikir hansıdır?",
  "Hakimiyyət mərkəzi Suriyadan İraqa keçdi, idarəçilikdə qeyri-ərəb müsəlmanların rolu artdı.",
  ["Mərkəz İraqa keçdi, qeyri-ərəblərin rolu artdı",
   "Xilafət xristian dövlətinə çevrildi",
   "Xilafətin paytaxtı Konstantinopola köçürüldü",
   "Ərəb dili dövlət işlərindən çıxarıldı"], 1, None, 3),
 ("Erkən orta əsrlərdə Bizansı Qərbi Avropadan fərqləndirən başlıca cəhət nə idi?",
  "Bizansda güclü mərkəzi hakimiyyət, şəhər həyatı və pul təsərrüfatı davam edirdi.",
  ["Mərkəzi hakimiyyət və şəhər həyatı davam edirdi",
   "Ölkədə yazı və kitab istifadədən çıxmışdı",
   "İmperator hakimiyyəti seçki ilə müəyyən olunurdu",
   "Xristianlıq qadağan edilmişdi"], 1, None, 3),
 ("Erkən orta əsr türk dövlətləri haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "İlk müsəlman türk dövləti Göytürk xaqanlığı deyil, Qaraxanlılar dövlətidir.",
  ["İlk müsəlman türk dövləti Göytürk xaqanlığıdır",
   "Uyğur xaqanlığı 744-cü ildə qurulmuşdur",
   "Xəzər xaqanlığı Volqaboyunda mövcud olmuşdur",
   "Qəznəlilərin ən güclü hökmdarı Sultan Mahmud idi"], 1, None, 3),
 ("Karl Böyükün 800-cü ildə imperator elan olunmasının siyasi mənası nə idi?",
  "Qərbdə Roma imperiya ənənəsinin bərpasına iddia irəli sürülür, papa ilə ittifaq möhkəmlənirdi.",
  ["Qərbdə Roma imperiya ənənəsinə iddia irəli sürüldü",
   "Bizans imperiyası ləğv edildi",
   "Frank dövləti xilafətə tabe oldu",
   "Avropada respublika quruluşu bərqərar oldu"], 1, None, 3)],

"utarix-10-orta-esrler": [
 # ---- asan (4)
 ("Osmanlı dövlətinin əsasını kim qoymuşdur?",
  "Osmanlı dövlətinin əsasını Osman bəy qoymuşdur.",
  ["Osman bəy", "Toğrul bəy", "Batı xan", "Uluqbəy"], 1, None, 1),
 ("Monqol imperiyasının banisi kim olmuşdur?",
  "Monqol imperiyasının banisi Çingiz xan olmuşdur.",
  ["Çingiz xan", "Əmir Teymur", "Alp Arslan", "Salahəddin Əyyubi"], 1, None, 1),
 ("Konstantinopolu 1453-cü ildə hansı Osmanlı sultanı almışdır?",
  "Konstantinopolu Fateh Sultan Mehmet almışdır.",
  ["Fateh Sultan Mehmet", "İldırım Bəyazid", "Osman bəy", "Məlikşah"], 1, None, 1),
 ("Əmir Teymur dövlətinin paytaxtı hansı şəhər idi?",
  "Əmir Teymur dövlətinin paytaxtı Səmərqənd idi.",
  ["Səmərqənd", "Bağdad", "Dehli", "Kiyev"], 1, None, 1),

 # ---- orta (15)
 ("Böyük Səlcuq dövlətinin əsasını kim qoymuşdur?",
  "Böyük Səlcuq dövlətinin əsasını Toğrul bəy qoymuşdur.",
  ["Toğrul bəy", "Osman bəy", "Çingiz xan", "Sultan Mahmud"], 1, None, 2),
 ("Dandanakan döyüşü hansı iki dövlət arasında baş vermişdir?",
  "Dandanakan döyüşü səlcuqlarla Qəznəlilər arasında baş vermişdir.",
  ["Səlcuqlarla Qəznəlilər", "Osmanlılarla Bizans",
   "Monqollarla Ruslar", "Franklarla Ərəblər"], 1, None, 2),
 ("1071-ci il Malazgird döyüşündə Bizans ordusunu kim məğlub etmişdir?",
  "Malazgird döyüşündə Bizans ordusunu Alp Arslan məğlub etmişdir.",
  ["Alp Arslan", "Osman bəy", "Batı xan", "Hannibal"], 1, None, 2),
 ("«Siyasətnamə» əsərinin müəllifi kimdir?",
  "«Siyasətnamə» Səlcuq vəziri Nizamülmülkün əsəridir.",
  ["Nizamülmülk", "Uluqbəy", "Tonyukuk", "Salahəddin Əyyubi"], 1, None, 2),
 ("Osmanlı dövləti hansı ildə qurulmuşdur?",
  "Osmanlı dövləti 1299-cu ildə qurulmuşdur.",
  ["1299-cu ildə", "1206-cı ildə", "1370-ci ildə", "1453-cü ildə"], 1, None, 2),
 ("1402-ci il Ankara döyüşü kimlər arasında baş vermişdir?",
  "Ankara döyüşü Əmir Teymurla İldırım Bəyazid arasında baş vermişdir.",
  ["Əmir Teymurla İldırım Bəyazid", "Alp Arslanla Bizans imperatoru",
   "Çingiz xanla Batı xan", "Osman bəylə Salahəddin"], 1, None, 2),
 ("Qızıl Ordu dövlətinin əsasını kim qoymuşdur?",
  "Qızıl Ordu dövlətinin əsasını Batı xan qoymuşdur.",
  ["Batı xan", "Çingiz xan", "Uluqbəy", "Toğrul bəy"], 1, None, 2),
 ("Çingiz xan hansı ildə qurultayda xaqan elan olunmuşdur?",
  "Çingiz xan 1206-cı ildə qurultayda xaqan elan olunmuşdur.",
  ["1206-cı ildə", "1071-ci ildə", "1299-cu ildə", "1492-ci ildə"], 1, None, 2),
 ("Xaçlı yürüşləri dövründə Yerusəlimi geri qaytaran hökmdar kimdir?",
  "Yerusəlimi Salahəddin Əyyubi geri qaytarmışdır.",
  ["Salahəddin Əyyubi", "Fateh Sultan Mehmet",
   "Nizamülmülk", "Karl Böyük"], 1, None, 2),
 ("Dördüncü səlib yürüşü hansı şəhərin tutulması ilə nəticələnmişdir?",
  "Dördüncü səlib yürüşü Konstantinopolun tutulması ilə nəticələnmişdir.",
  ["Konstantinopolun", "Bağdadın", "Səmərqəndin", "Parisin"], 1, None, 2),
 ("Teymurilər sülaləsindən olan Uluqbəy hansı sahədə şöhrət qazanmışdır?",
  "Uluqbəy astronomiya sahəsindəki tədqiqatları ilə şöhrət qazanmışdır.",
  ["Astronomiya sahəsində", "Dənizçilik sahəsində",
   "Heykəltəraşlıq sahəsində", "Musiqi sahəsində"], 1, None, 2),
 ("Dehli sultanlığı hansı ildə qurulmuşdur?",
  "Dehli sultanlığı 1206-cı ildə qurulmuşdur.",
  ["1206-cı ildə", "1299-cu ildə", "1370-ci ildə", "1492-ci ildə"], 1, None, 2),
 ("Kosovo döyüşü hansı tərəflər arasında baş vermişdir?",
  "Kosovo döyüşü osmanlılarla Balkan dövlətlərinin birləşmiş qüvvələri arasında baş vermişdir.",
  ["Osmanlılarla Balkan qüvvələri", "Səlcuqlarla Qəznəlilər",
   "Monqollarla Teymurilər", "Franklarla normanlar"], 1, None, 2),
 ("Rekonkista hansı ildə başa çatmışdır?",
  "Rekonkista 1492-ci ildə Qranadanın alınması ilə başa çatmışdır.",
  ["1492-ci ildə", "1206-cı ildə", "1402-ci ildə", "1071-ci ildə"], 1, None, 2),
 ("Yüzillik müharibə hansı əsrləri əhatə edir?",
  "Yüzillik müharibə XIV-XV əsrləri əhatə edir.",
  ["XIV-XV əsrləri", "XI-XII əsrləri", "IX-X əsrləri", "XVI-XVII əsrləri"], 1, None, 2),

 # ---- cetin (12)
 ("Aşağıdakı hadisələri xronoloji ardıcıllıqla düzün: 1. Ankara döyüşü 2. Malazgird döyüşü 3. Konstantinopolun osmanlılar tərəfindən alınması",
  "Malazgird 1071, Ankara 1402, Konstantinopolun alınması isə 1453-cü ilə aiddir.",
  ["2 - 1 - 3", "1 - 2 - 3", "3 - 2 - 1", "2 - 3 - 1"], 1, None, 3),
 ("XI-XV yüzilliklər üçün «döyüş - il» uyğunluğu hansı sırada düzgündür?",
  "Malazgird 1071, Ankara 1402, Kosovo 1389, Dandanakan isə 1040-cı ilə aiddir.",
  ["Malazgird - 1071", "Dandanakan - 1402",
   "Ankara - 1071", "Kosovo - 1453"], 1, None, 3),
 ("XI-XV yüzilliklərin tarixi haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "Qızıl Ordunun banisi Çingiz xan deyil, onun nəvəsi Batı xandır.",
  ["Qızıl Ordu dövlətinin banisi Çingiz xandır",
   "Osmanlı dövləti 1299-cu ildə qurulmuşdur",
   "Malazgird döyüşü 1071-ci ildə olmuşdur",
   "Uluqbəy astronomiya ilə məşğul olmuşdur"], 1, None, 3),
 ("Malazgird döyüşünün uzunmüddətli nəticəsini düzgün göstərən fikir hansıdır?",
  "Bizansın müdafiəsi sarsıldı və Anadolu türk tayfalarının məskunlaşmasına açıldı.",
  ["Anadolu türk tayfalarının məskunlaşmasına açıldı",
   "Bizans imperiyası dərhal süqut etdi",
   "Səlcuqlar Anadoludan geri çəkildi",
   "Xaçlı yürüşləri dayandırıldı"], 1, None, 3),
 ("1402-ci il Ankara döyüşünün Osmanlı dövləti üçün nəticəsi nə oldu?",
  "Məğlubiyyətdən sonra dövlət parçalandı və on ilə yaxın davam edən fasilə dövrü başladı.",
  ["Dövlət parçalandı, uzun fasilə dövrü başladı",
   "Osmanlılar Səmərqəndi ələ keçirdi",
   "Konstantinopol dərhal alındı",
   "Teymurilər dövləti süquta uğradı"], 1, None, 3),
 ("XI-XV yüzilliklərin hansı hadisəsi digərlərindən əvvəl olmuşdur?",
  "Çingiz xanın xaqan elan olunması 1206, Kalka döyüşü 1223, Kosovo 1389, Ankara isə 1402-ci ilə aiddir.",
  ["Çingiz xanın xaqan elan olunması", "Kalka çayı üzərindəki döyüş",
   "Kosovo düzündəki döyüş", "Ankara yaxınlığındakı döyüş"], 1, None, 3),
 ("XI-XV yüzilliklər üçün «şəxs - dövlət» uyğunluğu hansı sırada düzgündür?",
  "Toğrul bəy Böyük Səlcuq, Batı xan Qızıl Ordu, Osman bəy isə Osmanlı dövlətinin banisidir.",
  ["Toğrul bəy - Böyük Səlcuq dövləti", "Batı xan - Böyük Səlcuq dövləti",
   "Osman bəy - Qızıl Ordu", "Uluqbəy - Dehli sultanlığı"], 1, None, 3),
 ("Çingiz xanın hərbi uğurlarının başlıca səbəbini düzgün göstərən fikir hansıdır?",
  "Sərt intizam və onluq sistemlə qurulmuş sürətli süvari ordu ona üstünlük verirdi.",
  ["Sərt intizamlı, onluq sistemli süvari ordu",
   "Güclü dəniz donanması", "Odlu silahların üstünlüyü",
   "Qala mühasirəsindən imtina siyasəti"], 1, None, 3),
 ("Qızıl Ordunun Şərqi Avropa üçün nəticəsini düzgün göstərən fikir hansıdır?",
  "Rus knyazlıqları uzun müddət Qızıl Orduya tabe olub xərac verməli oldu.",
  ["Rus knyazlıqları uzun müddət xərac verdi",
   "Rus knyazlıqları dərhal birləşdi",
   "Bizans Şərqi Avropanı ələ keçirdi",
   "Bölgədə şəhər ticarəti tamam dayandı"], 1, None, 3),
 ("Xaçlı yürüşləri və Şərq dövlətləri haqqında hansı fikir SƏHVDİR?",
  "Dördüncü səlib yürüşü Bağdadın deyil, Konstantinopolun tutulması ilə nəticələnmişdir.",
  ["Dördüncü səlib yürüşü Bağdadın tutulması ilə bitmişdir",
   "Salahəddin Əyyubi Yerusəlimi geri qaytarmışdır",
   "Rekonkista 1492-ci ildə başa çatmışdır",
   "Dehli sultanlığı 1206-cı ildə qurulmuşdur"], 1, None, 3),
 ("Böyük Səlcuq dövləti ilə Osmanlı dövləti arasındakı tarixi bağlılıq nədir?",
  "Osmanlılar Anadolu Səlcuq dövlətinin varisi kimi çıxış edir, onun dövlət ənənəsini davam etdirirdi.",
  ["Osmanlılar Anadolu Səlcuq ənənəsinin varisi idi",
   "Osmanlılar Səlcuqlardan əvvəl dövlət qurmuşdu",
   "Səlcuq və Osmanlı dövlətləri eyni sülalənin iki qoludur",
   "Osmanlılar Səlcuqları Orta Asiyadan qovmuşdu"], 1, None, 3),
 ("Xaçlı yürüşlərinin Yaxın Şərq üçün nəticəsini düzgün göstərən fikir hansıdır?",
  "İki əsrə yaxın davam edən müharibələr bölgəni zəiflətdi, sonda səlibçilər Şərqdən çıxarıldı.",
  ["Bölgə zəiflədi, sonda səlibçilər Şərqdən çıxarıldı",
   "Səlibçilər bölgədə daimi hakim oldu",
   "Bölgədə ticarət yolları tamam bağlandı",
   "Yerusəlim səlibçilərin əlində qaldı"], 1, None, 3)],
}
SUALLAR.update(HISSE_2)

HISSE_3 = {
"utarix-10-yeni-dovr": [
 # ---- asan (4)
 ("Otuzillik müharibə hansı sülhlə başa çatmışdır?",
  "Otuzillik müharibə 1648-ci il Vestfaliya sülhü ilə başa çatmışdır.",
  ["Vestfaliya sülhü ilə", "Niştadt sülhü ilə",
   "Karlovitsa sülhü ilə", "Versal sülhü ilə"], 1, None, 1),
 ("Rusiyada 1613-cü ildən hakimiyyətə gələn sülalə hansıdır?",
  "Rusiyada 1613-cü ildən Romanovlar sülaləsi hakimiyyətə gəlmişdir.",
  ["Romanovlar", "Teymurilər", "Baburilər", "Sinlər"], 1, None, 1),
 ("Hindistanda Böyük Moğol dövlətinin banisi kimdir?",
  "Böyük Moğol dövlətinin banisi Baburdur.",
  ["Babur", "Övrəngzeb", "I Pyotr", "Osman bəy"], 1, None, 1),
 ("Fransada mütləqiyyətin zirvəsi hansı kralın adı ilə bağlıdır?",
  "Fransada mütləqiyyətin zirvəsi XIV Lüdovikin adı ilə bağlıdır.",
  ["XIV Lüdovik", "IV İvan", "II Yekaterina", "İldırım Bəyazid"], 1, None, 1),

 # ---- orta (15)
 ("Otuzillik müharibə hansı illəri əhatə edir?",
  "Otuzillik müharibə 1618-1648-ci illəri əhatə edir.",
  ["1618-1648-ci illəri", "1700-1721-ci illəri",
   "1337-1453-cü illəri", "1789-1799-cu illəri"], 1, None, 2),
 ("Rusiyada ilk dəfə çar titulunu kim qəbul etmişdir?",
  "Rusiyada ilk dəfə çar titulunu IV İvan qəbul etmişdir.",
  ["IV İvan", "I Pyotr", "II Yekaterina", "Batı xan"], 1, None, 2),
 ("Şimal müharibəsi hansı iki dövlət arasında getmişdir?",
  "Şimal müharibəsi Rusiya ilə İsveç arasında getmişdir.",
  ["Rusiya ilə İsveç", "Fransa ilə İspaniya",
   "Osmanlı ilə Baburilər", "İngiltərə ilə Hollandiya"], 1, None, 2),
 ("Şimal müharibəsi hansı sülhlə başa çatmışdır?",
  "Şimal müharibəsi 1721-ci il Niştadt sülhü ilə başa çatmışdır.",
  ["Niştadt sülhü ilə", "Vestfaliya sülhü ilə",
   "Küçük Qaynarca müqaviləsi ilə", "Aqsburq sülhü ilə"], 1, None, 2),
 ("Rusiya hansı ildə rəsmən imperiya elan olunmuşdur?",
  "Rusiya 1721-ci ildə rəsmən imperiya elan olunmuşdur.",
  ["1721-ci ildə", "1613-cü ildə", "1648-ci ildə", "1774-cü ildə"], 1, None, 2),
 ("I Pyotrun apardığı islahatların başlıca məqsədi nə idi?",
  "İslahatların məqsədi ölkəni Avropa nümunəsində yeniləmək və gücləndirmək idi.",
  ["Ölkəni Avropa nümunəsində yeniləmək", "Ölkəni xarici aləmdən qapamaq",
   "Ordunu tamam buraxmaq", "Paytaxtı Səmərqəndə köçürmək"], 1, None, 2),
 ("Osmanlı imperiyasının ilk geniş ərazi güzəşti hansı sülhlə bağlıdır?",
  "İlk geniş ərazi güzəşti 1699-cu il Karlovitsa sülhü ilə bağlıdır.",
  ["Karlovitsa sülhü ilə", "Niştadt sülhü ilə",
   "Vestfaliya sülhü ilə", "Utrext ittifaqı ilə"], 1, None, 2),
 ("Osmanlı tarixində Lalə dövrü nə ilə səciyyələnir?",
  "Lalə dövrü Avropa ilə mədəni yaxınlaşma və ilk mətbəənin açılması ilə səciyyələnir.",
  ["Avropa ilə mədəni yaxınlaşma və mətbəənin açılması",
   "Bütün xarici əlaqələrin kəsilməsi",
   "Paytaxtın Bağdada köçürülməsi",
   "Ordunun ləğv edilməsi"], 1, None, 2),
 ("Babur Hindistanda hakimiyyəti hansı döyüşdən sonra ələ almışdır?",
  "Babur 1526-cı il Panipat döyüşündən sonra Hindistanda hakimiyyəti ələ almışdır.",
  ["Panipat döyüşündən sonra", "Ankara döyüşündən sonra",
   "Kosovo döyüşündən sonra", "Malazgird döyüşündən sonra"], 1, None, 2),
 ("Böyük Moğol dövləti hansı ildə qurulmuşdur?",
  "Böyük Moğol dövləti 1526-cı ildə qurulmuşdur.",
  ["1526-cı ildə", "1613-cü ildə", "1699-cu ildə", "1721-ci ildə"], 1, None, 2),
 ("Küçük Qaynarca müqaviləsi hansı iki dövlət arasında bağlanmışdır?",
  "Küçük Qaynarca müqaviləsi Osmanlı imperiyası ilə Rusiya arasında bağlanmışdır.",
  ["Osmanlı ilə Rusiya", "Fransa ilə İsveç",
   "İngiltərə ilə Hollandiya", "İspaniya ilə Portuqaliya"], 1, None, 2),
 ("Fransada mütləqiyyət dövrünün simvoluna çevrilmiş saray hansıdır?",
  "Mütləqiyyət dövrünün simvolu Versal sarayıdır.",
  ["Versal sarayı", "Topqapı sarayı", "Tac Mahal", "Ayasofya"], 1, None, 2),
 ("XVI-XVII əsrlərdə Rusiyanın ərazi genişlənməsi əsasən hansı istiqamətdə getmişdir?",
  "Rusiyanın genişlənməsi əsasən şərqə, Sibir istiqamətində getmişdir.",
  ["Şərqə, Sibir istiqamətində", "Cənuba, Misir istiqamətində",
   "Qərbə, Britaniya istiqamətində", "Şimala, Qrenlandiya istiqamətində"], 1, None, 2),
 ("II Yekaterinanın Rusiyada yeritdiyi daxili siyasət necə adlandırılır?",
  "Onun daxili siyasəti maarifçi mütləqiyyət adlandırılır.",
  ["Maarifçi mütləqiyyət", "Konstitusiyalı monarxiya",
   "Hərbi protektorluq", "Parlament respublikası"], 1, None, 2),
 ("Vestfaliya sülhündən sonra Almaniya ərazisi hansı vəziyyətdə qaldı?",
  "Almaniya çoxsaylı müstəqil knyazlıqlara bölünmüş halda qaldı.",
  ["Çoxsaylı knyazlıqlara bölünmüş halda", "Vahid mərkəzləşmiş dövlət kimi",
   "Fransanın tərkibində", "Osmanlı vassalı kimi"], 1, None, 2),

 # ---- cetin (12)
 ("Aşağıdakı hadisələri xronoloji ardıcıllıqla düzün: 1. Vestfaliya sülhünün bağlanması 2. Küçük Qaynarca müqaviləsi 3. Niştadt sülhü",
  "Vestfaliya sülhü 1648, Niştadt sülhü 1721, Küçük Qaynarca müqaviləsi isə 1774-cü ilə aiddir.",
  ["1 - 3 - 2", "1 - 2 - 3", "3 - 1 - 2", "2 - 3 - 1"], 1, None, 3),
 ("XVI-XVIII yüzilliklər üçün «müqavilə - tərəflər» uyğunluğu hansı sırada düzgündür?",
  "Niştadt sülhü Rusiya ilə İsveç, Küçük Qaynarca isə Osmanlı ilə Rusiya arasında bağlanmışdır.",
  ["Niştadt sülhü - Rusiya və İsveç", "Vestfaliya sülhü - Rusiya və İsveç",
   "Karlovitsa sülhü - Fransa və İngiltərə", "Küçük Qaynarca - Osmanlı və İsveç"], 1, None, 3),
 ("XVI-XVIII yüzilliklərin tarixi haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "Şimal müharibəsi Rusiya ilə İsveç arasında getmişdir, Osmanlı bu müharibənin tərəfi olmamışdır.",
  ["Şimal müharibəsi Rusiya ilə Osmanlı arasında getmişdir",
   "Otuzillik müharibə Vestfaliya sülhü ilə bitmişdir",
   "Böyük Moğol dövlətini Babur qurmuşdur",
   "Rusiya 1721-ci ildə imperiya elan olunmuşdur"], 1, None, 3),
 ("Otuzillik müharibənin Almaniya torpaqları üçün nəticəsini düzgün göstərən fikir hansıdır?",
  "Ölkə parçalanmış qaldı, əhali və təsərrüfat ağır itki verdi.",
  ["Ölkə parçalanmış qaldı, təsərrüfat ağır itki verdi",
   "Vahid Alman imperiyası quruldu",
   "Almaniya Avropanın ən güclü dövlətinə çevrildi",
   "Alman knyazlıqları Fransaya birləşdirildi"], 1, None, 3),
 ("I Pyotrun islahatlarını II Yekaterinanın siyasətindən fərqləndirən cəhət nədir?",
  "I Pyotr dövləti sərt inzibati tədbirlərlə Avropa qaydasına saldı, II Yekaterina isə maarifçi ideyalara söykənərək zadəganlara güzəştə getdi.",
  ["Biri sərt inzibati yolla, digəri maarifçi güzəştlərlə hərəkət edirdi",
   "Hər ikisi dövlət idarəçiliyini parlamentə verdi",
   "Biri ordunu buraxdı, digəri donanmanı ləğv etdi",
   "Hər ikisi ölkəni xarici aləmdən qapadı"], 1, None, 3),
 ("XVI-XVIII yüzilliklərin hansı hadisəsi digərlərindən əvvəl olmuşdur?",
  "Osmanlıların Vyana yürüşü 1683, Karlovitsa sülhü 1699, Şimal müharibəsinin başlanması 1700, Niştadt sülhü isə 1721-ci ilə aiddir.",
  ["Osmanlıların Vyana yürüşü", "Karlovitsa sülhünün bağlanması",
   "Şimal müharibəsinin başlanması", "Niştadt sülhünün bağlanması"], 1, None, 3),
 ("XVI-XVIII yüzilliklər üçün «hökmdar - ölkə» uyğunluğu hansı sırada düzgündür?",
  "I Pyotr Rusiyanın, XIV Lüdovik Fransanın, Övrəngzeb isə Böyük Moğol dövlətinin hökmdarı olmuşdur.",
  ["I Pyotr - Rusiya", "XIV Lüdovik - Rusiya",
   "Övrəngzeb - Fransa", "IV İvan - Böyük Moğol dövləti"], 1, None, 3),
 ("Karlovitsa sülhünün Osmanlı tarixi üçün mənasını düzgün göstərən fikir hansıdır?",
  "İmperiya ilk dəfə geniş ərazi güzəştinə getdi, bu isə uzunmüddətli geriləmənin başlanğıcı oldu.",
  ["İlk geniş ərazi güzəşti və geriləmənin başlanğıcı oldu",
   "İmperiyanın ən böyük ərazi qazancı oldu",
   "Osmanlının Avropadan tam çıxması demək idi",
   "Rusiya ilə ittifaqın başlanğıcı oldu"], 1, None, 3),
 ("Vestfaliya sülhünün beynəlxalq münasibətlərə gətirdiyi əsas yenilik nədir?",
  "Sülh dövlətlərin suveren bərabərliyinə əsaslanan ilk beynəlxalq münasibətlər sistemini qurdu.",
  ["Dövlətlərin suveren bərabərliyi prinsipini gətirdi",
   "Bütün monarxiyaları ləğv etdi",
   "Avropada vahid imperiya yaratdı",
   "Koloniyaların sərhədlərini müəyyən etdi"], 1, None, 3),
 ("Rusiya və Şərq dövlətləri haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "Rusiyada ilk çar titulunu I Pyotr deyil, IV İvan qəbul etmişdir; I Pyotr imperator titulunu almışdır.",
  ["Rusiyada ilk çar titulunu I Pyotr qəbul etmişdir",
   "Lalə dövründə Osmanlıda mətbəə açılmışdır",
   "Babur Panipat döyüşündən sonra Hindistanda hakim oldu",
   "Versal sarayı Fransa mütləqiyyətinin simvoludur"], 1, None, 3),
 ("Böyük Moğol dövlətinin XVIII əsrdə zəifləməsinin daxili səbəbini düzgün göstərən fikir hansıdır?",
  "Uzun sürən müharibələr və dini dözümsüzlük siyasəti yerli əhalinin narazılığını artırmışdı.",
  ["Uzun müharibələr və dini siyasət narazılığı artırdı",
   "Ölkədə ticarət tamam qadağan olunmuşdu",
   "Paytaxt Səmərqəndə köçürülmüşdü",
   "Hökmdar seçki yolu ilə təyin olunurdu"], 1, None, 3),
 ("Rusiyanın XVIII əsrdə Baltik dənizinə çıxış qazanmasının əhəmiyyətini düzgün göstərən fikir hansıdır?",
  "Avropa ilə birbaşa dəniz ticarəti mümkün oldu və sahildə yeni paytaxt salındı.",
  ["Avropa ilə birbaşa dəniz ticarəti və yeni paytaxt imkanı yarandı",
   "Ölkə Sibirdəki torpaqlardan əl çəkməli oldu",
   "Ölkənin xarici ticarəti tamam dayandırıldı",
   "Rusiya Aralıq dənizi yollarına nəzarəti ələ aldı"], 1, None, 3)],

"utarix-10-medeniyyet": [
 # ---- asan (4)
 ("Cəbr elminin əsasını qoyan orta əsr Şərq alimi kimdir?",
  "Cəbr elminin əsasını əl-Xarəzmi qoymuşdur.",
  ["Əl-Xarəzmi", "Rembrandt", "Mimar Sinan", "Rene Dekart"], 1, None, 1),
 ("«Tibb qanunu» əsərinin müəllifi kimdir?",
  "«Tibb qanunu» əsərinin müəllifi İbn Sinadır.",
  ["İbn Sina", "Ömər Xəyyam", "İsaak Nyuton", "Yohan Sebastyan Bax"], 1, None, 1),
 ("Marağa rəsədxanasının banisi kimdir?",
  "Marağa rəsədxanasının banisi Nəsirəddin Tusidir.",
  ["Nəsirəddin Tusi", "Əl-Biruni", "Qalileo Qaliley", "Mimar Sinan"], 1, None, 1),
 ("Ümumdünya cazibə qanununu kəşf edən alim kimdir?",
  "Ümumdünya cazibə qanununu İsaak Nyuton kəşf etmişdir.",
  ["İsaak Nyuton", "İbn Rüşd", "Uluqbəy", "Volfqanq Mosart"], 1, None, 1),

 # ---- orta (15)
 ("Ömər Xəyyam hansı şeir formasının ustadı sayılır?",
  "Ömər Xəyyam rübai formasının ustadı sayılır.",
  ["Rübai", "Sonet", "Poema", "Oda"], 1, None, 2),
 ("Uluqbəyin Səmərqənddə qurduğu elm ocağı nə idi?",
  "Uluqbəy Səmərqənddə böyük rəsədxana qurmuşdu.",
  ["Rəsədxana", "Dəniz məktəbi", "Mətbəə", "Xəstəxana"], 1, None, 2),
 ("Osmanlı memarlığının zirvəsi sayılan memar kimdir?",
  "Osmanlı memarlığının zirvəsi Mimar Sinanın adı ilə bağlıdır.",
  ["Mimar Sinan", "Nəsirəddin Tusi", "Rene Dekart", "Rembrandt"], 1, None, 2),
 ("Teleskopla göy cisimlərini müşahidə edən italyan alimi kimdir?",
  "Teleskopla göy cisimlərini Qalileo Qaliley müşahidə etmişdir.",
  ["Qalileo Qaliley", "Əl-Biruni", "İbn Rüşd", "Mimar Sinan"], 1, None, 2),
 ("«Düşünürəm, deməli, varam» fikri hansı mütəfəkkirə aiddir?",
  "Bu fikir fransız filosofu Rene Dekarta aiddir.",
  ["Rene Dekart", "İsaak Nyuton", "Ömər Xəyyam", "Uluqbəy"], 1, None, 2),
 ("Əl-Biruni hansı elm sahələrində şöhrət qazanmışdır?",
  "Əl-Biruni astronomiya, coğrafiya və riyaziyyat sahələrində şöhrət qazanmışdır.",
  ["Astronomiya, coğrafiya və riyaziyyat", "Memarlıq və heykəltəraşlıq",
   "Musiqi və rəqs", "Dənizçilik və gəmiqayırma"], 1, None, 2),
 ("XVII-XVIII əsrlərdə Avropa memarlığındakı təmtəraqlı üslub necə adlanır?",
  "Bu təmtəraqlı üslub barokko adlanır.",
  ["Barokko", "Qotika", "Roman üslubu", "Konstruktivizm"], 1, None, 2),
 ("Antik ölçü və sadəliyə qayıdışı əsas götürən XVII-XVIII əsr üslubu hansıdır?",
  "Bu üslub klassisizm adlanır.",
  ["Klassisizm", "Barokko", "Qotika", "Romantizm"], 1, None, 2),
 ("XVII əsr Hollandiya rəssamlığının ən böyük ustadı kimdir?",
  "Hollandiya rəssamlığının ən böyük ustadı Rembrandtdır.",
  ["Rembrandt", "Mimar Sinan", "Qalileo Qaliley", "Ömər Xəyyam"], 1, None, 2),
 ("Barokko musiqisinin ən görkəmli nümayəndəsi kimdir?",
  "Barokko musiqisinin ən görkəmli nümayəndəsi Yohan Sebastyan Baxdır.",
  ["Yohan Sebastyan Bax", "Volfqanq Amadey Mosart",
   "Rene Dekart", "İsaak Nyuton"], 1, None, 2),
 ("Vyana klassik musiqi məktəbinin tanınmış nümayəndəsi kimdir?",
  "Vyana klassik məktəbinin tanınmış nümayəndəsi Volfqanq Amadey Mosartdır.",
  ["Volfqanq Amadey Mosart", "Yohan Sebastyan Bax",
   "Rembrandt", "Əl-Xarəzmi"], 1, None, 2),
 ("İbn Rüşd hansı antik filosofun əsərlərinə şərhlər yazmışdır?",
  "İbn Rüşd Aristotelin əsərlərinə şərhlər yazmışdır.",
  ["Aristotelin", "Homerin", "Herodotun", "Arximedin"], 1, None, 2),
 ("Avropada işlənən rəqəmlər əslində hansı ölkədən götürülmüşdür?",
  "Bu rəqəmlər Hindistandan götürülüb ərəblər vasitəsilə Avropaya keçmişdir.",
  ["Hindistandan", "Misirdən", "Yunanıstandan", "Çindən"], 1, None, 2),
 ("İsaak Nyutonun əsas elmi əsəri necə adlanır?",
  "Nyutonun əsas əsəri «Natural fəlsəfənin riyazi əsasları»dır.",
  ["«Natural fəlsəfənin riyazi əsasları»", "«Tibb qanunu»",
   "«Siyasətnamə»", "«Avesta»"], 1, None, 2),
 ("XVII-XVIII əsrlərdə elmi biliklərin yayılmasına təkan verən yeni qurumlar hansılardır?",
  "Bu dövrdə yaranan elmlər akademiyaları biliklərin yayılmasına təkan vermişdir.",
  ["Elmlər akademiyaları", "Cəngavər ordenləri",
   "Sex birlikləri", "Monastır emalatxanaları"], 1, None, 2),

 # ---- cetin (12)
 ("Aşağıdakı hadisələri xronoloji ardıcıllıqla düzün: 1. Uluqbəy rəsədxanasının qurulması 2. Nyutonun cazibə qanununu verməsi 3. İbn Sinanın «Tibb qanunu»nu yazması",
  "İbn Sina XI əsrdə, Uluqbəy XV əsrdə, Nyuton isə XVII əsrin sonunda fəaliyyət göstərmişdir.",
  ["3 - 1 - 2", "1 - 2 - 3", "2 - 1 - 3", "3 - 2 - 1"], 1, None, 3),
 ("Orta əsrlər və yeni dövr üçün «alim - elm sahəsi» uyğunluğu hansı sırada düzgündür?",
  "Əl-Xarəzmi cəbrin, Mimar Sinan memarlığın, Rembrandt isə rəssamlığın nümayəndəsidir.",
  ["Əl-Xarəzmi - cəbr", "İbn Sina - memarlıq",
   "Mimar Sinan - tibb", "Rembrandt - riyaziyyat"], 1, None, 3),
 ("Orta əsrlər və yeni dövr mədəniyyəti haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "«Tibb qanunu» əsəri Ömər Xəyyamın deyil, İbn Sinanın qələmindən çıxmışdır.",
  ["«Tibb qanunu» əsərini Ömər Xəyyam yazmışdır",
   "Marağa rəsədxanasını Nəsirəddin Tusi qurmuşdur",
   "Uluqbəy Səmərqənddə rəsədxana tikdirmişdir",
   "İbn Rüşd Aristotelə şərhlər yazmışdır"], 1, None, 3),
 ("Rəsədxanaların qurulmasının astronomiya elminə təsirini düzgün göstərən fikir hansıdır?",
  "Uzunmüddətli müntəzəm müşahidələr ulduz cədvəllərini xeyli dəqiqləşdirdi.",
  ["Müntəzəm müşahidələr ulduz cədvəllərini dəqiqləşdirdi",
   "Göy cisimlərinin öyrənilməsi dayandırıldı",
   "Təqvim hesablamaları istifadədən çıxdı",
   "Riyazi hesablamalara ehtiyac qalmadı"], 1, None, 3),
 ("Barokko ilə klassisizm üslublarını düzgün müqayisə edən fikir hansıdır?",
  "Barokko təmtəraq və hərəkət, klassisizm isə antik ölçü və sadəlik üzərində qurulur.",
  ["Barokko təmtəraqlı, klassisizm ölçülü və sadədir",
   "Barokko sadə, klassisizm təmtəraqlıdır",
   "Hər ikisi orta əsr qotikasının davamıdır",
   "Hər ikisi yalnız musiqiyə aid üslubdur"], 1, None, 3),
 ("Şərq alimlərinin Avropa elminə təsirini düzgün göstərən fikir hansıdır?",
  "Antik mətnlər və yeni biliklər ərəb dilindən latın dilinə tərcümə yolu ilə Avropaya keçdi.",
  ["Biliklər ərəb dilindən latın dilinə tərcümə ilə keçdi",
   "Avropa Şərq elmindən tamam təcrid olunmuşdu",
   "Şərq alimləri Avropa universitetlərini idarə edirdi",
   "Avropa öz elmini Şərqə latın dilində ötürürdü"], 1, None, 3),
 ("Yeni dövr incəsənəti haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "Barokko musiqisinin nümayəndəsi Bax, Vyana klassik məktəbinin nümayəndəsi isə Mosartdır.",
  ["Vyana klassik məktəbinin nümayəndəsi Baxdır",
   "Rembrandt Hollandiya rəssamlıq məktəbinə aiddir",
   "Dekart yeni dövr fəlsəfəsinin görkəmli siması idi",
   "Qaliley teleskopla göy cisimlərini müşahidə etmişdir"], 1, None, 3),
 ("Qalileyin teleskop müşahidələrinin elm tarixi üçün əhəmiyyəti nədir?",
  "Müşahidələr günəşmərkəzli sistemin lehinə ilk birbaşa dəlilləri verdi.",
  ["Günəşmərkəzli sistemin lehinə dəlil verdi",
   "Yerin kainatın mərkəzi olduğunu təsdiqlədi",
   "Cazibə qanununu riyazi ifadə etdi",
   "Ulduzların sayının sabit olduğunu göstərdi"], 1, None, 3),
 ("Nyuton mexanikasının elm üçün başlıca mənası nədir?",
  "O, göy cisimlərinin və yerdəki cisimlərin hərəkətini vahid qanunlarla izah etdi.",
  ["Göy və yer hərəkətini vahid qanunlarla izah etdi",
   "Astronomiya ilə fizikanı bir-birindən ayırdı",
   "Riyaziyyatın fizikada istifadəsini məhdudlaşdırdı",
   "Yalnız optikaya aid nəticələr verdi"], 1, None, 3),
 ("Orta əsrlər və yeni dövr üçün «usta - əsər» uyğunluğu hansı sırada düzgündür?",
  "«Natural fəlsəfənin riyazi əsasları» Nyutonun, «Tibb qanunu» İbn Sinanın əsəridir.",
  ["Nyuton - «Natural fəlsəfənin riyazi əsasları»",
   "İbn Sina - «Natural fəlsəfənin riyazi əsasları»",
   "Ömər Xəyyam - «Tibb qanunu»", "Dekart - «Siyasətnamə»"], 1, None, 3),
 ("Şərq riyaziyyatında onluq say sistemi və sıfırın yayılmasının əhəmiyyəti nədir?",
  "Bu sistem hesablamaları xeyli asanlaşdırdı və ticarətlə elmin inkişafına təkan verdi.",
  ["Hesablamaları asanlaşdırıb elmin inkişafına təkan verdi",
   "Yazının unudulmasına gətirib çıxardı",
   "Astronomiya müşahidələrini çətinləşdirdi",
   "Ticarət sənədlərinin tərtibini ləngitdi"], 1, None, 3),
 ("XVII-XVIII əsrlərdə elmi cəmiyyət və akademiyaların yaranmasının başlıca səbəbi nə idi?",
  "Təcrübi biliyin sürətlə artması alimlərin nəticələri bölüşmək və yoxlamaq ehtiyacını doğurmuşdu.",
  ["Alimlərin nəticələri bölüşmək və yoxlamaq ehtiyacı",
   "Universitetlərin bağlanması qərarı",
   "Kitab çapının hər yerdə qadağan olunması",
   "Elmdə latın dilindən imtina"], 1, None, 3)],
}
SUALLAR.update(HISSE_3)


def yoxla():
    n = xeta = 0
    butun = set()
    movzular = set(m for m, _r in MOVZULAR)
    for movzu, siyahi in SUALLAR.items():
        assert movzu in movzular, movzu
        if len(siyahi) != 31:
            print("XETA  %s: %d sual (31 olmalidir)" % (movzu, len(siyahi)))
            xeta += 1
        say = {1: 0, 2: 0, 3: 0}
        for body, why, opts, correct, expect, diff in siyahi:
            n += 1
            if diff in say:
                say[diff] += 1
            p = []
            if len(opts) != 4: p.append("variant sayi %d" % len(opts))
            if len(set(opts)) != len(opts): p.append("tekrar variant")
            if not (1 <= correct <= 4): p.append("correct")
            if not why: p.append("izah bos")
            if diff not in (1, 2, 3): p.append("cetinlik")
            if body in butun: p.append("eyni sual iki defe")
            butun.add(body)
            if expect is not None and opts[correct - 1] != expect:
                p.append("hesablanan «%s» != variant «%s»"
                         % (expect, opts[correct - 1]))
            for t in [body, why] + opts:
                if "'" in t: p.append("apostrof var")
                if any("Ѐ" <= ch <= "ӿ" for ch in t):
                    p.append("kiril herfi var")
            if p:
                xeta += 1
                print("XETA  %s: %s\n      %s" % (movzu, body[:60], "; ".join(p)))
        if say != BOLGU:
            print("XETA  %s: cetinlik bolgusu %s (gozlenilen %s)"
                  % (movzu, say, BOLGU))
            xeta += 1
    if len(SUALLAR) != len(MOVZULAR):
        print("XETA  movzu sayi %d (%d olmalidir)"
              % (len(SUALLAR), len(MOVZULAR)))
        xeta += 1
    #  ANS qaydasi bank uzre yoxlanir - bazadaki yoxlama da ext_key
    #  onluyune (utarix10-) gore aparilir
    cavab = {}
    for movzu, siyahi in SUALLAR.items():
        sinif = movzu.split("-")[1]
        for body, why, opts, correct, _e, _d in siyahi:
            cavab.setdefault((sinif, opts[correct - 1]), []).append(movzu)
    for (sinif, c), yer in sorted(cavab.items()):
        if len(yer) > 2:
            print("XETA  %s-ci sinif: duzgun cavab %d defe: «%s» (%s)"
                  % (sinif, len(yer), c, ", ".join(yer)))
            xeta += 1
    print("%d sual yoxlandı, %d xəta" % (n, xeta))
    return xeta == 0, n


def sql_yaz(n):
    q = lambda t: t.replace("'", "''")
    setirler = []
    for movzu, rub in MOVZULAR:
        pay = movzu.split("-")          # utarix, 10, antik
        on = "utarix" + pay[1]
        qisa = "-".join(pay[2:])
        for i, (body, why, opts, correct, _e, diff) in enumerate(SUALLAR[movzu], 1):
            setirler.append(
                "('%s-%s#%d','umumi-tarix','%s',%d,%d,'%s','%s',"
                "array['%s','%s','%s','%s'],%d)"
                % (on, qisa, i, movzu, diff, rub, q(body), q(why),
                   q(opts[0]), q(opts[1]), q(opts[2]), q(opts[3]), correct))
    with io.open(CIXIS, "w", encoding="utf-8") as f:
        f.write("""-- =====================================================================
--  69_bank_tarix_umumi10.sql : UMUMI TARIX 10 BANKI
--
--  BU FAYL ELLE YAZILMIR - tools/tarix_umumi10.py yaradir:
--      python3 tools/tarix_umumi10.py
--
--  6 movzu x 31 sual = %d.  Her movzuda 4 asan + 15 orta + 12 cetin.
--  ext_key: utarix10-...
--  ON SERT: 68_movzular_umumi_tarix10.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'umumi-tarix' and t.slug in
           ('utarix-10-qedim-serq', 'utarix-10-antik', 'utarix-10-medeniyyet')
     having count(*) = 3) then
    raise exception 'ONCE 68_movzular_umumi_tarix10.sql isledilmelidir.';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and q.ext_key like 'utarix10-%%';

with d(ext, fenn, topic, diff, rub, body, why, opts, correct) as (values
%s
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, tp.level_id, tp.id, 'single',
         d.body, d.why, d.diff, d.rub, 'published'
    from d
    join public.subjects s on s.slug = d.fenn
    join public.topics   tp on tp.subject_id = s.id and tp.slug = d.topic
  on conflict (ext_key) do update
    set body = excluded.body, explanation = excluded.explanation,
        difficulty = excluded.difficulty, quarter = excluded.quarter,
        topic_id = excluded.topic_id, level_id = excluded.level_id,
        subject_id = excluded.subject_id, status = 'published'
  returning id, ext_key
)
insert into public.question_options (question_id, ord, body, is_correct)
select ins.id, o.ord, o.txt, o.ord = d.correct
  from ins
  join d on d.ext = ins.ext_key,
  lateral unnest(d.opts) with ordinality as o(txt, ord);

do $$
declare n int; k int;
begin
  select count(*) into n from public.questions
   where owner_type = 'platform' and ext_key like 'utarix10-%%';
  if n <> %d then
    raise exception 'Umumi tarix 10 suallari: %d gozlenilirdi, %% tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'utarix10-%%'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '%% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'utarix10-%%';
  if k <> 6 then
    raise exception 'movzu sayi 6 deyil: %%', k;
  end if;
  --  Her movzuda en azi 12 cetin sual olmalidir ki, muellim BIR
  --  movzudan 10 sualliq cetin test yiga bilsin
  select count(*) into k from (
    select q.topic_id from public.questions q
     where q.ext_key like 'utarix10-%%' and q.difficulty = 3
     group by q.topic_id having count(*) < 12) z;
  if k > 0 then
    raise exception '%% movzuda 12-den az cetin sual var', k;
  end if;
  raise notice 'Umumi tarix 10 banki: %% sual, 6 movzu (her birinde 12 cetin).', n;
end $$;
""" % (n, ",\n".join(setirler), n, n))
    print("yazildi: %s" % CIXIS)


if __name__ == "__main__":
    ok, n = yoxla()
    if not ok:
        raise SystemExit(1)
    sql_yaz(n)
