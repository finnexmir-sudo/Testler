-- Yalniz LOKAL YOXLAMA ucun. Supabase-de bunlar artiq var - orada isletme.
-- Meqsed: sxemi ve RLS-i real Postgres uzerinde isledib yoxlamaq.
create schema if not exists auth;
create schema if not exists app;

-- Supabase uzanti funksiyalarini "extensions" sxeminde saxlayir, public-de yox.
-- Lokal yoxlamani da eyni etmesek, search_path sehvleri yalniz istehsalatda
-- uze cixir (bir defe bas verdi: gen_random_bytes tapilmadi -> HTTP 404).
create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;
-- Supabase-de de "extensions" sxemindedir: generatorun oxsarliq suzgeci
create extension if not exists pg_trgm with schema extensions;

-- Supabase-deki auth.users-in bize lazim olan sutunlari.
create table if not exists auth.users (
  id                 uuid primary key default gen_random_uuid(),
  email              text unique,
  encrypted_password text,
  raw_user_meta_data jsonb not null default '{}'::jsonb,
  created_at         timestamptz not null default now(),
  last_sign_in_at    timestamptz,
  email_confirmed_at timestamptz
);
--  202: kohne yerli bazalar ucun
alter table auth.users add column if not exists email_confirmed_at timestamptz;

-- Supabase-deki auth.uid() eynisi: JWT-deki sub iddiasini oxuyur.
create or replace function auth.uid() returns uuid
language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;

do $$ begin
  create role anon          nologin;
  create role authenticated nologin;
  create role service_role  nologin bypassrls;
exception when duplicate_object then null; end $$;

-- Supabase-de auth sxemi ve auth.uid() rollara aciqdir - eynisini edirik.
grant usage on schema auth   to anon, authenticated, service_role;
grant execute on function auth.uid() to anon, authenticated, service_role;
grant usage on schema public to anon, authenticated, service_role;
grant usage on schema app    to anon, authenticated, service_role;
alter default privileges in schema public
  grant select, insert, update, delete on tables to anon, authenticated;

--  DIQQET: Supabase yeni FUNKSIYALARA da anon ucun EXECUTE-u birbasa
--  verir.  Bunu tekrarlamasaq "revoke ... from public" kifayet edirmis
--  kimi gorunur - halbuki anon-un BIRBASA huququ qalir ve sehv yalniz
--  canli Supabase-de uze cixir.  Bir defe bele oldu.
alter default privileges in schema public
  grant execute on functions to anon, authenticated;

--  939: Supabase Storage-in bize lazim olan hissesi (canlida 'storage' sxemi
--  artiq var - orada bu fayl isledilmir).  Siyasetler (RLS) canlidaki kimi
--  storage.objects uzerinde yazilir; mock_supabase.py yukleme sorgusunu
--  'authenticated' rolunda bu cedvele INSERT edir - yeni siyaset lokal da
--  real Postgres-de yoxlanir.
create schema if not exists storage;
create table if not exists storage.buckets (
  id                 text primary key,
  name               text not null,
  public             boolean not null default false,
  file_size_limit    bigint,
  allowed_mime_types text[]
);
create table if not exists storage.objects (
  id         uuid primary key default gen_random_uuid(),
  bucket_id  text references storage.buckets(id),
  name       text not null,
  owner      uuid,
  metadata   jsonb,
  created_at timestamptz not null default now(),
  unique (bucket_id, name)
);
alter table storage.objects enable row level security;
create or replace function storage.foldername(name text) returns text[]
language sql immutable as $$
  select (string_to_array(name, '/'))[1:array_length(string_to_array(name, '/'), 1) - 1]
$$;
grant usage on schema storage to anon, authenticated, service_role;
grant select, insert, update, delete on storage.objects to authenticated;
grant select on storage.buckets to anon, authenticated;
