-- =====================================================================
--  smoke_sual_sekli_muellim.sql : muellimin oz sualina sekil (db/939)
--
--   1 · muellim A oz qovluguna yukleyir; B-nin qovluguna, yanlis ada, anon, numune hesaba - YOX
--   2 · hesaba fayl limiti (app.sekil_limit) - dolanda yukleme REDD
--   3 · silmek: A oz faylini silir, B A-nin faylini sile bilmir
--   4 · rpc_bank_question_media: oz suali + oz fayli - BELI; B-nin fayli,
--       olmayan fayl, B-nin suali - YOX; null sekli silir
--   5 · CHECK: muellim sualina https / data-URI yazmaq olmur, platforma qaydasi qalir
--   6 · rpc_sekil_yer (yalniz oz hesabi), rpc_admin_sekil (yalniz admin), anon hec birini cagira bilmir
--   7 · bucket: public, 100 KB, webp/jpeg
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;
set search_path = public, extensions;

delete from storage.objects where bucket_id = 'sual-sekil';
delete from public.question_options o using public.questions q
 where o.question_id = q.id and q.owner_type = 'educator';
delete from public.questions where owner_type = 'educator';
delete from public.questions where ext_key like 'smksk-%';
delete from public.subscriptions; delete from public.account_members;
delete from public.accounts; delete from public.user_roles;
delete from public.profiles; delete from auth.users;

insert into auth.users (id, email) values
  ('11110000-0000-0000-0000-0000000939a1','ska@t.az'),
  ('11110000-0000-0000-0000-0000000939b1','skb@t.az'),
  ('11110000-0000-0000-0000-0000000939c1','skadmin@t.az');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000939a1','tutor','SekilA','11110000-0000-0000-0000-0000000939a1'),
  ('aaaa0000-0000-0000-0000-0000000939b1','tutor','SekilB','11110000-0000-0000-0000-0000000939b1');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000939a1','11110000-0000-0000-0000-0000000939a1',true),
  ('aaaa0000-0000-0000-0000-0000000939b1','11110000-0000-0000-0000-0000000939b1',true);
insert into public.user_roles (user_id, role) values ('11110000-0000-0000-0000-0000000939c1','admin');

do $$
declare v_s uuid;
begin
  select id into v_s from public.subjects where slug = 'riyaziyyat';
  insert into public.questions (owner_type, owner_id, account_id, subject_id, kind, body, difficulty, status, ext_key) values
    ('educator','11110000-0000-0000-0000-0000000939a1','aaaa0000-0000-0000-0000-0000000939a1', v_s, 'single', 'A sekilli sual', 2, 'published', 'smksk-A'),
    ('educator','11110000-0000-0000-0000-0000000939b1','aaaa0000-0000-0000-0000-0000000939b1', v_s, 'single', 'B sekilli sual', 2, 'published', 'smksk-B');
end $$;

--  yukleme: Storage API-nin etdiyi kimi 'authenticated' rolunda INSERT
create or replace function pg_temp.up(p_user text, p_name text) returns text language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', p_user, true);
  execute 'set local role authenticated';
  insert into storage.objects (bucket_id, name, owner, metadata)
  values ('sual-sekil', p_name, nullif(p_user, '')::uuid, '{"size": 51200, "mimetype": "image/webp"}');
  execute 'reset role';
  return 'ok';
exception when others then
  execute 'reset role';
  return sqlstate;
end $$;
create or replace function pg_temp.del(p_user text, p_name text) returns int language plpgsql as $$
declare n int;
begin
  perform set_config('request.jwt.claim.sub', p_user, true);
  execute 'set local role authenticated';
  delete from storage.objects where bucket_id = 'sual-sekil' and name = p_name;
  get diagnostics n = row_count;
  execute 'reset role';
  return n;
end $$;

\echo '--- hazirliq tamam'
do $$
declare
  A  constant text := '11110000-0000-0000-0000-0000000939a1';
  B  constant text := '11110000-0000-0000-0000-0000000939b1';
  fa constant text := 'aaaa0000-0000-0000-0000-0000000939a1/0b3c1f9e-1111-4a2b-8c3d-000000000001.webp';
  fb constant text := 'aaaa0000-0000-0000-0000-0000000939b1/0b3c1f9e-2222-4a2b-8c3d-000000000002.webp';
  r text;
begin
  --  1
  assert pg_temp.up(A, fa) = 'ok', '1 A oz qovluguna yukleye bilmedi';
  assert pg_temp.up(B, fb) = 'ok', '1 B oz qovluguna yukleye bilmedi';
  r := pg_temp.up(A, 'aaaa0000-0000-0000-0000-0000000939b1/0b3c1f9e-3333-4a2b-8c3d-000000000003.webp');
  assert r <> 'ok', '1 A B-nin qovluguna yukledi';
  foreach r in array array[
      'aaaa0000-0000-0000-0000-0000000939a1/sekil.webp',
      'aaaa0000-0000-0000-0000-0000000939a1/0b3c1f9e-4444-4a2b-8c3d-000000000004.png',
      'aaaa0000-0000-0000-0000-0000000939a1/x/0b3c1f9e-4444-4a2b-8c3d-000000000004.webp',
      '0b3c1f9e-4444-4a2b-8c3d-000000000004.webp'] loop
    assert pg_temp.up(A, r) <> 'ok', '1 yanlis ad kecdi: ' || r;
  end loop;
  assert pg_temp.up('', 'aaaa0000-0000-0000-0000-0000000939a1/0b3c1f9e-5555-4a2b-8c3d-000000000005.webp') <> 'ok',
         '1 girissiz (sub yox) yukleme kecdi';
end $$;
\echo 'OK  1 · yalniz oz qovluguna, yalniz <uuid>.webp|jpg; B-nin qovlugu, yanlis ad, girissiz - redd'

--  1b. numune (demo) hesab - anonim ziyaretci yukleye bilmez
update public.accounts set is_demo = true where id = 'aaaa0000-0000-0000-0000-0000000939b1';
do $$
begin
  assert pg_temp.up('11110000-0000-0000-0000-0000000939b1',
           'aaaa0000-0000-0000-0000-0000000939b1/' || gen_random_uuid() || '.webp') <> 'ok', '1b numune hesaba yukleme kecdi';
end $$;
update public.accounts set is_demo = false where id = 'aaaa0000-0000-0000-0000-0000000939b1';
\echo 'OK  1b · numune hesaba yukleme redd'

--  2. limit
do $$
declare i int; n int;
begin
  select app.sekil_say('aaaa0000-0000-0000-0000-0000000939a1') into n;
  for i in n + 1 .. app.sekil_limit() loop
    insert into storage.objects (bucket_id, name) values
      ('sual-sekil', 'aaaa0000-0000-0000-0000-0000000939a1/' || gen_random_uuid() || '.webp');
  end loop;
  assert app.sekil_say('aaaa0000-0000-0000-0000-0000000939a1') = app.sekil_limit(), '2 hazirliq';
  assert pg_temp.up('11110000-0000-0000-0000-0000000939a1',
           'aaaa0000-0000-0000-0000-0000000939a1/' || gen_random_uuid() || '.webp') <> 'ok', '2 limitden artiq yuklendi';
  assert pg_temp.up('11110000-0000-0000-0000-0000000939b1',
           'aaaa0000-0000-0000-0000-0000000939b1/' || gen_random_uuid() || '.jpg') = 'ok', '2 A-nin limiti B-ni bagladi';
  delete from storage.objects where bucket_id = 'sual-sekil'
     and name like 'aaaa0000-0000-0000-0000-0000000939a1/%' and name not like '%000000000001.webp';
end $$;
\echo 'OK  2 · hesab limiti doldu - yeni yukleme redd; basqa hesaba tesir etmir'

--  3. silmek
do $$
declare x text;
begin
  x := 'aaaa0000-0000-0000-0000-0000000939a1/' || gen_random_uuid() || '.webp';
  assert pg_temp.up('11110000-0000-0000-0000-0000000939a1', x) = 'ok', '3 hazirliq';
  assert pg_temp.del('11110000-0000-0000-0000-0000000939b1', x) = 0, '3 B A-nin faylini sildi';
  assert pg_temp.del('11110000-0000-0000-0000-0000000939a1', x) = 1, '3 A oz faylini sile bilmedi';
end $$;
\echo 'OK  3 · oz faylini silir, basqasininkini yox'

--  4. rpc_bank_question_media
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000939a1';
do $$
declare
  qa uuid := (select id from public.questions where ext_key = 'smksk-A');
  qb uuid := (select id from public.questions where ext_key = 'smksk-B');
  P  constant text := '/storage/v1/object/public/sual-sekil/';
  ok_url constant text := P || 'aaaa0000-0000-0000-0000-0000000939a1/0b3c1f9e-1111-4a2b-8c3d-000000000001.webp';
  u text; bad boolean;
begin
  perform public.rpc_bank_question_media(qa, ok_url);
  assert (select media_url from public.questions where id = qa) = ok_url, '4 sekil yazilmadi';
  foreach u in array array[
      P || 'aaaa0000-0000-0000-0000-0000000939b1/0b3c1f9e-2222-4a2b-8c3d-000000000002.webp',   -- B-nin fayli
      P || 'aaaa0000-0000-0000-0000-0000000939a1/0b3c1f9e-9999-4a2b-8c3d-000000000009.webp',   -- yuklenmeyib
      'https://evil.example/x.webp', 'data:image/svg+xml,%3Csvg%3E%3C/svg%3E'] loop
    bad := false;
    begin perform public.rpc_bank_question_media(qa, u);
    exception when invalid_parameter_value then bad := true; end;
    assert bad, '4 qebul olunmamali unvan kecdi: ' || u;
  end loop;
  bad := false;
  begin perform public.rpc_bank_question_media(qb, null);
  exception when insufficient_privilege then bad := true; end;
  assert bad, '4 A B-nin sualinin seklini deyisdi';
  assert (select media_url from public.questions where id = qa) = ok_url, '4 redd olunan cehd sekli deyisdi';
  perform public.rpc_bank_question_media(qa, null);
  assert (select media_url from public.questions where id = qa) is null, '4 null sekli silmedi';
  perform public.rpc_bank_question_media(qa, ok_url);
end $$;
reset role; reset request.jwt.claim.sub;
\echo 'OK  4 · rpc_bank_question_media: oz fayli - beli; B-nin fayli, yuklenmemis, https, data-URI, B-nin suali - yox; null silir'

--  5. CHECK (birbasa yazi - RPC-den yan kecse de)
do $$
declare u text; bad boolean;
begin
  foreach u in array array['https://evil.example/x.webp', 'data:image/svg+xml,%3Csvg%3E%3C/svg%3E',
      '/storage/v1/object/public/basqa-bucket/aaaa0000-0000-0000-0000-0000000939a1/0b3c1f9e-1111-4a2b-8c3d-000000000001.webp',
      '/storage/v1/object/public/sual-sekil/aaaa0000-0000-0000-0000-0000000939a1/x.webp'] loop
    bad := false;
    begin update public.questions set media_url = u where ext_key = 'smksk-B';
    exception when check_violation then bad := true; end;
    assert bad, '5 CHECK muellim sualina buraxdi: ' || u;
  end loop;
end $$;
\echo 'OK  5 · CHECK: muellim sualinda yalniz bu bucket-in nisbi unvani'

--  6
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000939a1';
do $$
declare v jsonb; bad boolean := false;
begin
  v := public.rpc_sekil_yer('aaaa0000-0000-0000-0000-0000000939a1');
  assert (v->>'used')::int = 1 and (v->>'limit')::int = app.sekil_limit(), '6 sekil_yer: ' || v::text;
  begin perform public.rpc_sekil_yer('aaaa0000-0000-0000-0000-0000000939b1');
  exception when insufficient_privilege then bad := true; end;
  assert bad, '6 A B-nin hesabina baxdi';
  bad := false;
  begin perform public.rpc_admin_sekil();
  exception when insufficient_privilege then bad := true; end;
  assert bad, '6 adi muellim admin sekil setrini acdi';
end $$;
reset role; reset request.jwt.claim.sub;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000939c1';
do $$
declare v jsonb;
begin
  v := public.rpc_admin_sekil();
  assert (v->>'files')::int = 3 and (v->>'accounts')::int = 2 and (v->>'used_q')::int = 1
     and (v->>'bytes')::bigint = 3 * 51200, '6 admin (A 1 + B 2 fayl): ' || v::text;
end $$;
reset role; reset request.jwt.claim.sub;
do $$
begin
  assert not has_function_privilege('anon', 'public.rpc_bank_question_media(uuid, text)', 'EXECUTE'), '6 anon media RPC';
  assert not has_function_privilege('anon', 'public.rpc_sekil_yer(uuid)', 'EXECUTE'), '6 anon sekil_yer';
  assert not has_function_privilege('anon', 'public.rpc_admin_sekil()', 'EXECUTE'), '6 anon admin_sekil';
end $$;
\echo 'OK  6 · rpc_sekil_yer yalniz oz hesabi, rpc_admin_sekil yalniz admin, anon hec biri'

--  7
do $$
begin
  assert exists (select 1 from storage.buckets where id = 'sual-sekil' and public and file_size_limit = 102400
                    and allowed_mime_types @> array['image/webp', 'image/jpeg'] and cardinality(allowed_mime_types) = 2),
         '7 bucket parametrleri';
end $$;
\echo 'OK  7 · bucket: public, 100 KB, yalniz webp/jpeg'

delete from storage.objects where bucket_id = 'sual-sekil';
delete from public.questions where ext_key like 'smksk-%';
\echo 'SUAL SEKLI (MUELLIM): HAMISI KECDI'
