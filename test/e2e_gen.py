#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Generator axini: suzgec -> onizleme -> test yig -> veraq -> teyin et.

Ayrica: suzgec fenn siyahisinda SUALI OLMAYAN fenn cixmir (menasizdir),
sual formasinda ise hamisi qalir (ilk suali yazmaq ucun).
"""
import sys, datetime
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
  STUDENT_URL: "https://example.test/Testler/"
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
-- evvelki suite-lerin muellim testleri/suallari da getsin - yoxsa
-- auth.users silinende questions cascade-i test_questions-a ilisir
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
    ctx = br.new_context(viewport={"width": 430, "height": 900},
                         permissions=["clipboard-read", "clipboard-write"])

    def new_page():
        pg = ctx.new_page()
        pg.route("**/config.js*", lambda r: r.fulfill(
            status=200, content_type="application/javascript", body=TEST_CFG))
        pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
        pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))
        return pg

    # ------------------------------------------------ muellim + qrup
    pg = new_page()
    pg.goto(PANEL); pg.wait_for_timeout(400)
    pg.click("#btnSwap")
    pg.fill("#fname", "Gen Muellim"); pg.fill("#email", "gen@t.az")
    pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=8000)
    pg.select_option("#atype", "tutor")
    pg.fill("#aname", "Gen qrupu"); pg.click("#btnSetup")
    pg.wait_for_function("document.querySelectorAll('#glevel option').length > 1",
                         timeout=8000)
    pg.fill("#gname", "4-A qrupu"); pg.select_option("#glevel", "4")
    pg.click("#btnGroup")
    pg.wait_for_selector("#groups .item", timeout=8000)
    pg.click("#groups .item")
    pg.wait_for_selector("#btnStu", timeout=8000)
    pg.fill("#sname", "Kənan Əliyev"); pg.click("#btnStu")
    pg.wait_for_selector(".stu", timeout=8000)

    UID  = db("select id::text i from auth.users", one=True)["i"]
    AID  = db("select id::text i from public.accounts", one=True)["i"]
    GID  = db("select id::text i from public.classes", one=True)["i"]
    CODE = db("select login_code c from public.students", one=True)["c"]

    # Muellimin oz banki: 2 movzu x 6 sual (metnler ve cavablar ferqli -
    # oxsarliq suzgeci tekrar saymasin)
    db("""
    do $$
    declare v_s uuid; v_l uuid; v_t uuid; i int; j int; v_q uuid; tp text;
    begin
      select id into v_s from public.subjects where slug='riyaziyyat';
      select l.id into v_l from public.levels l
        join public.programs p on p.id=l.program_id
       where p.slug='ibtidai' and l.code='4';
      for j in 1..2 loop
        tp := case j when 1 then 'riy-4-vurma-bolme' else 'riy-4-toplama-cixma' end;
        select id into v_t from public.topics
         where slug = tp and subject_id = v_s;
        for i in 1..6 loop
          insert into public.questions
            (owner_type, owner_id, account_id, subject_id, level_id, topic_id,
             kind, body, difficulty, status)
          values ('educator', %(uid)s, %(aid)s, v_s, v_l, v_t, 'single',
                  case j when 1 then 'Vurma hesabi numune ' else 'Toplama calismasi numune ' end
                    || i || ' movzu ' || j,
                  (i %% 3) + 1, 'published')
          returning id into v_q;
          insert into public.question_options (question_id, ord, body, is_correct)
          values (v_q, 1, 'duz cavab ' || j || '-' || i, true),
                 (v_q, 2, 'sehv cavab ' || j || '-' || i, false);
        end loop;
      end loop;
    end $$;
    """, {"uid": UID, "aid": AID})

    print("A · Süzgəc yalnız sualı olan fənni göstərir")
    pg.goto(PANEL + "#/b"); pg.wait_for_selector("#bFilt", timeout=8000)
    if pg.locator("details.filt:not([open])").count():
        pg.locator("details.filt summary").click(); pg.wait_for_timeout(200)
    subs = pg.locator("#bsub option").all_inner_texts()
    ok("Fizika" not in " ".join(subs), "bank suzgecinde sualsiz fenn yoxdur", subs)
    ok(any("Riyaziyyat" in x for x in subs), "sualli fenn var")
    pg.goto(PANEL + "#/q/new"); pg.wait_for_selector("#qsub", timeout=8000)
    pg.wait_for_function("document.querySelectorAll('#qsub option').length > 3", timeout=8000)
    subs = pg.locator("#qsub option").all_inner_texts()
    ok(any("Fizika" in x for x in subs),
       "sual FORMASINDA butun fennler qalir (ilk sual ucun)", len(subs))

    print("B · Generator ekranı")
    pg.goto(PANEL + "#/gen"); pg.wait_for_selector("#gPool", timeout=8000)
    ok(pg.locator("#gPool .seg.on").inner_text() == "Öz suallarım",
       "abunesiz hesabda hovuz «öz suallarım»dır")
    subs = pg.locator("#gsub option").all_inner_texts()
    ok("Fizika" not in " ".join(subs), "generatorda da sualsiz fenn yoxdur")
    # "Oz suallarim" hovuzunda siyahi yalniz OZ fennlerinden ibaretdir
    nmine = db("select count(distinct subject_id) n from public.questions "
               "where owner_type = 'educator'", one=True)["n"]
    ok(len(subs) - 1 == nmine,
       "oz hovuzunda yalniz oz fennleri gorunur", (len(subs) - 1, nmine))
    # "Hovuz yoxlanılır..." da metndir - cavabin GELMESINI gozle
    pg.wait_for_function(
        "document.querySelector('#gPrev') && "
        "document.querySelector('#gPrev').innerText.indexOf('yoxlanılır') < 0 && "
        "document.querySelector('#gPrev').innerText.length > 5",
        timeout=8000)
    ok("kifayət qədər" in pg.inner_text("#gPrev"),
       "onizleme: 12 oz suali 10-a catir", pg.inner_text("#gPrev")[:60])

    # sayi hovuzdan boyuk edek - durust xeberdarliq
    pg.fill("#gCnt", "50"); pg.wait_for_timeout(700)
    ok("yalnız 12" in pg.inner_text("#gPrev"),
       "onizleme durust: hovuzda yalniz 12 sual", pg.inner_text("#gPrev")[:70])

    print("C · Abunəsiz platforma hovuzu")
    pg.locator("#gPool .seg", has_text="Platforma").click()
    pg.wait_for_selector("#gPool .seg.on", timeout=4000)
    ok("abunə paketinə daxildir" in pg.inner_text("#main"),
       "platforma secilende abune xeberdarligi cixir")
    pg.click("#btnMake"); pg.wait_for_timeout(900)
    ok(pg.inner_text("#gErr").strip() != "" or "yalnız" in pg.inner_text("#gPrev"),
       "abunesiz platforma testi yigilmir - acıq mesaj",
       (pg.inner_text("#gErr") or pg.inner_text("#gPrev"))[:60])
    ok(db("select count(*) n from public.tests where owner_type='educator'",
          one=True)["n"] == 0, "bazada yarimciq test qalmadi")

    print("D · Öz hovuzundan test yığılır")
    pg.locator("#gPool .seg", has_text="Öz suallarım").click()
    pg.wait_for_timeout(400)
    pg.fill("#gCnt", "8"); pg.wait_for_timeout(700)
    pg.fill("#gTitle", "Sınaq — öz suallarım")
    pg.click("#btnMake")
    pg.wait_for_selector(".paper", timeout=8000)
    ok("/t/" in pg.url, "veraq ekranina kecid", pg.url.split("#")[-1][:20])
    n = pg.locator(".paper .pq").count()
    ok(n == 8, "veraqda 8 sual var", n)
    ok(pg.locator(".popt.ok").count() == 8, "her sualda duzgun cavab isarelidir",
       pg.locator(".popt.ok").count())
    ok("öz sualınız" in pg.inner_text(".paper"), "sualin mensubiyyeti gorunur")
    TID = db("select id::text i from public.tests where owner_type='educator'",
             one=True)["i"]
    ok(db("select count(*) n from public.test_questions where test_id=%s",
          (TID,), one=True)["n"] == 8, "bazada 8 sual baglanib")

    print("E · Yenidən yığmaq")
    before = sorted(r["q"] for r in db(
        "select question_id::text q from public.test_questions where test_id=%s", (TID,)))
    pg.click("#btnRegen")
    pg.wait_for_selector(".paper", timeout=8000)
    pg.wait_for_timeout(300)
    ok(pg.locator(".paper .pq").count() == 8, "yeniden yigilan testde de 8 sual")
    after = sorted(r["q"] for r in db(
        "select question_id::text q from public.test_questions where test_id=%s", (TID,)))
    ok(len(after) == 8, "bazada yene 8 sual", len(after))
    ok(db("select count(*) n from public.tests where owner_type='educator'",
          one=True)["n"] == 1, "yeni test YARANMADI - eynisi yenilendi")

    print("F · Vərəqdən qrupa təyin etmək")
    day = (datetime.date.today() + datetime.timedelta(days=5)).isoformat()
    pg.fill("#pDate", day)
    pg.select_option("#pTry", "2")
    pg.click("#btnPAsg")
    #  teyinatdan sonra sehife yenilenir - "verilib" siyahisi tesdiqdir
    pg.wait_for_selector(".pgiven", timeout=8000)
    ok("verilib" in pg.inner_text(".pgiven"), "teyinat veraqde gorunur",
       pg.inner_text(".pgiven")[:50].replace("\n", " "))
    a = db("select class_id::text c, max_attempts m from public.assignments", one=True)
    ok(a is not None and a["c"] == GID and a["m"] == 2, "bazada teyinat duzgundur")

    print("F2 · Çap / PDF vərəqi")
    #  cap pencersi headless-de acilmir - print() saxta funksiya ile evezlenir
    #  (setir () => {} ile sarilir - yoxsa playwright onu ozu bir defe cagirir)
    pg.evaluate("() => { window.print = function(){ window.__prn = (window.__prn||0)+1 } }")
    pg.click("#btnPrn")
    ok(pg.evaluate("window.__prn") == 1, "cap pencersi cagirilir",
       pg.evaluate("window.__prn"))
    ok(pg.locator("#printBox .ppq").count() == 8, "cap nusxesinde 8 sual",
       pg.locator("#printBox .ppq").count())
    ptxt = pg.evaluate("document.getElementById('printBox').innerText")
    ok("Ad, soyad" in ptxt, "veraq basligi (ad, tarix, bal) var")
    ok("Cavab açarı" not in ptxt, "sagird nusxesinde acar YOXDUR")
    ok(pg.locator("#printBox .ppk").count() == 0, "acar bolmesi de yoxdur")
    ok("A)" in ptxt, "variantlar herflenib")
    #  su nisani: cap eden muellimin adi + tam tarix, her sehifenin altinda
    foot = pg.evaluate("document.querySelector('#printBox .ppfoot').textContent")
    ok("Bil10" in foot, "su nisaninda brend var", foot)
    ok("Gen Muellim" in foot, "su nisaninda muellimin adi var", foot)
    import datetime as _dt
    bugun = _dt.date.today().strftime("%d.%m.%Y")
    ok(bugun in foot, "su nisaninda tam tarix var", foot)
    pg.click("#btnPrnK")
    ok(pg.locator("#printBox .ppk").count() == 1, "acarli variantda acar sehifesi var")
    ok("şagirdlərə paylanmır" in pg.evaluate("document.querySelector('#printBox .ppkn').textContent"),
       "acar sehifesinde paylanmama qeydi var")
    ok(pg.locator("#printBox .ppfoot").count() == 1,
       "acarli nusxede de su nisani tekdir")
    ok(pg.locator("#printBox .ppkg span").count() == 8, "acarda 8 cavab",
       pg.locator("#printBox .ppkg span").count())
    #  ehtiyat temizlik isleyir - "printing" sinfi goturulur
    pg.wait_for_function("!document.body.classList.contains('printing')",
                         timeout=5000)

    print("G · Şagird tapşırığı görür")
    sp = new_page()
    sp.goto(STUDENT); sp.wait_for_selector("#btnIn", timeout=8000)
    sp.fill("#code", CODE); sp.click("#btnIn")
    sp.wait_for_selector(".test", timeout=8000)
    ok("Sınaq — öz suallarım" in sp.inner_text("#main"),
       "yigilan test sagirdin tapsiriqlarindadir")
    sp.close()

    print("H · İşlənmiş test yenilənmir")
    db("""insert into public.attempts (test_id, student_id, status, finished_at)
          select %s, s.id, 'submitted', now() from public.students s limit 1""", (TID,))
    # Unvan onsuz da #/t/<id>-dir - goto hec ne etmir, reload lazimdir
    pg.goto(PANEL + "#/t/" + TID); pg.reload()
    pg.wait_for_selector(".paper", timeout=8000)
    ok(pg.locator("#btnRegen").count() == 0, "yenile duymesi gizlenir")
    ok("yeniləmək olmaz" in pg.inner_text("#main"), "sebeb yazilir")

    print("I · Abunə ilə platforma hovuzu")
    db("""insert into public.subscriptions (account_id, plan_id, status, started_at, current_period_end)
          select %s, p.id, 'active', now(), now() + interval '30 days'
            from public.plans p where p.slug='repetitor-25'""", (AID,))
    pg.goto(PANEL); pg.wait_for_timeout(300)
    pg.reload(); pg.wait_for_selector("#btnGen", timeout=8000)
    pg.click("#btnGen"); pg.wait_for_selector("#gPool", timeout=8000)
    pg.locator("#gPool .seg", has_text="Platforma").click()
    pg.wait_for_timeout(500)
    ok("abunə paketinə daxildir" not in pg.inner_text("#main"),
       "abune ile xeberdarliq itir")
    pg.select_option("#gsub", "riyaziyyat")
    pg.wait_for_selector("#gsub", timeout=8000); pg.wait_for_timeout(400)
    # Sinifsiz movzu nisani CIXMIR - dord sinfin 40+ nisani telefonda
    # gozu yorurdu.  Sinif secilenden sonra en coxu ~12 nisan gelir.
    ok(pg.locator("#gTop").count() == 0, "sinifsiz movzu nisanlari gizlidir")
    ok("sinif də seçin" in pg.inner_text("#main"), "sebeb yazilir - sinif secilsin")
    pg.select_option("#glev", "4"); pg.wait_for_selector("#gTop", timeout=8000)
    nt = pg.locator("#gTop .chip").count()
    ok(0 < nt <= 15, "sinifle movzu nisanlari yigcamdir", nt)
    pg.fill("#gCnt", "12"); pg.wait_for_timeout(700)
    ok("kifayət qədər" in pg.inner_text("#gPrev"),
       "platforma hovuzunda riy-4 suallari tapilir")
    pg.fill("#gTitle", "Riyaziyyat 4 — platforma sınağı")
    pg.click("#btnMake")
    pg.wait_for_selector(".paper", timeout=8000)
    ok(pg.locator(".paper .pq").count() == 12, "12 sualliq platforma testi yigildi")
    ok("platforma" in pg.inner_text(".paper"), "platforma nisani gorunur")
    # movzular arasinda beraberlik: 12 movzudan 12 sual - hersinden 1
    tt = db("""select count(distinct q.topic_id) n
                 from public.test_questions tq
                 join public.questions q on q.id = tq.question_id
                 join public.tests t on t.id = tq.test_id
                where t.title = 'Riyaziyyat 4 — platforma sınağı'""", one=True)["n"]
    ok(tt >= 10, "suallar movzular arasinda paylanib", "%d movzu" % tt)

    print("J · Təhlükə zonası və düzəliş testi")
    SID = db("select id::text i from public.students limit 1", one=True)["i"]
    TOPIC = db("""select t.id::text i from public.topics t
                   join public.subjects s on s.id = t.subject_id
                  where s.slug='riyaziyyat' and t.slug='riy-4-vurma-bolme'""",
               one=True)["i"]
    # temiz tarixce: gerileyen sagird (88,85,82 -> 60,55,50) + zeif movzu
    # (evvele 2 kohne cehd elave olunub ki, lent 6-dan cox olsun ve
    #  "Daha N netice" duymesi de yoxlansin; son 6 deyismir - siqnal qalir)
    db("delete from public.attempt_answers; delete from public.attempts;")
    for i, p_ in enumerate([70, 72, 88, 85, 82, 60, 55, 50]):
        db("""insert into public.attempts (test_id, student_id, status, percent, finished_at)
              values (%s, %s, 'submitted', %s, now() - interval '20 days' + (%s || ' days')::interval)""",
           (TID, SID, p_, i))
    db("""insert into public.attempt_answers
            (attempt_id, question_id, topic_id, is_correct, question_body)
          select (select id from public.attempts where student_id = %s
                   order by finished_at desc limit 1),
                 q.id, %s, rn = 1, 'Vurma hesabi numune ' || (rn + 20) || ' movzu 1'
            from (select id, row_number() over (order by id) rn
                    from public.questions where owner_type='platform'
                   order by id limit 6) q(id, rn)""", (SID, TOPIC))

    # Esas sehife: lovheler dolur, hesab-boyu tehluke zonasi gorunur
    pg.goto(PANEL + "#/"); pg.reload()
    pg.wait_for_selector(".tiles", timeout=8000)
    pg.wait_for_function(
        "document.querySelector('.tile b') && document.querySelector('.tile b').innerText !== '—'",
        timeout=8000)
    ok("Xoş gəlmisiniz" in pg.inner_text("#main"), "salamlasma var")
    ok(pg.locator(".tile").count() == 4, "4 stat lovhesi var")
    ok(pg.inner_text(".tile.c b") == "1", "sagird sayi lovhede",
       pg.inner_text(".tile.c b"))
    pg.wait_for_selector("#hAlerts .al", timeout=8000)
    ok("geriləyir" in pg.inner_text("#hAlerts"), "ev sehifesinde de siqnal var")
    ok(pg.locator("#hRecent .trow").count() >= 1, "son neticeler lenti dolur",
       pg.locator("#hRecent .trow").count())
    ok(pg.locator("#recF").count() == 0, "tek qrupda lent cipleri gizlidir")
    # Lent yigcamdir: 8 neticeden yalniz 6-si gorunur, qalani duyme ile
    rn0 = pg.locator("#hRecent .trow").count()
    ok(rn0 == 6, "lent en coxu 6 setirle acilir", rn0)
    ok("Daha 2 nəticə" in pg.inner_text("#recMore"), "acici duyme sayi duz",
       pg.inner_text("#recMore"))
    pg.click("#recMore")
    ok(pg.locator("#hRecent .trow").count() == 8, "daha N netice acilir",
       pg.locator("#hRecent .trow").count())
    ok(pg.locator("#recMore").count() == 0, "acilandan sonra duyme itir")

    pg.goto(PANEL + "#/g/" + GID); pg.reload()
    pg.wait_for_selector("#alerts .al", timeout=8000)
    al = pg.inner_text("#alerts")
    ok("geriləyir" in al, "qrup ekrani OZU xeber verir - gerileme", al[:70].replace("\n", " "))
    ok("zəif" in al, "zeif movzu siqnala baglidir")
    ok(pg.locator("#alerts .al.risk").count() == 1, "qirmizi siqnal siniflidir")
    pg.locator("#alerts .al").first.click()
    pg.wait_for_selector("#btnRem", timeout=8000)
    ok("/s/" in pg.url, "siqnala klik sagird hesabatina aparir")

    print("K · Hesabatdan bir klikle düzəliş testi")
    pg.click("#btnRem")
    pg.wait_for_selector("#gPool", timeout=8000)
    ok("zəif mövzular seçilib" in pg.inner_text("#main"),
       "generator zeif movzularla acilir")
    ok("Vurma və bölmə" in pg.inner_text("#main"), "movzunun adi gorunur")
    # Fenn ve sinif AVTOMATIK secilir - muellim yalniz "Testi yig" basir
    ok(pg.input_value("#gsub") == "riyaziyyat", "fenn avtomatik secilir",
       pg.input_value("#gsub"))
    ok(pg.input_value("#glev") == "4", "sinif avtomatik secilir",
       pg.input_value("#glev"))
    pg.wait_for_selector("#gTop", timeout=8000)
    ok(pg.locator("#gTop .chip.on").count() >= 1,
       "zeif movzunun nisani secili gorunur")
    pg.wait_for_function(
        "document.querySelector('#gPrev') && "
        "document.querySelector('#gPrev').innerText.indexOf('yoxlanılır') < 0 && "
        "document.querySelector('#gPrev').innerText.length > 5", timeout=8000)
    ok("kifayət qədər" in pg.inner_text("#gPrev"), "duzelis hovuzu kifayetdir")
    pg.click("#btnMake")
    pg.wait_for_selector(".paper", timeout=8000)
    ok(pg.locator(".paper .rem").count() >= 1,
       "veraqda «səhvə bənzər» nisani var", pg.locator(".paper .rem").count())
    ok("səhvə bənzər" in pg.inner_text(".paper"), "nisan metni duzgundur")
    RID = pg.url.split("/t/")[1]
    ok(db("select (gen_rule->>'class') c from public.tests where id=%s",
          (RID,), one=True)["c"] == GID, "qayda qrupu yadda saxlayir")

    # qrup hesabatinda da eyni duyme
    pg.goto(PANEL + "#/r/" + GID); pg.reload()
    pg.wait_for_selector("#btnRem", timeout=8000)
    ok(True, "qrup hesabatinda da duzelis duymesi var")

    print("L · Valideyn xülasəsi")
    pg.goto(PANEL + "#/s/" + SID + "/" + GID); pg.reload()
    pg.wait_for_selector("#vTxt", timeout=8000)
    # Sehv siyahisi indi ACIQ gelir - hereket merkezidir
    ok(pg.locator("details.wrongbox").count() == 1, "sehv siyahisi var")
    ok(pg.locator("details.wrongbox[open]").count() == 1, "ilkin halda aciqdir")
    ok(pg.locator("details.wrongbox .fn").inner_text().strip().isdigit(),
       "basliqda say gorunur", pg.locator("details.wrongbox .fn").inner_text())
    ok(pg.locator(".wq").count() >= 1, "setirler gorunur",
       pg.locator(".wq").count())
    ok(pg.locator(".wq .wtag").count() >= 1, "sehvlerde movzu teqi var",
       pg.locator(".wq .wtag").count())
    ok(pg.locator("#btnFix").count() == 1, "sehvlerden test duymesi var")
    t = pg.input_value("#vTxt")
    ok("Kənan" in t, "sagirdin adi metndedir", t.split("\n")[0][:40])
    ok("📊" in t and "▰" in t, "semimi uslubda emoji ve zolaqlar var")
    ok("%" in t, "faizler metndedir")
    ok("↘" in t, "enme trendi gorunur (gerileyen sagird)")
    ok("Vurma və bölmə" in t, "zeif movzu metnde adi ile var")
    pg.locator("#vSty .seg", has_text="Rəsmi").click(); pg.wait_for_timeout(200)
    t2 = pg.input_value("#vTxt")
    ok("Hörmətli valideyn" in t2, "resmi uslub muracietle baslayir")
    ok("📊" not in t2, "resmi uslubda emoji yoxdur")
    pg.click("#vCopy"); pg.wait_for_timeout(400)
    ok("Kopyalandı" in pg.inner_text("#vCopy"), "kopyalama tesdiqi gorunur",
       pg.inner_text("#vCopy"))
    cb = pg.evaluate("navigator.clipboard.readText()")
    ok(cb == t2, "mubadile buferine TAM metn dusur")

    print("M · Dinamika, cavab vərəqi, səhvlərdən test")
    ok(pg.locator(".dyn i").count() >= 2, "dinamika sutunlari var",
       pg.locator(".dyn i").count())
    pg.locator(".atr").first.click()
    pg.wait_for_selector(".shq", timeout=8000)
    ok(pg.locator(".shq").count() >= 1, "cavab vereqi acilir",
       pg.locator(".shq").count())
    ok(pg.locator(".shq .sw").count() >= 1, "sehv cavab qirmizi gorunur")
    ok("Düzü:" in pg.inner_text(".sheet"), "duz cavab gosterilir")
    pg.locator(".atr").first.click(); pg.wait_for_timeout(200)
    ok(not pg.locator(".sheet .shq").first.is_visible(), "tekrar klik baglayir")

    pg.click("#btnFix")
    pg.wait_for_selector("#fixMsg .ok a", timeout=10000)
    ok("YALNIZ bu şagirdə verildi" in pg.inner_text("#fixMsg"),
       "sehv testi yigilir ve ferdi verildiyi yazilir",
       pg.inner_text("#fixMsg")[:70].replace("\n", " "))
    rem = db("""select t.id::text i,
                       (select count(*) from public.test_questions tq
                         where tq.test_id = t.id) nq
                  from public.tests t
                 where t.title like %s
                 order by t.created_at desc limit 1""",
             ("%səhvlər üzərində iş%",), one=True)
    ok(bool(rem) and rem["nq"] >= 1, "sehv testi bazadadir", rem and rem["nq"])
    asg = db("""select student_id::text s from public.assignments
                 where test_id = %s""", (rem["i"],), one=True)
    ok(asg is not None, "tapsiriq bazada var")
    #  duzelis testi FERDIDIR - qrupun qalani gormemelidir
    ok(asg is not None and asg["s"] == SID,
       "duzelis testi yalniz hemin sagirde verilib", asg and asg["s"])
    wq = db("""select count(*) n from public.test_questions tq
                where tq.test_id = %s
                  and tq.question_id not in (
                    select aa.question_id from public.attempt_answers aa
                     where aa.is_correct is not true)""", (rem["i"],), one=True)["n"]
    ok(wq == 0, "testde yalniz sehv edilen suallar var", wq)

    print("N · Qrup seçimi ilə yığ; «başqa qrupda verilib» nişanı")
    pg.goto(PANEL + "#/gen"); pg.reload()
    pg.wait_for_selector("#gAsg", timeout=8000)
    pg.wait_for_function(
        "document.querySelectorAll('#gAsg option').length > 1", timeout=8000)
    pg.select_option("#gAsg", GID)
    pg.wait_for_function(
        "document.querySelector('#gPrev') && "
        "document.querySelector('#gPrev').innerText.indexOf('yoxlanılır') < 0 && "
        "document.querySelector('#gPrev').innerText.length > 5", timeout=8000)
    pg.fill("#gTitle", "Qrupla birge test")
    pg.click("#btnMake")
    pg.wait_for_selector(".paper", timeout=8000)
    NID = pg.url.split("/t/")[1]
    ok(bool(db("select 1 ok from public.assignments "
               "where test_id = %s and class_id = %s", (NID, GID), one=True)),
       "yigan kimi tapsiriq da verildi")

    #  ikinci qrup: nisan + sexsi testin gizlenmesi
    db("""insert into public.classes (id, account_id, teacher_id, kind, name, join_code)
          values ('cccc2222-0000-0000-0000-0000000000e2', %s, %s,
                  'tutor_group', 'Iki qrup', 'KODIKI01')""", (AID, UID))
    pg.goto(PANEL + "#/a/cccc2222-0000-0000-0000-0000000000e2"); pg.reload()
    pg.wait_for_selector("#aTest", timeout=8000)
    opts = " | ".join(pg.locator("#aTest option").all_inner_texts())
    ok("başqa qrupda verilib" in opts, "verilib nisani gorunur", opts[:80])
    ok("səhvlər üzərində iş" not in opts,
       "sexsi sehv-testi basqa qrupa teklif olunmur")

    print("O · Tapşırıq ekranından yeni test yığmaq (gediş-qayıdış)")
    pg.goto(PANEL + "#/a/" + GID); pg.reload()
    pg.wait_for_selector("#btnGenHere", timeout=8000)
    pg.click("#btnGenHere")
    pg.wait_for_selector("#btnMake", timeout=8000)
    ok(pg.url.endswith("#/gen"), "generator acilir", pg.url[-12:])
    ok(pg.input_value("#glev") == "4", "qrupun sinfi avtomatik secilir",
       pg.input_value("#glev"))
    ok(pg.locator("#gAsg").count() == 0,
       "qrup sahesi gizlidir - teyinati tapsiriq ekrani verecek")
    ok("4-A qrupu" in pg.inner_text("#main"), "hara qayidacagi yazilir")
    #  Sinif artiq secilidir - ipucu onu tekrar istememelidir
    ok("fənn və sinif seçin" not in pg.inner_text("#main"),
       "ipucu hazir sinfi tekrar istemir")
    ok("Mövzu seçmək üçün fənn seçin" in pg.inner_text("#main"),
       "ipucu yalniz fenni isteyir")
    ok(pg.locator("#btnBack").inner_text().strip() == "4-A qrupu",
       "geri duymesi qrupun adini gosterir", pg.locator("#btnBack").inner_text())

    pg.select_option("#gsub", "riyaziyyat")
    pg.wait_for_selector("#gsub", timeout=8000); pg.wait_for_timeout(400)
    pg.fill("#gCnt", "6"); pg.fill("#gTitle", "Tapsiriqdan yigilan test")
    pg.wait_for_function(
        "document.querySelector('#gPrev') && "
        "document.querySelector('#gPrev').innerText.indexOf('yoxlanılır') < 0 && "
        "document.querySelector('#gPrev').innerText.length > 5", timeout=8000)
    pg.click("#btnMake")
    pg.wait_for_selector("#aTest", timeout=10000)
    ok(pg.url.endswith("#/a/" + GID), "tapsiriq ekranina QAYIDIR", pg.url[-20:])
    ok("seçildi" in pg.inner_text("#pick .ok"), "bildiris cixir",
       pg.inner_text("#pick .ok")[:60].replace("\n", " "))
    NEWT = db("""select id::text i from public.tests
                  where title = 'Tapsiriqdan yigilan test'""", one=True)
    ok(bool(NEWT), "test bazada yarandi")
    ok(pg.input_value("#aTest") == NEWT["i"], "teze test siyahida SECILI gelir")
    #  teyinat hele VERILMEYIB - son tarixi muellim ozu qoyur
    ok(not db("select 1 ok from public.assignments where test_id = %s",
              (NEWT["i"],), one=True),
       "yigmaq tek basina tapsiriq vermir")

    pg.select_option("#aWho", "")
    pg.click("#btnAsg")
    #  DIQQET: ".asg" gozlemek AZDIR - bu qrupda onsuz da teyinat var,
    #  selektor derhal qayidir ve baza yoxlamasi yazidan EVVEL isleyir.
    #  Konkret teze setri gozleyirik.
    pg.wait_for_function(
        "document.querySelector('#asgList') && "
        "document.querySelector('#asgList').innerText"
        ".indexOf('Tapsiriqdan yigilan test') >= 0", timeout=8000)
    ok(bool(db("select 1 ok from public.assignments where test_id = %s "
               "and class_id = %s", (NEWT["i"], GID), one=True)),
       "«Tapsiriq ver» basilanda teyinat yazilir")

    #  bildiris bir defelikdir - ekran yenilenende qalmamalidir
    pg.reload(); pg.wait_for_selector("#aTest", timeout=8000)
    ok(pg.locator("#pick .ok").count() == 0, "bildiris bir defelikdir")

    print("P · Sinif uyğun gəlməyəndə səbəb yazılır")
    #  Muellim generatorda sinfi deyisirse, teze test qrupun suzgecine
    #  DUSMUR (rpc_available_tests sinife gore suzur).  Test itmir -
    #  ekran sebebi yazmalidir, yoxsa "yigdim, hara getdi?" olur.
    pg.click("#btnGenHere"); pg.wait_for_selector("#btnMake", timeout=8000)
    pg.select_option("#gsub", "riyaziyyat")
    pg.wait_for_selector("#gsub", timeout=8000); pg.wait_for_timeout(400)
    pg.select_option("#glev", "3")
    pg.wait_for_selector("#glev", timeout=8000); pg.wait_for_timeout(400)
    pg.fill("#gCnt", "5"); pg.fill("#gTitle", "Yanlis sinifle yigilan")
    pg.wait_for_function(
        "document.querySelector('#gPrev') && "
        "document.querySelector('#gPrev').innerText.indexOf('yoxlanılır') < 0 && "
        "document.querySelector('#gPrev').innerText.length > 5", timeout=8000)
    pg.click("#btnMake")
    pg.wait_for_selector("#pick .warn", timeout=10000)
    ok("sinfi" in pg.inner_text("#pick .warn"), "sebeb izah olunur",
       pg.inner_text("#pick .warn")[:60].replace("\n", " "))
    MIS = db("""select id::text i from public.tests
                 where title = 'Yanlis sinifle yigilan'""", one=True)
    ok(bool(MIS), "test ITMIR - bazada durur")
    ok(pg.input_value("#aTest") != (MIS or {}).get("i"),
       "uygun olmayan test secili gelmir")

    print("R · İmtina və niyyətin təmizlənməsi")
    pg.click("#btnGenHere"); pg.wait_for_selector("#btnMake", timeout=8000)
    pg.click("#btnBack"); pg.wait_for_selector("#aTest", timeout=8000)
    ok(pg.url.endswith("#/a/" + GID), "geri duymesi tapsiriq ekranina qaytarir",
       pg.url[-20:])
    #  niyyet silinir: adi "Test yig"dan girende qrup sahesi geri gelir
    pg.goto(PANEL + "#/gen"); pg.reload()
    pg.wait_for_selector("#gAsg", timeout=8000)
    ok(pg.locator("#gAsg").count() == 1,
       "adi girisde qrup sahesi geri gelir - niyyet yapismir")

    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails))
    for f in fails: print("  - " + f)
    sys.exit(1)
print("GENERATOR: BUTUN YOXLAMALAR KECDI")
