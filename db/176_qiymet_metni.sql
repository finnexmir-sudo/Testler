-- =====================================================================
--  176_qiymet_metni.sql — QIYMET MƏTNİ: «hər şagird üçün», qayda
--  sətri serverdən
--
--  ISTIFADECI (2026-09-09), iki qeyd:
--
--  1. «Limitsiz şagird» abunə siyahısında çaşdırıcıdır.  Siyahıdakı
--     qalan bendlerin hamisi «abune alanda ACILAN imkandir»; sagird
--     sayi ise ODEDIYIN VAHIDDIR.  Eyni siyahida, reqemsiz duranda goz
--     onu da «daxildir» kimi oxuyur.  Zolaqdaki qiymet telefonda hemin
--     siyahi ile EYNI EKRANDA deyil, ona gore «yuxarida yazilib»
--     arqumenti islemir.  Hesab gelende «limitsiz yazilmisdi» deyilir -
--     pul isinde en bahali cur sehv budur.
--     ==> Bend siyahidan cixarildi, basligin altina QAYDA SETRI kimi
--         mebleqle birlikde qoyuldu.  Mebleg BURADAN gelir
--         (rpc_my_context.qiymet), koda yazilmir.
--
--  2. «şagird başına» sozu kobud seslenir.  Qrammatik olaraq duzdur
--     («adambasina» kimi), amma USAQLAR haqqinda mehsulda «bas» sozu
--     bas-say calarini getirir.  «hər şagird üçün» eyni uzunluqda,
--     eyni deqiqlikde, calari temizdir.
--     ==> Paketin ADI da deyisir.  Daxili ad (slug) 'sagird-basi'
--         QALIR - onu hec kim gormur, deyismek nahaq risqdir
--         (abuneler, testler, admin siyahisi ona baglidir).
--
--  Qiymet DEYISMIR: 1,50 ₼ hər şagird üçün, ayda.  Yalniz metn.
-- =====================================================================

do $$
begin
  if to_regclass('public.plans') is null then
    raise exception 'ONCE 21_paket.sql isledilmelidir.';
  end if;
end $$;

--  Paketin gorunen adi (slug toxunulmur)
update public.plans set name = 'Hər şagird üçün' where slug = 'sagird-basi';

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
    --  176: SATISDAKI QAYDA - ekranda «hər şagird üçün N ₼ / ay» yazmaq
    --  ucun.  Hesabin oz abunesinden ASILI DEYIL: pulsuz hedde dusmus
    --  muellim de qiymeti gormelidir (qerar verdiyi andir).  Reqem
    --  BURADAN gedir, koda yazilmir - yoxsa qiymet deyisende ekran
    --  kohne reqemi gosterer ve muellim yalan mebleg gorer.
    'qiymet', (select jsonb_build_object(
                 'per_seat_minor', p.price_per_seat_minor,
                 'base_minor',     p.price_minor)
                 from public.plans p
                where p.slug = 'sagird-basi' and p.is_active),
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
