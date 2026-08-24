-- =====================================================================
--  10_teyinat_migrasiya.sql   -   TEYINATLAR
--
--  01..08 fayllarini artiq isletmis bazaya BIR DEFE bunu isledirsen.
--  Basqa fayla toxunmaq lazim deyil.  Tekrar isledilse zerer vermir.
--
--    1. assignments cedveli + classes.free_practice + app.assignment_open()
--    2. RLS siyasetleri
--    3. sagird RPC-leri yenilenir
--    4. muellim teyinat RPC-leri
--    5. huquqlar + ozunu yoxlama
-- =====================================================================

-- =====================================================================
--  1. SXEM
-- =====================================================================
-- ------------------------------------------------------------ teyinatlar
--  Muellim testi QRUPA teyin edir. Sagird oz daimi kodu ile girib aktiv
--  tapsiriqlari gorur - her test ucun ayrica kod paylanmir.
--  tests.class_id kifayet deyildi: platforma testini qrupa teyin etmek
--  olmurdu, eyni testi iki qrupa vermek olmurdu, son tarix yox idi.
-- Qrup ayari: sagird pulsuz platforma testlerini serbest gore bilsinmi?
do $$ begin
  alter table public.classes
    add column free_practice boolean not null default true;
exception when duplicate_column then null; end $$;

comment on column public.classes.free_practice is
  'true: sagird teyinatdan elave pulsuz platforma testlerini de gorur';

create table if not exists public.assignments (
  id           uuid primary key default gen_random_uuid(),
  class_id     uuid not null references public.classes(id) on delete cascade,
  test_id      uuid not null references public.tests(id)   on delete cascade,
  assigned_by  uuid references public.profiles(id) on delete set null,
  opens_at     timestamptz not null default now(),
  closes_at    timestamptz,                    -- null = son tarix yoxdur
  max_attempts smallint not null default 1,    -- 0 = limitsiz
  note         text not null default '',
  created_at   timestamptz not null default now(),
  unique (class_id, test_id),
  constraint assignments_window_ck check (closes_at is null or closes_at > opens_at),
  constraint assignments_attempts_ck check (max_attempts between 0 and 20)
);

create index if not exists idx_assign_class on public.assignments(class_id);
create index if not exists idx_assign_test  on public.assignments(test_id);
create index if not exists idx_assign_open  on public.assignments(class_id, opens_at, closes_at);

-- Teyinat aktivdirmi?
create or replace function app.assignment_open(a public.assignments) returns boolean
language sql immutable as $$
  select a.opens_at <= now() and (a.closes_at is null or a.closes_at > now())
$$;




-- =====================================================================
--  2. RLS
-- =====================================================================
-- --------------------------------------------------------- teyinatlar
alter table public.assignments enable row level security;

drop policy if exists p_assign_read on public.assignments;
create policy p_assign_read on public.assignments
  for select using (exists (
    select 1 from public.classes c
     where c.id = class_id
       and (c.teacher_id = auth.uid() or app.is_account_member(c.account_id)
            or app.is_admin())));

drop policy if exists p_assign_write on public.assignments;
create policy p_assign_write on public.assignments
  for all using (exists (
    select 1 from public.classes c
     where c.id = class_id
       and (c.teacher_id = auth.uid() or app.is_account_member(c.account_id)
            or app.is_admin())))
  with check (exists (
    select 1 from public.classes c
     where c.id = class_id
       and (c.teacher_id = auth.uid() or app.is_account_member(c.account_id)
            or app.is_admin())));



-- =====================================================================
--  3. SAGIRD RPC-LERI  (yenilenir)
-- =====================================================================
create or replace function public.rpc_student_tests(p_token text)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_student uuid := app.session_student(p_token);
  v_class   uuid;
  v_account uuid;
  v_paid    boolean;
  v_free    boolean;
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
                 'questions', (select count(*) from public.questions q where q.test_id = t.id),
                 'time_limit_sec', t.time_limit_sec,
                 'max_attempts',   a.max_attempts,
                 'closes_at',      a.closes_at,
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
                 'questions', (select count(*) from public.questions q where q.test_id = t.id),
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
           -- Teyin olunmuşdursa "Tapsiriqlar"da gorunur, burada tekrarlanmasin
           and not exists (select 1 from public.assignments a
                            where a.class_id = v_class and a.test_id = t.id
                              and app.assignment_open(a.*))
      ) z), '[]'::jsonb) end
  );
end $$;

create or replace function public.rpc_start_attempt(p_token text, p_test_id uuid)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_student uuid := app.session_student(p_token);
  v_class   uuid;
  v_account uuid;
  v_test    public.tests%rowtype;
  v_asg     public.assignments%rowtype;
  v_free    boolean;
  v_limit   int;
  v_done    int;
  v_attempt uuid;
begin
  if v_student is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;
  select class_id, account_id into v_class, v_account
    from public.students where id = v_student;

  select * into v_test from public.tests where id = p_test_id and status = 'published';
  if not found then
    raise exception 'Test tapilmadi.' using errcode = '22023';
  end if;

  -- ACIQ teyinat varsa onun qaydalari isleyir.
  -- Vaxti bitmis teyinat testi bloklamir: test yeniden serbest mesq
  -- hovuzuna qayidir (rpc_student_tests de onu orada gosterir).
  select a.* into v_asg from public.assignments a
   where a.class_id = v_class and a.test_id = p_test_id
     and app.assignment_open(a.*);

  if v_asg.id is not null then
    v_limit := v_asg.max_attempts;
  else
    -- Acıq teyinat yoxdur: serbest mesq yolu
    select free_practice into v_free from public.classes where id = v_class;
    if v_test.owner_type <> 'platform' then
      -- Muellimin oz testi yalniz teyinatla acilir
      if exists (select 1 from public.assignments a
                  where a.class_id = v_class and a.test_id = p_test_id) then
        raise exception 'Bu tapsirigin vaxti bitib.' using errcode = '42501';
      end if;
      raise exception 'Bu test sizin qrup ucun teyin olunmayib.' using errcode = '42501';
    end if;
    if not coalesce(v_free, true) then
      if exists (select 1 from public.assignments a
                  where a.class_id = v_class and a.test_id = p_test_id) then
        raise exception 'Bu tapsirigin vaxti bitib.' using errcode = '42501';
      end if;
      raise exception 'Muelliminiz serbest mesqi baglayib.' using errcode = '42501';
    end if;
    v_limit := v_test.max_attempts;
  end if;

  -- Odenis heddi
  if not v_test.is_free and not app.has_active_subscription(v_account) then
    raise exception 'Bu test abune paketine daxildir.' using errcode = '42501';
  end if;

  -- Cehd limiti
  if v_limit > 0 then
    select count(*) into v_done from public.attempts
     where student_id = v_student and test_id = p_test_id and status = 'submitted';
    if v_done >= v_limit then
      raise exception 'Bu testi artiq % defe islemisiniz.', v_done using errcode = '42501';
    end if;
  end if;

  -- Yarimciq qalmis cehd varsa onu davam etdiririk
  select id into v_attempt from public.attempts
   where student_id = v_student and test_id = p_test_id and status = 'in_progress'
   order by started_at desc limit 1;

  if v_attempt is null then
    insert into public.attempts (student_id, test_id, class_id)
    values (v_student, p_test_id, v_class)
    returning id into v_attempt;
  end if;

  return jsonb_build_object(
    'attempt_id', v_attempt,
    'test', jsonb_build_object(
              'id', v_test.id, 'title', v_test.title,
              'time_limit_sec', v_test.time_limit_sec,
              'pass_percent',   v_test.pass_percent),
    'questions', coalesce((
      select jsonb_agg(qq order by qq->>'ord')
      from (
        select jsonb_build_object(
                 'id',   q.id,
                 'ord',  case when v_test.shuffle_questions
                              then lpad((row_number() over (order by md5(q.id::text || v_attempt::text)))::text, 4, '0')
                              else lpad(q.ord::text, 4, '0') end,
                 'kind', q.kind,
                 'body', q.body,
                 'media_url', q.media_url,
                 'options', coalesce((
                    select jsonb_agg(jsonb_build_object('id', o.id, 'body', o.body)
                             order by case when v_test.shuffle_options
                                           then md5(o.id::text || v_attempt::text)
                                           else lpad(o.ord::text, 4, '0') end)
                      from public.question_options o
                     where o.question_id = q.id), '[]'::jsonb)
               ) as qq
          from public.questions q
         where q.test_id = p_test_id
      ) z), '[]'::jsonb)
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
    select q.id, q.kind, q.points, q.topic_id,
           coalesce((select array_agg(o.id order by o.id) from public.question_options o
                      where o.question_id = q.id and o.is_correct), '{}') as correct_ids,
           coalesce((select array_agg(lower(btrim(o.body))) from public.question_options o
                      where o.question_id = q.id and o.is_correct), '{}') as correct_texts,
           (select a from jsonb_array_elements(coalesce(p_answers,'[]'::jsonb)) a
             where a->>'q' = q.id::text limit 1) as ans
      from public.questions q
     where q.test_id = v_att.test_id
  loop
    declare
      v_sel  uuid[] := '{}';
      v_txt  text;
      v_ok   boolean := false;
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

      if r.kind = 'text' then
        v_ok := v_txt is not null and lower(v_txt) = any (r.correct_texts);
      else
        v_ok := array_length(r.correct_ids,1) is not null
                and v_sel @> r.correct_ids and r.correct_ids @> v_sel;
      end if;

      if v_ok then v_score := v_score + r.points; end if;

      insert into public.attempt_answers
        (attempt_id, question_id, topic_id, selected_option_ids, text_answer, is_correct, points)
      values
        (p_attempt_id, r.id, r.topic_id, v_sel, v_txt, v_ok, case when v_ok then r.points else 0 end)
      on conflict (attempt_id, question_id) do update
        set selected_option_ids = excluded.selected_option_ids,
            text_answer         = excluded.text_answer,
            is_correct          = excluded.is_correct,
            points              = excluded.points,
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
    -- "Bir de cehd ede bilersen" yazisi ucun: hele cehd qalibmi?
    'can_retry',    v_limit = 0 or
                    (select count(*) from public.attempts a2
                      where a2.student_id = v_student and a2.test_id = v_att.test_id
                        and a2.status = 'submitted') < v_limit,
    'wrong', coalesce((
      select jsonb_agg(jsonb_build_object('question_id', aa.question_id, 'body', q.body,
                                          'explanation', q.explanation))
        from public.attempt_answers aa
        join public.questions q on q.id = aa.question_id
       where aa.attempt_id = v_att.id and aa.is_correct is not true), '[]'::jsonb)
  );
end $$;


-- =====================================================================
--  4. MUELLIM: TEYINAT RPC-LERI
-- =====================================================================
create or replace function public.rpc_assign_test(
  p_class_id uuid, p_test_id uuid,
  p_closes_at timestamptz default null,
  p_max_attempts int default 1)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid   uuid := auth.uid();
  v_class public.classes%rowtype;
  v_test  public.tests%rowtype;
  v_id    uuid;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;

  select * into v_class from public.classes where id = p_class_id;
  if not found then
    raise exception 'Qrup tapilmadi.' using errcode = '22023';
  end if;
  if v_class.teacher_id <> v_uid and not app.is_account_member(v_class.account_id) then
    raise exception 'Bu qrupa test teyin ede bilmezsiniz.' using errcode = '42501';
  end if;

  select * into v_test from public.tests where id = p_test_id and status = 'published';
  if not found then
    raise exception 'Test tapilmadi.' using errcode = '22023';
  end if;
  -- Muellim yalniz platforma testini ve ya OZ testini teyin ede biler
  if v_test.owner_type = 'educator' and v_test.owner_id <> v_uid then
    raise exception 'Bu test sizin deyil.' using errcode = '42501';
  end if;
  if p_max_attempts is null or p_max_attempts < 0 or p_max_attempts > 20 then
    raise exception 'Cehd sayi 0-20 araliginda olmalidir.' using errcode = '22023';
  end if;
  if p_closes_at is not null and p_closes_at <= now() then
    raise exception 'Son tarix kecmisde ola bilmez.' using errcode = '22023';
  end if;

  insert into public.assignments (class_id, test_id, assigned_by, closes_at, max_attempts)
  values (p_class_id, p_test_id, v_uid, p_closes_at, p_max_attempts)
  on conflict (class_id, test_id) do update
    set closes_at = excluded.closes_at,
        max_attempts = excluded.max_attempts,
        opens_at = now(),
        assigned_by = excluded.assigned_by
  returning id into v_id;

  return jsonb_build_object('id', v_id, 'test', v_test.title);
end $$;

create or replace function public.rpc_unassign_test(p_assignment_id uuid)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare v_class uuid;
begin
  select a.class_id into v_class
    from public.assignments a
    join public.classes c on c.id = a.class_id
   where a.id = p_assignment_id
     and (c.teacher_id = auth.uid() or app.is_account_member(c.account_id));
  if v_class is null then
    raise exception 'Teyinat tapilmadi.' using errcode = '42501';
  end if;
  delete from public.assignments where id = p_assignment_id;
  return jsonb_build_object('ok', true);
end $$;

-- ------------------------------------ muellim: teyin edile bilen testler
create or replace function public.rpc_available_tests(p_class_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid   uuid := auth.uid();
  v_class public.classes%rowtype;
begin
  select * into v_class from public.classes where id = p_class_id;
  if not found or (v_class.teacher_id <> v_uid
                   and not app.is_account_member(v_class.account_id)) then
    raise exception 'Bu qrupa giris huququnuz yoxdur.' using errcode = '42501';
  end if;

  return coalesce((
    select jsonb_agg(x order by x->>'subject', x->>'title')
    from (
      select jsonb_build_object(
               'id',        t.id,
               'title',     t.title,
               'subject',   sub.name,
               'level',     lv.name,
               'is_free',   t.is_free,
               'mine',      t.owner_type = 'educator',
               'questions', (select count(*) from public.questions q where q.test_id = t.id),
               'assigned',  (select a.id from public.assignments a
                              where a.class_id = p_class_id and a.test_id = t.id)
             ) as x
        from public.tests t
        join public.subjects sub on sub.id = t.subject_id
        left join public.levels lv on lv.id = t.level_id
       where t.status = 'published'
         and (t.owner_type = 'platform' or t.owner_id = v_uid)
         and (v_class.level_id is null or t.level_id is null or t.level_id = v_class.level_id)
    ) z
  ), '[]'::jsonb);
end $$;

-- ---------------------------------------- muellim: qrupun teyinatlari
create or replace function public.rpc_class_assignments(p_class_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid   uuid := auth.uid();
  v_class public.classes%rowtype;
  v_total int;
begin
  select * into v_class from public.classes where id = p_class_id;
  if not found or (v_class.teacher_id <> v_uid
                   and not app.is_account_member(v_class.account_id)) then
    raise exception 'Bu qrupa giris huququnuz yoxdur.' using errcode = '42501';
  end if;

  select count(*) into v_total from public.students
   where class_id = p_class_id and is_active;

  return jsonb_build_object(
    'free_practice', v_class.free_practice,
    'students', v_total,
    'items', coalesce((
      select jsonb_agg(x order by (x->>'open')::boolean desc, x->>'closes_at')
      from (
        select jsonb_build_object(
                 'id',        a.id,
                 'test_id',   t.id,
                 'title',     t.title,
                 'subject',   sub.name,
                 'questions', (select count(*) from public.questions q where q.test_id = t.id),
                 'closes_at', a.closes_at,
                 'max_attempts', a.max_attempts,
                 'open',      app.assignment_open(a.*),
                 -- Nece sagird bitirib ve ortalama netice
                 'done',      (select count(distinct at.student_id)
                                 from public.attempts at
                                 join public.students s on s.id = at.student_id
                                where at.test_id = t.id and s.class_id = p_class_id
                                  and at.status = 'submitted'),
                 'avg',       (select round(avg(best), 0) from (
                                 select max(at.percent) best
                                   from public.attempts at
                                   join public.students s on s.id = at.student_id
                                  where at.test_id = t.id and s.class_id = p_class_id
                                    and at.status = 'submitted'
                                  group by at.student_id) b)
               ) as x
          from public.assignments a
          join public.tests t on t.id = a.test_id
          join public.subjects sub on sub.id = t.subject_id
         where a.class_id = p_class_id
      ) z), '[]'::jsonb)
  );
end $$;

-- ---------------------------------------------------------------- huquq
revoke all on function public.rpc_assign_test(uuid, uuid, timestamptz, int) from public;
revoke all on function public.rpc_unassign_test(uuid)                       from public;
revoke all on function public.rpc_available_tests(uuid)                     from public;
revoke all on function public.rpc_class_assignments(uuid)                   from public;

grant execute on function public.rpc_assign_test(uuid, uuid, timestamptz, int) to authenticated;
grant execute on function public.rpc_unassign_test(uuid)                       to authenticated;
grant execute on function public.rpc_available_tests(uuid)                     to authenticated;
grant execute on function public.rpc_class_assignments(uuid)                   to authenticated;

do $$
declare bad text;
begin
  select string_agg(f, ', ') into bad from unnest(array[
    'public.rpc_assign_test(uuid, uuid, timestamptz, int)',
    'public.rpc_unassign_test(uuid)',
    'public.rpc_available_tests(uuid)',
    'public.rpc_class_assignments(uuid)']) f
   where not has_function_privilege('authenticated', f, 'EXECUTE');
  if bad is not null then
    raise exception 'authenticated bu funksiyalari cagira bilmir: %', bad;
  end if;
  raise notice 'Teyinat funksiyalari acildi.';
end $$;


-- =====================================================================
--  5. HUQUQLAR
--  DIQQET: PostgREST EXECUTE huququ olmayan funksiyani "yoxdur" kimi
--  gosterir (404).  Ona gore sonda ozunu yoxlayir.
-- =====================================================================
grant select, insert, update, delete on public.assignments to authenticated;

do $$
declare bad text;
begin
  if not has_table_privilege('authenticated', 'public.assignments', 'SELECT') then
    raise exception 'authenticated assignments cedvelini goremir';
  end if;
  if has_table_privilege('anon', 'public.assignments', 'SELECT') then
    raise exception 'anon assignments cedvelini gorur - olmamalidir';
  end if;

  select string_agg(f, ', ') into bad from unnest(array[
    'public.rpc_assign_test(uuid, uuid, timestamptz, int)',
    'public.rpc_unassign_test(uuid)',
    'public.rpc_available_tests(uuid)',
    'public.rpc_class_assignments(uuid)']) f
   where not has_function_privilege('authenticated', f, 'EXECUTE');
  if bad is not null then
    raise exception 'muellim bu funksiyalari cagira bilmir: %', bad;
  end if;

  select string_agg(f, ', ') into bad from unnest(array[
    'public.rpc_student_tests(text)',
    'public.rpc_start_attempt(text, uuid)',
    'public.rpc_submit_attempt(text, uuid, jsonb)']) f
   where not has_function_privilege('anon', f, 'EXECUTE');
  if bad is not null then
    raise exception 'sagird bu funksiyalari cagira bilmir: %', bad;
  end if;

  raise notice 'Teyinatlar quruldu: cedvel, RLS, RPC ve huquqlar yerindedir.';
end $$;
