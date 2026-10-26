#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Qrupun Şagirdlər sekməsi (26.10, istifadəçinin son maketi) — nümunə hesabda.

  A  Başlıqda əsas düymə «+ Şagird əlavə et» («Tapşırıq ver» bu sekmədə yoxdur); «N şagird · əlifba sırası»
     başlıqdakı «N şagird» və bazadakı aktiv say ilə eyni; sətirlər əlifba sırası ilə; sütunlar
     Şagird | Son fəaliyyət | «Profilə bax»; siyahıda nəticə faizi yoxdur (Hesabatdadır)
  B  «Profilə bax» → #/s/<şagird>/<qrup>; «Geri» Şagirdlər sekməsinə qaytarır
  C  Axtarış: yalnız adda, Azərbaycan hərfləri («ibra» → «İbrahimov»); tapılmayanda izah; say sətri
  D  «+ Şagird əlavə et»: forma açılır, ad yazılır, şagird əlifba yerində çıxır, iki say birlikdə artır
  E  Dayandırılmış ayrıca bölmədə; aktiv saya girmir
  F  20-dən çox şagird: səhifələr (1–20 / N), axtarış bütün siyahıda gəzir
  G  390 / 360: yana sürüşmə yoxdur, sətir və düymələr ≥ 44 px, «Bax», alt yazıda son fəaliyyət
  H  Boş qrup: «Hələ şagird yoxdur», forma özü açıqdır
"""
import os, re, sys
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

def page(ctx):
    p = ctx.new_page()
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    p.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)[:160]))
    p.on("dialog", lambda d: d.accept())
    return p

def sagirdler(pg, gid):
    h = "#/g/%s/s" % gid
    if pg.evaluate("location.hash") == h: pg.reload()
    else: pg.goto(PANEL + h)
    pg.wait_for_function("document.querySelector('#stuCnt, #stu .empty') && document.querySelector('#gMeta').textContent.length > 3", timeout=20000)
    pg.wait_for_timeout(300)
def hash_(pg): return pg.evaluate("location.hash")
def sw(pg): return pg.evaluate("[document.documentElement.scrollWidth, window.innerWidth]")
def gorunen(pg):
    return pg.evaluate("""[...document.querySelectorAll('#stuT a.ytr')].filter(r => r.offsetParent !== null)
                          .map(r => r.querySelector('.sta b').textContent.trim())""")
def aktivSay(gid):
    return db("select count(*) n from public.students where class_id = %s::uuid and is_active", (gid,), one=True)["n"]

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 1280, "height": 900})
    pg = page(ctx)
    pg.goto(PANEL + "#/demo"); pg.wait_for_selector("#demoBar", timeout=60000); pg.wait_for_timeout(2500)
    acc = db("select id::text i, owner_id::text o from public.accounts where is_demo and id <> app.demo_account() order by created_at desc limit 1", one=True)
    gid = db("""select c.id::text i from public.classes c where c.account_id = %s::uuid
                 and (select count(*) from public.students s where s.class_id = c.id and s.is_active) > 10
               order by c.name limit 1""", (acc["i"],), one=True)["i"]

    print("A · başlıq, say, əlifba sırası (1280)")
    sagirdler(pg, gid)
    n = aktivSay(gid)
    ok(pg.locator("#gHd #btnStuOpen").count() == 1 and pg.locator("#btnAsgs").count() == 0,
       "başlıqda «+ Şagird əlavə et», «Tapşırıq ver» yoxdur", pg.inner_text("#gHd .phd-a"))
    ok(pg.inner_text("#stuCnt").strip() == "%d şagird · əlifba sırası" % n, "say sətri bazadakı aktiv say", pg.inner_text("#stuCnt"))
    ok(pg.inner_text("#gMeta").strip().endswith("· %d şagird" % n), "başlıqdakı say eyni", pg.inner_text("#gMeta"))
    adlar = gorunen(pg)
    ok(len(adlar) == n, "%d sətir" % n, len(adlar))
    ok(pg.evaluate("a => { const c = a.slice().sort((x, y) => x.localeCompare(y, 'az')); return JSON.stringify(c) === JSON.stringify(a); }", adlar),
       "əlifba sırası", adlar[:4])
    hd = [x.strip() for x in pg.locator("#stuT .yth span").all_inner_texts()]
    ok(hd[:2] == ["Şagird", "Son fəaliyyət"], "sütunlar Şagird | Son fəaliyyət", hd)
    ok(all(re.search(r"son test .+ · \d+ test|hələ girməyib|hələ test işləməyib", x) for x in pg.locator("#stuT a.ytr .yts").all_inner_texts()),
       "hər sətirdə son fəaliyyət")
    ok("%" not in pg.inner_text("#stu"), "siyahıda nəticə faizi yoxdur")
    ok(pg.locator("#stuT a.ytr .ytk .ytl").first.is_visible() and pg.inner_text("#stuT a.ytr .ytk >> nth=0").strip().startswith("Profilə bax"),
       "«Profilə bax» keçidi")

    print("B · profilə keçid və Geri")
    r0 = pg.locator("#stuT a.ytr").first
    href = r0.get_attribute("href"); ad0 = r0.locator(".sta b").inner_text().strip()
    sid = db("select id::text i from public.students where class_id = %s::uuid and full_name = %s", (gid, ad0), one=True)["i"]
    ok(href == "#/s/%s/%s" % (sid, gid), "sətir → #/s/<şagird>/<qrup>", href)
    r0.locator(".ytk").click(); pg.wait_for_selector("#sTabs", timeout=20000); pg.wait_for_timeout(500)
    ok(hash_(pg) == href and ad0 in pg.inner_text("body"), "«Profilə bax» profili açır", hash_(pg))
    pg.go_back(); pg.wait_for_selector("#stuCnt", timeout=20000)
    ok(hash_(pg) == "#/g/%s/s" % gid, "brauzer geri → Şagirdlər", hash_(pg))

    print("C · axtarış")
    soz = next((x for x in adlar if "İ" in x), None)
    if soz:
        q = soz.split("İ", 1)[1][:3]
        pg.fill("#stuQ", "i" + q); pg.wait_for_timeout(300)
        ok(soz in gorunen(pg), "«i%s» → «%s» (İ kiçik hərflə tapılır)" % (q, soz), gorunen(pg))
    ad2 = adlar[len(adlar) // 2]; k = ad2.split()[0][:4].lower()
    pg.fill("#stuQ", k); pg.wait_for_timeout(300)
    g2 = gorunen(pg)
    ok(g2 and ad2 in g2 and len(g2) < n, "«%s» yalnız uyğun adlar" % k, g2)
    ok(pg.inner_text("#stuCnt").strip() == "%d / %d şagird tapıldı" % (len(g2), n), "say sətri tapılanı deyir", pg.inner_text("#stuCnt"))
    pg.fill("#stuQ", "girm"); pg.wait_for_timeout(300)
    ok(all("girm" in x.lower() for x in gorunen(pg)), "axtarış yalnız adda gedir")
    pg.fill("#stuQ", "Zzqw"); pg.wait_for_timeout(300)
    ok(not gorunen(pg) and pg.locator("#stuQNone").is_visible() and "«Zzqw» adlı şagird tapılmadı" in pg.inner_text("#stuQNone"), "tapılmayanda izah")
    pg.fill("#stuQ", ""); pg.wait_for_timeout(300)
    ok(len(gorunen(pg)) == n and pg.locator("#stuQNone").is_hidden(), "təmizləyəndə hamısı qayıdır")

    print("D · şagird əlavə et")
    pg.click("#btnStuOpen"); pg.wait_for_timeout(200)
    ok(pg.locator("#stuForm").is_visible() and pg.evaluate("document.activeElement.id") == "sname", "forma açılır, ad sahəsi fokusda")
    ok(pg.locator("#btnStuOpen").is_visible(), "başlıq düyməsi yerində qalır")
    pg.fill("#sname", "Cəlil Babayev"); pg.click("#btnStu")
    pg.wait_for_function("document.querySelector('#stuCnt') && document.querySelector('#stuCnt').textContent.startsWith('%d ')" % (n + 1), timeout=20000)
    pg.wait_for_function("document.querySelector('#gMeta').textContent.endsWith('· %d şagird')" % (n + 1), timeout=20000)
    a2 = gorunen(pg)
    ok("Cəlil Babayev" in a2 and pg.evaluate("a => { const c = a.slice().sort((x, y) => x.localeCompare(y, 'az')); return JSON.stringify(c) === JSON.stringify(a); }", a2),
       "yeni şagird əlifba yerində", a2[:5])
    yeni = pg.locator("#stuT a.ytr", has_text="Cəlil Babayev").inner_text()
    ok("hələ girməyib" in yeni, "yeni şagird: «hələ girməyib — kodu göndərin»", yeni.replace("\n", " | "))
    ok(aktivSay(gid) == n + 1 and pg.inner_text("#gMeta").strip().endswith("· %d şagird" % (n + 1)), "başlıq və siyahı eyni sayı göstərir", pg.inner_text("#gMeta"))

    print("E · dayandırılmış")
    db("update public.students set is_active = false where class_id = %s::uuid and full_name = 'Cəlil Babayev'", (gid,))
    sagirdler(pg, gid)
    ok(pg.inner_text("#stuCnt").strip().startswith("%d " % n) and "Cəlil Babayev" not in gorunen(pg), "aktiv saya girmir")
    ok(pg.locator("details.stoff").count() == 1 and "1" in pg.inner_text("details.stoff summary"), "«Dayandırılmış 1» bölməsi")
    pg.click("details.stoff summary"); pg.wait_for_timeout(200)
    ok("dayandırılıb — yer tutmur" in pg.inner_text("details.stoff"), "sətirdə «dayandırılıb — yer tutmur»")

    print("F · 20-dən çox şagird: səhifələr")
    bg = db("""insert into public.classes (account_id, teacher_id, kind, name, join_code, level_id)
               select %s::uuid, %s::uuid, 'tutor_group', 'Böyük qrup', 'BG' || substr(md5(random()::text), 1, 6), l.id
                 from public.levels l where l.code = '7' returning id::text i""", (acc["i"], acc["o"]), one=True)["i"]
    ADS = ["Ağa", "Bəhruz", "Cavid", "Çingiz", "Dəniz", "Elçin", "Əli", "Fərid", "Gülnar", "Həsən", "İlkin", "Jalə",
           "Kamran", "Lalə", "Məryəm", "Nurlan", "Orxan", "Ömər", "Pərvin", "Rəna", "Səbinə", "Şahin", "Tofiq", "Ülvi", "Vüsal"]
    for i, a in enumerate(ADS):
        db("""insert into public.students (account_id, class_id, created_by, full_name, display_name, login_code)
              values (%s::uuid, %s::uuid, %s::uuid, %s, %s, 'PG' || substr(md5(random()::text), 1, 8))""",
           (acc["i"], bg, acc["o"], a + " Testov", a + " T."))
    sagirdler(pg, bg)
    ok(len(gorunen(pg)) == 20 and pg.locator("#stuPg").is_visible() and pg.inner_text("#stuPgN").strip() == "1–20 / 25",
       "1-ci səhifə: 20 sətir, «1–20 / 25»", pg.inner_text("#stuPgN") if pg.locator("#stuPgN").count() else "-")
    ok(pg.locator("#stuPrev").is_disabled(), "«Əvvəlki» 1-ci səhifədə bağlıdır")
    pg.click("#stuNext"); pg.wait_for_timeout(200)
    g3 = gorunen(pg)
    ok(len(g3) == 5 and pg.inner_text("#stuPgN").strip() == "21–25 / 25" and pg.locator("#stuNext").is_disabled(), "2-ci səhifə: 5 sətir", g3)
    pg.fill("#stuQ", "vüs"); pg.wait_for_timeout(300)
    ok(gorunen(pg) == ["Vüsal Testov"] and pg.locator("#stuPg").is_hidden(), "axtarış bütün siyahıda (səhifə zolağı gizlənir)", gorunen(pg))
    pg.fill("#stuQ", "ağa"); pg.wait_for_timeout(300)
    ok(gorunen(pg) == ["Ağa Testov"], "1-ci səhifədəki ad da tapılır", gorunen(pg))
    pg.fill("#stuQ", ""); pg.wait_for_timeout(300)
    ok(pg.locator("#stuPg").is_visible(), "təmizləyəndə səhifə zolağı qayıdır")
    if SHOT: pg.screenshot(path=SHOT + "/sagirdler_seh_1280.png", full_page=True)
    sagirdler(pg, gid)
    ok(pg.locator("#stuPg").is_hidden(), "20 və az şagirddə səhifə zolağı yoxdur")
    if SHOT: pg.screenshot(path=SHOT + "/sagirdler_1280.png", full_page=True)

    print("G · telefon 390 / 360")
    for w in (390, 360):
        pg.set_viewport_size({"width": w, "height": 844})
        sagirdler(pg, gid)
        s2 = sw(pg); ok(s2[0] <= s2[1], "%d: yana sürüşmə yoxdur" % w, s2)
        r = pg.locator("#stuT a.ytr").first
        ok(r.locator(".sta i").is_visible() and r.locator(".yts").is_hidden(), "%d: son fəaliyyət adın altında" % w, r.locator(".sta i").inner_text())
        ok(r.locator(".yta").is_visible() and r.locator(".ytl").is_hidden() and r.locator(".ytk").inner_text().strip() == "Bax", "%d: «Bax»" % w)
        hh = pg.evaluate("""() => ['#btnStuOpen', '#gSet', '#stuQ', '#stuT a.ytr'].map(s => document.querySelector(s)).filter(Boolean)
            .map(e => [e.id || e.className, Math.round(e.getBoundingClientRect().height)])""")
        ok(len(hh) == 4 and min(x[1] for x in hh) >= 44, "%d: düymə, axtarış, sətir ≥ 44 px" % w, hh)
        fs = pg.evaluate("[getComputedStyle(document.querySelector('#gName')).fontSize, getComputedStyle(document.querySelector('#stuT a.ytr .sta b')).fontSize]")
        ok(fs == ["22px", "15px"], "%d: başlıq 22 px, ad 15 px" % w, fs)
        fit = pg.evaluate("""() => { const t = document.getElementById('stuT').getBoundingClientRect();
            return [...document.querySelectorAll('#stuT a.ytr .ytk')].every(e => e.getBoundingClientRect().right <= t.right + .5); }""")
        ok(fit, "%d: «Bax» cədvəlin içində" % w)
        if SHOT: pg.screenshot(path=SHOT + "/sagirdler_%d.png" % w, full_page=True)

    print("H · boş qrup")
    eg = db("""insert into public.classes (account_id, teacher_id, kind, name, join_code, level_id)
               select %s::uuid, %s::uuid, 'tutor_group', 'Boş qrup', 'BQ' || substr(md5(random()::text), 1, 6), l.id
                 from public.levels l where l.code = '7' returning id::text i""", (acc["i"], acc["o"]), one=True)["i"]
    sagirdler(pg, eg)
    ok("Hələ şagird yoxdur" in pg.inner_text("#stu") and "Yuxarıdakı formaya" in pg.inner_text("#stu") and pg.locator("#stuForm").is_visible(), "boş: izah + forma açıq")
    ok(pg.locator("#stuQ").count() == 0 and pg.locator("#stuPg").count() == 0, "boş: axtarış və səhifə zolağı yoxdur")
    s2 = sw(pg); ok(s2[0] <= s2[1], "boş: yana sürüşmə yoxdur", s2)
    if SHOT: pg.screenshot(path=SHOT + "/sagirdler_bos_360.png", full_page=True)
    br.close()

print("\n" + ("BUTUN YOXLAMALAR KECDI" if not fails else "SEHV (%d): %s" % (len(fails), " | ".join(fails))))
sys.exit(1 if fails else 0)
