#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Bildiris axini + admin duzelis + 2FA: ucdan-uca.

Muellim veraqde oz sualini bildirir; platforma sualina bildiris
fixture ile dusur; admin kartlari gorur, platforma sualini yerinde
duzeldir (bildirisler avtomatik baglanir), oz sualini "Baxildi" edir;
sonra 2FA qurur - kilid ekrani, yanlis/duzgun kod, ehtiyat kodlar.
"""
import re, sys
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

PANEL  = "http://127.0.0.1:8010/muellim/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN    = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
BLOCK  = "**://*.supabase.co/**"
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
delete from public.question_reports;
delete from public.admin_totp; delete from public.admin_unlocks;
delete from public.admin_code_attempts; delete from public.admin_backup_codes;
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
    ctx = br.new_context(viewport={"width": 1280, "height": 900})

    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=TEST_CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))
    pg.on("dialog", lambda d: d.accept())

    pg.goto(PANEL); pg.wait_for_timeout(400)
    pg.click("#btnSwap")
    pg.fill("#fname", "Bildiris Muellim"); pg.fill("#email", "bld@t.az")
    pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=8000)
    pg.select_option("#atype", "tutor")
    pg.fill("#aname", "Bildiris hesabi"); pg.click("#btnSetup")
    pg.wait_for_selector("#gForm", timeout=8000)
    UID = db("select id::text i from auth.users where email='bld@t.az'", one=True)["i"]
    AID = db("select id::text i from public.accounts", one=True)["i"]

    # oz suallari - generator "mine" hovuzu ucun
    db("""
    do $$
    declare v_s uuid; v_l uuid; v_t uuid; i int; v_q uuid;
    begin
      select id into v_s from public.subjects where slug='riyaziyyat';
      select l.id into v_l from public.levels l
        join public.programs p on p.id=l.program_id
       where p.slug='ibtidai' and l.code='4';
      select id into v_t from public.topics
       where slug='riy-4-vurma-bolme' and subject_id=v_s;
      for i in 1..6 loop
        insert into public.questions
          (owner_type, owner_id, account_id, subject_id, level_id, topic_id,
           kind, body, difficulty, status)
        values ('educator', %(uid)s, %(aid)s, v_s, v_l, v_t, 'single',
                'Bildiris numune sual nomre ' || i, 2, 'published')
        returning id into v_q;
        insert into public.question_options (question_id, ord, body, is_correct)
        values (v_q, 1, 'duz ' || i, true), (v_q, 2, 'sehv ' || i, false);
      end loop;
    end $$;
    """, {"uid": UID, "aid": AID})

    print("A · Müəllim vərəqdən səhv bildirir")
    pg.goto(PANEL + "#/gen"); pg.reload()
    pg.wait_for_selector("#gPool", timeout=8000)
    pg.wait_for_function(
        "document.querySelector('#gPrev') && "
        "document.querySelector('#gPrev').innerText.indexOf('yoxlanılır') < 0",
        timeout=8000)
    pg.fill("#gCnt", "5"); pg.wait_for_timeout(700)
    pg.fill("#gTitle", "Bildiris testi")
    pg.click("#btnMake")
    pg.wait_for_selector(".paper", timeout=8000)
    ok(pg.locator(".pq .rlink").count() == 5, "her sualda bildir duymesi var",
       pg.locator(".pq .rlink").count())
    pg.locator(".pq .rlink").first.click()
    pg.wait_for_selector(".rfrm", timeout=4000)
    pg.select_option(".rfrm .rsel", "yazi")
    pg.fill(".rfrm .rnote", "Vergul catismir")
    pg.locator("[data-rsend]").first.click()
    pg.wait_for_selector(".rok", timeout=6000)
    ok("Bildirildi" in pg.inner_text(".rok"), "bildiris gonderildi")
    r = db("select reason, note from public.question_reports", one=True)
    ok(r and r["reason"] == "yazi" and "Vergul" in r["note"],
       "sebeb ve qeyd bazaya dusdu")

    # platforma sualina bildiris - fixture (sagird axini e2e_student-dedir)
    db("""
    insert into public.question_reports (question_id, account_id, reason, note)
    select q.id, %(aid)s, 'cavab', 'Duz cavab B olmalidir'
      from public.questions q
     where q.owner_type='platform' and q.status='published'
     order by q.created_at limit 1
    """, {"aid": AID})

    print("B · Admin bildiriş kartlarını görür")
    db("insert into public.user_roles (user_id, role) values (%s,'admin') on conflict do nothing",
       (UID,))
    pg.goto(PANEL + "#/adm"); pg.reload()
    pg.wait_for_selector(".repc", timeout=8000)
    ok(pg.locator(".repc").count() == 2, "iki bildiris karti", pg.locator(".repc").count())
    ok(pg.locator(".repc .popt.ok").count() >= 2, "duz cavablar isarelenib")
    ok("müəllimin öz sualı" in pg.inner_text("#repList"), "oz sual ayrica isarelenir")
    plat = pg.locator(".repc", has_text="platforma").first
    ok(plat.locator("[data-fix]").count() == 1, "platforma sualina Duzelt var")
    own = pg.locator(".repc", has_text="müəllimin öz sualı").first
    ok(own.locator("[data-fix]").count() == 0, "oz suala Duzelt yoxdur")

    print("C · Yerində düzəliş")
    plat.locator("[data-fix]").click()
    pg.wait_for_selector(".ffrm", timeout=4000)
    pg.fill(".ffrm .fbody", "Duzeldilmis platforma sual metni")
    pg.locator(".ffrm [data-save]").click()
    pg.wait_for_selector("#admMsg .ok", timeout=8000)
    ok("düzəldildi" in pg.inner_text("#admMsg"), "netice mesaji")
    b = db("select body from public.questions where body='Duzeldilmis platforma sual metni'",
           one=True)
    ok(bool(b), "sual bazada duzeldi")
    nq = db("select count(*) n from public.question_reports where status='new'", one=True)["n"]
    ok(nq == 1, "platforma bildirisi avtomatik baglandi", nq)

    print("D · Öz suala «Baxıldı»")
    pg.wait_for_selector(".repc", timeout=8000)
    pg.locator(".repc [data-cls]").first.click()
    pg.wait_for_timeout(900)
    nq = db("select count(*) n from public.question_reports where status='new'", one=True)["n"]
    ok(nq == 0, "butun bildirisler baglandi", nq)
    pg.wait_for_selector("#repF", timeout=8000)
    pg.locator("#repF .chip", has_text="Düzəldilib").click()
    pg.wait_for_timeout(700)
    ok(pg.locator("#repList .repc").count() == 2, "baglanmis siyahida gorunur",
       pg.locator("#repList .repc").count())

    print("E · 2FA qurulur")
    pg.click("#btn2On")
    pg.wait_for_selector(".s2setup", timeout=8000)
    key = pg.inner_text(".s2key").strip()
    ok(len(key) == 32, "acar gosterilir", key[:8] + "…")
    ok(pg.locator(".s2bkp code").count() == 4, "4 ehtiyat kod verilir")
    bkp = pg.locator(".s2bkp code").first.inner_text().strip()
    code = db("select app.totp_at(secret, now()) c from public.admin_totp "
              "where user_id=%s", (UID,), one=True)["c"]
    pg.fill("#s2New", code)
    pg.click("#btn2Ok")
    pg.wait_for_selector("#admMsg .ok", timeout=8000)
    ok("aktivləşdi" in pg.inner_text("#admMsg"), "2FA aktivlesdi")

    print("F · Kilid ekranı: yanlış kod keçmir, düzgün keçir")
    db("delete from public.admin_unlocks")
    pg.goto(PANEL + "#/adm"); pg.reload()
    pg.wait_for_selector("#ulCode", timeout=8000)
    ok(True, "kilid ekrani cixir")
    pg.fill("#ulCode", "000000"); pg.click("#btnUl")
    pg.wait_for_selector("#ulMsg .err", timeout=6000)
    ok("düzgün deyil" in pg.inner_text("#ulMsg"), "yanlis kod acmir")
    code = db("select app.totp_at(secret, now()) c from public.admin_totp "
              "where user_id=%s", (UID,), one=True)["c"]
    pg.fill("#ulCode", code); pg.click("#btnUl")
    pg.wait_for_selector(".tiles", timeout=8000)
    ok(True, "duzgun kod paneli acir")

    print("G · Ehtiyat kod da açır, bir dəfə işləyir")
    db("delete from public.admin_unlocks; delete from public.admin_code_attempts")
    pg.goto(PANEL + "#/adm"); pg.reload()
    pg.wait_for_selector("#ulCode", timeout=8000)
    pg.fill("#ulCode", bkp); pg.click("#btnUl")
    pg.wait_for_selector(".tiles", timeout=8000)
    ok(True, "ehtiyat kod paneli acir")
    db("delete from public.admin_unlocks")
    pg.goto(PANEL + "#/adm"); pg.reload()
    pg.wait_for_selector("#ulCode", timeout=8000)
    pg.fill("#ulCode", bkp); pg.click("#btnUl")
    pg.wait_for_selector("#ulMsg .err", timeout=6000)
    ok("düzgün deyil" in pg.inner_text("#ulMsg"), "yanmis ehtiyat kod tekrar islemir")

    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails))
    for f in fails: print("  - " + f)
    sys.exit(1)
print("BILDIRIS: BUTUN YOXLAMALAR KECDI")
