-- =====================================================================
--  smoke_admin_grant.sql : 909 - admin «sinaq» / «odenisli» abune verir; gelir yalniz 'active'
--  Hamisi tranzaksiyada, sonda GERI alinir.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;
begin;

insert into auth.users (id, email) values
  ('11110000-0000-0000-0000-0000000007a1','admin@t.az'),
  ('11110000-0000-0000-0000-0000000007a2','samir@t.az');
insert into public.accounts (id, type, name, owner_id, is_demo) values
  ('aaaa0000-0000-0000-0000-0000000007a1','tutor','Admin','11110000-0000-0000-0000-0000000007a1', false),
  ('aaaa0000-0000-0000-0000-0000000007a2','tutor','Samir test','11110000-0000-0000-0000-0000000007a2', false);
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000007a1','11110000-0000-0000-0000-0000000007a1',true),
  ('aaaa0000-0000-0000-0000-0000000007a2','11110000-0000-0000-0000-0000000007a2',true);
insert into public.user_roles (user_id, role) values ('11110000-0000-0000-0000-0000000007a1','admin');
insert into public.classes (id, account_id, teacher_id, kind, name, join_code)
values ('cccc0000-0000-0000-0000-0000000007a2','aaaa0000-0000-0000-0000-0000000007a2','11110000-0000-0000-0000-0000000007a2','tutor_group','Samir qrup','KODSM901');
insert into public.students (account_id, class_id, created_by, full_name, display_name, login_code)
select 'aaaa0000-0000-0000-0000-0000000007a2','cccc0000-0000-0000-0000-0000000007a2','11110000-0000-0000-0000-0000000007a2','Sagird '||g,'S'||g,'SMRX000'||g from generate_series(1,2) g;

set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000007a1';

do $$
declare v text;
begin
  --  1) abune yoxdur + SINAQ -> trialing, gelir 0
  perform public.rpc_admin_grant('samir@t.az', 'sagird-basi', 1, true);
  v := (select coalesce(string_agg(status::text || '/' || provider, ',' order by created_at), '-')
                          from public.subscriptions where account_id = 'aaaa0000-0000-0000-0000-0000000007a2');
  assert v = 'trialing/trial', '1: sinaq trialing olmalidir: ' || v;
  assert (public.rpc_admin_stats()->>'mrr_minor')::bigint = 0, '1: sinaq gelir vermemelidir';

  --  2) sinaq + ODENISLI -> active (muddet bu gunden), gelir = 2 sagird x 1,50
  perform public.rpc_admin_grant('samir@t.az', 'sagird-basi', 1, false);
  v := (select coalesce(string_agg(status::text || '/' || provider, ',' order by created_at), '-')
                          from public.subscriptions where account_id = 'aaaa0000-0000-0000-0000-0000000007a2');
  assert v = 'active/manual', '2: sinaqdan odenisliye kecmelidir: ' || v;
  assert (public.rpc_admin_stats()->>'mrr_minor')::bigint = 300, '2: gelir 3 AZN olmalidir: ' || (public.rpc_admin_stats()->>'mrr_minor')::bigint;

  --  3) hele QUVVEDE olan odenisli + SINAQ -> odenisli QALIR (evvelki qayda)
  perform public.rpc_admin_grant('samir@t.az', 'sagird-basi', 1, true);
  v := (select coalesce(string_agg(status::text || '/' || provider, ',' order by created_at), '-')
                          from public.subscriptions where account_id = 'aaaa0000-0000-0000-0000-0000000007a2');
  assert v = 'active/manual', '3: quvvedeki odenisli sinaga enmemelidir: ' || v;

  --  4) DAYANDIR -> canceled, gelir 0
  perform public.rpc_admin_stop('samir@t.az');
  assert (public.rpc_admin_stats()->>'mrr_minor')::bigint = 0, '4: dayandirilandan sonra gelir 0 olmalidir';
  assert (select coalesce(string_agg(status::text || '/' || provider, ',' order by created_at), '-')
                          from public.subscriptions where account_id = 'aaaa0000-0000-0000-0000-0000000007a2') = 'canceled/manual', '4: ' || (select coalesce(string_agg(status::text || '/' || provider, ',' order by created_at), '-')
                          from public.subscriptions where account_id = 'aaaa0000-0000-0000-0000-0000000007a2');

  --  5) dayandirilmis + SINAQ -> YENI trialing setri, gelir 0
  perform public.rpc_admin_grant('samir@t.az', 'sagird-basi', 1, true);
  assert (select coalesce(string_agg(status::text || '/' || provider, ',' order by created_at), '-')
                          from public.subscriptions where account_id = 'aaaa0000-0000-0000-0000-0000000007a2') = 'canceled/manual,trialing/trial', '5: ' || (select coalesce(string_agg(status::text || '/' || provider, ',' order by created_at), '-')
                          from public.subscriptions where account_id = 'aaaa0000-0000-0000-0000-0000000007a2');
  assert (public.rpc_admin_stats()->>'mrr_minor')::bigint = 0, '5: gelir 0 olmalidir';
end $$;

--  6) 909: vaxti KECMIS 'active' (dayandirilmayib) + SINAQ -> trialing (evvel 'active' qalirdi, gelir 3 AZN)
reset role; reset request.jwt.claim.sub;
delete from public.subscriptions where account_id = 'aaaa0000-0000-0000-0000-0000000007a2';
insert into public.subscriptions (account_id, plan_id, status, started_at, current_period_end, provider)
select 'aaaa0000-0000-0000-0000-0000000007a2', p.id, 'active', now() - interval '40 days', now() - interval '2 days', 'manual'
  from public.plans p where p.slug = 'sagird-basi';
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000007a1';
do $$
declare v_end timestamptz;
begin
  assert (public.rpc_admin_stats()->>'mrr_minor')::bigint = 0, '6: vaxti kecmis abune gelir vermemelidir';
  perform public.rpc_admin_grant('samir@t.az', 'sagird-basi', 1, true);
  assert (select coalesce(string_agg(status::text || '/' || provider, ',' order by created_at), '-')
                          from public.subscriptions where account_id = 'aaaa0000-0000-0000-0000-0000000007a2') = 'trialing/trial', '6: kecmis active + sinaq = trialing olmalidir: ' || (select coalesce(string_agg(status::text || '/' || provider, ',' order by created_at), '-')
                          from public.subscriptions where account_id = 'aaaa0000-0000-0000-0000-0000000007a2');
  assert (public.rpc_admin_stats()->>'mrr_minor')::bigint = 0, '6: gelir 0 olmalidir (evvel 3 AZN idi)';
  select current_period_end into v_end from public.subscriptions
   where account_id = 'aaaa0000-0000-0000-0000-0000000007a2';
  assert v_end > now() + interval '27 days' and v_end < now() + interval '32 days',
         '6: sinaq muddeti bu gunden ~1 ay olmalidir: ' || v_end;

  --  7) kecmis active + ODENISLI -> active (muddet bu gunden)
  perform public.rpc_admin_grant('samir@t.az', 'sagird-basi', 1, false);
  assert (select coalesce(string_agg(status::text || '/' || provider, ',' order by created_at), '-')
                          from public.subscriptions where account_id = 'aaaa0000-0000-0000-0000-0000000007a2') = 'active/manual', '7: ' || (select coalesce(string_agg(status::text || '/' || provider, ',' order by created_at), '-')
                          from public.subscriptions where account_id = 'aaaa0000-0000-0000-0000-0000000007a2');
  assert (public.rpc_admin_stats()->>'mrr_minor')::bigint = 300, '7: gelir 3 AZN';
  raise warning 'smoke_admin_grant: HAMISI KECDI';
end $$;
reset role; reset request.jwt.claim.sub;
rollback;
