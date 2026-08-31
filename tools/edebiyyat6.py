#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Edebiyyat 6 banki -> db/63_bank_edebiyyat6.sql

    5 movzu x 31 sual = 155

Movzular 61_movzular_edebiyyat5_8.sql agacina uygundur (e-derslik
kitab id 911).  Derslikde bolmeler TEMA uzredir.
Dersliyin BEDII METNI goturulmur; suallar mundericatdan cixan
faktlar (muellif-eser, bolme, edebi nov, janr) ve dovre uygun
edebiyyat nezeriyyesi uzerinde qurulur.

CETINLIK BOLGUSU her movzuda:  4 asan + 15 orta + 12 cetin.
"""
import io
import os

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CIXIS = os.path.join(KOK, "db", "63_bank_edebiyyat6.sql")

MOVZULAR = [
    ("edeb-6-sifahi", 1),
    ("edeb-6-usaq",   2),
    ("edeb-6-yurd",   2),
    ("edeb-6-menevi", 3),
    ("edeb-6-tebiet", 4),
]

BOLGU = {1: 4, 2: 15, 3: 12}

SUALLAR = {}

HISSE_1 = {
"edeb-6-sifahi": [
 # ---- asan (4)
 ("«Alı kişi» parçası hansı xalq dastanının hissəsidir?",
  "Parça «Koroğlu» dastanındandır.",
  ["«Koroğlu»", "«Kitabi-Dədə Qorqud»", "«Əsli və Kərəm»",
   "«Aşıq Qərib»"], 1, None, 1),
 ("Alı kişi «Koroğlu» dastanında kimdir?",
  "Alı kişi Koroğlunun atasıdır.",
  ["Koroğlunun atası", "Koroğlunun oğlu", "Düşmən xanı",
   "Çənlibelin aşığı"], 1, None, 1),
 ("Şifahi xalq ədəbiyyatı nümunələrini kim yaradır?",
  "Onları xalq yaradır, konkret müəllifi olmur.",
  ["Xalq", "Saray katibi", "Xarici tərcüməçi", "Dövlət məmuru"],
  1, None, 1),
 ("«Su həsrəti» mətni hansı ədəbiyyata aiddir?",
  "Mətn şifahi xalq ədəbiyyatına aiddir.",
  ["Şifahi xalq ədəbiyyatına", "Yazılı saray ədəbiyyatına",
   "Elmi ədəbiyyata", "Tərcümə ədəbiyyatına"], 1, None, 1),
 # ---- orta (15)
 ("Alı kişi hansı peşə sahibidir?",
  "O, xanın ilxısına baxan ilxıçıdır.",
  ["İlxıçı", "Dəmirçi", "Dərzi", "Karvan taciri"], 1, None, 2),
 ("Alı kişinin başına gələn faciə nədir?",
  "Onun gözləri kor edilir.",
  ["Gözlərinin kor edilməsi", "Evinin yanması",
   "Sürüsünün itməsi", "Uzaq sürgünə göndərilməsi"], 1, None, 2),
 ("Bu faciə Koroğlunun taleyində nəyə səbəb olur?",
  "Koroğlunun zülmə qarşı üsyana qalxmasına səbəb olur.",
  ["Zülmə qarşı üsyana", "Ticarətə başlamasına",
   "Şəhərə köçməsinə", "Uzaqda təhsil almasına"], 1, None, 2),
 ("Şifahi xalq ədəbiyyatının yaşamasında kimlər rol oynayır?",
  "Söyləyicilər və aşıqlar rol oynayır.",
  ["Söyləyicilər və aşıqlar", "Saray katibləri",
   "Xarici tərcüməçilər", "Dövlət məmurları"], 1, None, 2),
 ("Dastan hansı ədəbi növə aiddir?",
  "Dastan epik növə aiddir.",
  ["Epik növə", "Lirik növə", "Dram növünə", "Publisistikaya"],
  1, None, 2),
 ("Alı kişi obrazı hansı keyfiyyəti ilə yadda qalır?",
  "Səbri və mərdliyi ilə yadda qalır.",
  ["Səbir və mərdlik", "Xəsislik", "Qorxaqlıq", "Laqeydlik"],
  1, None, 2),
 ("Xalq yaradıcılığında hansı obrazlar çox işlənir?",
  "Xeyirxah qəhrəman və zalım obrazı çox işlənir.",
  ["Xeyirxah qəhrəman və zalım obrazı", "Ancaq saray adamları",
   "Ancaq xarici tacirlər", "Ancaq alimlər"], 1, None, 2),
 ("«Qanlı daş» mətni hansı ədəbiyyata aiddir?",
  "Bu mətn də şifahi xalq ədəbiyyatına aiddir.",
  ["Şifahi xalq ədəbiyyatına", "Yazılı divan ədəbiyyatına",
   "Elmi ədəbiyyata", "Xarici tərcümə ədəbiyyatına"], 1, None, 2),
 ("Dastan söyləyən xalq sənətkarı necə adlanır?",
  "O, aşıq adlanır.",
  ["Aşıq", "Rəssam", "Memar", "Bəstəkar"], 1, None, 2),
 ("Xalq yaradıcılığı nümunələri necə nəsildən-nəslə ötürülür?",
  "Şifahi yolla, söyləyicilər vasitəsilə ötürülür.",
  ["Şifahi yolla", "Rəsmi sənədlərlə", "Xarici tərcümələrlə",
   "Ancaq məktəb dərsliyi ilə"], 1, None, 2),
 ("Koroğlu obrazı hansı ideyanı daşıyır?",
  "Ədalət və azadlıq ideyasını daşıyır.",
  ["Ədalət və azadlıq", "Var-dövlət toplamaq",
   "Saray xidməti", "Ticarət uğuru"], 1, None, 2),
 ("«Alı kişi» parçasında ata-oğul münasibəti necə verilir?",
  "Oğul atasının haqqını qorumağa hazırlaşır.",
  ["Oğul atasının haqqını qorumağa hazırlaşır",
   "Oğul atasını tərk edir", "Ata oğlunu evdən qovur",
   "Ata və oğul ticarətə başlayır"], 1, None, 2),
 ("Bu bölmədə hansı növ nümunələr toplanmışdır?",
  "Bölmədə xalq yaradıcılığı nümunələri toplanmışdır.",
  ["Xalq yaradıcılığı nümunələri", "Saray şeirləri",
   "Elmi məqalələr", "Xarici tərcümələr"], 1, None, 2),
 ("Xalq qəhrəmanı obrazı adətən kimin tərəfini tutur?",
  "O, zəiflərin və məzlumların tərəfini tutur.",
  ["Zəiflərin və məzlumların", "Varlı bəylərin",
   "Xarici tacirlərin", "Saray əyanlarının"], 1, None, 2),
 ("Dastanlarda söz və musiqi necə birləşir?",
  "Aşıq dastanı sazın müşayiəti ilə söyləyir.",
  ["Aşıq sazın müşayiəti ilə söyləyir", "Mətn ancaq oxunur",
   "Musiqi ayrıca ifa olunur", "Mətn yazılı paylanır"],
  1, None, 2),
 # ---- cetin (12)
 ("Altıncı sinif materialı üzrə «obraz - rol» cütlüyü hansı düzgündür?",
  "Alı kişi Koroğlunun atasıdır.",
  ["Alı kişi - Koroğlunun atası", "Alı kişi - Koroğlunun oğlu",
   "Həsən xan - Koroğlunun atası",
   "Nigar xanım - Koroğlunun atası"], 1, None, 3),
 ("Şifahi ədəbiyyat bölməsi barədə hansı fikir SƏHVDİR?",
  "«Alı kişi» «Koroğlu» dastanının hissəsidir.",
  ["«Alı kişi» «Dədə Qorqud» dastanındandır",
   "«Alı kişi» «Koroğlu» dastanındandır",
   "Alı kişi Koroğlunun atasıdır",
   "Dastan şifahi yolla yayılır"], 1, None, 3),
 ("Xalq qəhrəmanı ilə saray qəhrəmanının fərqi nədir?",
  "Xalq qəhrəmanı xalqın, saray qəhrəmanı hakimiyyətin tərəfindədir.",
  ["Biri xalqın, digəri hakimiyyətin tərəfindədir",
   "Biri hakimiyyətin, digəri xalqın tərəfindədir",
   "Hər ikisi xalqın tərəfindədir",
   "Hər ikisi hakimiyyətin tərəfindədir"], 1, None, 3),
 ("Alı kişinin başına gələn faciənin dastandakı rolu nədir?",
  "Bu faciə Koroğlunun üsyanına başlanğıc verir.",
  ["Koroğlunun üsyanına səbəb olması",
   "Ticarətin başlanmasına səbəb olması",
   "Yeni şəhərin salınmasına səbəb olması",
   "Toyun təxirə düşməsinə səbəb olması"], 1, None, 3),
 ("Şifahi ədəbiyyat üzrə «əsər - növ» cütlüyü hansı doğrudur?",
  "«Koroğlu» xalq dastanıdır.",
  ["«Koroğlu» - xalq dastanı", "«Koroğlu» - yazılı roman",
   "«Kozetta» - xalq dastanı", "«Qaz və Durna» - xalq dastanı"],
  1, None, 3),
 ("«Koroğlu» dastanında hadisələr necə sıralanır? "
  "(1 - Koroğlunun üsyana qalxması, 2 - Alı kişinin kor edilməsi, "
  "3 - Çənlibelin qurulması)",
  "Əvvəlcə Alı kişi kor edilir, sonra Koroğlu üsyana qalxır, "
  "sonra Çənlibel qurulur.",
  ["2 - 1 - 3", "1 - 2 - 3", "3 - 2 - 1", "2 - 3 - 1"], 1, None, 3),
 ("Altıncı sinifdə xalq yaradıcılığı barədə hansı fikir SƏHVDİR?",
  "Xalq yaradıcılığı ilk növbədə şifahi yolla yayılır.",
  ["Bu nümunələr ancaq yazılı yayılır",
   "Xalq yaradıcılığının müəllifi bilinmir",
   "Aşıq dastanı sazla söyləyir",
   "Dastan epik növə aiddir"], 1, None, 3),
 ("Alı kişi və Koroğlu obrazları haqqında hansı fikir doğrudur?",
  "Alı kişi ata, Koroğlu isə onun oğludur.",
  ["Alı kişi ata, Koroğlu isə oğuldur",
   "Alı kişi oğul, Koroğlu isə atadır",
   "Hər ikisi qardaşdır",
   "Aralarında qohumluq yoxdur"], 1, None, 3),
 ("Aşağıdakı «sənətkar - alət» cütlüklərindən hansı düzgündür?",
  "Aşığın əsas aləti sazdır.",
  ["Aşıq - saz", "Aşıq - tar", "Aşıq - kaman", "Aşıq - piano"],
  1, None, 3),
 ("Xalq dastanlarının uzun əsrlər yaşamasının səbəbi nədir?",
  "Onlar xalqın arzu və ideallarını ifadə etdiyi üçün yaşayır.",
  ["Xalqın arzularını ifadə etməsi",
   "Kitab şəklində çap olunması",
   "Məktəbdə əzbərlədilməsi", "Xarici dilə tərcümə olunması"],
  1, None, 3),
 ("Dastanla nağılın quruluşca fərqi nədir?",
  "Dastanda nəzm parçaları olur, nağıl bütövlükdə nəsrdir.",
  ["Dastanda nəzm parçaları olur",
   "Nağılda nəzm parçaları olur",
   "Hər ikisində nəzm parçaları olur",
   "Heç birində nəzm parçası olmur"], 1, None, 3),
 ("Aşağıdakı «əsər - qəhrəman» cütlüklərindən hansı doğrudur?",
  "Koroğlu Alı kişinin oğludur.",
  ["«Koroğlu» - Alı kişinin oğlu",
   "«Kozetta» - Alı kişinin oğlu", "«Koroğlu» - Jan Valjan",
   "«Balaca qara balıq» - Alı kişi"], 1, None, 3)],

"edeb-6-usaq": [
 # ---- asan (4)
 ("«Kozetta» parçasının müəllifi kimdir?",
  "Parçanın müəllifi Viktor Hüqodur.",
  ["Viktor Hüqo", "Zahid Xəlil", "Naibə Yusif",
   "Səməd Behrəngi"], 1, None, 1),
 ("«Dostlar» əsərinin müəllifi kimdir?",
  "Əsərin müəllifi Zahid Xəlildir.",
  ["Zahid Xəlil", "Naibə Yusif", "Viktor Hüqo",
   "Mahirə Nağıqızı"], 1, None, 1),
 ("«Dərs» əsərinin müəllifi kimdir?",
  "Əsərin müəllifi Naibə Yusifdir.",
  ["Naibə Yusif", "Zahid Xəlil", "Viktor Hüqo",
   "Ramiz Qusarçaylı"], 1, None, 1),
 ("Altıncı sinif uşaq bölməsi nədən bəhs edir?",
  "Uşaq düşüncəsi və uşaq dünyası mövzusudur.",
  ["Uşaq düşüncəsi və uşaq dünyası", "Hərbi taktika",
   "Ticarət qaydaları", "Kosmos tədqiqatı"], 1, None, 1),
 # ---- orta (15)
 ("Kozetta obrazı hansı romanın qəhrəmanıdır?",
  "Kozetta «Səfillər» romanının qəhrəmanıdır.",
  ["«Səfillər»", "«Qorxulu nağıllar»", "«Gün var əsrə bərabər»",
   "«Ağ dəvə»"], 1, None, 2),
 ("Kozetta hansı vəziyyətdə olan qızdır?",
  "O, yetim və əziyyət çəkən qızdır.",
  ["Yetim və əziyyət çəkən", "Varlı ailənin qızı",
   "Saray xanımı", "Xaricdən gələn qonaq"], 1, None, 2),
 ("Kozettanı kim himayəsinə götürür?",
  "Onu Jan Valjan himayəsinə götürür.",
  ["Jan Valjan", "Qavroş", "Tenardye", "Marius"], 1, None, 2),
 ("Kozettaya əziyyət verən ailənin adı nədir?",
  "Ona Tenardyelər ailəsi əziyyət verir.",
  ["Tenardyelər", "Valjanlar", "Mariuslar", "Hüqolar"], 1, None, 2),
 ("Viktor Hüqo hansı əsrin yazıçısıdır?",
  "O, XIX əsrin yazıçısıdır.",
  ["XIX əsrin", "XII əsrin", "XVI əsrin", "XX əsrin sonunun"],
  1, None, 2),
 ("«Dostlar» əsəri hansı oxucu üçün yazılmışdır?",
  "Əsər uşaq oxucular üçün yazılmışdır.",
  ["Uşaqlar üçün", "Ancaq böyüklər üçün", "Alimlər üçün",
   "Hərbçilər üçün"], 1, None, 2),
 ("Uşaq obrazı ədəbiyyatda niyə vacibdir?",
  "Uşaq gözü dünyanı təmiz və saf göstərir.",
  ["Dünyanı təmiz gözlə göstərir", "Ticarəti öyrədir",
   "Hərbi taktika verir", "Coğrafiya öyrədir"], 1, None, 2),
 ("«Dərs» əsərinin adı nə ilə bağlıdır?",
  "Ad qəhrəmanın aldığı həyat dərsi ilə bağlıdır.",
  ["Həyat dərsi ilə", "Ticarət hesabı ilə", "Hərbi təlimlə",
   "Coğrafi xəritə ilə"], 1, None, 2),
 ("Dostluq mövzusu uşaq ədəbiyyatında nəyi öyrədir?",
  "Bir-birinə dayaq olmağı, sədaqəti öyrədir.",
  ["Bir-birinə dayaq olmağı", "Rəqabət aparmağı",
   "Xəsis olmağı", "Laqeyd qalmağı"], 1, None, 2),
 ("Kozettanın taleyi necə dəyişir?",
  "O, himayəyə götürülərək ağır həyatdan xilas olur.",
  ["Himayəyə götürülüb xilas olur", "Daha da ağırlaşır",
   "Heç dəyişmir", "Uzaq ölkəyə qaçır"], 1, None, 2),
 ("Uşaq ədəbiyyatının dili necə olmalıdır?",
  "Sadə və uşağa anlaşıqlı olmalıdır.",
  ["Sadə və anlaşıqlı", "Ağır elmi dildə",
   "Rəsmi sənəd dilində", "Arxaik sözlərlə"], 1, None, 2),
 ("Viktor Hüqo dünya ədəbiyyatında hansı ölkəni təmsil edir?",
  "O, Fransanı təmsil edir.",
  ["Fransanı", "İngiltərəni", "İtaliyanı", "İspaniyanı"],
  1, None, 2),
 ("Bu bölmədəki əsərlərdə hansı hisslər önə çıxır?",
  "Mərhəmət və dostluq hissləri önə çıxır.",
  ["Mərhəmət və dostluq", "Nifrət və qisas", "Tam laqeydlik",
   "Xəsislik"], 1, None, 2),
 ("«Səfillər» romanının mövzusu nə ilə bağlıdır?",
  "Roman yoxsulların, cəmiyyətin aşağı təbəqəsinin taleyi ilə bağlıdır.",
  ["Yoxsulların taleyi ilə", "Saray həyatı ilə",
   "Dəniz səfəri ilə", "Kosmos tədqiqatı ilə"], 1, None, 2),
 ("Uşaq obrazının çətinliklərə tab gətirməsi nəyi göstərir?",
  "İnsan iradəsinin gücünü göstərir.",
  ["İnsan iradəsinin gücünü", "Var-dövlətin əhəmiyyətini",
   "Təsadüfün həlledici rolunu", "Coğrafi şəraitin təsirini"],
  1, None, 2),
 # ---- cetin (12)
 ("Uşaq bölməsi üzrə «obraz - əsər» cütlüyü hansı düzgündür?",
  "Kozetta «Səfillər» romanının obrazıdır.",
  ["Kozetta - «Səfillər»", "Kozetta - «Dostlar»",
   "Jan Valjan - «Dostlar»", "Nurəddin - «Səfillər»"],
  1, None, 3),
 ("Kozetta obrazı barədə aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "Kozetta yetim və yoxsul qızdır.",
  ["Kozetta varlı ailənin qızıdır", "Kozetta yetim qızdır",
   "«Kozetta» Viktor Hüqonun əsərindəndir",
   "Jan Valjan Kozettanı himayə edir"], 1, None, 3),
 ("Kozetta və Qavroş obrazlarının ortaq cəhəti nədir?",
  "Hər ikisi «Səfillər» romanının uşaq obrazıdır.",
  ["Hər ikisi «Səfillər» romanının uşaq obrazıdır",
   "Hər ikisi varlı ailə uşağıdır",
   "Biri uşaq, digəri böyük obrazıdır",
   "Hər ikisi Azərbaycan ədəbiyyatındandır"], 1, None, 3),
 ("Kozettanın əziyyət çəkməsinin səbəbi nədir?",
  "O, yetim qalıb yad ailənin yanında yaşamağa məcbur olur.",
  ["Yetim qalıb yad ailədə yaşaması",
   "Uzaq ölkəyə səfər etməsi", "Məktəbi tərk etməsi",
   "Ticarətdə uduzması"], 1, None, 3),
 ("Uşaq bölməsi üzrə «obraz - rol» cütlüyü hansı doğrudur?",
  "Jan Valjan Kozettanın himayədarıdır.",
  ["Jan Valjan - Kozettanın himayədarı",
   "Tenardye - Kozettanın himayədarı",
   "Jan Valjan - Kozettaya əziyyət verən",
   "Qavroş - Kozettanın himayədarı"], 1, None, 3),
 ("«Səfillər» romanında hadisələr necə sıralanır? "
  "(1 - Kozettanın xilas olunması, 2 - Kozettanın yetim qalması, "
  "3 - yad ailənin yanında əziyyət çəkməsi)",
  "Əvvəlcə qız yetim qalır, sonra yad ailədə əziyyət çəkir, "
  "sonra xilas olunur.",
  ["2 - 3 - 1", "1 - 2 - 3", "3 - 2 - 1", "2 - 1 - 3"], 1, None, 3),
 ("Uşaq ədəbiyyatı barədə aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "Uşaq ədəbiyyatının dili sadə olmalıdır.",
  ["Uşaq ədəbiyyatının dili ağır elmi olmalıdır",
   "Uşaq ədəbiyyatının dili sadə olmalıdır",
   "Dostluq mövzusu bu ədəbiyyatda vacibdir",
   "Uşaq obrazı dünyanı təmiz gözlə göstərir"], 1, None, 3),
 ("Viktor Hüqo və Zahid Xəlil haqqında hansı fikir doğrudur?",
  "Hüqo fransız, Zahid Xəlil isə Azərbaycan yazıçısıdır.",
  ["Hüqo fransız, Zahid Xəlil Azərbaycan yazıçısıdır",
   "Hüqo Azərbaycan, Zahid Xəlil fransız yazıçısıdır",
   "Hər ikisi fransız yazıçısıdır",
   "Hər ikisi Azərbaycan yazıçısıdır"], 1, None, 3),
 ("Uşaq bölməsi üzrə «əsər - müəllif» cütlüyü hansı doğrudur?",
  "«Dostlar» Zahid Xəlilin, «Dərs» isə Naibə Yusifindir.",
  ["«Dostlar» - Zahid Xəlil", "«Dostlar» - Naibə Yusif",
   "«Dərs» - Zahid Xəlil", "«Kozetta» - Zahid Xəlil"],
  1, None, 3),
 ("«Səfillər» romanının adının mənası nə ilə bağlıdır?",
  "Ad cəmiyyətin ən yoxsul təbəqəsi ilə bağlıdır.",
  ["Cəmiyyətin ən yoxsul təbəqəsi ilə",
   "Saray əyanlarının həyatı ilə", "Dəniz səyyahları ilə",
   "Elm adamlarının işi ilə"], 1, None, 3),
 ("Uşaq obrazı ilə böyük obrazın bədii funksiyası necə fərqlənir?",
  "Uşaq gözü hadisələri daha təmiz və birbaşa göstərir.",
  ["Uşaq gözü hadisələri daha təmiz göstərir",
   "Böyük gözü hadisələri daha təmiz göstərir",
   "Hər ikisi eyni funksiya daşıyır",
   "Uşaq obrazı heç bir funksiya daşımır"], 1, None, 3),
 ("Uşaq bölməsi üzrə «əsər - ədəbiyyat» cütlüyü hansı düzgündür?",
  "«Kozetta» fransız ədəbiyyatına aiddir.",
  ["«Kozetta» - fransız ədəbiyyatı",
   "«Dostlar» - fransız ədəbiyyatı",
   "«Kozetta» - Azərbaycan ədəbiyyatı",
   "«Dərs» - fransız ədəbiyyatı"], 1, None, 3)],
}
SUALLAR.update(HISSE_1)

HISSE_2 = {
"edeb-6-yurd": [
 # ---- asan (4)
 ("«Azərbaycan bayrağı» şeirinin müəllifi kimdir?",
  "Şeirin müəllifi Süleyman Abdulladır.",
  ["Süleyman Abdulla", "Məmməd İsmayıl", "Nəbi Xəzri",
   "Eyvaz Zeynallı"], 1, None, 1),
 ("«Vətən seçilməz» şeirinin müəllifi kimdir?",
  "Şeirin müəllifi Məmməd İsmayıldır.",
  ["Məmməd İsmayıl", "Nəbi Xəzri", "Süleyman Abdulla",
   "Mikayıl Rzaquluzadə"], 1, None, 1),
 ("Altıncı sinifdə keçilən «İstiqlal marşı» şeirinin müəllifi kimdir?",
  "Şeirin müəllifi Nəbi Xəzridir.",
  ["Nəbi Xəzri", "Məmməd İsmayıl", "Süleyman Abdulla",
   "Eyvaz Zeynallı"], 1, None, 1),
 ("Yurd bölməsinin əsas mövzusu nədir?",
  "Yurd sevgisi və qəhrəmanlıq mövzusudur.",
  ["Yurd sevgisi və qəhrəmanlıq", "Ticarət və sənaye",
   "Kosmos və texnika", "Dəniz macərası"], 1, None, 1),
 # ---- orta (15)
 ("«And» əsərinin müəllifi kimdir?",
  "Əsərin müəllifi Mikayıl Rzaquluzadədir.",
  ["Mikayıl Rzaquluzadə", "Eyvaz Zeynallı", "Nəbi Xəzri",
   "Süleyman Abdulla"], 1, None, 2),
 ("«Tənha nar ağacı» əsərinin müəllifi kimdir?",
  "Əsərin müəllifi Eyvaz Zeynallıdır.",
  ["Eyvaz Zeynallı", "Mikayıl Rzaquluzadə", "Məmməd İsmayıl",
   "Nəbi Xəzri"], 1, None, 2),
 ("Azərbaycan bayrağı neçə rənglidir?",
  "Bayraq üçrənglidir.",
  ["Üç", "İki", "Dörd", "Beş"], 1, None, 2),
 ("Azərbaycan bayrağının ortasındakı nişanlar hansılardır?",
  "Aypara və səkkizguşəli ulduzdur.",
  ["Aypara və səkkizguşəli ulduz", "Qılınc və qalxan",
   "Buğda sünbülü", "Dəniz dalğası"], 1, None, 2),
 ("Vətən mövzusunda yazılan şeirlərin əsas hissi nədir?",
  "Vətənə sevgi və qürur hissidir.",
  ["Vətənə sevgi və qürur", "Qorxu və nigarançılıq",
   "Tam laqeydlik", "Kədər və ümidsizlik"], 1, None, 2),
 ("Nəbi Xəzri hansı ədəbi növün nümayəndəsidir?",
  "Nəbi Xəzri poeziyanın nümayəndəsidir.",
  ["Poeziyanın", "Dramaturgiyanın", "Elmi nəsrin",
   "Publisistikanın"], 1, None, 2),
 ("«Vətən seçilməz» ifadəsi nə deməkdir?",
  "Vətən doğulduğun yerdir, onu seçmək olmaz.",
  ["Vətən doğulduğun yerdir, seçilmir",
   "Vətəni istənilən vaxt dəyişmək olar",
   "Vətən ancaq coğrafi ərazidir",
   "Vətən ticarət meydanıdır"], 1, None, 2),
 ("Marş nədir?",
  "Çağırış xarakterli, ruh yüksəkliyi verən əsərdir.",
  ["Çağırış xarakterli, ruhlandıran əsər", "Kədərli xalq mahnısı",
   "Uzun tarixi roman", "Elmi məqalə"], 1, None, 2),
 ("Bayraq bir dövlət üçün nəyi bildirir?",
  "Müstəqilliyi və dövlətçiliyi bildirir.",
  ["Müstəqilliyi və dövlətçiliyi", "Ticarətin həcmini",
   "Əhalinin sayını", "Ölkənin sahəsini"], 1, None, 2),
 ("Məmməd İsmayıl hansı ədəbi növdə çalışır?",
  "O, poeziyada çalışır.",
  ["Poeziyada", "Dramaturgiyada", "Elmi nəsrdə",
   "Publisistikada"], 1, None, 2),
 ("Bu bölmədəki şeirlərin əsas çağırışı nədir?",
  "Vətəni sevmək və qorumaq çağırışıdır.",
  ["Vətəni sevmək və qorumaq", "Ticarəti artırmaq",
   "Yeni şəhər salmaq", "Xaricə köçmək"], 1, None, 2),
 ("Vətənpərvərlik şeirlərində hansı obraz tez-tez işlənir?",
  "Bayraq və torpaq obrazı tez-tez işlənir.",
  ["Bayraq və torpaq obrazı", "Dəniz gəmisi obrazı",
   "Kosmos gəmisi obrazı", "Ticarət karvanı obrazı"], 1, None, 2),
 ("Dövlətin milli rəmzlərinə hansılar daxildir?",
  "Bayraq, gerb və himn daxildir.",
  ["Bayraq, gerb, himn", "Şeir, roman, dram",
   "Saz, tar, kaman", "Dağ, çay, göl"], 1, None, 2),
 ("Vətən şeirlərində lirik qəhrəmanın münasibəti necə olur?",
  "O, vətəni doğma və müqəddəs sayır.",
  ["Doğma və müqəddəs sayır", "Yad bir yer sayır",
   "Laqeyd yanaşır", "Ticarət obyekti sayır"], 1, None, 2),
 ("Bu bölmədəki əsərlər əsasən hansı ədəbi növdədir?",
  "Bölmədə əsasən şeir nümunələri var.",
  ["Əsasən şeir", "Ancaq roman", "Ancaq dram",
   "Ancaq elmi məqalə"], 1, None, 2),
 # ---- cetin (12)
 ("Yurd bölməsi üzrə «əsər - müəllif» cütlüyü hansı düzgündür?",
  "«Vətən seçilməz» Məmməd İsmayılın şeiridir.",
  ["«Vətən seçilməz» - Məmməd İsmayıl",
   "«Vətən seçilməz» - Nəbi Xəzri",
   "«Azərbaycan bayrağı» - Məmməd İsmayıl",
   "«And» - Məmməd İsmayıl"], 1, None, 3),
 ("Yurd bölməsi barədə aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "«Azərbaycan bayrağı» Süleyman Abdullanın şeiridir.",
  ["«Azərbaycan bayrağı» Nəbi Xəzrinindir",
   "«Vətən seçilməz» Məmməd İsmayılındır",
   "«And» Mikayıl Rzaquluzadənindir",
   "«Tənha nar ağacı» Eyvaz Zeynallınındır"], 1, None, 3),
 ("Bayraq və himn kimi rəmzlərin ədəbiyyatda yer alması nəyi göstərir?",
  "Milli kimliyin ədəbiyyatda ifadə olunmasını göstərir.",
  ["Milli kimliyin bədii ifadəsini",
   "Ticarətin genişləndiyini", "Coğrafiyanın öyrənildiyini",
   "Elmin sürətlə inkişaf etdiyini"], 1, None, 3),
 ("Marş janrının çağırış ruhu daşımasının səbəbi nədir?",
  "Marş kütləni birləşdirib ruhlandırmaq üçün yaranır.",
  ["Kütləni birləşdirmək məqsədi",
   "Çox qısa həcmli olması", "Nəsrlə yazılmış olması",
   "Tərcüməsinin asan olması"], 1, None, 3),
 ("Aşağıdakı «rəmz - məna» cütlüklərindən hansı doğrudur?",
  "Bayraq dövlət müstəqilliyinin rəmzidir.",
  ["Bayraq - dövlət müstəqilliyi", "Bayraq - ticarət nişanı",
   "Himn - coğrafi xəritə", "Gerb - şeir forması"], 1, None, 3),
 ("Aşağıdakı üç hadisə zaman ardıcıllığı ilə necə düzülür? "
  "(1 - müstəqilliyin bərpası, 2 - Xalq Cümhuriyyətinin qurulması, "
  "3 - günümüz)",
  "Cümhuriyyət 1918-ci ildə qurulub, müstəqillik 1991-ci ildə bərpa "
  "olunub, sonra günümüzə gəlinib.",
  ["2 - 1 - 3", "1 - 2 - 3", "3 - 2 - 1", "2 - 3 - 1"], 1, None, 3),
 ("Milli rəmzlər barədə aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "Saz, tar və kaman musiqi alətidir, milli dövlət rəmzi deyil.",
  ["Milli rəmzlərə saz, tar və kaman daxildir",
   "Milli rəmzlərə bayraq daxildir",
   "Milli rəmzlərə himn daxildir",
   "Milli rəmzlərə gerb daxildir"], 1, None, 3),
 ("Nəbi Xəzri və Məmməd İsmayıl haqqında hansı fikir doğrudur?",
  "Hər ikisi şair kimi tanınır.",
  ["Hər ikisi şair kimi tanınır",
   "Hər ikisi nasir kimi tanınır",
   "Biri şair, digəri bəstəkardır",
   "Hər ikisi dramaturq kimi tanınır"], 1, None, 3),
 ("Yurd bölməsi üzrə «əsər - mövzu» cütlüyü hansı düzgündür?",
  "«Azərbaycan bayrağı» milli rəmz mövzusundadır.",
  ["«Azərbaycan bayrağı» - milli rəmz", "«Dostlar» - milli rəmz",
   "«Azərbaycan bayrağı» - dostluq", "«Kozetta» - milli rəmz"],
  1, None, 3),
 ("Şairlərin bayraq obrazına müraciət etməsinin səbəbi nədir?",
  "Bayraq müstəqilliyi və dövlətçiliyi təcəssüm etdirir.",
  ["Bayrağın müstəqilliyi təcəssüm etdirməsi",
   "Bayraq rənglərinin çox olması",
   "Şeir yazmağın asan olması", "Dərslik tələbinin olması"],
  1, None, 3),
 ("Adi şeir ilə marşın fərqi nədir?",
  "Marş çağırış xarakterlidir və kütləvi ifa üçün nəzərdə tutulur.",
  ["Marş çağırış və kütləvi ifa üçündür",
   "Adi şeir çağırış və kütləvi ifa üçündür",
   "Hər ikisi eyni məqsəd daşıyır",
   "Marş nəsrlə yazılır"], 1, None, 3),
 ("Yurd bölməsi üzrə «şair - əsər» cütlüyü hansı doğrudur?",
  "«İstiqlal marşı» şeiri Nəbi Xəzrinindir.",
  ["Nəbi Xəzri - «İstiqlal marşı»",
   "Süleyman Abdulla - «İstiqlal marşı»",
   "Nəbi Xəzri - «Vətən seçilməz»",
   "Eyvaz Zeynallı - «İstiqlal marşı»"], 1, None, 3)],

"edeb-6-menevi": [
 # ---- asan (4)
 ("«Qurd və İlbiz» təmsilinin müəllifi kimdir?",
  "Təmsilin müəllifi Abbasqulu ağa Bakıxanovdur.",
  ["Abbasqulu ağa Bakıxanov", "Seyid Əzim Şirvani",
   "Xəlil Rza Ulutürk", "Mahirə Nağıqızı"], 1, None, 1),
 ("«Qaz və Durna» təmsilinin müəllifi kimdir?",
  "Təmsilin müəllifi Seyid Əzim Şirvanidir.",
  ["Seyid Əzim Şirvani", "Abbasqulu ağa Bakıxanov",
   "Səməd Behrəngi", "Mahirə Nağıqızı"], 1, None, 1),
 ("Altıncı sinifdə keçilən «Balaca qara balıq» əsərinin müəllifi kimdir?",
  "Əsərin müəllifi Səməd Behrəngidir.",
  ["Səməd Behrəngi", "Xəlil Rza Ulutürk", "Naibə Yusif",
   "Zahid Xəlil"], 1, None, 1),
 ("«Ana dilim» şeirinin müəllifi kimdir?",
  "Şeirin müəllifi Mahirə Nağıqızıdır.",
  ["Mahirə Nağıqızı", "Xəlil Rza Ulutürk", "Naibə Yusif",
   "Seyid Əzim Şirvani"], 1, None, 1),
 # ---- orta (15)
 ("«Laylam mənim, nərəm mənim» şeirinin müəllifi kimdir?",
  "Şeirin müəllifi Xəlil Rza Ulutürkdür.",
  ["Xəlil Rza Ulutürk", "Mahirə Nağıqızı", "Səməd Behrəngi",
   "Abbasqulu ağa Bakıxanov"], 1, None, 2),
 ("«Qurd və İlbiz» hansı janrdadır?",
  "Əsər təmsil janrındadır.",
  ["Təmsil", "Roman", "Faciə", "Qəsidə"], 1, None, 2),
 ("Təmsildə əsasən hansı obrazlar iştirak edir?",
  "Təmsildə əsasən heyvan obrazları iştirak edir.",
  ["Heyvan obrazları", "Saray əyanları", "Kosmos alimləri",
   "Dəniz kapitanları"], 1, None, 2),
 ("Səməd Behrəngi harada yaşayıb-yaratmışdır?",
  "O, Cənubi Azərbaycanda - İranda yaşayıb-yaratmışdır.",
  ["Cənubi Azərbaycanda", "Türkiyədə", "Rusiyada", "Fransada"],
  1, None, 2),
 ("«Balaca qara balıq» nağılında qəhrəman hara üz tutur?",
  "Balaca balıq çayı tərk edib dənizə üz tutur.",
  ["Dənizə", "Dağa", "Səhraya", "Meşəyə"], 1, None, 2),
 ("Balaca qara balığın əsas məqsədi nədir?",
  "Dünyanı görmək, çayın sonunu tapmaqdır.",
  ["Dünyanı görmək və axtarmaq", "Var-dövlət toplamaq",
   "Rahat yaşamaq", "Başqalarına hökm etmək"], 1, None, 2),
 ("«Ana dilim» şeirinin mövzusu nədir?",
  "Ana dilinə məhəbbət mövzusudur.",
  ["Ana dilinə məhəbbət", "Dəniz səfəri", "Ticarət uğuru",
   "Kosmos tədqiqatı"], 1, None, 2),
 ("Ana dili insan üçün niyə vacibdir?",
  "Ana dili milli kimliyin əsasıdır.",
  ["Milli kimliyin əsası olduğu üçün", "Ticarəti asanlaşdırdığı üçün",
   "Səfəri qısaltdığı üçün", "Hesab aparmağa kömək etdiyi üçün"],
  1, None, 2),
 ("Altıncı sinifdə mənəvi dəyərlər bölməsi nədən bəhs edir?",
  "Mənəvi dəyərlər və yaşayan hikmətlərdir.",
  ["Mənəvi dəyərlər və hikmətlər", "Sənaye tikintisi",
   "Dəniz ticarəti", "Hərbi taktika"], 1, None, 2),
 ("Təmsilin dili necə olur?",
  "Yığcam, obrazlı və anlaşıqlı olur.",
  ["Yığcam və obrazlı", "Uzun və mürəkkəb",
   "Elmi terminlərlə dolu", "Rəsmi sənəd dilində"], 1, None, 2),
 ("Xəlil Rza Ulutürk hansı ədəbi növün nümayəndəsidir?",
  "O, poeziyanın nümayəndəsidir.",
  ["Poeziyanın", "Dramaturgiyanın", "Elmi nəsrin",
   "Publisistikanın"], 1, None, 2),
 ("Səməd Behrənginin nağılları kimlər üçün yazılıb?",
  "Uşaqlar üçün yazılıb, lakin böyük ictimai məna daşıyır.",
  ["Uşaqlar üçün, böyük məna ilə", "Ancaq alimlər üçün",
   "Ancaq hərbçilər üçün", "Ancaq tacirlər üçün"], 1, None, 2),
 ("Təmsildə əxlaqi nəticə harada verilir?",
  "Əxlaqi nəticə əsərin sonunda verilir.",
  ["Əsərin sonunda", "Əsərin əvvəlində", "Əsərin ortasında",
   "Ümumiyyətlə verilmir"], 1, None, 2),
 ("Abbasqulu ağa Bakıxanov hansı dövrün nümayəndəsidir?",
  "O, XIX əsr maarifçiliyinin nümayəndəsidir.",
  ["XIX əsr maarifçiliyinin", "XII əsr intibahının",
   "XVI əsr klassikasının", "XX əsr romantizminin"], 1, None, 2),
 ("Balaca qara balığın yolunda hansı təhlükələr olur?",
  "Onu ovlamaq istəyən güclü canlılar təhlükə yaradır.",
  ["Onu ovlamaq istəyən canlılar", "Ticarət rəqibləri",
   "Məktəb imtahanları", "Uzaq qohumları"], 1, None, 2),
 # ---- cetin (12)
 ("Təmsil müəllifləri üzrə «əsər - müəllif» cütlüyü hansı düzgündür?",
  "«Qurd və İlbiz» Bakıxanovun, «Qaz və Durna» Şirvaninindir.",
  ["«Qurd və İlbiz» - Bakıxanov",
   "«Qurd və İlbiz» - Seyid Əzim Şirvani",
   "«Qaz və Durna» - Bakıxanov",
   "«Ana dilim» - Bakıxanov"], 1, None, 3),
 ("Təmsil və nağıllar barədə hansı fikir SƏHVDİR?",
  "«Balaca qara balıq» Səməd Behrənginin nağılıdır.",
  ["«Balaca qara balıq» Bakıxanovun əsəridir",
   "«Qurd və İlbiz» təmsildir",
   "«Ana dilim» Mahirə Nağıqızınındır",
   "«Qaz və Durna» Şirvaninindir"], 1, None, 3),
 ("Təmsil ilə lirik şeirin əsas fərqi nədir?",
  "Təmsildə süjet və əxlaqi nəticə, lirik şeirdə duyğu əsasdır.",
  ["Təmsildə süjet və nəticə, şeirdə duyğu əsasdır",
   "Təmsildə duyğu, şeirdə süjet əsasdır",
   "Hər ikisində süjet əsasdır",
   "Hər ikisi eyni quruluşdadır"], 1, None, 3),
 ("Balaca qara balığın çayı tərk etməsinin səbəbi nədir?",
  "O, dünyanı tanımaq, çayın sonunu görmək istəyir.",
  ["Dünyanı tanımaq istəyi", "Yem tapa bilməməsi",
   "Ailəsi ilə mübahisəsi", "Suyun soyuması"], 1, None, 3),
 ("Təmsillər üzrə «əsər - janr» cütlüyü hansı doğrudur?",
  "«Qaz və Durna» təmsil, «Ana dilim» isə şeirdir.",
  ["«Qaz və Durna» - təmsil", "«Ana dilim» - təmsil",
   "«Qaz və Durna» - şeir", "«Balaca qara balıq» - təmsil"],
  1, None, 3),
 ("Aşağıdakı üç müəllif dövr baxımından necə düzülür? "
  "(1 - Abbasqulu ağa Bakıxanov, 2 - Səməd Behrəngi, "
  "3 - Seyid Əzim Şirvani)",
  "Bakıxanov XIX əsrin birinci yarısında, Şirvani XIX əsrin ikinci "
  "yarısında, Behrəngi isə XX əsrdə yaşamışdır.",
  ["1 - 3 - 2", "1 - 2 - 3", "3 - 2 - 1", "2 - 1 - 3"], 1, None, 3),
 ("Təmsil janrı barədə aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "Təmsil yığcam əsərdir, uzun tarixi roman deyil.",
  ["Təmsil uzun tarixi romandır",
   "Təmsildə heyvan obrazları iştirak edir",
   "Təmsil əxlaqi nəticə ilə bitir",
   "Təmsilin dili yığcam və obrazlıdır"], 1, None, 3),
 ("Bakıxanov və Seyid Əzim Şirvani haqqında hansı fikir doğrudur?",
  "Hər ikisi təmsil yazmış maarifçi sənətkardır.",
  ["Hər ikisi təmsil yazmış maarifçidir",
   "Hər ikisi ancaq roman yazmışdır",
   "Biri şair, digəri bəstəkardır",
   "Hər ikisi dünya ədəbiyyatı nümayəndəsidir"], 1, None, 3),
 ("Mənəvi dəyərlər üzrə «əsər - mövzu» cütlüyü hansı düzgündür?",
  "«Ana dilim» ana dili mövzusundadır.",
  ["«Ana dilim» - ana dili", "«Qurd və İlbiz» - ana dili",
   "«Ana dilim» - dəniz səfəri",
   "«Balaca qara balıq» - ana dili"], 1, None, 3),
 ("«Balaca qara balıq» nağılının böyük məna daşımasının səbəbi nədir?",
  "Nağıl azadlıq və axtarış ideyasını rəmzi şəkildə verir.",
  ["Azadlıq və axtarış ideyasını verməsi",
   "Çox uzun həcmli olması",
   "Sənədli material üzərində qurulması",
   "Xarici dildə yazılmış olması"], 1, None, 3),
 ("Ana dili mövzusunun ədəbiyyatda güclü olmasının səbəbi nədir?",
  "Dil milli kimliyin və yaddaşın əsasıdır.",
  ["Dilin milli kimliyin əsası olması",
   "Dilin ticarəti asanlaşdırması",
   "Dilin səfəri qısaltması",
   "Dilin hesab aparmağa kömək etməsi"], 1, None, 3),
 ("Altıncı sinif üzrə «şair - əsər» cütlüyü hansı doğrudur?",
  "«Laylam mənim, nərəm mənim» Xəlil Rza Ulutürkündür.",
  ["Xəlil Rza Ulutürk - «Laylam mənim, nərəm mənim»",
   "Mahirə Nağıqızı - «Laylam mənim, nərəm mənim»",
   "Xəlil Rza Ulutürk - «Ana dilim»",
   "Səməd Behrəngi - «Ana dilim»"], 1, None, 3)],

"edeb-6-tebiet": [
 # ---- asan (4)
 ("«Qəsd edilmiş gözəllik» əsərinin müəllifi kimdir?",
  "Əsərin müəllifi Elçin Hüseynbəylidir.",
  ["Elçin Hüseynbəyli", "Ramiz Qusarçaylı", "Rahil Məmməd",
   "Bayram Həsənov"], 1, None, 1),
 ("«Payız» şeirinin müəllifi kimdir?",
  "Şeirin müəllifi Ramiz Qusarçaylıdır.",
  ["Ramiz Qusarçaylı", "Rahil Məmməd", "Bayram Həsənov",
   "Elçin Hüseynbəyli"], 1, None, 1),
 ("«Bulaq başında» əsərinin müəllifi kimdir?",
  "Əsərin müəllifi Bayram Həsənovdur.",
  ["Bayram Həsənov", "Ramiz Qusarçaylı", "Rahil Məmməd",
   "Elçin Hüseynbəyli"], 1, None, 1),
 ("Altıncı sinifdə təbiət bölməsinin əsas mövzusu nədir?",
  "Təbiətin gözəlliyi və təbiətə qayğı mövzusudur.",
  ["Təbiətin gözəlliyi və qayğı", "Hərbi taktika",
   "Ticarət qaydaları", "Kosmos tədqiqatı"], 1, None, 1),
 # ---- orta (15)
 ("«İlin qızıl fəsli» əsərinin müəllifi kimdir?",
  "Əsərin müəllifi Rahil Məmməddir.",
  ["Rahil Məmməd", "Bayram Həsənov", "Ramiz Qusarçaylı",
   "Elçin Hüseynbəyli"], 1, None, 2),
 ("«İlin qızıl fəsli» ifadəsi hansı fəsli bildirir?",
  "Bu ifadə payız fəslini bildirir.",
  ["Payızı", "Qışı", "Yazı", "Yayı"], 1, None, 2),
 ("«Qəsd edilmiş gözəllik» adı nəyə işarə edir?",
  "Təbiət gözəlliyinə vurulan zərbəyə işarə edir.",
  ["Təbiətə vurulan zərbəyə", "Ticarət uğursuzluğuna",
   "Hərbi əməliyyata", "Məktəb imtahanına"], 1, None, 2),
 ("Təbiət haqqında yazılan əsərlər oxucunu nəyə çağırır?",
  "Təbiəti qorumaq və ona qayğı göstərmək çağırışıdır.",
  ["Təbiəti qorumaq və qayğı göstərmək", "Ov etməyi öyrənmək",
   "Ticarəti artırmaq", "Yeni şəhər salmaq"], 1, None, 2),
 ("Payız fəslinin təsvirində hansı rənglər önə çıxır?",
  "Sarı və qızılı rənglər önə çıxır.",
  ["Sarı və qızılı", "Ağ və mavi", "Qara və boz",
   "Yaşıl və çəhrayı"], 1, None, 2),
 ("Şeirdə təbiət təsvirinə nə deyilir?",
  "Bədii əsərdə təbiət təsvirinə peyzaj deyilir.",
  ["Peyzaj", "Portret", "Süjet", "Kompozisiya"], 1, None, 2),
 ("Elçin Hüseynbəyli hansı ədəbi növdə yazır?",
  "O, nəsrdə yazır.",
  ["Nəsrdə", "Ancaq mənzum dramda", "Ancaq qəsidədə",
   "Ancaq aşıq şeirində"], 1, None, 2),
 ("Ramiz Qusarçaylı hansı ədəbi növdə yazır?",
  "O, şeir - poeziya sahəsində yazır.",
  ["Şeirdə", "Dramaturgiyada", "Elmi nəsrdə", "Publisistikada"],
  1, None, 2),
 ("Təbiət mənzərəsini canlandıran bədii vasitələr hansılardır?",
  "Epitet və bənzətmə çox işlənir.",
  ["Epitet və bənzətmə", "Sənədli statistika", "Riyazi düstur",
   "Xəritə işarəsi"], 1, None, 2),
 ("Ekologiya mövzusu ədəbiyyatda nəyi qabardır?",
  "İnsanın təbiət qarşısındakı məsuliyyətini qabardır.",
  ["İnsanın təbiət qarşısında məsuliyyətini",
   "Ticarətin faydasını", "Hərbi gücü", "Şəhər memarlığını"],
  1, None, 2),
 ("Bulaq obrazı xalq təfəkküründə nəyi bildirir?",
  "Saflığı, təmizliyi və həyat mənbəyini bildirir.",
  ["Saflıq və həyat mənbəyi", "Var-dövlət", "Döyüş gücü",
   "Ticarət yolu"], 1, None, 2),
 ("Təbiət mövzulu şeirlərdə lirik qəhrəman necə görünür?",
  "Təbiətə vurğun, ona həssas münasibət bəsləyən insan kimi görünür.",
  ["Təbiətə vurğun və həssas insan kimi", "Laqeyd müşahidəçi kimi",
   "Təbiətdən qorxan insan kimi", "Ticarətçi kimi"], 1, None, 2),
 ("Fəsillərin ədəbiyyatda təsviri nəyə xidmət edir?",
  "İnsan əhvalını təbiət mənzərəsi ilə bağlamağa xidmət edir.",
  ["İnsan əhvalını təbiətlə bağlamağa", "Hesab öyrətməyə",
   "Xəritə çəkməyə", "Ticarət planı qurmağa"], 1, None, 2),
 ("Təbiət bölməsindəki əsərlər hansı ədəbi növlərdədir?",
  "Bölmədə həm şeir, həm də nəsr nümunələri var.",
  ["Həm şeir, həm nəsr", "Ancaq dram", "Ancaq elmi məqalə",
   "Ancaq tərcümə"], 1, None, 2),
 ("Təbiət təsvirində epitet hansı vəzifəni yerinə yetirir?",
  "Epitet təsvirə bədii təyin verib onu canlandırır.",
  ["Bədii təyin verib canlandırır", "Hadisələri sıralayır",
   "Vəzni müəyyən edir", "Bəndləri sayır"], 1, None, 2),
 # ---- cetin (12)
 ("Altıncı sinif təbiət bölməsi üzrə «əsər - müəllif» cütlüyü hansıdır?",
  "«Payız» Ramiz Qusarçaylının, «Bulaq başında» Bayram Həsənovundur.",
  ["«Payız» - Ramiz Qusarçaylı", "«Payız» - Bayram Həsənov",
   "«Bulaq başında» - Ramiz Qusarçaylı",
   "«İlin qızıl fəsli» - Ramiz Qusarçaylı"], 1, None, 3),
 ("Altıncı sinif təbiət bölməsi barədə hansı fikir SƏHVDİR?",
  "«Qəsd edilmiş gözəllik» Elçin Hüseynbəylinin əsəridir.",
  ["«Qəsd edilmiş gözəllik» Rahil Məmmədindir",
   "«Payız» Ramiz Qusarçaylınındır",
   "«Bulaq başında» Bayram Həsənovundur",
   "«İlin qızıl fəsli» Rahil Məmmədindir"], 1, None, 3),
 ("Şeirdə və nəsrdə təbiətin verilməsi necə fərqlənir?",
  "Şeirdə duyğu, nəsrdə isə hadisə fonu kimi verilir.",
  ["Şeirdə duyğu, nəsrdə hadisə fonu kimi",
   "Şeirdə hadisə fonu, nəsrdə duyğu kimi",
   "Hər ikisində eyni cür verilir",
   "Heç birində təbiət təsviri olmur"], 1, None, 3),
 ("«Qəsd edilmiş gözəllik» adının seçilməsinin səbəbi nədir?",
  "Ad təbiətə vurulan zərbəni kəskin şəkildə vurğulayır.",
  ["Təbiətə vurulan zərbəni vurğulamaq",
   "Ov qaydalarını öyrətmək", "Şəhər memarlığını təsvir etmək",
   "Ticarət yolunu göstərmək"], 1, None, 3),
 ("Təbiət bölməsi üzrə «anlayış - tərif» cütlüyü hansı doğrudur?",
  "Peyzaj bədii əsərdə təbiət təsviridir.",
  ["Peyzaj - təbiət təsviri", "Portret - təbiət təsviri",
   "Peyzaj - qəhrəmanın xarici görünüşü",
   "Süjet - təbiət təsviri"], 1, None, 3),
 ("Fəsillər il ərzində necə sıralanır? "
  "(1 - payız, 2 - yaz, 3 - yay)",
  "Yazdan sonra yay, yaydan sonra payız gəlir.",
  ["2 - 3 - 1", "1 - 2 - 3", "3 - 2 - 1", "2 - 1 - 3"], 1, None, 3),
 ("Təbiət mövzusu barədə aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "Təbiət mövzulu əsərlər təbiəti qorumağa çağırır.",
  ["Təbiət mövzulu əsərlər ova çağırır",
   "Təbiət mövzulu əsərlər qorumağa çağırır",
   "Peyzaj təbiət təsviridir",
   "Epitet bədii təyin yaradır"], 1, None, 3),
 ("Ramiz Qusarçaylı və Elçin Hüseynbəyli haqqında hansı fikir doğrudur?",
  "Biri poeziyada, digəri nəsrdə yazır.",
  ["Qusarçaylı poeziyada, Hüseynbəyli nəsrdə yazır",
   "Qusarçaylı nəsrdə, Hüseynbəyli poeziyada yazır",
   "Hər ikisi ancaq nəsrdə yazır",
   "Hər ikisi ancaq poeziyada yazır"], 1, None, 3),
 ("Təbiət bölməsi üzrə «əsər - fəsil» cütlüyü hansı düzgündür?",
  "«İlin qızıl fəsli» payız fəsli ilə bağlıdır.",
  ["«İlin qızıl fəsli» - payız", "«İlin qızıl fəsli» - qış",
   "«Payız» - yaz fəsli", "«Bulaq başında» - qış"], 1, None, 3),
 ("Ədəbiyyatda ekoloji mövzunun güclənməsinin səbəbi nədir?",
  "Təbiətə vurulan zərərin get-gedə artmasıdır.",
  ["Təbiətə vurulan zərərin artması",
   "Şəhərlərin sayının azalması",
   "Ov ənənəsinin tamam bitməsi",
   "Kitab sayının kəskin artması"], 1, None, 3),
 ("Təbiəti vəsf etmək ilə təbiəti qorumağa çağırmağın fərqi nədir?",
  "Biri gözəlliyi göstərir, digəri məsuliyyət tələb edir.",
  ["Biri gözəlliyi göstərir, digəri məsuliyyət tələb edir",
   "Biri məsuliyyət tələb edir, digəri gözəlliyi göstərir",
   "Hər ikisi eyni məqsəd daşıyır",
   "Hər ikisi ancaq gözəlliyi göstərir"], 1, None, 3),
 ("Təbiət bölməsi üzrə «obraz - məna» cütlüyü hansı doğrudur?",
  "Bulaq obrazı saflığın və həyat mənbəyinin nişanıdır.",
  ["Bulaq - saflıq və həyat mənbəyi", "Bulaq - döyüş gücü",
   "Payız - yenidən doğuluş", "Bulaq - ticarət yolu"],
  1, None, 3)],
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
--  63_bank_edebiyyat6.sql : EDEBIYYAT 6 BANKI
--
--  BU FAYL ELLE YAZILMIR - tools/edebiyyat6.py yaradir:
--      python3 tools/edebiyyat6.py
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
           ('edeb-6-sifahi', 'edeb-6-tebiet')
     having count(*) = 2) then
    raise exception 'ONCE 61_movzular_edebiyyat5_8.sql isledilmelidir.';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and q.ext_key like 'edeb6-%%';

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
   where owner_type = 'platform' and ext_key like 'edeb6-%%';
  if n <> %d then
    raise exception 'Edebiyyat 6 suallari: %d gozlenilirdi, %% tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'edeb6-%%'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '%% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'edeb6-%%';
  if k <> 5 then
    raise exception 'movzu sayi 5 deyil: %%', k;
  end if;
  --  Her movzuda en azi 12 cetin sual olmalidir ki, muellim BIR
  --  movzudan 10 sualliq cetin test yiga bilsin
  select count(*) into k from (
    select q.topic_id from public.questions q
     where q.ext_key like 'edeb6-%%' and q.difficulty = 3
     group by q.topic_id having count(*) < 12) z;
  if k > 0 then
    raise exception '%% movzuda 12-den az cetin sual var', k;
  end if;
  raise notice 'Edebiyyat 6 banki: %% sual, 5 movzu (her birinde 12 cetin).', n;
end $$;
""" % (n, ",\n".join(setirler), n, n))
    print("yazildi: %s" % CIXIS)


if __name__ == "__main__":
    ok, n = yoxla()
    if not ok:
        raise SystemExit(1)
    sql_yaz(n)
