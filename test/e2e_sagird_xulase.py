#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Şagird səhifəsi · Xülasə (UX, 23.10) — nümunə hesabda.

  A  «son 30 gün» rəqəmləri = «Valideyn üçün hesabat» cümləsi = valideyn mətni (bir mənbə)
  B  «Təkrar tövsiyəsi»: mövzu və faiz Mövzular sekmesindəki sətirlə eyni; düymə generatoru
     HƏMİN mövzu və YALNIZ bu şagirdlə açır
  C  «Son nəticələr» = Tarixçənin ilk 5 sətri; keçid Tarixçə sekmesini açır
  D  «Gözləyən tapşırıqlar» = #/ht səhifəsindəki həmin şagirdin sətri
  E  Diaqnostika Mövzular sekmesindədir, Xülasədə yoxdur; «Mətnə bax» açır, «Mətni kopyala» mətni kopyalayır
  F  Boş şagird (test yoxdur): kartların boş mətni
  G  390 və 1280 px: yana sürüşmə yoxdur
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

def norm(t): return re.sub(r"\s+", " ", t or "").strip()
def sw(pg): return pg.evaluate("[document.documentElement.scrollWidth, window.innerWidth]")
def ac(pg, sid, gid):
    pg.goto(PANEL + "#/s/%s/%s" % (sid, gid)); pg.reload()
    pg.wait_for_selector("#stuSon", timeout=25000)
    pg.wait_for_function("document.querySelector('#stuPend') && !/Yüklənir/.test(document.querySelector('#stuPend').textContent)", timeout=20000)
    pg.wait_for_timeout(500)

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 1280, "height": 900})
    ctx.grant_permissions(["clipboard-read", "clipboard-write"], origin="http://127.0.0.1:8010")
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)[:160]))
    pg.goto(PANEL + "#/demo"); pg.wait_for_selector("#demoBar", timeout=60000); pg.wait_for_timeout(2500)
    acc = db("select id::text i, owner_id::text o from public.accounts where is_demo and id <> app.demo_account() order by created_at desc limit 1", one=True)
    #  zeif movzusu olan (Təkrar tövsiyəsi duymesi cixan) ve 6+ testli sagird
    rows = db("""select c.id::text g, s.id::text s, s.full_name n from public.classes c join public.students s on s.class_id = c.id
                 where c.account_id = %s::uuid and (select count(*) from public.attempts a where a.student_id = s.id) >= 6
                 order by (select count(*) from public.attempts a where a.student_id = s.id) desc, s.full_name""", (acc["i"],))
    for row in rows:
        gid, sid, NAME = row["g"], row["s"], row["n"]
        ac(pg, sid, gid)
        if pg.locator("#vdTov").count(): break
    FN = NAME.split()[0]
    print("   şagird:", NAME)

    print("A · son 30 gün = valideyn cümləsi = valideyn mətni")
    rs = norm(pg.inner_text(".rstat"))
    mA = re.search(r"(\d+)% orta · son 30 gün", rs); mN = re.search(r"(\d+) test · son 30 gün", rs)
    vs = pg.inner_text("#vSum")
    mV = re.search(r"Son 30 gündə (\d+) test işləyib\. Orta nəticə (\d+)%", vs)
    vt = pg.input_value("#vTxt")
    ok(mA and mN and mV and mA.group(1) == mV.group(2) and mN.group(1) == mV.group(1), "rəqəm sətri = valideyn cümləsi", (rs[:60], vs))
    ok(mV and ("İşlənən test: " + mV.group(1)) in vt and ("Ortalama: " + mV.group(2) + "%") in vt, "valideyn mətni eyni rəqəmləri deyir", vt[:90].replace("\n", " | "))
    ok("bütün dövr" in rs, "bütün dövr kiçik sətirdə qalır", rs[-40:])

    print("B · Təkrar tövsiyəsi")
    tv = pg.inner_text("#stuTov")
    mT = re.search(r"Təkrar tövsiyəsi\s+(.+?)\s+Son nəticə: (\d+)%", tv, re.S)
    ok(mT is not None and "Yalnız " + FN + " üçün" in tv, "mövzu, faiz və «Yalnız %s üçün»" % FN, tv[:120].replace("\n", " | "))
    pg.locator("#sTabs [data-v='m']").click(); pg.wait_for_timeout(500)
    trow = pg.locator("#topicBox .trow", has_text=mT.group(1)).first if mT else None
    ok(trow is not None and trow.count() == 1 and (mT.group(2) + "%") in trow.inner_text(), "Mövzular sekmesində eyni mövzu, eyni faiz",
       trow.inner_text().replace("\n", " ") if trow is not None and trow.count() else "-")
    ok(pg.locator("#tab-m #diagBox").count() == 1 and pg.locator("#tab-x #diagBox").count() == 0, "diaqnostika Mövzular sekmesindədir")
    pg.locator("#sTabs [data-v='x']").click(); pg.wait_for_timeout(300)
    pg.click("#vdTov"); pg.wait_for_selector("#btnMake", timeout=20000); pg.wait_for_timeout(1200)
    mt = pg.inner_text("#main")
    ok(pg.evaluate("location.hash") == "#/gen" and mT and mT.group(1) in mt and NAME in mt and "şagirdə ver" in pg.inner_text("#btnMake"),
       "generator həmin mövzu və şagirdlə, düymə «… şagirdə ver»", pg.inner_text("#btnMake"))

    print("C · Son nəticələr = Tarixçə")
    ac(pg, sid, gid)
    son = pg.evaluate("""() => [...document.querySelectorAll('#stuSon .gkn')].map(e => e.innerText.replace(/\\s+/g,' ').trim())""")
    pg.click("#vdTar"); pg.wait_for_timeout(400)
    ok(pg.locator("#tab-t").is_visible(), "keçid Tarixçə sekmesini açır")
    tar = pg.evaluate("""() => [...document.querySelectorAll('#atList .atr')].slice(0,5).map(e => e.innerText.replace(/\\s+/g,' ').trim())""")
    ok(len(son) == 5 and son == tar, "ilk 5 sətir Tarixçə ilə eyni", (son[:1], tar[:1]))

    print("D · Gözləyən tapşırıqlar = #/ht")
    pg.locator("#sTabs [data-v='x']").click()
    pend = norm(pg.inner_text("#stuPend"))
    pg.goto(PANEL + "#/ht/" + gid); pg.wait_for_selector("#htBox .mrow, #htBox .empty", timeout=20000); pg.wait_for_timeout(500)
    ht_rows = [norm(t) for t in pg.locator("#htBox .udr", has_text=NAME).all_inner_texts()]
    mP = re.search(r"(\d+) test gözləyir", pend)
    ht_t = [t for t in ht_rows if "test gözləyir" in t]
    ok((mP is None and not ht_t) or (mP and ht_t and (mP.group(0) in ht_t[0])), "test gözləyir sayı #/ht ilə eyni", (pend[:60], ht_t[:1]))
    ok(("Yazılı tapşırığı etməyib" in pend) == any("yazılı tapşırığı etməyib" in t for t in ht_rows), "yazılı tapşırıq #/ht ilə eyni")

    print("E · Mətnə bax / Mətni kopyala")
    ac(pg, sid, gid)
    ok(not pg.locator("#vTxt").is_visible(), "mətn susmaya görə bağlı")
    pg.click("#vOpen"); pg.wait_for_timeout(200)
    ok(pg.locator("#vTxt").is_visible() and "gizlət" in pg.inner_text("#vOpen"), "«Mətnə bax» açır")
    pg.click("#vCopy"); pg.wait_for_timeout(400)
    ok(pg.evaluate("navigator.clipboard.readText()") == pg.input_value("#vTxt"), "«Mətni kopyala» mətni kopyalayır")
    ok(sw(pg)[0] <= sw(pg)[1], "1280: yana sürüşmə yoxdur")
    if SHOT: pg.screenshot(path=SHOT + "/sagird_1280.png", full_page=True)

    print("F · boş şagird")
    #  sagird panelin oz yolu ile elave olunur (kod, yer, owner yoxlamalari server isidir)
    pg.goto(PANEL + "#/g/%s/s" % gid); pg.wait_for_selector("#btnStuOpen", timeout=20000)
    pg.click("#btnStuOpen"); pg.fill("#sname", "Test Boşov"); pg.click("#btnStu"); pg.wait_for_timeout(2500)
    e = db("select id::text i from public.students where class_id = %s::uuid and full_name = 'Test Boşov'", (gid,), one=True)["i"]
    pg.goto(PANEL + "#/s/%s/%s" % (e, gid)); pg.reload(); pg.wait_for_selector("#stuSon", timeout=25000); pg.wait_for_timeout(1500)
    t = pg.inner_text("#tab-x")
    ok("Hələ test işləməyib" in pg.inner_text("#stuSon"), "boş: «Hələ test işləməyib»")
    ok("ən zəif mövzu görünəcək" in pg.inner_text("#stuTov"), "boş: tövsiyə kartında izah", pg.inner_text("#stuTov")[:80])
    ok(pg.locator("#vdTov").count() == 0 and pg.locator("#vdF").count() == 0, "boş: düymələr yoxdur")
    ok("Hələ test işləməyib" in pg.inner_text("#vSum"), "boş: valideyn cümləsi")
    ok(pg.locator("#tab-x .rstat").count() == 0 and "0%" not in t, "boş: «0 test · 0%» yazılmır")
    ok(pg.locator("#vCopy").count() == 0, "boş: boş mətni kopyalamaq düyməsi yoxdur")
    if SHOT: pg.screenshot(path=SHOT + "/sagird_bos.png", full_page=True)

    print("G · telefon 390")
    pg.set_viewport_size({"width": 390, "height": 844})
    ac(pg, sid, gid)
    ok(sw(pg)[0] <= sw(pg)[1], "390: yana sürüşmə yoxdur", sw(pg))
    bb = pg.locator("#vdTov").bounding_box()
    ok(bb and bb["height"] >= 44, "390: təkrar düyməsi ≥ 44 px", bb)
    hh = pg.evaluate("""() => ['#band .bback', '#btnAsgStu', '#vdF', '#vCopy', '#vOpen', '#stuPend [data-sp]', '#sTabs .seg']
        .map(s => document.querySelector(s)).filter(Boolean).map(e => Math.round(e.getBoundingClientRect().height))""")
    ok(hh and min(hh) >= 44, "390: bütün düymələr ≥ 44 px", hh)
    ok(pg.evaluate("getComputedStyle(document.querySelector('#band h1')).fontSize") == "22px", "390: şagirdin adı 22 px (kiçilməyib)")
    if SHOT: pg.screenshot(path=SHOT + "/sagird_390.png", full_page=True)
    br.close()

print("\n" + ("BUTUN YOXLAMALAR KECDI" if not fails else "SEHV (%d): %s" % (len(fails), " | ".join(fails))))
sys.exit(1 if fails else 0)
