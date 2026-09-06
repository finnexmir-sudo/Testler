#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Kurikulum paketi - ucdan-uca (db/135, yol xeritesi 22.d).

Ders plani qurulur; "Ders paketi" ekraninda isinme (5 sual, dersden
evvel), ev tapsirigi (Kecildi-den sonra, 10 sual) ve rub sinagi (kecilmis
movzulardan 20 sual) bir toxunusla yigilib tapsirilir; "Bu gunun dersi"
kartinda isinme; sagird uc tapsirigi gorur."""
import time
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

PANEL   = "http://127.0.0.1:8010/muellim/index.html"
STUDENT = "http://127.0.0.1:8010/sagird/index.html"
CHROME  = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN     = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
TEST_CFG = """window.CFG = {
  SUPABASE_URL: "http://127.0.0.1:54321",
  SUPABASE_ANON_KEY: "test-anon-key",
  STUDENT_URL: "http://127.0.0.1:8010/sagird/",
  PARENT_URL:  "http://127.0.0.1:8010/valideyn/",
  SHOW_PLANS: false
};"""
BLOCK = "**://*.supabase.co/**"

fails = []
def ok(cond, label, extra=""):
    print(("  OK   " if cond else "  FAIL ") + label + (("  " + str(extra)) if extra else ""), flush=True)
    if not cond: fails.append(label)

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            return cur.fetchone() if one else cur.fetchall()

db("""
delete from public.plan_exams; delete from public.question_stats; delete from public.practice; delete from public.mistakes;
delete from public.feedback; delete from public.question_reports; delete from public.parent_sessions;
delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers; delete from public.attempts; delete from public.assignments;
delete from public.student_sessions; delete from public.students; delete from public.classes;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator'; delete from public.subscriptions;
delete from public.account_members; delete from public.accounts; delete from public.user_roles;
delete from public.profiles; delete from auth.users;""")

EMAIL = "paket%d@t.az" % int(time.time())

def page(ctx, w, h):
    pg = ctx.new_page(); pg.set_viewport_size({"width": w, "height": h})
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=TEST_CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))
    pg.on("dialog", lambda d: (fails.append("DIALOQ: " + d.message), d.dismiss()))
    return pg

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context()
    pg = page(ctx, 430, 1000)

    print("A · Hazırlıq: müəllim (abunəli), qrup, şagird, dərs planı")
    pg.goto(PANEL); pg.wait_for_selector("#btnAuth", timeout=15000)
    pg.click("#btnSwap")
    pg.fill("#fname", "Paket Müəllim"); pg.fill("#email", EMAIL)
    pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=15000)
    pg.select_option("#atype", "tutor"); pg.fill("#aname", "Paket hesabı"); pg.click("#btnSetup")
    pg.wait_for_selector("#btnGroup", timeout=15000)
    pg.fill("#gname", "3-cü sinif"); pg.select_option("#glevel", "3"); pg.click("#btnGroup")
    pg.wait_for_selector("#groups .item", timeout=15000)
    pg.click("#groups .item"); pg.wait_for_selector("#gTabs", timeout=15000)
    try: pg.wait_for_selector("#sname", state="visible", timeout=3000)
    except Exception: pg.click("#btnStuOpen")
    pg.fill("#sname", "Ayan Bir"); pg.click("#btnStu"); pg.wait_for_selector(".stu", timeout=15000)
    GID  = db("select id::text i from public.classes limit 1", one=True)["i"]
    AID  = db("select id::text i from public.accounts limit 1", one=True)["i"]
    CODE = db("select login_code c from public.students limit 1", one=True)["c"]
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select %s, p.id, 'active', now() + interval '30 days' from public.plans p where p.slug='repetitor-25'""", (AID,))
    pg.reload(); pg.wait_for_selector("#gTabs", timeout=15000); pg.click("#gTabs [data-v='p']")
    pg.wait_for_selector("#btnPlOpen", timeout=15000); pg.click("#btnPlOpen"); pg.wait_for_selector("#btnPlMk", timeout=8000)
    pg.wait_for_function("document.querySelectorAll('#plSub option').length > 1", timeout=8000)
    pg.select_option("#plSub", "riyaziyyat"); pg.select_option("#plLev", "3"); pg.click("#btnPlMk")
    pg.wait_for_selector(".plan .plhead", timeout=15000)
    PLAN = db("select id::text i from public.class_plans limit 1", one=True)["i"]
    NIT = db("select count(*) n from public.class_plan_items", one=True)["n"]
    ok(pg.locator(".plpack").count() == 1 and "Dərs paketi" in pg.locator(".plpack").inner_text(), "plan kartinda «Dərs paketi» linki")

    print("B · Paket ekranı: cədvəl, isinmə bir toxunuşla")
    pg.locator(".plpack").click(); pg.wait_for_selector(".pktab", timeout=15000)
    ok(pg.locator(".pkr").count() == NIT, "her movzu bir setir", (pg.locator(".pkr").count(), NIT))
    ok(pg.locator(".pkr [data-pkwarm]").count() == NIT, "her movzuda isinme duymesi")
    ok(pg.locator(".pkr [data-pkhw]").count() == 0 and pg.locator(".pkr .pkc.no").count() == NIT, "kecilmemis movzuda ev tapsirigi yoxdur")
    ok(pg.locator("#pkExam").is_disabled(), "sinaq: kecilmis movzu yoxdur - duyme bagli")
    pg.locator(".pkr").first.locator("[data-pkwarm]").click()
    pg.wait_for_selector("#pkMsg .ok", timeout=20000)
    ok("İsinmə yığıldı" in pg.inner_text("#pkMsg") and "5 sual" in pg.inner_text("#pkMsg"), "isinme yigildi mesaji", pg.inner_text("#pkMsg"))
    W = db("select i.warm_test_id::text t, (select count(*) from public.test_questions tq where tq.test_id=i.warm_test_id) n from public.class_plan_items i order by ord limit 1", one=True)
    ok(W["t"] and W["n"] == 5, "isinme testi 5 sualla bazada", W)
    ok(db("select count(*) n from public.assignments where test_id=%s and max_attempts=1 and closes_at < now() + interval '26 hours'", (W["t"],), one=True)["n"] == 1, "isinme 1 gune tapsirilib")
    fr = pg.locator(".pkr").first
    ok(fr.locator(".pkc.has").count() == 1 and "verilib" in fr.inner_text(), "setirde isinme «verilib»", fr.inner_text().replace("\n", " "))

    print("C · Keçildi → ev tapşırığı 10 sual; sınaq keçilmiş mövzulardan")
    pg.goto(PANEL + "#/g/" + GID); pg.reload(); pg.wait_for_selector("#gTabs", timeout=15000); pg.click("#gTabs [data-v='p']")
    pg.wait_for_selector("[data-pldone]", timeout=15000); pg.locator("[data-pldone]").click()
    pg.wait_for_selector("[data-plskip]", timeout=15000); pg.locator("[data-plskip]").click()
    pg.goto(PANEL + "#/pk/" + PLAN); pg.reload(); pg.wait_for_selector(".pktab", timeout=15000)
    fr = pg.locator(".pkr").first
    ok("done" in (fr.get_attribute("class") or "") and fr.locator("[data-pkhw]").count() == 1, "kecilmis movzuda ev tapsirigi duymesi")
    fr.locator("[data-pkhw]").click(); pg.wait_for_selector("#pkMsg .ok", timeout=20000)
    ok("Ev tapşırığı yığıldı" in pg.inner_text("#pkMsg"), "ev tapsirigi yigildi", pg.inner_text("#pkMsg"))
    H = db("select (select count(*) from public.test_questions tq where tq.test_id=i.test_id) n from public.class_plan_items i order by ord limit 1", one=True)
    ok(H["n"] == 10, "ev tapsirigi 10 sual", H)
    ok("son sınaqdan sonra 1 mövzu keçilib" in pg.inner_text(".pkexam") and not pg.locator("#pkExam").is_disabled(), "sinaq: 1 movzu gozleyir")
    pg.fill("#pkCnt", "12"); pg.click("#pkExam"); pg.wait_for_selector("#pkMsg .ok", timeout=25000)
    ok("Sınaq yığıldı" in pg.inner_text("#pkMsg") and "1 mövzu" in pg.inner_text("#pkMsg"), "sinaq yigildi", pg.inner_text("#pkMsg"))
    E = db("select t.title, (select count(*) from public.test_questions tq where tq.test_id=t.id) n, cardinality(e.item_ids) k from public.plan_exams e join public.tests t on t.id=e.test_id", one=True)
    ok(E and E["title"].startswith("Rüb sınağı") and E["n"] == 12 and E["k"] == 1, "sinaq bazada: 12 sual, 1 movzu", E)
    ok(pg.locator(".pkexr").count() == 1 and "hələ yazan yoxdur" in pg.inner_text(".pkexl"), "sinaq siyahida")
    ok(pg.locator(".pkr").first.locator(".pkex").count() == 1, "movzuda «sınaq» nisani")
    ok(pg.locator("#pkExam").is_disabled() and pg.locator("#pkExamAll").count() == 1, "sinaqdan sonra gozleyen 0, «Hamısından» var")

    print("D · Bu günün dərsi: növbəti mövzunun isinməsi")
    pg.goto(PANEL + "#/g/" + GID); pg.reload(); pg.wait_for_selector("#prep", timeout=15000)
    pg.wait_for_selector("#prepWarm", timeout=15000)
    ok(pg.locator("#prepWarm").count() == 1, "novbeti movzuda «isinmə 5 sual» duymesi")
    pg.click("#prepWarm"); pg.wait_for_selector("#prep a[href^='#/t/']", timeout=20000)
    ok("isinmə verilib" in pg.inner_text("#prep"), "isinme verildi, vereq linki", pg.inner_text("#prep")[:120].replace("\n", " "))

    print("E · Şagird üç tapşırığı görür")
    sp = page(ctx, 390, 844)
    sp.goto(STUDENT); sp.wait_for_selector("#btnIn", timeout=15000)
    sp.fill("#code", CODE); sp.click("#btnIn"); sp.wait_for_selector(".test", timeout=15000)
    st = sp.inner_text("body")
    ok(sp.locator(".test.asg").count() == 4 and "İsinmə" in st and "Rüb sınağı" in st, "isinme x2, ev tapsirigi, sinaq tapsiriqlarda", sp.locator(".test.asg").count())

    br.close()

print()
if fails:
    print("XETA:", len(fails)); [print("  -", f) for f in fails]; raise SystemExit(1)
print("hamisi kecdi")
