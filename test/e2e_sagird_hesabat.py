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
    #  sagirdin secdiyi cavab (yanlis variant) - «Yazdi / Duz» ucun
    db("""update public.attempt_answers aa set selected_option_ids = array[(
            select o.id from public.question_options o
             where o.question_id = aa.question_id and not o.is_correct order by o.ord limit 1)]""")
    #  daha iki movzu: 55% (zeif) ve 70% (orta) - cubuq/faiz reng uygunlugu
    AT = db("select id::text i from public.attempts where student_id = %s order by finished_at desc limit 1", (S0,), one=True)["i"]
    tops = db("""select q.topic_id::text i from public.questions q
                   join public.topics t on t.id = q.topic_id join public.subjects s on s.id = t.subject_id
                  where q.owner_type='platform' and s.slug='riyaziyyat' and q.topic_id <> %s::uuid
                    and q.level_id = (select level_id from public.questions where topic_id = %s::uuid limit 1)
                  group by q.topic_id order by count(*) desc limit 2""", (TOPIC, TOPIC))
    for tp_, nok, nbad in ((tops[0]["i"], 6, 5), (tops[1]["i"], 7, 3)):
        db("""insert into public.attempt_answers (attempt_id, question_id, topic_id, is_correct, question_body)
              select %s::uuid, q.id, %s::uuid, rn <= %s, 'Movzu numune ' || rn
                from (select id, row_number() over (order by id) rn from public.questions
                       where owner_type='platform' and topic_id = %s::uuid order by id limit %s) q(id, rn)""",
           (AT, tp_, nok, tp_, nok + nbad))
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
    ok("+40" in pg.inner_text(".rstat"), "gedişat yuxarıdadır (+40)", pg.inner_text(".rstat").replace("\n", " "))
    ok("ilk test 20% → son test 60%" in pg.inner_text(".rstat"), "«+40» nəyi bildirdiyini deyir: ilk test 20% → son test 60%")
    ok("bütün dövr" in pg.inner_text(".rstat") or "son 30 gün" in pg.inner_text(".rstat"), "dövr yazılıb")
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
    ok(pg.locator("#vdF").count() == 1, "kartda «Təkrar test ver» düyməsi var")
    ok(pg.locator("#vdT").count() == 0 and pg.locator("#vdS").count() == 0, "«Mövzular» / «Səhvlər» düymələri YOXDUR (sekmələr yuxarıdadır)")
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

    print("\nD2 · Mövzular sekmesi: ümumi «Zəif mövzulardan test yığ» düyməsi götürülüb")
    pg.goto(PANEL + "#/s/" + S0 + "/" + GA); pg.reload(); pg.wait_for_selector("#sTabs", timeout=20000); pg.wait_for_timeout(800)
    pg.locator("#sTabs [data-v='m']").click(); pg.wait_for_selector("#topicBox .trow.topen", timeout=10000)
    ok(pg.locator("#btnRem").count() == 0, "ümumi düymə YOXDUR (hər mövzunun öz düyməsi var)")

    print("\nG · Səhvlər sekmesi")
    pg.goto(PANEL + "#/s/" + S0 + "/" + GA); pg.reload(); pg.wait_for_selector("#sTabs", timeout=20000); pg.wait_for_timeout(1000)
    diq = pg.locator("#stuDiq").evaluate("e => e.textContent")
    import re as _re
    mdiq = _re.search(r"(\d+)\s*səhv düzəliş", diq)
    tabn = pg.locator("#sTabs [data-v='s'] .tn").inner_text().strip()
    ok(mdiq and mdiq.group(1) == tabn, "sekmə rəqəmi = Diqqət kartındakı rəqəm (bir mənbə)", "%s / %s" % (mdiq.group(1) if mdiq else None, tabn))
    pg.locator("#sTabs [data-v='s']").click(); pg.wait_for_selector(".wq .wans", state="attached", timeout=10000); pg.wait_for_timeout(1500)
    ok("Ən çox səhv edilən suallar" in pg.locator("#tab-s").evaluate("e => e.textContent"), "başlıq «Ən çox səhv edilən suallar»")
    ok("ən çox səhv edilən" not in pg.locator("#tab-s summary").first.inner_text().lower().replace("ən çox səhv edilən suallar", ""), "eyni söz iki dəfə yazılmır")
    w0 = pg.locator("#wList .wq").first
    wt = w0.locator(".wans").evaluate("e => e.textContent")
    ok("Yazdı:" in wt and "Düz:" in wt, "hər sualda «Yazdı … · Düz …» var", wt[:90])
    row = db("""select o.body chosen from public.attempt_answers aa join public.question_options o on o.id = aa.selected_option_ids[1]
                where aa.question_body like 'Zeif movzu numune%%' limit 1""", one=True)
    ok(row and any(row["chosen"] in pg.locator("#wList .wq").nth(i).locator(".wans").evaluate("e => e.textContent") for i in range(pg.locator("#wList .wq").count())),
       "yazılan cavab bazadakı ilə üst-üstə düşür", row["chosen"] if row else None)
    pg.screenshot(path="/tmp/claude-0/sh_sehvler.png", full_page=False)

    print("\nI · Mövzular sekmesi")
    pg.locator("#sTabs [data-v='m']").click(); pg.wait_for_selector("#topicBox .trow", timeout=10000); pg.wait_for_timeout(500)
    ok(pg.locator("#sTabs [data-v='m'] .tn.tw").count() == 1, "«Mövzular» nişanı zəif mövzu rəngindədir (narıncı)")
    nw = pg.locator("#sTabs [data-v='m'] .tn").inner_text().strip()
    sec = pg.locator("#topicBox .tsec")
    ok(sec.count() == 2, "iki ayrı bölmə: «Zəif mövzular» və «Təkrar lazımdır»", sec.count())
    ok(sec.nth(0).evaluate("e => e.textContent").startswith("Zəif mövzular · " + nw), "birinci bölmənin sayı = sekmə nişanı (%s)" % nw, sec.nth(0).evaluate("e => e.textContent"))
    ok(sec.nth(1).evaluate("e => e.textContent").startswith("Təkrar lazımdır"), "ikinci bölmə «Təkrar lazımdır»")
    c1 = pg.locator("#topicBox > .card").nth(0).locator(".trow"); c2 = pg.locator("#topicBox > .card").nth(1).locator(".trow")
    ok(c1.count() == int(nw) and all("weakrow" in (c1.nth(i).get_attribute("class") or "") for i in range(c1.count())), "birinci kartda YALNIZ zəif mövzular (sol xətli)", c1.count())
    ok(c2.count() >= 1 and all("weakrow" not in (c2.nth(i).get_attribute("class") or "") for i in range(c2.count())), "ikinci kartda zəif mövzu yoxdur", c2.count())
    pg.screenshot(path="/tmp/claude-0/sh_movzular.png", full_page=False)
    ok(pg.locator("#sTabs [data-v='s'] .tn.tw").count() == 0, "«Səhvlər» nişanı neytral qalır")
    ok(pg.locator("#topicBox .wdot").count() == 0, "adın üstündə tək qalan nöqtə yoxdur")
    ok(pg.locator("#topicBox .trow.weakrow").count() >= 2, "zəif mövzu sətirləri sol xətlə", pg.locator("#topicBox .trow.weakrow").count())
    #  cubuq rengi = faiz rengi (80/60)
    pairs = pg.evaluate("""() => Array.from(document.querySelectorAll('#topicBox .trow')).map(r => ({
        m: (r.querySelector('.meter') || {className: ''}).className, p: (r.querySelector('.pctv') || {className: ''}).className,
        v: r.querySelector('.pctv') ? r.querySelector('.pctv').textContent : ''}))""")
    okmap = all(("m-ok" in x["m"]) == ("pvh" in x["p"]) and ("m-mid" in x["m"]) == ("pvm" in x["p"]) and ("m-low" in x["m"]) == ("pvl" in x["p"]) for x in pairs)
    ok(okmap and len(pairs) >= 3, "çubuğun rəngi faizin rəngi ilə eynidir", str([(x["v"], x["m"].replace("meter ", "")) for x in pairs]))
    rows = pg.locator("#topicBox .trow.topen")
    ok(rows.count() >= 3 and pg.locator("#topicBox .tpan:visible").count() == 0, "sətirlər basılandır, paneller susmaya görə bağlıdır", rows.count())
    ok(pg.evaluate("getComputedStyle(document.querySelector('#topicBox .trow.topen')).cursor") == "pointer", "basılan sətirdə əl işarəsi var")
    ok(pg.locator("#topicBox .tpan [data-tg]").count() == rows.count(), "HƏR mövzunun panelində «test yığ» düyməsi var", pg.locator("#topicBox .tpan [data-tg]").count())
    rows.first.click(); pg.wait_for_timeout(200)
    ok(pg.locator("#topicBox .tpan:visible").count() == 1 and "yığ" in pg.locator("#topicBox .tpan:visible").inner_text() and "Şagird" in pg.locator("#topicBox .tpan:visible").inner_text(),
       "sətrə basanda altında «Bu mövzudan test yığ — «Şagird» üçün» açılır", pg.locator("#topicBox .tpan:visible").inner_text().replace("\n", " ")[:70])
    pg.screenshot(path="/tmp/claude-0/sh_movzu_panel.png", full_page=False)
    rows.nth(1).click(); pg.wait_for_timeout(200)
    ok(pg.locator("#topicBox .tpan:visible").count() == 1, "ikinci sətir açılanda birinci bağlanır")
    rows.nth(1).click(); pg.wait_for_timeout(200)
    ok(pg.locator("#topicBox .tpan:visible").count() == 0, "təkrar basanda bağlanır")
    #  «sehvlerine bax» - suzgec
    tl = pg.locator("#topicBox .tlink").first
    ok(pg.locator("#topicBox .tlink").count() >= 1, "səhv sualı olan mövzuda «səhvlərinə bax →» panelin içindədir")
    tname = tl.get_attribute("data-tf")
    tl.locator("xpath=../preceding-sibling::div[contains(@class,'trow')][1]").click(); pg.wait_for_timeout(200)
    tl.click(); pg.wait_for_selector("#wFilt .wfilt", timeout=10000); pg.wait_for_timeout(300)
    ok(pg.locator("#tab-s").is_visible(), "keçid Səhvlər sekmesini açır")
    vis = pg.locator("#wList .wq:visible")
    ok(vis.count() >= 1 and all(vis.nth(i).get_attribute("data-tp") == tname for i in range(vis.count())), "yalnız «%s» mövzusunun sualları göstərilir" % tname, vis.count())
    ok(tname in pg.inner_text("#wFilt"), "süzgəc zolağında mövzunun adı yazılıb")
    pg.click("#wFiltX"); pg.wait_for_timeout(300)
    ok(pg.locator("#wFilt .wfilt").count() == 0, "«Filtri təmizlə» zolağı silir")
    #  HER movzuda sehv varsa kecid var; suzgec o movzunun BUTUN sehv suallarini gosterir (top-10 yox, db/902)
    pg.locator("#sTabs [data-v='m']").click(); pg.wait_for_timeout(200)
    wrong_by = {r["n"]: r["c"] for r in db(
        """select tp.name n, count(distinct aa.question_id) c
             from public.attempt_answers aa join public.attempts a on a.id = aa.attempt_id and a.student_id = %s::uuid
             join public.topics tp on tp.id = aa.topic_id
            where aa.is_correct is not true group by tp.name""", (S0,))}
    nwrong = sum(wrong_by.values())
    ok(nwrong > 10 and len(wrong_by) >= 3, "hazırlıq: 10-dan çox səhv sual, ≥3 mövzuda", "%d sual / %d mövzu" % (nwrong, len(wrong_by)))
    links = pg.locator("#topicBox .tlink")
    lnames = sorted(links.nth(i).get_attribute("data-tf") for i in range(links.count()))
    ok(lnames == sorted(wrong_by), "səhvi olan HƏR mövzunun panelində «səhvlərinə bax →» var", "%s / %s" % (lnames, sorted(wrong_by)))
    for nm, cnt in sorted(wrong_by.items()):
        pg.locator("#sTabs [data-v='m']").click(); pg.wait_for_timeout(150)
        lk = pg.locator("#topicBox .tlink[data-tf=\"%s\"]" % nm)
        lk.locator("xpath=../preceding-sibling::div[contains(@class,'trow')][1]").click(); pg.wait_for_timeout(150)
        lk.click(); pg.wait_for_selector("#wFilt .wfilt", timeout=10000); pg.wait_for_timeout(1200)
        vis = pg.locator("#wList .wq:visible")
        ok(vis.count() == cnt and all(vis.nth(i).get_attribute("data-tp") == nm for i in range(vis.count())),
           "«%s»: süzgəc %d səhv sualın hamısını göstərir" % (nm, cnt), vis.count())
        ok(pg.locator("#wCnt").inner_text().strip() == str(cnt), "başlıqdakı say süzgəclə uyğundur (%d)" % cnt)
        ok(pg.locator("#wList .wq:visible .wans").evaluate_all("els => els.every(e => e.textContent.trim().length > 0)"),
           "hər sualda «Yazdı» sətri dolu")
        pg.click("#wFiltX"); pg.wait_for_timeout(200)
        ok(pg.locator("#wList .wq.wx").count() == 0 and pg.locator("#wList .wq:visible").count() == 5 and pg.locator("#wCnt").inner_text().strip() == "10",
           "«Filtri təmizlə» ilk 5 sualı və 10 sayını qaytarır")

    print("\nH · Tarixçə sekmesi")
    pg.locator("#sTabs [data-v='t']").click(); pg.wait_for_selector(".dynw", timeout=10000); pg.wait_for_timeout(400)
    ok(pg.locator(".dynw .dyn i em").count() == 3, "hər sütunun üstündə rəqəm var", pg.locator(".dynw .dyn i em").count())
    ok(pg.locator(".dynw .dgl").count() == 2, "60% və 80% xətləri")
    ok(pg.locator(".dynw .dyd span").count() == 2, "ilk və son tarix")
    ok("cavab vərəqi" not in pg.locator("#atList").evaluate("e => e.textContent"), "sətirdə ikinci sətrə düşən «cavab vərəqi» yazısı yoxdur")
    ok(pg.locator("#atList .atr .ar").count() == 3, "sətirlərdə açılış oxu var")
    pg.locator("#atList .atr").first.click(); pg.wait_for_timeout(1200)
    ok(pg.locator("#atList .atr.open").count() == 1 and pg.locator("#atList .sheet:not(.hide)").count() == 1, "sətrə basanda cavab vərəqi açılır")
    pg.screenshot(path="/tmp/claude-0/sh_tarixce.png", full_page=False)

    print("\nI2 · Zəif mövzu sətri → «Bu mövzudan test yığ» (yalnız bu şagirdə)")
    pg.goto(PANEL + "#/s/" + S0 + "/" + GA); pg.reload(); pg.wait_for_selector("#sTabs", timeout=20000); pg.wait_for_timeout(800)
    pg.locator("#sTabs [data-v='m']").click(); pg.wait_for_selector("#topicBox .trow.weakrow", timeout=10000)
    wrow = pg.locator("#topicBox .trow.weakrow").first
    wname = wrow.locator(".g b").inner_text().strip()
    wrow.click(); pg.wait_for_timeout(200)
    pg.locator("#topicBox .tpan:visible [data-tg]").click(); pg.wait_for_selector("#gsub", timeout=20000); pg.wait_for_timeout(800)
    ok(pg.locator("#gAsg").count() == 0 and "yalnız" in pg.locator("#main").evaluate("e => e.textContent"), "generator açılır: qrup seçimi yoxdur, «yalnız … şagirdinə veriləcək»")
    ok(wname in pg.locator("#main").evaluate("e => e.textContent"), "yalnız «%s» mövzusu seçilib" % wname)
    ok("şagirdə ver" in pg.inner_text("#btnMake"), "düymə «Testi yığ və şagirdə ver»", pg.inner_text("#btnMake"))
    pg.wait_for_function("document.querySelector('#gPrev') && document.querySelector('#gPrev').innerText.indexOf('yoxlanılır') < 0 && document.querySelector('#gPrev').innerText.length > 5", timeout=15000)
    pg.click("#btnMake"); pg.wait_for_selector(".pasgok", timeout=25000); pg.wait_for_timeout(600)
    last = db("select a.student_id::text s from public.assignments a where a.class_id=%s::uuid order by a.created_at desc limit 1", (GA,), one=True)
    ok(last["s"] == S0, "tapşırıq YALNIZ bu şagirdə yazıldı", last["s"])

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
    tabs = pg.evaluate("""() => { var w = document.getElementById('sTabs').getBoundingClientRect();
        return Array.from(document.querySelectorAll('#sTabs .seg')).map(s => { var r = s.getBoundingClientRect();
          return {l: r.left >= w.left - 1, r: r.right <= w.right + 1, clip: s.scrollWidth > s.clientWidth + 1}; }); }""")
    ok(all(t["l"] and t["r"] and not t["clip"] for t in tabs), "4 sekmə telefonda sıxılmır və kəsilmir", str(tabs))
    pg.locator("#sTabs").screenshot(path="/tmp/claude-0/sh_sekmeler_telefon.png")
    bt = pg.locator("#stuPend .stpr [data-sp]").first.bounding_box(); rw = pg.locator("#stuPend .stpr").first.bounding_box()
    ok(bt["x"] + bt["width"] <= rw["x"] + rw["width"] + 1, "«Mesajı kopyala» düyməsi sıranın içindədir")
    pg.locator("#sTabs [data-v='s']").click(); pg.wait_for_selector(".wq .wans", state="attached", timeout=10000); pg.wait_for_timeout(1200)
    ok(scroll_x(pg) <= 1, "Səhvlər sekmesi telefonda yana sürüşmür", scroll_x(pg))
    wh = pg.locator("#wList .wq .wans").first.bounding_box()
    ok(wh["height"] < 60, "«Yazdı/Düz» qısa yer tutur (iki sətir)", round(wh["height"]))
    pg.locator("#wList").screenshot(path="/tmp/claude-0/sh_sehvler_telefon.png")
    pg.screenshot(path="/tmp/claude-0/sh_xulase_telefon.png", full_page=False)
    ctx.close()
    br.close()

print()
if fails:
    print("SINDI (%d):" % len(fails))
    for f in fails: print("  -", f)
    sys.exit(1)
print("HAMISI KECDI")
