#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Qrupun heftelik cedveli (db/177) - ekran terefi.

Uc iddia:
  1. ISTEYE BAGLI - cedvel qurulmayibsa Icmalda kart YOXDUR ve
     valideyn ekraninda «Bu həftə» bolmesi CIXMIR.  Bos kart
     istifadecini yaniltir («demeli ders yoxdur?»).
  2. Qurulandan sonra Icmalda «bu gün dərs var» cixir ve oradan
     BIR TOXUNUSLA davamiyyet ekranina kecilir.
  3. Legv edilen ders siyahidan ITMIR - ustunden xett cekilir.
"""
import sys, datetime
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

PANEL  = "http://127.0.0.1:8010/muellim/index.html"
BASE   = "http://127.0.0.1:8010"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN    = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
BLOCK  = "**://*.supabase.co/**"
TEST_CFG = """window.CFG = {
  SUPABASE_URL: "http://127.0.0.1:54321",
  SUPABASE_ANON_KEY: "test-anon-key",
  STUDENT_URL: "https://example.test/",
  CONTACT_WHATSAPP: "+994501234567",
  SHOW_PLANS: false
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
delete from public.lesson_changes; delete from public.class_schedule;
delete from public.attendance;     delete from public.lessons;
delete from public.parent_sessions;delete from public.students;
delete from public.classes;        delete from public.subscriptions;
delete from public.account_members;delete from public.accounts;
delete from public.user_roles;     delete from auth.users;
""")
#  BAKI gunu - server bununla isleyir
baki = db("select (now() at time zone 'Asia/Baku')::date d,"
          " extract(isodow from (now() at time zone 'Asia/Baku'))::int w", one=True)
BUGUN, ISODOW = baki["d"], baki["w"]

with sync_playwright() as pw:
    br  = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 430, "height": 900})
    pg  = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=TEST_CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))

    print("A · Hesab və qrup")
    pg.goto(PANEL); pg.wait_for_timeout(400)
    pg.click("#btnSwap"); pg.fill("#fname", "Cedvel M"); pg.fill("#email", "cd@t.az")
    pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=15000)
    pg.select_option("#atype", "tutor"); pg.fill("#aname", "Cedvel hesabi")
    pg.click("#btnSetup"); pg.wait_for_selector("#gForm", timeout=20000)
    pg.fill("#gname", "9-A qrupu"); pg.click("#btnGroup")
    pg.wait_for_selector(".gcard", timeout=20000)
    acc = db("select a.id, a.owner_id from public.accounts a join auth.users u"
             " on u.id = a.owner_id where u.email = 'cd@t.az'", one=True)
    cls = db("select id from public.classes where account_id = %s", (acc["id"],), one=True)["id"]
    db("insert into public.students (account_id, class_id, created_by, full_name,"
       " display_name, login_code, parent_code) values"
       " (%s,%s,%s,'Ayan Qasımova','Ayan Q.','SHVCE001','VLDCE001')",
       (acc["id"], cls, acc["owner_id"]))

    print("B · Cədvəl qurulmayıb — heç yerdə görünmür")
    pg.goto(PANEL + "#/"); pg.reload()
    pg.wait_for_selector(".gcard", timeout=20000); pg.wait_for_timeout(1200)
    ok(pg.inner_html("#hWeek").strip() == "", "Icmalda cedvel karti YOXDUR",
       pg.inner_html("#hWeek")[:60])
    p2 = ctx.new_page()
    p2.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=TEST_CFG))
    p2.goto(BASE + "/valideyn/?kod=VLDCE001")
    p2.wait_for_selector(".card.sum", timeout=20000); p2.wait_for_timeout(900)
    ok("Bu həftə" not in p2.inner_text("#main"), "valideynde «Bu həftə» bolmesi YOXDUR")

    print("C · Cədvəl qurulur")
    pg.goto(PANEL + "#/g/" + str(cls)); pg.wait_for_selector("#gTabs", timeout=20000)
    pg.locator("#gTabs [data-v='d']").click()
    pg.wait_for_selector("#schFold", timeout=20000)
    ok("qurulmayıb" in pg.inner_text("#schFold"), "yigilmis setir «qurulmayıb» yazir")
    pg.eval_on_selector("#schFold", "e => e.open = true"); pg.wait_for_timeout(300)
    pg.locator("#schDays [data-w='%d']" % ISODOW).click(); pg.wait_for_timeout(300)
    pg.select_option("#schTimes [data-t='%d']" % ISODOW, "16:00")
    pg.click("#schSave"); pg.wait_for_timeout(1800)
    ok("yadda saxlanıldı" in pg.inner_text("#schWarn"), "tesdiq gorunur",
       pg.inner_text("#schWarn")[:60])
    ok("16:00" in pg.inner_text("#schFold"), "yigilmis setirde saat yazir")

    print("D · İcmalda «bu gün dərs var»")
    pg.goto(PANEL + "#/"); pg.reload()
    pg.wait_for_selector("#hWeek .wk", timeout=20000); pg.wait_for_timeout(800)
    wk = pg.inner_text("#hWeek").replace("\n", " ")
    ok("Bu gün dərs var" in wk, "kart bugunu deyir", wk[:70])
    ok("16:00" in wk and "9-A" in wk, "saat ve qrup yazilir", wk[:70])
    #  bir toxunusla davamiyyet
    pg.locator("#hWeek [data-wk]").click()
    pg.wait_for_selector("#ledgerBox", timeout=20000); pg.wait_for_timeout(800)
    ok("Bu gün" in pg.inner_text("#ledgerBox"), "kartdan defter ekranina kecir")

    print("E · Ləğv edilən dərs siyahıda qalır")
    db("insert into public.lesson_changes (class_id, on_date) values (%s,%s)", (cls, BUGUN))
    pg.goto(PANEL + "#/"); pg.reload()
    pg.wait_for_selector("#hWeek .wk", timeout=20000); pg.wait_for_timeout(800)
    wk = pg.inner_text("#hWeek").replace("\n", " ")
    ok("ləğv edilib" in wk, "legv edilen ders ITMIR, ustunden xett cekilir", wk[:80])
    ok(pg.locator("#hWeek .wkr.off").count() == 1, "xett cekilmis setir var")
    p2.reload(); p2.wait_for_selector(".card.sum", timeout=20000); p2.wait_for_timeout(900)
    ok("ləğv edilib" in p2.inner_text("#main"),
       "valideyn de legvi gorur - onun ucun en vacib xeberdir")

    print("F · Cədvəl silinəndə hər şey gizlənir")
    db("delete from public.class_schedule where class_id = %s", (cls,))
    pg.goto(PANEL + "#/"); pg.reload()
    pg.wait_for_selector(".gcard", timeout=20000); pg.wait_for_timeout(1200)
    ok(pg.inner_html("#hWeek").strip() == "", "Icmalda kart yeniden gizlenir")
    p2.reload(); p2.wait_for_selector(".card.sum", timeout=20000); p2.wait_for_timeout(900)
    ok("Bu həftə" not in p2.inner_text("#main"), "valideynde bolme yeniden gizlenir")

    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails))
    for f in fails: print("  - " + f)
    sys.exit(1)
print("CEDVEL: BUTUN YOXLAMALAR KECDI")
