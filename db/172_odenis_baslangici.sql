-- =====================================================================
--  172_odenis_baslangici.sql — "ODENIS NE VAXTDAN BASLAYIR" AYARI
--
--  Istifadeci qerari (2026-09-09): mueellime meblegi INDIDEN gosterek
--  ki, sonra surpriz olmasin - AMMA ekranda acıq yazilsin ki, bu
--  sertler beta dovru bitenden sonra quvveye minir.  Yoxsa muellim
--  indi pul istenildiyini dusune biler.
--
--  Ayar app_state.qiymet-e elave olunur: 'odenis_start'.
--   * BOS (null / '') -> "beta dovru davam edir, tarix hele elan
--     olunmayib" - ekran tarixsiz vede yazir.  SUSMA HALI budur:
--     tarix vermemek daha tehlukesizdir, cunki verilen tarix vedidir.
--   * tarix (YYYY-MM-DD) -> ekran hemin gunu yazir.
--
--  Tarixi sonra bir setirle qoymaq olar:
--    update public.app_state
--       set val = val || jsonb_build_object('odenis_start','2027-01-01')
--     where key = 'qiymet';
--
--  DIQQET: bu ayar HEC BIR HESABIN davranisini deyismir - nə abunə,
--  nə hədd, nə məbləğ.  Yalniz ekranda yazilan cümlədir.  Pul mentiqi
--  (has_active_subscription, seat_limit, due_minor) toxunulmur.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.app_state where key = 'qiymet') then
    raise exception 'ONCE 165_sagird_basi_qiymet.sql isledilmelidir.';
  end if;
end $$;

--  Acar yoxdursa elave olunur; VARSA toxunulmur (istifadeci qoyduğu
--  tarix miqrasiyanin tekrar islenmesi ile silinmesin).
update public.app_state
   set val = jsonb_build_object('odenis_start', null) || val
 where key = 'qiymet'
   and not (val ? 'odenis_start');
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
               'plan', (select jsonb_build_object(
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
                         order by s2.started_at desc limit 1)
             ) order by a.name)
        from public.accounts a
        join public.account_members m on m.account_id = a.id and m.user_id = v_uid
    ), '[]'::jsonb)
  );
end $$;
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

revoke all on function public.rpc_my_context() from public, anon;
grant  execute on function public.rpc_my_context() to authenticated;
revoke all on function public.rpc_paket(uuid) from public, anon;
grant  execute on function public.rpc_paket(uuid) to authenticated;
