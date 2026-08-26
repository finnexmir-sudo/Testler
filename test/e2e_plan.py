#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Ders plani axini: qurulus -> kecildi -> test teklifi -> tapsiriq.

Pullu qapi da yoxlanir: abunesiz kilid karti gorunur.
"""
import sys
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

PANEL  = "http://127.0.0.1:8010/muellim/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN    = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
BLOCK  = "**://*.supabase.co/**"
TEST_CFG = """window.CFG = {
  SUPABASE_URL: "http://127.0.0.1:54321",
  SUPABASE_ANON_KEY: "test-anon-key",
  STUDENT_URL: "https://example.test/Testler/"
};"""

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
delete from public.question_reports;
delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments;     delete from public.student_sessions;
delete from public.students;        delete from public.classes;
delete from public.subscriptions;
delete from public.test_questions tq using public.tests t
 where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.account_members; delete from public.accounts;
delete from public.user_roles;      delete from auth.users;
""")

with sync_playwright() as pw:
    br  = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 1280, "height": 900})
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=TEST_CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))
    pg.on("dialog", lambda d: d.accept())

    pg.goto(PANEL); pg.wait_for_timeout(400)
    pg.click("#btnSwap")
    pg.fill("#fname", "Plan Muellim"); pg.fill("#email", "pln@t.az")
    pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=8000)
    pg.select_option("#atype", "tutor")
    pg.fill("#aname", "Plan hesabi"); pg.click("#btnSetup")
    pg.wait_for_selector("#btnBank", timeout=8000)
    AID = db("select id::text i from public.accounts", one=True)["i"]
    UID = db("select id::text i from auth.users where email='pln@t.az'", one=True)["i"]
    db("""insert into public.classes (id, account_id, teacher_id, kind, name, join_code)
          values ('cccc1111-0000-0000-0000-0000000000e9', %s, %s,
                  'tutor_group', 'Plan qrupu', 'KODPLE01')""", (AID, UID))

    print("A · Abunəsiz: kilid kartı")
    pg.goto(PANEL + "#/g/cccc1111-0000-0000-0000-0000000000e9"); pg.reload()
    pg.wait_for_selector(".plock", timeout=8000)
    ok("abunə paketi" in pg.inner_text(".plock"), "kilid karti gorunur")

    print("B · Abunə ilə: plan qurulur")
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select %s, p.id, 'active', now() + interval '30 days'
            from public.plans p where p.slug = 'repetitor-25'""", (AID,))
    pg.reload()
    pg.wait_for_selector("#btnPlMk", timeout=8000)
    pg.wait_for_function("document.querySelectorAll('#plSub option').length > 1", timeout=8000)
    subs = pg.locator("#plSub option").all_inner_texts()
    ndb = db("select count(distinct subject_id) n from public.topics "
             "where level_id is not null", one=True)["n"]
    ok(len(subs) == ndb, "yalniz movzu agaci olan fennler", (len(subs), ndb))
    pg.select_option("#plSub", "riyaziyyat")
    pg.select_option("#plLev", "3")
    pg.click("#btnPlMk")
    pg.wait_for_selector(".plan", timeout=8000)
    ntop = db("""select count(*) n from public.topics t
                  join public.subjects s on s.id=t.subject_id
                  join public.levels l on l.id=t.level_id
                 where s.slug='riyaziyyat' and l.code='3'""", one=True)["n"]
    head = pg.inner_text(".plan .plhead").replace("\n", " ")
    ok(("0 / %d" % ntop) in head, "irelileyis 0/N gorunur", head)
    # CSS text-transform metni boyutdur - metn yox, quruluş yoxlanır
    ok(pg.locator(".plcur [data-pldone]").count() == 1,
       "cari movzu ve Keçildi duymesi var")

    print("C · «Keçildi» → təklif → test + tapşırıq")
    pg.locator("[data-pldone]").click()
    pg.wait_for_selector(".ploffer", timeout=8000)
    ok("Yoxlama testi yığılsınmı" in pg.inner_text(".ploffer"), "teklif cixir")
    pg.fill("#plCnt", "5")
    pg.locator("[data-pltest]").click()
    # .ok sinfi .plrow.ok ile toqqusur - netice qutusu plm- konteynerindedir
    pg.wait_for_selector(".plan [id^='plm-'] a", timeout=10000)
    ok("tapşırıq verildi" in pg.inner_text(".plan [id^='plm-']"), "netice mesaji")
    t = db("""select t.id::text i,
                     (select count(*) from public.test_questions tq
                       where tq.test_id = t.id) nq
                from public.tests t where t.owner_type='educator'""", one=True)
    ok(t and t["nq"] == 5, "test 5 sualliqdir", t and t["nq"])
    ok(bool(db("select 1 ok from public.assignments where test_id = %s", (t["i"],), one=True)),
       "tapsiriq bazada var")
    head = pg.inner_text(".plan .plhead").replace("\n", " ")
    ok(("1 / %d" % ntop) in head, "irelileyis 1/N oldu", head)

    print("D · Siyahı, vərəq linki, geri qaytarma")
    pg.locator(".plan summary").click(); pg.wait_for_timeout(300)
    ok(pg.locator(".plrow").count() == ntop, "butun movzular siyahida",
       pg.locator(".plrow").count())
    ok(pg.locator(".plrow.ok").count() == 1, "kecilmis isarelenib")
    ok(pg.locator(".plrow .pltest").count() == 1, "veraq linki var")
    pg.locator("[data-plundo]").click()
    pg.wait_for_timeout(900)
    head = pg.inner_text(".plan .plhead").replace("\n", " ")
    ok(("0 / %d" % ntop) in head, "geri qaytarma isledi", head)

    print("E · Yenidən keçildi → «Sonra» yolu")
    pg.locator("[data-pldone]").click()
    pg.wait_for_selector(".ploffer", timeout=8000)
    pg.locator("[data-plskip]").click()
    pg.wait_for_timeout(300)
    ok(pg.locator(".ploffer").count() == 0, "teklif baglanir")

    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails))
    for f in fails: print("  - " + f)
    sys.exit(1)
print("PLAN: BUTUN YOXLAMALAR KECDI")
