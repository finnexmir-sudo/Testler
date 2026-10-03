-- =====================================================================
--  smoke_push_yeni.sql : 911 - teyinat yaranan kimi «yeni test» bildirisi
--  Hamisi tranzaksiyada, sonda GERI alinir.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;
begin;

insert into auth.users (id, email) values
  ('11110000-0000-0000-0000-00000000f6a1', 'py1@t.az'),
  ('11110000-0000-0000-0000-00000000f6a2', 'py2@t.az');
insert into public.accounts (id, type, name, owner_id, is_demo) values
  ('aaaa0000-0000-0000-0000-00000000f6a1', 'tutor', 'PY1', '11110000-0000-0000-0000-00000000f6a1', false),
  ('aaaa0000-0000-0000-0000-00000000f6a2', 'tutor', 'PY2 (abunesiz)', '11110000-0000-0000-0000-00000000f6a2', false);
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-00000000f6a1', '11110000-0000-0000-0000-00000000f6a1', true),
  ('aaaa0000-0000-0000-0000-00000000f6a2', '11110000-0000-0000-0000-00000000f6a2', true);
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-00000000f6a1', p.id, 'trialing', now() + interval '20 days'
  from public.plans p where p.slug = 'sagird-basi';
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-00000000f6a1', 'aaaa0000-0000-0000-0000-00000000f6a1', '11110000-0000-0000-0000-00000000f6a1', 'tutor_group', 'PY sinif 1', 'PYS00001'),
  ('cccc0000-0000-0000-0000-00000000f6a2', 'aaaa0000-0000-0000-0000-00000000f6a1', '11110000-0000-0000-0000-00000000f6a1', 'tutor_group', 'PY sinif 2', 'PYS00002'),
  ('cccc0000-0000-0000-0000-00000000f6a3', 'aaaa0000-0000-0000-0000-00000000f6a2', '11110000-0000-0000-0000-00000000f6a2', 'tutor_group', 'PY sinif 3', 'PYS00003');
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code) values
  ('5555000a-0000-0000-0000-00000000f6a1', 'aaaa0000-0000-0000-0000-00000000f6a1', 'cccc0000-0000-0000-0000-00000000f6a1', '11110000-0000-0000-0000-00000000f6a1', 'Aysu A', 'Aysu A.', 'PYSTU001'),
  ('5555000a-0000-0000-0000-00000000f6a2', 'aaaa0000-0000-0000-0000-00000000f6a1', 'cccc0000-0000-0000-0000-00000000f6a1', '11110000-0000-0000-0000-00000000f6a1', 'Bəhruz B', 'Bəhruz B.', 'PYSTU002'),
  ('5555000a-0000-0000-0000-00000000f6a3', 'aaaa0000-0000-0000-0000-00000000f6a1', 'cccc0000-0000-0000-0000-00000000f6a2', '11110000-0000-0000-0000-00000000f6a1', 'Cavid C', 'Cavid C.', 'PYSTU003'),
  ('5555000a-0000-0000-0000-00000000f6a4', 'aaaa0000-0000-0000-0000-00000000f6a2', 'cccc0000-0000-0000-0000-00000000f6a3', '11110000-0000-0000-0000-00000000f6a2', 'Dilarə D', 'Dilarə D.', 'PYSTU004');
--  abuneler (RPC-siz, birbaşa)
insert into public.push_subs (role, student_id, endpoint, p256dh, auth) values
  ('student', '5555000a-0000-0000-0000-00000000f6a1', 'https://fcm.googleapis.com/fcm/send/PY-1s-aaaaaaaaaaaaaaaa', repeat('B', 87), repeat('c', 22)),
  ('parent',  '5555000a-0000-0000-0000-00000000f6a1', 'https://fcm.googleapis.com/fcm/send/PY-1p-aaaaaaaaaaaaaaaa', repeat('B', 87), repeat('c', 22)),
  ('student', '5555000a-0000-0000-0000-00000000f6a2', 'https://fcm.googleapis.com/fcm/send/PY-2s-aaaaaaaaaaaaaaaa', repeat('B', 87), repeat('c', 22)),
  ('student', '5555000a-0000-0000-0000-00000000f6a3', 'https://fcm.googleapis.com/fcm/send/PY-3s-aaaaaaaaaaaaaaaa', repeat('B', 87), repeat('c', 22)),
  ('student', '5555000a-0000-0000-0000-00000000f6a4', 'https://fcm.googleapis.com/fcm/send/PY-4s-aaaaaaaaaaaaaaaa', repeat('B', 87), repeat('c', 22));
--  testler
insert into public.tests (id, program_id, subject_id, title)
select ('7e570000-0000-0000-0000-00000000f6b' || i)::uuid, pr.id, sb.id, 'Smoke test ' || i
  from generate_series(1, 4) i,
       (select id from public.programs limit 1) pr,
       (select id from public.subjects limit 1) sb;
update public.app_state set val = '{"on": false}' where key = 'hesab_bagli';

-- ------------------------------------------------ 1 · oldurme duymesi sonukdur
update public.app_state set val = '{"on": false}' where key = 'push';
insert into public.assignments (class_id, test_id) values
  ('cccc0000-0000-0000-0000-00000000f6a1', '7e570000-0000-0000-0000-00000000f6b1');
do $$ begin
  assert (select count(*) from public.push_outbox where kind = 'yeni_test') = 0, 'push sonukdur: novbeye yazilmamali';
end $$;
delete from public.assignments;

-- ------------------------------------------------ 2 · bir test, bir sinif
update public.app_state set val = '{"on": true}' where key = 'push';
insert into public.assignments (class_id, test_id) values
  ('cccc0000-0000-0000-0000-00000000f6a1', '7e570000-0000-0000-0000-00000000f6b1');
do $$
declare r record;
begin
  assert (select count(*) from public.push_outbox where kind = 'yeni_test') = 3, 'A:sagird, A:valideyn, B:sagird = 3 setir';
  select * into r from public.push_outbox where role = 'student' and student_id = '5555000a-0000-0000-0000-00000000f6a1';
  assert r.title = 'Yeni test' and r.body like '%Smoke test 1%', 'sagird metni test adini deyir: ' || r.body;
  assert r.body not like '%Aysu%', 'sagirde ad yazilmir';
  assert r.send_after = app.push_quiet_next(r.created_at) or r.send_after >= r.created_at - interval '1 second', 'vaxt';
  select * into r from public.push_outbox where role = 'parent' and student_id = '5555000a-0000-0000-0000-00000000f6a1';
  assert r.body like 'Aysu A. üçün%' and r.body like '%Smoke test 1%', 'valideyn metni usagin adini deyir: ' || r.body;
  assert not exists (select 1 from public.push_outbox where role = 'parent' and student_id = '5555000a-0000-0000-0000-00000000f6a2'),
    'valideyn abunesi olmayan usaga valideyn bildirisi yazilmir';
  assert not exists (select 1 from public.push_outbox where student_id = '5555000a-0000-0000-0000-00000000f6a3'), 'basqa sinif almamalidir';
end $$;

-- ------------------------------------------------ 2b · FERDI teyinat: yalniz hemin sagird (sinif yox)
insert into public.assignments (class_id, test_id, student_id) values
  ('cccc0000-0000-0000-0000-00000000f6a1', '7e570000-0000-0000-0000-00000000f6b4', '5555000a-0000-0000-0000-00000000f6a2');
do $$ begin
  assert exists (select 1 from public.push_outbox where role = 'student' and student_id = '5555000a-0000-0000-0000-00000000f6a2'
                    and body like '%Smoke test 4%'), 'ferdi: hedef sagirde var';
  assert not exists (select 1 from public.push_outbox where student_id = '5555000a-0000-0000-0000-00000000f6a1'
                        and body like '%Smoke test 4%'), 'ferdi: sinif yoldasina getmir';
end $$;
delete from public.assignments where test_id = '7e570000-0000-0000-0000-00000000f6b4';
delete from public.push_outbox where body like '%Smoke test 4%';

-- ------------------------------------------------ 3 · eyni sorguda iki test: BIR bildiris
insert into public.assignments (class_id, test_id) values
  ('cccc0000-0000-0000-0000-00000000f6a1', '7e570000-0000-0000-0000-00000000f6b2'),
  ('cccc0000-0000-0000-0000-00000000f6a1', '7e570000-0000-0000-0000-00000000f6b3');
do $$
declare r record;
begin
  select * into r from public.push_outbox
   where role = 'student' and student_id = '5555000a-0000-0000-0000-00000000f6a1' and body like '2 yeni test%';
  assert r.id is not null, 'iki test birlesdirilib: ' || coalesce((select string_agg(body, ' | ') from public.push_outbox where student_id = '5555000a-0000-0000-0000-00000000f6a1'), '-');
  select * into r from public.push_outbox
   where role = 'parent' and student_id = '5555000a-0000-0000-0000-00000000f6a1' and body like '%2 yeni test%';
  assert r.body like 'Aysu A. üçün 2 yeni test verildi.', 'valideyn birlesdirilmis metn: ' || r.body;
  assert (select count(*) from public.push_outbox where role = 'student' and student_id = '5555000a-0000-0000-0000-00000000f6a1') = 2, 'sagird: cemi 2 bildiris';
end $$;

-- ------------------------------------------------ 4 · gundelik hedd (2): ucuncu yazilmir, teyinat ise yaranir
insert into public.assignments (class_id, test_id) values
  ('cccc0000-0000-0000-0000-00000000f6a1', '7e570000-0000-0000-0000-00000000f6b4');
do $$ begin
  assert (select count(*) from public.assignments where test_id = '7e570000-0000-0000-0000-00000000f6b4') = 1, 'teyinat yaranib';
  assert (select count(*) from public.push_outbox where role = 'student' and student_id = '5555000a-0000-0000-0000-00000000f6a1') = 2, 'gunluk hedd: 3-cu yazilmir';
end $$;

-- ------------------------------------------------ 5 · qapali hesab: teyinat 905 ile bloklanir, bildiris de yoxdur
update public.app_state set val = '{"on": true}' where key = 'hesab_bagli';
do $$
begin
  begin
    insert into public.assignments (class_id, test_id) values
      ('cccc0000-0000-0000-0000-00000000f6a3', '7e570000-0000-0000-0000-00000000f6b1');
    assert false, 'qapali hesabda teyinat yaranmamali idi';
  exception when others then
    if sqlerrm not like 'Hesabın%' then raise; end if;
  end;
  assert not exists (select 1 from public.push_outbox where student_id = '5555000a-0000-0000-0000-00000000f6a4'), 'qapali hesaba bildiris yoxdur';
end $$;
update public.app_state set val = '{"on": false}' where key = 'hesab_bagli';

-- ------------------------------------------------ 6 · bitmis teyinat: yazilmir
insert into public.assignments (class_id, test_id, opens_at, closes_at) values
  ('cccc0000-0000-0000-0000-00000000f6a2', '7e570000-0000-0000-0000-00000000f6b1', now() - interval '2 days', now() - interval '1 day');
do $$ begin
  assert not exists (select 1 from public.push_outbox where student_id = '5555000a-0000-0000-0000-00000000f6a3'), 'bitmis teyinat bildiris vermir';
end $$;

-- ------------------------------------------------ 7 · gelecek teyinat: acilan vaxta saxlanir
insert into public.assignments (class_id, test_id, opens_at) values
  ('cccc0000-0000-0000-0000-00000000f6a2', '7e570000-0000-0000-0000-00000000f6b2', now() + interval '2 days');
do $$
declare r record;
begin
  select * into r from public.push_outbox where student_id = '5555000a-0000-0000-0000-00000000f6a3';
  assert r.id is not null, 'gelecek teyinat novbeye yazilib';
  assert r.send_after >= app.push_quiet_next(now() + interval '2 days') - interval '1 second',
    'acilma vaxtindan evvel getmir: ' || r.send_after;
end $$;

-- ------------------------------------------------ 8 · xeta teyinati pozmur
alter table public.push_outbox add constraint py_boz check (false) not valid;
update public.app_state set val = '{"on": true}' where key = 'push';
delete from public.push_outbox;
delete from public.assignments;
insert into public.assignments (class_id, test_id) values
  ('cccc0000-0000-0000-0000-00000000f6a1', '7e570000-0000-0000-0000-00000000f6b3');
do $$ begin
  assert (select count(*) from public.assignments) = 1, 'xeta olsa da teyinat qalir';
end $$;

rollback;
\echo smoke_push_yeni: HAMISI KECDI
