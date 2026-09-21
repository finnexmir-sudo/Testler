#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Suret olcusu: yalniz Icmal ile acilanda yazilmalidir.

Evvel Icmaldan basqa ekranla acilanda 6 saniyelik TAYMER yazilirdi -
olcu deyil, uydurma reqem idi (idareetmede «4-8 saniye» kovasi 57%).
"""
import time
from playwright.sync_api import sync_playwright
PANEL = "http://127.0.0.1:8010/muellim/index.html"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
OK = [0]
def ok(c, ad, elave=""):
    print(("  OK   " if c else "  SEHV ") + ad + ("  " + str(elave) if elave else ""))
    if not c: OK[0] += 1
with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 390, "height": 844})
    p = ctx.new_page()
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    p.goto(PANEL); p.wait_for_selector("#email", timeout=30000)
    mail = "prf%d@t.az" % int(time.time() * 1000)
    p.click("#btnSwap"); p.fill("#fname", "Ölçü müəllim"); p.fill("#email", mail)
    p.fill("#pass", "parol1234"); p.click("#btnAuth")
    p.wait_for_selector("#btnSetup", timeout=30000)
    p.fill("#aname", "Ölçü müəllim"); p.click("#btnSetup")
    p.wait_for_selector("#btnGroup", timeout=30000)
    p.fill("#gname", "5-ci sinif"); p.click("#btnGroup")
    p.wait_for_selector("#groups .gcard", timeout=20000)
    sess = p.evaluate("localStorage.getItem('panel_session')")
    ctx.close()

    def ac(hash_, gozle, saniye=9):
        ctx = br.new_context(viewport={"width": 390, "height": 844})
        pg = ctx.new_page()
        say = {"n": 0}
        pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
        def _req(r):
            if "rpc_perf" in r.url:
                say["n"] += 1
                try: print("      [yazilan olcu]", r.post_data)
                except Exception: pass
        pg.on("request", _req)
        pg.goto(PANEL, wait_until="domcontentloaded")
        pg.evaluate("(s)=>localStorage.setItem('panel_session',s)", sess)
        pg.goto(PANEL + hash_); pg.reload()
        pg.wait_for_selector(gozle, timeout=30000)
        pg.wait_for_timeout(saniye * 1000)     # kohne taymer 6 s idi - kecirik
        n = say["n"]; ctx.close(); return n

    print("A · İcmal ilə açılanda ölçü YAZILIR")
    ok(ac("#/", "#groups .gcard") == 1, "bir olcu gedir")
    print("B · Başqa ekranla açılanda ölçü YAZILMIR")
    ok(ac("#/gen", "#gPool, .card") == 0, "generator ekraninda olcu yoxdur")
    ok(ac("#/me", ".card") == 0, "profil ekraninda olcu yoxdur")
    br.close()
print("SURET OLCUSU: " + ("BUTUN YOXLAMALAR KECDI" if not OK[0] else "UGURSUZ: %d" % OK[0]))
