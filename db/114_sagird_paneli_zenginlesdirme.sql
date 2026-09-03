-- =====================================================================
--  114_sagird_paneli_zenginlesdirme.sql : sagird oz ekraninda 4 yeni sey gorur
--
--  Evvel sagirdin oz ekraninda YALNIZ tapsiriqlar/serbest mesq var idi.
--  "Nece kecirem" (dovamlilik), "nə vaxt ne kecdik" (dərs planı) ve
--  "harada zeifem" (movzu) yalniz muellim ve valideyn terefinde gorunurdu -
--  amma bunlarin hamisi elə şagirdin özünə lazımdır, valideynə yox.
--
--  ZEIF MOVZULAR: valideyn ekraninda (107/110) bu abunə tələb edir -
--  o, muellimin satdigi analitikadir.  Burda ISE ABUNƏSIZ acigdir:
--  şagirdin öz zəifliyini bilmesi tehsil mezmunudur, satilan analitika
--  deyil.  Qərar istifadəçi ilə aydinlasdirilib.
--
--  assigned/practice hissesi TOXUNULMAYIB - amma diqqet: 03-den yox,
--  28_ferdi_tapsiriq.sql-in CARI govdesinden goturulub (orda 'personal'
--  sahesi ve ferdi teyinat filtri elave olunmusdu).  Ilk versiyada
--  bunu 03-den kopyalamisdim ve ferdi teyinat duzelisini oz-ozune geri
--  qaytarmisdim - smoke_ferdi.sql bunu tutdu.
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
        ) z), '[]'::jsonb)
  );
end $$;
