#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Tedris fennleri: qurulusda secim -> siyahilar daralir -> profilden sifirlanir."""
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
delete from public.class_plan_items; delete from public.class_plans;
delete from public.question_reports;
delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments;     delete from public.student_sessions;
delete from public.students;        delete from public.classes;
delete from public.subscriptions;
delete from public.test_questions tq using public.tests t
 where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.account_members; delete from public.accounts;
delete from public.user_roles;      delete from auth.users;
""")

with sync_playwright() as pw:
    br  = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 1280, "height": 900})
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=TEST_CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))

    print("A · Quruluşda fənn seçilir")
    pg.goto(PANEL); pg.wait_for_timeout(400)
    pg.click("#btnSwap")
    pg.fill("#fname", "Fenn Muellim"); pg.fill("#email", "fn@t.az")
    pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=8000)
    pg.wait_for_selector("#setSubs [data-sub]", timeout=8000)
    ok(pg.locator("#setSubs [data-sub]").count() >= 2, "fenn nisanlari dolur",
       pg.locator("#setSubs [data-sub]").count())
    pg.locator("#setSubs [data-sub='riyaziyyat']").click()
    pg.select_option("#atype", "tutor")
    pg.fill("#aname", "Fenn hesabi"); pg.click("#btnSetup")
    pg.wait_for_selector("#btnBank", timeout=8000)
    r = db("select subjects from public.accounts", one=True)
    ok(r and r["subjects"] == ["riyaziyyat"], "fenn bazaya yazildi",
       r and r["subjects"])

    #  platforma hovuzu abune ile acilir - siyahilarin dolmasi ucun
    AID = db("select id::text i from public.accounts", one=True)["i"]
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select %s, p.id, 'active', now() + interval '30 days'
            from public.plans p where p.slug = 'repetitor-25'""", (AID,))

    print("B · Siyahılar daralır")
    pg.goto(PANEL + "#/gen"); pg.reload()
    pg.wait_for_selector("#gsub", timeout=8000)
    pg.wait_for_function(
        "document.querySelectorAll('#gsub option').length > 1", timeout=8000)
    ok(pg.locator("#gsub option").count() == 2,
       "generatorda yalniz oz fenni (+Butun)", pg.locator("#gsub option").count())
    pg.goto(PANEL + "#/b"); pg.reload()
    pg.wait_for_selector(".seg[data-v='platform']", timeout=8000)
    pg.locator(".seg[data-v='platform']").click()
    pg.wait_for_selector(".pkb", timeout=8000)
    ok(pg.locator(".pkb").count() == 1, "bank secicisinde tek fenn",
       pg.locator(".pkb").count())
    ok("Riyaziyyat" in pg.inner_text(".bpick"), "o fenn riyaziyyatdir")

    print("C · Profildən sıfırlanır")
    pg.goto(PANEL + "#/me"); pg.reload()
    pg.wait_for_selector("#meSubs [data-sub]", timeout=8000)
    ok("on" in (pg.locator("#meSubs [data-sub='riyaziyyat']")
                .get_attribute("class") or ""), "profil secimi gosterir")
    pg.locator("#meSubs [data-sub='riyaziyyat']").click()
    pg.click("#btnMeSave")
    pg.wait_for_selector("#meErr .ok", timeout=8000)
    r = db("select subjects from public.accounts", one=True)
    ok(r and r["subjects"] == [], "bazada siyahi bosaldi", r and r["subjects"])
    pg.goto(PANEL + "#/gen"); pg.reload()
    pg.wait_for_selector("#gsub", timeout=8000)
    pg.wait_for_function(
        "document.querySelectorAll('#gsub option').length > 1", timeout=8000)
    ok(pg.locator("#gsub option").count() > 2, "filtr goturulende hamisi qayidir",
       pg.locator("#gsub option").count())

    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails))
    for f in fails: print("  - " + f)
    sys.exit(1)
print("FENN: BUTUN YOXLAMALAR KECDI")
