#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Cox setirli sual metni MUELLIM ekranlarinda setirlerini saxlayir.

Bankda proqram kodu olan suallar cixir:  «Proqram:\\n    if tip == "x":»
Sagird tetbiqinde duz gorunur (sagird/app.css: .q .body{white-space:pre-wrap}).
Muellim panelinde white-space verilmeyen yerde setirler BIRLESIR ve kod
yeniden sehv sintaksis kimi gorunur.

Olcu usulu: innerText.  Brauzer onu EKRANDA GORUNDUYU kimi qaytarir -
white-space normaldirsa setir sonlari bosluga cevrilir, pre-wrap-dirsa
qalir.  Yeni bu, CSS-in ozunu yox, NETICENI yoxlayir.

Yoxlanan yerler (muellim/app.js):
  A  :9468  cavab vereqi / test onizleme  (.paper .qh b)
  B  :9223  cap                           (#printBox .ppb)
  C  :5955  sagird hesabati - cavab vereqi (.shq > b)
  D  :10166 bank siyahisi                 (.qrow .g b)
  E  :10066 bankdan numune suallar        (.smp .sq b)
  F  :5765  hesabatda sehv edilen suallar (.wq b)
"""
import sys
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

ROOT = "http://127.0.0.1:8010/"
PANEL = ROOT + "muellim/index.html"
APP = ROOT + "sagird/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
CFG = """window.CFG = {SUPABASE_URL:"http://127.0.0.1:54321",
  SUPABASE_ANON_KEY:"test-anon-key", STUDENT_URL:"http://127.0.0.1:8010/sagird/",
  SHOW_PLANS:false};"""

#  Dord bosluqla abzas - kodun menasi ondadir.
KOD = ('Proqram nə çap edir?\n'
       'tip = "x"\n'
       'if tip == "x":\n'
       '    s = 1\n'
       '    s = s + 2\n'
       'print(s)')

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

def setirli(pg, sel, ad):
    """Ekranda GORUNEN metn: setir sonlari ve abzas qalibmi?

    Elementi MEZMUNUNA gore secirik, birinci uygun geleni yox: eyni
    siyahida tek setirlik sual da var, birinci elementi olcmek bir
    defe YALANCI netice verdi (ne FAIL, ne OK - sehv sual olculurdu)."""
    t = pg.evaluate(
        "s => { const els = [...document.querySelectorAll(s)];"
        "       const e = els.find(x => (x.textContent || '').indexOf('if tip') >= 0);"
        "       return e ? e.innerText : null; }", sel)
    if t is None:
        ok(False, ad + " - kod suali tapilmadi", sel); return
    nl = t.count("\n")
    abzas = "\n    " in t or "\n " in t
    ok(nl >= 4, ad + " - setir sonlari qalir", "%d setir sonu" % nl)
    ok(abzas, ad + " - 4 bosluq abzas qalir", repr(t[t.find("if tip"):][:34]))

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
delete from public.question_options o using public.questions q
 where q.id = o.question_id and q.topic_id in (select id from public.topics where slug = 'kod-setir');
delete from public.questions where topic_id in (select id from public.topics where slug = 'kod-setir');
delete from public.topics where slug = 'kod-setir';
""")

#  Kod suali PLATFORMA suali kimi qurulur - bank siyahisi ve numuneler
#  platforma hovuzundan gelir.
INF = db("select id::text i from public.subjects where slug = 'informatika'", one=True)
SUBJ = INF["i"] if INF else db("select id::text i from public.subjects limit 1", one=True)["i"]
LEV = db("select id::text i, code c from public.levels order by sort limit 1", one=True)
PRG = db("select id::text i from public.programs where slug = 'ibtidai'", one=True)["i"]
TOP = db("""insert into public.topics (subject_id, level_id, parent_id, name, slug, sort)
            values (%s::uuid, %s::uuid, null, 'Kod sətirləri (sınaq)', 'kod-setir', 993)
            returning id::text i""", (SUBJ, LEV["i"]), one=True)["i"]
QID = db("""insert into public.questions (owner_type, subject_id, level_id, topic_id,
                                          kind, body, status, points)
            values ('platform', %s::uuid, %s::uuid, %s::uuid, 'single', %s, 'published', 1)
            returning id::text i""", (SUBJ, LEV["i"], TOP, KOD), one=True)["i"]
db("""insert into public.question_options (question_id, ord, body, is_correct) values
      (%s::uuid, 1, '3', true), (%s::uuid, 2, '1', false)""", (QID, QID))
#  Ikinci, tek setirli sual: siyahida qonsu setir pozulmasin
QID2 = db("""insert into public.questions (owner_type, subject_id, level_id, topic_id,
                                           kind, body, status, points)
             values ('platform', %s::uuid, %s::uuid, %s::uuid, 'single',
                     'Bir sətirlik adi sual?', 'published', 1)
             returning id::text i""", (SUBJ, LEV["i"], TOP), one=True)["i"]
db("""insert into public.question_options (question_id, ord, body, is_correct) values
      (%s::uuid, 1, 'Bəli', true), (%s::uuid, 2, 'Xeyr', false)""", (QID2, QID2))
print("A · Hazırlıq: %d sətirlik kod sualı" % (KOD.count("\n") + 1))

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 1280, "height": 1000})
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    pg.goto(PANEL); pg.wait_for_timeout(500)
    pg.click("#btnSwap")
    pg.fill("#fname", "Kod Muellim"); pg.fill("#email", "kod@t.az")
    pg.fill("#pass", "kodparol123"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=20000)
    pg.select_option("#atype", "tutor"); pg.fill("#aname", "Kod hesabi")
    pg.click("#btnSetup"); pg.wait_for_selector("#gForm", timeout=20000)

    uid = db("select id::text i from auth.users where email='kod@t.az'", one=True)["i"]
    acc = db("""select a.id::text i from public.accounts a
                 join auth.users u on u.id = a.owner_id where u.email='kod@t.az'""", one=True)["i"]
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select %s::uuid, p.id, 'active', now() + interval '30 days'
            from public.plans p where p.slug = 'repetitor-25'""", (acc,))
    cls = db("""insert into public.classes (account_id, teacher_id, kind, name, join_code)
                values (%s::uuid, %s::uuid, 'tutor_group', 'Kod qrup', 'KODQRUP1')
                returning id::text i""", (acc, uid), one=True)["i"]
    stu = db("""insert into public.students (account_id, class_id, created_by, full_name,
                                             display_name, login_code)
                values (%s::uuid, %s::uuid, %s::uuid, 'Kamal Kod', 'Kamal K.', 'KODSAGR1')
                returning id::text i""", (acc, cls, uid), one=True)["i"]
    #  shuffle sondurulur: olcu HEMISE kod sualini tutsun (qarisanda
    #  bir defe tek setirlik suali olcdu ve yalanci FAIL verdi).
    tid = db("""insert into public.tests (owner_type, owner_id, program_id, subject_id, level_id,
                                          slug, title, status, pass_percent,
                                          shuffle_questions, shuffle_options)
                values ('educator', %s::uuid, %s::uuid, %s::uuid, %s::uuid,
                        'kod-setir-test', 'Kod sınağı', 'published', 50, false, false)
                returning id::text i""", (uid, PRG, SUBJ, LEV["i"]), one=True)["i"]
    db("""insert into public.test_questions (test_id, question_id, ord)
          values (%s::uuid, %s::uuid, 1), (%s::uuid, %s::uuid, 2)""", (tid, QID, tid, QID2))
    db("""insert into public.assignments (test_id, class_id, assigned_by, opens_at)
          values (%s::uuid, %s::uuid, %s::uuid, now() - interval '1 hour')""", (tid, cls, uid))

    print("B · Vərəq (test önizləmə) — .paper .qh b")
    pg.goto(PANEL + "#/t/" + tid); pg.wait_for_selector(".paper .pq", timeout=20000)
    setirli(pg, ".paper .pq .qh b", "vereq")
    pg.screenshot(path="/tmp/claude-0/kod/vereq_masaustu.png", full_page=True)

    print("C · Çap — #printBox .ppb")
    #  #printBox ekranda display:none-dur, yalniz @media print-de acilir.
    #  Gizli elementde innerText XAM metni qaytarir (setirler «var» kimi
    #  gorunur) - olcu YALANCI kecerdi.  Ona gore evvel print rejimine
    #  kecirik, element heqiqeten cizilir, sonra olculur.
    pg.once("dialog", lambda d: d.dismiss())
    pg.click("#btnPrn")
    pg.wait_for_selector("#printBox .ppb", state="attached", timeout=20000)
    pg.emulate_media(media="print")
    pg.wait_for_timeout(400)
    vis = pg.evaluate("() => { const e = document.querySelector('#printBox .ppb');"
                      " return e ? e.getBoundingClientRect().height > 0 : false; }")
    ok(vis, "cap qutusu print rejiminde cizilir")
    setirli(pg, "#printBox .ppb", "cap")
    pg.screenshot(path="/tmp/claude-0/kod/cap_masaustu.png", full_page=True)
    pg.emulate_media(media="screen")
    pg.wait_for_timeout(200)

    print("D · Bank siyahısı — .qrow .g b")
    pg.goto(PANEL + "#/b"); pg.wait_for_selector("#bq", timeout=20000)
    pg.fill("#bq", "Proqram nə çap"); pg.wait_for_timeout(1400)
    pg.wait_for_selector(".qrow", timeout=20000)
    setirli(pg, ".qrow .g b", "bank siyahisi")
    pg.screenshot(path="/tmp/claude-0/kod/bank_masaustu.png", full_page=True)

    print("E · Şagird testi yazır (sonrakı ekranlar üçün)")
    sctx = br.new_context(viewport={"width": 390, "height": 844})
    sp = sctx.new_page()
    sp.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=CFG))
    sp.goto(APP); sp.wait_for_selector("#btnIn", timeout=15000)
    sp.fill("#code", "KODSAGR1"); sp.click("#btnIn")
    sp.wait_for_selector(".test", timeout=15000)
    sp.locator(".test:not(.lock)", has_text="Kod sınağı").first.click()
    sp.wait_for_selector(".opt", timeout=15000)
    #  Sagird tetbiqi ETALONDUR - orada onsuz da duz gorunur
    setirli(sp, ".q .body", "sagird tetbiqi (etalon)")
    KEY = {r["o"] for r in db("""select o.id::text o from public.question_options o
              join public.questions q on q.id = o.question_id and o.is_correct
             where q.topic_id = %s::uuid""", (TOP,))}
    for i in range(2):
        ids = sp.locator(".opt").evaluate_all("els => els.map(e => e.getAttribute('data-o'))")
        sp.locator("[data-o='%s']" % next(o for o in ids if o not in KEY)).click()
        sp.wait_for_timeout(90)
        if i == 0: sp.click("#btnNext")
        else:
            sp.once("dialog", lambda d: d.accept()); sp.click("#btnFinish")
        sp.wait_for_timeout(140)
    sp.wait_for_selector("#wrongBox", timeout=20000)
    setirli(sp, "#wrongBox .qh b", "sagird netice ekrani")
    sctx.close()

    print("F · Şagird hesabatı — cavab vərəqi (.shq b)")
    pg.goto(PANEL + "#/s/" + stu + "/" + cls); pg.wait_for_selector("#sTabs", timeout=20000)
    pg.locator('#sTabs .seg[data-v="t"]').click()
    pg.wait_for_selector("#tab-t [data-att]", timeout=20000)
    pg.locator("#tab-t [data-att]").first.click()
    pg.wait_for_selector(".shq b", timeout=20000)
    setirli(pg, ".shq b", "cavab vereqi")
    pg.screenshot(path="/tmp/claude-0/kod/cavabvereq_masaustu.png", full_page=True)

    print("G · Hesabatda səhv edilən suallar — .wq b")
    pg.locator('#sTabs .seg[data-v="s"]').click()
    pg.wait_for_selector("#tab-s .wq", timeout=20000)
    if pg.locator("#wMore").count():
        pg.click("#wMore"); pg.wait_for_timeout(300)
    sel = "#tab-s .wq b"
    setirli(pg, sel, "sehvler siyahisi")
    pg.screenshot(path="/tmp/claude-0/kod/sehvler_masaustu.png", full_page=True)

    print("H · Bankdan nümunə suallar — .smp .sq b")
    db("insert into public.user_roles (user_id, role) values (%s::uuid,'admin') "
       "on conflict do nothing", (uid,))
    pg.goto(PANEL + "#/b"); pg.reload(); pg.wait_for_selector("#bPool", timeout=20000)
    pg.locator("#bPool .seg", has_text="Hazır suallar").first.click()
    pg.wait_for_selector(".bpick .pkb", timeout=20000)
    pg.locator(".bpick .pkb", has_text="nformatika").first.click()
    pg.wait_for_selector(".bpick .pkb[data-l]", timeout=20000)
    pg.locator(".bpick .pkb[data-l='%s']" % LEV["c"]).first.click()
    pg.wait_for_selector(".cvr", timeout=20000)
    pg.locator(".cvr", has_text="Kod sətirləri").first.click()
    pg.wait_for_selector(".smp .sq b", timeout=20000)
    setirli(pg, ".smp .sq b", "bank numuneleri")
    pg.screenshot(path="/tmp/claude-0/kod/numune_masaustu.png", full_page=True)

    print("I · Telefon (390 px)")
    mctx = br.new_context(viewport={"width": 390, "height": 844})
    m = mctx.new_page()
    m.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=CFG))
    m.goto(PANEL); m.wait_for_timeout(600)
    m.fill("#email", "kod@t.az"); m.fill("#pass", "kodparol123"); m.click("#btnAuth")
    m.wait_for_timeout(2500)
    m.goto(PANEL + "#/t/" + tid); m.wait_for_selector(".paper .pq", timeout=20000)
    setirli(m, ".paper .pq .qh b", "vereq (telefon)")
    w = m.evaluate("() => { const e = document.querySelector('.paper .pq .qh b');"
                   " return e ? e.getBoundingClientRect().width : 0; }")
    ok(0 < w <= 390, "telefonda enden asmir", round(w))
    ok(m.evaluate("() => document.documentElement.scrollWidth <= window.innerWidth + 1"),
       "sehifede yana surusme yoxdur")
    m.screenshot(path="/tmp/claude-0/kod/vereq_telefon.png", full_page=True)
    m.goto(PANEL + "#/b"); m.wait_for_selector("#bq", timeout=20000)
    m.fill("#bq", "Proqram nə çap"); m.wait_for_timeout(1400)
    m.wait_for_selector(".qrow", timeout=20000)
    setirli(m, ".qrow .g b", "bank siyahisi (telefon)")
    m.screenshot(path="/tmp/claude-0/kod/bank_telefon.png", full_page=True)

    print("J · Valideyn ekranı — sual metni yoxdur, tapşırıq metni var")
    #  Valideyn ekraninda SUAL metni cixmir (yoxlanildi: yalniz ev
    #  tapsirigi ve oz yazdiqlari).  Tapsirigi ise muellim yazir ve o
    #  da cox setirli ola biler - muellim panelinde .hwrow b onsuz da
    #  pre-wrap idi, valideynde deyildi.
    db("""insert into public.homework (class_id, created_by, body)
          values (%s::uuid, %s::uuid, %s)""", (cls, uid, KOD))
    db("update public.students set parent_code = 'KODVAL01' where id = %s::uuid", (stu,))
    vctx = br.new_context(viewport={"width": 390, "height": 844})
    vp = vctx.new_page()
    vp.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=CFG))
    vp.goto(ROOT + "valideyn/index.html"); vp.wait_for_selector("#code", timeout=15000)
    vp.fill("#code", "KODVAL01"); vp.click("#btnIn")
    vp.wait_for_selector(".hwr b", timeout=20000)
    setirli(vp, ".hwr b", "valideyn - tapsiriq metni")
    vp.screenshot(path="/tmp/claude-0/kod/valideyn_telefon.png", full_page=True)
    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails))
    for f in fails: print("  - " + f)
    sys.exit(1)
print("KOD SETIRLERI: BUTUN YOXLAMALAR KECDI")
