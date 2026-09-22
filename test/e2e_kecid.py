#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""KECID AUDITI: yeni gorunusdeki her setir basilir, hara dusduyune baxilir.

CLAUDE.md «TEHVILDEN EVVEL - MEXANIKI SIYAHI» 1-ci bendi: href yazmaq
yoxlamaq deyil.  Her kecid ACILIR, dusdugu sehifenin BASLIGI oxunur,
setrin VEDI ile uygunlugu yoxlanilir."""
import os, re, time, psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
BASE = "http://127.0.0.1:8010/"; PANEL = BASE + "muellim/index.html"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
OUT = "/tmp/claude-0/yeni"; os.makedirs(OUT, exist_ok=True)
def q(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            r = cur.fetchall(); return (r[0] if r else None) if one else r
#  Paylasilan bazani ARDIMIZCA temiz qoyuruq - yoxsa e2e_panel kimi
#  skriptler «hesab artiq var» halina dusur (auth.users-i silmirler).
def temizle():
    #  Muellimin OZ testleri ve suallari da gedir: auth.users silinende
    #  kaskad questions-a catir, amma test_questions onlari tutub saxlayir
    #  (FK xetasi).  Ona gore evvelce testler, sonra hesablar silinir.
    q("""delete from public.attempt_answers where attempt_id in (
             select a.id from public.attempts a
              join public.tests t on t.id = a.test_id
             where t.owner_type = 'educator');
           delete from public.attempts where test_id in (
             select id from public.tests where owner_type = 'educator');
           delete from public.assignments where test_id in (
             select id from public.tests where owner_type = 'educator');
           delete from public.test_questions where test_id in (
             select id from public.tests where owner_type = 'educator');
           delete from public.tests where owner_type = 'educator';
           delete from public.subscriptions; delete from public.students;
           delete from public.classes; delete from public.account_members;
           delete from public.accounts; delete from public.user_roles;
           delete from auth.users;""")
temizle()
T = int(time.time() * 1000)
with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2)
    p = ctx.new_page()
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    mail = "yni%d@t.az" % T
    p.goto(PANEL + "?yeni=1"); p.wait_for_selector("#email", timeout=30000)
    p.click("#btnSwap"); p.fill("#fname", "Leyla müəllim"); p.fill("#email", mail)
    p.fill("#pass", "parol1234"); p.click("#btnAuth")
    p.wait_for_selector("#btnSetup", timeout=30000)
    p.fill("#aname", "Leyla müəllim — riyaziyyat"); p.click("#btnSetup")
    p.wait_for_selector("#yMenu .mrow", timeout=30000); p.wait_for_timeout(900)
    h = p.evaluate("document.body.scrollHeight")
    print("BOS hesab: %d px = %.1f ekran · %d setir" % (h, h / 844.0, p.locator("#yMenu .mrow").count()))
    print("   baslangic:", p.locator("#yBas").inner_text().replace("\n", " | ")[:70])
    p.screenshot(path=OUT + "/bos.png", full_page=True)

    #  ---- hesabi doldururuq
    acc = q("select a.id acc, a.owner_id own from public.accounts a join auth.users u"
            " on u.id=a.owner_id where u.email=%s", (mail,), one=True)
    q("insert into public.subscriptions (account_id, plan_id, status, started_at, current_period_end)"
      " select %s, pl.id, 'active', now()-interval '25 days', now()+interval '5 days'"
      " from public.plans pl where pl.slug='repetitor-60'", (acc["acc"],))
    for nm, kod in (("5-ci sinif", "K1"), ("Ev qrup", "K2")):
        q("insert into public.classes (account_id,teacher_id,kind,name,join_code,level_id)"
          " select %s,%s,'tutor_group',%s,%s,l.id from public.levels l where l.code='3'",
          (acc["acc"], acc["own"], nm, kod + str(T)[-6:]))
    cls = q("select id from public.classes where account_id=%s order by name", (acc["acc"],))
    adlar = ["Ayan Məmmədova", "Murad Həsənov", "Lalə Quliyeva", "Samir Əliyev", "Nihad Cəfərov"]
    for i, ad in enumerate(adlar):
        qisa = ad.split(" ")[0] + " " + ad.split(" ")[1][0] + "."
        q("insert into public.students (account_id,class_id,created_by,full_name,display_name,"
          "login_code,is_active,created_at)"
          " values (%s,%s,%s,%s,%s,%s,true, now()-interval '20 days')",
          (acc["acc"], cls[i % 2]["id"], acc["own"], ad, qisa, "SD%s%d" % (str(T)[-5:], i)))
    tst = [r["id"] for r in q("select id from public.tests where owner_type='platform'"
                              " and title in ('Vurma cədvəli — 1','Azərbaycan dili — 1') order by title")]
    stu = [r["id"] for r in q("select id, class_id from public.students where account_id=%s", (acc["acc"],))]
    for t in tst:
        for c in cls:
            q("insert into public.assignments (class_id,test_id,assigned_by,opens_at,closes_at,max_attempts,created_at)"
              " values (%s,%s,%s,now()-interval '6 days',now()+interval '3 days',1,now()-interval '6 days')",
              (c["id"], t, acc["own"]))
    bac = [0.35, 0.5, 0.9, 0.75, 0.6]
    tops = [r["id"] for r in q("select distinct tq.topic_id id from public.test_questions x"
                               " join public.questions tq on tq.id=x.question_id"
                               " where x.test_id=%s and tq.topic_id is not null", (tst[0],))]
    for i, s in enumerate(q("select id, class_id from public.students where account_id=%s order by full_name", (acc["acc"],))):
        for r in range(3):
            for t in tst:
                q("select app.demo_attempt(%s,%s,%s,%s,%s::uuid[], now() - make_interval(days => %s))",
                  (s["id"], t, s["class_id"], bac[i], tops[:1] if i < 2 else [], 11 - i - r * 3))
    #  iki SESSIZ sagird: 20 gun evvel elave olunub, hec ne islemeyib -
    #  Icmaldaki «N sagird bir heftedir sessizdir» setri ucun
    for i, ad in enumerate(["Röya Nəbiyeva", "Tural İsmayılov"]):
        q("insert into public.students (account_id,class_id,created_by,full_name,display_name,"
          "login_code,is_active,created_at)"
          " values (%s,%s,%s,%s,%s,%s,true, now()-interval '20 days')",
          (acc["acc"], cls[i % 2]["id"], acc["own"], ad,
           ad.split(" ")[0] + " " + ad.split(" ")[1][0] + ".",
           "SS%s%d" % (str(T)[-5:], i)))
    p.goto(PANEL + "#/"); p.reload()
    p.wait_for_selector("#yMenu .mrow", timeout=30000); p.wait_for_timeout(1500)
    h = p.evaluate("document.body.scrollHeight")
    print("DOLU hesab: %d px = %.1f ekran" % (h, h / 844.0))
    print("   diqqet:", p.locator("#yDiq").inner_text().replace("\n", " | ")[:140])
    print("   menyu :", p.locator("#yMenu").inner_text().replace("\n", " | ")[:200])
    p.screenshot(path=OUT + "/dolu.png", full_page=True)
    #  ---- ders plani qururuq ki, «Bu gunun dersi» real gorunsun
    gid0 = cls[0]["id"]
    riy = q("select id from public.subjects where slug='riyaziyyat'", one=True)["id"]
    lev = q("select id from public.levels where code='3'", one=True)["id"]
    pid = q("insert into public.class_plans (class_id, subject_id, level_id)"
            " values (%s,%s,%s) returning id", (gid0, riy, lev), one=True)["id"]
    tps = q("select t.id, t.name from public.topics t"
            " where t.subject_id=%s and t.level_id=%s"
            "   and not exists (select 1 from public.topics c where c.parent_id=t.id)"
            " order by t.sort, t.name limit 7", (riy, lev))
    for i, t0 in enumerate(tps):
        #  ilk iki ders kecilib, qalanlari yox
        q("insert into public.class_plan_items (plan_id, topic_id, ord, done_at)"
          " values (%s,%s,%s, case when %s then now() - interval '3 days' end)",
          (pid, t0["id"], i + 1, i < 2))

    #  yazili ev tapsirigi: hec kim etmeyib - qrup menyusunda «diqqet» setri
    q("insert into public.homework (class_id, created_by, body, due)"
      " values (%s,%s,%s, current_date + 1)",
      (gid0, acc["own"], "Çalışma kitabı, səh. 41 — 1-6 misallar"))

    #  ---- qrup menyusu
    gid = gid0
    p.goto(PANEL + "#/g/" + str(gid)); p.reload()
    p.wait_for_selector("#gMenu .mrow", timeout=30000); p.wait_for_timeout(2000)
    h = p.evaluate("document.body.scrollHeight")
    print("QRUP menyusu: %d px = %.1f ekran" % (h, h / 844.0))
    print("   diqqet:", p.locator("#gDiq").inner_text().replace("\n", " | ")[:120])
    print("   menyu :", p.locator("#gMenu").inner_text().replace("\n", " | ")[:220])
    p.screenshot(path=OUT + "/qrup.png", full_page=True)
    #  ---- sagirdler bolmesi
    p.goto(PANEL + "#/g/" + str(gid) + "/s"); p.reload()
    p.wait_for_selector("#stu .mrow", timeout=30000); p.wait_for_timeout(900)
    h = p.evaluate("document.body.scrollHeight")
    print("SAGIRDLER: %d px · %d setir" % (h, p.locator("#stu .mrow").count()))
    p.screenshot(path=OUT + "/sagirdler.png", full_page=True)
    #  ---- ders plani bolmesi
    p.goto(PANEL + "#/g/" + str(gid0) + "/p"); p.reload()
    p.wait_for_selector("#prep .prep, #planBox", timeout=30000); p.wait_for_timeout(1500)
    print("DERS PLANI:", p.inner_text("#main")[:160].replace("\n", " | "))
    p.screenshot(path=OUT + "/plan.png", full_page=True)

    #  ================= KECID AUDITI =================
    XETA = []
    def bashq():
        t = p.locator("#band h1")
        return (t.inner_text().strip() if t.count() else p.inner_text("#main")[:40]).replace("\n", " ")

    def kecidler(unvan, qab):
        """qabdaki her <a>/<button> setrini basib hara dusduyunu yazir"""
        p.goto(PANEL + unvan); p.reload()
        p.wait_for_selector(qab + " .mrow", timeout=30000); p.wait_for_timeout(1200)
        n = p.locator(qab + " .mrow").count()
        cix = []
        for i in range(n):
            p.goto(PANEL + unvan); p.reload()
            p.wait_for_selector(qab + " .mrow", timeout=30000); p.wait_for_timeout(1000)
            r = p.locator(qab + " .mrow").nth(i)
            ad = r.inner_text().replace("\n", " · ")[:52]
            r.click(); p.wait_for_timeout(1400)
            h = (p.evaluate("location.hash") or "#/")
            b = bashq()
            cix.append((ad, h, b))
            if b.startswith("Qruplarınız") and "qrup" not in ad.lower():
                XETA.append(unvan + " : «" + ad + "» -> Qruplar (olu kecid)")
            if "Yüklənir" in b or not b.strip():
                XETA.append(unvan + " : «" + ad + "» -> bos sehife " + h)
            #  CLAUDE.md 1-ci bend, 2-ci sual: setrin VEDI ile acilan sehife
            #  uyusurmu?  Setirde «X» varsa, X hemin sehifede GORUNMELIDIR.
            #  (Istifadeci: «5 şagird kimdir? hanı?» - setir movzunu ve
            #   sagird sayini yazirdi, acilan sehifede ne biri var idi, ne o biri.)
            p.wait_for_timeout(700)
            #  ad bezen ZOLAQDA olur (sehifenin basligi), bezen govdede -
            #  ikisine de baxilir
            mtn = p.inner_text("#band") + " " + p.inner_text("#main")
            m = re.search("«([^»]{3,60})»", ad)
            if m and m.group(1) not in mtn:
                XETA.append(unvan + " : setir «" + m.group(1) +
                            "» ved edir, acilan sehifede yoxdur (" + h + ")")
            #  Istifadeci: «ilkinde say ver, acilanda hemin sagirdleri
            #  gostersin».  Setirde «N sagird» varsa, acilan sehifede
            #  DEQIQ N setir olmalidir - 5 deyib 7 gostermek olmaz.
            ms = re.search(r"(\d+)\s+şagird", ad)
            if ms and (h.startswith("#/sus") or h.startswith("#/zm")):
                say = int(ms.group(1))
                var = p.locator("#suBox .mrow, #zmBox .mrow").count()
                if var != say:
                    XETA.append(unvan + " : setir " + str(say) + " şagird deyir, "
                                "acilan sehifede " + str(var) + " setir var (" + h + ")")
        return cix

    print("\n=== KECID AUDITI ===")
    for unvan, qab, ad in (("#/", "#yDiq", "Icmal · diqqet"),
                           ("#/", "#yMenu", "Icmal · menyu"),
                           ("#/sus", "#suBox", "Sessiz sagirdler"),
                           ("#/nt", "#ntQ", "Neticeler · qruplar"),
                           ("#/nt", "#ntZ", "Neticeler · zeif movzular"),
                           ("#/nt", "#ntS", "Neticeler · son cavablar"),
                           ("#/g/" + str(gid), "#gDiq", "Qrup · diqqet"),
                           ("#/g/" + str(gid), "#gMenu", "Qrup menyusu")):
        print("\n-- " + ad + " (" + unvan + ")")
        for a, h, b in kecidler(unvan, qab):
            print("   %-52s -> %-34s %s" % (a, h, b))

    #  ---- ADMIN: «Idareetme» bendi Icmalda gorunur ve isleyir
    #  (Istifadeci: «admin sehifesinde admin panele giris ucun buton
    #   var idi, hani o?» - yeni menyuda unudulmusdu.)
    q("insert into public.user_roles (user_id, role) values (%s,'admin')"
      " on conflict do nothing", (acc["own"],))
    p.goto(PANEL + "#/"); p.reload()
    p.wait_for_selector("#yMenu .mrow", timeout=30000); p.wait_for_timeout(1500)
    adm = p.locator("#yMenu .mrow").filter(has_text="\u0130dar\u0259etm\u0259")
    if not adm.count():
        XETA.append("#/ : admin ucun \u00abIdareetme\u00bb bendi yoxdur")
    else:
        adm.first.click(); p.wait_for_timeout(1800)
        hh = p.evaluate("location.hash") or ""
        bb = bashq()
        print("\n-- Admin")
        print("   %-52s -> %-10s %s" % ("\u0130dar\u0259etm\u0259", hh, bb))
        if not hh.startswith("#/adm"):
            XETA.append("#/ : \u00abIdareetme\u00bb -> " + hh + " (idareetmeye aparmir)")
    q("delete from public.user_roles where user_id=%s", (acc["own"],))

    print("\n=== NETICE ===")
    if XETA:
        for e in XETA: print("  XETA:", e)
        raise SystemExit("OLU KECID VAR: %d" % len(XETA))
    print("  butun kecidler ved etdikleri yere aparir")

#  Paylasilan bazani ardimizca temiz qoyuruq - yoxsa e2e_panel kimi
#  skriptler «hesab artiq var» halina dusur.
temizle()
print("KECID AUDITI: BUTUN YOXLAMALAR KECDI")
