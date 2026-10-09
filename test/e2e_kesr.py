#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Kesrler ekranda UST-ALT (29.09) - bazaya toxunmadan.

  A  sagird testi: sual ve variantlarda kesr elementi; «km/saat», «x/6», «2/3/4» olduğu kimi
  B  netice ekrani: sual, sagirdin secimi, izah
  C  muellim: test vereqi (ekran + cap), sual banki
  D  tehlukesizlik: sual metni «<b>1</b>/2» ve «"><img onerror>» - HTML islemir
  E  baza deyismir: suallarin metni olduğu kimi qalir
Sekiller: /tmp/claude-0/ks_*.png (390 ve 1280 px)
"""
import sys, time
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

ROOT = "http://127.0.0.1:8010/"
PANEL = ROOT + "muellim/index.html"
STUDENT = ROOT + "sagird/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
CFG = """window.CFG = {SUPABASE_URL:"http://127.0.0.1:54321",
  SUPABASE_ANON_KEY:"test-anon-key", STUDENT_URL:"http://127.0.0.1:8010/sagird/",
  SHOW_PLANS:false};"""
SS = "/tmp/claude-0/ks_"

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
delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers;  delete from public.attempts;
delete from public.assignments;      delete from public.student_sessions;
delete from public.students;         delete from public.classes;
delete from public.test_questions tq using public.tests t
 where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.questions where owner_type = 'educator';
delete from public.subscriptions;
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from auth.users;
""")

T = int(time.time()); MAIL = "ks%d@t.az" % T
QUES = [
    #  (metn, [(variant, duzgun)], izah)
    ("3/4 və 12 1/4 ədədlərindən hansı böyükdür?",
     [("3/4", False), ("12 1/4", True), ("−3/7", False), ("1/2-dən azdır", False)],
     "12 1/4 tam hissəsi böyükdür: 12 > 0, ona görə 12 1/4 > 3/4."),
    ("Sürət 60 km/saat, x/6 nədir? 0,(3) və 0,5/2 yazılışlarına, 2/3/4 zəncirinə baxın.",
     [("km/saat", True), ("q/sm³", False), ("2/3/4", False), ("x/6", False)], "Vahid olduğu kimi qalır."),
    ("<b>1</b>/2 və \"><img src=x onerror=\"window.__xss=1\">",
     [("<i>3</i>/4", False), ("5/6", True)], "izah <u>1</u>/3"),
]

def context(br, w, h):
    ctx = br.new_context(viewport={"width": w, "height": h})
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)[:140]))
    return ctx, pg

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])

    print("0 · Hazırlıq")
    ctx0, pg0 = context(br, 1280, 1000)
    pg0.goto(PANEL); pg0.wait_for_timeout(600); pg0.click("#btnSwap")
    pg0.fill("#fname", "Kesr Test"); pg0.fill("#email", MAIL)
    pg0.fill("#pass", "ksparol123"); pg0.click("#btnAuth")
    pg0.wait_for_selector("#btnSetup", timeout=20000)
    pg0.select_option("#atype", "tutor"); pg0.fill("#aname", "Kesr hesabi")
    pg0.click("#btnSetup"); pg0.wait_for_timeout(4500)
    uid = db("select id::text i from auth.users where email=%s", (MAIL,), one=True)["i"]
    acc = db("select id::text i from public.accounts where owner_id=%s::uuid", (uid,), one=True)["i"]
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select %s::uuid, p.id, 'active', now() + interval '30 days'
            from public.plans p where p.slug = 'repetitor-25'""", (acc,))
    db("insert into public.user_roles (user_id, role) values (%s::uuid, 'admin') on conflict do nothing", (uid,))
    base = db("""select program_id::text p, subject_id::text s from public.tests where slug='riy-3-vurma-1'""", one=True)
    lvl5 = db("select id::text i from public.levels where code='5'", one=True)["i"]
    GA = db("""insert into public.classes (account_id, teacher_id, kind, name, join_code, level_id)
               values (%s::uuid, %s::uuid, 'tutor_group', '5-ci sinif', 'KSKOD005', %s::uuid) returning id::text i""",
            (acc, uid, lvl5), one=True)["i"]
    CODE = "KSS%d" % (T % 10000)
    db("""insert into public.students (account_id, class_id, created_by, full_name, display_name, login_code)
          values (%s::uuid, %s::uuid, %s::uuid, 'Kesr Sagird', 'Kesr S.', %s)""", (acc, GA, uid, CODE))
    TID = db("""insert into public.tests (owner_type, owner_id, program_id, subject_id, level_id, title,
                                          status, shuffle_questions, shuffle_options)
                values ('educator', %s::uuid, %s::uuid, %s::uuid, %s::uuid, 'Kəsr sınağı', 'published', false, false)
                returning id::text i""", (uid, base["p"], base["s"], lvl5), one=True)["i"]
    for n, (body, opts, izah) in enumerate(QUES):
        qid = db("""insert into public.questions (owner_type, owner_id, account_id, subject_id, level_id, kind, body, explanation, status)
                    values ('educator', %s::uuid, %s::uuid, %s::uuid, %s::uuid, 'single', %s, %s, 'published') returning id::text i""",
                 (uid, acc, base["s"], lvl5, body, izah), one=True)["i"]
        for k, (ob, oc) in enumerate(opts):
            db("insert into public.question_options (question_id, ord, body, is_correct) values (%s::uuid, %s, %s, %s)",
               (qid, k, ob, oc))
        db("insert into public.test_questions (test_id, question_id, ord) values (%s::uuid, %s::uuid, %s)", (TID, qid, n + 1))
    db("insert into public.assignments (class_id, test_id, assigned_by) values (%s::uuid, %s::uuid, %s::uuid)", (GA, TID, uid))
    SNAP = db("select body from public.questions where owner_type='educator' order by body", )
    SNAP_O = db("select o.body from public.question_options o join public.questions q on q.id=o.question_id where q.owner_type='educator' order by o.body")
    print("   hesab, qrup, şagird, 3 suallıq kəsr testi")
    ctx0.close()

    for (w, h, tel) in ((1280, 900, "masaustu"), (390, 844, "telefon")):
        print("\n=== %s (%d px)" % (tel, w))
        db("delete from public.attempt_answers; delete from public.attempts; delete from public.student_sessions;")
        ctx, pg = context(br, w, h)
        pg.goto(STUDENT); pg.wait_for_selector("#btnIn", timeout=15000)
        pg.fill("#code", CODE); pg.click("#btnIn")
        pg.wait_for_selector(".test", timeout=15000)
        pg.locator(".test", has_text="Kəsr sınağı").first.click()
        pg.wait_for_selector(".opt", timeout=15000)

        print("A · Şagird testi — sual 1 (3/4, 12 1/4, −3/7, 1/2-dən)")
        ok(pg.locator(".q .body .kesr").count() >= 2, "sualda kesr elementleri var", pg.locator(".q .body .kesr").count())
        ok(pg.locator(".q .body .kmix").count() == 1, "«12 1/4» qarisiq eded kimi")
        ok(pg.locator(".opt .kesr").count() >= 3, "variantlarda da kesr var", pg.locator(".opt .kesr").count())
        ok(pg.locator("[aria-label='3/4']").count() >= 1 and pg.locator("[aria-label='12 1/4']").count() >= 1,
           "ekran oxuyucusu ucun aria-label")
        n = pg.locator(".q .body .kesr .kn").first.bounding_box(); d = pg.locator(".q .body .kesr .kd").first.bounding_box()
        ok(n and d and n["y"] + n["height"] <= d["y"] + 1, "surət məxrəcin ÜSTÜNDƏDİR", "%s / %s" % (round(n["y"]), round(d["y"])))
        ok(scroll_x := pg.evaluate("document.documentElement.scrollWidth - document.documentElement.clientWidth") <= 1,
           "yana surusme yoxdur", scroll_x)
        pg.screenshot(path=SS + "sagird_test_%s.png" % tel)
        pg.locator(".opt").nth(0).click(); pg.click("#btnNext"); pg.wait_for_timeout(400)   # 3/4 - SEHV cavab

        print("A2 · Sual 2 (çevrilməməli: km/saat, x/6, 2/3/4, 0,(3), 0,5/2)")
        bt = pg.inner_text(".q .body")
        ok(pg.locator(".q .body .kesr").count() == 0, "sualda HEC BIR kesr elementi yoxdur", pg.locator(".q .body .kesr").count())
        ok(all(x in bt for x in ("km/saat", "x/6", "0,(3)", "0,5/2", "2/3/4")), "yazilis olduğu kimi qalıb", bt[:70])
        ot = pg.inner_text(".opts") if pg.locator(".opts").count() else pg.inner_text("#main")
        ok(all(x in ot for x in ("km/saat", "q/sm³", "2/3/4", "x/6")), "variantlar olduğu kimi qalıb")
        pg.locator(".opt").nth(3).click(); pg.click("#btnNext"); pg.wait_for_timeout(400)

        print("D · Təhlükəsizlik — sual 3")
        ok(pg.locator(".q .body img").count() == 0 and pg.locator(".q .body b").count() == 0, "sual mətnindən HTML elementi yaranmır")
        ok("<b>1</b>" in pg.inner_text(".q .body") and "onerror" in pg.inner_text(".q .body"), "mətn olduğu kimi görünür (etiketlər YAZI kimi)")
        ok(pg.locator(".opt i, .opt u").count() == 0, "variantdan HTML yaranmır")
        ok(pg.evaluate("window.__xss") is None, "skript İŞLƏMƏDİ (window.__xss yoxdur)")
        pg.locator(".opt").nth(0).click(); pg.click("#btnFinish")
        pg.wait_for_selector(".ring", timeout=15000); pg.wait_for_timeout(500)

        print("B · Nəticə ekranı")
        ok(pg.locator(".wrong .kesr").count() >= 3, "nəticədə kəsr elementləri var", pg.locator(".wrong .kesr, .right .kesr").count())
        ok(pg.locator(".picked .kesr").count() >= 1, "«Sən yazdın» cavabında da kəsr var", pg.locator(".picked .kesr").count())
        ok(pg.locator("main .qh img, #main .qh img, #main .wrong img").count() == 0, "nəticədə də HTML sızmır")
        pg.screenshot(path=SS + "sagird_netice_%s.png" % tel, full_page=True)
        ctx.close()

        print("C · Müəllim: test vərəqi, çap, sual bankı")
        ctx, pg = context(br, w, h)
        pg.goto(PANEL); pg.wait_for_timeout(700)
        pg.fill("#email", MAIL); pg.fill("#pass", "ksparol123"); pg.click("#btnAuth"); pg.wait_for_timeout(3500)
        pg.goto(PANEL + "#/t/" + TID); pg.reload()
        pg.wait_for_selector(".paper .pq, .paper", state="attached", timeout=20000); pg.evaluate("var f=document.getElementById('qFold'); if(f) f.open=true"); pg.wait_for_timeout(1500)
        ok(pg.locator(".paper .kesr").count() >= 3, "test vərəqində kəsr elementləri var", pg.locator(".paper .kesr").count())
        ok(pg.locator(".paper img[src='x']").count() == 0, "vərəqdə HTML sızmır")
        ok(pg.evaluate("window.__xss") is None, "vərəqdə skript işləmədi")
        pg.screenshot(path=SS + "muellim_verq_%s.png" % tel, full_page=True)
        #  HEQIQI cap gorunusu: window.print susdurulur, «cavab acari ile» isarelenir
        pg.evaluate("window.print = function () {}")
        pg.check("#prnK"); pg.click("#btnPrn"); pg.wait_for_selector("#printBox .ppq", state="attached", timeout=8000)
        ok(pg.locator("#printBox .ppb .kesr").count() >= 2, "cap vərəqində sual kəsrləri var", pg.locator("#printBox .ppb .kesr").count())
        ok(pg.locator("#printBox .kmix").count() >= 1, "cap vərəqində qarışıq ədəd var")
        pg.emulate_media(media="print")
        pg.wait_for_timeout(300)
        bw = pg.locator("#printBox .kesr .kn").first.evaluate("e => getComputedStyle(e).borderBottomWidth")
        ok(bw not in ("0px", ""), "çap rejimində kəsr xətti qalır", bw)
        ok(pg.locator("#printBox .kesr .kn").first.is_visible(), "çap rejimində kəsr görünür")
        pg.screenshot(path=SS + "muellim_cap_%s.png" % tel, full_page=True)
        pg.emulate_media(media="screen")
        pg.uncheck("#prnK")
        #  sual banki: Riyaziyyat 5 -> Adi kesrler
        pg.goto(PANEL + "#/b"); pg.reload()
        pg.wait_for_selector("#bPool", timeout=20000)
        pg.locator("#bPool .seg", has_text="Hazır suallar").click()
        pg.wait_for_selector(".bpick .pkb", timeout=15000)
        pg.locator(".bpick .pkb", has_text="Riyaziyyat").first.click()
        pg.wait_for_selector(".bpick .pkb[data-l]", timeout=15000)
        pg.locator('.bpick .pkb[data-l="5"]').click(); pg.wait_for_timeout(1500)
        row = pg.locator(".cvr", has_text="Adi kəsrlər").first
        row.wait_for(timeout=15000); row.click(); pg.wait_for_timeout(1500)
        pg.wait_for_selector(".smp .kesr", timeout=15000)
        nk = pg.locator(".smp .kesr").count()
        ok(nk >= 3, "sual bankında (Riyaziyyat 5 → Adi kəsrlər) kəsr elementləri var", nk)
        row.scroll_into_view_if_needed()
        pg.screenshot(path=SS + "muellim_bank_%s.png" % tel)
        ok(pg.evaluate("document.documentElement.scrollWidth - document.documentElement.clientWidth") <= 1, "bank yana surusmur")
        ctx.close()

    print("\nE · Baza dəyişməyib")
    ok(db("select body from public.questions where owner_type='educator' order by body") == SNAP, "sual mətnləri olduğu kimi")
    ok(db("select o.body from public.question_options o join public.questions q on q.id=o.question_id where q.owner_type='educator' order by o.body") == SNAP_O,
       "variantlar olduğu kimi")
    ok(db("select count(*) n from public.questions where body like '%%<span class=\"kesr\"%%' or body like '%%kesr%%'", one=True)["n"] == 0,
       "bazada kəsr elementi YOXDUR")
    br.close()

print()
if fails:
    print("SINDI (%d):" % len(fails))
    for f in fails: print("  -", f)
    sys.exit(1)
print("HAMISI KECDI")
