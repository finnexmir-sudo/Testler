#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Cavab terzi + "Ne etmeli" - ucdan-uca (db/128_cavab_terzi.sql).

Sagird testi TEZ ve SEHV yazir, bir sualda "Emin deyilem" basir;
muellim sagird hesabatinda "Cavab terzi" kartini ve sehv siyahisinda
nisanlari, qrup hesabatinda "Ne etmeli" setrini gorur."""
import time
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

PANEL   = "http://127.0.0.1:8010/muellim/index.html"
STUDENT = "http://127.0.0.1:8010/sagird/index.html"
CHROME  = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN     = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
TEST_CFG = """window.CFG = {
  SUPABASE_URL: "http://127.0.0.1:54321",
  SUPABASE_ANON_KEY: "test-anon-key",
  STUDENT_URL: "http://127.0.0.1:8010/sagird/",
  PARENT_URL:  "http://127.0.0.1:8010/valideyn/",
  SHOW_PLANS: false
};"""
BLOCK = "**://*.supabase.co/**"

fails = []
def ok(cond, label, extra=""):
    print(("  OK   " if cond else "  FAIL ") + label + (("  " + str(extra)) if extra else ""), flush=True)
    if not cond: fails.append(label)

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            return cur.fetchone() if one else cur.fetchall()

db("""
delete from public.feedback; delete from public.question_reports; delete from public.parent_sessions;
delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers; delete from public.attempts; delete from public.assignments;
delete from public.student_sessions; delete from public.students; delete from public.classes;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator'; delete from public.subscriptions;
delete from public.account_members; delete from public.accounts; delete from public.user_roles;
delete from public.profiles; delete from auth.users;""")

EMAIL = "inam%d@t.az" % int(time.time())

def page(ctx, w, h):
    pg = ctx.new_page(); pg.set_viewport_size({"width": w, "height": h})
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=TEST_CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))
    return pg

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context()
    pg = page(ctx, 430, 1000)

    print("A · Hazırlıq: müəllim (abunəli), qrup, şagird, tapşırıq")
    pg.goto(PANEL); pg.wait_for_selector("#btnAuth", timeout=15000)
    pg.click("#btnSwap")
    pg.fill("#fname", "İnam Müəllim"); pg.fill("#email", EMAIL)
    pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=15000)
    pg.fill("#aname", "İnam hesabı"); pg.click("#btnSetup")
    #  30.10: yeni panel - qrup «Qruplar»da yaranir, yaranan kimi ICI acilir; bos qrupda «İlk şagirdi əlavə et»
    pg.wait_for_function("document.querySelector('#yMenu, #yBos, #yHd')", timeout=15000)
    pg.goto(PANEL + "#/gs"); pg.wait_for_selector("#btnGroup", timeout=15000); pg.wait_for_timeout(600)
    pg.fill("#gname", "3-cü sinif"); pg.select_option("#glevel", "3"); pg.click("#btnGroup")
    pg.wait_for_function("location.hash.indexOf('#/g/') === 0", timeout=15000)
    pg.wait_for_selector("#gFirstStu", timeout=15000); pg.click("#gFirstStu")
    pg.wait_for_selector("#sname", state="visible", timeout=15000)
    pg.fill("#sname", "Ayan Bir"); pg.click("#btnStu"); pg.wait_for_selector("#stu a.ytr", timeout=15000)
    GID = db("select id::text i from public.classes limit 1", one=True)["i"]
    AID = db("select id::text i from public.accounts limit 1", one=True)["i"]
    SID = db("select id::text i from public.students limit 1", one=True)["i"]
    CODE = db("select login_code c from public.students limit 1", one=True)["c"]
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select %s, p.id, 'active', now() + interval '30 days' from public.plans p where p.slug='repetitor-25'""", (AID,))
    #  tapsiriq bazadan verilir (tapsiriq ekrani oz testlerindedir: e2e_dord_is, e2e_test_yig) - burada mesele cavab terzidir
    db("""insert into public.assignments (class_id, test_id, assigned_by)
          select %s::uuid, t.id, a.owner_id from public.tests t, public.accounts a
           where t.slug = 'riy-3-vurma-1' and a.id = %s::uuid""", (GID, AID))

    print("B · Şagird: tez və səhv yazır, 1-ci sualda «Əmin deyiləm»")
    KEY = {r["q"]: r["o"] for r in db("""select q.id::text q, o.id::text o from public.questions q
        join public.question_options o on o.question_id=q.id and o.is_correct
        join public.test_questions tq on tq.question_id=q.id join public.tests t on t.id=tq.test_id
        where t.slug='riy-3-vurma-1'""")}
    NQ = len(KEY)
    sp = page(ctx, 390, 844)
    sp.goto(STUDENT); sp.wait_for_selector("#btnIn", timeout=15000)
    sp.fill("#code", CODE); sp.click("#btnIn"); sp.wait_for_selector(".test", timeout=15000)
    sp.locator(".test.asg").first.click(); sp.wait_for_selector(".opt", timeout=15000)
    ok(sp.locator("#btnSure").count() == 1 and "Əmin deyiləm" in sp.inner_text("#btnSure"), "«Əmin deyiləm» duymesi var")
    for i in range(NQ):
        ids = sp.locator(".opt").evaluate_all("els => els.map(e => e.getAttribute('data-o'))")
        wrong = next(o for o in ids if o not in KEY.values())
        sp.locator("[data-o='%s']" % wrong).click(); sp.wait_for_timeout(80)
        if i == 0:
            sp.click("#btnSure"); sp.wait_for_timeout(80)
            ok("on" in (sp.locator("#btnSure").get_attribute("class") or ""), "1-ci sualda emin deyilem secildi")
        if i + 1 < NQ: sp.click("#btnNext")
        else:
            sp.once("dialog", lambda d: d.accept()); sp.click("#btnFinish")
        sp.wait_for_timeout(120)
    sp.wait_for_selector(".ring", timeout=15000)
    rows = db("select seconds, sure, is_correct from public.attempt_answers order by answered_at")
    ok(len(rows) == NQ and all(r["seconds"] is not None and r["seconds"] <= 5 for r in rows), "her cavabda saniye var, hamisi tez", [r["seconds"] for r in rows])
    ok(sum(1 for r in rows if r["sure"] is False) == 1 and sum(1 for r in rows if r["sure"] is True) == NQ - 1, "bir cavab emin deyil, qalani emin")
    ok(all(r["is_correct"] is False for r in rows), "hamisi sehv")

    print("C · Müəllim: şagird hesabatında «Cavab tərzi» və nişanlar")
    #  yeni panel: «Cavab xüsusiyyətləri» Mövzular sekmesinde, acilan bolmededir
    def styl_ac():
        pg.goto(PANEL + "#/s/" + SID + "/" + GID); pg.reload(); pg.wait_for_selector("#sTabs", timeout=15000)
        pg.click("#sTabs [data-v='m']"); pg.wait_for_selector("details.styd", state="attached", timeout=15000)
        pg.evaluate("document.querySelector('details.styd').open = true"); pg.wait_for_selector(".styl", timeout=15000)
    styl_ac()
    ok("Cavab xüsusiyyətləri" in pg.inner_text("details.styd > summary"), "bölmənin adı «Cavab xüsusiyyətləri»", pg.inner_text("details.styd > summary"))
    st = pg.inner_text(".styl").replace("\n", " ")
    #  «Əmin idi» -> «Bildiyini sanır»: tək sözlə anlaşılmırdı, sual
    #  yarandı.  Kartda və səhv siyahısındakı nişanda ad EYNİDİR.
    #  30.10 (audit): «Bildiyini sanır» -> «Əmin olub səhv cavablayıb» (ne oldugu deqiq deyilir)
    ok("Tələsik səhv" in st and "Əmin olub səhv cavablayıb" in st, "kart var", st[:60])
    nums = [int(b.inner_text()) for b in pg.locator(".styl .srow > b").all()]
    #  yeni panelde sira: emin olub sehv (en vacib) - telesik - bilmeden duz
    ok(nums == [NQ - 1, NQ, 0], "saylar: emin olub sehv=NQ-1, telesik=NQ, bilmeden duz=0", nums)
    pg.click("#sTabs [data-v='s']")
    pg.wait_for_selector(".wq", timeout=8000)
    ok(pg.locator(".wq .wb-h").count() >= 1 and pg.locator(".wq .wb-s").count() >= 1, "sehv setrinde 'telesik' ve 'emin idi' nisanlari",
       (pg.locator(".wq .wb-h").count(), pg.locator(".wq .wb-s").count()))

    print("D · Qrup hesabatında «Nə etməli»")
    pg.goto(PANEL + "#/r/" + GID); pg.wait_for_selector("#rTabs", timeout=15000)
    ok(pg.locator("#rTodo").count() == 1, "'Ne etmeli' karti var")
    td = pg.inner_text("#rTodo").replace("\n", " ")
    ok("1 şagirdə" in td and "Ayan" in td, "movzu + 1 sagird adbaad", td[:90])
    pg.click("#btnTodo"); pg.wait_for_selector("#gsub", timeout=15000); pg.wait_for_timeout(1500)
    dbg = {"lev": pg.locator("#gLevs .chip.on").all_inner_texts(), "sub": pg.locator("#gsub").input_value(),
           "top": pg.locator("#gTop").count(), "ok": pg.locator(".ok").count() and pg.inner_text(".ok")[:80]}
    ok(pg.locator("#gTop .chip.on").count() >= 1 or "zəif mövzular seçilib" in str(dbg["ok"]).lower(),
       "duyme generatoru movzu secili acir", dbg)
    styl_ac()
    pg.locator(".styl").screenshot(path="/tmp/inam_styl.png")
    pg.goto(PANEL + "#/r/" + GID); pg.wait_for_selector("#rTodo", timeout=15000)
    pg.locator("#rTodo").screenshot(path="/tmp/inam_todo.png")
    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails)); [print("  - " + f) for f in fails]; raise SystemExit(1)
print("hamisi kecdi")
