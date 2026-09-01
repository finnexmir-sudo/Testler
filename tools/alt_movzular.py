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
