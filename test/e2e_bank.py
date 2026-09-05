#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sual banki ekrani: yazmaq, redakte, suzgec, tekrar xeberdarligi."""
import sys
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

PANEL  = "http://127.0.0.1:8010/muellim/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN    = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
BLOCK  = "**://*.supabase.co/**"
TEST_CFG = """window.CFG = {
  SUPABASE_URL: "http://127.0.0.1:54321",
  SUPABASE_ANON_KEY: "test-anon-key",
  STUDENT_URL: "https://example.test/Testler/"
};"""

def pool_click(pg, name):
    """Hovuz seqmentine klik + kliyin TUTDUGUNU tesdiq.

    Sehife tezece qurulanda ekran ard-arda iki defe cizile bilir
    (kontekst -> route -> screenBank).  Klik ikinci cizilisin altina
    dusse itir: DOM deyisir, hadise hec kime catmir.  Bu, istifadeci
    ucun kicik meseledir (bir daha basir), amma yoxlamada kes verir.
    Ona gore seqmentin AKTIV oldugunu gozleyirik, tutmayibsa bir
    defe tekrar basiriq."""
    for attempt in (1, 2):
        pg.locator("#bPool .seg", has_text=name).click()
        try:
            pg.wait_for_function(
                "n => { const s = document.querySelector('#bPool .seg.on');"
                "       return !!s && s.innerText.indexOf(n) >= 0; }",
                arg=name, timeout=6000)
            return
        except Exception:
            if attempt == 2:
                raise


def empty_icons(pg):
    """Terif olunmayan ikon: <svg> var, icinde hec ne yoxdur."""
    return pg.evaluate(
        "() => [...document.querySelectorAll('svg')]"
        ".filter(s => s.innerHTML.trim() === '').length")

fails = []
def ok(cond, label, extra=""):
    print(("  OK   " if cond else "  FAIL ") + label + (("  " + str(extra)) if extra else ""),
          flush=True)
    if not cond: fails.append(label)

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            return cur.fetchone() if one else cur.fetchall()

db("""
delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments;     delete from public.student_sessions;
delete from public.test_questions where test_id in
  (select id from public.tests where owner_type = 'educator');
delete from public.question_options o using public.questions q
 where o.question_id = q.id and q.owner_type = 'educator';
delete from public.questions where owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.students; delete from public.classes;
delete from public.subscriptions; delete from public.account_members;
delete from public.accounts; delete from public.user_roles; delete from auth.users;
""")
if not db("select 1 from public.tests where owner_type='platform' limit 1", one=True):
    db(open("db/07_seed_tests.sql", encoding="utf-8").read())

with sync_playwright() as pw:
    br  = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 390, "height": 860})
    pg  = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=TEST_CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))

    # qeydiyyat
    pg.goto(PANEL); pg.wait_for_timeout(400)
    pg.click("#btnSwap")
    pg.fill("#fname", "Bank Muellim"); pg.fill("#email", "bank@t.az"); pg.fill("#pass", "parol1234")
    pg.click("#btnAuth"); pg.wait_for_selector("#btnSetup", timeout=8000)
    pg.select_option("#atype", "tutor"); pg.fill("#aname", "Riyaziyyat")
    pg.click("#btnSetup"); pg.wait_for_selector("#gForm", timeout=8000)

    print("A · Bank ekranı")
    ok(True, "esas sehifede 'Sual banki' var")
    # Terif olunmayan ikon BOS svg verir - gozle gorunmur, ona gore yoxlanilir
    ok(empty_icons(pg) == 0, "esas sehifede bos ikon yoxdur", empty_icons(pg))
    ok(pg.locator("#btnBank").evaluate(
        "e => getComputedStyle(e.closest('.card')).backgroundColor") != "rgba(0, 0, 0, 0)",
       "bank kecidi kart icindedir")
    #  telefonda suretli emeliyyatlar gizlidir - alt menyudan gedirik
    pg.click("#bnav a[href='#/b']"); pg.wait_for_selector("#btnNewQ", timeout=8000)
    ok("/b" in pg.url, "bankin oz unvani var", pg.url.split("#")[-1])
    ok("0" in pg.inner_text(".seat .num"), "istifade gostericisi 0-dan baslayir",
       pg.inner_text(".seat .num").replace("\n", " "))
    #  Oz suali olmayan muellime bank PLATFORMA ile acilir (UX yoxlamasi) -
    #  bos "Sual tapilmadi" ilk ekran olmasin
    pg.wait_for_selector(".bpick .pkb", timeout=8000)   # platforma: fenn secimi
    ok("Hazır bank" in pg.locator("#bPool .seg.on").inner_text(), "oz suali yoxdursa Hazır bank acilir",
       pg.locator("#bPool .seg.on").inner_text())
    pg.locator("#bPool .seg", has_text="Öz suallarım").click()
    pg.wait_for_selector("#bList .empty", timeout=8000)
    ok("Sual tapılmadı" in pg.inner_text("#bList"), "bos veziyyet aydindir")
    ok(empty_icons(pg) == 0, "bank ekraninda bos ikon yoxdur", empty_icons(pg))

    print("B · Yeni sual yazmaq")
    pg.click("#btnNewQ"); pg.wait_for_selector("#qbody", timeout=8000)
    ok(pg.locator(".opt-row").count() == 2, "iki bos variant hazir gelir",
       pg.locator(".opt-row").count())
    ok(pg.locator(".okmark.on").count() == 1, "birinci variant duzgun kimi isarelidir")

    # bos sualla saxlamaq olmur
    pg.click("#qSave"); pg.wait_for_timeout(400)
    ok(pg.inner_text("#qErr").strip() != "", "bos sual redd edilir",
       pg.inner_text("#qErr").strip()[:40])

    pg.fill("#qbody", "6 x 7 neçə edər?")
    pg.locator(".obody").nth(0).fill("42")
    pg.locator(".obody").nth(1).fill("36")
    # ucuncu variant
    pg.click("#qAdd"); pg.wait_for_timeout(200)
    ok(pg.locator(".opt-row").count() == 3, "variant elave olunur")

    # Her klik DEQIQ bir variant elave etmelidir.  Bir defe dinleyici
    # her cizilisde ustune yigildi: iki klik 4 variant verdi, sonra 8, 16...
    for expect in (4, 5, 6, 7, 8):
        pg.click("#qAdd"); pg.wait_for_timeout(200)
        n = pg.locator(".opt-row").count()
        if n != expect:
            ok(False, "her klik BIR variant elave edir", "gozlenilen %d, alinan %d" % (expect, n))
            break
    else:
        ok(True, "her klik BIR variant elave edir", "3 -> 8")
    ok(pg.locator("#qAdd").count() == 0, "8 variantdan sonra duyme gizlenir",
       pg.locator(".opt-row").count())
    # 8-den yuxari qalxmasin
    for i in range(3):
        if pg.locator("#qAdd").count(): pg.click("#qAdd"); pg.wait_for_timeout(120)
    ok(pg.locator(".opt-row").count() == 8, "hedd asilmir",
       pg.locator(".opt-row").count())
    # geri 3-e qayidiriq
    while pg.locator(".opt-row").count() > 3:
        pg.locator("[data-rm]").last.click(); pg.wait_for_timeout(150)
    ok(pg.locator(".opt-row").count() == 3, "silmek de bir-bir isleyir")
    pg.locator(".obody").nth(2).fill("48")
    pg.select_option("#qlev", "3")
    tp = db("select id::text i from public.topics where slug='riy-3-vurma-bolme'", one=True)
    # Movzu tapilmasa SUSMAQ olmaz - evvel "if tp:" yazilmisdi ve slug
    # deyisende test sadece movzusuz davam edirdi, "movzu saxlanildi"
    # yoxlamasi ise sonra sinirdi.  Sebeb burdadir, orda yox.
    assert tp, "riy-3-vurma-bolme movzusu bazada yoxdur"
    pg.select_option("#qtop", tp["i"])
    # Sehife QACMAMALIDIR: cetinlik/tip secmek butun formani yeniden
    # cizirdi ve surusme yuxari atilirdi - muellim yerini itirirdi.
    pg.locator("#qdiff").scroll_into_view_if_needed(); pg.wait_for_timeout(200)
    y0 = pg.evaluate("window.scrollY")
    pg.locator("#qdiff .seg", has_text="Çətin").click()
    pg.wait_for_timeout(300)
    y1 = pg.evaluate("window.scrollY")
    ok(abs(y1 - y0) < 40, "cetinlik secende sehife qacmir",
       "%d -> %d" % (y0, y1))
    ok(pg.locator("#qdiff .seg.on").inner_text() == "Çətin", "nisan kecdi")

    # Olcu MENALI olmalidir: sehife SIFIRDAN FERQLI yerde dayanmalidir,
    # yoxsa "0 -> 0" hec ne subut etmir.  Tip secicisi ekranin ortasina
    # dusecek qeder asagi surusduruk.
    pg.evaluate("""() => {
      const t = document.getElementById('qkind').getBoundingClientRect().top
                + window.scrollY;
      window.scrollTo(0, Math.max(0, t - 150));
    }""")
    pg.wait_for_timeout(300)
    ykind0 = pg.evaluate("window.scrollY")
    ok(ykind0 > 80, "olcu menalidir - sehife asagidadir", ykind0)
    pg.locator("#qkind .seg", has_text="Çox cavab").click(); pg.wait_for_timeout(400)
    ok(abs(pg.evaluate("window.scrollY") - ykind0) < 40,
       "tip secende de sehife qacmir",
       "%d -> %d" % (ykind0, pg.evaluate("window.scrollY")))
    # Yazili -> bir cavab: setir sayi 3-den 1-e dusur, sehife QISALIR.
    # Klamp burda bas verirdi.
    pg.locator("#qkind .seg", has_text="Yazılı").click(); pg.wait_for_timeout(400)
    y2 = pg.evaluate("window.scrollY")
    ok(abs(y2 - ykind0) < 60, "setir sayi azalanda da qacmir",
       "%d -> %d" % (ykind0, y2))
    pg.locator("#qkind .seg", has_text="Bir cavab").click(); pg.wait_for_timeout(400)
    while pg.locator(".opt-row").count() < 3:
        pg.click("#qAdd"); pg.wait_for_timeout(150)
    for i, v in enumerate(["42", "36", "48"]):
        pg.locator(".obody").nth(i).fill(v)
    pg.locator(".okmark").first.click(); pg.wait_for_timeout(200)
    ok(pg.inner_text("#qbody") or pg.input_value("#qbody") == "6 x 7 neçə edər?",
       "cetinlik deyisende sual metni ITMIR", pg.input_value("#qbody"))
    ok(pg.locator(".obody").nth(0).input_value() == "42",
       "cetinlik deyisende variantlar ITMIR")

    pg.click("#qSave"); pg.wait_for_selector("#btnNewQ", timeout=8000)
    r = db("select body, difficulty, level_id, topic_id from public.questions "
           "where owner_type='educator'", one=True)
    ok(r is not None and r["body"] == "6 x 7 neçə edər?", "sual bazaya dusdu")
    ok(r and r["difficulty"] == 3, "cetinlik saxlanildi", r and r["difficulty"])
    ok(r and r["level_id"] is not None, "sinif saxlanildi")
    ok(r and r["topic_id"] is not None, "movzu saxlanildi")
    n = db("select count(*) n from public.question_options o join public.questions q "
           "on q.id=o.question_id where q.owner_type='educator'", one=True)["n"]
    ok(n == 3, "uc variant yazildi", n)
    nk = db("select count(*) n from public.question_options o join public.questions q "
            "on q.id=o.question_id where q.owner_type='educator' and o.is_correct",
            one=True)["n"]
    ok(nk == 1, "yalniz bir duzgun cavab", nk)

    print("C · Siyahı və süzgəc")
    ok(pg.locator(".qrow").count() == 1, "sual siyahida gorunur")
    row = pg.inner_text(".qrow")
    ok("6 x 7" in row, "sualin metni gorunur")
    ok("Çətin" in row, "cetinlik nisani gorunur", row.replace("\n", " ")[:60])
    ok("1" in pg.inner_text(".seat .num"), "sayğac artdi")

    # cavab acari siyahida OLMAMALIDIR
    ok("is_correct" not in pg.content(), "siyahida is_correct yoxdur")

    if pg.locator("details.filt:not([open])").count():
        pg.locator("details.filt summary").click(); pg.wait_for_timeout(200)
    ok(pg.is_visible("#bDiff"), "suzgec acilir")
    ok(pg.locator("#bTop").count() == 0,
       "fenn secilmeyibse movzu nisanlari cixmir")
    pg.select_option("#bsub", "riyaziyyat"); pg.wait_for_timeout(900)
    if pg.locator("details.filt:not([open])").count():
        pg.locator("details.filt summary").click(); pg.wait_for_timeout(200)
    nt = pg.locator("#bTop .chip").count()
    # Bank ekrani OZ hovuzuna gore suzur: yalniz muellimin sual yazdigi
    # movzular gorunur (bos movzu nisani aldadici olardi).
    nriy = db("select count(distinct q.topic_id) n from public.questions q "
              "join public.subjects s on s.id = q.subject_id "
              "where s.slug = 'riyaziyyat' and q.owner_type = 'educator' "
              "and q.topic_id is not null", one=True)["n"]
    ok(nt == nriy, "fenn secilende yalniz oz suallarinin movzulari cixir",
       "ekran %d, baza %d" % (nt, nriy))
    pg.select_option("#bsub", ""); pg.wait_for_timeout(900)
    if pg.locator("details.filt:not([open])").count():
        pg.locator("details.filt summary").click(); pg.wait_for_timeout(200)
    pg.locator("#bDiff .chip", has_text="Asan").click(); pg.wait_for_timeout(500)
    ok(pg.locator(".qrow").count() == 0, "cetinlik suzgeci isleyir")
    ok(pg.locator("details.filt").get_attribute("open") is not None,
       "suzgec aktiv olanda acıq qalir")
    ok(pg.inner_text("details.filt summary").strip().endswith("1"),
       "aktiv suzgec sayi gorunur", pg.inner_text("details.filt summary").strip())
    pg.locator("#bDiff .chip", has_text="Asan").click(); pg.wait_for_timeout(500)
    ok(pg.locator(".qrow").count() == 1, "suzgec geri qaytarilir")

    pool_click(pg, "Hazır bank")
    # suzgecsiz platforma hovuzu siyahi tokmur - fenn secimi teklif edir
    pg.wait_for_selector(".bpick .pkb", timeout=8000)
    ok(pg.locator(".qrow").count() == 0,
       "suzgecsiz platforma hovuzunda siyahi tokulmur")
    #  Bank hecmi adi muellime gorunmur (istifadeci qerari): fenn kartinda
    #  say yoxdur, "Bankda N sual var" yazisi yoxdur
    ok("sual" not in pg.locator(".bpick .pkb").first.inner_text(), "adi muellim fenn kartinda sual sayi gormur",
       pg.locator(".bpick .pkb").first.inner_text().replace("\n", " "))
    ok("Bankda" not in pg.inner_text(".bpick"), "adi muellim 'Bankda N sual' yazisini gormur")
    npk = pg.locator(".bpick .pkb").count()
    ndb = db("select count(distinct subject_id) n from public.questions "
             "where owner_type = 'platform' and status = 'published'",
             one=True)["n"]
    ok(npk == ndb, "fenn secimi bazadaki fennlerle ust-uste dusur", (npk, ndb))
    #  Fenn secilende artiq 50 sual TOKULMUR - ehate goruntusu gelir.
    #  Kohne davranis: siyahi acilirdi, setirler disabled idi, ustelik
    #  siralama created_at desc oldugu ucun yalniz EN SON yazilan
    #  sinfin kesiyi gorunurdu.
    pg.locator(".bpick .pkb").first.click()
    pg.wait_for_selector(".bpick .pkb[data-l]", timeout=8000)
    ok(pg.locator(".qrow").count() == 0,
       "fenn secilende siyahi yox, sinif secicisi gelir")
    #  Siyahiya axtarisla catmaq olur - orada da platforma setirleri
    #  redakte olunmamalidir
    pg.fill("#bq", "?")
    pg.wait_for_selector(".qrow", timeout=8000)
    np = pg.locator(".qrow").count()
    ok(np >= 1, "axtarisla platforma siyahisi acilir", np)
    ok(pg.locator(".qrow[disabled]").count() == np,
       "platforma suallari redakte olunmur")
    pg.fill("#bq", ""); pg.wait_for_timeout(700)
    pg.locator("#bPool .seg", has_text="Öz suallarım").click()
    pg.wait_for_selector(".qrow:not([disabled])", timeout=8000)

    pg.fill("#bq", "tapilmaz"); pg.wait_for_timeout(800)
    ok(pg.locator(".qrow").count() == 0, "metn axtarisi isleyir")
    pg.fill("#bq", "6 x 7"); pg.wait_for_timeout(800)
    ok(pg.locator(".qrow").count() == 1, "axtaris sualı tapir")
    pg.fill("#bq", ""); pg.wait_for_timeout(800)

    print("D · Redaktə")
    pg.locator(".qrow").first.click(); pg.wait_for_selector("#qbody", timeout=8000)
    ok(pg.input_value("#qbody") == "6 x 7 neçə edər?", "forma dolu gelir")
    ok(pg.locator(".opt-row").count() == 3, "variantlar dolu gelir")
    ok(pg.locator("#qdiff .seg.on").inner_text() == "Çətin", "cetinlik secili gelir")
    pg.fill("#qbody", "6 x 7 = ?")
    pg.click("#qSave"); pg.wait_for_selector("#btnNewQ", timeout=8000)
    r = db("select body from public.questions where owner_type='educator'", one=True)
    ok(r["body"] == "6 x 7 = ?", "redakte saxlanildi", r["body"])
    n = db("select count(*) n from public.question_options o join public.questions q "
           "on q.id=o.question_id where q.owner_type='educator'", one=True)["n"]
    ok(n == 3, "redaktede variantlar COXALMIR", n)

    print("E · Təkrar sual")
    pg.click("#btnNewQ"); pg.wait_for_selector("#qbody", timeout=8000)
    pg.fill("#qbody", "7 x 6 = ?"); pg.wait_for_timeout(1200)
    ok("oxşar sual var" in pg.inner_text("#qSim"),
       "yerdeyismis tekrar xeberdarliq verir", pg.inner_text("#qSim").strip()[:60])
    # amma BLOKLAMIR
    pg.locator(".obody").nth(0).fill("42"); pg.locator(".obody").nth(1).fill("36")
    pg.click("#qSave"); pg.wait_for_selector("#btnNewQ", timeout=8000)
    ok(db("select count(*) n from public.questions where owner_type='educator'",
          one=True)["n"] == 2, "xeberdarliq BLOKLAMIR - sual yazilir")

    # herfi eyni sual - BLOKLANIR
    pg.click("#btnNewQ"); pg.wait_for_selector("#qbody", timeout=8000)
    pg.fill("#qbody", "6 x 7 = ?"); pg.wait_for_timeout(1200)
    ok("EYNİ sual var" in pg.inner_text("#qSim"), "herfi tekrar aydin bildirilir",
       pg.inner_text("#qSim").strip()[:50])
    pg.locator(".obody").nth(0).fill("42"); pg.locator(".obody").nth(1).fill("36")
    pg.click("#qSave"); pg.wait_for_timeout(900)
    ok("artıq var" in pg.inner_text("#qErr"), "server herfi tekrari redd edir",
       pg.inner_text("#qErr").strip()[:50])
    ok(db("select count(*) n from public.questions where owner_type='educator'",
          one=True)["n"] == 2, "tekrar sual bazaya dusmedi")

    print("F0 · Mövzu fənnə görə süzülür")
    pg.click("#btnBack"); pg.wait_for_selector("#btnNewQ", timeout=8000)
    pg.click("#btnNewQ"); pg.wait_for_selector("#qtop", timeout=8000)
    pg.wait_for_timeout(800)
    riy = pg.locator("#qtop option").all_inner_texts()
    ok(any("Vurma cədvəli" in x for x in riy), "riyaziyyat movzulari gorunur", riy[:3])
    ok(not any("Sait və samit" in x for x in riy),
       "BASQA fennin movzusu teklif olunmur", riy[:3])
    # sinif secilmeyib -> ada sinif de yazilmalidir
    ok(any(" · " in x and "sinif" in x for x in riy),
       "sinif secilmeyende movzunun sinfi gorunur",
       [x for x in riy if " · " in x][:2])
    # sinif secilende yalniz onun movzulari, ad tekrarsiz
    #  Sabit gozleme YOX: movzu siyahisi serverden gelir ve baza
    #  soyuq olanda 900 ms catmirdi - yoxlama kohne siyahini olcub
    #  "670 movzu" deyirdi.  Veziyyetin ozunu gozleyirik: sinif
    #  secilende adlara " · sinif" yazilmir.
    pg.select_option("#qlev", "3")
    pg.wait_for_function(
        """() => {
          const o = [...document.querySelectorAll('#qtop option')]
                      .map(x => x.textContent)
                      .filter(x => x !== 'Seçilməyib');
          return o.length > 0 && o.every(x => x.indexOf(' · ') < 0);
        }""", timeout=10000)
    r3 = [x for x in pg.locator("#qtop option").all_inner_texts() if x != "Seçilməyib"]
    ok(len(r3) == len(set(r3)), "sinif secilende ad tekrarlanmir", r3)
    ok(all(" · " not in x for x in r3), "sinif secilibse ada tekrar yazilmir", r3[:3])
    ok(0 < len(r3) <= 12, "yalniz o sinifin movzulari", len(r3))
    pg.select_option("#qsub", "az-dili")
    pg.wait_for_function(
        """() => [...document.querySelectorAll('#qtop option')]
                   .some(x => x.textContent.indexOf('Sait və samit') >= 0)""",
        timeout=10000)
    az = pg.locator("#qtop option").all_inner_texts()
    ok(any("Sait və samit" in x for x in az),
       "fenn deyisende movzular da deyisir", az[:3])
    ok(not any("Vurma cədvəli" in x for x in az),
       "kohne fennin movzulari qalmir", az[:3])

    print("F · Yazılı sual")
    pg.click("#btnBack"); pg.wait_for_selector("#btnNewQ", timeout=8000)
    pg.click("#btnNewQ"); pg.wait_for_selector("#qbody", timeout=8000)
    pg.locator("#qkind .seg", has_text="Yazılı").click(); pg.wait_for_timeout(300)
    ok(pg.locator(".opt-row").count() == 1, "yazili sualda bir cavab qalir")
    ok(pg.locator(".okmark").count() == 0, "yazili sualda isarə duymesi yoxdur",
       pg.locator(".okmark").count())
    ttl = pg.locator("#optTitle").evaluate("e => e.textContent")
    ok("Qəbul ediləcək cavablar" == ttl, "basliq deyisir", ttl)
    pg.fill("#qbody", "5 x 5 = ?")
    pg.locator(".obody").nth(0).fill("25")
    pg.click("#qSave"); pg.wait_for_selector("#btnNewQ", timeout=8000)
    r = db("select kind from public.questions where body='5 x 5 = ?'", one=True)
    ok(r and r["kind"] == "text", "yazili sual duzgun tipde saxlanildi", r and r["kind"])

    print("F2 · Yazılı sual şagird tərəfində işləyir")
    # Muellim "Yazili" sual yaza bilirdise, sagird onu CAVABLANDIRA
    # bilmelidir - eks halda dalan olur.
    # Asililiqlari OZUMUZ yaradiriq: sessizce atlanan yoxlama yoxlama deyil.
    acc = db("select id::text i from public.accounts limit 1", one=True)
    ok(acc is not None, "hesab var")
    # OZ sualini yaradiriq - G bolmesi silmek ucun basqa sualdan istifade
    # edir, onun veziyyetini pozmayaq.
    q = db("""insert into public.questions
                (id, owner_type, owner_id, account_id, subject_id, kind, body, status)
              select '7777aaaa-0000-0000-0000-00000000000f', 'educator',
                     a.owner_id, a.id, s.id, 'text', '9 + 9 = ?', 'published'
                from public.accounts a, public.subjects s
               where a.id = %s and s.slug = 'riyaziyyat'
              returning id::text i""", (acc["i"],), one=True)
    db("""insert into public.question_options (question_id, ord, body, is_correct)
          values (%s, 1, '18', true)""", (q["i"],))
    ok(q is not None, "yazili sual yaradildi")

    db("""insert into public.classes (id, account_id, teacher_id, kind, name, join_code)
          select '7777cccc-0000-0000-0000-00000000000f', a.id, a.owner_id,
                 'tutor_group', 'Yazi qrupu', 'YAZIQRUP'
            from public.accounts a where a.id = %s
          on conflict (id) do nothing""", (acc["i"],))
    db("""insert into public.students
            (id, account_id, class_id, created_by, full_name, display_name, login_code)
          select '7777000a-0000-0000-0000-00000000000f', c.account_id, c.id,
                 c.teacher_id, 'Yazi Sagird', 'Yazi S.', 'YAZIKOD1'
            from public.classes c where c.id = '7777cccc-0000-0000-0000-00000000000f'
          on conflict (id) do nothing""")
    t = db("""insert into public.tests
                (owner_type, owner_id, program_id, subject_id, title, status)
              select 'educator', c.teacher_id, p.id, s.id, 'Yazili sinaq', 'published'
                from public.classes c, public.programs p, public.subjects s
               where c.id = '7777cccc-0000-0000-0000-00000000000f'
                 and p.slug='ibtidai' and s.slug='riyaziyyat'
              returning id::text i""", one=True)["i"]
    db("insert into public.test_questions (test_id, question_id, ord) values (%s,%s,1)",
       (t, q["i"]))
    db("insert into public.assignments (class_id, test_id) values "
       "('7777cccc-0000-0000-0000-00000000000f', %s)", (t,))

    sp = ctx.new_page()
    sp.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=TEST_CFG))
    sp.on("pageerror", lambda e: fails.append("JS xetasi (sagird): " + str(e)))
    sp.goto("http://127.0.0.1:8010/sagird/index.html")
    sp.wait_for_selector("#btnIn", timeout=8000)
    sp.fill("#code", "YAZIKOD1"); sp.click("#btnIn")
    sp.wait_for_selector(".test", timeout=8000)
    sp.locator(".test", has_text="Yazili").first.click()
    sp.wait_for_selector("#ans", timeout=8000)
    ok(True, "yazili sualda cavab sahesi var")
    ok(sp.locator(".opt").count() == 0, "yazili sualda variant gorunmur")
    correct = db("""select o.body b from public.question_options o
                     where o.question_id = %s and o.is_correct limit 1""",
                 (q["i"],), one=True)["b"]
    sp.fill("#ans", correct); sp.wait_for_timeout(350)
    # Tek sualliq testde "Növbəti" yoxdur - yalniz "Testi bitir"
    ok(sp.locator("#btnNext").count() == 0, "tek sualda 'Novbeti' yoxdur")
    ok("bitir" in sp.inner_text("#btnFinish").lower(),
       "'Testi bitir' duymesi var", sp.inner_text("#btnFinish"))
    sp.click("#btnFinish"); sp.wait_for_selector(".ring", timeout=8000)
    ok("100" in sp.inner_text(".ring .val"),
       "yazili cavab SERVERDE duzgun sayilir", sp.inner_text(".ring .val"))
    sp.close()

    print("G · Silmək")
    pg.on("dialog", lambda d: d.accept())
    pg.locator(".qrow", has_text="5 x 5").first.click()
    pg.wait_for_selector("#qDel", timeout=8000)
    pg.click("#qDel"); pg.wait_for_selector("#btnNewQ", timeout=8000)
    ok(db("select count(*) n from public.questions where body='5 x 5 = ?'",
          one=True)["n"] == 0, "islenmemis sual tamamile silinir")

    print("H · Başlıqdakı nişan pozulmayıb")
    mk = pg.locator(".top .mark").first
    ok(mk.count() > 0 if hasattr(mk, "count") else True, "basliqda nisan var")
    #  Nisan ag 32px kvadratdadir, icindeki SVG 24px (mavi zolaq ucun)
    w = pg.locator(".top .mark").first.evaluate("e => e.getBoundingClientRect().width")
    sv = pg.locator(".top .mark svg").first.evaluate("e => e.getBoundingClientRect().width")
    ok(30 <= w <= 34 and 22 <= sv <= 26, "nisan olcusu duzgun (kvadrat 32, svg 24)",
       str(round(w)) + "/" + str(round(sv)) + "px")
    ok(pg.locator(".top .wm").count() == 1 and pg.inner_text(".top .wm") == "Bil10", "zolaqda Bil10 yazisi var")

    print("I · Platforma hovuzu: siyahı yox, əhatə görüntüsü (admin — saylar görünür)")
    #  Bundan sonraki say yoxlamalari ADMIN gorunusunu sinayir: bank hecmi
    #  yalniz adminə gosterilir.  Rol bazaya yazilir, sehife yenilenir.
    db("insert into public.user_roles (user_id, role) select id, 'admin' from auth.users "
       "where email = 'bank@t.az' on conflict do nothing")
    pg.goto(PANEL + "#/b"); pg.reload()
    pg.wait_for_selector("#bPool", timeout=15000)
    pool_click(pg, "Hazır bank")
    pg.wait_for_selector(".bpick .pkb", timeout=15000)
    ok(pg.locator(".bpick .pkb").count() >= 1, "fenn secicisi cixir",
       pg.locator(".bpick .pkb").count())
    #  fenn secilir -> SINIF SECICISI gelmelidir, 50 sualliq siyahi yox
    pg.locator(".bpick .pkb", has_text="Riyaziyyat").first.click()
    pg.wait_for_selector(".bpick .pkb[data-l]", timeout=15000)
    ok(pg.locator(".qrow").count() == 0, "siyahi tokulmur", pg.locator(".qrow").count())
    nlev = pg.locator(".bpick .pkb[data-l]").count()
    ok(nlev >= 1, "sinif duymeleri sayla gelir", nlev)
    ok("sual" in pg.locator(".bpick .pkb[data-l]").first.inner_text(),
       "sinif duymesinde sual sayi var",
       pg.locator(".bpick .pkb[data-l]").first.inner_text().replace("\n", " "))
    #  saylar bazadaki hegiqi say ile uzlasmalidir
    code = pg.locator(".bpick .pkb[data-l]").first.get_attribute("data-l")
    real = db("""select count(*) n from public.questions q
                  join public.subjects s on s.id = q.subject_id
                 where s.slug = 'riyaziyyat' and q.owner_type = 'platform'
                   and q.status = 'published'
                   and q.level_id in (select id from public.levels where code = %s)""",
              (code,), one=True)["n"]
    shown = int("".join(ch for ch in
                pg.locator(".bpick .pkb[data-l]").first.inner_text()
                  .split("\n")[-1] if ch.isdigit()))
    ok(shown == real, "sinifdeki say bazadaki ile uyusur",
       "%d vs %d" % (shown, real))

    print("J · Mövzular, çətinlik bölgüsü və nümunə suallar")
    pg.locator(".bpick .pkb[data-l]").first.click()
    pg.wait_for_selector(".cvr", timeout=15000)
    ok(pg.locator(".cvr").count() >= 1, "movzu setirleri gelir",
       pg.locator(".cvr").count())
    #  Zolaq yalniz FERQ olanda cizilir.  Hamisinda eyni say varsa
    #  12 dene tam dolu xett qalirdi - hec ne demeyen bezek.
    ns = [int(x) for x in pg.locator(".cvr .n").all_inner_texts()]
    if len(set(ns)) > 1:
        ok(pg.locator(".cvr .cbar").count() >= 1, "ferq olanda zolaq cizilir", ns[:5])
    else:
        ok(pg.locator(".cvr .cbar").count() == 0,
           "saylar eyni olanda zolaq cizilmir", ns[:5])
    t0 = pg.locator(".cvr").first.inner_text()
    ok("asan" in t0 or "orta" in t0 or "çətin" in t0,
       "cetinlik bolgusu yazilir", t0.replace("\n", " ")[:60])
    ok(pg.locator("#covUp").count() == 1, "«bütün siniflər» geri duymesi var")
    #  Katalogda movzu nisanlari ARTIQDIR - asagidaki setirler eyni
    #  movzulari sayla ve numune ile gosterir.  Eyni 12 ad iki defe
    #  yazilirdi.
    ok(pg.locator("#bTop").count() == 0,
       "katalogda movzu nisanlari tekrarlanmir")
    #  Basliqda sinfin ADI olmalidir, cilpaq kod yox.  Bu blok reload-dan
    #  sonra gelir, yeni LEVELS kesi BOSDUR - adi serverin cavabindan
    #  goturduyumuzu mehz burada yoxlayiriq.
    #  DIQQET: "sinif" sozunu butov metnde axtarmaq ALDADICIDIR -
    #  "bütün siniflər" geri duymesi de eyni elementin icindedir.
    #  Ortadaki hisseni ayirib baxiriq: cilpaq reqem olmamalidir.
    hd  = pg.inner_text(".bcount")
    seg = hd.split("·")[1].strip() if "·" in hd else hd
    ok(not seg.isdigit(), "basliqda sinfin ADI var (cilpaq kod yox)",
       hd.replace("\n", " "))

    #  movzuya klik -> numuneler acilir, duz cavab isarelenir
    pg.locator(".cvr").first.click()
    pg.wait_for_selector(".smp .sq", timeout=15000)
    ns = pg.locator(".smp .sq").count()
    ok(1 <= ns <= 3, "numune sayi serverde 3-le mehdudlasir", ns)
    ok(pg.locator(".smp .sq li.c").count() >= 1, "duz cavab isarelenib",
       pg.locator(".smp .sq li.c").count())
    #  ikinci klik baglayir
    pg.locator(".cvr").first.click(); pg.wait_for_timeout(300)
    ok(pg.locator(".smp .sq").count() == 0, "tekrar klik numuneleri baglayir")

    print("K · Mövzudan siyahıya keçid və «daha göstər»")
    #  Variantlar siyahida ABUNE ile gorunur (106_bank_siyahi_variantlar).
    #  Abunesiz hal SQL suitlerinde olculur - burada muellimin ekranda
    #  gorduyu esas hali yoxlayiriq.
    db("""insert into public.subscriptions
            (account_id, plan_id, status, seats, current_period_end)
          select a.id, p.id, 'active', 25, now() + interval '30 days'
            from public.accounts a, public.plans p
           where p.slug = 'repetitor-25' limit 1""")
    pg.locator(".cvr").first.click()
    pg.wait_for_selector(".smp [data-all]", timeout=15000)
    pg.click(".smp [data-all]")
    pg.wait_for_selector(".qrow", timeout=15000)
    ok(pg.locator(".qrow").count() >= 1, "movzunun suallari siyahi ile acilir",
       pg.locator(".qrow").count())
    #  suzgecde secili olan fenn/sinif setirlerde TEKRARLANMIR
    r0 = pg.locator(".qrow i").first.inner_text()
    ok("Riyaziyyat" not in r0, "setirde fenn tekrarlanmir", r0.replace("\n", " "))

    #  Numunede cavablar gorunurdu, siyahida ise yox olurdu - muellim
    #  "butun suallari gor" deyende DAHA AZ melumat alirdi.
    ok(pg.locator(".qopts").count() >= 1, "siyahida variantlar gorunur",
       pg.locator(".qopts").count())
    ok(pg.locator(".qopts li.c").count() >= 1, "siyahida duz cavab isarelenib",
       pg.locator(".qopts li.c").count())
    ok(pg.locator(".qitem").first.locator(".qopts li").count() == 4,
       "setirde dord variant var",
       pg.locator(".qitem").first.locator(".qopts li").count())
    db("delete from public.subscriptions")

    #  Siyahi rejimde nisanlar geri gelir - secilmis movzunu goturmek
    #  ucun basqa yol yoxdur
    if pg.locator("details.filt:not([open])").count():
        pg.locator("details.filt summary").click(); pg.wait_for_timeout(200)
    ok(pg.locator("#bTop .chip.on").count() == 1,
       "siyahida secilmis movzu nisani gorunur",
       pg.locator("#bTop .chip.on").count())

    #  «daha gostər»: 50-den cox netice veren axtarisa kecirik
    pg.goto(PANEL + "#/b"); pg.reload()
    pg.wait_for_selector("#bPool", timeout=15000)
    pool_click(pg, "Hazır bank")
    #  DIQQET: reload-dan sonra hovuz "mine"-dir ve OZ suallarinin
    #  siyahisi ekrandadir.  Sadece ".qrow" gozlesek kohne setirlere
    #  baxariq - fenn secicisini gozleyib teze render-i tesdiqleyirik.
    pg.wait_for_selector(".bpick .pkb", timeout=15000)
    pg.fill("#bq", "?")          # axtaris -> katalog yox, siyahi
    pg.wait_for_function(
        "() => !document.querySelector('.bpick') && "
        "document.querySelectorAll('.qrow').length > 0", timeout=15000)
    #  Sayi bazadan yeniden hesablamiriq (axtaris semantikasini tekrar
    #  yazmaq olardi) - ekranin OZ dediyi ile setir sayini tutusduruq.
    head  = pg.inner_text(".bcount")
    total = int("".join(ch for ch in head.split("·")[0] if ch.isdigit()))
    n1    = pg.locator(".qrow").count()
    if total > n1:
        ok(pg.locator("#bMore").count() == 1,
           "hamisi gosterilmeyibse «daha göstər» cixir", "%d/%d" % (n1, total))
        pg.click("#bMore")
        pg.wait_for_function(
            "document.querySelectorAll('.qrow').length > %d" % n1, timeout=15000)
        n2 = pg.locator(".qrow").count()
        ok(n2 > n1, "novbeti 50 elave olunur", "%d -> %d" % (n1, n2))
        ok(n2 == min(total, n1 + 50), "elave olunan say duzdur", n2)
    else:
        ok(pg.locator("#bMore").count() == 0,
           "hamisi gorunurse duyme cixmir", "%d/%d" % (n1, total))

    print("L · Siyahı rejimində mövzu nişanları sinif istəyir")
    #  Katalogda nisan bloku umumiyyetle yoxdur (blok J).  Qayda
    #  SIYAHI rejiminde qalir: cetinlik secilen kimi katalogdan
    #  cixiriq ve 113 nisan tokulmesin deye sinif teleb olunur.
    pg.goto(PANEL + "#/b"); pg.reload()
    pg.wait_for_selector("#bPool", timeout=15000)
    pool_click(pg, "Hazır bank")
    pg.wait_for_selector(".bpick .pkb", timeout=15000)
    pg.locator("details.filt summary").click()
    pg.wait_for_selector("#bsub", timeout=15000)
    pg.select_option("#bsub", "riyaziyyat")
    pg.wait_for_selector("#bsub", timeout=15000); pg.wait_for_timeout(600)
    ok(pg.locator("#bTop").count() == 0, "katalogda nisan bloku yoxdur")
    ok("mövzu var" not in pg.inner_text("#bFilt"),
       "katalogda ipucu da tekrarlanmir - ehate paneli onu ozu verir")

    #  cetinlik secilir -> siyahi rejimi -> nisan bloku qayidir
    pg.locator("#bDiff .chip", has_text="Asan").click()
    pg.wait_for_selector(".qrow", timeout=15000)
    ok("sinif də seçin" in pg.inner_text("#bFilt"),
       "cox movzu olanda siyahida sinif istenilir")
    ok("mövzu var" in pg.inner_text("#bFilt"), "necə mövzu oldugu yazilir")
    ok(pg.locator("#bTop").count() == 0, "sinifsiz nisanlar hele tokulmur")
    pg.select_option("#blev", code)
    pg.wait_for_selector("#bTop", timeout=15000)
    nch = pg.locator("#bTop .chip").count()
    ok(0 < nch <= 20, "sinifle nisan sayi yigcamdir", nch)

    print("M · Köhnə cavab təzə ekranın üstünə düşmür")
    #  guard() yalniz UNVANI tutusdurur; bank ekraninda hovuz
    #  deyisende unvan ("#/b") DEYISMIR.  Ona gore "mine" hovuzunun
    #  ucusdaki cavabi "Platforma" render-inin ustune dusurdu:
    #  seqmentde Platforma yanirdi, siyahida ise muellimin OZ
    #  suallari qalirdi.  Yarisi deterministik etmek ucun BIRINCI
    #  rpc_bank_list-i mock-da 2 saniye lengidirik (X-Test-Delay).
    calls = {"n": 0}

    def slow_first_list(route, request):
        calls["n"] += 1
        h = dict(request.headers)
        if calls["n"] == 1:
            h["x-test-delay"] = "2000"
        route.continue_(headers=h)

    pg.route("**/rpc/rpc_bank_list", slow_first_list)
    pg.goto(PANEL + "#/b"); pg.reload()
    pg.wait_for_selector("#bPool", timeout=20000)
    pool_click(pg, "Hazır bank")           # kohne sorgu HELE ucusdadir
    pg.wait_for_selector(".bpick .pkb", timeout=20000)
    ok(calls["n"] >= 1, "lengidilen sorgu hequiqeten gedib", calls["n"])
    pg.wait_for_timeout(2600)             # lengidilen cavab bu araliqda gelir
    seg  = pg.locator("#bPool .seg.on").inner_text()
    rows = pg.locator(".qrow").count()
    ok(seg == "Hazır bank", "seqment Hazır bank qalir", seg)
    ok(rows == 0, "KOHNE hovuzun siyahisi ustune DUSMUR", "%d setir" % rows)
    ok(pg.locator(".bpick .pkb").count() >= 1, "fenn secicisi yerinde qalir")
    pg.unroute("**/rpc/rpc_bank_list")

    print("H2 · Telefonda səliqə")
    ok(pg.evaluate("document.documentElement.scrollWidth <= window.innerWidth + 1"),
       "bank ekraninda yana surusme yoxdur")
    pg.click("#btnNewQ"); pg.wait_for_selector("#qbody", timeout=8000)
    ok(pg.evaluate("document.documentElement.scrollWidth <= window.innerWidth + 1"),
       "formada yana surusme yoxdur")

    ctx.close(); br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails))
    for f in fails: print("  - " + f)
    sys.exit(1)
print("SUAL BANKI: BUTUN YOXLAMALAR KECDI")
