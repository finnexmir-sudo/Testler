#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""216: sehv defteri - movzu setri BOS oldugu hal.

Canlida cixdi: «17 sual gözləyir» yazirdi, movzu setri yox idi, mətn ise
«Mövzunu seç» deyirdi - olmayan bir seyi ved edirdi ve sagird ILISIB
qalirdi (hec bir duyme yox).

Iki hal yoxlanir:
  A  yeni server, movzu setri bos (suallar 'published' deyil)
  B  KOHNE server (tek parametrli imza) - PGRST202 -> geriye qayidis
"""
import time
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

STUDENT = "http://127.0.0.1:8010/sagird/index.html"
PANEL   = "http://127.0.0.1:8010/muellim/index.html"
CHROME  = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN     = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
BLOCK   = "**://*.supabase.co/**"
TEST_CFG = """window.CFG = {
  SUPABASE_URL: "http://127.0.0.1:54321",
  SUPABASE_ANON_KEY: "test-anon-key",
  STUDENT_URL: "http://127.0.0.1:8010/sagird/",
  PARENT_URL:  "http://127.0.0.1:8010/valideyn/",
  SHOW_PLANS: false
};"""

fails = []
def ok(cond, label, extra=""):
    print(("  OK   " if cond else "  FAIL ") + label + (("  " + str(extra)) if extra else ""), flush=True)
    if not cond: fails.append(label)

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args) if args else cur.execute(sql)
        if cur.description:
            return cur.fetchone() if one else cur.fetchall()

db("""
delete from public.daily_packs;  delete from public.mistakes;
delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments;  delete from public.student_sessions;
delete from public.parent_sessions; delete from public.students;
delete from public.classes;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator'; delete from public.subscriptions;
delete from public.account_members; delete from public.accounts; delete from public.user_roles;
delete from public.profiles; delete from auth.users;""")

EMAIL = "defbos%d@t.az" % int(time.time())

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

    pg.goto(PANEL); pg.wait_for_selector("#btnAuth", timeout=15000)
    pg.click("#btnSwap")
    pg.fill("#fname", "Boş Müəllim"); pg.fill("#email", EMAIL)
    pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=15000)
    pg.select_option("#atype", "tutor"); pg.fill("#aname", "Boş hesabı"); pg.click("#btnSetup")
    pg.wait_for_selector("#btnGroup", timeout=15000)
    pg.fill("#gname", "3-cü sinif"); pg.select_option("#glevel", "3"); pg.click("#btnGroup")
    pg.wait_for_selector("#groups .gcard", timeout=15000)
    pg.click("#groups .gcard"); pg.wait_for_selector("#gTabs", timeout=15000)
    try: pg.wait_for_selector("#sname", state="visible", timeout=3000)
    except Exception: pg.click("#btnStuOpen")
    pg.fill("#sname", "Boş Şagird"); pg.click("#btnStu"); pg.wait_for_selector(".stu", timeout=15000)
    AID  = db("select id::text i from public.accounts limit 1", one=True)["i"]
    SID  = db("select id::text i from public.students limit 1", one=True)["i"]
    CODE = db("select login_code c from public.students limit 1", one=True)["c"]
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select %s, p.id, 'active', now() + interval '30 days'
            from public.plans p where p.slug='repetitor-25'""", (AID,))

    print("A · Mövzu sətri boş: mətn «Mövzunu seç» DEMƏMƏLİDİR")
    #  Defterde 4 sehv, amma suallarin hamisi 'draft' - topics bos qalir
    db("""insert into public.mistakes (student_id, question_id, status, next_at)
          select %s, q.id, 'open', now() - interval '1 hour'
            from (select id from public.questions
                   where status = 'published' and kind = 'single' limit 4) q""", (SID,))
    db("""update public.questions set status = 'draft'
           where id in (select question_id from public.mistakes)""")
    sp = page(ctx, 390, 844)
    sp.goto(STUDENT); sp.wait_for_selector("#btnIn", timeout=15000)
    sp.fill("#code", CODE); sp.click("#btnIn")
    sp.wait_for_selector("#mistBox .mist", timeout=15000); sp.wait_for_timeout(300)
    mt = sp.inner_text("#mistBox").replace("\n", " ")
    ok(sp.locator("#mistBox .mtop").count() == 0, "movzu setri dogrudan bosdur")
    ok("Mövzunu seç" not in mt, "«Mövzunu seç» YAZILMIR (ziddiyyet yoxdur)", mt[:90])
    ok("4 sual gözləyir" in mt, "sayğac duzdur", mt[:60])
    ok(sp.locator("#mistBox [data-mt]").count() == 1,
       "sagird ilisib qalmir - umumi «sual işlə» duymesi var")
    db("update public.questions set status = 'published' where status = 'draft'")

    print("B · Köhnə server (tək parametrli imza) — geriyə qayıdış")
    #  210-un yeni imzasini silib 129-un imzasini qaytaririq
    db("drop function if exists public.rpc_student_mistakes(text, uuid, int)")
    db("""create or replace function public.rpc_student_mistakes(p_token text)
          returns jsonb language plpgsql stable security definer
          set search_path = public, extensions, pg_temp as $f$
          declare v_st uuid := app.session_student(p_token);
          begin
            if v_st is null then
              raise exception 'Sessiya bitib.' using errcode = '28000';
            end if;
            return jsonb_build_object(
              'open',   (select count(*) from public.mistakes where student_id = v_st and status = 'open'),
              'review', 0, 'closed', 0,
              'due',    (select count(*) from public.mistakes
                          where student_id = v_st and status <> 'closed' and next_at <= now()),
              'items', coalesce((
                select jsonb_agg(jsonb_build_object(
                         'qid', q.id, 'body', q.body, 'kind', q.kind, 'topic', null,
                         'status', m.status, 'wrong_n', m.wrong_n,
                         'options', coalesce((
                           select jsonb_agg(jsonb_build_object('id', o.id, 'body', o.body) order by o.ord)
                             from public.question_options o where o.question_id = q.id), '[]'::jsonb)))
                  from public.mistakes m
                  join public.questions q on q.id = m.question_id and q.status = 'published'
                 where m.student_id = v_st and m.status <> 'closed' and m.next_at <= now()), '[]'::jsonb));
          end $f$""")
    db("grant execute on function public.rpc_student_mistakes(text) to anon, authenticated")
    sp.reload(); sp.wait_for_selector("#mistBox .mist", timeout=15000); sp.wait_for_timeout(300)
    ok(sp.locator("#mistBox [data-mt]").count() == 1, "kohne serverde de duyme var")
    sp.locator("#mistBox [data-mt]").first.click()
    sp.wait_for_selector(".opt", timeout=15000)
    ok(sp.locator(".opt").count() >= 2, "kohne serverde mesq ACILIR (geriye qayidis)",
       sp.locator(".opt").count())
    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails)); [print("  - " + f) for f in fails]; raise SystemExit(1)
print("HAMISI KECDI")
