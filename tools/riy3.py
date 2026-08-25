#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Riyaziyyat 3 platforma banki -> db/19_bank_riy3.sql

tools/riy4.py qelibi ile: 12 movzu x 10 sual = 120, her riyazi cavab
YENIDEN HESABLANIB duzgun variantla tutusdurulur.  Movzular
15_movzular_ederslik.sql agacina uygundur (e-derslik Riyaziyyat 3).

DIQQET: 07_seed_tests.sql-in kohne 3-cu sinif suallari ile eyni
reqemler ISLETMEMISIK (6x7, 9x8, 56:8 ve s.) - generator >= 0.95
oxsarligi tekrar sayir, bank ici tekrar da pis gorunur.

Isletmek:
    python3 tools/riy3.py
"""
import io
import os

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CIXIS = os.path.join(KOK, "db", "19_bank_riy3.sql")


def fmt(n):
    return format(n, ",").replace(",", " ")


def man(qepik):
    m, q = divmod(qepik, 100)
    if m and q:
        return "%d man %02d qəp" % (m, q)
    if m:
        return "%d manat" % m
    return "%d qəpik" % q


RUBLAR = {
    "riy-3-ededler-1000": 1, "riy-3-toplama": 1, "riy-3-cixma": 1,
    "riy-3-vurma-bolme": 2, "riy-3-ifade-tenlik": 2, "riy-3-fiqurlar": 2,
    "riy-3-vurma-bolme-2": 3, "riy-3-kesr": 3, "riy-3-ededler-10000": 3,
    "riy-3-olcme": 4, "riy-3-melumat": 4, "riy-3-mesele": 4,
}

SUALLAR = {
"riy-3-ededler-1000": [
 ("«Beş yüz altmış üç» ədədi rəqəmlə necə yazılır?",
  "500 + 60 + 3 = 563.",
  ["563", "536", "653", "530"], 1, str(563), 1),
 ("407 ədədində onluqlar mərtəbəsində hansı rəqəm durur?",
  "407 = 4 yüzlük, 0 onluq, 7 təklik.",
  ["0", "4", "7", "47"], 1, str(407 // 10 % 10), 2),
 ("289 ədədindən bilavasitə sonra gələn ədəd hansıdır?",
  "289 + 1 = 290.",
  ["290", "288", "280", "300"], 1, str(289 + 1), 1),
 ("3 yüzlük, 5 onluq və 2 təklikdən ibarət ədəd hansıdır?",
  "300 + 50 + 2 = 352.",
  ["352", "325", "532", "3502"], 1, str(3 * 100 + 5 * 10 + 2), 2),
 ("Ədədlər hansı sırada azalan ardıcıllıqla düzülüb?",
  "981 > 918 > 891.",
  ["981, 918, 891", "918, 981, 891", "891, 918, 981", "981, 891, 918"],
  1, None, 2),
 ("545 və 554 ədədlərindən hansı böyükdür?",
  "Onluqlar mərtəbəsinə baxın: 5 > 4, deməli 554 böyükdür.",
  ["554", "545", "Bərabərdirlər", "Müqayisə etmək olmaz"], 1,
  str(max(545, 554)), 1),
 ("Ən böyük üçrəqəmli ədəd hansıdır?",
  "Üçrəqəmli ədədlərin ən böyüyü 999-dur.",
  ["999", "998", "900", "1 000"], 1, str(999), 1),
 ("700 + 60 + 4 cəmi hansı ədədi verir?",
  "Mərtəbə toplananlarının cəmi: 764.",
  ["764", "746", "7 604", "674"], 1, str(700 + 60 + 4), 2),
 ("3 yüzlük neçə onluqdur?",
  "1 yüzlük = 10 onluq; 3 yüzlük = 30 onluq.",
  ["30", "3", "300", "13"], 1, str(300 // 10), 3),
 ("Hansı ədəd cütdür?",
  "Sonu 0, 2, 4, 6, 8 ilə bitən ədədlər cütdür.",
  ["348", "431", "567", "209"], 1, None, 2),
],
"riy-3-toplama": [
 ("245 + 132 cəmini tapın.",
  "245 + 132 = 377.",
  ["377", "367", "387", "477"], 1, str(245 + 132), 1),
 ("368 + 254 neçə edər?",
  "368 + 254 = 622; keçidləri unutmayın.",
  ["622", "612", "522", "632"], 1, str(368 + 254), 2),
 ("470 + 280 cəmini hesablayın.",
  "470 + 280 = 750.",
  ["750", "650", "740", "760"], 1, str(470 + 280), 2),
 ("İki ədədin cəmi 600-dür. Onlardan biri 280-dirsə, o biri neçədir?",
  "600 − 280 = 320.",
  ["320", "380", "330", "420"], 1, str(600 - 280), 2),
 ("156 + 244 neçə edər?",
  "156 + 244 = 400.",
  ["400", "390", "410", "300"], 1, str(156 + 244), 2),
 ("305 + 486 cəmini tapın.",
  "305 + 486 = 791.",
  ["791", "781", "891", "701"], 1, str(305 + 486), 2),
 ("623 + 189 neçə edər?",
  "623 + 189 = 812.",
  ["812", "802", "712", "822"], 1, str(623 + 189), 3),
 ("348 + 267 = 267 + ? Bərabərlik doğru olsun deyə sual işarəsinin "
  "yerinə hansı ədəd yazılmalıdır?",
  "Toplananların yeri dəyişəndə cəm dəyişmir.",
  ["348", "267", "615", "81"], 1, str(348), 1),
 ("138 + 162 cəmini hesablayın.",
  "138 + 162 = 300.",
  ["300", "290", "310", "200"], 1, str(138 + 162), 1),
 ("Cəmi 1 000 olan cütü seçin.",
  "550 + 450 = 1 000.",
  ["550 və 450", "540 və 450", "550 və 550", "600 və 500"], 1, None, 3),
],
"riy-3-cixma": [
 ("568 − 234 fərqini tapın.",
  "568 − 234 = 334.",
  ["334", "324", "344", "234"], 1, str(568 - 234), 1),
 ("700 − 358 neçə edər?",
  "Sıfırlardan borc alınır: 700 − 358 = 342.",
  ["342", "352", "442", "332"], 1, str(700 - 358), 2),
 ("903 − 476 fərqini hesablayın.",
  "903 − 476 = 427.",
  ["427", "437", "527", "417"], 1, str(903 - 476), 3),
 ("Çıxılan 600, fərq 250-dirsə, çıxan neçədir?",
  "Çıxan = çıxılan − fərq = 600 − 250 = 350.",
  ["350", "850", "250", "450"], 1, str(600 - 250), 2),
 ("645 − 45 neçə edər?",
  "645 − 45 = 600.",
  ["600", "640", "605", "500"], 1, str(645 - 45), 1),
 ("812 − 407 fərqini tapın.",
  "812 − 407 = 405.",
  ["405", "415", "305", "495"], 1, str(812 - 407), 2),
 ("1 000 − 630 neçə edər?",
  "1 000 − 630 = 370.",
  ["370", "430", "470", "360"], 1, str(1000 - 630), 2),
 ("500 − 213 = 287 əməlini toplama ilə necə yoxlamaq olar?",
  "Fərq + çıxan = çıxılan olmalıdır.",
  ["287 + 213 = 500", "287 − 213 = 74", "500 + 213 = 713",
   "500 + 287 = 787"], 1, None, 2),
 ("555 − 267 fərqini hesablayın.",
  "555 − 267 = 288.",
  ["288", "298", "278", "388"], 1, str(555 - 267), 3),
 ("Hansı ədəddən 140 çıxsaq, 260 alarıq?",
  "260 + 140 = 400.",
  ["400", "120", "300", "260"], 1, str(260 + 140), 3),
],
"riy-3-vurma-bolme": [
 ("7 × 4 neçə edər?",
  "7 × 4 = 28.",
  ["28", "24", "32", "21"], 1, str(7 * 4), 1),
 ("9 × 6 hasilini tapın.",
  "9 × 6 = 54.",
  ["54", "56", "45", "63"], 1, str(9 * 6), 2),
 ("8 × 8 neçə edər?",
  "8 × 8 = 64.",
  ["64", "72", "56", "68"], 1, str(8 * 8), 1),
 ("36 : 4 qismətini tapın.",
  "36 : 4 = 9, çünki 4 × 9 = 36.",
  ["9", "8", "7", "6"], 1, str(36 // 4), 2),
 ("42 : 6 neçə edər?",
  "42 : 6 = 7.",
  ["7", "6", "8", "9"], 1, str(42 // 6), 2),
 ("9 × 9 hasilini hesablayın.",
  "9 × 9 = 81.",
  ["81", "72", "89", "99"], 1, str(9 * 9), 2),
 ("0 × 25 neçə edər?",
  "Sıfırla vurmanın hasili həmişə sıfırdır.",
  ["0", "25", "250", "1"], 1, str(0 * 25), 1),
 ("48 : 6 qismətini tapın.",
  "48 : 6 = 8.",
  ["8", "7", "9", "6"], 1, str(48 // 6), 2),
 ("35 : 5 = 7 bölməsini vurma ilə necə yoxlamaq olar?",
  "Qismət × bölən = bölünən olmalıdır.",
  ["5 × 7 = 35", "35 × 5 = 175", "7 + 5 = 12", "35 − 5 = 30"],
  1, None, 2),
 ("Hasili 24 olan cütü seçin.",
  "4 × 6 = 24.",
  ["4 və 6", "5 və 6", "3 və 9", "4 və 8"], 1, None, 3),
],
"riy-3-ifade-tenlik": [
 ("20 + 30 : 5 ifadəsinin qiymətini tapın.",
  "Əvvəl bölmə: 30 : 5 = 6; sonra 20 + 6 = 26.",
  ["26", "10", "50", "56"], 1, str(20 + 30 // 5), 3),
 ("x + 60 = 140 tənliyində x-i tapın.",
  "x = 140 − 60 = 80.",
  ["80", "200", "90", "70"], 1, str(140 - 60), 1),
 ("x · 4 = 32 tənliyinin kökü neçədir?",
  "x = 32 : 4 = 8.",
  ["8", "28", "36", "128"], 1, str(32 // 4), 2),
 ("(45 − 15) : 5 ifadəsinin qiyməti neçədir?",
  "Əvvəl mötərizə: 45 − 15 = 30; sonra 30 : 5 = 6.",
  ["6", "30", "42", "12"], 1, str((45 - 15) // 5), 2),
 ("x : 3 = 20 tənliyində x neçədir?",
  "x = 20 · 3 = 60.",
  ["60", "23", "17", "50"], 1, str(20 * 3), 2),
 ("90 − x = 55 tənliyinin kökü neçədir?",
  "x = 90 − 55 = 35.",
  ["35", "145", "45", "25"], 1, str(90 - 55), 1),
 ("6 · 3 + 12 ifadəsini hesablayın.",
  "6 · 3 = 18; 18 + 12 = 30.",
  ["30", "90", "21", "36"], 1, str(6 * 3 + 12), 2),
 ("a = 7 olduqda a · 5 ifadəsinin qiyməti neçədir?",
  "7 · 5 = 35.",
  ["35", "12", "57", "75"], 1, str(7 * 5), 2),
 ("100 − (20 + 30) ifadəsinin qiymətini tapın.",
  "Əvvəl mötərizə: 20 + 30 = 50; sonra 100 − 50 = 50.",
  ["50", "110", "80", "70"], 1, str(100 - (20 + 30)), 2),
 ("Hansı yazılış tənlikdir?",
  "Tənlikdə naməlum (x) və bərabərlik işarəsi olur.",
  ["x + 5 = 12", "7 + 5", "12 > 7", "x + 5"], 1, None, 3),
],
"riy-3-fiqurlar": [
 ("Üçbucağın neçə təpəsi var?",
  "Üçbucağın 3 tərəfi, 3 təpəsi, 3 bucağı var.",
  ["3", "4", "2", "6"], 1, None, 1),
 ("Kvadratın tərəfləri haqqında hansı fikir doğrudur?",
  "Kvadratın bütün tərəfləri bərabərdir.",
  ["Hamısı bərabərdir", "Yalnız qarşı tərəflər bərabərdir",
   "Hamısı fərqlidir", "Tərəfi yoxdur"], 1, None, 1),
 ("Tərəfi 6 sm olan kvadratın perimetrini tapın.",
  "P = 4 · 6 = 24 sm.",
  ["24 sm", "12 sm", "36 sm", "10 sm"], 1, "%d sm" % (4 * 6), 2),
 ("Tərəfləri 5 sm, 7 sm və 9 sm olan üçbucağın perimetri neçədir?",
  "P = 5 + 7 + 9 = 21 sm.",
  ["21 sm", "19 sm", "23 sm", "35 sm"], 1, "%d sm" % (5 + 7 + 9), 2),
 ("Uzunluğu 8 sm, eni 3 sm olan düzbucaqlının perimetrini tapın.",
  "P = 2 · (8 + 3) = 22 sm.",
  ["22 sm", "11 sm", "24 sm", "16 sm"], 1, "%d sm" % (2 * (8 + 3)), 3),
 ("Küncləri (təpələri) olmayan fiqur hansıdır?",
  "Dairənin təpəsi və tərəfi yoxdur.",
  ["Dairə", "Kvadrat", "Üçbucaq", "Düzbucaqlı"], 1, None, 1),
 ("Perimetri 20 sm olan kvadratın tərəfi neçə santimetrdir?",
  "a = P : 4 = 20 : 4 = 5 sm.",
  ["5 sm", "4 sm", "10 sm", "16 sm"], 1, "%d sm" % (20 // 4), 3),
 ("Düzbucaqlının neçə bucağı var?",
  "Düzbucaqlının 4 bucağı var və hamısı düz bucaqdır.",
  ["4", "2", "3", "6"], 1, None, 1),
 ("Parça nədir?",
  "Parça düz xəttin iki nöqtə arasındakı hissəsidir.",
  ["Düz xəttin iki nöqtə arasındakı hissəsi", "Sonsuz düz xətt",
   "Əyri xətt", "Dairənin yarısı"], 1, None, 2),
 ("Kubun üzləri hansı fiqurdur?",
  "Kubun 6 üzünün hamısı kvadratdır.",
  ["Kvadrat", "Üçbucaq", "Dairə", "Düzbucaqlı olmayan dördbucaqlı"],
  1, None, 2),
],
"riy-3-vurma-bolme-2": [
 ("23 × 3 hasilini tapın.",
  "23 × 3 = 69.",
  ["69", "66", "63", "96"], 1, str(23 * 3), 1),
 ("45 × 4 neçə edər?",
  "45 × 4 = 180.",
  ["180", "160", "170", "185"], 1, str(45 * 4), 2),
 ("96 : 3 qismətini tapın.",
  "96 : 3 = 32.",
  ["32", "31", "33", "23"], 1, str(96 // 3), 2),
 ("84 : 4 neçə edər?",
  "84 : 4 = 21.",
  ["21", "22", "24", "12"], 1, str(84 // 4), 2),
 ("120 × 4 hasilini hesablayın.",
  "120 × 4 = 480.",
  ["480", "440", "460", "484"], 1, str(120 * 4), 2),
 ("260 × 3 neçə edər?",
  "260 × 3 = 780.",
  ["780", "680", "760", "790"], 1, str(260 * 3), 2),
 ("690 : 3 qismətini tapın.",
  "690 : 3 = 230.",
  ["230", "220", "203", "330"], 1, str(690 // 3), 2),
 ("57 × 2 neçə edər?",
  "57 × 2 = 114.",
  ["114", "104", "124", "112"], 1, str(57 * 2), 1),
 ("17 : 5 bölməsində qismət və qalıq neçədir?",
  "5 × 3 = 15; 17 − 15 = 2: qismət 3, qalıq 2.",
  ["Qismət 3, qalıq 2", "Qismət 2, qalıq 3", "Qismət 3, qalıq 0",
   "Qismət 4, qalıq 3"], 1, None, 3),
 ("800 : 4 neçə edər?",
  "8 : 4 = 2, deməli 800 : 4 = 200.",
  ["200", "20", "240", "400"], 1, str(800 // 4), 1),
],
"riy-3-kesr": [
 ("Tamın yarısı hansı kəsrlə göstərilir?",
  "Yarı — tamın 2 bərabər hissəsindən biridir: 1/2.",
  ["1/2", "2/1", "1/4", "2/2"], 1, None, 1),
 ("1/4 kəsri nəyi bildirir?",
  "Tam 4 bərabər hissəyə bölünüb, onlardan biri götürülüb.",
  ["Tamın 4 bərabər hissəsindən birini", "4 tamı",
   "Tamın 4 mislini", "4 fərqli hissəni"], 1, None, 1),
 ("12-nin 1/3 hissəsi neçədir?",
  "12 : 3 = 4.",
  ["4", "3", "6", "36"], 1, str(12 // 3), 2),
 ("20-nin 1/4 hissəsini tapın.",
  "20 : 4 = 5.",
  ["5", "4", "10", "80"], 1, str(20 // 4), 2),
 ("2/6 və 5/6 kəsrlərindən hansı böyükdür?",
  "Məxrəclər eynidirsə, surəti böyük olan böyükdür.",
  ["5/6", "2/6", "Bərabərdirlər", "Müqayisə etmək olmaz"], 1, None, 2),
 ("1/5 və 1/8 kəsrlərindən hansı böyükdür?",
  "Surətlər eynidirsə, məxrəci kiçik olan böyükdür.",
  ["1/5", "1/8", "Bərabərdirlər", "Müqayisə etmək olmaz"], 1, None, 3),
 ("18-in 2/3 hissəsini tapın.",
  "18 : 3 = 6; 6 · 2 = 12.",
  ["12", "6", "9", "27"], 1, str(18 // 3 * 2), 3),
 ("Kəsrdə xəttin üstündəki ədəd necə adlanır?",
  "Üstdəki — surət, altdakı — məxrəcdir.",
  ["Surət", "Məxrəc", "Qismət", "Vuruq"], 1, None, 1),
 ("8/8 kəsri nəyə bərabərdir?",
  "Surət məxrəcə bərabərdirsə, kəsr 1 tama bərabərdir.",
  ["1 tam", "0", "8", "1/8"], 1, None, 2),
 ("24-ün 1/2 hissəsi ilə 1/4 hissəsinin fərqi neçədir?",
  "24 : 2 = 12; 24 : 4 = 6; 12 − 6 = 6.",
  ["6", "12", "18", "3"], 1, str(24 // 2 - 24 // 4), 3),
],
"riy-3-ededler-10000": [
 ("«İki min dörd yüz on» ədədi rəqəmlə necə yazılır?",
  "2 000 + 400 + 10 = 2 410.",
  ["2 410", "2 401", "24 010", "2 041"], 1, fmt(2410), 1),
 ("3 999 ədədindən sonra gələn ədəd hansıdır?",
  "3 999 + 1 = 4 000.",
  ["4 000", "3 998", "3 000", "4 999"], 1, fmt(3999 + 1), 1),
 ("5 306 ədədində yüzlər mərtəbəsində hansı rəqəm durur?",
  "5 306: 5 — minlər, 3 — yüzlər, 0 — onluqlar, 6 — təkliklər.",
  ["3", "5", "0", "6"], 1, str(5306 // 100 % 10), 2),
 ("4 minlik və 7 yüzlükdən ibarət ədəd hansıdır?",
  "4 000 + 700 = 4 700.",
  ["4 700", "4 070", "47 000", "4 007"], 1, fmt(4 * 1000 + 700), 2),
 ("6 099 və 6 100 ədədlərindən hansı böyükdür?",
  "6 100 = 6 099 + 1.",
  ["6 100", "6 099", "Bərabərdirlər", "Müqayisə etmək olmaz"], 1,
  fmt(max(6099, 6100)), 2),
 ("1 manat neçə qəpikdir?",
  "1 manat = 100 qəpik.",
  ["100 qəpik", "10 qəpik", "1 000 qəpik", "60 qəpik"], 1, None, 1),
 ("2 man 50 qəp + 1 man 50 qəp neçə edər?",
  "50 + 50 = 100 qəpik = 1 manat; cəmi 4 manat.",
  ["4 manat", "3 manat", "3 man 50 qəp", "4 man 50 qəp"], 1,
  man(250 + 150), 2),
 ("Alıcı 5 manatla 3 man 20 qəp ödədi. Qalığı neçədir?",
  "5 man − 3 man 20 qəp = 1 man 80 qəp.",
  ["1 man 80 qəp", "2 man 20 qəp", "1 man 20 qəp", "2 man 80 qəp"], 1,
  man(500 - 320), 3),
 ("Ən kiçik dördrəqəmli ədəd hansıdır?",
  "Dördrəqəmli ədədlər 1 000-dən başlayır.",
  ["1 000", "1 001", "9 999", "100"], 1, fmt(1000), 2),
 ("9 999 + 1 neçə edər?",
  "9 999 + 1 = 10 000.",
  ["10 000", "9 998", "99 991", "10 999"], 1, fmt(9999 + 1), 2),
],
"riy-3-olcme": [
 ("1 metr neçə santimetrdir?",
  "1 m = 100 sm.",
  ["100 sm", "10 sm", "1 000 sm", "60 sm"], 1, None, 1),
 ("4 metr neçə santimetrdir?",
  "4 · 100 = 400 sm.",
  ["400 sm", "40 sm", "4 000 sm", "104 sm"], 1, "%d sm" % (4 * 100), 1),
 ("1 saat neçə dəqiqədir?",
  "1 saat = 60 dəqiqə.",
  ["60 dəq", "100 dəq", "30 dəq", "24 dəq"], 1, None, 1),
 ("300 sm neçə metrdir?",
  "300 : 100 = 3 m.",
  ["3 m", "30 m", "13 m", "300 m"], 1, "%d m" % (300 // 100), 2),
 ("2 kiloqram neçə qramdır?",
  "1 kq = 1 000 q; 2 kq = 2 000 q.",
  ["2 000 q", "200 q", "20 q", "1 002 q"], 1, "%s q" % fmt(2 * 1000), 2),
 ("1 dəqiqə neçə saniyədir?",
  "1 dəq = 60 saniyə.",
  ["60 saniyə", "100 saniyə", "30 saniyə", "10 saniyə"], 1, None, 2),
 ("5 m 20 sm neçə santimetrdir?",
  "5 m = 500 sm; 500 + 20 = 520 sm.",
  ["520 sm", "52 sm", "5 020 sm", "502 sm"], 1,
  "%d sm" % (5 * 100 + 20), 3),
 ("Yarım saat neçə dəqiqədir?",
  "60 : 2 = 30 dəqiqə.",
  ["30 dəq", "50 dəq", "15 dəq", "45 dəq"], 1, "%d dəq" % (60 // 2), 2),
 ("1 500 qram neçə kiloqram, neçə qramdır?",
  "1 500 q = 1 000 q + 500 q = 1 kq 500 q.",
  ["1 kq 500 q", "15 kq", "1 kq 50 q", "150 kq"], 1, None, 3),
 ("Termometr nəyi ölçür?",
  "Termometr temperaturu (istiliyi) ölçür.",
  ["Temperaturu", "Uzunluğu", "Kütləni", "Vaxtı"], 1, None, 1),
],
"riy-3-melumat": [
 ("Satış cədvəli: alma — 12 kq, armud — 8 kq, gilas — 15 kq. "
  "Ən çox hansı meyvə satılıb?",
  "15 > 12 > 8.",
  ["Gilas", "Alma", "Armud", "Hamısı bərabər"], 1, None, 1),
 ("Həmin cədvələ görə cəmi neçə kiloqram meyvə satılıb?",
  "12 + 8 + 15 = 35 kq.",
  ["35 kq", "20 kq", "27 kq", "45 kq"], 1, "%d kq" % (12 + 8 + 15), 2),
 ("Ardıcıllığı davam etdirin: 3, 6, 9, 12, …",
  "Hər ədəd əvvəlkindən 3 vahid çoxdur: 12 + 3 = 15.",
  ["15", "13", "14", "16"], 1, str(12 + 3), 1),
 ("Ardıcıllığı davam etdirin: 40, 35, 30, …",
  "Hər ədəd əvvəlkindən 5 vahid azdır: 30 − 5 = 25.",
  ["25", "20", "28", "24"], 1, str(30 - 5), 2),
 ("I gün 24, II gün 18 kitab satılıb. II gün neçə kitab az satılıb?",
  "24 − 18 = 6.",
  ["6", "8", "42", "4"], 1, str(24 - 18), 2),
 ("Adi oyun zərində «9» düşməsi necə hadisədir?",
  "Zərin üzlərində 1-dən 6-ya qədər ədədlər var.",
  ["Mümkünsüz", "Mütləq", "Mümkün", "Hər dəfə baş verən"], 1, None, 2),
 ("Qutuda yalnız qırmızı toplar var. Çıxarılan topun qırmızı olması "
  "necə hadisədir?",
  "Başqa rəng yoxdursa, qırmızı çıxması yəqin (mütləq) hadisədir.",
  ["Yəqin (mütləq)", "Mümkünsüz", "Təsadüfi", "Az ehtimallı"], 1, None, 3),
 ("Ardıcıllığı davam etdirin: 2, 4, 8, 16, …",
  "Hər ədəd əvvəlkinin 2 mislidir: 16 · 2 = 32.",
  ["32", "18", "24", "20"], 1, str(16 * 2), 3),
 ("Siyahıdakı ən kiçik ədəd hansıdır: 507; 570; 705; 750?",
  "Yüzlər mərtəbəsi kiçik olan ədəd kiçikdir: 507.",
  ["507", "570", "705", "750"], 1, str(min(507, 570, 705, 750)), 1),
 ("Ballar: Aynur — 7, Tural — 9, Nərmin — 8. Ən yüksək bal kimindir?",
  "9 > 8 > 7.",
  ["Tural", "Aynur", "Nərmin", "Hamısınınkı bərabərdir"], 1,
  max({"Aynur": 7, "Tural": 9, "Nərmin": 8}.items(), key=lambda kv: kv[1])[0], 2),
],
"riy-3-mesele": [
 ("Mağazada 350 dəftər var idi. 120 dəftər satıldı. Neçə dəftər qaldı?",
  "350 − 120 = 230.",
  ["230", "240", "220", "470"], 1, str(350 - 120), 1),
 ("Bir tabaqda 8 alma var. 4 belə tabaqda neçə alma var?",
  "8 · 4 = 32.",
  ["32", "24", "12", "36"], 1, str(8 * 4), 1),
 ("Hər sinifdə 25 şagird olmaqla 3 sinifdə cəmi neçə şagird var?",
  "25 · 3 = 75.",
  ["75", "65", "28", "85"], 1, str(25 * 3), 2),
 ("96 konfet 8 uşağa bərabər paylanıldı. Hər uşağa neçə konfet düşdü?",
  "96 : 8 = 12.",
  ["12", "11", "13", "88"], 1, str(96 // 8), 2),
 ("Kitab 78 səhifədir. Aysu 35 səhifə oxuyub. Neçə səhifə qalıb?",
  "78 − 35 = 43.",
  ["43", "53", "33", "113"], 1, str(78 - 35), 2),
 ("Biletin qiyməti 2 manatdır. 4 bilet üçün nə qədər ödənilməlidir?",
  "2 · 4 = 8 manat.",
  ["8 manat", "6 manat", "2 man 40 qəp", "12 manat"], 1, man(200 * 4), 1),
 ("5 qutunun hərəsində 20 karandaş var. 30 karandaş paylanılsa, "
  "neçəsi qalar?",
  "5 · 20 = 100; 100 − 30 = 70.",
  ["70", "100", "50", "90"], 1, str(5 * 20 - 30), 3),
 ("İki ədədin cəmi 90-dır. Onlardan biri 54-dürsə, o biri neçədir?",
  "90 − 54 = 36.",
  ["36", "46", "34", "144"], 1, str(90 - 54), 2),
 ("3 həftə neçə gündür?",
  "7 · 3 = 21 gün.",
  ["21", "14", "24", "10"], 1, str(7 * 3), 2),
 ("Anarın 9 yaşı var. Atası ondan 4 dəfə böyükdür. Atasının neçə yaşı var?",
  "«4 dəfə böyük» — vurma deməkdir: 9 · 4 = 36.",
  ["36", "13", "27", "45"], 1, str(9 * 4), 3),
],
}


def yoxla():
    n = xeta = 0
    butun = set()
    for movzu, siyahi in SUALLAR.items():
        assert movzu in RUBLAR, movzu
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
        qisa = movzu.replace("riy-3-", "")
        for i, (body, why, opts, correct, _e, diff) in enumerate(SUALLAR[movzu], 1):
            setirler.append(
                "('riy3-%s#%d','%s',%d,%d,'%s','%s',array['%s','%s','%s','%s'],%d)"
                % (qisa, i, movzu, diff, RUBLAR[movzu], q(body), q(why),
                   q(opts[0]), q(opts[1]), q(opts[2]), q(opts[3]), correct))
    with io.open(CIXIS, "w", encoding="utf-8") as f:
        f.write("""-- =====================================================================
--  19_bank_riy3.sql : RIYAZIYYAT 3 PLATFORMA SUAL BANKI
--
--  BU FAYL ELLE YAZILMIR - tools/riy3.py yaradir:
--      python3 tools/riy3.py
--
--  12 movzu x 10 sual = %d.  ext_key: riy3-<movzu>#<sira>.
--  ON SERT: 15_movzular_ederslik.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (
    select 1 from public.topics t
      join public.subjects s on s.id = t.subject_id
     where s.slug = 'riyaziyyat' and t.slug = 'riy-3-vurma-bolme-2') then
    raise exception 'ONCE 15_movzular_ederslik.sql isledilmelidir (riy-3-* movzulari yoxdur).';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and q.ext_key like 'riy3-%%';

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
    join public.levels   l on l.program_id = p.id and l.code = '3'
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
   where owner_type = 'platform' and ext_key like 'riy3-%%';
  if n <> %d then
    raise exception 'riy3 suallari: %d gozlenilirdi, %% tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'riy3-%%'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '%% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'riy3-%%';
  if k <> 12 then
    raise exception 'movzu sayi 12 deyil: %%', k;
  end if;
  raise notice 'Riyaziyyat 3 banki: %% sual, 12 movzu.', n;
end $$;
""" % (n, ",\n".join(setirler), n, n))
    print("yazildi: %s" % CIXIS)


if __name__ == "__main__":
    ok, n = yoxla()
    if not ok:
        raise SystemExit(1)
    sql_yaz(n)
