-- =====================================================================
--  107_valideyn.sql — valideyn girisi
--
--  NIYE
--  Repetitor onsuz da gece-gunduz valideynle danisir: "bu belə oldu,
--  bunu kecdim, burda zeifdir".  Biz nezaret qurmuruq - onun ARTIQ
--  gorduyu isi avtomatlasdiririq.  Valideyn oz usagini izleyir:
--  hansi ders kecildi, ne tapsiriq verildi, nece oxuyur.
--
--  MUELLIM OZU ACIR - SUSMAYA GORE BAGLI
--  parent_code NULL-dursa valideyn girisi YOXDUR.  Bezi muellimler
--  isinin seffaflasmasindan narahat olacaq; mecburi etsek muellimi
--  itiririk.  Acan muellim ise bunu OZ ustunluyu kimi isledir.
--
--  NIYE AYRI SESSIYA CEDVELI
--  Valideyn tokeni HEC VAXT sagird RPC-lerinde islememelidir - eks
--  halda valideyn kodu sagird koduna cevrilir ve usagin adindan test
--  yazila biler.  student_sessions-a "rol" sutunu elave etmek bu
--  sehvi bir gun mutleq yaradardi; ona gore AYRI cedvel.
--
--  VALIDEYN NE GORMUR (dizaynin yarisi budur)
--    - basqa usaqlarin adlari ve ballari (reytinq yoxdur)
--    - usagin OZ giris kodu (yoxsa onun adindan testə girmek olar)
--    - duz cavablar (is_correct hec bir yerde qaytarilmir)
--    - qrupla muqayise (valideyn hem usaga tezyiq eder, hem de
--      qrupun veziyyetini oyrener)
--    - muellimin elaqe melumati (adi kifayetdir)
-- =====================================================================

-- ------------------------------------------------------------ sutun
alter table public.students
  add column if not exists parent_code text;

create unique index if not exists students_parent_code_key
  on public.students (parent_code) where parent_code is not null;

comment on column public.students.parent_code is
  'Valideyn giris kodu.  NULL = valideyn girisi bagli (susma hali).';

-- ------------------------------------------------------- sessiyalar
--  Sagird sessiyasi 12 saatdir.  Valideyn ucun bu, her gun yeniden
--  kod yazmaq demekdir - bezdiricidir.  30 gun secilib.
create table if not exists public.parent_sessions (
  token_hash text primary key,
  student_id uuid not null references public.students(id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null
);

create index if not exists idx_parent_sessions_student
  on public.parent_sessions(student_id);
create index if not exists idx_parent_sessions_expiry
  on public.parent_sessions(expires_at);

alter table public.parent_sessions enable row level security;
--  Siyaset yoxdur - yalniz definer RPC-ler toxunur.

-- --------------------------------------------------- sessiya -> usaq
create or replace function app.session_parent(p_token text) returns uuid
language sql stable security definer
set search_path = public, extensions, pg_temp as $$
  select ps.student_id
    from public.parent_sessions ps
    join public.students s on s.id = ps.student_id and s.is_active
   where ps.token_hash = app.hash_token(p_token)
     and ps.expires_at > now()
$$;

-- ============================================================ MUELLIM
--  Valideyn girisini acir / baglayir.  Acanda kod qaytarir ki, muellim
--  onu valideyne versin.  Baglayanda ACIQ sessiyalar da derhal olur -
--  "bagladim, amma hele de baxir" olmasin.
create or replace function public.rpc_parent_access(
  p_student_id uuid, p_on boolean default true)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare v_code text; i int;
begin
  if not app.can_read_student(p_student_id) then
    raise exception 'Bu sagirde giris huququnuz yoxdur.' using errcode = '42501';
  end if;

  if not coalesce(p_on, true) then
    update public.students set parent_code = null where id = p_student_id;
    delete from public.parent_sessions where student_id = p_student_id;
    return jsonb_build_object('id', p_student_id, 'parent_code', null);
  end if;

  --  Kod ARTIQ varsa yenisini yaratmiriq - muellim duymeye ikinci defe
  --  basanda valideynin kodu qirilmasin.
  select parent_code into v_code from public.students where id = p_student_id;
  if v_code is not null then
    return jsonb_build_object('id', p_student_id, 'parent_code', v_code);
  end if;

  for i in 1..20 loop
    v_code := 'V' || app.gen_login_code(7);
    exit when not exists (select 1 from public.students where parent_code = v_code);
    v_code := null;
  end loop;
  if v_code is null then
    raise exception 'Kod yaradila bilmedi.';
  end if;

  update public.students set parent_code = v_code where id = p_student_id;
  return jsonb_build_object('id', p_student_id, 'parent_code', v_code);
end $$;

--  Kodu deyismek: kod yayilibsa muellim onu bir kliklə evez edir.
create or replace function public.rpc_parent_code_reset(p_student_id uuid)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
begin
  if not app.can_read_student(p_student_id) then
    raise exception 'Bu sagirde giris huququnuz yoxdur.' using errcode = '42501';
  end if;
  update public.students set parent_code = null where id = p_student_id;
  delete from public.parent_sessions where student_id = p_student_id;
  return public.rpc_parent_access(p_student_id, true);
end $$;

-- =========================================================== VALIDEYN
create or replace function public.rpc_parent_login(p_code text)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_st    public.students%rowtype;
  v_class public.classes%rowtype;
  v_token text;
begin
  if p_code is null or length(btrim(p_code)) < 6 then
    return jsonb_build_object('ok', false, 'error', 'Kod qisadir.');
  end if;

  select * into v_st from public.students
   where parent_code = upper(btrim(p_code)) and is_active;
  if not found then
    return jsonb_build_object('ok', false, 'error', 'Bele kod tapilmadi.');
  end if;

  select * into v_class from public.classes where id = v_st.class_id;

  v_token := encode(gen_random_bytes(32), 'hex');
  insert into public.parent_sessions (token_hash, student_id, expires_at)
  values (app.hash_token(v_token), v_st.id, now() + interval '30 days');

  --  DIQQET: login_code BURADA YOXDUR ve olmamalidir.
  return jsonb_build_object(
    'ok',    true,
    'token', v_token,
    'child', jsonb_build_object('name', v_st.display_name),
    'class', case when v_class.id is null then null
                  else jsonb_build_object('name', v_class.name) end);
end $$;

create or replace function public.rpc_parent_logout(p_token text)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
begin
  delete from public.parent_sessions where token_hash = app.hash_token(p_token);
  return jsonb_build_object('ok', true);
end $$;

-- ---------------------------------------------------- valideyn ekrani
--  BIR sorgu ile butun ekran.  Valideyn telefonda 40 saniye baxir -
--  ekranlar arasi gezmek ucun gelmir.
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
                                  where tq.test_id = t.id)) as x
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
                   'percent', round(a.percent, 0)) as x
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
revoke all on function app.session_parent(text) from public, anon, authenticated;

revoke all on function public.rpc_parent_access(uuid, boolean) from public, anon;
revoke all on function public.rpc_parent_code_reset(uuid)      from public, anon;
grant execute on function public.rpc_parent_access(uuid, boolean) to authenticated;
grant execute on function public.rpc_parent_code_reset(uuid)      to authenticated;

--  Valideyn tetbiqi anon-la isleyir - eynen sagird kimi
revoke all on function public.rpc_parent_login(text)  from public;
revoke all on function public.rpc_parent_home(text)   from public;
revoke all on function public.rpc_parent_logout(text) from public;
grant execute on function public.rpc_parent_login(text)  to anon, authenticated;
grant execute on function public.rpc_parent_home(text)   to anon, authenticated;
grant execute on function public.rpc_parent_logout(text) to anon, authenticated;

-- --------------------------------------------------------------- yoxlama
do $$
declare v_def text;
begin
  if has_function_privilege('anon',
      'public.rpc_parent_access(uuid, boolean)', 'EXECUTE') then
    raise exception 'anon valideyn girisini aca bilir';
  end if;
  --  Valideyn ekranı duz cavab qaytarmamalidir
  select pg_get_functiondef(p.oid) into v_def from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'rpc_parent_home';
  if v_def like '%login_code%' then
    raise exception 'valideyn ekrani usagin giris kodunu qaytarir';
  end if;
  raise notice 'Valideyn girisi quruldu: kod susmaya gore BAGLI, sessiya 30 gun.';
end $$;
