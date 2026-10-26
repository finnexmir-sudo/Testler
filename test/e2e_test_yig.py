#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Test yığ (26.10, istifadəçinin son maketi) — nümunə hesabda.

  A  İlk görünüş: «Test yığ» başlığı, iri zolaq yoxdur; Fənn · Sinif · Mövzu · Sual sayı · Kimə · «Suallara bax»;
     sual mənbəyi, çətinlik, testin adı «Əlavə seçimlər» altında (bağlı)
  B  Mövzu bir sətirdir — basanda siyahı + axtarış açılır; seçim sətirdə yazılır; çox mövzu seçmək qalır
  C  Sual sayı 5/10/15/20 = «Dəqiq sual sayı» (biri o birini yeniləyir); hovuz yoxlaması həmin sayı deyir
  D  Tövsiyə formanın ALTINDADIR və formanı doldurur (test özü yığılmır): mövzu, 10 sual, Kimə = həmin qrup
  E  «Suallara bax» testi yığır, VERMİR; vərəqdə alıcı seçili, son tarix 7 gün sonra, cəhd 1; «Testi ver» verir
  F  Qrupdan gələndə: say 5, mövzu, Kimə = həmin qrup; şagirddən gələndə: Kimə = «yalnız Ad»
  G  390 / 360: yana sürüşmə yoxdur, düymə və sahələr ≥ 44 px, başlıq 22 px
"""
import os, re, sys, datetime
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
    print(("  OK   " if cond else "  FAIL ") + label + (("  " + str(extra)) if extra != "" else ""), flush=True)
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

def hash_(pg): return pg.evaluate("location.hash")
def sw(pg): return pg.evaluate("[document.documentElement.scrollWidth, window.innerWidth]")
def sel_txt(pg, sid): return pg.evaluate("(s => s && s.selectedIndex >= 0 ? s.options[s.selectedIndex].text : '')(document.getElementById('%s'))" % sid)
def hazir(pg):
    pg.wait_for_selector("#btnMake", timeout=20000)
    pg.wait_for_function("document.querySelector('#gPrev') && document.querySelector('#gPrev').innerText.indexOf('yoxlanılır') < 0 "
                         "&& document.querySelector('#gPrev').innerText.length > 5", timeout=20000)
    pg.wait_for_timeout(400)
def gen(pg):
    pg.goto(PANEL + "#/gen"); pg.reload(); hazir(pg)

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 1280, "height": 900})
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)[:160]))
    pg.goto(PANEL + "#/demo"); pg.wait_for_selector("#demoBar", timeout=60000); pg.wait_for_timeout(2500)
    acc = db("select id::text i from public.accounts where is_demo and id <> app.demo_account() order by created_at desc limit 1", one=True)
    G = db("""select c.id::text i, c.name n from public.classes c where c.account_id = %s::uuid
                and (select count(*) from public.students s where s.class_id = c.id and s.is_active) > 10 order by c.name limit 1""", (acc["i"],), one=True)
    gid = G["i"]
    nst = db("select count(*) n from public.students where class_id = %s::uuid and is_active", (gid,), one=True)["n"]

    print("A · ilk görünüş")
    gen(pg)
    ok(pg.inner_text("#genHd h1").strip() == "Test yığ" and pg.locator("#band").is_hidden(), "başlıq «Test yığ», iri zolaq yoxdur")
    labels = [x.strip() for x in pg.locator(".genf > label, #gKim > label").all_inner_texts()]
    ok(labels == ["Fənn", "Sinif", "Mövzu", "Sual sayı", "Kimə veriləcək?"], "əsas sahələr sırası", labels)
    ok(not pg.evaluate("document.getElementById('gMore').open") and pg.locator("#gPool").is_hidden() and pg.locator("#gDiff").is_hidden() and pg.locator("#gTitle").is_hidden(),
       "sual mənbəyi, çətinlik, ad «Əlavə seçimlər» altında, bağlı")
    ok("Suallara bax" in pg.inner_text("#btnMake"), "əsas düymə «Suallara bax»")
    rec_top = pg.evaluate("(document.getElementById('gRec').getBoundingClientRect().top)")
    form_bot = pg.evaluate("document.querySelector('.genf').getBoundingClientRect().bottom")
    ok(rec_top >= form_bot, "tövsiyə formanın altındadır (formanı itələmir)", (round(form_bot), round(rec_top)))
    if SHOT: pg.screenshot(path=SHOT + "/gen_1280.png", full_page=True)

    print("B · Mövzu sətri")
    pg.select_option("#gsub", "riyaziyyat"); pg.wait_for_timeout(600)
    pg.click("#gLevs [data-l='7']"); pg.wait_for_timeout(1500)
    ok(pg.inner_text("#gTopSum").strip() == "Bütün mövzular" and pg.locator("#gTop").is_hidden(), "bağlı: «Bütün mövzular»")
    pg.click("#gTopD > summary"); pg.wait_for_timeout(300)
    chips = pg.locator("#gTop [data-t]")
    ok(chips.count() >= 3 and pg.locator("#gTq").is_visible(), "açılır: mövzu siyahısı + axtarış", chips.count())
    t1 = chips.nth(0).inner_text().strip(); chips.nth(0).click(); pg.wait_for_timeout(300)
    ok(pg.inner_text("#gTopSum").strip() == t1, "seçilən mövzu sətirdə yazılır", t1)
    chips.nth(1).click(); pg.wait_for_timeout(300)
    ok(pg.inner_text("#gTopSum").strip() == "2 mövzu seçilib", "iki mövzu: «2 mövzu seçilib»")
    chips.nth(1).click(); pg.wait_for_timeout(300); pg.click("#gTopD > summary")

    print("C · Sual sayı")
    pg.click("#gCntS [data-c='15']"); pg.wait_for_timeout(900)
    pg.evaluate("document.getElementById('gMore').open = true"); pg.wait_for_timeout(200)
    ok(pg.input_value("#gCnt") == "15" and "15 sual yığılacaq" in pg.inner_text("#gPrev"), "15 seçiləndə dəqiq say 15, hovuz «15 sual»", pg.inner_text("#gPrev"))
    pg.fill("#gCnt", "12"); pg.wait_for_timeout(900)
    ok(pg.locator("#gCntS .seg.on").count() == 0 and "12 sual" in pg.inner_text("#gMoreSum") and "12 sual yığılacaq" in pg.inner_text("#gPrev"),
       "dəqiq say 12: düymə seçilmir, «Əlavə seçimlər» sətri «12 sual» deyir", pg.inner_text("#gMoreSum"))
    pg.click("#gCntS [data-c='10']"); pg.wait_for_timeout(600)

    print("D · Tövsiyə formanı doldurur")
    gen(pg)
    rows = pg.locator("#gRec .grow2")
    if rows.count():
        r = rows.filter(has_text=G["n"]).first if rows.filter(has_text=G["n"]).count() else rows.first
        rtxt = r.inner_text(); rname = r.locator("b").inner_text().strip()
        n0 = db("select count(*) n from public.tests t join public.accounts a on a.owner_id = t.owner_id where a.id = %s::uuid", (acc["i"],), one=True)["n"]
        r.click(); pg.wait_for_selector("#gFill .ok", timeout=20000); hazir(pg)
        n1 = db("select count(*) n from public.tests t join public.accounts a on a.owner_id = t.owner_id where a.id = %s::uuid", (acc["i"],), one=True)["n"]
        ok(n1 == n0 and hash_(pg) == "#/gen", "test yığılmadı, forma dolduruldu", (n0, n1))
        ok(pg.inner_text("#gTopSum").strip() == rname and pg.locator("#gCntS .seg.on").inner_text().strip() == "10", "mövzu və 10 sual formada", pg.inner_text("#gTopSum"))
        grp = rtxt.split("\n")[1].split(" · ")[0].strip() if "\n" in rtxt else ""
        ok(sel_txt(pg, "gAsg") == grp, "Kimə = tövsiyənin qrupu", (sel_txt(pg, "gAsg"), grp))
    else:
        ok(False, "nümunədə tövsiyə var")

    print("E · Suallara bax → vərəq → Testi ver")
    gen(pg)
    pg.select_option("#gAsg", gid); pg.wait_for_timeout(300)
    ok(pg.inner_text("#gAsgSub").strip() == "Bütün qrup · %d şagird" % nst and "Baxışdan sonra göndəriləcək" in pg.inner_text("#gNote"),
       "Kimə altında «Bütün qrup · N şagird» (bazadakı say), «Baxışdan sonra göndəriləcək»", pg.inner_text("#gAsgSub"))
    pg.click("#btnMake"); pg.wait_for_selector("#btnPAsg", timeout=30000); pg.wait_for_timeout(600)
    tid = hash_(pg).split("/")[-1]
    ok(db("select count(*) n from public.assignments where test_id = %s::uuid", (tid,), one=True)["n"] == 0, "«Suallara bax» testi VERMİR")
    d7 = (datetime.date.today() + datetime.timedelta(days=7)).isoformat()
    ok(pg.locator("#pCls").input_value() == gid and pg.locator("#pWho").input_value() == "" and pg.input_value("#pDate") == d7 and pg.locator("#pTry").input_value() == "1",
       "vərəqdə: qrup seçili, bütün qrup, son tarix 7 gün sonra, 1 cəhd", (pg.input_value("#pDate"), d7))
    ok("hələ verilməyib" in pg.inner_text("#main"), "mesaj: «Test hazırdır, hələ verilməyib…»")
    pg.click("#qFold > summary"); pg.wait_for_timeout(300)
    ok(pg.locator(".paper .pq").count() == 10 and pg.locator(".paper .pq").first.is_visible(), "suallar açılır (10)", pg.locator(".paper .pq").count())
    pg.click("#btnPAsg"); pg.wait_for_selector(".pasgok", timeout=20000)
    a = db("select count(*) n, max(max_attempts) m, max(closes_at)::date d from public.assignments where test_id = %s::uuid and class_id = %s::uuid and student_id is null", (tid, gid), one=True)
    ok(a["n"] == 1 and a["m"] == 1 and str(a["d"]) in (d7, (datetime.date.today() + datetime.timedelta(days=8)).isoformat()), "«Testi ver» → qrupa, 1 cəhd, son tarix 7 gün", a)
    gen(pg)
    ok(pg.locator("#gAsg").input_value() == "", "növbəti «Test yığ» köhnə alıcını daşımır")

    print("F · qrupdan və şagirddən gələndə")
    pg.goto(PANEL + "#/g/" + gid); pg.wait_for_selector("#prepGen", timeout=20000); pg.wait_for_timeout(800)
    nx = pg.inner_text("#gkNext").strip() if pg.locator("#gkNext").count() else ""
    pg.click("#prepGen"); hazir(pg); pg.wait_for_selector("#gAsgSub", timeout=20000)
    ok(pg.locator("#gCntS .seg.on").inner_text().strip() == "5" and pg.locator("#gAsg").input_value() == gid, "qrupdan: 5 sual, Kimə = həmin qrup")
    ok(pg.inner_text("#gTopSum").strip() != "Bütün mövzular", "qrupdan: bugünkü dərsin mövzusu seçili", (pg.inner_text("#gTopSum"), nx))
    st = db("""select s.id::text i, s.full_name n from public.students s where s.class_id = %s::uuid and s.is_active
                and exists (select 1 from public.attempts a where a.student_id = s.id) order by s.full_name limit 1""", (gid,), one=True)
    pg.goto(PANEL + "#/s/%s/%s" % (st["i"], gid)); pg.wait_for_selector("#stuSon", timeout=25000); pg.wait_for_timeout(1200)
    if pg.locator("#vdTov").count():
        pg.click("#vdTov"); hazir(pg); pg.wait_for_selector("#gAsgSub", timeout=20000)
        ok(sel_txt(pg, "gAsg") == "yalnız " + st["n"] and "Yalnız bu şagird" in pg.inner_text("#gAsgSub"), "şagirddən: Kimə = «yalnız Ad»", sel_txt(pg, "gAsg"))
        pg.click("#btnMake"); pg.wait_for_selector("#btnPAsg", timeout=30000); pg.wait_for_timeout(500)
        ok(pg.locator("#pWho").input_value() == st["i"], "vərəqdə həmin şagird seçili gəlir",
           (pg.locator("#pWho").input_value(), pg.locator("#pCls").input_value() == gid, pg.evaluate("[...document.querySelectorAll('#pWho option')].map(o => o.value).indexOf('%s')" % st["i"]), pg.locator("details.pother").count()))
    else:
        print("   (bu şagirdin zəif mövzusu yoxdur — keçildi)")

    print("G · telefon 390 / 360")
    for w in (390, 360):
        pg.set_viewport_size({"width": w, "height": 844})
        gen(pg)
        s2 = sw(pg); ok(s2[0] <= s2[1], "%d: yana sürüşmə yoxdur" % w, s2)
        hh = pg.evaluate("""() => ['#btnBack', '#gsub', '#gLevs .chip', '#gTopD > summary', '#gCntS .seg', '#gMore > summary', '#gAsg', '#btnMake', '#gRec .grow2']
            .map(s => [s, document.querySelector(s)]).filter(x => x[1]).map(([s, e]) => [s, Math.round(e.getBoundingClientRect().height)])""")
        low = [x for x in hh if x[1] < 44]
        ok(len(hh) >= 8 and not low, "%d: düymə və sahələr ≥ 44 px" % w, hh)
        ok(pg.evaluate("getComputedStyle(document.querySelector('#genHd h1')).fontSize") == "22px", "%d: başlıq 22 px" % w)
        mk = pg.evaluate("document.getElementById('btnMake').getBoundingClientRect().bottom")
        ok(True, "%d: «Suallara bax» düyməsinin altı %d px (səhifə hündürlüyü %d)" % (w, mk, pg.evaluate("document.documentElement.scrollHeight")))
        if SHOT: pg.screenshot(path=SHOT + "/gen_%d.png" % w, full_page=True)
    br.close()

print("\n" + ("BUTUN YOXLAMALAR KECDI" if not fails else "SEHV (%d): %s" % (len(fails), " | ".join(fails))))
sys.exit(1 if fails else 0)
