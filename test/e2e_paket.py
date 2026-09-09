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

    print("A · Abunə səhifəsi (abunəsiz)")
    ok(pg.locator("#btnPkt").count() == 1, "esas sehifede Paket bendi var")
    ok(pg.locator("#btnAdm").count() == 0, "adi muellimde Idareetme bendi YOXDUR")
    pg.click("#bnav a[href='#/p']")
    pg.wait_for_selector(".abn", timeout=8000)
    mt = pg.inner_text("#main")
    ok("Abunəniz yoxdur" in mt, "abunesiz hal aydin yazilir")
    #  169: pilleli paket siyahisi YOXDUR - qayda birdir
    ok(pg.locator(".pkt").count() == 0, "pilleli paket siyahisi qalmayib",
       pg.locator(".pkt").count())
    ok("Şagird başına" in mt, "tek qayda gorunur")
    ok("1,50 ₼" in mt or "1.50 ₼" in mt, "tarif manatladir",
       mt[:80].replace("\n", " "))
    ok("Valideyn" not in mt, "ozge auditoriya plani gorunmur")
    #  qaydanin oz setirleri
    ok(pg.locator("#qayda li").count() == 6, "qayda 6 setirdir",
       pg.locator("#qayda li").count())
    #  172: mebleg gorunur - yaninda "hele odenis yoxdur" ACIQ durmalidir
    ok("beta dövrü bitəndən sonra" in mt, "beta qeydi qaydada var")
    ok("həmişə pulsuz" in mt, "sagird/valideyn pulsuzdur yazilir")
    ok("ilk ay hədiyyədir" in mt, "hediyye ayi yazilir")
    #  Muellim neyi ITIRECEYINI evvelceden gormelidir (istifadeci teleb etdi)
    ok(pg.locator(".cmp .cc").count() == 2, "pulsuz hedd / abune muqayisesi var",
       pg.locator(".cmp .cc").count())
    cmp_t = pg.inner_text(".cmp")
    for soz in ("Platforma sual bankı", "Diaqnostika", "Zəif mövzu analizi",
                "Dərs planı", "Cavab vərəqi", "gündə 20 sual"):
        ok(soz in cmp_t, "muqayisede «" + soz + "» yazilir")
    #  abunesiz hesabda hele sagird yoxdur -> 0 x 1,50 = 0 ₼
    abx = pg.inner_text(".abn").replace("\n", " ")
    ok("aktiv şagird" in abx and "ayda" in abx, "hesab qutusu qurulur", abx[:70])
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
    #  Emeliyyat duymeleri setirdeki «···» menyusundadir (cedvel
    #  qurulusu).  Menyu <details>-dir; testde onu birbasa aciriq -
    #  bu, klik yarisindan asili deyil.  Menyunun ELE KLIKLE
    #  acildigi asagida bir defe ayrica yoxlanilir.
    def menu_bas(setir, sec):
        pg.eval_on_selector_all(setir + " .rmenu", "els => els.forEach(e => e.open = true)")
        pg.wait_for_timeout(120)
        pg.locator(setir + " " + sec).click()
    ADM = ".admr[data-em='pkt@t.az']"
    pg.goto(PANEL); pg.reload()
    pg.wait_for_selector("#btnAdm", timeout=8000)
    ok("Admin · daimi" in pg.inner_text(".seat"), "ana sehifede pill 'Admin · daimi'",
       pg.inner_text(".seat").replace("\n", " "))
    ok(True, "admin rolunda Idareetme bendi gorunur")
    pg.click("#btnAdm")
    pg.wait_for_selector(".admr", timeout=8000)
    ok(pg.locator("#tBugun .tile").count() + pg.locator("#tUmumi .tile").count() == 7,
       "gosterici lovheleri gorunur", pg.locator(".tile").count())
    tl = pg.inner_text("#tUmumi").replace("\n", " ")
    ok("hesab" in tl and "pullu" in tl and "pulsuz" in tl and "gəlir" in tl,
       "lovhelerde hesab/pullu/pulsuz/gelir var", tl[:70])
    ok(pg.locator("#admF .chip").count() == 7,
       "pullu/sinaq/pulsuz/bitir/girmir/numune suzgec cipleri var",
       pg.locator("#admF .chip").count())
    ok("sınaq" in tl, "pullu lovhesinde sinaq sayi var", tl[:70])
    ok("yalnız ödənişli" in tl, "gelir lovhesi 'yalniz odenisli' deyir")
    #  173: lovheler iki setirdir - "Bu gün" 3, "Ümumi" 4
    ok(pg.locator("#tBugun .tile").count() == 3, "bu gun setri 3 lovhe",
       pg.locator("#tBugun .tile").count())
    ok(pg.locator("#tUmumi .tile").count() == 4 and "girib (7 gün)" in tl,
       "umumi setri 4 lovhe, sonuncuda heftelik giris", tl[-60:])
    print("C1 · (160) Hədiyyə paket ayarı")
    #  173: bolmeler yigilib gelir - Playwright gizli elementi gormur
    pg.eval_on_selector_all(".fold", "els => els.forEach(e => e.open = true)")
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
    ok(pg.locator(ADM + " .rmenu").count() == 0 and pg.locator(ADM + " button").count() == 0,
       "admin setrinde emeliyyat menyusu yoxdur")
    row = pg.inner_text(ROW).replace("\n", " ")
    ok("iki@t.az" in row, "hesab siyahida e-poctla gorunur", row[:60])
    ok("paketsiz" in row, "paketsiz nisani gorunur")
    row = arow
    ok("Son giriş" in pg.inner_text(".admt thead"), "son giris sutunu var")
    #  173: uc setirlik «Aktivlik» xanasi «Son giriş»e yigildi - esas
    #  siqnal muellimin girisidir, sagird girisi yalniz HEC VAXT olanda
    #  ayrica yazilir (hesab qurulub, amma islenmir).
    ok("bu gün" in row, "muellim girisi bu gun (rpc_seen)", row[-90:])
    #  Bu hesabda sagird YOXDUR - "hələ girməyib" xeberdarligi yalniz
    #  sagirdi olan hesabda menalidir (bos hesabda yanlis siqnal olardi).
    ok("şagird yoxdur" in row, "sagirdsiz hesabda xeberdarliq yoxdur", row[-60:])
    #  173: lovheler iki setre bolundu - "Bu gün" ve "Ümumi".
    ok(pg.inner_text("#tBugun .tile.b").startswith("1"),
       "bu gun giren muellim 1", pg.inner_text("#tBugun .tile.b").replace("\n", " "))
    ok("girib (7 gün)" in pg.inner_text("#tUmumi .tile.e"),
       "umumi setrinde sagird + heftelik giris",
       pg.inner_text("#tUmumi .tile.e").replace("\n", " "))
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

    #  (169) Gelir artiq "paketin qiymeti" deyil, AKTIV SAGIRD x tarif -
    #  ona gore yoxlamanin menali olmasi ucun hesaba sagird lazimdir.
    #  4 sagird (pulsuz hedd 5-dir, hele paketsizdir) -> 4 x 1,50 = 6 ₼.
    iki = db("select a.id from public.accounts a join auth.users u"
             " on u.id = a.owner_id where u.email = 'iki@t.az'", one=True)["id"]
    db("insert into public.classes (id, account_id, teacher_id, kind, name, join_code)"
       " select '00000169-0000-4000-8000-000000000169', %s, a.owner_id, 'tutor_group',"
       " 'Gelir qrupu', 'KODG169A' from public.accounts a where a.id = %s"
       " on conflict do nothing", (iki, iki))
    db("insert into public.students (account_id, class_id, created_by, full_name,"
       " display_name, login_code, is_active)"
       " select %s, '00000169-0000-4000-8000-000000000169', a.owner_id,"
       " 'Gelir Sagird ' || g, 'G' || g, 'GLR0000' || g, true"
       " from public.accounts a, generate_series(1,4) g where a.id = %s"
       " on conflict do nothing", (iki, iki))

    print("D0 · (138) Sınaq — pulsuz paket: tam imkan, gəlirə düşmür")
    pg.on("dialog", lambda d: d.accept())
    ok(pg.locator(".admr [data-trial]").count() == 1, "adi setirde 'Sinaq 1 ay' duymesi var (adminde yox)")
    #  «···» menyusu bagli gelir ve KLIKLE acilir (bir defe yoxlanilir)
    ok(not pg.locator(ROW + " .rmenu").evaluate("e => e.open"), "menyu bagli gelir")
    ok(not pg.locator(ROW + " [data-trial]").is_visible(), "menyu bagli ikən duyme gizlidir")
    pg.locator(ROW + " .rmenu summary").click(); pg.wait_for_timeout(200)
    ok(pg.locator(ROW + " [data-trial]").is_visible(), "«···» kliki menyunu acir")
    menu_bas(ROW, "[data-trial]")
    pg.wait_for_selector(ROW + " .pb.s", timeout=8000)
    ok("sınaq" in pg.inner_text(ROW + " .pb.s")
       and "Şagird başına" in pg.inner_text(ROW + " .pb.s"),
       "goy sinaq nisani setirde", pg.inner_text(ROW + " .pb.s")[:40])
    a0 = db("select s.status, s.provider from public.subscriptions s", one=True)
    ok(a0 and a0["status"] == "trialing" and a0["provider"] == "trial",
       "bazada trialing/trial abune var", a0)
    tb = pg.inner_text("#tUmumi .tile.b").replace("\n", " ")
    ok(tb.startswith("0") and "1 sınaq" in tb, "lovhe: 0 pullu · 1 sinaq", tb)
    ok("0,00" in pg.inner_text("#tUmumi .tile.c") or "0 ₼" in pg.inner_text("#tUmumi .tile.c"),
       "gelir sifirdir", pg.inner_text("#tUmumi .tile.c").replace("\n", " "))
    pg.locator("#admF .chip[data-f='sinaq']").click()
    #  siyahi yeniden cizilene qeder gozle (kohne siyahida da .pb.s var)
    pg.wait_for_function("document.querySelectorAll('.admr').length === 1", timeout=8000)
    ok("iki@t.az" in pg.inner_text(".admr") and pg.locator(".admr").count() == 1,
       "sinaq suzgecinde yalniz o hesab gorunur")
    pg.locator("#admF .chip[data-f='pullu']").click(); pg.wait_for_timeout(700)
    ok("Hesab tapılmadı" in pg.inner_text("#admList"), "pullu suzgecinde sinaq hesab cixmir")
    pg.locator("#admF .chip[data-f='']").click(); pg.wait_for_selector(".admr", timeout=8000)

    print("D · Bir kliklə abunə açmaq (sınaq → ödənişli)")
    menu_bas(ROW, "[data-m='6']")
    pg.wait_for_selector(ROW + " .pb.y", timeout=8000)
    ok("Şagird başına" in pg.inner_text(ROW + " .pb.y"), "abune nisani setirde gorunur",
       pg.inner_text(ROW + " .pb.y")[:40])
    ok("yerinə yetirildi" in pg.inner_text("#admMsg"), "netice mesaji gorunur")
    ok(pg.inner_text("#tUmumi .tile.b").replace("\n", " ").startswith("1"), "aktiv abune lovhesi yenilenir",
       pg.inner_text("#tUmumi .tile.b").replace("\n", " "))
    #  (169) 4 aktiv sagird x 1,50 = 6 ₼.  Kohne pilleli paketde bu
    #  reqem 29 ₼ idi (paketin qiymeti) - artiq sagird sayina baglidir.
    ok("6,00" in pg.inner_text("#tUmumi .tile.c") or "6 ₼" in pg.inner_text("#tUmumi .tile.c"),
       "gelir = 4 aktiv sagird x 1,50 = 6 ₼", pg.inner_text("#tUmumi .tile.c").replace("\n", " "))
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

    print("E · Abunə səhifəsi abunəni göstərir")
    pg.goto(PANEL + "#/p"); pg.reload()
    pg.wait_for_selector(".abn", timeout=8000)
    mt = pg.inner_text("#main")
    ok("Admin hesabı" in mt, "admin ucun ayrica veziyyet yazilir",
       mt[:80].replace("\n", " "))
    ok("Admin · daimi" in mt, "plan adi 'Admin · daimi'",
       mt[:80].replace("\n", " "))

    print("F · Dayandırmaq")
    pg.goto(PANEL + "#/adm"); pg.reload()
    pg.wait_for_selector(".admr", timeout=8000)
    ok(pg.locator(".admr [data-stop]").count() == 1, "Dayandir yalniz abuneli adi setirde")
    menu_bas(ROW, "[data-stop]")
    pg.wait_for_timeout(900)
    pg.wait_for_selector(".admr", timeout=8000)
    ok(not db("select 1 ok from public.subscriptions where status='active'", one=True),
       "bazada aktiv abune qalmadi")

    print("G · (165) Şagird başına paket və ödəniş xatırlatması")
    #  DIQQET: bu hesab yuxarida ADMIN olub.  173-den sonra rpc_my_context
    #  admin hesabina "Admin · daimi" qaytarir (qiymet gostermir) - ona
    #  gore sagird basina karti gormek ucun rol MUVEQQETI goturulur.
    #  Guzestin baza mentiqi db/test/smoke_qiymet.sql-dedir.
    db("delete from public.user_roles where user_id = %s and role = 'admin'", (UID,))
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

    #  e) (169) abune sehifesi eyni meblegi gosterir - reqem SERVERDEN
    abune(30)
    pg.goto(PANEL + "#/p"); pg.reload()
    pg.wait_for_selector(".abn", timeout=15000)
    ab = pg.inner_text(".abn").replace("\n", " ")
    ok(str(n) in ab and gozlenen in ab,
       "abune sehifesinde hesab: %d sagird -> %s ₼" % (n, gozlenen), ab[:80])
    ok("Bu ayın hesabı" in pg.inner_text("#main"), "hesab bolmesi basligi var")

    #  f) (169) hediyye ayinda mebleg tutulmur - 'Novbeti ay' yazilir
    #  Admin rolu MUVEQQETI goturulur: rpc_paket admin hesabina hemise
    #  "Admin - daimi" qaytarir, hediyye veziyyeti gorunmezdi.
    db("update public.subscriptions set provider = 'gift', status = 'trialing'"
       " where account_id = %s", (acc,))
    pg.goto(PANEL + "#/"); pg.reload(); pg.wait_for_selector("#band .bseat", timeout=15000)
    bs = pg.inner_text("#band .bseat").replace("\n", " ")
    #  172: mebleg SERTI dilde durur - "bu ay" yox, "beta bitendən sonra"
    ok("Beta bitəndən sonra aylıq" in bs,
       "hediyye ayinda mebleg serti dilde yazilir", bs[:80])
    #  172: kartda qalan gun ve "indi odenis yoxdur" qeydi
    ok("Hədiyyə bitir" in bs and "gün" in bs,
       "kartda hediyyenin bitme tarixi ve qalan gun", bs[:110])
    ok("İndi ödəniş yoxdur" in bs, "kartda 'indi odenis yoxdur' qeydi", bs[:140])
    #  hediyye karti (yalniz ESAS sehifede olur) paketin sertini yazir
    gc = pg.inner_text("#giftCard").replace("\n", " ")
    ok("şagird başına" in gc and "Beta bitəndən sonra" in gc
       and "İndi heç nə tutulmur" in gc,
       "hediyye kartinda paket serti + beta qeydi", gc[-130:])
    #  konkret hesab: N aktiv sagird -> M ₼ / ay "ederdi"
    ok("aktiv şagird" in gc and gozlenen in gc and "edərdi" in gc,
       "hediyye kartinda konkret hesab (serti dilde)", gc[-170:])
    pg.goto(PANEL + "#/p"); pg.reload()
    pg.wait_for_selector(".abn", timeout=15000)
    mt = pg.inner_text("#main")
    ok("Hədiyyə ay" in mt, "hediyye veziyyeti yazilir", mt[:90].replace("\n", " "))
    ok("beta dövrü bitəndən sonra" in mt, "abune sehifesinde beta qeydi")
    ab = pg.inner_text(".abn").replace("\n", " ")
    ok("beta bitəndən sonra aylıq" in ab and gozlenen in ab,
       "hediyye ayinda qutu serti dilde mebleg yazir", ab[:90])

    #  g) adminin EL ILE verdiyi sinaq da pulsuzdur - eyni davranis.
    #  Evvel ekran yalniz provider='gift'-e baxirdi: el ile verilmis
    #  sinaqda kart "Bu ay N ₼" yazirdi, altdaki kart ise "Tam paket
    #  sizə hədiyyədir" - ziddiyyet idi.
    db("update public.subscriptions set provider = 'trial'"
       " where account_id = %s", (acc,))
    pg.goto(PANEL + "#/"); pg.reload(); pg.wait_for_selector("#band .bseat", timeout=15000)
    bs = pg.inner_text("#band .bseat").replace("\n", " ")
    ok("Beta bitəndən sonra aylıq" in bs,
       "el ile verilmis sinaqda da serti dil", bs[:80])
    pg.goto(PANEL + "#/p"); pg.reload()
    pg.wait_for_selector(".abn", timeout=15000)
    mt = pg.inner_text("#main")
    ok("Sınaq ayı" in mt and "0 ₼" in mt, "sinaq ayi veziyyeti yazilir",
       mt[:90].replace("\n", " "))
    ab = pg.inner_text(".abn").replace("\n", " ")
    ok("beta bitəndən sonra aylıq" in ab and gozlenen in ab,
       "sinaq ayinda qutu serti dilde mebleg yazir", ab[:90])

    db("insert into public.user_roles (user_id, role) values (%s, 'admin')"
       " on conflict do nothing", (UID,))

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
