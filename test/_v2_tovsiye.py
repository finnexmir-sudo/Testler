#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""217: idareetmede «Tovsiyeler» bolmesi - sekil."""
import os, time, psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
BASE = "http://127.0.0.1:8010/"; PANEL = BASE + "muellim/index.html"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
OUT = "/tmp/claude-0/yer/tovsiye"; os.makedirs(OUT, exist_ok=True)
def q(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            r = cur.fetchall(); return (r[0] if r else None) if one else r
T = int(time.time() * 1000)
with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    def qeyd(p, mail, ad):
        p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
        p.goto(PANEL); p.wait_for_selector("#email", timeout=30000)
        p.click("#btnSwap"); p.fill("#fname", ad); p.fill("#email", mail)
        p.fill("#pass", "parol1234"); p.click("#btnAuth")
        p.wait_for_selector("#btnSetup", timeout=30000)
        p.fill("#aname", ad); p.click("#btnSetup")
        p.wait_for_selector("#btnGroup", timeout=30000)
    #  getiren
    ctx = br.new_context(viewport={"width": 1280, "height": 900}); pa = ctx.new_page()
    ma = "rfa%d@t.az" % T
    qeyd(pa, ma, "Qızbəst müəllim")
    own = q("select a.owner_id o from public.accounts a join auth.users u on u.id=a.owner_id"
            " where u.email=%s", (ma,), one=True)["o"]
    kod = q("select app.ref_code_for(%s) k", (own,), one=True)["k"]
    q("insert into public.user_roles (user_id, role) values (%s,'admin') on conflict do nothing", (own,))
    ctx.close()
    #  iki getirilen
    for i, ad in enumerate(["Atilla Yaverli", "Nigar müəllimə"]):
        c2 = br.new_context(); p2 = c2.new_page()
        p2.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
        p2.goto(BASE + "index.html?src=hemkar&r=" + kod); p2.wait_for_timeout(500)
        p2.goto(PANEL); p2.wait_for_selector("#email", timeout=30000)
        p2.click("#btnSwap"); p2.fill("#fname", ad); p2.fill("#email", "rfb%d%d@t.az" % (T, i))
        p2.fill("#pass", "parol1234"); p2.click("#btnAuth")
        p2.wait_for_selector("#btnSetup", timeout=30000)
        c2.close()
    #  admin ekrani
    for tag, vp in (("d", {"width": 1280, "height": 900}), ("m", {"width": 390, "height": 844})):
        c3 = br.new_context(viewport=vp, device_scale_factor=2); p3 = c3.new_page()
        p3.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
        p3.goto(PANEL); p3.wait_for_selector("#email", timeout=30000)
        p3.fill("#email", ma); p3.fill("#pass", "parol1234"); p3.click("#btnAuth")
        p3.wait_for_selector("#btnGroup", timeout=30000)
        p3.goto(PANEL + "#/adm"); p3.wait_for_timeout(3000)
        el = p3.locator(".card.tight", has_text="Tövsiyələr").first
        print(tag, "bolme var:", el.count() if hasattr(el, "count") else "?")
        if el.count():
            print("  ", el.inner_text().replace("\n", " | ")[:200])
            el.scroll_into_view_if_needed(); p3.wait_for_timeout(300)
            el.screenshot(path="%s/tovsiye_%s.png" % (OUT, tag))
        c3.close()
    br.close()
print("OK")
