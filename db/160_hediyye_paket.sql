-- =====================================================================
--  160_hediyye_paket.sql — QOSULANA HEDIYYE PAKET + ANA SEHIFE KARTI
--
--  Istifadeci ideyasi (2026-09-07): "yeni qeydiyyatdan kecene admin
--  mesaj versin - qosuldugunuz ucun bir ayliq abune qazandiniz".
--  Adminin el ile etmesi evezine sistem ozu edir:
--
--   * Ayar app_state.hediyye = {"on":true, "days":30, "beta_until":"2026-12-31"}.
--     rpc_create_account (repetitor/mekteb) -> app.hediyye_grant(hesab):
--     repetitor-25 plani status='trialing', provider='gift', bitme =
--     max(beta_until gununun sonu, indi + days).  Beta bitene qeder
--     "beta dovrunde tam paket pulsuzdur" vedi ile ziddiyyet olmasin
--     deye bitme beta_until-dan tez ola bilmez; beta bitenden sonra
--     qeydiyyat 30 gunluk sinaq verir.  Gelire dusmur (138 qaydasi).
--   * rpc_my_context.plan -> status/ends/provider: panel ana sehifede
--     h1-in altinda #giftCard ("Xos gelmisiniz! ... tam paket hediyyedir
--     ... bitme: ...").  7 gun qalanda narinci + WhatsApp duymesi.
--   * rpc_admin_hediyye(p_on, p_days, p_beta_until): admin oxuyur/yazir
--     (hamisi null = yalniz oxu).  Idareetmede "Hediyye paket" setri.
--
--  Yerli test bazasinda ayar SONDURULUR (run.sh --local), yoxsa 27 e2e
--  skriptinin pulsuz-hedd yoxlamalari (0 / 5) pozulur; smoke_hediyye ve
--  e2e_panel ayari ozu acir.  Numune hesabina (136) toxunmur - onun oz
--  abunesi var (has_active_subscription yoxlanir).
-- =====================================================================

do $$
begin
  if to_regclass('public.app_state') is null then
    raise exception 'ONCE 136_numune_hesab.sql isledilmelidir.';
  end if;
end $$;

insert into public.app_state (key, val)
values ('hediyye', jsonb_build_object('on', true, 'days', 30, 'beta_until', '2026-12-31'))
on conflict (key) do nothing;

create or replace function app.hediyye_cfg() returns jsonb
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select coalesce((select val from public.app_state where key = 'hediyye'),
                  jsonb_build_object('on', false, 'days', 30, 'beta_until', null))
$$;

--  Hesaba hediyye paket: ayar aciq + repetitor/mekteb + aktiv abune yox.
--  Qaytarir: bitme tarixi (verilmeyibse null).
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

  v_end := now() + (greatest(coalesce((v_cfg->>'days')::int, 30), 1) || ' days')::interval;
  v_beta := nullif(v_cfg->>'beta_until', '')::date;
  if v_beta is not null and (v_beta + 1)::timestamptz > v_end then
    v_end := (v_beta + 1)::timestamptz;      -- beta gununun sonu
  end if;

  insert into public.subscriptions
    (account_id, plan_id, status, seats, started_at, current_period_end, provider)
  values (p_account, v_plan, 'trialing', 25, now(), v_end, 'gift');
  return v_end;
end $$;

--  Admin: ayari oxu / yaz.  Hamisi null = yalniz oxu.
create or replace function public.rpc_admin_hediyye(
  p_on boolean default null, p_days int default null, p_beta_until date default null,
  p_clear_beta boolean default false)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare v jsonb := app.hediyye_cfg();
begin
  if not app.admin_ok() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;
  if p_days is not null and (p_days < 1 or p_days > 365) then
    raise exception 'Gun sayi 1-365 araliginda olmalidir.' using errcode = '22023';
  end if;
  if p_on is not null then v := v || jsonb_build_object('on', p_on); end if;
  if p_days is not null then v := v || jsonb_build_object('days', p_days); end if;
  if p_beta_until is not null then v := v || jsonb_build_object('beta_until', p_beta_until::text); end if;
  if coalesce(p_clear_beta, false) then v := v || jsonb_build_object('beta_until', null); end if;
  insert into public.app_state (key, val, updated_at) values ('hediyye', v, now())
  on conflict (key) do update set val = excluded.val, updated_at = now();
  return v;
end $$;

create or replace function public.rpc_create_account(p_type text, p_name text)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_uid  uuid := auth.uid();
  v_acc  uuid;
  v_role app_role;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  if p_type not in ('parent','tutor','school','individual') then
    raise exception 'Hesab tipi yanlisdir.' using errcode = '22023';
  end if;
  if coalesce(btrim(p_name), '') = '' then
    raise exception 'Ad bos ola bilmez.' using errcode = '22023';
  end if;

  insert into public.accounts (type, name, owner_id)
  values (p_type::account_type, btrim(p_name), v_uid)
  returning id into v_acc;

  insert into public.account_members (account_id, user_id, is_admin)
  values (v_acc, v_uid, true);

  v_role := case p_type when 'tutor'  then 'tutor'
                        when 'school' then 'teacher'
                        when 'parent' then 'parent'
                        else 'learner' end;
  insert into public.user_roles (user_id, role) values (v_uid, v_role)
  on conflict do nothing;

  --  160: qosulana hediyye paket (ayar aciqdirsa) - repetitor/mekteb
  perform app.hediyye_grant(v_acc);

  return jsonb_build_object('id', v_acc, 'type', p_type, 'name', btrim(p_name));
end $$;

create or replace function public.rpc_my_context()
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;

  return jsonb_build_object(
    'user_id', v_uid,
    'profile', (select jsonb_build_object('full_name', p.full_name, 'phone', p.phone)
                  from public.profiles p where p.id = v_uid),
    'roles',   coalesce((select jsonb_agg(role) from public.user_roles where user_id = v_uid), '[]'::jsonb),
    'accounts', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id',    a.id,
               'type',  a.type,
               'name',  a.name,
               'is_owner', a.owner_id = v_uid,
               --  136: numune hesab nisani ve numune kodlari (zolaq ucun)
               'is_demo', a.is_demo,
               'demo_codes', case when a.is_demo then (
                   select jsonb_build_object('student', st.login_code, 'parent', st.parent_code)
                     from public.students st where st.account_id = a.id
                    order by st.created_at, st.id limit 1) end,
               'subjects', to_jsonb(a.subjects),
               'students_used',  app.account_student_count(a.id),
               'students_limit', app.account_seat_limit(a.id),
               --  160: ana sehifedeki hediyye karti ucun status/bitme/menbe
               'plan', (select jsonb_build_object('slug', pl.slug, 'name', pl.name,
                                                  'status', s2.status, 'ends', s2.current_period_end,
                                                  'provider', s2.provider)
                          from public.subscriptions s2
                          join public.plans pl on pl.id = s2.plan_id
                         where s2.account_id = a.id
                           and s2.status in ('trialing','active')
                           and (s2.current_period_end is null or s2.current_period_end > now())
                         order by s2.started_at desc limit 1)
             ) order by a.name)
        from public.accounts a
        join public.account_members m on m.account_id = a.id and m.user_id = v_uid
    ), '[]'::jsonb)
  );
end $$;

revoke all on function app.hediyye_cfg()                                     from public, anon, authenticated;
revoke all on function app.hediyye_grant(uuid)                               from public, anon, authenticated;
revoke all on function public.rpc_admin_hediyye(boolean, int, date, boolean) from public, anon;
grant execute on function public.rpc_admin_hediyye(boolean, int, date, boolean) to authenticated;
revoke all on function public.rpc_create_account(text, text) from public, anon;
grant execute on function public.rpc_create_account(text, text) to authenticated;
revoke all on function public.rpc_my_context() from public, anon;
grant execute on function public.rpc_my_context() to authenticated;
