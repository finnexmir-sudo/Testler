#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""«Bu gunun 5 sualı» - sagirdin ferdi gundelik tekrari (db/212).

Yoxlanan:
  A  muellim: qrup, sagird, ders plani, «Kecildi»
  B  sagird: kart YALNIZ ders kecilenden sonra cixir
  C  bes sual - sira serverden gelir, «hardan geldi» setri yazilir
  D  bitis: movzu-movzu hesabat, «Sabah» vedi, «daha test isle» YOXDUR
  E  gun icinde sabit: sehife yenilense eyni yerden davam edir
  F  abunesiz: kart kilidli, sual gelmir
"""
import time
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

PANEL   = "http://127.0.0.1:8010/muellim/index.html"
STUDENT = "http://127.0.0.1:8010/sagird/index.html"
CHROME  = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN     = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
BLOCK   = "**://*.supabase.co/**"
TEST_CFG = """window.CFG = {
  SUPABASE_URL: "http://127.0.0.1:54321",
  SUPABASE_ANON_KEY: "test-anon-key",
  STUDENT_URL: "http://127.0.0.1:8010/sagird/",
  PARENT_URL:  "http://127.0.0.1:8010/valideyn/",
  SHOW_PLANS: false
};"""
SINIF = "2"     # e2e_plan ile eyni sebeb: fesilsiz (duz) plan

fails = []
def ok(cond, label, extra=""):
    print(("  OK   " if cond else "  FAIL ") + label + (("  " + str(extra)) if extra else ""), flush=True)
    if not cond: fails.append(label)

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args) if args else cur.execute(sql)
        if cur.description:
            return cur.fetchone() if one else cur.fetchall()

db("""
delete from public.daily_packs;     delete from public.mistakes;
delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments;     delete from public.student_sessions;
delete from public.parent_sessions; delete from public.students;
delete from public.classes;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator'; delete from public.subscriptions;
delete from public.account_members; delete from public.accounts; delete from public.user_roles;
delete from public.profiles; delete from auth.users;""")

EMAIL = "gunluk%d@t.az" % int(time.time())

def page(ctx, w, h):
    pg = ctx.new_page(); pg.set_viewport_size({"width": w, "height": h})
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=TEST_CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))
    return pg

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context()
    pg = page(ctx, 1280, 900)

    print("A · Müəllim, qrup, şagird, abunə")
    pg.goto(PANEL); pg.wait_for_selector("#btnAuth", timeout=15000)
    pg.click("#btnSwap")
    pg.fill("#fname", "Gündəlik Müəllim"); pg.fill("#email", EMAIL)
    pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=15000)
    pg.select_option("#atype", "tutor"); pg.fill("#aname", "Gündəlik hesabı"); pg.click("#btnSetup")
    pg.wait_for_selector("#btnGroup", timeout=15000)
    pg.fill("#gname", "2-ci sinif"); pg.select_option("#glevel", SINIF); pg.click("#btnGroup")
    pg.wait_for_selector("#groups .gcard", timeout=15000)
    pg.click("#groups .gcard"); pg.wait_for_selector("#gTabs", timeout=15000)
    try: pg.wait_for_selector("#sname", state="visible", timeout=3000)
    except Exception: pg.click("#btnStuOpen")
    pg.fill("#sname", "Aysel Bir"); pg.click("#btnStu"); pg.wait_for_selector(".stu", timeout=15000)
    AID  = db("select id::text i from public.accounts limit 1", one=True)["i"]
    GID  = db("select id::text i from public.classes limit 1", one=True)["i"]
    CODE = db("select login_code c from public.students limit 1", one=True)["c"]
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select %s, p.id, 'active', now() + interval '30 days'
            from public.plans p where p.slug='repetitor-25'""", (AID,))

    print("B · Dərs keçilməmişdən əvvəl kart YOXDUR")
    sp = page(ctx, 390, 844)
    sp.goto(STUDENT); sp.wait_for_selector("#btnIn", timeout=15000)
    sp.fill("#code", CODE); sp.click("#btnIn"); sp.wait_for_selector("#dayBox", state="attached", timeout=15000)
    sp.wait_for_timeout(700)
    ok(sp.inner_text("#dayBox").strip() == "", "ders kecilmeyibse gundelik kart cixmir",
       sp.inner_text("#dayBox")[:60])

    print("B2 · Müəllim planı qurur və bir dərsi «Keçildi» edir")
    pg.goto(PANEL + "#/g/" + GID); pg.reload(); pg.wait_for_selector("#gTabs", timeout=15000)
    pg.click("#gTabs [data-v='p']"); pg.wait_for_selector("#btnPlOpen", timeout=15000)
    pg.click("#btnPlOpen"); pg.wait_for_selector("#btnPlMk", timeout=8000)
    pg.wait_for_function("document.querySelectorAll('#plSub option').length > 1", timeout=8000)
    pg.select_option("#plSub", "riyaziyyat"); pg.select_option("#plLev", SINIF)
    pg.click("#btnPlMk"); pg.wait_for_selector(".plan", timeout=15000)
    pg.locator("[data-pldone]").first.click(); pg.wait_for_selector(".ploffer", timeout=8000)
    ok(db("select count(*) n from public.class_plan_items where done_at is not null",
          one=True)["n"] == 1, "bir ders «kecildi» isarelendi")

    print("B3 · (213) Müəllim kartı: «Keçildi» geri alınanda itələmə çıxır")
    db("update public.class_plan_items set done_at = null where done_at is not null")
    pg.goto(PANEL + "#/"); pg.reload(); pg.wait_for_selector("#hBugun .bugun", timeout=15000)
    nud = pg.inner_text("#hBugun").replace("\n", " ")
    ok("gündəlik təkrar hazırlana bilmir" in nud, "iteleme setri cixir", nud[:110])
    ok(pg.locator("#hBugun .bgnud .btn").count() == 1, "«Dərs planı» kecidi var")
    db("""update public.class_plan_items set done_at = now() - interval '1 hour'
           where ord = (select min(ord) from public.class_plan_items)""")
    pg.reload(); pg.wait_for_selector("#hBugun .bugun", timeout=15000)
    ok(pg.locator("#hBugun .bgnud").count() == 0,
       "isarelenenden sonra setir itir", pg.inner_text("#hBugun").replace("\n", " ")[:80])

    print("C · Şagird: «Bu günün sualları» kartı + beş sual")
    sp.reload(); sp.wait_for_selector("#dayBox .dcard", timeout=15000)
    kart = sp.inner_text("#dayBox").replace("\n", " ")
    ok("Bu günün" in kart and "sualı" in kart, "kart basligi", kart[:70])
    ok("Müəllimin keçdiyi" in kart, "menbe yazilir - «muellimin kecdiyi …»", kart[:90])
    ok(sp.locator("#btnDay").count() == 1, "TEK duyme var - movzu/test secimi yoxdur")
    #  kart tapsiriqlarin USTUNDEDIR
    ok(sp.evaluate("""() => {
         const d = document.getElementById('dayBox');
         const hs = Array.from(document.querySelectorAll('#main h2'));
         const t = hs.find(h => h.textContent.indexOf('Tapşırıq') >= 0);
         return !!(d && t) && (d.compareDocumentPosition(t) & Node.DOCUMENT_POSITION_FOLLOWING) > 0;
       }"""), "kart «Tapşırıqlar» başlığından yuxarıdadır")

    N = db("""select jsonb_array_length(items) n from public.daily_packs limit 1""", one=True)["n"]
    ok(N == 5, "paketde bes sual var", N)
    sp.click("#btnDay"); sp.wait_for_selector(".opt", timeout=15000)
    ok("is_correct" not in sp.content(), "duz variant client-e getmir")
    ok(sp.locator(".dwhy").count() == 1 and sp.inner_text(".dwhy").strip() != "",
       "sualin hardan geldiyi yazilir", sp.inner_text(".dwhy")[:60])

    def cavabla(duz):
        qid = db("""select (d.items->(jsonb_array_length(d.answers))->>'q') q
                      from public.daily_packs d limit 1""", one=True)["q"]
        row = db("""select o.id::text o from public.question_options o
                     where o.question_id = %s and o.is_correct = %s limit 1""", (qid, duz), one=True)
        if not row:
            row = db("select o.id::text o from public.question_options o where o.question_id = %s limit 1",
                     (qid,), one=True)
        sp.locator("[data-o='%s']" % row["o"]).click()
        sp.wait_for_selector("#btnDNext", timeout=10000)

    #  1-ci sual QESDEN sehv - «sabah bir de» vedi yoxlanir
    cavabla(False)
    ok(sp.locator(".opt.wrong").count() == 1, "sehv cavab qirmizi isarelenir")
    ok("Sabah" in sp.inner_text("#dFb"), "sehv cavab: «sabah bir de»", sp.inner_text("#dFb")[:60])
    sp.click("#btnDNext"); sp.wait_for_selector(".opt", timeout=10000)

    print("E · Gün içində sabit: səhifə yenilənir, eyni yerdən davam")
    q_evvel = db("select (d.items->1->>'q') q from public.daily_packs d limit 1", one=True)["q"]
    sp.reload(); sp.wait_for_selector("#dayBox .dcard", timeout=15000)
    ok("Davam et" in sp.inner_text("#dayBox"), "kart «Davam et» deyir",
       sp.inner_text("#dayBox").replace("\n", " ")[:70])
    sp.click("#btnDay"); sp.wait_for_selector(".opt", timeout=15000)
    ok(db("select (d.items->1->>'q') q from public.daily_packs d limit 1", one=True)["q"] == q_evvel,
       "suallar deyismedi")
    ok("2 / 5" in sp.inner_text(".prog"), "eyni yerden davam edir", sp.inner_text(".prog"))

    print("D · Qalanı düz → bitiş ekranı")
    for _ in range(4):
        cavabla(True)
        sp.click("#btnDNext")
        sp.wait_for_timeout(250)
    sp.wait_for_selector("#btnDHome", timeout=15000)
    son = sp.inner_text("#main").replace("\n", " ")
    ok("Bu gün bitdi" in son, "bitis ekrani", son[:60])
    ok("5 sualdan 4 düz" in son, "netice sayla", son[:80])
    ok(sp.locator(".drow").count() >= 1, "movzu-movzu hesabat var", sp.locator(".drow").count())
    ok("Sabah" in son, "sabahin sebebi yazilir")
    ok("Daha" not in son and "daha" not in son.lower().replace("hazırlayacağıq", ""),
       "«daha test isle» teklifi YOXDUR - dovre baglanir")
    ok(db("select count(*) n from public.daily_packs where done_at is not null", one=True)["n"] == 1,
       "bazada paket bitmis isarelenib")
    sp.click("#btnDHome"); sp.wait_for_selector("#dayBox .dcard.done", timeout=15000)
    ok("Bu gün bitdi" in sp.inner_text("#dayBox"), "ev ekraninda «bu gun bitdi» karti",
       sp.inner_text("#dayBox").replace("\n", " ")[:70])

    print("F · Abunəsiz: kart kilidlidir, sual gəlmir")
    db("delete from public.subscriptions")
    db("delete from public.daily_packs")
    sp.reload(); sp.wait_for_selector("#dayBox .dcard.lock", timeout=15000)
    kilid = sp.inner_text("#dayBox").replace("\n", " ")
    ok(sp.locator("#dayBox .dlock").count() == 1, "kilid nisani var")
    ok("abunəsi ilə açılır" in kilid, "sebeb yazilir", kilid[:90])
    ok(sp.locator("#btnDay").count() == 0, "duyme yoxdur")
    ok(db("select coalesce(jsonb_array_length(items), 0) n from public.daily_packs limit 1",
          one=True)["n"] == 0, "abunesiz paket qurulmur (sual sizmir)")

    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails)); [print("  - " + f) for f in fails]; raise SystemExit(1)
print("HAMISI KECDI")
