-- =====================================================================
--  smoke_davamiyyet.sql : davamiyyet ve odenis defteri (db/130)
--
--  Iddialar: ders + istirak yazilir, eyni gun tekrar yazanda yenilenir ·
--  yad sagird reddedilir · odenis toggle · defter ay uzre ·
--  valideyn oz usaginin istirakini ve odenisini gorur · yad muellim yox.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.fee_payments; delete from public.attendance; delete from public.lessons;
delete from public.parent_sessions; delete from public.mistakes;
delete from public.attempt_answers;  delete from public.attempts;
delete from public.assignments;      delete from public.student_sessions;
delete from public.students;         delete from public.classes;
delete from public.subscriptions;
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-0000000000a1','dv@t.az','{"full_name":"Davam Muellim"}'),
  ('11110000-0000-0000-0000-0000000000a2','yad@t.az','{"full_name":"Yad Muellim"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000a1','tutor','DV hesabi','11110000-0000-0000-0000-0000000000a1'),
  ('aaaa0000-0000-0000-0000-0000000000a2','tutor','Yad hesab','11110000-0000-0000-0000-0000000000a2');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000a1','11110000-0000-0000-0000-0000000000a1',true),
  ('aaaa0000-0000-0000-0000-0000000000a2','11110000-0000-0000-0000-0000000000a2',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-0000000000a1','aaaa0000-0000-0000-0000-0000000000a1',
   '11110000-0000-0000-0000-0000000000a1','tutor_group','DV qrup','KODDV001'),
  ('cccc0000-0000-0000-0000-0000000000a2','aaaa0000-0000-0000-0000-0000000000a2',
   '11110000-0000-0000-0000-0000000000a2','tutor_group','Yad qrup','KODDV002');
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code) values
  ('5555000a-0000-0000-0000-0000000000a1','aaaa0000-0000-0000-0000-0000000000a1',
   'cccc0000-0000-0000-0000-0000000000a1','11110000-0000-0000-0000-0000000000a1','Ayan Bir','Ayan B.','DVAM0001'),
  ('5555000a-0000-0000-0000-0000000000a2','aaaa0000-0000-0000-0000-0000000000a1',
   'cccc0000-0000-0000-0000-0000000000a1','11110000-0000-0000-0000-0000000000a1','Murad Iki','Murad I.','DVAM0002'),
  ('5555000a-0000-0000-0000-0000000000a3','aaaa0000-0000-0000-0000-0000000000a2',
   'cccc0000-0000-0000-0000-0000000000a2','11110000-0000-0000-0000-0000000000a2','Yad Uc','Yad U.','DVAM0003');
insert into public.parent_sessions (token_hash, student_id, expires_at) values
  (app.hash_token('val-ayan'),'5555000a-0000-0000-0000-0000000000a1', now() + interval '1 day');

\echo '--- hazirliq tamam'

-- =====================================================================
--  1. Ders + istirak; eyni gun tekrar yazanda yenilenir; yad sagird yox
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000a1';
do $$
declare r jsonb; ok boolean := false;
begin
  r := public.rpc_lesson_mark('cccc0000-0000-0000-0000-0000000000a1', current_date,
         array['5555000a-0000-0000-0000-0000000000a1'::uuid], array['5555000a-0000-0000-0000-0000000000a2'::uuid]);
  assert (r->>'present')::int = 1 and (r->>'absent')::int = 1, 'istirak yazilmadi';
  --  duzelis: Murad da gelib
  r := public.rpc_lesson_mark('cccc0000-0000-0000-0000-0000000000a1', current_date,
         array['5555000a-0000-0000-0000-0000000000a1'::uuid, '5555000a-0000-0000-0000-0000000000a2'::uuid], '{}');
  assert (r->>'present')::int = 2 and (r->>'absent')::int = 0, 'duzelis islemedi';
  begin
    perform public.rpc_lesson_mark('cccc0000-0000-0000-0000-0000000000a1', current_date,
              array['5555000a-0000-0000-0000-0000000000a3'::uuid], '{}');
  exception when others then ok := true; end;
  assert ok, 'yad sagird qebul olundu';
  --  ikinci ders: dunen, Ayan yox
  perform public.rpc_lesson_mark('cccc0000-0000-0000-0000-0000000000a1', current_date - 1,
            array['5555000a-0000-0000-0000-0000000000a2'::uuid], array['5555000a-0000-0000-0000-0000000000a1'::uuid]);
end $$;
\echo 'OK  1 · ders + istirak, duzelis, yad sagird yox'

-- =====================================================================
--  2. Odenis toggle; defter ay uzre
-- =====================================================================
do $$
declare v jsonb; a jsonb;
begin
  perform public.rpc_payment_set('5555000a-0000-0000-0000-0000000000a1', current_date, true, 8000, null);
  v := public.rpc_ledger_get('cccc0000-0000-0000-0000-0000000000a1', null);
  --  dunen ile bu gun eyni ayda olmaya biler (ayin 1-i) - ders sayi 1 ve ya 2
  assert jsonb_array_length(v->'lessons') between 1 and 2, 'dersler';
  assert v->'today'->>'id' is not null and jsonb_array_length(v->'today'->'present') = 2, 'bu gunun veraqi';
  select x into a from jsonb_array_elements(v->'students') x where x->>'name' = 'Ayan Bir';
  assert (a->>'paid')::boolean and (a->>'amount_minor')::int = 8000, 'Ayan odenilib';
  assert (a->>'present')::int >= 1, 'Ayan istirak';
  select x into a from jsonb_array_elements(v->'students') x where x->>'name' = 'Murad Iki';
  assert not (a->>'paid')::boolean and not (a->>'has_pay')::boolean, 'Murad odenis qeydi yox';
  perform public.rpc_payment_set('5555000a-0000-0000-0000-0000000000a1', current_date, false, null, null);
  v := public.rpc_ledger_get('cccc0000-0000-0000-0000-0000000000a1', null);
  select x into a from jsonb_array_elements(v->'students') x where x->>'name' = 'Ayan Bir';
  assert not (a->>'paid')::boolean and (a->>'amount_minor')::int = 8000, 'geri alanda mebleg qalir';
  --  kecen ay bos
  v := public.rpc_ledger_get('cccc0000-0000-0000-0000-0000000000a1', (current_date - interval '40 days')::date);
  assert jsonb_array_length(v->'lessons') = 0, 'kecen ay bos olmali';
end $$;
\echo 'OK  2 · odenis toggle, defter ay uzre'

-- =====================================================================
--  3. Yad muellim gormur / yaza bilmir
-- =====================================================================
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000a2';
do $$
declare ok1 boolean := false; ok2 boolean := false;
begin
  begin
    perform public.rpc_ledger_get('cccc0000-0000-0000-0000-0000000000a1', null);
  exception when insufficient_privilege then ok1 := true; end;
  begin
    perform public.rpc_payment_set('5555000a-0000-0000-0000-0000000000a1', current_date, true, null, null);
  exception when insufficient_privilege then ok2 := true; end;
  assert ok1 and ok2, 'yad muellim kecdi';
end $$;
\echo 'OK  3 · yad muellim gormur'

-- =====================================================================
--  4. Valideyn: bu ayin istiraki ve odenisi
-- =====================================================================
reset role; reset request.jwt.claim.sub;
update public.fee_payments set paid = true, paid_at = now() where student_id = '5555000a-0000-0000-0000-0000000000a1';
do $$
declare v jsonb;
begin
  set local role anon;
  v := public.rpc_parent_home('val-ayan');
  reset role;
  assert (v->'attendance'->>'lessons')::int >= 1, 'valideyn: ders sayi';
  assert (v->'attendance'->>'attended')::int >= 1, 'valideyn: istirak';
  assert (v->'attendance'->>'paid')::boolean, 'valideyn: odenis';
end $$;
\echo 'OK  4 · valideyn istirak ve odenisi gorur'
