-- =====================================================================
--  smoke_plani.sql : ders plani - yaratma, kecildi, yoxlama testi
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.class_plan_items; delete from public.class_plans;
delete from public.question_reports;
delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments;     delete from public.student_sessions;
delete from public.students;        delete from public.classes;
delete from public.subscriptions;
delete from public.test_questions tq using public.tests t
 where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.account_members; delete from public.accounts;
delete from public.user_roles;      delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email) values
  ('11110000-0000-0000-0000-0000000000f1','plan@t.az'),
  ('11110000-0000-0000-0000-0000000000f2','ozge@t.az');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000f1','tutor','Plan hesabi',
   '11110000-0000-0000-0000-0000000000f1'),
  ('aaaa0000-0000-0000-0000-0000000000f2','tutor','Ozge hesab',
   '11110000-0000-0000-0000-0000000000f2');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000f1','11110000-0000-0000-0000-0000000000f1',true),
  ('aaaa0000-0000-0000-0000-0000000000f2','11110000-0000-0000-0000-0000000000f2',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-0000000000f1','aaaa0000-0000-0000-0000-0000000000f1',
   '11110000-0000-0000-0000-0000000000f1','tutor_group','Plan qrupu','KODPLN01');
insert into public.students (id, account_id, class_id, created_by,
                             full_name, display_name, login_code) values
  ('5555000a-0000-0000-0000-0000000000f1','aaaa0000-0000-0000-0000-0000000000f1',
   'cccc0000-0000-0000-0000-0000000000f1','11110000-0000-0000-0000-0000000000f1',
   'Plan Sagird','Plan S.','PLANSGF1');

\echo '--- hazirliq tamam'

-- =====================================================================
--  1. Abunesiz plan yaradila bilmez - acıq imtina
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f1';
do $$
declare ok boolean := false;
begin
  begin
    perform public.rpc_plan_create('cccc0000-0000-0000-0000-0000000000f1',
                                   'riyaziyyat', '3');
  exception when insufficient_privilege then ok := true; end;
  assert ok, 'abunesiz plan yaradildi!';
end $$;
\echo 'OK  1 · plan pullu qapinin arxasindadir'

-- =====================================================================
--  2. Abune ile: plan yaranir, movzular derslik sirasi ile dolur
-- =====================================================================
reset role; reset request.jwt.claim.sub;
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-0000000000f1', p.id, 'active', now() + interval '30 days'
  from public.plans p where p.slug = 'repetitor-25';
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f1';
do $$
declare v jsonb; n int; ok1 boolean := false; ok2 boolean := false;
begin
  v := public.rpc_plan_create('cccc0000-0000-0000-0000-0000000000f1',
                              'riyaziyyat', '3');
  --  Plan YARPAQLARDAN dolur (db/101): alt movzusu olan movzu ozu
  --  ders deyil, onun alt movzulari dersdir.  Ona gore burada butun
  --  movzular yox, yalniz yarpaqlar sayilir - yoxsa alt movzu elave
  --  edilen kimi bu yoxlama sinardi (bir defe sindi).
  select count(*) into n from public.topics t
    join public.subjects s on s.id = t.subject_id
    join public.levels   l on l.id = t.level_id
   where s.slug = 'riyaziyyat' and l.code = '3'
     and not exists (select 1 from public.topics c where c.parent_id = t.id);
  assert (v->>'topics')::int = n, format('movzu sayi: %s / %s', v->>'topics', n);
  assert n > 0, 'yarpaq movzu yoxdur';

  --  tekrar plan / bos movzu agaci - acıq imtina
  begin
    perform public.rpc_plan_create('cccc0000-0000-0000-0000-0000000000f1',
                                   'riyaziyyat', '3');
  exception when others then ok1 := true; end;
  begin
    perform public.rpc_plan_create('cccc0000-0000-0000-0000-0000000000f1',
                                   'fizika', '3');
  exception when others then ok2 := true; end;
  assert ok1 and ok2, 'tekrar/bos plan kecdi';
end $$;
\echo 'OK  2 · plan movzu agacindan dolur, tekrar/bos imtina'

-- =====================================================================
--  2b. Secimler: yalniz movzu agaci olan fenn+sinif kombinasiyalari
-- =====================================================================
do $$
declare v jsonb;
begin
  v := public.rpc_plan_options();
  assert exists (select 1 from jsonb_array_elements(v) e
                  where e->>'slug' = 'riyaziyyat'
                    and exists (select 1 from jsonb_array_elements(e->'levels') l
                                 where l->>'code' = '3')),
         'riyaziyyat/3 secimlerde yoxdur';
  --  agaci olmayan fenn siyahiya dusmur
  assert not exists (select 1 from jsonb_array_elements(v) e
                      where not exists (
                        select 1 from public.topics t
                          join public.subjects s on s.id = t.subject_id
                         where s.slug = e->>'slug')),
         'agacsiz fenn siyahiya dusdu';
end $$;
\echo 'OK 2b · secimlerde yalniz agaci olan kombinasiyalar'

-- =====================================================================
--  3. plan_get: irelileyis, cari movzu
-- =====================================================================
do $$
declare v jsonb;
begin
  v := public.rpc_plan_get('cccc0000-0000-0000-0000-0000000000f1');
  assert (v->>'paid')::boolean, 'paid bayragi sehvdir';
  assert jsonb_array_length(v->'plans') = 1, 'plan sayi sehvdir';
  assert (v->'plans'->0->>'done')::int = 0, 'done sifir olmali idi';
  assert (v->'plans'->0->'items'->0->>'ord')::int = 1, 'sira pozulub';
end $$;
\echo 'OK  3 · plan_get: siyahi, sira, paid bayragi'

-- =====================================================================
--  4. "Kecildi": yalniz cari movzu; geri qaytarma yalniz sonuncu
-- =====================================================================
do $$
declare
  v jsonb; it1 uuid; it2 uuid; ok1 boolean := false; ok2 boolean := false;
begin
  v := public.rpc_plan_get('cccc0000-0000-0000-0000-0000000000f1');
  it1 := (v->'plans'->0->'items'->0->>'id')::uuid;
  it2 := (v->'plans'->0->'items'->1->>'id')::uuid;

  --  cari olmayan movzu kecile bilmez
  begin
    perform public.rpc_plan_done(it2);
  exception when others then ok1 := true; end;
  assert ok1, 'cari olmayan movzu kecildi!';

  perform public.rpc_plan_done(it1);
  perform public.rpc_plan_done(it2);
  v := public.rpc_plan_get('cccc0000-0000-0000-0000-0000000000f1');
  assert (v->'plans'->0->>'done')::int = 2, 'done sayi sehvdir';

  --  yalniz SON kecilmis geri qaytarilir
  begin
    perform public.rpc_plan_undo(it1);
  exception when others then ok2 := true; end;
  assert ok2, 'kohne movzu geri qaytarildi!';
  perform public.rpc_plan_undo(it2);
  v := public.rpc_plan_get('cccc0000-0000-0000-0000-0000000000f1');
  assert (v->'plans'->0->>'done')::int = 1, 'undo islemedi';
end $$;
\echo 'OK  4 · kecildi/undo yalniz duzgun movzuda isleyir'

-- =====================================================================
--  5. Yoxlama testi: yaranir, movzuya baglidir, tapsiriq verilir
-- =====================================================================
do $$
declare
  v jsonb; it1 uuid; it2 uuid; tid uuid; ok1 boolean := false;
begin
  v := public.rpc_plan_get('cccc0000-0000-0000-0000-0000000000f1');
  it1 := (v->'plans'->0->'items'->0->>'id')::uuid;
  it2 := (v->'plans'->0->'items'->1->>'id')::uuid;

  --  kecilmemis movzudan test olmaz
  begin
    perform public.rpc_plan_test(it2, 5);
  exception when others then ok1 := true; end;
  assert ok1, 'kecilmemis movzudan test yigildi!';

  v := public.rpc_plan_test(it1, 5);
  tid := (v->>'test_id')::uuid;
  --  cedvel oxunuslari ucun superuser kontekstine kecirik
  reset role; reset request.jwt.claim.sub;
  assert (select count(*) from public.test_questions where test_id = tid) = 5,
         'test 5 sualliq deyil';
  --  Butun suallar mehz bu movzudandir.  Bend ALT MOVZUDURSA hovuz
  --  valideyndedir (db/101 bele qurub - alt movzuya sual baglanmir),
  --  ona gore valideynin movzusu da qanunidir.
  assert not exists (
    select 1 from public.test_questions tq
      join public.questions q on q.id = tq.question_id
      join public.class_plan_items i on i.id = it1
      join public.topics t on t.id = i.topic_id
     where tq.test_id = tid
       and q.topic_id is distinct from coalesce(t.parent_id, t.id)),
    'basqa movzunun suali dusdu';
  --  tapsiriq avtomatik verilib
  assert exists (select 1 from public.assignments
                  where test_id = tid
                    and class_id = 'cccc0000-0000-0000-0000-0000000000f1'),
         'tapsiriq verilmedi';
  --  item test ile baglandi
  assert (select test_id from public.class_plan_items where id = it1) = tid,
         'item test_id yazilmadi';
end $$;
\echo 'OK  5 · yoxlama testi: movzudan yigilir, qrupa teyin olunur'

-- =====================================================================
--  5b. Qarisiq test: bir nece kecilmis movzudan birge
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f1';
do $$
declare
  v jsonb; it1 uuid; it2 uuid; it3 uuid; tid uuid;
  ok1 boolean := false; ok2 boolean := false;
begin
  v := public.rpc_plan_get('cccc0000-0000-0000-0000-0000000000f1');
  it1 := (v->'plans'->0->'items'->0->>'id')::uuid;
  it2 := (v->'plans'->0->'items'->1->>'id')::uuid;
  it3 := (v->'plans'->0->'items'->2->>'id')::uuid;

  perform public.rpc_plan_done(it2);

  --  kecilmemis movzu qarisiga dusmez; tek movzu da olmaz
  begin
    perform public.rpc_plan_test_multi(array[it1, it3], 5);
  exception when others then ok1 := true; end;
  begin
    perform public.rpc_plan_test_multi(array[it1], 5);
  exception when others then ok2 := true; end;
  assert ok1 and ok2, 'yanlis qarisiq test kecdi';

  v := public.rpc_plan_test_multi(array[it1, it2], 6);
  tid := (v->>'test_id')::uuid;

  --  cedvel oxunuslari ucun superuser kontekstine kecirik
  reset role; reset request.jwt.claim.sub;
  --  Bu yoxlamanin qiymeti alt movzudadir: db/103-den evvel iki alt
  --  movzudan qarisiq test "0 ferqli sual tapildi" verirdi.  Bendler
  --  alt movzu olmasa yoxlama hec ne subut etmir - ona gore israr et.
  assert exists (select 1 from public.class_plan_items i
                   join public.topics t on t.id = i.topic_id
                  where i.id in (it1, it2) and t.parent_id is not null),
         'bendlerin hec biri alt movzu deyil - yoxlama bos qalir';

  assert (select count(*) from public.test_questions where test_id = tid) = 6,
         'qarisiq test 6 sualliq deyil';
  --  Alt movzuda sual olmadigi ucun hovuz valideyndedir (db/103) -
  --  qanuni movzular: bendin oz movzusu ve ya onun valideyni.
  assert not exists (
    select 1 from public.test_questions tq
      join public.questions q on q.id = tq.question_id
     where tq.test_id = tid
       and q.topic_id not in (
             select coalesce(t.parent_id, t.id)
               from public.class_plan_items i
               join public.topics t on t.id = i.topic_id
              where i.id in (it1, it2))),
    'kenar movzunun suali dusdu';
  assert exists (select 1 from public.assignments where test_id = tid),
         'qarisiq teste tapsiriq verilmedi';
  assert (select test_id from public.class_plan_items where id = it2) is null,
         'qarisiq test item-e baglanmamalidir';
end $$;
\echo 'OK 5b · qarisiq test: 2 movzudan yigilir, item-e baglanmir'

-- =====================================================================
--  5c. Adaptiv plan: movzu testinin qrup ortalamasi plana qayidir
-- =====================================================================
do $$
declare tid uuid;
begin
  select test_id into tid from public.class_plan_items
   where test_id is not null order by ord limit 1;
  insert into public.attempts (student_id, test_id, class_id, status,
                               finished_at, score, max_score, percent)
  values ('5555000a-0000-0000-0000-0000000000f1', tid,
          'cccc0000-0000-0000-0000-0000000000f1', 'submitted',
          now(), 2, 5, 40);
end $$;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f1';
do $$
declare v jsonb; it jsonb;
begin
  v := public.rpc_plan_get('cccc0000-0000-0000-0000-0000000000f1');
  it := v->'plans'->0->'items'->0;
  assert (it->>'avg')::numeric = 40, format('ortalama 40 deyil: %s', it->>'avg');
  assert (it->>'takers')::int = 1, 'istirakci sayi 1 deyil';
  --  testi olmayan movzuda avg bosdur
  assert v->'plans'->0->'items'->2->'avg' = 'null'::jsonb,
         'testsiz movzuda avg dolu geldi';
end $$;
reset role; reset request.jwt.claim.sub;
\echo 'OK 5c · movzu testinin ortalamasi plan setirine qayidir'

-- =====================================================================
--  6. Ozge muellim plana toxuna bilmir
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f2';
do $$
declare ok1 boolean := false;
begin
  begin
    perform public.rpc_plan_get('cccc0000-0000-0000-0000-0000000000f1');
  exception when insufficient_privilege then ok1 := true; end;
  assert ok1, 'ozge muellim plani gordu!';
end $$;
\echo 'OK  6 · ozge muellim qrupun planina toxuna bilmir'

-- =====================================================================
--  7. anon hec ne gormur
-- =====================================================================
reset role; reset request.jwt.claim.sub;
do $$
begin
  assert not has_function_privilege('anon', 'public.rpc_plan_get(uuid)', 'EXECUTE'),
         'anon plani gorur';
  assert not has_function_privilege('anon', 'public.rpc_plan_test(uuid, int)', 'EXECUTE'),
         'anon test yigir';
end $$;
\echo 'OK  7 · anon plan funksiyalarini gormur'
