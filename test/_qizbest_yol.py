#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ONBAXIS: «Testi gondermek olmur» - muellimin yolunu ADDIM-ADDIM gedirik.

Sikayet (Qizbest muellime, 25.09, ekran: Icmal, uc defe):
    «Testi gondermek olmur. Niye?»
Cavab yazmazdan evvel EYNI yolu ozumuz gedirik ve her addimin sekli
cekilir.  Hec bir seyi qabaqcadan dogru saymiriq.

    test/tek.sh _qizbest_yol.py   ->  /tmp/claude-0/yol/
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
OUT = "/tmp/claude-0/yol"; os.makedirs(OUT, exist_ok=True)

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            return cur.fetchone() if one else cur.fetchall()

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

T = int(time.time())
MAIL = "yol%d@t.az" % T
say = lambda s: print("\n" + s, flush=True)

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 1280, "height": 1000})
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=CFG))
    pg.on("pageerror", lambda e: print("   !! JS XETASI: " + str(e), flush=True))
    #  «Hec ne olmur» halini tutmaq ucun: her klikden sonra unvan ve
    #  ekranin basligi yazilir.  Duyme olu ise ikisi de deyismir.
    def hara(etiket):
        h = pg.evaluate("() => location.hash")
        t = pg.evaluate("() => { const e = document.querySelector('.band b, h1, .eye');"
                        "         return e ? e.innerText.trim().slice(0,40) : ''; }")
        print("   %-28s hash=%-22s ekran=%s" % (etiket, h or "(bos)", t), flush=True)
        return h

    say("1 · Qeydiyyat")
    pg.goto(PANEL); pg.wait_for_timeout(600)
    pg.click("#btnSwap")
    pg.fill("#fname", "Qızbəst sınaq"); pg.fill("#email", MAIL)
    pg.fill("#pass", "yolparol123"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=20000)
    pg.select_option("#atype", "tutor"); pg.fill("#aname", "Qızbəst müəllim-riyaziyyat")
    pg.click("#btnSetup"); pg.wait_for_selector("#gForm", timeout=20000)
    pg.screenshot(path=OUT + "/01_ilk_ekran.png", full_page=True)
    print("   ilk ekran cekildi")

    uid = db("select id::text i from auth.users where email=%s", (MAIL,), one=True)["i"]
    acc = db("select id::text i from public.accounts where owner_id=%s::uuid", (uid,), one=True)["i"]

    say("2 · Üç addım kartı — 1-ci addım (test yığ)")
    pg.goto(PANEL + "#/"); pg.wait_for_timeout(1500)
    n = pg.locator(".onb .ost").count()
    print("   kartda addim sayi:", n)
    if n:
        for i in range(n):
            o = pg.locator(".onb .ost").nth(i)
            print("   addim %d [%s] %s" % (i + 1, o.get_attribute("class"),
                                           o.inner_text().replace("\n", " · ")[:90]))
    pg.screenshot(path=OUT + "/02_uc_addim.png", full_page=True)

    say("3 · Test yığılır (generatorla)")
    tid = db("""insert into public.tests (owner_type, owner_id, program_id, subject_id, level_id,
                                          slug, title, status, pass_percent)
                select 'educator', %s::uuid, p.id, s.id, l.id,
                       'yol-test-%s', 'Vurma sınağı', 'published', 50
                  from public.programs p, public.subjects s, public.levels l
                 where p.slug='ibtidai' and s.slug='riyaziyyat' and l.code='3'
                 limit 1
                returning id::text i""", (uid, T), one=True)["i"]
    db("""insert into public.test_questions (test_id, question_id, ord)
          select %s::uuid, q.id, row_number() over ()
            from public.questions q
            join public.subjects s on s.id = q.subject_id and s.slug='riyaziyyat'
           where q.owner_type='platform' and q.status='published' limit 5""", (tid,))
    print("   test bazada quruldu (generator ekranini kecirik)")

    say("4 · Qrup + şagirdlər")
    cls = db("""insert into public.classes (account_id, teacher_id, kind, name, join_code, level_id)
                select %s::uuid, %s::uuid, 'tutor_group', '3-cü sinif', 'YOLKOD01', l.id
                  from public.levels l where l.code='3'
                returning id::text i""", (acc, uid), one=True)["i"]
    for ad, kod in (("Aysel Məmmədova", "YOLS0001"), ("Murad Əliyev", "YOLS0002")):
        db("""insert into public.students (account_id, class_id, created_by, full_name,
                                           display_name, login_code)
              values (%s::uuid, %s::uuid, %s::uuid, %s, %s, %s)""",
           (acc, cls, uid, ad, ad.split()[0] + " " + ad.split()[1][0] + ".", kod))
    print("   qrup + 2 şagird quruldu")

    say("5 · İcmala qayıdırıq — 3-cü addım necə görünür?")
    pg.goto(PANEL + "#/"); pg.reload(); pg.wait_for_timeout(2500)
    n = pg.locator(".onb .ost").count()
    print("   kartda addim sayi:", n)
    for i in range(n):
        o = pg.locator(".onb .ost").nth(i)
        print("   addim %d [%s] %s" % (i + 1, o.get_attribute("class"),
                                       o.inner_text().replace("\n", " · ")[:100]))
    var3 = pg.locator("#onbAsg").count()
    print("   «Testi qrupa ver» duymesi var?", "BELI" if var3 else "YOX")
    pg.screenshot(path=OUT + "/03_ucuncu_addim.png", full_page=True)

    say("6 · «Testi qrupa ver» basılır — nə olur?")
    h0 = hara("klikden EVVEL")
    if var3:
        pg.click("#onbAsg"); pg.wait_for_timeout(2000)
        h1 = hara("klikden SONRA")
        print("   NETICE:", "ekran deyisdi" if h1 != h0 else "!!! HEC NE OLMADI")
        pg.screenshot(path=OUT + "/04_tapsiriq_ekrani.png", full_page=True)
    else:
        print("   !!! duyme yoxdur - muellim burada dayanir")

    say("7 · Tapşırıq ekranı: test siyahıda görünürmü?")
    pg.goto(PANEL + "#/a/" + cls); pg.wait_for_timeout(2500)
    hara("tapsiriq ekrani")
    nt = pg.locator("#aList [data-t]").count()
    print("   siyahida test sayi:", nt)
    if nt:
        print("   siyahi:", " | ".join(x.replace("\n", " ")[:40]
                                       for x in pg.locator("#aList [data-t]").all_inner_texts()))
    else:
        print("   ekranda ne yazir:", pg.inner_text("#main").replace("\n", " · ")[:220])
    pg.screenshot(path=OUT + "/05_tapsiriq_siyahi.png", full_page=True)

    say("8 · Testi seçib «Tapşırıq ver» basılır")
    if nt:
        pg.locator("#aList [data-t]").first.click(); pg.wait_for_timeout(400)
        pg.click("#btnAsg"); pg.wait_for_timeout(2500)
        hara("tapsiriqdan sonra")
        say_n = db("select count(*) n from public.assignments where assigned_by=%s::uuid",
                   (uid,), one=True)["n"]
        print("   bazada tapsiriq sayi:", say_n)
        print("   NETICE:", "ISLEDI" if say_n else "!!! BAZAYA HEC NE YAZILMADI")
        pg.screenshot(path=OUT + "/06_verildi.png", full_page=True)

    say("9 · «göndər» sözü ekranlarda hardadır?")
    for yer, url in (("İcmal", "#/"), ("Qruplar", "#/g/" + cls), ("Tapşırıq", "#/a/" + cls)):
        pg.goto(PANEL + url); pg.wait_for_timeout(2000)
        t = pg.inner_text("#main")
        g = [l.strip() for l in t.split("\n") if "öndər" in l]
        b = [l.strip() for l in t.split("\n") if "apşır" in l]
        print("   %-9s «göndər»: %-42s «tapşır»: %s"
              % (yer, (g[0][:40] if g else "-"), (b[0][:40] if b else "-")))

    say("10 · Telefonda 3-cü addım")
    mctx = br.new_context(viewport={"width": 390, "height": 844})
    m = mctx.new_page()
    m.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=CFG))
    m.goto(PANEL); m.wait_for_timeout(700)
    m.fill("#email", MAIL); m.fill("#pass", "yolparol123"); m.click("#btnAuth")
    m.wait_for_timeout(3000)
    m.goto(PANEL + "#/g/" + cls); m.wait_for_timeout(2000)
    m.screenshot(path=OUT + "/07_qrup_telefon.png", full_page=True)
    print("   qrup ekrani (telefon) cekildi")
    br.close()

print("\nşəkillər: " + OUT)
