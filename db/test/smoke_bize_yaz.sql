-- =====================================================================
--  smoke_bize_yaz.sql : «Bize yaz» (db/122_bize_yaz.sql)
--
--  Iddialar: muellim yazir ve oz siyahisini gorur · qisa/uzun metn ve
--  yanlis nov reddedilir · gunluk hedd · sagird ve valideyn token ile
--  yazir, bitmis token yox · adi muellim admin siyahisini gormur ·
--  admin siyahi/say/status+qeyd · muellim adminin qeydini gorur ·
--  cedvele birbasa giris yoxdur (RLS deny).
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.feedback;
delete from public.parent_sessions;  delete from public.question_reports;
delete from public.admin_totp; delete from public.admin_unlocks;
delete from public.admin_code_attempts;
delete from public.attempt_answers;  delete from public.attempts;
delete from public.assignments;      delete from public.student_sessions;
delete from public.students;         delete from public.classes;
delete from public.subscriptions;
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-0000000000d1','adm@t.az','{"full_name":"Admin"}'),
  ('11110000-0000-0000-0000-0000000000d2','mlm@t.az','{"full_name":"Mlm Muellim"}');
insert into public.user_roles (user_id, role) values
  ('11110000-0000-0000-0000-0000000000d1','admin');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000d2','tutor','Muellim hesabi',
   '11110000-0000-0000-0000-0000000000d2');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000d2','11110000-0000-0000-0000-0000000000d2',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-0000000000d1','aaaa0000-0000-0000-0000-0000000000d2',
   '11110000-0000-0000-0000-0000000000d2','tutor_group','Qrup A','KODBIL01');
insert into public.students (id, account_id, class_id, created_by, full_name,
                             display_name, login_code) values
  ('5555000d-0000-0000-0000-000000000001','aaaa0000-0000-0000-0000-0000000000d2',
   'cccc0000-0000-0000-0000-0000000000d1','11110000-0000-0000-0000-0000000000d2',
   'Sagird Bir','Sagird Bir','KODSAG01');
insert into public.student_sessions (token_hash, student_id, expires_at) values
  (app.hash_token('sag-token'),'5555000d-0000-0000-0000-000000000001',
   now() + interval '1 day'),
  (app.hash_token('sag-kohne'),'5555000d-0000-0000-0000-000000000001',
   now() - interval '1 minute');
insert into public.parent_sessions (token_hash, student_id, expires_at) values
  (app.hash_token('val-token'),'5555000d-0000-0000-0000-000000000001',
   now() + interval '1 day');

\echo '--- hazirliq tamam'

-- =====================================================================
--  1. Muellim yazir; qisa/uzun/yanlis nov reddedilir; oz siyahisi
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000d2';
do $$
declare r jsonb; m jsonb; ok1 boolean := false; ok2 boolean := false; ok3 boolean := false;
begin
  r := public.rpc_feedback_send('teklif', 'Testin sonunda duz cavablar acilsin.', 'profil');
  assert (r->>'id') is not null, 'id qayitmadi';
  begin
    perform public.rpc_feedback_send('teklif', 'qisa', null);
  exception when others then ok1 := true; end;
  begin
    perform public.rpc_feedback_send('teklif', repeat('a', 2001), null);
  exception when others then ok2 := true; end;
  begin
    perform public.rpc_feedback_send('spam', 'Bu bir yoxlama mesajidir.', null);
  exception when others then ok3 := true; end;
  assert ok1 and ok2 and ok3, 'qisa/uzun/yanlis nov kecdi';
  m := public.rpc_feedback_mine();
  assert jsonb_array_length(m) = 1, 'oz siyahisi sehvdir';
  assert m->0->>'status' = 'new' and m->0->>'kind' = 'teklif', 'status/nov sehvdir';
  assert m->0->>'page' = 'profil', 'sehife yazilmadi';
end $$;
\echo 'OK  1 · muellim yazir: yoxlanisli, oz siyahisi'

-- =====================================================================
--  2. Gunluk hedd: 10-dan sonra dayanir
-- =====================================================================
do $$
declare i int; ok boolean := false;
begin
  for i in 1..9 loop
    perform public.rpc_feedback_send('sual', 'Mesaj nomre ' || i || ' - yoxlama.', null);
  end loop;
  begin
    perform public.rpc_feedback_send('sual', 'On birinci mesaj kecmemelidir.', null);
  exception when others then ok := true; end;
  assert ok, 'gunluk hedd islemedi';
end $$;
reset role; reset request.jwt.claim.sub;
do $$
begin
  assert (select count(*) from public.feedback where author_type = 'teacher') = 10,
         'muellim mesaj sayi sehvdir';
end $$;
\echo 'OK  2 · gunluk hedd: 10 mesaj'

-- =====================================================================
--  3. Sagird ve valideyn token ile yazir; bitmis token yox
-- =====================================================================
do $$
declare ok boolean := false;
begin
  set local role anon;
  perform public.rpc_student_feedback('sag-token', 'problem', 'Sekil acilmir, telefondan baxiram.', 'test');
  perform public.rpc_parent_feedback('val-token', 'tesekkur', 'Hesabat cox aydin gelir, sag olun.', 'ev');
  begin
    perform public.rpc_student_feedback('sag-kohne', 'sual', 'Bitmis tokenle yazmaq olmaz.', null);
  exception when others then ok := true; end;
  assert ok, 'bitmis token kecdi';
  reset role;
  assert (select count(*) from public.feedback where author_type = 'student'
           and student_id = '5555000d-0000-0000-0000-000000000001'
           and account_id = 'aaaa0000-0000-0000-0000-0000000000d2') = 1,
         'sagird mesaji yazilmadi';
  assert (select count(*) from public.feedback where author_type = 'parent') = 1,
         'valideyn mesaji yazilmadi';
end $$;
\echo 'OK  3 · sagird/valideyn token ile; bitmis token yox'

-- =====================================================================
--  4. Adi muellim admin siyahisini gormur; say 0
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000d2';
do $$
declare ok boolean := false;
begin
  begin
    perform public.rpc_admin_feedback('new');
  exception when insufficient_privilege then ok := true; end;
  assert ok, 'adi muellim siyahini gordu!';
  assert public.rpc_admin_feedback_count() = 0, 'adi muellime say gorundu';
  begin
    ok := false;
    perform public.rpc_admin_feedback_set((select id from public.feedback limit 1), 'done', 'x');
  exception when insufficient_privilege then ok := true; end;
  assert ok, 'adi muellim status deyisdi!';
end $$;
\echo 'OK  4 · adi muellim: siyahi yox, say 0, status yox'

-- =====================================================================
--  5. Admin: siyahi, kimlik, say, status + qeyd
-- =====================================================================
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000d1';
do $$
declare v jsonb; f jsonb; fid uuid;
begin
  assert public.rpc_admin_feedback_count() = 12, 'yeni say sehvdir';
  v := public.rpc_admin_feedback('new');
  assert jsonb_array_length(v) = 12, 'siyahi sehvdir';
  select x into f from jsonb_array_elements(v) x where x->>'author_type' = 'student';
  assert f->>'who' = 'Sagird Bir' and f->>'class' = 'Qrup A', 'sagird kimliyi sehvdir';
  select x into f from jsonb_array_elements(v) x where x->>'author_type' = 'parent';
  assert f->>'who' = 'Valideyn · Sagird Bir', 'valideyn kimliyi sehvdir';
  select x into f from jsonb_array_elements(v) x where x->>'kind' = 'teklif';
  assert f->>'email' = 'mlm@t.az' and f->>'account' = 'Muellim hesabi'
     and f->>'who' = 'Mlm Muellim', 'muellim kimliyi sehvdir';
  fid := (f->>'id')::uuid;
  perform public.rpc_admin_feedback_set(fid, 'planned', 'Novbeti buraxilisda olacaq.');
  assert public.rpc_admin_feedback_count() = 11, 'status sonrasi say sehvdir';
  assert jsonb_array_length(public.rpc_admin_feedback('planned')) = 1, 'planned suzgeci';
  assert jsonb_array_length(public.rpc_admin_feedback('all')) = 12, 'all suzgeci';
  --  qeyd null gelende evvelki qalir
  perform public.rpc_admin_feedback_set(fid, 'done', null);
  select x into f from jsonb_array_elements(public.rpc_admin_feedback('done')) x;
  assert f->>'note' = 'Novbeti buraxilisda olacaq.', 'qeyd itdi';
end $$;
reset role; reset request.jwt.claim.sub;
do $$
begin
  assert (select count(*) from public.feedback where status = 'done'
           and answered_at is not null) = 1, 'cavab vaxti yox';
end $$;
set role authenticated;
\echo 'OK  5 · admin: siyahi, kimlik, say, status + qeyd'

-- =====================================================================
--  6. Muellim adminin cavabini gorur (dovre baglanir)
-- =====================================================================
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000d2';
do $$
declare m jsonb; f jsonb;
begin
  m := public.rpc_feedback_mine();
  select x into f from jsonb_array_elements(m) x where x->>'kind' = 'teklif';
  assert f->>'status' = 'done' and f->>'note' = 'Novbeti buraxilisda olacaq.',
         'muellim cavabi gormur';
end $$;
\echo 'OK  6 · muellim adminin cavabini gorur'

-- =====================================================================
--  7. Cedvele birbasa giris yoxdur
-- =====================================================================
do $$
declare ok boolean := false;
begin
  begin
    perform count(*) from public.feedback;
  exception when insufficient_privilege then ok := true; end;
  assert ok, 'authenticated cedveli oxudu!';
end $$;
reset role; reset request.jwt.claim.sub;
do $$
declare ok boolean := false;
begin
  set local role anon;
  begin
    perform count(*) from public.feedback;
  exception when insufficient_privilege then ok := true; end;
  reset role;
  assert ok, 'anon cedveli oxudu!';
end $$;
\echo 'OK  7 · cedvele birbasa giris yoxdur'
