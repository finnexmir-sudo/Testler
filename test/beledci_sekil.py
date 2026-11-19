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
OUT = os.environ.get("OUT") or os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "komek", "img")
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

def el(pg, sel, name):
    """Tek kartin sekli: sabit ust zolaq ve alt menyu (.top, .bnav) karta dusmesin."""
    if ONLY and name not in ONLY:
        return
    pg.evaluate("document.querySelectorAll('.top,.bnav').forEach(e => e.style.visibility = 'hidden')")
    pg.locator(sel).scroll_into_view_if_needed(); pg.wait_for_timeout(300)
    #  kartin kenarinda 10 px bosluq - basliq (meselen «Diaqnostika») kenara yapismasin
    b = pg.evaluate("""s => { const r = document.querySelector(s).getBoundingClientRect();
        return {x: Math.max(0, r.left - 10), y: r.top + window.scrollY - 10, width: Math.min(innerWidth, r.width + 20), height: r.height + 20}; }""", sel)
    pg.screenshot(path=f"{OUT}/{name}.png", full_page=True, clip=b); print("  ", name)
    pg.evaluate("document.querySelectorAll('.top,.bnav').forEach(e => e.style.visibility = '')")

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

    # ---------------- MUELLIM (430 en - telefon).  30.10: yeni panel - qeydiyyat → bos Icmal →
    # «İlk qrupunu yarat» → qrup acilir («İlk nəticəyə 4 addım») → sagirdler → kodlar → Test yig →
    # vereq → «Testi ver».  Beledcideki addimlar bu sira ile gedir.
    t = page(ctx, 430, 760)
    #  «E-poçtunuz təsdiqlənməyib» zolagi (mock poct gondermir) her sekle dusurdu - «Sonra» basilmis kimi
    t.add_init_script("try { sessionStorage.setItem('bil10_mailbar', '1'); } catch (e) {}")
    t.goto(PANEL); t.wait_for_selector("#btnAuth", timeout=15000)
    shot(t, "m1_giris")
    t.click("#btnSwap"); t.fill("#fname", "Leyla Məmmədova"); t.fill("#email", "leyla%d@numune.az" % int(time.time()))
    t.fill("#pass", "parol1234"); t.click("#btnAuth")
    t.wait_for_selector("#btnSetup", timeout=15000)
    t.fill("#aname", "Leyla müəllim — riyaziyyat")
    t.wait_for_selector("#setSubs [data-sub='riyaziyyat']", timeout=15000)
    t.click("#setSubs [data-sub='riyaziyyat']")
    shot(t, "m2_hesab")
    t.set_viewport_size({"width": 430, "height": 900})
    t.click("#btnSetup"); t.wait_for_selector("#yFirstG", timeout=15000); t.wait_for_timeout(600)

    t.click("#yFirstG"); t.wait_for_selector("#btnGroup", timeout=15000)
    t.fill("#gname", "3-cü sinif — şənbə qrupu"); t.select_option("#glevel", "3")
    t.click("#btnGroup"); t.wait_for_function("location.hash.indexOf('#/g/') === 0", timeout=15000)
    t.wait_for_selector("#gkStart:not([hidden])", timeout=15000); t.wait_for_selector("#gFirstStu", timeout=15000)
    t.wait_for_timeout(600); shot(t, "m3_qrup_yeni")
    gid = db("select id::text i from public.classes limit 1", one=True)["i"]
    t.click("#gFirstStu"); t.wait_for_selector("#stuForm:not([hidden])", timeout=15000)
    for nm in ("Aysu Məmmədova", "Kənan Əliyev", "Nigar Həsənova", "Murad Quliyev"):
        t.fill("#sname", nm); t.click("#btnStu"); t.wait_for_timeout(1500)
    t.goto(PANEL + "#/g/" + gid + "/s"); t.reload(); t.wait_for_selector("#stu a.ytr", timeout=15000); t.wait_for_timeout(600)

    code = db("select login_code c from public.students where full_name='Aysu Məmmədova'", one=True)["c"]
    pcode = db("select parent_code c from public.students where full_name='Aysu Məmmədova'", one=True)["c"]
    # «İlk nəticəyə 4 addım»: 1 ✓, 2-ci addimda kodlar ve «Mətni kopyala»
    t.goto(PANEL + "#/g/" + gid); t.reload(); t.wait_for_selector("#gkStart .gkod", timeout=15000); t.wait_for_timeout(500)
    el(t, "#gkStart", "m4_kodlar")
    # 3-cu addim «Test yığ» → generator: Kimə = bu qrup, sinif qrupun sinfi
    t.click("#gsGen"); t.wait_for_selector("#btnMake", timeout=15000)
    t.wait_for_function("document.querySelector('#gLevs .chip.on') && document.getElementById('gAsg').value.length > 0", timeout=15000)
    t.wait_for_timeout(800)
    t.set_viewport_size({"width": 430, "height": 1150}); shot(t, "m8_test_yig"); t.set_viewport_size({"width": 430, "height": 900})
    t.click("#btnMake"); t.wait_for_selector("#btnPAsg", timeout=30000); t.wait_for_timeout(600)
    t.add_style_tag(content=".top,.bnav{display:none!important}")
    if not ONLY or "m5_testi_ver" in ONLY:
        # «Qrupa təyin et» basligindan «Testi ver» duymesine qeder (vereq uzundur)
        box = t.evaluate("""() => { const a = document.getElementById('pAsgH').getBoundingClientRect(),
            b = document.getElementById('btnPAsg').getBoundingClientRect();
            return {x: 0, y: a.top + window.scrollY - 14, width: 430, height: b.bottom - a.top + 30}; }""")
        t.screenshot(path=f"{OUT}/m5_testi_ver.png", full_page=True, clip=box); print("   m5_testi_ver")
    t.click("#btnPAsg"); t.wait_for_selector(".pasgok", timeout=15000)
    t.reload(); t.wait_for_timeout(800)
    # hazir test: qrupun basligindaki «Tapşırıq ver» → «Test ver» (kohne forma, eyni ekran)
    t.goto(PANEL + "#/a/" + gid + "/t"); t.reload(); t.wait_for_selector("#aList [data-t]", timeout=15000)
    t.wait_for_function("document.querySelectorAll('#aTest option').length > 0", timeout=15000)
    opts = t.locator("#aTest option").all_inner_texts()
    lbl = next(o for o in opts if "Vurma cədvəli" in o)
    t.click("#aList [data-t='" + t.evaluate("l => Array.from(document.querySelectorAll('#aTest option')).filter(o => o.textContent === l)[0].value", lbl) + "']")
    t.fill("#aDate", (datetime.date.today() + datetime.timedelta(days=7)).isoformat())
    t.select_option("#aTry", "2"); t.evaluate("document.activeElement && document.activeElement.blur()")

    t.click("#btnAsg"); t.wait_for_timeout(1500)
    # sablon (parametrik) sual - redaktor, numune ile (db/132)
    t.goto(PANEL + "#/q/new"); t.wait_for_selector("#qbody", timeout=15000)
    t.fill("#qbody", "{a} + {b} neçə edər?")
    t.locator(".obody").nth(0).fill("{a+b}"); t.locator(".obody").nth(1).fill("{a+b+10}")
    t.locator("details.more summary", has_text="Şablon").click()
    t.fill("#qpar", "a = 100..999, b = 100..999; şərt: a > b")
    t.click("#qparTry"); t.wait_for_selector("#qparOut .qsample", timeout=15000)
    t.evaluate("document.querySelector('#qbody').scrollIntoView()")
    shot(t, "m13_sablon")

    # ---------------- SAGIRD (390x844)
    # 07_seed_tests-deki 'Genislendirilmis analiz testi' YERLI numunedir (is_free=false,
    # kilidli) - canlida yoxdur.  Beledcide gorunse casdirir: sekil muddetince gizledilir.
    db("update public.tests set status='draft' where slug='riy-3-analiz'")
    s = page(ctx, 390, 844)
    s.goto(STUDENT); s.wait_for_selector("#btnIn", timeout=15000)
    s.fill("#code", code); shot(s, "s1_giris")
    s.click("#btnIn"); s.wait_for_selector(".test", timeout=15000); shot(s, "s2_tapsiriqlar")
    s.locator(".test.asg").first.click(); s.wait_for_selector(".opt", timeout=15000)
    # duzgun cavablarla bitir ki, netice guzel gorunsun (2 sehv buraxiriq)
    key = {r["q"]: r["o"] for r in db("""select q.id::text q, o.id::text o from public.questions q
        join public.question_options o on o.question_id=q.id and o.is_correct
        join public.test_questions tq on tq.question_id=q.id
        where tq.test_id in (select test_id from public.assignments)""")}
    #  sekil: DUZ variant secili (ilk variant secilende "4 x 9 = 32" kimi
    #  sehv cavab secilmis gorunurdu - reklamda yanlis tesir)
    ids0 = s.locator(".opt").evaluate_all("els => els.map(e => e.getAttribute('data-o'))")
    s.locator("[data-o='%s']" % next((o for o in ids0 if o in key.values()), ids0[0])).click()
    s.wait_for_timeout(200); shot(s, "s3_sual")
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
    # movzu mesqi (db/133): ilk movzunu ac, bir sual - ekran
    #  30.10: mesq karti bu anda gorunmeye biler (abune hele yoxdur) - beledci sekli
    #  ucun sert sert deyil, olmasa s7 kohne qalir
    try:
        s.wait_for_selector("#adBox .arow", timeout=6000)
        s.locator("#adBox .arow").first.click(); s.wait_for_selector(".adprog", timeout=15000)
        shot(s, "s7_mesq")
        s.click("#btnBack"); s.wait_for_selector(".test", timeout=15000)
    except Exception:
        print("   (s7_mesq cekilmedi - movzu mesqi karti yoxdur)")

    # ---------------- MUELLIM: hesabat (qrupun «Hesabat» sekmesi)
    t.goto(PANEL + "#/r/" + gid); t.reload(); t.wait_for_selector(".rstat", timeout=15000); t.wait_for_timeout(1500)
    shot(t, "m9_hesabat")
    # sagird profili: Xulase - dovr cedveli, «Növbəti addım», son testler
    sid = db("select id::text i from public.students where full_name='Aysu Məmmədova'", one=True)["i"]
    t.goto(PANEL + "#/s/" + sid + "/" + gid); t.reload(); t.wait_for_selector("#stuSt", timeout=15000); t.wait_for_timeout(1200)
    shot(t, "m16_profil")

    # ---------------- DIAQNOSTIKA: muellim abune ile yaradir, sagird yazir
    # (xerite ucun 3 reng lazimdir: 1-ci fesil 0/3 zeif, 3-cu 1/3 zeif, 5-ci 2/3 orta, qalani yaxsi)
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select a.id, p.id, 'active', now() + interval '30 days'
            from public.accounts a, public.plans p where p.slug = 'repetitor-25'""")
    t.goto(PANEL + "#/s/" + sid + "/" + gid); t.reload(); t.wait_for_selector("#sTabs", timeout=15000)
    t.click("#sTabs [data-v='m']"); t.wait_for_selector("#dgGo", state="attached", timeout=15000)
    t.evaluate("document.querySelectorAll('details.dgmore').forEach(d => d.open = true)")
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
    t.reload(); t.wait_for_selector("#sTabs", timeout=15000)
    t.click("#sTabs [data-v='m']"); t.wait_for_selector("#dgMap", timeout=15000)
    el(t, "#diagBox", "m10_diaqnostika")

    # ---------------- «BU GUNUN DERSI»: plan qurulur, bir movzu kecilir, kart cekilir
    lev = db("select l.code c from public.classes c join public.levels l on l.id=c.level_id limit 1", one=True)["c"]
    t.goto(PANEL + "#/g/" + gid + "/p"); t.reload(); t.wait_for_selector("#btnPlOpen", timeout=15000); t.click("#btnPlOpen")
    t.wait_for_function("document.querySelector('#plSub option[value=riyaziyyat]')", timeout=15000)
    t.select_option("#plSub", "riyaziyyat"); t.select_option("#plLev", lev); t.click("#btnPlMk")
    t.wait_for_selector(".plcur [data-pldone]", timeout=15000)
    t.locator("[data-pldone]").first.click(); t.wait_for_timeout(2500)
    print("   plan: kecilen ders", db("select count(*) n from public.class_plan_items where done_at is not null", one=True)["n"])
    # qrupun «İcmal» sekmesi: «Bugünkü dərs» karti (planda novbeti ders, Davamiyyət, 5 suallıq test)
    t.goto(PANEL + "#/g/" + gid); t.reload(); t.wait_for_selector("#gkDers .gkt", timeout=15000); t.wait_for_timeout(600)
    el(t, "#gkDers", "m11_bu_gun")
    # ders paketi (db/135): ilk movzunun isinmesi yigilib, cedvel
    pkid = db("select id::text i from public.class_plans limit 1", one=True)["i"]
    t.goto(PANEL + "#/pk/" + pkid); t.wait_for_selector(".pktab", timeout=15000)
    t.wait_for_timeout(1200)
    shot(t, "m14_paket")

    # ---------------- DEFTER: cedvel + bu gun ders oldu, biri gelmeyib, biri odeyib
    #  177: «Dəftər» sekmesinin basinda artiq CEDVEL setri var.  Sekilde
    #  qurulmus halda gorunsun - «qurulmayıb» yazan bos setir beledciye
    #  hec ne oyretmir.
    t.goto(PANEL + "#/g/" + gid + "/d"); t.reload(); t.wait_for_selector("#schFold", timeout=15000)
    t.eval_on_selector("#schFold", "e => e.open = true"); t.wait_for_timeout(300)
    #  gunlerden biri BU GUNdur (Baki) - Icmalda «Bugünkü dərslər» setri gorunsun
    bugun = (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(hours=4)).isoweekday()
    for w, saat in ((bugun, "16:00"), (6 if bugun != 6 else 3, "11:00")):
        t.locator("#schDays [data-w='%d']" % w).click(); t.wait_for_timeout(200)
        t.select_option("#schTimes [data-t='%d']" % w, saat)
    t.click("#schSave"); t.wait_for_timeout(1500)
    t.eval_on_selector("#schFold", "e => e.open = false"); t.wait_for_timeout(200)
    t.wait_for_selector("#ledOpen", timeout=15000); t.click("#ledOpen")
    t.wait_for_selector("#ledChips [data-st]", timeout=15000)
    t.locator("#ledChips [data-st]").nth(2).click(); t.click("#ledSave")
    t.wait_for_selector("#ledEdit", timeout=15000)
    t.locator("[data-pay]").first.click(); t.wait_for_selector(".pay.on", timeout=15000); t.wait_for_timeout(400)
    el(t, "#ledgerBox", "m12_defter")

    # ---------------- ICMAL (ana ekran): Bugünkü dərslər · Qruplarım · Siqnallar
    db("update public.students set created_at = now() - interval '20 days'")
    t.goto(PANEL + "#/"); t.reload(); t.wait_for_selector("#yMenu .ytr", timeout=15000); t.wait_for_timeout(1500)
    shot(t, "m3_icmal", full=True)
    # Siqnallar → «Son 7 gündə test işləməyənlər», her setirde «Xatırlat»
    t.goto(PANEL + "#/sus"); t.reload(); t.wait_for_selector("#suBox .surow", timeout=15000); t.wait_for_timeout(600)
    shot(t, "m15_xatirlat")

    # ---------------- VALIDEYN (390x844)
    v = page(ctx, 390, 844)
    v.goto(PARENT); v.wait_for_selector("#code", timeout=15000)
    v.fill("#code", pcode); shot(v, "v1_giris")
    v.click("#btnIn"); v.wait_for_selector(".who", timeout=15000); shot(v, "v2_usagim", full=True)
    db("update public.tests set status='published' where slug='riy-3-analiz'")
    br.close()
print("HAZIR:", sorted(os.listdir(OUT)))
