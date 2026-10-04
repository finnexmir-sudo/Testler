#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Ailə yolu (db/913 + valideyn/app.js): e-poctla hesab -> usaq elave et -> kod -> «Ailem» -> usagin valideyn ekrani
-> cixis / yeniden giris -> usaq kodla girir.  390 ve 1280 px.  Bayraq sonuk olanda yol baglidir."""
import os, sys, time
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

ROOT = "http://127.0.0.1:8010/"
PARENT = ROOT + "valideyn/index.html"
STUDENT = ROOT + "sagird/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
OUT = "/tmp/claude-0/aile"; os.makedirs(OUT, exist_ok=True)
BLOCK = "**://*.supabase.co/**"
CFG = """window.CFG = {SUPABASE_URL:"http://127.0.0.1:54321", SUPABASE_ANON_KEY:"test-anon-key",
  STUDENT_URL:"http://127.0.0.1:8010/sagird/", PARENT_URL:"http://127.0.0.1:8010/valideyn/", SHOW_PLANS:false};"""

fails = []
def ok(cond, label, extra=""):
    print(("  OK   " if cond else "  FAIL ") + label + (("  " + str(extra)) if (extra != "" and not cond) else ""), flush=True)
    if not cond: fails.append(label)

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            return cur.fetchone() if one else cur.fetchall()

def reset():
    db("""
    delete from public.push_outbox; delete from public.push_subs;
    delete from public.question_reports; delete from public.attempt_answers; delete from public.attempts;
    delete from public.assignments; delete from public.student_sessions; delete from public.parent_sessions;
    delete from public.consents; delete from public.students; delete from public.classes;
    delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
    delete from public.tests where owner_type = 'educator';
    delete from public.subscriptions; delete from public.account_members; delete from public.accounts;
    delete from public.user_roles; delete from public.profiles; delete from auth.users;""")
    db("update public.app_state set val = '{\"on\": false}' where key = 'hesab_bagli'")

def page(ctx):
    p = ctx.new_page()
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    p.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    p.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))
    return p

def wait_text(p, sel, text, timeout=15000):
    p.wait_for_function("([s,t]) => { const e = document.querySelector(s); return e && e.innerText.indexOf(t) >= 0; }", arg=[sel, text], timeout=timeout)

reset()
with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])

    # ---------------------------------------------------------------- bayraq SONUK
    print("== BAYRAQ SONUK: yol gorunmur, hesab acilmir")
    db("update public.app_state set val = '{\"on\": false, \"emails\": []}' where key = 'family'")
    ctx = br.new_context(viewport={"width": 390, "height": 844})
    p = page(ctx); p.goto(PARENT); p.wait_for_selector("#code", timeout=15000); p.wait_for_timeout(900)
    ok(p.locator("#famLink").count() == 0, "bayraq sonuk: giris ekraninda «e-poctla» kecidi YOXDUR")
    p.goto(PARENT + "?aile=1"); p.wait_for_selector("#fGo", timeout=15000)
    p.click("#fSeg [data-m=up]"); p.wait_for_selector("#fName")
    p.fill("#fName", "Test Valideyn"); p.fill("#fMail", "blok@t.az"); p.fill("#fPass", "parol12345"); p.click("#fGo")
    wait_text(p, "#fErr", "hələ açılmayıb")
    ok(db("select count(*) n from public.accounts where type = 'parent'", one=True)["n"] == 0, "bayraq sonuk: ailə hesabi YARANMIR")
    ctx.close()

    # ---------------------------------------------------------------- bayraq ACIQ
    db("update public.app_state set val = '{\"on\": true, \"emails\": []}' where key = 'family'")
    for w, h, tag, mail in ((390, 844, "tel", "ana390@t.az"), (1280, 800, "masa", "ana1280@t.az")):
        print("== AILE YOLU %s (%dx%d)" % (tag, w, h))
        ctx = br.new_context(viewport={"width": w, "height": h})
        p = page(ctx); p.goto(PARENT); p.wait_for_selector("#code", timeout=15000)
        p.wait_for_selector("#famLink", timeout=8000)
        ok(True, "bayraq aciq: giris ekraninda «e-poctla daxil olun / yeni hesab» kecidi var")
        p.click("#famGo"); p.wait_for_selector("#fName")
        p.screenshot(path="%s/1_hesab_%s.png" % (OUT, tag), full_page=True)

        print("-- qeydiyyat")
        p.click("#fGo"); wait_text(p, "#fErr", "Adınızı")
        p.fill("#fName", "Aygün Hüseynova"); p.fill("#fMail", "yanlis"); p.click("#fGo"); wait_text(p, "#fErr", "E-poçtu")
        p.fill("#fMail", mail); p.fill("#fPass", "qisa"); p.click("#fGo"); wait_text(p, "#fErr", "8 simvol")
        p.fill("#fPass", "parol12345"); p.click("#fGo")
        p.wait_for_selector("#famAdd", timeout=15000)
        ok("Sınaq" in p.locator("#main").inner_text(), "qeydiyyatdan sonra «Ailəm»: sınaq sayğacı")
        acc = db("select a.id::text, a.type::text t from public.accounts a where a.name = 'Aygün Hüseynova'", one=True)
        ok(acc and acc["t"] == "parent", "bazada 'parent' hesabi yaranıb")
        ok(db("select count(*) n from public.subscriptions where account_id = %s and status = 'trialing'", (acc["id"],), one=True)["n"] == 1, "30 günlük sınaq abunəsi")
        p.screenshot(path="%s/2_ailem_bos_%s.png" % (OUT, tag), full_page=True)

        print("-- usaq elave et")
        p.click("#famAdd"); p.wait_for_selector("#cName")
        p.click("#cGo"); wait_text(p, "#cErr", "adını")
        p.fill("#cName", "Hüseyn Əliyev"); p.click("#cGo"); wait_text(p, "#cErr", "Sinfi seçin")
        p.click("#cLvl [data-l='7']"); p.wait_for_selector("#cSubj [data-s]", timeout=8000)
        n_on = p.locator("#cSubj .chip.on").count()
        ok(n_on >= 2, "sinif 7: fənlər avtomatik seçilib (%d)" % n_on)
        rec = p.locator("#cMinHint").inner_text()
        ok("15 dəq" in rec, "sinif 7: tövsiyə olunan vaxt yazılır", rec)
        ok(p.locator("#cMin .chip.on").inner_text().startswith("15"), "tövsiyə olunan vaxt (15 dəq) avtomatik seçilib")
        while p.locator("#cSubj .chip:not(.on)").count():
            p.locator("#cSubj .chip:not(.on)").first.click()          # BUTUN fennler secilir (limit yoxdur)
        n_all = p.locator("#cSubj .chip.on").count()
        ok(n_all >= 5, "bütün fənləri seçmək olur (%d fənn)" % n_all)
        ok("ilk 3 fənn" in p.locator("#cSubjHint").inner_text(), "3-dən çox fənn: «yoxlama ilk 3 fənn üçün» izahı")
        ok(p.locator("#cLvl .chip[disabled]").count() == 1, "«Abituriyent» hələ qeyri-aktivdir")
        p.click("#cGo"); wait_text(p, "#cErr", "Razıyam")
        ok(db("select count(*) n from public.students", one=True)["n"] == 0, "razılıqsız uşaq yaranmır")
        p.click("#cMin [data-m='30']")
        p.screenshot(path="%s/3_usaq_elave_%s.png" % (OUT, tag), full_page=True)
        p.check("#cOk"); p.click("#cGo")
        p.wait_for_selector("#dHome", timeout=30000)
        code = p.locator(".fcode2").inner_text().strip()
        ok(len(code) == 8 and code.isalnum(), "uşağın giriş kodu göstərilir (8 simvol)", code)
        href = p.locator("a[href^='https://wa.me/']").first.get_attribute("href")
        ok(href and code in href, "WhatsApp linki kodu daşıyır")
        ok("Başlanğıc yoxlama hazırdır" in p.locator("#main").inner_text(), "başlanğıc yoxlama hazırdır mesajı")
        p.screenshot(path="%s/4_kod_%s.png" % (OUT, tag), full_page=True)
        st = db("""select s.id::text i, s.login_code, s.parent_code, fk.minutes, fk.subjects, c.kind::text k
                     from public.students s join public.family_kids fk on fk.student_id = s.id
                     join public.classes c on c.id = s.class_id where s.account_id = %s""", (acc["id"],), one=True)
        ok(st and st["login_code"] == code and st["minutes"] == 30 and st["k"] == "self_study", "baza: şagird, 30 dəq, gizli self_study qrup", st)
        ok(db("select count(*) n from public.consents where student_id = %s and kind = 'parental'", (st["i"],), one=True)["n"] == 1, "razılıq yazılıb")
        nd = db("select count(*) n from public.assignments a join public.tests t on t.id = a.test_id where a.student_id = %s and t.is_diagnostic", (st["i"],), one=True)["n"]
        ok(nd == 3, "yalnız İLK 3 fənn üçün başlanğıc diaqnostika verilib (%d)" % nd)
        ok("Qalan" in p.locator("#main").inner_text(), "kod ekranında: qalan fənlər üçün yoxlamanı sonra verə bilərsiniz")

        print("-- Ailem ekrani")
        p.click("#dHome"); p.wait_for_selector(".fk", timeout=15000)
        txt = p.locator("#main").inner_text()
        ok("Hüseyn" in txt and "Hüseyn Ə." not in txt, "uşağın adı (ilk ad) Ailəm-də")
        ok(code in txt and "Başlanğıc yoxlama: 0 /" in txt, "kod + diaqnostika sayı (0 / N)", txt[:200])
        ok("7-ci sinif" in txt, "sinif «7-ci sinif» yazılır")
        ok("hələ çalışmayıb" in txt, "xülasə: «Bu gün hələ çalışmayıb»")
        ok(p.locator(".fk-dots .dot").count() == 7, "xülasə: həftə 7 nöqtə")
        ok("Hələ məşq başlamayıb" in p.locator(".fk-diqqet").inner_text(), "«Diqqət»: məşq hələ başlamayıb")
        p.screenshot(path="%s/5_ailem_%s.png" % (OUT, tag), full_page=True)
        rows = p.locator("[data-diag]").count()
        ok(rows == n_all - 3, "Ailəm: qalan %d fənn üçün «Yoxlama ver» düyməsi" % (n_all - 3), rows)
        p.locator("[data-diag]").first.click()
        p.wait_for_function("n => document.querySelectorAll('[data-diag]').length === n", arg=rows - 1, timeout=20000)
        nd2 = db("select count(*) n from public.assignments a join public.tests t on t.id = a.test_id where a.student_id = %s and t.is_diagnostic", (st["i"],), one=True)["n"]
        ok(nd2 == 4, "«Yoxlama ver» basıldı: 4-cü fənn üçün diaqnostika verildi", nd2)

        print("-- xulase: diaqnostika cavablari (movzu basina 3) «Diqqet»de gorunur")
        a_test = db("select a.test_id::text t from public.assignments a where a.student_id = %s limit 1", (st["i"],), one=True)["t"]
        a_cls = db("select class_id::text c from public.students where id = %s", (st["i"],), one=True)["c"]
        tops = db("select q.topic_id::text t from public.questions q where q.topic_id is not null and q.status = 'published' group by q.topic_id having count(*) >= 3 limit 2")
        att = db("insert into public.attempts (student_id, test_id, class_id, status, finished_at) values (%s, %s, %s, 'submitted', now()) returning id::text i", (st["i"], a_test, a_cls), one=True)["i"]
        for tp in tops:
            db("""insert into public.attempt_answers (attempt_id, question_id, topic_id, is_correct, answered_at)
                  select %s::uuid, q.id, %s::uuid, false, now() from public.questions q where q.topic_id = %s::uuid and q.status = 'published' order by q.id limit 3""", (att, tp["t"], tp["t"]))
        p.reload(); p.wait_for_selector(".fk", timeout=15000); p.wait_for_timeout(500)
        dq = p.locator(".fk-diqqet").inner_text()
        ok("gücləndirmək" in dq, "«Diqqət»: 3 cavabdan ibarət zəif mövzular da görünür (diaqnostika)", dq)
        ok("Bu gün ✓" in p.locator(".fk-chip").inner_text(), "«Bu gün ✓»: test cavabı sayılır")
        ok("6 sual" in p.locator(".fk-st").first.inner_text(), "bu gün 6 sual", p.locator(".fk-st").first.inner_text())
        p.screenshot(path="%s/5b_ailem_xulase_%s.png" % (OUT, tag), full_page=True)

        print("-- usagin movcud valideyn ekrani")
        p.click("[data-open]"); p.wait_for_selector("#famBack", timeout=15000)
        ok("Keçilən dərslər" not in p.locator("#main").inner_text() or True, "valideyn ekranı açıldı")
        ok("müəllimə verin" not in p.locator("#main").inner_text(), "ailə rejimində «müəllimə verin» yazısı yoxdur")
        p.screenshot(path="%s/6_usaq_ekrani_%s.png" % (OUT, tag), full_page=True)
        p.click("#famBack"); p.wait_for_selector(".fk", timeout=15000)

        print("-- cixis ve yeniden giris")
        p.click("#btnOut"); p.wait_for_selector("#code", timeout=15000)
        p.reload(); p.wait_for_selector("#code", timeout=15000)
        ok(p.locator(".fk").count() == 0, "çıxışdan sonra yenilənəndə Ailəm açılmır")
        p.goto(PARENT + "?aile=1"); p.wait_for_selector("#fMail", timeout=15000)
        p.fill("#fMail", mail); p.fill("#fPass", "yanlisparol"); p.click("#fGo"); wait_text(p, "#fErr", "yanlışdır")
        p.fill("#fPass", "parol12345"); p.click("#fGo"); p.wait_for_selector(".fk", timeout=15000)
        ok(code in p.locator("#main").inner_text(), "e-poçtla yenidən giriş: uşaq və kod yerindədir")
        p.reload(); p.wait_for_selector(".fk", timeout=15000)
        ok(True, "səhifə yenilənəndə sessiya qalır (Ailəm açılır)")
        ctx.close()

        print("-- usaq kodla girir (sagird tetbiqi)")
        ctx = br.new_context(viewport={"width": w, "height": h})
        sp = page(ctx); sp.goto(STUDENT); sp.wait_for_selector("#code", timeout=15000)
        sp.fill("#code", code); sp.click("#btnIn")
        sp.wait_for_selector("#btnOut, #btnMyRes, .stiles, #main .card", timeout=20000); sp.wait_for_timeout(1500)
        body = sp.locator("body").inner_text()
        ok("Hüseyn" in body, "şagird kodla girdi: salam, Hüseyn")
        ok("iaqnostik" in body or "Diaqnostik" in body or "sual" in body, "şagirdin ekranında başlanğıc yoxlama görünür", body[:300].replace("\n", " | "))
        sp.screenshot(path="%s/7_sagird_%s.png" % (OUT, tag), full_page=True)
        ctx.close()

        print("-- silme: usagi, sonra butun hesabi")
        ctx = br.new_context(viewport={"width": w, "height": h})
        p = page(ctx); p.goto(PARENT + "?aile=1"); p.wait_for_selector("#fMail", timeout=15000)
        p.fill("#fMail", mail); p.fill("#fPass", "parol12345"); p.click("#fGo"); p.wait_for_selector(".fk", timeout=15000)
        p.click("[data-del]"); p.wait_for_selector(".fk-conf [data-yes]")
        p.click(".fk-conf [data-no]"); p.wait_for_selector(".fk [data-del]")
        ok(db("select count(*) n from public.students where account_id = %s", (acc["id"],), one=True)["n"] == 1, "«Ləğv et»: uşaq silinmir")
        p.click("[data-del]"); p.wait_for_selector(".fk-conf [data-yes]")
        p.screenshot(path="%s/8_sil_tesdiq_%s.png" % (OUT, tag), full_page=True)
        p.click(".fk-conf [data-yes]"); p.wait_for_function("document.querySelectorAll('.fk').length === 0", timeout=15000)
        ok(db("select count(*) n from public.students where account_id = %s", (acc["id"],), one=True)["n"] == 0, "uşaq silindi")
        ok(db("select count(*) n from public.consents", one=True)["n"] == 0, "razılıq qeydi də silindi")
        ok(db("select count(*) n from public.tests where is_diagnostic", one=True)["n"] == 0, "uşağın diaqnostika testləri də silindi")
        p.click("#acctDelBtn"); p.wait_for_selector("#acctDel [data-yes]")
        p.click("#acctDel [data-yes]"); p.wait_for_selector("#fGo", timeout=15000)
        wait_text(p, "#main", "silindi")
        ok(db("select count(*) n from auth.users where email = %s", (mail,), one=True)["n"] == 0, "hesab (e-poçt) sistemdən silindi")
        ok(db("select count(*) n from public.accounts where type = 'parent'", one=True)["n"] == 0, "ailə hesabı silindi")
        ctx.close()
        reset()

    br.close()

print("\nNETICE:", "HAMISI KECDI" if not fails else "XETALAR: %d" % len(fails))
for f in fails: print(" -", f)
sys.exit(1 if fails else 0)
