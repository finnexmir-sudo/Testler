-- =====================================================================
--  03_rpc.sql : sagird terefi
--
--  Sagirdin auth hesabi yoxdur. O, anon acar ile gelir ve YALNIZ
--  bu funksiyalari cagira bilir. Butun funksiyalar SECURITY DEFINER-dir,
--  yeni RLS-i kecir - ona gore her biri icinde oz yoxlamasini edir.
--
--  Esas prinsip: duzgun cavab bazadan cixmir. Sagird cavablarini
--  gonderir, bal SERVERDE hesablanir. Frontend-de saxtakarliq mumkun deyil.
-- =====================================================================

-- ----------------------------------------------------------- sessiya
-- DIQQET: pgcrypto Supabase-de "extensions" sxemindedir, public-de yox.
-- search_path teyin edilmese digest() tapilmir ve butun sagird terefi
-- HTTP 404 verir. Bir defe bas verdi - tekrarlanmasin.
create or replace function app.hash_token(p_token text) returns text
language sql immutable
set search_path = public, extensions, pg_temp as $$
  select encode(digest(p_token, 'sha256'), 'hex')
$$;

create or replace function app.session_student(p_token text) returns uuid
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select s.student_id
    from public.student_sessions s
    join public.students st on st.id = s.student_id
   where s.token_hash = app.hash_token(p_token)
     and s.expires_at > now()
     and st.is_active
$$;

create or replace function app.gc_sessions() returns void
language sql security definer set search_path = public, extensions, pg_temp as $$
  delete from public.student_sessions where expires_at < now() - interval '1 day'
$$;

-- Sagird giris kodu ile daxil olur, qisa omurlu token alir.
create or replace function public.rpc_student_login(p_code text)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_student public.students%rowtype;
  v_token   text;
  v_class   public.classes%rowtype;
begin
  if p_code is null or length(btrim(p_code)) < 6 then
    return jsonb_build_object('ok', false, 'error', 'Kod qisadir.');
  end if;

  select * into v_student from public.students
   where login_code = upper(btrim(p_code)) and is_active;

  if not found then
    return jsonb_build_object('ok', false, 'error', 'Bele kod tapilmadi.');
  end if;

  select * into v_class from public.classes where id = v_student.class_id;

  v_token := encode(gen_random_bytes(32), 'hex');
  insert into public.student_sessions (token_hash, student_id, expires_at)
  values (app.hash_token(v_token), v_student.id, now() + interval '12 hours');

  return jsonb_build_object(
    'ok',      true,
    'token',   v_token,
    'student', jsonb_build_object(
                 'id',           v_student.id,
                 'display_name', v_student.display_name),
    'class',   case when v_class.id is null then null else jsonb_build_object(
                 'id',   v_class.id,
                 'name', v_class.name) end
  );
end $$;

-- --------------------------------------------------------- test siyahisi
-- Sagirde gorunen testler: derc olunmuş platforma testleri
-- + oz sinfine teyin olunmuş muellim/repetitor testleri.
create or replace function public.rpc_student_tests(p_token text)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_student uuid := app.session_student(p_token);
  v_class   uuid;
  v_account uuid;
  v_paid    boolean;
  v_free    boolean;
begin
  if v_student is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;
  select class_id, account_id into v_class, v_account
    from public.students where id = v_student;
  v_paid := app.has_active_subscription(v_account);

  select free_practice into v_free from public.classes where id = v_class;

  return jsonb_build_object(
    -- Muellimin teyin etdikleri
    'assigned', coalesce((
      select jsonb_agg(x order by (x->>'closes_at') nulls last, x->>'title')
      from (
        select jsonb_build_object(
                 'id',      t.id,
                 'title',   t.title,
                 'subject', sub.name,
                 'locked',  (not t.is_free and not v_paid),
                 'questions', (select count(*) from public.test_questions tq where tq.test_id = t.id),
                 'time_limit_sec', t.time_limit_sec,
                 'max_attempts',   a.max_attempts,
                 'closes_at',      a.closes_at,
                 'done', (select count(*) from public.attempts at
                           where at.test_id = t.id and at.student_id = v_student
                             and at.status = 'submitted'),
                 'best', (select round(max(at.percent), 0) from public.attempts at
                           where at.test_id = t.id and at.student_id = v_student
                             and at.status = 'submitted')
               ) as x
          from public.assignments a
          join public.tests t     on t.id = a.test_id and t.status = 'published'
          join public.subjects sub on sub.id = t.subject_id
         where a.class_id = v_class and app.assignment_open(a.*)
      ) z), '[]'::jsonb),

    -- Serbest mesq: yalniz qrup ayari acıq olanda
    'practice', case when not coalesce(v_free, true) then '[]'::jsonb else coalesce((
      select jsonb_agg(x order by x->>'subject', x->>'title')
      from (
        select jsonb_build_object(
                 'id',      t.id,
                 'title',   t.title,
                 'subject', sub.name,
                 'locked',  (not t.is_free and not v_paid),
                 'questions', (select count(*) from public.test_questions tq where tq.test_id = t.id),
                 'time_limit_sec', t.time_limit_sec,
                 'max_attempts',   t.max_attempts,
                 'done', (select count(*) from public.attempts at
                           where at.test_id = t.id and at.student_id = v_student
                             and at.status = 'submitted'),
                 'best', (select round(max(at.percent), 0) from public.attempts at
                           where at.test_id = t.id and at.student_id = v_student
                             and at.status = 'submitted')
               ) as x
          from public.tests t
          join public.subjects sub on sub.id = t.subject_id
         where t.status = 'published' and t.owner_type = 'platform'
           -- Teyin olunmuşdursa "Tapsiriqlar"da gorunur, burada tekrarlanmasin
           and not exists (select 1 from public.assignments a
                            where a.class_id = v_class and a.test_id = t.id
                              and app.assignment_open(a.*))
      ) z), '[]'::jsonb) end
  );
end $$;

-- --------------------------------------------------------- cehde baslamaq
-- Suallari duzgun cavab OLMADAN qaytarir.
create or replace function public.rpc_start_attempt(p_token text, p_test_id uuid)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
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
  select a.* into v_asg from public.assignments a
   where a.class_id = v_class and a.test_id = p_test_id
     and app.assignment_open(a.*);

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

  return jsonb_build_object(
    'attempt_id', v_attempt,
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
                 'body', q.body,
                 'media_url', q.media_url,
                 'options', coalesce((
                    select jsonb_agg(jsonb_build_object('id', o.id, 'body', o.body)
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
end $$;

-- ------------------------------------------------------- cehdi gondermek
--  p_answers formati:
--    [{"q":"<question uuid>","o":["<option uuid>", ...]},
--     {"q":"<question uuid>","t":"metn cavabi"}]
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

-- --------------------------------------------------- bitmis testin neticesi
--  Sagird bitirdiyi teste tekrar girende yeni cehd yox, EVVELKI neticesi
--  acilir. Cavab acari yene getmir - yalniz sehv suallar ve izahlar.
create or replace function public.rpc_test_result(p_token text, p_test_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
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
    'finished_at',  v_att.finished_at,
    'can_retry',    false,   -- baxis rejimi: cehd bitib
    'test', jsonb_build_object('id', v_test.id, 'title', v_test.title,
                               'pass_percent', v_test.pass_percent),
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

-- ------------------------------------------------------- liderler lovhesi
-- Yalniz oz sinfi/qrupu daxilinde, yalniz gorunen ad ve faiz.
create or replace function public.rpc_leaderboard(p_token text, p_test_id uuid, p_limit int default 20)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_student uuid := app.session_student(p_token);
  v_class   uuid;
begin
  if v_student is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;
  select class_id into v_class from public.students where id = v_student;
  if v_class is null then return '[]'::jsonb; end if;

  -- Her sagird lovhede BIR defe gorunur: en yaxsi neticesi ile.
  -- Eks halda testi iki defe islayen sagird iki setirde cixirdi.
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'rank',    z.rn,
             'name',    z.display_name,
             'percent', z.percent,
             'tries',   z.tries,
             'is_me',   z.student_id = v_student) order by z.rn)
    from (
      select b.display_name, b.student_id, b.percent, b.seconds, b.tries,
             row_number() over (order by b.percent desc, b.seconds asc) as rn
        from (
          select st.display_name,
                 a.student_id,
                 max(a.percent)                                   as percent,
                 min(a.duration_sec)                              as seconds,
                 count(*)                                         as tries
            from public.attempts a
            join public.students st on st.id = a.student_id
           where a.test_id = p_test_id and a.class_id = v_class
             and a.status = 'submitted'
           group by st.display_name, a.student_id
        ) b
    ) z
    where z.rn <= least(greatest(p_limit, 1), 100)
  ), '[]'::jsonb);
end $$;

-- ---------------------------------------------------------------- huquq
--  DIQQET: PostgREST EXECUTE huququ olmayan funksiyani "yoxdur" kimi
--  gosterir (HTTP 404, kod 42883). Yeni bu blok isləməzsə butun sagird
--  terefi yox olur - ona gore sertsizdir ve sonda ozunu yoxlayir.
revoke all on function public.rpc_student_login(text)                     from public;
revoke all on function public.rpc_student_tests(text)                     from public;
revoke all on function public.rpc_start_attempt(text, uuid)               from public;
revoke all on function public.rpc_submit_attempt(text, uuid, jsonb)       from public;
revoke all on function public.rpc_leaderboard(text, uuid, int)            from public;
revoke all on function public.rpc_test_result(text, uuid)                 from public;

grant execute on function public.rpc_student_login(text)               to anon, authenticated;
grant execute on function public.rpc_student_tests(text)               to anon, authenticated;
grant execute on function public.rpc_start_attempt(text, uuid)         to anon, authenticated;
grant execute on function public.rpc_submit_attempt(text, uuid, jsonb) to anon, authenticated;
grant execute on function public.rpc_leaderboard(text, uuid, int)      to anon, authenticated;
grant execute on function public.rpc_test_result(text, uuid)           to anon, authenticated;

do $$
declare bad text;
begin
  select string_agg(f, ', ') into bad from unnest(array[
    'public.rpc_student_login(text)',
    'public.rpc_student_tests(text)',
    'public.rpc_start_attempt(text, uuid)',
    'public.rpc_submit_attempt(text, uuid, jsonb)',
    'public.rpc_leaderboard(text, uuid, int)',
    'public.rpc_test_result(text, uuid)']) f
   where not has_function_privilege('anon', f, 'EXECUTE');
  if bad is not null then
    raise exception 'anon bu funksiyalari cagira bilmir: %', bad;
  end if;
  raise notice 'Sagird RPC-leri anon ucun acildi.';
end $$;
