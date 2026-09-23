#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""TEST SEHIFESI: duymeler dord zolaqda, iyerarxiya var

23.09 (istifadeci): «butonlar yan yana qatisiq nedir bele?»
Bir setirde 9 element, bes gorunusde idi.  Indi:
  1. ESAS      - tek yasil duyme
  2. CAP       - duyme + IKI CHECKBOX (cavab acari, yigcam)
  3. SAKIT     - hamisi ag: hemkar, yeniden yig, adi deyis, vaxt
  4. TEHLUKELI - «Sil» ayrica, sag kenarda

Yoxlanilir:
  1. dord zolaq var ve duymeler oz zolagindadir
  2. «Cavab acari ile» ARTIQ DUYME DEYIL - checkbox (btnPrnK yoxdur)
  3. «Sil» esas zolaqda deyil, oz zolagindadir
  4. vaxt cipi secilmeyibse NEYTRAL (set sinfi yoxdur)
  5. butun duymeler hele de yerindedir - hec biri itmeyib
"""
import os, sys, time, psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
PANEL = "http://127.0.0.1:8010/muellim/index.html"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
OUT = "/tmp/claude-0/testduyme"; os.makedirs(OUT, exist_ok=True)
SEHV = []
def yox(sert, ad):
    print(("  OK   " if sert else "  SEHV ") + ad)
    if not sert: SEHV.append(ad)
def q(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args) if args else cur.execute(sql)
        if cur.description:
            r = cur.fetchall(); return (r[0] if r else None) if one else r
def temizle():
    q("""delete from public.test_questions where test_id in (
             select id from public.tests where owner_type='educator');
         delete from public.tests where owner_type='educator';
         delete from public.subscriptions; delete from public.students;
         delete from public.classes; delete from public.account_members;
         delete from public.accounts; delete from public.user_roles;
         delete from auth.users;""")
temizle()
T = int(time.time() * 1000)
with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 1280, "height": 1000})
    p = ctx.new_page()
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    mail = "td%d@t.az" % T
    p.goto(PANEL); p.wait_for_selector("#email", timeout=30000)
    p.click("#btnSwap"); p.fill("#fname", "Samir müəllim"); p.fill("#email", mail)
    p.fill("#pass", "parol1234"); p.click("#btnAuth")
    p.wait_for_selector("#btnSetup", timeout=30000)
    p.fill("#aname", "Samir test"); p.click("#btnSetup")
    p.wait_for_selector("#adminMsg", state="attached", timeout=30000)
    acc = q("select a.id acc, a.owner_id own from public.accounts a join auth.users u"
            " on u.id=a.owner_id where u.email=%s", (mail,), one=True)
    q("insert into public.subscriptions (account_id, plan_id, status, started_at, current_period_end)"
      " select %s, pl.id, 'active', now()-interval '5 days', now()+interval '25 days'"
      " from public.plans pl where pl.slug='repetitor-60'", (acc["acc"],))
    src = q("select * from public.tests where owner_type='platform' limit 1", one=True)
    tid = q("insert into public.tests (owner_type,owner_id,program_id,subject_id,"
            "level_id,title,status,gen_rule,shuffle_questions,shuffle_options)"
            " values ('educator',%s,%s,%s,%s,'Sınaq testi','published',"
            "'{\"pool\":\"all\"}'::jsonb,true,true) returning id",
            (acc["own"], src["program_id"], src["subject_id"], src["level_id"]), one=True)["id"]
    q("insert into public.test_questions (test_id, question_id, ord)"
      " select %s, question_id, ord from public.test_questions where test_id=%s", (tid, src["id"]))

    p.goto(PANEL + "#/t/" + str(tid)); p.reload()
    p.wait_for_selector(".tacts", timeout=30000); p.wait_for_timeout(900)

    print("\n1) dord zolaq")
    for z in ("tact1", "tact2", "tact3", "tact4"):
        yox(p.locator("." + z).count() == 1, "%s zolagi var" % z)

    print("\n2) hansi duyme hansi zolaqda")
    yox(p.locator(".tact1 #btnGoAsg").count() == 1, "esas duyme 1-ci zolaqda")
    yox(p.locator(".tact2 #btnPrn").count() == 1, "«Çap / PDF» 2-ci zolaqda")
    yox(p.locator(".tact2 #prnK").count() == 1, "«cavab açarı ilə» CHECKBOX-dur")
    yox(p.locator(".tact2 #prnC").count() == 1, "«yığcam» checkbox 2-ci zolaqda")
    yox(p.locator("#btnPrnK").count() == 0, "kohne sari DUYME artiq yoxdur")
    for b in ("btnHemkar", "btnTRen"):
        yox(p.locator(".tact3 #" + b).count() == 1, "%s 3-cu zolaqda" % b)
    yox(p.locator(".tact3 .plim").count() == 1, "vaxt cipi 3-cu zolaqda")
    yox(p.locator(".tact4 #btnTDel").count() == 1, "«Sil» AYRICA zolaqdadir")
    yox(p.locator(".tact1 #btnTDel, .tact2 #btnTDel, .tact3 #btnTDel").count() == 0,
        "«Sil» basqa zolaqda YOXDUR")

    print("\n3) vaxt cipi secilmeyib - neytral")
    yox(p.locator(".tact3 .plim.set").count() == 0,
        "vaxt secilmeyib, «set» sinfi yoxdur (ag qalir)")

    print("\n4) capin ayarlari isleyir")
    p.check("#prnK")
    yox(p.locator("#prnK").is_checked(), "«cavab açarı ilə» qeyd olunur")
    p.uncheck("#prnK")
    yox(not p.locator("#prnK").is_checked(), "geri goturulur")
    p.screenshot(path=OUT + "/tacts.png", full_page=True)
    br.close()
temizle()
print("\n" + ("BUTUN YOXLAMALAR KECDI" if not SEHV
              else "SEHV (%d): %s" % (len(SEHV), " | ".join(SEHV))))
sys.exit(1 if SEHV else 0)
