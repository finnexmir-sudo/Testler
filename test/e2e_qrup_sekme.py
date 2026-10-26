#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Qrup səhifəsi (26.10, istifadəçinin son maketi) — nümunə hesabda.

  A  Başlıq hər sekmədə eyni: «Geri · Qruplar / ad», ad, «sinif · N şagird», «+ Tapşırıq ver», dişli (ayarlar);
     alt xətli sekmələr: kompüterdə 6, telefonda 4 + «Daha» (Dərs planı, Dəftər); iri zolaq yoxdur
  B  Sekmə keçidi tarixçəyə yazılmır: 4 sekmədən sonra «Geri» və brauzer geri → Qruplar
  C  Bugünkü dərs: mövzu, «fəsil · dərs N / M» (faiz yoxdur), «Davamiyyət» → Dəftər, «5 suallıq test ver» →
     generator (5 sual, bu qrupa); xəbərdarlıq sətirləri #/ht ilə eyni say
  D  Son tapşırıqlar: «done / tot» Tapşırıqlar sətri ilə eyni; «Hamısına bax» → Tapşırıqlar sekməsi;
     nəticə və zəif mövzu bu səhifədə YOXDUR — qeyd sətri Hesabata aparır
  E  «+ Tapşırıq ver» menyusu: Test ver / Ev tapşırığı yaz; dişli → ayarlar
  F  Boş qrup; 360/390: yana sürüşmə yoxdur, düymə ≥ 44 px, başlıq kiçilməyib
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

def page(ctx):
    p = ctx.new_page()
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    p.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)[:160]))
    p.on("dialog", lambda d: d.accept())
    return p

def icmal(pg, gid):
    pg.goto(PANEL + "#/g/" + gid)
    pg.wait_for_function("document.querySelector('#gkAsg .ykh') && document.querySelector('#gkDers .ykh') && document.querySelector('#gMeta').textContent.length > 3", timeout=20000)
    pg.wait_for_timeout(300)
def hash_(pg): return pg.evaluate("location.hash")
def aktiv(pg):
    return pg.evaluate("""() => { const a = document.querySelector('#gSek .gtab.on'); return a ? a.textContent.trim() : ''; }""")
def sw(pg): return pg.evaluate("[document.documentElement.scrollWidth, window.innerWidth]")

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 1280, "height": 900})
    pg = page(ctx)
    pg.goto(PANEL + "#/demo"); pg.wait_for_selector("#demoBar", timeout=60000); pg.wait_for_timeout(2500)
    acc = db("select id::text i, owner_id::text o from public.accounts where is_demo and id <> app.demo_account() order by created_at desc limit 1", one=True)
    gid = db("""select c.id::text i from public.classes c where c.account_id = %s::uuid
                 and (select count(*) from public.students s where s.class_id = c.id and s.is_active) > 10
               order by c.name limit 1""", (acc["i"],), one=True)["i"]
    G = db("""select c.name n, l.name l, (select count(*) from public.students s where s.class_id = c.id and s.is_active) k
                from public.classes c join public.levels l on l.id = c.level_id where c.id = %s::uuid""", (gid,), one=True)

    print("A · başlıq və sekmələr (1280)")
    icmal(pg, gid)
    ok(pg.inner_text("#gName").strip() == G["n"] and pg.inner_text("#gCrumb").strip() == G["n"], "ad və yol", pg.inner_text("#gName"))
    ok(pg.inner_text("#gMeta").strip() == "%s · %d şagird" % (G["l"], G["k"]), "«sinif · N şagird» bazadakı ilə eyni", pg.inner_text("#gMeta"))
    ok(pg.locator("#band").is_hidden(), "iri zolaq yoxdur")
    vis = pg.evaluate("""() => [...document.querySelectorAll('#gSek .gtab')].filter(e => e.offsetParent).map(e => e.textContent.trim())""")
    ok(vis == ["İcmal", "Şagirdlər", "Tapşırıqlar", "Hesabat", "Dərs planı", "Dəftər"], "kompüterdə 6 sekmə", vis)
    ok(aktiv(pg) == "İcmal" and pg.evaluate("getComputedStyle(document.querySelector('#gSek .gtab.on')).borderBottomStyle") == "solid", "alt xətli seçili sekmə")
    for k, ad, h, sel in (("s", "Şagirdlər", "#/g/%s/s", "#stu .mrow"), ("a", "Tapşırıqlar", "#/a/%s", "#asgList"),
                          ("r", "Hesabat", "#/r/%s", "#rTabs"), ("p", "Dərs planı", "#/g/%s/p", "#planBox"),
                          ("d", "Dəftər", "#/g/%s/d", "#ledgerBox")):
        pg.click("#gSek .gtab[data-gt='%s']" % k); pg.wait_for_selector(sel, timeout=20000); pg.wait_for_timeout(400)
        ok(hash_(pg) == h % gid and aktiv(pg) == ad and pg.locator("#gHd").count() == 1 and pg.inner_text("#gName").strip() == G["n"],
           "«%s» → eyni başlıq, sekmə seçili" % ad, (hash_(pg), aktiv(pg)))
    pg.click("#gSet"); pg.wait_for_selector("#btnRen", timeout=20000)
    ok(hash_(pg) == "#/g/%s/x" % gid and pg.locator("#gSet.on").count() == 1, "dişli → Qrup ayarları", hash_(pg))
    pg.click("#gSek .gtab[data-gt='']"); pg.wait_for_selector("#gkDers", timeout=20000)

    print("B · Geri")
    pg.goto(PANEL + "#/gs"); pg.wait_for_timeout(1200)
    pg.goto(PANEL + "#/g/" + gid); pg.wait_for_selector("#gkDers .ykh", timeout=20000); pg.wait_for_timeout(800)
    for k in ("s", "a", "r", "p"):
        pg.click("#gSek .gtab[data-gt='%s']" % k); pg.wait_for_timeout(1300)
    pg.click("#gBack"); pg.wait_for_timeout(1300)
    ok(hash_(pg) == "#/gs", "«Geri» 4 sekmədən sonra Qruplara", hash_(pg))
    pg.goto(PANEL + "#/g/" + gid); pg.wait_for_selector("#gkDers .ykh", timeout=20000); pg.wait_for_timeout(800)
    pg.click("#gSek .gtab[data-gt='r']"); pg.wait_for_timeout(1300)
    pg.click("#gSek .gtab[data-gt='s']"); pg.wait_for_timeout(1300)
    pg.go_back(); pg.wait_for_timeout(1300)
    ok(hash_(pg) == "#/gs", "brauzerin «geri»si də Qruplara", hash_(pg))

    print("C · Bugünkü dərs")
    icmal(pg, gid)
    pos = pg.inner_text("#gkPos") if pg.locator("#gkPos").count() else ""
    ok(bool(re.search(r"dərs \d+ / \d+", pos)) and "%" not in pos, "«fəsil · dərs N / M», faiz yoxdur", pos)
    ok(pg.locator("#gkDers").inner_text().count("%") == 0, "kartda nəticə faizi yoxdur")
    pg.click("#gkDav"); pg.wait_for_selector("#ledgerBox", timeout=20000)
    ok(hash_(pg) == "#/g/%s/d" % gid, "«Davamiyyət» → Dəftər", hash_(pg))
    icmal(pg, gid)
    pend = pg.inner_text("#gkPend") if pg.locator("#gkPend").count() else ""
    mP = re.search(r"(\d+) şagird", pend)
    hwt = pg.inner_text("#gkHw") if pg.locator("#gkHw").count() else ""
    mH = re.search(r"(\d+) şagird", hwt)
    #  26.10: setir ozunun HISSESINI acir - «N şagird testi işləməyib» -> yalniz o N ad (#/ht/<qrup>/t)
    pg.click("#gkPend"); pg.wait_for_selector("#htBox .mrow, #htBox .empty", timeout=20000); pg.wait_for_timeout(500)
    ok(hash_(pg) == "#/ht/%s/t" % gid, "test sətri → #/ht/…/t", hash_(pg))
    ht = pg.inner_text("#htBox")
    mT = re.search(r"Test · (\d+) şagird işləməyib", ht, re.I)
    ok(mP and mT and mP.group(1) == mT.group(1) and pg.locator("#htBox .menu").first.locator(".udr").count() == int(mP.group(1)),
       "test sətrinin sayı = açılan səhifədəki adlar", (pend, mT.group(0) if mT else "-"))
    ok("Yazılı tapşırıq ·" not in ht, "açılan səhifədə yalnız test hissəsi")
    if mH:
        icmal(pg, gid)
        pg.click("#gkHw"); pg.wait_for_selector("#htBox .mrow", timeout=20000); pg.wait_for_timeout(500)
        ht2 = pg.inner_text("#htBox"); mY = re.search(r"Yazılı tapşırıq · (\d+) şagird etməyib", ht2, re.I)
        ok(hash_(pg) == "#/ht/%s/h" % gid and mY and mY.group(1) == mH.group(1) and "Test ·" not in ht2,
           "yazılı sətri → yalnız yazılı hissə, say eyni", (hwt, mY.group(0) if mY else "-"))
    icmal(pg, gid)
    ok(pg.locator("#gkDers .gwarn").count() <= 2, "xəbərdarlıq ən çox 2 sətir")
    pg.click("#prepGen"); pg.wait_for_selector("#btnMake", timeout=20000); pg.wait_for_timeout(800)
    ok(hash_(pg) == "#/gen" and "qrupa ver" in pg.inner_text("#btnMake"), "«5 suallıq test ver» → generator, «… qrupa ver»", pg.inner_text("#btnMake"))
    ok(pg.evaluate("(document.getElementById('gCnt') || {}).value") == "5", "sual sayı 5", pg.evaluate("(document.getElementById('gCnt') || {}).value"))

    print("D · Son tapşırıqlar; nəticə Hesabatda")
    icmal(pg, gid)
    ok(pg.locator("#gkDiq, #gkNet, #gkTodo").count() == 0, "nəticə / zəif mövzu kartı yoxdur")
    a1 = pg.inner_text("#gkAsg .gka1 .gkfr") if pg.locator("#gkAsg .gka1").count() else ""
    t1 = pg.inner_text("#gkAsg .gka1 .ytq b") if pg.locator("#gkAsg .gka1").count() else ""
    pg.click("#gkAsgAll"); pg.wait_for_selector("#asgList .asg", timeout=20000); pg.wait_for_timeout(400)
    ok(hash_(pg) == "#/a/" + gid and aktiv(pg) == "Tapşırıqlar", "«Hamısına bax» → Tapşırıqlar sekməsi", hash_(pg))
    row = pg.locator("#asgList .asg", has_text=t1).first.inner_text() if t1 else ""
    ok(a1 and a1.replace(" ", "") + " şagird bitirib" in row.replace(" / ", "/"), "«%s» Tapşırıqlar sətri ilə eyni" % a1, row[-80:].replace("\n", " | "))
    icmal(pg, gid)
    pg.click("#gkRep"); pg.wait_for_selector("#rTabs", timeout=20000)
    ok(hash_(pg) == "#/r/" + gid and aktiv(pg) == "Hesabat", "qeyd sətri → Hesabat", hash_(pg))
    ok(pg.locator("#btnRef").count() == 1, "Hesabatda «Yenilə» qalıb")

    print("E · «+ Tapşırıq ver»")
    icmal(pg, gid)
    pg.click("#btnAsgs"); pg.wait_for_timeout(200)
    items = [x.strip() for x in pg.locator("#gAsgMenu a").all_inner_texts()]
    ok(pg.locator("#gAsgMenu").is_visible() and items == ["Test ver", "Ev tapşırığı yaz"], "menyu: Test ver / Ev tapşırığı yaz", items)
    pg.mouse.click(700, 700); pg.wait_for_timeout(200)
    ok(pg.locator("#gAsgMenu").is_hidden(), "kənara basanda bağlanır")
    pg.click("#btnAsgs"); pg.click("#gAsgT"); pg.wait_for_selector("#pick", timeout=20000)
    ok(hash_(pg) == "#/a/%s/t" % gid, "Test ver → #/a/…/t", hash_(pg))
    icmal(pg, gid)
    pg.click("#btnAsgs"); pg.click("#gAsgH"); pg.wait_for_selector("#hwText", timeout=20000)
    ok(hash_(pg) == "#/a/%s/h" % gid, "Ev tapşırığı yaz → #/a/…/h", hash_(pg))
    if SHOT:
        icmal(pg, gid); pg.screenshot(path=SHOT + "/qrup_1280.png", full_page=True)

    print("F · telefon 390 / 360")
    for w in (390, 360):
        pg.set_viewport_size({"width": w, "height": 844})
        icmal(pg, gid)
        vis = pg.evaluate("""() => [...document.querySelectorAll('#gSek .gtab')].filter(e => e.offsetParent).map(e => e.textContent.trim())""")
        ok(vis == ["İcmal", "Şagirdlər", "Tapşırıqlar", "Hesabat", "Daha"], "%d: 4 sekmə + Daha" % w, vis)
        s2 = sw(pg); ok(s2[0] <= s2[1], "%d: yana sürüşmə yoxdur" % w, s2)
        fit = pg.evaluate("""() => { const n = document.getElementById('gSek').getBoundingClientRect();
            return [...document.querySelectorAll('#gSek .gtab')].filter(e => e.offsetParent).every(e => e.getBoundingClientRect().right <= n.right + .5); }""")
        ok(fit, "%d: sekmələr sığır" % w)
        hh = pg.evaluate("""() => ['#gBack', '#btnAsgs', '#gSet', '#gSek .gtab', '#gkDav', '#prepGen', '#gkPend', '#gkAsgAll', '#gkPlan']
            .map(s => document.querySelector(s)).filter(Boolean).map(e => [e.id || e.className, Math.round(e.getBoundingClientRect().height)])""")
        ok(hh and min(x[1] for x in hh) >= 44, "%d: düymə və keçidlər ≥ 44 px" % w, hh)
        ok(pg.evaluate("getComputedStyle(document.querySelector('#gName')).fontSize") == "22px", "%d: başlıq 22 px (əvvəl 20 idi — kiçilməyib)" % w)
    pg.click("#gMoreBtn"); pg.wait_for_timeout(200)
    items = [x.strip() for x in pg.locator("#gMoreMenu a").all_inner_texts()]
    ok(items == ["Dərs planı", "Dəftər"], "«Daha»: Dərs planı, Dəftər", items)
    pg.click("#gMoreMenu a[data-gt='d']"); pg.wait_for_selector("#ledgerBox", timeout=20000); pg.wait_for_timeout(300)
    ok(pg.inner_text("#gMoreBtn").strip() == "Dəftər", "Daha düyməsində «Dəftər»")
    if SHOT:
        pg.set_viewport_size({"width": 390, "height": 844}); icmal(pg, gid)
        pg.screenshot(path=SHOT + "/qrup_390.png", full_page=True)

    print("G · boş qrup")
    eg = db("""insert into public.classes (account_id, teacher_id, kind, name, join_code, level_id)
               select %s::uuid, %s::uuid, 'tutor_group', 'Boş qrup', 'BQ' || substr(md5(random()::text), 1, 6), l.id
                 from public.levels l where l.code = '7' returning id::text i""", (acc["i"], acc["o"]), one=True)["i"]
    icmal(pg, eg)
    t = pg.inner_text("#main")
    ok("Dərs planı qurulmayıb" in t and pg.locator("#gkPlanQur").count() == 1 and pg.locator("#gkDav").count() == 1, "boş: plan yoxdur + Planı qur + Davamiyyət")
    ok("Hələ tapşırıq verilməyib" in t, "boş: «Hələ tapşırıq verilməyib»")
    ok(pg.inner_text("#gMeta").strip() == "7-ci sinif · 0 şagird", "boş: «7-ci sinif · 0 şagird»", pg.inner_text("#gMeta"))
    if SHOT: pg.screenshot(path=SHOT + "/qrup_bos_390.png", full_page=True)
    pg.click("#gkPlanQur"); pg.wait_for_selector("#planBox", timeout=20000)
    ok(hash_(pg) == "#/g/%s/p" % eg, "«Planı qur» → plan sekməsi", hash_(pg))
    br.close()

print("\n" + ("BUTUN YOXLAMALAR KECDI" if not fails else "SEHV (%d): %s" % (len(fails), " | ".join(fails))))
sys.exit(1 if fails else 0)
