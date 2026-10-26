#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""QRUP SEHIFESI TELEFONDA (23.10-dan sekmeler).  Kohne bas yazi asagida - tarixce ucun.

DERS QAPISI (db/903): «test yig» dugmesi DERS-DERS acilir.

Server her plan setri ucun deyir: ders_hazir (app.ders_sual_sayi >= app.ders_min).
Bir fesil, uc ders (sintetik - real bank boyudukce netice deyismesin):
  A - 25 nisanli sual   -> HAZIR
  B - 5 nisanli sual    -> hazir deyil
  C - 25 nisanli sual   -> HAZIR (feslin SON dersi)
Feslin qalan 30 sualı nisansizdir.

Yoxlanilir:
  1. hazir ders: setirde «test yig»; basanda qutu «yalniz bu dersden» deyir;
     test adi dersin adidir, HAMISI dersin nisanini dasiyir
  2. hazir olmayan ders: «fesil sonunda · N/M», «test yig» YOXDUR
  3. kecilmemis ders: nə dugme, nə izah
  4. feslin sonu: fesil basliginda «fesilden test yig»; qutu «bu fesilden» deyir;
     fesil testi NISANSIZ suallar da alir; son dersin oz testi ayri qalir
  5. «geri al» - dugmeler de itir
  6. eyni dersden iki defe: suallar (mumkun oldugu qeder) ferqli (223)
  7. server: hazir olmayan dersde p_scope='ders' xeta verir; iki parametrli kohne cagiris isleyir
"""
import os, sys, time, psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
PANEL = "http://127.0.0.1:8010/muellim/index.html"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
OUT = "/tmp/claude-0/qrupmenyu"; os.makedirs(OUT, exist_ok=True)
SEHV = []
def yox(sert, ad, ek=""):
    print(("  OK   " if sert else "  SEHV ") + ad + (("  " + str(ek)) if ek != "" else ""))
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
         delete from public.feedback where true;
         delete from public.subscriptions; delete from public.students;
         delete from public.classes; delete from public.account_members;
         delete from public.accounts; delete from public.user_roles;
         delete from auth.users;
         delete from public.question_options where question_id in (
             select id from public.questions where ext_key like 'qm-%');
         delete from public.questions where ext_key like 'qm-%';""")
def movzu_sil():
    q("""delete from public.class_plan_items where topic_id in (
             select id from public.topics where slug like 'qm-%');
         delete from public.question_options where question_id in (
             select id from public.questions where ext_key like 'qm-%');
         delete from public.questions where ext_key like 'qm-%';
         delete from public.topics where slug like 'qm-%';""")
temizle()
T = int(time.time() * 1000)
lev = q("select id from public.levels where code='5'", one=True)["id"]
with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 375, "height": 667})
    p = ctx.new_page()
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    mail = "qm%d@t.az" % T
    p.goto(PANEL + "?yeni=1"); p.wait_for_selector("#email", timeout=30000)
    p.click("#btnSwap"); p.fill("#fname", "Nurlan müəllim"); p.fill("#email", mail)
    p.fill("#pass", "parol1234"); p.click("#btnAuth")
    p.wait_for_selector("#btnSetup", timeout=30000)
    p.fill("#aname", "Nurlan — riyaziyyat"); p.click("#btnSetup")
    p.wait_for_selector("#adminMsg", state="attached", timeout=30000)
    acc = q("select a.id acc, a.owner_id own from public.accounts a join auth.users u on u.id=a.owner_id where u.email=%s", (mail,), one=True)
    q("insert into public.subscriptions (account_id, plan_id, status, started_at, current_period_end)"
      " select %s, pl.id, 'active', now()-interval '5 days', now()+interval '25 days' from public.plans pl where pl.slug='repetitor-60'", (acc["acc"],))
    gid = q("insert into public.classes (account_id,teacher_id,kind,name,join_code,level_id)"
            " values (%s,%s,'tutor_group','Ev qrup',%s,%s) returning id", (acc["acc"], acc["own"], "QM" + str(T)[-6:], lev), one=True)["id"]
    #  23.10: menyu yerine SEKMELER (e2e_qrup_sekme.py).  Bu test olcunu yoxlayir:
    #  telefonda zolaq + sekme zolagi + ilk kartin basligi BIRINCI ekrandadir.
    def ac(pg, w, h, yol=""):
        pg.set_viewport_size({"width": w, "height": h})
        pg.goto(PANEL + "?yeni=1#/g/" + str(gid) + yol); pg.reload()
        pg.wait_for_selector("#gSek .gtab", timeout=30000); pg.wait_for_timeout(1200)
    #  26.10 (son maket): iri zolaq yoxdur - qrupun basligi (yol, ad, «Tapşırıq ver») #main-in icinde
    def olcu(pg):
        #  test hesabinda e-poct tesdiqi xeberdarligi var (real hesabda yox) - olcudən evvel gizlet
        pg.evaluate("""() => { document.querySelectorAll('div,section').forEach(e => {
            if (e.children.length && /E-poçtunuz təsdiqlənməyib/.test(e.textContent) && e.textContent.length < 400) e.style.display = 'none'; }); }""")
        return pg.evaluate("""() => {
            const vis = [...document.querySelectorAll('#gSek .gtab')].filter(e => e.offsetParent);
            const sek = document.getElementById('gSek').getBoundingClientRect();
            const k1 = document.querySelector('#gkDers .ykh');
            const nav = document.getElementById('bnav').getBoundingClientRect();
            const navShown = getComputedStyle(document.getElementById('bnav')).display !== 'none';
            return {n: vis.length, k1Bottom: k1 ? k1.getBoundingClientRect().bottom : 0,
                    navTop: navShown ? nav.top : window.innerHeight,
                    fit: vis.every(e => e.getBoundingClientRect().right <= sek.right + .5),
                    back: !!document.querySelector('#gBack'), band: getComputedStyle(document.getElementById('band')).display,
                    sw: document.documentElement.scrollWidth, iw: window.innerWidth}; }""")
    print("\n=== telefon 375x667 (iPhone SE) ===")
    ac(p, 375, 667); o = olcu(p)
    yox(o["n"] == 5, "telefonda 4 sekmə + «Daha»", o["n"])
    yox(o["fit"], "sekmələr zolağa sığır")
    yox(o["k1Bottom"] <= o["navTop"], "ilk kartın başlığı alt naviqasiyanın üstündə görünür", "%d ≤ %d" % (o["k1Bottom"], o["navTop"]))
    yox(o["back"] and o["band"] == "none", "«Geri» başlığın yolundadır, iri zolaq yoxdur")
    yox(o["sw"] <= o["iw"], "yana sürüşmə yoxdur")
    p.screenshot(path=OUT + "/1-telefon-375.png")
    print("\n=== telefon 360x640 (kiçik Android) ===")
    ac(p, 360, 640); o2 = olcu(p)
    yox(o2["sw"] <= o2["iw"] and o2["fit"], "başlıq və sekmələr sığır, yana sürüşmə yoxdur")
    p.screenshot(path=OUT + "/2-telefon-360.png")
    print("\n=== uzun ad ===")
    q("update public.classes set name=%s where id=%s", ("Riyaziyyat hazırlıq qrupu 9-cu sinif axşam", gid))
    ac(p, 375, 667); o3 = olcu(p)
    yox(o3["sw"] <= o3["iw"], "uzun adda yana sürüşmə yoxdur")
    p.screenshot(path=OUT + "/3-uzun-ad-375.png")
    q("update public.classes set name='Ev qrup' where id=%s", (gid,))
    print("\n=== qrupun hər sekməsində eyni başlıq, başqa ekrana sızmır ===")
    for yol, ad in (("/s", "şagirdlər"), ("/p", "dərs planı")):
        ac(p, 375, 667, yol)
        yox(p.locator("#gHd").count() == 1 and p.locator("#band").is_hidden(), ad + " sekməsində eyni başlıq")
    p.goto(PANEL + "?yeni=1#/a/" + str(gid)); p.wait_for_selector("#gSek", timeout=20000); p.wait_for_timeout(600)
    yox(p.locator("#gHd").count() == 1, "tapşırıqlar sekməsində eyni başlıq")
    p.goto(PANEL + "?yeni=1#/a/" + str(gid) + "/t"); p.wait_for_selector("#pick", timeout=20000); p.wait_for_timeout(800)
    yox(p.locator("#gSek").count() == 0 and p.locator("#gHd").count() == 0, "«Test ver» ekranı sekmə deyil — qrup başlığı və sekmələr YOXDUR")
    print("\n=== kompüter 1280 ===")
    ac(p, 1280, 900); o4 = olcu(p)
    yox(o4["n"] == 6, "kompüterdə 6 sekmə (ayarlar dişli düymədədir)", o4["n"])
    p.screenshot(path=OUT + "/4-kompyuter.png")
    br.close()
temizle()
print("\n" + ("BUTUN YOXLAMALAR KECDI" if not SEHV else "SEHV (%d): %s" % (len(SEHV), " | ".join(SEHV))))
sys.exit(1 if SEHV else 0)
