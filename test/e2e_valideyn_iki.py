#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Bir valideyn - iki usaq (yol xeritesi 16, yalniz tetbiq).

Valideyn A-nin kodu ile girir, "usaq elave et" ile B-nin kodunu yazir;
ustde iki cip, kecid adi deyisir; yenilenende qalir; Cixis hamisini baglayir."""
import time
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

PANEL   = "http://127.0.0.1:8010/muellim/index.html"
PARENT  = "http://127.0.0.1:8010/valideyn/index.html"
CHROME  = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN     = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
TEST_CFG = """window.CFG = {
  SUPABASE_URL: "http://127.0.0.1:54321",
  SUPABASE_ANON_KEY: "test-anon-key",
  STUDENT_URL: "http://127.0.0.1:8010/sagird/",
  PARENT_URL:  "http://127.0.0.1:8010/valideyn/",
  SHOW_PLANS: false
};"""
BLOCK = "**://*.supabase.co/**"

fails = []
def ok(cond, label, extra=""):
    print(("  OK   " if cond else "  FAIL ") + label + (("  " + str(extra)) if extra else ""), flush=True)
    if not cond: fails.append(label)

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            return cur.fetchone() if one else cur.fetchall()

db("""
delete from public.fee_payments; delete from public.attendance; delete from public.lessons;
delete from public.mistakes; delete from public.feedback; delete from public.question_reports; delete from public.parent_sessions;
delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers; delete from public.attempts; delete from public.assignments;
delete from public.student_sessions; delete from public.students; delete from public.classes;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator'; delete from public.subscriptions;
delete from public.account_members; delete from public.accounts; delete from public.user_roles;
delete from public.profiles; delete from auth.users;""")

EMAIL = "iki%d@t.az" % int(time.time())

def page(ctx, w, h):
    pg = ctx.new_page(); pg.set_viewport_size({"width": w, "height": h})
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=TEST_CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))
    return pg

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context()
    pg = page(ctx, 430, 1000)

    print("A · Hazırlıq: müəllim, qrup, iki şagird, iki valideyn kodu")
    pg.goto(PANEL); pg.wait_for_selector("#btnAuth", timeout=15000)
    pg.click("#btnSwap")
    pg.fill("#fname", "İki Müəllim"); pg.fill("#email", EMAIL)
    pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=15000)
    pg.select_option("#atype", "tutor"); pg.fill("#aname", "İki hesabı"); pg.click("#btnSetup")
    pg.wait_for_selector("#btnGroup", timeout=15000)
    pg.fill("#gname", "4-cü sinif"); pg.click("#btnGroup")
    pg.wait_for_selector("#groups .item", timeout=15000)
    pg.click("#groups .item"); pg.wait_for_selector("#gTabs", timeout=15000)
    for nm in ("Ayan Bir", "Murad İki"):
        try: pg.wait_for_selector("#sname", state="visible", timeout=3000)
        except Exception: pg.click("#btnStuOpen")
        pg.fill("#sname", nm); pg.click("#btnStu"); pg.wait_for_timeout(500)
    pg.wait_for_function("document.querySelectorAll('.stu').length >= 2", timeout=15000)
    for nm in ("Ayan Bir", "Murad İki"):
        row = pg.locator('.stu:has-text("%s")' % nm)
        row.locator("[data-edit]").click(); pg.wait_for_selector('.stu:has-text("%s") .edit .pbox [data-pon]' % nm, timeout=15000)
        row.locator("[data-pon]").click(); pg.wait_for_selector('.stu:has-text("%s") [data-poff]' % nm, timeout=15000)
    KA = db("select parent_code c from public.students where full_name='Ayan Bir'", one=True)["c"]
    KB = db("select parent_code c from public.students where full_name='Murad İki'", one=True)["c"]
    ok(bool(KA and KB and KA != KB), "iki ayri valideyn kodu")

    print("B · Valideyn A ilə girir, B-ni əlavə edir")
    vp = page(ctx, 390, 844)
    vp.goto(PARENT); vp.wait_for_selector("#code", timeout=15000)
    vp.fill("#code", KA); vp.click("#btnIn"); vp.wait_for_selector(".who", timeout=15000)
    ok("Ayan" in vp.inner_text(".who"), "A-nin ekrani")
    ok(vp.locator("#kids").count() == 0 and vp.locator("#kidAdd").count() == 1, "tek usaqda cip yoxdur, 'usaq elave et' linki var")
    vp.click("#kidAdd"); vp.wait_for_selector("#code", timeout=8000)
    ok("İkinci uşağı" in vp.inner_text("#main") and "Əlavə et" in vp.inner_text("#btnIn"), "elave rejimi")
    vp.click("#btnAddCancel"); vp.wait_for_selector(".who", timeout=8000)
    ok("Ayan" in vp.inner_text(".who"), "legv: A-ya qayidir")
    vp.click("#kidAdd"); vp.wait_for_selector("#code", timeout=8000)
    vp.fill("#code", KB); vp.click("#btnIn"); vp.wait_for_selector("#kids", timeout=15000)
    ok(vp.locator("#kids .kid").count() == 3 and "Murad" in vp.inner_text(".who"), "iki cip + elave, B secili", vp.inner_text("#kids"))
    ok(db("select count(*) n from public.parent_sessions", one=True)["n"] == 2, "bazada iki sessiya")

    print("C · Keçid, yenilənmə, çıxış")
    vp.locator("#kids .kid", has_text="Ayan").click(); vp.wait_for_selector(".who:has-text('Ayan')", timeout=8000)
    ok("on" in (vp.locator("#kids .kid", has_text="Ayan").get_attribute("class") or ""), "A secili cip")
    vp.reload(); vp.wait_for_selector("#kids", timeout=15000)
    ok("Ayan" in vp.inner_text(".who") and vp.locator("#kids .kid").count() == 3, "yenilenende hem siyahi, hem secim qalir")
    #  A-nin sessiyasi serverde bitir -> yalniz A dusur, B qalir
    db("update public.parent_sessions set expires_at = now() - interval '1 minute' where student_id = (select id from public.students where full_name='Ayan Bir')")
    vp.reload(); vp.wait_for_selector(".who", timeout=15000)
    ok("Murad" in vp.inner_text(".who") and vp.locator("#kids").count() == 0, "A-nin sessiyasi bitdi - B ile davam", vp.inner_text(".who")[:40])
    vp.click("#btnOut"); vp.wait_for_selector("#code", timeout=15000)
    #  cixis RPC-leri arxa planda gedir - bir nece saniye gozle
    for _ in range(20):
        if db("select count(*) n from public.parent_sessions where expires_at > now()", one=True)["n"] == 0: break
        time.sleep(0.25)
    ok(db("select count(*) n from public.parent_sessions where expires_at > now()", one=True)["n"] == 0, "cixis: butun sessiyalar bagli")
    vp.screenshot(path="/tmp/iki_login.png")
    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails)); [print("  - " + f) for f in fails]; raise SystemExit(1)
print("hamisi kecdi")
