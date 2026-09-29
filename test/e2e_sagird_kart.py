#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Şagirdin hesab kartı — yeni görünüşdə itən əməliyyatlar (29.09).

Yeni gorunusde sagird siyahisi ad + netice + ox idi; kod, valideyn
giris, ad deyismek, kod yenilemek, dayandirmaq YOX idi (test/
_yeni_kohne_ferq.py).  Siyahida yazilirdi «hele girmeyib - kodu
gonderin», gondermek ucun duyme yox idi.  Bunlar sagird sehifesinde
BIR KART kimi qaytarildi.

Her duyme HEQIQETEN basilir, netice BAZADA yoxlanilir.

Yoxlanir:
  A  siyahida «hele girmeyib» sagirdin setri kartli sehifeye aparir; kart ACIQDIR
  B  giris/valideyn kodu duzgun gorunur; kopyala buferi doldurur
  C  «WhatsApp-la gonder» duzgun mesaj acir (kod + unvan)
  D  valideyn: bagla -> ac -> kodu yenile  (baza deyisir)
  E  ad deyismek: bos ad redd olunur; yeni ad bazada, basliqda
  F  giris kodunu yenile: kod deyisir, BASLIQ da yenilenir
  G  dayandir / davam etdir
  H  girmis sagirdin karti YIGILIB gelir
  I  kohne gorunusde kart YOXDUR (o deyismir)
  J  telefonda enden asmir
"""
import sys, time, urllib.parse
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

ROOT = "http://127.0.0.1:8010/"
PANEL = ROOT + "muellim/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
CFG = """window.CFG = {SUPABASE_URL:"http://127.0.0.1:54321",
  SUPABASE_ANON_KEY:"test-anon-key", STUDENT_URL:"http://127.0.0.1:8010/sagird/",
  PARENT_URL:"http://127.0.0.1:8010/valideyn/", SHOW_PLANS:false};"""

fails = []
def ok(cond, label, extra=""):
    print(("  OK   " if cond else "  FAIL ") + label + (("  " + str(extra)) if extra else ""), flush=True)
    if not cond: fails.append(label)

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            r = cur.fetchall(); return (r[0] if r else None) if one else r

db("""
delete from public.homework; delete from public.class_plan_items; delete from public.class_plans;
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
T = int(time.time()); MAIL = "sk%d@t.az" % T

def row(sid): return db("select * from public.students where id=%s::uuid", (sid,), one=True)

def context(br, w, h, kohne=False):
    ctx = br.new_context(viewport={"width": w, "height": h})
    ctx.grant_permissions(["clipboard-read", "clipboard-write"], origin="http://127.0.0.1:8010")
    #  xarici unvan: wa.me hec vaxt heqiqeten acilmasin
    ctx.route("https://wa.me/**", lambda r: r.fulfill(status=200, content_type="text/html", body="ok"))
    if kohne:
        ctx.add_init_script("try{localStorage.setItem('bil10_yeni','0')}catch(e){}")
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)[:140]))
    pg.on("dialog", lambda d: d.accept())
    return ctx, pg

def daxil(pg):
    pg.goto(PANEL); pg.wait_for_timeout(700)
    pg.fill("#email", MAIL); pg.fill("#pass", "skparol123"); pg.click("#btnAuth")
    pg.wait_for_timeout(3000)

def sehife(pg, sid, gid):
    pg.goto(PANEL + "#/s/%s/%s" % (sid, gid)); pg.reload()
    pg.wait_for_selector("#stuKart .stkart", timeout=20000)

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])

    print("0 · Hazırlıq")
    c0, p0 = context(br, 1280, 1000)
    p0.goto(PANEL); p0.wait_for_timeout(600); p0.click("#btnSwap")
    p0.fill("#fname", "Kart Muellim"); p0.fill("#email", MAIL); p0.fill("#pass", "skparol123"); p0.click("#btnAuth")
    p0.wait_for_selector("#btnSetup", timeout=20000)
    p0.select_option("#atype", "tutor"); p0.fill("#aname", "Kart hesabi"); p0.click("#btnSetup"); p0.wait_for_timeout(4500)
    uid = db("select id::text i from auth.users where email=%s", (MAIL,), one=True)["i"]
    acc = db("select id::text i from public.accounts where owner_id=%s::uuid", (uid,), one=True)["i"]
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select %s::uuid, p.id, 'active', now() + interval '30 days' from public.plans p where p.slug='repetitor-25'""", (acc,))
    G = db("""insert into public.classes (account_id, teacher_id, kind, name, join_code, level_id)
              select %s::uuid, %s::uuid, 'tutor_group', 'Kart qrup', 'SKKOD001', l.id from public.levels l where l.code='6'
              returning id::text i""", (acc, uid), one=True)["i"]
    def stu(ad, kod, pkod):
        return db("""insert into public.students (account_id, class_id, created_by, full_name, display_name, login_code, parent_code)
                     values (%s::uuid, %s::uuid, %s::uuid, %s, %s, %s, %s) returning id::text i""",
                  (acc, G, uid, ad, ad.split()[0] + " " + ad.split()[1][0] + ".", kod, pkod), one=True)["i"]
    S0 = stu("Aysel Məmmədova", "SKA%05d" % (T % 100000), "SKP%05d" % (T % 100000))   # girmeyib, valideyn ACIQ
    S1 = stu("Murad Əliyev",    "SKB%05d" % (T % 100000), None)                        # girib, valideyn YOX
    S2 = stu("Leyla Hüseynova", "SKC%05d" % (T % 100000), None)                        # dayandirma ucun
    tid = db("""insert into public.tests (owner_type, owner_id, program_id, subject_id, level_id, slug, title, status, pass_percent)
                select 'educator', %s::uuid, p.id, s.id, l.id, 'sk-%s', 'Sınaq', 'published', 50
                  from public.programs p, public.subjects s, public.levels l
                 where p.slug='orta' and s.slug='riyaziyyat' and l.code='6' limit 1 returning id::text i""", (uid, T), one=True)["i"]
    db("""insert into public.test_questions (test_id, question_id, ord)
          select %s::uuid, q.id, row_number() over () from public.questions q join public.subjects s on s.id=q.subject_id
           where s.slug='riyaziyyat' and q.owner_type='platform' and q.status='published' limit 4""", (tid,))
    att = db("""insert into public.attempts (student_id, test_id, class_id, status, started_at, finished_at, score, max_score, percent)
                values (%s::uuid, %s::uuid, %s::uuid, 'submitted', now() - interval '2 hours', now() - interval '1 hour', 2, 4, 50)
                returning id::text i""", (S1, tid, G), one=True)["i"]
    db("""insert into public.attempt_answers (attempt_id, question_id, topic_id, is_correct, points, question_body)
          select %s::uuid, q.id, q.topic_id, (row_number() over ()) %% 2 = 0, 1, q.body
            from public.questions q join public.test_questions tq on tq.question_id=q.id where tq.test_id=%s::uuid""", (att, tid))
    print("   qrup, 3 şagird: biri girməyib (valideyn açıq), biri girib, biri dayandırma üçün")
    c0.close()

    ctx, pg = context(br, 1280, 1000)
    daxil(pg)

    print("\nA · Siyahıdan şagird səhifəsinə")
    pg.goto(PANEL + "#/g/%s/s" % G); pg.reload(); pg.wait_for_timeout(3500)
    #  Iki sagird girmeyib (Aysel, Leyla) - Ayselin ozunu aciriq
    hint = pg.locator("a.mrow", has_text="Aysel Məmmədova")
    ok(hint.count() == 1 and "kodu göndərin" in hint.first.inner_text(),
       "siyahida «hele girmeyib - kodu gonderin» setri var", hint.first.inner_text().replace("\n", " · ")[:70])
    hint.first.click(); pg.wait_for_selector("#stuKart .stkart", timeout=20000)
    ok("/s/" + S0 in pg.evaluate("() => location.hash"), "setir sagird sehifesine aparir")
    ok(pg.locator("#stuKart details").first.get_attribute("open") is not None,
       "girmeyen sagirdin karti ACIQDIR (kodu gondermek lazimdir)")
    ok("hələ girməyib" in pg.inner_text("#stuKart summary"), "basliqda «hele girmeyib» yazilir")

    print("\nB · Kodlar və kopyalama")
    r0 = row(S0)
    chips = pg.locator("#stuKart .code").all_inner_texts()
    ok(r0["login_code"] in chips, "sagird kodu gorunur", chips)
    ok(r0["parent_code"] in chips, "valideyn kodu gorunur", chips)
    pg.click('#stuKart [data-sk="cp"]'); pg.wait_for_timeout(400)
    ok(pg.evaluate("navigator.clipboard.readText()") == r0["login_code"], "kopyala: sagird kodu buferdedir")
    #  «Kopyalandi» reyi 30 px-lik ikon duymesinin icinde cixir - sigirmi?
    pg.click('#stuKart [data-sk="cp"]'); pg.wait_for_timeout(200)
    pg.locator("#stuKart .stkart").screenshot(path="/tmp/claude-0/kart/kart_kopya_masaustu.png")
    bcp = pg.locator('#stuKart [data-sk="cp"]').evaluate(
        "e => ({sw: e.scrollWidth, cw: e.clientWidth, t: e.innerText})")
    ok(bcp["sw"] <= bcp["cw"] + 1, "«Kopyalandi» rəyi duymeden TASMIR", bcp)
    pg.click('#stuKart [data-sk="pcp"]'); pg.wait_for_timeout(400)
    ok(pg.evaluate("navigator.clipboard.readText()") == r0["parent_code"], "kopyala: valideyn kodu buferdedir")

    print("\nC · WhatsApp-la göndər")
    with ctx.expect_page() as pi:
        pg.click('#stuKart [data-sk="wa"]')
    w1 = pi.value; w1.wait_for_url("https://wa.me/**", timeout=8000)
    u1 = urllib.parse.unquote(w1.url)
    ok(r0["login_code"] in u1 and "Giriş kodu" in u1, "sagird mesajinda KOD var", u1[:60])
    ok("/sagird/" in u1, "sagird mesajinda SAGIRD unvani var")
    ok(r0["parent_code"] not in u1, "sagird mesajinda valideyn kodu YOXDUR (qarismir)")
    w1.close()
    with ctx.expect_page() as pi:
        pg.click('#stuKart [data-sk="pwa"]')
    w2 = pi.value; w2.wait_for_url("https://wa.me/**", timeout=8000)
    u2 = urllib.parse.unquote(w2.url)
    ok(r0["parent_code"] in u2 and "/valideyn/" in u2, "valideyn mesajinda valideyn kodu ve VALIDEYN unvani var")
    ok(r0["login_code"] not in u2, "valideyn mesajinda sagirdin kodu YOXDUR")
    w2.close()

    print("\nD · Valideyn girişi: bağla → aç → yenilə")
    pg.click('#stuKart [data-sk="poff"]'); pg.wait_for_timeout(2500)
    ok(row(S0)["parent_code"] is None, "baglandi - bazada valideyn kodu yoxdur")
    ok(pg.locator('#stuKart [data-sk="pon"]').count() == 1, "kart «Valideyn girisini ac» gosterir")
    pg.click('#stuKart [data-sk="pon"]'); pg.wait_for_timeout(2500)
    yeni_p = row(S0)["parent_code"]
    ok(bool(yeni_p), "acildi - yeni valideyn kodu yarandi", yeni_p)
    ok(yeni_p in pg.locator("#stuKart .code").all_inner_texts(), "kart yeni kodu gosterir")
    pg.click('#stuKart [data-sk="pnew"]'); pg.wait_for_timeout(2500)
    ok(row(S0)["parent_code"] not in (None, yeni_p), "kod yenilendi - kohne kod deyisdi", row(S0)["parent_code"])

    print("\nE · Adı dəyiş")
    pg.click('#stuKart [data-sk="ren"]'); pg.wait_for_selector("#skName", timeout=5000)
    ok(pg.input_value("#skName") == "Aysel Məmmədova", "input kohne adla dolu acilir")
    pg.fill("#skName", "   "); pg.click('#stuKart [data-sk="save"]'); pg.wait_for_timeout(500)
    ok("boş ola bilməz" in pg.inner_text("#skErr"), "bos ad redd olunur")
    ok(row(S0)["full_name"] == "Aysel Məmmədova", "bos adla baza deyismir")
    pg.fill("#skName", "Nigar Quliyeva"); pg.click('#stuKart [data-sk="save"]')
    pg.wait_for_selector("#stuKart .stkart", timeout=15000); pg.wait_for_timeout(1500)
    r1 = row(S0)
    ok(r1["full_name"] == "Nigar Quliyeva", "yeni ad bazada", r1["full_name"])
    ok(r1["display_name"] == "Nigar Q.", "qisa ad avtomatik yenilendi", r1["display_name"])
    ok("Nigar Quliyeva" in pg.inner_text("#band"), "sehife basliginda yeni ad")

    print("\nF · Giriş kodunu yenilə")
    kohne_kod = r1["login_code"]
    pg.click('#stuKart [data-sk="reset"]'); pg.wait_for_timeout(3000)
    pg.wait_for_selector("#stuKart .stkart", timeout=15000)
    yeni_kod = row(S0)["login_code"]
    ok(yeni_kod != kohne_kod, "giris kodu deyisdi", "%s -> %s" % (kohne_kod, yeni_kod))
    ok(yeni_kod in pg.locator("#stuKart .code").all_inner_texts(), "kart YENI kodu gosterir")
    ok(yeni_kod in pg.inner_text("#band"), "BASLIQDAKI kod da yenilendi (kohne kod qalmir)")
    ok(kohne_kod not in pg.inner_text("#main") + pg.inner_text("#band"), "kohne kod ekranda qalmir")

    print("\nG · Dayandır / davam etdir")
    sehife(pg, S2, G)
    pg.click('#stuKart [data-sk="off"]'); pg.wait_for_timeout(3000)
    pg.wait_for_selector('#stuKart [data-sk="on"]', timeout=15000)
    ok(row(S2)["is_active"] is False, "dayandirildi - bazada is_active = false")
    ok("dayandırılıb" in pg.inner_text("#stuKart summary"), "kart «dayandirilib» yazir")
    ok(pg.locator('#stuKart [data-sk="wa"]').count() == 0, "dayandirilmisda kod gondermek YOXDUR")
    pg.click('#stuKart [data-sk="on"]'); pg.wait_for_timeout(3000)
    pg.wait_for_selector('#stuKart [data-sk="off"]', timeout=15000)
    ok(row(S2)["is_active"] is True, "davam etdirildi - is_active = true")

    print("\nH · Girmiş şagirdin kartı yığılıb gəlir")
    sehife(pg, S1, G)
    ok(pg.locator("#stuKart details").first.get_attribute("open") is None, "girmis sagirdin karti YIGILIBDIR")
    ok("şagird girib" in pg.inner_text("#stuKart summary"), "basliqda «sagird girib»")
    pg.click("#stuKart summary"); pg.wait_for_timeout(300)
    ok(pg.locator('#stuKart [data-sk="pon"]').is_visible(), "acilanda valideyn girisi «ac» duymesi var")
    pg.screenshot(path="/tmp/claude-0/kart/kart_masaustu_girmis.png", full_page=True)
    sehife(pg, S0, G)
    pg.screenshot(path="/tmp/claude-0/kart/kart_masaustu.png", full_page=True)
    ctx.close()

    print("\nI · Köhnə görünüşdə kart yoxdur")
    ctx, pg = context(br, 1280, 1000, kohne=True)
    daxil(pg)
    pg.goto(PANEL + "#/s/%s/%s" % (S0, G)); pg.reload(); pg.wait_for_selector("#sTabs", timeout=20000)
    ok(pg.locator("#stuKart").count() == 0 and pg.locator(".stkart").count() == 0,
       "kohne gorunus DEYISMIR - kart cizilmir")
    ctx.close()

    print("\nJ · Telefon (390 px)")
    ctx, pg = context(br, 390, 844)
    daxil(pg)
    sehife(pg, S0, G)
    ok(pg.evaluate("() => document.documentElement.scrollWidth <= window.innerWidth + 1"), "yana surusme yoxdur")
    bx = pg.locator("#stuKart .stkart").bounding_box()
    ok(bx and bx["width"] <= 390, "kart ekrandan enmir", bx and round(bx["width"]))
    for sel in ('[data-sk="wa"]', '[data-sk="pwa"]', '[data-sk="cp"]', '[data-sk="reset"]', '[data-sk="off"]'):
        b = pg.locator("#stuKart " + sel).first.bounding_box()
        ok(b and b["x"] >= 0 and b["x"] + b["width"] <= 391, "duyme ekranin icindedir " + sel, b and round(b["x"] + b["width"]))
    pg.screenshot(path="/tmp/claude-0/kart/kart_telefon.png", full_page=True)
    ctx.close()
    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails))
    for f in fails: print("  - " + f)
    sys.exit(1)
print("SAGIRD KARTI: BUTUN YOXLAMALAR KECDI")
