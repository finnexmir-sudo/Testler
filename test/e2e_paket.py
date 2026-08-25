#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Paket sehifesi ve admin idareetmesi."""
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
  STUDENT_URL: "https://example.test/Testler/",
  CONTACT_WHATSAPP: "+994501234567"
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
delete from public.students;        delete from public.classes;
delete from public.subscriptions;
delete from public.test_questions tq using public.tests t
 where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.question_options o using public.questions q
 where q.id = o.question_id and q.owner_type = 'educator';
delete from public.questions where owner_type = 'educator';
delete from public.account_members; delete from public.accounts;
delete from public.user_roles;      delete from auth.users;
""")

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

    pg = new_page()
    pg.goto(PANEL); pg.wait_for_timeout(400)
    pg.click("#btnSwap")
    pg.fill("#fname", "Paket Muellim"); pg.fill("#email", "pkt@t.az")
    pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=8000)
    pg.select_option("#atype", "tutor")
    pg.fill("#aname", "Paket hesabi"); pg.click("#btnSetup")
    pg.wait_for_selector("#btnBank", timeout=8000)

    print("A · Paket səhifəsi (abunəsiz)")
    ok(pg.locator("#btnPkt").count() == 1, "esas sehifede Paket bendi var")
    ok(pg.locator("#btnAdm").count() == 0, "adi muellimde Idareetme bendi YOXDUR")
    pg.click("#btnPkt")
    pg.wait_for_selector(".pkt", timeout=8000)
    ok("abunəniz yoxdur" in pg.inner_text("#main"), "abunesiz hal aydin yazilir")
    npl = pg.locator(".pkt").count()
    ok(npl >= 2, "planlar gorunur", npl)
    ok("₼" in pg.inner_text("#main"), "qiymetler manatladir")
    ok("Valideyn" not in pg.inner_text("#main"), "ozge auditoriya plani gorunmur")
    href = pg.locator("#btnWa").get_attribute("href")
    ok(href and "wa.me/994501234567" in href, "WhatsApp duymesi nomreye acilir",
       (href or "")[:50])

    print("B · Adi müəllim admin ünvanına girə bilmir")
    pg.goto(PANEL + "#/adm"); pg.wait_for_timeout(700)
    ok("admin" in pg.inner_text("#main").lower(), "acıq imtina mesaji gorunur",
       pg.inner_text("#main")[:60].replace("\n", " "))

    print("C · Admin rolu ilə idarəetmə")
    UID = db("select id::text i from auth.users", one=True)["i"]
    db("insert into public.user_roles (user_id, role) values (%s, 'admin') on conflict do nothing", (UID,))
    pg.goto(PANEL); pg.reload()
    pg.wait_for_selector("#btnAdm", timeout=8000)
    ok(True, "admin rolunda Idareetme bendi gorunur")
    pg.click("#btnAdm")
    pg.wait_for_selector(".admr", timeout=8000)
    ok(pg.locator(".tile").count() == 4, "gosterici lovheleri gorunur",
       pg.locator(".tile").count())
    tl = pg.inner_text(".tiles").replace("\n", " ")
    ok("hesab" in tl and "abun" in tl and "gəlir" in tl,
       "lovhelerde hesab/abune/gelir var", tl[:70])
    npo = pg.locator("#admPlan option").count()
    ok(npo >= 2, "plan secimi bazadan dolur", npo)
    row = pg.inner_text(".admr").replace("\n", " ")
    ok("pkt@t.az" in row, "hesab siyahida e-poctla gorunur", row[:60])
    ok("paketsiz" in row, "paketsiz nisani gorunur")
    ok("aktivlik" in row, "son aktivlik gorunur", row[:80])

    print("D · Bir kliklə abunə açmaq")
    pg.on("dialog", lambda d: d.accept())
    pg.locator(".admr [data-m='6']").click()
    pg.wait_for_selector(".admr .pb.y", timeout=8000)
    ok("Repetitor" in pg.inner_text(".admr .pb.y"), "abune nisani setirde gorunur",
       pg.inner_text(".admr .pb.y")[:40])
    ok("yerinə yetirildi" in pg.inner_text("#admMsg"), "netice mesaji gorunur")
    ok("1" in pg.inner_text(".tile.b"), "aktiv abune lovhesi yenilenir",
       pg.inner_text(".tile.b").replace("\n", " "))
    a = db("""select s.status, s.provider from public.subscriptions s""", one=True)
    ok(a and a["status"] == "active" and a["provider"] == "manual",
       "bazada active/manual abune var")

    print("E · Paket səhifəsi abunəni göstərir")
    pg.goto(PANEL + "#/p"); pg.reload()
    pg.wait_for_selector(".pkt", timeout=8000)
    ok("Hazırkı paket" in pg.inner_text("#main"), "hazirki paket gorunur")
    ok("bitmə tarixi" in pg.inner_text("#main"), "bitme tarixi gorunur")

    print("F · Dayandırmaq")
    pg.goto(PANEL + "#/adm"); pg.reload()
    pg.wait_for_selector(".admr", timeout=8000)
    pg.locator(".admr [data-stop]").click()
    pg.wait_for_timeout(900)
    pg.wait_for_selector(".admr", timeout=8000)
    ok(not db("select 1 ok from public.subscriptions where status='active'", one=True),
       "bazada aktiv abune qalmadi")

    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails))
    for f in fails: print("  - " + f)
    sys.exit(1)
print("PAKET: BUTUN YOXLAMALAR KECDI")
