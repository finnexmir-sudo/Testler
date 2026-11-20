-- =====================================================================
--  937 : TEST SEVIYYESI - «Qarışıq / Daha asan / Daha çətin»  (2026-11-20, istifadeci)
--
--  PROBLEM
--  Test yig-da «Asan / Orta / Çətin» FILTR idi: «Çətin» yalniz difficulty = 3
--  suallari goturur.  Bazada 10-dan az cetin sual olan fesil cox: Ingilis dili 63,
--  Azerbaycan dili 59, Heyat bilgisi 22, Riyaziyyat 21 (Az 10-11-de cetin 0-1).
--  Bele movzuda «Çətin» test yiga bilmirdi.
--
--  HELL - filtr yox, SIRALAMA (qayda acari 'level_mode'):
--    mixed  (susmaya gore) - indiki balans, hec ne deyismir;
--    harder - movzu daxilinde cetinliye gore azalan (3, 2, 1), yuxaridan lazim olan say;
--    easier - artan (1, 2, 3).
--  Movzuda kifayet qeder sual varsa test HEMISE yigilir.  Eyni seviyye daxilinde
--  generatorun qaydalari OLDUGU KIMI: sehve benzeyen one (rem), bu qrupa verilmis
--  arxaya (exclude/isk), tesaduf; tekrar suzgeci (pg_trgm >= 0.95) ve eyni duz
--  cavab limiti secim dovrunde.  Bir nece movzuda balans qalir (siralama her
--  movzunun ICINDE, movzular novbe ile).
--  Kohne 'difficulty' MASSIVI (filtr) daxili cagirislar ucun qalir (paket, kohne
--  testlerin «Yenidən yığ»-i) - toxunulmur.
--  rpc_generate_preview / rpc_generate_test elave 'mix' qaytarir: {hard, mid, easy}.
--
--  generate_pick-in govdesi 929-dan (canli versiya) HERFEN, yalniz v_mode, siralama
--  acari ve q.difficulty secimi elave olunub.  RPC govdeleri de canlidan herfen.
--  ON SERT: 13, 103, 223, 929.   Tekrar isledile biler.   Supabase: temp / begin yoxdur.
-- =====================================================================

CREATE OR REPLACE FUNCTION app.generate_pick(p_rule jsonb, p_account uuid)
 RETURNS uuid[]
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
declare
  v_want   int  := least(greatest(coalesce((p_rule->>'count')::int, 10), 1), 100);
  v_pool   text := coalesce(p_rule->>'pool', 'all');
  v_paid   boolean := app.has_active_subscription(p_account);
  v_out    uuid[] := '{}';
  v_bodies text[] := '{}';
  v_ans    text[] := '{}';
  v_ansmax int;
  r        record;
  v_dup    boolean;
  i        int;
  --  SEHV CUTLESDIRME: qayda "class" veribse, hemin qrupun sehv
  --  cavablandigi suallarin metnleri yigilir; hovuzda onlara QELIBCE
  --  benzeyen suallar movzu daxilinde one kecir.  Muellim gorur ki,
  --  sistem uşagin buraxdigi sehvleri teqib edir.
  v_class  uuid   := nullif(p_rule->>'class', '')::uuid;
  v_wrongs text[] := null;
  --  223: ISLENMIS SUALLAR.  Qayda «exclude» veribse, hemin suallar
  --  ATILMIR - sadece NOVBEDE GERI QALIR.  Sert yox, meyildir:
  --  hovuz dar olanda (fesilde derse 6.6 sual dusur) sert suzgec
  --  «kifayet sual yoxdur» xetasi verirdi; meyil ise teze sualı one
  --  cekir, catmayanda kohnesini goturur.  Test hemise yigilir.
  v_excl   uuid[] := (select array_agg(x::uuid)
                        from jsonb_array_elements_text(
                               coalesce(p_rule->'exclude', '[]'::jsonb)) x);
  --  937: SEVIYYE REJIMI.  'harder' - movzu daxilinde evvel 3, sonra 2, sonra 1;
  --  'easier' - eksine; 'mixed' (ve ya yoxdur) - indiki balans.  Filtr DEYIL, siralamadir:
  --  hovuzda sual varsa test hemise yigilir.  Eyni seviyye daxilinde qaydalar eynidir
  --  (sehve benzeyen one, verilmis arxaya, tesaduf); tekrar suzgecleri (>= 0.95, eyni cavab) dovrdedir.
  v_mode   int := case p_rule->>'level_mode' when 'harder' then -1 when 'easier' then 1 else 0 end;
begin
  --  Platformanin hovuzu abune telebidir; oz suallarin her zaman acıq
  if v_pool in ('platform','all') and not v_paid then
    v_pool := 'mine';
  end if;

  if v_class is not null then
    if not exists (select 1 from public.classes c
                    where c.id = v_class and c.account_id = p_account) then
      raise exception 'Bu qrup sizin deyil.' using errcode = '42501';
    end if;
    select array_agg(w.b) into v_wrongs from (
      --  Cavab aninda saxlanan SURET esasdir - sual sonradan deyisse de
      --  sagirdin gorduyu metn qalir
      select distinct app.norm_body(coalesce(nullif(aa.question_body, ''), q.body)) b
        from public.attempt_answers aa
        join public.attempts a   on a.id = aa.attempt_id and a.status = 'submitted'
        join public.students st  on st.id = a.student_id and st.class_id = v_class
        left join public.questions q on q.id = aa.question_id
       where aa.is_correct = false
       limit 300) w;
  end if;

  --  Eyni cavab en coxu bu qeder tekrarlana biler (20 sualda 3)
  v_ansmax := greatest(2, ceil(v_want / 7.0)::int);

  for r in
    --  Movzular arasinda BERABER: her movzudan novbe ile goturulur,
    --  eks halda tesaduf 20 sualin 19-unu bir movzudan gotura biler.
    select z.id, z.body, z.answer
      from (
        select m.id, m.body, m.answer,
               --  Movzu daxilinde sehve benzeyenler ONE kecir; balans
               --  yene movzular arasindadir (rn_topic novbesi qalir)
               --  223: «isk» rem-den SONRA gelir - tekrar testinde
               --  sagirdin sehv etdiyi sual one cixmalidir, hetta
               --  evvel verilmis olsa da.  Tezelik ikinci meyardir.
               row_number() over (partition by m.topic_id
                                  order by v_mode * m.difficulty, m.rem desc, m.isk, random()) as rn_topic,
               random() as rnd, m.rem, m.isk
        from (
        select q.id, q.body, q.topic_id, q.difficulty,
               --  223: bu sual bu qrupa artiq verilibmi
               (v_excl is not null and q.id = any(v_excl)) as isk,
               coalesce((select string_agg(lower(btrim(o.body)), '|' order by o.body)
                           from public.question_options o
                          where o.question_id = q.id and o.is_correct), '') as answer,
               (v_wrongs is not null and exists (
                  select 1 from unnest(v_wrongs) w
                   where similarity(app.norm_body(q.body), w) >= app.rem_similarity()
                )) as rem
          from public.questions q
          join public.subjects s on s.id = q.subject_id
          left join public.levels l on l.id = q.level_id
         where q.status = 'published'
           and (case v_pool
                  when 'mine'     then q.account_id = p_account
                  when 'platform' then q.owner_type = 'platform'
                  else q.account_id = p_account or q.owner_type = 'platform' end)
           and (p_rule->>'subject' is null or s.slug = p_rule->>'subject')
           --  929: sinif suzgeci - 'levels' MASSIVI (103) ve ya 'level' tek deyeri.
           --  223 bu bloku kohne tek-'level' setri ile evez etmisdi: iki sinif
           --  secilende qaydada 'level' olmur, sual BUTUN siniflerden gelirdi.
           and (case
                  when jsonb_typeof(p_rule->'levels') = 'array'
                       and p_rule->'levels' <> '[]'::jsonb
                    then l.code in (select jsonb_array_elements_text(p_rule->'levels'))
                  when p_rule->>'level' is not null
                    then l.code = p_rule->>'level'
                  else true
                end)
           and (p_rule->'topics' is null or jsonb_array_length(p_rule->'topics') = 0
                or q.topic_id::text in (select jsonb_array_elements_text(p_rule->'topics')))
           and (p_rule->'difficulty' is null or jsonb_array_length(p_rule->'difficulty') = 0
                or q.difficulty::text in (select jsonb_array_elements_text(p_rule->'difficulty')))
           and (p_rule->>'quarter' is null or q.quarter = (p_rule->>'quarter')::int)
           and (p_rule->>'month'   is null or q.month   = (p_rule->>'month')::int)
           and (p_rule->'tags' is null or jsonb_array_length(p_rule->'tags') = 0
                or q.tags @> (select array_agg(x)
                                from jsonb_array_elements_text(p_rule->'tags') x))
           --  Sualsiz test olmaz
           and exists (select 1 from public.question_options o
                        where o.question_id = q.id and o.is_correct)
        ) m
      ) z
     order by z.rn_topic, z.rem desc, z.isk, z.rnd
  loop
    exit when array_length(v_out, 1) >= v_want;

    --  Acgoz suzgec: yerdeyismis tekrari at (>= 0.95).
    --  Bu hedd OLCULEREK secilib - asagisi qanuni suallari atirdi.
    v_dup := false;
    if array_length(v_bodies, 1) is not null then
      for i in 1 .. array_length(v_bodies, 1) loop
        if similarity(v_bodies[i], r.body) >= 0.95 then
          v_dup := true; exit;
        end if;
      end loop;
    end if;

    --  Eyni duzgun cavab hedden cox tekrarlanmasin - riyaziyyatda
    --  esl tekrar siqnali metn yox, CAVABDIR.
    if not v_dup and r.answer <> '' then
      if (select count(*) from unnest(v_ans) a where a = r.answer) >= v_ansmax then
        v_dup := true;
      end if;
    end if;

    if not v_dup then
      v_out    := v_out    || r.id;
      v_bodies := v_bodies || r.body;
      v_ans    := v_ans    || r.answer;
    end if;
  end loop;

  return v_out;
end $function$;

CREATE OR REPLACE FUNCTION public.rpc_generate_preview(p_rule jsonb, p_account uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
declare
  v_acc  uuid := app.pick_account(p_account);
  v_ids  uuid[];
  v_want int := least(greatest(coalesce((p_rule->>'count')::int, 10), 1), 100);
begin
  v_ids := app.generate_pick(p_rule, v_acc);
  return jsonb_build_object(
    'want',  v_want,
    'found', coalesce(array_length(v_ids, 1), 0),
    'enough', coalesce(array_length(v_ids, 1), 0) >= v_want,
    --  937: secilen suallarin terkibi - panel «Testdə: X çətin, Y orta, Z asan» yazir
    'mix',   (select jsonb_build_object(
                      'hard', count(*) filter (where q.difficulty = 3),
                      'mid',  count(*) filter (where q.difficulty = 2),
                      'easy', count(*) filter (where q.difficulty not in (2, 3)))
                 from public.questions q where q.id = any(v_ids)),
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
  v_ids := app.generate_pick(p_rule, v_acc);
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
                            'regenerated', p_test_id is not null,
                            --  937: terkib (vereq de ozu sayir - bu, yalniz cavabda)
                            'mix', (select jsonb_build_object(
                      'hard', count(*) filter (where q.difficulty = 3),
                      'mid',  count(*) filter (where q.difficulty = 2),
                      'easy', count(*) filter (where q.difficulty not in (2, 3)))
                 from public.questions q where q.id = any(v_ids)));
end $function$;

revoke all on function app.generate_pick(jsonb, uuid) from public, anon, authenticated;
revoke all on function public.rpc_generate_preview(jsonb, uuid) from public, anon;
grant execute on function public.rpc_generate_preview(jsonb, uuid) to authenticated;
revoke all on function public.rpc_generate_test(jsonb, text, uuid, uuid) from public, anon;
grant execute on function public.rpc_generate_test(jsonb, text, uuid, uuid) to authenticated;
--  evvelki 937 qaralamasi (canliya getmeyib) - yerli bazalarda qalibsa
drop function if exists app.generate_pick_cetin(jsonb, uuid);

do $$
begin
  if position('level_mode' in pg_get_functiondef('app.generate_pick(jsonb,uuid)'::regprocedure)) = 0
     or position('p_rule->''levels''' in pg_get_functiondef('app.generate_pick(jsonb,uuid)'::regprocedure)) = 0
     or position('''mix''' in pg_get_functiondef('public.rpc_generate_test(jsonb,text,uuid,uuid)'::regprocedure)) = 0
     or position('''mix''' in pg_get_functiondef('public.rpc_generate_preview(jsonb,uuid)'::regprocedure)) = 0 then
    raise exception '937: generate_pick / rpc_generate_* yenilenmeyib';
  end if;
  raise notice '937 OK - test seviyyesi: Qarışıq / Daha asan / Daha çətin.';
end $$;
