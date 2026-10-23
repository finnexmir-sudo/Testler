#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sıra 0 (UX yoxlaması, 23.10) — dörd xəta, nümunə hesabda.

  A  İcmal: «… zəif gedir» sətrində faiz 0% DEYİL, açılan #/zm-dəki
     «qrup ortalaması» ilə eynidir (server «avg» verir, panel «ratio» oxuyurdu)
  B  Çap / PDF: bir basış = BİR window.print() (əvvəl iki dəfə çağırılırdı)
  C  Çap: variantlar qarışdırılıb (açar «A, A, A…» deyil), açardakı hərf
     çap olunmuş sualda DÜZ variantın hərfidir; ikinci çap eyni açarı verir
  D  Test yığ: fənn dəyişəndə sinif seçimi sıfırlanır; iki sinifdə ipucu dəqiqdir
  E  Çox sinifli test (9 + 10): vərəq və çap başlığında «9, 10 siniflər»
  F  Qrupun şagird siyahısında axtarış süzür (yeni görünüşdə süzmürdü)
Çox sinif süzgəci (929) SQL-dədir: db/test/smoke_cox_sinif.sql.
"""
import re, sys
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

ROOT = "http://127.0.0.1:8010/"
PANEL = ROOT + "muellim/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
import os
DSN = "host=/tmp port=55432 user=postgres dbname=" + os.environ.get("DB", "panel_e2e")
CFG = """window.CFG = {SUPABASE_URL:"http://127.0.0.1:54321",
  SUPABASE_ANON_KEY:"test-anon-key", STUDENT_URL:"http://127.0.0.1:8010/sagird/",
  PARENT_URL:"http://127.0.0.1:8010/valideyn/", SHOW_PLANS:false};"""

fails = []
def ok(cond, label, extra=""):
    print(("  OK   " if cond else "  FAIL ") + label + (("  " + str(extra)) if extra else ""), flush=True)
    if not cond: fails.append(label)

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            r = cur.fetchall(); return (r[0] if r else None) if one else r

#  evvelki numune nusxeleri (saatliq hedd dolmasin) + paylasilan numune
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

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 390, "height": 844})
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)[:160]))
    pg.goto(PANEL + "#/demo")
    pg.wait_for_selector("#demoBar", timeout=60000)
    pg.wait_for_function("document.body.innerText.indexOf('zəif gedir') >= 0", timeout=30000)
    pg.wait_for_timeout(600)

    print("A · İcmal: zəif mövzu sətrinin faizi")
    row = pg.locator("a.mrow", has_text="zəif gedir").first
    chip = row.locator(".pv, [class*='pv']").last.inner_text().strip() if row.locator(".pv, [class*='pv']").count() else ""
    m = re.search(r"(\d+)\s*%", row.inner_text())
    home_pct = int(m.group(1)) if m else -1
    ok(home_pct > 0, "sətirdə faiz 0% deyil", row.inner_text().replace("\n", " ")[:90])
    row_txt = row.inner_text()
    row.click()
    pg.wait_for_url(re.compile(r"#/zm/"), timeout=15000)
    pg.wait_for_function("document.body.innerText.indexOf('ortalama') >= 0", timeout=15000)
    zt = pg.evaluate("document.body.innerText")
    m2 = re.search(r"ortalamas[ıi]\D{0,12}(\d+)\s*%", zt)
    zm_pct = int(m2.group(1)) if m2 else -2
    #  Iki ayri duster var: Icmal (db/219) sagirdlerin faizinin ORTASI, #/zm (db/220)
    #  butun cavablarin cemi.  Ferq 1-2 bend ola biler - tek menbeye baglamaq Sira 1-dir.
    #  Burada yalniz «0% xetasi» olculur: reqem gelir ve #/zm-e yaxindir.
    #  931 (Sira 2.2): Icmal ve #/zm eyni dusturla - faiz EYNI olmalidir
    ok(home_pct == zm_pct, "İcmaldakı faiz #/zm-dəki qrup ortalaması ilə eynidir", "%s / %s" % (home_pct, zm_pct))
    m3 = re.search(r"(\d+) şagird", row_txt)
    zm_n = pg.locator("#zmBox a.mrow").count()
    ok(m3 and int(m3.group(1)) == zm_n, "İcmaldakı «N şagird» #/zm-dəki ad sayı ilə eynidir", "%s / %s" % (m3.group(1) if m3 else "?", zm_n))
    print("A2 · Nəticələr: zəif mövzu sətri #/zm-ə aparır")
    pg.goto(PANEL + "#/nt"); pg.wait_for_selector("#ntZ a.mrow", timeout=20000)
    hrefs = pg.evaluate("[...document.querySelectorAll('#ntZ a.mrow')].map(a => a.getAttribute('href'))")
    ok(hrefs and all(h.startswith("#/zm/") for h in hrefs), "bütün zəif mövzu sətirləri #/zm-ə aparır", hrefs[:2])
    r0 = pg.locator("#ntZ a.mrow").first
    r0_ad = r0.locator("b").first.inner_text().strip()
    r0_txt = r0.inner_text()
    r0.click(); pg.wait_for_url(re.compile(r"#/zm/"), timeout=15000)
    pg.wait_for_function("document.body.innerText.indexOf('ortalama') >= 0", timeout=15000); pg.wait_for_timeout(300)
    zt2 = pg.evaluate("document.body.innerText")
    ok(r0_ad in zt2, "açılan səhifə həmin mövzunundur", r0_ad)
    m4 = re.search(r"(\d+)\s*%", r0_txt); m5 = re.search(r"ortalamas[ıi]\D{0,12}(\d+)\s*%", zt2)
    ok(m4 and m5 and m4.group(1) == m5.group(1), "Nəticələrdəki faiz açılan səhifədəki ilə eynidir", "%s / %s" % (m4 and m4.group(1), m5 and m5.group(1)))

    #  numune hesabinin bir hazir testi (en cox suallisi)
    acc = db("select id::text i, owner_id::text o from public.accounts where is_demo and id <> app.demo_account() order by created_at desc limit 1", one=True)
    t = db("""select t.id::text i, count(*) n from public.tests t join public.test_questions tq on tq.test_id = t.id
               where t.owner_id = %s::uuid group by t.id order by count(*) desc, t.id limit 1""", (acc["o"],), one=True)
    TID = t["i"]
    corr = {r["ord"]: r["b"] for r in db("""
        select tq.ord, (select o.body from public.question_options o where o.question_id = q.id and o.is_correct order by o.ord limit 1) b
          from public.test_questions tq join public.questions q on q.id = tq.question_id
         where tq.test_id = %s and q.params is null""", (TID,))}

    print("B · Çap / PDF: bir basış = bir çap pəncərəsi")
    pg.goto(PANEL + "#/t/" + TID); pg.wait_for_selector("#btnPrn", timeout=20000); pg.wait_for_timeout(500)
    pg.evaluate("() => { window.__prn = 0; window.print = function(){ window.__prn++ } }")
    pg.check("#prnK")
    pg.click("#btnPrn"); pg.wait_for_timeout(400)
    ok(pg.evaluate("window.__prn") == 1, "window.print() bir dəfə çağırıldı", pg.evaluate("window.__prn"))

    print("C · Çap: variantlar qarışdırılıb, açar çap olunmuş sıraya uyğundur")
    data = pg.evaluate("""() => ({
        qs: [...document.querySelectorAll('#printBox .ppq')].map(q => ({
              b: q.querySelector('.ppb').innerText,
              o: [...q.querySelectorAll('.ppo > span')].map(s => s.innerText.trim()) })),
        key: [...document.querySelectorAll('#printBox .ppkg span')].map(s => s.innerText) })""")
    keys = [re.sub(r"^\d+\.\s*", "", k).strip() for k in data["key"]]
    n = len(keys)
    nA = sum(1 for k in keys if k == "A")
    ok(n >= 8, "açarda kifayət qədər sual var", n)
    ok(nA < n * 0.7, "açar «hamısı A» deyil", "%d/%d A: %s" % (nA, n, " ".join(keys)))
    L = "ABCDEFGH"; uygun = 0; yoxlanan = 0
    for i, q in enumerate(data["qs"]):
        ordm = re.match(r"(\d+)\.", q["b"]);
        if not ordm or int(ordm.group(1)) not in corr or not corr[int(ordm.group(1))]: continue
        if len(keys[i]) != 1: continue
        yoxlanan += 1
        idx = L.index(keys[i])
        if idx < len(q["o"]) and q["o"][idx].replace(" ", "") == corr[int(ordm.group(1))].strip().replace(" ", ""):
            uygun += 1
    ok(yoxlanan >= 5 and uygun == yoxlanan, "açardakı hərf çap olunmuş sualda düz variantdır", "%d/%d" % (uygun, yoxlanan))
    pg.evaluate("() => { window.__prn = 0 }")
    pg.click("#btnPrn"); pg.wait_for_timeout(400)
    key2 = pg.evaluate("[...document.querySelectorAll('#printBox .ppkg span')].map(s => s.innerText)")
    ok(key2 == data["key"], "ikinci çap eyni açarı verir")

    print("D · Test yığ: fənn dəyişəndə sinif seçimi sıfırlanır")
    #  numune hesabinin tek fenni var - ikinci fenn elave olunur ki, secim olsun
    db("update public.accounts set subjects = array['riyaziyyat','informatika'] where id = %s::uuid", (acc["i"],))
    pg.goto(PANEL + "#/gen"); pg.reload(); pg.wait_for_selector("#gsub", timeout=20000); pg.wait_for_timeout(1200)
    subs = pg.evaluate("[...document.querySelectorAll('#gsub option')].map(o => o.value).filter(Boolean)")
    pg.select_option("#gsub", subs[0]); pg.wait_for_timeout(1200)
    pg.wait_for_selector("#gLevs [data-l]", timeout=15000)
    pg.locator("#gLevs [data-l]").first.click(); pg.wait_for_timeout(900)
    sel1 = pg.evaluate("[...document.querySelectorAll('#gLevs [data-l].on, #gLevs [data-l][aria-pressed=true], #gLevs [data-l].sel')].length")
    ok(sel1 >= 1, "sinif seçildi", sel1)
    other = [s for s in subs if s != subs[0]][0]
    pg.select_option("#gsub", other); pg.wait_for_timeout(1200)
    sel2 = pg.evaluate("[...document.querySelectorAll('#gLevs [data-l].on, #gLevs [data-l][aria-pressed=true], #gLevs [data-l].sel')].length")
    ok(sel2 == 0, "başqa fənn seçiləndə heç bir sinif seçili qalmır", sel2)
    chips = pg.locator("#gLevs [data-l]")
    if chips.count() >= 2:
        chips.nth(0).click(); pg.wait_for_timeout(700); chips.nth(1).click(); pg.wait_for_timeout(900)
        hint = pg.evaluate("document.body.innerText")
        ok("bərabər paylanır" not in hint and "mövzularından növbə ilə" in hint,
           "iki sinifdə ipucu «bərabər paylanır» demir, mövzu növbəsini deyir")

    print("E · Çox sinifli test: vərəq və çap başlığında «9, 10 siniflər»")
    db("""update public.tests set gen_rule = coalesce(gen_rule, '{}'::jsonb) || '{"levels":["10","9"]}'::jsonb
           where id = %s""", (TID,))
    pg.goto(PANEL + "#/t/" + TID); pg.reload(); pg.wait_for_selector("#btnPrn", timeout=20000); pg.wait_for_timeout(800)
    top = pg.locator(".card p.muted").first.inner_text()
    ok("9, 10 siniflər" in top, "vərəq başlığı «9, 10 siniflər»", top[:80])
    pg.evaluate("() => { window.print = function(){} }")
    pg.uncheck("#prnK"); pg.click("#btnPrn"); pg.wait_for_timeout(400)
    ppm = pg.evaluate("document.querySelector('#printBox .ppm').innerText")
    ok("9, 10 siniflər" in ppm and "10-cu sinif" not in ppm, "çap başlığı «9, 10 siniflər»", ppm)

    print("F · Qrupun şagird siyahısı: axtarış süzür")
    g = db("""select c.id::text i from public.classes c join public.students s on s.class_id = c.id and s.is_active
               where c.account_id = %s::uuid group by c.id having count(*) > 10 order by count(*) desc limit 1""", (acc["i"],), one=True)
    pg.goto(PANEL + "#/g/" + g["i"] + "/s"); pg.wait_for_selector("#stuQ", timeout=20000); pg.wait_for_timeout(600)
    def gorunen():
        return pg.evaluate("""[...document.querySelectorAll('#stu a.mrow, #stu .stu[data-row]')]
                               .filter(r => r.offsetParent !== null).map(r => (r.querySelector('b') || r).textContent.trim())""")
    hamisi = gorunen()
    adlar = [x for x in hamisi]
    ad1 = next((x for x in adlar if x.lower().startswith("aysel")), adlar[0])
    ad2 = next((x for x in adlar if x.lower().startswith("orxan")), adlar[-1])
    for ad in (ad1, ad2):
        soz = ad.split()[0]
        pg.fill("#stuQ", soz); pg.wait_for_timeout(300)
        g2 = gorunen()
        ok(len(g2) >= 1 and all(soz.lower() in x.lower() for x in g2) and len(g2) < len(hamisi),
           "«%s» yazanda yalnız uyğun adlar qalır" % soz, "%d/%d: %s" % (len(g2), len(hamisi), ", ".join(g2)))
    pg.fill("#stuQ", "gir"); pg.wait_for_timeout(300)
    ok(all("gir" in x.lower() for x in gorunen()), "axtarış yalnız adda gedir («gir» → «hələ girməyib» sətirləri qalmır)", len(gorunen()))
    pg.fill("#stuQ", "Zzqw"); pg.wait_for_timeout(300)
    ok(len(gorunen()) == 0 and pg.locator("#stuQNone").is_visible() and "tapılmadı" in pg.inner_text("#stuQNone"),
       "heç kim tapılmayanda «… adlı şagird tapılmadı» yazılır")
    pg.fill("#stuQ", "Ays"); pg.wait_for_timeout(300)
    import os as _o
    _S = _o.environ.get("SHOT_DIR")
    if _S:
        for w, h in ((390, 844), (1280, 900)):
            pg.set_viewport_size({"width": w, "height": h}); pg.wait_for_timeout(300)
            pg.locator("#stuQ").scroll_into_view_if_needed(); pg.screenshot(path="%s/axtar_%d.png" % (_S, w))
        pg.fill("#stuQ", "Zzqw"); pg.wait_for_timeout(300); pg.screenshot(path="%s/axtar_bos_1280.png" % _S)
        pg.set_viewport_size({"width": 390, "height": 844}); pg.wait_for_timeout(300); pg.screenshot(path="%s/axtar_bos_390.png" % _S)
    pg.fill("#stuQ", ""); pg.wait_for_timeout(300)
    ok(len(gorunen()) == len(hamisi) and pg.locator("#stuQNone").count() == 0, "sahə boşalanda bütün şagirdlər qayıdır, mesaj itir", len(gorunen()))
    br.close()

print()
if fails:
    print("SINDI (%d):" % len(fails))
    for f in fails: print("  - " + f)
    sys.exit(1)
print("HAMISI KECDI")
