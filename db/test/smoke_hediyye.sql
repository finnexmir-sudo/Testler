-- =====================================================================
--  smoke_hediyye.sql : qosulana hediyye paket (db/160)
--
--  Iddialar: ayar aciq + repetitor -> trialing/gift abune, muddet
--  HEMISE 'days' gun (168) · teklif tarixi kecibse hediyye YOXDUR ·
--  valideyn hesabina yox · ayar
--  bagli -> yox · my_context.plan status/ends/provider · admin ayari
--  oxuyur/yazir, adi muellim yox · gelire dusmur.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.subscriptions;
delete from public.account_members; delete from public.accounts;
delete from public.user_roles;      delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-00000000f0a1','hed-admin@t.az','{"full_name":"Hediyye Admin"}'),
  ('11110000-0000-0000-0000-00000000f0a2','hed-tutor@t.az','{"full_name":"Yeni Repetitor"}'),
  ('11110000-0000-0000-0000-00000000f0a3','hed-parent@t.az','{"full_name":"Valideyn"}'),
  ('11110000-0000-0000-0000-00000000f0a4','hed-late@t.az','{"full_name":"Gec Gelen"}'),
  ('11110000-0000-0000-0000-00000000f0a5','hed-off@t.az','{"full_name":"Ayar Bagli"}');
insert into public.user_roles (user_id, role) values ('11110000-0000-0000-0000-00000000f0a1','admin');
update public.app_state set val = jsonb_build_object('on', true, 'days', 30, 'beta_until', (current_date + 90)::text)
 where key = 'hediyye';

-- =====================================================================
--  1. Repetitor qeydiyyati: hediyye abune, bitme = beta gununun sonu
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-00000000f0a2';
do $$
declare v jsonb; c jsonb; acc uuid; e timestamptz; pl jsonb;
begin
  v := public.rpc_create_account('tutor', 'Yeni repetitor');
  acc := (v->>'id')::uuid;
  select current_period_end into e from public.subscriptions where account_id = acc;
  assert e is not null, 'hediyye abune yaranmadi';
  assert (select status from public.subscriptions where account_id = acc) = 'trialing', 'status trialing deyil';
  assert (select provider from public.subscriptions where account_id = acc) = 'gift', 'provider gift deyil';
  --  168: muddet HEMISE 'days' gundur.  Evvel beta tarixine uzanirdi -
  --  sentyabrda qosulan muellim 30 gun evezine 114 gun alirdi.
  assert e > now() + interval '29 days' and e < now() + interval '31 days',
    'hediyye 30 gun deyil (beta tarixine uzanib?): ' || e::text;
  --  169: hediyye = odenisli mehsulun ozu - LIMITSIZ, 'repetitor-25' yox.
  --  Evvel pulsuz ay odenisli mehsuldan daha mehdud idi (25 yer).
  assert (select pl.slug from public.subscriptions s2
            join public.plans pl on pl.id = s2.plan_id
           where s2.account_id = acc) = 'sagird-basi',
    'hediyye plani sagird-basi deyil';
  assert app.account_seat_limit(acc) = 2147483647, 'hediyye ayinda sagird limiti olmamalidir';
  c := public.rpc_my_context();
  pl := c->'accounts'->0->'plan';
  assert pl->>'status' = 'trialing' and pl->>'provider' = 'gift' and pl->>'ends' is not null, 'my_context.plan tam deyil: ' || pl::text;
end $$;
\echo 'OK  1 · hediyye: sagird-basi plani, limitsiz, HEMISE 30 gun, my_context'

-- =====================================================================
--  2. Valideyn hesabina hediyye yoxdur
-- =====================================================================
set request.jwt.claim.sub = '11110000-0000-0000-0000-00000000f0a3';
do $$
declare v jsonb;
begin
  v := public.rpc_create_account('parent', 'Valideyn hesabi');
  assert not exists (select 1 from public.subscriptions where account_id = (v->>'id')::uuid), 'valideyne hediyye verildi';
end $$;
\echo 'OK  2 · valideyn hesabina hediyye yoxdur'

-- =====================================================================
--  3. (168) Teklif tarixi kecib: hediyye VERILMIR
--  Evvel bu halda 30 gun verilirdi.  Yeni qayda (istifadeci):
--  "il sonuna kimi yeni muellimler bir ay pulsuz alir" - tarix
--  kecdikden sonra teklif bitir.
-- =====================================================================
reset role; reset request.jwt.claim.sub;
update public.app_state set val = val || jsonb_build_object('beta_until', (current_date - 1)::text) where key = 'hediyye';
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-00000000f0a4';
do $$
declare v jsonb; e timestamptz;
begin
  v := public.rpc_create_account('tutor', 'Gec gelen');
  select current_period_end into e from public.subscriptions where account_id = (v->>'id')::uuid;
  assert e is null, 'teklif tarixi kecib, hediyye verilmemelidir: ' || coalesce(e::text, '-');
  assert app.account_seat_limit((v->>'id')::uuid) = 5, 'pulsuz hedde dusmedi';
end $$;
\echo 'OK  3 · teklif tarixi kecende hediyye verilmir, pulsuz hedd 5'

-- =====================================================================
--  4. Ayar bagli: hediyye yoxdur, pulsuz hedd 5
-- =====================================================================
reset role; reset request.jwt.claim.sub;
update public.app_state set val = val || jsonb_build_object('on', false) where key = 'hediyye';
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-00000000f0a5';
do $$
declare v jsonb;
begin
  v := public.rpc_create_account('tutor', 'Ayar bagli');
  assert not exists (select 1 from public.subscriptions where account_id = (v->>'id')::uuid), 'ayar bagli olsa da hediyye verildi';
  assert app.account_seat_limit((v->>'id')::uuid) = 5, 'pulsuz hedd 5 deyil';
end $$;
\echo 'OK  4 · ayar bagli: hediyye yoxdur, pulsuz hedd 5'

-- =====================================================================
--  5. Admin ayari oxuyur/yazir; adi muellim yox; gelir sifir
-- =====================================================================
do $$
declare bad boolean := false;
begin
  begin perform public.rpc_admin_hediyye(); exception when insufficient_privilege then bad := true; end;
  assert bad, 'adi muellim hediyye ayarini gordu';
end $$;
set request.jwt.claim.sub = '11110000-0000-0000-0000-00000000f0a1';
do $$
declare v jsonb; st jsonb; bad boolean := false;
begin
  v := public.rpc_admin_hediyye();
  assert (v->>'on')::boolean = false, 'oxu sehv';
  v := public.rpc_admin_hediyye(true, 45, (current_date + 10)::date);
  assert (v->>'on')::boolean and (v->>'days')::int = 45 and v->>'beta_until' = (current_date + 10)::text, 'yazma sehv: ' || v::text;
  v := public.rpc_admin_hediyye(null, null, null, true);
  assert v->>'beta_until' is null, 'beta temizlenmedi';
  begin perform public.rpc_admin_hediyye(null, 0); bad := false; exception when others then bad := true; end;
  assert bad, 'gun heddi yoxlanmir';
  st := public.rpc_admin_stats();
  assert (st->>'mrr_minor')::int = 0 and (st->>'paid_accounts')::int = 0, 'hediyye gelire dusdu';
  --  168: yalniz 1-ci hesab hediyye aldi (3-cude teklif tarixi kecmisdi)
  assert (st->>'trial_accounts')::int = 1, 'sinaq sayi 1 deyil: ' || (st->>'trial_accounts');
end $$;
reset role; reset request.jwt.claim.sub;
\echo 'OK  5 · admin ayari oxuyur/yazir, adi muellim yox, gelir sifir'

-- =====================================================================
--  6. (170) Sehven uzun verilmis hediyye qaydaya salinir
--  Yalniz hediyye + sinaq setirleri, yalniz HEQIQETEN uzun olanlar;
--  odenisli abuneye toxunmur, tekrar isledilende deyismir.
-- =====================================================================
reset role; reset request.jwt.claim.sub;
delete from public.subscriptions;
update public.app_state set val = jsonb_build_object('on', true, 'days', 30,
       'beta_until', (current_date + 90)::text) where key = 'hediyye';

--  a) sehv setir: 9 sentyabrda baslayib, 1 yanvara kimi verilib
insert into public.subscriptions (account_id, plan_id, status, seats,
                                  started_at, current_period_end, provider)
select (select id from public.accounts order by created_at limit 1), p.id,
       'trialing', 1, timestamptz '2026-09-09 06:00+00',
       timestamptz '2027-01-01 00:00+00', 'gift'
  from public.plans p where p.slug = 'sagird-basi';
--  b) odenisli abune - UZUN olsa da toxunulmamalidir
insert into public.subscriptions (account_id, plan_id, status, seats,
                                  started_at, current_period_end, provider)
select (select id from public.accounts order by created_at limit 1), p.id,
       'active', 1, timestamptz '2026-09-09 06:00+00',
       timestamptz '2027-06-01 00:00+00', 'manual'
  from public.plans p where p.slug = 'sagird-basi';

do $$
declare n int; e timestamptz; e2 timestamptz;
begin
  n := app.hediyye_uzun_duzelt();
  assert n = 1, 'duzelen setir sayi 1 deyil: ' || n;
  select current_period_end into e from public.subscriptions where provider = 'gift';
  assert e = timestamptz '2026-09-09 06:00+00' + interval '30 days',
    'hediyye qeydiyyat aninden +30 gun olmadi: ' || e::text;
  select current_period_end into e2 from public.subscriptions where provider = 'manual';
  assert e2 = timestamptz '2027-06-01 00:00+00', 'odenisli abuneye toxunuldu';
  --  idempotent: ikinci defe hec ne deyismir
  n := app.hediyye_uzun_duzelt();
  assert n = 0, 'tekrar isletmede yene deyisdi: ' || n;
  select current_period_end into e from public.subscriptions where provider = 'gift';
  assert e = timestamptz '2026-09-09 06:00+00' + interval '30 days',
    'tekrar isletme tarixi pozdu';
end $$;
\echo 'OK  6 · (170) uzun hediyye qeydiyyat + 30 gune salinir, odenisliye toxunmur'

-- =====================================================================
--  7. (171) Kohne sinaq/hediyye abuneleri yeni qaydaya kecir
--  169 yalniz YENI hediyyeni deyisdi; artiq verilmis setirler
--  'repetitor-25'-de qalirdi - "7 / 25 sagird yeri" gorunurdu.
--  Pullu abuneye TOXUNMAMALIDIR, muddet DEYISMEMELIDIR.
-- =====================================================================
reset role; reset request.jwt.claim.sub;
delete from public.subscriptions;

--  a) hediyye/sinaq setri kohne paketde
insert into public.subscriptions (account_id, plan_id, status, seats,
                                  started_at, current_period_end, provider)
select (select id from public.accounts order by created_at limit 1), p.id,
       'trialing', 25, now() - interval '1 day', now() + interval '20 days', 'gift'
  from public.plans p where p.slug = 'repetitor-25';
--  b) ODENISLI setr kohne paketde - toxunulmamalidir
insert into public.subscriptions (account_id, plan_id, status, seats,
                                  started_at, current_period_end, provider)
select (select id from public.accounts order by created_at offset 1 limit 1), p.id,
       'active', 25, now() - interval '1 day', now() + interval '40 days', 'manual'
  from public.plans p where p.slug = 'repetitor-25';

do $$
declare n int; v_acc uuid; e0 timestamptz; e1 timestamptz;
begin
  select account_id, current_period_end into v_acc, e0
    from public.subscriptions where provider = 'gift';

  n := app.sinaqlari_sagird_basina_kecir();
  assert n = 1, 'kecirilen setir sayi 1 deyil: ' || n;

  --  sinaq setri artiq 'sagird-basi'-dedir ve LIMITSIZDIR
  assert (select pl.slug from public.subscriptions s
            join public.plans pl on pl.id = s.plan_id
           where s.provider = 'gift') = 'sagird-basi',
    'sinaq setri sagird-basina kecmedi';
  assert app.account_seat_limit(v_acc) = 2147483647,
    'sagird limiti hele qalir: ' || app.account_seat_limit(v_acc);
  --  muddete toxunulmayib
  select current_period_end into e1 from public.subscriptions where provider = 'gift';
  assert e1 = e0, 'muddet deyisdi';

  --  ODENISLI setr kohne paketde qalir (169 qaydasi)
  assert (select pl.slug from public.subscriptions s
            join public.plans pl on pl.id = s.plan_id
           where s.provider = 'manual') = 'repetitor-25',
    'odenisli abune de kocuruldu - buna icaze yoxdur';

  --  idempotent
  n := app.sinaqlari_sagird_basina_kecir();
  assert n = 0, 'tekrar isletmede yene deyisdi: ' || n;
end $$;
\echo 'OK  7 · (171) kohne sinaqlar sagird-basina kecir, odenisli toxunulmur'
