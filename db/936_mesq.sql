-- =====================================================================
--  936 : MESQ — TEST KITABINI EVEZ EDEN DERS MESQI (2026-11-19, pilot riy 5)
--
--  Istifadeci: muellim «test kitabindan 45-47-ci sehifeleri isleyin» deyir.
--  Sayt bunu evez etsin: derse aid OXSAR, ASANDAN CETINE duzulmus mesq
--  suallari; muellim «Məşq ver» deyir, sagird sual-sual isleyir, cavabdan
--  derhal sonra duz/sehv + izah gorur, muellim kimin ne etdiyini gorur.
--
--  ON SERT: 935 (content_status 'mesq').  Bank fayli 1470 (suallar) BU
--  fayldan sonra isledilir.  Suallarin nisani: status = 'mesq',
--  tags @> {'ders:<yarpaq slug>', 'mesq'}, ext_key 'riy5mesq-<ders>#NNN'.
--
--  TEST MEXANIZMINE QARISMIR: suallar 'published' deyil - test, generator,
--  bank siyahisi, adaptiv mesq (133), sehv defteri onlari gormur; cavablar
--  attempts / attempt_answers-e YAZILMIR (ortalama, zeif movzu, siqnallar
--  deyismir).  Oz cedvelleri: mesq_assignments, mesq_answers.
--
--  SIRA: tapsiriq verilende dersin suallari (difficulty, ext_key) sirasi ile
--  qids-e DONDURULUR - sonra banka sual elave olunsa, verilmis mesq deyismir.
--  Sablon sual (132): her sagirde teze reqem (pq_seed), reqem cavab verilene
--  qeder saxlanir - sehife yenilenende eyni sual eyni reqemle qayidir.
--
--  BAL SERVERDE (ƏN VACİB QAYDA 1): duz variant sagirde getmir; cavab yalniz
--  duz/sehv + izah qaytarir.
--
--  Supabase: temp cedvel yoxdur, begin/commit yoxdur (rehber, 2026-11-11).
-- =====================================================================

create table if not exists public.mesq_assignments (
  id          uuid primary key default gen_random_uuid(),
  class_id    uuid not null references public.classes(id) on delete cascade,
  student_id  uuid references public.students(id) on delete cascade,   -- NULL = butun qrup
  topic_id    uuid not null references public.topics(id) on delete cascade,   -- ders (yarpaq)
  qids        uuid[] not null,                                          -- verilen anin sirasi
  created_by  uuid not null references auth.users(id) on delete cascade,
  due         date,
  created_at  timestamptz not null default now()
);
create index if not exists mesq_asg_class_idx on public.mesq_assignments (class_id, created_at desc);
alter table public.mesq_assignments enable row level security;
revoke all on public.mesq_assignments from public, anon, authenticated;

create table if not exists public.mesq_answers (
  assignment_id uuid not null references public.mesq_assignments(id) on delete cascade,
  student_id    uuid not null references public.students(id) on delete cascade,
  question_id   uuid not null references public.questions(id) on delete cascade,
  params        jsonb,                      --  sablon sualin bu sagirde dusen reqemleri
  shown_at      timestamptz not null default now(),
  is_correct    boolean,                    --  NULL = gosterilib, hele cavablanmayib
  chosen        text,                       --  sagirdin cavabi (metn) - muellim hesabati ucun
  answered_at   timestamptz,
  primary key (assignment_id, student_id, question_id)
);
create index if not exists mesq_ans_student_idx on public.mesq_answers (student_id, assignment_id);
alter table public.mesq_answers enable row level security;
revoke all on public.mesq_answers from public, anon, authenticated;

--  bagli hesab (905): yeni mesq de verilmir
drop trigger if exists hesab_bagli on public.mesq_assignments;
create trigger hesab_bagli before insert on public.mesq_assignments
  for each row execute function app.trg_hesab_bagli();

-- ---------------------------------------------------------------------
--  Dersin mesq hovuzu - asandan cetine.  status::text: enum literalina
--  baglanmir (935 hele islenmeyibse funksiya yene yaranir, bos qaytarir).
-- ---------------------------------------------------------------------
create or replace function app.mesq_pool(p_leaf uuid)
returns table (id uuid, difficulty smallint, ext_key text)
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select q.id, q.difficulty, q.ext_key
    from public.questions q
   where q.status::text = 'mesq'
     and q.tags @> array['ders:' || (select t.slug from public.topics t where t.id = p_leaf)]
   order by q.difficulty, q.ext_key nulls last, q.id
$$;
revoke all on function app.mesq_pool(uuid) from public, anon, authenticated;

--  Bu mesqin hedef sagirdleri: sexsi - o sagird; qrup - qrupun aktiv sagirdleri
create or replace function app.mesq_targets(p_asg uuid)
returns table (student_id uuid)
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select s.id from public.mesq_assignments m
    join public.students s on s.class_id = m.class_id
   where m.id = p_asg and (m.student_id is null and s.is_active or s.id = m.student_id)
$$;
revoke all on function app.mesq_targets(uuid) from public, anon, authenticated;

--  Muellim bu mesqe baxa bilermi (qrupun muellimi ve ya hesab uzvu)
create or replace function app.mesq_teacher_ok(p_asg uuid)
returns boolean
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select coalesce((select app.homework_class_ok(m.class_id) from public.mesq_assignments m where m.id = p_asg), false)
$$;
revoke all on function app.mesq_teacher_ok(uuid) from public, anon, authenticated;

--  Bir mesqin xulasesi (siyahi, sagird, valideyn eyni sayir): n - suallar,
--  hedef, baslayan, bitiren, duz %.
create or replace function app.mesq_summary(p_asg uuid)
returns jsonb
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  with m as (select * from public.mesq_assignments where id = p_asg),
       nq as (select count(*)::int n from m, unnest(m.qids) x where exists (select 1 from public.questions q where q.id = x)),
       per as (
         select a.student_id, count(*) filter (where a.is_correct is not null) ans,
                count(*) filter (where a.is_correct) ok
           from public.mesq_answers a
          where a.assignment_id = p_asg
            and a.student_id in (select student_id from app.mesq_targets(p_asg))
          group by a.student_id)
  select jsonb_build_object(
    'n',        (select n from nq),
    'targets',  (select count(*) from app.mesq_targets(p_asg)),
    'started',  (select count(*) from per where ans > 0),
    'finished', (select count(*) from per, nq where per.ans >= nq.n and nq.n > 0),
    'answered', coalesce((select sum(ans) from per), 0),
    'pct',      (select case when sum(ans) > 0 then round(sum(ok) * 100.0 / sum(ans)) end from per))
$$;
revoke all on function app.mesq_summary(uuid) from public, anon, authenticated;

-- =====================================================================
--  MUELLIM
-- =====================================================================

--  Mesq sualı olan dersler - qrupun sinfi uzre (sinif yoxdursa hamisi).
create or replace function public.rpc_mesq_lessons(p_class_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare v_lvl uuid;
begin
  if auth.uid() is null then
    raise exception 'Daxil olmamısınız.' using errcode = '28000';
  end if;
  if not app.homework_class_ok(p_class_id) then
    raise exception 'Bu qrupa giriş yoxdur.' using errcode = '42501';
  end if;
  select level_id into v_lvl from public.classes where id = p_class_id;
  return jsonb_build_object(
    'level', (select l.name from public.levels l where l.id = v_lvl),
    'items', coalesce((
      with m as (
        select substr(t, 6) slug, count(*)::int n
          from public.questions q, unnest(q.tags) t
         where q.status::text = 'mesq' and t like 'ders:%'
         group by 1)
      select jsonb_agg(jsonb_build_object(
               'id', d.id, 'name', d.name, 'chapter', f.name, 'subject', s.name,
               'level', l.name, 'n', m.n,
               'given', (select count(*) from public.mesq_assignments a
                          where a.class_id = p_class_id and a.topic_id = d.id))
             order by s.sort, l.sort, f.sort, d.sort, d.name)
        from m
        join public.topics d on d.slug = m.slug
        join public.topics f on f.id = d.parent_id
        join public.subjects s on s.id = f.subject_id
        left join public.levels l on l.id = f.level_id
       where v_lvl is null or f.level_id = v_lvl), '[]'::jsonb));
end $$;

create or replace function public.rpc_mesq_assign(p_class_id uuid, p_topic_id uuid,
  p_student_id uuid default null, p_due date default null)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_q  uuid[];
  v_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Daxil olmamısınız.' using errcode = '28000';
  end if;
  if not app.homework_class_ok(p_class_id) then
    raise exception 'Bu qrupa məşq verə bilməzsiniz.' using errcode = '42501';
  end if;
  if p_student_id is not null and not exists (
       select 1 from public.students s where s.id = p_student_id and s.class_id = p_class_id and s.is_active) then
    raise exception 'Şagird bu qrupda deyil.' using errcode = '22023';
  end if;
  if p_due is not null and p_due < (now() at time zone 'Asia/Baku')::date then
    raise exception 'Son tarix keçmiş gün ola bilməz.' using errcode = '22023';
  end if;
  select coalesce(array_agg(x.id order by x.difficulty, x.ext_key nulls last, x.id), '{}')
    into v_q from app.mesq_pool(p_topic_id) x;
  if cardinality(v_q) = 0 then
    raise exception 'Bu dərsdə hələ məşq sualı yoxdur.' using errcode = '22023';
  end if;
  --  gunde 50-den cox yox (ev tapsirigi ile eyni qoruyucu)
  if (select count(*) from public.mesq_assignments a
       where a.class_id = p_class_id and a.created_at > now() - interval '1 day') >= 50 then
    raise exception 'Bu gün üçün kifayətdir — sabah davam edin.' using errcode = '22023';
  end if;
  insert into public.mesq_assignments (class_id, student_id, topic_id, qids, created_by, due)
  values (p_class_id, p_student_id, p_topic_id, v_q, auth.uid(), p_due)
  returning id into v_id;
  return jsonb_build_object('ok', true, 'id', v_id, 'n', cardinality(v_q));
end $$;

create or replace function public.rpc_mesq_list(p_class_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
begin
  if auth.uid() is null then
    raise exception 'Daxil olmamısınız.' using errcode = '28000';
  end if;
  if not app.homework_class_ok(p_class_id) then
    raise exception 'Bu qrupa giriş yoxdur.' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', m.id, 'lesson', d.name, 'chapter', f.name,
             'student', s.full_name, 'student_id', m.student_id,
             'due', m.due, 'at', m.created_at) || app.mesq_summary(m.id)
           order by m.created_at desc)
      from public.mesq_assignments m
      join public.topics d on d.id = m.topic_id
      left join public.topics f on f.id = d.parent_id
      left join public.students s on s.id = m.student_id
     where m.class_id = p_class_id), '[]'::jsonb);
end $$;

--  Bir mesqin hesabati: kim basladi / bitirdi, duz %, en cox sehv olunan suallar
create or replace function public.rpc_mesq_report(p_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare m public.mesq_assignments%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Daxil olmamısınız.' using errcode = '28000';
  end if;
  if not app.mesq_teacher_ok(p_id) then
    raise exception 'Bu məşqə giriş yoxdur.' using errcode = '42501';
  end if;
  select * into m from public.mesq_assignments where id = p_id;
  return jsonb_build_object(
    'id', m.id, 'class_id', m.class_id, 'due', m.due, 'at', m.created_at,
    'class', (select c.name from public.classes c where c.id = m.class_id),
    'lesson', (select d.name from public.topics d where d.id = m.topic_id),
    'chapter', (select f.name from public.topics d join public.topics f on f.id = d.parent_id where d.id = m.topic_id),
    'student', (select s.full_name from public.students s where s.id = m.student_id),
    'summary', app.mesq_summary(m.id),
    'students', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', s.id, 'name', s.full_name,
               'answered', coalesce(z.ans, 0), 'correct', coalesce(z.ok, 0), 'last', z.last)
             order by coalesce(z.ans, 0) = 0, s.full_name)
        from app.mesq_targets(m.id) t
        join public.students s on s.id = t.student_id
        left join lateral (
          select count(*) filter (where a.is_correct is not null) ans,
                 count(*) filter (where a.is_correct) ok, max(a.answered_at) last
            from public.mesq_answers a
           where a.assignment_id = m.id and a.student_id = s.id) z on true), '[]'::jsonb),
    --  en cox sehv olunan 5 sual: sablon sualda metn sehv eden sagirdin gorduyu reqemle
    'hard', coalesce((
      select jsonb_agg(jsonb_build_object(
               'no', array_position(m.qids, w.question_id),
               'body', app.pq_render(q.body, w.p), 'wrong', w.wrong, 'answered', w.ans)
             order by w.wrong desc, array_position(m.qids, w.question_id))
        from (
          select a.question_id, count(*) filter (where a.is_correct = false) wrong,
                 count(*) filter (where a.is_correct is not null) ans,
                 (array_agg(a.params) filter (where a.is_correct = false))[1] p
            from public.mesq_answers a
           where a.assignment_id = m.id
           group by a.question_id
          having count(*) filter (where a.is_correct = false) > 0
           order by 2 desc, 1
           limit 5) w
        join public.questions q on q.id = w.question_id), '[]'::jsonb));
end $$;

create or replace function public.rpc_mesq_del(p_id uuid)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
begin
  if auth.uid() is null then
    raise exception 'Daxil olmamısınız.' using errcode = '28000';
  end if;
  if not app.mesq_teacher_ok(p_id) then
    raise exception 'Bu məşqi silə bilməzsiniz.' using errcode = '42501';
  end if;
  delete from public.mesq_assignments where id = p_id;
  return jsonb_build_object('ok', true);
end $$;

revoke all on function public.rpc_mesq_lessons(uuid)                 from public, anon;
grant execute on function public.rpc_mesq_lessons(uuid)                 to authenticated;
revoke all on function public.rpc_mesq_assign(uuid, uuid, uuid, date)  from public, anon;
grant execute on function public.rpc_mesq_assign(uuid, uuid, uuid, date)  to authenticated;
revoke all on function public.rpc_mesq_list(uuid)                    from public, anon;
grant execute on function public.rpc_mesq_list(uuid)                    to authenticated;
revoke all on function public.rpc_mesq_report(uuid)                  from public, anon;
grant execute on function public.rpc_mesq_report(uuid)                  to authenticated;
revoke all on function public.rpc_mesq_del(uuid)                     from public, anon;
grant execute on function public.rpc_mesq_del(uuid)                     to authenticated;

-- =====================================================================
--  SAGIRD
-- =====================================================================

--  Sagirdin mesqleri: bitmemisler + son 14 gunde bitenler
create or replace function public.rpc_student_mesq_list(p_token text)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare
  v_st  uuid := app.session_student(p_token);
  v_cls uuid;
begin
  if v_st is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;
  select class_id into v_cls from public.students where id = v_st;
  return coalesce((
    select jsonb_agg(x order by (x->>'done')::boolean, x->>'at' desc)
      from (
        select jsonb_build_object(
                 'id', m.id, 'lesson', d.name, 'chapter', f.name, 'subject', sj.name,
                 'personal', m.student_id is not null, 'due', m.due, 'at', m.created_at,
                 'n', z.n, 'answered', z.ans, 'correct', z.ok,
                 'done', z.n > 0 and z.ans >= z.n) x
          from public.mesq_assignments m
          join public.topics d on d.id = m.topic_id
          left join public.topics f on f.id = d.parent_id
          left join public.subjects sj on sj.id = d.subject_id
          cross join lateral (
            select (select count(*) from unnest(m.qids) q0 where exists (select 1 from public.questions q where q.id = q0))::int n,
                   (select count(*) from public.mesq_answers a where a.assignment_id = m.id and a.student_id = v_st and a.is_correct is not null)::int ans,
                   (select count(*) from public.mesq_answers a where a.assignment_id = m.id and a.student_id = v_st and a.is_correct)::int ok,
                   (select max(a.answered_at) from public.mesq_answers a where a.assignment_id = m.id and a.student_id = v_st) last) z
         where m.class_id = v_cls and (m.student_id is null or m.student_id = v_st)
           and (z.ans < z.n or z.last > now() - interval '14 days')) q), '[]'::jsonb);
end $$;

--  Novbeti sual.  Gosterilib cavablanmayan varsa - eynisi (eyni reqemle).
create or replace function public.rpc_student_mesq_next(p_token text, p_id uuid)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_st   uuid := app.session_student(p_token);
  m      public.mesq_assignments%rowtype;
  v_q    uuid;
  v_par  jsonb;
  v_n    int;
  v_ans  int;
  v_ok   int;
begin
  if v_st is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;
  select ma.* into m from public.mesq_assignments ma
    join public.students s on s.id = v_st and s.class_id = ma.class_id
   where ma.id = p_id and (ma.student_id is null or ma.student_id = v_st);
  if m.id is null then
    raise exception 'Bu məşq sənin üçün deyil.' using errcode = '42501';
  end if;

  select count(*) into v_n from unnest(m.qids) x where exists (select 1 from public.questions q where q.id = x);
  select count(*) filter (where is_correct is not null), count(*) filter (where is_correct)
    into v_ans, v_ok
    from public.mesq_answers where assignment_id = m.id and student_id = v_st;

  --  gosterilib, cavabsiz (sehife yenilendi)
  select a.question_id, a.params into v_q, v_par
    from public.mesq_answers a
   where a.assignment_id = m.id and a.student_id = v_st and a.is_correct is null
     and exists (select 1 from public.questions q where q.id = a.question_id)
   limit 1;
  if v_q is null then
    select x.q into v_q
      from unnest(m.qids) with ordinality x(q, k)
     where exists (select 1 from public.questions q where q.id = x.q)
       and not exists (select 1 from public.mesq_answers a
                        where a.assignment_id = m.id and a.student_id = v_st and a.question_id = x.q)
     order by x.k limit 1;
    if v_q is not null then
      select app.pq_seed(q.params, q.id) into v_par from public.questions q where q.id = v_q;
      insert into public.mesq_answers (assignment_id, student_id, question_id, params)
      values (m.id, v_st, v_q, v_par)
      on conflict do nothing;
    end if;
  end if;

  return jsonb_build_object(
    'id', m.id,
    'lesson', (select d.name from public.topics d where d.id = m.topic_id),
    'subject', (select s.name from public.topics d join public.subjects s on s.id = d.subject_id where d.id = m.topic_id),
    'n', v_n, 'answered', v_ans, 'correct', v_ok, 'pos', v_ans + 1,
    'done', v_q is null,
    'question', case when v_q is null then null else (
      select jsonb_build_object(
               'id', q.id, 'kind', q.kind,
               'body', app.pq_render(q.body, v_par),
               'media_url', q.media_url,
               'difficulty', q.difficulty,
               'options', coalesce((
                 select jsonb_agg(jsonb_build_object('id', o.id, 'body', app.pq_render(o.body, v_par)) order by o.ord)
                   from public.question_options o where o.question_id = q.id), '[]'::jsonb))
        from public.questions q where q.id = v_q) end);
end $$;

--  Cavab - yalniz gosterilmis, cavabsiz suala.  Qaytarir: duz/sehv + izah.
create or replace function public.rpc_student_mesq_answer(p_token text, p_id uuid,
  p_question_id uuid, p_option_ids uuid[] default null, p_text text default null)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_st   uuid := app.session_student(p_token);
  a      public.mesq_answers%rowtype;
  q      public.questions%rowtype;
  v_ok   boolean;
  v_sel  uuid[] := coalesce(p_option_ids, '{}');
  v_cor  uuid[];
  v_txt  text := nullif(btrim(coalesce(p_text, '')), '');
  v_ch   text;
  v_n    int;
  v_ans  int;
  v_cnt  int;
begin
  if v_st is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;
  select * into a from public.mesq_answers
   where assignment_id = p_id and student_id = v_st and question_id = p_question_id;
  if a.assignment_id is null or a.is_correct is not null then
    raise exception 'Bu sual artıq cavablanıb — «Növbəti» bas.' using errcode = '22023';
  end if;
  select * into q from public.questions where id = p_question_id;

  if q.kind = 'text' then
    if v_txt is null then
      raise exception 'Cavab yazılmayıb.' using errcode = '22023';
    end if;
    v_ok := lower(v_txt) = any (
      select lower(btrim(app.pq_render(o.body, a.params))) from public.question_options o
       where o.question_id = q.id and o.is_correct);
    v_ch := v_txt;
  else
    select coalesce(array_agg(x order by x), '{}') into v_sel
      from unnest(v_sel) x
     where exists (select 1 from public.question_options o where o.id = x and o.question_id = q.id);
    if cardinality(v_sel) = 0 then
      raise exception 'Cavab seçilməyib.' using errcode = '22023';
    end if;
    select coalesce(array_agg(o.id order by o.id), '{}') into v_cor
      from public.question_options o where o.question_id = q.id and o.is_correct;
    v_ok := cardinality(v_cor) > 0 and v_sel @> v_cor and v_cor @> v_sel;
    select string_agg(app.pq_render(o.body, a.params), ' · ' order by o.ord) into v_ch
      from public.question_options o where o.id = any(v_sel);
  end if;

  update public.mesq_answers
     set is_correct = v_ok, chosen = left(v_ch, 300), answered_at = now()
   where assignment_id = p_id and student_id = v_st and question_id = p_question_id;

  select count(*) into v_n
    from public.mesq_assignments m, unnest(m.qids) x
   where m.id = p_id and exists (select 1 from public.questions q2 where q2.id = x);
  select count(*) filter (where is_correct is not null), count(*) filter (where is_correct)
    into v_ans, v_cnt
    from public.mesq_answers where assignment_id = p_id and student_id = v_st;

  return jsonb_build_object(
    'correct', v_ok,
    'explanation', app.pq_render(coalesce(q.explanation, ''), a.params),
    'n', v_n, 'answered', v_ans, 'ok', v_cnt, 'done', v_ans >= v_n);
end $$;

revoke all on function public.rpc_student_mesq_list(text)                         from public;
grant execute on function public.rpc_student_mesq_list(text)                         to anon, authenticated;
revoke all on function public.rpc_student_mesq_next(text, uuid)                   from public;
grant execute on function public.rpc_student_mesq_next(text, uuid)                   to anon, authenticated;
revoke all on function public.rpc_student_mesq_answer(text, uuid, uuid, uuid[], text) from public;
grant execute on function public.rpc_student_mesq_answer(text, uuid, uuid, uuid[], text) to anon, authenticated;

-- =====================================================================
--  VALIDEYN: bir setir - son mesqler (bitmemis + son 14 gun)
-- =====================================================================
create or replace function public.rpc_parent_mesq(p_token text)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare
  v_st  uuid := app.session_parent(p_token);
  v_cls uuid;
begin
  if v_st is null then
    raise exception 'Sessiya bitib. Yenidən daxil olun.' using errcode = '28000';
  end if;
  select class_id into v_cls from public.students where id = v_st;
  return coalesce((
    select jsonb_agg(x order by x->>'at' desc)
      from (
        select jsonb_build_object('lesson', d.name, 'due', m.due, 'at', m.created_at,
                 'n', z.n, 'answered', z.ans, 'correct', z.ok) x
          from public.mesq_assignments m
          join public.topics d on d.id = m.topic_id
          cross join lateral (
            select (select count(*) from unnest(m.qids) q0 where exists (select 1 from public.questions q where q.id = q0))::int n,
                   (select count(*) from public.mesq_answers a where a.assignment_id = m.id and a.student_id = v_st and a.is_correct is not null)::int ans,
                   (select count(*) from public.mesq_answers a where a.assignment_id = m.id and a.student_id = v_st and a.is_correct)::int ok,
                   (select max(a.answered_at) from public.mesq_answers a where a.assignment_id = m.id and a.student_id = v_st) last) z
         where m.class_id = v_cls and (m.student_id is null or m.student_id = v_st)
           and (z.ans < z.n or z.last > now() - interval '14 days')
         order by m.created_at desc
         limit 5) q), '[]'::jsonb);
end $$;
revoke all on function public.rpc_parent_mesq(text) from public;
grant execute on function public.rpc_parent_mesq(text) to anon, authenticated;
