-- =====================================================================
--  smoke_test_sil.sql : oz testini silmek / adini deyismek (db/193)
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;
delete from public.attempt_answers; delete from public.attempts; delete from public.assignments;
delete from public.student_sessions; delete from public.students; delete from public.classes;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.question_options o using public.questions q where q.id = o.question_id and q.owner_type = 'educator';
delete from public.questions where owner_type = 'educator';
delete from public.subscriptions; delete from public.account_members; delete from public.accounts;
delete from public.user_roles; delete from public.profiles; delete from auth.users;
insert into auth.users (id, email) values
  ('11110000-0000-0000-0000-0000000000d1','sil-muellim@t.az'),
  ('11110000-0000-0000-0000-0000000000d2','sil-basqa@t.az');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000d1','tutor','Sil hesabi','11110000-0000-0000-0000-0000000000d1');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000d1','11110000-0000-0000-0000-0000000000d1',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-0000000000d1','aaaa0000-0000-0000-0000-0000000000d1',
   '11110000-0000-0000-0000-0000000000d1','tutor_group','Sil qrupu','SILQRUP1');
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code) values
  ('dddd0000-0000-0000-0000-0000000000d1','aaaa0000-0000-0000-0000-0000000000d1','cccc0000-0000-0000-0000-0000000000d1',
   '11110000-0000-0000-0000-0000000000d1','Sil Sagird','Sil','SILSAG01');
insert into public.questions (id, owner_type, owner_id, account_id, subject_id, kind, body, points)
select 'eeee0000-0000-0000-0000-0000000000d1', 'educator', '11110000-0000-0000-0000-0000000000d1', 'aaaa0000-0000-0000-0000-0000000000d1', s.id, 'single', '1+1?', 1
  from (select id from public.subjects where slug = 'riyaziyyat' limit 1) s;
insert into public.question_options (id, question_id, body, is_correct, ord) values
  ('0000d000-0000-0000-0000-0000000000a1','eeee0000-0000-0000-0000-0000000000d1','2',true,1),
  ('0000d000-0000-0000-0000-0000000000a2','eeee0000-0000-0000-0000-0000000000d1','3',false,2);
insert into public.tests (id, owner_type, owner_id, program_id, subject_id, title, status, max_attempts)
select x.id, 'educator', '11110000-0000-0000-0000-0000000000d1',
       (select id from public.programs order by sort limit 1), (select id from public.subjects where slug = 'riyaziyyat' limit 1),
       x.t, 'published', 0
  from (values ('ffff0000-0000-0000-0000-0000000000d1'::uuid, 'Samir 1'), ('ffff0000-0000-0000-0000-0000000000d2'::uuid, 'Samir 1')) x(id, t);
insert into public.test_questions (test_id, question_id, ord) values
  ('ffff0000-0000-0000-0000-0000000000d1','eeee0000-0000-0000-0000-0000000000d1',1),
  ('ffff0000-0000-0000-0000-0000000000d2','eeee0000-0000-0000-0000-0000000000d1',1);
insert into public.assignments (class_id, test_id, assigned_by, max_attempts) values
  ('cccc0000-0000-0000-0000-0000000000d1','ffff0000-0000-0000-0000-0000000000d1','11110000-0000-0000-0000-0000000000d1',0),
  ('cccc0000-0000-0000-0000-0000000000d1','ffff0000-0000-0000-0000-0000000000d2','11110000-0000-0000-0000-0000000000d1',0);

--  1. sagird 2-ci testi isleyir -> o silinmir
set role anon;
do $$
declare tok text; d jsonb;
begin
  tok := (public.rpc_student_login('SILSAG01'))->>'token';
  d := public.rpc_start_attempt(tok, 'ffff0000-0000-0000-0000-0000000000d2');
  perform public.rpc_submit_attempt(tok, (d->>'attempt_id')::uuid,
    '[{"q":"eeee0000-0000-0000-0000-0000000000d1","o":["0000d000-0000-0000-0000-0000000000a1"]}]'::jsonb);
end $$;
reset role;

--  2. sahib: ad deyisir, islenmemis testi silir, islenmis test silinmir; yad muellim hec ne
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000d1';
do $$
declare r jsonb; e boolean := false;
begin
  r := public.rpc_test_rename('ffff0000-0000-0000-0000-0000000000d1', '  Samir — vurma  ');
  assert r->>'title' = 'Samir — vurma', 'ad: ' || r::text;
  begin perform public.rpc_test_rename('ffff0000-0000-0000-0000-0000000000d1', '   ');
  exception when others then e := true; end;
  assert e, 'bos ad qebul olundu';
  e := false;
  begin perform public.rpc_test_delete('ffff0000-0000-0000-0000-0000000000d2');
  exception when others then e := true; end;
  assert e, 'islenmis test silindi!';
  r := public.rpc_test_delete('ffff0000-0000-0000-0000-0000000000d1');
  assert (r->>'ok')::boolean, 'silinmedi';
end $$;
reset role; reset request.jwt.claim.sub;
do $$
declare n int;
begin
  select count(*) into n from public.tests where id = 'ffff0000-0000-0000-0000-0000000000d1'; assert n = 0, 'test qaldi';
  select count(*) into n from public.assignments where test_id = 'ffff0000-0000-0000-0000-0000000000d1'; assert n = 0, 'teyinat qaldi';
  select count(*) into n from public.test_questions where test_id = 'ffff0000-0000-0000-0000-0000000000d1'; assert n = 0, 'test_questions qaldi';
  select count(*) into n from public.questions where id = 'eeee0000-0000-0000-0000-0000000000d1'; assert n = 1, 'SUAL silindi - olmaz';
  select count(*) into n from public.tests where title = 'Samir 1'; assert n = 1, 'islenmis test itdi';
end $$;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000d2';
do $$
declare e boolean := false;
begin
  begin perform public.rpc_test_rename('ffff0000-0000-0000-0000-0000000000d2', 'Yad');
  exception when insufficient_privilege then e := true; end;
  assert e, 'yad muellim ad deyisdi';
  e := false;
  begin perform public.rpc_test_delete('ffff0000-0000-0000-0000-0000000000d2');
  exception when insufficient_privilege then e := true; end;
  assert e, 'yad muellim sildi';
end $$;
reset role; reset request.jwt.claim.sub;
--  3. platforma testi silinmir (admin olsa bele can_manage_test true - owner_type yoxlanir)
do $$
declare e boolean := false; pid uuid;
begin
  select id into pid from public.tests where owner_type = 'platform' limit 1;
  if pid is not null then
    begin perform public.rpc_test_delete(pid);
    exception when others then e := true; end;
    assert e, 'platforma testi silindi!';
  end if;
end $$;
\echo 'OK  1 · test sil / ad deyis: sahib, islenmemis; islenmis ve yad ve platforma - yox'
