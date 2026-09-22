-- =====================================================================
--  smoke_bu_gun_kart.sql : «Bu gün» karti + bir toxunusla tapsiriq (209)
--
--  Iddialar: rpc_home 'bugun' verir (dunen/bu gun isleyen sagird sayi,
--  susan, aktiv, bu gun verilmis tapsiriq); rpc_quick_assign test yigir
--  VE tapsiriq kimi verir; abunesiz reddedilir; ozge muellim cata bilmir.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.subscriptions;
delete from public.account_members; delete from public.accounts;
delete from public.user_roles;      delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-0000000009a1','bg@t.az','{"full_name":"BG Muellim"}'),
  ('11110000-0000-0000-0000-0000000009a2','ozge@t.az','{"full_name":"Ozge"}');
insert into public.accounts (id, type, name, owner_id, subjects) values
  ('aaaa0000-0000-0000-0000-0000000009a1','tutor','BG hesabi','11110000-0000-0000-0000-0000000009a1','{riyaziyyat}'),
  ('aaaa0000-0000-0000-0000-0000000009a2','tutor','Ozge hesabi','11110000-0000-0000-0000-0000000009a2','{riyaziyyat}');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000009a1','11110000-0000-0000-0000-0000000009a1',true),
  ('aaaa0000-0000-0000-0000-0000000009a2','11110000-0000-0000-0000-0000000009a2',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code, level_id) values
  ('cccc0000-0000-0000-0000-0000000009a1','aaaa0000-0000-0000-0000-0000000009a1',
   '11110000-0000-0000-0000-0000000009a1','tutor_group','BG qrup','KODBG001',
   (select id from public.levels where code = '7' order by sort limit 1));
--  216: «susan» yalniz BIR HEFTEDEN artiq movcud olan sagirdi sayir
--  (teze elave olunan sagird «bir heftedir susur» ola bilmez).  Fikstur
--  sagirdleri 20 gun evvele qoyulur - yoxsa Leyla susan sayilmir.
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code, created_at) values
  ('5555000b-0000-0000-0000-000000000001','aaaa0000-0000-0000-0000-0000000009a1',
   'cccc0000-0000-0000-0000-0000000009a1','11110000-0000-0000-0000-0000000009a1','Ayan Bir','Ayan B.','BGST0001', now() - interval '20 days'),
  ('5555000b-0000-0000-0000-000000000002','aaaa0000-0000-0000-0000-0000000009a1',
   'cccc0000-0000-0000-0000-0000000009a1','11110000-0000-0000-0000-0000000009a1','Murad Iki','Murad I.','BGST0002', now() - interval '20 days'),
  ('5555000b-0000-0000-0000-000000000003','aaaa0000-0000-0000-0000-0000000009a1',
   'cccc0000-0000-0000-0000-0000000009a1','11110000-0000-0000-0000-0000000009a1','Leyla Uc','Leyla U.','BGST0003', now() - interval '20 days');

--  Ayan DUNEN, Murad BU GUN isleyib; Leyla hec ne etmeyib (susan)
do $$
declare v_t uuid; v_a uuid;
begin
  select id into v_t from public.tests where owner_type = 'platform' limit 1;
  insert into public.attempts (student_id, test_id, class_id, status, percent, started_at, finished_at)
  values ('5555000b-0000-0000-0000-000000000001', v_t, 'cccc0000-0000-0000-0000-0000000009a1',
          'submitted', 40, now() - interval '1 day', (now() at time zone 'Asia/Baku')::date - 1 + time '18:00' at time zone 'Asia/Baku'),
         ('5555000b-0000-0000-0000-000000000002', v_t, 'cccc0000-0000-0000-0000-0000000009a1',
          'submitted', 80, now() - interval '2 hours', now() - interval '1 hour');
end $$;

set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000009a1';

-- =====================================================================
--  1. rpc_home -> 'bugun'
-- =====================================================================
do $$
declare v jsonb; b jsonb;
begin
  v := public.rpc_home('aaaa0000-0000-0000-0000-0000000009a1');
  b := v->'bugun';
  assert b is not null, '209: bugun acari yoxdur';
  assert (b->>'dunen')::int = 1, '209 dunen (Ayan): ' || b::text;
  assert (b->>'bu_gun')::int = 1, '209 bu gun (Murad): ' || b::text;
  assert (b->>'aktiv')::int = 3, '209 aktiv: ' || b::text;
  assert (b->>'susan')::int = 1, '209 susan (Leyla): ' || b::text;
  assert (b->>'verdim')::int = 0, '209 bu gun tapsiriq yoxdur: ' || b::text;
end $$;
\echo 'OK  1 · (209) «Bu gün» kəsimi: dünən, bu gün, susan, aktiv, verdim'

-- =====================================================================
--  2. rpc_quick_assign: abunesiz REDD
-- =====================================================================
do $$
declare v_top uuid;
begin
  select t.id into v_top from public.topics t
    join public.levels lv on lv.id = t.level_id and lv.code = '7'
   where t.parent_id is null
     and exists (select 1 from public.questions q where q.topic_id = t.id)
   limit 1;
  perform set_config('smoke.top9', v_top::text, false);
  begin
    perform public.rpc_quick_assign('cccc0000-0000-0000-0000-0000000009a1', v_top, 5);
    raise exception '209: abunesiz test yigildi';
  exception when insufficient_privilege then null; end;
end $$;
\echo 'OK  2 · (209) abunəsiz hesabda bir toxunuş bağlıdır'

-- =====================================================================
--  3. Abune acilir: test yigilir VE tapsiriq kimi gedir
-- =====================================================================
reset role;
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-0000000009a1', id, 'active', now() + interval '30 days'
  from public.plans where slug = 'repetitor-25';
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000009a1';
do $$
declare r jsonb; v_top uuid := current_setting('smoke.top9')::uuid;
begin
  r := public.rpc_quick_assign('cccc0000-0000-0000-0000-0000000009a1', v_top, 5);
  assert (r->>'ok')::boolean and (r->>'test_id') is not null, '209 quick_assign: ' || r::text;
  assert (r->>'count')::int between 1 and 5, '209 sual sayi: ' || r::text;
  perform set_config('smoke.test9', r->>'test_id', false);
end $$;
reset role;
do $$
declare v_test uuid := current_setting('smoke.test9')::uuid;
begin
  assert exists (select 1 from public.tests where id = v_test and owner_type = 'educator'),
    '209: test yaranmadi';
  assert exists (select 1 from public.assignments where test_id = v_test
                   and class_id = 'cccc0000-0000-0000-0000-0000000009a1'),
    '209: tapsiriq verilmedi';
end $$;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000009a1';
do $$
declare v jsonb;
begin
  v := public.rpc_home('aaaa0000-0000-0000-0000-0000000009a1');
  assert (v->'bugun'->>'verdim')::int >= 1, '209: «verdim» artmadi: ' || (v->'bugun')::text;
end $$;
\echo 'OK  3 · (209) bir toxunuş: test yığılır, tapşırıq gedir, «verdim» artır'

-- =====================================================================
--  4. Ozge muellim cata bilmir
-- =====================================================================
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000009a2';
do $$
declare v_top uuid := current_setting('smoke.top9')::uuid;
begin
  begin
    perform public.rpc_quick_assign('cccc0000-0000-0000-0000-0000000009a1', v_top, 5);
    raise exception '209: ozge muellim tapsiriq verdi';
  exception when insufficient_privilege then null; end;
end $$;
reset role; reset request.jwt.claim.sub;
\echo 'OK  4 · (209) özgə müəllim bu qrupa tapşırıq verə bilmir'
\echo ''
\echo '=============================='
\echo ' BU GUN KARTI: HAMISI KECDI'
\echo '=============================='
