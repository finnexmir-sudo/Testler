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
    pg.wait_for_selector("#btnStu", timeout=8000)
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
        sp.click("#btnNext"); sp.wait_for_timeout(300)
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
    # Test bazasinda yalniz 3-cu sinif var. 4-cu sinif qrupunda siyahi
    # bosdur - amma "hamisi verilib" YOX, "hele test yoxdur" yazilmalidir.
    pg.click("#btnBack"); pg.wait_for_selector("#btnRen", timeout=8000)
    pg.click("#btnRen"); pg.wait_for_selector("#gLev", timeout=8000)
    pg.select_option("#gLev", "4"); pg.click("#gSave")
    pg.wait_for_timeout(900)
    pg.click("#btnAsgs"); pg.wait_for_selector("#pick .empty", timeout=8000)
    t = pg.inner_text("#pick")
    ok("hələ test yoxdur" in t, "bos test bazasi duzgun izah olunur",
       t.replace("\n", " ")[:70])
    ok("Bütün testlər verilib" not in t, "yaniltici 'hamisi verilib' yazilmir")
    ok("4-cü sinif" in t, "hansi sinif oldugu yazilir")
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

    ctx.close(); br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails))
    for f in fails: print("  - " + f)
    sys.exit(1)
print("TAPSIRIQLAR: BUTUN YOXLAMALAR KECDI")
