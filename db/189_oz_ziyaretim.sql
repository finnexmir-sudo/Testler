-- =====================================================================
--  189_oz_ziyaretim.sql — ADMININ OZ BAXISLARI SAYILMASIN (serverde)
--
--  Movcud hell YARIMCIQ idi: admin paneli acanda BRAUZERE 'bil10_oz'
--  nisani qoyulurdu (app.js -> ozBrauzer) ve assets/visit.js hemin
--  brauzerde sayğaci hec cagirmirdi.  Bosluqlar:
--    * telefonda sayta baxirsan, o telefonda panele girmemisense -
--      sayilirsan
--    * baska brauzer, gizli rejim, temizlenmis yaddas - sayilirsan
--    * nisan QOYULMAMISDAN evvel edilen baxislar onsuz da sayilib
--
--  Olcu (2026-09-12): bir gunde 3 "ziyaretci"den biri 9 deqiqede 11
--  baxis etmisdi - istifadecinin ozu idi, telefondan.  Reqem yalan
--  danisir: "16 baxis, 3 unikal" desek de, real ziyaretci 1-2 nefer.
--
--  YENI QAYDA - server terefinde, brauzerden ASILI DEYIL:
--    admin paneli acanda (rpc_seen) server ONUN ziyaret nisanini
--    hesablayir (eyni md5: gunluk duz + IP + brauzer adi) ve
--    public.own_vids-e yazir.  Hesablamalarda hemin nisanin HEMIN
--    GUNKU butun setirleri cixarilir - baxis, unikal, demo, hadise.
--
--  GERIYE de isleyir: sehere sayta baxib, axsam panele girsen, seher
--  qoyulan setirler de sayilmir (suzgec HESABLAMA aninda islenir).
--
--  Brauzer nisani QALIR - o, setrin hec yazilmamasini temin edir;
--  bu ise yazilanı saymamaqdir.  Iki qat.
-- =====================================================================

do $$
begin
  if to_regclass('public.visits') is null then
    raise exception 'ONCE 161_ziyaret.sql isledilmelidir.';
  end if;
end $$;

--  ------------------------------------------------------- oz nisanlar
create table if not exists public.own_vids (
  vid  text not null,
  day  date not null,
  at   timestamptz not null default now(),
  primary key (vid, day)
);
alter table public.own_vids enable row level security;
revoke all on public.own_vids from public, anon, authenticated;

--  ------------------------------------ indiki sorgunun ziyaret nisani
--  rpc_visit-deki hesablamanin EYNISI - bir yerde saxlanir ki, ikisi
--  bir-birinden ayri dusmesin (ayri dusse suzgec hec ne tutmaz).
create or replace function app.vid_now() returns text
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare h jsonb; ip text := ''; ua text := '';
begin
  begin
    h := nullif(current_setting('request.headers', true), '')::jsonb;
  exception when others then h := null;
  end;
  if h is null then return null; end if;
  ip := btrim(split_part(coalesce(h->>'x-forwarded-for', ''), ',', 1));
  ua := left(coalesce(h->>'user-agent', ''), 300);
  if ip = '' and ua = '' then return null; end if;
  return md5(app.visit_salt() || '|' || ip || '|' || ua);
end $$;
revoke all on function app.vid_now() from public, anon, authenticated;

--  ------------------------------------------- setir "ozumuzunku"dur?
create or replace function app.is_own_visit(p_vid text, p_at timestamptz)
returns boolean
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select p_vid is not null and exists (
    select 1 from public.own_vids o
     where o.vid = p_vid
       and o.day = (p_at at time zone 'Asia/Baku')::date)
$$;
revoke all on function app.is_own_visit(text, timestamptz) from public, anon, authenticated;

--  Hesablamalar bu gorunusden oxuyur - oz setirlerimiz onsuz da yoxdur
create or replace view app.visits_pub as
  select v.* from public.visits v where not app.is_own_visit(v.vid, v.at);
revoke all on app.visits_pub from public, anon, authenticated;

--  --------------------------------------- admin panele girende nisan
create or replace function public.rpc_seen()
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare v_vid text;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false);
  end if;
  update public.profiles
     set last_seen_at = now()
   where id = auth.uid()
     and (last_seen_at is null or last_seen_at < now() - interval '15 minutes');

  --  189: YALNIZ admin.  Adi muellimin ana sehifeye qayitmasi HEQIQI
  --  siqnaldir - onu saymaga davam edirik.
  if app.admin_ok() then
    v_vid := app.vid_now();
    if v_vid is not null then
      insert into public.own_vids (vid, day)
      values (v_vid, (now() at time zone 'Asia/Baku')::date)
      on conflict (vid, day) do nothing;
      delete from public.own_vids where day < current_date - 120;
    end if;
  end if;
  return jsonb_build_object('ok', true);
end $$;
revoke all on function public.rpc_seen() from public, anon;
grant execute on function public.rpc_seen() to authenticated;

--  ---- rpc_visit
CREATE OR REPLACE FUNCTION public.rpc_visit(p_page text, p_ev text DEFAULT 'view'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
declare
  h   jsonb;
  ip  text := '';
  ua  text := '';
  v_vid text;
begin
  if p_page is null or p_page not in ('home','komek','giris') then
    return jsonb_build_object('ok', false);
  end if;
  if p_ev is null or p_ev not in ('view','demo_muellim','demo_sagird',
                                 'demo_valideyn','panel','beledci',
                                 'wa','mail') then
    return jsonb_build_object('ok', false);
  end if;
  v_vid := app.vid_now();
  if v_vid is not null then
    --  spam: bir ziyaretci gunde 200 setirden cox yox
    if (select count(*) from public.visits v
         where v.vid = v_vid and v.at > now() - interval '1 day') >= 200 then
      return jsonb_build_object('ok', false, 'limit', true);
    end if;
  end if;
  insert into public.visits (page, ev, vid) values (p_page, p_ev, v_vid);
  return jsonb_build_object('ok', true);
end $function$;

--  ---- visit_sum
CREATE OR REPLACE FUNCTION app.visit_sum(p_from date, p_to date)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
  select jsonb_build_object(
    'views', (select count(*) from app.visits_pub x
               where x.ev = 'view' and x.at::date between p_from and p_to),
    'uniq',  (select count(distinct x.vid) from app.visits_pub x
               where x.at::date between p_from and p_to and x.vid is not null),
    'demo',  (select count(*) from app.visits_pub x
               where x.ev like 'demo_%' and x.at::date between p_from and p_to),
    --  187: NECE NEFER - klik yox, adam.  Bir nefer uc defe basirsa
    --  'demo' 3 sayir; sual ise «nece nefer numuneye girdi»dir.
    --  Basliqsiz sorguda vid null olur - o setirler nefer sayilmir
    --  (kim oldugunu bilmirik), klik sayinda ise qalir.
    'demo_uniq', (select count(distinct x.vid) from app.visits_pub x
                   where x.ev like 'demo_%' and x.vid is not null
                     and x.at::date between p_from and p_to),
    'signup', (select count(*) from public.accounts a
                where not a.is_demo
                  and a.created_at::date between greatest(p_from, app.visit_start()) and p_to))
$function$;

--  ---- rpc_admin_visits
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

revoke all on function public.rpc_visit(text, text)   from public;
grant execute on function public.rpc_visit(text, text) to anon, authenticated;
revoke all on function public.rpc_admin_visits(int)   from public, anon;
grant  execute on function public.rpc_admin_visits(int) to authenticated;
