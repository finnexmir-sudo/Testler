-- =====================================================================
--  smoke_ev_tapsirigi.sql : metnle ev tapsirigi (db/191)
--
--  Iddialar: muellim qrupa ve tek sagirde yazir · basqa muellim yaza
--  bilmir · sagird yalniz qrupa ve OZUNE aid olani gorur · «etdim»
--  deyir, geri alir · valideyn eyni siyahini gorur · muellim siyahisi
--  «nece nefer etdi» deyir · silinir · bos metn redd olunur.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.homework_done; delete from public.homework;
delete from public.parent_sessions; delete from public.student_sessions;
delete from public.students; delete from public.classes;
delete from public.attempt_answers; delete from public.attempts; delete from public.assignments;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.question_options o using public.questions q where q.id = o.question_id and q.owner_type = 'educator';
delete from public.questions where owner_type = 'educator';
delete from public.subscriptions;
delete from public.account_members; delete from public.accounts;
delete from public.user_roles; delete from public.profiles; delete from auth.users;
insert into auth.users (id, email) values
  ('11110000-0000-0000-0000-0000000000e1','ev-muellim@t.az'),
  ('11110000-0000-0000-0000-0000000000e2','ev-basqa@t.az');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000e1','tutor','Ev hesabi','11110000-0000-0000-0000-0000000000e1'),
  ('aaaa0000-0000-0000-0000-0000000000e2','tutor','Basqa hesab','11110000-0000-0000-0000-0000000000e2');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000e1','11110000-0000-0000-0000-0000000000e1',true),
  ('aaaa0000-0000-0000-0000-0000000000e2','11110000-0000-0000-0000-0000000000e2',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-0000000000e1','aaaa0000-0000-0000-0000-0000000000e1',
   '11110000-0000-0000-0000-0000000000e1','tutor_group','Ev qrupu','EVQRUP01');
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code, parent_code) values
  ('dddd0000-0000-0000-0000-0000000000e1','aaaa0000-0000-0000-0000-0000000000e1','cccc0000-0000-0000-0000-0000000000e1',
   '11110000-0000-0000-0000-0000000000e1','Aysu Ev','Aysu','EVAYSU01','VEVAYSU1'),
  ('dddd0000-0000-0000-0000-0000000000e2','aaaa0000-0000-0000-0000-0000000000e1','cccc0000-0000-0000-0000-0000000000e1',
   '11110000-0000-0000-0000-0000000000e1','Kenan Ev','Kenan','EVKENAN1','VEVKENA1');

--  1. muellim: qrupa ve tek sagirde yazir; bos metn redd
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000e1';
do $$
declare r jsonb; bos boolean := false;
begin
  r := public.rpc_homework_add('cccc0000-0000-0000-0000-0000000000e1', '  12-ci paraqrafı oxu  ', current_date + 3, null);
  assert (r->>'ok')::boolean, 'qrupa yazilmadi';
  r := public.rpc_homework_add('cccc0000-0000-0000-0000-0000000000e1', 'Vurma cədvəlini təkrarla', null, 'dddd0000-0000-0000-0000-0000000000e2');
  assert (r->>'ok')::boolean, 'tek sagirde yazilmadi';
  begin
    perform public.rpc_homework_add('cccc0000-0000-0000-0000-0000000000e1', '   ', null, null);
  exception when others then bos := true;
  end;
  assert bos, 'bos metn qebul olundu';
end $$;
reset role; reset request.jwt.claim.sub;
--  cedvele birbasa baxis - yalniz sahib gorur
do $$
declare n int;
begin
  select count(*) into n from public.homework; assert n = 2, 'homework sayi: ' || n;
  assert (select body from public.homework where student_id is null) = '12-ci paraqrafı oxu', 'btrim islemedi';
end $$;

--  2. basqa muellim yaza bilmir, siyahini gore bilmir
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000e2';
do $$
declare yox boolean := false;
begin
  begin
    perform public.rpc_homework_add('cccc0000-0000-0000-0000-0000000000e1', 'Yad', null, null);
  exception when insufficient_privilege then yox := true;
  end;
  assert yox, 'basqa muellim qrupa yazdi';
  yox := false;
  begin
    perform public.rpc_homework_list('cccc0000-0000-0000-0000-0000000000e1');
  exception when insufficient_privilege then yox := true;
  end;
  assert yox, 'basqa muellim siyahini gordu';
end $$;
reset role; reset request.jwt.claim.sub;

--  3. sagird (Aysu): qrupa olani gorur, Kenana olani GORMUR; etdim / geri al
set role anon;
do $$
declare tok text; d jsonb; n int;
begin
  tok := (public.rpc_student_login('EVAYSU01'))->>'token';
  d := public.rpc_student_tests(tok);
  assert jsonb_array_length(d->'homework') = 1, 'Aysu ' || jsonb_array_length(d->'homework') || ' tapsiriq gorur (1 olmalidir)';
  assert d->'homework'->0->>'body' = '12-ci paraqrafı oxu', 'metn: ' || (d->'homework'->0->>'body');
  assert not (d->'homework'->0->>'done')::boolean, 'hele edilmeyib olmalidir';
  perform public.rpc_student_homework_done(tok, (d->'homework'->0->>'id')::uuid, true);
  d := public.rpc_student_tests(tok);
  assert (d->'homework'->0->>'done')::boolean, '«etdim» yazilmadi';
  perform public.rpc_student_homework_done(tok, (d->'homework'->0->>'id')::uuid, false);
  d := public.rpc_student_tests(tok);
  assert not (d->'homework'->0->>'done')::boolean, 'geri alinmadi';
  perform public.rpc_student_homework_done(tok, (d->'homework'->0->>'id')::uuid, true);
  --  Kenana verileni Aysu «etdim» deye bilmez
  begin
    perform public.rpc_student_homework_done(tok, (select id from public.homework where student_id is not null), true);
    raise exception 'KECDI';
  exception when others then
    if sqlerrm = 'KECDI' then raise exception 'Aysu basqasinin tapsirigini isareledi'; end if;
  end;
  --  Kenan ikisini de gorur
  tok := (public.rpc_student_login('EVKENAN1'))->>'token';
  d := public.rpc_student_tests(tok);
  assert jsonb_array_length(d->'homework') = 2, 'Kenan ' || jsonb_array_length(d->'homework') || ' gorur (2 olmalidir)';
  assert (d->'homework'->0->>'done')::boolean = false, 'sira: edilmeyen evvel';
end $$;
reset role;

--  4. valideyn (Aysunun): eyni siyahi, «done» ile
set role anon;
do $$
declare tok text; d jsonb;
begin
  tok := (public.rpc_parent_login('VEVAYSU1'))->>'token';
  d := public.rpc_parent_home(tok);
  assert jsonb_array_length(d->'homework') = 1, 'valideyn ' || jsonb_array_length(d->'homework') || ' gorur';
  assert (d->'homework'->0->>'done')::boolean, 'valideyn «etdim»i gormur';
end $$;
reset role;

--  5. muellim siyahisi: nece nefer etdi; silme
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000e1';
do $$
declare l jsonb; g jsonb;
begin
  l := public.rpc_homework_list('cccc0000-0000-0000-0000-0000000000e1');
  assert jsonb_array_length(l) = 2, 'siyahi: ' || jsonb_array_length(l);
  select x into g from jsonb_array_elements(l) x where x->>'student_id' is null;
  assert (g->>'done')::int = 1 and (g->>'total')::int = 2, 'qrup tapsirigi: ' || g->>'done' || '/' || g->>'total';
  assert g->'done_names'->>0 = 'Aysu Ev', 'edenlerin adi: ' || (g->'done_names')::text;
  select x into g from jsonb_array_elements(l) x where x->>'student_id' is not null;
  assert g->>'student' = 'Kenan Ev' and (g->>'total')::int = 1, 'ferdi tapsiriq: ' || g::text;
  perform public.rpc_homework_del((g->>'id')::uuid);
end $$;
reset role; reset request.jwt.claim.sub;
do $$
declare n int;
begin
  select count(*) into n from public.homework; assert n = 1, 'silinmedi: ' || n;
end $$;

\echo 'OK  1 · ev tapsirigi: muellim yazir, sagird gorur ve «etdim» deyir, valideyn gorur, yad muellim girmir'

--  6. numune hesab: qurulanda ev tapsiriqlari da gelir (Tapsiriqlar ekrani bos olmasin)
delete from public.app_state where key = 'demo_reset';
do $$
declare v jsonb; n int; d int;
begin
  v := public.rpc_demo_reset();
  assert (v->>'ok')::boolean, 'numune qurulmadi';
  select count(*) into n from public.homework h
    join public.classes c on c.id = h.class_id where c.account_id = app.demo_account();
  assert n >= 4, 'numune hesabda ev tapsirigi: ' || n || ' (>= 4 gozlenilir)';
  select count(*) into d from public.homework_done hd
    join public.homework h on h.id = hd.homework_id
    join public.classes c on c.id = h.class_id where c.account_id = app.demo_account();
  assert d >= 1, 'numune hesabda «etdim» yoxdur';
  assert exists (select 1 from public.homework h join public.classes c on c.id = h.class_id
                  where c.account_id = app.demo_account() and h.student_id is not null), 'numune ferdi tapsiriq yoxdur';
end $$;
\echo 'OK  2 · numune hesab ev tapsiriqlari ile qurulur (qrup + ferdi + «etdim»)'

--  7. (194) «Bu gunun dersi» -> hw; Icmal -> hw_alerts (son tarix bu gun, etmeyen var)
delete from public.homework_done; delete from public.homework;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000e1';
--  iki ayri emr = iki ayri created_at (eyni tranzaksiyada now() eynidir)
select public.rpc_homework_add('cccc0000-0000-0000-0000-0000000000e1', 'Bu gün üçün tapşırıq', (now() at time zone 'Asia/Baku')::date, null) \g /dev/null
select pg_sleep(0.01) \g /dev/null
select public.rpc_homework_add('cccc0000-0000-0000-0000-0000000000e1', 'Sabah üçün tapşırıq', (now() at time zone 'Asia/Baku')::date + 1, null) \g /dev/null
do $$
declare r jsonb; h jsonb; d jsonb;
begin
  r := public.rpc_lesson_prep('cccc0000-0000-0000-0000-0000000000e1');
  h := r->'hw';
  assert h is not null and h->>'body' = 'Sabah üçün tapşırıq', 'hw sonuncu tapsiriq olmalidir: ' || coalesce(h::text, 'null');
  assert (h->>'done')::int = 0 and (h->>'total')::int = 2, 'hw done/total: ' || h->>'done' || '/' || h->>'total';
  assert jsonb_array_length(h->'undone') = 2, 'etmeyenler 2 olmalidir';
  d := public.rpc_home(null);
  assert jsonb_array_length(d->'hw_alerts') = 1, 'siqnal: yalniz bu gunku (1), gelen: ' || jsonb_array_length(d->'hw_alerts');
  assert d->'hw_alerts'->0->>'body' = 'Bu gün üçün tapşırıq', 'siqnal metni';
  assert (d->'hw_alerts'->0->>'undone')::int = 2, 'siqnalda etmeyen sayi';
end $$;
reset role; reset request.jwt.claim.sub;
--  hamisi edende siqnal itir
select set_config('smoke.hid', (select id::text from public.homework where body = 'Bu gün üçün tapşırıq'), false) \g /dev/null
set role anon;
do $$
declare tok text; d jsonb; hid uuid := current_setting('smoke.hid')::uuid;
begin
  tok := (public.rpc_student_login('EVAYSU01'))->>'token';
  perform public.rpc_student_homework_done(tok, hid, true);
  tok := (public.rpc_student_login('EVKENAN1'))->>'token';
  perform public.rpc_student_homework_done(tok, hid, true);
end $$;
reset role;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000e1';
do $$
declare d jsonb;
begin
  d := public.rpc_home(null);
  assert jsonb_array_length(d->'hw_alerts') = 0, 'hami edib - siqnal qalmali deyil';
end $$;
reset role; reset request.jwt.claim.sub;
\echo 'OK  3 · 194: Bu gunun dersi son tapsirigi kim etdi/etmedi ile verir; siqnal yalniz son tarixi catmis ve etmeyen olanda'
