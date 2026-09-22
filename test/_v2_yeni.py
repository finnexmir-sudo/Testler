#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Yeni gorunus (?yeni=1): bos hesab + dolu hesab - telefon."""
import os, time, psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
BASE = "http://127.0.0.1:8010/"; PANEL = BASE + "muellim/index.html"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
OUT = "/tmp/claude-0/yeni"; os.makedirs(OUT, exist_ok=True)
def q(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            r = cur.fetchall(); return (r[0] if r else None) if one else r
#  Paylasilan bazani ARDIMIZCA temiz qoyuruq - yoxsa e2e_panel kimi
#  skriptler «hesab artiq var» halina dusur (auth.users-i silmirler).
def temizle():
    q("""delete from public.subscriptions; delete from public.students;
           delete from public.classes; delete from public.account_members;
           delete from public.accounts; delete from public.user_roles;
           delete from auth.users;""")
temizle()
T = int(time.time() * 1000)
with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2)
    p = ctx.new_page()
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    mail = "yni%d@t.az" % T
    p.goto(PANEL + "?yeni=1"); p.wait_for_selector("#email", timeout=30000)
    p.click("#btnSwap"); p.fill("#fname", "Leyla müəllim"); p.fill("#email", mail)
    p.fill("#pass", "parol1234"); p.click("#btnAuth")
    p.wait_for_selector("#btnSetup", timeout=30000)
    p.fill("#aname", "Leyla müəllim — riyaziyyat"); p.click("#btnSetup")
    p.wait_for_selector("#yMenu .mrow", timeout=30000); p.wait_for_timeout(900)
    h = p.evaluate("document.body.scrollHeight")
    print("BOS hesab: %d px = %.1f ekran · %d setir" % (h, h / 844.0, p.locator("#yMenu .mrow").count()))
    print("   baslangic:", p.locator("#yBas").inner_text().replace("\n", " | ")[:70])
    p.screenshot(path=OUT + "/bos.png", full_page=True)

    #  ---- hesabi doldururuq
    acc = q("select a.id acc, a.owner_id own from public.accounts a join auth.users u"
            " on u.id=a.owner_id where u.email=%s", (mail,), one=True)
    q("insert into public.subscriptions (account_id, plan_id, status, started_at, current_period_end)"
      " select %s, pl.id, 'active', now()-interval '25 days', now()+interval '5 days'"
      " from public.plans pl where pl.slug='repetitor-60'", (acc["acc"],))
    for nm, kod in (("5-ci sinif", "K1"), ("Ev qrup", "K2")):
        q("insert into public.classes (account_id,teacher_id,kind,name,join_code,level_id)"
          " select %s,%s,'tutor_group',%s,%s,l.id from public.levels l where l.code='3'",
          (acc["acc"], acc["own"], nm, kod + str(T)[-6:]))
    cls = q("select id from public.classes where account_id=%s order by name", (acc["acc"],))
    adlar = ["Ayan Məmmədova", "Murad Həsənov", "Lalə Quliyeva", "Samir Əliyev", "Nihad Cəfərov"]
    for i, ad in enumerate(adlar):
        qisa = ad.split(" ")[0] + " " + ad.split(" ")[1][0] + "."
        q("insert into public.students (account_id,class_id,created_by,full_name,display_name,"
          "login_code,is_active,created_at)"
          " values (%s,%s,%s,%s,%s,%s,true, now()-interval '20 days')",
          (acc["acc"], cls[i % 2]["id"], acc["own"], ad, qisa, "SD%s%d" % (str(T)[-5:], i)))
    tst = [r["id"] for r in q("select id from public.tests where owner_type='platform'"
                              " and title in ('Vurma cədvəli — 1','Azərbaycan dili — 1') order by title")]
    stu = [r["id"] for r in q("select id, class_id from public.students where account_id=%s", (acc["acc"],))]
    for t in tst:
        for c in cls:
            q("insert into public.assignments (class_id,test_id,assigned_by,opens_at,closes_at,max_attempts,created_at)"
              " values (%s,%s,%s,now()-interval '6 days',now()+interval '3 days',1,now()-interval '6 days')",
              (c["id"], t, acc["own"]))
    bac = [0.35, 0.5, 0.9, 0.75, 0.6]
    tops = [r["id"] for r in q("select distinct tq.topic_id id from public.test_questions x"
                               " join public.questions tq on tq.id=x.question_id"
                               " where x.test_id=%s and tq.topic_id is not null", (tst[0],))]
    for i, s in enumerate(q("select id, class_id from public.students where account_id=%s order by full_name", (acc["acc"],))):
        for r in range(3):
            for t in tst:
                q("select app.demo_attempt(%s,%s,%s,%s,%s::uuid[], now() - make_interval(days => %s))",
                  (s["id"], t, s["class_id"], bac[i], tops[:1] if i < 2 else [], 11 - i - r * 3))
    p.goto(PANEL + "#/"); p.reload()
    p.wait_for_selector("#yMenu .mrow", timeout=30000); p.wait_for_timeout(1500)
    h = p.evaluate("document.body.scrollHeight")
    print("DOLU hesab: %d px = %.1f ekran" % (h, h / 844.0))
    print("   diqqet:", p.locator("#yDiq").inner_text().replace("\n", " | ")[:140])
    print("   menyu :", p.locator("#yMenu").inner_text().replace("\n", " | ")[:200])
    p.screenshot(path=OUT + "/dolu.png", full_page=True)
    #  ---- qrup menyusu
    gid = q("select id from public.classes where account_id=%s order by name", (acc["acc"],))[0]["id"]
    p.goto(PANEL + "#/g/" + str(gid)); p.reload()
    p.wait_for_selector("#gMenu .mrow", timeout=30000); p.wait_for_timeout(2000)
    h = p.evaluate("document.body.scrollHeight")
    print("QRUP menyusu: %d px = %.1f ekran" % (h, h / 844.0))
    print("   diqqet:", p.locator("#gDiq").inner_text().replace("\n", " | ")[:120])
    print("   menyu :", p.locator("#gMenu").inner_text().replace("\n", " | ")[:220])
    p.screenshot(path=OUT + "/qrup.png", full_page=True)
    #  ---- sagirdler bolmesi
    p.goto(PANEL + "#/g/" + str(gid) + "/s"); p.reload()
    p.wait_for_selector("#stu .mrow", timeout=30000); p.wait_for_timeout(900)
    h = p.evaluate("document.body.scrollHeight")
    print("SAGIRDLER: %d px · %d setir" % (h, p.locator("#stu .mrow").count()))
    p.screenshot(path=OUT + "/sagirdler.png", full_page=True)
    br.close()
temizle()
print("OK")
