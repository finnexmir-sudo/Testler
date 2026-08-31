#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Riyaziyyat 5-11 (8 istisna - o, db/74-de hazirdir) ucun ALT MOVZU
agacini qurur: mundericat/riyaziyyat-*.txt fayllarini oxuyur,
db/82_alt_movzular_riy5_11.sql cixarir.

NIYE SKRIPT: adlar derslikden EYNILE goturulur, amma portalin
mundericat panelinde bezi adlar naqisdir (dusen duster simvollari,
10-cu sinifde rus dilinde qalmis iki bolme).  Duzelisler burada
BIR yerdedir - SQL-in icinde deyil.  Duzelis lazim olsa skript
deyisir, sonra SQL yeniden cixarilir.

Isletmek:
    python3 tools/alt_movzular_riy.py            # SQL yazir
    python3 tools/alt_movzular_riy.py --siyahi   # yalniz siyahi
"""
import os
import re
import sys

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOC = os.path.join(KOK, "mundericat")
CIXIS = os.path.join(KOK, "db", "82_alt_movzular_riy5_11.sql")

# --------------------------------------------------------------------
#  Hansi kitab hansi sinif, bolmeler hansi movzu slug-larina baglanir.
#  Sira derslikdeki bolme sirasidir.
# --------------------------------------------------------------------
SINIFLER = [
    (5, [(840, ["riy-5-natural-ededler", "riy-5-adi-kesrler",
                "riy-5-onluq-kesrler", "riy-5-faiz"]),
         (841, ["riy-5-ifade-tenlik", "riy-5-mustevi-fiqurlar",
                "riy-5-feza-fiqurlari", "riy-5-statistika"])]),
    (6, [(906, ["riy-6-natural-ededler", "riy-6-nisbet-faiz",
                "riy-6-tam-ededler", "riy-6-koordinat"]),
         (907, ["riy-6-coxluqlar", "riy-6-ifade-tenlik",
                "riy-6-ucbucaqlar", "riy-6-sahe-hecm",
                "riy-6-statistika"])]),
    (7, [(714, ["riy-7-statistika", "riy-7-rasional", "riy-7-paralellik",
                "riy-7-coxhedliler", "riy-7-ucbucaqlar", "riy-7-muxteser",
                "riy-7-funksiya", "riy-7-tenlikler-sistemi",
                "riy-7-konqruyentlik", "riy-7-situasiya"])]),
    (9, [(507, ["riy-9-kok", "riy-9-cevre", "riy-9-funksiya",
                "riy-9-cevre-tenliyi", "riy-9-tenlikler",
                "riy-9-coxbucaqli", "riy-9-berabersizlik",
                "riy-9-vektorlar", "riy-9-silsile", "riy-9-ehtimal"])]),
    (10, [(741, ["riy-10-funksiya", "riy-10-feza", "riy-10-triq-ifade",
                 "riy-10-sinus-kosinus", "riy-10-triq-qrafik",
                 "riy-10-coxuzlu", "riy-10-triq-tenlik", "riy-10-hecm",
                 "riy-10-ustlu-loqarifm", "riy-10-statistika"])]),
    (11, [(817, ["riy-11-coxhedli", "riy-11-feza-vektor", "riy-11-limit",
                 "riy-11-firlanma", "riy-11-toreme",
                 "riy-11-firlanma-hecm", "riy-11-arasdirma",
                 "riy-11-inteqral", "riy-11-statistika",
                 "riy-11-tenlikler"])]),
]

# --------------------------------------------------------------------
#  XARIC: kitabin SONUNDAKI aparat.  Bolmenin dersi deyil - kitabin
#  arxasindaki umumi hisse.  db/74 de eyni qaydani tutub.
# --------------------------------------------------------------------
XARIC_AD = {
    "Sözlük", "Cavablar", "Cavabla", "Özünüzü yoxlayın",
    "Bölmələr üzrə ümumiləşdirici tapşırıqlar",
    "Birinci yarımil üzrə ümumiləşdirici tapşırıqlar",
    "5-ci sinif üzrə ümumiləşdirici tapşırıqlar",
    "6-cı sinif üzrə ümumiləşdirici tapşırıqlar",
}
#  9-cu sinif: bolme 10-un sonundaki s.243 kitabin ozunun yekunudur
#  (s.241-de artiq "Bolme uzre umumilesdirici tapsiriqlar" var).
XARIC_SEH = {(507, 243)}

# --------------------------------------------------------------------
#  AD DUZELISLERI.  Her biri ucun sebeb yazilib; heckim "daha yaxsi
#  seslenir" deye deyismir.
#    duster  - portalin mundericatinda duster simvollari dusub;
#              dogru ad kitabin oz sehife basligindan goturulub
#    rusca   - portal 10-cu sinfin 9/10-cu bolmesini rus nesrinden
#              yigib; dogru ad kitabin oz sehife basligindan
#    yazi    - durgu/herf qusuru (bosluq, "va"->"ve", "altindan")
# --------------------------------------------------------------------
DUZELIS = {
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

DAYAN = {"ve", "ile", "onun", "uzre", "olan", "bir", "iki", "uc", "gore",
         "steam", "ucun", "aid", "her", "bu", "da", "de", "ki", "ya",
         "bezi", "hemin", "onlar"}


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


SIRA = {5: "5-ci", 6: "6-ci", 7: "7-ci", 9: "9-cu", 10: "10-cu",
        11: "11-ci"}

BOLME = re.compile(r"^== (.*)$")
BEND = re.compile(r"^\s+(\d+)\s\s(.*)$")
NOMRE = re.compile(r"^\d+(\.\d+)?\.?\s+")


def oxu(kid, fenn="riyaziyyat"):
    """(bolme_adi, [(seh, ad), ...]) siyahisi qaytarir."""
    yol = None
    for f in os.listdir(TOC):
        if f.endswith("-%d.txt" % kid) and f.startswith(fenn + "-"):
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


def yigim():
    """[(sinif, valideyn_slug, bolme_adi, [(slug, ad, sort), ...]), ...]"""
    netice, duzelen = [], []
    for sinif, kitablar in SINIFLER:
        gorulen = set()
        for kid, valideynler in kitablar:
            bolmeler = oxu(kid)
            #  yalniz valideyni olan bolmeler (yarimil/sinif yekunu yox)
            uygun = [b for b in bolmeler
                     if b[0] not in XARIC_AD and b[1]]
            if len(uygun) != len(valideynler):
                raise SystemExit(
                    "kitab %d: %d bolme gozlenilirdi, %d tapildi\n  %s"
                    % (kid, len(valideynler), len(uygun),
                       "\n  ".join(b[0] for b in uygun)))
            for valideyn, (bolme_adi, bendler) in zip(valideynler, uygun):
                #  bolmenin butun adlarini once duzelt, sonra slug ver
                adlar = []
                for seh, xam in bendler:
                    ad = NOMRE.sub("", xam).strip()
                    if ad in XARIC_AD or (kid, seh) in XARIC_SEH:
                        continue
                    acar = xam if xam in DUZELIS else ad
                    if acar in DUZELIS:
                        ad, sebeb = DUZELIS[acar]
                        duzelen.append((sinif, seh, xam, ad, sebeb))
                    adlar.append(ad)
                tezlik_f, tezlik_u = {}, {}
                for ad in adlar:
                    for w in sozler(ad, valideyn):
                        tezlik_f[w] = tezlik_f.get(w, 0) + 1
                    for w in sozler(ad):
                        tezlik_u[w] = tezlik_u.get(w, 0) + 1
                sira, cixis = 0, []
                for ad in adlar:
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


BASLIQ = """\
-- =====================================================================
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
--  8-ci sinif db/74-dedir, tekrarlanmir.  Basqa fenne toxunulmur.
--
--  MENBE: e-derslik.edu.az sag paneldeki "Movzular" agaci -
--  kitab id 840/841 (5), 906/907 (6), 714 (7), 507 (9), 741 (10),
--  817 (11).  Adlar EYNILE goturulub.  Derslikdeki sira sort-a
--  dusub; her valideyn altinda 10-dan baslayir.
--
--  ELLE YAZILMIR: tools/alt_movzular_riy.py cixarir.  Duzelis
--  skriptde edilir, sonra SQL yeniden yaradilir.
--
--  XARIC EDILEN BENDLER: kitabin sonundaki aparat - "Sozluk",
--  "Cavablar", "Ozunuzu yoxlayin", "Birinci yarimil / sinif uzre
--  umumilesdirici tapsiriqlar".  Bolmenin dersi deyil.  db/74 de
--  eyni qaydani tutub.
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


def sql_yaz(netice, duzelen):
    p = []
    p.append(BASLIQ)
    #  duzelis siyahisi - fayl ozu izah etsin
    p.append("--  AD DUZELISLERI (mezmun deyismeyib):")
    sebebler = {
        "duster": "portal mundericatinda dusen duster simvollari - dogru"
                  " ad kitabin oz sehife basligindan",
        "rusca": "portal 10-cu sinfin 9/10-cu bolmesini rus nesrinden"
                 " yigib - dogru ad kitabin oz sehife basligindan",
        "yazi": "yazi qusuru (bosluq, herf)",
    }
    for k in ("duster", "rusca", "yazi"):
        say = [d for d in duzelen if d[4] == k]
        if not say:
            continue
        p.append("--   * %s (%d): %s" % (k, len(say), sebebler[k]))
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
    setirler = []
    cari_sinif = None
    for sinif, valideyn, bolme_adi, bendler in netice:
        if sinif != cari_sinif:
            setirler.append("    --  ============  %s sinif  ============"
                            % SIRA[sinif])
            cari_sinif = sinif
        setirler.append("    --  %s" % latin(bolme_adi).replace("-", " "))
        for slug, ad, sira in bendler:
            setirler.append("    (%s, %s,\n     %s, %d),"
                            % (q(valideyn), q(slug), q(ad), sira))
            say += 1
    setirler[-1] = setirler[-1].rstrip(",")
    p.extend(setirler)
    p.append("  ) as v(parent_slug, slug, name, sort)")
    p.append("  join public.topics p on p.slug = v.parent_slug")
    p.append("   and p.subject_id = (select id from public.subjects"
             " where slug = 'riyaziyyat')")
    p.append("on conflict (subject_id, slug) do update")
    p.append("  set name = excluded.name, sort = excluded.sort,")
    p.append("      parent_id = excluded.parent_id,"
             " level_id = excluded.level_id;")
    p.append("")

    #  oz-ozunu yoxlayan blok
    sinif_say = {}
    for sinif, _, _, bendler in netice:
        sinif_say[sinif] = sinif_say.get(sinif, 0) + len(bendler)
    p.append("do $$")
    p.append("declare k int;")
    p.append("begin")
    for sinif in sorted(sinif_say):
        p.append("""  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'riyaziyyat'
    join public.levels   l on l.id = p.level_id and l.code = '%d';
  if k <> %d then
    raise exception 'Riyaziyyat %s alt movzulari: %d gozlenilirdi, %% tapildi', k;
  end if;
""" % (sinif, sinif_say[sinif], SIRA[sinif], sinif_say[sinif]))
    p.append("""  --  alt movzuda sual OLMAMALIDIR
  select count(*) into k from public.questions q
    join public.topics t on t.id = q.topic_id
   where t.parent_id is not null;
  if k > 0 then
    raise exception '% sual alt movzuya baglanib - bu merhelede olmamalidir', k;
  end if;

  --  ust movzu sayi deyismemelidir (5..11: 8+9+10+11+10+10+10)
  select count(*) into k from public.topics t
    join public.subjects s on s.id = t.subject_id and s.slug = 'riyaziyyat'
    join public.levels   l on l.id = t.level_id
   where t.parent_id is null and l.code in ('5','6','7','8','9','10','11');
  if k <> 68 then
    raise exception 'Riyaziyyat 5-11 ust movzu sayi 68 deyil: %', k;
  end if;
""")
    p.append("  raise notice 'Riyaziyyat 5-11: %d alt movzu hazir"
             " (8-ci sinif db/74-de).';" % say)
    p.append("end $$;")
    return "\n".join(p) + "\n", say


def q(s):
    assert "'" not in s, "apostrof: %s" % s
    return "'" + s + "'"


def main():
    netice, duzelen = yigim()
    #  Islenmeyen duzelis acari = derslik deyisib ve ya acar sehvdir.
    #  Susmasin, sinsin - yoxsa duzelis edilmemis ad baza gedir.
    islenen = set()
    for _, _, xam, _, _ in duzelen:
        islenen.add(xam)
        islenen.add(NOMRE.sub("", xam).strip())
    qalan = [k for k in DUZELIS if k not in islenen]
    if qalan:
        raise SystemExit("DUZELIS acari mundericatda tapilmadi:\n  "
                         + "\n  ".join(qalan))
    if "--siyahi" in sys.argv:
        for sinif, valideyn, bolme, bendler in netice:
            print("== %d  %s  (%s)" % (sinif, bolme, valideyn))
            for slug, ad, sira in bendler:
                print("   %-46s %s" % (slug, ad))
        return
    metn, say = sql_yaz(netice, duzelen)
    open(CIXIS, "w", encoding="utf-8").write(metn)
    sinif_say = {}
    for sinif, _, _, b in netice:
        sinif_say[sinif] = sinif_say.get(sinif, 0) + len(b)
    print("db/82_alt_movzular_riy5_11.sql  -  %d alt movzu" % say)
    for s in sorted(sinif_say):
        print("   %-6s sinif : %3d" % (SIRA[s], sinif_say[s]))
    print("   ad duzelisi : %d" % len(duzelen))


if __name__ == "__main__":
    main()
