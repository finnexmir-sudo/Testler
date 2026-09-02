#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Ders plani ucun ALT MOVZU agacini qurur: mundericat/*.txt fayllarini
oxuyur, db/8N_alt_movzular_*.sql cixarir.

NIYE SKRIPT: adlar derslikden EYNILE goturulur, amma portalin
mundericat panelinde bezi adlar naqisdir (dusen duster simvollari,
10-cu sinifde rus dilinde qalmis iki bolme, yazi qusurlari).
Duzelisler burada BIR yerdedir - SQL-in icinde deyil.  Duzelis
lazim olsa skript deyisir, sonra SQL yeniden cixarilir.

Isletmek:
    python3 tools/alt_movzular.py               # butun paketler
    python3 tools/alt_movzular.py --siyahi      # yalniz siyahi
    python3 tools/alt_movzular.py --siyahi riy1_4
"""
import os
import re
import sys

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOC = os.path.join(KOK, "mundericat")
DB = os.path.join(KOK, "db")

#  Siniflerin adi - SQL serhleri ASCII-dir
SIRA = {1: "1-ci", 2: "2-ci", 3: "3-cu", 4: "4-cu", 5: "5-ci", 6: "6-ci",
        7: "7-ci", 8: "8-ci", 9: "9-cu", 10: "10-cu", 11: "11-ci"}

#  Kitabin SONUNDAKI aparat - bolmenin dersi deyil.  db/74 de eyni
#  qaydani tutub: "Bolmeler uzre umumilesdirici tapsiriqlar",
#  "Ozunuzu yoxlayin", "Cavablar" xaricde qalib.
XARIC_UMUMI = {
    "Sözlük", "Lüğət", "Cavablar", "Cavabla", "Özünüzü yoxlayın",
    "Məsələ həllinə nümunə",
    "Bölmələr üzrə ümumiləşdirici tapşırıqlar",
    "Birinci yarımil üzrə ümumiləşdirici tapşırıqlar",
    "1-ci yarımil üzrə ümumiləşdirici tapşırıqlar",
    "1-ci sinif üzrə ümumiləşdirici tapşırıqlar",
    "3-cü sinif üzrə ümumiləşdirici tapşırıqlar",
    "4-cü sinif üzrə ümumiləşdirici tapşırıqlar",
    "5-ci sinif üzrə ümumiləşdirici tapşırıqlar",
    "6-cı sinif üzrə ümumiləşdirici tapşırıqlar",
}


QISA = {
    "Ümumiləşdirici tapşırıqlar": "umumi",
    "Bölmə üzrə ümumiləşdirici tapşırıqlar": "umumi",
    "İlkin yoxlama": "ilkin",
    "Xülasə": "xulase",
    "Məsələ və misallar": "meseleler",
    "Məsələlər": "meseleler",
}

# --------------------------------------------------------------------
HARF = {"ə": "e", "ı": "i", "ö": "o", "ü": "u", "ç": "c", "ş": "s",
        "ğ": "g", "İ": "i", "I": "i", "Ə": "e", "Ö": "o", "Ü": "u",
        "Ç": "c", "Ş": "s", "Ğ": "g", "²": "2", "³": "3", "ⁿ": "n"}

ASCII = {
    "ə": "e", "Ə": "E", "ı": "i", "İ": "I", "ö": "o", "Ö": "O",
    "ü": "u", "Ü": "U", "ç": "c", "Ç": "C", "ş": "s", "Ş": "S",
    "ğ": "g", "Ğ": "G", "²": "^2", "³": "^3", "ⁿ": "^n", "∈": "in", "€": "in", "«": '"', "»": '"', "–": "-", "—": "-", "’": "",
    "а": "a", "б": "b", "в": "v", "г": "g", "д": "d", "е": "e",
    "ё": "yo", "ж": "j", "з": "z", "и": "i", "й": "y", "к": "k",
    "л": "l", "м": "m", "н": "n", "о": "o", "п": "p", "р": "r",
    "с": "s", "т": "t", "у": "u", "ф": "f", "х": "h", "ц": "ts",
    "ч": "ch", "ш": "sh", "щ": "sch", "ъ": "", "ы": "y", "ь": "",
    "э": "e", "ю": "yu", "я": "ya",
    "А": "A", "Б": "B", "В": "V", "Г": "G", "Д": "D", "Е": "E",
    "Ж": "J", "З": "Z", "И": "I", "К": "K", "Л": "L", "М": "M",
    "Н": "N", "О": "O", "П": "P", "Р": "R", "С": "S", "Т": "T",
    "У": "U", "Ф": "F", "Х": "H", "Ц": "Ts", "Ч": "Ch", "Ш": "Sh",
    "Щ": "Sch", "Э": "E", "Ю": "Yu", "Я": "Ya",
}

HARF = {"ə": "e", "ı": "i", "ö": "o", "ü": "u", "ç": "c", "ş": "s",
        "ğ": "g", "İ": "i", "I": "i", "Ə": "e", "Ö": "o", "Ü": "u",
        "Ç": "c", "Ş": "s", "Ğ": "g", "²": "2", "³": "3", "ⁿ": "n"}

DAYAN = {"ve", "ile", "onun", "uzre", "olan", "bir", "iki", "uc", "gore",
         "steam", "ucun", "aid", "her", "bu", "da", "de", "ki", "ya",
         "bezi", "hemin", "onlar"}

#  Riyaziyyat 5-11 ad duzelisleri (paketin icinde islenir)
DUZELIS_RIY5_11 = {
    # ---- 5-ci sinif (yazi qusurlari) ----
    "Natural ədədlərin toplanması va çıxılması":
        ("Natural ədədlərin toplanması və çıxılması", "yazi"),
    "Natural ədədin kvadratı va kubu":
        ("Natural ədədin kvadratı və kubu", "yazi"),
    "Məxrəcləri müxtəlif olan kəsrlərin toplanması va çıxılması":
        ("Məxrəcləri müxtəlif olan kəsrlərin toplanması və çıxılması", "yazi"),
    "Onluq kəsrın natural ədədə vurulması":
        ("Onluq kəsrin natural ədədə vurulması", "yazi"),
    "Kub və kuboidın səthinin sahəsi":
        ("Kub və kuboidin səthinin sahəsi", "yazi"),
    'STEAM. "Quşlar bizim dostlarımızdır".':
        ('STEAM. "Quşlar bizim dostlarımızdır"', "yazi"),
    # ---- 7-ci sinif (yazi qusurlari) ----
    "Rasioanl ədədlərin yazılışı və oxunuşu":
        ("Rasional ədədlərin yazılışı və oxunuşu", "yazi"),
    "İkidayişənli xətti tənliklər sistemi":
        ("İkidəyişənli xətti tənliklər sistemi", "yazi"),
    # ---- 9-cu sinif (dusen dusterler) ----
    "= + + funksiyasının qrafikinin qurulması":
        ("y = ax² + bx + c funksiyasının qrafikinin qurulması", "duster"),
    "= + + funksiyasının araşdırılması":
        ("y = ax² + bx + c funksiyasının araşdırılması", "duster"),
    "= || funksiyası və onun qrafiki":
        ("y = |x| funksiyası və onun qrafiki", "duster"),
    "= funksiyası və onun qrafiki":
        ("y = x³ funksiyası və onun qrafiki", "duster"),
    "Ədədi silsilənin -ci həddinin düsturu":
        ("Ədədi silsilənin n-ci həddinin düsturu", "duster"),
    "Ədədi silsilənin ilk həddinin cəmi düsturu":
        ("Ədədi silsilənin ilk n həddinin cəmi düsturu", "duster"),
    "Həndəsi silsilənin -ci həddinin düsturu":
        ("Həndəsi silsilənin n-ci həddinin düsturu", "duster"),
    "Həndəsi silsilənin ilk həddinin cəmi düsturu":
        ("Həndəsi silsilənin ilk n həddinin cəmi düsturu", "duster"),
    "Permutasiya-yerdəyişmə, P":
        ("Permutasiya-yerdəyişmə, nPn", "duster"),
    "Permutasiya-yerləşdirmə, P":
        ("Permutasiya-yerləşdirmə, nPk", "duster"),
    "Kombinezon, C":
        ("Kombinezon, nCk", "duster"),
    "Vuruğun kök işarəsi altindan çıxarılması":
        ("Vuruğun kök işarəsi altından çıxarılması", "yazi"),
    "Vuruğun kök işarəsi altina daxil edilməsi":
        ("Vuruğun kök işarəsi altına daxil edilməsi", "yazi"),
    # ---- 10-cu sinif ----
    "y = xn (n € N) qüvvət funksiyalar":
        ("y = xⁿ (n ∈ N) qüvvət funksiyası", "duster"),
    "Müstəvilərin qarşılıqlı vəziyyəti.İkiüzlü bucaqlar":
        ("Müstəvilərin qarşılıqlı vəziyyəti. İkiüzlü bucaqlar", "yazi"),
    "Xətt sürət, bucaq sürəti":
        ("Xətti sürət, bucaq sürəti", "yazi"),
    "Toplama düsturlar":
        ("Toplama düsturları", "yazi"),
    "Степень с действительным показателем":
        ("Həqiqi üstlü qüvvət", "rusca"),
    "Показательная функция":     ("Üstlü funksiya", "rusca"),
    "Логарифм числа":            ("Ədədin loqarifmi", "rusca"),
    "Логарифмическая функция":   ("Loqarifmik funksiya", "rusca"),
    "Свойства логарифмов":       ("Loqarifmin xassələri", "rusca"),
    "Логарифмическая шкала.Решение задач":
        ("Loqarifmik şkala və məsələ həlli", "rusca"),
    "Показательные уравнения":   ("Üstlü tənliklər", "rusca"),
    "Логарифмические уравнения": ("Loqarifmik tənliklər", "rusca"),
    "Показательные неравенства": ("Üstlü bərabərsizliklər", "rusca"),
    "Логарифмические неравенства":
        ("Loqarifmik bərabərsizliklər", "rusca"),
    "Обобщающие задания":        ("Ümumiləşdirici tapşırıqlar", "rusca"),
    "Совокупность и выборка. Случайная выборка и её разновидности":
        ("Külliyyat və seçim. Təsadüfi seçim və növləri", "rusca"),
    "Представление информации":  ("Məlumatın təqdimi", "rusca"),
    "Разложение бинома":         ("Binomial açılış", "rusca"),
    "Испытания Бернулли":        ("Bernulli sınaqları", "rusca"),
    # ---- 11-ci sinif (yazi qusurlari) ----
    "İbtidai funksiya.Qeyri-müəyyən inteqral":
        ("İbtidai funksiya. Qeyri-müəyyən inteqral", "yazi"),
    "Məlumatin paylanma formaları":
        ("Məlumatın paylanma formaları", "yazi"),
}

#  Slug ucun qisa ad - avtomatik cixmayan bendler


# =====================================================================
#  PAKETLER
#  Her paket bir SQL fayli verir.  "sinifler" -> derslikdeki bolme
#  sirasi ile valideyn movzu slug-lari.  Bolme iki movzuya bolunurse
#  (slug_a, sehife, slug_b) yazilir: hemin sehifeden sonrakilar
#  ikinci movzuya gedir.
# =====================================================================

BASLIQ_RIY5_11 = """\
--  82_alt_movzular_riy5_11.sql : RIYAZIYYAT 5-7, 9-11 - ALT MOVZULAR
--
--  NIYE
--  db/74 8-ci sinif ucun alt movzu agacini qurdu; muellim onu
--  yoxlayib tesdiqledi (derslik 11 bolme = baza 74 setir = panel
--  74 ders).  Bu fayl EYNI qelible riyaziyyatin qalan
--  siniflerini bitirir - bir fenn sona qeder, muellime gostermeye
--  tam bir sey olsun.
--
--  EHATE: yalniz Riyaziyyat, 5, 6, 7, 9, 10, 11-ci sinifler.
--  8-ci sinif db/74-dedir, 1-4 ise db/83-de.
--
--  MENBE: e-derslik.edu.az sag paneldeki "Movzular" agaci -
--  kitab id 840/841 (5), 906/907 (6), 714 (7), 507 (9), 741 (10),
--  817 (11).  Adlar EYNILE goturulub.  Derslikdeki sira sort-a
--  dusub; her valideyn altinda 10-dan baslayir."""

BASLIQ_RIY1_4 = """\
--  83_alt_movzular_riy1_4.sql : RIYAZIYYAT 1, 3, 4 - ALT MOVZULAR
--
--  NIYE
--  db/74 (8-ci sinif) ve db/82 (5-7, 9-11) yuxari sinifleri bitirdi.
--  Ibtidai derslikler de IKIPILLELIDIR - bolmenin icinde 4-12 ders
--  var, movzu tek ders deyil.  Bu fayl 1, 3 ve 4-cu sinfi elave edir;
--  bununla riyaziyyat sona catir.
--
--  2-Cİ SINIF YOXDUR - qesden.  Portaldaki nesr kohnedir (yalniz
--  20-ye qeder gedir, cemi 2 bolme), bazadaki 9 movzu ile
--  uygunlasmir.  Portal yeni nesri qoyanda elave olunacaq.
--
--  MENBE: e-derslik.edu.az "Movzular" agaci - kitab id 419/420 (1),
--  680/681 (3), 774/775 (4).  Adlar EYNILE goturulub.
--
--  BIR BOLME IKI MOVZUYA BOLUNUB: derslikde 4-cu sinfin 7-ci bolmesi
--  "Adi ve onluq kesrler" birdir, bazada ise iki movzudur.  Kitabin
--  oz nomrelemesi ayirir - 33-cu ders "Onluq kesrler"den etibaren
--  ikinci movzuya gedir (s.19-dan sonrasi).
--
--  "Metn meseleleri" (riy-3-mesele, riy-4-mesele) derslikde bolme
--  deyil - bizim elave movzumuzdur, ona gore alt movzusu yoxdur.
--  Plan yarpaqlarla islediyi ucun o, tek ders kimi qalir."""

BASLIQ_HB1_4 = """\
--  84_alt_movzular_hb1_4.sql : HEYAT BILGISI 1-4 - ALT MOVZULAR
--
--  NIYE
--  Riyaziyyatdan sonra ikinci fenn.  Heyat bilgisi derslikleri
--  bolme -> ders quruluşundadir ve bazadaki movzu agaci ile
--  DORD SINIFDE DE bire-bir uygundur (5+6+6+5 = 22 bolme) - ona
--  gore ilk secilen odur, xeritede muzakire teleb eden yer yoxdur.
--
--  MENBE: e-derslik.edu.az "Movzular" agaci - kitab id 762 (1),
--  829 (2), 900 (3), 769 (4).  Adlar EYNILE goturulub."""

BASLIQ_INF = """\
--  85_alt_movzular_inf1_11.sql : INFORMATIKA 1-11 - ALT MOVZULAR
--
--  NIYE
--  Ucuncu fenn.  Riyaziyyat (74/82/83) ve heyat bilgisi (84) hazirdir;
--  informatika ile IBTIDAI SINIFLER de tam bitir (az dili istisnadir -
--  derslik temaya gore bolunub, bizim agac qrammatikadir).
--
--  MENBE: e-derslik.edu.az "Movzular" agaci - kitab id 417 (1),
--  520 (2), 676 (3), 360 (4), 846 (5), 912 (6), 708 (7), 797 (8),
--  884 (9), 736 (10), 822 (11).  Adlar EYNILE goturulub.
--
--  DERSLIYIN QURULUSU UC YERDE BIZIMKINDEN FERQLIDIR:
--
--  1) 1, 3 ve 4-cu sinifde bolmenin icinde ALT BASLIQ var - nomresiz,
--     ozunden sonraki dersle EYNI sehifede ("QRAFIK REDAKTOR" s.52,
--     "20. PAINT PROQRAMI" s.52).  O, ders deyil, ona gore siyahiya
--     dusmur; bizim iki movzuya bolunen bolmelerde ise sarhed kimi
--     islenir (inf-3-kompyuter | inf-3-qrafik).
--  2) 2-ci sinifde alt basliq YOXDUR, amma bazada "Kompüter" ve
--     "Proqramlarla iş" ayri movzudur.  Sarhed s.53-dur: 21-ci ders
--     "Metn redaktoru"ndan etibaren proqramlarla is baslayir; 20-ci
--     ders ("İş masası və proqram pəncərəsi") hele komputerin ozudur.
--  3) 10 ve 11-ci sinifde derslikde bolme COXDUR: 10-da "Veb-
--     proqramlasdirma" + "Informasiya cemiyyeti" bizde bir movzudur
--     ("Veb və informasiya cəmiyyəti"), 11-de "Komputer" + "Veb-
--     layihe" birdir.  Setirler birlesir, sira davam edir.
--
--  BURAXILAN BOLMELER: 5-ci sinifde "Giriş" (derslikle nece
--  islemeli), 11-ci sinifde "Layihələr üçün yardımçı materiallar" ve
--  "Informatika kursu uzre testler" - ders deyil, elavedir.
--
--  ADLARIN BOYUK HERFLE YAZILISI DEYISDIRILMIR: 1, 3 ve 4-cu sinif
--  dersliyi basliqlari kitabin OZUNDE de tam boyuk herfle verib
--  (s.6 basligi <h3>1. INSAN VE INFORMASIYA</h3>).  Bu, portal
--  qusuru deyil - dersliyin dizaynidir, ona gore toxunulmur."""

BASLIQ_FIZ = """\
--  86_alt_movzular_fizika6_11.sql : FIZIKA 6-11 - ALT MOVZULAR
--
--  NIYE
--  Dorduncu fenn.  Riyaziyyat, heyat bilgisi ve informatika hazirdir.
--  Fizika 6-cı sinifden baslayir (1-5-de yoxdur).
--
--  MENBE: e-derslik.edu.az "Movzular" agaci - kitab id 546 (6),
--  867/868 (7), 931/932 (8), 472 (9), 734 (10), 282 (11).  Adlar
--  EYNILE goturulub.
--
--  DERSLIYIN QURULUSU BIZIMKINDEN FERQLIDIR - HER SINIFDE AYRI SEBEB:
--
--  6-cı sinif: derslikde 4 bolme, bazada 6 movzu - iki bolme
--  SEHIFEYE GORE ikiye bolunur ("1 FIZIKA NEYI OYRENIR?" ->
--  fiz-6-giris + fiz-6-olcmeler, sehife 22-den; "4 QARSILIQLI
--  TESIRLER VE HEREKET" -> fiz-6-hereket + fiz-6-enerji, sehife 83-den).
--
--  7-ci sinif: kitab 867-nin "Giris" bolmesi (3 hemin dersin adi ile -
--  "Fizikler tebiet haqqinda ne bilirler?" ve s.) NOMRESIZ ve derslikde
--  ayri "==" bolme kimi gorunur, amma bazada ayri movzusu yoxdur -
--  ilk movzuya (fiz-7-olcme) elave edilib.  Daha ciddi tele: kitabin
--  öz mundericat sehifesinde "Bolme 4. Atomun qurulusu ve olcusu"
--  basligi mundericat SCRAPER-inde "==" kimi DEYIL, adi bir sətir
--  kimi "Bolme 3. Eyrixetli hereket"in daxilinde gorunur (portal
--  qusuru).  Bu setir ozu XARIC edilib (movzu deyil, basliqdir),
--  sehife 76-dan sonrasi fiz-7-atom-a gedir.
--
--  9-cu sinif: 4 fesil, bazada 6 movzu.  Fesil 3 (ISIQ HADISELERI)
--  ISIQ ve GUZGU-LINZA arasinda İKİ DEFE novbelesir (dersler movzu
--  uzre deyil, dersliyin oz ardicilligi ilə düzülüb): yayilma+qayitma
--  (isiq) -> guzgu (guzgu-linza) -> sinma+tam-daxili-qayitma (isiq) ->
--  linza+goz (guzgu-linza).  Sehife serhedleri: 123, 133, 145.
--  Fesil 4 (ATOM VE ATOM NUVESI) bir sehifede (193) radioaktivlik/
--  nuve arasinda bolunur.
--
--  10-cu sinif: derslikde 7 fesil, bazada 6 movzu - V fesil
--  (RELYATIVISTIK MEXANIKA, cemi 2 ders: nisbilik nezeriyyesi ve
--  enerji-kutle elaqesi) III fesle (SAXLANMA QANUNLARI) birlesir -
--  hər ikisi enerjinin saxlanmasi movzusudur.
--
--  11-ci sinif: 4 fesil, bazada 6 movzu.  I fesil (ELEKTROMAQNIT
--  SAHESI) sehife 31-den ELEKTROSTATIKA/MAQNIT-INDUKSIYA arasinda,
--  III fesil (ELEKTROMAQNIT REQSLERI VE DALGALARI) sehife 128-den
--  REQS/OPTIKA arasinda bolunur.
--
--  "•" ILE BASLAYAN BENDLER (6-cı sinif: "• Ümumiləşdirici
--  tapşırıqlar"): dusterin ozu, movzu adinin hissesi deyil - silinir.
--
--  BURAXILAN BOLMELER: yoxdur - hamisi hardasa bir movzuya baglanir.
--  Arxa hisse (Sozluk/Terminler lugeti/fesil cavab acari/Elaveler)
--  xaric edilir."""

BASLIQ_KIM = """\
--  87_alt_movzular_kimya7_11.sql : KIMYA 7-11 - ALT MOVZULAR
--
--  NIYE
--  Altinci fenn.  Riyaziyyat, heyat bilgisi, informatika, fizika
--  hazirdir.  Kimya 7-ci sinifden baslayir (1-6-da yoxdur).
--
--  MENBE: e-derslik.edu.az "Movzular" agaci - kitab id 871/872 (7),
--  935/936 (8), 505 (9), 739 (10), 349 (11).  Adlar EYNILE goturulub.
--
--  DERSLIYIN QURULUSU 9 VE 11-CI SINIFDE COX PILLELIDIR:
--
--  9-cu sinif: derslikde YALNIZ 3 boyuk boluk var ("I. METALLAR",
--  "II. QEYRİ-METALLAR", "III. ÜZVİ KİMYAYA GİRİŞ...") - hər biri
--  ozunun icinde "Fəsil N." basliqlari ile bolunub, bazada ise 6
--  movzu var.  "I" boluk sehife 23-den iki movzuya (metal-umumi/
--  metallar), "II" boluk sehife 89 ve 121-den UC movzuya (halogen-
--  kukurd/azot-fosfor/karbon-silisium) bolunur.  "Fəsil N." basliqlari
--  ozleri movzu deyil - novbeti derslə eyni sehifede olsalar da,
--  bezen basqa sehifede oldugu ucun umumi qaydayla (bolmebasliq)
--  tutulmur, ona gore herfi mетnleri xaric siyahisindadir.
--
--  11-ci sinif: daha da derindir - "I. Hissə" YEGANE boluk daxilinde
--  DORD movzu gizlenib (spirtler/aldehid-tursu/efir-yag/karbohidrat),
--  sehife 50/97/118-den bolunur.  "fəsil N." basliqlari (kicik herflə)
--  eyni sebeble xaric siyahisindadir.  Bir yazi qusuru var:
--  "Ümumiləşdİrİcl sual və tapşırıqlar" (s.47) - boyuk/kicik herf
--  qarisigi. "3.5.Sabun..." bosluqsuz nomrelidir (s.109).
--
--  7-ci sinifin "Giriş" bolmesi (1 ders - laboratoriya tehlukesizliyi)
--  nomresiz ayri "==" bolme kimi gelir, bazada ayri movzusu yoxdur -
--  ilk movzuya (kim-7-elementler) elave edildi.
--
--  10-cu sinifin "Kimya" / "Giriş" bolmesi (1 ders, dersliyin ozunun
--  "bu kitabla nece isləmeli" tipli girisidir - real kimya mezmunu
--  deyil) ATILIB, informatika 5-in "Giriş"i kimi.
--
--  10-cu sinifde III BÖLMƏ (Alkadienlər) ve V BÖLMƏ (Tsikloalkanlar)
--  EYNI movzuya (kim-10-dien-tsiklo) gedir, aralarinda IV BÖLMƏ
--  (Alkinler, oz movzusu) olsa da - setirler birlesir, sort davam edir.
--
--  ELLE YAZILMIR: tools/alt_movzular.py cixarir."""

BASLIQ_BIO = """\
--  88_alt_movzular_biologiya6_11.sql : BIOLOGIYA 6-11 - ALT MOVZULAR
--
--  NIYE
--  Yeddinci fenn.  Riyaziyyat, heyat bilgisi, informatika, fizika,
--  kimya hazirdir.  Biologiya 6-ci sinifden baslayir (1-5-de yoxdur).
--
--  MENBE: e-derslik.edu.az "Movzular" agaci - kitab id 538 (6),
--  863/864 (7), 927/928 (8), 727 (10), 276 (11).  Adlar EYNILE
--  goturulub.
--
--  9-CU SINIF BU FAYLDA YOXDUR: kitab id 467-nin server terefi
--  BOS qayidir (Cemi sehife: 0) - portal bu derslik ucun meznunu
--  hele yuklemeyib, umumi mundericat.py scraperi de bunu tesdiq edir.
--  Ust movzular (bio-9-*) ondan evvel, basqa menbeden qurulub -
--  toxunulmur, sadece bu merhelede alt movzu almir.  Portal
--  meznunu yukleyende elave olunacaq.
--
--  DERSLIYIN QURULUSU:
--
--  6-ci sinif: 8 Fesil, hamisi bire-bir movzuya (birbasa).
--
--  7-ci sinif: kitab 863-un "Giris" bolmesi (2 ders, basliq yoxdur)
--  ayri "==" bolme kimi gelir, bazada ayri movzusu yoxdur - ilk
--  movzuya (bio-7-huceyre-orqanizm) elave edildi.
--
--  8-ci sinif: 8 Bolme, hamisi bire-bir movzuya (birbasa).
--
--  10-cu sinif: derslikde 5 boyuk boluk (I-V), bazada 8 movzu -
--  ILK boluk ("I. Biosferde istehsal ve istehlak") sehife 31-den
--  IKI movzuya bolunur (heyat-prosesleri/istehsal).  "II" ve "III"
--  boluklerin ICINDE nomresiz "Bolme N." alt-basliqlari var (novbeti
--  dersle EYNI sehifede, alt-basliq qaydasi ile tutulur) - "II"
--  UC movzuya (deyiskenlik/saglam-heyat/epidemiologiya), "III" ISE
--  IKI alt-basliqla da EYNI movzuya (tekamul) gedir - dersllik iki
--  hisseye bolse de bazada tek movzudur.  "IV" ve "V" birbasa.
--
--  11-ci sinif: derslikde 7 boyuk boluk (I-VII), bazada 8 movzu -
--  "II. Mikrobiologiya"nin 9 dersi TAM bakteriyalar movzusuna
--  (bio-11-bakteriyalar) yonledi.  Sebeb: dersliyin mundericat
--  panelinde bu bolmenin icinde virus-a aid AYRI basliq YOXDUR (butun
--  9 ders "Mikroorqanizmler/menfur muhit/infeksion proses" basliqli,
--  sehife araliqlari da bolunme gostermir) - uydurma sehife serhedi
--  qoymaqdansa, movcud movzunun (bio-11-viruslar) bu merhelede 0 alt
--  movzu qalmasi seçildi.  Qalan 6 boluk birbasa bire-bir movzuya.
--
--  BURAXILAN BENDLER: "Layihə", "Təqdimat mövzuları" / "Təqdimat və
--  referat mövzuları" / "Təqdimat üçün mövzular" - ders deyil, elavedir
--  (10 ve 11-ci sinifde tekrar-tekrar cixir).  "İstifadə edilmiş
--  ədəbiyyat" da eyni sebeble xaric edilib.
--
--  "•" ILE BASLAYAN BENDLER (6-ci sinif): dusterin ozu, silinir.
--
--  YAZI QUSURLARI: 6-ci sinifde "Xəstəliktörədən" (bosluq dusub),
--  7-ci sinifde iki bend sonunda artiq nöqte ("Tozlanma.",
--  "Çiçək və onun quruluşu."), 8-ci sinifde bir bend sonunda ("İnsan
--  ürəyinin quruluşu və işi."), 7-ci sinif II hissede iki bendde
--  noqteden sonra bosluq yoxdur ("hissələri.Buğumayaqlılar",
--  "hissələri.Molyusklar").
--
--  ELLE YAZILMIR: tools/alt_movzular.py cixarir."""

BASLIQ_ING = """\
--  89_alt_movzular_ingilis6_11.sql : INGILIS DILI 6-7, 10-11 - ALT MOVZULAR
--
--  NIYE
--  Sekkizinci fenn.  Riyaziyyat, heyat bilgisi, informatika, fizika,
--  kimya, biologiya hazirdir.
--
--  MENBE: e-derslik.edu.az "Movzular" agaci - kitab id 916 (6),
--  710 (7), 738 (10), 805 (11).  Adlar EYNILE goturulub.
--
--  BU FAYLDA YALNIZ 4 SINIF VAR - qalan 7 sinifin sebebi ferqlidir:
--
--  1-4-CU SINIF: bazadaki movzular ("Alphabet - elifba", "Colours -
--  renglor" kimi ikidilli adlarla) e-derslik dersliyinden GOTURULMEYIB
--  - elle qurulmus lugetevi movzulardir, arxasinda kitab id yoxdur.
--  Alt movzu ucun menbe HEC vaxt olmayacaq.
--
--  5 VE 9-CU SINIF: kitab id 850 (5) ve 886 (9) - dersliyin oz
--  mundericat paneli YALNIZ UNIT basliqlarini verir, hech bir alt
--  ders sadalanmir (bax: sehife: 120/160, amma bolme: 1, hamisi tek
--  "UNITS" basligi altinda).  Bazadaki 6-8 movzu artiq bu tek-sevi-
--  yeli mundericatin ozudur - alt movzu cixaracaq basqa sey yoxdur.
--
--  8-Cİ SINIF: kitab id 824-un server terefi TAM BOSDUR (Cemi sehife:
--  0) - portal bu derslik ucun meznunu hele yuklemeyib (biologiya
--  9-la eyni veziyyet, bax db/88). Portal meznunu yukleyende elave
--  olunacaq.
--
--  10-CU SINIFDE 9 UNIT, BAZADA 6 MOVZU: iki movzu adinin ozu
--  birlesmeni gosterir - "Success and Health" (ing-10-success)
--  Unit 5 (Success) + Unit 6 (Health is Wealth) deyir, "Stages of
--  Life. Media" (ing-10-media) ise Unit 7 (Stages of Life) + Unit 9
--  (Media) - aralarindaki Unit 8 (Happiness) adda gorunmese de bu
--  ikisinin arasinda basqa yeri yoxdur, ona gore de ing-10-media-ya
--  gedir.  Qalan 4 unit (Kindness/Victorious/Environmental Problems/
--  Cultures) birbasa bire-bir.
--
--  BURAXILAN BENDLER: dersliyin sonundaki aparat - "Tests",
--  "Grammar bank/Bank", "Communication activities", "Audio scripts",
--  "Wordlist", "List/Irregular verb(s) list", "References", "Tracks",
--  "Activities", "Text credits, video credits and references" -
--  ders deyil, elavedir (7, 10 ve 11-ci sinifin son unitinde gelir).
--
--  YAZI QUSURLARI: 11-ci sinifde iki bend noqteden sonra bosluqsuz
--  ("Reading.A text...", "topic.A lead-in..."), bir bend apostrofu
--  SQL-de tehlukelidir ("shouldn't" -> "should not").
--
--  ELLE YAZILMIR: tools/alt_movzular.py cixarir."""

BASLIQ_COG = """\
--  90_alt_movzular_cografiya6_11.sql : COGRAFIYA 6-11 - ALT MOVZULAR
--
--  NIYE
--  Doqquzuncu fenn.  Riyaziyyat, heyat bilgisi, informatika, fizika,
--  kimya, biologiya, ingilis dili hazirdir.  Cografiya 6-ci sinifden
--  baslayir (1-5-de yoxdur).
--
--  MENBE: e-derslik.edu.az "Movzular" agaci - kitab id 859/860 (6),
--  922/923 (7), 799 (8), 881 (9), 729 (10), 814 (11).  Adlar EYNILE
--  goturulub.
--
--  DERSLIYIN QURULUSU HER SINIFDE FERQLIDIR:
--
--  6-ci sinif: kitab 859-un "Bolme 3. COL TEDQIQATI"-nin mundericat
--  sehifesinde "Bolme 4. KAINATI SEYR EDIREM" basligi "==" bolme kimi
--  DEYIL, adi bir setir kimi bolme 3-un daxilinde gorunur (fizika 7-
--  nin "Bolme 4" teləsi ile eyni portal qusuru, bax db/86).  Bu setir
--  ozu xaric edilib, sehife 68-den sonrasi cog-6-kainat-a gedir.
--
--  7-ci sinif: 7 bolme birbasa bire-bir - problemsiz.
--
--  8-ci sinif: dersliyde 10 Roma reqemli bolme (I-X) var, bazada 8
--  movzu - iki movzunun ozu birlesmeni gosterir: "Su tebeqesi ve
--  biosfer" (cog-8-hidrosfer) VI (Yerin su tebeqesi) + VII (Biosfer)
--  bolmelerini birlesdirir, "Dunya olkeleri ve ehali" (cog-8-olkeler)
--  ise VIII (Dunya olkelerinin tesnifati) + IX (Ehali ve tesserrufatin
--  erazi teskili) bolmelerini - IX-un basligindaki "Ehali" sozu movzu
--  adindaki "ehali" ile birbasa uygunlasir.
--
--  9-cu sinif: dersliyde 3 boyuk boluk var ("Giris", "I Bolme", "II
--  Bolme"), her BOLME oz icinde Roma reqemli alt-basliqlarla (I-VII)
--  bolunub - novbeti dersle EYNI sehifede olduqları ucun alt-basliq
--  qaydasi ile tutulur (informatika/kimya/biologiya-dan tanis
--  mexanizm).  "Giris" -> cog-9-xerite (movzuca uygun gelir), "I
--  Bolme" 4 alt-basliqla 4 movzuya (relyef/iqlim/sular/bioehtiyat),
--  "II Bolme" 3 alt-basliqla 3 movzuya (sivilizasiya/ehali/
--  iqtisadiyyat) - hamisi basligin ozunde adlanib.
--
--  10-cu sinif: dersliyde "Giris" + iki boyuk boluk ("1. YERIN
--  TEBIETI", "2. DUNYANIN SIYASI VE IQTISADI MENZERESI"), bunlarin da
--  icinde Roma reqemli alt-basliqlar (I-IX) var.  "Giris" ve "I.
--  YER SEMA CISMIDIR" eyni movzuya (cog-10-yer-kainat) gedir - adlari
--  demek olar eynidir.  "VII. Dunya ehalisi" ve "VIII. Siyasi
--  munasibetler" de eyni movzuye (cog-10-ehali-siyasi) - movzu adinin
--  ozu ("Ehali ve siyasi xeritə") hər ikisini eyni anda cagirir.
--
--  11-ci sinif: dersliyde 6 boyuk boluk (1-6), bazada 8 movzu.
--  "5. QLOBAL PROBLEMLER VE ONLARIN HELLI YOLLARI"-nin 6 dersi arasinda
--  enerji/erzaq ve ekoloji mövzular qarisiqdir (5.1 enerji, 5.4 erzaq,
--  qalanlari - bioloji ehtiyat/su/alicilq/tullanti - aydin ekoloji
--  deyil), sehife serhedi ile aydin bolunmur.  Boluk basliginin ozu
--  ("Qlobal problemler") cog-11-ekoloji-qlobal-in adina ("Qlobal
--  ekoloji problemler") daha yaxindir, ona gore 6 ders də ora getdi -
--  cog-11-enerji-erzaq hele 0 alt movzu qalir (biologiya-11-viruslar
--  ile eyni qerar: uydurma sehife serhedi qoyulmadi).
--  "6. BEYNELXALQ INTEQRASIYA VE QLOBALLASMA" ise aydindir - ilk ders
--  (6.1) hərfi-hərfinə "Beynelxalq inteqrasiya" adlanir, sehife 182-
--  den qalani cog-11-qloballasma-ya gedir.
--
--  BURAXILAN BENDLER: "SOZLUK" (boyuk herfle - XARIC_UMUMI-deki
--  "Sozluk" bunu tutmur, boyuk-kicik herf fərqlidir), "Terminlerin
--  izahli lugeti", "Terminler lugeti".
--
--  YAZI VE EDED QUSURLARI: 9-cu sinifde iki bend "20" evezine "2O"
--  (herf O reqem 0 evezine) yazilib - NOMRE bunlari tanimir, elle
--  duzeldildi.  Bir necə bend soz birlesmesi ("Amerikanındaxilisuları"),
--  kesik soz ("daxili sul" -> "daxili sulari", "sahə qurulus" ->
--  "sahə qurulusu", "iqlim tiplər" -> "iqlim tipləri") ve bosluqsuz
--  vergul/baglayici ("Avropa,Şimali Amerikavə") - hamisi mezmunu
--  deyismeden duzeldilib.  11-ci sinifde iki bend "Praktik ders"
--  evezine "Praktikders" yazilib.
--
--  ELLE YAZILMIR: tools/alt_movzular.py cixarir."""

BASLIQ_EDEB = """\
--  91_alt_movzular_edebiyyat5_11.sql : EDEBIYYAT 5-11 - ALT MOVZULAR
--
--  NIYE
--  Onuncu fenn.  Riyaziyyat, heyat bilgisi, informatika, fizika,
--  kimya, biologiya, ingilis dili, cografiya hazirdir.
--
--  MENBE: e-derslik.edu.az "Movzular" agaci - kitab id 845 (5),
--  911 (6), 701 (7), 793 (8), 883 (9), 732 (10), 821 (11).  Adlar
--  EYNILE goturulub.
--
--  DERSLIYIN QURULUSU HER SINIFDE FERQLIDIR - movzu adlari 5-7-de
--  TEMA (Yurd sevgisi, Tebietin gozelliyi), 8-11-de DOVR uzredir
--  (bu, derslikdeki bolgu - suni deyil).
--
--  5-7-ci sinif: "Giris"/"Edebiyyat" basliqli ilk bolme (dersliklo
--  nece isleməli - meznun deyil) ve son bolme ("Insani nece yazmali"
--  / "Insa ve esseni nece yazmali") - hər ikisi BURAXILIR (None).
--  Qalan bolmeler bire-bir movzuya.  5-ci sinifde son (7-ci) movzunun
--  bendleri arasina kitabin sonundaki aparat (Layihələr, Luget ve s.)
--  qarisib - xaric edilib; 6 ve 7-ci sinifde bu aparat dusen bolmenin
--  daxilindedir, ayrica xaric lazim gelmir.
--
--  8-ci sinif: ilk ve son bolme (Dərsliklə/İnformasiya xarakterli)
--  buraxilir.  Qalan 6 bolmeden 5-i bire-bir, "TƏNQİDİ REALİZM VƏ
--  ROMANTİZM DÖVRÜ" bolmesi ise İKİ movzuya bolunur - muellif adlari
--  ozu sinir cekir: Memmedquluzade+Sabir (tenqidi realizm) sehife
--  123-e qeder, Hadi+Cavid (romantizm, dunya edebiyyatindan Ersoy
--  daxil) sonrasi.
--
--  9-cu sinif: dersliyde 4 boyuk boluk var, ICINDE nomrelenmis
--  "merhele"lerlə (I-III) daha da bolunur.  "II merhele"nin ICINDƏ
--  3 alt-dovr var (repressiya 1920-40, muharibe 1941-60, ozunuderk
--  1961-90) - ve ozunuderk ozu bazada İKİ movzuya (poeziya/nesr)
--  ayrilib.  Muellifleri janrina gore taniyiriq (R.Rza, Kurcayli,
--  Araz, Azeroglu, Eli Kerim, Rustemxanli = seir; Sixli, Huseynov,
--  Anar, Elcin = nesr) - sehife sirasi bunlari NOVBELESDIRIR (aydin
--  bir kesim yoxdur), ona gore COX SERHEDLI (list) spec ile hər
--  muellifin oz sehifesi ayri-ayri qeyd olunub (biologiya-11-in
--  Mikrobiologiya teleside olan kimi tesadufi bolunme YOXDUR - bu,
--  hər addimda meydana cixan real sehife serhedidir).
--  "III merhele" de eyni qelible 3 movzuya bolunur (mustaqillik/
--  cenub/dunya) - "CƏNUBİ AZƏRBAYCAN ƏDƏBİYYATI" ve "DÜNYA
--  ƏDƏBİYYATI" basliqlari sehife serhedine gore duz movzuya dusur;
--  xaric edilmir, cunki EYNI metn 11-ci sinifde HƏQIQI bolmə
--  basligidir (xaric etsək 11-ci sinifin bolmesi yox olardi - bir
--  defe belə oldu, tapilib duzeldildi).
--
--  10-cu sinif: derslikde CEMI BIR bolme var ("bölmə: 1") - butun
--  kitab boyu 6 boyuk dovr basligi (AZƏRBAYCAN ŞİFAHİ.../QƏDİM
--  DOVR.../İNTİBAH.../ORTA ƏSRLƏR.../ERKƏN YENİ DOVR.../MAARİFÇİ-
--  REALİZM...) novbeti bendlə EYNI sehifede DEYIL (basliq-teleside
--  olan "eyni sehife" qaydasi bunu tutmur).  Bu basliqlar 8-ci
--  sinifin bezi bolme adlari ilə HƏRFİ EYNIDIR (herfi xaric etmek
--  8-ci sinifin real bolmelerini de silerdi - bir defe belə oldu,
--  tapilib duzeldildi) - ona gore xaric edilmir, sadece butun kitab
--  TEK bir COX SERHEDLI (list) spec ile 8 movzuya bolunur; basliqlar
--  ozleri hər movzunun ilk (bir az artiq) bendi kimi qalir.
--  "ORTA ƏSRLƏR" Nesimi+Xetayi / Fuzuli-ye,
--  "MAARİFÇİ-REALİZM" ise Zakir+Elesger+Sirvani+Vezirov / Axundzade-
--  ye bolunur - Axundzadenin bendleri (sehife 125-153) Zakirlə
--  Elesger arasinda YERLESIB (üç seqmentli list: Zakir <125,
--  Axundzade 125-153, qalanlari >=154 - iki qonsu seqment eyni
--  movzuya (maarifci) gedir).
--
--  11-ci sinif: derslikde 6 bolme, bazada 8 movzu.  "TƏNQİDİ REALİZM
--  VƏ ROMANTİZM DÖVRÜ" bolmesi 8-ci sinifdəki eyni prinsiple bolunur
--  (Memmedquluzade+Sabir / Cavid+Ehmed Cavad, sehife 37-den).
--  "CƏNUBİ AZƏRBAYCAN ƏDƏBİYYATI" (Şəhriyar) ve son bolme "DÜNYA
--  ƏDƏBİYYATINDAN SEÇMƏ" (Aytmatov) EYNI movzuya (cenub-dunya) gedir
--  - iki bolme arasinda basqa heç bir elaqe yoxdur, sadece hər ikisi
--  movzu adinin ("Cənubi Azərbaycan və dünya ədəbiyyatı") iki yarisidir.
--  "SOVET DÖVRÜ..." bolmesi Cabbarli+Vurgun / R.Rza+Mir Celala bolunur
--  (sehife 108-den).  edeb-11-nezeriyye (Edebi cereyanlar ve
--  nezeriyye) ucun mundericatda HEC bir isare yoxdur - biologiya-11-
--  viruslar ile eyni qerar: uydurma sehife qoyulmadi, 0 alt movzu
--  qalir.
--
--  YAZI QUSURLARI: bir necə muellif adinda bosluq/herf sehvi
--  (CəfərCabbarlı -> Cəfər Cabbarlı, SViktor Hüqo -> Viktor Hüqo,
--  İlsmayıl -> İsmayıl, İldınm -> İldırım) ve tirnaqdan sonra
--  bosluq (dastanında/poemasından bitisik yazilib) - mezmun
--  deyismeden duzeldilib.
--
--  ELLE YAZILMIR: tools/alt_movzular.py cixarir."""

BASLIQ_TARIX = """\
--  92_alt_movzular_tarix5_8_9_11.sql : TARIX 5,6,8,9,11 - ALT MOVZULAR
--
--  NIYE
--  On birinci fenn.  Riyaziyyat, heyat bilgisi, informatika, fizika,
--  kimya, biologiya, ingilis dili, cografiya, edebiyyat hazirdir.
--  Bu, Azerbaycan tarixi dersliyidir (Umumi tarix ayri fenndir, ayri
--  merhelede - bax roadmap qeydi).  7 ve 10-cu sinifde "Tarix" yoxdur
--  (portalda o siniflər ucun yalniz "Umumi tarix" derslikdir).
--
--  MENBE: e-derslik.edu.az "Movzular" agaci - kitab id 844 (5),
--  910 (6), 801 (8), 877 (9), 807 (11).  Adlar EYNILE goturulub.
--
--  5-CI SINIF: 5 bolme, bire-bir movzuya - problemsiz.
--
--  6-CI SINIF: dersliyin oz mundericati COX SEYREKDIR (cemi 9 ders!),
--  bazada 6 movzu var.  "II Bolme. Azerbaycanda qedim dovletler"nin
--  4 dersi (Manna/Atropatena/Albaniya/umumi baxis) HƏR BİRİ artiq
--  bazada OZ AYRI ust movzusudur - alt movzu ucun daha derinlik
--  yoxdur, bu bolme BURAXILIR (None).  Qalan iki bolme (I - ibtidai
--  cemiyyet, III - erken orta esrler) bire-bir öz movzusuna gedir.
--
--  8-Cİ SINIF: 4 bolme, bazada 6 movzu - son bolme ("4. AZƏRBAYCAN
--  XIX ƏSRİN ƏVVƏLLƏRİNDƏ") İKİ movzuya bolunur: Gulustan (31) ve
--  Turkmencay (34) muqavileleri ozleri ile bağlı dersler ARADAN-ARADAN
--  sepelenib (34-cu ders 30-31-32-33-un arasindadir), COX SERHEDLI
--  (list) spec ile hər dersin oz sehifesi qeyd olunub - tesadufi
--  bolgu yoxdur, hər sinir muellifin/mueqavilenin oz sehifesidir.
--
--  9-CU SINIF: 4 bolme, icinde "I/II fesil" (ve b.) NOMRELENMIS
--  basliqlarla daha da bolunur - basliqlar HERFI basliq kimi xaric
--  edilmir (biologiya-11-in tələsi ile eyni sebeb: basqa sinifde
--  eyni metn HƏQIQI bolme ola bilerdi), sadece sehife serhedine gore
--  duz movzuya dusurler.  "I bolme" I fesil (xix) / II fesil
--  (xx-evvel) - sehife 50-den bolunur.  "II bolme" TAM cumhuriyyete
--  (III fesil tekdir).  "III bolme" TAM sovete (IV+V fesil EYNI
--  movzuya - hər ikisi sovet dovrudur).  "IV bolme" VI fesil
--  (musteqillik) / VII fesil (yeni-dovr) - sehife 172-den bolunur.
--
--  11-Cİ SINIF: 4 bolme, icinde "I/II/...XII fesil" basliqlarla
--  daha da bolunur (9-cu sinifle eyni qelib).  "I bolme" I fesil
--  (isgal) / II-V fesil (mustemleke - hamisi mustemleke dovrunun
--  fərqli teref-i: idare, sosial-iqtisadi, Cenubi Azerbaycan,
--  medeniyyet) - sehife 21-den bolunur.  "II bolme" TAM cumhuriyyete
--  (VI+VII fesil).  "III bolme" TAM sovete (VIII+IX fesil).
--  "IV bolme" X+XI fesil (musteqillik) / XII fesil (zefer - basliq
--  "Boyuk Zefer" movzu adi ile HƏRFI eynidir) - sehife 203-den.
--
--  YAZI QUSURLARI: 6-ci sinifde "1." evezine dotless "ı." (herf,
--  reqem deyil), 8-ci sinifde iki kesik/yanlis soz (Abbasm ->
--  Abbasın, yansı -> yarısı), 9-cu sinifde kesik soz (Azərbayca ->
--  Azərbaycanda) ve "Azarbaycan" (ə evezine a), 11-ci sinifde bir
--  bendde bosluqsuz nöqte (fəsil.Şimali -> fəsil. Şimali).
--
--  ELLE YAZILMIR: tools/alt_movzular.py cixarir."""

PAKETLER = [
    {
        "ad": "riy5_11",
        "etiket": "Riyaziyyat 5-11 (8-ci sinif db/74-de)",
        "fayl": "82_alt_movzular_riy5_11.sql",
        "fenn": "riyaziyyat",
        "fayl_on": "riyaziyyat",
        "basliq": BASLIQ_RIY5_11,
        "xaric_seh": {(507, 243)},
        "duzelis": DUZELIS_RIY5_11,
        "ust": ("Riyaziyyat 5-11 ust movzu sayi 68 deyil",
                "l.code in ('5','6','7','8','9','10','11')", 68),
        "sinifler": [
            (5, [(840, ["riy-5-natural-ededler", "riy-5-adi-kesrler",
                        "riy-5-onluq-kesrler", "riy-5-faiz"]),
                 (841, ["riy-5-ifade-tenlik", "riy-5-mustevi-fiqurlar",
                        "riy-5-feza-fiqurlari", "riy-5-statistika"])]),
            (6, [(906, ["riy-6-natural-ededler", "riy-6-nisbet-faiz",
                        "riy-6-tam-ededler", "riy-6-koordinat"]),
                 (907, ["riy-6-coxluqlar", "riy-6-ifade-tenlik",
                        "riy-6-ucbucaqlar", "riy-6-sahe-hecm",
                        "riy-6-statistika"])]),
            (7, [(714, ["riy-7-statistika", "riy-7-rasional",
                        "riy-7-paralellik", "riy-7-coxhedliler",
                        "riy-7-ucbucaqlar", "riy-7-muxteser",
                        "riy-7-funksiya", "riy-7-tenlikler-sistemi",
                        "riy-7-konqruyentlik", "riy-7-situasiya"])]),
            (9, [(507, ["riy-9-kok", "riy-9-cevre", "riy-9-funksiya",
                        "riy-9-cevre-tenliyi", "riy-9-tenlikler",
                        "riy-9-coxbucaqli", "riy-9-berabersizlik",
                        "riy-9-vektorlar", "riy-9-silsile",
                        "riy-9-ehtimal"])]),
            (10, [(741, ["riy-10-funksiya", "riy-10-feza",
                         "riy-10-triq-ifade", "riy-10-sinus-kosinus",
                         "riy-10-triq-qrafik", "riy-10-coxuzlu",
                         "riy-10-triq-tenlik", "riy-10-hecm",
                         "riy-10-ustlu-loqarifm", "riy-10-statistika"])]),
            (11, [(817, ["riy-11-coxhedli", "riy-11-feza-vektor",
                         "riy-11-limit", "riy-11-firlanma",
                         "riy-11-toreme", "riy-11-firlanma-hecm",
                         "riy-11-arasdirma", "riy-11-inteqral",
                         "riy-11-statistika", "riy-11-tenlikler"])]),
        ],
    },
    {
        "ad": "riy1_4",
        "etiket": "Riyaziyyat 1, 3, 4 (2-ci sinif portalda kohnedir)",
        "fayl": "83_alt_movzular_riy1_4.sql",
        "fenn": "riyaziyyat",
        "fayl_on": "riyaziyyat",
        "basliq": BASLIQ_RIY1_4,
        "xaric_seh": set(),
        "duzelis": {
            "Gün, həftə, ay.": ("Gün, həftə, ay", "yazi"),
            "51. Məlumatların təsviri.Praktik dərs":
                ("Məlumatların təsviri. Praktik dərs", "yazi"),
            "20. İkirəqəmli ədədin ikirəqəmli ədədə bölünməsi.":
                ("İkirəqəmli ədədin ikirəqəmli ədədə bölünməsi", "yazi"),
            "22. Sadə həndəsi fiqurlar.Çevrə":
                ("Sadə həndəsi fiqurlar. Çevrə", "yazi"),
            "23. Bucaq.Bucağın ölçüsü":
                ("Bucaq. Bucağın ölçüsü", "yazi"),
            "24. Bucağın ölçülməsi.Transportir":
                ("Bucağın ölçülməsi. Transportir", "yazi"),
        },
        "ust": ("Riyaziyyat 1-4 ust movzu sayi 45 deyil",
                "l.code in ('1','2','3','4')", 45),
        "sinifler": [
            (1, [(419, ["riy-1-elamet", "riy-1-ededler-10",
                        "riy-1-muqayise", "riy-1-toplama-10",
                        "riy-1-cixma-10", "riy-1-ededler-20"]),
                 (420, ["riy-1-fiqurlar", "riy-1-toplama-20",
                        "riy-1-cixma-20", "riy-1-ededler-100",
                        "riy-1-olcme", "riy-1-melumat"])]),
            (3, [(680, ["riy-3-ededler-1000", "riy-3-toplama",
                        "riy-3-cixma", "riy-3-vurma-bolme",
                        "riy-3-ifade-tenlik"]),
                 (681, ["riy-3-fiqurlar", "riy-3-vurma-bolme-2",
                        "riy-3-kesr", "riy-3-ededler-10000",
                        "riy-3-olcme", "riy-3-melumat"])]),
            (4, [(774, ["riy-4-coxreqemli", "riy-4-toplama-cixma",
                        "riy-4-vurma-bolme", "riy-4-ifade-tenlik",
                        "riy-4-vurma-bolme-2", "riy-4-fiqurlar"]),
                 (775, [("riy-4-kesr", 19, "riy-4-onluq-kesr"),
                        "riy-4-pullar", "riy-4-olcme",
                        "riy-4-melumat"])]),
        ],
    },
    {
        "ad": "hb1_4",
        "etiket": "Heyat bilgisi 1-4",
        "fayl": "84_alt_movzular_hb1_4.sql",
        "fenn": "hayat-bilgisi",
        "fayl_on": "heyat-bilgisi",
        "basliq": BASLIQ_HB1_4,
        "xaric_seh": set(),
        "duzelis": {
            "3. ölkəm": ("Ölkəm", "yazi"),
            "11. Matenalların istifadəsi":
                ("Materialların istifadəsi", "yazi"),
        },
        "ust": ("Heyat bilgisi ust movzu sayi 22 deyil",
                "l.code in ('1','2','3','4')", 22),
        "sinifler": [
            (1, [(762, ["hey-1-men-kimem", "hey-1-saglamliq",
                        "hey-1-insanlar-esyalar", "hey-1-etraf-muhit",
                        "hey-1-ehtiyat"])]),
            (2, [(829, ["hey-2-men-mektebim", "hey-2-deyerler",
                        "hey-2-materiallar", "hey-2-yer-kuresi",
                        "hey-2-canlilar", "hey-2-ehtiyat"])]),
            (3, [(900, ["hey-3-cemiyyet", "hey-3-saglamliq",
                        "hey-3-yer-ay", "hey-3-materiallar",
                        "hey-3-bayramlar", "hey-3-tehlukesizlik"])]),
            (4, [(769, ["hey-4-canli-heyat", "hey-4-ferd-aile",
                        "hey-4-dovlet-huquq", "hey-4-saglamliq-teh",
                        "hey-4-hereket-enerji"])]),
        ],
    },
    {
        "ad": "inf1_11",
        "etiket": "Informatika 1-11",
        "fayl": "85_alt_movzular_inf1_11.sql",
        "fenn": "informatika",
        "fayl_on": "informatika",
        "basliq": BASLIQ_INF,
        "bolmebasliq": True,
        "nomre": "bos",
        "xaric_seh": set(),
        "xaric_ad": {"Terminlər", "Terminlər lüğəti", "Ədəbiyyat",
                     "ALPLogo proqramlaşdırma mühitinin komandaları",
                     "Dərslikdə işlənmiş ingiliscə söz və ifadələr",
                     "Dərslikdə işlənmiş qısaltmalar"},
        "duzelis": {
            "4.Əşyalarınmüqayisəsi": ("Əşyaların müqayisəsi", "yazi"),
            "21. Fiqurlarınçəkilməsi": ("Fiqurların çəkilməsi", "yazi"),
            "8. “VƏ”, “VƏ YA\" SÖZLƏRİ OLAN MÜRƏKKƏB MÜLAHİZƏLƏR":
                ("“VƏ”, “VƏ YA” SÖZLƏRİ OLAN MÜRƏKKƏB MÜLAHİZƏLƏR", "yazi"),
            "10. “ƏGƏR - ONDA\" QAYDASI":
                ("“ƏGƏR - ONDA” QAYDASI", "yazi"),
            "12. Verilənlərin vizuallaşdırılması.Diaqramlar":
                ("Verilənlərin vizuallaşdırılması. Diaqramlar", "yazi"),
            "3.8. Verilənləlrin axtarışı və çeşidlənməsi":
                ("Verilənlərin axtarışı və çeşidlənməsi", "yazi"),
            "1.1. informasiya sistemi və onun elementləri":
                ("İnformasiya sistemi və onun elementləri", "yazi"),
            "1.2. informasiya sistemlərinin təsnifatı":
                ("İnformasiya sistemlərinin təsnifatı", "yazi"),
            "1.7. \"Böyük verilənlər\"texnologiyası":
                ("\"Böyük verilənlər\" texnologiyası", "yazi"),
            "1.8. informasiya cəmiyyəti": ("İnformasiya cəmiyyəti", "yazi"),
            "4.5. internet xidmətləri": ("İnternet xidmətləri", "yazi"),
            "5.1. idarəetmə paneli": ("İdarəetmə paneli", "yazi"),
        },
        "ust": ("Informatika ust movzu sayi 56 deyil", "true", 56),
        "sinifler": [
            (1, [(417, ["inf-1-esyalar", "inf-1-ardicilliq",
                        "inf-1-informasiya",
                        {None: "inf-1-kompyuter",
                         "KOMPÜTERLƏ TANIŞLIQ": "inf-1-kompyuter",
                         "KOMPÜTERİN İMKANLARI": "inf-1-komp-imkanlar"}])]),
            (2, [(520, ["inf-2-obyekt", "inf-2-informasiya", "inf-2-alqoritm",
                        ("inf-2-kompyuter", 53, "inf-2-proqramlar")])]),
            (3, [(676, ["inf-3-informasiya", "inf-3-alqoritm",
                        {None: "inf-3-kompyuter",
                         "KOMPÜTERDƏ ƏMƏLİYYATLAR": "inf-3-kompyuter",
                         "QRAFİK REDAKTOR": "inf-3-qrafik"},
                        "inf-3-metn"])]),
            (4, [(360, ["inf-4-informasiya",
                        {None: "inf-4-mentiq",
                         "MƏNTİQ": "inf-4-mentiq",
                         "ALQORİTM VƏ İCRAÇILAR": "inf-4-alqoritm"},
                        {None: "inf-4-qrafik",
                         "QRAFİK REDAKTOR": "inf-4-qrafik",
                         "MƏTN REDAKTORU": "inf-4-kompyuter"}])]),
            (5, [(846, [None, "inf-5-informasiya", "inf-5-kompyuter",
                        "inf-5-tetbiqi", "inf-5-alqoritm",
                        "inf-5-internet"])]),
            (6, [(912, ["inf-6-kompyuter", "inf-6-proqram-teminati",
                        "inf-6-alqoritm", "inf-6-proqramlasdirma",
                        "inf-6-internet"])]),
            (7, [(708, ["inf-7-kompyuter", "inf-7-tetbiqi",
                        "inf-7-informasiya", "inf-7-proqramlasdirma",
                        "inf-7-internet"])]),
            (8, [(797, ["inf-8-informasiya", "inf-8-multimedia",
                        "inf-8-proqramlasdirma", "inf-8-kompyuter",
                        "inf-8-tetbiqi", "inf-8-internet"])]),
            (9, [(884, ["inf-9-kodlasdirma", "inf-9-komputer",
                        "inf-9-cedvel", "inf-9-proqramlasdirma",
                        "inf-9-texnologiya"])]),
            (10, [(736, ["inf-10-informasiya", "inf-10-model",
                         "inf-10-baza", "inf-10-sebeke",
                         "inf-10-veb", "inf-10-veb"])]),
            (11, [(822, ["inf-11-sistemler", "inf-11-modellesdirme",
                         "inf-11-baza-layihe", "inf-11-sebeke-tex",
                         "inf-11-komputer-veb", "inf-11-komputer-veb",
                         None, None])]),
        ],
    },
    {
        "ad": "fiz6_11",
        "etiket": "Fizika 6-11",
        "fayl": "86_alt_movzular_fizika6_11.sql",
        "fenn": "fizika",
        "fayl_on": "fizika",
        "basliq": BASLIQ_FIZ,
        "xaric_seh": {(867, 75), (282, 204)},
        "xaric_ad": {"Terminlər lüğəti", "Əlavələr",
                     "Fəsillərə aid məsələlərin cavabları"},
        "duzelis": {
            "1.7 Elastiklik qüvvəsi.": ("Elastiklik qüvvəsi", "yazi"),
        },
        "ust": ("Fizika ust movzu sayi 37 deyil", "true", 37),
        "sinifler": [
            (6, [(546, [("fiz-6-giris", 22, "fiz-6-olcmeler"),
                        "fiz-6-materiya", "fiz-6-madde",
                        ("fiz-6-hereket", 83, "fiz-6-enerji")])]),
            (7, [(867, ["fiz-7-olcme", "fiz-7-olcme", "fiz-7-duzxetli",
                        ("fiz-7-eyrixetli", 76, "fiz-7-atom")]),
                 (868, ["fiz-7-elektrik-sahe", "fiz-7-dovre",
                        "fiz-7-maqnit"])]),
            (8, [(931, ["fiz-8-quvve", "fiz-8-is-enerji",
                        "fiz-8-tezyiq"]),
                 (932, ["fiz-8-dalgalar", "fiz-8-istilik",
                        "fiz-8-istilik-qanun"])]),
            (9, [(472, ["fiz-9-cereyan-muhit", "fiz-9-maqnit-sahe",
                        [(123, "fiz-9-isiq"), (133, "fiz-9-guzgu-linza"),
                         (145, "fiz-9-isiq"),
                         (float("inf"), "fiz-9-guzgu-linza")],
                        [(193, "fiz-9-radioaktivlik"),
                         (float("inf"), "fiz-9-nuve")]])]),
            (10, [(734, ["fiz-10-kinematika", "fiz-10-dinamika",
                         "fiz-10-saxlanma", "fiz-10-reqs-dalga",
                         "fiz-10-saxlanma", "fiz-10-molekulyar",
                         "fiz-10-termodinamika"])]),
            (11, [(282, [("fiz-11-elektrostatika", 31,
                          "fiz-11-maqnit-induksiya"),
                         "fiz-11-cereyan-qanunlari",
                         ("fiz-11-em-reqs", 128, "fiz-11-optika"),
                         "fiz-11-atom"])]),
        ],
    },
    {
        "ad": "kim7_11",
        "etiket": "Kimya 7-11",
        "fayl": "87_alt_movzular_kimya7_11.sql",
        "fenn": "kimya",
        "fayl_on": "kimya",
        "basliq": BASLIQ_KIM,
        "xaric_seh": set(),
        "xaric_ad": {
            "Terminlər və kimyəvi anlayışlar", "Bəzi tapşırıqların cavabları",
            "Əlavələr",
            #  9-cu sinif: "Fəsil N." basliqlari + tekrarlanan ust basliq
            "Fəsil 1. Metalların ümumi xarakteristikası",
            "Fəsil 2. Əsas yarımqrup metalları",
            "Fəsil 3. Əlavə yarımqrup metalları",
            "Fəsil 4. Flüor yarımqrupu elementləri",
            "Fəsil 5. Oksigen yarımqrupu elementləri",
            "Fəsil 6. Azot yarımqrupu elementləri",
            "Fəsil 7. Karbon yarımqrupu elementləri",
            "Fəsil 8. Karbohidrogenlər",
            "Fəsil 9. Karbohidrogenlərin oksigenli və azotlu törəmələri",
            "SADƏ ÜZVİ BİRLƏŞMƏLƏRLƏ TANIŞLIQ",
            #  11-ci sinif: "fəsil N." basliqlari (kicik herflə)
            "fəsil 1. SPİRTLƏR VƏ FENOLLAR",
            "fəsil 2. ALDEHİDLƏR",
            "fəsil 3. KARBON TURŞULARI VƏ ONLARIN TÖRƏMƏLƏRİ",
            "fəsil 4. KARBOHİDRATLAR (SAXARİDLƏR)",
            "fəsil 5. NİTROBİRLƏŞMƏLƏR, AMİNLƏR, AMİNTURŞULAR VƏ ZÜLALLAR",
            "fəsil 6. POLİMERLƏR",
        },
        "duzelis": {
            "Məişətdə istifadə edilən mühüm kimyəvi birləşmələr.":
                ("Məişətdə istifadə edilən mühüm kimyəvi birləşmələr", "yazi"),
            "Ümumiləşdİrİcl sual və tapşırıqlar":
                ("Ümumiləşdirici sual və tapşırıqlar", "yazi"),
            "3.5.Sabun və sintetik yuyucu maddələr":
                ("Sabun və sintetik yuyucu maddələr", "yazi"),
        },
        "ust": ("Kimya ust movzu sayi 31 deyil", "true", 31),
        "sinifler": [
            (7, [(871, ["kim-7-elementler", "kim-7-elementler",
                        "kim-7-atom", "kim-7-birlesmeler",
                        "kim-7-qarisiqlar"]),
                 (872, ["kim-7-ayrilma", "kim-7-reaksiyalar",
                        "kim-7-tursu-esas"])]),
            (8, [(935, ["kim-8-dovri-cedvel", "kim-8-rabite",
                        "kim-8-reaksiya-tesnifat"]),
                 (936, ["kim-8-reaksiya-sureti", "kim-8-oksidlesme",
                        "kim-8-tursu-esas"])]),
            (9, [(505, [[(23, "kim-9-metal-umumi"),
                         (float("inf"), "kim-9-metallar")],
                        [(89, "kim-9-halogen-kukurd"),
                         (121, "kim-9-azot-fosfor"),
                         (float("inf"), "kim-9-karbon-silisium")],
                        "kim-9-uzvi"])]),
            (10, [(739, [None, "kim-10-alkan", "kim-10-alken",
                         "kim-10-dien-tsiklo", "kim-10-alkin",
                         "kim-10-dien-tsiklo", "kim-10-aromatik",
                         "kim-10-neft"])]),
            (11, [(349, [[(50, "kim-11-spirtler"),
                          (97, "kim-11-aldehid-tursu"),
                          (118, "kim-11-efir-yag"),
                          (float("inf"), "kim-11-karbohidrat")],
                         "kim-11-azotlu",
                         "kim-11-polimer"])]),
        ],
    },
    {
        "ad": "bio6_11",
        "etiket": "Biologiya 6-11 (9-cu sinif menbesi bos)",
        "fayl": "88_alt_movzular_biologiya6_11.sql",
        "fenn": "biologiya",
        "fayl_on": "biologiya",
        "basliq": BASLIQ_BIO,
        "bolmebasliq": True,
        "xaric_seh": set(),
        "xaric_ad": {
            "Layihə", "Təqdimat mövzuları",
            "Təqdimat və referat mövzuları", "Təqdimat üçün mövzular",
            "İstifadə edilmiş ədəbiyyat",
        },
        "duzelis": {
            "9. Bakteriyaların yayılması və təbiətdə rolu."
            " Xəstəliktörədən bakteriyalar. Viruslar":
                ("Bakteriyaların yayılması və təbiətdə rolu."
                 " Xəstəlik törədən bakteriyalar. Viruslar", "yazi"),
            "3.1 Çiçək və onun quruluşu.":
                ("Çiçək və onun quruluşu", "yazi"),
            "3.2 Tozlanma.": ("Tozlanma", "yazi"),
            "4.4 Onurğasız heyvanlarda bədənin əsas hissələri."
            "Buğumayaqlılar":
                ("Onurğasız heyvanlarda bədənin əsas hissələri."
                 " Buğumayaqlılar", "yazi"),
            "4.5 Onurğasız heyvanlarda bədənin əsas hissələri."
            "Molyusklar":
                ("Onurğasız heyvanlarda bədənin əsas hissələri."
                 " Molyusklar", "yazi"),
            "3.2 İnsan ürəyinin quruluşu və işi.":
                ("İnsan ürəyinin quruluşu və işi", "yazi"),
        },
        "ust": ("Biologiya ust movzu sayi 47 deyil", "true", 47),
        "sinifler": [
            (6, [(538, ["bio-6-tedqiqat", "bio-6-huceyre",
                        "bio-6-vegetativ", "bio-6-generativ",
                        "bio-6-hereket-qida", "bio-6-dasinma-coxalma",
                        "bio-6-muhit", "bio-6-rol"])]),
            (7, [(863, ["bio-7-huceyre-orqanizm", "bio-7-huceyre-orqanizm",
                        "bio-7-bitki", "bio-7-coxalma"]),
                 (864, ["bio-7-heyvanlar", "bio-7-muxteliflik",
                        "bio-7-ekosistem", "bio-7-saglam-heyat"])]),
            (8, [(927, ["bio-8-heyat-kimyasi", "bio-8-bitki",
                        "bio-8-qan-dovrani", "bio-8-teneffus"]),
                 (928, ["bio-8-hezm", "bio-8-coxalma",
                        "bio-8-tesnifat", "bio-8-saglamliq"])]),
            (10, [(727, [("bio-10-heyat-prosesleri", 31,
                          "bio-10-istehsal"),
                         {"Bölmə 1. Dəyişkənlik": "bio-10-deyiskenlik",
                          "Bölmə 2. Sağlam həyat": "bio-10-saglam-heyat",
                          "Bölmə 3. Epidemiologiya": "bio-10-epidemiologiya"},
                         {"Bölmə 1. Makrotəkamül": "bio-10-tekamul",
                          "Bölmə 2. İnsanın tarixi inkişafı": "bio-10-tekamul"},
                         "bio-10-genetika", "bio-10-ekologiya"])]),
            (11, [(276, ["bio-11-heyatin-yaranmasi", "bio-11-bakteriyalar",
                         "bio-11-seleksiya", "bio-11-biotexnologiya",
                         "bio-11-biosfer", "bio-11-insan-muhit",
                         "bio-11-bolunme-nezaret"])]),
        ],
    },
    {
        "ad": "ing6_11",
        "etiket": "Ingilis dili 6, 7, 10, 11 (1-4, 5, 8, 9 menbesiz/bos)",
        "fayl": "89_alt_movzular_ingilis6_11.sql",
        "fenn": "ingilis-dili",
        "fayl_on": "ingilis-dili",
        "basliq": BASLIQ_ING,
        "xaric_seh": set(),
        "xaric_ad": {
            "Tests", "Grammar bank", "Grammar Bank",
            "Communication activities", "Audio scripts", "Wordlist",
            "List of irregular verbs", "Irregular verb list",
            "Irregular verbs list", "References", "Activities", "Tracks",
            "Text credits, video credits and references",
        },
        "duzelis": {
            "Reading.A text about an unusual natural phenomenon":
                ("Reading. A text about an unusual natural phenomenon",
                 "yazi"),
            "Focus on the topic.A lead-in to the topic: No Regrets":
                ("Focus on the topic. A lead-in to the topic: No Regrets",
                 "yazi"),
            "Grammar A. Past Regrets or Mistakes should/shouldn't have done":
                ("Grammar A. Past Regrets or Mistakes should/should not"
                 " have done", "yazi"),
        },
        "ust": ("Ingilis dili ust movzu sayi 70 deyil", "true", 70),
        "sinifler": [
            (6, [(916, ["ing-6-town", "ing-6-food", "ing-6-holiday",
                        "ing-6-stories", "ing-6-journeys", "ing-6-heroes",
                        "ing-6-ideas", "ing-6-nature"])]),
            (7, [(710, ["ing-7-schools", "ing-7-technology", "ing-7-talent",
                        "ing-7-travel", "ing-7-friends", "ing-7-future"])]),
            (10, [(738, ["ing-10-kindness", "ing-10-victory",
                         "ing-10-cultures", "ing-10-environment",
                         "ing-10-success", "ing-10-success",
                         "ing-10-media", "ing-10-media", "ing-10-media"])]),
            (11, [(805, ["ing-11-whys", "ing-11-experiences",
                         "ing-11-conversation", "ing-11-regrets",
                         "ing-11-creativity", "ing-11-news"])]),
        ],
    },
    {
        "ad": "cog6_11",
        "etiket": "Cografiya 6-11 (11-ci sinif enerji-erzaq hele bos)",
        "fayl": "90_alt_movzular_cografiya6_11.sql",
        "fenn": "cografiya",
        "fayl_on": "cografiya",
        "basliq": BASLIQ_COG,
        "bolmebasliq": True,
        "xaric_seh": set(),
        "xaric_ad": {
            "SÖZLÜK", "Bölmə 4. KAİNATI SEYR EDİRƏM",
            "Terminlərin izahlı lüğəti", "Terminlər lüğəti",
        },
        "duzelis": {
            "Azərbaycan təbiətinin formalaşmas":
                ("Azərbaycan təbiətinin formalaşması", "yazi"),
            "2O. Praktik dərs. Azərbaycanın iqlimi":
                ("Praktik dərs. Azərbaycanın iqlimi", "yazi"),
            "Şimali Amerikanındaxilisuları":
                ("Şimali Amerikanın daxili suları", "yazi"),
            "Avstraliyanın daxili sul":
                ("Avstraliyanın daxili suları", "yazi"),
            "Avropa,Şimali Amerikavə Avstraliyanın əhalisi":
                ("Avropa, Şimali Amerika və Avstraliyanın əhalisi", "yazi"),
            "Təsərrüfatın sahə quruluş":
                ("Təsərrüfatın sahə quruluşu", "yazi"),
            "5O. İstehsal və qeyri-istehsal sahələri":
                ("İstehsal və qeyri-istehsal sahələri", "yazi"),
            "Azərbaycanın iqlim tiplər":
                ("Azərbaycanın iqlim tipləri", "yazi"),
            "Praktikdərs. Azərbaycanın iqtisadi rayonlarının səciyyəsi":
                ("Praktik dərs. Azərbaycanın iqtisadi rayonlarının"
                 " səciyyəsi", "yazi"),
            "Praktikdərs.Türk dünyası birliyi":
                ("Praktik dərs. Türk dünyası birliyi", "yazi"),
        },
        "ust": ("Cografiya ust movzu sayi 46 deyil", "true", 46),
        "sinifler": [
            (6, [(859, ["cog-6-mekan", "cog-6-beledci",
                        ("cog-6-col", 68, "cog-6-kainat")]),
                 (860, ["cog-6-tebiet", "cog-6-yurdumuz", "cog-6-dunya"])]),
            (7, [(922, ["cog-7-movqe", "cog-7-daxili", "cog-7-seth"]),
                 (923, ["cog-7-hava", "cog-7-iqlim", "cog-7-mesken",
                        "cog-7-iqtisadi"])]),
            (8, [(799, ["cog-8-kesfler", "cog-8-xerite",
                        "cog-8-yer-hereketi", "cog-8-tektonik",
                        "cog-8-atmosfer", "cog-8-hidrosfer",
                        "cog-8-hidrosfer", "cog-8-olkeler",
                        "cog-8-olkeler", "cog-8-ekologiya"])]),
            (9, [(881, ["cog-9-xerite",
                        {"I. Relyef və onun təsərrüfata təsiri":
                             "cog-9-relyef",
                         "II. İqlim və onun təsərrüfatda rolu":
                             "cog-9-iqlim",
                         "III. Su ehtiyatları və onların iqtisadi"
                         " əhəmiyyəti": "cog-9-sular",
                         "IV. Bioehtiyatların müxtəlifliyi və ondan"
                         " istifadə": "cog-9-bioehtiyat"},
                        {"V. Qədim və müasir sivilizasiyalar":
                             "cog-9-sivilizasiya",
                         "VI. Dünya əhalisinin müxtəlifliyi":
                             "cog-9-ehali",
                         "VII. İqtisadi-sosial həyat və onun inkişaf"
                         " yolları": "cog-9-iqtisadiyyat"}])]),
            (10, [(729, ["cog-10-yer-kainat",
                         {"I. Yer səma cismidir": "cog-10-yer-kainat",
                          "II. Yer səthinin təsviri": "cog-10-kartoqrafiya",
                          "III. Yer qabığının inkişaf tarixi":
                              "cog-10-geologiya",
                          "IV. İqlim ehtiyatları": "cog-10-iqlim-ehtiyat",
                          "V. Quru suları": "cog-10-quru-sulari",
                          "VI. Coğrafi təbəqə": "cog-10-tebeqe"},
                         {"VII. Dünya əhalisi": "cog-10-ehali-siyasi",
                          "VIII. Siyasi münasibətlər": "cog-10-ehali-siyasi",
                          "IX. Elmi-texniki inqilab və iqtisadiyyat":
                              "cog-10-eti"}])]),
            (11, [(814, ["cog-11-xerite-cis", "cog-11-tebii-ehtiyat",
                         "cog-11-demoqrafiya", "cog-11-iqtisadi-inkisaf",
                         "cog-11-ekoloji-qlobal",
                         ("cog-11-inteqrasiya", 182, "cog-11-qloballasma")])]),
        ],
    },
    {
        "ad": "edeb5_11",
        "etiket": "Edebiyyat 5-11 (11-ci sinif nezeriyye hele bos)",
        "fayl": "91_alt_movzular_edebiyyat5_11.sql",
        "fenn": "edebiyyat",
        "fayl_on": "edebiyyat",
        "basliq": BASLIQ_EDEB,
        "xaric_seh": set(),
        "xaric_ad": {
            "Layihələr", "Layihələr üzrə iş",
            "İfadəli oxuda istifadə edilən şərti işarələr",
            "Dərslikdəki bəzi terminlərin izahı",
            "Oxumağı məsləhət görürük",
            "Qısa ədəbiyyatşünaslıq terminləri lüğəti",
            "Sinifdən xaric oxu materialları",
            "Özünü qiymətləndirmə meyarları",
            "Mövzular üzrə internet mənbələri",
            "Mənbələr", "Mənbələlər",
            "Müqayisə xarakterli mətni - inşa, esse və məruzəni necə"
            " yazmalı?",
        },
        "duzelis": {
            "SViktor Hüqo. KOZETTA": ("Viktor Hüqo. KOZETTA", "yazi"),
            'Qazan bəyin oğlu Uruz bəyin dustaq olduğu boy ("Kitabi-Dədə'
            ' Qorqud"dastanında)':
                ('Qazan bəyin oğlu Uruz bəyin dustaq olduğu boy'
                 ' ("Kitabi-Dədə Qorqud" dastanında)', "yazi"),
            'Nizami Gəncəvi. Sultan Səncər və qarı ("Sirlər'
            ' xəzinəsi"poemasından)':
                ('Nizami Gəncəvi. Sultan Səncər və qarı ("Sirlər'
                 ' xəzinəsi" poemasından)', "yazi"),
            'Şah İlsmayıl Xətayi. Bahariyyə("Dəhnamə"poemasından)':
                ('Şah İsmayıl Xətayi. Bahariyyə ("Dəhnamə"'
                 ' poemasından)', "yazi"),
            "CəfərCabbarlı. Ana": ("Cəfər Cabbarlı. Ana", "yazi"),
            "Almas İldınm. Əsir Azərbaycanım":
                ("Almas İldırım. Əsir Azərbaycanım", "yazi"),
            "Əli Kərim .Qaytar ana borcunu":
                ("Əli Kərim. Qaytar ana borcunu", "yazi"),
            "Həbib Sahir.Səhənd dağı (qiymətləndirmə materialı)":
                ("Həbib Sahir. Səhənd dağı (qiymətləndirmə materialı)",
                 "yazi"),
        },
        "ust": ("Edebiyyat ust movzu sayi 48 deyil", "true", 48),
        "sinifler": [
            (5, [(845, [None, "edeb-5-sifahi", "edeb-5-yurd",
                        "edeb-5-menevi", "edeb-5-muharibe", "edeb-5-usaq",
                        "edeb-5-emek", "edeb-5-tebiet"])]),
            (6, [(911, ["edeb-6-sifahi", "edeb-6-usaq", "edeb-6-yurd",
                        "edeb-6-menevi", "edeb-6-tebiet", None])]),
            (7, [(701, [None, "edeb-7-sifahi", "edeb-7-veten",
                        "edeb-7-menevi", "edeb-7-usaq", "edeb-7-tebiet",
                        None])]),
            (8, [(793, [None, "edeb-8-qedim", "edeb-8-intibah",
                        "edeb-8-orta", "edeb-8-erken", "edeb-8-maarifci",
                        ("edeb-8-tenqidi", 123, "edeb-8-romantizm"),
                        None])]),
            (9, [(883, [None, "edeb-9-milli-demokratik",
                        [(40, "edeb-9-repressiya"),
                         (74, "edeb-9-muharibe"),
                         (83, "edeb-9-ozunuderk-seir"),
                         (98, "edeb-9-ozunuderk-nesr"),
                         (109, "edeb-9-ozunuderk-seir"),
                         (136, "edeb-9-ozunuderk-nesr"),
                         (float("inf"), "edeb-9-ozunuderk-seir")],
                        [(159, "edeb-9-mustaqillik"),
                         (170, "edeb-9-cenub"),
                         (float("inf"), "edeb-9-dunya")]])]),
            (10, [(732, [[(17, "edeb-10-sifahi"),
                          (38, "edeb-10-dede-qorqud"),
                          (57, "edeb-10-nizami"),
                          (79, "edeb-10-nesimi-xetayi"),
                          (91, "edeb-10-fuzuli"),
                          (113, "edeb-10-koroglu-vaqif"),
                          (125, "edeb-10-maarifci"),
                          (154, "edeb-10-axundzade"),
                          (float("inf"), "edeb-10-maarifci")]])]),
            (11, [(821, [("edeb-11-tenqidi-realizm", 37,
                          "edeb-11-romantizm"),
                         "edeb-11-cenub-dunya",
                         ("edeb-11-cabbarli-vurgun", 108,
                          "edeb-11-rza-mircelal"),
                         "edeb-11-ozunuderk", "edeb-11-istiqlal",
                         "edeb-11-cenub-dunya"])]),
        ],
    },
    {
        "ad": "tarix5_8_9_11",
        "etiket": "Tarix 5, 6, 8, 9, 11 (7 ve 10-da yoxdur)",
        "fayl": "92_alt_movzular_tarix5_8_9_11.sql",
        "fenn": "tarix",
        "fayl_on": "tarix",
        "basliq": BASLIQ_TARIX,
        "xaric_seh": set(),
        "xaric_ad": set(),
        "duzelis": {
            "ı. Əsas tarixi anlayışlar və zaman ölçü vahidləri":
                ("Əsas tarixi anlayışlar və zaman ölçü vahidləri", "yazi"),
            "Cəlalilər hərəkatı. Şah I Abbasm hərbi uğurları":
                ("Cəlalilər hərəkatı. Şah I Abbasın hərbi uğurları",
                 "yazi"),
            "XVI əsrin ikinci yansı - XVII əsrdə sosial-iqtisadi və"
            " ictimai həyat":
                ("XVI əsrin ikinci yarısı - XVII əsrdə sosial-iqtisadi"
                 " və ictimai həyat", "yazi"),
            "İran İslam inqilabı və Cənubi Azərbayca":
                ("İran İslam inqilabı və Cənubi Azərbaycanda", "yazi"),
            "V fəsil. Azarbaycan İkinci dünya müharibəsindən sonrakı"
            " dövrdə":
                ("V fəsil. Azərbaycan İkinci dünya müharibəsindən"
                 " sonrakı dövrdə", "yazi"),
            "II fəsil.Şimali Azərbaycan Rusiya işğalı dövründə":
                ("II fəsil. Şimali Azərbaycan Rusiya işğalı dövründə",
                 "yazi"),
        },
        "ust": ("Tarix ust movzu sayi 29 deyil", "true", 29),
        "sinifler": [
            (5, [(844, ["tarix-5-qedim", "tarix-5-dovletler",
                        "tarix-5-qalalar", "tarix-5-respublika",
                        "tarix-5-medeniyyet"])]),
            (6, [(910, ["tarix-6-ibtidai", None, "tarix-6-erken-orta"])]),
            (8, [(801, ["tarix-8-xvi-xvii", "tarix-8-xviii-1",
                        "tarix-8-xanliqlar",
                        [(163, "tarix-8-xix"),
                         (169, "tarix-8-muqavileler"),
                         (179, "tarix-8-xix"),
                         (184, "tarix-8-muqavileler"),
                         (193, "tarix-8-xix"),
                         (float("inf"), "tarix-8-muqavileler")]])]),
            (9, [(877, [("tarix-9-xix", 50, "tarix-9-xx-evvel"),
                        "tarix-9-cumhuriyyet", "tarix-9-sovet",
                        ("tarix-9-musteqillik", 172,
                         "tarix-9-yeni-dovr")])]),
            (11, [(807, [("tarix-11-isgal", 21, "tarix-11-mustemleke"),
                         "tarix-11-cumhuriyyet", "tarix-11-sovet",
                         ("tarix-11-musteqillik", 203,
                          "tarix-11-zefer")])]),
        ],
    },
    {
        "ad": "utarix6",
        "etiket": "Umumi tarix 6 (8/9/11 uygunsuzluq - bax CLAUDE.md)",
        "fayl": "93_alt_movzular_utarix6.sql",
        "fenn": "umumi-tarix",
        "fayl_on": "tarix",
        "basliq": """\
--  93_alt_movzular_utarix6.sql : UMUMI TARIX 6 - ALT MOVZULAR
--
--  NIYE
--  On ikinci fenn.  Kitab id 920 - şagird gostərdi (link
--  bu sessiyada mundericat.py-a elave edildi).
--
--  YALNIZ 6-CI SINIF: 8, 9 ve 11-ci sinifin kitablari (791/879/809,
--  eyni yolla tapilib) HEC BIR halda bazadaki movzu adlarina UYGUN
--  GəLMIR - dersliyin real bolmeleri REGIONAL-OLKE icindir (Qizilbas/
--  Mogol/Cin/Osmanli/Qafqaz, Amerika/Britaniya/Fransa/Rusiya), baza
--  ise TEMATIK dovr adlari gozleyir (Boyuk cografi kesfler/Intibah/
--  Inqilablar/Maarifcilik, Senaye cevrilisi/Napoleon/Birlesme/ABS).
--  Bu, tesadufi adlandirma ferqi deyil - iki AYRI dersliyin mundericati
--  kimi gorunur.  CLAUDE.md-de qeyd edildi, davam etmezden evvel
--  istifadeci ile aydinlasdirilmalidir.
--
--  MENBE: e-derslik.edu.az kitab id 920.  Adlar EYNILE goturulub.
--
--  DERSLIYIN QURULUSU: 3 bolme - "Tarix" (2 ders) -> utarix-6-ibtidai,
--  "Qedim Serq sivilizasiyalari" (8 ders, sehife 50-den ikiye bolunur:
--  Ehramlar/Sumer/Ikicayarasi -> mesopotamiya, Oda sitayis/Parfiya/
--  Tanrinin doyusculeri/Ipek yolu/Sahmat -> serq) ve "Qedim Qerb
--  sivilizasiyalari" (2 ders, sehife 116-dan bolunur: Avropa
--  medeniyyetinin besiyi -> yunanistan, ilk Respublika yaradanlar ->
--  roma).  utarix-6-medeniyyet ucun mundericatda isare yoxdur -
--  biologiya-11-viruslar ile eyni qerar, 0 alt movzu qalir.
--
--  ELLE YAZILMIR: tools/alt_movzular.py cixarir.""",
        "xaric_seh": set(),
        "xaric_ad": set(),
        "duzelis": {},
        "ust": ("Umumi tarix ust movzu sayi (6,8,9,11) 24 deyil",
                "l.code in ('6','8','9','11')", 24),
        "sinifler": [
            (6, [(920, ["utarix-6-ibtidai",
                        ("utarix-6-mesopotamiya", 50, "utarix-6-serq"),
                        ("utarix-6-yunanistan", 116, "utarix-6-roma")])]),
        ],
    },
]


def ascii_ad(s):
    """SQL serhi ucun: diakritikleri ve kirili ASCII-ye cevirir."""
    out = "".join(ASCII.get(c, c) for c in s)
    return "".join(c if ord(c) < 128 else "?" for c in out).strip()


def latin(s):
    s = "".join(HARF.get(c, c) for c in s).lower()
    return re.sub(r"[^a-z0-9]+", "-", s).strip("-")


def sozler(ad, valideyn=None):
    """Adin menali sozleri.  valideyn verilse, valideyn slug-inda
    artiq olan sozler atilir (kok uzre: "kesrlerin" ~ "kesrler")."""
    v = [w for w in (valideyn or "").split("-") if len(w) >= 4]
    cixis = []
    for w in latin(ad).split("-"):
        if not w or (len(w) < 3 and not w.isdigit()) or w in DAYAN:
            continue
        if any(w.startswith(k) or k.startswith(w) for k in v):
            continue
        if w not in cixis:
            cixis.append(w[:14])
    return cixis


def namizedler(ad, valideyn, tezlik_f, tezlik_u):
    """Slug quyrugu ucun namizedler - yaxsidan pise.

    Once bolme daxilinde YALNIZ bu bende aid olan sozler goturulur -
    "qrafik usulla" / "evezetme usulu" / "toplama usulu" kimi.  O
    alinmirsa ilk+son soz, sonra butun sozler.
    """
    if ad in QISA:
        return [QISA[ad]]
    f = sozler(ad, valideyn)
    u = sozler(ad)
    n = []
    for ws, tz in ((f, tezlik_f), (u, tezlik_u)):
        if not ws:
            continue
        tek = [w for w in ws if tz.get(w, 0) == 1]
        if tek:
            if len(tek) >= 2:
                n.append("-".join(tek[:2]))
            else:
                #  tek ferqlendirici soz - yanina kontekst ucun bir soz
                yan = ws[-1] if ws[-1] != tek[0] else ws[0]
                cut = sorted({tek[0], yan}, key=ws.index)
                n.append("-".join(cut))
            #  "-".join(tek) hamisi TEK ola biler (dar qrupda ferdi
            #  basliq) - o zaman butun sozler qeder uzanmasin deye 3-e
            #  kesilir; qisa namizedler (C/D/E) onsuz da asagida gelir.
            n.append(tek[0] if len(tek) == 1 else "-".join(tek[:3]))
        n.append("-".join([ws[0], ws[-1]] if len(ws) > 1 else ws))
        if len(ws) > 2:
            n.append("-".join(ws[:3]))
            n.append("-".join(ws))
    cixis = []
    for x in n:
        if x and x not in cixis:
            cixis.append(x)
    return cixis or ["movzu"]


BOLME = re.compile(r"^== (.*)$")
BEND = re.compile(r"^\s+(\d+)\s\s(.*)$")
#  Bendin evvelindeki NOMRELEME atilir: "1.4 Natural...",
#  "1.1. Natural...", "26. Kesisen...", "9.Oxsarliq...".
#  NOMRELEMEDE HOKMEN NOQTE VAR - ona gore "10-a qeder sayma" ve
#  "9 ve 10 ededleri" toxunulmaz qalir (bir defe elden getdi).
#  Kimya 11-de UC SEVIYYELI nomre var ("1.1.1. Adlandirilmasi") -
#  ikinci qrup {1,2} defe teklana biler.  Iki seviyyeli ("1.1. ")
#  ucun eyni neticeni verir - geriye uygundur.
NOMRE = re.compile(r"^(\d+(\.\d+){1,2}\.?\s+|\d+\.(?=\D)\s*)")
#  Informatika dersliklerinde nomre bezen noqtesizdir ("8 OBYEKTLER
#  QRUPU").  Riyaziyyatda bu qaydani ISLETMEK OLMAZ - "9 ve 10
#  ededleri" adinin ozudur.  Ona gore paketde acilir.
NOMRE_BOS = re.compile(r"^(\d+\.\d+\.?\s+|\d+[.\s]\s*)")


def oxu(kid, fayl_on):
    """(bolme_adi, [(seh, ad), ...]) siyahisi qaytarir."""
    yol = None
    for f in os.listdir(TOC):
        if f.endswith("-%d.txt" % kid) and f.startswith(fayl_on + "-"):
            yol = os.path.join(TOC, f)
    assert yol, "mundericat tapilmadi: %d" % kid
    bolmeler, cari = [], None
    for setir in open(yol, encoding="utf-8"):
        setir = setir.rstrip("\n")
        m = BOLME.match(setir)
        if m:
            cari = (m.group(1).strip(), [])
            bolmeler.append(cari)
            continue
        m = BEND.match(setir)
        if m and cari is not None:
            cari[1].append((int(m.group(1)), m.group(2).strip()))
    return bolmeler


def yigim(paket):
    """[(sinif, valideyn, bolme_adi, [(slug, ad, sort), ...]), ...]

    Valideyn gostericisi dord formada ola biler:
      "slug"                       - butun bolme bir movzuya
      None                         - bolme buraxilir (elave, test bloku)
      ("slug_a", sehife, "slug_b") - sehifeden sonrasi ikinci movzuya
      {None: "slug_a", "BASLIQ": "slug_b"}
                                   - bolme daxilindeki ALT BASLIQLARA gore
    Eyni slug iki bolmede tekrarlansa setirler BIRLESIR (sort davam edir).
    """
    duzelis = paket["duzelis"]
    nomre = NOMRE_BOS if paket.get("nomre") == "bos" else NOMRE
    xaric = XARIC_UMUMI | set(paket.get("xaric_ad", ()))
    netice, duzelen = [], []
    for sinif, kitablar in paket["sinifler"]:
        gorulen = set()
        siracli = {}          #  valideyn -> son sort (birlesen bolmeler ucun)
        for kid, valideynler in kitablar:
            bolmeler = oxu(kid, paket["fayl_on"])
            uygun = [b for b in bolmeler if b[0] not in xaric and b[1]]
            if len(uygun) != len(valideynler):
                raise SystemExit(
                    "kitab %d: %d bolme gozlenilirdi, %d tapildi\n  %s"
                    % (kid, len(valideynler), len(uygun),
                       "\n  ".join(b[0] for b in uygun)))
            for spec, (bolme_adi, bendler) in zip(valideynler, uygun):
                if spec is None:
                    continue
                #  Bolme daxilindeki ALT BASLIQ: nomresizdir ve NOVBETI
                #  bendle EYNI sehifededir (kitabda basliq dersin ustunde
                #  durur).  Ders deyil - siyahiya dusmur; iki movzuya
                #  bolunen bolmede ise sarhed kimi islenir.
                basliq = set()
                if paket.get("bolmebasliq"):
                    for i, (seh, xam) in enumerate(bendler):
                        if nomre.match(xam) or i + 1 >= len(bendler):
                            continue
                        if (bendler[i + 1][0] == seh
                                and nomre.match(bendler[i + 1][1])):
                            basliq.add(i)
                adlar, qrup = [], None
                for i, (seh, xam) in enumerate(bendler):
                    if i in basliq:
                        qrup = xam.strip()
                        continue
                    ad = nomre.sub("", xam).strip()
                    ad = re.sub(r"^[•]\s*", "", ad).strip()
                    if ad in xaric or (kid, seh) in paket["xaric_seh"]:
                        continue
                    acar = xam if xam in duzelis else ad
                    if acar in duzelis:
                        ad, sebeb = duzelis[acar]
                        duzelen.append((sinif, seh, xam, ad, sebeb))
                    adlar.append((seh, qrup, ad))
                #  bendleri valideynlere payla
                if isinstance(spec, tuple):
                    a, kesik, b = spec
                    paylar = [(a, [x for x in adlar if x[0] < kesik]),
                              (b, [x for x in adlar if x[0] >= kesik])]
                elif isinstance(spec, list):
                    #  COX SERHEDLI bolunme: sinif fesli mundericati
                    #  interleaved ola biler (fizika 9 - isiq/guzgu
                    #  novbelesir).  spec = [(esh_qeder, valideyn), ...,
                    #  (float("inf"), son valideyn)] - sehife < esh olan
                    #  ilk cutu goturur.
                    sira_v, gorulmus = [], set()
                    for _, v in spec:
                        if v not in gorulmus:
                            sira_v.append(v); gorulmus.add(v)
                    def hansi(seh):
                        for esh, v in spec:
                            if seh < esh:
                                return v
                        return spec[-1][1]
                    paylar = [(v, [x for x in adlar if hansi(x[0]) == v])
                              for v in sira_v]
                elif isinstance(spec, dict):
                    sira_v = []
                    for _, q_ad, _ in adlar:
                        v = spec.get(q_ad, spec.get(None))
                        if not v:
                            raise SystemExit(
                                "kitab %d: '%s' alt basligi xeritede yoxdur"
                                % (kid, q_ad))
                        if v not in sira_v:
                            sira_v.append(v)
                    paylar = [(v, [x for x in adlar
                                   if spec.get(x[1], spec.get(None)) == v])
                              for v in sira_v]
                else:
                    paylar = [(spec, adlar)]
                for valideyn, pay in paylar:
                    tezlik_f, tezlik_u = {}, {}
                    for _, _, ad in pay:
                        for w in sozler(ad, valideyn):
                            tezlik_f[w] = tezlik_f.get(w, 0) + 1
                        for w in sozler(ad):
                            tezlik_u[w] = tezlik_u.get(w, 0) + 1
                    cixis = []
                    for _, _, ad in pay:
                        nm = namizedler(ad, valideyn, tezlik_f, tezlik_u)
                        slug = None
                        for quyruq in nm:
                            if valideyn + "-" + quyruq not in gorulen:
                                slug = valideyn + "-" + quyruq
                                break
                        if slug is None:
                            esas, n = valideyn + "-" + nm[0], 1
                            while True:
                                n += 1
                                slug = "%s-%d" % (esas, n)
                                if slug not in gorulen:
                                    break
                        gorulen.add(slug)
                        siracli[valideyn] = siracli.get(valideyn, 0) + 10
                        cixis.append((slug, ad, siracli[valideyn]))
                    if cixis:
                        netice.append((sinif, valideyn, bolme_adi, cixis))
    return netice, duzelen


ORTAK = """\
--  ELLE YAZILMIR: tools/alt_movzular.py cixarir.  Duzelis skriptde
--  edilir, sonra SQL yeniden yaradilir.
--
--  XARIC EDILEN BENDLER: kitabin sonundaki aparat - "Sozluk",
--  "Cavablar", "Ozunuzu yoxlayin", "Mesele hellline numune",
--  "yarimil / sinif uzre umumilesdirici tapsiriqlar".  Bolmenin
--  dersi deyil.  db/74 de eyni qaydani tutub.
--
--  DIQQET
--   * questions cedveline TOXUNULMUR - suallar alt movzulara
--     baglanmir, teqler deyismir.  O, ayri merhelendir.
--   * Movcud ust movzu setirleri deyismir - yalniz parent kimi
--     islenir.  programs/levels-e de toxunulmur.
--   * Tekrar isledile biler (on conflict do update).
--   * db/102 movzu silmeyi bloklayir - bu fayl hec ne silmir.
-- =====================================================================
set search_path = public, extensions;
"""

SEBEBLER = {
    "duster": "portal mundericatinda dusen duster simvollari - dogru"
              " ad kitabin oz sehife basligindan",
    "rusca": "portal 10-cu sinfin 9/10-cu bolmesini rus nesrinden"
             " yigib - dogru ad kitabin oz sehife basligindan",
    "yazi": "yazi qusuru (bosluq, herf)",
}


def q(s):
    assert "'" not in s, "apostrof: %s" % s
    return "'" + s + "'"


def sql_yaz(paket, netice, duzelen):
    p = ["-- " + "=" * 69, paket["basliq"], "--", ORTAK]
    if duzelen:
        p.append("--  AD DUZELISLERI (mezmun deyismeyib):")
        for k in ("duster", "rusca", "yazi"):
            say = [d for d in duzelen if d[4] == k]
            if not say:
                continue
            p.append("--   * %s (%d): %s" % (k, len(say), SEBEBLER[k]))
            for sinif, seh, xam, ad, _ in say:
                p.append("--       %-6s s.%-3d  %s"
                         % (SIRA[sinif], seh, ascii_ad(xam)))
                eyni = (ascii_ad(NOMRE.sub("", xam).strip()) == ascii_ad(ad))
                p.append("--                    -> %s%s"
                         % (ascii_ad(ad),
                            "   [ASCII-de eyni gorunur: diakritik duzelisi]"
                            if eyni else ""))
        p.append("")

    say = 0
    p.append("insert into public.topics"
             " (subject_id, level_id, parent_id, slug, name, sort)")
    p.append("select p.subject_id, p.level_id, p.id, v.slug, v.name, v.sort")
    p.append("  from (values")
    setirler, cari_sinif = [], None
    for sinif, valideyn, bolme_adi, bendler in netice:
        if sinif != cari_sinif:
            setirler.append("    --  ============  %s sinif  ============"
                            % SIRA[sinif])
            cari_sinif = sinif
        setirler.append("    --  %s  (%s)"
                        % (ascii_ad(bolme_adi), valideyn))
        for slug, ad, sira in bendler:
            setirler.append("    (%s, %s,\n     %s, %d),"
                            % (q(valideyn), q(slug), q(ad), sira))
            say += 1
    setirler[-1] = setirler[-1].rstrip(",")
    p.extend(setirler)
    p.append("  ) as v(parent_slug, slug, name, sort)")
    p.append("  join public.topics p on p.slug = v.parent_slug")
    p.append("   and p.subject_id = (select id from public.subjects"
             " where slug = %s)" % q(paket["fenn"]))
    p.append("on conflict (subject_id, slug) do update")
    p.append("  set name = excluded.name, sort = excluded.sort,")
    p.append("      parent_id = excluded.parent_id,"
             " level_id = excluded.level_id;")
    p.append("")

    sinif_say = {}
    for sinif, _, _, bendler in netice:
        sinif_say[sinif] = sinif_say.get(sinif, 0) + len(bendler)
    fenn_adi = paket["fenn"].replace("hayat-bilgisi", "Heyat bilgisi") \
                            .replace("riyaziyyat", "Riyaziyyat")
    p.append("do $$")
    p.append("declare k int;")
    p.append("begin")
    for sinif in sorted(sinif_say):
        p.append("""  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = %s
    join public.levels   l on l.id = p.level_id and l.code = '%d';
  if k <> %d then
    raise exception '%s %s alt movzulari: %d gozlenilirdi, %% tapildi', k;
  end if;
""" % (q(paket["fenn"]), sinif, sinif_say[sinif],
       fenn_adi, SIRA[sinif], sinif_say[sinif]))
    p.append("""  --  alt movzuda sual OLMAMALIDIR
  select count(*) into k from public.questions q
    join public.topics t on t.id = q.topic_id
   where t.parent_id is not null;
  if k > 0 then
    raise exception '% sual alt movzuya baglanib - bu merhelede olmamalidir', k;
  end if;
""")
    mesaj, sert, gozlenilen = paket["ust"]
    p.append("""  --  ust movzu sayi deyismemelidir
  select count(*) into k from public.topics t
    join public.subjects s on s.id = t.subject_id and s.slug = %s
    join public.levels   l on l.id = t.level_id
   where t.parent_id is null and %s;
  if k <> %d then
    raise exception '%s: %%', k;
  end if;
""" % (q(paket["fenn"]), sert, gozlenilen, mesaj))
    p.append("  raise notice '%s: %d alt movzu hazir.';"
             % (paket.get("etiket", fenn_adi), say))
    p.append("end $$;")
    return "\n".join(p) + "\n", say


def main():
    istenen = [a for a in sys.argv[1:] if not a.startswith("--")]
    for paket in PAKETLER:
        if istenen and paket["ad"] not in istenen:
            continue
        netice, duzelen = yigim(paket)
        #  Islenmeyen duzelis acari = derslik deyisib ve ya acar sehvdir.
        #  Susmasin, sinsin - yoxsa duzelis edilmemis ad baza gedir.
        islenen = set()
        for _, _, xam, _, _ in duzelen:
            islenen.add(xam)
            islenen.add(NOMRE.sub("", xam).strip())
        qalan = [k for k in paket["duzelis"] if k not in islenen]
        if qalan:
            raise SystemExit("%s: DUZELIS acari mundericatda tapilmadi:\n  %s"
                             % (paket["ad"], "\n  ".join(qalan)))
        if "--siyahi" in sys.argv:
            for sinif, valideyn, bolme, bendler in netice:
                print("== %d  %s  (%s)" % (sinif, bolme, valideyn))
                for slug, ad, sira in bendler:
                    print("   %-48s %s" % (slug, ad))
            continue
        metn, say = sql_yaz(paket, netice, duzelen)
        open(os.path.join(DB, paket["fayl"]), "w", encoding="utf-8").write(metn)
        sinif_say = {}
        for sinif, _, _, b in netice:
            sinif_say[sinif] = sinif_say.get(sinif, 0) + len(b)
        print("db/%-32s %4d alt movzu  (%s)  duzelis %d"
              % (paket["fayl"], say,
                 " ".join("%s:%d" % (SIRA[s], sinif_say[s])
                          for s in sorted(sinif_say)),
                 len(duzelen)))


if __name__ == "__main__":
    main()
