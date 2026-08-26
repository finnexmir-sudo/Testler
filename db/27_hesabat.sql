-- =====================================================================
--  27_hesabat.sql : sagird hesabatinin derinlesdirilmesi
--
--  1) rpc_student_report EYNI IMZA ile genislenir (08-e toxunulmur ki,
--     movcud bazada tek bu fayl kifayet etsin):
--     - topics: 1 cavabdan gorunur; 'min_answers' sahesi ile UI
--       "az melumat" nisani qoyur (evvel esik altda tam gizlenirdi)
--     - weak setirlerine movzu adi ('topic') ve sual id-si ('qid')
--  2) rpc_attempt_sheet: cehdin CAVAB VEREQI - sagird hansi suala
--     ne cavab verib, duzu ne idi.  Odenisli (derin analitika).
--  3) rpc_remedial_test: sagirdin SEHV etdiyi suallarin OZUNDEN
--     "sehvler uzerinde is" testi yaradir ve qrupa tapsiriq verir
--     (son tarix +7 gun, 1 cehd).  Odenisli.
--
--  Sagird terefine hec ne acilmir: her uc funksiya yalniz muellim
--  (authenticated + uzvluk) ucundur; is_correct yalniz bu kanalla gedir.
--
--  ON SERT: 01, 08 (can_read_student), 09 (rpc_assign_test), 21 (abune).
--  Tekrar isledile biler.
-- =====================================================================

do $$
begin
  if to_regprocedure('public.rpc_assign_test(uuid, uuid, timestamptz, int)') is null
     or to_regproc('app.can_read_student') is null then
    raise exception 'ONCE 08_reports.sql ve 09_assignments.sql islenmelidir.';
  end if;
end $$;

-- ------------------------------------------------- hesabat (genis)
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
                 'wrong',       count(*)) as y
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

-- ------------------------------------------------- cavab vereqi
create or replace function public.rpc_attempt_sheet(p_attempt_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_a  public.attempts%rowtype;
  v_st public.students%rowtype;
begin
  select * into v_a from public.attempts
   where id = p_attempt_id and status = 'submitted';
  if not found then
    raise exception 'Cehd tapilmadi.' using errcode = '22023';
  end if;
  if not app.can_read_student(v_a.student_id) then
    raise exception 'Bu sagirdin hesabatina giris huququnuz yoxdur.' using errcode = '42501';
  end if;
  select * into v_st from public.students where id = v_a.student_id;
  if not app.has_active_subscription(v_st.account_id) then
    raise exception 'Cavab vereqi abune paketine daxildir.' using errcode = '42501';
  end if;

  return jsonb_build_object(
    'test',    (select t.title from public.tests t where t.id = v_a.test_id),
    'at',      v_a.finished_at,
    'percent', round(v_a.percent, 0),
    'items', coalesce((
      select jsonb_agg(x order by (x->>'ord')::int, x->>'body')
      from (
        select jsonb_build_object(
                 'ord',  coalesce(tq.ord, 999),
                 'body', aa.question_body,
                 'explanation', aa.question_explanation,
                 'ok',   aa.is_correct is true,
                 'chosen', coalesce((
                    select string_agg(o.body, ' · ' order by o.ord)
                      from public.question_options o
                     where o.id = any(aa.selected_option_ids)),
                    nullif(btrim(coalesce(aa.text_answer, '')), ''), '—'),
                 'correct', coalesce((
                    select string_agg(o.body, ' · ' order by o.ord)
                      from public.question_options o
                     where o.question_id = aa.question_id and o.is_correct), '')
               ) as x
          from public.attempt_answers aa
          left join public.test_questions tq
                 on tq.test_id = v_a.test_id and tq.question_id = aa.question_id
         where aa.attempt_id = p_attempt_id
      ) z), '[]'::jsonb));
end $$;

-- ------------------------------------------------- sehvler uzerinde is
--  Sagirdin sehv etdiyi suallarin OZUNDEN test: en cox sehv edilenler
--  birinci.  Test qrupa tapsiriq kimi verilir - repetitor qrupu cox
--  vaxt 1 sagirddir, faktiki ferdi test alinir.
create or replace function public.rpc_remedial_test(
  p_student_id uuid, p_count int default 10)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid  uuid := auth.uid();
  v_st   public.students%rowtype;
  v_qids uuid[];
  v_subj uuid;
  v_lev  uuid;
  v_prog uuid;
  v_test uuid;
  v_n    int;
begin
  if p_count is null or p_count < 1 or p_count > 50 then
    raise exception 'Sual sayi 1-50 araliginda olmalidir.' using errcode = '22023';
  end if;
  if not app.can_read_student(p_student_id) then
    raise exception 'Bu sagirdin hesabatina giris huququnuz yoxdur.' using errcode = '42501';
  end if;
  select * into v_st from public.students where id = p_student_id;
  if not app.has_active_subscription(v_st.account_id) then
    raise exception 'Sehvler uzerinde is abune paketine daxildir.' using errcode = '42501';
  end if;
  if v_st.class_id is null then
    raise exception 'Sagird hec bir qrupda deyil.' using errcode = '22023';
  end if;

  --  en cox sehv edilen suallar (yalniz derc olunmus, movcud suallar)
  select array_agg(qid) into v_qids from (
    select aa.question_id as qid
      from public.attempt_answers aa
      join public.attempts a on a.id = aa.attempt_id
                            and a.student_id = p_student_id
                            and a.status = 'submitted'
      join public.questions q on q.id = aa.question_id
                             and q.status = 'published'
     where aa.is_correct is not true
     group by aa.question_id
     order by count(*) desc, max(aa.answered_at) desc
     limit p_count
  ) z;
  v_n := coalesce(array_length(v_qids, 1), 0);
  if v_n = 0 then
    raise exception 'Sehv edilmis sual yoxdur.' using errcode = '22023';
  end if;

  --  test ust-basligi: coxluqda olan fenn/sinif (qarisiq ola biler)
  select q.subject_id into v_subj from public.questions q
   where q.id = any(v_qids) group by q.subject_id
   order by count(*) desc limit 1;
  select q.level_id into v_lev from public.questions q
   where q.id = any(v_qids) and q.level_id is not null
   group by q.level_id order by count(*) desc limit 1;
  select p.id into v_prog from public.programs p where p.slug = 'ibtidai';

  insert into public.tests
    (owner_type, owner_id, program_id, subject_id, level_id, title,
     status, shuffle_questions, shuffle_options)
  values ('educator', v_uid, v_prog, v_subj, v_lev,
          v_st.display_name || ' — səhvlər üzərində iş',
          'published', true, true)
  returning id into v_test;

  insert into public.test_questions (test_id, question_id, ord)
  select v_test, q, row_number() over ()
    from unnest(v_qids) q;

  perform public.rpc_assign_test(
    v_st.class_id, v_test, now() + interval '7 days', 1);

  return jsonb_build_object('ok', true, 'test_id', v_test, 'count', v_n);
end $$;

-- ---------------------------------------------------------------- huquq
revoke all on function public.rpc_student_report(uuid)     from public, anon;
revoke all on function public.rpc_attempt_sheet(uuid)      from public, anon;
revoke all on function public.rpc_remedial_test(uuid, int) from public, anon;

grant execute on function public.rpc_student_report(uuid)     to authenticated;
grant execute on function public.rpc_attempt_sheet(uuid)      to authenticated;
grant execute on function public.rpc_remedial_test(uuid, int) to authenticated;

do $$
begin
  if has_function_privilege('anon', 'public.rpc_attempt_sheet(uuid)', 'EXECUTE')
     or has_function_privilege('anon', 'public.rpc_remedial_test(uuid, int)', 'EXECUTE') then
    raise exception 'anon hesabat funksiyalarini gorur!';
  end if;
  raise notice 'Hesabat derinlesdirildi.';
end $$;
