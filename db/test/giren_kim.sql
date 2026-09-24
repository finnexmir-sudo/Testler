-- =====================================================================
--  giren_kim.sql — «Bu gün: N girən müəllim» sayğacı KİMİ sayıb?
--
--  Istifadeci sualı (2026-09-24): «giren muellim 1 yazir ama ziyaretci
--  0-dir, bu nece hesablayir?»  Iki saygac ayri menbedendir:
--    * «giren muellim»  = paneli acan hesab   (profiles.last_seen_at)
--    * «ziyaretci»      = ana sehife/beledci  (visits cedveli)
--  Panel ziyaret saymir (assets/visit.js orada yoxdur), ona gore
--  birbasa bil10.az/muellim/ acan muellim ZIYARET kimi gorunmur.
--
--  Bu sorgu «giren» sayilan hesablari ad-ad gosterir - reqemin
--  arxasinda kim durdugunu yoxlamaq ucun.
-- =====================================================================
select a.name                                            as hesab,
       a.type                                            as tip,
       (max(p.last_seen_at) at time zone 'Asia/Baku')    as panel_acib,
       (u.last_sign_in_at   at time zone 'Asia/Baku')    as parolla_giris,
       case when (max(p.last_seen_at) at time zone 'Asia/Baku')::date
                 = (now() at time zone 'Asia/Baku')::date
            then 'panel nebzi' else 'parolla giris' end  as niye_sayilib
  from public.accounts a
  left join public.profiles p
         on p.id = a.owner_id
         or p.id in (select am.user_id from public.account_members am
                      where am.account_id = a.id)
  left join auth.users u on u.id = a.owner_id
 where not a.is_demo
   and not app.account_is_admin(a.id)
 group by a.id, a.name, a.type, u.last_sign_in_at
having ((max(p.last_seen_at) at time zone 'Asia/Baku')::date
        = (now() at time zone 'Asia/Baku')::date)
    or ((u.last_sign_in_at at time zone 'Asia/Baku')::date
        = (now() at time zone 'Asia/Baku')::date)
 order by 3 desc nulls last;
