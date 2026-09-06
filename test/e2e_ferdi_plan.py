#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Ferdi plan - ucdan-uca (db/131, yol xeritesi 18c).

Muellim diaqnostika verir; sagird yazir (2 fesil zeif, 1 orta, SQL ile);
muellim "Ferdi plan qur" -> 3 setir; "Kecildi", "Test ver" (yalniz bu
sagirde); valideyn "1 / 3 movzu kecilib" gorur."""
import time
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

PANEL   = "http://127.0.0.1:8010/muellim/index.html"
PARENT  = "http://127.0.0.1:8010/valideyn/index.html"
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
delete from public.student_plan_items; delete from public.student_plans;
delete from public.fee_payments; delete from public.attendance; delete from public.lessons;
delete from public.mistakes; delete from public.feedback; delete from public.question_reports; delete from public.parent_sessions;
delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers; delete from public.attempts; delete from public.assignments;
delete from public.student_sessions; delete from public.students; delete from public.classes;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator'; delete from public.subscriptions;
delete from public.account_members; delete from public.accounts; delete from public.user_roles;
delete from public.profiles; delete from auth.users;""")

EMAIL = "fplan%d@t.az" % int(time.time())

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

    print("A · Hazırlıq: müəllim (abunəli), 3-cü sinif, şagird, diaqnostika")
    pg.goto(PANEL); pg.wait_for_selector("#btnAuth", timeout=15000)
    pg.click("#btnSwap")
    pg.fill("#fname", "Plan Müəllim"); pg.fill("#email", EMAIL)
    pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=15000)
    pg.select_option("#atype", "tutor"); pg.fill("#aname", "Plan hesabı"); pg.click("#btnSetup")
    pg.wait_for_selector("#btnGroup", timeout=15000)
    pg.fill("#gname", "3-cü sinif"); pg.select_option("#glevel", "3"); pg.click("#btnGroup")
    pg.wait_for_selector("#groups .item", timeout=15000)
    pg.click("#groups .item"); pg.wait_for_selector("#gTabs", timeout=15000)
    try: pg.wait_for_selector("#sname", state="visible", timeout=3000)
    except Exception: pg.click("#btnStuOpen")
    pg.fill("#sname", "Kənan Əliyev"); pg.click("#btnStu"); pg.wait_for_selector(".stu", timeout=15000)
    row = pg.locator(".stu").first
    row.locator("[data-edit]").click(); pg.wait_for_selector(".edit .pbox [data-pon]", timeout=15000)
    row.locator("[data-pon]").click(); pg.wait_for_selector(".stu [data-poff]", timeout=15000)
    GID = db("select id::text i from public.classes limit 1", one=True)["i"]
    AID = db("select id::text i from public.accounts limit 1", one=True)["i"]
    SID = db("select id::text i from public.students limit 1", one=True)["i"]
    CODE = db("select login_code c from public.students limit 1", one=True)["c"]
    PKOD = db("select parent_code c from public.students limit 1", one=True)["c"]
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select %s, p.id, 'active', now() + interval '30 days' from public.plans p where p.slug='repetitor-25'""", (AID,))
    pg.goto(PANEL + "#/s/" + SID + "/" + GID); pg.wait_for_selector("#dgGo", timeout=15000)
    ok(pg.locator("#splanBox").inner_text().strip() == "", "diaqnostikasiz ferdi plan karti yoxdur")
    pg.select_option("#dgSub", "riyaziyyat"); pg.click("#dgGo"); pg.wait_for_selector("#dgMsg .ok", timeout=20000)
    T1 = db("select id::text i from public.tests where is_diagnostic order by created_at desc limit 1", one=True)["i"]
    #  sagird yazir: 1-2-ci fesil tam sehv, 3-cu fesil 2/3 (orta), qalani duz
    db("""do $$ declare tok text; att uuid; ans jsonb; begin
      tok := public.rpc_student_login(%s)->>'token';
      att := (public.rpc_start_attempt(tok, %s)->>'attempt_id')::uuid;
      with q as (select q.id qid, dense_rank() over (order by tp.sort, tp.name) rk,
                        row_number() over (partition by q.topic_id order by q.id) k
                   from public.test_questions tq join public.questions q on q.id = tq.question_id
                   join public.topics tp on tp.id = q.topic_id where tq.test_id = %s)
      select jsonb_agg(jsonb_build_object('q', qid, 'o', jsonb_build_array(
               (select o.id from public.question_options o where o.question_id = qid
                 and o.is_correct = (case when rk <= 2 then false when rk = 3 then (k <> 1) else true end)
                 order by o.ord limit 1)))) into ans from q;
      perform public.rpc_submit_attempt(tok, att, ans);
    end $$""", (CODE, T1, T1))

    print("B · «Fərdi plan qur» → 3 sətir")
    pg.reload(); pg.wait_for_selector("#spMake", timeout=15000)
    ok("3 mövzu" in pg.inner_text("#spMake"), "duymede movzu sayi", pg.inner_text("#spMake"))
    pg.click("#spMake"); pg.wait_for_selector(".sprow", timeout=15000)
    ok(pg.locator(".sprow").count() == 3, "3 setir")
    ok("0/3" in pg.inner_text(".splan .spn"), "0/3")
    kinds = pg.locator(".sprow .dst").all_inner_texts()
    ok(kinds == ["zəif", "zəif", "orta"], "sira: zeif, zeif, orta (kurikulum)", kinds)
    ok(pg.locator("#spRenew").count() == 0, "teze planda 'Yenile' yoxdur")

    print("C · «Keçildi» və «Test ver»")
    pg.locator(".sprow [data-spdone]").first.click(); pg.wait_for_selector(".sprow.done", timeout=8000)
    ok("1/3" in pg.inner_text(".splan .spn") and pg.locator(".sprow.done").count() == 1, "1/3, ilk setir kecildi")
    pg.locator(".sprow:not(.done) [data-sptest]").first.click(); pg.wait_for_selector("#spMsg .ok", timeout=20000)
    ok("yalnız bu şagirdə" in pg.inner_text("#spMsg"), "test yigildi ve ferdi tapsirildi")
    a = db("select a.student_id::text s, a.max_attempts m from public.assignments a join public.tests t on t.id=a.test_id where t.is_diagnostic = false", one=True)
    ok(a and a["s"] == SID and a["m"] == 1, "bazada ferdi teyinat, 1 cehd")
    pg.wait_for_selector(".sprow .spt", timeout=8000)
    ok("gözlənilir" in pg.inner_text(".sprow .spt"), "setirde test linki 'gozlenilir'")
    pg.locator(".splan").screenshot(path="/tmp/fplan.png")

    print("D · Valideyn: 1 / 3 mövzu keçilib")
    vp = page(ctx, 390, 844)
    vp.goto(PARENT); vp.wait_for_selector("#code", timeout=15000)
    vp.fill("#code", PKOD); vp.click("#btnIn"); vp.wait_for_selector(".plan2", timeout=15000)
    ok("1 / 3" in vp.inner_text(".plan2"), "valideyn ferdi plan setri", vp.inner_text(".plan2"))
    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails)); [print("  - " + f) for f in fails]; raise SystemExit(1)
print("hamisi kecdi")
