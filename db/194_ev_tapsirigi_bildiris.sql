-- =====================================================================
--  194_ev_tapsirigi_bildiris.sql : ev tapsirigi «Bu gunun dersi»nde ve siqnallarda
--
--  Istifadeci: «Bu gunun dersi kartinda son ev tapsirigi; bildiris - bu da
--  yaxsi fikirdir».
--    rpc_lesson_prep -> 'hw'        son metnle tapsiriq: kim etdi / etmedi
--    rpc_home        -> 'hw_alerts' son tarixi bu gun ve ya kecmis, etmeyen
--                                   var - Bildirisler ekraninda, zeng noqtesi
--  Govdeler pg_get_functiondef ile goturulub, bir acar elave olunub.
-- =====================================================================

CREATE OR REPLACE FUNCTION public.rpc_lesson_prep(p_class_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
declare
  v_class public.classes%rowtype := app.plan_class(p_class_id);
  v_plan  public.class_plans%rowtype;
  v_next  jsonb;
  v_last  jsonb;
  v_pend  jsonb;
  v_open  int;
begin
  --  Qrupun plani (bir qrupda bir nece fenn plani ola biler - en son
  --  islenen: son "kecildi" tarixi, yoxsa yaranma tarixi)
  select p.* into v_plan
    from public.class_plans p
   where p.class_id = p_class_id
   order by (select max(i.done_at) from public.class_plan_items i
              where i.plan_id = p.id) desc nulls last,
            p.created_at desc
   limit 1;

  if v_plan.id is not null then
    --  novbeti = ilk kecilmemis ders
    select jsonb_build_object(
             'item_id',  i.id,
             'topic',    t.name,
             'topic_id', coalesce(par.id, t.id),
             'group',    par.name,
             --  135: isinme testi
             'warm_test_id', i.warm_test_id,
             'warm_avg', (select round(avg(a.percent)) from public.attempts a where a.test_id = i.warm_test_id and a.status = 'submitted'),
             'warm_takers', (select count(distinct a.student_id) from public.attempts a where a.test_id = i.warm_test_id and a.status = 'submitted'),
             'gpos', case when par.id is null then null else
                       (select count(*) from public.class_plan_items i2
                          join public.topics t2 on t2.id = i2.topic_id
                         where i2.plan_id = v_plan.id and t2.parent_id = par.id
                           and i2.ord <= i.ord) end,
             'gtotal', case when par.id is null then null else
                       (select count(*) from public.class_plan_items i2
                          join public.topics t2 on t2.id = i2.topic_id
                         where i2.plan_id = v_plan.id and t2.parent_id = par.id) end)
      into v_next
      from public.class_plan_items i
      join public.topics t on t.id = i.topic_id
      left join public.topics par on par.id = t.parent_id
     where i.plan_id = v_plan.id and i.done_at is null
     order by i.ord limit 1;

    --  son kecilen = done_at en boyuk; testi varsa ortalama
    select jsonb_build_object(
             'item_id',  i.id,
             'topic',    t.name,
             'topic_id', coalesce(par.id, t.id),
             'group',    par.name,
             'done_at',  i.done_at,
             'test_id',  i.test_id,
             'avg', (select round(avg(a.percent)) from public.attempts a
                      where a.test_id = i.test_id and a.status = 'submitted'),
             'takers', (select count(distinct a.student_id) from public.attempts a
                         where a.test_id = i.test_id and a.status = 'submitted'))
      into v_last
      from public.class_plan_items i
      join public.topics t on t.id = i.topic_id
      left join public.topics par on par.id = t.parent_id
     where i.plan_id = v_plan.id and i.done_at is not null
     order by i.done_at desc, i.ord desc limit 1;
  end if;

  --  Acıq teyinatlar: bu qrupa (hamiya ve ya ferdi) verilmis, vaxti
  --  bitmemis; sagird hele submit etmeyibse "etmeyib" sayilir
  select count(*) into v_open
    from public.assignments a
   where a.class_id = p_class_id and app.assignment_open(a.*);

  select coalesce(jsonb_agg(jsonb_build_object(
           'student_id', z.id, 'name', z.full_name, 'n', z.n,
           'tests', z.tests) order by z.n desc, z.full_name), '[]'::jsonb)
    into v_pend
    from (
      select s.id, s.full_name, count(*) n,
             jsonb_agg(t.title order by a.closes_at nulls last, t.title) tests
        from public.students s
        join public.assignments a on a.class_id = s.class_id
                                 and (a.student_id is null or a.student_id = s.id)
                                 and app.assignment_open(a.*)
        join public.tests t on t.id = a.test_id
       where s.class_id = p_class_id and s.is_active
         and not exists (select 1 from public.attempts at
                          where at.student_id = s.id and at.test_id = a.test_id
                            and at.status = 'submitted')
       group by s.id, s.full_name
    ) z;

  return jsonb_build_object(
    --  194: son metnle ev tapsirigi - «Bu gunun dersi» kartinda kim etdi/etmedi
    'hw', (select jsonb_build_object(
             'id', h.id, 'body', h.body, 'due', h.due, 'created_at', h.created_at,
             'personal', h.student_id is not null,
             'student', (select s.full_name from public.students s where s.id = h.student_id),
             'done', (select count(*) from public.homework_done hd where hd.homework_id = h.id),
             'total', case when h.student_id is not null then 1
                      else (select count(*) from public.students s where s.class_id = h.class_id and s.is_active) end,
             'undone', coalesce((select jsonb_agg(s.full_name order by s.full_name)
                                   from public.students s
                                  where s.class_id = h.class_id and s.is_active
                                    and (h.student_id is null or h.student_id = s.id)
                                    and not exists (select 1 from public.homework_done hd
                                                     where hd.homework_id = h.id and hd.student_id = s.id)), '[]'::jsonb))
             from public.homework h
            where h.class_id = p_class_id and h.created_at > now() - interval '45 days'
            order by h.created_at desc, h.id desc limit 1),
    'paid',     app.has_active_subscription(v_class.account_id),
    'has_plan', v_plan.id is not null,
    'plan_id',  v_plan.id,
    'subject',  (select s.slug from public.subjects s where s.id = v_plan.subject_id),
    'level',    (select l.code from public.levels l where l.id = v_plan.level_id),
    'next',     v_next,
    'plan_id',  v_plan.id,
    'last',     v_last,
    'open',     v_open,
    'pending',  v_pend,
    'students', (select count(*) from public.students s
                  where s.class_id = p_class_id and s.is_active));
end $function$;

CREATE OR REPLACE FUNCTION public.rpc_home(p_account uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
declare
  v_acc  uuid := app.pick_account(p_account);
  v_paid boolean := app.has_active_subscription(v_acc);
begin
  return jsonb_build_object(
    --  194: ev tapsirigi siqnallari - son tarixi bu gun ve ya kecmis, hele
    --  etmeyen var.  Abuneden asili DEYIL (ev tapsirigi pulsuzdur).
    'hw_alerts', coalesce((
      select jsonb_agg(x order by x->>'due', x->>'class')
        from (select jsonb_build_object(
                       'id', h.id, 'body', h.body, 'due', h.due,
                       'class_id', h.class_id, 'class', c.name,
                       'personal', h.student_id is not null,
                       'undone', (select count(*) from public.students s
                                   where s.class_id = h.class_id and s.is_active
                                     and (h.student_id is null or h.student_id = s.id)
                                     and not exists (select 1 from public.homework_done hd
                                                      where hd.homework_id = h.id and hd.student_id = s.id)),
                       'total', case when h.student_id is not null then 1
                                else (select count(*) from public.students s where s.class_id = h.class_id and s.is_active) end) as x
                from public.homework h
                join public.classes c on c.id = h.class_id
               where c.account_id = v_acc
                 and h.due is not null
                 and h.due <= (now() at time zone 'Asia/Baku')::date
                 and h.due >= (now() at time zone 'Asia/Baku')::date - 14
                 and exists (select 1 from public.students s
                              where s.class_id = h.class_id and s.is_active
                                and (h.student_id is null or h.student_id = s.id)
                                and not exists (select 1 from public.homework_done hd
                                                 where hd.homework_id = h.id and hd.student_id = s.id))
               limit 8) z), '[]'::jsonb),
    'paid', v_paid,

    'stats', jsonb_build_object(
      'groups',   (select count(*) from public.classes c
                    where c.account_id = v_acc),
      --  diaqnostik testler (118) sayilmir: onlari sistem yigir,
      --  "oz testiniz" kartinda muellimi casdirirdi
      'tests',    (select count(*) from public.tests t
                    where t.owner_type = 'educator'
                      and not t.is_diagnostic
                      and t.owner_id in (select user_id from public.account_members
                                          where account_id = v_acc)),
      'students', (select count(*) from public.students s
                    where s.account_id = v_acc and s.is_active),
      'attempts', (select count(*) from public.attempts a
                    join public.students s on s.id = a.student_id
                   where s.account_id = v_acc and a.status = 'submitted'),
      'avg',      (select round(coalesce(avg(a.percent), 0), 0)
                     from public.attempts a
                     join public.students s on s.id = a.student_id
                    where s.account_id = v_acc and a.status = 'submitted')),

    --  Tehluke zonasi - hesabin BUTUN qruplari uzre, risk birinci.
    --  Qaydalar 18_siqnal.sql-dekiler ile eynidir.
    'alerts', case when not v_paid then null else coalesce((
      with att as (
        select a.student_id, a.percent,
               row_number() over (partition by a.student_id
                                  order by a.finished_at desc) rn
          from public.attempts a
          join public.students s on s.id = a.student_id
         where s.account_id = v_acc and s.is_active
           and a.status = 'submitted'
      ),
      st as (
        select student_id, count(*) n,
               round(avg(percent) filter (where rn <= 3), 1)          last3,
               min(percent)       filter (where rn <= 3)              last3min,
               round(avg(percent) filter (where rn between 4 and 6), 1) prev3,
               count(*)           filter (where rn between 4 and 6)   prevn
          from att group by student_id
      ),
      wt as (
        select distinct on (x.student_id) x.*
          from (
            select a.student_id, t.id topic_id, t.name topic,
                   round(count(*) filter (where aa.is_correct) * 100.0
                         / count(*), 0) ratio
              from public.attempt_answers aa
              join public.attempts a  on a.id = aa.attempt_id
                                     and a.status = 'submitted'
              join public.students s2 on s2.id = a.student_id
                                     and s2.account_id = v_acc and s2.is_active
              join public.topics t    on t.id = aa.topic_id
             group by a.student_id, t.id, t.name
            having count(*) >= app.alert_weak_min()
               and count(*) filter (where aa.is_correct) * 100.0
                   / count(*) < app.alert_weak_pct()
          ) x
         order by x.student_id, x.ratio
      ),
      j as (
        select s.id, s.full_name, s.class_id, c.name class_name,
               case
                 when st.n >= app.alert_min_n() and st.prevn >= 2
                      and st.prev3 - st.last3 >= app.alert_drop() then 'risk'
                 when wt.topic_id is not null                     then 'weak'
                 when st.n >= 3 and st.last3min >= app.alert_star() then 'star'
               end kind,
               st.last3, st.prev3, wt.topic_id, wt.topic, wt.ratio
          from public.students s
          join public.classes c on c.id = s.class_id
          join st on st.student_id = s.id
          left join wt on wt.student_id = s.id
         where s.account_id = v_acc and s.is_active
      )
      select jsonb_agg(jsonb_build_object(
               'kind', kind, 'student_id', id, 'name', full_name,
               'class_id', class_id, 'class', class_name,
               'last3', last3, 'prev3', prev3,
               'topic_id', topic_id, 'topic', topic, 'topic_ratio', ratio)
             order by case kind when 'risk' then 1 when 'weak' then 2 else 3 end,
                      full_name)
        from (select * from j where kind is not null limit 8) z), '[]'::jsonb) end,

    --  En yaxsi sagirdler (163): orta bala gore ilk 5.
    --  EN AZI 3 test sertdir - bir defe 100% yazan sagird siyahini
    --  basina kecib yalan siralama vermesin.  Dayandirilmis sagird
    --  sayilmir.  Abunesiz hesabda da gorunur (siqnallardan ferqli):
    --  burada gizli analiz yoxdur, sadece oz sagirdlerinin balidir.
    --  167: siralama HER QRUPUN ICINDE.  Evvel butun hesab uzre tek
    --  siyahi idi - 3-cu sinif qrupu ile 11-ci sinif DIM qrupu yan-yana
    --  dusurdu.  Onlar ferqli test yazir, ona gore "89% vs 77%"
    --  riyazi duzgun, MENACA bos idi (istifadeci).  Indi her qrupun
    --  oz ilk 5-i qaytarilir, panel cip ile birini gosterir.
    --  Qrupsuz sagird siyahida yoxdur - muqayise uchun konteksti yoxdur.
    'top', coalesce((
      select jsonb_agg(jsonb_build_object(
               'student_id', id, 'name', full_name,
               'class_id', class_id, 'class', class_name,
               'attempts', n, 'avg', avg_pct)
             order by class_name, avg_pct desc, n desc, full_name)
        from (
          select s.id, s.full_name, s.class_id, c.name class_name,
                 count(*) n, round(avg(a.percent), 0) avg_pct,
                 row_number() over (
                   partition by s.class_id
                   order by round(avg(a.percent), 0) desc,
                            count(*) desc, s.full_name) rn
            from public.attempts a
            join public.students s on s.id = a.student_id
            join public.classes c on c.id = s.class_id
           where s.account_id = v_acc and s.is_active
             and a.status = 'submitted'
           group by s.id, s.full_name, s.class_id, c.name
          having count(*) >= 3
        ) z
       where rn <= 5), '[]'::jsonb),

    --  Son neticeler lenti
    'recent', coalesce((
      select jsonb_agg(r order by r->>'at' desc)
      from (
        select jsonb_build_object(
                 'at',      a.finished_at,
                 'student', s.display_name,
                 'test',    t.title,
                 'class',   c.name,
                 'class_id', c.id,
                 'percent', round(a.percent, 0)) as r
          from public.attempts a
          join public.students s on s.id = a.student_id
                                and s.account_id = v_acc
          left join public.classes c on c.id = s.class_id
          join public.tests t on t.id = a.test_id
         where a.status = 'submitted'
         order by a.finished_at desc
         --  qrup cipleri ile suzulur - suzgecden sonra da dolu qalsin
         limit 20
      ) z), '[]'::jsonb));
end $function$;
