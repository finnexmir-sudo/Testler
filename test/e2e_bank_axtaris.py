#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Bank axtarisi MOVZU ADINA da baxir (db/907) + movzu kartlari ve Test yig-da movzu axtarisi (db/908).

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
    # sehife ONLUQDUR: ilk 10, «Daha 10 sual göstər» ile 20, 30 ...
    ok(p.locator("#bList .qitem").count() == 10, "ilk sehife 10 sual", p.locator("#bList .qitem").count())
    ok("Daha 10" in p.inner_text("#bMore"), "duyme «Daha 10 sual göstər»", p.inner_text("#bMore"))
    for k in (20, 30, 40, 50):
        p.click("#bMore"); p.wait_for_function("n => document.querySelectorAll('#bList .qitem').length >= n", arg=k, timeout=20000)
    ok(p.locator("#bList .qitem").count() == 50, "10-10 artir: 50-ye catdi", p.locator("#bList .qitem").count())
    r = p.evaluate("""(t) => { const it = [...document.querySelectorAll('#bList .qitem')];
        const rows = it.map(x => ({ body: x.querySelector('.g b').innerText, meta: x.querySelector('.g i').innerText }));
        return { n: rows.length, byTopic: rows.filter(r => r.meta.indexOf(t) >= 0 && r.body.toLowerCase().indexOf(t.toLowerCase()) < 0).length,
                 sample: rows.slice(0, 2) }; }""", TOPIC)
    ok(r["n"] > 0, "movzu adi ile axtaris netice verdi (%d sual)" % r["n"], r)
    ok(r["byTopic"] > 0, "sual metninde olmayan, yalniz movzu adina gore tapilan sual var (%d)" % r["byTopic"], r)
    # ---- variantlar default BAGLIDIR (sehife uzanmasin), duyme ile acilir
    vis = "() => [...document.querySelectorAll('#bList .qopts')].filter(u => u.offsetParent !== null).length"
    ok(p.locator("#bList .qopts").count() > 0 and p.evaluate(vis) == 0, "siyahida variantlar default baglidir")
    ok(p.locator("#bList .qtg").count() == p.locator("#bList .qitem").count(), "her suala «Variantlar · N» duymesi var")
    h_bagli = p.evaluate("document.querySelector('#bList').offsetHeight")
    p.locator("#bList .qtg").first.click(); p.wait_for_timeout(200)
    ok(p.evaluate(vis) == 1 and p.locator("#bList .qtg").first.get_attribute("aria-expanded") == "true", "bir sualin variantlari acildi")
    p.locator("#bList .qtg").first.click(); p.wait_for_timeout(200)
    ok(p.evaluate(vis) == 0, "ikinci klik bagladi")
    p.click("#bAll"); p.wait_for_timeout(300)
    n_all = p.locator("#bList .qopts").count()
    ok(p.evaluate(vis) == n_all and "bağla" in p.inner_text("#bAll"), "«Variantları aç» hamisini acdi (%d)" % n_all)
    h_aciq = p.evaluate("document.querySelector('#bList').offsetHeight")
    ok(h_aciq > h_bagli, "baglı siyahi daha qisadir (%d px < %d px)" % (h_bagli, h_aciq))
    p.click("#bAll"); p.wait_for_timeout(300)
    ok(p.evaluate(vis) == 0 and "aç" in p.inner_text("#bAll"), "«Variantları bağla» hamisini bagladi")
    p.screenshot(path="%s/%s_movzu.png" % (OUT, tag))

    p.fill("#bq", "zzqqxx yoxdur"); p.wait_for_selector("text=Sual tapılmadı", timeout=20000)
    ok(True, "olmayan soz: «Sual tapılmadı»")
    p.screenshot(path="%s/%s_yoxdur.png" % (OUT, tag))

    p.fill("#bq", TOPIC.lower()); p.wait_for_selector(".qitem", timeout=20000)
    ok(p.locator("#bList .qitem").count() > 0, "kicik herflerle de tapilir")

    # ---- 908: movzu karti (sual bankinda)
    p.fill("#bq", TOPIC); p.wait_for_selector("#bTopHit .thit", timeout=20000); p.wait_for_timeout(500)
    card = p.evaluate("""() => { const e = document.querySelector('#bTopHit .thit'); return e ? e.innerText : ''; }""")
    ok(TOPIC.lower() in card.lower() and "sual" in card, "movzu karti: ad + sual sayi", card)
    ok(p.locator("#bTopHit [data-th='gen']").count() > 0 and p.locator("#bTopHit [data-th='q']").count() > 0,
       "kartda «Test yığ» ve «Suallar» duymeleri var")
    p.screenshot(path="%s/%s_karti.png" % (OUT, tag))
    p.locator("#bTopHit [data-th='gen']").first.click()
    p.wait_for_selector("#gTopBox .chip.on", timeout=25000); p.wait_for_timeout(600)
    ok("#/gen" in p.evaluate("location.hash"), "«Test yığ» generatora aparir")
    ok(p.evaluate("document.getElementById('gsub').value") == "az-dili", "fenn avtomatik secildi (Azərbaycan dili)")
    on_chip = p.evaluate("document.querySelector('#gTopBox .chip.on').innerText")
    ok(TOPIC.lower() in on_chip.lower(), "movzu nisani yanir: " + on_chip, on_chip)
    p.screenshot(path="%s/%s_gen_secili.png" % (OUT, tag))

    # ---- 908: Test yig ekraninda movzu axtarisi
    p.evaluate("location.hash='#/'"); p.wait_for_timeout(500)
    p.evaluate("location.hash='#/gen'"); p.wait_for_selector("#gTq", timeout=20000)
    p.click("#gPool [data-v='platform']"); p.wait_for_timeout(600)
    p.evaluate("(() => { const s = document.getElementById('gsub'); s.value=''; s.dispatchEvent(new Event('change')); })()")
    p.wait_for_timeout(500)
    p.fill("#gTq", "Söz birləşm"); p.wait_for_selector("#gTqHits .thit", timeout=20000); p.wait_for_timeout(400)
    ok(p.locator("#gTqHits .thit").count() > 0, "Test yığ: movzu axtarisi netice verdi")
    p.screenshot(path="%s/%s_gen_axtaris.png" % (OUT, tag))
    p.locator("#gTqHits [data-th='sec']").first.click(); p.wait_for_selector("#gTopBox .chip.on", timeout=25000); p.wait_for_timeout(500)
    ok(p.evaluate("document.getElementById('gsub').value") == "az-dili", "Test yığ: fenn secildi")
    ok("Seçildi" in p.evaluate("document.getElementById('gTqHits').innerText"), "Test yığ: «Seçildi» yazisi")
    p.screenshot(path="%s/%s_gen_secildi.png" % (OUT, tag))
    p.fill("#gTq", "zzqqxx"); p.wait_for_timeout(1200)
    ok(p.locator("#gTqHits .thit").count() == 0, "olmayan soz: kart yoxdur")
    br.close()

with sync_playwright() as pw:
    run(pw, 390, 844, "tel")
    run(pw, 1280, 800, "masa")
print("\nNETICE:", "HAMISI KECDI" if not fails else "XETALAR: %d" % len(fails))
sys.exit(1 if fails else 0)
