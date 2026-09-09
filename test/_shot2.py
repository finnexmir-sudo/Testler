# -*- coding: utf-8 -*-
#  Metn deyisikliyi ucun sekil: ana sehife «pulsuz» bolmesi ve beledci
#  «Valideyn ucun» bolmesi.  Baza lazim deyil - yalniz statik sehife.
from playwright.sync_api import sync_playwright
BASE = "http://127.0.0.1:8010"
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
CFG = """window.CFG={SUPABASE_URL:"http://127.0.0.1:54321",SUPABASE_ANON_KEY:"k",
STUDENT_URL:"https://example.test/Testler/",CONTACT_WHATSAPP:"+994501234567",SHOW_PLANS:false};"""
with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
    def shot(path, url, sel, name, w, h):
        ctx = br.new_context(viewport={"width": w, "height": h}, device_scale_factor=2)
        p = ctx.new_page()
        p.route("**/config.js*", lambda r: r.fulfill(status=200,
            content_type="application/javascript", body=CFG))
        p.goto(BASE + url); p.wait_for_timeout(900)
        p.locator(sel).first.scroll_into_view_if_needed(); p.wait_for_timeout(400)
        p.locator(sel).first.screenshot(path="/tmp/claude-0/" + name)
        ctx.close()
    shot(None, "/index.html", ".freesec", "t_ana_masa.png", 1280, 800)
    shot(None, "/index.html", ".freesec", "t_ana_tel.png", 430, 932)
    shot(None, "/komek/index.html", "#valideyn .step:nth-of-type(2)", "t_komek_masa.png", 1280, 800)
    shot(None, "/komek/index.html", "#valideyn", "t_komek_tel.png", 430, 932)
    br.close()
print("hazir")
