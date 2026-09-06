-- =====================================================================
--  131  FERDI PLAN - diaqnostikadan sagirdin oz plani (yol xeritesi 18c)
--
--  Diaqnostika xeritesindeki zeif ve orta fesiller kurikulum sirasi ile
--  sagirdin OZ planina dusur (3-6 setir; 74 yox).  Muellim "Kecildi"
--  isareleyir, "Test ver" - hemin fesilden yalniz bu sagirde tapsiriq.
--  Tekrar diaqnostikadan sonra "Yenile": yaxsilasan fesil cixir, kecilmis
--  qalir.  Valideyn "Ferdi plan: 2/5" gorur.
-- =====================================================================

create table if not exists public.student_plans (
  id         uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  subject_id uuid not null references public.subjects(id) on delete restrict,
  level_id   uuid not null references public.levels(id)   on delete restrict,
  attempt_id uuid references public.attempts(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (student_id, subject_id)
);
create table if not exists public.student_plan_items (
  id       uuid primary key default gen_random_uuid(),
  plan_id  uuid not null references public.student_plans(id) on delete cascade,
  topic_id uuid not null references public.topics(id) on delete cascade,
  ord      int  not null default 0,
  kind     text not null default 'weak' check (kind in ('weak','mid')),
  done_at  timestamptz,
  test_id  uuid references public.tests(id) on delete set null,
  unique (plan_id, topic_id)
);
alter table public.student_plans      enable row level security;
alter table public.student_plan_items enable row level security;
revoke all on public.student_plans, public.student_plan_items from public, anon, authenticated;

--  planin sagirdine giris (muellim / hesab uzvu / admin)
create or replace function app.splan_student(p_plan uuid) returns uuid
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare v_st uuid;
begin
  select student_id into v_st from public.student_plans where id = p_plan;
  if v_st is null then
    raise exception 'Plan tapilmadi.' using errcode = '22023';
  end if;
  if not app.can_read_student(v_st) then
    raise exception 'Bu sagirde giris huququnuz yoxdur.' using errcode = '42501';
  end if;
  return v_st;
end $$;
revoke all on function app.splan_student(uuid) from public, anon, authenticated;

-- ------------------------------------------------- oxumaq
create or replace function public.rpc_student_plan_get(p_student_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
begin
  if not app.can_read_student(p_student_id) then
    raise exception 'Bu sagirde giris huququnuz yoxdur.' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', p.id, 'subject', s.name, 'subject_slug', s.slug,
             'level', l.name, 'level_code', l.code, 'updated_at', p.updated_at,
             'total', (select count(*) from public.student_plan_items i where i.plan_id = p.id),
             'done',  (select count(*) from public.student_plan_items i where i.plan_id = p.id and i.done_at is not null),
             'items', coalesce((
               select jsonb_agg(jsonb_build_object(
                        'id', i.id, 'topic', t.name, 'topic_id', t.id, 'ord', i.ord, 'kind', i.kind,
                        'done', i.done_at is not null, 'done_at', i.done_at, 'test_id', i.test_id,
                        'pct', (select round(a.percent) from public.attempts a
                                 where a.test_id = i.test_id and a.student_id = p.student_id
                                   and a.status = 'submitted' order by a.finished_at desc limit 1))
                      order by i.ord)
                 from public.student_plan_items i
                 join public.topics t on t.id = i.topic_id
                where i.plan_id = p.id), '[]'::jsonb))
           order by s.name)
      from public.student_plans p
      join public.subjects s on s.id = p.subject_id
      join public.levels   l on l.id = p.level_id
     where p.student_id = p_student_id), '[]'::jsonb);
end $$;

-- ------------------------------------------------- qurmaq / yenilemek
create or replace function public.rpc_student_plan_make(p_student_id uuid, p_subject text default null)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_st   public.students%rowtype;
  v_att  public.attempts%rowtype;
  v_test public.tests%rowtype;
  v_map  jsonb;
  v_pid  uuid;
  v_n    int := 0;
begin
  if not app.can_read_student(p_student_id) then
    raise exception 'Bu sagirde giris huququnuz yoxdur.' using errcode = '42501';
  end if;
  select * into v_st from public.students where id = p_student_id;
  if not app.has_active_subscription(v_st.account_id) then
    raise exception 'Ferdi plan abune paketine daxildir.' using errcode = '42501';
  end if;
  select a.* into v_att
    from public.attempts a
    join public.tests t on t.id = a.test_id and t.is_diagnostic
   where a.student_id = p_student_id and a.status = 'submitted'
     and (p_subject is null or t.subject_id = (select id from public.subjects where slug = p_subject))
   order by a.finished_at desc limit 1;
  if v_att.id is null then
    raise exception 'Evvel diaqnostik test yazilmalidir.' using errcode = '22023';
  end if;
  select * into v_test from public.tests where id = v_att.test_id;
  v_map := app.diag_map(v_att.id);

  insert into public.student_plans (student_id, subject_id, level_id, attempt_id)
  values (p_student_id, v_test.subject_id, v_test.level_id, v_att.id)
  on conflict (student_id, subject_id) do update
    set attempt_id = excluded.attempt_id, level_id = excluded.level_id, updated_at = now()
  returning id into v_pid;

  --  yaxsilasib "ok" olan fesil cixir; kecilmis olan qalir (done_at qorunur)
  delete from public.student_plan_items i
   where i.plan_id = v_pid
     and not exists (select 1 from jsonb_array_elements(v_map->'topics') e
                      where (e->>'id')::uuid = i.topic_id and e->>'status' in ('weak','mid'));
  insert into public.student_plan_items (plan_id, topic_id, ord, kind)
  select v_pid, (e->>'id')::uuid,
         row_number() over (order by (e->>'sort')::int, e->>'name'),
         e->>'status'
    from jsonb_array_elements(v_map->'topics') e
   where e->>'status' in ('weak','mid')
  on conflict (plan_id, topic_id) do update set kind = excluded.kind, ord = excluded.ord;

  select count(*) into v_n from public.student_plan_items where plan_id = v_pid;
  return jsonb_build_object('plan_id', v_pid, 'items', v_n);
end $$;

-- ------------------------------------------------- kecildi / geri
create or replace function public.rpc_student_plan_done(p_item_id uuid, p_done boolean default true)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare v_pid uuid;
begin
  select plan_id into v_pid from public.student_plan_items where id = p_item_id;
  if v_pid is null then
    raise exception 'Movzu tapilmadi.' using errcode = '22023';
  end if;
  perform app.splan_student(v_pid);
  update public.student_plan_items set done_at = case when p_done then coalesce(done_at, now()) end
   where id = p_item_id;
  update public.student_plans set updated_at = now() where id = v_pid;
  return jsonb_build_object('ok', true);
end $$;

-- ------------------------------------------------- bu fesilden yalniz bu sagirde test
create or replace function public.rpc_student_plan_test(p_item_id uuid, p_count int default 10)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_it   public.student_plan_items%rowtype;
  v_pl   public.student_plans%rowtype;
  v_st   public.students%rowtype;
  v_name text;
  v_res  jsonb;
  v_test uuid;
begin
  if p_count is null or p_count < 3 or p_count > 50 then
    raise exception 'Sual sayi 3-50 araliginda olmalidir.' using errcode = '22023';
  end if;
  select * into v_it from public.student_plan_items where id = p_item_id;
  if v_it.id is null then
    raise exception 'Movzu tapilmadi.' using errcode = '22023';
  end if;
  select * into v_pl from public.student_plans where id = v_it.plan_id;
  perform app.splan_student(v_pl.id);
  select * into v_st from public.students where id = v_pl.student_id;
  select name into v_name from public.topics where id = v_it.topic_id;

  v_res := public.rpc_generate_test(jsonb_build_object(
             'pool', 'all', 'count', p_count,
             'subject', (select slug from public.subjects where id = v_pl.subject_id),
             'level',   (select code from public.levels   where id = v_pl.level_id),
             'topics',  jsonb_build_array(v_it.topic_id::text)),
           v_name || ' — ' || split_part(v_st.full_name, ' ', 1));
  v_test := (v_res->>'test_id')::uuid;
  perform public.rpc_assign_test(v_st.class_id, v_test, now() + interval '7 days', 1, v_st.id);
  update public.student_plan_items set test_id = v_test where id = p_item_id;
  update public.student_plans set updated_at = now() where id = v_pl.id;
  return jsonb_build_object('ok', true, 'test_id', v_test, 'count', v_res->>'count');
end $$;

revoke all on function public.rpc_student_plan_get(uuid)           from public, anon;
grant execute on function public.rpc_student_plan_get(uuid)           to authenticated;
revoke all on function public.rpc_student_plan_make(uuid, text)     from public, anon;
grant execute on function public.rpc_student_plan_make(uuid, text)     to authenticated;
revoke all on function public.rpc_student_plan_done(uuid, boolean)  from public, anon;
grant execute on function public.rpc_student_plan_done(uuid, boolean)  to authenticated;
revoke all on function public.rpc_student_plan_test(uuid, int)      from public, anon;
grant execute on function public.rpc_student_plan_test(uuid, int)      to authenticated;

-- ------------------------------------------------- valideyn: ferdi plan irelileyisi
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

