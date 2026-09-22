#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ONBAXIS: plan setrinde «fesil sonunda · 2/4» izahi nece gorunur.

Yoxlama deyil - SEKIL cekir (masaustu + telefon).  Iki fesil, birincisi
yarim kecilmis: izahli setirler, duymeli setir ve kecilmemis setirler
bir ekranda gorunsun.
  test/tek.sh _plan_sekil.py
Sekiller: /tmp/claude-0/plansekil/masaustu.png, telefon.png
"""
import os, sys, time, psycopg2, psycopg2.extras
sys.path.insert(0, "test")
from playwright.sync_api import sync_playwright
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
PANEL = "http://127.0.0.1:8010/muellim/index.html"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
OUT = "/tmp/claude-0/plansekil"; os.makedirs(OUT, exist_ok=True)
def q(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args) if args else cur.execute(sql)
        if cur.description:
            r = cur.fetchall(); return (r[0] if r else None) if one else r
q("delete from public.class_plan_items where topic_id in (select id from public.topics where slug like 'sk-%'); delete from public.topics where slug like 'sk-%';")
T = int(time.time()*1000)
riy = q("select id from public.subjects where slug='riyaziyyat'", one=True)["id"]
lev = q("select id from public.levels where code='9'", one=True)
lev = lev["id"] if lev else q("select id from public.levels where code='3'", one=True)["id"]
fesiller = [("Kvadrat tənliklər", ["Tam kvadrat ayırmaqla həll", "Diskriminant düsturu",
                                   "Viet teoremi", "Tənliyə gətirilən məsələlər"]),
            ("Ədədi ardıcıllıqlar", ["Ardıcıllıq anlayışı", "Arifmetik silsilə",
                                     "Həndəsi silsilə"])]
tree = []
for fi, (fn, alt) in enumerate(fesiller):
    f = q("insert into public.topics (subject_id,level_id,parent_id,name,slug,sort)"
          " values (%s,%s,null,%s,%s,%s) returning id",
          (riy, lev, fn, "sk-f%d" % fi, 800+fi*10), one=True)["id"]
    ids = []
    for ai, an in enumerate(alt):
        ids.append(q("insert into public.topics (subject_id,level_id,parent_id,name,slug,sort)"
                     " values (%s,%s,%s,%s,%s,%s) returning id",
                     (riy, lev, f, an, "sk-f%da%d" % (fi, ai), 801+fi*10+ai), one=True)["id"])
    tree.append(ids)
with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    for ad, vp in (("masaustu", {"width": 1280, "height": 1000}),
                   ("telefon",  {"width": 390, "height": 844})):
        ctx = br.new_context(viewport=vp, device_scale_factor=2)
        p = ctx.new_page()
        p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
        mail = "sk%s%d@t.az" % (ad[:2], T)
        p.goto(PANEL + "?yeni=1"); p.wait_for_selector("#email", timeout=30000)
        p.click("#btnSwap"); p.fill("#fname", "Qızbəst müəllim"); p.fill("#email", mail)
        p.fill("#pass", "parol1234"); p.click("#btnAuth")
        p.wait_for_selector("#btnSetup", timeout=30000)
        p.fill("#aname", "Qızbəst müəllim — riyaziyyat"); p.click("#btnSetup")
        p.wait_for_selector("#yMenu .mrow", timeout=30000)
        acc = q("select a.id acc, a.owner_id own from public.accounts a join auth.users u"
                " on u.id=a.owner_id where u.email=%s", (mail,), one=True)
        q("insert into public.subscriptions (account_id, plan_id, status, started_at, current_period_end)"
          " select %s, pl.id, 'active', now()-interval '5 days', now()+interval '25 days'"
          " from public.plans pl where pl.slug='repetitor-60'", (acc["acc"],))
        gid = q("insert into public.classes (account_id,teacher_id,kind,name,join_code,level_id)"
                " values (%s,%s,'tutor_group','9-cu sinif',%s,%s) returning id",
                (acc["acc"], acc["own"], "SK" + ad[:1].upper() + str(T)[-5:], lev), one=True)["id"]
        pid = q("insert into public.class_plans (class_id,subject_id,level_id) values (%s,%s,%s) returning id",
                (gid, riy, lev), one=True)["id"]
        o = 0
        for ids in tree:
            for tid in ids:
                o += 1
                q("insert into public.class_plan_items (plan_id,topic_id,ord,done_at)"
                  " values (%s,%s,%s, case when %s then now() - make_interval(days => %s) end)",
                  (pid, tid, o, o <= 5, 12 - o))
        p.goto(PANEL + "?yeni=1#/g/" + str(gid) + "/p"); p.reload()
        p.wait_for_selector(".card.plan", timeout=30000)
        p.evaluate("document.querySelectorAll('.card.plan details').forEach(function(d){d.open=true})")
        p.wait_for_timeout(900)
        p.screenshot(path=OUT + "/" + ad + ".png", full_page=True)
        print(ad, "cekildi")
        ctx.close()
    br.close()
print("hazir")
