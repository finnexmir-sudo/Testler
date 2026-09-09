-- =====================================================================
--  173_admin_ekrani.sql — ADMIN EKRANI: iki duzelis
--
--  1. ADMIN HESABI ODEMIR.  Admin oz esas sehifesinde qiymet karti
--     ("Beta bitəndən sonra aylıq 12 ₼"), hediyye karti ("Tam paket
--     sizə hədiyyədir... 26 sen bitir") ve xatirlatma zolagi gorurdu -
--     halbuki app.has_active_subscription admin ucun HEMISE true-dur
--     ve limit yoxdur.  rpc_paket bunu onsuz da duzgun edirdi
--     ("Admin — daimi"); rpc_my_context geride qalmisdi.
--
--  2. "BU GUN" REQEMLERI.  rpc_admin_stats yalniz heftelik saylar
--     verirdi (accounts_week, seen_week, attempts_week).  Admin ise
--     sehifeni her gun acir - bugunku hereket gorunmelidir.
--     Elave olunur: accounts_today, seen_today, attempts_today.
--     Hamisi BAKI gunu ile (CLAUDE.md - tarixler Baki gunudur).
--
--  Hec bir davranis deyismir: nə abunə, nə hədd, nə məbləğ.  Birinci
--  bend yalniz EKRANI duzeldir, ikincisi yeni saylar elave edir.
-- =====================================================================

do $$
begin
  if to_regclass('public.app_state') is null then
    raise exception 'ONCE 136_numune_hesab.sql isledilmelidir.';
  end if;
end $$;
create or replace function public.rpc_my_context()
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_gr  int  := app.grace_days();
  --  Muellimin gunu - baza UTC-de olsa da
  v_bugun date := (now() at time zone 'Asia/Baku')::date;
  --  172: odenisin basladigi tarix - bos ola biler (beta davam edir)
  v_ods  text := nullif(app.qiymet_cfg()->>'odenis_start', '');
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
               --  165: qiymet, bu ayin meblegi, qalan gun, guzest
               --  173: ADMIN hesabi hec vaxt odemir - onun ekraninda
               --  qiymet, "hediyye bitir" ve xatirlatma zolagi gorunmemelidir.
               --  rpc_paket onsuz da bele edirdi; my_context geride qalmisdi.
               'plan', case when app.account_is_admin(a.id) then
                   jsonb_build_object('slug', 'admin', 'name', 'Admin · daimi',
                     'status', 'active', 'ends', null, 'provider', 'admin',
                     'grace_days', v_gr, 'odenis_start', v_ods,
                     'days_left', null)
                 else (select jsonb_build_object(
                          'slug', pl.slug, 'name', pl.name,
                          'status', s2.status, 'ends', s2.current_period_end,
                          'provider', s2.provider,
                          'base_minor', pl.price_minor,
                          'per_seat_minor', pl.price_per_seat_minor,
                          'due_minor', pl.price_minor
                            + pl.price_per_seat_minor * app.account_student_count(a.id),
                          'grace_days', v_gr,
                          --  172: odenisin basladigi tarix (bos ola biler)
                          'odenis_start', v_ods,
                          --  166: tam GUN ferqi, BAKI vaxti ile.
                          --  Menfi = guzest muddetindedir.
                          'days_left', case when s2.current_period_end is null then null
                            else ((s2.current_period_end at time zone 'Asia/Baku')::date
                                  - v_bugun) end)
                          from public.subscriptions s2
                          join public.plans pl on pl.id = s2.plan_id
                         where s2.account_id = a.id
                           and s2.status in ('trialing','active')
                           and (s2.current_period_end is null
                                or s2.current_period_end
                                   > now() - (v_gr || ' days')::interval)
                         order by s2.started_at desc limit 1) end
             ) order by a.name)
        from public.accounts a
        join public.account_members m on m.account_id = a.id and m.user_id = v_uid
    ), '[]'::jsonb)
  );
end $$;
create or replace function public.rpc_admin_stats()
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
begin
  if not app.admin_ok() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;

  return jsonb_build_object(
    --  173: "Bu gün" zolagi ucun - Baki gunu ile.  Evvel yalniz heftelik
    --  reqemler var idi, admin ise sehifeni HER GUN acir.
    'accounts_today', (select count(*) from public.accounts a
                        where not a.is_demo
                          and (a.created_at at time zone 'Asia/Baku')::date
                              = (now() at time zone 'Asia/Baku')::date),
    'seen_today', (select count(*) from public.accounts a
                    where not a.is_demo
                      and exists (select 1 from auth.users u2
                                   where u2.id = a.owner_id
                                     and (u2.last_sign_in_at at time zone 'Asia/Baku')::date
                                         = (now() at time zone 'Asia/Baku')::date)),
    'attempts_today', (select count(*) from public.attempts att
                        join public.students st on st.id = att.student_id
                        join public.accounts a on a.id = st.account_id
                       where att.status = 'submitted' and not a.is_demo
                         and (att.finished_at at time zone 'Asia/Baku')::date
                             = (now() at time zone 'Asia/Baku')::date),
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
--  173: ad hər yerdə eyni olsun - cədvəldə «admin · daimi» yazır
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
    --  172: odenis ne vaxtdan baslayir (bos = beta davam edir)
    'odenis_start', nullif(app.qiymet_cfg()->>'odenis_start', ''),
    'base_minor', coalesce(v_base, 0),
    'per_seat_minor', coalesce(v_seat, 0),
    'due_minor', coalesce(v_base, 0)
      + coalesce(v_seat, 0) * app.account_student_count(v_acc),
    'current', case when app.account_is_admin(v_acc) then
      jsonb_build_object('plan', 'Admin · daimi', 'slug', 'admin',
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

revoke all on function public.rpc_my_context() from public, anon;
grant  execute on function public.rpc_my_context() to authenticated;
revoke all on function public.rpc_admin_stats() from public, anon;
grant  execute on function public.rpc_admin_stats() to authenticated;
revoke all on function public.rpc_paket(uuid) from public, anon;
grant  execute on function public.rpc_paket(uuid) to authenticated;
