#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Qrupu OLMAYAN muellim test veraqinda: dalan idi, indi qrup buradaca yaranir."""
import os, time, psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
PANEL = "http://127.0.0.1:8010/muellim/index.html"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
OUT = "/tmp/claude-0/yer/" + os.environ.get("TAG", "veraq"); os.makedirs(OUT, exist_ok=True)
def q(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            r = cur.fetchall(); return (r[0] if r else None) if one else r
with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    p = br.new_context(viewport={"width": 360, "height": 800}, device_scale_factor=2).new_page()
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    p.goto(PANEL); p.wait_for_selector("#email", timeout=30000)
    mail = "vrq%d@t.az" % int(time.time() * 1000)
    p.click("#btnSwap"); p.fill("#fname", "Atilla müəllim"); p.fill("#email", mail)
    p.fill("#pass", "parol1234"); p.click("#btnAuth")
    p.wait_for_selector("#btnSetup", timeout=30000)
    p.fill("#aname", "Atilla müəllim"); p.click("#btnSetup")
    p.wait_for_selector("#btnGroup", timeout=30000)
    #  QRUP YARATMIRIQ - adminde gorunen hal: test var, qrup yoxdur
    r = q("select a.id acc, a.owner_id own from public.accounts a"
          " join auth.users u on u.id=a.owner_id where u.email=%s", (mail,), one=True)
    src = q("select id, subject_id, level_id, program_id from public.tests"
            " where owner_type='platform' and title='Vurma cədvəli — 1'", one=True)
    tid = q("insert into public.tests (owner_type,owner_id,program_id,subject_id,level_id,"
            "title,status,max_attempts,created_at,updated_at)"
            " values ('educator',%s,%s,%s,%s,'Vurma cədvəli — mənim testim','published',1,now(),now())"
            " returning id", (r["own"], src["program_id"], src["subject_id"], src["level_id"]), one=True)["id"]
    q("insert into public.test_questions (test_id, question_id, ord)"
      " select %s, question_id, ord from public.test_questions where test_id=%s", (tid, src["id"]))
    p.goto(PANEL + "#/t/" + str(tid)); p.reload()
    p.wait_for_selector("#pAsgH", timeout=20000); p.wait_for_timeout(1200)
    print("duyme «Qrup yarat və ver»:", p.locator("#btnGoAsg").count(),
          "| forma:", p.locator("#btnNewG").count(),
          "| sinif secimi:", p.locator("#pNewL option").count())
    h = p.evaluate("document.body.scrollHeight")
    print("veraq %d px" % h)
    p.screenshot(path=OUT + "/veraq.png", full_page=True)
    #  isledek: qrup yaransin, test ona getsin
    p.fill("#pNewG", "Cümə qrupu")
    p.click("#btnNewG")
    p.wait_for_selector("#gTabs", timeout=20000); p.wait_for_timeout(1500)
    print("qrup ekranina dusduk:", "/g/" in p.url)
    asg = q("select c.name, t.title from public.assignments a"
            " join public.classes c on c.id=a.class_id"
            " join public.tests t on t.id=a.test_id where c.account_id=%s", (r["acc"],))
    print("tapsiriq bazada:", asg)
    p.screenshot(path=OUT + "/sonra_qrup.png", full_page=True)
    br.close()
print("OK")
