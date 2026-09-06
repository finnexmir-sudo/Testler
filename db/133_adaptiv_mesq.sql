-- =====================================================================
--  133_adaptiv_mesq.sql : adaptiv movzu mesqi (yol xeritesi 22.b)
--
--  IXL / Khan "menimseme" modeli: sagird movzu secir, suallar bir-bir
--  gelir, cetinlik sagirdin balina uygunlasir, bal 100 olanda movzu
--  "menimsenildi".  Muellim vaxti serf olunmur - sagird ozu isleyir,
--  muellim hesabatda yalniz "5 menimsenilib, 2 davam edir" gorur.
--
--  Bal (0..100, IXL SmartScore-a benzer):
--    duz  : +8+4*cetinlik (bal<80) · +4+2*cetinlik (bal>=80)  -> yuxari
--           qalxdiqca yavaslayir, 100 ucun cetin suallar lazimdir
--    sehv : -8 (bal<80) · -12 (bal>=80)
--    seviyye (novbeti sualin cetinliyi) baldan cixir: <35 asan, <75 orta,
--    sonra cetin.  Bal 100 -> mastered_at.
--
--  Sual secimi: movzunun (kok movzu - platforma suallari kok movzuya
--  baglidir) platforma + hesabin oz suallari, cetinliyi seviyyeye en
--  yaxin olan, son 30-da gorulmemis; hamisi gorulubse en kohnesi.
--  Sablon suallar (132) her defe teze reqemle.  Verilmis sual "cur"-da
--  saxlanir - cavab yalniz ona qebul olunur (tekrar gonderme yoxdur),
--  sehife yenilenende eyni sual qayidir.
--
--  Duz variant sagirde getmir (129 ile eyni qayda): cavab yalniz
--  duz/sehv + izah qaytarir.  Sehv sehv defterine dusur (test kimi).
-- =====================================================================

create table if not exists public.practice (
  student_id  uuid not null references public.students(id) on delete cascade,
  topic_id    uuid not null references public.topics(id)   on delete cascade,
  score       smallint not null default 0 check (score between 0 and 100),
  streak      smallint not null default 0,
  answered    int not null default 0,
  correct     int not null default 0,
  seen        uuid[] not null default '{}',
  cur         jsonb,
  mastered_at timestamptz,
  started_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  primary key (student_id, topic_id)
);
alter table public.practice enable row level security;
revoke all on public.practice from public, anon, authenticated;

create or replace function app.practice_level(p_score int) returns int
language sql immutable as $$
  select case when p_score < 35 then 1 when p_score < 75 then 2 else 3 end $$;
revoke all on function app.practice_level(int) from public, anon, authenticated;

--  Bu sagird ucun movzu mesqi acıqdirmi + hansi movzular.
--  Qaytarir: (ok, sebeb, level_id, account_id, subjects[])
create or replace function app.practice_scope(p_student uuid,
  out o_ok boolean, out o_reason text, out o_level uuid, out o_account uuid, out o_subs text[])
language plpgsql stable as $$
declare v_free boolean;
begin
  select c.level_id, c.free_practice, s.account_id, coalesce(a.subjects, '{}')
    into o_level, v_free, o_account, o_subs
    from public.students s
    join public.classes c on c.id = s.class_id
    left join public.accounts a on a.id = s.account_id
   where s.id = p_student;
  o_ok := true; o_reason := null;
  if not coalesce(v_free, true) then
    o_ok := false; o_reason := 'Müəlliminiz sərbəst məşqi bağlayıb.';
  elsif o_level is null then
    o_ok := false; o_reason := 'Qrupun sinfi qoyulmayıb — müəlliminə de, qrupun sinfini seçsin.';
  end if;
end $$;
revoke all on function app.practice_scope(uuid) from public, anon, authenticated;

--  Movzunun mesq hovuzu: kok movzu, sagirdin sinfi, platforma ve ya
--  hesabin oz suallari, yalniz variantli/yazili derc olunmus suallar.
create or replace function app.practice_pool(p_topic uuid, p_level uuid, p_account uuid)
returns table (id uuid, difficulty smallint, params jsonb)
language sql stable as $$
  select q.id, q.difficulty, q.params
    from public.questions q
   where q.topic_id = p_topic and q.status = 'published'
     and (q.level_id = p_level or q.level_id is null)
     and (q.owner_type = 'platform' or q.account_id = p_account)
$$;
revoke all on function app.practice_pool(uuid, uuid, uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------
--  Movzu siyahisi: fenn -> movzular, her birinde bal/veziyyet; tovsiye
--  (zeif movzu, son kecilen ders).
-- ---------------------------------------------------------------------
create or replace function public.rpc_student_practice_topics(p_token text)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare
  v_st  uuid := app.session_student(p_token);
  sc    record;
  v_class uuid;
  v_min int := app.min_topic_answers();
begin
  if v_st is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;
  select class_id into v_class from public.students where id = v_st;
  select * into sc from app.practice_scope(v_st);
  if not sc.o_ok then
    return jsonb_build_object('enabled', false, 'reason', sc.o_reason, 'subjects', '[]'::jsonb);
  end if;
  return jsonb_build_object(
    'enabled', true,
    'level', (select name from public.levels where id = sc.o_level),
    'mastered', (select count(*) from public.practice p where p.student_id = v_st and p.mastered_at is not null),
    'active',   (select count(*) from public.practice p where p.student_id = v_st and p.mastered_at is null and p.answered > 0),
    'subjects', coalesce((
      select jsonb_agg(jsonb_build_object('name', s.name, 'topics', s.topics) order by s.sort, s.name)
        from (
          select sub.sort, sub.name,
                 jsonb_agg(jsonb_build_object(
                   'id', t.id, 'name', t.name, 'n', z.n,
                   'score', coalesce(p.score, 0),
                   'answered', coalesce(p.answered, 0),
                   'mastered', p.mastered_at is not null,
                   'level', app.practice_level(coalesce(p.score, 0)),
                   'why', case
                     when w.topic_id is not null then 'zəif'
                     when l.topic_id is not null then 'dərs'
                     else null end,
                   'at', p.updated_at) order by t.sort, t.name) as topics
            from public.topics t
            join public.subjects sub on sub.id = t.subject_id
            join lateral (select count(*) n from app.practice_pool(t.id, sc.o_level, sc.o_account)) z on z.n >= 5
            left join public.practice p on p.student_id = v_st and p.topic_id = t.id
            --  zeif: testlerde <60% (en azi v_min cavab)
            left join lateral (
              select aa.topic_id from public.attempt_answers aa
                join public.attempts a on a.id = aa.attempt_id and a.student_id = v_st and a.status = 'submitted'
               where aa.topic_id = t.id
               group by aa.topic_id
              having count(*) >= v_min and count(*) filter (where aa.is_correct) * 100.0 / count(*) < 60) w on true
            --  son 2 kecilen ders
            left join lateral (
              select i.topic_id from public.class_plan_items i
                join public.class_plans cp on cp.id = i.plan_id and cp.class_id = v_class
               where i.done_at is not null
               order by i.done_at desc limit 2) l on l.topic_id = t.id
           where t.parent_id is null and t.level_id = sc.o_level
             and (coalesce(array_length(sc.o_subs, 1), 0) = 0 or sub.slug = any(sc.o_subs))
           group by sub.sort, sub.name
        ) s), '[]'::jsonb));
end $$;

-- ---------------------------------------------------------------------
--  Novbeti sual.  Verilmis, cavabsiz sual varsa (1 saat) eynisi.
-- ---------------------------------------------------------------------
create or replace function public.rpc_student_practice_next(p_token text, p_topic_id uuid)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_st  uuid := app.session_student(p_token);
  sc    record;
  p     public.practice%rowtype;
  v_q   uuid;
  v_par jsonb;
  v_lvl int;
begin
  if v_st is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;
  select * into sc from app.practice_scope(v_st);
  if not sc.o_ok then
    raise exception '%', sc.o_reason using errcode = '42501';
  end if;
  if not exists (select 1 from public.topics t
                  where t.id = p_topic_id and t.parent_id is null and t.level_id = sc.o_level
                    and (coalesce(array_length(sc.o_subs, 1), 0) = 0
                         or exists (select 1 from public.subjects s where s.id = t.subject_id and s.slug = any(sc.o_subs)))) then
    raise exception 'Bu mövzu sənin sinfin üçün deyil.' using errcode = '22023';
  end if;

  insert into public.practice (student_id, topic_id) values (v_st, p_topic_id)
  on conflict (student_id, topic_id) do nothing;
  select * into p from public.practice where student_id = v_st and topic_id = p_topic_id;
  v_lvl := app.practice_level(p.score);

  --  verilmis sual hele cavabsizdir - eynisi (sehife yenilendi)
  if p.cur is not null and (p.cur->>'at')::timestamptz > now() - interval '1 hour'
     and exists (select 1 from app.practice_pool(p_topic_id, sc.o_level, sc.o_account) x where x.id = (p.cur->>'q')::uuid) then
    v_q := (p.cur->>'q')::uuid;
    v_par := p.cur->'params';
  else
    select x.id, app.pq_seed(x.params, x.id) into v_q, v_par
      from app.practice_pool(p_topic_id, sc.o_level, sc.o_account) x
     order by abs(x.difficulty - v_lvl),
              (x.id = any(p.seen)),                                -- gorulmemis evvel
              coalesce(array_position(p.seen, x.id), 0),           -- gorulubse en kohnesi
              random()
     limit 1;
    if v_q is null then
      raise exception 'Bu mövzuda hələ sual yoxdur.' using errcode = '22023';
    end if;
    update public.practice
       set cur = jsonb_strip_nulls(jsonb_build_object('q', v_q, 'params', v_par, 'at', now())),
           updated_at = now()
     where student_id = v_st and topic_id = p_topic_id;
  end if;

  return jsonb_build_object(
    'topic',    (select t.name from public.topics t where t.id = p_topic_id),
    'subject',  (select s.name from public.topics t join public.subjects s on s.id = t.subject_id where t.id = p_topic_id),
    'score',    p.score, 'level', v_lvl, 'streak', p.streak,
    'answered', p.answered, 'mastered', p.mastered_at is not null,
    'question', (
      select jsonb_build_object(
               'id', q.id, 'kind', q.kind,
               'body', app.pq_render(q.body, v_par),
               'media_url', q.media_url,
               'difficulty', q.difficulty,
               'options', coalesce((
                 select jsonb_agg(jsonb_build_object('id', o.id, 'body', app.pq_render(o.body, v_par)) order by o.ord)
                   from public.question_options o where o.question_id = q.id), '[]'::jsonb))
        from public.questions q where q.id = v_q));
end $$;

-- ---------------------------------------------------------------------
--  Cavab.  Yalniz verilmis suala; bal, seviyye, menimseme yenilenir.
-- ---------------------------------------------------------------------
create or replace function public.rpc_student_practice_answer(p_token text, p_topic_id uuid,
  p_question_id uuid, p_option_ids uuid[] default null, p_text text default null)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_st   uuid := app.session_student(p_token);
  p      public.practice%rowtype;
  q      public.questions%rowtype;
  v_par  jsonb;
  v_ok   boolean;
  v_sel  uuid[] := coalesce(p_option_ids, '{}');
  v_cor  uuid[];
  v_txt  text := nullif(btrim(coalesce(p_text, '')), '');
  v_new  int;
  v_gain int;
  v_was  boolean;
begin
  if v_st is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;
  select * into p from public.practice where student_id = v_st and topic_id = p_topic_id;
  if p.student_id is null or p.cur is null or (p.cur->>'q')::uuid <> p_question_id then
    raise exception 'Bu sual artıq bağlanıb — «Növbəti» bas.' using errcode = '22023';
  end if;
  select * into q from public.questions where id = p_question_id;
  v_par := p.cur->'params';

  if q.kind = 'text' then
    v_ok := v_txt is not null and lower(v_txt) = any (
      select lower(btrim(app.pq_render(o.body, v_par))) from public.question_options o
       where o.question_id = q.id and o.is_correct);
  else
    select coalesce(array_agg(o.id order by o.id), '{}') into v_cor
      from public.question_options o where o.question_id = q.id and o.is_correct;
    select coalesce(array_agg(x order by x), '{}') into v_sel from unnest(v_sel) x;
    v_ok := array_length(v_cor, 1) is not null and v_sel @> v_cor and v_cor @> v_sel;
  end if;
  if not v_ok and v_txt is null and array_length(v_sel, 1) is null then
    raise exception 'Cavab seçilməyib.' using errcode = '22023';
  end if;

  if v_ok then
    v_gain := case when p.score < 80 then 8 + 4 * q.difficulty else 4 + 2 * q.difficulty end;
  else
    v_gain := case when p.score < 80 then -8 else -12 end;
  end if;
  v_new := least(100, greatest(0, p.score + v_gain));
  v_was := p.mastered_at is not null;

  update public.practice
     set score = v_new,
         streak = case when v_ok then p.streak + 1 else 0 end,
         answered = p.answered + 1,
         correct = p.correct + case when v_ok then 1 else 0 end,
         seen = (array_remove(p.seen, q.id) || q.id)[greatest(1, cardinality(array_remove(p.seen, q.id)) + 1 - 29):],
         cur = null,
         mastered_at = case when v_new = 100 and p.mastered_at is null then now() else p.mastered_at end,
         updated_at = now()
   where student_id = v_st and topic_id = p_topic_id;

  --  sehv defteri: test kimi (sehv -> acıq, duz -> tekrar/baglanir)
  perform app.mistake_note(v_st, q.id, v_ok, false);

  return jsonb_build_object(
    'correct', v_ok, 'gain', v_new - p.score, 'score', v_new,
    'level', app.practice_level(v_new),
    'streak', case when v_ok then p.streak + 1 else 0 end,
    'mastered', v_new = 100 or v_was,
    'just_mastered', v_new = 100 and not v_was,
    'explanation', case when v_ok then '' else app.pq_render(coalesce(q.explanation, ''), v_par) end);
end $$;

revoke all on function public.rpc_student_practice_topics(text)                     from public;
grant execute on function public.rpc_student_practice_topics(text)                     to anon, authenticated;
revoke all on function public.rpc_student_practice_next(text, uuid)                 from public;
grant execute on function public.rpc_student_practice_next(text, uuid)                 to anon, authenticated;
revoke all on function public.rpc_student_practice_answer(text, uuid, uuid, uuid[], text) from public;
grant execute on function public.rpc_student_practice_answer(text, uuid, uuid, uuid[], text) to anon, authenticated;

-- rpc_student_report (esas: 129): 'practice' bloku
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

-- rpc_parent_home (esas: 131): 'practice' sayğaclari
create or replace function public.rpc_parent_home(p_token text)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
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
      'attempts30', (select count(*) from public.attempts a
                      where a.student_id = v_sid and a.status = 'submitted'
                        and a.finished_at >= now() - interval '30 days'),
      'avg30',  v_now,
      'prev30', v_prev,
      'delta',  case when v_now is null or v_prev is null then null
                     else v_now - v_prev end,
      'best',   (select round(max(a.percent), 0) from public.attempts a
                  where a.student_id = v_sid and a.status = 'submitted')),

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
end $$;

