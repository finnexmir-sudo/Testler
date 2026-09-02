#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
e-derslik.edu.az mundericatini (TOC) yigir.

Nə üçün: mövzu ağacımız (db/14_movzular.sql) real dərslik
mündəricatına uyğun olmalıdır. Dərsliyin mətni deyil, yalnız
bölmə/fəsil adları götürülür - bu, faktdır, kopyalanan məzmun deyil.

İşlətmək:
    python3 tools/mundericat.py            # hamısı
    python3 tools/mundericat.py 774 775    # yalnız verilən kitablar

Nəticə: mundericat/<id>-<ad>.txt
"""
import html
import os
import re
import sys
import time
import urllib.request

BASE = "https://www.e-derslik.edu.az"
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "mundericat")

# 1-4 sinif dord fennimiz + 5-ci sinif (orta). e-derslik portal id-leri.
KITABLAR = [
    # (id, fenn, sinif, qeyd)
    # ------- Edebiyyat 5-11 (ayrica fenn, ayri derslik) -------
    (845, "edebiyyat", 5, ""),
    (911, "edebiyyat", 6, ""),
    (701, "edebiyyat", 7, ""),
    (793, "edebiyyat", 8, ""),
    (883, "edebiyyat", 9, ""),
    (732, "edebiyyat", 10, ""),
    (821, "edebiyyat", 11, ""),
    (419, "riyaziyyat", 1, "I hisse"),
    (420, "riyaziyyat", 1, "II hisse"),
    (664, "riyaziyyat", 2, "I hisse"),
    (665, "riyaziyyat", 2, "II hisse"),
    (680, "riyaziyyat", 3, "I hisse"),
    (681, "riyaziyyat", 3, "II hisse"),
    (774, "riyaziyyat", 4, "I hisse"),
    (775, "riyaziyyat", 4, "II hisse"),
    (413, "azerbaycan-dili", 1, "I hisse"),
    (414, "azerbaycan-dili", 1, "II hisse"),
    (662, "azerbaycan-dili", 2, "I hisse"),
    (663, "azerbaycan-dili", 2, "II hisse"),
    (670, "azerbaycan-dili", 3, "I hisse"),
    (671, "azerbaycan-dili", 3, "II hisse"),
    (764, "azerbaycan-dili", 4, "I hisse"),
    (765, "azerbaycan-dili", 4, "II hisse"),
    (762, "heyat-bilgisi", 1, ""),
    (829, "heyat-bilgisi", 2, ""),
    (900, "heyat-bilgisi", 3, ""),
    (769, "heyat-bilgisi", 4, ""),
    (417, "informatika", 1, ""),
    (520, "informatika", 2, ""),
    (676, "informatika", 3, ""),
    (360, "informatika", 4, ""),
    # ------- 5-ci sinif (orta mekteb) -------
    (840, "riyaziyyat", 5, "I hisse"),
    (841, "riyaziyyat", 5, "II hisse"),
    (837, "azerbaycan-dili", 5, "I hisse"),
    (838, "azerbaycan-dili", 5, "II hisse"),
    (850, "ingilis-dili", 5, "esas xarici dil"),
    (846, "informatika", 5, ""),
    (844, "tarix", 5, "Azerbaycan tarixi"),
    # ------- 6-ci sinif -------
    (906, "riyaziyyat", 6, "I hisse"),
    (907, "riyaziyyat", 6, "II hisse"),
    (903, "azerbaycan-dili", 6, "I hisse"),
    (904, "azerbaycan-dili", 6, "II hisse"),
    (916, "ingilis-dili", 6, "esas xarici dil"),
    (912, "informatika", 6, ""),
    (910, "tarix", 6, "Azerbaycan tarixi"),
    (920, "tarix", 6, "Umumi tarix"),
    (546, "fizika", 6, ""),
    (538, "biologiya", 6, ""),
    (859, "cografiya", 6, "I hisse"),
    (860, "cografiya", 6, "II hisse"),
    # ------- 7-ci sinif -------
    (714, "riyaziyyat", 7, ""),
    (696, "azerbaycan-dili", 7, "I hisse"),
    (697, "azerbaycan-dili", 7, "II hisse"),
    (710, "ingilis-dili", 7, ""),
    (708, "informatika", 7, ""),
    (723, "tarix", 7, "Umumi tarix"),
    (867, "fizika", 7, "I hisse"),
    (868, "fizika", 7, "II hisse"),
    (871, "kimya", 7, "I hisse"),
    (872, "kimya", 7, "II hisse"),
    (863, "biologiya", 7, "I hisse"),
    (864, "biologiya", 7, "II hisse"),
    (922, "cografiya", 7, "I hisse"),
    (923, "cografiya", 7, "II hisse"),
    # ------- 8-ci sinif -------
    (393, "riyaziyyat", 8, ""),
    (784, "azerbaycan-dili", 8, ""),
    (824, "ingilis-dili", 8, "esas xarici dil"),
    (788, "ingilis-dili", 8, "ikinci xarici dil"),
    (797, "informatika", 8, ""),
    (801, "tarix", 8, "Azerbaycan tarixi"),
    (791, "tarix", 8, "Umumi tarix"),
    (931, "fizika", 8, "I hisse"),
    (932, "fizika", 8, "II hisse"),
    (935, "kimya", 8, "I hisse"),
    (936, "kimya", 8, "II hisse"),
    (927, "biologiya", 8, "I hisse"),
    (928, "biologiya", 8, "II hisse"),
    (799, "cografiya", 8, ""),
    # ------- 9-cu sinif -------
    (507, "riyaziyyat", 9, ""),
    (875, "azerbaycan-dili", 9, "tedris dili"),
    (886, "ingilis-dili", 9, "esas xarici dil"),
    (887, "ingilis-dili", 9, "ikinci xarici dil"),
    (884, "informatika", 9, ""),
    (877, "tarix", 9, "Azerbaycan tarixi"),
    (879, "tarix", 9, "Umumi tarix"),
    (472, "fizika", 9, ""),
    (505, "kimya", 9, ""),
    (467, "biologiya", 9, ""),
    (881, "cografiya", 9, ""),
    # ------- 10-cu sinif -------
    (741, "riyaziyyat", 10, ""),
    (725, "azerbaycan-dili", 10, "I"),
    (726, "azerbaycan-dili", 10, "II"),
    (738, "ingilis-dili", 10, "esas xarici dil"),
    (736, "informatika", 10, ""),
    (745, "tarix", 10, "Umumi tarix"),
    (734, "fizika", 10, ""),
    (739, "kimya", 10, ""),
    (727, "biologiya", 10, ""),
    (729, "cografiya", 10, ""),
    # ------- 11-ci sinif -------
    (817, "riyaziyyat", 11, ""),
    (812, "azerbaycan-dili", 11, ""),
    (805, "ingilis-dili", 11, "esas xarici dil"),
    (822, "informatika", 11, ""),
    (807, "tarix", 11, "Azerbaycan tarixi"),
    (809, "tarix", 11, "Umumi tarix"),
    (282, "fizika", 11, ""),
    (349, "kimya", 11, ""),
    (276, "biologiya", 11, ""),
    (814, "cografiya", 11, ""),
]

TEG = re.compile(r"<[^>]*>")
BOSLUQ = re.compile(r"\s+")


def yukle(url):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=40) as r:
        return r.read().decode("utf-8", "replace")


def temizle(s):
    return BOSLUQ.sub(" ", html.unescape(TEG.sub(" ", s))).strip()


BOX = re.compile(
    r'<div class="box">\s*<h6>(.*?)</h6>(.*?)</div>', re.S)
LINK = re.compile(
    r'<li><a href="#[^"]*?page(\d+)\.xhtml">(.*?)</a></li>', re.S)


def mundericat(pleyer):
    """Pleyerin «Mövzular» panelini oxuyur.

    Qaytarir: [(bolme_adi, [(seh_no, movzu_adi), ...]), ...]
    Yalniz basliqlar goturulur - dersliyin metni yox.
    """
    i = pleyer.find('topics-box')
    if i < 0:
        return []
    j = pleyer.find('<!-- /topics box', i)
    blok = pleyer[i:j if j > 0 else len(pleyer)]
    netice = []
    for m in BOX.finditer(blok):
        bolme = temizle(m.group(1))
        movzular = [(int(a), temizle(b)) for a, b in LINK.findall(m.group(2))]
        if bolme or movzular:
            netice.append((bolme, movzular))
    return netice


def sehife_sayi(pleyer):
    m = re.search(r"Cəmi səhifə\s*(\d+)", pleyer)
    return int(m.group(1)) if m else 0


def main():
    istenen = set(int(a) for a in sys.argv[1:]) if len(sys.argv) > 1 else None
    os.makedirs(OUT, exist_ok=True)
    umumi = 0
    for kid, fenn, sinif, qeyd in KITABLAR:
        if istenen is not None and kid not in istenen:
            continue
        try:
            pleyer = yukle(BASE + "/player/index3.php?book_id=%d" % kid)
        except Exception as e:
            print("  X %d - %s" % (kid, e))
            continue
        ad = "%s %d %s" % (fenn, sinif, qeyd)
        toc = mundericat(pleyer)
        n = sehife_sayi(pleyer)
        nm = sum(len(v) for _, v in toc)
        yol = os.path.join(OUT, "%s-%d-%d.txt" % (fenn, sinif, kid))
        with open(yol, "w", encoding="utf-8") as f:
            f.write("# %s\n" % ad.strip())
            f.write("# mənbə: %s/player/index3.php?book_id=%d\n" % (BASE, kid))
            f.write("# səhifə: %d · bölmə: %d · mövzu: %d\n\n" % (n, len(toc), nm))
            for bolme, movzular in toc:
                f.write("== %s\n" % bolme)
                for seh, mv in movzular:
                    f.write("   %3d  %s\n" % (seh, mv))
                f.write("\n")
        print("  %-26s %2d bölmə %3d mövzu %3d səh  -> %s"
              % (ad.strip()[:26], len(toc), nm, n, os.path.basename(yol)))
        umumi += nm
        time.sleep(0.4)
    print("\ncəmi %d mövzu" % umumi)


if __name__ == "__main__":
    main()
