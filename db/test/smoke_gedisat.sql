-- =====================================================================
--  smoke_gedisat.sql : 932 - gedisat (son 3 test / evvelki 3 test) bir dusturla
--
--    1  Siqnallar (rpc_home.alerts) last3 / prev3 = app.student_trend()
--    2  muellimin sagird hesabati (rpc_student_report.trend) = app.student_trend()
--    3  valideyn paneli (rpc_parent_home.summary.trend) = muellimin gorduyu
--    4  valideyn panelinin boyuk reqemi (avg30) = trend.avg30
--    5  «geriləyir» siqnali olan sagirdde trend de dusus gosterir (prev3 - last3 >= drop)
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

select set_config('smoke.uid', (select owner_id::text from public.accounts where id = app.demo_account()), false);
select set_config('smoke.acc', app.demo_account()::text, false);
--  valideyn girisi olan sagird (VDEMO001) - muqayise ucun onun trendi saxlanir
select set_config('smoke.psid', (select id::text from public.students where parent_code = 'VDEMO001'), false);
select set_config('smoke.ptrend', app.student_trend((select id from public.students where parent_code = 'VDEMO001'))::text, false);
create temp table tr_ref as
  select s.id, app.student_trend(s.id) t from public.students s where s.account_id = app.demo_account();
grant select on tr_ref to authenticated;

set role authenticated;
select set_config('request.jwt.claim.sub', current_setting('smoke.uid'), false);
do $$
declare
  h jsonb := public.rpc_home(current_setting('smoke.acc')::uuid);
  a jsonb; t jsonb; r jsonb; n int := 0; nr int := 0;
begin
  assert jsonb_array_length(coalesce(h->'alerts', '[]')) > 0, 'numunede siqnal yoxdur';
  for a in select * from jsonb_array_elements(h->'alerts') loop
    select tr_ref.t into t from tr_ref where tr_ref.id = (a->>'student_id')::uuid;
    assert (t->>'last3')::numeric = (a->>'last3')::numeric
       and coalesce((t->>'prev3')::numeric, -1) = coalesce((a->>'prev3')::numeric, -1),
      format('1 · %s: siqnal %s→%s, trend %s→%s', a->>'name', a->>'prev3', a->>'last3', t->>'prev3', t->>'last3');
    r := public.rpc_student_report((a->>'student_id')::uuid);
    assert r->'trend' = t, format('2 · %s: hesabatin trendi ferqlidir', a->>'name');
    if a->>'kind' = 'risk' then
      assert (t->>'prev3')::numeric - (t->>'last3')::numeric >= (t->>'drop')::numeric,
        format('5 · %s: siqnal «geriləyir», trend dusus gostermir', a->>'name');
      nr := nr + 1;
    end if;
    n := n + 1;
  end loop;
  assert n > 0;
  --  qrup sehifesinin siqnallari (rpc_class_alerts) - eyni dustur
  for r in select public.rpc_class_alerts(c.cid) from (select distinct (x->>'class_id')::uuid cid
             from jsonb_array_elements(h->'alerts') x) c loop
    for a in select * from jsonb_array_elements(r->'alerts') loop
      select tr_ref.t into t from tr_ref where tr_ref.id = (a->>'student_id')::uuid;
      assert (t->>'last3')::numeric = (a->>'last3')::numeric
         and coalesce((t->>'prev3')::numeric, -1) = coalesce((a->>'prev3')::numeric, -1),
        format('1b · qrup siqnali %s: %s→%s, trend %s→%s', a->>'name', a->>'prev3', a->>'last3', t->>'prev3', t->>'last3');
    end loop;
  end loop;
end $$;
reset role;
\echo 'OK  1 · Siqnallarin son 3 / evvelki 3 ortasi app.student_trend ile eynidir (Icmal ve qrup sehifesi)'
\echo 'OK  2 · muellimin sagird hesabatindaki gedisat eyni funksiyadandir'
\echo 'OK  5 · «geriləyir» siqnalinda trend de dusus gosterir'

--  6 (933): siqnallar novun icinde en agirdan - Icmal ve qrup sehifesi
set role authenticated;
select set_config('request.jwt.claim.sub', current_setting('smoke.uid'), false);
do $$
declare
  lists jsonb[] := array[public.rpc_home(current_setting('smoke.acc')::uuid)->'alerts'];
  l jsonb; i int; a jsonb; b jsonb; ka int; kb int; c record;
begin
  for c in select distinct (x->>'class_id')::uuid cid
             from jsonb_array_elements(lists[1]) x loop
    lists := lists || (public.rpc_class_alerts(c.cid)->'alerts');
  end loop;
  foreach l in array lists loop
    for i in 0 .. jsonb_array_length(l) - 2 loop
      a := l->i; b := l->(i + 1);
      ka := case a->>'kind' when 'risk' then 1 when 'weak' then 2 else 3 end;
      kb := case b->>'kind' when 'risk' then 1 when 'weak' then 2 else 3 end;
      assert ka <= kb, format('6 · nov sirasi pozulub: %s sonra %s', a->>'kind', b->>'kind');
      if ka = kb and ka = 1 then
        assert (a->>'prev3')::numeric - (a->>'last3')::numeric >= (b->>'prev3')::numeric - (b->>'last3')::numeric,
          format('6 · geriləyir: %s (%s) %s-dan (%s) evvel', a->>'name', (a->>'prev3')::numeric - (a->>'last3')::numeric,
                 b->>'name', (b->>'prev3')::numeric - (b->>'last3')::numeric);
      elsif ka = kb and ka = 2 then
        assert (a->>'topic_ratio')::numeric <= (b->>'topic_ratio')::numeric,
          format('6 · zeif movzu: %s (%s%%) %s-dan (%s%%) evvel', a->>'name', a->>'topic_ratio', b->>'name', b->>'topic_ratio');
      end if;
    end loop;
  end loop;
end $$;
reset role;
\echo 'OK  6 · siqnallar (Icmal ve qrup) novun icinde en agirdan siralanir'

do $$
declare tok text; v jsonb; t jsonb := current_setting('smoke.ptrend')::jsonb;
begin
  tok := public.rpc_parent_login('VDEMO001')->>'token';
  assert tok is not null, 'valideyn girisi alinmadi';
  v := public.rpc_parent_home(tok);
  assert v->'summary'->'trend' = t, format('3 · valideyn trendi %s, muellim %s', v->'summary'->'trend', t);
  assert (v->'summary'->>'avg30')::numeric is not distinct from (t->>'avg30')::numeric,
    format('4 · valideynin boyuk reqemi %s, trend avg30 %s', v->'summary'->>'avg30', t->>'avg30');
end $$;
\echo 'OK  3 · valideyn paneli muellimle eyni gedisati gorur'
\echo 'OK  4 · valideynin «son 30 gun» reqemi trend.avg30 ile eynidir'
\echo 'GEDISAT: BUTUN YOXLAMALAR KECDI'
