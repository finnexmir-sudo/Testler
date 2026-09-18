#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""214: «Dostuna at» - sagird duymesi + dostun gorduyu sehife."""
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

STUDENT = "http://127.0.0.1:8010/sagird/index.html"
SHARE   = "http://127.0.0.1:8010/s/index.html"
DSN     = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "http://127.0.0.1:8010/sagird/", PARENT_URL: "http://127.0.0.1:8010/valideyn/", SHOW_PLANS: false };"""
OUT = "/tmp/claude-0/shot"

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args) if args else cur.execute(sql)
        if cur.description:
            return cur.fetchone() if one else cur.fetchall()

db("delete from public.shares")
db("""update public.class_plan_items set done_at = coalesce(done_at, now() - interval '1 hour')
       where ord = 1 and plan_id in (select cp.id from public.class_plans cp
                                       join public.classes c on c.id = cp.class_id
                                       join public.accounts a on a.id = c.account_id
                                      where not a.is_demo)""")
db("delete from public.subscriptions")
db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
      select a.id, p.id, 'active', now() + interval '30 days'
        from public.accounts a, public.plans p where p.slug='repetitor-25'""")
CODE = db("select login_code c from public.students limit 1", one=True)["c"]

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    for tag, vp in (("d", {"width": 1280, "height": 900}), ("m", {"width": 390, "height": 844})):
        db("delete from public.shares")
        ctx = br.new_context(viewport=vp)
        p = ctx.new_page()
        p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
        #  navigator.share telefonda var - masaustunde yoxdur; ikisini de
        #  gormek ucun telefonda sondururuk (kopyalama yolu cixir)
        p.add_init_script("try { delete navigator.share; } catch (e) {}")

        #  Sagird: bir testi isle -> netice ekraninda «Dostuna at»
        p.goto(STUDENT); p.wait_for_selector("#btnIn", timeout=30000)
        p.fill("#code", CODE); p.click("#btnIn"); p.wait_for_selector(".test", timeout=30000)
        if p.locator(".test.asg").count() == 0:
            p.locator(".test").first.click()
        else:
            p.locator(".test.asg").first.click()
        p.wait_for_selector(".opt", timeout=30000)
        while True:
            p.locator(".opt").first.click(); p.wait_for_timeout(120)
            if p.locator("#btnNext").count():
                p.click("#btnNext"); p.wait_for_timeout(150)
            else:
                p.once("dialog", lambda d: d.accept())
                p.click("#btnFinish"); break
        p.wait_for_selector(".ring", timeout=30000); p.wait_for_timeout(600)
        #  yigilmis «duz cavablar» bolmesini ac ki, setirler gorunsun
        p.evaluate("""() => { const d = document.querySelector('#main details'); if (d) d.open = true; }""")
        p.wait_for_timeout(300)
        p.evaluate("""() => { const b = document.querySelector('[data-sq]');
                              if (b) b.scrollIntoView({block:'center'}); }""")
        p.wait_for_timeout(250)
        p.screenshot(path=OUT + "/pay_duyme_" + tag + ".png"); print("duyme " + tag)

        p.locator("[data-sq]").first.click()
        p.wait_for_timeout(1200)
        p.screenshot(path=OUT + "/pay_gonderildi_" + tag + ".png"); print("gonderildi " + tag)
        ctx.close()

        K = db("select k from public.shares order by created_at desc limit 1", one=True)["k"]
        #  Dost: linki acir (temiz kontekst - giris yoxdur)
        ctx2 = br.new_context(viewport=vp)
        f = ctx2.new_page()
        f.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
        f.goto(SHARE + "?k=" + K)
        f.wait_for_selector(".sopt", timeout=30000); f.wait_for_timeout(400)
        f.screenshot(path=OUT + "/pay_dost_" + tag + ".png"); print("dost " + tag)
        f.locator(".sopt").first.click()
        f.wait_for_selector(".spitch", timeout=20000); f.wait_for_timeout(400)
        f.screenshot(path=OUT + "/pay_cavab_" + tag + ".png", full_page=(tag == "m")); print("cavab " + tag)
        ctx2.close()

    #  vaxti bitmis link
    db("update public.shares set expires_at = now() - interval '1 day'")
    K = db("select k from public.shares order by created_at desc limit 1", one=True)["k"]
    ctx3 = br.new_context(viewport={"width": 390, "height": 844})
    f = ctx3.new_page()
    f.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    f.goto(SHARE + "?k=" + K); f.wait_for_selector(".serr", timeout=20000); f.wait_for_timeout(300)
    f.screenshot(path=OUT + "/pay_vaxt_m.png"); print("vaxt m")
    ctx3.close()
    br.close()
print("OK")
