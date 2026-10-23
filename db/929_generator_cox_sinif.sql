-- =====================================================================
--  929 : GENERATOR - COX SINIF SUZGECI QAYIDIR  (2026-10-23)
--
--  PROBLEM (UX yoxlamasi, 23.10)
--  Test yig ekraninda iki sinif secilende (9 + 10) teste 1, 5, 6, 8, 11-ci
--  sinif suallari dusurdu: 10 sualdan 4-u 9-10-cu sinifden idi.  Ekran ise
--  «2 sinif arasinda beraber paylanir» yazirdi.
--
--  SEBEB
--  103 app.generate_pick-e 'levels' MASSIVI suzgecini elave etmisdi.  223
--  (islenmis sual) funksiyanin TAM govdesini yeniden yazanda hemin bloku
--  kohne setirle evez etdi:  (p_rule->>'level' is null or l.code = ...).
--  Panel iki sinifde 'level' gondermir (yalniz 'levels'), ona gore suzgec
--  hec ne suzmurdu.
--
--  HELL
--  223-un govdesi HERFEN saxlanir, yalniz sinif setri 103-deki case ile
--  evez olunur ('levels' massiv deyilse - kohne davranis).  Tek sinif
--  ('level') ve sinifsiz qaydalar deyismir.
--
--  ON SERT: 13 (generator), 103 (cox sinif), 223 (generate_pick).
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
end $$;

do $$
begin
  --  ozunu yoxlama: funksiya 'levels' acarini taniyir
  if position('p_rule->''levels''' in pg_get_functiondef('app.generate_pick(jsonb,uuid)'::regprocedure)) = 0 then
    raise exception '929: generate_pick levels suzgecini tanimir';
  end if;
  raise notice '929 OK - generate_pick yeniden levels massivi ile suzur.';
end $$;
