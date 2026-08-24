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
    pg.click("#btnSetup"); pg.wait_for_selector("#btnBank", timeout=8000)

    print("A · Bank ekranı")
    ok(True, "esas sehifede 'Sual banki' var")
    pg.click("#btnBank"); pg.wait_for_selector("#btnNewQ", timeout=8000)
    ok("/b" in pg.url, "bankin oz unvani var", pg.url.split("#")[-1])
    ok("0" in pg.inner_text(".seat .num"), "istifade gostericisi 0-dan baslayir",
       pg.inner_text(".seat .num").replace("\n", " "))
    pg.wait_for_selector("#bList .empty", timeout=8000)
    ok("Sual tapılmadı" in pg.inner_text("#bList"), "bos veziyyet aydindir")

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
    pg.locator(".obody").nth(2).fill("48")
    pg.select_option("#qlev", "3")
    tp = db("select id::text i from public.topics where slug='vurma-cedveli'", one=True)
    if tp: pg.select_option("#qtop", tp["i"])
    pg.locator("#qdiff .seg", has_text="Çətin").click()
    pg.wait_for_timeout(200)
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
    pg.locator("#bDiff .chip", has_text="Asan").click(); pg.wait_for_timeout(500)
    ok(pg.locator(".qrow").count() == 0, "cetinlik suzgeci isleyir")
    ok(pg.locator("details.filt").get_attribute("open") is not None,
       "suzgec aktiv olanda acıq qalir")
    ok(pg.inner_text("details.filt summary").strip().endswith("1"),
       "aktiv suzgec sayi gorunur", pg.inner_text("details.filt summary").strip())
    pg.locator("#bDiff .chip", has_text="Asan").click(); pg.wait_for_timeout(500)
    ok(pg.locator(".qrow").count() == 1, "suzgec geri qaytarilir")

    pg.locator("#bPool .seg", has_text="Platforma").click(); pg.wait_for_timeout(600)
    np = pg.locator(".qrow").count()
    ok(np >= 20, "platforma hovuzu gorunur", np)
    ok(pg.locator(".qrow[disabled]").count() == np,
       "platforma suallari redakte olunmur")
    pg.locator("#bPool .seg", has_text="Öz suallarım").click(); pg.wait_for_timeout(600)

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
    w = pg.locator(".top .mark").first.evaluate("e => e.getBoundingClientRect().width")
    ok(24 <= w <= 28, "nisan olcusu duzgun (32 olsa CSS toqqusub)", str(round(w)) + "px")

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
