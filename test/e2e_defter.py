#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sehv defteri + irelileyis karti - ucdan-uca (db/129, yol xeritesi 21.3/21.5).

Sagird testi sehv yazir -> ev ekraninda "Sehv defteri" karti; mesq: bir
duz (review), bir sehv (+1 gun); muellim Sehvler sekmesinde sayğaclari,
Xulasede irelileyis kartini (canvas + yukle linki) gorur."""
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
delete from public.mistakes; delete from public.feedback; delete from public.question_reports; delete from public.parent_sessions;
delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers; delete from public.attempts; delete from public.assignments;
delete from public.student_sessions; delete from public.students; delete from public.classes;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator'; delete from public.subscriptions;
delete from public.account_members; delete from public.accounts; delete from public.user_roles;
delete from public.profiles; delete from auth.users;""")

EMAIL = "defter%d@t.az" % int(time.time())

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
    pg.fill("#fname", "Dəftər Müəllim"); pg.fill("#email", EMAIL)
    pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=15000)
    pg.select_option("#atype", "tutor"); pg.fill("#aname", "Dəftər hesabı"); pg.click("#btnSetup")
    pg.wait_for_selector("#btnGroup", timeout=15000)
    pg.fill("#gname", "3-cü sinif"); pg.select_option("#glevel", "3"); pg.click("#btnGroup")
    pg.wait_for_selector("#groups .item", timeout=15000)
    pg.click("#groups .item"); pg.wait_for_selector("#gTabs", timeout=15000)
    try: pg.wait_for_selector("#sname", state="visible", timeout=3000)
    except Exception: pg.click("#btnStuOpen")
    pg.fill("#sname", "Ayan Bir"); pg.click("#btnStu"); pg.wait_for_selector(".stu", timeout=15000)
    GID = db("select id::text i from public.classes limit 1", one=True)["i"]
    AID = db("select id::text i from public.accounts limit 1", one=True)["i"]
    SID = db("select id::text i from public.students limit 1", one=True)["i"]
    CODE = db("select login_code c from public.students limit 1", one=True)["c"]
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select %s, p.id, 'active', now() + interval '30 days' from public.plans p where p.slug='repetitor-25'""", (AID,))
    pg.goto(PANEL + "#/a/" + GID); pg.wait_for_function("document.querySelectorAll('#aTest option').length > 0", timeout=15000)
    lbl = next(o for o in pg.locator("#aTest option").all_inner_texts() if "Vurma cədvəli" in o)
    pg.click("#aList [data-t='" + pg.evaluate("l => Array.from(document.querySelectorAll('#aTest option')).filter(o => o.textContent === l)[0].value", lbl) + "']"); pg.click("#btnAsg"); pg.wait_for_selector(".asg", timeout=15000)

    print("B · Şagird testi səhv yazır → dəftər dolur")
    KEY = {r["q"]: r["o"] for r in db("""select q.id::text q, o.id::text o from public.questions q
        join public.question_options o on o.question_id=q.id and o.is_correct
        join public.test_questions tq on tq.question_id=q.id join public.tests t on t.id=tq.test_id
        where t.slug='riy-3-vurma-1'""")}
    NQ = len(KEY)
    sp = page(ctx, 390, 844)
    sp.goto(STUDENT); sp.wait_for_selector("#btnIn", timeout=15000)
    sp.fill("#code", CODE); sp.click("#btnIn"); sp.wait_for_selector(".test", timeout=15000)
    ok(sp.locator("#mistBox").inner_text().strip() == "", "sehv yoxdursa defter karti gorunmur")
    sp.locator(".test.asg").first.click(); sp.wait_for_selector(".opt", timeout=15000)
    for i in range(NQ):
        ids = sp.locator(".opt").evaluate_all("els => els.map(e => e.getAttribute('data-o'))")
        wrong = next(o for o in ids if o not in KEY.values())
        sp.locator("[data-o='%s']" % wrong).click(); sp.wait_for_timeout(80)
        if i + 1 < NQ: sp.click("#btnNext")
        else:
            sp.once("dialog", lambda d: d.accept()); sp.click("#btnFinish")
        sp.wait_for_timeout(120)
    sp.wait_for_selector(".ring", timeout=15000)
    ok(db("select count(*) n from public.mistakes where status='open'", one=True)["n"] == NQ, "defterde NQ acıq sual")
    sp.click("#btnHome"); sp.wait_for_selector("#mistBox .mist", timeout=15000)
    mt = sp.inner_text("#mistBox").replace("\n", " ")
    ok(str(NQ) in mt and "gözləyir" in mt and "Məşq et" in mt, "ev ekraninda defter karti", mt[:80])

    print("C · Məşq: 1-ci düz (təkrara), 2-ci səhv (+1 gün), qalanı düz")
    sp.click("#btnMist"); sp.wait_for_selector(".opt", timeout=15000)
    html = sp.content()
    ok("is_correct" not in html, "mesq ekraninda is_correct yoxdur")
    def pick(correct):
        ids = sp.locator(".opt").evaluate_all("els => els.map(e => e.getAttribute('data-o'))")
        want = next(o for o in ids if (o in KEY.values()) == correct)
        sp.locator("[data-o='%s']" % want).click()
        sp.wait_for_selector("#btnMNext", timeout=8000)
    pick(True)
    ok(sp.locator(".opt.right").count() == 1 and "Düzdür" in sp.inner_text("#mFb"), "duz cavab: yasil + 'Duzdur'")
    ok("bir də yoxlayacağıq" in sp.inner_text("#mFb"), "izah: bir hefte sonra tekrar")
    sp.click("#btnMNext"); sp.wait_for_selector(".opt", timeout=8000)
    pick(False)
    ok(sp.locator(".opt.wrong").count() == 1 and "Səhvdir" in sp.inner_text("#mFb"), "sehv cavab: qirmizi + 'Sehvdir'")
    for i in range(NQ - 2):
        sp.click("#btnMNext"); sp.wait_for_selector(".opt", timeout=8000); pick(True)
    sp.click("#btnMNext"); sp.wait_for_selector("#btnMHome", timeout=8000)
    ok("Məşq bitdi" in sp.inner_text("#main") and "%d düz · 1 səhv" % (NQ - 1) in sp.inner_text("#main"), "bitis ekrani sayla", sp.inner_text("#main")[:60])
    st = db("select status, count(*) n from public.mistakes group by status order by status")
    ok({r["status"]: r["n"] for r in st} == {"open": 1, "review": NQ - 1}, "bazada 1 open (+1 gun), NQ-1 review", st)
    sp.click("#btnMHome"); sp.wait_for_selector("#mistBox .mist", timeout=15000)
    ok("gözləyən yoxdur" in sp.inner_text("#mistBox") and sp.locator("#btnMist").count() == 0, "bu gun gozleyen yoxdur - duyme yoxdur")

    print("D · Müəllim: Səhvlər sekməsində dəftər sayğacları")
    pg.goto(PANEL + "#/s/" + SID + "/" + GID); pg.wait_for_selector("#sTabs", timeout=15000)
    pg.click("#sTabs [data-v='s']"); pg.wait_for_selector(".mkbox", timeout=8000)
    mk = pg.inner_text(".mkbox").replace("\n", " ")
    ok("1 gözləyir" in mk and "%d təkrarda" % (NQ - 1) in mk and "0 bağlanıb" in mk, "sayğaclar", mk[:90])

    print("E · İrəliləyiş kartı (2+ cəhd)")
    #  ikinci cehd - serbest mesq: qarisiq test duz cavablarla (SQL ile)
    T2 = db("select id::text i from public.tests where slug='riy-3-qarisiq-1'", one=True)["i"]
    db("""do $$ declare tok text; att uuid; ans jsonb; begin
            tok := public.rpc_student_login(%s)->>'token';
            att := (public.rpc_start_attempt(tok, %s)->>'attempt_id')::uuid;
            select coalesce(jsonb_agg(jsonb_build_object('q', q.id, 'o', jsonb_build_array(
                     (select o.id from public.question_options o where o.question_id=q.id and o.is_correct order by o.ord limit 1)))), '[]'::jsonb)
              into ans from public.test_questions tq join public.questions q on q.id=tq.question_id where tq.test_id=%s;
            perform public.rpc_submit_attempt(tok, att, ans);
          end $$""", (CODE, T2, T2))
    #  eyni unvan: yalniz hash - sehife yenilenmir, kohne hesabat qalir -> reload
    pg.goto(PANEL + "#/s/" + SID + "/" + GID); pg.reload(); pg.wait_for_selector("#sTabs", timeout=15000)
    pg.click("#sTabs [data-v='x']"); pg.wait_for_selector("#pcv", state="attached", timeout=8000); pg.wait_for_timeout(300)
    href = pg.locator("#pcDl").get_attribute("href") or ""
    ok(href.startswith("data:image/png;base64,") and len(href) > 20000, "yukle linki PNG-dir", len(href))
    painted = pg.evaluate("""() => { const c = document.getElementById('pcv'); const g = c.getContext('2d');
        const d = g.getImageData(0, 0, c.width, c.height).data; let n = 0;
        for (let i = 0; i < d.length; i += 4 * 97) { if (d[i] < 240 || d[i+1] < 240 || d[i+2] < 240) n++; } return n; }""")
    ok(painted > 500, "kart cekilib (rengli piksel var)", painted)
    ok(pg.locator("#pcShare").count() == 1, "Paylas duymesi var")
    pg.locator("#pcv").screenshot(path="/tmp/defter_kart.png")
    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails)); [print("  - " + f) for f in fails]; raise SystemExit(1)
print("hamisi kecdi")
