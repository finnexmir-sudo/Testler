#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sualin sekli DORD yerde (db/900 + 906): vereq, cap, sagird neticesi, muellimin cehd vereqi.

Sekil GORUNMEYEN axindir: metn onsuz da cixir, RPC sahəni vermese xeta yox, sekil sadece yoxa cixir
(900-de bu uc defe baş verib).  Ona gore HER yer ayri yoxlanir, 390 ve 1280 px-de:
  1  muellimin kagiz vereqi                 (rpc_test_preview)
  2  cap (Çap / PDF) - #printBox            (rpc_test_preview, @media print)
  3  sagirdin neticesi: TEZE bitirende      (rpc_submit_attempt)
  4  sagirdin neticesi: SONRADAN acanda     (rpc_test_result)
  5  muellimin cehd vereqi                  (rpc_attempt_sheet, db/906)
Sekil <img> kimi cizilir (SVG innerHTML-e dusmur) ve qirmis deyil."""
import os, sys, time
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

ROOT = "http://127.0.0.1:8010/"
PANEL = ROOT + "muellim/index.html?yeni=1"
STUDENT = ROOT + "sagird/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
OUT = "/tmp/claude-0/sekilnetice"; os.makedirs(OUT, exist_ok=True)
BLOCK = "**://*.supabase.co/**"
CFG = """window.CFG = {SUPABASE_URL:"http://127.0.0.1:54321", SUPABASE_ANON_KEY:"test-anon-key",
  STUDENT_URL:"http://127.0.0.1:8010/sagird/", PARENT_URL:"http://127.0.0.1:8010/valideyn/", SHOW_PLANS:false};"""
SVG = ('<svg viewBox="0 0 200 130"><path d="M20 110 L180 110 L60 20 Z" fill="none" stroke="#1a2233" stroke-width="3"/>'
       '<text x="24" y="104" font-family="sans-serif" font-size="14">A</text></svg>')

fails = []
def ok(cond, label, extra=""):
    print(("  OK   " if cond else "  FAIL ") + label + (("  " + str(extra)) if extra != "" else ""), flush=True)
    if not cond: fails.append(label)

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            return cur.fetchone() if one else cur.fetchall()

db("""
delete from public.question_reports; delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments; delete from public.student_sessions; delete from public.students; delete from public.classes;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.question_options o using public.questions q where q.id = o.question_id and q.owner_type = 'educator';
delete from public.questions where owner_type = 'educator';
delete from public.subscriptions; delete from public.account_members; delete from public.accounts;
delete from public.user_roles; delete from public.profiles; delete from auth.users;""")
db("update public.app_state set val = '{\"on\": false}' where key = 'hesab_bagli'")

#  sekilli suallar: riy-3-vurma-1 testinin ilk 3 sualina sekil
QIDS = [r["i"] for r in db("""select q.id::text i from public.questions q
          join public.test_questions tq on tq.question_id = q.id
          join public.tests t on t.id = tq.test_id and t.slug = 'riy-3-vurma-1' order by tq.ord limit 3""")]
db("update public.questions set media_url = app.svg_uri(%s) where id = any(%s::uuid[])", (SVG, QIDS))
NQ = len(QIDS)

def page(ctx):
    p = ctx.new_page()
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    p.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    p.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))
    return p

def sekil_var(p, sel, ad, minn=1, maxw=None):
    n = p.locator(sel + " .qfig img").count()
    ok(n >= minn, "%s: şəkil var" % ad, n)
    if n:
        ok(p.evaluate("(s) => { const i = document.querySelector(s + ' .qfig img'); return !!i && i.naturalWidth > 0; }", sel),
           "%s: şəkil qırıq deyil" % ad)
        ok(p.evaluate("(s) => document.querySelectorAll(s + ' .qfig svg').length", sel) == 0, "%s: yalnız <img> (SVG innerHTML-ə düşmür)" % ad)
        if maxw:
            bb = p.locator(sel + " .qfig img").first.bounding_box()
            ok(bb and bb["x"] >= 0 and bb["x"] + bb["width"] <= maxw + 1, "%s: ekrandan aşmır" % ad, bb and round(bb["width"]))
    if maxw:
        ok(p.evaluate("document.documentElement.scrollWidth <= window.innerWidth"), "%s: yana sürüşmə yoxdur" % ad)

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 1280, "height": 900})
    pg = page(ctx)

    print("Hazırlıq: müəllim, qrup, şagird, şəkilli test, tapşırıq")
    pg.goto(PANEL); pg.wait_for_selector("#btnAuth", timeout=20000); pg.click("#btnSwap")
    pg.fill("#fname", "Sekil Muellim"); pg.fill("#email", "sekilnetice@t.az"); pg.fill("#pass", "sekilparol1"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=20000)
    pg.select_option("#atype", "tutor"); pg.fill("#aname", "Sekil hesabi"); pg.click("#btnSetup")
    pg.wait_for_selector("#adminMsg", state="attached", timeout=30000)
    acc = db("select a.id::text i, a.owner_id::text o from public.accounts a limit 1", one=True)
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select %s::uuid, p.id, 'trialing', now() + interval '30 days' from public.plans p where p.slug = 'repetitor-25'""", (acc["i"],))
    lev = db("select l.id::text i from public.levels l join public.programs p on p.id = l.program_id where p.slug='ibtidai' and l.code='3'", one=True)["i"]
    GID = db("""insert into public.classes (account_id, teacher_id, kind, name, join_code, level_id)
                values (%s::uuid, %s::uuid, 'tutor_group', '3-cü sinif', 'SKN00001', %s::uuid) returning id::text i""", (acc["i"], acc["o"], lev), one=True)["i"]
    SID = db("""insert into public.students (account_id, class_id, created_by, full_name, display_name, login_code)
                values (%s::uuid, %s::uuid, %s::uuid, 'Aysu Məmmədova', 'Aysu M.', 'SEKILNET') returning id::text i""", (acc["i"], GID, acc["o"]), one=True)["i"]
    TID = db("""insert into public.tests (owner_type, owner_id, title, program_id, subject_id, pass_percent, is_free, status)
                select 'educator', %s::uuid, 'Şəkilli test', p.id, qq.subject_id, 50, false, 'published'
                  from public.questions qq, public.programs p where qq.id = %s::uuid limit 1 returning id::text i""", (acc["o"], QIDS[0]), one=True)["i"]
    for i, q in enumerate(QIDS):
        db("insert into public.test_questions (test_id, question_id, ord) values (%s::uuid, %s::uuid, %s)", (TID, q, i + 1))
    db("insert into public.assignments (class_id, test_id, assigned_by) values (%s::uuid, %s::uuid, %s::uuid)", (GID, TID, acc["o"]))

    # --------------------------------------------------- sagird: testi isleyir, neticeler
    print("\n3 · Şagird: testi bitirir — NƏTİCƏ ekranı (təzə, rpc_submit_attempt)")
    sp = page(ctx); sp.set_viewport_size({"width": 390, "height": 844})
    sp.goto(STUDENT); sp.wait_for_selector("#btnIn", timeout=15000)
    sp.fill("#code", "SEKILNET"); sp.click("#btnIn"); sp.wait_for_selector(".test", timeout=15000)
    sp.locator(".test", has_text="Şəkilli test").first.click(); sp.wait_for_selector(".opt", timeout=15000)
    for i in range(NQ):
        ids = sp.locator(".opt").evaluate_all("els => els.map(e => e.getAttribute('data-o'))")
        sp.locator("[data-o='%s']" % ids[0]).click(); sp.wait_for_timeout(120)
        if i + 1 < NQ: sp.click("#btnNext")
        else: sp.click("#btnFinish")
        sp.wait_for_timeout(300)
    sp.wait_for_selector(".ring", timeout=15000); sp.wait_for_timeout(600)
    sekil_var(sp, "#main", "təzə nəticə (390 px)", minn=1, maxw=390)
    sp.screenshot(path=OUT + "/3-netice-teze-390.png", full_page=True)

    print("\n4 · Şagird: nəticəyə SONRADAN baxır (rpc_test_result)")
    sp.click("#btnHome"); sp.wait_for_selector(".test", timeout=15000)
    sp2 = page(ctx); sp2.set_viewport_size({"width": 390, "height": 844})
    sp2.goto(STUDENT); sp2.wait_for_selector(".test", timeout=15000)
    sp2.locator(".test", has_text="Şəkilli test").first.click(); sp2.wait_for_selector(".ring", timeout=15000); sp2.wait_for_timeout(600)
    sekil_var(sp2, "#main", "sonradan açılan nəticə (390 px)", minn=1, maxw=390)
    sp2.screenshot(path=OUT + "/4-netice-sonradan-390.png", full_page=True)
    sp2.set_viewport_size({"width": 1280, "height": 900}); sp2.wait_for_timeout(300)
    sekil_var(sp2, "#main", "sonradan açılan nəticə (1280 px)", minn=1, maxw=1280)
    sp2.screenshot(path=OUT + "/4-netice-sonradan-1280.png", full_page=True)

    # --------------------------------------------------- muellim: vereq, cap, cehd vereqi (iki en)
    for W, H in ((1280, 900), (390, 844)):
        ctx_t = br.new_context(viewport={"width": W, "height": H})
        tp = page(ctx_t)
        tp.goto(PANEL); tp.wait_for_selector("#btnAuth", timeout=20000)
        tp.fill("#email", "sekilnetice@t.az"); tp.fill("#pass", "sekilparol1"); tp.click("#btnAuth")
        tp.wait_for_selector("#adminMsg, #yMenu .mrow", state="attached", timeout=30000)

        print("\n1 · Müəllimin kağız vərəqi (%d px)" % W)
        tp.goto(PANEL + "#/t/" + TID); tp.wait_for_selector(".paper", state="attached", timeout=20000); tp.evaluate("var f=document.getElementById('qFold'); if(f) f.open=true"); tp.wait_for_timeout(500)
        sekil_var(tp, ".paper", "vərəq (%d px)" % W, minn=NQ, maxw=W)
        tp.screenshot(path=OUT + "/1-vereq-%d.png" % W, full_page=True)

        print("\n2 · Çap / PDF (%d px)" % W)
        tp.evaluate("window.print = function () { window.__cap = true; }")
        tp.click("#btnPrn"); tp.wait_for_timeout(500)
        ok(tp.evaluate("window.__cap === true"), "çap çağırıldı")
        sekil_var(tp, "#printBox", "çap (%d px)" % W, minn=NQ)
        tp.emulate_media(media="print"); tp.wait_for_timeout(300)
        vis = tp.evaluate("(() => { const i = document.querySelector('#printBox .qfig img'); if (!i) return 0; const r = i.getBoundingClientRect(); return r.width * r.height; })()")
        ok(vis > 0, "çap görünüşündə şəkil yer tutur (@media print)", round(vis))
        tp.screenshot(path=OUT + "/2-cap-%d.png" % W, full_page=True)
        tp.emulate_media(media="screen")

        print("\n5 · Müəllimin cəhd vərəqi (%d px)" % W)
        tp.goto(PANEL + "#/s/" + SID + "/" + GID); tp.wait_for_selector("#sTabs", timeout=20000)
        tp.locator("#sTabs [data-v='t']").click(); tp.wait_for_selector(".atr", timeout=15000)
        tp.locator(".atr").first.click(); tp.wait_for_selector(".sheet:not(.hide) .shq", timeout=15000); tp.wait_for_timeout(500)
        sekil_var(tp, ".sheet:not(.hide)", "cəhd vərəqi (%d px)" % W, minn=NQ, maxw=W)
        tp.screenshot(path=OUT + "/5-cehd-vereqi-%d.png" % W, full_page=True)
        ctx_t.close()
    br.close()

db("update public.questions set media_url = null where media_url is not null and id = any(%s::uuid[])", (QIDS,))
print("\n" + ("HAMISI KECDI" if not fails else "XETA (%d): %s" % (len(fails), " | ".join(fails))))
sys.exit(1 if fails else 0)
