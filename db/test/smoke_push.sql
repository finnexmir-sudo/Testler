-- =====================================================================
--  smoke_push.sql : 910 - push abunelik, novbe, qaydalar, gonderici RPC-leri
--  Hamisi tranzaksiyada, sonda GERI alinir.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;
begin;

insert into auth.users (id, email) values
  ('11110000-0000-0000-0000-0000000005a1', 'push@t.az'),
  ('11110000-0000-0000-0000-0000000005a2', 'pushdemo@t.az');
insert into public.accounts (id, type, name, owner_id, is_demo) values
  ('aaaa0000-0000-0000-0000-0000000005a1', 'tutor', 'Push', '11110000-0000-0000-0000-0000000005a1', false),
  ('aaaa0000-0000-0000-0000-0000000005a2', 'tutor', 'Push demo', '11110000-0000-0000-0000-0000000005a2', true);
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000005a1', '11110000-0000-0000-0000-0000000005a1', true),
  ('aaaa0000-0000-0000-0000-0000000005a2', '11110000-0000-0000-0000-0000000005a2', true);
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-0000000005a1', p.id, 'trialing', now() + interval '20 days'
  from public.plans p where p.slug = 'sagird-basi';
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-0000000005a1', 'aaaa0000-0000-0000-0000-0000000005a1', '11110000-0000-0000-0000-0000000005a1', 'tutor_group', 'Push sinif', 'PSH00001'),
  ('cccc0000-0000-0000-0000-0000000005a2', 'aaaa0000-0000-0000-0000-0000000005a2', '11110000-0000-0000-0000-0000000005a2', 'tutor_group', 'Demo sinif', 'PSH00002');
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code) values
  ('5555000a-0000-0000-0000-0000000005a1', 'aaaa0000-0000-0000-0000-0000000005a1', 'cccc0000-0000-0000-0000-0000000005a1', '11110000-0000-0000-0000-0000000005a1', 'Aysu A', 'Aysu A.', 'PSHSTU01'),
  ('5555000a-0000-0000-0000-0000000005a2', 'aaaa0000-0000-0000-0000-0000000005a1', 'cccc0000-0000-0000-0000-0000000005a1', '11110000-0000-0000-0000-0000000005a1', 'Bəhruz B', 'Bəhruz B.', 'PSHSTU02'),
  ('5555000a-0000-0000-0000-0000000005a3', 'aaaa0000-0000-0000-0000-0000000005a2', 'cccc0000-0000-0000-0000-0000000005a2', '11110000-0000-0000-0000-0000000005a2', 'Demo D', 'Demo D.', 'PSHSTU03');
--  sessiyalar: tokenin ozu deyil, ozeti saxlanir
insert into public.student_sessions (token_hash, student_id, expires_at) values
  (app.hash_token('tokA'), '5555000a-0000-0000-0000-0000000005a1', now() + interval '1 day'),
  (app.hash_token('tokB'), '5555000a-0000-0000-0000-0000000005a2', now() + interval '1 day'),
  (app.hash_token('tokD'), '5555000a-0000-0000-0000-0000000005a3', now() + interval '1 day'),
  (app.hash_token('tokX'), '5555000a-0000-0000-0000-0000000005a1', now() - interval '1 hour');   -- vaxti kecib
insert into public.parent_sessions (token_hash, student_id, expires_at) values
  (app.hash_token('parA'), '5555000a-0000-0000-0000-0000000005a1', now() + interval '10 days');
update public.app_state set val = '{"on": false}' where key = 'hesab_bagli';

-- ------------------------------------------------ 1 · unvan yoxlamasi (SSRF)
do $$
begin
  assert app.push_host_ok('https://fcm.googleapis.com/fcm/send/abc:APA91b-_x'), 'fcm';
  assert app.push_host_ok('https://updates.push.services.mozilla.com/wpush/v2/gAAAAAB'), 'mozilla';
  assert app.push_host_ok('https://web.push.apple.com/QJ4_x-abc'), 'apple web';
  assert app.push_host_ok('https://api.sandbox.push.apple.com/3/device/abc'), 'apple sub';
  assert app.push_host_ok('https://wns2-par02p.notify.windows.com/w/?token=BQYAAAB%2b&x=1'), 'windows';
  assert not app.push_host_ok('http://fcm.googleapis.com/fcm/send/abcdefgh'), 'http yox';
  assert not app.push_host_ok('https://evil.com/fcm.googleapis.com/abcdefghij'), 'basqa host';
  assert not app.push_host_ok('https://fcm.googleapis.com.evil.com/fcm/send/abcd'), 'alt-domen aldatmasi';
  assert not app.push_host_ok('https://fcm.googleapis.com@evil.com/fcm/send/abcd'), '@ ile aldatma';
  assert not app.push_host_ok('https://evilpush.apple.com.evil.com/x1234567890'), 'apple aldatma';
  assert not app.push_host_ok('https://127.0.0.1/fcm/send/abcdefghijk'), 'ip';
  assert not app.push_host_ok('https://localhost/abcdefghijklmnop'), 'localhost';
  assert not app.push_host_ok(null), 'null';
  assert not app.push_host_ok('https://fcm.googleapis.com/' || repeat('a', 1000)), 'cox uzun';
end $$;

-- ------------------------------------------- 2 · gece sakitliyi (Baki vaxti)
do $$
begin
  assert app.push_quiet_next('2026-10-05 12:00:00+04') = '2026-10-05 12:00:00+04'::timestamptz, 'gunorta olduğu kimi';
  assert app.push_quiet_next('2026-10-05 10:00:00+04') = '2026-10-05 10:00:00+04'::timestamptz, '10:00 serhedi (artiq sakit deyil)';
  assert app.push_quiet_next('2026-10-05 09:59:00+04') = '2026-10-05 10:00:00+04'::timestamptz, '09:59 -> 10:00';
  assert app.push_quiet_next('2026-10-05 08:00:00+04') = '2026-10-05 10:00:00+04'::timestamptz, '08:00 -> 10:00 (evvel buraxilirdi)';
  assert app.push_quiet_next('2026-10-05 20:59:00+04') = '2026-10-05 20:59:00+04'::timestamptz, '20:59 serhedi';
  assert app.push_quiet_next('2026-10-05 21:00:00+04') = '2026-10-06 10:00:00+04'::timestamptz, '21:00 -> sabah 10:00';
  assert app.push_quiet_next('2026-10-05 23:30:00+04') = '2026-10-06 10:00:00+04'::timestamptz, '23:30 -> sabah 10:00';
  assert app.push_quiet_next('2026-10-05 03:15:00+04') = '2026-10-05 10:00:00+04'::timestamptz, '03:15 -> eyni gun 10:00';
  assert app.push_quiet_next('2026-10-05 17:30:00+00') = '2026-10-06 10:00:00+04'::timestamptz, 'UTC 17:30 = Baki 21:30';
end $$;

-- ------------------------------------------------ 3 · abune ol (brauzer, anon)
set role anon;
do $$
declare
  ep  text := 'https://fcm.googleapis.com/fcm/send/ENDPOINT-A-aaaaaaaaaaaaaaaaaaaa';
  pk  text := repeat('B', 87);
  au  text := repeat('c', 22);
  r   jsonb;
  n   int;
  ok_ boolean;
begin
  r := public.rpc_push_subscribe('tokA', 'student', ep, pk, au, 'Test UA');
  assert (r->>'ok')::boolean, 'abune ol';
  r := public.rpc_push_subscribe('tokA', 'student', ep, pk, au, 'Test UA 2');     -- tekrar - idempotent
  --  tekrar abune: setir sayi asagida (rol sifirlandiqdan sonra) yoxlanir - anon cedvele toxuna bilmir

  --  etibarsiz / vaxti kecmis token
  begin perform public.rpc_push_subscribe('yanlis', 'student', ep, pk, au); assert false, 'yanlis token';
  exception when sqlstate '42501' then null; end;
  begin perform public.rpc_push_subscribe('tokX', 'student', ep, pk, au); assert false, 'vaxti kecmis token';
  exception when sqlstate '42501' then null; end;
  --  rol ve token uygunsuzluqu: sagird tokeni ile valideyn abunesi OLMAZ
  begin perform public.rpc_push_subscribe('tokA', 'parent', ep, pk, au); assert false, 'rol uygunsuzluqu';
  exception when sqlstate '42501' then null; end;
  begin perform public.rpc_push_subscribe('tokA', 'admin', ep, pk, au); assert false, 'yanlis rol';
  exception when sqlstate '22023' then null; end;
  --  pis unvan / acar
  begin perform public.rpc_push_subscribe('tokA', 'student', 'https://evil.com/fcm/send/aaaaaaaaaaaaaaaa', pk, au); assert false, 'pis unvan';
  exception when sqlstate '22023' then null; end;
  begin perform public.rpc_push_subscribe('tokA', 'student', ep, 'qisa', au); assert false, 'qisa p256dh';
  exception when sqlstate '22023' then null; end;
  begin perform public.rpc_push_subscribe('tokA', 'student', ep, pk, 'x'); assert false, 'qisa auth';
  exception when sqlstate '22023' then null; end;

  --  numune hesab: saxlanmir
  r := public.rpc_push_subscribe('tokD', 'student', ep, pk, au);
  assert (r->>'demo')::boolean, 'numune hesab';

  --  valideyn de eyni endpoint ile abune ola bilir (eyni telefon)
  r := public.rpc_push_subscribe('parA', 'parent', ep, pk, au);
  assert (r->>'ok')::boolean, 'valideyn abunesi';

  --  cihaz limiti: en cox 10
  for i in 1..12 loop
    perform public.rpc_push_subscribe('tokB', 'student',
      'https://fcm.googleapis.com/fcm/send/DEV' || lpad(i::text, 12, '0') || 'xxxxxxxxxxxxxxxx', pk, au);
  end loop;
end $$;
reset role;
do $$
declare n int;
begin
  select count(*) into n from public.push_subs where student_id = '5555000a-0000-0000-0000-0000000005a2';
  assert n = 10, 'cihaz limiti 10: ' || n;
  select count(*) into n from public.push_subs where student_id = '5555000a-0000-0000-0000-0000000005a3';
  assert n = 0, 'numune hesabda abune yoxdur';
  select count(*) into n from public.push_subs where student_id = '5555000a-0000-0000-0000-0000000005a1';
  assert n = 2, 'sagird A: 1 sagird + 1 valideyn: ' || n;
end $$;

-- ------------------------------------------------ 4 · abunelikden cix
set role anon;
do $$
declare r jsonb; ep text := 'https://fcm.googleapis.com/fcm/send/ENDPOINT-A-aaaaaaaaaaaaaaaaaaaa';
begin
  r := public.rpc_push_unsubscribe('yanlis', 'student', ep);                 -- etibarsiz sessiya: hec ne silinmir
  assert (r->>'removed')::int = 0, 'etibarsiz sessiya silmemelidir';
  r := public.rpc_push_unsubscribe('tokB', 'student', ep);                   -- BASQA sagirdin tokeni
  assert (r->>'removed')::int = 0, 'basqasinin abunesi silinmemelidir';
  r := public.rpc_push_unsubscribe('parA', 'parent', ep);
  assert (r->>'removed')::int = 1, 'valideyn oz abunesini silir';
  r := public.rpc_push_unsubscribe('tokA', 'student', ep);
  assert (r->>'removed')::int = 1, 'sagird oz abunesini silir';
  --  yeniden abune ol (novbe sinaqlari ucun)
  perform public.rpc_push_subscribe('tokA', 'student', ep, repeat('B', 87), repeat('c', 22));
  perform public.rpc_push_subscribe('parA', 'parent', ep, repeat('B', 87), repeat('c', 22));
end $$;
--  anon cedvellere ve gonderici RPC-lerine toxuna bilmir
do $$
begin
  begin perform 1 from public.push_subs limit 1; assert false, 'anon push_subs oxuya bilmemelidir';
  exception when insufficient_privilege then null; end;
  begin perform public.rpc_push_claim(10); assert false, 'anon rpc_push_claim cagira bilmemelidir';
  exception when insufficient_privilege then null; end;
  begin perform public.rpc_push_done('[]'::jsonb); assert false, 'anon rpc_push_done cagira bilmemelidir';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
set role authenticated;
do $$
begin
  begin perform public.rpc_push_claim(10); assert false, 'authenticated rpc_push_claim';
  exception when insufficient_privilege then null; end;
end $$;
reset role;

-- ------------------------------------------------ 5 · novbeye yazma qaydalari
do $$
declare
  A uuid := '5555000a-0000-0000-0000-0000000005a1';
  B uuid := '5555000a-0000-0000-0000-0000000005a2';
  i1 bigint; i2 bigint; i3 bigint; i4 bigint; n int; sa timestamptz;
begin
  --  oldurme duymesi sonukdur
  assert app.push_enqueue('student', A, 'yeni_test', 'k1', 'T', 'B') is null, 'duyme sonukken novbeye yazilmamalidir';
  update public.app_state set val = '{"on": true}' where key = 'push';

  --  abunesi olmayan (A-nin ozu var, B-nin de var: 10 cihaz) - basqa sagird
  assert app.push_enqueue('student', '5555000a-0000-0000-0000-0000000005a3', 'yeni_test', 'k0', 'T', 'B') is null,
         'abunesi olmayan alici ucun yazilmamalidir';

  i1 := app.push_enqueue('student', A, 'yeni_test', 'k1', 'Bil10 · Yeni test', 'Test var', './');
  assert i1 is not null, 'novbeye yazilmalidir';
  assert app.push_enqueue('student', A, 'yeni_test', 'k1', 'T', 'B') is null, 'eyni dedupe_key tekrar yazilmamalidir';

  --  gunluk hedd: 2 bildiris (test istisnadir)
  i2 := app.push_enqueue('student', A, 'son_tarix', 'k2', 'T2', 'B2');
  assert i2 is not null, 'ikinci bildiris';
  assert app.push_enqueue('student', A, 'gundelik', 'k3', 'T3', 'B3') is null, 'ucuncu bildiris - gunluk hedd';
  i3 := app.push_enqueue('student', A, 'test', 'k4', 'Sinaq', 'Isleyir');
  assert i3 is not null, 'kind=test heddi kecir';
  --  valideyn ayrica hesablanir
  i4 := app.push_enqueue('parent', A, 'yeni_test', 'p1', 'Aysu A. üçün yeni test', 'B');
  assert i4 is not null, 'valideyn ayri say';

  --  gece sakitliyi: kind='test' DERHAL, qalani sakit saata gore
  select send_after into sa from public.push_outbox where id = i3;
  assert sa <= now() + interval '1 second', 'kind=test derhal';
  select send_after into sa from public.push_outbox where id = i1;
  assert sa = app.push_quiet_next(sa), 'gonderme vaxti sakit saata dusmur';
  assert extract(hour from (sa at time zone 'Asia/Baku')) between 10 and 20 or sa >= now(), 'sakit saat';

end $$;

-- ------------------------------------- 5b · qapali hesab (905) ve gundelik
do $$
declare A uuid := '5555000a-0000-0000-0000-0000000005a1';
begin
  delete from public.push_outbox where role = 'student' and student_id = A;     -- gunluk say sifirlanir
  update public.app_state set val = '{"on": true}' where key = 'hesab_bagli';
  delete from public.subscriptions where account_id = 'aaaa0000-0000-0000-0000-0000000005a1';
  assert app.account_locked('aaaa0000-0000-0000-0000-0000000005a1'), 'hazirliq: hesab qapali olmalidir';
  assert app.push_enqueue('student', A, 'gundelik', 'g1', 'T', 'B') is null, 'qapali hesabda gundelik yazilmir';
  assert app.push_enqueue('student', A, 'son_tarix', 'g2', 'T', 'B') is not null,
         'qapali hesabda verilmis testin son tarixi yazilir (tapsiriqlar qalir)';
  update public.app_state set val = '{"on": false}' where key = 'hesab_bagli';
end $$;

-- ------------------------------------- 6 · gonderici: claim / done (service_role)
delete from public.push_outbox;
insert into public.push_outbox (role, student_id, kind, dedupe_key, title, body, send_after) values
  ('student', '5555000a-0000-0000-0000-0000000005a1', 'yeni_test', 'c1', 'T1', 'B1', now() - interval '1 minute'),
  ('student', '5555000a-0000-0000-0000-0000000005a1', 'yeni_test', 'c2', 'T2', 'B2', now() + interval '1 hour'),   -- hele erken
  ('student', '5555000a-0000-0000-0000-0000000005a3', 'yeni_test', 'c3', 'T3', 'B3', now() - interval '1 minute'); -- abunesi yoxdur
create temp table _r (k text, j jsonb);
grant all on _r to service_role;

set role service_role;
do $$
declare r jsonb;
begin
  r := public.rpc_push_claim(50);
  insert into _r values ('claim1', r);
  r := public.rpc_push_claim(50);                      -- 5 deqiqe erzinde ikinci defe VERILMIR
  insert into _r values ('claim2', r);
end $$;
reset role;
do $$
declare r jsonb;
begin
  select j into r from _r where k = 'claim1';
  assert jsonb_array_length(r) = 1, 'yalniz hazir ve abunesi olan: ' || r::text;
  assert r->0->>'title' = 'T1' and jsonb_array_length(r->0->'subs') = 1, 'basliq/abune: ' || r::text;
  assert (r->0->'subs'->0->>'endpoint') like 'https://fcm.googleapis.com/%', 'abune unvani';
  select j into r from _r where k = 'claim2';
  assert jsonb_array_length(r) = 0, 'ikinci claim bos olmalidir';
  assert (select status from public.push_outbox where dedupe_key = 'c3') = 'skipped', 'abunesiz setir skipped';
  assert (select status from public.push_outbox where dedupe_key = 'c2') = 'pending', 'gelecek setire toxunulmur';
  assert (select attempts from public.push_outbox where dedupe_key = 'c1') = 1, 'cehd sayi';
end $$;

-- oldurme duymesi sonuk: claim bos qaytarir
update public.app_state set val = '{"on": false}' where key = 'push';
update public.push_outbox set claimed_at = null, send_after = now() - interval '1 minute' where dedupe_key = 'c1';
set role service_role;
do $$ begin insert into _r values ('off', public.rpc_push_claim(50)); end $$;
reset role;
do $$ begin
  assert jsonb_array_length((select j from _r where k = 'off')) = 0, 'sonuk duymede claim bos olmalidir';
end $$;
update public.app_state set val = '{"on": true}' where key = 'push';

-- done: ugurlu
set role service_role;
do $$
declare r jsonb; sid text;
begin
  r := public.rpc_push_claim(50);
  sid := r->0->'subs'->0->>'id';
  perform public.rpc_push_done(jsonb_build_array(jsonb_build_object('id', (r->0->>'id')::bigint, 'ok', jsonb_build_array(sid))));
end $$;
reset role;
do $$ begin
  assert (select status from public.push_outbox where dedupe_key = 'c1') = 'sent', 'ugurlu: sent';
  assert (select sent_at from public.push_outbox where dedupe_key = 'c1') is not null, 'sent_at';
  assert (select count(*) from public.push_subs where last_ok_at is not null) = 1, 'last_ok_at';
end $$;

-- done: ABUNE OLU (404/410) -> abune silinir, bildiris skipped
insert into public.push_outbox (role, student_id, kind, dedupe_key, title, body, send_after)
values ('parent', '5555000a-0000-0000-0000-0000000005a1', 'yeni_test', 'c4', 'T4', 'B4', now() - interval '1 minute');
set role service_role;
do $$
declare r jsonb; sid text;
begin
  r := public.rpc_push_claim(50);
  assert jsonb_array_length(r) = 1 and r->0->>'title' = 'T4', 'valideyn bildirisi claim';
  sid := r->0->'subs'->0->>'id';
  perform public.rpc_push_done(jsonb_build_array(jsonb_build_object('id', (r->0->>'id')::bigint, 'dead', jsonb_build_array(sid), 'error', 'HTTP 410')));
end $$;
reset role;
do $$ begin
  assert (select status from public.push_outbox where dedupe_key = 'c4') = 'skipped', 'olu abune: skipped';
  assert (select count(*) from public.push_subs where role = 'parent'
           and student_id = '5555000a-0000-0000-0000-0000000005a1') = 0, 'olu abune silinmelidir';
end $$;

-- done: kecici xeta -> yeniden cehd (gecikmeli), 3 cehddən sonra failed
insert into public.push_outbox (role, student_id, kind, dedupe_key, title, body, send_after)
values ('student', '5555000a-0000-0000-0000-0000000005a1', 'yeni_test', 'c5', 'T5', 'B5', now() - interval '1 minute');
set role service_role;
do $$
declare r jsonb; sid text;
begin
  r := public.rpc_push_claim(50);
  assert jsonb_array_length(r) = 1 and r->0->>'title' = 'T5', '1. cehd claim: ' || r::text;
  sid := r->0->'subs'->0->>'id';
  perform public.rpc_push_done(jsonb_build_array(jsonb_build_object('id', (r->0->>'id')::bigint, 'failed', jsonb_build_array(sid), 'error', 'HTTP 503')));
end $$;
reset role;
do $$ begin
  assert (select status from public.push_outbox where dedupe_key = 'c5') = 'pending', '1: pending olmalidir';
  assert (select send_after from public.push_outbox where dedupe_key = 'c5') > now(), '1: gecikdirilmelidir';
end $$;
update public.push_outbox set send_after = now() - interval '1 minute' where dedupe_key = 'c5';   -- vaxti cekmek
set role service_role;
do $$
declare r jsonb; sid text;
begin
  r := public.rpc_push_claim(50);
  assert jsonb_array_length(r) = 1 and r->0->>'title' = 'T5', '2. cehd claim: ' || r::text;
  sid := r->0->'subs'->0->>'id';
  perform public.rpc_push_done(jsonb_build_array(jsonb_build_object('id', (r->0->>'id')::bigint, 'failed', jsonb_build_array(sid), 'error', 'HTTP 503')));
end $$;
reset role;
do $$ begin
  assert (select status from public.push_outbox where dedupe_key = 'c5') = 'pending', '2: pending olmalidir';
  assert (select send_after from public.push_outbox where dedupe_key = 'c5') > now(), '2: gecikdirilmelidir';
end $$;
update public.push_outbox set send_after = now() - interval '1 minute' where dedupe_key = 'c5';   -- vaxti cekmek
set role service_role;
do $$
declare r jsonb; sid text;
begin
  r := public.rpc_push_claim(50);
  assert jsonb_array_length(r) = 1 and r->0->>'title' = 'T5', '3. cehd claim: ' || r::text;
  sid := r->0->'subs'->0->>'id';
  perform public.rpc_push_done(jsonb_build_array(jsonb_build_object('id', (r->0->>'id')::bigint, 'failed', jsonb_build_array(sid), 'error', 'HTTP 503')));
end $$;
reset role;
do $$ begin
  assert (select status from public.push_outbox where dedupe_key = 'c5') = 'failed', '3 cehddən sonra failed';
  assert (select attempts from public.push_outbox where dedupe_key = 'c5') = 3, 'cehd sayi 3';
  assert (select fail_count from public.push_subs where role = 'student'
           and student_id = '5555000a-0000-0000-0000-0000000005a1') = 3, 'abunenin xeta sayi';
end $$;

-- ------------------------------------- 7 · temizlik
insert into public.push_outbox (role, student_id, kind, dedupe_key, title, body, created_at)
values ('student', '5555000a-0000-0000-0000-0000000005a1', 'yeni_test', 'kohne', 'T', 'B', now() - interval '20 days');
update public.push_subs set last_ok_at = now() - interval '100 days' where student_id = '5555000a-0000-0000-0000-0000000005a2' and id in
  (select id from public.push_subs where student_id = '5555000a-0000-0000-0000-0000000005a2' limit 3);
select app.push_cleanup();
do $$ begin
  assert not exists (select 1 from public.push_outbox where dedupe_key = 'kohne'), 'kohne novbe silinmelidir';
  assert (select count(*) from public.push_subs where student_id = '5555000a-0000-0000-0000-0000000005a2') = 7, '90 gunluk abuneler silinmelidir';
  raise warning 'smoke_push: HAMISI KECDI';
end $$;
rollback;
