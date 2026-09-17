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

-- =====================================================================
--  8. (199) Admin -> muellim mesaji: admin yazir, muellim Icmalda gorur,
--     oxudu isaresi, cavab reply_to ile, admin siyahida cavabi taniyir;
--     adi muellim gondere bilmir; numune hesaba gonderilmir; adminin
--     mesaji «yeni» sayina ve muellimin «Yazdiqlariniz»a dusmur.
-- =====================================================================
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000d2';
do $$
begin
  begin
    perform public.rpc_admin_message('mlm@t.az', 'Adi muellim gondere bilmez.');
    raise exception 'adi muellim admin mesaji gonderdi';
  exception when insufficient_privilege then null; end;
  assert public.rpc_my_messages() = '[]'::jsonb, 'bos siyahi gozlenirdi';
end $$;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000d1';
do $$
declare v jsonb; n0 int;
begin
  n0 := public.rpc_admin_feedback_count();
  begin
    perform public.rpc_admin_message('mlm@t.az', 'qisa');
    raise exception 'qisa mesaj kecdi';
  exception when invalid_parameter_value then null; end;
  begin
    perform public.rpc_admin_message('yox@t.az', 'Bele hesab yoxdur, sehv olmalidir.');
    raise exception 'tapilmayan e-poct kecdi';
  exception when invalid_parameter_value then null; end;
  v := public.rpc_admin_message('MLM@t.az', 'Salam! Qrup qurmusunuz, sagirdleri men elave edim?');
  assert (v->>'id') is not null, 'mesaj id yox';
  assert public.rpc_admin_feedback_count() = n0, 'admin mesaji yeni sayina dusdu';
  assert jsonb_array_length(public.rpc_admin_feedback('new')) = n0, 'admin mesaji yeni siyahida';
  select x into v from jsonb_array_elements(public.rpc_admin_feedback('closed')) x
   where x->>'author_type' = 'admin';
  assert v->>'who' = 'Siz' and v->>'email' = 'mlm@t.az' and v->>'kind' = 'mesaj',
         'admin setri siyahida sehv: ' || v::text;
end $$;
--  numune hesaba gonderilmir
reset role; reset request.jwt.claim.sub;
update public.accounts set is_demo = true where id = 'aaaa0000-0000-0000-0000-0000000000d2';
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000d1';
do $$
begin
  begin
    perform public.rpc_admin_message('mlm@t.az', 'Numune hesaba getmemelidir.');
    raise exception 'numune hesaba mesaj getdi';
  exception when invalid_parameter_value then null; end;
end $$;
reset role; reset request.jwt.claim.sub;
update public.accounts set is_demo = false where id = 'aaaa0000-0000-0000-0000-0000000000d2';
set role authenticated;
--  muellim gorur, oxuyur, cavab yazir  (2-ci bolmede gunluk hedd dolub -
--  kohne yazilari dunene cekirik)
reset role; reset request.jwt.claim.sub;
update public.feedback set created_at = created_at - interval '2 days'
 where user_id = '11110000-0000-0000-0000-0000000000d2' and author_type = 'teacher';
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000d2';
do $$
declare m jsonb; mid uuid; r jsonb;
begin
  m := public.rpc_my_messages();
  assert jsonb_array_length(m) = 1, 'muellim mesaji gormur';
  assert (m->0->>'seen_at') is null and (m->0->>'replied') = 'false', 'ilk hal sehv';
  assert m->0->>'body' like 'Salam! Qrup%', 'metn sehv';
  mid := (m->0->>'id')::uuid;
  assert (public.rpc_message_seen(mid)->>'ok') = 'true', 'seen olmadi';
  assert (public.rpc_my_messages()->0->>'seen_at') is not null, 'seen_at yazilmadi';
  --  yad id - ok:false, sehv yox
  assert (public.rpc_message_seen(gen_random_uuid())->>'ok') = 'false', 'yad id ok verdi';
  begin
    perform public.rpc_feedback_send('sual', 'Yad mesaja cavab olmaz, yoxlanis.', 'Profil', gen_random_uuid());
    raise exception 'yad reply_to kecdi';
  exception when invalid_parameter_value then null; end;
  r := public.rpc_feedback_send('sual', 'Beli, siyahini gonderirem, sag olun!', 'Profil', mid);
  assert (r->>'id') is not null, 'cavab yazilmadi';
  assert (public.rpc_my_messages()->0->>'replied') = 'true', 'replied false qaldi';
  --  Yazdiqlarinizda cavab reply_to ile, admin mesaji yoxdur
  select x into r from jsonb_array_elements(public.rpc_feedback_mine()) x
   where x->>'reply_to' = mid::text;
  assert r is not null, 'cavab Yazdiqlarinizda yoxdur';
  assert not exists (select 1 from jsonb_array_elements(public.rpc_feedback_mine()) x
                      where x->>'kind' = 'mesaj'), 'admin mesaji Yazdiqlarinizda cixdi';
end $$;
--  admin cavabi taniyir
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000d1';
do $$
declare f jsonb;
begin
  select x into f from jsonb_array_elements(public.rpc_admin_feedback('new')) x
   where x->>'reply_to' is not null;
  assert f is not null, 'cavab admin siyahisinda yoxdur';
  assert f->>'reply_body' like 'Salam! Qrup%' and f->>'who' = 'Mlm Muellim', 'cavab konteksti sehv';
end $$;
\echo 'OK  8 · (199) admin -> muellim mesaji, oxudu, cavab, siyahi'

-- =====================================================================
--  9. (208) Cavab SAGIRDE ve VALIDEYNE catir; status ozu «seen»-e kecir
-- =====================================================================
reset role; reset request.jwt.claim.sub;
delete from public.feedback where body like 'smoke208%';
set role anon;
do $$
declare r jsonb; v_id uuid;
begin
  --  sagird yazir
  r := public.rpc_student_feedback('sag-token', 'teklif', 'smoke208 daha asan suallar olsun zehmet olmasa', 'testler');
  v_id := (r->>'id')::uuid;
  perform set_config('smoke.f208', v_id::text, false);
  --  cavabdan ONCE: siyahida var, note bosdur, fresh false
  --  siyahi en tezeden gelir; evvelki bolmelerden de yazi var
  r := public.rpc_student_feedback_mine('sag-token', false);
  assert r->0->>'body' like 'smoke208%', '208 sagird siyahisi sirasi: ' || r::text;
  assert r->0->>'note' is null and (r->0->>'fresh')::boolean = false, '208 cavabsiz fresh: ' || r::text;
  --  valideyn de yazir
  r := public.rpc_parent_feedback('val-token', 'sual', 'smoke208 valideyn sualidir yoxlanis ucun', 'valideyn');
  perform set_config('smoke.p208', (r->>'id'), false);
end $$;
reset role;

--  admin cavab yazir: status «new» idi, ozu «seen» olur
--  (cedvel yoxlamalari reset role altindadir - authenticated cedveli gormur)
do $$
declare v_id uuid := current_setting('smoke.f208')::uuid;
begin
  assert (select status from public.feedback where id = v_id) = 'new', '208 baslangic status';
end $$;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000d1';
do $$
declare r jsonb; v_id uuid := current_setting('smoke.f208')::uuid;
begin
  r := public.rpc_admin_feedback_set(v_id, 'new', 'Salam Ayse! Suallarin cetinliyini muellimin secir - ona catdirdiq.');
  assert r->>'status' = 'seen', '208 status ozu seen olmali: ' || r::text;
  --  valideyne de cavab
  perform public.rpc_admin_feedback_set(current_setting('smoke.p208')::uuid, 'new', 'Salam! Suala cavab budur.');
  --  status ELLE secilibse toxunulmur
  r := public.rpc_admin_feedback_set(v_id, 'planned', 'Ikinci cavab - status elle secilib.');
  assert r->>'status' = 'planned', '208 elle secilen status pozuldu: ' || r::text;
end $$;
reset role; reset request.jwt.claim.sub;
do $$
declare v_id uuid := current_setting('smoke.f208')::uuid;
begin
  assert (select status from public.feedback where id = v_id) = 'planned', '208 bazada status';
  assert (select answered_at from public.feedback where id = v_id) is not null, '208 answered_at';
  assert (select reply_seen_at from public.feedback where id = v_id) is null, '208 oxunmamis olmali';
end $$;

--  sagird cavabi gorur; p_seen=false oxunmus saymir, true saydirir
set role anon;
do $$
declare r jsonb;
begin
  r := public.rpc_student_feedback_mine('sag-token', false);
  assert r->0->>'note' like 'Ikinci cavab%', '208 sagird cavabi gormedi: ' || r::text;
  assert (r->0->>'fresh')::boolean, '208 fresh true olmali (hele acmayib)';
  --  qutu acildi: hemin cagirista da fresh false olmalidir (ele indi gorundu)
  r := public.rpc_student_feedback_mine('sag-token', true);
  assert (r->0->>'fresh')::boolean = false, '208 p_seen=true cagirisinda fresh false olmali: ' || r::text;
  r := public.rpc_student_feedback_mine('sag-token', false);
  assert (r->0->>'fresh')::boolean = false, '208 oxunandan sonra fresh false olmali';
  --  valideyn oz cavabini gorur, SAGIRD yazisini gormur
  r := public.rpc_parent_feedback_mine('val-token', true);
  assert r->0->>'body' like 'smoke208%' and r->0->>'note' like 'Salam! Suala%', '208 valideyn cavabi: ' || r::text;
  --  valideyn siyahisinda SAGIRD yazisi olmamalidir
  assert not exists (select 1 from jsonb_array_elements(r) x where x->>'body' like 'smoke208 daha asan%'),
    '208 valideyn sagird yazisini gordu: ' || r::text;
  --  yanlis token
  begin
    perform public.rpc_student_feedback_mine('yoxdur-token', false);
    raise exception '208 yanlis token kecdi';
  exception when sqlstate '28000' then null; end;
end $$;
reset role;

--  admin «oxudu» nisanini gorur
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000d1';
do $$
declare f jsonb; v_id uuid := current_setting('smoke.f208')::uuid;
begin
  select x into f from jsonb_array_elements(public.rpc_admin_feedback('all')) x
   where x->>'id' = v_id::text;
  assert f is not null, '208 setir admin siyahisinda yoxdur';
  assert f->>'reply_seen_at' is not null, '208 admin «oxudu» gormur: ' || f::text;
end $$;
reset role; reset request.jwt.claim.sub;
delete from public.feedback where body like 'smoke208%';
\echo 'OK  9 · (208) cavab sagirde/valideyne catir, status ozu seen, oxudu nisani'
