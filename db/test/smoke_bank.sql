-- =====================================================================
--  smoke_bank.sql : sual banki - mulkiyyet, tarixce, terkib
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments;     delete from public.student_sessions;
delete from public.test_questions where test_id in
  (select id from public.tests where owner_type = 'educator');
delete from public.questions where owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.students; delete from public.classes;
delete from public.account_members; delete from public.accounts;
delete from public.user_roles; delete from public.profiles; delete from auth.users;

insert into auth.users (id, email) values
  ('11110000-0000-0000-0000-00000000000a','a@b.az'),
  ('22220000-0000-0000-0000-00000000000b','b@b.az');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-00000000000a','tutor','A','11110000-0000-0000-0000-00000000000a'),
  ('aaaa0000-0000-0000-0000-00000000000b','tutor','B','22220000-0000-0000-0000-00000000000b');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-00000000000a','11110000-0000-0000-0000-00000000000a',true),
  ('aaaa0000-0000-0000-0000-00000000000b','22220000-0000-0000-0000-00000000000b',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code, level_id)
select 'cccc0000-0000-0000-0000-00000000000a','aaaa0000-0000-0000-0000-00000000000a',
       '11110000-0000-0000-0000-00000000000a','tutor_group','Qrup A','BANKKOD1', l.id
  from public.levels l join public.programs p on p.id = l.program_id
 where p.slug='ibtidai' and l.code='3';
insert into public.students (id, account_id, class_id, created_by, full_name,
                             display_name, login_code) values
  ('5555000b-0000-0000-0000-00000000000a','aaaa0000-0000-0000-0000-00000000000a',
   'cccc0000-0000-0000-0000-00000000000a','11110000-0000-0000-0000-00000000000a',
   'Eli Mirzeyev','Eli M.','BANK1111');

-- anon rolu public.tests-i oxuya bilmir - id-leri qabaqcadan yigiriq
drop table if exists public.test_fixtures;
create table public.test_fixtures (k text primary key, v uuid);
insert into public.test_fixtures select slug, id from public.tests
 where slug in ('riy-3-vurma-1');
insert into public.test_fixtures
select 'q1', tq.question_id from public.test_questions tq
  join public.tests t on t.id = tq.test_id and t.slug = 'riy-3-vurma-1'
 order by tq.ord limit 1;
insert into public.test_fixtures
select 'o1', o.id from public.question_options o
 where o.question_id = (select v from public.test_fixtures where k = 'q1')
   and o.is_correct limit 1;
grant select on public.test_fixtures to anon, authenticated;

\echo '--- hazirliq tamam'

-- =====================================================================
--  1. Sual testden ASILI DEYIL
-- =====================================================================
do $$
declare v_q uuid;
begin
  insert into public.questions
    (owner_type, owner_id, account_id, subject_id, level_id, topic_id,
     kind, body, explanation, difficulty, quarter)
  select 'educator','11110000-0000-0000-0000-00000000000a',
         'aaaa0000-0000-0000-0000-00000000000a', s.id, l.id, tp.id,
         'single','7 x 6 nece eder?','Qirx iki.',2,1
    from public.subjects s
    join public.levels l on l.code = '3'
    join public.programs p on p.id = l.program_id and p.slug = 'ibtidai'
    left join public.topics tp on tp.subject_id = s.id and tp.slug = 'vurma-cedveli'
   where s.slug = 'riyaziyyat'
  returning id into v_q;
  assert v_q is not null, 'test olmadan sual yazila bilmedi';
end $$;
\echo 'OK  1 · sual test olmadan banka yazilir'

-- =====================================================================
--  2. Bir sual IKI testde isleye bilir
-- =====================================================================
do $$
declare v_q uuid; t1 uuid; t2 uuid;
begin
  select id into v_q from public.questions where owner_type = 'educator';
  insert into public.tests (owner_type, owner_id, program_id, subject_id, title, status)
  select 'educator','11110000-0000-0000-0000-00000000000a', p.id, s.id, 'Test 1','published'
    from public.programs p, public.subjects s
   where p.slug='ibtidai' and s.slug='riyaziyyat' returning id into t1;
  insert into public.tests (owner_type, owner_id, program_id, subject_id, title, status)
  select 'educator','11110000-0000-0000-0000-00000000000a', p.id, s.id, 'Test 2','published'
    from public.programs p, public.subjects s
   where p.slug='ibtidai' and s.slug='riyaziyyat' returning id into t2;

  insert into public.test_questions (test_id, question_id, ord) values (t1, v_q, 1), (t2, v_q, 1);
  assert (select count(*) from public.test_questions where question_id = v_q) = 2,
         'eyni sual iki testde ola bilmedi';
end $$;
\echo 'OK  2 · eyni sual bir nece testde islenir'

-- =====================================================================
--  3. Eyni testde eyni sual IKI DEFE olmur, sira tekrarlanmir
-- =====================================================================
do $$
declare v_q uuid; t1 uuid; ok1 boolean := false; ok2 boolean := false; v_q2 uuid;
begin
  select id into v_q from public.questions where owner_type = 'educator';
  select id into t1 from public.tests where title = 'Test 1';
  begin
    insert into public.test_questions (test_id, question_id, ord) values (t1, v_q, 9);
  exception when unique_violation then ok1 := true; end;
  assert ok1, 'eyni sual teste iki defe dusdu';

  insert into public.questions (owner_type, owner_id, account_id, subject_id, kind, body)
  select 'educator','11110000-0000-0000-0000-00000000000a',
         'aaaa0000-0000-0000-0000-00000000000a', s.id, 'single','8 x 8 ?'
    from public.subjects s where s.slug='riyaziyyat' returning id into v_q2;
  begin
    insert into public.test_questions (test_id, question_id, ord) values (t1, v_q2, 1);
  exception when unique_violation then ok2 := true; end;
  assert ok2, 'eyni sira nomresi iki defe dusdu';
end $$;
\echo 'OK  3 · testde sual ve sira tekrarlanmir'

-- =====================================================================
--  4. Cetinlik 1-3, rub 1-4, ay 1-12 ile mehdudlasir
-- =====================================================================
do $$
declare n int := 0;
begin
  begin insert into public.questions (owner_type, subject_id, kind, body, difficulty)
        select 'platform', s.id, 'single','x', 4 from public.subjects s where s.slug='riyaziyyat';
  exception when check_violation then n := n + 1; end;
  begin insert into public.questions (owner_type, subject_id, kind, body, quarter)
        select 'platform', s.id, 'single','x', 5 from public.subjects s where s.slug='riyaziyyat';
  exception when check_violation then n := n + 1; end;
  begin insert into public.questions (owner_type, subject_id, kind, body, month)
        select 'platform', s.id, 'single','x', 13 from public.subjects s where s.slug='riyaziyyat';
  exception when check_violation then n := n + 1; end;
  begin insert into public.questions (owner_type, subject_id, kind, body)
        select 'platform', s.id, 'single','   ' from public.subjects s where s.slug='riyaziyyat';
  exception when check_violation then n := n + 1; end;
  assert n = 4, format('yalniz %s hedd tutuldu, 4 olmali idi', n);
end $$;
\echo 'OK  4 · cetinlik, rub, ay ve bos metn hedleri bazada tetbiq olunur'

-- =====================================================================
--  5. Muellimin sualina sahiblik: hesab MECBURIDIR
-- =====================================================================
do $$
declare ok1 boolean := false; ok2 boolean := false;
begin
  begin  -- educator, amma hesabsiz
    insert into public.questions (owner_type, owner_id, subject_id, kind, body)
    select 'educator','11110000-0000-0000-0000-00000000000a', s.id,'single','x'
      from public.subjects s where s.slug='riyaziyyat';
  exception when check_violation then ok1 := true; end;
  assert ok1, 'hesabsiz muellim sualı yazildi';

  begin  -- platform, amma sahibi var
    insert into public.questions (owner_type, owner_id, subject_id, kind, body)
    select 'platform','11110000-0000-0000-0000-00000000000a', s.id,'single','x'
      from public.subjects s where s.slug='riyaziyyat';
  exception when check_violation then ok2 := true; end;
  assert ok2, 'platforma sualina sahib yazildi';
end $$;
\echo 'OK  5 · sualin mulkiyyeti bazada tetbiq olunur'

-- =====================================================================
--  6. RLS: ozge muellim sualı gormur, platformanini gorur
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '22220000-0000-0000-0000-00000000000b';
do $$
declare n_own int; n_plat int;
begin
  select count(*) into n_own  from public.questions where owner_type = 'educator';
  select count(*) into n_plat from public.questions where owner_type = 'platform';
  assert n_own = 0, format('ozge muellimin %s sualini gordu', n_own);
  assert n_plat > 0, 'platformanin suallarini gormur - generator islemeyecek';
end $$;
\echo 'OK  6 · ozge sual gizli, platforma hovuzu acıq'

-- =====================================================================
--  7. Cavab acari: variantlar OZGEYE ve platformaya baglidir
-- =====================================================================
do $$
declare n int;
begin
  select count(*) into n from public.question_options;
  assert n = 0, format('muellim %s ozge variant gordu - cavab acari sizir!', n);
end $$;
\echo 'OK  7 · cavab acari basqa muellime ve platformaya baglidir'

reset role; reset request.jwt.claim.sub;

-- =====================================================================
--  8. ISLENMIS sual silinmir  (tarixce qorunur)
-- =====================================================================
set role anon;
do $$
declare tok text; t uuid; att uuid; oid uuid; q uuid;
begin
  select f.v into t   from public.test_fixtures f where f.k = 'riy-3-vurma-1';
  select f.v into q   from public.test_fixtures f where f.k = 'q1';
  select f.v into oid from public.test_fixtures f where f.k = 'o1';
  tok := public.rpc_student_login('BANK1111')->>'token';
  att := (public.rpc_start_attempt(tok, t)->>'attempt_id')::uuid;
  perform public.rpc_submit_attempt(tok, att,
    jsonb_build_array(jsonb_build_object('q', q, 'o', jsonb_build_array(oid))));
end $$;
reset role;

do $$
declare q uuid; ok boolean := false;
begin
  select question_id into q from public.attempt_answers limit 1;
  begin
    delete from public.questions where id = q;
    assert false, 'islenmis sual silindi - tarixce oldu!';
  exception when foreign_key_violation then ok := true; end;
  assert ok, 'foreign key qorumasi islemedi';
end $$;
\echo 'OK  8 · testde islenmis sual silinmir'

-- =====================================================================
--  9. SURET: sual redakte olunsa da kohne netice deyismir
-- =====================================================================
do $$
declare q uuid; kohne text; sonra text;
begin
  select question_id, question_body into q, kohne from public.attempt_answers limit 1;
  assert kohne is not null and length(kohne) > 3, 'sualin sureti yazilmayib';
  assert kohne = (select body from public.questions where id = q),
         'suret sualin ozunden ferqlidir';

  update public.questions set body = 'TAMAM BASQA SUAL' where id = q;
  select question_body into sonra from public.attempt_answers where question_id = q;
  assert sonra = kohne,
    format('sual deyisdi, hesabat da deyisdi: %s -> %s', kohne, sonra);
end $$;
\echo 'OK  9 · sual redakte olunanda kohne netice deyismir'

-- =====================================================================
-- 10. Test silinende terkib gedir, BANK qalir
-- =====================================================================
do $$
declare t1 uuid; n_before int; n_after int;
begin
  select count(*) into n_before from public.questions where owner_type = 'educator';
  select id into t1 from public.tests where title = 'Test 2';
  delete from public.tests where id = t1;
  select count(*) into n_after from public.questions where owner_type = 'educator';
  assert n_before = n_after, format('test silindi, %s sual da getdi', n_before - n_after);
  assert (select count(*) from public.test_questions where test_id = t1) = 0,
         'terkib qaldi';
end $$;
\echo 'OK 10 · test silinir, suallar bankda qalir'

\echo ''
\echo '=============================='
\echo ' SUAL BANKI: HAMISI KECDI'
\echo '=============================='
drop table if exists public.test_fixtures;
