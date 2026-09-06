-- =====================================================================
--  smoke_adaptiv.sql : adaptiv movzu mesqi (db/133)
--
--  Iddialar: movzu siyahisi sinfe/fenne gore · serbest mesq bagli ->
--  bagli · sual duz variantsiz gelir, tekrar sorguda eyni · duz +bal,
--  sehv -bal, seviyye baldan · kohne suala cavab reddedilir · 100 ->
--  menimsenildi, muellim hesabati ve valideyn sayğaci · tekrar yoxdur ·
--  sehv deftere dusur.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.practice; delete from public.mistakes;
delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers;  delete from public.attempts;
delete from public.assignments;      delete from public.student_sessions; delete from public.parent_sessions;
delete from public.students;         delete from public.classes;
delete from public.subscriptions;
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-0000000000a5','ad@t.az','{"full_name":"Adaptiv Muellim"}');
insert into public.accounts (id, type, name, owner_id, subjects) values
  ('aaaa0000-0000-0000-0000-0000000000a5','tutor','AD hesabi','11110000-0000-0000-0000-0000000000a5', '{riyaziyyat}');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000a5','11110000-0000-0000-0000-0000000000a5',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code, level_id) values
  ('cccc0000-0000-0000-0000-0000000000a5','aaaa0000-0000-0000-0000-0000000000a5',
   '11110000-0000-0000-0000-0000000000a5','tutor_group','AD qrup','KODAD001',
   (select id from public.levels where code = '3' order by sort limit 1));
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code) values
  ('5555000a-0000-0000-0000-0000000000a5','aaaa0000-0000-0000-0000-0000000000a5',
   'cccc0000-0000-0000-0000-0000000000a5','11110000-0000-0000-0000-0000000000a5','Ayan Bir','Ayan B.','ADFT0001');

create or replace function pg_temp.duz(p_q uuid) returns uuid[] language sql as $$
  select coalesce(array_agg(o.id), '{}') from public.question_options o where o.question_id = p_q and o.is_correct $$;
create or replace function pg_temp.sehv(p_q uuid) returns uuid[] language sql as $$
  select array[o.id] from public.question_options o where o.question_id = p_q and not o.is_correct order by o.ord limit 1 $$;

\echo '--- hazirliq tamam'

-- =====================================================================
--  1. Movzu siyahisi: yalniz hesabin fenni, sinfin kok movzulari;
--     serbest mesq bagli -> enabled false; sinif yoxdur -> sebeb
-- =====================================================================
do $$
declare tok text; v jsonb; n int;
begin
  tok := public.rpc_student_login('ADFT0001')->>'token';
  set local role anon;
  v := public.rpc_student_practice_topics(tok);
  reset role;
  assert (v->>'enabled')::boolean, 'acıq olmali';
  assert jsonb_array_length(v->'subjects') = 1 and v->'subjects'->0->>'name' = 'Riyaziyyat', 'yalniz riyaziyyat: ' || left(v::text, 120);
  n := jsonb_array_length(v->'subjects'->0->'topics');
  assert n >= 5, 'movzu sayi az: ' || n;
  assert (select bool_and((t->>'n')::int >= 5 and (t->>'score')::int = 0 and not (t->>'mastered')::boolean)
            from jsonb_array_elements(v->'subjects'->0->'topics') t), 'movzu setri';
  perform set_config('smoke.t1', v->'subjects'->0->'topics'->0->>'id', false);

  update public.classes set free_practice = false where id = 'cccc0000-0000-0000-0000-0000000000a5';
  set local role anon;
  v := public.rpc_student_practice_topics(tok);
  reset role;
  assert not (v->>'enabled')::boolean and v->>'reason' like '%bağlayıb%', 'bagli olmali';
  update public.classes set free_practice = true, level_id = null where id = 'cccc0000-0000-0000-0000-0000000000a5';
  set local role anon;
  v := public.rpc_student_practice_topics(tok);
  reset role;
  assert not (v->>'enabled')::boolean and v->>'reason' like '%sinfi%', 'sinifsiz sebeb';
  update public.classes set level_id = (select id from public.levels where code = '3' order by sort limit 1)
   where id = 'cccc0000-0000-0000-0000-0000000000a5';
end $$;
\echo 'OK  1 · movzu siyahisi fenne/sinfe gore; bagli ve sinifsiz hallar'

-- =====================================================================
--  2. Sual: duz variant yoxdur, tekrar sorguda eyni sual, seviyye 1
-- =====================================================================
do $$
declare tok text; a jsonb; b jsonb; t1 uuid := current_setting('smoke.t1')::uuid; bad boolean := false;
begin
  tok := public.rpc_student_login('ADFT0001')->>'token';
  set local role anon;
  a := public.rpc_student_practice_next(tok, t1);
  b := public.rpc_student_practice_next(tok, t1);
  reset role;
  assert a::text not like '%is_correct%', 'duz variant sizdi';
  assert a->'question'->>'id' = b->'question'->>'id', 'tekrar sorguda eyni sual olmali';
  assert (a->>'level')::int = 1 and (a->>'score')::int = 0, 'basda seviyye 1';
  assert (a->'question'->>'difficulty')::int = 1, 'asan sual gelmeli: ' || (a->'question'->>'difficulty');
  assert jsonb_array_length(a->'question'->'options') >= 2, 'variantlar';
  --  basqa sinfin movzusu reddedilir
  begin
    set local role anon;
    perform public.rpc_student_practice_next(tok, (select t.id from public.topics t join public.levels l on l.id = t.level_id where l.code = '7' and t.parent_id is null limit 1));
  exception when others then bad := true; end;
  reset role;
  assert bad, 'yad sinif movzusu qebul olundu';
end $$;
\echo 'OK  2 · sual duz variantsiz, tekrarda eyni, seviyye baldan'

-- =====================================================================
--  3. Duz +12, sehv -8, kohne suala cavab reddedilir, sehv deftere dusur
-- =====================================================================
do $$
declare tok text; a jsonb; r jsonb; t1 uuid := current_setting('smoke.t1')::uuid; q uuid; ok uuid[]; no uuid[]; bad boolean := false;
begin
  tok := public.rpc_student_login('ADFT0001')->>'token';
  a := public.rpc_student_practice_next(tok, t1);
  q := (a->'question'->>'id')::uuid; ok := pg_temp.duz(q); no := pg_temp.sehv(q);
  set local role anon;
  r := public.rpc_student_practice_answer(tok, t1, q, ok, null);
  reset role;
  assert (r->>'correct')::boolean and (r->>'score')::int = 12 and (r->>'gain')::int = 12 and (r->>'streak')::int = 1,
         'duz: ' || r::text;
  assert r::text not like '%is_correct%', 'sizinti';
  --  eyni suala ikinci cavab reddedilir
  begin
    set local role anon;
    perform public.rpc_student_practice_answer(tok, t1, q, ok, null);
  exception when others then bad := true; end;
  reset role;
  assert bad, 'tekrar cavab qebul olundu';
  --  sehv
  a := public.rpc_student_practice_next(tok, t1);
  q := (a->'question'->>'id')::uuid; no := pg_temp.sehv(q);
  set local role anon;
  r := public.rpc_student_practice_answer(tok, t1, q, no, null);
  reset role;
  assert not (r->>'correct')::boolean and (r->>'score')::int = 4 and (r->>'gain')::int = -8 and (r->>'streak')::int = 0,
         'sehv: ' || r::text;
  assert exists (select 1 from public.mistakes where student_id = '5555000a-0000-0000-0000-0000000000a5' and question_id = q and status = 'open'),
         'sehv deftere dusmedi';
  assert (select answered = 2 and correct = 1 and cardinality(seen) = 2 and cur is null from public.practice where topic_id = t1), 'sayğaclar';
end $$;
\echo 'OK  3 · duz +bal, sehv -bal, tekrar cavab reddedilir, sehv deftere dusur'

-- =====================================================================
--  4. 100-e qeder: seviyye qalxir, tekrar sual yoxdur, menimsenildi;
--     muellim hesabati ve valideyn sayğaci
-- =====================================================================
do $$
declare tok text; a jsonb; r jsonb; t1 uuid := current_setting('smoke.t1')::uuid; q uuid; i int := 0;
        seen uuid[] := '{}'; lv3 boolean := false; v jsonb; ptok text; pc text; jm int := 0; ok uuid[];
begin
  tok := public.rpc_student_login('ADFT0001')->>'token';
  loop
    i := i + 1;
    a := public.rpc_student_practice_next(tok, t1);
    q := (a->'question'->>'id')::uuid;
    assert not (q = any(seen)), 'sual tekrar geldi';
    seen := seen || q;
    if (a->>'level')::int = 3 then
      lv3 := true;
      assert (a->'question'->>'difficulty')::int = 3, 'seviyye 3-de cetin sual gelmeli';
    end if;
    ok := pg_temp.duz(q);
    set local role anon;
    r := public.rpc_student_practice_answer(tok, t1, q, ok, null);
    reset role;
    if (r->>'just_mastered')::boolean then jm := jm + 1; end if;
    exit when (r->>'mastered')::boolean or i > 15;
  end loop;
  assert (r->>'mastered')::boolean and (r->>'score')::int = 100, 'menimsenilmedi: ' || i;
  assert jm = 1, 'just_mastered bir defe';
  assert lv3, 'seviyye 3-e catmadi';
  assert i between 6 and 10, 'cehd sayi gozlenilmez: ' || i;
  assert (select mastered_at is not null from public.practice where topic_id = t1), 'mastered_at';
  --  siyahida
  set local role anon;
  v := public.rpc_student_practice_topics(tok);
  reset role;
  assert (v->>'mastered')::int = 1 and (select (t->>'mastered')::boolean from jsonb_array_elements(v->'subjects'->0->'topics') t where t->>'id' = t1::text), 'siyahida menimsenilib';
  --  muellim hesabati
  set local role authenticated;
  set local request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000a5';
  v := public.rpc_student_report('5555000a-0000-0000-0000-0000000000a5');
  pc := public.rpc_parent_access('5555000a-0000-0000-0000-0000000000a5', true)->>'parent_code';
  reset role;
  assert (v->'practice'->>'mastered')::int = 1 and (v->'practice'->>'active')::int = 0
     and jsonb_array_length(v->'practice'->'items') = 1 and (v->'practice'->'items'->0->>'score')::int = 100, 'hesabat: ' || (v->'practice')::text;
  --  valideyn
  set local role anon;
  ptok := public.rpc_parent_login(pc)->>'token';
  v := public.rpc_parent_home(ptok);
  reset role;
  assert (v->'practice'->>'mastered')::int = 1, 'valideyn sayğaci: ' || (v->'practice')::text;
  --  menimsenildikden sonra da mesq davam edir (bal 100-de qalir)
  a := public.rpc_student_practice_next(tok, t1);
  q := (a->'question'->>'id')::uuid; ok := pg_temp.duz(q);
  set local role anon;
  r := public.rpc_student_practice_answer(tok, t1, q, ok, null);
  reset role;
  assert (r->>'score')::int = 100 and (r->>'mastered')::boolean and not (r->>'just_mastered')::boolean, 'sonra da davam';
end $$;
\echo 'OK  4 · 100-e qeder: seviyye qalxir, tekrar yoxdur, menimsenildi; hesabat ve valideyn'

\echo 'ADAPTIV: BUTUN YOXLAMALAR KECDI'
