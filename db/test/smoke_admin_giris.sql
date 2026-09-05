-- =====================================================================
--  smoke_admin_giris.sql : admin girisleri gorur (db/125)
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.parent_sessions; delete from public.feedback;
delete from public.admin_totp; delete from public.admin_unlocks; delete from public.admin_code_attempts;
delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments;     delete from public.student_sessions;
delete from public.students;        delete from public.classes;
delete from public.subscriptions;
delete from public.account_members; delete from public.accounts;
delete from public.user_roles;      delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data, last_sign_in_at) values
  ('11110000-0000-0000-0000-0000000000b1','adm@t.az','{"full_name":"Admin"}', now()),
  ('11110000-0000-0000-0000-0000000000b2','yeni@t.az','{"full_name":"Yeni Muellim"}', now()),
  ('11110000-0000-0000-0000-0000000000b3','kohne@t.az','{"full_name":"Kohne Muellim"}', now() - interval '20 days');
insert into public.user_roles (user_id, role) values ('11110000-0000-0000-0000-0000000000b1','admin');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000b2','tutor','Yeni hesab', '11110000-0000-0000-0000-0000000000b2'),
  ('aaaa0000-0000-0000-0000-0000000000b3','tutor','Kohne hesab','11110000-0000-0000-0000-0000000000b3');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000b2','11110000-0000-0000-0000-0000000000b2',true),
  ('aaaa0000-0000-0000-0000-0000000000b3','11110000-0000-0000-0000-0000000000b3',true);
--  kohne hesab 20 gun evvel yaradilib (girmir suzgeci created_at-a da baxir)
update public.accounts set created_at = now() - interval '20 days'
 where id = 'aaaa0000-0000-0000-0000-0000000000b3';
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-0000000000b3','aaaa0000-0000-0000-0000-0000000000b3',
   '11110000-0000-0000-0000-0000000000b3','tutor_group','K qrup','KODKOH01');
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code) values
  ('5555000b-0000-0000-0000-0000000000b3','aaaa0000-0000-0000-0000-0000000000b3',
   'cccc0000-0000-0000-0000-0000000000b3','11110000-0000-0000-0000-0000000000b3',
   'Kohne Sagird','Kohne S.','KOHN0001');

\echo '--- hazirliq tamam'

-- =====================================================================
--  1. rpc_seen: yazir, 15 deqiqe icinde tekrar yazmir
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000b3';
do $$
declare t1 timestamptz; t2 timestamptz;
begin
  perform public.rpc_seen();
  select last_seen_at into t1 from public.profiles where id = '11110000-0000-0000-0000-0000000000b3';
  assert t1 is not null and t1 > now() - interval '1 minute', 'last_seen_at yazilmadi';
  update public.profiles set last_seen_at = now() - interval '5 minutes'
   where id = '11110000-0000-0000-0000-0000000000b3';
  perform public.rpc_seen();
  select last_seen_at into t2 from public.profiles where id = '11110000-0000-0000-0000-0000000000b3';
  assert t2 < now() - interval '4 minutes', '15 deqiqe kecmeden tekrar yazdi';
  update public.profiles set last_seen_at = now() - interval '10 days'
   where id = '11110000-0000-0000-0000-0000000000b3';
end $$;
\echo 'OK  1 · rpc_seen yazir, 15 deqiqede bir defe'

-- =====================================================================
--  2. Admin siyahisi: giris saheleri ve girmir suzgeci
-- =====================================================================
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000b1';
do $$
declare v jsonb; y jsonb; k jsonb;
begin
  v := public.rpc_admin_accounts(null, null);
  select x into y from jsonb_array_elements(v) x where x->>'name' = 'Yeni hesab';
  select x into k from jsonb_array_elements(v) x where x->>'name' = 'Kohne hesab';
  assert (y->>'last_login')::timestamptz > now() - interval '1 minute', 'yeni: last_login';
  assert y->'student_login' = 'null'::jsonb, 'yeni: sagird girisi olmamalidir';
  assert (k->>'last_login')::timestamptz < now() - interval '9 days', 'kohne: last_login (10 gun)';
  --  girmir suzgeci: yalniz kohne
  v := public.rpc_admin_accounts(null, 'girmir');
  assert jsonb_array_length(v) = 1 and v->0->>'name' = 'Kohne hesab', 'girmir suzgeci';
end $$;
\echo 'OK  2 · last_login, student_login, girmir suzgeci'

-- =====================================================================
--  3. Sagird kodla girir -> student_login dolur; stats.seen_week
-- =====================================================================
reset role; reset request.jwt.claim.sub;
do $$
begin
  set local role anon;
  perform public.rpc_student_login('KOHN0001');
  reset role;
end $$;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000b1';
do $$
declare v jsonb; k jsonb; st jsonb;
begin
  v := public.rpc_admin_accounts(null, null);
  select x into k from jsonb_array_elements(v) x where x->>'name' = 'Kohne hesab';
  assert (k->>'student_login')::timestamptz > now() - interval '1 minute', 'sagird girisi gorunmur';
  st := public.rpc_admin_stats();
  assert (st->>'seen_week')::int = 1, 'seen_week 1 olmalidir: ' || (st->>'seen_week');
end $$;
\echo 'OK  3 · sagird girisi gorunur, seen_week duzgundur'

-- =====================================================================
--  4. Adi muellim: rpc_seen olur, admin siyahisi yox
-- =====================================================================
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000b2';
do $$
declare ok boolean := false;
begin
  perform public.rpc_seen();
  begin
    perform public.rpc_admin_accounts(null, 'girmir');
  exception when insufficient_privilege then ok := true; end;
  assert ok, 'adi muellim siyahini gordu';
end $$;
\echo 'OK  4 · adi muellim: yalniz rpc_seen'
