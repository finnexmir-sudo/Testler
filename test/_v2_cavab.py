#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""208: «Bize yaz» cavabi sagirde ve valideyne catir - ekran sekilleri."""
import time, psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright
ROOT = "http://127.0.0.1:8010/"
PANEL, STUDENT, PARENT = ROOT + "muellim/index.html", ROOT + "sagird/", ROOT + "valideyn/"
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "http://127.0.0.1:8010/sagird/", PARENT_URL: "http://127.0.0.1:8010/valideyn/", SHOW_PLANS: false };"""
OUT = "/tmp/claude-0/shot"
def db(q, a=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(q, a) if a else cur.execute(q)
        if cur.description: return cur.fetchone() if one else cur.fetchall()

#  numune nusxesinin bir sagirdi ile isleyirik
db("delete from public.feedback where body like 'Sekil208%'")
with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    p = br.new_context(viewport={"width": 1280, "height": 860}).new_page()
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    p.goto(PANEL + "#/demo"); p.wait_for_selector("#demoBar", timeout=90000)
    p.wait_for_selector("#groups .gcard", timeout=30000)
    p.add_style_tag(content="#demoBar{display:none!important}")
    acc = db("select id, owner_id from public.accounts where is_demo and id <> app.demo_account() order by created_at desc limit 1", one=True)
    st = db("select id, full_name, login_code, parent_code from public.students where account_id = %s order by created_at limit 1", (acc["id"],), one=True)
    #  sagird yazir
    db("""insert into public.feedback (author_type, account_id, student_id, kind, page, body, status, created_at)
          values ('student', %s, %s, 'teklif', 'testlər',
                  'Sekil208 daha asan şeylər yaza bilərsiz nooolar amma buda qəşəngdir 6 7 olsun', 'new', now() - interval '2 hours')""",
       (acc["id"], st["id"]))
    db("insert into public.user_roles (user_id, role) values (%s, 'admin') on conflict do nothing", (acc["owner_id"],))
    db("update public.accounts set is_demo = false where id = %s", (acc["id"],))
    try:
        # 1) admin: cavab yazir
        p.evaluate("location.hash = '#/'"); p.wait_for_timeout(400)
        p.evaluate("location.hash = '#/adm'"); p.wait_for_selector("#admList .admr", timeout=30000)
        p.eval_on_selector_all(".fold", "els => els.forEach(e => e.open = true)")
        p.wait_for_selector("#fbList .fbc", timeout=15000); p.wait_for_timeout(400)
        card = p.locator("#fbList .fbc", has_text="Sekil208").first
        card.locator("textarea").fill("Salam, Ayşə! Rəyin üçün sağ ol. Testlərin çətinliyini müəllimin seçir — bu təklifini ona çatdırdıq. Asan suallarla başlayıb yavaş-yavaş çətinləşdirəcəyik.")
        card.scroll_into_view_if_needed(); p.wait_for_timeout(300)
        p.screenshot(path=OUT + "/cvb_adm1.png"); print("adm1")
        card.locator("[data-fbsave]").click()
        p.wait_for_selector(".fbc .fbcm .ok", timeout=8000); p.wait_for_timeout(600)
        # 2) sagird: nisan + cavab
        sp = br.new_context(viewport={"width": 390, "height": 844}).new_page()
        sp.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
        sp.goto(STUDENT); sp.wait_for_selector("#code", timeout=30000)
        sp.fill("#code", st["login_code"]); sp.click("#btnIn")
        sp.wait_for_selector("#fbDot:not(.hide)", timeout=30000)
        sp.evaluate("document.querySelector('#fbBox').scrollIntoView({block:'center'})"); sp.wait_for_timeout(400)
        sp.screenshot(path=OUT + "/cvb_sag_nisan.png"); print("sag nisan")
        sp.click("#fbBox summary"); sp.wait_for_selector("#fbMine .fbre", timeout=10000); sp.wait_for_timeout(500)
        sp.evaluate("document.querySelector('#fbMine').scrollIntoView({block:'center'})"); sp.wait_for_timeout(300)
        sp.screenshot(path=OUT + "/cvb_sag_cavab.png"); print("sag cavab")
        # 3) admin: «oxudu» nisani
        p.reload(); p.wait_for_selector("#admList .admr", timeout=30000)
        p.eval_on_selector_all(".fold", "els => els.forEach(e => e.open = true)")
        p.wait_for_selector("#fbList .fbc", timeout=15000)
        p.click("#fbF .chip[data-fs='all']"); p.wait_for_timeout(700)
        card = p.locator("#fbList .fbc", has_text="Sekil208").first
        card.scroll_into_view_if_needed(); p.wait_for_timeout(300)
        p.screenshot(path=OUT + "/cvb_adm2.png"); print("adm2")
        sp.context.close()
    finally:
        db("update public.accounts set is_demo = true where id = %s", (acc["id"],))
        db("delete from public.user_roles where role='admin' and user_id in (select owner_id from public.accounts where is_demo)")
    br.close()
print("OK")
