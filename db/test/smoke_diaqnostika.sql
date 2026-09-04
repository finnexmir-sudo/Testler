-- =====================================================================
--  smoke_diaqnostika.sql : diaqnostik test (db/118_diaqnostika.sql)
--
--  Iddialar: her fesilden DUZ 3 sual · yalniz o sagirde · abunesiz yox ·
--  yad muellim yox · dublikat yox · xerite duzgun (weak/mid/ok) ·
--  "bundan basla" sirasi · ikinci diaqnostikada ferq · sagird oz
--  xeritesini gorur (duz cavab yox) · abune bitende xerite baglanir,
--  bal qalir · valideyn setrinde nisan.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.parent_sessions; delete from public.question_reports;
delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers;  delete from public.attempts;
delete from public.assignments;      delete from public.student_sessions;
delete from public.students;         delete from public.classes;
delete from public.subscriptions;
delete from public.test_questions tq using public.tests t
 where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-0000000000da','da@t.az','{"full_name":"Diaq Muellim"}'),
  ('11110000-0000-0000-0000-0000000000db','db@t.az','{"full_name":"Yad Muellim"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000da','tutor','Diaq hesabi','11110000-0000-0000-0000-0000000000da'),
  ('aaaa0000-0000-0000-0000-0000000000db','tutor','Yad hesab',  '11110000-0000-0000-0000-0000000000db');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000da','11110000-0000-0000-0000-0000000000da',true),
  ('aaaa0000-0000-0000-0000-0000000000db','11110000-0000-0000-0000-0000000000db',true);
--  A abuneli, B abunesiz
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-0000000000da', p.id, 'active', now() + interval '30 days'
  from public.plans p where p.slug = 'repetitor-25';
insert into public.classes (id, account_id, teacher_id, kind, name, join_code, level_id)
select 'cccc0000-0000-0000-0000-0000000000da','aaaa0000-0000-0000-0000-0000000000da',
       '11110000-0000-0000-0000-0000000000da','tutor_group','Diaq qrupu','KODDIAQ1',
       l.id from public.levels l where l.code = '3' and l.code ~ '^[0-9]+$';
insert into public.classes (id, account_id, teacher_id, kind, name, join_code, level_id)
select 'cccc0000-0000-0000-0000-0000000000db','aaaa0000-0000-0000-0000-0000000000db',
       '11110000-0000-0000-0000-0000000000db','tutor_group','Yad qrupu','KODDIAQ2',
       l.id from public.levels l where l.code = '3' and l.code ~ '^[0-9]+$';
--  sinifsiz qrup - xeta yolu ucun
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-0000000000dc','aaaa0000-0000-0000-0000-0000000000da',
   '11110000-0000-0000-0000-0000000000da','tutor_group','Sinifsiz','KODDIAQ3');
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code) values
  ('5555000a-0000-0000-0000-0000000000d1','aaaa0000-0000-0000-0000-0000000000da',
   'cccc0000-0000-0000-0000-0000000000da','11110000-0000-0000-0000-0000000000da','Kənan Əliyev','Kənan Ə.','DIAQKEN1'),
  ('5555000a-0000-0000-0000-0000000000d2','aaaa0000-0000-0000-0000-0000000000da',
   'cccc0000-0000-0000-0000-0000000000da','11110000-0000-0000-0000-0000000000da','Nigar Həsənova','Nigar H.','DIAQNIG1'),
  ('5555000a-0000-0000-0000-0000000000d3','aaaa0000-0000-0000-0000-0000000000db',
   'cccc0000-0000-0000-0000-0000000000db','11110000-0000-0000-0000-0000000000db','Yad Şagird','Yad Ş.','DIAQYAD1'),
  ('5555000a-0000-0000-0000-0000000000d4','aaaa0000-0000-0000-0000-0000000000da',
   'cccc0000-0000-0000-0000-0000000000dc','11110000-0000-0000-0000-0000000000da','Sinifsiz Uşaq','Sinifsiz U.','DIAQSNF1');

drop table if exists public.diag_fx; create table public.diag_fx (k text primary key, val text);
grant all on public.diag_fx to anon, authenticated;   -- rol deyisende de yazila bilsin
\echo '--- hazirliq tamam'

set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000da';

-- =====================================================================
--  1. Secimler: sinif 3, riyaziyyat 12 fesil x 3 = 36, hele diaqnostika yox
-- =====================================================================
do $$
declare v jsonb; r jsonb;
begin
  v := public.rpc_diagnostic_options('5555000a-0000-0000-0000-0000000000d1');
  assert (v->>'paid')::boolean, 'abune gorunmur';
  assert v->'level'->>'code' = '3', 'sinif kodu sehv: ' || (v->'level')::text;
  select x into r from jsonb_array_elements(v->'subjects') x where x->>'slug' = 'riyaziyyat';
  assert r is not null, 'riyaziyyat secimlerde yoxdur';
  assert (r->>'topics')::int = 12, 'fesil sayi 12 deyil: ' || (r->>'topics');
  assert (r->>'questions')::int = 36, 'sual sayi 36 deyil: ' || (r->>'questions');
  assert r->'last' = 'null'::jsonb, 'hele diaqnostika olmamalidir';
  --  sinifsiz qrup: secim yox, sebeb yazilir
  v := public.rpc_diagnostic_options('5555000a-0000-0000-0000-0000000000d4');
  assert v->'level' = 'null'::jsonb and v->>'reason' like '%sinfi secilmeyib%', 'sinifsiz qrupda sebeb yoxdur';
end $$;
\echo 'OK  1 · secimler: 12 fesil x 3 = 36 sual, sinifsiz qrupda aydin sebeb'

-- =====================================================================
--  2. Yaratmaq: 36 sual, her fesilden DUZ 3, yalniz Kenana, 1 cehd
-- =====================================================================
do $$
declare v jsonb; t uuid; n int; bad int; dif int;
begin
  v := public.rpc_diagnostic_create('5555000a-0000-0000-0000-0000000000d1', 'riyaziyyat', 7);
  t := (v->>'test_id')::uuid;
  assert (v->>'existing')::boolean = false, 'ilk yaradilis "existing" olmamalidir';
  assert (v->>'questions')::int = 36, 'sual sayi: ' || (v->>'questions');
  assert (v->>'topics')::int = 12, 'fesil sayi: ' || (v->>'topics');
  assert v->>'title' like 'Diaqnostika · Riyaziyyat · %', 'basliq: ' || (v->>'title');
  insert into public.diag_fx values ('t1', t::text);

  select count(*) into n from public.test_questions where test_id = t;
  assert n = 36, 'test_questions sayi: ' || n;
  --  her fesilden duz 3
  select count(*) into bad from (
    select q.topic_id, count(*) c from public.test_questions tq
      join public.questions q on q.id = tq.question_id
     where tq.test_id = t group by q.topic_id having count(*) <> 3) z;
  assert bad = 0, bad || ' fesilde 3-den ferqli sual var';
  --  cetinlik qarisigi: en azi 2 ferqli seviyye
  select count(distinct q.difficulty) into dif from public.test_questions tq
    join public.questions q on q.id = tq.question_id where tq.test_id = t;
  assert dif >= 2, 'cetinlik qarisigi yoxdur';
  --  test sahələri
  assert (select is_diagnostic and status = 'published' and max_attempts = 1 and is_free
            from public.tests where id = t), 'test sahələri sehv';
  assert (select time_limit_sec from public.tests where id = t) = 36 * 75, 'vaxt limiti sehv';
  --  teyinat: yalniz Kenan, 1 cehd, ~7 gun
  assert (select count(*) from public.assignments where test_id = t) = 1, 'teyinat sayi';
  assert (select student_id = '5555000a-0000-0000-0000-0000000000d1' and max_attempts = 1
            and closes_at between now() + interval '6 days' and now() + interval '8 days'
            from public.assignments where test_id = t), 'teyinat ferdi/1 cehd/7 gun deyil';
end $$;
\echo 'OK  2 · 36 sual, her fesilden duz 3, cetinlik qarisiq, yalniz Kenana, 1 cehd, 7 gun'

-- =====================================================================
--  3. Dublikat yoxdur; secimlerde "gozleyir"; netice "has=false, pending"
-- =====================================================================
do $$
declare v jsonb; r jsonb; t text;
begin
  select val into t from public.diag_fx where diag_fx.k = 't1';
  v := public.rpc_diagnostic_create('5555000a-0000-0000-0000-0000000000d1', 'riyaziyyat', 7);
  assert (v->>'existing')::boolean and v->>'test_id' = t, 'acıq diaqnostika varken yenisi yaradildi';
  assert (select count(*) from public.tests where is_diagnostic) = 1, 'test coxaldi';

  v := public.rpc_diagnostic_options('5555000a-0000-0000-0000-0000000000d1');
  select x into r from jsonb_array_elements(v->'subjects') x where x->>'slug' = 'riyaziyyat';
  assert r->'last'->>'test_id' = t and (r->'last'->>'taken')::boolean = false
     and (r->'last'->>'open')::boolean, 'secimlerde son diaqnostika gozleyir kimi gorunmur';

  v := public.rpc_diagnostic_result('5555000a-0000-0000-0000-0000000000d1', null);
  assert (v->>'has')::boolean = false, 'yazilmamis diaqnostika "has" olmamalidir';
  assert v->'pending'->>'test_id' = t, 'pending yoxdur';
  assert (v->'pending'->>'questions')::int = 36, 'pending sual sayi';
end $$;
\echo 'OK  3 · dublikat yaranmir, secim ve netice "gozleyir" deyir'

-- =====================================================================
--  4. Yad muellim: ne yarada, ne oxuya biler; abunesiz: yarada bilmir
-- =====================================================================
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000db';
do $$
declare v jsonb; ok boolean := false;
begin
  begin
    v := public.rpc_diagnostic_create('5555000a-0000-0000-0000-0000000000d1', 'riyaziyyat', 7);
  exception when others then ok := sqlstate = '42501'; end;
  assert ok, 'yad muellim basqasinin sagirdine diaqnostika yaratdi';
  ok := false;
  begin
    v := public.rpc_diagnostic_result('5555000a-0000-0000-0000-0000000000d1', null);
  exception when others then ok := sqlstate = '42501'; end;
  assert ok, 'yad muellim neticeni oxudu';
  --  oz sagirdi, amma abune yoxdur
  ok := false;
  begin
    v := public.rpc_diagnostic_create('5555000a-0000-0000-0000-0000000000d3', 'riyaziyyat', 7);
  exception when others then ok := sqlstate = '42501' and sqlerrm like '%abune%'; end;
  assert ok, 'abunesiz hesab diaqnostika yaratdi';
  v := public.rpc_diagnostic_options('5555000a-0000-0000-0000-0000000000d3');
  assert (v->>'paid')::boolean = false, 'abunesiz "paid" true';
end $$;
\echo 'OK  4 · yad muellim yarada/oxuya bilmir, abunesiz hesab yarada bilmir'

-- =====================================================================
--  5. Sagird: tapsiriqda "diagnostic" nisani; yazir - fesil 1 sehv,
--     fesil 2 2/3, qalani duz
-- =====================================================================
reset role; reset request.jwt.claim.sub;
insert into public.diag_fx values ('tok', public.rpc_student_login('DIAQKEN1')->>'token');
do $$
declare tok text; t uuid; v jsonb; a jsonb; att uuid; ans jsonb := '[]'::jsonb; r record;
        oid uuid; k int := 0; cur uuid := null; tix int := 0; t1 text; t2 text;
begin
  select val into tok from public.diag_fx where diag_fx.k = 'tok';
  select val::uuid into t from public.diag_fx where diag_fx.k = 't1';
  v := public.rpc_student_tests(tok);
  select x into a from jsonb_array_elements(v->'assigned') x where x->>'id' = t::text;
  assert a is not null, 'sagird diaqnostikani gormur';
  assert (a->>'diagnostic')::boolean, 'diagnostic nisani yoxdur';
  assert (a->>'personal')::boolean, 'ferdi nisani yoxdur';
  assert (a->>'locked')::boolean = false, 'diaqnostika kilidlidir';

  att := (public.rpc_start_attempt(tok, t)->>'attempt_id')::uuid;
  --  fesiller kurikulum sirasi ile: 1-ci hamisi sehv, 2-ci 2/3, qalani duz
  for r in
    select q.id qid, q.topic_id, tp.sort, tp.name
      from public.test_questions tq
      join public.questions q on q.id = tq.question_id
      join public.topics tp on tp.id = q.topic_id
     where tq.test_id = t order by tp.sort, tp.name, tq.ord
  loop
    if cur is distinct from r.topic_id then cur := r.topic_id; tix := tix + 1; k := 0;
      if tix = 1 then t1 := r.name; elsif tix = 2 then t2 := r.name; end if;
    end if;
    k := k + 1;
    select o.id into oid from public.question_options o
     where o.question_id = r.qid
       and o.is_correct = (case when tix = 1 then false when tix = 2 then (k <= 2) else true end)
     order by o.ord limit 1;
    ans := ans || jsonb_build_array(jsonb_build_object('q', r.qid, 'o', jsonb_build_array(oid)));
  end loop;
  insert into public.diag_fx values ('t_weak', t1), ('t_mid', t2);
  v := public.rpc_submit_attempt(tok, att, ans);
  assert (v->>'diagnostic')::boolean, 'submit: diagnostic nisani yoxdur';
  assert v->'topics' is not null and v->'topics' <> 'null'::jsonb, 'submit: sagird xeritesi yoxdur';
  assert jsonb_array_length(v->'topics'->'topics') = 12, 'sagird xeritesinde 12 fesil yoxdur';
  assert v->'topics'->'start'->>0 = t1 and v->'topics'->'start'->>1 = t2
     and jsonb_array_length(v->'topics'->'start') = 2, '"bundan basla" sehv: ' || (v->'topics'->'start')::text;
  assert (v->>'score')::numeric = 36 - 3 - 1, 'bal: ' || (v->>'score');
  assert (v::text) not like '%is_correct%', 'is_correct sizdi';
end $$;
\echo 'OK  5 · sagird nisani gorur, yazir; oz xeritesi: 12 fesil, "bundan basla" = zeif, orta'

-- =====================================================================
--  6. Muellim neticesi: xerite, statuslar, saylar, ferq yoxdur (ilk)
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000da';
do $$
declare v jsonb; e jsonb; t1 text; t2 text;
begin
  select val into t1 from public.diag_fx where diag_fx.k = 't_weak';
  select val into t2 from public.diag_fx where diag_fx.k = 't_mid';
  v := public.rpc_diagnostic_result('5555000a-0000-0000-0000-0000000000d1', 'riyaziyyat');
  assert (v->>'has')::boolean and (v->>'paid')::boolean, 'has/paid';
  assert v->'pending' = 'null'::jsonb, 'yazilandan sonra pending qalib';
  assert jsonb_array_length(v->'topics') = 12, 'xeritede 12 fesil yoxdur';
  assert (v->>'weak_now')::int = 1 and (v->>'mid_now')::int = 1 and (v->>'ok_now')::int = 10,
    format('saylar: weak %s mid %s ok %s', v->>'weak_now', v->>'mid_now', v->>'ok_now');
  select x into e from jsonb_array_elements(v->'topics') x where x->>'name' = t1;
  assert e->>'status' = 'weak' and (e->>'correct')::int = 0 and (e->>'total')::int = 3, 'zeif fesil: ' || e::text;
  select x into e from jsonb_array_elements(v->'topics') x where x->>'name' = t2;
  assert e->>'status' = 'mid' and (e->>'correct')::int = 2, 'orta fesil: ' || e::text;
  assert v->'start'->>0 = t1 and v->'start'->>1 = t2, 'basla sirasi: ' || (v->'start')::text;
  assert v->'weak_prev' = 'null'::jsonb and v->'prev_at' = 'null'::jsonb, 'ilk diaqnostikada ferq olmamalidir';
  assert (v->>'percent')::numeric between 88 and 90, 'faiz: ' || (v->>'percent');
  --  secimlerde: son diaqnostika yazilib
  v := public.rpc_diagnostic_options('5555000a-0000-0000-0000-0000000000d1');
  select x into e from jsonb_array_elements(v->'subjects') x where x->>'slug' = 'riyaziyyat';
  assert (e->'last'->>'taken')::boolean and (e->'last'->>'percent')::numeric between 88 and 90, 'secimlerde yazilib gorunmur';
end $$;
\echo 'OK  6 · muellim xeritesi: 1 zeif, 1 orta, 10 ok; "bundan basla" duzgun; ilkde ferq yoxdur'

-- =====================================================================
--  7. Ikinci diaqnostika: yeni test, hamisi duz -> ferq "1 -> 0", prev_status
-- =====================================================================
do $$
declare v jsonb; t text;
begin
  select val into t from public.diag_fx where diag_fx.k = 't1';
  v := public.rpc_diagnostic_create('5555000a-0000-0000-0000-0000000000d1', 'riyaziyyat', 7);
  assert (v->>'existing')::boolean = false and v->>'test_id' <> t, 'yazilmis diaqnostikadan sonra yenisi yaranmadi';
  insert into public.diag_fx values ('t2', v->>'test_id');
end $$;
reset role; reset request.jwt.claim.sub;
do $$
declare tok text; t uuid; att uuid; ans jsonb := '[]'::jsonb; r record; oid uuid;
begin
  select val into tok from public.diag_fx where diag_fx.k = 'tok';
  select val::uuid into t from public.diag_fx where diag_fx.k = 't2';
  att := (public.rpc_start_attempt(tok, t)->>'attempt_id')::uuid;
  for r in select tq.question_id qid from public.test_questions tq where tq.test_id = t loop
    select o.id into oid from public.question_options o where o.question_id = r.qid and o.is_correct limit 1;
    ans := ans || jsonb_build_array(jsonb_build_object('q', r.qid, 'o', jsonb_build_array(oid)));
  end loop;
  perform public.rpc_submit_attempt(tok, att, ans);
end $$;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000da';
do $$
declare v jsonb; e jsonb; t1 text;
begin
  select val into t1 from public.diag_fx where diag_fx.k = 't_weak';
  v := public.rpc_diagnostic_result('5555000a-0000-0000-0000-0000000000d1', 'riyaziyyat');
  assert (v->>'weak_now')::int = 0 and (v->>'ok_now')::int = 12, 'ikinci: hamisi ok deyil';
  assert (v->>'weak_prev')::int = 1, 'weak_prev 1 deyil: ' || (v->>'weak_prev');
  assert v->'prev_at' <> 'null'::jsonb, 'prev_at yoxdur';
  select x into e from jsonb_array_elements(v->'topics') x where x->>'name' = t1;
  assert e->>'status' = 'ok' and e->>'prev_status' = 'weak', 'prev_status: ' || e::text;
  assert jsonb_array_length(v->'start') = 0, 'hamisi ok-de "basla" bos olmalidir';
end $$;
\echo 'OK  7 · ikinci diaqnostika: 1 zeif -> 0, her fesilde evvelki status'

-- =====================================================================
--  8. Sagird baxis rejimi (rpc_test_result) xerite dasiyir; abune bitende
--     muellimde xerite baglanir, bal qalir; sagirdin oz xeritesi qalir
-- =====================================================================
reset role; reset request.jwt.claim.sub;
do $$
declare tok text; t uuid; v jsonb;
begin
  select val into tok from public.diag_fx where diag_fx.k = 'tok';
  select val::uuid into t from public.diag_fx where diag_fx.k = 't1';
  v := public.rpc_test_result(tok, t);
  assert (v->>'diagnostic')::boolean and jsonb_array_length(v->'topics'->'topics') = 12, 'baxis rejiminde xerite yoxdur';
end $$;
update public.subscriptions set status = 'canceled', current_period_end = now() - interval '1 day';
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000da';
do $$
declare v jsonb;
begin
  v := public.rpc_diagnostic_result('5555000a-0000-0000-0000-0000000000d1', 'riyaziyyat');
  assert (v->>'paid')::boolean = false and (v->>'has')::boolean, 'abunesiz has/paid';
  assert v->'topics' = 'null'::jsonb and v->'start' = 'null'::jsonb and v->'weak_now' = 'null'::jsonb, 'abune bitende xerite acıq qaldi';
  assert (v->>'percent')::numeric = 100, 'bal itdi';
end $$;
reset role; reset request.jwt.claim.sub;
do $$
declare tok text; t uuid; v jsonb;
begin
  select val into tok from public.diag_fx where diag_fx.k = 'tok';
  select val::uuid into t from public.diag_fx where diag_fx.k = 't2';
  v := public.rpc_test_result(tok, t);
  assert jsonb_array_length(v->'topics'->'topics') = 12, 'sagirdin oz xeritesi abuneden asili olmamalidir';
end $$;
\echo 'OK  8 · baxis rejimi xerite dasiyir; abune bitende muellim xeritesi baglanir, bal qalir, sagirdinki qalir'

-- =====================================================================
--  9. Valideyn: neticelerde "diag" nisani
-- =====================================================================
update public.subscriptions set status = 'active', current_period_end = now() + interval '30 days';
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000da';
do $$ begin perform public.rpc_parent_access('5555000a-0000-0000-0000-0000000000d1', true); end $$;
reset role; reset request.jwt.claim.sub;
insert into public.diag_fx values ('ptok',
  public.rpc_parent_login((select parent_code from public.students where id = '5555000a-0000-0000-0000-0000000000d1'))->>'token');
do $$
declare ptok text; v jsonb; n int;
begin
  select val into ptok from public.diag_fx where diag_fx.k = 'ptok';
  v := public.rpc_parent_home(ptok);
  select count(*) into n from jsonb_array_elements(v->'results') x where (x->>'diag')::boolean;
  assert n = 2, 'valideyn neticelerinde diaqnostika nisani: ' || n;
  assert (v::text) not like '%is_correct%', 'valideyne is_correct sizdi';
end $$;
\echo 'OK  9 · valideyn neticelerinde diaqnostika nisani var, duz cavab sizmir'

-- =====================================================================
--  10. Qoruyucular (119): "Yeniden yig" ve qrupa teyinat redd olunur
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000da';
do $$
declare t uuid; c uuid; ok1 boolean := false; ok2 boolean := false; ok3 boolean := false;
begin
  select val::uuid into t from public.diag_fx where diag_fx.k = 't2';
  select class_id into c from public.students where id = '5555000a-0000-0000-0000-0000000000d1';
  begin
    perform public.rpc_regenerate_test(t);
  exception when others then
    ok1 := sqlerrm like '%Diaqnostik test yeniden yigilmir%';
  end;
  assert ok1, 'diaqnostik test yeniden yigildi';
  assert (select count(*) from public.test_questions where test_id = t) = 36, 'suallar deyisdi';
  begin
    perform public.rpc_assign_test(c, t, null, 1, null);
  exception when others then
    ok2 := sqlerrm like '%yalniz oz sagirdine%';
  end;
  assert ok2, 'diaqnostik test qrupa teyin olundu';
  begin
    perform public.rpc_assign_test(c, t, null, 1, '5555000a-0000-0000-0000-0000000000d2');
  exception when others then
    ok3 := sqlerrm like '%yalniz oz sagirdine%';
  end;
  assert ok3, 'diaqnostik test basqa sagirde teyin olundu';
  assert (select count(*) from public.assignments where test_id = t) = 1, 'teyinat sayi deyisdi';
  -- oz sagirdine yeniden teyin (muddet uzatmaq) ise icazelidir
  perform public.rpc_assign_test(c, t, now() + interval '3 days', 1, '5555000a-0000-0000-0000-0000000000d1');
end $$;
reset role; reset request.jwt.claim.sub;
\echo 'OK 10 · diaqnostik test yeniden yigilmir, qrupa/basqasina verilmir; oz sagirdine uzatmaq olar'
drop table public.diag_fx;
