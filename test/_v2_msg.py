#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""199: admin -> muellim mesaji ekranlari: Icmal karti, Profil cavab, Idareetme gonderme -> /tmp/claude-0/v2/msg_*.png"""
import os, psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"; BASE = "http://127.0.0.1:8010/"; PANEL = BASE + "muellim/index.html"
OUT = "/tmp/claude-0/v2"; os.makedirs(OUT, exist_ok=True)
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
def db(q, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(q)
        if cur.description: return cur.fetchone() if one else cur.fetchall()
db("delete from public.app_state where key='demo_reset'"); db("select public.rpc_demo_reset()")
db("delete from public.feedback where author_type='admin'")
db("delete from public.user_roles where role='admin' and user_id in (select owner_id from public.accounts where is_demo)")
MSG = "Salam, İlahə müəllimə! Gördüm ki, qrup yaratmısınız, hələ şagird əlavə olunmayıb. Şagirdlərin adını və sinfini bura cavab kimi yazsanız, özüm əlavə edib giriş kodlarını göndərərəm. Sonra ilk testi birlikdə yığarıq."
COPY = {}
def seed():
    #  #/demo her ziyaretciye numunenin NUSXESINI acir - mesaj hemin nusxeye yazilir
    a = db("select id, owner_id from public.accounts where is_demo and id <> app.demo_account() order by created_at desc limit 1", one=True)
    db("insert into public.feedback (author_type, user_id, account_id, kind, page, body, status, created_at) values ('admin', app.demo_owner(), '%s', 'mesaj', 'admin', '%s', 'closed', now() - interval '3 hours')" % (a["id"], MSG.replace("'", "''")))
    db("insert into public.user_roles (user_id, role) values ('%s', 'admin') on conflict do nothing" % a["owner_id"])
    COPY["id"] = a["id"]
HIDE = "#demoBar{display:none!important}"
with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    for tag, vp, dpr in (("d", {"width": 1280, "height": 800}, 1), ("m", {"width": 390, "height": 844}, 2)):
        p = br.new_context(viewport=vp, device_scale_factor=dpr).new_page()
        p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
        p.goto(PANEL + "#/demo"); p.wait_for_selector("#demoBar", timeout=60000)
        p.wait_for_selector("#groups .gcard", timeout=30000); seed()
        p.reload(); p.wait_for_selector("#amsgCard", timeout=30000); p.wait_for_selector("#groups .gcard", timeout=30000)
        p.add_style_tag(content=HIDE); p.wait_for_timeout(700)
        p.screenshot(path="%s/msg_%s_home.png" % (OUT, tag), full_page=False); print(tag, "home")
        p.click("#amsgReply"); p.wait_for_selector("#fbReply .fbctx", timeout=15000); p.wait_for_timeout(600)
        p.fill("#fbT", "Salam! Bəli, 7-ci sinifdən 12 nəfərdir, siyahını axşam göndərirəm.")
        p.evaluate("document.querySelector('#fbCard').scrollIntoView({block:'start'})"); p.wait_for_timeout(300)
        p.screenshot(path="%s/msg_%s_me.png" % (OUT, tag), full_page=False); print(tag, "me")
        p.click("#fbGo"); p.wait_for_selector("#fbM .ok, #fbM .msg", timeout=15000); p.wait_for_timeout(900)
        p.evaluate("document.querySelector('#fbMine').scrollIntoView({block:'start'})"); p.wait_for_timeout(300)
        p.screenshot(path="%s/msg_%s_me2.png" % (OUT, tag), full_page=False); print(tag, "me2")
        if tag == "d":
            p.evaluate("location.hash = '#/adm'"); p.wait_for_selector("#admList .admr", timeout=20000); p.wait_for_timeout(800)
            row = p.locator("#admList .admr").filter(has=p.locator(".rmsg")).first
            row.locator("details.rmenu > summary").click(); p.wait_for_timeout(300)
            row.locator(".rmsg textarea").fill("Salam! Qrup qurmusunuz, şagirdləri mən əlavə edim? Siyahını bura yazın.")
            row.scroll_into_view_if_needed(); p.wait_for_timeout(300)
            p.screenshot(path="%s/msg_%s_adm.png" % (OUT, tag), full_page=False); print(tag, "adm")
            #  numune hesabin yazisi admin siyahisinda gizlidir - sekil ucun nusxeni adi hesab kimi gosteririk
            db("update public.accounts set is_demo = false where id = '%s'" % COPY["id"])
            p.evaluate("location.hash = '#/'"); p.wait_for_timeout(400)
            p.evaluate("location.hash = '#/adm'"); p.wait_for_selector("#admList .admr", timeout=20000); p.wait_for_timeout(600)
            p.evaluate("document.querySelector('#fbF [data-fs=\"new\"]') && document.querySelector('#fbF [data-fs=\"new\"]').click()")
            p.wait_for_selector("#fbList .fbc .fbctx", timeout=15000); p.wait_for_timeout(500)
            p.evaluate("document.querySelector('#fbList .fbc .fbctx').scrollIntoView({block:'center'})"); p.wait_for_timeout(300)
            p.screenshot(path="%s/msg_%s_adm2.png" % (OUT, tag), full_page=False); print(tag, "adm2")
            db("update public.accounts set is_demo = true where id = '%s'" % COPY["id"])
        p.context.close()
    br.close()
db("delete from public.user_roles where role='admin' and user_id in (select owner_id from public.accounts where is_demo)")
print("OK")
