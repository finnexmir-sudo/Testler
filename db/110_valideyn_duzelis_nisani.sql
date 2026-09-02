-- =====================================================================
--  110_valideyn_duzelis_nisani.sql — nisan artiq SUTUNDAN gelir
--
--  108-de "sexsi" nisani teyinata baxirdi (yalniz bir sagirde verilib).
--  Canlida alti neticenin UCUNDE cixdi: muellim adi testi de ferdi
--  verir.  Yarisinda gorunen nisan hec ne ayirmir.
--
--  Indi 109-un is_remedial sutununa baxilir - duzelis testi yaranan
--  anda nisanlanir, sonradan tapilmir.  Ekranda "düzəliş" yazilir:
--  valideyn 100%-i "ela yazdi" kimi oxumasin, cunki o, usagin OZ
--  sehvlerini tekrar islediyi testdir.
-- =====================================================================

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
                   'fix', t.is_remedial) as x
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
                   'fix', t.is_remedial) as x
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

revoke all on function public.rpc_parent_home(text) from public;
grant execute on function public.rpc_parent_home(text) to anon, authenticated;

do $x$
declare v_def text;
begin
  select pg_get_functiondef(p.oid) into v_def from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'rpc_parent_home';
  if v_def like '%login_code%' then
    raise exception 'valideyn ekrani usagin giris kodunu qaytarir';
  end if;
  if v_def not like '%is_remedial%' then
    raise exception 'duzelis nisani sutundan gelmir';
  end if;
  raise notice 'Valideyn ekrani: duzelis nisani sutundan gelir.';
end $x$;
