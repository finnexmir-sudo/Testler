#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Ders mesqi (db/935-936, pilot riy 5) — nümunə hesabda, uçdan-uca.

  A  Qrupun «Tapşırıqlar» sekməsində «Məşq ver»; başlıq menyusunda da var
  B  «Məşq ver»: yalnız məşq sualı olan dərslər (6 sual), dərs seçilmədən düymə bağlı,
     son tarix +7 gün uzun yazı ilə; verilir → hesabat «0 / 2 başlayıb», təsdiq yazısı
  C  «Geri» (düymə və brauzer) Tapşırıqlara qaytarır; «Məşqlər» siyahısında görünür
  D  Boş hal: 7-ci sinif qrupunda «Bu sinif üçün hələ məşq yoxdur»
  E  Şagird: ev ekranında «Məşq», sual-sual, düz variant gəlmir, cavabdan sonra düz/səhv + izah,
     «Sonra davam et» → siyahıda 2 / 6, yenidən açanda 3-cü sual (şablon — rəqəmlər render olunub),
     bitəndə «Məşq bitdi · 5 / 6»
  F  Müəllim hesabatı: 1 / 2 başlayıb, 1 bitirib, 83%, başlamayan «hələ başlamayıb», ən çox səhv № 2
  G  Valideyn: bir sətir «6 / 6 sual işləyib ✓, 83% düz»
  H  Test mexanizminə qarışmır: attempts boş, «işlənmiş test» sayğacı yoxdur
  I  390 / 360: yana sürüşmə yoxdur, düymələr ≥ 44 px (SHOT_DIR varsa şəkillər)
"""
import os, sys, re
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

ROOT = "http://127.0.0.1:8010/"
PANEL, STUDENT, PARENT = ROOT + "muellim/index.html", ROOT + "sagird/index.html", ROOT + "valideyn/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN = "host=/tmp port=55432 user=postgres dbname=" + os.environ.get("DB", "panel_e2e")
SHOT = os.environ.get("SHOT_DIR")
CFG = """window.CFG = {SUPABASE_URL:"http://127.0.0.1:54321",
  SUPABASE_ANON_KEY:"test-anon-key", STUDENT_URL:"http://127.0.0.1:8010/sagird/",
  PARENT_URL:"http://127.0.0.1:8010/valideyn/", SHOW_PLANS:false};"""

fails = []
def ok(cond, label, extra=""):
    print(("  OK   " if cond else "  FAIL ") + label + (("  " + str(extra)) if extra != "" else ""), flush=True)
    if not cond: fails.append(label)

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            r = cur.fetchall(); return (r[0] if r else None) if one else r

# ---------------------------------------------------------------- hazirliq
#  nümunə hesab sıfırdan + riy-5 «Natural ədədlər» dərsinə 6 məşq sualı (bank faylı 1470 hələ yoxdur)
db("""
delete from public.mesq_assignments;
delete from public.classes c using public.accounts a where a.id = c.account_id and a.is_demo and a.id <> app.demo_account();
delete from public.tests t using public.accounts a where a.owner_id = t.owner_id and a.is_demo and a.id <> app.demo_account();
delete from public.students s using public.accounts a where a.id = s.account_id and a.is_demo and a.id <> app.demo_account();
create temp table demo_old_e2e as select owner_id from public.accounts where is_demo and id <> app.demo_account();
delete from public.accounts where is_demo and id <> app.demo_account();
delete from auth.users u using demo_old_e2e o where u.id = o.owner_id
  and not exists (select 1 from public.accounts a2 where a2.owner_id = u.id);
delete from public.questions where ext_key like 'e2emesq-%%';""")
db("delete from public.app_state where key='demo_reset'")
db("select public.rpc_demo_reset()")
LEAF = "riy-5-natural-ededler-natural-ededler"
db("""
insert into public.questions (owner_type, subject_id, level_id, topic_id, tags, kind, body, explanation, difficulty, status, ext_key, params)
select 'platform', f.subject_id, f.level_id, f.id, array['ders:' || %s, 'mesq'], 'single', x.body, x.ex, x.d, 'mesq', x.ek, x.par::jsonb
  from public.topics f,
       (values ('Ədədi oxu: 305', '305 — üç yüz beş.', 1::smallint, 'e2emesq-d#001', null),
               ('Hansı ədəd 47-dən böyükdür?', '74 > 47, çünki onluqları 7 > 4.', 1::smallint, 'e2emesq-d#002', null),
               ('{a} ədədindən sonra gələn ədəd hansıdır?', '{a} + 1 = {a+1}', 2::smallint, 'e2emesq-d#003',
                '{"vars": {"a": [100, 899]}}'),
               ('Ən kiçik üçrəqəmli ədəd hansıdır?', 'Ən kiçik üçrəqəmli ədəd 100-dür.', 2::smallint, 'e2emesq-d#004', null),
               ('Ən böyük dördrəqəmli ədəd hansıdır?', '9999.', 3::smallint, 'e2emesq-d#005', null),
               ('1000 ədədində neçə yüzlük var?', '1000 = 10 · 100.', 3::smallint, 'e2emesq-d#006', null)) x(body, ex, d, ek, par)
 where f.slug = 'riy-5-natural-ededler' and f.parent_id is null""", (LEAF,))
db("""
insert into public.question_options (question_id, ord, body, is_correct)
select q.id, o.ord,
       case q.ext_key
         when 'e2emesq-d#001' then (array['üç yüz beş','üç yüz əlli','otuz beş'])[o.ord]
         when 'e2emesq-d#002' then (array['74','38','47'])[o.ord]
         when 'e2emesq-d#003' then (array['{a+1}','{a-1}','{a+10}'])[o.ord]
         when 'e2emesq-d#004' then (array['100','101','999'])[o.ord]
         when 'e2emesq-d#005' then (array['9999','9000','1000'])[o.ord]
         else (array['10','100','1'])[o.ord] end,
       o.ord = 1
  from public.questions q, generate_series(1, 3) o(ord)
 where q.ext_key like 'e2emesq-%%'""")
CORRECT = {r["id"] for r in db("select o.id::text id from public.question_options o join public.questions q on q.id = o.question_id where q.ext_key like 'e2emesq-%%' and o.is_correct")}

def hash_(pg): return pg.evaluate("location.hash")
def sw(pg): return pg.evaluate("[document.documentElement.scrollWidth, window.innerWidth]")
def page(ctx, w, h):
    pg = ctx.new_page(); pg.set_viewport_size({"width": w, "height": h})
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)[:160]))
    return pg

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context()
    pg = page(ctx, 1280, 900)
    pg.goto(PANEL + "#/demo"); pg.wait_for_selector("#demoBar", timeout=60000); pg.wait_for_timeout(2500)
    acc = db("select id::text i, owner_id::text o from public.accounts where is_demo and id <> app.demo_account() order by created_at desc limit 1", one=True)
    lv = lambda c: db("select id::text i from public.levels where code = %s order by sort limit 1", (c,), one=True)["i"]
    gid = db("""insert into public.classes (account_id, teacher_id, kind, name, join_code, level_id)
                values (%s::uuid, %s::uuid, 'tutor_group', '5-ci sinif — məşq', 'MQ' || substr(md5(random()::text), 1, 6), %s::uuid)
                returning id::text i""", (acc["i"], acc["o"], lv("5")), one=True)["i"]
    g7 = db("""insert into public.classes (account_id, teacher_id, kind, name, join_code, level_id)
               values (%s::uuid, %s::uuid, 'tutor_group', '7-ci sinif — boş', 'MQ' || substr(md5(random()::text), 1, 6), %s::uuid)
               returning id::text i""", (acc["i"], acc["o"], lv("7")), one=True)["i"]
    for nm, k in (("Aysel Quliyeva", "MQAYSEL1"), ("Murad Əliyev", "MQMURAD1")):
        db("""insert into public.students (account_id, class_id, created_by, full_name, display_name, login_code, parent_code)
              values (%s::uuid, %s::uuid, %s::uuid, %s, %s, %s, %s)""",
           (acc["i"], gid, acc["o"], nm, nm.split()[0] + " " + nm.split()[1][0] + ".", k, "V" + k[:7]))

    print("A · «Məşq ver» düyməsi")
    pg.goto(PANEL + "#/a/" + gid); pg.reload(); pg.wait_for_selector("#btnAsgM", timeout=20000); pg.wait_for_timeout(800)
    ok(pg.inner_text("#btnAsgM").strip() == "Məşq ver", "Tapşırıqlar sekməsində «Məşq ver»")
    ok(pg.locator("#mqBox h2").count() == 0, "məşq verilməyib — «Məşqlər» bölməsi yoxdur")
    ok(pg.locator("#gAsgM").count() == 1 and pg.locator("#gAsgM").get_attribute("href") == "#/a/%s/m" % gid, "başlıq menyusunda «Məşq ver»")

    print("B · Məşq ver")
    pg.click("#btnAsgM"); pg.wait_for_selector("#mqList .trow", timeout=20000); pg.wait_for_timeout(400)
    ok(hash_(pg) == "#/a/%s/m" % gid, "ünvan #/a/<qrup>/m", hash_(pg))
    rows = pg.locator("#mqList .trow")
    ok(rows.count() == 1 and "Natural ədədlər" in rows.first.inner_text() and "6 sual" in rows.first.inner_text(),
       "yalnız məşq sualı olan dərs (Natural ədədlər · 6 sual)", rows.first.inner_text().replace("\n", " ") if rows.count() else "")
    ok(pg.evaluate("document.getElementById('btnMqGive').disabled"), "dərs seçilmədən düymə bağlı")
    dt = pg.inner_text("#mqDateTxt")
    ok(re.search(r"\d+ (yanvar|fevral|mart|aprel|may|iyun|iyul|avqust|sentyabr|oktyabr|noyabr|dekabr) \d{4}, ", dt) is not None, "son tarix uzun yazı ilə", dt)
    ok(pg.locator("#mqWho option").count() == 3, "Kimə: bütün qrup + 2 şagird")
    if SHOT: pg.screenshot(path=SHOT + "/mq_ver_1280.png", full_page=True)
    rows.first.click(); pg.wait_for_timeout(200)
    ok(not pg.evaluate("document.getElementById('btnMqGive').disabled") and "on" in (rows.first.get_attribute("class") or ""), "dərs seçildi, düymə açıq")
    pg.click("#btnMqGive"); pg.wait_for_function("location.hash.indexOf('#/mq/') === 0", timeout=20000)
    pg.wait_for_selector("#mqStarted", timeout=20000); pg.wait_for_timeout(400)
    mid = hash_(pg).split("/")[-1]
    ok(pg.inner_text("#mqStarted").strip() == "0 / 2" and "Dərs məşqi verildi — 6 sual" in pg.inner_text("#main"), "hesabat: 0 / 2 başlayıb, təsdiq yazısı")
    ok(pg.locator("#mqStu .mqr .mq0").count() == 2, "hər iki şagird «hələ başlamayıb»")
    ok("Hələ səhv yoxdur" in pg.inner_text("#mqHard"), "boş hal: «Hələ səhv yoxdur»")
    m = db("select cardinality(qids) n from public.mesq_assignments where id = %s::uuid", (mid,), one=True)
    ok(m and m["n"] == 6, "6 sual dondurulub", m)

    print("C · Geri")
    pg.click("#btnBack"); pg.wait_for_function("location.hash === '#/a/%s/m' || location.hash === '#/a/%s'" % (gid, gid), timeout=10000)
    #  «Geri» geldiyi yere aparir (Məşq ver); oradan bir daha «Geri» - Tapşırıqlar
    if hash_(pg).endswith("/m"):
        pg.wait_for_selector("#btnBack", timeout=10000); pg.click("#btnBack")
    pg.wait_for_function("location.hash === '#/a/%s'" % gid, timeout=10000)
    pg.wait_for_selector("#mqBox .mqr", timeout=20000)
    ok("Natural ədədlər" in pg.inner_text("#mqBox") and "0 / 2 bitirib" in pg.inner_text("#mqBox"), "«Dərs məşqləri» siyahısında", pg.inner_text("#mqBox").replace("\n", " "))
    pg.click("#mqBox .mqr"); pg.wait_for_selector("#mqStarted", timeout=20000)
    pg.go_back(); pg.wait_for_function("location.hash === '#/a/%s'" % gid, timeout=10000)
    ok(True, "brauzerin geri oxu hesabatdan Tapşırıqlara qaytardı")

    print("B2 · qrupun İcmalı: «Son tapşırıqlar»da dərs məşqi")
    pg.goto(PANEL + "#/g/" + gid); pg.reload(); pg.wait_for_selector("#gkAsg .ykh", timeout=20000)
    pg.wait_for_selector("#gkAsg .gkmq", timeout=20000)
    r0 = pg.locator("#gkAsg .gkmq").first
    ok("dərs məşqi" in r0.inner_text() and "Natural ədədlər" in r0.inner_text() and r0.get_attribute("href") == "#/mq/" + mid,
       "«Son tapşırıqlar»da «dərs məşqi» sətri, hesabata aparır", r0.inner_text().replace("\n", " "))
    if SHOT: pg.screenshot(path=SHOT + "/mq_icmal_1280.png", full_page=True)

    print("D · boş hal")
    pg.goto(PANEL + "#/a/" + g7 + "/m"); pg.wait_for_selector(".empty", timeout=20000)
    ok("Bu sinif üçün hələ məşq yoxdur" in pg.inner_text("#main") and pg.locator("#btnMqGive").count() == 0, "7-ci sinif: «hələ məşq yoxdur», düymə yoxdur")
    if SHOT: pg.screenshot(path=SHOT + "/mq_bos_1280.png", full_page=True)

    print("E · şagird")
    sp = page(ctx, 390, 844)
    sp.goto(STUDENT); sp.wait_for_selector("#btnIn", timeout=15000)
    sp.fill("#code", "MQAYSEL1"); sp.click("#btnIn"); sp.wait_for_selector("#msqBox .mqrow", timeout=20000)
    ok("Natural ədədlər" in sp.inner_text("#msqBox") and "6 sual" in sp.inner_text("#msqBox"), "ev ekranında «Məşq» · 6 sual")
    ok("Müəllimin tapşırıq verməsini gözlə" not in sp.inner_text("#main") and "Yuxarıdakı məşqi işlə" in sp.inner_text("#main"),
       "məşq varkən «tapşırıq yoxdur — gözlə» yazılmır")
    ok(sp.locator("#msqBox .mqrow .ic svg").count() == 1, "kartda ikon var")
    ok(sp.inner_text("#msqH").strip() == "Dərs məşqi" and sp.locator("#msqBox .mqrow .mqtag").count() == 1
       and "Hər cavabdan sonra düzünü görəcəksən" in sp.inner_text("#msqBox"), "kart testdən seçilir: «Dərs məşqi» başlığı, «məşq» nişanı, ipucu")
    if SHOT:
        sp.screenshot(path=SHOT + "/mq_sagird_ev_390.png", full_page=True)
        #  tutusdurma sekli: eyni ev ekraninda HEM test HEM ders mesqi - ferq gorunsun (sonra test silinir)
        db("""insert into public.assignments (class_id, test_id, assigned_by, closes_at, max_attempts)
              select %s::uuid, t.id, %s::uuid, now() + interval '7 days', 1 from public.tests t
               where t.owner_type = 'platform' and t.status = 'published' and t.is_free order by t.created_at limit 1""", (gid, acc["o"]))
        sp.reload(); sp.wait_for_selector("#msqBox .mqrow", timeout=20000); sp.wait_for_selector(".test.asg:not(.mqrow)", timeout=20000); sp.wait_for_timeout(500)
        sp.screenshot(path=SHOT + "/mq_vs_test_390.png", full_page=True)
        db("delete from public.assignments where class_id = %s::uuid", (gid,))
        sp.reload(); sp.wait_for_selector("#msqBox .mqrow", timeout=20000)
    def opts(): return sp.locator("#mopts [data-o]").evaluate_all("els => els.map(e => e.getAttribute('data-o'))")
    def cnt(): return sp.inner_text(".mqprog .cnt").strip()
    def answer(right):
        ids = opts(); want = next(o for o in ids if (o in CORRECT) == right)
        sp.locator("[data-o='%s']" % want).click(); sp.wait_for_selector("#mFb .ok, #mFb .warn", timeout=15000)
    sp.click("#msqBox .mqrow"); sp.wait_for_selector("#mopts [data-o]", timeout=20000)
    ok(cnt() == "1 / 6" and "Ədədi oxu: 305" in sp.inner_text(".q"), "1-ci sual (asan), 1 / 6", cnt())
    ok(sp.locator("#mopts .right, #mopts .wrong").count() == 0, "cavabdan əvvəl düz variant işarələnmir")
    answer(True)
    ok("Düzdür!" in sp.inner_text("#mFb") and "üç yüz beş" in sp.inner_text("#mFb"), "düz → «Düzdür!» + izah")
    ok(cnt() == "1 / 6", "cavabdan sonra sayğac eyni sualda qalır (1 / 6)", cnt())
    if SHOT: sp.screenshot(path=SHOT + "/mq_sagird_duz_390.png", full_page=True)
    #  Beledci sekli (komek/img/m17_mesq.png): BELEDCI_IMG=1 ile - ekranin ustunden «Növbəti sual»a qeder
    if os.environ.get("BELEDCI_IMG"):
        box = sp.evaluate("() => { const b = document.getElementById('btnMNext').getBoundingClientRect(); return {x: 0, y: 0, width: 390, height: b.bottom + window.scrollY + 18}; }")
        sp.screenshot(path=os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "komek", "img", "m17_mesq.png"), full_page=True, clip=box)
    sp.click("#btnMNext"); sp.wait_for_function("document.querySelector('.mqprog .cnt') && document.querySelector('.mqprog .cnt').textContent.trim() === '2 / 6' && !document.querySelector('#mFb .ok, #mFb .warn')", timeout=15000)
    answer(False)
    ok("Səhvdir." in sp.inner_text("#mFb") and "74 > 47" in sp.inner_text("#mFb"), "səhv → «Səhvdir.» + izah")
    ok(sp.locator("#mopts .right").count() == 0, "səhvdən sonra da düz variant göstərilmir")
    if SHOT: sp.screenshot(path=SHOT + "/mq_sagird_sehv_390.png", full_page=True)
    sp.click("#btnMOut"); sp.wait_for_selector("#msqBox .mqrow", timeout=20000)
    ok("2 / 6 sual" in sp.inner_text("#msqBox") and "50%" in sp.inner_text("#msqBox"), "«Sonra davam et» → siyahıda 2 / 6, 50%", sp.inner_text("#msqBox").replace("\n", " "))
    ok(sp.locator(".stiles").count() == 0, "məşq «işlənmiş test» sayğacına düşmür")
    sp.click("#msqBox .mqrow"); sp.wait_for_selector("#mopts [data-o]", timeout=20000)
    body = sp.inner_text(".q")
    ok(cnt() == "3 / 6" and re.search(r"^\d{3} ədədindən sonra", body.strip()) is not None, "davam: 3-cü sual, şablon rəqəmlə", body)
    n0 = int(re.search(r"(\d{3})", body).group(1))
    ok(str(n0 + 1) in sp.inner_text("#mopts"), "şablonun düz rəqəmi variantlarda")
    answer(True)
    ok(("%d + 1 = %d" % (n0, n0 + 1)) in sp.inner_text("#mFb"), "şablon izahı şagirdin rəqəmi ilə")
    for i in range(3):
        sp.click("#btnMNext"); sp.wait_for_function("document.querySelector('#mopts [data-o]') && !document.querySelector('#mFb .ok, #mFb .warn')", timeout=15000)
        answer(True)
    ok(sp.inner_text("#btnMNext").strip() == "Nəticəyə bax", "son sualdan sonra «Nəticəyə bax»")
    sp.click("#btnMNext"); sp.wait_for_selector(".mqdone", timeout=15000)
    ok("Məşq bitdi" in sp.inner_text(".mqdone") and "5 / 6" in sp.inner_text(".mqres") and "83%" in sp.inner_text(".mqres"), "«Məşq bitdi · 5 / 6 · 83%»")
    if SHOT: sp.screenshot(path=SHOT + "/mq_sagird_son_390.png", full_page=True)
    sp.click("#btnMqHome"); sp.wait_for_selector("#msqBox .mqrow.done", timeout=20000)
    ok("bitib" in sp.inner_text("#msqBox"), "siyahıda «bitib»")

    print("F · müəllim hesabatı")
    pg.goto(PANEL + "#/mq/" + mid); pg.reload(); pg.wait_for_selector("#mqStarted", timeout=20000); pg.wait_for_timeout(400)
    ok(pg.inner_text("#mqStarted").strip() == "1 / 2" and pg.inner_text("#mqFinished").strip() == "1" and pg.inner_text("#mqPct").strip() == "83%",
       "1 / 2 başlayıb · 1 bitirib · 83%", [pg.inner_text("#mqStarted"), pg.inner_text("#mqFinished"), pg.inner_text("#mqPct")])
    st = pg.inner_text("#mqStu").replace("\n", " ")
    ok("Aysel Quliyeva" in st and "6 / 6 sual · bitirib ✓" in st and "Murad Əliyev hələ başlamayıb" in st, "şagird sətirləri", st)
    ok(pg.locator("#mqHard .mqh").count() == 1 and "№ 2" in pg.inner_text("#mqHard") and "47-dən böyük" in pg.inner_text("#mqHard"), "ən çox səhv: № 2", pg.inner_text("#mqHard").replace("\n", " "))
    pg.click("#mqStu .mqr >> nth=0"); pg.wait_for_function("location.hash.indexOf('#/s/') === 0", timeout=10000)
    ok(True, "şagird sətri profilə aparır")

    print("G · valideyn")
    vp = page(ctx, 390, 844)
    vp.goto(PARENT); vp.wait_for_selector("#code", timeout=15000)
    vp.fill("#code", "VMQAYSEL"); vp.click("#btnIn"); vp.wait_for_selector("#mqLine .mqline", timeout=20000)
    ok("«Natural ədədlər» — 6 / 6 sual işləyib ✓, 83% düz" in vp.inner_text("#mqLine"), "bir sətir", vp.inner_text("#mqLine"))
    if SHOT: vp.screenshot(path=SHOT + "/mq_valideyn_390.png", full_page=True)

    print("H · test mexanizmi")
    ok(db("select count(*) n from public.attempts a join public.students s on s.id = a.student_id where s.class_id = %s::uuid", (gid,), one=True)["n"] == 0, "attempts-ə heç nə yazılmayıb")

    print("I · telefon 390 / 360")
    for w in (390, 360):
        pg.set_viewport_size({"width": w, "height": 844})
        pg.goto(PANEL + "#/a/" + gid + "/m"); pg.reload(); pg.wait_for_selector("#mqList .trow", timeout=20000); pg.wait_for_timeout(500)
        s2 = sw(pg); ok(s2[0] <= s2[1], "%d: Məşq ver — yana sürüşmə yoxdur" % w, s2)
        hh = pg.evaluate("['#btnMqGive', '#mqList .trow', '#mqWho', '.mqgive .dfld'].map(s => Math.round(document.querySelector(s).getBoundingClientRect().height))")
        ok(min(hh) >= 44, "%d: düymə və sahələr ≥ 44 px" % w, hh)
        if SHOT: pg.screenshot(path=SHOT + "/mq_ver_%d.png" % w, full_page=True)
        pg.goto(PANEL + "#/mq/" + mid); pg.reload(); pg.wait_for_selector("#mqStarted", timeout=20000); pg.wait_for_timeout(500)
        s2 = sw(pg); ok(s2[0] <= s2[1], "%d: hesabat — yana sürüşmə yoxdur" % w, s2)
        hh = pg.evaluate("[...document.querySelectorAll('#mqStu .mqr')].map(e => Math.round(e.getBoundingClientRect().height))")
        ok(hh and min(hh) >= 44, "%d: şagird sətirləri ≥ 44 px" % w, hh)
        if SHOT: pg.screenshot(path=SHOT + "/mq_hesabat_%d.png" % w, full_page=True)
        pg.goto(PANEL + "#/a/" + gid); pg.reload(); pg.wait_for_selector("#mqBox .mqr", timeout=20000); pg.wait_for_timeout(400)
        s2 = sw(pg); ok(s2[0] <= s2[1], "%d: Tapşırıqlar — yana sürüşmə yoxdur" % w, s2)
        bb = pg.evaluate("[...document.querySelectorAll('.asgact .btn')].map(e => [Math.round(e.getBoundingClientRect().width), Math.round(e.getBoundingClientRect().height)])")
        ok(len(bb) == 3 and min(b[1] for b in bb) >= 44, "%d: 3 düymə, ≥ 44 px" % w, bb)
        if SHOT: pg.screenshot(path=SHOT + "/mq_tapsiriqlar_%d.png" % w, full_page=True)
        pg.goto(PANEL + "#/g/" + gid); pg.reload(); pg.wait_for_selector("#gkAsg .gkmq", timeout=20000); pg.wait_for_timeout(400)
        s2 = sw(pg); ok(s2[0] <= s2[1], "%d: qrupun İcmalı — yana sürüşmə yoxdur" % w, s2)
        if SHOT: pg.screenshot(path=SHOT + "/mq_icmal_%d.png" % w, full_page=True)
    for w in (360,):
        sp.set_viewport_size({"width": w, "height": 800})
        sp.goto(STUDENT); sp.wait_for_selector("#msqBox .mqrow", timeout=20000)
        s2 = sw(sp); ok(s2[0] <= s2[1], "%d: şagird ev ekranı — yana sürüşmə yoxdur" % w, s2)
    pg.set_viewport_size({"width": 1280, "height": 900})
    pg.goto(PANEL + "#/mq/" + mid); pg.reload(); pg.wait_for_selector("#mqStarted", timeout=20000); pg.wait_for_timeout(400)
    if SHOT: pg.screenshot(path=SHOT + "/mq_hesabat_1280.png", full_page=True)
    pg.goto(PANEL + "#/a/" + gid); pg.reload(); pg.wait_for_selector("#mqBox .mqr", timeout=20000); pg.wait_for_timeout(400)
    if SHOT: pg.screenshot(path=SHOT + "/mq_tapsiriqlar_1280.png", full_page=True)
    br.close()

db("delete from public.mesq_assignments; delete from public.questions where ext_key like 'e2emesq-%%'")
print("\n" + ("BUTUN YOXLAMALAR KECDI" if not fails else "SEHV (%d): %s" % (len(fails), " | ".join(fails))))
sys.exit(1 if fails else 0)
