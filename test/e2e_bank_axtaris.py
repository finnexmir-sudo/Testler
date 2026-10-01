#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Bank axtarisi MOVZU ADINA da baxir (db/907): «Hazir suallar» -> axtaris xanasi.

Sikayet: muellim «frazeoloji birlesme» yazdi, hec ne cixmadi - rpc_bank_list yalniz sualin metnine baxirdi.
Burada yerli bazada movzu adi (sual metninde kecmeyen) ile axtarilir: «Söz birləşmələri».
390 ve 1280 px-de: netice cixir, setirlerin movzu nisani movzunun adidir, sual metni sozu ehtiva etmir,
olmayan soz «Sual tapılmadı» verir, xananin yazisi «Mövzu və ya ...» deyir."""
import os, sys
from playwright.sync_api import sync_playwright

ROOT = "http://127.0.0.1:8010/"
PANEL = ROOT + "muellim/index.html?yeni=1"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
OUT = "/tmp/claude-0/bankaxtaris"; os.makedirs(OUT, exist_ok=True)
CFG = """window.CFG = {SUPABASE_URL:"http://127.0.0.1:54321", SUPABASE_ANON_KEY:"test-anon-key",
  STUDENT_URL:"http://127.0.0.1:8010/sagird/", PARENT_URL:"http://127.0.0.1:8010/valideyn/", SHOW_PLANS:false};"""
TOPIC = "Söz birləşmələri"

fails = []
def ok(cond, label, extra=""):
    print(("  OK   " if cond else "  XETA ") + label + ((" -- " + str(extra)) if (extra and not cond) else ""))
    if not cond: fails.append(label)

def run(pw, w, h, tag):
    print("== %s (%dx%d)" % (tag, w, h))
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    p = br.new_context(viewport={"width": w, "height": h}, device_scale_factor=1).new_page()
    p.route("**/config.js*", lambda r: r.fulfill(status=200, content_type="application/javascript", body=CFG))
    p.goto(PANEL + "#/demo"); p.wait_for_selector("text=Xoş gəlmisiniz", timeout=60000)
    p.add_style_tag(content="#demoBar{display:none!important}")
    p.evaluate("location.hash='#/b'"); p.wait_for_selector("#bq", timeout=20000)
    ok("Mövzu" in (p.get_attribute("#bq", "placeholder") or ""), "xananin yazisi movzunu da deyir")
    p.click("#bPool [data-v='platform']"); p.wait_for_timeout(800)

    p.fill("#bq", TOPIC); p.wait_for_selector(".qitem", timeout=20000); p.wait_for_timeout(600)
    r = p.evaluate("""(t) => { const it = [...document.querySelectorAll('#bList .qitem')];
        const rows = it.map(x => ({ body: x.querySelector('.g b').innerText, meta: x.querySelector('.g i').innerText }));
        return { n: rows.length, byTopic: rows.filter(r => r.meta.indexOf(t) >= 0 && r.body.toLowerCase().indexOf(t.toLowerCase()) < 0).length,
                 sample: rows.slice(0, 2) }; }""", TOPIC)
    ok(r["n"] > 0, "movzu adi ile axtaris netice verdi (%d sual)" % r["n"], r)
    ok(r["byTopic"] > 0, "sual metninde olmayan, yalniz movzu adina gore tapilan sual var (%d)" % r["byTopic"], r)
    p.screenshot(path="%s/%s_movzu.png" % (OUT, tag))

    p.fill("#bq", "zzqqxx yoxdur"); p.wait_for_selector("text=Sual tapılmadı", timeout=20000)
    ok(True, "olmayan soz: «Sual tapılmadı»")
    p.screenshot(path="%s/%s_yoxdur.png" % (OUT, tag))

    p.fill("#bq", TOPIC.lower()); p.wait_for_selector(".qitem", timeout=20000)
    ok(p.locator("#bList .qitem").count() > 0, "kicik herflerle de tapilir")
    br.close()

with sync_playwright() as pw:
    run(pw, 390, 844, "tel")
    run(pw, 1280, 800, "masa")
print("\nNETICE:", "HAMISI KECDI" if not fails else "XETALAR: %d" % len(fails))
sys.exit(1 if fails else 0)
