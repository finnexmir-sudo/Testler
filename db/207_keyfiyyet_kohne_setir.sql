-- =====================================================================
--  207 : SUAL KEYFIYYETI - KOHNE (NUMUNE) SETIRLER TEMIZLENIR (2026-09-17)
--
--  139 numune hesablarinin cehdlerini app.qstat_rows-dan cixarmisdi,
--  amma question_stats KES cedveli yalniz «upsert» ile yenilenirdi:
--  teze hesablamada olmayan sual (yalniz numune cehdleri olan) kohne
--  reqemleri ile ebedi qalirdi.  Canlida: Idareetmede «Sual keyfiyyəti 3»
--  - 7-ci sinif Rasional ededler / Statistika, 20-27 cavab: numunenin oz
--  movzulari.
--
--  Indi qstat_refresh: teze hesablama muveqqeti cedvele, upsert, sonra
--  hesablamada OLMAYAN setirler silinir (baxildi nisani da onunla gedir -
--  melumat yoxdursa nisan da menasizdir).
-- =====================================================================
create or replace function app.qstat_refresh() returns int
language plpgsql as $$
declare v int;
begin
  create temp table if not exists qs_new (like public.question_stats including defaults) on commit drop;
  delete from qs_new where true;
  insert into qs_new (question_id, n, p, rpb, opts, flags, sev, computed_at)
  select r.question_id, r.n, r.p, r.rpb, r.opts, r.flags, r.sev, now()
    from app.qstat_rows(null) r;

  insert into public.question_stats (question_id, n, p, rpb, opts, flags, sev, computed_at)
  select question_id, n, p, rpb, opts, flags, sev, computed_at from qs_new
  on conflict (question_id) do update
    set n = excluded.n, p = excluded.p, rpb = excluded.rpb, opts = excluded.opts,
        flags = excluded.flags, sev = excluded.sev, computed_at = now();
  get diagnostics v = row_count;

  --  207: teze hesablamada olmayan sual (cehdleri yalniz numuneden idi,
  --  ya da silinib) kesde qalmasin
  delete from public.question_stats qs
   where not exists (select 1 from qs_new x where x.question_id = qs.question_id);
  return v;
end $$;
revoke all on function app.qstat_refresh() from public, anon, authenticated;
