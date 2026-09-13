-- =====================================================================
--  190_oz_nisan_2fa.sql : oz ziyaret nisani 2FA kilidinden asili olmasin
--
--  189-un deliyi (canli olcu, 2026-09-13): rpc_seen oz cihazi YALNIZ
--  app.admin_ok() dogru olanda nisanlayirdi.  admin_ok ise 2FA kilidinin
--  ACIQ olmasini teleb edir.  rpc_seen panel yuklenende - kod yazilmazdan
--  EVVEL - bir defe cagirilir; kilid bagli idise nisan qoyulmur ve bir de
--  cehd edilmir.  Netice: adminin oz telefonu (IP deyisende yeni vid)
--  "1 unikal kenar ziyaretci" kimi gorunurdu - 14 baxis, hamisi ozu.
--
--  Duzelis - iki xett:
--    1. app.own_mark(): nisan is_admin() ile qoyulur.  Oz baxisini
--       gizletmek hessas oxunus deyil - 2FA lazim deyil.  Adi muellim
--       yene nisanlanmir (onun ana sehifeye qayitmasi heqiqi siqnaldir).
--    2. rpc_admin_visits: admin REQEMLERE BAXAN ANDA cari cihazi
--       nisanlayir, sonra hesablayir.  IP deyisse de (mobil internet)
--       baxdigi reqem hec vaxt onu saymir.
--
--  Serverin duzelde bilmeyeceyi hal: sessiyasiz brauzer (WhatsApp /
--  Telegram icindeki brauzer) - o, admin oldugunu hec vaxt demir.
--  Linki oz brauzerinden yoxla.
-- =====================================================================

create or replace function app.own_mark() returns void
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare v_vid text;
begin
  if not app.is_admin() then return; end if;
  v_vid := app.vid_now();
  if v_vid is null then return; end if;
  insert into public.own_vids (vid, day)
  values (v_vid, (now() at time zone 'Asia/Baku')::date)
  on conflict (vid, day) do nothing;
  delete from public.own_vids where day < current_date - 120;
end $$;
revoke all on function app.own_mark() from public, anon, authenticated;

--  ---- rpc_seen: 189-dakı govde, nisan hissesi own_mark()-a kocdu
create or replace function public.rpc_seen()
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false);
  end if;
  update public.profiles
     set last_seen_at = now()
   where id = auth.uid()
     and (last_seen_at is null or last_seen_at < now() - interval '15 minutes');
  --  190: 2FA kilidinden asili deyil
  perform app.own_mark();
  return jsonb_build_object('ok', true);
end $$;
revoke all on function public.rpc_seen() from public, anon;
grant execute on function public.rpc_seen() to authenticated;

--  ---- rpc_admin_visits: 189-dakı govde + baxan anda nisan
CREATE OR REPLACE FUNCTION public.rpc_admin_visits(p_days integer DEFAULT 30)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
declare v_days int := least(greatest(coalesce(p_days, 30), 7), 90);
begin
  if not app.admin_ok() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;
  --  190: reqemlere baxan cihaz elə indi nisanlanir
  perform app.own_mark();
  delete from app.visits_pub where at < now() - interval '90 days';

  return jsonb_build_object(
    'today', app.visit_sum(current_date, current_date),
    'd7',    app.visit_sum(current_date - 6, current_date),
    'd30',   app.visit_sum(current_date - 29, current_date),
    'start', app.visit_start(),
    --  189: seffafliq - oz baxislarimizdan neceni saymadiq
    'own_today', (select count(*) from public.visits x
                   where app.is_own_visit(x.vid, x.at)
                     and (x.at at time zone 'Asia/Baku')::date
                         = (now() at time zone 'Asia/Baku')::date),
    'days', coalesce((
      select jsonb_agg(jsonb_build_object(
               'day', d::date,
               'views', (select count(*) from app.visits_pub x
                          where x.ev = 'view' and x.at::date = d::date),
               'uniq',  (select count(distinct x.vid) from app.visits_pub x
                          where x.at::date = d::date and x.vid is not null),
               'demo',  (select count(*) from app.visits_pub x
                          where x.ev like 'demo_%' and x.at::date = d::date),
               'signup', (select count(*) from public.accounts a
                           where not a.is_demo and a.created_at::date = d::date
                             and d::date >= app.visit_start()))
             order by d)
        from generate_series(current_date - (v_days - 1), current_date, interval '1 day') d), '[]'::jsonb),
    'events', (select coalesce(jsonb_object_agg(e.ev, e.n), '{}'::jsonb)
                 from (select ev, count(*) n from app.visits_pub
                        where at > now() - interval '30 days' and ev <> 'view'
                        group by ev) e));
end $function$;
revoke all on function public.rpc_admin_visits(int)   from public, anon;
grant  execute on function public.rpc_admin_visits(int) to authenticated;
