#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""17.09 Baslangic: 1) ilk test 2) qrup + adlar 3) testi gonder - masaustu + telefon"""
import os, time, psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"; BASE = "http://127.0.0.1:8010/"; PANEL = BASE + "muellim/index.html"
OUT = "/tmp/claude-0/v2"; os.makedirs(OUT, exist_ok=True)
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
def db(q, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(q)
        if cur.description: return cur.fetchone() if one else cur.fetchall()
HIDE = "#mailBar{display:none!important}"
with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    for tag, vp, dpr in (("d", {"width": 1280, "height": 800}, 1), ("m", {"width": 390, "height": 844}, 2)):
        em = "onb%s%d@test.az" % (tag, int(time.time()))
        p = br.new_context(viewport=vp, device_scale_factor=dpr).new_page()
        p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
        p.goto(PANEL); p.wait_for_selector("#email", timeout=30000)
        p.click("#btnSwap"); p.wait_for_selector("#fname", timeout=8000)
        p.fill("#fname", "Aysel Məmmədova"); p.fill("#email", em); p.fill("#pass", "parol123"); p.click("#btnAuth")
        p.wait_for_selector("#btnSetup", timeout=30000)
        p.fill("#aname", "Aysel müəllim — riyaziyyat"); p.click("#btnSetup")
        p.wait_for_selector("#onbGen", timeout=30000); p.add_style_tag(content=HIDE); p.wait_for_timeout(700)
        p.evaluate("document.getElementById('onb').scrollIntoView({block:'start'})"); p.evaluate("window.scrollBy(0,-70)"); p.wait_for_timeout(300)
        p.screenshot(path="%s/onb2_%s_1.png" % (OUT, tag)); print(tag, "1")
        #  test yaradilmis kimi - 2-ci addim
        uid = db("select id::text i from auth.users where email = '%s'" % em, one=True)["i"]
        db("""insert into public.tests (owner_type, owner_id, program_id, subject_id, level_id, slug, title, status)
              select 'educator', '%s', program_id, subject_id, level_id, 'onb-%s', 'Kəsrlər — 10 sual', 'published'
                from public.tests where owner_type = 'platform' limit 1""" % (uid, tag))
        p.reload(); p.wait_for_selector("#onb #onbNames", timeout=30000); p.add_style_tag(content=HIDE); p.wait_for_timeout(700)
        p.evaluate("document.getElementById('onb').scrollIntoView({block:'start'})"); p.evaluate("window.scrollBy(0,-70)"); p.wait_for_timeout(300)
        p.fill("#gname", "7-ci sinif"); p.fill("#onbNames", "Aysel Məmmədova\nMurad Əliyev\nLeyla Hüseynova")
        p.screenshot(path="%s/onb2_%s_2.png" % (OUT, tag)); print(tag, "2")
        p.click("#btnGroup"); p.wait_for_selector("#onbAsg", timeout=30000); p.add_style_tag(content=HIDE); p.wait_for_timeout(700)
        p.evaluate("document.getElementById('onb').scrollIntoView({block:'start'})"); p.evaluate("window.scrollBy(0,-70)"); p.wait_for_timeout(300)
        p.screenshot(path="%s/onb2_%s_3.png" % (OUT, tag)); print(tag, "3")
        n = db("select count(*) n from public.students s join public.accounts a on a.id = s.account_id where a.owner_id = '%s'" % uid, one=True)["n"]
        print(tag, "sagird:", n)
        p.context.close()
    br.close()
print("OK")
