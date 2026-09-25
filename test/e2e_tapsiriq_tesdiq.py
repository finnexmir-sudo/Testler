#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""«Tapşırıq ver»dən SONRA nə yazılır (25.09).

Qizbest muellime uc defe «testi gondermek olmur» yazdi.  Ozumuz yolu
getdik: mexanizm ISLEYIR - tapsiriq bazaya yazilir.  Amma ekran bunu
DEMIRDI: sehife yenilenir, kicik «verilib» setri qalir, testin sagirde
NECE CATDIGI hec yerde yazilmir.

Yoxlanir:
  A  tapsiriqdan sonra tesdiq qutusu cixir
  B  icinde KIME getdiyi yazilir (butun qrup / tek sagird - adi ile)
  C  sagirdin NECE gorecəyi yazilir (oz kodu, ayrica link lazim deyil)
  D  son tarix ve cehd sayi yazilir
  E  tek sagirde verende «yalniz o» deyilir
  F  tesdiq BIR DEFELIKDIR - sehife yenilenende qalmir
  G  qrup adi ekrana ESCAPE olunmus dusur (HTML sizmir)
"""
import sys, time
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

ROOT = "http://127.0.0.1:8010/"
PANEL = ROOT + "muellim/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
CFG = """window.CFG = {SUPABASE_URL:"http://127.0.0.1:54321",
  SUPABASE_ANON_KEY:"test-anon-key", STUDENT_URL:"http://127.0.0.1:8010/sagird/",
  SHOW_PLANS:false};"""

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
delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers;  delete from public.attempts;
delete from public.assignments;      delete from public.student_sessions;
delete from public.students;         delete from public.classes;
delete from public.test_questions tq using public.tests t
 where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.subscriptions;
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from auth.users;
""")

T = int(time.time())
MAIL = "tsd%d@t.az" % T
#  Qrup adinda < > var: ekrana ESCAPE olunmus dusmelidir
QRUP = '6-cı <sinif>'

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 1280, "height": 1000})
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))

    print("A · Hazırlıq")
    pg.goto(PANEL); pg.wait_for_timeout(600)
    pg.click("#btnSwap")
    pg.fill("#fname", "Tesdiq Muellim"); pg.fill("#email", MAIL)
    pg.fill("#pass", "tesdiqparol1"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=20000)
    pg.select_option("#atype", "tutor"); pg.fill("#aname", "Tesdiq hesabi")
    pg.click("#btnSetup"); pg.wait_for_selector("#gForm", timeout=20000)

    uid = db("select id::text i from auth.users where email=%s", (MAIL,), one=True)["i"]
    acc = db("select id::text i from public.accounts where owner_id=%s::uuid", (uid,), one=True)["i"]
    cls = db("""insert into public.classes (account_id, teacher_id, kind, name, join_code, level_id)
                select %s::uuid, %s::uuid, 'tutor_group', %s, 'TSDKOD01', l.id
                  from public.levels l where l.code='3'
                returning id::text i""", (acc, uid, QRUP), one=True)["i"]
    for ad, kod in (("Aysel Məmmədova", "TSDS0001"), ("Murad Əliyev", "TSDS0002")):
        db("""insert into public.students (account_id, class_id, created_by, full_name,
                                           display_name, login_code)
              values (%s::uuid, %s::uuid, %s::uuid, %s, %s, %s)""",
           (acc, cls, uid, ad, ad.split()[0], kod))
    tid = db("""insert into public.tests (owner_type, owner_id, program_id, subject_id, level_id,
                                          slug, title, status, pass_percent)
                select 'educator', %s::uuid, p.id, s.id, l.id, 'tsd-%s', 'Vurma sınağı',
                       'published', 50
                  from public.programs p, public.subjects s, public.levels l
                 where p.slug='ibtidai' and s.slug='riyaziyyat' and l.code='3' limit 1
                returning id::text i""", (uid, T), one=True)["i"]
    db("""insert into public.test_questions (test_id, question_id, ord)
          select %s::uuid, q.id, row_number() over ()
            from public.questions q join public.subjects s on s.id=q.subject_id
           where s.slug='riyaziyyat' and q.owner_type='platform' and q.status='published'
           limit 5""", (tid,))
    print("   qrup «%s» + 2 şagird + test hazır" % QRUP)

    print("B · Bütün qrupa tapşırıq verilir")
    pg.goto(PANEL + "#/t/" + tid); pg.wait_for_selector("#btnPAsg", timeout=20000)
    ok(pg.locator(".pasgok").count() == 0, "tapsiriqdan EVVEL tesdiq qutusu yoxdur")
    pg.select_option("#pDate", "") if False else None
    pg.click("#btnPAsg"); pg.wait_for_timeout(2500)
    ok(pg.locator(".pasgok").count() == 1, "tesdiq qutusu cixdi",
       pg.locator(".pasgok").count())
    t = pg.inner_text(".pasgok") if pg.locator(".pasgok").count() else ""
    print("   mətn: " + t.replace("\n", " ")[:150])
    ok("Tapşırıq verildi" in t, "«Tapşırıq verildi» yazir")
    ok(QRUP in t and "bütün şagirdləri" in t, "KIME getdiyi yazilir (butun qrup, adi ile)")
    ok("öz giriş kodu" in t and "bil10.az/sagird" in t, "sagird NECE gorecek - yazilir")
    ok("link, fayl və ya mesaj göndərmək lazım deyil" in t,
       "elave gondermek lazim olmadigi ACIQ yazilir")
    ok("Son tarix yoxdur" in t, "son tarix qeyd olunur", "-")
    ok("Cəhd sayı: 1" in t, "cehd sayi qeyd olunur")
    #  HTML sizmamalidir: qrup adindaki <sinif> ETIKET kimi acilmamalidir
    ok(pg.locator(".pasgok sinif").count() == 0, "qrup adi escape olunur - HTML sizmir")

    print("C · Təsdiq BİR DƏFƏLİKDİR")
    pg.reload(); pg.wait_for_selector("#pAsgH", timeout=20000)
    ok(pg.locator(".pasgok").count() == 0,
       "sehife yenilenende tesdiq qalmir", pg.locator(".pasgok").count())

    print("D · Tək şagirdə veriləndə «yalnız o» deyilir")
    tid2 = db("""insert into public.tests (owner_type, owner_id, program_id, subject_id, level_id,
                                           slug, title, status, pass_percent)
                 select 'educator', %s::uuid, p.id, s.id, l.id, 'tsd2-%s', 'İkinci sınaq',
                        'published', 50
                   from public.programs p, public.subjects s, public.levels l
                  where p.slug='ibtidai' and s.slug='riyaziyyat' and l.code='3' limit 1
                 returning id::text i""", (uid, T), one=True)["i"]
    db("""insert into public.test_questions (test_id, question_id, ord)
          select %s::uuid, q.id, row_number() over ()
            from public.questions q join public.subjects s on s.id=q.subject_id
           where s.slug='riyaziyyat' and q.owner_type='platform' and q.status='published'
           limit 5""", (tid2,))
    pg.goto(PANEL + "#/t/" + tid2); pg.wait_for_selector("#btnPAsg", timeout=20000)
    sid = db("select id::text i from public.students where login_code='TSDS0001'", one=True)["i"]
    pg.select_option("#pWho", sid); pg.wait_for_timeout(300)
    pg.select_option("#pTry", "3"); pg.wait_for_timeout(200)
    pg.click("#btnPAsg"); pg.wait_for_timeout(2500)
    t2 = pg.inner_text(".pasgok") if pg.locator(".pasgok").count() else ""
    print("   mətn: " + t2.replace("\n", " ")[:150])
    ok("Yalnız Aysel Məmmədova bu testi görür" in t2 and "qrupun qalanı yox" in t2,
       "tek sagirdin ADI ve «qrupun qalani yox» yazilir")
    ok("yalnız yalnız" not in t2.lower(), "«yalniz» sozu tekrarlanmir")
    ok("bütün şagirdləri" not in t2, "«butun qrup» YAZILMIR - yanlis melumat yoxdur")
    ok("Cəhd sayı: 3" in t2, "secilen cehd sayi duzgun yazilir")

    print("E · Telefonda oxunur")
    mctx = br.new_context(viewport={"width": 390, "height": 844})
    m = mctx.new_page()
    m.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=CFG))
    m.goto(PANEL); m.wait_for_timeout(700)
    m.fill("#email", MAIL); m.fill("#pass", "tesdiqparol1"); m.click("#btnAuth")
    m.wait_for_timeout(3000)
    tid3 = db("""insert into public.tests (owner_type, owner_id, program_id, subject_id, level_id,
                                           slug, title, status, pass_percent)
                 select 'educator', %s::uuid, p.id, s.id, l.id, 'tsd3-%s', 'Üçüncü sınaq',
                        'published', 50
                   from public.programs p, public.subjects s, public.levels l
                  where p.slug='ibtidai' and s.slug='riyaziyyat' and l.code='3' limit 1
                 returning id::text i""", (uid, T), one=True)["i"]
    db("""insert into public.test_questions (test_id, question_id, ord)
          select %s::uuid, q.id, row_number() over ()
            from public.questions q join public.subjects s on s.id=q.subject_id
           where s.slug='riyaziyyat' and q.owner_type='platform' and q.status='published'
           limit 5""", (tid3,))
    m.goto(PANEL + "#/t/" + tid3); m.wait_for_selector("#btnPAsg", timeout=20000)
    m.click("#btnPAsg"); m.wait_for_timeout(2500)
    ok(m.locator(".pasgok").count() == 1, "telefonda da tesdiq cixir")
    m.locator(".pasgok").first.scroll_into_view_if_needed(); m.wait_for_timeout(300)
    ok(m.evaluate("() => document.documentElement.scrollWidth <= window.innerWidth + 1"),
       "telefonda yana surusme yaratmir")
    m.screenshot(path="/tmp/claude-0/tsd/tesdiq_telefon.png", full_page=True)
    pg.goto(PANEL + "#/t/" + tid); pg.wait_for_selector("#pAsgH", timeout=20000)
    pg.screenshot(path="/tmp/claude-0/tsd/tesdiq_masaustu.png", full_page=True)
    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails))
    for f in fails: print("  - " + f)
    sys.exit(1)
print("TAPSIRIQ TESDIQI: BUTUN YOXLAMALAR KECDI")
