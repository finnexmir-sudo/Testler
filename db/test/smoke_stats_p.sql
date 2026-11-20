-- =====================================================================
--  smoke_stats_p.sql : «Daha çətin / asan» real cetinliye gore + admin etiket siyahisi (db/938)
--
--  Hovuz (oz bank, bir movzu), statistika question_stats-a birbasa yazilir:
--    E1: etiket 3, n 30, p 95  -> 95      E2: etiket 1, n 30, p 10 -> 10
--    E3: etiket 3, n 10, p 5   -> 20 (n < 30 - etiket)
--    E4: etiket 2, stat yox    -> 57.5    E5: etiket 1, stat yox  -> 87.5
--  Iddialar:
--   1 · «Daha çətin»·2 -> E2 + E3 (real p 10, etiket 3); E1 (etiket 3, p 95) DUSMUR
--   2 · «Daha asan»·2  -> E1 + E5 (real p 95, etiket 1)
--   3 · «Qarışıq» ve kohne 'difficulty' filtri statistikadan asili deyil
--   4 · admin: platforma suallarinda etiket ≠ p zolagi siyahisi; 'cetin-namized' AYRICA,
--       n < 30 namizedler «gozleyir» sayilir; admin olmayan acamir
--   5 · rpc_qstat_tick: 20 saatdan tezdirse hesablamir; kohnedirse yenileyir
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;
set search_path = public, extensions;

delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments;     delete from public.student_sessions;
delete from public.test_questions where test_id in
  (select id from public.tests where owner_type = 'educator');
delete from public.question_options o using public.questions q
 where o.question_id = q.id and q.owner_type = 'educator';
delete from public.questions where owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.questions where ext_key like 'smkstp-%';
delete from public.students; delete from public.classes;
delete from public.subscriptions; delete from public.account_members;
delete from public.accounts; delete from public.user_roles;
delete from public.profiles; delete from auth.users;

insert into auth.users (id, email) values
  ('11110000-0000-0000-0000-0000000009d1','statp@t.az'),
  ('11110000-0000-0000-0000-0000000009d2','statp-admin@t.az');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000009d1','tutor','StatP','11110000-0000-0000-0000-0000000009d1');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000009d1','11110000-0000-0000-0000-0000000009d1',true);
insert into public.user_roles (user_id, role) values ('11110000-0000-0000-0000-0000000009d2','admin');

do $$
declare v_s uuid; v_l uuid; v_t uuid; r record;
begin
  select id into v_s from public.subjects where slug = 'riyaziyyat';
  select l.id into v_l from public.levels l join public.programs p on p.id = l.program_id where p.slug = 'ibtidai' and l.code = '3';
  select id into v_t from public.topics where slug = 'riy-3-toplama' and subject_id = v_s;
  perform set_config('smoke.t', v_t::text, false);
  for r in select * from (values
      ('E1', 3, 30, 95.0), ('E2', 1, 30, 10.0), ('E3', 3, 10, 5.0), ('E4', 2, null, null), ('E5', 1, null, null)) x(k, d, n, p)
  loop
    insert into public.questions (owner_type, owner_id, account_id, subject_id, level_id, topic_id, kind, body, difficulty, status, ext_key)
    values ('educator','11110000-0000-0000-0000-0000000009d1','aaaa0000-0000-0000-0000-0000000009d1', v_s, v_l, v_t, 'single',
            format('%s: sebetde %s alma var, bir-bir sayilsa necedir (%s)', r.k, length(r.k) * 13, md5(r.k)), r.d, 'published', 'smkstp-' || r.k);
    insert into public.question_options (question_id, ord, body, is_correct)
    select q.id, o.ord, o.b || ' ' || r.k, o.ok from public.questions q,
           (values (1, 'duz', true), (2, 'yanlis', false)) o(ord, b, ok) where q.ext_key = 'smkstp-' || r.k;
    if r.n is not null then
      insert into public.question_stats (question_id, n, p, computed_at)
      select q.id, r.n, r.p, now() from public.questions q where q.ext_key = 'smkstp-' || r.k;
    end if;
  end loop;
  --  admin siyahisi ucun PLATFORMA suallari (n >= 30):
  --    P1 etiket 3, p 82 -> uygun deyil (teklif 1) · P2 etiket 2, p 60 -> uygun · P3 etiket 1, p 30 -> uygun deyil (teklif 3)
  --    N1 'cetin-namized' etiket 3, p 35 -> namized, teklif 3 · N2 namized p 70 -> teklif 2 · N3 namized n 12 -> gozleyir
  for r in select * from (values
      ('P1', 3, 40, 82.0, false), ('P2', 2, 50, 60.0, false), ('P3', 1, 31, 30.0, false),
      ('N1', 3, 33, 35.0, true),  ('N2', 3, 45, 70.0, true),  ('N3', 3, 12, 20.0, true)) x(k, d, n, p, nam)
  loop
    insert into public.questions (owner_type, subject_id, level_id, topic_id, kind, body, difficulty, status, ext_key, tags)
    values ('platform', v_s, v_l, v_t, 'single', format('Platforma %s: %s', r.k, md5('p' || r.k)), r.d, 'published', 'smkstp-' || r.k,
            case when r.nam then array['cetin-namized'] else '{}'::text[] end);
    insert into public.question_stats (question_id, n, p, computed_at)
    select q.id, r.n, r.p, now() from public.questions q where q.ext_key = 'smkstp-' || r.k;
  end loop;
end $$;

create or replace function pg_temp.keys(p_test uuid) returns text language sql security definer as $$
  select string_agg(replace(q.ext_key, 'smkstp-', ''), ',' order by q.ext_key)
    from public.test_questions tq join public.questions q on q.id = tq.question_id where tq.test_id = p_test $$;
create or replace function pg_temp.rule(p_mode text, p_count int, p_extra jsonb default '{}') returns jsonb language sql as $$
  select jsonb_build_object('pool', 'mine', 'subject', 'riyaziyyat', 'level', '3',
           'topics', jsonb_build_array(current_setting('smoke.t')), 'count', p_count)
         || case when p_mode is null then '{}'::jsonb else jsonb_build_object('level_mode', p_mode) end || p_extra $$;

\echo '--- hazirliq tamam'
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000009d1';
do $$
declare v jsonb; i int;
begin
  --  1-2: tesaduf yoxdur (zolaq qiymetleri ferqlidir) - bir nece defe eyni netice
  for i in 1..3 loop
    v := public.rpc_generate_test(pg_temp.rule('harder', 2), 'harder');
    assert pg_temp.keys((v->>'test_id')::uuid) = 'E2,E3', '1 «Daha çətin»: ' || pg_temp.keys((v->>'test_id')::uuid);
    v := public.rpc_generate_test(pg_temp.rule('easier', 2), 'easier');
    assert pg_temp.keys((v->>'test_id')::uuid) = 'E1,E5', '2 «Daha asan»: ' || pg_temp.keys((v->>'test_id')::uuid);
  end loop;
  --  3: kohne filtr etiketle isleyir (statistika filtrde nezere alinmir)
  v := public.rpc_generate_test(pg_temp.rule(null, 2, '{"difficulty":["3"]}'::jsonb), 'filtr 3');
  assert pg_temp.keys((v->>'test_id')::uuid) = 'E1,E3', '3 filtr: ' || pg_temp.keys((v->>'test_id')::uuid);
  v := public.rpc_generate_test(pg_temp.rule(null, 5), 'qarisiq');
  assert (v->>'count')::int = 5, '3 qarisiq';
end $$;
\echo 'OK  1 · «Daha çətin»: real p 10 (etiket 1) ve etiket 3 (n < 30) evvel; etiket 3, p 95 dusmur'
\echo 'OK  2 · «Daha asan»: real p 95 (etiket 3) ve etiket 1 evvel'
\echo 'OK  3 · «Qarışıq» ve kohne difficulty filtri deyismir'

--  4. admin
do $$
declare ok boolean := false;
begin
  begin perform public.rpc_admin_qlabels(); exception when insufficient_privilege then ok := true; end;
  assert ok, 'adi muellim admin siyahisini acdi';
end $$;
reset role; reset request.jwt.claim.sub;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000009d2';
do $$
declare v jsonb; mm text; nn text;
begin
  v := public.rpc_admin_qlabels();
  select string_agg(replace(x->>'ext_key', 'smkstp-', '') || ':' || (x->>'difficulty') || '>' || (x->>'band'), ',' order by x->>'ext_key')
    into mm from jsonb_array_elements(v->'mismatch') x where x->>'ext_key' like 'smkstp-%';
  assert mm = 'P1:3>1,P3:1>3', '4 uygunsuz: ' || coalesce(mm, 'bos');
  select string_agg(replace(x->>'ext_key', 'smkstp-', '') || ':' || (x->>'band'), ',' order by x->>'ext_key')
    into nn from jsonb_array_elements(v->'namized') x where x->>'ext_key' like 'smkstp-%';
  assert nn = 'N1:3,N2:2', '4 namized: ' || coalesce(nn, 'bos');
  assert (v->>'namized_wait')::int >= 1, '4 gozleyen namized';
  assert not exists (select 1 from jsonb_array_elements(v->'mismatch') x where x->>'ext_key' like 'smkstp-E%'), 'oz (muellim) suali siyahida';
end $$;
reset role; reset request.jwt.claim.sub;
\echo 'OK  4 · admin: etiket ≠ p (P1 3→1, P3 1→3), namizedler ayrica (N1 → 3, N2 → 2), n < 30 gozleyir; muellim acamir'

--  5. rpc_qstat_tick
do $$
declare v jsonb;
begin
  update public.question_stats set computed_at = now();
  set local role anon;
  v := public.rpc_qstat_tick();
  reset role;
  assert not (v->>'refreshed')::boolean, '5: teze statistika yeniden hesablandi';
  update public.question_stats set computed_at = now() - interval '25 hours';
  set local role anon;
  v := public.rpc_qstat_tick();
  reset role;
  assert (v->>'refreshed')::boolean, '5: kohne statistika yenilenmedi: ' || v::text;
  assert (select max(computed_at) from public.question_stats) > now() - interval '1 minute'
      or not exists (select 1 from public.question_stats), '5: computed_at teze deyil';
end $$;
\echo 'OK  5 · rpc_qstat_tick: 20 saatdan tez - yox, kohne - yenileyir (anon cagira bilir)'

delete from public.test_questions where test_id in (select id from public.tests where owner_type = 'educator');
delete from public.tests where owner_type = 'educator';
delete from public.question_options o using public.questions q where q.id = o.question_id and q.ext_key like 'smkstp-%';
delete from public.questions where ext_key like 'smkstp-%';
\echo 'STATS P: HAMISI KECDI'
