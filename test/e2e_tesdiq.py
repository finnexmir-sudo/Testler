#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Poct linkinden qayidis: qeydiyyat tesdiqi, kohnelmis link, berpa.

Niye bu test var (2026-09-11): panel hash-de YALNIZ «type=recovery»
tutrudu.  Qeydiyyat tesdiqi «type=signup» ile gelir - onu gormezden
gelirdik.  Muellim mektubdaki linke basirdi, Supabase sessiyani acirdi,
biz onu tullayirdiq ve qarsisina YENIDEN giris formasi cixirdi.  Hemin
gun bir muellim mehz bele itdi: bazada tesdiq var, hesab yoxdur.
Bu axin GORUNMEYEN axindir - elle yoxlamaq ucun her defe heqiqi mektub
lazimdir, ona gore testi var.

Yoxlanir:
  A  tesdiq linki (type=signup) adami ICERI salir - qurasdirma ekrani
  B  tokenler unvanda qalmir
  C  kohnelmis link sakitce udulmur - oxunan xeberdarliq verilir
  D  berpa linki (type=recovery) evvelki kimi isleyir
  E  kok sehifeye dusen link muellim panele oturulur
"""
import json, sys, urllib.request
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

ROOT   = "http://127.0.0.1:8010/"
PANEL  = ROOT + "muellim/index.html"
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

def db(sql, args=None):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())

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

def jeton(mail):
    """Mock-dan hemin poct ucun sessiya jetonlari - heqiqi mektubdaki
    linkde gelenlerin eynisi (Supabase tesdiq ve berpa ucun EYNI
    sekilli hash gonderir)."""
    urllib.request.urlopen(urllib.request.Request(
        API + "/auth/v1/recover",
        data=json.dumps({"email": mail}).encode(),
        headers={"Content-Type": "application/json", "apikey": "test-anon-key"}))
    return json.loads(urllib.request.urlopen(API + "/test/recovery").read())

with sync_playwright() as pw:
    br  = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 1280, "height": 900})
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=TEST_CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))

    print("A · Hesabsız müəllim yaranır")
    pg.goto(PANEL); pg.wait_for_timeout(400)
    pg.click("#btnSwap")
    pg.fill("#fname", "Tesdiq Muellim"); pg.fill("#email", "ts@t.az")
    pg.fill("#pass", "tesdiqparol1"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=8000)
    ok(True, "qeydiyyat qurasdirma ekranina getirdi")
    pg.click("#btnOut")
    pg.wait_for_selector("#btnAuth", timeout=8000)

    print("B · Təsdiq linki (type=signup) içəri salır")
    t = jeton("ts@t.az")
    pg.goto("about:blank")
    pg.goto(PANEL + "#access_token=" + t["access_token"] +
            "&expires_in=3600&refresh_token=" + t.get("refresh_token", "") +
            "&token_type=bearer&type=signup")
    pg.wait_for_selector("#btnSetup", timeout=8000)
    ok(True, "tesdiq linki qurasdirma ekranini acdi")
    ok(pg.locator("#btnAuth").count() == 0, "giris formasi TEKRAR cixmir")
    ok("access_token" not in pg.url, "tokenler unvanda qalmir", pg.url)

    print("C · Köhnəlmiş link susmur")
    pg.goto("about:blank")
    pg.goto(PANEL + "#error=access_denied&error_code=otp_expired"
            "&error_description=Email+link+is+invalid+or+has+expired")
    pg.wait_for_selector("#btnAuth", timeout=8000)
    mtn = pg.inner_text("#main")
    ok("vaxtı keçib" in mtn, "vaxti kecmis link izah olunur")
    ok("Parolu unutmusunuz?" in mtn, "cixis yolu gosterilir")
    ok("error" not in pg.url, "xeta unvanda qalmir", pg.url)

    print("D · Bərpa linki (type=recovery) əvvəlki kimi")
    t = jeton("ts@t.az")
    pg.goto("about:blank")
    pg.goto(PANEL + "#access_token=" + t["access_token"] +
            "&expires_in=3600&refresh_token=" + t.get("refresh_token", "") +
            "&type=recovery")
    pg.wait_for_selector("#np1", timeout=8000)
    ok(True, "yeni parol ekrani acilir")

    print("E · Kök səhifəyə düşən link panelə ötürülür")
    t = jeton("ts@t.az")
    pg.goto("about:blank")
    pg.goto(ROOT + "#access_token=" + t["access_token"] +
            "&expires_in=3600&refresh_token=" + t.get("refresh_token", "") +
            "&type=signup")
    pg.wait_for_selector("#btnSetup", timeout=8000)
    ok("/muellim/" in pg.url, "kok sehifeden panele kecdi", pg.url)
    ok(True, "qurasdirma ekrani acildi")

    print("F · Adi ünvan toxunulmaz qalır")
    pg.goto("about:blank")
    pg.goto(ROOT)
    pg.wait_for_timeout(500)
    ok("/muellim/" not in pg.url, "tokensiz ana sehife yerinde qalir", pg.url)

    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails))
    for f in fails: print("  - " + f)
    sys.exit(1)
print("TESDIQ: BUTUN YOXLAMALAR KECDI")
