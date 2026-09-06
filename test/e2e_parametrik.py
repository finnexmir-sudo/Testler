#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Parametrik (sablon) suallar - ucdan-uca (db/132, yol xeritesi 22.a).

Muellim redaktorda {a} + {b} sablonu yazir, "Numune goster" reqemlerle
render edir, yadda saxlayir -> siyahida "sablon" nisani.  Sagird testi
acanda reqemler gorur, dogru cavabi ID ile verir, bal alir; ikinci cehdde
BASQA reqemler.  Muellimin vereqinde sablon nisani ve reqemler."""
import re, time
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
delete from public.mistakes; delete from public.feedback; delete from public.question_reports; delete from public.parent_sessions;
delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers; delete from public.attempts; delete from public.assignments;
delete from public.student_sessions; delete from public.students; delete from public.classes;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.question_options o using public.questions q where o.question_id = q.id and q.owner_type = 'educator';
delete from public.questions where owner_type = 'educator'; delete from public.subscriptions;
delete from public.account_members; delete from public.accounts; delete from public.user_roles;
delete from public.profiles; delete from auth.users;""")

EMAIL = "sablon%d@t.az" % int(time.time())

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

    print("A · Hazırlıq: müəllim, qrup, şagird")
    pg.goto(PANEL); pg.wait_for_selector("#btnAuth", timeout=15000)
    pg.click("#btnSwap")
    pg.fill("#fname", "Şablon Müəllim"); pg.fill("#email", EMAIL)
    pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=15000)
    pg.select_option("#atype", "tutor"); pg.fill("#aname", "Şablon hesabı"); pg.click("#btnSetup")
    pg.wait_for_selector("#btnGroup", timeout=15000)
    pg.fill("#gname", "3-cü sinif"); pg.select_option("#glevel", "3"); pg.click("#btnGroup")
    pg.wait_for_selector("#groups .item", timeout=15000)
    pg.click("#groups .item"); pg.wait_for_selector("#gTabs", timeout=15000)
    try: pg.wait_for_selector("#sname", state="visible", timeout=3000)
    except Exception: pg.click("#btnStuOpen")
    pg.fill("#sname", "Ayan Bir"); pg.click("#btnStu"); pg.wait_for_selector(".stu", timeout=15000)
    GID  = db("select id::text i from public.classes limit 1", one=True)["i"]
    UID  = db("select id::text i from auth.users limit 1", one=True)["i"]
    CODE = db("select login_code c from public.students limit 1", one=True)["c"]

    print("B · Redaktor: şablon yazılır, nümunə render olunur, yadda saxlanır")
    pg.goto(PANEL + "#/q/new"); pg.reload(); pg.wait_for_selector("#qbody", timeout=15000)
    pg.fill("#qbody", "{a} + {b} neçə edər?")
    pg.locator(".obody").nth(0).fill("{a+b}")
    pg.locator(".obody").nth(1).fill("{a+b+10}")
    ok(pg.locator("#qpar").count() == 1, "şablon sahəsi var")
    pg.locator("details.more summary", has_text="Şablon").click()
    pg.fill("#qpar", "a = 100..999, b = 100..999; şərt: a > b")
    pg.click("#qparTry"); pg.wait_for_selector("#qparOut .qsample", timeout=15000)
    smp = pg.inner_text("#qparOut .qsample")
    m = re.search(r"(\d+) \+ (\d+) neçə edər\?", smp)
    ok(bool(m), "numune reqemlerle render olunur", smp[:60])
    if m:
        a, b = int(m.group(1)), int(m.group(2))
        ok(100 <= b < a <= 999, "numune araliqda ve sertle", (a, b))
        ok(str(a + b) in smp, "numunede dogru cavab hesablanib", a + b)
    #  yararsiz sert -> server xetasi gorunur, yadda saxlanmir
    pg.fill("#qpar", "a = 100..999, b = 100..999; şərt: a > b and a < b")
    pg.click("#qparTry"); pg.wait_for_selector("#qparOut .err", timeout=15000)
    ok("uyğun qiymət" in pg.inner_text("#qparOut"), "sertsiz sablon xeta verir", pg.inner_text("#qparOut")[:60])
    pg.fill("#qpar", "a = 100..999, b = 100..999; şərt: a > b")
    pg.click("#qSave"); pg.wait_for_selector("#btnNewQ", timeout=15000)
    Q = db("select id::text i, params from public.questions where owner_type='educator'", one=True)
    ok(Q and Q["params"] and Q["params"]["vars"]["a"] == [100, 999] and Q["params"].get("cond") == "a > b",
       "params bazada", Q and Q["params"])
    ok("şablon" in pg.inner_text("body").lower(), "siyahida 'sablon' nisani")
    #  redakteye acanda deyisenler geri oxunur
    pg.locator(".qrow").first.click(); pg.wait_for_selector("#qpar", timeout=15000)
    ok(pg.input_value("#qpar") == "a = 100..999, b = 100..999; şərt: a > b", "deyisenler redaktorda geri oxunur", pg.input_value("#qpar"))

    print("C · Şagird: rəqəmlər görür, düz variantla bal alır")
    db("""insert into public.tests (id, owner_type, owner_id, program_id, subject_id, level_id, title, status, shuffle_questions, shuffle_options, max_attempts)
          select 'a1b20000-0000-0000-0000-0000000000e1', 'educator', %s, (select id from public.programs order by id limit 1),
                 (select id from public.subjects where slug='riyaziyyat'), (select id from public.levels where code='3' order by sort limit 1),
                 'Şablon test', 'published', false, true, 2""", (UID,))
    db("insert into public.test_questions (test_id, question_id, ord) values ('a1b20000-0000-0000-0000-0000000000e1', %s, 1)", (Q["i"],))
    db("insert into public.assignments (class_id, test_id, assigned_by, max_attempts) values (%s, 'a1b20000-0000-0000-0000-0000000000e1', %s, 2)", (GID, UID))
    sp = page(ctx, 390, 844)
    sp.goto(STUDENT); sp.wait_for_selector("#btnIn", timeout=15000)
    sp.fill("#code", CODE); sp.click("#btnIn"); sp.wait_for_selector(".test", timeout=15000)
    sp.locator(".test.asg").first.click(); sp.wait_for_selector(".opt", timeout=15000)
    body = sp.inner_text(".q .body")
    m = re.search(r"^(\d+) \+ (\d+) neçə edər\?$", body.strip())
    ok(bool(m), "sagird reqemli sual gorur", body)
    P = db("select params from public.attempts order by started_at desc limit 1", one=True)["params"]
    a, b = int(P[Q["i"]]["a"]), int(P[Q["i"]]["b"])
    ok(m and int(m.group(1)) == a and int(m.group(2)) == b, "ekran bazadaki qiymetlerle eynidir", (a, b))
    opts = sp.locator(".opt").all_inner_texts()
    #  variantin metni herf nisani ile gelir ("A\n1661") - son reqem goturulur
    ok(sorted(int(re.findall(r"\d+", x)[-1]) for x in opts) == sorted([a + b, a + b + 10]), "variantlar hesablanib", opts)
    ok(not re.search(r"[{}]", body + " ".join(opts)), "moterize qalmayib")
    #  davam: sehifeni yenile - eyni reqemler
    sp.reload(); sp.wait_for_selector(".test", timeout=15000)
    sp.locator(".test.asg").first.click(); sp.wait_for_selector(".opt", timeout=15000)
    ok(sp.inner_text(".q .body").strip() == body.strip(), "yenilenende eyni reqemler qalir")
    OK_ID = db("select id::text i from public.question_options where question_id=%s and is_correct", (Q["i"],), one=True)["i"]
    ok(sp.locator("[data-o='%s']" % OK_ID).inner_text().strip().endswith(str(a + b)), "dogru variantin metni a+b-dir")
    sp.locator("[data-o='%s']" % OK_ID).click(); sp.wait_for_timeout(120)
    sp.once("dialog", lambda d: d.accept()); sp.click("#btnFinish")
    sp.wait_for_selector(".ring", timeout=15000)
    R = db("select aa.is_correct c, aa.question_body qb, a.percent p from public.attempt_answers aa join public.attempts a on a.id=aa.attempt_id order by a.started_at desc limit 1", one=True)
    ok(R["c"] is True and float(R["p"]) == 100, "dogru variant ID ile bal", (R["c"], R["p"]))
    ok(R["qb"] == "%d + %d neçə edər?" % (a, b), "question_body render olunmus", R["qb"])
    rt = sp.inner_text("body")
    ok(("%d + %d" % (a, b)) in rt and "{" not in rt, "netice ekraninda reqemli metn")

    print("D · İkinci cəhd: başqa rəqəmlər")
    sp.click("#btnHome"); sp.wait_for_selector(".test", timeout=15000)
    sp.locator(".test.asg").first.click(); sp.wait_for_selector(".opt", timeout=15000)
    body2 = sp.inner_text(".q .body")
    ok(body2.strip() != body.strip() and re.search(r"^\d+ \+ \d+ neçə edər\?$", body2.strip()), "ikinci cehdde basqa reqemler", body2)

    print("E · Müəllimin vərəqi: şablon nişanı və rəqəmlər")
    pg.goto(PANEL + "#/t/a1b20000-0000-0000-0000-0000000000e1"); pg.reload(); pg.wait_for_selector(".pq", timeout=15000)
    pt = pg.inner_text(".pq")
    ok("şablon" in pt and re.search(r"\d+ \+ \d+ neçə edər\?", pt) is not None, "vereqde nisan ve reqemler", pt[:80])

    br.close()

print()
if fails:
    print("XETA:", len(fails)); [print("  -", f) for f in fails]; raise SystemExit(1)
print("hamisi kecdi")
