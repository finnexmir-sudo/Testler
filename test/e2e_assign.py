#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Tapsiriq axini: muellim test teyin edir, sagird onu gorur ve isleyir."""
import sys, datetime
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

PANEL   = "http://127.0.0.1:8010/muellim/index.html"
STUDENT = "http://127.0.0.1:8010/sagird/index.html"
CHROME  = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN     = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
BLOCK   = "**://*.supabase.co/**"
TEST_CFG = """window.CFG = {
  SUPABASE_URL: "http://127.0.0.1:54321",
  SUPABASE_ANON_KEY: "test-anon-key",
  STUDENT_URL: "https://example.test/Testler/"
};"""

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

# ------------------------------------------------ hazirliq
# Muellim UI-dan qeydiyyatdan kecir: mock-un parol yaddasi yalniz
# signup-la dolur, birbasa auth.users setri ile giris mumkun deyil.
db("""
delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments;     delete from public.student_sessions;
delete from public.students;        delete from public.classes;
-- muellim testleri/suallari da silinir - suite sirasindan asililiq olmasin
delete from public.test_questions tq using public.tests t
 where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.question_options o using public.questions q
 where q.id = o.question_id and q.owner_type = 'educator';
delete from public.questions where owner_type = 'educator';
delete from public.account_members; delete from public.accounts;
delete from public.user_roles;      delete from auth.users;
""")
if not db("select 1 from public.tests where owner_type='platform' limit 1", one=True):
    db(open("db/07_seed_tests.sql", encoding="utf-8").read())

# Duzgun cavablar - test ozu ucun, imtiyazli rolda
KEY = {r["qid"]: r["oid"] for r in db("""
  select q.id::text qid, o.id::text oid
    from public.questions q
    join public.test_questions tq on tq.question_id = q.id
    join public.tests t on t.id = tq.test_id and t.slug = 'riy-3-vurma-1'
    join public.question_options o on o.question_id = q.id and o.is_correct""")}

with sync_playwright() as pw:
    br  = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 430, "height": 900})

    def new_ctx_page():
        '''Ayri kontekst: sagird sessiyasi localStorage-de saxlanir,
           eyni kontekstde ikinci sagird avtomatik birincinin
           sessiyasi ile acilirdi.'''
        c = br.new_context(viewport={"width": 430, "height": 900})
        pg = c.new_page()
        pg.route("**/config.js*", lambda r: r.fulfill(
            status=200, content_type="application/javascript", body=TEST_CFG))
        pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
        pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))
        return c, pg

    def new_page():
        pg = ctx.new_page()
        pg.route("**/config.js*", lambda r: r.fulfill(
            status=200, content_type="application/javascript", body=TEST_CFG))
        pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
        pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))
        return pg

    # ---------------------------------------------------- muellim
    pg = new_page()
    pg.goto(PANEL); pg.wait_for_timeout(400)
    pg.click("#btnSwap")
    pg.fill("#fname", "Muellim"); pg.fill("#email", "t@t.az")
    pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=8000)
    pg.select_option("#atype", "tutor")
    pg.fill("#aname", "Riyaziyyat qrupu"); pg.click("#btnSetup")
    pg.wait_for_function("document.querySelectorAll('#glevel option').length > 1",
                         timeout=8000)
    pg.fill("#gname", "3-B qrupu"); pg.select_option("#glevel", "3")
    pg.click("#btnGroup")
    pg.wait_for_selector("#groups .item", timeout=8000)
    pg.click("#groups .item")
    pg.wait_for_selector("#gTabs", timeout=8000)
    try: pg.wait_for_selector("#sname", state="visible", timeout=3000)   # 0 sagirdde forma ozu acilir
    except Exception: pg.click("#btnStuOpen")
    pg.fill("#sname", "Aysu Məmmədova"); pg.click("#btnStu")
    pg.wait_for_selector(".stu", timeout=8000)

    GID  = db("select id::text i from public.classes", one=True)["i"]
    CODE = db("select login_code c from public.students", one=True)["c"]

    print("A · Tapşırıqlar ekranı")
    pg.wait_for_selector("#btnAsgs", timeout=8000)
    ok(True, "qrup ekraninda 'Tapsiriqlar' duymesi var")
    pg.click("#btnAsgs")
    pg.wait_for_selector("#fp", timeout=8000)
    ok("/a/" + GID in pg.url, "tapsiriq ekraninin oz unvani var", pg.url.split("#")[-1])
    ok(pg.is_checked("#fp"), "serbest mesq ilkin olarak ACIQDIR")
    ok("Hələ tapşırıq verilməyib" in pg.inner_text("#asgList"), "bos veziyyet aydindir")
    pg.wait_for_function("document.querySelectorAll('#aTest option').length > 0",
                         timeout=8000)
    n = pg.locator("#aTest option").count()
    ok(n >= 3, "teyin edile bilen testler yuklenir", n)
    labels = pg.locator("#aTest option").all_inner_texts()
    dup = [t for t in labels
           if t.count("Azərbaycan dili") > 1 or t.count("Riyaziyyat") > 1]
    ok(not dup, "fenn adi siyahida tekrarlanmir", dup[:1] or labels[0])

    #  Fenn dugmeleri ve axtaris siyahini suzur (canli sikayet: qarisiq)
    if pg.locator("#aSubs").count():
        chips = pg.locator("#aSubs .chip")
        ok(chips.count() >= 3, "fenn dugmeleri: Hamisi + fennler", chips.count())
        chips.nth(1).click()
        m = pg.locator("#aTest option").count()
        ok(0 < m < n, "fenn secilende siyahi qisalir", (m, n))
        ok(pg.locator("#aHint").inner_text().strip() != "", "secilmis testin izahi yazilir",
           pg.locator("#aHint").inner_text())
        chips.nth(0).click()
        ok(pg.locator("#aTest option").count() == n, "Hamisi - siyahi qayidir")
    if pg.locator("#aQ").count():
        pg.fill("#aQ", "vurma")
        vs = pg.locator("#aTest option").all_inner_texts()
        ok(vs and all("Vurma" in v for v in vs), "axtaris yalniz uygun testleri saxlayir", vs[:2])
        pg.fill("#aQ", "")
        ok(pg.locator("#aTest option").count() == n, "axtaris silinende siyahi qayidir")

    print("B · Tapşırıq vermək")
    lbl = [t for t in pg.locator("#aTest option").all_inner_texts()
           if "Vurma cədvəli" in t][0]
    pg.select_option("#aTest", label=lbl)
    day = (datetime.date.today() + datetime.timedelta(days=7)).isoformat()
    pg.fill("#aDate", day)
    pg.select_option("#aTry", "2")
    pg.click("#btnAsg")
    pg.wait_for_selector(".asg", timeout=8000)
    row = pg.inner_text(".asg").replace("\n", " ")
    ok("Vurma cədvəli" in row, "tapsiriq siyahiya dusdu", row[:60])
    ok("Aktiv" in row, "aktiv kimi isarelenir")
    ok("2 cəhd" in row, "cehd sayi gorunur")
    ok("son tarix" in row, "son tarix gorunur")
    ok("0/1 şagird bitirib" in row, "gedisat gorunur")
    ok("Aktiv (1)" in pg.inner_text("#asgTabs"), "tablarda say gorunur",
       pg.inner_text("#asgTabs").replace("\n", " "))
    pg.locator("#asgTabs .seg", has_text="Bağlı").click()
    pg.wait_for_timeout(300)
    ok("Bağlı tapşırıq yoxdur" in pg.inner_text("#asgList"), "bagli tab bosdur")
    pg.locator("#asgTabs .seg", has_text="Aktiv").click()
    pg.wait_for_timeout(300)
    ok(pg.locator(".asg").count() == 1, "aktiv taba qayidir")
    a = db("select max_attempts m, closes_at c from public.assignments", one=True)
    ok(a is not None and a["m"] == 2, "bazada cehd sayi 2", a and a["m"])
    ok(a and a["c"] is not None, "bazada son tarix var")

    print("C · Keçmiş tarix qəbul edilmir")
    past = (datetime.date.today() - datetime.timedelta(days=1)).isoformat()
    pg.wait_for_function("document.querySelectorAll('#aTest option').length > 0",
                         timeout=8000)
    pg.fill("#aDate", past)
    pg.click("#btnAsg"); pg.wait_for_timeout(500)
    ok(pg.is_visible("#aErr") and pg.inner_text("#aErr").strip() != "",
       "kecmis tarixde xeta gosterilir", pg.inner_text("#aErr").strip()[:45])
    ok(db("select count(*) n from public.assignments", one=True)["n"] == 1,
       "ikinci teyinat yaranmadi")

    # ---------------------------------------------------- sagird
    print("D · Şagird tapşırığı görür")
    sp = new_page()
    sp.goto(STUDENT); sp.wait_for_selector("#btnIn", timeout=8000)
    sp.fill("#code", CODE); sp.click("#btnIn")
    sp.wait_for_selector(".test", timeout=8000)
    heads = sp.locator("#main h2").evaluate_all("els => els.map(e => e.textContent)")
    ok("Tapşırıqlar" in heads, "'Tapsiriqlar' bolmesi var", heads)
    ok("Sərbəst məşq" in heads, "'Serbest mesq' bolmesi var", heads)
    ok(sp.locator(".test.asg").count() == 1, "bir tapsiriq gorunur",
       sp.locator(".test.asg").count())
    asg = sp.inner_text(".test.asg").replace("\n", " ")
    ok("Vurma cədvəli" in asg, "duzgun test", asg[:50])
    ok("son tarix" in asg, "sagird son tarixi gorur", asg[-40:])
    ok(sp.locator(".test:not(.asg)").count() == 3,
       "teyin olunan test serbest mesqde TEKRARLANMIR",
       sp.locator(".test:not(.asg)").count())

    print("E · Tapşırığı işləmək")
    sp.locator(".test.asg").first.click()
    sp.wait_for_selector(".opt", timeout=8000)
    nq = len(KEY)
    for i in range(nq):
        ids = sp.locator(".opt").evaluate_all("els => els.map(e => e.getAttribute('data-o'))")
        want = next((o for o in ids if o in KEY.values()), None)
        sp.locator("[data-o='%s']" % want).click()
        sp.wait_for_timeout(100)
        if i + 1 < nq: sp.click("#btnNext")
        else: sp.click("#btnFinish")
        sp.wait_for_timeout(300)
    sp.wait_for_selector(".ring", timeout=8000)
    ok("100" in sp.inner_text(".ring .val"), "netice 100%")
    ok("bir də cəhd edə bilərsən" in sp.inner_text("#main"),
       "teyinatda 2 cehd var -> ikinci cehd teklif olunur",
       sp.inner_text(".score .sub"))

    sp.click("#btnHome"); sp.wait_for_selector(".test", timeout=8000)
    asg = sp.inner_text(".test.asg").replace("\n", " ")
    ok("1 cəhd qalıb" in asg, "qalan cehd sayi gorunur", asg[-40:])

    print("F · Müəllim nəticəni görür")
    pg.reload(); pg.wait_for_selector(".asg", timeout=8000)
    row = pg.inner_text(".asg").replace("\n", " ")
    ok("1/1 şagird bitirib" in row, "bitiren sagird sayilir", row[-50:])
    ok("orta 100%" in row, "orta netice gorunur", row[-30:])

    print("G · Sərbəst məşqi bağlamaq")
    pg.uncheck("#fp"); pg.wait_for_timeout(600)
    ok(db("select free_practice f from public.classes where id = %s", (GID,),
          one=True)["f"] is False, "ayar bazada saxlanildi")
    sp.reload(); sp.wait_for_selector(".test", timeout=8000)
    ok(sp.locator(".test").count() == 1, "sagirde yalniz tapsiriq qalir",
       sp.locator(".test").count())
    heads = sp.locator("#main h2").evaluate_all("els => els.map(e => e.textContent)")
    ok("Sərbəst məşq" not in heads, "serbest mesq bolmesi gizlenir", heads)

    print("H · Testi olmayan sinif aydın izah olunur")
    # Test bazasinda yalniz 3-cu sinif var.
    # DIQQET: db/112-den sonra ASAGI sinif testleri de gorunur, ona gore
    # 4-cu sinif qrupu ARTIQ BOS DEYIL - 3-cu sinif testlerini gorur.
    # Bos hal indi yalniz movcud testlerden ASAGI sinifde olur: 2-ci
    # sinif qrupuna 3-cu sinif testi teklif olunmur (yuxaridir).
    pg.click("#btnBack"); pg.wait_for_selector("#btnRen", timeout=8000)
    pg.click("#btnRen"); pg.wait_for_selector("#gLev", timeout=8000)
    pg.select_option("#gLev", "4"); pg.click("#gSave")
    pg.wait_for_timeout(900)
    pg.click("#btnAsgs"); pg.wait_for_selector("#aTest", timeout=8000)
    ok(pg.locator("#aTest option").count() >= 1,
       "4-cu sinif qrupu ASAGI sinif testlerini gorur",
       pg.locator("#aTest option").count())
    #  ayrica izah yoxdur (UX yoxlamasi) - asagi sinif testinin sinfi
    #  secim setrinin ozunde " · N-ci sinif" kimi yazilir
    ok(any("sinif" in o for o in pg.locator("#aTest option").all_inner_texts()),
       "asagi sinif testinin sinfi secim setrinde yazilir")

    pg.click("#btnBack"); pg.wait_for_selector("#btnRen", timeout=8000)
    pg.click("#btnRen"); pg.wait_for_selector("#gLev", timeout=8000)
    pg.select_option("#gLev", "2"); pg.click("#gSave")
    pg.wait_for_timeout(900)
    pg.click("#btnAsgs"); pg.wait_for_selector("#pick .empty", timeout=8000)
    t = pg.inner_text("#pick")
    ok("hələ test yoxdur" in t, "bos test bazasi duzgun izah olunur",
       t.replace("\n", " ")[:70])
    ok("Bütün testlər verilib" not in t, "yaniltici 'hamisi verilib' yazilmir")
    ok("2-ci sinif" in t, "hansi sinif oldugu yazilir")
    # geri qaytaririq
    pg.click("#btnBack"); pg.wait_for_selector("#btnRen", timeout=8000)
    pg.click("#btnRen"); pg.wait_for_selector("#gLev", timeout=8000)
    pg.select_option("#gLev", "3"); pg.click("#gSave")
    pg.wait_for_timeout(900)
    pg.click("#btnAsgs"); pg.wait_for_selector("#aTest", timeout=8000)
    ok(pg.locator("#aTest option").count() >= 3,
       "sinif duzelende testler qayidir", pg.locator("#aTest option").count())

    print("I · Tapşırığı götürmək")
    pg.reload(); pg.wait_for_selector(".asg [data-del]", timeout=8000)
    pg.click(".asg [data-del]")
    pg.wait_for_selector("#asgList .empty", timeout=8000)
    ok(db("select count(*) n from public.assignments", one=True)["n"] == 0,
       "teyinat bazadan silindi")
    sp.reload(); sp.wait_for_selector(".empty", timeout=8000)
    ok(sp.locator(".test").count() == 0,
       "serbest mesq bagli + tapsiriq yox -> sagirde test qalmir")
    ok("Tapşırıq yoxdur" in sp.inner_text("#main"), "sagirde sebeb izah olunur")

    print("F · Fərdi tapşırıq — yalnız bir şagirdə")
    #  ikinci sagird elave edilir ki, "yalniz o gorur" yoxlanila bilsin
    pg.goto(PANEL + "#/g/" + GID); pg.reload()
    pg.wait_for_selector("#gTabs", timeout=8000)
    try: pg.wait_for_selector("#sname", state="visible", timeout=3000)   # 0 sagirdde forma ozu acilir
    except Exception: pg.click("#btnStuOpen")
    pg.fill("#sname", "Ikinci Sagird"); pg.click("#btnStu")
    pg.wait_for_function("document.querySelectorAll('.stu').length >= 2", timeout=8000)
    SID1 = db("select id::text i from public.students where login_code = %s",
              (CODE,), one=True)["i"]
    KOD2 = db("""select login_code c from public.students
                  where full_name = 'Ikinci Sagird'""", one=True)["c"]

    pg.goto(PANEL + "#/a/" + GID); pg.reload()
    pg.wait_for_selector("#aWho", timeout=8000)
    whos = pg.locator("#aWho option").all_inner_texts()
    ok(len(whos) == 3, "kime siyahisi: butun qrup + 2 sagird", whos)
    ok("Bütün qrup" in whos[0], "ilk secim butun qrupdur", whos[0])
    ok(sum(1 for w in whos if "yalnız" in w) == 2, "her sagird 'yalniz' ile gelir")
    ok(any("Ikinci Sagird" in w for w in whos), "kime siyahisinda TAM ad gorunur (qisa 'Ikinci S.' yox)", whos)

    #  sagird hesabatindan "Test tapsir": tapsiriq ekrani hemin sagird secili acilir
    pg.goto(PANEL + "#/s/" + SID1 + "/" + GID); pg.reload()
    pg.wait_for_selector("#btnAsgStu", timeout=8000)
    pg.click("#btnAsgStu")
    pg.wait_for_selector("#aWho", timeout=8000)
    ok(pg.locator("#aWho").input_value() == SID1, "sagird hesabatindan gelende o secilidir")
    ok("Yalnız" in pg.inner_text("#aErr"), "ekranda 'yalniz ... ucun' yazisi", pg.inner_text("#aErr")[:50])
    pg.click("#btnBack"); pg.wait_for_selector("#btnAsgStu", timeout=8000)
    ok(True, "Geri sagird hesabatina qaytarir")
    #  Qrup ekranindan sagird hesabatina girib "Geri" - qrup ekranina (hesabata yox)
    pg.goto(PANEL + "#/g/" + GID); pg.wait_for_selector("#gTabs", timeout=8000)
    pg.locator("[data-rep]").first.click(); pg.wait_for_selector("#btnAsgStu", timeout=8000)
    pg.click("#btnB"); pg.wait_for_selector("#gTabs", timeout=8000)
    ok(pg.evaluate("location.hash") == "#/g/" + GID, "Geri qrup ekranina qaytarir", pg.evaluate("location.hash"))
    pg.goto(PANEL + "#/r/" + GID); pg.wait_for_selector("#rTabs", timeout=8000)
    pg.goto(PANEL + "#/s/" + SID1 + "/" + GID); pg.wait_for_selector("#btnAsgStu", timeout=8000)
    pg.click("#btnB"); pg.wait_for_timeout(600)
    ok(pg.evaluate("location.hash") == "#/r/" + GID, "hesabatdan gelende Geri hesabata qaytarir", pg.evaluate("location.hash"))
    pg.goto(PANEL + "#/a/" + GID); pg.reload()
    pg.wait_for_selector("#aWho", timeout=8000)
    ok(pg.locator("#aWho").input_value() == "", "adi girisde 'Butun qrup' secilidir")

    #  novbeti testi YALNIZ birinci sagirde veririk
    SOLO = pg.locator("#aTest option").first.get_attribute("value")
    TTL  = pg.locator("#aTest option").first.inner_text()
    pg.select_option("#aWho", SID1)
    pg.click("#btnAsg")
    pg.wait_for_selector(".asg .pill.solo", timeout=8000)
    ok("yalnız" in pg.inner_text(".asg .pill.solo"), "siyahida ferdi nisani var",
       pg.inner_text(".asg .pill.solo"))
    a = db("""select student_id::text s, test_id::text t from public.assignments
               where student_id is not null""", one=True)
    ok(a is not None and a["s"] == SID1 and a["t"] == SOLO,
       "bazada dogru sagirde / dogru testle yazilib")
    #  ferdi teyinat mexreci 1-dir - "0/2" yazilmamalidir
    ok("/1 şagird bitirib" in pg.inner_text("#asgList"),
       "ferdi setirde mexrec 1-dir")

    print("G · Şagird tərəfi: fərdi tapşırıq yalnız sahibinə")
    #  testin adi qrup teyinatlarindan ferqlenir - ada gore axtaririq
    ad = db("select title t from public.tests where id = %s", (SOLO,), one=True)["t"]
    c1, s1 = new_ctx_page(); s1.goto(STUDENT)
    s1.wait_for_selector("#code", timeout=8000)
    s1.fill("#code", CODE); s1.click("#btnIn")
    s1.wait_for_selector(".test", timeout=8000)
    ok(ad in s1.inner_text("#main"), "sahibi ferdi tapsirigi gorur", ad[:40])
    ok(s1.locator(".test .solo").count() == 1, "sahibinde 'sene' nisani var",
       s1.locator(".test .solo").count())

    c2, s2 = new_ctx_page(); s2.goto(STUDENT)
    s2.wait_for_selector("#code", timeout=8000)
    s2.fill("#code", KOD2); s2.click("#btnIn")
    s2.wait_for_selector(".shero", timeout=8000)
    ok(ad not in s2.inner_text("#main"),
       "BASQA sagird ferdi tapsirigi GORMUR - sizinti yoxdur")
    ok(s2.locator(".test .solo").count() == 0, "basqa sagirdde 'sene' nisani yoxdur")
    c1.close(); c2.close()

    ctx.close()
    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails))
    for f in fails: print("  - " + f)
    sys.exit(1)
print("TAPSIRIQLAR: BUTUN YOXLAMALAR KECDI")
