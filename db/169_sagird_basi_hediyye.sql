-- =====================================================================
--  169_sagird_basi_hediyye.sql — HEDIYYE = ODENISLI MEHSULUN OZU
--
--  BOSLUQ: 165-de qiymet "sagird basina 1.50 AZN, limit yoxdur" oldu,
--  amma hediyye (160/168) hele de 'repetitor-25' verirdi - 25 sagird
--  yeri ile.  Netice tersine cixirdi: PULSUZ ay ODENISLI mehsuldan
--  daha mehdud idi.  Muellim hediyye ayinda 25-de dayanir, sonra
--  "limitsiz" plana kecirdi.
--
--  QAYDA (istifadeci qerari 2026-09-09):
--    Hediyye ay = odenisli mehsulun eynisi, sadece 0 AZN.
--    Sagird limiti YOXDUR.  Nece sagird elave edirse, novbeti ay
--    onun sayina gore odeyecek - bu bizim xeyrimizedir, mehdudiyyet
--    yalniz muellimi sagird elave etmemeye oyredirdi.
--
--  Bu miqrasiya:
--    1. hediyye_grant  -> 'sagird-basi' (mekteb hesabina 'mekteb')
--    2. kohne pilleli paketler baglanir (repetitor-25/60/acik)
--    3. rpc_admin_grant susmada 'sagird-basi'
--    4. rpc_paket abune sehifesi ucun canli reqemleri qaytarir
--    5. rpc_admin_stats geliri ANBAAN aktiv sagird sayina gore sayir
--       (kohne 's.seats' sutunu sagird basina modelde bosdur)
--
--  MOVCUD ABUNELERE TOXUNULMUR: repetitor-25 uzerinde oturan hesablar
--  islemeye davam edir (account_seat_limit plana is_active suzgeci
--  qoymur), sadece yeni hesaba o paket verilmir.
-- =====================================================================

do $$
begin
  if to_regclass('public.plans') is null then
    raise exception 'ONCE 21_paket.sql isledilmelidir.';
  end if;
  if not exists (select 1 from public.plans where slug = 'sagird-basi') then
    raise exception 'ONCE 165_sagird_basi_qiymet.sql isledilmelidir.';
  end if;
end $$;

-- ---------------------------------------------------------- 1. hediyye
create or replace function app.hediyye_grant(p_account uuid) returns timestamptz
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_cfg  jsonb := app.hediyye_cfg();
  v_type account_type;
  v_plan uuid;
  v_end  timestamptz;
  v_beta date;
begin
  if not coalesce((v_cfg->>'on')::boolean, false) then return null; end if;
  select type into v_type from public.accounts where id = p_account;
  if v_type is null or v_type not in ('tutor','school') then return null; end if;
  if app.has_active_subscription(p_account) then return null; end if;

  --  169: hediyye = odenisli mehsulun ozu (limitsiz), 'repetitor-25' yox
  select id into v_plan from public.plans
   where slug = case when v_type = 'school' then 'mekteb' else 'sagird-basi' end
     and is_active;
  if v_plan is null then return null; end if;

  --  168: 'beta_until' TEKLIFIN son gunudur - kecibse hediyye yoxdur
  v_beta := nullif(v_cfg->>'beta_until', '')::date;
  if v_beta is not null and (now() at time zone 'Asia/Baku')::date > v_beta then
    return null;
  end if;

  --  168: uzunluq HEMISE 'days'-dir (beta tarixine uzanmir)
  v_end := now() + (greatest(coalesce((v_cfg->>'days')::int, 30), 1) || ' days')::interval;

  --  seats: sagird basina planda max_students bosdur, ona gore bu sutun
  --  hedde tesir etmir.  1 qoyulur (sutun not null default 1).
  insert into public.subscriptions
    (account_id, plan_id, status, seats, started_at, current_period_end, provider)
  values (p_account, v_plan, 'trialing', 1, now(), v_end, 'gift');
  return v_end;
end $$;

revoke all on function app.hediyye_grant(uuid) from public, anon, authenticated;

-- ------------------------------------------------- 2. kohne paketler
--  Silmirik - kohne abuneler onlara istinad edir.  Sadece yeni satisdan
--  cixarilir: rpc_paket ve admin secimi yalniz is_active planlari gorur.
update public.plans set is_active = false
 where slug in ('repetitor-25', 'repetitor-60', 'repetitor-acik');

-- --------------------------------------------- 3. admin: susan plan
--  Imza deyismir (yalniz susma qiymeti) - kohne grant-lar qalir.
create or replace function public.rpc_admin_grant(
  p_email text, p_plan text default 'sagird-basi', p_months int default 1,
  p_trial boolean default false)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_acc    uuid;
  v_plan   uuid;
  v_sub    public.subscriptions%rowtype;
  v_end    timestamptz;
  v_status sub_status;
  v_trial  boolean := coalesce(p_trial, false);
begin
  if not app.admin_ok() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;
  if p_months is null or p_months < 1 or p_months > 24 then
    raise exception 'Ay sayi 1-24 araliginda olmalidir.' using errcode = '22023';
  end if;

  select a.id into v_acc
    from public.accounts a
    join auth.users u on u.id = a.owner_id
   where lower(u.email) = lower(btrim(p_email))
   order by a.created_at limit 1;
  if v_acc is null then
    raise exception 'Bu e-poctla hesab tapilmadi: %', p_email using errcode = '22023';
  end if;

  select id into v_plan from public.plans where slug = p_plan and is_active;
  if v_plan is null then
    raise exception 'Plan tapilmadi: %', p_plan using errcode = '22023';
  end if;

  select * into v_sub from public.subscriptions
   where account_id = v_acc and plan_id = v_plan
     and status in ('trialing','active')
   order by current_period_end desc nulls last limit 1;

  if v_sub.id is not null then
    --  sinaq + sinaq = sinaq qalir; odenisli hec vaxt sinaga enmir
    v_status := case when v_trial and v_sub.status = 'trialing'
                     then 'trialing' else 'active' end;
    if v_sub.status = 'trialing' and not v_trial then
      --  sinaq odenisliye kecir: odenisli muddet bu gunden
      v_end := now() + (p_months || ' months')::interval;
    else
      v_end := greatest(coalesce(v_sub.current_period_end, now()), now())
               + (p_months || ' months')::interval;
    end if;
    update public.subscriptions
       set current_period_end = v_end, status = v_status,
           provider = case when v_status = 'trialing' then 'trial' else 'manual' end
     where id = v_sub.id;
  else
    v_status := case when v_trial then 'trialing' else 'active' end;
    v_end := now() + (p_months || ' months')::interval;
    insert into public.subscriptions
      (account_id, plan_id, status, started_at, current_period_end, provider)
    values (v_acc, v_plan, v_status, now(), v_end,
            case when v_trial then 'trial' else 'manual' end);
  end if;

  return jsonb_build_object('ok', true, 'account', v_acc, 'ends', v_end,
                            'trial', v_status = 'trialing');
end $$;

-- ------------------------------------------------ 4. abune sehifesi
--  138-dekinin uzerine.  Elave olunanlar:
--    students · free_limit          : indiki aktiv sagird, pulsuz hedd
--    per_seat_minor · base_minor    : tarif
--    due_minor                      : bu ayin meblegi (server hesablayir)
--    days_left · grace_days         : qalan gun (Baki), guzest
--    gift                           : bu abune hediyyedirmi
--  QAYDA "pul isi - 100 olc, bir bic": meblegi HEMISE server sayir,
--  brauzer yalniz gosterir.
create or replace function public.rpc_paket(p_account uuid default null)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_acc   uuid := app.pick_account(p_account);
  v_type  account_type;
  v_gr    int  := app.grace_days();
  v_bugun date := (now() at time zone 'Asia/Baku')::date;
  v_base  int;
  v_seat  int;
begin
  select type into v_type from public.accounts where id = v_acc;
  if v_type is null then
    raise exception 'Hesab tapilmadi.' using errcode = '22023';
  end if;

  --  Satisda olan qayda (abunesi olmayana da gosterilir).  Mebleg
  --  HEMISE burada sayilir - brauzer vurma emeliyyati aparmir.
  select p.price_minor, p.price_per_seat_minor
    into v_base, v_seat
    from public.plans p
   where p.is_active and p.audience = v_type and p.slug <> 'pulsuz'
   order by p.sort limit 1;

  return jsonb_build_object(
    'students',   app.account_student_count(v_acc),
    'free_limit', app.free_seat_limit(),
    'grace_days', v_gr,
    'base_minor', coalesce(v_base, 0),
    'per_seat_minor', coalesce(v_seat, 0),
    'due_minor', coalesce(v_base, 0)
      + coalesce(v_seat, 0) * app.account_student_count(v_acc),
    'current', case when app.account_is_admin(v_acc) then
      jsonb_build_object('plan', 'Admin — daimi', 'slug', 'admin',
                         'status', 'active', 'ends', null)
    else (
      select jsonb_build_object(
               'plan',   pl.name,
               'slug',   pl.slug,
               'status', s.status,
               'ends',   s.current_period_end,
               'gift',   s.provider = 'gift',
               'base_minor', pl.price_minor,
               'per_seat_minor', pl.price_per_seat_minor,
               'due_minor', pl.price_minor
                 + pl.price_per_seat_minor * app.account_student_count(v_acc),
               'days_left', case when s.current_period_end is null then null
                 else ((s.current_period_end at time zone 'Asia/Baku')::date
                       - v_bugun) end)
        from public.subscriptions s
        join public.plans pl on pl.id = s.plan_id
       where s.account_id = v_acc
         and s.status in ('trialing','active')
         and (s.current_period_end is null
              or s.current_period_end > now() - (v_gr || ' days')::interval)
       order by s.current_period_end desc nulls last
       limit 1) end,
    'plans', coalesce((
      select jsonb_agg(jsonb_build_object(
               'slug', p.slug, 'name', p.name,
               'price_minor', p.price_minor,
               'price_per_seat_minor', p.price_per_seat_minor,
               'max_students', p.max_students,
               'period', p.period,
               'features', p.features) order by p.sort)
        from public.plans p
       where p.is_active and p.audience = v_type and p.slug <> 'pulsuz'),
      '[]'::jsonb));
end $$;

-- ------------------------------------------- 5. admin: aylik gelir
--  Kohne hesab 's.seats' sutunundan gedirdi - pilleli paketlerde o
--  doldurulurdu.  Sagird basina modelde seats bosdur (1), gelir ise
--  ANBAAN aktiv sagird sayina baglidir.  Ona gore hesablanan say
--  istifade olunur.  Yalniz status='active' - hediyye gelir deyil.
create or replace function app.mrr_minor() returns bigint
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select coalesce(sum(pl.price_minor
           + pl.price_per_seat_minor * app.account_student_count(s.account_id)), 0)::bigint
    from public.subscriptions s
    join public.plans pl on pl.id = s.plan_id
    join public.accounts a on a.id = s.account_id
   where s.status = 'active'
     and not a.is_demo
     and not app.account_is_admin(a.id)
     and (s.current_period_end is null or s.current_period_end > now())
$$;

create or replace function public.rpc_admin_stats()
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
begin
  if not app.admin_ok() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;

  return jsonb_build_object(
    --  numune nusxeleri hec bir sayda yoxdur
    'accounts', (select count(*) from public.accounts where not is_demo),
    'accounts_week', (select count(*) from public.accounts
                       where not is_demo
                         and created_at > now() - interval '7 days'),
    'demo_accounts', (select count(*) from public.accounts where is_demo),
    --  pullu = yalniz ODENISLI (active).  Admin sahibli hesab sayilmir.
    'paid_accounts', (select count(distinct s.account_id)
                       from public.subscriptions s
                       join public.accounts a on a.id = s.account_id
                      where s.status = 'active'
                        and not a.is_demo
                        and not app.account_is_admin(a.id)
                        and (s.current_period_end is null
                             or s.current_period_end > now())),
    'trial_accounts', (select count(distinct s.account_id)
                        from public.subscriptions s
                        join public.accounts a on a.id = s.account_id
                       where s.status = 'trialing'
                         and not a.is_demo
                         and not app.account_is_admin(a.id)
                         and (s.current_period_end is null
                              or s.current_period_end > now())),
    'active_subs', (select count(*) from public.subscriptions s
                     join public.accounts a on a.id = s.account_id
                     where s.status = 'active'
                       and not a.is_demo
                       and not app.account_is_admin(a.id)
                       and (s.current_period_end is null
                            or s.current_period_end > now())),
    --  169: gelir 's.seats' sutunundan yox, ANBAAN aktiv sagird sayindan
    'mrr_minor', app.mrr_minor(),
    'students', (select count(*) from public.students st
                  join public.accounts a on a.id = st.account_id
                 where st.is_active and not a.is_demo),
    'seen_week', (select count(*) from public.accounts a
                   where not a.is_demo
                     and (exists (select 1 from public.profiles p2
                                  where (p2.id = a.owner_id
                                     or p2.id in (select am.user_id from public.account_members am
                                                   where am.account_id = a.id))
                                    and p2.last_seen_at > now() - interval '7 days')
                      or exists (select 1 from auth.users u2
                                  where u2.id = a.owner_id
                                    and u2.last_sign_in_at > now() - interval '7 days'))),
    'attempts_week', (select count(*) from public.attempts att
                       join public.students st on st.id = att.student_id
                       join public.accounts a on a.id = st.account_id
                       where att.status = 'submitted'
                         and not a.is_demo
                         and att.finished_at > now() - interval '7 days'),
    'plans', coalesce((
      select jsonb_agg(jsonb_build_object('slug', p.slug, 'name', p.name)
                       order by (p.audience <> 'tutor'), p.sort)
        from public.plans p
       where p.is_active and p.slug <> 'pulsuz'), '[]'::jsonb));
end $$;

revoke all on function app.mrr_minor() from public, anon, authenticated;
revoke all on function public.rpc_admin_grant(text, text, int, boolean) from public, anon;
grant  execute on function public.rpc_admin_grant(text, text, int, boolean) to authenticated;
revoke all on function public.rpc_paket(uuid) from public, anon;
grant  execute on function public.rpc_paket(uuid) to authenticated;
revoke all on function public.rpc_admin_stats() from public, anon;
grant  execute on function public.rpc_admin_stats() to authenticated;
