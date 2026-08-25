-- =====================================================================
--  21_paket.sql : PAKET SEHIFESI VE ADMIN IDAREETMESI
--
--  Odenis MERHELE 1 (el ile): muellim paneldeki "Paket" sehifesinde
--  qiymetleri gorur, WhatsApp-la yazir, pulu kocurur; ADMIN bir klikle
--  abunesini acir.  Odenis provayderi (merhele 2) sonra qosulacaq -
--  subscriptions.provider/provider_ref sahesi ona hazirdir.
--
--  ADMIN KIMDIR:  user_roles cedvelinde 'admin' rolu olan istifadeci.
--  Ilk admini SQL ile tayin et (birdefelik):
--      insert into public.user_roles (user_id, role)
--      select id, 'admin' from auth.users where email = 'SENIN@EPOCTUN'
--      on conflict do nothing;
--
--  Butun admin funksiyalari iceride app.is_admin() yoxlayir - rol
--  olmayan istifadeciye acıq imtina qaytarilir.
--
--  ON SERT: 01_schema.sql, 04_seed.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
--  Tekrar isledile biler.
-- =====================================================================

do $$
begin
  if to_regclass('public.plans') is null then
    raise exception 'ONCE 01_schema.sql isledilmelidir.';
  end if;
end $$;

-- ------------------------------------------------- paket sehifesi
--  Muellim oz hesabinin veziyyetini ve ona uygun planlari gorur.
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
    'current', (
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
       limit 1),
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

-- ------------------------------------------------- admin: hesablar
create or replace function public.rpc_admin_accounts(p_q text default null)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
begin
  if not app.is_admin() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;

  return coalesce((
    select jsonb_agg(x order by x->>'created' desc)
    from (
      select jsonb_build_object(
               'id',    a.id,
               'name',  a.name,
               'type',  a.type,
               'email', u.email,
               'students', app.account_student_count(a.id),
               'created', a.created_at,
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
       where p_q is null or btrim(p_q) = ''
          or a.name ilike '%' || btrim(p_q) || '%'
          or u.email ilike '%' || btrim(p_q) || '%'
       order by a.created_at desc
       limit 50
    ) z), '[]'::jsonb);
end $$;

-- ------------------------------------------------- admin: abune acmaq
--  Eyni plan aktivdirse UZADILIR (bitmə tarixinin ustune), deyilse
--  yenisi acilir.  p_months 1..24.
create or replace function public.rpc_admin_grant(
  p_email text, p_plan text default 'repetitor-25', p_months int default 1)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_acc  uuid;
  v_plan uuid;
  v_sub  public.subscriptions%rowtype;
  v_end  timestamptz;
begin
  if not app.is_admin() then
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
    v_end := greatest(coalesce(v_sub.current_period_end, now()), now())
             + (p_months || ' months')::interval;
    update public.subscriptions
       set current_period_end = v_end, status = 'active', provider = 'manual'
     where id = v_sub.id;
  else
    v_end := now() + (p_months || ' months')::interval;
    insert into public.subscriptions
      (account_id, plan_id, status, started_at, current_period_end, provider)
    values (v_acc, v_plan, 'active', now(), v_end, 'manual');
  end if;

  return jsonb_build_object('ok', true, 'account', v_acc, 'ends', v_end);
end $$;

-- ------------------------------------------------- admin: dayandirmaq
create or replace function public.rpc_admin_stop(p_email text)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare v_n int;
begin
  if not app.is_admin() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;

  update public.subscriptions s
     set status = 'canceled', cancel_at = now()
    from public.accounts a
    join auth.users u on u.id = a.owner_id
   where s.account_id = a.id
     and lower(u.email) = lower(btrim(p_email))
     and s.status in ('trialing','active');
  get diagnostics v_n = row_count;
  return jsonb_build_object('ok', true, 'stopped', v_n);
end $$;

-- ---------------------------------------------------------------- huquq
revoke all on function public.rpc_paket(uuid)                    from public, anon;
revoke all on function public.rpc_admin_accounts(text)           from public, anon;
revoke all on function public.rpc_admin_grant(text, text, int)   from public, anon;
revoke all on function public.rpc_admin_stop(text)               from public, anon;

grant execute on function public.rpc_paket(uuid)                  to authenticated;
grant execute on function public.rpc_admin_accounts(text)         to authenticated;
grant execute on function public.rpc_admin_grant(text, text, int) to authenticated;
grant execute on function public.rpc_admin_stop(text)             to authenticated;

do $$
begin
  if has_function_privilege('anon', 'public.rpc_admin_grant(text, text, int)', 'EXECUTE') then
    raise exception 'anon abune aca bilir!';
  end if;
  raise notice 'Paket ve admin funksiyalari quruldu.';
end $$;
