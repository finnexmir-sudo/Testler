#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Paylasim karti (Open Graph) - butun sehifelerde.

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
    br.close()

print()
if fails:
    print("XETA:", len(fails)); [print("  -", f) for f in fails]; raise SystemExit(1)
print("PAYLASIM: BUTUN YOXLAMALAR KECDI")
