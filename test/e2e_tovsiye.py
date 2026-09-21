#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""217: TOVSIYE KODU - «bu muellimi kim getirdi».

Muellim A test veraqinda «Hemkarina gonder» basir: linkde onun kodu
gedir.  Muellim B hemin linkle gelib qeydiyyatdan kecir - idareetmede
«A -> B» gorunur.
"""
import time, psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
BASE = "http://127.0.0.1:8010/"
PANEL = BASE + "muellim/index.html"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
BAD = [0]
def ok(c, ad, elave=""):
    print(("  OK   " if c else "  SEHV ") + ad + ("  " + str(elave) if elave else ""))
    if not c: BAD[0] += 1
def q(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            r = cur.fetchall(); return (r[0] if r else None) if one else r
T = int(time.time() * 1000)
MAIL_A = "tvsa%d@t.az" % T
MAIL_B = "tvsb%d@t.az" % T
with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    def qur(ctx, mail, ad):
        p = ctx.new_page()
        p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
        p.goto(PANEL); p.wait_for_selector("#email", timeout=30000)
        p.click("#btnSwap"); p.fill("#fname", ad); p.fill("#email", mail)
        p.fill("#pass", "parol1234"); p.click("#btnAuth")
        return p

    print("A · Müəllim A linki paylaşır — kod linkdədir")
    ctxA = br.new_context(viewport={"width": 1280, "height": 900},
                          permissions=["clipboard-read", "clipboard-write"])
    pa = qur(ctxA, MAIL_A, "Aygün müəllim")
    pa.wait_for_selector("#btnSetup", timeout=30000)
    pa.fill("#aname", "Aygün müəllim"); pa.click("#btnSetup")
    pa.wait_for_selector("#btnGroup", timeout=30000)
    acc = q("select a.id acc, a.owner_id own from public.accounts a join auth.users u"
            " on u.id=a.owner_id where u.email=%s", (MAIL_A,), one=True)
    src = q("select id, subject_id, level_id, program_id from public.tests"
            " where owner_type='platform' and title='Vurma cədvəli — 1'", one=True)
    tid = q("insert into public.tests (owner_type,owner_id,program_id,subject_id,level_id,"
            "title,status,max_attempts,created_at,updated_at)"
            " values ('educator',%s,%s,%s,%s,'Mənim testim','published',1,now(),now())"
            " returning id", (acc["own"], src["program_id"], src["subject_id"], src["level_id"]),
            one=True)["id"]
    q("insert into public.test_questions (test_id, question_id, ord)"
      " select %s, question_id, ord from public.test_questions where test_id=%s", (tid, src["id"]))
    pa.goto(PANEL + "#/t/" + str(tid)); pa.reload()
    pa.wait_for_selector("#btnHemkar", timeout=20000)
    pa.click("#btnHemkar")
    pa.wait_for_selector(".hmtxt", timeout=20000)
    metn = pa.input_value(".hmtxt")
    kod = q("select ref_code from public.profiles where id=%s", (acc["own"],), one=True)["ref_code"]
    ok(bool(kod), "muellime tovsiye kodu verildi", kod)
    ok("?src=hemkar&r=" + (kod or "") in metn, "kod paylasilan linkdedir",
       metn[-45:])
    ctxA.close()

    print("B · Müəllim B həmin linklə gəlir")
    ctxB = br.new_context(viewport={"width": 390, "height": 844})
    pb0 = ctxB.new_page()
    pb0.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    #  ana sehife: visit.js nisanlari sessiyaya yazir
    pb0.goto(BASE + "index.html?src=hemkar&r=" + kod)
    pb0.wait_for_timeout(700)
    nis = pb0.evaluate("[sessionStorage.getItem('bil10_src'),"
                       " (JSON.parse(localStorage.getItem('bil10_ref')||'null')||{}).c]")
    ok(nis[0] == "hemkar", "menbe nisani saxlanildi", nis[0])
    ok(nis[1] == kod, "tovsiye kodu saxlanildi", nis[1])
    #  Muellim ana sehifeden panele KECIR - eyni tab (real gedis)
    pb = pb0
    pb.goto(PANEL); pb.wait_for_selector("#email", timeout=30000)
    pb.click("#btnSwap"); pb.fill("#fname", "Bahar müəllim"); pb.fill("#email", MAIL_B)
    pb.fill("#pass", "parol1234"); pb.click("#btnAuth")
    pb.wait_for_selector("#btnSetup", timeout=30000)
    pr = q("select p.src, p.ref_by from public.profiles p join auth.users u on u.id=p.id"
           " where u.email=%s", (MAIL_B,), one=True)
    ok(pr["src"] == "hemkar", "qeydiyyatda menbe yazildi", pr["src"])
    ok(pr["ref_by"] == acc["own"], "qeydiyyatda GETIREN yazildi", pr["ref_by"])
    ctxB.close()

    print("C · A-nın sayı artdı")
    ctxA2 = br.new_context(viewport={"width": 1280, "height": 900})
    pa2 = ctxA2.new_page()
    pa2.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    pa2.goto(PANEL); pa2.wait_for_selector("#email", timeout=30000)
    pa2.fill("#email", MAIL_A); pa2.fill("#pass", "parol1234"); pa2.click("#btnAuth")
    pa2.wait_for_selector("#btnGroup", timeout=30000)
    say = pa2.evaluate("""() => new Promise(r => { var x=new XMLHttpRequest();
      x.open("POST","http://127.0.0.1:54321/rest/v1/rpc/rpc_ref_link");
      x.setRequestHeader("Content-Type","application/json");
      x.setRequestHeader("apikey","test-anon-key");
      var s=JSON.parse(localStorage.getItem("panel_session")||"{}");
      x.setRequestHeader("Authorization","Bearer "+(s.access_token||""));
      x.onload=()=>r(x.responseText); x.send("{}"); })""")
    ok('"n": 1' in say or '"n":1' in say, "rpc_ref_link say qaytarir", say[:80])
    ctxA2.close()

    print("D · Özünü gətirmək olmaz")
    ctxC = br.new_context()
    pc0 = ctxC.new_page()
    pc0.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    pc0.goto(BASE + "index.html?src=hemkar&r=ZZZZZZ"); pc0.wait_for_timeout(500)
    mc = "tvsc%d@t.az" % T
    pc = pc0
    pc.goto(PANEL); pc.wait_for_selector("#email", timeout=30000)
    pc.click("#btnSwap"); pc.fill("#fname", "Cavid müəllim"); pc.fill("#email", mc)
    pc.fill("#pass", "parol1234"); pc.click("#btnAuth")
    pc.wait_for_selector("#btnSetup", timeout=30000)
    pr2 = q("select p.ref_by from public.profiles p join auth.users u on u.id=p.id"
            " where u.email=%s", (mc,), one=True)
    ok(pr2["ref_by"] is None, "tanınmayan kod getiren yazmir", pr2["ref_by"])
    ctxC.close()
    br.close()
print("TOVSIYE: " + ("BUTUN YOXLAMALAR KECDI" if not BAD[0] else "UGURSUZ: %d" % BAD[0]))
