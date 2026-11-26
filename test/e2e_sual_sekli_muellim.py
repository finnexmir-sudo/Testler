#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Muellimin oz sualina sekil (db/939, Storage) - butun zencir.

  A  sekil olmayan fayl - aydin xeta, hec ne yuklenmir
  B  iri PNG (1800x1200) secilir -> brauzer kicildir (<= 80 KB, WebP, <= 1000 px),
     Storage-e yuklenir, redaktorda gorunur
  C  sekil deyisdirilir -> saxlanmamis evvelki fayl silinir (hesabda 1 fayl qalir)
  D  sual saxlanir -> media_url nisbi unvandir; bank siyahisinda sekil acilir
  E  kagiz vereqde sekil var
  F  sagird testi acir -> sekil gorunur (Storage-den, qirmis deyil); netice ekraninda da
  G  «Şəkli sil» + saxla -> media_url bos, fayl Storage-den silinir
  H  saxlamadan cixmaq -> yuklenmis fayl silinir (limit bos yere dolmur)
  I  390 / 1280: yana surusme yoxdur, duymeler >= 44 px; sekiller (SHOT_DIR)
  J  admin ekraninda Storage setri (fayl, MB / 1 GB, limit)
"""
import os, sys, time, zlib, struct, random
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

ROOT = "http://127.0.0.1:8010/"
PANEL = ROOT + "muellim/index.html"
APP = ROOT + "sagird/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN = "host=/tmp port=55432 user=postgres dbname=" + os.environ.get("DB", "panel_e2e")
SHOT = os.environ.get("SHOT_DIR")
CFG = """window.CFG = {SUPABASE_URL:"http://127.0.0.1:54321",
  SUPABASE_ANON_KEY:"test-anon-key", STUDENT_URL:"http://127.0.0.1:8010/sagird/",
  PARENT_URL:"http://127.0.0.1:8010/valideyn/", SHOW_PLANS:false};"""
PRE = "/storage/v1/object/public/sual-sekil/"

fails = []
def ok(cond, label, extra=""):
    print(("  OK   " if cond else "  FAIL ") + label + (("  " + str(extra)) if extra != "" else ""), flush=True)
    if not cond: fails.append(label)

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            r = cur.fetchall(); return (r[0] if r else None) if one else r

def png(w, h, shade):
    """Telefon sekline oxsar iri PNG: kagiz denesi (sum-kuy) + diaqonal ve ufuqi xett.
    Sum-kuy vacibdir: hamar sekil 12 KB-a sixilir ve kicildilme yolu yoxlanmir."""
    random.seed(w * h + shade)
    tbl = bytes(shade + (i % 48) for i in range(256))
    rows = []
    for y in range(h):
        row = bytearray(random.randbytes(w * 3).translate(tbl))
        x = int(w * 0.1 + (w * 0.8) * y / h)
        for xx in range(max(0, x - 6), min(w, x + 6)):
            row[xx * 3:xx * 3 + 3] = b"\x10\x10\x30"
        if h // 2 - 5 < y < h // 2 + 5:
            row[int(w * 0.1) * 3:int(w * 0.9) * 3] = b"\x10\x10\x30" * (int(w * 0.9) - int(w * 0.1))
        rows.append(b"\x00" + bytes(row))
    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)) +
            chunk(b"IDAT", zlib.compress(b"".join(rows), 6)) + chunk(b"IEND", b""))

BIG = png(1800, 1200, 120)
BIG2 = png(1200, 900, 60)

db("""delete from public.attempt_answers; delete from public.attempts; delete from public.assignments;
      delete from public.student_sessions;
      delete from storage.objects where bucket_id = 'sual-sekil'""")

def objs(acc):
    return db("select name, (metadata->>'size')::int size, metadata->>'mimetype' mt from storage.objects "
              "where bucket_id = 'sual-sekil' and name like %s order by created_at", (acc + "/%",))

def nat(pg, sel):
    return pg.evaluate("(s) => { const i = document.querySelector(s); return i && i.complete ? i.naturalWidth : 0; }", sel)

def wait_img(pg, sel, t=10000):
    try:
        pg.wait_for_function("(s) => { const i = document.querySelector(s); return i && i.complete && i.naturalWidth > 0; }",
                             arg=sel, timeout=t)
    except Exception:
        pass

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 1280, "height": 900})
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)[:160]))
    pg.on("dialog", lambda d: d.accept())
    em = "sk%d@t.az" % int(time.time())
    pg.goto(PANEL); pg.wait_for_selector("#btnAuth", timeout=20000)
    pg.click("#btnSwap"); pg.fill("#fname", "Şəkil Müəllim"); pg.fill("#email", em); pg.fill("#pass", "parol1234")
    pg.click("#btnAuth"); pg.wait_for_selector("#btnSetup", timeout=20000)
    pg.fill("#aname", "Şəkil hesabı"); pg.click("#btnSetup"); pg.wait_for_timeout(2500)
    acc = db("""select a.id::text i, a.owner_id::text u from public.accounts a join auth.users u on u.id = a.owner_id
                where u.email = %s""", (em,), one=True)
    A = acc["i"]

    def open_new():
        pg.goto(PANEL + "#/q/new"); pg.wait_for_selector("#qImgCard", timeout=20000); pg.wait_for_timeout(300)

    print("A · Şəkil olmayan fayl")
    open_new()
    ok("Şəkil əlavə et" in pg.inner_text("#qImgCard"), "redaktorda «Şəkil əlavə et» var")
    if SHOT: pg.locator("#qImgCard").screenshot(path=SHOT + "/sekil_bos_1280.png")
    pg.set_input_files("#qImgIn", files=[{"name": "qeyd.txt", "mimeType": "text/plain", "buffer": b"salam"}])
    pg.wait_for_selector("#qImgMsg .err, #qImgMsg [class*=err]", timeout=10000)
    ok("Şəkil faylı seçin" in pg.inner_text("#qImgMsg"), "aydın xəta", pg.inner_text("#qImgMsg"))
    ok(len(objs(A)) == 0, "heç nə yüklənmədi")

    print("B · İri PNG kiçildilir və yüklənir")
    ok(len(BIG) > 100 * 1024, "giriş faylı iridir", "%d KB" % (len(BIG) // 1024))
    pg.set_input_files("#qImgIn", files=[{"name": "ucbucaq.png", "mimeType": "image/png", "buffer": BIG}])
    pg.wait_for_selector("#qImgCard .qfig img", timeout=20000); wait_img(pg, "#qImgCard .qfig img")
    o = objs(A)
    ok(len(o) == 1, "Storage-də 1 fayl", len(o))
    if o:
        ok(o[0]["size"] <= 80 * 1024 and o[0]["mt"] == "image/webp" and o[0]["name"].endswith(".webp"),
           "≤ 80 KB, WebP", "%s · %d KB" % (o[0]["mt"], o[0]["size"] // 1024))
    nw = pg.evaluate("() => { const i = document.querySelector('#qImgCard .qfig img'); return [i.naturalWidth, i.naturalHeight]; }")
    ok(nw[0] in (1000, 800, 640) and abs(nw[1] / max(nw[0], 1) - 2 / 3) < 0.01, "≤ 1000 px-ə kiçildi, nisbət qorundu", nw)
    ok("Şəkli dəyiş" in pg.inner_text("#qImgCard") and pg.locator("#qImgDel").count() == 1, "«Şəkli dəyiş» / «Şəkli sil»")

    print("C · Şəkil dəyişdirilir")
    first = o[0]["name"] if o else ""
    pg.set_input_files("#qImgIn", files=[{"name": "ikinci.png", "mimeType": "image/png", "buffer": BIG2}])
    pg.wait_for_function("(f) => { const i = document.querySelector('#qImgCard .qfig img'); return i && i.src.indexOf(f) < 0; }",
                         arg=first or "x", timeout=20000)
    wait_img(pg, "#qImgCard .qfig img"); pg.wait_for_timeout(500)
    o = objs(A)
    ok(len(o) == 1 and o[0]["name"] != first, "saxlanmamış əvvəlki fayl silindi, yenisi qaldı", [x["name"][-12:] for x in o])
    NAME = o[0]["name"] if o else ""

    if SHOT:
        pg.locator("#qImgCard").screenshot(path=SHOT + "/sekil_redaktor_1280.png")

    print("D · Sual saxlanır, bankda görünür")
    body = "Şəkildəki üçbucağın perimetri neçə sm-dir? (%d)" % int(time.time())
    pg.fill("#qbody", body)
    ins = pg.locator("#qopts .obody")
    ins.nth(0).fill("24 sm"); ins.nth(1).fill("18 sm")
    pg.click("#qSave"); pg.wait_for_function("location.hash === '#/b'", timeout=20000)
    q = db("select id::text i, media_url m from public.questions where body = %s", (body,), one=True)
    ok(q and q["m"] == PRE + NAME, "media_url nisbi ünvandır", q and q["m"])
    QID = q["i"] if q else None
    pg.wait_for_selector("#bq", timeout=20000); pg.fill("#bq", body[:22]); pg.wait_for_timeout(1300)
    pg.wait_for_selector(".qrow .qfig img", timeout=20000); wait_img(pg, ".qrow .qfig img")
    src = pg.locator(".qrow .qfig img").first.get_attribute("src") or ""
    ok(src == "http://127.0.0.1:54321" + PRE + NAME, "bankda ünvan = SUPABASE_URL + nisbi", src[-40:])
    ok(nat(pg, ".qrow .qfig img") > 0, "bankda şəkil açılır (qırmış deyil)")

    print("E · Kağız vərəq")
    db("""insert into public.classes (id, account_id, teacher_id, kind, name, join_code)
          values ('939c0000-0000-0000-0000-000000000001', %s, %s, 'tutor_group', 'Şəkil qrupu', 'SEKQRUP9')
          on conflict (id) do nothing""", (A, acc["u"]))
    db("""insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code)
          values ('939d0000-0000-0000-0000-000000000001', %s, '939c0000-0000-0000-0000-000000000001', %s,
                  'Nigar Əliyeva', 'Nigar Ə.', 'SEKKOD99') on conflict (id) do nothing""", (A, acc["u"]))
    tid = db("""insert into public.tests (owner_type, owner_id, program_id, subject_id, title, status)
                select 'educator', %s::uuid, p.id, s.id, 'Şəkilli sınaq', 'published'
                  from public.programs p, public.subjects s where p.slug = 'ibtidai' and s.slug = 'riyaziyyat'
                returning id::text i""", (acc["u"],), one=True)["i"]
    db("insert into public.test_questions (test_id, question_id, ord) values (%s, %s, 1)", (tid, QID))
    db("insert into public.assignments (class_id, test_id) values ('939c0000-0000-0000-0000-000000000001', %s)", (tid,))
    pg.goto(PANEL + "#/t/" + tid); pg.wait_for_selector(".paper", state="attached", timeout=20000)
    pg.evaluate("var f=document.getElementById('qFold'); if(f) f.open=true"); pg.wait_for_timeout(400)
    ok(pg.locator(".paper .qfig img").count() == 1, "vərəqdə şəkil var", pg.locator(".paper .qfig img").count())

    print("F · Şagird görür")
    sc = br.new_context(viewport={"width": 390, "height": 844})
    sp = sc.new_page()
    sp.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    sp.on("pageerror", lambda e: fails.append("JS xetasi (sagird): " + str(e)[:160]))
    sp.goto(APP); sp.wait_for_selector("#btnIn", timeout=15000)
    sp.fill("#code", "SEKKOD99"); sp.click("#btnIn"); sp.wait_for_selector(".test", timeout=15000)
    sp.locator(".test", has_text="Şəkilli").first.click(); sp.wait_for_selector(".opt", timeout=15000)
    wait_img(sp, ".qfig img")
    ok(sp.locator(".qfig img").count() == 1 and nat(sp, ".qfig img") > 0, "şagird testində şəkil açılır")
    bx = sp.locator(".qfig img").first.bounding_box()
    ok(bx and bx["width"] <= 390, "telefonda enə sığır", bx and round(bx["width"]))
    if SHOT:
        sp.screenshot(path=SHOT + "/sekil_sagird_390.png")
    sp.locator(".opt", has_text="18 sm").first.click(); sp.wait_for_timeout(300)
    sp.click("#btnFinish"); sp.wait_for_selector(".ring", timeout=15000); sp.wait_for_timeout(600)
    wait_img(sp, ".qfig img", 5000)
    ok(sp.locator(".qfig img").count() >= 1 and nat(sp, ".qfig img") > 0, "nəticə ekranında da şəkil var",
       sp.locator(".qfig img").count())
    sc.close()

    print("G · Şəkli sil")
    pg.goto(PANEL + "#/q/" + QID); pg.wait_for_selector("#qImgDel", timeout=20000)
    pg.click("#qImgDel"); pg.wait_for_timeout(200)
    ok(pg.locator("#qImgCard .qfig").count() == 0 and "Şəkil əlavə et" in pg.inner_text("#qImgCard"), "redaktorda şəkil getdi")
    ok(len(objs(A)) == 1, "saxlamamış fayl hələ yerindədir (fikir dəyişə bilər)")
    pg.click("#qSave"); pg.wait_for_function("location.hash === '#/b'", timeout=20000); pg.wait_for_timeout(800)
    ok(db("select media_url m from public.questions where id = %s", (QID,), one=True)["m"] is None, "media_url boşdur")
    ok(len(objs(A)) == 0, "fayl Storage-dən silindi")

    print("H · Saxlamadan çıxmaq")
    open_new()
    pg.set_input_files("#qImgIn", files=[{"name": "u.png", "mimeType": "image/png", "buffer": BIG2}])
    pg.wait_for_selector("#qImgCard .qfig img", timeout=20000)
    ok(len(objs(A)) == 1, "yükləndi")
    pg.goto(PANEL + "#/b"); pg.wait_for_selector("#bq", timeout=20000); pg.wait_for_timeout(800)
    ok(len(objs(A)) == 0, "saxlanmamış fayl silindi")

    print("I · 390 / 1280")
    for w, h in ((390, 844), (1280, 900)):
        pg.set_viewport_size({"width": w, "height": h})
        open_new()
        pg.set_input_files("#qImgIn", files=[{"name": "u.png", "mimeType": "image/png", "buffer": BIG}])
        pg.wait_for_selector("#qImgCard .qfig img", timeout=20000); wait_img(pg, "#qImgCard .qfig img")
        sw = pg.evaluate("[document.documentElement.scrollWidth, window.innerWidth]")
        ok(sw[0] <= sw[1], "%d: yana sürüşmə yoxdur" % w, sw)
        hs = pg.evaluate("Array.from(document.querySelectorAll('#qImgPick,#qImgDel')).map(b => Math.round(b.getBoundingClientRect().height))")
        ok(hs and min(hs) >= 44, "%d: düymələr ≥ 44 px" % w, hs)
        if SHOT:
            pg.evaluate("document.querySelectorAll('.top,.bnav').forEach(e => e.style.visibility = 'hidden')")
            pg.locator("#qImgCard").scroll_into_view_if_needed()
            pg.screenshot(path=SHOT + "/sekil_redaktor_%d.png" % w)
            pg.evaluate("document.querySelectorAll('.top,.bnav').forEach(e => e.style.visibility = '')")
        pg.goto(PANEL + "#/b"); pg.wait_for_selector("#bq", timeout=20000); pg.wait_for_timeout(600)
    ok(len(objs(A)) == 0, "ölçü yoxlamasının faylları da silindi")

    print("J · Admin: Storage sətri")
    db("insert into public.user_roles (user_id, role) values (%s, 'admin') on conflict do nothing", (acc["u"],))
    db("update public.question_stats set computed_at = now()")
    pg.set_viewport_size({"width": 1280, "height": 900})
    pg.goto(PANEL + "#/adm"); pg.reload(); pg.wait_for_selector("#skBox .skbox", timeout=30000)
    t = pg.inner_text("#skBox")
    ok("Sual şəkilləri (Storage)" in t and "0 fayl" in t and "/ 1 GB" in t and "limit 150 fayl" in t, "admin sətri", t.replace("\n", " "))
    db("delete from public.user_roles where user_id = %s", (acc["u"],))
    br.close()

db("delete from public.attempt_answers; delete from public.attempts; delete from public.assignments")
print("\n" + ("BUTUN YOXLAMALAR KECDI" if not fails else "SEHV (%d): %s" % (len(fails), " | ".join(fails))))
sys.exit(1 if fails else 0)
