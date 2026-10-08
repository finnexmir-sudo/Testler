-- =====================================================================
--  923 : AILE YOLU - valideynə istisna esasli bildirisler (2026-10-06)
--
--  Her gun xulase YOX (bildiris yorgunlugu) - yalniz valideynin bilmesi lazim olan an:
--   1. «Lale bu gun hele calismayib» - axsam (Baki 19:00-21:00, saatlıq tick 19:05-de tutur),
--      YALNIZ usaq o gun heç bir sual cavablamayibsa; usaq elave edildiyi gun gonderilmir;
--      bir hesaba bir bildiris (bir nece usaq varsa adlar birlikde).
--   2. «Lale bu heftenin hedefini tamamladi» - hedefe catan an (hefte basina usaq basina bir defe),
--      «Aferin gonder» teklifi ile.
--  Sakit saatlar (21:00-10:00) dayismir.  Valideyn «Ailem»den hər ikisini ayrica sondure biler
--  (family_prefs: hesab seviyyesinde; defolt hamisi acıqdır).
--  Heftelik xulase (918) ayridir.  ON SERT: 910-922.   Tekrar isledile biler.
-- =====================================================================

create table if not exists public.family_prefs (
  account_id uuid primary key references public.accounts(id) on delete cascade,
  nostudy    boolean not null default true,
  goal       boolean not null default true,
  updated_at timestamptz not null default now()
);
alter table public.family_prefs enable row level security;
revoke all on public.family_prefs from public, anon, authenticated;

create or replace function public.rpc_family_push_prefs_get()
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
  return jsonb_build_object(
    'nostudy', coalesce((select p.nostudy from public.family_prefs p where p.account_id = v_acc), true),
    'goal',    coalesce((select p.goal    from public.family_prefs p where p.account_id = v_acc), true));
end $$;
revoke all on function public.rpc_family_push_prefs_get() from public, anon;
grant execute on function public.rpc_family_push_prefs_get() to authenticated;

create or replace function public.rpc_family_push_prefs_set(p_nostudy boolean, p_goal boolean)
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
  if v_acc is null then
    raise exception 'Əvvəl valideyn hesabı açın.' using errcode = '42501';
  end if;
  insert into public.family_prefs (account_id, nostudy, goal)
  values (v_acc, coalesce(p_nostudy, true), coalesce(p_goal, true))
  on conflict (account_id) do update set nostudy = excluded.nostudy, goal = excluded.goal, updated_at = now();
  return jsonb_build_object('ok', true, 'nostudy', coalesce(p_nostudy, true), 'goal', coalesce(p_goal, true));
end $$;
revoke all on function public.rpc_family_push_prefs_set(boolean, boolean) from public, anon;
grant execute on function public.rpc_family_push_prefs_set(boolean, boolean) to authenticated;

-- ------------------------------------------------ 1 · «bu gun hele calismayib»
create or replace function app.push_scan_family_nostudy(p_now timestamptz default now()) returns int
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  r       record;
  k       record;
  v_n     int := 0;
  v_id    bigint;
  v_h     int  := extract(hour from (p_now at time zone 'Asia/Baku'))::int;
  v_day   date := (p_now at time zone 'Asia/Baku')::date;
  v_names text[];
  v_body  text;
begin
  if not app.push_on() then return 0; end if;
  if v_h < 19 or v_h >= 21 then return 0; end if;

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
      if not app.has_active_subscription(r.acc) then continue; end if;
      if not coalesce((select p.nostudy from public.family_prefs p where p.account_id = r.acc), true) then continue; end if;
      v_names := '{}';
      for k in select st.id, st.display_name nm, st.created_at
                 from public.students st join public.family_kids fk on fk.student_id = st.id
                where st.account_id = r.acc and st.is_active order by st.created_at loop
        continue when (k.created_at at time zone 'Asia/Baku')::date = v_day;      -- bu gun elave olunub: tezdir
        continue when exists (select 1 from public.attempt_answers aa join public.attempts a on a.id = aa.attempt_id
                               where a.student_id = k.id and (aa.answered_at at time zone 'Asia/Baku')::date = v_day)
                   or exists (select 1 from public.daily_packs dp
                               where dp.student_id = k.id and dp.day = v_day and jsonb_array_length(dp.answers) > 0);
        v_names := v_names || k.nm;
      end loop;
      if cardinality(v_names) = 0 then continue; end if;
      v_body := array_to_string(v_names, ' və ') ||
                case when cardinality(v_names) = 1 then ' bu gün hələ çalışmayıb.' else ' bu gün hələ çalışmayıblar.' end ||
                ' Bir neçə dəqiqəlik məşqə həvəsləndirin.';
      v_id := app.push_enqueue('parent', r.first_sid, 'bugun_yox', 'yox:' || r.acc || ':' || v_day,
                               'Bu gün hələ çalışmayıb', v_body, './valideyn/?aile=1', 5);
      if v_id is not null then v_n := v_n + 1; end if;
    exception when others then
      raise warning 'push bugun yox: % (%)', sqlerrm, sqlstate;
    end;
  end loop;
  return v_n;
end $$;
revoke all on function app.push_scan_family_nostudy(timestamptz) from public, anon, authenticated;

-- ------------------------------------------------ 2 · hedef tamamlandi
create or replace function app.push_scan_family_goal(p_now timestamptz default now()) returns int
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  r      record;
  k      record;
  v_n    int := 0;
  v_id   bigint;
  v_day  date := (p_now at time zone 'Asia/Baku')::date;
  v_mon  date := ((p_now at time zone 'Asia/Baku')::date) - (extract(isodow from (p_now at time zone 'Asia/Baku'))::int - 1);
  v_from timestamptz;
  v_days int;
begin
  if not app.push_on() then return 0; end if;
  v_from := (v_mon::timestamp) at time zone 'Asia/Baku';

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
      if not app.has_active_subscription(r.acc) then continue; end if;
      if not coalesce((select p.goal from public.family_prefs p where p.account_id = r.acc), true) then continue; end if;
      for k in select st.id, st.display_name nm, app.family_goal(fk.minutes, fk.goal_days) goal
                 from public.students st join public.family_kids fk on fk.student_id = st.id
                where st.account_id = r.acc and st.is_active order by st.created_at loop
        select count(distinct e.d) into v_days from (
          select (aa.answered_at at time zone 'Asia/Baku')::date d
            from public.attempt_answers aa join public.attempts a on a.id = aa.attempt_id
           where a.student_id = k.id and aa.answered_at >= v_from and aa.answered_at < v_from + interval '7 days'
          union all
          select dp.day from public.daily_packs dp
           where dp.student_id = k.id and dp.day >= v_mon and dp.day < v_mon + 7 and jsonb_array_length(dp.answers) > 0
        ) e;
        if v_days >= k.goal then
          v_id := app.push_enqueue('parent', r.first_sid, 'hedef', 'hedef:' || k.id || ':' || v_mon,
                                   'Həftənin hədəfi tamamlandı 🎉',
                                   k.nm || ' bu həftənin hədəfini tamamladı (' || v_days || ' / ' || k.goal || ' gün). «Afərin göndər» ilə təbrik edə bilərsiniz.',
                                   './valideyn/?aile=1', 5);
          if v_id is not null then v_n := v_n + 1; end if;
        end if;
      end loop;
    exception when others then
      raise warning 'push hedef: % (%)', sqlerrm, sqlstate;
    end;
  end loop;
  return v_n;
end $$;
revoke all on function app.push_scan_family_goal(timestamptz) from public, anon, authenticated;

-- ------------------------------------------------ saatlig planlayici (918-den + 2 yeni)
create or replace function app.push_tick() returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_d int := 0;
  v_g int := 0;
  v_w int := 0;
  v_y int := 0;
  v_h int := 0;
begin
  if not app.push_on() then return jsonb_build_object('on', false); end if;
  begin v_d := app.push_scan_deadlines();      exception when others then raise warning 'push tick son tarix: %', sqlerrm; end;
  begin v_g := app.push_scan_daily();          exception when others then raise warning 'push tick gundelik: %', sqlerrm; end;
  begin v_w := app.push_scan_weekly();         exception when others then raise warning 'push tick heftelik: %', sqlerrm; end;
  begin v_y := app.push_scan_family_nostudy(); exception when others then raise warning 'push tick bugun yox: %', sqlerrm; end;
  begin v_h := app.push_scan_family_goal();    exception when others then raise warning 'push tick hedef: %', sqlerrm; end;
  begin perform app.push_cleanup();            exception when others then raise warning 'push tick temizlik: %', sqlerrm; end;
  return jsonb_build_object('on', true, 'son_tarix', v_d, 'gundelik', v_g, 'heftelik', v_w, 'bugun_yox', v_y, 'hedef', v_h);
end $$;
revoke all on function app.push_tick() from public, anon, authenticated;
