-- =====================================================================
--  smoke_ziyaret.sql : ziyaret saygaci (db/161)
--
--  Iddialar: anon rpc_visit yazir · eyni IP+UA eyni gun eyni vid,
--  ferqli IP ferqli vid · basliq yoxdursa vid null (say yene islenir) ·
--  yanlis sehife/hadise redd · gunde 200 hedd · anon cedveli oxuya
--  bilmir · admin cemi/gunler/hadiseler; adi muellim yox · 90 gunden
--  kohne setir silinir · «wa»/«mail» klikleri de sayilir (186).
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.visits;
delete from public.subscriptions;
delete from public.account_members; delete from public.accounts;
delete from public.user_roles;      delete from public.profiles;
delete from auth.users;
insert into auth.users (id, email) values
  ('11110000-0000-0000-0000-00000000f1a1','zy-admin@t.az'),
  ('11110000-0000-0000-0000-00000000f1a2','zy-tutor@t.az');
insert into public.user_roles (user_id, role) values ('11110000-0000-0000-0000-00000000f1a1','admin');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-00000000f1a2','tutor','Zy hesabi','11110000-0000-0000-0000-00000000f1a2');

-- 1. anon yazir; vid eyni/ferqli; basliqsiz null
set role anon;
do $$
declare v jsonb; a text; b text; c text;
begin
  perform set_config('request.headers', '{"x-forwarded-for":"1.2.3.4, 10.0.0.1","user-agent":"UA-1"}', true);
  v := public.rpc_visit('home', 'view');
  assert (v->>'ok')::boolean, 'anon baxis yazmadi';
  v := public.rpc_visit('home', 'demo_muellim');
  v := public.rpc_visit('komek', 'view');
  --  186: altliqdaki «WhatsApp» ve «e-poct» klikleri.  Evvel bunlar
  --  sakitce redd olunurdu - sehifede data-ev var idi, serverde yox.
  assert (public.rpc_visit('home', 'wa')->>'ok')::boolean, 'wa kliki sayilmadi';
  assert (public.rpc_visit('home', 'mail')->>'ok')::boolean, 'mail kliki sayilmadi';
  perform set_config('request.headers', '{"x-forwarded-for":"5.6.7.8","user-agent":"UA-1"}', true);
  v := public.rpc_visit('home', 'view');
  perform set_config('request.headers', '', true);
  v := public.rpc_visit('home', 'view');
  assert (v->>'ok')::boolean, 'basliqsiz baxis yazmadi';
  --  redd
  assert not (public.rpc_visit('admin', 'view')->>'ok')::boolean, 'yanlis sehife kecdi';
  assert not (public.rpc_visit('home', 'hack')->>'ok')::boolean, 'yanlis hadise kecdi';
end $$;
reset role;
do $$
declare n int; d int; z int;
begin
  select count(*) into n from public.visits; assert n = 7, 'setir sayi: ' || n;
  select count(distinct vid) into d from public.visits where vid is not null; assert d = 2, 'unikal vid: ' || d;
  select count(*) into z from public.visits where vid is null; assert z = 1, 'basliqsiz vid null deyil';
  assert not exists (select 1 from public.visits where vid like '%1.2.3.4%'), 'IP acıq saxlanib!';
end $$;
\echo 'OK  1 · anon yazir, vid hash, basliqsiz null, yanlis giris redd'

-- 2. anon cedveli oxuya bilmir; hedd 200
set role anon;
do $$
declare bad boolean := false; n int; v jsonb;
begin
  begin select count(*) into n from public.visits; exception when insufficient_privilege then bad := true; end;
  assert bad, 'anon visits cedvelini oxudu!';
  perform set_config('request.headers', '{"x-forwarded-for":"9.9.9.9","user-agent":"BOT"}', true);
  for i in 1..200 loop perform public.rpc_visit('home', 'view'); end loop;
  v := public.rpc_visit('home', 'view');
  assert not (v->>'ok')::boolean and (v->>'limit')::boolean, 'hedd islemedi';
end $$;
reset role;
\echo 'OK  2 · anon cedveli oxumur; gunde 200 hedd'

-- 3. admin cemi; adi muellim yox; kohne setir silinir
insert into public.visits (at, page, ev, vid) values (now() - interval '100 days', 'home', 'view', 'old');
insert into auth.users (id, email) values ('11110000-0000-0000-0000-00000000f1a3','zy-old@t.az');
insert into public.accounts (id, type, name, owner_id, created_at) values
  ('aaaa0000-0000-0000-0000-00000000f1a3','tutor','Kohne hesab','11110000-0000-0000-0000-00000000f1a3', now() - interval '10 days');
insert into public.visits (at, page, ev, vid) values (now() - interval '3 days', 'home', 'view', 'w1');
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-00000000f1a2';
do $$
declare bad boolean := false;
begin
  begin perform public.rpc_admin_visits(30); exception when insufficient_privilege then bad := true; end;
  assert bad, 'adi muellim ziyaretleri gordu';
end $$;
set request.jwt.claim.sub = '11110000-0000-0000-0000-00000000f1a1';
do $$
declare v jsonb;
begin
  v := public.rpc_admin_visits(30);
  assert (v->'today'->>'views')::int = 204, 'bu gun baxis: ' || (v->'today'->>'views');
  assert (v->'today'->>'uniq')::int = 3, 'bu gun unikal: ' || (v->'today'->>'uniq');
  assert (v->'today'->>'demo')::int = 1, 'bu gun demo: ' || (v->'today'->>'demo');
  assert (v->'d7'->>'views')::int = 205, '7 gun baxis: ' || (v->'d7'->>'views');
  assert (v->'today'->>'signup')::int = 1, 'bu gun qeydiyyat: ' || (v->'today'->>'signup');
  --  162: saygacdan EVVEL acilmis hesab huniye dusmur
  assert (v->>'start') = (current_date - 3)::text, 'baslangic gunu (w1, 3 gun evvel): ' || (v->>'start');
  assert jsonb_array_length(v->'days') = 30, 'gun sayi 30 deyil';
  assert (v->'d30'->>'signup')::int = 1, '30 gun qeydiyyat (kohne hesab dusdu?): ' || (v->'d30'->>'signup');
  assert (v->'events'->>'demo_muellim')::int = 1, 'hadise sayi';
  assert (v->'events'->>'wa')::int = 1, 'wa hadisesi: ' || coalesce(v->'events'->>'wa','yox');
  assert (v->'events'->>'mail')::int = 1, 'mail hadisesi: ' || coalesce(v->'events'->>'mail','yox');
end $$;
reset role; reset request.jwt.claim.sub;
do $$
begin
  assert not exists (select 1 from public.visits where vid = 'old'), '90 gunden kohne setir silinmedi';
  assert exists (select 1 from public.visits where vid = 'w1'), 'teze setir silindi';
end $$;
\echo 'OK  3 · admin cemi/gunler/hadiseler; adi muellim yox; 90 gun temizlik'
