-- =====================================================================
--  191_ev_tapsirigi.sql : metnle ev tapsirigi - «12-ci paraqrafi oxu»
--
--  NIYE.  Bizde «tapsiriq» hemise TEST idi.  Repetitor her dersden sonra
--  «bunu oxu, bunu tekrarla, defterde 5 mesele» deyir - proqramda bunun
--  yeri yox idi, WhatsApp-a yazilirdi, valideyn gormurdu.  Istifadeci:
--  «muellimde, sagirdde, valideynde her seyi gorur».
--
--  Qurulus:
--    homework(class_id, student_id NULL=butun qrup, body <= 500, due)
--    homework_done(homework_id, student_id) - sagird «etdim» deyir
--  Muellim: rpc_homework_add / rpc_homework_list / rpc_homework_del
--  Sagird:  rpc_student_tests -> 'homework' (movcud cagiris, yeni acar)
--           rpc_student_homework_done(p_token, p_id, p_done)  - YENI ANON
--  Valideyn: rpc_parent_home -> 'homework' (movcud cagiris, yeni acar)
--
--  Anon siyahisi 20 -> 21 (05_grants, smoke_huquq).  05_grants-i
--  bu fayldan SONRA yeniden isle.
--
--  rpc_student_tests ve rpc_parent_home govdeleri pg_get_functiondef ile
--  canli bazadan goturulub, YALNIZ bir acar elave olunub - elle
--  kocurulmeyib ki, basqa sey deyismesin.
-- =====================================================================

create table if not exists public.homework (
  id         uuid primary key default gen_random_uuid(),
  class_id   uuid not null references public.classes(id) on delete cascade,
  student_id uuid references public.students(id) on delete cascade,   -- NULL = butun qrup
  created_by uuid not null references auth.users(id) on delete cascade,
  body       text not null check (length(btrim(body)) between 1 and 500),
  due        date,
  created_at timestamptz not null default now()
);
create index if not exists homework_class_idx on public.homework (class_id, created_at desc);
alter table public.homework enable row level security;
revoke all on public.homework from public, anon, authenticated;

create table if not exists public.homework_done (
  homework_id uuid not null references public.homework(id) on delete cascade,
  student_id  uuid not null references public.students(id) on delete cascade,
  done_at     timestamptz not null default now(),
  primary key (homework_id, student_id)
);
alter table public.homework_done enable row level security;
revoke all on public.homework_done from public, anon, authenticated;

--  Muellimin qrupa girisi - rpc_assign_test ile eyni qayda
create or replace function app.homework_class_ok(p_class uuid)
returns boolean
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare v_class public.classes%rowtype;
begin
  if auth.uid() is null then return false; end if;
  select * into v_class from public.classes where id = p_class;
  if v_class.id is null then return false; end if;
  return v_class.teacher_id = auth.uid() or app.is_account_member(v_class.account_id);
end $$;
revoke all on function app.homework_class_ok(uuid) from public, anon, authenticated;

--  ---------------------------------------------------------- muellim
create or replace function public.rpc_homework_add(
  p_class_id uuid, p_text text, p_due date default null, p_student_id uuid default null)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare v_id uuid; v_body text := btrim(coalesce(p_text, ''));
begin
  if auth.uid() is null then
    raise exception 'Daxil olmamısınız.' using errcode = '28000';
  end if;
  if not app.homework_class_ok(p_class_id) then
    raise exception 'Bu qrupa tapşırıq yaza bilməzsiniz.' using errcode = '42501';
  end if;
  if length(v_body) < 1 then
    raise exception 'Tapşırığın mətnini yazın.' using errcode = '22023';
  end if;
  if length(v_body) > 500 then
    raise exception 'Mətn 500 hərfdən uzun olmasın.' using errcode = '22023';
  end if;
  if p_student_id is not null and not exists (
       select 1 from public.students s where s.id = p_student_id and s.class_id = p_class_id) then
    raise exception 'Şagird bu qrupda deyil.' using errcode = '22023';
  end if;
  --  gunde 50-den cox yox - sehven dovr olsa baza dolmasin
  if (select count(*) from public.homework h
       where h.class_id = p_class_id and h.created_at > now() - interval '1 day') >= 50 then
    raise exception 'Bu gün üçün kifayətdir — sabah davam edin.' using errcode = '22023';
  end if;
  insert into public.homework (class_id, student_id, created_by, body, due)
  values (p_class_id, p_student_id, auth.uid(), v_body, p_due)
  returning id into v_id;
  return jsonb_build_object('ok', true, 'id', v_id);
end $$;
revoke all on function public.rpc_homework_add(uuid, text, date, uuid) from public, anon;
grant execute on function public.rpc_homework_add(uuid, text, date, uuid) to authenticated;

create or replace function public.rpc_homework_list(p_class_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
begin
  if not app.homework_class_ok(p_class_id) then
    raise exception 'Bu qrupa baxa bilməzsiniz.' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(x order by x->>'created_at' desc)
      from (select jsonb_build_object(
                     'id', h.id, 'body', h.body, 'due', h.due, 'created_at', h.created_at,
                     'student_id', h.student_id,
                     'student', (select s.full_name from public.students s where s.id = h.student_id),
                     --  nece nefer etdi / nece nefere aiddir
                     'done', (select count(*) from public.homework_done hd where hd.homework_id = h.id),
                     'total', case when h.student_id is not null then 1
                              else (select count(*) from public.students s
                                     where s.class_id = h.class_id and s.is_active) end,
                     'done_names', coalesce((select jsonb_agg(s.full_name order by hd.done_at)
                                              from public.homework_done hd
                                              join public.students s on s.id = hd.student_id
                                             where hd.homework_id = h.id), '[]'::jsonb)) as x
              from public.homework h
             where h.class_id = p_class_id
               and h.created_at > now() - interval '90 days'
             limit 60) z), '[]'::jsonb);
end $$;
revoke all on function public.rpc_homework_list(uuid) from public, anon;
grant execute on function public.rpc_homework_list(uuid) to authenticated;

create or replace function public.rpc_homework_del(p_id uuid)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare v_class uuid;
begin
  select class_id into v_class from public.homework where id = p_id;
  if v_class is null or not app.homework_class_ok(v_class) then
    raise exception 'Tapşırıq tapılmadı.' using errcode = '22023';
  end if;
  delete from public.homework where id = p_id;
  return jsonb_build_object('ok', true);
end $$;
revoke all on function public.rpc_homework_del(uuid) from public, anon;
grant execute on function public.rpc_homework_del(uuid) to authenticated;

--  ---------------------------------------------------------- sagird
create or replace function public.rpc_student_homework_done(p_token text, p_id uuid, p_done boolean default true)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare v_student uuid := app.session_student(p_token); v_class uuid;
begin
  if v_student is null then
    raise exception 'Sessiya bitib. Yenidən daxil ol.' using errcode = '28000';
  end if;
  select class_id into v_class from public.students where id = v_student;
  if not exists (select 1 from public.homework h
                  where h.id = p_id and h.class_id = v_class
                    and (h.student_id is null or h.student_id = v_student)) then
    raise exception 'Tapşırıq tapılmadı.' using errcode = '22023';
  end if;
  if coalesce(p_done, true) then
    insert into public.homework_done (homework_id, student_id) values (p_id, v_student)
    on conflict do nothing;
  else
    delete from public.homework_done where homework_id = p_id and student_id = v_student;
  end if;
  return jsonb_build_object('ok', true, 'done', coalesce(p_done, true));
end $$;
revoke all on function public.rpc_student_homework_done(text, uuid, boolean) from public;
grant execute on function public.rpc_student_homework_done(text, uuid, boolean) to anon, authenticated;

--  ---------------------------------------------------------- movcud cagirislar + 'homework'
CREATE OR REPLACE FUNCTION public.rpc_student_tests(p_token text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
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
    --  191: ev tapsirigi (metnle) - son 45 gun, qrupa ve ya mene verilen.
    --  Edilmeyenler evvel, sonra son tarixe gore.
    'homework', coalesce((
      select jsonb_agg(x order by (x->>'done')::boolean, x->>'due' nulls last, x->>'created_at' desc)
        from (select jsonb_build_object(
                       'id', h.id, 'body', h.body, 'due', h.due,
                       'personal', h.student_id is not null,
                       'created_at', h.created_at,
                       'done', exists (select 1 from public.homework_done hd
                                        where hd.homework_id = h.id and hd.student_id = v_student)) as x
                from public.homework h
               where h.class_id = v_class
                 and (h.student_id is null or h.student_id = v_student)
                 and h.created_at > now() - interval '45 days') z), '[]'::jsonb),
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
end $function$;

CREATE OR REPLACE FUNCTION public.rpc_parent_home(p_token text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
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
    --  191: ev tapsirigi (metnle) - valideyn "usaga ne deyilib" gorur
    'homework', coalesce((
      select jsonb_agg(x order by (x->>'done')::boolean, x->>'due' nulls last, x->>'created_at' desc)
        from (select jsonb_build_object(
                       'id', h.id, 'body', h.body, 'due', h.due,
                       'personal', h.student_id is not null,
                       'created_at', h.created_at,
                       'done', exists (select 1 from public.homework_done hd
                                        where hd.homework_id = h.id and hd.student_id = v_sid)) as x
                from public.homework h
               where h.class_id = v_st.class_id
                 and (h.student_id is null or h.student_id = v_sid)
                 and h.created_at > now() - interval '45 days') z), '[]'::jsonb),
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
      --  174: NE BAS VERIB - pulsuz; NECEDIR (tehlil) - abune ile.
      --  Valideyn «Son nəticələr» siyahisini ve tapsiriqlari HEMISE
      --  gorur; ortalama, meyl ve en yaxsi netice muellimin abunesi
      --  ile acilir.  Sebeb (istifadeci qerari): muellimi valideyne
      --  hesabat vermek eziyyetinden qurtaran hisse elə budur.
      'avg30',  case when v_paid then v_now end,
      'prev30', case when v_paid then v_prev end,
      'delta',  case when v_paid and v_now is not null and v_prev is not null
                     then v_now - v_prev end,
      'best',   case when v_paid then
                  (select round(max(a.percent), 0) from public.attempts a
                    where a.student_id = v_sid and a.status = 'submitted') end),

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

    --  133: movzu mesqi
    'practice', (select jsonb_build_object(
                   'mastered', count(*) filter (where p.mastered_at is not null),
                   'active',   count(*) filter (where p.mastered_at is null and p.answered > 0))
                   from public.practice p where p.student_id = v_sid),

    --  177: BU HEFTENIN DERSLERI.  Cedvel qurulmayibsa acar NULL
    --  qayidir - valideyn ekraninda bos «Cədvəl» karti CIXMAMALIDIR
    --  (istifadeci qaydasi: qurulmayan funksiya gorunmur).
    --  PULSUZDUR - abune qapisi yoxdur: «nə baş verir» hissesidir.
    --  Valideyn ekraninda «bu gün» BAKI gunu ile isaretlenir.  Brauzerin
    --  oz tarixi ile hesablansaydi, saat 00:00-04:00 araliginda telefonu
    --  basqa vaxt zonasinda olan valideyn sehv gun gorerdi.
    'today', app.baki_bugun(),
    'week', (select case when count(*) = 0 then null else
               jsonb_agg(jsonb_build_object(
                 'date', w.on_date, 'time', to_char(w.starts_at, 'HH24:MI'),
                 'mins', w.mins, 'hal', w.hal, 'other', w.other)
                 order by w.on_date, w.starts_at) end
               from app.cedvel_araliq(v_st.account_id,
                      (app.baki_bugun() - (extract(isodow from app.baki_bugun())::int - 1))::date,
                      7) w
              where w.class_id = v_st.class_id),

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
end $function$;

--  ---------------------------------------------------------- numune hesab
--  «Muellim kimi bax» - Tapsiriqlar ekraninda ev tapsirigi bolmesi bos
--  gorunmesin.  Hesabin qruplarina bir nece metn, bir hissesi «edilib».
--  demo_build-in sonunda cagirilir (govde pg_get_functiondef ile
--  goturulub, bir setir elave olunub) - gece sifirlanmasi da bunu qurur.
create or replace function app.demo_homework(p_owner uuid, p_account uuid)
returns void
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_c   record;
  v_i   int := 0;
  v_hw  uuid;
  v_st  uuid;
begin
  delete from public.homework where class_id in (select id from public.classes where account_id = p_account);
  for v_c in select id, level_id from public.classes where account_id = p_account order by created_at loop
    v_i := v_i + 1;
    if v_i = 1 then
      --  esas qrup: biri dunen (yarisi edib), biri bu gun, biri ferdi
      insert into public.homework (class_id, created_by, body, due, created_at)
      values (v_c.id, p_owner, 'Dərslik səh. 42–45-i oxu, 3 və 4-cü çalışmanı dəftərdə həll et',
              current_date + 1, now() - interval '1 day')
      returning id into v_hw;
      for v_st in select s.id from public.students s where s.class_id = v_c.id and s.is_active
                   order by s.full_name limit 4 loop
        insert into public.homework_done (homework_id, student_id, done_at)
        values (v_hw, v_st, now() - interval '6 hours') on conflict do nothing;
      end loop;
      insert into public.homework (class_id, created_by, body, due, created_at)
      values (v_c.id, p_owner, 'Keçdiyimiz mövzunu təkrarla — növbəti dərsdə qısa sorğu olacaq',
              current_date + 3, now() - interval '2 hours');
      select s.id into v_st from public.students s where s.class_id = v_c.id and s.is_active
       order by s.full_name desc limit 1;
      if v_st is not null then
        insert into public.homework (class_id, student_id, created_by, body, due, created_at)
        values (v_c.id, v_st, p_owner, 'Səhv dəftərindəki 3 sualı yenidən həll et', current_date + 2,
                now() - interval '2 hours');
      end if;
    elsif v_i = 2 then
      insert into public.homework (class_id, created_by, body, due, created_at)
      values (v_c.id, p_owner, 'Vurma cədvəlini 6-ya qədər əzbərlə', current_date + 4, now() - interval '3 days');
    end if;
  end loop;
end $$;
revoke all on function app.demo_homework(uuid, uuid) from public, anon, authenticated;

CREATE OR REPLACE FUNCTION app.demo_build(p_owner uuid, p_account uuid, p_fixed boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
declare
  v_riy  uuid; v_lm record; v_l3 record; v_l11 record;   -- esas qrup 7-ci sinif
  v_c1 uuid; v_c2 uuid;
  v_names1 text[] := array['Ayan Məmmədova','Murad Həsənov','Nigar Əliyeva','Tural Quliyev','Leyla Hüseynova',
                           'Elvin Rəhimov','Aysel Kərimova','Kənan İbrahimov','Zəhra Abbasova','Rəşad Nəbiyev',
                           'Fidan Səfərova','Orxan Mustafayev'];
  v_names2 text[] := array['Aytac Cəfərova','Nihad Vəliyev','Günel Əhmədova','Rauf Ağayev',
                           'Səbinə Qasımova','Tunar Bağırov','Lalə Hacıyeva','Ülvi Salmanov'];
  v_names3 text[] := array['Cavid Məmmədli','Nərmin Əsgərova','Emil Tağıyev','Aylin Şirinova','Fərid Zeynalov'];
  v_abil3 numeric[] := array[0.88,0.80,0.72,0.66,0.58];
  v_c3 uuid; v_stu3 uuid[] := '{}'; v_plan3 uuid;
  --  1-ci sagird (DEMO0001 / VDEMO001 - numune girisleri) ORTA seviyyeli:
  --  zeif movzu ve sehv defteri gorunsun.  Gucluler 3 ve 4-dur.
  --  Canli baxisdan sonra qaldirildi: orta 50% ve 7 nefer tehluke zonasinda
  --  hedden artiq zeif gorunurdu; hedef orta 60-65%, zonada 3-4 nefer.
  v_abil1 numeric[] := array[0.82,0.94,0.97,0.88,0.85,0.82,0.80,0.78,0.74,0.68,0.60,0.52];
  v_abil2 numeric[] := array[0.90,0.82,0.78,0.74,0.70,0.66,0.60,0.52];
  v_stu1 uuid[] := '{}'; v_stu2 uuid[] := '{}';
  v_sid uuid; v_code text; v_pcode text; i int; k int;
  v_plan uuid; v_plan2 uuid;
  v_items uuid[]; v_topics uuid[]; v_weak uuid[] := '{}';
  v_item uuid; v_topic uuid; v_tname text; v_test uuid; v_at timestamptz; v_days int[] := array[45,40,35,30,25,20,15,10,3];
  v_par record;
  v_exam uuid; v_diag uuid;
  v_month date := date_trunc('month', current_date)::date;
  v_les uuid; v_d date;
  v_q uuid;
  v_code1 text; v_pcode1 text;
begin
  perform setseed(case when p_fixed then 0.4242 else random() end);

  -- ---- temizlik (numune hesabin oz melumati)
  delete from public.classes where account_id = p_account;
  delete from public.tests where owner_type = 'educator' and owner_id = p_owner;
  delete from public.feedback where account_id = p_account;
  delete from public.question_reports where account_id = p_account;
  delete from public.students where account_id = p_account;

  update public.accounts set subjects = '{riyaziyyat}', is_demo = true where id = p_account;
  update public.profiles set full_name = 'Nümunə Müəllim' where id = p_owner and coalesce(full_name, '') in ('', 'Nümunə Müəllim');
  --  183: 169-dan sonra 'repetitor-25' satisdan cixdi (25 yer limiti).
  --  Numunede o paket qalmisdi ve deqiq 25 sagirdle limit HEMISE dolu
  --  idi - gosterisde "Paketin limiti dolub" xeberdarligi cixirdi.
  --  Indi numune canli mehsulun ozunu gosterir: 'sagird-basi', limitsiz.
  delete from public.subscriptions s
   using public.plans p
   where s.account_id = p_account and p.id = s.plan_id and p.slug <> 'sagird-basi';
  if not app.has_active_subscription(p_account) then
    insert into public.subscriptions (account_id, plan_id, status, seats, current_period_end)
    select p_account, p.id, 'active', 1, now() + interval '30 days'
      from public.plans p where p.slug = 'sagird-basi';
  else
    --  Kohne nusxede muddet neceyse qalmisdisa taze yazilir: numune
    --  hemise "aylik abune, novbeti odenis bir aydan sonra" kimi
    --  gorunsun (evvel 365 gun yazilirdi - aylik mehsula uygun deyil).
    update public.subscriptions
       set status = 'active', current_period_end = now() + interval '30 days'
     where account_id = p_account;
  end if;

  select id into v_riy from public.subjects where slug = 'riyaziyyat';
  select l.* into v_lm  from public.levels l where l.code = '7'  order by l.sort limit 1;
  select l.* into v_l3  from public.levels l where l.code = '3'  order by l.sort limit 1;
  select l.* into v_l11 from public.levels l where l.code = '11' order by l.sort limit 1;

  -- ---- qrup 1 (esas, zengin): 7-ci sinif, 12 sagird
  insert into public.classes (account_id, teacher_id, kind, program_id, level_id, name, join_code)
  values (p_account, p_owner, 'tutor_group', v_lm.program_id, v_lm.id, '7-ci sinif — şənbə qrupu', app.gen_login_code(8))
  returning id into v_c1;
  for i in 1..12 loop
    v_code := case when p_fixed then 'DEMO' || lpad(i::text, 4, '0') else app.gen_login_code(8) end;
    v_pcode := case when i = 1 then (case when p_fixed then 'VDEMO001' else 'V' || app.gen_login_code(7) end) else null end;
    insert into public.students (account_id, class_id, created_by, full_name, display_name, login_code, parent_code, created_at)
    values (p_account, v_c1, p_owner, v_names1[i], app.unique_display_name(v_c1, v_names1[i]), v_code, v_pcode,
            now() - interval '50 days' + make_interval(mins => i))
    returning id into v_sid;
    v_stu1 := v_stu1 || v_sid;
    if i = 1 then v_code1 := v_code; v_pcode1 := v_pcode; end if;
  end loop;

  -- ---- plan: riyaziyyat (esas sinif), yarpaqlar, ilk 9 kecilib
  insert into public.class_plans (class_id, subject_id, level_id, created_at)
  values (v_c1, v_riy, v_lm.id, now() - interval '48 days') returning id into v_plan;
  insert into public.class_plan_items (plan_id, topic_id, ord)
  select v_plan, t.id, row_number() over (order by coalesce(par.sort, t.sort), coalesce(par.name, t.name), t.sort, t.name)
    from public.topics t left join public.topics par on par.id = t.parent_id
   where t.subject_id = v_riy and t.level_id = v_lm.id
     and not exists (select 1 from public.topics c where c.parent_id = t.id);
  select array_agg(id order by ord) into v_items from public.class_plan_items where plan_id = v_plan;

  --  zeif movzu (diaqnostikada, hamiya): ilk 9 dersin fesillerinden OLMAYAN
  --  ilk fesil - hovuz ferqli olsun deye
  select t.id into v_topic from public.topics t
   where t.subject_id = v_riy and t.level_id = v_lm.id and t.parent_id is null
     and t.id not in (select tp.o_id from unnest(v_items[1:least(9, cardinality(v_items))]) x
                        join public.class_plan_items it on it.id = x
                        cross join lateral app.pack_topic(it.topic_id) tp)
   order by t.sort limit 1;
  if v_topic is null then
    select tp.o_id into v_topic from app.pack_topic((select topic_id from public.class_plan_items where id = v_items[cardinality(v_items)])) tp;
  end if;
  v_weak := array[v_topic];
  if cardinality(v_items) >= 6 then
    v_weak := v_weak || (select tp.o_id from app.pack_topic((select topic_id from public.class_plan_items where id = v_items[6])) tp);
  end if;

  for i in 1..least(9, cardinality(v_items)) loop
    v_item := v_items[i];
    v_at := now() - make_interval(days => v_days[i]);
    update public.class_plan_items set done_at = v_at where id = v_item;
    select * into v_par from app.pack_topic((select topic_id from public.class_plan_items where id = v_item));
    --  ev tapsirigi
    v_test := app.demo_test(p_owner, v_riy, v_lm.id, v_lm.program_id, array[v_par.o_id], 10,
                v_par.o_name || ' — yoxlama', jsonb_build_object('pack','hw','topics',jsonb_build_array(v_par.o_id::text)),
                '{1,2,3}', null, false, v_at);
    update public.class_plan_items set test_id = v_test where id = v_item;
    insert into public.assignments (class_id, test_id, assigned_by, opens_at, closes_at, max_attempts, created_at)
    values (v_c1, v_test, p_owner, v_at, case when i = 9 then now() + interval '4 days' else v_at + interval '7 days' end, 1, v_at);
    for k in 1..12 loop
      --  sonuncu (acıq) tapsiriq: 4 nefer hele etmeyib
      if i = 9 then
        if k in (3, 7, 10, 12) then continue; end if;
        perform app.demo_attempt(v_stu1[k], v_test, v_c1, v_abil1[k], case when k in (1, 7, 10, 11, 12) then v_weak else v_weak[1:1] end, now() - make_interval(hours => 6 + floor(random() * 60)::int));
      elsif random() < 0.86 then
        perform app.demo_attempt(v_stu1[k], v_test, v_c1, v_abil1[k], case when k in (1, 7, 10, 11, 12) then v_weak else v_weak[1:1] end, v_at + make_interval(hours => 20 + floor(random() * 96)::int));
      end if;
    end loop;
    --  isinme: son uc movzuda
    if i >= 7 then
      v_test := app.demo_test(p_owner, v_riy, v_lm.id, v_lm.program_id, array[v_par.o_id], 5,
                  'İsinmə — ' || v_par.o_name, jsonb_build_object('pack','warm','topics',jsonb_build_array(v_par.o_id::text)),
                  '{1,2}', null, false, v_at - interval '1 day');
      update public.class_plan_items set warm_test_id = v_test where id = v_item;
      insert into public.assignments (class_id, test_id, assigned_by, opens_at, closes_at, max_attempts, created_at)
      values (v_c1, v_test, p_owner, v_at - interval '1 day', v_at, 1, v_at - interval '1 day');
      for k in 1..12 loop
        if random() < 0.7 then
          perform app.demo_attempt(v_stu1[k], v_test, v_c1, v_abil1[k] + 0.1, case when k in (1, 7, 10, 11, 12) then v_weak else v_weak[1:1] end, v_at - make_interval(hours => 2 + floor(random() * 14)::int));
        end if;
      end loop;
    end if;
    --  rub sinagi: 6-ci movzudan sonra
    if i = 6 then
      select array_agg(distinct tp.o_id) into v_topics
        from unnest(v_items[1:6]) x join public.class_plan_items it on it.id = x
        cross join lateral app.pack_topic(it.topic_id) tp;
      v_exam := app.demo_test(p_owner, v_riy, v_lm.id, v_lm.program_id, v_topics, 20,
                  'Rüb sınağı — Riyaziyyat · 6 mövzu', jsonb_build_object('pack','exam','plan',v_plan::text,'topics',to_jsonb(v_topics)),
                  '{1,2,3}', null, false, v_at + interval '1 day');
      insert into public.plan_exams (plan_id, test_id, item_ids, created_at) values (v_plan, v_exam, v_items[1:6], v_at + interval '1 day');
      insert into public.assignments (class_id, test_id, assigned_by, opens_at, closes_at, max_attempts, created_at)
      values (v_c1, v_exam, p_owner, v_at + interval '1 day', v_at + interval '8 days', 1, v_at + interval '1 day');
      for k in 1..12 loop
        if k <> 6 and k <> 11 then
          perform app.demo_attempt(v_stu1[k], v_exam, v_c1, v_abil1[k], case when k in (1, 7, 10, 11, 12) then v_weak else v_weak[1:1] end, v_at + make_interval(days => 2, hours => floor(random() * 96)::int));
        end if;
      end loop;
    end if;
  end loop;

  -- ---- diaqnostika (35 gun evvel): her kok movzudan 3 sual
  select array_agg(t.id) into v_topics from public.topics t
   where t.subject_id = v_riy and t.level_id = v_lm.id and t.parent_id is null;
  v_at := now() - interval '35 days';
  v_diag := app.demo_test(p_owner, v_riy, v_lm.id, v_lm.program_id, v_topics, 3 * cardinality(v_topics),
              'Diaqnostika · Riyaziyyat · ' || v_lm.name,
              jsonb_build_object('kind','diagnostic','subject','riyaziyyat','level',v_lm.code,'per_topic',3),
              '{1,2,3}', 3, true, v_at);
  insert into public.assignments (class_id, test_id, assigned_by, opens_at, closes_at, max_attempts, created_at)
  values (v_c1, v_diag, p_owner, v_at, v_at + interval '7 days', 1, v_at);
  --  diaqnostika dersden EVVELdir: bacariq 0.12 asagi, Kesrler hamiya zeif
  --  (qrup hesabatinda "axsayan movzu" gorunsun)
  for k in 1..12 loop
    perform app.demo_attempt(v_stu1[k], v_diag, v_c1, v_abil1[k] - 0.12, v_weak, v_at + make_interval(hours => 10 + floor(random() * 100)::int));
  end loop;

  -- ---- movzu mesqi: uc sagird
  for k in 1..3 loop
    insert into public.practice (student_id, topic_id, score, streak, answered, correct, mastered_at, started_at, updated_at)
    select v_stu1[k], t.id, 100, 4, 9, 8, now() - interval '6 days', now() - interval '9 days', now() - interval '6 days'
      from public.topics t where t.id = v_topics[1];
    insert into public.practice (student_id, topic_id, score, streak, answered, correct, started_at, updated_at)
    select v_stu1[k], t.id, 40 + 12 * k, 1, 7, 5, now() - interval '2 days', now() - make_interval(hours => 5 * k)
      from public.topics t where t.id = v_weak[1];
  end loop;

  -- ---- davamiyyet: son 6 senbe; odenis: bu ay 8 odenib, kecen ay hamisi
  for k in 0..6 loop
    v_d := (date_trunc('week', current_date)::date + 5) - k * 7;   -- senbe
    if v_d > current_date then continue; end if;
    insert into public.lessons (class_id, held_on, created_by) values (v_c1, v_d, p_owner) returning id into v_les;
    insert into public.attendance (lesson_id, student_id, present)
    select v_les, s, random() > 0.12 from unnest(v_stu1) s;
  end loop;
  insert into public.fee_payments (student_id, month, paid, paid_at, updated_by)
  select v_stu1[g.n], v_month, g.n <= 8, case when g.n <= 8 then now() - make_interval(days => 2 + g.n) end, p_owner
    from generate_series(1, 12) as g(n);
  insert into public.fee_payments (student_id, month, paid, paid_at, updated_by)
  select v_stu1[g.n], (v_month - interval '1 month')::date, true, v_month - make_interval(days => 20 - g.n), p_owner
    from generate_series(1, 12) as g(n);

  -- ---- bize yaz + sual bildirisi
  insert into public.feedback (author_type, user_id, account_id, kind, page, body, created_at)
  values ('teacher', p_owner, p_account, 'teklif', 'hesabat',
          'Qrup hesabatında zəif mövzuların yanında «təkrar dərs» üçün hazır test düyməsi çox yaxşı olardı.',
          now() - interval '4 days');
  select tq.question_id into v_q from public.test_questions tq
   where tq.test_id = (select test_id from public.class_plan_items where id = v_items[2]) order by tq.ord limit 1;
  if v_q is not null then
    insert into public.question_reports (question_id, student_id, reason, note, created_at)
    values (v_q, v_stu1[4], 'yazi', 'Sualda «neçə edər» sözü iki dəfə yazılıb.', now() - interval '2 days');
  end if;

  -- ---- qrup 2: 3-cu sinif, 8 sagird, plan 2 movzu
  insert into public.classes (account_id, teacher_id, kind, program_id, level_id, name, join_code)
  values (p_account, p_owner, 'tutor_group', v_l3.program_id, v_l3.id, '3-cü sinif — ibtidai', app.gen_login_code(8))
  returning id into v_c2;
  for i in 1..8 loop
    v_code := case when p_fixed then 'DEMO' || lpad((12 + i)::text, 4, '0') else app.gen_login_code(8) end;
    insert into public.students (account_id, class_id, created_by, full_name, display_name, login_code, created_at)
    values (p_account, v_c2, p_owner, v_names2[i], app.unique_display_name(v_c2, v_names2[i]), v_code,
            now() - interval '30 days' + make_interval(mins => i))
    returning id into v_sid;
    v_stu2 := v_stu2 || v_sid;
  end loop;
  insert into public.class_plans (class_id, subject_id, level_id, created_at)
  values (v_c2, v_riy, v_l3.id, now() - interval '28 days') returning id into v_plan2;
  insert into public.class_plan_items (plan_id, topic_id, ord)
  select v_plan2, t.id, row_number() over (order by coalesce(par.sort, t.sort), coalesce(par.name, t.name), t.sort, t.name)
    from public.topics t left join public.topics par on par.id = t.parent_id
   where t.subject_id = v_riy and t.level_id = v_l3.id
     and not exists (select 1 from public.topics c where c.parent_id = t.id);
  select array_agg(id order by ord) into v_items from public.class_plan_items where plan_id = v_plan2;
  if cardinality(v_items) >= 2 then
    update public.class_plan_items set done_at = now() - interval '20 days' where id = v_items[1];
    update public.class_plan_items set done_at = now() - interval '12 days' where id = v_items[2];
    --  183: birinci movzunun testini HAMI edib.  Evvel yalniz bir test
    --  var idi ve 5-ci ile 8-ci sagird hec ne etmemis qalirdi - numunede
    --  bos hesabat acilirdi.  "Kim etmeyib" yene isleyir: o iki nefer
    --  ASAGIDAKI (son) tapsirigi etmeyib.
    select * into v_par from app.pack_topic((select topic_id from public.class_plan_items where id = v_items[1]));
    select t.name into v_tname from public.topics t
     where t.id = (select topic_id from public.class_plan_items where id = v_items[1]);
    v_at := now() - interval '20 days';
    v_test := app.demo_test(p_owner, v_riy, v_l3.id, v_l3.program_id, array[v_par.o_id], 10,
                v_tname || ' — yoxlama', jsonb_build_object('pack','hw','topics',jsonb_build_array(v_par.o_id::text)),
                '{1,2,3}', null, false, v_at);
    update public.class_plan_items set test_id = v_test where id = v_items[1];
    insert into public.assignments (class_id, test_id, assigned_by, opens_at, closes_at, max_attempts, created_at)
    values (v_c2, v_test, p_owner, v_at, v_at + interval '7 days', 1, v_at);
    for k in 1..8 loop
      perform app.demo_attempt(v_stu2[k], v_test, v_c2, v_abil2[k], '{}', v_at + make_interval(hours => 20 + floor(random() * 96)::int));
    end loop;
    select * into v_par from app.pack_topic((select topic_id from public.class_plan_items where id = v_items[2]));
    v_at := now() - interval '12 days';
    v_test := app.demo_test(p_owner, v_riy, v_l3.id, v_l3.program_id, array[v_par.o_id], 10,
                v_par.o_name || ' — yoxlama', jsonb_build_object('pack','hw','topics',jsonb_build_array(v_par.o_id::text)),
                '{1,2,3}', null, false, v_at);
    update public.class_plan_items set test_id = v_test where id = v_items[2];
    insert into public.assignments (class_id, test_id, assigned_by, opens_at, closes_at, max_attempts, created_at)
    values (v_c2, v_test, p_owner, v_at, v_at + interval '7 days', 1, v_at);
    for k in 1..8 loop
      if k <> 5 and k <> 8 then
        perform app.demo_attempt(v_stu2[k], v_test, v_c2, v_abil2[k], '{}', v_at + make_interval(hours => 20 + floor(random() * 96)::int));
      end if;
    end loop;
  end if;

  -- ---- qrup 3: 11-ci sinif DIM hazirliq, 5 sagird, 1 movzu kecilib
  insert into public.classes (account_id, teacher_id, kind, program_id, level_id, name, join_code)
  values (p_account, p_owner, 'tutor_group', v_l11.program_id, v_l11.id, '11-ci sinif — DİM hazırlıq', app.gen_login_code(8))
  returning id into v_c3;
  for i in 1..5 loop
    v_code := case when p_fixed then 'DEMO' || lpad((20 + i)::text, 4, '0') else app.gen_login_code(8) end;
    insert into public.students (account_id, class_id, created_by, full_name, display_name, login_code, created_at)
    values (p_account, v_c3, p_owner, v_names3[i], app.unique_display_name(v_c3, v_names3[i]), v_code,
            now() - interval '20 days' + make_interval(mins => i))
    returning id into v_sid;
    v_stu3 := v_stu3 || v_sid;
  end loop;
  insert into public.class_plans (class_id, subject_id, level_id, created_at)
  values (v_c3, v_riy, v_l11.id, now() - interval '18 days') returning id into v_plan3;
  insert into public.class_plan_items (plan_id, topic_id, ord)
  select v_plan3, t.id, row_number() over (order by coalesce(par.sort, t.sort), coalesce(par.name, t.name), t.sort, t.name)
    from public.topics t left join public.topics par on par.id = t.parent_id
   where t.subject_id = v_riy and t.level_id = v_l11.id
     and not exists (select 1 from public.topics c where c.parent_id = t.id);
  select array_agg(id order by ord) into v_items from public.class_plan_items where plan_id = v_plan3;
  --  183: evvel BIR movzu, BIR test var idi ve 4-cu sagird onu da
  --  etmemisdi - numunede o sagirdin butun tablari bos acilirdi.
  --  Indi uc movzu kecilib, ucu de testli; 4-cu sagird yalniz SON
  --  tapsirigi etmeyib ("kim etmeyib" gorunsun deye).
  --  Basliqda YARPAG movzunun adi islenir: pack_topic FESIL adini
  --  qaytarir, uc test eyni adla cixirdi.
  if cardinality(v_items) >= 1 then
   for i in 1..least(3, cardinality(v_items)) loop
    v_at := now() - make_interval(days => 9 + (3 - i) * 7);
    update public.class_plan_items set done_at = v_at where id = v_items[i];
    select * into v_par from app.pack_topic((select topic_id from public.class_plan_items where id = v_items[i]));
    select t.name into v_tname from public.topics t
     where t.id = (select topic_id from public.class_plan_items where id = v_items[i]);
    v_test := app.demo_test(p_owner, v_riy, v_l11.id, v_l11.program_id, array[v_par.o_id], 10,
                v_tname || ' — yoxlama', jsonb_build_object('pack','hw','topics',jsonb_build_array(v_par.o_id::text)),
                '{1,2,3}', null, false, v_at);
    update public.class_plan_items set test_id = v_test where id = v_items[i];
    insert into public.assignments (class_id, test_id, assigned_by, opens_at, closes_at, max_attempts, created_at)
    values (v_c3, v_test, p_owner, v_at, v_at + interval '7 days', 1, v_at);
    for k in 1..5 loop
      if i = least(3, cardinality(v_items)) and k = 4 then continue; end if;
      perform app.demo_attempt(v_stu3[k], v_test, v_c3, v_abil3[k], '{}', v_at + make_interval(hours => 20 + floor(random() * 96)::int));
    end loop;
   end loop;
  end if;

  -- ---- 183: valideyn kodu HER sagirde.  182-den sonra yeni qrupda
  --  kodlar ozu yaranir; numunede yalniz bir sagirdde var idi ve
  --  gosterisde valideyn hissesi gorunmurdu.  Birinci sagirdin kodu
  --  (VDEMO001) toxunulmur - ana sehifedeki "Valideyn kimi bax" ona
  --  baglidir.
  --  Bir statement icinde tekrar yoxlamasi isini gormezdi (hele
  --  yazilmamis setirler gorunmur), ona gore bir-bir verilir -
  --  students_parent_code_key unikal indeksdir.
  for v_sid in select s.id from public.students s
                where s.account_id = p_account and s.parent_code is null
  loop
    update public.students set parent_code = app.parent_code_new() where id = v_sid;
  end loop;

  -- ---- 183: qrup 2 ve 3 ucun de davamiyyet, odenis defteri ve cedvel.
  --  Evvel yalniz 1-ci qrupda var idi - o biri iki qrupun «Davamiyyət»
  --  ve «Ödəniş» tablari numunede bos acilirdi.
  for k in 0..3 loop
    v_d := (date_trunc('week', current_date)::date + 4) - k * 7;    -- cume
    if v_d <= current_date then
      insert into public.lessons (class_id, held_on, created_by) values (v_c2, v_d, p_owner) returning id into v_les;
      insert into public.attendance (lesson_id, student_id, present)
      select v_les, s, random() > 0.1 from unnest(v_stu2) s;
    end if;
    v_d := (date_trunc('week', current_date)::date + 3) - k * 7;    -- cume axsami
    if v_d <= current_date then
      insert into public.lessons (class_id, held_on, created_by) values (v_c3, v_d, p_owner) returning id into v_les;
      insert into public.attendance (lesson_id, student_id, present)
      select v_les, s, random() > 0.1 from unnest(v_stu3) s;
    end if;
  end loop;
  insert into public.fee_payments (student_id, month, paid, paid_at, updated_by)
  select v_stu2[g.n], v_month, g.n <= 6, case when g.n <= 6 then now() - make_interval(days => 3 + g.n) end, p_owner
    from generate_series(1, 8) as g(n);
  insert into public.fee_payments (student_id, month, paid, paid_at, updated_by)
  select v_stu2[g.n], (v_month - interval '1 month')::date, true, v_month - make_interval(days => 18 - g.n), p_owner
    from generate_series(1, 8) as g(n);
  insert into public.fee_payments (student_id, month, paid, paid_at, updated_by)
  select v_stu3[g.n], v_month, g.n <= 4, case when g.n <= 4 then now() - make_interval(days => 4 + g.n) end, p_owner
    from generate_series(1, 5) as g(n);
  insert into public.fee_payments (student_id, month, paid, paid_at, updated_by)
  select v_stu3[g.n], (v_month - interval '1 month')::date, true, v_month - make_interval(days => 16 - g.n), p_owner
    from generate_series(1, 5) as g(n);

  --  Hefte cedveli (177).  Cedvel yoxdursa Icmalda «Bu gün dərs var»
  --  ve «Bütün həftə» kartlari hec vaxt gorunmurdu.  Ucuncu qrupa
  --  bugunku hefte gunu de elave olunur ki, numune hemise "canli" olsun.
  if to_regclass('public.class_schedule') is not null then
    delete from public.class_schedule cs using public.classes c
     where cs.class_id = c.id and c.account_id = p_account;
    insert into public.class_schedule (class_id, weekday, starts_at, mins) values
      (v_c1, 6, '11:00', 90),
      (v_c2, 2, '18:00', 60), (v_c2, 5, '18:00', 60),
      (v_c3, 1, '16:00', 90), (v_c3, 4, '16:00', 90)
    on conflict do nothing;
    insert into public.class_schedule (class_id, weekday, starts_at, mins)
    values (v_c3, extract(isodow from (now() at time zone 'Asia/Baku'))::int, '16:00', 90)
    on conflict do nothing;
  end if;

  --  191: numune ev tapsiriqlari - Tapsiriqlar ekrani bos gorunmesin
  perform app.demo_homework(p_owner, p_account);

  return jsonb_build_object('ok', true, 'account_id', p_account, 'student_code', v_code1, 'parent_code', v_pcode1,
                            'classes', 3, 'students', 25);
end $function$;
revoke all on function app.demo_build(uuid, uuid, boolean) from public, anon, authenticated;
