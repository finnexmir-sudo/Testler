#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Teqdimat videosu - tetbiqin ozunden, mock uzerinde, KADR-KADR.

Niye kadr-kadr (Playwright-in oz video yazmasi yox)?  Playwright videonu
CSS piksel olcusunde yazir (432x768) - DPR 2.5 tetbiq olunmur, 1080x1920
kadrin dortde biri dolur, qalani boz.  Ekran sekli ise DPR-i tanıyır:
her kadr 1080x1920 keskin PNG, sonra ffmpeg concat ile mp4.

    test/tek.sh _video.py            -> /tmp/claude-0/video/frames + list.txt
    sonra:  python3 test/_video.py --mp4

Uzunluq ~45 s.  Yazilar (caption) sehifeye ozumuz qoyuruq - videoda
gorunur, tetbiqe toxunmur.
"""
import io, os, sys, time, datetime, subprocess
import psycopg2, psycopg2.extras

OUT = "/tmp/claude-0/video"
FR = OUT + ("/frames_carx" if ("--carx" in sys.argv or os.environ.get("VIDEO_CARX") == "1")
            else ("/frames_tam" if ("--tam" in sys.argv or os.environ.get("VIDEO_TAM") == "1") else "/frames"))
FF = "/tmp/claude-0/pylib/imageio_ffmpeg/binaries/ffmpeg-linux-x86_64-v7.0.2"

TAM = "--tam" in sys.argv or os.environ.get("VIDEO_TAM") == "1"
CARX = "--carx" in sys.argv or os.environ.get("VIDEO_CARX") == "1"
NAME = "bil10_carx.mp4" if CARX else ("bil10_teqdimat_tam.mp4" if TAM else "bil10_teqdimat_9x16.mp4")
LIST = OUT + ("/list_carx.txt" if CARX else ("/list_tam.txt" if TAM else "/list.txt"))
if "--mp4" in sys.argv:
    for name, vf, crf in ((NAME, "format=yuv420p", "20"),
                          (NAME.replace(".mp4", "_720.mp4"), "scale=720:1280,format=yuv420p", "24")):
        cmd = [FF, "-y", "-v", "error", "-f", "concat", "-safe", "0", "-i", LIST,
               "-vf", vf, "-r", "30", "-c:v", "libx264", "-preset", "slow", "-crf", crf,
               "-movflags", "+faststart", OUT + "/" + name]
        subprocess.run(cmd, check=True)
        print("hazir:", OUT + "/" + name)
    #  uz sekli - ilk kadr
    first = io.open(LIST, encoding="utf-8").readline().split("'")[1]
    #  poster: ayrica ▶ kadri varsa o, yoxsa ilk kadr
    pst = OUT + ("/poster_carx.png" if CARX else ("/poster_tam.png" if TAM else "/poster.png"))
    if os.path.exists(pst): first = pst
    subprocess.run([FF, "-y", "-v", "error", "-i", first, "-vf", "scale=720:1280", "-q:v", "4", OUT + "/" + NAME.replace(".mp4", "_uz.jpg")], check=True)
    sys.exit(0)

from playwright.sync_api import sync_playwright

DSN = "host=/tmp port=55432 user=postgres dbname=panel_e2e"
BASE = "http://127.0.0.1:8010/"
PANEL, STUDENT = BASE + "muellim/index.html", BASE + "sagird/index.html"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
CFG = """window.CFG = {
  SUPABASE_URL: "http://127.0.0.1:54321",
  SUPABASE_ANON_KEY: "test-anon-key",
  STUDENT_URL: "https://bil10.az/sagird/",
  PARENT_URL:  "https://bil10.az/valideyn/",
  SHOW_PLANS: false
};"""
LOGO = io.open("/tmp/claude-0/shot/logo.svg", encoding="utf-8").read()

os.makedirs(FR, exist_ok=True)
for f in os.listdir(FR): os.remove(FR + "/" + f)

def db(sql, args=None, one=False):
    with psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql, args or ())
        if cur.description:
            return cur.fetchone() if one else cur.fetchall()

db("""delete from public.question_reports; delete from public.parent_sessions;
delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers; delete from public.attempts; delete from public.assignments;
delete from public.student_sessions; delete from public.students; delete from public.classes;
delete from public.test_questions tq using public.tests t where t.id=tq.test_id and t.owner_type='educator';
delete from public.tests where owner_type='educator'; delete from public.subscriptions;
delete from public.account_members; delete from public.accounts; delete from public.user_roles;
delete from public.profiles; delete from auth.users;""")

# ----------------------------------------------------------------- kadrlar
FRAMES = []          # (fayl, muddet)
CAP = {"t": ""}      # cari yazi

CAP_CSS = """
#vcap{position:fixed;left:0;right:0;bottom:0;z-index:2147483000;
  background:rgba(15,23,42,.94);color:#fff;padding:18px 22px 22px;
  font:700 18px/1.35 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;
  border-top:5px solid #ffc94d;letter-spacing:.1px;pointer-events:none}
#vcap.up{top:0;bottom:auto;border-top:0;border-bottom:5px solid #ffc94d}
#vcap small{display:block;font-weight:600;font-size:13px;color:#ffc94d;margin-bottom:5px;letter-spacing:.6px;text-transform:uppercase}
#vtap{position:fixed;z-index:2147483001;border:4px solid #ffc94d;border-radius:50%;
  background:rgba(255,201,77,.28);pointer-events:none;transform:translate(-50%,-50%)}
"""

def ensure_cap(pg):
    pg.evaluate("""([css, t]) => {
      if (!document.getElementById('vcss')) {
        const s = document.createElement('style'); s.id = 'vcss'; s.textContent = css;
        document.head.appendChild(s);
      }
      let c = document.getElementById('vcap');
      if (!t) { if (c) c.remove(); return; }
      if (!c) { c = document.createElement('div'); c.id = 'vcap'; document.body.appendChild(c); }
      const [k, v] = t.indexOf('|') >= 0 ? t.split('|') : ['', t];
      c.innerHTML = (k ? '<small>' + k + '</small>' : '') + v;
    }""", [CAP_CSS, CAP["t"]])

SPEED = float(os.environ.get("VIDEO_SPEED", "2.3"))   # >= 0.3 s dayanmalar bu qeder uzanir
SHORT = float(os.environ.get("VIDEO_SHORT", "1.8"))   # toxunus / yazma kadrlari

def cap(pg, sec):
    sec = sec * SPEED if sec >= 0.3 else sec * SHORT
    ensure_cap(pg)
    n = len(FRAMES) + 1
    f = "%s/%04d.png" % (FR, n)
    pg.screenshot(path=f)
    FRAMES.append((f, sec))

def say(pg, text, sec=0):
    CAP["t"] = text
    if sec: cap(pg, sec)

def tap(pg, sel, hold=0.0):
    """Nisan: dairə böyüyür (3 kadr), sonra klik."""
    el = pg.locator(sel).first
    el.scroll_into_view_if_needed(); pg.wait_for_timeout(120)
    b = el.bounding_box()
    cx, cy = b["x"] + b["width"] / 2, b["y"] + b["height"] / 2
    #  hedef yazinin altindadirsa (alt menyu) yazi yuxari qalxir
    up = pg.evaluate("""y => { const c = document.getElementById('vcap');
        return !!c && y > c.getBoundingClientRect().top - 8; }""", cy)
    if up: pg.evaluate("() => { const c = document.getElementById('vcap'); if (c) c.classList.add('up'); }")
    for r in (18, 34, 52):
        pg.evaluate("""([x,y,r]) => { let d = document.getElementById('vtap');
          if (!d) { d = document.createElement('div'); d.id='vtap'; document.body.appendChild(d); }
          d.style.left = x+'px'; d.style.top = y+'px'; d.style.width = d.style.height = r+'px';
          d.style.opacity = r > 40 ? '.45' : '1'; }""", [cx, cy, r])
        cap(pg, 0.09)
    pg.evaluate("() => { const d = document.getElementById('vtap'); if (d) d.remove(); }")
    el.click()
    if up: pg.evaluate("() => { const c = document.getElementById('vcap'); if (c) c.classList.remove('up'); }")
    if hold: cap(pg, hold)

def scroll(pg, y, n=8, dt=0.07, hold=0.0):
    y0 = pg.evaluate("window.scrollY")
    for i in range(1, n + 1):
        pg.evaluate("y => window.scrollTo(0, y)", y0 + (y - y0) * i / n)
        pg.wait_for_timeout(30); cap(pg, dt)
    if hold: cap(pg, hold)

CARD_CSS = """
#vcard{position:fixed;inset:0;z-index:2147483100;background:#0f172a;color:#fff;
  font-family:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}
#vcard .w{height:100%;display:flex;flex-direction:column;align-items:center;justify-content:center;
  padding-top:26px;padding-bottom:26px;
  text-align:center;padding:0 36px;box-sizing:border-box;
  background:radial-gradient(120% 80% at 50% 0%,#134e4a 0%,#0f172a 60%)}
#vcard .logo{width:132px;height:132px;margin-bottom:26px}
#vcard .logo svg{width:100%;height:100%}
#vcard h1{font-size:54px;margin:0 0 10px;letter-spacing:-.5px;color:#fff}
#vcard h2{font-size:22px;font-weight:600;margin:0;color:#cbd5e1;line-height:1.4}
#vcard .y{color:#ffc94d}
#vcard .pill{margin-top:34px;background:#ffc94d;color:#0f172a;font-weight:800;font-size:20px;
  padding:14px 26px;border-radius:999px}
#vcard .site{font-size:40px;font-weight:800;margin-top:8px;color:#fff}
#vcard .sm{font-size:17px;color:#94a3b8;margin-top:22px;line-height:1.5}
#vcard .k{font-size:15px;font-weight:700;letter-spacing:.12em;text-transform:uppercase;color:#5eead4;margin-bottom:14px}
#vcard .ben{list-style:none;margin:30px 0 0;padding:0;width:100%;max-width:560px;text-align:left}
#vcard .ben li{display:flex;align-items:center;gap:18px;padding:16px 20px;margin-bottom:12px;border-radius:18px;
  background:rgba(255,255,255,.07);border:1px solid rgba(255,255,255,.12);font-size:24px;font-weight:600;line-height:1.3;
  opacity:0;transform:translateY(10px)}
#vcard .ben li.on{opacity:1;transform:none}
#vcard .ben li i{flex:0 0 52px;width:52px;height:52px;border-radius:14px;background:#ffc94d;color:#0f172a;
  display:flex;align-items:center;justify-content:center;font-style:normal;font-size:26px;font-weight:800}
#vcard .ben li s{display:block;text-decoration:none;font-size:16px;font-weight:500;color:#94a3b8;margin-top:2px}
/*  Olculer CSS px-dir: kadr 432x768 (DPR 2.5 -> 1080x1920)  */
#vcard .top{width:100%;text-align:left;padding:0 4px}
#vcard .top .k{margin-bottom:8px}
#vcard .top h1{font-size:25px;line-height:1.15;margin:0 0 6px}
#vcard .top .sm{margin-top:4px;font-size:14px;line-height:1.45}
#vcard .phone{width:80%;height:430px;margin:18px auto 0;border-radius:22px;overflow:hidden;
  border:3px solid #334155;box-shadow:0 18px 40px rgba(0,0,0,.55);background:#fff;flex:0 0 auto}
#vcard .phone img{width:100%;display:block}
#vcard .play{width:150px;height:150px;border-radius:50%;background:#ffc94d;margin:34px auto 0;
  display:flex;align-items:center;justify-content:center;box-shadow:0 20px 60px rgba(0,0,0,.45)}
#vcard .play i{display:block;width:0;height:0;border-left:56px solid #0f172a;border-top:34px solid transparent;
  border-bottom:34px solid transparent;margin-left:12px}
"""

BEN = [("Test 1 dəqiqəyə yığılır", "hazır sual bankından — sinif, fənn, mövzu seçirsiniz", "gen"),
       ("Nəticə özü toplanır", "şagird kodla girir, bal serverdə hesablanır, siz yalnız baxırsınız", "prep"),
       ("Hansı mövzu axsayır — görünür", "hesabat, səhv dəftəri, zəif şagird siqnalı", "rep"),
       ("Valideyn də görür", "uşağının nəticəsi, ev tapşırığı, davamiyyəti — öz telefonunda", "par")]

SHOTS_DIR = OUT + "/shots"

def demo_shots(ctx):
    """Numune hesabin (dolu melumat) real ekranlari - giris kartlarinda
    subut kimi.  EVVELCEDEN cekilibse (test/_demo_shots.py -> OUT/shots)
    fayldan goturulur: video ile eyni gedisde cekende hesabat ekrani
    sonra acilmirdi (iki yigim bosa getdi)."""
    import base64
    keys = ("gen", "prep", "rep", "par")
    if all(os.path.exists("%s/%s.png" % (SHOTS_DIR, k)) for k in keys):
        names = [f[:-4] for f in os.listdir(SHOTS_DIR) if f.endswith(".png")]
        return {k: "data:image/png;base64," + base64.b64encode(open("%s/%s.png" % (SHOTS_DIR, k), "rb").read()).decode("ascii") for k in names}
    db("delete from public.app_state where key='demo_reset'"); db("select public.rpc_demo_reset()")
    #  AYRI kontekst: numune girisi esas sehifenin sessiyasina qarismasin
    #  (eyni kontekstde girisden sonra panel acilir, qeydiyyat ekrani cixmir)
    ctx = ctx.browser.new_context(viewport={"width": 432, "height": 768}, device_scale_factor=2.5)
    p = ctx.new_page()
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    p.route("**://*.supabase.co/**", lambda r: r.abort())
    p.goto(PANEL + "#/demo"); p.wait_for_selector("#demoBar", timeout=60000)
    p.wait_for_selector("#groups .gcard", timeout=30000)
    p.add_style_tag(content="#demoBar{display:none!important}")
    p.locator("#groups .gcard", has_text="7-ci sinif").first.click(); p.wait_for_selector("#gTabs", timeout=15000)
    p.wait_for_function("document.querySelector('#prep .prow')", timeout=20000); p.wait_for_timeout(900)
    gid = p.evaluate("location.hash").split("/")[-1]
    out = {}
    p.evaluate("document.getElementById('prep').scrollIntoView({block:'start'}); window.scrollBy(0,-60)"); p.wait_for_timeout(300)
    out["prep"] = p.screenshot()
    p.evaluate("location.hash = '#/gen'"); p.wait_for_selector("#gsub", timeout=15000); p.wait_for_timeout(900)
    out["gen"] = p.screenshot()
    p.evaluate("location.hash = '#/r/" + gid + "'"); p.wait_for_selector("#rTabs", timeout=15000); p.wait_for_timeout(1200)
    out["rep"] = p.screenshot()
    p.goto(BASE + "valideyn/index.html?kod=VDEMO001"); p.wait_for_selector(".who", timeout=30000); p.wait_for_timeout(900)
    out["par"] = p.screenshot()
    ctx.close()
    import base64
    return {k: "data:image/png;base64," + base64.b64encode(v).decode("ascii") for k, v in out.items()}

def intro(pg, poster_path=None):
    """Reklam carxi kimi giris - her qazanc REAL EKRANLA (numune hesab).
    Vaxt DEQIQ saniyedir (SPEED-e bolunur): kartlar 1x suretde rahat
    oxunur, yavaslatmaga ehtiyac yoxdur (istifadeci: «çarx çox sürətlidir,
    sürəti aşağı salıram, sonra proqram lap çox ləngiyir»)."""
    R = 1.0 / SPEED
    shots = demo_shots(pg.context)
    card(pg, '<div class="logo">' + LOGO + '</div><h1>Bil10</h1>'
             '<h2>Repetitor və müəllim üçün<br><span class="y">onlayn test sistemi</span></h2>', 1.8 * R)
    card(pg, '<div class="k">Hər həftə eyni iş</div>'
             '<h1 style="font-size:46px;line-height:1.15">Test yaz.<br>Yoxla.<br>Nəticəni say.<br>Valideynə de.</h1>', 3.0 * R)
    #  tekrar YOX (istifadeci: «iki dəfə eyni şeyi yazmısan») - yalniz cavab
    card(pg, '<div class="logo">' + LOGO + '</div>'
             '<h1 style="font-size:40px;line-height:1.2">Bil10 bunu<br><span class="y">sizin yerinizə</span> edir.</h1>', 2.6 * R)
    for i, (t, d, key) in enumerate(BEN):
        card(pg, '<div class="top"><div class="k">Müəllim nə qazanır · ' + str(i + 1) + '/4</div>'
                 '<h1>' + t + '</h1>'
                 '<div class="sm">' + d + '</div></div>'
                 '<div class="phone"><img src="' + shots[key] + '" alt=""></div>', 3.0 * R)
    card(pg, '<h1>Necə işləyir?</h1><h2>addım-addım, real ekranlarda</h2><div class="pill">İndi baxaq →</div>', 1.8 * R)
    if poster_path:
        pg.evaluate("""([css, html]) => {
          if (!document.getElementById('vcardcss')) {
            const s = document.createElement('style'); s.id = 'vcardcss'; s.textContent = css;
            (document.head || document.documentElement).appendChild(s);
          }
          let d = document.getElementById('vcard');
          if (!d) { d = document.createElement('div'); d.id = 'vcard'; (document.body || document.documentElement).appendChild(d); }
          d.innerHTML = '<div class="w">' + html + '</div>';
        }""", [CARD_CSS, '<div class="logo">' + LOGO + '</div><h1>Bil10</h1>'
               '<h2>Müəllim nə qazanır?<br><span class="y">addım-addım təqdimat</span></h2>'
               '<div class="play"><i></i></div><div class="sm">səssiz · real ekranlar · bil10.az</div>'])
        pg.wait_for_timeout(250); pg.screenshot(path=poster_path)
        pg.evaluate("() => { const d = document.getElementById('vcard'); if (d) d.remove(); }")

def card(pg, html, sec):
    """Kart - sehifenin USTUNE qoyulur (set_content sessiyani pozurdu)."""
    pg.evaluate("""([css, html]) => {
      if (!document.getElementById('vcardcss')) {
        const s = document.createElement('style'); s.id = 'vcardcss'; s.textContent = css;
        (document.head || document.documentElement).appendChild(s);
      }
      const c = document.getElementById('vcap'); if (c) c.remove();
      let d = document.getElementById('vcard');
      if (!d) { d = document.createElement('div'); d.id = 'vcard'; (document.body || document.documentElement).appendChild(d); }
      d.innerHTML = '<div class="w">' + html + '</div>';
    }""", [CARD_CSS, html])
    pg.wait_for_timeout(250)
    CAP["t"] = ""
    cap(pg, sec)
    pg.evaluate("() => { const d = document.getElementById('vcard'); if (d) d.remove(); }")

CHAPS = []   # (n, basliq, saniye) - sayt oyunçusunda fesil siyahisi

def chap(pg, n, title, sec=1.5):
    CHAPS.append({"n": n, "t": title, "s": round(sum(d for _, d in FRAMES), 1)})
    card(pg, '<div style="font-size:120px;font-weight:800;color:#ffc94d;line-height:1">%d</div>'
             '<h1 style="font-size:40px;margin-top:10px">%s</h1>' % (n, title), sec)

# ----------------------------------------------------------------- axin
def qisa(pg):
    # 0 · basliq karti
    card(pg, '<div class="logo">' + LOGO + '</div><h1>Bil10</h1>'
             '<h2>Müəllim üçün test platforması<br><span class="y">1–11 sinif · bütün fənlər</span></h2>', 2.6)

    # hazirliq (kadrsiz): qeydiyyat, hesab, qrup, sagirdler, abune
    pg.goto(PANEL); pg.wait_for_selector("#btnAuth", timeout=15000)
    pg.click("#btnSwap"); pg.fill("#fname", "Leyla Məmmədova")
    pg.fill("#email", "leyla%d@numune.az" % int(time.time())); pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=15000)
    pg.select_option("#atype", "tutor"); pg.fill("#aname", "Leyla müəllim — riyaziyyat"); pg.click("#btnSetup")
    pg.wait_for_selector("#btnGroup", timeout=15000)
    pg.fill("#gname", "3-cü sinif — şənbə qrupu"); pg.select_option("#glevel", "3"); pg.click("#btnGroup")
    pg.wait_for_selector("#groups .gcard", timeout=15000)
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select a.id, p.id, 'active', now() + interval '30 days'
            from public.accounts a, public.plans p where p.slug = 'repetitor-25'""")
    pg.click("#groups .gcard"); pg.wait_for_selector("#gTabs", timeout=15000)
    for nm in ("Aysu Məmmədova", "Kənan Əliyev", "Nigar Həsənova", "Tural Quliyev"):
        try: pg.wait_for_selector("#sname", state="visible", timeout=3000)
        except Exception: pg.click("#btnStuOpen")
        pg.fill("#sname", nm); pg.click("#btnStu"); pg.wait_for_timeout(600)
    pg.wait_for_selector(".stu .l3 .code", timeout=15000)
    gid = db("select id::text i from public.classes limit 1", one=True)["i"]
    code = db("select login_code c from public.students where full_name='Aysu Məmmədova'", one=True)["c"]

    # 1 · qrup ekrani
    pg.evaluate("window.scrollTo(0,0)"); pg.wait_for_timeout(300)
    say(pg, "MÜƏLLİM|Qrup və şagirdlər — hər şagirdin öz giriş kodu var", 2.6)

    # 2 · test yig
    pg.goto(PANEL + "#/gen"); pg.wait_for_selector("#gsub", timeout=15000); pg.wait_for_timeout(700)
    say(pg, "TEST YIĞ|Fənn, sinif, mövzu — seçirsiniz, qalanını proqram edir", 1.8)
    pg.select_option("#gsub", "riyaziyyat"); pg.wait_for_timeout(900)
    pg.wait_for_selector("#gTop .chip", timeout=15000)
    cap(pg, 0.8)
    chips = pg.locator("#gTop .chip")
    n = min(chips.count(), 2)
    for i in range(n):
        tap(pg, "#gTop .chip >> nth=%d" % i, hold=0.5)
    pg.fill("#gCnt", "10"); pg.wait_for_timeout(500); cap(pg, 0.8)
    pg.evaluate("document.getElementById('btnMake').scrollIntoView({block:'center'})"); pg.wait_for_timeout(200)
    say(pg, "TEST YIĞ|21 000-dən çox hazır sual — 1–11 sinif")
    tap(pg, "#btnMake")
    pg.wait_for_selector(".paper", timeout=20000); pg.wait_for_timeout(500)
    pg.evaluate("window.scrollTo(0,0)")
    pg.fill("#pDate", (datetime.date.today() + datetime.timedelta(days=7)).isoformat())
    pg.select_option("#pTry", "2")
    pg.evaluate("window.scrollTo(0,0)"); pg.wait_for_timeout(150)
    say(pg, "HAZIRDIR|10 sual, bir dəqiqəyə — çap edin və ya telefona göndərin", 2.4)
    scroll(pg, 700, n=10, hold=0.9)
    pg.evaluate("document.getElementById('btnPAsg').scrollIntoView({block:'center'})"); pg.wait_for_timeout(200)
    say(pg, "TƏYİN ET|Son tarix, cəhd sayı — və qrupa göndər", 1.4)
    tap(pg, "#btnPAsg")
    pg.wait_for_selector(".pgiven", timeout=15000); pg.wait_for_timeout(400)
    pg.evaluate("document.querySelector('.pgiven').scrollIntoView({block:'center'})"); pg.wait_for_timeout(200)
    say(pg, "TƏYİN ET|Göndərildi — şagird telefonunda görür", 2.2)

    # 3 · sagird
    tid = db("select id::text i from public.tests where owner_type='educator' order by created_at desc limit 1", one=True)["i"]
    key = {r["o"] for r in db("""select o.id::text o from public.question_options o
        join public.test_questions tq on tq.question_id = o.question_id
        where tq.test_id = %s and o.is_correct""", (tid,))}
    #  Sehvler BIR movzuya yigilir - hesabatda heqiqi «zeif movzu» cixsin.
    #  Ikinci movzudan (say uzre az olan) 3 sual sehv, qalani duz -> ~70 %.
    rows = db("""select o.id::text o, q.topic_id::text t from public.question_options o
        join public.questions q on q.id = o.question_id
        join public.test_questions tq on tq.question_id = q.id where tq.test_id = %s""", (tid,))
    O2T = {r["o"]: r["t"] for r in rows}
    tcount = {}
    for r in db("select q.topic_id::text t, count(*) n from public.questions q join public.test_questions tq on tq.question_id=q.id where tq.test_id=%s group by 1", (tid,)):
        tcount[r["t"]] = r["n"]
    weak_t = min(tcount, key=lambda t: (tcount[t] < 3, -tcount[t]))   # >=3 suali olan en kicik movzu
    wrong_left = {"n": min(3, tcount[weak_t])}
    pg.goto(STUDENT); pg.wait_for_selector("#btnIn", timeout=15000); pg.wait_for_timeout(400)
    say(pg, "ŞAGİRD|Kodla girir — parol, e-poçt lazım deyil", 1.2)
    for i in range(1, len(code) + 1):
        pg.fill("#code", code[:i]); cap(pg, 0.11)
    cap(pg, 0.6)
    tap(pg, "#btnIn")
    pg.wait_for_selector(".test.asg", timeout=15000); pg.wait_for_timeout(400)
    say(pg, "ŞAGİRD|Tapşırıq gəlib — son tarixi də görür", 2.0)
    tap(pg, ".test.asg >> nth=0")
    pg.wait_for_selector(".opt", timeout=15000); pg.wait_for_timeout(400)
    say(pg, "ŞAGİRD|Telefonda həll edir", 1.4)
    qi = 0
    while True:
        ids = pg.locator(".opt").evaluate_all("els => els.map(e => e.getAttribute('data-o'))")
        want = next((o for o in ids if o in key), ids[0])
        if O2T.get(ids[0]) == weak_t and wrong_left["n"] > 0:
            wrong_left["n"] -= 1; want = next((o for o in ids if o not in key), ids[0])
        if qi < 2:
            tap(pg, "[data-o='%s']" % want, hold=0.7)
        else:
            pg.locator("[data-o='%s']" % want).click(); pg.wait_for_timeout(80)
        pg.wait_for_timeout(2600)   # kadrsiz: sagirdin dusunme vaxti (videoya dusmur)
        if pg.locator("#btnNext").count() and pg.locator("#btnNext").is_visible():
            if qi < 2: tap(pg, "#btnNext", hold=0.35)
            else: pg.click("#btnNext"); pg.wait_for_timeout(90)
            qi += 1
        else:
            pg.once("dialog", lambda d: d.accept())
            say(pg, "ŞAGİRD|Bitir — nəticə dərhal")
            tap(pg, "#btnFinish"); break
    pg.wait_for_selector(".ring", timeout=15000); pg.wait_for_timeout(600)
    pg.evaluate("window.scrollTo(0,0)")
    say(pg, "NƏTİCƏ|Özü yoxlanır — hansı mövzu zəifdir, hər sualın izahı", 2.6)
    h = pg.evaluate("document.body.scrollHeight")
    scroll(pg, min(h - 768, 1100), n=12, hold=1.2)

    # 4 · muellim hesabat
    pg.goto(PANEL + "#/r/" + gid); pg.wait_for_selector("#rTabs", timeout=15000); pg.wait_for_timeout(900)
    say(pg, "MÜƏLLİM|Hesabat özü yığılır — kim işləyib, neçə faiz", 1.8)
    tap(pg, "#rTabs .seg:has-text('Mövzular')")
    pg.wait_for_timeout(700)
    say(pg, "MÜƏLLİM|Zəif mövzular göz qabağında — təkrar test bir düymədir", 3.0)

    # 5 · son kart
    card(pg, '<div class="logo">' + LOGO + '</div><div class="site">bil10.az</div>'
             '<h2>Test hazırlamaq — <span class="y">1 dəqiqə</span><br>Yoxlamaq — <span class="y">0 dəqiqə</span></h2>'
             '<div class="pill">Şagird və valideyn üçün pulsuz</div>'
             '<div class="sm">Nümunəyə baxın — qeydiyyatsız<br>bil10.az</div>', 3.6)

def tam(pg):
    """Her ekrana GORUNEN toxunusla girilir - goto yalniz tetbiq deyisende
    (sagird / valideyn).  Yazinin ust setri YOL-dur: harada oldugunu deyir."""
    PARENT = BASE + "valideyn/index.html"
    NAV = {"b": "#bnav a[href='#/b']", "gen": "#bnav a[href='#/gen']", "home": "#bnav a[href='#/']"}
    intro(pg, OUT + "/poster_tam.png")

    # hazirliq (kadrsiz)
    pg.goto(PANEL); pg.wait_for_selector("#btnAuth", timeout=15000)
    pg.click("#btnSwap"); pg.fill("#fname", "Leyla Məmmədova")
    pg.fill("#email", "leyla%d@numune.az" % int(time.time())); pg.fill("#pass", "parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup", timeout=15000)
    pg.select_option("#atype", "tutor"); pg.fill("#aname", "Leyla müəllim — riyaziyyat"); pg.click("#btnSetup")
    pg.wait_for_selector("#btnGroup", timeout=15000)
    pg.fill("#gname", "3-cü sinif — şənbə qrupu"); pg.select_option("#glevel", "3"); pg.click("#btnGroup")
    pg.wait_for_selector("#groups .gcard", timeout=15000)
    db("""insert into public.subscriptions (account_id, plan_id, status, current_period_end)
          select a.id, p.id, 'active', now() + interval '30 days'
            from public.accounts a, public.plans p where p.slug = 'repetitor-25'""")
    pg.click("#groups .gcard"); pg.wait_for_selector("#gTabs", timeout=15000)
    for nm in ("Aysu Məmmədova", "Kənan Əliyev", "Nigar Həsənova"):
        try: pg.wait_for_selector("#sname", state="visible", timeout=3000)
        except Exception: pg.click("#btnStuOpen")
        pg.fill("#sname", nm); pg.click("#btnStu"); pg.wait_for_timeout(600)
    pg.wait_for_selector(".stu .l3 .code", timeout=15000)
    gid = db("select id::text i from public.classes limit 1", one=True)["i"]
    code = db("select login_code c from public.students where full_name='Aysu Məmmədova'", one=True)["c"]
    pcode = db("select parent_code c from public.students where full_name='Aysu Məmmədova'", one=True)["c"]
    sid = db("select id::text i from public.students where full_name='Aysu Məmmədova'", one=True)["i"]

    # ---- 1 · ICMAL -> QRUP
    chap(pg, 1, "Qrup və şagirdlər")
    pg.goto(PANEL + "#/"); pg.wait_for_selector("#groups .gcard", timeout=15000); pg.wait_for_timeout(600)
    pg.evaluate("window.scrollTo(0,0)")
    say(pg, "İCMAL|Girişdən sonra ilk ekran — qruplarınız burada. Qrupa toxunuruq", 2.4)
    tap(pg, "#groups .gcard")
    pg.wait_for_selector("#gTabs", timeout=15000); pg.wait_for_timeout(600)
    say(pg, "İCMAL › QRUP|Qrup ekranı: şagirdlər, dərs planı, dəftər — üç sekmə", 2.4)
    try: pg.wait_for_selector("#sname", state="visible", timeout=2000)
    except Exception: tap(pg, "#btnStuOpen", hold=0.5)
    pg.evaluate("document.getElementById('sname').scrollIntoView({block:'center'})"); pg.wait_for_timeout(200)
    say(pg, "QRUP › ŞAGİRDLƏR|Yeni şagird: adını yazırsınız — vəssalam")
    nm = "Tural Quliyev"
    for i in range(1, len(nm) + 1):
        pg.fill("#sname", nm[:i]); cap(pg, 0.05)
    cap(pg, 0.6)
    tap(pg, "#btnStu"); pg.wait_for_timeout(900)
    pg.wait_for_selector(".stu .l3 .code", timeout=15000)
    say(pg, "QRUP › ŞAGİRDLƏR|Giriş kodu və valideyn kodu özü yaranır — «Göndər» ilə WhatsApp-a", 3.2)
    scroll(pg, 500, n=8, hold=1.0)

    # ---- 2 · alt menyu -> SUALLAR
    chap(pg, 2, "Sual bankı")
    say(pg, "QRUP|Alt menyudan «Suallar»a keçirik", 1.2)
    tap(pg, NAV["b"])
    pg.wait_for_selector("#bFilt", timeout=15000); pg.wait_for_timeout(1500)
    say(pg, "SUALLAR|21 000-dən çox hazır sual — 1–11 sinif, bütün fənlər. Hər sualda izah var", 2.8)
    if pg.locator("details.filt").count():
        tap(pg, "details.filt summary", hold=0.5)
    pg.wait_for_selector("#bsub", state="visible", timeout=15000)
    say(pg, "SUALLAR › SÜZGƏC|Fənn, sinif, çətinlik, mövzu — istədiyinizi tapırsınız")
    pg.select_option("#bsub", "riyaziyyat"); pg.wait_for_timeout(1400); cap(pg, 1.6)
    scroll(pg, 650, n=8, hold=1.4)
    pg.evaluate("window.scrollTo(0,0)"); pg.wait_for_timeout(200)
    say(pg, "SUALLAR|Öz sualınızı da yaza bilərsiniz — «Yeni sual»", 1.2)
    tap(pg, "#btnNewQ")
    pg.wait_for_selector("#qbody", timeout=15000); pg.wait_for_timeout(500)
    say(pg, "SUALLAR › YENİ SUAL|Sual, variantlar, düzgün cavab, izah — və şablon", 1.4)
    txt = "{a} + {b} neçə edər?"
    for i in range(1, len(txt) + 1):
        pg.fill("#qbody", txt[:i]); cap(pg, 0.05)
    pg.locator(".obody").nth(0).fill("{a+b}"); cap(pg, 0.6)
    pg.locator(".obody").nth(1).fill("{a+b+10}"); cap(pg, 0.6)
    pg.locator("details.more summary", has_text="Şablon").click(); pg.wait_for_timeout(300)
    pg.fill("#qpar", "a = 100..999, b = 100..999; şərt: a > b"); cap(pg, 1.2)
    say(pg, "YENİ SUAL › ŞABLON|{a}, {b} — hər çapda, hər şagirdə başqa rəqəm. Köçürmək mümkün deyil")
    tap(pg, "#qparTry")
    pg.wait_for_selector("#qparOut .qsample", timeout=15000); pg.wait_for_timeout(400)
    pg.evaluate("document.querySelector('#qparOut').scrollIntoView({block:'center'})"); pg.wait_for_timeout(200)
    cap(pg, 3.2)

    # ---- 3 · alt menyu -> TEST YIG
    chap(pg, 3, "Test və ev tapşırığı")
    say(pg, "YENİ SUAL|Alt menyudan «Test yığ»a keçirik", 1.2)
    tap(pg, NAV["gen"])
    pg.wait_for_selector("#gsub", timeout=15000); pg.wait_for_timeout(700)
    say(pg, "TEST YIĞ|Fənn, sinif, çətinlik, mövzu — seçirsiniz, qalanını proqram edir", 2.2)
    pg.select_option("#gsub", "riyaziyyat"); pg.wait_for_timeout(900)
    pg.wait_for_selector("#gTop .chip", timeout=15000); cap(pg, 1.0)
    say(pg, "TEST YIĞ|Mövzuları toxunuşla seçirsiniz — iki mövzu, bərabər paylanır")
    for i in range(min(pg.locator("#gTop .chip").count(), 2)):
        tap(pg, "#gTop .chip >> nth=%d" % i, hold=0.6)
    pg.fill("#gCnt", "10"); pg.wait_for_timeout(400); cap(pg, 0.9)
    pg.evaluate("document.getElementById('btnMake').scrollIntoView({block:'center'})"); pg.wait_for_timeout(200)
    say(pg, "TEST YIĞ|Sual sayı 10 — «Testi yığ»")
    tap(pg, "#btnMake")
    pg.wait_for_selector(".paper", timeout=20000); pg.wait_for_timeout(500)
    pg.fill("#pDate", (datetime.date.today() + datetime.timedelta(days=7)).isoformat())
    pg.select_option("#pTry", "2")
    pg.evaluate("window.scrollTo(0,0)"); pg.wait_for_timeout(150)
    say(pg, "TEST YIĞ › VƏRƏQ|Hazırdır: çap / PDF, cavab açarı ilə və ya açarsız, yığcam", 3.0)
    scroll(pg, 700, n=10, hold=1.2)
    pg.evaluate("document.getElementById('btnPAsg').scrollIntoView({block:'center'})"); pg.wait_for_timeout(200)
    say(pg, "VƏRƏQ › TƏYİN ET|Bütün qrupa və ya tək şagirdə · son tarix · cəhd sayı", 2.0)
    tap(pg, "#btnPAsg")
    pg.wait_for_selector(".pgiven", timeout=15000); pg.wait_for_timeout(400)
    pg.evaluate("document.querySelector('.pgiven').scrollIntoView({block:'center'})"); pg.wait_for_timeout(200)
    say(pg, "VƏRƏQ › TƏYİN ET|Göndərildi — şagird telefonunda görür", 2.2)
    tid = db("select id::text i from public.tests where owner_type='educator' order by created_at desc limit 1", one=True)["i"]

    # ---- 3b · EV TAPSIRIGI (metnle): Icmal -> qrup -> Tapsiriqlar
    say(pg, "VƏRƏQ|Test deyil, sadəcə «bunu oxu» demək lazımdır? Alt menyudan «İcmal» → qrup", 1.4)
    tap(pg, NAV["home"])
    pg.wait_for_selector("#groups .gcard", timeout=15000); pg.wait_for_timeout(400)
    tap(pg, "#groups .gcard")
    pg.wait_for_selector("#btnAsgs", timeout=15000); pg.wait_for_timeout(300)
    pg.evaluate("window.scrollTo(0,0)"); pg.wait_for_timeout(150)
    say(pg, "QRUP|«Tapşırıqlar» düyməsi")
    tap(pg, "#btnAsgs")
    pg.wait_for_selector("#hwText", timeout=15000); pg.wait_for_timeout(300)
    pg.evaluate("document.getElementById('hwForm').scrollIntoView({block:'center'})"); pg.wait_for_timeout(250)
    say(pg, "QRUP › TAPŞIRIQLAR › EV TAPŞIRIĞI|Mətnlə: «bunu oxu, bunu təkrarla» — şagird siyahısında görür, valideyn də", 2.2)
    txt = "12-ci paraqrafı oxu, çalışma 3–5-i dəftərdə həll et"
    for i in range(1, len(txt) + 1):
        pg.fill("#hwText", txt[:i]); cap(pg, 0.04)
    pg.fill("#hwDue", (datetime.date.today() + datetime.timedelta(days=3)).isoformat()); cap(pg, 0.9)
    say(pg, "EV TAPŞIRIĞI|Son tarix — və «Tapşırıq yaz»")
    tap(pg, "#btnHwAdd")
    pg.wait_for_selector("#hwList .hwrow", timeout=15000); pg.wait_for_timeout(400)
    pg.evaluate("document.getElementById('hwList').scrollIntoView({block:'center'})"); pg.wait_for_timeout(250)
    say(pg, "EV TAPŞIRIĞI|Yazıldı. Kim etdi, kim etmədi — burada görünəcək", 2.6)

    # ---- 4 · alt menyu -> ICMAL -> QRUP -> DERS PLANI
    chap(pg, 4, "Dərs planı")
    lev = db("select l.code c from public.classes c join public.levels l on l.id=c.level_id limit 1", one=True)["c"]
    say(pg, "TEST YIĞ|Alt menyudan «İcmal»a qayıdırıq", 1.0)
    tap(pg, NAV["home"])
    pg.wait_for_selector("#groups .gcard", timeout=15000); pg.wait_for_timeout(500)
    say(pg, "İCMAL|Qrupa toxunuruq")
    tap(pg, "#groups .gcard")
    pg.wait_for_selector("#gTabs", timeout=15000); pg.wait_for_timeout(400)
    say(pg, "QRUP|«Dərs planı» sekməsi")
    tap(pg, "#gTabs [data-v='p']")
    pg.wait_for_selector("#btnPlOpen", timeout=15000); pg.wait_for_timeout(400)
    say(pg, "QRUP › DƏRS PLANI|Kurikulum üzrə mövzu ardıcıllığı — bir düymə ilə qurulur", 1.6)
    tap(pg, "#btnPlOpen")
    pg.wait_for_function("document.querySelectorAll('#plSub option').length > 1", timeout=15000)
    pg.select_option("#plSub", "riyaziyyat"); pg.select_option("#plLev", lev); cap(pg, 1.0)
    tap(pg, "#btnPlMk")
    pg.wait_for_selector(".plcur [data-pldone]", timeout=15000); pg.wait_for_timeout(500)
    say(pg, "QRUP › DƏRS PLANI|Plan hazırdır. Hər dərsdən sonra «keçildi» — plan özü irəliləyir", 2.8)
    tap(pg, "[data-pldone] >> nth=0")
    pg.wait_for_selector(".ploffer", timeout=15000)
    pg.wait_for_function("document.querySelector('#prep .prep') && document.querySelector('#prep .prep').textContent.indexOf('Son keçilən') >= 0", timeout=15000)
    pg.evaluate("document.getElementById('prep').scrollIntoView({block:'start'})"); pg.wait_for_timeout(400)
    say(pg, "DƏRS PLANI › BU GÜNÜN DƏRSİ|Son keçilən, növbəti mövzu, hazır test təklifi — dərsdən əvvəl bir baxış", 3.4)
    pg.evaluate("document.querySelector('a.plpack').scrollIntoView({block:'center'})"); pg.wait_for_timeout(200)
    say(pg, "DƏRS PLANI|«Dərs paketi» keçidi")
    tap(pg, "a.plpack")
    pg.wait_for_selector(".pktab", timeout=15000); pg.wait_for_timeout(600)
    say(pg, "DƏRS PLANI › DƏRS PAKETİ|Hər mövzu üçün: isinmə testi, ev tapşırığı, rüb sınağı — bir yerdə", 2.6)
    tap(pg, ".pkr >> nth=0 >> [data-pkwarm]")
    pg.wait_for_selector("#pkMsg .ok", timeout=30000); pg.wait_for_timeout(400)
    say(pg, "DƏRS PAKETİ|İsinmə testi yığıldı və qrupa verildi — dərsin ilk 5 dəqiqəsi hazırdır", 2.8)

    # ---- 5 · geri -> QRUP -> DEFTER
    chap(pg, 5, "Dəftər")
    say(pg, "DƏRS PAKETİ|«Geri» — qrupa qayıdırıq", 1.0)
    tap(pg, "#btnBack")
    pg.wait_for_selector("#gTabs", timeout=15000); pg.wait_for_timeout(400)
    say(pg, "QRUP|«Dəftər» sekməsi")
    tap(pg, "#gTabs [data-v='d']")
    pg.wait_for_selector("#schFold", timeout=15000); pg.wait_for_timeout(300)
    pg.eval_on_selector("#schFold", "e => e.open = true"); pg.wait_for_timeout(300)
    say(pg, "QRUP › DƏFTƏR|Həftəlik cədvəl — hansı gün, hansı saat", 1.4)
    tap(pg, "#schDays [data-w='3']", hold=0.4)
    pg.select_option("#schTimes [data-t='3']", "16:00"); cap(pg, 0.5)
    tap(pg, "#schDays [data-w='6']", hold=0.4)
    pg.select_option("#schTimes [data-t='6']", "11:00"); cap(pg, 0.6)
    tap(pg, "#schSave"); pg.wait_for_timeout(1500)
    pg.eval_on_selector("#schFold", "e => e.open = false"); pg.wait_for_timeout(200)
    pg.wait_for_selector("#ledOpen", timeout=15000)
    pg.evaluate("document.getElementById('ledOpen').scrollIntoView({block:'center'})"); pg.wait_for_timeout(200)
    say(pg, "QRUP › DƏFTƏR|Bu gün dərs oldu — kim gəldi, kim gəlmədi", 1.2)
    tap(pg, "#ledOpen")
    pg.wait_for_selector("#ledChips [data-st]", timeout=15000); cap(pg, 1.0)
    tap(pg, "#ledChips [data-st] >> nth=2", hold=0.6)
    tap(pg, "#ledSave")
    pg.wait_for_selector("#ledEdit", timeout=15000); pg.wait_for_timeout(300)
    say(pg, "QRUP › DƏFTƏR|Ödəniş qeydi — bir toxunuşla. Valideyn öz tətbiqində görür", 1.2)
    tap(pg, "[data-pay] >> nth=0")
    pg.wait_for_selector(".pay.on", timeout=15000); pg.wait_for_timeout(400)
    pg.evaluate("document.getElementById('ledgerBox').scrollIntoView({block:'start'})"); pg.wait_for_timeout(200)
    cap(pg, 3.0)

    # ---- 6 · SAGIRD TETBIQI
    chap(pg, 6, "Şagird tətbiqi")
    key = {r["o"] for r in db("""select o.id::text o from public.question_options o
        join public.test_questions tq on tq.question_id = o.question_id
        where tq.test_id = %s and o.is_correct""", (tid,))}
    rows = db("""select o.id::text o, q.topic_id::text t from public.question_options o
        join public.questions q on q.id = o.question_id
        join public.test_questions tq on tq.question_id = q.id where tq.test_id = %s""", (tid,))
    O2T = {r["o"]: r["t"] for r in rows}
    tcount = {}
    for r in db("select q.topic_id::text t, count(*) n from public.questions q join public.test_questions tq on tq.question_id=q.id where tq.test_id=%s group by 1", (tid,)):
        tcount[r["t"]] = r["n"]
    weak_t = min(tcount, key=lambda t: (tcount[t] < 3, -tcount[t]))
    wrong_left = {"n": min(3, tcount[weak_t])}
    db("update public.tests set status='draft' where slug='riy-3-analiz'")
    pg.goto(STUDENT); pg.wait_for_selector("#btnIn", timeout=15000); pg.wait_for_timeout(400)
    say(pg, "ŞAGİRD TƏTBİQİ|Şagird öz telefonunda bil10.az/sagird açır — kodla girir. Parol, e-poçt, qeydiyyat yoxdur", 2.0)
    for i in range(1, len(code) + 1):
        pg.fill("#code", code[:i]); cap(pg, 0.1)
    cap(pg, 0.6)
    tap(pg, "#btnIn")
    pg.wait_for_selector(".test.asg", timeout=15000); pg.wait_for_timeout(400)
    say(pg, "ŞAGİRD › TAPŞIRIQLAR|Üstdə müəllimin yazdığı ev tapşırığı, altda testlər — son tarix, cəhd sayı", 2.6)
    if pg.locator("[data-hw]").count():
        say(pg, "ŞAGİRD › TAPŞIRIQLAR|Oxudu — «Etdim». Müəllim və valideyn dərhal görür")
        tap(pg, "[data-hw] >> nth=0")
        pg.wait_for_selector(".hwr.done", state="attached", timeout=15000); pg.wait_for_timeout(500)
        cap(pg, 2.0)
    tap(pg, ".test.asg:has-text('10 sual') >> nth=0")
    pg.wait_for_selector(".opt", timeout=15000); pg.wait_for_timeout(400)
    say(pg, "ŞAGİRD › TEST|Telefonda həll edir — «Əmin deyiləm» nişanı da var", 1.6)
    qi = 0
    while True:
        ids = pg.locator(".opt").evaluate_all("els => els.map(e => e.getAttribute('data-o'))")
        want = next((o for o in ids if o in key), ids[0])
        if O2T.get(ids[0]) == weak_t and wrong_left["n"] > 0:
            wrong_left["n"] -= 1; want = next((o for o in ids if o not in key), ids[0])
        if qi < 2: tap(pg, "[data-o='%s']" % want, hold=0.8)
        else: pg.locator("[data-o='%s']" % want).click(); pg.wait_for_timeout(80)
        pg.wait_for_timeout(2400)
        if pg.locator("#btnNext").count() and pg.locator("#btnNext").is_visible():
            if qi < 2: tap(pg, "#btnNext", hold=0.4)
            else: pg.click("#btnNext"); pg.wait_for_timeout(90)
            qi += 1
        else:
            pg.once("dialog", lambda d: d.accept())
            say(pg, "ŞAGİRD › TEST|«Testi bitir» — nəticə dərhal")
            tap(pg, "#btnFinish"); break
    pg.wait_for_selector(".ring", timeout=15000); pg.wait_for_timeout(600)
    pg.evaluate("window.scrollTo(0,0)")
    say(pg, "ŞAGİRD › NƏTİCƏ|Özü yoxlanır — faiz, vaxt, hər səhvin izahı. Müəllim eyni anda görür", 3.0)
    h = pg.evaluate("document.body.scrollHeight")
    scroll(pg, min(h - 768, 1100), n=12, hold=1.4)
    pg.click("#btnHome"); pg.wait_for_selector(".test", timeout=15000); pg.wait_for_timeout(600)
    try:
        pg.wait_for_selector("#mistBox h2", timeout=6000)
        pg.evaluate("document.querySelector('#mistBox').scrollIntoView({block:'start'})"); pg.wait_for_timeout(300)
        say(pg, "ŞAGİRD › SƏHV DƏFTƏRİ|Səhv etdiyi sual bir neçə gün sonra yenidən gəlir — unutmasın", 3.0)
    except Exception:
        pass
    pg.wait_for_selector("#adBox .arow", timeout=15000)
    pg.evaluate("document.querySelector('#adBox').scrollIntoView({block:'start'})"); pg.wait_for_timeout(300)
    say(pg, "ŞAGİRD › MÖVZU MƏŞQİ|Zəif mövzudan avtomatik məşq — müəllimsiz, hər gün", 1.8)
    tap(pg, "#adBox .arow >> nth=0")
    pg.wait_for_selector(".adprog", timeout=15000); pg.wait_for_timeout(500)
    cap(pg, 2.6)
    pg.click("#btnBack"); pg.wait_for_selector(".test", timeout=15000)

    # ---- 7 · MUELLIM: ICMAL -> QRUP -> SAGIRD -> DIAQNOSTIKA
    chap(pg, 7, "Diaqnostika")
    pg.goto(PANEL + "#/"); pg.wait_for_selector("#groups .gcard", timeout=15000); pg.wait_for_timeout(500)
    say(pg, "MÜƏLLİM › İCMAL|Yeni şagird gəldi — bilik səviyyəsi nədir? Qrupa girib şagirdi seçirik", 1.6)
    tap(pg, "#groups .gcard")
    pg.wait_for_selector("#gTabs", timeout=15000); pg.wait_for_timeout(400)
    #  qrup ekrani son sekmeni (Defter) yadda saxlayir - Sagirdler sekmesine kecirik
    tap(pg, "#gTabs [data-v='s']", hold=0.4)
    pg.wait_for_selector("[data-rep]", timeout=15000)
    pg.evaluate("document.querySelector('[data-rep]').scrollIntoView({block:'center'})"); pg.wait_for_timeout(200)
    say(pg, "QRUP › ŞAGİRDLƏR|Aysu — «Hesabat»")
    tap(pg, "[data-rep] >> nth=0")
    pg.wait_for_selector("#dgGo", timeout=15000); pg.wait_for_timeout(500)
    pg.evaluate("document.getElementById('dgGo').scrollIntoView({block:'center'})"); pg.wait_for_timeout(200)
    say(pg, "ŞAGİRD KARTI › DİAQNOSTİKA|Bir test, fənnin bütün fəsilləri — 12 mövzu, 7 gün", 2.0)
    pg.select_option("#dgSub", "riyaziyyat"); cap(pg, 0.6)
    tap(pg, "#dgGo")
    pg.wait_for_selector("#diagBox:has-text('Gözlənilir')", timeout=20000); pg.wait_for_timeout(300)
    say(pg, "ŞAGİRD KARTI › DİAQNOSTİKA|Verildi — şagird həll edənə qədər «gözlənilir»", 1.6)
    dt = db("select id::text i from public.tests where is_diagnostic order by created_at desc limit 1", one=True)["i"]
    drows = db("""select o.id::text oid, q.id::text qid, o.is_correct c,
                        dense_rank() over (order by tp.sort, tp.name) rk
                   from public.test_questions tq
                   join public.questions q on q.id = tq.question_id
                   join public.topics tp on tp.id = q.topic_id
                   join public.question_options o on o.question_id = q.id
                  where tq.test_id = %s""", (dt,))
    O2Q = {r["oid"]: r["qid"] for r in drows}; QRK = {r["qid"]: r["rk"] for r in drows}
    CORR = {r["oid"] for r in drows if r["c"]}
    wl = {1: 3, 3: 2, 5: 1}
    pg.goto(STUDENT); pg.wait_for_selector(".test", timeout=15000); pg.wait_for_timeout(300)
    say(pg, "ŞAGİRD TƏTBİQİ|Diaqnostika şagirdə gəlir — həll edir", 1.4)
    tap(pg, ".test.asg:has-text('Diaqnostika') >> nth=0")
    pg.wait_for_selector(".opt", timeout=15000)
    while True:
        ids = pg.locator(".opt").evaluate_all("els => els.map(e => e.getAttribute('data-o'))")
        rk = QRK.get(O2Q.get(ids[0]))
        if wl.get(rk, 0) > 0:
            wl[rk] -= 1; want = next(o for o in ids if o not in CORR)
        else:
            want = next(o for o in ids if o in CORR)
        pg.locator("[data-o='%s']" % want).click(); pg.wait_for_timeout(60)
        if pg.locator("#btnNext").count() and pg.locator("#btnNext").is_visible():
            pg.click("#btnNext"); pg.wait_for_timeout(80)
        else:
            pg.once("dialog", lambda d: d.accept()); pg.click("#btnFinish"); break
    pg.wait_for_selector(".ring", timeout=15000); pg.wait_for_timeout(500)
    y = pg.evaluate("""() => { const h = [...document.querySelectorAll('h2')].find(e => /xərit/i.test(e.textContent));
        return h ? h.getBoundingClientRect().top + window.scrollY - 12 : 0; }""")
    pg.evaluate("y => window.scrollTo(0, y)", y); pg.wait_for_timeout(300)
    say(pg, "ŞAGİRD › MÖVZU XƏRİTƏSİ|Hansı fəsil zəif, hansı möhkəm — şagird özü görür", 3.2)
    pg.goto(PANEL + "#/s/" + sid + "/" + gid); pg.wait_for_selector("#dgMap", timeout=15000); pg.wait_for_timeout(500)
    pg.evaluate("document.getElementById('diagBox').scrollIntoView({block:'start'})"); pg.wait_for_timeout(300)
    say(pg, "MÜƏLLİM › ŞAGİRD KARTI|Eyni xəritə müəllimdə — «bundan başla» proqram özü deyir", 3.2)

    # ---- 8 · geri -> QRUP -> HESABAT -> SAGIRD KARTI
    chap(pg, 8, "Hesabat")
    say(pg, "ŞAGİRD KARTI|«Geri» — qrupun hesabatına", 0.9)
    tap(pg, "#btnB")
    #  «Geri» tarixce ile gedir (geri duymesi, 14.09); bos tarixcede
    #  ehtiyat unvan hesabatdir - yene de acilmasa birbasa acilir
    try: pg.wait_for_selector("#rTabs", timeout=30000)
    except Exception:
        pg.goto(PANEL + "#/r/" + gid); pg.wait_for_selector("#rTabs", timeout=30000)
    pg.wait_for_timeout(900)
    pg.evaluate("window.scrollTo(0,0)"); pg.wait_for_timeout(150)
    say(pg, "QRUP › HESABAT|Özü yığılır: kim işləyib, neçə faiz, «nə etməli bu həftə»", 2.6)
    tap(pg, "#rTabs .seg:has-text('Mövzular')"); pg.wait_for_timeout(700)
    say(pg, "HESABAT › MÖVZULAR|Zəif mövzular — «bu mövzudan test yığ» bir düymədir", 2.8)
    tap(pg, "#rTabs .seg:has-text('Fəaliyyət')"); pg.wait_for_timeout(700)
    say(pg, "HESABAT › FƏALİYYƏT|Kim nə vaxt işləyib", 1.8)
    tap(pg, "#rTabs .seg:has-text('Şagirdlər')"); pg.wait_for_timeout(500)
    say(pg, "HESABAT › ŞAGİRDLƏR|Şagirdə toxunuruq — kartı açılır")
    tap(pg, "[data-s] >> nth=0")
    pg.wait_for_selector("#dgMap", timeout=15000); pg.wait_for_timeout(600)
    pg.evaluate("window.scrollTo(0,0)")
    say(pg, "HESABAT › ŞAGİRD KARTI|Bir şagird — dinamika, zəif mövzular, davamiyyət, gözləyən tapşırıq", 2.6)
    scroll(pg, 600, n=8, hold=1.2)

    # ---- 9 · alt menyu -> ICMAL
    chap(pg, 9, "İcmal — hər açılışda")
    db("""insert into public.attempts (student_id, test_id, status, percent, finished_at)
          select s.id, (select id from public.tests order by created_at limit 1), 'submitted',
                 62 + ((row_number() over (order by s.full_name) * 7 + g * 11) %% 34),
                 now() - (g || ' days')::interval
            from public.students s cross join generate_series(1, 3) g where s.is_active""")
    say(pg, "ŞAGİRD KARTI|Alt menyudan «İcmal»", 0.9)
    tap(pg, NAV["home"])
    pg.wait_for_selector("#hTop5 .lrow", timeout=20000); pg.wait_for_timeout(900)
    pg.evaluate("window.scrollTo(0,0)")
    say(pg, "İCMAL|Bu günün dərsi, təhlükə zonası, son nəticələr, liderlər — hər girişdə bir baxış", 2.8)
    y = pg.evaluate("document.getElementById('hTop5').getBoundingClientRect().top + window.scrollY - 60")
    scroll(pg, y, n=10, hold=2.6)

    # ---- 10 · VALIDEYN
    chap(pg, 10, "Valideyn tətbiqi")
    pg.goto(PARENT); pg.wait_for_selector("#code", timeout=15000); pg.wait_for_timeout(400)
    say(pg, "VALİDEYN TƏTBİQİ|Valideyn bil10.az/valideyn açır — kodu müəllimdən alıb. Pulsuz", 1.6)
    for i in range(1, len(pcode) + 1):
        pg.fill("#code", pcode[:i]); cap(pg, 0.1)
    cap(pg, 0.5)
    tap(pg, "#btnIn")
    pg.wait_for_selector(".who", timeout=15000); pg.wait_for_timeout(700)
    say(pg, "VALİDEYN|Bu həftə, son nəticələr, zəif mövzular, davamiyyət, ev tapşırığı, ödəniş — hamısı", 3.0)
    h = pg.evaluate("document.body.scrollHeight")
    scroll(pg, min(h - 768, 1400), n=14, hold=1.8)
    db("update public.tests set status='published' where slug='riy-3-analiz'")

    card(pg, '<div class="logo">' + LOGO + '</div><div class="site">bil10.az</div>'
             '<h2>Test hazırlamaq — <span class="y">1 dəqiqə</span><br>Yoxlamaq — <span class="y">0 dəqiqə</span></h2>'
             '<div class="pill">Şagird və valideyn üçün pulsuz</div>'
             '<div class="sm">Bu, əsas axındır — daha çox imkan bələdçidə: <b style="color:#fff">bil10.az/komek</b><br>'
             'Nümunəyə baxın — qeydiyyatsız · info@bil10.az</div>', 4.5)

# ------------------------------------------------------------ CARX
#  Istifadeci: «7 dəq çox uzun və yorucudur, çarx fikri yaxşıdır - 2-3 dəq,
#  detallı izahla, şəkillə».  Her sehne: kicker + basliq + 2 cumle izah +
#  numune hesabdan REAL EKRAN.  Vaxt deqiq saniyedir (SPEED-e bolunur).
SCENES = [
 ("Qrup", "Qrup yaradın, şagirdə kod verin",
  "Şagird qeydiyyatdan keçmir — 8 simvollu kodla girir. Kodu «Göndər» ilə WhatsApp-a atırsınız; valideyn kodu da yanındadır.", "grp", 8),
 ("Test yığ", "Test 1 dəqiqəyə yığılır",
  "Fənn, sinif, mövzu seçirsiniz — sistem hazır bankdan balanslı 10 sual yığır. Öz suallarınızı da əlavə edə bilərsiniz.", "gen", 8),
 ("Tapşırıq", "Son tarix, cəhd sayı — bir toxunuşla",
  "Bütün qrupa və ya bir şagirdə. WhatsApp mətni hazır çıxır: «Kodunla gir, testi həll et».", "asg", 7),
 ("Şagird", "Şagird telefonda həll edir",
  "Kodla girir, həll edir — nəticə dərhal: neçə faiz, hansı sual səhv, izahı ilə. Bal serverdə hesablanır, düz cavab telefona getmir.", "s_q", 8),
 ("Hesabat", "Nəticə özü yığılır",
  "Kim işləyib, neçə faiz, hansı mövzu axsayır. «Nə etməli bu həftə» — adbaad, bir toxunuşla təkrar testi.", "rep", 9),
 ("Şagird kartı", "Hər şagirdin öz xəritəsi",
  "Diaqnostika mövzu-mövzu səviyyəni göstərir: «bundan başla». Səhv dəftəri səhv etdiyi sualları yenidən gətirir.", "card", 8),
 ("Dərs planı", "Dərsdən əvvəl bir baxış",
  "Kurikulum üzrə hazır plan: bu günün dərsi, isinmə 5 sual, son keçilən, tapşırığı etməyənlər — bir kartda.", "prep", 8),
 ("Ev tapşırığı", "«Bunu oxu, bunu təkrarla»",
  "Test olmayan tapşırığı da yazırsınız. Şagird «Etdim» deyir — siz və valideyn dərhal görürsünüz.", "hw", 7),
 ("Valideyn", "Valideyn də görür",
  "Öz kodu ilə: uşağının nəticəsi, meyli, gözləyən tapşırıqlar, davamiyyət. Sizə zəng etmir — özü baxır.", "par", 8),
 ("İcmal", "Hər açılışda bir baxış",
  "Bu günün dərsi, təhlükə zonası — geriləyən şagird, son nəticələr, liderlər. Hamısı bir ekranda.", "home", 7),
]

def carx(pg):
    R = 1.0 / SPEED
    pg.goto("about:blank")
    shots = demo_shots(pg.context)
    card(pg, '<div class="logo">' + LOGO + '</div><h1>Bil10</h1>'
             '<h2>Repetitor və müəllim üçün<br><span class="y">onlayn test sistemi</span></h2>', 2.0 * R)
    card(pg, '<div class="k">Hər həftə eyni iş</div>'
             '<h1 style="font-size:46px;line-height:1.15">Test yaz.<br>Yoxla.<br>Nəticəni say.<br>Valideynə de.</h1>', 3.2 * R)
    card(pg, '<div class="logo">' + LOGO + '</div>'
             '<h1 style="font-size:40px;line-height:1.2">Bil10 bunu<br><span class="y">sizin yerinizə</span> edir.</h1>', 2.6 * R)
    for i, (k, t, d, key, sec) in enumerate(SCENES):
        CHAPS.append({"n": i + 1, "t": k, "s": round(sum(x for _, x in FRAMES), 1)})
        card(pg, '<div class="top"><div class="k">' + str(i + 1) + '/' + str(len(SCENES)) + ' · ' + k + '</div>'
                 '<h1>' + t + '</h1><div class="sm">' + d + '</div></div>'
                 '<div class="phone"><img src="' + shots[key] + '" alt=""></div>', sec * R)
    card(pg, '<div class="logo">' + LOGO + '</div><h1>Bil10</h1>'
             '<h2>Şagird və valideyn üçün <span class="y">pulsuz</span></h2>'
             '<div class="pill">Nümunəyə baxın — qeydiyyatsız</div>'
             '<div class="site">bil10.az</div>', 5.0 * R)
    #  uz sekli
    pg.evaluate("""([css, html]) => {
      if (!document.getElementById('vcardcss')) {
        const s = document.createElement('style'); s.id = 'vcardcss'; s.textContent = css;
        (document.head || document.documentElement).appendChild(s);
      }
      let d = document.getElementById('vcard');
      if (!d) { d = document.createElement('div'); d.id = 'vcard'; (document.body || document.documentElement).appendChild(d); }
      d.innerHTML = '<div class="w">' + html + '</div>';
    }""", [CARD_CSS, '<div class="logo">' + LOGO + '</div><h1>Bil10</h1>'
           '<h2>Müəllim nə qazanır?<br><span class="y">2 dəqiqəlik çarx</span></h2>'
           '<div class="play"><i></i></div><div class="sm">səssiz · real ekranlar · bil10.az</div>'])
    pg.wait_for_timeout(250); pg.screenshot(path=OUT + "/poster_carx.png")

with sync_playwright() as p:
    br = p.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    ctx = br.new_context(viewport={"width": 432, "height": 768}, device_scale_factor=2.5,
                         permissions=["clipboard-read", "clipboard-write"])
    pg = ctx.new_page()
    pg.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    pg.route("**://*.supabase.co/**", lambda r: r.abort())
    (carx if CARX else (tam if TAM else qisa))(pg)
    br.close()

with io.open(LIST, "w", encoding="utf-8") as f:
    for path, sec in FRAMES:
        f.write("file '%s'\nduration %.3f\n" % (path, sec))
    f.write("file '%s'\n" % FRAMES[-1][0])
total = sum(s for _, s in FRAMES)
import json
io.open(LIST.replace(".txt", "_fesil.json"), "w", encoding="utf-8").write(
    json.dumps({"uzunluq": round(total, 1), "fesil": CHAPS}, ensure_ascii=False, indent=1))
print("kadr: %d  uzunluq: %.1f s" % (len(FRAMES), total))
