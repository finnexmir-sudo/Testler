-- =====================================================================
--  smoke_reports.sql : hesabatlar ve odenis heddi
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.attempt_answers; delete from public.attempts;
delete from public.student_sessions; delete from public.students;
delete from public.classes; delete from public.subscriptions;
delete from public.account_members; delete from public.accounts;
delete from public.user_roles; delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-000000000001','a@t.az','{"full_name":"Muellim A"}'),
  ('22220000-0000-0000-0000-000000000002','b@t.az','{"full_name":"Muellim B"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-000000000001','tutor','A hesabi','11110000-0000-0000-0000-000000000001'),
  ('aaaa0000-0000-0000-0000-000000000002','tutor','B hesabi','22220000-0000-0000-0000-000000000002');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-000000000001','11110000-0000-0000-0000-000000000001',true),
  ('aaaa0000-0000-0000-0000-000000000002','22220000-0000-0000-0000-000000000002',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-000000000001','aaaa0000-0000-0000-0000-000000000001',
   '11110000-0000-0000-0000-000000000001','tutor_group','3-B','KOD3B111');
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code) values
  ('5555000a-0000-0000-0000-000000000001','aaaa0000-0000-0000-0000-000000000001',
   'cccc0000-0000-0000-0000-000000000001','11110000-0000-0000-0000-000000000001',
   'Aysu Memmedova','Aysu M.','AYSU1111'),
  ('5555000a-0000-0000-0000-000000000002','aaaa0000-0000-0000-0000-000000000001',
   'cccc0000-0000-0000-0000-000000000001','11110000-0000-0000-0000-000000000001',
   'Kenan Aliyev','Kenan A.','KENA2222');

-- Aysu: vurma cedveli testini isleyir (4 duz, 2 sehv)
do $$
declare tok text; att uuid; ans jsonb := '[]'::jsonb; r record; k int := 0; oid uuid;
begin
  tok := public.rpc_student_login('AYSU1111')->>'token';
  att := (public.rpc_start_attempt(tok,
           (select id from public.tests where slug='riy-3-vurma-1'))->>'attempt_id')::uuid;
  for r in select q.id from public.questions q
             join public.test_questions tq on tq.question_id=q.id
             join public.tests t on t.id=tq.test_id and t.slug='riy-3-vurma-1'
            order by tq.ord loop
    k := k + 1;
    -- ilk 4 sual duzgun, qalani sehv
    select o.id into oid from public.question_options o
     where o.question_id = r.id and o.is_correct = (k <= 4) limit 1;
    ans := ans || jsonb_build_array(jsonb_build_object('q', r.id, 'o', jsonb_build_array(oid)));
  end loop;
  perform public.rpc_submit_attempt(tok, att, ans);
end $$;

-- Kenan: hamisi duzgun
do $$
declare tok text; att uuid; ans jsonb := '[]'::jsonb; r record; oid uuid;
begin
  tok := public.rpc_student_login('KENA2222')->>'token';
  att := (public.rpc_start_attempt(tok,
           (select id from public.tests where slug='riy-3-vurma-1'))->>'attempt_id')::uuid;
  for r in select q.id from public.questions q
             join public.test_questions tq on tq.question_id=q.id
             join public.tests t on t.id=tq.test_id and t.slug='riy-3-vurma-1' loop
    select o.id into oid from public.question_options o
     where o.question_id = r.id and o.is_correct limit 1;
    ans := ans || jsonb_build_array(jsonb_build_object('q', r.id, 'o', jsonb_build_array(oid)));
  end loop;
  perform public.rpc_submit_attempt(tok, att, ans);
end $$;

\echo '--- hazirliq tamam'

set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-000000000001';

-- =====================================================================
--  1. PULSUZ hesab: xulase var, movzu analizi YOXDUR
-- =====================================================================
do $$
declare v jsonb; s jsonb;
begin
  v := public.rpc_class_report('cccc0000-0000-0000-0000-000000000001');
  assert (v->>'paid')::boolean = false, 'paid bayragi sehv';
  assert v->'topics' = 'null'::jsonb, 'PULSUZ hesabda movzu analizi qaytarildi!';
  assert v->>'since' is not null, 'pulsuz hedd tarixi gostrilmir';

  s := v->'summary';
  assert (s->>'students')::int = 2, format('sagird sayi: %s', s->>'students');
  assert (s->>'attempts')::int = 2, format('cehd sayi: %s', s->>'attempts');
  assert (s->>'active')::int   = 2, 'aktiv sagird sayi sehv';
  -- Aysu 4/6 = 66.7, Kenan 6/6 = 100  ->  orta 83.35
  assert (s->>'avg')::numeric between 83 and 84, format('orta faiz: %s', s->>'avg');
end $$;
\echo 'OK  1 · pulsuz: xulase var, movzu analizi qaytarilmir'

-- =====================================================================
--  2. Sagird uzre setirler duzgundur
-- =====================================================================
do $$
declare v jsonb; a jsonb; k jsonb;
begin
  v := public.rpc_class_report('cccc0000-0000-0000-0000-000000000001');
  assert jsonb_array_length(v->'students') = 2, 'sagird setri sayi sehv';
  select x into a from jsonb_array_elements(v->'students') x where x->>'display_name'='Aysu M.';
  select x into k from jsonb_array_elements(v->'students') x where x->>'display_name'='Kenan A.';
  assert (a->>'attempts')::int = 1, 'Aysu cehd sayi';
  assert (a->>'avg')::numeric between 66 and 67, format('Aysu orta: %s', a->>'avg');
  assert (k->>'avg')::numeric = 100, format('Kenan orta: %s', k->>'avg');
  assert a->>'last_at' is not null, 'son fealiyyet tarixi yoxdur';
  assert jsonb_array_length(v->'recent') = 2, 'son fealiyyet siyahisi sehv';
end $$;
\echo 'OK  2 · sagird uzre orta, cehd sayi ve son fealiyyet duzgun'

-- =====================================================================
--  3. ODENISLI hesab: movzu analizi acilir
-- =====================================================================
reset role;
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-000000000001', id, 'active', now() + interval '30 days'
  from public.plans where slug = 'repetitor-25';
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-000000000001';

do $$
declare v jsonb; t jsonb;
begin
  v := public.rpc_class_report('cccc0000-0000-0000-0000-000000000001');
  assert (v->>'paid')::boolean = true, 'paid bayragi acilmadi';
  assert v->'topics' <> 'null'::jsonb, 'odenisli hesabda movzu analizi yoxdur!';
  assert jsonb_array_length(v->'topics') >= 1, 'movzu siyahisi bos';
  t := v->'topics'->0;
  assert t->>'name' is not null and t->>'ratio' is not null, 'movzu setri natamam';
  -- 12 cavab, 10 duz (Aysu 4 + Kenan 6) -> 83.3%
  assert (t->>'total')::int = 12, format('movzu cavab sayi: %s', t->>'total');
  assert (t->>'correct')::int = 10, format('duz cavab: %s', t->>'correct');
  assert v->>'since' is null, 'odenisli hesabda tarix heddi qalib';
end $$;
\echo 'OK  3 · odenisli: movzu analizi acilir, reqemler duzgun'

-- =====================================================================
--  4. Sagird hesabati
-- =====================================================================
do $$
declare v jsonb;
begin
  v := public.rpc_student_report('5555000a-0000-0000-0000-000000000001');
  assert v->'student'->>'full_name' = 'Aysu Memmedova', 'sagird adi sehv';
  assert v->'student'->>'login_code' is not null, 'giris kodu yoxdur';
  assert (v->'summary'->>'attempts')::int = 1, 'cehd sayi';
  assert (v->'summary'->>'avg')::numeric between 66 and 67, 'orta faiz';
  assert jsonb_array_length(v->'attempts') = 1, 'cehd tarixcesi';
  assert v->'attempts'->0->>'test' is not null, 'test adi yoxdur';
  assert v->'topics' <> 'null'::jsonb, 'odenisli hesabda movzu yoxdur';
  assert v->'weak' <> 'null'::jsonb, 'zeif suallar siyahisi yoxdur';
  assert jsonb_array_length(v->'weak') = 2, format('sehv sual sayi: %s',
         jsonb_array_length(v->'weak'));
  assert v->'weak'->0->>'explanation' is not null, 'izah yoxdur';
end $$;
\echo 'OK  4 · sagird hesabati: tarixce, movzu, zeif suallar'

-- =====================================================================
--  5. Abune bitende movzu analizi yeniden baglanir
-- =====================================================================
reset role;
update public.subscriptions set current_period_end = now() - interval '1 day'
 where account_id = 'aaaa0000-0000-0000-0000-000000000001';
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-000000000001';

do $$
declare v jsonb;
begin
  v := public.rpc_class_report('cccc0000-0000-0000-0000-000000000001');
  assert (v->>'paid')::boolean = false, 'bitmis abune hele de aktiv sayilir!';
  assert v->'topics' = 'null'::jsonb, 'bitmis abunede movzu analizi acilib!';
  v := public.rpc_student_report('5555000a-0000-0000-0000-000000000001');
  assert v->'topics' = 'null'::jsonb, 'sagird hesabatinda movzu acilib!';
  assert v->'weak' = 'null'::jsonb, 'zeif suallar acilib!';
end $$;
\echo 'OK  5 · abune bitende odenisli hisseler baglanir'

-- =====================================================================
--  6. Ozge muellim bu qrupun hesabatini gore bilmir
-- =====================================================================
set request.jwt.claim.sub = '22220000-0000-0000-0000-000000000002';
do $$
declare ok1 boolean := false; ok2 boolean := false;
begin
  begin
    perform public.rpc_class_report('cccc0000-0000-0000-0000-000000000001');
    assert false, 'Ozge muellim sinif hesabatini gordu!';
  exception when insufficient_privilege then ok1 := true;
  end;
  begin
    perform public.rpc_student_report('5555000a-0000-0000-0000-000000000001');
    assert false, 'Ozge muellim sagird hesabatini gordu!';
  exception when insufficient_privilege then ok2 := true;
  end;
  assert ok1 and ok2, 'Icaze xetasi gelmedi';
end $$;
\echo 'OK  6 · ozge muellim hesabata cata bilmir'

-- =====================================================================
--  7. anon hesabata cata bilmir
-- =====================================================================
set role anon;
reset request.jwt.claim.sub;
do $$
declare ok boolean := false;
begin
  begin
    perform public.rpc_class_report('cccc0000-0000-0000-0000-000000000001');
    assert false, 'ANON hesabati gordu!';
  exception when insufficient_privilege or invalid_authorization_specification then ok := true;
  end;
  assert ok, 'anon ucun icaze xetasi gelmedi';
end $$;
\echo 'OK  7 · anon hesabata cata bilmir'

reset role;
\echo ''
\echo '=============================='
\echo ' HESABATLAR: HAMISI KECDI'
\echo '=============================='
