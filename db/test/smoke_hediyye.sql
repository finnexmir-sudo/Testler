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
  assert app.account_seat_limit(acc) = 25, 'yer limiti 25 deyil';
  c := public.rpc_my_context();
  pl := c->'accounts'->0->'plan';
  assert pl->>'status' = 'trialing' and pl->>'provider' = 'gift' and pl->>'ends' is not null, 'my_context.plan tam deyil: ' || pl::text;
end $$;
\echo 'OK  1 · repetitor qeydiyyati: hediyye abune, HEMISE 30 gun, my_context'

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
