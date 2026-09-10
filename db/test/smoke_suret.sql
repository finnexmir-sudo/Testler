-- smoke_suret.sql - db/180: suret olcusu
\set ON_ERROR_STOP on
begin;

insert into auth.users (id, email) values
  ('dddd0000-0000-0000-0000-0000000000c1','sradmin@t.az'),
  ('dddd0000-0000-0000-0000-0000000000c2','srmuel@t.az');
insert into public.profiles (id, full_name) values
  ('dddd0000-0000-0000-0000-0000000000c1','Sr Admin'),
  ('dddd0000-0000-0000-0000-0000000000c2','Sr Muellim')
on conflict (id) do update set full_name = excluded.full_name;
insert into public.user_roles (user_id, role) values
  ('dddd0000-0000-0000-0000-0000000000c1','admin') on conflict do nothing;

delete from public.perf_days;
\echo '--- hazirliq tamam'

-- =====================================================================
--  1. Cixis etmemis istifadeci yaza bilmir (sakitce kecir, xeta yox)
-- =====================================================================
set role anon;
do $$ begin
  begin
    perform public.rpc_perf('muellim', 1200);
    raise exception 'SEHV: anon rpc_perf-i cagira bildi';
  exception when sqlstate '42501' then null;
  end;
end $$;
\echo 'OK  1 · anon yaza bilmir'

-- =====================================================================
--  2. Adi muellim yazir; kova duzgun secilir
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = 'dddd0000-0000-0000-0000-0000000000c2';
do $$
begin
  perform public.rpc_perf('muellim',  800);   -- b1
  perform public.rpc_perf('muellim', 1500);   -- b2
  perform public.rpc_perf('muellim', 3000);   -- b3
  perform public.rpc_perf('muellim', 5000);   -- b4
  perform public.rpc_perf('muellim', 9000);   -- b5
end $$;
--  Cedvel authenticated-e BAGLIDIR (yoxlama 5) - oxumaq ucun rol
--  sifirlanir, sonra geri qaytarilir.
reset role; reset request.jwt.claim.sub;
do $$
declare r public.perf_days%rowtype;
begin
  select * into r from public.perf_days where page = 'muellim';
  assert r.n = 5, 'setir sayi 5 deyil: ' || r.n;
  assert r.b1 = 1 and r.b2 = 1 and r.b3 = 1 and r.b4 = 1 and r.b5 = 1,
         'kovalar duzgun bolunmedi';
  assert r.ms_max = 9000, 'ms_max yanlis: ' || r.ms_max;
  assert r.ms_sum = 19300, 'ms_sum yanlis: ' || r.ms_sum;
end $$;
\echo 'OK  2 · bes olcu, bes kova, cem ve maksimum duzdur'
set role authenticated;
set request.jwt.claim.sub = 'dddd0000-0000-0000-0000-0000000000c2';

-- =====================================================================
--  3. Ag-qara deyerler: 2 deqiqeden uzun olcme YAZILMIR
--     (arxa fonda dayandirilmis tab - olcu deyil)
-- =====================================================================
do $$ begin
  perform public.rpc_perf('muellim', 500000);
  perform public.rpc_perf('muellim', 0);
  perform public.rpc_perf('sehv_sehife', 1000);
end $$;
reset role; reset request.jwt.claim.sub;
do $$
declare v int;
begin
  select n into v from public.perf_days where page = 'muellim';
  assert v = 6, 'kirpme islemedi, say: ' || v;   -- 0 -> 1 ms kimi yazilir
  assert not exists (select 1 from public.perf_days where page = 'sehv_sehife'),
         'tanimayan sehife adi yazildi';
end $$;
\echo 'OK  3 · 2 deqiqeden uzun olcme ve tanimayan sehife atilir'
set role authenticated;
set request.jwt.claim.sub = 'dddd0000-0000-0000-0000-0000000000c2';

-- =====================================================================
--  4. Yekun: adi muellim GORE bilmir, admin gorur
-- =====================================================================
do $$ begin
  begin
    perform public.rpc_admin_suret(30);
    raise exception 'SEHV: adi muellim yekunu gordu';
  exception when sqlstate '42501' then null;
  end;
end $$;
set request.jwt.claim.sub = 'dddd0000-0000-0000-0000-0000000000c1';
do $$
declare v jsonb;
begin
  v := public.rpc_admin_suret(30);
  assert (v->>'n')::int = 6, 'yekun sayi yanlis: ' || (v->>'n');
  assert (v->>'orta')::int > 0, 'ortalama hesablanmadi';
  assert (v->>'max')::int = 9000, 'maksimum yanlis';
  assert jsonb_array_length(v->'kova') = 5, 'kova massivi bes deyil';
  assert jsonb_array_length(v->'gunler') = 1, 'gun-gun siyahi bos';
end $$;
\echo 'OK  4 · yekun yalniz adminde, reqemler uygundur'

-- =====================================================================
--  5. Cedvel birbasa oxunmur/yazilmir (RLS + revoke)
-- =====================================================================
do $$ begin
  begin
    perform 1 from public.perf_days limit 1;
    raise exception 'SEHV: authenticated cedveli oxudu';
  exception when sqlstate '42501' then null;
  end;
end $$;
\echo 'OK  5 · perf_days birbasa oxunmur - yalniz RPC ile'

reset role; reset request.jwt.claim.sub;
rollback;
\echo 'SURET: BUTUN YOXLAMALAR KECDI'
