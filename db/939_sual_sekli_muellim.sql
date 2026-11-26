-- =====================================================================
--  939_sual_sekli_muellim.sql — MUELLIMIN OZ SUALINA SEKIL (Supabase Storage)
--
--  Reqib saytlarda (TestUp, Kampus) var idi, bizde yox: muellim oz
--  sualina sekil (fiqur, qrafik, cedvel) qosa bilmirdi - 188-in CHECK-i
--  sekli yalniz platforma sualina icaze verirdi.
--
--  QERAR (istifadeci, 26.11): sekil BAZADA yox, Storage-de saxlanir.
--  Sebeb olculub: baza 233 MB / 500 (47%) - en dar yer odur; sekil
--  bazada olsa her test acilanda yeniden gedir (trafik).  Storage ayrica
--  1 GB-dir, brauzer sekli bir defe yukleyib kesde saxlayir.
--
--  NECE ISLEYIR
--   1. Brauzer sekli kicildir (<= 1000 px, WebP/JPEG, ~80 KB) ve
--      'sual-sekil' bucket-ine yukleyir:  <hesab_id>/<uuid>.webp
--   2. Sual saxlananda rpc_bank_question_media sualin media_url-ine
--      NISBI unvan yazir:  /storage/v1/object/public/sual-sekil/<hesab>/<uuid>.webp
--      Host yazilmir - ekran CFG.SUPABASE_URL-i ozu qosur (lokal mock da,
--      canli da eyni setirle isleyir).
--
--  QORUYUCULAR
--   - Bucket: public (oxumaq ucun giris lazim deyil - sagird kodla girir),
--     fayl <= 100 KB, yalniz image/webp ve image/jpeg.
--   - Yazmaq/silmek (RLS, storage.objects): yalniz oz hesabinin qovluguna,
--     ad yalniz <uuid>.webp|jpg, hesaba en cox app.sekil_limit() fayl.
--   - media_url: RPC yalniz oz hesabinin qovlugundaki, REAL yuklenmis
--     fayli qebul edir; CHECK ikinci qapidir (format).
--   - Ekranda <img> ile cizilir (innerHTML yox) - 188-deki kimi.
--
--  CANLIDA: bu fayl, sonra 05_grants.sql.  Supabase 'storage' sxemi artiq
--  var; lokal yoxlamada test/00_supabase_stub.sql onun kicik surətini qurur.
-- =====================================================================

do $$
begin
  if to_regclass('storage.objects') is null or to_regclass('storage.buckets') is null then
    raise exception '939: storage sxemi yoxdur (Supabase-de var; lokalda test/00_supabase_stub.sql).';
  end if;
  if to_regclass('public.questions') is null then
    raise exception '939: once 01_schema.sql isledilmelidir.';
  end if;
  --  Komekci funksiyalar (security definer, sahibi bu faylı isleden rol)
  --  storage.objects-i SAYIR.  Sahib RLS-den kecmirse, sayim siyasetlere
  --  gore 0 olar: limit islemez, RPC «Şəkil tapılmadı» deyer - SESSIZ sınma.
  if not exists (select 1 from pg_roles where rolname = current_user and (rolbypassrls or rolsuper)) then
    raise exception '939: % rolu RLS-den kece bilmir - SQL Editor-da postgres rolu ile isledin.', current_user;
  end if;
end $$;

--  ---------------------------------------------------------------- 1. bucket
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('sual-sekil', 'sual-sekil', true, 102400, array['image/webp', 'image/jpeg'])
on conflict (id) do update
   set public             = true,
       file_size_limit    = excluded.file_size_limit,
       allowed_mime_types = excluded.allowed_mime_types;

--  ---------------------------------------------------------- 2. komekciler
--  Hesaba fayl limiti.  Tetbiq sual saxlanmadan cixilanda yuklenmis fayli
--  ozu silir, amma brauzer baglanarsa fayl qala biler - ona gore limit
--  "sual sayi" yox, "fayl sayi"dir ve bir az ehtiyatlidir.
create or replace function app.sekil_limit() returns int
language sql immutable as $$ select 150 $$;

--  Fayl adi: <hesab uuid>/<fayl uuid>.webp|jpg  ve hesab cagiranindir.
create or replace function app.sekil_yol_ok(p_name text) returns boolean
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_p text[] := string_to_array(coalesce(p_name, ''), '/');
  v_u constant text := '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}';
begin
  if coalesce(array_length(v_p, 1), 0) <> 2
     or v_p[1] !~ ('^' || v_u || '$')
     or v_p[2] !~ ('^' || v_u || '\.(webp|jpg)$') then
    return false;
  end if;
  --  Numune (demo) hesabi anonim ziyaretcinindir - ora yukleme YOX:
  --  her ziyaret 150 fayl ede bilerdi, 1 GB-ni yad adam doldurardi.
  if exists (select 1 from public.accounts a where a.id = v_p[1]::uuid and a.is_demo) then
    return false;
  end if;
  return app.is_account_member(v_p[1]::uuid);
end $$;

--  Hesabin qovlugunda neçe fayl var (siyasetin icinden cagirilir - RLS-i
--  kecmek ucun security definer).
create or replace function app.sekil_say(p_account uuid) returns int
language sql stable security definer
set search_path = public, extensions, pg_temp as $$
  select count(*)::int from storage.objects
   where bucket_id = 'sual-sekil' and name like p_account::text || '/%'
$$;

create or replace function app.sekil_yer_var(p_name text) returns boolean
language sql stable security definer
set search_path = public, extensions, pg_temp as $$
  select app.sekil_say(split_part(p_name, '/', 1)::uuid) < app.sekil_limit()
$$;

revoke all on function app.sekil_limit()         from public, anon;
revoke all on function app.sekil_yol_ok(text)    from public, anon;
revoke all on function app.sekil_say(uuid)       from public, anon;
revoke all on function app.sekil_yer_var(text)   from public, anon;
grant execute on function app.sekil_limit()       to authenticated;
grant execute on function app.sekil_yol_ok(text)  to authenticated;
grant execute on function app.sekil_say(uuid)     to authenticated;
grant execute on function app.sekil_yer_var(text) to authenticated;

--  ------------------------------------------------- 3. siyasetler (RLS)
--  Oxumaq: bucket public-dir, /object/public/... RLS-siz verilir.
--  'select' siyaseti silmek ucun lazimdir (Storage silmezden evvel oxuyur).
drop policy if exists sual_sekil_insert on storage.objects;
create policy sual_sekil_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'sual-sekil' and app.sekil_yol_ok(name) and app.sekil_yer_var(name));
drop policy if exists sual_sekil_select on storage.objects;
create policy sual_sekil_select on storage.objects for select to authenticated
  using (bucket_id = 'sual-sekil' and app.sekil_yol_ok(name));
drop policy if exists sual_sekil_delete on storage.objects;
create policy sual_sekil_delete on storage.objects for delete to authenticated
  using (bucket_id = 'sual-sekil' and app.sekil_yol_ok(name));

--  ------------------------------------------------------------ 4. CHECK
--  Platforma qaydasi 188-deki kimi QALIR.  Muellim sualina yalniz Storage-in
--  nisbi unvani (bu bucket, uuid qovluq, uuid ad).  Qovlugun HANSI hesaba
--  aid oldugunu RPC yoxlayir (CHECK sorgu ede bilmez).
alter table public.questions drop constraint if exists questions_media_ok;
alter table public.questions add constraint questions_media_ok check (
  media_url is null
  or (
    owner_type = 'platform'
    and length(media_url) <= 24000
    and (media_url like 'data:image/svg+xml,%'
      or media_url like 'data:image/svg+xml;%'
      or media_url like 'https://%')
    and position('script'      in lower(media_url)) = 0
    and position('onload'      in lower(media_url)) = 0
    and position('onerror'     in lower(media_url)) = 0
    and position('javascript:' in lower(media_url)) = 0
  )
  or (
    owner_type = 'educator'
    and media_url ~ '^/storage/v1/object/public/sual-sekil/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(webp|jpg)$'
  )
);
comment on column public.questions.media_url is
  'Sualin sekli. Platforma: SVG data-URI (app.svg_uri) ve ya https. '
  'Muellim (939): /storage/v1/object/public/sual-sekil/<hesab>/<uuid>.webp|jpg - nisbi, ekran SUPABASE_URL qosur. '
  'Ekranda <img> ile cizilir - innerHTML-e dusmur.';

--  ------------------------------------------------------------- 5. RPC-ler
--  Sualin sekli: qoy / deyis / sil.  rpc_bank_save_question-un imzasina
--  toxunulmur - sual saxlanandan sonra bu ayrica cagirilir.
create or replace function public.rpc_bank_question_media(p_id uuid, p_media text)
returns jsonb language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_q    record;
  v_name text;
  v_m    text := nullif(btrim(coalesce(p_media, '')), '');
begin
  if auth.uid() is null then
    raise exception 'Daxil olun.' using errcode = '42501';
  end if;
  select id, owner_type, account_id, media_url into v_q from public.questions where id = p_id;
  if not found or v_q.owner_type <> 'educator' or not app.is_account_member(v_q.account_id) then
    raise exception 'Bu sual sizin deyil.' using errcode = '42501';
  end if;
  if v_m is not null then
    v_name := substring(v_m from '^/storage/v1/object/public/sual-sekil/(.+)$');
    if v_name is null or split_part(v_name, '/', 1) <> v_q.account_id::text
       or not app.sekil_yol_ok(v_name) then
      raise exception 'Şəkil ünvanı yanlışdır.' using errcode = '22023';
    end if;
    if not exists (select 1 from storage.objects where bucket_id = 'sual-sekil' and name = v_name) then
      raise exception 'Şəkil tapılmadı — yenidən yükləyin.' using errcode = '22023';
    end if;
  end if;
  update public.questions set media_url = v_m where id = p_id;
  return jsonb_build_object('id', p_id, 'media_url', v_m, 'old', v_q.media_url);
end $$;
revoke all on function public.rpc_bank_question_media(uuid, text) from public, anon;
grant execute on function public.rpc_bank_question_media(uuid, text) to authenticated;

--  Yuklemeden evvel: hesabda yer varmi (Storage-in RLS xetasi "limit dolub"
--  ile "icaze yoxdur"u ayirmir - muellim aydin cumle gorsun).
create or replace function public.rpc_sekil_yer(p_account uuid)
returns jsonb language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
begin
  if auth.uid() is null or not app.is_account_member(p_account) then
    raise exception 'Bu hesab sizin deyil.' using errcode = '42501';
  end if;
  return jsonb_build_object('used', app.sekil_say(p_account), 'limit', app.sekil_limit());
end $$;
revoke all on function public.rpc_sekil_yer(uuid) from public, anon;
grant execute on function public.rpc_sekil_yer(uuid) to authenticated;

--  Admin: Storage ne qeder dolub (pulsuz plan 1 GB).
create or replace function public.rpc_admin_sekil()
returns jsonb language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
begin
  if not app.is_admin() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;
  return (
    select jsonb_build_object(
      'files',    count(*),
      'bytes',    coalesce(sum(nullif(o.metadata->>'size', '')::bigint), 0),
      'accounts', count(distinct split_part(o.name, '/', 1)),
      'used_q',   (select count(*) from public.questions q
                    where q.owner_type = 'educator' and q.media_url like '/storage/%'),
      'limit',    app.sekil_limit())
      from storage.objects o where o.bucket_id = 'sual-sekil');
end $$;
revoke all on function public.rpc_admin_sekil() from public, anon;
grant execute on function public.rpc_admin_sekil() to authenticated;

--  ------------------------------------------------------------ 6. yoxlama
do $$
begin
  if not exists (select 1 from storage.buckets where id = 'sual-sekil' and public) then
    raise exception '939: sual-sekil bucket-i yaranmadi';
  end if;
  if (select count(*) from pg_policies where schemaname = 'storage' and tablename = 'objects'
        and policyname in ('sual_sekil_insert', 'sual_sekil_select', 'sual_sekil_delete')) <> 3 then
    raise exception '939: storage siyasetleri tam deyil';
  end if;
  raise notice '939 OK - sual-sekil bucket-i, 3 siyaset, rpc_bank_question_media, rpc_sekil_yer, rpc_admin_sekil';
end $$;
