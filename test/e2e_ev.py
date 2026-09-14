#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Metnle ev tapsirigi (db/191): muellim yazir -> sagird gorur, «etdim» -> valideyn gorur.

Uc tetbiq, bir axin.  Sekiller: /tmp/claude-0/ev/*.png (istifadeci baxir).
"""
import os, time, datetime
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
BASE = "http://127.0.0.1:8010/"
PANEL, STUDENT, PARENT = BASE + "muellim/index.html", BASE + "sagird/index.html", BASE + "valideyn/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
SHOT = "/tmp/claude-0/ev"; os.makedirs(SHOT, exist_ok=True)
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key",
  STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
BLOCK = "**://*.supabase.co/**"
fails = []
def ok(c, label, extra=""):
    print(("  OK   " if c else "  FAIL ") + label + (("  " + str(extra)) if extra else ""), flush=True)
    if not c: fails.append(label)
def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description: return cur.fetchone() if one else cur.fetchall()

db("""delete from public.homework_done; delete from public.homework;
delete from public.question_reports; delete from public.parent_sessions;
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
    pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    return pg

with sync_playwright() as p:
    br = p.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(permissions=["clipboard-read", "clipboard-write"])

    print("A · Müəllim yazır")
    t = page(ctx, 430, 1000)
    t.goto(PANEL); t.wait_for_selector("#btnAuth", timeout=15000)
    t.click("#btnSwap"); t.fill("#fname", "Ev Müəllim"); t.fill("#email", "ev%d@t.az" % int(time.time()))
    t.fill("#pass", "parol1234"); t.click("#btnAuth"); t.wait_for_selector("#btnSetup", timeout=15000)
    t.select_option("#atype", "tutor"); t.fill("#aname", "Ev hesabı"); t.click("#btnSetup")
    t.wait_for_selector("#btnGroup", timeout=15000)
    t.fill("#gname", "3-cü sinif"); t.select_option("#glevel", "3"); t.click("#btnGroup")
    t.wait_for_selector("#groups .gcard", timeout=15000); t.click("#groups .gcard")
    t.wait_for_selector("#gTabs", timeout=15000)
    for nm in ("Aysu Məmmədova", "Kənan Əliyev"):
        try: t.wait_for_selector("#sname", state="visible", timeout=3000)
        except Exception: t.click("#btnStuOpen")
        t.fill("#sname", nm); t.click("#btnStu"); t.wait_for_timeout(600)
    t.wait_for_selector(".stu .l3 .code", timeout=15000)
    gid = db("select id::text i from public.classes limit 1", one=True)["i"]
    aysu = db("select id::text i, login_code c, parent_code p from public.students where full_name='Aysu Məmmədova'", one=True)
    kenan = db("select login_code c from public.students where full_name='Kənan Əliyev'", one=True)

    t.click("#btnAsgs"); t.wait_for_selector("#hwText", timeout=15000)
    ok(True, "tapsiriqlar ekraninda «Ev tapsirigi - metnle» bolmesi var")
    ok("Hələ tapşırıq yazılmayıb" in t.inner_text("#hwList"), "bos halda izah var")
    t.click("#btnHwAdd"); t.wait_for_timeout(400)
    ok("mətnini yazın" in t.inner_text("#hwErr"), "bos metn - anlasilan xeta", t.inner_text("#hwErr")[:40])
    t.fill("#hwText", "12-ci paraqrafı oxu, çalışma 3–5-i dəftərdə həll et")
    t.fill("#hwDue", (datetime.date.today() + datetime.timedelta(days=3)).isoformat())
    t.click("#btnHwAdd"); t.wait_for_selector("#hwList .hwrow", timeout=15000)
    ok("Yazıldı" in t.inner_text("#hwErr"), "yazildi mesaji")
    row = t.inner_text("#hwList .hwrow")
    ok("12-ci paraqrafı" in row and "bütün qrup" in row and "0 / 2 etdi" in row,
       "qrup tapsirigi siyahida: metn, kime, nece nefer etdi", row.replace("\n", " ")[:80])
    ok(t.input_value("#hwText") == "", "forma temizlenir")
    t.select_option("#hwWho", aysu["i"]); t.fill("#hwText", "Vurma cədvəlini təkrarla")
    t.click("#btnHwAdd"); t.wait_for_function("document.querySelectorAll('#hwList .hwrow').length === 2", timeout=15000)
    rows = t.locator("#hwList .hwrow").all_inner_texts()
    ok(any("yalnız Aysu" in r and "0 / 1 etdi" in r for r in rows), "ferdi tapsiriq: yalniz Aysu, 0/1")
    t.evaluate("document.getElementById('hwForm').scrollIntoView({block:'start'})"); t.wait_for_timeout(300)
    t.screenshot(path=SHOT + "/m_tapsiriq.png")

    print("B · Şagird görür, «etdim» deyir")
    s = page(ctx, 390, 844)
    s.goto(STUDENT); s.wait_for_selector("#btnIn", timeout=15000)
    s.fill("#code", aysu["c"]); s.click("#btnIn"); s.wait_for_selector(".hwr", timeout=15000)
    ok(s.locator(".hwr").count() == 2, "Aysu 2 tapsiriq gorur (qrup + ferdi)", s.locator(".hwr").count())
    txt = s.inner_text(".hwbox")
    ok("12-ci paraqrafı" in txt and "Vurma cədvəlini" in txt and "yalnız sənə" in txt, "metnler ve «yalniz sene» nisani")
    ok("son tarix" in txt, "son tarix gorunur")
    #  Tapsiriqlar basligi altinda, testlerin USTUNDE
    pos = s.evaluate("() => { const h=[...document.querySelectorAll('h2')].find(e=>e.textContent.trim()==='Tapşırıqlar'); const b=document.querySelector('.hwbox'); return h && b && h.compareDocumentPosition(b) & 4; }")
    ok(bool(pos), "ev tapsirigi «Tapsiriqlar» basligindan sonra gelir")
    s.screenshot(path=SHOT + "/s_tapsiriq.png")
    s.locator("[data-hw]").first.click()
    #  edilen setir qatlanmis «Edilib» altina dusur - DOM-da var, gorunmur
    s.wait_for_selector(".hwr.done", state="attached", timeout=15000)
    ok(s.locator(".hwr.done").count() == 1, "«etdim» - sətir edilib kimi isarelenir")
    ok("Edilib" in s.inner_text(".hwbox"), "edilenler «Edilib» altina yigilir")
    ok(not s.locator(".hwr.done").first.is_visible(), "edilen setir qatlanib - siyahi temiz qalir")
    s.locator(".hwdone summary").click(); s.wait_for_timeout(300)
    ok(s.locator(".hwr.done").first.is_visible() and "Geri al" in s.inner_text(".hwr.done"),
       "acilanda «Geri al» var")
    n = db("select count(*) n from public.homework_done", one=True)["n"]
    ok(n == 1, "serverde yazildi", n)
    s.screenshot(path=SHOT + "/s_etdim.png")
    #  Kenan yalniz qrup tapsirigini gorur - AYRI kontekst (eyni brauzerde
    #  Aysunun sessiyasi qalir, giris ekrani cixmir)
    ctx2 = br.new_context()
    k = page(ctx2, 390, 844)
    k.goto(STUDENT); k.wait_for_selector("#btnIn", timeout=15000)
    k.fill("#code", kenan["c"]); k.click("#btnIn"); k.wait_for_selector(".hwr", timeout=15000)
    ok(k.locator(".hwr").count() == 1 and "Vurma" not in k.inner_text(".hwbox"), "Kenan ferdi tapsirigi GORMUR")

    print("C · Valideyn görür")
    ctx3 = br.new_context()
    v = page(ctx3, 390, 844)
    v.goto(PARENT); v.wait_for_selector("#code", timeout=15000)
    v.fill("#code", aysu["p"]); v.click("#btnIn"); v.wait_for_selector(".who", timeout=15000)
    v.wait_for_selector(".row.hwr", timeout=15000)
    vt = v.inner_text("body")
    ok(v.locator(".row.hwr").count() == 1, "valideyn edilmeyen 1 tapsirigi gorur", v.locator(".row.hwr").count())
    ok("müəllimin tapşırığı" in vt, "«muellimin tapsirigi» nisani")
    v.evaluate("document.querySelector('.row.hwr').scrollIntoView({block:'center'})"); v.wait_for_timeout(300)
    v.screenshot(path=SHOT + "/v_tapsiriq.png")

    print("D · Müəllim: kim etdi, silmək")
    t.reload(); t.wait_for_selector("#hwList .hwrow", timeout=15000)
    rows = t.locator("#hwList .hwrow").all_inner_texts()
    ok(any("1 / 2 etdi" in r and "Aysu" in r for r in rows) or any("1 / 1 etdi" in r for r in rows),
       "muellim siyahisinda «etdi» sayi ve ad", " | ".join(r.replace("\n", " ")[:60] for r in rows))
    t.once("dialog", lambda d: d.accept())
    t.locator("[data-hwdel]").last.click()
    t.wait_for_function("document.querySelectorAll('#hwList .hwrow').length === 1", timeout=15000)
    ok(db("select count(*) n from public.homework", one=True)["n"] == 1, "silindi")
    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails)); [print("  - " + f) for f in fails]; raise SystemExit(1)
print("EV TAPSIRIGI: BUTUN YOXLAMALAR KECDI")
