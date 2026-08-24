-- =====================================================================
--  smoke_generator.sql : agilli test generatoru
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
  ('11110000-0000-0000-0000-00000000009a','g@g.az');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-00000000009a','tutor','G','11110000-0000-0000-0000-00000000009a');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-00000000009a','11110000-0000-0000-0000-00000000009a',true);

--  Muellimin oz bankı: 3 movzu x 8 sual, cavablari ferqli
do $$
declare v_s uuid; v_l uuid; v_t uuid; i int; k int := 0; tp text;
begin
  select id into v_s from public.subjects where slug='riyaziyyat';
  select l.id into v_l from public.levels l join public.programs p on p.id=l.program_id
   where p.slug='ibtidai' and l.code='3';
  foreach tp in array array['vurma-cedveli','toplama-cixma','bolme'] loop
    select id into v_t from public.topics where slug = tp and subject_id = v_s;
    for i in 1..8 loop
      k := k + 1;
      insert into public.questions
        (owner_type, owner_id, account_id, subject_id, level_id, topic_id,
         kind, body, difficulty, quarter, status)
      values ('educator','11110000-0000-0000-0000-00000000009a',
              'aaaa0000-0000-0000-0000-00000000009a', v_s, v_l, v_t,
              'single', tp || ' sualı nomre ' || i, (i % 3) + 1, 1, 'published');
      insert into public.question_options (question_id, ord, body, is_correct)
      select q.id, 1, 'cavab ' || k, true from public.questions q
       where q.body = tp || ' sualı nomre ' || i;
      insert into public.question_options (question_id, ord, body, is_correct)
      select q.id, 2, 'yanlis ' || k, false from public.questions q
       where q.body = tp || ' sualı nomre ' || i;
    end loop;
  end loop;
end $$;

\echo '--- hazirliq tamam: 24 sual, 3 movzu'

set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-00000000009a';

-- =====================================================================
--  1. Oz suallarindan test yigilir (abunesiz)
-- =====================================================================
do $$
declare v jsonb; n int;
begin
  v := public.rpc_generate_test(
        '{"pool":"mine","subject":"riyaziyyat","level":"3","count":9}'::jsonb,
        'Sinaq 1');
  assert (v->>'count')::int = 9, format('sual sayi: %s', v->>'count');
  select count(*) into n from public.test_questions
   where test_id = (v->>'test_id')::uuid;
  assert n = 9, format('terkibde %s sual', n);
  assert (select gen_rule is not null from public.tests where id=(v->>'test_id')::uuid),
         'qayda saxlanilmadi';
end $$;
\echo 'OK  1 · oz suallarindan test yigilir (abune telebi yoxdur)'

-- =====================================================================
--  2. Movzular BERABER bolunur
-- =====================================================================
do $$
declare v jsonb; mx int; mn int;
begin
  v := public.rpc_generate_test(
        '{"pool":"mine","subject":"riyaziyyat","count":9}'::jsonb, 'Balans');
  select max(c), min(c) into mx, mn from (
    select count(*) c from public.test_questions tq
      join public.questions q on q.id = tq.question_id
     where tq.test_id = (v->>'test_id')::uuid
     group by q.topic_id) z;
  assert mx - mn <= 1,
    format('movzu bolgusu balansli deyil: en cox %s, en az %s', mx, mn);
end $$;
\echo 'OK  2 · suallar movzular arasinda beraber bolunur'

-- =====================================================================
--  3. Suzgecler generatorda da isleyir
-- =====================================================================
do $$
declare v jsonb; tp uuid; n int;
begin
  select id into tp from public.topics where slug='bolme';
  v := public.rpc_generate_test(
        format('{"pool":"mine","topics":["%s"],"count":5}', tp)::jsonb, 'Tek movzu');
  select count(*) into n from public.test_questions tq
    join public.questions q on q.id = tq.question_id
   where tq.test_id = (v->>'test_id')::uuid and q.topic_id = tp;
  assert n = 5, format('movzu suzgeci: %s/5', n);

  v := public.rpc_generate_test(
        '{"pool":"mine","difficulty":[1],"count":3}'::jsonb, 'Asan');
  select count(*) into n from public.test_questions tq
    join public.questions q on q.id = tq.question_id
   where tq.test_id = (v->>'test_id')::uuid and q.difficulty = 1;
  assert n = 3, format('cetinlik suzgeci: %s/3', n);
end $$;
\echo 'OK  3 · movzu ve cetinlik suzgecleri generatorda isleyir'

-- =====================================================================
--  4. Sual CATMAYANDA acıq xeta - yarimciq test YARANMIR
-- =====================================================================
do $$
declare ok boolean := false; n_before int; n_after int;
begin
  select count(*) into n_before from public.tests where owner_type='educator';
  begin
    perform public.rpc_generate_test('{"pool":"mine","count":99}'::jsonb, 'Cox');
    assert false, 'catmayan sualla test yarandi';
  exception when others then
    ok := position('ferqli sual tapildi' in sqlerrm) > 0;
  end;
  assert ok, 'acıq xeta mesajı gelmedi';
  select count(*) into n_after from public.tests where owner_type='educator';
  assert n_before = n_after, 'yarimciq test bazada qaldi';
end $$;
\echo 'OK  4 · sual catmayanda acıq xeta, yarimciq test qalmir'

-- =====================================================================
--  5. Onizleme: neçe sual var, kifayetdirmi
-- =====================================================================
do $$
declare v jsonb;
begin
  v := public.rpc_generate_preview('{"pool":"mine","count":5}'::jsonb);
  assert (v->>'enough')::boolean, 'kifayet etmeli idi';
  assert (v->>'found')::int = 5, format('tapilan: %s', v->>'found');
  assert not (v->>'paid')::boolean, 'abunesiz hesab odenisli gorunur';

  v := public.rpc_generate_preview('{"pool":"mine","count":99}'::jsonb);
  assert not (v->>'enough')::boolean, 'catmadigi bildirilmedi';
  assert (v->>'found')::int = 24, format('hovuz: %s', v->>'found');
end $$;
\echo 'OK  5 · onizleme hovuzun heqiqi sayini verir'

-- =====================================================================
--  6. Platforma hovuzu ABUNE telebidir
-- =====================================================================
do $$
declare ok boolean := false; v jsonb;
begin
  begin
    perform public.rpc_generate_test('{"pool":"platform","count":3}'::jsonb, 'P');
    assert false, 'abunesiz platforma hovuzu acildi';
  exception when insufficient_privilege then ok := true; end;
  assert ok, 'abune yoxlanisi islemedi';

  -- onizleme abunesiz OZ hovuzuna dusur, xeta vermir
  v := public.rpc_generate_preview('{"pool":"all","count":5}'::jsonb);
  assert (v->>'found')::int <= 24, 'abunesiz platforma suallari sizdi';
end $$;
\echo 'OK  6 · platforma hovuzu abune telebidir, oz hovuzun acıq'

-- =====================================================================
--  7. Abune ile platforma hovuzu acilir
-- =====================================================================
reset role; reset request.jwt.claim.sub;
insert into public.subscriptions (account_id, plan_id, status, started_at, current_period_end)
select 'aaaa0000-0000-0000-0000-00000000009a', p.id, 'active', now(), now() + interval '30 days'
  from public.plans p where p.slug = 'repetitor-25';
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-00000000009a';
do $$
declare v jsonb;
begin
  v := public.rpc_generate_preview('{"pool":"platform","count":5}'::jsonb);
  assert (v->>'paid')::boolean, 'abune gorunmur';
  assert (v->>'found')::int = 5, format('platforma hovuzu: %s', v->>'found');
  v := public.rpc_generate_test('{"pool":"platform","count":5}'::jsonb, 'Platforma');
  assert (v->>'count')::int = 5, 'platforma testi yigilmadi';
end $$;
\echo 'OK  7 · abune ile platforma hovuzu acilir'

-- =====================================================================
--  8. TEKRAR SUAL: herfi eyni sual banka IKI DEFE dusmur
-- =====================================================================
do $$
declare ok boolean := false; v jsonb;
begin
  perform public.rpc_bank_save_question(null,'riyaziyyat','Tekrar sualı budur',
    '[{"body":"1","correct":true},{"body":"2"}]'::jsonb);
  begin
    -- eyni sual, basqa yazilis: boşluq, boyuk herf, son sual isaresi
    perform public.rpc_bank_save_question(null,'riyaziyyat','  TEKRAR   Sualı budur? ',
      '[{"body":"1","correct":true},{"body":"2"}]'::jsonb);
    assert false, 'herfi tekrar sual banka dusdu';
  exception when unique_violation then ok := true; end;
  assert ok, 'tekrar yoxlanisi islemedi';
end $$;
\echo 'OK  8 · herfi tekrar sual banka iki defe dusmur'

-- =====================================================================
--  9. OXSAR sual xeberdarliq verir, BLOKLAMIR
-- =====================================================================
do $$
declare v jsonb;
begin
  -- yerdeyismis tekrar: "6 x 7" ~ "7 x 6" = 1.00
  perform public.rpc_bank_save_question(null,'riyaziyyat','6 x 7 nece eder?',
    '[{"body":"42","correct":true},{"body":"36"}]'::jsonb);
  v := public.rpc_bank_similar('7 x 6 nece eder?');
  assert jsonb_array_length(v) >= 1, 'yerdeyismis tekrar tapilmadi';
  assert (v->0->>'score')::numeric >= 0.95, format('bal: %s', v->0->>'score');

  -- FERQLI sual: "6 x 8" ~ 0.75 - bu tutulmamalidir
  v := public.rpc_bank_similar('6 x 8 nece eder?');
  assert jsonb_array_length(v) = 0,
    format('ferqli sual yanlisliqla tekrar sayildi: %s', v::text);

  -- xeberdarliq BLOKLAMIR: sual yene de yazilir
  perform public.rpc_bank_save_question(null,'riyaziyyat','7 x 6 nece eder?',
    '[{"body":"42","correct":true},{"body":"36"}]'::jsonb);
end $$;
\echo 'OK  9 · oxsar sual xeberdarliq verir, ferqli suala toxunmur'

-- =====================================================================
-- 10. Generator yerdeyismis tekrari EYNI kagiza qoymur
-- =====================================================================
do $$
declare v jsonb; n int;
begin
  -- bankda hem "6 x 7", hem "7 x 6" var; ikisi de eyni kagiza dusmemelidir
  v := public.rpc_generate_test(
        '{"pool":"mine","subject":"riyaziyyat","count":20}'::jsonb, 'Tekrarsiz');
  select count(*) into n from public.test_questions tq
    join public.questions q on q.id = tq.question_id
   where tq.test_id = (v->>'test_id')::uuid
     and q.body in ('6 x 7 nece eder?','7 x 6 nece eder?');
  assert n <= 1, format('yerdeyismis tekrarin ikisi de kagizdadir (%s)', n);
end $$;
\echo 'OK 10 · generator yerdeyismis tekrari bir kagiza qoymur'

-- =====================================================================
-- 11. Eyni CAVAB hedden cox tekrarlanmir
-- =====================================================================
reset role; reset request.jwt.claim.sub;
do $$
declare v_s uuid; i int;
begin
  select id into v_s from public.subjects where slug='riyaziyyat';
  -- 10 ferqli sual, hamisinin cavabi eynidir
  for i in 1..10 loop
    insert into public.questions
      (owner_type, owner_id, account_id, subject_id, kind, body, status)
    values ('educator','11110000-0000-0000-0000-00000000009a',
            'aaaa0000-0000-0000-0000-00000000009a', v_s, 'single',
            'eyni cavabli sual ' || i, 'published');
    insert into public.question_options (question_id, ord, body, is_correct)
    select q.id, 1, 'HAMISI EYNI', true from public.questions q
     where q.body = 'eyni cavabli sual ' || i;
    insert into public.question_options (question_id, ord, body, is_correct)
    select q.id, 2, 'yanlis', false from public.questions q
     where q.body = 'eyni cavabli sual ' || i;
  end loop;
end $$;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-00000000009a';
do $$
declare v jsonb; n int;
begin
  v := public.rpc_generate_test('{"pool":"mine","count":14}'::jsonb, 'Cavab balansi');
  select count(*) into n from public.test_questions tq
    join public.question_options o on o.question_id = tq.question_id and o.is_correct
   where tq.test_id = (v->>'test_id')::uuid and lower(o.body) = 'hamisi eyni';
  assert n <= 3, format('eyni cavab %s defe tekrarlanib', n);
end $$;
\echo 'OK 11 · eyni duzgun cavab hedden cox tekrarlanmir'

-- =====================================================================
-- 12. YENILEMEK: islenmemis test yenilenir
-- =====================================================================
do $$
declare v jsonb; t uuid; a uuid[]; b uuid[];
begin
  v := public.rpc_generate_test('{"pool":"mine","count":8}'::jsonb, 'Yenilenen');
  t := (v->>'test_id')::uuid;
  select array_agg(question_id order by ord) into a
    from public.test_questions where test_id = t;

  v := public.rpc_regenerate_test(t);
  assert (v->>'regenerated')::boolean, 'yenilenme nisani yoxdur';
  assert (v->>'test_id')::uuid = t, 'yeni test yarandi - eynisi olmali idi';
  select array_agg(question_id order by ord) into b
    from public.test_questions where test_id = t;
  assert array_length(b,1) = 8, 'yenilenmeden sonra sual sayi deyisdi';
  assert (select count(*) from public.test_questions where test_id = t) = 8,
         'kohne terkib qalib';
end $$;
\echo 'OK 12 · islenmemis test eyni qayda ile yenilenir'

-- =====================================================================
-- 13. ISLENMIS test YENILENMIR - tarixce qorunur
-- =====================================================================
reset role; reset request.jwt.claim.sub;
do $$
declare t uuid; st uuid; cl uuid;
begin
  select id into t from public.tests where title = 'Yenilenen';
  insert into public.classes (id, account_id, teacher_id, kind, name, join_code)
  values ('cccc0000-0000-0000-0000-00000000009a','aaaa0000-0000-0000-0000-00000000009a',
          '11110000-0000-0000-0000-00000000009a','tutor_group','G','GENKOD11')
  returning id into cl;
  insert into public.students (id, account_id, class_id, created_by, full_name,
                               display_name, login_code)
  values ('5555000c-0000-0000-0000-00000000009a','aaaa0000-0000-0000-0000-00000000009a',
          cl,'11110000-0000-0000-0000-00000000009a','S G','S G.','GENSAG11')
  returning id into st;
  insert into public.attempts (student_id, test_id, class_id, status, percent,
                               score, max_score, finished_at)
  values (st, t, cl, 'submitted', 80, 8, 10, now());
end $$;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-00000000009a';
do $$
declare t uuid; ok boolean := false;
begin
  select id into t from public.tests where title = 'Yenilenen';
  begin
    perform public.rpc_regenerate_test(t);
    assert false, 'islenmis test yenilendi - tarixce oldu!';
  exception when insufficient_privilege then ok := true; end;
  assert ok, 'qoruma islemedi';
end $$;
\echo 'OK 13 · islenmis test yenilenmir'

-- =====================================================================
-- 14. Kagiza baxis: muellim cavablari gorur
-- =====================================================================
do $$
declare v jsonb; t uuid;
begin
  select id into t from public.tests where title = 'Sinaq 1';
  v := public.rpc_test_preview(t);
  assert jsonb_array_length(v->'questions') = 9, 'kagizda sual sayi sehv';
  assert v->'questions'->0->'options'->0 ? 'correct', 'muellim cavabi gormur';
  assert (v->>'done')::int = 0, 'isleyen sagird sayi sehv';
  assert v->>'gen_rule' is not null, 'qayda gorunmur';
end $$;
\echo 'OK 14 · muellim kagizi cavablarla gorur'

reset role; reset request.jwt.claim.sub;
\echo ''
\echo '=============================='
\echo ' GENERATOR: HAMISI KECDI'
\echo '=============================='
