# -*- coding: utf-8 -*-
"""A/B olcme: ilk aciilis ne qeder cekir?

Her Supabase cavabina SUNI 300 ms gecikme qoyulur.  Boylelikle olculen
sey NOVBELI GEDIS-GELISLERIN sayidir - mock-un oz suretinden asili
deyil.  Iki ssenari, hər ikisi eyni sertlerde:
  1. jeton DIRI  - adi keçid
  2. jeton BITIB - gunun ilk aciilisi (server 401 verir)
Her olcmeden EVVEL yaddasdaki sessiya ilk (kohne) haline qaytarilir -
yoxsa birinci olcme jetonu yenileyir ve ikincisi eyni ssenari olmur.
"""
import time, json, psycopg2
from playwright.sync_api import sync_playwright
PANEL="http://127.0.0.1:8010/muellim/index.html"
CHROME="/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN="host=/tmp port=55432 user=postgres dbname=panel_e2e"
CFG="""window.CFG={SUPABASE_URL:"http://127.0.0.1:54321",SUPABASE_ANON_KEY:"test-anon-key",
STUDENT_URL:"https://example.test/",CONTACT_WHATSAPP:"+994501234567",SHOW_PLANS:false};"""
GECIKME=0.300
def db(sql,args=None):
    with psycopg2.connect(DSN) as c, c.cursor() as cur: cur.execute(sql,args or ())
db("""delete from public.students; delete from public.classes;
delete from public.account_members; delete from public.accounts;
delete from public.user_roles; delete from auth.users;""")
with sync_playwright() as pw:
    br=pw.chromium.launch(executable_path=CHROME,args=["--no-sandbox"])
    ctx=br.new_context(viewport={"width":430,"height":900}); pg=ctx.new_page()
    pg.route("**/config.js*",lambda r:r.fulfill(status=200,content_type="application/javascript",body=CFG))
    pg.goto(PANEL); pg.wait_for_timeout(400)
    pg.click("#btnSwap"); pg.fill("#fname","O M"); pg.fill("#email","o@t.az")
    pg.fill("#pass","parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup",timeout=15000)
    pg.select_option("#atype","tutor"); pg.fill("#aname","O hesab"); pg.click("#btnSetup")
    pg.wait_for_selector("#gForm",timeout=20000)
    with psycopg2.connect(DSN) as c, c.cursor() as cur:
        cur.execute("select a.id,a.owner_id from public.accounts a join auth.users u"
                    " on u.id=a.owner_id where u.email='o@t.az'"); r=cur.fetchone()
    db("insert into public.classes (account_id,teacher_id,kind,name,join_code)"
       " values (%s,%s,'tutor_group','O qrupu','KODOOO01')",(r[0],r[1]))

    ILK = pg.evaluate("()=>JSON.parse(localStorage.getItem('panel_session'))")
    KOHNE = ILK["access_token"]
    sayac={"n":0,"israf":0,"bitib":False}
    #  GECIKME SERVERDE olur (mock ThreadingHTTPServer-dir ve
    #  X-Test-Delay basligini taniyir).  Burada time.sleep(...) ETMEK
    #  OLMAZ: Playwright-in sinxron API-si marsrutlari BIR-BIR isleyir,
    #  ona gore paralel sorgular suni olaraq novbeye duserdi ve olcme
    #  "novbeli derinlik" yerine "sorgu sayi" olcerdi.
    def yol(route):
        sayac["n"]+=1
        if (sayac["bitib"] and "/rest/v1/" in route.request.url
                and route.request.headers.get("authorization")=="Bearer "+KOHNE):
            sayac["israf"]+=1
            time.sleep(GECIKME)          # serverə catmadi - gecikmeni ozumuz veririk
            route.fulfill(status=401,content_type="application/json",
                          body='{"message":"JWT expired","code":"PGRST301"}')
        else:
            h=dict(route.request.headers); h["x-test-delay"]=str(int(GECIKME*1000))
            route.continue_(headers=h)
    pg.route("**/rest/v1/**",yol); pg.route("**/auth/v1/**",yol)

    def olc(etiket,bitib):
        #  hər olcme eyni noqtəden baslasin
        pg.evaluate("(s)=>localStorage.setItem('panel_session',JSON.stringify(s))",
                    json.loads(json.dumps(ILK)))
        if bitib:
            pg.evaluate("()=>{var s=JSON.parse(localStorage.getItem('panel_session'));"
                        "s.sb_exp=Date.now()-60000;"
                        "localStorage.setItem('panel_session',JSON.stringify(s));}")
        sayac["n"]=0; sayac["israf"]=0; sayac["bitib"]=bitib
        t0=time.monotonic()
        pg.reload()
        #  «Yüklənir…» kartinin itdiyi an - ekranin ozu cizilir
        pg.wait_for_selector("#btnGroup",timeout=40000); t1=time.monotonic()-t0
        #  qruplar da yerinde - sehife tam hazir
        pg.wait_for_selector(".gcard",timeout=40000);  t2=time.monotonic()-t0
        print("  %-30s ekran %5.2f s | tam %5.2f s   (%d sorgu, %d israf)"
              %(etiket,t1,t2,sayac["n"],sayac["israf"]))
    print("Her sorguya %d ms suni gecikme:"%int(GECIKME*1000))
    olc("jeton DIRI",  False)
    olc("jeton BITIB (gunun ilki)", True)
    br.close()
