#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Tapsiriq ekraninda hazir test secimi: fennler MUELLIMIN profilindeki fennlere gore (29.09).

Muellim: «profilde secdiyi fennlere gore gelen fennler, sual yigda etmisik,
amma burda qalib» - test secimi butun fennleri gosterirdi.

  A  fenn secilmeyib: hamisi gorunur (evvelki davranis)
  B  bir fenn secilib: yalniz o fennin testleri, fenn cipleri YOXDUR
  C  iki fenn secilib: iki cip (ucuncu yox)
  D  muellimin OZ testi basqa fennde olsa da siyahida qalir
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



T = int(time.time()); MAIL = "pf%d@t.az" % T

def context(br, w, h):
    ctx = br.new_context(viewport={"width": w, "height": h})
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)[:140]))
    return ctx, pg

def ac(br, GA):
    ctx, pg = context(br, 1280, 1000)
    pg.goto(PANEL); pg.wait_for_timeout(700)
    pg.fill("#email", MAIL); pg.fill("#pass", "pfparol123"); pg.click("#btnAuth"); pg.wait_for_timeout(3000)
    pg.goto(PANEL + "#/a/" + GA); pg.reload()
    pg.wait_for_selector("#aList .trow", timeout=20000)
    return ctx, pg

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx0, pg0 = context(br, 1280, 1000)
    pg0.goto(PANEL); pg0.wait_for_timeout(600); pg0.click("#btnSwap")
    pg0.fill("#fname", "Fenn Test"); pg0.fill("#email", MAIL)
    pg0.fill("#pass", "pfparol123"); pg0.click("#btnAuth")
    pg0.wait_for_selector("#btnSetup", timeout=20000)
    pg0.select_option("#atype", "tutor"); pg0.fill("#aname", "Fenn hesabi")
    pg0.click("#btnSetup"); pg0.wait_for_timeout(4500)
    uid = db("select id::text i from auth.users where email=%s", (MAIL,), one=True)["i"]
    acc = db("select id::text i from public.accounts where owner_id=%s::uuid", (uid,), one=True)["i"]
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select %s::uuid, p.id, 'active', now() + interval '30 days'
            from public.plans p where p.slug = 'repetitor-25'""", (acc,))
    GA = db("""insert into public.classes (account_id, teacher_id, kind, name, join_code, level_id)
               select %s::uuid, %s::uuid, 'tutor_group', '3-cu sinif', 'PFKOD003', l.id
                 from public.levels l where l.code='3' returning id::text i""", (acc, uid), one=True)["i"]
    ctx0.close()

    print("A · Fənn seçilməyib — hamısı görünür")
    db("update public.accounts set subjects = '{}' where id=%s::uuid", (acc,))
    ctx, pg = ac(br, GA)
    chips = pg.locator("#aSubs .chip").all_inner_texts()
    ok("Azərbaycan dili" in chips and "Riyaziyyat" in chips, "iki fenn cipi var", chips)
    ok("Azərbaycan dili" in pg.inner_text("#aList"), "Azərbaycan dili testi siyahıdadır")
    ctx.close()

    print("B · Bir fənn seçilib (riyaziyyat)")
    db("update public.accounts set subjects = '{riyaziyyat}' where id=%s::uuid", (acc,))
    ctx, pg = ac(br, GA)
    ok(pg.locator("#aSubs").count() == 0, "fenn cipleri YOXDUR (tek fenn)", pg.locator("#aSubs").count())
    lt = pg.inner_text("#aList")
    ok("Azərbaycan dili" not in lt, "basqa fennin testi siyahida YOXDUR")
    ok("Vurma cədvəli" in lt, "oz fennin testleri var")
    pg.screenshot(path="/tmp/claude-0/pf_bir_fenn.png")
    ctx.close()

    print("C · İki fənn (az-dili + riyaziyyat) və D · öz test")
    db("update public.accounts set subjects = '{az-dili,riyaziyyat}' where id=%s::uuid", (acc,))
    ctx, pg = ac(br, GA)
    chips = pg.locator("#aSubs .chip").all_inner_texts()
    ok(chips[:1] == ["Hamısı"] and set(chips[1:]) == {"Azərbaycan dili", "Riyaziyyat"}, "yalniz secilen iki fenn cipi", chips)
    ctx.close()
    #  ucuncu fenn: muellimin OZ testi (tarix) - subjects-de yoxdur
    az = db("select subject_id::text s, program_id::text p, level_id::text l from public.tests where slug is not null and title like 'Azərbaycan dili%%' limit 1", one=True)
    tarix = db("select id::text i from public.subjects where slug='tarix'", one=True)
    if tarix:
        tid = db("""insert into public.tests (owner_type, owner_id, program_id, subject_id, level_id, title, status)
                    values ('educator', %s::uuid, %s::uuid, %s::uuid, %s::uuid, 'Öz tarix testim', 'published') returning id::text i""",
                 (uid, az["p"], tarix["i"], az["l"]), one=True)["i"]
        db("""insert into public.test_questions (test_id, question_id, ord)
              select %s::uuid, question_id, ord from public.test_questions tq join public.tests t on t.id=tq.test_id
               where t.title like 'Azərbaycan dili%%' limit 3""", (tid,))
        db("update public.accounts set subjects = '{riyaziyyat}' where id=%s::uuid", (acc,))
        ctx, pg = ac(br, GA)
        ok("Öz tarix testim" in pg.inner_text("#aList"), "D · oz testi basqa fennde olsa da siyahidadir")
        ctx.close()
    else:
        ok(False, "tarix fenni bazada yoxdur - D yoxlanmadi")
    br.close()

print()
if fails:
    print("SINDI (%d):" % len(fails))
    for f in fails: print("  -", f)
    sys.exit(1)
print("HAMISI KECDI")
