#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Edebiyyat 11 banki -> db/56_bank_edebiyyat11.sql

    8 movzu x 31 sual = 248

Movzular 55_movzular_edebiyyat11.sql agacina uygundur (e-derslik
kitab id 821).  Dersliyin BEDII METNI goturulmur - muellif huququ
ile qorunur.  Suallar eserin adi, muellifi, movzusu, obrazlari,
janri ve edebiyyatsunasliq terminleri uzerinde qurulur; sitat
lazim gelende bir-iki misra ve menbe gosterilir.

CETINLIK BOLGUSU her movzuda:  4 asan + 15 orta + 12 cetin.

Cetin suallar bes qelible (CLAUDE.md "Cetinlik seviyyesi"):
xronoloji duzulus, yaxin tarixler, sebeb-netice, "hansi SEHVDIR",
"eser - muellif" / "obraz - eser" cutluk uygunlugu.

Isletmek:
    python3 tools/edebiyyat11.py
    python3 tools/cetinlik_analiz.py edeb11      # 0 vermelidir
"""
import io
import os

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CIXIS = os.path.join(KOK, "db", "56_bank_edebiyyat11.sql")

#  (movzu-slug, rub)
MOVZULAR = [
    ("edeb-11-tenqidi-realizm", 1),
    ("edeb-11-romantizm",       1),
    ("edeb-11-cabbarli-vurgun", 2),
    ("edeb-11-rza-mircelal",    2),
    ("edeb-11-ozunuderk",       3),
    ("edeb-11-istiqlal",        3),
    ("edeb-11-cenub-dunya",     4),
    ("edeb-11-nezeriyye",       4),
]

BOLGU = {1: 4, 2: 15, 3: 12}

SUALLAR = {}

HISSE_1 = {
"edeb-11-tenqidi-realizm": [
 # ---- asan (4)
 ("«Molla Nəsrəddin» jurnalının banisi kimdir?",
  "Jurnalı 1906-cı ildə Tiflisdə Cəlil Məmmədquluzadə nəşr etdirmişdir.",
  ["Cəlil Məmmədquluzadə", "Mirzə Ələkbər Sabir",
   "Hüseyn Cavid", "Əhməd Cavad"], 1, None, 1),
 ("Mirzə Ələkbər Sabirin şeirlər toplusu necə adlanır?",
  "Şairin satirik şeirləri «Hophopnamə» adı ilə toplanmışdır.",
  ["Hophopnamə", "Divan", "Xəmsə", "Hədiqətüs-süəda"], 1, None, 1),
 ("Cəlil Məmmədquluzadənin «Anamın kitabı» əsəri hansı janrdadır?",
  "«Anamın kitabı» dram (pyes) janrındadır.",
  ["Dram", "Roman", "Poema", "Hekayə"], 1, None, 1),
 ("Tənqidi realizm ədəbiyyatın hansı cəhətini önə çəkir?",
  "Cəmiyyətin nöqsanlarını açıb tənqid etməyi önə çəkir.",
  ["Cəmiyyətin nöqsanlarının tənqidini", "Xəyali aləmin təsvirini",
   "Keçmişin tərənnümünü", "Təbiətin vəsfini yalnız"], 1, None, 1),
 # ---- orta (15)
 ("«Molla Nəsrəddin» jurnalı ilk dəfə harada nəşr olunmuşdur?",
  "Jurnalın ilk nömrələri Tiflisdə çıxmışdır.",
  ["Tiflisdə", "Bakıda", "Gəncədə", "İrəvanda"], 1, None, 2),
 ("Cəlil Məmmədquluzadə hansı təxəllüslə tanınırdı?",
  "Yazıçı «Molla Nəsrəddin» təxəllüsü ilə də tanınırdı.",
  ["Molla Nəsrəddin", "Hophop", "Sabir", "Şəhriyar"], 1, None, 2),
 ("«Anamın kitabı» əsərində üç qardaş hansı üç mədəni yönü təmsil edir?",
  "Rus, İran və Osmanlı təhsili almış qardaşlar üç ayrı yönü təmsil edir.",
  ["Rus, İran və Osmanlı yönünü", "Yalnız Avropa yönünü",
   "Yalnız Şərq yönünü", "Heç bir yönü"], 1, None, 2),
 ("«Anamın kitabı»nda ana obrazı nəyi simvollaşdırır?",
  "Zəhrabəyim obrazı ana dilini və milli birliyi simvollaşdırır.",
  ["Ana dilini və milli birliyi", "Var-dövləti",
   "Xarici təhsili", "Şəhər həyatını"], 1, None, 2),
 ("«Anamın kitabı»nın əsas ideyası nədir?",
  "Millətin parçalanmaması, ana dili və milli birlik ideyasıdır.",
  ["Milli birlik və ana dili", "Var-dövlət yığmaq",
   "Xaricə köçmək", "Təhsildən imtina"], 1, None, 2),
 ("Cəlil Məmmədquluzadənin məşhur hekayələrindən biri hansıdır?",
  "«Poçt qutusu» yazıçının tanınmış hekayələrindəndir.",
  ["Poçt qutusu", "Qızılgül olmayaydı", "Şəhidlər", "Dəli Kür"], 1, None, 2),
 ("Cəlil Məmmədquluzadənin «Ölülər» əsəri hansı janrdadır?",
  "«Ölülər» faciəli komediya - tragikomediyadır.",
  ["Komediya", "Poema", "Roman", "Qəzəl"], 1, None, 2),
 ("Mirzə Ələkbər Sabir hansı şəhərdə doğulmuşdur?",
  "Sabir 1862-ci ildə Şamaxıda doğulmuşdur.",
  ["Şamaxıda", "Gəncədə", "Naxçıvanda", "Şuşada"], 1, None, 2),
 ("Sabirin şeirləri əsasən hansı nəşrdə çap olunurdu?",
  "Şeirlərinin çoxu «Molla Nəsrəddin» jurnalında çıxırdı.",
  ["Molla Nəsrəddin jurnalında", "Əkinçi qəzetində",
   "Kaspi qəzetində", "Füyuzat jurnalında"], 1, None, 2),
 ("Sabirin «Hophop» təxəllüsü nə ilə bağlıdır?",
  "Şair satirik şeirlərini bu təxəllüslə imzalayırdı.",
  ["Satirik şeirlərinin imzası idi", "Doğulduğu kəndin adıdır",
   "Atasının adıdır", "Jurnalın adıdır"], 1, None, 2),
 ("Sabir satirasının əsas hədəfi nə idi?",
  "Cəhalət, mövhumat və geriliyə qarşı yönəlmişdi.",
  ["Cəhalət və mövhumat", "Təbiət gözəllikləri",
   "Məhəbbət mövzusu", "Tarixi qəhrəmanlıq"], 1, None, 2),
 ("«Neylərdin, ilahi?!» şeirində şair kimə müraciət edir?",
  "Şeirdə şair Allaha müraciət formasında cəmiyyəti tənqid edir.",
  ["Allaha müraciət formasındadır", "Şaha müraciət edir",
   "Ordusuna müraciət edir", "Uşaqlara müraciət edir"], 1, None, 2),
 ("Tənqidi realizm cərəyanının Azərbaycanda mərkəzi hansı nəşr idi?",
  "«Molla Nəsrəddin» jurnalı cərəyanın mərkəzi idi.",
  ["Molla Nəsrəddin", "Füyuzat", "Əkinçi", "Ziya"], 1, None, 2),
 ("Satira nədir?",
  "Nöqsanları kəskin gülüş və istehza ilə tənqid edən bədii üsuldur.",
  ["Nöqsanları gülüşlə tənqid edən üsul", "Təbiəti vəsf edən janr",
   "Tarixi salnamə növü", "Nəsr şəkli"], 1, None, 2),
 ("Cəlil Məmmədquluzadə və Sabirin yaradıcılığındakı ortaq cəhət nədir?",
  "Hər ikisi cəmiyyətin gerilik və cəhalətini satira ilə tənqid edirdi.",
  ["Cəhaləti satira ilə tənqid etməsi", "Romantik xəyal aləmi",
   "Tarixi mövzulara üstünlük", "Təbiət lirikası"], 1, None, 2),
 # ---- cetin (12)
 ("Tənqidi realizm dövrünə aid «əsər - müəllif» cütlüyü hansı düzgündür?",
  "«Anamın kitabı» Məmmədquluzadənin, «Hophopnamə» Sabirin, «İblis» Cavidindir.",
  ["Anamın kitabı - C.Məmmədquluzadə", "Hophopnamə - Hüseyn Cavid",
   "İblis - Mirzə Ələkbər Sabir", "Ölülər - Əhməd Cavad"], 1, None, 3),
 ("Hadisələri ardıcıllıqla düzün: 1 - «Anamın kitabı»nın yazılması; 2 - «Əkinçi» qəzetinin nəşri; 3 - «Molla Nəsrəddin» jurnalının nəşrə başlaması.",
  "«Əkinçi» 1875, «Molla Nəsrəddin» 1906, «Anamın kitabı» 1920-ci ilə aiddir.",
  ["2 - 3 - 1", "3 - 2 - 1", "2 - 1 - 3", "1 - 2 - 3"], 1, None, 3),
 ("«Anamın kitabı» haqqında aşağıdakılardan hansı SƏHVDİR?",
  "Əsər dram janrındadır; roman deyil.",
  ["Əsər roman janrında yazılmışdır",
   "Əsərdə üç qardaş üç ayrı mədəni yönü təmsil edir",
   "Ana obrazı milli birliyi simvollaşdırır",
   "Müəllifi Cəlil Məmmədquluzadədir"], 1, None, 3),
 ("«Anamın kitabı»nda bacı obrazının əsərdəki rolu nədir?",
  "Gülbahar ananın vəsiyyətini qoruyan, milli dəyərlərə sadiq obrazdır.",
  ["Ananın vəsiyyətini qoruyur", "Qardaşları bir-birinə qarşı qoyur",
   "Xaricə köçməyi təklif edir", "Əsərdə iştirak etmir"], 1, None, 3),
 ("Aşağıdakı «şəxs - təxəllüs» cütlüklərindən hansı düzgündür?",
  "Sabirin təxəllüsü Hophop, Məmmədquluzadənin isə Molla Nəsrəddin idi.",
  ["M.Ə.Sabir - Hophop", "C.Məmmədquluzadə - Hophop",
   "Hüseyn Cavid - Molla Nəsrəddin", "Əhməd Cavad - Sabir"], 1, None, 3),
 ("Sabirin satirasında «başqasının dili ilə danışma» üsulu nəyə xidmət edir?",
  "Şair tənqid etdiyi adamın dilindən yazır - onun düşüncəsi öz-özünü ifşa edir.",
  ["Obrazın öz sözü ilə ifşa olunmasına", "Şairin fikrini gizlətməyə",
   "Şeirin qafiyəsini asanlaşdırmağa", "Mövzunu dəyişməyə"], 1, None, 3),
 ("Tənqidi realizmlə maarifçi realizmin əsas fərqi nədir?",
  "Maarifçilər maariflə düzəlişə ümid edirdi, tənqidi realistlər sistemin özünü ifşa edirdi.",
  ["Biri maarifə ümid edir, digəri sistemi ifşa edir",
   "Biri sistemi ifşa edir, digəri maarifə ümid edir",
   "Biri şeirdə, digəri dramda təzahür edir",
   "Maarifçi realizm yalnız dramda olur"], 1, None, 3),
 ("«Molla Nəsrəddin» jurnalının satirik gücünü artıran vasitə hansı idi?",
  "Mətnlə yanaşı karikaturalar oxucuya birbaşa təsir edirdi.",
  ["Karikaturalar", "Elmi məqalələr", "Şəkilsiz elanlar", "Xəritələr"], 1, None, 3),
 ("Cəlil Məmmədquluzadənin «Poçt qutusu» hekayəsində əsas ifşa hədəfi nədir?",
  "Savadsızlıq və cəhalət - Novruzəli məktubu poçt qutusunu tanımadığı üçün itirir.",
  ["Savadsızlıq və cəhalət", "Var-dövlət hərisliyi",
   "Şəhər həyatının çətinliyi", "Təbiətin dağıdılması"], 1, None, 3),
 ("Aşağıdakı «nəşr - il» cütlüklərindən hansı düzgündür?",
  "«Əkinçi» 1875, «Molla Nəsrəddin» 1906-cı ildə nəşrə başlamışdır.",
  ["Molla Nəsrəddin - 1906", "Əkinçi - 1906",
   "Molla Nəsrəddin - 1875", "Füyuzat - 1875"], 1, None, 3),
 ("Sabir yaradıcılığının Azərbaycan şeirinə gətirdiyi yenilik nədir?",
  "Satiranı ictimai mübarizə silahına çevirdi və canlı danışıq dilini şeirə gətirdi.",
  ["Satiranı ictimai silaha çevirdi", "Əruz vəznindən imtina etdi tam",
   "Yalnız məhəbbət lirikası yazdı", "Nəsrə keçdi"], 1, None, 3),
 ("Tənqidi realizm dövrü hansı illəri əhatə edir?",
  "Dövr XIX əsrin 90-cı illərindən 1920-ci ilə qədəri əhatə edir.",
  ["XIX əsrin sonundan 1920-ci ilədək",
   "XVIII əsrin ortalarından XIX əsrədək",
   "1920-ci ildən 1960-cı ilədək",
   "1960-cı ildən 1990-cı ilədək"], 1, None, 3)],
"edeb-11-romantizm": [
 # ---- asan (4)
 ("«İblis» faciəsinin müəllifi kimdir?",
  "«İblis» mənzum faciəsi Hüseyn Cavidin qələmindəndir.",
  ["Hüseyn Cavid", "Cəfər Cabbarlı", "Səməd Vurğun", "Mir Cəlal"], 1, None, 1),
 ("Hüseyn Cavid hansı şəhərdə doğulmuşdur?",
  "Şair 1882-ci ildə Naxçıvanda doğulmuşdur.",
  ["Naxçıvanda", "Şamaxıda", "Gəncədə", "Şuşada"], 1, None, 1),
 ("Romantizm cərəyanı nəyə üstünlük verir?",
  "Yüksək ideal, güclü hiss və xəyal aləminə üstünlük verir.",
  ["İdeal və xəyal aləminə", "Gündəlik məişət təsvirinə",
   "Statistik faktlara", "Elmi sübutlara"], 1, None, 1),
 ("Azərbaycan Xalq Cümhuriyyətinin himninin sözlərinin müəllifi kimdir?",
  "Himnin sözləri Əhməd Cavada məxsusdur.",
  ["Əhməd Cavad", "Hüseyn Cavid", "Mirzə Ələkbər Sabir", "Səməd Vurğun"], 1, None, 1),
 # ---- orta (15)
 ("«İblis» əsəri hansı janrdadır?",
  "Əsər mənzum faciədir - şeirlə yazılmış dramdır.",
  ["Mənzum faciə", "Roman", "Hekayə", "Qəzəl"], 1, None, 2),
 ("«İblis» faciəsinin baş qəhrəmanı kimdir?",
  "Əsərin mərkəzində Arif obrazı dayanır.",
  ["Arif", "Vaqif", "Oqtay", "Cahandar ağa"], 1, None, 2),
 ("«İblis» əsərində Rəna obrazı kimdir?",
  "Rəna Arifin sevdiyi qızdır.",
  ["Arifin sevdiyi qız", "Arifin anası",
   "Vasifin bacısı deyil, düşməni", "İblisin köməkçisi"], 1, None, 2),
 ("«İblis» əsərinin əsas ideyası nədir?",
  "Şər insanın öz içindədir - müharibə və xəyanət insanı iblisləşdirir.",
  ["Şərin mənbəyi insanın özüdür", "Müharibə qaçılmazdır",
   "Var-dövlət xoşbəxtlik gətirir", "Təbiət insandan güclüdür"], 1, None, 2),
 ("«İblis» əsəri hansı tarixi şəraitdə yazılmışdır?",
  "Birinci Dünya müharibəsi dövründə - 1918-ci ildə yazılmışdır.",
  ["Birinci Dünya müharibəsi dövründə", "İkinci Dünya müharibəsi dövründə",
   "XIX əsrin əvvəlində", "Müstəqillik dövründə"], 1, None, 2),
 ("Hüseyn Cavidin taleyi necə olmuşdur?",
  "1937-ci il repressiyasının qurbanı olmuş, 1941-ci ildə Sibirdə vəfat etmişdir.",
  ["Repressiya qurbanı olub Sibirdə vəfat etmişdir", "Xaricə mühacirət etmişdir",
   "Uzun ömür sürüb Bakıda vəfat etmişdir", "Müharibədə həlak olmuşdur"], 1, None, 2),
 ("Hüseyn Cavidin nəşi hansı ildə vətənə gətirilmişdir?",
  "Şairin nəşi 1982-ci ildə Naxçıvana gətirilmişdir.",
  ["1982", "1956", "1991", "1937"], 1, None, 2),
 ("Hüseyn Cavidin əsərlərindən biri hansıdır?",
  "«Şeyx Sənan» şairin məşhur mənzum faciələrindəndir.",
  ["Şeyx Sənan", "Anamın kitabı", "Dəli Kür", "Açıq kitab"], 1, None, 2),
 ("Cavid dramaturgiyasının səciyyəvi cəhəti nədir?",
  "Əsərləri mənzumdur və fəlsəfi-romantik məzmun daşıyır.",
  ["Mənzum və fəlsəfi-romantik olması", "Sənədli olması",
   "Yalnız məişət mövzusu", "Qısa hekayə forması"], 1, None, 2),
 ("Əhməd Cavadın «Azərbaycan bayrağına» şeirində nə tərənnüm olunur?",
  "Üçrəngli bayraq və müstəqillik ideyası tərənnüm olunur.",
  ["Üçrəngli bayraq və müstəqillik", "Təbiət gözəllikləri",
   "Şəhər həyatı", "Elmi kəşflər"], 1, None, 2),
 ("Əhməd Cavadın taleyi necə olmuşdur?",
  "Şair 1937-ci il repressiyasının qurbanı olmuşdur.",
  ["Repressiya qurbanı olmuşdur", "Mühacirətdə yaşamışdır",
   "Müharibədə həlak olmuşdur", "Uzun ömür sürmüşdür"], 1, None, 2),
 ("Romantizm cərəyanının Azərbaycanda əsas nümayəndələri kimlərdir?",
  "Hüseyn Cavid, Əhməd Cavad, Məhəmməd Hadi romantizmin nümayəndələridir.",
  ["Cavid, Ə.Cavad, M.Hadi", "Sabir, Məmmədquluzadə, Ə.Haqverdiyev",
   "Mir Cəlal, İ.Şıxlı, Anar", "Vaqif, Zakir, Nəbati"], 1, None, 2),
 ("Romantiklərin əsas dayaq nəşri hansı idi?",
  "«Füyuzat» jurnalı romantik ədəbiyyatın mərkəzi sayılırdı.",
  ["Füyuzat", "Molla Nəsrəddin", "Əkinçi", "Kaspi"], 1, None, 2),
 ("Cavidin «İblis» əsərinin sonunda hansı sual qoyulur?",
  "İblisin kim olduğu sualı verilir - cavab insanın özündə axtarılır.",
  ["İblis kimdir sualı", "Vətən nədir sualı",
   "Elm nədir sualı", "Sərvət nədir sualı"], 1, None, 2),
 ("Romantizmlə tənqidi realizmin fərqi nədədir?",
  "Romantizm ideal və xəyala, tənqidi realizm mövcud gerçəkliyin ifşasına söykənir.",
  ["Biri ideala, digəri gerçəkliyin ifşasına söykənir", "Fərq yoxdur",
   "İkisi də yalnız nəsrdir", "İkisi də tarixi mövzu yazır"], 1, None, 2),
 # ---- cetin (12)
 ("Romantizm dövrünə aid «əsər - müəllif» cütlüklərindən hansı düzgündür?",
  "«İblis» və «Şeyx Sənan» Cavidin, «Səsli qız» Əhməd Cavadındır.",
  ["Şeyx Sənan - Hüseyn Cavid", "İblis - Əhməd Cavad",
   "Səsli qız - Hüseyn Cavid", "Hophopnamə - Əhməd Cavad"], 1, None, 3),
 ("Hadisələri ardıcıllıqla düzün: 1 - Hüseyn Cavidin nəşinin vətənə gətirilməsi; 2 - «İblis» faciəsinin yazılması; 3 - Cavidin repressiyaya məruz qalması.",
  "«İblis» 1918, repressiya 1937, nəşin gətirilməsi 1982.",
  ["2 - 3 - 1", "3 - 2 - 1", "2 - 1 - 3", "1 - 2 - 3"], 1, None, 3),
 ("Hüseyn Cavid haqqında aşağıdakılardan hansı SƏHVDİR?",
  "Cavid mühacirətə getməmiş, repressiyaya məruz qalıb Sibirdə vəfat etmişdir.",
  ["Şair mühacirətdə - Türkiyədə vəfat etmişdir",
   "«İblis» faciəsi mənzum şəkildə yazılmışdır",
   "Şair Naxçıvanda doğulmuşdur",
   "Nəşi 1982-ci ildə vətənə gətirilmişdir"], 1, None, 3),
 ("«İblis» faciəsində müharibə mövzusunun qoyuluşu nə ilə səciyyəvidir?",
  "Müharibə konkret tərəflərin deyil, insandakı şərin nəticəsi kimi göstərilir.",
  ["Şərin insandan doğduğu göstərilir", "Bir tərəf haqlı sayılır",
   "Müharibə tərənnüm olunur", "Mövzu ümumiyyətlə yoxdur"], 1, None, 3),
 ("Romantizmin bədii dilində üstünlük təşkil edən vasitə hansıdır?",
  "Rəmz, obrazlı təşbeh və yüksək üslub üstünlük təşkil edir.",
  ["Rəmz və yüksək üslub", "Sənədli dəqiqlik",
   "Rəqəm və statistika", "Danışıq şivəsi"], 1, None, 3),
 ("Aşağıdakı «şair - şeir» cütlüklərindən hansı düzgündür?",
  "«Azərbaycan bayrağına» və «Səsli qız» Əhməd Cavadın şeirləridir.",
  ["Əhməd Cavad - Səsli qız", "Hüseyn Cavid - Səsli qız",
   "Sabir - Azərbaycan bayrağına", "Səməd Vurğun - Səsli qız"], 1, None, 3),
 ("«Füyuzat» və «Molla Nəsrəddin» nəşrləri arasındakı əsas fərq nədir?",
  "«Füyuzat» romantik-ideal, «Molla Nəsrəddin» satirik-realist mövqedə idi.",
  ["Biri romantik, digəri satirik idi", "İkisi də eyni mövqedə dayanırdı",
   "İkisi də elmi-texniki jurnal idi",
   "İkisi də uşaqlar üçün nəşr olunurdu"], 1, None, 3),
 ("Cavidin qəhrəmanlarının səciyyəvi cəhəti nədir?",
  "Onlar fərdi taleyi deyil, ümumbəşəri ideya uğrunda mübarizəni təmsil edir.",
  ["Ümumbəşəri ideyanı təmsil edirlər", "Yalnız məişət qayğısı çəkirlər",
   "Tarixi sənədə əsaslanırlar", "Komik obrazlardır"], 1, None, 3),
 ("Romantizm dövründə yaranan əsərlərdə Şərq mövzusuna müraciət nə ilə izah olunur?",
  "Şərq tarixi və əfsanələri ümumbəşəri ideyaları ifadə üçün zəngin material verirdi.",
  ["Ümumbəşəri ideya üçün material verirdi",
   "Sənədli mənbə axtarışı ilə bağlı idi",
   "Coğrafi maraqdan doğan meyl idi",
   "Dil öyrənmək məqsədi daşıyırdı"], 1, None, 3),
 ("1937-ci il repressiyası Azərbaycan ədəbiyyatına necə təsir etdi?",
  "Cavid, Müşfiq, Ə.Cavad kimi bir nəsil yazıçı məhv edildi, yaradıcılıq azadlığı boğuldu.",
  ["Bütöv bir yazıçı nəsli məhv edildi", "Ədəbiyyat sürətlə inkişaf etdi",
   "Nəsr janrları xüsusi yüksəliş yaşadı",
   "Ədəbi tənqid müstəqillik qazandı"], 1, None, 3),
 ("Aşağıdakı «şair - doğum yeri» cütlüklərindən hansı düzgündür?",
  "Cavid Naxçıvanda, Sabir Şamaxıda, Vurğun Qazaxda doğulmuşdur.",
  ["Hüseyn Cavid - Naxçıvan", "Mirzə Ələkbər Sabir - Naxçıvan",
   "Hüseyn Cavid - Şamaxı", "Səməd Vurğun - Şamaxı"], 1, None, 3),
 ("Romantizmin Azərbaycan ədəbiyyatındakı tarixi rolu nədir?",
  "Milli özünüdərki və istiqlal ideyasını bədii şəkildə formalaşdırdı.",
  ["Milli özünüdərki formalaşdırdı", "Yalnız əyləncə funksiyası daşıdı",
   "Elmi biliyi yaydı", "Xalq mahnılarını topladı"], 1, None, 3)],
}
SUALLAR.update(HISSE_1)

HISSE_2 = {
"edeb-11-cabbarli-vurgun": [
 # ---- asan (4)
 ("«Sevil» pyesinin müəllifi kimdir?",
  "Pyes Cəfər Cabbarlının qələmindən çıxmışdır.",
  ["Cəfər Cabbarlı", "Səməd Vurğun", "Mir Cəlal", "Rəsul Rza"], 1, None, 1),
 ("Səməd Vurğunun «Vaqif» əsəri hansı janrdadır?",
  "«Vaqif» mənzum dram janrındadır.",
  ["Mənzum dram", "Roman", "Hekayə", "Qəzəl"], 1, None, 1),
 ("Səməd Vurğun hansı bölgədə doğulmuşdur?",
  "Şair Qazax bölgəsində, Yuxarı Salahlı kəndində doğulmuşdur.",
  ["Qazaxda", "Şəkidə", "Göyçayda", "Naxçıvanda"], 1, None, 1),
 ("Cəfər Cabbarlı ədəbiyyatın əsasən hansı sahəsində tanınır?",
  "O, ilk növbədə dramaturq kimi tanınır.",
  ["Dramaturgiyada", "Uşaq şeirində", "Ədəbi tərcümədə",
   "Elmi-fantastik nəsrdə"], 1, None, 1),
 # ---- orta (15)
 ("«Sevil» pyesində əsas ideya hansıdır?",
  "Qadının azadlığı, təhsil alması və şəxsiyyət kimi formalaşmasıdır.",
  ["Qadın azadlığı və maarifi", "Var-dövlət hərisliyi",
   "Hərbi vətənpərvərlik", "Kənd təsərrüfatı islahatı"], 1, None, 2),
 ("«Almaz» pyesinin baş qəhrəmanı hansı peşə sahibidir?",
  "Almaz kənddə çalışan gənc müəllimədir.",
  ["Kənd müəllimi", "Həkim", "Mühəndis", "Tacir"], 1, None, 2),
 ("Cəfər Cabbarlının «Od gəlini» əsərinin mövzusu hansı dövrdən götürülüb?",
  "Əsər ərəb işğalı və ona qarşı azadlıq hərəkatı dövrünə həsr olunub.",
  ["Ərəb işğalı dövründən", "Səfəvilər dövründən",
   "Rusiya imperiyası dövründən", "İkinci Dünya müharibəsi dövründən"],
  1, None, 2),
 ("«Oqtay Eloğlu» pyesi hansı sahənin problemlərinə həsr olunmuşdur?",
  "Əsər milli teatrın yaranması yolundakı çətinliklərdən bəhs edir.",
  ["Milli teatrın", "Neft sənayesinin", "Kənd təsərrüfatının",
   "Tibb elminin"], 1, None, 2),
 ("«1905-ci ildə» pyesində Cəfər Cabbarlı hansı hadisəni qələmə almışdır?",
  "Çarizmin qızışdırdığı milli qırğını və onun əsl səbəblərini.",
  ["Çarizmin qızışdırdığı milli qırğını", "Uzunmüddətli aclıq illərini",
   "Güclü zəlzələ fəlakətini", "Dəniz gəmisinin qəzasını"], 1, None, 2),
 ("Səməd Vurğunun «Azərbaycan» şeirinin aparıcı motivi nədir?",
  "Şeir vətənə məhəbbət və vətən həsrəti motivi üzərində qurulub.",
  ["Vətənə məhəbbət", "Elmi kəşflərin təbliği",
   "Şəhər həyatının tənqidi", "Dini mövzuların şərhi"], 1, None, 2),
 ("«Vaqif» mənzum dramında Vaqifin qarşısında duran tarixi şəxsiyyət kimdir?",
  "Dramda əsas qarşıdurma Ağa Məhəmməd şah Qacar ilədir.",
  ["Ağa Məhəmməd şah Qacar", "Şah İsmayıl Xətai", "Nadir şah Əfşar",
   "Şah Abbas"], 1, None, 2),
 ("«Vaqif» dramında Eldar obrazı kimi təmsil edir?",
  "Eldar xalq içindən çıxmış, haqsızlığa üsyan edən gəncdir.",
  ["Xalq içindən çıxmış üsyankar gənci", "Saray şairini",
   "Xarici ölkənin elçisini", "Din xadimini"], 1, None, 2),
 ("Səməd Vurğunun «Fərhad və Şirin» əsəri hansı klassik süjet əsasında yazılıb?",
  "Əsər Nizaminin «Xosrov və Şirin» poemasının süjeti üzərində qurulub.",
  ["«Xosrov və Şirin» süjeti üzərində", "«Koroğlu» dastanı üzərində",
   "«Dədə Qorqud» boyları üzərində", "«Leyli və Məcnun» süjeti üzərində"],
  1, None, 2),
 ("Səməd Vurğun Azərbaycanda ilk dəfə hansı fəxri ada layiq görülmüşdür?",
  "O, respublikada ilk Xalq şairi adını almışdır.",
  ["Xalq şairi", "Xalq yazıçısı", "Xalq artisti", "Əməkdar müəllim"],
  1, None, 2),
 ("Cəfər Cabbarlı ədəbiyyatdan başqa hansı sahədə fəaliyyət göstərmişdir?",
  "O, kino üçün ssenarilər yazmış, milli kinonun inkişafına təsir etmişdir.",
  ["Kino ssenarisi yazmışdır", "Musiqi bəstələmişdir",
   "Memarlıqla məşğul olmuşdur", "Heykəltəraşlıqla məşğul olmuşdur"],
  1, None, 2),
 ("«Sevil» pyesində Balaş obrazı nəyi ifadə edir?",
  "Balaş milli kökündən uzaqlaşan, ailəsini utanc sayan ziyalı tipidir.",
  ["Milli kökündən uzaqlaşan ziyalını", "Fədakar kənd müəllimini",
   "Sadə zəhmətkeş kəndlini", "Vətənpərvər cəbhə əsgərini"], 1, None, 2),
 ("Aşağıdakılardan hansı Səməd Vurğunun poemasıdır?",
  "«Muğan» Səməd Vurğunun poemasıdır.",
  ["«Muğan»", "«Qızılgül olmayaydı»", "«Gülüstan»", "«Heydərbabaya salam»"],
  1, None, 2),
 ("«Almaz» pyesindəki əsas konflikt nədir?",
  "Yeni maarif ideyası ilə köhnə mühitin qarşıdurmasıdır.",
  ["Maarif ideyası ilə köhnə mühitin qarşıdurması",
   "İki ailə arasında miras davası", "Şəhərlə kəndin ticarət rəqabəti",
   "Ordudakı intizam məsələsi"], 1, None, 2),
 ("«Od gəlini» pyesinin baş qəhrəmanı kimdir?",
  "Əsərin mərkəzində üsyançı Elxan obrazı dayanır.",
  ["Elxan", "Aydın", "Oqtay", "Balaş"], 1, None, 2),
 # ---- cetin (12)
 ("«Solğun çiçəklər», «Sevil» və «Vaqif» əsərləri yazılma ardıcıllığı ilə "
  "necə düzülür? (1 - «Sevil», 2 - «Solğun çiçəklər», 3 - «Vaqif»)",
  "«Solğun çiçəklər» 1917-ci, «Sevil» 1928-ci, «Vaqif» 1937-ci ildə yazılıb.",
  ["2 - 1 - 3", "1 - 2 - 3", "3 - 1 - 2", "1 - 3 - 2"], 1, None, 3),
 ("Aşağıdakı «əsər - yazılma ili» cütlüklərindən hansı düzgündür?",
  "«Sevil» 1928-ci ildə, «Almaz» isə 1931-ci ildə yazılmışdır.",
  ["«Sevil» - 1928", "«Sevil» - 1931", "«Almaz» - 1928",
   "«Od gəlini» - 1931"], 1, None, 3),
 ("«Sevil» pyesində Balaşın ailəsindən uzaqlaşmasının əsas səbəbi nədir?",
  "Balaş yeni mühitə uyğunlaşdıqca arvadını və öz kökünü geridə qalmış saydı.",
  ["Yeni mühitə uyğunlaşıb ailəsini geri sayması",
   "Sevilin şəhərə köçüb onu tərk etməsi",
   "Atakişinin onu evdən qovması",
   "Gülüşün ailəni ayırmağa çalışması"], 1, None, 3),
 ("Cəfər Cabbarlının əsərləri haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "«Oqtay Eloğlu» teatr mühitindən bəhs edir, neft sənayesindən yox.",
  ["«Oqtay Eloğlu» neft sənayesinə həsr olunub",
   "«Od gəlini» tarixi mövzuda yazılıb",
   "«Sevil» qadın azadlığından bəhs edir",
   "«Almaz» kənd həyatını əks etdirir"], 1, None, 3),
 ("Cabbarlı və Vurğunun əsərləri üzrə «əsər - janr» cütlüyü hansı düzgündür?",
  "«Vaqif» mənzum dram, «Azərbaycan» şeir, «Muğan» isə poemadır.",
  ["«Vaqif» - mənzum dram", "«Azərbaycan» - poema",
   "«Muğan» - mənzum dram", "«Almaz» - poema"], 1, None, 3),
 ("Cabbarlı və Vurğunun əsərləri üzrə «obraz - əsər» cütlüyü hansı düzgündür?",
  "Eldar «Vaqif» dramının, Elxan «Od gəlini»nin, Balaş «Sevil»in obrazıdır.",
  ["Eldar - «Vaqif»", "Elxan - «Sevil»", "Balaş - «Od gəlini»",
   "Almaz - «Vaqif»"], 1, None, 3),
 ("Cəfər Cabbarlı ilə Səməd Vurğunun yaradıcılığındakı ortaq cəhət hansıdır?",
  "Hər ikisi dram janrına müraciət etmiş, səhnə əsərləri yazmışdır.",
  ["Hər ikisi dram janrında əsər yazmışdır",
   "Hər ikisi roman janrında əsər yazmışdır",
   "Hər ikisi sərbəst şeirin banisi sayılır",
   "Hər ikisi Cənubi Azərbaycanda doğulmuşdur"], 1, None, 3),
 ("Səməd Vurğunun üç əsəri yazılma ardıcıllığı ilə necə düzülür? "
  "(1 - «Azərbaycan», 2 - «Fərhad və Şirin», 3 - «Komsomol poeması»)",
  "«Komsomol poeması» 1930-cu illərin əvvəlində, «Azərbaycan» 1935-ci, "
  "«Fərhad və Şirin» 1941-ci ildə yazılmışdır.",
  ["3 - 1 - 2", "1 - 2 - 3", "2 - 3 - 1", "1 - 3 - 2"], 1, None, 3),
 ("Səməd Vurğunun əsərləri haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "«Fərhad və Şirin» mənzum dramdır, roman deyil.",
  ["«Fərhad və Şirin» roman janrındadır", "«Vaqif» mənzum dram janrındadır",
   "«Muğan» poema janrındadır", "«Azərbaycan» lirik şeirdir"], 1, None, 3),
 ("Cəfər Cabbarlının hansı əsəri «Sevil» ilə eyni ildə yazılmışdır?",
  "«Sevil» və «Od gəlini» 1928-ci ildə, «Almaz» və «1905-ci ildə» 1931-ci, "
  "«Yaşar» isə 1932-ci ildə yazılmışdır.",
  ["«Od gəlini»", "«Almaz»", "«1905-ci ildə»", "«Yaşar»"], 1, None, 3),
 ("«1905-ci ildə» pyesində qırğının əsas səbəbi kimi nə göstərilir?",
  "Pyesdə qırğının kökündə çar hakimiyyətinin xalqları qarşı-qarşıya "
  "qoyması dayanır.",
  ["Çar hakimiyyətinin xalqları qarşı qoyması",
   "Ticarət yollarına nəzarət uğrunda mübarizə",
   "Din xadimlərinin şəxsi ədavəti",
   "Torpaq islahatının gecikdirilməsi"], 1, None, 3),
 ("Aşağıdakı «yazıçı - fəaliyyət sahəsi» cütlüklərindən hansı düzgündür?",
  "Cabbarlı dramaturq və kino ssenaristi, Vurğun isə şair və mənzum dram "
  "müəllifidir.",
  ["Cəfər Cabbarlı - kino ssenaristi", "Səməd Vurğun - kino ssenaristi",
   "Cəfər Cabbarlı - ensiklopediya redaktoru",
   "Səməd Vurğun - satirik hekayə müəllifi"], 1, None, 3)],

"edeb-11-rza-mircelal": [
 # ---- asan (4)
 ("«Bir gəncin manifesti» romanının müəllifi kimdir?",
  "Roman Mir Cəlalın qələmindən çıxmışdır.",
  ["Mir Cəlal", "Rəsul Rza", "İlyas Əfəndiyev", "İsmayıl Şıxlı"],
  1, None, 1),
 ("Rəsul Rza Azərbaycan poeziyasında hansı şeir formasının ustadı sayılır?",
  "O, sərbəst şeirin ən görkəmli ustadlarındandır.",
  ["Sərbəst şeirin", "Qəzəlin", "Rübainin", "Qəsidənin"], 1, None, 1),
 ("Mir Cəlal hansı ədəbi növdə daha çox tanınır?",
  "Mir Cəlal ilk növbədə nasir - hekayə və roman müəllifidir.",
  ["Nəsrdə", "Dramaturgiyada", "Lirik şeirdə", "Ədəbi tərcümədə"],
  1, None, 1),
 ("Rəsul Rzanın «Rənglər» silsiləsi hansı ədəbi formadadır?",
  "«Rənglər» şeir silsiləsidir.",
  ["Şeir silsiləsi", "Hekayələr toplusu", "Dram əsəri", "Roman"],
  1, None, 1),
 # ---- orta (15)
 ("Rəsul Rza hansı şəhərdə doğulmuşdur?",
  "Şair 1910-cu ildə Göyçayda doğulmuşdur.",
  ["Göyçayda", "Şəkidə", "Qazaxda", "Ərdəbildə"], 1, None, 2),
 ("Rəsul Rzanın «Qızılgül olmayaydı» poeması kimin taleyinə həsr olunub?",
  "Poema repressiya qurbanı olmuş şair Mikayıl Müşfiqin taleyindən bəhs edir.",
  ["Mikayıl Müşfiqin", "Hüseyn Cavidin", "Əhməd Cavadın",
   "Səməd Vurğunun"], 1, None, 2),
 ("Mir Cəlalın ilk romanı hansıdır?",
  "«Dirilən adam» yazıçının ilk romanıdır.",
  ["«Dirilən adam»", "«Bir gəncin manifesti»", "«Açıq kitab»",
   "«Yaşıdlarım»"], 1, None, 2),
 ("Mir Cəlal hansı klassik şairin sənətkarlığına dair monoqrafiya yazmışdır?",
  "Onun «Füzuli sənətkarlığı» monoqrafiyası ədəbiyyatşünaslıqda mühüm yer tutur.",
  ["Füzulinin", "Nizaminin", "Nəsiminin", "Xətainin"], 1, None, 2),
 ("«Bir gəncin manifesti» romanının baş qəhrəmanı kimdir?",
  "Romanın mərkəzində Mərdan obrazı dayanır.",
  ["Mərdan", "Oqtay", "Almaz", "Elxan"], 1, None, 2),
 ("Aşağıdakılardan hansı Mir Cəlalın satirik hekayəsidir?",
  "«Anket Anketov» Mir Cəlalın məşhur satirik hekayəsidir.",
  ["«Anket Anketov»", "«Rənglər»", "«Gülüstan»", "«Dəli Kür»"], 1, None, 2),
 ("Rəsul Rzanın şeirlərində hansı cəhət önə çıxır?",
  "Fəlsəfi düşüncə və qeyri-adi obrazlılıq onun şeirinin əsas cəhətidir.",
  ["Fəlsəfi düşüncə və obrazlılıq", "Nağılvari süjet qurulusu",
   "Dini rəvayətlərin şərhi", "Tarixi salnamə üslubu"], 1, None, 2),
 ("Rəsul Rza uzun müddət hansı böyük nəşrin rəhbəri olmuşdur?",
  "O, Azərbaycan Sovet Ensiklopediyasına baş redaktor olmuşdur.",
  ["Azərbaycan Sovet Ensiklopediyasının", "Dövlət Arxivinin",
   "Milli Kitabxananın", "Dilçilik İnstitutunun"], 1, None, 2),
 ("«Bir gəncin manifesti» romanı hansı dövrün həyatını əks etdirir?",
  "Roman XX əsrin əvvəllərindəki ictimai həyatı canlandırır.",
  ["XX əsrin əvvəllərini", "XV əsri", "XIX əsrin ortalarını",
   "İkinci Dünya müharibəsi illərini"], 1, None, 2),
 ("Rəsul Rzanın «Rənglər» silsiləsində hər şeir nə üzərində qurulur?",
  "Hər şeir bir rəngin doğurduğu assosiasiya və düşüncə üzərində qurulur.",
  ["Bir rəngin doğurduğu assosiasiya", "Bir tarixi hadisənin təsviri",
   "Bir nağıl süjeti", "Bir xalq mahnısının motivi"], 1, None, 2),
 ("Mir Cəlalın hekayələrində aparıcı bədii vasitə hansıdır?",
  "Yumor və satira onun hekayələrinin aparıcı vasitəsidir.",
  ["Yumor və satira", "Mübaliğəli qəhrəmanlıq", "Mistik təsvir",
   "Quru elmi şərh"], 1, None, 2),
 ("Rəsul Rzanın həyat yoldaşı olan tanınmış şairə kimdir?",
  "Şairin həyat yoldaşı Nigar Rəfibəyli olmuşdur.",
  ["Nigar Rəfibəyli", "Mirvarid Dilbazi", "Xurşidbanu Natəvan",
   "Mədinə Gülgün"], 1, None, 2),
 ("Mir Cəlal harada anadan olmuşdur?",
  "Yazıçı Cənubi Azərbaycanın Ərdəbil bölgəsində doğulmuşdur.",
  ["Ərdəbildə", "Gəncədə", "Şəkidə", "Bakıda"], 1, None, 2),
 ("«Bir gəncin manifesti» romanında qabardılan əsas ictimai problem nədir?",
  "Sosial ədalətsizlik və yoxsul ailənin faciəsi ön plandadır.",
  ["Sosial ədalətsizlik və yoxsulluq", "Elmi kəşf uğrunda mübarizə",
   "Dəniz səyahəti macərası", "Şəhərsalma problemləri"], 1, None, 2),
 ("Rəsul Rzanın oğlu olan tanınmış yazıçı kimdir?",
  "Yazıçı Anar Rəsul Rza ilə Nigar Rəfibəylinin oğludur.",
  ["Anar", "Elçin", "Sabir Əhmədli", "Çingiz Hüseynov"], 1, None, 2),
 # ---- cetin (12)
 ("Mir Cəlalın üç əsəri yazılma ardıcıllığı ilə necə düzülür? "
  "(1 - «Dirilən adam», 2 - «Yaşıdlarım», 3 - «Bir gəncin manifesti»)",
  "«Dirilən adam» 1935-ci, «Bir gəncin manifesti» 1939-cu, «Yaşıdlarım» "
  "isə 1940-cı illərin ortalarında yazılmışdır.",
  ["1 - 3 - 2", "1 - 2 - 3", "3 - 1 - 2", "2 - 1 - 3"], 1, None, 3),
 ("Rəsul Rza və Mir Cəlala aid «əsər - müəllif» cütlüyü hansı düzgündür?",
  "«Rənglər» Rəsul Rzanın, «Açıq kitab» isə Mir Cəlalın əsəridir.",
  ["«Rənglər» - Rəsul Rza", "«Rənglər» - Mir Cəlal",
   "«Açıq kitab» - Rəsul Rza", "«Qızılgül olmayaydı» - Mir Cəlal"],
  1, None, 3),
 ("Rəsul Rza haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "Rəsul Rza əruz vəznində deyil, əsasən sərbəst şeirdə yazmışdır.",
  ["Əsasən əruz vəznində yazmışdır",
   "Sərbəst şeirin inkişafında rol oynamışdır",
   "«Rənglər» silsiləsi onun qələmindəndir",
   "«Qızılgül olmayaydı» poeması ona məxsusdur"], 1, None, 3),
 ("Rəsul Rzanın sərbəst şeirə üstünlük verməsinin əsas səbəbi nə idi?",
  "Şair fikri ənənəvi vəzn və qafiyə qəliblərindən azad etmək istəyirdi.",
  ["Fikri vəzn qəliblərindən azad etmək istəyi",
   "Xalq şeiri formalarını canlandırmaq istəyi",
   "Klassik əruzu bərpa etmək niyyəti",
   "Dram dilinə yaxınlaşmaq cəhdi"], 1, None, 3),
 ("Aşağıdakı «obraz - əsər» cütlüklərindən hansı doğrudur?",
  "Mərdan «Bir gəncin manifesti» romanının obrazıdır.",
  ["Mərdan - «Bir gəncin manifesti»", "Mərdan - «Dirilən adam»",
   "Almaz - «Bir gəncin manifesti»", "Elxan - «Dirilən adam»"],
  1, None, 3),
 ("Rəsul Rza ilə Mir Cəlalın yaradıcılığını fərqləndirən əsas cəhət hansıdır?",
  "Rəsul Rza poeziyada, Mir Cəlal isə nəsrdə yazmışdır.",
  ["Biri poeziyada, digəri nəsrdə yazmışdır",
   "Biri nəsrdə, digəri dramda yazmışdır",
   "Biri tərcümədə, digəri tənqiddə çalışmışdır",
   "Biri uşaq ədəbiyyatında, digəri publisistikada işləmişdir"],
  1, None, 3),
 ("Mir Cəlal haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "Mir Cəlal mənzum dram yazmamışdır; o, nasir və ədəbiyyatşünas idi.",
  ["Mənzum dram müəllifidir", "«Dirilən adam» onun romanıdır",
   "Füzuli sənətkarlığını araşdırmışdır",
   "Satirik hekayələr müəllifidir"], 1, None, 3),
 ("Mir Cəlalın «Dirilən adam» və «Bir gəncin manifesti» romanları "
  "arasında neçə il fərq var?",
  "«Dirilən adam» 1935-ci, «Bir gəncin manifesti» 1939-cu ildə yazılıb.",
  ["4 il", "2 il", "7 il", "11 il"], 1, None, 3),
 ("Aşağıdakı «şəxs - fəaliyyət» cütlüklərindən hansı düzgündür?",
  "Nigar Rəfibəyli şairə, Anar isə nasir və dramaturqdur.",
  ["Nigar Rəfibəyli - şairə", "Nigar Rəfibəyli - dramaturq",
   "Anar - Xalq şairi", "Mir Cəlal - ensiklopediya redaktoru"],
  1, None, 3),
 ("«Qızılgül olmayaydı» poemasının yaranmasına səbəb olan hadisə hansıdır?",
  "Poema Mikayıl Müşfiqin repressiya qurbanı olması faciəsi üzərində qurulub.",
  ["Mikayıl Müşfiqin repressiya qurbanı olması",
   "Hüseyn Cavidin nəşinin vətənə gətirilməsi",
   "Səməd Vurğunun Xalq şairi seçilməsi",
   "Əhməd Cavadın himn mətnini yazması"], 1, None, 3),
 ("Mir Cəlal və Rəsul Rzanın əsərləri üzrə «əsər - janr» cütlüyü hansı doğrudur?",
  "«Bir gəncin manifesti» roman, «Anket Anketov» hekayə, «Rənglər» "
  "isə şeir silsiləsidir.",
  ["«Bir gəncin manifesti» - roman", "«Anket Anketov» - roman",
   "«Rənglər» - poema", "«Dirilən adam» - hekayə"], 1, None, 3),
 ("Mir Cəlal və Rəsul Rzanın doğulduğu yerlər haqqında hansı fikir doğrudur?",
  "Mir Cəlal Ərdəbildə, Rəsul Rza isə Göyçayda doğulmuşdur.",
  ["Mir Cəlal Ərdəbildə, Rəsul Rza Göyçayda",
   "Mir Cəlal Göyçayda, Rəsul Rza Ərdəbildə",
   "Mir Cəlal Bakıda, Rəsul Rza Ərdəbildə",
   "Mir Cəlal Göyçayda, Rəsul Rza Bakıda"], 1, None, 3)],
}
SUALLAR.update(HISSE_2)

HISSE_3 = {
"edeb-11-ozunuderk": [
 # ---- asan (4)
 ("«Dəli Kür» romanının müəllifi kimdir?",
  "Roman İsmayıl Şıxlının qələmindən çıxmışdır.",
  ["İsmayıl Şıxlı", "İlyas Əfəndiyev", "Mir Cəlal", "Rəsul Rza"],
  1, None, 1),
 ("«Söyüdlü arx» əsərinin müəllifi kimdir?",
  "«Söyüdlü arx» İlyas Əfəndiyevin romanıdır.",
  ["İlyas Əfəndiyev", "İsmayıl Şıxlı", "Mir Cəlal", "Bəxtiyar Vahabzadə"],
  1, None, 1),
 ("«Dəli Kür» romanının baş qəhrəmanı kimdir?",
  "Əsərin mərkəzində Cahandar ağa obrazı dayanır.",
  ["Cahandar ağa", "Şamxal", "Əşrəf", "Mərdan"], 1, None, 1),
 ("İsmayıl Şıxlı hansı bölgədə doğulmuşdur?",
  "Yazıçı Qazax rayonunun İkinci Şıxlı kəndində doğulmuşdur.",
  ["Qazax rayonunda", "Şəki rayonunda", "Füzuli rayonunda",
   "Göyçay rayonunda"], 1, None, 1),
 # ---- orta (15)
 ("İlyas Əfəndiyev Azərbaycan teatrında hansı üslubun banisi sayılır?",
  "O, lirik-psixoloji dram üslubunun əsasını qoymuşdur.",
  ["Lirik-psixoloji dramın", "Satirik komediyanın", "Tarixi faciənin",
   "Musiqili komediyanın"], 1, None, 2),
 ("«Dəli Kür» romanında hadisələr hansı çayın sahilində cərəyan edir?",
  "Roman Kür çayı sahilindəki kənd həyatını təsvir edir.",
  ["Kür çayının", "Araz çayının", "Samur çayının", "Qanıx çayının"],
  1, None, 2),
 ("«Dəli Kür»də Cahandar ağa obrazı nəyi təmsil edir?",
  "O, dağılmaqda olan patriarxal dünyanın son nümayəndəsidir.",
  ["Dağılmaqda olan patriarxal dünyanı", "Yeni sənaye şəhərini",
   "Xaricdə təhsil almış ziyalını", "Din xadimlərinin nüfuzunu"],
  1, None, 2),
 ("«Dəli Kür» romanında Əşrəf obrazı nəyə can atır?",
  "Əşrəf təhsilə və yeni həyat qaydalarına can atır.",
  ["Təhsilə və yeni həyata", "Var-dövlət toplamağa", "Hərbi karyeraya",
   "Ticarətlə zənginləşməyə"], 1, None, 2),
 ("İlyas Əfəndiyevin «Mahnı dağlarda qaldı» əsəri hansı janrdadır?",
  "Əsər dram (pyes) janrındadır.",
  ["Dram", "Roman", "Poema", "Hekayə"], 1, None, 2),
 ("İlyas Əfəndiyev hansı tarixi şəxsiyyət haqqında dram yazmışdır?",
  "O, şairə Xurşidbanu Natəvanın həyatına dram həsr etmişdir.",
  ["Xurşidbanu Natəvan", "Molla Pənah Vaqif", "Şah İsmayıl Xətai",
   "Nizami Gəncəvi"], 1, None, 2),
 ("Aşağıdakılardan hansı İlyas Əfəndiyevin romanıdır?",
  "«Körpüsalanlar» İlyas Əfəndiyevin romanıdır.",
  ["«Körpüsalanlar»", "«Dəli Kür»", "«Açıq kitab»", "«Rənglər»"],
  1, None, 2),
 ("İsmayıl Şıxlının ilk romanı hansıdır?",
  "«Ayrılan yollar» yazıçının ilk romanıdır.",
  ["«Ayrılan yollar»", "«Dəli Kür»", "«Ölən dünyam»", "«Üçatılan»"],
  1, None, 2),
 ("«Dəli Kür» romanı hansı dövrün hadisələrini əks etdirir?",
  "Roman XX əsrin ilk onilliklərindəki kənd həyatını canlandırır.",
  ["XX əsrin ilk onilliklərini", "XVI əsri", "XIX əsrin ortalarını",
   "İkinci Dünya müharibəsi illərini"], 1, None, 2),
 ("İlyas Əfəndiyevin dramlarında hansı cəhət önə çıxır?",
  "Qəhrəmanın daxili aləminin incə psixoloji təhlili önə çıxır.",
  ["Qəhrəmanın daxili aləminin təhlili", "Kütləvi döyüş səhnələri",
   "Detektiv süjet qurulusu", "Fantastik təsvirlər"], 1, None, 2),
 ("İsmayıl Şıxlının həyatındakı hansı təcrübə əsərlərinə güclü təsir etmişdir?",
  "Yazıçı İkinci Dünya müharibəsində cəbhədə olmuş, bu təcrübə əsərlərinə hopmuşdur.",
  ["Cəbhədə keçirdiyi illər", "Xaricdə təhsil illəri",
   "Dənizçilik təcrübəsi", "Diplomatik xidməti"], 1, None, 2),
 ("«Dəli Kür» romanında Şamxal atası ilə hansı münasibətdədir?",
  "Şamxal ataya qarşı çıxır, onun qaydalarını qəbul etmir.",
  ["Ataya qarşı çıxan oğuldur", "Ataya sözsüz tabe olan oğuldur",
   "Atasını əvəz edən böyük qardaşdır", "Ailədən uzaqda böyümüş oğuldur"],
  1, None, 2),
 ("İlyas Əfəndiyev hansı fəxri ada layiq görülmüşdür?",
  "Ona Xalq yazıçısı fəxri adı verilmişdir.",
  ["Xalq yazıçısı", "Xalq şairi", "Xalq artisti", "Əməkdar həkim"],
  1, None, 2),
 ("İlyas Əfəndiyevin oğlu olan tanınmış yazıçı kimdir?",
  "Yazıçı Elçin İlyas Əfəndiyevin oğludur.",
  ["Elçin", "Anar", "Sabir Əhmədli", "Əkrəm Əylisli"], 1, None, 2),
 ("İsmayıl Şıxlının son romanlarından biri hansıdır?",
  "«Ölən dünyam» yazıçının son dövr romanlarındandır.",
  ["«Ölən dünyam»", "«Söyüdlü arx»", "«Yaşıdlarım»", "«Açıq kitab»"],
  1, None, 2),
 # ---- cetin (12)
 ("Aşağıdakı üç hadisə zaman ardıcıllığı ilə necə düzülür? "
  "(1 - «Dəli Kür» romanı, 2 - «Ayrılan yollar» romanı, "
  "3 - İsmayıl Şıxlının doğulması)",
  "İsmayıl Şıxlı 1919-cu ildə doğulub, «Ayrılan yollar» 1950-ci illərin "
  "sonunda, «Dəli Kür» isə 1960-cı illərdə nəşr olunub.",
  ["3 - 2 - 1", "1 - 2 - 3", "2 - 3 - 1", "3 - 1 - 2"], 1, None, 3),
 ("İ.Əfəndiyev və İ.Şıxlıya aid «əsər - müəllif» cütlüyü hansı doğrudur?",
  "«Dəli Kür» İsmayıl Şıxlının, «Söyüdlü arx» İlyas Əfəndiyevindir.",
  ["«Dəli Kür» - İsmayıl Şıxlı", "«Dəli Kür» - İlyas Əfəndiyev",
   "«Söyüdlü arx» - İsmayıl Şıxlı", "«Ölən dünyam» - İlyas Əfəndiyev"],
  1, None, 3),
 ("İlyas Əfəndiyev haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "«Dəli Kür» İsmayıl Şıxlının romanıdır, İlyas Əfəndiyevin deyil.",
  ["«Dəli Kür» romanının müəllifidir", "«Söyüdlü arx» onun romanıdır",
   "Lirik-psixoloji dramlar yazmışdır",
   "Xalq yazıçısı adına layiq görülüb"], 1, None, 3),
 ("Cahandar ağanın faciəsinin əsas səbəbi nədir?",
  "Dəyişən zamanla köhnə həyat qaydalarının toqquşması onu məhvə aparır.",
  ["Zamanla köhnə qaydaların toqquşması", "Ailəsinin torpaqsız qalması",
   "Uzaq şəhərə köçmək məcburiyyəti", "Ticarətdə uğursuzluğa düşməsi"],
  1, None, 3),
 ("«Dəli Kür» üzrə «obraz - əsər» cütlüklərindən hansı düzgündür?",
  "Cahandar ağa «Dəli Kür» romanının obrazıdır.",
  ["Cahandar ağa - «Dəli Kür»", "Cahandar ağa - «Söyüdlü arx»",
   "Mərdan - «Dəli Kür»", "Şamxal - «Ayrılan yollar»"], 1, None, 3),
 ("İlyas Əfəndiyev və İsmayıl Şıxlının yaradıcılığındakı ortaq cəhət hansıdır?",
  "Hər ikisi nəsrdə çalışmış və Xalq yazıçısı adına layiq görülmüşdür.",
  ["Hər ikisi Xalq yazıçısı adını almışdır",
   "Hər ikisi əsasən poeziyada yazmışdır",
   "Hər ikisi Cənubi Azərbaycanda doğulmuşdur",
   "Hər ikisi ensiklopediya redaktoru olmuşdur"], 1, None, 3),
 ("«Dəli Kür» romanı haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "Romanın hadisələri müharibə illərində deyil, XX əsrin əvvəlində keçir.",
  ["Hadisələr İkinci Dünya müharibəsindən bəhs edir",
   "Cahandar ağa əsərin mərkəzi obrazıdır",
   "Hadisələr Kür sahilindəki kənddə keçir",
   "Şamxal Cahandar ağanın oğludur"], 1, None, 3),
 ("İlyas Əfəndiyev ilə İsmayıl Şıxlının doğum illəri arasında neçə il fərq var?",
  "İlyas Əfəndiyev 1914-cü ildə, İsmayıl Şıxlı 1919-cu ildə doğulmuşdur.",
  ["5 il", "2 il", "9 il", "14 il"], 1, None, 3),
 ("Aşağıdakı «yazıçı - üslub» cütlüklərindən hansı doğrudur?",
  "Lirik-psixoloji dram İlyas Əfəndiyevin adı ilə bağlıdır.",
  ["İlyas Əfəndiyev - lirik-psixoloji dram",
   "İsmayıl Şıxlı - lirik-psixoloji dram",
   "İlyas Əfəndiyev - satirik hekayə", "İsmayıl Şıxlı - sərbəst şeir"],
  1, None, 3),
 ("Şamxalın atası ilə toqquşmasının kökündə nə dayanır?",
  "Nəsil dəyişməsi və yeni həyat tərzinin köhnə qaydaları sıxışdırmasıdır.",
  ["Nəsil dəyişməsi və yeni həyat tərzi",
   "Torpaq mülkiyyəti üstündə mübahisə",
   "Qonşu kəndlə ticarət rəqabəti", "Şəhərdə təhsil almaq istəyi"],
  1, None, 3),
 ("İsmayıl Şıxlının iki romanı haqqında hansı fikir doğrudur?",
  "«Ayrılan yollar» daha əvvəl, «Dəli Kür» isə sonra yazılmışdır.",
  ["«Ayrılan yollar» əvvəl, «Dəli Kür» sonra",
   "«Dəli Kür» əvvəl, «Ayrılan yollar» sonra",
   "Hər ikisi eyni ildə yazılıb", "Hər ikisi müharibədən əvvəl yazılıb"],
  1, None, 3),
 ("Özünüdərk mövzusu bu iki yazıçının əsərlərində necə təzahür edir?",
  "Milli kökə, keçmişə və adət-ənənəyə yeni gözlə baxmaqla təzahür edir.",
  ["Milli kökə və keçmişə yeni baxışla",
   "Xarici ölkə həyatının təsviri ilə",
   "Elmi-texniki tərəqqinin tərənnümü ilə",
   "Dini rəvayətlərin bədii şərhi ilə"], 1, None, 3)],

"edeb-11-istiqlal": [
 # ---- asan (4)
 ("«Gülüstan» poemasının müəllifi kimdir?",
  "Poema Bəxtiyar Vahabzadənin qələmindən çıxmışdır.",
  ["Bəxtiyar Vahabzadə", "Məmməd Araz", "Xəlil Rza Ulutürk", "Rəsul Rza"],
  1, None, 1),
 ("Bəxtiyar Vahabzadə hansı şəhərdə doğulmuşdur?",
  "Şair 1925-ci ildə Şəkidə doğulmuşdur.",
  ["Şəkidə", "Qazaxda", "Göyçayda", "Naxçıvanda"], 1, None, 1),
 ("«Gülüstan» poemasının əsas mövzusu nədir?",
  "Poema xalqın iki yerə bölünməsi faciəsindən bəhs edir.",
  ["Xalqın iki yerə bölünməsi", "Sənaye inqilabı", "Dəniz səyahəti",
   "Kənd təsərrüfatı islahatı"], 1, None, 1),
 ("Bəxtiyar Vahabzadə hansı fəxri ada layiq görülmüşdür?",
  "Ona Xalq şairi fəxri adı verilmişdir.",
  ["Xalq şairi", "Xalq artisti", "Əməkdar müəllim", "Əməkdar rəssam"],
  1, None, 1),
 # ---- orta (15)
 ("Bəxtiyar Vahabzadənin «Şəhidlər» əsəri hansı hadisəyə həsr olunub?",
  "Əsər 20 Yanvar faciəsinin qurbanlarına həsr olunmuşdur.",
  ["20 Yanvar faciəsinə", "Xocalı soyqırımına",
   "İkinci Dünya müharibəsinə", "1937-ci il repressiyasına"], 1, None, 2),
 ("«Gülüstan» poemasının yazılması şairə hansı nəticəni gətirdi?",
  "Şair təqib olundu və universitetdəki işindən uzaqlaşdırıldı.",
  ["Təqib olunub işindən uzaqlaşdırıldı", "Dövlət mükafatı aldı",
   "Xaricə səfərə göndərildi", "Akademiyaya üzv seçildi"], 1, None, 2),
 ("Məmməd Arazın məşhur şeirlərindən biri hansıdır?",
  "«Ayağa dur, Azərbaycan!» Məmməd Arazın məşhur şeiridir.",
  ["«Ayağa dur, Azərbaycan!»", "«Gülüstan»", "«Rənglər»",
   "«Heydərbabaya salam»"], 1, None, 2),
 ("Xəlil Rza Ulutürk ədəbiyyat tarixinə hansı adla düşmüşdür?",
  "O, istiqlal şairi kimi tanınır.",
  ["İstiqlal şairi", "Uşaq şairi", "Satira ustası", "Ədəbi tənqidçi"],
  1, None, 2),
 ("Bəxtiyar Vahabzadənin «Muğam» əsəri hansı janrdadır?",
  "«Muğam» poema janrındadır.",
  ["Poema", "Roman", "Hekayə", "Komediya"], 1, None, 2),
 ("Aşağıdakılardan hansı Bəxtiyar Vahabzadənin dramıdır?",
  "«Vicdan» şairin dram əsəridir.",
  ["«Vicdan»", "«Almaz»", "«Sevil»", "«Dəli Kür»"], 1, None, 2),
 ("İstiqlal ədəbiyyatının əsas ideyası nədir?",
  "Milli azadlıq və dövlət müstəqilliyi ideyasıdır.",
  ["Milli azadlıq və müstəqillik", "Sənaye tərəqqisi",
   "Şəhər həyatının tərənnümü", "Elmi kəşflərin təbliği"], 1, None, 2),
 ("«Gülüstan» poemasında Araz çayı nəyin nişanına çevrilir?",
  "Araz bölünmüş xalqın ayrılıq nişanına çevrilir.",
  ["Bölünmüş xalqın ayrılıq nişanının", "Bolluq və bərəkətin",
   "Ticarət yolunun", "Sərhədsiz dostluğun"], 1, None, 2),
 ("Bəxtiyar Vahabzadənin yaradıcılığında hansı mövzu aparıcıdır?",
  "Vətən, ana dili və milli kimlik mövzusu aparıcıdır.",
  ["Vətən və ana dili", "Kosmos və elm", "Dəniz macəraları",
   "Şəhər memarlığı"], 1, None, 2),
 ("Xəlil Rza Ulutürk 1990-cı ildə hansı hadisə ilə üzləşdi?",
  "O, həbs olunub Moskvada saxlanılmışdır.",
  ["Həbs olunub Moskvada saxlanıldı", "Xaricə mühacirət etdi",
   "Akademiyaya rəhbər seçildi", "Ordudan tərxis olundu"], 1, None, 2),
 ("Məmməd Araz hansı bölgədə doğulmuşdur?",
  "Şair Naxçıvanın Şahbuz bölgəsində doğulmuşdur.",
  ["Naxçıvanda", "Şəkidə", "Lənkəranda", "Qubada"], 1, None, 2),
 ("Bəxtiyar Vahabzadənin «Şəhidlər» əsəri hansı ildə yazılmışdır?",
  "Əsər 1990-cı ildə, faciədən dərhal sonra yazılmışdır.",
  ["1990", "1988", "1993", "1995"], 1, None, 2),
 ("İstiqlal ədəbiyyatının yüksəliş dövrü hansı illərə təsadüf edir?",
  "Yüksəliş 1980-ci illərin sonu - 1990-cı illərin əvvəlinə düşür.",
  ["1980-ci illərin sonuna", "1930-cu illərə", "1950-ci illərə",
   "1960-cı illərin ortasına"], 1, None, 2),
 ("Bəxtiyar Vahabzadə ədəbi yaradıcılıqla yanaşı hansı işlə məşğul olmuşdur?",
  "O, uzun illər universitetdə müəllim və ədəbiyyatşünas kimi çalışmışdır.",
  ["Universitet müəllimi kimi", "Həkim kimi", "Mühəndis kimi",
   "Diplomat kimi"], 1, None, 2),
 ("«Gülüstan» poeması hansı ildə yazılmışdır?",
  "Poema 1959-cu ildə yazılmışdır.",
  ["1959", "1937", "1970", "1990"], 1, None, 2),
 # ---- cetin (12)
 ("Aşağıdakı üç hadisə zaman ardıcıllığı ilə necə düzülür? "
  "(1 - Gülüstan müqaviləsi, 2 - «Gülüstan» poeması, 3 - «Şəhidlər» əsəri)",
  "Müqavilə 1813-cü ildə, poema 1959-cu ildə, «Şəhidlər» 1990-cı ildə.",
  ["1 - 2 - 3", "2 - 1 - 3", "3 - 2 - 1", "2 - 3 - 1"], 1, None, 3),
 ("Aşağıdakı «əsər - il» cütlüklərindən hansı düzgündür?",
  "«Şəhidlər» 1990-cı ildə, «Gülüstan» poeması isə 1959-cu ildə yazılıb.",
  ["«Şəhidlər» - 1990", "«Gülüstan» - 1990", "«Şəhidlər» - 1959",
   "«Gülüstan» - 1813"], 1, None, 3),
 ("Bəxtiyar Vahabzadə haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "«Rənglər» silsiləsi Rəsul Rzaya məxsusdur.",
  ["«Rənglər» silsiləsinin müəllifidir", "«Gülüstan» poemasını yazmışdır",
   "«Vicdan» dramının müəllifidir", "Şəkidə doğulmuşdur"], 1, None, 3),
 ("«Gülüstan» poemasının hakimiyyət tərəfindən xoş qarşılanmamasının "
  "səbəbi nə idi?",
  "Poema xalqın bölünməsini açıq şəkildə xatırladırdı.",
  ["Xalqın bölünməsini xatırlatması", "Dini mövzuya toxunması",
   "Xarici dildə yazılması", "Klassik vəznə uyğun gəlməməsi"], 1, None, 3),
 ("Aşağıdakı «şair - əsər» cütlüklərindən hansı doğrudur?",
  "«Ayağa dur, Azərbaycan!» Məmməd Arazın şeiridir.",
  ["Məmməd Araz - «Ayağa dur, Azərbaycan!»",
   "Bəxtiyar Vahabzadə - «Ayağa dur, Azərbaycan!»",
   "Məmməd Araz - «Gülüstan»", "Xəlil Rza Ulutürk - «Muğam»"],
  1, None, 3),
 ("Bəxtiyar Vahabzadə ilə Xəlil Rza Ulutürkün yaradıcılığındakı ortaq "
  "cəhət hansıdır?",
  "Hər ikisi milli azadlıq və istiqlal mövzusunda yazmışdır.",
  ["Hər ikisi milli azadlıq mövzusunda yazmışdır",
   "Hər ikisi satirik hekayə müəllifidir",
   "Hər ikisi eyni şəhərdə doğulmuşdur",
   "Hər ikisi roman janrında çalışmışdır"], 1, None, 3),
 ("İstiqlal ədəbiyyatı haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "Bu ədəbiyyat XIX əsrdə deyil, XX əsrin sonunda güclənmişdir.",
  ["Əsasən XIX əsrdə formalaşmışdır",
   "Milli azadlıq ideyasını önə çəkir",
   "20 Yanvar hadisələri onda əks olunub",
   "Bəxtiyar Vahabzadə onun nümayəndəsidir"], 1, None, 3),
 ("«Gülüstan» poeması ilə «Şəhidlər» əsərinin yazılması arasında neçə il "
  "keçmişdir?",
  "Poema 1959-cu ildə, «Şəhidlər» isə 1990-cı ildə yazılmışdır.",
  ["31 il", "21 il", "41 il", "11 il"], 1, None, 3),
 ("Aşağıdakı «şair - doğulduğu yer» cütlüklərindən hansı düzgündür?",
  "Bəxtiyar Vahabzadə Şəkidə, Məmməd Araz Naxçıvanda doğulmuşdur.",
  ["Bəxtiyar Vahabzadə - Şəki", "Məmməd Araz - Şəki",
   "Bəxtiyar Vahabzadə - Naxçıvan", "Xəlil Rza Ulutürk - Şəki"],
  1, None, 3),
 ("20 Yanvar faciəsinin Azərbaycan poeziyasına təsiri necə oldu?",
  "Şəhidlik və müqavimət mövzusu poeziyada güclə önə çıxdı.",
  ["Şəhidlik və müqavimət mövzusu önə çıxdı",
   "Məhəbbət lirikası aparıcı mövzuya çevrildi",
   "Tarixi salnamə üslubu üstünlük qazandı",
   "Şeir dili klassik əruza qayıtdı"], 1, None, 3),
 ("«Gülüstan» poemasında hansı iki tarixi fakt qarşılaşdırılır?",
  "1813-cü il müqaviləsi və onun doğurduğu ayrılıq qarşılaşdırılır.",
  ["1813-cü il müqaviləsi və sonrakı ayrılıq",
   "1918-ci il istiqlalı və 1920-ci il işğalı",
   "1937-ci il repressiyası və müharibə illəri",
   "1991-ci il müstəqilliyi və Qarabağ münaqişəsi"], 1, None, 3),
 ("İstiqlal ədəbiyyatı üzrə «əsər - janr» cütlüklərindən hansı düzgündür?",
  "«Gülüstan» poema, «Vicdan» dram janrındadır.",
  ["«Gülüstan» - poema", "«Vicdan» - poema", "«Muğam» - dram",
   "«Şəhidlər» - roman"], 1, None, 3)],
}
SUALLAR.update(HISSE_3)

HISSE_4 = {
"edeb-11-cenub-dunya": [
 # ---- asan (4)
 ("«Heydərbabaya salam» poemasının müəllifi kimdir?",
  "Poemanı Məhəmmədhüseyn Şəhriyar yazmışdır.",
  ["Məhəmmədhüseyn Şəhriyar", "Səməd Behrəngi",
   "Bulud Qaraçorlu Səhənd", "Balaş Azəroğlu"], 1, None, 1),
 ("«Hamlet» faciəsinin müəllifi kimdir?",
  "Faciənin müəllifi Uilyam Şekspirdir.",
  ["Uilyam Şekspir", "Onore de Balzak", "Ernest Heminquey",
   "Lev Tolstoy"], 1, None, 1),
 ("Səməd Behrənginin ən məşhur nağılı hansıdır?",
  "«Balaca qara balıq» onun ən məşhur nağılıdır.",
  ["«Balaca qara balıq»", "«Qoca və dəniz»", "«Ağ gəmi»", "«Faust»"],
  1, None, 1),
 ("Məhəmmədhüseyn Şəhriyar hansı şəhərdə doğulmuşdur?",
  "Şair Təbrizdə doğulmuşdur.",
  ["Təbrizdə", "Bakıda", "Ərdəbildə", "Tehranda"], 1, None, 1),
 # ---- orta (15)
 ("«Heydərbabaya salam» poemasında Heydərbaba nədir?",
  "Heydərbaba Təbriz yaxınlığındakı dağın adıdır.",
  ["Bir dağın adı", "Bir çayın adı", "Bir şəhərin adı",
   "Bir kitabın adı"], 1, None, 2),
 ("Məhəmmədhüseyn Şəhriyar hansı iki dildə əsərlər yazmışdır?",
  "Şair həm Azərbaycan, həm də fars dilində yazmışdır.",
  ["Azərbaycan və fars dillərində", "Azərbaycan və rus dillərində",
   "Fars və ərəb dillərində", "Türk və ingilis dillərində"], 1, None, 2),
 ("Səməd Behrəngi əsas peşəsinə görə kim idi?",
  "O, kənd məktəblərində çalışan müəllim idi.",
  ["Müəllim", "Həkim", "Mühəndis", "Hüquqşünas"], 1, None, 2),
 ("«Sazımın sözü» əsəri hansı abidənin motivləri üzərində qurulub?",
  "Bulud Qaraçorlu Səhəndin əsəri «Kitabi-Dədə Qorqud» motivlərinə əsaslanır.",
  ["«Kitabi-Dədə Qorqud»", "«Koroğlu»", "«Şahnamə»", "«Xəmsə»"],
  1, None, 2),
 ("«Qoca və dəniz» əsərinin müəllifi kimdir?",
  "Əsərin müəllifi Ernest Heminqueydir.",
  ["Ernest Heminquey", "Qabriel Qarsia Markes", "Çingiz Aytmatov",
   "Nazim Hikmət"], 1, None, 2),
 ("«Faust» əsərinin müəllifi hansı ölkənin yazıçısıdır?",
  "«Faust»un müəllifi alman yazıçısı Hötedir.",
  ["Almaniyanın", "Fransanın", "İngiltərənin", "İtaliyanın"], 1, None, 2),
 ("Çingiz Aytmatov hansı xalqın ədəbiyyatının görkəmli nümayəndəsidir?",
  "Aytmatov qırğız ədəbiyyatının görkəmli nümayəndəsidir.",
  ["Qırğız", "Özbək", "Qazax", "Tatar"], 1, None, 2),
 ("Nazim Hikmət hansı ölkənin şairidir?",
  "Nazim Hikmət Türkiyə şairidir.",
  ["Türkiyənin", "İranın", "Rusiyanın", "Bolqarıstanın"], 1, None, 2),
 ("«Yüz ilin tənhalığı» romanının müəllifi kimdir?",
  "Romanın müəllifi Qabriel Qarsia Markesdir.",
  ["Qabriel Qarsia Markes", "Lev Tolstoy", "Onore de Balzak",
   "Uilyam Şekspir"], 1, None, 2),
 ("Cənubi Azərbaycan ədəbiyyatının aparıcı mövzusu nədir?",
  "Ana dili, vətən həsrəti və azadlıq arzusu aparıcı mövzudur.",
  ["Ana dili və vətən həsrəti", "Sənaye tərəqqisi",
   "Dəniz səyahətləri", "Şəhər memarlığı"], 1, None, 2),
 ("«Balaca qara balıq» nağılının əsas ideyası nədir?",
  "Nağıl azadlıq, cəsarət və yeni dünyanı görmək arzusundan bəhs edir.",
  ["Azadlıq və cəsarət axtarışı", "Var-dövlət toplamaq",
   "Ailə ənənəsini qorumaq", "Elm öyrənməyin çətinliyi"], 1, None, 2),
 ("«Qorio ata» romanının müəllifi kimdir?",
  "Romanın müəllifi fransız yazıçısı Onore de Balzakdır.",
  ["Onore de Balzak", "Ernest Heminquey", "Çingiz Aytmatov",
   "Rəsul Həmzətov"], 1, None, 2),
 ("«Heydərbabaya salam» poeması hansı dildə yazılmışdır?",
  "Poema Azərbaycan dilində, ana dilində yazılmışdır.",
  ["Azərbaycan dilində", "Fars dilində", "Ərəb dilində", "Rus dilində"],
  1, None, 2),
 ("1945-1946-cı il hadisələrindən sonra bir sıra cənublu şair harada "
  "yaşayıb-yaratdı?",
  "Onlar Şimali Azərbaycana keçib burada yaradıcılığını davam etdirdilər.",
  ["Şimali Azərbaycanda", "Türkiyədə", "Almaniyada", "Misirdə"],
  1, None, 2),
 ("«Mənim Dağıstanım» əsərinin müəllifi kimdir?",
  "Əsərin müəllifi Rəsul Həmzətovdur.",
  ["Rəsul Həmzətov", "Nazim Hikmət", "Çingiz Aytmatov", "Lev Tolstoy"],
  1, None, 2),
 # ---- cetin (12)
 ("Aşağıdakı üç əsər yazılma ardıcıllığı ilə necə düzülür? "
  "(1 - «Hamlet», 2 - «Yüz ilin tənhalığı», 3 - «Faust»)",
  "«Hamlet» XVII əsrin əvvəlində, «Faust» XIX əsrin birinci yarısında, "
  "«Yüz ilin tənhalığı» isə XX əsrin ikinci yarısında yazılmışdır.",
  ["1 - 3 - 2", "1 - 2 - 3", "3 - 1 - 2", "2 - 1 - 3"], 1, None, 3),
 ("Cənub şairlərinə aid «əsər - müəllif» cütlüklərindən hansı doğrudur?",
  "«Heydərbabaya salam» Şəhriyarın, «Sazımın sözü» Səhəndin əsəridir.",
  ["«Heydərbabaya salam» - Şəhriyar", "«Sazımın sözü» - Şəhriyar",
   "«Balaca qara balıq» - Səhənd",
   "«Heydərbabaya salam» - Behrəngi"], 1, None, 3),
 ("Məhəmmədhüseyn Şəhriyar haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "«Sazımın sözü» Bulud Qaraçorlu Səhəndin əsəridir.",
  ["«Sazımın sözü» əsərinin müəllifidir",
   "«Heydərbabaya salam» onun poemasıdır", "Təbrizdə doğulmuşdur",
   "İki dildə əsər yazmışdır"], 1, None, 3),
 ("Cənubi Azərbaycan ədəbiyyatında ana dili mövzusunun güclü olmasının "
  "səbəbi nədir?",
  "Ana dilində təhsilin və nəşrin məhdudlaşdırılması bu mövzunu ön plana "
  "çıxarmışdır.",
  ["Ana dilində təhsilin məhdudlaşdırılması",
   "Yazı ənənəsinin gec formalaşması", "Xalq şeirinin unudulması",
   "Mətbəənin gec yaranması"], 1, None, 3),
 ("Aşağıdakı «yazıçı - ölkə» cütlüklərindən hansı düzgündür?",
  "Heminquey ABŞ, Balzak Fransa, Nazim Hikmət Türkiyə ədəbiyyatındandır.",
  ["Ernest Heminquey - ABŞ", "Ernest Heminquey - İngiltərə",
   "Onore de Balzak - ABŞ", "Nazim Hikmət - Almaniya"], 1, None, 3),
 ("Şəhriyar və Səməd Behrənginin yaradıcılığındakı ortaq cəhət hansıdır?",
  "Hər ikisi Cənubi Azərbaycanda yaşayıb-yaratmış, ana dilinə bağlı olmuşdur.",
  ["Hər ikisi Cənubi Azərbaycanda yaratmışdır",
   "Hər ikisi nağıl janrında yazmışdır",
   "Hər ikisi Bakıda təhsil almışdır",
   "Hər ikisi poema janrında yazmışdır"], 1, None, 3),
 ("Dünya ədəbiyyatı haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "«Qoca və dəniz» Heminqueyin əsəridir, Markesin deyil.",
  ["«Qoca və dəniz» Markesin əsəridir", "«Hamlet» Şekspirin faciəsidir",
   "«Faust» Hötenin əsəridir", "«Qorio ata» Balzakın romanıdır"],
  1, None, 3),
 ("Dünya və cənub ədəbiyyatı üzrə «əsər - janr» cütlüyü hansı doğrudur?",
  "«Heydərbabaya salam» poema, «Hamlet» faciə janrındadır.",
  ["«Heydərbabaya salam» - poema", "«Balaca qara balıq» - poema",
   "«Hamlet» - roman", "«Qorio ata» - faciə"], 1, None, 3),
 ("Şəhriyarın doğum ili ilə «Heydərbabaya salam»ın yazılma ili arasında "
  "neçə il var?",
  "Şair 1906-cı ildə doğulub, poemanın birinci hissəsi 1954-cü ildə yazılıb.",
  ["48 il", "28 il", "38 il", "58 il"], 1, None, 3),
 ("Səməd Behrənginin nağıllarının uşaq ədəbiyyatından artıq məna "
  "daşımasının səbəbi nədir?",
  "O, nağıl dilindən istifadə edərək ictimai fikir ifadə edirdi.",
  ["Nağıl dilində ictimai fikir ifadə etməsi",
   "Uzun süjet qurulusuna malik olması",
   "Xarici dildən tərcümə edilməsi", "Şeirlə yazılmış olması"],
  1, None, 3),
 ("Şəhriyar və Səhəndin əsərləri haqqında hansı fikir doğrudur?",
  "Şəhriyar Heydərbaba dağını, Səhənd isə Dədə Qorqud dünyasını qələmə alıb.",
  ["Biri Heydərbabanı, digəri Dədə Qorqudu qələmə alıb",
   "Biri Dədə Qorqudu, digəri Heydərbabanı qələmə alıb",
   "Hər ikisi Dədə Qorqud motivlərinə əsaslanır",
   "Hər ikisi fars dilində yazılıb"], 1, None, 3),
 ("Aşağıdakı «əsər - ədəbiyyat» cütlüklərindən hansı düzgündür?",
  "«Ağ gəmi» qırğız, «Mənim Dağıstanım» isə Dağıstan ədəbiyyatına aiddir.",
  ["«Ağ gəmi» - qırğız ədəbiyyatı", "«Ağ gəmi» - Dağıstan ədəbiyyatı",
   "«Mənim Dağıstanım» - qırğız ədəbiyyatı",
   "«Hamlet» - fransız ədəbiyyatı"], 1, None, 3)],

"edeb-11-nezeriyye": [
 # ---- asan (4)
 ("Ədəbiyyatın üç əsas növü hansılardır?",
  "Ədəbiyyatın növləri lirika, epos və dramdır.",
  ["Lirika, epos, dram", "Roman, hekayə, povest",
   "Qəzəl, qəsidə, rübai", "Nəsr, nəzm, tərcümə"], 1, None, 1),
 ("Rübai neçə misradan ibarətdir?",
  "Rübai dörd misralı şeir formasıdır.",
  ["4", "2", "8", "14"], 1, None, 1),
 ("Sonet neçə misradan ibarətdir?",
  "Sonet on dörd misralı şeir formasıdır.",
  ["14", "4", "8", "20"], 1, None, 1),
 ("Bənzətmə (təşbeh) nədir?",
  "İki əşya və ya hadisənin oxşar cəhətinə görə tutuşdurulmasıdır.",
  ["İki əşyanın oxşarlığa görə tutuşdurulması",
   "Sözün əks mənada işlənməsi", "Hadisənin böyüdülərək verilməsi",
   "Sətrin təkrarlanması"], 1, None, 1),
 # ---- orta (15)
 ("Metafora nədir?",
  "Sözün oxşarlıq əsasında məcazi mənada işlədilməsidir.",
  ["Sözün məcazi mənada işlədilməsi", "İki misranın qafiyələnməsi",
   "Hadisələrin ardıcıllığı", "Əsərin bölmələrə ayrılması"], 1, None, 2),
 ("Epitet hansı vəzifəni daşıyır?",
  "Epitet bədii təyin kimi çıxış edir.",
  ["Bədii təyin verir", "Səsləri təkrarlayır", "Süjeti bağlayır",
   "Vəzni müəyyən edir"], 1, None, 2),
 ("Mübaliğə hansı bədii vasitədir?",
  "Mübaliğə şişirtmə vasitəsidir.",
  ["Şişirtmə", "Kiçiltmə", "Səs təkrarı", "Qarşılaşdırma"], 1, None, 2),
 ("Azərbaycan klassik şeirində hansı vəzn əsas olmuşdur?",
  "Klassik şeirdə əruz vəzni əsas olmuşdur.",
  ["Əruz vəzni", "Heca vəzni", "Sərbəst şeir", "Ağ şeir"], 1, None, 2),
 ("Xalq şeirində hansı vəzn işlənir?",
  "Xalq şeiri heca vəznində qurulur.",
  ["Heca vəzni", "Əruz vəzni", "Sərbəst şeir", "Sonet forması"],
  1, None, 2),
 ("Süjetin hansı elementi hadisələrin ən gərgin anıdır?",
  "Ən gərgin an kulminasiya adlanır.",
  ["Kulminasiya", "Ekspozisiya", "Düyün", "Sonluq"], 1, None, 2),
 ("Ekspozisiya süjetin hansı hissəsidir?",
  "Ekspozisiya şəraitin və obrazların tanıdıldığı başlanğıcdır.",
  ["Şəraitin tanıdıldığı başlanğıc", "Ən gərgin an",
   "Münaqişənin həlli", "Əsərin sonluğu"], 1, None, 2),
 ("Realizm cərəyanı nəyi əsas götürür?",
  "Realizm həyatın olduğu kimi, gerçək təsvirini əsas götürür.",
  ["Həyatın olduğu kimi təsvirini", "Xəyali aləmin qurulmasını",
   "Qədim miflərin bərpasını", "Dini rəvayətlərin şərhini"], 1, None, 2),
 ("Romantizm cərəyanının səciyyəvi cəhəti nədir?",
  "İdeal aləmə, güclü hisslərə və xəyala üstünlük verilməsidir.",
  ["İdeal aləmə və güclü hisslərə üstünlük", "Statistik dəqiqlik",
   "Sənədli təsvir", "Quru elmi şərh"], 1, None, 2),
 ("Lirik qəhrəman anlayışı nəyi bildirir?",
  "Şeirdə duyğu və düşüncələri ifadə olunan obrazı bildirir.",
  ["Şeirdə duyğuları ifadə olunan obrazı", "Romanın baş qəhrəmanını",
   "Dramın quruluşçu rejissorunu", "Nağılın söyləyicisini"], 1, None, 2),
 ("Qafiyə nədir?",
  "Misra sonlarındakı səs uyğunluğudur.",
  ["Misra sonlarındakı səs uyğunluğu", "Misradakı heca sayı",
   "Şeirin mövzusu", "Bəndlərin sayı"], 1, None, 2),
 ("Rədif nədir?",
  "Qafiyədən sonra eyni şəkildə təkrarlanan sözdür.",
  ["Qafiyədən sonra təkrarlanan söz", "Misradakı vurğulu heca",
   "Bəndin ilk misrası", "Şeirin adı"], 1, None, 2),
 ("Poema hansı əlamətinə görə adi lirik şeirdən fərqlənir?",
  "Poema həcmli olur və süjet üzərində qurulur.",
  ["Həcmli və süjetli olması", "Qafiyəsiz olması",
   "Nəsrlə yazılması", "Səhnə üçün yazılması"], 1, None, 2),
 ("Faciə dram növünün hansı formasıdır?",
  "Kəskin münaqişənin qəhrəmanın həlakı ilə bitdiyi formadır.",
  ["Qəhrəmanın həlakı ilə bitən forma", "Gülüş doğuran forma",
   "Musiqi ilə müşayiət olunan forma", "Nağıl üstündə qurulan forma"],
  1, None, 2),
 ("Ədəbi əsərdə ideya nəyi bildirir?",
  "Müəllifin əsərdə irəli sürdüyü əsas fikri bildirir.",
  ["Müəllifin irəli sürdüyü əsas fikri", "Hadisələrin sırasını",
   "Obrazların sayını", "Əsərin həcmini"], 1, None, 2),
 # ---- cetin (12)
 ("Ədəbi cərəyanlar tarixi ardıcıllıqla necə düzülür? "
  "(1 - romantizm, 2 - klassisizm, 3 - realizm)",
  "Klassisizm daha erkən, sonra romantizm, ardınca realizm formalaşmışdır.",
  ["2 - 1 - 3", "1 - 2 - 3", "3 - 2 - 1", "2 - 3 - 1"], 1, None, 3),
 ("Aşağıdakı «termin - tərif» cütlüklərindən hansı düzgündür?",
  "Rədif qafiyədən sonra təkrarlanan sözdür.",
  ["Rədif - təkrarlanan söz", "Qafiyə - heca sayı",
   "Vəzn - misra sonundakı uyğunluq", "Bənd - şeirin mövzusu"],
  1, None, 3),
 ("Şeir formaları haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "Sonet səkkiz deyil, on dörd misradan ibarətdir.",
  ["Sonet səkkiz misradan ibarətdir", "Rübai dörd misradan ibarətdir",
   "Qəzəl klassik lirik janrdır", "Poema süjetli şeir əsəridir"],
  1, None, 3),
 ("Epitet ilə metafora arasındakı əsas fərq nədir?",
  "Epitet bədii təyin yaradır, metafora isə məcazi məna qurur.",
  ["Epitet bədii təyin, metafora məcaz yaradır",
   "Epitet məcaz, metafora bədii təyin yaradır",
   "Hər ikisi eyni vəzifəni daşıyır",
   "Epitet vəznlə, metafora qafiyə ilə bağlıdır"], 1, None, 3),
 ("Ədəbi janrlar üzrə «əsər - janr» cütlüklərindən hansı doğrudur?",
  "«Leyli və Məcnun» poema, «Hophopnamə» isə şeirlər toplusudur.",
  ["«Leyli və Məcnun» - poema", "«Leyli və Məcnun» - dram",
   "«Hophopnamə» - roman", "«Vaqif» - poema"], 1, None, 3),
 ("Sərbəst şeiri ənənəvi şeirdən fərqləndirən əsas cəhət hansıdır?",
  "Sərbəst şeirdə sabit vəzn və qafiyə qəlibi gözlənilmir.",
  ["Sabit vəzn və qafiyə qəlibinin gözlənilməməsi",
   "Misra sayının məhdudlaşdırılması",
   "Bəndlərin bərabər bölünməsi", "Klassik bəhrlərə əsaslanması"],
  1, None, 3),
 ("Vəznlər haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?",
  "Uzun və qısa hecalara əsaslanan əruzdur, heca vəzni deyil.",
  ["Heca vəzni hecaların uzunluğuna əsaslanır",
   "Əruz vəznində hecaların uzunluğu əsasdır",
   "Heca vəznində heca sayı əsasdır",
   "Sərbəst şeirdə sabit vəzn gözlənilmir"], 1, None, 3),
 ("Aşağıdakı «cərəyan - səciyyəvi cəhət» cütlüklərindən hansı düzgündür?",
  "Realizm həyatı olduğu kimi, romantizm isə ideal aləmi təsvir edir.",
  ["Realizm - həyatın olduğu kimi təsviri",
   "Romantizm - həyatın olduğu kimi təsviri",
   "Realizm - ideal aləmə üstünlük",
   "Klassisizm - sərbəst formaya üstünlük"], 1, None, 3),
 ("Poema ilə roman arasındakı əsas fərq nədir?",
  "Poema nəzmlə, roman isə nəsrlə yazılır.",
  ["Biri nəzmlə, digəri nəsrlə yazılır",
   "Biri nəsrlə, digəri nəzmlə yazılır",
   "Hər ikisi səhnə üçün yazılır",
   "Biri lirik, digəri dram növünə aiddir"], 1, None, 3),
 ("Süjet elementləri düzgün ardıcıllıqla necə düzülür? "
  "(1 - ekspozisiya, 2 - kulminasiya, 3 - sonluq)",
  "Əvvəlcə şərait tanıdılır, sonra gərginlik zirvəyə çatır, sonda həll olunur.",
  ["1 - 2 - 3", "2 - 1 - 3", "3 - 1 - 2", "1 - 3 - 2"], 1, None, 3),
 ("Faciə ilə komediya arasındakı əsas fərq nədir?",
  "Faciədə qəhrəman həlak olur, komediya isə gülüş doğurur.",
  ["Faciədə qəhrəman həlak olur, komediyada gülüş doğur",
   "Komediyada qəhrəman həlak olur, faciədə gülüş doğur",
   "Hər ikisi lirik növə aiddir",
   "Faciə nəsrlə, komediya nəzmlə yazılır"], 1, None, 3),
 ("Aşağıdakı «bədii vasitə - nümunə» cütlüklərindən hansı düzgündür?",
  "«Dağ boyda ürək» ifadəsi şişirtmə, yəni mübaliğədir.",
  ["Mübaliğə - dağ boyda ürək", "Epitet - dağ boyda ürək",
   "Mübaliğə - qara gözlər", "Təşbeh - qızıl payız"], 1, None, 3)],
}
SUALLAR.update(HISSE_4)


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
--  56_bank_edebiyyat11.sql : EDEBIYYAT 11 BANKI
--
--  BU FAYL ELLE YAZILMIR - tools/edebiyyat11.py yaradir:
--      python3 tools/edebiyyat11.py
--
--  8 movzu x 31 sual = %d.  Her movzuda 4 asan + 15 orta + 12 cetin.
--  ext_key: edeb11-...
--  ON SERT: 55_movzular_edebiyyat11.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'edebiyyat' and t.slug in
           ('edeb-11-tenqidi-realizm', 'edeb-11-nezeriyye')
     having count(*) = 2) then
    raise exception 'ONCE 55_movzular_edebiyyat11.sql isledilmelidir.';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and q.ext_key like 'edeb11-%%';

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
   where owner_type = 'platform' and ext_key like 'edeb11-%%';
  if n <> %d then
    raise exception 'Edebiyyat 11 suallari: %d gozlenilirdi, %% tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'edeb11-%%'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '%% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'edeb11-%%';
  if k <> 8 then
    raise exception 'movzu sayi 8 deyil: %%', k;
  end if;
  --  Her movzuda en azi 12 cetin sual olmalidir ki, muellim BIR
  --  movzudan 10 sualliq cetin test yiga bilsin
  select count(*) into k from (
    select q.topic_id from public.questions q
     where q.ext_key like 'edeb11-%%' and q.difficulty = 3
     group by q.topic_id having count(*) < 12) z;
  if k > 0 then
    raise exception '%% movzuda 12-den az cetin sual var', k;
  end if;
  raise notice 'Edebiyyat 11 banki: %% sual, 8 movzu (her birinde 12 cetin).', n;
end $$;
""" % (n, ",\n".join(setirler), n, n))
    print("yazildi: %s" % CIXIS)


if __name__ == "__main__":
    ok, n = yoxla()
    if not ok:
        raise SystemExit(1)
    sql_yaz(n)
