-- =====================================================================
--  192_vaxtli_test.sql : vaxtli test - limit serverde
--
--  tests.time_limit_sec sutunu 01-den beri var idi, amma hec yerde
--  islemirdi: muellim qoya bilmirdi, sagird saat gormurdu, server
--  yoxlamirdi.  Rub sinagi vaxtsiz olmur.
--
--    rpc_test_time_limit(test, deq)  muellim oz testine limit qoyur
--    rpc_start_attempt -> remaining_sec   SERVER saati ile qalan saniye
--    rpc_submit_attempt: limit kecib -> timed_out; limit + 60 s guzest
--                        de kecib -> cavablar SAYILMIR (late)
--    rpc_test_result -> timed_out
--    attempts.timed_out  hesabatda «vaxt bitdi» nisani
--
--  Sagird terefde geri sayan saat ve 0-da avtomatik gonderme var; amma
--  qerar serverdedir - telefonun saati deyisdirile biler.
--  Govdeler pg_get_functiondef ile goturulub, yalniz gosterilen setirler
--  elave olunub.
-- =====================================================================

alter table public.attempts add column if not exists timed_out boolean not null default false;

create or replace function public.rpc_test_time_limit(p_test_id uuid, p_min int)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare v_sec int;
begin
  if not app.can_manage_test(p_test_id) then
    raise exception 'Bu test sizin deyil.' using errcode = '42501';
  end if;
  if p_min is null or p_min <= 0 then
    v_sec := null;
  elsif p_min > 180 then
    raise exception 'Vaxt limiti 180 dəqiqədən çox olmasın.' using errcode = '22023';
  else
    v_sec := p_min * 60;
  end if;
  update public.tests set time_limit_sec = v_sec where id = p_test_id;
  return jsonb_build_object('ok', true, 'time_limit_sec', v_sec);
end $$;
revoke all on function public.rpc_test_time_limit(uuid, int) from public, anon;
grant execute on function public.rpc_test_time_limit(uuid, int) to authenticated;

CREATE OR REPLACE FUNCTION public.rpc_start_attempt(p_token text, p_test_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
declare
  v_student uuid := app.session_student(p_token);
  v_class   uuid;
  v_account uuid;
  v_test    public.tests%rowtype;
  v_asg     public.assignments%rowtype;
  v_free    boolean;
  v_limit   int;
  v_done    int;
  v_attempt uuid;
  v_params  jsonb;
begin
  if v_student is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;
  select class_id, account_id into v_class, v_account
    from public.students where id = v_student;

  select * into v_test from public.tests where id = p_test_id and status = 'published';
  if not found then
    raise exception 'Test tapilmadi.' using errcode = '22023';
  end if;

  -- ACIQ teyinat varsa onun qaydalari isleyir.
  -- Vaxti bitmis teyinat testi bloklamir: test yeniden serbest mesq
  -- hovuzuna qayidir (rpc_student_tests de onu orada gosterir).
  --  28-den beri eyni test hem butun qrupa, hem de ayrica bir sagirde
  --  teyin oluna bilir - iki ACIQ setir.  Yalniz bu sagirde aid olanlar
  --  sayilir (basqasinin ferdi teyinati yox); ferdi olan ustundur.
  select a.* into v_asg from public.assignments a
   where a.class_id = v_class and a.test_id = p_test_id
     and (a.student_id is null or a.student_id = v_student)
     and app.assignment_open(a.*)
   order by a.student_id nulls last limit 1;

  if v_asg.id is not null then
    v_limit := v_asg.max_attempts;
  else
    -- Acıq teyinat yoxdur: serbest mesq yolu
    select free_practice into v_free from public.classes where id = v_class;
    if v_test.owner_type <> 'platform' then
      -- Muellimin oz testi yalniz teyinatla acilir
      if exists (select 1 from public.assignments a
                  where a.class_id = v_class and a.test_id = p_test_id) then
        raise exception 'Bu tapsirigin vaxti bitib.' using errcode = '42501';
      end if;
      raise exception 'Bu test sizin qrup ucun teyin olunmayib.' using errcode = '42501';
    end if;
    if not coalesce(v_free, true) then
      if exists (select 1 from public.assignments a
                  where a.class_id = v_class and a.test_id = p_test_id) then
        raise exception 'Bu tapsirigin vaxti bitib.' using errcode = '42501';
      end if;
      raise exception 'Muelliminiz serbest mesqi baglayib.' using errcode = '42501';
    end if;
    v_limit := v_test.max_attempts;
  end if;

  -- Odenis heddi
  if not v_test.is_free and not app.has_active_subscription(v_account) then
    raise exception 'Bu test abune paketine daxildir.' using errcode = '42501';
  end if;

  -- Cehd limiti
  if v_limit > 0 then
    select count(*) into v_done from public.attempts
     where student_id = v_student and test_id = p_test_id and status = 'submitted';
    if v_done >= v_limit then
      raise exception 'Bu testi artiq % defe islemisiniz.', v_done using errcode = '42501';
    end if;
  end if;

  -- Yarimciq qalmis cehd varsa onu davam etdiririk
  select id into v_attempt from public.attempts
   where student_id = v_student and test_id = p_test_id and status = 'in_progress'
   order by started_at desc limit 1;

  if v_attempt is null then
    insert into public.attempts (student_id, test_id, class_id)
    values (v_student, p_test_id, v_class)
    returning id into v_attempt;
  end if;

  --  132: sablon suallara BU cehd ucun qiymetler.  Bir defe secilir,
  --  davam etdirilen cehd eyni reqemleri gorur.  Evvel baslamis cehdde
  --  catismayan sual varsa yalniz o elave olunur.
  select params into v_params from public.attempts where id = v_attempt;
  select coalesce(v_params, '{}'::jsonb)
         || coalesce(jsonb_object_agg(q.id::text, app.pq_seed(q.params, q.id)), '{}'::jsonb)
    into v_params
    from public.test_questions tq
    join public.questions q on q.id = tq.question_id
   where tq.test_id = p_test_id and q.params is not null
     and not (coalesce(v_params, '{}'::jsonb) ? q.id::text);
  if v_params <> '{}'::jsonb then
    update public.attempts set params = v_params where id = v_attempt;
  end if;

  return jsonb_build_object(
    'attempt_id', v_attempt,
    --  192: vaxt limiti - qalan saniye SERVER saati ile (telefonun saati
    --  sehv olsa da duz). Yarimciq cehd davam edende de dogru qalir.
    'remaining_sec', case when v_test.time_limit_sec is null then null
                          else greatest(0, v_test.time_limit_sec - extract(epoch from (now() -
                                 (select a.started_at from public.attempts a where a.id = v_attempt)))::int) end,
    'test', jsonb_build_object(
              'id', v_test.id, 'title', v_test.title,
              'time_limit_sec', v_test.time_limit_sec,
              'pass_percent',   v_test.pass_percent),
    'questions', coalesce((
      select jsonb_agg(qq order by qq->>'ord')
      from (
        select jsonb_build_object(
                 'id',   q.id,
                 'ord',  case when v_test.shuffle_questions
                              then lpad((row_number() over (order by md5(q.id::text || v_attempt::text)))::text, 4, '0')
                              else lpad(tq.ord::text, 4, '0') end,
                 'kind', q.kind,
                 'body', app.pq_render(q.body, v_params->(q.id::text)),
                 'media_url', q.media_url,
                 'options', coalesce((
                    select jsonb_agg(jsonb_build_object('id', o.id,
                                        'body', app.pq_render(o.body, v_params->(q.id::text)))
                             order by case when v_test.shuffle_options
                                           then md5(o.id::text || v_attempt::text)
                                           else lpad(o.ord::text, 4, '0') end)
                      from public.question_options o
                     where o.question_id = q.id), '[]'::jsonb)
               ) as qq
          from public.test_questions tq
          join public.questions q on q.id = tq.question_id
         where tq.test_id = p_test_id
      ) z), '[]'::jsonb)
  );
end $function$;

CREATE OR REPLACE FUNCTION public.rpc_submit_attempt(p_token text, p_attempt_id uuid, p_answers jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
declare
  v_student uuid := app.session_student(p_token);
  v_att     public.attempts%rowtype;
  v_test    public.tests%rowtype;
  v_score   numeric(7,2) := 0;
  v_max     numeric(7,2) := 0;
  v_timed_out boolean := false;   -- 192
  v_late      boolean := false;   -- 192: guzest de kecib - cavablar sayilmir
  v_limit   int;
  r         record;
begin
  if v_student is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;

  select * into v_att from public.attempts
   where id = p_attempt_id and student_id = v_student;
  if not found then
    raise exception 'Cehd tapilmadi.' using errcode = '22023';
  end if;
  if v_att.status <> 'in_progress' then
    raise exception 'Bu cehd artiq baglanib.' using errcode = '42501';
  end if;

  select * into v_test from public.tests where id = v_att.test_id;
  --  192: vaxt limiti SERVERDE. Limit kecibse cehd «vaxt bitdi» kimi
  --  isarelenir; limit + 60 s (sebeke guzesti) de kecibse cavablar
  --  SAYILMIR - sagird telefonun saatini deyise biler, server saatini yox.
  if v_test.time_limit_sec is not null then
    v_timed_out := now() > v_att.started_at + make_interval(secs => v_test.time_limit_sec);
    if now() > v_att.started_at + make_interval(secs => v_test.time_limit_sec + 60) then
      v_late := true;
      p_answers := '[]'::jsonb;
    end if;
  end if;
  -- Cehd limiti teyinatdan gelir; teyinat yoxdursa testin ozunden
  --  Qrup + ferdi teyinat eyni vaxtda acıq ola biler - "more than one
  --  row returned by a subquery" vermesin: ferdi olan ustundur, bir setir.
  select coalesce((select a.max_attempts from public.assignments a
                    where a.class_id = v_att.class_id and a.test_id = v_att.test_id
                      and (a.student_id is null or a.student_id = v_student)
                      and app.assignment_open(a.*)
                    order by a.student_id nulls last limit 1),
                  v_test.max_attempts) into v_limit;

  -- Her sual uzre serverde yoxlanis
  for r in
    select q.id, q.kind, coalesce(tq.points, q.points) as points, q.topic_id,
           --  132: sagirdin GORDUYU (render olunmus) metn yazilir
           app.pq_render(q.body, v_att.params->(q.id::text)) as q_body,
           app.pq_render(q.explanation, v_att.params->(q.id::text)) as q_expl,
           coalesce((select array_agg(o.id order by o.id) from public.question_options o
                      where o.question_id = q.id and o.is_correct), '{}') as correct_ids,
           coalesce((select array_agg(lower(btrim(app.pq_render(o.body, v_att.params->(q.id::text)))))
                       from public.question_options o
                      where o.question_id = q.id and o.is_correct), '{}') as correct_texts,
           (select a from jsonb_array_elements(coalesce(p_answers,'[]'::jsonb)) a
             where a->>'q' = q.id::text limit 1) as ans
      from public.test_questions tq
      join public.questions q on q.id = tq.question_id
     where tq.test_id = v_att.test_id
  loop
    declare
      v_sel  uuid[] := '{}';
      v_txt  text;
      v_ok   boolean := false;   -- null = cavab verilmeyib
      v_sec  int;                -- sualda kecirilen saniye (tetbiq gonderir)
      v_sure boolean;            -- "eminem" (true) / "emin deyilem" (false)
    begin
      v_max := v_max + r.points;

      if r.ans is not null then
        --  128: cavab terzi.  Olmasa null - kohne tetbiq de isleyir.
        if (r.ans->>'s') ~ '^[0-9]+$' then
          v_sec := least(3600, (r.ans->>'s')::int);
        end if;
        if r.ans ? 'c' and jsonb_typeof(r.ans->'c') = 'boolean' then
          v_sure := (r.ans->>'c')::boolean;
        end if;
        if r.ans ? 'o' then
          select coalesce(array_agg((e)::uuid order by (e)::uuid), '{}') into v_sel
            from jsonb_array_elements_text(r.ans->'o') e
           where e ~ '^[0-9a-fA-F-]{36}$';
        end if;
        v_txt := nullif(btrim(coalesce(r.ans->>'t','')), '');
      end if;

      if r.ans is null or (array_length(v_sel,1) is null and v_txt is null) then
        --  Sagird bu suala HEC TOXUNMAYIB.  "Sehv cavab verdi" ile eyni
        --  sey deyil - hesabatda ayrilsin deye null yazilir.  Bal yene 0.
        v_ok := null;
      elsif r.kind = 'text' then
        v_ok := v_txt is not null and lower(v_txt) = any (r.correct_texts);
      else
        v_ok := array_length(r.correct_ids,1) is not null
                and v_sel @> r.correct_ids and r.correct_ids @> v_sel;
      end if;

      if v_ok is true then v_score := v_score + r.points; end if;

      --  Sualin metni de yazilir: muellim sonradan sual redakte etse,
      --  bu hesabat hele de sagirdin GORDUYU sual gosterecek.
      insert into public.attempt_answers
        (attempt_id, question_id, topic_id, selected_option_ids, text_answer,
         is_correct, points, question_body, question_explanation, seconds, sure)
      values
        (p_attempt_id, r.id, r.topic_id, v_sel, v_txt, v_ok,
         case when v_ok is true then r.points else 0 end, r.q_body, r.q_expl,
         v_sec, v_sure)
      on conflict (attempt_id, question_id) do update
        set selected_option_ids = excluded.selected_option_ids,
            text_answer         = excluded.text_answer,
            is_correct          = excluded.is_correct,
            points              = excluded.points,
            question_body        = excluded.question_body,
            question_explanation = excluded.question_explanation,
            seconds             = excluded.seconds,
            sure                = excluded.sure,
            answered_at         = now();
    end;
  end loop;

  update public.attempts
     set status       = 'submitted',
         timed_out    = v_timed_out,
         finished_at  = now(),
         duration_sec = greatest(0, extract(epoch from (now() - started_at))::int),
         score        = v_score,
         max_score    = v_max,
         percent      = case when v_max > 0 then round(v_score * 100 / v_max, 2) else 0 end
   where id = p_attempt_id
   returning * into v_att;

  return jsonb_build_object(
    'attempt_id',   v_att.id,
    'timed_out',    v_att.timed_out,
    'late',         v_late,
    'score',        v_att.score,
    'max_score',    v_att.max_score,
    'percent',      v_att.percent,
    'passed',       v_att.percent >= v_test.pass_percent,
    'duration_sec', v_att.duration_sec,
    'diagnostic',   v_test.is_diagnostic,
    'topics',       app.diag_student_map(v_att.id, v_test.is_diagnostic),
    -- "Bir de cehd ede bilersen" yazisi ucun: hele cehd qalibmi?
    'can_retry',    v_limit = 0 or
                    (select count(*) from public.attempts a2
                      where a2.student_id = v_student and a2.test_id = v_att.test_id
                        and a2.status = 'submitted') < v_limit,
    'questions', coalesce((
      --  Suret: sagird hansi sual gorubse, onu gosteririk.
      --  Sual sonradan redakte olunsa da bu netice deyismir.
      --  "picked" - sagirdin sectiyi variantIN METNI (testi yazarken
      --  artiq gorub - yeni sizinti yoxdur).  Hansi variantin DOGRU
      --  oldugu (is_correct) heç vaxt qayıtmır - 116_sagird_tam_netice.sql-
      --  deki eyni qayda burada da isleyir.
      select jsonb_agg(x order by tq.ord)
        from public.attempt_answers aa
        join public.test_questions tq
          on tq.test_id = v_att.test_id and tq.question_id = aa.question_id
        cross join lateral (
          select jsonb_build_object(
                   'question_id', aa.question_id,
                   'body',        aa.question_body,
                   'explanation', aa.question_explanation,
                   'correct',     aa.is_correct,
                   --  Metn tipli sual variant deyil, yazi qebul edir -
                   --  onda selected_option_ids bosdur, text_answer dolur.
                   'picked',      case
                     when aa.text_answer is not null and aa.text_answer <> ''
                       then jsonb_build_array(aa.text_answer)
                     else coalesce((
                       select jsonb_agg(app.pq_render(o.body, v_att.params->(aa.question_id::text)) order by o.ord)
                         from public.question_options o
                        where o.id = any(aa.selected_option_ids)), '[]'::jsonb)
                   end
                 ) as x
        ) q
       where aa.attempt_id = v_att.id), '[]'::jsonb)
  );
end $function$;

CREATE OR REPLACE FUNCTION public.rpc_test_result(p_token text, p_test_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
declare
  v_student uuid := app.session_student(p_token);
  v_att  public.attempts%rowtype;
  v_test public.tests%rowtype;
begin
  if v_student is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;

  select * into v_att from public.attempts
   where student_id = v_student and test_id = p_test_id and status = 'submitted'
   order by percent desc, finished_at desc
   limit 1;
  if not found then
    raise exception 'Bu testin neticesi tapilmadi.' using errcode = '22023';
  end if;

  select * into v_test from public.tests where id = p_test_id;

  return jsonb_build_object(
    'attempt_id',   v_att.id,
    'score',        v_att.score,
    'max_score',    v_att.max_score,
    'percent',      v_att.percent,
    'passed',       v_att.percent >= v_test.pass_percent,
    'duration_sec', v_att.duration_sec,
    'timed_out',    v_att.timed_out,
    'finished_at',  v_att.finished_at,
    'can_retry',    false,   -- baxis rejimi: cehd bitib
    'diagnostic',   v_test.is_diagnostic,
    'topics',       app.diag_student_map(v_att.id, v_test.is_diagnostic),
    'test', jsonb_build_object('id', v_test.id, 'title', v_test.title,
                               'pass_percent', v_test.pass_percent),
    'questions', coalesce((
      --  Suret: sagird hansi sual gorubse, onu gosteririk.
      --  Sual sonradan redakte olunsa da bu netice deyismir.
      --  "picked" - sagirdin sectiyi variantIN METNI, o cavabi
      --  testi yazarken artiq gorub - burda YENI heç nə sızmır.
      --  Hansi variantin DOGRU oldugu (is_correct) heç vaxt qayıtmır.
      select jsonb_agg(x order by tq.ord)
        from public.attempt_answers aa
        join public.test_questions tq
          on tq.test_id = v_att.test_id and tq.question_id = aa.question_id
        cross join lateral (
          select jsonb_build_object(
                   'question_id', aa.question_id,
                   'body',        aa.question_body,
                   'explanation', aa.question_explanation,
                   'correct',     aa.is_correct,
                   --  Metn tipli sual variant deyil, yazi qebul edir -
                   --  onda selected_option_ids bosdur, text_answer dolur.
                   'picked',      case
                     when aa.text_answer is not null and aa.text_answer <> ''
                       then jsonb_build_array(aa.text_answer)
                     else coalesce((
                       select jsonb_agg(app.pq_render(o.body, v_att.params->(aa.question_id::text)) order by o.ord)
                         from public.question_options o
                        where o.id = any(aa.selected_option_ids)), '[]'::jsonb)
                   end
                 ) as x
        ) q
       where aa.attempt_id = v_att.id), '[]'::jsonb)
  );
end $function$;

--  rpc_test_preview: vereq limiti gorsun (govde pg_get_functiondef-den, bir setir elave)
CREATE OR REPLACE FUNCTION public.rpc_test_preview(p_test_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
declare
  v jsonb;
  v_acc    uuid;
  v_class  uuid;
  v_wrongs text[] := null;
begin
  if not app.can_manage_test(p_test_id) then
    raise exception 'Bu test sizin deyil.' using errcode = '42501';
  end if;

  --  Test sehv-cutlesdirme ile yigilibsa, veraqda "sehve benzer"
  --  nisani gosterilir.  Qrup yeniden yoxlanir - qayda kohne ola biler.
  select nullif(t.gen_rule->>'class', '')::uuid into v_class
    from public.tests t where t.id = p_test_id;
  if v_class is not null then
    v_acc := app.pick_account(null);
    if exists (select 1 from public.classes c
                where c.id = v_class and c.account_id = v_acc) then
      select array_agg(w.b) into v_wrongs from (
        select distinct app.norm_body(coalesce(nullif(aa.question_body, ''), q.body)) b
          from public.attempt_answers aa
          join public.attempts a  on a.id = aa.attempt_id and a.status = 'submitted'
          join public.students st on st.id = a.student_id and st.class_id = v_class
          left join public.questions q on q.id = aa.question_id
         where aa.is_correct = false
         limit 300) w;
    end if;
  end if;

  select jsonb_build_object(
    'time_limit_sec', t.time_limit_sec,   -- 192: vereqde limit gorunsun
    'id', t.id, 'title', t.title, 'gen_rule', t.gen_rule,
    'subject', s.name, 'level', l.name,
    'done', (select count(*) from public.attempts a
              where a.test_id = t.id and a.status = 'submitted'),
    'questions', coalesce((
      select jsonb_agg(jsonb_build_object(
               'ord',  tq.ord,
               'id',   q.id,
               'body', app.pq_render(q.body, pv.v),
               'media_url', q.media_url,
               'tpl',  q.params is not null,
               'kind', q.kind,
               'difficulty', q.difficulty,
               'topic', tp.name,
               'explanation', app.pq_render(q.explanation, pv.v),
               'mine', q.owner_type = 'educator',
               'remedial', (v_wrongs is not null and exists (
                  select 1 from unnest(v_wrongs) w
                   where similarity(app.norm_body(q.body), w) >= app.rem_similarity())),
               'options', coalesce((
                  select jsonb_agg(jsonb_build_object(
                           'body', app.pq_render(o.body, pv.v), 'correct', o.is_correct) order by o.ord)
                    from public.question_options o
                   where o.question_id = q.id), '[]'::jsonb)
             ) order by tq.ord)
        from public.test_questions tq
        join public.questions q on q.id = tq.question_id
        left join public.topics tp on tp.id = q.topic_id
        --  132: vereq bir variantdir - her acilisda teze qiymet
        cross join lateral (select app.pq_seed(q.params, q.id) as v) pv
       where tq.test_id = t.id), '[]'::jsonb)
  ) into v
   from public.tests t
   join public.subjects s on s.id = t.subject_id
   left join public.levels l on l.id = t.level_id
  where t.id = p_test_id;
  return v;
end $function$;
