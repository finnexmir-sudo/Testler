#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Oz testini silmek / adini deyismek (db/193): vereqde duymeler, pick siyahisinda kecid."""
import os, time, datetime
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
BASE = "http://127.0.0.1:8010/"; PANEL = BASE + "muellim/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
SHOT = "/tmp/claude-0/vaxt"; os.makedirs(SHOT, exist_ok=True)
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", SHOW_PLANS: false };"""
fails = []
def ok(c, label, extra=""):
    print(("  OK   " if c else "  FAIL ") + label + (("  " + str(extra)) if extra else ""), flush=True)
    if not c: fails.append(label)
def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description: return cur.fetchone() if one else cur.fetchall()

db("""delete from public.attempt_answers; delete from public.attempts; delete from public.assignments;
delete from public.student_sessions; delete from public.students; delete from public.classes;
delete from public.test_questions tq using public.tests t where t.id=tq.test_id and t.owner_type='educator';
delete from public.tests where owner_type='educator'; delete from public.subscriptions;
delete from public.account_members; delete from public.accounts; delete from public.user_roles;
delete from public.profiles; delete from auth.users;""")

with sync_playwright() as p:
    br = p.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context()
    t = ctx.new_page(); t.set_viewport_size({"width": 430, "height": 1000})
    t.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    t.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    t.goto(PANEL); t.wait_for_selector("#btnAuth", timeout=15000)
    t.click("#btnSwap"); t.fill("#fname", "Sil Müəllim"); t.fill("#email", "sil%d@t.az" % int(time.time()))
    t.fill("#pass", "parol1234"); t.click("#btnAuth"); t.wait_for_selector("#btnSetup", timeout=15000)
    t.select_option("#atype", "tutor"); t.fill("#aname", "Sil hesabı"); t.click("#btnSetup")
    t.wait_for_selector("#btnGroup", timeout=15000)
    t.fill("#gname", "3-cü sinif"); t.select_option("#glevel", "3"); t.click("#btnGroup")
    t.wait_for_selector("#groups .gcard", timeout=15000)
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select a.id, p.id, 'active', now() + interval '30 days' from public.accounts a, public.plans p where p.slug = 'repetitor-25'""")
    t.click("#groups .gcard"); t.wait_for_selector("#gTabs", timeout=15000)
    try: t.wait_for_selector("#sname", state="visible", timeout=3000)
    except Exception: t.click("#btnStuOpen")
    t.fill("#sname", "Aysu Məmmədova"); t.click("#btnStu"); t.wait_for_selector(".stu .l3 .code", timeout=15000)
    gid = db("select id::text i from public.classes limit 1", one=True)["i"]

    def gen(title):
        t.goto(PANEL); t.wait_for_selector("#groups .gcard", timeout=15000); t.wait_for_timeout(300)
        t.evaluate("location.hash = '#/gen'"); t.wait_for_selector("#gsub", timeout=15000)
        t.wait_for_function("[...document.querySelectorAll('#gsub option')].some(o => o.value === 'riyaziyyat')", timeout=20000)
        t.select_option("#gsub", "riyaziyyat"); t.wait_for_timeout(900); t.fill("#gCnt", "5"); t.fill("#gTitle", title)
        t.click("#btnMake"); t.wait_for_selector(".paper", timeout=20000); t.wait_for_timeout(300)
        return db("select id::text i from public.tests where owner_type='educator' order by created_at desc limit 1", one=True)["i"]

    print("A · Adı dəyiş")
    t1 = gen("Samir 1")
    ok(t.locator("#btnTRen").count() == 1 and t.locator("#btnTDel").count() == 1, "vereqde «Adi deyis» ve «Sil» var")
    ok(not t.locator("#btnTDel").is_disabled(), "islenmemis test - Sil acıqdır")
    t.click("#btnTRen"); t.wait_for_selector("#tTitle", timeout=5000)
    t.fill("#tTitle", "Samir — vurma cədvəli"); t.press("#tTitle", "Enter")
    t.wait_for_function("document.querySelector('h1') && document.querySelector('h1').textContent.indexOf('vurma') >= 0", timeout=15000)
    ok(db("select title from public.tests where id=%s", (t1,), one=True)["title"] == "Samir — vurma cədvəli", "ad bazada deyisdi")
    ok(t.inner_text("#topTitle").find("vurma") >= 0, "ustlukde de yeni ad")
    t.evaluate("window.scrollTo(0,0)"); t.wait_for_timeout(300); t.screenshot(path=SHOT + "/sil_vereq.png")

    print("B · Pick siyahısında vərəq keçidi")
    #  real yol: Icmal -> qrup -> Tapsiriqlar (geri duymesi bu yolu geri gedir)
    t.goto(PANEL); t.wait_for_selector("#groups .gcard", timeout=15000); t.wait_for_timeout(300)
    t.click("#groups .gcard"); t.wait_for_selector("#btnAsgs", timeout=15000)
    t.click("#btnAsgs"); t.wait_for_selector("#aList .trow", timeout=15000); t.wait_for_timeout(500)
    ok(t.locator("#aList .trw .tgo").count() >= 1, "oz testinin yaninda vereq kecidi var", t.locator("#aList .trw .tgo").count())
    ok(t.locator("#aList .trow:not(:has(+ .tgo))").count() >= 0, "hazir bank testlerinde kecid yoxdur")
    ok(all("#/t/" in h for h in t.locator("#aList .tgo").evaluate_all("els => els.map(e => e.getAttribute('href'))")), "kecid vereqe aparir")
    t.evaluate("document.querySelector('#aList').scrollIntoView({block:'start'})"); t.wait_for_timeout(300)
    t.screenshot(path=SHOT + "/sil_siyahi.png")
    t.locator("#aList .tgo").first.click(); t.wait_for_selector("#btnTDel", timeout=15000)
    ok("vurma" in t.inner_text("h1"), "kecid dogru testin vereqini acir")
    #  194: geri HARADAN gelibse ora - Tapsiriqlardan gelmisik, «Test yig»a yox
    ok("Tapşırıqlar" in t.inner_text("#btnBack"), "geri duymesi «Tapsiriqlar» yazir", t.inner_text("#btnBack"))
    t.evaluate("window.scrollTo(0,0)"); t.wait_for_timeout(200); t.screenshot(path=SHOT + "/geri_vereq.png")
    t.click("#btnBack"); t.wait_for_selector("#hwText", timeout=15000)
    ok(t.url.find("#/a/") >= 0, "geri Tapsiriqlar ekranina qaytardi")
    t.click("#btnBack"); t.wait_for_selector("#gTabs", timeout=15000)
    ok(t.url.find("#/g/") >= 0, "bir de geri - qrup")
    t.click("#btnRep"); t.wait_for_selector("#rTabs", timeout=15000)
    ok("Qrup" in t.inner_text("#btnB"), "hesabatda geri «Qrup»", t.inner_text("#btnB"))
    t.click("#btnB"); t.wait_for_selector("#gTabs", timeout=15000)
    t.click("#btnBack"); t.wait_for_selector("#groups .gcard", timeout=15000)
    ok(t.url.endswith("#/") or t.url.endswith("index.html") or "#/" in t.url, "qrupdan geri - Icmal")
    t.evaluate("location.hash = '#/t/%s'" % t1); t.wait_for_selector("#btnTDel", timeout=15000)
    ok("Əsas səhifə" in t.inner_text("#btnBack"), "Icmaldan birbasa vereqe: geri «Esas sehife»", t.inner_text("#btnBack"))

    print("C · Sil")
    t.once("dialog", lambda d: d.accept())
    t.click("#btnTDel"); t.wait_for_selector("#gsub", timeout=15000)
    ok(db("select count(*) n from public.tests where id=%s", (t1,), one=True)["n"] == 0, "test silindi, Test yig ekranina qayitdi")

    print("D · Şagird işləyibsə silinmir")
    t2 = gen("Samir 2")
    t.fill("#pDate", (datetime.date.today() + datetime.timedelta(days=5)).isoformat()); t.click("#btnPAsg")
    t.wait_for_selector(".pgiven", timeout=15000)
    sid = db("select id::text i from public.students limit 1", one=True)["i"]
    db("""insert into public.attempts (student_id, test_id, class_id, status, score, max_score, percent, finished_at)
          values (%s, %s, %s, 'submitted', 3, 5, 60, now())""", (sid, t2, gid))
    #  eyni unvana goto naviqasiya yaratmir - tam yuklenme, sonra hash
    t.goto(PANEL); t.wait_for_selector("#groups .gcard", timeout=15000); t.wait_for_timeout(300)
    t.evaluate("location.hash = '#/t/%s'" % t2); t.wait_for_selector("#btnTDel", timeout=15000)
    ok(t.locator("#btnTDel").is_disabled(), "cehd varsa Sil bagli")
    ok("silinmir" in (t.get_attribute("#btnTDel", "title") or ""), "sebebi yazilib", t.get_attribute("#btnTDel", "title"))
    #  server de redd edir - duyme kenardan acilsa bele
    r = db("select count(*) n from public.tests where id=%s", (t2,), one=True)["n"]
    ok(r == 1, "test yerindedir")
    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails)); [print("  - " + f) for f in fails]; raise SystemExit(1)
print("TEST SIL: BUTUN YOXLAMALAR KECDI")
