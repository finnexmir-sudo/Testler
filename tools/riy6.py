#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Riyaziyyat 6 platforma banki -> db/30_bank_riy6.sql

tools/riy5.py qelibi ile: 9 movzu x 10 sual = 90, her riyazi cavab
YENIDEN HESABLANIB duzgun variantla tutusdurulur (EBOB/EKOB math.gcd
ile, ehtimallar Fraction ile, coxluqlar set ile).  Movzular
29_movzular_orta6.sql agacina uygundur (e-derslik Riyaziyyat 6,
kitab 906 + 907).

Menfi ededler «−» (U+2212) isaresi ile yazilir - tam() koməkçisi.
DIQQET: riy3/riy4/riy5 fayllarinin reqemleri tekrarlanmayib.

Isletmek:
    python3 tools/riy6.py
"""
import io
import math
import os
from fractions import Fraction

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CIXIS = os.path.join(KOK, "db", "30_bank_riy6.sql")


def tam(n):
    """Menfi eded ucun riyazi minus isaresi."""
    return str(n).replace("-", "−")


def kesr(f):
    f = Fraction(f)
    if f.denominator == 1:
        return str(f.numerator)
    return "%d/%d" % (f.numerator, f.denominator)


def coxluq(elems):
    return "{%s}" % "; ".join(str(e) for e in sorted(elems))


RUBLAR = {
    "riy-6-natural-ededler": 1, "riy-6-nisbet-faiz": 1,
    "riy-6-tam-ededler": 2, "riy-6-koordinat": 2,
    "riy-6-coxluqlar": 3, "riy-6-ifade-tenlik": 3,
    "riy-6-ucbucaqlar": 3, "riy-6-sahe-hecm": 4,
    "riy-6-statistika": 4,
}

SUALLAR = {
"riy-6-natural-ededler": [
 ("Hansı ədəd sadə ədəddir?",
  "13-ün yalnız iki böləni var: 1 və 13.",
  ["13", "9", "15", "21"], 1,
  str([n for n in (13, 9, 15, 21)
       if sum(1 for d in range(1, n + 1) if n % d == 0) == 2][0]), 2),
 ("12 və 18 ədədlərinin ən böyük ortaq böləni (EBOB) neçədir?",
  "12 = 2·2·3; 18 = 2·3·3; ortaq vuruqlar: 2·3 = 6.",
  ["6", "3", "36", "2"], 1, str(math.gcd(12, 18)), 2),
 ("4 və 6 ədədlərinin ən kiçik ortaq bölünəni (EKOB) neçədir?",
  "4-ə və 6-ya bölünən ən kiçik ədəd 12-dir.",
  ["12", "24", "6", "2"], 1, str(4 * 6 // math.gcd(4, 6)), 2),
 ("Hansı ədəd həm 2-yə, həm də 5-ə bölünür?",
  "Sonu 0 ilə bitən ədədlər həm 2-yə, həm 5-ə bölünür: 90.",
  ["90", "85", "72", "55"], 1,
  str([n for n in (90, 85, 72, 55) if n % 2 == 0 and n % 5 == 0][0]), 2),
 ("2⁵ neçəyə bərabərdir?",
  "2⁵ = 2·2·2·2·2 = 32.",
  ["32", "10", "25", "64"], 1, str(2 ** 5), 2),
 ("Hansı ədəd 9-a qalıqsız bölünür?",
  "Rəqəmlərinin cəmi 9-a bölünən ədəd 9-a bölünür: 7+3+8 = 18.",
  ["738", "728", "745", "703"], 1,
  str([n for n in (738, 728, 745, 703) if n % 9 == 0][0]), 3),
 ("Hansı ədəd mürəkkəb ədəddir?",
  "21 = 3 · 7 — ikidən çox böləni var; 11, 17, 23 sadədir.",
  ["21", "11", "17", "23"], 1,
  str([n for n in (21, 11, 17, 23)
       if sum(1 for d in range(1, n + 1) if n % d == 0) > 2][0]), 2),
 ("56 ədədinin sadə vuruqlara ayrılışı hansıdır?",
  "56 = 2 · 2 · 2 · 7.",
  ["2 · 2 · 2 · 7", "2 · 4 · 7", "2 · 2 · 14", "7 · 8"], 1, None, 3),
 ("10² + 10 neçə edər?",
  "100 + 10 = 110.",
  ["110", "30", "1 010", "120"], 1, str(10 ** 2 + 10), 1),
 ("1 000 000 ədədi 10-un neçənci qüvvətidir?",
  "1 000 000 = 10⁶ — altı sıfır.",
  ["6", "5", "7", "100"], 1, str(len(str(10 ** 6)) - 1), 2),
],
"riy-6-nisbet-faiz": [
 ("8 : 12 nisbətini sadələşdirin.",
  "Hər iki həddi 4-ə bölək: 2 : 3.",
  ["2 : 3", "3 : 2", "4 : 6", "1 : 2"], 1,
  "%d : %d" % (8 // math.gcd(8, 12), 12 // math.gcd(8, 12)), 2),
 ("Tənasübdə x-i tapın: x : 10 = 6 : 4.",
  "x = 10 · 6 : 4 = 15.",
  ["15", "24", "60", "12"], 1, str(10 * 6 // 4), 3),
 ("Sinifdə oğlanların qızlara nisbəti 3 : 2-dir. 15 oğlan varsa, "
  "neçə qız var?",
  "Bir pay: 15 : 3 = 5; qızlar: 5 · 2 = 10.",
  ["10", "12", "6", "30"], 1, str(15 // 3 * 2), 3),
 ("300-ün 12%-i neçədir?",
  "300 : 100 = 3; 3 · 12 = 36.",
  ["36", "12", "25", "360"], 1, str(300 * 12 // 100), 2),
 ("Ədədin 40%-i 28-ə bərabərdirsə, ədədin özü neçədir?",
  "1%: 28 : 40 = 0,7; ədəd: 0,7 · 100 = 70.",
  ["70", "40", "112", "68"], 1, str(28 * 100 // 40), 3),
 ("Tənasübün əsas xassəsi hansıdır?",
  "Kənar hədlərin hasili orta hədlərin hasilinə bərabərdir.",
  ["Kənar hədlərin hasili orta hədlərin hasilinə bərabərdir",
   "Bütün hədlər bərabərdir", "Hədlərin cəmi sabitdir",
   "Hədlər həmişə cütdür"], 1, None, 2),
 ("Xəritənin miqyası 1 : 100 000-dir. Xəritədə 3 sm olan məsafə "
  "həqiqətdə neçə kilometrdir?",
  "3 · 100 000 = 300 000 sm = 3 km.",
  ["3 km", "30 km", "300 km", "1 km"], 1,
  "%d km" % (3 * 100000 // 100000), 3),
 ("45-in 60-a nisbəti hansı kəsrlə ifadə olunur?",
  "45/60 = 3/4.",
  ["3/4", "4/3", "5/6", "1/4"], 1,
  kesr(Fraction(45, 60)), 2),
 ("Qarışıqda şəkər və un 1 : 4 nisbətindədir. 500 q qarışıqda "
  "neçə qram şəkər var?",
  "Cəmi 5 pay; bir pay: 500 : 5 = 100 q.",
  ["100 q", "125 q", "400 q", "20 q"], 1,
  "%d q" % (500 // (1 + 4)), 3),
 ("20 ədədi 50-nin neçə faizidir?",
  "20/50 = 0,4 = 40%.",
  ["40%", "20%", "50%", "25%"], 1,
  "%d%%" % (20 * 100 // 50), 3),
],
"riy-6-tam-ededler": [
 ("−7 və 3 ədədlərindən hansı böyükdür?",
  "Müsbət ədəd mənfidən həmişə böyükdür.",
  ["3", "−7", "Bərabərdirlər", "Müqayisə olunmur"], 1,
  tam(max(-7, 3)), 1),
 ("|−9| (modul) neçəyə bərabərdir?",
  "Ədədin modulu onun sıfırdan məsafəsidir: 9.",
  ["9", "−9", "0", "18"], 1, tam(abs(-9)), 2),
 ("−5 + 7 neçə edər?",
  "Modullar fərqi, böyüyün işarəsi: 2.",
  ["2", "−2", "12", "−12"], 1, tam(-5 + 7), 2),
 ("−4 − 6 neçə edər?",
  "Mənfi ədəddən çıxanda modullar toplanır: −10.",
  ["−10", "2", "−2", "10"], 1, tam(-4 - 6), 2),
 ("(−3) · (−6) hasilini tapın.",
  "Mənfi ilə mənfinin hasili müsbətdir: 18.",
  ["18", "−18", "9", "−9"], 1, tam(-3 * -6), 2),
 ("−20 : 4 neçə edər?",
  "İşarələr fərqlidirsə, qismət mənfidir: −5.",
  ["−5", "5", "−16", "−24"], 1, tam(-20 // 4), 2),
 ("−2 ədədinin əks ədədi hansıdır?",
  "Əks ədədlərin cəmi sıfırdır: 2.",
  ["2", "−2", "0", "1/2"], 1, tam(2), 1),
 ("Termometr −3° göstərirdi. Temperatur 5° artdı. İndi termometr "
  "neçə dərəcəni göstərir?",
  "−3 + 5 = 2°.",
  ["2°", "−8°", "8°", "−2°"], 1, "%s°" % tam(-3 + 5), 2),
 ("−6, 0, 4 ədədləri hansı sırada düzülüb?",
  "Hər sonrakı ədəd böyükdür — artan sıradadır.",
  ["Artan", "Azalan", "Qarışıq", "Sıra yoxdur"], 1, None, 2),
 ("(−1) · (−1) · (−1) hasili neçədir?",
  "Tək sayda mənfi vuruq — nəticə mənfidir: −1.",
  ["−1", "1", "−3", "0"], 1, tam(-1 * -1 * -1), 3),
],
"riy-6-koordinat": [
 ("Koordinat oxlarının kəsişdiyi nöqtə necə adlanır?",
  "O(0; 0) — koordinat başlanğıcıdır.",
  ["Koordinat başlanğıcı", "Təpə nöqtəsi", "Mərkəz qövsü",
   "Kəsişmə bucağı"], 1, None, 2),
 ("A(3; 5) nöqtəsinin yazılışında 3 ədədi nəyi göstərir?",
  "Birinci ədəd absisdir (x koordinatı).",
  ["Absisi (x-i)", "Ordinatı (y-i)", "Məsafəni", "Bucağı"],
  1, None, 2),
 ("Üfüqi koordinat oxu necə adlanır?",
  "Üfüqi ox absis oxudur (Ox).",
  ["Absis oxu (Ox)", "Ordinat oxu (Oy)", "Simmetriya oxu",
   "Paralel ox"], 1, None, 2),
 ("B(0; 4) nöqtəsi harada yerləşir?",
  "Absisi 0 olan nöqtə ordinat oxu üzərindədir.",
  ["Ordinat oxu üzərində", "Absis oxu üzərində",
   "Başlanğıcda", "II rübdə"], 1, None, 3),
 ("Koordinat müstəvisi oxlarla neçə rübə bölünür?",
  "Oxlar müstəvini 4 rübə bölür.",
  ["4", "2", "3", "6"], 1, str(4), 1),
 ("C(−2; 3) nöqtəsi hansı rübdə yerləşir?",
  "x < 0, y > 0 olduqda nöqtə II rübdədir.",
  ["II rübdə", "I rübdə", "III rübdə", "IV rübdə"], 1, None, 3),
 ("Şaquli koordinat oxu necə adlanır?",
  "Şaquli ox ordinat oxudur (Oy).",
  ["Ordinat oxu (Oy)", "Absis oxu (Ox)", "Diaqonal ox",
   "Miqyas oxu"], 1, None, 2),
 ("D(5; 0) nöqtəsi harada yerləşir?",
  "Ordinatı 0 olan nöqtə absis oxu üzərindədir.",
  ["Absis oxu üzərində", "Ordinat oxu üzərində",
   "I rübdə", "Heç yerdə"], 1, None, 3),
 ("M(2; 7) və N(2; 1) nöqtələrindən keçən düz xətt hansı oxa "
  "paraleldir?",
  "Absislər eynidirsə, xətt Oy oxuna paraleldir.",
  ["Oy oxuna", "Ox oxuna", "Heç birinə", "Hər ikisinə"],
  1, None, 3),
 ("Hansı nöqtə III rübdə yerləşir?",
  "III rübdə hər iki koordinat mənfidir: (−4; −1).",
  ["(−4; −1)", "(4; 1)", "(−4; 1)", "(4; −1)"], 1, None, 3),
],
"riy-6-coxluqlar": [
 ("Çoxluğu təşkil edən obyektlərin hər biri necə adlanır?",
  "Çoxluğun obyektləri onun elementləridir.",
  ["Element", "Rəqəm", "Hərf", "Qrup"], 1, None, 1),
 ("A = {1; 2; 3} çoxluğunun neçə elementi var?",
  "Çoxluqda 3 element var.",
  ["3", "6", "1", "123"], 1, str(len({1, 2, 3})), 1),
 ("İki çoxluğun ortaq elementlərindən ibarət çoxluq necə adlanır?",
  "Ortaq elementlər kəsişməni əmələ gətirir.",
  ["Kəsişmə", "Birləşmə", "Fərq", "Alt çoxluq"], 1, None, 2),
 ("A = {1; 2; 3}, B = {2; 3; 4}. A ∩ B çoxluğunu tapın.",
  "Ortaq elementlər: 2 və 3.",
  ["{2; 3}", "{1; 2; 3; 4}", "{1; 4}", "{1}"], 1,
  coxluq({1, 2, 3} & {2, 3, 4}), 2),
 ("A = {1; 2}, B = {2; 5}. A ∪ B çoxluğunu tapın.",
  "Birləşməyə hər iki çoxluğun bütün elementləri daxildir.",
  ["{1; 2; 5}", "{2}", "{1; 5}", "{1; 2; 2; 5}"], 1,
  coxluq({1, 2} | {2, 5}), 2),
 ("Heç bir elementi olmayan çoxluq necə adlanır?",
  "Elementsiz çoxluq boş çoxluqdur.",
  ["Boş çoxluq", "Tam çoxluq", "Kiçik çoxluq", "Sıfır ədədi"],
  1, None, 2),
 ("Bütün elementləri başqa çoxluğa daxil olan çoxluq necə adlanır?",
  "Belə çoxluq alt çoxluqdur.",
  ["Alt çoxluq", "Üst çoxluq", "Kəsişmə", "Qalıq"], 1, None, 2),
 ("C = {a; b; c; d} çoxluğundan neçə birelementli alt çoxluq "
  "ayırmaq olar?",
  "Hər elementdən bir alt çoxluq: 4.",
  ["4", "1", "16", "2"], 1, str(len(["a", "b", "c", "d"])), 3),
 ("Cüt ədədlər çoxluğu ilə tək ədədlər çoxluğunun kəsişməsi nədir?",
  "Həm cüt, həm tək ədəd yoxdur — kəsişmə boşdur.",
  ["Boş çoxluqdur", "Bütün ədədlərdir", "Yalnız sıfırdır",
   "Yalnız 1-dir"], 1, None, 3),
 ("{5; 10; 15; 20; …} çoxluğunun elementlərini birləşdirən "
  "ümumi xassə hansıdır?",
  "Hamısı 5-ə bölünür.",
  ["5-ə bölünmə", "Cüt olma", "Tək olma", "Sadə olma"],
  1, None, 2),
],
"riy-6-ifade-tenlik": [
 ("7x − 2x ifadəsini sadələşdirin.",
  "Oxşar hədlər: (7 − 2)x = 5x.",
  ["5x", "9x", "5", "14x"], 1, None, 2),
 ("3(x + 4) mötərizəsini açın.",
  "Paylama qanunu: 3x + 12.",
  ["3x + 12", "3x + 4", "x + 12", "7x"], 1, None, 2),
 ("4x = −20 tənliyinin kökü neçədir?",
  "x = −20 : 4 = −5.",
  ["−5", "5", "−16", "−80"], 1, tam(-20 // 4), 2),
 ("x + 15 = 9 tənliyini həll edin.",
  "x = 9 − 15 = −6.",
  ["−6", "6", "24", "−24"], 1, tam(9 - 15), 2),
 ("2x + 3 = 19 tənliyinin kökü neçədir?",
  "2x = 16; x = 8.",
  ["8", "11", "16", "38"], 1, str((19 - 3) // 2), 2),
 ("x : 3 = −7 tənliyində x-i tapın.",
  "x = −7 · 3 = −21.",
  ["−21", "21", "−4", "−10"], 1, tam(-7 * 3), 2),
 ("5 − x = 12 tənliyinin kökü neçədir?",
  "x = 5 − 12 = −7.",
  ["−7", "7", "17", "−17"], 1, tam(5 - 12), 3),
 ("x > −2 bərabərsizliyini hansı ədəd ödəyir?",
  "0 ədədi −2-dən böyükdür.",
  ["0", "−3", "−5", "−10"], 1,
  str([n for n in (0, -3, -5, -10) if n > -2][0]), 2),
 ("a = −2 olduqda 3a + 11 ifadəsinin qiyməti neçədir?",
  "3 · (−2) = −6; −6 + 11 = 5.",
  ["5", "17", "−17", "−5"], 1, tam(3 * -2 + 11), 3),
 ("Ədədin 3 misli ilə 5-in cəmi 26-dır. Ədədi tapın.",
  "3x + 5 = 26; 3x = 21; x = 7.",
  ["7", "21", "31", "9"], 1, str((26 - 5) // 3), 3),
],
"riy-6-ucbucaqlar": [
 ("Üçbucağın daxili bucaqlarının cəmi neçə dərəcədir?",
  "İstənilən üçbucaqda bucaqların cəmi 180°-dir.",
  ["180°", "90°", "360°", "100°"], 1, None, 2),
 ("Bərabərtərəfli üçbucağın hər bucağı neçə dərəcədir?",
  "180 : 3 = 60°.",
  ["60°", "90°", "45°", "120°"], 1, "%d°" % (180 // 3), 2),
 ("Üçbucağın iki bucağı 50° və 60°-dirsə, üçüncü bucağı tapın.",
  "180 − 50 − 60 = 70°.",
  ["70°", "110°", "80°", "60°"], 1,
  "%d°" % (180 - 50 - 60), 2),
 ("İki tərəfi bərabər olan üçbucaq necə adlanır?",
  "İki bərabər tərəfli üçbucaq bərabəryanlıdır.",
  ["Bərabəryanlı", "Bərabərtərəfli", "Müxtəliftərəfli",
   "Düzbucaqlı"], 1, None, 2),
 ("Düzbucaqlı üçbucaqda iti bucaqların cəmi neçə dərəcədir?",
  "180 − 90 = 90°.",
  ["90°", "180°", "45°", "100°"], 1, "%d°" % (180 - 90), 3),
 ("Bütün bucaqları iti olan üçbucaq necə adlanır?",
  "Hər üç bucağı iti olan üçbucaq itibucaqlıdır.",
  ["İtibucaqlı", "Korbucaqlı", "Düzbucaqlı", "Bərabəryanlı"],
  1, None, 2),
 ("Tərəfləri 6 sm, 8 sm və 10 sm olan üçbucağın perimetri neçədir?",
  "P = 6 + 8 + 10 = 24 sm.",
  ["24 sm", "22 sm", "26 sm", "48 sm"], 1,
  "%d sm" % (6 + 8 + 10), 2),
 ("Üçbucağın bir tərəfi digər iki tərəfin cəmindən böyük ola bilərmi?",
  "Xeyr — üçbucaq bərabərsizliyinə görə ola bilməz.",
  ["Xeyr, ola bilməz", "Bəli, həmişə", "Yalnız düzbucaqlıda",
   "Yalnız bərabəryanlıda"], 1, None, 3),
 ("Bərabəryanlı üçbucağın oturacağına bitişik bucaqları necədir?",
  "Oturacaq bucaqları bərabərdir.",
  ["Bərabərdir", "Fərqlidir", "Həmişə 90°-dir", "Kor bucaqdır"],
  1, None, 3),
 ("Bucaqlarından biri kor olan üçbucaq necə adlanır?",
  "Kor bucağı olan üçbucaq korbucaqlıdır.",
  ["Korbucaqlı", "İtibucaqlı", "Düzbucaqlı", "Bərabərtərəfli"],
  1, None, 2),
],
"riy-6-sahe-hecm": [
 ("Paraleloqramın sahəsi necə hesablanır?",
  "S = oturacaq × hündürlük.",
  ["Oturacaq × hündürlük", "Tərəflərin cəmi",
   "Diaqonalların cəmi", "Perimetr × 2"], 1, None, 2),
 ("Oturacağı 10 sm, hündürlüyü 6 sm olan paraleloqramın sahəsi "
  "neçədir?",
  "S = 10 · 6 = 60 sm².",
  ["60 sm²", "30 sm²", "16 sm²", "32 sm²"], 1,
  "%d sm²" % (10 * 6), 2),
 ("Oturacağı 12 sm, hündürlüyü 5 sm olan üçbucağın sahəsini tapın.",
  "S = (12 · 5) : 2 = 30 sm².",
  ["30 sm²", "60 sm²", "17 sm²", "34 sm²"], 1,
  "%d sm²" % (12 * 5 // 2), 2),
 ("Tili 5 sm olan kubun həcmini tapın.",
  "V = 5³ = 125 sm³.",
  ["125 sm³", "25 sm³", "15 sm³", "150 sm³"], 1,
  "%d sm³" % (5 ** 3), 2),
 ("Ölçüləri 7 sm, 4 sm və 3 sm olan düzbucaqlı paralelepipedin "
  "həcmi neçədir?",
  "V = 7 · 4 · 3 = 84 sm³.",
  ["84 sm³", "14 sm³", "28 sm³", "168 sm³"], 1,
  "%d sm³" % (7 * 4 * 3), 2),
 ("1 sm² neçə kvadrat millimetrdir?",
  "1 sm = 10 mm; 10 · 10 = 100 mm².",
  ["100 mm²", "10 mm²", "1 000 mm²", "20 mm²"], 1,
  "%d mm²" % (10 * 10), 3),
 ("Trapesiyanın sahəsi necə tapılır?",
  "Oturacaqların cəminin yarısı hündürlüyə vurulur.",
  ["Oturacaqlar cəminin yarısı × hündürlük",
   "Bütün tərəflərin cəmi", "Diaqonalların hasili",
   "Oturacaqların fərqi × 2"], 1, None, 3),
 ("Sahəsi 48 sm², oturacağı 8 sm olan paraleloqramın hündürlüyü "
  "neçədir?",
  "h = S : a = 48 : 8 = 6 sm.",
  ["6 sm", "8 sm", "40 sm", "384 sm"], 1,
  "%d sm" % (48 // 8), 3),
 ("Kubun bütün tillərinin uzunluqları cəmi 36 sm-dirsə, bir til "
  "neçə santimetrdir?",
  "Kubun 12 tili var: 36 : 12 = 3 sm.",
  ["3 sm", "6 sm", "12 sm", "4 sm"], 1, "%d sm" % (36 // 12), 3),
 ("Rombun sahəsi diaqonalları ilə necə tapılır?",
  "S = diaqonalların hasilinin yarısı.",
  ["Diaqonalların hasilinin yarısı", "Diaqonalların cəmi",
   "Tərəflərin hasili", "Perimetrin yarısı"], 1, None, 3),
],
"riy-6-statistika": [
 ("Zər atılanda cüt ədəd düşməsi ehtimalı neçədir?",
  "6 üzdən 3-ü cütdür: 3/6 = 1/2.",
  ["1/2", "1/6", "1/3", "2/3"], 1, kesr(Fraction(3, 6)), 3),
 ("Ehtimal hansı qiymətlər arasında dəyişir?",
  "Ehtimal 0 ilə 1 arasında olur.",
  ["0 ilə 1 arasında", "1 ilə 10 arasında",
   "−1 ilə 1 arasında", "10 ilə 100 arasında"],
  1, None, 2),
 ("Yəqin (mütləq baş verən) hadisənin ehtimalı neçədir?",
  "Mütləq hadisənin ehtimalı 1-dir.",
  ["1", "0", "1/2", "100"], 1, str(1), 2),
 ("Qutuda 2 qırmızı və 3 mavi kürəcik var. Qırmızı kürəcik çıxarma "
  "ehtimalı neçədir?",
  "Cəmi 5 kürəcik: 2/5.",
  ["2/5", "3/5", "1/2", "2/3"], 1, kesr(Fraction(2, 5)), 3),
 ("5, 8, 8, 9, 10 sırasında moda (ən çox təkrarlanan) hansıdır?",
  "8 iki dəfə təkrarlanır.",
  ["8", "5", "10", "9"], 1,
  str(max((5, 8, 8, 9, 10), key=(5, 8, 8, 9, 10).count)), 2),
 ("12, 15, 18, 15 ədədlərinin ədədi ortası neçədir?",
  "(12 + 15 + 18 + 15) : 4 = 60 : 4 = 15.",
  ["15", "12", "60", "18"], 1,
  str((12 + 15 + 18 + 15) // 4), 2),
 ("Median nədir?",
  "Sıralanmış sıranın ortasındakı qiymətdir.",
  ["Sıralanmış sıranın ortasındakı qiymət",
   "Ən böyük qiymət", "Qiymətlərin cəmi",
   "Ən çox təkrarlanan qiymət"], 1, None, 3),
 ("3, 7, 9, 11, 20 sırasının medianı neçədir?",
  "Beş ədədin ortadakısı üçüncüdür: 9.",
  ["9", "7", "10", "11"], 1, str(sorted((3, 7, 9, 11, 20))[2]), 3),
 ("Mümkünsüz hadisənin ehtimalı neçədir?",
  "Baş verə bilməyən hadisənin ehtimalı 0-dır.",
  ["0", "1", "1/2", "−1"], 1, str(0), 2),
 ("Sütunlu diaqram nəyi göstərmək üçün əlverişlidir?",
  "Kəmiyyətləri müqayisə etmək üçün əlverişlidir.",
  ["Kəmiyyətlərin müqayisəsini", "Yalnız rəngləri",
   "Xəritəni", "Hərfləri"], 1, None, 2),
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
        qisa = movzu.replace("riy-6-", "")
        for i, (body, why, opts, correct, _e, diff) in enumerate(SUALLAR[movzu], 1):
            setirler.append(
                "('riy6-%s#%d','%s',%d,%d,'%s','%s',array['%s','%s','%s','%s'],%d)"
                % (qisa, i, movzu, diff, RUBLAR[movzu], q(body), q(why),
                   q(opts[0]), q(opts[1]), q(opts[2]), q(opts[3]), correct))
    with io.open(CIXIS, "w", encoding="utf-8") as f:
        f.write("""-- =====================================================================
--  30_bank_riy6.sql : RIYAZIYYAT 6 PLATFORMA SUAL BANKI (orta mekteb)
--
--  BU FAYL ELLE YAZILMIR - tools/riy6.py yaradir:
--      python3 tools/riy6.py
--
--  9 movzu x 10 sual = %d.  ext_key: riy6-<movzu>#<sira>.
--  ON SERT: 29_movzular_orta6.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (
    select 1 from public.topics t
      join public.subjects s on s.id = t.subject_id
     where s.slug = 'riyaziyyat' and t.slug = 'riy-6-coxluqlar') then
    raise exception 'ONCE 29_movzular_orta6.sql isledilmelidir (riy-6-* movzulari yoxdur).';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and q.ext_key like 'riy6-%%';

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
    join public.levels   l on l.program_id = p.id and l.code = '6'
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
   where owner_type = 'platform' and ext_key like 'riy6-%%';
  if n <> %d then
    raise exception 'riy6 suallari: %d gozlenilirdi, %% tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'riy6-%%'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '%% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'riy6-%%';
  if k <> 9 then
    raise exception 'movzu sayi 9 deyil: %%', k;
  end if;
  raise notice 'Riyaziyyat 6 banki: %% sual, 9 movzu.', n;
end $$;
""" % (n, ",\n".join(setirler), n, n))
    print("yazildi: %s" % CIXIS)


if __name__ == "__main__":
    ok, n = yoxla()
    if not ok:
        raise SystemExit(1)
    sql_yaz(n)
