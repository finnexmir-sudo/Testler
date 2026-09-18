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
-- =====================================================================
do $$
declare
  v_src  text := pg_get_functiondef('public.rpc_admin_stats()'::regprocedure);
  v_mark text := '''seen_today'', (select count(*) from public.accounts a
                    where not a.is_demo
                      and not app.account_is_admin(a.id)
                      and exists (select 1 from auth.users u2
                                   where u2.id = a.owner_id
                                     and (u2.last_sign_in_at at time zone ''Asia/Baku'')::date
                                         = (now() at time zone ''Asia/Baku'')::date)),';
  v_add  text := '''seen_today'', (select count(*) from public.accounts a
                    where not a.is_demo
                      and not app.account_is_admin(a.id)
                      --  215: paneli acmaq da girisdir.  last_sign_in_at
                      --  yalniz parolla girisde yenilenir - diri sessiya
                      --  ile her gun girən muellim sayilmirdi.
                      --  215b: IKI MENBE MOTERIZEDE.  SQL-de AND OR-dan
                      --  guclu baglayir; moterizesiz "or" yuxaridaki
                      --  "numune deyil / admin deyil" sertlerini qirirdi
                      --  ve adminin oz hesabi sayilirdi (smoke_admin_giris
                      --  bolme 5 tutdu).
                      and (((select max(p2.last_seen_at) from public.profiles p2
                              where p2.id = a.owner_id
                                 or p2.id in (select am.user_id from public.account_members am
                                               where am.account_id = a.id))
                            at time zone ''Asia/Baku'')::date
                           = (now() at time zone ''Asia/Baku'')::date
                        or exists (select 1 from auth.users u2
                                    where u2.id = a.owner_id
                                      and (u2.last_sign_in_at at time zone ''Asia/Baku'')::date
                                          = (now() at time zone ''Asia/Baku'')::date))),';
begin
  if position('215b: IKI MENBE MOTERIZEDE' in v_src) > 0 then
    raise notice '215 artiq tetbiq olunub, kecilir';
    return;
  end if;
  if (length(v_src) - length(replace(v_src, v_mark, ''))) / length(v_mark) <> 1 then
    raise exception '215: seen_today markeri 1 defe olmalidir (175 isledilibmi?)';
  end if;
  execute replace(v_src, v_mark, v_add);
end $$;

revoke all on function public.rpc_admin_stats() from public, anon;
grant execute on function public.rpc_admin_stats() to authenticated;
