-- =====================================================================
--  171_kohne_sinaqlar_sagird_basi.sql — MOVCUD SINAQ/HEDIYYE ABUNELERI
--  YENI QAYDAYA KECIRILIR (melumat duzelisi)
--
--  BOSLUQ: 169 yalniz YENI hediyyeni 'sagird-basi' etdi.  Artiq
--  verilmis setirler 'repetitor-25'-de qaldi - yeni qeydiyyatdan
--  kecen limitsiz alirdi, evvel gelmis muellim ise 25 yerde idi.
--  Ekranda da "7 / 25 sagird yeri" gorunurdu.
--
--  ISTIFADECI QERARI: "her kesde eyni olsun".
--
--  TEHLUKESIZLIK ("pul isi: 100 olc, bir bic"):
--   * yalniz status='trialing' - PULLU abuneye toxunmur.  Odenisli
--     musteri aldigi paketde qalir (169-un qaydasi).
--   * yalniz baglanmis kohne paketlerden (repetitor-25/60/acik) -
--     artiq 'sagird-basi'-de olan setir tekrar yazilmir
--   * plan tutor auditoriyasindadir; mekteb hesablari 'mekteb'-e kecir
--   * seats sutunu 1-e endirilir: sagird basina planda o sutun
--     istifade olunmur (max_students bosdur, limit yoxdur)
--   * MUDDETE TOXUNMUR - bitme tarixi olduğu kimi qalir
--   * idempotent: ikinci defe isledilende hec ne deyismir
--
--  NETICE: hemin muellimler ucun sagird limiti GOTURULUR (25 -> yox).
--  Yalniz xeyrinedir; hec kimin muddeti qisalmir.
-- =====================================================================

create or replace function app.sinaqlari_sagird_basina_kecir() returns int
language sql security definer set search_path = public, extensions, pg_temp as $$
  with duz as (
    update public.subscriptions s
       set plan_id = yeni.id, seats = 1
      from public.plans kohne, public.accounts a, public.plans yeni
     where kohne.id = s.plan_id
       and a.id     = s.account_id
       and kohne.slug in ('repetitor-25', 'repetitor-60', 'repetitor-acik')
       and s.status = 'trialing'
       and yeni.slug = case when a.type = 'school' then 'mekteb'
                            else 'sagird-basi' end
       and yeni.is_active
    returning 1)
  select count(*)::int from duz
$$;

revoke all on function app.sinaqlari_sagird_basina_kecir()
  from public, anon, authenticated;

do $$
declare n int;
begin
  if to_regclass('public.subscriptions') is null then
    raise exception 'ONCE 01_schema.sql isledilmelidir.';
  end if;
  n := app.sinaqlari_sagird_basina_kecir();
  raise notice '171: yeni qaydaya kecirilen sinaq/hediyye abunesi: %', n;
end $$;
