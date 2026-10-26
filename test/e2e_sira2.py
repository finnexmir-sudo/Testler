#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sıra 2 (UX yoxlaması, 23.10) — hesabatın rəqəmləri bir mənbədən, nümunə hesabda.

  A  Siqnallar «geriləyir (X% → Y%)» → həmin şagirdin kartında gedişat ↘, eyni X və Y
  B  Şagird kartı: «orta · bütün dövr», «son 30 gün» və gedişat; valideyn paneli
     eyni şagird üçün eyni «son 30 gün» rəqəmini və eyni gedişatı göstərir
  C  İcmal «Nəticələr» sətri və Nəticələr ekranı həftə müqayisəsini EYNİ cümlə ilə yazır
  D  Valideynə gedən mətn eyni «son 30 gün» ortasını və gedişatı yazır
SQL tərəfi: db/test/smoke_zeif_movzu.sql (931), smoke_gedisat.sql (932).
"""
import os, re, sys
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

ROOT = "http://127.0.0.1:8010/"
PANEL = ROOT + "muellim/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN = "host=/tmp port=55432 user=postgres dbname=" + os.environ.get("DB", "panel_e2e")
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
    return p

def rstat(pg):
    return pg.evaluate("(document.querySelector('.rstat') || {}).innerText || ''").replace("\n", " ")

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 390, "height": 844})
    pg = page(ctx)
    pg.goto(PANEL + "#/demo"); pg.wait_for_selector("#demoBar", timeout=60000)
    #  26.10: Icmalda «Nəticələr» menyu setri yoxdur - «Yeni nəticələr» karti
    pg.wait_for_selector("#yMenu .ytr", timeout=30000); pg.wait_for_timeout(600)
    acc = db("select id::text i from public.accounts where is_demo and id <> app.demo_account() order by created_at desc limit 1", one=True)

    print("C · Nəticələr ekranı həftə müqayisəsini fərq kimi yazır")
    #  26.10: umumi Icmalda netice yoxdur - cumle yalniz Nəticələr ekranindadir
    pg.goto(PANEL + "#/nt"); pg.wait_for_selector("#ntUst .rstat", timeout=20000)
    nt_txt = pg.inner_text("#ntUst")
    ok(re.search(r"keçən həftəyə görə [+−]\d+ bənd|keçən həftə ilə eyni|son 7 gün: \d+%", nt_txt) is not None, "Nəticələr həftə cümləsini yazır", nt_txt.replace("\n", " ")[:90])
    ok("bütün dövr" in nt_txt and re.search(r"\d+\s*test", nt_txt) and "cavab" not in nt_txt, "Nəticələr: «orta · bütün dövr», say «test» adlanır", nt_txt.replace("\n", " ")[:80])

    print("A · Siqnallar «geriləyir» → şagird kartında eyni gedişat")
    #  nüsxədə «geriləyir» olmaya bilər (təsadüfi toxum) - bir şagirdə 3 aşağı nəticə yazılır
    gs = db("""select s.id::text i from public.students s
                where s.account_id = %s::uuid and s.is_active
                  and (select count(*) from public.attempts a where a.student_id = s.id and a.status = 'submitted') >= 4
                order by s.full_name limit 1""", (acc["i"],), one=True)
    for k in range(3):
        db("""insert into public.attempts (test_id, student_id, class_id, status, percent, score, max_score, finished_at)
              select a.test_id, a.student_id, a.class_id, 'submitted', 10, 1, 10, now() - (%s || ' minutes')::interval
                from public.attempts a where a.student_id = %s::uuid order by a.finished_at desc limit 1""", (str(k + 1), gs["i"]))
    pg.goto(PANEL + "#/n"); pg.wait_for_selector("button.al", timeout=20000); pg.wait_for_timeout(400)
    risk = pg.locator("button.al.risk").first
    if risk.count() == 0:
        ok(False, "nümunədə «geriləyir» siqnalı var")
    else:
        rt = risk.inner_text().replace("\n", " ")
        mm = re.search(r"\((\d+)% → (\d+)%\)", rt)
        sid = risk.get_attribute("data-al"); cid = risk.get_attribute("data-g")
        pg.goto(PANEL + "#/s/" + sid + "/" + cid); pg.wait_for_selector(".rstat", timeout=20000); pg.wait_for_timeout(400)
        rs = rstat(pg)
        ok(mm and ("son 3 test %s%%" % mm.group(2)) in rs and ("test %s%%" % mm.group(1)) in rs and "↘" in rs,
           "kartda «↘ … son 3 test Y% · əvvəlki N test X%» — Siqnaldakı X və Y", rt[:70] + " | " + rs)

    print("B · Şagird kartı və valideyn paneli: eyni «son 30 gün», eyni gedişat")
    st = db("""select s.id::text i, s.class_id::text c, s.parent_code p from public.students s
                where s.account_id = %s::uuid and s.parent_code is not null limit 1""", (acc["i"],), one=True)
    pg.goto(PANEL + "#/s/" + st["i"] + "/" + st["c"]); pg.wait_for_selector(".rstat", timeout=20000); pg.wait_for_timeout(400)
    rs = rstat(pg)
    ok("orta · bütün dövr" in rs, "orta bütün dövr kimi yazılır", rs)
    m30 = re.search(r"(\d+)%\s*(?:orta · )?son 30 gün", rs)   #  23.10: «74% orta · son 30 gün» (Xülasə kartı)
    mtr = re.search(r"son 3 test (\d+)% · əvvəlki (\d+) test (\d+)%", rs)
    pv = page(ctx)
    pv.goto(ROOT + "valideyn/?kod=" + st["p"]); pv.wait_for_selector(".card.sum", timeout=30000); pv.wait_for_timeout(500)
    vt = pv.inner_text(".card.sum").replace("\n", " ")
    mv = re.search(r"^(\d+)%", vt.strip())
    ok(m30 and mv and m30.group(1) == mv.group(1), "«son 30 gün» müəllimdə və valideyndə eynidir", "%s / %s" % (m30 and m30.group(1), mv and mv.group(1)))
    if mtr:
        ok(("Son 3 testdə %s%%" % mtr.group(1)) in vt and ("əvvəlki %s test" % mtr.group(2)) in vt,
           "valideyn eyni gedişatı yazır (son 3 test, əvvəlki N test)", vt[:120])
    else:
        ok("ən azı 4 test" in vt, "az testdə valideyn də müqayisə göstərmir", vt[:120])
    for w, h in ((390, 844), (1280, 900)):
        pg.set_viewport_size({"width": w, "height": h}); pv.set_viewport_size({"width": w, "height": h}); pg.wait_for_timeout(300)
        if os.environ.get("SHOT_DIR"):
            pg.screenshot(path="%s/kart_%d.png" % (os.environ["SHOT_DIR"], w)); pv.screenshot(path="%s/valideyn_%d.png" % (os.environ["SHOT_DIR"], w))
    pv.close()

    print("E · Şagird kartı: «ilkin nəticə», səhv sayı Səhvlər sekməsi ilə eyni")
    pg.set_viewport_size({"width": 390, "height": 844})
    xt = pg.inner_text("#tab-x") if pg.locator("#tab-x").count() else ""
    m6 = re.search(r"(\d+) səhv düzəliş gözləyir(?: · (\d+) təkrarda)?", xt)
    pg.locator("#sTabs [data-v='s'], #sTabs .seg").nth(2).click(); pg.wait_for_timeout(500)
    st_txt = pg.inner_text("#tab-s")
    m7 = re.search(r"(\d+)\s*gözləyir\s*(\d+)\s*təkrarda", st_txt.replace("\n", " "))
    ok(m6 and m7 and m6.group(1) == m7.group(1) and (m6.group(2) or "0") == m7.group(2),
       "Xülasədə «N gözləyir · M təkrarda» Səhvlər sekməsi ilə eynidir",
       "%s | %s" % (m6.group(0) if m6 else xt[:60], m7.group(0) if m7 else st_txt[:60]))
    pg.locator("#sTabs .seg").nth(1).click(); pg.wait_for_timeout(500)
    rows = pg.evaluate("""[...document.querySelectorAll('#tab-m .trow')].map(r => r.innerText.replace(/\\n/g, ' '))""")
    az = [x for x in rows if re.search(r"· (\d+) / ([1-4])\b", x)]
    ok(all("ilkin nəticə" in x for x in az) and all("ilkin nəticə" not in x for x in rows if x not in az),
       "4 və az cavablı mövzu «ilkin nəticə · N sual · tarix», qalanı yox", "%d ilkin / %d sətir" % (len(az), len(rows)))

    print("F · Qrup hesabatı: Şagirdlər ən zəifdən; qrup siyahısında say «test»")
    pg.goto(PANEL + "#/r/" + st["c"]); pg.wait_for_selector("#rTabs, .segs", timeout=20000); pg.wait_for_timeout(800)
    pcs = pg.evaluate("""[...document.querySelectorAll('button.mrow[data-s] .pctv')].map(e => e.innerText.trim())""")
    nums = [int(x.rstrip('%')) for x in pcs if x.rstrip('%').isdigit()]
    ok(len(nums) >= 3 and nums == sorted(nums), "hesabatda şagirdlər faizə görə artan sıradadır", nums[:8])
    pg.goto(PANEL + "#/g/" + st["c"] + "/s"); pg.wait_for_selector("#stu a.mrow", timeout=20000)
    gl = pg.inner_text("#stu")
    ok(" test" in gl and " cavab" not in gl, "qrupun şagird siyahısında «N test» (cavab yox)")

    print("G · Siqnallar ekranı: «geriləyir» ən böyük düşüşdən")
    pg.goto(PANEL + "#/n"); pg.wait_for_selector("button.al", timeout=20000); pg.wait_for_timeout(400)
    drops = [int(a) - int(b) for a, b in re.findall(r"geriləyir \((\d+)% → (\d+)%\)", pg.inner_text("body"))]
    ok(drops == sorted(drops, reverse=True), "«geriləyir» siqnalları düşüşə görə azalan sıradadır", drops)

    print("D · Valideynə gedən mətn eyni rəqəmləri yazır")
    pg.set_viewport_size({"width": 390, "height": 844})
    #  23.10: reqem setri Xulase sekmesindedir - sekme sessiya boyu yadda qalir, ona gore Xulase acilir
    pg.goto(PANEL + "#/s/" + st["i"] + "/" + st["c"]); pg.wait_for_selector("#sTabs", timeout=20000)
    pg.locator("#sTabs [data-v='x']").click(); pg.wait_for_selector(".rstat", timeout=20000); pg.wait_for_timeout(600)
    txt = pg.evaluate("(document.getElementById('vTxt') || {}).value || (document.getElementById('vTxt') || {}).textContent || ''")
    if m30 and txt:
        ok(("Ortalama: %s%%" % m30.group(1)) in txt or ("Ortalama nəticə: %s%%" % m30.group(1)) in txt,
           "mətndəki ortalama «son 30 gün» rəqəmidir", txt.replace("\n", " ")[:120])
    else:
        ok(bool(txt), "valideyn mətni var")
    br.close()

print()
if fails:
    print("SINDI (%d):" % len(fails))
    for f in fails: print("  - " + f)
    sys.exit(1)
print("HAMISI KECDI")
