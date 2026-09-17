#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""204 sekilleri: cap veraqi altligi, netice karti, «Həmkarına göndər», Huni menbe bolgusu."""
import time, psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright
PANEL = "http://127.0.0.1:8010/muellim/index.html"
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
OUT = "/tmp/claude-0/shot"
def db(q, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(q)
        if cur.description: return cur.fetchone() if one else cur.fetchall()
HIDE = "#demoBar{display:none!important}"
with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    # bir nece qeydiyyat menbe ile - huni bolgusu dolu gorunsun
    for i, src in enumerate(["wa", "wa", "hemkar", ""]):
        p = br.new_context(viewport={"width": 1280, "height": 800}).new_page()
        p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
        p.goto(PANEL); p.wait_for_selector("#email", timeout=30000)
        if src: p.evaluate("sessionStorage.setItem('bil10_src', '%s')" % src)
        p.click("#btnSwap"); p.wait_for_selector("#fname", timeout=8000)
        p.fill("#fname", "Müəllim %d" % i); p.fill("#email", "rk%d_%d@test.az" % (int(time.time()), i)); p.fill("#pass", "parol123"); p.click("#btnAuth")
        p.wait_for_selector("#btnSetup", timeout=30000); p.context.close()
    db("delete from public.app_state where key='demo_reset'"); db("select public.rpc_demo_reset()")
    p = br.new_context(viewport={"width": 1280, "height": 800}).new_page()
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    p.goto(PANEL + "#/demo"); p.wait_for_selector("#demoBar", timeout=60000); p.wait_for_selector("#groups .gcard", timeout=30000)
    p.add_style_tag(content=HIDE)
    a = db("select owner_id from public.accounts where is_demo and id <> app.demo_account() order by created_at desc limit 1", one=True)
    db("insert into public.user_roles (user_id, role) values ('%s', 'admin') on conflict do nothing" % a["owner_id"])
    # 1. test veraqi: hemkar duymesi
    t = db("select id::text from public.tests where owner_type='educator' and owner_id='%s' and not is_diagnostic order by created_at desc limit 1" % a["owner_id"], one=True)
    p.evaluate("location.hash = '#/t/%s'" % t["id"]); p.wait_for_selector("#btnHemkar", timeout=30000); p.wait_for_timeout(500)
    p.click("#btnHemkar"); p.wait_for_selector("#hemkarMsg .hmtxt", timeout=8000); p.wait_for_timeout(300)
    p.screenshot(path=OUT + "/rk_hemkar_d.png"); print("hemkar")
    # 2. cap veraqi (printBox) - altliq
    p.click("#btnPrn"); p.wait_for_timeout(600)
    p.add_style_tag(content="body.printing>:not(#printBox){display:none!important} body.printing #printBox{display:block;background:#fff;color:#000;padding:24px;font:12.5px/1.5 Georgia,serif;max-width:700px;margin:0 auto} #printBox .ppfoot{font-size:9.5px;color:#8a8a8a;text-align:center;border-top:.5px solid #d8d8d8;padding-top:4px;margin-top:10px} #printBox .ppq{margin:0 0 12px}")
    p.evaluate("document.body.classList.add('printing')")
    p.wait_for_timeout(300)
    p.evaluate("document.querySelector('#printBox .ppfoot').scrollIntoView({block:'end'})"); p.wait_for_timeout(200)
    p.screenshot(path=OUT + "/rk_cap_d.png"); print("cap")
    p.evaluate("document.body.classList.remove('printing')")
    # 3. netice karti
    s = db("select st.id::text sid, st.class_id::text gid from public.students st join public.accounts a on a.id = st.account_id where a.owner_id='%s' and st.class_id is not null order by st.created_at limit 1" % a["owner_id"], one=True)
    p.evaluate("location.hash = '#/s/%s/%s'" % (s["sid"], s["gid"])); p.wait_for_selector("#sTabs", timeout=30000)
    p.click("#sTabs [data-v='x']"); p.wait_for_selector("#pcv", state="attached", timeout=15000); p.wait_for_timeout(800)
    p.locator("#pcv").screenshot(path=OUT + "/rk_kart.png"); print("kart")
    # 4. huni
    p.evaluate("location.hash = '#/'"); p.wait_for_timeout(400)
    p.evaluate("location.hash = '#/adm'"); p.wait_for_selector(".card.huni", timeout=30000); p.wait_for_timeout(600)
    p.evaluate("document.querySelector('.card.huni').scrollIntoView({block:'center'})"); p.wait_for_timeout(300)
    p.screenshot(path=OUT + "/rk_huni_d.png"); print("huni")
    p.context.close(); br.close()
db("delete from public.user_roles where role='admin' and user_id in (select owner_id from public.accounts where is_demo)")
print("OK")
