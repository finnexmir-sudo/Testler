-- =====================================================================
--  900_netice_sekli.sql — SEKILLI SUALIN SEKLI NETICEDE VE HESABATDA
--
--  BOSLUQ.  Bankda qrafikli (SVG) suallar coxalir.  Sekil
--  questions.media_url-dadir ve ARTIQ gorunur: sagird testi yazarken
--  (rpc_start_attempt), sehv defterinde, movzu mesqinde, gunluk 5
--  sualda.  UC yerde ise gorunmurdu:
--    1. Sagirdin NETICE ekrani - testi bitirende (rpc_submit_attempt)
--       ve sonradan baxanda (rpc_test_result).  Sagird qrafiksiz
--       «Sən yazdın: 1-ci qrafik» oxuyurdu.
--    2. Muellimin sagird hesabati - 'weak' siyahisi
--       (rpc_student_report): en cox sehv edilen suallar.
--
--  UCUNCU TAPINTI (bu isin yanisi).  Yoxlayanda e2e_sekil.py «kagiz
--  vereqde sekil var» yoxlamasi UGURSUZ cixdi: db/224 (vereqde vaxt
--  limiti) rpc_test_preview govdesini pg_get_functiondef-den goturende
--  'media_url' setrini ITIRMISDI - mehz 188-in xeberdarliq etdiyi tele.
--  Yeni muellimin kagiz vereqinde sekil ARTIQ gorunmurdu.  Bu fayl onu
--  da qaytarir (224-un vaxt limiti oldugu kimi qalir).
--
--  NIYE EVVEL EDILMEMISDI (1-2).  db/188 bu uc funksiyani QESDLE kenarda
--  qoymusdu: onlar sual metnini ANLIQ NUSXEDEN goturur
--  (attempt_answers.question_body) - yeni cehd anindaki vəziyyəti.
--  Sekli orada gostermek ucun ya sekli de nusxeye yazmaq, ya da suala
--  qosulmaq lazim idi; 188 «bal tarixcesine toxunan qerardir» deyib
--  saxlamisdi.
--
--  SECILEN YOL: SUALA QOSULMAQ (left join public.questions).
--  Sebeb:
--    * Sxem deyismir - attempt_answers-e yeni sutun yazilmir, kohne
--      cehdler ucun de sekil derhal isleyir (geriye dogru).
--    * Yazma yolu (submit) agirlasmir - hər cavabla 24 KB SVG
--      kopyalanmir.  Baza olcusu db/179-da olculur.
--    * media_url YALNIZ platforma sualinda ola biler (188-deki CHECK)
--      ve platforma suali muellim terefinden redakte olunmur - yeni
--      «sagird baska sekil gorur» riski demek olar yoxdur.
--  ODENIS: bank sonradan hemin sualin SVG-sini deyisse, kohne netice
--  yeni sekli gosterecek (metn ise kohne qalacaq - o, nusxedendir).
--  Bilerekden qebul olunur: sekil sualin izahidir, cavab deyil.
--  Sual TAM silinse, left join null verir - ekran sekilsiz acilir.
--
--  TEHLUKESIZLIK.  question_options.is_correct YENE qaytarilmir - bu
--  fayl yalniz bir sahe elave edir.  Sekil ekranda <img src> ile
--  cizilir (innerHTML-e dusmur) ve unvan suzgecinden kecir - 188-deki
--  iki qat qoruma oldugu kimi qalir.
--
--  USUL.  Dord govde MOVCUD fayllardan proqramla goturulub (192, 133,
--  224), elle kocurulmeyib; her birine yalniz elave setirler qoyulub.  MARKER usulu
--  ISLEDILMIR - o, db/211-de canlida sindi (CLAUDE.md).
--  Imza deyismir, ona gore 05_grants.sql lazim deyil.
--
--  ICINDE DORD FUNKSIYA VAR: rpc_submit_attempt, rpc_test_result,
--  rpc_student_report, rpc_test_preview.
--
--  CANLIYA: bu fayl tek basina isledilir.  Bank terefindeki db/308
--  (qrafik oxuma pilotu) bundan SONRA yuklenir.
-- =====================================================================

--  ---- rpc_submit_attempt (govde 192-den, iki setir elave)
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
        --  900: sekil ANLIQ NUSXEDE yoxdur (attempt_answers yalniz metni
        --  saxlayir), ona gore suala qosuluruq.  left join - sual silinse
        --  de netice ekrani acilir, sadece sekilsiz.
        left join public.questions qq on qq.id = aa.question_id
        cross join lateral (
          select jsonb_build_object(
                   'question_id', aa.question_id,
                   'body',        aa.question_body,
                   'media_url',   qq.media_url,
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

--  ---- rpc_test_result (govde 192-den, iki setir elave)
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
        --  900: sekil ANLIQ NUSXEDE yoxdur (attempt_answers yalniz metni
        --  saxlayir), ona gore suala qosuluruq.  left join - sual silinse
        --  de netice ekrani acilir, sadece sekilsiz.
        left join public.questions qq on qq.id = aa.question_id
        cross join lateral (
          select jsonb_build_object(
                   'question_id', aa.question_id,
                   'body',        aa.question_body,
                   'media_url',   qq.media_url,
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

--  ---- rpc_student_report (govde 133-den, iki setir elave)
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

    --  129: sehv defteri sayğaclari
    'mistakes', (
      select jsonb_build_object(
               'open',   count(*) filter (where m.status = 'open'),
               'review', count(*) filter (where m.status = 'review'),
               'closed', count(*) filter (where m.status = 'closed'))
        from public.mistakes m where m.student_id = p_student_id),

    --  133: movzu mesqi - menimsenilib / davam edir, son 6 movzu
    'practice', (
      select jsonb_build_object(
               'mastered', count(*) filter (where p.mastered_at is not null),
               'active',   count(*) filter (where p.mastered_at is null and p.answered > 0),
               'answered', coalesce(sum(p.answered), 0),
               'items', coalesce((
                 select jsonb_agg(jsonb_build_object(
                          'topic', t.name, 'score', p2.score, 'answered', p2.answered,
                          'mastered', p2.mastered_at is not null, 'at', p2.updated_at)
                        order by p2.updated_at desc)
                   from (select * from public.practice p3
                          where p3.student_id = p_student_id and p3.answered > 0
                          order by p3.updated_at desc limit 6) p2
                   join public.topics t on t.id = p2.topic_id), '[]'::jsonb))
        from public.practice p where p.student_id = p_student_id),

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
                 --  900: sekil sualdan gelir (nusxede saxlanmir).  Qruplasma
                 --  onsuz da question_id uzredir - min() tek deyeri qaytarir,
                 --  "group by"-a toxunmaq lazim deyil.
                 'media_url',   min(qq.media_url),
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
          left join public.questions qq on qq.id = aa.question_id
         where aa.is_correct is not true
         group by aa.question_id, aa.question_body, aa.question_explanation
         order by count(*) desc
         limit 10
      ) z), '[]'::jsonb) end
  );
end $$;

--  ---- rpc_test_preview (govde 224-den, itmis setir qaytarilir)
create or replace function public.rpc_test_preview(p_test_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
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
    'id', t.id, 'title', t.title, 'gen_rule', t.gen_rule,
    'subject', s.name, 'level', l.name,
    --  224: VAXT LIMITI.  192 bu imkani elave etdi, amma bu RPC-ye
    --  yazmadi - muellim 5 deq secirdi, baza yazirdi, ekran ise
    --  gostermirdi (sahe undefined idi).  Uc yer birden bos qalirdi:
    --  veraq basligi, «vaxtsiz» cipi, cap basligi.  Sagird terefi
    --  islyirdi, cunki o, sutunu cedvelden birbasa oxuyur.
    'time_limit_sec', t.time_limit_sec,
    'done', (select count(*) from public.attempts a
              where a.test_id = t.id and a.status = 'submitted'),
    'questions', coalesce((
      select jsonb_agg(jsonb_build_object(
               'ord',  tq.ord,
               'id',   q.id,
               'body', app.pq_render(q.body, pv.v),
               --  900: bu setir db/224-de ITMISDI (govde pg_get_functiondef-den
               --  goturulende sual sekli ile birlikde dusmusdu) - qaytarilir.
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
end $$;
