#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""HESAB BAGLI (db/905): sinaq bitende hesab baglanir - ucdan-uca (1-A / 2-B).

  1-A  Muellim: butun panel yerine BIR bagli ekran (melumat silinmir); abune/uzatma - her sey qayidir.
  2-B  Sagird: verilmis testi gorur, oz basina mesq baglidir.
Ayar app_state.hesab_bagli yerli bazada SONUKDUR; bu test onu acir ve sonda geri qoyur."""
import time
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

PANEL   = "http://127.0.0.1:8010/muellim/index.html"
STUDENT = "http://127.0.0.1:8010/sagird/index.html"
CHROME  = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN     = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
OUT     = "/tmp/claude-0/hesabbagli"
import os; os.makedirs(OUT, exist_ok=True)
TEST_CFG = """window.CFG = {
  SUPABASE_URL: "http://127.0.0.1:54321",
  SUPABASE_ANON_KEY: "test-anon-key",
  STUDENT_URL: "http://127.0.0.1:8010/sagird/",
  PARENT_URL:  "http://127.0.0.1:8010/valideyn/",
  CONTACT_WHATSAPP: "+994 50 123 45 67",
  SHOW_PLANS: false
};"""
BLOCK = "**://*.supabase.co/**"

fails = []
def ok(cond, label, extra=""):
    print(("  OK   " if cond else "  FAIL ") + label + (("  " + str(extra)) if extra != "" else ""), flush=True)
    if not cond: fails.append(label)

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            return cur.fetchone() if one else cur.fetchall()

def ayar(on):
    db("update public.app_state set val = %s::jsonb where key = 'hesab_bagli'", ('{"on": %s}' % ("true" if on else "false"),))

db("""
delete from public.practice; delete from public.mistakes; delete from public.feedback; delete from public.question_reports; delete from public.parent_sessions;
delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers; delete from public.attempts; delete from public.assignments;
delete from public.student_sessions; delete from public.students; delete from public.classes;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator'; delete from public.subscriptions;
delete from public.account_members; delete from public.accounts; delete from public.user_roles;
delete from public.profiles; delete from auth.users;""")
ayar(False)
EMAIL = "bagli%d@t.az" % int(time.time())

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

    print("A · Hazırlıq (ayar sönük): müəllim, qrup, şagird, verilmiş test")
    pg.goto(PANEL + "?yeni=1"); pg.wait_for_selector("#btnAuth", timeout=15000)
    pg.click("#btnSwap")
    pg.fill("#fname", "Bagli Muellim"); pg.fill("#email", EMAIL)
    pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=15000)
    pg.select_option("#atype", "tutor"); pg.fill("#aname", "Bagli hesabi"); pg.click("#btnSetup")
    pg.wait_for_selector("#adminMsg", state="attached", timeout=30000)
    acc = db("select a.id::text i, a.owner_id::text o from public.accounts a limit 1", one=True)
    lev = db("select l.id::text i from public.levels l join public.programs p on p.id = l.program_id where p.slug='ibtidai' and l.code='3'", one=True)["i"]
    GID = db("""insert into public.classes (account_id, teacher_id, kind, name, join_code, level_id)
                values (%s::uuid, %s::uuid, 'tutor_group', '3-cu sinif', 'BGL00001', %s::uuid) returning id::text i""",
             (acc["i"], acc["o"], lev), one=True)["i"]
    SID = db("""insert into public.students (account_id, class_id, created_by, full_name, display_name, login_code)
                values (%s::uuid, %s::uuid, %s::uuid, 'Ayan Bir', 'Ayan B.', 'SAGBGL01') returning id::text i""",
             (acc["i"], GID, acc["o"]), one=True)["i"]
    TEST = db("select id::text i, title t from public.tests where slug='riy-3-vurma-1'", one=True)
    db("insert into public.assignments (class_id, test_id, assigned_by) values (%s::uuid, %s::uuid, %s::uuid)",
       (GID, TEST["i"], acc["o"]))
    pg.goto(PANEL + "?yeni=1"); pg.reload()
    pg.wait_for_selector("#adminMsg", state="attached", timeout=20000)
    ok(pg.locator("#lockCard").count() == 0, "ayar sönükdür: panel adi açılır (köhnə davranış)")

    print("\nB · Ayar açıq, abunəsiz hesab — BAĞLI EKRAN (1-A)")
    ayar(True)
    pg.goto(PANEL + "?yeni=1"); pg.reload()
    pg.wait_for_selector("#lockCard", timeout=20000)
    #  bu hesabin HEC VAXT abunesi olmayib -> «sinaq bitib» demek yalan olardi
    ok("Hesab aktiv deyil" in pg.inner_text("#band") and pg.locator("#lockCard").get_attribute("data-kind") == "yox",
       "heç vaxt abunəsi olmayana: «Hesab aktiv deyil»", pg.inner_text("#band").replace("\n", " ")[:60])
    lc = pg.inner_text("#lockCard").replace("\n", " ")
    ok("silinməyib" in lc and "bizə yazın" in lc, "kart: məlumat silinməyib, bizə yazmaq deyilir", lc[:110])
    ok("sınaq" not in lc.lower(), "«sınaq» sözü yoxdur (sınağı olmayıb)")
    ok("pulsuz" not in lc.lower(), "«pulsuz» sözü yoxdur")
    ok("şagirdləriniz" in lc.lower() and "yeni tapşırıq və məşq" in lc, "şagirdlərə nə olduğu yazılıb (2-B)")
    href = pg.locator("#lockWa").get_attribute("href") or ""
    ok("wa.me/994501234567" in href, "WhatsApp düyməsi nömrəyə açılır", href[:60])
    ok(pg.evaluate("document.getElementById('bnav').innerHTML.trim() === '' || getComputedStyle(document.getElementById('bnav')).display === 'none'"),
       "alt naviqasiya (İcmal/Qruplar/Test yığ) yoxdur")
    ok(pg.locator("#groups, #yMenu").count() == 0, "qruplar / icmal menyusu yoxdur")
    pg.screenshot(path=OUT + "/1-bagli-masaustu.png")
    for h in ("#/gs", "#/g/" + GID, "#/a/" + GID, "#/r/" + GID, "#/gen", "#/me"):
        pg.goto(PANEL + "?yeni=1" + h); pg.wait_for_timeout(500)
        ok(pg.locator("#lockCard").count() == 1, "başqa ünvan da bağlıdır: " + h)
    ok(pg.locator("#btnOut:visible").count() == 1 or pg.locator("#btnOut").count() == 1, "«Çıxış» düyməsi qalır")

    print("\nC · Server: UI olmadan da yaratmaq olmur")
    try:
        db("""insert into public.homework (class_id, created_by, body, due)
              values (%s::uuid, %s::uuid, 'x', current_date)""", (GID, acc["o"]))
        ok(False, "bağlı hesabda ev tapşırığı yaranmamalı idi")
    except Exception as e:
        ok("müddəti bitib" in str(e), "bağlı hesabda ev tapşırığı yaranmır", str(e).strip().splitlines()[0][:70])

    print("\nD · Şagird (2-B): verilmiş test və nəticə qalır, məşq bağlıdır")
    sp = page(ctx, 390, 844)
    sp.goto(STUDENT); sp.wait_for_selector("#btnIn", timeout=15000)
    sp.fill("#code", "SAGBGL01"); sp.click("#btnIn")
    sp.wait_for_selector("#adBox", state="attached", timeout=20000); sp.wait_for_timeout(1500)
    body = sp.inner_text("body")
    ok(TEST["t"] in body, "verilmiş test şagirdin siyahısında görünür", TEST["t"][:40])
    ok("Məşq hazırda bağlıdır" in sp.inner_text("#adBox"), "«Mövzu məşqi» yerində «Məşq hazırda bağlıdır»", sp.inner_text("#adBox").replace("\n", " ")[:90])
    ok(sp.locator("#adBox .arow").count() == 0, "mövzu siyahısı açılmır")
    sp.screenshot(path=OUT + "/2-sagird-telefon.png", full_page=True)

    print("\nE · Müddət uzadılır — hər şey qayıdır")
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select %s::uuid, p.id, 'trialing', now() + interval '30 days' from public.plans p where p.slug = 'repetitor-25'""", (acc["i"],))
    pg.goto(PANEL + "?yeni=1"); pg.reload()
    pg.wait_for_selector("#adminMsg", state="attached", timeout=20000)
    ok(pg.locator("#lockCard").count() == 0, "uzadılandan sonra bağlı ekran yoxdur")
    sp.reload(); sp.wait_for_selector("#adBox", state="attached", timeout=20000); sp.wait_for_timeout(1500)
    ok("Məşq hazırda bağlıdır" not in sp.inner_text("#adBox"), "şagirdin məşqi geri açılıb")

    print("\nF · Güzəşt müddəti və sonrası")
    db("update public.subscriptions set current_period_end = now() - interval '1 day' where account_id = %s::uuid", (acc["i"],))
    pg.reload(); pg.wait_for_selector("#adminMsg", state="attached", timeout=20000)
    ok(pg.locator("#lockCard").count() == 0, "müddət 1 gün əvvəl bitib: güzəşt gününə düşür, hələ bağlı deyil")
    db("update public.subscriptions set current_period_end = now() - interval '10 days' where account_id = %s::uuid", (acc["i"],))
    pg.reload(); pg.wait_for_selector("#lockCard", timeout=20000)
    ok(pg.locator("#lockCard").get_attribute("data-kind") == "sinaq" and "Sınaq müddəti bitib" in pg.inner_text("#band"),
       "10 gün əvvəl bitən SINAQ: bağlıdır, «Sınaq müddəti bitib»", pg.inner_text("#band").replace("\n", " ")[:50])
    lc = pg.inner_text("#lockCard").replace("\n", " ")
    ok("müddəti birlikdə uzadaq" in lc and "abunə" not in lc.lower(), "sınaq mətni: «uzadaq», «abunə» sözü yoxdur", lc[:100])
    pg.screenshot(path=OUT + "/1b-bagli-sinaq.png")

    print("\nF2 · PULLU abunə bitib — «Abunə müddəti bitib»")
    db("update public.subscriptions set status = 'active' where account_id = %s::uuid", (acc["i"],))
    pg.reload(); pg.wait_for_selector("#lockCard", timeout=20000)
    ok(pg.locator("#lockCard").get_attribute("data-kind") == "abune" and "Abunə müddəti bitib" in pg.inner_text("#band"),
       "pullu abunə: başlıq «Abunə müddəti bitib»", pg.inner_text("#band").replace("\n", " ")[:50])
    lc = pg.inner_text("#lockCard").replace("\n", " ")
    ok("abunəni birlikdə yeniləyək" in lc and "sınaq" not in lc.lower(), "abunə mətni: «yeniləyək», «sınaq» sözü yoxdur", lc[:110])
    href = pg.locator("#lockWa").get_attribute("href") or ""
    ok("abun%C9%99mi%20yenil%C9%99m%C9%99k" in href or "yenil" in href.lower() or "abun" in href.lower(), "WhatsApp mesajı abunə yeniləməyi deyir", href[-80:])
    pg.screenshot(path=OUT + "/1c-bagli-abune.png")
    db("update public.subscriptions set status = 'trialing' where account_id = %s::uuid", (acc["i"],))

    print("\nG · Ayar söndürülür — köhnə davranış (təcili geri qaytarma)")
    ayar(False)
    pg.reload(); pg.wait_for_selector("#adminMsg", state="attached", timeout=20000)
    ok(pg.locator("#lockCard").count() == 0, "ayar sönəndə panel yenə açılır")

    print("\nH · Telefon (390 px) — bağlı ekran")
    ayar(True)
    ph = page(ctx, 390, 844)
    ph.goto(PANEL + "?yeni=1"); ph.wait_for_selector("#lockCard", timeout=20000)
    ok(ph.evaluate("document.documentElement.scrollWidth <= window.innerWidth"), "yana sürüşmə yoxdur")
    bb = ph.locator("#lockWa").bounding_box()
    ok(bb and bb["x"] >= 0 and bb["x"] + bb["width"] <= 390, "WhatsApp düyməsi ekranın içindədir", bb)
    ph.screenshot(path=OUT + "/3-bagli-telefon.png", full_page=True)
    ayar(False)
    br.close()

ayar(False)
print("\n" + ("HAMISI KECDI" if not fails else "XETA (%d): %s" % (len(fails), " | ".join(fails))))
raise SystemExit(1 if fails else 0)
