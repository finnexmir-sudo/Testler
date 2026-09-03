-- =====================================================================
--  118_diaqnostika.sql : DIAQNOSTIK TEST - "bu usaq neyi bilmir?"
--
--  Yeni sagird gelende muellim 3-4 derse "hiss edir" - bezen sehv.
--  Diaqnostika: sinfin BUTUN fesillerinden (ust seviyye movzu) her
--  birine 3 sual (asan/orta/cetin - varsa), bir cehd, yalniz o sagirde.
--  Netice - MOVZU XERITESI: her fesil ok/mid/weak, "bundan basla" siyahisi,
--  evvelki diaqnostika ile ferq ("3 qirmizi -> 1").
--
--  NIYE 3 SUAL: app.min_topic_answers() = 3 - ondan az cavabla movzu
--  analizi susur (hesabatda da eyni qayda).  15 movzuya 30 sual versen
--  movzu basina 2 duser ve xerite bos qalar - ona gore say movzudan
--  cixir, eksi yox.
--
--  ABUNE: test platforma bankindan yigilir - rpc_generate_test ve
--  rpc_remedial_test kimi abune paketine daxildir (bank sizmasin: bir
--  diaqnostika 30+ platforma sualini pulsuz acardi).  Xerite (movzu
--  analizi) de hesabatdaki "topics" kimi abune ile; sagirdin OZ
--  xeritesi pulsuzdur (sagirdin oz zeif movzulari kimi - 114-de qerar).
--
--  Override-lar (rpc_student_tests, rpc_test_result, rpc_submit_attempt,
--  rpc_parent_home) 115/116/117/110-un CARI govdesinden PROQRAMLA
--  toredilib - el ile kocurulmeyib (CLAUDE.md-deki tele).  Novbeti
--  override BU fayldan basa gotursun.
-- =====================================================================

alter table public.tests add column if not exists is_diagnostic boolean not null default false;
create index if not exists idx_tests_diag on public.tests (is_diagnostic) where is_diagnostic;

-- ------------------------------------------------------------ komekciler
--  Diaqnostikaya yararli fesiller: ust seviyye, en azi 3 dogru cavabli
--  platforma suali olan.  Alt movzunun oz hovuzu yoxdur (bax 101).
create or replace function app.diag_topics(p_subject uuid, p_level uuid)
returns table (topic_id uuid, name text, sort int, n int)
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select t.id, t.name, t.sort::int, count(q.id)::int
    from public.topics t
    join public.questions q
      on q.topic_id = t.id and q.status = 'published' and q.owner_type = 'platform'
     and exists (select 1 from public.question_options o
                  where o.question_id = q.id and o.is_correct)
   where t.subject_id = p_subject and t.level_id = p_level and t.parent_id is null
   group by t.id, t.name, t.sort
  having count(q.id) >= app.min_topic_answers()
   order by t.sort, t.name
$$;

--  3 sualda: 3/3 ok · 2/3 mid · 0-1 weak  (hesabatdaki meter hedleri: 75/50)
create or replace function app.diag_status(p_correct int, p_total int) returns text
language sql immutable as $$
  select case when coalesce(p_total, 0) = 0 then 'none'
              when p_correct * 100.0 / p_total >= 75 then 'ok'
              when p_correct * 100.0 / p_total >= 50 then 'mid'
              else 'weak' end
$$;

--  Bir cehdin movzu xeritesi.  Sagird ucun de, muellim ucun de eyni
--  hesab - iki ferqli reqem olmasin.  Duz cavab yoxdur, yalniz say.
create or replace function app.diag_map(p_attempt uuid) returns jsonb
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  with m as (
    select t.id, t.name, t.sort::int as sort,
           count(*)::int as total,
           count(*) filter (where aa.is_correct)::int as correct
      from public.attempt_answers aa
      join public.topics t on t.id = aa.topic_id
     where aa.attempt_id = p_attempt
     group by t.id, t.name, t.sort
  ),
  rows_ as (
    select jsonb_build_object(
             'id', id, 'name', name, 'sort', sort, 'total', total, 'correct', correct,
             'ratio', round(correct * 100.0 / total, 0),
             'status', app.diag_status(correct, total)) as x,
           sort, name, app.diag_status(correct, total) as st
      from m
  )
  select jsonb_build_object(
    'topics', coalesce((select jsonb_agg(x order by sort, name) from rows_), '[]'::jsonb),
    --  "bundan basla": evvel qirmizilar, sonra narincilar - kurikulum sirasi ile, en coxu 3
    'start', coalesce((select jsonb_agg(q.name order by q.rk, q.sort)
                         from (select name, sort, case st when 'weak' then 0 else 1 end as rk
                                 from rows_ where st in ('weak','mid')
                                order by case st when 'weak' then 0 else 1 end, sort limit 3) q), '[]'::jsonb),
    'weak', (select count(*) from rows_ where st = 'weak'),
    'mid',  (select count(*) from rows_ where st = 'mid'),
    'ok',   (select count(*) from rows_ where st = 'ok'))
$$;

--  Sagird terefi: diaqnostik deyilse null - netice ekrani xerite gostermir
create or replace function app.diag_student_map(p_attempt uuid, p_is_diag boolean) returns jsonb
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select case when coalesce(p_is_diag, false) then app.diag_map(p_attempt) else null end
$$;

-- --------------------------------------------------- muellim: secimler
create or replace function public.rpc_diagnostic_options(p_student_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare
  v_st    public.students%rowtype;
  v_class public.classes%rowtype;
  v_lev   public.levels%rowtype;
  v_paid  boolean;
begin
  if not app.can_read_student(p_student_id) then
    raise exception 'Bu sagirde giris huququnuz yoxdur.' using errcode = '42501';
  end if;
  select * into v_st from public.students where id = p_student_id;
  v_paid := app.has_active_subscription(v_st.account_id);
  if v_st.class_id is null then
    return jsonb_build_object('paid', v_paid, 'level', null, 'subjects', '[]'::jsonb,
                              'reason', 'Sagird hec bir qrupda deyil.');
  end if;
  select * into v_class from public.classes where id = v_st.class_id;
  if v_class.level_id is null then
    return jsonb_build_object('paid', v_paid, 'level', null, 'subjects', '[]'::jsonb,
                              'reason', 'Qrupun sinfi secilmeyib - qrup ayarlarinda sinfi secin.');
  end if;
  select * into v_lev from public.levels where id = v_class.level_id;

  return jsonb_build_object(
    'paid',  v_paid,
    'level', jsonb_build_object('code', v_lev.code, 'name', v_lev.name),
    'subjects', coalesce((
      select jsonb_agg(x order by (x->>'sort')::int, x->>'name')
        from (
          select jsonb_build_object(
                   'slug', s.slug, 'name', s.name, 'sort', s.sort,
                   'topics', (select count(*) from app.diag_topics(s.id, v_lev.id)),
                   'questions', (select count(*) from app.diag_topics(s.id, v_lev.id)) * app.min_topic_answers(),
                   --  bu fennde son diaqnostika (varsa)
                   'last', (
                     select jsonb_build_object(
                              'test_id',   t.id,
                              'assigned_at', a.created_at,
                              'closes_at', a.closes_at,
                              'open',      app.assignment_open(a.*),
                              'taken',     exists (select 1 from public.attempts at
                                                    where at.test_id = t.id and at.student_id = v_st.id
                                                      and at.status = 'submitted'),
                              'percent',   (select round(max(at.percent), 0) from public.attempts at
                                             where at.test_id = t.id and at.student_id = v_st.id
                                               and at.status = 'submitted'))
                       from public.assignments a
                       join public.tests t on t.id = a.test_id and t.is_diagnostic
                      where a.student_id = v_st.id and t.subject_id = s.id
                      order by a.created_at desc limit 1)) as x
            from public.subjects s
           where exists (select 1 from app.diag_topics(s.id, v_lev.id))
        ) z), '[]'::jsonb));
end $$;

-- ------------------------------------------------------ muellim: yarat
create or replace function public.rpc_diagnostic_create(
  p_student_id uuid, p_subject text, p_days int default 7)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_uid   uuid := auth.uid();
  v_st    public.students%rowtype;
  v_class public.classes%rowtype;
  v_lev   public.levels%rowtype;
  v_subj  public.subjects%rowtype;
  v_acc   uuid;
  v_open  uuid;
  v_ids   uuid[] := '{}';
  v_pick  uuid[];
  v_any   uuid[];
  r       record;
  d       int;
  i       int;
  v_n     int := 0;
  v_test  uuid;
  v_close timestamptz;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  if not app.can_read_student(p_student_id) then
    raise exception 'Bu sagirde giris huququnuz yoxdur.' using errcode = '42501';
  end if;
  select * into v_st from public.students where id = p_student_id;
  if v_st.class_id is null then
    raise exception 'Sagird hec bir qrupda deyil.' using errcode = '22023';
  end if;
  select * into v_class from public.classes where id = v_st.class_id;
  if v_class.level_id is null then
    raise exception 'Qrupun sinfi secilmeyib - qrup ayarlarinda sinfi secin.' using errcode = '22023';
  end if;
  v_acc := v_st.account_id;
  if not app.has_active_subscription(v_acc) then
    raise exception 'Diaqnostik test platformanin sual bankindan yigilir - abune paketine daxildir.'
      using errcode = '42501';
  end if;
  if p_days is null or p_days < 1 or p_days > 60 then
    raise exception 'Muddet 1-60 gun araliginda olmalidir.' using errcode = '22023';
  end if;
  select * into v_subj from public.subjects where slug = p_subject;
  if not found then
    raise exception 'Fenn tapilmadi.' using errcode = '22023';
  end if;
  select * into v_lev from public.levels where id = v_class.level_id;

  --  Acıq, hele yazilmamis diaqnostika varsa DUBLIKAT yaratma - onu qaytar
  select t.id into v_open
    from public.tests t
    join public.assignments a on a.test_id = t.id and a.student_id = v_st.id
   where t.is_diagnostic and t.subject_id = v_subj.id and app.assignment_open(a.*)
     and not exists (select 1 from public.attempts at
                      where at.test_id = t.id and at.student_id = v_st.id and at.status = 'submitted')
   order by a.created_at desc limit 1;
  if v_open is not null then
    return jsonb_build_object('test_id', v_open, 'existing', true,
             'questions', (select count(*) from public.test_questions where test_id = v_open),
             'closes_at', (select a.closes_at from public.assignments a
                            where a.test_id = v_open and a.student_id = v_st.id limit 1));
  end if;

  --  Her fesilden 3 sual: asan, orta, cetin - varsa; yoxsa ne varsa
  for r in select * from app.diag_topics(v_subj.id, v_lev.id) loop
    v_pick := '{}';
    for d in 1..3 loop
      v_any := app.generate_pick(jsonb_build_object(
                 'subject', v_subj.slug, 'level', v_lev.code,
                 'topics', jsonb_build_array(r.topic_id::text),
                 'difficulty', jsonb_build_array(d::text),
                 'count', 1, 'pool', 'platform'), v_acc);
      if coalesce(array_length(v_any, 1), 0) >= 1 and not (v_any[1] = any(v_pick)) then
        v_pick := v_pick || v_any[1];
      end if;
    end loop;
    if coalesce(array_length(v_pick, 1), 0) < 3 then
      v_any := app.generate_pick(jsonb_build_object(
                 'subject', v_subj.slug, 'level', v_lev.code,
                 'topics', jsonb_build_array(r.topic_id::text),
                 'count', 6, 'pool', 'platform'), v_acc);
      for i in 1 .. coalesce(array_length(v_any, 1), 0) loop
        exit when coalesce(array_length(v_pick, 1), 0) >= 3;
        if not (v_any[i] = any(v_pick)) then v_pick := v_pick || v_any[i]; end if;
      end loop;
    end if;
    if coalesce(array_length(v_pick, 1), 0) = 3 then
      v_ids := v_ids || v_pick;
      v_n := v_n + 1;
    end if;
  end loop;
  if v_n = 0 then
    raise exception 'Bu fenn ve sinif ucun kifayet qeder sual yoxdur.' using errcode = '22023';
  end if;

  v_close := now() + make_interval(days => p_days);
  insert into public.tests
    (owner_type, owner_id, program_id, subject_id, level_id, title, description,
     status, gen_rule, shuffle_questions, shuffle_options, time_limit_sec,
     max_attempts, pass_percent, is_free, is_diagnostic)
  values ('educator', v_uid, v_lev.program_id, v_subj.id, v_lev.id,
          'Diaqnostika · ' || v_subj.name || ' · ' || v_lev.name,
          'Hər mövzudan 3 sual — hansı mövzudan başlamalı olduğunu göstərir.',
          'published',
          jsonb_build_object('kind', 'diagnostic', 'subject', v_subj.slug,
                             'level', v_lev.code, 'per_topic', 3, 'student', v_st.id),
          true, true, 75 * array_length(v_ids, 1), 1, 60, true, true)
  returning id into v_test;

  for i in 1 .. array_length(v_ids, 1) loop
    insert into public.test_questions (test_id, question_id, ord) values (v_test, v_ids[i], i);
  end loop;

  --  Teyinat YALNIZ bu sagirde - movcud yoxlamalar (28) ile
  perform public.rpc_assign_test(v_st.class_id, v_test, v_close, 1, v_st.id);

  return jsonb_build_object('test_id', v_test, 'existing', false,
                            'questions', array_length(v_ids, 1), 'topics', v_n,
                            'closes_at', v_close,
                            'title', 'Diaqnostika · ' || v_subj.name || ' · ' || v_lev.name);
end $$;

-- ----------------------------------------------------- muellim: netice
create or replace function public.rpc_diagnostic_result(p_student_id uuid, p_subject text default null)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare
  v_st    public.students%rowtype;
  v_paid  boolean;
  v_att   public.attempts%rowtype;
  v_prev  public.attempts%rowtype;
  v_test  public.tests%rowtype;
  v_map   jsonb;
  v_pmap  jsonb;
  v_pend  jsonb;
begin
  if not app.can_read_student(p_student_id) then
    raise exception 'Bu sagirde giris huququnuz yoxdur.' using errcode = '42501';
  end if;
  select * into v_st from public.students where id = p_student_id;
  v_paid := app.has_active_subscription(v_st.account_id);

  --  gozleyen: teyin olunub, acıqdir, yazilmayib
  select jsonb_build_object('test_id', t.id, 'title', t.title, 'subject', s.name,
                            'closes_at', a.closes_at, 'questions',
                            (select count(*) from public.test_questions tq where tq.test_id = t.id))
    into v_pend
    from public.assignments a
    join public.tests t    on t.id = a.test_id and t.is_diagnostic
    join public.subjects s on s.id = t.subject_id
   where a.student_id = v_st.id and app.assignment_open(a.*)
     and (p_subject is null or s.slug = p_subject)
     and not exists (select 1 from public.attempts x
                      where x.test_id = t.id and x.student_id = v_st.id and x.status = 'submitted')
   order by a.created_at desc limit 1;

  --  son yazilmis diaqnostika
  select a.* into v_att
    from public.attempts a
    join public.tests t on t.id = a.test_id and t.is_diagnostic
   where a.student_id = v_st.id and a.status = 'submitted'
     and (p_subject is null or t.subject_id = (select id from public.subjects where slug = p_subject))
   order by a.finished_at desc limit 1;

  if v_att.id is null then
    return jsonb_build_object('paid', v_paid, 'has', false, 'pending', v_pend);
  end if;
  select * into v_test from public.tests where id = v_att.test_id;

  --  eyni fennde EVVELKI diaqnostika - ferq ucun
  select a.* into v_prev
    from public.attempts a
    join public.tests t on t.id = a.test_id and t.is_diagnostic and t.subject_id = v_test.subject_id
   where a.student_id = v_st.id and a.status = 'submitted' and a.finished_at < v_att.finished_at
   order by a.finished_at desc limit 1;

  v_map := app.diag_map(v_att.id);
  if v_prev.id is not null then
    v_pmap := app.diag_map(v_prev.id);
    --  her movzuya evvelki status yazilir
    v_map := jsonb_set(v_map, '{topics}', coalesce((
      select jsonb_agg(e || jsonb_build_object('prev_status',
               (select p->>'status' from jsonb_array_elements(v_pmap->'topics') p
                 where p->>'id' = e->>'id')))
        from jsonb_array_elements(v_map->'topics') e), '[]'::jsonb));
  end if;

  return jsonb_build_object(
    'paid',     v_paid,
    'has',      true,
    'pending',  v_pend,
    'test',     jsonb_build_object('id', v_test.id, 'title', v_test.title,
                  'subject', (select name from public.subjects where id = v_test.subject_id),
                  'level',   (select name from public.levels   where id = v_test.level_id),
                  --  duzelis testi generatoru ucun
                  'subject_slug', (select slug from public.subjects where id = v_test.subject_id),
                  'level_code',   (select code from public.levels   where id = v_test.level_id)),
    'taken_at', v_att.finished_at,
    'percent',  round(v_att.percent, 0),
    'score',    v_att.score,
    'max_score', v_att.max_score,
    --  xerite (movzu analizi) hesabatdaki kimi abune ile
    'topics',   case when v_paid then v_map->'topics' else null end,
    'start',    case when v_paid then v_map->'start'  else null end,
    'weak_now', case when v_paid then (v_map->>'weak')::int else null end,
    'mid_now',  case when v_paid then (v_map->>'mid')::int  else null end,
    'ok_now',   case when v_paid then (v_map->>'ok')::int   else null end,
    'prev_at',  v_prev.finished_at,
    'weak_prev', case when v_paid and v_prev.id is not null then (v_pmap->>'weak')::int else null end);
end $$;

-- ------------------------------------------- sagird ve valideyn terefi
--  Asagidaki dord funksiya 115/116/117/110-un cari govdesi + bir-iki sahe.

create or replace function public.rpc_student_tests(p_token text)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_student uuid := app.session_student(p_token);
  v_class   uuid;
  v_account uuid;
  v_paid    boolean;
  v_free    boolean;
  v_min     int := app.min_topic_answers();
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
                 --  yalniz mene verilibse sagird de bilsin
                 'personal',       a.student_id is not null,
                 --  diaqnostik test - sagird ekraninda nisan
                 'diagnostic',     t.is_diagnostic,
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
           --  ferdi teyinat basqasina gorunmur
           and (a.student_id is null or a.student_id = v_student)
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
           -- Teyin olunmuşdursa "Tapsiriqlar"da gorunur, burada tekrarlanmasin.
           -- Basqasinin ferdi teyinati bu sagirde mane olmamalidir.
           and not exists (select 1 from public.assignments a
                            where a.class_id = v_class and a.test_id = t.id
                              and app.assignment_open(a.*)
                              and (a.student_id is null or a.student_id = v_student))
      ) z), '[]'::jsonb) end,

    -- ------------------------------------------------- en yaxsi netice
    'best', (select round(max(at.percent), 0) from public.attempts at
              where at.student_id = v_student and at.status = 'submitted'),

    -- --------------------------------------------------- dovamlilik
    --  Ne qeder gundur ARDICIL test yazir.  Bugun ve ya dunen bir sey
    --  yazilmayibsa zencir qirilib sayilir - "3 gun" gostermek yalan
    --  motivasiya olar.
    'streak', coalesce((
      with gunler as (
        select distinct at.finished_at::date as gun
          from public.attempts at
         where at.student_id = v_student and at.status = 'submitted'
      ),
      zencirler as (
        select gun,
               gun - (row_number() over (order by gun))::int * interval '1 day' as qrup
          from gunler
      ),
      son as (
        select max(gun) as son_gun, count(*) as uzunluq
          from zencirler
         group by qrup
         order by son_gun desc
         limit 1
      )
      select case when son_gun >= current_date - 1 then uzunluq else 0 end
        from son
    ), 0),

    -- ------------------------------------------------------ novbeti ders
    --  Muellim ekranindaki "NOVBETI DERS" karti ile eyni mentiq: ilk
    --  fenn plani (fenn.sort-a gore), ordakı ilk bitirilməmiş sətir.
    'next_lesson', (
      select jsonb_build_object('topic', t.name, 'subject', sub.name)
        from public.class_plan_items i
        join public.class_plans p on p.id = i.plan_id and p.class_id = v_class
        join public.topics   t   on t.id = i.topic_id
        join public.subjects sub on sub.id = p.subject_id
       where i.done_at is null
       order by sub.sort, i.ord
       limit 1
    ),

    -- --------------------------------------------------- zeif movzular
    --  Valideyn ekranindan ferqli olaraq ABUNƏ TELEB ETMIR: bu, sagirdin
    --  ozune aid tehsil melumatidir, muellimin satdigi analitika deyil.
    --  Ən çoxu 3, ən azı 3 cavab - az sualdan cixan "zeifsen" hokmu
    --  yalan xeberdarlik olar (eyni qayda hesabatda da var).
    'weak', coalesce((
      select jsonb_agg(y order by (y->>'percent')::numeric)
        from (
          select jsonb_build_object(
                   'topic',   t.name,
                   'subject', sub.name,
                   'percent', round(count(*) filter (where aa.is_correct)
                                    * 100.0 / count(*), 0)) as y
            from public.attempt_answers aa
            join public.attempts a on a.id = aa.attempt_id
                                  and a.student_id = v_student
                                  and a.status = 'submitted'
            join public.topics t     on t.id = aa.topic_id
            join public.subjects sub on sub.id = t.subject_id
           group by t.id, t.name, sub.name
          having count(*) >= v_min
             and count(*) filter (where aa.is_correct) * 100.0 / count(*) < 60
           order by count(*) filter (where aa.is_correct) * 100.0 / count(*)
           limit 3
        ) z), '[]'::jsonb),

    -- --------------------------------------------------- kecdiyi dersler
    --  "Novbeti ders" hara gedirik deyir, bu hardan geldik.  Valideyn
    --  ekranindaki eyni sorgu (110_valideyn_duzelis_nisani.sql) - en
    --  coxu 5, en yenisi evvel.
    'lessons', coalesce((
      select jsonb_agg(x order by x->>'at' desc)
        from (
          select jsonb_build_object(
                   'topic',   t.name,
                   'subject', sub.name,
                   'at',      i.done_at) as x
            from public.class_plan_items i
            join public.class_plans p on p.id = i.plan_id and p.class_id = v_class
            join public.topics   t   on t.id = i.topic_id
            join public.subjects sub on sub.id = p.subject_id
           where i.done_at is not null
           order by i.done_at desc limit 5
        ) z), '[]'::jsonb)
  );
end $$;

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

-- --------------------------------------------------------------- huquq
revoke all on function app.diag_topics(uuid, uuid)          from public, anon, authenticated;
revoke all on function app.diag_status(int, int)            from public, anon, authenticated;
revoke all on function app.diag_map(uuid)                   from public, anon, authenticated;
revoke all on function app.diag_student_map(uuid, boolean)  from public, anon, authenticated;
revoke all on function public.rpc_diagnostic_options(uuid)             from public, anon;
revoke all on function public.rpc_diagnostic_create(uuid, text, int)   from public, anon;
revoke all on function public.rpc_diagnostic_result(uuid, text)        from public, anon;
grant execute on function public.rpc_diagnostic_options(uuid)           to authenticated;
grant execute on function public.rpc_diagnostic_create(uuid, text, int) to authenticated;
grant execute on function public.rpc_diagnostic_result(uuid, text)      to authenticated;

do $$
begin
  if has_function_privilege('anon', 'public.rpc_diagnostic_create(uuid, text, int)', 'EXECUTE') then
    raise exception 'anon diaqnostika yarada bilir';
  end if;
  if not has_function_privilege('anon', 'public.rpc_student_tests(text)', 'EXECUTE') then
    raise exception 'rpc_student_tests anon ucun baglandi - 05_grants-a bax';
  end if;
  raise notice 'Diaqnostika quruldu: her fesilden 3 sual, movzu xeritesi, ferq.';
end $$;
