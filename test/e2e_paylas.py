#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""214: «Dostuna at» - ucdan-uca.

A  sagird testi isleyir -> netice ekraninda «Dostuna at» duymesi
B  link duzelir, duyme veziyyetini deyir
C  DOST linki acir (temiz brauzer, giris yoxdur) - duz variant getmir
D  cavab: duz variant SONRA gorunur, izah cixir, «muellimine de» cumlesi
E  vaxti bitmis / yad link - sakit ekran
F  REQRESSIYA: «Sualda səhv var?» axini pozulmayib (qacts deyisdi)
"""
import time
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

STUDENT = "http://127.0.0.1:8010/sagird/index.html"
PANEL   = "http://127.0.0.1:8010/muellim/index.html"
SHARE   = "http://127.0.0.1:8010/s/index.html"
CHROME  = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN     = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
BLOCK   = "**://*.supabase.co/**"
TEST_CFG = """window.CFG = {
  SUPABASE_URL: "http://127.0.0.1:54321",
  SUPABASE_ANON_KEY: "test-anon-key",
  STUDENT_URL: "http://127.0.0.1:8010/sagird/",
  PARENT_URL:  "http://127.0.0.1:8010/valideyn/",
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

db("""
delete from public.shares;      delete from public.daily_packs;
delete from public.mistakes;    delete from public.question_reports;
delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments; delete from public.student_sessions;
delete from public.parent_sessions; delete from public.students;
delete from public.classes;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator'; delete from public.subscriptions;
delete from public.account_members; delete from public.accounts; delete from public.user_roles;
delete from public.profiles; delete from auth.users;""")

EMAIL = "paylas%d@t.az" % int(time.time())

def page(ctx, w, h, share_ok=False):
    pg = ctx.new_page(); pg.set_viewport_size({"width": w, "height": h})
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=TEST_CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))
    if not share_ok:
        #  masaustu yolu: navigator.share yoxdur -> «Link kopyalandi»
        pg.add_init_script("try { delete navigator.share; } catch (e) {}")
    return pg

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(permissions=["clipboard-read", "clipboard-write"])
    pg = page(ctx, 1280, 900)

    print("A · Hazırlıq: müəllim, qrup, şagird, tapşırıq")
    pg.goto(PANEL); pg.wait_for_selector("#btnAuth", timeout=15000)
    pg.click("#btnSwap")
    pg.fill("#fname", "Paylaş Müəllim"); pg.fill("#email", EMAIL)
    pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=15000)
    pg.select_option("#atype", "tutor"); pg.fill("#aname", "Paylaş hesabı"); pg.click("#btnSetup")
    pg.wait_for_selector("#btnGroup", timeout=15000)
    pg.fill("#gname", "3-cü sinif"); pg.select_option("#glevel", "3"); pg.click("#btnGroup")
    pg.wait_for_selector("#groups .gcard", timeout=15000)
    pg.click("#groups .gcard"); pg.wait_for_selector("#gTabs", timeout=15000)
    try: pg.wait_for_selector("#sname", state="visible", timeout=3000)
    except Exception: pg.click("#btnStuOpen")
    pg.fill("#sname", "Aysu Məmmədova"); pg.click("#btnStu"); pg.wait_for_selector(".stu", timeout=15000)
    GID  = db("select id::text i from public.classes limit 1", one=True)["i"]
    CODE = db("select login_code c from public.students limit 1", one=True)["c"]
    pg.goto(PANEL + "#/a/" + GID)
    pg.wait_for_function("document.querySelectorAll('#aTest option').length > 0", timeout=15000)
    lbl = next(o for o in pg.locator("#aTest option").all_inner_texts() if "Vurma cədvəli" in o)
    pg.click("#aList [data-t='" + pg.evaluate(
        "l => Array.from(document.querySelectorAll('#aTest option')).filter(o => o.textContent === l)[0].value", lbl) + "']")
    pg.click("#btnAsg"); pg.wait_for_selector(".asg", timeout=15000)

    print("B · Şagird testi işləyir → nəticə ekranında «Dostuna at»")
    sp = page(ctx, 390, 844)
    sp.goto(STUDENT); sp.wait_for_selector("#btnIn", timeout=15000)
    sp.fill("#code", CODE); sp.click("#btnIn"); sp.wait_for_selector(".test", timeout=15000)
    sp.locator(".test.asg").first.click(); sp.wait_for_selector(".opt", timeout=15000)
    while True:
        sp.locator(".opt").first.click(); sp.wait_for_timeout(100)
        if sp.locator("#btnNext").count():
            sp.click("#btnNext"); sp.wait_for_timeout(120)
        else:
            sp.once("dialog", lambda d: d.accept()); sp.click("#btnFinish"); break
    sp.wait_for_selector(".ring", timeout=15000); sp.wait_for_timeout(500)
    ok(sp.locator("[data-sq]").count() >= 1, "netice ekraninda «Dostuna at» var",
       sp.locator("[data-sq]").count())
    #  duz cavab setri yigilmis <details>-dedir - acilanda da duyme baglanmalidir
    if sp.locator("#main details").count():
        n_evvel = sp.locator("[data-sq]").count()
        sp.evaluate("() => { document.querySelector('#main details').open = true; }")
        sp.wait_for_timeout(300)
        ok(sp.locator("[data-sq][data-sb]").count() == sp.locator("[data-sq]").count(),
           "yigilmis bolme acilanda yeni duymeler de baglanir",
           (n_evvel, sp.locator("[data-sq]").count()))

    sp.locator("[data-sq]").first.click()
    sp.wait_for_timeout(1500)
    ok(db("select count(*) n from public.shares", one=True)["n"] == 1, "bazada bir link yarandi")
    ok("kopyaland" in sp.locator("[data-sq]").first.inner_text(),
       "duyme veziyyetini deyir", sp.locator("[data-sq]").first.inner_text())
    K = db("select k from public.shares limit 1", one=True)["k"]
    ok(len(K) == 12, "acar 12 simvol", K)

    print("C · Dost linki açır — giriş yoxdur, düz variant getmir")
    fctx = br.new_context()          # TEMIZ brauzer: sessiya yoxdur
    fp = fctx.new_page()
    fp.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=TEST_CFG))
    fp.on("pageerror", lambda e: fails.append("JS xetasi (dost): " + str(e)))
    fp.route(BLOCK, lambda r: (fails.append("XARICI SORGU (dost): " + r.request.url), r.abort()))
    fp.goto(SHARE + "?k=" + K); fp.wait_for_selector(".sopt", timeout=15000)
    html = fp.content()
    ok("is_correct" not in html, "duz variant client-e getmir")
    ok("Məmmədova" not in html, "sagirdin TAM ADI getmir")
    ok("Aysu M." in fp.inner_text(".sfrom"), "gorunen ad var", fp.inner_text(".sfrom"))
    ok(fp.locator(".sopt").count() >= 2, "variantlar gelir", fp.locator(".sopt").count())
    ok(fp.evaluate("() => localStorage.length") == 0, "dostun brauzerinde hec ne saxlanmir")

    print("D · Cavab → düz variant sonra görünür + «müəllimine de» cümləsi")
    fp.locator(".sopt").first.click()
    fp.wait_for_selector(".spitch", timeout=15000)
    ok(fp.locator(".sopt.ok2").count() >= 1, "duz variant CAVABDAN SONRA isarelenir")
    ok(fp.locator(".sfb").count() == 1, "cavab reaksiyasi var", fp.inner_text(".sfb")[:60])
    pit = fp.inner_text(".spitch").replace("\n", " ")
    ok("Müəllimin bunu sinfə qura bilər" in pit, "tekrarlana bilen cumle var", pit[:80])
    ok("pulsuzdur" in pit, "sagirde pulsuz oldugu yazilir")
    fp.click("#goBil"); fp.wait_for_timeout(700)
    ok(db("select clicks from public.shares limit 1", one=True)["clicks"] == 1, "bil10.az kliki sayilir")
    fctx.close()

    print("E · Vaxtı bitmiş və yad link")
    db("update public.shares set expires_at = now() - interval '1 day'")
    f2 = br.new_context(); fp2 = f2.new_page()
    fp2.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=TEST_CFG))
    fp2.on("pageerror", lambda e: fails.append("JS xetasi (vaxt): " + str(e)))
    fp2.goto(SHARE + "?k=" + K); fp2.wait_for_selector(".serr", timeout=15000)
    ok("vaxtı bitib" in fp2.inner_text(".serr"), "vaxti bitmis link sakit izah verir",
       fp2.inner_text(".serr").replace("\n", " ")[:60])
    fp2.goto(SHARE + "?k=yoxbelekey1"); fp2.wait_for_selector(".serr", timeout=15000)
    ok("tapılmadı" in fp2.inner_text(".serr"), "yad acar sakit izah verir")
    fp2.goto(SHARE); fp2.wait_for_selector(".serr", timeout=15000)
    ok("tam deyil" in fp2.inner_text(".serr"), "acarsiz acilis")
    f2.close()

    print("F · Reqressiya: «Sualda səhv var?» axını pozulmayıb")
    sp.goto(STUDENT); sp.wait_for_selector(".test", timeout=15000)
    sp.locator(".test.asg").first.click()
    sp.wait_for_selector(".ring, .opt", timeout=15000)
    if sp.locator(".opt").count():        # yeniden cehd acildisa
        while True:
            sp.locator(".opt").first.click(); sp.wait_for_timeout(100)
            if sp.locator("#btnNext").count():
                sp.click("#btnNext"); sp.wait_for_timeout(120)
            else:
                sp.once("dialog", lambda d: d.accept()); sp.click("#btnFinish"); break
        sp.wait_for_selector(".ring", timeout=15000)
    sp.wait_for_timeout(500)
    ok(sp.locator("[data-rq]").count() >= 1, "«Sualda səhv var?» duymesi qalib",
       sp.locator("[data-rq]").count())
    sp.locator("[data-rq]").first.click()
    sp.wait_for_selector(".rfrm", timeout=10000)
    ok(sp.locator(".rfrm select").count() == 1, "bildiris formasi acilir")
    sp.locator(".rfrm .btn").first.click()
    sp.wait_for_timeout(900)
    ok(db("select count(*) n from public.question_reports", one=True)["n"] >= 1,
       "bildiris bazaya dusur")

    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails)); [print("  - " + f) for f in fails]; raise SystemExit(1)
print("HAMISI KECDI")
