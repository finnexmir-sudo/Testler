-- =====================================================================
--  921 : AILE YOLU - HEFTELIK HEDEF + gundelik vaxti deyismek (2026-10-06)
--
--  Evvel «Hedef 4 gun» sabit idi.  Indi:
--   * hedef (gun/hefte) usagin gundelik vaxtindan gelir: 5 dəq -> 5, 10 -> 5, 15 -> 4, 20 -> 4, 30 -> 3
--     (az vaxt = tez-tez, cox vaxt = az gun); valideyn 2-7 arasi deyise biler (goal_days);
--   * valideyn «Hedef»den gundelik vaxti ve hedefi bir yerde deyisir (rpc_family_set_plan);
--     vaxt deyiseni bu gunun hazir paketine tesir etmir - sabahdan;
--   * usaq «Menim heftem»de «2 / 4 gun» ve hedef dolanda tebrik gorur (rpc_student_family);
--   * heftelik xulase push «Lale: 3/4 gun, 40 sual …» yazir.
--  Gun «calisdi» sayilir: o gun en azi 1 sual cavablanib (915 ile eyni).
--  ON SERT: 913-920.   Tekrar isledile biler.
-- =====================================================================

alter table public.family_kids add column if not exists goal_days smallint;
alter table public.family_kids drop constraint if exists family_kids_goal_days_check;
alter table public.family_kids add constraint family_kids_goal_days_check check (goal_days is null or goal_days between 2 and 7);

create or replace function app.family_goal(p_minutes int, p_goal smallint)
returns int
language sql immutable as $$
  select coalesce(p_goal::int, case coalesce(p_minutes, 10) when 5 then 5 when 10 then 5 when 15 then 4 when 20 then 4 when 30 then 3 else 4 end)
$$;
revoke all on function app.family_goal(int, smallint) from public, anon, authenticated;

create or replace function public.rpc_family_set_plan(p_student uuid, p_minutes int, p_days int)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_acc uuid;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  v_acc := app.family_account(v_uid);
  if v_acc is null or not exists (select 1 from public.students st
                                   join public.family_kids fk on fk.student_id = st.id
                                  where st.id = p_student and st.account_id = v_acc and st.is_active) then
    raise exception 'Uşaq tapılmadı.' using errcode = '22023';
  end if;
  if p_minutes is null or p_minutes not in (5, 10, 15, 20, 30) then
    raise exception 'Gündəlik vaxtı seçin.' using errcode = '22023';
  end if;
  if p_days is null or p_days < 2 or p_days > 7 then
    raise exception 'Həftəlik hədəf 2–7 gün arasında olmalıdır.' using errcode = '22023';
  end if;
  update public.family_kids set minutes = p_minutes, goal_days = p_days::smallint where student_id = p_student;
  return jsonb_build_object('ok', true, 'minutes', p_minutes, 'goal', p_days);
end $$;
revoke all on function public.rpc_family_set_plan(uuid, int, int) from public, anon;
grant execute on function public.rpc_family_set_plan(uuid, int, int) to authenticated;

-- ---------------------------------------------------------------------
--  917/920/918-den kopya: progress (goal, minutes), student_family (goal), heftelik push (x/y gun)
-- ---------------------------------------------------------------------
create or replace function public.rpc_family_progress()
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_acc uuid;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  v_acc := app.family_account(v_uid);
  if v_acc is null then
    raise exception 'Əvvəl valideyn hesabı açın.' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', st.id,
             'goal', app.family_goal(fk.minutes, fk.goal_days),
             'minutes', fk.minutes,
             'mastered', (select count(*) from public.topic_mastery m where m.student_id = st.id and m.state = 'mastered'),
             'learning',  (select count(*) from public.topic_mastery m where m.student_id = st.id and m.state = 'learning'),
             'due',       (select count(*) from public.topic_mastery m where m.student_id = st.id and m.state = 'mastered' and m.due_at <= now()),
             'cur', coalesce((
               select jsonb_agg(jsonb_build_object('subject', y.sname, 'chapter', y.cname) order by y.sname)
                 from (select distinct on (p.id) sb.name sname, coalesce(par.name, t.name) cname
                         from public.class_plan_items i
                         join public.class_plans p on p.id = i.plan_id and p.class_id = st.class_id
                         join public.subjects sb on sb.id = p.subject_id
                         join public.topics t on t.id = i.topic_id
                         left join public.topics par on par.id = t.parent_id
                        where i.done_at is not null
                        order by p.id, i.ord desc) y), '[]'::jsonb))
             order by st.created_at)
      from public.students st
      join public.family_kids fk on fk.student_id = st.id
     where st.account_id = v_acc and st.is_active), '[]'::jsonb);
end $$;

create or replace function public.rpc_student_family(p_token text)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_st    uuid := app.session_student(p_token);
  v_today date := (now() at time zone 'Asia/Baku')::date;
  v_mon   date;
  v_min   int;
  v_goal  int;
  v_cls   uuid;
  v_out   jsonb;
begin
  if v_st is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;
  select fk.minutes, st.class_id, app.family_goal(fk.minutes, fk.goal_days) into v_min, v_cls, v_goal
    from public.family_kids fk join public.students st on st.id = fk.student_id
   where fk.student_id = v_st;
  if not found then
    return jsonb_build_object('family', false);
  end if;
  v_mon := v_today - (extract(isodow from v_today)::int - 1);

  with ev as (
    select (aa.answered_at at time zone 'Asia/Baku')::date as d
      from public.attempt_answers aa join public.attempts a on a.id = aa.attempt_id
     where a.student_id = v_st and aa.answered_at >= v_mon - 1
    union all
    select dp.day from public.daily_packs dp
     where dp.student_id = v_st and dp.day >= v_mon and jsonb_array_length(dp.answers) > 0
  )
  select jsonb_build_object(
           'family', true,
           'minutes', coalesce(v_min, 10),
           'goal', v_goal,
           'today_i', v_today - v_mon,
           'week', (select jsonb_agg(case when exists (select 1 from ev where ev.d = v_mon + g) then 1 else 0 end order by g)
                      from generate_series(0, 6) g),
           'mastered', (select count(*) from public.topic_mastery m where m.student_id = v_st and m.state = 'mastered'),
           'cur', coalesce((
             select jsonb_agg(jsonb_build_object('subject', y.sname, 'chapter', y.cname) order by y.sname)
               from (select distinct on (p.id) sb.name sname, coalesce(par.name, t.name) cname
                       from public.class_plan_items i
                       join public.class_plans p on p.id = i.plan_id and p.class_id = v_cls
                       join public.subjects sb on sb.id = p.subject_id
                       join public.topics t on t.id = i.topic_id
                       left join public.topics par on par.id = t.parent_id
                      where i.done_at is not null
                      order by p.id, i.ord desc) y), '[]'::jsonb))
    into v_out;
  return v_out;
end $$;

create or replace function app.push_scan_weekly(p_now timestamptz default now()) returns int
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  r      record;
  k      record;
  v_n    int := 0;
  v_id   bigint;
  v_h    int  := extract(hour from (p_now at time zone 'Asia/Baku'))::int;
  v_day  date := (p_now at time zone 'Asia/Baku')::date;
  v_mon  date := ((p_now at time zone 'Asia/Baku')::date) - (extract(isodow from (p_now at time zone 'Asia/Baku'))::int - 1);
  v_from timestamptz;
  v_body text;
  v_part text;
  v_days int; v_q int; v_ok int; v_ms int;
begin
  if not app.push_on() then return 0; end if;
  if extract(isodow from (p_now at time zone 'Asia/Baku')) <> 7 or v_h < 18 or v_h >= 21 then return 0; end if;
  v_from := (v_mon::timestamp) at time zone 'Asia/Baku';

  --  hesab basina bir setir: usaqlari var ve bu cihazlar valideyn bildirisi acib
  for r in
    select st.account_id as acc, (array_agg(st.id order by st.created_at))[1] as first_sid
      from public.students st
      join public.family_kids fk on fk.student_id = st.id
     where st.is_active
       and exists (select 1 from public.push_subs s where s.student_id = st.id and s.role = 'parent')
     group by st.account_id
  loop
    begin
      if app.account_locked(r.acc) then continue; end if;
      v_body := '';
      for k in select st.id, st.display_name nm, app.family_goal(fk.minutes, fk.goal_days) goal from public.students st
                 join public.family_kids fk on fk.student_id = st.id
                where st.account_id = r.acc and st.is_active order by st.created_at loop
        select count(distinct e.d), coalesce(sum(e.q), 0), coalesce(sum(e.ok), 0)
          into v_days, v_q, v_ok
          from (
            select (aa.answered_at at time zone 'Asia/Baku')::date d, 1 q, case when aa.is_correct then 1 else 0 end ok
              from public.attempt_answers aa join public.attempts a on a.id = aa.attempt_id
             where a.student_id = k.id and aa.answered_at >= v_from and aa.answered_at < v_from + interval '7 days'
            union all
            select dp.day, jsonb_array_length(dp.answers),
                   (select count(*) from jsonb_array_elements(dp.answers) x where (x->>'ok')::boolean)::int
              from public.daily_packs dp
             where dp.student_id = k.id and dp.day >= v_mon and dp.day < v_mon + 7 and jsonb_array_length(dp.answers) > 0
          ) e where e.q > 0;
        select count(*) into v_ms from public.topic_mastery m
         where m.student_id = k.id and m.state = 'mastered' and m.mastered_at >= v_from;
        if v_q = 0 then
          v_part := k.nm || ': bu həftə çalışmayıb';
        else
          v_part := k.nm || ': ' || v_days || '/' || k.goal || ' gün, ' || v_q || ' sual (' || round(v_ok * 100.0 / v_q) || ' % düz)'
                    || case when v_ms > 0 then ', ' || v_ms || ' mövzu mənimsədi' else '' end;
        end if;
        v_body := v_body || case when v_body = '' then '' else '. ' end || v_part;
      end loop;
      if v_body = '' then continue; end if;

      v_id := app.push_enqueue('parent', r.first_sid, 'hefte', 'hefte:' || r.acc || ':' || v_mon,
                               'Həftənin xülasəsi', v_body || '.', null, 5);
      if v_id is not null then v_n := v_n + 1; end if;
    exception when others then
      raise warning 'push heftelik: % (%)', sqlerrm, sqlstate;
    end;
  end loop;
  return v_n;
end $$;

revoke all on function public.rpc_family_progress() from public, anon;
grant execute on function public.rpc_family_progress() to authenticated;
revoke all on function public.rpc_student_family(text) from public;
grant execute on function public.rpc_student_family(text) to anon, authenticated;
revoke all on function app.push_scan_weekly(timestamptz) from public, anon, authenticated;
