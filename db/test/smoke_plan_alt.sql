-- =====================================================================
--  smoke_plan_alt.sql : ders plani iki seviyyeli
--                       (db/101_ders_plani_alt.sql)
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers;  delete from public.attempts;
delete from public.assignments;      delete from public.student_sessions;
delete from public.students;         delete from public.classes;
delete from public.subscriptions;
delete from public.test_questions tq using public.tests t
 where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.topics where parent_id is not null;
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-0000000000ba','p@t.az','{"full_name":"Plan Muellim"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000ba','tutor','P hesabi',
   '11110000-0000-0000-0000-0000000000ba');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000ba','11110000-0000-0000-0000-0000000000ba',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code, level_id)
select 'cccc0000-0000-0000-0000-0000000000ba',
       'aaaa0000-0000-0000-0000-0000000000ba',
       '11110000-0000-0000-0000-0000000000ba','tutor_group','P qrupu','KODPLN01',
       l.id from public.levels l where l.code = '3' and l.code ~ '^[0-9]+$';
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-0000000000ba', p.id, 'active', now() + interval '30 days'
  from public.plans p where p.slug = 'repetitor-25';

\echo '--- hazirliq tamam'

-- =====================================================================
--  1. ALT MOVZU YOXDURSA davranis bu gunku ile EYNIDIR
--     (bu vacibdir: fayl alt movzu setirlerinden EVVEL de cixir)
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000ba';
do $$
declare r jsonb; v_n int; v_all int;
begin
  r := public.rpc_plan_create('cccc0000-0000-0000-0000-0000000000ba','riyaziyyat','3');
  v_n := (r->>'topics')::int;
  select count(*) into v_all from public.topics t
    join public.levels l on l.id = t.level_id
   where t.subject_id = (select id from public.subjects where slug='riyaziyyat')
     and l.code = '3';
  assert v_n = v_all,
    'alt movzusuz halda setir sayi movzu sayindan ferqlenir: ' || v_n || ' <> ' || v_all;
end $$;
\echo 'OK  1 · alt movzu yoxdursa plan eskisi kimi qurulur'

-- =====================================================================
--  2. Fesil melumati BOSDUR - interfeys duz yigcam gostersin
-- =====================================================================
do $$
declare v jsonb; it jsonb;
begin
  v := public.rpc_plan_get('cccc0000-0000-0000-0000-0000000000ba');
  it := v->'plans'->0->'items'->0;
  assert it->'group' = 'null'::jsonb,
    'fesilsiz movzuda fesil adi geldi: ' || (it->'group')::text;
  assert it->'gpos' = 'null'::jsonb, 'fesilsiz movzuda mövqe geldi';
end $$;
\echo 'OK  2 · fesilsiz movzuda qrup melumati bosdur'

-- =====================================================================
--  3. INDI ALT MOVZU ELAVE EDIRIK - plan yenidən qurulanda
--     setirler YARPAQLARDAN ibaret olur, basliq setir DEYIL
-- =====================================================================
reset role; reset request.jwt.claim.sub;
--  ilk movzuya 3 alt movzu
insert into public.topics (subject_id, level_id, parent_id, slug, name, sort)
select t.subject_id, t.level_id, t.id,
       t.slug || '-alt' || g, 'Alt ' || g, g * 10
  from public.topics t
  join public.levels l on l.id = t.level_id
  cross join generate_series(1,3) g
 where t.subject_id = (select id from public.subjects where slug='riyaziyyat')
   and l.code = '3' and t.parent_id is null
   and t.sort = (select min(t2.sort) from public.topics t2
                   join public.levels l2 on l2.id = t2.level_id
                  where t2.subject_id = t.subject_id and l2.code = '3'
                    and t2.parent_id is null);

set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000ba';
do $$
declare r jsonb; v_n int; v_leaf int;
begin
  --  DIQQET: class_plans-i BIRBASA oxumaq olmaz - RLS baglayir.
  --  Id-ni definer funksiyanin cavabindan gotururuk.
  perform public.rpc_plan_delete(
    ((public.rpc_plan_get('cccc0000-0000-0000-0000-0000000000ba')
      ->'plans'->0->>'id')::uuid));
  r := public.rpc_plan_create('cccc0000-0000-0000-0000-0000000000ba','riyaziyyat','3');
  v_n := (r->>'topics')::int;
  select count(*) into v_leaf from public.topics t
    join public.levels l on l.id = t.level_id
   where t.subject_id = (select id from public.subjects where slug='riyaziyyat')
     and l.code = '3'
     and not exists (select 1 from public.topics c where c.parent_id = t.id);
  assert v_n = v_leaf,
    'setirler yarpaq deyil: ' || v_n || ' <> ' || v_leaf;
  --  basliq setir OLMAMALIDIR.  Setirleri definer funksiyadan
  --  oxuyuruq - class_plan_items-e birbasa giris RLS ile baglidir.
  assert not exists (
    select 1 from jsonb_array_elements(
             public.rpc_plan_get('cccc0000-0000-0000-0000-0000000000ba')
             ->'plans'->0->'items') x
      join public.topics t on t.name = x->>'topic'
     where exists (select 1 from public.topics c where c.parent_id = t.id)),
    'ovladi olan basliq plan setiri kimi dusub';
end $$;
\echo 'OK  3 · setirler yalniz yarpaqdir, basliq setir deyil'

-- =====================================================================
--  4. Siralama AGAC sirasi iledir - alt movzular oz feslinin altinda
-- =====================================================================
do $$
declare v jsonb; n int;
begin
  v := public.rpc_plan_get('cccc0000-0000-0000-0000-0000000000ba');
  --  ilk uc setir eyni feslin alt movzulari olmalidir
  select count(*) into n
    from jsonb_array_elements(v->'plans'->0->'items') x
   where (x->>'ord')::int <= 3 and x->>'group' is not null;
  assert n = 3, 'ilk uc setir bir feslin alti deyil: ' || n;
  assert (v->'plans'->0->'items'->0->>'gpos') = '1',
    'fesildeki movqe yanlisdir: ' || (v->'plans'->0->'items'->0->>'gpos');
  assert (v->'plans'->0->'items'->0->>'gtotal') = '3',
    'fesildeki cem yanlisdir: ' || (v->'plans'->0->'items'->0->>'gtotal');
end $$;
\echo 'OK  4 · agac sirasi qorunur, fesildeki movqe duzgundur'

-- =====================================================================
--  5. "Test yig" YALNIZ feslin SON yarpagindadir
-- =====================================================================
do $$
declare v jsonb; i1 uuid; i2 uuid; i3 uuid; c1 bool; c3 bool;
begin
  v := public.rpc_plan_get('cccc0000-0000-0000-0000-0000000000ba');
  select (x->>'id')::uuid into i1 from jsonb_array_elements(v->'plans'->0->'items') x
   where (x->>'ord')::int = 1;
  select (x->>'id')::uuid into i2 from jsonb_array_elements(v->'plans'->0->'items') x
   where (x->>'ord')::int = 2;
  select (x->>'id')::uuid into i3 from jsonb_array_elements(v->'plans'->0->'items') x
   where (x->>'ord')::int = 3;
  perform public.rpc_plan_done(i1);
  v := public.rpc_plan_get('cccc0000-0000-0000-0000-0000000000ba');
  select (x->>'can_test')::bool into c1
    from jsonb_array_elements(v->'plans'->0->'items') x where (x->>'ord')::int = 1;
  assert c1 = false, 'fesil bitmeden "test yig" teklif olunur';

  perform public.rpc_plan_done(i2);
  perform public.rpc_plan_done(i3);
  v := public.rpc_plan_get('cccc0000-0000-0000-0000-0000000000ba');
  select (x->>'can_test')::bool into c3
    from jsonb_array_elements(v->'plans'->0->'items') x where (x->>'ord')::int = 3;
  assert c3, 'fesil bitdi, amma "test yig" cixmir';
end $$;
\echo 'OK  5 · "test yig" yalniz feslin son yarpaginda cixir'

-- =====================================================================
--  6. Test VALIDEYN movzudan yigilir - alt movzunun oz sualı yoxdur
-- =====================================================================
do $$
declare i3 uuid; r jsonb; v jsonb; v_rule jsonb; v_par uuid; v_top text;
begin
  v := public.rpc_plan_get('cccc0000-0000-0000-0000-0000000000ba');
  select (x->>'id')::uuid, x->>'topic' into i3, v_top
    from jsonb_array_elements(v->'plans'->0->'items') x
   where (x->>'ord')::int = 3;
  r := public.rpc_plan_test(i3, 5);
  select gen_rule into v_rule from public.tests where id = (r->>'test_id')::uuid;
  --  alt movzunun valideyni (topics oxumaq authenticated-e aciqdir)
  select t.parent_id into v_par from public.topics t where t.name = v_top
     and t.parent_id is not null limit 1;
  assert v_rule->'topics'->>0 = v_par::text,
    'test alt movzudan yigilib, valideynden yox: ' || (v_rule->'topics')::text;
end $$;
\echo 'OK  6 · test valideyn movzunun hovuzundan yigilir'

-- =====================================================================
--  7. Anon plana yaxin dusmur
-- =====================================================================
reset role; reset request.jwt.claim.sub;
do $$
begin
  if has_function_privilege('anon', 'public.rpc_plan_get(uuid)', 'EXECUTE') then
    raise exception 'anon plani gore bilir';
  end if;
  if has_function_privilege('anon', 'public.rpc_plan_test(uuid, int)', 'EXECUTE') then
    raise exception 'anon plan testi yiga bilir';
  end if;
end $$;
\echo 'OK  7 · anon plan funksiyalarindan kenardadir'

\echo 'PLAN ALT: BUTUN YOXLAMALAR KECDI'
