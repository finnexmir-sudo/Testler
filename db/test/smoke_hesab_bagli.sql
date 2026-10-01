-- =====================================================================
--  smoke_hesab_bagli.sql : 905 - sinaq bitende hesab baglanir (1-A / 2-B)
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments; delete from public.homework; delete from public.lessons;
delete from public.class_plan_items; delete from public.class_plans;
delete from public.student_sessions; delete from public.practice_days;
delete from public.students; delete from public.classes;
delete from public.subscriptions; delete from public.account_members;
delete from public.accounts; delete from public.user_roles;
delete from public.profiles; delete from auth.users;

insert into auth.users (id, email) values
  ('11110000-0000-0000-0000-0000000000c1','kilid@t.az'),     -- A: abunesiz (bagli)
  ('11110000-0000-0000-0000-0000000000c2','sinaq@t.az'),     -- B: aktiv sinaq
  ('11110000-0000-0000-0000-0000000000c3','admin@t.az'),     -- C: admin
  ('11110000-0000-0000-0000-0000000000c4','yad@t.az');       -- Y: ustelik uzvu deyil
insert into public.accounts (id, type, name, owner_id, is_demo) values
  ('aaaa0000-0000-0000-0000-0000000000c1','tutor','A bagli','11110000-0000-0000-0000-0000000000c1', false),
  ('aaaa0000-0000-0000-0000-0000000000c2','tutor','B sinaq','11110000-0000-0000-0000-0000000000c2', false),
  ('aaaa0000-0000-0000-0000-0000000000c3','tutor','C admin','11110000-0000-0000-0000-0000000000c3', false),
  ('aaaa0000-0000-0000-0000-0000000000c5','tutor','D numune','11110000-0000-0000-0000-0000000000c4', true);
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000c1','11110000-0000-0000-0000-0000000000c1',true),
  ('aaaa0000-0000-0000-0000-0000000000c2','11110000-0000-0000-0000-0000000000c2',true),
  ('aaaa0000-0000-0000-0000-0000000000c3','11110000-0000-0000-0000-0000000000c3',true);
insert into public.user_roles (user_id, role) values ('11110000-0000-0000-0000-0000000000c3','admin');
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
  select 'aaaa0000-0000-0000-0000-0000000000c2', p.id, 'trialing', now() + interval '20 days'
    from public.plans p where p.slug = 'repetitor-25';

--  siniflar (ayar sonuludur - hamisi yaranir)
update public.app_state set val = '{"on": false}' where key = 'hesab_bagli';
insert into public.classes (id, account_id, teacher_id, kind, name, join_code, level_id)
select v.id::uuid, v.acc::uuid, v.own::uuid, 'tutor_group', v.nm, v.kod, l.id
  from (values
    ('cccc0000-0000-0000-0000-0000000000c1','aaaa0000-0000-0000-0000-0000000000c1','11110000-0000-0000-0000-0000000000c1','A sinif','KODC0001'),
    ('cccc0000-0000-0000-0000-0000000000c2','aaaa0000-0000-0000-0000-0000000000c2','11110000-0000-0000-0000-0000000000c2','B sinif','KODC0002'),
    ('cccc0000-0000-0000-0000-0000000000c3','aaaa0000-0000-0000-0000-0000000000c3','11110000-0000-0000-0000-0000000000c3','C sinif','KODC0003'),
    ('cccc0000-0000-0000-0000-0000000000c5','aaaa0000-0000-0000-0000-0000000000c5','11110000-0000-0000-0000-0000000000c4','D sinif','KODC0005')
  ) v(id, acc, own, nm, kod)
  cross join (select l2.id from public.levels l2 join public.programs p on p.id = l2.program_id
               where p.slug = 'ibtidai' and l2.code = '3') l;
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code)
values ('5555000a-0000-0000-0000-0000000000c1','aaaa0000-0000-0000-0000-0000000000c1','cccc0000-0000-0000-0000-0000000000c1','11110000-0000-0000-0000-0000000000c1','Bagli Sagird','Bagli S.','SAGC0001'),
       ('5555000a-0000-0000-0000-0000000000c2','aaaa0000-0000-0000-0000-0000000000c2','cccc0000-0000-0000-0000-0000000000c2','11110000-0000-0000-0000-0000000000c2','Sinaq Sagird','Sinaq S.','SAGC0002');
\echo 'OK  0 · hazirliq: ayar SONUKDUR - her sey yaranir'

-- ---------------------------------------------------------------------
--  1. Ayar sonuk: kohne davranis (abunesiz hesab de yarada bilir)
-- ---------------------------------------------------------------------
do $$
begin
  assert not app.hesab_bagli_on(), 'ayar sonuk olmalidir';
  assert not app.account_locked('aaaa0000-0000-0000-0000-0000000000c1'), 'ayar sonukdur - bagli sayilmamalidir';
  insert into public.homework (class_id, created_by, body, due)
    values ('cccc0000-0000-0000-0000-0000000000c1','11110000-0000-0000-0000-0000000000c1','sonuk ayar', current_date);
  assert (select o_max from app.practice_quota('5555000a-0000-0000-0000-0000000000c1')) = app.practice_daily_limit(),
    'ayar sonukdur - mesq limiti 5';
end $$;
\echo 'OK  1 · ayar sonukken heç nə dəyişmir'

-- ---------------------------------------------------------------------
--  2. Ayar aciq: yalniz abunesiz hesab baglanir
-- ---------------------------------------------------------------------
update public.app_state set val = '{"on": true}' where key = 'hesab_bagli';
do $$
declare
  A uuid := 'aaaa0000-0000-0000-0000-0000000000c1';
  B uuid := 'aaaa0000-0000-0000-0000-0000000000c2';
  C uuid := 'aaaa0000-0000-0000-0000-0000000000c3';
  D uuid := 'aaaa0000-0000-0000-0000-0000000000c5';
begin
  assert app.account_locked(A), 'A (abunesiz) baglidir';
  assert not app.account_locked(B), 'B (aktiv sinaq) baglanmir';
  assert not app.account_locked(C), 'C (admin) baglanmir';
  assert not app.account_locked(D), 'D (numune) baglanmir';
end $$;
\echo 'OK  2 · yalniz abunesiz hesab baglidir (sinaq, admin, numune baglanmir)'

-- ---------------------------------------------------------------------
--  3. Baglı hesabda yaratma bloklanir (hər cədvəl), aktivdə olur
-- ---------------------------------------------------------------------
create or replace function pg_temp.bloklanir(p_sql text) returns boolean
language plpgsql as $$
begin
  execute p_sql;
  return false;
exception when insufficient_privilege then
  return true;
end $$;

do $$
begin
  assert pg_temp.bloklanir($q$insert into public.classes (account_id, teacher_id, kind, name, join_code, level_id)
    select 'aaaa0000-0000-0000-0000-0000000000c1','11110000-0000-0000-0000-0000000000c1','tutor_group','Yeni','KODX0001', id
      from public.levels limit 1$q$), 'qrup yaratmaq bloklanmalidir';
  assert pg_temp.bloklanir($q$insert into public.students (account_id, class_id, created_by, full_name, display_name, login_code)
    values ('aaaa0000-0000-0000-0000-0000000000c1','cccc0000-0000-0000-0000-0000000000c1','11110000-0000-0000-0000-0000000000c1','X','X','SAGX0001')$q$), 'sagird elave bloklanmalidir';
  assert pg_temp.bloklanir($q$insert into public.homework (class_id, created_by, body, due)
    values ('cccc0000-0000-0000-0000-0000000000c1','11110000-0000-0000-0000-0000000000c1','x', current_date)$q$), 'ev tapsirigi bloklanmalidir';
  assert pg_temp.bloklanir($q$insert into public.assignments (class_id, test_id, assigned_by)
    select 'cccc0000-0000-0000-0000-0000000000c1', id, '11110000-0000-0000-0000-0000000000c1' from public.tests limit 1$q$), 'tapsiriq bloklanmalidir';
  assert pg_temp.bloklanir($q$insert into public.lessons (class_id, held_on, created_by)
    values ('cccc0000-0000-0000-0000-0000000000c1', current_date, '11110000-0000-0000-0000-0000000000c1')$q$), 'dars qeydi bloklanmalidir';
  assert pg_temp.bloklanir($q$insert into public.class_plans (class_id, subject_id, level_id)
    select 'cccc0000-0000-0000-0000-0000000000c1', s.id, l.id from public.subjects s, public.levels l limit 1$q$), 'plan bloklanmalidir';
  --  aktiv sinaq: HAMISI kecir
  insert into public.homework (class_id, created_by, body, due)
    values ('cccc0000-0000-0000-0000-0000000000c2','11110000-0000-0000-0000-0000000000c2','sinaq ok', current_date);
  insert into public.lessons (class_id, held_on, created_by)
    values ('cccc0000-0000-0000-0000-0000000000c2', current_date, '11110000-0000-0000-0000-0000000000c2');
  --  admin ve numune
  insert into public.homework (class_id, created_by, body, due)
    values ('cccc0000-0000-0000-0000-0000000000c3','11110000-0000-0000-0000-0000000000c3','admin ok', current_date);
  insert into public.homework (class_id, created_by, body, due)
    values ('cccc0000-0000-0000-0000-0000000000c5','11110000-0000-0000-0000-0000000000c4','numune ok', current_date);
end $$;
\echo 'OK  3 · baglı hesabda qrup/sagird/tapsiriq/ev tapsirigi/dars/plan YARANMIR; sinaq/admin/numune yaranir'

-- ---------------------------------------------------------------------
--  4. Plan setri «Kecildi» bloklanir
-- ---------------------------------------------------------------------
update public.app_state set val = '{"on": false}' where key = 'hesab_bagli';
insert into public.class_plans (id, class_id, subject_id, level_id)
  select 'bbbb0000-0000-0000-0000-0000000000c1','cccc0000-0000-0000-0000-0000000000c1', s.id, l.id
    from public.subjects s, public.levels l limit 1;
insert into public.class_plan_items (id, plan_id, topic_id, ord)
  select 'dddd0000-0000-0000-0000-0000000000c1','bbbb0000-0000-0000-0000-0000000000c1', t.id, 1 from public.topics t limit 1;
update public.app_state set val = '{"on": true}' where key = 'hesab_bagli';
do $$
begin
  assert pg_temp.bloklanir($q$update public.class_plan_items set done_at = now() where id = 'dddd0000-0000-0000-0000-0000000000c1'$q$),
    '«Kecildi» bloklanmalidir';
  update public.class_plan_items set test_id = null where id = 'dddd0000-0000-0000-0000-0000000000c1';   -- done_at-siz yenilenme olur
end $$;
\echo 'OK  4 · plan «Kecildi» bloklanir, diger yenilenmeler yox'

-- ---------------------------------------------------------------------
--  5. 2-B: sagird hele de neticeye/teste baxir; oz basina mesq baglidir
-- ---------------------------------------------------------------------
do $$
declare q record;
begin
  select * into q from app.practice_quota('5555000a-0000-0000-0000-0000000000c1');
  assert q.o_max = 0, 'baglı hesabin sagirdinde mesq limiti 0: ' || q.o_max;
  select * into q from app.practice_quota('5555000a-0000-0000-0000-0000000000c2');
  assert q.o_max = app.practice_daily_limit() and q.o_paid, 'aktiv sinaqda mesq adidir: ' || q.o_max;
  --  verilmis testin cehdi (attempts) bloklanmir
  insert into public.attempts (test_id, student_id, status, percent, finished_at)
    select id, '5555000a-0000-0000-0000-0000000000c1', 'submitted', 50, now() from public.tests limit 1;
end $$;
\echo 'OK  5 · sagird: cehd/netice davam edir, oz basina mesq baglidir (2-B)'

-- ---------------------------------------------------------------------
--  6. Uzatma: abune verilen kimi her sey geri qayidir; guzest daxil
-- ---------------------------------------------------------------------
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
  select 'aaaa0000-0000-0000-0000-0000000000c1', p.id, 'trialing', now() + interval '30 days'
    from public.plans p where p.slug = 'repetitor-25';
do $$
begin
  assert not app.account_locked('aaaa0000-0000-0000-0000-0000000000c1'), 'uzadilandan sonra baglanmir';
  insert into public.homework (class_id, created_by, body, due)
    values ('cccc0000-0000-0000-0000-0000000000c1','11110000-0000-0000-0000-0000000000c1','uzadildi', current_date);
  update public.subscriptions set current_period_end = now() - (app.grace_days() - 1 || ' days')::interval
   where account_id = 'aaaa0000-0000-0000-0000-0000000000c1';
  assert not app.account_locked('aaaa0000-0000-0000-0000-0000000000c1'), 'guzest daxilindedir - baglanmir';
  update public.subscriptions set current_period_end = now() - (app.grace_days() + 1 || ' days')::interval
   where account_id = 'aaaa0000-0000-0000-0000-0000000000c1';
  assert app.account_locked('aaaa0000-0000-0000-0000-0000000000c1'), 'guzest bitdi - baglidir';
end $$;
\echo 'OK  6 · abune/uzatma acir; guzest muddeti daxilinde baglanmir, sonra baglanir'

-- ---------------------------------------------------------------------
--  7. rpc_account_lock: yalniz uzv oz hesabi ucun bilir; sebeb duz deyilir
-- ---------------------------------------------------------------------
--  A hazirda: son abune 'trialing', guzest de bitib -> sinaq bitib
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000c1';
do $$
declare r jsonb;
begin
  r := public.rpc_account_lock('aaaa0000-0000-0000-0000-0000000000c1');
  assert (r->>'locked')::boolean, 'A oz hesabi ucun «bagli» goruur';
  assert r->>'kind' = 'sinaq', 'sinaq bitib: ' || (r->>'kind');
  assert r->>'ends' is not null, 'bitme tarixi var';
  assert not (public.rpc_account_lock('aaaa0000-0000-0000-0000-0000000000c2')->>'locked')::boolean,
    'basqasinin hesabi haqqinda melumat yoxdur';
end $$;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000c2';
do $$
begin
  assert not (public.rpc_account_lock('aaaa0000-0000-0000-0000-0000000000c2')->>'locked')::boolean, 'B baglı deyil';
end $$;
reset role; reset request.jwt.claim.sub;
--  PULLU abune bitib: status 'active' -> «abune bitib» (sinaq yox)
update public.subscriptions set status = 'active' where account_id = 'aaaa0000-0000-0000-0000-0000000000c1';
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000c1';
do $$
declare r jsonb;
begin
  r := public.rpc_account_lock('aaaa0000-0000-0000-0000-0000000000c1');
  assert (r->>'locked')::boolean and r->>'kind' = 'abune', 'pullu abune bitib: ' || (r->>'kind');
end $$;
reset role; reset request.jwt.claim.sub;
--  hec vaxt abunesi olmayib
delete from public.subscriptions where account_id = 'aaaa0000-0000-0000-0000-0000000000c1';
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000c1';
do $$
declare r jsonb;
begin
  r := public.rpc_account_lock('aaaa0000-0000-0000-0000-0000000000c1');
  assert (r->>'locked')::boolean and r->>'kind' = 'yox', 'abunesi olmayan: ' || (r->>'kind');
end $$;
reset role; reset request.jwt.claim.sub;
do $$
begin
  assert not has_function_privilege('anon', 'public.rpc_account_lock(uuid)', 'EXECUTE'), 'anon cagira bilmir';
end $$;
\echo 'OK  7 · rpc_account_lock: uzv ucun dogru; sebeb: sinaq / abune / yox; anon yox'

--  temizlik: ayar yerli standartinda (sonuk)
update public.app_state set val = '{"on": false}' where key = 'hesab_bagli';
\echo 'HESAB BAGLI: BUTUN YOXLAMALAR KECDI'
