-- =====================================================================
--  08_reports.sql : muellim / valideyn hesabatlari
--
--  Pulsuz:  kim ne islayib, nece bal - son 7 gun
--  Odenisli: movzu uzre zeif noqte analizi + tam tarixce
--
--  Hedd BAZADA tetbiq olunur, frontend-e etibar edilmir: pulsuz hesabda
--  funksiya movzu analizini ummumiyyetle qaytarmir.
-- =====================================================================

create or replace function app.free_history_days() returns int
language sql immutable as $$ select 7 $$;

-- Movzu analizi ucun en az bu qeder cavab lazimdir - eks halda
-- bir sehv cavab "zeif movzu" kimi gorunur ve muellimi cas etdirir.
create or replace function app.min_topic_answers() returns int
language sql immutable as $$ select 3 $$;

-- ------------------------------------------------------ sinif hesabati
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
        select jsonb_build_object(
                 'id',      t.id,
                 'name',    t.name,
                 'subject', sub.name,
                 'total',   count(*),
                 'correct', count(*) filter (where aa.is_correct),
                 'ratio',   round(count(*) filter (where aa.is_correct) * 100.0 / count(*), 1)
               ) as y
          from public.attempt_answers aa
          join public.attempts a  on a.id = aa.attempt_id and a.status = 'submitted'
                                 and a.finished_at >= v_since
          join public.students s  on s.id = a.student_id and s.class_id = p_class_id
          join public.topics   t  on t.id = aa.topic_id
          join public.subjects sub on sub.id = t.subject_id
         group by t.id, t.name, sub.name
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

-- ----------------------------------------------------- sagird hesabati
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

    -- Movzu uzre menimseme - YALNIZ odenisli
    'topics', case when not v_paid then null else coalesce((
      select jsonb_agg(y order by (y->>'ratio')::numeric, y->>'name')
      from (
        select jsonb_build_object(
                 'id',      t.id,
                 'name',    t.name,
                 'subject', sub.name,
                 'total',   count(*),
                 'correct', count(*) filter (where aa.is_correct),
                 'ratio',   round(count(*) filter (where aa.is_correct) * 100.0 / count(*), 1)) as y
          from public.attempt_answers aa
          join public.attempts a on a.id = aa.attempt_id
                                and a.student_id = p_student_id
                                and a.status = 'submitted'
                                and a.finished_at >= v_since
          join public.topics t   on t.id = aa.topic_id
          join public.subjects sub on sub.id = t.subject_id
         group by t.id, t.name, sub.name
        having count(*) >= app.min_topic_answers()
      ) z), '[]'::jsonb) end,

    -- Tekrar sehv edilen suallar - YALNIZ odenisli
    'weak', case when not v_paid then null else coalesce((
      select jsonb_agg(y order by (y->>'wrong')::int desc)
      from (
        select jsonb_build_object(
                 'body',        aa.question_body,
                 'explanation', aa.question_explanation,
                 'wrong',       count(*)) as y
          from public.attempt_answers aa
          join public.attempts a on a.id = aa.attempt_id
                                and a.student_id = p_student_id
                                and a.status = 'submitted'
                                and a.finished_at >= v_since
         where aa.is_correct is not true
         group by aa.question_id, aa.question_body, aa.question_explanation
         order by count(*) desc
         limit 10
      ) z), '[]'::jsonb) end
  );
end $$;

-- ---------------------------------------------------------------- huquq
--  DIQQET: "from public" KIFAYET DEYIL.  Supabase yeni funksiyalara
--  anon ucun EXECUTE-u BIRBASA verir; PUBLIC-den geri almaq onu
--  toxunmadan buraxir.  Ona gore anon da acıq yazilir.
revoke all on function public.rpc_class_report(uuid)   from public, anon;
revoke all on function public.rpc_student_report(uuid) from public, anon;
grant execute on function public.rpc_class_report(uuid)   to authenticated;
grant execute on function public.rpc_student_report(uuid) to authenticated;

do $$
declare bad text;
begin
  select string_agg(f, ', ') into bad from unnest(array[
    'public.rpc_class_report(uuid)',
    'public.rpc_student_report(uuid)']) f
   where not has_function_privilege('authenticated', f, 'EXECUTE');
  if bad is not null then
    raise exception 'authenticated bu funksiyalari cagira bilmir: %', bad;
  end if;
  raise notice 'Hesabat funksiyalari authenticated ucun acildi.';
end $$;
