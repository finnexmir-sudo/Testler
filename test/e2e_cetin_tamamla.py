#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""«Çətin» seçilib, mövzuda çətin sual azdır (db/937) — Test yığ → vərəq, nümunə hesabda.

  Baza: Az dili 10/11-in yeni faylları (bank 1440–1459) işlənmiş baza lazımdır — orada Az 11-də
  çətin sual 0-dır (canlıdakı kimi).  DB=az11 ./test/tek.sh e2e_cetin_tamamla.py

  A  Az dili · 11 · «İşgüzar sənədlər. Təqdimat» · 10 sual · «Çətin»: ön baxışda «test yığılacaq» +
     qeyd «Bu mövzuda çətin sual azdır — test orta suallarla tamamlanacaq (0 çətin, 10 orta)»
  B  «Suallara bax» → vərəq açılır (əvvəl xəta verirdi), qeyd «… tamamlandı (0 çətin, 10 orta)»;
     bazada: 10 sual, hamısı «orta», hamısı həmin mövzudan
  C  Qeyd yalnız TƏZƏ yığılmış vərəqdədir — vərəq yenidən açılanda yoxdur
  D  Çətin sualı bol mövzuda (riyaziyyat) «Çətin» — qeyd YOXDUR, hamısı 3
  E  Orta sual da yoxdur («Fonetika və leksika»): əvvəlki kimi «yalnız 0 fərqli sual tapıldı»
  F  «Geri» (düymə və brauzer) vərəqdən Test yığ-a qaytarır
  G  390 / 360 / 1280: yana sürüşmə yoxdur; şəkillər (SHOT_DIR)
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

TOPIC = "az-11-isguzar"
t = db("""select t.id::text id, t.name,
                 (select count(*) from public.questions q where q.topic_id = t.id and q.status = 'published' and q.owner_type = 'platform' and q.difficulty = 3) c,
                 (select count(*) from public.questions q where q.topic_id = t.id and q.status = 'published' and q.owner_type = 'platform' and q.difficulty = 2) o
            from public.topics t where t.slug = %s and t.parent_id is null""", (TOPIC,), one=True)
if not t or t["c"] >= 10 or t["o"] < 10:
    print("Baza uygun deyil (Az 11 yeni fayllari islenmeyib?):", t); sys.exit(2)
print("Mövzu: %s — çətin %d, orta %d" % (t["name"], t["c"], t["o"]))
WANT_C = int(t["c"])

def hash_(pg): return pg.evaluate("location.hash")
def sw(pg): return pg.evaluate("[document.documentElement.scrollWidth, window.innerWidth]")

def gen_form(pg, subj, lev, topic_name, count=10, diff=3):
    pg.goto(PANEL + "#/gen"); pg.reload(); pg.wait_for_selector("#btnMake", timeout=20000); pg.wait_for_timeout(800)
    pg.select_option("#gsub", subj); pg.wait_for_timeout(700)
    for c in pg.locator("#gLevs .chip.on").all(): c.click(); pg.wait_for_timeout(200)
    pg.click("#gLevs [data-l='%s']" % lev); pg.wait_for_timeout(1500)
    pg.click("#gTopD > summary"); pg.wait_for_timeout(300)
    pg.locator("#gTop [data-t]", has_text=topic_name).first.click(); pg.wait_for_timeout(300)
    pg.click("#gTopD > summary")
    pg.click("#gCntS [data-c='%d']" % count); pg.wait_for_timeout(500)
    pg.evaluate("document.getElementById('gMore').open = true"); pg.wait_for_timeout(200)
    for c in pg.locator("#gDiff .chip.on").all(): c.click(); pg.wait_for_timeout(200)
    pg.click("#gDiff [data-d='%d']" % diff)
    pg.wait_for_function("document.querySelector('#gPrev .gok, #gPrev .err, #gPrev .warn')", timeout=20000); pg.wait_for_timeout(1200)

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 1280, "height": 900})
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)[:160]))
    pg.goto(PANEL + "#/demo"); pg.wait_for_selector("#demoBar", timeout=60000); pg.wait_for_timeout(2500)
    #  nümunə hesabın fənn süzgəci Az dilini gizlətməsin
    db("update public.accounts set subjects = '{}' where is_demo and id <> app.demo_account()")

    print("A · ön baxış")
    gen_form(pg, "az-dili", "11", t["name"])
    pv = pg.inner_text("#gPrev").replace("\n", " ")
    ok("10 sual yığılacaq" in pv, "test yığılacaq (əvvəl «yalnız N sual tapıldı» idi)", pv)
    ok(pg.locator("#gCetin").count() == 1 and
       ("Bu mövzuda çətin sual azdır — test orta suallarla tamamlanacaq (%d çətin, %d orta)" % (WANT_C, 10 - WANT_C)) in pg.inner_text("#gCetin"),
       "qeyd: «… orta suallarla tamamlanacaq (%d çətin, %d orta)»" % (WANT_C, 10 - WANT_C), pv)
    if SHOT: pg.screenshot(path=SHOT + "/cetin_onbaxis_1280.png", full_page=True)

    print("B · vərəq")
    pg.click("#btnMake"); pg.wait_for_function("location.hash.indexOf('#/t/') === 0", timeout=30000)
    pg.wait_for_selector("#pFill", timeout=20000); pg.wait_for_timeout(500)
    tid = hash_(pg).split("/")[-1]
    ok(("Bu mövzuda çətin sual azdır — test orta suallarla tamamlandı (%d çətin, %d orta)" % (WANT_C, 10 - WANT_C)) in pg.inner_text("#pFill"),
       "vərəqdə qeyd «… tamamlandı»", pg.inner_text("#pFill"))
    r = db("""select count(*) n, count(*) filter (where q.difficulty = 2) o, count(*) filter (where q.difficulty = 3) c,
                     count(distinct q.topic_id) tp, bool_and(q.topic_id = %s::uuid) eyni
                from public.test_questions tq join public.questions q on q.id = tq.question_id where tq.test_id = %s::uuid""", (t["id"], tid), one=True)
    ok(r["n"] == 10 and r["c"] == WANT_C and r["o"] == 10 - WANT_C and r["eyni"], "bazada: 10 sual, %d çətin + %d orta, hamısı həmin mövzudan" % (WANT_C, 10 - WANT_C), dict(r))
    ok(pg.locator("#qFold").evaluate("e => e.open") and "10 sual" in pg.inner_text("#qFold summary"), "suallar açıq, 10 sual")
    if SHOT: pg.screenshot(path=SHOT + "/cetin_vereq_1280.png", full_page=True)

    print("F · Geri")
    pg.click("#btnBack"); pg.wait_for_function("location.hash === '#/gen'", timeout=10000)
    ok(True, "«Geri» düyməsi Test yığ-a qaytardı")
    pg.go_forward(); pg.wait_for_function("location.hash.indexOf('#/t/') === 0", timeout=10000); pg.wait_for_selector("#qFold", timeout=20000)
    pg.go_back(); pg.wait_for_function("location.hash === '#/gen'", timeout=10000)
    ok(True, "brauzerin geri oxu Test yığ-a qaytardı")

    print("C · qeyd yalnız təzə vərəqdə")
    pg.goto(PANEL + "#/t/" + tid); pg.reload(); pg.wait_for_selector("#qFold", timeout=20000); pg.wait_for_timeout(500)
    ok(pg.locator("#pFill").count() == 0, "vərəq yenidən açılanda qeyd yoxdur")

    print("D · çətin sual bol olan mövzu")
    rich = db("""select t.name, l.code from public.topics t join public.subjects s on s.id = t.subject_id join public.levels l on l.id = t.level_id
                  where s.slug = 'riyaziyyat' and t.parent_id is null
                    and (select count(*) from public.questions q where q.topic_id = t.id and q.status = 'published'
                          and q.owner_type = 'platform' and q.difficulty = 3) >= 30
                  order by l.sort, t.sort limit 1""", one=True)
    gen_form(pg, "riyaziyyat", rich["code"], rich["name"])
    ok("10 sual yığılacaq" in pg.inner_text("#gPrev") and pg.locator("#gCetin").count() == 0, "riyaziyyat «%s»: qeyd yoxdur" % rich["name"])
    pg.click("#btnMake"); pg.wait_for_function("location.hash.indexOf('#/t/') === 0", timeout=30000); pg.wait_for_selector("#qFold", timeout=20000)
    t2 = hash_(pg).split("/")[-1]
    ok(pg.locator("#pFill").count() == 0, "vərəqdə qeyd yoxdur")
    r = db("select array_agg(distinct q.difficulty) d from public.test_questions tq join public.questions q on q.id = tq.question_id where tq.test_id = %s::uuid", (t2,), one=True)
    ok(r["d"] == [3], "hamısı çətin", r["d"])

    print("E · orta da yoxdur")
    f0 = db("select t.name from public.topics t where t.slug = 'az-11-fonetika-leksika'", one=True)
    gen_form(pg, "az-dili", "11", f0["name"])
    pv = pg.inner_text("#gPrev").replace("\n", " ")
    ok("fərqli sual tapıldı" in pv and pg.locator("#gCetin").count() == 0, "«%s»: əvvəlki xəta, qeyd yoxdur" % f0["name"], pv)

    print("G · telefon / masaüstü")
    for w in (390, 360):
        pg.set_viewport_size({"width": w, "height": 844})
        gen_form(pg, "az-dili", "11", t["name"])
        s2 = sw(pg); ok(s2[0] <= s2[1] and pg.locator("#gCetin").is_visible(), "%d: ön baxış — qeyd görünür, yana sürüşmə yoxdur" % w, s2)
        if SHOT:
            pg.evaluate("document.getElementById('gPrev').scrollIntoView({block: 'center'})"); pg.wait_for_timeout(300)
            pg.screenshot(path=SHOT + "/cetin_onbaxis_%d.png" % w)
        pg.click("#btnMake"); pg.wait_for_function("location.hash.indexOf('#/t/') === 0", timeout=30000); pg.wait_for_selector("#pFill", timeout=20000)
        pg.wait_for_timeout(400)
        s2 = sw(pg); ok(s2[0] <= s2[1], "%d: vərəq — yana sürüşmə yoxdur" % w, s2)
        if SHOT: pg.screenshot(path=SHOT + "/cetin_vereq_%d.png" % w)
    br.close()

print("\n" + ("BUTUN YOXLAMALAR KECDI" if not fails else "SEHV (%d): %s" % (len(fails), " | ".join(fails))))
sys.exit(1 if fails else 0)
