#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""«Bu gunun dersi» karti - ucdan-uca (db/126_bu_gunun_dersi.sql).

Qrup ekraninda dersden evvel bir kart: plansiz/tapsiriqsiz sakit hal;
tapsiriq verilir -> etmeyenler adbaad; sagird yazir -> siyahidan cixir;
plan qurulur -> novbeti movzu; "kecildi" -> son kecilen + test duymesi;
duyme generatoru hemin fesil secili acir."""
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
delete from public.feedback; delete from public.question_reports; delete from public.parent_sessions;
delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers; delete from public.attempts; delete from public.assignments;
delete from public.student_sessions; delete from public.students; delete from public.classes;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator'; delete from public.subscriptions;
delete from public.account_members; delete from public.accounts; delete from public.user_roles;
delete from public.profiles; delete from auth.users;""")

EMAIL = "bugun%d@t.az" % int(time.time())

def page(ctx, w, h):
    pg = ctx.new_page(); pg.set_viewport_size({"width": w, "height": h})
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=TEST_CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))
    return pg

def prep(pg):
    #  CSS basliqlari boyuk herfe cevirir (innerText) - textContent oxunur
    pg.wait_for_selector("#prep .prep", timeout=15000)
    return " ".join(pg.locator("#prep .prep").evaluate("el => el.textContent").split())

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context()
    pg = page(ctx, 430, 1000)

    print("A · Hazırlıq: müəllim, 3-cü sinif qrupu, 2 şagird")
    pg.goto(PANEL); pg.wait_for_selector("#btnAuth", timeout=15000)
    pg.click("#btnSwap")
    pg.fill("#fname", "Bugün Müəllim"); pg.fill("#email", EMAIL)
    pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=15000)
    pg.select_option("#atype", "tutor"); pg.fill("#aname", "Bugün hesabı"); pg.click("#btnSetup")
    pg.wait_for_selector("#btnGroup", timeout=15000)
    pg.fill("#gname", "3-cü sinif"); pg.select_option("#glevel", "3"); pg.click("#btnGroup")
    pg.wait_for_selector("#groups .item", timeout=15000)
    pg.click("#groups .item"); pg.wait_for_selector("#gTabs", timeout=15000)
    for nm in ("Ayan Bir", "Murad İki"):
        try: pg.wait_for_selector("#sname", state="visible", timeout=3000)
        except Exception: pg.click("#btnStuOpen")
        pg.fill("#sname", nm); pg.click("#btnStu"); pg.wait_for_timeout(600)
    pg.wait_for_function("document.querySelectorAll('.stu').length >= 2", timeout=15000)
    GID = db("select id::text i from public.classes limit 1", one=True)["i"]
    AID = db("select id::text i from public.accounts limit 1", one=True)["i"]
    CODE1 = db("select login_code c from public.students where full_name='Ayan Bir'", one=True)["c"]

    print("B · Plansız, tapşırıqsız: sakit kart")
    t = prep(pg)
    ok("Bu günün dərsi" in t, "kart basligi")
    ok("Dərs planı yoxdur" in t and pg.locator("#prepPlan").count() == 1, "plan yoxdur + «Planı qur» linki")
    ok("Açıq tapşırıq yoxdur" in t, "acıq tapsiriq yoxdur")
    ok(pg.locator("#prepGen").count() == 0 and pg.locator("#prepAsg").count() == 1, "yalniz «Tapşırıq ver» duymesi")

    print("C · Tapşırıq verilir → etməyənlər adbaad")
    pg.click("#prepAsg"); pg.wait_for_selector("#aList", timeout=15000)
    pg.wait_for_function("document.querySelectorAll('#aTest option').length > 0", timeout=15000)
    opts = pg.locator("#aTest option").all_inner_texts()
    lbl = next(o for o in opts if "Vurma cədvəli" in o)
    pg.click("#aList [data-t='" + pg.evaluate("l => Array.from(document.querySelectorAll('#aTest option')).filter(o => o.textContent === l)[0].value", lbl) + "']"); pg.click("#btnAsg")
    pg.wait_for_selector(".asg", timeout=15000)
    #  tapsiriqdan sonra hazir WhatsApp metni
    pg.wait_for_selector("#asgFlash", timeout=8000)
    fl = pg.inner_text("#asgFlash")
    ok("Tapşırıq verildi" in fl and "Vurma cədvəli" in fl, "tapsiriqdan sonra netice qutusu", fl[:80])
    href = pg.locator("#asgFlash a[href^='https://wa.me/']").get_attribute("href") or ""
    ok("wa.me" in href and "Vurma" in __import__("urllib.parse").parse.unquote(href) and "Tap%C5%9F%C4%B1r%C4%B1qlar" in href,
       "WhatsApp linki test adi ve 'Tapşırıqlar' ile", href[:60])
    ok("Kodunla gir" in pg.locator("#asgFlash .watxt").input_value(), "metn qutuda kopyalanmaga hazir")
    pg.click("#btnBack"); t = prep(pg)
    ok("Etməyənlər" in t and "Ayan" in t and "Murad" in t and "Ayan Bir" not in t, "iki sagird etmeyib - yalniz ad", t[-120:])
    ok("2/2 şagird" in t, "2/2 sagird")

    print("D · Ayan yazır → siyahıdan çıxır")
    T1 = db("select id::text i from public.tests where slug='riy-3-vurma-1'", one=True)["i"]
    db("""do $$ declare tok text; att uuid; ans jsonb; begin
            tok := public.rpc_student_login(%s)->>'token';
            att := (public.rpc_start_attempt(tok, %s)->>'attempt_id')::uuid;
            select coalesce(jsonb_agg(jsonb_build_object('q', q.id, 'o', jsonb_build_array(
                     (select o.id from public.question_options o where o.question_id=q.id and o.is_correct order by o.ord limit 1)))), '[]'::jsonb)
              into ans from public.test_questions tq join public.questions q on q.id=tq.question_id where tq.test_id=%s;
            perform public.rpc_submit_attempt(tok, att, ans);
          end $$""", (CODE1, T1, T1))
    pg.reload(); t = prep(pg)
    ok("Murad" in t and "Ayan" not in t and "1/2 şagird" in t, "yalniz Murad qalib", t[-100:])
    ok(pg.locator("#prep a[href^='#/s/']").count() == 1, "ad sagird hesabatina linkdir")

    print("E · Plan qurulur → növbəti mövzu; «Keçildi» → son keçilən + test düyməsi")
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select %s, p.id, 'active', now() + interval '30 days' from public.plans p where p.slug='repetitor-25'""", (AID,))
    pg.reload(); pg.wait_for_selector("#prepPlan", timeout=15000)
    pg.click("#prepPlan"); pg.wait_for_selector("#btnPlMk", timeout=8000)
    ok(pg.locator("#btnPlMk").is_visible(), "«Planı qur» linki plan sekmesini ve formani acir")
    pg.wait_for_function("document.querySelectorAll('#plSub option').length > 1", timeout=8000)
    pg.select_option("#plSub", "riyaziyyat"); pg.select_option("#plLev", "3"); pg.click("#btnPlMk")
    pg.wait_for_selector(".plcur [data-pldone]", timeout=8000)
    pg.reload(); t = prep(pg)
    first = db("""select t.name n from public.class_plan_items i join public.topics t on t.id=i.topic_id
                  order by i.ord limit 1""", one=True)["n"]
    ok("Növbəti mövzu" in t and first in t, "novbeti movzu = planin 1-ci dersi", first)
    ok("Son keçilən" not in t, "hele kecilen yoxdur")
    pg.click("#gTabs [data-v='p']"); pg.locator("[data-pldone]").first.click()
    pg.wait_for_selector(".ploffer", timeout=8000)
    pg.wait_for_function("document.querySelector('#prep .prep') && document.querySelector('#prep .prep').textContent.indexOf('Son keçilən') >= 0", timeout=8000)
    t = prep(pg)
    ok("Son keçilən" in t and first in t, "kecildi -> son kecilen kartda (yenilenmeden)")
    ok(pg.locator("#prepGen").count() == 1 and "testi yığ" in pg.inner_text("#prepGen"), "«… testi yığ» duymesi", pg.inner_text("#prepGen"))
    ok("test verilib" not in t or "hələ yazan yoxdur" in t, "test yoxdursa ortalama yazilmir")

    print("F · Düymə generatoru həmin fəsil seçili açır")
    pg.click("#prepGen"); pg.wait_for_selector("#gTop", timeout=15000)
    pg.wait_for_function("document.querySelectorAll('#gTop .chip.on').length >= 1", timeout=8000)
    ok(pg.locator("#gLevs .chip.on").inner_text().strip() == "3", "sinif 3 secili", pg.locator("#gLevs .chip.on").all_inner_texts())
    #  suallar FESLE baglidir: generator alt movzunun valideynini secir
    chap = db("""select coalesce(par.name, t.name) n from public.class_plan_items i
                   join public.topics t on t.id=i.topic_id left join public.topics par on par.id=t.parent_id
                  order by i.ord limit 1""", one=True)["n"]
    ok(chap in pg.locator("#gTop .chip.on").first.inner_text(), "fesil secili", (chap, pg.locator("#gTop .chip.on").all_inner_texts()))
    pg.screenshot(path="/tmp/bugun_gen.png", full_page=False)

    print("G · Generatorda «Tövsiyə olunan»: bir toxunuşla ev tapşırığı")
    pg.wait_for_selector("#gRec .grow", timeout=8000)
    ok(chap in pg.inner_text("#gRec") and "3-cü sinif" in pg.inner_text("#gRec"), "tovsiye: fesil + qrup", pg.inner_text("#gRec")[:80])
    pg.locator("#gRec [data-grec]").first.click()
    pg.wait_for_selector("#asgFlash, #aList", timeout=20000)
    pg.wait_for_function("document.querySelectorAll('#aTest option').length > 0", timeout=15000)
    sel = pg.locator("#aTest option:checked").inner_text()
    ok("ev tapşırığı" in sel, "tapsiriq ekrani teze test secili acilir", sel)
    ok(db("select count(*) n from public.tests where owner_type='educator' and title like '%%ev tapşırığı%%'", one=True)["n"] == 1, "test bazada")
    pg.goto(PANEL + "#/g/" + GID); prep(pg)
    pg.locator("#prep .prep").screenshot(path="/tmp/bugun_kart.png")
    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails)); [print("  - " + f) for f in fails]; raise SystemExit(1)
print("hamisi kecdi")
