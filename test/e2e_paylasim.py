#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Paylasim karti (Open Graph) + axtaris gigiyenasi.

Niye test lazimdir: bu teqler GORUNMUR.  Biri silinse ve ya sekil
yolu qirilsa sayt normal isleyir, yalniz WhatsApp-da link quru gedir -
aylarla xeberimiz olmaya biler.

Yoxlanir: alti sehifenin her birinde og:title / og:description /
og:image / twitter:card var; sekil unvani MUTLEQdir (https://); sekil
movcuddur, 1200x630-dur ve 300 KB-dan kicikdir (WhatsApp haddi)."""
import os, struct
from playwright.sync_api import sync_playwright

ROOT   = "http://127.0.0.1:8010/"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
SEKIL  = "/home/user/testler/assets/og.png"
#  WhatsApp bundan boyuk sekli onizlemede GOSTERMIR
WA_HEDD = 300 * 1024

YOLLAR = ["index.html", "komek/", "mexfilik/",
          "muellim/", "sagird/", "valideyn/"]

fails = []
def ok(cond, label, extra=""):
    print(("  OK   " if cond else "  FAIL ") + label + (("  " + str(extra)) if extra else ""), flush=True)
    if not cond: fails.append(label)

print("A · Şəkil faylı")
ok(os.path.exists(SEKIL), "assets/og.png var")
boy = os.path.getsize(SEKIL)
ok(boy < WA_HEDD, "sekil 300 KB-dan kicikdir (WhatsApp haddi)", str(round(boy / 1024)) + " KB")
with open(SEKIL, "rb") as f:
    bas = f.read(24)
ok(bas[:8] == b"\x89PNG\r\n\x1a\n", "PNG faylidir")
en, hund = struct.unpack(">II", bas[16:24])
ok((en, hund) == (1200, 630), "olcu 1200x630", str(en) + "x" + str(hund))

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    pg = br.new_page()
    print("B · Hər səhifədə teqlər")
    for yol in YOLLAR:
        pg.goto(ROOT + yol)
        d = pg.evaluate("""() => {
            const g = n => (document.querySelector(`meta[property="${n}"]`) || {}).content
                        || (document.querySelector(`meta[name="${n}"]`) || {}).content || '';
            return {t: g('og:title'), d: g('og:description'), i: g('og:image'),
                    u: g('og:url'), c: g('twitter:card'), ti: g('twitter:image')};
        }""")
        ad = yol.rstrip("/") or "ana"
        ok(len(d["t"]) > 5 and "Bil10" in d["t"], ad + ": og:title", d["t"])
        ok(len(d["d"]) > 30, ad + ": og:description", str(len(d["d"])) + " simvol")
        #  Nisbi yol olarsa WhatsApp sekli TAPMIR - mutleq olmalidir
        ok(d["i"].startswith("https://bil10.az/"), ad + ": og:image mutleq unvandir", d["i"])
        ok(d["u"].startswith("https://bil10.az/"), ad + ": og:url mutleq unvandir", d["u"])
        ok(d["c"] == "summary_large_image", ad + ": twitter:card", d["c"])
        ok(d["ti"] == d["i"], ad + ": twitter:image og:image ile eynidir")

    #  Sekil saytdan ACILIR (yol duzgundur)
    r = pg.request.get(ROOT + "assets/og.png")
    ok(r.status == 200, "sekil saytdan acilir", r.status)

    print("C · Kanonik ünvan və noindex")
    for yol in YOLLAR:
        pg.goto(ROOT + yol)
        d = pg.evaluate("""() => ({
            c: (document.querySelector('link[rel=canonical]') || {}).href || '',
            r: (document.querySelector('meta[name=robots]') || {}).content || ''
        })""")
        ad = yol.rstrip("/") or "ana"
        ok(d["c"].startswith("https://bil10.az/"), ad + ": canonical var", d["c"])
        #  Muellim paneli giris formasidir - indeksde yeri yoxdur.
        #  Qalanlari ACIQ qalmalidir: birini sehven baglasaq saytin
        #  yarisi axtarisdan itər və bunu aylarla bilmərik.
        if ad == "muellim":
            ok("noindex" in d["r"], "muellim: noindex", d["r"])
        else:
            ok("noindex" not in d["r"], ad + ": indekslenir", d["r"] or "(teq yoxdur)")

    print("D · robots.txt və sitemap.xml")
    r = pg.request.get(ROOT + "robots.txt")
    ok(r.status == 200, "robots.txt acilir", r.status)
    rob = r.text()
    ok("Sitemap: https://bil10.az/sitemap.xml" in rob, "robots.txt sitemap-i gosterir")
    ok("Disallow: /db/" in rob and "Disallow: /test/" in rob,
       "db/ ve test/ axtarisdan baglanib")
    #  Muellim paneli robots.txt-de OLMAMALIDIR - orada baglamaq onu
    #  indeksden cixarmir, yalniz «noindex» teqini gormeye mane olur.
    ok("Disallow: /muellim/" not in rob, "muellim robots.txt ile baglanmayib")

    r = pg.request.get(ROOT + "sitemap.xml")
    ok(r.status == 200, "sitemap.xml acilir", r.status)
    sm = r.text()
    import xml.etree.ElementTree as ET
    try:
        kok = ET.fromstring(sm)
        unv = [e.text for e in kok.iter("{http://www.sitemaps.org/schemas/sitemap/0.9}loc")]
    except Exception as e:
        unv = []
        ok(False, "sitemap duzgun XML-dir", str(e)[:60])
    ok(len(unv) >= 4, "sitemap-de sehifeler var", len(unv))
    ok("https://bil10.az/" in unv, "ana sehife sitemap-dedir")
    ok(all("muellim" not in u for u in unv), "noindex sehife sitemap-de YOXDUR")
    br.close()

print()
if fails:
    print("XETA:", len(fails)); [print("  -", f) for f in fails]; raise SystemExit(1)
print("PAYLASIM: BUTUN YOXLAMALAR KECDI")
