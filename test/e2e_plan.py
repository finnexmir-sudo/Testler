#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Ders plani axini: qurulus -> kecildi -> test teklifi -> tapsiriq.

Pullu qapi da yoxlanir: abunesiz kilid karti gorunur.
"""
import sys
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

PANEL  = "http://127.0.0.1:8010/muellim/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN    = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
BLOCK  = "**://*.supabase.co/**"
TEST_CFG = """window.CFG = {
  SUPABASE_URL: "http://127.0.0.1:54321",
  SUPABASE_ANON_KEY: "test-anon-key",
  STUDENT_URL: "https://example.test/Testler/"
};"""

#  A-I bolmeleri DUZ plani (fesilsiz) yoxlayir: "kecilmis movzuda test
#  yig" yalniz fesilsiz movzuda ve ya feslin SON dersinde cixir.  J
#  bolmesi fesilleri OZU qurur.  Ona gore burada hele alt movzusu
#  olmayan sinif secilir - riyaziyyat 2 (portaldaki nesr kohne oldugu
#  ucun alt movzu almir).  Bir gun o sinfe de alt movzu gelse
#  asagidaki assert susmayacaq.
SINIF = "2"

fails = []
def ok(cond, label, extra=""):
    print(("  OK   " if cond else "  FAIL ") + label + (("  " + str(extra)) if extra else ""),
          flush=True)
    if not cond: fails.append(label)

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            return cur.fetchone() if one else cur.fetchall()

db("""
delete from public.class_plan_items; delete from public.class_plans;
delete from public.question_reports;
delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments;     delete from public.student_sessions;
delete from public.students;        delete from public.classes;
delete from public.subscriptions;
delete from public.test_questions tq using public.tests t
 where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.account_members; delete from public.accounts;
delete from public.user_roles;      delete from auth.users;
""")

with sync_playwright() as pw:
    br  = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 1280, "height": 900})
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=TEST_CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))
    pg.on("dialog", lambda d: d.accept())

    pg.goto(PANEL); pg.wait_for_timeout(400)
    pg.click("#btnSwap")
    pg.fill("#fname", "Plan Muellim"); pg.fill("#email", "pln@t.az")
    pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=8000)
    pg.select_option("#atype", "tutor")
    pg.fill("#aname", "Plan hesabi"); pg.click("#btnSetup")
    pg.wait_for_selector("#gForm", timeout=8000)
    AID = db("select id::text i from public.accounts", one=True)["i"]
    UID = db("select id::text i from auth.users where email='pln@t.az'", one=True)["i"]
    db("""insert into public.classes (id, account_id, teacher_id, kind, name, join_code)
          values ('cccc1111-0000-0000-0000-0000000000e9', %s, %s,
                  'tutor_group', 'Plan qrupu', 'KODPLE01')""", (AID, UID))

    print("A · Abunəsiz: kilid kartı")
    pg.goto(PANEL + "#/g/cccc1111-0000-0000-0000-0000000000e9"); pg.reload()
    pg.wait_for_selector(".plock", timeout=8000)
    ok("abunə paketi" in pg.inner_text(".plock"), "kilid karti gorunur")

    print("B · Abunə ilə: plan qurulur")
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select %s, p.id, 'active', now() + interval '30 days'
            from public.plans p where p.slug = 'repetitor-25'""", (AID,))
    pg.reload()
    pg.wait_for_selector("#btnPlOpen", timeout=8000)
    ok(not pg.locator("#btnPlMk").is_visible(), "plan formasi yigilmis gelir - bir setir + «Planı qur»")
    pg.click("#btnPlOpen"); pg.wait_for_selector("#btnPlMk", timeout=8000)
    pg.wait_for_function("document.querySelectorAll('#plSub option').length > 1", timeout=8000)
    subs = pg.locator("#plSub option").all_inner_texts()
    ndb = db("select count(distinct subject_id) n from public.topics "
             "where level_id is not null", one=True)["n"]
    ok(len(subs) == ndb, "yalniz movzu agaci olan fennler", (len(subs), ndb))
    pg.select_option("#plSub", "riyaziyyat")
    pg.select_option("#plLev", SINIF)
    pg.click("#btnPlMk")
    pg.wait_for_selector(".plan", timeout=8000)
    # Plan YARPAQLARDAN dolur (db/101): alt movzusu olan movzu ozu ders
    # deyil, onun alt movzulari dersdir.  Butun movzulari saysaq, alt
    # movzu elave edilen kimi bu yoxlama sinar (bir defe sindi).
    ntop = db("""select count(*) n from public.topics t
                  join public.subjects s on s.id=t.subject_id
                  join public.levels l on l.id=t.level_id
                 where s.slug='riyaziyyat' and l.code=%s
                   and not exists (select 1 from public.topics c
                                    where c.parent_id = t.id)""",
              (SINIF,), one=True)["n"]
    assert ntop > 0, "yarpaq movzu yoxdur"
    duz = db("""select count(*) n from public.topics t
                  join public.subjects s on s.id=t.subject_id
                  join public.levels l on l.id=t.level_id
                 where s.slug='riyaziyyat' and l.code=%s
                   and t.parent_id is not null""", (SINIF,), one=True)["n"]
    assert duz == 0, ("SINIF=%s artiq fesillidir - A-I bolmeleri duz plan "
                      "isteyir, basqa sinif sec" % SINIF)
    head = pg.inner_text(".plan .plhead").replace("\n", " ")
    ok(("0 / %d" % ntop) in head, "irelileyis 0/N gorunur", head)
    # CSS text-transform metni boyutdur - metn yox, quruluş yoxlanır
    ok(pg.locator(".plcur [data-pldone]").count() == 1,
       "cari movzu ve Keçildi duymesi var")

    print("C · «Keçildi» → təklif → test + tapşırıq")
    pg.locator("[data-pldone]").click()
    pg.wait_for_selector(".ploffer", timeout=8000)
    ok("Yoxlama testi yığılsınmı" in pg.inner_text(".ploffer"), "teklif cixir")
    pg.fill("#plCnt", "5")
    pg.locator("[data-pltest]").click()
    # .ok sinfi .plrow.done ile toqqusur - netice qutusu plm- konteynerindedir
    pg.wait_for_selector(".plan [id^='plm-'] a", timeout=10000)
    ok("tapşırıq verildi" in pg.inner_text(".plan [id^='plm-']"), "netice mesaji")
    t = db("""select t.id::text i,
                     (select count(*) from public.test_questions tq
                       where tq.test_id = t.id) nq
                from public.tests t where t.owner_type='educator'""", one=True)
    ok(t and t["nq"] == 5, "test 5 sualliqdir", t and t["nq"])
    ok(bool(db("select 1 ok from public.assignments where test_id = %s", (t["i"],), one=True)),
       "tapsiriq bazada var")
    head = pg.inner_text(".plan .plhead").replace("\n", " ")
    ok(("1 / %d" % ntop) in head, "irelileyis 1/N oldu", head)

    print("D · Siyahı, vərəq linki, geri qaytarma")
    pg.locator(".plan details:not(.plgrp):not(.plnext) > summary").click(); pg.wait_for_timeout(300)
    ok(pg.locator(".plrow").count() == ntop, "butun movzular siyahida",
       pg.locator(".plrow").count())
    ok(pg.locator(".plrow.done").count() == 1, "kecilmis isarelenib")
    ok(pg.locator(".plrow .pltest").count() == 1, "veraq linki var")
    pg.locator("[data-plundo]").click()
    pg.wait_for_timeout(900)
    head = pg.inner_text(".plan .plhead").replace("\n", " ")
    ok(("0 / %d" % ntop) in head, "geri qaytarma isledi", head)

    print("E · Yenidən keçildi → «Sonra» yolu")
    pg.locator("[data-pldone]").click()
    pg.wait_for_selector(".ploffer", timeout=8000)
    pg.locator("[data-plskip]").click()
    pg.wait_for_timeout(300)
    ok(pg.locator(".ploffer").count() == 0, "teklif baglanir")

    print("F · Sonradan test: siyahıdan «test yığ»")
    pg.locator("[data-pldone]").click()          # movzu 2 kecildi
    pg.wait_for_selector(".ploffer", timeout=8000)
    pg.locator("[data-plskip]").click()          # helelik test yigilmir
    pg.wait_for_timeout(300)
    pg.locator(".plan details:not(.plgrp):not(.plnext) > summary").click(); pg.wait_for_timeout(300)
    ok(pg.locator("[data-plmk]").count() == 1, "kecilmis movzuda «test yığ» var",
       pg.locator("[data-plmk]").count())
    pg.locator("[data-plmk]").click()
    pg.wait_for_selector(".ploffer", timeout=4000)
    pg.fill("#plCnt", "4")
    pg.locator("[data-pltest]").click()
    pg.wait_for_selector(".plan [id^='plm-'] a", timeout=10000)
    ok("tapşırıq verildi" in pg.inner_text(".plan [id^='plm-']"),
       "sonradan test yigildi")
    n2 = db("select count(*) n from public.tests where owner_type='educator'",
            one=True)["n"]
    ok(n2 == 2, "ikinci test bazada var", n2)
    pg.locator(".plan details:not(.plgrp):not(.plnext) > summary").click(); pg.wait_for_timeout(300)
    ok(pg.locator("[data-plmk]").count() == 0, "test yigilandan sonra duyme itir")
    ok(pg.locator(".plrow .pltest").count() == 2, "iki movzuda veraq linki var",
       pg.locator(".plrow .pltest").count())


    print("G · Birgə test: 2 mövzu seçilir, qarışıq yığılır")
    ok(pg.locator(".plck").count() == 2, "kecilmis movzularda secim qutusu var",
       pg.locator(".plck").count())
    pg.locator(".plck").nth(0).check()
    pg.wait_for_timeout(200)
    ok(pg.locator("[data-plmulti]").count() == 0, "tek secimde duyme cixmir")
    pg.locator(".plck").nth(1).check()
    pg.wait_for_selector("[data-plmulti]", timeout=4000)
    ok("2 mövzudan" in pg.inner_text("[data-plmulti]"), "birge duyme cixir")
    pg.locator("[data-plmulti]").click()
    pg.wait_for_selector(".ploffer", timeout=4000)
    ok("qarışıq" in pg.inner_text(".ploffer"), "qarisiq teklif qutusu")
    pg.fill("#plCnt", "6")
    pg.locator("[data-pltest]").click()
    pg.wait_for_selector(".plan [id^='plm-'] a", timeout=10000)
    t3 = db("""select t.id::text i, t.title,
                      (select count(*) from public.test_questions tq
                        where tq.test_id = t.id) nq
                 from public.tests t
                where t.owner_type='educator' and t.title like '%%qarışıq%%'""",
            one=True)
    ok(bool(t3), "qarisiq test bazada var")
    ok(t3 and t3["nq"] == 6, "qarisiq test 6 sualliqdir", t3 and t3["nq"])
    ok(bool(db("select 1 ok from public.assignments where test_id = %s",
               (t3["i"],), one=True)), "qarisiq teste tapsiriq verildi")
    ok(not db("select 1 ok from public.class_plan_items where test_id = %s",
              (t3["i"],), one=True), "qarisiq test item-e baglanmir")

    print("H · Adaptiv plan: ortalama, tarix, zəif mövzuda «təkrar yığ»")
    db("""insert into public.students (account_id, class_id, created_by,
                                       full_name, display_name, login_code)
          select c.account_id, c.id, c.teacher_id, 'Plan Sagird', 'Plan S.', 'PLANSGE1'
            from public.classes c where c.id = 'cccc1111-0000-0000-0000-0000000000e9'""")
    t1 = db("""select test_id::text t from public.class_plan_items
                where test_id is not null order by ord limit 1""", one=True)["t"]
    db("""insert into public.attempts (student_id, test_id, class_id, status,
                                       finished_at, score, max_score, percent)
          select s.id, %s, s.class_id, 'submitted', now(), 2, 5, 40
            from public.students s where s.login_code = 'PLANSGE1'""", (t1,))
    pg.reload()
    pg.wait_for_selector(".plan details:not(.plgrp):not(.plnext) > summary", timeout=8000)
    head = pg.inner_text(".plan .plhead").replace("\n", " ")
    ok("%" in head, "basliqda faiz gorunur", head)
    pg.locator(".plan details:not(.plgrp):not(.plnext) > summary").click(); pg.wait_for_timeout(300)
    ok(pg.locator(".plavg").count() == 1, "movzu ortalamasi cipi var",
       pg.locator(".plavg").count())
    ok("40%" in pg.inner_text(".plavg"), "ortalama 40%-dir")
    ok(pg.locator(".pldate").count() >= 2, "kecilme tarixleri gorunur",
       pg.locator(".pldate").count())
    ok(pg.locator(".plmk.plre").count() == 1, "zeif movzuda «təkrar yığ» var")
    pg.locator(".plmk.plre").click()
    pg.wait_for_selector(".ploffer", timeout=4000)
    pg.fill("#plCnt", "4")
    pg.locator("[data-pltest]").click()
    pg.wait_for_selector(".plan [id^='plm-'] a", timeout=10000)
    t1b = db("""select test_id::text t from public.class_plan_items
                 where test_id is not null order by ord limit 1""", one=True)["t"]
    ok(t1b != t1, "tekrar test item-e baglandi (yeni test)")
    ok(bool(db("select 1 ok from public.assignments where test_id = %s",
               (t1b,), one=True)), "tekrar teste tapsiriq verildi")


    print("I · Alt mövzular: plan dərs səviyyəsinə enir")
    #  Bu ana qeder bazada alt movzu YOX idi - plan feslerle isleyirdi
    #  (bugunku hal).  Indi bir fesle 3 alt movzu elave edib plani
    #  yeniden yigiriq: setirler artiq DERSDIR, fesil ise onlari
    #  qruplasdiran etiketdir.
    CLS = "cccc1111-0000-0000-0000-0000000000e9"
    n_before = db("""select count(*) n from public.class_plan_items i
                       join public.class_plans p on p.id = i.plan_id
                      where p.class_id = %s""", (CLS,), one=True)["n"]
    #  IKI fesle alt movzu veririk: "yalniz cari feslin bloku aciqdir"
    #  serti tek fesille ozu-ozune kecirdi - yoxlama menasiz olurdu.
    db("""insert into public.topics (subject_id, level_id, parent_id, slug, name, sort)
          select t.subject_id, t.level_id, t.id, t.slug || '-d' || g,
                 'Ders ' || g, g * 10
            from (select t2.*, row_number() over (order by t2.sort) rn
                    from public.topics t2
                    join public.class_plans p2 on p2.subject_id = t2.subject_id
                                              and p2.level_id  = t2.level_id
                   where p2.class_id = %s and t2.parent_id is null) t
            cross join generate_series(1,3) g
           where t.rn <= 2""", (CLS,))

    #  plani silib yeniden qururuq - movcud planlar toxunulmur, bu
    #  qesdendir; muellim "Planı sil" ile teze quruluşa kecir
    pg.reload(); pg.wait_for_selector(".plan details:not(.plgrp):not(.plnext) > summary", timeout=8000)
    pg.locator(".plan details:not(.plgrp):not(.plnext) > summary").first.click(); pg.wait_for_timeout(300)
    #  dialoq dinleyicisi suite-in evvelinde onsuz da qeydiyyatdadir
    #  (setir 55) - ikincisini elave etmek "already handled" verir
    pg.locator("[data-pldel]").click()
    pg.wait_for_selector("#btnPlOpen", timeout=8000); pg.click("#btnPlOpen")
    pg.wait_for_selector("#btnPlMk", timeout=8000)
    pg.wait_for_function(
        "document.querySelectorAll('#plSub option').length > 1", timeout=8000)
    pg.select_option("#plSub", "riyaziyyat")
    pg.select_option("#plLev", SINIF)
    pg.click("#btnPlMk")
    pg.wait_for_selector(".plan", timeout=10000)

    n_after = db("""select count(*) n from public.class_plan_items i
                      join public.class_plans p on p.id = i.plan_id
                     where p.class_id = %s""", (CLS,), one=True)["n"]
    #  iki fesil 3-er alt movzuya bolundu: 2 setir gedir, 6 setir gelir
    ok(n_after == n_before + 4, "setir sayi yarpaqlara gore artir",
       "%d -> %d" % (n_before, n_after))
    #  ovladi olan fesil setir kimi DUSMEMELIDIR
    bad = db("""select count(*) n from public.class_plan_items i
                  join public.class_plans p on p.id = i.plan_id
                  join public.topics t on t.id = i.topic_id
                 where p.class_id = %s
                   and exists (select 1 from public.topics c
                                where c.parent_id = t.id)""", (CLS,), one=True)["n"]
    ok(bad == 0, "ovladi olan fesil plan setiri kimi dusmur", bad)

    head = pg.inner_text(".plan .plhead").replace("\n", " ")
    ok("dərs" in head, "basliqda vahid «ders»dir (fesil yox)", head)
    ok("Ders 1" in pg.inner_text(".plcur"), "novbeti setir ARTIQ dersdir",
       pg.inner_text(".plcur").replace("\n", " ")[:60])
    ok(pg.locator(".plcur .plgn").count() == 1, "novbeti kartda feslin adi var",
       pg.inner_text(".plcur .plgn") if pg.locator(".plcur .plgn").count() else "")

    pg.locator(".plan > details > summary").first.click(); pg.wait_for_timeout(300)
    ok(pg.locator(".plgrp").count() == 2, "iki fesil bloku cixir",
       pg.locator(".plgrp").count())
    ok("0/3" in pg.inner_text(".plgrp .plgc"), "fesilde ders sayi gorunur",
       pg.inner_text(".plgrp .plgc"))
    #  cari dersin fesli ACIQ, O BIRISI yigilmis olmalidir
    ok(pg.locator(".plgrp[open]").count() == 1,
       "YALNIZ cari feslin bloku aciqdir", pg.locator(".plgrp[open]").count())
    ok(pg.locator(".plgrp:not([open])").count() == 1,
       "o biri fesil YIGILMIS gelir",
       pg.locator(".plgrp:not([open])").count())

    print("J · «Test yığ» yalnız fəsil bitəndə")
    ok(pg.locator(".plgrp .plmk").count() == 0,
       "fesil bitmeden hec bir dersde «test yığ» yoxdur")
    for i in range(3):
        pg.locator("[data-pldone]").first.click()
        pg.wait_for_timeout(900)
    pg.locator(".plan > details > summary").first.click(); pg.wait_for_timeout(300)
    ok(pg.locator(".plgrp .plmk").count() == 1,
       "fesil bitende YALNIZ bir «test yığ» cixir",
       pg.locator(".plgrp .plmk").count())
    #  birinci fesil bitdi -> cari ders IKINCI fesildedir -> indi o aciqdir
    ok(pg.locator(".plgrp[open]").count() == 1,
       "aciq blok NOVBETI fesle kecir", pg.locator(".plgrp[open]").count())
    ok("3/3" in pg.inner_text(".plgrp .plgc"), "fesil tam kecilmis gorunur",
       pg.inner_text(".plgrp .plgc"))

    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails))
    for f in fails: print("  - " + f)
    sys.exit(1)
print("PLAN: BUTUN YOXLAMALAR KECDI")
