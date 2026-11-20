-- =====================================================================
--  938 : «DAHA ÇƏTİN / DAHA ASAN» REAL ÇETINLIYE GORE (stats.p) + ADMIN
--        «ETIKET ↔ REAL» SIYAHISI  (2026-11-20, istifadeci)
--
--  1. SIRALAMA.  937 movzu daxilinde etikete (difficulty) gore siralayirdi.
--     Indi sualin cavab sayi n >= 30 olanda REAL duz cavab faizi (question_stats.p)
--     isledilir; az cavabli sualda etiket bankin oz qaydasi ile p-ye cevrilir
--     (plan/az_cetin_yeni_yol.md: p < 40 -> 3, 40-75 -> 2, > 75 -> 1; zolagin ortasi):
--       3 -> 20,  2 -> 57.5,  1 -> 87.5.
--     «Daha çətin» - p-si EN ASAGI olan evvel; «Daha asan» - eksine; «Qarışıq» deyismir.
--     Eyni qaydalar (sehve benzeyen, verilmis arxaya, tesaduf, tekrar suzgeci) olduğu kimi.
--     «Testdə: X çətin…» terkibi ETIKETLE qalir (vereq de etiketi gosterir) - bank etiketi
--     duzeldende avtomatik uygunlasir.
--  2. STATISTIKANIN TEZELIYI.  question_stats evvel yalniz admin ekrani acilanda yenilenirdi.
--     rpc_qstat_tick (anon, gunluk is axini oyaq-saxla.yml cagirir): son yenilemeden 20 saat
--     kecibse app.qstat_refresh(), yoxsa hec ne - tekrar cagiris bazani yormur.
--  3. ADMIN: rpc_admin_qlabels - n >= 30 olub etiketi p zolagina uymayan suallar
--     (meselen difficulty = 3, p > 75) ve 'cetin-namized' nisanlilar AYRICA (teklif olunan
--     son etiket ile; n < 30 olanlar «gozleyir» sayilir).  Bank etiketi ext_key ile duzeldir.
--
--  generate_pick-in govdesi 937-den HERFEN, yalniz statistika birlesmesi ve siralama acari.
--  ON SERT: 134 (question_stats), 207 (qstat_refresh), 937.   Tekrar isledile biler.
-- =====================================================================

create or replace function app.qlabel_min_n() returns int
language sql immutable as $$ select 30 $$;
revoke all on function app.qlabel_min_n() from public, anon, authenticated;

--  p (faiz) -> bankin etiket zolagi
create or replace function app.qlabel_band(p_p numeric) returns smallint
language sql immutable as $$
  select case when p_p is null then null when p_p < 40 then 3 when p_p <= 75 then 2 else 1 end::smallint $$;
revoke all on function app.qlabel_band(numeric) from public, anon, authenticated;

--  siralama ucun «gozlenen duz faizi»: n >= 30 - real p, yoxsa etiketin zolaq ortasi
create or replace function app.qhard_p(p_diff smallint, p_n int, p_p numeric) returns numeric
language sql immutable as $$
  select case when coalesce(p_n, 0) >= app.qlabel_min_n() and p_p is not null then p_p
              else case p_diff when 3 then 20 when 1 then 87.5 else 57.5 end end $$;
revoke all on function app.qhard_p(smallint, int, numeric) from public, anon, authenticated;

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
                                  order by v_mode * (100 - m.hk), m.rem desc, m.isk, random()) as rn_topic,
               random() as rnd, m.rem, m.isk
        from (
        select q.id, q.body, q.topic_id, q.difficulty,
               --  938: gozlenen duz faizi - n >= 30 real p, yoxsa etiketin zolaq ortasi
               app.qhard_p(q.difficulty, qs.n, qs.p) as hk,
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
          left join public.question_stats qs on qs.question_id = q.id
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

revoke all on function app.generate_pick(jsonb, uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------
--  2. Statistikanin gunluk yenilenmesi (anon, ozu-ozunu mehdudlasdirir)
-- ---------------------------------------------------------------------
create or replace function public.rpc_qstat_tick()
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare v_at timestamptz; v_n int;
begin
  select max(computed_at) into v_at from public.question_stats;
  if v_at is not null and v_at > now() - interval '20 hours' then
    return jsonb_build_object('refreshed', false, 'at', v_at);
  end if;
  --  eyni anda iki cagiris - biri hesablayir, o biri gozlemir
  if not pg_try_advisory_xact_lock(hashtext('qstat_tick')) then
    return jsonb_build_object('refreshed', false, 'busy', true);
  end if;
  v_n := app.qstat_refresh();
  return jsonb_build_object('refreshed', true, 'rows', v_n, 'at', now());
end $$;
revoke all on function public.rpc_qstat_tick() from public;
grant execute on function public.rpc_qstat_tick() to anon, authenticated;

-- ---------------------------------------------------------------------
--  3. Admin: etiket ↔ real cetinlik
-- ---------------------------------------------------------------------
create or replace function public.rpc_admin_qlabels(p_limit int default 200)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare v_lim int := least(greatest(coalesce(p_limit, 200), 1), 1000);
begin
  if not app.admin_ok() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;
  return (
    with r as (
      select q.id, q.ext_key, q.difficulty, s.n, s.p, app.qlabel_band(s.p) band,
             ('cetin-namized' = any(q.tags)) nam,
             left(regexp_replace(q.body, '\s+', ' ', 'g'), 160) body,
             sj.name subject, lv.name lvl, t.name topic
        from public.questions q
        join public.subjects sj on sj.id = q.subject_id
        left join public.levels lv on lv.id = q.level_id
        left join public.topics t on t.id = q.topic_id
        left join public.question_stats s on s.question_id = q.id
       where q.status = 'published' and q.owner_type = 'platform'
    )
    select jsonb_build_object(
      'computed_at', (select max(computed_at) from public.question_stats),
      'min_n', app.qlabel_min_n(),
      'rated', (select count(*) from r where r.n >= app.qlabel_min_n()),
      'mismatch_n', (select count(*) from r where not r.nam and r.n >= app.qlabel_min_n() and r.band <> r.difficulty),
      'mismatch', coalesce((
        select jsonb_agg(jsonb_build_object('id', x.id, 'ext_key', x.ext_key, 'difficulty', x.difficulty,
                 'n', x.n, 'p', x.p, 'band', x.band, 'body', x.body,
                 'where', concat_ws(' · ', x.subject, x.lvl, x.topic))
               order by abs(x.band - x.difficulty) desc, x.n desc)
          from (select * from r where not r.nam and r.n >= app.qlabel_min_n() and r.band <> r.difficulty
                 order by abs(r.band - r.difficulty) desc, r.n desc limit v_lim) x), '[]'::jsonb),
      'namized_wait', (select count(*) from r where r.nam and coalesce(r.n, 0) < app.qlabel_min_n()),
      'namized', coalesce((
        select jsonb_agg(jsonb_build_object('id', x.id, 'ext_key', x.ext_key, 'difficulty', x.difficulty,
                 'n', x.n, 'p', x.p, 'band', x.band, 'body', x.body,
                 'where', concat_ws(' · ', x.subject, x.lvl, x.topic))
               order by x.p, x.n desc)
          from (select * from r where r.nam and r.n >= app.qlabel_min_n() order by r.p limit v_lim) x), '[]'::jsonb))
  );
end $$;
revoke all on function public.rpc_admin_qlabels(int) from public, anon;
grant execute on function public.rpc_admin_qlabels(int) to authenticated;

do $$
begin
  if position('qhard_p' in pg_get_functiondef('app.generate_pick(jsonb,uuid)'::regprocedure)) = 0
     or position('level_mode' in pg_get_functiondef('app.generate_pick(jsonb,uuid)'::regprocedure)) = 0 then
    raise exception '938: generate_pick statistika ile yenilenmeyib';
  end if;
  raise notice '938 OK - «Daha çətin / asan» n >= 30 olanda real p ile; admin etiket siyahisi.';
end $$;
