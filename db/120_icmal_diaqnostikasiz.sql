-- =====================================================================
--  120  ICMAL: "oz testiniz" sayinda diaqnostik test yoxdur
--
--  UX yoxlamasi: muellim hec test yigmamis Icmalda "1 oz testiniz"
--  gorurdu - o, sistemin yigdigi diaqnostika idi (118).  rpc_home
--  22_esas.sql-deki govde + `not t.is_diagnostic`.
--  Grant deyismir (authenticated).
-- =====================================================================

create or replace function public.rpc_home(p_account uuid default null)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_acc  uuid := app.pick_account(p_account);
  v_paid boolean := app.has_active_subscription(v_acc);
begin
  return jsonb_build_object(
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
end $$;
