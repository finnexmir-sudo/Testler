#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""FESIL BITMEMIS DERSDE «test yig» yoxdur - SEBEBI YAZILIRMI?

22.09: Qizbest muellim «Bəzi mövzularda testlər yoxdur» yazdi.  Olcu
gosterdi ki bank bos deyil (her fenn/sinif 100%), sebeb basqadir:
«test yig» duymesi YALNIZ feslin son dersinde cixir (101-deki can_test).
3480 plan setrinin 2846-sinda (82%) duyme yoxdur ve IZAH da yox idi -
muellim bos yer gorurdu.

Bu skript izahi yoxlayir:
  1. fesilde 3 ders var, 1-ci kecilib  -> «fəsil sonunda · 1/3», duyme YOX
  2. 2-ci kecilib                      -> «fəsil sonunda · 2/3»
  3. hamisi kecilib                    -> SON dersde «test yig», izah YOX
  4. kecilmemis dersde ne duyme, ne izah
"""
import os, sys, time, psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
BASE = "http://127.0.0.1:8010/"; PANEL = BASE + "muellim/index.html"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
OUT = "/tmp/claude-0/plangozle"; os.makedirs(OUT, exist_ok=True)
SEHV = []
def yox(sert, ad):
    print(("  OK   " if sert else "  SEHV ") + ad)
    if not sert: SEHV.append(ad)
def q(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args) if args else cur.execute(sql)
        if cur.description:
            r = cur.fetchall(); return (r[0] if r else None) if one else r
def temizle():
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
           delete from auth.users;
           delete from public.topics where slug like 'gz-test-%';""")
temizle()
T = int(time.time() * 1000)

#  --- FESIL + 3 ALT MOVZU.  Yerli bazada hazir agacin alt movzusu
#  yoxdur, ona gore ozumuz qururuq - yoxlama deterministik olsun.
riy = q("select id from public.subjects where slug='riyaziyyat'", one=True)["id"]
lev = q("select id from public.levels where code='3'", one=True)["id"]
fes = q("insert into public.topics (subject_id, level_id, parent_id, name, slug, sort)"
        " values (%s,%s,null,'Kvadrat tənliklər','gz-test-fesil',900) returning id",
        (riy, lev), one=True)["id"]
alt = []
for i, nm in enumerate(["Tam kvadrat ayırmaqla həll",
                        "Diskriminant düsturu",
                        "Viet teoremi"]):
    alt.append(q("insert into public.topics (subject_id, level_id, parent_id, name, slug, sort)"
                 " values (%s,%s,%s,%s,%s,%s) returning id",
                 (riy, lev, fes, nm, "gz-test-alt%d" % i, 901 + i), one=True)["id"])

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 1280, "height": 900})
    p = ctx.new_page()
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    mail = "gz%d@t.az" % T
    p.goto(PANEL + "?yeni=1"); p.wait_for_selector("#email", timeout=30000)
    p.click("#btnSwap"); p.fill("#fname", "Nurlan müəllim"); p.fill("#email", mail)
    p.fill("#pass", "parol1234"); p.click("#btnAuth")
    p.wait_for_selector("#btnSetup", timeout=30000)
    p.fill("#aname", "Nurlan müəllim — riyaziyyat"); p.click("#btnSetup")
    #  «#main» karkasda hemise var - hesab yaranmamis kecerdi.  Icmalin
    #  ILK setrini gozleyirik: o gorunende hesab bazadadir.
    p.wait_for_selector("#yMenu .mrow", timeout=30000)

    acc = q("select a.id acc, a.owner_id own from public.accounts a join auth.users u"
            " on u.id=a.owner_id where u.email=%s", (mail,), one=True)
    q("insert into public.subscriptions (account_id, plan_id, status, started_at, current_period_end)"
      " select %s, pl.id, 'active', now()-interval '5 days', now()+interval '25 days'"
      " from public.plans pl where pl.slug='repetitor-60'", (acc["acc"],))
    gid = q("insert into public.classes (account_id,teacher_id,kind,name,join_code,level_id)"
            " values (%s,%s,'tutor_group','9-cu sinif',%s,%s) returning id",
            (acc["acc"], acc["own"], "GZ" + str(T)[-6:], lev), one=True)["id"]
    pid = q("insert into public.class_plans (class_id, subject_id, level_id)"
            " values (%s,%s,%s) returning id", (gid, riy, lev), one=True)["id"]
    for i, tid in enumerate(alt):
        q("insert into public.class_plan_items (plan_id, topic_id, ord) values (%s,%s,%s)",
          (pid, tid, i + 1))

    def setirler():
        p.goto(PANEL + "?yeni=1#/g/" + str(gid) + "/p"); p.reload()
        p.wait_for_selector(".card.plan", timeout=30000)
        #  butun fesiller acilsin - alt setirler <details> icinde ola biler
        p.evaluate("document.querySelectorAll('.card.plan details')"
                   ".forEach(function(d){d.open=true})")
        p.wait_for_timeout(700)
        out = []
        for i in range(p.locator(".plrow").count()):
            out.append(p.locator(".plrow").nth(i).inner_text().replace("\n", " "))
        return out

    def kecildi(n):
        q("update public.class_plan_items set done_at = now() - make_interval(days => %s)"
          " where plan_id = %s and ord = %s", (5 - n, pid, n))

    print("\n1) fesilde 3 ders, 1-cisi kecilib")
    kecildi(1)
    r = setirler()
    yox(len(r) >= 3, "plan setirleri gorunur (%d)" % len(r))
    s1 = [x for x in r if "Tam kvadrat" in x]
    yox(bool(s1), "1-ci ders setri tapildi")
    if s1:
        yox("fəsil sonunda" in s1[0], "1-ci derste izah var: %r" % s1[0][:90])
        yox("1/3" in s1[0], "izahda mövqe 1/3 yazilib")
        yox("test yığ" not in s1[0], "1-ci derste «test yig» YOXDUR")
    s3 = [x for x in r if "Viet" in x]
    if s3:
        yox("fəsil sonunda" not in s3[0] and "test yığ" not in s3[0],
            "kecilmemis derste ne duyme, ne izah var")
    p.screenshot(path=OUT + "/1-ders.png", full_page=True)

    print("\n2) 2-ci ders de kecilib")
    kecildi(2)
    r = setirler()
    s2 = [x for x in r if "Diskriminant" in x]
    yox(bool(s2), "2-ci ders setri tapildi")
    if s2:
        yox("2/3" in s2[0], "2-ci derste mövqe 2/3 yazilib: %r" % s2[0][:90])
        yox("test yığ" not in s2[0], "2-ci derste hele «test yig» yoxdur")

    print("\n3) fesil bitdi - son derste duyme cixir")
    kecildi(3)
    r = setirler()
    s3 = [x for x in r if "Viet" in x]
    yox(bool(s3), "son ders setri tapildi")
    if s3:
        yox("test yığ" in s3[0], "son derste «test yig» var: %r" % s3[0][:90])
        yox("fəsil sonunda" not in s3[0], "son derste izah YOXDUR (duyme var)")
    s1 = [x for x in r if "Tam kvadrat" in x]
    if s1:
        yox("fəsil sonunda" in s1[0], "1-ci derste izah qalir")
    p.screenshot(path=OUT + "/3-ders.png", full_page=True)
    br.close()

#  temizle() evvel gelir: sinif silinende class_plan_items kaskadla
#  gedir, yoxsa movzunu silmek FK-ya dusur.
temizle()
print("\n" + ("BUTUN YOXLAMALAR KECDI" if not SEHV
              else "SEHV (%d): %s" % (len(SEHV), " | ".join(SEHV))))
sys.exit(1 if SEHV else 0)
