-- =====================================================================
--  937 : «CETIN» SECILIB, CETIN SUAL AZDIR -> TEST ORTA SUALLARLA TAMAMLANIR
--        (2026-11-20, istifadeci)
--
--  PROBLEM
--  Muellim Test yig-da movzu secib «Çətin» basanda generator yalniz
--  difficulty = 3 suallari goturur.  Az dili 10 ve 11-de cetin sual 0-1-dir,
--  basqa bezi movzularda da azdir - test YIGILMIRDI («Bu suzgecle yalniz
--  N ferqli sual tapildi»).
--
--  HELL
--  app.generate_pick_cetin: qaydada cetinlik YALNIZ «3»-dursa ve 3-ler
--  testin sayina catmirsa, evvel 3-lerin HAMISI goturulur, qalani EYNI
--  qaydadan (eyni fenn, sinif, movzular, hovuz) difficulty = 2 suallarla
--  doldurulur.  Tekrar suzgeci (>= 0.95 oxsarliq) qarisiqda da isleyir.
--  Qaytarir: o_ids (sira: evvel cetinler), o_filled (nece «orta» elave olundu).
--  rpc_generate_preview ve rpc_generate_test bunu cagirir ve 'filled' qaytarir -
--  panel muellime qisa qeyd gosterir: «Bu mövzuda çətin sual azdır — test orta
--  suallarla tamamlandı.»  Basqa cetinlik secimleri (asan, orta, bir nece) DEYISMIR.
--  ASANLA DOLDURULMUR (istifadeci, 20.11): 3 + 2 birlikde catmirsa test yigilmir;
--  rpc_generate_preview bunu 'cetin_ok' ile evvelceden deyir, panel «Çətin»i boz edir:
--  «Bu mövzuda çətin və orta sual yoxdur — adi test yığın.»  Fayl tekrar isledile biler.
--
--  app.generate_pick-e TOXUNULMUR.  RPC govdeleri canli bazadaki versiyadan
--  HERFEN kocurulub, yalniz secim setri ve qaytarilan 'filled' elave olunub.
--  ON SERT: 13, 103, 223, 929 (generate_pick).   Supabase: temp cedvel / begin yoxdur.
-- =====================================================================

create or replace function app.generate_pick_cetin(p_rule jsonb, p_account uuid,
  out o_ids uuid[], out o_filled int)
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare
  v_want int := least(greatest(coalesce((p_rule->>'count')::int, 10), 1), 100);
  v_more uuid[];
  v_b    text;
  x      uuid;
begin
  o_filled := 0;
  o_ids := coalesce(app.generate_pick(p_rule, p_account), '{}');
  if cardinality(o_ids) >= v_want
     or jsonb_typeof(p_rule->'difficulty') is distinct from 'array'
     or (select coalesce(array_agg(distinct d), '{}') from jsonb_array_elements_text(p_rule->'difficulty') d) <> array['3'] then
    return;
  end if;
  --  eyni qayda, yalniz cetinlik «orta» (fenn, sinif, movzular, hovuz, exclude eyni qalir)
  v_more := coalesce(app.generate_pick(
              p_rule || jsonb_build_object('difficulty', jsonb_build_array('2'), 'count', v_want), p_account), '{}');
  foreach x in array v_more loop
    exit when cardinality(o_ids) >= v_want;
    continue when x = any(o_ids);
    select q.body into v_b from public.questions q where q.id = x;
    --  tekrar suzgeci: generate_pick ile eyni hedd (>= 0.95)
    continue when exists (select 1 from public.questions q2
                           where q2.id = any(o_ids) and similarity(q2.body, v_b) >= 0.95);
    o_ids := o_ids || x;
    o_filled := o_filled + 1;
  end loop;
end $$;
revoke all on function app.generate_pick_cetin(jsonb, uuid) from public, anon, authenticated;

CREATE OR REPLACE FUNCTION public.rpc_generate_preview(p_rule jsonb, p_account uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
declare
  v_acc  uuid := app.pick_account(p_account);
  v_ids  uuid[];
  v_fill int;
  v_ck   uuid[];
  v_want int := least(greatest(coalesce((p_rule->>'count')::int, 10), 1), 100);
begin
  --  937: «Cetin» secilib, cetin sual catmir - eyni suzgecden «orta» ile tamamlanir
  select o_ids, o_filled into v_ids, v_fill from app.generate_pick_cetin(p_rule, v_acc);
  --  937: «Çətin» bu suzgecde mumkundurmu - testi yigan EYNI funksiya ile (3 + 2 testin sayina catirmi).
  --  Catmirsa panel «Çətin»i boz gosterir (xeta yox).  Asanla doldurulmur.
  select o_ids into v_ck from app.generate_pick_cetin(
    p_rule || jsonb_build_object('difficulty', jsonb_build_array('3')), v_acc);
  return jsonb_build_object(
    'cetin_ok', coalesce(cardinality(v_ck), 0) >= v_want,
    'cetin_n',  coalesce(cardinality(v_ck), 0),
    'want',  v_want,
    'found', coalesce(array_length(v_ids, 1), 0),
    'enough', coalesce(array_length(v_ids, 1), 0) >= v_want,
    'filled', v_fill,
    'paid',  app.has_active_subscription(v_acc));
end $function$;

CREATE OR REPLACE FUNCTION public.rpc_generate_test(p_rule jsonb, p_title text, p_test_id uuid DEFAULT NULL::uuid, p_account uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
declare
  v_uid   uuid := auth.uid();
  v_acc   uuid := app.pick_account(p_account);
  v_want  int  := least(greatest(coalesce((p_rule->>'count')::int, 10), 1), 100);
  v_pool  text := coalesce(p_rule->>'pool', 'all');
  v_ids   uuid[];
  v_fill  int;
  v_test  uuid := p_test_id;
  v_prog  uuid;
  v_subj  uuid;
  v_lev   uuid;
  v_done  int;
  i       int;
begin
  if v_pool in ('platform','all') and not app.has_active_subscription(v_acc) then
    raise exception 'Platformanin sual bankindan test yigmaq abune paketine daxildir. Oz suallarinizdan yiga bilersiniz.'
      using errcode = '42501';
  end if;

  -- ---- yeniden yigmaq: islenmis test DEYISMIR
  if v_test is not null then
    if not app.can_manage_test(v_test) then
      raise exception 'Bu test sizin deyil.' using errcode = '42501';
    end if;
    select count(*) into v_done from public.attempts
     where test_id = v_test and status = 'submitted';
    if v_done > 0 then
      raise exception 'Bu testi % sagird artiq isleyib - yenilemek olmaz. Yeni variant yaradin.',
        v_done using errcode = '42501';
    end if;
  end if;

  -- ---- suallari sec
  --  937: «Cetin» secilib, cetin sual catmir - eyni suzgecden «orta» ile tamamlanir
  select o_ids, o_filled into v_ids, v_fill from app.generate_pick_cetin(p_rule, v_acc);
  if coalesce(array_length(v_ids, 1), 0) < v_want then
    raise exception 'Bu suzgecle yalniz % ferqli sual tapildi (% istenilir). Suzgeci genislendirin ve ya sual sayini azaldin.',
      coalesce(array_length(v_ids, 1), 0), v_want using errcode = '22023';
  end if;

  -- ---- fenn / sinif
  select id into v_subj from public.subjects where slug = p_rule->>'subject';
  if v_subj is null then
    select q.subject_id into v_subj from public.questions q where q.id = v_ids[1];
  end if;
  --  Testin OZ sinfi: bir nece sinif secilibse EN YUXARISI.
  --  Sebeb: 8+7 testi 8-ci sinif testidir (7 tekrardir), ona gore
  --  rpc_available_tests onu 8-ci sinif qrupuna gostermelidir.
  select l.id into v_lev from public.levels l
   where l.code = coalesce(
           (select x from jsonb_array_elements_text(p_rule->'levels') x
             where x ~ '^[0-9]+$' order by x::int desc limit 1),
           p_rule->>'level')
   order by l.sort limit 1;
  select p.id into v_prog from public.programs p where p.slug = 'ibtidai';

  -- ---- test
  if v_test is null then
    insert into public.tests
      (owner_type, owner_id, program_id, subject_id, level_id, title,
       status, gen_rule, shuffle_questions, shuffle_options)
    values ('educator', v_uid, v_prog, v_subj, v_lev,
            coalesce(nullif(btrim(p_title), ''), 'Avtomatik test'),
            'published', p_rule, true, true)
    returning id into v_test;
  else
    update public.tests
       set title = coalesce(nullif(btrim(p_title), ''), title),
           subject_id = v_subj, level_id = v_lev, gen_rule = p_rule
     where id = v_test;
    delete from public.test_questions where test_id = v_test;
  end if;

  for i in 1 .. array_length(v_ids, 1) loop
    insert into public.test_questions (test_id, question_id, ord)
    values (v_test, v_ids[i], i);
  end loop;

  return jsonb_build_object('test_id', v_test, 'count', array_length(v_ids, 1),
                            'regenerated', p_test_id is not null, 'filled', v_fill);
end $function$;

revoke all on function public.rpc_generate_preview(jsonb, uuid) from public, anon;
grant execute on function public.rpc_generate_preview(jsonb, uuid) to authenticated;
revoke all on function public.rpc_generate_test(jsonb, text, uuid, uuid) from public, anon;
grant execute on function public.rpc_generate_test(jsonb, text, uuid, uuid) to authenticated;

do $$
begin
  if position('generate_pick_cetin' in pg_get_functiondef('public.rpc_generate_test(jsonb,text,uuid,uuid)'::regprocedure)) = 0
     or position('generate_pick_cetin' in pg_get_functiondef('public.rpc_generate_preview(jsonb,uuid)'::regprocedure)) = 0 then
    raise exception '937: rpc_generate_test / rpc_generate_preview teze funksiyani cagirmir';
  end if;
  raise notice '937 OK - «Çətin» catmayanda test orta suallarla tamamlanir.';
end $$;
