-- =====================================================================
--  195_ziyaret_menbe.sql — ZIYARETIN MENBEYI (?src=...)
--
--  Istifadeci reklam seklini WhatsApp qruplarinda paylasir, sayta
--  gelen 7 neferin haradan geldiyini bilmirik.  Linkde ?src=wa kimi
--  qisa nisan gelir, brauzer onu ziyaretle gonderir, admin 30 gunluk
--  bolguni gorur («wa 5 nəfər · birbaşa 12»).
--
--  - visits.src (<= 20 simvol, yalniz [a-z0-9_-]; qalan hamisi bos)
--  - rpc_visit(p_page, p_ev, p_src default null) - kohne 2-parametrli
--    imza SILINIR (PostgREST-de iki imza qarisiq olur); 05_grants
--    adi ile verir, yeniden isledilmelidir
--  - app.visits_pub gorunusune src sutunu
--  - rpc_admin_visits -> 'src' (pg_get_functiondef ile goturulub, bir
--    acar elave olunub)
-- =====================================================================

do $$
begin
  --  tekrar isledilende 2-parametrli imza artiq silinib - 3-lu de olar
  if to_regprocedure('public.rpc_visit(text, text)') is null
     and to_regprocedure('public.rpc_visit(text, text, text)') is null then
    raise exception 'ONCE 189_oz_ziyaretim.sql isledilmelidir.';
  end if;
end $$;

alter table public.visits add column if not exists src text;

create or replace view app.visits_pub as
  select id, at, page, ev, vid, src
    from public.visits v
   where not app.is_own_visit(vid, at);

drop function if exists public.rpc_visit(text, text);

create or replace function public.rpc_visit(p_page text, p_ev text default 'view', p_src text default null)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_vid text;
  v_src text;
begin
  if p_page is null or p_page not in ('home','komek','giris') then
    return jsonb_build_object('ok', false);
  end if;
  if p_ev is null or p_ev not in ('view','demo_muellim','demo_sagird',
                                 'demo_valideyn','panel','beledci',
                                 'wa','mail') then
    return jsonb_build_object('ok', false);
  end if;
  --  menbe: yalniz qisa, tehlukesiz nisan; qalan hamisi bos sayilir
  v_src := lower(coalesce(p_src, ''));
  --  uzun deyer KESILMIR, atilir - kesilse «cox-uzun-...» kecerdi
  if v_src !~ '^[a-z0-9_-]{1,20}$' then v_src := null; end if;
  v_vid := app.vid_now();
  if v_vid is not null then
    --  spam: bir ziyaretci gunde 200 setirden cox yox
    if (select count(*) from public.visits v
         where v.vid = v_vid and v.at > now() - interval '1 day') >= 200 then
      return jsonb_build_object('ok', false, 'limit', true);
    end if;
  end if;
  insert into public.visits (page, ev, vid, src) values (p_page, p_ev, v_vid, v_src);
  return jsonb_build_object('ok', true);
end $$;

revoke all on function public.rpc_visit(text, text, text) from public;
grant execute on function public.rpc_visit(text, text, text) to anon, authenticated;

--  ---- rpc_admin_visits (govde: pg_get_functiondef, 'src' acari elave)
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
                        group by ev) e),
    --  195: menbe - linkdeki ?src=... (wa, fb, ...); bos = birbasa/bilinmir
    'src', coalesce((
      select jsonb_agg(jsonb_build_object('src', s.src, 'views', s.n, 'uniq', s.u) order by s.n desc)
        from (select coalesce(nullif(x.src, ''), '') src, count(*) n,
                     count(distinct x.vid) u
                from app.visits_pub x
               where x.ev = 'view' and x.at > now() - interval '30 days'
               group by 1) s), '[]'::jsonb));
end $function$

;
