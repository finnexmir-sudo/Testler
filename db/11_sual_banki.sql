-- =====================================================================
--  11_sual_banki.sql   -   SUAL BANKI
--
--  01..10 fayllarini isletmis bazaya BIR DEFE bunu isledirsen.
--  Tekrar isledilse zerer vermir.  Melumat itkisi YOXDUR.
--
--  Ne deyisir:
--    Evvel:  sual TESTIN icinde yasayirdi (questions.test_id not null)
--    Indi:   sual BANKDA yasayir, test onu test_questions ile goturur
--
--  Niye:  generator "100 sualdan 20 sec" ede bilmek ucun hovuz teleb
--         edir; ve testi "yenilemek" suallari silmek olmamalidir -
--         attempt_answers onlara baglidir, tarixce oler.
-- =====================================================================

-- =====================================================================
--  1. BANK: yeni sutunlar
-- =====================================================================
alter table public.questions
  add column if not exists owner_type  test_owner not null default 'platform',
  add column if not exists owner_id    uuid references public.profiles(id) on delete cascade,
  add column if not exists account_id  uuid references public.accounts(id) on delete cascade,
  add column if not exists subject_id  uuid references public.subjects(id) on delete restrict,
  add column if not exists level_id    uuid references public.levels(id)   on delete set null,
  add column if not exists tags        text[] not null default '{}',
  add column if not exists quarter     smallint,
  add column if not exists month       smallint,
  add column if not exists status      content_status not null default 'published',
  add column if not exists ext_key     text,
  add column if not exists created_by  uuid references public.profiles(id) on delete set null,
  add column if not exists updated_at  timestamptz not null default now();

-- =====================================================================
--  2. TERKIB cedveli
-- =====================================================================
create table if not exists public.test_questions (
  test_id     uuid not null references public.tests(id)     on delete cascade,
  question_id uuid not null references public.questions(id) on delete restrict,
  ord         int  not null,
  points      numeric(5,2),
  primary key (test_id, question_id),
  unique (test_id, ord)
);

-- Kohne siyasetler test_id sutununa baglidir - once onlar getmelidir,
-- yoxsa "drop column" imtina edir.
drop policy if exists p_questions_all on public.questions;
drop policy if exists p_options_all   on public.question_options;

-- =====================================================================
--  3. MELUMATIN KOCURULMESI
--     Movcud suallar hansi testdedirse, o baglanti terkib cedveline
--     kocur; fenn/sinif/sahiblik hemin testden goturulur.
-- =====================================================================
do $$
declare n int;
begin
  if exists (select 1 from information_schema.columns
              where table_schema='public' and table_name='questions'
                and column_name='test_id') then

    -- 3a. terkib
    insert into public.test_questions (test_id, question_id, ord)
    select q.test_id, q.id, q.ord from public.questions q
     where q.test_id is not null
    on conflict do nothing;
    get diagnostics n = row_count;
    raise notice 'Terkibe kocurulen sual: %', n;

    -- 3b. metadata testden
    update public.questions q
       set subject_id = coalesce(q.subject_id, t.subject_id),
           level_id   = coalesce(q.level_id,   t.level_id),
           owner_type = t.owner_type,
           owner_id   = case when t.owner_type = 'educator' then t.owner_id end,
           account_id = case when t.owner_type = 'educator'
                             then (select c.account_id from public.classes c
                                    where c.id = t.class_id)
                        end
      from public.tests t
     where t.id = q.test_id;

    -- 3c. hesabi tapilmayan muellim sualı: sahibin ilk hesabina baglanir
    update public.questions q
       set account_id = (select am.account_id from public.account_members am
                          where am.user_id = q.owner_id limit 1)
     where q.owner_type = 'educator' and q.account_id is null;

    -- 3d. hele de hesabsiz qalan varsa platformaya kecir (itmesin)
    update public.questions
       set owner_type = 'platform', owner_id = null, account_id = null
     where owner_type = 'educator' and (account_id is null or owner_id is null);

    alter table public.questions drop column test_id;
    alter table public.questions drop column ord;
    raise notice 'questions.test_id ve ord silindi - artiq terkib cedvelindedir.';
  else
    raise notice 'Kocurme artiq edilib, otururuk.';
  end if;
end $$;

-- Platforma seed suallarina sabit acar: 07_seed_tests.sql tekrar
-- isledilende sual coxalmasin deye.  Acar = test slug + sira nomresi.
update public.questions q
   set ext_key = t.slug || '#' || tq.ord
  from public.test_questions tq
  join public.tests t on t.id = tq.test_id
 where tq.question_id = q.id and q.owner_type = 'platform'
   and q.ext_key is null and t.slug is not null;

--  DIQQET: QISMEN indeks olmamalidir.  01_schema.sql-de bu sutun
--  "unique"-dir; qismen indeks yaratsaq 07_seed_tests.sql-in
--  "on conflict (ext_key)" ifadesi ona uygun gelmir:
--    ERROR 42P10: there is no unique or exclusion constraint matching
--  Tam unikal indeksde NULL-lar onsuz da serbestdir.
drop index if exists public.questions_ext_key_key;
create unique index if not exists questions_ext_key_key
  on public.questions(ext_key);

-- =====================================================================
--  4. MEHDUDIYYETLER
--     Cetinlik 1-5 idi, 1-3 olur: Asan · Orta · Cetin.
--     Movcud deyerler 3-den boyukdursa evvelce 3-e endirilir.
-- =====================================================================
update public.questions set difficulty = 3 where difficulty > 3;
update public.questions set difficulty = 1 where difficulty < 1;

alter table public.questions alter column subject_id set not null;

alter table public.questions drop constraint if exists questions_difficulty_ck;
alter table public.questions drop constraint if exists questions_quarter_ck;
alter table public.questions drop constraint if exists questions_month_ck;
alter table public.questions drop constraint if exists questions_body_ck;
alter table public.questions drop constraint if exists questions_owner_ck;

alter table public.questions
  add constraint questions_difficulty_ck check (difficulty between 1 and 3),
  add constraint questions_quarter_ck    check (quarter is null or quarter between 1 and 4),
  add constraint questions_month_ck      check (month   is null or month   between 1 and 12),
  add constraint questions_body_ck       check (length(btrim(body)) between 1 and 2000),
  add constraint questions_owner_ck check (
       (owner_type = 'platform' and owner_id is null and account_id is null)
    or (owner_type = 'educator' and owner_id is not null and account_id is not null)
  );

-- =====================================================================
--  5. CAVABIN SURETI
--     Sual sonradan redakte olunsa da kohne hesabat sagirdin GORDUYU
--     sualı gostersin deye metn cavabla birlikde saxlanilir.
-- =====================================================================
alter table public.attempt_answers
  add column if not exists question_body        text not null default '',
  add column if not exists question_explanation text not null default '';

-- Kohne cavablar ucun suret indi doldurulur (bir defelik)
update public.attempt_answers aa
   set question_body        = q.body,
       question_explanation = q.explanation
  from public.questions q
 where q.id = aa.question_id and aa.question_body = '';

-- =====================================================================
--  6. GENERATOR QAYDASI
-- =====================================================================
alter table public.tests add column if not exists gen_rule jsonb;

-- =====================================================================
--  7. INDEKSLER
-- =====================================================================
drop index if exists public.idx_questions_test;
create index if not exists idx_q_bank on public.questions
  (subject_id, level_id, difficulty, status);
create index if not exists idx_q_topic     on public.questions(topic_id);
create index if not exists idx_q_account   on public.questions(account_id);
create index if not exists idx_q_period    on public.questions(quarter, month);
create index if not exists idx_q_tags      on public.questions using gin (tags);
create index if not exists idx_tq_test     on public.test_questions(test_id, ord);
create index if not exists idx_tq_question on public.test_questions(question_id);

drop trigger if exists trg_questions_touch on public.questions;
create trigger trg_questions_touch before update on public.questions
  for each row execute function app.touch_updated_at();

-- =====================================================================
--  8. RLS
-- =====================================================================
alter table public.test_questions enable row level security;

create or replace function app.can_manage_question(p_q uuid) returns boolean
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select exists (
    select 1 from public.questions q
    where q.id = p_q
      and (app.is_admin()
           or (q.owner_type = 'educator' and app.is_account_member(q.account_id)))
  )
$$;

drop policy if exists p_questions_all  on public.questions;
drop policy if exists p_questions_read on public.questions;
create policy p_questions_read on public.questions
  for select using (
       app.is_admin() or owner_type = 'platform' or app.is_account_member(account_id));

drop policy if exists p_questions_ins on public.questions;
create policy p_questions_ins on public.questions
  for insert with check (
       app.is_admin()
    or (owner_type = 'educator' and owner_id = auth.uid()
        and app.is_account_member(account_id)));

drop policy if exists p_questions_upd on public.questions;
create policy p_questions_upd on public.questions
  for update using (app.can_manage_question(id)) with check (app.can_manage_question(id));

drop policy if exists p_questions_del on public.questions;
create policy p_questions_del on public.questions
  for delete using (app.can_manage_question(id));

drop policy if exists p_options_all on public.question_options;
create policy p_options_all on public.question_options
  for all using (app.can_manage_question(question_id))
  with check  (app.can_manage_question(question_id));

drop policy if exists p_tq_read on public.test_questions;
create policy p_tq_read on public.test_questions
  for select using (app.can_manage_test(test_id));

drop policy if exists p_tq_write on public.test_questions;
create policy p_tq_write on public.test_questions
  for all using (app.can_manage_test(test_id))
  with check (app.can_manage_test(test_id));

-- =====================================================================
--  10. FUNKSIYALAR
--      Bunlar evvel questions.test_id-ye baxirdi - indi test_questions
--      uzerinden gedir, ve cavab yazilarken sualin sureti saxlanilir.
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
                 'questions', (select count(*) from public.test_questions tq where tq.test_id = t.id),
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
                              else lpad(tq.ord::text, 4, '0') end,
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
          from public.test_questions tq
          join public.questions q on q.id = tq.question_id
         where tq.test_id = p_test_id
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

      --  Sualin metni de yazilir: muellim sonradan sual redakte etse,
      --  bu hesabat hele de sagirdin GORDUYU sual gosterecek.
      insert into public.attempt_answers
        (attempt_id, question_id, topic_id, selected_option_ids, text_answer,
         is_correct, points, question_body, question_explanation)
      values
        (p_attempt_id, r.id, r.topic_id, v_sel, v_txt, v_ok,
         case when v_ok then r.points else 0 end, r.q_body, r.q_expl)
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
    -- "Bir de cehd ede bilersen" yazisi ucun: hele cehd qalibmi?
    'can_retry',    v_limit = 0 or
                    (select count(*) from public.attempts a2
                      where a2.student_id = v_student and a2.test_id = v_att.test_id
                        and a2.status = 'submitted') < v_limit,
    'wrong', coalesce((
      --  Suret: sagird hansi sual gorubse, onu gosteririk.
      --  Sual sonradan redakte olunsa da bu netice deyismir.
      select jsonb_agg(jsonb_build_object('question_id', aa.question_id,
                                          'body', aa.question_body,
                                          'explanation', aa.question_explanation))
        from public.attempt_answers aa
       where aa.attempt_id = v_att.id and aa.is_correct is not true), '[]'::jsonb)
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
    'test', jsonb_build_object('id', v_test.id, 'title', v_test.title,
                               'pass_percent', v_test.pass_percent),
    'wrong', coalesce((
      --  Suret: sagird hansi sual gorubse, onu gosteririk.
      --  Sual sonradan redakte olunsa da bu netice deyismir.
      select jsonb_agg(jsonb_build_object('question_id', aa.question_id,
                                          'body', aa.question_body,
                                          'explanation', aa.question_explanation))
        from public.attempt_answers aa
       where aa.attempt_id = v_att.id and aa.is_correct is not true), '[]'::jsonb)
  );
end $$;

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
         group by t.name, sub.name
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
               'questions', (select count(*) from public.test_questions tq where tq.test_id = t.id),
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
                 'questions', (select count(*) from public.test_questions tq where tq.test_id = t.id),
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

-- =====================================================================
--  9. HUQUQLAR
-- =====================================================================
grant select, insert, update, delete on public.test_questions to authenticated;

do $$
declare n int;
begin
  if has_table_privilege('anon', 'public.test_questions', 'SELECT') then
    raise exception 'anon test_questions cedvelini gorur - olmamalidir';
  end if;
  if has_table_privilege('anon', 'public.questions', 'SELECT') then
    raise exception 'anon questions cedvelini gorur - cavab acari sizir';
  end if;
  if exists (select 1 from information_schema.columns
              where table_schema='public' and table_name='questions'
                and column_name='test_id') then
    raise exception 'questions.test_id hele de var - kocurme tamamlanmayib';
  end if;
  select count(*) into n from public.questions q
   where not exists (select 1 from public.test_questions tq where tq.question_id = q.id)
     and not exists (select 1 from public.attempt_answers aa where aa.question_id = q.id);
  raise notice 'Sual banki quruldu.  Bankda % sual, terkibde % baglanti, sahibsiz %.',
    (select count(*) from public.questions),
    (select count(*) from public.test_questions), n;
end $$;
