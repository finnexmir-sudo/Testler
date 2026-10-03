#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sagird ana sehifesi (04.10): «Serbest mesq» GIZLIDIR + «Yeni test» bildirisi (tetbiqin icinde, push deyil).

Qaydalar:
  - sehifede «Sərbəst məşq» basligi ve platforma test siyahisi YOXDUR; yalniz muellimin tapsiriqlari var;
  - ilk acilis: movcud tapsiriqlar «gorulmus» sayilir -> bildiris YOXDUR;
  - muellim yeni tapsiriq verir -> yeniden acanda «Yeni test» karti: bir testdirse adi, coxdursa «N yeni test»;
  - «Sonra» / «Bax» / «Başla» kartı baglayir, bir daha cixmir (bu cihazda);
  - icaze sorgusu, xarici sorgu, JS xetasi yoxdur.
390 ve 1280 px."""
import os, sys
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

ROOT = "http://127.0.0.1:8010/"
STUDENT = ROOT + "sagird/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
OUT = "/tmp/claude-0/sagirdbildiris"; os.makedirs(OUT, exist_ok=True)
BLOCK = "**://*.supabase.co/**"
CFG = """window.CFG = {SUPABASE_URL:"http://127.0.0.1:54321", SUPABASE_ANON_KEY:"test-anon-key",
  STUDENT_URL:"http://127.0.0.1:8010/sagird/", PARENT_URL:"http://127.0.0.1:8010/valideyn/", SHOW_PLANS:false};"""

fails = []
def ok(cond, label, extra=""):
    print(("  OK   " if cond else "  FAIL ") + label + (("  " + str(extra)) if (extra != "" and not cond) else ""), flush=True)
    if not cond: fails.append(label)

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            return cur.fetchone() if one else cur.fetchall()

db("""
delete from public.question_reports; delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments; delete from public.student_sessions; delete from public.students; delete from public.classes;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.question_options o using public.questions q where q.id = o.question_id and q.owner_type = 'educator';
delete from public.questions where owner_type = 'educator';
delete from public.subscriptions; delete from public.account_members; delete from public.accounts;
delete from public.user_roles; delete from public.profiles; delete from auth.users;""")
db("update public.app_state set val = '{\"on\": false}' where key = 'hesab_bagli'")

OWN, ACC = "11110000-0000-0000-0000-0000000006a1", "aaaa0000-0000-0000-0000-0000000006a1"
db("insert into auth.users (id, email) values (%s, 'bildiris@t.az')", (OWN,))
db("insert into public.accounts (id, type, name, owner_id) values (%s, 'tutor', 'Bildiris', %s)", (ACC, OWN))
db("insert into public.account_members values (%s, %s, true)", (ACC, OWN))
db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
      select %s::uuid, p.id, 'trialing', now() + interval '30 days' from public.plans p where p.slug = 'repetitor-25'""", (ACC,))
GID = db("""insert into public.classes (account_id, teacher_id, kind, name, join_code)
            values (%s, %s, 'tutor_group', 'Bildiris sinfi', 'BLD00001') returning id::text i""", (ACC, OWN), one=True)["i"]
db("""insert into public.students (account_id, class_id, created_by, full_name, display_name, login_code)
      values (%s, %s, %s, 'Lalə Test', 'Lalə T.', 'BILDIRIS')""", (ACC, GID, OWN))
TESTS = [r["i"] for r in db("""select t.id::text i from public.tests t where t.owner_type = 'platform' and t.status = 'published'
                                order by t.slug limit 8""")]
#  yerli bazada platforma testi azdir: ilk testden 2 nusxe (muellim testi) - 6 ayri tapsiriq lazimdir
for n in (1, 2):
    nid = db("""insert into public.tests (owner_type, owner_id, title, program_id, subject_id, pass_percent, is_free, status)
                select 'educator', %s::uuid, 'Bildiris testi ' || %s, program_id, subject_id, 50, false, 'published'
                  from public.tests where id = %s::uuid returning id::text i""", (OWN, str(n), TESTS[0]), one=True)["i"]
    db("""insert into public.test_questions (test_id, question_id, ord)
          select %s::uuid, question_id, ord from public.test_questions where test_id = %s::uuid""", (nid, TESTS[0]))
    TESTS.append(nid)
TITLE = {r["i"]: r["t"] for r in db("select id::text i, title t from public.tests where id = any(%s::uuid[])", (TESTS,))}
def ver(*idx):
    for i in idx:
        db("insert into public.assignments (class_id, test_id, assigned_by) values (%s, %s, %s)", (GID, TESTS[i], OWN))
ver(0, 1)       # ilk acilisdan ONCE verilmis iki tapsiriq

def page(ctx):
    p = ctx.new_page()
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    p.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    p.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))
    return p

def ac(p):
    p.reload(); p.wait_for_selector(".test", timeout=20000); p.wait_for_timeout(500)

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    for w, h, tag in ((390, 844, "tel"), (1280, 800, "masa")):
        print("== %s (%dx%d)" % (tag, w, h))
        ctx = br.new_context(viewport={"width": w, "height": h})
        sp = page(ctx)
        sp.goto(STUDENT); sp.wait_for_selector("#btnIn", timeout=15000)
        sp.fill("#code", "BILDIRIS"); sp.click("#btnIn"); sp.wait_for_selector(".test", timeout=15000); sp.wait_for_timeout(600)

        print("1 · Sərbəst məşq gizlidir")
        txt = sp.inner_text("#main")
        ok("Sərbəst məşq" not in txt, "«Sərbəst məşq» başlığı yoxdur")
        ok(sp.locator("#pracBox").count() == 0 and sp.locator("#pSub").count() == 0, "platforma test siyahısı və fənn çipləri yoxdur")
        ok(sp.locator(".test").count() == 2, "yalnız müəllimin 2 tapşırığı görünür", sp.locator(".test").count())

        print("2 · İlk açılış: mövcud tapşırıqlar «görülmüş» — bildiriş yoxdur")
        ok(sp.locator("#newBox").count() == 0, "ilk açılışda «Yeni test» kartı yoxdur")

        print("3 · Müəllim yeni tapşırıq verir → bir yeni test")
        ver(2); ac(sp)
        ok(sp.locator("#newBox").count() == 1, "«Yeni test» kartı çıxdı")
        box = sp.inner_text("#newBox")
        ok(TITLE[TESTS[2]] in box and "TEST" in box.upper(), "kartda yeni testin adı yazılıb", box.replace("\n", " "))
        ok(sp.locator("#newBox").evaluate("e => e.getBoundingClientRect().top") < 330, "kart ekranın yuxarısındadır")
        ok(sp.evaluate("document.documentElement.scrollWidth <= window.innerWidth"), "yana sürüşmə yoxdur")
        sp.screenshot(path="%s/%s_yeni_test.png" % (OUT, tag))
        sp.click("#ntX"); sp.wait_for_timeout(200)
        ok(sp.locator("#newBox").count() == 0, "«Sonra» kartı bağladı")
        ac(sp)
        ok(sp.locator("#newBox").count() == 0, "yenidən açanda kart bir daha çıxmır")

        print("4 · Bir neçə yeni tapşırıq → «N yeni test», «Bax» bağlayır")
        ver(3, 4); ac(sp)
        ok("2 yeni test" in sp.inner_text("#newBox").lower(), "«2 yeni test»", sp.inner_text("#newBox").replace("\n", " "))
        ok(sp.locator("#ntGo").inner_text().strip() == "Bax", "düymə «Bax»")
        sp.screenshot(path="%s/%s_iki_yeni.png" % (OUT, tag))
        sp.click("#ntGo"); sp.wait_for_timeout(300)
        ok(sp.locator("#newBox").count() == 0 and sp.locator(".test").count() == 5, "«Bax» kartı bağladı, siyahı yerindədir")
        ac(sp)
        ok(sp.locator("#newBox").count() == 0, "yenidən açanda kart yoxdur")

        print("5 · Tək yeni test → «Başla» testi açır")
        ver(5); ac(sp)
        ok(sp.locator("#ntGo").inner_text().strip() == "Başla", "düymə «Başla»")
        sp.click("#ntGo"); sp.wait_for_selector(".opt", timeout=15000)
        ok(sp.locator(".opt").count() >= 2, "test açıldı (variantlar var)")
        ctx.close()

        # sonraki olcu ucun tapsiriqlari sifirla
        db("delete from public.attempt_answers; delete from public.attempts; delete from public.assignments")
        db("delete from public.student_sessions")
        ver(0, 1)
    br.close()

print("\nNETICE:", "HAMISI KECDI" if not fails else "XETALAR: %d" % len(fails))
for f in fails: print(" -", f)
sys.exit(1 if fails else 0)
