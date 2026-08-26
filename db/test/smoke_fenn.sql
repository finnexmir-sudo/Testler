-- =====================================================================
--  smoke_fenn.sql : tedris fennleri - yazma, temizleme, huquq
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.class_plan_items; delete from public.class_plans;
delete from public.question_reports;
delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments;     delete from public.student_sessions;
delete from public.students;        delete from public.classes;
delete from public.subscriptions;
delete from public.account_members; delete from public.accounts;
delete from public.user_roles;      delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email) values
  ('11110000-0000-0000-0000-0000000000fe','fenn@t.az'),
  ('11110000-0000-0000-0000-0000000000ff','ozge@t.az');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000fe','tutor','Fenn hesabi',
   '11110000-0000-0000-0000-0000000000fe');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000fe','11110000-0000-0000-0000-0000000000fe',true);

\echo '--- hazirliq tamam'

-- =====================================================================
--  1. Fennler yazilir; seif slug sakitce atilir; kontekstde gorunur
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000fe';
do $$
declare v jsonb;
begin
  v := public.rpc_set_subjects('aaaa0000-0000-0000-0000-0000000000fe',
                               array['riyaziyyat', 'yalan-fenn', 'riyaziyyat']);
  assert v->'subjects' = '["riyaziyyat"]'::jsonb,
         format('fennler sehv yazildi: %s', v->'subjects');

  v := public.rpc_my_context();
  assert v->'accounts'->0->'subjects' = '["riyaziyyat"]'::jsonb,
         'kontekstde fennler yoxdur';
end $$;
\echo 'OK  1 · fennler yazilir, seif slug atilir, kontekstde gorunur'

-- =====================================================================
--  2. Bos siyahi = filtr silinir
-- =====================================================================
do $$
declare v jsonb;
begin
  v := public.rpc_set_subjects('aaaa0000-0000-0000-0000-0000000000fe',
                               '{}'::text[]);
  assert v->'subjects' = '[]'::jsonb, 'bos siyahi yazilmadi';
end $$;
\echo 'OK  2 · bos siyahi filtri sifirlayir'

-- =====================================================================
--  3. Ozge istifadeci hesabin fennlerini deyise bilmir
-- =====================================================================
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000ff';
do $$
declare ok1 boolean := false;
begin
  begin
    perform public.rpc_set_subjects('aaaa0000-0000-0000-0000-0000000000fe',
                                    array['riyaziyyat']);
  exception when insufficient_privilege then ok1 := true; end;
  assert ok1, 'ozge istifadeci fenn yazdi!';
end $$;
\echo 'OK  3 · ozge istifadeci fennleri deyise bilmir'

-- =====================================================================
--  4. anon gormur
-- =====================================================================
reset role; reset request.jwt.claim.sub;
do $$
begin
  assert not has_function_privilege('anon',
    'public.rpc_set_subjects(uuid, text[])', 'EXECUTE'),
    'anon fenn yaza bilir';
end $$;
\echo 'OK  4 · anon fenn funksiyasini gormur'
