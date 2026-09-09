# -*- coding: utf-8 -*-
import psycopg2, psycopg2.extras
from playwright.sync_api import sync_playwright
BASE="http://127.0.0.1:8010"
CHROME="/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
DSN="host=/tmp port=55432 user=postgres dbname=panel_e2e"
CFG="""window.CFG={SUPABASE_URL:"http://127.0.0.1:54321",SUPABASE_ANON_KEY:"test-anon-key",
STUDENT_URL:"https://example.test/Testler/",CONTACT_WHATSAPP:"+994501234567",SHOW_PLANS:false};"""
def db(sql,args=None,one=False):
    with psycopg2.connect(DSN,cursor_factory=psycopg2.extras.RealDictCursor) as c, c.cursor() as cur:
        cur.execute(sql,args or ())
        if cur.description: return cur.fetchone() if one else cur.fetchall()
db("""delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments; delete from public.parent_sessions;
delete from public.student_sessions; delete from public.students;
delete from public.classes; delete from public.subscriptions;
delete from public.account_members; delete from public.accounts;
delete from public.user_roles; delete from auth.users;""")
db("update public.app_state set val=jsonb_build_object('on',true,'days',30,"
   "'beta_until','2026-12-31') where key='hediyye'")
with sync_playwright() as pw:
    br=pw.chromium.launch(executable_path=CHROME,args=["--no-sandbox"])
    ctx=br.new_context(viewport={"width":430,"height":932},device_scale_factor=3)
    pg=ctx.new_page()
    pg.route("**/config.js*",lambda r:r.fulfill(status=200,
        content_type="application/javascript",body=CFG))
    pg.goto(BASE+"/muellim/index.html"); pg.wait_for_timeout(500)
    pg.click("#btnSwap"); pg.fill("#fname","Samir Hüseynov"); pg.fill("#email","sam@t.az")
    pg.fill("#pass","parol1234"); pg.click("#btnAuth")
    pg.wait_for_selector("#btnSetup",timeout=15000)
    pg.select_option("#atype","tutor"); pg.fill("#aname","Samir müəllim")
    pg.click("#btnSetup"); pg.wait_for_selector("#gForm",timeout=20000)
    acc=db("select a.id, a.owner_id from public.accounts a join auth.users u"
           " on u.id=a.owner_id where u.email='sam@t.az'",one=True)
    A, U = acc["id"], acc["owner_id"]
    c=db("insert into public.classes (account_id,teacher_id,kind,name,join_code)"
         " values (%s,%s,'tutor_group','9-A qrupu','KODV17401') returning id",(A,U),one=True)["id"]
    st=db("insert into public.students (account_id,class_id,created_by,full_name,"
          "display_name,login_code,parent_code,is_active) values"
          " (%s,%s,%s,'Aysu Məmmədova','Aysu M.','SHV17401','VLD17401',true)"
          " returning id",(A,c,U),one=True)["id"]
    t=db("insert into public.tests (owner_type,owner_id,title,program_id,subject_id,"
         "pass_percent,is_free,status) select 'educator',%s,'Riyaziyyat — vurma',"
         " p.id, s.id, 50, false, 'published' from public.programs p, public.subjects s"
         " limit 1 returning id",(U,),one=True)["id"]
    #  son 60 gunde cehdler: kecen ay 62%, bu ay 78% -> meyl musbet
    for gun, pc in [(45,60),(40,64),(20,74),(10,80),(3,82)]:
        db("insert into public.attempts (student_id,test_id,status,score,max_score,"
           "percent,started_at,finished_at,duration_sec) values"
           " (%s,%s,'submitted',%s,10,%s,now()-(%s||' days')::interval,"
           " now()-(%s||' days')::interval,600)",(st,t,pc//10,pc,str(gun),str(gun)))
    db("insert into public.parent_sessions (token_hash,student_id,created_at,expires_at)"
       " values (md5('p1'),%s,now()-interval '2 days',now()+interval '30 days')",(st,))
    def val(name):
        p2=ctx.new_page()
        p2.route("**/config.js*",lambda r:r.fulfill(status=200,
            content_type="application/javascript",body=CFG))
        p2.goto(BASE+"/valideyn/?kod=VLD17401")
        p2.wait_for_selector(".card.sum",timeout=20000); p2.wait_for_timeout(1200)
        p2.screenshot(path="/tmp/claude-0/"+name,full_page=True)
        p2.close()
    val("v_abuneli.png")          # hediyye abunesi var
    db("delete from public.subscriptions where account_id=%s",(A,))
    val("v_pulsuz.png")           # pulsuz hedd
    #  admin cedveli - valideyn sayi gorunsun
    db("insert into public.user_roles (user_id,role) values (%s,'admin')",(U,))
    pg.set_viewport_size({"width":1200,"height":700})
    pg.goto(BASE+"/muellim/index.html#/adm"); pg.reload()
    pg.wait_for_selector(".admr",timeout=20000); pg.wait_for_timeout(1000)
    pg.locator("#admList").screenshot(path="/tmp/claude-0/v_admin.png")
    br.close()
print("hazir")
