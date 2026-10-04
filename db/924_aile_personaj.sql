-- =====================================================================
--  924 : AILE YOLU - personaj («Tumurcuq»), zencir, nisanlar, valideynin mukafati (2026-10-06)
--
--  Hamisi USAGA ozeldir - hec bir melumat basqasina getmir (yarisi/reytinq YOXDUR, qerar 06.10).
--   * personaj mərhələsi cəmi calisdigi gunlerden (days_total) cixir: 0 toxum · 3 cucerti · 7 bitki · 14 agac · 30 cicekli agac;
--     MƏRHƏLƏ HEC VAXT GERI GETMIR (calismayanda cəza yoxdur - «seni gozleyirem»);
--   * zencir: ardicil calisdigi gunler, BIR gun buraxmaq zənciri pozmur (aralıq <=2 gun);
--   * 7 nisan: ilk gun, 3/7 gun ardicil, ilk movzu, 5 movzu, 100 sual, hedef heftesi (hesablanir, cedvel yoxdur);
--   * valideyn «Gundelik mesq -> deyis»de mukafat yaza biler (<=80 simvol): hedef dolanda usaq gorur.
--  rpc_student_family: days_total, streak, best_streak, answers_total, badges, reward.
--  rpc_family_progress: reward.   rpc_family_set_reward(usaq, metn).
--  ON SERT: 913-923.   Tekrar isledile biler.
-- =====================================================================

alter table public.family_kids add column if not exists reward text;
alter table public.family_kids drop constraint if exists family_kids_reward_check;
alter table public.family_kids add constraint family_kids_reward_check check (reward is null or length(reward) <= 80);

create or replace function public.rpc_family_set_reward(p_student uuid, p_text text)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_acc uuid;
  v_t   text := nullif(btrim(regexp_replace(coalesce(p_text, ''), '[[:cntrl:]]+', ' ', 'g')), '');
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
  if v_t is not null and length(v_t) > 80 then
    raise exception 'Mükafat mətni ən çox 80 simvol ola bilər.' using errcode = '22023';
  end if;
  update public.family_kids set reward = v_t where student_id = p_student;
  return jsonb_build_object('ok', true, 'reward', v_t);
end $$;
revoke all on function public.rpc_family_set_reward(uuid, text) from public, anon;
grant execute on function public.rpc_family_set_reward(uuid, text) to authenticated;

-- ---------------------------------------------------------------------
--  usagin oz sehifesi (920/921-den genisletilib)
-- ---------------------------------------------------------------------
create or replace function public.rpc_student_family(p_token text)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_st      uuid := app.session_student(p_token);
  v_today   date := (now() at time zone 'Asia/Baku')::date;
  v_mon     date;
  v_min     int;
  v_goal    int;
  v_reward  text;
  v_cls     uuid;
  v_total   int;
  v_best    int;
  v_cur     int;
  v_answers int;
  v_gweeks  int;
  v_mast    int;
  v_out     jsonb;
begin
  if v_st is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;
  select fk.minutes, st.class_id, app.family_goal(fk.minutes, fk.goal_days), fk.reward
    into v_min, v_cls, v_goal, v_reward
    from public.family_kids fk join public.students st on st.id = fk.student_id
   where fk.student_id = v_st;
  if not found then
    return jsonb_build_object('family', false);
  end if;
  v_mon := v_today - (extract(isodow from v_today)::int - 1);

  --  butun calisdigi gunler (testler + gundelik paket); zencir: aralıq <=2 gun (bir gun buraxmaq pozmur)
  with days as (
    select distinct d from (
      select (aa.answered_at at time zone 'Asia/Baku')::date as d
        from public.attempt_answers aa join public.attempts a on a.id = aa.attempt_id
       where a.student_id = v_st
      union all
      select dp.day from public.daily_packs dp
       where dp.student_id = v_st and jsonb_array_length(dp.answers) > 0
    ) x
  ), ordered as (
    select d, lag(d) over (order by d) as prev from days
  ), grp as (
    select d, sum(case when prev is null or d - prev > 2 then 1 else 0 end) over (order by d) as g from ordered
  ), runs as (
    select g, count(*)::int as n, max(d) as last_d from grp group by g
  )
  select (select count(*) from days),
         coalesce((select max(n) from runs), 0),
         coalesce((select n from runs where last_d >= v_today - 2 order by last_d desc limit 1), 0),
         (select count(*) from (select date_trunc('week', d::timestamp) w, count(*) c from days group by 1) q where q.c >= v_goal)
    into v_total, v_best, v_cur, v_gweeks;

  select (select count(*) from public.attempt_answers aa join public.attempts a on a.id = aa.attempt_id where a.student_id = v_st)
         + coalesce((select sum(jsonb_array_length(dp.answers)) from public.daily_packs dp where dp.student_id = v_st), 0)
    into v_answers;
  select count(*) into v_mast from public.topic_mastery m where m.student_id = v_st and m.state = 'mastered';

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
           'reward', v_reward,
           'today_i', v_today - v_mon,
           'week', (select jsonb_agg(case when exists (select 1 from ev where ev.d = v_mon + g) then 1 else 0 end order by g)
                      from generate_series(0, 6) g),
           'mastered', v_mast,
           'days_total', v_total,
           'streak', v_cur,
           'best_streak', v_best,
           'answers_total', v_answers,
           'badges', jsonb_build_array(
             jsonb_build_object('k', 'first', 't', 'İlk gün',          'd', 'İlk dəfə çalışdın',                'on', v_total >= 1),
             jsonb_build_object('k', 's3',    't', '3 gün ardıcıl',    'd', '3 gün ardıcıl çalışdın',           'on', v_best >= 3),
             jsonb_build_object('k', 's7',    't', '7 gün ardıcıl',    'd', '7 gün ardıcıl çalışdın',           'on', v_best >= 7),
             jsonb_build_object('k', 'm1',    't', 'İlk mövzu',        'd', 'Bir mövzunu mənimsədin',           'on', v_mast >= 1),
             jsonb_build_object('k', 'm5',    't', '5 mövzu',          'd', '5 mövzunu mənimsədin',             'on', v_mast >= 5),
             jsonb_build_object('k', 'q100',  't', '100 sual',         'd', '100 sual həll etdin',              'on', v_answers >= 100),
             jsonb_build_object('k', 'g1',    't', 'Hədəf həftəsi',    'd', 'Həftəlik hədəfi tamamladın',       'on', v_gweeks >= 1)),
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
revoke all on function public.rpc_student_family(text) from public;
grant execute on function public.rpc_student_family(text) to anon, authenticated;

-- ---------------------------------------------------------------------
--  922-den kopya: rpc_family_progress ('reward' elave)
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
             'reward', fk.reward,
             'praise_n', (select count(*) from public.family_praise fp
                           where fp.student_id = st.id and (fp.at at time zone 'Asia/Baku')::date = (now() at time zone 'Asia/Baku')::date),
             'praise_last', (select to_char(max(fp.at) at time zone 'Asia/Baku', 'HH24:MI') from public.family_praise fp
                              where fp.student_id = st.id and (fp.at at time zone 'Asia/Baku')::date = (now() at time zone 'Asia/Baku')::date),
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

revoke all on function public.rpc_family_progress() from public, anon;
grant execute on function public.rpc_family_progress() to authenticated;
