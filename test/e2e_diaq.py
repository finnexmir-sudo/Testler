#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Diaqnostik test - ucdan-uca (db/118_diaqnostika.sql).

Muellim: abunesiz -> kilid; abune ile "Diaqnostik test ver" -> gozleyir;
sagird: nisan, yazir (1-ci fesil sehv), oz xeritesi; muellim: xerite
1 zeif, "bundan basla", duzelis testi duymesi; ikinci diaqnostika -> ferq."""
import datetime, time, os
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

PANEL   = "http://127.0.0.1:8010/muellim/index.html"
STUDENT = "http://127.0.0.1:8010/sagird/index.html"
CHROME  = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN     = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
TEST_CFG = """window.CFG = {
  SUPABASE_URL: "http://127.0.0.1:54321",
  SUPABASE_ANON_KEY: "test-anon-key",
  STUDENT_URL: "https://finnexmir-sudo.github.io/Testler/sagird/",
  PARENT_URL:  "https://finnexmir-sudo.github.io/Testler/valideyn/",
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
delete from public.question_reports; delete from public.parent_sessions;
delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers; delete from public.attempts; delete from public.assignments;
delete from public.student_sessions; delete from public.students; delete from public.classes;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator'; delete from public.subscriptions;
delete from public.account_members; delete from public.accounts; delete from public.user_roles;
delete from public.profiles; delete from auth.users;""")

ACC = "Diaq hesabi %d" % int(time.time())

def page(ctx, w, h):
    pg = ctx.new_page(); pg.set_viewport_size({"width": w, "height": h})
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=TEST_CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))
    return pg

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context()
    pg = page(ctx, 430, 1000)

    print("A · Hazırlıq: müəllim, qrup (3-cü sinif), şagird")
    pg.goto(PANEL); pg.wait_for_selector("#btnAuth", timeout=15000)
    pg.click("#btnSwap")
    pg.fill("#fname", "Diaq Müəllim"); pg.fill("#email", "diaq%d@t.az" % int(time.time()))
    pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=15000)
    pg.select_option("#atype", "tutor"); pg.fill("#aname", ACC); pg.click("#btnSetup")
    pg.wait_for_selector("#btnGroup", timeout=15000)
    pg.fill("#gname", "3-cü sinif"); pg.select_option("#glevel", "3"); pg.click("#btnGroup")
    pg.wait_for_selector("#groups .item", timeout=15000)
    pg.click("#groups .item"); pg.wait_for_selector("#btnStu", timeout=15000)
    pg.fill("#sname", "Kənan Əliyev"); pg.click("#btnStu")
    pg.wait_for_selector(".stu", timeout=15000)
    gid  = db("select id::text i from public.classes limit 1", one=True)["i"]
    sid  = db("select id::text i from public.students limit 1", one=True)["i"]
    code = db("select login_code c from public.students limit 1", one=True)["c"]
    ok(bool(gid and sid and code), "qrup ve sagird bazadadir")

    print("B · Abunəsiz: diaqnostika kilidlidir")
    pg.goto(PANEL + "#/s/" + sid + "/" + gid)
    pg.wait_for_selector("#diagBox .upsell, #diagBox #dgGo", timeout=15000)
    ok(pg.locator("#diagBox .upsell").count() == 1, "abunesiz: kilid karti")
    ok(pg.locator("#dgGo").count() == 0, "abunesiz: 'Diaqnostik test ver' duymesi YOXDUR")
    ok("abunə" in pg.inner_text("#diagBox").lower(), "sebeb yazilir")

    print("C · Abunə ilə: fənn seçimi, yaratmaq, gözlənilir")
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select a.id, p.id, 'active', now() + interval '30 days'
            from public.accounts a, public.plans p where a.name = %s and p.slug = 'repetitor-25'""", (ACC,))
    pg.reload(); pg.wait_for_selector("#dgGo", timeout=15000)
    opts = pg.locator("#dgSub option").all_inner_texts()
    ok(any("Riyaziyyat" in o and "12 mövzu" in o and "36 sual" in o for o in opts),
       "fenn secimi: Riyaziyyat - 12 movzu - 36 sual", opts[:2])
    pg.select_option("#dgSub", "riyaziyyat")
    pg.click("#dgGo"); pg.wait_for_selector("#dgMsg .ok", timeout=20000)
    ok("36 sual" in pg.inner_text("#dgMsg") and "12 mövzu" in pg.inner_text("#dgMsg"),
       "yaradildi: 36 sual, 12 movzu", pg.inner_text("#dgMsg")[:60])
    pg.wait_for_selector("#diagBox:has-text('Gözlənilir')", timeout=15000)
    ok(pg.locator("#dgGo").count() == 0, "gozleyende ikinci duyme yoxdur (dublikat qorunmasi)")
    t1 = db("select id::text i from public.tests where is_diagnostic order by created_at limit 1", one=True)["i"]
    row = db("select student_id::text s, max_attempts m from public.assignments where test_id = %s", (t1,), one=True)
    ok(row and row["s"] == sid and row["m"] == 1, "teyinat yalniz bu sagirde, 1 cehd")
    ok(db("select count(*) n from public.test_questions where test_id=%s", (t1,), one=True)["n"] == 36, "36 sual bazada")

    print("D · Şagird: nişan, yazır (1-ci fəsil səhv), öz xəritəsi")
    # option id -> sual, sual -> fesil siresi, duzgun variantlar
    rows = db("""select o.id::text oid, q.id::text qid, o.is_correct c,
                        dense_rank() over (order by tp.sort, tp.name) rk, tp.name tname
                   from public.test_questions tq
                   join public.questions q on q.id = tq.question_id
                   join public.topics tp on tp.id = q.topic_id
                   join public.question_options o on o.question_id = q.id
                  where tq.test_id = %s""", (t1,))
    O2Q = {r["oid"]: r["qid"] for r in rows}
    QRK = {r["qid"]: r["rk"] for r in rows}
    CORR = {r["oid"] for r in rows if r["c"]}
    T1NAME = next(r["tname"] for r in rows if r["rk"] == 1)
    sp = page(ctx, 390, 844)
    sp.goto(STUDENT); sp.wait_for_selector("#btnIn", timeout=15000)
    sp.fill("#code", code); sp.click("#btnIn"); sp.wait_for_selector(".test", timeout=15000)
    #  basliq onsuz da "Diaqnostika ·" ile baslayir - ayrica cip tekrardir (UX yoxlamasi)
    ok(sp.locator(".test .solo.diag").count() == 0, "basliqda 'Diaqnostika' olanda ikinci nisan yoxdur")
    ok("Diaqnostika" in sp.locator(".test.asg").first.inner_text(), "basliq 'Diaqnostika ·' ile baslayir")
    sp.locator(".test.asg").first.click(); sp.wait_for_selector(".opt", timeout=15000)
    ok("is_correct" not in sp.content(), "sual ekraninda is_correct yoxdur")
    n = 0
    while True:
        ids = sp.locator(".opt").evaluate_all("els => els.map(e => e.getAttribute('data-o'))")
        qid = O2Q.get(ids[0])
        if QRK.get(qid) == 1:
            want = next(o for o in ids if o not in CORR)      # 1-ci fesil: sehv
        else:
            want = next(o for o in ids if o in CORR)          # qalani: duz
        sp.locator("[data-o='%s']" % want).click(); sp.wait_for_timeout(80); n += 1
        if sp.locator("#btnNext").count() and sp.locator("#btnNext").is_visible():
            sp.click("#btnNext"); sp.wait_for_timeout(100)
        else:
            sp.once("dialog", lambda d: d.accept()); sp.click("#btnFinish"); break
    sp.wait_for_selector(".ring", timeout=15000)
    ok(n == 36, "36 sual cavablandi", n)
    t = sp.inner_text("#main")
    ok("XƏRİTƏN" in t or "xəritən" in t, "sagirdde 'Movzu xeriten' bolmesi var (I telesi: lower() yox)")
    ok(T1NAME in t and "Bundan başla" in t, "sagirdde 'Bundan basla' = 1-ci fesil", T1NAME)
    ok(sp.locator(".myr").count() == 12, "xeritede 12 fesil", sp.locator(".myr").count())
    ok(sp.locator("details.more").count() == 1 and sp.locator("details.more .myr").count() == 11,
       "11 yaxsi fesil yigilmis bolmededir, 1 zeif acıqdadir")
    ok(sp.locator(".myr .best.bl").count() == 1 and sp.locator(".myr .best.bh").count() == 11,
       "1 zeif, 11 yaxsi")
    if os.environ.get("SHOT"): sp.screenshot(path=os.environ["SHOT"] + "/diaq_sagird.png", full_page=True)

    print("E · Müəllim: xəritə, «bundan başla», düzəliş testi düyməsi")
    pg.reload(); pg.wait_for_selector("#dgMap", timeout=15000)
    ok(pg.locator("#dgMap .dgrow").count() == 12, "muellim xeritesinde 12 fesil")
    ok(pg.locator("#dgMap .dgrow.st-weak").count() == 1 and pg.locator("#dgMap .dgrow.st-ok").count() == 11,
       "1 zeif, 11 yaxsi (muellim)")
    box = pg.inner_text("#diagBox")
    ok("1 zəif" in box and "11 yaxşı" in box, "xulase cipleri", box[:80].replace("\n", " "))
    ok("Bundan başla" in box and T1NAME in box, "'Bundan basla' 1-ci fesil")
    ok(pg.locator("#dgRem").count() == 0, "diaqnostika kartinda ayrica duyme yoxdur (bir duyme: #btnRem)")
    ok(pg.locator("#btnRem").count() == 1 and "(1)" in pg.inner_text("#btnRem"), "'Zeif movzulardan test yig (1)'")
    ok(pg.locator("#dgMap details").count() == 1 and not pg.locator("#dgMap details").first.get_attribute("open"),
       "yaxsi movzular yigilmis bolmededir")
    ok(pg.locator("#dgGo").count() == 1 and "Yenidən diaqnostika" in box, "yenidən diaqnostika formasi var")
    ok(pg.locator("#dgMap .dprev").count() == 0, "ilk diaqnostikada muqayise oxu yoxdur")
    if os.environ.get("SHOT"):
        pg.evaluate("document.getElementById('diagBox').scrollIntoView()"); pg.wait_for_timeout(200)
        pg.locator("#diagBox").screenshot(path=os.environ["SHOT"] + "/diaq_muellim.png")
    pg.click("#btnRem"); pg.wait_for_timeout(1200)
    ok("#/gen" in pg.url, "duzelis duymesi generatora aparir", pg.url.split("#")[-1])
    ok(T1NAME in pg.inner_text("#main"), "generatorda zeif fesil secilib")

    print("F · İkinci diaqnostika: hamısı düz → fərq «1 zəif → 0»")
    pg.goto(PANEL + "#/s/" + sid + "/" + gid); pg.wait_for_selector("#dgGo", timeout=15000)
    pg.click("#dgGo"); pg.wait_for_selector("#diagBox:has-text('Gözlənilir')", timeout=20000)
    t2 = db("select id::text i from public.tests where is_diagnostic order by created_at desc limit 1", one=True)["i"]
    ok(t2 != t1, "yeni test yarandi")
    rows2 = db("""select o.id::text oid from public.test_questions tq
                  join public.question_options o on o.question_id = tq.question_id
                 where tq.test_id = %s and o.is_correct""", (t2,))
    CORR2 = {r["oid"] for r in rows2}
    sp.click("#btnHome"); sp.wait_for_selector(".test", timeout=15000)
    sp.locator(".test.asg:not(.done)").first.click(); sp.wait_for_selector(".opt", timeout=15000)
    while True:
        ids = sp.locator(".opt").evaluate_all("els => els.map(e => e.getAttribute('data-o'))")
        sp.locator("[data-o='%s']" % next(o for o in ids if o in CORR2)).click(); sp.wait_for_timeout(80)
        if sp.locator("#btnNext").count() and sp.locator("#btnNext").is_visible():
            sp.click("#btnNext"); sp.wait_for_timeout(100)
        else:
            sp.once("dialog", lambda d: d.accept()); sp.click("#btnFinish"); break
    sp.wait_for_selector(".ring", timeout=15000)
    ok("100" in sp.inner_text(".ring .val"), "ikinci diaqnostika 100%")
    ok("Bütün mövzular yaxşıdır" in sp.inner_text("#main"), "sagirdde 'hamisi yaxsidir'")
    pg.reload(); pg.wait_for_selector("#dgMap", timeout=15000)
    box = pg.inner_text("#diagBox")
    ok("1 zəif → 0" in box, "ferq yazilir: 1 zeif -> 0", box[:120].replace("\n", " "))
    ok(pg.locator("#dgMap .dprev.up").count() == 1 and pg.locator("#dgMap .dprev.same").count() == 11,
       "muqayise oxlari: 1 yuxari, 11 eyni")
    #  #btnRem "Movzu uzre menimseme"ye baglidir (butun testler): 1-ci fesil
    #  tarixce uzre 3/6 = 50% - hele zeifdir, duyme qalir; diaqnostika karti ise
    #  SON xeriteni gosterir ("hamisi yaxsidir")
    ok(pg.locator("#btnRem").count() == 1 and "(1)" in pg.inner_text("#btnRem"),
       "duzelis duymesi tarixceye gore qalir (1-ci fesil 3/6)")
    ok(pg.locator("#dgMap .dgrow.st-weak").count() == 0, "son xeritede zeif fesil yoxdur")
    ok("Bütün mövzular yaxşıdır" in box, "muellimde 'hamisi yaxsidir'")
    if os.environ.get("SHOT"): pg.locator("#diagBox").screenshot(path=os.environ["SHOT"] + "/diaq_muellim2.png")

    print("G · Test vərəqi: diaqnostik testdə «Yenidən yığ» və «Qrupa təyin et» yoxdur")
    pg.goto(PANEL + "#/t/" + t1); pg.wait_for_selector("#btnPrn", timeout=15000)
    ok(pg.locator("#btnRegen").count() == 0, "«Yeniden yig» yoxdur")
    ok(pg.locator("#btnPAsg").count() == 0 and pg.locator("#pWho").count() == 0, "«Qrupa teyin et» formasi yoxdur")
    ok(pg.locator("#pDiag").count() == 1 and "Hər mövzudan 3 sual" in pg.inner_text("#pDiag"), "diaqnostika qeydi var")
    ok(pg.locator("#pDiag a[href^='#/s/']").count() == 1, "sagird ekranina kecid var")
    if os.environ.get("SHOT"): pg.screenshot(path=os.environ["SHOT"] + "/diaq_vereq.png")
    pg.locator("#pDiag a").click(); pg.wait_for_selector("#diagBox", timeout=15000)
    ok(("#/s/" + sid) in pg.url, "kecid sagird ekranina aparir")

    br.close()

if fails:
    print("UGURSUZ: %d" % len(fails))
    for f in fails: print("  - " + f)
    raise SystemExit(1)
print("DIAQNOSTIKA: BUTUN YOXLAMALAR KECDI")
