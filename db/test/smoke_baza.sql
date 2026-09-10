-- smoke_baza.sql - db/179: bazanin hecmi, pullu/pulsuz bolgusu
\set ON_ERROR_STOP on
begin;

--  admin + iki hesab: biri abuneli, biri pulsuz
insert into auth.users (id, email) values
  ('bbbb0000-0000-0000-0000-0000000000a1','bzadmin@t.az'),
  ('bbbb0000-0000-0000-0000-0000000000a2','bzpullu@t.az'),
  ('bbbb0000-0000-0000-0000-0000000000a3','bzpulsuz@t.az');
insert into public.profiles (id, full_name) values
  ('bbbb0000-0000-0000-0000-0000000000a1','Bz Admin'),
  ('bbbb0000-0000-0000-0000-0000000000a2','Bz Pullu'),
  ('bbbb0000-0000-0000-0000-0000000000a3','Bz Pulsuz')
on conflict (id) do update set full_name = excluded.full_name;
insert into public.user_roles (user_id, role) values
  ('bbbb0000-0000-0000-0000-0000000000a1','admin') on conflict do nothing;

insert into public.accounts (id, owner_id, type, name) values
  ('bbba0000-0000-0000-0000-0000000000a2','bbbb0000-0000-0000-0000-0000000000a2','tutor','Bz Pullu hesab'),
  ('bbba0000-0000-0000-0000-0000000000a3','bbbb0000-0000-0000-0000-0000000000a3','tutor','Bz Pulsuz hesab');
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
  select 'bbba0000-0000-0000-0000-0000000000a2', p.id, 'active', now() + interval '30 days'
    from public.plans p where p.slug = 'sagird-basi';

insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('bbbc0000-0000-0000-0000-0000000000a2','bbba0000-0000-0000-0000-0000000000a2',
   'bbbb0000-0000-0000-0000-0000000000a2','tutor_group','Bz P','BZKOD001'),
  ('bbbc0000-0000-0000-0000-0000000000a3','bbba0000-0000-0000-0000-0000000000a3',
   'bbbb0000-0000-0000-0000-0000000000a3','tutor_group','Bz F','BZKOD002');
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code) values
  ('bbbd0000-0000-0000-0000-0000000000a2','bbba0000-0000-0000-0000-0000000000a2',
   'bbbc0000-0000-0000-0000-0000000000a2','bbbb0000-0000-0000-0000-0000000000a2','P Sagird','P S.','BZST0001'),
  ('bbbd0000-0000-0000-0000-0000000000a3','bbba0000-0000-0000-0000-0000000000a3',
   'bbbc0000-0000-0000-0000-0000000000a3','bbbb0000-0000-0000-0000-0000000000a3','F Sagird','F S.','BZST0002');

--  cavablar: pulluda 3, pulsuzda 1 - bolgu ferqi gorunsun
insert into public.tests (id, owner_type, owner_id, class_id, program_id, subject_id, title, status)
  select 'bbbe0000-0000-0000-0000-0000000000a2','educator',
         'bbbb0000-0000-0000-0000-0000000000a2','bbbc0000-0000-0000-0000-0000000000a2',
         (select id from public.programs limit 1), q.subject_id, 'Bz test','published'
    from public.questions q where q.owner_type='platform' limit 1;
insert into public.attempts (id, test_id, student_id, status, finished_at) values
  ('bbbf0000-0000-0000-0000-0000000000a2','bbbe0000-0000-0000-0000-0000000000a2',
   'bbbd0000-0000-0000-0000-0000000000a2','submitted', now()),
  ('bbbf0000-0000-0000-0000-0000000000a3','bbbe0000-0000-0000-0000-0000000000a2',
   'bbbd0000-0000-0000-0000-0000000000a3','submitted', now());
insert into public.attempt_answers (attempt_id, question_id, question_body, answered_at)
  select 'bbbf0000-0000-0000-0000-0000000000a2', q.id, q.body, now()
    from public.questions q where q.owner_type='platform' limit 3;
insert into public.attempt_answers (attempt_id, question_id, question_body, answered_at)
  select 'bbbf0000-0000-0000-0000-0000000000a3', q.id, q.body, now()
    from public.questions q where q.owner_type='platform' offset 5 limit 1;

\echo '--- hazirliq tamam'

-- =====================================================================
--  1. Adi muellim gore bilmir
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = 'bbbb0000-0000-0000-0000-0000000000a2';
do $$ begin
  begin
    perform public.rpc_admin_baza();
    raise exception 'SEHV: adi muellim bazanin hecmini gordu';
  exception when sqlstate '42501' then null;
  end;
end $$;
\echo 'OK  1 · adi muellim rpc_admin_baza-ni cagira bilmir'

-- =====================================================================
--  2. Admin gorur; acarlar yerindedir
-- =====================================================================
set request.jwt.claim.sub = 'bbbb0000-0000-0000-0000-0000000000a1';
do $$
declare v jsonb;
begin
  v := public.rpc_admin_baza();
  assert (v->>'db')::bigint > 0, 'baza hecmi sifirdir';
  assert (v->>'bank')::bigint > 0, 'bank hecmi sifirdir';
  assert v ? 'pullu' and v ? 'pulsuz' and v ? 'demo' and v ? 'qalan', 'acar catmir';
  assert (v->>'bank')::bigint < (v->>'db')::bigint, 'bank bazadan boyuk cixdi';
end $$;
\echo 'OK  2 · admin gorur, hecm ve bank musbetdir'

-- =====================================================================
--  3. Pullu / pulsuz bolgusu: saylar DEQIQDIR
-- =====================================================================
do $$
declare v jsonb;
begin
  v := public.rpc_admin_baza();
  assert (v->'pullu'->>'cavab')::int = 3,
         'pullu cavab sayi 3 deyil: ' || (v->'pullu'->>'cavab');
  assert (v->'pulsuz'->>'cavab')::int = 1,
         'pulsuz cavab sayi 1 deyil: ' || (v->'pulsuz'->>'cavab');
  assert (v->'pullu'->>'sagird')::int >= 1 and (v->'pulsuz'->>'sagird')::int >= 1,
         'sagird saylari bolunmedi';
end $$;
\echo 'OK  3 · pullu 3 cavab, pulsuz 1 cavab - bolgu duzdur'

-- =====================================================================
--  4. AZ DATA: bayt UYDURULMUR.  4 setirde total_size/say 24 KB verir
--     (bos sehifeler + 4 indeks) - real deyer 434 baytdir.  Ona gore
--     hedd altinda bolgu null qaytarilir, saylar ise qalir.
-- =====================================================================
do $$
declare v jsonb;
begin
  v := public.rpc_admin_baza();
  assert (v->>'olculur')::boolean = false, 'az datada olculur=true qaldi';
  assert v->'pullu'->>'bayt' is null, 'az datada bayt uydurulur';
  assert (v->'pullu'->>'cavab')::int = 3, 'say itdi';
  assert v->>'artim30' is null and v->>'gun500' is null, 'az datada artim yazilir';
end $$;
--  kicik cedvelde birbasa cagirsan da null gelir (app.* funksiyasi
--  authenticated-e baglidir, ona gore rol sifirlanir)
reset role; reset request.jwt.claim.sub;
do $$ begin
  assert app.baza_bpr('public.plans') is null, 'kicik cedvelde bpr uydurulur';
end $$;
set role authenticated;
set request.jwt.claim.sub = 'bbbb0000-0000-0000-0000-0000000000a1';
\echo 'OK  4 · az datada bayt uydurulmur, saylar qalir'

-- =====================================================================
--  5. Artim ve "500 MB-a ne qeder qalib" - hedd asilandan sonra
-- =====================================================================
reset role; reset request.jwt.claim.sub;
insert into public.attempt_answers (attempt_id, question_id, question_body, answered_at)
  select 'bbbf0000-0000-0000-0000-0000000000a2', q.id, q.body, now()
    from public.questions q where q.owner_type='platform' offset 100 limit 1200;
analyze public.attempt_answers;
set role authenticated;
set request.jwt.claim.sub = 'bbbb0000-0000-0000-0000-0000000000a1';
do $$
declare v jsonb;
begin
  v := public.rpc_admin_baza();
  assert (v->>'olculur')::boolean = true, 'hedd asildi, hele olculmur';
  assert (v->>'artim30')::bigint > 0, 'son 30 gunun artimi sifirdir';
  assert (v->>'gun500') is not null, 'gun500 hesablanmadi';
  --  ESAS OLCU: bir cavabin bayti ag-qara olmalidir.  Sintetik olcmede
  --  434 bayt cixmisdi; 200-1500 araligi genisdir, amma 24 KB kimi
  --  yalanci deyeri tutur.
  assert (v->>'bpr')::bigint between 200 and 1500,
         'bir cavabin bayti ag-qara deyil: ' || (v->>'bpr');
  assert (v->'pullu'->>'bayt')::bigint > (v->'pulsuz'->>'bayt')::bigint,
         'pullu hesab daha cox yazib, bayti da boyuk olmalidir';
end $$;
\echo 'OK  5 · hedd asilanda olculur: bir cavab 200-1500 bayt, bolgu duzdur'

-- =====================================================================
--  6. Demo hesab artima dusmur
-- =====================================================================
reset role; reset request.jwt.claim.sub;
update public.accounts set is_demo = true where id = 'bbba0000-0000-0000-0000-0000000000a3';
set role authenticated;
set request.jwt.claim.sub = 'bbbb0000-0000-0000-0000-0000000000a1';
do $$
declare v jsonb;
begin
  v := public.rpc_admin_baza();
  assert (v->'demo'->>'cavab')::int = 1, 'demo cavabi ayrilmadi';
  assert (v->'pulsuz'->>'cavab')::int = 0, 'demo hele pulsuzda sayilir';
  --  1203 cavab pullu hesabdadir, 1-i demoda.  Artim yalniz pullunu
  --  saymalidir.  Yuvarlaqlasmaya gore 1% dozum verilir.
  assert abs((v->>'artim30')::numeric - (v->>'bpr')::numeric * 1203)
         < (v->>'artim30')::numeric * 0.01,
         'artimda demo da sayildi: ' || (v->>'artim30');
end $$;
\echo 'OK  6 · numune hesab ayrica, artima dusmur'

reset role; reset request.jwt.claim.sub;
rollback;
\echo 'BAZA: BUTUN YOXLAMALAR KECDI'
