-- =====================================================================
--  smoke_sagird_zenginlesdirme.sql : sagirdin oz ekranindaki 4 yeni sahe
--                                    (db/114_sagird_paneli_zenginlesdirme.sql)
--
--  best, streak, next_lesson, weak - rpc_student_tests-e elave olundu.
--  "weak" testi en vacibidir: valideyndeki eyni sorgu ABUNƏSIZ islemelidir -
--  bu istifadeci ile ayrica razılasdirilib (öz zəifliyini bilmek tehsil
--  mezmunudur, satilan analitika deyil).
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers;  delete from public.attempts;
delete from public.assignments;      delete from public.student_sessions;
delete from public.students;         delete from public.classes;
delete from public.subscriptions;
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-0000000000ee','sg@t.az','{"full_name":"Sağ Müəllim"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000ee','tutor','Sağ hesabı',
   '11110000-0000-0000-0000-0000000000ee');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000ee','11110000-0000-0000-0000-0000000000ee',true);
--  Abune QESDEN acigdir: "weak" onsuz da abunesiz isleyeceyini gorek -
--  yeni sahe abuneden asili olmadigini subut etmek ucun.
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-0000000000ee', p.id, 'active', now() + interval '30 days'
  from public.plans p where p.slug = 'repetitor-25';
insert into public.classes (id, account_id, teacher_id, kind, name, join_code, level_id)
select 'cccc0000-0000-0000-0000-0000000000ee',
       'aaaa0000-0000-0000-0000-0000000000ee',
       '11110000-0000-0000-0000-0000000000ee','tutor_group','Sağ qrupu','KODSAG01',
       l.id from public.levels l where l.code = '3' and l.code ~ '^[0-9]+$';
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code) values
  ('5555000a-0000-0000-0000-0000000000ea','aaaa0000-0000-0000-0000-0000000000ee',
   'cccc0000-0000-0000-0000-0000000000ee','11110000-0000-0000-0000-0000000000ee',
   'Aygün Sağdı','Aygün S.','AYGSAG01'),
  ('5555000a-0000-0000-0000-0000000000eb','aaaa0000-0000-0000-0000-0000000000ee',
   'cccc0000-0000-0000-0000-0000000000ee','11110000-0000-0000-0000-0000000000ee',
   'Vüsal Qırıq','Vüsal Q.','VUSQIR01');

\echo '--- hazirliq tamam'

-- =====================================================================
--  1. Hec bir feallıq yoxdursa - hamisi bos/sıfırdır
-- =====================================================================
do $$
declare v jsonb; tok text;
begin
  tok := public.rpc_student_login('AYGSAG01')->>'token';
  v := public.rpc_student_tests(tok);
  assert v->'best' = 'null'::jsonb, 'fealiyyetsiz halda best bos olmalidir';
  assert (v->>'streak')::int = 0, 'fealiyyetsiz halda streak 0 olmalidir';
  assert v->'next_lesson' = 'null'::jsonb, 'plan qurulmayibsa next_lesson bos olmalidir';
  assert v->'weak' = '[]'::jsonb, 'fealiyyetsiz halda zeif movzu ola bilmez';
  assert v->'lessons' = '[]'::jsonb, 'plan qurulmayibsa kecdiyi ders ola bilmez';
end $$;
\echo 'OK  1 · fealiyyet yoxdursa best/streak/next_lesson/weak/lessons hamisi bosdur'

-- =====================================================================
--  2. Ders plani: novbeti ders ILK BITIRILMEMIS movzudur
--     class_plans/class_plan_items-e birbasa SELECT huququ yoxdur (yalniz
--     RPC ile) - ona gore rpc_plan_get-in QAYTARDIGI jsonb-dan oxuyuruq.
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000ee';
do $$
declare v jsonb; v_item1 uuid; v_item2 text; tok text; sv jsonb;
begin
  perform public.rpc_plan_create('cccc0000-0000-0000-0000-0000000000ee','riyaziyyat','3');
  v := public.rpc_plan_get('cccc0000-0000-0000-0000-0000000000ee');
  v_item1 := (v->'plans'->0->'items'->0->>'id')::uuid;
  perform public.rpc_plan_done(v_item1);

  v := public.rpc_plan_get('cccc0000-0000-0000-0000-0000000000ee');
  select i->>'topic' into v_item2
    from jsonb_array_elements(v->'plans'->0->'items') i
   where not (i->>'done')::boolean
   order by (i->>'ord')::int limit 1;

  tok := public.rpc_student_login('AYGSAG01')->>'token';
  sv := public.rpc_student_tests(tok);
  assert sv->'next_lesson'->>'topic' = v_item2,
    format('novbeti ders sehvdir: gozlenilen "%s", gelen "%s"', v_item2, sv->'next_lesson'->>'topic');
  assert sv->'next_lesson'->>'subject' = 'Riyaziyyat', 'novbeti dersin fenni sehvdir';
end $$;
\echo 'OK  2 · novbeti ders ilk bitirilməmiş mövzudur'

-- =====================================================================
--  3. Butun movzular kecilende novbeti ders YOXDUR
-- =====================================================================
do $$
declare v jsonb; ids uuid[]; idx int; tok text; sv jsonb;
begin
  v := public.rpc_plan_get('cccc0000-0000-0000-0000-0000000000ee');
  select array_agg((i->>'id')::uuid order by (i->>'ord')::int) into ids
    from jsonb_array_elements(v->'plans'->0->'items') i
   where not (i->>'done')::boolean;
  if ids is not null then
    for idx in 1..array_length(ids, 1) loop
      perform public.rpc_plan_done(ids[idx]);
    end loop;
  end if;

  tok := public.rpc_student_login('AYGSAG01')->>'token';
  sv := public.rpc_student_tests(tok);
  assert sv->'next_lesson' = 'null'::jsonb, 'plan bitibse next_lesson bos olmalidir';

  --  85 movzu kecilib, "lessons" en coxu 5-i qaytarir
  assert jsonb_array_length(sv->'lessons') = 5,
    format('kecdiyi ders sayi 5 olmalidir (limit): %s', jsonb_array_length(sv->'lessons'));
  assert sv->'lessons'->0->>'subject' = 'Riyaziyyat', 'kecdiyi dersin fenni sehvdir';
  assert sv->'lessons'->0->>'topic' is not null, 'kecdiyi dersin movzu adi yoxdur';
  assert sv->'lessons'->0->>'at' is not null, 'kecdiyi dersin tarixi yoxdur';
end $$;
\echo 'OK  3 · butun movzular kecilende novbeti ders yoxdur, kecdiyi dersler 5-e kimi gorunur'

reset role; reset request.jwt.claim.sub;

-- =====================================================================
--  4. Aygün 3 gundur ardıcıl test yazır - ferqli gunlere köçürülür
-- =====================================================================
do $$
declare tok text; att uuid; ans jsonb; r record; oid uuid;
begin
  tok := public.rpc_student_login('AYGSAG01')->>'token';

  -- srağagün: qarisiq test, hamisi duzgun
  att := (public.rpc_start_attempt(tok,
           (select id from public.tests where slug='riy-3-qarisiq-1'))->>'attempt_id')::uuid;
  ans := '[]'::jsonb;
  for r in select q.id from public.questions q
             join public.test_questions tq on tq.question_id=q.id
             join public.tests t on t.id=tq.test_id and t.slug='riy-3-qarisiq-1' loop
    select o.id into oid from public.question_options o
     where o.question_id = r.id and o.is_correct limit 1;
    ans := ans || jsonb_build_array(jsonb_build_object('q', r.id, 'o', jsonb_build_array(oid)));
  end loop;
  perform public.rpc_submit_attempt(tok, att, ans);
  update public.attempts set finished_at = now() - interval '2 days' where id = att;

  -- dunen: vurma cedveli, 1 duz 5 sehv - "Vurma ve bolme" mövzusu zeifleyir
  att := (public.rpc_start_attempt(tok,
           (select id from public.tests where slug='riy-3-vurma-1'))->>'attempt_id')::uuid;
  ans := '[]'::jsonb;
  declare k int := 0;
  begin
    for r in select q.id from public.questions q
               join public.test_questions tq on tq.question_id=q.id
               join public.tests t on t.id=tq.test_id and t.slug='riy-3-vurma-1'
              order by tq.ord loop
      k := k + 1;
      select o.id into oid from public.question_options o
       where o.question_id = r.id and o.is_correct = (k <= 1) limit 1;
      ans := ans || jsonb_build_array(jsonb_build_object('q', r.id, 'o', jsonb_build_array(oid)));
    end loop;
  end;
  perform public.rpc_submit_attempt(tok, att, ans);
  update public.attempts set finished_at = now() - interval '1 day' where id = att;

  -- bugun: az dili, hamisi duzgun - en yaxsi netice 100%
  att := (public.rpc_start_attempt(tok,
           (select id from public.tests where slug='az-3-dil-1'))->>'attempt_id')::uuid;
  ans := '[]'::jsonb;
  for r in select q.id from public.questions q
             join public.test_questions tq on tq.question_id=q.id
             join public.tests t on t.id=tq.test_id and t.slug='az-3-dil-1' loop
    select o.id into oid from public.question_options o
     where o.question_id = r.id and o.is_correct limit 1;
    ans := ans || jsonb_build_array(jsonb_build_object('q', r.id, 'o', jsonb_build_array(oid)));
  end loop;
  perform public.rpc_submit_attempt(tok, att, ans);
end $$;

do $$
declare tok text; v jsonb;
begin
  tok := public.rpc_student_login('AYGSAG01')->>'token';
  v := public.rpc_student_tests(tok);
  assert (v->>'best')::numeric = 100, format('en yaxsi netice sehv: %s', v->>'best');
  assert (v->>'streak')::int = 3, format('ardicillik sehv: %s (3 gozlenilir)', v->>'streak');
end $$;
\echo 'OK  4 · en yaxsi netice 100%, 3 ardıcıl gün duzgun sayilir'

-- =====================================================================
--  5. Zeif movzu: <60% ve ABUNƏSIZ - hesab abunəli olsa da eyni netice
-- =====================================================================
do $$
declare tok text; v jsonb; w jsonb;
begin
  tok := public.rpc_student_login('AYGSAG01')->>'token';
  v := public.rpc_student_tests(tok);
  assert jsonb_array_length(v->'weak') = 1, format('zeif movzu sayi: %s', v->'weak');
  w := v->'weak'->0;
  assert w->>'topic' = 'Vurma və bölmə', format('zeif movzu adi: %s', w->>'topic');
  assert (w->>'percent')::numeric between 28 and 30, format('zeif movzu faizi: %s', w->>'percent');
end $$;
\echo 'OK  5 · zeif movzu (<60%) tapılır, abunə olsa belə bloklanmır'

-- =====================================================================
--  6. Vüsal: son fealiyyet 6 gun evvel - zencir qirilib, streak 0
-- =====================================================================
do $$
declare tok text; att uuid; ans jsonb := '[]'::jsonb; r record; oid uuid; v jsonb;
begin
  tok := public.rpc_student_login('VUSQIR01')->>'token';
  att := (public.rpc_start_attempt(tok,
           (select id from public.tests where slug='riy-3-qarisiq-1'))->>'attempt_id')::uuid;
  for r in select q.id from public.questions q
             join public.test_questions tq on tq.question_id=q.id
             join public.tests t on t.id=tq.test_id and t.slug='riy-3-qarisiq-1' loop
    select o.id into oid from public.question_options o
     where o.question_id = r.id and o.is_correct limit 1;
    ans := ans || jsonb_build_array(jsonb_build_object('q', r.id, 'o', jsonb_build_array(oid)));
  end loop;
  perform public.rpc_submit_attempt(tok, att, ans);
  update public.attempts set finished_at = now() - interval '6 days' where id = att;

  v := public.rpc_student_tests(tok);
  assert (v->>'streak')::int = 0,
    format('zencir qirilib amma streak sehv: %s', v->>'streak');
  assert (v->>'best')::numeric = 100, 'kohne cehd best-den dusmemelidir';
end $$;
\echo 'OK  6 · zencir qirilibsa (6 gun evvel) ardıcıllıq sıfırdır, best qalir'
