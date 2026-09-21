#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Qrup sehifesi telefonda - neticesi olan real qrup kimi."""
import os, time, psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
PANEL = "http://127.0.0.1:8010/muellim/index.html"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
OUT = "/tmp/claude-0/yer/" + os.environ.get("TAG", "qrup"); os.makedirs(OUT, exist_ok=True)
def q(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            r = cur.fetchall(); return (r[0] if r else None) if one else r
ADLAR = ["Hüseynov Mirhüseyn", "Hüseynov Mirkənan", "Hüseynova Lalə", "Samir"]
with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    p = br.new_context(viewport={"width": 360, "height": 800}, device_scale_factor=2).new_page()
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    p.goto(PANEL); p.wait_for_selector("#email", timeout=30000)
    mail = "qrup%d@t.az" % int(time.time() * 1000)
    p.click("#btnSwap"); p.fill("#fname", "Leyla müəllim"); p.fill("#email", mail)
    p.fill("#pass", "parol1234"); p.click("#btnAuth")
    p.wait_for_selector("#btnSetup", timeout=30000)
    p.fill("#aname", "Leyla müəllim — riyaziyyat"); p.click("#btnSetup")
    p.wait_for_selector("#btnGroup", timeout=30000)
    acc = q("select a.id from public.accounts a join auth.users u on u.id=a.owner_id"
            " where u.email=%s", (mail,), one=True)["id"]
    q("insert into public.subscriptions (account_id, plan_id, status, started_at, current_period_end)"
      " select %s, p.id, 'active', now()-interval '10 days', now()+interval '60 days'"
      " from public.plans p where p.slug='repetitor-60'", (acc,))
    p.fill("#gname", "Ev qrup")
    try: p.select_option("#glevel", label="3-cü sinif")
    except Exception: pass
    p.click("#btnGroup"); p.wait_for_selector("#groups .gcard", timeout=20000)
    p.click("#groups .gcard"); p.wait_for_selector("#gTabs", timeout=20000)
    gid = p.evaluate("location.hash.split('/')[2]")
    try: p.wait_for_selector("#sname", state="visible", timeout=3000)
    except Exception: p.click("#btnStuOpen")
    for nm in ADLAR:
        p.fill("#sname", nm); p.click("#btnStu"); p.wait_for_timeout(700)
    p.wait_for_selector(".stu", timeout=15000)
    #  netice: iki test, her sagird ucun ayri bacariq + zeif movzu
    stu = [r["id"] for r in q("select id from public.students where class_id=%s order by full_name", (gid,))]
    tst = [r["id"] for r in q("select id from public.tests where owner_type='platform'"
                              " and title in ('Vurma cədvəli — 1','Azərbaycan dili — 1') order by title")]
    for t in tst:
        q("insert into public.assignments (class_id,test_id,assigned_by,opens_at,closes_at,max_attempts,created_at)"
          " select %s,%s,c.teacher_id,now()-interval '6 days',now()+interval '3 days',1,now()-interval '6 days'"
          " from public.classes c where c.id=%s", (gid, t, gid))
    tops = [r["id"] for r in q("select distinct tq.topic_id id from public.test_questions x"
                               " join public.questions tq on tq.id=x.question_id"
                               " where x.test_id=%s and tq.topic_id is not null", (tst[0],))]
    bac = [0.25, 0.45, 0.93, 0.8]
    for i, sid in enumerate(stu):
        for r in range(3):          # uc dovr - movzuda 5+ cavab yigilsin
            for t in tst:
                zeif = tops[:1] if i < 2 else []
                q("select app.demo_attempt(%s,%s,%s,%s,%s::uuid[],"
                  "now() - make_interval(days => %s))",
                  (sid, t, gid, bac[i], zeif, 12 - i - r * 3))
    p.goto(PANEL + "#/g/" + gid); p.reload()
    p.wait_for_selector("#gTabs", timeout=20000)
    p.wait_for_timeout(2500)
    h = p.evaluate("document.body.scrollHeight")
    print("qrup (netice ile) %d px = %.1f ekran" % (h, h / 800.0))
    print("  movzu setri:", p.locator(".tmap .tm-row").count(),
          "| siqnal setri:", p.locator("#alerts .al").count())
    if p.locator(".tmap .tm-row").count():
        print("  ilk setir:", p.locator(".tmap .tm-row").first.inner_text().replace("\n", " "))
    ad = p.locator(".stu .l1 b").first
    if p.locator("#alerts .al").count():
        print("  siqnallar:", " || ".join(p.locator("#alerts .al").all_inner_texts())[:220].replace("\n"," "))
    print("  ad eni:", round(ad.evaluate("e=>e.getBoundingClientRect().width")),
          "| kesilib?", ad.evaluate("e=>e.scrollWidth>e.clientWidth+1"))
    p.screenshot(path=OUT + "/qrup.png", full_page=True)
    #  sagird hesabati - «Sagirde bax»
    p.locator(".stu .l1 b").first.click()
    p.wait_for_selector("#sTabs", timeout=20000); p.wait_for_timeout(2000)
    hs = p.evaluate("document.body.scrollHeight")
    print("sagird hesabati %d px = %.1f ekran" % (hs, hs / 800.0))
    print("  xulase bas:", p.locator("#tab-x").inner_text()[:150].replace("\n", " | "))
    p.screenshot(path=OUT + "/sagird.png", full_page=True)
    br.close()
print("OK")
