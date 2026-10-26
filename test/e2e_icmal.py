#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""İcmal (UX, 26.10 — GPT siyahısında 2-ci) — nümunə hesabda.

  A  Menyu təkrarı yoxdur: Qruplar / Test yığ / Nəticələr / Sual bankı / Profil iri sətirləri çıxıb
  B  «Yeni nəticələr» = Nəticələr səhifəsindəki «Son cavablar» (eyni 5 şagird, eyni faiz); «Hamısına bax» → #/nt
  C  «Qruplarım» faizləri = Nəticələr · Qruplar (eyni sorğu); sətir qrupun özünü açır
  D  «Diqqət tələb edir» sətri səssiz şagirdləri sayır → #/sus eyni sayda ad
  E  Zolaqda «Test yığ» → #/gen; «Hamısı» → #/gs
  F  360 px: yana sürüşmə yoxdur, düymə/keçid ≥ 44 px, başlıq 22 px (kiçilməyib); 1280 px: başlıq 26 px
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

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 1280, "height": 900})
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)[:160]))
    pg.goto(PANEL + "#/demo"); pg.wait_for_selector("#demoBar", timeout=60000); pg.wait_for_timeout(2500)
    icmal(pg)

    print("A · menyu təkrarı yoxdur")
    rows = [t.split("\n")[0].strip() for t in pg.locator("#main .mrow").all_inner_texts()]
    dup = [r for r in rows if r in ("Qruplar", "Test yığ", "Nəticələr", "Sual bankı", "Profil")]
    ok(not dup, "iri menyu sətirləri yoxdur", dup)
    ok(pg.locator("#yDiq .gkh").count() == 1 and pg.locator("#yNet .gkh").count() == 1 and pg.locator("#yQrp .gkh").count() == 1,
       "kartlar: Diqqət, Yeni nəticələr, Qruplarım")
    if SHOT: pg.screenshot(path=SHOT + "/icmal_1280.png", full_page=True)
    ok(pg.evaluate("getComputedStyle(document.querySelector('#band h1')).fontSize") == "26px", "1280: başlıq 26 px")

    print("B · Yeni nəticələr = Nəticələr · Son cavablar")
    yn = [(re.sub(r"\s+", " ", a.split("\n")[0]).strip(), re.findall(r"(\d+)%", a)[-1]) for a in pg.locator("#yNet .gkn").all_inner_texts()]
    pg.click("#yNetAll"); pg.wait_for_selector("#ntS .mrow", timeout=20000); pg.wait_for_timeout(300)
    ok(h(pg) == "#/nt", "«Hamısına bax» → #/nt", h(pg))
    sc = []
    for t in pg.locator("#ntS .mrow").all_inner_texts():
        ln = [x.strip() for x in t.split("\n") if x.strip()]
        sc.append((ln[1] if len(ln[0]) <= 2 else ln[0], re.findall(r"(\d+)%", t)[-1]))
    ok(len(yn) == 5 and yn == sc[:5], "5 nəticə eyni (ad, faiz)", (yn[:2], sc[:2]))
    nq = {}
    for t in pg.locator("#ntQ .mrow").all_inner_texts():
        ln = [x.strip() for x in t.split("\n") if x.strip()]
        m = re.findall(r"(\d+)%", t); nq[ln[0]] = m[-1] if m else None

    print("C · Qruplarım = Nəticələr · Qruplar")
    icmal(pg)
    yq = {}
    for t in pg.locator("#yMenu .mrow").all_inner_texts():
        ln = [x.strip() for x in t.split("\n") if x.strip()]
        m = re.findall(r"(\d+)%", t); yq[ln[0]] = m[-1] if m else None
    ok(yq and yq == nq, "qrup faizləri eyni", (yq, nq))
    first = pg.locator("#yMenu .mrow").first
    href = first.get_attribute("href"); first.click(); pg.wait_for_selector("#gSek", timeout=20000)
    ok(h(pg) == href and href.startswith("#/g/"), "qrup sətri qrupun İcmalını açır", h(pg))

    print("D · Diqqət: səssiz şagirdlər")
    icmal(pg)
    sus = pg.locator("#yDiq .mrow", has_text="səssizdir")
    if sus.count():
        n = int(re.search(r"(\d+) şagird", sus.first.inner_text()).group(1))
        sus.first.click(); pg.wait_for_selector("#suBox", timeout=20000); pg.wait_for_timeout(800)
        k = pg.locator("#suBox .mrow").count()
        ok(h(pg) == "#/sus" and k == n, "sətir %d deyir, #/sus %d ad göstərir" % (n, k))
    else:
        ok(pg.locator("#yDiqOk").count() == 1, "səssiz yoxdursa «Hər şey qaydasındadır»")

    print("E · keçidlər")
    icmal(pg)
    pg.click("#yGen"); pg.wait_for_selector("#btnMake, #gsub", timeout=20000)
    ok(h(pg) == "#/gen", "«Test yığ» → #/gen", h(pg))
    icmal(pg)
    pg.click("#yQrpAll"); pg.wait_for_timeout(1200)
    ok(h(pg) == "#/gs", "«Hamısı» → #/gs", h(pg))

    print("F · telefon 360")
    pg.set_viewport_size({"width": 360, "height": 800})
    icmal(pg)
    sw = pg.evaluate("[document.documentElement.scrollWidth, window.innerWidth]")
    ok(sw[0] <= sw[1], "360: yana sürüşmə yoxdur", sw)
    hh = pg.evaluate("""() => ['#yGen', '#yNetAll', '#yQrpAll', '#yDiq .mrow', '#yMenu .mrow', '#wkCard [data-wk]']
        .map(s => document.querySelector(s)).filter(Boolean).map(e => [e.id || e.className, Math.round(e.getBoundingClientRect().height)])""")
    ok(hh and min(x[1] for x in hh) >= 44, "360: düymə və keçidlər ≥ 44 px", hh)
    ok(pg.evaluate("getComputedStyle(document.querySelector('#band h1')).fontSize") == "22px", "360: başlıq 22 px (kiçilməyib)")
    if SHOT: pg.screenshot(path=SHOT + "/icmal_360.png", full_page=True)
    br.close()
print("\n" + ("BUTUN YOXLAMALAR KECDI" if not fails else "SEHV (%d): %s" % (len(fails), " | ".join(fails))))
sys.exit(1 if fails else 0)
