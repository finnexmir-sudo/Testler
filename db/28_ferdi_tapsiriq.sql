-- =====================================================================
--  28_ferdi_tapsiriq.sql : TAPSIRIQ TEK SAGIRDE DE VERILIR
--
--  Problem:  assignments-de yalniz class_id var idi - teyinat HEMISE
--  butun qrupa gedirdi.  Ona gore "sehvler uzerinde is" testi (bir
--  sagirdin OZ sehvlerinden yigilir) qrupdaki HAMIYA gorunurdu,
--  ustelik adinda hemin sagirdin adi ile.  Hem menasiz, hem xosagelmez.
--
--  Hell:  assignments.student_id (bos = butun qrup).  Kohne setirlerde
--  bos qalir - davranis deyismir.
--
--  ESAS:    rpc_assign_test-in mexeyi 09_assignments.sql-dir
--           (10_teyinat_migrasiya.sql run.sh-de YOXDUR - o, yalniz
--           kohne bazalar ucun miqrasiyadir; oradan kopyalama).
--  ON SERT: 27_hesabat.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if to_regproc('public.rpc_remedial_test') is null then
    raise exception 'ONCE 27_hesabat.sql isledilmelidir.';
  end if;
end $$;

-- ---------------------------------------------------------------- sxem
alter table public.assignments
  add column if not exists student_id uuid
      references public.students(id) on delete cascade;

comment on column public.assignments.student_id is
  'Bos = butun qrup.  Dolu = yalniz hemin sagird gorur.';

--  Unikallik: eyni test bir qrupa bir defe, HER sagirde bir defe.
--  "nulls not distinct" olmasa iki qrup-teyinati da kecerdi.
alter table public.assignments
  drop constraint if exists assignments_class_id_test_id_key;
alter table public.assignments
  drop constraint if exists assignments_class_test_student_key;
alter table public.assignments
  add  constraint assignments_class_test_student_key
       unique nulls not distinct (class_id, test_id, student_id);

--  Sagird ekrani her acilanda bu sutunlarla suzur
create index if not exists idx_assign_class_student
  on public.assignments(class_id, student_id);

-- ---------------------------------------------------------------- teyin et
--  DIQQET: yeni parametr elave olundugu ucun kohne 4-arqumentli
--  funksiya SILINIR.  "create or replace" ile qalsa, PostgREST iki
--  namized arasinda secim ede bilmir ve sorgu 300 xetasi verir.
drop function if exists public.rpc_assign_test(uuid, uuid, timestamptz, int);

create or replace function public.rpc_assign_test(
  p_class_id uuid, p_test_id uuid,
  p_closes_at timestamptz default null,
  p_max_attempts int default 1,
  p_student_id uuid default null)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid   uuid := auth.uid();
  v_class public.classes%rowtype;
  v_test  public.tests%rowtype;
  v_stu   public.students%rowtype;
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

  --  Odenisli test abunesiz teyin olunsa DALAN yaranir: muellim teyin
  --  edir, sagird acanda "abune lazimdir" gorur ve ise dusmur.
  --  Ona gore teyin anindaca dayandiririq.  (09_assignments.sql-den)
  if not v_test.is_free and not app.has_active_subscription(v_class.account_id) then
    raise exception 'Bu test abune paketine daxildir. Sagird onu aca bilmeyecek - once paketi genislendirin.'
      using errcode = '42501';
  end if;

  --  Ferdi teyinat: sagird HEMIN qrupun aktiv sagirdi olmalidir.
  --  (Yoxsa basqa hesabin sagirdine tapsiriq yazmaq olardi.)
  if p_student_id is not null then
    select * into v_stu from public.students
     where id = p_student_id and class_id = p_class_id and is_active;
    if not found then
      raise exception 'Sagird bu qrupda tapilmadi.' using errcode = '22023';
    end if;
  end if;

  insert into public.assignments
    (class_id, test_id, student_id, assigned_by, closes_at, max_attempts)
  values (p_class_id, p_test_id, p_student_id, v_uid, p_closes_at, p_max_attempts)
  on conflict (class_id, test_id, student_id) do update
    set closes_at = excluded.closes_at,
        max_attempts = excluded.max_attempts,
        opens_at = now(),
        assigned_by = excluded.assigned_by
  returning id into v_id;

  return jsonb_build_object('id', v_id, 'test', v_test.title,
                            'student', v_stu.display_name);
end $$;

-- ---------------------------------------------------------------- sagird
--  Yegane deyisiklik: ferdi teyinat yalniz sahibine gorunur.
--  Qalani 11_sual_banki.sql-dekinin eynidir (10-dakina YOX - orada
--  questions.test_id vardi, indi test_questions ile baglanir).
--  DIQQET: funksiya STABLE OLMAMALIDIR - rpc_student_login yeni
--  sessiya yazir, stable variant onu hemin sorguda gormur.
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
                 --  yalniz mene verilibse sagird de bilsin
                 'personal',       a.student_id is not null,
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
           --  BU SETIR YENIDIR: ferdi teyinat basqasina gorunmur
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
      ) z), '[]'::jsonb) end
  );
end $$;

-- ---------------------------------------------------------------- muellim
--  Tapsiriq siyahisi: kime verildiyi de gorunur.
--  "done/students" ferdi teyinatda 1 nefere gore hesablanir.
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
                 --  kime verilib: bos = butun qrup
                 'student_id',   a.student_id,
                 'student',      st.display_name,
                 --  ferdi teyinatda mexrec 1-dir, qrupda butun sagirdler
                 'targets',   case when a.student_id is null then v_total else 1 end,
                 'done',      (select count(distinct at.student_id)
                                 from public.attempts at
                                 join public.students s on s.id = at.student_id
                                where at.test_id = t.id and s.class_id = p_class_id
                                  and at.status = 'submitted'
                                  and (a.student_id is null
                                       or at.student_id = a.student_id)),
                 'avg',       (select round(avg(best), 0) from (
                                 select max(at.percent) best
                                   from public.attempts at
                                   join public.students s on s.id = at.student_id
                                  where at.test_id = t.id and s.class_id = p_class_id
                                    and at.status = 'submitted'
                                    and (a.student_id is null
                                         or at.student_id = a.student_id)
                                  group by at.student_id) b)
               ) as x
          from public.assignments a
          join public.tests t on t.id = a.test_id
          join public.subjects sub on sub.id = t.subject_id
          left join public.students st on st.id = a.student_id
         where a.class_id = p_class_id
      ) z), '[]'::jsonb)
  );
end $$;

-- ---------------------------------------------------------------- secim
--  "assigned" indi YALNIZ qrup teyinatini bildirir - ferdi teyinat
--  testi siyahidan cixarmir (basqa sagirde de vermek olar).
--  "assigned_n" nece nefere ferdi verildiyini gosterir.
--  Alt sorgu tek setir qaytarmalidir: student_id is null sertisiz
--  eyni test iki sagirde verilende "more than one row" xetasi olardi.
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
                              where a.class_id = p_class_id and a.test_id = t.id
                                and a.student_id is null),
               'assigned_n',(select count(*) from public.assignments a
                              where a.class_id = p_class_id and a.test_id = t.id
                                and a.student_id is not null)
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

-- ---------------------------------------------------------------- duzelis testi
--  ESAS DUZELIS: sehvler uzerinde is testi artiq YALNIZ hemin
--  sagirde verilir.  Evvel butun qrup gorurdu - ustelik adinda
--  sagirdin adi ile.  Qalani 27_hesabat.sql-dekiler ile eynidir.
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

  --  YEGANE DEYISIKLIK (27-ye nisbeten): teyinat YALNIZ bu sagirde
  --  gedir - evvel butun qrup gorurdu, ustelik adinda sagirdin adi ile.
  perform public.rpc_assign_test(
    v_st.class_id, v_test, now() + interval '7 days', 1, p_student_id);

  return jsonb_build_object('ok', true, 'test_id', v_test, 'count', v_n);
end $$;

-- ---------------------------------------------------------------- huquq
revoke all on function public.rpc_assign_test(uuid, uuid, timestamptz, int, uuid)
  from public, anon;
revoke all on function public.rpc_available_tests(uuid)     from public, anon;
revoke all on function public.rpc_class_assignments(uuid)   from public, anon;
revoke all on function public.rpc_remedial_test(uuid, int)  from public, anon;
revoke all on function public.rpc_student_tests(text)       from public;

grant execute on function public.rpc_assign_test(uuid, uuid, timestamptz, int, uuid)
  to authenticated;
grant execute on function public.rpc_available_tests(uuid)    to authenticated;
grant execute on function public.rpc_class_assignments(uuid)  to authenticated;
grant execute on function public.rpc_remedial_test(uuid, int) to authenticated;
--  sagird tetbiqi tokenle isleyir - anon qalir
grant execute on function public.rpc_student_tests(text)      to anon, authenticated;

do $$
begin
  if has_function_privilege('anon',
      'public.rpc_assign_test(uuid, uuid, timestamptz, int, uuid)', 'EXECUTE') then
    raise exception 'anon tapsiriq teyin ede bilir';
  end if;
  if not has_function_privilege('anon', 'public.rpc_student_tests(text)', 'EXECUTE') then
    raise exception 'sagird oz testlerini gore bilmir';
  end if;
  raise notice 'Ferdi tapsiriq quruldu: assignments.student_id (bos = butun qrup).';
end $$;
