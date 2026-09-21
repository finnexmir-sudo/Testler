-- =====================================================================
--  217 : TOVSIYE KODU - «bu muellimi kim getirdi?»  (2026-09-21)
--
--  204-de ?src=hemkar nisani qeydiyyata qeder dasinirdi, amma LINKI
--  KIMIN PAYLASDIGI hec yerde qalmirdi.  Canli hal: Atilla Yaverli
--  «hemkar» nisani ile geldi - kimin linki oldugu barede yalniz
--  tehmin etmek olurdu.
--
--  Indi linkde ikinci nisan var:  bil10.az/?src=hemkar&r=<kod>
--  Kod muellimin profilindedir (profiles.ref_code), ilk paylasmada
--  yaranir.  Qeydiyyatdan kecen adamin profilinde ref_by = getirenin
--  id-si yazilir.
--
--  NIYE LAZIMDIR: tovsiyeye gore hediyye vermek ucun SAYMAQ lazimdir.
--  Saymadan «siz uc muellim getirdiniz» demek olmaz.
--
--  MEXFILIK: kod sexsi melumat deyil - tesadufi 6 simvol.  Linkde ad,
--  e-poct, telefon GETMIR.
-- =====================================================================
set search_path = public, app;

alter table public.profiles add column if not exists ref_code text;
alter table public.profiles add column if not exists ref_by   uuid
  references public.profiles(id) on delete set null;

create unique index if not exists profiles_ref_code_uq
  on public.profiles (ref_code) where ref_code is not null;
create index if not exists profiles_ref_by_ix
  on public.profiles (ref_by) where ref_by is not null;

comment on column public.profiles.ref_code is
  '217: muellimin oz tovsiye kodu - paylasdigi linkde gedir.';
comment on column public.profiles.ref_by is
  '217: bu istifadecini getiren muellimin profil id-si.';

-- ------------------------------------------------- kod (varsa qaytarir)
create or replace function app.ref_code_for(p_uid uuid) returns text
language plpgsql volatile security definer
set search_path = public, extensions, pg_temp as $$
declare v_code text; i int;
begin
  select ref_code into v_code from public.profiles where id = p_uid;
  if v_code is not null then return v_code; end if;
  --  Toqqusma ehtimali cox kicikdir, yene de bir nece cehd edirik
  for i in 1..8 loop
    v_code := app.gen_login_code(6);
    begin
      update public.profiles set ref_code = v_code where id = p_uid;
      return v_code;
    exception when unique_violation then
      null;   -- teze kod yigilir
    end;
  end loop;
  return null;   -- kod verile bilmedi: link kodsuz gedecek, ziyani yoxdur
end $$;

-- ------------------------------------------- muellimin oz linki + sayi
--  Panel «Hemkarina gonder» duymesinde cagirir.
create or replace function public.rpc_ref_link()
returns jsonb
language plpgsql volatile security definer
set search_path = public, extensions, pg_temp as $$
declare v_uid uuid := auth.uid(); v_code text;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  v_code := app.ref_code_for(v_uid);
  return jsonb_build_object(
    'code', v_code,
    --  nece nefer bu muellimin linki ile qeydiyyatdan kecib
    'n', (select count(*) from public.profiles p where p.ref_by = v_uid));
end $$;
revoke all on function public.rpc_ref_link() from public, anon;
grant  execute on function public.rpc_ref_link() to authenticated;

-- ------------------------------------------------- qeydiyyatda yazilir
--  204-un uzerine: 'ref' meta-sahesi de oxunur.  (Marker usulu
--  islenmir - govde tamdir.)
create or replace function app.handle_new_user() returns trigger
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_src  text := lower(coalesce(new.raw_user_meta_data->>'src', ''));
  v_ref  text := upper(coalesce(new.raw_user_meta_data->>'ref', ''));
  v_by   uuid;
begin
  if v_src !~ '^[a-z0-9_-]{1,20}$' then v_src := null; end if;
  if v_ref ~ '^[A-Z0-9]{4,12}$' then
    select id into v_by from public.profiles where ref_code = v_ref;
    --  Oz-ozunu getiren olmaz
    if v_by = new.id then v_by := null; end if;
  end if;
  insert into public.profiles (id, full_name, src, ref_by)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', ''), v_src, v_by)
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists trg_auth_user_created on auth.users;
create trigger trg_auth_user_created
  after insert on auth.users
  for each row execute function app.handle_new_user();

-- ------------------------------------------------------ idareetme uzre
--  Kim kimi getirib.  Hediyye qerari bu siyahiya baxilaraq verilecek.
create or replace function public.rpc_admin_ref()
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
begin
  if not app.admin_ok() then
    raise exception 'Icaze yoxdur.' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(x order by x->>'n' desc, x->>'ad')
      from (
        select jsonb_build_object(
                 'id',   r.id,
                 'ad',   coalesce(nullif(r.full_name, ''), '(adsiz)'),
                 'kod',  r.ref_code,
                 'n',    count(g.id),
                 'kim',  jsonb_agg(jsonb_build_object(
                           'ad',  coalesce(nullif(g.full_name, ''), '(adsiz)'),
                           'gun', g.created_at)
                         order by g.created_at desc)
               ) x
          from public.profiles r
          join public.profiles g on g.ref_by = r.id
         group by r.id, r.full_name, r.ref_code
      ) z), '[]'::jsonb);
end $$;
revoke all on function public.rpc_admin_ref() from public, anon;
grant  execute on function public.rpc_admin_ref() to authenticated;
