#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""GENERATOR: EKRAN NE GOSTERIRSE, HOVUZ O OLMALIDIR

22.09 (istifadeci): «yalniz bir fenn secimi var, secmiyende ama basqa
fenlerin suallari da cixir».  Sebeb: siyahi muellimin OZ fennlerine
daraldilirdi (subFilter), «Bütün fənlər» ise generatora hec bir fenn
suzgeci gondermirdi - bank butov acilirdi.  Riyaziyyat muellimi ingilis
dili suali alirdi.

Yoxlanilir:
  1. muellimin fenni secilibse «Bütün fənlər» siyahida YOXDUR
  2. fenn OZU secilmis gelir (bos qalmir)
  3. yigilan testde YALNIZ o fennin suallari olur
  4. fenn secmeyen muellimde «Bütün fənlər» QALIR (daralma yoxdur)
"""
import os, sys, time, psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
PANEL = "http://127.0.0.1:8010/muellim/index.html"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
OUT = "/tmp/claude-0/genfenn"; os.makedirs(OUT, exist_ok=True)
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
         delete from auth.users;""")
temizle()
T = int(time.time() * 1000)

#  bankda en azi iki fenn olmalidir, yoxsa yoxlama mena kesb etmir
fenler = q("""select s.slug, s.name, count(*) n
                from public.questions q
                join public.subjects s on s.id = q.subject_id
               where q.owner_type='platform' and q.status='published'
               group by s.slug, s.name order by n desc""")
print("bankdaki fennler:", ", ".join("%s(%s)" % (f["slug"], f["n"]) for f in fenler))
if len(fenler) < 2:
    print("ATLANDI: yerli bankda iki fenn yoxdur"); sys.exit(0)
mine = fenler[0]["slug"]

def hesab(p, mail, ad, fenler_siyahi):
    p.goto(PANEL); p.wait_for_selector("#email", timeout=30000)
    p.click("#btnSwap"); p.fill("#fname", ad); p.fill("#email", mail)
    p.fill("#pass", "parol1234"); p.click("#btnAuth")
    p.wait_for_selector("#btnSetup", timeout=30000)
    p.fill("#aname", ad); p.click("#btnSetup")
    p.wait_for_selector("#adminMsg", state="attached", timeout=30000)
    a = q("select a.id acc, a.owner_id own from public.accounts a join auth.users u"
          " on u.id=a.owner_id where u.email=%s", (mail,), one=True)
    q("update public.accounts set subjects = %s where id = %s", (fenler_siyahi, a["acc"]))
    #  paket: platforma hovuzu abunə ile acilir
    q("insert into public.subscriptions (account_id, plan_id, status, started_at, current_period_end)"
      " select %s, pl.id, 'active', now()-interval '5 days', now()+interval '25 days'"
      " from public.plans pl where pl.slug='repetitor-60'", (a["acc"],))
    return a

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 1280, "height": 900})
    p = ctx.new_page()
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))

    print("\n=== A) fenni SECILMIS muellim (%s) ===" % mine)
    a = hesab(p, "gf%d@t.az" % T, "Riyaziyyat müəllimi", [mine])
    p.goto(PANEL + "#/gen"); p.reload()
    p.wait_for_selector("#gsub", timeout=30000); p.wait_for_timeout(1800)
    opts = p.locator("#gsub option").all_inner_texts()
    print("  siyahi:", opts)
    yox("Bütün fənlər" not in opts, "«Bütün fənlər» siyahida YOXDUR")
    secili = p.eval_on_selector("#gsub", "e => e.value")
    yox(secili == mine, "fenn ozu secilib (%r)" % secili)
    p.screenshot(path=OUT + "/secilmis.png", full_page=True)

    #  testi yig ve suallarin fennine bax
    p.click("#btnMake")
    p.wait_for_timeout(4000)
    t = q("select id, subject_id from public.tests where owner_type='educator'"
          " order by created_at desc limit 1", one=True)
    if t:
        yad = q("""select distinct s.slug from public.test_questions x
                     join public.questions qq on qq.id = x.question_id
                     join public.subjects s on s.id = qq.subject_id
                    where x.test_id = %s and s.slug <> %s""", (t["id"], mine))
        yox(not yad, "testde YALNIZ «%s» suallari (yad: %s)" % (mine, [y["slug"] for y in yad]))
    else:
        yox(False, "test yigilmadi")
    ctx.close()

    print("\n=== B) fenn SECMEYEN muellim ===")
    ctx = br.new_context(viewport={"width": 1280, "height": 900})
    p = ctx.new_page()
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    hesab(p, "gf2%d@t.az" % T, "Fənnsiz müəllim", [])
    p.goto(PANEL + "#/gen"); p.reload()
    p.wait_for_selector("#gsub", timeout=30000); p.wait_for_timeout(1800)
    opts = p.locator("#gsub option").all_inner_texts()
    print("  siyahi:", opts)
    yox("Bütün fənlər" in opts, "fenn secmeyende «Bütün fənlər» QALIR")
    ctx.close(); br.close()
temizle()
print("\n" + ("BUTUN YOXLAMALAR KECDI" if not SEHV
              else "SEHV (%d): %s" % (len(SEHV), " | ".join(SEHV))))
sys.exit(1 if SEHV else 0)
