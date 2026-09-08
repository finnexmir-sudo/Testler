-- =====================================================================
--  smoke_sessiya.sql : Sagird sessiyasinin omru (db/164)
--
--  Iddialar: giris 30 gunluk sessiya yaradir (12 saatliq yox) ·
--  valideynle eyni omurdur · kod yenilenende sessiya olur ·
--  dayandirilmis sagirdin tokeni islemir.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.attempt_answers;  delete from public.attempts;
delete from public.assignments;      delete from public.parent_sessions;
delete from public.student_sessions; delete from public.students;
delete from public.classes;          delete from public.subscriptions;
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email) values
  ('11110000-0000-0000-0000-0000000164a1','ses-a@t.az');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000164a1','tutor','Sessiya hesabi',
   '11110000-0000-0000-0000-0000000164a1');
insert into public.account_members (account_id, user_id, is_admin) values
  ('aaaa0000-0000-0000-0000-0000000164a1','11110000-0000-0000-0000-0000000164a1',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('ccc00000-0000-0000-0000-0000000164a1','aaaa0000-0000-0000-0000-0000000164a1',
   '11110000-0000-0000-0000-0000000164a1','tutor_group','Sessiya qrupu','KODSES01');
insert into public.students (id, account_id, class_id, created_by,
                             full_name, display_name, login_code, is_active) values
  ('5b100000-0000-0000-0000-0000000164a1','aaaa0000-0000-0000-0000-0000000164a1',
   'ccc00000-0000-0000-0000-0000000164a1','11110000-0000-0000-0000-0000000164a1',
   'Sessiya Sagird','Sessiya S.','SES00001',true),
  ('5b100000-0000-0000-0000-0000000164a2','aaaa0000-0000-0000-0000-0000000164a1',
   'ccc00000-0000-0000-0000-0000000164a1','11110000-0000-0000-0000-0000000164a1',
   'Dayandirilmis S','Dayan. S.','SES00002',false);

-- 1 · giris 30 gunluk sessiya verir (12 saat DEYIL)
do $$
declare d jsonb; v_exp timestamptz; v_saat numeric;
begin
  d := public.rpc_student_login('SES00001');
  if not (d->>'ok')::boolean then
    raise exception 'giris alinmadi: %', d->>'error';
  end if;
  select expires_at into v_exp from public.student_sessions
   where token_hash = app.hash_token(d->>'token');
  v_saat := extract(epoch from (v_exp - now())) / 3600;
  if v_saat < 29 * 24 or v_saat > 31 * 24 then
    raise exception 'sessiya omru 30 gun deyil: % saat', round(v_saat);
  end if;
end $$;
\echo 'OK  1 · giris 30 gunluk sessiya verir'

-- 2 · valideyn girisi ile EYNI omurdur (ikisi de oz RPC-sinden gelir)
update public.students set parent_code = 'VSES0001'
 where id = '5b100000-0000-0000-0000-0000000164a1';
do $$
declare s_exp timestamptz; p_exp timestamptz; t text;
begin
  delete from public.student_sessions;  delete from public.parent_sessions;
  t := public.rpc_student_login('SES00001')->>'token';
  select expires_at into s_exp from public.student_sessions
   where token_hash = app.hash_token(t);
  t := public.rpc_parent_login('VSES0001')->>'token';
  select expires_at into p_exp from public.parent_sessions
   where token_hash = app.hash_token(t);
  if p_exp is null then raise exception 'valideyn sessiyasi yaranmadi'; end if;
  if abs(extract(epoch from (s_exp - p_exp))) > 60 then
    raise exception 'sagird (%) ve valideyn (%) omru ferqlidir', s_exp, p_exp;
  end if;
end $$;
\echo 'OK  2 · valideyn girisi ile eyni omurdur'

-- 3 · dayandirilmis sagird gire bilmir; teze token kohnesini evez etmir
do $$
declare d jsonb; t text; n int;
begin
  d := public.rpc_student_login('SES00002');
  if (d->>'ok')::boolean then
    raise exception 'dayandirilmis sagird girdi';
  end if;
  delete from public.student_sessions;
  t := public.rpc_student_login('SES00001')->>'token';
  if app.session_student(t) is null then
    raise exception 'teze token islemir';
  end if;
  if app.session_student('yanlis-token') is not null then
    raise exception 'yanlis token isledi';
  end if;
  --  omru kecmis sessiya sayilmir
  update public.student_sessions set expires_at = now() - interval '1 minute';
  if app.session_student(t) is not null then
    raise exception 'vaxti kecmis sessiya hele isleyir';
  end if;
  select count(*) into n from public.student_sessions;
  if n <> 1 then raise exception 'gozlenilmeyen sessiya sayi: %', n; end if;
end $$;
\echo 'OK  3 · dayandirilmis gire bilmir, vaxti kecen token islemir'
