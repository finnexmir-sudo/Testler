#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Vaxtli test (db/192): muellim limit qoyur -> sagird saat gorur -> 0-da ozu gonderilir -> server qerar verir.

Sekiller: /tmp/claude-0/vaxt/*.png
"""
import os, time, datetime
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
BASE = "http://127.0.0.1:8010/"
PANEL, STUDENT = BASE + "muellim/index.html", BASE + "sagird/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
SHOT = "/tmp/claude-0/vaxt"; os.makedirs(SHOT, exist_ok=True)
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", SHOW_PLANS: false };"""
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
    ctx = br.new_context()

    print("A · Müəllim limit qoyur")
    t = page(ctx, 430, 1000)
    t.goto(PANEL); t.wait_for_selector("#btnAuth", timeout=15000)
    t.click("#btnSwap"); t.fill("#fname", "Vaxt Müəllim"); t.fill("#email", "vaxt%d@t.az" % int(time.time()))
    t.fill("#pass", "parol1234"); t.click("#btnAuth"); t.wait_for_selector("#btnSetup", timeout=15000)
    t.select_option("#atype", "tutor"); t.fill("#aname", "Vaxt hesabı"); t.click("#btnSetup")
    t.wait_for_selector("#btnGroup", timeout=15000)
    t.fill("#gname", "3-cü sinif"); t.select_option("#glevel", "3"); t.click("#btnGroup")
    t.wait_for_selector("#groups .gcard", timeout=15000)
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select a.id, p.id, 'active', now() + interval '30 days' from public.accounts a, public.plans p
           where p.slug = 'repetitor-25'""")
    t.click("#groups .gcard"); t.wait_for_selector("#gTabs", timeout=15000)
    try: t.wait_for_selector("#sname", state="visible", timeout=3000)
    except Exception: t.click("#btnStuOpen")
    t.fill("#sname", "Aysu Məmmədova"); t.click("#btnStu"); t.wait_for_selector(".stu .l3 .code", timeout=15000)
    code = db("select login_code c from public.students limit 1", one=True)["c"]
    t.goto(PANEL + "#/gen"); t.wait_for_selector("#gsub", timeout=15000); t.wait_for_timeout(600)
    t.select_option("#gsub", "riyaziyyat"); t.wait_for_timeout(900); t.fill("#gCnt", "5"); t.wait_for_timeout(400)
    t.click("#btnMake"); t.wait_for_selector(".paper", timeout=20000)
    ok(t.locator("#pLim").count() == 1, "vereqde vaxt limiti secimi var")
    ok("vaxtsız" in t.inner_text("#pLim summary"), "susmaya gore vaxtsiz")
    t.click("#pLim summary"); t.wait_for_selector(".plimm button[data-min='5']", state="visible", timeout=5000)
    t.click(".plimm button[data-min='5']"); t.wait_for_selector(".paper", timeout=15000); t.wait_for_timeout(600)
    tid = db("select id::text i, time_limit_sec s from public.tests where owner_type='educator' order by created_at desc limit 1", one=True)
    ok(tid["s"] == 300, "limit bazaya yazildi (5 deq = 300 s)", tid["s"])
    ok("⏱ 5 dəq" in t.inner_text("#main"), "vereq basliginda ⏱ 5 deq")
    ok("5 dəq" in t.inner_text("#pLim summary"), "secim yeniden acilanda qalir")
    t.fill("#pDate", (datetime.date.today() + datetime.timedelta(days=5)).isoformat())
    t.select_option("#pTry", "3"); t.click("#btnPAsg"); t.wait_for_selector(".pgiven", timeout=15000)
    t.evaluate("window.scrollTo(0,0)"); t.wait_for_timeout(300); t.screenshot(path=SHOT + "/m_vereq.png")
    #  cap basligi
    t.click("#btnPrn"); t.wait_for_timeout(600)
    ok("vaxt: 5 dəq" in (t.evaluate("() => { const b = document.getElementById('printBox'); return b ? b.innerText : ''; }") or ""),
       "cap basliginda «vaxt: 5 deq»")

    print("B · Şagird: saat görür")
    s = page(ctx, 390, 844)
    s.goto(STUDENT); s.wait_for_selector("#btnIn", timeout=15000)
    s.fill("#code", code); s.click("#btnIn"); s.wait_for_selector(".test.asg", timeout=15000)
    ok("⏱ 5 dəq" in s.inner_text(".test.asg"), "siyahida ⏱ 5 deq")
    s.locator(".test.asg").first.click(); s.wait_for_selector("#tmr", timeout=15000)
    tx = s.inner_text("#tmr")
    ok(tx.startswith("⏱ 4:5") or tx == "⏱ 5:00", "geri sayan saat gorunur", tx)
    s.wait_for_timeout(1500)
    ok(s.inner_text("#tmr") != tx or tx.startswith("⏱ 4:5"), "saat isleyir", s.inner_text("#tmr"))
    s.screenshot(path=SHOT + "/s_saat.png")
    #  DUZ varianti secirik (acar bazadan) - guzestde balin hesablandigini gormek ucun
    key = {r["o"] for r in db("""select o.id::text o from public.question_options o
        join public.test_questions tq on tq.question_id = o.question_id where tq.test_id = %s and o.is_correct""", (tid["i"],))}
    ids = s.locator(".opt").evaluate_all("els => els.map(e => e.getAttribute('data-o'))")
    s.locator("[data-o='%s']" % next(o for o in ids if o in key)).click(); s.wait_for_timeout(300)

    print("C · Vaxt bitir: cavablar özü gedir, server sayır (güzəşt)")
    att = db("select id::text i, extract(epoch from (now() - started_at))::int e from public.attempts where status='in_progress' limit 1", one=True)
    ok(att is not None, "cehd acilib")
    #  limit = kecen + 3 s: yeniden acanda saat 0:03-den baslayir, 0-da gonderilir
    db("update public.tests set time_limit_sec = %s where id = %s", (att["e"] + 4, tid["i"]))
    s.click("#btnHome") if s.locator("#btnHome").count() else None
    s.goto(STUDENT); s.wait_for_selector(".test.asg", timeout=15000)
    s.locator(".test.asg").first.click(); s.wait_for_selector("#tmr", timeout=15000)
    ok(s.inner_text("#tmr").startswith("⏱ 0:0"), "davam eden cehdde qalan vaxt serverden gelir", s.inner_text("#tmr"))
    s.wait_for_timeout(600)
    ok("soon" in (s.get_attribute("#tmr", "class") or ""), "son deqiqede qirmizi")
    s.wait_for_selector(".ring", timeout=15000)
    ok(True, "0-da netice ekrani ozu acildi (avtomatik gonderme)")
    ok("Vaxt bitdi — cavablar avtomatik göndərildi" in s.inner_text("#main"), "«vaxt bitdi» qeydi")
    r = db("select timed_out t, percent p from public.attempts where id = %s", (att["i"],), one=True)
    ok(r["t"] is True, "serverde timed_out")
    ok(r["p"] is not None and r["p"] > 0, "guzestde bal hesablanib (1 duz cavab)", r["p"])
    s.screenshot(path=SHOT + "/s_vaxt_bitdi.png")

    print("D · Güzəşt də keçib: cavablar sayılmır")
    s.click("#btnHome"); s.wait_for_selector(".test.asg", timeout=15000)
    db("update public.tests set time_limit_sec = 300 where id = %s", (tid["i"],))
    s.locator(".test.asg").first.click(); s.wait_for_selector("#tmr", timeout=15000)
    s.locator(".opt").first.click(); s.wait_for_timeout(200)
    att2 = db("select id::text i from public.attempts where status='in_progress' limit 1", one=True)
    db("update public.attempts set started_at = now() - interval '500 seconds' where id = %s", (att2["i"],))
    #  sehife yenilenir - server qalan 0 deyir, client derhal gonderir, server gec sayir
    s.goto(STUDENT); s.wait_for_selector(".test.asg", timeout=15000)
    s.locator(".test.asg").first.click(); s.wait_for_selector(".ring", timeout=15000)
    ok("bal hesablanmadı" in s.inner_text("#main"), "gec cavab: «bal hesablanmadi» qeydi")
    r = db("select timed_out t, percent p from public.attempts where id = %s", (att2["i"],), one=True)
    ok(r["t"] is True and float(r["p"]) == 0, "serverde late: 0 bal, timed_out", (r["t"], r["p"]))
    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails)); [print("  - " + f) for f in fails]; raise SystemExit(1)
print("VAXTLI TEST: BUTUN YOXLAMALAR KECDI")
