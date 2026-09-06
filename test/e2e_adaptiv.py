#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Adaptiv movzu mesqi - ucdan-uca (db/133, yol xeritesi 22.b).

Sagird ev ekraninda "Movzu mesqi" kartini gorur, movzu secir, suallar
bir-bir gelir; duz cavab bal artirir, sehv azaldir; 100 -> menimsenildi.
Muellim hesabatinda ve valideyn ekraninda sayğac."""
import re, time
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

PANEL   = "http://127.0.0.1:8010/muellim/index.html"
STUDENT = "http://127.0.0.1:8010/sagird/index.html"
PARENT  = "http://127.0.0.1:8010/valideyn/index.html"
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
delete from public.practice; delete from public.mistakes; delete from public.feedback; delete from public.question_reports; delete from public.parent_sessions;
delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers; delete from public.attempts; delete from public.assignments;
delete from public.student_sessions; delete from public.students; delete from public.classes;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator'; delete from public.subscriptions;
delete from public.account_members; delete from public.accounts; delete from public.user_roles;
delete from public.profiles; delete from auth.users;""")

EMAIL = "adaptiv%d@t.az" % int(time.time())

def page(ctx, w, h):
    pg = ctx.new_page(); pg.set_viewport_size({"width": w, "height": h})
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=TEST_CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))
    return pg

def answer(sp, sid, want_ok):
    """Ekrandaki suala DB-den duz/sehv cavab verir; geri: (score, feedback text)."""
    cur = db("select cur->>'q' q from public.practice where student_id=%s and cur is not null", (sid,), one=True)
    q = cur["q"]
    kind = db("select kind from public.questions where id=%s", (q,), one=True)["kind"]
    good = [r["i"] for r in db("select id::text i from public.question_options where question_id=%s and is_correct order by ord", (q,))]
    bad  = [r["i"] for r in db("select id::text i from public.question_options where question_id=%s and not is_correct order by ord", (q,))]
    if kind == "text":
        body = db("select body from public.question_options where question_id=%s and is_correct limit 1", (q,), one=True)["body"]
        sp.fill("#pans", body if want_ok else body + "x"); sp.click("#btnPAns")
    elif kind == "multi":
        for i in (good if want_ok else bad[:1]): sp.locator("[data-o='%s']" % i).click()
        sp.click("#btnPAns")
    else:
        sp.locator("[data-o='%s']" % (good[0] if want_ok else bad[0])).click()
    sp.wait_for_selector("#pFb .ok, #pFb .warn", timeout=15000)
    fb = sp.inner_text("#pFb")
    sc = int(re.search(r"(\d+) / 100", sp.inner_text(".adprog")).group(1))
    return sc, fb

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context()
    pg = page(ctx, 430, 1000)

    print("A · Hazırlıq: müəllim (riyaziyyat), 3-cü sinif qrupu, şagird")
    pg.goto(PANEL); pg.wait_for_selector("#btnAuth", timeout=15000)
    pg.click("#btnSwap")
    pg.fill("#fname", "Adaptiv Müəllim"); pg.fill("#email", EMAIL)
    pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=15000)
    pg.select_option("#atype", "tutor"); pg.fill("#aname", "Adaptiv hesabı"); pg.click("#btnSetup")
    pg.wait_for_selector("#btnGroup", timeout=15000)
    pg.fill("#gname", "3-cü sinif"); pg.select_option("#glevel", "3"); pg.click("#btnGroup")
    pg.wait_for_selector("#groups .item", timeout=15000)
    pg.click("#groups .item"); pg.wait_for_selector("#gTabs", timeout=15000)
    try: pg.wait_for_selector("#sname", state="visible", timeout=3000)
    except Exception: pg.click("#btnStuOpen")
    pg.fill("#sname", "Ayan Bir"); pg.click("#btnStu"); pg.wait_for_selector(".stu", timeout=15000)
    GID  = db("select id::text i from public.classes limit 1", one=True)["i"]
    SID  = db("select id::text i from public.students limit 1", one=True)["i"]
    CODE = db("select login_code c from public.students limit 1", one=True)["c"]
    db("update public.accounts set subjects = '{riyaziyyat}'")

    print("B · Şagird: ev ekranında «Mövzu məşqi», mövzu siyahısı")
    sp = page(ctx, 390, 844)
    sp.goto(STUDENT); sp.wait_for_selector("#btnIn", timeout=15000)
    sp.fill("#code", CODE); sp.click("#btnIn"); sp.wait_for_selector("#adBox .arow", timeout=15000)
    top = sp.locator("#adBox > div > .arow").count()
    ok(1 <= top <= 4, "ustde 1-4 movzu", top)
    sp.locator("#adBox details summary").click()
    allr = sp.locator("#adBox .arow").count()
    ok(allr >= 6, "butun movzular acilir", allr)
    ok("Riyaziyyat" in sp.inner_text("#adBox") and "Azərbaycan dili" not in sp.inner_text("#adBox"), "yalniz hesabin fenni")
    TOPIC = sp.locator("#adBox .arow").first.get_attribute("data-t")
    TNAME = sp.locator("#adBox .arow").first.locator("b").inner_text()

    print("C · Məşq: düz +bal, səhv -bal, çətinlik dəyişir")
    sp.locator("#adBox .arow").first.click(); sp.wait_for_selector(".adprog", timeout=15000)
    ok(TNAME in sp.inner_text(".adhead"), "movzu adi basliqda", TNAME)
    ok("0 / 100" in sp.inner_text(".adprog") and "asan" in sp.inner_text("body"), "basda 0 bal, asan seviyye")
    ok(sp.locator(".q .body").count() == 1 and (sp.locator(".opt").count() >= 2 or sp.locator("#pans").count() == 1), "sual gelir")
    s1, fb = answer(sp, SID, True)
    ok(s1 > 0 and "+" in fb and "Düzdür" in fb, "duz cavab bal artirir", (s1, fb[:40]))
    ok("is_correct" not in sp.content(), "duz variant sizmir")
    sp.click("#btnPNext"); sp.wait_for_selector(".adprog", timeout=15000)
    s2, fb = answer(sp, SID, False)
    ok(s2 < s1 and "Səhvdir" in fb, "sehv cavab bal azaldir", (s1, s2))
    ok(db("select count(*) n from public.mistakes where student_id=%s and status='open'", (SID,), one=True)["n"] == 1, "sehv deftere dusdu")
    sp.click("#btnPHome"); sp.wait_for_selector("#adBox .arow", timeout=15000)
    ok(str(s2) in sp.locator("#adBox .arow").first.inner_text() and "2 cavab" in sp.locator("#adBox .arow").first.inner_text(),
       "ev ekraninda bal ve cavab sayi", sp.locator("#adBox .arow").first.inner_text().replace("\n", " "))

    print("D · 100-ə qədər: mənimsənildi")
    sp.locator("#adBox .arow").first.click(); sp.wait_for_selector(".adprog", timeout=15000)
    got = False; seen = set()
    for i in range(14):
        cur = db("select cur->>'q' q from public.practice where student_id=%s", (SID,), one=True)["q"]
        ok(cur not in seen, "sual tekrar gelmir") if cur in seen else None
        seen.add(cur)
        sc, fb = answer(sp, SID, True)
        if "mənimsənilib" in fb:
            got = True; break
        sp.click("#btnPNext"); sp.wait_for_selector(".adprog", timeout=15000)
    ok(got and sc == 100, "movzu menimsenildi", (got, sc, i + 1))
    ok("çətin" in sp.inner_text("body"), "sonda cetin seviyye")
    ok(db("select mastered_at is not null m from public.practice where student_id=%s and topic_id=%s", (SID, TOPIC), one=True)["m"], "bazada mastered_at")
    ok(sp.locator("#btnPHome").inner_text().strip() == "Mövzulara qayıt", "menimsenilende duyme")
    sp.click("#btnPHome"); sp.wait_for_selector("#adBox", timeout=15000)
    ok("1 mövzu mənimsənilib" in sp.inner_text("#adBox"), "ev ekraninda menimsenilib sayı")

    print("E · Müəllim hesabatı və valideyn")
    pg.goto(PANEL + "#/s/" + SID + "/" + GID); pg.reload(); pg.wait_for_selector("#sTabs", timeout=15000)
    pg.click("#sTabs [data-v='s']"); pg.wait_for_selector(".mkbox", timeout=8000)
    rt = pg.inner_text("body")
    ok("Mövzu məşqi" in rt and "mənimsənilib" in rt and TNAME in rt, "hesabatda movzu mesqi karti")
    PC = "VADPT001"
    db("update public.students set parent_code=%s where id=%s", (PC, SID))
    vp = page(ctx, 390, 844)
    vp.goto(PARENT); vp.wait_for_selector("#code", timeout=15000)
    vp.fill("#code", PC); vp.click("#btnIn"); vp.wait_for_selector(".who", timeout=15000)
    vt = vp.inner_text("body")
    ok("Mövzu məşqi" in vt and "1 mövzu mənimsənilib" in vt, "valideyn ekraninda sayğac", vt[:160].replace("\n", " "))

    br.close()

print()
if fails:
    print("XETA:", len(fails)); [print("  -", f) for f in fails]; raise SystemExit(1)
print("hamisi kecdi")
