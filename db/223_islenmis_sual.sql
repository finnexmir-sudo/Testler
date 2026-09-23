-- =====================================================================
--  223 : ISLENMIS SUAL NOVBEDE GERI QALIR (2026-09-23)
--
--  NIYE
--  Generator tesadufi secir ve qrupa EVVEL verilmis suali xatirlamir.
--  Fesil hovuzu dardir - olculdu: derse orta 6.6 sual (ders_basina
--  hovuz.sql).  Ona gore ardicil derslerin testleri ust-uste dusur,
--  «tekrar yig» ise zeif sagirde demek olar eyni sualları qaytarir.
--  Bu, olcme deyil - yaddas yoxlamasidir.
--
--  NECE
--  Qaydaya «exclude» acari elave olunur: sual id-leri massivi.
--  DIQQET - bu SERT DEYIL, MEYILDIR.  Sert suzgec qoysaq, dar hovuzda
--  «kifayet sual yoxdur» xetasi cixardi (13_generator.sql:319) ve
--  muellim duymeni basib bos qayidardi.  Meyil ise teze sualı one
--  cekir, catmayanda kohnesini goturur - test HEMISE yigilir.
--
--  Siralama qaydasi: movzu balansi (rn_topic) > sehv-benzerlik (rem) >
--  tezelik (isk) > tesaduf.  «rem» oneden qalir, cunki tekrar testinde
--  sagirdin sehv etdiyi sual one cixmalidir, hetta evvel verilse de.
--
--  HARADAN DOLUR
--  rpc_plan_test qrupa SON 20 tapsiriqda verilmis sualları yigir.
--  Hədd var ki, il boyu yigilan minlerle id massivi sismesin.
--
--  TOXUNULAN: app.generate_pick (tam govde), rpc_plan_test (tam govde).
--  rpc_generate_test TOXUNULMUR - secim mentiqi onda deyil.
--  Qalan cagiris yerleri (isinme, ev tapsirigi, rub sinagi, diaqnostika,
--  adaptiv) «exclude» vermir - onlarda davranis HERFEN eskisi kimidir.
--
--  ON SERT: 13 (generator), 222 (ders testi).
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
  --  223: ISLENMIS SUALLAR.  Qayda «exclude» veribse, hemin suallar
  --  ATILMIR - sadece NOVBEDE GERI QALIR.  Sert yox, meyildir:
  --  hovuz dar olanda (fesilde derse 6.6 sual dusur) sert suzgec
  --  «kifayet sual yoxdur» xetasi verirdi; meyil ise teze sualı one
  --  cekir, catmayanda kohnesini goturur.  Test hemise yigilir.
  v_excl   uuid[] := (select array_agg(x::uuid)
                        from jsonb_array_elements_text(
                               coalesce(p_rule->'exclude', '[]'::jsonb)) x);
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
                                  order by m.rem desc, m.isk, random()) as rn_topic,
               random() as rnd, m.rem, m.isk
        from (
        select q.id, q.body, q.topic_id,
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
           and (p_rule->>'level'   is null or l.code = p_rule->>'level')
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
end $$;


-- ------------------------------------------------- plan testi
--  222-deki govde + «exclude».  TAM govde yazilir (marker uslubu yox).
create or replace function public.rpc_plan_test(
  p_item_id uuid, p_count int default 15)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_item   public.class_plan_items%rowtype;
  v_plan   public.class_plans%rowtype;
  v_topic  text;
  v_tid    uuid;
  v_slug   text;
  v_leaf   text;
  v_n      int := 0;
  v_ders   boolean := false;
  v_count  int;
  v_rule   jsonb;
  v_res    jsonb;
  v_test   uuid;
  v_excl   jsonb;
begin
  if p_count is null or p_count < 3 or p_count > 50 then
    raise exception 'Sual sayi 3-50 araliginda olmalidir.' using errcode = '22023';
  end if;
  select * into v_item from public.class_plan_items where id = p_item_id;
  if not found then
    raise exception 'Movzu tapilmadi.' using errcode = '22023';
  end if;
  select * into v_plan from public.class_plans where id = v_item.plan_id;
  perform app.plan_class(v_plan.class_id);
  if v_item.done_at is null then
    raise exception 'Evvel movzunu "kecildi" isareleyin.' using errcode = '22023';
  end if;

  --  Hovuz VALIDEYNDEDIR (101).  Alt movzunun oz slug-u nisan ucundur.
  select coalesce(par.id, t.id), coalesce(par.name, t.name), t.slug, t.name
    into v_tid, v_topic, v_slug, v_leaf
    from public.topics t
    left join public.topics par on par.id = t.parent_id
   where t.id = v_item.topic_id;

  --  Nisanli sual yeterlidirse DERS testi, deyilse kohne kimi FESIL.
  if v_slug is not null and v_slug <> '' then
    v_n := app.ders_sual_sayi(v_tid, v_slug);
    v_ders := v_n >= app.ders_min();
  end if;

  --  223: bu qrupa SON 20 tapsiriqda verilmis suallar.  Hedd var ki,
  --  il boyu yigilan minlerle id massivi sismesin.  Bu, SERT suzgec
  --  deyil - generator onlari sadece novbede geri qoyur.
  select coalesce(jsonb_agg(distinct tq.question_id::text), '[]'::jsonb)
    into v_excl
    from (select a.test_id from public.assignments a
           where a.class_id = v_plan.class_id
           order by a.created_at desc limit 20) z
    join public.test_questions tq on tq.test_id = z.test_id;

  if v_ders then
    --  Ders testi qisadir; hovuzdan cox istemirik ki generator
    --  «N sual tapildi» xetasi atmasin.
    v_count := least(app.ders_test_count(), v_n);
    v_rule := jsonb_build_object(
      'pool', 'all',
      'count', v_count,
      'subject', (select slug from public.subjects where id = v_plan.subject_id),
      'level',   (select code from public.levels   where id = v_plan.level_id),
      'topics',  jsonb_build_array(v_tid::text),
      'tags',    jsonb_build_array(app.ders_tag(v_slug)),
      'exclude', v_excl);
    v_res := public.rpc_generate_test(v_rule, v_leaf || ' — yoxlama');
  else
    v_count := p_count;
    v_rule := jsonb_build_object(
      'pool', 'all',
      'count', v_count,
      'subject', (select slug from public.subjects where id = v_plan.subject_id),
      'level',   (select code from public.levels   where id = v_plan.level_id),
      'topics',  jsonb_build_array(v_tid::text),
      'exclude', v_excl);
    v_res := public.rpc_generate_test(v_rule, v_topic || ' — yoxlama');
  end if;

  v_test := (v_res->>'test_id')::uuid;

  perform public.rpc_assign_test(
    v_plan.class_id, v_test, now() + interval '7 days', 1);

  update public.class_plan_items set test_id = v_test where id = p_item_id;

  --  'scope' interfeys ucundur: setir «dərs testi» yoxsa «fəsil
  --  testi» yigildigini yaza bilsin - muellim ne aldigini bilsin.
  return jsonb_build_object('ok', true, 'test_id', v_test,
                            'count', v_res->>'count',
                            'scope', case when v_ders then 'ders' else 'fesil' end,
                            'pool',  v_n);
end $$;

-- ------------------------------------------------- huquq
revoke all on function public.rpc_plan_test(uuid, int) from public, anon;
grant execute on function public.rpc_plan_test(uuid, int) to authenticated;
