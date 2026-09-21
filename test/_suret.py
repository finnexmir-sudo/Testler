#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""«Panel niye 5,4 saniye acilir?» - soyuq acilisi hisse-hisse olcur.

Statik fayllar SIXISLENMIS gelir (test/_gzweb.py, 8011) - GitHub Pages
kimi.  Sebeke ve prosessor CDP ile yavaslasdirilir.  Olculen an
tetbiqin ozunun olcduyu andir: Icmal ISLEK olanda (qrup kartlari).
"""
import os, time, subprocess, psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
WEB = "http://127.0.0.1:8011/"
PANEL = WEB + "muellim/index.html"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
SENARI = [
    ("yaxsi 4G", 12_000_000/8, 40, 1),
    ("adi 4G",    4_000_000/8, 100, 4),
    ("zeif 3G",   1_600_000/8, 300, 6),
]
gz = subprocess.Popen(["python3", "test/_gzweb.py", "8011"])
time.sleep(1.5)
def q(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            r = cur.fetchall(); return (r[0] if r else None) if one else r
try:
    with sync_playwright() as pw:
        br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
        #  bir defe hesab qurulur, sonra hemin sessiya ile olculur
        ctx = br.new_context(viewport={"width": 390, "height": 844})
        p = ctx.new_page()
        p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
        p.goto(PANEL); p.wait_for_selector("#email", timeout=30000)
        mail = "sur%d@t.az" % int(time.time() * 1000)
        p.click("#btnSwap"); p.fill("#fname", "Sürət müəllim"); p.fill("#email", mail)
        p.fill("#pass", "parol1234"); p.click("#btnAuth")
        p.wait_for_selector("#btnSetup", timeout=30000)
        p.fill("#aname", "Sürət müəllim"); p.click("#btnSetup")
        p.wait_for_selector("#btnGroup", timeout=30000)
        p.fill("#gname", "5-ci sinif"); p.click("#btnGroup")
        p.wait_for_selector("#groups .gcard", timeout=20000)
        sess = p.evaluate("localStorage.getItem('panel_session')")
        ctx.close()

        for ad, down, rtt, cpu in SENARI:
            ctx = br.new_context(viewport={"width": 390, "height": 844})
            pg = ctx.new_page()
            pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
            #  sessiyani qoyuruq: giris formasi yox, birbasa panel
            pg.goto(WEB + "muellim/", wait_until="domcontentloaded")
            pg.evaluate("(s)=>localStorage.setItem('panel_session',s)", sess)
            cdp = ctx.new_cdp_session(pg)
            cdp.send("Network.enable"); cdp.send("Network.clearBrowserCache")
            cdp.send("Network.emulateNetworkConditions", {
                "offline": False, "downloadThroughput": down,
                "uploadThroughput": down / 4, "latency": rtt})
            cdp.send("Emulation.setCPUThrottlingRate", {"rate": cpu})
            t0 = time.monotonic()
            pg.goto(PANEL, wait_until="commit", timeout=180000)
            pg.wait_for_selector("#groups .gcard", timeout=180000)
            tam = pg.evaluate("Math.round(performance.now())")
            d = pg.evaluate("""() => {
              const n = performance.getEntriesByType('navigation')[0] || {};
              const r = performance.getEntriesByType('resource');
              const kb = x => Math.round((x.transferSize||0)/1024);
              const own = r.filter(x => x.name.indexOf('8011') >= 0);
              const api = r.filter(x => x.name.indexOf('54321') >= 0);
              const app = own.filter(x => x.name.indexOf('app.min.js') >= 0)[0] || {};
              return {
                html: Math.round(n.responseEnd||0),
                appEnd: Math.round(app.responseEnd||0), appKb: kb(app),
                fayl: own.length, faylKb: own.reduce((s,x)=>s+kb(x),0),
                api: api.length,
                apiIlk: api.length ? Math.round(Math.min(...api.map(x=>x.startTime))) : 0,
                apiSon: api.length ? Math.round(Math.max(...api.map(x=>x.responseEnd))) : 0
              };
            }""")
            print("%-9s  ICMAL ISLEK: %6d ms" % (ad, tam))
            print("           html %4d ms · app.js bitdi %5d ms (%d KB) · %d fayl %d KB"
                  % (d["html"], d["appEnd"], d["appKb"], d["fayl"], d["faylKb"]))
            print("           ilk API %5d ms · son API %5d ms · %d sorgu"
                  % (d["apiIlk"], d["apiSon"], d["api"]))
            print("           => fayllar %d ms | API zenciri %d ms | qalan %d ms"
                  % (d["apiIlk"], d["apiSon"] - d["apiIlk"], tam - d["apiSon"]))
            ctx.close()
        br.close()
finally:
    gz.terminate()
print("OK")
