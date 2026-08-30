#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
cetinlik_analiz.py : "cetin" (difficulty=3) suallarin HEQIQETEN cetin
olub-olmadigini olcur.

Suala baxmadan, YALNIZ variantlarin qurulusuna gore zeiflik axtarir -
cunki eliminasiya faktdan yox, variantlarin bicimindən dogur:

  ILLER-ARALIQ   variantlar ciliq ildir, en boyuk fərq > 12 il
                 (sagird dovru bilirse yarisini atir)
  ERA-QARISIQ    iller muxtelif tarixi dovrlere dusur
  UZUN-CAVAB     duzgun variant qalanlardan >= 1.6 defe uzundur
  MUTLEQ-SOZ     yanlis variantda "yalniz/hec/tam/heç bir" - qelib nisani
  TEK-DOMEN      duzgun cavab movzunun acar sozunu tekrarlayir
  ABSURD         variant acıq-askar ciddi deyil

Isletmek:
    python3 tools/cetinlik_analiz.py tarix11
    python3 tools/cetinlik_analiz.py tarix9 tarix10 tarix11 --hamisi
"""
import io
import os
import re
import sys

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

#  SQL setrindeki array['a','b','c','d'] hissesini cixaran qelib.
#  IKI FORMA var:  humanitar/fenn banklarinda fenn sutunu VAR,
#  riyaziyyat banklarinda YOXDUR (fenn onsuz da birdir).  Ikisini de
#  tanimasaq riyaziyyat yoxlamadan sessizce kenarda qalir.
SETIR = re.compile(
    r"\('(?P<ext>[^']+)','(?P<fenn>[^']*)','(?P<movzu>[^']*)',"
    r"(?P<diff>\d+),(?P<rub>\d+),'(?P<body>(?:[^']|'')*)',"
    r"'(?P<why>(?:[^']|'')*)',array\[(?P<opts>.*?)\],(?P<corr>\d+)\)")
SETIR_RIY = re.compile(
    r"\('(?P<ext>[^']+)','(?P<movzu>[^']*)',"
    r"(?P<diff>\d+),(?P<rub>\d+),'(?P<body>(?:[^']|'')*)',"
    r"'(?P<why>(?:[^']|'')*)',array\[(?P<opts>.*?)\],(?P<corr>\d+)\)")

IL = re.compile(r"\b(1[0-9]{3}|20[0-9]{2})\b")
MUTLEQ = ("yalnız", "heç ", "heç bir", "tamamilə", "həmişə", "heç nə",
          "mümkün deyil", "yoxdur")

#  Tarixi dovrler - variantlar bunlarin ferqli xanalarina duserse
#  sagird "bu dovr deyil" deyib atir
DOVR = [(0, 1800), (1800, 1830), (1830, 1900), (1900, 1918), (1918, 1920),
        (1920, 1941), (1941, 1945), (1945, 1985), (1985, 1991),
        (1991, 2003), (2003, 2020), (2020, 2100)]


def dovr_no(il):
    for i, (a, b) in enumerate(DOVR):
        if a <= il < b:
            return i
    return -1


def opt_ayir(s):
    """array['a','b','c','d'] icini siyahiya cevirir"""
    out, cari, qoyt = [], [], False
    i = 0
    while i < len(s):
        c = s[i]
        if c == "'":
            if qoyt and i + 1 < len(s) and s[i + 1] == "'":
                cari.append("'"); i += 2; continue
            qoyt = not qoyt
            if not qoyt:
                out.append("".join(cari)); cari = []
            i += 1; continue
        if qoyt:
            cari.append(c)
        i += 1
    return out


def yoxla(ext, body, opts, corr):
    p = []
    duz = opts[corr - 1]
    yanlis = [o for i, o in enumerate(opts, 1) if i != corr]

    #  YALNIZ "hansi il?" suallari:  variant ciliq ildir (1827, 1827-ci il).
    #  "Turkmencay - 1828" kimi CUTLUK sualinda iller qesden uzaqdir -
    #  cetinlik adi ille uygunlasdirmaqdadir, eliminasiyada yox.
    CILIQ = re.compile(r"^\s*(1[0-9]{3}|20[0-9]{2})(-[cç][iı] il)?\s*$")
    iller = []
    for o in opts:
        m = IL.findall(o)
        iller.append(int(m[0]) if (len(m) == 1 and CILIQ.match(o)) else None)
    if all(x is not None for x in iller):
        fərq = max(iller) - min(iller)
        if fərq > 12:
            p.append("ILLER-ARALIQ(%d il)" % fərq)
            #  Qonsu iller (1917-1920) tesadufen ferqli dovr xanasina
            #  duse biler - era yoxlamasi yalniz genis araliqda menalidir
            if len(set(dovr_no(x) for x in iller)) > 2:
                p.append("ERA-QARISIQ")

    #  uzunluq tellosu
    orta = sum(len(o) for o in yanlis) / 3.0
    if orta > 0 and len(duz) >= orta * 1.6:
        p.append("UZUN-CAVAB")

    #  mutleq sozler yalniz yanlislarda
    m_y = sum(1 for o in yanlis if any(w in o.lower() for w in MUTLEQ))
    m_d = any(w in duz.lower() for w in MUTLEQ)
    if m_y >= 2 and not m_d:
        p.append("MUTLEQ-SOZ(%d)" % m_y)

    #  duzgun cavab sualin acar sozunu tekrarlayirsa
    bs = set(w.lower().strip(".,?!«»()") for w in body.split() if len(w) > 5)
    ds = set(w.lower().strip(".,?!«»()") for w in duz.split() if len(w) > 5)
    ys = set()
    for o in yanlis:
        ys |= set(w.lower().strip(".,?!«»()") for w in o.split() if len(w) > 5)
    if (bs & ds) and not (bs & ys):
        p.append("EKO-CAVAB")

    return p


def main():
    banklar = [a for a in sys.argv[1:] if not a.startswith("--")]
    hamisi = "--hamisi" in sys.argv
    if not banklar:
        print("istifade: python3 tools/cetinlik_analiz.py tarix11 [tarix9 ...]")
        return 1

    fayllar = [os.path.join(KOK, "db", f)
               for f in sorted(os.listdir(os.path.join(KOK, "db")))
               if f.endswith(".sql")]

    n = zeif = 0
    tapinti = {}
    for fp in fayllar:
        with io.open(fp, encoding="utf-8") as f:
            metn = f.read()
        qelib = SETIR if SETIR.search(metn) else SETIR_RIY
        for m in qelib.finditer(metn):
            ext = m.group("ext")
            pre = ext.split("-")[0]
            if pre not in banklar:
                continue
            if not hamisi and m.group("diff") != "3":
                continue
            opts = opt_ayir(m.group("opts"))
            if len(opts) != 4:
                continue
            body = m.group("body").replace("''", "'")
            opts = [o.replace("''", "'") for o in opts]
            n += 1
            p = yoxla(ext, body, opts, int(m.group("corr")))
            if p:
                zeif += 1
                tapinti.setdefault(m.group("movzu"), []).append(
                    (ext, body, opts, int(m.group("corr")), p))

    for movzu in sorted(tapinti):
        print("\n### %s" % movzu)
        for ext, body, opts, corr, p in tapinti[movzu]:
            print("  %-26s %s" % (ext, "; ".join(p)))
            print("      %s" % body[:96])
            print("      DUZ: %s" % opts[corr - 1])
            print("      var: %s" % " / ".join(
                o for i, o in enumerate(opts, 1) if i != corr))
    print("\n%d cetin sualdan %d-de zeiflik nisani var (%.0f%%)"
          % (n, zeif, 100.0 * zeif / n if n else 0))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
