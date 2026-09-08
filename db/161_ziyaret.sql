-- =====================================================================
--  161_ziyaret.sql — ZIYARET SAYGACI (ana sehife + beledci)
--
--  Istifadeci sualı (2026-09-07, reklam paylasilan gun): "ziyaretci
--  sayini gore bilerem?"  GitHub Pages statistika vermir, Cloudflare
--  "DNS only"-de trafiki gormur, kenar skript (Plausible, GA) qadagandir.
--  Ona gore oz saygacimiz: ana sehife/beledci acilanda assets/visit.js
--  anon acarla rpc_visit cagirir (baxis), dugmelere basanda hadise
--  (demo_muellim, demo_sagird, demo_valideyn, panel, beledci).
--
--  Mexfilik: IP saxlanmir.  Unikal ziyaretci = md5(gunluk tesadufi duz +
--  IP + brauzer).  Duz her gun deyisir (app_state.visit_salt), dunenki
--  hash bu gunku ile uygun gelmir - izleme yoxdur, yalniz say.
--  Basliqlar PostgREST-den request.headers ile gelir; yerli mock-da
--  yoxdur -> vid null (say yene islenir, unikal yox).
--
--  Spam: bir vid gunde 200 setirden cox yaza bilmir.  90 gunden kohne
--  setirler admin baxanda silinir.  Cedvel RLS ile bagli, siyaset yox
--  (anon/authenticated oxuya bilmir) - yalniz rpc_admin_visits.
-- =====================================================================

do $$
begin
  if to_regclass('public.app_state') is null then
    raise exception 'ONCE 136_numune_hesab.sql isledilmelidir.';
  end if;
end $$;

create table if not exists public.visits (
  id   bigserial primary key,
  at   timestamptz not null default now(),
  page text not null,
  ev   text not null default 'view',
  vid  text
);
create index if not exists visits_at_idx on public.visits (at);
alter table public.visits enable row level security;
revoke all on public.visits from public, anon, authenticated;
revoke all on sequence public.visits_id_seq from public, anon, authenticated;

--  gunluk tesadufi duz - app_state-de, her gun yenisi
create or replace function app.visit_salt() returns text
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare v jsonb; s text;
begin
  select val into v from public.app_state where key = 'visit_salt';
  if v is not null and v->>'day' = current_date::text then
    return v->>'salt';
  end if;
  s := encode(gen_random_bytes(16), 'hex');
  insert into public.app_state (key, val, updated_at)
  values ('visit_salt', jsonb_build_object('day', current_date::text, 'salt', s), now())
  on conflict (key) do update set val = excluded.val, updated_at = now();
  return s;
end $$;
revoke all on function app.visit_salt() from public, anon, authenticated;

create or replace function public.rpc_visit(p_page text, p_ev text default 'view')
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  h   jsonb;
  ip  text := '';
  ua  text := '';
  v_vid text;
begin
  if p_page is null or p_page not in ('home','komek') then
    return jsonb_build_object('ok', false);
  end if;
  if p_ev is null or p_ev not in ('view','demo_muellim','demo_sagird','demo_valideyn','panel','beledci') then
    return jsonb_build_object('ok', false);
  end if;
  begin
    h := nullif(current_setting('request.headers', true), '')::jsonb;
  exception when others then h := null;
  end;
  if h is not null then
    ip := btrim(split_part(coalesce(h->>'x-forwarded-for', ''), ',', 1));
    ua := left(coalesce(h->>'user-agent', ''), 300);
  end if;
  if ip <> '' or ua <> '' then
    v_vid := md5(app.visit_salt() || '|' || ip || '|' || ua);
    --  spam: bir ziyaretci gunde 200 setirden cox yox
    if (select count(*) from public.visits v
         where v.vid = v_vid and v.at > now() - interval '1 day') >= 200 then
      return jsonb_build_object('ok', false, 'limit', true);
    end if;
  end if;
  insert into public.visits (page, ev, vid) values (p_page, p_ev, v_vid);
  return jsonb_build_object('ok', true);
end $$;

--  Admin: gunler uzre baxis/unikal/demo/qeydiyyat, ceml lovheler, huni
create or replace function public.rpc_admin_visits(p_days int default 30)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare v_days int := least(greatest(coalesce(p_days, 30), 7), 90);
begin
  if not app.admin_ok() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;
  --  ev isi: 90 gunden kohne setirler
  delete from public.visits where at < now() - interval '90 days';

  return jsonb_build_object(
    'today', app.visit_sum(current_date, current_date),
    'd7',    app.visit_sum(current_date - 6, current_date),
    'd30',   app.visit_sum(current_date - 29, current_date),
    'days', coalesce((
      select jsonb_agg(jsonb_build_object(
               'day', d::date,
               'views', (select count(*) from public.visits x
                          where x.ev = 'view' and x.at::date = d::date),
               'uniq',  (select count(distinct x.vid) from public.visits x
                          where x.at::date = d::date and x.vid is not null),
               'demo',  (select count(*) from public.visits x
                          where x.ev like 'demo_%' and x.at::date = d::date),
               'signup', (select count(*) from public.accounts a
                           where not a.is_demo and a.created_at::date = d::date))
             order by d)
        from generate_series(current_date - (v_days - 1), current_date, interval '1 day') d), '[]'::jsonb),
    'events', (select coalesce(jsonb_object_agg(e.ev, e.n), '{}'::jsonb)
                 from (select ev, count(*) n from public.visits
                        where at > now() - interval '30 days' and ev <> 'view'
                        group by ev) e));
end $$;

create or replace function app.visit_sum(p_from date, p_to date) returns jsonb
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select jsonb_build_object(
    'views', (select count(*) from public.visits x
               where x.ev = 'view' and x.at::date between p_from and p_to),
    'uniq',  (select count(distinct x.vid) from public.visits x
               where x.at::date between p_from and p_to and x.vid is not null),
    'demo',  (select count(*) from public.visits x
               where x.ev like 'demo_%' and x.at::date between p_from and p_to),
    'signup', (select count(*) from public.accounts a
                where not a.is_demo and a.created_at::date between p_from and p_to))
$$;
revoke all on function app.visit_sum(date, date) from public, anon, authenticated;

revoke all on function public.rpc_visit(text, text)   from public;
grant execute on function public.rpc_visit(text, text) to anon, authenticated;
revoke all on function public.rpc_admin_visits(int)   from public, anon;
grant execute on function public.rpc_admin_visits(int) to authenticated;
