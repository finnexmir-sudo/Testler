#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Qrup səhifəsi 1-ci addım (UX yoxlaması, 23.10) — sekmələr + İcmal, nümunə hesabda.

  A  Sekmələr: kompüterdə 6 + ayarlar, telefonda 4 + «Daha» (3 bənd); hər sekmə öz ekranını açır,
     açılan ekranda HƏMİN sekmə seçilidir; 390 və 360 px-də yana sürüşmə yoxdur
  B  «Geri»: Qruplar → qrup → 4 sekmə → «Geri» Qruplara qaytarır (sekmələr arasında dolanmır);
     brauzerin geri düyməsi də
  C  Rəqəmlər mənbə ekranla eynidir: etməyənlər = #/ht siyahısı; son tapşırıq «done / tot» =
     Tapşırıqlar sətri; son nəticələr = Hesabat · Fəaliyyət ilk 5; zəif mövzu = «Nə etməli»
  D  Plandakı yer və son dərsin testi AYRI blokdur: «Plandakı yeri»ndə faiz yoxdur
  E  Keçidlər: Kim etməyib, Tapşırıqlar/Nəticələr «Hamısına bax», Dərs planı, Test ver, Təkrar ver
  F  Boş qrup: dörd kartın boş mətni
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
    pg.wait_for_function("document.querySelector('#gkNet') && !document.querySelector('#gIcmal .skel')", timeout=20000)
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

    print("A · sekmələr (1280)")
    icmal(pg, gid)
    vis = pg.evaluate("""() => [...document.querySelectorAll('#gSek .gtab')].filter(e => e.offsetParent).map(e => e.textContent.trim())""")
    ok(vis == ["İcmal", "Şagirdlər", "Tapşırıqlar", "Hesabat", "Dərs planı", "Dəftər", "Qrup ayarları"], "kompüterdə 6 sekmə + ayarlar", vis)
    ok(aktiv(pg) == "İcmal", "İcmal seçilidir", aktiv(pg))
    for k, ad, h, sel in (("s", "Şagirdlər", "#/g/%s/s", "#stu .mrow"), ("a", "Tapşırıqlar", "#/a/%s", "#asgList"),
                          ("r", "Hesabat", "#/r/%s", "#rTabs"), ("p", "Dərs planı", "#/g/%s/p", "#planBox"),
                          ("d", "Dəftər", "#/g/%s/d", "#ledgerBox"), ("x", "Qrup ayarları", "#/g/%s/x", "#btnRen")):
        pg.click("#gSek .gtab[data-gt='%s']" % k); pg.wait_for_selector(sel, timeout=20000); pg.wait_for_timeout(300)
        ok(hash_(pg) == h % gid and aktiv(pg) == ad and pg.locator("#gSek").count() == 1,
           "«%s» → %s, sekmə seçili" % (ad, h % "…"), (hash_(pg), aktiv(pg)))
    pg.click("#gSek .gtab[data-gt='']"); pg.wait_for_selector("#gkNet", timeout=20000)
    ok(hash_(pg) == "#/g/" + gid, "İcmal sekməsi qrupa qaytarır")

    print("B · Geri (1280)")
    pg.goto(PANEL + "#/gs"); pg.wait_for_timeout(1200)
    pg.goto(PANEL + "#/g/" + gid); pg.wait_for_selector("#gkNet", timeout=20000); pg.wait_for_timeout(800)
    for k in ("s", "a", "r", "p"):
        pg.click("#gSek .gtab[data-gt='%s']" % k); pg.wait_for_timeout(1300)
    pg.click("#band .bback"); pg.wait_for_timeout(1300)
    ok(hash_(pg) == "#/gs", "«Geri» 4 sekmədən sonra Qruplara qaytarır", hash_(pg))
    pg.goto(PANEL + "#/g/" + gid); pg.wait_for_selector("#gkNet", timeout=20000); pg.wait_for_timeout(800)
    pg.click("#gSek .gtab[data-gt='r']"); pg.wait_for_timeout(1300)
    pg.click("#gSek .gtab[data-gt='s']"); pg.wait_for_timeout(1300)
    pg.go_back(); pg.wait_for_timeout(1300)
    ok(hash_(pg) == "#/gs", "brauzerin «geri»si də Qruplara", hash_(pg))
    #  sekmənin İÇİNDƏN dərinə keçid adi qalır: hesabat → şagird → Geri → hesabat
    pg.goto(PANEL + "#/g/" + gid); pg.wait_for_selector("#gkNet", timeout=20000); pg.wait_for_timeout(800)
    pg.click("#gSek .gtab[data-gt='r']"); pg.wait_for_selector("#rTabs", timeout=20000); pg.wait_for_timeout(600)
    pg.locator("#rtab-s [data-s]").first.click(); pg.wait_for_timeout(1500)
    pg.click("#band .bback"); pg.wait_for_timeout(1500)
    ok(hash_(pg).startswith("#/r/" + gid), "şagird kartından «Geri» Hesabat sekməsinə", hash_(pg))

    print("C · rəqəmlər mənbə ekranla eyni")
    icmal(pg, gid)
    pend = pg.inner_text("#gkPend b") if pg.locator("#gkPend").count() else ""
    mP = re.search(r"(\d+) / (\d+) şagird", pend)
    hwn = pg.inner_text("#gkHw .gkdn") if pg.locator("#gkHw").count() else "0"
    pg.goto(PANEL + "#/ht/" + gid); pg.wait_for_selector("#htBox .mrow, #htBox .empty", timeout=20000); pg.wait_for_timeout(500)
    ht = pg.inner_text("#htBox")
    mT = re.search(r"Test · (\d+) şagird işləməyib", ht, re.I)
    mH = re.search(r"Yazılı tapşırıq · (\d+) şagird etməyib", ht, re.I)
    ok(mP is not None and mT is not None and mP.group(1) == mT.group(1), "test etməyənlər sayı #/ht ilə eyni",
       (pend, mT.group(0) if mT else ht[:100]))
    ok((mH.group(1) if mH else "0") == hwn, "yazılı etməyənlər sayı #/ht ilə eyni", (hwn, mH.group(0) if mH else "-"))
    icmal(pg, gid)
    a1 = pg.inner_text("#gkAsg .gka1 .gkfr") if pg.locator("#gkAsg .gka1").count() else ""
    t1 = pg.inner_text("#gkAsg .gka1 .g b") if pg.locator("#gkAsg .gka1").count() else ""
    pg.click("#gkAsgAll"); pg.wait_for_selector("#asgList .asg", timeout=20000); pg.wait_for_timeout(400)
    ok(hash_(pg) == "#/a/" + gid, "Son tapşırıqlar «Hamısına bax» → Tapşırıqlar", hash_(pg))
    row = pg.locator("#asgList .asg", has_text=t1).first.inner_text() if t1 else ""
    ok(a1 and a1.replace(" ", "") + " şagird bitirib" in row.replace(" / ", "/"), "son tapşırıq «%s» Tapşırıqlar sətri ilə eyni" % a1, row[-90:].replace("\n", " | "))
    icmal(pg, gid)
    net = pg.evaluate("""() => [...document.querySelectorAll('#gkNet .gkn')].map(e => e.innerText.replace(/\\s+/g,' ').trim())""")
    pg.click("#gkNetAll"); pg.wait_for_selector("#rRec", timeout=20000); pg.wait_for_timeout(400)
    ok(hash_(pg) == "#/r/" + gid + "/f" and pg.locator("#rtab-f").is_visible(), "Son nəticələr «Hamısına bax» → Hesabat · Fəaliyyət", hash_(pg))
    rec = pg.evaluate("""() => [...document.querySelectorAll('#rRec .trow')].slice(0,5).map(e => e.innerText.replace(/\\s+/g,' ').trim())""")
    ok(len(net) == 5 and net == rec, "son 5 nəticə Fəaliyyətin ilk 5 sətri ilə eyni", (net[:2], rec[:2]))
    todo_r = pg.inner_text("#rTodo") if pg.locator("#rTodo").count() else ""
    mR = re.search(r"«(.+?)» mövzusunu (\d+) şagirdə", todo_r)
    icmal(pg, gid)
    td = pg.inner_text("#gkTodo b") if pg.locator("#gkTodo").count() else ""
    ok(mR is not None and td == "«%s» — %s şagird zəifdir" % (mR.group(1), mR.group(2)), "zəif mövzu = Hesabatın «Nə etməli»si", (td, todo_r[:80]))

    print("D · plan yeri ≠ son dərsin nəticəsi")
    pos = pg.inner_text("#gkPos") if pg.locator("#gkPos").count() else ""
    ok(bool(re.search(r"dərs \d+ / \d+", pos)) and "%" not in pos, "«Plandakı yeri»: dərs N / M, faiz yoxdur", pos)
    #  24.10: «Son keçilən dərs» açılıb-bağlanandır - bağlı gəlir, başlığında faiz
    ok(pg.locator("#gkLast").count() == 1 and pg.locator("#gkLast").get_attribute("open") is None, "«Son keçilən dərs» bağlı gəlir")
    if pg.locator("#gkLast summary").count(): pg.click("#gkLast summary"); pg.wait_for_timeout(200)
    last = pg.inner_text("#gkLast") if pg.locator("#gkLast").count() else ""
    ok("bu dərsin testi" in last and "%" in last, "son dərsin testi ayrı blokda, öz sözü ilə", last.replace("\n", " | "))
    pg.click("#gkPlan"); pg.wait_for_selector("#planBox", timeout=20000); pg.wait_for_timeout(300)
    ok(hash_(pg) == "#/g/%s/p" % gid and aktiv(pg) == "Dərs planı", "«Dərs planı →» plan sekməsini açır", hash_(pg))

    print("E · keçidlər")
    icmal(pg, gid)
    pg.click("#gkPendGo"); pg.wait_for_selector("#htBox", timeout=20000)
    ok(hash_(pg) == "#/ht/" + gid, "«Kim etməyib» → #/ht", hash_(pg))
    icmal(pg, gid)
    pg.click("#btnAsgs"); pg.wait_for_selector("#pick", timeout=20000)
    ok(hash_(pg) == "#/a/%s/t" % gid, "zolaqda «Test ver» → test ver ekranı", hash_(pg))
    icmal(pg, gid)
    if pg.locator("#gkHwGo").count():
        pg.click("#gkHwGo"); pg.wait_for_timeout(1200)
        ok(hash_(pg) == "#/a/" + gid, "yazılı tapşırıq → Tapşırıqlar", hash_(pg))
        icmal(pg, gid)
    pg.click("#gkTodoGo"); pg.wait_for_selector("#btnMake", timeout=20000); pg.wait_for_timeout(800)
    ok(hash_(pg) == "#/gen" and mR is not None and mR.group(1) in pg.inner_text("#main"), "«Təkrar ver» → generator həmin mövzu ilə", hash_(pg))
    if SHOT:
        icmal(pg, gid); pg.screenshot(path=SHOT + "/icmal_1280.png", full_page=True)

    print("A2 · telefon 390 / 360")
    for w in (390, 360):
        pg.set_viewport_size({"width": w, "height": 844})
        icmal(pg, gid)
        vis = pg.evaluate("""() => [...document.querySelectorAll('#gSek .gtab')].filter(e => e.offsetParent).map(e => e.textContent.trim())""")
        ok(vis == ["İcmal", "Şagirdlər", "Tapşırıqlar", "Hesabat", "Daha"], "%d: 4 sekmə + Daha" % w, vis)
        s = sw(pg); ok(s[0] <= s[1], "%d: yana sürüşmə yoxdur" % w, s)
        tabs_fit = pg.evaluate("""() => { const n = document.getElementById('gSek').getBoundingClientRect();
            return [...document.querySelectorAll('#gSek .gtab')].filter(e => e.offsetParent).every(e => e.getBoundingClientRect().right <= n.right + .5); }""")
        ok(tabs_fit, "%d: sekmələr zolağa sığır" % w)
        hgt = pg.evaluate("""() => Math.min(...[...document.querySelectorAll('#gSek .gtab')].filter(e => e.offsetParent).map(e => e.getBoundingClientRect().height))""")
        ok(hgt >= 44, "%d: sekmə hündürlüyü ≥ 44" % w, hgt)
        #  26.10: yigcamliq yazini ve duymeni kicilterek olmur - telefonda 44 px, basliq 20 px
        hh = pg.evaluate("""() => ['#btnAsgs', '#band .bback', '#gkPendGo', '#gkTodoGo', '#gkAsgAll', '#gkNetAll']
            .map(s => document.querySelector(s)).filter(Boolean).map(e => Math.round(e.getBoundingClientRect().height))""")
        ok(hh and min(hh) >= 44, "%d: düymə və keçidlər ≥ 44 px" % w, hh)
        ok(pg.evaluate("getComputedStyle(document.querySelector('#band h1')).fontSize") == "20px", "%d: başlıq 20 px (kiçilməyib)" % w)
    pg.click("#gMoreBtn"); pg.wait_for_timeout(200)
    items = pg.evaluate("""() => [...document.querySelectorAll('#gMoreMenu a')].filter(e => e.offsetParent).map(e => e.textContent.trim())""")
    ok(items == ["Dərs planı", "Dəftər", "Qrup ayarları"], "«Daha»: Dərs planı, Dəftər, Qrup ayarları", items)
    pg.mouse.click(5, 500); pg.wait_for_timeout(200)
    ok(pg.locator("#gMoreMenu").is_hidden(), "kənara basanda «Daha» bağlanır")
    pg.click("#gMoreBtn"); pg.click("#gMoreMenu a[data-gt='d']"); pg.wait_for_selector("#ledgerBox", timeout=20000); pg.wait_for_timeout(400)
    ok(hash_(pg) == "#/g/%s/d" % gid and pg.inner_text("#gMoreBtn").strip() == "Dəftər", "Daha → Dəftər; düymədə «Dəftər» yazılır", pg.inner_text("#gMoreBtn"))
    if SHOT:
        pg.set_viewport_size({"width": 390, "height": 844}); icmal(pg, gid)
        pg.screenshot(path=SHOT + "/icmal_390.png", full_page=True)

    print("F · boş qrup")
    eg = db("""insert into public.classes (account_id, teacher_id, kind, name, join_code, level_id)
               select %s::uuid, %s::uuid, 'tutor_group', 'Boş qrup', 'BQ' || substr(md5(random()::text), 1, 6), l.id
                 from public.levels l where l.code = '7' returning id::text i""", (acc["i"], acc["o"]), one=True)["i"]
    pg.set_viewport_size({"width": 390, "height": 844})
    icmal(pg, eg)
    t = pg.inner_text("#gIcmal")
    ok("Dərs planı qurulmayıb" in t and pg.locator("#gkPlanQur").count() == 1, "boş: «Dərs planı qurulmayıb» + Planı qur")
    ok(pg.locator("#gkNoStu").count() == 1 and pg.locator("#gkOk").count() == 0,
       "boş: «Qrupda hələ şagird yoxdur» (yalançı «qaydasındadır» yox)")
    ok("Hələ tapşırıq verilməyib" in t, "boş: «Hələ tapşırıq verilməyib»")
    ok("Hələ test yazan yoxdur" in t, "boş: «Hələ test yazan yoxdur»")
    ok("0 şagird" in pg.inner_text("#gMeta"), "boş: başlıqda «0 şagird»", pg.inner_text("#gMeta"))
    if SHOT: pg.screenshot(path=SHOT + "/bos_390.png", full_page=True)
    pg.click("#gkPlanQur"); pg.wait_for_selector("#planBox", timeout=20000)
    ok(hash_(pg) == "#/g/%s/p" % eg, "«Planı qur» → plan sekməsi", hash_(pg))
    br.close()

print("\n" + ("BUTUN YOXLAMALAR KECDI" if not fails else "SEHV (%d): %s" % (len(fails), " | ".join(fails))))
sys.exit(1 if fails else 0)
