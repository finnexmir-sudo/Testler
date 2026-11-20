-- =====================================================================
--  smoke_cetin_tamamla.sql : «Çətin» secilib, cetin sual azdir (db/937)
--
--  Iddialar:
--   1 · cetin yeterlidir      -> test yalniz 3-lerden, filled = 0 (davranis deyismir)
--   2 · cetin azdir (2 / 8)   -> 3-lerin HAMISI + 6 «orta», asan YOX, basqa movzu YOX, filled = 6;
--                                preview: enough = true, filled = 6
--   3 · cetin 0               -> test butunlukle «orta»dan, filled = count
--   4 · basqa secimler deyismir: «Asan» catmir -> xeta; «Orta + Çətin» catmir -> xeta
--   5 · 3 + 2 birlikde de catmir -> evvelki xeta (test yigilmir)
--   6 · «Yenidən yığ» (rpc_regenerate_test) eyni qaydani isledir
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
delete from public.students; delete from public.classes;
delete from public.subscriptions; delete from public.account_members;
delete from public.accounts; delete from public.user_roles;
delete from public.profiles; delete from auth.users;

insert into auth.users (id, email) values
  ('11110000-0000-0000-0000-0000000009c1','cetin@t.az');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000009c1','tutor','Cetin','11110000-0000-0000-0000-0000000009c1');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000009c1','11110000-0000-0000-0000-0000000009c1',true);

--  oz bank (pool mine - abune lazim deyil), 3-cu sinif riyaziyyat:
--    movzu A: 2 cetin + 10 orta + 6 asan ;  movzu B: 12 cetin ;  movzu C: 0 cetin + 9 orta
--  metnler bir-birine oxsamir (generator >= 0.95 oxsarligi tekrar sayir)
do $$
declare
  v_s uuid; v_l uuid; v_t uuid; j int; i int; k int := 0; v_body text;
  tp  text[] := array['riy-3-vurma-bolme','riy-3-toplama','riy-3-vurma-bolme-2'];
  plan int[][] := array[[6, 10, 2], [0, 0, 12], [0, 9, 0]];      -- [asan, orta, cetin]
  soz text[] := array['alma','armud','heyva','nar','gilas','alca','erik','qoz','findiq','badam',
                      'uzum','qarpiz','yemis','limon','portagal','banan'];
  d int;
begin
  select id into v_s from public.subjects where slug = 'riyaziyyat';
  select l.id into v_l from public.levels l join public.programs p on p.id = l.program_id
   where p.slug = 'ibtidai' and l.code = '3';
  for j in 1..3 loop
    select id into v_t from public.topics where slug = tp[j] and subject_id = v_s;
    assert v_t is not null, 'movzu tapilmadi: ' || tp[j];
    perform set_config('smoke.t' || j, v_t::text, false);
    for d in 1..3 loop
      for i in 1..plan[j][d] loop
        k := k + 1;
        v_body := format('%s sebetinde %s %s var, cetinlik %s, sira %s', tp[j], k * 7, soz[1 + (k % 16)], d, i);
        insert into public.questions
          (owner_type, owner_id, account_id, subject_id, level_id, topic_id, kind, body, difficulty, status)
        values ('educator','11110000-0000-0000-0000-0000000009c1','aaaa0000-0000-0000-0000-0000000009c1',
                v_s, v_l, v_t, 'single', v_body, d, 'published');
        insert into public.question_options (question_id, ord, body, is_correct)
        select q.id, o.ord, o.b, o.ok from public.questions q,
               (values (1, 'cavab ' || k, true), (2, 'yanlis ' || k, false)) o(ord, b, ok)
         where q.body = v_body;
      end loop;
    end loop;
  end loop;
end $$;

create or replace function pg_temp.rule(p_topic int, p_diff text, p_count int) returns jsonb language sql as $$
  select jsonb_build_object('pool', 'mine', 'subject', 'riyaziyyat', 'level', '3',
           'topics', jsonb_build_array(current_setting('smoke.t' || p_topic)),
           'difficulty', p_diff::jsonb, 'count', p_count) $$;
create or replace function pg_temp.diffs(p_test uuid) returns int[] language sql security definer as $$
  select array_agg(q.difficulty::int order by q.difficulty)
    from public.test_questions tq join public.questions q on q.id = tq.question_id where tq.test_id = p_test $$;
create or replace function pg_temp.topics(p_test uuid) returns int language sql security definer as $$
  select count(distinct q.topic_id)::int
    from public.test_questions tq join public.questions q on q.id = tq.question_id where tq.test_id = p_test $$;

\echo '--- hazirliq tamam'

set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000009c1';

--  1. cetin yeterlidir - davranis deyismir
do $$
declare v jsonb;
begin
  v := public.rpc_generate_test(pg_temp.rule(2, '["3"]', 8), 'B cetin');
  assert (v->>'count')::int = 8 and (v->>'filled')::int = 0, 'B: ' || v::text;
  assert pg_temp.diffs((v->>'test_id')::uuid) = array[3,3,3,3,3,3,3,3], 'B yalniz 3: ' || pg_temp.diffs((v->>'test_id')::uuid)::text;
end $$;
\echo 'OK  1 · cetin yeterlidir: yalniz 3-ler, filled = 0'

--  2. cetin azdir: 2 cetin + 6 orta
do $$
declare v jsonb; p jsonb;
begin
  p := public.rpc_generate_preview(pg_temp.rule(1, '["3"]', 8));
  assert (p->>'enough')::boolean and (p->>'found')::int = 8 and (p->>'filled')::int = 6, 'preview: ' || p::text;
  v := public.rpc_generate_test(pg_temp.rule(1, '["3"]', 8), 'A cetin');
  assert (v->>'count')::int = 8 and (v->>'filled')::int = 6, 'A: ' || v::text;
  assert pg_temp.diffs((v->>'test_id')::uuid) = array[2,2,2,2,2,2,3,3], 'A: 2 cetin + 6 orta, asan yox: ' || pg_temp.diffs((v->>'test_id')::uuid)::text;
  assert pg_temp.topics((v->>'test_id')::uuid) = 1, 'basqa movzudan sual dusdu';
  perform set_config('smoke.tA', v->>'test_id', false);
end $$;
\echo 'OK  2 · cetin azdir: 3-lerin hamisi + eyni movzunun «orta»lari, asan ve basqa movzu yoxdur; preview filled'

--  3. cetin 0 - butunlukle orta
do $$
declare v jsonb;
begin
  v := public.rpc_generate_test(pg_temp.rule(3, '["3"]', 5), 'C cetin');
  assert (v->>'count')::int = 5 and (v->>'filled')::int = 5, 'C: ' || v::text;
  assert pg_temp.diffs((v->>'test_id')::uuid) = array[2,2,2,2,2], 'C butunlukle orta';
end $$;
\echo 'OK  3 · cetin 0: test orta suallarla, filled = 5'

--  4-5. basqa secimler ve catmayan hal - evvelki xeta
do $$
declare yox int := 0; p jsonb;
begin
  begin perform public.rpc_generate_test(pg_temp.rule(1, '["1"]', 8), 'asan'); exception when others then yox := yox + 1; end;
  begin perform public.rpc_generate_test(pg_temp.rule(1, '["2","3"]', 13), 'orta+cetin'); exception when others then yox := yox + 1; end;
  begin perform public.rpc_generate_test(pg_temp.rule(1, '["3"]', 13), '3+2 de catmir'); exception when others then yox := yox + 1; end;
  assert yox = 3, 'xeta gozlenirdi, ' || (3 - yox) || ' hal test yigdi';
  p := public.rpc_generate_preview(pg_temp.rule(1, '["3"]', 13));
  assert not (p->>'enough')::boolean and (p->>'found')::int = 12, 'catmayan preview: ' || p::text;
  p := public.rpc_generate_preview(pg_temp.rule(1, '["1"]', 4));
  assert (p->>'enough')::boolean and (p->>'filled')::int = 0, '«Asan» toxunulmur: ' || p::text;
end $$;
\echo 'OK  4 · «Asan», «Orta + Çətin» deyismir; 3 + 2 de catmayanda evvelki xeta'

--  6. Yeniden yig - eyni qayda, eyni tamamlama
do $$
declare v jsonb;
begin
  v := public.rpc_regenerate_test(current_setting('smoke.tA')::uuid);
  assert (v->>'count')::int = 8 and (v->>'filled')::int = 6, 'regenerate: ' || v::text;
  assert pg_temp.diffs(current_setting('smoke.tA')::uuid) = array[2,2,2,2,2,2,3,3], 'regenerate terkibi';
end $$;
\echo 'OK  5 · «Yenidən yığ» eyni tamamlamanı isledir'
reset role; reset request.jwt.claim.sub;
\echo 'CETIN TAMAMLA: HAMISI KECDI'
