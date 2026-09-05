-- =====================================================================
--  129  SEHV DEFTERI - sagirdin oz sehvleri, araliqli tekrar
--
--  Yol xeritesi 21.5.  Testde sehv edilen her sual sagirdin defterine
--  dusur ve duz cavablanana qeder qalir; bir hefte sonra yeniden gelir;
--  ikinci defe de duz olsa baglanir (Anki qaydasi, sade versiya).
--
--  Veziyyetler:  open   - gozleyir (next_at <= now olanda mesqe cixir)
--                review - bir defe duz cavablanib, 7 gun sonra tekrar
--                closed - tekrarda da duz, defterden cixib
--  Testde (attempt_answers) sehv -> open; duz -> open ise review(+7g),
--  review ve vaxti catibsa closed.  Mesqde sehv -> open, next_at +1 gun
--  (variantlari bir-bir yoxlamaqla cavabi tapmasin).
--
--  Sagird tetbiqine DUZ VARIANT getmir: cavab RPC-si yalniz "duz/sehv"
--  ve izah qaytarir.  Muellim hesabatinda sayğaclar (rpc_student_report).
-- =====================================================================

create table if not exists public.mistakes (
  student_id   uuid not null references public.students(id) on delete cascade,
  question_id  uuid not null references public.questions(id) on delete cascade,
  status       text not null default 'open' check (status in ('open','review','closed')),
  wrong_n      int  not null default 1,
  first_at     timestamptz not null default now(),
  last_at      timestamptz not null default now(),
  next_at      timestamptz not null default now(),
  cleared_at   timestamptz,
  primary key (student_id, question_id)
);
create index if not exists idx_mistakes_due on public.mistakes (student_id, status, next_at);
alter table public.mistakes enable row level security;
revoke all on public.mistakes from public, anon, authenticated;

create or replace function app.review_days() returns int
language sql immutable as $$ select 7 $$;
revoke all on function app.review_days() from public, anon, authenticated;

--  Bir cavabin deftere tesiri (test ve mesq eyni qaydani isledir)
create or replace function app.mistake_note(p_student uuid, p_question uuid, p_ok boolean, p_practice boolean)
returns void
language plpgsql as $$
declare m public.mistakes%rowtype;
begin
  if p_ok is null then return; end if;     -- cavabsiz sual sehv deyil
  select * into m from public.mistakes where student_id = p_student and question_id = p_question;
  if not p_ok then
    if m.student_id is null then
      insert into public.mistakes (student_id, question_id) values (p_student, p_question);
    else
      update public.mistakes
         set status = 'open', wrong_n = wrong_n + 1, last_at = now(), cleared_at = null,
             next_at = case when p_practice then now() + interval '1 day' else now() end
       where student_id = p_student and question_id = p_question;
    end if;
  elsif m.student_id is not null and m.status <> 'closed' then
    if m.status = 'open' then
      update public.mistakes
         set status = 'review', last_at = now(),
             next_at = now() + (app.review_days() || ' days')::interval
       where student_id = p_student and question_id = p_question;
    elsif m.next_at <= now() then
      update public.mistakes
         set status = 'closed', last_at = now(), cleared_at = now()
       where student_id = p_student and question_id = p_question;
    end if;
  end if;
end $$;
revoke all on function app.mistake_note(uuid, uuid, boolean, boolean) from public, anon, authenticated;

--  Test cavabi yazilanda deftere dusur (yalniz submit olunmus cehdlerde
--  is_correct dolur - rpc_submit_attempt bir defe yazir)
create or replace function app.trg_mistake() returns trigger
language plpgsql as $$
declare v_st uuid;
begin
  select student_id into v_st from public.attempts where id = new.attempt_id;
  if v_st is not null then
    perform app.mistake_note(v_st, new.question_id, new.is_correct, false);
  end if;
  return new;
end $$;
drop trigger if exists trg_mistake on public.attempt_answers;
create trigger trg_mistake after insert or update of is_correct on public.attempt_answers
  for each row execute function app.trg_mistake();

--  Movcud sehvler bir defelik deftere (en son cavab veziyyeti ile)
insert into public.mistakes (student_id, question_id, status, wrong_n, first_at, last_at, next_at)
select a.student_id, aa.question_id, 'open',
       count(*) filter (where aa.is_correct is false),
       min(aa.answered_at), max(aa.answered_at), now()
  from public.attempt_answers aa
  join public.attempts a on a.id = aa.attempt_id and a.status = 'submitted'
 group by a.student_id, aa.question_id
having count(*) filter (where aa.is_correct is false) > 0
   and not exists (select 1 from public.mistakes m
                    where m.student_id = a.student_id and m.question_id = aa.question_id)
   --  son cavab duz idise deftere dusmur
   and (select aa2.is_correct from public.attempt_answers aa2
          join public.attempts a2 on a2.id = aa2.attempt_id
         where a2.student_id = a.student_id and aa2.question_id = aa.question_id
         order by aa2.answered_at desc limit 1) is false
on conflict do nothing;

-- ------------------------------------------------- sagird: defter
create or replace function public.rpc_student_mistakes(p_token text)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare v_st uuid := app.session_student(p_token);
begin
  if v_st is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;
  return jsonb_build_object(
    'open',   (select count(*) from public.mistakes where student_id = v_st and status = 'open'),
    'review', (select count(*) from public.mistakes where student_id = v_st and status = 'review'),
    'closed', (select count(*) from public.mistakes where student_id = v_st and status = 'closed'),
    'due',    (select count(*) from public.mistakes
                where student_id = v_st and status <> 'closed' and next_at <= now()),
    --  mesq ucun 10 sual: evvel acıq, sonra tekrar; DUZ VARIANT GETMIR
    'items', coalesce((
      select jsonb_agg(jsonb_build_object(
               'qid', q.id, 'body', q.body, 'kind', q.kind, 'media_url', q.media_url,
               'topic', t.name, 'status', m.status, 'wrong_n', m.wrong_n,
               'options', coalesce((
                 select jsonb_agg(jsonb_build_object('id', o.id, 'body', o.body) order by o.ord)
                   from public.question_options o where o.question_id = q.id), '[]'::jsonb))
             order by (m.status = 'open') desc, m.next_at, m.last_at)
        from (select * from public.mistakes
               where student_id = v_st and status <> 'closed' and next_at <= now()
               order by (status = 'open') desc, next_at, last_at limit 10) m
        join public.questions q on q.id = m.question_id and q.status = 'published'
        left join public.topics t on t.id = q.topic_id), '[]'::jsonb));
end $$;

-- ------------------------------------------------- sagird: mesq cavabi
create or replace function public.rpc_student_mistake_answer(p_token text, p_question_id uuid, p_option_id uuid)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_st  uuid := app.session_student(p_token);
  v_ok  boolean;
  v_exp text;
  v_m   public.mistakes%rowtype;
begin
  if v_st is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;
  select * into v_m from public.mistakes where student_id = v_st and question_id = p_question_id;
  if v_m.student_id is null or v_m.status = 'closed' or v_m.next_at > now() then
    raise exception 'Bu sual defterde gozlemir.' using errcode = '22023';
  end if;
  select o.is_correct into v_ok from public.question_options o
   where o.id = p_option_id and o.question_id = p_question_id;
  if v_ok is null then
    raise exception 'Variant tapilmadi.' using errcode = '22023';
  end if;
  select coalesce(q.explanation, '') into v_exp from public.questions q where q.id = p_question_id;
  perform app.mistake_note(v_st, p_question_id, v_ok, true);
  select * into v_m from public.mistakes where student_id = v_st and question_id = p_question_id;
  return jsonb_build_object('correct', v_ok, 'explanation', v_exp, 'status', v_m.status,
                            'next_at', v_m.next_at,
                            'due', (select count(*) from public.mistakes
                                     where student_id = v_st and status <> 'closed' and next_at <= now()));
end $$;

revoke all on function public.rpc_student_mistakes(text) from public;
grant execute on function public.rpc_student_mistakes(text) to anon, authenticated;
revoke all on function public.rpc_student_mistake_answer(text, uuid, uuid) from public;
grant execute on function public.rpc_student_mistake_answer(text, uuid, uuid) to anon, authenticated;

-- ------------------------------------------------- muellim: hesabatda sayğaclar
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

