#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""205: sagird siyahisi netice ile - masaustu (numune) + telefon (teze hesab, girmeyen sagird)."""
import time
from playwright.sync_api import sync_playwright
PANEL = "http://127.0.0.1:8010/muellim/index.html"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
OUT = "/tmp/claude-0/shot"
with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    for tag, vp in (("d", {"width": 1280, "height": 860}), ("m", {"width": 390, "height": 844})):
        p = br.new_context(viewport=vp).new_page()
        p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
        p.goto(PANEL + "#/demo"); p.wait_for_selector("#demoBar", timeout=90000); p.wait_for_selector("#groups .gcard", timeout=30000)
        p.add_style_tag(content="#demoBar{display:none!important}")
        p.locator("#groups .gcard", has_text="7-ci sinif").first.click(); p.wait_for_selector(".stu", timeout=30000); p.wait_for_timeout(600)
        p.evaluate("document.querySelector('#gTabs').scrollIntoView({block:'start'})"); p.wait_for_timeout(300)
        p.screenshot(path=OUT + "/stu_demo_" + tag + ".png"); print("demo", tag)
        p.context.close()
    # teze hesab: sagird hele girmeyib - kodlar aciq
    p = br.new_context(viewport={"width": 360, "height": 780}).new_page()
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    p.goto(PANEL); p.wait_for_selector("#email", timeout=30000)
    p.click("#btnSwap"); p.fill("#fname", "Leyla müəllim"); p.fill("#email", "stu%d@t.az" % int(time.time())); p.fill("#pass", "parol1234"); p.click("#btnAuth")
    p.wait_for_selector("#btnSetup", timeout=30000); p.fill("#aname", "Leyla müəllim — riyaziyyat"); p.click("#btnSetup")
    p.wait_for_selector("#btnGroup", timeout=30000); p.fill("#gname", "5-ci sinif"); p.click("#btnGroup")
    p.wait_for_selector("#groups .gcard", timeout=15000); p.click("#groups .gcard"); p.wait_for_selector("#gTabs", timeout=15000)
    try: p.wait_for_selector("#sname", state="visible", timeout=3000)
    except Exception: p.click("#btnStuOpen")
    for nm in ("Ayan Məmmədova", "Murad Həsənov"):
        p.fill("#sname", nm); p.click("#btnStu"); p.wait_for_timeout(700)
    p.wait_for_selector(".stu .l3 .code", timeout=15000); p.wait_for_timeout(400)
    h = p.locator(".stu").first.evaluate("e => e.getBoundingClientRect().height")
    print("row height 360px:", round(h))
    p.evaluate("document.querySelector('#gTabs').scrollIntoView({block:'start'})"); p.wait_for_timeout(300)
    p.screenshot(path=OUT + "/stu_new_m.png"); print("new m")
    br.close()
print("OK")
