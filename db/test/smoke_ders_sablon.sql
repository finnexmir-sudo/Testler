-- =====================================================================
--  smoke_ders_sablon.sql : 926 - sablon (parametrik) sual ders qapisinda 2 sayilir
--
--  Dort ders, ayri fixture:
--    D1  10 sablon             -> cekili 20 (HAZIR), setir 10
--    D2   9 sablon             -> cekili 18 (yox),   setir 9
--    D3   5 sablon + 10 adi    -> cekili 20 (HAZIR), setir 15
--    D4  19 adi                -> cekili 19 (yox)    (kohne qayda eynen)
--  Yoxlanir:
--    1) app.ders_sual_sayi cekili sayir, app.ders_sual_setir setir sayir
--    2) rpc_plan_get: ders_n / ders_hazir cekili sayidan
--    3) rpc_plan_test(.., 'ders'): hazir ders -> 10 FERQLI sual (setir sayindan artiq yox), hamisi
--       dersin nisanli sualidir; hazir olmayan -> xeta (sessizce fesle dusmur)
--    4) D1-de test butun 10 setiri (sablon) goturur - cekili 20 deyil
--    5) rpc_plan_test fesil rejimi sablonla pozulmur
--
--  ISTIFADE:  psql -f db/test/smoke_ders_sablon.sql   (oz bazasinda; yoxla.sh)
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers;  delete from public.attempts;
delete from public.assignments;      delete from public.student_sessions;
delete from public.students;         delete from public.classes;
delete from public.subscriptions;
delete from public.test_questions tq using public.tests t
 where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.questions where topic_id in (select id from public.topics where slug = 'sb-fesil');   -- tekrar isletmek ucun
delete from public.topics where slug like 'sb-d%' or slug = 'sb-fesil';
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-0000000009a6','sb@t.az','{"full_name":"Sablon Muellim"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000009a6','tutor','SB hesabi','11110000-0000-0000-0000-0000000009a6');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000009a6','11110000-0000-0000-0000-0000000009a6',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code, level_id)
select 'cccc0000-0000-0000-0000-0000000009a6','aaaa0000-0000-0000-0000-0000000009a6',
       '11110000-0000-0000-0000-0000000009a6','tutor_group','SB qrupu','KODSB926', l.id
  from public.levels l where l.code = '3' and l.code ~ '^[0-9]+$';
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-0000000009a6', p.id, 'active', now() + interval '30 days'
  from public.plans p where p.slug = 'repetitor-25';

-- ------------------------------------------------- fixture: fesil + 4 ders + suallar
do $$
declare
  v_subj uuid; v_lev uuid; v_f uuid; v_d uuid; v_q uuid; i int; k int;
  v_cfg jsonb := '[["sb-d1",10,0],["sb-d2",9,0],["sb-d3",5,10],["sb-d4",0,19]]';
  x jsonb; v_slug text; v_p int; v_a int;
  v_say int := 0;
begin
  select id into v_subj from public.subjects where slug = 'riyaziyyat';
  select id into v_lev  from public.levels   where code = '3';
  insert into public.topics (subject_id, level_id, parent_id, name, slug, sort)
       values (v_subj, v_lev, null, 'SB fəsil 926', 'sb-fesil', 996) returning id into v_f;
  for x in select * from jsonb_array_elements(v_cfg) loop
    v_slug := x->>0; v_p := (x->>1)::int; v_a := (x->>2)::int;
    insert into public.topics (subject_id, level_id, parent_id, name, slug, sort)
         values (v_subj, v_lev, v_f, 'SB ' || v_slug, v_slug, 996 + (v_say % 5) + 1) returning id into v_d;
    v_say := v_say + 1;
    --  sablon suallar: her biri ferqli sozle + ferqli duz cavab ifadesi (generatorun oxsarliq/cavab suzgeci kecsin)
    for i in 1 .. v_p loop
      insert into public.questions (owner_type, subject_id, level_id, topic_id, kind, body, status, tags, params)
           values ('platform', v_subj, v_lev, v_f, 'single',
                   (array['Hesablayın: {a} + {b} ifadəsi neçədir',
                          '{a} ədədinə {b} əlavə edin',
                          'Cəmi tapın: {a} və {b}',
                          '{a} ilə {b}-nin cəmi hansıdır',
                          'Sayları toplayın: {a}, {b}'])[1 + (i % 5)] || ' (şablon ' || v_slug || ' ' || i || ')',
                   'published', array[app.ders_tag(v_slug)],
                   '{"vars":{"a":[100,999],"b":[100,999]}}'::jsonb)
        returning id into v_q;
      insert into public.question_options (question_id, ord, body, is_correct)
           values (v_q, 1, '{a+b+' || (i * 3) || '}', true),
                  (v_q, 2, '{a+b+' || (i * 3 + 1) || '}', false),
                  (v_q, 3, '{a+b+' || (i * 3 + 2) || '}', false);
    end loop;
    for i in 1 .. v_a loop
      insert into public.questions (owner_type, subject_id, level_id, topic_id, kind, body, status, tags)
           values ('platform', v_subj, v_lev, v_f, 'single',
                   (array['%s ədədinin kvadratı neçədir?','Tənliyi həll edin: x - %s = 0','%s ədədini 3-ə vurun',
                          '%s ilə 7-nin fərqi nədir?','%s ədədinin yarısı nədir?'])[1 + (i % 5)] || ' (adi ' || v_slug || ' ' || i || ')',
                   'published', array[app.ders_tag(v_slug)])
        returning id into v_q;
      insert into public.question_options (question_id, ord, body, is_correct)
           values (v_q, 1, (i * 17 + v_say * 101)::text, true),
                  (v_q, 2, (i * 17 + v_say * 101 + 1)::text, false),
                  (v_q, 3, (i * 17 + v_say * 101 + 2)::text, false);
    end loop;
  end loop;
end $$;

-- ------------------------------------------------- 1) sayimlar
do $$
declare v_f uuid := (select id from public.topics where slug = 'sb-fesil');
begin
  assert app.ders_sual_sayi(v_f, 'sb-d1') = 20, 'D1 cekili 20: ' || app.ders_sual_sayi(v_f, 'sb-d1');
  assert app.ders_sual_sayi(v_f, 'sb-d2') = 18, 'D2 cekili 18: ' || app.ders_sual_sayi(v_f, 'sb-d2');
  assert app.ders_sual_sayi(v_f, 'sb-d3') = 20, 'D3 cekili 20: ' || app.ders_sual_sayi(v_f, 'sb-d3');
  assert app.ders_sual_sayi(v_f, 'sb-d4') = 19, 'D4 cekili 19 (kohne qayda): ' || app.ders_sual_sayi(v_f, 'sb-d4');
  assert app.ders_sual_setir(v_f, 'sb-d1') = 10 and app.ders_sual_setir(v_f, 'sb-d2') = 9
     and app.ders_sual_setir(v_f, 'sb-d3') = 15 and app.ders_sual_setir(v_f, 'sb-d4') = 19, 'setir sayi';
  assert app.ders_sual_sayi(v_f, 'yoxdur-slug') = 0, 'bos hovuz 0 (null yox)';
  assert app.ders_min() = 20, 'hedd deyismeyib';
end $$;
\echo 'OK  1 · ders_sual_sayi cekili (sablon = 2), ders_sual_setir setir sayir; hedd 20'

-- ------------------------------------------------- plan qur, derslerin hamisini «kecildi» isarele
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000009a6';
select (public.rpc_plan_create('cccc0000-0000-0000-0000-0000000009a6','riyaziyyat','3')->>'ok') as plan_qurdu;
reset role; reset request.jwt.claim.sub;
update public.class_plan_items i set done_at = now()
  from public.topics t where t.id = i.topic_id and t.slug like 'sb-d%';

-- ------------------------------------------------- 2) rpc_plan_get
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000009a6';
do $$
declare v jsonb; it jsonb; ok_ boolean;
begin
  v := public.rpc_plan_get('cccc0000-0000-0000-0000-0000000009a6');
  for it in select e from jsonb_array_elements(v->'plans'->0->'items') e where (e->>'topic') like 'SB sb-d%' loop
    case it->>'topic'
      when 'SB sb-d1' then assert (it->>'ders_n')::int = 20 and (it->>'ders_hazir')::boolean, 'plan_get D1: ' || it::text;
      when 'SB sb-d2' then assert (it->>'ders_n')::int = 18 and not (it->>'ders_hazir')::boolean, 'plan_get D2: ' || it::text;
      when 'SB sb-d3' then assert (it->>'ders_n')::int = 20 and (it->>'ders_hazir')::boolean, 'plan_get D3: ' || it::text;
      when 'SB sb-d4' then assert (it->>'ders_n')::int = 19 and not (it->>'ders_hazir')::boolean, 'plan_get D4: ' || it::text;
    end case;
  end loop;
  assert (select count(*) from jsonb_array_elements(v->'plans'->0->'items') e where (e->>'topic') like 'SB sb-d%') = 4, '4 ders setiri';
end $$;
\echo 'OK  2 · rpc_plan_get: D1/D3 hazir (20), D2 (18) / D4 (19) hazir deyil'

-- ------------------------------------------------- 3-4) rpc_plan_test
--  Cagirislar muellim rolunda, yoxlamalar superuser-de (cedvellere birbaşa oxumaq authenticated-e baglidir).
reset role; reset request.jwt.claim.sub;
select set_config('smoke.i1', (select i.id::text from public.class_plan_items i join public.topics t on t.id = i.topic_id where t.slug = 'sb-d1'), false);
select set_config('smoke.i2', (select i.id::text from public.class_plan_items i join public.topics t on t.id = i.topic_id where t.slug = 'sb-d2'), false);
select set_config('smoke.i3', (select i.id::text from public.class_plan_items i join public.topics t on t.id = i.topic_id where t.slug = 'sb-d3'), false);
select set_config('smoke.i4', (select i.id::text from public.class_plan_items i join public.topics t on t.id = i.topic_id where t.slug = 'sb-d4'), false);

set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000009a6';
do $$
declare m text;
begin
  perform set_config('smoke.r1', public.rpc_plan_test(current_setting('smoke.i1')::uuid, 15, 'ders')::text, false);
  perform set_config('smoke.r3', public.rpc_plan_test(current_setting('smoke.i3')::uuid, 15, 'ders')::text, false);
  --  D2 (18) ve D4 (19): 'ders' sertle xeta, sessizce fesle dusmur
  begin perform public.rpc_plan_test(current_setting('smoke.i2')::uuid, 15, 'ders'); assert false, 'D2: hazir olmayan ders testi yigildi';
  exception when others then m := sqlerrm; end;
  assert m like '%kifayet qeder sual yoxdur%18 / 20%', 'D2 xetasinda cekili say (18 / 20): ' || m;
  begin perform public.rpc_plan_test(current_setting('smoke.i4')::uuid, 15, 'ders'); assert false, 'D4: hazir olmayan ders testi yigildi';
  exception when others then m := sqlerrm; end;
  assert m like '%kifayet qeder sual yoxdur%19 / 20%', 'D4 xetasinda say (19 / 20): ' || m;
  --  fesil rejimi sablonla pozulmur
  perform set_config('smoke.rf', public.rpc_plan_test(current_setting('smoke.i2')::uuid, 12, 'fesil')::text, false);
end $$;
reset role; reset request.jwt.claim.sub;

do $$
declare r jsonb; v_t uuid; n int; n_dist int;
begin
  --  D1: hazir ders, 10 sablon setir - butun 10-u goturulmelidir (cekili 20 yox)
  r := current_setting('smoke.r1')::jsonb;
  assert r->>'scope' = 'ders', 'D1 ders testi: ' || r::text;
  assert (r->>'pool')::int = 20 and (r->>'rows')::int = 10, 'D1 pool/rows: ' || r::text;
  v_t := (r->>'test_id')::uuid;
  select count(*), count(distinct tq.question_id) into n, n_dist from public.test_questions tq where tq.test_id = v_t;
  assert n = 10 and n_dist = 10, 'D1: 10 FERQLI sual (cekili 20 yox): ' || n || '/' || n_dist;
  assert (select count(*) from public.test_questions tq join public.questions q on q.id = tq.question_id
           where tq.test_id = v_t and not (q.tags @> array[app.ders_tag('sb-d1')])) = 0, 'D1: yad sual sizdi';
  assert (select count(*) from public.test_questions tq join public.questions q on q.id = tq.question_id
           where tq.test_id = v_t and q.params is not null) = 10, 'D1: hamisi sablondur';

  --  D3: qarisiq, 15 setir -> 10 sual
  r := current_setting('smoke.r3')::jsonb; v_t := (r->>'test_id')::uuid;
  select count(*), count(distinct tq.question_id) into n, n_dist from public.test_questions tq where tq.test_id = v_t;
  assert r->>'scope' = 'ders' and n = 10 and n_dist = 10, 'D3: 10 ferqli sual: ' || r::text || ' ' || n || '/' || n_dist;
  assert (r->>'rows')::int = 15 and (r->>'pool')::int = 20, 'D3 pool/rows: ' || r::text;
  assert (select count(*) from public.test_questions tq join public.questions q on q.id = tq.question_id
           where tq.test_id = v_t and not (q.tags @> array[app.ders_tag('sb-d3')])) = 0, 'D3: yad sual yoxdur';
end $$;
\echo 'OK  3 · hazir ders: 10 FERQLI sual, yalniz dersin nisanli suali; hazir olmayan: xeta'
\echo 'OK  4 · D1: butun 10 sablon setir goturuldu (cekili 20 yox)'

-- ------------------------------------------------- 5) fesil rejimi
do $$
declare r jsonb := current_setting('smoke.rf')::jsonb;
begin
  assert r->>'scope' = 'fesil' and (r->>'count')::int = 12, 'fesil rejimi: ' || r::text;
end $$;
\echo 'OK  5 · xeta mesaji cekili sayi gosterir (18 / 20, 19 / 20); fesil rejimi pozulmayib'

\echo 'smoke_ders_sablon: HAMISI KECDI'
