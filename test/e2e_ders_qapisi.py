#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""DERS QAPISI (db/903): «test yig» dugmesi DERS-DERS acilir.

Server her plan setri ucun deyir: ders_hazir (app.ders_sual_sayi >= app.ders_min).
Bir fesil, uc ders (sintetik - real bank boyudukce netice deyismesin):
  A - 25 nisanli sual   -> HAZIR
  B - 5 nisanli sual    -> hazir deyil
  C - 25 nisanli sual   -> HAZIR (feslin SON dersi)
Feslin qalan 30 sualı nisansizdir.

Yoxlanilir:
  1. hazir ders: setirde «test yig»; basanda qutu «yalniz bu dersden» deyir;
     test adi dersin adidir, HAMISI dersin nisanini dasiyir
  2. hazir olmayan ders: «fesil sonunda · N/M», «test yig» YOXDUR
  3. kecilmemis ders: nə dugme, nə izah
  4. feslin sonu: fesil basliginda «fesilden test yig»; qutu «bu fesilden» deyir;
     fesil testi NISANSIZ suallar da alir; son dersin oz testi ayri qalir
  5. «geri al» - dugmeler de itir
  6. eyni dersden iki defe: suallar (mumkun oldugu qeder) ferqli (223)
  7. server: hazir olmayan dersde p_scope='ders' xeta verir; iki parametrli kohne cagiris isleyir
"""
import os, sys, time, psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
PANEL = "http://127.0.0.1:8010/muellim/index.html"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
OUT = "/tmp/claude-0/dersqapisi"; os.makedirs(OUT, exist_ok=True)
SEHV = []
def yox(sert, ad, ek=""):
    print(("  OK   " if sert else "  SEHV ") + ad + (("  " + str(ek)) if ek != "" else ""))
    if not sert: SEHV.append(ad)
def q(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args) if args else cur.execute(sql)
        if cur.description:
            r = cur.fetchall(); return (r[0] if r else None) if one else r
def temizle():
    q("""delete from public.attempt_answers where attempt_id in (
             select a.id from public.attempts a join public.tests t
               on t.id = a.test_id where t.owner_type = 'educator');
         delete from public.attempts where test_id in (
             select id from public.tests where owner_type = 'educator');
         delete from public.assignments where test_id in (
             select id from public.tests where owner_type = 'educator');
         delete from public.test_questions where test_id in (
             select id from public.tests where owner_type = 'educator');
         delete from public.tests where owner_type = 'educator';
         delete from public.feedback where true;
         delete from public.subscriptions; delete from public.students;
         delete from public.classes; delete from public.account_members;
         delete from public.accounts; delete from public.user_roles;
         delete from auth.users;
         delete from public.question_options where question_id in (
             select id from public.questions where ext_key like 'dq-%');
         delete from public.questions where ext_key like 'dq-%';""")
def movzu_sil():
    q("""delete from public.class_plan_items where topic_id in (
             select id from public.topics where slug like 'dq-%');
         delete from public.question_options where question_id in (
             select id from public.questions where ext_key like 'dq-%');
         delete from public.questions where ext_key like 'dq-%';
         delete from public.topics where slug like 'dq-%';""")
temizle(); movzu_sil()
T = int(time.time() * 1000)
HEDD = q("select app.ders_min() n", one=True)["n"]
DTEST = q("select app.ders_test_count() n", one=True)["n"]

subj = q("select id from public.subjects where slug='riyaziyyat'", one=True)["id"]
lev = q("select id from public.levels where code='8'", one=True)["id"]

FES = "Qapı fəsli"
fes = q("insert into public.topics (subject_id,level_id,parent_id,name,slug,sort)"
        " values (%s,%s,null,%s,'dq-fesil',900) returning id", (subj, lev, FES), one=True)["id"]
QELIB = ["%d ədədinin kvadratı neçədir?", "Tənliyin kökünü tapın: x - %d = 0",
         "%d ədədini 2-yə vurun, nəticə?", "Ardıcıllığın %d-ci həddi nədir?",
         "%d ilə 4-ün cəmi neçədir?", "Kəsrin surəti %d olarsa, nə alınır?",
         "%d ədədinin yarısı nədir?"]
sayac = [0]
def suallar(ad, nisan, n, top=None):
    for i in range(n):
        sayac[0] += 1
        k = sayac[0]
        qq = q("insert into public.questions (owner_type,subject_id,level_id,topic_id,kind,body,"
               "status,tags,ext_key) values ('platform',%s,%s,%s,'single',%s,'published',%s,%s) returning id",
               (subj, lev, top or fes, "%s · %s" % (ad, QELIB[k % len(QELIB)] % (k * 3 + 7)),
                [nisan] if nisan else [], "dq-%d" % k), one=True)["id"]
        q("insert into public.question_options (question_id,ord,body,is_correct)"
          " values (%s,1,%s,true),(%s,2,%s,false),(%s,3,%s,false)",
          (qq, str(k * 11 + 13), qq, str(k * 11 + 14), qq, str(k * 11 + 15)))
DERS = {}
for j, (ad, slug, nis) in enumerate((("Dərs A", "dq-a", HEDD + 5), ("Dərs B", "dq-b", 5), ("Dərs C", "dq-c", HEDD + 5))):
    DERS[ad] = dict(slug=slug, id=q("insert into public.topics (subject_id,level_id,parent_id,name,slug,sort)"
                    " values (%s,%s,%s,%s,%s,%s) returning id", (subj, lev, fes, ad, slug, 901 + j), one=True)["id"])
    suallar(ad, "ders:" + slug, nis)
suallar("Fəsil ümumi", None, 30)
#  Ikinci fesil, tek ders (D): plan «Kecildi»den sonra da CARI ders qalsin - yoxsa
#  (plan bitibse) «Kecildi» teklif qutusunu gosterecek yer olmur.
fes2 = q("insert into public.topics (subject_id,level_id,parent_id,name,slug,sort)"
         " values (%s,%s,null,'Sonrakı fəsil','dq-fesil2',910) returning id", (subj, lev), one=True)["id"]
#  Ucuncu fesil: iki HAZIR OLMAYAN ders (E, F) - «Kecildi»den sonra teklifin vaxti yoxlanir
fes3 = q("insert into public.topics (subject_id,level_id,parent_id,name,slug,sort)"
         " values (%s,%s,null,'Üçüncü fəsil','dq-fesil3',905) returning id", (subj, lev), one=True)["id"]
dE = q("insert into public.topics (subject_id,level_id,parent_id,name,slug,sort)"
       " values (%s,%s,%s,'Dərs E','dq-e',906) returning id", (subj, lev, fes3), one=True)["id"]
dF = q("insert into public.topics (subject_id,level_id,parent_id,name,slug,sort)"
       " values (%s,%s,%s,'Dərs F','dq-f',907) returning id", (subj, lev, fes3), one=True)["id"]
suallar("Üçüncü fəsil", None, 20, fes3)
dD = q("insert into public.topics (subject_id,level_id,parent_id,name,slug,sort)"
       " values (%s,%s,%s,'Dərs D','dq-d',911) returning id", (subj, lev, fes2), one=True)["id"]
suallar("Sonrakı fəsil", None, 20, fes2)
print("hedd=%d · ders testi=%d sual · A/C: %d nişanlı, B: 5 nişanlı, +30 nişansız" % (HEDD, DTEST, HEDD + 5))

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 1280, "height": 1000})
    p = ctx.new_page()
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    p.on("response", lambda r: print("  SERVER %d: %s" % (r.status, r.url[-60:])) if r.status >= 400 else None)
    mail = "dq%d@t.az" % T
    p.goto(PANEL + "?yeni=1"); p.wait_for_selector("#email", timeout=30000)
    p.click("#btnSwap"); p.fill("#fname", "Nurlan müəllim"); p.fill("#email", mail)
    p.fill("#pass", "parol1234"); p.click("#btnAuth")
    p.wait_for_selector("#btnSetup", timeout=30000)
    p.fill("#aname", "Nurlan — riyaziyyat"); p.click("#btnSetup")
    p.wait_for_selector("#adminMsg", state="attached", timeout=30000)
    acc = q("select a.id acc, a.owner_id own from public.accounts a join auth.users u"
            " on u.id=a.owner_id where u.email=%s", (mail,), one=True)
    q("insert into public.subscriptions (account_id, plan_id, status, started_at, current_period_end)"
      " select %s, pl.id, 'active', now()-interval '5 days', now()+interval '25 days'"
      " from public.plans pl where pl.slug='repetitor-60'", (acc["acc"],))
    gid = q("insert into public.classes (account_id,teacher_id,kind,name,join_code,level_id)"
            " values (%s,%s,'tutor_group','8-ci sinif',%s,%s) returning id",
            (acc["acc"], acc["own"], "DQ" + str(T)[-6:], lev), one=True)["id"]
    pid = q("insert into public.class_plans (class_id,subject_id,level_id) values (%s,%s,%s) returning id",
            (gid, subj, lev), one=True)["id"]
    ITEM = {}
    for i, ad in enumerate(("Dərs A", "Dərs B", "Dərs C")):
        ITEM[ad] = q("insert into public.class_plan_items (plan_id,topic_id,ord) values (%s,%s,%s) returning id",
                     (pid, DERS[ad]["id"], i + 1), one=True)["id"]
    ITEM["Dərs E"] = q("insert into public.class_plan_items (plan_id,topic_id,ord) values (%s,%s,4) returning id", (pid, dE), one=True)["id"]
    ITEM["Dərs F"] = q("insert into public.class_plan_items (plan_id,topic_id,ord) values (%s,%s,5) returning id", (pid, dF), one=True)["id"]
    ITEM["Dərs D"] = q("insert into public.class_plan_items (plan_id,topic_id,ord) values (%s,%s,6) returning id", (pid, dD), one=True)["id"]
    def kecdi(ad, gun):
        q("update public.class_plan_items set done_at = now() - make_interval(days => %s) where id=%s", (gun, ITEM[ad]))

    def ac(page=None):
        pg = page or p
        pg.goto(PANEL + "?yeni=1#/g/" + str(gid) + "/p"); pg.reload()
        pg.wait_for_selector(".card.plan", timeout=30000)
        pg.evaluate("document.querySelectorAll('.card.plan details').forEach(function(d){d.open=true})")
        pg.wait_for_timeout(800)
    def setir(ad, page=None):
        pg = page or p
        #  planTest/planDone siyahini yeniden cizir, <details> baglanir - hər oxumadan evvel ac
        pg.evaluate("document.querySelectorAll('.card.plan details').forEach(function(d){d.open=true})")
        return pg.locator(".plrow", has_text=ad).first
    def sec(ad, page=None):
        #  08.10: sətirdə «test yığ» düyməsi yoxdur - checkbox seçilir, küncdəki «Test yığ» basılır
        pg = page or p
        setir(ad, pg).locator("[data-plsel]").check()
    def yig_bas(page=None):
        (page or p).locator("[data-plsgo]").click()
    def yaz(ad):
        return setir(ad).inner_text().replace("\n", " ")
    def item_row(ad):
        return q("select test_id::text t, fesil_test_id::text f from public.class_plan_items where id=%s", (ITEM[ad],), one=True)
    def testin(tid):
        r = q("select t.title, count(*) n, array_agg(x.question_id::text) ids from public.tests t"
              " join public.test_questions x on x.test_id=t.id where t.id=%s group by t.title", (tid,), one=True)
        return r
    def nisanli(tid, slug):
        return q("select count(*) n, count(*) filter (where qq.tags @> array[%s]) nis from public.test_questions x"
                 " join public.questions qq on qq.id=x.question_id where x.test_id=%s", ("ders:" + slug, tid), one=True)

    print("\n=== 1-3 · A, B keçilib, C keçilməyib ===")
    kecdi("Dərs A", 3); kecdi("Dərs B", 2)
    ac()
    yox(setir("Dərs A").locator("[data-plsel]").count() == 1, "A (hazır, keçilib): «test yığ» görünür")
    yox(setir("Dərs A").locator("[data-plsel]").count() == 1 and p.locator("[data-plsgo]").count() == 0, "A: checkbox var, seçilməyibsə küncdə düymə yoxdur")
    yox("fəsil sonunda" not in yaz("Dərs A"), "A (hazır): «fəsil sonunda» izahı YOXDUR — dərsin öz düyməsi var")
    yox(setir("Dərs B").locator("[data-plsel]").count() == 0 and "test yığ" not in yaz("Dərs B"),
        "B (hazır deyil): «test yığ» YOXDUR")
    yox("fəsil sonunda" in yaz("Dərs B") and "2/3" in yaz("Dərs B"), "B: «fəsil sonunda · 2/3» qalır", yaz("Dərs B")[:80])
    yox(setir("Dərs C").locator("[data-plsel]").count() == 0 and "fəsil sonunda" not in yaz("Dərs C") and "test yığ" not in yaz("Dərs C"),
        "C (keçilməyib): nə düymə, nə izah", yaz("Dərs C")[:60])
    yox(p.locator(".plgrp > summary .plgm").count() == 0, "fəsil bitməyib: başlıqda «fəsildən test yığ» yoxdur")
    p.screenshot(path=OUT + "/1-masaustu.png", full_page=True)

    print("\n=== 1 · A: «test yığ» → dərs testi ===")
    sec("Dərs A"); yig_bas(); p.wait_for_timeout(700)
    box = p.locator(".ploffer").inner_text()
    yox("yalnız bu dərsdən" in box and "bu fəsildən" not in box, "qutu «yalnız bu dərsdən» deyir", box.replace("\n", " ")[:120])
    yox(p.locator("#plCnt").count() == 0, "dərs testində sual sayı sahəsi yoxdur (ölçünü server qoyur)")
    p.locator(".card.plan").screenshot(path=OUT + "/4-qutu-ders-masaustu.png")
    p.locator('[data-pltest="%s"]' % ITEM["Dərs A"]).click(); p.wait_for_timeout(6000)
    ra = item_row("Dərs A")
    yox(bool(ra["t"]) and ra["f"] is None, "A: test_id yazıldı, fesil_test_id boş")
    if ra["t"]:
        t = testin(ra["t"]); n = nisanli(ra["t"], "dq-a")
        yox(t["title"] == "Dərs A — yoxlama", "vərəqin başlığı dərsin adıdır", t["title"])
        yox(t["n"] == DTEST and n["nis"] == n["n"], "%d sual, hamısı dərsin nişanını daşıyır" % DTEST, "%d/%d" % (n["nis"], n["n"]))
    TA1 = ra["t"]
    p.wait_for_timeout(500)
    yox(setir("Dərs A").locator("[data-plmk]").count() == 0 and setir("Dərs A").locator("a.pltest").count() == 1,
        "A sətrində «test yığ» yox olub, «vərəq» qalıb")

    print("\n=== 4 · C keçildi (Keçildi düyməsi) ===")
    p.locator('[data-pldone="%s"]' % ITEM["Dərs C"]).click(); p.wait_for_timeout(1500)
    box = p.locator(".ploffer").inner_text() if p.locator(".ploffer").count() else ""
    yox("Dərs C" in box and "yalnız bu dərsdən" in box, "«Keçildi»dən sonrakı qutu (C hazırdır): «yalnız bu dərsdən»", box.replace("\n", " ")[:110])
    p.locator("[data-plskip]").first.click(); p.wait_for_timeout(300)
    setir("Dərs B")
    yox(p.locator(".plgrp > summary .plgm").count() == 1, "fəsil bitdi: başlıqda «fəsildən test yığ» var")
    yox(setir("Dərs C").locator("[data-plsel]").count() == 1, "C sətrində də «test yığ» (dərs) var — ikisi ayrıdır")
    yox("fəsil sonunda" in yaz("Dərs B"), "B hələ də hazır deyil: izah qalır")
    p.evaluate("document.querySelectorAll('.card.plan details').forEach(function(d){d.open=true})")
    p.screenshot(path=OUT + "/2-masaustu-fesil-bitdi.png", full_page=True)

    print("\n=== 4 · fəsil testi (nişansız hovuz) ===")
    p.locator(".plgrp > summary .plgm").click(); p.wait_for_timeout(700)
    box = p.locator(".ploffer").inner_text()
    yox("bu fəsildən" in box and "yalnız bu dərsdən" not in box and FES in box, "qutu «bu fəsildən» deyir, fəsli adlandırır", box.replace("\n", " ")[:120])
    yox(p.locator("#plCnt").count() == 1, "fəsil testində sual sayı sahəsi var")
    def merkez():
        a = p.locator("#plCnt").bounding_box(); b = p.locator(".ploffer [data-pltest]").bounding_box()
        return a["y"] + a["height"] / 2, b["y"] + b["height"] / 2
    ya, yb = merkez()
    yox(abs(ya - yb) <= 1, "«Yığ və tapşırıq ver» düyməsi «10» sahəsi ilə EYNİ səviyyədədir", "mərkəzlər: %.1f / %.1f" % (ya, yb))
    p.locator(".card.plan").screenshot(path=OUT + "/5-qutu-fesil-masaustu.png")
    p.locator('[data-pltest="%s"][data-sc="fesil"]' % ITEM["Dərs C"]).click(); p.wait_for_timeout(6000)
    rc = item_row("Dərs C")
    yox(bool(rc["f"]), "C: fesil_test_id yazıldı")
    if rc["f"]:
        t = testin(rc["f"]); n = nisanli(rc["f"], "dq-c")
        yox(t["title"] == FES + " — yoxlama", "fəsil vərəqinin başlığı fəslin adıdır", t["title"])
        yox(n["nis"] < n["n"], "fəsil testi nişansız / başqa dərsin sualını da alır", "%d/%d C-dən" % (n["nis"], n["n"]))
    yox(p.locator(".plgrp > summary .plgm").count() == 0, "fəsil testi yığılandan sonra başlıq düyməsi yox olur")
    yox("fəsil vərəqi" in yaz("Dərs C") and setir("Dərs C").locator("[data-plsel]").count() == 1,
        "C sətri: «fəsil vərəqi» dərsin öz testi sayılmır — «test yığ» qalır", yaz("Dərs C")[:80])

    print("\n=== C: dərsin öz testi fəsil testini pozmur ===")
    sec("Dərs C"); yig_bas(); p.wait_for_timeout(600)
    p.locator('[data-pltest="%s"][data-sc="ders"]' % ITEM["Dərs C"]).click(); p.wait_for_timeout(6000)
    rc2 = item_row("Dərs C")
    yox(rc2["f"] == rc["f"] and rc2["t"] and rc2["t"] != rc2["f"], "fesil_test_id toxunulmaz, test_id dərs testidir")
    if rc2["t"]:
        yox(testin(rc2["t"])["title"] == "Dərs C — yoxlama", "dərs vərəqi «Dərs C — yoxlama»")
    yox(yaz("Dərs C").count("vərəq") >= 1 and setir("Dərs C").locator("[data-plmk]").count() == 0, "C sətrində düymə yox olub, vərəq var")

    print("\n=== 5 · «geri al» ===")
    p.locator('[data-plundo="%s"]' % ITEM["Dərs C"]).click(); p.wait_for_timeout(1500)
    yox(setir("Dərs C").locator("[data-plsel]").count() == 0 and "fəsil sonunda" not in yaz("Dərs C"), "geri alınan dərsdə düymə də yoxdur", yaz("Dərs C")[:60])
    yox(p.locator(".plgrp > summary .plgm").count() == 0, "fəsil yenə bitməyib: başlıq düyməsi yoxdur")
    kecdi("Dərs C", 1)

    print("\n=== 6 · eyni dərsdən iki dəfə: suallar fərqli (223) ===")
    #  A-nin ilk testinden sonra 25 nisanli sualin 10-u istifade olunub; fesil ve C testleri de
    #  A-dan sual ala biler.  Gozlenti: ikinci test evvelce VERILMEMIS A suallarindan baslayir.
    used = q("select distinct x.question_id::text i from public.assignments a join public.test_questions x on x.test_id=a.test_id"
             " where a.class_id=%s", (gid,))
    used = set(r["i"] for r in used)
    poolA = set(r["i"] for r in q("select id::text i from public.questions where tags @> array['ders:dq-a']"))
    unseen = len(poolA - used)
    q("update public.class_plan_items set test_id=null where id=%s", (ITEM["Dərs A"],))
    ac()
    sec("Dərs A"); yig_bas(); p.wait_for_timeout(600)
    p.locator('[data-pltest="%s"]' % ITEM["Dərs A"]).click(); p.wait_for_timeout(6000)
    ra2 = item_row("Dərs A")
    if ra2["t"] and TA1:
        s1 = set(testin(TA1)["ids"]); s2 = set(testin(ra2["t"])["ids"])
        beklenen = max(0, DTEST - unseen)
        yox(ra2["t"] != TA1 and len(s1 & s2) <= beklenen,
            "ikinci test fərqlidir: kəsişmə %d ≤ %d (yeni suallar: %d)" % (len(s1 & s2), beklenen, unseen))
    else:
        yox(False, "ikinci test yığılmadı")

    print("\n=== server: p_scope qoruyucusu ===")
    def rpc(sql, args):
        with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
            cur.execute("select set_config('request.jwt.claim.sub', %s, false)", (str(acc["own"]),))
            try:
                cur.execute(sql, args); c.commit(); return None
            except Exception as e:
                c.rollback(); return str(e)
    e1 = rpc("select public.rpc_plan_test(%s::uuid, 10, 'ders')", (ITEM["Dərs B"],))
    yox(e1 is not None and "kifayet" in e1, "B-də p_scope='ders' — «kifayət qədər sual yoxdur» xətası (səssiz fəslə düşmür)", (e1 or "xəta yox")[:60])
    e2 = rpc("select public.rpc_plan_test(%s::uuid, 10, 'yanlis')", (ITEM["Dərs B"],))
    yox(e2 is not None, "yanlış p_scope rədd edilir")
    e3 = rpc("select public.rpc_plan_test(%s::uuid, 10)", (ITEM["Dərs B"],))
    yox(e3 is None, "iki parametrli köhnə çağırış işləyir (köhnə brauzer)", e3 or "")
    npg = q("select count(*) n from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname='rpc_plan_test'", one=True)["n"]
    yox(npg == 1, "rpc_plan_test-in tək imzası var (PostgREST iki namizəd arasında seçə bilmir)", npg)
    g = q("select count(*) n from public.class_plan_items i join public.topics t on t.id=i.topic_id where i.plan_id=%s", (pid,), one=True)["n"]

    print("\n=== hazır olmayan dərs: təklif YALNIZ fəsil bitəndə ===")
    kecdi("Dərs C", 1)
    ac()
    p.locator('[data-pldone="%s"]' % ITEM["Dərs E"]).click(); p.wait_for_timeout(1500)
    yox(p.locator(".ploffer").count() == 0, "E (hazır deyil, fəsil bitməyib): «Ev tapşırığı verilsinmi?» qutusu ÇIXMIR")
    ht = p.locator(".plhint").inner_text() if p.locator(".plhint").count() else ""
    yox("fəsil bitəndə" in ht and "1/2" in ht, "əvəzinə qısa izah: fəsil bitəndə təklif olunacaq (1/2)", ht[:100])
    yox(p.locator("[data-pltest]").count() == 0, "yarımçıq fəsildə yığma düyməsi yoxdur")
    p.locator(".card.plan").screenshot(path=OUT + "/10-yarimciq-fesil-izah.png")
    p.locator('[data-pldone="%s"]' % ITEM["Dərs F"]).click(); p.wait_for_timeout(1500)
    bx = p.locator(".ploffer").inner_text() if p.locator(".ploffer").count() else ""
    yox("Üçüncü fəsil" in bx and "fəsli bitdi" in bx and "bu fəsildən" in bx,
        "F (fəslin SON dərsi, hazır deyil): fəsil testi təklifi çıxır", bx.replace("\n", " ")[:110])
    p.locator(".card.plan").screenshot(path=OUT + "/9-fesil-bitdi-teklif.png")
    p.locator('[data-pltest="%s"][data-sc="fesil"]' % ITEM["Dərs F"]).click(); p.wait_for_timeout(6000)
    rf = item_row("Dərs F")
    yox(bool(rf["f"]) and testin(rf["f"])["title"] == "Üçüncü fəsil — yoxlama", "fəsil testi yığıldı: «Üçüncü fəsil — yoxlama»")

    print("\n=== planın SON dərsi «Keçildi» — təklif qutusu çıxır ===")
    ac()
    yox(p.locator('[data-pldone="%s"]' % ITEM["Dərs D"]).count() == 1, "D cari dərsdir («Keçildi» düyməsi var)")
    p.locator('[data-pldone="%s"]' % ITEM["Dərs D"]).click(); p.wait_for_timeout(1500)
    yox(p.locator(".plcur.done > b").count() == 1 and "Bütün dərslər keçilib" in p.locator(".plcur.done > b").inner_text(), "plan bitdi: «Bütün dərslər keçilib» (yuxarıdakı «dərs» sözü ilə eyni)")
    bx = p.locator(".ploffer").inner_text() if p.locator(".ploffer").count() else ""
    yox("Sonrakı fəsil" in bx and "fəsli bitdi" in bx and "bu fəsildən" in bx, "SON dərsdən sonra da «Ev tapşırığı verilsinmi?» çıxır (D hazır deyil → «bu fəsildən»)", bx.replace("\n", " ")[:100])
    p.locator(".card.plan").screenshot(path=OUT + "/7-son-ders-qutu.png")
    p.set_viewport_size({"width": 390, "height": 900}); p.wait_for_timeout(500)
    yox(p.evaluate("document.documentElement.scrollWidth <= window.innerWidth"), "telefonda son dərs qutusu yana sürüşmə yaratmır")
    p.locator(".ploffer").scroll_into_view_if_needed()
    p.locator(".card.plan").screenshot(path=OUT + "/8-son-ders-qutu-telefon.png")
    p.set_viewport_size({"width": 1280, "height": 1000})
    p.locator('[data-pltest="%s"]' % ITEM["Dərs D"]).click(); p.wait_for_timeout(6000)
    rd = item_row("Dərs D")
    yox(bool(rd["t"]), "son dərsdən test yığıldı və qrupa verildi")
    q("update public.class_plan_items set done_at=null, test_id=null, fesil_test_id=null where id=%s", (ITEM["Dərs D"],))
    print("\n=== telefon (390 px) ===")
    kecdi("Dərs A", 3)
    q("update public.class_plan_items set test_id=null, fesil_test_id=null where plan_id=%s", (pid,))
    ctx2 = br.new_context(viewport={"width": 390, "height": 900})
    p2 = ctx2.new_page()
    p2.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    p2.goto(PANEL + "?yeni=1"); p2.wait_for_selector("#email", timeout=30000)
    p2.fill("#email", mail); p2.fill("#pass", "parol1234"); p2.click("#btnAuth")
    p2.wait_for_selector("#yMenu .mrow", timeout=30000)
    ac(p2)
    yox(p2.evaluate("document.documentElement.scrollWidth <= window.innerWidth"), "telefonda yana sürüşmə yoxdur")
    b = setir("Dərs A", p2).locator("[data-plsel]").first
    yox(b.count() == 1 and b.is_visible(), "A: «test yığ» telefonda görünür")
    bb = b.bounding_box()
    yox(bb and bb["x"] >= 0 and bb["x"] + bb["width"] <= 390, "düymə ekranın içindədir", bb)
    p2.screenshot(path=OUT + "/3-telefon.png", full_page=True)
    b.check(); p2.wait_for_timeout(300)
    gb = p2.locator("[data-plsgo]")
    yox(gb.count() == 1 and gb.is_visible(), "telefonda küncdə «Test yığ» düyməsi çıxdı")
    gbb = gb.bounding_box()
    yox(gbb and gbb["x"] + gbb["width"] <= 390 and gbb["y"] + gbb["height"] <= 900, "düymə ekranın içindədir (kunc)", gbb)
    p2.screenshot(path=OUT + "/7-telefon-secim.png")
    gb.click(); p2.wait_for_timeout(600)
    yox(p2.evaluate("document.documentElement.scrollWidth <= window.innerWidth") and p2.locator(".ploffer").is_visible(), "telefonda təklif qutusu ekrana sığır")
    p2.locator(".ploffer").scroll_into_view_if_needed()
    p2.locator(".card.plan").screenshot(path=OUT + "/6-qutu-ders-telefon.png")
    print("\n=== 08.10 · checkbox + küncdə «Test yığ» (2+ dərs → rpc_plan_test_done) ===")
    q("update public.class_plan_items set test_id=null, fesil_test_id=null where plan_id=%s", (pid,))
    kecdi("Dərs A", 3); kecdi("Dərs C", 1)
    ac()
    yox(p.locator("[data-plexam]").count() == 0, "plan səviyyəsində köhnə düymə yoxdur")
    yox(p.locator("[data-plsgo]").count() == 0, "heç nə seçilməyib: küncdə düymə yoxdur")
    sec("Dərs A"); sec("Dərs C"); p.wait_for_timeout(300)
    yox(p.locator("[data-plsgo]").count() == 1 and "2 dərs" in p.locator("[data-plsgo]").inner_text(), "2 seçim: «Test yığ · 2 dərs»", p.locator("[data-plsgo]").inner_text())
    p.locator("[data-plsel]:checked").first.uncheck(); p.wait_for_timeout(200)
    yox("dərs" not in p.locator("[data-plsgo]").inner_text(), "1 seçim: sadəcə «Test yığ»")
    setir("Dərs A").locator("[data-plsel]").check(); p.wait_for_timeout(200)
    yig_bas(); p.wait_for_timeout(400)
    yox(p.locator("[data-plexgo]").count() == 1 and "Seçilmiş 2 dərsdən" in p.locator(".ploffer").inner_text(), "təsdiq qutusu: seçilmiş 2 dərs")
    p.locator("[data-plexgo]").click(); p.wait_for_timeout(6000)
    pe = q("select count(*) n from public.tests where gen_rule->>'pack'='done' and gen_rule->>'plan'=%s", (str(pid),), one=True)
    yox(pe["n"] == 1, "seçilmiş dərslərdən test yığıldı", pe)
    yox(p.locator('#plm-%s a[href^="#/t/"]' % pid).count() == 1, "«Testə bax» linki çıxdı")
    br.close()

temizle(); movzu_sil()
print("\n" + ("BUTUN YOXLAMALAR KECDI" if not SEHV else "SEHV (%d): %s" % (len(SEHV), " | ".join(SEHV))))
sys.exit(1 if SEHV else 0)
