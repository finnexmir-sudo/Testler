#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ONBAXIS: test sehifesinin duyme zolaqlari (masaustu + telefon).
   test/tek.sh _test_sekil.py   ->  /tmp/claude-0/testsehife/"""
import os, time, psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
PANEL = "http://127.0.0.1:8010/muellim/index.html"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
OUT = "/tmp/claude-0/testsehife"; os.makedirs(OUT, exist_ok=True)
def q(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args) if args else cur.execute(sql)
        if cur.description:
            r = cur.fetchall(); return (r[0] if r else None) if one else r
q("""delete from public.test_questions where test_id in (select id from public.tests where owner_type='educator');
     delete from public.tests where owner_type='educator';
     delete from public.subscriptions; delete from public.students;
     delete from public.classes; delete from public.account_members;
     delete from public.accounts; delete from public.user_roles;
     delete from auth.users;""")
T = int(time.time() * 1000)
with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    for ad, vp in (("masaustu", {"width": 1280, "height": 1000}),
                   ("telefon",  {"width": 390, "height": 844})):
        ctx = br.new_context(viewport=vp, device_scale_factor=2)
        p = ctx.new_page()
        p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
        mail = "ts%s%d@t.az" % (ad[:2], T)
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
        #  hazir platforma testini muellimin testi kimi kopyalayaq
        src = q("select * from public.tests where owner_type='platform' limit 1", one=True)
        tid = q("insert into public.tests (owner_type,owner_id,program_id,subject_id,"
                "level_id,title,status,gen_rule,shuffle_questions,shuffle_options)"
                " values ('educator',%s,%s,%s,%s,'Test · 23 sen','published',"
                "'{\"pool\":\"all\"}'::jsonb,true,true) returning id",
                (acc["own"], src["program_id"], src["subject_id"], src["level_id"]), one=True)["id"]
        q("insert into public.test_questions (test_id, question_id, ord)"
          " select %s, question_id, ord from public.test_questions where test_id=%s", (tid, src["id"]))
        p.goto(PANEL + "#/t/" + str(tid)); p.reload()
        p.wait_for_selector(".tacts", timeout=30000); p.wait_for_timeout(900)
        p.screenshot(path=OUT + "/" + ad + ".png", full_page=True)
        print(ad, "cekildi")
        ctx.close()
    br.close()
print("hazir")
