#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sagird tetbiqini real brauzerde, real sxem uzerinde surur."""
import json, re, sys
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

APP = "http://127.0.0.1:8010/sagird/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
TEST_CFG = """window.CFG = {
  SUPABASE_URL: "http://127.0.0.1:54321",
  SUPABASE_ANON_KEY: "test-anon-key"
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

# ---------- hazirliq: muellim, hesab, qrup, sagird ----------
db("""
-- DIQQET: truncate ... cascade profiles-e istinad eden tests cedvelini de
-- bosaldir - platforma testleri itir. Ona gore hedefli silme.
delete from public.attempt_answers;
delete from public.attempts;
delete from public.student_sessions;
delete from public.students;
delete from public.classes;
delete from public.account_members;
delete from public.accounts;
delete from public.user_roles;
delete from auth.users;
insert into auth.users (id, email, raw_user_meta_data) values
  ('a1a1a1a1-0000-0000-0000-000000000001','m@t.az','{"full_name":"Muellim"}');
insert into public.accounts (id, type, name, owner_id) values
  ('b1b1b1b1-0000-0000-0000-000000000001','tutor','Qrup','a1a1a1a1-0000-0000-0000-000000000001');
insert into public.account_members values
  ('b1b1b1b1-0000-0000-0000-000000000001','a1a1a1a1-0000-0000-0000-000000000001',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('c1c1c1c1-0000-0000-0000-000000000001','b1b1b1b1-0000-0000-0000-000000000001',
   'a1a1a1a1-0000-0000-0000-000000000001','tutor_group','3-B qrupu','QRUP1234');
insert into public.students (id, account_id, class_id, created_by, full_name,
                             display_name, login_code) values
  ('d1d1d1d1-0000-0000-0000-000000000001','b1b1b1b1-0000-0000-0000-000000000001',
   'c1c1c1c1-0000-0000-0000-000000000001','a1a1a1a1-0000-0000-0000-000000000001',
   'Aysu Məmmədova','Aysu M.','AYSUKOD1'),
  ('d1d1d1d1-0000-0000-0000-000000000002','b1b1b1b1-0000-0000-0000-000000000001',
   'c1c1c1c1-0000-0000-0000-000000000001','a1a1a1a1-0000-0000-0000-000000000001',
   'Kənan Əliyev','Pələng','KENANKOD');
""")

# Platforma testleri yerindedirmi? Yoxdursa yeniden yaziriq -
# bele olanda test hansi siradan isledilmesinden asili qalmir.
if not db("select 1 from public.tests where owner_type='platform' limit 1", one=True):
    db(open("db/07_seed_tests.sql", encoding="utf-8").read())

# Duzgun cavablari IMTIYAZLI rolda gotururuk (test ozu ucun)
KEY = {}
for r in db("""
  select q.id::text qid, o.id::text oid
    from public.questions q
    join public.test_questions tq on tq.question_id = q.id
    join public.tests t on t.id = tq.test_id and t.slug = 'riy-3-vurma-1'
    join public.question_options o on o.question_id = q.id and o.is_correct"""):
    KEY[r["qid"]] = r["oid"]
NQ = len(KEY)

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 400, "height": 860})
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=TEST_CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))

    print("A · Giriş")
    pg.goto(APP); pg.wait_for_selector("#btnIn", timeout=8000)
    ok(True, "giris ekrani acilir")
    pg.fill("#code", "yoxdur9"); pg.click("#btnIn"); pg.wait_for_timeout(700)
    e = pg.inner_text("#lErr").lower()
    ok(("tapil" in e or "tapıl" in e or "yanlis" in e or "yanlış" in e),
       "yanlis kodda anlasilan mesaj (500 yox)", pg.inner_text("#lErr").strip()[:50])
    ok(pg.is_visible("#btnIn"), "xetadan sonra ekran qalir")

    pg.fill("#code", "aysukod1")          # kicik herfle yazsa da islemelidir
    ok(pg.input_value("#code") == "AYSUKOD1", "kod avtomatik boyuk herfe cevrilir")
    pg.click("#btnIn")
    pg.wait_for_selector(".test", timeout=8000)
    ok(True, "kodla giris isleyir")
    ok("Aysu M." in pg.inner_text("#topTitle"), "ustlukde leqeb gorunur")
    ok("3-B qrupu" in pg.inner_text("#main"), "qrup adi gorunur")

    print("B · Test siyahısı")
    n = pg.locator(".test").count()
    ok(n == 4, "4 test gorunur", n)
    ok(pg.locator(".test.lock").count() == 1, "odenisli test kilidlidir")
    ok(pg.locator(".test.lock").first.is_disabled(), "kilidli teste toxunmaq olmur")

    print("C · Testi işləmək")
    pg.evaluate("window.__tid = " + json.dumps(db("select id::text i from public.tests where slug=\'riy-3-vurma-1\'", one=True)["i"]))
    pg.locator(".test:not(.lock)", has_text="Vurma cədvəli").first.click()
    pg.wait_for_selector(".opt", timeout=8000)
    ok("1 / " + str(NQ) in pg.inner_text(".prog"), "irelileyis gostericisi",
       pg.inner_text(".prog").replace("\n", " "))
    ok(pg.is_disabled("#btnNext"), "cavab secilmeden novbeti duymesi bagli")

    body = pg.inner_text(".q .body")
    ok(len(body) > 3, "sual metni gorunur", body[:40])
    # Brauzerde az/tr sesi yoxdur -> duyme gizli olmalidir.
    # Ingilis sesi ile azerbaycanca oxumaq anlasilmaz cixir.
    has_voice = pg.evaluate(
        "(()=>{try{return (speechSynthesis.getVoices()||[])"
        ".some(v=>/^(az|tr)/i.test(v.lang||''));}catch(e){return false}})()")
    ok(pg.is_visible("#spk") == bool(has_voice),
       "seslendirme duymesi yalniz uygun ses olanda gorunur",
       "ses var" if has_voice else "ses yoxdur -> gizli")

    # Cavab acari sehifeye sizmayibmi?
    html = pg.content()
    ok("is_correct" not in html, "sehifede is_correct yoxdur")
    ok("explanation" not in html, "izah cavabdan evvel sizmir")

    # Butun suallara DUZGUN cavab veririk
    for i in range(NQ):
        opts = pg.locator(".opt")
        qid = pg.evaluate("(() => { const s = window.__S; return null; })()")
        # duzgun variantin id-sini DOM-dan tapiriq
        ids = opts.evaluate_all("els => els.map(e => e.getAttribute('data-o'))")
        want = None
        for oid in ids:
            if oid in KEY.values(): want = oid; break
        ok(want is not None, "sual %d ucun duzgun variant tapildi" % (i + 1)) if i == 0 else None
        pg.locator("[data-o='%s']" % want).click()
        pg.wait_for_timeout(120)
        if i == 0:
            ok(pg.locator(".opt.sel").count() == 1, "secilen variant isaretlenir")
            ok(not pg.is_disabled("#btnNext"), "cavabdan sonra duyme acilir")
        pg.click("#btnNext")
        pg.wait_for_timeout(350)

    print("D · Nəticə")
    pg.wait_for_selector(".ring", timeout=8000)
    ok("100" in pg.inner_text(".ring .val"), "hamisi duzgun -> 100%",
       pg.inner_text(".ring .val").replace("\n", ""))
    ok(str(NQ) + " / " + str(NQ) in pg.inner_text(".score"), "bal duzgun",
       pg.inner_text(".score").replace("\n", " "))
    ok("səhv suallar" not in pg.inner_text("#main").lower(), "sehv siyahisi gorunmur")

    print("E · Nəticə ekranı")
    ok("yadda saxlanıldı" in pg.inner_text("#main"),
       "netice bazaya yazildigi bildirilir")
    ok(pg.locator("#btnWa").count() == 0,
       "WhatsApp duymesi yoxdur (netice onsuz da bazadadir)")
    ok(pg.is_visible("#btnHome") and pg.is_visible("#btnLb"),
       "Testler ve Lovhe duymeleri var")

    print("F · Lövhə")
    pg.click("#btnLb"); pg.wait_for_selector(".lb", timeout=8000)
    ok("Vurma cədvəli" in pg.inner_text("#main"),
       "lovhede hansi testin oldugu yazilir")
    ok("qrupundan" in pg.inner_text("#main"), "qrup adi da gorunur")
    ok(pg.locator(".lb").count() == 1, "lovhede bir netice var")
    ok(pg.locator(".lb.me").count() == 1, "oz setri isaretlenib")
    ok("Aysu M." in pg.inner_text(".lb"), "leqeb gorunur")
    ok("Məmmədova" not in pg.inner_text("#main"), "lovhede tam ad yoxdur")

    print("G · Bitmiş test təkrar işlənmir")
    pg.click("#btnB"); pg.wait_for_selector(".ring", timeout=8000)
    pg.click("#btnHome"); pg.wait_for_selector(".test", timeout=8000)
    row = pg.locator(".test", has_text="Vurma cədvəli").first
    ok("100%" in row.inner_text(), "siyahida onceki netice gorunur",
       row.inner_text().replace("\n", " "))
    ok("nəticəni gör" in row.inner_text().lower(),
       "islenmis test aydin isarelenir", row.inner_text().replace("\n", " ")[-40:])

    row.click(); pg.wait_for_timeout(900)
    ok(pg.locator(".opt").count() == 0, "yeni cehd ACILMIR - sual gorunmur")
    ok(pg.locator(".ring").count() == 1, "evezine netice ekrani acilir")
    t = pg.inner_text("#main")
    ok("yenidən işləmək olmaz" in t, "sagirde sebeb izah olunur")
    ok("yuxarıda nəticən" in t, "netice ekranin harasinda oldugu gosterilir")
    ok("Bir də cəhd edə bilərsən" not in t,
       "cehd qalmayanda 'bir de cehd ede bilersen' YAZILMIR")
    ok("100" in pg.inner_text(".ring .val"), "kohne netice gosterilir")

    # Frontend-e etibar etmirik: birbasa sorgu da bloklanmalidir
    st = pg.evaluate("""(async () => {
      const t = JSON.parse(localStorage.getItem('sagird_ses')).t;
      const r = await fetch(window.CFG.SUPABASE_URL + '/rest/v1/rpc/rpc_start_attempt', {
        method: 'POST',
        headers: {apikey: window.CFG.SUPABASE_ANON_KEY,
                  Authorization: 'Bearer ' + window.CFG.SUPABASE_ANON_KEY,
                  'Content-Type': 'application/json'},
        body: JSON.stringify({p_token: t, p_test_id: window.__tid})});
      return r.status;
    })()""")
    ok(st in (400, 403), "birbasa sorgu ile de yeni cehd acilmir (server bloklayir)", st)

    print("H · Səhv cavab yolu")
    pg.click("#btnHome"); pg.wait_for_selector(".test", timeout=8000)
    pg.locator(".test:not(.lock)", has_text="Azərbaycan dili").first.click()
    pg.wait_for_selector(".opt", timeout=8000)
    naz = db("""select count(*) n from public.test_questions tq join public.tests t
                 on t.id=tq.test_id and t.slug='az-3-dil-1'""", one=True)["n"]
    for i in range(naz):
        pg.locator(".opt").first.click()      # hemise birinci variant
        pg.wait_for_timeout(100)
        pg.click("#btnNext"); pg.wait_for_timeout(300)
    pg.wait_for_selector(".ring", timeout=8000)
    ok("səhv suallar" in pg.inner_text("#main").lower(),
       "sehv suallar siyahisi cixir")
    ok(pg.locator(".wrong").count() >= 1, "sehv sual sayilir",
       pg.locator(".wrong").count())
    ok(len(pg.locator(".wrong i").first.inner_text()) > 5,
       "sehv sualda izah gosterilir", pg.locator(".wrong i").first.inner_text()[:45])

    print("I · Yarımçıq testdə çıxış xəbərdarlığı")
    pg.click("#btnHome"); pg.wait_for_selector(".test", timeout=8000)
    pg.locator(".test:not(.lock)", has_text="Qarışıq").first.click()
    pg.wait_for_selector(".opt", timeout=8000)
    asked = {"v": False}
    def on_dialog(d):
        asked["v"] = True
        d.dismiss()                      # "Yox" - testde qalmaq
    pg.once("dialog", on_dialog)
    pg.click("#btnOut"); pg.wait_for_timeout(700)
    ok(asked["v"], "yarimciq testde cixis xeberdarliq verir")
    ok(pg.locator(".opt").count() > 0, "imtina edende testde qalir")

    pg.once("dialog", lambda d: d.accept())
    pg.click("#btnOut"); pg.wait_for_selector("#btnIn", timeout=8000)
    ok(True, "tesdiq edende cixis olur")
    pg.fill("#code", "AYSUKOD1"); pg.click("#btnIn")
    pg.wait_for_selector(".test", timeout=8000)

    print("J · Sessiya")
    pg.reload(); pg.wait_for_selector(".test", timeout=8000)
    ok(True, "sehife yenilendikde sessiya qalir")
    pg.click("#btnOut"); pg.wait_for_selector("#btnIn", timeout=8000)
    ok(True, "cixis isleyir")
    pg.reload(); pg.wait_for_selector("#btnIn", timeout=8000)
    ok(True, "cixisdan sonra yeniden giris ekrani")

    print("K · Şəbəkə kəsintisi")
    # Onceki bolme cixisla bitir - evvelce yeniden daxil oluruq
    pg.fill("#code", "AYSUKOD1"); pg.click("#btnIn")
    pg.wait_for_selector(".test", timeout=8000)
    # Sonra butun Supabase sorgularini kesirik - telefonda internetin
    # kesilmesi ile eyni veziyyet
    pg.route("**/rest/v1/rpc/**", lambda r: r.abort())
    pg.locator(".test").first.click(); pg.wait_for_timeout(2500)
    t = pg.inner_text("#main")
    ok("İnternet" in t, "sebeke xetasi anlasilan dilde", t.split("\n")[0][:55])
    ok("Failed to fetch" not in t, "xam brauzer xetasi gorunmur")
    ok(pg.is_visible("#btnRetry"), "'Yeniden cehd et' duymesi var")
    ok(pg.is_visible("#btnHome2"), "'Testlere qayit' duymesi var")

    # Sebeke qayidir - tekrar cehd islemelidir
    pg.unroute("**/rest/v1/rpc/**")
    pg.click("#btnRetry"); pg.wait_for_timeout(1200)
    ok("İnternet" not in pg.inner_text("#main"),
       "sebeke qayidanda tekrar cehd isleyir")

    print("L · Server balı hesablayır (saxtakarlıq yoxlaması)")
    row = db("""select score, max_score, percent from public.attempts
                 where student_id='d1d1d1d1-0000-0000-0000-000000000001'
                   and status='submitted' order by finished_at limit 1""", one=True)
    ok(float(row["score"]) == float(NQ), "bazada bal serverde hesablanib",
       "%s / %s" % (row["score"], row["max_score"]))
    n_ans = db("""select count(*) n from public.attempt_answers""", one=True)["n"]
    ok(n_ans >= NQ, "cavablar bazaya yazilib", n_ans)

    ctx.close(); br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails))
    for f in fails: print("  - " + f)
    sys.exit(1)
print("SAGIRD TETBIQI: BUTUN YOXLAMALAR KECDI")
