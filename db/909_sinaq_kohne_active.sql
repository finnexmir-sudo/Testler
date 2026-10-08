-- =====================================================================
--  909 : SINAQ VERENDE KOHNE (VAXTI KECMIS) 'active' SETIR SINAGA CEVRILSIN (2026-10-03)
--
--  XETA (02.10, Samir test): admin «sinaq» verir, panel «ayliq gelir» 3 AZN gosterir.
--  Sebeb (bu yox, ayrica «+1 ay» duymesi idi), amma ELAVE gizli xeta tapildi:
--  rpc_admin_grant 'trialing'/'active' setiri axtarir; vaxti KECMIS 'active' setir
--  (dayandirilmayib, tarix kecib) tapilanda sinaq verilse de status 'active' QALIRDI
--  («odenisli hec vaxt sinaga enmir» qaydasi) - hesab ODENISLI sayilir, gelir sismirdi.
--
--  NE DEYISIR: yalniz rpc_admin_grant-in status mentiqi.  Muddeti kecmis 'active'
--  setirde p_trial=true -> 'trialing' (provider='trial').  Hele quvvede olan ODENISLI
--  abune evvelki kimi qalir (sinaq verilse de 'active').  Qalan govde 169-dan eynen
--  (proqramla kocurulub).  Geri almaq: 169-dakini yeniden isletmek.
-- =====================================================================

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
  v_expired boolean;
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
    --  909: vaxti KECMIS 'active' setir hele odenisli sayilmir - sinaq verilende sinaq olur.
    --  Evvel: 'active' + sinaq = 'active' qalirdi, panel «ayliq gelir»de 1,50 x sagird gosterirdi.
    v_expired := v_sub.current_period_end is not null and v_sub.current_period_end <= now();
    v_status := case when v_trial and (v_sub.status = 'trialing' or v_expired)
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

revoke all on function public.rpc_admin_grant(text, text, int, boolean) from public, anon;
grant  execute on function public.rpc_admin_grant(text, text, int, boolean) to authenticated;
