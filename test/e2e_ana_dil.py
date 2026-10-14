"""Ana sehife: AZ | RU duymesi.
Yoxlanir: (1) RU secende hec bir Azerbaycanca yazi qalmir, (2) AZ-a qayidanda
metn herfi-herfine evvelki kimidir, (3) secim yenilemeden sonra qalir,
(4) ?lang=ru linki rusca acir, (5) 390px-de duymeler siqir, (6) brend adi qalir.
Isle:  python3 test/e2e_ana_dil.py"""
import re, sys, pathlib
from playwright.sync_api import sync_playwright

ROOT = pathlib.Path(__file__).resolve().parent.parent
URL = "file://" + str(ROOT / "index.html")
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
AZ_HERF = re.compile(r"[əğıöüşçƏĞİÖÜŞÇ]")
TEXTS = '''()=>{const o=[];const w=document.createTreeWalker(document.body,NodeFilter.SHOW_TEXT);let n;
while(n=w.nextNode()){const p=n.parentElement;if(!p||/^(SCRIPT|STYLE)$/.test(p.tagName)||p.closest("svg"))continue;
const t=n.nodeValue.replace(/\\s+/g," ").trim();if(t)o.push(t)}return o}'''
bad = []

def ok(c, m):
    print(("OK   " if c else "XETA ") + m)
    if not c: bad.append(m)

with sync_playwright() as p:
    br = p.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    pg = br.new_page(viewport={"width": 1280, "height": 900})
    pg.goto(URL)
    az0 = pg.evaluate(TEXTS)
    ok(pg.evaluate("document.documentElement.lang") == "az", "ilk aciliş AZ")

    pg.click('.lsw [data-lang="ru"]')
    ru = pg.evaluate(TEXTS)
    ok(pg.evaluate("document.documentElement.lang") == "ru", "html lang=ru")
    # Azerbaycan herfi qalan yazi = tercumesiz qalib
    # (Bil10, e-poct, ad kimi sabitler Azerbaycan herfi dasimir)
    qalan = [t for t in ru if AZ_HERF.search(t)]
    ok(not qalan, "RU-da Azerbaycanca qalan yazi yoxdur: " + "; ".join(qalan[:5]))
    # lugetde acar yoxdursa, yazi eynen qalir - Azerbaycan herfi olmayan
    # tercumesizleri de tapaq (meselen 'Normal'): ru==az ve herf var
    deyismeyen = [a for a, b in zip(az0, ru) if a == b and re.search(r"[A-Za-z]{4,}", a)]
    sabit = {"Bil", "beta", "WhatsApp: +994 70 611 41 16", "info@bil10.az", "bil10.az"}
    deyismeyen = [t for t in deyismeyen if t not in sabit]
    ok(not deyismeyen, "tercumesiz latin yazi yoxdur: " + "; ".join(deyismeyen[:5]))
    ok("Bil10" in " ".join(ru) and pg.inner_text(".site-header .logo") .replace("\n", "").lower().startswith("bil10"), "brend adi Bil10 qalir")
    ok(pg.get_attribute(".lsw [data-lang=ru]", "aria-pressed") == "true", "RU duymesi aktivdir")
    pg.screenshot(path="/tmp/ana_ru.png", full_page=True)

    pg.reload()
    ok(pg.evaluate("document.documentElement.lang") == "ru", "yenilemeden sonra RU qalir")

    pg.click('.lsw [data-lang="az"]')
    az1 = pg.evaluate(TEXTS)
    ok(az1 == az0, "AZ-a qayidanda metn evvelki kimidir")
    ok(pg.evaluate("document.documentElement.lang") == "az", "html lang=az geri")

    pg.evaluate("localStorage.clear()")
    pg.goto(URL + "?lang=ru")
    ok(pg.evaluate("document.documentElement.lang") == "ru", "?lang=ru linki rusca acir")
    pg.evaluate("localStorage.clear()")

    m = br.new_page(viewport={"width": 390, "height": 800})
    m.goto(URL + "?lang=ru")
    ok(m.evaluate("document.documentElement.scrollWidth <= window.innerWidth"), "390px: yana sürüşmə yoxdur")
    r = m.evaluate("(()=>{const a=document.querySelector('.lsw').getBoundingClientRect(),b=document.querySelector('.enter').getBoundingClientRect();return [a.right<=b.left+1,a.width]})()")
    ok(r[0], "390px: dil duymesi giris duymesi ile toqquşmur")
    m.screenshot(path="/tmp/ana_ru_m.png")
    br.close()

print("\nNETICE:", "HAMISI KECDI" if not bad else f"{len(bad)} XETA")
sys.exit(1 if bad else 0)
