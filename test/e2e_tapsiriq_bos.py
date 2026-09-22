#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""«TAPSIRIQ» EKRANI BOS OLANDA NE DEYIR?

22.09: Qizbest muellim «Bəzi mövzularda testlər yoxdur» yazdi.
feedback.page = «Tapşırıq».  Oradaki bos hal metni deyirdi:
  «Test bazasına 3-cü sinif materialları hələ əlavə olunmayıb.
   Qrupun sinfini dəyişsəniz mövcud testlər açılacaq.»
Iki yerde yanlis: bankda 22963 sual var (her fenn/sinif ortulu), ve
hazir PLATFORMA testi hec vaxt olmayib (olculdu: 0, hamisi educator).
Siyahi bosdur, cunki muellim hele OZ testini yigmayib.

Bu skript yoxlayir:
  1. yeni muellimde siyahi bos olur
  2. metn «materialları əlavə olunmayıb» DEMIR
  3. metn «sinfi dəyişin» TEKLIF ETMIR
  4. asagidaki movcud «Yeni test yig» duymesine yonlendirir
  5. bos halda TEKRAR duyme elave etmir
"""
import os, sys, time, psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
BASE = "http://127.0.0.1:8010/"; PANEL = BASE + "muellim/index.html"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
OUT = "/tmp/claude-0/tapsiriqbos"; os.makedirs(OUT, exist_ok=True)
SEHV = []
def yox(sert, ad):
    print(("  OK   " if sert else "  SEHV ") + ad)
    if not sert: SEHV.append(ad)
def q(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args) if args else cur.execute(sql)
        if cur.description:
            r = cur.fetchall(); return (r[0] if r else None) if one else r
def temizle():
    q("""delete from public.attempt_answers where attempt_id in (
             select a.id from public.attempts a join public.tests t
               on t.id = a.test_id where t.owner_type = 'educator');
           delete from public.attempts where test_id in (
             select id from public.tests where owner_type = 'educator');
           delete from public.assignments where test_id in (
             select id from public.tests where owner_type = 'educator');
           delete from public.test_questions where test_id in (
             select id from public.tests where owner_type = 'educator');
           delete from public.tests where owner_type = 'educator';
           delete from public.subscriptions; delete from public.students;
           delete from public.classes; delete from public.account_members;
           delete from public.accounts; delete from public.user_roles;
           delete from auth.users;""")
temizle()
T = int(time.time() * 1000)

#  Produksiyada platforma testi YOXDUR (olculdu).  Yerli bazada seed
#  testleri var - onlari gizledirik ki ekran CANLIDAKI hali gostersin.
gizli = q("update public.tests set status = 'draft'"
          " where owner_type = 'platform' and status = 'published'"
          " returning id")
print("platforma testi muveqqeti gizledildi: %d" % len(gizli or []))

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2)
    p = ctx.new_page()
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    mail = "tb%d@t.az" % T
    p.goto(PANEL + "?yeni=1"); p.wait_for_selector("#email", timeout=30000)
    p.click("#btnSwap"); p.fill("#fname", "Qızbəst müəllim"); p.fill("#email", mail)
    p.fill("#pass", "parol1234"); p.click("#btnAuth")
    p.wait_for_selector("#btnSetup", timeout=30000)
    p.fill("#aname", "Qızbəst müəllim — riyaziyyat"); p.click("#btnSetup")
    p.wait_for_selector("#yMenu .mrow", timeout=30000)

    acc = q("select a.id acc, a.owner_id own from public.accounts a join auth.users u"
            " on u.id=a.owner_id where u.email=%s", (mail,), one=True)
    lev = q("select id from public.levels where code='3'", one=True)["id"]
    gid = q("insert into public.classes (account_id,teacher_id,kind,name,join_code,level_id)"
            " values (%s,%s,'tutor_group','3-cü sinif',%s,%s) returning id",
            (acc["acc"], acc["own"], "TB" + str(T)[-6:], lev), one=True)["id"]

    p.goto(PANEL + "?yeni=1#/a/" + str(gid)); p.reload()
    p.wait_for_selector("#pick .empty, #pick .tlist, #aTest", timeout=30000)
    p.wait_for_timeout(800)
    metn = p.locator("#pick").inner_text().replace("\n", " ")
    print("  ekran:", metn[:150])
    p.screenshot(path=OUT + "/bos.png", full_page=True)

    yox("empty" in p.locator("#pick").inner_html(), "siyahi bos haldadir")
    yox("materialları" not in metn and "əlavə olunmayıb" not in metn,
        "«materiallari elave olunmayib» DEMIR")
    yox("sinfini dəyiş" not in metn, "«sinfi deyisin» TEKLIF ETMIR")
    yox("Yeni test yığ" in metn, "asagidaki duymeye yonlendirir")
    #  Duymeni TEKRARLAMIRIQ - ekranda onsuz da «Yeni test yig» var
    #  (5947-ci setir, hemise gorunur).  Iki eyni duyme seliqesizlikdir.
    yox(p.locator("#pick .btn").count() == 0, "bos halda TEKRAR duyme yoxdur")
    yox(p.locator("#btnGenHere").count() == 1, "movcud «Yeni test yig» duymesi yerindedir")

    p.click("#btnGenHere"); p.wait_for_timeout(1200)
    yox("#/gen" in p.url, "duyme generatora aparir (url: %s)" % p.url.split("#")[-1])
    p.screenshot(path=OUT + "/gen.png", full_page=True)
    br.close()

if gizli:
    q("update public.tests set status = 'published' where id in %s",
      (tuple(r["id"] for r in gizli),))
    print("platforma testleri geri qaytarildi")
temizle()
print("\n" + ("BUTUN YOXLAMALAR KECDI" if not SEHV
              else "SEHV (%d): %s" % (len(SEHV), " | ".join(SEHV))))
sys.exit(1 if SEHV else 0)
