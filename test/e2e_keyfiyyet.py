#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sual keyfiyyeti tehlili - ucdan-uca (db/134, yol xeritesi 22.g).

25 sagirdin cehdleri: bir platforma suali "acar subheli" (distraktor
duzden cox, gucluler sehv), biri normal (olu variant); admin ekraninda
kartlar, suzgec, Baxildi, yerinde duzelis; muellim oz sualinin
statistikasini redaktorda gorur."""
import time
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

PANEL   = "http://127.0.0.1:8010/muellim/index.html"
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

db("""
delete from public.question_stats; delete from public.practice; delete from public.mistakes;
delete from public.feedback; delete from public.question_reports; delete from public.parent_sessions;
delete from public.admin_totp; delete from public.admin_unlocks; delete from public.admin_code_attempts; delete from public.admin_backup_codes;
delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers; delete from public.attempts; delete from public.assignments;
delete from public.student_sessions; delete from public.students; delete from public.classes;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.question_options o using public.questions q where o.question_id = q.id and q.owner_type = 'educator';
delete from public.questions where owner_type = 'educator'; delete from public.subscriptions;
delete from public.account_members; delete from public.accounts; delete from public.user_roles;
delete from public.profiles; delete from auth.users;""")

EMAIL = "keyf%d@t.az" % int(time.time())

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

    print("A · Hazırlıq: müəllim, qrup, 25 şagirdin cəhdləri (bazadan)")
    pg.goto(PANEL); pg.wait_for_selector("#btnAuth", timeout=15000)
    pg.click("#btnSwap")
    pg.fill("#fname", "Keyfiyyət Admin"); pg.fill("#email", EMAIL)
    pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=15000)
    pg.select_option("#atype", "tutor"); pg.fill("#aname", "KF hesabı"); pg.click("#btnSetup")
    pg.wait_for_selector("#btnGroup", timeout=15000)
    pg.fill("#gname", "3-cü sinif"); pg.select_option("#glevel", "3"); pg.click("#btnGroup")
    pg.wait_for_selector("#groups .item", timeout=15000)
    UID = db("select id::text i from auth.users limit 1", one=True)["i"]
    AID = db("select id::text i from public.accounts limit 1", one=True)["i"]
    GID = db("select id::text i from public.classes limit 1", one=True)["i"]
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select %s, p.id, 'active', now() + interval '30 days' from public.plans p where p.slug='repetitor-25'""", (AID,))
    db("""insert into public.students (account_id, class_id, created_by, full_name, display_name, login_code)
          select %s, %s, %s, 'Sagird ' || i, 'S' || i || '.', 'KFST' || lpad(i::text, 4, '0') from generate_series(1, 25) i""", (AID, GID, UID))
    db("""
    create or replace function pg_temp.opt(p_q uuid, p_ok boolean) returns uuid language sql as $$
      select o.id from public.question_options o where o.question_id = p_q and o.is_correct = p_ok order by o.ord limit 1 $$;
    do $$
    declare q1 uuid; q2 uuid; q3 uuid; t1 uuid; st record; att uuid; ok boolean; sel uuid; pc numeric;
    begin
      select t.id into t1 from public.tests t where t.slug = 'riy-3-vurma-1';
      select tq.question_id into q1 from public.test_questions tq where tq.test_id = t1 order by tq.ord limit 1;
      select tq.question_id into q2 from public.test_questions tq where tq.test_id = t1 order by tq.ord offset 1 limit 1;
      insert into public.questions (owner_type, owner_id, account_id, subject_id, kind, body, status, created_by)
      values ('educator', %(uid)s, %(aid)s, (select id from public.subjects where slug = 'riyaziyyat'), 'single',
              'Öz sual: 5 + 5 neçə edər?', 'published', %(uid)s) returning id into q3;
      insert into public.question_options (question_id, ord, body, is_correct) values (q3, 1, '10', true), (q3, 2, '11', false);
      for st in select s.id, row_number() over (order by s.login_code) rn from public.students s loop
        pc := case when st.rn <= 15 then 80 + st.rn else 30 + st.rn end;
        insert into public.attempts (student_id, test_id, class_id, status, finished_at, score, max_score, percent)
        values (st.id, t1, %(gid)s, 'submitted', now(), pc, 100, pc) returning id into att;
        ok := st.rn in (16, 17, 18, 19);
        sel := case when ok then pg_temp.opt(q1, true) else pg_temp.opt(q1, false) end;
        insert into public.attempt_answers (attempt_id, question_id, selected_option_ids, is_correct, points)
        values (att, q1, array[sel], ok, case when ok then 1 else 0 end);
        ok := st.rn <= 18;
        sel := case when ok then pg_temp.opt(q2, true) else pg_temp.opt(q2, false) end;
        insert into public.attempt_answers (attempt_id, question_id, selected_option_ids, is_correct, points)
        values (att, q2, array[sel], ok, case when ok then 1 else 0 end);
        --  oz sual: 9 guclu duz, 3 zeif sehv -> musbet ayirdetme
        if st.rn <= 9 or st.rn between 20 and 22 then
          ok := st.rn <= 9;
          sel := case when ok then pg_temp.opt(q3, true) else pg_temp.opt(q3, false) end;
          insert into public.attempt_answers (attempt_id, question_id, selected_option_ids, is_correct, points)
          values (att, q3, array[sel], ok, case when ok then 1 else 0 end);
        end if;
      end loop;
    end $$;""", {"uid": UID, "aid": AID, "gid": GID})
    Q1 = db("select tq.question_id::text i from public.test_questions tq join public.tests t on t.id=tq.test_id where t.slug='riy-3-vurma-1' order by tq.ord limit 1", one=True)["i"]
    Q3 = db("select id::text i from public.questions where owner_type='educator'", one=True)["i"]
    db("insert into public.user_roles (user_id, role) values (%s,'admin') on conflict do nothing", (UID,))

    print("B · Admin: keyfiyyət kartları, süzgəc, Baxıldı")
    pg.goto(PANEL + "#/adm"); pg.reload(); pg.wait_for_selector(".qsc", timeout=15000)
    ok(pg.locator(".qsc").count() == 2, "iki siqnalli sual", pg.locator(".qsc").count())
    first = pg.locator(".qsc").first
    ok(first.get_attribute("data-q") == Q1, "acar subheli sual birinci")
    ft = first.inner_text()
    ok("açar şübhəli" in ft and "mənfi ayırdetmə" in ft and "çox çətin" in ft, "siqnal nisanlari", ft[:120].replace("\n", " "))
    ok("16% düz" in ft and "ayırdetmə -" in ft, "faiz ve ayirdetme", ft[:160].replace("\n", " "))
    ok(first.locator(".qso").count() >= 3 and first.locator(".qso.ok .qsn").inner_text().strip() == "16%", "variant zolaqlari, duz variant 16%")
    ok("Cəhdlərdən hesablanır: 2 sual" in pg.inner_text("#qsInfo"), "izah setri", pg.inner_text("#qsInfo")[:60])
    ok("Hamısı · 2" in pg.inner_text("#qsF") and "açar şübhəli · 1" in pg.inner_text("#qsF"), "cip sayğaclari")
    pg.click("#qsF [data-qf='acar']"); pg.wait_for_timeout(600)
    ok(pg.locator(".qsc").count() == 1, "acar suzgeci: 1")
    pg.click("#qsF [data-qf='olu']"); pg.wait_for_timeout(600)
    ok(pg.locator(".qsc").count() == 2, "olu suzgeci: 2 (her ikisinde secilmeyen variant)")
    pg.locator(".qsc").nth(1).locator("[data-qhide]").click(); pg.wait_for_timeout(800)
    ok(pg.locator(".qsc").count() == 1, "Baxildi - siyahidan cixdi")
    pg.click("#qsF [data-qf='hidden']"); pg.wait_for_timeout(600)
    ok(pg.locator(".qsc").count() == 1 and pg.locator(".qsc [data-qshow]").count() == 1, "baxilanlar siyahisi, Geri qaytar")
    pg.locator(".qsc [data-qshow]").click(); pg.wait_for_timeout(800)
    ok(pg.locator(".qsc").count() == 0, "geri qaytarildi - baxilanlar bos")
    pg.click("#qsF [data-qf='']"); pg.wait_for_timeout(600)
    ok(pg.locator(".qsc").count() == 2, "Hamisi yene 2")
    pg.click("#qsRefresh"); pg.wait_for_timeout(1200)
    ok(pg.locator(".qsc").count() == 2, "Yenile - siyahi qalir")

    print("C · Yerində düzəliş: açar dəyişir, sual siyahıdan çıxır")
    pg.locator(".qsc").first.locator("[data-qfix]").click(); pg.wait_for_selector("#qs-" + Q1 + " .ffrm", timeout=4000)
    frm = pg.locator("#qs-" + Q1 + " .ffrm")
    frm.locator("input[type='radio']").nth(1).check()
    frm.locator("[data-save]").click()
    pg.wait_for_selector("#admMsg .ok", timeout=15000)
    ok("keyfiyyət siyahısından çıxarıldı" in pg.inner_text("#admMsg"), "netice mesaji")
    pg.wait_for_selector(".qsc", timeout=15000)
    ok(pg.locator(".qsc").count() == 1 and pg.locator(".qsc").first.get_attribute("data-q") != Q1, "duzeldilen sual siyahidan cixdi")
    ok(db("select count(*) n from public.question_options where question_id=%s and is_correct", (Q1,), one=True)["n"] == 1, "acar bazada bir dene")

    print("D · Müəllim öz sualının statistikasını görür")
    pg.goto(PANEL + "#/q/" + Q3); pg.reload(); pg.wait_for_selector("#qbody", timeout=15000)
    ok(pg.locator(".qstat").count() == 1, "statistika setri var")
    qt = pg.locator(".qstat").inner_text() if pg.locator(".qstat").count() else ""
    ok("12 cavab" in qt and "75% düz" in qt and "ayırdetmə +" in qt, "12 cavab, 75% duz, musbet ayirdetme", qt)

    br.close()

print()
if fails:
    print("XETA:", len(fails)); [print("  -", f) for f in fails]; raise SystemExit(1)
print("hamisi kecdi")
