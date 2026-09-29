#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Docx-dan dord is (29.09): yeni gorunusde qrup menyusu, «Testi yig», tapsiriq ekrani.

  A  qrup menyusunda «Dersden evvel» karti qayidib; «Tapsiriq ver» duymesi tekdir;
     «Plani qur» plan sehifesine aparir; plan sehifesinde kart menyudakinin
     tekrari deyil
  B  hesabatdan «Zeif movzulardan test yig» -> generatorda qrup SECILI,
     duymenin adi «Testi yig ve qrupa ver»; qrup silinende «Testi yig»;
     yigilandan sonra tesdiq var, «Indi onu qrupa verin» YOX
  C  tapsiriq verilenden sonra: tesdiq EN BASDA, WhatsApp metni baglidir,
     hazir test secimi baglidir, aktiv siyahi 3-le baslayir
  D  adlar: «Testi ver» (hazir test) ve «Ev tapsirigi yaz» (metn)
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


T = int(time.time()); MAIL = "is%d@t.az" % T
QRUP_A = "Ev qrup"

def context(br, w, h):
    ctx = br.new_context(viewport={"width": w, "height": h})
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)[:140]))
    return ctx, pg

def daxil(pg):
    pg.goto(PANEL); pg.wait_for_timeout(700)
    pg.fill("#email", MAIL); pg.fill("#pass", "isparol123"); pg.click("#btnAuth")
    pg.wait_for_timeout(3000)

def scroll_x(pg):
    return pg.evaluate("document.documentElement.scrollWidth - document.documentElement.clientWidth")

def gen_qrupla(pg, ad, qrup):
    pg.wait_for_selector("#gsub", timeout=20000); pg.wait_for_timeout(500)
    pg.fill("#gTitle", ad)
    pg.wait_for_function("document.querySelectorAll('#gAsg option').length > 1", timeout=10000)
    if qrup is not None:
        pg.select_option("#gAsg", qrup)
    pg.wait_for_function(
        "document.querySelector('#gPrev') && document.querySelector('#gPrev').innerText.indexOf('yoxlanılır') < 0 "
        "&& document.querySelector('#gPrev').innerText.length > 5", timeout=15000)

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])

    print("0 · Hazırlıq")
    ctx0, pg0 = context(br, 1280, 1000)
    pg0.goto(PANEL); pg0.wait_for_timeout(600); pg0.click("#btnSwap")
    pg0.fill("#fname", "Dord Is"); pg0.fill("#email", MAIL)
    pg0.fill("#pass", "isparol123"); pg0.click("#btnAuth")
    pg0.wait_for_selector("#btnSetup", timeout=20000)
    pg0.select_option("#atype", "tutor"); pg0.fill("#aname", "Is hesabi")
    pg0.click("#btnSetup"); pg0.wait_for_timeout(4500)
    uid = db("select id::text i from auth.users where email=%s", (MAIL,), one=True)["i"]
    acc = db("select id::text i from public.accounts where owner_id=%s::uuid", (uid,), one=True)["i"]
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select %s::uuid, p.id, 'active', now() + interval '30 days'
            from public.plans p where p.slug = 'repetitor-25'""", (acc,))
    GA = db("""insert into public.classes (account_id, teacher_id, kind, name, join_code, level_id)
               select %s::uuid, %s::uuid, 'tutor_group', %s, 'ISKOD006', l.id
                 from public.levels l where l.code='6' returning id::text i""",
            (acc, uid, QRUP_A), one=True)["i"]
    SIDS = []
    for i in range(2):
        SIDS.append(db("""insert into public.students (account_id, class_id, created_by, full_name,
                                           display_name, login_code)
              values (%s::uuid, %s::uuid, %s::uuid, %s, %s, %s) returning id::text i""",
           (acc, GA, uid, "Şagird A%d Test" % (i + 1), "Şagird A%d" % (i + 1),
            "ISS%d%d" % (i, T % 1000)), one=True)["i"])
    #  zeif movzu: 6 sehv cavab (ratio 0)
    TID = db("select id::text i from public.tests limit 1", one=True)["i"]
    TOPIC = db("""select q.topic_id::text i from public.questions q
                   join public.topics t on t.id = q.topic_id
                   join public.subjects s on s.id = t.subject_id
                  where q.owner_type='platform' and s.slug='riyaziyyat'
                  group by q.topic_id order by count(*) desc limit 1""", one=True)["i"]
    for i in range(2):
        db("""insert into public.attempts (test_id, student_id, status, percent, finished_at)
              values (%s, %s, 'submitted', 0, now() - interval '1 day')""", (TID, SIDS[i]))
    db("""insert into public.attempt_answers
            (attempt_id, question_id, topic_id, is_correct, question_body)
          select (select id from public.attempts where student_id = %s order by finished_at desc limit 1),
                 q.id, %s, false, 'Zeif movzu numune ' || rn
            from (select id, row_number() over (order by id) rn
                    from public.questions where owner_type='platform' and topic_id = %s::uuid order by id limit 6) q(id, rn)""",
       (SIDS[0], TOPIC, TOPIC))
    print("   hesab, abunə, qrup, 2 şagird, zəif mövzu")
    ctx0.close()

    ctx, pg = context(br, 1280, 1000)
    daxil(pg)

    print("\nA · Qrup menyusunda «Dərsdən əvvəl»")
    pg.goto(PANEL + "#/g/" + GA); pg.reload()
    pg.wait_for_selector("#gMenu", timeout=20000)
    pg.wait_for_selector("#prep .card.prep", timeout=15000)
    kt = pg.inner_text("#prep")
    ok("dərsdən əvvəl" in kt.lower(), "kart «Dərsdən əvvəl» adi ile qayidib", kt[:40].replace("\n", " "))
    ok(pg.locator("#prep .card.prep").count() >= 3, "kart AYRI kartlara bolunub", pg.locator("#prep .card.prep").count())
    ok("bu günün dərsi" in kt.lower(), "«Bu gunun dersi» karti var")
    ok("test" in kt.lower() and "yazılı" in kt.lower(), "«Test» ve «Yazili» kartlari var")
    ok(pg.locator("#main button", has_text="Tapşırıq ver").count() == 1,
       "«Tapsiriq ver» duymesi TEKDIR",
       pg.locator("#main button", has_text="Tapşırıq ver").count())
    ok(pg.locator("#prepAsg").count() == 0, "kartda ikinci «Tapsiriq ver» yoxdur")
    ok(pg.locator("#prepPlan").count() == 1, "plan yoxdursa «Plani qur» linki var")
    pg.screenshot(path="/tmp/claude-0/is_A_menyu.png", full_page=True)
    pg.click("#prepPlan"); pg.wait_for_timeout(600)
    ok(pg.url.endswith("/g/" + GA + "/p"), "«Plani qur» plan sehifesine aparir", pg.url[-30:])
    pg.wait_for_selector("#planBox", timeout=10000); pg.wait_for_timeout(1500)
    pt = pg.locator(".card.prep .pt b")
    ok(pt.count() == 0 or pt.first.inner_text() != "Dərsdən əvvəl",
       "plan sehifesinde kart menyudakinin tekrari deyil")

    print("\nB · Hesabat → «Test yığ» qrupu seçili açır")
    pg.goto(PANEL + "#/r/" + GA); pg.reload()
    pg.wait_for_selector("#rTabs", timeout=20000)
    pg.click("#rTabs [data-v='m']")
    pg.wait_for_selector("#btnRem", timeout=10000)
    pg.click("#btnRem")
    pg.wait_for_selector("#gsub", timeout=20000)
    pg.wait_for_function("document.querySelectorAll('#gAsg option').length > 1", timeout=10000)
    ok(pg.locator("#gAsg").input_value() == GA, "generatorda qrup SECILIDIR", pg.locator("#gAsg").input_value())
    mk = pg.inner_text("#btnMake")
    ok("qrupa ver" in mk, "duymenin adi «Testi yig ve qrupa ver»", mk)
    pg.select_option("#gAsg", "")
    ok(pg.inner_text("#btnMake").strip() == "Testi yığ", "qrup silinende «Testi yig»", pg.inner_text("#btnMake"))
    pg.select_option("#gAsg", GA)
    ok("qrupa ver" in pg.inner_text("#btnMake"), "qrup secilende yene «...qrupa ver»")
    gen_qrupla(pg, "Düzəliş B1", GA)
    pg.click("#btnMake")
    try:
        pg.wait_for_selector(".paper", timeout=25000)
    except Exception:
        print("   gErr:", pg.inner_text("#gErr")[:200], "| prev:", pg.inner_text("#gPrev")[:120]); raise
    pg.wait_for_timeout(1500)
    t = pg.inner_text("#main")
    ok(pg.locator(".pasgok").count() == 1, "tesdiq qutusu cixdi")
    ok("İndi onu qrupa verin" not in t, "«Indi onu qrupa verin» YOXDUR")
    ok(db("select count(*) n from public.assignments where class_id=%s::uuid", (GA,), one=True)["n"] == 1,
       "bazada tapsiriq bir dene")

    print("\nC · Tapşırıq verildikdən sonrakı səhifə")
    #  aktiv siyahi 3-den uzun olsun: daha 3 test yigib qrupa veririk
    for i in range(3):
        pg.goto(PANEL + "#/gen"); pg.reload()
        gen_qrupla(pg, "Düzəliş C%d" % i, GA)
        pg.click("#btnMake"); pg.wait_for_selector(".paper", timeout=25000); pg.wait_for_timeout(600)
    pg.goto(PANEL + "#/a/" + GA); pg.reload()
    pg.wait_for_selector("#aList .trow", timeout=20000)
    ok(pg.locator("#newAsg").count() == 0, "adi giriside secim qutusu baglanmir (tesdiq yoxdur)")
    ok(pg.locator("#pick").is_visible(), "adi giriside hazir test secimi ACIQDIR")
    ok("Testi ver" in pg.inner_text("#btnAsg"), "duyme «Testi ver» adlanir", pg.inner_text("#btnAsg"))
    ok("Ev tapşırığı yaz" in pg.inner_text("#btnHwAdd"), "metn duymesi «Ev tapsirigi yaz»", pg.inner_text("#btnHwAdd"))
    ok("Tapşırıq yaz" not in pg.inner_text("#main"), "«Tapsiriq yaz» adi qalmayib")
    pg.screenshot(path="/tmp/claude-0/is_C_evvel.png", full_page=True)
    #  yeni test yigib DEYIL, hazir siyahidan verek
    n0 = db("select count(*) n from public.assignments where class_id=%s::uuid", (GA,), one=True)["n"]
    tid = pg.evaluate("""() => { var o = Array.from(document.querySelectorAll('#aTest option')).map(x => x.value).filter(Boolean);
                               return o.length ? o[o.length-1] : '' }""")
    pg.click("#aList [data-t='" + tid + "']")
    pg.click("#btnAsg"); pg.wait_for_selector("#asgFlash", timeout=20000); pg.wait_for_timeout(1200)
    ok(db("select count(*) n from public.assignments where class_id=%s::uuid", (GA,), one=True)["n"] == n0 + 1,
       "tapsiriq bazaya yazildi")
    #  1 · tesdiq en basda
    ftop = pg.evaluate("document.getElementById('asgFlash').getBoundingClientRect().top")
    ltop = pg.evaluate("document.getElementById('asgList').getBoundingClientRect().top")
    ok(ftop < ltop, "tesdiq siyahidan YUXARIDADIR", "%d < %d" % (ftop, ltop))
    ok(pg.evaluate("document.querySelector('#main').firstElementChild.id") == "asgFlash",
       "tesdiq sehifenin ILK elementidir")
    ok(ftop < 500, "tesdiq basliqdan hemen sonra gorunur (scroll lazim deyil)", ftop)
    ok(pg.locator("#asgFlash .asgok").is_visible(), "tesdiq gorunur")
    fl = pg.inner_text("#asgFlash .asgok")
    ok("Tapşırıq verildi" in fl and "qrupun bütün şagirdləri" in fl, "tesdiq tam oxunur", fl[:70])
    ok(not pg.locator("#asgFlash .watxt").is_visible(), "WhatsApp metni baglidir")
    ok(pg.locator("#asgFlash summary").count() == 1, "«xeber vermek» acan setir var")
    ok(pg.locator("#newAsg").count() == 1 and not pg.locator("#pick").is_visible(),
       "hazir test secimi BAGLI qutudadir")
    ok(pg.locator("#asgList .asg").count() == 3, "aktiv siyahi 3-le baslayir", pg.locator("#asgList .asg").count())
    ok(pg.locator("#asgList .asg.fresh").count() == 1, "en yeni tapsiriq secilib")
    ok(pg.locator("#asgMore").count() == 1, "«Daha N tapsiriq» duymesi var")
    pg.screenshot(path="/tmp/claude-0/is_C_sonra_masaustu.png", full_page=False)
    #  yeni qutunu acmaq secimi gosterir
    pg.click("#newAsg > summary"); pg.wait_for_timeout(400)
    ok(pg.locator("#pick").is_visible(), "«Yeni tapsiriq ver» acilanda secim gorunur")
    pg.click("#asgMore"); pg.wait_for_timeout(300)
    ok(pg.locator("#asgList .asg").count() >= 5, "«Daha» hamisini acir", pg.locator("#asgList .asg").count())

    print("\nD · Telefon")
    ctx.close()
    ctx, pg = context(br, 390, 844)
    daxil(pg)
    pg.goto(PANEL + "#/g/" + GA); pg.reload()
    pg.wait_for_selector("#prep .card.prep", timeout=20000)
    ok(scroll_x(pg) <= 1, "menyu telefonda yana surusmur", scroll_x(pg))
    pg.screenshot(path="/tmp/claude-0/is_A_menyu_tel.png", full_page=True)
    pg.goto(PANEL + "#/gen"); pg.reload()
    gen_qrupla(pg, "Düzəliş D", GA)
    pg.click("#btnMake"); pg.wait_for_selector(".paper", timeout=25000); pg.wait_for_timeout(600)
    pg.goto(PANEL + "#/a/" + GA); pg.reload()
    pg.wait_for_selector("#aList .trow", timeout=20000)
    tid = pg.evaluate("""() => { var o = Array.from(document.querySelectorAll('#aTest option')).map(x => x.value).filter(Boolean);
                               return o.length ? o[0] : '' }""")
    pg.click("#aList [data-t='" + tid + "']")
    pg.click("#btnAsg"); pg.wait_for_selector("#asgFlash", timeout=20000); pg.wait_for_timeout(1200)
    ok(scroll_x(pg) <= 1, "tapsiriq sehifesi telefonda yana surusmur", scroll_x(pg))
    ok(pg.evaluate("document.querySelector('#main').firstElementChild.id") == "asgFlash",
       "telefonda da tesdiq ILK elementdir")
    ok(pg.evaluate("document.getElementById('asgFlash').getBoundingClientRect().bottom") < 844,
       "telefonda tesdiq birinci ekrana sigir")
    pg.screenshot(path="/tmp/claude-0/is_C_sonra_telefon.png", full_page=False)
    ctx.close()
    br.close()

print()
if fails:
    print("SINDI (%d):" % len(fails))
    for f in fails: print("  -", f)
    sys.exit(1)
print("HAMISI KECDI")
