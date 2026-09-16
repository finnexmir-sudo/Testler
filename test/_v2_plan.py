#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""16.09: plan tek secim duymesi, «Planı sil» yeri, Deftər → Cədvəl nisani (telefon)"""
import os, psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"; BASE = "http://127.0.0.1:8010/"; PANEL = BASE + "muellim/index.html"
OUT = "/tmp/claude-0/v2"; os.makedirs(OUT, exist_ok=True)
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
def db(q):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur: cur.execute(q)
db("delete from public.app_state where key='demo_reset'"); db("select public.rpc_demo_reset()")
HIDE = "#demoBar{display:none!important}"
with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    p = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2).new_page()
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    p.goto(PANEL + "#/demo"); p.wait_for_selector("#demoBar", timeout=60000); p.wait_for_selector("#groups .gcard", timeout=30000)
    p.add_style_tag(content=HIDE)
    p.locator("#groups .gcard", has_text="7-ci sinif").first.click(); p.wait_for_selector("#gTabs", timeout=15000)
    p.click("#gTabs [data-v='p']"); p.wait_for_selector(".plcur", timeout=15000); p.wait_for_timeout(500)
    det = p.locator(".card.plan details").first
    if not det.evaluate("d => d.open"): det.locator("summary").first.click(); p.wait_for_timeout(400)
    p.locator(".plgrp[open] .plck").first.check(); p.wait_for_selector("[data-plmulti]", timeout=4000); p.wait_for_timeout(300)
    p.locator("[data-plmulti]").scroll_into_view_if_needed(); p.evaluate("window.scrollBy(0,-200)"); p.wait_for_timeout(300)
    p.screenshot(path=OUT + "/plan_m_1.png"); print("plan 1")
    p.locator("[data-pldel]").scroll_into_view_if_needed(); p.evaluate("window.scrollBy(0,-350)"); p.wait_for_timeout(300)
    p.screenshot(path=OUT + "/plan_m_2.png"); print("plan 2")
    p.click("#gTabs [data-v='d']"); p.wait_for_selector("#schFold", timeout=15000); p.wait_for_timeout(500)
    p.locator("#schFold").scroll_into_view_if_needed(); p.evaluate("window.scrollBy(0,-120)"); p.wait_for_timeout(300)
    p.screenshot(path=OUT + "/sch_m_1.png"); print("sch closed")
    p.locator("#schFold summary").click(); p.wait_for_timeout(400)
    p.screenshot(path=OUT + "/sch_m_2.png"); print("sch open")
    p.locator("#schFold summary").click(); p.wait_for_timeout(300)
    p.evaluate("document.getElementById('ledOpen').scrollIntoView({block:'center'})"); p.wait_for_timeout(300)
    p.screenshot(path=OUT + "/led_m_1.png"); print("led")
    br.close()
print("OK")
