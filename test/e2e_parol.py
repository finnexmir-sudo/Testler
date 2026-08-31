#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Parol berpasi axini: unutdum -> link -> yeni parol -> giris.

Kohne parol islemir, yenisi isleyir.
"""
import json, sys, urllib.request
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

PANEL  = "http://127.0.0.1:8010/muellim/index.html"
API    = "http://127.0.0.1:54321"
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

    print("A · Qeydiyyat və çıxış")
    pg.goto(PANEL); pg.wait_for_timeout(400)
    pg.click("#btnSwap")
    pg.fill("#fname", "Parol Muellim"); pg.fill("#email", "pr@t.az")
    pg.fill("#pass", "kohneparol1"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=8000)
    pg.select_option("#atype", "tutor"); pg.fill("#aname", "Parol hesabi")
    pg.click("#btnSetup"); pg.wait_for_selector("#btnBank", timeout=8000)
    pg.click("#btnOut")
    pg.wait_for_selector("#btnAuth", timeout=8000)
    ok(pg.locator("#btnForgot").count() == 1, "girisde 'Parolu unutmusunuz?' var")

    print("B · Bərpa linki istənilir")
    pg.click("#btnForgot")
    pg.wait_for_selector("#fgMail", timeout=4000)
    pg.fill("#fgMail", "yanlis-format")
    pg.click("#btnFg"); pg.wait_for_timeout(300)
    ok("Düzgün e-poçt" in pg.inner_text("#fgErr"), "format yoxlanisi isleyir")
    pg.fill("#fgMail", "pr@t.az")
    pg.click("#btnFg")
    pg.wait_for_selector("#authErr .ok, .ok", timeout=8000)
    ok("bərpa linki göndərildi" in pg.inner_text("#main"), "gonderildi mesaji")

    print("C · Linkdən yeni parol ekranı")
    tok = json.loads(urllib.request.urlopen(API + "/test/recovery").read())
    ok(bool(tok.get("access_token")), "berpa tokeni yarandi")
    pg.goto("about:blank")
    pg.goto(PANEL + "#access_token=" + tok["access_token"] +
            "&refresh_token=" + tok.get("refresh_token", "") + "&type=recovery")
    pg.wait_for_selector("#np1", timeout=8000)
    ok(True, "yeni parol ekrani acilir")
    pg.fill("#np1", "qisa")
    pg.fill("#np2", "qisa")
    pg.click("#btnNp"); pg.wait_for_timeout(300)
    ok("8 simvol" in pg.inner_text("#npErr"), "qisa parol reddedilir")
    pg.fill("#np1", "tezeparol22"); pg.fill("#np2", "tezeparol22")
    pg.click("#btnNp")
    pg.wait_for_selector("#btnBank", timeout=8000)
    ok(True, "parol deyisdi, panel acildi")

    print("D · Köhnə parol işləmir, yenisi işləyir")
    pg.click("#btnOut"); pg.wait_for_selector("#btnAuth", timeout=8000)
    pg.fill("#email", "pr@t.az"); pg.fill("#pass", "kohneparol1")
    pg.click("#btnAuth"); pg.wait_for_timeout(700)
    ok("yanlisdir" in pg.inner_text("#authErr").lower()
       or "yanlış" in pg.inner_text("#authErr").lower(),
       "kohne parol reddedilir", pg.inner_text("#authErr")[:40])
    pg.fill("#pass", "tezeparol22")
    pg.click("#btnAuth")
    pg.wait_for_selector("#btnBank", timeout=8000)
    ok(True, "yeni parolla giris ugurludur")

    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails))
    for f in fails: print("  - " + f)
    sys.exit(1)
print("PAROL: BUTUN YOXLAMALAR KECDI")
