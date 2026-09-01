-- =====================================================================
--  103_cox_sinif.sql — test yiganda BIR NECE sinif secmek
--
--  NIYE
--  Generatorda sinif secimi TEK secimli idi: ya bir sinif, ya
--  "Hamisi".  Ortasi yox idi.  Repetitor 8-ci sinfi hazirlayarken
--  7-ci sinfin materialini da qatmaq isteyende ya ayrica test
--  yigmali, ya da suzgeci tam acib 1-11-i qarisdirmali idi.
--
--  Indi qayda 'levels' MASSIVI qebul edir: ["8","7"].
--
--  BALANS - bilerekden CEKI QOYULMUR.  Generator suallari movzular
--  arasinda BERABER paylayir; muellim 8 ve 7-ni bilerekden secirse,
--  beraber paylama onun seciminin durust oxunusudur.  "Cari sinif
--  agir, asagilar yungul" kimi gizli ceki muellimin gormediyi sehrdir -
--  o, ne secdiyini ekranda gorur ve neticeni gozleyir.
--
--  KOHNE QAYDALAR POZULMUR.  Movcud testlerin gen_rule-unda 'level'
--  tek deyer kimi durur ("yenile" duymesi onu tekrar isledir), ona
--  gore filtr HER IKI formani taniyir.
--
--  BU FAYL 13_generator.sql-DEN PROQRAMLA CIXARILIB - iki funksiyanin
--  govdesi herfen eynidir, yalniz iki setir deyisib (sinif suzgeci ve
--  testin oz sinfi).  Elle kocurulmeyib ki, tesadufen basqa şey
--  deyismesin.
-- =====================================================================

create or replace function app.generate_pick(p_rule jsonb, p_account uuid)
returns uuid[]
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
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
               row_number() over (partition by m.topic_id
                                  order by m.rem desc, random()) as rn_topic,
               random() as rnd, m.rem
        from (
        select q.id, q.body, q.topic_id,
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
           --  Sinif suzgeci: 'levels' MASSIVI (yeni) ve ya 'level'
           --  tek deyeri (kohne qaydalar).  Ikisi de yoxdursa suzmur.
           and (case
                  when p_rule->'levels' is not null
                       and jsonb_array_length(p_rule->'levels') > 0
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
     order by z.rn_topic, z.rem desc, z.rnd
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
end $$;

create or replace function public.rpc_generate_test(
  p_rule    jsonb,
  p_title   text,
  p_test_id uuid default null,       -- verilibse YENIDEN yigilir
  p_account uuid default null)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
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
                            'regenerated', p_test_id is not null);
end $$;

-- --------------------------------------------------------------- huquq
revoke all on function public.rpc_generate_test(jsonb, text, uuid, uuid) from public, anon;
grant execute on function public.rpc_generate_test(jsonb, text, uuid, uuid) to authenticated;

do $$
begin
  if has_function_privilege('anon',
      'public.rpc_generate_test(jsonb, text, uuid, uuid)', 'EXECUTE') then
    raise exception 'anon test yiga bilir';
  end if;
  raise notice 'Cox sinif secimi quruldu: qayda artiq levels massivini taniyir.';
end $$;
