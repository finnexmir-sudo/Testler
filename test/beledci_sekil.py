#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Beledci (komek/) ucun REAL ekran sekilleri - tetbiqin ozunden, mock uzerinde.

Ne vaxt isletmeli: ekran deyisende (yeni bolme, basliq, duyme) - beledcidəki
sekil kohnelmesin.  Cixis: komek/img/*.png (18 sekil, ~1 MB).
Yalniz bir-iki sekli yenilemek:  ONLY=m10_diaqnostika,s6_diaqnostika python3 test/beledci_sekil.py
(axin tam gedir, amma disk-e yalniz adi cekilenler yazilir - qalan PNG-ler git-de deyismir).

Nece isletmeli (postgres isleyir, bil10-bank yan qovluqdadir):
    createdb panel_e2e && (cd db && ./run.sh panel_e2e --local)
    MOCK_DSN="host=/tmp port=55432 user=postgres dbname=panel_e2e" python3 test/mock_supabase.py 54321 &
    python3 -m http.server 8010 &
    python3 test/beledci_sekil.py
Skript bazani ozu temizleyir; qeydiyyat e-poctu her defe unikaldir (mock
yaddasinda kohne e-poct qalir, tekrar qeydiyyati redd edir).
"""
import os, datetime, time
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
BASE = "http://127.0.0.1:8010/"
PANEL, STUDENT, PARENT = BASE + "muellim/index.html", BASE + "sagird/index.html", BASE + "valideyn/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
OUT = "/home/user/testler/komek/img"
os.makedirs(OUT, exist_ok=True)
CFG = """window.CFG = {
  SUPABASE_URL: "http://127.0.0.1:54321",
  SUPABASE_ANON_KEY: "test-anon-key",
  STUDENT_URL: "https://finnexmir-sudo.github.io/Testler/sagird/",
  PARENT_URL:  "https://finnexmir-sudo.github.io/Testler/valideyn/",
  SHOW_PLANS: false
};"""

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            return cur.fetchone() if one else cur.fetchall()

db("""delete from public.question_reports; delete from public.parent_sessions;
delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers; delete from public.attempts; delete from public.assignments;
delete from public.student_sessions; delete from public.students; delete from public.classes;
delete from public.test_questions tq using public.tests t where t.id=tq.test_id and t.owner_type='educator';
delete from public.tests where owner_type='educator'; delete from public.subscriptions;
delete from public.account_members; delete from public.accounts; delete from public.user_roles;
delete from public.profiles; delete from auth.users;""")

def page(ctx, w, h):
    pg = ctx.new_page(); pg.set_viewport_size({"width": w, "height": h})
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    pg.route("**://*.supabase.co/**", lambda r: r.abort())
    return pg

ONLY = {x for x in os.environ.get("ONLY", "").split(",") if x}

def shot(pg, name, full=False):
    if ONLY and name not in ONLY:
        return
    pg.evaluate("window.scrollTo(0,0)")
    pg.wait_for_timeout(350)
    pg.screenshot(path=f"{OUT}/{name}.png", full_page=full)
    print("  ", name)

with sync_playwright() as p:
    br = p.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(permissions=["clipboard-read", "clipboard-write"])

    # ---------------- MUELLIM (430x900 - telefon, panel testleri ile eyni)
    t = page(ctx, 430, 1150)
    # giris ve hesab ekrani qisadir - hundur pencerede alt bos qalir
    t.set_viewport_size({"width": 430, "height": 760})
    t.goto(PANEL); t.wait_for_selector("#btnAuth", timeout=15000)
    shot(t, "m1_giris")
    t.click("#btnSwap"); t.fill("#fname", "Leyla Məmmədova"); t.fill("#email", "leyla%d@numune.az" % int(time.time()))
    t.fill("#pass", "parol1234"); t.click("#btnAuth")
    t.wait_for_selector("#btnSetup", timeout=15000)
    t.select_option("#atype", "tutor"); t.fill("#aname", "Leyla müəllim — riyaziyyat")
    shot(t, "m2_hesab")
    t.set_viewport_size({"width": 430, "height": 1150})
    t.click("#btnSetup"); t.wait_for_selector("#btnGroup", timeout=15000)
    t.fill("#gname", "3-cü sinif — şənbə qrupu"); t.select_option("#glevel", "3")
    t.click("#btnGroup"); t.wait_for_selector("#groups .item", timeout=15000)
    t.wait_for_timeout(500); shot(t, "m3_icmal")
    t.click("#groups .item"); t.wait_for_selector("#gTabs", timeout=15000)
    for nm in ("Aysu Məmmədova", "Kənan Əliyev", "Nigar Həsənova"):
        if t.locator("#btnStuOpen").count() and t.locator("#btnStuOpen").is_visible(): t.click("#btnStuOpen")   # forma duyme ile acilir
        t.fill("#sname", nm); t.click("#btnStu"); t.wait_for_timeout(700)
    t.wait_for_selector(".stu", timeout=15000)
    # valideyn girisini ilk sagird ucun ac
    row = t.locator(".stu").first
    row.locator("[data-edit]").click(); t.wait_for_selector(".edit .pbox [data-pon]", timeout=15000)
    row.locator("[data-pon]").click(); t.wait_for_selector(".stu [data-poff]", timeout=15000)
    t.wait_for_timeout(400); shot(t, "m4_qrup_sagirdler")
    gid = db("select id::text i from public.classes limit 1", one=True)["i"]
    code = db("select login_code c from public.students where full_name='Aysu Məmmədova'", one=True)["c"]
    pcode = db("select parent_code c from public.students where full_name='Aysu Məmmədova'", one=True)["c"]
    # tapsiriq
    t.click("#btnAsgs"); t.wait_for_selector("#fp", timeout=15000)
    t.wait_for_function("document.querySelectorAll('#aTest option').length > 0", timeout=15000)
    opts = t.locator("#aTest option").all_inner_texts()
    lbl = next(o for o in opts if "Vurma cədvəli" in o)
    t.select_option("#aTest", label=lbl)
    t.fill("#aDate", (datetime.date.today() + datetime.timedelta(days=7)).isoformat())
    t.select_option("#aTry", "2")
    shot(t, "m5_tapsiriq_ver")
    t.click("#btnAsg"); t.wait_for_selector(".asg", timeout=15000)
    shot(t, "m6_tapsiriq_siyahi")
    # bank ve generator
    t.goto(PANEL + "#/b"); t.wait_for_timeout(1800)
    shot(t, "m7_bank")
    t.goto(PANEL + "#/gen"); t.wait_for_timeout(1200); shot(t, "m8_test_yig")

    # ---------------- SAGIRD (390x844)
    # 07_seed_tests-deki 'Genislendirilmis analiz testi' YERLI numunedir (is_free=false,
    # kilidli) - canlida yoxdur.  Beledcide gorunse casdirir: sekil muddetince gizledilir.
    db("update public.tests set status='draft' where slug='riy-3-analiz'")
    s = page(ctx, 390, 844)
    s.goto(STUDENT); s.wait_for_selector("#btnIn", timeout=15000)
    s.fill("#code", code); shot(s, "s1_giris")
    s.click("#btnIn"); s.wait_for_selector(".test", timeout=15000); shot(s, "s2_tapsiriqlar")
    s.locator(".test.asg").first.click(); s.wait_for_selector(".opt", timeout=15000)
    s.locator(".opt").first.click(); s.wait_for_timeout(200); shot(s, "s3_sual")
    # duzgun cavablarla bitir ki, netice guzel gorunsun (2 sehv buraxiriq)
    key = {r["q"]: r["o"] for r in db("""select q.id::text q, o.id::text o from public.questions q
        join public.question_options o on o.question_id=q.id and o.is_correct
        join public.test_questions tq on tq.question_id=q.id join public.tests t on t.id=tq.test_id
        where t.slug='riy-3-vurma-1'""")}
    i = 0
    while True:
        ids = s.locator(".opt").evaluate_all("els => els.map(e => e.getAttribute('data-o'))")
        want = next((o for o in ids if o in key.values()), ids[0])
        if i in (1, 4): want = next((o for o in ids if o not in key.values()), ids[0])
        s.locator("[data-o='%s']" % want).click(); s.wait_for_timeout(120)
        if s.locator("#btnNext").count() and s.locator("#btnNext").is_visible():
            s.click("#btnNext"); s.wait_for_timeout(150); i += 1
        else:
            s.once("dialog", lambda d: d.accept()); s.click("#btnFinish"); break
    s.wait_for_selector(".ring", timeout=15000); shot(s, "s4_netice", full=True)
    s.click("#btnHome"); s.wait_for_selector(".test", timeout=15000); shot(s, "s5_ev_ekrani", full=True)

    # ---------------- MUELLIM: hesabat
    t.goto(PANEL + "#/r/" + gid); t.wait_for_timeout(1500); shot(t, "m9_hesabat")

    # ---------------- DIAQNOSTIKA: muellim abune ile yaradir, sagird yazir
    # (xerite ucun 3 reng lazimdir: 1-ci fesil 0/3 zeif, 3-cu 1/3 zeif, 5-ci 2/3 orta, qalani yaxsi)
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select a.id, p.id, 'active', now() + interval '30 days'
            from public.accounts a, public.plans p where p.slug = 'repetitor-25'""")
    sid = db("select id::text i from public.students where full_name='Aysu Məmmədova'", one=True)["i"]
    t.goto(PANEL + "#/s/" + sid + "/" + gid); t.wait_for_selector("#dgGo", timeout=15000)
    t.select_option("#dgSub", "riyaziyyat"); t.click("#dgGo")
    t.wait_for_selector("#diagBox:has-text('Gözlənilir')", timeout=20000)
    dt = db("select id::text i from public.tests where is_diagnostic order by created_at desc limit 1", one=True)["i"]
    rows = db("""select o.id::text oid, q.id::text qid, o.is_correct c,
                        dense_rank() over (order by tp.sort, tp.name) rk
                   from public.test_questions tq
                   join public.questions q on q.id = tq.question_id
                   join public.topics tp on tp.id = q.topic_id
                   join public.question_options o on o.question_id = q.id
                  where tq.test_id = %s""", (dt,))
    O2Q = {r["oid"]: r["qid"] for r in rows}; QRK = {r["qid"]: r["rk"] for r in rows}
    CORR = {r["oid"] for r in rows if r["c"]}
    wrong_left = {1: 3, 3: 2, 5: 1}          # fesil sirasi -> nece sual sehv
    s.goto(STUDENT); s.wait_for_selector(".test", timeout=15000)
    s.locator(".test.asg:has-text('Diaqnostika')").first.click(); s.wait_for_selector(".opt", timeout=15000)
    while True:
        ids = s.locator(".opt").evaluate_all("els => els.map(e => e.getAttribute('data-o'))")
        rk = QRK.get(O2Q.get(ids[0]))
        if wrong_left.get(rk, 0) > 0:
            wrong_left[rk] -= 1; want = next(o for o in ids if o not in CORR)
        else:
            want = next(o for o in ids if o in CORR)
        s.locator("[data-o='%s']" % want).click(); s.wait_for_timeout(80)
        if s.locator("#btnNext").count() and s.locator("#btnNext").is_visible():
            s.click("#btnNext"); s.wait_for_timeout(100)
        else:
            s.once("dialog", lambda d: d.accept()); s.click("#btnFinish"); break
    s.wait_for_selector(".ring", timeout=15000)
    if not ONLY or "s6_diaqnostika" in ONLY:
        # yalniz xerite hissesi: "Movzu xeriten" basligindan kartin sonuna qeder (tam sehife 5000px-dir)
        box = s.evaluate("""() => { const h = [...document.querySelectorAll('h2')].find(e => /x\u0259rit/i.test(e.textContent));
            const c = h.nextElementSibling.nextElementSibling; const a = h.getBoundingClientRect(), b = c.getBoundingClientRect();
            return {x: 0, y: a.top + window.scrollY - 12, width: 390, height: b.bottom - a.top + 24}; }""")
        s.wait_for_timeout(350); s.screenshot(path=f"{OUT}/s6_diaqnostika.png", full_page=True, clip=box); print("   s6_diaqnostika")
    t.reload(); t.wait_for_selector("#dgMap", timeout=15000)
    # element sekli uzun kart uzre suruslur - sabit ust zolaq ve alt menyu araya dusmesin deye gizledilir
    t.add_style_tag(content=".top,.bnav{display:none!important}")
    t.evaluate("document.getElementById('diagBox').scrollIntoView()"); t.wait_for_timeout(350)
    if not ONLY or "m10_diaqnostika" in ONLY:
        t.locator("#diagBox").screenshot(path=f"{OUT}/m10_diaqnostika.png"); print("   m10_diaqnostika")

    # ---------------- VALIDEYN (390x844)
    v = page(ctx, 390, 844)
    v.goto(PARENT); v.wait_for_selector("#code", timeout=15000)
    v.fill("#code", pcode); shot(v, "v1_giris")
    v.click("#btnIn"); v.wait_for_selector(".who", timeout=15000); shot(v, "v2_usagim", full=True)
    db("update public.tests set status='published' where slug='riy-3-analiz'")
    br.close()
print("HAZIR:", sorted(os.listdir(OUT)))
