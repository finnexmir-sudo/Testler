-- Yalniz LOKAL YOXLAMA ucun (canlida storage sxemi Supabase-in ozundedir).
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
