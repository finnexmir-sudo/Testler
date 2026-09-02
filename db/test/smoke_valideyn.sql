-- =====================================================================
--  smoke_valideyn.sql : valideyn girisi (db/107_valideyn.sql)
--
--  Bu suite esasen TEHLUKESIZLIK iddiasidir.  Valideyn kodu usagin
--  koduna cevrilse, valideyn usagin adindan test yaza biler ve butun
--  neticeler yalan olar.  Ona gore hemin sinirlarin HER BIRI ayrica
--  yoxlanilir - "isleyir" kifayet deyil.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.parent_sessions;
delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers;  delete from public.attempts;
delete from public.assignments;      delete from public.student_sessions;
delete from public.students;         delete from public.classes;
delete from public.subscriptions;
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-0000000000fa','v@t.az','{"full_name":"Valideyn M"}'),
  ('11110000-0000-0000-0000-0000000000fb','y@t.az','{"full_name":"Yad Muellim"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000fa','tutor','V hesabi',
   '11110000-0000-0000-0000-0000000000fa'),
  ('aaaa0000-0000-0000-0000-0000000000fb','tutor','Yad hesab',
   '11110000-0000-0000-0000-0000000000fb');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000fa','11110000-0000-0000-0000-0000000000fa',true),
  ('aaaa0000-0000-0000-0000-0000000000fb','11110000-0000-0000-0000-0000000000fb',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-0000000000fa','aaaa0000-0000-0000-0000-0000000000fa',
   '11110000-0000-0000-0000-0000000000fa','tutor_group','V qrupu','KODVAL01');

\echo '--- hazirliq tamam'

set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000fa';

-- =====================================================================
--  1. SUSMAYA GORE BAGLI - muellim acmayibsa valideyn girisi yoxdur
-- =====================================================================
do $$
declare v jsonb; sid uuid; n int;
begin
  v := public.rpc_add_student('cccc0000-0000-0000-0000-0000000000fa','Ayan Qasimova');
  sid := (v->>'id')::uuid;
  select count(*) into n from public.students
   where id = sid and parent_code is not null;
  assert n = 0, 'yeni sagirde valideyn kodu OZ-OZUNE verildi';
end $$;
\echo 'OK  1 · valideyn girisi susmaya gore BAGLIDIR'

-- =====================================================================
--  2. Muellim acir -> kod gelir; ikinci defe basanda kod DEYISMIR
-- =====================================================================
do $$
declare sid uuid; a jsonb; b jsonb;
begin
  select id into sid from public.students where full_name = 'Ayan Qasimova';
  a := public.rpc_parent_access(sid, true);
  assert a->>'parent_code' is not null, 'kod yaranmadi';
  assert length(a->>'parent_code') = 8, 'kod uzunlugu yanlisdir';
  b := public.rpc_parent_access(sid, true);
  assert a->>'parent_code' = b->>'parent_code',
    'ikinci klik valideynin kodunu qirdi: ' || (a->>'parent_code') ||
    ' -> ' || (b->>'parent_code');
end $$;
\echo 'OK  2 · muellim acir, tekrar klik kodu qirmir'

-- =====================================================================
--  3. YAD muellim basqasinin sagirdine valideyn girisi aca bilmir
-- =====================================================================
reset role; reset request.jwt.claim.sub;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000fb';
do $$
declare sid uuid; ok boolean := false;
begin
  select id into sid from public.students where full_name = 'Ayan Qasimova';
  begin
    perform public.rpc_parent_access(sid, true);
  exception when others then ok := true;
  end;
  assert ok, 'yad muellim basqasinin sagirdine valideyn girisi acdi';
end $$;
\echo 'OK  3 · yad muellim ozge sagirde giris aca bilmir'

-- =====================================================================
--  4. Valideyn kodla girir; yanlis kod kecmir
-- =====================================================================
reset role; reset request.jwt.claim.sub;
do $$
declare code text; v jsonb;
begin
  select parent_code into code from public.students where full_name = 'Ayan Qasimova';
  v := public.rpc_parent_login(code);
  assert (v->>'ok')::boolean, 'duz kodla giris alinmadi: ' || coalesce(v->>'error','');
  assert v->>'token' is not null, 'token gelmedi';
  assert v->'child'->>'name' is not null, 'usagin adi gelmedi';
  --  TAM AD getmemelidir - kod yayilsa yad adam tam adi oyrenmesin
  assert v::text not like '%Qasimova%', 'valideyn girisinde usagin TAM ADI gedir';
  --  usagin oz giris kodu HEC VAXT
  assert v::text not like '%login_code%', 'valideyn cavabinda login_code var';

  v := public.rpc_parent_login('YOXBELE1');
  assert not (v->>'ok')::boolean, 'yanlis kod qebul olundu';
end $$;
\echo 'OK  4 · kodla giris isleyir, tam ad ve usaq kodu sizmir'

-- =====================================================================
--  5. ƏSAS SINIR: valideyn tokeni SAGIRD RPC-lerinde ISLEMIR
--     Eks halda valideyn usagin adindan test yaza biler.
-- =====================================================================
do $$
declare code text; tok text; ok boolean;
begin
  select parent_code into code from public.students where full_name = 'Ayan Qasimova';
  tok := public.rpc_parent_login(code)->>'token';

  ok := false;
  begin perform public.rpc_student_tests(tok);
  exception when others then ok := true; end;
  assert ok, 'valideyn tokeni rpc_student_tests-de isledi';

  ok := false;
  begin perform public.rpc_student_my_results(tok);
  exception when others then ok := true; end;
  assert ok, 'valideyn tokeni rpc_student_my_results-de isledi';

  ok := false;
  begin perform public.rpc_start_attempt(tok, gen_random_uuid());
  exception when others then ok := true; end;
  assert ok, 'valideyn tokeni rpc_start_attempt-de isledi';

  --  ve eksi: sagird sessiyasi valideyn ekranini acmamalidir
  assert app.session_parent('uydurma-token-0123456789abcdef') is null,
    'uydurma token valideyn sessiyasi acdi';
end $$;
\echo 'OK  5 · valideyn tokeni sagird RPC-lerinde ISLEMIR'

-- =====================================================================
--  6. Sagird tokeni valideyn ekranini ACMIR
-- =====================================================================
do $$
declare scode text; stok text; ok boolean := false;
begin
  select login_code into scode from public.students where full_name = 'Ayan Qasimova';
  stok := public.rpc_student_login(scode)->>'token';
  assert stok is not null, 'sagird girisi alinmadi';
  begin perform public.rpc_parent_home(stok);
  exception when others then ok := true; end;
  assert ok, 'sagird tokeni valideyn ekranini acdi';
end $$;
\echo 'OK  6 · sagird tokeni valideyn ekranini acmir'

-- =====================================================================
--  7. Ekran: duz cavab, usaq kodu, basqa usaqlar YOXDUR
-- =====================================================================
do $$
declare code text; tok text; v jsonb; t text;
begin
  select parent_code into code from public.students where full_name = 'Ayan Qasimova';
  tok := public.rpc_parent_login(code)->>'token';
  v := public.rpc_parent_home(tok);
  t := v::text;
  assert t not like '%is_correct%', 'valideyn ekraninda is_correct var';
  assert t not like '%"correct"%',  'valideyn ekraninda duz cavab nisani var';
  assert t not like '%login_code%', 'valideyn ekraninda usagin giris kodu var';
  assert t not like '%Qasimova%',   'valideyn ekraninda TAM AD var';
  assert v->'child'->>'name' is not null, 'usagin adi yoxdur';
  assert v ? 'summary' and v ? 'pending' and v ? 'results'
     and v ? 'weak' and v ? 'lessons', 'ekranin bolmeleri catismir';
end $$;
\echo 'OK  7 · ekran duz cavabi, usaq kodunu ve tam adi vermir'

-- =====================================================================
--  8. Muellim BAGLAYANDA acilmis sessiya DERHAL olur
-- =====================================================================
do $$
declare sid uuid; code text; tok text; ok boolean := false;
begin
  select id, parent_code into sid, code from public.students
   where full_name = 'Ayan Qasimova';
  tok := public.rpc_parent_login(code)->>'token';
  assert public.rpc_parent_home(tok) is not null, 'giris evvelce islememelidir?';

  set role authenticated;
  set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000fa';
  perform public.rpc_parent_access(sid, false);
  reset role; reset request.jwt.claim.sub;

  begin perform public.rpc_parent_home(tok);
  exception when others then ok := true; end;
  assert ok, 'giris baglandi, amma acilmis sessiya HELE DE isleyir';
  assert not (public.rpc_parent_login(code)->>'ok')::boolean,
    'baglandiqdan sonra kohne kod hele de isleyir';
end $$;
\echo 'OK  8 · baglayanda acilmis sessiyalar da derhal olur'

-- =====================================================================
--  9. Kod deyisdirilende kohnesi olur (kod yayilanda lazimdir)
-- =====================================================================
do $$
declare sid uuid; k1 text; k2 text; tok text; ok boolean := false;
begin
  select id into sid from public.students where full_name = 'Ayan Qasimova';
  set role authenticated;
  set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000fa';
  k1  := public.rpc_parent_access(sid, true)->>'parent_code';
  reset role; reset request.jwt.claim.sub;
  tok := public.rpc_parent_login(k1)->>'token';

  set role authenticated;
  set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000fa';
  k2 := public.rpc_parent_code_reset(sid)->>'parent_code';
  reset role; reset request.jwt.claim.sub;

  assert k1 <> k2, 'kod deyismedi';
  assert not (public.rpc_parent_login(k1)->>'ok')::boolean, 'kohne kod hele isleyir';
  begin perform public.rpc_parent_home(tok);
  exception when others then ok := true; end;
  assert ok, 'kod deyisdi, amma kohne sessiya isleyir';
  assert (public.rpc_parent_login(k2)->>'ok')::boolean, 'yeni kod islemir';
end $$;
\echo 'OK  9 · kod deyisdirilende kohne kod ve sessiya olur'

-- =====================================================================
-- 10. Sessiya 30 gundur - vaxti kecmis token qebul olunmur
-- =====================================================================
do $$
declare code text; tok text; ok boolean := false; v_exp timestamptz;
begin
  select parent_code into code from public.students where full_name = 'Ayan Qasimova';
  tok := public.rpc_parent_login(code)->>'token';
  select expires_at into v_exp from public.parent_sessions
   where token_hash = app.hash_token(tok);
  assert v_exp > now() + interval '29 days'
     and v_exp < now() + interval '31 days',
    'sessiya 30 gun deyil: ' || v_exp::text;

  update public.parent_sessions set expires_at = now() - interval '1 minute'
   where token_hash = app.hash_token(tok);
  begin perform public.rpc_parent_home(tok);
  exception when others then ok := true; end;
  assert ok, 'vaxti kecmis token hele de isleyir';
end $$;
\echo 'OK 10 · sessiya 30 gundur, vaxti kecende baglanir'

-- =====================================================================
-- 11. Dayandirilmis sagirdin valideyni de gire bilmir
-- =====================================================================
do $$
declare sid uuid; code text; ok boolean := false;
begin
  select id, parent_code into sid, code from public.students
   where full_name = 'Ayan Qasimova';
  update public.students set is_active = false where id = sid;
  assert not (public.rpc_parent_login(code)->>'ok')::boolean,
    'dayandirilmis sagirdin valideyni gire bildi';
  update public.students set is_active = true where id = sid;
end $$;
\echo 'OK 11 · dayandirilmis sagirdin valideyni gire bilmir'

-- =====================================================================
-- 12. Huquqlar: anon giris/ekran cagira bilir, ACMAGI bacarmir
-- =====================================================================
do $$
begin
  if not has_function_privilege('anon','public.rpc_parent_login(text)','EXECUTE') then
    raise exception 'anon valideyn girisini cagira bilmir - tetbiq islemez';
  end if;
  if not has_function_privilege('anon','public.rpc_parent_home(text)','EXECUTE') then
    raise exception 'anon valideyn ekranini cagira bilmir - tetbiq islemez';
  end if;
  if has_function_privilege('anon',
      'public.rpc_parent_access(uuid, boolean)','EXECUTE') then
    raise exception 'anon valideyn girisini ACA bilir';
  end if;
  if has_function_privilege('anon',
      'public.rpc_parent_code_reset(uuid)','EXECUTE') then
    raise exception 'anon valideyn kodunu deyise bilir';
  end if;
  if has_function_privilege('anon','app.session_parent(text)','EXECUTE') then
    raise exception 'anon sessiya funksiyasini birbasa cagira bilir';
  end if;
end $$;
\echo 'OK 12 · huquqlar duzgun bolusdurulub'

\echo 'VALIDEYN: BUTUN YOXLAMALAR KECDI'
