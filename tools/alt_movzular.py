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
            n.append(tek[0] if len(tek) == 1 else "-".join(tek))
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
NOMRE = re.compile(r"^(\d+\.\d+\.?\s+|\d+\.(?=\D)\s*)")


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
    """[(sinif, valideyn, bolme_adi, [(slug, ad, sort), ...]), ...]"""
    duzelis = paket["duzelis"]
    netice, duzelen = [], []
    for sinif, kitablar in paket["sinifler"]:
        gorulen = set()
        for kid, valideynler in kitablar:
            bolmeler = oxu(kid, paket["fayl_on"])
            uygun = [b for b in bolmeler
                     if b[0] not in XARIC_UMUMI and b[1]]
            if len(uygun) != len(valideynler):
                raise SystemExit(
                    "kitab %d: %d bolme gozlenilirdi, %d tapildi\n  %s"
                    % (kid, len(valideynler), len(uygun),
                       "\n  ".join(b[0] for b in uygun)))
            for spec, (bolme_adi, bendler) in zip(valideynler, uygun):
                #  bolmenin butun adlarini once duzelt
                adlar = []
                for seh, xam in bendler:
                    ad = NOMRE.sub("", xam).strip()
                    if ad in XARIC_UMUMI or (kid, seh) in paket["xaric_seh"]:
                        continue
                    acar = xam if xam in duzelis else ad
                    if acar in duzelis:
                        ad, sebeb = duzelis[acar]
                        duzelen.append((sinif, seh, xam, ad, sebeb))
                    adlar.append((seh, ad))
                #  bolme iki movzuya bolunurse - sehifeye gore
                if isinstance(spec, tuple):
                    a, kesik, b = spec
                    paylar = [(a, [x for x in adlar if x[0] < kesik]),
                              (b, [x for x in adlar if x[0] >= kesik])]
                else:
                    paylar = [(spec, adlar)]
                for valideyn, pay in paylar:
                    tezlik_f, tezlik_u = {}, {}
                    for _, ad in pay:
                        for w in sozler(ad, valideyn):
                            tezlik_f[w] = tezlik_f.get(w, 0) + 1
                        for w in sozler(ad):
                            tezlik_u[w] = tezlik_u.get(w, 0) + 1
                    sira, cixis = 0, []
                    for _, ad in pay:
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
                        sira += 10
                        cixis.append((slug, ad, sira))
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
