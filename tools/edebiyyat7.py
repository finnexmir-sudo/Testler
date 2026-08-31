#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Edebiyyat 7 banki -> db/64_bank_edebiyyat7.sql

    5 movzu x 31 sual = 155

Movzular 61_movzular_edebiyyat5_8.sql agacina uygundur (e-derslik
kitab id 701).  5-7-ci sinifde derslik TEMA uzre bolunub, ona gore
movzular da temadir.  Dersliyin BEDII METNI goturulmur.

DIQQET:  bu siniflerde derslikde COX muasir muellif var (Rahil
Memmed, Eyvaz Zeynalli, Bayram Hesenov...).  Onlarin metnlerinin
suje teferrüati uydurulmur - suallar mundericatdan cixan FAKTLAR
uzerinde qurulur:  muellif-eser cutu, bolme (tema), edebi nov,
janr (mundericat gosterirse) ve dovre uygun edebiyyat nezeriyyesi.

CETINLIK BOLGUSU her movzuda:  4 asan + 15 orta + 12 cetin.
"""
import io
import os

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CIXIS = os.path.join(KOK, "db", "64_bank_edebiyyat7.sql")

MOVZULAR = [
    ("edeb-7-sifahi", 1),
    ("edeb-7-veten",  1),
    ("edeb-7-menevi", 2),
    ("edeb-7-usaq",   3),
    ("edeb-7-tebiet", 4),
]

BOLGU = {1: 4, 2: 15, 3: 12}

SUALLAR = {}

HISSE_1 = {
"edeb-7-sifahi": [
 # ---- asan (4)
 ("«Dərzi şagirdi Əhməd» hansı janrdadır?",
  "Bu, xalq nağılıdır.",
  ["Nağıl", "Şeir", "Dram", "Roman"], 1, None, 1),
 ("«Durna teli» hansı dastandan götürülmüşdür?",
  "«Durna teli» «Koroğlu» dastanının qoludur.",
  ["«Koroğlu»", "«Kitabi-Dədə Qorqud»", "«Əsli və Kərəm»",
   "«Aşıq Qərib»"], 1, None, 1),
 ("«Xəzinəqaya» mətni hansı janrdadır?",
  "Bu, əfsanədir.",
  ["Əfsanə", "Qəzəl", "Povest", "Komediya"], 1, None, 1),
 ("Şifahi xalq ədəbiyyatı əsərləri necə yayılır?",
  "Onlar ağızdan-ağıza, şifahi yolla yayılır.",
  ["Ağızdan-ağıza, şifahi yolla", "Ancaq kitab vasitəsilə",
   "Tərcümə yolu ilə", "Rəsmi sənədlərlə"], 1, None, 1),
 # ---- orta (15)
 ("Nağılın sonunda hansı ənənəvi ifadə işlənir?",
  "Nağıllar çox vaxt «Göydən üç alma düşdü» ilə bitir.",
  ["«Göydən üç alma düşdü»", "«Biri var idi, biri yox idi»",
   "«Salam verdim, almadılar»", "«Bir zamanlar uzaqda»"], 1, None, 2),
 ("«Koroğlu» dastanının qolları kim tərəfindən ifa olunurdu?",
  "Qollar aşıqlar tərəfindən ifa olunurdu.",
  ["Aşıqlar tərəfindən", "Saray katibləri tərəfindən",
   "Məktəb müəllimləri tərəfindən", "Karvan tacirləri tərəfindən"],
  1, None, 2),
 ("Əfsanəni nağıldan fərqləndirən əsas cəhət nədir?",
  "Əfsanə real bir yerə, dağa, qayaya və ya hadisəyə bağlanır.",
  ["Əfsanə real yerə və hadisəyə bağlanır",
   "Nağıl real yerə bağlanır", "İkisi arasında fərq yoxdur",
   "Əfsanə hökmən şeirlə söylənir"], 1, None, 2),
 ("Nağıllarda hansı saylar daha çox işlənir?",
  "Nağıllarda üç və yeddi sayları çox işlənir.",
  ["Üç və yeddi", "İki və dörd", "Beş və on", "Səkkiz və doqquz"],
  1, None, 2),
 ("Nağıl qəhrəmanının yolunda nə olur?",
  "Onun yolunda sınaqlar və çətinliklər olur.",
  ["Sınaqlar və çətinliklər", "Ancaq asan tapşırıqlar",
   "Heç bir maneə", "Ticarət müqavilələri"], 1, None, 2),
 ("«Dərzi şagirdi Əhməd» nağılının qəhrəmanı hansı peşə ilə bağlıdır?",
  "Qəhrəman dərzilik peşəsi ilə bağlıdır.",
  ["Dərziliklə", "Dəmirçiliklə", "Balıqçılıqla", "Çobanlıqla"],
  1, None, 2),
 ("Şifahi xalq ədəbiyyatı nümunələrinin müəllifi kimdir?",
  "Onların konkret müəllifi bilinmir, yaradıcısı xalqdır.",
  ["Müəllifi bilinmir, yaradıcısı xalqdır", "Bir konkret şair",
   "Saray katibi", "Xarici bir müəllif"], 1, None, 2),
 ("Əfsanələr çox vaxt nəyi izah edir?",
  "Yer adlarının, qayaların, təbiət hadisələrinin mənşəyini izah edir.",
  ["Yer adlarının mənşəyini", "Riyazi qanunları",
   "Ticarət qaydalarını", "Hərbi taktikanı"], 1, None, 2),
 ("Dastanların söylənməsində hansı musiqi aləti işlənir?",
  "Aşıq dastanı sazın müşayiəti ilə söyləyir.",
  ["Saz", "Tar", "Piano", "Ney"], 1, None, 2),
 ("Nağılda sehrli əşyalar hansı rolu oynayır?",
  "Onlar qəhrəmana kömək edir, ona güc verir.",
  ["Qəhrəmana kömək edir", "Qəhrəmana mane olur",
   "Heç bir rol oynamır", "Ancaq bəzək üçündür"], 1, None, 2),
 ("Nağıllarda xeyirlə şərin mübarizəsi necə bitir?",
  "Nağıllar xeyirin qələbəsi ilə bitir.",
  ["Xeyirin qələbəsi ilə", "Şərin qələbəsi ilə",
   "Heç bir nəticə olmadan", "Ticarət razılaşması ilə"], 1, None, 2),
 ("Əfsanə hansı ədəbi növə aiddir?",
  "Əfsanə epik növə aiddir.",
  ["Epik növə", "Lirik növə", "Dram növünə", "Publisistikaya"],
  1, None, 2),
 ("Nağıl qəhrəmanı adətən hansı keyfiyyətlərə malik olur?",
  "O, cəsarətli, zəkalı və xeyirxah olur.",
  ["Cəsarət, zəka və xeyirxahlıq", "Xəsislik və qorxaqlıq",
   "Laqeydlik və etinasızlıq", "Tənbəllik və süstlük"], 1, None, 2),
 ("«Koroğlu» dastanında Koroğlunun atının adı nədir?",
  "Koroğlunun atı Qıratdır.",
  ["Qırat", "Düldül", "Rəxş", "Şəbdiz"], 1, None, 2),
 ("Şifahi xalq ədəbiyyatı hansı dildə yaranır?",
  "O, xalqın canlı danışıq dilində yaranır.",
  ["Xalqın canlı danışıq dilində", "Ancaq ərəb dilində",
   "Ancaq fars dilində", "Latın dilində"], 1, None, 2),
 # ---- cetin (12)
 ("Yeddinci sinif materialı üzrə «əsər - janr» cütlüyü hansı düzgündür?",
  "«Xəzinəqaya» əfsanə, «Dərzi şagirdi Əhməd» isə nağıldır.",
  ["«Xəzinəqaya» - əfsanə", "«Dərzi şagirdi Əhməd» - əfsanə",
   "«Xəzinəqaya» - nağıl", "«Durna teli» - əfsanə"], 1, None, 3),
 ("Şifahi ədəbiyyat bölməsi haqqında hansı fikir SƏHVDİR?",
  "«Durna teli» «Koroğlu» dastanının qoludur.",
  ["«Durna teli» «Dədə Qorqud» dastanındandır",
   "«Dərzi şagirdi Əhməd» nağıldır",
   "Əfsanələr real yerlə bağlanır",
   "Nağıllarda üç sayı çox işlənir"], 1, None, 3),
 ("Şifahi xalq ədəbiyyatı ilə yazılı ədəbiyyatın əsas fərqi nədir?",
  "Şifahi ədəbiyyatın müəllifi bilinmir, yazılı ədəbiyyatınkı bilinir.",
  ["Şifahi ədəbiyyatın müəllifi bilinmir",
   "Yazılı ədəbiyyatın müəllifi bilinmir",
   "Hər ikisinin müəllifi bilinmir",
   "Hər ikisinin müəllifi dəqiq bilinir"], 1, None, 3),
 ("Nağıllarda sehrli əşyaların olmasının səbəbi nədir?",
  "Sehrli əşyalar xalqın arzu və istəklərinin bədii ifadəsidir.",
  ["Xalqın arzu və istəklərinin ifadəsi",
   "Tarixi sənədlərin birbaşa təsiri",
   "Elmi biliklərin geniş yayılması",
   "Ticarət əlaqələrinin genişlənməsi"], 1, None, 3),
 ("Şifahi ədəbiyyat üzrə «əsər - mənbə» cütlüyü hansı doğrudur?",
  "«Durna teli» «Koroğlu» dastanından götürülmüşdür.",
  ["«Durna teli» - «Koroğlu» dastanı",
   "«Durna teli» - «Kitabi-Dədə Qorqud»",
   "«Dərzi şagirdi Əhməd» - «Koroğlu» dastanı",
   "«Xəzinəqaya» - «Koroğlu» dastanı"], 1, None, 3),
 ("Nağılda hadisələr necə sıralanır? "
  "(1 - qəhrəmanın sınaqlardan keçməsi, 2 - qəhrəmanın yola düşməsi, "
  "3 - xeyirin qələbəsi)",
  "Əvvəlcə qəhrəman yola düşür, sonra sınaqlardan keçir, sonda xeyir udur.",
  ["2 - 1 - 3", "1 - 2 - 3", "3 - 2 - 1", "2 - 3 - 1"], 1, None, 3),
 ("Ədəbi növlər haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "Əfsanə epik növə aiddir, lirik növə deyil.",
  ["Əfsanə lirik növə aiddir", "Nağıl epik növə aiddir",
   "Dastan şifahi yolla yayılır", "Aşıq dastanı sazla ifa edir"],
  1, None, 3),
 ("Nağıl və əfsanənin ortaq cəhəti nədir?",
  "Hər ikisi şifahi xalq ədəbiyyatı nümunəsidir.",
  ["Hər ikisi şifahi xalq ədəbiyyatı nümunəsidir",
   "Hər ikisi yazılı ədəbiyyata aiddir",
   "Biri şifahi, digəri yazılı ədəbiyyatdandır",
   "Hər ikisi hökmən şeirlə söylənir"], 1, None, 3),
 ("Aşağıdakı «obraz - əsər» cütlüklərindən hansı düzgündür?",
  "Qırat «Koroğlu» dastanının obrazıdır.",
  ["Qırat - «Koroğlu» dastanı", "Qırat - «Kitabi-Dədə Qorqud»",
   "Basat - «Koroğlu» dastanı", "Uruz - «Koroğlu» dastanı"],
  1, None, 3),
 ("Əfsanələrin konkret yer adları ilə bağlanmasının səbəbi nədir?",
  "Xalq ətrafındakı dünyanı, yer adlarını izah etmək istəyirdi.",
  ["Ətrafdakı dünyanı izah etmək istəyi",
   "Coğrafiya dərsinin tələbi",
   "Rəsmi sənədlərin birbaşa təsiri",
   "Xarici ədəbiyyatın güclü təsiri"], 1, None, 3),
 ("Nağıl qəhrəmanı ilə dastan qəhrəmanının fərqi nədir?",
  "Dastan qəhrəmanı çox vaxt real tarixi zəmində verilir.",
  ["Dastan qəhrəmanı real tarixi zəmindədir",
   "Nağıl qəhrəmanı real tarixi zəmindədir",
   "İkisi arasında heç bir fərq yoxdur",
   "Hər ikisi ancaq sehrli aləmdə yaşayır"], 1, None, 3),
 ("Aşağıdakı «janr - əlamət» cütlüklərindən hansı doğrudur?",
  "Sehrli əşyalar və qeyri-adi qüvvələr nağıl üçün səciyyəvidir.",
  ["Nağıl - sehrli əşyalar", "Atalar sözü - sehrli əşyalar",
   "Bayatı - sehrli əşyalar", "Tapmaca - sehrli əşyalar"],
  1, None, 3)],

"edeb-7-veten": [
 # ---- asan (4)
 ("Yeddinci sinifdə keçilən «Azərbaycan» şeirinin müəllifi kimdir?",
  "Şeirin müəllifi Səməd Vurğundur.",
  ["Səməd Vurğun", "Mirzə İbrahimov", "Zahid Xəlil",
   "Rahil Məmməd"], 1, None, 1),
 ("«Azad» əsərinin müəllifi kimdir?",
  "Əsərin müəllifi Mirzə İbrahimovdur.",
  ["Mirzə İbrahimov", "Səməd Vurğun", "Eyvaz Zeynallı",
   "Zahid Xəlil"], 1, None, 1),
 ("«Babəkin andı» əsərinin müəllifi kimdir?",
  "Əsərin müəllifi Mikayıl Rzaquluzadədir.",
  ["Mikayıl Rzaquluzadə", "Mirzə İbrahimov", "Rahil Məmməd",
   "Səməd Vurğun"], 1, None, 1),
 ("«Kəşfiyyatçılar» əsərinin müəllifi kimdir?",
  "Əsərin müəllifi Eyvaz Zeynallıdır.",
  ["Eyvaz Zeynallı", "Zahid Xəlil", "Mikayıl Rzaquluzadə",
   "Mirzə İbrahimov"], 1, None, 1),
 # ---- orta (15)
 ("«Azərbaycan» şeiri hansı ədəbi növə aiddir?",
  "Şeir lirik növə aiddir.",
  ["Lirik növə", "Epik növə", "Dram növünə", "Publisistikaya"],
  1, None, 2),
 ("«Babəkin andı» hansı tarixi şəxsiyyətə həsr olunmuşdur?",
  "Əsər Babəkə həsr olunmuşdur.",
  ["Babəkə", "Koroğluya", "Cavanşirə", "Şah İsmayıla"], 1, None, 2),
 ("Babək hansı hərəkatın rəhbəri olmuşdur?",
  "O, ərəb işğalına qarşı azadlıq hərəkatının rəhbəri olmuşdur.",
  ["Ərəb işğalına qarşı hərəkatın",
   "Monqol işğalına qarşı hərəkatın",
   "Rus işğalına qarşı hərəkatın",
   "Səlib yürüşlərinə qarşı hərəkatın"], 1, None, 2),
 ("«Qələbə müjdəsi» əsərinin müəllifi kimdir?",
  "Əsərin müəllifi Rahil Məmməddir.",
  ["Rahil Məmməd", "Eyvaz Zeynallı", "Zahid Xəlil",
   "Mikayıl Rzaquluzadə"], 1, None, 2),
 ("«Sonuncu güllə» əsərinin müəllifi kimdir?",
  "Əsərin müəllifi Zahid Xəlildir.",
  ["Zahid Xəlil", "Rahil Məmməd", "Mirzə İbrahimov",
   "Eyvaz Zeynallı"], 1, None, 2),
 ("Zahid Xəlil ədəbiyyatın hansı sahəsində tanınır?",
  "O, uşaq ədəbiyyatı sahəsində tanınır.",
  ["Uşaq ədəbiyyatında", "Elmi fantastikada", "Memarlıqda",
   "Bəstəkarlıqda"], 1, None, 2),
 ("Bu bölmənin əsas mövzusu nədir?",
  "Vətən sevgisi və qəhrəmanlıq mövzusudur.",
  ["Vətən sevgisi və qəhrəmanlıq", "Ticarət və sənaye",
   "Kosmos və texnika", "Dəniz macərası"], 1, None, 2),
 ("Mirzə İbrahimov hansı ədəbi növdə tanınmışdır?",
  "O, nəsrdə tanınmışdır.",
  ["Nəsrdə", "Aşıq şeirində", "Mənzum dramda", "Qəsidədə"],
  1, None, 2),
 ("Səməd Vurğunun şeirlərində hansı ovqat üstünlük təşkil edir?",
  "Nikbinlik və vətənpərvərlik ovqatı üstünlük təşkil edir.",
  ["Nikbinlik və vətənpərvərlik", "Kədər və ümidsizlik",
   "Yumor və zarafat", "Quru elmi soyuqluq"], 1, None, 2),
 ("Vətənpərvərlik mövzusunda yazılan əsərlərin məqsədi nədir?",
  "Oxucuda vətənə bağlılıq hissi aşılamaqdır.",
  ["Vətənə bağlılıq hissi aşılamaq", "Ticarəti öyrətmək",
   "Coğrafiya öyrətmək", "Riyaziyyat öyrətmək"], 1, None, 2),
 ("«Kəşfiyyatçılar» əsərinin mövzusu nə ilə bağlıdır?",
  "Mövzu müharibə və igidliklə bağlıdır.",
  ["Müharibə və igidliklə", "Ticarət səfəri ilə",
   "Kənd təsərrüfatı ilə", "Dəniz səyahəti ilə"], 1, None, 2),
 ("Qəhrəmanlıq mövzulu əsərlərdə baş obraz necə verilir?",
  "Fədakar və cəsur insan kimi verilir.",
  ["Fədakar və cəsur", "Qorxaq və laqeyd",
   "Xəsis və tamahkar", "Etinasız və süst"], 1, None, 2),
 ("«Azərbaycan» şeirində vətən obrazı necə canlandırılır?",
  "Vətən ana kimi doğma və müqəddəs varlıq kimi canlandırılır.",
  ["Ana kimi doğma və müqəddəs", "Yad və uzaq bir yer kimi",
   "Sadəcə coğrafi ərazi kimi", "Ticarət meydanı kimi"], 1, None, 2),
 ("Mikayıl Rzaquluzadə hansı mövzuya müraciət etmişdir?",
  "O, tarixi qəhrəmanlıq mövzusuna müraciət etmişdir.",
  ["Tarixi qəhrəmanlıq mövzusuna", "Kosmos mövzusuna",
   "Dəniz macərası mövzusuna", "Memarlıq mövzusuna"], 1, None, 2),
 ("Bu bölmədəki əsərlər hansı ədəbi növlərdədir?",
  "Bölmədə həm nəsr, həm də şeir nümunələri var.",
  ["Həm nəsr, həm şeir", "Ancaq dram", "Ancaq publisistika",
   "Ancaq qəzəl"], 1, None, 2),
 # ---- cetin (12)
 ("Vətən mövzusu üzrə «əsər - müəllif» cütlüyü hansı düzgündür?",
  "«Azad» Mirzə İbrahimovun, «Azərbaycan» isə Səməd Vurğunundur.",
  ["«Azad» - Mirzə İbrahimov", "«Azad» - Zahid Xəlil",
   "«Azərbaycan» - Mirzə İbrahimov",
   "«Babəkin andı» - Eyvaz Zeynallı"], 1, None, 3),
 ("Vətən bölməsi barədə aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "«Azərbaycan» şeirinin müəllifi Səməd Vurğundur.",
  ["«Azərbaycan» şeirinin müəllifi Zahid Xəlildir",
   "«Azad» Mirzə İbrahimovun əsəridir",
   "«Babəkin andı» Rzaquluzadənindir",
   "«Sonuncu güllə» Zahid Xəlilindir"], 1, None, 3),
 ("Şeir və hekayənin vətənpərvərlik mövzusunu açma yolu necə fərqlənir?",
  "Şeir duyğu ilə, hekayə isə hadisə ilə açır.",
  ["Şeir duyğu ilə, hekayə hadisə ilə açır",
   "Şeir hadisə ilə, hekayə duyğu ilə açır",
   "Hər ikisi eyni yolla açır",
   "Hər ikisi sənədli üsulla açır"], 1, None, 3),
 ("Babək obrazının ədəbiyyata gətirilməsinin səbəbi nədir?",
  "Babək azadlıq mübarizəsinin simvoluna çevrilmişdir.",
  ["Azadlıq mübarizəsinin simvolu olması",
   "Yeni ticarət yolları açmış olması",
   "Böyük şəhərlər saldırmış olması",
   "Dəyərli elmi əsərlər yazması"], 1, None, 3),
 ("Tarixi şəxsiyyətlər üzrə «şəxs - fəaliyyət» cütlüyü hansı doğrudur?",
  "Babək ərəb işğalına qarşı azadlıq hərəkatının rəhbəridir.",
  ["Babək - azadlıq hərəkatının rəhbəri", "Babək - saray şairi",
   "Nizami - azadlıq hərəkatının rəhbəri", "Babək - karvan taciri"],
  1, None, 3),
 ("Aşağıdakı üç hadisə zaman ardıcıllığı ilə necə düzülür? "
  "(1 - «Azərbaycan» şeirinin yazılması, 2 - Babək hərəkatı, "
  "3 - «Koroğlu» dastanının formalaşması)",
  "Babək hərəkatı IX əsrdə, dastan XVI-XVII əsrlərdə, şeir isə "
  "XX əsrdə meydana çıxmışdır.",
  ["2 - 3 - 1", "1 - 2 - 3", "3 - 2 - 1", "2 - 1 - 3"], 1, None, 3),
 ("Bölmənin mövzusu haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "Bölmənin mövzusu vətən sevgisi və qəhrəmanlıqdır.",
  ["Bu bölmənin mövzusu kosmos tədqiqatıdır",
   "Bölmənin mövzusu vətən sevgisidir",
   "«Azərbaycan» Səməd Vurğunun şeiridir",
   "Babək tarixi şəxsiyyətdir"], 1, None, 3),
 ("Səməd Vurğun və Mirzə İbrahimov haqqında hansı fikir doğrudur?",
  "Səməd Vurğun şair, Mirzə İbrahimov isə nasirdir.",
  ["Vurğun şair, Mirzə İbrahimov nasirdir",
   "Vurğun nasir, Mirzə İbrahimov şairdir",
   "Hər ikisi ancaq şair olmuşdur",
   "Hər ikisi ancaq dramaturq olmuşdur"], 1, None, 3),
 ("Vətən bölməsi üzrə «əsər - mövzu» cütlüyü hansı düzgündür?",
  "«Babəkin andı» tarixi qəhrəmanlıq mövzusundadır.",
  ["«Babəkin andı» - tarixi qəhrəmanlıq",
   "«Azərbaycan» - tarixi qəhrəmanlıq",
   "«Babəkin andı» - dəniz səfəri",
   "«Kəşfiyyatçılar» - dəniz səfəri"], 1, None, 3),
 ("Vətənpərvərlik mövzusunun dərslikdə geniş yer tutmasının səbəbi nədir?",
  "Şagirddə vətənə bağlılıq tərbiyə etmək məqsədi güdülür.",
  ["Şagirddə vətənə bağlılıq tərbiyəsi",
   "Dərsliyin həcmini artırmaq istəyi",
   "Xarici dil öyrətmək məqsədi",
   "Riyazi bacarıq qazandırmaq"], 1, None, 3),
 ("Tarixi qəhrəman ilə uydurma qəhrəmanın fərqi nədir?",
  "Tarixi qəhrəman real yaşamış, uydurma qəhrəman təxəyyül məhsuludur.",
  ["Biri real yaşamış, digəri təxəyyül məhsuludur",
   "Biri təxəyyül məhsulu, digəri real yaşamışdır",
   "Hər ikisi real yaşamış şəxslərdir",
   "Hər ikisi təxəyyül məhsuludur"], 1, None, 3),
 ("Bu bölmə üzrə «əsər - ədəbi növ» cütlüyü hansı doğrudur?",
  "«Azərbaycan» şeir, «Azad» isə nəsr əsəridir.",
  ["«Azərbaycan» - şeir", "«Azad» - şeir",
   "«Azərbaycan» - hekayə", "«Sonuncu güllə» - şeir"],
  1, None, 3)],
}
SUALLAR.update(HISSE_1)

HISSE_2 = {
"edeb-7-menevi": [
 # ---- asan (4)
 ("«Manqurt» hansı yazıçının əsərindən götürülmüşdür?",
  "Parça Çingiz Aytmatovun əsərindəndir.",
  ["Çingiz Aytmatovun", "Abdulla Şaiqin", "Mir Cəlalın",
   "Viktor Hüqonun"], 1, None, 1),
 ("«Hikmətin fəziləti» əsərinin müəllifi kimdir?",
  "Əsərin müəllifi Abbasqulu ağa Bakıxanovdur.",
  ["Abbasqulu ağa Bakıxanov", "Hikmət Ziya", "Fikrət Qoca",
   "Abdulla Şaiq"], 1, None, 1),
 ("«Kərgədan və qarışqa» hansı janrdadır?",
  "Bu, təmsildir.",
  ["Təmsil", "Roman", "Faciə", "Qəsidə"], 1, None, 1),
 ("«Usta Bəxtiyar» əsərinin müəllifi kimdir?",
  "Əsərin müəllifi Abdulla Şaiqdir.",
  ["Abdulla Şaiq", "Hikmət Ziya", "Fikrət Qoca",
   "Abbasqulu ağa Bakıxanov"], 1, None, 1),
 # ---- orta (15)
 ("«Manqurt» hansı romandan götürülmüşdür?",
  "Parça «Gün var əsrə bərabər» romanındandır.",
  ["«Gün var əsrə bərabər»", "«Səfillər»", "«Qorxulu nağıllar»",
   "«Gülüstani-İrəm»"], 1, None, 2),
 ("Manqurt sözü nə deməkdir?",
  "Yaddaşı silinmiş, kim olduğunu unudan insan deməkdir.",
  ["Yaddaşı silinmiş insan", "Uzaq ölkə taciri",
   "Saray məmuru", "Aşıq sənətkarı"], 1, None, 2),
 ("Manqurtu kimlər yaratmışdır?",
  "Onu əsir götürən düşmənlər yaddaşını məhv etməklə yaratmışdır.",
  ["Əsir götürən düşmənlər", "Öz doğma qohumları",
   "Karvan tacirləri", "Kənd müəllimləri"], 1, None, 2),
 ("Naiman-Ana obrazı kimdir?",
  "Naiman-Ana manqurtun anasıdır.",
  ["Manqurtun anası", "Manqurtun bacısı", "Düşmən başçısı",
   "Karvan rəhbəri"], 1, None, 2),
 ("Naiman-Ana ilə oğlunun görüşü necə bitir?",
  "Oğul anasını tanımır və onu oxla vurur.",
  ["Oğul anasını tanımır və onu vurur",
   "Ana və oğul birlikdə evə qayıdır",
   "Oğul yaddaşını tam bərpa edir",
   "Ana oğlunu heç tapa bilmir"], 1, None, 2),
 ("«Manqurt» parçasının əsas ideyası nədir?",
  "Yaddaşsızlığın, kökünü unutmağın faciəsidir.",
  ["Yaddaşsızlığın faciəsi", "Ticarətin faydası",
   "Ov ənənəsinin qorunması", "Elmi kəşfin əhəmiyyəti"], 1, None, 2),
 ("Təmsil nədir?",
  "Heyvan obrazları vasitəsilə əxlaqi dərs verən qısa əsərdir.",
  ["Heyvan obrazları ilə dərs verən qısa əsər",
   "Uzun tarixi roman", "Səhnə faciəsi", "Dörd misralı bayatı"],
  1, None, 2),
 ("Təmsilin sonunda adətən nə verilir?",
  "Sonda əxlaqi nəticə verilir.",
  ["Əxlaqi nəticə", "Müəllifin tərcümeyi-halı", "Coğrafi xəritə",
   "Riyazi düstur"], 1, None, 2),
 ("Abbasqulu ağa Bakıxanovun məşhur tarixi əsəri hansıdır?",
  "Onun məşhur tarixi əsəri «Gülüstani-İrəm»dir.",
  ["«Gülüstani-İrəm»", "«Gün var əsrə bərabər»",
   "«Qorxulu nağıllar»", "«Səfillər»"], 1, None, 2),
 ("Abbasqulu ağa Bakıxanovun ədəbi təxəllüsü nədir?",
  "Onun təxəllüsü Qüdsidir.",
  ["Qüdsi", "Hophop", "Vaqif", "Xətayi"], 1, None, 2),
 ("«Anamın sözləri» şeirinin müəllifi kimdir?",
  "Şeirin müəllifi Fikrət Qocadır.",
  ["Fikrət Qoca", "Hikmət Ziya", "Abdulla Şaiq",
   "Çingiz Aytmatov"], 1, None, 2),
 ("Mənəvi dəyərlər bölməsinin əsas mövzusu nədir?",
  "Mənəvi dəyərlər və həmişəyaşar hikmətlərdir.",
  ["Mənəvi dəyərlər və hikmət", "Sənaye tikintisi",
   "Dəniz ticarəti", "Kosmos tədqiqatı"], 1, None, 2),
 ("Abdulla Şaiq hansı ədəbi növlərdə yazmışdır?",
  "O, həm şeir, həm də nəsr yazmışdır.",
  ["Həm şeir, həm nəsr", "Ancaq dram", "Ancaq elmi məqalə",
   "Ancaq tərcümə"], 1, None, 2),
 ("Manqurt obrazı hansı təhlükəni xatırladır?",
  "Kökü, dili və yaddaşı unutmaq təhlükəsini xatırladır.",
  ["Kökü və yaddaşı unutmaq təhlükəsini",
   "Ticarətdə uduzmaq təhlükəsini", "Yolu azmaq təhlükəsini",
   "Xəstələnmək təhlükəsini"], 1, None, 2),
 ("Didaktik əsərlərin məqsədi nədir?",
  "Öyüd vermək, oxucunu tərbiyə etməkdir.",
  ["Öyüd vermək və tərbiyə etmək", "Ancaq güldürmək",
   "Tarixi salnamə yazmaq", "Coğrafi xəritə vermək"], 1, None, 2),
 # ---- cetin (12)
 ("Mənəvi dəyərlər bölməsi üzrə «əsər - müəllif» cütlüyü hansı düzgündür?",
  "«Manqurt» Aytmatovun, «Usta Bəxtiyar» isə Abdulla Şaiqindir.",
  ["«Manqurt» - Çingiz Aytmatov", "«Manqurt» - Abdulla Şaiq",
   "«Usta Bəxtiyar» - Çingiz Aytmatov",
   "«Hikmətin fəziləti» - Çingiz Aytmatov"], 1, None, 3),
 ("Mənəvi dəyərlər bölməsi barədə hansı fikir SƏHVDİR?",
  "«Gülüstani-İrəm» Abbasqulu ağa Bakıxanovun əsəridir.",
  ["«Gülüstani-İrəm» Aytmatovun əsəridir",
   "«Manqurt» Aytmatovun əsərindəndir",
   "«Hikmətin fəziləti» Bakıxanovundur",
   "«Usta Bəxtiyar» Abdulla Şaiqindir"], 1, None, 3),
 ("Təmsil ilə nağılın əsas fərqi nədir?",
  "Təmsildə sonda açıq əxlaqi nəticə verilir.",
  ["Təmsildə sonda açıq əxlaqi nəticə verilir",
   "Nağılda sonda açıq əxlaqi nəticə verilir",
   "Hər ikisində nəticə verilmir",
   "Hər ikisi hökmən şeirlə yazılır"], 1, None, 3),
 ("Manqurtun anasını tanımamasının səbəbi nədir?",
  "Onun yaddaşı zorla, işgəncə ilə məhv edilmişdi.",
  ["Yaddaşının zorla məhv edilməsi",
   "Uzun müddət ayrı qalmaları", "Gözlərinin görməməsi",
   "Anasının çox dəyişməsi"], 1, None, 3),
 ("Mənəvi dəyərlər bölməsi üzrə «obraz - əsər» cütlüyü hansı doğrudur?",
  "Naiman-Ana «Manqurt» parçasının obrazıdır.",
  ["Naiman-Ana - «Manqurt»", "Naiman-Ana - «Usta Bəxtiyar»",
   "Usta Bəxtiyar - «Manqurt»", "Nurəddin - «Manqurt»"],
  1, None, 3),
 ("«Manqurt» parçasında hadisələr necə sıralanır? "
  "(1 - ananın oğlunu tapması, 2 - oğlanın əsir düşməsi, "
  "3 - ananın həlak olması)",
  "Əvvəlcə oğlan əsir düşür, sonra ana onu tapır, sonda ana həlak olur.",
  ["2 - 1 - 3", "1 - 2 - 3", "3 - 2 - 1", "2 - 3 - 1"], 1, None, 3),
 ("Təmsil janrı haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "Təmsil qısa əsərdir, uzun tarixi roman deyil.",
  ["Təmsil uzun tarixi romandır",
   "Təmsildə heyvan obrazları olur",
   "Təmsil əxlaqi nəticə ilə bitir",
   "Təmsil qısa həcmli əsərdir"], 1, None, 3),
 ("Bakıxanov və Abdulla Şaiq haqqında hansı fikir doğrudur?",
  "Hər ikisi maarifçi mövqedən yazıb, öyrədici əsərlər yaratmışdır.",
  ["Hər ikisi maarifçi mövqedən yazmışdır",
   "Hər ikisi ancaq təmsil yazmışdır",
   "Biri şair, digəri bəstəkar olmuşdur",
   "Hər ikisi dünya ədəbiyyatı nümayəndəsidir"], 1, None, 3),
 ("Aşağıdakı «parça - mənbə» cütlüklərindən hansı düzgündür?",
  "«Manqurt» «Gün var əsrə bərabər» romanındandır.",
  ["«Manqurt» - «Gün var əsrə bərabər»",
   "«Manqurt» - «Qorxulu nağıllar»",
   "«Usta Bəxtiyar» - «Gün var əsrə bərabər»",
   "«Anamın sözləri» - «Gün var əsrə bərabər»"], 1, None, 3),
 ("«Manqurt» parçasının dünya oxucusuna doğma olmasının səbəbi nədir?",
  "Yaddaşsızlıq problemi ümumbəşəri məsələ kimi qoyulmuşdur.",
  ["Problemin ümumbəşəri qoyulması",
   "Parçanın qısa həcmli olması",
   "Sənədli material olması", "Uşaq nağılı olması"], 1, None, 3),
 ("Didaktik əsər ilə lirik şeirin fərqi nədir?",
  "Didaktik əsər öyüd verir, lirik şeir duyğu ifadə edir.",
  ["Biri öyüd verir, digəri duyğu ifadə edir",
   "Biri duyğu ifadə edir, digəri öyüd verir",
   "Hər ikisi ancaq öyüd verir",
   "Hər ikisi ancaq duyğu ifadə edir"], 1, None, 3),
 ("Aşağıdakı «şəxs - təxəllüs» cütlüklərindən hansı doğrudur?",
  "Abbasqulu ağa Bakıxanovun təxəllüsü Qüdsidir.",
  ["Abbasqulu ağa Bakıxanov - Qüdsi", "Abdulla Şaiq - Qüdsi",
   "Abbasqulu ağa Bakıxanov - Hophop", "Fikrət Qoca - Qüdsi"],
  1, None, 3)],

"edeb-7-usaq": [
 # ---- asan (4)
 ("«Nurəddin» əsərinin müəllifi kimdir?",
  "Əsərin müəllifi Süleyman Sani Axundovdur.",
  ["Süleyman Sani Axundov", "Mir Cəlal", "Ənvər Məmmədxanlı",
   "Elçin Hüseynbəyli"], 1, None, 1),
 ("«Qavroş» hansı yazıçının əsərindən götürülmüşdür?",
  "Parça Viktor Hüqonun əsərindəndir.",
  ["Viktor Hüqonun", "Mir Cəlalın", "Çingiz Aytmatovun",
   "Süleyman Sani Axundovun"], 1, None, 1),
 ("Yeddinci sinifdə keçilən «Bahar» əsərinin müəllifi kimdir?",
  "Əsərin müəllifi Mir Cəlaldır.",
  ["Mir Cəlal", "Ənvər Məmmədxanlı", "Elçin Hüseynbəyli",
   "Viktor Hüqo"], 1, None, 1),
 ("«Qızıl qönçələr» əsərinin müəllifi kimdir?",
  "Əsərin müəllifi Ənvər Məmmədxanlıdır.",
  ["Ənvər Məmmədxanlı", "Mir Cəlal", "Süleyman Sani Axundov",
   "Elçin Hüseynbəyli"], 1, None, 1),
 # ---- orta (15)
 ("«Nurəddin» hansı silsiləyə daxildir?",
  "Əsər «Qorxulu nağıllar» silsiləsinə daxildir.",
  ["«Qorxulu nağıllar»", "«Gün var əsrə bərabər»", "«Səfillər»",
   "«Xəmsə»"], 1, None, 2),
 ("Nurəddin obrazı hansı vəziyyətdə olan uşaqdır?",
  "O, yetim və kimsəsiz uşaqdır.",
  ["Yetim və kimsəsiz uşaq", "Varlı ailənin oğlu",
   "Saray uşağı", "Xaricdən gələn qonaq"], 1, None, 2),
 ("«Qavroş» hansı romandan götürülmüşdür?",
  "Parça «Səfillər» romanındandır.",
  ["«Səfillər»", "«Qorxulu nağıllar»", "«Gün var əsrə bərabər»",
   "«Gülüstani-İrəm»"], 1, None, 2),
 ("Qavroş hansı şəhərin küçə uşağıdır?",
  "Qavroş Paris küçələrinin uşağıdır.",
  ["Parisin", "Londonun", "Romanın", "Bakının"], 1, None, 2),
 ("Viktor Hüqo hansı ölkənin yazıçısıdır?",
  "Viktor Hüqo Fransa yazıçısıdır.",
  ["Fransanın", "İngiltərənin", "Almaniyanın", "İtaliyanın"],
  1, None, 2),
 ("Uşaq bölməsinin əsas mövzusu nədir?",
  "Uşaq aləmi və uşaq taleyi mövzusudur.",
  ["Uşaq aləmi və uşaq taleyi", "Dəniz ticarəti",
   "Kosmos yarışı", "Hərbi taktika"], 1, None, 2),
 ("«Nəvə» əsərinin müəllifi kimdir?",
  "Əsərin müəllifi Elçin Hüseynbəylidir.",
  ["Elçin Hüseynbəyli", "Mir Cəlal", "Ənvər Məmmədxanlı",
   "Viktor Hüqo"], 1, None, 2),
 ("«Qorxulu nağıllar» silsiləsinin əsas məqsədi nədir?",
  "Yetim və kimsəsiz uşaqların ağır taleyini göstərməkdir.",
  ["Yetim uşaqların taleyini göstərmək",
   "Ov qaydalarını öyrətmək", "Ticarəti təbliğ etmək",
   "Coğrafiya öyrətmək"], 1, None, 2),
 ("Qavroş obrazı hansı keyfiyyəti ilə seçilir?",
  "Cəsarəti və xeyirxahlığı ilə seçilir.",
  ["Cəsarəti və xeyirxahlığı", "Xəsisliyi", "Qorxaqlığı",
   "Laqeydliyi"], 1, None, 2),
 ("Uşaq ədəbiyyatının əsas vəzifəsi nədir?",
  "Uşağa tərbiyə və dünyagörüşü verməkdir.",
  ["Tərbiyə və dünyagörüşü vermək", "Ticarət öyrətmək",
   "Hərbi hazırlıq vermək", "Riyaziyyat öyrətmək"], 1, None, 2),
 ("Mir Cəlal hansı ədəbi növdə tanınmışdır?",
  "Mir Cəlal nəsrdə tanınmışdır.",
  ["Nəsrdə", "Mənzum dramda", "Qəsidədə", "Aşıq şeirində"],
  1, None, 2),
 ("«Qavroş» parçasında uşağın taleyi necə göstərilir?",
  "Yoxsulluq içində, lakin ruhdan düşmədən göstərilir.",
  ["Yoxsulluq içində, ruhdan düşmədən", "Var-dövlət içində",
   "Sarayda rahat şəraitdə", "Xaricdə təhsil alarkən"], 1, None, 2),
 ("Bədii əsərdə uşaq obrazının verilməsi nəyə imkan yaradır?",
  "Cəmiyyətin vəziyyətini uşağın gözü ilə göstərməyə imkan verir.",
  ["Cəmiyyəti uşağın gözü ilə göstərməyə", "Ordunun gücünü ölçməyə",
   "Ticarətin həcmini saymağa", "Coğrafi mövqeyi təyin etməyə"],
  1, None, 2),
 ("Elçin Hüseynbəyli hansı dövrün yazıçısıdır?",
  "O, müasir dövrün yazıçısıdır.",
  ["Müasir dövrün", "XII əsrin", "XVI əsrin",
   "XIX əsrin əvvəlinin"], 1, None, 2),
 ("Ənvər Məmmədxanlı hansı ədəbi növdə çalışmışdır?",
  "O, nəsr sahəsində çalışmışdır.",
  ["Nəsr sahəsində", "Aşıq şeirində", "Mənzum dramda",
   "Elmi tənqiddə"], 1, None, 2),
 # ---- cetin (12)
 ("Uşaq mövzusu üzrə «əsər - müəllif» cütlüyü hansı düzgündür?",
  "«Nurəddin» S.S.Axundovun, «Bahar» isə Mir Cəlalındır.",
  ["«Nurəddin» - Süleyman Sani Axundov", "«Nurəddin» - Mir Cəlal",
   "«Bahar» - Süleyman Sani Axundov", "«Qavroş» - Mir Cəlal"],
  1, None, 3),
 ("Uşaq bölməsi haqqında hansı fikir SƏHVDİR?",
  "«Qavroş» Viktor Hüqonun əsərindəndir.",
  ["«Qavroş» Mir Cəlalın əsəridir",
   "«Qavroş» Viktor Hüqonun əsərindəndir",
   "«Nurəddin» S.S.Axundovundur",
   "«Nəvə» Elçin Hüseynbəylinindir"], 1, None, 3),
 ("Nurəddin və Qavroş obrazlarının ortaq cəhəti nədir?",
  "Hər ikisi çətin şəraitdə yaşayan uşaq obrazıdır.",
  ["Hər ikisi çətin şəraitdə yaşayan uşaqdır",
   "Hər ikisi varlı ailə uşağıdır",
   "Biri uşaq, digəri qoca obrazıdır",
   "Hər ikisi saray mühitində böyüyür"], 1, None, 3),
 ("«Qorxulu nağıllar» silsiləsinin belə adlandırılmasının səbəbi nədir?",
  "Uşaq taleyinin ağır və acı olması bu adı doğurmuşdur.",
  ["Uşaq taleyinin ağır və acı olması",
   "Qəhrəmanların sehrli olması",
   "Hadisələrin gecə baş verməsi", "Əsərlərin uzun olması"],
  1, None, 3),
 ("Aşağıdakı «parça - roman» cütlüklərindən hansı doğrudur?",
  "«Qavroş» «Səfillər» romanından götürülmüşdür.",
  ["«Qavroş» - «Səfillər» romanı",
   "«Qavroş» - «Qorxulu nağıllar»",
   "«Nurəddin» - «Səfillər» romanı",
   "«Bahar» - «Səfillər» romanı"], 1, None, 3),
 ("Üç yazıçı yaşadıqları dövrün ardıcıllığı ilə necə düzülür? "
  "(1 - Elçin Hüseynbəyli, 2 - Viktor Hüqo, "
  "3 - Süleyman Sani Axundov)",
  "Hüqo XIX əsrdə, S.S.Axundov XIX əsrin sonu - XX əsrin əvvəlində, "
  "Elçin Hüseynbəyli isə müasir dövrdə yaşamışdır.",
  ["2 - 3 - 1", "1 - 2 - 3", "3 - 2 - 1", "2 - 1 - 3"], 1, None, 3),
 ("Obrazlar haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "Qavroş küçədə yaşayan yoxsul uşaqdır.",
  ["Qavroş varlı ailənin uşağıdır",
   "Qavroş Paris küçələrinin uşağıdır",
   "Nurəddin yetim uşaqdır",
   "Hər iki obraz uşaq obrazıdır"], 1, None, 3),
 ("Viktor Hüqo və Süleyman Sani Axundov haqqında hansı fikir doğrudur?",
  "Hüqo fransız, S.S.Axundov isə Azərbaycan yazıçısıdır.",
  ["Hüqo fransız, Axundov Azərbaycan yazıçısıdır",
   "Hüqo Azərbaycan, Axundov fransız yazıçısıdır",
   "Hər ikisi fransız yazıçısıdır",
   "Hər ikisi Azərbaycan yazıçısıdır"], 1, None, 3),
 ("Aşağıdakı «obraz - ölkə» cütlüklərindən hansı düzgündür?",
  "Qavroş fransız ədəbiyyatının obrazıdır.",
  ["Qavroş - Fransa", "Nurəddin - Fransa", "Qavroş - Azərbaycan",
   "Manqurt - Fransa"], 1, None, 3),
 ("Yazıçıların uşaq obrazına müraciət etməsinin səbəbi nədir?",
  "Cəmiyyətdəki ədalətsizliyi daha kəskin göstərmək üçün.",
  ["Ədalətsizliyi kəskin göstərmək üçün",
   "Əsəri qısaltmaq istəyi ilə", "Dərslik tələbi ilə",
   "Tərcüməni asanlaşdırmaq üçün"], 1, None, 3),
 ("Uşaq ədəbiyyatı ilə uşaq haqqında ədəbiyyatın fərqi nədir?",
  "Biri uşaq üçün, digəri uşaq haqqında yazılır.",
  ["Biri uşaq üçün, digəri uşaq haqqında yazılır",
   "Biri uşaq haqqında, digəri uşaq üçün yazılır",
   "İkisi arasında heç bir fərq yoxdur",
   "Hər ikisi ancaq böyüklər üçün yazılır"], 1, None, 3),
 ("Uşaq bölməsi üzrə «əsər - ədəbi növ» cütlüyü hansı doğrudur?",
  "«Nurəddin» nəsr əsəri, «Anamın sözləri» isə şeirdir.",
  ["«Nurəddin» - nəsr əsəri", "«Nurəddin» - şeir",
   "«Anamın sözləri» - nəsr əsəri",
   "«Azərbaycan» - nəsr əsəri"], 1, None, 3)],

"edeb-7-tebiet": [
 # ---- asan (4)
 ("«Yağış yağarkən» şeirinin müəllifi kimdir?",
  "Şeirin müəllifi Mikayıl Müşfiqdir.",
  ["Mikayıl Müşfiq", "Əliağa Kürçaylı", "Hüseyn Arif",
   "Bayram Həsənov"], 1, None, 1),
 ("«Qaranquş» şeirinin müəllifi kimdir?",
  "Şeirin müəllifi Əliağa Kürçaylıdır.",
  ["Əliağa Kürçaylı", "Mikayıl Müşfiq", "Hüseyn Arif",
   "İlyas Əfəndiyev"], 1, None, 1),
 ("«Şəhərdən gələn ovçu» əsərinin müəllifi kimdir?",
  "Əsərin müəllifi İlyas Əfəndiyevdir.",
  ["İlyas Əfəndiyev", "Bayram Həsənov", "Hüseyn Arif",
   "Mikayıl Müşfiq"], 1, None, 1),
 ("Təbiət bölməsinin əsas mövzusu nədir?",
  "Təbiətə vurğunluq və təbiətə qayğı mövzusudur.",
  ["Təbiətə vurğunluq və qayğı", "Hərbi taktika",
   "Ticarət qaydaları", "Kosmos tədqiqatı"], 1, None, 1),
 # ---- orta (15)
 ("«İki bala» əsərinin müəllifi kimdir?",
  "Əsərin müəllifi Bayram Həsənovdur.",
  ["Bayram Həsənov", "Hüseyn Arif", "Əliağa Kürçaylı",
   "İlyas Əfəndiyev"], 1, None, 2),
 ("«Yaşıl işıq» əsərinin müəllifi kimdir?",
  "Əsərin müəllifi Hüseyn Arifdir.",
  ["Hüseyn Arif", "Bayram Həsənov", "Mikayıl Müşfiq",
   "İlyas Əfəndiyev"], 1, None, 2),
 ("«Yağış yağarkən» şeirində nə təsvir olunur?",
  "Yağışlı təbiət mənzərəsi təsvir olunur.",
  ["Yağışlı təbiət mənzərəsi", "Şəhər tikintisi",
   "Dəniz döyüşü", "Ticarət bazarı"], 1, None, 2),
 ("Mikayıl Müşfiqin şeirlərində təbiət necə verilir?",
  "Təbiət canlı, duyğulu obrazlarla verilir.",
  ["Canlı və duyğulu obrazlarla", "Quru rəqəmlərlə",
   "Sənədli hesabat kimi", "Xəritə üzərində"], 1, None, 2),
 ("«Şəhərdən gələn ovçu» hansı ədəbi növə aiddir?",
  "Əsər nəsrə aiddir.",
  ["Nəsrə", "Poeziyaya", "Dramaturgiyaya", "Publisistikaya"],
  1, None, 2),
 ("Təbiət mövzulu əsərlərin əsas çağırışı nədir?",
  "Təbiəti qorumaq çağırışıdır.",
  ["Təbiəti qorumaq", "Ov etməyi öyrənmək",
   "Ticarəti artırmaq", "Yeni şəhər salmaq"], 1, None, 2),
 ("Qaranquş obrazı şeirdə nəyi bildirir?",
  "Baharı və doğma yurdu bildirir.",
  ["Baharı və doğma yurdu", "Qışın gəlişini",
   "Ticarət yolunu", "Döyüş nişanını"], 1, None, 2),
 ("Əliağa Kürçaylı hansı ədəbi növdə çalışmışdır?",
  "O, poeziyada çalışmışdır.",
  ["Poeziyada", "Dramaturgiyada", "Elmi nəsrdə",
   "Publisistikada"], 1, None, 2),
 ("İlyas Əfəndiyev hansı ədəbi növlərdə tanınmışdır?",
  "O, həm nəsrdə, həm də dramaturgiyada tanınmışdır.",
  ["Həm nəsrdə, həm dramaturgiyada", "Ancaq aşıq şeirində",
   "Ancaq qəsidədə", "Ancaq tərcümədə"], 1, None, 2),
 ("Təbiət təsvirində hansı bədii vasitələr çox işlənir?",
  "Epitet və bənzətmə çox işlənir.",
  ["Epitet və bənzətmə", "Sənədli statistika", "Riyazi düstur",
   "Xəritə işarəsi"], 1, None, 2),
 ("«Şəhərdən gələn ovçu» adı hansı ziddiyyəti göstərir?",
  "Şəhər adamı ilə təbiət arasındakı ziddiyyəti göstərir.",
  ["Şəhər adamı ilə təbiət arasındakı", "İki ölkə arasındakı",
   "İki nəsil arasındakı", "İki dil arasındakı"], 1, None, 2),
 ("Peyzaj nədir?",
  "Bədii əsərdə təbiət təsviridir.",
  ["Bədii əsərdə təbiət təsviri", "Qəhrəmanın portreti",
   "Əsərin sonluğu", "Şeirin vəzni"], 1, None, 2),
 ("Ekoloji mövzu ədəbiyyatda nəyi qabardır?",
  "İnsanın təbiət qarşısındakı məsuliyyətini qabardır.",
  ["İnsanın təbiət qarşısında məsuliyyətini",
   "Ticarətin faydasını", "Hərbi gücü",
   "Şəhər memarlığını"], 1, None, 2),
 ("Hüseyn Arif hansı ədəbi növün nümayəndəsidir?",
  "Hüseyn Arif poeziyanın nümayəndəsidir.",
  ["Poeziyanın", "Dramaturgiyanın", "Elmi nəsrin",
   "Publisistikanın"], 1, None, 2),
 ("Təbiət mövzulu şeirlərdə lirik qəhrəmanın münasibəti necə olur?",
  "Sevgi və heyranlıq münasibəti olur.",
  ["Sevgi və heyranlıq", "Tam laqeydlik", "Qorxu və nifrət",
   "Soyuq etinasızlıq"], 1, None, 2),
 # ---- cetin (12)
 ("Təbiət bölməsi üzrə «əsər - müəllif» cütlüyü hansı düzgündür?",
  "«Qaranquş» Kürçaylının, «Yağış yağarkən» isə Müşfiqindir.",
  ["«Qaranquş» - Əliağa Kürçaylı", "«Qaranquş» - Hüseyn Arif",
   "«Yağış yağarkən» - Əliağa Kürçaylı",
   "«Yaşıl işıq» - Mikayıl Müşfiq"], 1, None, 3),
 ("Təbiət bölməsi barədə aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "«Yağış yağarkən» Mikayıl Müşfiqin şeiridir.",
  ["«Yağış yağarkən» İlyas Əfəndiyevindir",
   "«Yağış yağarkən» Mikayıl Müşfiqindir",
   "«Qaranquş» Əliağa Kürçaylınındır",
   "«Yaşıl işıq» Hüseyn Arifindir"], 1, None, 3),
 ("Şeirdə və nəsrdə təbiət təsvirinin fərqi nədir?",
  "Şeirdə duyğu, nəsrdə isə hadisə fonu kimi verilir.",
  ["Şeirdə duyğu, nəsrdə hadisə fonu kimi verilir",
   "Şeirdə hadisə fonu, nəsrdə duyğu kimi verilir",
   "Hər ikisində eyni cür verilir",
   "Heç birində təbiət təsviri olmur"], 1, None, 3),
 ("Təbiət mövzusunun müasir ədəbiyyatda güclənməsinin səbəbi nədir?",
  "Ekoloji problemlərin kəskinləşməsi bu mövzunu gücləndirmişdir.",
  ["Ekoloji problemlərin kəskinləşməsi",
   "Şəhərlərin sayının azalması",
   "Ov ənənəsinin tamam bitməsi",
   "Kitab sayının kəskin artması"], 1, None, 3),
 ("Təbiət bölməsi üzrə «əsər - ədəbi növ» cütlüyü hansı doğrudur?",
  "«Şəhərdən gələn ovçu» nəsr, «Qaranquş» isə şeirdir.",
  ["«Şəhərdən gələn ovçu» - nəsr",
   "«Şəhərdən gələn ovçu» - şeir", "«Qaranquş» - nəsr",
   "«Yağış yağarkən» - nəsr"], 1, None, 3),
 ("Üç şair-yazıçı dövr baxımından necə düzülür? "
  "(1 - Mikayıl Müşfiq, 2 - müasir dövr müəllifləri, "
  "3 - Əliağa Kürçaylı)",
  "Müşfiq 1930-cu illərdə, Kürçaylı XX əsrin ikinci yarısında, "
  "müasir müəlliflər isə daha sonra yazmışdır.",
  ["3 - 1 - 2", "1 - 2 - 3", "2 - 1 - 3", "2 - 3 - 1"], 1, None, 3),
 ("Ədəbiyyat nəzəriyyəsi üzrə aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "Peyzaj təbiət təsviridir, qəhrəmanın portreti deyil.",
  ["Peyzaj qəhrəmanın portretidir",
   "Peyzaj bədii əsərdə təbiət təsviridir",
   "Epitet bədii təyin yaradır",
   "Bənzətmə oxşarlığa əsaslanır"], 1, None, 3),
 ("Mikayıl Müşfiq və Əliağa Kürçaylı haqqında hansı fikir doğrudur?",
  "Hər ikisi şair kimi tanınmışdır.",
  ["Hər ikisi şair kimi tanınmışdır",
   "Hər ikisi nasir kimi tanınmışdır",
   "Biri şair, digəri dramaturq olmuşdur",
   "Hər ikisi ancaq tərcüməçi olmuşdur"], 1, None, 3),
 ("Təbiət təsviri üzrə «anlayış - tərif» cütlüyü hansı düzgündür?",
  "Peyzaj təbiət təsviri, portret isə xarici görünüş təsviridir.",
  ["Peyzaj - təbiət təsviri", "Portret - təbiət təsviri",
   "Peyzaj - qəhrəmanın xarici görünüşü",
   "Süjet - təbiət təsviri"], 1, None, 3),
 ("«Şəhərdən gələn ovçu» adının seçilməsinin səbəbi nədir?",
  "Ad şəhərlə təbiət arasındakı ziddiyyəti vurğulayır.",
  ["Şəhərlə təbiət ziddiyyətini vurğulamaq",
   "Ov qaydalarını öyrətmək",
   "Şəhər memarlığını təsvir etmək",
   "Ticarət yolunu göstərmək"], 1, None, 3),
 ("Təbiəti vəsf etmək ilə təbiəti qorumağa çağırmaq arasında fərq nədir?",
  "Biri gözəlliyi göstərir, digəri məsuliyyət tələb edir.",
  ["Biri gözəlliyi göstərir, digəri məsuliyyət tələb edir",
   "Biri məsuliyyət tələb edir, digəri gözəlliyi göstərir",
   "Hər ikisi eyni məqsəd daşıyır",
   "Hər ikisi ancaq gözəlliyi göstərir"], 1, None, 3),
 ("Bu bölmə üzrə «şair - əsər» cütlüyü hansı doğrudur?",
  "«Yaşıl işıq» Hüseyn Arifin əsəridir.",
  ["Hüseyn Arif - «Yaşıl işıq»", "Hüseyn Arif - «Qaranquş»",
   "Mikayıl Müşfiq - «Yaşıl işıq»",
   "Bayram Həsənov - «Yaşıl işıq»"], 1, None, 3)],
}
SUALLAR.update(HISSE_2)


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
    #  ANS qaydasi: eyni duzgun cavab metni bank uzre 2 defeden cox olmasin
    cavab = {}
    for movzu, siyahi in SUALLAR.items():
        for body, why, opts, correct, _e, _d in siyahi:
            cavab.setdefault(opts[correct - 1], []).append(movzu)
    for c, yer in sorted(cavab.items()):
        if len(yer) > 2:
            print("XETA  duzgun cavab %d defe: «%s» (%s)"
                  % (len(yer), c, ", ".join(yer)))
            xeta += 1
    print("%d sual yoxlandı, %d xəta" % (n, xeta))
    return xeta == 0, n


def sql_yaz(n):
    q = lambda t: t.replace("'", "''")
    setirler = []
    for movzu, rub in MOVZULAR:
        pay = movzu.split("-")          # edeb, 11, tenqidi, realizm
        on = "edeb" + pay[1]
        qisa = "-".join(pay[2:])
        for i, (body, why, opts, correct, _e, diff) in enumerate(SUALLAR[movzu], 1):
            setirler.append(
                "('%s-%s#%d','edebiyyat','%s',%d,%d,'%s','%s',"
                "array['%s','%s','%s','%s'],%d)"
                % (on, qisa, i, movzu, diff, rub, q(body), q(why),
                   q(opts[0]), q(opts[1]), q(opts[2]), q(opts[3]), correct))
    with io.open(CIXIS, "w", encoding="utf-8") as f:
        f.write("""-- =====================================================================
--  64_bank_edebiyyat7.sql : EDEBIYYAT 7 BANKI
--
--  BU FAYL ELLE YAZILMIR - tools/edebiyyat7.py yaradir:
--      python3 tools/edebiyyat7.py
--
--  5 movzu x 31 sual = %d.  Her movzuda 4 asan + 15 orta + 12 cetin.
--  ext_key: edeb11-...
--  ON SERT: 61_movzular_edebiyyat5_8.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'edebiyyat' and t.slug in
           ('edeb-7-sifahi', 'edeb-7-tebiet')
     having count(*) = 2) then
    raise exception 'ONCE 61_movzular_edebiyyat5_8.sql isledilmelidir.';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and q.ext_key like 'edeb7-%%';

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
   where owner_type = 'platform' and ext_key like 'edeb7-%%';
  if n <> %d then
    raise exception 'Edebiyyat 7 suallari: %d gozlenilirdi, %% tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'edeb7-%%'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '%% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'edeb7-%%';
  if k <> 5 then
    raise exception 'movzu sayi 5 deyil: %%', k;
  end if;
  --  Her movzuda en azi 12 cetin sual olmalidir ki, muellim BIR
  --  movzudan 10 sualliq cetin test yiga bilsin
  select count(*) into k from (
    select q.topic_id from public.questions q
     where q.ext_key like 'edeb7-%%' and q.difficulty = 3
     group by q.topic_id having count(*) < 12) z;
  if k > 0 then
    raise exception '%% movzuda 12-den az cetin sual var', k;
  end if;
  raise notice 'Edebiyyat 7 banki: %% sual, 5 movzu (her birinde 12 cetin).', n;
end $$;
""" % (n, ",\n".join(setirler), n, n))
    print("yazildi: %s" % CIXIS)


if __name__ == "__main__":
    ok, n = yoxla()
    if not ok:
        raise SystemExit(1)
    sql_yaz(n)
