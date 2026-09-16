#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""v2 baslangic karti: teze hesab -> 1-ci addim, qrup -> 2-ci, sagird -> 3-cu.  -> /tmp/claude-0/v2/onb_*.png"""
import os, time, psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"; BASE = "http://127.0.0.1:8010/"; PANEL = BASE + "muellim/index.html"
OUT = "/tmp/claude-0/v2"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
def db(q):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur: cur.execute(q)
db("""delete from public.student_sessions; delete from public.students; delete from public.classes;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator'; delete from public.subscriptions;
delete from public.account_members; delete from public.accounts; delete from public.user_roles;
delete from public.profiles; delete from auth.users;""")
EMAIL = "onb%d@t.az" % int(time.time())
with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    def page(w, h, dpr):
        p = br.new_context(viewport={"width": w, "height": h}, device_scale_factor=dpr).new_page()
        p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG)); return p
    p = page(1280, 800, 1)
    p.goto(PANEL); p.wait_for_selector("#btnAuth", timeout=15000); p.click("#btnSwap")
    p.fill("#fname", "Sevinc Əliyeva"); p.fill("#email", EMAIL); p.fill("#pass", "parol1234"); p.click("#btnAuth")
    p.wait_for_selector("#btnSetup", timeout=15000); p.select_option("#atype", "tutor"); p.fill("#aname", "Sevinc müəllim"); p.click("#btnSetup")
    p.wait_for_selector("#btnGroup", timeout=15000); p.wait_for_timeout(900)
    p.screenshot(path=OUT + "/onb1_d.png", full_page=True); print("onb1_d")
    p.fill("#gname", "7-ci sinif"); p.select_option("#glevel", "7"); p.click("#btnGroup")
    p.wait_for_selector("#groups .gcard", timeout=15000); p.wait_for_selector("#onbStu", timeout=15000); p.wait_for_timeout(700)
    p.screenshot(path=OUT + "/onb2_d.png", full_page=True); print("onb2_d")
    p.click("#onbStu"); p.wait_for_selector("#gTabs", timeout=15000)
    p.wait_for_selector("#sname", state="visible", timeout=5000)
    for nm in ("Aysel Məmmədova", "Murad Əliyev"):
        p.fill("#sname", nm); p.click("#btnStu"); p.wait_for_timeout(900)
    p.evaluate("location.hash='#/'"); p.wait_for_selector("#onbGen", timeout=15000); p.wait_for_timeout(700)
    p.screenshot(path=OUT + "/onb3_d.png", full_page=True); print("onb3_d")
    p.context.close()
    m = page(390, 844, 2)
    m.goto(PANEL); m.wait_for_selector("#btnAuth", timeout=15000)
    m.fill("#email", EMAIL); m.fill("#pass", "parol1234"); m.click("#btnAuth")
    m.wait_for_selector("#onbGen", timeout=20000); m.wait_for_timeout(800)
    m.screenshot(path=OUT + "/onb3_m.png", full_page=True); print("onb3_m")
    m.context.close(); br.close()
print("OK")
