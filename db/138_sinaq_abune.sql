-- =====================================================================
--  138_sinaq_abune.sql — SINAQ (PULSUZ) ABUNE, ADMIN DAIMI, NUMUNE SAYILMIR
--
--  ISTIFADECI SIKAYETI (2026-09-07, Idareetme ekrani):
--    "ayliq gelir 233 AZN yazir - bunlar hamisi pulsuz sinaqdir, gelir
--     deyil.  Panelde pulsuz abune imkani olmalidir.  Admin hesabina
--     abune lazim deyil, daimi olmali.  Numune hesablari niye 4 dene?"
--
--  UC QUSUR, UC DUZELIS:
--
--  1. SINAQ ABUNE.  rpc_admin_grant hemise status='active' yazirdi -
--     pulsuz verilen paket de "odenisli" sayilir, gelire dusurdu.
--     Indi p_trial=true ile status='trialing', provider='trial'.
--     Butun qapilar (has_active_subscription, seat_limit, mesq limiti)
--     onsuz da 'trialing'-i 'active' kimi qebul edir - muellim tam
--     imkan alir, amma gelire, "pullu" sayina dusmur.  Sinaq bitmeden
--     odenisli grant gelse: odenisli muddet BU GUNDEN baslayir (sinaqin
--     qaligi ustune gelmir - gelir hesabi durust olsun).
--
--  2. ADMIN DAIMI.  Admin rolu olan istifadecinin SAHIB oldugu hesab
--     abunesiz limitsizdir: app.account_is_admin(hesab) ->
--     has_active_subscription = true, seat_limit = sonsuz.  Statistikada
--     pullu/sinaq/gelire dusmur; siyahida "admin · daimi" nisani,
--     duymeler yoxdur; Paket sehifesi "Admin - daimi" yazir.
--
--  3. NUMUNE SAYILMIR.  Her "Muellim kimi bax" kliki ziyaretciye oz
--     nusxesini yaradir (136); nusxelerin 1 illik abunesi var - ona
--     gore 4 numune x 29 AZN gelire, hesab sayina, cehd sayina dusurdu.
--     Indi rpc_admin_stats butun saylarda is_demo hesablari cixarir;
--     rpc_admin_accounts onlari yalniz p_f='numune' suzgecinde gosterir.
--     Nusxeler 24 saatdan sonra rpc_demo_reset ile ozu silinir - el ile
--     silmek lazim deyil.
--
--  GOVDELER: rpc_admin_accounts 125-in uzerindedir (gen138.py ile
--  proqramla), rpc_admin_stats 125-den, rpc_admin_grant/rpc_paket 21-den
--  yeniden yazilib.  rpc_admin_grant imzasi deyisdiyi ucun kohne
--  (text,text,int) silinir - PostgREST "best candidate" cashmasin.
--
--  ON SERT: 136 (accounts.is_demo).  SONRA: 05_grants.sql lazim deyil
--  (admin funksiyalari authenticated-e burda verilir).
-- =====================================================================

do $$
begin
  if not exists (select 1 from information_schema.columns
                  where table_schema = 'public' and table_name = 'accounts'
                    and column_name = 'is_demo') then
    raise exception 'ONCE 136_numune_hesab.sql isledilmelidir.';
  end if;
end $$;

-- ------------------------------------------------- admin sahibli hesab
create or replace function app.account_is_admin(p_account uuid) returns boolean
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select exists (
    select 1 from public.accounts a
    join public.user_roles r on r.user_id = a.owner_id and r.role = 'admin'
    where a.id = p_account
  )
$$;

--  02_rls.sql-dekilerin uzerine: admin sahibli hesab abunesiz aktivdir
create or replace function app.has_active_subscription(p_account uuid) returns boolean
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select app.account_is_admin(p_account) or exists (
    select 1 from public.subscriptions
    where account_id = p_account
      and status in ('trialing','active')
      and (current_period_end is null or current_period_end > now())
  )
$$;

create or replace function app.account_seat_limit(p_account uuid) returns int
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select case when app.account_is_admin(p_account) then 2147483647
         else coalesce(
    (select case
              when p.max_students is null then 2147483647
              else greatest(p.max_students, s.seats)
            end
       from public.subscriptions s
       join public.plans p on p.id = s.plan_id
      where s.account_id = p_account
        and s.status in ('trialing','active')
        and (s.current_period_end is null or s.current_period_end > now())
      order by coalesce(p.max_students, 2147483647) desc
      limit 1),
    app.free_seat_limit()) end
$$;

-- ------------------------------------------------- admin: abune acmaq
drop function if exists public.rpc_admin_grant(text, text, int);

create or replace function public.rpc_admin_grant(
  p_email text, p_plan text default 'repetitor-25', p_months int default 1,
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

-- ------------------------------------------------- paket sehifesi
create or replace function public.rpc_paket(p_account uuid default null)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_acc  uuid := app.pick_account(p_account);
  v_type account_type;
begin
  select type into v_type from public.accounts where id = v_acc;
  if v_type is null then
    raise exception 'Hesab tapilmadi.' using errcode = '22023';
  end if;

  return jsonb_build_object(
    'current', case when app.account_is_admin(v_acc) then
      jsonb_build_object('plan', 'Admin — daimi', 'slug', 'admin',
                         'status', 'active', 'ends', null)
    else (
      select jsonb_build_object(
               'plan',   pl.name,
               'slug',   pl.slug,
               'status', s.status,
               'ends',   s.current_period_end)
        from public.subscriptions s
        join public.plans pl on pl.id = s.plan_id
       where s.account_id = v_acc
         and s.status in ('trialing','active')
         and (s.current_period_end is null or s.current_period_end > now())
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

-- ------------------------------------------------- admin: gostericiler
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
    'mrr_minor', coalesce((
      select sum(pl.price_minor
                 + pl.price_per_seat_minor * greatest(s.seats, 0))
        from public.subscriptions s
        join public.plans pl on pl.id = s.plan_id
        join public.accounts a on a.id = s.account_id
       where s.status = 'active'
         and not a.is_demo
         and not app.account_is_admin(a.id)
         and (s.current_period_end is null
              or s.current_period_end > now())), 0),
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

-- ------------------------------------------------- admin: hesablar

create or replace function public.rpc_admin_accounts(
  p_q text default null, p_f text default null)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
begin
  if not app.admin_ok() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;

  return coalesce((
    select jsonb_agg(x order by
             case when p_f in ('pullu','bitir','sinaq')
                  then x->'plan'->>'ends' end asc nulls last,
             x->>'created' desc)
    from (
      select jsonb_build_object(
               'id',    a.id,
               'name',  a.name,
               'type',  a.type,
               'email', u.email,
               'students', app.account_student_count(a.id),
               'groups', (select count(*) from public.classes c
                           where c.account_id = a.id),
               --  Testler hesaba SAHIBLIK uzre baglanir.  Evvel
               --  class_id uzre birlesdirilirdi, halbuki muellimin
               --  yigdigi testde class_id HEC VAXT dolmur (nə generator,
               --  ne duzelis testi onu yazmir) - say butun hesablarda
               --  hemise 0 gorunurdu.
               'tests', (select count(*) from public.tests t
                          where (t.owner_type = 'educator'
                      and (t.owner_id in (select am.user_id
                                            from public.account_members am
                                           where am.account_id = a.id)
                           or t.class_id in (select c.id from public.classes c
                                              where c.account_id = a.id)))),
               'attempts', (select count(*) from public.attempts att
                             join public.students st on st.id = att.student_id
                            where st.account_id = a.id
                              and att.status = 'submitted'),
               'last_active', greatest(
                 (select max(att.finished_at) from public.attempts att
                   join public.students st on st.id = att.student_id
                  where st.account_id = a.id),
                 --  Eyni qusur burada da vardi: test yigan, amma hele
                 --  cehd olmayan muellim "aktivlik: hec vaxt" gorunurdu.
                 (select max(t.created_at) from public.tests t
                   where (t.owner_type = 'educator'
                      and (t.owner_id in (select am.user_id
                                            from public.account_members am
                                           where am.account_id = a.id)
                           or t.class_id in (select c.id from public.classes c
                                              where c.account_id = a.id))))),
               'created', a.created_at,
               --  Girisler: muellim paneli acilanda rpc_seen() yazir
               --  (profiles.last_seen_at); Supabase-in oz last_sign_in_at-i
               --  yalniz parolla girisde yenilenir - ikisinin boyuyu.
               'last_login', greatest(
                 (select max(p2.last_seen_at) from public.profiles p2
                   where p2.id = a.owner_id
                      or p2.id in (select am.user_id from public.account_members am
                                    where am.account_id = a.id)),
                 u.last_sign_in_at),
               --  Sagird/valideyn girisi: kodla giris = yeni sessiya
               'student_login', greatest(
                 (select max(ss.created_at) from public.student_sessions ss
                   join public.students st on st.id = ss.student_id
                  where st.account_id = a.id),
                 (select max(ps.created_at) from public.parent_sessions ps
                   join public.students st on st.id = ps.student_id
                  where st.account_id = a.id)),
               --  138: admin sahibli hesab daimidir, numune nusxesi
               --  sayilmir - panel duymeleri buna gore gizledir
               'admin', app.account_is_admin(a.id),
               'demo',  a.is_demo,
               'plan', (select jsonb_build_object(
                          'name', pl.name, 'status', s.status,
                          'ends', s.current_period_end)
                          from public.subscriptions s
                          join public.plans pl on pl.id = s.plan_id
                         where s.account_id = a.id
                           and s.status in ('trialing','active')
                           and (s.current_period_end is null
                                or s.current_period_end > now())
                         order by s.current_period_end desc nulls last
                         limit 1)
             ) as x
        from public.accounts a
        join auth.users u on u.id = a.owner_id
       --  138: numune nusxeleri yalniz 'numune' suzgecinde
       where a.is_demo = coalesce(p_f = 'numune', false)
         and (p_q is null or btrim(p_q) = ''
           or a.name ilike '%' || btrim(p_q) || '%'
           or u.email ilike '%' || btrim(p_q) || '%')
         and (p_f is null
           --  Girmeyenler: 7 gundur hec bir uzv paneli acmayib
           or (p_f = 'girmir' and coalesce(greatest(
                 (select max(p3.last_seen_at) from public.profiles p3
                   where p3.id = a.owner_id
                      or p3.id in (select am.user_id from public.account_members am
                                    where am.account_id = a.id)),
                 u.last_sign_in_at), a.created_at) < now() - interval '7 days')
           or (p_f = 'bitir' and exists (
                select 1 from public.subscriptions s2
                 where s2.account_id = a.id
                   and s2.status in ('trialing','active')
                   and s2.current_period_end > now()
                   and s2.current_period_end <= now() + interval '14 days'))
           or p_f = 'numune'
           --  138: pullu = yalniz ODENISLI (active); sinaq = trialing;
           --  pulsuz = hec biri.  Admin sahibli hesab pullu deyil.
           or (p_f = 'pullu' and not app.account_is_admin(a.id) and exists (
                select 1 from public.subscriptions s2
                 where s2.account_id = a.id
                   and s2.status = 'active'
                   and (s2.current_period_end is null
                        or s2.current_period_end > now())))
           or (p_f = 'sinaq' and exists (
                select 1 from public.subscriptions s2
                 where s2.account_id = a.id
                   and s2.status = 'trialing'
                   and (s2.current_period_end is null
                        or s2.current_period_end > now())))
           or (p_f = 'pulsuz' and not app.account_is_admin(a.id) and not exists (
                select 1 from public.subscriptions s2
                 where s2.account_id = a.id
                   and s2.status in ('trialing','active')
                   and (s2.current_period_end is null
                        or s2.current_period_end > now()))))
       order by a.created_at desc
       limit 50
    ) z), '[]'::jsonb);
end $$;

-- ---------------------------------------------------------------- huquq
revoke all on function public.rpc_admin_grant(text, text, int, boolean)    from public, anon;
revoke all on function public.rpc_paket(uuid)                              from public, anon;
revoke all on function public.rpc_admin_stats()                            from public, anon;
revoke all on function public.rpc_admin_accounts(text, text)               from public, anon;

grant execute on function public.rpc_admin_grant(text, text, int, boolean) to authenticated;
grant execute on function public.rpc_paket(uuid)                           to authenticated;
grant execute on function public.rpc_admin_stats()                         to authenticated;
grant execute on function public.rpc_admin_accounts(text, text)            to authenticated;
