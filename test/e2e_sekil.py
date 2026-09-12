#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sualin sekli (db/188): sagird gorur, muellim gorur, pis unvan cizilmir.

Niye test lazimdir: sekil GORUNMEYEN axindir - sual metni onsuz da
cixir, sekil dususe hec bir xeta vermir, sadece yoxa cixir.  Ustelik
burada tehlukesizlik serti var: SVG <img> ile cizilmelidir (skript
islemesin) ve yalniz duzgun unvan qebul edilmelidir.

Yoxlanir:
  A  sagird test ekraninda sekil <img> kimi cixir, unvan data-URI-dir
  B  sekil INNERHTML-e dusmur - sehifede <svg> elementi yaranmir
  C  pis unvan (bazadaki qapi asilsa bele) EKRANDA da cizilmir
  D  muellim: sual bankinda ve kagiz vereqde sekil gorunur
"""
import sys
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

ROOT = "http://127.0.0.1:8010/"
APP = ROOT + "sagird/index.html"
PANEL = ROOT + "muellim/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
BLOCK = "**://*.supabase.co/**"
CFG = """window.CFG = {SUPABASE_URL:"http://127.0.0.1:54321",
  SUPABASE_ANON_KEY:"test-anon-key", STUDENT_URL:"http://127.0.0.1:8010/sagird/",
  SHOW_PLANS:false};"""
SVG = ('<svg viewBox="0 0 200 130"><path d="M20 110 L180 110 L60 20 Z" fill="none" '
       'stroke="#1a2233" stroke-width="3"/>'
       '<text x="24" y="104" font-family="sans-serif" font-size="14">A</text></svg>')

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
delete from public.question_reports; delete from public.attempt_answers;
delete from public.attempts; delete from public.assignments;
delete from public.student_sessions; delete from public.students;
delete from public.classes;
delete from public.test_questions tq using public.tests t
 where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.question_options o using public.questions q
 where q.id = o.question_id and q.owner_type = 'educator';
delete from public.questions where owner_type = 'educator';
delete from public.subscriptions;
delete from public.account_members; delete from public.accounts;
delete from public.user_roles; delete from auth.users;
insert into auth.users (id, email, raw_user_meta_data) values
  ('a1a1a1a1-0000-0000-0000-0000000000f1','sk@t.az','{"full_name":"Muellim"}');
insert into public.accounts (id, type, name, owner_id) values
  ('b1b1b1b1-0000-0000-0000-0000000000f1','tutor','Qrup','a1a1a1a1-0000-0000-0000-0000000000f1');
insert into public.account_members values
  ('b1b1b1b1-0000-0000-0000-0000000000f1','a1a1a1a1-0000-0000-0000-0000000000f1',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('c1c1c1c1-0000-0000-0000-0000000000f1','b1b1b1b1-0000-0000-0000-0000000000f1',
   'a1a1a1a1-0000-0000-0000-0000000000f1','tutor_group','3-B qrupu','QRUPSKL1');
insert into public.students (id, account_id, class_id, created_by, full_name,
                             display_name, login_code) values
  ('d1d1d1d1-0000-0000-0000-0000000000f1','b1b1b1b1-0000-0000-0000-0000000000f1',
   'c1c1c1c1-0000-0000-0000-0000000000f1','a1a1a1a1-0000-0000-0000-0000000000f1',
   'Aysu Məmmədova','Aysu M.','SEKILKOD');
""")
if not db("select 1 from public.tests where owner_type='platform' limit 1", one=True):
    db(open("db/07_seed_tests.sql", encoding="utf-8").read())

#  Testin BUTUN suallarina sekil qosulur.  Niye hamisina: cehd
#  suallari QARISDIRIR - bir suala qosanda ekranda birinci gelen
#  bəzən sekilsiz olurdu, test de "sekil yoxdur" deyirdi.
QIDS = [r["i"] for r in db("""select q.id::text i from public.questions q
            join public.test_questions tq on tq.question_id = q.id
            join public.tests t on t.id = tq.test_id and t.slug = 'riy-3-vurma-1'
           order by tq.ord""")]
db("""update public.questions set media_url = app.svg_uri(%s)
       where id = any(%s::uuid[])""", (SVG, QIDS))
r0 = db("select media_url m, body b from public.questions where id = %s::uuid", (QIDS[0],), one=True)
uri = r0["m"]; QBODY = r0["b"]
print("A · Şəkil bazaya yazıldı")
ok(uri and uri.startswith("data:image/svg+xml,"), "data-URI yarandi", (uri or "")[:46])
ok("xmlns" in (uri or ""), "xmlns funksiyanin ozu elave etdi (SVG-de yox idi)")

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 430, "height": 900})
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))

    print("B · Şagird test ekranında görünür")
    pg.goto(APP); pg.wait_for_selector("#btnIn", timeout=15000)
    pg.fill("#code", "SEKILKOD"); pg.click("#btnIn")
    pg.wait_for_selector(".test", timeout=15000)
    pg.locator(".test:not(.lock)", has_text="Vurma cədvəli").first.click()
    pg.wait_for_selector(".opt", timeout=15000)
    ok(pg.locator(".qfig img").count() == 1, "sekil cixir", pg.locator(".qfig img").count())
    src = pg.locator(".qfig img").first.get_attribute("src") or ""
    ok(src.startswith("data:image/svg+xml,"), "unvan data-URI-dir", src[:46])
    #  Sekil HEQIQETEN cizilir - qirmis sekil deyil
    w = pg.evaluate("() => { const i = document.querySelector('.qfig img');"
                    " return i ? i.naturalWidth : 0; }")
    ok(w > 0, "brauzer sekli acdi (qirmis deyil)", w)
    #  Telefonda enden asmir
    box = pg.locator(".qfig img").first.bounding_box()
    ok(box and box["width"] <= 430, "telefonda enden asmir", box and round(box["width"]))
    #  EN VACIB: SVG innerHTML-e DUSMUR - sehifede <svg> yaranmir
    nsvg = pg.evaluate("() => document.querySelectorAll('.qfig svg').length")
    ok(nsvg == 0, "SVG innerHTML-e dusmur (yalniz <img>)", nsvg)

    print("C · Pis ünvan ekranda çəkilmir")
    #  Bazadaki qapini QESDLE acıb pis unvan yaziriq: ikinci qapinin
    #  (ekran suzgeci) heqiqeten islediyini gormek ucun.
    db("alter table public.questions drop constraint questions_media_ok")
    db("""update public.questions set media_url = 'javascript:alert(1)'
           where id = any(%s::uuid[])""", (QIDS,))
    pg.goto(APP); pg.wait_for_selector(".test", timeout=15000)
    pg.locator(".test:not(.lock)", has_text="Vurma cədvəli").first.click()
    pg.wait_for_selector(".opt", timeout=15000)
    ok(pg.locator(".qfig").count() == 0, "javascript: unvani cizilmir",
       pg.locator(".qfig").count())
    db("""update public.questions set media_url = app.svg_uri(%s)
           where id = any(%s::uuid[])""", (SVG, QIDS))
    db("""alter table public.questions add constraint questions_media_ok check (
            media_url is null or (owner_type = 'platform' and length(media_url) <= 24000
            and (media_url like 'data:image/svg+xml,%%' or media_url like 'data:image/svg+xml;%%'
                 or media_url like 'https://%%')
            and position('script' in lower(media_url)) = 0
            and position('onload' in lower(media_url)) = 0
            and position('onerror' in lower(media_url)) = 0
            and position('javascript:' in lower(media_url)) = 0))""")
    ctx.close()

    print("D · Müəllim panelində")
    ctx = br.new_context(viewport={"width": 1280, "height": 900})
    mp = ctx.new_page()
    mp.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=CFG))
    mp.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    mp.goto(PANEL); mp.wait_for_timeout(500)
    mp.click("#btnSwap")
    mp.fill("#fname", "Sekil Muellim"); mp.fill("#email", "sekil@t.az")
    mp.fill("#pass", "sekilparol1"); mp.click("#btnAuth")
    mp.wait_for_selector("#btnSetup", timeout=20000)
    mp.select_option("#atype", "tutor"); mp.fill("#aname", "Sekil hesabi")
    mp.click("#btnSetup"); mp.wait_for_selector("#gForm", timeout=20000)

    #  Sual banki: hazir sual siyahida sekli ile gorunur
    mp.goto(PANEL + "#/b"); mp.wait_for_selector("#bq", timeout=20000)
    mp.fill("#bq", QBODY[:18]); mp.wait_for_timeout(1200)
    mp.wait_for_selector(".qrow", timeout=20000)
    ok(mp.locator(".qrow .qfig img").count() >= 1, "bank siyahisinda sekil var",
       mp.locator(".qrow .qfig img").count())

    #  Kagiz vereq: MUELLIMIN yigdigi test (platforma testi acilmir -
    #  «Bu test sizin deyil»; muellim bankdan test yigir, sekilli sual
    #  ora dusur).
    uid = db("select id::text i from auth.users where email='sekil@t.az'", one=True)["i"]
    tid = db("""insert into public.tests (owner_type, owner_id, title, program_id,
                  subject_id, pass_percent, is_free, status)
                select 'educator', %s::uuid, 'Şəkilli test', q.program_id, q.subject_id,
                       50, false, 'published'
                  from (select p.id program_id, qq.subject_id
                          from public.questions qq, public.programs p
                         where qq.id = %s::uuid limit 1) q
                returning id::text i""", (uid, QIDS[0]), one=True)["i"]
    db("insert into public.test_questions (test_id, question_id, ord) values (%s::uuid, %s::uuid, 1)",
       (tid, QIDS[0]))
    mp.goto(PANEL + "#/t/" + tid); mp.wait_for_selector(".paper", timeout=20000)
    ok(mp.locator(".paper .qfig img").count() == 1, "kagiz vereqde sekil var",
       mp.locator(".paper .qfig img").count())
    ok(mp.evaluate("() => document.querySelectorAll('.paper .qfig svg').length") == 0,
       "burada da yalniz <img>")
    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails))
    for f in fails: print("  - " + f)
    sys.exit(1)
print("SUAL SEKLI: BUTUN YOXLAMALAR KECDI")
