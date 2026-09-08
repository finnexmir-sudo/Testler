-- =====================================================================
--  166_baki_vaxti.sql — QALAN GUN BAKI VAXTI ILE SAYILIR
--
--  165-de 'days_left' bele hesablanirdi:
--      s2.current_period_end::date - current_date
--  Her iki cast sessiyanin saat qursagindan asilidir.  Supabase UTC-de
--  isleyir, muellim ise UTC+4-de.  Gece yarisina yaxin netice BIR GUN
--  surusurdu:
--      abune bitir 01.10 saat 02:00 UTC (= 01.10 06:00 Baki)
--      indi       30.09 saat 23:00 UTC (= 01.10 03:00 Baki)
--      UTC-de  -> "1 gun sonra bitir"   Baki-de -> "bu gun bitir"
--
--  Yazida bu zerersizdir, PULDA deyil: xatirlatma ve odenis dovru
--  muellimin gunune gore hesablanmalidir (CLAUDE.md - "pul isi:
--  100 olc, bir bic", 10-cu bend).
--
--  165-in ustune yazilir - orada olan her sey qalir, yalniz iki
--  setirlik tarix hesablamasi deyisir.
-- =====================================================================

create or replace function public.rpc_my_context()
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_gr  int  := app.grace_days();
  --  Muellimin gunu - baza UTC-de olsa da
  v_bugun date := (now() at time zone 'Asia/Baku')::date;
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

revoke all on function public.rpc_my_context() from public, anon;
grant execute on function public.rpc_my_context() to authenticated;
