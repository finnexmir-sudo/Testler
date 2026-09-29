#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""«Tapşırığı etməyənlər» səhifəsi (#/ht/<qrup>) — 29.09.

İcmalda «2 şagird yazılı tapşırığı etməyib» sətri var idi; basanda qrup menyusu
açılırdı, adlar aşağıdakı kartda idi (say ilə siyahı üst-üstə düşmürdü).

  A  İcmal sətri: say + «yazılı» sözü; basanda #/ht/<qrup> açılır
  B  səhifədə EYNİ say qədər ad var; hər adın yanında «Xatırlat»; ad hesabata aparır
  C  «Xatırlat» hazır mesajı kopyalayır (ad, tapşırıq mətni, «Kodunla gir»)
  D  «Geri» İcmala qaytarır (düymə və brauzerin geri düyməsi)
  E  test bölməsi; boş qrup üçün boş hal
  F  telefonda yana sürüşmə yoxdur, düymə sıranın içindədir
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


    #  --- tapsirig: 1 test + yazili ev tapsirigi (2 sagird ikisini de etmeyib)
    db("""insert into public.assignments (class_id, test_id, assigned_by)
          select %s::uuid, t.id, %s::uuid from public.tests t where t.slug = 'riy-3-vurma-1'""", (GA, uid))
    ctx, pg = context(br, 1280, 1000)
    ctx.grant_permissions(["clipboard-read", "clipboard-write"], origin="http://127.0.0.1:8010")
    daxil(pg)
    pg.goto(PANEL + "#/a/" + GA + "/h"); pg.reload(); pg.wait_for_selector("#hwText", timeout=20000)
    pg.fill("#hwText", "12-ci paraqrafı oxu, çalışma 3–5-i həll et"); pg.fill("#hwDue", time.strftime("%Y-%m-%d")); pg.click("#btnHwAdd"); pg.wait_for_selector("#hwList .hwrow", timeout=15000)

    print("\nA · İcmal sətri")
    pg.goto(PANEL + "#/"); pg.reload()
    sat = pg.locator("#yDiq .mrow.dq", has_text="yazılı tapşırığı etməyib")
    sat.wait_for(timeout=20000)
    st = sat.first.inner_text().replace("\n", " ")
    ok("2 şagird yazılı tapşırığı etməyib" in st, "sətir dəqiq yazılıb", st[:70])
    ok(sat.first.get_attribute("href").endswith("#/ht/" + GA), "keçid #/ht/<qrup>", sat.first.get_attribute("href"))
    pg.screenshot(path="/tmp/claude-0/ht_icmal.png")
    sat.first.click(); pg.wait_for_selector("#htBox .udr", timeout=15000); pg.wait_for_timeout(600)
    ok(pg.url.endswith("#/ht/" + GA), "səhifə açıldı", pg.url[-30:])

    print("\nB · Səhifədə eyni say qədər ad")
    bas = pg.locator("#htBox").evaluate("e => e.textContent")   #  CSS basliqlari boyuk herfe cevirir (inner_text)
    ok("2 şagird etməyib" in bas, "bölmə başlığı «2 şagird etməyib»")
    ok("2 şagird işləməyib" in bas, "test bölməsi «2 şagird işləməyib»")
    ok("12-ci paraqrafı oxu" in bas, "tapşırığın mətni yazılıb")
    yaz = pg.locator("#htBox .menu").first.locator(".udr")
    ok(yaz.count() == 2, "yazılı bölmədə 2 sıra var (say ilə eyni)", yaz.count())
    ok(all(yaz.nth(i).locator("[data-ud]").count() == 1 for i in range(2)), "hər sırada «Xatırlat» var")
    ok(pg.locator("#htBox .udr").count() == 4, "cəmi 4 sıra (2 yazılı + 2 test)", pg.locator("#htBox .udr").count())
    ok(pg.locator("#htBox a.mrow", has_text="Tapşırıqlara bax").count() == 1, "«Tapsiriqlara bax» menyu sirasi kimidir (iconlu, oxlu)")
    pg.screenshot(path="/tmp/claude-0/ht_sehife_masaustu.png", full_page=True)
    pg.locator("#htBox a.mrow", has_text="Tapşırıqlara bax").click(); pg.wait_for_selector("#btnAsgT", timeout=15000)
    ok(pg.url.endswith("#/a/" + GA), "«Tapsiriqlara bax» tapsiriqlar ekranina aparir", pg.url[-20:])
    pg.go_back(); pg.wait_for_selector("#htBox .udr", timeout=15000)

    print("\nC · «Xatırlat»")
    yaz.first.locator("[data-ud]").click(); pg.wait_for_timeout(500)
    ok("Kopyalandı" in yaz.first.locator("[data-ud]").inner_text(), "düymə «Kopyalandı» deyir", yaz.first.locator("[data-ud]").inner_text())
    clip = pg.evaluate("navigator.clipboard.readText()")
    ok("Salam" in clip and "12-ci paraqrafı oxu" in clip and "Kodunla gir" in clip, "mesaj kopyalanıb", clip.replace("\n", " | ")[:100])
    ok("Şagird" in clip.split("!")[0], "mesaj şagirdin adı ilə başlayır")
    yaz.first.locator("a.udl").click(); pg.wait_for_timeout(1500)
    ok("/s/" in pg.url, "ada basanda şagirdin hesabatı açılır", pg.url[-40:])
    pg.go_back(); pg.wait_for_selector("#htBox .udr", timeout=15000)
    ok(pg.url.endswith("#/ht/" + GA), "brauzerin geri düyməsi səhifəyə qaytarır")

    print("\nD · Geri")
    pg.click("#htBack"); pg.wait_for_selector("#yDiq", timeout=15000)
    ok(pg.url.endswith("#/") or pg.url.endswith("/muellim/") or pg.url.endswith("index.html"), "«Geri» İcmala qaytarır", pg.url[-25:])

    print("\nE · Boş hal: tapşırığı olmayan qrup")
    GB = db("""insert into public.classes (account_id, teacher_id, kind, name, join_code, level_id)
               select %s::uuid, %s::uuid, 'tutor_group', 'Boş qrup', 'ISKOD007', l.id
                 from public.levels l where l.code='6' returning id::text i""", (acc, uid), one=True)["i"]
    pg.goto(PANEL + "#/ht/" + GB); pg.reload(); pg.wait_for_selector("#htBox .empty", timeout=15000)
    ok("Açıq tapşırıq yoxdur" in pg.inner_text("#htBox"), "boş qrupda aydın mesaj", pg.inner_text("#htBox")[:60].replace("\n", " "))
    ctx.close()

    print("\nF · Telefon (390 px)")
    ctx, pg = context(br, 390, 844)
    daxil(pg)
    pg.goto(PANEL + "#/ht/" + GA); pg.reload(); pg.wait_for_selector("#htBox .udr", timeout=20000); pg.wait_for_timeout(600)
    ok(scroll_x(pg) <= 1, "yana sürüşmə yoxdur", scroll_x(pg))
    rw = pg.locator("#htBox .udr").first.bounding_box(); bt = pg.locator("#htBox .udr [data-ud]").first.bounding_box()
    ok(bt["x"] + bt["width"] <= rw["x"] + rw["width"] + 1 and bt["x"] >= rw["x"], "«Xatırlat» düyməsi sıranın içindədir")
    ok(bt["height"] >= 30, "düymənin hündürlüyü kifayətdir", round(bt["height"]))
    pg.screenshot(path="/tmp/claude-0/ht_sehife_telefon.png", full_page=True)
    ctx.close()
    br.close()

print()
if fails:
    print("SINDI (%d):" % len(fails))
    for f in fails: print("  -", f)
    sys.exit(1)
print("HAMISI KECDI")
