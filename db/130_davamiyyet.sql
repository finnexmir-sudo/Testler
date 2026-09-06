-- =====================================================================
--  130  DAVAMIYYET VE ODENIS DEFTERI (yol xeritesi 21.4)
--
--  Her repetitorun defterçesi: kim gelib, kim bu ay odeyib.  Bir
--  toxunusla "istirak etdi"; ay sonunda "6 ders, 5-de istirak, odenilib".
--  Valideyn oz ekraninda istirak sayini ve odenis veziyyetini gorur -
--  mubahise bitir.  Pulsuz (abune qapisi yoxdur) - muellimi her gun
--  tetbiqe getiren yapisqan xususiyyetdir.
--
--  lessons(class, held_on)  - bir gunde bir ders (unique)
--  attendance(lesson, student, present)
--  payments(student, month, paid, amount_minor, note)
--  RPC: rpc_lesson_mark, rpc_lesson_delete, rpc_ledger_get,
--       rpc_payment_set (muellim); rpc_parent_home-a 'attendance'.
-- =====================================================================

create table if not exists public.lessons (
  id         uuid primary key default gen_random_uuid(),
  class_id   uuid not null references public.classes(id) on delete cascade,
  held_on    date not null,
  note       text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (class_id, held_on)
);
create table if not exists public.attendance (
  lesson_id  uuid not null references public.lessons(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  present    boolean not null default true,
  primary key (lesson_id, student_id)
);
create table if not exists public.fee_payments (
  student_id   uuid not null references public.students(id) on delete cascade,
  month        date not null,
  paid         boolean not null default false,
  amount_minor int,
  note         text,
  paid_at      timestamptz,
  updated_by   uuid references auth.users(id) on delete set null,
  updated_at   timestamptz not null default now(),
  primary key (student_id, month),
  constraint fee_payments_month_ck check (month = date_trunc('month', month)::date)
);
create index if not exists idx_lessons_class_day on public.lessons (class_id, held_on desc);
alter table public.lessons    enable row level security;
alter table public.attendance enable row level security;
alter table public.fee_payments   enable row level security;
revoke all on public.lessons, public.attendance, public.fee_payments from public, anon, authenticated;

-- ------------------------------------------------- ders + istirak
create or replace function public.rpc_lesson_mark(
  p_class_id uuid, p_held_on date, p_present uuid[], p_absent uuid[] default '{}')
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_class public.classes%rowtype := app.plan_class(p_class_id);
  v_lid   uuid;
  v_bad   int;
begin
  if p_held_on is null or p_held_on > current_date + 1 then
    raise exception 'Tarix duzgun deyil.' using errcode = '22023';
  end if;
  --  yalniz bu qrupun sagirdleri
  select count(*) into v_bad from unnest(coalesce(p_present, '{}') || coalesce(p_absent, '{}')) x
   where not exists (select 1 from public.students s where s.id = x and s.class_id = p_class_id);
  if v_bad > 0 then
    raise exception 'Sagird bu qrupda deyil.' using errcode = '22023';
  end if;
  insert into public.lessons (class_id, held_on, created_by)
  values (p_class_id, p_held_on, auth.uid())
  on conflict (class_id, held_on) do update set created_by = excluded.created_by
  returning id into v_lid;
  insert into public.attendance (lesson_id, student_id, present)
  select v_lid, x, true from unnest(coalesce(p_present, '{}')) x
  union all
  select v_lid, x, false from unnest(coalesce(p_absent, '{}')) x
  on conflict (lesson_id, student_id) do update set present = excluded.present;
  return jsonb_build_object('lesson_id', v_lid,
           'present', (select count(*) from public.attendance where lesson_id = v_lid and present),
           'absent',  (select count(*) from public.attendance where lesson_id = v_lid and not present));
end $$;

create or replace function public.rpc_lesson_delete(p_lesson_id uuid)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare v_cls uuid;
begin
  select class_id into v_cls from public.lessons where id = p_lesson_id;
  if v_cls is null then
    raise exception 'Ders tapilmadi.' using errcode = '22023';
  end if;
  perform app.plan_class(v_cls);
  delete from public.lessons where id = p_lesson_id;
  return jsonb_build_object('ok', true);
end $$;

-- ------------------------------------------------- odenis
create or replace function public.rpc_payment_set(
  p_student_id uuid, p_month date, p_paid boolean,
  p_amount_minor int default null, p_note text default null)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare v_cls uuid; v_month date := date_trunc('month', p_month)::date;
begin
  select class_id into v_cls from public.students where id = p_student_id;
  if v_cls is null then
    raise exception 'Sagird tapilmadi.' using errcode = '22023';
  end if;
  perform app.plan_class(v_cls);
  insert into public.fee_payments (student_id, month, paid, amount_minor, note, paid_at, updated_by)
  values (p_student_id, v_month, coalesce(p_paid, false), p_amount_minor, nullif(btrim(coalesce(p_note, '')), ''),
          case when p_paid then now() end, auth.uid())
  on conflict (student_id, month) do update
    set paid = excluded.paid,
        amount_minor = coalesce(excluded.amount_minor, public.fee_payments.amount_minor),
        note = coalesce(excluded.note, public.fee_payments.note),
        paid_at = case when excluded.paid then coalesce(public.fee_payments.paid_at, now()) else null end,
        updated_by = excluded.updated_by, updated_at = now();
  return jsonb_build_object('ok', true, 'paid', coalesce(p_paid, false));
end $$;

-- ------------------------------------------------- ayin defteri
create or replace function public.rpc_ledger_get(p_class_id uuid, p_month date default null)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare
  v_class public.classes%rowtype := app.plan_class(p_class_id);
  v_m  date := date_trunc('month', coalesce(p_month, current_date))::date;
  v_m2 date := (date_trunc('month', coalesce(p_month, current_date)) + interval '1 month')::date;
begin
  return jsonb_build_object(
    'month', to_char(v_m, 'YYYY-MM-DD'),
    'lessons', coalesce((
      select jsonb_agg(jsonb_build_object('id', l.id, 'held_on', l.held_on,
               'present', (select count(*) from public.attendance a where a.lesson_id = l.id and a.present),
               'absent',  (select count(*) from public.attendance a where a.lesson_id = l.id and not a.present))
             order by l.held_on desc)
        from public.lessons l
       where l.class_id = p_class_id and l.held_on >= v_m and l.held_on < v_m2), '[]'::jsonb),
    --  bu gunun dersi (varsa) - veraq onunla dolur
    'today', (select jsonb_build_object('id', l.id,
                'present', coalesce((select jsonb_agg(a.student_id) from public.attendance a
                                      where a.lesson_id = l.id and a.present), '[]'::jsonb),
                'absent',  coalesce((select jsonb_agg(a.student_id) from public.attendance a
                                      where a.lesson_id = l.id and not a.present), '[]'::jsonb))
                from public.lessons l where l.class_id = p_class_id and l.held_on = current_date),
    'students', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', s.id, 'name', s.full_name,
               'present', (select count(*) from public.attendance a
                            join public.lessons l on l.id = a.lesson_id
                           where a.student_id = s.id and a.present
                             and l.held_on >= v_m and l.held_on < v_m2),
               'absent',  (select count(*) from public.attendance a
                            join public.lessons l on l.id = a.lesson_id
                           where a.student_id = s.id and not a.present
                             and l.held_on >= v_m and l.held_on < v_m2),
               'paid',    coalesce((select p.paid from public.fee_payments p
                                     where p.student_id = s.id and p.month = v_m), false),
               'has_pay', exists (select 1 from public.fee_payments p
                                   where p.student_id = s.id and p.month = v_m),
               'amount_minor', (select p.amount_minor from public.fee_payments p
                                 where p.student_id = s.id and p.month = v_m),
               'note',    (select p.note from public.fee_payments p
                            where p.student_id = s.id and p.month = v_m))
             order by s.full_name)
        from public.students s
       where s.class_id = p_class_id and s.is_active), '[]'::jsonb));
end $$;

revoke all on function public.rpc_lesson_mark(uuid, date, uuid[], uuid[]) from public, anon;
grant execute on function public.rpc_lesson_mark(uuid, date, uuid[], uuid[]) to authenticated;
revoke all on function public.rpc_lesson_delete(uuid) from public, anon;
grant execute on function public.rpc_lesson_delete(uuid) to authenticated;
revoke all on function public.rpc_payment_set(uuid, date, boolean, int, text) from public, anon;
grant execute on function public.rpc_payment_set(uuid, date, boolean, int, text) to authenticated;
revoke all on function public.rpc_ledger_get(uuid, date) from public, anon;
grant execute on function public.rpc_ledger_get(uuid, date) to authenticated;

-- ------------------------------------------------- valideyn: bu ayin istiraki
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

