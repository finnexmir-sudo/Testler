#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ZENG NISANI: «size mektub var» deyirmi?

22.09 (istifadeci): «bildiris ikonunda 1, 2 yazilmalidirki size mektub
var».  Evvel nisan yalniz SAGIRD siqnallarini sayirdi - admin mesaji
gelende zeng susurdu; muellim «Bizə yaz»a girmeyene qeder bilmirdi.

Yoxlanilir:
  1. mesaj yoxdursa nisan gizlidir
  2. bir mesaj gelende nisanda «1» yazilir
  3. iki mesajda «2»
  4. zenge basanda Siqnallar ekraninda mesajlar GORUNUR
     (say bir yeri, ekran basqa yeri gostermesin)
  5. «Oxudum» basilandan sonra say sonur
  6. eyni sey YENI gorunusde de islyir (?yeni=1)
"""
import os, sys, time, psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
PANEL = "http://127.0.0.1:8010/muellim/index.html"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
OUT = "/tmp/claude-0/zeng"; os.makedirs(OUT, exist_ok=True)
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
    q("""delete from public.feedback where true;
         delete from public.subscriptions; delete from public.students;
         delete from public.classes; delete from public.account_members;
         delete from public.accounts; delete from public.user_roles;
         delete from auth.users;""")
temizle()
T = int(time.time() * 1000)

def mesaj(own, acc, metn):
    q("insert into public.feedback (author_type,user_id,account_id,kind,page,body,status)"
      " values ('admin',%s,%s,'mesaj','admin',%s,'closed')", (own, acc, metn))

def nisan(p):
    """zeng nisaninin metni: gizlidirse None"""
    d = p.locator("#bellDot")
    if not d.count(): return None
    gizli = p.evaluate("!!document.querySelector('#bellDot.hide')")
    if gizli: return None
    return (d.inner_text() or "").strip()

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    for gor in ("kohne", "yeni"):
        ctx = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2)
        p = ctx.new_page()
        p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
        temizle()
        sfx = "?yeni=1" if gor == "yeni" else ""
        mail = "zg%s%d@t.az" % (gor[:1], T)
        print("\n=== %s gorunus ===" % gor.upper())
        p.goto(PANEL + sfx); p.wait_for_selector("#email", timeout=30000)
        p.click("#btnSwap"); p.fill("#fname", "Samir müəllim"); p.fill("#email", mail)
        p.fill("#pass", "parol1234"); p.click("#btnAuth")
        p.wait_for_selector("#btnSetup", timeout=30000)
        p.fill("#aname", "Samir test"); p.click("#btnSetup")
        p.wait_for_selector("#adminMsg", state="attached", timeout=30000)
        p.wait_for_timeout(1500)
        yox(nisan(p) is None, "mesaj yoxdur - nisan gizlidir")

        acc = q("select a.id acc, a.owner_id own from public.accounts a join auth.users u"
                " on u.id=a.owner_id where u.email=%s", (mail,), one=True)
        mesaj(acc["own"], acc["acc"], "Birinci mesaj — qeydinizə baxdıq.")
        p.goto(PANEL + sfx + "#/"); p.reload()
        p.wait_for_selector("#adminMsg", state="attached", timeout=30000)
        p.wait_for_timeout(1600)
        yox(nisan(p) == "1", "bir mesaj - nisanda «1» (indi: %r)" % nisan(p))
        yox("Bil10-dan mesaj" in p.locator("#adminMsg").inner_text(),
            "Icmalda kart gorunur")
        p.screenshot(path=OUT + "/%s-1.png" % gor, full_page=True)

        mesaj(acc["own"], acc["acc"], "İkinci mesaj — test yığmağa baxın.")
        p.goto(PANEL + sfx + "#/"); p.reload()
        p.wait_for_selector("#adminMsg", state="attached", timeout=30000)
        p.wait_for_timeout(1600)
        yox(nisan(p) == "2", "iki mesaj - nisanda «2» (indi: %r)" % nisan(p))

        #  zenge bas - Siqnallar ekraninda mesajlar gorunmelidir
        p.click("#btnBell")
        p.wait_for_selector("#nMsg", state="attached", timeout=30000)
        p.wait_for_timeout(1400)
        #  Basligi METNLE yoxlamaq olmaz: .alh CSS ile BOYUK herfe
        #  cevirir, «Bil10» -> «BIL10» noqteli I ile cixir ve lower()
        #  onu geri qaytarmir (i + birlesen noqte).  Struktura baxiriq.
        sq = p.locator("#main").inner_text()
        yox(p.locator("#nMsgC").count() == 1, "zeng Siqnallara aparir ve mesaj bolmesi var")
        yox("Birinci mesaj" in sq and "İkinci mesaj" in sq, "her iki mesaj siyahida")
        p.screenshot(path=OUT + "/%s-siqnal.png" % gor, full_page=True)

        #  «Oxudum» - say sonmelidir
        p.goto(PANEL + sfx + "#/"); p.reload()
        p.wait_for_selector("#amsgOk", timeout=30000)
        p.click("#amsgOk"); p.wait_for_timeout(1500)
        yox(nisan(p) == "1", "biri oxundu - nisan «1»-e dusdu (indi: %r)" % nisan(p))
        ctx.close()
    br.close()
temizle()
print("\n" + ("BUTUN YOXLAMALAR KECDI" if not SEHV
              else "SEHV (%d): %s" % (len(SEHV), " | ".join(SEHV))))
sys.exit(1 if SEHV else 0)
