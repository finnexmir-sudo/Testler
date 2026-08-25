#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Riyaziyyat 7 platforma banki -> db/34_bank_riy7.sql

tools/riy6.py qelibi ile: 10 movzu x 10 sual = 100, her riyazi cavab
YENIDEN HESABLANIB duzgun variantla tutusdurulur (ehtimallar Fraction,
coxluq emelleri set, coxhedli emsallari Python hesabi ile).
Movzular 33_movzular_orta7.sql agacina uygundur (e-derslik
Riyaziyyat 7, kitab 714).

Menfi ededler «−» (U+2212) ile yazilir.  riy3-riy6 fayllarinin
reqemleri tekrarlanmayib.

Isletmek:
    python3 tools/riy7.py
"""
import io
import os
from fractions import Fraction

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CIXIS = os.path.join(KOK, "db", "34_bank_riy7.sql")


def tam(n):
    return str(n).replace("-", "−")


def dec(x):
    s = ("%.10f" % float(x)).rstrip("0").rstrip(".")
    return s.replace(".", ",").replace("-", "−")


def kesr(f):
    f = Fraction(f)
    if f.denominator == 1:
        return tam(f.numerator)
    if f.numerator < 0:
        return "−%d/%d" % (-f.numerator, f.denominator)
    return "%d/%d" % (f.numerator, f.denominator)


def coxluq(elems):
    return "{%s}" % "; ".join(str(e) for e in sorted(elems))


def fmt(n):
    return format(n, ",").replace(",", " ")


RUBLAR = {
    "riy-7-statistika": 1, "riy-7-rasional": 1,
    "riy-7-paralellik": 2, "riy-7-coxhedliler": 2,
    "riy-7-ucbucaqlar": 3, "riy-7-muxteser": 3, "riy-7-funksiya": 3,
    "riy-7-tenlikler-sistemi": 4, "riy-7-konqruyentlik": 4,
    "riy-7-situasiya": 4,
}

SUALLAR = {
"riy-7-statistika": [
 ("Məlumat toplamağın üsullarından biri hansıdır?",
  "Sorğu (anket) məlumat toplama üsuludur.",
  ["Sorğu", "Yuxu", "Təxmin", "Fal"], 1, None, 1),
 ("Nizamlı zər atılır. 3-dən kiçik ədəd düşməsi ehtimalı neçədir?",
  "Uyğun hallar: 1 və 2 — cəmi 2 hal; 2/6 = 1/3.",
  ["1/3", "1/2", "2/3", "1/6"], 1, kesr(Fraction(2, 6)), 3),
 ("Sinifdə 12 qız və 8 oğlan var. Təsadüfi seçilən şagirdin qız "
  "olması ehtimalı neçədir?",
  "12/20 = 3/5.",
  ["3/5", "2/5", "12/8", "1/2"], 1, kesr(Fraction(12, 20)), 3),
 ("A və B uyuşmayan hadisələrdirsə, «A və ya B» hadisəsinin "
  "ehtimalı necə tapılır?",
  "Uyuşmayan hadisələrin ehtimalları toplanır.",
  ["Ehtimallar toplanır", "Ehtimallar vurulur",
   "Böyüyü götürülür", "Fərqi alınır"], 1, None, 3),
 ("Hadisənin ehtimalı 0,3-dürsə, əks hadisənin ehtimalı neçədir?",
  "1 − 0,3 = 0,7.",
  ["0,7", "0,3", "0,4", "1,3"], 1, dec(1 - 0.3), 2),
 ("Proqnozlaşdırma nəyə əsaslanır?",
  "Toplanmış məlumatların təhlilinə əsaslanır.",
  ["Toplanmış məlumatların təhlilinə", "Təsadüfə",
   "Arzulara", "Heç nəyə"], 1, None, 2),
 ("4, 7, 11, 13, 15 sırasının medianı neçədir?",
  "Beş ədədin ortadakısı: 11.",
  ["11", "7", "10", "13"], 1,
  str(sorted((4, 7, 11, 13, 15))[2]), 2),
 ("Məlumatın qrafik təqdimat formalarından biri hansıdır?",
  "Diaqram məlumatı əyani göstərir.",
  ["Diaqram", "Nağıl", "Şeir", "Mahnı"], 1, None, 1),
 ("Sikkə iki dəfə atılır. Hər ikisində gerb düşməsi ehtimalı "
  "neçədir?",
  "1/2 · 1/2 = 1/4.",
  ["1/4", "1/2", "1/8", "2/4 sadələşmir"], 1,
  kesr(Fraction(1, 2) * Fraction(1, 2)), 3),
 ("10, 20 və 60 ədədlərinin ədədi ortası neçədir?",
  "(10 + 20 + 60) : 3 = 30.",
  ["30", "20", "90", "45"], 1, str((10 + 20 + 60) // 3), 2),
],
"riy-7-rasional": [
 ("Rasional ədəd hansı şəkildə yazıla bilər?",
  "m/n şəklində (m tam, n natural).",
  ["m/n kəsri şəklində", "Yalnız tam ədəd kimi",
   "Yalnız müsbət ədəd kimi", "Yazıla bilməz"], 1, None, 2),
 ("1/3 kəsrinin onluq yazılışı necədir?",
  "1 : 3 = 0,333… = 0,(3) — dövri kəsr.",
  ["0,(3)", "0,3", "0,33", "3,1"], 1, None, 3),
 ("−3,5 və −2,8 ədədlərindən hansı böyükdür?",
  "Mənfilərdə modulu kiçik olan böyükdür: −2,8.",
  ["−2,8", "−3,5", "Bərabərdirlər", "Müqayisə olunmur"], 1,
  dec(max(-3.5, -2.8)), 2),
 ("|−4,2| neçəyə bərabərdir?",
  "Modul mənfi ola bilməz: 4,2.",
  ["4,2", "−4,2", "0", "42"], 1, dec(abs(-4.2)), 2),
 ("−7/2 ədədi ədəd oxunda hansı tam ədədlər arasındadır?",
  "−7/2 = −3,5 — deməli −4 ilə −3 arasındadır.",
  ["−4 və −3", "−3 və −2", "3 və 4", "−7 və −2"], 1, None, 3),
 ("0,4(6) yazılışında mötərizə nəyi bildirir?",
  "6 rəqəminin sonsuz təkrarlandığını (dövrü).",
  ["6-nın dövr etdiyini", "Vurmanı", "Toplamanı",
   "Mənfi işarəni"], 1, None, 2),
 ("−2 < x < 3 ikiqat bərabərsizliyini hansı tam ədəd ödəyir?",
  "1 ədədi −2 ilə 3 arasındadır.",
  ["1", "−3", "4", "5"], 1,
  str([n for n in (1, -3, 4, 5) if -2 < n < 3][0]), 2),
 ("(−0,5) · 8 neçə edər?",
  "0,5 · 8 = 4; işarə mənfi: −4.",
  ["−4", "4", "−40", "−0,4"], 1, dec(-0.5 * 8), 2),
 ("−3/4 + 1/4 neçə edər?",
  "(−3 + 1)/4 = −2/4 = −1/2.",
  ["−1/2", "1/2", "−1", "−4/4"], 1,
  kesr(Fraction(-3, 4) + Fraction(1, 4)), 3),
 ("Toplamanın yerdəyişmə xassəsi nəyi deyir?",
  "a + b = b + a.",
  ["a + b = b + a", "a − b = b − a", "a · b = a + b",
   "a : b = b : a"], 1, None, 1),
],
"riy-7-paralellik": [
 ("İki paralel düz xətti üçüncü xətt kəsdikdə uyğun bucaqlar "
  "necə olur?",
  "Uyğun bucaqlar bərabər olur.",
  ["Bərabər", "Cəmi 90°", "Fərqli", "Cəmi 360°"], 1, None, 2),
 ("Paralel xətləri kəsəndə əmələ gələn birtərəfli daxili bucaqların "
  "cəmi neçədir?",
  "Birtərəfli daxili bucaqların cəmi 180°-dir.",
  ["180°", "90°", "360°", "60°"], 1, None, 3),
 ("Parçanın orta perpendikulyarı nədir?",
  "Parçanın ortasından ona perpendikulyar keçən düz xəttdir.",
  ["Ortadan keçən perpendikulyar düz xətt",
   "Parçanı uzadan xətt", "İstənilən mail", "Diaqonal"],
  1, None, 3),
 ("Nöqtədən düz xəttə qədər ən qısa məsafə hansı xətlə ölçülür?",
  "Ən qısa məsafə perpendikulyar boyuncadır.",
  ["Perpendikulyarla", "Mail ilə", "Əyri ilə",
   "İstənilən xətlə"], 1, None, 2),
 ("Mərkəzi simmetriya nəyə nəzərən simmetriyadır?",
  "Bir nöqtəyə (mərkəzə) nəzərən simmetriyadır.",
  ["Nöqtəyə nəzərən", "Düz xəttə nəzərən",
   "Müstəviyə nəzərən", "Heç nəyə nəzərən"], 1, None, 3),
 ("Bir düz xəttə perpendikulyar olan iki düz xətt bir-birinə "
  "necədir?",
  "Hər ikisi eyni xəttə perpendikulyardırsa, paraleldirlər.",
  ["Paraleldir", "Perpendikulyardır", "Kəsişir",
   "Üst-üstə düşür"], 1, None, 3),
 ("Çarpaz bucaqlar bərabərdirsə, kəsilən iki düz xətt haqqında "
  "nə demək olar?",
  "Bu, paralellik əlamətidir — xətlər paraleldir.",
  ["Paraleldirlər", "Perpendikulyardırlar",
   "Mütləq kəsişirlər", "Heç nə demək olmaz"], 1, None, 3),
 ("Uyğun tərəfləri paralel olan bucaqlar necə olur?",
  "Belə bucaqlar bərabərdir və ya cəmi 180°-dir.",
  ["Bərabər və ya cəmi 180°", "Həmişə 90°",
   "Həmişə fərqli", "Cəmi 100°"], 1, None, 3),
 ("a ∥ b və b ∥ c olarsa, a ilə c necədir?",
  "Paralellik ötürülür: a ∥ c.",
  ["a ∥ c", "a ⊥ c", "Kəsişirlər", "Bilmək olmaz"],
  1, None, 2),
 ("İki kəsişən düz xətt neçə cüt çarpaz bucaq əmələ gətirir?",
  "Kəsişmədə 2 cüt çarpaz bucaq yaranır.",
  ["2", "4", "1", "8"], 1, str(2), 3),
],
"riy-7-coxhedliler": [
 ("3x² · 4x³ hasilini tapın.",
  "Əmsallar vurulur, qüvvətlər toplanır: 12x⁵.",
  ["12x⁵", "7x⁵", "12x⁶", "7x⁶"], 1, "%dx⁵" % (3 * 4), 2),
 ("x² · x⁵ neçə olar?",
  "Eyni əsaslı qüvvətlər vurulanda üstlər toplanır: x⁷.",
  ["x⁷", "x¹⁰", "x³", "2x⁷"], 1, "x⁷", 2),
 ("Hansı ifadə birhədlidir?",
  "5xy — ədəd və dəyişənlərin hasilidir.",
  ["5xy", "x + y", "x − 1", "2x + 3"], 1, None, 2),
 ("(2x + 3) + (x − 5) cəmini sadələşdirin.",
  "2x + x = 3x; 3 − 5 = −2: 3x − 2.",
  ["3x − 2", "3x + 2", "2x − 2", "3x − 8"], 1,
  "%dx − %d" % (2 + 1, 5 - 3), 2),
 ("Çoxhədlinin standart şəkli nədir?",
  "Bütün oxşar hədləri birləşdirilmiş yazılışdır.",
  ["Oxşar hədləri birləşdirilmiş yazılış", "Ən uzun yazılış",
   "Mötərizəli yazılış", "Rəqəmsiz yazılış"], 1, None, 2),
 ("2(x + 4) − x ifadəsini sadələşdirin.",
  "2x + 8 − x = x + 8.",
  ["x + 8", "3x + 8", "x + 4", "2x + 8"], 1, None, 2),
 ("x(x + 3) hasilini açın.",
  "x · x + x · 3 = x² + 3x.",
  ["x² + 3x", "x² + 3", "2x + 3", "3x²"], 1, None, 2),
 ("6x + 9 ifadəsini vuruqlara ayırın.",
  "Ortaq vuruq 3: 3(2x + 3).",
  ["3(2x + 3)", "3(2x + 9)", "6(x + 9)", "9(6x + 1)"],
  1, None, 3),
 ("(x + 2)(x + 5) hasilində sərbəst hədd neçədir?",
  "Sərbəst hədd: 2 · 5 = 10.",
  ["10", "7", "3", "25"], 1, str(2 * 5), 3),
 ("a⁶ : a² neçə olar?",
  "Bölmədə üstlər çıxılır: a⁴.",
  ["a⁴", "a³", "a⁸", "a¹²"], 1, "a⁴", 2),
],
"riy-7-ucbucaqlar": [
 ("Üçbucağın xarici bucağı nəyə bərabərdir?",
  "Ona qonşu olmayan iki daxili bucağın cəminə.",
  ["Qonşu olmayan iki daxili bucağın cəminə",
   "Bütün bucaqların cəminə", "90°-yə", "Qonşu bucağa"],
  1, None, 3),
 ("Üçbucağın medianı nədir?",
  "Təpəni qarşı tərəfin orta nöqtəsi ilə birləşdirən parçadır.",
  ["Təpəni qarşı tərəfin ortası ilə birləşdirən parça",
   "Bucağı yarıya bölən şüa", "Perpendikulyar parça",
   "Ən uzun tərəf"], 1, None, 3),
 ("Üçbucağın hündürlüyü nədir?",
  "Təpədən qarşı tərəfə endirilən perpendikulyardır.",
  ["Təpədən qarşı tərəfə perpendikulyar",
   "Tərəflərin cəmi", "Ən qısa tərəf", "Median ilə eynidir"],
  1, None, 2),
 ("Üçbucağın iki bucağı 35° və 65°-dirsə, üçüncü bucağı tapın.",
  "180 − 35 − 65 = 80°.",
  ["80°", "100°", "90°", "70°"], 1,
  "%d°" % (180 - 35 - 65), 2),
 ("Üçbucağın iki tərəfi 3 sm və 4 sm-dirsə, üçüncü tərəf hansı "
  "aralıqda ola bilər?",
  "Üçbucaq bərabərsizliyi: 4 − 3 < x < 4 + 3.",
  ["1 sm-dən böyük, 7 sm-dən kiçik", "İstənilən uzunluqda",
   "Düz 7 sm", "3 sm-dən kiçik"], 1, None, 3),
 ("Üçbucaqda böyük bucağın qarşısında hansı tərəf durur?",
  "Böyük bucaq qarşısında böyük tərəf durur.",
  ["Böyük tərəf", "Kiçik tərəf", "Orta tərəf",
   "İstənilən tərəf"], 1, None, 2),
 ("Üçbucağın neçə medianı var?",
  "Hər təpədən bir median: 3.",
  ["3", "1", "2", "6"], 1, str(3), 2),
 ("Tərəfləri 2 sm, 9 sm və 5 sm olan üçbucaq qurmaq olarmı?",
  "2 + 5 = 7 < 9 — üçbucaq bərabərsizliyi pozulur, qurmaq olmaz.",
  ["Olmaz", "Olar", "Yalnız düzbucaqlı olar",
   "Yalnız bərabəryanlı olar"], 1,
  ("Olmaz" if 2 + 5 <= 9 else "Olar"), 3),
 ("Bərabərtərəfli üçbucaqda median, tənbölən və hündürlük necədir?",
  "Hər təpədən çəkilən bu üç xətt üst-üstə düşür.",
  ["Üst-üstə düşür", "Həmişə fərqlidir", "Kəsişmir",
   "Yalnız ikisi bərabərdir"], 1, None, 3),
 ("Üçbucağın bucaqları 2 : 3 : 4 nisbətindədirsə, böyük bucaq "
  "neçədir?",
  "Bir pay: 180 : 9 = 20; böyük bucaq: 20 · 4 = 80°.",
  ["80°", "40°", "60°", "90°"], 1,
  "%d°" % (180 * 4 // (2 + 3 + 4)), 3),
],
"riy-7-muxteser": [
 ("(a + b)² açılışı hansıdır?",
  "(a + b)² = a² + 2ab + b².",
  ["a² + 2ab + b²", "a² + b²", "a² − 2ab + b²", "2a + 2b"],
  1, None, 2),
 ("(x − 3)² açılışında orta hədd hansıdır?",
  "−2 · x · 3 = −6x.",
  ["−6x", "6x", "−9x", "−3x"], 1, "−%dx" % (2 * 3), 3),
 ("a² − b² fərqi hansı hasilə bərabərdir?",
  "Kvadratlar fərqi: (a − b)(a + b).",
  ["(a − b)(a + b)", "(a − b)²", "(a + b)²", "a·b·(a − b)"],
  1, None, 2),
 ("51² − 49² fərqini müxtəsər düsturla hesablayın.",
  "(51 − 49)(51 + 49) = 2 · 100 = 200.",
  ["200", "2", "100", "400"], 1, str(51 ** 2 - 49 ** 2), 3),
 ("(x + 4)² açılışını yazın.",
  "x² + 2·4·x + 16 = x² + 8x + 16.",
  ["x² + 8x + 16", "x² + 16", "x² + 4x + 16", "x² + 8x + 8"],
  1, "x² + %dx + %d" % (2 * 4, 4 ** 2), 2),
 ("(a + b)³ açılışında neçə hədd olur?",
  "a³ + 3a²b + 3ab² + b³ — dörd hədd.",
  ["4", "3", "2", "8"], 1, str(4), 3),
 ("x² − 25 ifadəsini vuruqlara ayırın.",
  "x² − 5² = (x − 5)(x + 5).",
  ["(x − 5)(x + 5)", "(x − 5)²", "(x + 5)²", "x(x − 25)"],
  1, None, 2),
 ("a³ + b³ cəmi hansı hasilə bərabərdir?",
  "Kublar cəmi: (a + b)(a² − ab + b²).",
  ["(a + b)(a² − ab + b²)", "(a + b)³",
   "(a + b)(a² + ab + b²)", "(a + b)(a + b)"],
  1, None, 3),
 ("99 · 101 hasilini müxtəsər düsturla tapın.",
  "(100 − 1)(100 + 1) = 10 000 − 1 = 9 999.",
  ["9 999", "10 001", "9 909", "10 000"], 1, fmt(99 * 101), 3),
 ("x² + 6x + 9 üçhədlisi hansı ifadənin kvadratıdır?",
  "x² + 2·3x + 3² = (x + 3)².",
  ["(x + 3)²", "(x + 6)²", "(x + 9)²", "(x − 3)²"], 1, None, 3),
],
"riy-7-funksiya": [
 ("y = 2x + 1 funksiyasında x = 3 olduqda y neçədir?",
  "y = 2 · 3 + 1 = 7.",
  ["7", "6", "5", "9"], 1, str(2 * 3 + 1), 2),
 ("Xətti funksiyanın qrafiki hansı xətdir?",
  "Xətti funksiyanın qrafiki düz xəttdir.",
  ["Düz xətt", "Parabola", "Çevrə", "Sınıq xətt"], 1, None, 2),
 ("y = kx + b yazılışında k nəyi bildirir?",
  "k — bucaq əmsalıdır.",
  ["Bucaq əmsalını", "Sərbəst həddi", "Funksiyanın adını",
   "Qrafikin rəngini"], 1, None, 3),
 ("y = 3x funksiyasının qrafiki hansı nöqtədən mütləq keçir?",
  "b = 0 olduğundan qrafik (0; 0)-dan keçir.",
  ["(0; 0)", "(1; 0)", "(0; 3)", "(3; 0)"], 1, None, 3),
 ("y = −x + 5 funksiyasında y = 0 olduqda x neçədir?",
  "0 = −x + 5; x = 5.",
  ["5", "−5", "0", "1"], 1, str(5), 2),
 ("Bucaq əmsalları bərabər, sərbəst hədləri fərqli xətti "
  "funksiyaların qrafikləri necədir?",
  "Belə düz xətlər paraleldir.",
  ["Paraleldir", "Kəsişir", "Üst-üstə düşür",
   "Perpendikulyardır"], 1, None, 3),
 ("Funksiya nədir?",
  "Hər x qiymətinə yeganə y qarşı qoyan uyğunluqdur.",
  ["Hər x-ə bir y qarşı qoyan uyğunluq", "İki ədədin cəmi",
   "Həndəsi fiqur", "Tənliyin kökü"], 1, None, 3),
 ("x + y = 4 tənliyinin həllərindən biri hansıdır?",
  "1 + 3 = 4 — (1; 3) cütlüyü tənliyi ödəyir.",
  ["(1; 3)", "(2; 3)", "(4; 4)", "(0; 3)"], 1, None, 2),
 ("y = 4x − 8 funksiyasının qrafiki Ox oxunu hansı nöqtədə kəsir?",
  "y = 0: 4x = 8; x = 2 — nöqtə (2; 0).",
  ["(2; 0)", "(0; 2)", "(8; 0)", "(0; −8)"], 1,
  "(%d; 0)" % (8 // 4), 3),
 ("y = 5x asılılığında asılı dəyişən hansıdır?",
  "y-in qiyməti x-dən asılıdır — asılı dəyişən y-dir.",
  ["y", "x", "5", "Heç biri"], 1, None, 2),
],
"riy-7-tenlikler-sistemi": [
 ("x + y = 5 və x − y = 1 sisteminin həlli hansıdır?",
  "Toplasaq: 2x = 6, x = 3; y = 2.",
  ["x = 3; y = 2", "x = 2; y = 3", "x = 4; y = 1",
   "x = 5; y = 0"], 1,
  "x = %d; y = %d" % ((5 + 1) // 2, (5 - 1) // 2), 3),
 ("İkidəyişənli sistemin həlli nə deməkdir?",
  "Hər iki tənliyi eyni zamanda ödəyən ədədlər cütüdür.",
  ["Hər iki tənliyi ödəyən cütlük", "İstənilən iki ədəd",
   "Yalnız birinci tənliyin kökü", "Qrafikin rəngi"],
  1, None, 2),
 ("Əvəzetmə üsulunda nə edilir?",
  "Bir dəyişən digəri ilə ifadə olunub o biri tənlikdə yerinə "
  "yazılır.",
  ["Dəyişən ifadə olunub yerinə yazılır",
   "Tənliklər silinir", "Qrafik çəkilir", "Ədədlər təxmin edilir"],
  1, None, 2),
 ("Toplama üsulunda tənliklər nə üçün toplanır?",
  "Dəyişənlərdən birini yox etmək üçün.",
  ["Bir dəyişəni yox etmək üçün", "Cavabı böyütmək üçün",
   "Qrafiki çəkmək üçün", "Səbəbsiz"], 1, None, 2),
 ("2x + y = 7 tənliyində y = 3 olarsa, x neçədir?",
  "2x = 7 − 3 = 4; x = 2.",
  ["2", "5", "4", "10"], 1, str((7 - 3) // 2), 2),
 ("Qrafik üsulda sistemin həlli nəyə uyğun gəlir?",
  "Düz xətlərin kəsişmə nöqtəsinə.",
  ["Kəsişmə nöqtəsinə", "Ox oxuna", "Başlanğıca",
   "Ən hündür nöqtəyə"], 1, None, 3),
 ("Qrafikləri paralel olan sistemin neçə həlli var?",
  "Xətlər kəsişmir — həll yoxdur.",
  ["Həlli yoxdur", "Bir həlli var", "İki həlli var",
   "Sonsuz həlli var"], 1, None, 3),
 ("x − 2y = 0 tənliyində x = 6 olduqda y neçədir?",
  "6 = 2y; y = 3.",
  ["3", "6", "12", "0"], 1, str(6 // 2), 2),
 ("Cəmi 12, fərqi 2 olan iki ədədi tapın.",
  "(12 + 2) : 2 = 7 və 12 − 7 = 5.",
  ["7 və 5", "8 və 4", "6 və 6", "10 və 2"], 1,
  "%d və %d" % ((12 + 2) // 2, (12 - 2) // 2), 3),
 ("Qrafikləri üst-üstə düşən sistemin həll sayı neçədir?",
  "Xəttin hər nöqtəsi həlldir — sonsuz sayda.",
  ["Sonsuz", "Bir", "İki", "Sıfır"], 1, None, 3),
],
"riy-7-konqruyentlik": [
 ("Konqruyent fiqurlar necə fiqurlardır?",
  "Üst-üstə qoyduqda tam üst-üstə düşən fiqurlardır.",
  ["Üst-üstə düşən (bərabər)", "Yalnız oxşar",
   "Sahələri fərqli", "Rəngi eyni"], 1, None, 2),
 ("Konqruyentliyin birinci əlaməti hansı elementlərə görədir?",
  "İki tərəf və onlar arasındakı bucağa görə.",
  ["İki tərəf və arasındakı bucağa", "Üç bucağa",
   "Bir tərəfə", "Perimetrə"], 1, None, 3),
 ("Konqruyentliyin ikinci əlaməti nəyə əsaslanır?",
  "Bir tərəf və ona bitişik iki bucağa.",
  ["Tərəf və ona bitişik iki bucağa", "Üç tərəfə",
   "İki bucağa", "Sahəyə"], 1, None, 3),
 ("Konqruyentliyin üçüncü əlaməti hansıdır?",
  "Üç tərəfə görə konqruyentlik.",
  ["Üç tərəfə görə", "Üç bucağa görə", "Perimetrə görə",
   "Hündürlüyə görə"], 1, None, 3),
 ("Bərabəryanlı üçbucaqda təpədən oturacağa çəkilən median həm "
  "də nədir?",
  "O həm hündürlük, həm də tənböləndir.",
  ["Hündürlük və tənbölən", "Yalnız median",
   "Orta xətt", "Diaqonal"], 1, None, 3),
 ("Konqruyent üçbucaqların uyğun bucaqları necədir?",
  "Uyğun bucaqlar bərabərdir.",
  ["Bərabərdir", "Fərqlidir", "Cəmi 90°-dir",
   "Müqayisə olunmur"], 1, None, 2),
 ("Konqruyent üçbucaqların perimetrləri haqqında nə demək olar?",
  "Uyğun tərəflər bərabərdir — perimetrlər də bərabərdir.",
  ["Perimetrlər bərabərdir", "Perimetrlər fərqlidir",
   "Biri iki dəfə böyükdür", "Bilmək olmaz"], 1, None, 2),
 ("△ABC ≅ △DEF yazılışında AB tərəfinə hansı tərəf uyğundur?",
  "Yazılış sırasına görə AB-yə DE uyğundur.",
  ["DE", "EF", "DF", "FE"], 1, None, 3),
 ("Konqruyentlik əlamətləri nəyi sübut etməyə imkan verir?",
  "İki üçbucağın konqruyent olduğunu.",
  ["Üçbucaqların konqruyentliyini", "Sahənin böyüklüyünü",
   "Bucağın adını", "Perimetrin uzunluğunu"], 1, None, 2),
 ("Konqruyent fiqurların sahələri necədir?",
  "Konqruyent fiqurların sahələri bərabərdir.",
  ["Sahələri bərabərdir", "Sahələri fərqlidir",
   "Sahəsi olmur", "Yalnız perimetrləri bərabərdir"],
  1, None, 2),
],
"riy-7-situasiya": [
 ("Mütləq xəta nədir?",
  "Həqiqi və təqribi qiymətlər fərqinin moduludur.",
  ["Həqiqi ilə təqribi qiymət fərqinin modulu",
   "Qiymətlərin cəmi", "Qiymətlərin hasili", "Faiz nisbəti"],
  1, None, 3),
 ("Həqiqi qiymət 50, təqribi qiymət 45-dirsə, mütləq xəta neçədir?",
  "|50 − 45| = 5.",
  ["5", "95", "45", "−5"], 1, str(abs(50 - 45)), 2),
 ("Nisbi xəta necə tapılır?",
  "Mütləq xətanın həqiqi qiymətə nisbəti kimi.",
  ["Mütləq xəta : həqiqi qiymət", "Qiymətlərin cəmi kimi",
   "Həqiqi qiymət : 100", "Təqribi qiymətin kvadratı kimi"],
  1, None, 3),
 ("Malın qiyməti 40 manatdan 50 manata qalxdı. Qiymət neçə faiz "
  "artıb?",
  "Artım 10 manat; 10/40 = 25%.",
  ["25%", "10%", "20%", "50%"], 1,
  "%d%%" % ((50 - 40) * 100 // 40), 3),
 ("240 manatın 35%-i neçə manatdır?",
  "240 · 35 : 100 = 84.",
  ["84", "35", "205", "175"], 1, str(240 * 35 // 100), 2),
 ("A = {1; 2; 3; 4}, B = {3; 4; 5}. A \\ B fərqini tapın.",
  "A-da olub B-də olmayanlar: {1; 2}.",
  ["{1; 2}", "{3; 4}", "{5}", "{1; 2; 5}"], 1,
  coxluq({1, 2, 3, 4} - {3, 4, 5}), 3),
 ("250 manatlıq mala 20% endirim edildi. Yeni qiymət neçədir?",
  "Endirim 50 manat; 250 − 50 = 200 manat.",
  ["200 manat", "230 manat", "50 manat", "210 manat"], 1,
  "%d manat" % (250 - 250 * 20 // 100), 3),
 ("Ölçmə nəticəsi 19,6 sm, həqiqi uzunluq 20 sm-dirsə, mütləq "
  "xəta neçədir?",
  "|20 − 19,6| = 0,4 sm.",
  ["0,4 sm", "4 sm", "0,6 sm", "39,6 sm"], 1,
  "%s sm" % dec(abs(20 - 19.6)), 3),
 ("A = {a; b}, B = {b; c; d}. A ∪ B çoxluğunda neçə element var?",
  "Birləşmə: {a; b; c; d} — 4 element.",
  ["4", "5", "3", "2"], 1, str(len({"a", "b"} | {"b", "c", "d"})), 3),
 ("Araşdırma məsələsinin həllində ilk addım nədir?",
  "Məsələni anlamaq, verilənləri müəyyən etmək.",
  ["Məsələni anlayıb verilənləri ayırmaq", "Cavabı yazmaq",
   "Təsadüfi hesablamaq", "Məsələni atmaq"], 1, None, 2),
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
        qisa = movzu.replace("riy-7-", "")
        for i, (body, why, opts, correct, _e, diff) in enumerate(SUALLAR[movzu], 1):
            setirler.append(
                "('riy7-%s#%d','%s',%d,%d,'%s','%s',array['%s','%s','%s','%s'],%d)"
                % (qisa, i, movzu, diff, RUBLAR[movzu], q(body), q(why),
                   q(opts[0]), q(opts[1]), q(opts[2]), q(opts[3]), correct))
    with io.open(CIXIS, "w", encoding="utf-8") as f:
        f.write("""-- =====================================================================
--  34_bank_riy7.sql : RIYAZIYYAT 7 PLATFORMA SUAL BANKI (orta mekteb)
--
--  BU FAYL ELLE YAZILMIR - tools/riy7.py yaradir:
--      python3 tools/riy7.py
--
--  10 movzu x 10 sual = %d.  ext_key: riy7-<movzu>#<sira>.
--  ON SERT: 33_movzular_orta7.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (
    select 1 from public.topics t
      join public.subjects s on s.id = t.subject_id
     where s.slug = 'riyaziyyat' and t.slug = 'riy-7-muxteser') then
    raise exception 'ONCE 33_movzular_orta7.sql isledilmelidir (riy-7-* movzulari yoxdur).';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and q.ext_key like 'riy7-%%';

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
    join public.levels   l on l.program_id = p.id and l.code = '7'
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
   where owner_type = 'platform' and ext_key like 'riy7-%%';
  if n <> %d then
    raise exception 'riy7 suallari: %d gozlenilirdi, %% tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'riy7-%%'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '%% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'riy7-%%';
  if k <> 10 then
    raise exception 'movzu sayi 10 deyil: %%', k;
  end if;
  raise notice 'Riyaziyyat 7 banki: %% sual, 10 movzu.', n;
end $$;
""" % (n, ",\n".join(setirler), n, n))
    print("yazildi: %s" % CIXIS)


if __name__ == "__main__":
    ok, n = yoxla()
    if not ok:
        raise SystemExit(1)
    sql_yaz(n)
