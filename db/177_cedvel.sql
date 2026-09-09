-- =====================================================================
--  177_cedvel.sql — QRUPUN HƏFTƏLİK CƏDVƏLİ (v1)
--
--  ISTIFADECI QERARI (2026-09-09):
--   * v1 SADE olsun: heftelik gun+saat, bir dersi legv/kocurme,
--     toqqusma xeberdarligi.  Otaq, coxmuellimli cedvel, odenisle
--     elaqe YOXDUR.
--   * ISTEYE BAGLI: cedvel qurulmayibsa hec bir ekranda GORUNMESIN -
--     ne muellimde, ne valideynde, ne sagirdde.  Bos «Cədvəl» karti
--     olmamalidir; qurmayan muellim ucun tetbiq elə bil bu funksiyaya
--     sahib deyil.  Sondurmek = setirleri silmek, melumat itmir
--     (kecmis dersler public.lessons-dadir, ora toxunulmur).
--   * PULSUZ.  Abune qapisi YOXDUR.  Sebeb: cedvel gundelik vərdiş
--     yaradan hissedir ve DAVAMIYYETI OZU DOLDURUR - «bu gun dərs
--     var» karti cixir, muellim tarix secmir.  Reqib (kampus.az)
--     onu birinci pilledən pullu satir; biz pulsuz veririk.
--
--  NIYE MATERIALLASDIRMIRIQ:  cedveldən dersler ONCEDEN public.lessons-a
--  yazilmir.  Yoxsa cedvel deyisende gelecek setirlər kohne qalir ve
--  iki heqiqet yaranir.  Burada QAYDA saxlanilir, hefte ANBAAN
--  hesablanir; public.lessons yalniz FAKTI (davamiyyet goturulub)
--  saxlayir - o, artiq db/130-un isidir.
--
--  HEFTENIN GUNU: ISO - 1 = Bazar ertəsi ... 7 = Bazar.
--  Tarixler BAKI gunu ile (CLAUDE.md qaydasi).
-- =====================================================================

do $$
begin
  if to_regclass('public.lessons') is null then
    raise exception 'ONCE 130_davamiyyet.sql isledilmelidir.';
  end if;
end $$;

--  QAYDA: qrupun heftelik derslari
create table if not exists public.class_schedule (
  class_id  uuid     not null references public.classes(id) on delete cascade,
  weekday   smallint not null check (weekday between 1 and 7),
  starts_at time     not null,
  mins      smallint not null default 60 check (mins between 15 and 480),
  primary key (class_id, weekday, starts_at)
);

--  ISTISNA: bir dersin legvi ve ya kocurulmesi.
--  new_date null  -> hemin gun ders YOXDUR (legv)
--  new_date dolu  -> ders basqa gune/saata kecirilib
create table if not exists public.lesson_changes (
  class_id uuid not null references public.classes(id) on delete cascade,
  on_date  date not null,
  new_date date,
  new_time time,
  note     text,
  primary key (class_id, on_date)
);

create index if not exists idx_sched_class on public.class_schedule (class_id);
create index if not exists idx_lchg_class  on public.lesson_changes (class_id, on_date);

alter table public.class_schedule enable row level security;
alter table public.lesson_changes enable row level security;
revoke all on public.class_schedule, public.lesson_changes from public, anon, authenticated;

-- ------------------------------------------------------------ komekci
--  Baki gunu - butun teqvim hesablari bundan baslayir
create or replace function app.baki_bugun() returns date
language sql stable set search_path = public, extensions, pg_temp as $$
  select (now() at time zone 'Asia/Baku')::date
$$;

--  Bir hesabin BUTUN qruplari uzre [p_from, p_from+p_days) araligindaki
--  dersler.  VEZIYYET (hal) sutunu:
--    plan       adi ders
--    cancelled  legv edilib - EKRANDAN SILINMIR, ustunden xett cekilir
--               ki, muellim «Bərpa et» ede bilsin (yoxsa geri qaytarmaq
--               ucun tutacaq qalmir - ilk qurulusda bele idi, duzeldildi)
--    moved_out  bu gunden kocurulub, hara kocduyu 'other'-dedir
--    moved_in   basqa gunden BURA kocurulub
create or replace function app.cedvel_araliq(p_account uuid, p_from date, p_days int)
returns table (on_date date, starts_at time, mins smallint,
               class_id uuid, class_name text, hal text, other date)
language sql stable set search_path = public, extensions, pg_temp as $$
  with gun as (
    select (p_from + g)::date d from generate_series(0, greatest(p_days, 1) - 1) g
  ),
  plan as (
    select gun.d as on_date, s.starts_at, s.mins, c.id as class_id, c.name as class_name,
           ch.on_date is not null as deyisib, ch.new_date
      from gun
      join public.class_schedule s on s.weekday = extract(isodow from gun.d)::int
      join public.classes c on c.id = s.class_id
      left join public.lesson_changes ch on ch.class_id = c.id and ch.on_date = gun.d
     where c.account_id = p_account
  ),
  kocme as (
    select ch.new_date as on_date,
           coalesce(ch.new_time, (select min(s2.starts_at) from public.class_schedule s2
                                   where s2.class_id = ch.class_id)) as starts_at,
           coalesce((select min(s2.mins) from public.class_schedule s2
                      where s2.class_id = ch.class_id), 60::smallint) as mins,
           c.id as class_id, c.name as class_name, ch.on_date as haradan
      from public.lesson_changes ch
      join public.classes c on c.id = ch.class_id
     where c.account_id = p_account
       and ch.new_date is not null
       and ch.new_date >= p_from
       and ch.new_date <  p_from + greatest(p_days, 1)
  )
  select on_date, starts_at, mins, class_id, class_name,
         case when not deyisib then 'plan'
              when new_date is null then 'cancelled'
              else 'moved_out' end,
         new_date
    from plan
  union all
  select on_date, starts_at, mins, class_id, class_name, 'moved_in', haradan from kocme
  order by 1, 2, 5
$$;

-- ------------------------------------------------------ muellim: oxu
create or replace function public.rpc_schedule_get(p_class_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_class public.classes%rowtype := app.plan_class(p_class_id);
begin
  return jsonb_build_object(
    'class_id', p_class_id,
    'rows', coalesce((
      select jsonb_agg(jsonb_build_object('weekday', s.weekday,
                                          'starts_at', to_char(s.starts_at, 'HH24:MI'),
                                          'mins', s.mins)
                       order by s.weekday, s.starts_at)
        from public.class_schedule s where s.class_id = p_class_id), '[]'::jsonb),
    --  TOQQUSMA: eyni hesabda basqa qrup eyni gun/saatda.  Xeta deyil,
    --  XEBERDARLIQDIR - repetitor bezen bunu bilerek edir (iki usaq
    --  eyni masada).  Qərar muellimindir.
    'conflicts', coalesce((
      select jsonb_agg(distinct jsonb_build_object('class', c2.name,
                                                   'weekday', s1.weekday,
                                                   'starts_at', to_char(s1.starts_at, 'HH24:MI')))
        from public.class_schedule s1
        join public.class_schedule s2 on s2.weekday = s1.weekday
                                     and s2.class_id <> s1.class_id
        join public.classes c2 on c2.id = s2.class_id
                              and c2.account_id = v_class.account_id
       where s1.class_id = p_class_id
         --  vaxt araliqlari kesisirse
         and s1.starts_at < s2.starts_at + (s2.mins || ' minutes')::interval
         and s2.starts_at < s1.starts_at + (s1.mins || ' minutes')::interval
      ), '[]'::jsonb));
end $$;

-- ----------------------------------------------------- muellim: yaz
--  Qrupun BUTUN cedveli birdefeye evez olunur.  Bos massiv = cedvel
--  silinir (funksiya sondurulur) - kecmis dersler qalir.
create or replace function public.rpc_schedule_set(p_class_id uuid, p_rows jsonb)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_class public.classes%rowtype := app.plan_class(p_class_id);
  v_n     int;
begin
  if p_rows is null or jsonb_typeof(p_rows) <> 'array' then
    raise exception 'Cedvel siyahi olmalidir.' using errcode = '22023';
  end if;
  if jsonb_array_length(p_rows) > 14 then
    raise exception 'Heftede en coxu 14 ders.' using errcode = '22023';
  end if;

  delete from public.class_schedule where class_id = p_class_id;
  insert into public.class_schedule (class_id, weekday, starts_at, mins)
  select p_class_id,
         (x->>'weekday')::smallint,
         (x->>'starts_at')::time,
         coalesce(nullif(x->>'mins', '')::smallint, 60)
    from jsonb_array_elements(p_rows) x
  on conflict (class_id, weekday, starts_at) do nothing;

  select count(*) into v_n from public.class_schedule where class_id = p_class_id;
  --  Cedvel silinende kohne legv/kocurmeler menasiz qalir
  if v_n = 0 then
    delete from public.lesson_changes where class_id = p_class_id;
  end if;
  return public.rpc_schedule_get(p_class_id) || jsonb_build_object('ok', true, 'n', v_n);
end $$;

-- ------------------------------------------- muellim: legv / kocurme
create or replace function public.rpc_lesson_move(
  p_class_id uuid, p_on_date date,
  p_new_date date default null, p_new_time text default null,
  p_note text default null)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare v_class public.classes%rowtype := app.plan_class(p_class_id);
begin
  if p_on_date is null then
    raise exception 'Tarix lazimdir.' using errcode = '22023';
  end if;
  if p_new_date is not null and p_new_date < p_on_date - 30 then
    raise exception 'Ders 30 gunden cox geri kecirile bilmez.' using errcode = '22023';
  end if;
  insert into public.lesson_changes (class_id, on_date, new_date, new_time, note)
  values (p_class_id, p_on_date, p_new_date,
          nullif(btrim(coalesce(p_new_time, '')), '')::time,
          nullif(btrim(coalesce(p_note, '')), ''))
  on conflict (class_id, on_date) do update
    set new_date = excluded.new_date,
        new_time = excluded.new_time,
        note     = excluded.note;
  return jsonb_build_object('ok', true);
end $$;

--  Legvi geri al
create or replace function public.rpc_lesson_restore(p_class_id uuid, p_on_date date)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare v_class public.classes%rowtype := app.plan_class(p_class_id);
begin
  delete from public.lesson_changes
   where class_id = p_class_id and on_date = p_on_date;
  return jsonb_build_object('ok', true);
end $$;

-- -------------------------------------------------- muellim: hefte
--  Icmaldaki «bu gün dərs var» karti ve heftelik baxis.
--  CEDVEL QURULMAYIBSA 'on' false qayidir - ekran hec ne cizmir.
create or replace function public.rpc_week(p_from date default null)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_acc uuid := app.pick_account(null);
  v_b   date := app.baki_bugun();
  --  hefte BAZAR ERTESI baslayir
  v_from date := coalesce(p_from, (v_b - (extract(isodow from v_b)::int - 1))::date);
begin
  return jsonb_build_object(
    'on',    exists (select 1 from public.class_schedule s
                      join public.classes c on c.id = s.class_id
                     where c.account_id = v_acc),
    'today', v_b,
    'from',  v_from,
    'days', coalesce((
      select jsonb_agg(jsonb_build_object(
               'date', r.on_date,
               'time', to_char(r.starts_at, 'HH24:MI'),
               'mins', r.mins,
               'class_id', r.class_id,
               'class', r.class_name,
               'hal', r.hal,
               'other', r.other,
               --  davamiyyet artiq goturulubmu?
               'done', exists (select 1 from public.lessons l
                                where l.class_id = r.class_id and l.held_on = r.on_date),
               'students', (select count(*) from public.students st
                             where st.class_id = r.class_id and st.is_active))
               order by r.on_date, r.starts_at)
        from app.cedvel_araliq(v_acc, v_from, 7) r), '[]'::jsonb));
end $$;

-- ------------------------------------------------- valideyn: bu hefte
--  Valideyn ekranina «Bu həftə» elave olunur.  Govde 174-dendir,
--  yeganə deyisiklik - yeni 'week' acari.  Sagird tetbiqi v1-de
--  toxunulmur (sadə saxlayiriq - istifadeci qaydasi).
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
end $$;

revoke all on function public.rpc_schedule_get(uuid) from public, anon;
grant execute on function public.rpc_schedule_get(uuid) to authenticated;
revoke all on function public.rpc_schedule_set(uuid, jsonb) from public, anon;
grant execute on function public.rpc_schedule_set(uuid, jsonb) to authenticated;
revoke all on function public.rpc_lesson_move(uuid, date, date, text, text) from public, anon;
grant execute on function public.rpc_lesson_move(uuid, date, date, text, text) to authenticated;
revoke all on function public.rpc_lesson_restore(uuid, date) from public, anon;
grant execute on function public.rpc_lesson_restore(uuid, date) to authenticated;
revoke all on function public.rpc_week(date) from public, anon;
grant execute on function public.rpc_week(date) to authenticated;
revoke all on function app.cedvel_araliq(uuid, date, int) from public, anon, authenticated;
revoke all on function app.baki_bugun() from public, anon, authenticated;
