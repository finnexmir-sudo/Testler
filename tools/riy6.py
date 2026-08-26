#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Riyaziyyat 6 platforma banki -> db/30_bank_riy6.sql

tools/riy5.py qelibi ile: 9 movzu x 20 sual = 90, her riyazi cavab
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


def fmt(n):
    return "{:,}".format(n).replace(",", " ")


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



#  Derinlesdirme: her movzuya 10 elave sual (#11-20).
ELAVE = {
"riy-6-natural-ededler": [
 ("20 və 30 ədədlərinin ortaq bölənlərindən ən böyüyü hansıdır?",
  "20 = 2·2·5; 30 = 2·3·5; EBOB = 2·5 = 10.",
  ["10", "5", "60", "600"], 1, str(math.gcd(20, 30)), 2),
 ("6-ya və 8-ə bölünən ən kiçik natural ədəd neçədir?",
  "EKOB(6, 8) = 24.",
  ["24", "48", "14", "2"], 1,
  str(6 * 8 // math.gcd(6, 8)), 2),
 ("3 ədədinin dördüncü qüvvətini hesablayın.",
  "3⁴ = 3·3·3·3 = 81.",
  ["81", "12", "27", "43"], 1, str(3 ** 4), 2),
 ("Sonu 0 və ya 5 ilə bitən ədədlər hansı ədədə mütləq bölünür?",
  "Bölünmə əlaməti: 5-ə bölünür.",
  ["5-ə", "2-yə", "3-ə", "9-a"], 1, None, 2),
 ("Rəqəmlərinin cəmi 3-ə bölünən ədəd hansı ədədə bölünür?",
  "3-ə bölünmə əlaməti belədir.",
  ["3-ə", "5-ə", "10-a", "7-yə"], 1, None, 2),
 ("1-dən 20-yə qədər neçə sadə ədəd var?",
  "2, 3, 5, 7, 11, 13, 17, 19 — cəmi 8 sadə ədəd.",
  ["8 sadə ədəd", "6 sadə ədəd", "10 sadə ədəd",
   "4 sadə ədəd"], 1,
  "%d sadə ədəd" % len([n for n in range(2, 21)
    if sum(1 for d in range(1, n + 1) if n % d == 0) == 2]), 3),
 ("Hansı hasil 48-in sadə vuruqlara ayrılışıdır?",
  "48 = 2 · 2 · 2 · 2 · 3.",
  ["2 · 2 · 2 · 2 · 3", "2 · 2 · 12", "4 · 12", "6 · 8"],
  1, None, 3),
 ("Qonşu iki natural ədədin hasili 72-dirsə, bu ədədlər hansılardır?",
  "8 · 9 = 72.",
  ["8 və 9", "6 və 12", "7 və 8", "9 və 10"], 1,
  ("8 və 9" if 8 * 9 == 72 else ""), 3),
 ("10⁴ ədədini açıq şəkildə yazın.",
  "10⁴ = 10 000 (dörd sıfır).",
  ["10 000", "1 000", "100 000", "40"], 1, fmt(10 ** 4), 2),
 ("Hansı ədəd həm 3-ə, həm də 4-ə bölünür?",
  "84 = 3 · 28 = 4 · 21 — hər ikisinə bölünür.",
  ["84", "74", "92", "58"], 1,
  str([n for n in (84, 74, 92, 58) if n % 3 == 0 and n % 4 == 0][0]), 3),
],
"riy-6-nisbet-faiz": [
 ("5 : 20 nisbəti ən sadə şəkildə necə yazılır?",
  "Hər iki həddi 5-ə bölək: 1 : 4.",
  ["1 : 4", "4 : 1", "1 : 5", "2 : 5"], 1,
  "%d : %d" % (5 // math.gcd(5, 20), 20 // math.gcd(5, 20)), 2),
 ("x : 4 = 27 : 9 tənasübünü ödəyən x hansıdır?",
  "x = 4 · 27 : 9 = 12.",
  ["12", "3", "108", "31"], 1, str(4 * 27 // 9), 3),
 ("200 manatın 45 faizi neçə manatdır?",
  "200 · 45 : 100 = 90 manat.",
  ["90 manat", "45 manat", "110 manat", "9 manat"], 1,
  "%d manat" % (200 * 45 // 100), 2),
 ("25%-i 13 olan ədədi tapın.",
  "25% dörddə birdir: ədəd = 13 · 4 = 52.",
  ["52", "26", "39", "65"], 1, str(13 * 4), 3),
 ("Plan 1 : 50 000 miqyasındadır. Plandakı 4 sm həqiqətdə neçə kilometrdir?",
  "4 · 50 000 = 200 000 sm = 2 km.",
  ["2 km", "4 km", "20 km", "8 km"], 1,
  "%d km" % (4 * 50000 // 100000), 3),
 ("Nisbətin hər iki həddini eyni sıfırdan fərqli ədədə vursaq nisbət necə dəyişər?",
  "Nisbət dəyişməz.",
  ["Dəyişməz", "İki dəfə artar", "Yarıya düşər", "Sıfır olar"],
  1, None, 2),
 ("Malın qiyməti 50 manat idi, 10% bahalaşdı. Yeni qiymət neçə oldu?",
  "Artım 5 manat: 50 + 5 = 55 manat.",
  ["55 manat", "60 manat", "51 manat", "45 manat"], 1,
  "%d manat" % (50 + 50 * 10 // 100), 3),
 ("18 kitabdan 6-sı dərslikdir. Dərsliklərin bütün kitablara nisbəti hansı kəsrdir?",
  "6/18 = 1/3.",
  ["1/3", "1/6", "3/1", "6/12"], 1,
  kesr(Fraction(6, 18)), 3),
 ("İki ədəd 4 : 5 nisbətindədir. Kiçik ədəd 16-dırsa, böyüyü neçədir?",
  "Bir pay: 16 : 4 = 4; böyük ədəd: 4 · 5 = 20.",
  ["20", "17", "25", "80"], 1, str(16 // 4 * 5), 3),
 ("100% ifadəsi nəyi bildirir?",
  "Tamın hamısını — bütövü.",
  ["Bütöv tamı (hamısını)", "Yarısını", "Onda birini",
   "Heç nəyi"], 1, None, 1),
],
"riy-6-tam-ededler": [
 ("Cəmi hesablayın: −9 + 3.",
  "Modullar fərqi 6, böyük modulun işarəsi mənfi: −6.",
  ["−6", "6", "−12", "12"], 1, tam(-9 + 3), 2),
 ("12 − 20 fərqi neçədir?",
  "12 − 20 = −8.",
  ["−8", "8", "−32", "32"], 1, tam(12 - 20), 2),
 ("(−4)² neçəyə bərabərdir?",
  "(−4) · (−4) = 16.",
  ["16", "−16", "−8", "8"], 1, tam((-4) ** 2), 2),
 ("−1 ilə 2 arasında hansı tam ədədlər var?",
  "Aralıqda 0 və 1 var.",
  ["0 və 1", "Yalnız 1", "−1 və 2", "Heç biri"],
  1, None, 2),
 ("Modulu 11 olan mənfi ədəd hansıdır?",
  "|−11| = 11.",
  ["−11", "11", "−1", "0"], 1, tam(-11), 2),
 ("Ən böyük mənfi tam ədəd hansıdır?",
  "Sıfıra ən yaxın mənfi tam ədəd −1-dir.",
  ["−1", "−10", "0", "1"], 1, tam(-1), 2),
 ("56 : (−8) neçə edər?",
  "İşarələr fərqlidir: −7.",
  ["−7", "7", "−48", "−64"], 1, tam(56 // -8), 2),
 ("Temperatur −2°-dən −9°-yə düşdü. Neçə dərəcə soyudu?",
  "|−9 − (−2)| = 7°.",
  ["7°", "11°", "2°", "9°"], 1,
  "%s°" % tam(abs(-9 - (-2))), 3),
 ("Sıfırın modulu haqqında nə demək olar?",
  "|0| = 0.",
  ["Sıfıra bərabərdir", "Müsbətdir", "Mənfidir",
   "Təyin olunmur"], 1, None, 2),
 ("Kubu hesablayın: (−3)³.",
  "(−3)·(−3)·(−3) = −27.",
  ["−27", "27", "−9", "−6"], 1, tam((-3) ** 3), 3),
],
"riy-6-koordinat": [
 ("Absisi müsbət, ordinatı mənfi olan K(6; −2) nöqtəsi hansı rübdədir?",
  "x > 0, y < 0 — IV rüb.",
  ["IV rübdə", "I rübdə", "II rübdə", "III rübdə"],
  1, None, 3),
 ("Nöqtənin ikinci koordinatı necə adlanır?",
  "İkinci koordinat ordinatdır (y).",
  ["Ordinat", "Absis", "Modul", "Miqyas"], 1, None, 2),
 ("P(−3; −8) nöqtəsinin ordinatı neçədir?",
  "İkinci ədəd ordinatdır: −8.",
  ["−8", "−3", "8", "3"], 1, tam(-8), 2),
 ("(0; 0) koordinatlı nöqtə haradadır?",
  "Hər iki koordinatı sıfır olan nöqtə başlanğıcdadır.",
  ["Koordinat başlanğıcında", "I rübdə", "Ox oxunda sağda",
   "Müstəvidən kənarda"], 1, None, 2),
 ("I rübdə yerləşən nöqtənin koordinatlarının işarələri necədir?",
  "I rübdə x > 0 və y > 0.",
  ["Hər ikisi müsbətdir", "Hər ikisi mənfidir",
   "x müsbət, y mənfidir", "x mənfi, y müsbətdir"],
  1, None, 2),
 ("Ordinatları bərabər olan iki nöqtədən keçən düz xətt hansı oxa paraleldir?",
  "y-lər eynidirsə, xətt Ox oxuna paraleldir.",
  ["Ox oxuna", "Oy oxuna", "Heç birinə", "Hər ikisinə"],
  1, None, 3),
 ("Koordinat müstəvisində nöqtənin yerini göstərmək üçün neçə ədəd lazımdır?",
  "Bir cüt: absis və ordinat.",
  ["İki ədəd (x və y)", "Bir ədəd", "Üç ədəd", "Dörd ədəd"],
  1, None, 2),
 ("A(2; 3) nöqtəsinin Ox oxuna nəzərən simmetrik nöqtəsi hansıdır?",
  "Ox oxuna nəzərən ordinatın işarəsi dəyişir: (2; −3).",
  ["(2; −3)", "(−2; 3)", "(−2; −3)", "(3; 2)"],
  1, None, 3),
 ("Koordinat müstəvisində rüblər hansı istiqamətdə nömrələnir?",
  "I rübdən başlayaraq saat əqrəbinin əksinə.",
  ["Saat əqrəbinin əksinə", "Saat əqrəbi istiqamətində",
   "Soldan sağa", "Yuxarıdan aşağı"], 1, None, 3),
 ("B(−7; 0) nöqtəsi hansı ox üzərindədir?",
  "Ordinatı sıfırdır — absis oxu üzərindədir.",
  ["Absis oxu üzərində", "Ordinat oxu üzərində",
   "Heç bir oxda", "Hər iki oxda"], 1, None, 3),
],
"riy-6-coxluqlar": [
 ("B = {a; e; i} çoxluğunda neçə element var?",
  "Üç hərf — 3 element.",
  ["3 element", "1 element", "6 element", "9 element"], 1,
  "%d element" % len({"a", "e", "i"}), 1),
 ("A = {3; 6; 9}, B = {6; 9; 12}. A ∪ B çoxluğunu tapın.",
  "Bütün elementlər bir yerdə: {3; 6; 9; 12}.",
  ["{3; 6; 9; 12}", "{6; 9}", "{3; 12}", "{3; 6}"], 1,
  coxluq({3, 6, 9} | {6, 9, 12}), 2),
 ("A ⊂ B yazılışı nəyi bildirir?",
  "A çoxluğu B-nin alt çoxluğudur.",
  ["A-nın B-nin alt çoxluğu olduğunu", "A ilə B-nin bərabərliyini",
   "A-nın boş olduğunu", "B-nin A-dan kiçik olduğunu"],
  1, None, 2),
 ("N hərfi ilə hansı ədədlər çoxluğu işarələnir?",
  "N — natural ədədlər çoxluğudur.",
  ["Natural ədədlər", "Tam ədədlər", "Mənfi ədədlər",
   "Kəsrlər"], 1, None, 2),
 ("Z hərfi hansı ədədlər çoxluğunu bildirir?",
  "Z — tam ədədlər çoxluğudur.",
  ["Tam ədədlər", "Natural ədədlər", "Onluq kəsrlər",
   "Sadə ədədlər"], 1, None, 2),
 ("A = {1; 2; 3; 4; 5} çoxluğundan B = {2; 4} çıxılsa, fərq çoxluğu nə olar?",
  "A-da olub B-də olmayanlar: {1; 3; 5}.",
  ["{1; 3; 5}", "{2; 4}", "{1; 2; 3}", "{4; 5}"], 1,
  coxluq({1, 2, 3, 4, 5} - {2, 4}), 3),
 ("Çoxluğun yazılışında eyni element neçə dəfə göstərilir?",
  "Hər element yalnız bir dəfə yazılır.",
  ["Yalnız bir dəfə", "İki dəfə", "İstənilən qədər",
   "Heç yazılmır"], 1, None, 2),
 ("Həftənin günləri çoxluğunda neçə element var?",
  "Həftədə 7 gün var.",
  ["7", "5", "12", "30"], 1, str(7), 1),
 ("Boş çoxluq hansı simvolla işarələnir?",
  "∅ simvolu ilə.",
  ["∅", "∩", "∪", "⊂"], 1, None, 2),
 ("A ∪ B əməli necə adlanır?",
  "İki çoxluğun birləşməsidir.",
  ["Birləşmə", "Kəsişmə", "Fərq", "Bölmə"], 1, None, 2),
],
"riy-6-ifade-tenlik": [
 ("9x − 4x + x ifadəsini sadələşdirin.",
  "9 − 4 + 1 = 6: nəticə 6x.",
  ["6x", "5x", "14x", "6"], 1, None, 2),
 ("Paylama qanunu ilə 5(x − 2) ifadəsini açın.",
  "5x − 10.",
  ["5x − 10", "5x − 2", "5x + 10", "3x"], 1, None, 2),
 ("x − 8 = −3 tənliyinin kökü neçədir?",
  "x = −3 + 8 = 5.",
  ["5", "−5", "−11", "11"], 1, str(-3 + 8), 2),
 ("3x − 7 = 26 olduqda x-in qiymətini tapın.",
  "3x = 33; x = 11.",
  ["11", "33", "19", "7"], 1, str((26 + 7) // 3), 3),
 ("−x = 4 tənliyinin kökü neçədir?",
  "x = −4.",
  ["−4", "4", "1/4", "0"], 1, tam(-4), 2),
 ("Tənliyin kökü nədir?",
  "Tənliyi doğru bərabərliyə çevirən qiymətdir.",
  ["Tənliyi doğru bərabərliyə çevirən qiymət",
   "İstənilən ədəd", "Ən böyük ədəd", "Tənliyin uzunluğu"],
  1, None, 2),
 ("b = 3 olduqda 2b² ifadəsinin qiyməti neçədir?",
  "2 · 9 = 18.",
  ["18", "36", "12", "6"], 1, str(2 * 3 ** 2), 3),
 ("Yarısı 13-ə bərabər olan ədəd hansıdır?",
  "x : 2 = 13; x = 26.",
  ["26", "13", "6,5", "39"], 1, str(13 * 2), 2),
 ("Ədədlə dəyişənin hasilində ədəd vuruğu necə adlanır?",
  "Ədəd vuruğu əmsaldır.",
  ["Əmsal", "Kök", "Modul", "Qüvvət"], 1, None, 2),
 ("x + x + x yazılışı hansı ifadəyə bərabərdir?",
  "Üç dəfə toplama: 3x.",
  ["3x", "x³", "3 + x", "x/3"], 1, None, 1),
],
"riy-6-ucbucaqlar": [
 ("Bucaqları 45° və 85° olan üçbucağın üçüncü bucağını hesablayın.",
  "180 − 45 − 85 = 50°.",
  ["50°", "130°", "40°", "95°"], 1,
  "%d°" % (180 - 45 - 85), 2),
 ("Bərabəryanlı üçbucağın təpə bucağı 40°-dirsə, oturacaq bucaqlarından hər biri neçədir?",
  "(180 − 40) : 2 = 70°.",
  ["70°", "40°", "140°", "35°"], 1,
  "%d°" % ((180 - 40) // 2), 3),
 ("Perimetri 30 sm olan bərabərtərəfli üçbucağın tərəfi neçədir?",
  "30 : 3 = 10 sm.",
  ["10 sm", "15 sm", "90 sm", "6 sm"], 1,
  "%d sm" % (30 // 3), 2),
 ("Bir bucağı düz bucaq olan üçbucaq necə adlanır?",
  "Düz bucağı olan üçbucaq düzbucaqlıdır.",
  ["Düzbucaqlı", "İtibucaqlı", "Korbucaqlı", "Bərabərtərəfli"],
  1, None, 1),
 ("Tərəfləri 5 sm, 5 sm və 7 sm olan üçbucaq hansı növdəndir?",
  "İki tərəfi bərabərdir — bərabəryanlıdır.",
  ["Bərabəryanlı", "Bərabərtərəfli", "Müxtəliftərəfli",
   "Qurmaq olmaz"], 1, None, 2),
 ("Üçbucağın hündürlüyü qarşı tərəfə hansı bucaq altında endirilir?",
  "Hündürlük perpendikulyardır — 90° altında.",
  ["90° altında", "60° altında", "45° altında",
   "İstənilən bucaq altında"], 1, None, 2),
 ("İki bucağı 60° olan üçbucaq hansı növdəndir?",
  "Üçüncü bucaq da 60° olur — bərabərtərəflidir.",
  ["Bərabərtərəfli", "Korbucaqlı", "Düzbucaqlı",
   "Müxtəliftərəfli"], 1, None, 3),
 ("Üçbucağın perimetri necə tapılır?",
  "Üç tərəfin uzunluqları toplanır.",
  ["Tərəflərin cəmi kimi", "Tərəflərin hasili kimi",
   "Bucaqların cəmi kimi", "Sahənin yarısı kimi"],
  1, None, 1),
 ("Tərəfləri 7 sm və 3 sm olan üçbucağın üçüncü tərəfi 10 sm ola bilərmi?",
  "7 + 3 = 10 — cəm üçüncü tərəfə bərabərdir, üçbucaq alınmaz.",
  ["Xeyr, ola bilməz", "Bəli, olar", "Yalnız düzbucaqlıda",
   "Yalnız bərabəryanlıda"], 1,
  ("Xeyr, ola bilməz" if 7 + 3 <= 10 else "Bəli, olar"), 3),
 ("Bərabərtərəfli üçbucağın neçə simmetriya oxu var?",
  "Hər təpədən bir ox keçir: üç.",
  ["Üç", "Bir", "İki", "Heç bir"], 1, None, 3),
],
"riy-6-sahe-hecm": [
 ("Tərəfi 12 sm olan kvadratın sahəsi neçədir?",
  "S = 12² = 144 sm².",
  ["144 sm²", "48 sm²", "24 sm²", "121 sm²"], 1,
  "%d sm²" % (12 ** 2), 2),
 ("Uzunluğu 9 sm, eni 4 sm olan düzbucaqlının sahəsini tapın.",
  "S = 9 · 4 = 36 sm².",
  ["36 sm²", "13 sm²", "26 sm²", "72 sm²"], 1,
  "%d sm²" % (9 * 4), 2),
 ("Diaqonalları 6 sm və 8 sm olan rombun sahəsi neçədir?",
  "S = (6 · 8) : 2 = 24 sm².",
  ["24 sm²", "48 sm²", "14 sm²", "28 sm²"], 1,
  "%d sm²" % (6 * 8 // 2), 3),
 ("Tili 3 sm olan kubun tam səthinin sahəsi neçədir?",
  "Bir üz 9 sm²; altı üz: 6 · 9 = 54 sm².",
  ["54 sm²", "27 sm²", "18 sm²", "36 sm²"], 1,
  "%d sm²" % (6 * 3 ** 2), 3),
 ("Akvariumun ölçüləri 10 sm, 6 sm və 2 sm-dir. Həcmini tapın.",
  "V = 10 · 6 · 2 = 120 sm³.",
  ["120 sm³", "18 sm³", "60 sm³", "240 sm³"], 1,
  "%d sm³" % (10 * 6 * 2), 2),
 ("Bir kvadratmetrdə neçə kvadrat santimetr var?",
  "1 m = 100 sm; 100 · 100 = 10 000 sm².",
  ["10 000 sm²", "100 sm²", "1 000 sm²", "10 sm²"], 1,
  "%s sm²" % fmt(100 * 100), 3),
 ("Həcmi 64 sm³ olan kubun tili neçədir?",
  "4³ = 64 — til 4 sm.",
  ["4 sm", "8 sm", "16 sm", "32 sm"], 1,
  "%d sm" % round(64 ** (1 / 3)), 3),
 ("Sahəsi 45 sm², hündürlüyü 9 sm olan üçbucağın oturacağı neçədir?",
  "a = 2S : h = 90 : 9 = 10 sm.",
  ["10 sm", "5 sm", "36 sm", "405 sm"], 1,
  "%d sm" % (2 * 45 // 9), 3),
 ("Litr hansı kəmiyyətin ölçü vahididir?",
  "Litr həcm vahididir.",
  ["Həcmin", "Sahənin", "Uzunluğun", "Kütlənin"],
  1, None, 1),
 ("Perimetri 20 sm olan kvadratın sahəsi neçədir?",
  "Tərəf 5 sm; S = 25 sm².",
  ["25 sm²", "20 sm²", "400 sm²", "10 sm²"], 1,
  "%d sm²" % ((20 // 4) ** 2), 3),
],
"riy-6-statistika": [
 ("Zər atılanda 4-dən kiçik ədəd düşməsi ehtimalı neçədir?",
  "Uyğun üzlər: 1, 2, 3 — 3/6 = 1/2.",
  ["1/2", "1/3", "2/3", "1/4"], 1, kesr(Fraction(3, 6)), 3),
 ("10, 20, 30, 40 və 50 ədədlərinin ədədi ortası neçədir?",
  "150 : 5 = 30.",
  ["30", "50", "150", "25"], 1,
  str((10 + 20 + 30 + 40 + 50) // 5), 2),
 ("Qutuda 7 ağ və 3 qara kürəcik var. Qara kürəcik çıxarma ehtimalı neçədir?",
  "3/10.",
  ["3/10", "7/10", "3/7", "1/3"], 1, kesr(Fraction(3, 10)), 3),
 ("25, 13, 25, 8, 25 siyahısında ən çox rast gəlinən qiymət hansıdır?",
  "25 üç dəfə təkrarlanır — moda 25-dir.",
  ["25", "13", "8", "96"], 1,
  str(max((25, 13, 25, 8, 25), key=(25, 13, 25, 8, 25).count)), 2),
 ("Sikkə bir dəfə atıldıqda gerbin düşmə şansı nə qədərdir?",
  "İki bərabər imkandan biri.",
  ["1/2 (yarı-yarıya)", "1/4", "1", "2"], 1, None, 2),
 ("4, 9, 13, 20 sırasının medianı neçədir?",
  "Cüt saylı sırada ortadakı ikisinin ortası: (9 + 13) : 2 = 11.",
  ["11", "9", "13", "46"], 1, str((9 + 13) // 2), 3),
 ("Ehtimalı 1 olan hadisə necə adlanır?",
  "Mütləq baş verən hadisə yəqin hadisədir.",
  ["Yəqin hadisə", "Mümkünsüz hadisə", "Təsadüfi hadisə",
   "Qeyri-müəyyən hadisə"], 1, None, 2),
 ("Ehtimalı 0 olan hadisə necə adlanır?",
  "Baş verə bilməyən hadisə mümkünsüz hadisədir.",
  ["Mümkünsüz hadisə", "Yəqin hadisə", "Adi hadisə",
   "Kiçik hadisə"], 1, None, 2),
 ("Dairəvi diaqram nəyi göstərmək üçün əlverişlidir?",
  "Tamın hissələrə necə bölündüyünü göstərir.",
  ["Tamın hissələrə bölünməsini", "Zamanla dəyişməni",
   "Məsafəni", "Temperaturu"], 1, None, 3),
 ("Məlumat toplamaq üçün verilən suallar siyahısı necə adlanır?",
  "Bu, anketdir (sorğu vərəqidir).",
  ["Anket (sorğu vərəqi)", "Lüğət", "Cədvəl", "Xəritə"],
  1, None, 1),
],
}
for _k, _v in ELAVE.items():
    SUALLAR[_k] = SUALLAR[_k] + _v


def yoxla():
    n = xeta = 0
    butun = set()
    for movzu, siyahi in SUALLAR.items():
        assert movzu in RUBLAR, movzu
        if len(siyahi) != 20:
            print("XETA  %s: %d sual (20 olmalidir)" % (movzu, len(siyahi)))
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
--  9 movzu x 20 sual = %d.  ext_key: riy6-<movzu>#<sira>.
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
