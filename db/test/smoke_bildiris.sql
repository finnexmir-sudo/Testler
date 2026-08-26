-- =====================================================================
--  smoke_bildiris.sql : sual sehvi bildirisleri ve admin 2FA
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.question_reports;
delete from public.admin_totp; delete from public.admin_unlocks;
delete from public.admin_code_attempts;
delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments;     delete from public.student_sessions;
delete from public.students;        delete from public.classes;
delete from public.subscriptions;
delete from public.question_options o using public.questions q
 where q.id = o.question_id and q.owner_type = 'educator';
delete from public.questions where owner_type = 'educator';
delete from public.account_members; delete from public.accounts;
delete from public.user_roles;      delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email) values
  ('11110000-0000-0000-0000-0000000000d1','adm@t.az'),
  ('11110000-0000-0000-0000-0000000000d2','mlm@t.az');
insert into public.user_roles (user_id, role) values
  ('11110000-0000-0000-0000-0000000000d1','admin');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000d2','tutor','Muellim',
   '11110000-0000-0000-0000-0000000000d2');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000d2','11110000-0000-0000-0000-0000000000d2',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-0000000000d1','aaaa0000-0000-0000-0000-0000000000d2',
   '11110000-0000-0000-0000-0000000000d2','tutor_group','Qrup','KODBIL01');
insert into public.students (id, account_id, class_id, created_by, full_name,
                             display_name, login_code) values
  ('5555000d-0000-0000-0000-000000000001','aaaa0000-0000-0000-0000-0000000000d2',
   'cccc0000-0000-0000-0000-0000000000d1','11110000-0000-0000-0000-0000000000d2',
   'Sagird Bir','Sagird Bir','KODSAG01');
insert into public.student_sessions (token_hash, student_id, expires_at) values
  (app.hash_token('bil-token'),'5555000d-0000-0000-0000-000000000001',
   now() + interval '1 day');

--  sagirdin gorduyu platforma suali (cehd + cavab sureti)
insert into public.attempts (id, student_id, test_id, class_id, status,
                             started_at, finished_at)
select '77770000-0000-0000-0000-0000000000d1',
       '5555000d-0000-0000-0000-000000000001', t.id,
       'cccc0000-0000-0000-0000-0000000000d1','submitted', now(), now()
  from public.tests t where t.owner_type = 'platform' limit 1;
insert into public.attempt_answers (attempt_id, question_id, is_correct,
                                    question_body)
select '77770000-0000-0000-0000-0000000000d1', q.id, false, q.body
  from public.questions q
 where q.owner_type = 'platform' and q.status = 'published'
 order by q.created_at limit 1;

\echo '--- hazirliq tamam'

-- =====================================================================
--  1. Muellim bildirir: tekrar udulur, yanlis sebeb/sual reddedilir
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000d2';
do $$
declare q uuid; ok1 boolean := false; ok2 boolean := false;
begin
  select id into q from public.questions
   where owner_type = 'platform' and status = 'published' limit 1;
  perform public.rpc_report_question(q, 'cavab', 'Cavab B olmalidir');
  perform public.rpc_report_question(q, 'yazi', 'tekrar');
  begin
    perform public.rpc_report_question(q, 'xxx', '');
  exception when others then ok1 := true; end;
  begin
    perform public.rpc_report_question(gen_random_uuid(), 'cavab', '');
  exception when others then ok2 := true; end;
  assert ok1 and ok2, 'yanlis sebeb/sual kecdi';
end $$;
reset role; reset request.jwt.claim.sub;
do $$
begin
  assert (select count(*) from public.question_reports) = 1,
         'tekrar bildiris udulmadi';
end $$;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000d2';
\echo 'OK  1 · muellim bildirisi: tekrarsiz, yoxlanisli'

-- =====================================================================
--  2. Sagird bildirir: yalniz oz gorduyu suali
-- =====================================================================
reset role; reset request.jwt.claim.sub;
do $$
declare q uuid; q2 uuid; ok1 boolean := false;
begin
  select question_id into q from public.attempt_answers limit 1;
  select id into q2 from public.questions where owner_type = 'platform'
   order by created_at desc limit 1;
  --  sagird axini anon acari ile gedir
  set local role anon;
  perform public.rpc_report_question_student('bil-token', q, 'sert', 'Qeyd');
  begin
    perform public.rpc_report_question_student('bil-token', q2, 'sert', '');
  exception when others then ok1 := true; end;
  assert ok1, 'sagird gormediyi suali bildirdi!';
  reset role;
  assert (select count(*) from public.question_reports
           where student_id is not null) = 1, 'sagird bildirisi yazilmadi';
end $$;
\echo 'OK  2 · sagird yalniz oz gorduyu suali bildirir'

-- =====================================================================
--  3. Admin siyahisi: qruplanmis, sayli; adi muellim gore bilmir
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000d2';
do $$
declare ok boolean := false;
begin
  begin
    perform public.rpc_admin_reports('new');
  exception when insufficient_privilege then ok := true; end;
  assert ok, 'adi muellim bildirisleri gordu!';
end $$;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000d1';
do $$
declare v jsonb;
begin
  v := public.rpc_admin_reports('new');
  assert jsonb_array_length(v) = 1, 'qruplasma sehvdir';
  assert (v->0->>'n')::int = 2, 'bildiris sayi sehvdir';
  assert jsonb_array_length(v->0->'options') = 4, 'variantlar gelmir';
  assert public.rpc_admin_reports_count() = 1, 'sayğac sehvdir';
end $$;
\echo 'OK  3 · admin siyahisi: 1 sual, 2 bildiris, variantlar'

-- =====================================================================
--  4. Yerinde duzelis: id-ler qorunur, bildirisler avtomatik baglanir
-- =====================================================================
reset role;
do $$
declare
  q uuid; opts jsonb; bad jsonb; ok1 boolean := false; ok2 boolean := false;
begin
  select question_id into q from public.question_reports limit 1;
  select jsonb_agg(jsonb_build_object('id', id, 'body', body || ' (duz)',
                                      'is_correct', is_correct)
                   order by ord)
    into opts from public.question_options where question_id = q;
  set local role authenticated;
  set local request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000d1';

  --  iki duz cavab - imtina
  bad := (select jsonb_agg(jsonb_set(o, '{is_correct}', 'true'))
            from jsonb_array_elements(opts) o);
  begin
    perform public.rpc_admin_fix_question(q, 'Yeni metn burda', 'izah', bad);
  exception when others then ok1 := true; end;
  --  ozge variant id-si - imtina
  bad := jsonb_set(opts, '{0,id}', to_jsonb(gen_random_uuid()::text));
  begin
    perform public.rpc_admin_fix_question(q, 'Yeni metn burda', 'izah', bad);
  exception when others then ok2 := true; end;
  assert ok1 and ok2, 'yanlis variant paketi kecdi';

  perform public.rpc_admin_fix_question(q, 'Duzelmis sual metni', 'Yeni izah', opts);
  assert public.rpc_admin_reports_count() = 0, 'sayğac sifirlanmadi';
  reset role; reset request.jwt.claim.sub;
  assert (select body from public.questions where id = q) = 'Duzelmis sual metni',
         'sual metni yenilenmedi';
  assert (select count(*) from public.question_options
           where question_id = q and body like '%(duz)') = 4,
         'variantlar yenilenmedi';
  assert not exists (select 1 from public.question_reports
                      where question_id = q and status = 'new'),
         'duzelisden sonra bildiris aciq qaldi';
end $$;
\echo 'OK  4 · yerinde duzelis + bildirisler avtomatik baglandi'

-- =====================================================================
--  5. 2FA: qurulus, tesdiq, kilid, cehd heddi
-- =====================================================================
--  Qeyd: cedvel oxunuslari (admin_totp.secret) superuser kontekstinde
--  gedir, RPC-ler ise admin rolunda - real Supabase axini ile eynidir.
do $$
declare
  v jsonb; sec bytea; code text; bkp text; okbad boolean := false;
begin
  set local role authenticated;
  set local request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000d1';
  --  hele qurulmayib - panel acilir
  assert app.admin_ok(), '2FA-siz admin baglandi';
  v := public.rpc_admin_2fa_status();
  assert not (v->>'enabled')::boolean, 'enabled sehvdir';

  v := public.rpc_admin_2fa_setup();
  assert length(v->>'secret') = 32, 'secret uzunlugu sehvdir';
  assert (v->>'uri') like 'otpauth://totp/%', 'uri sehvdir';
  assert jsonb_array_length(v->'backup') = 4, 'ehtiyat kodlar gelmir';
  bkp := v->'backup'->>0;

  --  yanlis kod: exception YOX, ok:false - cehd qeydi qalsin deye
  assert not (public.rpc_admin_2fa_confirm('000000')->>'ok')::boolean,
         'yanlis kod kecdi!';

  --  gizli acari birbasa cedvelden goturmek ucun superuser konteksti
  reset role;
  select secret into sec from public.admin_totp
   where user_id = '11110000-0000-0000-0000-0000000000d1';
  set local role authenticated;
  code := app.totp_at(sec, now());
  perform public.rpc_admin_2fa_confirm(code);
  assert (public.rpc_admin_2fa_status()->>'enabled')::boolean, 'aktivlesmedi';
  assert app.admin_ok(), 'tesdiqden sonra kilid acilmali idi';

  --  kilidi baglayaq - admin RPC-leri islemez
  reset role;
  delete from public.admin_unlocks;
  set local role authenticated;
  assert not app.admin_ok(), 'kilidli halda admin_ok true verdi!';
  begin
    perform public.rpc_admin_reports('new'); okbad := false;
  exception when insufficient_privilege then okbad := true; end;
  assert okbad, 'kilidli halda admin RPC isledi!';

  --  kodla acilir
  reset role;
  delete from public.admin_code_attempts;
  set local role authenticated;
  code := app.totp_at(sec, now());
  assert (public.rpc_admin_unlock(code)->>'ok')::boolean, 'kilid acilmadi';
  assert app.admin_ok(), 'kilid acilmadi';
  perform public.rpc_admin_reports('new');

  --  ehtiyat kod: bir defe isleyir, ikinci defe yanir
  reset role;
  delete from public.admin_unlocks; delete from public.admin_code_attempts;
  set local role authenticated;
  v := public.rpc_admin_unlock(bkp);
  assert (v->>'ok')::boolean, 'ehtiyat kod islemedi';
  assert (v->>'backup_left')::int = 3, 'ehtiyat sayi sehvdir';
  reset role;
  delete from public.admin_unlocks;
  set local role authenticated;
  assert not (public.rpc_admin_unlock(bkp)->>'ok')::boolean,
         'yanmis ehtiyat kod tekrar isledi!';
  code := app.totp_at(sec, now());
  perform public.rpc_admin_unlock(code);
  reset role;
end $$;
\echo 'OK  5 · 2FA: qurulus -> tesdiq -> kilid -> acilis'

-- =====================================================================
--  6. Cehd heddi: 5 cehden sonra 10 deqiqe kilid
-- =====================================================================
do $$
declare i int; v jsonb;
begin
  delete from public.admin_code_attempts;
  set local role authenticated;
  set local request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000d1';
  for i in 1..5 loop
    perform public.rpc_admin_unlock('000000');
  end loop;
  v := public.rpc_admin_unlock('000000');
  assert not (v->>'ok')::boolean
     and position('Çox cəhd' in v->>'err') > 0, 'cehd heddi islemir';
  reset role;
end $$;
\echo 'OK  6 · kobud guc: 5 cehdden sonra dayandirilir'

-- =====================================================================
--  7. anon hec neye toxuna bilmir
-- =====================================================================
reset role; reset request.jwt.claim.sub;
do $$
begin
  assert not has_function_privilege('anon', 'public.rpc_report_question(uuid, text, text)', 'EXECUTE'),
         'anon muellim kimi bildirir';
  assert not has_function_privilege('anon', 'public.rpc_admin_reports(text)', 'EXECUTE'),
         'anon bildirisleri gorur';
  assert not has_function_privilege('anon', 'public.rpc_admin_unlock(text)', 'EXECUTE'),
         'anon kilide toxunur';
  assert has_function_privilege('anon', 'public.rpc_report_question_student(text, uuid, text, text)', 'EXECUTE'),
         'sagird bildirisi anon acari ile islemelidir';
end $$;
\echo 'OK  7 · huquqlar: anon yalniz sagird bildirisine (token ile) catir'
