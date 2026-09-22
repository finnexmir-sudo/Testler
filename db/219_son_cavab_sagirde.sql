--  219: SON CAVAB SETRI SAGIRDE APARSIN
--
--  Yeni «Nəticələr» (#/nt) sehifesinde «Son cavablar» setri sagirdin
--  adini yazir - «Samir Ə. · Vurma cədvəli — 1».  Basilanda ise QRUP
--  hesabati acilirdi: setir bir sey ved edir, basqa sey verirdi.
--  rpc_home.recent artiq 'student_id' de qaytarir.
--
--  Basqa hec ne deyismir: funksiyanin govdesi 216-nin eynidir, ustune
--  bir sahe elave olunub (marker usulu artiq islenmir - tam govde).
set search_path = public, app;

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
    'tekrar_plansiz', (
      --  213: plani olan, amma hec bir dersi «kecildi» isarelenmeyen
      --  qruplardaki aktiv sagird sayi - onlara gundelik tekrar
      --  hazirlana bilmir.
      select count(*) from public.students st
        join public.classes c on c.id = st.class_id and c.account_id = v_acc
       where st.is_active
         and exists (select 1 from public.class_plans cp where cp.class_id = c.id)
         and not exists (select 1 from public.class_plan_items i
                          join public.class_plans cp2 on cp2.id = i.plan_id
                         where cp2.class_id = c.id and i.done_at is not null)),
    'tekrar_qrup', (
      --  hansi qrup - kart birbasa ders plani sekmesine aparir
      select jsonb_build_object('id', c.id, 'name', c.name)
        from public.classes c
       where c.account_id = v_acc
         and exists (select 1 from public.students st
                      where st.class_id = c.id and st.is_active)
         and exists (select 1 from public.class_plans cp where cp.class_id = c.id)
         and not exists (select 1 from public.class_plan_items i
                          join public.class_plans cp2 on cp2.id = i.plan_id
                         where cp2.class_id = c.id and i.done_at is not null)
       order by c.created_at limit 1),
    'tekrar_hazir', (
      --  paketi qurula bilen sagird sayi (en azi bir «kecildi» ders)
      select count(*) from public.students st
        join public.classes c on c.id = st.class_id and c.account_id = v_acc
       where st.is_active
         and exists (select 1 from public.class_plan_items i
                       join public.class_plans cp on cp.id = i.plan_id
                      where cp.class_id = c.id and i.done_at is not null)),
    'bugun', (
      with gun as (
        select (now() at time zone 'Asia/Baku')::date d
      ),
      cehd as (
        select a.student_id,
               (a.finished_at at time zone 'Asia/Baku')::date d
          from public.attempts a
          join public.students s on s.id = a.student_id
         where s.account_id = v_acc and s.is_active and a.status = 'submitted'
           and a.finished_at >= now() - interval '30 days'
      )
      select jsonb_build_object(
        --  dunen / bu gun nece SAGIRD isledi (cehd sayi yox - adam sayi)
        'dunen',  (select count(distinct student_id) from cehd, gun where cehd.d = gun.d - 1),
        'bu_gun', (select count(distinct student_id) from cehd, gun where cehd.d = gun.d),
        --  7 gundur hec ne etmeyen aktiv sagird
        'susan', (select count(*) from public.students s
                     where s.account_id = v_acc and s.is_active
                       --  216: DUNEN elave olunan sagird «bir heftedir
                       --  susur» sayila bilmez - hele bir hefte olmayib
                       and s.created_at < now() - interval '7 days'
                       and not exists (select 1 from public.attempts a
                                        where a.student_id = s.id and a.status = 'submitted'
                                          and a.finished_at >= now() - interval '7 days')),
        'aktiv', (select count(*) from public.students s
                     where s.account_id = v_acc and s.is_active),
        --  bu gun tapsiriq verilibmi (kart «gonderdiniz» desin)
        'verdim', (select count(*) from public.assignments asg
                      join public.classes c on c.id = asg.class_id
                     where c.account_id = v_acc
                       and (asg.created_at at time zone 'Asia/Baku')::date
                           = (select d from gun)))
    ),
    'topics', case when not v_paid then null else coalesce((
      with per as (
        select a.student_id, s.class_id, s.full_name, t.id topic_id, t.name topic,
               t.subject_id, t.level_id,
               count(*) n, count(*) filter (where aa.is_correct) ok
          from public.attempt_answers aa
          join public.attempts a  on a.id = aa.attempt_id and a.status = 'submitted'
          join public.students s  on s.id = a.student_id
                                 and s.account_id = v_acc and s.is_active
          join public.topics t    on t.id = aa.topic_id
         group by a.student_id, s.class_id, s.full_name, t.id, t.name, t.subject_id, t.level_id
        having count(*) >= app.alert_weak_min()
      ),
      agg as (
        select class_id, topic_id, topic, subject_id, level_id,
               count(*) n_st,
               count(*) filter (where ok * 100.0 / n < app.alert_weak_pct()) n_weak,
               round(avg(ok * 100.0 / n), 0) avg_ratio,
               (select jsonb_agg(jsonb_build_object('id', p2.student_id, 'name', p2.full_name)
                                 order by p2.ok * 100.0 / p2.n)
                  from per p2
                 where p2.class_id = per.class_id and p2.topic_id = per.topic_id
                   and p2.ok * 100.0 / p2.n < app.alert_weak_pct()) weak
          from per
         group by class_id, topic_id, topic, subject_id, level_id
        having count(*) filter (where ok * 100.0 / n < app.alert_weak_pct()) >= 2
            or count(*) filter (where ok * 100.0 / n < app.alert_weak_pct()) * 2 >= count(*)
      )
      select jsonb_agg(jsonb_build_object(
               'class_id', c.id, 'class', c.name,
               'id', g.topic_id, 'name', g.topic,
               'subject_slug', sub.slug, 'level', lv.code,
               'n', g.n_st, 'weak_n', g.n_weak, 'avg', g.avg_ratio, 'weak', g.weak)
             order by g.n_weak desc, g.avg_ratio, c.name, g.topic)
        from (select * from agg order by n_weak desc, avg_ratio limit 6) g
        join public.classes c on c.id = g.class_id
        left join public.subjects sub on sub.id = g.subject_id
        left join public.levels lv on lv.id = g.level_id
    ), '[]'::jsonb) end,

    'stats', jsonb_build_object(
      'tests_w',    (select count(*) from public.tests t
                        where t.owner_type = 'educator'
                          and not t.is_diagnostic
                          and t.created_at >= now() - interval '7 days'
                          and t.owner_id in (select user_id from public.account_members
                                              where account_id = v_acc)),
      'students_w', (select count(*) from public.students s
                        where s.account_id = v_acc and s.is_active
                          and s.created_at >= now() - interval '7 days'),
      'attempts_w', (select count(*) from public.attempts a
                        join public.students s on s.id = a.student_id
                       where s.account_id = v_acc and a.status = 'submitted'
                         and a.finished_at >= now() - interval '7 days'),
      'avg_w',      (select round(avg(a.percent), 0)
                         from public.attempts a
                         join public.students s on s.id = a.student_id
                        where s.account_id = v_acc and a.status = 'submitted'
                          and a.finished_at >= now() - interval '7 days'),
      'avg_pw',     (select round(avg(a.percent), 0)
                         from public.attempts a
                         join public.students s on s.id = a.student_id
                        where s.account_id = v_acc and a.status = 'submitted'
                          and a.finished_at >= now() - interval '14 days'
                          and a.finished_at <  now() - interval '7 days'),
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
                 --  219: setir sagirdin ADINI yazir - basilanda da SAGIRDIN
                 --  hesabati acilmalidir.  Evvel yalniz qrupa aparirdi.
                 'student_id', s.id,
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

revoke all on function public.rpc_home(uuid) from public, anon;
grant execute on function public.rpc_home(uuid) to authenticated;
