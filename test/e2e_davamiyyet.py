#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Defter: davamiyyet ve odenis - ucdan-uca (db/130).

Muellim "Ders oldu" basir, birini gelmeyib isareleyir, birine "Odenilib"
qoyur; ay kecidi; valideyn oz ekraninda istirak ve odenisi gorur."""
import time, datetime
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

EMAIL = "davam%d@t.az" % int(time.time())

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
    pg.on("dialog", lambda d: d.accept())

    print("A · Hazırlıq: müəllim, qrup, 3 şagird, valideyn kodu")
    pg.goto(PANEL); pg.wait_for_selector("#btnAuth", timeout=15000)
    pg.click("#btnSwap")
    pg.fill("#fname", "Dəftər Müəllim"); pg.fill("#email", EMAIL)
    pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=15000)
    pg.select_option("#atype", "tutor"); pg.fill("#aname", "Dəftər hesabı"); pg.click("#btnSetup")
    pg.wait_for_selector("#btnGroup", timeout=15000)
    pg.fill("#gname", "5-ci sinif"); pg.click("#btnGroup")
    pg.wait_for_selector("#groups .item", timeout=15000)
    pg.click("#groups .item"); pg.wait_for_selector("#gTabs", timeout=15000)
    for nm in ("Ayan Bir", "Murad İki", "Leyla Üç"):
        try: pg.wait_for_selector("#sname", state="visible", timeout=3000)
        except Exception: pg.click("#btnStuOpen")
        pg.fill("#sname", nm); pg.click("#btnStu"); pg.wait_for_timeout(500)
    pg.wait_for_function("document.querySelectorAll('.stu').length >= 3", timeout=15000)
    GID = db("select id::text i from public.classes limit 1", one=True)["i"]
    row = pg.locator('.stu:has-text("Ayan Bir")')
    row.locator("[data-edit]").click(); pg.wait_for_selector(".edit .pbox [data-pon]", timeout=15000)
    row.locator("[data-pon]").click(); pg.wait_for_selector('.stu:has-text("Ayan Bir") [data-poff]', timeout=15000)
    PKOD = db("select parent_code c from public.students where full_name='Ayan Bir'", one=True)["c"]

    print("B · Dəftər sekməsi: «Dərs oldu», Murad gəlməyib")
    pg.click("#gTabs [data-v='d']"); pg.wait_for_selector("#ledOpen", timeout=15000)
    #  sekme acilanda defter yeniden yuklenir (sagirdler tezece elave olunub)
    pg.wait_for_function("document.querySelector('.lhead') && document.querySelector('.lhead').innerText.indexOf('0/3') >= 0", timeout=8000)
    hd = pg.inner_text(".lhead").replace("\n", " ")
    ok("0 dərs" in hd and "ödənilib 0/3" in hd, "bos ay basligi", hd)
    ok(pg.locator(".lrow").count() == 3 and "dərs yoxdur" in pg.inner_text("#ledgerBox"), "3 sagird, ders yoxdur")
    pg.click("#ledOpen"); pg.wait_for_selector("#ledChips [data-st]", timeout=8000)
    ok(pg.locator("#ledChips .lch.on").count() == 3, "hamisi secili gelir")
    pg.locator("#ledChips [data-st]", has_text="Murad").click()
    ok(pg.locator("#ledChips .lch.on").count() == 2, "Murad sondu")
    pg.click("#ledSave"); pg.wait_for_selector("#ledEdit", timeout=8000)
    ok("2 gəlib" in pg.inner_text("#ledToday") and "1 gəlməyib" in pg.inner_text("#ledToday"), "bu gun qeyd olundu", pg.inner_text("#ledToday")[:60])
    ok("1/1 dərs" in pg.locator('.lrow:has-text("Ayan")').inner_text() and "0/1 dərs" in pg.locator('.lrow:has-text("Murad")').inner_text(), "setirlerde istirak")
    ls = db("select count(*) n from public.lessons", one=True)["n"]; at = db("select count(*) n from public.attendance where present", one=True)["n"]
    ok(ls == 1 and at == 2, "bazada 1 ders, 2 istirak")

    print("C · Düzəlt: Murad da gəlib; ödəniş toggle")
    pg.click("#ledEdit"); pg.wait_for_selector("#ledChips", timeout=8000)
    ok(pg.locator("#ledChips .lch.on").count() == 2, "duzeltde evvelki secim gelir")
    pg.locator("#ledChips [data-st]", has_text="Murad").click(); pg.click("#ledSave"); pg.wait_for_selector("#ledEdit", timeout=8000)
    ok("3 gəlib" in pg.inner_text("#ledToday"), "duzelis: 3 gelib")
    pg.locator('.lrow:has-text("Ayan") [data-pay]').click(); pg.wait_for_selector('.lrow:has-text("Ayan") .pay.on', timeout=8000)
    ok("Ödənilib" in pg.locator('.lrow:has-text("Ayan") .pay').inner_text() and "ödənilib 1/3" in pg.inner_text(".lhead"), "Ayan odenilib, basliq 1/3")
    ok(db("select paid from public.fee_payments", one=True)["paid"] is True, "bazada odenis")
    pg.click("#ledPrev"); pg.wait_for_function("document.querySelector('.lhead') && document.querySelector('.lhead').innerText.indexOf('0 dərs') >= 0", timeout=8000)
    ok(pg.locator("#ledOpen").count() == 0 and pg.locator("#ledNext").is_enabled(), "kecen ay: bu gun karti yoxdur, ireli acıqdir")
    pg.click("#ledNext"); pg.wait_for_selector("#ledEdit", timeout=8000)
    ok(True, "bu aya qayitdi")

    print("D · Valideyn: iştirak və ödəniş")
    vp = page(ctx, 390, 844)
    vp.goto(PARENT); vp.wait_for_selector("#code", timeout=15000)
    vp.fill("#code", PKOD); vp.click("#btnIn"); vp.wait_for_selector(".att", timeout=15000)
    t = vp.inner_text(".att").replace("\n", " ")
    ok("1 / 1" in t and "iştirak edib" in t, "valideyn: 1/1 istirak", t[:60])
    ok("ödənişi: edilib" in t, "valideyn: odenis edilib", t)
    pg.locator('.lrow:has-text("Ayan") [data-pay]').click(); pg.wait_for_selector('.lrow:has-text("Ayan") .pay:not(.on)', timeout=8000)
    vp.reload(); vp.wait_for_selector(".att", timeout=15000)
    ok("gözlənilir" in vp.inner_text(".att"), "geri alanda valideynde 'gozlenilir'")
    pg.locator("#ledgerBox").screenshot(path="/tmp/davam_defter.png")
    vp.locator(".att").screenshot(path="/tmp/davam_val.png")

    print("E · Dərsi silmək")
    pg.locator("details.filt summary", has_text="Dərslər").click(); pg.wait_for_selector("[data-ldel]", timeout=8000)
    pg.locator("[data-ldel]").first.click(); pg.wait_for_selector("#ledOpen", timeout=8000)
    ok(db("select count(*) n from public.lessons", one=True)["n"] == 0, "ders silindi")
    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails)); [print("  - " + f) for f in fails]; raise SystemExit(1)
print("hamisi kecdi")
