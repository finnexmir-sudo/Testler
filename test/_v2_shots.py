#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""v2 dizayn: panelin esas ekranlari masaustu + telefon -> /tmp/claude-0/v2/*.png"""
import os, psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"; BASE = "http://127.0.0.1:8010/"; PANEL = BASE + "muellim/index.html"
OUT = "/tmp/claude-0/v2"; os.makedirs(OUT, exist_ok=True)
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
def db(q, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(q)
        if cur.description: return cur.fetchone() if one else cur.fetchall()
db("delete from public.app_state where key='demo_reset'"); db("select public.rpc_demo_reset()")
HIDE = "#demoBar{display:none!important}"
with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    for tag, vp, dpr in (("d", {"width": 1280, "height": 800}, 1), ("m", {"width": 390, "height": 844}, 2)):
        p = br.new_context(viewport=vp, device_scale_factor=dpr).new_page()
        p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
        p.goto(PANEL + "#/demo"); p.wait_for_selector("#demoBar", timeout=60000); p.wait_for_selector("#groups .gcard", timeout=30000)
        p.add_style_tag(content=HIDE); p.wait_for_timeout(900)
        p.screenshot(path="%s/%s_home.png" % (OUT, tag), full_page=True); print(tag, "home")
        p.locator("#groups .gcard", has_text="7-ci sinif").first.click(); p.wait_for_selector("#gTabs", timeout=15000)
        p.wait_for_function("document.querySelector('#prep .prow')", timeout=20000); p.wait_for_timeout(700)
        gid = p.evaluate("location.hash").split("/")[-1]
        p.screenshot(path="%s/%s_grp.png" % (OUT, tag), full_page=True); print(tag, "grp")
        p.evaluate("location.hash = '#/r/" + gid + "'"); p.wait_for_selector("#rTabs", timeout=15000); p.wait_for_timeout(1200)
        p.screenshot(path="%s/%s_rep.png" % (OUT, tag), full_page=True); print(tag, "rep")
        p.evaluate("location.hash = '#/gen'"); p.wait_for_selector("#gsub", timeout=15000); p.wait_for_timeout(800)
        p.screenshot(path="%s/%s_gen.png" % (OUT, tag), full_page=True); print(tag, "gen")
        p.context.close()
    br.close()
print("OK")
