#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Riyaziyyat 8 platforma banki -> db/38_bank_riy8.sql

tools/riy7.py qelibi ile: 11 movzu x 10 sual = 110, her riyazi cavab
YENIDEN HESABLANIB duzgun variantla tutusdurulur (kvadrat kokler
math.isqrt, Pifaqor ucluklari yoxlanilir, ehtimallar Fraction ile).
Movzular 37_movzular_orta8.sql agacina uygundur (e-derslik
Riyaziyyat 8, kitab 393).

riy3-riy7 fayllarinin reqemleri tekrarlanmayib.

Isletmek:
    python3 tools/riy8.py
"""
import io
import math
import os
from fractions import Fraction

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CIXIS = os.path.join(KOK, "db", "38_bank_riy8.sql")


def tam(n):
    return str(n).replace("-", "−")


def kesr(f):
    f = Fraction(f)
    if f.denominator == 1:
        return tam(f.numerator)
    return "%d/%d" % (f.numerator, f.denominator)


RUBLAR = {
    "riy-8-kvadrat-kok": 1, "riy-8-pifaqor": 1,
    "riy-8-kvadrat-tenlik": 2, "riy-8-dordbucaqlilar": 2,
    "riy-8-rasional-ifade": 2, "riy-8-sahe": 3,
    "riy-8-rasional-tenlik": 3, "riy-8-oxsarliq": 3,
    "riy-8-berabersizlik": 4, "riy-8-triqonometrik": 4,
    "riy-8-ehtimal": 4,
}

SUALLAR = {
"riy-8-kvadrat-kok": [
 ("√49 neçəyə bərabərdir?",
  "7² = 49, deməli √49 = 7.",
  ["7", "9", "24,5", "49"], 1, str(math.isqrt(49)), 1),
 ("√81 + √16 cəmini tapın.",
  "9 + 4 = 13.",
  ["13", "12", "97", "5"], 1,
  str(math.isqrt(81) + math.isqrt(16)), 2),
 ("Hansı ədəd irrasional ədəddir?",
  "√2 sonsuz dövrsüz onluq kəsrdir — irrasionaldır.",
  ["√2", "0,5", "3/4", "7"], 1, None, 3),
 ("121 ədədinin kvadrat kökü neçədir?",
  "11² = 121.",
  ["11", "12", "60,5", "21"], 1, str(math.isqrt(121)), 2),
 ("(√5)² neçəyə bərabərdir?",
  "Kökün kvadratı kökaltı ifadəyə bərabərdir: 5.",
  ["5", "25", "10", "2,5"], 1, str(5), 2),
 ("√18 ifadəsini sadələşdirin.",
  "√18 = √(9·2) = 3√2.",
  ["3√2", "9√2", "2√3", "6√3"], 1, None, 3),
 ("√a · √b nəyə bərabərdir? (a, b ≥ 0)",
  "Köklərin hasili hasilin kökünə bərabərdir: √(ab).",
  ["√(a·b)", "√(a+b)", "a·b", "√a + √b"], 1, None, 3),
 ("Həqiqi ədədlər çoxluğuna hansı ədədlər daxildir?",
  "Rasional və irrasional ədədlərin birliyi.",
  ["Rasional və irrasional ədədlər", "Yalnız natural ədədlər",
   "Yalnız kəsrlər", "Yalnız mənfi ədədlər"], 1, None, 2),
 ("√36 · √25 hasilini tapın.",
  "6 · 5 = 30.",
  ["30", "61", "11", "900"], 1,
  str(math.isqrt(36) * math.isqrt(25)), 2),
 ("x² = 64 tənliyinin müsbət kökü neçədir?",
  "8² = 64, müsbət kök 8-dir.",
  ["8", "32", "16", "4"], 1, str(math.isqrt(64)), 2),
],
"riy-8-pifaqor": [
 ("Pifaqor teoremi hansı üçbucağa tətbiq olunur?",
  "Teorem düzbucaqlı üçbucaq üçündür.",
  ["Düzbucaqlı üçbucağa", "İstənilən üçbucağa",
   "Yalnız bərabərtərəfliyə", "Dördbucaqlıya"], 1, None, 2),
 ("Pifaqor teoreminin düsturu hansıdır?",
  "Hipotenuzun kvadratı katetlərin kvadratları cəminə bərabərdir.",
  ["c² = a² + b²", "c = a + b", "c² = a² − b²",
   "c = a · b"], 1, None, 2),
 ("Katetlər 3 və 4 olarsa, hipotenuz neçədir?",
  "√(9 + 16) = √25 = 5.",
  ["5", "7", "12", "25"], 1,
  str(math.isqrt(3 ** 2 + 4 ** 2)), 2),
 ("Katetlər 5 və 12 olarsa, hipotenuzu tapın.",
  "√(25 + 144) = √169 = 13.",
  ["13", "17", "60", "169"], 1,
  str(math.isqrt(5 ** 2 + 12 ** 2)), 2),
 ("Hipotenuz 13, katetlərdən biri 5-dirsə, o biri kateti tapın.",
  "√(169 − 25) = √144 = 12.",
  ["12", "8", "18", "144"], 1,
  str(math.isqrt(13 ** 2 - 5 ** 2)), 3),
 ("Hipotenuz üçbucağın hansı tərəfidir?",
  "Düz bucağın qarşısındakı ən böyük tərəfdir.",
  ["Düz bucaq qarşısındakı tərəf", "Ən kiçik tərəf",
   "İstənilən tərəf", "Hündürlük"], 1, None, 2),
 ("Tərəfləri 7, 24 və 25 olan üçbucaq düzbucaqlıdırmı?",
  "7² + 24² = 49 + 576 = 625 = 25² — bəli.",
  ["Bəli", "Xeyr", "Yalnız bərabəryanlıdırsa",
   "Müəyyən etmək olmaz"], 1,
  ("Bəli" if 7 ** 2 + 24 ** 2 == 25 ** 2 else "Xeyr"), 3),
 ("Kvadratın diaqonalı tərəfindən neçə dəfə böyükdür?",
  "d = a√2 — √2 dəfə böyükdür.",
  ["√2 dəfə", "2 dəfə", "4 dəfə", "Bərabərdir"], 1, None, 3),
 ("Katetləri a olan bərabəryanlı düzbucaqlı üçbucağın hipotenuzu "
  "nəyə bərabərdir?",
  "c = √(a² + a²) = a√2.",
  ["a√2", "2a", "a²", "a/2"], 1, None, 3),
 ("Düzbucaqlının tərəfləri 9 və 12-dirsə, diaqonalı neçədir?",
  "√(81 + 144) = √225 = 15.",
  ["15", "21", "13", "225"], 1,
  str(math.isqrt(9 ** 2 + 12 ** 2)), 3),
],
"riy-8-kvadrat-tenlik": [
 ("Kvadrat tənliyin ümumi şəkli hansıdır?",
  "ax² + bx + c = 0 (a ≠ 0).",
  ["ax² + bx + c = 0", "ax + b = 0", "a/x = b",
   "ax³ = 0"], 1, None, 2),
 ("x² − 9 = 0 tənliyinin kökləri hansılardır?",
  "x² = 9; x = 3 və x = −3.",
  ["3 və −3", "Yalnız 3", "9 və −9", "Kökü yoxdur"],
  1, None, 2),
 ("Diskriminant hansı düsturla hesablanır?",
  "D = b² − 4ac.",
  ["D = b² − 4ac", "D = b² + 4ac", "D = 2a − b",
   "D = a² − c²"], 1, None, 2),
 ("D < 0 olduqda kvadrat tənliyin neçə həqiqi kökü var?",
  "Mənfi diskriminantda həqiqi kök yoxdur.",
  ["Həqiqi kökü yoxdur", "Bir kökü var", "İki kökü var",
   "Sonsuz kökü var"], 1, None, 3),
 ("x² − 5x + 6 = 0 tənliyinin kökləri hansılardır?",
  "Vietaya görə: cəm 5, hasil 6 — köklər 2 və 3.",
  ["2 və 3", "1 və 6", "−2 və −3", "5 və 6"], 1,
  ("2 və 3" if 2 + 3 == 5 and 2 * 3 == 6 else ""), 3),
 ("x² + 4x = 0 tənliyini həll edin.",
  "x(x + 4) = 0; x = 0 və x = −4.",
  ["0 və −4", "Yalnız −4", "0 və 4", "2 və −2"], 1, None, 3),
 ("D = 0 olduqda tənliyin neçə kökü olur?",
  "Bir (ikiqat) kök olur.",
  ["Bir (ikiqat) kök", "İki müxtəlif kök", "Kök olmur",
   "Üç kök"], 1, None, 3),
 ("x² + px + q = 0 tənliyində köklərin cəmi nəyə bərabərdir?",
  "Viet teoreminə görə cəm −p-yə bərabərdir.",
  ["−p", "p", "q", "−q"], 1, None, 3),
 ("x² = 11x tənliyinin sıfırdan fərqli kökü neçədir?",
  "x(x − 11) = 0; sıfırdan fərqli kök 11-dir.",
  ["11", "−11", "121", "1"], 1, str(11), 3),
 ("2x² − 8 = 0 tənliyinin müsbət kökü neçədir?",
  "x² = 4; müsbət kök 2.",
  ["2", "4", "8", "16"], 1, str(math.isqrt(8 // 2)), 2),
],
"riy-8-dordbucaqlilar": [
 ("Paraleloqramın qarşı tərəfləri necədir?",
  "Qarşı tərəflər paralel və bərabərdir.",
  ["Paralel və bərabərdir", "Perpendikulyar",
   "Həmişə fərqlidir", "Kəsişir"], 1, None, 2),
 ("Rombun bütün tərəfləri haqqında nə demək olar?",
  "Rombda bütün tərəflər bərabərdir.",
  ["Bərabərdir", "Fərqlidir", "Paralel deyil",
   "Ölçüsüzdür"], 1, None, 2),
 ("Dördbucaqlının daxili bucaqlarının cəmi neçədir?",
  "Dördbucaqlıda bucaqların cəmi 360°-dir.",
  ["360°", "180°", "90°", "540°"], 1, None, 2),
 ("Paraleloqramın diaqonalları kəsişmə nöqtəsində nə edir?",
  "Diaqonallar yarıya bölünür.",
  ["Yarıya bölünür", "Perpendikulyar olur", "Kəsişmir",
   "Bərabərləşir"], 1, None, 3),
 ("Rombun diaqonalları bir-birinə necədir?",
  "Diaqonallar perpendikulyardır və yarıya bölünür.",
  ["Perpendikulyardır", "Paraleldir", "Bərabərdir həmişə",
   "Kəsişmir"], 1, None, 3),
 ("Trapesiyanın hansı tərəfləri paraleldir?",
  "Oturacaqları paraleldir.",
  ["Oturacaqları", "Yan tərəfləri", "Bütün tərəfləri",
   "Heç biri"], 1, None, 2),
 ("Kvadrat hansı fiqurların xüsusi halıdır?",
  "Kvadrat həm düzbucaqlı, həm də rombdur.",
  ["Düzbucaqlının və rombun", "Yalnız trapesiyanın",
   "Yalnız üçbucağın", "Dairənin"], 1, None, 3),
 ("Düzbucaqlının diaqonalları haqqında nə demək olar?",
  "Düzbucaqlının diaqonalları bərabərdir.",
  ["Bərabərdirlər", "Perpendikulyardırlar həmişə",
   "Kəsişmirlər", "Tərəfə bərabərdirlər"], 1, None, 3),
 ("Trapesiyanın orta xətti nəyə bərabərdir?",
  "Oturacaqların cəminin yarısına.",
  ["Oturacaqlar cəminin yarısına", "Yan tərəflərin cəminə",
   "Hündürlüyə", "Perimetrə"], 1, None, 3),
 ("Paraleloqramın qonşu bucaqlarının cəmi neçədir?",
  "Qonşu bucaqların cəmi 180°-dir.",
  ["180°", "90°", "360°", "60°"], 1, None, 3),
],
"riy-8-rasional-ifade": [
 ("Rasional kəsrin məxrəci hansı qiyməti ala bilməz?",
  "Məxrəc sıfır ola bilməz.",
  ["Sıfır", "Bir", "Mənfi ədəd", "Kəsr"], 1, None, 2),
 ("x/(x − 3) ifadəsi x-in hansı qiymətində mənasızdır?",
  "x = 3 olduqda məxrəc sıfırdır.",
  ["x = 3", "x = 0", "x = −3", "Həmişə mənalıdır"], 1, None, 2),
 ("(a²)³ neçə olar?",
  "Qüvvətin qüvvəti: üstlər vurulur — a⁶.",
  ["a⁶", "a⁵", "a⁸", "a⁹"], 1, "a⁶", 3),
 ("6x² : (2x) ifadəsini sadələşdirin.",
  "6 : 2 = 3; x² : x = x — nəticə 3x.",
  ["3x", "3x²", "4x", "12x"], 1, "%dx" % (6 // 2), 2),
 ("1/a + 1/b cəmi nəyə bərabərdir?",
  "Ortaq məxrəc ab: (a + b)/(ab).",
  ["(a + b)/(ab)", "2/(a + b)", "1/(a + b)", "(a·b)/(a+b)"],
  1, None, 3),
 ("Kəsri ixtisar etmək nə deməkdir?",
  "Surət və məxrəci eyni ifadəyə bölmək.",
  ["Surət və məxrəci eyni ifadəyə bölmək",
   "Kəsri silmək", "Məxrəci atmaq", "Kəsri çevirmək"],
  1, None, 2),
 ("(x² − 4)/(x − 2) ifadəsini sadələşdirin (x ≠ 2).",
  "x² − 4 = (x − 2)(x + 2); nəticə x + 2.",
  ["x + 2", "x − 2", "x + 4", "x² − 2"], 1, None, 3),
 ("a⁰ nəyə bərabərdir? (a ≠ 0)",
  "Sıfırıncı qüvvət 1-ə bərabərdir.",
  ["1", "0", "a", "−1"], 1, str(1), 2),
 ("Mənfi qüvvət qaydasına görə a⁻¹ necə yazılır?",
  "Mənfi birinci qüvvət tərs ədəddir: 1/a.",
  ["1/a", "−a", "a", "0"], 1, None, 3),
 ("(2x)³ neçə olar?",
  "2³ · x³ = 8x³.",
  ["8x³", "6x³", "2x³", "8x"], 1, "%dx³" % (2 ** 3), 3),
],
"riy-8-sahe": [
 ("Rombun diaqonalları 14 və 4 olarsa, sahəsi neçədir?",
  "S = (14 · 4) : 2 = 28.",
  ["28", "56", "18", "112"], 1, str(14 * 4 // 2), 3),
 ("Tərəfi 9 sm olan kvadratın sahəsi neçədir?",
  "S = 9² = 81 sm².",
  ["81 sm²", "36 sm²", "18 sm²", "27 sm²"], 1,
  "%d sm²" % (9 ** 2), 2),
 ("Üçbucağın sahə düsturu hansıdır?",
  "S = (oturacaq · hündürlük) : 2.",
  ["S = (a · h) : 2", "S = a · h", "S = a + h",
   "S = 2(a + h)"], 1, None, 2),
 ("Paraleloqramın oturacağı 7, hündürlüyü 8 olarsa, sahəsi "
  "neçədir?",
  "S = 7 · 8 = 56.",
  ["56", "28", "15", "30"], 1, str(7 * 8), 2),
 ("Oturacaqları 5 və 9, hündürlüyü 6 olan trapesiyanın sahəsini "
  "tapın.",
  "S = (5 + 9) : 2 · 6 = 42.",
  ["42", "84", "20", "70"], 1, str((5 + 9) // 2 * 6), 3),
 ("Katetləri 10 və 7 olan düzbucaqlı üçbucağın sahəsi neçədir?",
  "S = (10 · 7) : 2 = 35.",
  ["35", "70", "17", "34"], 1, str(10 * 7 // 2), 2),
 ("Çevrənin uzunluğu hansı düsturla tapılır?",
  "C = 2πr.",
  ["C = 2πr", "C = πr²", "C = 4πr", "C = r²"],
  1, None, 3),
 ("Dairənin sahəsi hansı düsturla hesablanır?",
  "S = πr².",
  ["S = πr²", "S = 2πr", "S = πd", "S = r³"], 1, None, 3),
 ("Radiusu 10 olan dairənin sahəsi neçə π-dir?",
  "S = π · 10² = 100π.",
  ["100π", "20π", "10π", "1000π"], 1,
  "%dπ" % (10 ** 2), 3),
 ("Fiqur iki hissəyə bölünərsə, sahəsi necə tapılır?",
  "Hissələrin sahələrinin cəmi kimi.",
  ["Hissələrin sahələri cəmi kimi", "Hissələrin fərqi kimi",
   "Böyük hissəyə görə", "Tapılmır"], 1, None, 2),
],
"riy-8-rasional-tenlik": [
 ("Rasional tənlik hansı tənlikdir?",
  "Rasional ifadələrdən ibarət tənlikdir.",
  ["Rasional ifadələrdən ibarət tənlik", "Yalnız kvadrat tənlik",
   "Köklü tənlik", "Bərabərsizlik"], 1, None, 2),
 ("x/(x − 1) = 0 tənliyinin kökü neçədir?",
  "Kəsr sıfırdır — surət sıfır olmalıdır: x = 0.",
  ["0", "1", "−1", "Kökü yoxdur"], 1, str(0), 3),
 ("Rasional tənliyi həll edərkən nəyi yoxlamaq vacibdir?",
  "Məxrəci sıfır edən qiymətlər kök ola bilməz.",
  ["Məxrəci sıfır edən qiymətləri", "Surəti",
   "Tənliyin uzunluğunu", "Heç nəyi"], 1, None, 3),
 ("12/x = 4 tənliyinin kökü neçədir?",
  "x = 12 : 4 = 3.",
  ["3", "48", "8", "4"], 1, str(12 // 4), 2),
 ("(x + 2)/5 = 2 tənliyini həll edin.",
  "x + 2 = 10; x = 8.",
  ["8", "12", "0", "10"], 1, str(2 * 5 - 2), 2),
 ("1/x = 1/9 tənliyinin kökü neçədir?",
  "Kəsrlər bərabərdirsə, məxrəclər bərabərdir: x = 9.",
  ["9", "1/9", "−9", "3"], 1, str(9), 2),
 ("Kənar kök nədir?",
  "Çevirmələr zamanı alınan, lakin tənliyi ödəməyən kökdür.",
  ["Tənliyi ödəməyən alınmış kök", "Ən böyük kök",
   "Mənfi kök", "İlk tapılan kök"], 1, None, 3),
 ("x/2 + x/3 = 5 tənliyinin kökü neçədir?",
  "Ortaq məxrəc 6: 3x + 2x = 30; x = 6.",
  ["6", "5", "30", "12"], 1, str(30 // 5), 3),
 ("20/x = x/5 tənliyinin müsbət kökü neçədir?",
  "x² = 100; müsbət kök 10.",
  ["10", "100", "4", "25"], 1, str(math.isqrt(20 * 5)), 3),
 ("Tənliyin iki tərəfini məxrəcə vuranda nə nəzərə alınmalıdır?",
  "Məxrəcin sıfırdan fərqli olması.",
  ["Məxrəcin sıfır olmaması", "Surətin böyüklüyü",
   "Kökün işarəsi", "Heç nə"], 1, None, 3),
],
"riy-8-oxsarliq": [
 ("Oxşar fiqurlar necə fiqurlardır?",
  "Formaca eyni, ölçüləri mütənasib fiqurlardır.",
  ["Formaca eyni, ölçücə mütənasib", "Tamamilə eyni",
   "Sahəcə bərabər", "Həmişə konqruyent"], 1, None, 2),
 ("Oxşarlıq əmsalı nədir?",
  "Uyğun tərəflərin nisbətidir.",
  ["Uyğun tərəflərin nisbəti", "Bucaqların cəmi",
   "Sahələrin fərqi", "Perimetrlərin hasili"], 1, None, 3),
 ("Oxşar üçbucaqların uyğun bucaqları necədir?",
  "Uyğun bucaqlar bərabərdir.",
  ["Bərabərdir", "Mütənasibdir", "Fərqlidir",
   "Cəmi 90°-dir"], 1, None, 2),
 ("Oxşarlıq əmsalı 3 olarsa, sahələrin nisbəti neçədir?",
  "Sahələr k² kimi nisbətdədir: 9.",
  ["9", "3", "6", "27"], 1, str(3 ** 2), 3),
 ("Üçbucaqların oxşarlıq əlamətlərindən biri hansıdır?",
  "İki bucağa görə oxşarlıq.",
  ["İki bucağa görə", "Perimetrə görə", "Sahəyə görə",
   "Rəngə görə"], 1, None, 3),
 ("Xəritə oxşarlığın hansı tətbiqidir?",
  "Ərazinin kiçildilmiş oxşar təsviridir.",
  ["Ərazinin kiçildilmiş oxşarı", "Böyüdülmüş şəkil",
   "Təsadüfi çertyoj", "Oxşarlıqla bağlı deyil"], 1, None, 3),
 ("Tərəfləri 2 dəfə böyüdülən kvadratın sahəsi neçə dəfə artar?",
  "Sahə k² dəfə artır: 4 dəfə.",
  ["4", "2", "8", "16"], 1, str(2 ** 2), 3),
 ("Oxşar üçbucaqlarda perimetrlərin nisbəti nəyə bərabərdir?",
  "Oxşarlıq əmsalına bərabərdir.",
  ["Oxşarlıq əmsalına", "Əmsalın kvadratına",
   "Həmişə 1-ə", "Sahələr nisbətinə"], 1, None, 3),
 ("△ABC ~ △DEF və AB/DE = 1/2 olarsa, hansı üçbucaq böyükdür?",
  "AB tərəfi DE-nin yarısıdır — DEF böyükdür.",
  ["DEF", "ABC", "Bərabərdirlər", "Bilmək olmaz"], 1, None, 3),
 ("Gündəlik həyatda oxşar fiqurlara misal hansıdır?",
  "Fotonun müxtəlif ölçülü çapları oxşar fiqurlardır.",
  ["Fotonun böyüdülmüş çapı", "İki fərqli formalı daş",
   "Kvadrat və dairə", "Hərflər"], 1, None, 2),
],
"riy-8-berabersizlik": [
 ("x + 5 > 9 bərabərsizliyinin həlli hansıdır?",
  "x > 9 − 5 = 4.",
  ["x > 4", "x < 4", "x > 14", "x = 4"], 1,
  "x > %d" % (9 - 5), 2),
 ("Bərabərsizliyin iki tərəfi mənfi ədədə vurulanda nə baş verir?",
  "Bərabərsizlik işarəsi əksinə dəyişir.",
  ["İşarə əksinə dəyişir", "İşarə dəyişmir",
   "Bərabərlik alınır", "Həll itir"], 1, None, 3),
 ("2x < 10 bərabərsizliyini həll edin.",
  "x < 10 : 2 = 5.",
  ["x < 5", "x > 5", "x < 20", "x = 5"], 1,
  "x < %d" % (10 // 2), 2),
 ("−3x > 12 bərabərsizliyinin həlli hansıdır?",
  "Mənfiyə bölərkən işarə dəyişir: x < −4.",
  ["x < −4", "x > −4", "x < 4", "x > 4"], 1,
  "x < %s" % tam(12 // -3), 3),
 ("x ≥ 2 həlləri ədəd oxunda necə göstərilir?",
  "2 nöqtəsi daxil olmaqla sağa yönəlmiş şüa.",
  ["2-dən sağa şüa (2 daxil)", "2-dən sola şüa",
   "Yalnız 2 nöqtəsi", "Bütün ox"], 1, None, 3),
 ("1 < x < 7 bərabərsizliyini ödəyən ən böyük tam ədəd neçədir?",
  "7-dən kiçik ən böyük tam ədəd 6-dır.",
  ["6", "7", "5", "1"], 1,
  str(max(n for n in range(-10, 10) if 1 < n < 7)), 2),
 ("a > b və b > c olarsa, a ilə c arasında hansı münasibət var?",
  "Tranzitivlik: a > c.",
  ["a > c", "a < c", "a = c", "Münasibət yoxdur"],
  1, None, 2),
 ("x − 7 ≤ 0 bərabərsizliyinin həlli hansıdır?",
  "x ≤ 7.",
  ["x ≤ 7", "x ≥ 7", "x < 0", "x = 7"], 1, None, 2),
 ("Bərabərsizliyin iki tərəfinə eyni ədəd əlavə edəndə işarə "
  "dəyişirmi?",
  "Xeyr — toplama işarəni dəyişmir.",
  ["Xeyr, dəyişmir", "Bəli, həmişə dəyişir",
   "Yalnız mənfidə dəyişir", "Bərabərlik olur"], 1, None, 2),
 ("5 − x > 1 bərabərsizliyini həll edin.",
  "−x > −4; işarə dəyişir: x < 4.",
  ["x < 4", "x > 4", "x < −4", "x > 6"], 1, None, 3),
],
"riy-8-triqonometrik": [
 ("Düzbucaqlı üçbucaqda bucağın sinusu nəyin nisbətidir?",
  "Qarşı katetin hipotenuza nisbətidir.",
  ["Qarşı katetin hipotenuza", "Bitişik katetin hipotenuza",
   "Hipotenuzun katetə", "Katetlərin bir-birinə"],
  1, None, 3),
 ("Kosinus hansı nisbətdir?",
  "Bitişik katetin hipotenuza nisbətidir.",
  ["Bitişik katetin hipotenuza", "Qarşı katetin hipotenuza",
   "Hipotenuzun katetə", "Bucağın tərəfə"], 1, None, 3),
 ("Tangens nəyə bərabərdir?",
  "Qarşı katetin bitişik katetə nisbətinə.",
  ["Qarşı katetin bitişik katetə nisbətinə",
   "Katetin hipotenuza nisbətinə", "Hipotenuzun yarısına",
   "Bucaqların cəminə"], 1, None, 3),
 ("sin 30° neçəyə bərabərdir?",
  "sin 30° = 1/2.",
  ["1/2", "√3/2", "1", "√2/2"], 1, None, 3),
 ("cos 60° neçəyə bərabərdir?",
  "cos 60° = 1/2.",
  ["1/2", "√3/2", "0", "2"], 1, None, 3),
 ("tan 45° neçəyə bərabərdir?",
  "45°-də katetlər bərabərdir: tan 45° = 1.",
  ["1", "1/2", "√2", "0"], 1, None, 3),
 ("1 − sin²α ifadəsi nəyə bərabərdir?",
  "Əsas eynilikdən: 1 − sin²α = cos²α.",
  ["cos²α", "sin²α", "tan²α", "0"], 1, None, 3),
 ("Koordinat başlanğıcından A(6; 8) nöqtəsinə qədər məsafə "
  "neçədir?",
  "√(36 + 64) = √100 = 10.",
  ["10", "14", "48", "100"], 1,
  str(math.isqrt(6 ** 2 + 8 ** 2)), 3),
 ("Paralel köçürmə zamanı fiqurun nəyi dəyişmir?",
  "Forması və ölçüləri dəyişmir, yalnız yeri dəyişir.",
  ["Forması və ölçüləri", "Yeri", "Hər şeyi dəyişir",
   "Yalnız rəngi"], 1, None, 3),
 ("Ox simmetriyasında (inikasda) fiqur necə alınır?",
  "Fiqurun güzgü əksi alınır, ölçülər saxlanır.",
  ["Güzgü əksi alınır", "Fiqur böyüyür", "Fiqur kiçilir",
   "Fiqur itir"], 1, None, 3),
],
"riy-8-ehtimal": [
 ("Zər atılanda 6 düşməsi ehtimalı neçədir?",
  "Altı üzdən biri: 1/6.",
  ["1/6", "1/2", "6", "1/3"], 1, kesr(Fraction(1, 6)), 2),
 ("Kartlar 1-dən 10-a qədər nömrələnib. Təsadüfi kartın 10-a "
  "bölünən olması ehtimalı neçədir?",
  "Yalnız 10 uyğundur: 1/10.",
  ["1/10", "1/5", "10", "1/2"], 1, kesr(Fraction(1, 10)), 3),
 ("Qutuda 3 ağ və 7 qara kürə var. Ağ kürə çıxarma ehtimalı "
  "neçədir?",
  "3/10.",
  ["3/10", "7/10", "3/7", "1/3"], 1, kesr(Fraction(3, 10)), 3),
 ("Statistik sıranın amplitudu nədir?",
  "Ən böyük qiymətlə ən kiçiyin fərqidir.",
  ["Ən böyüklə ən kiçiyin fərqi", "Qiymətlərin cəmi",
   "Orta qiymət", "Ən çox təkrarlanan"], 1, None, 3),
 ("7, 2, 9, 4 sırasının amplitudu neçədir?",
  "9 − 2 = 7.",
  ["7", "9", "2", "22"], 1,
  str(max(7, 2, 9, 4) - min(7, 2, 9, 4)), 3),
 ("Nisbi tezlik necə tapılır?",
  "Hadisənin baş vermə sayı bütün təcrübələrin sayına bölünür.",
  ["Hadisə sayı təcrübə sayına bölünür",
   "Təcrübə sayı vurulur", "Cəm alınır", "Fərq alınır"],
  1, None, 3),
 ("Zərdə 3-ə bölünən ədəd düşməsi ehtimalı neçədir?",
  "Uyğun hallar: 3 və 6 — 2/6 = 1/3.",
  ["1/3", "1/2", "1/6", "2/3"], 1, kesr(Fraction(2, 6)), 3),
 ("100 lotereya biletindən 5-i uduşludur. Uduş ehtimalı neçədir?",
  "5/100 = 1/20.",
  ["1/20", "1/5", "5", "1/100"], 1,
  kesr(Fraction(5, 100)), 3),
 ("Bütün mümkün nəticələrin ehtimallarının cəmi nəyə bərabərdir?",
  "Cəm həmişə vahidə (1-ə) bərabərdir.",
  ["Vahidə (1-ə)", "Sıfıra", "Yüzə", "Nəticədən asılıdır"],
  1, None, 3),
 ("İki zər atılanda düşən ədədlərin cəmi ən çoxu neçə ola bilər?",
  "6 + 6 = 12.",
  ["12", "6", "36", "11"], 1, str(6 + 6), 2),
],
}


def yoxla():
    n = xeta = 0
    butun = set()
    for movzu, siyahi in SUALLAR.items():
        assert movzu in RUBLAR, movzu
        if len(siyahi) != 10:
            print("XETA  %s: %d sual (10 olmalidir)" % (movzu, len(siyahi)))
            xeta += 1
        for body, why, opts, correct, expect, diff in siyahi:
            n += 1
            p = []
            if len(opts) != 4: p.append("variant sayi %d" % len(opts))
            if len(set(opts)) != len(opts): p.append("tekrar variant")
            if not (1 <= correct <= 4): p.append("correct")
            if not why: p.append("izah bos")
            if diff not in (1, 2, 3): p.append("cetinlik")
            if body in butun: p.append("eyni sual iki defe")
            butun.add(body)
            if expect is not None and opts[correct - 1] != expect:
                p.append("hesablanan «%s» != variant «%s»" % (expect, opts[correct - 1]))
            for t in [body, why] + opts:
                if "'" in t: p.append("apostrof var")
            if p:
                xeta += 1
                print("XETA  %s: %s\n      %s" % (movzu, body[:60], "; ".join(p)))
    hes = sum(1 for s in SUALLAR.values() for q in s if q[4] is not None)
    print("%d sual yoxlandı (%d-i hesabla təsdiqləndi), %d xəta" % (n, hes, xeta))
    return xeta == 0, n


def sql_yaz(n):
    q = lambda t: t.replace("'", "''")
    setirler = []
    for movzu in RUBLAR:
        qisa = movzu.replace("riy-8-", "")
        for i, (body, why, opts, correct, _e, diff) in enumerate(SUALLAR[movzu], 1):
            setirler.append(
                "('riy8-%s#%d','%s',%d,%d,'%s','%s',array['%s','%s','%s','%s'],%d)"
                % (qisa, i, movzu, diff, RUBLAR[movzu], q(body), q(why),
                   q(opts[0]), q(opts[1]), q(opts[2]), q(opts[3]), correct))
    with io.open(CIXIS, "w", encoding="utf-8") as f:
        f.write("""-- =====================================================================
--  38_bank_riy8.sql : RIYAZIYYAT 8 PLATFORMA SUAL BANKI (orta mekteb)
--
--  BU FAYL ELLE YAZILMIR - tools/riy8.py yaradir:
--      python3 tools/riy8.py
--
--  11 movzu x 10 sual = %d.  ext_key: riy8-<movzu>#<sira>.
--  ON SERT: 37_movzular_orta8.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (
    select 1 from public.topics t
      join public.subjects s on s.id = t.subject_id
     where s.slug = 'riyaziyyat' and t.slug = 'riy-8-pifaqor') then
    raise exception 'ONCE 37_movzular_orta8.sql isledilmelidir (riy-8-* movzulari yoxdur).';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and q.ext_key like 'riy8-%%';

with d(ext, topic, diff, rub, body, why, opts, correct) as (values
%s
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, d.diff, d.rub, 'published'
    from d
    join public.subjects s on s.slug = 'riyaziyyat'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '8'
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
   where owner_type = 'platform' and ext_key like 'riy8-%%';
  if n <> %d then
    raise exception 'riy8 suallari: %d gozlenilirdi, %% tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'riy8-%%'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '%% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'riy8-%%';
  if k <> 11 then
    raise exception 'movzu sayi 11 deyil: %%', k;
  end if;
  raise notice 'Riyaziyyat 8 banki: %% sual, 11 movzu.', n;
end $$;
""" % (n, ",\n".join(setirler), n, n))
    print("yazildi: %s" % CIXIS)


if __name__ == "__main__":
    ok, n = yoxla()
    if not ok:
        raise SystemExit(1)
    sql_yaz(n)
