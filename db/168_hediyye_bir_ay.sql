-- =====================================================================
--  168_hediyye_bir_ay.sql — HEDIYYE HEMISE 1 AY (teklif il sonuna kimi)
--
--  SEHV: 160-da bitme tarixi bele hesablanirdi:
--      v_end = indi + days
--      eger (beta_until + 1) daha gecdirse -> v_end = beta_until + 1
--  Yeni 'beta_until' TEKLIFIN son gunu deyil, HER MUELLIMIN abunesinin
--  bitme tarixi kimi islenirdi.  Netice: 9 sentyabrda qeydiyyatdan
--  kecen muellim 30 gun evezine 114 gun (1 yanvar 2027) aldi.
--
--  DUZGUN QAYDA (istifadeci): "il sonuna kimi yeni muellimler BIR AY
--  pulsuz alir; lazim olsa admin ozu elave ay hediyye edir."
--  Yeni:
--      teklif qüvvədədirmi?  bugun (Baki) > beta_until  -> hediyye YOX
--      qüvvədədirse         v_end = indi + days          -> HEMISE 1 ay
--
--  MOVCUD ABUNELERE TOXUNULMUR (istifadeci qerari): artiq verilmis
--  tarixler qalir - muellim onu ekranda gorub, qisaltmaq pis olardi.
--  Bu miqrasiya YALNIZ funksiyani deyisir, hec bir setri yenilemir.
--
--  Tarix Baki gunu ile (CLAUDE.md - "pul isi: 100 olc, bir bic", 10-cu
--  bend): baza UTC-dedir, teklifin son gunu muellimin gunudur.
-- =====================================================================

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
  select id into v_plan from public.plans where slug = 'repetitor-25' and is_active;
  if v_plan is null then return null; end if;

  --  168: 'beta_until' TEKLIFIN son gunudur - kecibse hediyye yoxdur
  v_beta := nullif(v_cfg->>'beta_until', '')::date;
  if v_beta is not null and (now() at time zone 'Asia/Baku')::date > v_beta then
    return null;
  end if;

  --  168: uzunluq HEMISE 'days'-dir (beta tarixine uzanmir)
  v_end := now() + (greatest(coalesce((v_cfg->>'days')::int, 30), 1) || ' days')::interval;

  insert into public.subscriptions
    (account_id, plan_id, status, seats, started_at, current_period_end, provider)
  values (p_account, v_plan, 'trialing', 25, now(), v_end, 'gift');
  return v_end;
end $$;

revoke all on function app.hediyye_grant(uuid) from public, anon, authenticated;
