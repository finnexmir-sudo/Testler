#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Numune (demo) hesab - ucdan-uca (db/136).

Ana sehifeden uc giris: "Muellim kimi bax" (anonim giris + oz nusxe,
zolaq, 2 qrup, "Bu gunun dersi"nde etmeyenler), "Sagird kimi bax"
(?kod=DEMO0001 avtomatik giris), "Valideyn kimi bax" (?kod=VDEMO001)."""
import time
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

ROOT    = "http://127.0.0.1:8010/"
PANEL   = ROOT + "muellim/index.html"
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

#  evvelki isden qalan anonim nusxeler (24 saatdan teze - sifirlama silmir)
db("""
delete from public.classes c using public.accounts a where a.id = c.account_id and a.is_demo and a.id <> app.demo_account();
delete from public.tests t using public.accounts a where a.owner_id = t.owner_id and a.is_demo and a.id <> app.demo_account();
delete from public.students s using public.accounts a where a.id = s.account_id and a.is_demo and a.id <> app.demo_account();
create temp table demo_old_e2e as select owner_id from public.accounts where is_demo and id <> app.demo_account();
delete from public.accounts where is_demo and id <> app.demo_account();
delete from auth.users u using demo_old_e2e o where u.id = o.owner_id
  and not exists (select 1 from public.accounts a2 where a2.owner_id = u.id);""")
#  paylasilan numune: is axininin etdiyini burada biz edirik
db("delete from public.app_state where key='demo_reset'")
db("select public.rpc_demo_reset()")

def page(ctx, w, h):
    pg = ctx.new_page(); pg.set_viewport_size({"width": w, "height": h})
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=TEST_CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))
    pg.on("dialog", lambda d: (fails.append("DIALOQ: " + d.message), d.dismiss()))
    return pg

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context()
    pg = page(ctx, 430, 1000)

    print("A · Ana səhifədə üç nümunə düyməsi")
    pg.goto(ROOT + "index.html"); pg.wait_for_selector("#demo", timeout=15000)
    links = pg.locator("#demo a").evaluate_all("els => els.map(e => e.getAttribute('href'))")
    ok(links == ["muellim/#/demo", "sagird/?kod=DEMO0001", "valideyn/?kod=VDEMO001"], "uc link", links)

    print("B · Müəllim kimi bax: anonim giriş, öz nüsxə, zolaq")
    pg.click("#demo a[href='muellim/#/demo']")
    pg.wait_for_selector("#demoBar", timeout=40000)
    bar = pg.inner_text("#demoBar")
    ok("Nümunə hesab" in bar and "24 saat" in bar, "numune zolagi", bar[:80])
    codes = pg.locator("#demoBar code").all_inner_texts()
    ok(len(codes) == 2 and codes[0] != "DEMO0001" and len(codes[0]) == 8 and codes[1].startswith("V"), "oz nusxenin kodlari (paylasilan deyil)", codes)
    ok(db("select count(*) n from public.accounts where is_demo", one=True)["n"] == 2, "paylasilan + nusxe = 2 numune hesab")
    pg.wait_for_selector("#groups .item", timeout=15000)
    ok(pg.locator("#groups .item").count() == 2, "iki qrup", pg.locator("#groups .item").count())
    ok("Nümunə Müəllim" in pg.inner_text("#topWho"), "ad: Numune Muellim")
    pg.locator("#groups .item", has_text="3-cü sinif").first.click(); pg.wait_for_selector("#gTabs", timeout=15000)
    pg.wait_for_selector("#prep .prep", timeout=20000)
    #  CSS boyuk herf edir - textContent oxunur
    pt = pg.evaluate("document.querySelector('#prep').textContent")
    ok("Etməyənlər" in pt and "4/12" in pt, "bu gunun dersi: 4 nefer etmeyib", pt[:160].replace("\n", " "))
    ok(pg.locator(".stu").count() == 12, "12 sagird")
    pg.click("#gTabs [data-v='p']"); pg.wait_for_selector(".plan .plhead", timeout=15000)
    ok("9 /" in pg.inner_text(".plan .plhead"), "planda 9 movzu kecilib", pg.inner_text(".plan .plhead"))
    #  zolaq her ekranda qalir
    pg.goto(PANEL + "#/"); pg.reload(); pg.wait_for_selector("#demoBar", timeout=15000)
    ok(pg.locator("#demoBar").count() == 1, "yenilenende zolaq qalir")
    #  "Oz hesabimi ac" -> qeydiyyat ekrani
    pg.click("#demoOwn"); pg.wait_for_selector("#btnAuth", timeout=15000)
    ok(pg.locator("#demoBar").count() == 0 and pg.locator("#fname").count() == 1, "oz hesab: qeydiyyat ekrani, zolaq yoxdur")

    print("C · Şagird kimi bax: ?kod= ilə avtomatik giriş")
    sp = page(ctx, 390, 844)
    sp.goto(ROOT + "sagird/?kod=DEMO0001"); sp.wait_for_selector(".test", timeout=20000)
    ok("Ayan" in sp.inner_text("body"), "sagird girdi (Ayan)", sp.inner_text("#topTitle") if sp.locator("#topTitle").count() else "")
    ok(sp.locator(".test.asg").count() == 1, "bir acıq tapsiriq")
    ok("kod=" not in sp.url, "unvandan kod silinib")
    st = sp.evaluate("document.body.textContent")
    ok("Zəif mövzular" in st and "Səhv dəftəri" in st and "Mövzu məşqi" in st, "zeif movzu, sehv defteri, movzu mesqi kartlari")

    print("D · Valideyn kimi bax")
    vp = page(ctx, 390, 844)
    vp.goto(ROOT + "valideyn/?kod=VDEMO001"); vp.wait_for_selector(".who", timeout=20000)
    vt = vp.evaluate("document.body.textContent")
    ok("Ayan" in vt and "Davamiyyət" in vt and "Mövzu məşqi" in vt, "valideyn ekrani: usaq, davamiyyet, movzu mesqi", vt[:120].replace("\n", " "))

    print("E · Sıfırlama: paylaşılan yenidən qurulur, kodlar eyni")
    db("update public.app_state set val = jsonb_build_object('at', now() - interval '1 hour') where key='demo_reset'")
    r = db("select public.rpc_demo_reset() v", one=True)["v"]
    ok(r["student_code"] == "DEMO0001" and r["deleted_copies"] == 0, "sifirlama: eyni kod, teze nusxe silinmir", r)
    ok(db("select count(*) n from public.students where login_code='DEMO0001'", one=True)["n"] == 1, "DEMO0001 tekdir")

    br.close()

print()
if fails:
    print("XETA:", len(fails)); [print("  -", f) for f in fails]; raise SystemExit(1)
print("hamisi kecdi")
