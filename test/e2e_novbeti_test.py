#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""«Növbəti test hazırdır» kartı — kimə gedir və təkrarlanırmı (25.09).

Istifadeci tapdi: sagirdin hesabatindan «Test tapsir» ile gelib karti
basdi - test BUTUN QRUPA getdi (0/4), ustelik IKI DEFE gonderilmisdi
ve sagird eyni testi siyahisinda iki defe gorurdu.

Yoxlanir:
  A  qrupdan gelende: kart «qrupun bütün şagirdləri» deyir, qrupa gedir
  B  sagirdden gelende: kart «yalnız <ad>» deyir
  C  sagirdden gelende tapsiriq YALNIZ o sagirde yazilir (bazada)
  D  eyni movzulardan aciq tapsiriq varsa: «artıq verilib» cixir,
     «Göndər» duymesi OLMUR - ikinci nusxe yigila bilmir
  E  tesdiq qutusu kime getdiyini ve artiq siyahida oldugunu yazir
"""
import sys, time
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

ROOT = "http://127.0.0.1:8010/"
PANEL = ROOT + "muellim/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
CFG = """window.CFG = {SUPABASE_URL:"http://127.0.0.1:54321",
  SUPABASE_ANON_KEY:"test-anon-key", STUDENT_URL:"http://127.0.0.1:8010/sagird/",
  SHOW_PLANS:false};"""

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
delete from public.attempt_answers;  delete from public.attempts;
delete from public.assignments;      delete from public.student_sessions;
delete from public.students;         delete from public.classes;
delete from public.test_questions tq using public.tests t
 where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.subscriptions;
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from auth.users;
""")

T = int(time.time())
MAIL = "nxt%d@t.az" % T

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 1280, "height": 1000})
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))

    print("A · Hazırlıq: 3 şagird, biri zəif cavablarla")
    pg.goto(PANEL); pg.wait_for_timeout(600)
    pg.click("#btnSwap")
    pg.fill("#fname", "Nxt Muellim"); pg.fill("#email", MAIL)
    pg.fill("#pass", "nxtparol123"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=20000)
    pg.select_option("#atype", "tutor"); pg.fill("#aname", "Nxt hesabi")
    pg.click("#btnSetup"); pg.wait_for_selector("#gForm", timeout=20000)

    uid = db("select id::text i from auth.users where email=%s", (MAIL,), one=True)["i"]
    acc = db("select id::text i from public.accounts where owner_id=%s::uuid", (uid,), one=True)["i"]
    #  «topics» YALNIZ odenislide qayidir - kart onsuz cizilmir
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select %s::uuid, p.id, 'active', now() + interval '30 days'
            from public.plans p where p.slug = 'repetitor-25'""", (acc,))
    cls = db("""insert into public.classes (account_id, teacher_id, kind, name, join_code, level_id)
                select %s::uuid, %s::uuid, 'tutor_group', 'Nxt qrup', 'NXTKOD01', l.id
                  from public.levels l where l.code='3'
                returning id::text i""", (acc, uid), one=True)["i"]
    SID = {}
    for ad, kod in (("Aysel Məmmədova", "NXTS0001"), ("Murad Əliyev", "NXTS0002"),
                    ("Leyla Hüseynova", "NXTS0003")):
        SID[ad] = db("""insert into public.students (account_id, class_id, created_by, full_name,
                                                     display_name, login_code)
                        values (%s::uuid, %s::uuid, %s::uuid, %s, %s, %s)
                        returning id::text i""",
                     (acc, cls, uid, ad, ad.split()[0], kod), one=True)["i"]

    #  Zeif movzu qurulur: hər şagird bir testi SEHV isleyir (ratio < 80,
    #  total >= 5).  Serverden kecmesi ucun cehd birbasa bazaya yazilir.
    tid = db("select id::text i from public.tests where slug='riy-3-vurma-1'", one=True)["i"]
    for ad in SID:
        att = db("""insert into public.attempts (student_id, test_id, class_id, status,
                                                 started_at, finished_at, score, max_score, percent)
                    values (%s::uuid, %s::uuid, %s::uuid, 'submitted', now(), now(), 1, 6, 17)
                    returning id::text i""", (SID[ad], tid, cls), one=True)["i"]
        db("""insert into public.attempt_answers (attempt_id, question_id, topic_id,
                                                  is_correct, points, question_body)
              select %s::uuid, q.id, q.topic_id, false, 0, q.body
                from public.questions q
                join public.test_questions tq on tq.question_id = q.id
               where tq.test_id = %s::uuid""", (att, tid))
    zeif = db("""select t.name from public.topics t
                  join public.attempt_answers aa on aa.topic_id = t.id
                 group by t.name limit 1""", one=True)["name"]
    print("   zəif mövzu: " + zeif)

    print("B · Qrupdan gələndə — «qrupun bütün şagirdləri»")
    pg.goto(PANEL + "#/a/" + cls); pg.wait_for_selector(".nxt2", timeout=25000)
    t = pg.inner_text(".nxt2")
    print("   kart: " + t.replace("\n", " ")[:120])
    ok("qrupun bütün şagirdləri" in t, "qrup kontekstinde «butun sagirdler» yazilir")
    ok(pg.locator("#btnNext2").count() == 1, "«Göndər» duymesi var")

    print("C · Şagirddən gələndə — «yalnız Aysel»")
    pg.goto(PANEL + "#/a/" + cls + "/" + SID["Aysel Məmmədova"])
    pg.wait_for_selector(".nxt2", timeout=25000)
    t2 = pg.inner_text(".nxt2")
    print("   kart: " + t2.replace("\n", " ")[:120])
    ok("yalnız Aysel Məmmədova" in t2, "sagird kontekstinde ADI yazilir")
    ok("qrupun bütün şagirdləri" not in t2, "«butun qrup» YAZILMIR")

    print("D · Göndərilir — yalnız o şagirdə yazılır")
    n0 = db("select count(*) n from public.assignments", one=True)["n"]
    pg.click("#btnNext2"); pg.wait_for_selector(".asgok", timeout=25000)
    rows = db("""select a.student_id::text s, t.title from public.assignments a
                  join public.tests t on t.id = a.test_id
                 where a.assigned_by = %s::uuid""", (uid,))
    ok(len(rows) == n0 + 1, "bir tapsiriq yarandi", len(rows))
    yeni = [r for r in rows if str(r["title"]).startswith("Təkrar")]
    ok(len(yeni) == 1, "«Təkrar — …» tapsirigi tekdir", len(yeni))
    ok(yeni and yeni[0]["s"] == SID["Aysel Məmmədova"],
       "tapsiriq YALNIZ hemin sagirde yazildi", yeni and yeni[0]["s"])

    print("E · Təsdiq mətni")
    fl = pg.inner_text(".asgok")
    print("   " + fl.replace("\n", " ")[:140])
    ok("yalnız Aysel Məmmədova" in fl, "tesdiqde kime getdiyi yazilir")
    ok("artıq" in fl and "siyahısındadır" in fl, "artiq siyahida oldugu yazilir")

    print("F · Təkrar göndərilmənin qarşısı")
    #  Gonderisden sonra ekran screenAssign() ile YENIDEN cizilib, amma
    #  unvan deyismeyib - eyni unvana goto() hec ne etmir (hashchange
    #  atesalmir).  Ona gore reload: muellimin sabah geri qayitmasi ile
    #  eyni haldir.
    pg.reload()
    pg.wait_for_selector(".nxt2", timeout=25000)
    t3 = pg.inner_text(".nxt2")
    print("   kart: " + t3.replace("\n", " ")[:140])
    ok(pg.locator(".nxtvar").count() == 1, "«artıq verilib» xeberdarligi cixdi")
    ok(pg.locator("#btnNext2").count() == 0, "«Göndər» duymesi YOXDUR - ikinci nusxe yigilmir")
    ok("artıq verilib" in t3 and "0/1" in t3, "ne qeder bitirdiyi yazilir", t3.replace("\n"," ")[-60:])
    n_son = db("""select count(*) n from public.assignments a join public.tests t on t.id=a.test_id
                   where t.title like 'Təkrar%%'""", one=True)["n"]
    ok(n_son == 1, "bazada hele de BIR «Təkrar» tapsirigi var", n_son)

    print("G · Qrup konteksti təsirlənmir")
    pg.goto(PANEL + "#/a/" + cls); pg.wait_for_selector(".nxt2", timeout=25000)
    t4 = pg.inner_text(".nxt2")
    ok("qrupun bütün şagirdləri" in t4, "qrupda yene «butun sagirdler»")
    ok(pg.locator("#btnNext2").count() == 1,
       "qrupa hele verilmeyib - «Göndər» durur (ferdi tapsiriq qrupu bloklamir)")
    pg.screenshot(path="/tmp/claude-0/nxt/kart_masaustu.png", full_page=True)

    print("H · Telefon")
    mctx = br.new_context(viewport={"width": 390, "height": 844})
    m = mctx.new_page()
    m.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=CFG))
    m.goto(PANEL); m.wait_for_timeout(700)
    m.fill("#email", MAIL); m.fill("#pass", "nxtparol123"); m.click("#btnAuth")
    m.wait_for_timeout(3000)
    m.goto(PANEL + "#/a/" + cls + "/" + SID["Aysel Məmmədova"])
    m.wait_for_selector(".nxt2", timeout=25000)
    ok(m.locator(".nxtvar").count() == 1, "telefonda da «artıq verilib» gorunur")
    ok(m.evaluate("() => document.documentElement.scrollWidth <= window.innerWidth + 1"),
       "telefonda yana surusme yoxdur")
    m.screenshot(path="/tmp/claude-0/nxt/kart_telefon.png", full_page=True)
    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails))
    for f in fails: print("  - " + f)
    sys.exit(1)
print("NOVBETI TEST KARTI: BUTUN YOXLAMALAR KECDI")
