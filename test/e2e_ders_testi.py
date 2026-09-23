#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""DERS TESTI (db/222): «test yig» nisanli hovuzdan yigirmi?

Bank sessiyasi suallara 'ders:<slug>' nisani yazir.  222 plan testini
hemin nisanla daraldir - amma YALNIZ nisanli sual app.ders_min()-e
catanda.  Catmayanda kohne kimi FESIL hovuzundan yigilir.

Iki fesil qurulur:
  AZ  - 19 nisanli + 15 nisansiz  (hedd 20, catmir)  -> FESIL testi
  BOL - 20 nisanli + 15 nisansiz  (hedd 20, catir)   -> DERS testi

Yoxlanilir:
  1. BOL: test 10 sualdir (app.ders_test_count) ve HAMISI nisanlidir
  2. AZ : test 15 sualdir (kohne olcu) ve icinde nisansiz sual VAR
  3. hec bir halda generator «kifayet sual yoxdur» xetasi atmir
"""
import os, sys, time, psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
PANEL = "http://127.0.0.1:8010/muellim/index.html"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
OUT = "/tmp/claude-0/derstesti"; os.makedirs(OUT, exist_ok=True)
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
             select id from public.questions where ext_key like 'dt-%');
         delete from public.questions where ext_key like 'dt-%';""")
def movzu_sil():
    q("""delete from public.class_plan_items where topic_id in (
             select id from public.topics where slug like 'dt-%');
         delete from public.question_options where question_id in (
             select id from public.questions where ext_key like 'dt-%');
         delete from public.questions where ext_key like 'dt-%';
         delete from public.topics where slug like 'dt-%';""")
temizle(); movzu_sil()
T = int(time.time() * 1000)

HEDD = q("select app.ders_min() n", one=True)["n"]
DTEST = q("select app.ders_test_count() n", one=True)["n"]
print("hedd = %d · ders testi = %d sual" % (HEDD, DTEST))

subj = q("select id from public.subjects where slug='riyaziyyat'", one=True)["id"]
lev = q("select id from public.levels where code='8'", one=True) \
      or q("select id from public.levels where code='3'", one=True)
lev = lev["id"]

def fesil(ad, slug, nisanli, nisansiz):
    f = q("insert into public.topics (subject_id,level_id,parent_id,name,slug,sort)"
          " values (%s,%s,null,%s,%s,900) returning id",
          (subj, lev, ad, "dt-" + slug), one=True)["id"]
    d = q("insert into public.topics (subject_id,level_id,parent_id,name,slug,sort)"
          " values (%s,%s,%s,%s,%s,901) returning id",
          (subj, lev, f, ad + " dərsi", "dt-" + slug + "-d"), one=True)["id"]
    tag = "ders:dt-" + slug + "-d"
    #  DIQQET: suallar BIR-BIRINE BENZEMEMELIDIR, yoxsa generator onlari
    #  tekrar sayib atir (13_generator.sql):
    #    - govde oxsarligi >= 0.95  -> atilir
    #    - eyni duzgun cavab ceil(say/7) defeden cox -> atilir
    #  Ilk variantda hamisinin cavabi «düz» idi: 20 sualdan 2-si kecdi
    #  ve «kifayet sual yoxdur» xetasi cixdi.  Bank ucun de eyni qayda:
    #  20 sual demek 20 FERQLI sual demekdir.
    qelib = ["%d ədədinin kvadratı neçədir?",
             "Tənliyin kökünü tapın: x - %d = 0",
             "%d ədədini 2-yə vurun, nəticə?",
             "Ardıcıllığın %d-ci həddi nədir?",
             "%d ilə 4-ün cəmi neçədir?",
             "Kəsrin surəti %d olarsa, nə alınır?",
             "%d ədədinin yarısı nədir?"]
    for i in range(nisanli + nisansiz):
        nisan = [tag] if i < nisanli else []
        govde = qelib[i % len(qelib)] % (i * 3 + 7)
        duz = str(i * 11 + 13)          # her sualda AYRI duzgun cavab
        qq = q("insert into public.questions (owner_type,subject_id,level_id,topic_id,"
               "kind,body,status,tags,ext_key) values ('platform',%s,%s,%s,'single',"
               "%s,'published',%s,%s) returning id",
               (subj, lev, f, "%s · %s" % (ad, govde), nisan,
                "dt-%s-%d" % (slug, i)), one=True)["id"]
        q("insert into public.question_options (question_id,ord,body,is_correct)"
          " values (%s,1,%s,true),(%s,2,%s,false),(%s,3,%s,false)",
          (qq, duz, qq, str(i * 11 + 14), qq, str(i * 11 + 15)))
    return f, d, tag

fAZ, dAZ, tagAZ = fesil("Fəsil AZ", "az", HEDD - 1, 15)
fBOL, dBOL, tagBOL = fesil("Fəsil BOL", "bol", HEDD, 15)
print("AZ: %d nişanlı · BOL: %d nişanlı" % (HEDD - 1, HEDD))

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 1280, "height": 1000})
    p = ctx.new_page()
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    #  RPC xetasi sessizce udulmasin - 400 gelirse derhal gorunsun
    p.on("response", lambda r: print("  SERVER %d: %s" % (r.status, r.url[-60:]))
         if r.status >= 400 else None)
    mail = "dt%d@t.az" % T
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
            (acc["acc"], acc["own"], "DT" + str(T)[-6:], lev), one=True)["id"]
    pid = q("insert into public.class_plans (class_id,subject_id,level_id)"
            " values (%s,%s,%s) returning id", (gid, subj, lev), one=True)["id"]
    for i, d in enumerate((dAZ, dBOL)):
        q("insert into public.class_plan_items (plan_id,topic_id,ord,done_at)"
          " values (%s,%s,%s, now() - make_interval(days => %s))",
          (pid, d, i + 1, 3 - i))

    def yig(ders_id, ad):
        p.goto(PANEL + "?yeni=1#/g/" + str(gid) + "/p"); p.reload()
        p.wait_for_selector(".card.plan", timeout=30000)
        p.evaluate("document.querySelectorAll('.card.plan details')"
                   ".forEach(function(d){d.open=true})")
        p.wait_for_timeout(700)
        it = q("select id from public.class_plan_items where plan_id=%s and topic_id=%s",
               (pid, ders_id), one=True)["id"]
        b = p.locator('[data-plmk="%s"]' % it)
        if not b.count():
            yox(False, "%s: «test yig» duymesi yoxdur" % ad); return None
        #  «test yig» derhal yigmir - TESDIQ qutusu acir (planOfferLate),
        #  sual sayi orada 10 gelir.  Ikinci duyme: data-pltest.
        b.first.click()
        p.wait_for_timeout(900)
        ok = p.locator('[data-pltest="%s"]' % it)
        if not ok.count():
            yox(False, "%s: tesdiq duymesi cixmadi" % ad); return None
        ok.first.click()
        p.wait_for_timeout(6000)
        t = q("select test_id from public.class_plan_items where id=%s", (it,), one=True)
        return t["test_id"] if t else None

    print("\n=== BOL fəsli — nişan yetir, DƏRS testi gözlənilir ===")
    tid = yig(dBOL, "BOL")
    if tid:
        rows = q("""select count(*) n,
                           count(*) filter (where qq.tags @> array[%s]) nis
                      from public.test_questions x
                      join public.questions qq on qq.id = x.question_id
                     where x.test_id = %s""", (tagBOL, tid), one=True)
        print("  test: %d sual, %d-i nişanlı" % (rows["n"], rows["nis"]))
        ad = q("select title from public.tests where id=%s", (tid,), one=True)["title"]
        print("  test adı:", ad)
        yox(ad.startswith("Fəsil BOL dərsi —"), "BOL: test adı DƏRSDƏNDİR (%r)" % ad)
        yox(rows["n"] == DTEST, "BOL: test %d sualdir (dərs ölçüsü)" % DTEST)
        yox(rows["nis"] == rows["n"], "BOL: HAMISI nişanlıdır — yad sual sızmır")
    else:
        yox(False, "BOL: test yigilmadi")

    print("\n=== AZ fəsli — nişan çatmır, FƏSİL testi gözlənilir ===")
    tid = yig(dAZ, "AZ")
    if tid:
        rows = q("""select count(*) n,
                           count(*) filter (where qq.tags @> array[%s]) nis
                      from public.test_questions x
                      join public.questions qq on qq.id = x.question_id
                     where x.test_id = %s""", (tagAZ, tid), one=True)
        print("  test: %d sual, %d-i nişanlı" % (rows["n"], rows["nis"]))
        ad = q("select title from public.tests where id=%s", (tid,), one=True)["title"]
        print("  test adı:", ad)
        #  Ad DETERMINISTIKDIR: ders rejimi YARPAGIN adini yazir,
        #  fesil rejimi VALIDEYNIN.  Tesadufe baglı deyil.
        yox(ad.startswith("Fəsil AZ —"), "AZ: test adı FƏSİLDƏNDİR (%r)" % ad)
        yox(rows["nis"] < rows["n"], "AZ: nişansız sual var — fəsil hovuzundan yığılıb")
    else:
        yox(False, "AZ: test yigilmadi")
    p.screenshot(path=OUT + "/plan.png", full_page=True)
    br.close()

temizle(); movzu_sil()
print("\n" + ("BUTUN YOXLAMALAR KECDI" if not SEHV
              else "SEHV (%d): %s" % (len(SEHV), " | ".join(SEHV))))
sys.exit(1 if SEHV else 0)
