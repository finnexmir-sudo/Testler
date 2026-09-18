#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""212/213: gundelik tekrar - ekran sekilleri (panel_e2e fiksturu)."""
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

PANEL   = "http://127.0.0.1:8010/muellim/index.html"
STUDENT = "http://127.0.0.1:8010/sagird/index.html"
DSN     = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "http://127.0.0.1:8010/sagird/", PARENT_URL: "http://127.0.0.1:8010/valideyn/", SHOW_PLANS: false };"""
OUT = "/tmp/claude-0/shot"

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args) if args else cur.execute(sql)
        if cur.description:
            return cur.fetchone() if one else cur.fetchall()

#  abune geri, paket temiz, defterde bir sehv olsun (slot 2 gorunsun)
db("delete from public.subscriptions")
db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
      select a.id, p.id, 'active', now() + interval '30 days'
        from public.accounts a, public.plans p where p.slug='repetitor-25'""")
db("""update public.class_plan_items set done_at = coalesce(done_at, now() - interval '1 hour')
       where ord = 1 and plan_id in (select cp.id from public.class_plans cp
                                       join public.classes c on c.id = cp.class_id
                                       join public.accounts a on a.id = c.account_id
                                      where not a.is_demo)""")
db("delete from public.daily_packs")
CODE = db("select login_code c from public.students limit 1", one=True)["c"]

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])

    for tag, vp in (("d", {"width": 1280, "height": 900}), ("m", {"width": 390, "height": 844})):
        db("delete from public.daily_packs")
        ctx = br.new_context(viewport=vp)
        p = ctx.new_page()
        p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))

        #  1) sagird: ev ekraninda gundelik kart
        p.goto(STUDENT); p.wait_for_selector("#btnIn", timeout=30000)
        p.fill("#code", CODE); p.click("#btnIn")
        p.wait_for_selector("#dayBox .dcard", timeout=30000); p.wait_for_timeout(500)
        p.screenshot(path=OUT + "/gun_kart_" + tag + ".png"); print("kart " + tag)

        #  2) sual ekrani
        p.click("#btnDay"); p.wait_for_selector(".opt", timeout=20000); p.wait_for_timeout(400)
        p.screenshot(path=OUT + "/gun_sual_" + tag + ".png"); print("sual " + tag)

        #  3) cavabdan sonra izah
        def cavabla(duz):
            qid = db("select (d.items->(jsonb_array_length(d.answers))->>'q') q from public.daily_packs d limit 1", one=True)["q"]
            row = db("select o.id::text o from public.question_options o where o.question_id=%s and o.is_correct=%s limit 1", (qid, duz), one=True) \
                  or db("select o.id::text o from public.question_options o where o.question_id=%s limit 1", (qid,), one=True)
            p.locator("[data-o='%s']" % row["o"]).click()
            p.wait_for_selector("#btnDNext", timeout=20000)
        cavabla(False); p.wait_for_timeout(350)
        p.screenshot(path=OUT + "/gun_cavab_" + tag + ".png"); print("cavab " + tag)

        #  4) bitis ekrani
        for _ in range(5):
            if p.locator("#btnDNext").count() == 0: break
            p.click("#btnDNext"); p.wait_for_timeout(300)
            if p.locator("#btnDHome").count(): break
            cavabla(True); p.wait_for_timeout(200)
        p.wait_for_selector("#btnDHome", timeout=20000); p.wait_for_timeout(400)
        p.screenshot(path=OUT + "/gun_bitdi_" + tag + ".png"); print("bitdi " + tag)

        #  5) abunesiz kilid
        db("delete from public.subscriptions"); db("delete from public.daily_packs")
        p.click("#btnDHome"); p.wait_for_timeout(400)
        p.reload(); p.wait_for_selector("#dayBox .dcard.lock", timeout=30000); p.wait_for_timeout(400)
        p.screenshot(path=OUT + "/gun_kilid_" + tag + ".png"); print("kilid " + tag)
        db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
              select a.id, p.id, 'active', now() + interval '30 days'
                from public.accounts a, public.plans p where p.slug='repetitor-25'""")
        ctx.close()

    #  6) muellim karti: iteleme setri.  Mock parollari YADDASDA saxlayir -
    #  movcud e2e istifadecisi ile girmek olmur; numune hesabla gedirik.
    for tag, vp in (("d", {"width": 1280, "height": 900}), ("m", {"width": 390, "height": 844})):
        ctx = br.new_context(viewport=vp)
        p = ctx.new_page()
        p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
        p.goto(PANEL + "#/demo"); p.wait_for_selector("#demoBar", timeout=120000)
        p.wait_for_selector("#groups .gcard", timeout=60000)
        #  numune surətinin planinda «kecildi» isarelerini sondururuk -
        #  kart mehz bu halda iteleme setrini gosterir
        db("""update public.class_plan_items set done_at = null
               where plan_id in (select cp.id from public.class_plans cp
                                   join public.classes c on c.id = cp.class_id
                                   join public.accounts a on a.id = c.account_id
                                  where a.is_demo)""")
        p.add_style_tag(content="#demoBar{display:none!important}")
        p.goto(PANEL + "#/"); p.reload()
        p.wait_for_selector("#hBugun .bugun", timeout=60000); p.wait_for_timeout(700)
        p.add_style_tag(content="#demoBar{display:none!important}")
        p.evaluate("document.querySelector('.card.bugun').scrollIntoView({block:'center'})")
        p.wait_for_timeout(300)
        p.screenshot(path=OUT + "/gun_muellim_" + tag + ".png"); print("muellim " + tag)
        ctx.close()
    br.close()
print("OK")
