#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Valideyn tetbiqi + muellim panelindeki acma/baglama duymesi.

Bu suite iki seyi olcur:
  1. Muellim valideyn girisini ACIR/BAGLAYIR - ve SUSMAYA GORE BAGLIDIR.
  2. Valideyn ekrani DOGRU melumati gosterir, YANLISLARINI gostermir:
     usagin giris kodu, duz cavablar, basqa usaqlar - hec biri.
"""
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

APP    = "http://127.0.0.1:8010/valideyn/index.html"
PANEL  = "http://127.0.0.1:8010/muellim/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN    = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
TEST_CFG = """window.CFG = {
  SUPABASE_URL: "http://127.0.0.1:54321",
  SUPABASE_ANON_KEY: "test-anon-key"
};"""

fails = []
def ok(cond, label, extra=""):
    print(("  OK   " if cond else "  FAIL ") + label + (("  " + str(extra)) if extra else ""), flush=True)
    if not cond: fails.append(label)

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            return cur.fetchone() if one else cur.fetchall()

# ---------------------------------------------------------- hazirliq
#  Muellim UI-dan qeydiyyatdan kecir (panelin oz axini) - sonra qrup ve
#  sagirdler SQL ile qoyulur ki, suite qisa qalsin.
db("""
delete from public.parent_sessions;
delete from public.question_reports;
delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments;     delete from public.student_sessions;
delete from public.class_plan_items; delete from public.class_plans;
delete from public.students;        delete from public.classes;
delete from public.test_questions tq using public.tests t
 where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.subscriptions;
delete from public.account_members; delete from public.accounts;
delete from public.user_roles;      delete from auth.users;
""")

with sync_playwright() as pw:
    br  = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 390, "height": 860})

    # =================================================== A · MUELLIM
    print("A · Müəllim valideyn girişini açır")
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=TEST_CFG))
    pg.goto(PANEL); pg.wait_for_timeout(400)
    pg.click("#btnSwap")
    pg.fill("#fname", "Aygun Muellim"); pg.fill("#email", "v@t.az")
    pg.fill("#pass", "parol1234")
    pg.click("#btnAuth"); pg.wait_for_selector("#btnSetup", timeout=15000)
    pg.select_option("#atype", "tutor"); pg.fill("#aname", "Riyaziyyat")
    pg.click("#btnSetup"); pg.wait_for_selector("#btnGroup", timeout=15000)

    #  Qrup ve iki sagird - SQL ile, suite qisa qalsin
    acc = db("select id, owner_id from public.accounts limit 1", one=True)
    db("""insert into public.classes (id, account_id, teacher_id, kind, name, join_code)
          values ('c1c1c1c1-0000-0000-0000-0000000000c1', %s, %s,
                  'tutor_group','5-A qrupu','QRUPVAL1')""",
       (acc["id"], acc["owner_id"]))
    db("""insert into public.students (id, account_id, class_id, created_by,
                                       full_name, display_name, login_code)
          values ('d1d1d1d1-0000-0000-0000-0000000000c1', %s,
                  'c1c1c1c1-0000-0000-0000-0000000000c1', %s,
                  'Ayan Qasimova','Ayan Q.','SAGIRD11'),
                 ('d1d1d1d1-0000-0000-0000-0000000000c2', %s,
                  'c1c1c1c1-0000-0000-0000-0000000000c1', %s,
                  'Rasad Memmedov','Rasad M.','SAGIRD22')""",
       (acc["id"], acc["owner_id"], acc["id"], acc["owner_id"]))

    pg.reload(); pg.wait_for_selector("#groups", timeout=15000)
    pg.locator("#groups .grp, #groups .item").first.click()
    pg.wait_for_selector(".stu", timeout=15000)

    #  SUSMAYA GORE BAGLI - setirde HEC NE gorunmur
    ok(pg.locator(".stu .l3").count() == 0,
       "susmaya gore BAGLI - setirde valideyn sətri yoxdur")
    ok(db("""select count(*) n from public.students
              where parent_code is not null""", one=True)["n"] == 0,
       "bazada da kod yoxdur")
    #  Telefonda setir sismemelidir - qelemin altinda oldugu ucun
    pg.set_viewport_size({"width": 360, "height": 780})
    h = pg.locator(".stu").first.evaluate("e => e.getBoundingClientRect().height")
    ok(h <= 120, "bagli ikən setir telefonda yigcam qalir", str(round(h)) + "px")
    pg.set_viewport_size({"width": 390, "height": 860})

    #  Acmaq qelemin altindadir - birdefelik qerardir, gundelik is deyil
    row = pg.locator('.stu:has-text("Ayan Qasimova")')
    row.locator("[data-edit]").click()
    pg.wait_for_selector(".edit .pbox [data-pon]", timeout=15000)
    ok("dərslərini" in pg.inner_text(".edit .pbox"),
       "acmadan evvel valideynin NE gorecəyi yazilir")
    row.locator("[data-pon]").click()
    pg.wait_for_selector('.stu:has-text("Ayan Qasimova") [data-poff]', timeout=15000)
    kod = db("""select parent_code c from public.students
                 where full_name = 'Ayan Qasimova'""", one=True)["c"]
    ok(bool(kod) and len(kod) == 8, "kod yarandi", kod)
    ok(kod.startswith("V"), "valideyn kodu «V» ile baslayir - sagird kodundan secilir")
    ok(pg.locator('.stu:has-text("Ayan Qasimova") .l3 .code').inner_text() == kod,
       "kod ekranda gorunur")
    #  Ikinci sagird TOXUNULMAMIS qalir
    ok(db("""select parent_code c from public.students
              where full_name = 'Rasad Memmedov'""", one=True)["c"] is None,
       "o biri sagird toxunulmamis qalir")

    # ================================================== B · VALIDEYN
    print("B · Valideyn kodla girir")
    #  Bir nece netice ve bir gozleyen tapsiriq quraq
    db("""
      insert into public.tests (id, owner_type, owner_id, class_id, program_id,
                                subject_id, title, status)
      select 'e1e1e1e1-0000-0000-0000-0000000000c1','educator', a.owner_id,
             'c1c1c1c1-0000-0000-0000-0000000000c1',
             (select id from public.programs limit 1),
             (select id from public.subjects where slug='riyaziyyat'),
             'Kesrler - 1','published'
        from public.accounts a limit 1;
      insert into public.tests (id, owner_type, owner_id, class_id, program_id,
                                subject_id, title, status)
      select 'e1e1e1e1-0000-0000-0000-0000000000c2','educator', a.owner_id,
             'c1c1c1c1-0000-0000-0000-0000000000c1',
             (select id from public.programs limit 1),
             (select id from public.subjects where slug='riyaziyyat'),
             'Gozleyen test','published'
        from public.accounts a limit 1;
      insert into public.attempts (student_id, test_id, class_id, status,
                                   score, max_score, percent, finished_at)
      values ('d1d1d1d1-0000-0000-0000-0000000000c1',
              'e1e1e1e1-0000-0000-0000-0000000000c1',
              'c1c1c1c1-0000-0000-0000-0000000000c1','submitted',
              8, 10, 80, now() - interval '3 days'),
             ('d1d1d1d1-0000-0000-0000-0000000000c1',
              'e1e1e1e1-0000-0000-0000-0000000000c1',
              'c1c1c1c1-0000-0000-0000-0000000000c1','submitted',
              5, 10, 50, now() - interval '45 days');
      insert into public.assignments (class_id, test_id, opens_at, closes_at, max_attempts)
      values ('c1c1c1c1-0000-0000-0000-0000000000c1',
              'e1e1e1e1-0000-0000-0000-0000000000c2',
              now() - interval '1 day', now() + interval '1 day', 1);
    """)
    vp = ctx.new_page()
    vp.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=TEST_CFG))
    vp.goto(APP); vp.wait_for_selector("#code", timeout=15000)
    vp.fill("#code", "YANLIS99"); vp.click("#btnIn")
    vp.wait_for_selector("#lErr .err", timeout=15000)
    ok("yanlış" in vp.inner_text("#lErr").lower() or
       "tapilmadi" in vp.inner_text("#lErr").lower(),
       "yanlis kod redd olunur", vp.inner_text("#lErr"))

    vp.fill("#code", kod); vp.click("#btnIn")
    vp.wait_for_selector(".who", timeout=15000)
    metn = vp.inner_text("#main")
    ok("Ayan Q." in metn, "usagin GORUNEN adi cixir")
    ok("Qasimova" not in metn, "TAM AD ekranda YOXDUR")
    ok("SAGIRD11" not in metn, "usagin giris kodu ekranda YOXDUR")
    ok("Rasad" not in metn, "basqa usagin adi ekranda YOXDUR")
    ok("5-A qrupu" in metn, "qrupun adi gorunur")
    ok("Aygun Muellim" in metn, "muellimin adi gorunur")

    print("C · Ekranın bölmələri")
    ok("80%" in metn, "son 30 gunun ortalamasi cixir", metn.split("\n")[0:6])
    #  IKI TELE BIR YERDE:
    #  1. base.css h2-ni BOYUK HERFE cevirir, inner_text ise ekranda
    #     GORUNEN metni verir - "Gözləyən tapşırıq" tapilmir.
    #  2. .lower() ile duzeltmek de olmur: Python "TAPŞIRIQ".lower()
    #     -> "tapşiriq" verir (noqtesiz "ı" noqteli "i"-ye cevrilir).
    #  Ona gore noqtesiz "ı" olmayan hisseye baxiriq.
    ok("GÖZLƏYƏN" in metn, "gozleyen tapsiriq bolmesi var")
    ok("Gozleyen test" in metn, "gozleyen tapsiriq siyahida")
    ok("sabah bitir" in metn or "saat qalıb" in metn or "bu gün bitir" in metn,
       "son tarixe ne qaldigi yazilir")
    ok("Kesrler - 1" in metn, "son netice siyahida")
    #  ARTIQ YAZILMIS test gozleyenler arasinda OLMAMALIDIR
    pend = vp.locator("h2:has-text('Gözləyən') + .card").inner_text()
    ok("Kesrler" not in pend, "yazilmis test gozleyenlerde gorunmur", pend.replace("\n", " "))

    print("D · Sessiya saxlanılır, çıxış işləyir")
    vp.reload(); vp.wait_for_selector(".who", timeout=15000)
    ok("Ayan Q." in vp.inner_text("#main"), "sehife yenilenende sessiya qalir")
    vp.click("#btnOut"); vp.wait_for_selector("#code", timeout=15000)
    ok(vp.locator("#code").count() == 1, "cixisdan sonra giris ekrani")
    ok(db("select count(*) n from public.parent_sessions", one=True)["n"] == 0,
       "cixis sessiyani bazadan da silir")

    print("E · Müəllim bağlayanda giriş dərhal kəsilir")
    vp.fill("#code", kod); vp.click("#btnIn")
    vp.wait_for_selector(".who", timeout=15000)
    ok(True, "valideyn yeniden girdi")

    pg.once("dialog", lambda d: d.accept())
    row.locator("[data-poff]").click()
    #  Baglananda setirdeki valideyn xetti ITIR (acmaq qelemin altina qayidir)
    pg.wait_for_function(
        "() => document.querySelectorAll('.stu .l3').length === 0", timeout=15000)
    ok(db("""select parent_code c from public.students
              where full_name = 'Ayan Qasimova'""", one=True)["c"] is None,
       "kod bazadan silindi")
    ok(db("select count(*) n from public.parent_sessions", one=True)["n"] == 0,
       "acilmis sessiya da derhal oldu")
    vp.reload()
    vp.wait_for_selector("#code", timeout=15000)
    ok(vp.locator("#code").count() == 1,
       "valideyn ekrani baglandi - giris ekranina qayidir")

    br.close()

print()
if fails:
    print("VALIDEYN: %d yoxlama SINDI" % len(fails))
    for f in fails: print("   - " + f)
    raise SystemExit(1)
print("VALIDEYN: BUTUN YOXLAMALAR KECDI")
