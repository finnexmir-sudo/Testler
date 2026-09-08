-- =====================================================================
--  165_sagird_basi_qiymet.sql — SAGIRD BASINA QIYMET + GUZEST MUDDETI
--
--  Qiymet qerari (istifadeci ile 2026-09-08 muzakiresi):
--   * Sagird ve valideyn HEMISE pulsuzdur - bazadaki pullu valideyn
--     paketleri baglanir (ana sehifedeki vedle ziddiyyet tesqil edirdi).
--   * Muellim: paket yox, SAGIRD BASINA - aktiv sagird basina ayda
--     1.50 AZN.  Sebeb: repetitorlarin coxunda 6-10 sagird olur;
--     pilleli paketlerde 25->26 kecidi qiymeti iki qat artirirdi ve
--     muellimi sagird elave etmemeye sovq edirdi.
--   * Vaxti bitende hesab DERHAL dayanmir: 3 gun guzest muddeti var,
--     ekranda xatirlatma gorunur.  Ondan sonra pulsuz hedde dusur -
--     movcud sagirdler islemekde davam edir, tezesi elave olunmur.
--
--  DIQQET: bu miqrasiya heç bir hesabin davranisini DEYISMIR.  Yeni
--  plan yaradilir, amma hec kime verilmir; qiymet sehifesi hele de
--  gizlidir (config.js -> SHOW_PLANS: false).  Yeganə real deyisiklik
--  guzest muddetidir - o da hamiya XEYRINEDIR (3 gun elave).
--
--  Ayarlar app_state.qiymet-dedir - miqrasiyasiz deyisdirmek ucun.
-- =====================================================================

do $$
begin
  if to_regclass('public.app_state') is null then
    raise exception 'ONCE 136_numune_hesab.sql isledilmelidir.';
  end if;
end $$;

--  per_seat_minor: qepikle, aktiv sagird basina aylig
--  grace_days:     abune bitenden sonra hesabin isledigi gun sayi
insert into public.app_state (key, val)
values ('qiymet', jsonb_build_object('per_seat_minor', 150, 'grace_days', 3))
on conflict (key) do nothing;

create or replace function app.qiymet_cfg() returns jsonb
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select coalesce((select val from public.app_state where key = 'qiymet'),
                  jsonb_build_object('per_seat_minor', 150, 'grace_days', 3))
$$;

--  Guzest muddeti (gun).  0-dan kicik ola bilmez, 30-dan boyuk yox -
--  sehv ayar hesabi aylarla acıq saxlamasin.
create or replace function app.grace_days() returns int
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select least(greatest(coalesce((app.qiymet_cfg()->>'grace_days')::int, 3), 0), 30)
$$;

-- ------------------------------------------------------------ paketler
--  Valideyn pullu paketleri baglanir: ana sehife "sagird ve valideyn
--  hemise pulsuz" deyir, bazada ise 9.90/99 AZN-lik paketler dururdu.
--  Silmirik (kohne abune onlara istinad ede biler), sadece gizledirik.
update public.plans set is_active = false
 where slug in ('valideyn-aylik', 'valideyn-illik');

--  Yeni plan: baza haqqi yoxdur, yalniz sagird basina, limit yoxdur.
insert into public.plans (slug, name, audience, price_minor, price_per_seat_minor,
                          max_students, period, sort, features)
values ('sagird-basi', 'Şagird başına', 'tutor', 0,
        coalesce((app.qiymet_cfg()->>'per_seat_minor')::int, 150),
        null, 'month', 35,
        '{"reports":true,"own_tests":true,"weak_topics":true,"class_analytics":true}'::jsonb)
on conflict (slug) do update
  set name = excluded.name, audience = excluded.audience,
      price_minor = excluded.price_minor,
      price_per_seat_minor = excluded.price_per_seat_minor,
      max_students = excluded.max_students,
      period = excluded.period, sort = excluded.sort,
      features = excluded.features, is_active = true;

-- --------------------------------------------------- guzest muddeti
--  138-dekilerin uzerine: bitme tarixine grace_days elave olunur.
create or replace function app.has_active_subscription(p_account uuid) returns boolean
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select app.account_is_admin(p_account) or exists (
    select 1 from public.subscriptions
    where account_id = p_account
      and status in ('trialing','active')
      and (current_period_end is null
           or current_period_end > now() - (app.grace_days() || ' days')::interval)
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
        and (s.current_period_end is null
             or s.current_period_end > now() - (app.grace_days() || ' days')::interval)
      order by coalesce(p.max_students, 2147483647) desc
      limit 1),
    app.free_seat_limit()) end
$$;

-- ------------------------------------------- panel ucun abune veziyyeti
--  160-dakinin uzerine.  Elave olunanlar (hamisi 'plan' obyektinde):
--    per_seat_minor · base_minor : qiymet
--    due_minor                   : bu ayin meblegi (aktiv sagird x tarif)
--    days_left                   : qalan gun; MENFI = guzest muddetinde
--    grace_days                  : guzestin uzunlugu
--  Bitme tarixi kecmis abune de qaytarilir (guzest bitene qeder) -
--  yoxsa ekranda xatirlatma gostermek ucun melumat qalmirdi.
create or replace function public.rpc_my_context()
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_gr  int  := app.grace_days();
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
                          --  Tam GUN ferqi (saniye yox): "5 gun sonra bitir"
                          --  yazisi saniye qirintisina gore 4 olmasin.
                          --  Menfi = guzest muddetindedir.
                          'days_left', case when s2.current_period_end is null then null
                            else (s2.current_period_end::date - current_date) end)
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

revoke all on function app.qiymet_cfg() from public, anon, authenticated;
revoke all on function app.grace_days() from public, anon, authenticated;
revoke all on function public.rpc_my_context() from public, anon;
grant execute on function public.rpc_my_context() to authenticated;
