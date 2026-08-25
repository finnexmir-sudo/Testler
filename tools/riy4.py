#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Riyaziyyat 4 ucun platforma sual banki -> db/16_bank_riy4.sql

Suallar ORIJINALDIR - e-derslikden yalniz movzu adlari goturulub,
calismalar goturulmeyib (muellif huququ).  Movzular 15_movzular_ederslik.sql
agacina uygundur: 12 movzu x 10 sual = 120.

HER RIYAZI CAVAB PROQRAMLA YOXLANIR: "expect" sahesi cavabi yeniden
hesablayir ve duzgun variantla tutusdurur.  Metn cavablarda (movzu adi,
qayda) expect None-dur - orada yalniz struktur yoxlanir.

Isletmek:
    python3 tools/riy4.py        # yoxlayir ve SQL yazir
"""
import io
import itertools
import os

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CIXIS = os.path.join(KOK, "db", "16_bank_riy4.sql")


def fmt(n):
    """1000-den boyuk ededleri kitabdaki kimi bosluqla qruplasdirir."""
    return format(n, ",").replace(",", " ")


def man(qepik):
    """Qepikle verilen mebleg -> «X man YY qəp» / «X manat» / «YY qəpik»."""
    m, q = divmod(qepik, 100)
    if m and q:
        return "%d man %02d qəp" % (m, q)
    if m:
        return "%d manat" % m
    return "%d qəpik" % q


def dec(x):
    """Onluq kesr vergulle: 6.2 -> «6,2», 6.0 -> «6»."""
    s = ("%g" % x).replace(".", ",")
    return s


# Har element: (movzu, [(body, why, opts, correct(1-4), expect, diff), ...])
# expect: None ve ya str - duzgun variantla EYNI olmali metn.

RUBLAR = {
    "riy-4-coxreqemli": 1, "riy-4-toplama-cixma": 1, "riy-4-vurma-bolme": 1,
    "riy-4-ifade-tenlik": 2, "riy-4-vurma-bolme-2": 2, "riy-4-fiqurlar": 2,
    "riy-4-kesr": 3, "riy-4-onluq-kesr": 3, "riy-4-pullar": 3,
    "riy-4-olcme": 4, "riy-4-melumat": 4, "riy-4-mesele": 4,
}

en_kicik_4req = min(
    int("".join(map(str, p))) for p in itertools.permutations([2, 0, 4, 7])
    if p[0] != 0)

SUALLAR = {
"riy-4-coxreqemli": [
 ("«Üç yüz qırx beş min iki yüz on səkkiz» ədədi rəqəmlə necə yazılır?",
  "300 000 + 45 000 + 218 = 345 218.",
  ["345 218", "34 518", "345 281", "3 045 218"], 1, fmt(345218), 2),
 ("507 090 ədədində minlər mərtəbəsində hansı rəqəm durur?",
  "507 090 — burada 507 min var: minlər mərtəbəsində 7-dir.",
  ["7", "0", "5", "9"], 1, str(507090 // 1000 % 10), 2),
 ("82 356 ədədini yüzlüklərə qədər yuvarlaqlaşdırın.",
  "Onluqlar mərtəbəsində 5 olduğu üçün yuxarı yuvarlaqlaşır.",
  ["82 400", "82 300", "82 000", "82 360"], 1,
  fmt((82356 + 50) // 100 * 100), 2),
 ("Ədədlər hansı sırada artan ardıcıllıqla düzülüb?",
  "Əvvəl minlər, sonra yüzlər müqayisə olunur: 9 099 < 9 909 < 9 990.",
  ["9 099, 9 909, 9 990", "9 909, 9 099, 9 990",
   "9 990, 9 909, 9 099", "9 099, 9 990, 9 909"], 1, None, 2),
 ("199 999 ədədindən bilavasitə sonra gələn ədəd hansıdır?",
  "Sonra gələn ədəd 1 vahid çoxdur: 199 999 + 1 = 200 000.",
  ["200 000", "199 998", "210 000", "199 990"], 1, fmt(199999 + 1), 1),
 ("Tərkibində 6 yüzminlik, 3 minlik və 8 təklik olan ədəd hansıdır?",
  "600 000 + 3 000 + 8 = 603 008.",
  ["603 008", "63 008", "600 308", "603 800"], 1,
  fmt(6 * 100000 + 3 * 1000 + 8), 3),
 ("745 632 ədədində 4 rəqəmi hansı mərtəbədə durur?",
  "745 632: 7 — yüz minlər, 4 — on minlər, 5 — minlər mərtəbəsidir.",
  ["On minlər", "Minlər", "Yüz minlər", "Yüzlər"], 1, None, 2),
 ("Ən böyük beşrəqəmli ədədlə ən kiçik beşrəqəmli ədədin fərqi neçədir?",
  "99 999 − 10 000 = 89 999.",
  ["89 999", "90 000", "99 999", "89 990"], 1, fmt(99999 - 10000), 3),
 ("340 500 ədədini minliklərə qədər yuvarlaqlaşdırın.",
  "Yüzlər mərtəbəsində 5 olduğundan yuxarı yuvarlaqlaşır.",
  ["341 000", "340 000", "340 500", "350 000"], 1,
  fmt((340500 + 500) // 1000 * 1000), 3),
 ("2, 0, 4, 7 rəqəmlərinin hər birini bir dəfə işlətməklə yazıla bilən "
  "ən kiçik dördrəqəmli ədəd hansıdır?",
  "Ədəd 0 ilə başlaya bilməz, ona görə ən kiçiyi 2 047-dir.",
  ["2 047", "2 074", "2 407", "7 420"], 1, fmt(en_kicik_4req), 3),
],
"riy-4-toplama-cixma": [
 ("45 236 + 28 457 əməlini yerinə yetirin.",
  "Mərtəbə-mərtəbə toplayın: 45 236 + 28 457 = 73 693.",
  ["73 693", "73 583", "73 793", "63 693"], 1, fmt(45236 + 28457), 2),
 ("60 000 − 24 375 fərqini tapın.",
  "Sıfırlardan borc alınır: 60 000 − 24 375 = 35 625.",
  ["35 625", "35 635", "36 625", "45 625"], 1, fmt(60000 - 24375), 2),
 ("123 456 + 76 544 cəmini hesablayın.",
  "123 456 + 76 544 = 200 000.",
  ["200 000", "199 000", "200 010", "190 000"], 1, fmt(123456 + 76544), 2),
 ("İki ədədin cəmi 90 000-dir. Onlardan biri 36 250 olarsa, o biri neçədir?",
  "90 000 − 36 250 = 53 750.",
  ["53 750", "54 750", "53 250", "63 750"], 1, fmt(90000 - 36250), 2),
 ("500 000 − 123 456 neçə edər?",
  "500 000 − 123 456 = 376 544.",
  ["376 544", "376 644", "386 544", "377 544"], 1, fmt(500000 - 123456), 3),
 ("8 704 + 12 296 cəmini tapın.",
  "8 704 + 12 296 = 21 000.",
  ["21 000", "20 990", "21 100", "20 000"], 1, fmt(8704 + 12296), 1),
 ("Çıxılan 40 000, fərq 15 380-dirsə, çıxan neçədir?",
  "Çıxan = çıxılan − fərq = 40 000 − 15 380 = 24 620.",
  ["24 620", "25 620", "24 720", "55 380"], 1, fmt(40000 - 15380), 3),
 ("25 634 + 25 634 neçə edər?",
  "Ədədin 2 misli: 25 634 + 25 634 = 51 268.",
  ["51 268", "50 268", "51 168", "51 368"], 1, fmt(25634 + 25634), 1),
 ("71 205 − 34 618 fərqini tapıb toplama ilə yoxlayın.",
  "36 587 + 34 618 = 71 205 — deməli fərq düzgündür.",
  ["36 587", "36 687", "37 587", "36 597"], 1, fmt(71205 - 34618), 2),
 ("Ardıcıl iki natural ədədin cəmi 4 001-dir. Kiçik ədədi tapın.",
  "(4 001 − 1) : 2 = 2 000; ədədlər 2 000 və 2 001-dir.",
  ["2 000", "2 001", "1 999", "2 500"], 1, fmt((4001 - 1) // 2), 3),
],
"riy-4-vurma-bolme": [
 ("1 234 × 4 hasilini tapın.",
  "1 234 × 4 = 4 936.",
  ["4 936", "4 836", "4 946", "5 936"], 1, fmt(1234 * 4), 1),
 ("2 508 × 7 neçə edər?",
  "2 508 × 7 = 17 556.",
  ["17 556", "17 456", "18 556", "17 656"], 1, fmt(2508 * 7), 2),
 ("9 648 : 8 qismətini tapın.",
  "9 648 : 8 = 1 206.",
  ["1 206", "1 216", "1 106", "1 260"], 1, fmt(9648 // 8), 2),
 ("15 435 : 5 neçə edər?",
  "15 435 : 5 = 3 087.",
  ["3 087", "3 187", "3 077", "3 870"], 1, fmt(15435 // 5), 2),
 ("3 006 × 9 hasilini hesablayın.",
  "3 006 × 9 = 27 054; aradakı sıfırlar unudulmamalıdır.",
  ["27 054", "27 154", "26 954", "27 540"], 1, fmt(3006 * 9), 2),
 ("36 000 : 6 neçə edər?",
  "36 : 6 = 6, deməli 36 000 : 6 = 6 000.",
  ["6 000", "600", "6 100", "60 000"], 1, fmt(36000 // 6), 1),
 ("7 214 × 6 hasilini tapın.",
  "7 214 × 6 = 43 284.",
  ["43 284", "43 184", "42 284", "43 294"], 1, fmt(7214 * 6), 3),
 ("45 927 : 9 qismətini hesablayın.",
  "45 927 : 9 = 5 103.",
  ["5 103", "5 113", "5 013", "5 130"], 1, fmt(45927 // 9), 3),
 ("48 ədədinin bütün bölənləri hansı sırada tam göstərilib?",
  "Hər biri 48-i qalıqsız bölür və siyahı tam olmalıdır.",
  ["1, 2, 3, 4, 6, 8, 12, 16, 24, 48",
   "1, 2, 4, 6, 8, 12, 24, 48",
   "2, 3, 4, 6, 8, 12, 16, 24",
   "1, 2, 3, 4, 6, 8, 12, 24, 48"], 1,
  ", ".join(str(d) for d in range(1, 49) if 48 % d == 0), 3),
 ("Hasil 5 600-dür. Vuruqlardan biri 8 olarsa, o biri neçədir?",
  "Naməlum vuruq = hasil : məlum vuruq = 5 600 : 8 = 700.",
  ["700", "70", "800", "7 000"], 1, fmt(5600 // 8), 2),
],
"riy-4-ifade-tenlik": [
 ("36 + 24 : 6 ifadəsinin qiymətini tapın.",
  "Əvvəl bölmə: 24 : 6 = 4; sonra 36 + 4 = 40.",
  ["40", "10", "42", "30"], 1, str(36 + 24 // 6), 2),
 ("x + 250 = 600 tənliyində x-i tapın.",
  "x = 600 − 250 = 350.",
  ["350", "850", "450", "250"], 1, str(600 - 250), 1),
 ("x · 8 = 720 tənliyinin kökü neçədir?",
  "x = 720 : 8 = 90.",
  ["90", "80", "5 760", "712"], 1, str(720 // 8), 2),
 ("(90 − 54) : 4 ifadəsinin qiyməti neçədir?",
  "Əvvəl mötərizə: 90 − 54 = 36; sonra 36 : 4 = 9.",
  ["9", "36", "13", "18"], 1, str((90 - 54) // 4), 2),
 ("x : 7 = 60 tənliyində x neçədir?",
  "Bölünən = qismət · bölən = 60 · 7 = 420.",
  ["420", "67", "8", "350"], 1, str(60 * 7), 2),
 ("5 · (18 − 9) + 12 ifadəsini hesablayın.",
  "5 · 9 = 45; 45 + 12 = 57.",
  ["57", "45", "93", "62"], 1, str(5 * (18 - 9) + 12), 3),
 ("100 − x = 37 tənliyinin kökü neçədir?",
  "x = 100 − 37 = 63.",
  ["63", "137", "73", "53"], 1, str(100 - 37), 1),
 ("640 : 8 · 3 ifadəsinin qiymətini tapın.",
  "Bölmə və vurma soldan sağa yerinə yetirilir: 80 · 3 = 240.",
  ["240", "27", "80", "1 920"], 1, fmt(640 // 8 * 3), 3),
 ("a = 25, b = 4 olduqda a · b − a ifadəsinin qiyməti neçədir?",
  "25 · 4 = 100; 100 − 25 = 75.",
  ["75", "100", "4", "79"], 1, str(25 * 4 - 25), 3),
 ("Tənliyi həll edin: 3 · x = 96.",
  "x = 96 : 3 = 32.",
  ["32", "93", "99", "288"], 1, str(96 // 3), 2),
],
"riy-4-vurma-bolme-2": [
 ("240 × 10 neçə edər?",
  "10-a vuranda ədədin sağına bir sıfır əlavə olunur.",
  ["2 400", "240", "24 000", "2 500"], 1, fmt(240 * 10), 1),
 ("35 600 : 100 neçə edər?",
  "100-ə bölanda sağdan iki sıfır atılır.",
  ["356", "3 560", "36", "355"], 1, str(35600 // 100), 1),
 ("46 × 25 hasilini tapın.",
  "46 × 25 = 46 × 100 : 4 = 1 150.",
  ["1 150", "1 050", "1 140", "1 250"], 1, fmt(46 * 25), 2),
 ("84 × 36 neçə edər?",
  "84 × 36 = 84 × 30 + 84 × 6 = 2 520 + 504 = 3 024.",
  ["3 024", "3 004", "2 924", "3 124"], 1, fmt(84 * 36), 3),
 ("1 728 : 12 qismətini hesablayın.",
  "1 728 : 12 = 144.",
  ["144", "134", "154", "1 440"], 1, str(1728 // 12), 3),
 ("950 : 25 neçə edər?",
  "950 : 25 = 38, çünki 25 × 38 = 950.",
  ["38", "36", "45", "380"], 1, str(950 // 25), 2),
 ("70 × 40 hasilini tapın.",
  "7 × 4 = 28; sıfırları əlavə edin: 2 800.",
  ["2 800", "2 400", "280", "2 700"], 1, fmt(70 * 40), 1),
 ("13 × 15 neçə edər?",
  "13 × 15 = 13 × 10 + 13 × 5 = 130 + 65 = 195.",
  ["195", "185", "205", "145"], 1, str(13 * 15), 2),
 ("2 448 : 24 qismətini tapın.",
  "2 448 : 24 = 102; qismətdəki sıfır unudulmamalıdır.",
  ["102", "12", "120", "112"], 1, str(2448 // 24), 3),
 ("72 × 50 hasilini hesablayın.",
  "72 × 5 = 360; bir sıfır əlavə edin: 3 600.",
  ["3 600", "360", "3 500", "3 700"], 1, fmt(72 * 50), 2),
],
"riy-4-fiqurlar": [
 ("Tərəfi 8 sm olan kvadratın perimetrini tapın.",
  "P = 4 · a = 4 · 8 = 32 sm.",
  ["32 sm", "16 sm", "64 sm", "24 sm"], 1, "%d sm" % (4 * 8), 1),
 ("Uzunluğu 12 sm, eni 7 sm olan düzbucaqlının sahəsini tapın.",
  "S = a · b = 12 · 7 = 84 sm².",
  ["84 sm²", "38 sm²", "19 sm²", "74 sm²"], 1, "%d sm²" % (12 * 7), 2),
 ("Perimetri 36 sm olan kvadratın tərəfi neçə santimetrdir?",
  "a = P : 4 = 36 : 4 = 9 sm.",
  ["9 sm", "6 sm", "12 sm", "18 sm"], 1, "%d sm" % (36 // 4), 2),
 ("Düzbucaqlının sahəsi 96 sm², uzunluğu 12 sm-dir. Enini tapın.",
  "b = S : a = 96 : 12 = 8 sm.",
  ["8 sm", "84 sm", "6 sm", "12 sm"], 1, "%d sm" % (96 // 12), 3),
 ("Tərəfləri 7 sm, 9 sm və 12 sm olan üçbucağın perimetri neçədir?",
  "P = 7 + 9 + 12 = 28 sm.",
  ["28 sm", "26 sm", "30 sm", "63 sm"], 1, "%d sm" % (7 + 9 + 12), 1),
 ("Sahəsi 49 sm² olan kvadratın tərəfi neçə santimetrdir?",
  "7 · 7 = 49, deməli tərəf 7 sm-dir.",
  ["7 sm", "12 sm", "14 sm", "9 sm"], 1, "7 sm", 2),
 ("Düz bucaq neçə dərəcədir?",
  "Düz bucaq 90°-dir.",
  ["90°", "45°", "180°", "60°"], 1, None, 1),
 ("Uzunluğu 15 sm, eni 4 sm olan düzbucaqlının perimetrini tapın.",
  "P = 2 · (15 + 4) = 38 sm.",
  ["38 sm", "60 sm", "19 sm", "34 sm"], 1, "%d sm" % (2 * (15 + 4)), 2),
 ("Kubun neçə üzü var?",
  "Kubun 6 üzü, 12 tili, 8 təpəsi var.",
  ["6", "4", "8", "12"], 1, None, 2),
 ("1 m² neçə kvadrat santimetrdir?",
  "1 m = 100 sm; 100 · 100 = 10 000 sm².",
  ["10 000 sm²", "100 sm²", "1 000 sm²", "100 000 sm²"], 1,
  "%s sm²" % fmt(100 * 100), 3),
],
"riy-4-kesr": [
 ("3/8 və 5/8 kəsrlərindən hansı böyükdür?",
  "Məxrəclər eynidirsə, surəti böyük olan kəsr böyükdür.",
  ["5/8", "3/8", "Bərabərdirlər", "Müqayisə etmək olmaz"], 1, None, 1),
 ("60-ın 1/5 hissəsi neçədir?",
  "60 : 5 = 12.",
  ["12", "5", "20", "300"], 1, str(60 // 5), 2),
 ("84-ün 3/7 hissəsini tapın.",
  "84 : 7 = 12; 12 · 3 = 36.",
  ["36", "12", "28", "63"], 1, str(84 // 7 * 3), 3),
 ("Hansı ədədin 1/6 hissəsi 9-a bərabərdir?",
  "9 · 6 = 54.",
  ["54", "15", "45", "3"], 1, str(9 * 6), 3),
 ("1/2, 1/3 və 1/4 kəsrlərindən ən böyüyü hansıdır?",
  "Surətlər eynidirsə, məxrəci kiçik olan kəsr böyükdür.",
  ["1/2", "1/3", "1/4", "Hamısı bərabərdir"], 1, None, 2),
 ("45-in 2/9 hissəsi neçədir?",
  "45 : 9 = 5; 5 · 2 = 10.",
  ["10", "5", "18", "90"], 1, str(45 // 9 * 2), 2),
 ("5/5 kəsri nəyə bərabərdir?",
  "Surət məxrəcə bərabərdirsə, kəsr 1 tama bərabərdir.",
  ["1 tam", "0", "5", "1/5"], 1, None, 1),
 ("7/10 kəsrində məxrəc hansı ədəddir?",
  "Kəsr xəttinin altındakı ədəd məxrəcdir.",
  ["10", "7", "17", "70"], 1, None, 1),
 ("100-ün 3/4 hissəsini tapın.",
  "100 : 4 = 25; 25 · 3 = 75.",
  ["75", "25", "30", "60"], 1, str(100 // 4 * 3), 2),
 ("Hansı kəsr 1-dən böyükdür?",
  "Surəti məxrəcindən böyük olan kəsr 1-dən böyükdür.",
  ["9/7", "7/9", "5/5", "3/8"], 1, None, 2),
],
"riy-4-onluq-kesr": [
 ("3,7 + 2,5 cəmini tapın.",
  "Vergüllər alt-alta yazılır: 3,7 + 2,5 = 6,2.",
  ["6,2", "5,2", "6,12", "5,12"], 1, dec(3.7 + 2.5), 2),
 ("5 − 1,8 fərqini hesablayın.",
  "5,0 − 1,8 = 3,2.",
  ["3,2", "4,2", "3,8", "4,8"], 1, dec(5 - 1.8), 2),
 ("0,9 və 0,45 ədədlərindən hansı böyükdür?",
  "0,9 = 0,90; 90 > 45 olduğundan 0,9 böyükdür.",
  ["0,9", "0,45", "Bərabərdirlər", "Müqayisə mümkün deyil"], 1, None, 2),
 ("2,45 + 3,55 neçə edər?",
  "2,45 + 3,55 = 6,00 = 6.",
  ["6", "5,90", "6,10", "5,100"], 1, dec(2.45 + 3.55), 2),
 ("«7 tam onda 3» onluq kəsrlə necə yazılır?",
  "Tam hissə 7, onda birlər 3: 7,3.",
  ["7,3", "7,03", "73", "3,7"], 1, None, 1),
 ("4,6 × 10 neçə edər?",
  "10-a vuranda vergül bir mərtəbə sağa keçir: 46.",
  ["46", "4,60", "460", "0,46"], 1, dec(4.6 * 10), 2),
 ("38 : 10 neçə edər?",
  "10-a bölanda vergül bir mərtəbə sola keçir: 3,8.",
  ["3,8", "0,38", "380", "3,08"], 1, dec(38 / 10), 2),
 ("12,5 − 4,7 fərqini tapın.",
  "12,5 − 4,7 = 7,8.",
  ["7,8", "8,8", "7,2", "8,2"], 1, dec(12.5 - 4.7), 3),
 ("0,25 hansı adi kəsrə bərabərdir?",
  "0,25 = 25/100 = 1/4.",
  ["1/4", "1/2", "2/5", "1/25"], 1, None, 3),
 ("Hansı bərabərlik doğrudur?",
  "Onluq kəsrin sonuna sıfır artırmaq qiymətini dəyişmir.",
  ["1,05 = 1,050", "1,5 = 1,05", "0,3 > 0,30", "2,4 < 2,04"], 1, None, 3),
],
"riy-4-pullar": [
 ("1 manat neçə qəpikdir?",
  "1 manat = 100 qəpik.",
  ["100 qəpik", "10 qəpik", "50 qəpik", "1 000 qəpik"], 1, None, 1),
 ("3 man 45 qəp + 2 man 80 qəp neçə edər?",
  "45 + 80 = 125 qəpik = 1 man 25 qəp; cəmi 6 man 25 qəp.",
  ["6 man 25 qəp", "5 man 25 qəp", "6 man 15 qəp", "5 man 65 qəp"], 1,
  man(345 + 280), 2),
 ("Aysu 10 manatla 2 man 75 qəp ödədi. Qalığı neçədir?",
  "10 man − 2 man 75 qəp = 7 man 25 qəp.",
  ["7 man 25 qəp", "8 man 25 qəp", "7 man 75 qəp", "6 man 25 qəp"], 1,
  man(1000 - 275), 2),
 ("Hər biri 60 qəpik olan 5 dəftərin qiyməti neçədir?",
  "60 · 5 = 300 qəpik = 3 manat.",
  ["3 manat", "2 man 40 qəp", "3 man 60 qəp", "65 qəpik"], 1,
  man(60 * 5), 2),
 ("Qiyməti 12 man 50 qəp olan kitabdan 2 ədəd alındı. Cəmi nə qədər ödənildi?",
  "12 man 50 qəp · 2 = 25 manat.",
  ["25 manat", "24 manat", "25 man 50 qəp", "24 man 50 qəp"], 1,
  man(1250 * 2), 2),
 ("50 qəp + 20 qəp + 20 qəp + 10 qəp neçə edər?",
  "50 + 20 + 20 + 10 = 100 qəpik = 1 manat.",
  ["1 manat", "90 qəpik", "1 man 10 qəp", "80 qəpik"], 1,
  man(50 + 20 + 20 + 10), 1),
 ("Kitab 8 man 40 qəp, jurnal ondan 3 man 15 qəp ucuzdur. "
  "Jurnalın qiyməti neçədir?",
  "8 man 40 qəp − 3 man 15 qəp = 5 man 25 qəp.",
  ["5 man 25 qəp", "5 man 35 qəp", "11 man 55 qəp", "5 man 15 qəp"], 1,
  man(840 - 315), 3),
 ("100 manat 4 nəfər arasında bərabər bölünərsə, hərəyə nə qədər düşər?",
  "100 : 4 = 25 manat.",
  ["25 manat", "20 manat", "40 manat", "50 manat"], 1, man(10000 // 4), 2),
 ("Hər biri 1 man 50 qəp olan 6 şirənin qiyməti neçədir?",
  "1 man 50 qəp · 6 = 9 manat.",
  ["9 manat", "6 man 50 qəp", "7 man 50 qəp", "9 man 50 qəp"], 1,
  man(150 * 6), 2),
 ("7 man 05 qəp − 2 man 30 qəp fərqini tapın.",
  "05 qəpikdən 30 çıxmaq üçün 1 manat xırdalanır: 4 man 75 qəp.",
  ["4 man 75 qəp", "5 man 25 qəp", "4 man 35 qəp", "5 man 75 qəp"], 1,
  man(705 - 230), 3),
],
"riy-4-olcme": [
 ("3 km neçə metrdir?",
  "1 km = 1 000 m; 3 km = 3 000 m.",
  ["3 000 m", "300 m", "30 m", "30 000 m"], 1, "%s m" % fmt(3 * 1000), 1),
 ("250 sm neçə metr, neçə santimetrdir?",
  "250 sm = 200 sm + 50 sm = 2 m 50 sm.",
  ["2 m 50 sm", "25 m", "2 m 5 sm", "20 m 50 sm"], 1, None, 2),
 ("4 500 qram neçə kiloqramdır?",
  "1 000 q = 1 kq; 4 500 q = 4 kq 500 q.",
  ["4 kq 500 q", "45 kq", "4 kq 50 q", "450 kq"], 1, None, 2),
 ("2 saat 30 dəqiqə neçə dəqiqədir?",
  "2 · 60 + 30 = 150 dəqiqə.",
  ["150 dəq", "230 dəq", "120 dəq", "90 dəq"], 1,
  "%d dəq" % (2 * 60 + 30), 2),
 ("1 ton neçə kiloqramdır?",
  "1 t = 1 000 kq.",
  ["1 000 kq", "100 kq", "10 000 kq", "500 kq"], 1, "%s kq" % fmt(1000), 1),
 ("7 m 8 sm neçə santimetrdir?",
  "7 m = 700 sm; 700 + 8 = 708 sm.",
  ["708 sm", "78 sm", "780 sm", "7 008 sm"], 1,
  "%d sm" % (7 * 100 + 8), 3),
 ("3 600 saniyə neçə saatdır?",
  "1 saat = 3 600 saniyə.",
  ["1 saat", "6 saat", "36 saat", "2 saat"], 1,
  "%d saat" % (3600 // 3600), 3),
 ("5 kq − 750 q fərqini tapın.",
  "5 000 q − 750 q = 4 250 q = 4 kq 250 q.",
  ["4 kq 250 q", "4 kq 750 q", "3 kq 250 q", "4 kq 350 q"], 1, None, 3),
 ("1 həftə neçə saatdır?",
  "7 · 24 = 168 saat.",
  ["168 saat", "24 saat", "148 saat", "170 saat"], 1,
  "%d saat" % (7 * 24), 3),
 ("40 mm neçə santimetrdir?",
  "10 mm = 1 sm; 40 mm = 4 sm.",
  ["4 sm", "400 sm", "40 sm", "0,4 sm"], 1, "%d sm" % (40 // 10), 1),
],
"riy-4-melumat": [
 ("Balların siyahısı: Aysu — 85, Kənan — 92, Ləman — 78. "
  "Ən yüksək bal kimindir?",
  "92 > 85 > 78.",
  ["Kənan", "Aysu", "Ləman", "Hamısınınkı bərabərdir"], 1,
  max({"Aysu": 85, "Kənan": 92, "Ləman": 78}.items(), key=lambda kv: kv[1])[0], 1),
 ("Ardıcıllığın qaydasını tapıb davam etdirin: 5, 10, 20, 40, …",
  "Hər ədəd əvvəlkinin 2 mislidir: 40 · 2 = 80.",
  ["80", "50", "60", "100"], 1, str(40 * 2), 2),
 ("Sinifdə 12 oğlan və 14 qız var. Cədvəldə cəmi neçə şagird qeyd olunmalıdır?",
  "12 + 14 = 26.",
  ["26", "24", "28", "2"], 1, str(12 + 14), 1),
 ("Mağazada satış: I gün — 120, II gün — 150, III gün — 90 kitab. "
  "Üç gündə cəmi neçə kitab satılıb?",
  "120 + 150 + 90 = 360.",
  ["360", "350", "270", "460"], 1, str(120 + 150 + 90), 2),
 ("Satış: I gün — 120, II gün — 150, III gün — 90 kitab. "
  "Ən çox satış hansı gündə olub?",
  "150 üç ədədin ən böyüyüdür.",
  ["II gün", "I gün", "III gün", "Hamısında eyni"], 1, None, 1),
 ("Dörd ədədin cəmi 200-dür. Onların ədədi ortası neçədir?",
  "Ədədi orta = cəm : say = 200 : 4 = 50.",
  ["50", "40", "100", "800"], 1, str(200 // 4), 3),
 ("Qaydanı tapın: 2, 5, 11, 23, … Növbəti ədəd hansıdır?",
  "Hər ədəd əvvəlkinin 2 mislindən 1 çoxdur: 23 · 2 + 1 = 47.",
  ["47", "46", "35", "29"], 1, str(23 * 2 + 1), 3),
 ("İdmançı həftədə 5 gün, hər gün 45 dəqiqə məşq edir. "
  "Həftəlik məşq vaxtı neçə dəqiqədir?",
  "5 · 45 = 225 dəqiqə.",
  ["225", "205", "240", "50"], 1, str(5 * 45), 2),
 ("Oyun zərində «7» düşməsi necə hadisədir?",
  "Zərin üzlərində 1-dən 6-ya qədər ədədlər var — 7 düşə bilməz.",
  ["Mümkünsüz", "Mütləq", "Mümkün", "Təsadüfi"], 1, None, 2),
 ("Siyahıdakı ən kiçik ədəd hansıdır: 3 407; 3 470; 3 047; 3 740?",
  "Yüzlər mərtəbəsinə baxın: 0 < 4 < 7.",
  ["3 047", "3 407", "3 470", "3 740"], 1,
  fmt(min(3407, 3470, 3047, 3740)), 2),
],
"riy-4-mesele": [
 ("Məktəb kitabxanasına 3 250 kitab gətirildi. 1 480-i şagirdlərə verildi. "
  "Neçə kitab qaldı?",
  "3 250 − 1 480 = 1 770.",
  ["1 770", "1 870", "1 670", "4 730"], 1, fmt(3250 - 1480), 2),
 ("Bir qutuda 24 karandaş var. 15 belə qutuda neçə karandaş var?",
  "24 · 15 = 360.",
  ["360", "340", "390", "39"], 1, str(24 * 15), 2),
 ("Avtobus 240 km yolu 4 saata getdi. Avtobusun sürətini tapın.",
  "Sürət = yol : vaxt = 240 : 4 = 60 km/saat.",
  ["60 km/saat", "56 km/saat", "80 km/saat", "960 km/saat"], 1,
  "%d km/saat" % (240 // 4), 2),
 ("Anara 5 manat verildi. O, 3 man 40 qəp xərclədi. Nə qədər pulu qaldı?",
  "5 man − 3 man 40 qəp = 1 man 60 qəp.",
  ["1 man 60 qəp", "2 man 60 qəp", "1 man 40 qəp", "2 man 40 qəp"], 1,
  man(500 - 340), 2),
 ("456 şagird 8 bərabər dəstəyə bölündü. Hər dəstədə neçə şagird var?",
  "456 : 8 = 57.",
  ["57", "47", "56", "64"], 1, str(456 // 8), 2),
 ("Bağda 125 alma ağacı var, armud ağacları isə ondan 3 dəfə çoxdur. "
  "Neçə armud ağacı var?",
  "«3 dəfə çox» — vurma deməkdir: 125 · 3 = 375.",
  ["375", "128", "250", "425"], 1, str(125 * 3), 2),
 ("Rəşad hər gün 250 m qaçır. Bir həftədə (7 gün) neçə metr qaçmış olur?",
  "250 · 7 = 1 750 m.",
  ["1 750 m", "1 450 m", "1 700 m", "257 m"], 1,
  "%s m" % fmt(250 * 7), 1),
 ("İki ədədin cəmi 900-dür. Biri o birindən 100 vahid çoxdur. "
  "Böyük ədədi tapın.",
  "(900 + 100) : 2 = 500; kiçik ədəd 400-dür.",
  ["500", "400", "450", "800"], 1, str((900 + 100) // 2), 3),
 ("20 m parçadan hər birinə 4 m gedən neçə pərdə tikmək olar?",
  "20 : 4 = 5.",
  ["5", "4", "16", "80"], 1, str(20 // 4), 1),
 ("240 səhifəlik kitabı Aysu gündə 30 səhifə oxuyur. "
  "Kitabı neçə günə bitirər?",
  "240 : 30 = 8 gün.",
  ["8", "7", "6", "12"], 1, str(240 // 30), 2),
],
}


def yoxla():
    n = 0
    xeta = 0
    butun_bodiler = set()
    for movzu, siyahi in SUALLAR.items():
        assert movzu in RUBLAR, movzu
        for body, why, opts, correct, expect, diff in siyahi:
            n += 1
            problemler = []
            if len(opts) != 4:
                problemler.append("variant sayi %d" % len(opts))
            if len(set(opts)) != len(opts):
                problemler.append("tekrar variant")
            if not (1 <= correct <= 4):
                problemler.append("correct=%s" % correct)
            if not (1 <= len(body) <= 2000):
                problemler.append("body uzunlugu")
            if not why:
                problemler.append("izah bos")
            if diff not in (1, 2, 3):
                problemler.append("cetinlik=%s" % diff)
            if body in butun_bodiler:
                problemler.append("eyni sual iki defe")
            butun_bodiler.add(body)
            if expect is not None and opts[correct - 1] != expect:
                problemler.append("hesablanan «%s» != variant «%s»"
                                  % (expect, opts[correct - 1]))
            for txt in [body, why] + opts:
                if "'" in txt:
                    problemler.append("apostrof var (SQL-de qacisi cetinlesdirir)")
            if problemler:
                xeta += 1
                print("XETA  %s: %s\n      %s" % (movzu, body[:60], "; ".join(problemler)))
    say_hes = sum(1 for s in SUALLAR.values() for q in s if q[4] is not None)
    print("%d sual yoxlandı (%d-i hesabla təsdiqləndi), %d xəta"
          % (n, say_hes, xeta))
    return xeta == 0, n


def sql_yaz(n):
    q = lambda t: t.replace("'", "''")
    setirler = []
    for movzu in RUBLAR:                      # sira sabitdir
        qisa = movzu.replace("riy-4-", "")
        for i, (body, why, opts, correct, _e, diff) in enumerate(SUALLAR[movzu], 1):
            setirler.append(
                "('riy4-%s#%d','%s',%d,%d,'%s','%s',array['%s','%s','%s','%s'],%d)"
                % (qisa, i, movzu, diff, RUBLAR[movzu], q(body), q(why),
                   q(opts[0]), q(opts[1]), q(opts[2]), q(opts[3]), correct))
    with io.open(CIXIS, "w", encoding="utf-8") as f:
        f.write("""-- =====================================================================
--  16_bank_riy4.sql : RIYAZIYYAT 4 PLATFORMA SUAL BANKI
--
--  BU FAYL ELLE YAZILMIR - tools/riy4.py yaradir:
--      python3 tools/riy4.py
--  Skript her riyazi cavabi YENIDEN HESABLAYIB duzgun variantla
--  tutusdurur, sonra bu SQL-i cixarir.  Duzelis skriptde edilir.
--
--  12 movzu x 10 sual = %d.  Suallar orijinaldir - e-derslikden
--  yalniz movzu adlari goturulub (15_movzular_ederslik.sql).
--
--  Suallar ext_key ile taninir (riy4-<movzu>#<sira>) - tekrar
--  isledilende coxalmir, uzerine yazilir.  07-deki qayda ile:
--  suallar SILINMIR (test_questions restrict), yalniz variantlar
--  temizlenib yeniden yazilir.
--
--  ON SERT: 15_movzular_ederslik.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (
    select 1 from public.topics t
      join public.subjects s on s.id = t.subject_id
     where s.slug = 'riyaziyyat' and t.slug = 'riy-4-coxreqemli') then
    raise exception 'ONCE 15_movzular_ederslik.sql isledilmelidir (riy-4-* movzulari yoxdur).';
  end if;
end $$;

-- Kohne variantlar temizlenir (suallar yox - onlara cavablar bagli ola biler)
delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and q.ext_key like 'riy4-%%';

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
    join public.programs p on p.slug = 'ibtidai'
    join public.levels   l on l.program_id = p.id and l.code = '4'
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

-- ---------------------------------------------------------------- yoxlama
do $$
declare n int; k int; bad text;
begin
  select count(*) into n from public.questions
   where owner_type = 'platform' and ext_key like 'riy4-%%';
  if n <> %d then
    raise exception 'riy4 suallari: %d gozlenilirdi, %% tapildi', n;
  end if;

  select count(*) into k from public.questions q
   where q.ext_key like 'riy4-%%'
     and (select count(*) from public.question_options o
           where o.question_id = q.id) <> 4;
  if k > 0 then
    raise exception '%% sualda variant sayi 4 deyil', k;
  end if;

  select count(*) into k from public.questions q
   where q.ext_key like 'riy4-%%'
     and (select count(*) from public.question_options o
           where o.question_id = q.id and o.is_correct) <> 1;
  if k > 0 then
    raise exception '%% sualda duzgun cavab sayi 1 deyil', k;
  end if;

  select string_agg(distinct t.slug, ', ') into bad
    from public.questions q
    join public.topics t on t.id = q.topic_id
   where q.ext_key like 'riy4-%%'
  having count(distinct t.slug) <> 12;
  if bad is not null then
    raise exception 'movzu sayi 12 deyil: %%', bad;
  end if;

  raise notice 'Riyaziyyat 4 banki: %% sual, 12 movzu.', n;
end $$;
""" % (n, ",\n".join(setirler), n, n))
    print("yazildi: %s" % CIXIS)


if __name__ == "__main__":
    ok, n = yoxla()
    if not ok:
        raise SystemExit(1)
    sql_yaz(n)
