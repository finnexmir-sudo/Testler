-- =====================================================================
--  932 : GEDISAT - BIR DUSTUR  (2026-10-23, Sira 2.3)
--
--  PROBLEM (UX yoxlamasi, 23.10)
--  Eyni gunde eyni sagird: Siqnallarda «geriləyir 77% → 60%», sagird kartinda
--  yasil «↗ +10», valideyn panelinde «keçən aya görə 20% yaxşılaşıb».  Dord
--  ayri dustur idi:
--    Siqnallar (rpc_home.alerts)   son 3 test / ondan evvelki 3 test
--    sagird karti «↗»  (panel)     son 30 gunun ILK 3 testi / SON 3 testi
--    valideyn (rpc_parent_home)    son 30 gunun ortasi / evvelki 30 gunun ortasi
--    valideyn metni (panel)        son 30 gunde son 3 / evvelki 3
--
--  HELL
--  app.student_trend(): Siqnallarin dusturu HERFEN (eyni yuvarlaqlasdirma, 1
--  onluq).  Muellimin sagird hesabati, valideyn paneli, valideyn metni ve
--  sekil karti ondan oxuyur.  «Son 30 gun» ortasi da buradadir - valideyn
--  panelinin boyuk reqemi ile eyni dustur (v_now).
--    n       - butun tesdiqlenmis cehdler (p_since-den)
--    last3   - son 3 testin ortasi        prev3 - ondan evvelki 3 testin
--    prevn   - evvelki hissede nece test  (muqayise yalniz n >= 4, prevn >= 2)
--    avg30 / n30 - son 30 gun
--
--  ON SERT: 18 / 219 (rpc_home.alerts), 900 (rpc_student_report), 177 (rpc_parent_home).
-- =====================================================================

create or replace function app.student_trend(p_sid uuid, p_since timestamptz default '-infinity')
returns jsonb
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  with att as (
    --  rpc_home.alerts-daki «att» ile eyni: tesdiqlenmis cehdler, en tezesi birinci
    select a.percent, a.finished_at,
           row_number() over (order by a.finished_at desc) rn
      from public.attempts a
     where a.student_id = p_sid and a.status = 'submitted'
       and a.finished_at >= p_since
  )
  select jsonb_build_object(
           'n',      count(*),
           'last3',  round(avg(percent) filter (where rn <= 3), 1),
           'prev3',  round(avg(percent) filter (where rn between 4 and 6), 1),
           'prevn',  count(*) filter (where rn between 4 and 6),
           'avg30',  round(avg(percent) filter (where finished_at >= now() - interval '30 days'), 0),
           'n30',    count(*) filter (where finished_at >= now() - interval '30 days'),
           'drop',   app.alert_drop())
    from att
$$;
revoke all on function app.student_trend(uuid, timestamptz) from public, anon, authenticated;

CREATE OR REPLACE FUNCTION public.rpc_student_report(p_student_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
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

    --  932: gedisat - Siqnallar, valideyn ve sekil karti ile EYNI funksiya
    'trend', app.student_trend(p_student_id, v_since),

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
end $function$;

CREATE OR REPLACE FUNCTION public.rpc_parent_home(p_token text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
declare
  v_sid   uuid := app.session_parent(p_token);
  v_st    public.students%rowtype;
  v_class public.classes%rowtype;
  v_paid  boolean;
  v_min   int := app.min_topic_answers();
  v_now   numeric;
  v_prev  numeric;
begin
  if v_sid is null then
    raise exception 'Sessiya bitib. Kodu yeniden yaz.' using errcode = '28000';
  end if;
  select * into v_st from public.students where id = v_sid;
  select * into v_class from public.classes where id = v_st.class_id;
  v_paid := app.has_active_subscription(v_st.account_id);

  --  Meyl: son 30 gun ve ondan EVVELKI 30 gun.  Cilpaq faiz valideyne
  --  hec ne demir - "8% yaxsilasib" deyir.
  select round(avg(a.percent), 0) into v_now from public.attempts a
   where a.student_id = v_sid and a.status = 'submitted'
     and a.finished_at >= now() - interval '30 days';
  select round(avg(a.percent), 0) into v_prev from public.attempts a
   where a.student_id = v_sid and a.status = 'submitted'
     and a.finished_at >= now() - interval '60 days'
     and a.finished_at <  now() - interval '30 days';

  return jsonb_build_object(
    --  191: ev tapsirigi (metnle) - valideyn "usaga ne deyilib" gorur
    'homework', coalesce((
      select jsonb_agg(x order by (x->>'done')::boolean, x->>'due' nulls last, x->>'created_at' desc)
        from (select jsonb_build_object(
                       'id', h.id, 'body', h.body, 'due', h.due,
                       'personal', h.student_id is not null,
                       'created_at', h.created_at,
                       'done', exists (select 1 from public.homework_done hd
                                        where hd.homework_id = h.id and hd.student_id = v_sid)) as x
                from public.homework h
               where h.class_id = v_st.class_id
                 and (h.student_id is null or h.student_id = v_sid)
                 and h.created_at > now() - interval '45 days') z), '[]'::jsonb),
    'paid', v_paid,
    --  Tam ad DEYIL - gorunen ad.  Kod yayilsa yad adam usagin tam
    --  adini oyrenmesin.
    'child', jsonb_build_object(
               'name',  v_st.display_name,
               'class', v_class.name),
    'teacher', (select p.full_name from public.profiles p
                 where p.id = v_class.teacher_id),

    -- ------------------------------------------------------ veziyyet
    'summary', jsonb_build_object(
      --  932: gedisat - muellimin sagird kartindaki ve Siqnallardaki ile EYNI funksiya
      --  (son 3 test / evvelki 3 test).  «delta» (son 30 gun / evvelki 30 gun) qalir -
      --  kohne tetbiq versiyasi onu oxuyur.
      'trend', case when v_paid then app.student_trend(v_sid) end,
      'attempts30', (select count(*) from public.attempts a
                      where a.student_id = v_sid and a.status = 'submitted'
                        and a.finished_at >= now() - interval '30 days'),
      --  174: NE BAS VERIB - pulsuz; NECEDIR (tehlil) - abune ile.
      --  Valideyn «Son nəticələr» siyahisini ve tapsiriqlari HEMISE
      --  gorur; ortalama, meyl ve en yaxsi netice muellimin abunesi
      --  ile acilir.  Sebeb (istifadeci qerari): muellimi valideyne
      --  hesabat vermek eziyyetinden qurtaran hisse elə budur.
      'avg30',  case when v_paid then v_now end,
      'prev30', case when v_paid then v_prev end,
      'delta',  case when v_paid and v_now is not null and v_prev is not null
                     then v_now - v_prev end,
      'best',   case when v_paid then
                  (select round(max(a.percent), 0) from public.attempts a
                    where a.student_id = v_sid and a.status = 'submitted') end),

    -- -------------------------------------------- gozleyen tapsiriq
    --  Ekranin en vacib hissesi: valideyni geri qaytaran yeganə sey.
    'pending', coalesce((
      select jsonb_agg(x order by x->>'closes_at' nulls last)
        from (
          select jsonb_build_object(
                   'title',     t.title,
                   'subject',   sub.name,
                   'closes_at', a.closes_at,
                   'questions', (select count(*) from public.test_questions tq
                                  where tq.test_id = t.id),
                   'fix', t.is_remedial, 'diag', t.is_diagnostic) as x
            from public.assignments a
            join public.tests t on t.id = a.test_id and t.status = 'published'
            left join public.subjects sub on sub.id = t.subject_id
           where a.class_id = v_st.class_id
             and app.assignment_open(a.*)
             --  bu usaq hele yazmayib
             and not exists (select 1 from public.attempts at
                              where at.test_id = t.id and at.student_id = v_sid
                                and at.status = 'submitted')
             --  ferdi tapsiriqsa YALNIZ bu usaga aiddirsa
             and (a.student_id is null or a.student_id = v_sid)
        ) z), '[]'::jsonb),

    -- --------------------------------------------------- neticeler
    'results', coalesce((
      select jsonb_agg(x order by x->>'at' desc)
        from (
          select jsonb_build_object(
                   'at',      a.finished_at,
                   'test',    t.title,
                   'subject', sub.name,
                   'percent', round(a.percent, 0),
                   --  DUZELIS testi - sutundan gelir, tehmin yox.
                   'fix', t.is_remedial, 'diag', t.is_diagnostic) as x
            from public.attempts a
            join public.tests t on t.id = a.test_id
            left join public.subjects sub on sub.id = t.subject_id
           where a.student_id = v_sid and a.status = 'submitted'
           order by a.finished_at desc limit 10
        ) z), '[]'::jsonb),

    -- ------------------------------------------------ zeif movzular
    --  En coxu 3.  Az cavab varsa GOSTERILMIR - uc sualdan cixarilan
    --  "zeifdir" hokmu valideyni nahaq yere hemlə edir.
    'weak', case when not v_paid then null else coalesce((
      select jsonb_agg(y order by (y->>'percent')::numeric)
        from (
          select jsonb_build_object(
                   'topic',   t.name,
                   'subject', sub.name,
                   'answers', count(*),
                   'percent', round(count(*) filter (where aa.is_correct)
                                    * 100.0 / count(*), 0)) as y
            from public.attempt_answers aa
            join public.attempts a on a.id = aa.attempt_id
                                  and a.student_id = v_sid
                                  and a.status = 'submitted'
            join public.topics t     on t.id = aa.topic_id
            join public.subjects sub on sub.id = t.subject_id
           group by t.id, t.name, sub.name
          having count(*) >= v_min
             and count(*) filter (where aa.is_correct) * 100.0 / count(*) < 60
           order by count(*) filter (where aa.is_correct) * 100.0 / count(*)
           limit 3
        ) z), '[]'::jsonb) end,

    -- --------------------------------------------- kecilen dersler
    --  "Bunu kecdim" - muellimin valideyne dediyi cumle.
    --  131: ferdi plan irelileyisi
    'plan', (select case when count(*) = 0 then null else
               jsonb_build_object('total', count(*), 'done', count(*) filter (where i.done_at is not null)) end
               from public.student_plan_items i
               join public.student_plans p on p.id = i.plan_id
              where p.student_id = v_sid),

    --  133: movzu mesqi
    'practice', (select jsonb_build_object(
                   'mastered', count(*) filter (where p.mastered_at is not null),
                   'active',   count(*) filter (where p.mastered_at is null and p.answered > 0))
                   from public.practice p where p.student_id = v_sid),

    --  177: BU HEFTENIN DERSLERI.  Cedvel qurulmayibsa acar NULL
    --  qayidir - valideyn ekraninda bos «Cədvəl» karti CIXMAMALIDIR
    --  (istifadeci qaydasi: qurulmayan funksiya gorunmur).
    --  PULSUZDUR - abune qapisi yoxdur: «nə baş verir» hissesidir.
    --  Valideyn ekraninda «bu gün» BAKI gunu ile isaretlenir.  Brauzerin
    --  oz tarixi ile hesablansaydi, saat 00:00-04:00 araliginda telefonu
    --  basqa vaxt zonasinda olan valideyn sehv gun gorerdi.
    'today', app.baki_bugun(),
    'week', (select case when count(*) = 0 then null else
               jsonb_agg(jsonb_build_object(
                 'date', w.on_date, 'time', to_char(w.starts_at, 'HH24:MI'),
                 'mins', w.mins, 'hal', w.hal, 'other', w.other)
                 order by w.on_date, w.starts_at) end
               from app.cedvel_araliq(v_st.account_id,
                      (app.baki_bugun() - (extract(isodow from app.baki_bugun())::int - 1))::date,
                      7) w
              where w.class_id = v_st.class_id),

    --  130: davamiyyet ve odenis - bu ay
    'attendance', (
      select jsonb_build_object(
               'month',    to_char(date_trunc('month', now()), 'YYYY-MM-DD'),
               'lessons',  (select count(*) from public.lessons l
                             where l.class_id = v_st.class_id
                               and l.held_on >= date_trunc('month', now())::date
                               and l.held_on <  (date_trunc('month', now()) + interval '1 month')::date),
               'attended', (select count(*) from public.attendance at
                             join public.lessons l on l.id = at.lesson_id
                            where at.student_id = v_sid and at.present
                              and l.held_on >= date_trunc('month', now())::date
                              and l.held_on <  (date_trunc('month', now()) + interval '1 month')::date),
               'paid',     (select p.paid from public.fee_payments p
                             where p.student_id = v_sid
                               and p.month = date_trunc('month', now())::date))),

    'lessons', coalesce((
      select jsonb_agg(x order by x->>'at' desc)
        from (
          select jsonb_build_object(
                   'topic',   t.name,
                   'subject', sub.name,
                   'at',      i.done_at) as x
            from public.class_plan_items i
            join public.class_plans p on p.id = i.plan_id
                                     and p.class_id = v_st.class_id
            join public.topics t     on t.id = i.topic_id
            join public.subjects sub on sub.id = p.subject_id
           where i.done_at is not null
           order by i.done_at desc limit 5
        ) z), '[]'::jsonb));
end $function$;

do $$
begin
  if position('932:' in pg_get_functiondef('public.rpc_student_report(uuid)'::regprocedure)) = 0
     or position('932:' in pg_get_functiondef('public.rpc_parent_home(text)'::regprocedure)) = 0 then
    raise exception '932: funksiyalar yenilenmedi';
  end if;
  raise notice '932 OK - gedisat sagird kartinda, valideynde ve Siqnallarda bir dusturla.';
end $$;
