#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Şagird profili (26.10, istifadəçinin son maketi) — nümunə hesabda.

  H  Başlıq: «Geri · Qruplar / qrup / Şagirdlər» (keçidlər), ad, «qrup · sinif», «+ Test tapşır» (menyu),
     dişli → «Giriş kodları» açılır; sekmələr Xülasə · Mövzular · Səhvlər · Tarixçə (sayısız); iri zolaq yoxdur
  A  «Dövr | Orta nəticə | Test sayı»: son 30 gün = valideyn cümləsi = valideyn mətni (bir mənbə); bütün dövr ikinci sətir
  B  «Növbəti addım»: mövzu və faiz Mövzular sekmesindəki sətirlə eyni; düymə generatoru HƏMİN mövzu
     və YALNIZ bu şagirdlə açır
  C  «Son nəticələr» cədvəli = Tarixçənin ilk 3 sətri (ad, tarix, bal, faiz); keçid Tarixçəni açır
  D  «Gözləyən tapşırıqlar · N» = #/ht səhifəsindəki həmin şagirdin sətri
  E  Diaqnostika Mövzular sekmesindədir; «Valideyn üçün hesabat» açılır, «Mətnə bax», «Mətni kopyala»
  I  Səhv dəftəri və «Bu səhvlərdən təkrar testi yığ» Səhvlər sekmesindədir (Xülasədən köçdü, itməyib)
  F  Boş şagird (test yoxdur): boş mətnlər, «0 test · 0%» yazılmır
  G  390 / 360: yana sürüşmə yoxdur, düymə və sətirlər ≥ 44 px, ad 22 px, yol bir sətirdə
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

def norm(t): return re.sub(r"\s+", " ", t or "").strip()
def sw(pg): return pg.evaluate("[document.documentElement.scrollWidth, window.innerWidth]")
def ac(pg, sid, gid):
    pg.goto(PANEL + "#/s/%s/%s" % (sid, gid)); pg.reload()
    pg.wait_for_selector("#stuSon", timeout=25000)
    pg.wait_for_function("document.getElementById('sMeta') && document.getElementById('sMeta').textContent.indexOf('·') > 0", timeout=20000)
    pg.wait_for_function("document.querySelector('#stuPend') && !/Yüklənir/.test(document.querySelector('#stuPend').textContent)", timeout=20000)
    pg.wait_for_timeout(500)

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 1280, "height": 900})
    ctx.grant_permissions(["clipboard-read", "clipboard-write"], origin="http://127.0.0.1:8010")
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)[:160]))
    pg.goto(PANEL + "#/demo"); pg.wait_for_selector("#demoBar", timeout=60000); pg.wait_for_timeout(2500)
    acc = db("select id::text i, owner_id::text o from public.accounts where is_demo and id <> app.demo_account() order by created_at desc limit 1", one=True)
    #  zeif movzusu olan (Təkrar tövsiyəsi duymesi cixan) ve 6+ testli sagird
    rows = db("""select c.id::text g, s.id::text s, s.full_name n from public.classes c join public.students s on s.class_id = c.id
                 where c.account_id = %s::uuid and (select count(*) from public.attempts a where a.student_id = s.id) >= 6
                 order by (select count(*) from public.attempts a where a.student_id = s.id) desc, s.full_name""", (acc["i"],))
    for row in rows:
        gid, sid, NAME = row["g"], row["s"], row["n"]
        ac(pg, sid, gid)
        if pg.locator("#vdTov").count(): break
    FN = NAME.split()[0]
    print("   şagird:", NAME)

    G0 = db("""select c.name n, l.name l from public.classes c join public.levels l on l.id = c.level_id where c.id = %s::uuid""", (gid,), one=True)
    def opn(sel):
        if not pg.evaluate("document.querySelector('%s').open" % sel): pg.click(sel + " > summary"); pg.wait_for_timeout(200)

    print("H · başlıq, sekmələr, menyu, dişli")
    ok(pg.locator("#band").is_hidden() and pg.inner_text("#sName").strip() == NAME, "iri zolaq yoxdur, ad başlıqda", pg.inner_text("#sName"))
    ok(pg.inner_text("#sMeta").strip() == "%s · %s" % (G0["n"], G0["l"]), "«qrup · sinif»", pg.inner_text("#sMeta"))
    ok(pg.get_attribute("#sCrG", "href") == "#/g/" + gid and pg.get_attribute("#sCrS", "href") == "#/g/%s/s" % gid and pg.inner_text("#sCrG").strip() == G0["n"],
       "yol: qrup → #/g/…, Şagirdlər → #/g/…/s")
    tabs = [x.strip() for x in pg.locator("#sTabs .seg").all_inner_texts()]
    ok(tabs == ["Xülasə", "Mövzular", "Səhvlər", "Tarixçə"], "sekmələr sayısız", tabs)
    ok(pg.evaluate("getComputedStyle(document.querySelector('#sTabs .seg.on')).borderBottomStyle") == "solid", "alt xətli seçili sekmə")
    pg.click("#btnAsgStu"); pg.wait_for_timeout(200)
    items = [x.strip() for x in pg.locator("#stuAsgMenu a").all_inner_texts()]
    ok(pg.locator("#stuAsgMenu").is_visible() and items[:2] == ["Hazır test — yalnız bu şagirdə", "Diaqnostik test"], "«Test tapşır» menyusu", items)
    pg.mouse.click(700, 800); pg.wait_for_timeout(200)
    ok(pg.locator("#stuAsgMenu").is_hidden(), "kənara basanda bağlanır")
    pg.click("#btnAsgStu"); pg.click("#stuAsgMenu [data-am='t']"); pg.wait_for_timeout(1500)
    ok(pg.evaluate("location.hash") == "#/a/%s/%s" % (gid, sid), "Hazır test → #/a/<qrup>/<şagird>", pg.evaluate("location.hash"))
    ac(pg, sid, gid)
    pg.click("#sSet"); pg.wait_for_timeout(300)
    ok(pg.evaluate("document.querySelector('#stuKart details').open") and pg.locator("#stuKart .skl").first.is_visible(), "dişli → «Giriş kodları» açılır")
    pg.click("#sCrS"); pg.wait_for_selector("#stuCnt", timeout=20000)
    ok(pg.evaluate("location.hash") == "#/g/%s/s" % gid, "«Şagirdlər» → qrupun Şagirdlər sekməsi")
    ac(pg, sid, gid)

    print("A · Dövr cədvəli = valideyn cümləsi = valideyn mətni")
    st = pg.evaluate("""() => [...document.querySelectorAll('#stuSt .sxr:not(.sxh)')].map(r => [...r.children].map(c => c.textContent.trim()))""")
    vs = norm(pg.text_content("#vSum"))
    mV = re.search(r"Son 30 gündə (\d+) test işləyib\. Orta nəticə (\d+)%", vs)
    vt = pg.input_value("#vTxt")
    ok(st and st[0][0] == "Son 30 gün" and mV and st[0][1] == mV.group(2) + "%" and st[0][2] == mV.group(1), "son 30 gün sətri = valideyn cümləsi", (st[:1], vs))
    ok(mV and ("İşlənən test: " + mV.group(1)) in vt and ("Ortalama: " + mV.group(2) + "%") in vt, "valideyn mətni eyni rəqəmləri deyir", vt[:90].replace("\n", " | "))
    nAll = db("select count(*) n from public.attempts where student_id = %s::uuid", (sid,), one=True)["n"]
    ok(len(st) == 2 and st[1][0] == "Bütün dövr" and st[1][2] == str(nAll), "bütün dövr ikinci sətir, test sayı bazadakı ilə eyni", (st[1:], nAll))
    ok(pg.locator("#stuSt .sxgd").count() == 0 or "Gedişat:" in pg.inner_text("#stuSt .sxgd"), "gedişat cədvəlin altında")

    print("B · Növbəti addım")
    tv = norm(pg.inner_text("#stuTov"))
    mT = re.search(r"Növbəti addım (.+?) mövzusunu təkrar edin\. Son nəticə: (\d+)%", tv)
    ok(mT is not None and "Yalnız " + FN + " üçün" in tv, "mövzu, faiz və «Yalnız %s üçün»" % FN, tv[:120])
    ok(pg.locator("#stuTov .sxsehv, #tab-x #vdF").count() == 0, "Xülasədə bir tövsiyə (səhv dəftəri Səhvlərdə)")
    pg.locator("#sTabs [data-v='m']").click(); pg.wait_for_timeout(500)
    trow = pg.locator("#topicBox .trow", has_text=mT.group(1)).first if mT else None
    ok(trow is not None and trow.count() == 1 and (mT.group(2) + "%") in trow.inner_text(), "Mövzular sekmesində eyni mövzu, eyni faiz",
       trow.inner_text().replace("\n", " ") if trow is not None and trow.count() else "-")
    ok(pg.locator("#tab-m #diagBox").count() == 1 and pg.locator("#tab-x #diagBox").count() == 0, "diaqnostika Mövzular sekmesindədir")

    print("I · Səhvlər sekməsi")
    pg.locator("#sTabs [data-v='s']").click(); pg.wait_for_timeout(300)
    ok(pg.locator("#btnFix").is_visible() and "gözləyir" in pg.inner_text("#tab-s"), "səhv dəftəri və «Bu səhvlərdən təkrar testi yığ» Səhvlər sekmesində")
    pg.locator("#sTabs [data-v='x']").click(); pg.wait_for_timeout(300)
    pg.click("#vdTov"); pg.wait_for_selector("#btnMake", timeout=20000); pg.wait_for_timeout(1200)
    mt = pg.inner_text("#main")
    kim = pg.evaluate("(s => s ? s.options[s.selectedIndex].text : '')(document.getElementById('gAsg'))")
    ok(pg.evaluate("location.hash") == "#/gen" and mT and mT.group(1) in pg.inner_text("#gTopSum") and kim == "yalnız " + NAME and "Suallara bax" in pg.inner_text("#btnMake"),
       "generator həmin mövzu və «Kimə: yalnız %s», düymə «Suallara bax»" % NAME, (kim, pg.inner_text("#gTopSum")))

    print("C · Son nəticələr = Tarixçə")
    ac(pg, sid, gid)
    son = pg.evaluate("""() => [...document.querySelectorAll('#stuSon .sxr:not(.sxh)')].map(r => [r.querySelector('b').textContent.trim(),
        r.querySelector('.sxd').textContent.trim(), r.querySelector('i').textContent.replace(/^.*· /, '').replace(' düz', '').trim(), r.querySelector('.pctv').textContent.trim()])""")
    pg.click("#vdTar"); pg.wait_for_timeout(400)
    ok(pg.locator("#tab-t").is_visible(), "keçid Tarixçə sekmesini açır")
    tar = pg.evaluate("""() => [...document.querySelectorAll('#atList .atr')].slice(0,3).map(e => { const i = e.querySelector('i').textContent.split(' · ');
        return [e.querySelector('b').textContent.trim(), i[0].trim(), i[1].trim(), e.querySelector('.pctv').textContent.trim()]; })""")
    ok(len(son) == 3 and son == tar, "3 sətir Tarixçə ilə eyni (ad, tarix, bal, faiz)", (son[:1], tar[:1]))

    print("D · Gözləyən tapşırıqlar = #/ht")
    pg.locator("#sTabs [data-v='x']").click()
    ok(not pg.evaluate("document.getElementById('stuDiq').open"), "sətir susmaya görə bağlı")
    nP = pg.inner_text("#stuPendN").strip()
    opn("#stuDiq")
    pend = norm(pg.inner_text("#stuPend"))
    pg.goto(PANEL + "#/ht/" + gid); pg.wait_for_selector("#htBox .mrow, #htBox .empty", timeout=20000); pg.wait_for_timeout(500)
    ht_rows = [norm(t) for t in pg.locator("#htBox .udr", has_text=NAME).all_inner_texts()]
    mP = re.search(r"(\d+) test gözləyir", pend)
    ht_t = [t for t in ht_rows if "test gözləyir" in t]
    yaz = "Yazılı tapşırığı etməyib" in pend
    ok((mP is None and not ht_t) or (mP and ht_t and (mP.group(0) in ht_t[0])), "test gözləyir sayı #/ht ilə eyni", (pend[:60], ht_t[:1]))
    ok(yaz == any("yazılı tapşırığı etməyib" in t for t in ht_rows), "yazılı tapşırıq #/ht ilə eyni")
    cem = (1 if yaz else 0) + (int(mP.group(1)) if mP else 0)
    ok(nP == ("· %d" % cem if cem else "· yoxdur"), "sətirdəki say = yazılı + gözləyən test", (nP, cem))

    print("E · Valideyn üçün hesabat")
    ac(pg, sid, gid)
    ok(not pg.locator("#vSum").is_visible(), "sətir susmaya görə bağlı")
    opn("#stuVal")
    ok(pg.locator("#vSum").is_visible() and not pg.locator("#vTxt").is_visible(), "açılır: cümlə görünür, mətn bağlı")
    pg.click("#vOpen"); pg.wait_for_timeout(200)
    ok(pg.locator("#vTxt").is_visible() and "gizlət" in pg.inner_text("#vOpen"), "«Mətnə bax» açır")
    pg.click("#vCopy"); pg.wait_for_timeout(400)
    ok(pg.evaluate("navigator.clipboard.readText()") == pg.input_value("#vTxt"), "«Mətni kopyala» mətni kopyalayır")
    ok(sw(pg)[0] <= sw(pg)[1], "1280: yana sürüşmə yoxdur")
    if SHOT: pg.screenshot(path=SHOT + "/sagird_1280.png", full_page=True)

    print("F · boş şagird")
    #  sagird panelin oz yolu ile elave olunur (kod, yer, owner yoxlamalari server isidir)
    pg.goto(PANEL + "#/g/%s/s" % gid); pg.wait_for_selector("#btnStuOpen", timeout=20000)
    pg.click("#btnStuOpen"); pg.fill("#sname", "Test Boşov"); pg.click("#btnStu"); pg.wait_for_timeout(2500)
    e = db("select id::text i from public.students where class_id = %s::uuid and full_name = 'Test Boşov'", (gid,), one=True)["i"]
    pg.goto(PANEL + "#/s/%s/%s" % (e, gid)); pg.reload(); pg.wait_for_selector("#stuSon", timeout=25000); pg.wait_for_timeout(1500)
    t = pg.inner_text("#tab-x")
    ok("Hələ test işləməyib" in pg.inner_text("#stuSon"), "boş: «Hələ test işləməyib»")
    ok("ən zəif mövzu görünəcək" in pg.inner_text("#stuTov"), "boş: tövsiyə kartında izah", pg.inner_text("#stuTov")[:80])
    ok(pg.locator("#vdTov").count() == 0, "boş: təkrar düyməsi yoxdur")
    ok("Hələ test işləməyib" in pg.text_content("#vSum"), "boş: valideyn cümləsi")
    ok(pg.locator("#stuSt").count() == 0 and "0%" not in t, "boş: «0 test · 0%» yazılmır")
    ok(pg.locator("#vCopy").count() == 0, "boş: boş mətni kopyalamaq düyməsi yoxdur")
    ok(pg.evaluate("document.querySelector('#stuKart details').open"), "boş (hələ girməyib): «Giriş kodları» açıq gəlir")
    if SHOT: pg.screenshot(path=SHOT + "/sagird_bos.png", full_page=True)

    print("G · telefon 390 / 360")
    for w in (390, 360):
        pg.set_viewport_size({"width": w, "height": 844})
        ac(pg, sid, gid)
        ok(sw(pg)[0] <= sw(pg)[1], "%d: yana sürüşmə yoxdur" % w, sw(pg))
        hh = pg.evaluate("""() => ['#btnB', '#btnAsgStu', '#sSet', '#sTabs .seg', '#vdTov', '#stuDiq > summary', '#stuVal > summary', '#stuKart summary', '#vdTar']
            .map(s => [s, document.querySelector(s)]).filter(x => x[1]).map(([s, e]) => [s, Math.round(e.getBoundingClientRect().height)])""")
        ok(len(hh) == 9 and min(x[1] for x in hh) >= 44, "%d: düymə və sətirlər ≥ 44 px" % w, hh)
        ok(pg.evaluate("getComputedStyle(document.querySelector('#sName')).fontSize") == "22px", "%d: ad 22 px (kiçilməyib)" % w)
        cr = pg.evaluate("document.querySelector('#sHd .crumb').getBoundingClientRect().height")
        ok(cr <= 46 and pg.locator("#sCrS").is_visible(), "%d: yol bir sətirdə, «Şagirdlər» görünür" % w, cr)
        ok(pg.locator("#stuSon .sxd").first.is_hidden() and "okt" in pg.inner_text("#stuSon .sxq i >> nth=0"), "%d: tarix adın altında" % w)
        if SHOT: pg.screenshot(path=SHOT + "/sagird_%d.png" % w, full_page=True)
    br.close()

print("\n" + ("BUTUN YOXLAMALAR KECDI" if not fails else "SEHV (%d): %s" % (len(fails), " | ".join(fails))))
sys.exit(1 if fails else 0)
