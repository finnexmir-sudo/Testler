-- =====================================================================
--  smoke_siqnal.sql : tehluke zonasi ve sehv cutlesdirme
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments;     delete from public.student_sessions;
delete from public.students;        delete from public.classes;
delete from public.subscriptions;
delete from public.test_questions tq using public.tests t
 where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.question_options o using public.questions q
 where q.id = o.question_id and q.owner_type = 'educator';
delete from public.questions where owner_type = 'educator';
delete from public.account_members; delete from public.accounts;
delete from public.user_roles;      delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email) values
  ('11110000-0000-0000-0000-0000000000c1','p@t.az'),   -- abuneli
  ('11110000-0000-0000-0000-0000000000c2','f@t.az');   -- pulsuz
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000c1','tutor','P','11110000-0000-0000-0000-0000000000c1'),
  ('aaaa0000-0000-0000-0000-0000000000c2','tutor','F','11110000-0000-0000-0000-0000000000c2');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000c1','11110000-0000-0000-0000-0000000000c1',true),
  ('aaaa0000-0000-0000-0000-0000000000c2','11110000-0000-0000-0000-0000000000c2',true);
insert into public.subscriptions (account_id, plan_id, status, started_at, current_period_end)
select 'aaaa0000-0000-0000-0000-0000000000c1', p.id, 'active', now(), now() + interval '30 days'
  from public.plans p where p.slug = 'repetitor-25';
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-0000000000c1','aaaa0000-0000-0000-0000-0000000000c1',
   '11110000-0000-0000-0000-0000000000c1','tutor_group','Siqnal qrupu','KODSIQ01'),
  ('cccc0000-0000-0000-0000-0000000000c2','aaaa0000-0000-0000-0000-0000000000c2',
   '11110000-0000-0000-0000-0000000000c2','tutor_group','Pulsuz qrup','KODSIQ02');
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code) values
  ('5555000c-0000-0000-0000-000000000001','aaaa0000-0000-0000-0000-0000000000c1',
   'cccc0000-0000-0000-0000-0000000000c1','11110000-0000-0000-0000-0000000000c1',
   'Saleh Quliyev','Saleh Q.','SALE0001'),
  ('5555000c-0000-0000-0000-000000000002','aaaa0000-0000-0000-0000-0000000000c1',
   'cccc0000-0000-0000-0000-0000000000c1','11110000-0000-0000-0000-0000000000c1',
   'Aysu Kazimova','Aysu K.','AYSU0002'),
  ('5555000c-0000-0000-0000-000000000003','aaaa0000-0000-0000-0000-0000000000c1',
   'cccc0000-0000-0000-0000-0000000000c1','11110000-0000-0000-0000-0000000000c1',
   'Nihad Bagirov','Nihad B.','NIHA0003'),
  ('5555000c-0000-0000-0000-000000000004','aaaa0000-0000-0000-0000-0000000000c2',
   'cccc0000-0000-0000-0000-0000000000c2','11110000-0000-0000-0000-0000000000c2',
   'Lale Ehmedova','Lale E.','LALE0004');

--  Cehd tarixcesi (platforma testi uzerinde):
--    Saleh: 88,85,82 sonra 60,55,50 -> gerileme (85 -> 55)
--    Aysu:  92,95,91                -> ulduz
--    Nihad: 40,45                   -> az melumat, SUSMALIDIR
do $$
declare v_t uuid; v_p numeric; i int := 0;
begin
  select id into v_t from public.tests where slug = 'riy-3-vurma-1';
  foreach v_p in array array[88,85,82,60,55,50] loop
    i := i + 1;
    insert into public.attempts (test_id, student_id, status, percent, finished_at)
    values (v_t, '5555000c-0000-0000-0000-000000000001', 'submitted', v_p,
            now() - interval '30 days' + (i || ' days')::interval);
  end loop;
  i := 0;
  foreach v_p in array array[92,95,91] loop
    i := i + 1;
    insert into public.attempts (test_id, student_id, status, percent, finished_at)
    values (v_t, '5555000c-0000-0000-0000-000000000002', 'submitted', v_p,
            now() - interval '20 days' + (i || ' days')::interval);
  end loop;
  i := 0;
  foreach v_p in array array[40,45] loop
    i := i + 1;
    insert into public.attempts (test_id, student_id, status, percent, finished_at)
    values (v_t, '5555000c-0000-0000-0000-000000000003', 'submitted', v_p,
            now() - interval '10 days' + (i || ' days')::interval);
  end loop;
end $$;

--  Salehin zeif movzusu: 6 cavab, 1 dogru (17% < 60%)
do $$
declare v_a uuid; v_tp uuid; i int;
begin
  select a.id into v_a from public.attempts a
   where a.student_id = '5555000c-0000-0000-0000-000000000001'
   order by a.finished_at desc limit 1;
  select t.id into v_tp from public.topics t
    join public.subjects s on s.id = t.subject_id
   where s.slug = 'riyaziyyat' and t.slug = 'riy-3-mesele';
  insert into public.attempt_answers
    (attempt_id, question_id, topic_id, is_correct, question_body)
  select v_a, q.id, v_tp, rn = 1, 'Salehin sehv etdiyi tapsiriq ' || rn
    from (select id, row_number() over (order by id) rn
            from public.questions
           where owner_type = 'platform'
           order by id limit 6) q(id, rn);
end $$;

\echo '--- hazirliq tamam'

-- =====================================================================
--  1. Pulsuz hesabda siqnal QAYTARILMIR (upsell)
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000c2';
do $$
declare v jsonb;
begin
  v := public.rpc_class_alerts('cccc0000-0000-0000-0000-0000000000c2');
  assert (v->>'paid')::boolean = false, 'pulsuz hesab paid=false olmali idi';
  assert v->'alerts' = 'null'::jsonb, 'pulsuz hesabda alerts null olmali idi';
end $$;
\echo 'OK  1 · pulsuz hesabda siqnal bagli (upsell)'

-- =====================================================================
--  2. Ozge qrupun siqnalina giris yoxdur
-- =====================================================================
do $$
declare ok boolean := false;
begin
  begin
    perform public.rpc_class_alerts('cccc0000-0000-0000-0000-0000000000c1');
  exception when insufficient_privilege then ok := true;
  end;
  assert ok, 'ozge qrupun siqnali acildi';
end $$;
\echo 'OK  2 · ozge qrupun siqnali oxunmur'

-- =====================================================================
--  3. Gerileyen sagird qirmizi siqnal alir, zeif movzu da yaninda
-- =====================================================================
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000c1';
do $$
declare v jsonb; a jsonb;
begin
  v := public.rpc_class_alerts('cccc0000-0000-0000-0000-0000000000c1');
  assert (v->>'paid')::boolean, 'abuneli hesab paid=true olmali idi';
  select x into a from jsonb_array_elements(v->'alerts') x
   where x->>'kind' = 'risk';
  assert a is not null, 'gerileyen sagird ucun risk siqnali yoxdur';
  assert a->>'name' = 'Saleh Quliyev', format('risk kimin uzerindedir: %s', a->>'name');
  assert (a->>'prev3')::numeric = 85 and (a->>'last3')::numeric = 55,
         format('faizler sehvdir: %s -> %s', a->>'prev3', a->>'last3');
  assert a->>'topic' is not null, 'zeif movzu siqnala baglanmayib';
end $$;
\echo 'OK  3 · gerileyen sagird: risk + zeif movzu yaninda'

-- =====================================================================
--  4. Sabit yuksek netice yasil siqnal alir
-- =====================================================================
do $$
declare v jsonb; a jsonb;
begin
  v := public.rpc_class_alerts('cccc0000-0000-0000-0000-0000000000c1');
  select x into a from jsonb_array_elements(v->'alerts') x
   where x->>'kind' = 'star';
  assert a is not null, 'ulduz siqnali yoxdur';
  assert a->>'name' = 'Aysu Kazimova', format('ulduz kimdir: %s', a->>'name');
end $$;
\echo 'OK  4 · sabit yuksek netice: yasil siqnal'

-- =====================================================================
--  5. Az melumatli sagird ucun siqnal YOXDUR - yalan siqnal olmasin
-- =====================================================================
do $$
declare v jsonb; n int;
begin
  v := public.rpc_class_alerts('cccc0000-0000-0000-0000-0000000000c1');
  select count(*) into n from jsonb_array_elements(v->'alerts') x
   where x->>'name' like 'Nihad%';
  assert n = 0, 'iki testle siqnal verildi - yalan siqnaldir';
  --  risk birinci gelir
  assert (v->'alerts'->0->>'kind') = 'risk', 'risk siyahida birinci deyil';
end $$;
\echo 'OK  5 · az melumatda susur; risk siyahida birincidir'

-- =====================================================================
--  6. Sehv cutlesdirme: qrupun sehvine QELIBCE benzeyen sual one kecir
-- =====================================================================
reset role; reset request.jwt.claim.sub;
do $$
declare
  v_s uuid; v_l uuid; v_t uuid; v_q uuid; i int;
  v_sim1 uuid; v_sim2 uuid;
  v_pick uuid[];
begin
  select id into v_s from public.subjects where slug='riyaziyyat';
  select l.id into v_l from public.levels l join public.programs p on p.id=l.program_id
   where p.slug='ibtidai' and l.code='4';
  select t.id into v_t from public.topics t
   where t.subject_id = v_s and t.slug = 'riy-4-vurma-bolme';

  --  4 oz suali: ikisi "N x M nece eder?" qelibinde, ikisi tam ferqli
  for i in 1..4 loop
    insert into public.questions
      (owner_type, owner_id, account_id, subject_id, level_id, topic_id,
       kind, body, difficulty, status)
    values ('educator','11110000-0000-0000-0000-0000000000c1',
            'aaaa0000-0000-0000-0000-0000000000c1', v_s, v_l, v_t, 'single',
            case i
              when 1 then '27 × 3 neçə edər?'
              when 2 then '41 × 6 neçə edər?'
              when 3 then 'Sinifdəki kitabların sayını hesablayıb yazın'
              else 'Bölmə əməlinin nəticəsini yoxlama qaydası hansıdır' end,
            2, 'published')
    returning id into v_q;
    if i = 1 then v_sim1 := v_q; end if;
    if i = 2 then v_sim2 := v_q; end if;
    insert into public.question_options (question_id, ord, body, is_correct)
    values (v_q, 1, 'cavab ' || i, true), (v_q, 2, 'yanlis ' || i, false);
  end loop;

  --  Qrupun sehv cavabi: eyni qelibli metn (suret sahesinde)
  --  question_id istenilen movcud sual ola biler - cutlesdirme
  --  SURETDEKI metnle isleyir (question_body), id ile yox
  insert into public.attempt_answers
    (attempt_id, question_id, topic_id, is_correct, question_body)
  select a.id, (select q.id from public.questions q
                 where q.owner_type = 'platform'
                 order by q.id desc limit 1),
         v_t, false, '35 × 4 neçə edər?'
    from public.attempts a
   where a.student_id = '5555000c-0000-0000-0000-000000000001'
   order by a.finished_at limit 1;

  --  count=2, yalniz bu movzu -> benzeyen iki sual secilmelidir
  v_pick := app.generate_pick(
    jsonb_build_object('pool','mine','count',2,'topics',
                       jsonb_build_array(v_t::text),
                       'class','cccc0000-0000-0000-0000-0000000000c1'),
    'aaaa0000-0000-0000-0000-0000000000c1');
  assert array_length(v_pick,1) = 2, format('secilen say: %s', array_length(v_pick,1));
  assert v_sim1 = any(v_pick) and v_sim2 = any(v_pick),
         'sehve benzeyen suallar one kecmedi';
end $$;
\echo 'OK  6 · sehve QELIBCE benzeyen suallar one kecir'

-- =====================================================================
--  7. Ozge qrupun id-si qaydada isledilse - acıq imtina
-- =====================================================================
do $$
declare ok boolean := false;
begin
  begin
    perform app.generate_pick(
      jsonb_build_object('pool','mine','count',1,
                         'class','cccc0000-0000-0000-0000-0000000000c2'),
      'aaaa0000-0000-0000-0000-0000000000c1');
  exception when insufficient_privilege then ok := true;
  end;
  assert ok, 'ozge qrupun sehvleri ile test yigildi';
end $$;
\echo 'OK  7 · qaydadaki qrup da yoxlanilir - ozgeninki islemir'

-- =====================================================================
--  8. Veraqda "sehve benzer" bayragi gorunur
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000c1';
do $$
declare v jsonb; t uuid; n int;
begin
  v := public.rpc_generate_test(
    jsonb_build_object('pool','mine','count',2,'topics',
      (select jsonb_build_array(tp.id::text) from public.topics tp
        join public.subjects s on s.id = tp.subject_id
       where s.slug='riyaziyyat' and tp.slug='riy-4-vurma-bolme'),
      'class','cccc0000-0000-0000-0000-0000000000c1'),
    'Duzelis testi');
  t := (v->>'test_id')::uuid;
  v := public.rpc_test_preview(t);
  select count(*) into n from jsonb_array_elements(v->'questions') q
   where (q->>'remedial')::boolean;
  assert n = 2, format('remedial bayraqli sual: %s (2 gozlenilirdi)', n);
end $$;
\echo 'OK  8 · veraqda «sehve benzer» bayragi gorunur'

reset role; reset request.jwt.claim.sub;
