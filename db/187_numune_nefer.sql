-- =====================================================================
--  187_numune_nefer.sql — «NUMUNEYE NECE NEFER GIRDI»
--
--  Istifadeci (2026-09-11): "admin sehifesinde lazimdir ki, ziyaret
--  edenlerden nece nefer numuneye girib - bu da menim ucun statistika".
--
--  Movcud 'demo' reqemi KLIK sayidir: bir nefer muellim/sagird/valideyn
--  numunesine ucunu de acirsa 3 gorunur.  Huni ise NEFERLE olculur -
--  «38 ziyaretci -> nece nefer numuneye girdi» sualina klik sayi cavab
--  vermir.  Ona gore visit_sum-a 'demo_uniq' elave olunur: eyni ziyaret
--  nisani (vid) uzre TEK say.  Kohne 'demo' qalir - klik bolgusu hele
--  de lazimdir (muellim / sagird / valideyn).
--
--  Govde 162-den proqramla goturulub; yalniz bir bend elave olunub.
--  Yeni funksiya yaranmir - anon ag siyahisi 20 olaraq qalir.
-- =====================================================================

do $$
begin
  if to_regprocedure('public.rpc_admin_visits(int)') is null then
    raise exception 'ONCE 161_ziyaret.sql / 162_ziyaret_huni.sql isledilmelidir.';
  end if;
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
    --  187: NECE NEFER - klik yox, adam.  Bir nefer uc defe basirsa
    --  'demo' 3 sayir; sual ise «nece nefer numuneye girdi»dir.
    --  Basliqsiz sorguda vid null olur - o setirler nefer sayilmir
    --  (kim oldugunu bilmirik), klik sayinda ise qalir.
    'demo_uniq', (select count(distinct x.vid) from public.visits x
                   where x.ev like 'demo_%' and x.vid is not null
                     and x.at::date between p_from and p_to),
    'signup', (select count(*) from public.accounts a
                where not a.is_demo
                  and a.created_at::date between greatest(p_from, app.visit_start()) and p_to))
$$;

create or replace function public.rpc_admin_visits(p_days int default 30)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare v_days int := least(greatest(coalesce(p_days, 30), 7), 90);
begin
  if not app.admin_ok() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;
  delete from public.visits where at < now() - interval '90 days';

  return jsonb_build_object(
    'today', app.visit_sum(current_date, current_date),
    'd7',    app.visit_sum(current_date - 6, current_date),
    'd30',   app.visit_sum(current_date - 29, current_date),
    'start', app.visit_start(),
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
                           where not a.is_demo and a.created_at::date = d::date
                             and d::date >= app.visit_start()))
             order by d)
        from generate_series(current_date - (v_days - 1), current_date, interval '1 day') d), '[]'::jsonb),
    'events', (select coalesce(jsonb_object_agg(e.ev, e.n), '{}'::jsonb)
                 from (select ev, count(*) n from public.visits
                        where at > now() - interval '30 days' and ev <> 'view'
                        group by ev) e));
end $$;
revoke all on function public.rpc_admin_visits(int)   from public, anon;
grant execute on function public.rpc_admin_visits(int) to authenticated;
