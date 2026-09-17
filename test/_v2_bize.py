#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Ekran sekli: ust zolaqda «Bizə yaz» + oz ekrani (masaustu + telefon). Numune hesabla."""
from playwright.sync_api import sync_playwright
PANEL = "http://127.0.0.1:8010/muellim/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
OUT = "/tmp/claude-0/shot/"
import os; os.makedirs(OUT, exist_ok=True)
with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    for name, w, h in (("desk", 1366, 900), ("tel", 390, 844)):
        ctx = br.new_context(viewport={"width": w, "height": h}, device_scale_factor=1)
        p = ctx.new_page()
        p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
        p.goto(PANEL + "#/demo"); p.wait_for_selector("#demoBar", timeout=90000)
        p.wait_for_selector("#groups .gcard", timeout=30000); p.wait_for_timeout(600)
        p.screenshot(path=OUT + "bize_top_" + name + ".png")
        p.click("#btnFb"); p.wait_for_selector("#fbCard", timeout=15000); p.wait_for_timeout(500)
        p.screenshot(path=OUT + "bize_ekran_" + name + ".png")
        p.evaluate("location.hash = '#/me'"); p.wait_for_selector("#btnMeFb", timeout=15000); p.wait_for_timeout(400)
        p.screenshot(path=OUT + "bize_profil_" + name + ".png")
        ctx.close()
    br.close()
print("ok")
