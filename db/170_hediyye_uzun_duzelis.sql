-- =====================================================================
--  170_hediyye_uzun_duzelis.sql — SEHVEN UZUN VERILMIS HEDIYYENIN
--  QAYDAYA SALINMASI (bir defelik MELUMAT duzelisi, kod deyisikliyi yox)
--
--  NE OLMUSDU: 160-in hesablamasi hediyyenin bitmesini 'beta_until'-e
--  uzadirdi.  9 sentyabr 2026-da qeydiyyatdan kecen ilk muellim 30 gun
--  evezine 1 yanvar 2027 (114 gun) aldi.  Mentiq 168-de duzeldildi,
--  amma ARTIQ VERILMIS setir olduğu kimi qalmisdi.
--
--  ISTIFADECI QERARI (2026-09-09): "her kesde eyni olsun" - hemin
--  muellimin hediyyesi de qeydiyyat anindan +1 ay olsun.
--
--  DUSTUR: current_period_end = started_at + hediyye 'days' (30).
--  started_at qeydiyyat anidir, ona gore netice "hemin gun + 1 ay"-dir
--  ve bugun qeydiyyatdan kecen her hansi muellimle EYNIDIR.
--
--  TEHLUKESIZLIK ("pul isi: 100 olc, bir bic"):
--   * yalniz provider='gift' + status='trialing' setirler - odenisli
--     abuneye, el ile verilmis paketlere, sinaqlara toxunmur
--   * yalniz 2026-09-01-den sonra baslayanlar (beta kohortu)
--   * yalniz HEQIQETEN uzun olanlar: bitme > baslangic + 31 gun -
--     ona gore tekrar isledilende hec ne deyismir (idempotent)
--   * muddet YALNIZ QISALIR, uzanmir
-- =====================================================================

--  Duzelis FUNKSIYA kimi yazilir ki, yoxlana bilsin: miqrasiya faylini
--  test icinde ikinci defe isletmek mumkun deyil (o, baza qurulanda
--  artiq islemis olur - o vaxt hele hec bir setir yoxdur).
create or replace function app.hediyye_uzun_duzelt() returns int
language sql security definer set search_path = public, extensions, pg_temp as $$
  with duz as (
    update public.subscriptions s
       set current_period_end = s.started_at
           + (greatest(coalesce((app.hediyye_cfg()->>'days')::int, 30), 1)
              || ' days')::interval
     where s.provider = 'gift'
       and s.status   = 'trialing'
       and s.started_at >= timestamptz '2026-09-01'
       and s.current_period_end > s.started_at + interval '31 days'
    returning 1)
  select count(*)::int from duz
$$;

revoke all on function app.hediyye_uzun_duzelt() from public, anon, authenticated;

do $$
declare n int;
begin
  if to_regclass('public.subscriptions') is null then
    raise exception 'ONCE 01_schema.sql isledilmelidir.';
  end if;
  n := app.hediyye_uzun_duzelt();
  raise notice '170: qaydaya salinan hediyye abunesi: %', n;
end $$;
