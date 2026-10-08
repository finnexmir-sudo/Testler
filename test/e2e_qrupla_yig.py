#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Generatorda QRUP seçib test yığmaq — nəticə səhifəsi (29.09).

Istifadeci uc problem gordu (yeni gorunus standart olandan sonra):
  1. Qrupa test yigdim, sonraki sehife qarisiq geldi
  2. Testin qrupa verildiyi deqiq bilinmir
  3. Test yig etdim ama teyin ede bilmedim

TEKRAR (test/_yeni_qrup_yol.py, sekillerle):  «Ev qrup»u secib «Testi yig»
basanda sehife OZUNE ZIDD idi:
    yuxari: «Test hazirdir. Indi onu qrupa verin»   (emr)
    asagi:  «Ev qrup - verilib»                      (artiq verilib)
    forma:  «Qrup» siyahisi BASQA qrupla acilir - secilen qrup siyahida YOX
Ustelik tapsiriq alinmayanda xeta .catch(function(){}) ile UDULURDU.

Yoxlanir (yeni ve kohne gorunusde):
  A  qrup secilib, tapsiriq verilib: TESDIQ var, «indi qrupa verin» YOX
  B  tesdiqde qrupun adi yazilir
  C  forma «Basqa qrupa da» deyir (verilmis qrup siyahida gorunmur)
  D  qrup secilib, tapsiriq ALINMAYIB: SEBEB yazilir, qrup formada SECILI
  E  qrup secilmeyib: evvelki davranis - «Indi onu qrupa verin» qalir
"""
import sys, time, json
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

ROOT = "http://127.0.0.1:8010/"
PANEL = ROOT + "muellim/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
CFG = """window.CFG = {SUPABASE_URL:"http://127.0.0.1:54321",
  SUPABASE_ANON_KEY:"test-anon-key", STUDENT_URL:"http://127.0.0.1:8010/sagird/",
  SHOW_PLANS:false};"""

fails = []
def ok(cond, label, extra=""):
    print(("  OK   " if cond else "  FAIL ") + label + (("  " + str(extra)) if extra else ""),
          flush=True)
    if not cond: fails.append(label)

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

T = int(time.time()); MAIL = "qy%d@t.az" % T
QRUP_A = "Ev qrup"; QRUP_B = "Kiçik qrup"

def context(br, w, h, kohne):
    ctx = br.new_context(viewport={"width": w, "height": h})
    if kohne:
        ctx.add_init_script("try{localStorage.setItem('bil10_yeni','0')}catch(e){}")
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)[:140]))
    return ctx, pg

def daxil(pg):
    pg.goto(PANEL); pg.wait_for_timeout(700)
    pg.fill("#email", MAIL); pg.fill("#pass", "qyparol123"); pg.click("#btnAuth")
    pg.wait_for_timeout(3000)

def yig(pg, ad, qrup=None):
    pg.goto(PANEL + "#/gen"); pg.reload()
    pg.wait_for_selector("#gsub", timeout=20000); pg.wait_for_timeout(500)
    pg.select_option("#gsub", "riyaziyyat"); pg.wait_for_timeout(500)
    pg.wait_for_selector("#gLevs", timeout=10000)
    while pg.locator("#gLevs .chip.on").count():
        pg.locator("#gLevs .chip.on").first.click(); pg.wait_for_timeout(200)
    pg.locator('#gLevs [data-l="6"]').click(); pg.wait_for_timeout(500)
    pg.fill("#gCnt", "10"); pg.fill("#gTitle", ad)
    pg.wait_for_function("document.querySelectorAll('#gAsg option').length > 1", timeout=10000)
    pg.select_option("#gAsg", qrup or "")
    pg.wait_for_function(
        "document.querySelector('#gPrev') && document.querySelector('#gPrev').innerText.indexOf('yoxlanılır') < 0 "
        "&& document.querySelector('#gPrev').innerText.length > 5", timeout=15000)
    pg.click("#btnMake")
    pg.wait_for_selector(".paper, #pAsgH", state="attached", timeout=20000); pg.evaluate("var f=document.getElementById('qFold'); if(f) f.open=true")
    pg.wait_for_timeout(1500)

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])

    print("0 · Hazırlıq")
    ctx0, pg0 = context(br, 1280, 1000, False)
    pg0.goto(PANEL); pg0.wait_for_timeout(600); pg0.click("#btnSwap")
    pg0.fill("#fname", "Qrupla Yig"); pg0.fill("#email", MAIL)
    pg0.fill("#pass", "qyparol123"); pg0.click("#btnAuth")
    pg0.wait_for_selector("#btnSetup", timeout=20000)
    pg0.select_option("#atype", "tutor"); pg0.fill("#aname", "QY hesabi")
    pg0.click("#btnSetup"); pg0.wait_for_timeout(4500)
    uid = db("select id::text i from auth.users where email=%s", (MAIL,), one=True)["i"]
    acc = db("select id::text i from public.accounts where owner_id=%s::uuid", (uid,), one=True)["i"]
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select %s::uuid, p.id, 'active', now() + interval '30 days'
            from public.plans p where p.slug = 'repetitor-25'""", (acc,))
    GA = db("""insert into public.classes (account_id, teacher_id, kind, name, join_code, level_id)
               select %s::uuid, %s::uuid, 'tutor_group', %s, 'QYKOD006', l.id
                 from public.levels l where l.code='6' returning id::text i""",
            (acc, uid, QRUP_A), one=True)["i"]
    GB = db("""insert into public.classes (account_id, teacher_id, kind, name, join_code, level_id)
               select %s::uuid, %s::uuid, 'tutor_group', %s, 'QYKOD003', l.id
                 from public.levels l where l.code='6' returning id::text i""",
            (acc, uid, QRUP_B), one=True)["i"]
    for c, pref in ((GA, "A"), (GB, "B")):
        for i in range(2):
            db("""insert into public.students (account_id, class_id, created_by, full_name,
                                               display_name, login_code)
                  values (%s::uuid, %s::uuid, %s::uuid, %s, %s, %s)""",
               (acc, c, uid, "Şagird %s%d Test" % (pref, i + 1), "Şagird %s%d" % (pref, i + 1),
                "QYS%s%d%d" % (pref, i, T % 100)))
    print("   hesab, abunə, iki 6-cı sinif qrupu, 4 şagird")
    ctx0.close()

    for kohne in (False, True):
        AD = "KÖHNƏ" if kohne else "YENİ (standart)"
        tag = "kohne" if kohne else "yeni"
        print("\n" + "=" * 58 + "\n%s GÖRÜNÜŞ" % AD)
        for (w, h, tel) in ((1280, 1000, "masaustu"), (390, 844, "telefon")):
            ctx, pg = context(br, w, h, kohne)
            daxil(pg)

            print("\nA-C · Qrup seçilib, tapşırıq VERİLİB   [%s · %s]" % (tag, tel))
            ad = "QY A %s %s" % (tag, tel)
            yig(pg, ad, GA)
            t = pg.inner_text("#main")
            ok(pg.locator(".pasgok").count() == 1, "tesdiq qutusu cixir", pg.locator(".pasgok").count())
            box = pg.inner_text(".pasgok") if pg.locator(".pasgok").count() else ""
            print("   qutu: " + box.replace("\n", " ")[:130])
            ok(QRUP_A in box and "Tapşırıq verildi" in box, "tesdiqde qrupun ADI yazilir", box[:60])
            ok("İndi onu qrupa verin" not in t,
               "«Indi onu qrupa verin» emri YOXDUR (artiq verilib)")
            ok("Başqa qrupa da ver" in t and not pg.evaluate("document.querySelector('details.pother').open"), "08.10: forma BAGLI «Başqa qrupa da ver» altındadır")
            opts = pg.locator("#pCls option").all_inner_texts()
            ok(all(QRUP_A not in o.split(" · ")[0] for o in opts),
               "verilmis qrup siyahida YOXDUR (basqa qrup ucun forma)", opts)
            n = db("""select count(*) n from public.assignments a join public.tests t on t.id=a.test_id
                       where t.title=%s""", (ad,), one=True)["n"]
            ok(n == 1, "bazada tapsiriq bir dene", n)
            pg.screenshot(path="/tmp/claude-0/yeniyol/QY_A_%s_%s.png" % (tag, tel), full_page=True)

            print("\nD · Qrup seçilib, tapşırıq ALINMAYIB   [%s · %s]" % (tag, tel))
            def blok(route):
                route.fulfill(status=400, content_type="application/json", body=json.dumps({
                    "code": "P0001",
                    "message": "Bu test abune paketine daxildir. Sagird onu aca bilmeyecek."}))
            pg.route("**/rpc/rpc_assign_test", blok)
            ad2 = "QY D %s %s" % (tag, tel)
            yig(pg, ad2, GB)
            pg.unroute("**/rpc/rpc_assign_test")
            t2 = pg.inner_text("#main")
            print("   mətn: " + t2.replace("\n", " · ")[:330])
            ok("verilə bilmədi" in t2 and QRUP_B in t2,
               "tapsiriq alinmayanda SEBEB yazilir (xeta udulmur)")
            ok("abunə paketinə daxildir" in t2 or "abune paketine daxildir" in t2,
               "serverin real sebebi gorunur")
            ok("İndi onu qrupa verin" not in t2 or "verilə bilmədi" in t2,
               "«hazirdir» emri sebebi ortmur")
            sel = pg.locator("#pCls").evaluate(
                "e => e.options[e.selectedIndex] ? e.options[e.selectedIndex].textContent : ''")
            ok(sel.startswith(QRUP_B), "forma HEMIN qrupu secili acir (basqasini yox)", sel)
            n2 = db("""select count(*) n from public.assignments a join public.tests t on t.id=a.test_id
                        where t.title=%s""", (ad2,), one=True)["n"]
            ok(n2 == 0, "bazada tapsiriq YOXDUR (dogrudan da verilmeyib)", n2)
            pg.screenshot(path="/tmp/claude-0/yeniyol/QY_D_%s_%s.png" % (tag, tel), full_page=True)
            #  el ile vermek isleyir
            pg.click("#btnPAsg"); pg.wait_for_timeout(2500)
            n3 = db("""select count(*) n from public.assignments a join public.tests t on t.id=a.test_id
                        where t.title=%s""", (ad2,), one=True)["n"]
            ok(n3 == 1, "sebebi oxuyub el ile vermek isleyir", n3)

            print("\nE · Qrup SEÇİLMƏYİB   [%s · %s]" % (tag, tel))
            yig(pg, "QY E %s %s" % (tag, tel), None)
            t3 = pg.inner_text("#main")
            ok("İndi onu qrupa verin" in t3, "qrupsuz yigilanda evvelki mesaj qalir")
            ok(pg.locator(".pasgok").count() == 0, "tesdiq qutusu YOXDUR (hec ne verilmeyib)")
            ok("Başqa qrupa da" not in t3, "«Basqa qrupa da» yazisi yoxdur")
            ctx.close()
    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails))
    for f in fails: print("  - " + f)
    sys.exit(1)
print("QRUPLA YIGMAQ: BUTUN YOXLAMALAR KECDI")
