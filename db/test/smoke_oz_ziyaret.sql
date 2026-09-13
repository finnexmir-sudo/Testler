-- =====================================================================
--  smoke_oz_ziyaret.sql : adminin oz baxislari sayilmir (db/189)
--
--  Iddialar: admin paneli acanda (rpc_seen) onun ziyaret nisani
--  yadda saxlanir · hemin nisanin butun setirleri hesablamadan cixir
--  (baxis, unikal, demo) · GERIYE de isleyir - nisandan EVVEL edilen
--  baxislar da cixir · adi muellim panele girende nisan QOYULMUR
--  (onun ana sehifeye qayitmasi heqiqi siqnaldir) · «own_today» nece
--  setrin sayilmadigini deyir.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.own_vids;
delete from public.visits;
delete from public.subscriptions;
delete from public.account_members; delete from public.accounts;
delete from public.user_roles;      delete from public.profiles;
delete from auth.users;
insert into auth.users (id, email) values
  ('11110000-0000-0000-0000-0000000000a1','oz-admin@t.az'),
  ('11110000-0000-0000-0000-0000000000a2','oz-muellim@t.az');
insert into public.user_roles (user_id, role) values ('11110000-0000-0000-0000-0000000000a1','admin');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000a2','tutor','Oz hesabi','11110000-0000-0000-0000-0000000000a2');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000a2','11110000-0000-0000-0000-0000000000a2',true);

--  1. ADMININ brauzeri: once sayta baxir (hele nisan yoxdur)
set role anon;
do $$
begin
  perform set_config('request.headers',
    '{"x-forwarded-for":"5.5.5.5","user-agent":"ADMIN-UA"}', true);
  perform public.rpc_visit('home', 'view');
  perform public.rpc_visit('home', 'view');
  perform public.rpc_visit('home', 'demo_muellim');
end $$;
reset role;

--  2. BASQA ziyaretci
set role anon;
do $$
begin
  perform set_config('request.headers',
    '{"x-forwarded-for":"9.9.9.9","user-agent":"QONAQ-UA"}', true);
  perform public.rpc_visit('home', 'view');
  perform public.rpc_visit('home', 'demo_sagird');
end $$;
reset role;

do $$
declare n int;
begin
  select count(*) into n from public.visits;
  assert n = 5, 'setir sayi: ' || n;
end $$;

--  3. ADI MUELLIM panele girir - nisan QOYULMAMALIDIR
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000a2';
do $$
begin
  perform set_config('request.headers',
    '{"x-forwarded-for":"9.9.9.9","user-agent":"QONAQ-UA"}', true);
  perform public.rpc_seen();
end $$;
reset role; reset request.jwt.claim.sub;
do $$
declare n int;
begin
  select count(*) into n from public.own_vids;
  assert n = 0, 'adi muellim ucun nisan qoyuldu! ' || n;
end $$;

--  4. ADMIN panele girir - EYNI brauzerden (5.5.5.5 / ADMIN-UA)
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000a1';
do $$
begin
  perform set_config('request.headers',
    '{"x-forwarded-for":"5.5.5.5","user-agent":"ADMIN-UA"}', true);
  perform public.rpc_seen();
end $$;

--  Cedvele baxmaq ucun rol geri qaytarilir (own_vids-i yalniz sahib
--  gorur - hesablamalar security definer funksiyalarindan kecir)
reset role; reset request.jwt.claim.sub;
do $$
declare n int;
begin
  select count(*) into n from public.own_vids;
  assert n = 1, 'admin nisani qoyulmadi: ' || n;
end $$;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000a1';

--  5. Hesablama: yalniz QONAQ qalir - hem de GERIYE isleyir
do $$
declare v jsonb;
begin
  v := public.rpc_admin_visits(30);
  assert (v->'today'->>'views')::int = 1,
    'bu gun baxis (qonaq 1 olmalidir): ' || (v->'today'->>'views');
  assert (v->'today'->>'uniq')::int = 1,
    'bu gun unikal: ' || (v->'today'->>'uniq');
  assert (v->'today'->>'demo')::int = 1,
    'bu gun demo (yalniz qonagin): ' || (v->'today'->>'demo');
  assert (v->'today'->>'demo_uniq')::int = 1,
    'numuneye giren nefer: ' || (v->'today'->>'demo_uniq');
  assert (v->>'own_today')::int = 3,
    'sayilmayan oz setirlerimiz: ' || (v->>'own_today');
  assert (v->'events'->>'demo_muellim') is null,
    'adminin demo kliki hadiselerde qaldi';
  assert (v->'events'->>'demo_sagird')::int = 1, 'qonagin demo kliki itdi';
end $$;
reset role; reset request.jwt.claim.sub;

--  6. Setirler SILINMIR - yalniz sayilmir (sonra baxmaq lazim ola biler)
do $$
declare n int;
begin
  select count(*) into n from public.visits;
  assert n = 5, 'setirler silinib: ' || n;
end $$;

\echo 'OK  1 · admin nisani qoyulur, oz setirleri sayilmir (geriye de), adi muellime toxunulmur'

--  7. (190) 2FA KILIDI BAGLI - nisan YENE qoyulmalidir.
--  Canli olcu 2026-09-13: admin_ok() kilid teleb edirdi, rpc_seen kod
--  yazilmazdan evvel cagirilir - adminin oz telefonu qonaq sayildi.
insert into public.admin_totp (user_id, secret, enabled)
  values ('11110000-0000-0000-0000-0000000000a1', '\x00'::bytea, true);
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000a1';
do $$
declare kilid boolean;
begin
  perform set_config('request.headers',
    '{"x-forwarded-for":"6.6.6.6","user-agent":"ADMIN-UA2"}', true);
  --  kilid heqiqeten baglidir?
  begin
    perform public.rpc_admin_visits(30); kilid := false;
  exception when insufficient_privilege then kilid := true;
  end;
  assert kilid, '2FA kilidi bagli deyil - test menasizdir';
  perform public.rpc_seen();
end $$;
reset role; reset request.jwt.claim.sub;
do $$
declare n int;
begin
  select count(*) into n from public.own_vids;
  assert n = 2, 'kilid bagli olanda nisan qoyulmadi: ' || n;
end $$;

--  8. (190) REQEMLERE BAXAN ANDA nisan: ucuncu brauzer (IP deyisib)
--  evvel sayta baxir, sonra kilidi acib panele girir - oz baxislari
--  hemin sorguda artiq sayilmir.
set role anon;
do $$
begin
  perform set_config('request.headers',
    '{"x-forwarded-for":"7.7.7.7","user-agent":"ADMIN-UA3"}', true);
  perform public.rpc_visit('home', 'view');
  perform public.rpc_visit('home', 'view');
end $$;
reset role;
insert into public.admin_unlocks (user_id, unlocked_until)
  values ('11110000-0000-0000-0000-0000000000a1', now() + interval '1 hour');
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000a1';
do $$
declare v jsonb;
begin
  perform set_config('request.headers',
    '{"x-forwarded-for":"7.7.7.7","user-agent":"ADMIN-UA3"}', true);
  v := public.rpc_admin_visits(30);
  assert (v->'today'->>'views')::int = 1,
    'ucuncu brauzerin baxislari sayildi: ' || (v->'today'->>'views');
  assert (v->'today'->>'uniq')::int = 1,
    'bu gun unikal (yalniz qonaq): ' || (v->'today'->>'uniq');
  assert (v->>'own_today')::int = 5,
    'sayilmayan oz setirlerimiz (3+2): ' || (v->>'own_today');
end $$;
reset role; reset request.jwt.claim.sub;
do $$
declare n int;
begin
  select count(*) into n from public.own_vids;
  assert n = 3, 'baxan anda nisan qoyulmadi: ' || n;
end $$;

--  9. Adi muellim 190-dan sonra da nisanlanmir
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000a2';
do $$
begin
  perform set_config('request.headers',
    '{"x-forwarded-for":"8.8.8.8","user-agent":"MUELLIM-UA"}', true);
  perform public.rpc_seen();
end $$;
reset role; reset request.jwt.claim.sub;
do $$
declare n int;
begin
  select count(*) into n from public.own_vids;
  assert n = 3, 'adi muellim nisanlandi: ' || n;
end $$;

\echo 'OK  2 · 190: nisan 2FA kilidinden asili deyil, reqemlere baxan anda cari cihaz nisanlanir, adi muellim yene toxunulmur'
