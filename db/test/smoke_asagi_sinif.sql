-- =====================================================================
--  smoke_asagi_sinif.sql : teyinat siyahisi asagi sinif testlerini de
--                          gosterir (db/112_asagi_sinif_testleri.sql)
--
--  Generatorda bir nece sinif secmek 103-de acilmisdi, amma teyinat
--  ekrani hele de DEQIQ beraberlik teleb edirdi - isin yarisi
--  islemirdi.  Bu suite hemin yarini olcur.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.parent_sessions;
delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers;  delete from public.attempts;
delete from public.assignments;      delete from public.student_sessions;
delete from public.students;         delete from public.classes;
delete from public.test_questions tq using public.tests t
 where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.subscriptions;
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-0000000000d1','as@t.az','{"full_name":"Asagi M"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000d1','tutor','A hesabi',
   '11110000-0000-0000-0000-0000000000d1');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000d1','11110000-0000-0000-0000-0000000000d1',true);
--  8-ci sinif qrupu
insert into public.classes (id, account_id, teacher_id, kind, name, join_code,
                            program_id, level_id)
select 'cccc0000-0000-0000-0000-0000000000d1',
       'aaaa0000-0000-0000-0000-0000000000d1',
       '11110000-0000-0000-0000-0000000000d1','tutor_group','8-ci qrup','KODAS001',
       l.program_id, l.id
  from public.levels l where l.code = '8' limit 1;

--  Uc test: 5-ci sinif (asagi), 8-ci sinif (eyni), 9-cu sinif (yuxari)
insert into public.tests (id, owner_type, owner_id, program_id, subject_id,
                          level_id, title, status)
select 'ee000000-0000-0000-0000-0000000000d5','educator',
       '11110000-0000-0000-0000-0000000000d1',
       l.program_id, (select id from public.subjects where slug='riyaziyyat'),
       l.id, 'Bes - tekrar', 'published'
  from public.levels l where l.code = '5' limit 1;
insert into public.tests (id, owner_type, owner_id, program_id, subject_id,
                          level_id, title, status)
select 'ee000000-0000-0000-0000-0000000000d8','educator',
       '11110000-0000-0000-0000-0000000000d1',
       l.program_id, (select id from public.subjects where slug='riyaziyyat'),
       l.id, 'Sekkiz - cari', 'published'
  from public.levels l where l.code = '8' limit 1;
insert into public.tests (id, owner_type, owner_id, program_id, subject_id,
                          level_id, title, status)
select 'ee000000-0000-0000-0000-0000000000d9','educator',
       '11110000-0000-0000-0000-0000000000d1',
       l.program_id, (select id from public.subjects where slug='riyaziyyat'),
       l.id, 'Doqquz - yuxari', 'published'
  from public.levels l where l.code = '9' limit 1;

\echo '--- hazirliq tamam'

set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000d1';

-- =====================================================================
--  1. ASAGI sinif testi siyahida GORUNUR (esas duzelis)
-- =====================================================================
do $$
declare v jsonb; n int;
begin
  v := public.rpc_available_tests('cccc0000-0000-0000-0000-0000000000d1');
  select count(*) into n from jsonb_array_elements(v) x
   where x->>'title' = 'Bes - tekrar';
  assert n = 1,
    '5-ci sinif testi 8-ci sinif qrupunda gorunmur - muellim onu vere bilmir';
end $$;
\echo 'OK  1 · asagi sinif testi teyinat siyahisinda gorunur'

-- =====================================================================
--  2. Qrupun OZ sinfi yene gorunur
-- =====================================================================
do $$
declare v jsonb; n int;
begin
  v := public.rpc_available_tests('cccc0000-0000-0000-0000-0000000000d1');
  select count(*) into n from jsonb_array_elements(v) x
   where x->>'title' = 'Sekkiz - cari';
  assert n = 1, 'qrupun oz sinfinin testi itdi';
end $$;
\echo 'OK  2 · qrupun oz sinfi yerinde qalir'

-- =====================================================================
--  3. YUXARI sinif testi GORUNMUR - sehv ehtimali yuksekdir
-- =====================================================================
do $$
declare v jsonb; n int;
begin
  v := public.rpc_available_tests('cccc0000-0000-0000-0000-0000000000d1');
  select count(*) into n from jsonb_array_elements(v) x
   where x->>'title' = 'Doqquz - yuxari';
  assert n = 0, '9-cu sinif testi 8-ci sinif qrupuna teklif olunur';
end $$;
\echo 'OK  3 · yuxari sinif testi teklif olunmur'

-- =====================================================================
--  4. Sinifsiz test hemise gorunur (kohne davranis pozulmayib)
-- =====================================================================
do $$
declare v jsonb; n int;
begin
  insert into public.tests (id, owner_type, owner_id, program_id, subject_id,
                            title, status)
  select 'ee000000-0000-0000-0000-0000000000d0','educator',
         '11110000-0000-0000-0000-0000000000d1',
         (select id from public.programs limit 1),
         (select id from public.subjects where slug='riyaziyyat'),
         'Sinifsiz', 'published';
  v := public.rpc_available_tests('cccc0000-0000-0000-0000-0000000000d1');
  select count(*) into n from jsonb_array_elements(v) x
   where x->>'title' = 'Sinifsiz';
  assert n = 1, 'sinifsiz test itdi';
end $$;
\echo 'OK  4 · sinifsiz test hemise gorunur'

-- =====================================================================
--  5. Sinifsiz QRUP butun testleri gorur (kohne davranis)
-- =====================================================================
do $$
declare v jsonb; n int;
begin
  update public.classes set level_id = null, program_id = null
   where id = 'cccc0000-0000-0000-0000-0000000000d1';
  v := public.rpc_available_tests('cccc0000-0000-0000-0000-0000000000d1');
  select count(*) into n from jsonb_array_elements(v) x
   where x->>'title' in ('Bes - tekrar','Sekkiz - cari','Doqquz - yuxari');
  assert n = 3, 'sinifsiz qrupda uc testin hamisi gorunmelidir, geldi: ' || n;
end $$;
\echo 'OK  5 · sinifsiz qrupda suzgec yoxdur'

-- =====================================================================
--  6. Setirde SINIF adi gelir - ekran onu gostere bilsin
-- =====================================================================
do $$
declare v jsonb; t text;
begin
  v := public.rpc_available_tests('cccc0000-0000-0000-0000-0000000000d1');
  select x->>'level' into t from jsonb_array_elements(v) x
   where x->>'title' = 'Bes - tekrar';
  assert t is not null and t <> '',
    'setirde sinif adi yoxdur - ekran asagi sinifi nisanlaya bilmez';
end $$;
\echo 'OK  6 · setirde sinif adi gelir'

\echo 'ASAGI SINIF: BUTUN YOXLAMALAR KECDI'
