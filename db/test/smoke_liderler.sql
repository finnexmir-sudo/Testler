-- =====================================================================
--  smoke_liderler.sql : Icmalda "En yaxsi sagirdler" (db/163)
--
--  Iddialar: en azi 3 testi olan sagird siyahiya dusur · 1-2 testlik
--  sagird DUSMUR (bir defelik 100% siralamani pozmasin) · siralama
--  orta bala goredir · en cox 5 sətir · dayandirilmis sagird yoxdur ·
--  BASQA hesabin sagirdi gorunmur · abunesiz hesabda da doludur.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.attempt_answers;  delete from public.attempts;
delete from public.assignments;      delete from public.student_sessions;
delete from public.students;         delete from public.classes;
delete from public.subscriptions;
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email) values
  ('11110000-0000-0000-0000-0000000163a1','ld-a@t.az'),
  ('11110000-0000-0000-0000-0000000163a2','ld-b@t.az');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000163a1','tutor','Lider hesabi','11110000-0000-0000-0000-0000000163a1'),
  ('aaaa0000-0000-0000-0000-0000000163a2','tutor','Ozge hesab',  '11110000-0000-0000-0000-0000000163a2');
insert into public.account_members (account_id, user_id, is_admin) values
  ('aaaa0000-0000-0000-0000-0000000163a1','11110000-0000-0000-0000-0000000163a1',true),
  ('aaaa0000-0000-0000-0000-0000000163a2','11110000-0000-0000-0000-0000000163a2',true);
insert into public.subscriptions (account_id, plan_id, status, started_at, current_period_end)
select 'aaaa0000-0000-0000-0000-0000000163a1', p.id, 'active', now(), now() + interval '30 days'
  from public.plans p where p.slug = 'repetitor-25';
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('ccc00000-0000-0000-0000-0000000163a1','aaaa0000-0000-0000-0000-0000000163a1',
   '11110000-0000-0000-0000-0000000163a1','tutor_group','Lider qrupu','KODLDR01'),
  ('ccc00000-0000-0000-0000-0000000163a2','aaaa0000-0000-0000-0000-0000000163a2',
   '11110000-0000-0000-0000-0000000163a2','tutor_group','Ozge qrupu','KODLDR02');

--  A hesabi: 6 sagird.  s1..s4 uc testlik (ferqli orta), s5 iki testlik
--  (100% - siyahiya DUSMEMELIDIR), s6 dayandirilmis (3 test, 100%).
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code, is_active) values
  ('55500000-0000-0000-0000-0000000163a1','aaaa0000-0000-0000-0000-0000000163a1','ccc00000-0000-0000-0000-0000000163a1','11110000-0000-0000-0000-0000000163a1','Aysu Birinci','Aysu B.','LDR00001',true),
  ('55500000-0000-0000-0000-0000000163a2','aaaa0000-0000-0000-0000-0000000163a1','ccc00000-0000-0000-0000-0000000163a1','11110000-0000-0000-0000-0000000163a1','Bahar Ikinci','Bahar I.','LDR00002',true),
  ('55500000-0000-0000-0000-0000000163a3','aaaa0000-0000-0000-0000-0000000163a1','ccc00000-0000-0000-0000-0000000163a1','11110000-0000-0000-0000-0000000163a1','Cavid Ucuncu','Cavid U.','LDR00003',true),
  ('55500000-0000-0000-0000-0000000163a4','aaaa0000-0000-0000-0000-0000000163a1','ccc00000-0000-0000-0000-0000000163a1','11110000-0000-0000-0000-0000000163a1','Dilare Dorduncu','Dilare D.','LDR00004',true),
  ('55500000-0000-0000-0000-0000000163a5','aaaa0000-0000-0000-0000-0000000163a1','ccc00000-0000-0000-0000-0000000163a1','11110000-0000-0000-0000-0000000163a1','Elvin Azcehd','Elvin A.','LDR00005',true),
  ('55500000-0000-0000-0000-0000000163a6','aaaa0000-0000-0000-0000-0000000163a1','ccc00000-0000-0000-0000-0000000163a1','11110000-0000-0000-0000-0000000163a1','Fidan Dayandirilmis','Fidan D.','LDR00006',false),
  ('55500000-0000-0000-0000-0000000163b1','aaaa0000-0000-0000-0000-0000000163a2','ccc00000-0000-0000-0000-0000000163a2','11110000-0000-0000-0000-0000000163a2','Ozge Sagird','Ozge S.','LDR00007',true);

--  test lazimdir (attempts.test_id not null)
insert into public.tests (id, owner_type, owner_id, program_id, subject_id, title, status)
select '77700000-0000-0000-0000-0000000163a1','educator',
       '11110000-0000-0000-0000-0000000163a1', p.id, s.id, 'Lider testi', 'published'
  from public.programs p, public.subjects s
 where p.slug = 'ibtidai' and s.slug = 'riyaziyyat';

do $$
declare
  r record; i int;
begin
  for r in
    select * from (values
      ('55500000-0000-0000-0000-0000000163a1'::uuid, 3, 95),   -- 1-ci
      ('55500000-0000-0000-0000-0000000163a2'::uuid, 3, 88),
      ('55500000-0000-0000-0000-0000000163a3'::uuid, 4, 77),
      ('55500000-0000-0000-0000-0000000163a4'::uuid, 3, 60),
      ('55500000-0000-0000-0000-0000000163a5'::uuid, 2, 100),  -- az cehd
      ('55500000-0000-0000-0000-0000000163a6'::uuid, 3, 100),  -- dayandirilmis
      ('55500000-0000-0000-0000-0000000163b1'::uuid, 3, 100)   -- ozge hesab
    ) v(sid, n, pct)
  loop
    for i in 1..r.n loop
      insert into public.attempts (student_id, test_id, status, percent, finished_at)
      values (r.sid, '77700000-0000-0000-0000-0000000163a1', 'submitted', r.pct,
              now() - (i || ' days')::interval);
    end loop;
  end loop;
end $$;

--  A hesabinin sahibi kimi
do $$
declare v jsonb; t jsonb;
begin
  perform set_config('request.jwt.claim.sub','11110000-0000-0000-0000-0000000163a1', true);
  perform set_config('role','authenticated', true);
  v := public.rpc_home('aaaa0000-0000-0000-0000-0000000163a1');
  t := v->'top';

  assert jsonb_typeof(t) = 'array', 'top massiv deyil: ' || coalesce(jsonb_typeof(t),'null');
  assert jsonb_array_length(t) = 4,
    'uc testlik AKTIV sagird sayi 4 olmalidir, geldi: ' || jsonb_array_length(t);

  --  siralama: orta bala gore azalan
  assert t->0->>'name' = 'Aysu Birinci',  'birinci sehvdir: ' || (t->0->>'name');
  assert t->1->>'name' = 'Bahar Ikinci',  'ikinci sehvdir: '  || (t->1->>'name');
  assert t->3->>'name' = 'Dilare Dorduncu','sonuncu sehvdir: '|| (t->3->>'name');
  assert (t->0->>'avg')::int = 95, 'orta bal sehvdir: ' || (t->0->>'avg');
  assert (t->2->>'attempts')::int = 4, 'cehd sayi sehvdir: ' || (t->2->>'attempts');
  assert t->0->>'class' = 'Lider qrupu', 'qrup adi yoxdur';

  --  DUSMEMELI olanlar
  assert not (t::text like '%Elvin Azcehd%'),        '2 cehdlik sagird siyahida';
  assert not (t::text like '%Fidan Dayandirilmis%'), 'dayandirilmis sagird siyahida';
  assert not (t::text like '%Ozge Sagird%'),         'BASQA hesabin sagirdi siyahida - sizinti';
end $$;

\echo 'OK  1 · en azi 3 test serti, siralama, dayandirilmis/ozge hesab kenarda'

--  hedd: 5 setir.  A hesabina daha 3 aktiv sagird (hamisi 3 test).
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code, is_active) values
  ('55500000-0000-0000-0000-0000000163c1','aaaa0000-0000-0000-0000-0000000163a1','ccc00000-0000-0000-0000-0000000163a1','11110000-0000-0000-0000-0000000163a1','Gunel Besinci','Gunel B.','LDR00008',true),
  ('55500000-0000-0000-0000-0000000163c2','aaaa0000-0000-0000-0000-0000000163a1','ccc00000-0000-0000-0000-0000000163a1','11110000-0000-0000-0000-0000000163a1','Hesen Altinci','Hesen A.','LDR00009',true),
  ('55500000-0000-0000-0000-0000000163c3','aaaa0000-0000-0000-0000-0000000163a1','ccc00000-0000-0000-0000-0000000163a1','11110000-0000-0000-0000-0000000163a1','Ilaha Yeddinci','Ilaha Y.','LDR00010',true);
do $$
declare r record; i int;
begin
  for r in select * from (values
      ('55500000-0000-0000-0000-0000000163c1'::uuid, 91),
      ('55500000-0000-0000-0000-0000000163c2'::uuid, 90),
      ('55500000-0000-0000-0000-0000000163c3'::uuid, 89)
    ) v(sid, pct)
  loop
    for i in 1..3 loop
      insert into public.attempts (student_id, test_id, status, percent, finished_at)
      values (r.sid, '77700000-0000-0000-0000-0000000163a1', 'submitted', r.pct, now() - (i || ' days')::interval);
    end loop;
  end loop;
end $$;

do $$
declare v jsonb; t jsonb;
begin
  perform set_config('request.jwt.claim.sub','11110000-0000-0000-0000-0000000163a1', true);
  perform set_config('role','authenticated', true);
  v := public.rpc_home('aaaa0000-0000-0000-0000-0000000163a1');
  t := v->'top';
  assert jsonb_array_length(t) = 5,
    'hedd 5 olmalidir, geldi: ' || jsonb_array_length(t);
  --  95, 91, 90, 89, 88 - Dilare (60) kenarda qalir
  assert t->0->>'name' = 'Aysu Birinci', 'hedddən sonra birinci sehvdir';
  assert not (t::text like '%Dilare%'), 'en asagi bal siyahida qalib';
end $$;

\echo 'OK  2 · hedd 5 setirdir, en asagi bal kenarda qalir'

--  ABUNESIZ hesab (B): 'top' yene dolu olmalidir - siqnallardan ferqli
--  olaraq bu bolme paketle baglanmir (oz sagirdinin oz balidir).
do $$
declare v jsonb;
begin
  perform set_config('request.jwt.claim.sub','11110000-0000-0000-0000-0000000163a2', true);
  perform set_config('role','authenticated', true);
  v := public.rpc_home('aaaa0000-0000-0000-0000-0000000163a2');
  assert v->'alerts' = 'null'::jsonb, 'abunesiz hesabda siqnal null olmalidir';
  assert jsonb_array_length(v->'top') = 1,
    'abunesiz hesabda top dolu olmalidir, geldi: ' || jsonb_array_length(v->'top');
  assert v->'top'->0->>'name' = 'Ozge Sagird', 'B hesabinin oz sagirdi gorunmur';
end $$;

\echo 'OK  3 · abunesiz hesabda da dolu, yalniz oz sagirdi'
