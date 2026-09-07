-- =====================================================================
--  smoke_mesq_limit.sql : movzu mesqinde abunesiz gundelik limit (db/137)
--
--  Iddialar: abunesiz hesabda 20 cavabdan sonra "novbeti" reddedilir,
--  verilmis sual yene cavablanir · quota siyahida ve cavabda gelir ·
--  abune ile limit yoxdur · sehv defteri limitden asili deyil.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.practice_days; delete from public.practice; delete from public.mistakes;
delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers;  delete from public.attempts;
delete from public.assignments;      delete from public.student_sessions;
delete from public.students where account_id = 'aaaa0000-0000-0000-0000-0000000000a6';
delete from public.classes  where account_id = 'aaaa0000-0000-0000-0000-0000000000a6';
delete from public.subscriptions where account_id = 'aaaa0000-0000-0000-0000-0000000000a6';
delete from public.account_members where account_id = 'aaaa0000-0000-0000-0000-0000000000a6';
delete from public.accounts where id = 'aaaa0000-0000-0000-0000-0000000000a6';
delete from auth.users where id = '11110000-0000-0000-0000-0000000000a6';

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-0000000000a6','lim@t.az','{"full_name":"Limit Muellim"}');
insert into public.accounts (id, type, name, owner_id, subjects) values
  ('aaaa0000-0000-0000-0000-0000000000a6','tutor','LIM hesabi','11110000-0000-0000-0000-0000000000a6', '{riyaziyyat}');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000a6','11110000-0000-0000-0000-0000000000a6',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code, level_id) values
  ('cccc0000-0000-0000-0000-0000000000a6','aaaa0000-0000-0000-0000-0000000000a6',
   '11110000-0000-0000-0000-0000000000a6','tutor_group','LIM qrup','KODLM001',
   (select id from public.levels where code = '3' order by sort limit 1));
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code) values
  ('5555000a-0000-0000-0000-0000000000a6','aaaa0000-0000-0000-0000-0000000000a6',
   'cccc0000-0000-0000-0000-0000000000a6','11110000-0000-0000-0000-0000000000a6','Lim Bir','Lim B.','LMFT0001');
create or replace function pg_temp.duz(p_q uuid) returns uuid[] language sql as $$
  select coalesce(array_agg(o.id), '{}') from public.question_options o where o.question_id = p_q and o.is_correct $$;
\echo '--- hazirliq tamam'

-- =====================================================================
--  1. Abunesiz: 20 cavab olur, 21-ci "novbeti" reddedilir; quota gelir
-- =====================================================================
do $$
declare tok text; v jsonb; t1 uuid; a jsonb; r jsonb; q uuid; ok uuid[]; i int; bad boolean := false;
begin
  tok := public.rpc_student_login('LMFT0001')->>'token';
  set local role anon;
  v := public.rpc_student_practice_topics(tok);
  reset role;
  assert not (v->'quota'->>'paid')::boolean and (v->'quota'->>'used')::int = 0 and (v->'quota'->>'max')::int = 20, 'quota basda: ' || (v->'quota')::text;
  t1 := (v->'subjects'->0->'topics'->0->>'id')::uuid;
  for i in 1..20 loop
    a := public.rpc_student_practice_next(tok, t1);
    q := (a->'question'->>'id')::uuid; ok := pg_temp.duz(q);
    set local role anon;
    r := public.rpc_student_practice_answer(tok, t1, q, ok, null);
    reset role;
    assert (r->'quota'->>'used')::int = i, 'sayğac ' || i;
  end loop;
  --  21-ci: novbeti reddedilir
  begin
    set local role anon;
    perform public.rpc_student_practice_next(tok, t1);
  exception when others then bad := true; end;
  reset role;
  assert bad, 'limitden sonra sual verildi';
  set local role anon;
  v := public.rpc_student_practice_topics(tok);
  reset role;
  assert (v->'quota'->>'used')::int = 20, 'siyahida 20/20';
  --  sehv defteri limitden asili deyil: cavab sehv olubsa deftere dusub, mesq acılır
  set local role anon;
  v := public.rpc_student_mistakes(tok);
  reset role;
  assert v ? 'items', 'defter cavab verir';
end $$;
\echo 'OK  1 · abunesiz 20 cavab, 21-ci reddedilir, quota gelir'

-- =====================================================================
--  2. Verilmis sual limitden sonra da cavablanir; abune ile limit yoxdur
-- =====================================================================
do $$
declare tok text; v jsonb; t2 uuid; a jsonb; r jsonb; q uuid; ok uuid[]; bad boolean := false;
begin
  tok := public.rpc_student_login('LMFT0001')->>'token';
  --  limitden evvel verilmis (cavabsiz) sual: 19-a endirib bir sual alaq, sonra 20-ye qaldiraq
  update public.practice_days set n = 19 where student_id = '5555000a-0000-0000-0000-0000000000a6';
  v := public.rpc_student_practice_topics(tok);
  t2 := (v->'subjects'->0->'topics'->1->>'id')::uuid;
  a := public.rpc_student_practice_next(tok, t2);
  q := (a->'question'->>'id')::uuid; ok := pg_temp.duz(q);
  update public.practice_days set n = 20 where student_id = '5555000a-0000-0000-0000-0000000000a6';
  --  eyni sual yeniden istenende (sehife yenilenib) - verilir, cunki cavabsizdir
  a := public.rpc_student_practice_next(tok, t2);
  assert (a->'question'->>'id')::uuid = q, 'verilmis sual limitde de qayitmali';
  set local role anon;
  r := public.rpc_student_practice_answer(tok, t2, q, ok, null);
  reset role;
  assert (r->>'correct')::boolean and (r->'quota'->>'used')::int = 21, 'verilmis sual cavablandi: ' || (r->'quota')::text;
  --  abune
  insert into public.subscriptions (account_id, plan_id, status, current_period_end)
  select 'aaaa0000-0000-0000-0000-0000000000a6', p.id, 'active', now() + interval '30 days'
    from public.plans p where p.slug = 'repetitor-25';
  a := public.rpc_student_practice_next(tok, t2);
  assert a->'question'->>'id' is not null, 'abune ile limit yoxdur';
  v := public.rpc_student_practice_topics(tok);
  assert (v->'quota'->>'paid')::boolean, 'quota paid';
end $$;
\echo 'OK  2 · verilmis sual limitde cavablanir; abune ile limit yoxdur'

\echo 'MESQ LIMIT: BUTUN YOXLAMALAR KECDI'
