#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Admin: «Etiket və real çətinlik» (db/938) — İdarəetmə ekranında.

  A  Bölmə görünür, sayı = uyğunsuz + namizəd; izah zolağı (40 / 75)
  B  «Etiket uyğun deyil»: P1 (çətin → asan, 82%), P3 (asan → çətin, 30%); uyğun olan P2 yoxdur
  C  «Çətin namizədlər»: N1 (→ çətin), N2 (→ orta); N3 (12 cavab) siyahıda yox, «1 namizəd gözləyir»
  D  «Siyahını kopyala» — TSV: başlıq + ext_key, etiket, təklif, n, p
  E  390 / 1280: yana sürüşmə yoxdur; şəkillər (SHOT_DIR)
"""
import os, sys, time
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

db("delete from public.question_options o using public.questions q where q.id = o.question_id and q.ext_key like 'e2eql-%%'")
db("delete from public.questions where ext_key like 'e2eql-%%'")
db("""
do $$
declare v_s uuid; v_l uuid; v_t uuid; r record;
begin
  select id into v_s from public.subjects where slug = 'riyaziyyat';
  select l.id into v_l from public.levels l join public.programs p on p.id = l.program_id where p.slug = 'ibtidai' and l.code = '3';
  select id into v_t from public.topics where slug = 'riy-3-toplama' and subject_id = v_s;
  for r in select * from (values
      ('P1', 3, 40, 82.0, false, 'Səbətdə 24 alma var, 6-sı yeyildi. Neçə qaldı?'),
      ('P2', 2, 50, 60.0, false, 'Bir tərəfi 7 sm olan kvadratın perimetri nədir?'),
      ('P3', 1, 31, 30.0, false, '305 ədədinin yazılışında neçə rəqəm var?'),
      ('N1', 3, 33, 35.0, true,  'Üç ardıcıl ədədin cəmi 51-dir. Ən böyüyü hansıdır?'),
      ('N2', 3, 45, 70.0, true,  'Saat 9:40-dan 1 saat 35 dəqiqə sonra saat neçə olar?'),
      ('N3', 3, 12, 20.0, true,  '4 dəftər 2 qələmdən 80 qəpik bahadır…')) x(k, d, n, p, nam, b)
  loop
    insert into public.questions (owner_type, subject_id, level_id, topic_id, kind, body, difficulty, status, ext_key, tags)
    values ('platform', v_s, v_l, v_t, 'single', r.b, r.d, 'published', 'e2eql-' || r.k,
            case when r.nam then array['cetin-namized'] else '{}'::text[] end);
    insert into public.question_stats (question_id, n, p, computed_at)
    select q.id, r.n, r.p, now() from public.questions q where q.ext_key = 'e2eql-' || r.k
    on conflict (question_id) do update set n = excluded.n, p = excluded.p, computed_at = now();
  end loop;
end $$;""")

def sw(pg): return pg.evaluate("[document.documentElement.scrollWidth, window.innerWidth]")

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 1280, "height": 900})
    ctx.grant_permissions(["clipboard-read", "clipboard-write"], origin="http://127.0.0.1:8010")
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)[:160]))
    em = "ql%d@t.az" % int(time.time())
    pg.goto(PANEL); pg.wait_for_selector("#btnAuth", timeout=20000)
    pg.click("#btnSwap"); pg.fill("#fname", "Admin Yoxlayan"); pg.fill("#email", em); pg.fill("#pass", "parol1234")
    pg.click("#btnAuth"); pg.wait_for_selector("#btnSetup", timeout=20000)
    pg.fill("#aname", "Admin hesabı"); pg.click("#btnSetup"); pg.wait_for_timeout(2500)
    db("insert into public.user_roles (user_id, role) select id, 'admin' from auth.users where email = %s on conflict do nothing", (em,))
    #  admin ekrani statistikani 1 saatdan kohnedirse yeniden hesablayir - fiksturun statistikasi silinmesin
    db("update public.question_stats set computed_at = now()")

    def open_adm():
        pg.goto(PANEL + "#/adm"); pg.reload(); pg.wait_for_selector("#qlBox details", timeout=30000); pg.wait_for_timeout(600)
        pg.evaluate("document.querySelector('#qlBox details').open = true"); pg.wait_for_timeout(200)

    print("A · bölmə")
    open_adm()
    txt = pg.inner_text("#qlBox")
    ok("Etiket və real çətinlik" in pg.inner_text("#qlBox summary"), "başlıq", pg.inner_text("#qlBox summary"))
    ok("40%-dən az — çətin, 40–75% — orta, 75%-dən çox — asan" in txt, "zolaq izahı")

    print("B · uyğunsuz")
    mis = pg.inner_text("#qlMis")
    ok("e2eql-P1" in mis and "e2eql-P3" in mis and "e2eql-P2" not in mis, "P1, P3 var; uyğun olan P2 yoxdur")
    r1 = pg.locator("#qlMis .qlr", has_text="e2eql-P1").inner_text().replace("\n", " ")
    ok("çətin → asan" in r1 and "82% düz" in r1 and "40 cavab" in r1, "P1: çətin → asan · 82% · 40 cavab", r1)
    r3 = pg.locator("#qlMis .qlr", has_text="e2eql-P3").inner_text().replace("\n", " ")
    ok("asan → çətin" in r3 and "30% düz" in r3, "P3: asan → çətin · 30%", r3)

    print("C · namizədlər")
    nam = pg.inner_text("#qlNam")
    ok("e2eql-N1" in nam and "e2eql-N2" in nam and "e2eql-N3" not in nam, "N1, N2 var; 12 cavablı N3 yoxdur")
    n1 = pg.locator("#qlNam .qlr", has_text="e2eql-N1").inner_text().replace("\n", " ")
    n2 = pg.locator("#qlNam .qlr", has_text="e2eql-N2").inner_text().replace("\n", " ")
    ok("çətin → çətin" in n1 and "çətin → orta" in n2, "təklif: N1 çətin, N2 orta", [n1[-40:], n2[-40:]])
    ok("namizəd hələ cavab gözləyir" in txt and "e2eql-N1" not in mis, "gözləyənlər sayılır; namizəd uyğunsuz siyahısında yoxdur")

    print("D · kopyala")
    pg.click("#qlCopyM"); pg.wait_for_timeout(400)
    clip = pg.evaluate("navigator.clipboard.readText()")
    lines = clip.split("\n")
    ok(lines[0] == "ext_key\tetiket\tteklif\tn\tp" and any(l.startswith("e2eql-P1\t3\t1\t40\t82") for l in lines), "TSV: başlıq + «e2eql-P1  3  1  40  82»", lines[:3])
    if SHOT: pg.locator("#qlBox").screenshot(path=SHOT + "/etiket_admin_1280.png")

    print("E · telefon")
    pg.set_viewport_size({"width": 390, "height": 844}); open_adm()
    s2 = sw(pg); ok(s2[0] <= s2[1], "390: yana sürüşmə yoxdur", s2)
    if SHOT:
        pg.evaluate("document.querySelectorAll('.top,.bnav').forEach(e => e.style.visibility = 'hidden')")
        pg.locator("#qlBox").screenshot(path=SHOT + "/etiket_admin_390.png")
    br.close()

db("delete from public.question_options o using public.questions q where q.id = o.question_id and q.ext_key like 'e2eql-%%'")
db("delete from public.questions where ext_key like 'e2eql-%%'")
print("\n" + ("BUTUN YOXLAMALAR KECDI" if not fails else "SEHV (%d): %s" % (len(fails), " | ".join(fails))))
sys.exit(1 if fails else 0)
