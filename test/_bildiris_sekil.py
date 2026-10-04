#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ONBAXIS: muellim sayta girende bildirisi HARADA gorur?

Iki hal yan-yana:
  A) yalniz «Cavabı göndər» basilib (feedback.admin_note dolur)
  B) «Mesaj göndər» islenib (feedback setri author_type='admin')
Ikisinde de muellimin ICMAL sehifesi cekilir.
  test/tek.sh _bildiris_sekil.py
Sekiller: /tmp/claude-0/bildiris/A_cavab.png, B_mesaj.png
"""
import os, time, psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
PANEL = "http://127.0.0.1:8010/muellim/index.html"
CFG = """window.CFG = { SUPABASE_URL: "http://127.0.0.1:54321", SUPABASE_ANON_KEY: "test-anon-key", STUDENT_URL: "https://bil10.az/sagird/", PARENT_URL: "https://bil10.az/valideyn/", SHOW_PLANS: false };"""
OUT = "/tmp/claude-0/bildiris"; os.makedirs(OUT, exist_ok=True)
def q(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args) if args else cur.execute(sql)
        if cur.description:
            r = cur.fetchall(); return (r[0] if r else None) if one else r
q("""delete from public.feedback where true;
     delete from public.subscriptions; delete from public.students;
     delete from public.classes; delete from public.account_members;
     delete from public.accounts; delete from public.user_roles;
     delete from auth.users;""")
T = int(time.time() * 1000)
with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path="/opt/pw-browsers/chromium", args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2)
    p = ctx.new_page()
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    mail = "bl%d@t.az" % T
    p.goto(PANEL); p.wait_for_selector("#email", timeout=30000)
    p.click("#btnSwap"); p.fill("#fname", "Qızbəst müəllim"); p.fill("#email", mail)
    p.fill("#pass", "parol1234"); p.click("#btnAuth")
    p.wait_for_selector("#btnSetup", timeout=30000)
    p.fill("#aname", "Qızbəst müəllim — riyaziyyat"); p.click("#btnSetup")
    p.wait_for_selector("#adminMsg", state="attached", timeout=30000)
    acc = q("select a.id acc, a.owner_id own from public.accounts a join auth.users u"
            " on u.id=a.owner_id where u.email=%s", (mail,), one=True)
    lev = q("select id from public.levels where code='3'", one=True)["id"]
    q("insert into public.classes (account_id,teacher_id,kind,name,join_code,level_id)"
      " values (%s,%s,'tutor_group','3-cü sinif',%s,%s)",
      (acc["acc"], acc["own"], "BL" + str(T)[-6:], lev))

    #  --- HAL A: muellim yazib, admin «Cavabı göndər» basib
    q("insert into public.feedback (author_type,user_id,account_id,kind,page,body,"
      "status,admin_note,answered_at)"
      " values ('teacher',%s,%s,'teklif','Tapşırıq',"
      "'Bəzi mövzularda testlər yoxdur .','done',"
      "'Düzəldildi — «Tapşırıq» ekranı bankı düzgün göstərmirdi.', now())",
      (acc["own"], acc["acc"]))
    p.goto(PANEL + "#/"); p.reload()
    p.wait_for_selector("#adminMsg", state="attached", timeout=30000); p.wait_for_timeout(1800)
    p.screenshot(path=OUT + "/A_cavab.png", full_page=True)
    print("A cekildi — yalniz «Cavabı göndər»")

    #  --- HAL B: ustune «Mesaj göndər» de islenib (db/199)
    q("insert into public.feedback (author_type,user_id,account_id,kind,page,body,status)"
      " values ('admin',%s,%s,'mesaj','admin',"
      "'Qızbəst müəllim, qeydinizə baxdıq və düzəltdik. Sual bankı doludur — "
      "«Test yığ» ilə mövzunu seçib bir neçə saniyəyə test yığa bilərsiniz.','closed')",
      (acc["own"], acc["acc"]))
    p.goto(PANEL + "#/"); p.reload()
    p.wait_for_selector("#adminMsg", state="attached", timeout=30000); p.wait_for_timeout(1800)
    p.screenshot(path=OUT + "/B_mesaj.png", full_page=True)
    print("B cekildi — «Mesaj göndər» islenib")
    br.close()
print("hazir")
