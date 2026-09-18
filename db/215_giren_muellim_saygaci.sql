-- =====================================================================
--  215 : «BU GUN - GIREN MUELLIM» SAYĞACI YANLIS IDI (2026-09-18)
--
--  Istifadeci: «Terane bu gun giris edib, amma yuxarida 0 gosterir».
--  Dogrudur - eyni ekranda iki reqem bir-birini tekzib edirdi:
--    * Hesablar cedveli:  «son giris - bu gun 12:54»   (DOGRU)
--    * «Bu gun» lovhesi:  «0 giren muellim»            (YANLIS)
--
--  SEBEB
--  seen_today YALNIZ auth.users.last_sign_in_at-e baxirdi.  Supabase
--  onu ancaq PAROLLA GIRISDE yenileyir.  Muellimin sessiyasi diridirse
--  (refresh token), o her gun paneli acir, amma parol yazmir - deməli
--  last_sign_in_at kohne tarixde qalir.  Netice: saygac demek olar
--  hemise 0 gosterirdi ve «hec kim girmir» kimi yalan mənzərə verirdi.
--
--  Duzgun menbe profiles.last_seen_at-dir - paneli acanda rpc_seen()
--  onu yazir (206-dan sonra her 2 deqiqede bir).  Hesablar cedveli
--  (125/138/174) ONSUZ DA ikisinin BOYUYUNU goturur; seen_week de
--  (175) hər iki menbeye baxir.  Yaddan cixan tek yer seen_today idi.
--
--  Burada sadece hemin bir ifadeni cedvel/heftelik ile eynilesdiririk.
--  Admin hesabi ve numune nusxeleri evvelki kimi sayilmir.
--
--  DIQQET (18.09): evvel MARKER usulu var idi - canlidaki funksiyanin
--  metnini herfbeherf tapib evez edirdi.  db/211-de mehz bu usul canlida
--  sindi (metn bosluq/setir sonu ile ferqlenirdi).  Ona gore burada da
--  govde TAM yazilir (db/175-in etdiyi kimi): fayl tek basina isleyir,
--  canlidaki metnden asili deyil, tekrar isledile biler.
-- =====================================================================
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
    --  215: paneli acmaq da girisdir.  auth.users.last_sign_in_at yalniz
    --  PAROLLA girisde yenilenir - sessiyasi diri olan muellim her gun
    --  paneli acirdi, saygac ise onu gormurdu (18.09, istifadeci tutdu).
    --  Dogru menbe profiles.last_seen_at-dir (rpc_seen yazir).  Hesablar
    --  cedveli ve seen_week onsuz da hər iki menbeye baxirdi.
    --
    --  215b: IKI MENBE MOTERIZEDE.  SQL-de AND OR-dan guclu baglayir;
    --  moterizesiz "or" yuxaridaki "numune deyil / admin deyil"
    --  sertlerini qirir ve adminin oz hesabi sayilirdi.
    'seen_today', (select count(*) from public.accounts a
                    where not a.is_demo
                      and not app.account_is_admin(a.id)
                      and ((((select max(p2.last_seen_at) from public.profiles p2
                               where p2.id = a.owner_id
                                  or p2.id in (select am.user_id from public.account_members am
                                                where am.account_id = a.id))
                             at time zone 'Asia/Baku')::date
                            = (now() at time zone 'Asia/Baku')::date)
                        or exists (select 1 from auth.users u2
                                    where u2.id = a.owner_id
                                      and (u2.last_sign_in_at at time zone 'Asia/Baku')::date
                                          = (now() at time zone 'Asia/Baku')::date))),
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
                     and not app.account_is_admin(a.id)
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
revoke all on function public.rpc_admin_stats() from public, anon;
grant execute on function public.rpc_admin_stats() to authenticated;
