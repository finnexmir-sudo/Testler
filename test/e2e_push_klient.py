#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Telefona bildiris - KLIENT (db/910, assets/push.js): sagird ve valideyn kartlari.

Brauzerin Notification / PushManager / service worker-i SAXTA ile evez olunur (headless-de real push yoxdur) -
yoxlanan: bizim mentiq: kart nezaman cixir, icaze YALNIZ duyme ile sorusulur, servere duzgun yazilir,
«Sondur» / cixis abuneni silir, iPhone/blok/acar-yox hallari, 390 ve 1280 px.
Real telefona catmasi bu testle yoxlanmir."""
import base64, os, sys, time
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright

ROOT = "http://127.0.0.1:8010/"
STUDENT = ROOT + "sagird/index.html"
PARENT = ROOT + "valideyn/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
OUT = "/tmp/claude-0/pushklient"; os.makedirs(OUT, exist_ok=True)
BLOCK = "**://*.supabase.co/**"
VAPID = base64.urlsafe_b64encode(b"\x04" + os.urandom(64)).decode().rstrip("=")      # 65 bayt, 87 simvol
def cfg(key):
    return """window.CFG = {SUPABASE_URL:"http://127.0.0.1:54321", SUPABASE_ANON_KEY:"test-anon-key",
      STUDENT_URL:"http://127.0.0.1:8010/sagird/", PARENT_URL:"http://127.0.0.1:8010/valideyn/", SHOW_PLANS:false, VAPID_PUBLIC:"%s"};""" % key

STUB = """
(() => {
  //  Hequiqi brauzer icaze ve abuneni sehife yenilenende SAXLAYIR - stub da saxlayir (localStorage, bu origin).
  //  Yeni sehife (yeni sessionStorage) __FRESH olsa temiz baslayir; yenileme halinda vəziyyət qalir.
  let saved = null;
  try {
    if (!sessionStorage.getItem('__stub_init')) {
      sessionStorage.setItem('__stub_init', '1');
      if (window.__FRESH) localStorage.removeItem('__stub_push');
    }
    saved = JSON.parse(localStorage.getItem('__stub_push') || 'null');
  } catch (e) {}
  function mk(ep) {
    return { endpoint: ep, toJSON() { return { endpoint: this.endpoint, keys: { p256dh: 'B'.repeat(87), auth: 'c'.repeat(22) } }; } };
  }
  const st = { perm: window.__PERM || (saved && saved.perm) || 'default', next: 'granted',
               sub: saved && saved.sub ? mk(saved.sub) : null, asked: 0, subOpts: null };
  function persist() {
    try { localStorage.setItem('__stub_push', JSON.stringify({ perm: st.perm, sub: st.sub && st.sub.endpoint })); } catch (e) {}
  }
  window.__push = st;
  function FakeN() {}
  Object.defineProperty(FakeN, 'permission', { get() { return st.perm; } });
  FakeN.requestPermission = () => { st.asked++; st.perm = st.next; persist(); return Promise.resolve(st.perm); };
  window.Notification = FakeN;
  window.PushManager = function () {};
  const reg = { pushManager: {
    getSubscription: async () => st.sub,
    subscribe: async (o) => {
      st.subOpts = { userVisibleOnly: o.userVisibleOnly, keyLen: o.applicationServerKey.length };
      st.sub = mk('https://fcm.googleapis.com/fcm/send/E2E-' + Math.random().toString(36).slice(2) + '-aaaaaaaaaaaa');
      persist();
      return st.sub;
    } } };
  Object.defineProperty(navigator, 'serviceWorker', { value: { ready: Promise.resolve(reg), register: () => Promise.resolve(reg) }, configurable: true });
})();
"""

fails = []
def ok(cond, label, extra=""):
    print(("  OK   " if cond else "  FAIL ") + label + (("  " + str(extra)) if (extra != "" and not cond) else ""), flush=True)
    if not cond: fails.append(label)

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            return cur.fetchone() if one else cur.fetchall()

def wait_db(sql, want, args=None, timeout=10):
    t0 = time.time(); v = None
    while time.time() - t0 < timeout:
        v = db(sql, args, one=True)["n"]
        if v == want: return v
        time.sleep(0.25)
    return v

db("""
delete from public.push_outbox; delete from public.push_subs;
delete from public.question_reports; delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments; delete from public.student_sessions; delete from public.parent_sessions;
delete from public.students; delete from public.classes;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.question_options o using public.questions q where q.id = o.question_id and q.owner_type = 'educator';
delete from public.questions where owner_type = 'educator';
delete from public.subscriptions; delete from public.account_members; delete from public.accounts;
delete from public.user_roles; delete from public.profiles; delete from auth.users;""")
db("update public.app_state set val = '{\"on\": false}' where key = 'hesab_bagli'")
OWN, ACC = "11110000-0000-0000-0000-0000000004a1", "aaaa0000-0000-0000-0000-0000000004a1"
db("insert into auth.users (id, email) values (%s, 'pushklient@t.az')", (OWN,))
db("insert into public.accounts (id, type, name, owner_id) values (%s, 'tutor', 'Push klient', %s)", (ACC, OWN))
db("insert into public.account_members values (%s, %s, true)", (ACC, OWN))
db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
      select %s::uuid, p.id, 'trialing', now() + interval '30 days' from public.plans p where p.slug = 'repetitor-25'""", (ACC,))
GID = db("""insert into public.classes (account_id, teacher_id, kind, name, join_code)
            values (%s, %s, 'tutor_group', 'Push sinfi', 'PSK00001') returning id::text i""", (ACC, OWN), one=True)["i"]
SIDS = []
for i, (nm, dn, lc, pc) in enumerate((("Aysu Kərimova", "Aysu K.", "PSKSTU01", "PSKPAR01"), ("Murad Kərimov", "Murad K.", "PSKSTU02", "PSKPAR02"))):
    SIDS.append(db("""insert into public.students (account_id, class_id, created_by, full_name, display_name, login_code, parent_code)
                      values (%s, %s, %s, %s, %s, %s, %s) returning id::text i""", (ACC, GID, OWN, nm, dn, lc, pc), one=True)["i"])
S1, S2 = SIDS
for t, sid in (("tokP1", S1), ("tokP2", S2)):
    db("insert into public.parent_sessions (token_hash, student_id, expires_at) values (app.hash_token(%s), %s, now() + interval '10 days')", (t, sid))

def page(ctx, key=VAPID, perm=None, extra_init=""):
    p = ctx.new_page()
    p.add_init_script(("window.__FRESH=true;window.__PERM=%s;" % ("'" + perm + "'" if perm else "undefined")) + STUB + extra_init)
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=cfg(key)))
    p.on("pageerror", lambda e: fails.append("JS xetasi: " + str(e)))
    p.route(BLOCK, lambda r: (fails.append("XARICI SORGU: " + r.request.url), r.abort()))
    return p

def sag_login(p):
    p.goto(STUDENT); p.wait_for_selector("#btnIn, #pushBox", state="attached", timeout=15000)
    if p.locator("#btnIn").count():                      # sessiya yoxdursa daxil ol (eyni kontekstde qalirsa ev ekrani acilir)
        p.fill("#code", "PSKSTU01"); p.click("#btnIn")
    p.wait_for_selector("#pushBox", state="attached", timeout=15000); p.wait_for_timeout(900)

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])

    for w, h, tag in ((390, 844, "tel"), (1280, 800, "masa")):
        print("== SAGIRD %s (%dx%d)" % (tag, w, h))
        db("delete from public.push_subs")
        ctx = br.new_context(viewport={"width": w, "height": h})

        print("1 · acar (VAPID_PUBLIC) yoxdursa xidmet GIZLIDIR")
        p = page(ctx, key=""); sag_login(p)
        ok(p.locator("#pushBox").inner_text().strip() == "" and p.locator("#pushOn").count() == 0, "acar yoxdur: kart cixmir")
        p.close()

        print("2 · kart cixir, icaze YALNIZ duymeye basanda sorusulur")
        p = page(ctx); sag_login(p)
        ok(p.locator("#pushOn").count() == 1, "«Bildirişləri aç» düyməsi var")
        ok("xəbər tut" in p.locator("#pushBox").inner_text(), "kart mətni")
        ok("İcazə ver" in p.locator("#pushBox .pc-h").inner_text(), "düymənin yanında: «Brauzer soruşanda «İcazə ver» seç»")
        ok(p.evaluate("window.__push.asked") == 0, "səhifə açılanda icazə SORUŞULMUR")
        p.screenshot(path="%s/sagird_%s_kart.png" % (OUT, tag), full_page=True)
        p.click("#pushOn"); p.wait_for_selector("#pushOff", timeout=10000)
        ok(p.evaluate("window.__push.asked") == 1, "düyməyə basanda icazə soruşuldu (1 dəfə)")
        so = p.evaluate("window.__push.subOpts")
        ok(so and so["userVisibleOnly"] is True and so["keyLen"] == 65, "subscribe: userVisibleOnly=true, açıq açar 65 bayt", so)
        n = wait_db("select count(*) n from public.push_subs where role='student' and student_id=%s", 1, (S1,))
        ok(n == 1, "bazada şagird abunəsi yazılıb", n)
        row = db("select endpoint, ua from public.push_subs where student_id=%s", (S1,), one=True)
        ok(row["endpoint"].startswith("https://fcm.googleapis.com/") and row["ua"], "endpoint + ua yazılıb")
        ok("açıqdır" in p.locator("#pushBox").inner_text(), "kart «açıqdır» göstərir")
        p.screenshot(path="%s/sagird_%s_aciq.png" % (OUT, tag), full_page=True)

        print("3 · yeniden acanda: abune 1 setir qalir (sinxron), «Sondur» silir ve cihazda yadda qalir")
        p.reload(); p.wait_for_selector("#pushOff", timeout=15000); p.wait_for_timeout(600)
        ok(db("select count(*) n from public.push_subs where student_id=%s", (S1,), one=True)["n"] == 1, "yenilənəndə təkrar sətir yaranmır")
        p.click("#pushOff"); p.wait_for_selector("#pushOn", timeout=10000)
        n = wait_db("select count(*) n from public.push_subs where student_id=%s", 0, (S1,))
        ok(n == 0, "«Söndür» server abunəsini silir", n)
        p.reload(); p.wait_for_selector("#pushBox", timeout=15000); p.wait_for_timeout(800)
        ok(p.locator("#pushOn").count() == 1 and p.locator("#pushOff").count() == 0, "söndürülüb: yenilənəndə «açıqdır» deyil, yenə «aç» təklifi")
        ok(db("select count(*) n from public.push_subs where student_id=%s", (S1,), one=True)["n"] == 0, "sinxron söndürülmüş abunəni geri yazmır")

        print("4 · cixis abuneni silir")
        p.click("#pushOn"); p.wait_for_selector("#pushOff", timeout=10000)
        ok(wait_db("select count(*) n from public.push_subs where student_id=%s", 1, (S1,)) == 1, "yenidən açıldı")
        p.click("#btnOut"); p.wait_for_selector("#btnIn", timeout=10000)
        n = wait_db("select count(*) n from public.push_subs where student_id=%s", 0, (S1,))
        ok(n == 0, "«Çıxış» bu cihazdakı abunəni silir", n)
        p.close()

        print("5 · icaze rədd olunur / bloklanıb / baglanir (dismissed)")
        p = page(ctx); sag_login(p)
        p.evaluate("window.__push.next = 'default'")                         # pəncərə bağlandı, seçim yoxdur
        p.click("#pushOn"); p.wait_for_selector("#pushMsg .warn, #pushMsg [class*=warn]", timeout=8000)
        ok("İcazə verilmədi" in p.locator("#pushMsg").inner_text() and p.locator("#pushOn").is_enabled(), "pəncərə bağlanıb: «İcazə verilmədi», düymə yenə aktivdir")
        p.evaluate("window.__push.next = 'denied'")
        p.click("#pushOn"); p.wait_for_selector(".pushblk .pc-steps", timeout=8000)
        ok("bloklanıb" in p.locator("#pushBox").inner_text(), "rədd: «bloklanıb» kartı")
        ok(p.locator(".pushblk .pc-steps li").count() >= 3 and p.locator("#pushOn").count() == 0, "rədd: ADDIMLAR göstərilir (3+), düymə yoxdur")
        ok(db("select count(*) n from public.push_subs where student_id=%s", (S1,), one=True)["n"] == 0, "rədd olunanda bazaya yazılmır")
        p.screenshot(path="%s/sagird_%s_bloklu.png" % (OUT, tag), full_page=True)
        p.close()
        p = page(ctx, perm="denied"); sag_login(p)
        ok("bloklanıb" in p.locator("#pushBox").inner_text() and p.locator("#pushOn").count() == 0, "icazə bloklanıb: yalnız izah, düymə yox")
        ok(p.locator(".pushblk .pc-steps li").count() >= 3, "açılışda da bloklu halda addımlar var")
        ok("basın" not in p.locator("#pushBox").inner_text(), "şagird mətni qeyri-rəsmidir («bas», «basın» yox)")
        p.close()

        print("6 · iPhone, ana ekrana elave olunmayib")
        ios = ctx.new_page()
        ctx.close()
        ctx = br.new_context(viewport={"width": w, "height": h},
                             user_agent="Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1")
        p = page(ctx); sag_login(p)
        ok("ana ekrana" in p.locator("#pushBox").inner_text().lower() and p.locator("#pushOn").count() == 0, "iPhone: «ana ekrana əlavə et» göstərişi, düymə yoxdur")
        p.screenshot(path="%s/sagird_%s_iphone.png" % (OUT, tag), full_page=True)
        ctx.close()

        print("7 · Android: bloklu halda Android addımları")
        ctx = br.new_context(viewport={"width": w, "height": h},
                             user_agent="Mozilla/5.0 (Linux; Android 13; SM-X700) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
        p = page(ctx, perm="denied"); sag_login(p)
        st = p.locator(".pushblk .pc-steps").inner_text()
        ok("İcazələr" in st and "Ünvan xəttinin solundakı kiçik işarə" in st, "Android: «İcazələr → Bildirişlər» addımları", st.replace("\n", " | "))
        ctx.close()

    # ------------------------------------------------------------------ VALIDEYN (iki usaq)
    for w, h, tag in ((390, 844, "tel"), (1280, 800, "masa")):
        print("== VALIDEYN %s (%dx%d), iki usaq" % (tag, w, h))
        db("delete from public.push_subs")
        db("delete from public.parent_sessions")
        for t, sid in (("tokP1", S1), ("tokP2", S2)):
            db("insert into public.parent_sessions (token_hash, student_id, expires_at) values (app.hash_token(%s), %s, now() + interval '10 days')", (t, sid))
        seed = "localStorage.setItem('valideyn_ses', JSON.stringify({kids:[{t:'tokP1',c:{name:'Aysu K.'}},{t:'tokP2',c:{name:'Murad K.'}}],cur:'tokP1',demo:false}));"
        ctx = br.new_context(viewport={"width": w, "height": h})
        p = page(ctx, extra_init=seed)
        p.goto(PARENT); p.wait_for_selector("#pushBox", timeout=20000); p.wait_for_selector("#pushOn", timeout=10000)
        ok("xəbər tutun" in p.locator("#pushBox").inner_text(), "valideyn kartı (siz formasında)")
        ok(p.evaluate("window.__push.asked") == 0, "açılanda icazə soruşulmur")
        p.screenshot(path="%s/valideyn_%s_kart.png" % (OUT, tag), full_page=True)
        p.click("#pushOn"); p.wait_for_selector("#pushOff", timeout=10000)
        n = wait_db("select count(*) n from public.push_subs where role='parent'", 2)
        ok(n == 2, "bir düymə BÜTÜN uşaqlar üçün abunə edir (2 sətir)", n)
        ok(db("select count(distinct endpoint) n from public.push_subs", one=True)["n"] == 1, "eyni telefon: eyni endpoint")
        ok({r["student_id"] for r in db("select student_id::text from public.push_subs")} == {S1, S2}, "hər iki uşağa bağlıdır")
        p.screenshot(path="%s/valideyn_%s_aciq.png" % (OUT, tag), full_page=True)
        p.click("#pushOff"); p.wait_for_selector("#pushOn", timeout=10000)
        n = wait_db("select count(*) n from public.push_subs", 0)
        ok(n == 0, "«Söndür» bütün uşaqların abunəsini silir", n)

        print("   bloklu hal: rəsmi («siz») addımlar")
        p2 = page(ctx, perm="denied", extra_init=seed)
        p2.goto(PARENT); p2.wait_for_selector(".pushblk .pc-steps", timeout=20000)
        stp = p2.locator(".pushblk .pc-steps").inner_text()
        ok("basın" in stp and "yeniləyin" in stp, "valideyn: addımlar rəsmi formadadır", stp.replace("\n", " | "))
        ok("bloklanıb" in p2.locator("#pushBox").inner_text() and p2.locator("#pushOn").count() == 0, "valideyn: bloklu kart, düymə yox")
        p2.screenshot(path="%s/valideyn_%s_bloklu.png" % (OUT, tag), full_page=True)
        p2.close()

        print("   çıxış: ƏVVƏL abunə silinir, SONRA sessiyalar bağlanır")
        p.click("#pushOn"); p.wait_for_selector("#pushOff", timeout=10000)
        wait_db("select count(*) n from public.push_subs where role='parent'", 2)
        p.click("#btnOut"); p.wait_for_selector("#btnLogin, #code, input", timeout=10000)
        n = wait_db("select count(*) n from public.push_subs", 0)
        ok(n == 0, "çıxışda abunələr silindi", n)
        ok(wait_db("select count(*) n from public.parent_sessions", 0) == 0, "sessiyalar da bağlandı (abunə silinəndən SONRA)")
        ctx.close()

    br.close()

print("\nNETICE:", "HAMISI KECDI" if not fails else "XETALAR: %d" % len(fails))
for f in fails: print(" -", f)
sys.exit(1 if fails else 0)
