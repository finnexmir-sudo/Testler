#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Başlanğıc yolu (30.10, audit: «yeni müəllimi ilk nəticəyə çatdır») — nümunə hesabda.

  A  Qrup yaranan kimi İÇİ açılır (əvvəl siyahıda qalırdı); boş qrupda əsas düymə «İlk şagirdi əlavə et»;
     İcmalda «İlk nəticəyə 4 addım», 1-ci addım cari
  B  «İlk şagirdi əlavə et» → Şagirdlər, forma açıq, ad sahəsi fokusda
  C  2 şagird əlavə olunanda: 1 ✓, 2-ci addımda girməyən şagirdlərin kodu + «Mətni kopyala» (kod mətni);
     başlıqda yenə «Tapşırıq ver»
  D  3-cü addım «Test yığ» → generator: Kimə = bu qrup, sinif qrupun sinfi (yenidən soruşulmur)
  E  İlk nəticə gələn kimi kart yoxdur
  F  Boş hesabatda «0%» yox — «— hələ nəticə yoxdur»
  G  «Son 7 gündə test işləməyənlər»: hər sətirdə «Xatırlat» (girməyənə kod mətni, girənə xatırlatma)
  H  390 / 360: yana sürüşmə yoxdur, düymələr ≥ 44 px
"""
import os, sys
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

ROOT = "http://127.0.0.1:8010/"
PANEL = ROOT + "muellim/index.html"
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

db("""
delete from public.classes c using public.accounts a where a.id = c.account_id and a.is_demo and a.id <> app.demo_account();
delete from public.tests t using public.accounts a where a.owner_id = t.owner_id and a.is_demo and a.id <> app.demo_account();
delete from public.students s using public.accounts a where a.id = s.account_id and a.is_demo and a.id <> app.demo_account();
create temp table demo_old_e2e as select owner_id from public.accounts where is_demo and id <> app.demo_account();
delete from public.accounts where is_demo and id <> app.demo_account();
delete from auth.users u using demo_old_e2e o where u.id = o.owner_id
  and not exists (select 1 from public.accounts a2 where a2.owner_id = u.id);""")
db("delete from public.app_state where key='demo_reset'")
db("select public.rpc_demo_reset()")

def hash_(pg): return pg.evaluate("location.hash")
def sw(pg): return pg.evaluate("[document.documentElement.scrollWidth, window.innerWidth]")
def icmal(pg, gid):
    pg.goto(PANEL + "#/g/" + gid); pg.reload()
    pg.wait_for_function("document.querySelector('#gkDers .ykh') && document.querySelector('#gMeta').textContent.length > 3", timeout=20000)
    pg.wait_for_timeout(1200)

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 1280, "height": 900})
    ctx.grant_permissions(["clipboard-read", "clipboard-write"], origin="http://127.0.0.1:8010")
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)[:160]))
    pg.goto(PANEL + "#/demo"); pg.wait_for_selector("#demoBar", timeout=60000); pg.wait_for_timeout(2500)
    acc = db("select id::text i from public.accounts where is_demo and id <> app.demo_account() order by created_at desc limit 1", one=True)["i"]

    print("A · qrup yaranan kimi içi açılır")
    pg.goto(PANEL + "#/gs"); pg.wait_for_selector("#btnGroup", timeout=20000); pg.wait_for_timeout(1200)
    pg.fill("#gname", "Başlanğıc qrupu"); pg.select_option("#glevel", label="7-ci sinif"); pg.click("#btnGroup")
    pg.wait_for_function("location.hash.indexOf('#/g/') === 0", timeout=20000)
    gid = db("select id::text i from public.classes where account_id = %s::uuid and name = 'Başlanğıc qrupu'", (acc,), one=True)["i"]
    ok(hash_(pg) == "#/g/" + gid, "qrup yarandı → #/g/<yeni qrup>", hash_(pg))
    pg.wait_for_selector("#gkStart:not([hidden])", timeout=20000); pg.wait_for_selector("#gFirstStu", timeout=20000)
    ok(pg.inner_text("#gFirstStu").strip() == "İlk şagirdi əlavə et" and pg.locator("#btnAsgs").count() == 0, "boş qrupda əsas düymə «İlk şagirdi əlavə et»")
    ok("İlk nəticəyə 4 addım" in pg.inner_text("#gkStart") and pg.locator("#gkStart .gstep.cur").first.inner_text().find("Şagird əlavə edin") >= 0,
       "«İlk nəticəyə 4 addım», 1-ci addım cari")
    ok(pg.locator("#gkStart .gstep").count() == 4, "4 addım")
    top = lambda s: pg.evaluate("document.querySelector('%s').getBoundingClientRect().top" % s)
    ok(top("#gkStart") < top("#gkDers"), "kart «Bugünkü dərs»dən yuxarıdadır (dərs planı tələb olunmur)")
    if SHOT: pg.screenshot(path=SHOT + "/bos_qrup_1280.png", full_page=True)

    print("B · İlk şagirdi əlavə et")
    pg.click("#gFirstStu"); pg.wait_for_selector("#stuForm:not([hidden])", timeout=20000); pg.wait_for_timeout(400)
    ok(hash_(pg) == "#/g/%s/s" % gid and pg.evaluate("document.activeElement.id") == "sname", "Şagirdlər, forma açıq, ad sahəsi fokusda")
    for ad in ("Aysel Quliyeva", "Murad Əliyev"):
        pg.fill("#sname", ad); pg.click("#btnStu"); pg.wait_for_timeout(2200)
    ok(db("select count(*) n from public.students where class_id = %s::uuid", (gid,), one=True)["n"] == 2, "2 şagird bazada")

    print("C · kodu göndərin")
    icmal(pg, gid); pg.wait_for_selector("#gkStart .gkod", timeout=20000)
    ok(pg.locator("#btnAsgs").count() == 1 and pg.locator("#gFirstStu").count() == 0, "şagird olanda başlıqda yenə «Tapşırıq ver»")
    steps = pg.locator("#gkStart .gstep")
    ok("done" in (steps.nth(0).get_attribute("class") or "") and "2 şagird əlavə olunub" in steps.nth(0).inner_text(), "1-ci addım ✓ «2 şagird əlavə olunub»")
    ok("cur" in (steps.nth(1).get_attribute("class") or "") and pg.locator("#gkStart .gkod").count() == 2, "2-ci addım cari, 2 kod sətri")
    kod = db("select login_code c from public.students where class_id = %s::uuid and full_name = 'Aysel Quliyeva'", (gid,), one=True)["c"]
    row = pg.locator("#gkStart .gkod", has_text="Aysel Quliyeva")
    ok(kod in row.inner_text(), "sətirdə şagirdin kodu (%s)" % kod)
    row.locator("[data-gk]").click(); pg.wait_for_timeout(400)
    clip = pg.evaluate("navigator.clipboard.readText()")
    ok("Aysel Quliyeva" in clip and kod in clip and "/sagird/" in clip, "«Mətni kopyala» — ad, link, kod", clip.replace("\n", " / ")[:120])

    print("D · İlk testi verin")
    pg.click("#gsGen"); pg.wait_for_selector("#btnMake", timeout=20000)
    pg.wait_for_function("document.querySelector('#gLevs .chip.on') && document.getElementById('gAsg').value.length > 0", timeout=20000); pg.wait_for_timeout(800)
    ok(pg.locator("#gAsg").input_value() == gid, "Kimə = bu qrup")
    ok(pg.evaluate("[...document.querySelectorAll('#gLevs .chip.on')].map(x => x.dataset.l)") == ["7"] and not pg.evaluate("document.getElementById('btnMake').disabled"),
       "sinif qrupun sinfi (7) — yenidən soruşulmur, düymə açıq")
    pg.click("#btnMake"); pg.wait_for_selector("#btnPAsg", timeout=30000); pg.click("#btnPAsg"); pg.wait_for_selector(".pasgok", timeout=20000)
    tid = hash_(pg).split("/")[-1]
    icmal(pg, gid)
    st = pg.locator("#gkStart .gstep")
    ok("done" in (st.nth(2).get_attribute("class") or "") and "Test verilib" in st.nth(2).inner_text(), "3-cü addım ✓ «Test verilib»")

    print("F · boş hesabat")
    pg.goto(PANEL + "#/r/" + gid); pg.wait_for_selector(".rstat", timeout=20000); pg.wait_for_timeout(500)
    rs = pg.inner_text(".rstat").replace("\n", " ")
    ok("0%" not in rs and "hələ nəticə yoxdur" in rs, "«0%» yox — «— hələ nəticə yoxdur»", rs)

    print("E · ilk nəticə gələndə kart yoxdur")
    s1 = db("select id from public.students where class_id = %s::uuid order by full_name limit 1", (gid,), one=True)["id"]
    db("""insert into public.attempts (test_id, student_id, class_id, status, score, max_score, percent, started_at, finished_at)
          values (%s::uuid, %s, %s::uuid, 'submitted', 3, 5, 60, now() - interval '5 minutes', now())""", (tid, s1, gid))
    icmal(pg, gid); pg.wait_for_timeout(800)
    ok(pg.locator("#gkStart").is_hidden(), "ilk nəticədən sonra «4 addım» kartı yoxdur")

    print("G · Son 7 gündə test işləməyənlər")
    db("update public.students set created_at = now() - interval '20 days' where class_id = %s::uuid", (gid,))
    pg.goto(PANEL + "#/sus"); pg.reload(); pg.wait_for_selector("#suBox .surow", timeout=20000); pg.wait_for_timeout(500)
    ok("Son 7 gündə test işləməyənlər" in pg.inner_text(".band") and pg.locator("#suBox .surow [data-sx]").count() == pg.locator("#suBox .surow").count(),
       "başlıq Siqnallar sətri ilə eyni, hər sətirdə «Xatırlat»")
    r2 = pg.locator("#suBox .surow", has_text="Murad Əliyev")
    if r2.count():
        r2.locator("[data-sx]").click(); pg.wait_for_timeout(300)
        k2 = db("select login_code c from public.students where class_id = %s::uuid and full_name = 'Murad Əliyev'", (gid,), one=True)["c"]
        clip = pg.evaluate("navigator.clipboard.readText()")
        ok(k2 in clip and "test girişi" in clip, "girməyən şagird üçün — kod mətni", clip.replace("\n", " / ")[:100])
    else:
        ok(False, "Murad Əliyev siyahıda var")
    girib = pg.locator("#suBox .surow", has_text="son cavab").first
    if girib.count():
        girib.locator("[data-sx]").click(); pg.wait_for_timeout(300)
        clip = pg.evaluate("navigator.clipboard.readText()")
        ok("son bir həftədə Bil10-da test işləməyib" in clip and "/sagird/" in clip, "girən şagird üçün — xatırlatma", clip.replace("\n", " / ")[:100])

    print("H · telefon 390 / 360")
    eg = db("""insert into public.classes (account_id, teacher_id, kind, name, join_code, level_id)
               select %s::uuid, a.owner_id, 'tutor_group', 'Telefon qrupu', 'TQ' || substr(md5(random()::text), 1, 6), l.id
                 from public.levels l, public.accounts a where l.code = '7' and a.id = %s::uuid returning id::text i""", (acc, acc), one=True)["i"]
    for w in (390, 360):
        pg.set_viewport_size({"width": w, "height": 844})
        icmal(pg, eg); pg.wait_for_selector("#gkStart:not([hidden])", timeout=20000); pg.wait_for_selector("#gFirstStu", timeout=20000)
        s2 = sw(pg); ok(s2[0] <= s2[1], "%d: yana sürüşmə yoxdur" % w, s2)
        hh = pg.evaluate("""() => ['#gFirstStu', '#gsStu'].map(s => [s, document.querySelector(s)]).filter(x => x[1])
            .map(([s, e]) => [s, Math.round(e.getBoundingClientRect().height)])""")
        ok(len(hh) == 2 and min(x[1] for x in hh) >= 44, "%d: düymələr ≥ 44 px" % w, hh)
        if SHOT: pg.screenshot(path=SHOT + "/bos_qrup_%d.png" % w, full_page=True)
    br.close()

print("\n" + ("BUTUN YOXLAMALAR KECDI" if not fails else "SEHV (%d): %s" % (len(fails), " | ".join(fails))))
sys.exit(1 if fails else 0)
