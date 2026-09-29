#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ONBAXIS: qrupa test yigmaq - YENI (standart) ve KOHNE gorunusde (29.09).

Istifadeci uc problem gordu:
  1. Qrupa test yigdim, sonraki sehife qarisiq geldi
  2. Testin qrupa verildiyi deqiq bilinmir
  3. Test yig etdim ama teyin ede bilmedim

Evvel TEKRAR EDIRIK, sonra duzeldirik.  Her merhelede unvan, ekranin
metni ve sekil yazilir.   test/tek.sh _yeni_qrup_yol.py -> /tmp/claude-0/yeniyol/
"""
import os, sys, time
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

ROOT = "http://127.0.0.1:8010/"
PANEL = ROOT + "muellim/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
CFG = """window.CFG = {SUPABASE_URL:"http://127.0.0.1:54321",
  SUPABASE_ANON_KEY:"test-anon-key", STUDENT_URL:"http://127.0.0.1:8010/sagird/",
  SHOW_PLANS:false};"""
OUT = "/tmp/claude-0/yeniyol"; os.makedirs(OUT, exist_ok=True)

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            r = cur.fetchall(); return (r[0] if r else None) if one else r

db("""
delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers;  delete from public.attempts;
delete from public.assignments;      delete from public.student_sessions;
delete from public.students;         delete from public.classes;
delete from public.test_questions tq using public.tests t
 where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.subscriptions;
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from auth.users;
""")

T = int(time.time()); MAIL = "yq%d@t.az" % T
def say(s): print("\n" + s, flush=True)

def ekran(pg, ad, uzun=260):
    h = pg.evaluate("() => location.hash") or "(bos)"
    t = pg.inner_text("#main").replace("\n", " · ")
    print("   [%s] hash=%s" % (ad, h)); print("      " + t[:uzun], flush=True)

def context(br, w, h, kohne):
    ctx = br.new_context(viewport={"width": w, "height": h})
    if kohne:
        ctx.add_init_script("try{localStorage.setItem('bil10_yeni','0')}catch(e){}")
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=CFG))
    pg.on("pageerror", lambda e: print("   !! JS XETASI:", str(e)[:160], flush=True))
    return ctx, pg

def daxil(pg):
    pg.goto(PANEL); pg.wait_for_timeout(700)
    pg.fill("#email", MAIL); pg.fill("#pass", "yqparol123"); pg.click("#btnAuth")
    pg.wait_for_timeout(3000)

def gen_doldur(pg, ad, qrup_id=None):
    pg.goto(PANEL + "#/gen"); pg.reload()
    pg.wait_for_selector("#gsub", timeout=20000); pg.wait_for_timeout(500)
    pg.select_option("#gsub", "riyaziyyat"); pg.wait_for_timeout(500)
    pg.wait_for_selector("#gLevs", timeout=10000)
    while pg.locator("#gLevs .chip.on").count():
        pg.locator("#gLevs .chip.on").first.click(); pg.wait_for_timeout(200)
    pg.locator('#gLevs [data-l="6"]').click(); pg.wait_for_timeout(500)
    pg.fill("#gCnt", "10"); pg.fill("#gTitle", ad)
    if qrup_id:
        pg.wait_for_function("document.querySelectorAll('#gAsg option').length > 1", timeout=10000)
        pg.select_option("#gAsg", qrup_id)
    pg.wait_for_function(
        "document.querySelector('#gPrev') && document.querySelector('#gPrev').innerText.indexOf('yoxlanılır') < 0 "
        "&& document.querySelector('#gPrev').innerText.length > 5", timeout=15000)
    print("   onizleme:", pg.inner_text("#gPrev").replace("\n", " ")[:110])

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])

    # ---- hazirliq: hesab, abune, iki qrup ----
    ctx0, pg0 = context(br, 1280, 1000, False)
    say("0 · Hazırlıq")
    pg0.goto(PANEL); pg0.wait_for_timeout(600)
    pg0.click("#btnSwap")
    pg0.fill("#fname", "Yeni Yol"); pg0.fill("#email", MAIL)
    pg0.fill("#pass", "yqparol123"); pg0.click("#btnAuth")
    pg0.wait_for_selector("#btnSetup", timeout=20000)
    pg0.select_option("#atype", "tutor"); pg0.fill("#aname", "Yol hesabi")
    pg0.click("#btnSetup"); pg0.wait_for_timeout(4500)   # yeni gorunusde #gForm ana sehifede yoxdur
    uid = db("select id::text i from auth.users where email=%s", (MAIL,), one=True)["i"]
    acc = db("select id::text i from public.accounts where owner_id=%s::uuid", (uid,), one=True)["i"]
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select %s::uuid, p.id, 'active', now() + interval '30 days'
            from public.plans p where p.slug = 'repetitor-25'""", (acc,))
    G6 = db("""insert into public.classes (account_id, teacher_id, kind, name, join_code, level_id)
               select %s::uuid, %s::uuid, 'tutor_group', 'Ev qrup', 'YQKOD006', l.id
                 from public.levels l where l.code='6' returning id::text i""", (acc, uid), one=True)["i"]
    G3 = db("""insert into public.classes (account_id, teacher_id, kind, name, join_code, level_id)
               select %s::uuid, %s::uuid, 'tutor_group', 'Kiçik qrup', 'YQKOD003', l.id
                 from public.levels l where l.code='3' returning id::text i""", (acc, uid), one=True)["i"]
    for c, pref in ((G6, "A"), (G3, "B")):
        for i in range(3):
            db("""insert into public.students (account_id, class_id, created_by, full_name,
                                               display_name, login_code)
                  values (%s::uuid, %s::uuid, %s::uuid, %s, %s, %s)""",
               (acc, c, uid, "Şagird %s%d Test" % (pref, i + 1), "Şagird %s%d" % (pref, i + 1),
                "YQS%s%d%d" % (pref, i, T % 100)))
    print("   hesab, abunə, 2 qrup (6-cı və 3-cü sinif), 6 şagird hazır")
    ctx0.close()

    for kohne in (False, True):
        AD = "kohne" if kohne else "yeni"
        say("=" * 60 + "\n%s GÖRÜNÜŞ (%s)" % (AD.upper(), "standart deyil" if kohne else "STANDART indi"))

        for (w, h, tel) in ((1280, 1000, "masaustu"), (390, 844, "telefon")):
            ctx, pg = context(br, w, h, kohne)
            daxil(pg)
            say("S1 · Generator + qrup seçilib → «Testi yığ»   [%s · %s]" % (AD, tel))
            gen_doldur(pg, "S1 %s %s" % (AD, tel), G6)
            pg.click("#btnMake"); pg.wait_for_timeout(3500)
            ekran(pg, "yigandan sonra", 330)
            pg.screenshot(path="%s/S1_%s_%s.png" % (OUT, AD, tel), full_page=True)
            n = db("select count(*) n from public.assignments a join public.tests t on t.id=a.test_id "
                   "where t.title like %s", ("S1 %s %s%%" % (AD, tel),), one=True)["n"]
            print("   bazada tapsiriq:", n)

            say("S2 · Generator, qrup SEÇİLMƏYİB → veraq → orada təyin   [%s · %s]" % (AD, tel))
            gen_doldur(pg, "S2 %s %s" % (AD, tel))
            pg.click("#btnMake"); pg.wait_for_timeout(3500)
            ekran(pg, "veraq", 300)
            pg.screenshot(path="%s/S2_%s_%s_veraq.png" % (OUT, AD, tel), full_page=True)
            var = pg.locator("#btnPAsg").count()
            print("   «Tapşırıq ver» düyməsi var?", "BƏLİ" if var else "YOX")
            if var:
                pg.locator("#pCls").select_option(G6); pg.wait_for_timeout(200)
                pg.click("#btnPAsg"); pg.wait_for_timeout(3000)
                ekran(pg, "təyin edəndən sonra", 330)
                pg.screenshot(path="%s/S2_%s_%s_sonra.png" % (OUT, AD, tel), full_page=True)
            ctx.close()

        ctx, pg = context(br, 390, 844, kohne)
        daxil(pg)
        say("S3 · Tapşırıq ekranı → «Yeni test yığ» → generator → geri   [%s · telefon]" % AD)
        pg.goto(PANEL + "#/a/" + G3); pg.wait_for_timeout(3000)
        ekran(pg, "tapşırıq ekranı (Kiçik qrup, 3-cü sinif)", 200)
        if pg.locator("#btnGenHere").count():
            pg.click("#btnGenHere"); pg.wait_for_timeout(2500)
            ekran(pg, "generator", 160)
            #  Generator qrupun sinfini (3) qabaqcadan secirse ona toxunmuruq;
            #  yoxsa 6-ci sinif secilir - muellimin real davranisi
            try:
                pg.wait_for_selector("#gsub", timeout=10000)
                if pg.locator("#gLevs .chip.on").count() == 0:
                    pg.select_option("#gsub", "riyaziyyat"); pg.wait_for_timeout(500)
                    pg.locator('#gLevs [data-l="6"]').click(); pg.wait_for_timeout(400)
                print("   sinif seçimi:", pg.locator("#gLevs .chip.on").all_inner_texts())
                pg.fill("#gTitle", "S3 %s" % AD)
                pg.wait_for_function(
                    "document.querySelector('#gPrev') && document.querySelector('#gPrev').innerText.indexOf('yoxlanılır') < 0 "
                    "&& document.querySelector('#gPrev').innerText.length > 5", timeout=15000)
                print("   onizleme:", pg.inner_text("#gPrev").replace("\n", " ")[:110])
                pg.click("#btnMake"); pg.wait_for_timeout(3500)
                ekran(pg, "geri qayıtdıq", 380)
                pg.screenshot(path="%s/S3_%s_telefon.png" % (OUT, AD), full_page=True)
                print("   «Tapşırıq ver» düyməsi var?", "BƏLİ" if pg.locator("#btnAsg").count() else "YOX")
            except Exception as e:
                print("   !! generatorda dayandı:", str(e)[:120])
        else:
            print("   !! «Yeni test yığ» düyməsi yoxdur")
        ctx.close()
    br.close()
print("\nşəkillər:", OUT)
