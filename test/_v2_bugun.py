#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""209: «Bu gün» karti - masaustu + telefon (numune hesab)."""
from playwright.sync_api import sync_playwright
PANEL = "http://127.0.0.1:8010/muellim/index.html"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "http://127.0.0.1:8010/sagird/", PARENT_URL: "http://127.0.0.1:8010/valideyn/", SHOW_PLANS: false };"""
OUT = "/tmp/claude-0/shot"
with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    for tag, vp in (("d", {"width": 1280, "height": 820}), ("m", {"width": 390, "height": 844})):
        p = br.new_context(viewport=vp).new_page()
        p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
        p.goto(PANEL + "#/demo"); p.wait_for_selector("#demoBar", timeout=90000)
        p.wait_for_selector("#groups .gcard", timeout=30000)
        p.add_style_tag(content="#demoBar{display:none!important}")
        p.wait_for_selector(".card.bugun", timeout=20000); p.wait_for_timeout(600)
        p.evaluate("document.querySelector('.card.bugun').scrollIntoView({block:'center'})")
        p.wait_for_timeout(300)
        p.screenshot(path=OUT + "/bugun_" + tag + ".png"); print(tag)
        if tag == "d":
            if p.locator("#bgSend").count():
                p.click("#bgSend")
                p.wait_for_selector(".bgact .muted", timeout=20000); p.wait_for_timeout(500)
                p.evaluate("document.querySelector('.card.bugun').scrollIntoView({block:'center'})")
                p.wait_for_timeout(300)
                p.screenshot(path=OUT + "/bugun_sent.png"); print("gonderildi")
        p.context.close()
    br.close()
print("OK")
