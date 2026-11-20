-- =====================================================================
--  smoke_test_seviyyesi.sql : «Qarışıq / Daha asan / Daha çətin» (db/937)
--
--  Hovuz (oz bank, 3-cu sinif riyaziyyat):
--    A: 6 asan + 10 orta + 2 cetin     B: 12 cetin + 1 «tekrar» cetin     C: 9 orta
--  Iddialar:
--   1 · «Daha çətin» A·8  -> 2 cetin + 6 orta (yuxaridan), 'mix' duz
--   2 · «Daha çətin» A·16 -> 2 + 10 + 4 asan: test YIGILIR (filtr deyil)
--   3 · «Daha asan»  A·8  -> 6 asan + 2 orta
--   4 · «Qarışıq» (level_mode yoxdur) -> test yigilir, 'mix' cemi = say
--   5 · hovuz catmir (A·19) -> evvelki xeta
--   6 · iki movzu A + C, «Daha çətin»·8 -> 4 + 4 (balans qalir), A-nin 2 cetini daxil
--   7 · eyni seviyye daxilinde qaydalar: verilmis (exclude) arxaya; tekrar suzgeci (>= 0.95)
--   8 · kohne 'difficulty' filtri daxili cagirislar ucun isleyir; «Yenidən yığ» rejimi saxlayir
--   9 · preview 'mix' = test 'mix' («Daha çətin»de deterministik)
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
  ('11110000-0000-0000-0000-0000000009c1','seviyye@t.az');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000009c1','tutor','Seviyye','11110000-0000-0000-0000-0000000009c1');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000009c1','11110000-0000-0000-0000-0000000009c1',true);

do $$
declare
  v_s uuid; v_l uuid; v_t uuid; j int; i int; k int := 0; v_body text; d int;
  tp  text[] := array['riy-3-vurma-bolme','riy-3-toplama','riy-3-vurma-bolme-2'];
  plan int[][] := array[[6, 10, 2], [0, 0, 12], [0, 9, 0]];      -- [asan, orta, cetin]
  soz text[] := array['alma','armud','heyva','nar','gilas','alca','erik','qoz','findiq','badam',
                      'uzum','qarpiz','yemis','limon','portagal','banan'];
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
  --  B: birinci cetin sualin TEKRARI (bir herf ferqli, oxsarliq >= 0.95)
  select body into v_body from public.questions
   where topic_id = current_setting('smoke.t2')::uuid and owner_type = 'educator' order by body limit 1;
  assert extensions.similarity(v_body, v_body || ' x') >= 0.95, 'tekrar sual oxsar deyil - 7b bos kecerdi';
  insert into public.questions
    (owner_type, owner_id, account_id, subject_id, level_id, topic_id, kind, body, difficulty, status)
  values ('educator','11110000-0000-0000-0000-0000000009c1','aaaa0000-0000-0000-0000-0000000009c1',
          v_s, v_l, current_setting('smoke.t2')::uuid, 'single', v_body || ' x', 3, 'published');
  insert into public.question_options (question_id, ord, body, is_correct)
  select q.id, o.ord, o.b, o.ok from public.questions q,
         (values (1, 'tekrar cavab', true), (2, 'tekrar yanlis', false)) o(ord, b, ok)
   where q.body = v_body || ' x';
end $$;

create or replace function pg_temp.rule(p_topics int[], p_mode text, p_count int, p_extra jsonb default '{}') returns jsonb language sql as $$
  select jsonb_build_object('pool', 'mine', 'subject', 'riyaziyyat', 'level', '3',
           'topics', (select jsonb_agg(current_setting('smoke.t' || x)) from unnest(p_topics) x),
           'count', p_count)
         || case when p_mode is null then '{}'::jsonb else jsonb_build_object('level_mode', p_mode) end
         || p_extra $$;
create or replace function pg_temp.diffs(p_test uuid) returns int[] language sql security definer as $$
  select array_agg(q.difficulty::int order by q.difficulty)
    from public.test_questions tq join public.questions q on q.id = tq.question_id where tq.test_id = p_test $$;
create or replace function pg_temp.per_topic(p_test uuid, p_t int) returns int language sql security definer as $$
  select count(*)::int from public.test_questions tq join public.questions q on q.id = tq.question_id
   where tq.test_id = p_test and q.topic_id = current_setting('smoke.t' || p_t)::uuid $$;
create or replace function pg_temp.dupcount(p_test uuid) returns int language sql security definer
  set search_path = public, extensions as $$
  select count(*)::int from public.test_questions a join public.questions qa on qa.id = a.question_id
    join public.test_questions b on b.test_id = a.test_id and b.question_id > a.question_id
    join public.questions qb on qb.id = b.question_id
   where a.test_id = p_test and similarity(qa.body, qb.body) >= 0.95 $$;
create or replace function pg_temp.mixstr(v jsonb) returns text language sql as $$
  select (v->'mix'->>'hard') || '/' || (v->'mix'->>'mid') || '/' || (v->'mix'->>'easy') $$;

\echo '--- hazirliq tamam'
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000009c1';

do $$
declare v jsonb; p jsonb; tid uuid; dup int;
begin
  --  1. Daha cetin A·8
  v := public.rpc_generate_test(pg_temp.rule(array[1], 'harder', 8), 'A daha cetin');
  tid := (v->>'test_id')::uuid;
  assert pg_temp.diffs(tid) = array[2,2,2,2,2,2,3,3], '1: ' || pg_temp.diffs(tid)::text;
  assert pg_temp.mixstr(v) = '2/6/0', '1 mix: ' || pg_temp.mixstr(v);
  perform set_config('smoke.tA', tid::text, false);
  raise notice 'OK  1 · «Daha çətin» A·8: 2 cetin + 6 orta, mix 2/6/0';

  --  2. Daha cetin A·16 - asanla tamamlanir, test yigilir
  v := public.rpc_generate_test(pg_temp.rule(array[1], 'harder', 16), 'A 16');
  assert pg_temp.mixstr(v) = '2/10/4', '2 mix: ' || pg_temp.mixstr(v);
  raise notice 'OK  2 · «Daha çətin» A·16: 2 + 10 + 4 asan, test yigilir';

  --  3. Daha asan A·8
  v := public.rpc_generate_test(pg_temp.rule(array[1], 'easier', 8), 'A asan');
  assert pg_temp.diffs((v->>'test_id')::uuid) = array[1,1,1,1,1,1,2,2], '3: ' || pg_temp.diffs((v->>'test_id')::uuid)::text;
  raise notice 'OK  3 · «Daha asan» A·8: 6 asan + 2 orta';

  --  4. Qarisiq (rejim yoxdur)
  v := public.rpc_generate_test(pg_temp.rule(array[1], null, 8), 'A qarisiq');
  assert (v->>'count')::int = 8
     and (v->'mix'->>'hard')::int + (v->'mix'->>'mid')::int + (v->'mix'->>'easy')::int = 8, '4: ' || v::text;
  raise notice 'OK  4 · «Qarışıq»: test yigilir, mix cemi 8';
end $$;
\echo 'OK  1-4 · rejimler (yuxaridaki NOTICE-ler)'

do $$
declare yox boolean := false; v jsonb; tid uuid;
begin
  --  5. hovuz catmir
  begin perform public.rpc_generate_test(pg_temp.rule(array[1], 'harder', 19), 'A 19'); exception when others then yox := true; end;
  assert yox, '5: 19 sual yigildi (hovuz 18)';
  --  6. iki movzu, balans
  v := public.rpc_generate_test(pg_temp.rule(array[1, 3], 'harder', 8), 'A+C');
  tid := (v->>'test_id')::uuid;
  assert pg_temp.per_topic(tid, 1) = 4 and pg_temp.per_topic(tid, 3) = 4, '6 balans: ' || pg_temp.per_topic(tid, 1) || '/' || pg_temp.per_topic(tid, 3);
  assert pg_temp.mixstr(v) = '2/6/0', '6 mix (A-nin 2 cetini + 2 orta, C-den 4 orta): ' || pg_temp.mixstr(v);
end $$;
\echo 'OK  5 · hovuz catmayanda evvelki xeta'
\echo 'OK  6 · iki movzuda balans qalir (4 + 4), A-nin cetinleri daxil'

do $$
declare v jsonb; tid uuid; h1 uuid; h2 uuid; dup int;
begin
  --  7a. verilmis (exclude) eyni seviyyede arxaya: A-nin 2 cetininden biri verilib, A·1 -> o biri
  select q.id into h1 from public.questions q
   where q.topic_id = current_setting('smoke.t1')::uuid and q.difficulty = 3 order by q.body limit 1;
  v := public.rpc_generate_test(pg_temp.rule(array[1], 'harder', 1, jsonb_build_object('exclude', jsonb_build_array(h1))), 'A exclude');
  select tq.question_id into h2 from public.test_questions tq where tq.test_id = (v->>'test_id')::uuid;
  assert h2 <> h1 and (select difficulty from public.questions where id = h2) = 3, '7a: verilmis sual one kecdi';
  --  7b. tekrar suzgeci: B-de 13 cetin, biri tekrardir -> «Daha çətin» B·12: tekrar cut dusmur
  v := public.rpc_generate_test(pg_temp.rule(array[2], 'harder', 12), 'B 12');
  dup := pg_temp.dupcount((v->>'test_id')::uuid);
  --  hovuzda tekrar cut hequiqeten var (yoxsa yoxlama bos kecer)
  assert (select count(*) from public.questions a join public.questions b on b.body = a.body || ' x'
           where a.topic_id = current_setting('smoke.t2')::uuid and a.owner_type = 'educator') = 1, '7b: tekrar cut hovuzda yoxdur';
  assert dup = 0 and (v->>'count')::int = 12, '7b: tekrar cut testde: ' || dup;
end $$;
\echo 'OK  7 · eyni seviyyede: verilmis arxaya, tekrar suzgeci (>= 0.95) isleyir'

do $$
declare v jsonb; p jsonb;
begin
  --  8. kohne difficulty filtri ve «Yenidən yığ»
  v := public.rpc_generate_test(pg_temp.rule(array[1], null, 6, '{"difficulty":["1"]}'::jsonb), 'kohne filtr');
  assert pg_temp.diffs((v->>'test_id')::uuid) = array[1,1,1,1,1,1], '8 filtr: ' || pg_temp.diffs((v->>'test_id')::uuid)::text;
  v := public.rpc_regenerate_test(current_setting('smoke.tA')::uuid);
  assert pg_temp.diffs(current_setting('smoke.tA')::uuid) = array[2,2,2,2,2,2,3,3] and pg_temp.mixstr(v) = '2/6/0', '8 regenerate: ' || v::text;
  --  9. preview mix = test mix
  p := public.rpc_generate_preview(pg_temp.rule(array[1], 'harder', 8));
  assert (p->>'enough')::boolean and pg_temp.mixstr(p) = '2/6/0', '9 preview: ' || p::text;
  p := public.rpc_generate_preview(pg_temp.rule(array[1], 'easier', 8));
  assert pg_temp.mixstr(p) = '0/2/6', '9 preview asan: ' || p::text;
end $$;
\echo 'OK  8 · kohne difficulty filtri isleyir; «Yenidən yığ» rejimi saxlayir'
\echo 'OK  9 · preview mix = test mix'
reset role; reset request.jwt.claim.sub;
\echo 'TEST SEVIYYESI: HAMISI KECDI'
