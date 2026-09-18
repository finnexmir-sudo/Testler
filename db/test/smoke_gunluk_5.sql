-- =====================================================================
--  smoke_gunluk_5.sql : «Bu gunun 5 sualı» (212)
--
--  Iddialar:
--    1  paket yalniz KECILEN movzudan gelir (mutleq qayda)
--    2  paket gun icinde SABITDIR - tekrar cagiris eyni sualı verir
--    3  sira SERVERDEDIR - yad suala cavab redd olunur
--    4  duz variant client-e GETMIR
--    5  besinci cavabdan sonra done + movzu-movzu hesabat
--    6  sehv cavab defterde SABAHA qalir (bu gun bir de cixmir)
--    7  abunesiz hesabda paket qurulmur, cavab redd olunur
--    8  plan hec isarelenmemisdirse fallback isleyir
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.daily_packs;
delete from public.mistakes;
delete from public.student_sessions;
delete from public.attempt_answers where attempt_id in
  (select id from public.attempts where student_id in
    (select id from public.students where login_code in ('GUN00001','GUN00002')));
delete from public.attempts where student_id in
  (select id from public.students where login_code in ('GUN00001','GUN00002'));
delete from public.students where login_code in ('GUN00001','GUN00002');
delete from public.class_plan_items where plan_id in
  (select id from public.class_plans where class_id = 'cccc0000-0000-0000-0000-000000000212');
delete from public.class_plans where class_id = 'cccc0000-0000-0000-0000-000000000212';
delete from public.classes where id in ('cccc0000-0000-0000-0000-000000000212',
                                        'cccc0000-0000-0000-0000-000000000213');
delete from public.accounts where id = 'aaaa0000-0000-0000-0000-000000000212';

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-000000000212','gun@t.az','{"full_name":"Gun Muellim"}')
on conflict (id) do nothing;
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-000000000212','tutor','Gun hesabi','11110000-0000-0000-0000-000000000212')
on conflict (id) do nothing;
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-000000000212','11110000-0000-0000-0000-000000000212',true)
on conflict do nothing;

--  Movzu agaci: suali bol olan iki KOK movzu secirik (suallar koke
--  baglidir, plan setri ise yarpaqdir - ona gore yarpaq axtaririq).
do $$
declare
  v_t1 uuid; v_t2 uuid; v_lev uuid; v_sub uuid;
  v_leaf1 uuid; v_leaf2 uuid; v_plan uuid;
begin
  select q.topic_id into v_t1
    from public.questions q
   where q.status = 'published' and q.kind = 'single' and q.topic_id is not null
     and q.owner_type = 'platform'
   group by q.topic_id having count(*) >= 8
   order by count(*) desc limit 1;
  select q.topic_id into v_t2
    from public.questions q
   where q.status = 'published' and q.kind = 'single' and q.topic_id is not null
     and q.owner_type = 'platform' and q.topic_id <> v_t1
   group by q.topic_id having count(*) >= 8
   order by count(*) desc limit 1;
  if v_t1 is null or v_t2 is null then
    raise exception '212 fikstur: 8+ tek secimli sualı olan iki movzu lazimdir';
  end if;
  select subject_id, level_id into v_sub, v_lev from public.topics where id = v_t1;

  --  Qrupun sinfi: sualin seviyyesi ile UST-USTE dusmelidir, yoxsa
  --  daily_pool bos qalir (q.level_id = p_level or q.level_id is null).
  insert into public.classes (id, account_id, teacher_id, kind, name, join_code, level_id)
  values ('cccc0000-0000-0000-0000-000000000212','aaaa0000-0000-0000-0000-000000000212',
          '11110000-0000-0000-0000-000000000212','tutor_group','Gun qrup','KODGUN12',
          (select level_id from public.questions where topic_id = v_t1 and level_id is not null limit 1))
  on conflict (id) do nothing;
  --  plan olmayan ikinci qrup (8-ci bolme: fallback)
  insert into public.classes (id, account_id, teacher_id, kind, name, join_code, level_id)
  values ('cccc0000-0000-0000-0000-000000000213','aaaa0000-0000-0000-0000-000000000212',
          '11110000-0000-0000-0000-000000000212','tutor_group','Gun qrup 2','KODGUN13',
          (select level_id from public.questions where topic_id = v_t1 and level_id is not null limit 1))
  on conflict (id) do nothing;

  --  Plan: yarpaq setirler.  v_t1 kokunun yarpagi varsa onu, yoxsa
  --  ozunu goturuk (101-in mentiqi).
  select coalesce((select c.id from public.topics c where c.parent_id = v_t1 limit 1), v_t1) into v_leaf1;
  select coalesce((select c.id from public.topics c where c.parent_id = v_t2 limit 1), v_t2) into v_leaf2;

  insert into public.class_plans (class_id, subject_id, level_id)
  values ('cccc0000-0000-0000-0000-000000000212', v_sub,
          (select level_id from public.classes where id = 'cccc0000-0000-0000-0000-000000000212'))
  returning id into v_plan;
  --  YALNIZ BIRINCI movzu «kecildi» - ikinci plandadir, amma kecilmemis
  insert into public.class_plan_items (plan_id, topic_id, ord, done_at)
  values (v_plan, v_leaf1, 1, now() - interval '2 days');
  insert into public.class_plan_items (plan_id, topic_id, ord, done_at)
  values (v_plan, v_leaf2, 2, null);

  perform set_config('smoke.t1', v_t1::text, false);
  perform set_config('smoke.t2', v_t2::text, false);
end $$;

insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code) values
  ('5555000d-0000-0000-0000-000000000212','aaaa0000-0000-0000-0000-000000000212',
   'cccc0000-0000-0000-0000-000000000212','11110000-0000-0000-0000-000000000212','Gun Sagird','Gun S.','GUN00001'),
  ('5555000d-0000-0000-0000-000000000213','aaaa0000-0000-0000-0000-000000000212',
   'cccc0000-0000-0000-0000-000000000213','11110000-0000-0000-0000-000000000212','Gun Sagird 2','Gun S2.','GUN00002')
on conflict (id) do nothing;
insert into public.student_sessions (token_hash, student_id, expires_at) values
  (app.hash_token('gun-token'),'5555000d-0000-0000-0000-000000000212', now() + interval '1 day'),
  (app.hash_token('gun-token2'),'5555000d-0000-0000-0000-000000000213', now() + interval '1 day')
on conflict (token_hash) do nothing;

-- =====================================================================
--  1 · abunesiz hesab: paket qurulmur, movzu adlari gorunur
-- =====================================================================
--  Yoxlama sualı/variantı ROLDAN EVVEL ayrilir: anon question_options-u
--  oxuya bilmir ve «permission denied» ozu 42501 verir - test yalan
--  yerden kecerdi.
do $$
declare v_q uuid; v_o uuid;
begin
  select q.id into v_q from public.questions q
   where q.status = 'published' and q.kind = 'single'
     and exists (select 1 from public.question_options o where o.question_id = q.id)
   limit 1;
  select o.id into v_o from public.question_options o where o.question_id = v_q limit 1;
  perform set_config('smoke.q', v_q::text, false);
  perform set_config('smoke.o', v_o::text, false);
end $$;
set role anon;
do $$
declare r jsonb;
begin
  r := public.rpc_student_daily('gun-token');
  if (r->>'paid')::boolean then raise exception '212/1: abune gozlenilmirdi'; end if;
  if (r->>'total')::int <> 0 then raise exception '212/1: abunesiz paket quruldu (%)', r->>'total'; end if;
  if r->'question' <> 'null'::jsonb and r->'question' is not null then
    raise exception '212/1: abunesiz hesaba sual gedir';
  end if;
  --  ne itirdiyini GORSUN - movzu adi gelir
  if jsonb_array_length(r->'topics') = 0 then
    raise exception '212/1: movzu adlari gelmedi (usaq ne itirdiyini gormur)';
  end if;
end $$;
do $$
begin
  begin
    perform public.rpc_student_daily_answer('gun-token',
      current_setting('smoke.q')::uuid, current_setting('smoke.o')::uuid);
    raise exception '212/1: abunesiz cavab qebul olundu';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;
\echo 'OK  1 · abunəsiz hesabda paket qurulmur, cavab rədd olunur'

--  abune acilir
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-000000000212', id, 'active', now() + interval '30 days'
  from public.plans where slug = 'repetitor-25'
on conflict do nothing;

-- =====================================================================
--  2 · paket qurulur ve YALNIZ kecilen movzudan gelir
-- =====================================================================
set role anon;
do $$
declare r jsonb; v_t1 uuid := current_setting('smoke.t1')::uuid; v_bad int;
begin
  r := public.rpc_student_daily('gun-token');
  if not (r->>'paid')::boolean then raise exception '212/2: abune gorunmur'; end if;
  if (r->>'total')::int < 3 then raise exception '212/2: paket qurulmadi (%)', r->>'total'; end if;
  if r->'question'->>'id' is null then raise exception '212/2: cari sual yoxdur'; end if;
  perform set_config('smoke.total', r->>'total', false);
end $$;
reset role;
do $$
declare v_t1 uuid := current_setting('smoke.t1')::uuid; v_bad int;
begin
  select count(*) into v_bad
    from public.daily_packs d, jsonb_array_elements(d.items) it
    join public.questions q on q.id = (it->>'q')::uuid
   where d.student_id = '5555000d-0000-0000-0000-000000000212'
     and q.topic_id is distinct from v_t1;
  if v_bad > 0 then
    raise exception '212/2: % sual KECILMEMIS movzudan geldi', v_bad;
  end if;
end $$;
\echo 'OK  2 · paket qurulur, bütün suallar keçilən mövzudandır'

-- =====================================================================
--  3 · gun icinde SABIT: tekrar cagiris eyni sualı verir
-- =====================================================================
set role anon;
do $$
declare a jsonb; b jsonb;
begin
  a := public.rpc_student_daily('gun-token');
  b := public.rpc_student_daily('gun-token');
  if a->'question'->>'id' <> b->'question'->>'id' then
    raise exception '212/3: sual deyisdi (%, %)', a->'question'->>'id', b->'question'->>'id';
  end if;
  if a->>'total' <> b->>'total' then raise exception '212/3: sual sayi deyisdi'; end if;
end $$;
\echo 'OK  3 · paket gün içində sabit qalır'

-- =====================================================================
--  4 · duz variant client-e getmir
-- =====================================================================
do $$
declare r jsonb;
begin
  set role anon;
  r := public.rpc_student_daily('gun-token');
  reset role;
  if r::text like '%is_correct%' or r::text like '%correct":true%' then
    raise exception '212/4: duz variant sizdi';
  end if;
  if jsonb_array_length(r->'question'->'options') < 2 then
    raise exception '212/4: variantlar gelmedi';
  end if;
end $$;
\echo 'OK  4 · düz variant cavabdan əvvəl göndərilmir'

-- =====================================================================
--  5 · sira serverdedir: yad suala cavab redd olunur
-- =====================================================================
--  paketin SONUNCU sualı - novbeti deyil.  Cedveli anon oxuya bilmir,
--  ona gore id-ni ROLDAN EVVEL ayirib set_config-le kecirik.
do $$
declare v_other uuid;
begin
  select (d.items->-1->>'q')::uuid into v_other from public.daily_packs d
   where d.student_id = '5555000d-0000-0000-0000-000000000212'
     and d.day = (now() at time zone 'Asia/Baku')::date;
  perform set_config('smoke.other', coalesce(v_other::text, ''), false);
  perform set_config('smoke.other_o', coalesce(
    (select o.id::text from public.question_options o where o.question_id = v_other limit 1), ''), false);
end $$;
set role anon;
do $$
declare r jsonb; v_other uuid := nullif(current_setting('smoke.other'), '')::uuid;
begin
  r := public.rpc_student_daily('gun-token');
  if v_other is null or v_other = (r->'question'->>'id')::uuid then
    raise notice '212/5: paket tek sualdir, yoxlama atlandi';
  else
    begin
      perform public.rpc_student_daily_answer('gun-token', v_other,
        nullif(current_setting('smoke.other_o'), '')::uuid);
      raise exception '212/5: sirasiz sual qebul olundu';
    exception when sqlstate '22023' then null;
    end;
  end if;
end $$;
\echo 'OK  5 · sıra serverdədir — sırasız suala cavab rədd olunur'

-- =====================================================================
--  6 · butun paketi isle: sehv -> defterde SABAHA, done + hesabat
-- =====================================================================
do $$
declare
  r jsonb; a jsonb; v_q uuid; v_opt uuid; v_n int; k int := 0;
  v_first_wrong uuid;
begin
  loop
    set role anon;
    r := public.rpc_student_daily('gun-token');
    reset role;
    exit when (r->>'done')::boolean;
    v_q := (r->'question'->>'id')::uuid;
    --  birinci sual QESDEN sehv cavablanir (6-ci iddia)
    if k = 0 then
      select o.id into v_opt from public.question_options o
       where o.question_id = v_q and not o.is_correct limit 1;
      v_first_wrong := v_q;
    else
      select o.id into v_opt from public.question_options o
       where o.question_id = v_q and o.is_correct limit 1;
    end if;
    if v_opt is null then
      select o.id into v_opt from public.question_options o where o.question_id = v_q limit 1;
    end if;
    set role anon;
    a := public.rpc_student_daily_answer('gun-token', v_q, v_opt);
    reset role;
    k := k + 1;
    if k > 10 then raise exception '212/6: dovre bitmedi'; end if;
  end loop;
  if k < 3 then raise exception '212/6: cox az sual isledi (%)', k; end if;
  perform set_config('smoke.wrong', v_first_wrong::text, false);

  --  sehv cavab SABAHA qaldi - bu gun bir de cixmir
  if not exists (select 1 from public.mistakes m
                  where m.student_id = '5555000d-0000-0000-0000-000000000212'
                    and m.question_id = v_first_wrong
                    and m.status = 'open' and m.next_at > now()) then
    raise exception '212/6: sehv cavab sabaha qalmadi';
  end if;

  set role anon;
  r := public.rpc_student_daily('gun-token');
  reset role;
  if not (r->>'done')::boolean then raise exception '212/6: done qoyulmadi'; end if;
  if r->'question' <> 'null'::jsonb then raise exception '212/6: bitmis paketde sual qaldi'; end if;
  if jsonb_array_length(r->'result') = 0 then raise exception '212/6: movzu hesabati bos'; end if;
  if (r->>'ok')::int <> k - 1 then
    raise exception '212/6: duz sayi yanlisdir (% , gozlenilen %)', r->>'ok', k - 1;
  end if;
end $$;
\echo 'OK  6 · paket bitir, səhv sabaha qalır, mövzu-mövzu hesabat gəlir'

-- =====================================================================
--  7 · bitmis paketde cavab qebul olunmur
-- =====================================================================
set role anon;
do $$
begin
  begin
    perform public.rpc_student_daily_answer('gun-token',
      current_setting('smoke.q')::uuid, current_setting('smoke.o')::uuid);
    raise exception '212/7: bitmis paketde cavab qebul olundu';
  exception when sqlstate '22023' then null;
  end;
end $$;
reset role;
\echo 'OK  7 · bitmiş paketdə yeni cavab qəbul olunmur'

-- =====================================================================
--  8 · plan hec isarelenmemisdirse FALLBACK: usagin cavabladigi movzu
-- =====================================================================
--  Ikinci sagirdin qrupunda plan yoxdur.  Evvel bir test isleyir -
--  cavab verdigi movzu «kecilmis» sayilir.
do $$
declare
  v_t1 uuid := current_setting('smoke.t1')::uuid;
  v_test uuid; v_att uuid; q record; i int := 0;
begin
  insert into public.tests (owner_type, owner_id, class_id, program_id, subject_id, level_id, title, status)
  values ('educator','11110000-0000-0000-0000-000000000212',
          'cccc0000-0000-0000-0000-000000000213',
          (select id from public.programs order by id limit 1),
          (select subject_id from public.topics where id = v_t1),
          (select level_id from public.classes where id = 'cccc0000-0000-0000-0000-000000000213'),
          'Gun fallback testi','published')
  returning id into v_test;
  for q in select id from public.questions
            where topic_id = v_t1 and status = 'published' and kind = 'single' limit 3 loop
    i := i + 1;
    insert into public.test_questions (test_id, question_id, ord) values (v_test, q.id, i);
  end loop;
  insert into public.attempts (test_id, student_id, class_id, status, finished_at, score, max_score, percent)
  values (v_test,'5555000d-0000-0000-0000-000000000213',
          'cccc0000-0000-0000-0000-000000000213','submitted', now() - interval '10 days', 3, 3, 100)
  returning id into v_att;
  for q in select tq.question_id from public.test_questions tq where tq.test_id = v_test loop
    insert into public.attempt_answers (attempt_id, question_id, topic_id, is_correct, points, answered_at)
    values (v_att, q.question_id, v_t1, true, 1, now() - interval '10 days');
  end loop;
end $$;

set role anon;
do $$
declare r jsonb;
begin
  r := public.rpc_student_daily('gun-token2');
  if (r->>'total')::int < 3 then
    raise exception '212/8: plansiz qrupda fallback islemedi (%)', r->>'total';
  end if;
  if r->>'src' <> 'ozu' then
    raise exception '212/8: src «ozu» gozlenilirdi, geldi «%»', r->>'src';
  end if;
end $$;
reset role;
\echo 'OK  8 · plan işarələnməyibsə şagirdin öz mövzularından qurulur'


-- =====================================================================
--  9 · (213) muellim karti: «tekrar hazirlanmir» isaresi
--     Qrup 212-de plan var ve bir ders kecilib -> hazir.
--     Qrup 213-de plan YOXDUR -> ne hazir, ne plansiz sayilir
--     (plansiz yalniz PLANI OLAN, amma isarelenmeyen qruplardir).
-- =====================================================================
set request.jwt.claim.sub = '11110000-0000-0000-0000-000000000212';
do $$
declare r jsonb;
begin
  r := public.rpc_home(null);
  if r->'tekrar_hazir' is null then
    raise exception '213: tekrar_hazir acari yoxdur';
  end if;
  if (r->>'tekrar_hazir')::int <> 1 then
    raise exception '213: tekrar_hazir 1 gozlenilirdi, geldi %', r->>'tekrar_hazir';
  end if;
  if (r->>'tekrar_plansiz')::int <> 0 then
    raise exception '213: tekrar_plansiz 0 gozlenilirdi, geldi %', r->>'tekrar_plansiz';
  end if;
end $$;

--  Indi «kecildi» geri alinir - hemin sagird «plansiz» olur
update public.class_plan_items set done_at = null
 where plan_id in (select id from public.class_plans
                    where class_id = 'cccc0000-0000-0000-0000-000000000212');
do $$
declare r jsonb;
begin
  r := public.rpc_home(null);
  if (r->>'tekrar_plansiz')::int <> 1 then
    raise exception '213: kecildi geri alinandan sonra plansiz 1 olmalidir (%)', r->>'tekrar_plansiz';
  end if;
  if (r->>'tekrar_hazir')::int <> 0 then
    raise exception '213: hazir 0 olmalidir (%)', r->>'tekrar_hazir';
  end if;
end $$;
update public.class_plan_items set done_at = now() - interval '2 days'
 where ord = 1 and plan_id in (select id from public.class_plans
                    where class_id = 'cccc0000-0000-0000-0000-000000000212');
reset request.jwt.claim.sub;
\echo 'OK  9 · (213) müəllim kartı «təkrar hazırlanmır» sətrini alır'

-- =====================================================================
--  10 · (213) admin: D2 qayitma + bitirme faizi
-- =====================================================================
insert into public.user_roles (user_id, role) values
  ('11110000-0000-0000-0000-000000000212','admin') on conflict do nothing;
--  bir sagird: dunenden evvel ilk paketi BITIRIB, ertesi gun ikincini ACIB
delete from public.daily_packs;
insert into public.daily_packs (student_id, day, items, answers, done_at) values
  ('5555000d-0000-0000-0000-000000000212', current_date - 4,
   '[{"q":"00000000-0000-0000-0000-000000000001"}]'::jsonb,
   '[{"q":"00000000-0000-0000-0000-000000000001","ok":true}]'::jsonb, now() - interval '4 days'),
  ('5555000d-0000-0000-0000-000000000212', current_date - 3,
   '[{"q":"00000000-0000-0000-0000-000000000002"}]'::jsonb,
   '[{"q":"00000000-0000-0000-0000-000000000002","ok":true}]'::jsonb, now() - interval '3 days'),
  --  ikinci sagird: basladi, BITIRMEDI -> bitirme faizini asagi salir
  ('5555000d-0000-0000-0000-000000000213', current_date - 4,
   '[{"q":"00000000-0000-0000-0000-000000000003"},{"q":"00000000-0000-0000-0000-000000000004"}]'::jsonb,
   '[{"q":"00000000-0000-0000-0000-000000000003","ok":false}]'::jsonb, null);
set request.jwt.claim.sub = '11110000-0000-0000-0000-000000000212';
do $$
declare r jsonb; t jsonb;
begin
  r := public.rpc_admin_huni(30);
  t := r->'tekrar';
  if t is null then raise exception '213: huni «tekrar» bloku yoxdur'; end if;
  if (t->>'basladi')::int <> 2 then
    raise exception '213: basladi 2 gozlenilirdi (%)', t->>'basladi';
  end if;
  if (t->>'bitirdi')::int <> 1 then
    raise exception '213: bitirdi 1 gozlenilirdi (%)', t->>'bitirdi';
  end if;
  --  3 baslanan paketden 2-si bitib
  if (t->>'bitirme')::int <> 67 then
    raise exception '213: bitirme 67%% gozlenilirdi (%)', t->>'bitirme';
  end if;
  --  ilk bitirilen paket 4 gun evveldir, ertesi gun ikinci acilib -> 100%
  if (t->>'d2_baza')::int <> 1 or (t->>'d2')::int <> 100 then
    raise exception '213: D2 1/100 gozlenilirdi (% / %)', t->>'d2_baza', t->>'d2';
  end if;
end $$;
reset request.jwt.claim.sub;
delete from public.user_roles where user_id = '11110000-0000-0000-0000-000000000212';
delete from public.daily_packs;
\echo 'OK 10 · (213) hunidə D2 qayıtma və bitirmə faizi'

-- ------------------------------------------------------------ temizlik
delete from public.daily_packs;
delete from public.subscriptions where account_id = 'aaaa0000-0000-0000-0000-000000000212';
\echo 'OK  smoke_gunluk_5 — hamısı keçdi'
