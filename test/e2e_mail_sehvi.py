#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""E-poct yazi sehvi ipucu: «gamil.com» -> «gmail.com» (2026-09-19).

Olcu: 16 qeydiyyatin 3-unde unvan sehv yazilmisdi.  Forma MANE OLMUR,
yalniz sorusur; bir toxunusla duzelir.  Duz unvana ve is domenine
toxunmur.
"""
import time
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

PANEL  = "http://127.0.0.1:8010/muellim/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN    = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
BLOCK  = "**://*.supabase.co/**"
TEST_CFG = """window.CFG = {
  SUPABASE_URL: "http://127.0.0.1:54321",
  SUPABASE_ANON_KEY: "test-anon-key",
  STUDENT_URL: "http://127.0.0.1:8010/sagird/",
  SHOW_PLANS: false
};"""

fails = []
def ok(cond, label, extra=""):
    print(("  OK   " if cond else "  FAIL ") + label + (("  " + str(extra)) if extra else ""), flush=True)
    if not cond: fails.append(label)

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args) if args else cur.execute(sql)
        if cur.description:
            return cur.fetchone() if one else cur.fetchall()

db("""delete from public.account_members; delete from public.accounts;
      delete from public.user_roles; delete from public.profiles; delete from auth.users;""")

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    pg = br.new_context().new_page()
    pg.set_viewport_size({"width": 390, "height": 844})
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=TEST_CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))

    pg.goto(PANEL); pg.wait_for_selector("#btnAuth", timeout=15000)
    pg.click("#btnSwap"); pg.wait_for_selector("#fname", timeout=8000)

    print("A · Səhv domen → ipucu çıxır")
    pg.fill("#email", "aliyevasevinc1973il@gamil.com")
    pg.click("#pass")          # blur
    pg.wait_for_selector(".mtip", timeout=5000)
    ok("gmail.com" in pg.inner_text(".mtip"), "ipucu duz domeni teklif edir",
       pg.inner_text(".mtip").replace("\n", " "))
    ok(pg.locator("#mtipGo").count() == 1, "teklif klik olunandir")

    print("B · Bir toxunuşla düzəlir")
    pg.click("#mtipGo"); pg.wait_for_timeout(250)
    ok(pg.input_value("#email") == "aliyevasevinc1973il@gmail.com",
       "unvan duzeldi", pg.input_value("#email"))
    ok(pg.locator(".mtip").count() == 0, "ipucu itdi")

    print("C · Düz ünvanda və iş domenində ipucu YOXDUR")
    for em in ["muellim@gmail.com", "a@bil10.az", "x@sabah.edu.az", "z@protonmail.com",
               "q@inbox.ru", "w@box.az"]:
        pg.fill("#email", em); pg.click("#pass"); pg.wait_for_timeout(180)
        ok(pg.locator(".mtip").count() == 0, "sakit: " + em)

    print("D · Enter ilə birbaşa göndərəndə BİR dəfə saxlayır")
    pg.fill("#fname", "Test Müəllim")
    pg.fill("#email", "necefovadeniz78@gemail.com")
    pg.fill("#pass", "parol1234")
    pg.click("#btnAuth"); pg.wait_for_timeout(600)
    ok(pg.locator(".mtip").count() == 1, "birinci toxunusda ipucu cixdi, gonderilmedi")
    ok(db("select count(*) n from auth.users", one=True)["n"] == 0, "bazada hesab yaranmadi")

    print("E · İkinci toxunuşda MANE OLMUR — istifadəçi qərar verir")
    pg.click("#btnAuth"); pg.wait_for_timeout(1500)
    ok(db("select count(*) n from auth.users where email = 'necefovadeniz78@gemail.com'",
          one=True)["n"] == 1, "ikinci toxunusda hesab yarandi (mane deyil)")

    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails)); [print("  - " + f) for f in fails]; raise SystemExit(1)
print("HAMISI KECDI")
