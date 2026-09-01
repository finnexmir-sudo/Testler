-- =====================================================================
--  104_cavabsiz_sual.sql — cavabsiz qalan sual "sehv" sayilmasin
--
--  NIYE
--  rpc_submit_attempt iki fayldadir: 03_rpc.sql (dogru, teze) ve
--  11_sual_banki.sql (kohne surət).  Fayllar hansi sira ile islenirse,
--  AXIRINCI qalir.  Teze baza qurulanda 03 axirda olur, tarixi
--  ardicilliqla gedilende ise 11 axirda qalir - ve o zaman KOHNE
--  govde qayidir.  Ferq kicik gorunur, amma neticeye tesir edir:
--
--      kohne:  toxunulmamis sual  ->  is_correct = false  ("sehv")
--      teze:   toxunulmamis sual  ->  is_correct = null   ("bos")
--
--  Hesabatda "sehv basa dusdu" ile "vaxti catmadi" bir-birinden
--  ayrilmalidir; muellim ikisine ayri reaksiya verir.  Bal ikisinde
--  de sifirdir - yeni bal hesablanmasi DEYISMIR.
--
--  NE EDIRIK
--  Govdeni 03_rpc.sql-den oldugu kimi burada tekrarlayiriq.  Bu fayl
--  siranin SONUNDA islediyi ucun hansi yolla gelinmesinden asili
--  olmayaraq dogru govde qalir.  Fayl proqramla yaradilib - əl ile
--  kocurulmeyib, ona gore iki govde arasinda ferq ola bilmez.
--
--  KOHNE CEHDLERE TOXUNMURUQ
--  Artiq yazilmis attempt_answers setirleri oldugu kimi qalir: kecmis
--  neticeni sonradan deyismek muellimin gorduyu hesabati pozardi.
--  Yalniz bundan sonraki cehdler duzgun yazilacaq.
-- =====================================================================

create or replace function public.rpc_submit_attempt(
  p_token text, p_attempt_id uuid, p_answers jsonb)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_student uuid := app.session_student(p_token);
  v_att     public.attempts%rowtype;
  v_test    public.tests%rowtype;
  v_score   numeric(7,2) := 0;
  v_max     numeric(7,2) := 0;
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
  -- Cehd limiti teyinatdan gelir; teyinat yoxdursa testin ozunden
  select coalesce((select a.max_attempts from public.assignments a
                    where a.class_id = v_att.class_id and a.test_id = v_att.test_id
                      and app.assignment_open(a.*)),
                  v_test.max_attempts) into v_limit;

  -- Her sual uzre serverde yoxlanis
  for r in
    select q.id, q.kind, coalesce(tq.points, q.points) as points, q.topic_id,
           q.body as q_body, q.explanation as q_expl,
           coalesce((select array_agg(o.id order by o.id) from public.question_options o
                      where o.question_id = q.id and o.is_correct), '{}') as correct_ids,
           coalesce((select array_agg(lower(btrim(o.body))) from public.question_options o
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
    begin
      v_max := v_max + r.points;

      if r.ans is not null then
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
         is_correct, points, question_body, question_explanation)
      values
        (p_attempt_id, r.id, r.topic_id, v_sel, v_txt, v_ok,
         case when v_ok is true then r.points else 0 end, r.q_body, r.q_expl)
      on conflict (attempt_id, question_id) do update
        set selected_option_ids = excluded.selected_option_ids,
            text_answer         = excluded.text_answer,
            is_correct          = excluded.is_correct,
            points              = excluded.points,
            question_body        = excluded.question_body,
            question_explanation = excluded.question_explanation,
            answered_at         = now();
    end;
  end loop;

  update public.attempts
     set status       = 'submitted',
         finished_at  = now(),
         duration_sec = greatest(0, extract(epoch from (now() - started_at))::int),
         score        = v_score,
         max_score    = v_max,
         percent      = case when v_max > 0 then round(v_score * 100 / v_max, 2) else 0 end
   where id = p_attempt_id
   returning * into v_att;

  return jsonb_build_object(
    'attempt_id',   v_att.id,
    'score',        v_att.score,
    'max_score',    v_att.max_score,
    'percent',      v_att.percent,
    'passed',       v_att.percent >= v_test.pass_percent,
    'duration_sec', v_att.duration_sec,
    -- "Bir de cehd ede bilersen" yazisi ucun: hele cehd qalibmi?
    'can_retry',    v_limit = 0 or
                    (select count(*) from public.attempts a2
                      where a2.student_id = v_student and a2.test_id = v_att.test_id
                        and a2.status = 'submitted') < v_limit,
    'wrong', coalesce((
      --  Suret: sagird hansi sual gorubse, onu gosteririk.
      --  Sual sonradan redakte olunsa da bu netice deyismir.
      select jsonb_agg(jsonb_build_object('question_id', aa.question_id,
                                          'body', aa.question_body,
                                          'explanation', aa.question_explanation))
        from public.attempt_answers aa
       where aa.attempt_id = v_att.id and aa.is_correct is not true), '[]'::jsonb)
  );
end $$;

-- --------------------------------------------------------------- huquq
--  "create or replace" huquqlari saxlayir, amma fayl tek-basina
--  isledile bilsin deye burada da yazilir.
revoke all on function public.rpc_submit_attempt(text, uuid, jsonb) from public;
grant execute on function public.rpc_submit_attempt(text, uuid, jsonb)
  to anon, authenticated;

-- --------------------------------------------------------------- yoxlama
do $x$
declare v_def text;
begin
  select pg_get_functiondef(p.oid) into v_def
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'rpc_submit_attempt';
  if v_def not like '%v_ok := null;%' then
    raise exception 'cavabsiz sual hele de "sehv" yazilir';
  end if;
  raise notice 'rpc_submit_attempt tezelendi: cavabsiz sual null yazilir.';
end $x$;
