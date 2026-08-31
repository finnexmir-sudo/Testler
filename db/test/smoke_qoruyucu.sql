-- =====================================================================
--  smoke_qoruyucu.sql : istifadedeki movzu silinmir
--                       (db/102_movzu_qoruyucu.sql)
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
delete from public.topics where parent_id is not null;
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-0000000000fa','q@t.az','{"full_name":"Qoruyucu M"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000fa','tutor','Q hesabi',
   '11110000-0000-0000-0000-0000000000fa');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000fa','11110000-0000-0000-0000-0000000000fa',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code, level_id)
select 'cccc0000-0000-0000-0000-0000000000fa',
       'aaaa0000-0000-0000-0000-0000000000fa',
       '11110000-0000-0000-0000-0000000000fa','tutor_group','Q qrupu','KODQOR01',
       l.id from public.levels l where l.code = '3' and l.code ~ '^[0-9]+$';
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-0000000000fa', p.id, 'active', now() + interval '30 days'
  from public.plans p where p.slug = 'repetitor-25';

--  bos, istifadesiz movzu - silinebilmelidir
insert into public.topics (subject_id, level_id, slug, name, sort)
select t.subject_id, t.level_id, 'test-bos-movzu', 'Bos movzu', 9999
  from public.topics t
  join public.levels l on l.id = t.level_id
 where l.code = '3' and t.parent_id is null limit 1;

set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000fa';
select public.rpc_plan_create('cccc0000-0000-0000-0000-0000000000fa','riyaziyyat','3');
reset role; reset request.jwt.claim.sub;

\echo '--- hazirliq tamam'

-- =====================================================================
--  1. Ders planinda duran movzu SILINMIR - xeta atir
--     (kohne davranis: sessizce silinirdi, planda setir yox olurdu)
-- =====================================================================
do $$
declare tid uuid; ok boolean := false;
begin
  select topic_id into tid from public.class_plan_items limit 1;
  assert tid is not null, 'plan setiri yaranmayib';
  begin
    delete from public.topics where id = tid;
  exception when foreign_key_violation then ok := true;
  end;
  assert ok, 'PLANDA duran movzu silinebildi - qoruyucu islemir';
end $$;
\echo 'OK  1 · planda duran movzu silinmir'

-- =====================================================================
--  2. Silinme cehdi plan setirini POZMAYIB
-- =====================================================================
do $$
declare n int;
begin
  select count(*) into n from public.class_plan_items;
  assert n > 0, 'plan setirleri itib';
end $$;
\echo 'OK  2 · ugursuz silme cehdi plani pozmur'

-- =====================================================================
--  3. Istifadesiz movzu YENE silinir - qoruyucu hər şeyi kilidlemir
-- =====================================================================
do $$
declare tid uuid; n int;
begin
  select id into tid from public.topics where slug = 'test-bos-movzu';
  assert tid is not null, 'bos movzu tapilmadi';
  assert not app.topu_islekdir(tid), 'bos movzu islek sayilir';
  delete from public.topics where id = tid;
  select count(*) into n from public.topics where slug = 'test-bos-movzu';
  assert n = 0, 'istifadesiz movzu silinmedi';
end $$;
\echo 'OK  3 · istifadesiz movzu yene silinir'

-- =====================================================================
--  4. VALIDEYNI silmek de bloklanir - ovlad plan setiridirse
--     (topics.parent_id cascade-dir, ovlad plan setirine catir)
-- =====================================================================
do $$
declare par uuid; alt uuid; ok boolean := false; pid uuid;
begin
  select i.topic_id into par from public.class_plan_items i limit 1;
  --  hemin movzuya alt movzu veririk ve plani yeniden qururuq ki,
  --  plan setiri ALT movzuya kecsin
  insert into public.topics (subject_id, level_id, parent_id, slug, name, sort)
  select t.subject_id, t.level_id, t.id, 'test-alt-movzu', 'Alt movzu', 10
    from public.topics t where t.id = par
  returning id into alt;

  select id into pid from public.class_plans limit 1;
  delete from public.class_plan_items where plan_id = pid;
  insert into public.class_plan_items (plan_id, topic_id, ord)
  values (pid, alt, 1);

  begin
    delete from public.topics where id = par;   -- ovlad cascade -> plan restrict
  exception when foreign_key_violation then ok := true;
  end;
  assert ok, 'ovladi planda olan VALIDEYN silinebildi';
end $$;
\echo 'OK  4 · alt movzusu planda olan valideyn de silinmir'

-- =====================================================================
--  5. Plan silinende setirler YENE gedir - o yol baglanmayib
-- =====================================================================
do $$
declare pid uuid; n int;
begin
  select id into pid from public.class_plans limit 1;
  delete from public.class_plans where id = pid;
  select count(*) into n from public.class_plan_items where plan_id = pid;
  assert n = 0, 'plan silindi, setirleri qaldi';
end $$;
\echo 'OK  5 · plan silinende setirleri gedir (o FK deyismeyib)'

-- =====================================================================
--  6. app.topu_islekdir dord elaqeni de goturur
-- =====================================================================
do $$
declare tid uuid;
begin
  --  suali olan movzu
  select q.topic_id into tid from public.questions q
   where q.topic_id is not null limit 1;
  assert app.topu_islekdir(tid), 'suali olan movzu islek sayilmir';
  --  alt movzusu olan movzu
  select parent_id into tid from public.topics where slug = 'test-alt-movzu';
  assert app.topu_islekdir(tid), 'alt movzusu olan movzu islek sayilmir';
end $$;
\echo 'OK  6 · app.topu_islekdir sual ve alt movzunu goturur'

-- =====================================================================
--  7. Koməkci funksiya anon/authenticated-e ACIQ DEYIL
-- =====================================================================
do $$
begin
  if has_function_privilege('anon', 'app.topu_islekdir(uuid)', 'EXECUTE') then
    raise exception 'anon komekci funksiyani cagira bilir';
  end if;
  if has_function_privilege('authenticated', 'app.topu_islekdir(uuid)', 'EXECUTE') then
    raise exception 'authenticated komekci funksiyani cagira bilir';
  end if;
end $$;
\echo 'OK  7 · komekci funksiya yalniz baxim ucundur'

\echo 'QORUYUCU: BUTUN YOXLAMALAR KECDI'
