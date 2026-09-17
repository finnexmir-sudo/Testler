-- =====================================================================
--  smoke_huni.sql : (202) rpc_admin_huni - aktivlesme hunisi
--  4 muellim: A tesdiqsiz/girmeyib · B tesdiqli, girib, qrup yox ·
--  C qrup + sagird + test · D hamisi + pullu.  Numune ve admin sayilmir.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;
delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments; delete from public.student_sessions;
delete from public.students; delete from public.classes;
delete from public.tests where owner_type = 'educator';
delete from public.subscriptions; delete from public.account_members;
delete from public.accounts; delete from public.user_roles; delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data, created_at, email_confirmed_at, last_sign_in_at) values
  ('11110000-0000-0000-0000-0000000000f0','adm@t.az','{"full_name":"Admin"}', now(), now(), now()),
  --  204: menbe raw_user_meta_data.src-den profiles.src-e (A: wa, B: pis deyer -> bos)
  ('11110000-0000-0000-0000-0000000000f1','a@t.az','{"full_name":"A","src":"wa"}', now() - interval '2 days', null, null),
  ('11110000-0000-0000-0000-0000000000f2','b@t.az','{"full_name":"B","src":"<script>alert(1)</script>"}', now() - interval '3 days', now(), now()),
  ('11110000-0000-0000-0000-0000000000f3','c@t.az','{"full_name":"C"}', now() - interval '4 days', now(), now()),
  ('11110000-0000-0000-0000-0000000000f4','d@t.az','{"full_name":"D"}', now() - interval '5 days', now(), now()),
  ('11110000-0000-0000-0000-0000000000f5','e@t.az','{"full_name":"E kohne"}', now() - interval '60 days', now(), now());
--  profiles auth.users trigger-i ile yaranir - yalniz last_seen_at yazilir
update public.profiles set last_seen_at = now()
 where id in ('11110000-0000-0000-0000-0000000000f2','11110000-0000-0000-0000-0000000000f3','11110000-0000-0000-0000-0000000000f4');
insert into public.user_roles (user_id, role) values ('11110000-0000-0000-0000-0000000000f0','admin');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000f0','tutor','Admin','11110000-0000-0000-0000-0000000000f0'),
  ('aaaa0000-0000-0000-0000-0000000000f2','tutor','B','11110000-0000-0000-0000-0000000000f2'),
  ('aaaa0000-0000-0000-0000-0000000000f3','tutor','C','11110000-0000-0000-0000-0000000000f3'),
  ('aaaa0000-0000-0000-0000-0000000000f4','tutor','D','11110000-0000-0000-0000-0000000000f4');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000f0','11110000-0000-0000-0000-0000000000f0',true),
  ('aaaa0000-0000-0000-0000-0000000000f2','11110000-0000-0000-0000-0000000000f2',true),
  ('aaaa0000-0000-0000-0000-0000000000f3','11110000-0000-0000-0000-0000000000f3',true),
  ('aaaa0000-0000-0000-0000-0000000000f4','11110000-0000-0000-0000-0000000000f4',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-0000000000f3','aaaa0000-0000-0000-0000-0000000000f3','11110000-0000-0000-0000-0000000000f3','tutor_group','C qrup','KODHUN03'),
  ('cccc0000-0000-0000-0000-0000000000f4','aaaa0000-0000-0000-0000-0000000000f4','11110000-0000-0000-0000-0000000000f4','tutor_group','D qrup','KODHUN04');
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code) values
  ('5555000f-0000-0000-0000-000000000003','aaaa0000-0000-0000-0000-0000000000f3','cccc0000-0000-0000-0000-0000000000f3','11110000-0000-0000-0000-0000000000f3','S C','S C','KODHS03'),
  ('5555000f-0000-0000-0000-000000000004','aaaa0000-0000-0000-0000-0000000000f4','cccc0000-0000-0000-0000-0000000000f4','11110000-0000-0000-0000-0000000000f4','S D','S D','KODHS04');
insert into public.tests (id, owner_type, owner_id, class_id, program_id, subject_id, level_id, slug, title, status)
select x.id, 'educator', x.own, x.cls, pt.program_id, pt.subject_id, pt.level_id, x.slug, 'T', 'published'
  from (select program_id, subject_id, level_id from public.tests where owner_type = 'platform' limit 1) pt,
       (values ('7777000f-0000-0000-0000-000000000003'::uuid,'11110000-0000-0000-0000-0000000000f3'::uuid,'cccc0000-0000-0000-0000-0000000000f3'::uuid,'hun-c'),
               ('7777000f-0000-0000-0000-000000000004'::uuid,'11110000-0000-0000-0000-0000000000f4'::uuid,'cccc0000-0000-0000-0000-0000000000f4'::uuid,'hun-d')) as x(id, own, cls, slug);
insert into public.attempts (student_id, test_id, class_id, status, started_at, finished_at, score, max_score, percent) values
  ('5555000f-0000-0000-0000-000000000004','7777000f-0000-0000-0000-000000000004','cccc0000-0000-0000-0000-0000000000f4','submitted', now(), now(), 8, 10, 80);
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select 'aaaa0000-0000-0000-0000-0000000000f4', p.id, 'active', now() + interval '30 days' from public.plans p where p.slug = 'repetitor-25';

set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f2';
do $$
begin
  begin
    perform public.rpc_admin_huni(30);
    raise exception 'adi muellim huni gordu';
  exception when insufficient_privilege then null; end;
end $$;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f0';
do $$
declare h jsonb;
begin
  h := public.rpc_admin_huni(30);
  assert (h->>'registered') = '4', 'registered: ' || h::text;   -- A B C D (E kohne, admin yox)
  assert (h->>'confirmed') = '3' and (h->>'entered') = '3', 'confirmed/entered: ' || h::text;
  assert (h->>'grup') = '2' and (h->>'sagird') = '2' and (h->>'test') = '2', 'grup/sagird/test: ' || h::text;
  assert (h->>'cehd') = '1' and (h->>'pullu') = '1', 'cehd/pullu: ' || h::text;
  assert jsonb_array_length(h->'stuck') = 2, 'stuck: ' || (h->'stuck')::text;
  assert h->'stuck'->0->>'email' = 'a@t.az' and (h->'stuck'->0->>'confirmed') = 'false', 'stuck sira: ' || (h->'stuck')::text;
  assert h->'stuck'->1->>'email' = 'b@t.az' and (h->'stuck'->1->>'seen') is not null, 'stuck B: ' || (h->'stuck')::text;
  --  204: menbe uzre say + stuck setirde src
  assert (h->'src'->>'wa') = '1' and (h->'src'->>'') = '3', 'src bolgusu: ' || (h->'src')::text;
  assert h->'stuck'->0->>'src' = 'wa' and coalesce(h->'stuck'->1->>'src', '') = '', 'stuck src: ' || (h->'stuck')::text;
  assert (select src from public.profiles where id = '11110000-0000-0000-0000-0000000000f2') is null, 'pis src bos olmalidir';
  h := public.rpc_admin_huni(0);
  assert (h->>'registered') = '5', 'butun tarix: ' || h::text;
end $$;
reset role; reset request.jwt.claim.sub;
\echo 'OK  1 · (202) huni: qeydiyyat -> tesdiq -> giris -> qrup -> sagird -> test -> cehd -> pullu'
\echo 'HUNI: BUTUN YOXLAMALAR KECDI'
