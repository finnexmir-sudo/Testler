#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sekil NETICE ekraninda ve MUELLIM HESABATINDA (db/900).

db/188 sekli sual ekranina cixardi, amma neticeye ve hesabata YOX -
onlar sual metnini anliq nusxeden (attempt_answers) goturur.  900
hemin uc RPC-ni suala qosur.

Niye ayrica test: bura GORUNMEYEN axindir.  Sekil dususe hec bir xeta
olmur - sagird sadece qrafiksiz «Sen yazdin: 1-ci qrafik» oxuyur.

Yoxlanir:
  A  testi bitirende netice ekraninda sekil <img> kimi cixir
  B  sonradan baxanda (rpc_test_result) sekil YENE cixir
  C  sekilsiz sualda bos yer / sinix sekil yoxdur
  D  SVG innerHTML-e dusmur - yalniz <img>
  E  muellim hesabatinda «Sehvler» sekmesinde sekil var
"""
import sys
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

ROOT = "http://127.0.0.1:8010/"
APP = ROOT + "sagird/index.html"
PANEL = ROOT + "muellim/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
BLOCK = "**://*.supabase.co/**"
CFG = """window.CFG = {SUPABASE_URL:"http://127.0.0.1:54321",
  SUPABASE_ANON_KEY:"test-anon-key", STUDENT_URL:"http://127.0.0.1:8010/sagird/",
  SHOW_PLANS:false};"""
SVG = ('<svg viewBox="0 0 200 130"><path d="M20 110 L180 20" fill="none" '
       'stroke="#087f75" stroke-width="4"/>'
       '<text x="24" y="124" font-family="sans-serif" font-size="13">artan</text></svg>')

fails = []
def ok(cond, label, extra=""):
    print(("  OK   " if cond else "  FAIL ") + label + (("  " + str(extra)) if extra else ""),
          flush=True)
    if not cond: fails.append(label)

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            return cur.fetchone() if one else cur.fetchall()

db("""
delete from public.question_reports; delete from public.mistakes;
delete from public.attempt_answers;  delete from public.attempts;
delete from public.assignments;      delete from public.student_sessions;
delete from public.students;         delete from public.class_plan_items;
delete from public.class_plans;      delete from public.classes;
delete from public.test_questions tq using public.tests t
 where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.subscriptions;
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from auth.users;
""")
if not db("select 1 from public.tests where owner_type='platform' limit 1", one=True):
    db(open("db/07_seed_tests.sql", encoding="utf-8").read())

#  Platforma testinin suallari: BIRINCISINE sekil qoyulur, o birilerine YOX.
#  Ikisi bir ekranda olsun deye - «sekilsizde bos yer cixmir» iddiasi
#  ancaq bele yoxlanila biler.
QIDS = [r["i"] for r in db("""select q.id::text i from public.questions q
            join public.test_questions tq on tq.question_id = q.id
            join public.tests t on t.id = tq.test_id and t.slug = 'riy-3-vurma-1'
           order by tq.ord""")]
db("update public.questions set media_url = null where id = any(%s::uuid[])", (QIDS,))
db("update public.questions set media_url = app.svg_uri(%s) where id = %s::uuid",
   (SVG, QIDS[0]))
QBODY = db("select body b from public.questions where id = %s::uuid", (QIDS[0],), one=True)["b"]
print("A · Hazırlıq: %d sualdan 1-i şəkilli" % len(QIDS))
ok(len(QIDS) >= 2, "testde en azi 2 sual var (sekilli + sekilsiz)", len(QIDS))

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])

    # ---- muellim qeydiyyati: hesabati onun adindan acacagiq ----------
    ctx = br.new_context(viewport={"width": 1280, "height": 900})
    mp = ctx.new_page()
    mp.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=CFG))
    mp.on("pageerror", lambda e: fails.append("JS xetasi (panel): " + str(e)))
    mp.goto(PANEL); mp.wait_for_timeout(500)
    mp.click("#btnSwap")
    mp.fill("#fname", "Qrafik Muellim"); mp.fill("#email", "qrafik@t.az")
    mp.fill("#pass", "qrafikparol1"); mp.click("#btnAuth")
    mp.wait_for_selector("#btnSetup", timeout=20000)
    mp.select_option("#atype", "tutor"); mp.fill("#aname", "Qrafik hesabi")
    mp.click("#btnSetup"); mp.wait_for_selector("#gForm", timeout=20000)

    acc = db("""select a.id::text i from public.accounts a
                 join auth.users u on u.id = a.owner_id where u.email = 'qrafik@t.az'""",
             one=True)["i"]
    uid = db("select id::text i from auth.users where email='qrafik@t.az'", one=True)["i"]
    #  'weak' siyahisi YALNIZ odenisli hesabda qayidir (db/133)
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select %s::uuid, p.id, 'active', now() + interval '30 days'
            from public.plans p where p.slug = 'repetitor-25'""", (acc,))
    cls = db("""insert into public.classes (account_id, teacher_id, kind, name, join_code)
                values (%s::uuid, %s::uuid, 'tutor_group', 'Qrafik qrup', 'QRAFIK01')
                returning id::text i""", (acc, uid), one=True)["i"]
    stu = db("""insert into public.students (account_id, class_id, created_by, full_name,
                                             display_name, login_code)
                values (%s::uuid, %s::uuid, %s::uuid, 'Nurlan Qrafik', 'Nurlan Q.', 'QRAFKOD1')
                returning id::text i""", (acc, cls, uid), one=True)["i"]
    tid = db("select id::text i from public.tests where slug = 'riy-3-vurma-1'", one=True)["i"]
    db("""insert into public.assignments (test_id, class_id, assigned_by, opens_at)
          values (%s::uuid, %s::uuid, %s::uuid, now() - interval '1 hour')""", (tid, cls, uid))

    # ---- sagird: testi yazir, HAMISINA SEHV cavab verir --------------
    sctx = br.new_context(viewport={"width": 390, "height": 844})
    pg = sctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi (sagird): " + str(e)))
    pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))

    print("B · Şagird testi yazır və bitirir")
    pg.goto(APP); pg.wait_for_selector("#btnIn", timeout=15000)
    pg.fill("#code", "QRAFKOD1"); pg.click("#btnIn")
    pg.wait_for_selector(".test", timeout=15000)
    pg.locator(".test:not(.lock)", has_text="Vurma cədvəli").first.click()
    pg.wait_for_selector(".opt", timeout=15000)
    #  HER sualda SEHV variant secilir - weak siyahisi dolsun ve
    #  sekilli sual netice ekraninda «sehvler» hissesine dussun.
    KEY = {r["o"] for r in db("""select o.id::text o from public.question_options o
              join public.questions q on q.id = o.question_id and o.is_correct
              join public.test_questions tq on tq.question_id = q.id
              join public.tests t on t.id = tq.test_id
             where t.slug = 'riy-3-vurma-1'""")}
    NQ = len(QIDS)
    for i in range(NQ):
        ids = pg.locator(".opt").evaluate_all("els => els.map(e => e.getAttribute('data-o'))")
        wrong = next(o for o in ids if o not in KEY)
        pg.locator("[data-o='%s']" % wrong).click(); pg.wait_for_timeout(90)
        if i + 1 < NQ:
            pg.click("#btnNext")
        else:
            pg.once("dialog", lambda d: d.accept()); pg.click("#btnFinish")
        pg.wait_for_timeout(140)
    pg.wait_for_selector("#wrongBox", timeout=20000)

    print("C · Nəticə ekranı (təzə bitirmə)")
    n_fig = pg.locator("#wrongBox .qfig img").count()
    ok(n_fig == 1, "neticede TEK sekil var (sekilli sual)", n_fig)
    src = (pg.locator("#wrongBox .qfig img").first.get_attribute("src") or "") if n_fig else ""
    ok(src.startswith("data:image/svg+xml,"), "unvan data-URI-dir", src[:46])
    w = pg.evaluate("() => { const i = document.querySelector('#wrongBox .qfig img');"
                    " return i ? i.naturalWidth : 0; }")
    ok(w > 0, "brauzer sekli acdi (sinix deyil)", w)
    box = pg.locator("#wrongBox .qfig img").first.bounding_box() if n_fig else None
    ok(box and box["width"] <= 390, "telefonda enden asmir", box and round(box["width"]))
    nsvg = pg.evaluate("() => document.querySelectorAll('#wrongBox .qfig svg').length")
    ok(nsvg == 0, "SVG innerHTML-e dusmur (yalniz <img>)", nsvg)
    #  Bos hal: sekilsiz sual setirlerinde .qfig ELEMENTI hec yaranmir
    nrow = pg.locator("#wrongBox > div").count()
    nqfig = pg.locator("#wrongBox .qfig").count()
    ok(nrow >= 2 and nqfig == 1,
       "sekilsiz suallarda .qfig yaranmir (bos yer yox)", "%d setir / %d qfig" % (nrow, nqfig))
    pg.screenshot(path="/tmp/claude-0/sekil/netice_telefon.png", full_page=True)

    print("D · Sonradan baxış (rpc_test_result)")
    pg.goto(APP); pg.wait_for_selector(".test", timeout=15000)
    pg.locator(".test", has_text="Vurma cədvəli").first.click()
    pg.wait_for_selector("#wrongBox", timeout=20000)
    n2 = pg.locator("#wrongBox .qfig img").count()
    ok(n2 == 1, "baxis rejiminde de sekil var - «iki yerde eyni RPC» telesi", n2)
    src2 = (pg.locator("#wrongBox .qfig img").first.get_attribute("src") or "") if n2 else ""
    ok(src2 and src2 == src, "eyni sekildir", src2[:30])
    sctx.close()

    #  Masaustu olcu - ekran sekli ucun
    dctx = br.new_context(viewport={"width": 1280, "height": 900})
    dp = dctx.new_page()
    dp.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=CFG))
    dp.goto(APP); dp.wait_for_selector("#btnIn", timeout=15000)
    dp.fill("#code", "QRAFKOD1"); dp.click("#btnIn")
    dp.wait_for_selector(".test", timeout=15000)
    dp.locator(".test", has_text="Vurma cədvəli").first.click()
    dp.wait_for_selector("#wrongBox", timeout=20000)
    ok(dp.locator("#wrongBox .qfig img").count() == 1, "masaustunde de sekil var")
    dp.screenshot(path="/tmp/claude-0/sekil/netice_masaustu.png", full_page=True)
    dctx.close()

    print("E · Müəllim hesabatı — «Səhvlər» sekmesi")
    mp.goto(PANEL + "#/s/" + stu + "/" + cls)
    mp.wait_for_selector("#sTabs", timeout=20000)
    mp.locator('#sTabs .seg[data-v="s"]').click()
    mp.wait_for_selector("#tab-s .wq", timeout=20000)
    #  Siyahi ilk 5 setri gosterir (WCAP), qalani «Daha ... sual goster»
    #  arxasindadir.  Sekilli sual altda ola biler - acmasaq olcu 0 cixir.
    if mp.locator("#wMore").count():
        mp.click("#wMore"); mp.wait_for_timeout(300)
    nw = mp.locator("#tab-s .wq .qfig img").count()
    ok(nw >= 1, "hesabatda sekil var", nw)
    srcw = (mp.locator("#tab-s .wq .qfig img").first.get_attribute("src") or "") if nw else ""
    ok(srcw.startswith("data:image/svg+xml,"), "hesabatda da data-URI", srcw[:46])
    ok(mp.evaluate("() => document.querySelectorAll('#tab-s .wq .qfig svg').length") == 0,
       "hesabatda da yalniz <img>")
    ok(mp.locator("#tab-s .wq .qfig img").first.is_visible(), "sekil gorunur (gizli setirde deyil)")
    hh = mp.evaluate("() => { const i = document.querySelector('#tab-s .wq .qfig img');"
                     " return i ? i.getBoundingClientRect().height : 0; }")
    ok(0 < hh <= 120, "siyahida sekil yigcamdir (<=110px qaydasi)", round(hh))
    nwq = mp.locator("#tab-s .wq").count()
    ok(mp.locator("#tab-s .wq .qfig").count() == 1,
       "sekilsiz sehv setirlerinde .qfig yoxdur", "%d setir" % nwq)
    mp.screenshot(path="/tmp/claude-0/sekil/hesabat_masaustu.png", full_page=True)

    mctx = br.new_context(viewport={"width": 390, "height": 844})
    m2 = mctx.new_page()
    m2.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=CFG))
    m2.goto(PANEL); m2.wait_for_timeout(600)
    m2.fill("#email", "qrafik@t.az"); m2.fill("#pass", "qrafikparol1"); m2.click("#btnAuth")
    m2.wait_for_timeout(2500)
    m2.goto(PANEL + "#/s/" + stu + "/" + cls); m2.wait_for_selector("#sTabs", timeout=20000)
    m2.locator('#sTabs .seg[data-v="s"]').click()
    m2.wait_for_selector("#tab-s .wq", timeout=20000)
    if m2.locator("#wMore").count():
        m2.click("#wMore"); m2.wait_for_timeout(300)
    ok(m2.locator("#tab-s .wq .qfig img").count() >= 1, "telefonda da hesabatda sekil var")
    ok(m2.locator("#tab-s .wq .qfig img").first.is_visible(), "telefonda sekil gorunur")
    mb = m2.locator("#tab-s .wq .qfig img").first.bounding_box()
    ok(mb and mb["width"] <= 390, "telefonda enden asmir", mb and round(mb["width"]))
    m2.locator("#tab-s .wq .qfig img").first.scroll_into_view_if_needed()
    m2.wait_for_timeout(200)
    m2.screenshot(path="/tmp/claude-0/sekil/hesabat_telefon.png", full_page=True)
    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails))
    for f in fails: print("  - " + f)
    sys.exit(1)
print("NETICE SEKLI: BUTUN YOXLAMALAR KECDI")
