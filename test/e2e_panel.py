#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Muellim panelini real brauzerde, real sxem uzerinde surur."""
import re, sys, time
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"


def db(sql, args=None, one=False):
    """Bazani BIRBASA oxumaq - ekranin dedikleri ile uzlasirmi.
       Ekran duz gostere biler, altda melumat yanlis yazilmis ola
       biler (proqram/sinif uygunsuzlugu mehz bele gizlenirdi)."""
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            return cur.fetchone() if one else cur.fetchall()

PANEL = "http://127.0.0.1:8010/muellim/index.html"
# Tehlukesizlik kilidi: yoxlama YALNIZ yerli mock-a getmelidir.
# Bir defe ?v=N nisani route qalibini pozdu ve test heqiqi layiheye getdi.
BLOCK = "**://*.supabase.co/**"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
TEST_CFG = """window.CFG = {
  SUPABASE_URL: "http://127.0.0.1:54321",
  SUPABASE_ANON_KEY: "test-anon-key",
  STUDENT_URL: "https://example.test/Testler/"
};"""

def empty_icons(pg):
    """Terif olunmayan ikon: <svg> var, icinde hec ne yoxdur."""
    return pg.evaluate(
        "() => [...document.querySelectorAll('svg')]"
        ".filter(s => s.innerHTML.trim() === '').length")

fails = []
def ok(cond, label, extra=""):
    print(("  OK   " if cond else "  FAIL ") + label + (("  " + str(extra)) if extra else ""), flush=True)
    if not cond: fails.append(label)

def db_nick(full):
    """Bazadan qisa formani oxuyur - lovhede gorunen addir."""
    import psycopg2, psycopg2.extras
    with psycopg2.connect("host=/tmp port=55432 user=postgres dbname=panel_e2e",
                          cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute("select display_name d from public.students where full_name = %s", (full,))
        r = cur.fetchone()
        return r["d"] if r else None


def new_page(ctx):
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=TEST_CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))
    return pg

def signup(pg, email, name, pw="parol1234"):
    pg.goto(PANEL); pg.wait_for_timeout(300)
    pg.click("#btnSwap")
    pg.fill("#fname", name); pg.fill("#email", email); pg.fill("#pass", pw)
    pg.click("#btnAuth")

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 430, "height": 900},
                         permissions=["clipboard-read", "clipboard-write"])
    pg = new_page(ctx)

    print("0 · İlk səhifə")
    # Iki defe CSS sinif adi toqqusdu (.mark, .top) - ikisi de yalniz
    # gozle goruldu.  Ilk sehife artiq YOXLANILIR.
    for w, h, lbl in ((1280, 900, "masaustu"), (390, 844, "telefon")):
        pg.set_viewport_size({"width": w, "height": h})
        pg.goto("http://127.0.0.1:8010/index.html"); pg.wait_for_timeout(400)
        ok(not pg.evaluate("document.documentElement.scrollWidth > window.innerWidth+1"),
           "ilk sehife " + lbl + ": yana surusme yoxdur")
        ok(pg.evaluate("[...document.querySelectorAll('svg')]"
                       ".filter(s=>!s.innerHTML.trim()).length") == 0,
           "ilk sehife " + lbl + ": bos ikon yoxdur")
        ok(pg.evaluate("""() => {
             const h = document.querySelector('.site'), r = h.getBoundingClientRect();
             const l = document.querySelector('.logo').getBoundingClientRect();
             return r.width > window.innerWidth * 0.5 && l.left < window.innerWidth * 0.4;
           }"""), "ilk sehife " + lbl + ": ustluk duzgun yerlesir")
    # Telefonda dikine bosluq.  Masaustu ucun secilmis olculer oldugu kimi
    # qalanda sehife "bos" gorunurdu: hero-nun alti (76px) bolmenin ustu
    # (64px) ile toplanib 140px bosluq verirdi.  Yan bosluq sutunlar
    # birlesende gedir, dikine ise ozu-ozune azalmir - olculmelidir.
    pg.set_viewport_size({"width": 360, "height": 740})
    pg.goto("http://127.0.0.1:8010/index.html"); pg.wait_for_timeout(400)
    #  Olcu SON hero elementinden gedir: qapilardan sonra valideyn
    #  sətri de var.  Yoxlamanin meqsedi "olu bosluq olmasin"dir -
    #  MEZMUN elave etmek onu pozmamalidir, bosluq buraxmaq pozmalidir.
    ara = pg.evaluate("""() => {
        const last = document.querySelector('.pdoor') ||
                     document.querySelector('.doors');
        const d = last.getBoundingClientRect();
        const s = document.querySelector('.stitle').getBoundingClientRect();
        return Math.round(s.top - d.bottom);
      }""")
    ok(ara <= 80, "telefonda bolmeler arasi bosluq olculudur", "%dpx" % ara)
    #  Valideyn zolagi: kecid olmalidir (evvel cilpaq <p> idi) ve
    #  kartlarla eyni enle durmalidir - iki seliqeli kartin altinda
    #  yarimciq gorunmesin.
    ok(pg.locator("a.pdoor[href='valideyn/']").count() == 1,
       "valideyn zolagi kecidddir")
    en = pg.evaluate("""() => {
        const d = document.querySelector('.doors').getBoundingClientRect();
        const p = document.querySelector('.pdoor').getBoundingClientRect();
        return Math.round(Math.abs(p.width - d.width));
      }""")
    ok(en <= 2, "valideyn zolagi kartlarla eyni endedir", "%dpx ferq" % en)
    ok(pg.locator(".pdoor .ic svg").count() == 1, "zolaqda ikon var")

    ok(pg.locator('a[href="muellim/"]').count() >= 1, "muellim kecidi var")
    ok(pg.locator('a[href="sagird/"]').count() == 1, "sagird kecidi var")
    ok("Bil10" in pg.inner_text(".logo"), "ad gorunur", pg.inner_text(".logo").replace("\n"," "))
    pg.set_viewport_size({"width": 430, "height": 900})

    print("A · Qeydiyyat və hesab quraşdırması")
    pg.goto(PANEL); pg.wait_for_timeout(400)
    ok(pg.is_visible("#btnAuth"), "giris ekrani acilir")
    ok("Daxil ol" in pg.inner_text("#main"), "basliq duzgun")

    signup(pg, "leyla@test.az", "Leyla Muellim")
    pg.wait_for_selector("#btnSetup", timeout=8000)
    ok(True, "qeydiyyatdan sonra quraşdirma ekrani acilir")

    pg.select_option("#atype", "tutor")
    pg.fill("#aname", "Leyla muellim - riyaziyyat")
    pg.click("#btnSetup")
    pg.wait_for_selector("#btnGroup", timeout=8000)
    ok(True, "hesab yaranir, esas ekran acilir")
    ok("0 / 5" in pg.inner_text(".seat"), "yer gostericisi 0 / 5", pg.inner_text(".seat").replace("\n"," "))
    ok("Leyla Muellim" in pg.inner_text("#topWho"), "ustlukde ad gorunur")

    ok(empty_icons(pg) == 0, "esas ekranda bos ikon yoxdur", empty_icons(pg))

    #  Paket gizlidir (SHOW_PLANS = false) - uc kart qalir
    ok(pg.locator(".qact").count() == 3, "suretli emeliyyatlar 3 kartdir",
       pg.locator(".qact").count())
    #  telefonda (430px) kart gizlidir - alt menyu eyni uc duymeni dasiyir
    ok(not pg.locator(".card.quick").is_visible(), "telefonda suretli emeliyyatlar gizlidir (alt menyu var)")
    ok(pg.locator("#btnMe").count() == 1, "profil qisayolu var")
    ok(pg.locator("#bnav a").count() == 4, "alt naviqasiya 4 bendlidir",
       pg.locator("#bnav a").count())
    #  PWA: manifest, tema rengi, ikonlar, qurasdirma skripti
    ok(pg.locator('link[rel="manifest"]').count() == 1, "manifest baglanib")
    mf = pg.evaluate("""async () => {
        const r = await fetch('manifest.json');
        if (!r.ok) return null;
        return await r.json();
    }""")
    ok(mf is not None, "manifest.json yuklenir")
    ok(mf and mf.get("display") == "standalone", "standalone rejimi",
       mf and mf.get("display"))
    ok(mf and mf.get("start_url") == "./", "start_url duzgun")
    ok(mf and len(mf.get("icons") or []) == 4, "dord ikon var",
       mf and len(mf.get("icons") or []))
    ok(any(i.get("purpose") == "maskable" for i in (mf or {}).get("icons", [])),
       "maskable ikon var")
    ok(pg.locator('meta[name="theme-color"]').count() == 1, "tema rengi var")
    ico = pg.evaluate("""async () => {
        const r = await fetch('../assets/icons/icon-512.png');
        return r.ok ? r.headers.get('content-type') : null;
    }""")
    ok(ico is not None and "image" in ico, "ikon fayli acilir", ico)
    #  http-de service worker QURULMAMALIDIR - yoxlamalar deterministik qalsin
    swn = pg.evaluate("""async () => {
        if (!('serviceWorker' in navigator)) return 0;
        const r = await navigator.serviceWorker.getRegistrations();
        return r.length;
    }""")
    ok(swn == 0, "http-de service worker qurulmur", swn)

    nvt = " | ".join(pg.locator("#bnav a").all_inner_texts())
    ok("Paket" not in nvt, "alt menyuda Paket yoxdur", nvt)
    ok(pg.locator("#btnPkt").count() == 0, "suretli emeliyyatlarda Paket yoxdur")
    #  unvanla da acilmir - ana sehifeye qaytarir
    pg.goto(PANEL + "#/p"); pg.wait_for_timeout(700)
    ok("Paketlər" not in pg.inner_text("#main"), "unvanla da Paket acilmir")
    pg.goto(PANEL + "#/"); pg.wait_for_selector("#gForm", timeout=8000)
    # kontekst 430px-dedir - dar ekranda panel gorunur, masaustunde yox
    ok(pg.locator("#bnav").is_visible(), "dar ekranda alt panel gorunur")
    pg.set_viewport_size({"width": 1280, "height": 900})
    pg.wait_for_timeout(200)
    ok(not pg.locator("#bnav").is_visible(), "masaustunde alt panel gizlidir")
    pg.set_viewport_size({"width": 430, "height": 900})
    pg.wait_for_timeout(200)
    pg.locator("#bnav a", has_text="Profil").click()
    pg.wait_for_selector("#meSubs", timeout=8000)
    ok(True, "alt paneldan profil acilir")
    pg.locator("#btnBack").click()
    pg.wait_for_selector("#btnGroup", timeout=8000)

    ok(pg.locator("#btnBell").count() == 1, "ustlukde zeng duymesi var")
    pg.click("#btnBell")
    pg.wait_for_selector("#btnBack", timeout=8000)
    # h2 CSS ile boyudulur - metn yox, unvan yoxlanilir
    ok(pg.evaluate("location.hash") == "#/n", "bildirisler ekrani acilir",
       pg.evaluate("location.hash"))
    ok("abunə paketi ilə" in pg.inner_text("#main"),
       "paketsiz hesabda siqnal upsell gorunur")
    pg.locator("#btnBack").click()
    pg.wait_for_selector("#btnGroup", timeout=8000)

    print("B · Qrup yaratmaq")
    # siniflər ayrıca sorğu ilə gəlir - dolmasını gözləyirik
    pg.wait_for_function("document.querySelectorAll('#glevel option').length > 1",
                         timeout=8000)
    ok(pg.locator("#glevel option").count() >= 5, "sinif siyahisi dolur",
       pg.locator("#glevel option").count())
    pg.fill("#gname", "Cume qrupu")
    pg.select_option("#glevel", "3")
    pg.click("#btnGroup")
    pg.wait_for_selector("#groups .item", timeout=8000)
    txt = pg.inner_text("#groups")
    ok("Cume qrupu" in txt, "qrup siyahida gorunur")
    ok("3-cü sinif" in txt, "SINIF siyahida gorunur", txt.replace("\n", " ")[:70])
    ok("0 şagird" in txt, "sagird sayi 0")
    # qosulma kodu sagird axininda istifade olunmur - UI-da gosterilmir
    code = re.search(r"\b([A-Z2-9]{8})\b", txt.replace("\n", " "))
    ok(code is None, "qosulma kodu siyahida GORUNMUR",
       code.group(1) if code else "")

    #  YUXARI SINIF.  Panel evvel hemise p_program_slug="ibtidai"
    #  gonderirdi, server ise sinfi HEMIN proqramin icinde axtarirdi -
    #  8-ci sinif orada olmadigi ucun qrup SINIFSIZ yaranirdi.
    #  Sessizce: xeta yox, sadece sinif itirdi.  1-4 islerdi, 5-11 yox.
    pg.fill("#gname", "Sekkizinci qrup")
    pg.select_option("#glevel", "8")
    pg.click("#btnGroup")
    pg.wait_for_function(
        "document.querySelector('#groups') && "
        "document.querySelector('#groups').innerText.indexOf('Sekkizinci qrup') >= 0",
        timeout=8000)
    t8 = pg.inner_text("#groups")
    ok("8-ci sinif" in t8, "YUXARI sinif (8) itmir - qrup sinifli yaranir",
       [x for x in t8.split("\n") if "Sekkizinci" in x or "sinif" in x][:3])
    row = db("""select l.code as sinif, p.slug as program
                  from public.classes c
                  left join public.levels   l on l.id = c.level_id
                  left join public.programs p on p.id = c.program_id
                 where c.name = 'Sekkizinci qrup'""", one=True)
    ok(row is not None and row["sinif"] == "8", "bazada sinif 8-dir",
       row and row["sinif"])
    #  Proqram GONDERILENDEN yox, SINIFDEN toremelidir
    ok(row is not None and row["program"] not in (None, "ibtidai"),
       "proqram sinifden toreyib (ibtidai qalmayib)", row and row["program"])

    print("C · Şagird əlavə etmək")
    pg.click("#groups .item")
    pg.wait_for_selector("#btnStu", timeout=8000)
    ok("Cume qrupu" in pg.inner_text("h1"), "qrup ekrani acilir")
    ok("3-cü sinif" in pg.inner_text("#gMeta"), "sinif qrup ekraninda da gorunur",
       pg.inner_text("#gMeta").replace("\n", " "))

    pg.fill("#sname", "Aysu Məmmədova")
    pg.click("#btnStu")
    pg.wait_for_selector(".stu", timeout=8000)
    s = pg.inner_text(".stu")
    ok("Aysu Məmmədova" in s, "sagird siyahiya dusur")
    ok("Aysu M." not in s, "muellim yalniz tam adi gorur", s.replace("\n", " ")[:60])
    scode = re.search(r"\b([A-Z2-9]{8})\b", s)
    ok(scode is not None, "giris kodu gorunur", scode.group(1) if scode else s[:60])
    first_code = scode.group(1) if scode else None

    ok(pg.locator("#snick").count() == 0,
       "leqeb sahesi yoxdur - qisa forma avtomatik yaranir")
    pg.fill("#sname", "Kənan Əliyev")
    pg.click("#btnStu"); pg.wait_for_timeout(900)
    ok(pg.locator(".stu").count() == 2, "ikinci sagird elave olunur")
    ok("Kənan Əliyev" in pg.inner_text("#stu"), "siyahida TAM ad gorunur")
    ok("Kənan Ə." not in pg.inner_text("#stu"),
       "qisa forma siyahida gorunmur - muellim ancaq tam adi gorur")

    print("D · WhatsApp və kopyalama")
    pg.evaluate("window.__opened=null; window.open = (u)=>{ window.__opened=u; return null; }")
    pg.locator("[data-wa]").first.click(); pg.wait_for_timeout(200)
    wa = pg.evaluate("window.__opened")
    ok(wa and wa.startswith("https://wa.me/?text="), "wa.me linki acilir", (wa or "")[:45])
    ok(wa and "example.test" in wa, "linkde sagird tetbiqinin unvani var")
    ok(wa and first_code and first_code in wa, "linkde giris kodu var")

    pg.locator("[data-copy]").first.click(); pg.wait_for_timeout(400)
    ok("Kopyalandı" in pg.inner_text("#stu"), "kopyala duymesi teqdiq verir")
    ok(pg.evaluate("navigator.clipboard.readText()") == first_code,
       "kod lovheye kopyalanir")

    print("E · Paket limiti panel içində")
    for nm in ["Sagird 3", "Sagird 4", "Sagird 5"]:
        pg.fill("#sname", nm)
        pg.click("#btnStu"); pg.wait_for_timeout(700)
    ok(pg.locator(".stu").count() == 5, "5 sagird elave olundu",
       pg.locator(".stu").count())

    pg.fill("#sname", "Altinci Sagird")
    pg.click("#btnStu"); pg.wait_for_timeout(900)
    err = pg.inner_text("#sErr")
    ok("limit" in err.lower() or "dolub" in err.lower(),
       "6-ci sagirdde limit mesaji cixir", err.strip()[:70])
    ok(pg.locator(".stu").count() == 5, "limit asilmadi - hele de 5 sagird")
    ok(pg.is_visible("#btnStu"), "xetadan sonra panel cokmur")

    pg.click("#btnBack"); pg.wait_for_selector(".seat", timeout=8000)
    ok("5 / 5" in pg.inner_text(".seat"), "yer gostericisi 5 / 5 gosterir",
       pg.inner_text(".seat").replace("\n", " "))
    ok("dolub" in pg.inner_text("#main").lower(), "limit xeberdarligi gorunur")

    print("F · Kodu yeniləmək")
    pg.click("#groups .item"); pg.wait_for_selector(".stu", timeout=8000)
    pg.on("dialog", lambda d: d.accept())
    # Kod yenilemek siyahida yox, qelemin altindadir (nadir + geri donusu yox)
    ok(pg.locator(".stu [data-reset]").count() == 0,
       "kod yenileme siyahini doldurmur")
    pg.locator("[data-edit]").first.click()
    pg.wait_for_selector(".edit [data-reset]", timeout=8000)
    ok(True, "kod yenileme redakte panelindedir")
    pg.locator(".edit [data-reset]").first.click(); pg.wait_for_timeout(1000)
    new_code = re.search(r"\b([A-Z2-9]{8})\b", pg.inner_text(".stu"))
    ok(new_code and new_code.group(1) != first_code, "kod deyisdi",
       (first_code or "?") + " -> " + (new_code.group(1) if new_code else "?"))

    print("F2 · Telefonda şagird sətri")
    pg.set_viewport_size({"width": 360, "height": 780})
    pg.click("#groups .item") if pg.locator("#groups .item").count() else None
    pg.wait_for_selector(".stu", timeout=8000)
    h = pg.locator(".stu").first.evaluate("e => e.getBoundingClientRect().height")
    ok(h <= 120, "sagird setri telefonda yigcamdir", str(round(h)) + "px")
    ok(pg.evaluate("document.documentElement.scrollWidth <= window.innerWidth + 1"),
       "telefonda yana surusme yoxdur")
    pg.set_viewport_size({"width": 430, "height": 900})

    print("G · Çıxış və yenidən giriş")
    pg.click("#btnOut"); pg.wait_for_selector("#btnAuth", timeout=8000)
    ok(True, "cixis isleyir")
    pg.fill("#email", "leyla@test.az"); pg.fill("#pass", "parol1234")
    pg.click("#btnAuth")
    pg.wait_for_selector(".seat", timeout=8000)
    ok("5 / 5" in pg.inner_text(".seat"), "yenidən girişdə melumat yerindedir")

    pg.reload(); pg.wait_for_selector("#groups .item", timeout=8000)
    ok("Cume qrupu" in pg.inner_text("#groups"), "sessiya sehife yenilenmesinden sonra qalir",
       pg.inner_text("#groups").replace("\n", " ")[:50])

    print("H · Ad dəyişmək")
    pg.click("#groups .item"); pg.wait_for_selector("#btnRen", timeout=8000)
    pg.click("#btnRen"); pg.wait_for_selector("#gNew", timeout=8000)
    ok(pg.input_value("#gNew") == "Cume qrupu", "hazirki ad forma dolur",
       pg.input_value("#gNew"))
    pg.fill("#gNew", "   "); pg.click("#gSave"); pg.wait_for_timeout(400)
    ok("boş ola bilməz" in pg.inner_text("#gRenErr"), "bos ad qebul edilmir")
    ok(pg.locator("#gLev").count() == 1, "ad formasinda sinif secimi de var")
    ok(pg.input_value("#gLev") == "3", "hazirki sinif secili gelir",
       pg.input_value("#gLev"))
    pg.fill("#gNew", "Bazar ertəsi qrupu")
    pg.select_option("#gLev", "4")
    pg.click("#gSave"); pg.wait_for_timeout(900)
    ok(pg.locator("#gRen").count() == 0, "yadda saxlayandan sonra forma baglanir")
    ok("Bazar ertəsi qrupu" in pg.inner_text("#gName"), "yeni ad ekranda",
       pg.inner_text("#gName"))
    ok("Bazar ertəsi qrupu" in pg.inner_text("#topTitle"), "ustlukde de yenilenir")
    ok("4-cü sinif" in pg.inner_text("#gMeta"), "sinif derhal yenilenir",
       pg.inner_text("#gMeta").replace("\n", " "))
    pg.reload(); pg.wait_for_selector("#gName", timeout=10000)
    ok("Bazar ertəsi qrupu" in pg.inner_text("#gName"), "ad bazada saxlanildi")
    ok("4-cü sinif" in pg.inner_text("#gMeta"), "sinif de bazada saxlanildi")

    # Sagirdin adi
    pg.locator("[data-edit]").first.click(); pg.wait_for_selector(".edit", timeout=8000)
    ok(pg.locator(".eName").first.input_value() == "Aysu Məmmədova",
       "sagirdin hazirki adi forma dolur")
    ok(pg.locator(".eNick").count() == 0, "redaktede de leqeb sahesi yoxdur")
    pg.locator(".eName").first.fill("Aysel Məmmədova")
    pg.locator(".eSave").first.click(); pg.wait_for_timeout(1000)
    t = pg.inner_text("#stu")
    ok("Aysel Məmmədova" in t, "sagirdin adi deyisdi")
    ok("Aysu Məmmədova" not in t, "kohne ad qalmadi")
    # Qisa forma da OZU yenilenmelidir - lovhede o gorunur
    nick = db_nick("Aysel Məmmədova")
    ok(nick == "Aysel M.", "qisa forma avtomatik yenilendi", nick)

    print("I · Hesabat və marşrut")
    pg.click("#btnRep"); pg.wait_for_selector(".stats", timeout=8000)
    ok("#/r/" in pg.url, "hesabat unvanda gorunur", pg.url.split("#")[-1])
    ok(pg.is_visible("#btnRef"), "'Yenile' duymesi var")
    ok("Son yenilənmə" in pg.inner_text("#main"), "son yenilenme vaxti yazilir")
    ok("5 / 5" in pg.inner_text(".stats") or "0 / 5" in pg.inner_text(".stats"),
       "xulase kartlari dolur", pg.inner_text(".stats").replace("\n", " ")[:40])
    # Menimseme zolagi GORUNUR olmalidir: "ok" sinfi base.css-in mesaj
    # qutusu ile toqqusub zolagi gizledirdi (ucuncu bele toqqusma) -
    # meter artiq m-ok/m-mid/m-low isledir, kohne adlar qayitmasin
    ok(pg.evaluate(
        "!document.querySelector('.meter.ok') && !document.querySelector('.meter.mid')"
        " && !document.querySelector('.meter.low')"),
       "meter koehne toqqusan sinifleri islemir")

    # Sehife yenilenende muellim yerini itirmemelidir
    url = pg.url
    pg.reload(); pg.wait_for_selector(".stats", timeout=10000)
    ok(pg.url == url, "sehife yenilendikde HESABATDA qalir", pg.url.split("#")[-1])
    ok("Son yenilənmə" in pg.inner_text("#main"), "hesabat yeniden yuklendi")

    # "Yenile" sehifeni yeniden yuklemeden melumati getirir
    pg.click("#btnRef"); pg.wait_for_timeout(900)
    ok(pg.url == url, "'Yenile' unvani deyismir")
    ok(pg.is_visible(".stats"), "'Yenile'-den sonra hesabat yerindedir")

    # Sagird hesabatina kecid ve geri
    pg.locator("[data-s]").first.click(); pg.wait_for_selector(".stats", timeout=8000)
    ok("#/s/" in pg.url, "sagird hesabati unvanda", pg.url.split("#")[-1])
    pg.go_back(); pg.wait_for_selector("#btnRef", timeout=8000)
    ok("#/r/" in pg.url, "brauzerin 'geri' duymesi isleyir", pg.url.split("#")[-1])
    pg.click("#btnB"); pg.wait_for_selector("#btnStu", timeout=8000)
    pg.click("#btnBack"); pg.wait_for_selector("#btnGroup", timeout=8000)

    print("I2 · Şagirdi dayandırmaq — yer azad olur")
    #  Yer limiti "is_active"e baxir, amma panelde sagirdi deaktiv
    #  etmek yolu YOX idi: yer bir defe tutulurdu ve geri qayitmirdi.
    #  Kecen ilin sagirdi bu ilin yerini yeyirdi.
    pg.goto(PANEL + "#/"); pg.reload()
    pg.wait_for_selector("#groups .item", timeout=8000)
    used0 = pg.inner_text(".seat .num").split("/")[0].strip()
    pg.locator("#groups .item").first.click()
    pg.wait_for_selector(".stu", timeout=8000)
    n0 = pg.locator(".stu").count()
    #  «Dayandır» setirde deyil, qelemin altindadir (nadir emeliyyat)
    ok(pg.locator("[data-arch]").count() == 0, "setirde «Dayandır» yoxdur (redakte panelindedir)")
    ok(pg.locator("details.arxiv").count() == 0, "dayandirilmis bolmesi hele yoxdur")

    ad = pg.locator(".stu b").first.inner_text()
    pg.locator(".stu [data-edit]").first.click(); pg.wait_for_selector(".stu .edit [data-arch]", timeout=8000)
    ok(pg.locator("[data-arch]").count() == 1, "redakte panelinde «Dayandır» var")
    pg.locator("[data-arch]").first.click()
    pg.wait_for_selector("details.arxiv", timeout=8000)
    ok(pg.locator("details.arxiv").count() == 1, "dayandirilmis bolmesi cixir")
    ok(pg.locator(".stu.off").count() == 1, "sagird dayandirilmis gorunusune kecir",
       pg.locator(".stu.off").count())
    #  DIQQET: bolme YIGILMIS gelir - inner_text bagli <details>-in
    #  icini QAYTARMIR.  Acib oxuyuruq (istifadeci de bele edir).
    pg.locator("details.arxiv summary").click()
    pg.wait_for_selector("details.arxiv[open]", timeout=8000)
    ok(ad in pg.inner_text("details.arxiv"), "bolmede DUZ sagird var", ad)
    ok("Dayandırılıb" in pg.inner_text(".stu.off"), "sebeb yazilir",
       pg.inner_text(".stu.off").replace("\n", " ")[:70])
    #  arxivdeki setirde kod/gonder duymeleri OLMAMALIDIR - kod onsuz
    #  da islemir, gostermek aldadici olardi
    ok(pg.locator(".stu.off [data-wa]").count() == 0,
       "dayandirilmisda «Göndər» duymesi yoxdur")
    ok(pg.locator(".stu.off .code").count() == 0, "dayandirilmisda giris kodu gosterilmir")
    ok(pg.locator(".stu.off [data-rep]").count() == 1,
       "«Hesabat» qalir - kecmis neticeler itmeyib")

    row = db("select is_active from public.students where full_name = %s",
             (ad,), one=True)
    ok(row is not None and row["is_active"] is False, "bazada dayandirilib",
       row and row["is_active"])

    #  yer sayğaci ASAGI dusmelidir - kes tezelenmelidir
    pg.goto(PANEL + "#/"); pg.reload()
    pg.wait_for_selector(".seat .num", timeout=8000)
    used1 = pg.inner_text(".seat .num").split("/")[0].strip()
    ok(int(used1) == int(used0) - 1, "yer sayğaci azalir",
       "%s -> %s" % (used0, used1))
    #  qrup setrindeki sagird sayi da azalmalidir
    pg.wait_for_function(
        "!/Yüklənir/.test(document.getElementById('groups').textContent)",
        timeout=8000)
    ok("%d şagird" % (n0 - 1) in pg.inner_text("#groups"),
       "qrup setrinde de dayandirilmis sayilmir",
       pg.inner_text("#groups").replace("\n", " ")[:70])

    print("I3 · Davam etdirmək")
    pg.locator("#groups .item").first.click()
    pg.wait_for_selector("details.arxiv", timeout=8000)
    if pg.locator("details.arxiv:not([open])").count():
        pg.locator("details.arxiv summary").click()
    pg.locator("[data-unarch]").first.click()
    pg.wait_for_function(
        "n => document.querySelectorAll('.stu:not(.off)').length === n",
        arg=n0, timeout=8000)
    ok(pg.locator(".stu.off").count() == 0, "dayandirilmis siyahisi bosaldi")
    ok(pg.locator("details.arxiv").count() == 0, "bolme itir")
    row = db("select is_active from public.students where full_name = %s",
             (ad,), one=True)
    ok(row is not None and row["is_active"] is True, "bazada davam etdirilib",
       row and row["is_active"])

    print("J · Başqa müəllim heç nə görmür")
    pg2 = new_page(ctx)
    pg2.goto(PANEL)
    pg2.evaluate("localStorage.clear()")
    signup(pg2, "ozge@test.az", "Ozge Muellim")
    pg2.wait_for_selector("#btnSetup", timeout=8000)
    pg2.select_option("#atype", "school")
    pg2.fill("#aname", "Ozge - 4B sinfi")
    pg2.click("#btnSetup")
    pg2.wait_for_selector("#btnGroup", timeout=8000)
    ok("0 / 5" in pg2.inner_text(".seat"), "yeni muellimde 0 sagird")
    pg2.wait_for_function(
        "!/Yüklənir/.test(document.getElementById('groups').textContent)", timeout=8000)
    ok("qrup yoxdur" in pg2.inner_text("#groups"), "yeni muellim basqasinin qrupunu gormur",
       pg2.inner_text("#groups").replace("\n", " ")[:60])

    print("K · Yanlış parol")
    pg3 = new_page(ctx)
    pg3.goto(PANEL); pg3.evaluate("localStorage.clear()"); pg3.reload()
    pg3.wait_for_selector("#btnAuth", timeout=8000)
    pg3.fill("#email", "leyla@test.az"); pg3.fill("#pass", "sehvparol")
    pg3.click("#btnAuth"); pg3.wait_for_timeout(800)
    ok(pg3.is_visible("#authErr") and pg3.inner_text("#authErr").strip() != "",
       "yanlis parolda anlasilan xeta", pg3.inner_text("#authErr").strip()[:50])
    ok(pg3.is_visible("#btnAuth"), "xetadan sonra ekran qalir")

    ctx.close()
    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails))
    for f in fails: print("  - " + f)
    sys.exit(1)
print("PANEL: BUTUN YOXLAMALAR KECDI")
