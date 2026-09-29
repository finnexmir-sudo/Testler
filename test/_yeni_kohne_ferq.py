#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ONBAXIS: KOHNE gorunusde OLAN, YENIDE OLMAYAN duymeler/kecidler (29.09).

Istifadeci yeni gorunusu standart etdi ve «bezi yerleri gormurem» dedi.
Eyni dolu hesab iki gorunusde acilir, her ekranda GORUNEN idarə elementleri
(button, a[href], input, select, textarea, summary) toplanir, cixilir.
  test/tek.sh _yeni_kohne_ferq.py     ->  /tmp/claude-0/ferq/
"""
import os, sys, time, json, re
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

ROOT = "http://127.0.0.1:8010/"
PANEL = ROOT + "muellim/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
CFG = """window.CFG = {SUPABASE_URL:"http://127.0.0.1:54321",
  SUPABASE_ANON_KEY:"test-anon-key", STUDENT_URL:"http://127.0.0.1:8010/sagird/",
  PARENT_URL:"http://127.0.0.1:8010/valideyn/", SHOW_PLANS:false};"""
OUT = "/tmp/claude-0/ferq"; os.makedirs(OUT, exist_ok=True)

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            r = cur.fetchall(); return (r[0] if r else None) if one else r

db("""
delete from public.homework; delete from public.class_plan_items; delete from public.class_plans;
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
T = int(time.time()); MAIL = "fq%d@t.az" % T

JS = """() => {
  document.querySelectorAll('details').forEach(d => d.open = true);
  const vis = e => { const r = e.getBoundingClientRect(); const cs = getComputedStyle(e);
                     return r.width > 0 && r.height > 0 && cs.visibility !== 'hidden' && cs.display !== 'none'; };
  const out = [];
  document.querySelectorAll('#main button, #main a[href], #main input, #main select, #main textarea, #main summary,'
      + '#band button, #band a[href], nav a, nav button, aside a, aside button, .top button, .top a').forEach(e => {
    if (!vis(e)) return;
    let t = (e.innerText || e.value || e.getAttribute('aria-label') || e.getAttribute('placeholder') || e.title || '')
              .replace(/\\s+/g, ' ').trim().slice(0, 48);
    out.push({tag: e.tagName.toLowerCase(), id: e.id || '', t: t});
  });
  return out;
}"""

def key(c): return (c["t"].lower() or ("#" + c["id"])) if (c["t"] or c["id"]) else ""

def snap(pg, ad, hash_, tabs=None):
    pg.goto(PANEL + hash_); pg.reload(); pg.wait_for_timeout(3200)
    res = {ad: pg.evaluate(JS)}
    if tabs:
        for tab in tabs:
            try:
                pg.locator(tabs_sel[0] + ' [data-v="%s"]' % tab).click(); pg.wait_for_timeout(900)
                res[ad + " / sekme " + tab] = pg.evaluate(JS)
            except Exception as e:
                res[ad + " / sekme " + tab] = []
    return res

tabs_sel = ["#sTabs"]

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx0 = br.new_context(viewport={"width": 1280, "height": 1000})
    p0 = ctx0.new_page()
    p0.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    p0.goto(PANEL); p0.wait_for_timeout(600); p0.click("#btnSwap")
    p0.fill("#fname", "Ferq Muellim"); p0.fill("#email", MAIL); p0.fill("#pass", "fqparol123"); p0.click("#btnAuth")
    p0.wait_for_selector("#btnSetup", timeout=20000)
    p0.select_option("#atype", "tutor"); p0.fill("#aname", "Ferq hesabi"); p0.click("#btnSetup"); p0.wait_for_timeout(4500)
    uid = db("select id::text i from auth.users where email=%s", (MAIL,), one=True)["i"]
    acc = db("select id::text i from public.accounts where owner_id=%s::uuid", (uid,), one=True)["i"]
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select %s::uuid, p.id, 'active', now() + interval '30 days' from public.plans p where p.slug='repetitor-25'""", (acc,))
    G = db("""insert into public.classes (account_id, teacher_id, kind, name, join_code, level_id)
              select %s::uuid, %s::uuid, 'tutor_group', 'Ev qrup', 'FQKOD001', l.id from public.levels l where l.code='6'
              returning id::text i""", (acc, uid), one=True)["i"]
    S = []
    for i, ad in enumerate(("Aysel Məmmədova", "Murad Əliyev", "Leyla Hüseynova")):
        S.append(db("""insert into public.students (account_id, class_id, created_by, full_name, display_name, login_code, parent_code)
                       values (%s::uuid, %s::uuid, %s::uuid, %s, %s, %s, %s) returning id::text i""",
                    (acc, G, uid, ad, ad.split()[0] + " " + ad.split()[1][0] + ".", "FQS%d%d" % (i, T % 1000), "FQP%d%d" % (i, T % 1000)),
                    one=True)["i"])
    tid = db("""insert into public.tests (owner_type, owner_id, program_id, subject_id, level_id, slug, title, status, pass_percent)
                select 'educator', %s::uuid, p.id, s.id, l.id, 'fq-%s', 'Sınaq testi', 'published', 50
                  from public.programs p, public.subjects s, public.levels l
                 where p.slug='orta' and s.slug='riyaziyyat' and l.code='6' limit 1 returning id::text i""", (uid, T), one=True)["i"]
    db("""insert into public.test_questions (test_id, question_id, ord)
          select %s::uuid, q.id, row_number() over () from public.questions q join public.subjects s on s.id=q.subject_id
           where s.slug='riyaziyyat' and q.owner_type='platform' and q.status='published' limit 6""", (tid,))
    db("""insert into public.assignments (test_id, class_id, assigned_by, opens_at)
          values (%s::uuid, %s::uuid, %s::uuid, now() - interval '1 day')""", (tid, G, uid))
    for k, sid in enumerate(S[:2]):     # ucuncu sagird HELE GIRMEYIB
        att = db("""insert into public.attempts (student_id, test_id, class_id, status, started_at, finished_at, score, max_score, percent)
                    values (%s::uuid, %s::uuid, %s::uuid, 'submitted', now() - interval '2 hours', now() - interval '1 hour', %s, 6, %s)
                    returning id::text i""", (sid, tid, G, 2 + 3 * k, 33 + 50 * k), one=True)["i"]
        db("""insert into public.attempt_answers (attempt_id, question_id, topic_id, is_correct, points, question_body)
              select %s::uuid, q.id, q.topic_id, (row_number() over ()) %% 2 = %s, 1, q.body
                from public.questions q join public.test_questions tq on tq.question_id=q.id where tq.test_id=%s::uuid""",
           (att, k, tid))
    db("update public.students set last_seen_at = now() - interval '1 hour' where id = any(%s::uuid[])" % "%s", (S[:2],)) if False else None
    db("insert into public.homework (class_id, created_by, body) values (%s::uuid, %s::uuid, 'Sınaq ev tapşırığı')", (G, uid))
    ctx0.close()

    EKR = [("Ana səhifə", "#/", None), ("Qruplar siyahısı", "#/gs", None),
           ("Qrup · şagirdlər", "#/g/%s/s" % G, None), ("Qrup · dərs planı", "#/g/%s/p" % G, None),
           ("Qrup · dəftər", "#/g/%s/d" % G, None), ("Qrup hesabatı", "#/r/%s" % G, None),
           ("Tapşırıqlar", "#/a/%s" % G, None),
           ("Şagird hesabatı", "#/s/%s/%s" % (S[0], G), ["x", "m", "s", "t"]),
           ("Şagird (girməyən)", "#/s/%s/%s" % (S[2], G), None),
           ("Test vərəqi", "#/t/%s" % tid, None), ("Test yığ", "#/gen", None),
           ("Sual bankı", "#/b", None), ("Profil", "#/me", None), ("Bizə yaz", "#/bize", None)]
    NET = {}
    for kohne in (False, True):
        tag = "kohne" if kohne else "yeni"
        ctx = br.new_context(viewport={"width": 1280, "height": 1000})
        if kohne:
            ctx.add_init_script("try{localStorage.setItem('bil10_yeni','0')}catch(e){}")
        pg = ctx.new_page()
        pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
        pg.on("pageerror", lambda e: print("  JS XETASI [%s]: %s" % (tag, str(e)[:100])))
        pg.goto(PANEL); pg.wait_for_timeout(700)
        pg.fill("#email", MAIL); pg.fill("#pass", "fqparol123"); pg.click("#btnAuth"); pg.wait_for_timeout(3000)
        for ad, h, tabs in EKR:
            for k, v in snap(pg, ad, h, tabs).items():
                NET.setdefault(k, {})[tag] = v
        ctx.close()
    br.close()
json.dump(NET, open(OUT + "/net.json", "w"), ensure_ascii=False)

print("\n" + "=" * 70 + "\nKÖHNƏDƏ VAR, YENİDƏ YOXDUR  (idarə elementləri, 1280 px)\n" + "=" * 70)
tam = 0
for ad, d in NET.items():
    y = {key(c) for c in d.get("yeni", []) if key(c)}
    k = [c for c in d.get("kohne", []) if key(c) and key(c) not in y]
    seen = set(); k2 = []
    for c in k:
        kk = key(c)
        if kk in seen: continue
        seen.add(kk); k2.append(c)
    print("\n▸ %s   (köhnə %d · yeni %d element)" % (ad, len(d.get("kohne", [])), len(d.get("yeni", []))))
    if not k2: print("   — fərq yoxdur"); continue
    tam += len(k2)
    for c in k2[:14]:
        print("   - %-7s %s" % (c["tag"], c["t"] or ("#" + c["id"])))
    if len(k2) > 14: print("   … +%d" % (len(k2) - 14))
print("\nCƏMİ köhnədə olub yenidə görünməyən: %d" % tam)
