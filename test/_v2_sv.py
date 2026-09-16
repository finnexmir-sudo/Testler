#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""v2: sagird ve valideyn tetbiqleri (telefon) -> /tmp/claude-0/v2/s_*.png, v_*.png"""
import os, psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"; BASE = "http://127.0.0.1:8010/"
OUT = "/tmp/claude-0/v2"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
def db(q):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur: cur.execute(q)
db("delete from public.app_state where key='demo_reset'"); db("select public.rpc_demo_reset()")
with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    def page(w=390, h=844, dpr=2):
        p = br.new_context(viewport={"width": w, "height": h}, device_scale_factor=dpr).new_page()
        p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG)); return p
    s = page(1280, 800, 1); s.goto(BASE + "sagird/index.html?kod=DEMO0001"); s.wait_for_selector(".test", timeout=30000); s.wait_for_timeout(900)
    s.screenshot(path=OUT + "/s_desk.png", full_page=True); print("s_home")
    s.context.close()
    v = page(1280, 800, 1); v.goto(BASE + "valideyn/index.html?kod=VDEMO001"); v.wait_for_selector(".who", timeout=30000); v.wait_for_timeout(900)
    v.screenshot(path=OUT + "/v_desk.png", full_page=True); print("v_home")
    v.context.close(); br.close()
print("OK")
