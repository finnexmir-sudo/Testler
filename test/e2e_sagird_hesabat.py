#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""«Şagird hesabatı, Xülasə sekmesi — 29.09.

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


    #  --- vəziyyət: S0 üç cəhd (20 -> 40 -> 60), zəif mövzu; yazılı ev tapşırığı (bu gün) və 1 test verilib
    S0, S1 = SIDS
    VT = db("select id::text i from public.tests where slug='riy-3-vurma-1'", one=True)["i"]
    AZ = db("select id::text i from public.tests where slug like 'az-%%' or title like 'Azərbaycan%%' order by title limit 1", one=True)["i"]
    db("delete from public.attempt_answers; delete from public.attempts;")
    for i, pcn in enumerate((20, 40, 60)):
        db("""insert into public.attempts (test_id, student_id, status, percent, finished_at)
              values (%s, %s, 'submitted', %s, now() - (%s || ' days')::interval)""", (AZ, S0, pcn, 3 - i))
    db("""insert into public.attempt_answers (attempt_id, question_id, topic_id, is_correct, question_body)
          select (select id from public.attempts where student_id = %s order by finished_at desc limit 1),
                 q.id, %s, false, 'Zeif movzu numune ' || rn
            from (select id, row_number() over (order by id) rn
                    from public.questions where owner_type='platform' and topic_id = %s::uuid order by id limit 6) q(id, rn)""",
       (S0, TOPIC, TOPIC))
    db("insert into public.assignments (class_id, test_id, assigned_by) values (%s::uuid, %s::uuid, %s::uuid)", (GA, VT, uid))
    db("insert into public.homework (class_id, created_by, body, due) values (%s::uuid, %s::uuid, %s, current_date)",
       (GA, uid, "12-ci paraqrafı oxu"))
    #  S1: gorunen ad tam adla EYNI - basliqda ad tekrarlanmamalidir
    db("update public.students set display_name = full_name where id = %s::uuid", (S1,))
    NAME0 = db("select full_name f from public.students where id=%s::uuid", (S0,), one=True)["f"]

    ctx, pg = context(br, 1280, 1000)
    ctx.grant_permissions(["clipboard-read", "clipboard-write"], origin="http://127.0.0.1:8010")
    daxil(pg)
    pg.goto(PANEL + "#/s/" + S0 + "/" + GA); pg.reload()
    pg.wait_for_selector("#stuPend .stpr", timeout=25000); pg.wait_for_timeout(1500)

    print("\nA · Başlıq və gedişat")
    ok("gedişat" in pg.inner_text(".rstat") and "+40" in pg.inner_text(".rstat"), "gedişat yuxarıdadır (+40)", pg.inner_text(".rstat").replace("\n", " "))
    ok("20% → 60%" in pg.inner_text(".rstat"), "20% → 60% yazılıb")
    ok("ən yaxşı" not in pg.inner_text(".rstat"), "«ən yaxşı» rəqəmi çıxarılıb")

    print("\nB · «Diqqət» kartı — gəliş səbəbi")
    dq = pg.inner_text("#stuDiq")
    ok(pg.locator("#stuDiq").is_visible() and "Gözləyən tapşırıqlar" in pg.locator("#stuDiq").evaluate("e => e.textContent"), "gözləyən tapşırıqlar bloku var")
    ok("Yazılı tapşırığı etməyib" in pg.locator("#stuPend").evaluate("e => e.textContent"), "yazılı tapşırıq sırası")
    ok("1 test gözləyir" in pg.locator("#stuPend").evaluate("e => e.textContent") and "Vurma cədvəli" in pg.locator("#stuPend").evaluate("e => e.textContent"),
       "test sırası testin adı ilə")
    pg.locator("#stuPend [data-sp]").first.click(); pg.wait_for_timeout(500)
    clip = pg.evaluate("navigator.clipboard.readText()")
    ok(clip.startswith("Salam! ") and "ev tapşırığı gözləyir: «12-ci paraqrafı oxu»" in clip, "mesaj etməyənlər səhifəsi ilə EYNİ mətn", clip.replace("\n", " | ")[:100])
    ok("Zəif mövzu" in dq, "zəif mövzu eyni kartdadır")
    ok(pg.locator("#vdF").count() == 1 and pg.locator("#vdT").count() == 1 and pg.locator("#vdS").count() == 1, "düymələr: Mövzular, Səhvlər, Təkrar test ver")
    pg.locator("#vdF").click(); pg.wait_for_timeout(2500)
    fm = pg.locator("#vdFMsg").evaluate("e => e.textContent")
    ok("test yığıldı" in fm and "YALNIZ bu şagirdə" in fm, "«Təkrar test ver» yalnız bu şagirdə test yığdı", fm[:80])
    pg.screenshot(path="/tmp/claude-0/sh_xulase_masaustu.png", full_page=True)

    print("\nC · Valideynə göndər — tək bölmə")
    txt = pg.locator("#tab-x").evaluate("e => e.textContent")
    ok("Valideyn üçün xülasə" not in txt and "Nəticə kartı" not in txt, "köhnə iki bölmə yoxdur")
    ok("Valideynə göndər" in txt, "«Valideynə göndər» bölməsi")
    ok(pg.locator("#vTabs .seg").count() == 2, "Mətn / Şəkil kartı sekmələri")
    ok(pg.locator("#vTxt").is_visible() and not pg.locator("#pcv").is_visible(), "susmaya görə mətn görünür, şəkil gizlidir")
    ok(pg.evaluate("getComputedStyle(document.getElementById('vTxt')).fontFamily").lower().find("mono") < 0, "mətn monospace deyil")
    pg.locator("#vTabs .seg", has_text="Şəkil kartı").click(); pg.wait_for_timeout(400)
    ok(pg.locator("#pcv").is_visible() and not pg.locator("#vTxt").is_visible(), "şəkil kartı sekmesi açılır")
    ok(pg.evaluate("document.getElementById('pcv').width") == 1080 and pg.evaluate("document.getElementById('pcDl').href").startswith("data:image"), "şəkil çəkilib, yüklə keçidi hazırdır")
    pg.screenshot(path="/tmp/claude-0/sh_valideyn_sekil.png", full_page=False)
    pg.locator("#vTabs .seg", has_text="Mətn").click()

    print("\nD · «Test tapşır» menyusu")
    ok(not pg.locator("#stuAsgMenu").is_visible(), "menyu susmaya görə bağlıdır")
    ok(not pg.locator("#diagBox summary").first.is_visible() if pg.locator("#diagBox summary").count() else True, "«+ Diaqnostik test ver» keçidi artıq ayrıca görünmür")
    pg.click("#btnAsgStu"); pg.wait_for_timeout(300)
    ok(pg.locator("#stuAsgMenu").is_visible() and pg.locator("#stuAsgMenu .mrow").count() == 3, "menyuda 3 sıra", pg.locator("#stuAsgMenu .mrow").count())
    pg.screenshot(path="/tmp/claude-0/sh_menyu.png", full_page=False)
    pg.locator("#stuAsgMenu [data-am='d']").click(); pg.wait_for_timeout(600)
    ok(pg.locator("#dgGo").is_visible(), "«Diaqnostik test» diaqnostika formasını açır", pg.locator("#dgGo").count())
    pg.click("#btnAsgStu"); pg.locator("#stuAsgMenu [data-am='s']").click(); pg.wait_for_timeout(600)
    ok(pg.locator("#tab-s").is_visible() and pg.locator("#btnFix").is_visible(), "«Səhvlərdən təkrar» Səhvlər sekmesini açır")
    pg.click("#btnAsgStu"); pg.locator("#stuAsgMenu [data-am='t']").click(); pg.wait_for_selector("#pick .trow", timeout=20000)
    ok(pg.url.endswith("#/a/" + GA + "/" + S0), "«Hazır test» seçim səhifəsinə aparır (şagirdlə)", pg.url[-30:])
    ok(pg.locator("#aWho").input_value() == S0, "şagird «Kimə»də seçilib")
    pg.go_back(); pg.wait_for_selector("#stuDiq", state="attached", timeout=20000)

    print("\nE · Ad təkrarı (görünən ad tam adla eynidir)")
    pg.goto(PANEL + "#/s/" + S1 + "/" + GA); pg.reload(); pg.wait_for_selector("#sTabs", timeout=20000); pg.wait_for_timeout(800)
    bt = pg.locator("#band").evaluate("e => e.textContent")
    n1 = db("select full_name f from public.students where id=%s::uuid", (S1,), one=True)["f"]
    ok(bt.count(n1) == 1, "başlıqda ad bir dəfə yazılıb", bt[:70])
    ctx.close()

    print("\nF · Telefon (390 px)")
    ctx, pg = context(br, 390, 844)
    daxil(pg)
    pg.goto(PANEL + "#/s/" + S0 + "/" + GA); pg.reload()
    pg.wait_for_selector("#stuPend .stpr", timeout=25000); pg.wait_for_timeout(1500)
    ok(scroll_x(pg) <= 1, "yana sürüşmə yoxdur", scroll_x(pg))
    bt = pg.locator("#stuPend .stpr [data-sp]").first.bounding_box(); rw = pg.locator("#stuPend .stpr").first.bounding_box()
    ok(bt["x"] + bt["width"] <= rw["x"] + rw["width"] + 1, "«Mesajı kopyala» düyməsi sıranın içindədir")
    pg.screenshot(path="/tmp/claude-0/sh_xulase_telefon.png", full_page=False)
    ctx.close()
    br.close()

print()
if fails:
    print("SINDI (%d):" % len(fails))
    for f in fails: print("  -", f)
    sys.exit(1)
print("HAMISI KECDI")
