-- =====================================================================
--  196_mesq_hedd_5.sql — PULSUZDA SAGIRD MESQI: GUNDE 5 SUAL
--
--  Istifadeci: «pulsuzda şagird məşqi gündə 20 sual çoxdur, 5 edək».
--  Hedd bir yerde saxlanir: app.practice_daily_limit() (db/137).
--  practice_quota / practice_next / practice_answer onu cagirir -
--  basqa hec ne deyismir.  Abune ile limit yoxdur (evvelki kimi).
-- =====================================================================

do $$
begin
  if to_regprocedure('app.practice_daily_limit()') is null then
    raise exception 'ONCE 137_mesq_limit.sql isledilmelidir.';
  end if;
end $$;

create or replace function app.practice_daily_limit() returns int
language sql immutable as $$ select 5 $$;
revoke all on function app.practice_daily_limit() from public, anon, authenticated;
