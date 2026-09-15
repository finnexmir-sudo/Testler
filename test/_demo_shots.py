#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Carx ucun numune hesabin real ekranlari -> /tmp/claude-0/video/shots/*.png (1080x1920).
Muellim (7-ci sinif qrupu), sagird (DEMO0001), valideyn (VDEMO001)."""
import os, psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"; BASE = "http://127.0.0.1:8010/"; PANEL = BASE + "muellim/index.html"
OUT = "/tmp/claude-0/video/shots"; os.makedirs(OUT, exist_ok=True)
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
def db(q, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(q)
        if cur.description: return cur.fetchone() if one else cur.fetchall()
db("delete from public.app_state where key='demo_reset'"); db("select public.rpc_demo_reset()")
HIDE = "#demoBar{display:none!important}"
def shot(p, name, sel=None, top=0):
    if sel:
        p.evaluate("(s) => { const e = document.querySelector(s); if (e) { e.scrollIntoView({block:'start'}); window.scrollBy(0, -%d); } }" % top, sel)
    p.wait_for_timeout(400); p.screenshot(path="%s/%s.png" % (OUT, name)); print("  ", name)
with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium-1194/chrome-linux/chrome", args=["--no-sandbox"])
    def page():
        p = br.new_context(viewport={"width": 432, "height": 768}, device_scale_factor=2.5).new_page()
        p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
        return p
    # ---- muellim
    p = page()
    p.goto(PANEL + "#/demo"); p.wait_for_selector("#demoBar", timeout=60000); p.wait_for_selector("#groups .gcard", timeout=30000)
    p.add_style_tag(content=HIDE); p.wait_for_timeout(800); shot(p, "home")
    p.locator("#groups .gcard", has_text="7-ci sinif").first.click(); p.wait_for_selector("#gTabs", timeout=15000)
    p.wait_for_function("document.querySelector('#prep .prow')", timeout=20000); p.wait_for_timeout(600)
    gid = p.evaluate("location.hash").split("/")[-1]
    p.click("#gTabs [data-v='s']"); p.wait_for_selector(".stu", timeout=15000); shot(p, "grp", "#gTabs", 70)
    shot(p, "prep", "#prep", 60)
    p.click("#gTabs [data-v='p']"); p.wait_for_selector(".plcur", timeout=15000); shot(p, "plan", ".card.plan", 70)
    p.evaluate("location.hash = '#/gen'"); p.wait_for_selector("#gsub", timeout=15000); p.wait_for_timeout(800); shot(p, "gen")
    p.evaluate("location.hash = '#/a/" + gid + "'"); p.wait_for_selector("#hwText", timeout=15000); p.wait_for_timeout(800); shot(p, "asg")
    shot(p, "hw", "#hwForm", 70)
    p.evaluate("location.hash = '#/r/" + gid + "'"); p.wait_for_selector("#rTabs", timeout=15000); p.wait_for_timeout(1200); shot(p, "rep")
    sid = db("select s.id::text i from public.students s where s.class_id = '%s' order by s.full_name limit 1" % gid, one=True)["i"]
    p.evaluate("location.hash = '#/s/" + sid + "/" + gid + "'"); p.wait_for_selector("#dgMap", timeout=20000); p.wait_for_timeout(800)
    shot(p, "card", "#diagBox", 70)
    p.context.close()
    # ---- sagird
    s = page()
    s.goto(BASE + "sagird/index.html?kod=DEMO0001"); s.wait_for_selector(".test", timeout=30000); s.wait_for_timeout(800); shot(s, "s_home")
    #  test acilanda evvel giris ekrani (Basla) ola biler; sual gelmese
    #  hemin ekran cekilir - carx ucun yeterlidir
    if s.locator(".test.asg").count():
        s.locator(".test.asg").first.click(); s.wait_for_timeout(1500)
        for sel in ("#btnStart", "button:has-text('Başla')"):
            if s.locator(sel).count() and s.locator(sel).first.is_visible():
                s.locator(sel).first.click(); s.wait_for_timeout(1000); break
        try: s.wait_for_selector(".opt", timeout=10000)
        except Exception: pass
        shot(s, "s_q")
    s.context.close()
    # ---- valideyn
    v = page()
    v.goto(BASE + "valideyn/index.html?kod=VDEMO001"); v.wait_for_selector(".who", timeout=30000); v.wait_for_timeout(900); shot(v, "par")
    v.context.close(); br.close()
print("OK", sorted(os.listdir(OUT)))
