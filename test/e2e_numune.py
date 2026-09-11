#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Numune (demo) hesab - ucdan-uca (db/136).

Ana sehifeden uc giris: "Muellim kimi bax" (anonim giris + oz nusxe,
zolaq, 2 qrup, "Bu gunun dersi"nde etmeyenler), "Sagird kimi bax"
(?kod=DEMO0001 avtomatik giris), "Valideyn kimi bax" (?kod=VDEMO001)."""
import time
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

ROOT    = "http://127.0.0.1:8010/"
PANEL   = ROOT + "muellim/index.html"
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

#  evvelki isden qalan anonim nusxeler (24 saatdan teze - sifirlama silmir)
db("""
delete from public.classes c using public.accounts a where a.id = c.account_id and a.is_demo and a.id <> app.demo_account();
delete from public.tests t using public.accounts a where a.owner_id = t.owner_id and a.is_demo and a.id <> app.demo_account();
delete from public.students s using public.accounts a where a.id = s.account_id and a.is_demo and a.id <> app.demo_account();
create temp table demo_old_e2e as select owner_id from public.accounts where is_demo and id <> app.demo_account();
delete from public.accounts where is_demo and id <> app.demo_account();
delete from auth.users u using demo_old_e2e o where u.id = o.owner_id
  and not exists (select 1 from public.accounts a2 where a2.owner_id = u.id);""")
#  paylasilan numune: is axininin etdiyini burada biz edirik
db("delete from public.app_state where key='demo_reset'")
db("select public.rpc_demo_reset()")

def page(ctx, w, h):
    pg = ctx.new_page(); pg.set_viewport_size({"width": w, "height": h})
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=TEST_CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))
    pg.on("dialog", lambda d: (fails.append("DIALOQ: " + d.message), d.dismiss()))
    return pg

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context()
    pg = page(ctx, 430, 1000)

    print("A · Ana səhifədə üç nümunə düyməsi")
    pg.goto(ROOT + "index.html"); pg.wait_for_selector("#demo", timeout=15000)
    links = pg.locator("#demo a").evaluate_all("els => els.map(e => e.getAttribute('href'))")
    ok(links == ["muellim/#/demo", "sagird/?kod=DEMO0001", "valideyn/?kod=VDEMO001"], "uc link", links)

    print("A2 · (185) Giriş ekranında nümunə keçidi")
    #  Huninin en boyuk deliyi: formaya gelen 18 neferden 12-si geri
    #  donurdu, numuneye kecid ise yalniz ana sehifede idi.
    ap = page(ctx, 412, 915)
    ap.goto(ROOT + "muellim/index.html")
    ap.wait_for_selector("#btnAuth", timeout=20000)
    ok(ap.locator("#btnDemoGo").count() == 1, "giris ekraninda «Nümunəyə bax» duymesi")
    ok(ap.locator(".authback a[href='../']").count() == 1,
       "giris ekraninda sayta qayidis")
    ap.click("#btnSwap"); ap.wait_for_selector("#fname", timeout=10000)
    ok(ap.locator("#btnDemoGo").count() == 1, "qeydiyyat ekraninda da var")
    ap.click("#btnSwap"); ap.wait_for_selector("#btnAuth", timeout=10000)
    #  Duyme ISLEMELIDIR: evvel nav() cagirilirdi, hashchange ise yalniz
    #  sessiya varsa marsrut qurur - unvan deyisir, ekran qalirdi.
    SAY = "select count(*) n from public.visits where page='giris' and ev='demo_muellim'"
    n0 = db(SAY, one=True)["n"]
    ap.click("#btnDemoGo")
    ap.wait_for_selector("#demoBar", timeout=60000)
    ap.wait_for_selector("#groups .gcard", timeout=30000)
    ok(ap.locator("#groups .gcard").count() == 3, "duyme numuneni acir",
       ap.locator("#groups .gcard").count())
    #  185: klik sayilir - ana sehifedeki klikden AYRI ('giris' sehifesi)
    n1 = db(SAY, one=True)["n"]
    ok(n1 > n0, "klik «giris» sehifesi kimi sayilir", str(n0) + " -> " + str(n1))
    ap.close()

    print("B · Müəllim kimi bax: anonim giriş, öz nüsxə, zolaq")
    pg.click("#demo a[href='muellim/#/demo']")
    pg.wait_for_selector("#demoBar", timeout=40000)
    bar = pg.inner_text("#demoBar")
    ok("Nümunə hesab" in bar and "24 saat" in bar, "numune zolagi", bar[:80])
    codes = pg.locator("#demoBar code").all_inner_texts()
    ok(len(codes) == 2 and codes[0] != "DEMO0001" and len(codes[0]) == 8 and codes[1].startswith("V"), "oz nusxenin kodlari (paylasilan deyil)", codes)
    ok(db("select count(*) n from public.accounts where is_demo", one=True)["n"] == 2, "paylasilan + nusxe = 2 numune hesab")
    pg.wait_for_selector("#groups .gcard", timeout=15000)
    ok(pg.locator("#groups .gcard").count() == 3, "uc qrup", pg.locator("#groups .gcard").count())
    #  183: numune 'repetitor-25' uzerinde otururdu - 25 sagirdle limit
    #  hemise dolu idi ve Icmalda qirmizi xeberdarliq cixirdi.
    icmal = pg.evaluate("document.body.textContent")
    ok("Paketin limiti dolub" not in icmal, "paket limiti xeberdarligi yoxdur (183)")
    #  183: cedvel elave olundu - «Bu gün dərs var» / hefte karti
    ok(len(pg.inner_text("#hWeek").strip()) > 0, "hefte cedveli karti dolu (183)",
       pg.inner_text("#hWeek")[:60].replace("\n", " "))
    ok("Nümunə Müəllim" in pg.inner_text("#topWho"), "ad: Numune Muellim")
    pg.locator("#groups .gcard", has_text="7-ci sinif").first.click(); pg.wait_for_selector("#gTabs", timeout=15000)
    pg.wait_for_selector("#prep .prep", timeout=20000)
    #  CSS boyuk herf edir - textContent oxunur
    pt = pg.evaluate("document.querySelector('#prep').textContent")
    ok("Etməyənlər" in pt and "4/12" in pt, "bu gunun dersi: 4 nefer etmeyib", pt[:160].replace("\n", " "))
    ok(pg.locator(".stu").count() == 12, "12 sagird")
    pg.click("#gTabs [data-v='p']"); pg.wait_for_selector(".plan .plhead", timeout=15000)
    ok("9 /" in pg.inner_text(".plan .plhead"), "planda 9 movzu kecilib", pg.inner_text(".plan .plhead"))
    #  zolaq her ekranda qalir
    pg.goto(PANEL + "#/"); pg.reload(); pg.wait_for_selector("#demoBar", timeout=15000)
    ok(pg.locator("#demoBar").count() == 1, "yenilenende zolaq qalir")
    print("B2 · (167) Ən yaxşı şagirdlər — qrup üzrə, klik şagirdə girir")
    #  Numune hesabda yalniz BIR qrupda 3+ testli sagird var - cip
    #  cixmasi ucun ikinci qrupa da cehd elave edirik (nusxe hesaba).
    db("""
      insert into public.attempts (student_id, test_id, status, percent, finished_at)
      select s.id, t.id, 'submitted', 70 + (g * 5), now() - (g || ' days')::interval
        from public.students s
        join public.classes c on c.id = s.class_id and c.name like '3-c%%'
        join public.accounts a on a.id = s.account_id
                              and a.is_demo and a.id <> app.demo_account()
        cross join lateral (select id from public.tests
                             where owner_id = a.owner_id limit 1) t
        cross join generate_series(1, 3) g
       where s.is_active""")
    pg.goto(PANEL + "#/"); pg.reload()
    pg.wait_for_selector("#hTop5 .lrow", timeout=25000)
    pg.wait_for_selector("#topF .chip", timeout=15000)
    ok(pg.locator("#topF .chip").count() >= 2, "qrup cipleri cixir",
       pg.locator("#topF .chip").count())
    #  Siralama MUQAYISEDIR - "Hamisi" cipi OLMAMALIDIR (ferqli
    #  qruplarin faizini yan-yana qoymaq mehz yanlis olan seydir)
    cips = pg.locator("#topF .chip").all_inner_texts()
    ok("Hamısı" not in cips, "«Hamısı» cipi yoxdur (siyahi muqayisedir)", cips)
    ok(pg.locator("#topF .chip.on").count() == 1, "hemise bir qrup secilidir")
    ok(pg.locator("#hTop5 .lrow").count() <= 5, "qrup basina en cox 5 setir",
       pg.locator("#hTop5 .lrow").count())
    ilk = pg.inner_text("#hTop5")
    #  Ikinci qrupa kecende siyahi DEYISIR
    pg.locator("#topF .chip").nth(1).click(); pg.wait_for_timeout(600)
    ok(pg.locator("#topF .chip.on").count() == 1, "kecidde de bir cip secili qalir")
    ok(pg.inner_text("#hTop5") != ilk, "cip deyisende siyahi deyisir")
    #  Klik SAGIRDE girir - evvel qrup id-si oturulmediyi ucun marsrut
    #  tanimir ve ana ekran yeniden cizilirdi ("sehife yuxari qalxdi")
    pg.locator("#hTop5 .lrow").first.click()
    pg.wait_for_timeout(1000)
    ok("#/s/" in pg.url, "klik sagird hesabatina girir (qrup id-si ile)",
       pg.url.split("#")[-1])
    ok(pg.locator("#hTop5").count() == 0, "ana ekrana qayitmayib")
    pg.goto(PANEL + "#/"); pg.wait_for_selector("#groups .gcard", timeout=20000)

    #  "Oz hesabimi ac" -> qeydiyyat ekrani
    pg.click("#demoOwn"); pg.wait_for_selector("#btnAuth", timeout=15000)
    ok(pg.locator("#demoBar").count() == 0 and pg.locator("#fname").count() == 1, "oz hesab: qeydiyyat ekrani, zolaq yoxdur")

    print("C · Şagird kimi bax: ?kod= ilə avtomatik giriş")
    sp = page(ctx, 390, 844)
    sp.goto(ROOT + "sagird/?kod=DEMO0001"); sp.wait_for_selector(".test", timeout=20000)
    ok("Ayan" in sp.inner_text("body"), "sagird girdi (Ayan)", sp.inner_text("#topTitle") if sp.locator("#topTitle").count() else "")
    ok(sp.locator(".test.asg").count() == 1, "bir acıq tapsiriq")
    ok("kod=" not in sp.url, "unvandan kod silinib")
    #  Bu uc bolme AYRICA sorgularla gelir (sehv defteri, movzu mesqi) -
    #  derhal oxusaq bezen hele bos olur.  Gorunene qeder gozleyirik.
    try:
        sp.wait_for_function(
            "() => { const t = document.body.textContent;"
            " return t.includes('Zəif mövzular') && t.includes('Səhv dəftəri')"
            " && t.includes('Mövzu məşqi'); }", timeout=15000)
    except Exception:
        pass
    st = sp.evaluate("document.body.textContent")
    ok("Zəif mövzular" in st and "Səhv dəftəri" in st and "Mövzu məşqi" in st, "zeif movzu, sehv defteri, movzu mesqi kartlari")

    print("D · Valideyn kimi bax")
    vp = page(ctx, 390, 844)
    vp.goto(ROOT + "valideyn/?kod=VDEMO001"); vp.wait_for_selector(".who", timeout=20000)
    vt = vp.evaluate("document.body.textContent")
    ok("Ayan" in vt and "Davamiyyət" in vt and "Mövzu məşqi" in vt, "valideyn ekrani: usaq, davamiyyet, movzu mesqi", vt[:120].replace("\n", " "))

    print("G0 · (184) Nümunədən çıxış: müəllim paneli")
    #  Ziyaretci numune panelinde «Çıxış»a basanda giris formasi acilirdi -
    #  hesabi olmayan adam ucun dalan.  Ustelik «Nümunə hesab» zolagi
    #  giris formasinin ustunde asili qalirdi.
    pg3b = page(ctx, 412, 900)
    pg3b.goto(PANEL + "#/demo")
    pg3b.wait_for_selector("#demoBar", timeout=40000)
    pg3b.wait_for_selector("#groups .gcard", timeout=20000)
    ok(pg3b.inner_text("#btnOut").strip() == "Nümunədən çıx",
       "muellim: ust zolaqda «Nümunədən çıx»", pg3b.inner_text("#btnOut"))
    pg3b.click("#btnOut"); pg3b.wait_for_load_state("load"); pg3b.wait_for_timeout(1200)
    ok(pg3b.url.rstrip("/").endswith("8010") or pg3b.url.endswith("/index.html"),
       "muellim: duyme sayta qaytarir", pg3b.url)
    pg3b.close()

    print("G · (184) Nümunədən çıxış: şagird və valideyn")
    #  Ziyaretci numuneye baxirdi ve sayta qayida bilmirdi: «Çıxış»
    #  kod ekranini acirdi, orada yazacaq kodu yox idi.
    ok(sp.inner_text("#btnOut").strip() == "Nümunədən çıx",
       "sagird: ust zolaqda «Nümunədən çıx»", sp.inner_text("#btnOut"))
    sp.click("#btnOut"); sp.wait_for_load_state("load"); sp.wait_for_timeout(800)
    ok(sp.url.rstrip("/").endswith("8010") or sp.url.endswith("/index.html")
       or sp.url == ROOT, "sagird: duyme sayta qaytarir", sp.url)
    ok(vp.inner_text("#btnOut").strip() == "Nümunədən çıx",
       "valideyn: ust zolaqda «Nümunədən çıx»", vp.inner_text("#btnOut"))
    vp.click("#btnOut"); vp.wait_for_load_state("load"); vp.wait_for_timeout(800)
    ok(vp.url.rstrip("/").endswith("8010") or vp.url.endswith("/index.html")
       or vp.url == ROOT, "valideyn: duyme sayta qaytarir", vp.url)
    #  Kod ekrani da dalan olmamalidir: gorunen qayidis duymesi
    for yol, ad in ((ROOT + "sagird/", "sagird"), (ROOT + "valideyn/", "valideyn")):
        kp = page(ctx, 390, 844)
        kp.goto(yol)
        kp.wait_for_selector("#btnIn", timeout=20000)
        ok(kp.locator("a.btn.bak").count() == 1,
           ad + ": kod ekraninda gorunen «ana səhifə» duymesi")
        ok(kp.locator("a.btn.bak").get_attribute("href") == "../",
           ad + ": duyme sayta baglidir")
        kp.close()

    print("E · Sıfırlama: paylaşılan yenidən qurulur, kodlar eyni")
    db("update public.app_state set val = jsonb_build_object('at', now() - interval '1 hour') where key='demo_reset'")
    r = db("select public.rpc_demo_reset() v", one=True)["v"]
    ok(r["student_code"] == "DEMO0001" and r["deleted_copies"] == 0 and r["students"] == 25, "sifirlama: eyni kod, 25 sagird, teze nusxe silinmir", r)
    ok(db("select count(*) n from public.students where login_code='DEMO0001'", one=True)["n"] == 1, "DEMO0001 tekdir")

    print("F · (159) Saatlıq hədd: sakit kart, «Yenidən cəhd et»")
    db("""insert into auth.users (id, email)
         select ('11110000-0000-0000-0000-00000000e1' || lpad(g::text, 2, '0'))::uuid, null from generate_series(1,20) g;
         insert into public.accounts (id, type, name, owner_id, is_demo)
         select ('aaaa0000-0000-0000-0000-00000000e1' || lpad(g::text, 2, '0'))::uuid, 'tutor', 'Nümunə hesabı',
                ('11110000-0000-0000-0000-00000000e1' || lpad(g::text, 2, '0'))::uuid, true from generate_series(1,20) g""")
    ctx3 = br.new_context(); pg3 = page(ctx3, 430, 900)
    pg3.goto(PANEL + "#/demo")
    pg3.wait_for_selector("#demoLim", timeout=20000)
    ok("Nümunə hazırlanır" in pg3.inner_text("#demoLim") and pg3.locator("#demoRetry").count() == 1,
       "hedd kecende sakit kart ve Yeniden cehd duymesi", pg3.inner_text("#demoLim")[:60])
    ok(pg3.locator("#demoBar").count() == 0, "nusxe qurulmadi")
    db("""delete from public.accounts where owner_id::text like '11110000-0000-0000-0000-00000000e1%%';
         delete from auth.users where id::text like '11110000-0000-0000-0000-00000000e1%%'""")
    pg3.click("#demoRetry")
    pg3.wait_for_selector("#demoBar", timeout=40000)
    ok(pg3.locator("#demoBar").count() == 1, "hedd kecdikden sonra Yeniden cehd nusxeni qurur")
    ctx3.close()

    br.close()

print()
if fails:
    print("XETA:", len(fails)); [print("  -", f) for f in fails]; raise SystemExit(1)
print("hamisi kecdi")
