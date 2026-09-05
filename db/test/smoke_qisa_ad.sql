-- =====================================================================
--  smoke_qisa_ad.sql : qisa ad qrupda tekrarlanmir (db/124)
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments;     delete from public.student_sessions;
delete from public.students;        delete from public.classes;
delete from public.subscriptions;
delete from public.account_members; delete from public.accounts;
delete from public.user_roles;      delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-0000000000a1','qa@t.az','{"full_name":"Qisa Muellim"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000a1','tutor','QA hesabi','11110000-0000-0000-0000-0000000000a1');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000a1','11110000-0000-0000-0000-0000000000a1',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-0000000000a1','aaaa0000-0000-0000-0000-0000000000a1',
   '11110000-0000-0000-0000-0000000000a1','tutor_group','QA qrup','KODQA001'),
  ('cccc0000-0000-0000-0000-0000000000a2','aaaa0000-0000-0000-0000-0000000000a1',
   '11110000-0000-0000-0000-0000000000a1','tutor_group','QA basqa','KODQA002');

insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-0000000000a1', p.id, 'active', now() + interval '30 days'
  from public.plans p where p.slug = 'repetitor-25';

\echo '--- hazirliq tamam'

set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000a1';
do $$
declare c uuid := 'cccc0000-0000-0000-0000-0000000000a1';
        d text;
begin
  perform public.rpc_add_student(c, 'Murad Hüseynov');
  select display_name into d from public.students where full_name = 'Murad Hüseynov';
  assert d = 'Murad H.', 'ilk: ' || d;
  perform public.rpc_add_student(c, 'Murad Həsənli');
  select display_name into d from public.students where full_name = 'Murad Həsənli';
  assert d = 'Murad Hə.', 'ikinci 2 herf olmali: ' || d;
  perform public.rpc_add_student(c, 'Murad Hədiyev');
  select display_name into d from public.students where full_name = 'Murad Hədiyev';
  assert d = 'Murad Hədiyev', 'ucuncu tam soyad olmali: ' || d;
  perform public.rpc_add_student(c, 'Murad Hədiyev');
  --  eyni tranzaksiyada created_at eynidir - siraya yox, varliga baxiriq
  assert exists (select 1 from public.students where display_name = 'Murad Hədiyev 2'),
         'eyniadli: say olmali';
end $$;
\echo 'OK  1 · tekrar: H. -> Hə. -> tam soyad -> say'

do $$
declare d text;
begin
  --  basqa qrupda eyni qisa ad serbestdir
  perform public.rpc_add_student('cccc0000-0000-0000-0000-0000000000a2', 'Murad Hüseynli');
  select display_name into d from public.students where full_name = 'Murad Hüseynli';
  assert d = 'Murad H.', 'basqa qrup: ' || d;
  --  muellim oz qisa adini verirse toxunulmur
  perform public.rpc_add_student('cccc0000-0000-0000-0000-0000000000a1', 'Murad Hacıyev', 'Murad H.');
  select display_name into d from public.students where full_name = 'Murad Hacıyev';
  assert d = 'Murad H.', 'el ile verilen ad deyisdi: ' || d;
  --  tek sozlu ad
  perform public.rpc_add_student('cccc0000-0000-0000-0000-0000000000a1', 'Ayan');
  select display_name into d from public.students where full_name = 'Ayan';
  assert d = 'Ayan', 'tek soz: ' || d;
end $$;
\echo 'OK  2 · basqa qrup serbest, el ile verilen ad qalir, tek soz'

reset role; reset request.jwt.claim.sub;
do $$
declare n int;
begin
  --  movcud tekrarlar (kohne melumat) 124-un sonundaki blokla duzelir
  update public.students set display_name = 'Murad H.'
   where class_id = 'cccc0000-0000-0000-0000-0000000000a1';
end $$;
\i 124_qisa_ad_tekrar.sql
do $$
declare n int;
begin
  select count(distinct lower(display_name)) into n from public.students
   where class_id = 'cccc0000-0000-0000-0000-0000000000a1' and is_active;
  assert n = (select count(*) from public.students
               where class_id = 'cccc0000-0000-0000-0000-0000000000a1' and is_active),
         'kohne tekrarlar duzelmedi';
  assert exists (select 1 from public.students where display_name = 'Murad H.'),
         'ilk sagird oz adini itirdi';
end $$;
\echo 'OK  3 · movcud tekrarlar bir defelik duzelir, ilk sagird qalir'
