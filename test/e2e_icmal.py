#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Ümumi İcmal (26.10, istifadəçinin son maketi) — nümunə hesabda.

  A  İcmalda qrupa aid nəticə və xəbərdarlıq YOXDUR; menyu təkrarı yoxdur; başlıq «Salam, … müəllim» + tarix
  B  «Qruplarım»: hər qrupun sinfi və şagird sayı (rpc_groups_summary) Nəticələr · Qruplar ilə eyni;
     başlıqdakı «N qrup · M şagird» sətirlərin cəmi ilə eyni; sətir qrupu açır
  C  «Bugünkü dərslər»: bugünkü dərslər rpc_week ilə eyni; sətir qrupu açır; «Bütün həftə» açılır;
     cədvəl yoxdursa ilk addım yazılır
  D  «Qrup yarat» → Qruplar, ad sahəsi hazır; «Test yığ» → #/gen; «Nəticələr» → #/nt
  E  İcmaldan köçənlər itmir: Siqnallarda «son 7 gündə test işləməyib» = #/sus adları
  F  360 px: yana sürüşmə yoxdur, düymə ≥ 44 px, başlıq 22 px; 1280 px: başlıq 26 px
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
def h(pg): return pg.evaluate("location.hash")
def icmal(pg):
    pg.goto(PANEL + "#/"); pg.reload()
    pg.wait_for_function("document.querySelector('#yNet .gkh') && document.querySelector('#yMenu .mrow')", timeout=25000)
    pg.wait_for_timeout(600)

def icmal(pg):
    pg.goto(PANEL + "#/"); pg.reload()
    pg.wait_for_function("document.querySelector('#yMenu .ytr') && document.querySelector('#hWeek .ykh')", timeout=25000)
    pg.wait_for_timeout(600)

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 1280, "height": 900})
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)[:160]))
    pg.goto(PANEL + "#/demo"); pg.wait_for_selector("#demoBar", timeout=60000); pg.wait_for_timeout(2500)
    acc = db("select id::text i from public.accounts where is_demo and id <> app.demo_account() order by created_at desc limit 1", one=True)["i"]
    icmal(pg)

    print("A · yalnız bu günün işi")
    mt = pg.inner_text("#main")
    ok(pg.locator("#yDiq, #yNet, #gkDiq").count() == 0 and "zəif gedir" not in mt and "test işləməyib" not in mt,
       "qrupa aid nəticə/xəbərdarlıq yoxdur")
    rows = [t.split("\n")[0].strip() for t in pg.locator("#main .mrow").all_inner_texts()]
    ok(not [r for r in rows if r in ("Qruplar", "Test yığ", "Nəticələr", "Sual bankı", "Profil")], "menyu təkrarı yoxdur", rows[:4])
    ok(pg.inner_text("#yHd h1").startswith("Salam") and re.search(r"^(Bazar|Çərşənbə|Cümə|Şənbə).*, \d+ [a-zəşç]+$", pg.inner_text("#ySub")),
       "başlıq və bu günün tarixi", pg.inner_text("#ySub"))
    ok(pg.locator("#band").is_hidden(), "iri rəngli zolaq yoxdur")
    ok(pg.evaluate("getComputedStyle(document.querySelector('#yHd h1')).fontSize") == "26px", "1280: başlıq 26 px")
    if SHOT: pg.screenshot(path=SHOT + "/icmal_1280.png", full_page=True)

    print("B · Qruplarım")
    yq = {}
    for r in pg.locator("#yMenu .ytr").all():
        yq[r.locator(".ytq b").inner_text().strip()] = (r.locator(".yts").inner_text().strip(), int(r.locator(".ytn").inner_text()))
    sub = pg.inner_text("#yQrpSub"); mS = re.search(r"(\d+) qrup · (\d+) şagird", sub)
    ok(mS and int(mS.group(1)) == len(yq) and int(mS.group(2)) == sum(v[1] for v in yq.values()),
       "«N qrup · M şagird» sətirlərin cəmi ilə eyni", (sub, len(yq), sum(v[1] for v in yq.values())))
    pg.goto(PANEL + "#/nt"); pg.wait_for_selector("#ntQ .mrow", timeout=20000)
    nq = {}
    for t in pg.locator("#ntQ .mrow").all_inner_texts():
        ln = [x.strip() for x in t.split("\n") if x.strip()]
        m = re.search(r"(\d+) şagird", t); nq[ln[0]] = int(m.group(1)) if m else None
    ok(nq and all(nq.get(k) == v[1] for k, v in yq.items()), "şagird sayları Nəticələr · Qruplar ilə eyni", (yq, nq))
    lv = {r["n"]: r["s"] for r in db("""select c.name n, l.name s from public.classes c join public.levels l on l.id = c.level_id
                                        where c.account_id = %s::uuid""", (acc,))}
    ok(all(lv.get(k) == v[0] for k, v in yq.items()), "sinif sütunu qrupun sinfi ilə eyni", (yq, lv))
    icmal(pg)
    first = pg.locator("#yMenu .ytr").first; href = first.get_attribute("href")
    ok(pg.locator("#yMenu .ytr .ytk").first.is_visible(), "«Qrupa keç» görünür")
    first.click(); pg.wait_for_selector("#gSek", timeout=20000)
    ok(pg.evaluate("location.hash") == href and href.startswith("#/g/"), "sətir qrupu açır", href)

    print("C · Bugünkü dərslər")
    icmal(pg)
    #  rpc_week-in oz menbeyi (auth olmadan): app.cedvel_araliq, bu gun, Baki
    bugun = db("""select to_char(r.starts_at, 'HH24:MI') "time", r.class_name "class" from app.cedvel_araliq(%s::uuid, app.baki_bugun(), 1) r
                  where r.on_date = app.baki_bugun() and r.hal <> 'moved_out' order by r.on_date, r.starts_at""", (acc,))
    ui = [(r.locator(".ytt").inner_text().strip(), r.locator(".ytq b").inner_text().strip()) for r in pg.locator("#hWeek a.ytr").all()]
    ok(ui == [(d["time"], d["class"]) for d in bugun], "bugünkü dərslər rpc_week ilə eyni", (ui, len(bugun)))
    if ui:
        h0 = pg.locator("#hWeek a.ytr").first.get_attribute("href")
        pg.locator("#hWeek a.ytr").first.click(); pg.wait_for_selector("#gSek", timeout=20000)
        ok(pg.evaluate("location.hash") == h0, "dərs sətri qrupu açır", h0)
        icmal(pg)
    if pg.locator("#wkAll").count():
        pg.click("#wkAll"); pg.wait_for_timeout(200)
        ok(pg.locator("#hWeek details.wkf").get_attribute("open") is not None and pg.locator("#hWeek .wkgrid").is_visible(), "«Bütün həftə» açılır")

    print("D · düymələr")
    pg.click("#yNewG"); pg.wait_for_selector("#gForm", timeout=20000); pg.wait_for_timeout(500)
    ok(pg.evaluate("location.hash") == "#/gs" and pg.evaluate("document.activeElement && document.activeElement.id") == "gname",
       "«Qrup yarat» → Qruplar, ad sahəsi hazır", pg.evaluate("location.hash"))
    icmal(pg)
    pg.click("#yGen"); pg.wait_for_selector("#btnMake, #gsub", timeout=20000)
    ok(pg.evaluate("location.hash") == "#/gen", "«Test yığ» → #/gen")
    icmal(pg)
    pg.click("#yNetAll"); pg.wait_for_selector("#ntUst", timeout=20000)
    ok(pg.evaluate("location.hash") == "#/nt", "«Nəticələr» → #/nt")

    print("E · İcmaldan köçənlər: Siqnallar")
    pg.goto(PANEL + "#/n"); pg.reload(); pg.wait_for_timeout(2500)
    if pg.locator("#nSus").count():
        n = int(re.search(r"(\d+) şagird son 7 gündə test işləməyib", pg.inner_text("#nSus")).group(1))
        pg.click("#nSus a.mrow"); pg.wait_for_selector("#suBox", timeout=20000); pg.wait_for_timeout(800)
        k = pg.locator("#suBox .mrow").count()
        ok(pg.evaluate("location.hash") == "#/sus" and k == n, "Siqnallar: %d deyir, #/sus %d ad" % (n, k))
    else:
        ok(True, "səssiz şagird yoxdur")

    print("F · telefon 360 + cədvəl yoxdursa")
    pg.set_viewport_size({"width": 360, "height": 800})
    icmal(pg)
    sw = pg.evaluate("[document.documentElement.scrollWidth, window.innerWidth]")
    ok(sw[0] <= sw[1], "360: yana sürüşmə yoxdur", sw)
    hh = pg.evaluate("""() => ['#yNewG', '#yGen', '#yNetAll', '#wkAll', '#yMenu .ytr', '#hWeek a.ytr']
        .map(s => document.querySelector(s)).filter(Boolean).map(e => [e.id || e.className, Math.round(e.getBoundingClientRect().height)])""")
    ok(hh and min(x[1] for x in hh) >= 44, "360: düymə və sətirlər ≥ 44 px", hh)
    ok(pg.evaluate("getComputedStyle(document.querySelector('#yHd h1')).fontSize") == "22px", "360: başlıq 22 px")
    if SHOT: pg.screenshot(path=SHOT + "/icmal_360.png", full_page=True)
    db("delete from public.class_schedule s using public.classes c where c.id = s.class_id and c.account_id = %s::uuid", (acc,))
    icmal(pg)
    ok(pg.locator("#wkNone").is_visible() and "Dəftər" in pg.inner_text("#wkNone"), "cədvəl yoxdursa: harada qurulduğu yazılır")
    br.close()
print("\n" + ("BUTUN YOXLAMALAR KECDI" if not fails else "SEHV (%d): %s" % (len(fails), " | ".join(fails))))
sys.exit(1 if fails else 0)
