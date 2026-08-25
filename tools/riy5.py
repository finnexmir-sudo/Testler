#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Riyaziyyat 5 platforma banki -> db/26_bank_riy5.sql

tools/riy3.py qelibi ile: 8 movzu x 10 sual = 80, her riyazi cavab
YENIDEN HESABLANIB duzgun variantla tutusdurulur (kesrler
fractions.Fraction ile).  Movzular 25_movzular_orta5.sql agacina
uygundur (e-derslik Riyaziyyat 5, kitab 840 + 841).

DIQQET: 16_bank_riy4.sql-in qelibleri ve reqemleri ISLENMEYIB
(3,7+2,5; 0,25=1/4; x+250=600; kvadrat perimetr 8 sm ve s.) -
generator >= 0.95 oxsarligi tekrar sayir.

Isletmek:
    python3 tools/riy5.py
"""
import io
import os
from fractions import Fraction

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CIXIS = os.path.join(KOK, "db", "26_bank_riy5.sql")


def fmt(n):
    return format(n, ",").replace(",", " ")


def dec(x):
    """Onluq kesr vergulle: 6.2 -> «6,2», 6.0 -> «6»."""
    s = ("%.10f" % float(x)).rstrip("0").rstrip(".")
    return s.replace(".", ",")


def kesr(f):
    """Fraction -> «a/b» ve ya tam eded."""
    f = Fraction(f)
    if f.denominator == 1:
        return str(f.numerator)
    return "%d/%d" % (f.numerator, f.denominator)


def qarisiq(f):
    """Fraction -> «2 tam 1/5» formasi."""
    f = Fraction(f)
    t, q = divmod(f.numerator, f.denominator)
    if q == 0:
        return str(t)
    return "%d tam %d/%d" % (t, q, f.denominator)


def bolen_sayi(n):
    return sum(1 for d in range(1, n + 1) if n % d == 0)


RUBLAR = {
    "riy-5-natural-ededler":  1, "riy-5-adi-kesrler":     1,
    "riy-5-onluq-kesrler":    2, "riy-5-faiz":            2,
    "riy-5-ifade-tenlik":     3, "riy-5-mustevi-fiqurlar": 3,
    "riy-5-feza-fiqurlari":   4, "riy-5-statistika":      4,
}

SUALLAR = {
"riy-5-natural-ededler": [
 ("7 milyonluq, 2 minlik və 5 təklikdən ibarət natural ədəd hansıdır?",
  "7 000 000 + 2 000 + 5 = 7 002 005.",
  ["7 002 005", "7 200 005", "7 002 500", "72 005"], 1,
  fmt(7 * 10**6 + 2 * 10**3 + 5), 2),
 ("56 789 ədədini onluqlara qədər yuvarlaqlaşdırın.",
  "Təkliklər mərtəbəsində 9 var — yuxarı yuvarlaqlaşır: 56 790.",
  ["56 790", "56 780", "56 700", "56 800"], 1,
  fmt(round(56789, -1)), 2),
 ("4 ədədinin kubu neçəyə bərabərdir?",
  "4³ = 4 · 4 · 4 = 64.",
  ["64", "12", "16", "43"], 1, str(4 ** 3), 2),
 ("9 ədədinin kvadratı neçəyə bərabərdir?",
  "9² = 9 · 9 = 81.",
  ["81", "18", "92", "99"], 1, str(9 ** 2), 1),
 ("54 : 9 + 6 × 3 ifadəsinin qiymətini tapın.",
  "Əvvəl bölmə və vurma: 6 + 18 = 24.",
  ["24", "36", "72", "21"], 1, str(54 // 9 + 6 * 3), 2),
 ("36 ədədinin neçə böləni var?",
  "Bölənlər: 1, 2, 3, 4, 6, 9, 12, 18, 36 — cəmi 9.",
  ["9", "6", "7", "36"], 1, str(bolen_sayi(36)), 3),
 ("Hansı ədəd 3-ə qalıqsız bölünür?",
  "Rəqəmlərinin cəmi 3-ə bölünən ədəd 3-ə bölünür: 2+3+4=9.",
  ["234", "125", "152", "203"], 1,
  str([n for n in (234, 125, 152, 203) if n % 3 == 0][0]), 2),
 ("1 205 × 30 hasilini tapın.",
  "1 205 × 3 = 3 615; sonra 10-a vur: 36 150.",
  ["36 150", "3 615", "36 015", "361 500"], 1, fmt(1205 * 30), 2),
 ("8 400 : 40 qismətini tapın.",
  "84 : 4 = 21, deməli 8 400 : 40 = 210.",
  ["210", "21", "2 100", "240"], 1, fmt(8400 // 40), 2),
 ("İki ədəddən hansı böyükdür: 456 789, yoxsa 456 798?",
  "Onluqlar mərtəbəsinə baxın: 9 > 8, deməli 456 798 böyükdür.",
  ["456 798", "456 789", "Bərabərdirlər", "Müqayisə etmək olmaz"],
  1, fmt(max(456789, 456798)), 1),
],
"riy-5-adi-kesrler": [
 ("Hansı kəsr düzgün kəsrdir?",
  "Düzgün kəsrdə surət məxrəcdən kiçikdir: 4/9.",
  ["4/9", "9/4", "7/7", "12/5"], 1, None, 1),
 ("1/2 + 1/3 cəmini tapın.",
  "Ortaq məxrəc 6: 3/6 + 2/6 = 5/6.",
  ["5/6", "2/5", "1/6", "2/6"], 1,
  kesr(Fraction(1, 2) + Fraction(1, 3)), 2),
 ("3/4 − 1/8 fərqini tapın.",
  "Ortaq məxrəc 8: 6/8 − 1/8 = 5/8.",
  ["5/8", "2/4", "1/2", "4/8"], 1,
  kesr(Fraction(3, 4) - Fraction(1, 8)), 2),
 ("2 tam 1/5 qarışıq ədədini düzgün olmayan kəsr şəklində yazın.",
  "2 · 5 + 1 = 11; deməli 11/5.",
  ["11/5", "3/5", "2/5", "10/5"], 1,
  kesr(Fraction(2) + Fraction(1, 5)), 2),
 ("2/3 × 3/8 hasilini tapın.",
  "Surətlər və məxrəclər vurulur: 6/24 = 1/4.",
  ["1/4", "5/11", "6/11", "3/4"], 1,
  kesr(Fraction(2, 3) * Fraction(3, 8)), 3),
 ("4/5 : 2/5 qismətini tapın.",
  "Bölmə tərs kəsrə vurmadır: 4/5 × 5/2 = 2.",
  ["2", "8/25", "1/2", "6/5"], 1,
  kesr(Fraction(4, 5) / Fraction(2, 5)), 3),
 ("40 kiloqram almanın 3/8 hissəsi satıldı. Neçə kiloqram alma "
  "satıldı?",
  "40 : 8 = 5; 5 · 3 = 15 kq.",
  ["15 kq", "5 kq", "24 kq", "3 kq"], 1,
  "%d kq" % (40 // 8 * 3), 2),
 ("Ədədin 2/7 hissəsi 10-a bərabərdirsə, ədədin özü neçədir?",
  "1/7 hissə: 10 : 2 = 5; ədəd: 5 · 7 = 35.",
  ["35", "20", "70", "14"], 1, str(10 // 2 * 7), 3),
 ("7/12 və 5/8 kəsrlərindən hansı böyükdür?",
  "Ortaq məxrəc 24: 14/24 və 15/24 — deməli 5/8 böyükdür.",
  ["5/8", "7/12", "Bərabərdirlər", "Müqayisə etmək olmaz"], 1,
  kesr(max(Fraction(7, 12), Fraction(5, 8))), 3),
 ("1 tam 3/4 + 2 tam 1/2 cəmini tapın.",
  "Tamlar: 1 + 2 = 3; kəsrlər: 3/4 + 2/4 = 5/4 = 1 tam 1/4; "
  "cəmi 4 tam 1/4.",
  ["4 tam 1/4", "3 tam 1/4", "4 tam 1/2", "3 tam 4/6"], 1,
  qarisiq(Fraction(7, 4) + Fraction(5, 2)), 3),
],
"riy-5-onluq-kesrler": [
 ("6,08 və 6,2 ədədlərindən hansı kiçikdir?",
  "6,08 və 6,20: onda birlər 0 < 2, deməli 6,08 kiçikdir.",
  ["6,08", "6,2", "Bərabərdirlər", "Müqayisə etmək olmaz"],
  1, dec(min(6.08, 6.2)), 2),
 ("7,354 ədədini onda birlərə qədər yuvarlaqlaşdırın.",
  "Yüzdə birlər mərtəbəsində 5 var — yuxarı: 7,4.",
  ["7,4", "7,3", "7,35", "7"], 1, dec(round(7.354, 1)), 2),
 ("3/5 kəsrini onluq kəsr şəklində yazın.",
  "3 : 5 = 0,6.",
  ["0,6", "0,35", "3,5", "0,3"], 1, dec(3 / 5), 2),
 ("15,73 + 4,27 cəmini tapın.",
  "15,73 + 4,27 = 20,00 = 20.",
  ["20", "19,9", "20,1", "19,10"], 1, dec(15.73 + 4.27), 2),
 ("9,1 − 3,45 fərqini tapın.",
  "9,10 − 3,45 = 5,65.",
  ["5,65", "6,65", "5,75", "6,35"], 1, dec(9.1 - 3.45), 3),
 ("0,37 ədədini 100-ə vurun.",
  "100-ə vuranda vergül iki mərtəbə sağa keçir: 37.",
  ["37", "3,7", "0,0037", "370"], 1, dec(0.37 * 100), 2),
 ("8,4 × 5 hasilini tapın.",
  "84 × 5 = 420; bir onda bir mərtəbəsi: 42.",
  ["42", "40,20", "4,2", "13,4"], 1, dec(8.4 * 5), 2),
 ("7,2 : 6 qismətini tapın.",
  "72 : 6 = 12; vergülü qaytar: 1,2.",
  ["1,2", "12", "0,12", "1,02"], 1, dec(7.2 / 6), 2),
 ("3 : 0,5 neçə edər?",
  "Hər vahiddə iki dənə 0,5 var: 3 : 0,5 = 6.",
  ["6", "1,5", "0,6", "60"], 1, dec(3 / 0.5), 3),
 ("3/4 kəsrinin onluq yazılışı hansıdır?",
  "3 : 4 = 0,75.",
  ["0,75", "0,34", "0,25", "7,5"], 1, dec(3 / 4), 2),
],
"riy-5-faiz": [
 ("Faiz nə deməkdir?",
  "1 faiz — ədədin yüzdə bir hissəsidir.",
  ["Ədədin yüzdə bir hissəsi", "Ədədin onda bir hissəsi",
   "Ədədin yarısı", "Ədədin iki misli"], 1, None, 1),
 ("1/2 kəsri neçə faizdir?",
  "1/2 = 50/100 = 50%.",
  ["50%", "12%", "2%", "25%"], 1, None, 2),
 ("0,07 onluq kəsri neçə faizdir?",
  "0,07 = 7/100 = 7%.",
  ["7%", "70%", "0,7%", "7,7%"], 1, None, 2),
 ("200-ün 15%-i neçədir?",
  "200 : 100 = 2; 2 · 15 = 30.",
  ["30", "15", "300", "3"], 1, str(200 * 15 // 100), 2),
 ("60-ın 25%-i neçədir?",
  "25% — dörddə bir hissədir: 60 : 4 = 15.",
  ["15", "25", "45", "6"], 1, str(60 * 25 // 100), 2),
 ("Ədədin 10%-i 12-yə bərabərdirsə, ədədin özü neçədir?",
  "10% on dəfə az deməkdir: 12 · 10 = 120.",
  ["120", "1,2", "22", "102"], 1, str(12 * 10), 3),
 ("80 manatlıq malın qiyməti 20% artdı. Yeni qiymət neçə manatdır?",
  "20%: 80 · 20 : 100 = 16; 80 + 16 = 96 manat.",
  ["96 manat", "100 manat", "84 manat", "16 manat"], 1,
  "%d manat" % (80 + 80 * 20 // 100), 3),
 ("150 manatlıq mal 10% ucuzlaşdı. Yeni qiyməti tapın.",
  "10%: 15 manat; 150 − 15 = 135 manat.",
  ["135 manat", "140 manat", "15 manat", "165 manat"], 1,
  "%d manat" % (150 - 150 * 10 // 100), 3),
 ("25% hansı adi kəsrə bərabərdir?",
  "25/100 = 1/4.",
  ["1/4", "1/2", "1/25", "2/5"], 1,
  kesr(Fraction(25, 100)), 2),
 ("Sinifdə 20 şagird var, onlardan 5-i əlaçıdır. Əlaçılar sinfin "
  "neçə faizini təşkil edir?",
  "5/20 = 1/4 = 25%.",
  ["25%", "5%", "20%", "40%"], 1,
  "%d%%" % (5 * 100 // 20), 3),
],
"riy-5-ifade-tenlik": [
 ("x − 45 = 120 tənliyinin kökünü tapın.",
  "x = 120 + 45 = 165.",
  ["165", "75", "155", "120"], 1, str(120 + 45), 2),
 ("5x + 3x ifadəsini sadələşdirin.",
  "Oxşar hədlər toplanır: (5 + 3)x = 8x.",
  ["8x", "15x", "8", "2x"], 1, None, 2),
 ("y = 7 olduqda 4y − 9 ifadəsinin qiyməti neçədir?",
  "4 · 7 = 28; 28 − 9 = 19.",
  ["19", "28", "2", "37"], 1, str(4 * 7 - 9), 2),
 ("2x = 46 tənliyinin kökü neçədir?",
  "x = 46 : 2 = 23.",
  ["23", "44", "92", "48"], 1, str(46 // 2), 1),
 ("36 : x = 4 tənliyində x-i tapın.",
  "Bölən = bölünən : qismət = 36 : 4 = 9.",
  ["9", "144", "32", "40"], 1, str(36 // 4), 2),
 ("x < 4 bərabərsizliyini hansı natural ədəd ödəyir?",
  "3 ədədi 4-dən kiçikdir.",
  ["3", "5", "4", "7"], 1, None, 2),
 ("Ədədin 3 misli 51-ə bərabərdir. Ədədi tapın.",
  "3x = 51; x = 51 : 3 = 17.",
  ["17", "48", "54", "153"], 1, str(51 // 3), 2),
 ("a = 6, b = 2 olduqda (a + b) : 4 ifadəsinin qiyməti neçədir?",
  "6 + 2 = 8; 8 : 4 = 2.",
  ["2", "8", "6,5", "12"], 1, str((6 + 2) // 4), 2),
 ("Hansı yazılış bərabərsizlikdir?",
  "«>» işarəsi bərabərsizlik bildirir.",
  ["x > 5", "x = 5", "x + 5", "5 + 3 = 8"], 1, None, 2),
 ("y = 3x asılılığında x = 4 olduqda y neçəyə bərabərdir?",
  "y = 3 · 4 = 12.",
  ["12", "7", "34", "43"], 1, str(3 * 4), 3),
],
"riy-5-mustevi-fiqurlar": [
 ("Açılmış bucaq neçə dərəcədir?",
  "Açılmış bucağın tərəfləri bir düz xətt üzərindədir: 180°.",
  ["180°", "90°", "360°", "100°"], 1, None, 1),
 ("Qonşu bucaqların cəmi neçə dərəcədir?",
  "Qonşu bucaqlar birlikdə açılmış bucaq əmələ gətirir: 180°.",
  ["180°", "90°", "60°", "120°"], 1, None, 2),
 ("Bucağı iki konqruyent (bərabər) hissəyə bölən şüa necə adlanır?",
  "Bu şüa bucağın tənböləni adlanır.",
  ["Tənbölən", "Perpendikulyar", "Diaqonal", "Oturacaq"],
  1, None, 2),
 ("Katetləri 6 sm və 8 sm olan düzbucaqlı üçbucağın sahəsini tapın.",
  "S = (6 · 8) : 2 = 24 sm².",
  ["24 sm²", "48 sm²", "14 sm²", "28 sm²"], 1,
  "%d sm²" % (6 * 8 // 2), 2),
 ("Qarşılıqlı bucaqlar bir-birinə görə necədir?",
  "İki düz xətt kəsişəndə qarşılıqlı bucaqlar bərabər olur.",
  ["Bərabərdirlər", "Cəmi 90° olur", "Həmişə fərqlidirlər",
   "Cəmi 100° olur"], 1, None, 3),
 ("Düzbucaqlı üçbucağın sahəsi eyni ölçülü düzbucaqlının sahəsinin "
  "hansı hissəsidir?",
  "Diaqonal düzbucaqlını iki bərabər üçbucağa bölür: yarısı.",
  ["Yarısı", "Dörddə biri", "Özü qədər", "İki misli"], 1, None, 2),
 ("Eyni müstəvidə yerləşən və kəsişməyən düz xətlər necə adlanır?",
  "Belə düz xətlər paralel adlanır.",
  ["Paralel", "Perpendikulyar", "Kəsişən", "Qonşu"], 1, None, 2),
 ("Perpendikulyar düz xətlər hansı bucaq altında kəsişir?",
  "Perpendikulyar xətlər düz bucaq (90°) altında kəsişir.",
  ["Düz bucaq (90°) altında", "İti bucaq altında",
   "Kor bucaq altında", "Açılmış bucaq altında"], 1, None, 2),
 ("45°-lik bucaq hansı növ bucaqdır?",
  "90°-dən kiçik bucaq iti bucaqdır.",
  ["İti", "Kor", "Düz", "Açılmış"], 1, None, 2),
 ("Kor bucaq hansı ölçüdə olur?",
  "Kor bucaq 90°-dən böyük, 180°-dən kiçikdir.",
  ["90°-dən böyük, 180°-dən kiçik", "90°-dən kiçik",
   "Düz 90°", "180°-dən böyük"], 1, None, 3),
],
"riy-5-feza-fiqurlari": [
 ("Tili 3 sm olan kubun səthinin sahəsini tapın.",
  "Bir üzün sahəsi 9 sm²; 6 üz: 6 · 9 = 54 sm².",
  ["54 sm²", "27 sm²", "9 sm²", "36 sm²"], 1,
  "%d sm²" % (6 * 3 * 3), 3),
 ("Ölçüləri 5 sm, 4 sm və 2 sm olan kuboidin həcmini tapın.",
  "V = 5 · 4 · 2 = 40 sm³.",
  ["40 sm³", "11 sm³", "22 sm³", "80 sm³"], 1,
  "%d sm³" % (5 * 4 * 2), 2),
 ("Tili 4 sm olan kubun həcmi neçədir?",
  "V = 4 · 4 · 4 = 64 sm³.",
  ["64 sm³", "16 sm³", "12 sm³", "96 sm³"], 1,
  "%d sm³" % (4 ** 3), 2),
 ("1 m³ neçə litrdir?",
  "1 m³ = 1 000 litr.",
  ["1 000 litr", "100 litr", "10 litr", "10 000 litr"], 1,
  "%s litr" % fmt(1000), 3),
 ("1 dm³ neçə kub santimetrdir?",
  "1 dm = 10 sm; 10 · 10 · 10 = 1 000 sm³.",
  ["1 000 sm³", "100 sm³", "10 sm³", "30 sm³"], 1,
  "%s sm³" % fmt(10 ** 3), 3),
 ("Düz prizmanın həcmi necə hesablanır?",
  "V = oturacağın sahəsi × hündürlük.",
  ["Oturacağın sahəsi × hündürlük", "Bütün tillərin cəmi",
   "Perimetr × 2", "Üzlərin sayı × 6"], 1, None, 2),
 ("Kuboidin neçə tili var?",
  "Kuboidin 12 tili var.",
  ["12", "6", "8", "4"], 1, str(12), 2),
 ("1 hektar neçə kvadrat metrdir?",
  "1 ha = 100 m · 100 m = 10 000 m².",
  ["10 000 m²", "1 000 m²", "100 m²", "100 000 m²"], 1,
  "%s m²" % fmt(100 * 100), 3),
 ("Ölçüləri 6 sm, 3 sm və 2 sm olan kuboidin səthinin sahəsini tapın.",
  "S = 2 · (6·3 + 6·2 + 3·2) = 2 · 36 = 72 sm².",
  ["72 sm²", "36 sm²", "11 sm²", "66 sm²"], 1,
  "%d sm²" % (2 * (6 * 3 + 6 * 2 + 3 * 2)), 3),
 ("Akvariumun ölçüləri 40 sm, 30 sm və 20 sm-dir. Onun tutumu "
  "neçə litrdir?",
  "V = 40 · 30 · 20 = 24 000 sm³ = 24 litr.",
  ["24 litr", "240 litr", "90 litr", "2,4 litr"], 1,
  "%d litr" % (40 * 30 * 20 // 1000), 3),
],
"riy-5-statistika": [
 ("7, 9 və 14 ədədlərinin ədədi ortasını tapın.",
  "(7 + 9 + 14) : 3 = 30 : 3 = 10.",
  ["10", "9", "30", "15"], 1, str((7 + 9 + 14) // 3), 2),
 ("Beş ədədin ədədi ortası 8-dirsə, bu ədədlərin cəmi neçədir?",
  "Cəm = orta · say = 8 · 5 = 40.",
  ["40", "13", "8", "85"], 1, str(8 * 5), 3),
 ("Dairəvi diaqram bütövlükdə neçə dərəcəlik dairədən ibarətdir?",
  "Tam dairə 360°-dir.",
  ["360°", "180°", "100°", "90°"], 1, None, 2),
 ("Dairəvi diaqramda yarım dairə bütövün neçə faizini göstərir?",
  "Yarım dairə — yarısı, yəni 50%.",
  ["50%", "25%", "75%", "100%"], 1, None, 2),
 ("Şagirdin qiymətləri: 4, 5, 3, 4. Qiymətlərin ədədi ortası neçədir?",
  "(4 + 5 + 3 + 4) : 4 = 16 : 4 = 4.",
  ["4", "5", "3", "16"], 1, str((4 + 5 + 3 + 4) // 4), 2),
 ("Məlumatları cədvəl və diaqramda göstərmək nə üçün faydalıdır?",
  "Müqayisə etmək və nəticə çıxarmaq asanlaşır.",
  ["Müqayisə və təhlil asanlaşır", "Yazı azalmır, çoxalır",
   "Heç bir faydası yoxdur", "Yalnız bəzək üçündür"], 1, None, 2),
 ("20, 30, 40 və 50 ədədlərinin ədədi ortası neçədir?",
  "(20 + 30 + 40 + 50) : 4 = 140 : 4 = 35.",
  ["35", "40", "140", "30"], 1, str((20 + 30 + 40 + 50) // 4), 2),
 ("Komanda üç oyunda 9, 3 və 6 xal topladı. Oyun başına orta xal "
  "neçədir?",
  "(9 + 3 + 6) : 3 = 18 : 3 = 6.",
  ["6", "9", "18", "3"], 1, str((9 + 3 + 6) // 3), 2),
 ("Dairəvi diaqramda 90°-lik sektor bütövün hansı hissəsidir?",
  "90/360 = 1/4 — dörddə biri (25%).",
  ["Dörddə biri (25%)", "Yarısı (50%)", "Onda biri (10%)",
   "Üçdə biri"], 1, None, 3),
 ("2, 5, 5, 3, 5, 2 sırasında ən çox təkrarlanan ədəd hansıdır?",
  "5 ədədi üç dəfə təkrarlanır.",
  ["5", "2", "3", "Hamısı bərabər"], 1,
  str(max((2, 5, 5, 3, 5, 2), key=(2, 5, 5, 3, 5, 2).count)), 2),
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
        qisa = movzu.replace("riy-5-", "")
        for i, (body, why, opts, correct, _e, diff) in enumerate(SUALLAR[movzu], 1):
            setirler.append(
                "('riy5-%s#%d','%s',%d,%d,'%s','%s',array['%s','%s','%s','%s'],%d)"
                % (qisa, i, movzu, diff, RUBLAR[movzu], q(body), q(why),
                   q(opts[0]), q(opts[1]), q(opts[2]), q(opts[3]), correct))
    with io.open(CIXIS, "w", encoding="utf-8") as f:
        f.write("""-- =====================================================================
--  26_bank_riy5.sql : RIYAZIYYAT 5 PLATFORMA SUAL BANKI (orta mekteb)
--
--  BU FAYL ELLE YAZILMIR - tools/riy5.py yaradir:
--      python3 tools/riy5.py
--
--  8 movzu x 10 sual = %d.  ext_key: riy5-<movzu>#<sira>.
--  ON SERT: 25_movzular_orta5.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (
    select 1 from public.topics t
      join public.subjects s on s.id = t.subject_id
     where s.slug = 'riyaziyyat' and t.slug = 'riy-5-faiz') then
    raise exception 'ONCE 25_movzular_orta5.sql isledilmelidir (riy-5-* movzulari yoxdur).';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and q.ext_key like 'riy5-%%';

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
    join public.levels   l on l.program_id = p.id and l.code = '5'
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
   where owner_type = 'platform' and ext_key like 'riy5-%%';
  if n <> %d then
    raise exception 'riy5 suallari: %d gozlenilirdi, %% tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'riy5-%%'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '%% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'riy5-%%';
  if k <> 8 then
    raise exception 'movzu sayi 8 deyil: %%', k;
  end if;
  raise notice 'Riyaziyyat 5 banki: %% sual, 8 movzu.', n;
end $$;
""" % (n, ",\n".join(setirler), n, n))
    print("yazildi: %s" % CIXIS)


if __name__ == "__main__":
    ok, n = yoxla()
    if not ok:
        raise SystemExit(1)
    sql_yaz(n)
