-- =====================================================================
--  smoke_zeif_movzu.sql : 931 - zeif movzu uc ekranda BIR qayda ile
--
--  Numune hesabinin dolu meselumatinda HER qrup x movzu ucun:
--    1  rpc_home.topics[].avg      = rpc_topic_weak.ratio          (Icmal = #/zm faizi)
--    2  rpc_home.topics[].weak     = rpc_topic_weak.students        (eyni adlar, eyni say)
--    3  rpc_class_report weak_students = rpc_topic_weak.students    («Ne etmeli» = #/zm)
--    4  rpc_class_report topic ratio  = rpc_topic_weak.ratio (yuvarlaq) - aktiv sagirdler
--    5  «Ne etmeli»nin secdiyi movzu (en cox zeif sagird) Icmalin hemin qrup ucun
--       birinci movzusudur
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.app_state where key = 'demo_reset';
select (public.rpc_demo_reset()->>'ok')::boolean as numune_quruldu \gset
\if :numune_quruldu
\else
  \echo 'numune qurulmadi'
  \quit 1
\endif

--  numune hesabinin sahibi kimi (rpc_class_report / rpc_topic_weak muellim yoxlayir)
select set_config('smoke.uid', (select owner_id::text from public.accounts where id = app.demo_account()), false);
select set_config('smoke.acc', app.demo_account()::text, false);
set role authenticated;
select set_config('request.jwt.claim.sub', current_setting('smoke.uid'), false);

do $$
declare
  h jsonb := public.rpc_home(current_setting('smoke.acc')::uuid);
  t jsonb; z jsonb; r jsonb; rt jsonb;
  n int := 0; zs text; hs text; rs text;
  top_home jsonb; todo jsonb;
  c record;
begin
  assert jsonb_array_length(coalesce(h->'topics', '[]')) > 0, 'numunede Icmal zeif movzu gostermir';

  for t in select * from jsonb_array_elements(h->'topics') loop
    z := public.rpc_topic_weak((t->>'class_id')::uuid, (t->>'id')::uuid);
    assert (t->>'avg')::numeric = (z->>'ratio')::numeric,
      format('1 · Icmal %s%% <> #/zm %s%% (%s)', t->>'avg', z->>'ratio', t->>'name');
    select string_agg(x->>'id', ',' order by x->>'id') into hs from jsonb_array_elements(t->'weak') x;
    select string_agg(x->>'id', ',' order by x->>'id') into zs from jsonb_array_elements(z->'students') x;
    assert coalesce(hs, '') = coalesce(zs, ''), format('2 · Icmal ve #/zm ferqli sagirdler (%s)', t->>'name');
    assert (t->>'weak_n')::int = jsonb_array_length(z->'students'), '2 · weak_n <> #/zm say';

    r := public.rpc_class_report((t->>'class_id')::uuid);
    select x into rt from jsonb_array_elements(r->'topics') x where x->>'id' = t->>'id';
    assert rt is not null, format('3 · qrup hesabatinda movzu yoxdur (%s)', t->>'name');
    select string_agg(x->>'id', ',' order by x->>'id') into rs from jsonb_array_elements(rt->'weak_students') x;
    assert coalesce(rs, '') = coalesce(zs, ''), format('3 · «Ne etmeli» ve #/zm ferqli sagirdler (%s): %s / %s',
      t->>'name', jsonb_array_length(rt->'weak_students'), jsonb_array_length(z->'students'));
    assert round((rt->>'ratio')::numeric) = (z->>'ratio')::numeric,
      format('4 · qrup hesabati %s%% <> #/zm %s%% (%s)', rt->>'ratio', z->>'ratio', t->>'name');
    n := n + 1;
  end loop;
  assert n > 0;

  --  5: her qrup ucun «Ne etmeli» (panelin qaydasi: en cox zeif sagird, sonra en asagi faiz)
  for c in select distinct (x->>'class_id')::uuid cid from jsonb_array_elements(h->'topics') x loop
    select x into top_home from jsonb_array_elements(h->'topics') x
     where (x->>'class_id')::uuid = c.cid limit 1;            -- rpc_home artiq bu sira ile verir
    r := public.rpc_class_report(c.cid);
    select x into todo from jsonb_array_elements(r->'topics') x
     where jsonb_array_length(x->'weak_students') > 0
     order by jsonb_array_length(x->'weak_students') desc, (x->>'ratio')::numeric limit 1;
    assert todo->>'id' = top_home->>'id',
      format('5 · «Ne etmeli» %s, Icmal %s', todo->>'name', top_home->>'name');
  end loop;
end $$;
reset role;
\echo 'OK  1-4 · Icmal, «Ne etmeli» ve #/zm: her movzuda eyni faiz ve eyni zeif sagirdler'
\echo 'OK  5 · «Ne etmeli» her qrupda Icmalin birinci movzusudur'
\echo 'ZEIF MOVZU: BUTUN YOXLAMALAR KECDI'
