#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Test səviyyəsi «Qarışıq / Daha asan / Daha çətin» (db/937) — Test yığ → vərəq, nümunə hesabda.

  Baza: Az dili 10/11-in yeni faylları (bank 1440–1459) işlənmiş baza — Az 11-də çətin sual 0-dır.
      DB=az11 ./test/tek.sh e2e_test_seviyyesi.py

  A  «Əlavə seçimlər»də «Səviyyə»: Qarışıq (seçili) / Daha asan / Daha çətin; köhnə «Çətinlik» düymələri yoxdur
  B  Az 11 «İşgüzar sənədlər» (0 çətin, 23 orta) · 10 · «Daha çətin»: ön baxışda «10 sual yığılacaq» +
     «Testdə: 0 çətin, 10 orta, 0 asan»; xəbərdarlıq / boz düymə yoxdur
  C  «Suallara bax» → vərəq: «Testdə: 0 çətin, 10 orta, 0 asan»; bazada hamısı orta, həmin mövzudan
  D  «Fonetika və leksika» (0 çətin, 0 orta, 23 asan) · «Daha çətin»: test YIĞILIR — 10 asan
  E  «Daha asan» «İşgüzar»: 10 asan (asan 25); «Qarışıq»: ön baxışda tərkib yazılmır, vərəqdə yazılır, cəmi 10
  F  «Geri» düyməsi və brauzerin geri oxu vərəqdən Test yığ-a
  G  390 / 360 / 1280: yana sürüşmə yoxdur, seqment düymələri ≥ 44 px; şəkillər (SHOT_DIR)
"""
import os, sys, re
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

def topic(slug):
    return db("""select t.id::text id, t.name,
                   count(*) filter (where q.difficulty = 3) c, count(*) filter (where q.difficulty = 2) o,
                   count(*) filter (where q.difficulty = 1) a
              from public.topics t left join public.questions q on q.topic_id = t.id and q.status = 'published' and q.owner_type = 'platform'
             where t.slug = %s and t.parent_id is null group by t.id, t.name""", (slug,), one=True)
ISG, FON = topic("az-11-isguzar"), topic("az-11-fonetika-leksika")
if not ISG or ISG["c"] > 0 or ISG["o"] < 10 or not FON or FON["c"] + FON["o"] > 0 or FON["a"] < 10:
    print("Baza uygun deyil (Az 11 yeni fayllari islenmeyib?):", ISG, FON); sys.exit(2)
print("Mövzular:", dict(ISG), dict(FON))

def hash_(pg): return pg.evaluate("location.hash")
def sw(pg): return pg.evaluate("[document.documentElement.scrollWidth, window.innerWidth]")
def mix(tid):
    r = db("""select count(*) filter (where q.difficulty = 3) c, count(*) filter (where q.difficulty = 2) o,
                     count(*) filter (where q.difficulty = 1) a, count(*) n, bool_and(q.topic_id = (select topic_id from public.questions q2
                       join public.test_questions t2 on t2.question_id = q2.id where t2.test_id = %s::uuid limit 1)) eyni
                from public.test_questions tq join public.questions q on q.id = tq.question_id where tq.test_id = %s::uuid""", (tid, tid), one=True)
    return (r["c"], r["o"], r["a"], r["n"], r["eyni"])

def gen_form(pg, name, mode, count=10):
    pg.goto(PANEL + "#/gen"); pg.reload(); pg.wait_for_selector("#btnMake", timeout=20000); pg.wait_for_timeout(800)
    pg.select_option("#gsub", "az-dili"); pg.wait_for_timeout(700)
    for c in pg.locator("#gLevs .chip.on").all(): c.click(); pg.wait_for_timeout(200)
    pg.click("#gLevs [data-l='11']"); pg.wait_for_timeout(1500)
    pg.click("#gTopD > summary"); pg.wait_for_timeout(300)
    pg.locator("#gTop [data-t]", has_text=name).first.click(); pg.wait_for_timeout(300)
    pg.click("#gTopD > summary")
    pg.click("#gCntS [data-c='%d']" % count); pg.wait_for_timeout(500)
    pg.evaluate("document.getElementById('gMore').open = true"); pg.wait_for_timeout(200)
    pg.click("#gMode [data-v='%s']" % mode)
    pg.wait_for_function("document.querySelector('#gPrev .gok, #gPrev .err, #gPrev .warn')", timeout=20000); pg.wait_for_timeout(1300)

def make(pg):
    pg.click("#btnMake"); pg.wait_for_function("location.hash.indexOf('#/t/') === 0", timeout=30000)
    pg.wait_for_selector("#pMix", timeout=20000); pg.wait_for_timeout(400)
    return hash_(pg).split("/")[-1]

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 1280, "height": 900})
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)[:160]))
    pg.goto(PANEL + "#/demo"); pg.wait_for_selector("#demoBar", timeout=60000); pg.wait_for_timeout(2500)
    db("update public.accounts set subjects = '{}' where is_demo and id <> app.demo_account()")

    print("A · Səviyyə seçimi")
    pg.goto(PANEL + "#/gen"); pg.reload(); pg.wait_for_selector("#btnMake", timeout=20000); pg.wait_for_timeout(600)
    pg.evaluate("document.getElementById('gMore').open = true"); pg.wait_for_timeout(200)
    labels = pg.locator("#gMode [data-v]").all_inner_texts()
    ok([x.strip() for x in labels] == ["Qarışıq", "Daha asan", "Daha çətin"], "Qarışıq / Daha asan / Daha çətin", labels)
    ok(pg.locator("#gMode [data-v='mixed'].on").count() == 1, "susmaya görə «Qarışıq»")
    ok(pg.locator("#gDiff").count() == 0, "köhnə «Çətinlik» düymələri yoxdur")

    print("B · «Daha çətin» — çətin sual 0 olan mövzu")
    gen_form(pg, ISG["name"], "harder")
    pv = pg.inner_text("#gPrev").replace("\n", " ")
    ok("10 sual yığılacaq" in pv and pg.locator("#gPrev .err, #gPrev .warn").count() == 0, "test yığılacaq, xəbərdarlıq yoxdur", pv)
    ok(pg.inner_text("#gMix").strip() == "Testdə: 0 çətin, 10 orta, 0 asan.", "ön baxış: «Testdə: 0 çətin, 10 orta, 0 asan»", pg.inner_text("#gMix"))
    ok("daha çətin" in pg.inner_text("#gMoreSum") and "Əvvəl çətin suallar" in pg.inner_text("#gModeHint"), "«Əlavə seçimlər» sətri və izah", pg.inner_text("#gMoreSum"))
    if SHOT:
        pg.evaluate("document.getElementById('gMode').scrollIntoView({block: 'center'})"); pg.wait_for_timeout(300)
        pg.screenshot(path=SHOT + "/sev_onbaxis_1280.png")

    print("C · vərəq")
    tid = make(pg)
    ok(pg.inner_text("#pMix").strip() == "Testdə: 0 çətin, 10 orta, 0 asan", "vərəqdə tərkib", pg.inner_text("#pMix"))
    ok(mix(tid) == (0, 10, 0, 10, True), "bazada: 10 orta, hamısı həmin mövzudan", mix(tid))
    if SHOT: pg.screenshot(path=SHOT + "/sev_vereq_1280.png")

    print("F · Geri")
    pg.click("#btnBack"); pg.wait_for_function("location.hash === '#/gen'", timeout=10000)
    pg.wait_for_selector("#gMode [data-v]", state="attached", timeout=20000); pg.wait_for_timeout(500)
    ok(pg.evaluate("document.querySelector('#gMode [data-v=\"harder\"]').classList.contains('on')"), "«Geri» Test yığ-a, «Daha çətin» seçili qalıb")
    pg.go_forward(); pg.wait_for_function("location.hash.indexOf('#/t/') === 0", timeout=10000); pg.wait_for_selector("#pMix", timeout=20000)
    pg.go_back(); pg.wait_for_function("location.hash === '#/gen'", timeout=10000)
    ok(True, "brauzerin geri oxu Test yığ-a qaytardı")

    print("D · «Daha çətin» — çətin də, orta da yoxdur")
    gen_form(pg, FON["name"], "harder")
    ok(pg.inner_text("#gMix").strip() == "Testdə: 0 çətin, 0 orta, 10 asan.", "ön baxış: 10 asan (test yığılır)", pg.inner_text("#gPrev").replace("\n", " "))
    tid = make(pg)
    ok(mix(tid)[:4] == (0, 0, 10, 10), "vərəq: 10 asan", mix(tid))

    print("E · «Daha asan» və «Qarışıq»")
    gen_form(pg, ISG["name"], "easier")
    tid = make(pg)
    exp_a = min(10, ISG["a"])
    ok(mix(tid)[:4] == (0, 10 - exp_a, exp_a, 10) and pg.inner_text("#pMix").strip() == "Testdə: 0 çətin, %d orta, %d asan" % (10 - exp_a, exp_a),
       "«Daha asan»: əvvəl asan", mix(tid))
    gen_form(pg, ISG["name"], "mixed")
    ok(pg.locator("#gMix").count() == 0 and "10 sual yığılacaq" in pg.inner_text("#gPrev"), "«Qarışıq»: ön baxışda tərkib yazılmır")
    tid = make(pg)
    c, o, a, n, _ = mix(tid)
    ok(n == 10 and pg.inner_text("#pMix").strip() == "Testdə: %d çətin, %d orta, %d asan" % (c, o, a), "«Qarışıq»: vərəqdə faktiki tərkib (%d/%d/%d)" % (c, o, a))

    print("G · telefon / masaüstü")
    for w in (390, 360):
        pg.set_viewport_size({"width": w, "height": 844})
        gen_form(pg, ISG["name"], "harder")
        s2 = sw(pg); hh = pg.evaluate("[...document.querySelectorAll('#gMode [data-v]')].map(e => Math.round(e.getBoundingClientRect().height))")
        ok(s2[0] <= s2[1] and min(hh) >= 44, "%d: Test yığ — yana sürüşmə yoxdur, seqment ≥ 44 px" % w, [s2, hh])
        if SHOT:
            pg.evaluate("document.getElementById('gMode').scrollIntoView({block: 'start'})"); pg.wait_for_timeout(300)
            pg.screenshot(path=SHOT + "/sev_onbaxis_%d.png" % w)
        make(pg)
        s2 = sw(pg); ok(s2[0] <= s2[1], "%d: vərəq — yana sürüşmə yoxdur" % w, s2)
        if SHOT: pg.screenshot(path=SHOT + "/sev_vereq_%d.png" % w)
    br.close()

print("\n" + ("BUTUN YOXLAMALAR KECDI" if not fails else "SEHV (%d): %s" % (len(fails), " | ".join(fails))))
sys.exit(1 if fails else 0)
