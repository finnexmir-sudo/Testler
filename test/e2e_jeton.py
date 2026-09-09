#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Jetonun ONCEDEN yenilenmesi (muellim/sb.js).

NIYE VAR:  giris jetonu bir saat yasayir.  Evvel sb.js jetonun
vaxtinin kecdiyini QABAQCADAN yoxlamirdi - sorgunu gonderirdi, 401
alirdi, SONRA yenileyib tekrarlayirdi.  Ilk aciilisda zencir bele
olurdu:  rpc_my_context -> 401 -> token yenile -> rpc_my_context
(tekrar) -> ekranin sorgusu.  Dord novbeli gedis-gelis, 3-4 saniye
(istifadeci sikayeti, 2026-09-09).

Bu yoxlama ISRAF OLUNAN sorgunu sayir: vaxti kecmis jetonla serverə
gonderilen ve 401 alan sorgu.  Duzeliş varsa SIFIR olmalidir.
Duzelis geri alinsa reqem artir ve yoxlama DUSUR.

Ucuncu bend eks terefi qoruyur: jeton DIRIDIRSE nahaq yere yenileme
getmemelidir (yoxsa her aciilis bir elave sorgu qazanardi).
"""
import sys, time
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

PANEL  = "http://127.0.0.1:8010/muellim/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN    = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
BLOCK  = "**://*.supabase.co/**"
TEST_CFG = """window.CFG = {
  SUPABASE_URL: "http://127.0.0.1:54321",
  SUPABASE_ANON_KEY: "test-anon-key",
  STUDENT_URL: "https://example.test/Testler/",
  CONTACT_WHATSAPP: "+994501234567",
  SHOW_PLANS: false
};"""

fails = []
def ok(cond, label, extra=""):
    print(("  OK   " if cond else "  FAIL ") + label + (("  " + str(extra)) if extra else ""),
          flush=True)
    if not cond: fails.append(label)

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            return cur.fetchone() if one else cur.fetchall()

db("""
delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments;     delete from public.student_sessions;
delete from public.students;        delete from public.classes;
delete from public.subscriptions;
delete from public.account_members; delete from public.accounts;
delete from public.user_roles;      delete from auth.users;
""")

with sync_playwright() as pw:
    br  = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 430, "height": 900})
    pg  = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(
        status=200, content_type="application/javascript", body=TEST_CFG))
    pg.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    pg.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))

    print("A · Hesab qurulur")
    pg.goto(PANEL); pg.wait_for_timeout(400)
    pg.click("#btnSwap")
    pg.fill("#fname", "Jeton Muellim"); pg.fill("#email", "jtn@t.az")
    pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=15000)
    pg.select_option("#atype", "tutor")
    pg.fill("#aname", "Jeton hesabi"); pg.click("#btnSetup")
    pg.wait_for_selector("#gForm", timeout=20000)

    sess = pg.evaluate("() => JSON.parse(localStorage.getItem('panel_session'))")
    ok(bool(sess and sess.get("access_token")), "sessiya yaddasda")
    #  Mock 'expires_in': 3600 verir - sb.js oz mohurunu vurmalidir
    ok(bool(sess.get("sb_exp")), "jetonun bitme mohuru vurulub", sess.get("sb_exp"))

    KOHNE = sess["access_token"]

    #  Serverin davranisi: KOHNE jetonla gelen her sorgu 401.  Real
    #  Supabase de bir saatdan sonra mehz bunu edir.
    israf = {"n": 0, "yol": []}
    def gozetci(route):
        h = route.request.headers
        if h.get("authorization") == "Bearer " + KOHNE:
            israf["n"] += 1
            israf["yol"].append(route.request.url.split("/")[-1])
            route.fulfill(status=401, content_type="application/json",
                          body='{"message":"JWT expired","code":"PGRST301"}')
        else:
            route.continue_()
    pg.route("**/rest/v1/**", gozetci)

    yenileme = {"n": 0}
    def sayci(req):
        if "grant_type=refresh_token" in req.url:
            yenileme["n"] += 1
    pg.on("request", sayci)

    print("B · Vaxti keçmiş jetonla ilk açılış")
    #  Jetonu KOHNELMIS elan edirik - saat irelilemis kimi
    pg.evaluate("""() => {
      var s = JSON.parse(localStorage.getItem('panel_session'));
      s.sb_exp = Date.now() - 60000;
      localStorage.setItem('panel_session', JSON.stringify(s));
    }""")
    pg.reload()
    pg.wait_for_selector("#gForm", timeout=20000)
    pg.wait_for_timeout(1200)          # rpc_seen / rpc_home da getsin

    ok(israf["n"] == 0,
       "vaxti kecmis jetonla SERVERE sorgu getmir (onceden yenilenir)",
       str(israf["n"]) + " israf: " + ", ".join(israf["yol"][:4]))
    ok(yenileme["n"] == 1,
       "yenileme YALNIZ bir defe gedir (paralel sorgular birlesir)",
       yenileme["n"])
    yeni = pg.evaluate("() => JSON.parse(localStorage.getItem('panel_session'))")
    ok(yeni["access_token"] != KOHNE, "yeni jeton yaddasa yazilib")
    ok(yeni.get("sb_exp", 0) > 0 and yeni["sb_exp"] > sess["sb_exp"],
       "yeni jetonun mohuru irelileyib")
    ok(pg.locator("#gForm").count() == 1, "ekran normal acilir - sessiya qirilmayib")

    print("C · Diri jetonla açılış — nahaq yenileme olmamalıdır")
    yenileme["n"] = 0
    pg.reload()
    pg.wait_for_selector("#gForm", timeout=20000)
    pg.wait_for_timeout(800)
    ok(yenileme["n"] == 0, "jeton diridirse elave sorgu getmir", yenileme["n"])

    print("D · Yeniləmə alınmasa sessiya təmiz bağlanır")
    #  Yenileme jetonunu korlayiriq: server 401 verir, tetbiq giris
    #  ekranina qayitmalidir - ag ekranda qalmamalidir.
    pg.evaluate("""() => {
      var s = JSON.parse(localStorage.getItem('panel_session'));
      s.sb_exp = Date.now() - 60000;
      s.refresh_token = 'korlanmis-jeton';
      localStorage.setItem('panel_session', JSON.stringify(s));
    }""")
    pg.reload()
    pg.wait_for_selector("#email", timeout=20000)
    ok(pg.locator("#email").count() == 1, "giris ekrani gorunur")
    ok(pg.evaluate("() => localStorage.getItem('panel_session')") is None,
       "kohnelmis sessiya yaddasdan silinib")

    print("E · İlk açılışda neçə gediş-gəliş")
    #  Bir qrup olsun ki, sagird sorgusu da getsin (real yol)
    acc = db("select a.id, a.owner_id from public.accounts a"
             " join auth.users u on u.id = a.owner_id where u.email = 'jtn@t.az'", one=True)
    db("insert into public.classes (account_id, teacher_id, kind, name, join_code)"
       " values (%s, %s, 'tutor_group', 'J qrupu', 'KODJTN01')"
       " on conflict do nothing", (acc["id"], acc["owner_id"]))
    #  Sessiyani yeniden qururuq (D bendinde silinmisdi)
    pg.fill("#email", "jtn@t.az"); pg.fill("#pass", "parol1234")
    pg.click("#btnAuth"); pg.wait_for_selector("#gForm", timeout=20000)

    izler = []
    def basla(r):
        if "/rest/v1/" in r.url or "/auth/v1/" in r.url:
            izler.append(("REQ", time.monotonic(), r.url))
    def bit(r):
        if "/rest/v1/" in r.url or "/auth/v1/" in r.url:
            izler.append(("RES", time.monotonic(), r.url))
    pg.on("request", basla); pg.on("response", bit)
    pg.reload()
    pg.wait_for_selector(".gcard", timeout=20000)
    pg.wait_for_timeout(1500)

    def nece(parca, novu="REQ"):
        return len([1 for t, _, u in izler if t == novu and parca in u])
    ok(nece("rpc_home") == 1,
       "rpc_home BIR defe gedir (zeng noktesi ve lovheler birlesdi)", nece("rpc_home"))

    #  Paralellik: qruplar sorgusu SEVIYYELERIN cavabindan EVVEL baslamalidir
    lv_res = [t for k, t, u in izler if k == "RES" and "/levels?" in u]
    cl_req = [t for k, t, u in izler if k == "REQ" and "/classes?" in u]
    ok(bool(lv_res) and bool(cl_req) and cl_req[0] < lv_res[0],
       "qruplar seviyyeleri gozlemir - eyni anda gedir",
       "levels cavab %.3f, classes sorgu %.3f" % (lv_res[0] if lv_res else -1,
                                                  cl_req[0] if cl_req else -1))
    ok(pg.locator(".gcard").count() == 1, "qrup karti duz cizilir",
       pg.inner_text("#groups").replace("\n", " ")[:60])

    br.close()

print()
if fails:
    print("UGURSUZ: %d" % len(fails))
    for f in fails: print("  - " + f)
    sys.exit(1)
print("JETON: BUTUN YOXLAMALAR KECDI")
