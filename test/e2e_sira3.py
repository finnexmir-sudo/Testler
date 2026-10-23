#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sıra 3 (UX yoxlaması, 23.10) — tövsiyə olunan şagirdlərə hədəfli tapşırıq, nümunə hesabda.

  A  Qrup hesabatı «Nə etməli» → generator «Yalnız zəif olanlar · N» + adlar, düymə «N şagirdə ver»;
     vərəqdə təsdiq adları sadalayır; bazada MƏHZ həmin N şagird, qrup sətri yoxdur
  B  Seçilmiş şagird testi öz panelində görür, seçilməyən görmür
  C  Tapşırıqlar siyahısı: bir sətir «N şagirdə», adlar; «×» hamısını götürür
  D  #/zm «Bu mövzudan təkrar testi yığ» → eyni siyahı (say = səhifədəki adlar); «Bütün qrup» seçimi qrupa verir
  E  Vərəq «Kimə → Bir neçə şagird seçin…» → 2 şagird
SQL tərəfi: db/test/smoke_hedefli.sql (934).
"""
import os, re, sys
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

ROOT = "http://127.0.0.1:8010/"
PANEL = ROOT + "muellim/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN = "host=/tmp port=55432 user=postgres dbname=" + os.environ.get("DB", "panel_e2e")
SHOT = os.environ.get("SHOT_DIR")
CFG = """window.CFG = {SUPABASE_URL:"http://127.0.0.1:54321",
  SUPABASE_ANON_KEY:"test-anon-key", STUDENT_URL:"http://127.0.0.1:8010/sagird/",
  PARENT_URL:"http://127.0.0.1:8010/valideyn/", SHOW_PLANS:false};"""

fails = []
def ok(cond, label, extra=""):
    print(("  OK   " if cond else "  FAIL ") + label + (("  " + str(extra)) if extra else ""), flush=True)
    if not cond: fails.append(label)

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            r = cur.fetchall(); return (r[0] if r else None) if one else r

db("""
delete from public.classes c using public.accounts a where a.id = c.account_id and a.is_demo and a.id <> app.demo_account();
delete from public.tests t using public.accounts a where a.owner_id = t.owner_id and a.is_demo and a.id <> app.demo_account();
delete from public.students s using public.accounts a where a.id = s.account_id and a.is_demo and a.id <> app.demo_account();
create temp table demo_old_e2e as select owner_id from public.accounts where is_demo and id <> app.demo_account();
delete from public.accounts where is_demo and id <> app.demo_account();
delete from auth.users u using demo_old_e2e o where u.id = o.owner_id
  and not exists (select 1 from public.accounts a2 where a2.owner_id = u.id);""")
db("delete from public.app_state where key='demo_reset'")
db("select public.rpc_demo_reset()")

def page(ctx):
    p = ctx.new_page()
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    p.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)[:160]))
    p.on("dialog", lambda d: d.accept())
    return p

def gen_hazir(pg):
    pg.wait_for_selector("#btnMake", timeout=20000)
    pg.wait_for_function("document.querySelector('#gPrev') && document.querySelector('#gPrev').innerText.indexOf('yoxlanılır') < 0 "
                         "&& document.querySelector('#gPrev').innerText.length > 5", timeout=20000)
    pg.wait_for_timeout(300)

def rows_for(test_id):
    return db("select student_id::text s from public.assignments where test_id = %s::uuid", (test_id,))

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 390, "height": 844})
    pg = page(ctx)
    pg.goto(PANEL + "#/demo"); pg.wait_for_selector("#demoBar", timeout=60000); pg.wait_for_timeout(2500)
    acc = db("select id::text i from public.accounts where is_demo and id <> app.demo_account() order by created_at desc limit 1", one=True)
    gid = db("""select c.id::text i from public.classes c where c.account_id = %s::uuid
                 and (select count(*) from public.students s where s.class_id = c.id and s.is_active) > 10
               order by c.name limit 1""", (acc["i"],), one=True)["i"]

    print("A · «Nə etməli» → yalnız zəif şagirdlərə")
    pg.goto(PANEL + "#/r/" + gid); pg.wait_for_selector("#rTodo", timeout=20000); pg.wait_for_timeout(400)
    todo_txt = pg.inner_text("#rTodo")
    mN = re.search(r"mövzusunu (\d+) şagirdə", todo_txt)
    N = int(mN.group(1)) if mN else -1
    pg.click("#btnTodo"); gen_hazir(pg)
    if SHOT:
        for w, h in ((390, 844), (1280, 900)):
            pg.set_viewport_size({"width": w, "height": h}); pg.wait_for_timeout(300)
            pg.locator("#gWho").scroll_into_view_if_needed(); pg.screenshot(path="%s/gen_kime_%d.png" % (SHOT, w))
        pg.set_viewport_size({"width": 390, "height": 844})
    who = pg.inner_text("#gWho") if pg.locator("#gWho").count() else ""
    ok(("Yalnız zəif olanlar · %d" % N) in who, "generator «Yalnız zəif olanlar · N» (N = «Nə etməli»dəki say)", "%s | N=%d" % (who.replace("\n", " "), N))
    ok(pg.inner_text("#btnMake").strip() == "Testi yığ və %d şagirdə ver" % N, "düymə alıcı sayını deyir", pg.inner_text("#btnMake"))
    pg.click("#btnMake"); pg.wait_for_selector(".pasgok", timeout=30000); pg.wait_for_timeout(500)
    tid = pg.evaluate("location.hash").split("/")[-1]
    conf = pg.inner_text(".pasgok")
    ok(("Yalnız bu %d şagird bu testi görür" % N) in conf, "vərəqdə təsdiq: «Yalnız bu N şagird…» + adlar", conf[:140])
    rows = rows_for(tid)
    ok(len(rows) == N and all(r["s"] for r in rows), "bazada MƏHZ N fərdi sətir, qrup sətri yoxdur", [r["s"] for r in rows][:3])
    if SHOT:
        pg.screenshot(path="%s/vereq_tesdiq_390.png" % SHOT)

    print("B · Seçilmiş şagird görür, seçilməyən görmür")
    sel_ids = [r["s"] for r in rows]
    ins = db("select login_code c, full_name n from public.students where id = %s::uuid", (sel_ids[0],), one=True)
    out = db("""select login_code c, full_name n from public.students where class_id = %s::uuid and is_active
                 and not (id = any(%s::uuid[])) order by full_name limit 1""", (gid, sel_ids), one=True)
    ttl = db("select title from public.tests where id = %s::uuid", (tid,), one=True)["title"]
    for kod, gozle in ((ins["c"], True), (out["c"], False)):
        sp = page(br.new_context(viewport={"width": 390, "height": 844}))
        sp.goto(ROOT + "sagird/?kod=" + kod); sp.wait_for_timeout(5000)
        has = ttl in sp.inner_text("body")
        ok(has == gozle, ("%s testi görür" if gozle else "%s (seçilməyib) testi görmür") % (ins["n"] if gozle else out["n"]), ttl)
        sp.context.close()

    print("C · Tapşırıqlar siyahısı: bir sətir, «×» hamısını götürür")
    pg.goto(PANEL + "#/a/" + gid); pg.wait_for_selector("#asgList", timeout=20000); pg.wait_for_timeout(600)
    lst = pg.inner_text("#asgList")
    ok(("%d şagirdə" % N) in lst, "siyahıda «N şagirdə» (N ayrı sətir yox)", lst.replace("\n", " ")[:120])
    nrow = pg.locator("#asgList .asg", has_text="%d şagirdə" % N).count()
    ok(nrow == 1, "həmin test siyahıda bir dəfə", nrow)
    if SHOT:
        for w, h in ((390, 844), (1280, 900)):
            pg.set_viewport_size({"width": w, "height": h}); pg.wait_for_timeout(300)
            pg.locator("#asgList").scroll_into_view_if_needed(); pg.screenshot(path="%s/tapsiriqlar_%d.png" % (SHOT, w))
        pg.set_viewport_size({"width": 390, "height": 844})
    #  «etmeyenler →» hedefli setirde: acilan sehifede bu testin yalniz N sagirdi (hele heç kim etmeyib)
    pg.locator("#asgList .asg", has_text="%d şagirdə" % N).locator("a.asgn").click()
    pg.wait_for_url(re.compile(r"#/ht/"), timeout=15000); pg.wait_for_timeout(1200)
    rws = pg.evaluate("""[...document.querySelectorAll('#main .mrow')].map(r => ({ n: (r.querySelector('b') || r).innerText.trim(), t: r.innerText }))""")
    names_sel = [db("select full_name n from public.students where id = %s::uuid", (x,), one=True)["n"] for x in sel_ids]
    #  Sətirdə test adlari yalniz birmenali olanda yazilir (pendTitles) - ona gore: secilmis HER sagird
    #  siyahidadir, secilmeyenlerin hec birinin setrinde bu testin adi yoxdur.
    adlar = [r["n"] for r in rws]
    yad = [r["n"] for r in rws if ttl in r["t"] and r["n"] not in names_sel]
    ok(all(n in adlar for n in names_sel) and not yad,
       "«etməyənlər»: seçilmiş N şagirdin hamısı var, seçilməyənlərə bu test düşmür", "%s | yad: %s" % (names_sel, yad))
    pg.go_back(); pg.wait_for_selector("#asgList", timeout=15000); pg.wait_for_timeout(500)
    pg.locator("#asgList .asg", has_text="%d şagirdə" % N).locator("[data-del]").click(); pg.wait_for_timeout(2500)
    ok(len(rows_for(tid)) == 0, "«×» N sətrin hamısını götürdü", len(rows_for(tid)))

    print("D · #/zm yolu; «Bütün qrup» seçimi")
    pg.goto(PANEL + "#/"); pg.wait_for_selector("a.mrow", timeout=20000)
    zrow = pg.locator("a.mrow", has_text="zəif gedir").first
    zrow.click(); pg.wait_for_url(re.compile(r"#/zm/"), timeout=15000); pg.wait_for_selector("#zmGen", timeout=15000)
    zn = pg.locator("#zmBox a.mrow").count()
    pg.click("#zmGen"); gen_hazir(pg)
    if zn > 1:
        ok(("Yalnız zəif olanlar · %d" % zn) in pg.inner_text("#gWho"), "#/zm-dən: siyahıdakı şagird sayı ötürülür", zn)
        pg.locator("#gWho [data-w='all']").click(); pg.wait_for_timeout(300)
        ok(pg.inner_text("#btnMake").strip() == "Testi yığ və qrupa ver" and "bütün qrupa" in pg.inner_text("#gWhoTxt"),
           "«Bütün qrup» seçiləndə düymə və mətn dəyişir")
        pg.click("#btnMake"); pg.wait_for_selector(".pasgok", timeout=30000); pg.wait_for_timeout(400)
        tid2 = pg.evaluate("location.hash").split("/")[-1]
        r2 = rows_for(tid2)
        ok(len(r2) == 1 and r2[0]["s"] is None, "«Bütün qrup» — bir qrup sətri", r2)
    else:
        ok("yalnız" in pg.inner_text("#main"), "#/zm-də 1 şagird — tək şagird yolu")

    print("E · Vərəq «Kimə → Bir neçə şagird seçin…»")
    t3 = db("""select t.id::text i from public.tests t join public.accounts a on a.owner_id = t.owner_id
                where a.id = %s::uuid and not t.is_diagnostic
                  and not exists (select 1 from public.assignments x where x.test_id = t.id and x.class_id = %s::uuid)
                order by t.created_at limit 1""", (acc["i"], gid), one=True)["i"]
    pg.goto(PANEL + "#/t/" + t3); pg.wait_for_selector("#pWho", state="attached", timeout=20000); pg.wait_for_timeout(500)
    #  test basqa qrupa verilibse forma «Başqa qrupa da ver» bolmesindedir - acilir
    pg.evaluate("() => { const d = document.querySelector('details.pother'); if (d) d.open = true; }"); pg.wait_for_timeout(200)
    pg.select_option("#pCls", gid); pg.wait_for_timeout(200)
    pg.select_option("#pWho", "__many"); pg.wait_for_timeout(200)
    boxes = pg.locator("#pWhoMany input")
    ok(boxes.count() >= 3 and pg.locator("#pWhoMany").is_visible(), "seçim qutuları açılır", boxes.count())
    boxes.nth(0).check(); boxes.nth(2).check()
    if SHOT:
        for w, h in ((390, 844), (1280, 900)):
            pg.set_viewport_size({"width": w, "height": h}); pg.wait_for_timeout(300)
            pg.locator("#pWhoMany").scroll_into_view_if_needed(); pg.screenshot(path="%s/vereq_kime_%d.png" % (SHOT, w))
        pg.set_viewport_size({"width": 390, "height": 844})
    pg.click("#btnPAsg"); pg.wait_for_selector(".pasgok", timeout=20000); pg.wait_for_timeout(400)
    r3 = db("select student_id::text s from public.assignments where test_id = %s::uuid and class_id = %s::uuid", (t3, gid))
    ok(len(r3) == 2 and all(r["s"] for r in r3) and "Yalnız bu 2 şagird" in pg.inner_text(".pasgok"),
       "2 şagirdə verildi, təsdiq «Yalnız bu 2 şagird…»", pg.inner_text(".pasgok")[:100])
    br.close()

print()
if fails:
    print("SINDI (%d):" % len(fails))
    for f in fails: print("  - " + f)
    sys.exit(1)
print("HAMISI KECDI")
