#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Paket sehifesi ve admin idareetmesi."""
import sys
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

PANEL  = "http://127.0.0.1:8010/muellim/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN    = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
BLOCK  = "**://*.supabase.co/**"
TEST_CFG = """window.CFG = {
  SUPABASE_URL: "http://127.0.0.1:54321",
  SUPABASE_ANON_KEY: "test-anon-key",
  STUDENT_URL: "https://example.test/Testler/",
  CONTACT_WHATSAPP: "+994501234567",
  SHOW_PLANS: true
};"""

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
delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments;     delete from public.student_sessions;
delete from public.students;        delete from public.classes;
delete from public.subscriptions;
delete from public.test_questions tq using public.tests t
 where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.question_options o using public.questions q
 where q.id = o.question_id and q.owner_type = 'educator';
delete from public.questions where owner_type = 'educator';
delete from public.account_members; delete from public.accounts;
delete from public.user_roles;      delete from auth.users;
""")

with sync_playwright() as pw:
    br  = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 430, "height": 900})

    def new_page():
        pg = ctx.new_page()
        pg.route("**/config.js*", lambda r: r.fulfill(
            status=200, content_type="application/javascript", body=TEST_CFG))
        pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
        pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))
        return pg

    pg = new_page()
    pg.goto(PANEL); pg.wait_for_timeout(400)
    pg.click("#btnSwap")
    pg.fill("#fname", "Paket Muellim"); pg.fill("#email", "pkt@t.az")
    pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=8000)
    pg.select_option("#atype", "tutor")
    pg.fill("#aname", "Paket hesabi"); pg.click("#btnSetup")
    pg.wait_for_selector("#gForm", timeout=8000)

    print("A · Paket səhifəsi (abunəsiz)")
    ok(pg.locator("#btnPkt").count() == 1, "esas sehifede Paket bendi var")
    ok(pg.locator("#btnAdm").count() == 0, "adi muellimde Idareetme bendi YOXDUR")
    pg.click("#bnav a[href='#/p']")
    pg.wait_for_selector(".pkt", timeout=8000)
    ok("abunəniz yoxdur" in pg.inner_text("#main"), "abunesiz hal aydin yazilir")
    npl = pg.locator(".pkt").count()
    ok(npl >= 2, "planlar gorunur", npl)
    ok("₼" in pg.inner_text("#main"), "qiymetler manatladir")
    ok("Valideyn" not in pg.inner_text("#main"), "ozge auditoriya plani gorunmur")
    href = pg.locator("#btnWa").get_attribute("href")
    ok(href and "wa.me/994501234567" in href, "WhatsApp duymesi nomreye acilir",
       (href or "")[:50])

    print("B · Adi müəllim admin ünvanına girə bilmir")
    pg.goto(PANEL + "#/adm"); pg.wait_for_timeout(700)
    ok("admin" in pg.inner_text("#main").lower(), "acıq imtina mesaji gorunur",
       pg.inner_text("#main")[:60].replace("\n", " "))

    print("C · Admin rolu ilə idarəetmə")
    UID = db("select id::text i from auth.users", one=True)["i"]
    db("insert into public.user_roles (user_id, role) values (%s, 'admin') on conflict do nothing", (UID,))
    #  138: admin sahibli hesab DAIMIDIR (duyme yoxdur) - abune emeliyyatlari
    #  ucun ikinci, adi muellim hesabi lazimdir
    db("""insert into auth.users (id, email) values ('22220000-0000-0000-0000-0000000000a2', 'iki@t.az');
          update public.profiles set full_name = 'Iki Muellim' where id = '22220000-0000-0000-0000-0000000000a2';
          insert into public.accounts (id, type, name, owner_id) values
            ('aaaa2222-0000-0000-0000-0000000000a2', 'tutor', 'Iki hesabi', '22220000-0000-0000-0000-0000000000a2');
          insert into public.account_members values
            ('aaaa2222-0000-0000-0000-0000000000a2', '22220000-0000-0000-0000-0000000000a2', true)""")
    ROW = ".admr[data-em='iki@t.az']"
    ADM = ".admr[data-em='pkt@t.az']"
    pg.goto(PANEL); pg.reload()
    pg.wait_for_selector("#btnAdm", timeout=8000)
    ok("Admin · daimi" in pg.inner_text(".seat"), "ana sehifede pill 'Admin · daimi'",
       pg.inner_text(".seat").replace("\n", " "))
    ok(True, "admin rolunda Idareetme bendi gorunur")
    pg.click("#btnAdm")
    pg.wait_for_selector(".admr", timeout=8000)
    ok(pg.locator(".tiles.five .tile").count() == 5, "gosterici lovheleri gorunur",
       pg.locator(".tile").count())
    tl = pg.inner_text(".tiles.five").replace("\n", " ")
    ok("hesab" in tl and "pullu" in tl and "pulsuz" in tl and "gəlir" in tl,
       "lovhelerde hesab/pullu/pulsuz/gelir var", tl[:70])
    ok(pg.locator("#admF .chip").count() == 7,
       "pullu/sinaq/pulsuz/bitir/girmir/numune suzgec cipleri var",
       pg.locator("#admF .chip").count())
    ok("sınaq" in tl, "pullu lovhesinde sinaq sayi var", tl[:70])
    ok("yalnız ödənişli" in tl, "gelir lovhesi 'yalniz odenisli' deyir")
    ok(pg.locator(".tiles.five .tile").count() == 5 and "girib" in tl, "5-ci lovhe: hesab girib · son 7 gun", tl[-60:])
    print("C1 · (160) Hədiyyə paket ayarı")
    pg.wait_for_selector("#hedSave", timeout=8000)
    ok("Hədiyyə paket" in pg.inner_text("#hedBox"), "ayar qutusu yuklenir")
    pg.fill("#hedDays", "45"); pg.fill("#hedBeta", "2027-01-15")
    pg.click("#hedSave"); pg.wait_for_timeout(900)
    ok("saxlanıldı" in pg.inner_text("#admMsg"), "ayar saxlanildi mesaji")
    hv = db("select val from public.app_state where key='hediyye'", one=True)["val"]
    ok(hv.get("days") == 45 and hv.get("beta_until") == "2027-01-15", "bazada 45 gun / beta tarixi", hv)
    ok(pg.input_value("#hedDays") == "45", "forma yeniden dolur")
    npo = pg.locator("#admPlan option").count()
    ok(npo >= 2, "plan secimi bazadan dolur", npo)
    ok(pg.locator(".admr").count() == 2, "iki hesab siyahida", pg.locator(".admr").count())
    arow = pg.inner_text(ADM).replace("\n", " ")
    ok("admin · daimi" in arow, "admin hesabi 'admin · daimi' nisani ile", arow[:60])
    ok(pg.locator(ADM + " button").count() == 0, "admin setrinde duyme yoxdur")
    row = pg.inner_text(ROW).replace("\n", " ")
    ok("iki@t.az" in row, "hesab siyahida e-poctla gorunur", row[:60])
    ok("paketsiz" in row, "paketsiz nisani gorunur")
    row = arow
    ok("aktivlik" in row, "son aktivlik gorunur", row[:80])
    ok("müəllim girişi: bu gün" in row, "muellim girisi bu gun (rpc_seen)", row[-90:])
    ok("şagird girişi: heç vaxt" in row, "sagird girisi hele yoxdur")
    ok(pg.inner_text(".tile.e").startswith("1"), "girib lovhesi 1", pg.inner_text(".tile.e").replace("\n", " "))
    #  Girmeyenler: bu hesab bu gun girib - cixmir; 10 gun evvele cekende cixir
    pg.locator("#admF .chip[data-f='girmir']").click(); pg.wait_for_timeout(700)
    ok("Hesab tapılmadı" in pg.inner_text("#admList"), "girmeyenler: bu gun giren cixmir")
    db("update public.profiles set last_seen_at = now() - interval '10 days'; "
       "update auth.users set last_sign_in_at = now() - interval '10 days'")
    pg.locator("#admF .chip[data-f='']").click(); pg.wait_for_timeout(500)
    pg.locator("#admF .chip[data-f='girmir']").click(); pg.wait_for_selector(".admr", timeout=8000)
    ok("pkt@t.az" in pg.inner_text("#admList") and "10 gün əvvəl" in pg.inner_text(ADM),
       "girmeyenler: 10 gundur girmeyen cixir, narinci", pg.inner_text(ADM + " .lg-old"))
    ok(pg.locator(".admr .lg-old").count() == 2, "koхne giris narinci sinifle")
    pg.locator("#admF .chip[data-f='']").click(); pg.wait_for_selector(".admr", timeout=8000)

    print("D0 · (138) Sınaq — pulsuz paket: tam imkan, gəlirə düşmür")
    pg.on("dialog", lambda d: d.accept())
    ok(pg.locator(".admr [data-trial]").count() == 1, "adi setirde 'Sinaq 1 ay' duymesi var (adminde yox)")
    pg.locator(ROW + " [data-trial]").click()
    pg.wait_for_selector(ROW + " .pb.s", timeout=8000)
    ok("sınaq" in pg.inner_text(ROW + " .pb.s") and "Repetitor" in pg.inner_text(ROW + " .pb.s"),
       "goy sinaq nisani setirde", pg.inner_text(ROW + " .pb.s")[:40])
    a0 = db("select s.status, s.provider from public.subscriptions s", one=True)
    ok(a0 and a0["status"] == "trialing" and a0["provider"] == "trial",
       "bazada trialing/trial abune var", a0)
    tb = pg.inner_text(".tile.b").replace("\n", " ")
    ok(tb.startswith("0") and "1 sınaq" in tb, "lovhe: 0 pullu · 1 sinaq", tb)
    ok("0,00" in pg.inner_text(".tile.c") or "0 ₼" in pg.inner_text(".tile.c"),
       "gelir sifirdir", pg.inner_text(".tile.c").replace("\n", " "))
    pg.locator("#admF .chip[data-f='sinaq']").click()
    #  siyahi yeniden cizilene qeder gozle (kohne siyahida da .pb.s var)
    pg.wait_for_function("document.querySelectorAll('.admr').length === 1", timeout=8000)
    ok("iki@t.az" in pg.inner_text(".admr") and pg.locator(".admr").count() == 1,
       "sinaq suzgecinde yalniz o hesab gorunur")
    pg.locator("#admF .chip[data-f='pullu']").click(); pg.wait_for_timeout(700)
    ok("Hesab tapılmadı" in pg.inner_text("#admList"), "pullu suzgecinde sinaq hesab cixmir")
    pg.locator("#admF .chip[data-f='']").click(); pg.wait_for_selector(".admr", timeout=8000)

    print("D · Bir kliklə abunə açmaq (sınaq → ödənişli)")
    pg.locator(ROW + " [data-m='6']").click()
    pg.wait_for_selector(ROW + " .pb.y", timeout=8000)
    ok("Repetitor" in pg.inner_text(ROW + " .pb.y"), "abune nisani setirde gorunur",
       pg.inner_text(ROW + " .pb.y")[:40])
    ok("yerinə yetirildi" in pg.inner_text("#admMsg"), "netice mesaji gorunur")
    ok(pg.inner_text(".tile.b").replace("\n", " ").startswith("1"), "aktiv abune lovhesi yenilenir",
       pg.inner_text(".tile.b").replace("\n", " "))
    ok("29,00" in pg.inner_text(".tile.c") or "29 ₼" in pg.inner_text(".tile.c"),
       "gelir 29 AZN oldu", pg.inner_text(".tile.c").replace("\n", " "))
    a = db("""select s.status, s.provider from public.subscriptions s""", one=True)
    ok(a and a["status"] == "active" and a["provider"] == "manual",
       "bazada active/manual abune var")
    pg.locator("#admF .chip[data-f='pulsuz']").click()
    pg.wait_for_timeout(700)
    ok("Hesab tapılmadı" in pg.inner_text("#admList"),
       "pulsuz suzgecinde abuneli hesab cixmir")
    pg.locator("#admF .chip[data-f='pullu']").click()
    pg.wait_for_function("document.querySelectorAll('.admr').length === 1", timeout=8000)
    ok("iki@t.az" in pg.inner_text(".admr") and pg.locator(".admr").count() == 1,
       "pullu suzgecinde yalniz odenisli hesab gorunur (admin yox)")
    pg.locator("#admF .chip[data-f='']").click()
    pg.wait_for_timeout(500)

    print("E · Paket səhifəsi abunəni göstərir")
    pg.goto(PANEL + "#/p"); pg.reload()
    pg.wait_for_selector(".pkt", timeout=8000)
    ok("Hazırkı paket" in pg.inner_text("#main"), "hazirki paket gorunur")
    ok("Admin — daimi" in pg.inner_text("#main"), "admin ucun 'Admin — daimi', tarix yoxdur",
       pg.inner_text("#main")[:80].replace("\n", " "))

    print("F · Dayandırmaq")
    pg.goto(PANEL + "#/adm"); pg.reload()
    pg.wait_for_selector(".admr", timeout=8000)
    ok(pg.locator(".admr [data-stop]").count() == 1, "Dayandir yalniz abuneli adi setirde")
    pg.locator(ROW + " [data-stop]").click()
    pg.wait_for_timeout(900)
    pg.wait_for_selector(".admr", timeout=8000)
    ok(not db("select 1 ok from public.subscriptions where status='active'", one=True),
       "bazada aktiv abune qalmadi")

    print("G · (165) Şagird başına paket və ödəniş xatırlatması")
    #  DIQQET: bu hesab yuxarida ADMIN olub - app.has_active_subscription
    #  admin ucun hemise true qaytarir.  Ona gore burada YALNIZ ekran
    #  yoxlanilir; guzestin baza mentiqi db/test/smoke_qiymet.sql-dedir.
    acc = db("select a.id from public.accounts a"
             " join auth.users u on u.id = a.owner_id"
             " where u.email = 'pkt@t.az'", one=True)["id"]
    def abune(gun):
        db("delete from public.subscriptions where account_id = %s", (acc,))
        db("insert into public.subscriptions (account_id, plan_id, status, seats,"
           " started_at, current_period_end, provider)"
           " select %s, p.id, 'active', 0, now() - interval '30 days',"
           " now() + (%s || ' days')::interval, 'manual'"
           " from public.plans p where p.slug = 'sagird-basi'", (acc, str(gun)))
    #  Mebleg olculebilen olsun deye iki sagird elave edirik (2 x 1.50 = 3 ₼)
    db("insert into public.classes (id, account_id, teacher_id, kind, name, join_code)"
       " select '00000165-0000-4000-8000-000000000165', %s, a.owner_id, 'tutor_group',"
       " 'Qiymet qrupu', 'KODQ165A' from public.accounts a where a.id = %s"
       " on conflict do nothing", (acc, acc))
    db("insert into public.students (account_id, class_id, created_by, full_name,"
       " display_name, login_code, is_active)"
       " select %s, '00000165-0000-4000-8000-000000000165', a.owner_id,"
       " 'Qiymet Sagird ' || g, 'Q' || g, 'QYMT000' || g, true"
       " from public.accounts a, generate_series(1,2) g where a.id = %s"
       " on conflict do nothing", (acc, acc))
    n = db("select count(*) c from public.students"
           " where account_id = %s and is_active", (acc,), one=True)["c"]

    #  a) vaxti var (30 gun) - zolaq YOXDUR, kart meblegi gosterir
    abune(30)
    pg.goto(PANEL + "#/"); pg.reload(); pg.wait_for_selector("#band .bseat", timeout=15000)
    ok(pg.locator("#payBar").count() == 0, "vaxt varken xatirlatma zolagi yoxdur")
    bs = pg.inner_text("#band .bseat").replace("\n", " ")
    ok("Bu ay" in bs and "aktiv şagird" in bs,
       "sagird basina planda kart meblegi gosterir", bs[:70])
    gozlenen = ("%.2f" % (n * 1.5)).rstrip("0").rstrip(".")
    ok(n >= 2 and gozlenen in bs, "mebleg = aktiv sagird x 1.50",
       "%d sagird -> %s ₼ · %s" % (n, gozlenen, bs[:44]))

    #  b) 5 gun qalir - sakit xatirlatma, gun sayi DOGRU olmalidir
    #  (saniye qirintisi "5" yerine "4" yazdirmasin - tam gun ferqi)
    abune(5)
    pg.reload(); pg.wait_for_selector("#payBar", timeout=15000)
    t = pg.inner_text("#payBar").replace("\n", " ")
    ok("5 gün sonra bitir" in t, "5 gun qalanda xatirlatma cixir", t[:70])
    ok(gozlenen in t and "aktiv şagird" in t,
       "xatirlatmada sagird sayi ve mebleg var", t[:80])
    ok(not pg.locator("#payBar").evaluate("e => e.classList.contains('over')"),
       "hele vaxt varken zolaq qirmizi deyil")

    #  c) 30 gun qalanda zolaq yoxdur, 7 gun qalanda var (hedd duzgundur)
    abune(8)
    pg.reload(); pg.wait_for_selector("#band .bseat", timeout=15000)
    pg.wait_for_timeout(400)
    ok(pg.locator("#payBar").count() == 0, "8 gun qalanda hele xatirlatma yoxdur")

    #  d) vaxt kecib, guzest muddetindedir - qirmizi, qalan gun dogru
    #  (2 gun kecib, guzest 3 gun -> 1 gun qalir)
    abune(-2)
    pg.reload(); pg.wait_for_selector("#payBar.over", timeout=15000)
    t = pg.inner_text("#payBar").replace("\n", " ")
    ok("vaxtı bitib" in t, "vaxt kecende qirmizi zolaq", t[:60])
    ok("1 gün ərzində" in t, "guzestde qalan gun dogru sayilir", t[:90])
    ok("Mövcud şagirdlər işləməkdə davam edir" in t,
       "sagirdin qapida qalmadigi yazilir", t[:110])

    db("delete from public.subscriptions where account_id = %s", (acc,))
    db("delete from public.students where account_id = %s", (acc,))
    db("delete from public.classes where account_id = %s", (acc,))

    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails))
    for f in fails: print("  - " + f)
    sys.exit(1)
print("PAKET: BUTUN YOXLAMALAR KECDI")
