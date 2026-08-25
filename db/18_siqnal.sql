-- =====================================================================
--  18_siqnal.sql : TEHLUKE ZONASI - qrup ekraninda proaktiv siqnallar
--
--  Muellim qrupa girende sistem OZU deyir:
--    qirmizi  "Saleh son testlerde gerileyir (85% -> 55%),
--              zeif movzu: Metn meseleleri"
--    yasil    "Aysu 3 testdir 90%+ saxlayir"
--
--  QAYDALAR (az melumatda SUSUR - yalan siqnal inami oldurur):
--    gerileme: en az 4 bitmis test VE evvelki pencerede en az 2 test;
--              son 3-un ortasi evvelki 3-un ortasindan
--              app.alert_drop() bend asagi
--    zeif movzu: hemin sagirdin movzuda en az app.alert_weak_min()
--              cavabi var VE dogru nisbeti app.alert_weak_pct()-den asagi
--    ulduz:    en az 3 bitmis test, son 3-un HAMISI app.alert_star()+
--
--  Siqnallar ABUNE analitikasinin hissesidir - pulsuz hesabda
--  funksiya alerts=null qaytarir (frontend upsell gosterir).
--
--  ON SERT: 01_schema.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
--  Tekrar isledile biler.
-- =====================================================================

do $$
begin
  if to_regclass('public.attempts') is null then
    raise exception 'ONCE 01_schema.sql isledilmelidir.';
  end if;
end $$;

-- Heddler ayri funksiyalarda - testler ve senedler eyni menbeden oxusun
create or replace function app.alert_drop() returns numeric
language sql immutable as $$ select 10::numeric $$;

create or replace function app.alert_min_n() returns int
language sql immutable as $$ select 4 $$;

create or replace function app.alert_star() returns numeric
language sql immutable as $$ select 90::numeric $$;

create or replace function app.alert_weak_pct() returns numeric
language sql immutable as $$ select 60::numeric $$;

create or replace function app.alert_weak_min() returns int
language sql immutable as $$ select 5 $$;

create or replace function public.rpc_class_alerts(p_class_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid   uuid := auth.uid();
  v_class public.classes%rowtype;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  select * into v_class from public.classes where id = p_class_id;
  if not found then
    raise exception 'Qrup tapilmadi.' using errcode = '22023';
  end if;
  if v_class.teacher_id <> v_uid
     and not app.is_account_member(v_class.account_id)
     and not app.is_admin() then
    raise exception 'Bu qrupun hesabatina giris huququnuz yoxdur.' using errcode = '42501';
  end if;

  if not app.has_active_subscription(v_class.account_id) then
    return jsonb_build_object('paid', false, 'alerts', null);
  end if;

  return jsonb_build_object('paid', true, 'alerts', coalesce((
    with att as (
      select a.student_id, a.percent,
             row_number() over (partition by a.student_id
                                order by a.finished_at desc) rn
        from public.attempts a
        join public.students s on s.id = a.student_id
       where s.class_id = p_class_id and s.is_active
         and a.status = 'submitted'
    ),
    st as (
      select student_id,
             count(*)                                              n,
             round(avg(percent) filter (where rn <= 3), 1)         last3,
             min(percent)       filter (where rn <= 3)             last3min,
             round(avg(percent) filter (where rn between 4 and 6), 1) prev3,
             count(*)           filter (where rn between 4 and 6)  prevn
        from att group by student_id
    ),
    --  Her sagirdin EN ZEIF movzusu (sagird uzre bir setir)
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
                                   and s2.class_id = p_class_id and s2.is_active
            join public.topics t    on t.id = aa.topic_id
           group by a.student_id, t.id, t.name
          having count(*) >= app.alert_weak_min()
             and count(*) filter (where aa.is_correct) * 100.0
                 / count(*) < app.alert_weak_pct()
        ) x
       order by x.student_id, x.ratio
    ),
    j as (
      select s.id, s.full_name,
             case
               when st.n >= app.alert_min_n() and st.prevn >= 2
                    and st.prev3 - st.last3 >= app.alert_drop() then 'risk'
               when wt.topic_id is not null                     then 'weak'
               when st.n >= 3 and st.last3min >= app.alert_star() then 'star'
             end kind,
             st.last3, st.prev3, wt.topic_id, wt.topic, wt.ratio
        from public.students s
        join st on st.student_id = s.id
        left join wt on wt.student_id = s.id
       where s.class_id = p_class_id and s.is_active
    )
    select jsonb_agg(jsonb_build_object(
             'kind', kind, 'student_id', id, 'name', full_name,
             'last3', last3, 'prev3', prev3,
             'topic_id', topic_id, 'topic', topic, 'topic_ratio', ratio)
           order by case kind when 'risk' then 1 when 'weak' then 2 else 3 end,
                    full_name)
      from j where kind is not null), '[]'::jsonb));
end $$;

-- ---------------------------------------------------------------- huquq
revoke all on function public.rpc_class_alerts(uuid) from public, anon;
grant execute on function public.rpc_class_alerts(uuid) to authenticated;

do $$
begin
  if not has_function_privilege('authenticated',
       'public.rpc_class_alerts(uuid)', 'EXECUTE') then
    raise exception 'muellim siqnallari oxuya bilmir';
  end if;
  if has_function_privilege('anon', 'public.rpc_class_alerts(uuid)', 'EXECUTE') then
    raise exception 'anon siqnallari oxuya bilir - sagird melumati sizir';
  end if;
  raise notice 'Siqnallar quruldu.';
end $$;
