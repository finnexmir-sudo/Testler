#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""«Bize yaz» - ucdan-uca (db/122_bize_yaz.sql).

Muellim profildən yazir (qisa metn reddedilir), oz siyahisinda gorur;
sagird ve valideyn oz ekranindan yazir; adi muellim Idareetmeni gormur;
admin ucunu de gorur, status + cavab qoyur; muellim cavabi profildə
gorur; Icmalda "N yeni muraciet" sayi."""
import time
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

PANEL   = "http://127.0.0.1:8010/muellim/index.html"
STUDENT = "http://127.0.0.1:8010/sagird/index.html"
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
delete from public.feedback; delete from public.question_reports; delete from public.parent_sessions;
delete from public.admin_totp; delete from public.admin_unlocks; delete from public.admin_code_attempts;
delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers; delete from public.attempts; delete from public.assignments;
delete from public.student_sessions; delete from public.students; delete from public.classes;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator'; delete from public.subscriptions;
delete from public.account_members; delete from public.accounts; delete from public.user_roles;
delete from public.profiles; delete from auth.users;""")

TS = int(time.time())
EMAIL = "bize%d@t.az" % TS

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

    print("A · Hazırlıq: müəllim, qrup, şagird, valideyn kodu")
    pg.goto(PANEL); pg.wait_for_selector("#btnAuth", timeout=15000)
    pg.click("#btnSwap")
    pg.fill("#fname", "Bizə Müəllim"); pg.fill("#email", EMAIL)
    pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=15000)
    pg.select_option("#atype", "tutor"); pg.fill("#aname", "Bizə hesabı"); pg.click("#btnSetup")
    pg.wait_for_selector("#btnGroup", timeout=15000)
    pg.fill("#gname", "5-ci sinif"); pg.click("#btnGroup")
    pg.wait_for_selector("#groups .item", timeout=15000)
    pg.click("#groups .item"); pg.wait_for_selector("#gTabs", timeout=15000)
    try: pg.wait_for_selector("#sname", state="visible", timeout=3000)     # 0 sagirdde forma ozu acilir
    except Exception: pg.click("#btnStuOpen")
    pg.fill("#sname", "Leyla Həsənova"); pg.click("#btnStu")
    pg.wait_for_selector(".stu", timeout=15000)
    pg.locator(".stu [data-edit]").first.click()
    pg.wait_for_selector(".edit .pbox [data-pon]", timeout=15000)
    pg.locator(".stu [data-pon]").first.click()
    pg.wait_for_selector(".stu [data-poff]", timeout=15000)
    UID  = db("select id::text i from auth.users where email=%s", (EMAIL,), one=True)["i"]
    code = db("select login_code c from public.students limit 1", one=True)["c"]
    pkod = db("select parent_code c from public.students limit 1", one=True)["c"]
    ok(bool(code and pkod), "sagird kodu ve valideyn kodu var")

    print("B · Müəllim profildən yazır")
    pg.goto(PANEL + "#/me"); pg.wait_for_selector("#fbCard", timeout=15000)
    ok(pg.locator("#fbK .chip").count() == 4, "4 nov cipi")
    ok(pg.locator("#fbMine").inner_text().strip() == "", "bos: 'Yazdiqlariniz' yoxdur")
    pg.fill("#fbT", "qisa"); pg.click("#fbGo"); pg.wait_for_selector("#fbM .warn", timeout=8000)
    ok("10 simvol" in pg.inner_text("#fbM"), "qisa metn: xeberdarliq, gonderilmir")
    ok(db("select count(*) n from public.feedback", one=True)["n"] == 0, "bazada hec ne yoxdur")
    pg.click("#fbK .chip[data-k='problem']")
    pg.fill("#fbT", "Test vərəqində çap düyməsi telefonda görünmür.")
    ok(pg.inner_text("#fbN").startswith("46 /"), "sayğac isleyir", pg.inner_text("#fbN"))
    pg.click("#fbGo"); pg.wait_for_selector("#fbM .ok", timeout=8000)
    ok("çatdı" in pg.inner_text("#fbM"), "gonderildi mesaji")
    ok(pg.inner_text("#fbT") == "" and pg.inner_text("#fbN").startswith("0 /"), "forma temizlendi")
    pg.wait_for_selector("#fbList .fbi", timeout=8000)
    ok(pg.locator("#fbList .fbi").count() == 1, "'Yazdiqlariniz'da 1 mesaj")
    ok("Problem" in pg.inner_text("#fbList .fbi") and "Yeni" in pg.inner_text("#fbList .fbi"),
       "nov Problem, status Yeni")
    row = db("select kind, page, author_type, account_id::text a from public.feedback", one=True)
    ok(row["kind"] == "problem" and row["author_type"] == "teacher" and row["a"], "bazada: problem, muellim, hesab", row)
    ok(row["page"] == "Qrup", "sehife: hansi ekrandan gelib (Qrup)", row["page"])
    #  Icmal → Profil: sehife "Icmal" olur
    #  telefonda suretli emeliyyatlar gizlidir - DOM-da var, gorunmur
    pg.goto(PANEL + "#/"); pg.wait_for_selector("#btnMe", state="attached", timeout=15000)
    ok("bizə yazın" in pg.locator("#btnMe").inner_text(), "Icmalda Profil duymesi 'bize yazin' deyir")
    pg.goto(PANEL + "#/me"); pg.wait_for_selector("#fbCard", timeout=15000)
    pg.fill("#fbT", "Sual bankına ingilis dili fənni nə vaxt gələcək?")
    pg.click("#fbK .chip[data-k='sual']"); pg.click("#fbGo"); pg.wait_for_selector("#fbM .ok", timeout=8000)
    pg.wait_for_function("document.querySelectorAll('#fbList .fbi').length === 2", timeout=8000)
    ok(db("select page from public.feedback where kind='sual'", one=True)["page"] == "İcmal", "ikinci mesajin sehifesi Icmal")

    print("C · Şagird öz ekranından yazır")
    sp = page(ctx, 390, 844)
    sp.goto(STUDENT); sp.wait_for_selector("#btnIn", timeout=15000)
    sp.fill("#code", code); sp.click("#btnIn")
    sp.wait_for_selector("#fbBox", timeout=15000)
    ok(not sp.locator("#fbBox").get_attribute("open"), "sagirdde forma yigilmis (details)")
    sp.click("#fbBox summary"); sp.wait_for_selector("#fbT", timeout=5000)
    sp.click("#fbK .chip[data-k='tesekkur']")
    sp.fill("#fbT", "Testlər çox maraqlıdır, təşəkkür edirəm!")
    sp.click("#fbGo"); sp.wait_for_selector("#fbM .ok", timeout=8000)
    ok("çatdı" in sp.inner_text("#fbM"), "sagird: gonderildi")
    r = db("select author_type, kind, student_id::text s, account_id::text a from public.feedback where author_type='student'", one=True)
    ok(r and r["kind"] == "tesekkur" and r["s"] and r["a"], "bazada sagird mesaji: sagird + hesab bagli")

    print("D · Valideyn yazır")
    vp = page(ctx, 390, 844)
    vp.goto(PARENT); vp.wait_for_selector("#btnIn", timeout=15000)
    vp.fill("#code", pkod); vp.click("#btnIn")
    vp.wait_for_selector("#fbBox", timeout=15000)
    vp.click("#fbBox summary"); vp.wait_for_selector("#fbT", timeout=5000)
    vp.fill("#fbT", "Hesabatda mövzu adları çox xırda yazılır.")
    vp.click("#fbGo"); vp.wait_for_selector("#fbM .ok", timeout=8000)
    ok("çatdı" in vp.inner_text("#fbM"), "valideyn: gonderildi")
    ok(db("select count(*) n from public.feedback where author_type='parent'", one=True)["n"] == 1, "bazada valideyn mesaji")

    print("E · Adi müəllim İdarəetməni görmür; admin görür")
    pg.goto(PANEL + "#/"); pg.wait_for_selector("#btnMe", state="attached", timeout=15000)
    ok(pg.locator("#btnAdm").count() == 0, "adi muellimde Idareetme karti yoxdur")
    db("insert into public.user_roles (user_id, role) values (%s,'admin') on conflict do nothing", (UID,))
    pg.reload(); pg.wait_for_selector("#btnAdm", timeout=15000)
    pg.wait_for_selector("#admSub:has-text('yeni müraciət')", timeout=8000)
    ok("4 yeni müraciət" in pg.inner_text("#admSub"), "Icmal: 4 yeni muraciet", pg.inner_text("#admSub"))
    pg.click("#btnAdm"); pg.wait_for_selector("#fbList .fbc", timeout=15000)
    ok(pg.locator("#fbList .fbc").count() == 4, "admin: 4 kart")
    ok("4" in pg.inner_text("#fbH"), "basliqda say")
    txt = pg.inner_text("#fbList")
    ok("Bizə Müəllim" in txt and EMAIL in txt, "muellim karti: ad + e-poct")
    ok("Leyla Həsənova" in txt and "5-ci sinif" in txt, "sagird karti: ad + sinif")
    ok("Valideyn · Leyla Həsənova" in txt, "valideyn karti: kimin valideyni")
    ok("ekran: Qrup" in txt, "muellimin hansi ekrandan yazdigi gorunur")

    print("F · Admin status + cavab yazır; siyahı yenilənir")
    card = pg.locator("#fbList .fbc", has_text="çap düyməsi").first
    card.locator("select").select_option("planned")
    card.locator("textarea").fill("Növbəti buraxılışda çap düyməsi telefona da gələcək.")
    card.locator("[data-fbsave]").click()
    pg.wait_for_selector(".fbc .fbcm .ok", timeout=8000)
    ok("profilində görəcək" in pg.inner_text(".fbc .fbcm .ok"), "yadda saxlanildi + izah")
    pg.wait_for_function("document.querySelectorAll('#fbList .fbc').length === 3", timeout=8000)
    ok("3" in pg.inner_text("#fbH"), "basliq sayi 3-e dusdu", pg.inner_text("#fbH"))
    pg.click("#fbF .chip[data-fs='planned']")
    pg.wait_for_function("document.querySelectorAll('#fbList .fbc').length === 1", timeout=8000)
    ok("çap düyməsi" in pg.inner_text("#fbList"), "Planda suzgeci: 1 kart")
    pg.click("#fbF .chip[data-fs='all']")
    pg.wait_for_function("document.querySelectorAll('#fbList .fbc').length === 4", timeout=8000)
    ok(True, "Hamisi: 4 kart")
    r = db("select status, admin_note n, answered_at a from public.feedback where kind='problem'", one=True)
    ok(r["status"] == "planned" and r["n"].startswith("Növbəti") and r["a"], "bazada status + qeyd + vaxt")

    print("G · Müəllim cavabı profildə görür")
    pg.goto(PANEL + "#/me"); pg.wait_for_selector("#fbList .fbi", timeout=15000)
    it = pg.locator("#fbList .fbi", has_text="çap düyməsi").first
    ok("Planda" in it.inner_text(), "status Planda")
    ok(it.locator(".fbre").count() == 1 and "Növbəti buraxılışda" in it.inner_text(), "Cavabimiz qutusu gorunur")
    other = pg.locator("#fbList .fbi", has_text="ingilis dili").first
    ok(other.locator(".fbre").count() == 0, "cavabsiz mesajda qutu yoxdur")

    print("H · Şəkil (390 · 1280)")
    pg.screenshot(path="/tmp/bize_me.png", full_page=True)
    pg.goto(PANEL + "#/adm"); pg.wait_for_selector("#fbList .fbc", timeout=15000)
    pg.set_viewport_size({"width": 1280, "height": 900})
    pg.screenshot(path="/tmp/bize_adm.png", full_page=True)
    sp.screenshot(path="/tmp/bize_sag.png", full_page=True)
    vp.screenshot(path="/tmp/bize_val.png", full_page=True)
    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails)); [print("  - " + f) for f in fails]; raise SystemExit(1)
print("hamisi kecdi")
