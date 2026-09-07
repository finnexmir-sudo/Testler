-- =====================================================================
--  137_mesq_limit.sql : movzu mesqinde abunesiz gundelik limit
--
--  Movzu mesqi (133) hazir bankin ozudur - abunesiz hesabin sagirdi
--  butun banki limitsiz isledirdi.  Qerar (istifadeci): sagird basina
--  gunde app.practice_daily_limit() = 20 cavab; muellimin abunesi ile
--  limitsiz.  Sehv defteri limitsiz qalir (sagirdin oz sehvleridir).
--  Sayğac practice_days (sagird, gun) - her cavabda +1.  Verilmis sual
--  hemise cavablana bilir (limit "novbeti" verilende yoxlanir).
-- =====================================================================

create table if not exists public.practice_days (
  student_id uuid not null references public.students(id) on delete cascade,
  day        date not null default current_date,
  n          int  not null default 0,
  primary key (student_id, day)
);
alter table public.practice_days enable row level security;
revoke all on public.practice_days from public, anon, authenticated;

create or replace function app.practice_daily_limit() returns int
language sql immutable as $$ select 20 $$;
revoke all on function app.practice_daily_limit() from public, anon, authenticated;

create or replace function app.practice_quota(p_student uuid,
  out o_paid boolean, out o_used int, out o_max int)
language sql stable as $$
  select app.has_active_subscription(s.account_id),
         coalesce((select d.n from public.practice_days d where d.student_id = s.id and d.day = current_date), 0),
         app.practice_daily_limit()
    from public.students s where s.id = p_student
$$;
revoke all on function app.practice_quota(uuid) from public, anon, authenticated;

-- rpc_student_practice_topics (esas: 133): quota
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
    --  137: gundelik limit (abunesiz)
    'quota', (select jsonb_build_object('paid', q.o_paid, 'used', q.o_used, 'max', q.o_max) from app.practice_quota(v_st) q),
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

-- rpc_student_practice_next (esas: 133): limit
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

  --  137: abunesiz gundelik limit - verilmis (cavabsiz) sual varsa o qayidir
  declare q record; begin
    select * into q from app.practice_quota(v_st);
    if not q.o_paid and q.o_used >= q.o_max
       and not exists (select 1 from public.practice p2 where p2.student_id = v_st and p2.topic_id = p_topic_id
                         and p2.cur is not null and (p2.cur->>'at')::timestamptz > now() - interval '1 hour') then
      raise exception 'Bugünkü məşq limiti dolub: gündə % sual. Sabah davam et — müəllimin abunəsi ilə limitsizdir.', q.o_max
        using errcode = '42501';
    end if;
  end;
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

-- rpc_student_practice_answer (esas: 133): sayğac + quota
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

  --  137: gundelik sayğac
  insert into public.practice_days (student_id, day, n) values (v_st, current_date, 1)
  on conflict (student_id, day) do update set n = public.practice_days.n + 1;

  --  sehv defteri: test kimi (sehv -> acıq, duz -> tekrar/baglanir)
  perform app.mistake_note(v_st, q.id, v_ok, false);

  return jsonb_build_object(
    'correct', v_ok, 'gain', v_new - p.score, 'score', v_new,
    'level', app.practice_level(v_new),
    'streak', case when v_ok then p.streak + 1 else 0 end,
    'mastered', v_new = 100 or v_was,
    'just_mastered', v_new = 100 and not v_was,
    'explanation', case when v_ok then '' else app.pq_render(coalesce(q.explanation, ''), v_par) end,
    'quota', (select jsonb_build_object('paid', qq.o_paid, 'used', qq.o_used, 'max', qq.o_max) from app.practice_quota(v_st) qq));
end $$;

