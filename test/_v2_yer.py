#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Teze muellim telefonda: hansi ekran ne qeder uzundur?  Olcu + tam sekil.

Numune (demo) bazasi deyil - QEYDIYYATDAN TEZE KECMIS hesab, cunki
muellimin «yorucu ve qeliz» dediyi ele ilk gunun ekranlaridir.
"""
import os, sys, time
from playwright.sync_api import sync_playwright
PANEL = "http://127.0.0.1:8010/muellim/index.html"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
TAG = sys.argv[1] if len(sys.argv) > 1 else "sonra"
OUT = "/tmp/claude-0/yer/" + os.environ.get("TAG", TAG); os.makedirs(OUT, exist_ok=True)
W, H = 390, 844
with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    p = br.new_context(viewport={"width": W, "height": H}, device_scale_factor=2).new_page()
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    p.goto(PANEL); p.wait_for_selector("#email", timeout=30000)
    p.click("#btnSwap"); p.fill("#fname", "Leyla müəllim")
    p.fill("#email", "yer%d@t.az" % int(time.time() * 1000)); p.fill("#pass", "parol1234")
    p.click("#btnAuth")
    p.wait_for_selector("#btnSetup", timeout=30000)
    p.fill("#aname", "Leyla müəllim — riyaziyyat"); p.click("#btnSetup")
    p.wait_for_selector("#btnGroup", timeout=30000)
    p.fill("#gname", "5-ci sinif"); p.click("#btnGroup")
    p.wait_for_selector("#groups .gcard", timeout=20000)
    p.click("#groups .gcard"); p.wait_for_selector("#gTabs", timeout=20000)
    gid = p.evaluate("location.hash.split('/')[2]")
    try: p.wait_for_selector("#sname", state="visible", timeout=3000)
    except Exception: p.click("#btnStuOpen")
    for nm in ("Ayan Məmmədova", "Murad Həsənov", "Nihad Quliyev"):
        p.fill("#sname", nm); p.click("#btnStu"); p.wait_for_timeout(700)
    p.wait_for_selector(".stu", timeout=15000)
    def olc(ad, hash_, sel):
        p.goto(PANEL + hash_)
        try: p.wait_for_selector(sel, timeout=20000)
        except Exception: print("   ! tapilmadi:", sel)
        p.wait_for_timeout(1400)
        h = p.evaluate("document.body.scrollHeight")
        print("  %-10s %5d px = %.1f ekran" % (ad, h, h / float(H)))
        p.screenshot(path="%s/%s.png" % (OUT, ad), full_page=True)
    olc("1icmal", "#/", "#hTiles, #onb")
    olc("2qrup", "#/g/" + gid, "#gTabs")
    olc("3tapsiriq", "#/a/" + gid, ".card")
    olc("4gen", "#/gen", ".card")
    olc("5profil", "#/me", ".card")
    br.close()
print("OK")
