-- =====================================================================
--  smoke_push_tick.sql : 912 - son tarix ve gundelik xatirlatmalar
--  Hamisi tranzaksiyada, sonda GERI alinir.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;
begin;

insert into auth.users (id, email) values
  ('11110000-0000-0000-0000-00000000e6a1', 'pt1@t.az'),
  ('11110000-0000-0000-0000-00000000e6a2', 'pt2@t.az');
insert into public.accounts (id, type, name, owner_id, is_demo) values
  ('aaaa0000-0000-0000-0000-00000000e6a1', 'tutor', 'PT1', '11110000-0000-0000-0000-00000000e6a1', false),
  ('aaaa0000-0000-0000-0000-00000000e6a2', 'tutor', 'PT2 (abunesiz)', '11110000-0000-0000-0000-00000000e6a2', false);
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-00000000e6a1', '11110000-0000-0000-0000-00000000e6a1', true),
  ('aaaa0000-0000-0000-0000-00000000e6a2', '11110000-0000-0000-0000-00000000e6a2', true);
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-00000000e6a1', p.id, 'trialing', now() + interval '20 days'
  from public.plans p where p.slug = 'sagird-basi';
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-00000000e6a1', 'aaaa0000-0000-0000-0000-00000000e6a1', '11110000-0000-0000-0000-00000000e6a1', 'tutor_group', 'PT sinif 1', 'PTS00001'),
  ('cccc0000-0000-0000-0000-00000000e6a3', 'aaaa0000-0000-0000-0000-00000000e6a2', '11110000-0000-0000-0000-00000000e6a2', 'tutor_group', 'PT sinif 3', 'PTS00003');
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code) values
  ('5555000a-0000-0000-0000-00000000e6a1', 'aaaa0000-0000-0000-0000-00000000e6a1', 'cccc0000-0000-0000-0000-00000000e6a1', '11110000-0000-0000-0000-00000000e6a1', 'Aysu A', 'Aysu A.', 'PTSTU001'),
  ('5555000a-0000-0000-0000-00000000e6a2', 'aaaa0000-0000-0000-0000-00000000e6a1', 'cccc0000-0000-0000-0000-00000000e6a1', '11110000-0000-0000-0000-00000000e6a1', 'Bəhruz B', 'Bəhruz B.', 'PTSTU002'),
  ('5555000a-0000-0000-0000-00000000e6a4', 'aaaa0000-0000-0000-0000-00000000e6a2', 'cccc0000-0000-0000-0000-00000000e6a3', '11110000-0000-0000-0000-00000000e6a2', 'Dilarə D', 'Dilarə D.', 'PTSTU004');
insert into public.push_subs (role, student_id, endpoint, p256dh, auth) values
  ('student', '5555000a-0000-0000-0000-00000000e6a1', 'https://fcm.googleapis.com/fcm/send/PT-1s-aaaaaaaaaaaaaaaa', repeat('B', 87), repeat('c', 22)),
  ('parent',  '5555000a-0000-0000-0000-00000000e6a1', 'https://fcm.googleapis.com/fcm/send/PT-1p-aaaaaaaaaaaaaaaa', repeat('B', 87), repeat('c', 22)),
  ('student', '5555000a-0000-0000-0000-00000000e6a2', 'https://fcm.googleapis.com/fcm/send/PT-2s-aaaaaaaaaaaaaaaa', repeat('B', 87), repeat('c', 22)),
  ('student', '5555000a-0000-0000-0000-00000000e6a4', 'https://fcm.googleapis.com/fcm/send/PT-4s-aaaaaaaaaaaaaaaa', repeat('B', 87), repeat('c', 22));
insert into public.tests (id, program_id, subject_id, title)
select ('7e570000-0000-0000-0000-00000000e6b' || i)::uuid, pr.id, sb.id, 'Tick test ' || i
  from generate_series(1, 4) i,
       (select id from public.programs limit 1) pr,
       (select id from public.subjects limit 1) sb;
update public.app_state set val = '{"on": false}' where key = 'hesab_bagli';

--  push SONUK: tapsiriqlar yaranir (trigger bos), sonra yandiririq
update public.app_state set val = '{"on": false}' where key = 'push';
insert into public.assignments (class_id, test_id, opens_at, closes_at) values
  ('cccc0000-0000-0000-0000-00000000e6a1', '7e570000-0000-0000-0000-00000000e6b1', now() - interval '2 days', now() + interval '20 hours'),   -- xatirlat
  ('cccc0000-0000-0000-0000-00000000e6a1', '7e570000-0000-0000-0000-00000000e6b2', now() - interval '2 days', now() + interval '1 hour'),     -- cox gec
  ('cccc0000-0000-0000-0000-00000000e6a1', '7e570000-0000-0000-0000-00000000e6b3', now() - interval '2 days', now() + interval '3 days'),     -- tezdir
  ('cccc0000-0000-0000-0000-00000000e6a1', '7e570000-0000-0000-0000-00000000e6b4', now() - interval '1 hour', now() + interval '20 hours');   -- yeni verilib
--  Bəhruz b1-i artiq edib
insert into public.attempts (student_id, test_id, class_id, status, finished_at)
values ('5555000a-0000-0000-0000-00000000e6a2', '7e570000-0000-0000-0000-00000000e6b1', 'cccc0000-0000-0000-0000-00000000e6a1', 'submitted', now());

-- ------------------------------------------------ 1 · push sonukdur: heç ne
do $$ begin
  assert app.push_scan_deadlines() = 0, 'sonuk: 0';
  assert (app.push_tick())->>'on' = 'false', 'sonuk: tick on=false';
  assert (select count(*) from public.push_outbox) = 0, 'sonuk: novbe bos';
end $$;

-- ------------------------------------------------ 2 · son tarix
update public.app_state set val = '{"on": true, "quiet": false}' where key = 'push';
do $$
declare r record; n int;
begin
  n := app.push_scan_deadlines();
  assert n = 2, 'Aysu: sagird + valideyn = 2 bildiris, alindi ' || n;
  select * into r from public.push_outbox where role = 'student' and student_id = '5555000a-0000-0000-0000-00000000e6a1';
  assert r.kind = 'son_tarix' and r.body like '%Tick test 1%' and r.body like '%saat%', 'sagird metni: ' || r.body;
  assert r.body not like '%Aysu%', 'sagirde ad yazilmir';
  assert r.url = './sagird/', 'sagird url';
  select * into r from public.push_outbox where role = 'parent' and student_id = '5555000a-0000-0000-0000-00000000e6a1';
  assert r.body like 'Aysu A. üçün%' and r.body like '%Tick test 1%' and r.url = './valideyn/', 'valideyn metni: ' || r.body;
  assert not exists (select 1 from public.push_outbox where student_id = '5555000a-0000-0000-0000-00000000e6a2'), 'testi edən sagirde xatirlatma yoxdur';
  assert not exists (select 1 from public.push_outbox where body like '%Tick test 2%' or body like '%Tick test 3%' or body like '%Tick test 4%'),
    '1 saat qalan / 3 gun qalan / yeni verilmis: xatirlatma yoxdur';
  assert app.push_scan_deadlines() = 0, 'ikinci yoxlama tekrar yazmir';
  assert (select count(*) from public.push_outbox where kind = 'son_tarix') = 2, 'cemi 2';
end $$;

-- ------------------------------------------------ 3 · gundelik «5 sual»
do $$
declare
  v_sub uuid; v_top uuid; v_plan uuid; n int;
  t19 timestamptz := ((now() at time zone 'Asia/Baku')::date + time '19:30') at time zone 'Asia/Baku';
  t12 timestamptz := ((now() at time zone 'Asia/Baku')::date + time '12:00') at time zone 'Asia/Baku';
  t22 timestamptz := ((now() at time zone 'Asia/Baku')::date + time '22:00') at time zone 'Asia/Baku';
begin
  delete from public.push_outbox;
  assert app.push_scan_daily(t12) = 0, '12:00-da gundelik getmir';
  assert app.push_scan_daily(t22) = 0, '22:00-dan sonra getmir';
  assert app.push_scan_daily(t19) = 0, 'kecilmis movzu yoxdur: getmir';

  select t.id, t.subject_id into v_top, v_sub from public.topics t limit 1;
  insert into public.class_plans (class_id, subject_id, level_id) values ('cccc0000-0000-0000-0000-00000000e6a1', v_sub, (select id from public.levels limit 1)) returning id into v_plan;
  insert into public.class_plan_items (plan_id, topic_id, ord, done_at) values (v_plan, v_top, 1, now() - interval '2 days');

  n := app.push_scan_daily(t19);
  assert n = 2, 'Aysu ve Bəhruz (abunesi aktiv, movzu kecilib) = 2, alindi ' || n;
  assert exists (select 1 from public.push_outbox where role = 'student' and student_id = '5555000a-0000-0000-0000-00000000e6a1' and kind = 'gundelik' and title like '%5 sual%'), 'Aysu gundelik';
  assert not exists (select 1 from public.push_outbox where role = 'parent'), 'valideynə gundelik getmir';
  assert not exists (select 1 from public.push_outbox where student_id = '5555000a-0000-0000-0000-00000000e6a4'), 'abunesiz hesab: getmir';
  assert app.push_scan_daily(t19) = 0, 'eyni gun ikinci defe yox';

  --  Bəhruz bu gun paketi bitirib -> yalniz Aysu
  delete from public.push_outbox;
  insert into public.daily_packs (student_id, day, items, answers, done_at)
  values ('5555000a-0000-0000-0000-00000000e6a2', (t19 at time zone 'Asia/Baku')::date, '[{"q":"x"}]', '[{"ok":true}]', now());
  assert app.push_scan_daily(t19) = 1, 'paketi bitiren Bəhruz-a getmir';
  assert exists (select 1 from public.push_outbox where student_id = '5555000a-0000-0000-0000-00000000e6a1') and
         not exists (select 1 from public.push_outbox where student_id = '5555000a-0000-0000-0000-00000000e6a2'), 'yalniz Aysu';
end $$;

-- ------------------------------------------------ 4 · tick hamisini cagirir, xeta tick-i dayandirmir
do $$
declare j jsonb;
begin
  j := app.push_tick();
  assert (j->>'on') = 'true' and j ? 'son_tarix' and j ? 'gundelik', 'tick neticesi: ' || j::text;
end $$;

rollback;
\echo smoke_push_tick: HAMISI KECDI
