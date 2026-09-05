-- =====================================================================
--  128  CAVAB TERZI ("telesik sehv", "emin deyilem") ve "NE EDIM" SETRI
--
--  Yol xeritesi 22c ve 20d.
--  1. attempt_answers.seconds / sure: sagird tetbiqi her cavabla sualda
--     kecirilen saniyeni (s) ve "eminem/emin deyilem" (c) gonderir.
--     Kohne tetbiq gondermese null - hec ne sinmir.
--  2. rpc_submit_attempt (123 uzerinde) onlari yazir.
--  3. rpc_student_report (27 uzerinde): 'style' - hasty (sehv ve
--     <= app.hasty_sec() saniye), guess_ok (duz amma emin deyildi),
--     sure_wrong (sehv amma emin idi); 'weak' setirlerinde hasty/sure_wrong.
--  4. rpc_class_report (08 uzerinde): her movzuda 'weak_students' -
--     qrup hesabatinin ustundeki "Bu hefte: 3 sagirde X tekrar ver" setri.
-- =====================================================================

alter table public.attempt_answers add column if not exists seconds int;
alter table public.attempt_answers add column if not exists sure boolean;

--  "telesik" heddi: bu qeder saniyeden az vaxtda verilen SEHV cavab
create or replace function app.hasty_sec() returns int
language sql immutable as $$ select 5 $$;
revoke all on function app.hasty_sec() from public, anon, authenticated;

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
                       select jsonb_agg(o.body order by o.ord)
                         from public.question_options o
                        where o.id = any(aa.selected_option_ids)), '[]'::jsonb)
                   end
                 ) as x
        ) q
       where aa.attempt_id = v_att.id), '[]'::jsonb)
  );
end $$;


create or replace function public.rpc_student_report(p_student_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_st    public.students%rowtype;
  v_paid  boolean;
  v_since timestamptz;
begin
  if not app.can_read_student(p_student_id) then
    raise exception 'Bu sagirdin hesabatina giris huququnuz yoxdur.' using errcode = '42501';
  end if;
  select * into v_st from public.students where id = p_student_id;

  v_paid  := app.has_active_subscription(v_st.account_id);
  v_since := case when v_paid then '-infinity'::timestamptz
                  else now() - (app.free_history_days() || ' days')::interval end;

  return jsonb_build_object(
    'paid', v_paid,
    'since', case when v_paid then null else v_since end,
    'min_answers', app.min_topic_answers(),
    'student', jsonb_build_object(
                 'id', v_st.id, 'full_name', v_st.full_name,
                 'display_name', v_st.display_name, 'login_code', v_st.login_code),

    'summary', (
      select jsonb_build_object(
               'attempts', count(*),
               'avg',      round(coalesce(avg(percent), 0), 1),
               'best',     round(coalesce(max(percent), 0), 1),
               'minutes',  round(coalesce(sum(duration_sec), 0) / 60.0, 0))
        from public.attempts
       where student_id = p_student_id and status = 'submitted'
         and finished_at >= v_since),

    --  128: cavab terzi.  Saniye ve "eminem" yalniz yeni tetbiqden gelir;
    --  melumat yoxdursa hamisi 0 - UI karti gizledir (n_meta = 0).
    'style', (
      select jsonb_build_object(
               'n_meta',     count(*) filter (where aa.seconds is not null),
               'hasty',      count(*) filter (where aa.is_correct is false
                                               and aa.seconds is not null and aa.seconds <= app.hasty_sec()),
               'guess_ok',   count(*) filter (where aa.is_correct is true and aa.sure is false),
               'sure_wrong', count(*) filter (where aa.is_correct is false and aa.sure is true),
               'n_sure',     count(*) filter (where aa.sure is not null))
        from public.attempt_answers aa
        join public.attempts a on a.id = aa.attempt_id
       where a.student_id = p_student_id and a.status = 'submitted'
         and a.finished_at >= v_since),

    'attempts', coalesce((
      select jsonb_agg(x order by x->>'at' desc)
      from (
        select jsonb_build_object(
                 'id',       a.id,
                 'at',       a.finished_at,
                 'test',     t.title,
                 'score',    a.score,
                 'max',      a.max_score,
                 'percent',  round(a.percent, 0),
                 'seconds',  a.duration_sec) as x
          from public.attempts a
          join public.tests t on t.id = a.test_id
         where a.student_id = p_student_id and a.status = 'submitted'
           and a.finished_at >= v_since
         order by a.finished_at desc
         limit 30
      ) z), '[]'::jsonb),

    -- Movzu uzre menimseme - YALNIZ odenisli.  Esik YOXDUR: 1 cavab da
    -- gorunur, "az melumat" qerarini UI min_answers ile verir.
    'topics', case when not v_paid then null else coalesce((
      select jsonb_agg(y order by (y->>'ratio')::numeric, y->>'name')
      from (
        select jsonb_build_object(
                 'id',      t.id,
                 'name',    t.name,
                 'subject', sub.name,
                 'subject_slug', sub.slug,
                 'level',   lv.code,
                 'total',   count(*),
                 'correct', count(*) filter (where aa.is_correct),
                 'ratio',   round(count(*) filter (where aa.is_correct) * 100.0 / count(*), 1)) as y
          from public.attempt_answers aa
          join public.attempts a on a.id = aa.attempt_id
                                and a.student_id = p_student_id
                                and a.status = 'submitted'
                                and a.finished_at >= v_since
          join public.topics t   on t.id = aa.topic_id
          left join public.levels lv on lv.id = t.level_id
          join public.subjects sub on sub.id = t.subject_id
         group by t.id, t.name, sub.name, sub.slug, lv.code
      ) z), '[]'::jsonb) end,

    -- Tekrar sehv edilen suallar - YALNIZ odenisli
    'weak', case when not v_paid then null else coalesce((
      select jsonb_agg(y order by (y->>'wrong')::int desc)
      from (
        select jsonb_build_object(
                 'qid',         aa.question_id,
                 'body',        aa.question_body,
                 'explanation', aa.question_explanation,
                 'topic',       min(tp.name),
                 'wrong',       count(*),
                 --  128: bu sualdaki sehvlerin necesi telesik / emin idi
                 'hasty',       count(*) filter (where aa.seconds is not null and aa.seconds <= app.hasty_sec()),
                 'sure_wrong',  count(*) filter (where aa.sure is true)) as y
          from public.attempt_answers aa
          join public.attempts a on a.id = aa.attempt_id
                                and a.student_id = p_student_id
                                and a.status = 'submitted'
                                and a.finished_at >= v_since
          left join public.topics tp on tp.id = aa.topic_id
         where aa.is_correct is not true
         group by aa.question_id, aa.question_body, aa.question_explanation
         order by count(*) desc
         limit 10
      ) z), '[]'::jsonb) end
  );
end $$;


create or replace function public.rpc_class_report(p_class_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid   uuid := auth.uid();
  v_class public.classes%rowtype;
  v_paid  boolean;
  v_since timestamptz;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;

  select * into v_class from public.classes where id = p_class_id;
  if not found then
    raise exception 'Qrup tapilmadi.' using errcode = '22023';
  end if;
  if v_class.teacher_id <> v_uid
     and not app.is_account_member(v_class.account_id)
     and not app.is_admin() then
    raise exception 'Bu qrupun hesabatina giris huququnuz yoxdur.' using errcode = '42501';
  end if;

  v_paid  := app.has_active_subscription(v_class.account_id);
  v_since := case when v_paid then '-infinity'::timestamptz
                  else now() - (app.free_history_days() || ' days')::interval end;

  return jsonb_build_object(
    'paid',  v_paid,
    'since', case when v_paid then null else v_since end,
    'class', jsonb_build_object('id', v_class.id, 'name', v_class.name),

    -- Umumi gostericiler
    'summary', (
      select jsonb_build_object(
               'students',  (select count(*) from public.students s
                              where s.class_id = p_class_id and s.is_active),
               'attempts',  count(*),
               'avg',       round(coalesce(avg(a.percent), 0), 1),
               'active',    count(distinct a.student_id))
        from public.attempts a
        join public.students s on s.id = a.student_id
       where s.class_id = p_class_id and a.status = 'submitted'
         and a.finished_at >= v_since),

    -- Sagird uzre xulase
    'students', coalesce((
      select jsonb_agg(x order by x->>'full_name')
      from (
        select jsonb_build_object(
                 'id',           s.id,
                 'full_name',    s.full_name,
                 'display_name', s.display_name,
                 'attempts',     count(a.id),
                 'avg',          round(coalesce(avg(a.percent), 0), 1),
                 'best',         round(coalesce(max(a.percent), 0), 1),
                 'last_at',      max(a.finished_at)
               ) as x
          from public.students s
          left join public.attempts a
                 on a.student_id = s.id and a.status = 'submitted'
                and a.finished_at >= v_since
         where s.class_id = p_class_id and s.is_active
         group by s.id, s.full_name, s.display_name
      ) z), '[]'::jsonb),

    -- Movzu analizi - YALNIZ odenisli
    'topics', case when not v_paid then null else coalesce((
      select jsonb_agg(y order by (y->>'ratio')::numeric, y->>'name')
      from (
        --  subject_slug ve level "duzelis testi" duymesi ucundur:
        --  generator fenn+sinifi avtomatik doldursun, muellim yalniz
        --  "Testi yig" bassin.
        select jsonb_build_object(
                 'id',      t.id,
                 'name',    t.name,
                 'subject', sub.name,
                 'subject_slug', sub.slug,
                 'level',   lv.code,
                 'total',   count(*),
                 'correct', count(*) filter (where aa.is_correct),
                 'ratio',   round(count(*) filter (where aa.is_correct) * 100.0 / count(*), 1),
                 --  128: "ne edim" setri ucun - bu movzuda zeif sagirdler
                 --  (her biri ucun >= min cavab, < 60%)
                 'weak_students', coalesce((
                    select jsonb_agg(jsonb_build_object('id', w.id, 'name', w.full_name)
                                     order by w.ratio, w.full_name)
                      from (
                        select s2.id, s2.full_name,
                               count(*) filter (where aa2.is_correct) * 100.0 / count(*) ratio
                          from public.attempt_answers aa2
                          join public.attempts a2 on a2.id = aa2.attempt_id and a2.status = 'submitted'
                                                 and a2.finished_at >= v_since
                          join public.students s2 on s2.id = a2.student_id
                                                 and s2.class_id = p_class_id and s2.is_active
                         where aa2.topic_id = t.id
                         group by s2.id, s2.full_name
                        having count(*) >= app.min_topic_answers()
                           and count(*) filter (where aa2.is_correct) * 100.0 / count(*) < 60
                      ) w), '[]'::jsonb)
               ) as y
          from public.attempt_answers aa
          join public.attempts a  on a.id = aa.attempt_id and a.status = 'submitted'
                                 and a.finished_at >= v_since
          join public.students s  on s.id = a.student_id and s.class_id = p_class_id
          join public.topics   t  on t.id = aa.topic_id
          left join public.levels lv on lv.id = t.level_id
          join public.subjects sub on sub.id = t.subject_id
         group by t.id, t.name, sub.name, sub.slug, lv.code
        having count(*) >= app.min_topic_answers()
      ) z), '[]'::jsonb) end,

    -- Son fealiyyet
    'recent', coalesce((
      select jsonb_agg(r order by r->>'at' desc)
      from (
        select jsonb_build_object(
                 'at',      a.finished_at,
                 'student', s.display_name,
                 'test',    t.title,
                 'percent', round(a.percent, 0)) as r
          from public.attempts a
          join public.students s on s.id = a.student_id and s.class_id = p_class_id
          join public.tests    t on t.id = a.test_id
         where a.status = 'submitted' and a.finished_at >= v_since
         order by a.finished_at desc
         limit 15
      ) z), '[]'::jsonb)
  );
end $$;

